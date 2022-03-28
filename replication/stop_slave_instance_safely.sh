#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Shell script for stopping slave database instance safely. In this case 
#	safely means that no slave temporary tables should be open when the slave 
#	database instance is stopped. Otherwise replication could get broken.
#
# Usage:
#	stop_slave_instance_safely.sh instance_number
#
# Revisions:
#	07/31/2009 - Dimitriy Alekseyev
#	Script created.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

inst=$1

# Instance number with the leading zero if it is less than 10.
inst_wlz="0$inst"
inst_wlz=${inst_wlz:${#inst_wlz}-2:2}

# Connection string.
mysql_connection="mysql --socket=/mysql_$inst_wlz/mysql.sock --user=dbauser --password=`cat /usr/local/bin/mysql/m${inst}_passwd.txt`"


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

function usage {
	# Function to show usage
	# No arguments
	echo "Usage:"
	echo "	$0 instance_number"
	echo "Example:"
	echo "	$0 7"
	clean_up
	exit 1
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT

# Check number of parameters.
if [[ $# -ne 1 ]]; then
	echo "Error: Incorrect number of parameters."
	echo
	usage
fi

echo "************************************************************"
echo "* Stop slave database instance safely"
echo "* Time started:" `date +'%F %T %Z'`
echo "************************************************************"
echo
echo "Hostname:" `hostname`
echo

# Loop while slave open temp tables is not 0.
# Should not stop MySQL slave instance until open temp tables is 0.
slave_open_tmp_tbls=1
while [ "$slave_open_tmp_tbls" != "0" ]
do
	echo
	echo "Stopping slave service..."
	$mysql_connection -e "STOP SLAVE SQL_THREAD;" || error_exit "Error on line $LINENO. 'STOP SLAVE SQL_THREAD;' failed."

	slave_running=$($mysql_connection -e "SHOW STATUS LIKE 'Slave_running'\\G;" | grep 'Value:' | gawk -F': ' '{print $2}') || error_exit "Error on line $LINENO."
	echo "slave_running: $slave_running"
	
	if [ "$slave_running" != "OFF" ] ; then
		error_exit "Error on line $LINENO. 'STOP SLAVE SQL_THREAD;' failed."
	fi

	slave_open_tmp_tbls=$($mysql_connection -e "SHOW STATUS LIKE 'Slave_open_temp_tables'\\G;" | grep 'Value:' | gawk -F': ' '{print $2}') || error_exit "Error on line $LINENO."
	echo "slave_open_tmp_tbls: $slave_open_tmp_tbls"

	if [ "$slave_open_tmp_tbls" != "0" ] ; then
		echo "There are open slave temporary tables, starting slave service..."
		$mysql_connection -e "START SLAVE;" || error_exit "Error on line $LINENO. 'START SLAVE' failed."

		echo
		echo 'Sleeping for 0.01 second(s)...'
		usleep 10000
    fi
done

echo "You can now safely stop the instance."

graceful_exit
