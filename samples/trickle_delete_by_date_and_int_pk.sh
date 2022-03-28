#!/bin/bash
################################################################################
# Author:
#	Samantha Browning
#
# Purpose:
#	Trickle delete records from rs_jboss_cache.rs_jboss_cache table.
#
# Usage:
#	rs_jboss_cache_trickle_delete.sh
#
# Revisions:
#	06/25/2009 - Samantha Browning
#	Script created.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# MySQL client connection.
mysqlclient="mysql --host=10.183.100.125 --port=3380 --user=dbauser --password=`cat /usr/local/bin/mysql/m15_passwd.txt` -n --skip-column-names -e"

# Database name.
database=rs_jboss_cache

# Table name.
table=rs_jboss_cache

# Date range.
## Use for daily delete
  begindate=`date -d "-91 days" +%F`
  enddate=`date -d "-89 days" +%F`
## Use for full delete.
  #begindate=`date -d "-365 days" +%F`
  #enddate=`date -d "-89 days" +%F`

# Set an increment value.
incr=500

# Set number of seconds to sleep before repeating.
#sleep=1


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
	exit
}

function int_exit {
	# Function to perform exit if interrupt signal is trapped
	# No arguments
	echo "${progname}: Aborted by user"
	clean_up
	exit
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT

echo "**************************************************"
echo "* Trickle delete rows from rs_jboss_cache"
echo "* Time started:" `date +'%F %T %Z'`
echo "**************************************************"
echo
echo "Database:" $database
echo "Table:" $table
echo
echo "Begin date:" $begindate
echo "End date:" $enddate
echo
echo
echo "Determine primary key range..."
qryresult=`$mysqlclient "SELECT min(cache_id), max(cache_id) FROM $database.$table WHERE insert_dt >= '$begindate' and insert_dt < '$enddate';"` || error_exit "Error on line $LINENO. Problem executing SQL statement."

pkstart=`echo $qryresult | gawk -F' '  '{ print $1 }'`
pkend=`echo $qryresult | gawk -F' ' '{ print $2 }'`

echo "Start PK value: $pkstart"
echo "End PK value: $pkend"
echo "Increment by: $incr"
echo
echo
echo "**************************************************"
echo "* Time:" `date +'%F %T %Z'`
echo "**************************************************"
echo
echo "Beginning deletion..."
echo
let x=$pkstart
while true
do
	if [[ $x -le $pkend ]]; then
		let n=$x
		let m=$n+$incr-1
		if [[ $m -gt $pkend ]]; then let m=$pkend; fi
		
		cmd="select count(*) as count from $database.$table where cache_id between $n and $m and node is not null"
		result_full=( "`$mysqlclient "$cmd"`" )
				
		# If number of records selected is greater than 0 then take action.
		if [[ $result_full != 0 ]]; then
			cmd="delete from $database.$table where cache_id between $n and $m and node is not null"
			$mysqlclient "$cmd"
			
		#	echo "Sleeping for $sleep second..."
		#	sleep $sleep
		#	echo
		fi
		
		let x=$n+$incr
	else
		break
	fi
done

echo "Deletion complete."

echo
echo "**************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "**************************************************"

graceful_exit
