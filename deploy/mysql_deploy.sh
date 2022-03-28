#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Deploy MySQL schema change scripts and validate database state before 
#	and after deployment.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	2012-11-19 - Dimitriy Alekseyev
#	Script created.
#	2012-12-07 - Dimitriy Alekseyev
#	Added verbose and silent options. Added more info to usage.
#	2012-12-31 - Dimitriy Alekseyev
#	Added code for apply and backout tasks. Revised script. Modified 
#	verbosity levels. Added error handling when .err file is not empty, 
#	since on a lot of servers mysql client is set not to abort on failure. 
#	Added run time and file name information to output.
#	2013-02-26 - Dimitriy Alekseyev
#	Corrected default value for run_task.
#  	2013-07-25 - Anil Kumar Alpati
#	Added code for validating mysql directory structure.
#	2013-08-22 - Dimitriy Alekseyev
#	Clean up of the script.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=$(basename $0)

validate_db_object_counts=/dba_share/scripts/mysql/deploy/validate_db_object_counts.sql

# Default values.
run_task=va
verbosity_level=3

tmp_file=""


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
	echo "Time of error:" `date +'%F %T %Z'`
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
	echo "SYNOPSIS
	$progname -r {v|a|b} -i instance [-d database] script_name.sql ...

EXAMPLE
	nohup $progname -r va -i 1 testdb.B-12345.script.sql >> mysql_deploy.log &
	or
	$progname -r B -i 4 testdb.B-12345.script.sql
	or
	$progname -r vab -i 5 -d testdb testdb.B-12345.script.sql testdb.B-12345.script2.sql

DESCRIPTION
	Use this script to deploy MySQL SQL schema change (DDL) scripts. You 
	can supply multiple SQL scripts to be deployed. Always supply the name 
	of the apply script (even for backout tasks, supply the name of apply 
	script). Separate timestamped log and error files will be created when 
	executing each SQL script.
	
	Supply instance, tasks to run, and script name(s). Optionally supply 
	database name, but if it is not supplied, then the name will be 
	derived from the SQL script name.

OPTIONS
	-r, --run-task
		What task to perform. Default is 'va'.
		v = validate (create schema dump and object counts).
		a = apply (run apply SQL script, then create schema dump and object counts).
		b = backout (run backout SQL script, then create schema dump and object counts).
		A = apply only (run apply SQL script).
		B = backout only (run backout SQL script).
	-i, --instance
		Connect to this instance number.
	-d, --database
		Connect to this database name.
	-v, --verbose
		Verbose mode. Produces more information in output.
		Could be specified multiple times.
	-s, --silent
		Silent mode. Produces less information in output.
		Could be specified multiple times."

	clean_up
	exit 1
}

function validate {
	# Function for validation
	# No arguments
	if [[ "$verbosity_level" -ge 0 ]]; then
		echo "validate: Get mysqldump of the schema."
	fi
	
	ts_start=$(date '+%s.%N')
	ts_file=$(date -d "1970-01-01 ${ts_start%.*} sec GMT" +'%Y%m%d_%H%M%S')
	filename_sql=$ts_file.$database.schema_dump.sql
	filename_err=$ts_file.$database.schema_dump.err
	mysqldump --socket=$socket --user=dbauser --password=$(cat /usr/local/bin/mysql/m${inst}_passwd.txt) --create-options --no-data --routines --databases $database > $filename_sql 2> $filename_err || error_exit "Error on line $LINENO."
	ts_end=$(date '+%s.%N')
	
	if [[ "$verbosity_level" -ge 4 ]]; then
		echo "filename_sql: $filename_sql"
		echo "filename_err: $filename_err"
	fi
	if [[ "$verbosity_level" -ge 1 ]]; then
		ts_diff=$(echo "$ts_end - $ts_start" | bc)
		echo "run_time: $ts_diff seconds"
		echo
	fi
	
	if [[ "$verbosity_level" -ge 0 ]]; then
		echo "validate: Get a count of database objects."
	fi
	
	ts_start=$(date '+%s.%N')
	ts_file=$(date -d "1970-01-01 ${ts_start%.*} sec GMT" +'%Y%m%d_%H%M%S')
	filename_log=$ts_file.$database.validate_db_object_counts.log
	filename_err=$ts_file.$database.validate_db_object_counts.err
	m${inst}c.sh < $validate_db_object_counts > $filename_log 2> $filename_err || error_exit "Error on line $LINENO."
	ts_end=$(date '+%s.%N')
	
	if [[ "$verbosity_level" -ge 4 ]]; then
		echo "filename_log: $filename_log"
		echo "filename_err: $filename_err"
	fi
	if [[ "$verbosity_level" -ge 1 ]]; then
		ts_diff=$(echo "$ts_end - $ts_start" | bc)
		echo "run_time: $ts_diff seconds"
		echo
	fi
}

