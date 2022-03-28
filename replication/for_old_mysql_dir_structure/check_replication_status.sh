#!/bin/bash

################################################################################
# Purpose:
#	Shell script for checking replication status.
#
# Author:
#	Dimitriy Alekseyev
#
# Usage:
#	check_replication_status.sh
#
# Revisions:
#	11/14/2006 - Dimitriy Alekseyev
#	File created.
#	12/05/2006 - Dimitriy Alekseyev
#	Updated script, so that emails are sent only once for an error. New
#	failure emails aren't sent until at least one replication check without
#	an error.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# MySQL database name.
mysql_db=orders

# MySQL instance number: 1, 2, 3, 4, ... n.
mysql_instance=5

# MySQL username.
mysql_user=dbauser

# MySQL password.
mysql_pass=surfb0ard

# Replication error indicator file.
repl_error_ind=check_replication_status.error

# Offline backup in progress indicator file.
# This file name should match the one used in MySQL slave backup script.
# Provide path and name of file.
backup_ind=/dba_share/database_servers/lv_data020/mysql_05/orders/mysql_backup


################################################################################
# Internal Variables
################################################################################

mysql_socket=/mysql_0${mysql_instance}/mysql.sock

mysql_connection="mysql --user=$mysql_user --password=$mysql_pass --socket=$mysql_socket"

PROGNAME=$(basename $0)

working_dir=$(dirname $0)


################################################################################
# Functions
################################################################################

function clean_up
{
	#####
	#	Function to remove temporary files and other housekeeping
	#	No arguments
	#####

	rm -f ${TEMP_FILE}
}

function graceful_exit
{
	#####
	#	Function called for a graceful exit
	#	No arguments
	#####

	clean_up
	exit
}

function warning_exit 
{
	#####
	# 	Function for exit due to warning
	# 	Accepts 1 argument
	#		string containing descriptive warning message
	#####

	echo
	echo "Warning:" $1
	date +'Time of warning: %F %T %Z'
	clean_up
	exit 2
}

function error_exit 
{
	#####
	# 	Function for exit due to fatal program error
	# 	Accepts 1 argument
	#		string containing descriptive error message
	#####

	if [ -e $backup_ind ] ; then
		warning_exit "Offline backup is in progress. Exiting."
	fi

	echo
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	date +'Time of error: %F %T %Z'
	clean_up
	exit 1
}

function term_exit
{
	#####
	#	Function to perform exit if termination signal is trapped
	#	No arguments
	#####

	echo "${PROGNAME}: Terminated"
	clean_up
	exit
}

function int_exit
{
	#####
	#	Function to perform exit if interrupt signal is trapped
	#	No arguments
	#####

	echo "${PROGNAME}: Aborted by user"
	clean_up
	exit
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit
trap term_exit TERM HUP
trap int_exit INT

echo "**************************************************"
echo "* Check Replication Status"
echo "* Time started:" `date +'%F %T %Z'`
echo "**************************************************"
echo
echo "Hostname:" `hostname`.`dnsdomainname`
echo "Database:" $mysql_db
echo "Instance:" $mysql_instance

if [ -e $backup_ind ] ; then
	warning_exit "Offline backup is in progress. Exiting."
fi

echo
echo "Getting current timestamp from MySQL..."
$mysql_connection -e "SELECT NOW() AS TIMESTAMP;" || error_exit "Error on line $LINENO."

# Get slave status.
echo
echo "Getting slave status..."
TEMP_FILE="$TEMP_FILE /tmp/show_slave_status.$$.tmp"
$mysql_connection -e "SHOW SLAVE STATUS\G;" > /tmp/show_slave_status.$$.tmp || error_exit "Error on line $LINENO."
cat /tmp/show_slave_status.$$.tmp || error_exit "Error on line $LINENO."

# Check if seconds behind master is null.
seconds_behind_master=`awk '$1 == "Seconds_Behind_Master:" {print $2}' /tmp/show_slave_status.$$.tmp` \
 || error_exit "Error on line $LINENO."
if [ $seconds_behind_master == "NULL" ] ; then
	# Check if this error has already been reported and if that's the case then make it a warning only.
	if [ -e $repl_error_ind ] ; then
		warning_exit "Slave server is still not replicating."
	else
		touch $working_dir/$repl_error_ind || error_exit "Error on line $LINENO. Cannot create file."
		chmod 770 $working_dir/$repl_error_ind || error_exit "Error on line $LINENO."
		error_exit "ERROR: Slave server is currently not replicating."
	fi
else
	# Delete replication error indicator file if it exists.
	rm -f $working_dir/$repl_error_ind || error_exit "Error on line $LINENO. Cannot remove file."
fi

echo
echo "**************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "**************************************************"

graceful_exit
