#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
# Purpose:
#	Plugin for Nagios to check if MySQL instance is alive.
# Usage:
#	Run script with -? or --help option to get usage information.
# Revisions:
#	06/08/2007 - Dimitriy Alekseyev
#	File created.
#	06/19/2007 - Dimitriy Alekseyev
#	Added more functionality and modified the script so that it accepts
#	parameters like host, port, username, and password.
#	07/10/2007 - Dimitriy Alekseyev
#	Modified script so that it shows the error message from MySQL when a
#	critical status is returned.
#	01/17/2008 - Dimitriy Alekseyev
#	Added warning and critical time parameters. If not connected within 
#	warning or critical time return warning or critical status respectively.
#	Added code to return performance metrics.
#	07/09/2008 - Dimitriy Alekseyev
#	Removed skip-reconnect option.
################################################################################


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
	# Accepts 1 argument
	#	integer containing exit status code
	clean_up
	exit $1
}

function error_exit {
	# Function for exit due to fatal program error
	# Accepts 1 argument
	#	string containing descriptive error message
	echo "$STATUS_UNKNOWN | ${progname}: ${1:-"Unknown Error"}" 1>&2
	clean_up
	exit $STATE_UNKNOWN
}

function term_exit {
	# Function to perform exit if termination signal is trapped
	# No arguments
	echo "$STATUS_UNKNOWN | ${progname}: Terminated"
	clean_up
	exit $STATE_UNKNOWN
}

function int_exit {
	# Function to perform exit if interrupt signal is trapped
	# No arguments
	echo "$STATUS_UNKNOWN | ${progname}: Aborted by user"
	clean_up
	exit $STATE_UNKNOWN
}

function usage {
	# Function to show usage
	# No arguments
	echo "$STATUS_UNKNOWN - Either usage information was requested or not all required parameters were passed in."
	echo
	echo "USAGE"
	echo "	$progname OPTIONS"
	echo
	echo "SYNOPSIS"
	echo "	$progname {-h hostname -P pnum -u uname -p pass} | [-?|--help]"
	echo
	echo "OPTIONS"
	echo "	-h|--host hostname"
	echo "		Connect to the specified host."
	echo
	echo "	-P|--port pnum"
	echo "		Use the specified port number for connecting to the database server."
	echo
	echo "	-u|--user uname"
	echo "		Use the specified user name for logging in to the server."
	echo
	echo "	-p|--password pass"
	echo "		Use the specified password for logging in to the server."
	echo
	echo "	-w|--warn_time warntime"
	echo "		Returning warning status if time to connect takes longer than warning time."
	echo "		Warning time has to be lower than critical time. Default = 15 seconds."
	echo
	echo "	-c|--crit_time crittime"
	echo "		Returning critical status if time to connect takes longer than critical time."
	echo "		Critical time has to be higher than warning time. Default = 30 seconds."
	echo
	echo "EXAMPLE"
	echo "	$progname --host testdb3 --port 3310 --user dbmon --password secret"

	clean_up
	exit $STATE_UNKNOWN
}


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# MySQL client path.
mysql=/usr/bin/mysql

# Return state codes.
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Return status messages.
STATUS_OK="OK"
STATUS_WARNING="WARNING"
STATUS_CRITICAL="CRITICAL"
STATUS_UNKNOWN="UNKNOWN"

tmp1=/tmp/$progname.$$.tmp1
tmp2=/tmp/$progname.$$.tmp2
tmp_file="$tmp1 $tmp2"


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit
trap term_exit TERM HUP
trap int_exit INT

while [ "$1" != "" ]; do
    case $1 in
        -h | --host )
            shift
            host=$1
            ;;
        -p | --password )
            shift
            password=$1
            ;;
        -P | --port )
            shift
            port=$1
            ;;
        -u | --user )
            shift
            user=$1
            ;;
        -w | --warn_time )
            shift
            warn_time=$1
            ;;
        -c | --crit_time )
            shift
            crit_time=$1
            ;;
        -? | --help | * )
            usage
    esac
    shift
done

# If required parameters are missing, then exit.
if [[ -z "$host" || -z "$port" || -z "$user" || -z "$password" ]]; then
    usage
fi

# Set default values for warning and critical time if they are not set.
warn_time=${warn_time:-15}
crit_time=${crit_time:-30}

if [[ "$crit_time" -le "$warn_time" ]]; then
	usage
fi

start_time=`date '+%s'`

(
	$mysql --host=$host --port=$port --user=$user --password="$password" \
	 --execute="SELECT 1;" &> $tmp1
	
	# Save exit status from last command into temporary file.
	echo $? > $tmp2
) &
child_pid=$!

check_time=`date '+%s'`
while [[ `expr "$check_time" - "$start_time"` -lt "$crit_time" ]]; do
	if [[ `ps | grep $child_pid | grep -v grep | wc -l` -eq 0 ]]; then
		break
	fi

	sleep 1
	check_time=`date '+%s'`
done

# Check if MySQL child processes are still running, then kill them.
if [[ `ps | grep $child_pid | grep -v grep | wc -l` -ne 0 ]]; then
	kill -9 $child_pid
	echo -e "$STATUS_CRITICAL - Port: $port. Error: Time to connect has exceeded critical time."
	graceful_exit $STATE_CRITICAL
fi

# Check if MySQL query returned a result.
if [[ "`head -1 $tmp2`" -eq 0 ]]; then
	connect_time=$((check_time - start_time))

	# If the query returned within warning time, then return ok status and state.
	if [[ "$connect_time" -le "warn_time" ]]; then
		echo "$STATUS_OK - Time to connect: $connect_time seconds. Port: $port. | connect_time=$connect_time"
		graceful_exit $STATE_OK
	fi
	# If the query returned within critical time, then return warning status and state.
	if [[ "$connect_time" -le "crit_time" ]]; then
		echo "$STATUS_WARNING - Time to connect: $connect_time seconds. Port: $port. | connect_time=$connect_time"
		graceful_exit $STATE_WARNING
	fi
fi

# Return critical status and state.
echo -e "$STATUS_CRITICAL - Database: $database. Error: `head -1 $tmp1`"
graceful_exit $STATE_CRITICAL