function check_for_errors {
	# Function for checking errors after executing a SQL script
	# Accepts 1 argument
	#	string containing error file name
	file_name_err=$1
	
	if [[ -s "$file_name_err" ]]; then
		error_exit "Error on line $LINENO. SQL script execution has failed."
	fi
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT
# Exit script if an uninitialised variable is used.
#set -o nounset

# Read parameters.
while [[ "$1" != "" ]]; do
	case $1 in
	-r | --run-task )
		shift
		run_task=$1;;
	-i | --instance )
		shift
		inst=$1;;
	-d | --database )
		shift
		database=$1;;
	-v | --verbose )
		verbosity_level=$((verbosity_level + 1));;
	-s | --silent )
		verbosity_level=$((verbosity_level - 1));;
	-? | --help )
		usage;;
	* )
		arguments="$@"
		if [[ -z "$database" ]]; then
			database=${1%%.*}
		fi
		break
	esac
	shift
done

# If required parameters are missing, then exit.
if [[ -z "$inst" || -z "$database" || -z "$run_task" || -z "$arguments" ]]; then
    echo "Error: Incorrect set of parameters were passed in."
    echo
    usage
fi

# Instance number with the leading zero if it is less than 10.
inst_wlz="0$inst"
inst_wlz=${inst_wlz:${#inst_wlz}-2:2}

# Instance number - no leading zero.
inst=$(echo "$inst_wlz" | sed 's/^0//')

# Configure socket file based on MySQL directory structure.
if [[ -d /mysql/$inst_wlz ]]; then
	socket=/mysql/$inst_wlz/mysql.sock
else
	socket=/mysql_$inst_wlz/mysql.sock
fi

if [[ "$verbosity_level" -ge 3 ]]; then
	echo "************************************************************"
	echo "* Deploy MySQL Script"
	echo "* Time started:" $(date +'%F %T %Z')
	echo "************************************************************"
	echo
fi
if [[ "$verbosity_level" -ge 2 ]]; then
	echo "database:" $database
	echo "hostname:" $(hostname)
	echo "instance:" $inst
	echo "  socket:" $socket
	echo
fi

# Verify database connectivity.
echo "SELECT 1" | mysql --socket=$socket --user=dbauser -p$(cat /usr/local/bin/mysql/m${inst}_passwd.txt) --force --table --unbuffered --verbose --verbose  --database $database > /dev/null || error_exit "Error on line $LINENO. Failed database connectivity test."

if [[ "$run_task" == *v* ]]; then
	validate
fi

# Apply SQL script.
if [[ ("$run_task" == *a*) || ("$run_task" == *A*) ]]; then
	sleep 1 # Sleeping to be sure that we get a different timestamp in validation filenames.
	
	for sql_script in $arguments
	do
		if [[ "$verbosity_level" -ge 0 ]]; then
			echo "apply: ${sql_script}"
		fi
		
		ts_start=$(date '+%s.%N')
		ts_file=$(date -d "1970-01-01 ${ts_start%.*} sec GMT" +'%Y%m%d_%H%M%S')
		filename_log=$ts_file.${sql_script%.sql}.log
		filename_err=$ts_file.${sql_script%.sql}.err
		if [[ "$verbosity_level" -ge 4 ]]; then
			echo "filename_log: $filename_log"
			echo "filename_err: $filename_err"
		fi
		m${inst}c.sh < $sql_script > $filename_log 2> $filename_err || error_exit "Error on line $LINENO. SQL script execution has failed."
		ts_end=$(date '+%s.%N')
		
		check_for_errors "$filename_err"
		
		if [[ "$verbosity_level" -ge 1 ]]; then
			ts_diff=$(echo "$ts_end - $ts_start" | bc)
			echo "run_time: $ts_diff seconds"
			echo
		fi
	done
	
	if [[ "$run_task" == *a* ]]; then
		validate
	fi
fi

# Backout SQL script.
if [[ ("$run_task" == *b*) || ("$run_task" == *B*) ]]; then
	sleep 1 # Sleeping to be sure that we get a different timestamp in validation filenames.
	
	for sql_script in $arguments
	do
		sql_script=${sql_script%.sql}.backout.sql
		if [[ "$verbosity_level" -ge 0 ]]; then
			echo "back_out: ${sql_script}"
		fi
		
		ts_start=$(date '+%s.%N')
		ts_file=$(date -d "1970-01-01 ${ts_start%.*} sec GMT" +'%Y%m%d_%H%M%S')
		filename_log=$ts_file.${sql_script%.sql}.log
		filename_err=$ts_file.${sql_script%.sql}.err
		if [[ "$verbosity_level" -ge 4 ]]; then
			echo "filename_log: $filename_log"
			echo "filename_err: $filename_err"
		fi
		m${inst}c.sh < $sql_script > $filename_log 2> $filename_err || error_exit "Error on line $LINENO. SQL script execution has failed."
		ts_end=$(date '+%s.%N')
		
		check_for_errors "$filename_err"
		
		if [[ "$verbosity_level" -ge 1 ]]; then
			ts_diff=$(echo "$ts_end - $ts_start" | bc)
			echo "run_time: $ts_diff seconds"
			echo
		fi
	done
	
	if [[ "$run_task" == *b* ]]; then
		validate
	fi
fi

if [[ "$verbosity_level" -ge 3 ]]; then
	echo "************************************************************"
	echo "* Time completed:" `date +'%F %T %Z'`
	echo "************************************************************"
fi

graceful_exit
