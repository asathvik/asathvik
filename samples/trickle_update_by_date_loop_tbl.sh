#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Explain the purpose of the script.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	04/12/2012 - Dimitriy Alekseyev
#	Script created.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# MySQL client connection.
mysqlc="mysql --host=127.0.0.1 --port=3460 --user=dbauser --password=`cat /usr/local/bin/mysql/m31_passwd.txt` --database=orders_archive --unbuffered"

# Loop table name.
loop_table=b66024_trickle_loop_tmp

# Set number of seconds to sleep before repeating.
sleep=10


################################################################################
# Functions
################################################################################

function clean_up {
	# Function to remove temporary files and other housekeeping
	# No arguments
	rm -f ${tmp_file}
}

function graceful_exit {
	# Function called for a graceful exit
	# No arguments
	clean_up
	exit
}

function error_exit {
	# Function for exit due to fatal program error
	# Accepts 1 argument
	#	string containing descriptive error message
	echo "${progname}: ${1:-"Unknown Error"}" 1>&2
	clean_up
	exit 1
}

function term_exit {
	# Function to perform exit if termination signal is trapped
	# No arguments
	echo "${progname}: Terminated"
	clean_up
	exit 1
}

function int_exit {
	# Function to perform exit if interrupt signal is trapped
	# No arguments
	echo "${progname}: Aborted by user"
	clean_up
	exit 1
}

function usage {
	# Function to show usage
	# No arguments
	echo "USAGE"
	echo "	$progname port"
	echo
	echo "EXAMPLE"
	echo "	$progname 3365"

	clean_up
	exit 1
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT

echo "**************************************************"
echo "* Trickle update"
echo "* Time started:" `date +'%F %T %Z'`
echo "**************************************************"
echo

echo "Building lookup table..."
$mysqlc -e "DROP TABLE IF EXISTS $loop_table;" || error_exit "Error on line $LINENO. Problem executing SQL statement."

$mysqlc -e "
CREATE TABLE
	$loop_table
SELECT
	@rownum := @rownum + 1 AS rownum,
	t1.order_date,
	t1.count
FROM (
	SELECT
		order_date,
		COUNT(*) AS count
	FROM
		b66024_loan_mapping_tmp AS m
		INNER JOIN b66024_orders_tmp AS o ON o.submission_key = m.submission_key
		INNER JOIN (SELECT @rownum := 0) AS rn
	GROUP BY
		order_date
	ORDER BY
		order_date
) AS t1;
" || error_exit "Error on line $LINENO. Problem executing SQL statement."

$mysqlc -e "ALTER TABLE $loop_table ADD PRIMARY KEY (rownum);" || error_exit "Error on line $LINENO. Problem executing SQL statement."

$mysqlc --table -e "SELECT * FROM $loop_table ORDER BY rownum;" || error_exit "Error on line $LINENO. Problem executing SQL statement."

echo "Done."

echo "Time:" `date +'%F %T %Z'`

echo "Begin cleanup..."

loop_total=`$mysqlc --skip-column-names -e "SELECT COUNT(*) FROM $loop_table;"` || error_exit "Error on line $LINENO. Problem executing SQL statement."

echo "There are $loop_total entries in the loop table."

x=0

while true
do
	if [[ $x -lt $loop_total ]]; then
		let x=$x+1
		echo
		echo
		echo "Processing entry $x."
		
		date=`$mysqlc --skip-column-names -e "SELECT order_date FROM $loop_table WHERE rownum = '$x';"` || error_exit "Error on line $LINENO. Problem executing SQL statement."
		echo "Date: $date"
		
		row_count=`$mysqlc --skip-column-names -e "SELECT count FROM $loop_table WHERE rownum = '$x';"` || error_exit "Error on line $LINENO. Problem executing SQL statement."
		echo "Row count: $row_count"
		
		# If number of records selected is greater than 0 then take action.
		if [[ $row_count != 0 ]]; then
			result_full=( "`$mysqlc -vvv -e "
			UPDATE
				b66024_loan_mapping_tmp AS m
				INNER JOIN b66024_orders_tmp AS o ON o.submission_key = m.submission_key AND o.loan_number = m.old_loan_nbr
			SET
				o.userdef1 = m.old_loan_nbr,
				o.loan_number = m.new_loan_nbr
			WHERE
				order_date = '$date'
			;
			"`" ) || error_exit "Error on line $LINENO. Problem executing SQL statement."
			echo "${result_full[@]}"
			
			rows_affected=`echo "${result_full[@]}" | grep -A 1 'Query OK' | grep -A 1 'rows affected' | grep -B 1 'Rows matched:' | grep -B 1 'Changed:' | head -1 | gawk -F'Query OK, ' '{print $2}' | gawk -F' ' '{print $1}'`
			rows_changed=`echo "${result_full[@]}" | grep -A 1 'Query OK' | grep -A 1 'rows affected' | grep -B 1 'Rows matched:' | grep -B 1 'Changed:' | tail -1 | gawk -F'Changed: ' '{print $2}' | gawk -F' ' '{print $1}'`
			
			if [[ $row_count != $rows_affected || $row_count != $rows_changed ]]; then
				error_exit "Error on line $LINENO. Row count and rows affected/changed do not match up."
			fi
			
			echo "Sleeping for $sleep seconds..."
			sleep $sleep
		fi
		
		echo "Time:" `date +'%F %T %Z'`
	else
		break
	fi
done

$mysqlc -e "DROP TABLE $loop_table;" || error_exit "Error on line $LINENO. Problem executing SQL statement."

echo "Done."

graceful_exit
