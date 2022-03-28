#!/bin/bash
################################################################################
# Purpose:
#	Shell script for checking replication status.
#
# Author:
#	Dimitriy Alekseyev
#
# Usage:
#	check_replication_status.sh config_file.ini
#
# Revisions:
#	11/14/2006 - Dimitriy Alekseyev
#	File created.
#	12/05/2006 - Dimitriy Alekseyev
#	Updated script, so that emails are sent only once for an error. New
#	failure emails aren't sent until at least one replication check without
#	an error.
#	12/29/2009 - Dimitriy Alekseyev, Ravi Koka
#	Modified to use configuration file (*.ini).
#	02/10/2012 - Dimitriy Alekseyev
#	Made minor changes to display of db name and host name.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Configuration file to use.
config_file=$1

PROGNAME=$(basename $0)

working_dir=$(dirname $config_file)


################################################################################
# Functions
################################################################################

function clean_up {
	# Function to remove temporary files and other housekeeping
	# No arguments
	rm -f ${TEMP_FILE}
}

function graceful_exit {
	# Function called for a graceful exit
	# No arguments
	clean_up
	exit
}

function warning_exit {
	# Function for exit due to warning
	# Accepts 1 argument
	#	string containing descriptive warning message
	echo
	echo "Warning:" $1
	date +'Time of warning: %F %T %Z'
	clean_up
	exit 2
}

function error_exit {
	# Function for exit due to fatal program error
	# Accepts 1 argument
	#	string containing descriptive error message
	if [ -e $backup_ind ] ; then
		warning_exit "Offline backup is in progress. Exiting."
	fi

	echo
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	date +'Time of error: %F %T %Z'
	clean_up
	exit 1
}

function term_exit {
	# Function to perform exit if termination signal is trapped
	# No arguments
	echo "${PROGNAME}: Terminated"
	clean_up
	exit
}

function int_exit {
	# Function to perform exit if interrupt signal is trapped
	# No arguments
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

# Check if configuration file is readable.
if [[ ! -r $config_file ]]; then
	error_exit "Error on line $LINENO. Cannot read from configuration file."
fi


# Read configuration file.

# Excel formula for generating below code:
# =A1 & "=$(cat $config_file | grep '^" & A1 & "=' | awk -F'=' '{print $2}')"

backup_ind=$(cat $config_file | grep '^backup_ind=' | awk -F'=' '{print $2}')
email_address=$(cat $config_file | grep '^email_address=' | awk -F'=' '{print $2}')
email_subject=$(cat $config_file | grep '^email_subject=' | awk -F'=' '{print $2}')
mysql_db=$(cat $config_file | grep '^mysql_db=' | awk -F'=' '{print $2}')
mysql_instance=$(cat $config_file | grep '^mysql_instance=' | awk -F'=' '{print $2}')
mysql_pass=$(cat $config_file | grep '^mysql_pass=' | awk -F'=' '{print $2}')
mysql_user=$(cat $config_file | grep '^mysql_user=' | awk -F'=' '{print $2}')
repl_error_ind=$(cat $config_file | grep '^repl_error_ind=' | awk -F'=' '{print $2}')

if [[ -z "$backup_ind" || -z "$email_address" || -z "$email_subject" || -z "$mysql_db" || -z "$mysql_instance" || -z "$mysql_pass" || -z "$mysql_user" || -z "$repl_error_ind" ]]; then
	error_exit "Error on line $LINENO. Not all required configuration options were provided."
fi


# Instance number with the leading zero if it is less than 10.
inst_wlz="0$mysql_instance"
inst_wlz=${inst_wlz:${#inst_wlz}-2:2}

# Instance directory.
inst_dir=/mysql/$inst_wlz

# Socket file.
mysql_socket=$inst_dir/mysql.sock

# Connection string.
mysql_connection="mysql --user=$mysql_user --password=$mysql_pass --socket=$mysql_socket"

echo "**************************************************"
echo "* Check Replication Status"
echo "* Time started:" `date +'%F %T %Z'`
echo "**************************************************"
echo
echo "Database:" $mysql_db
echo "Hostname:" `hostname`
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
