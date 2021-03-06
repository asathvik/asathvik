#!/bin/bash

################################################################################
# Purpose:
#	Shell script for running backup script and sending an email about
#	sucess or failure of the backup.
#
# Author:
#	Anil A
#
# Usage:
#	mysql_backup_run.sh
#
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

PROGNAME=$(basename $0)
WORKING_DIR=$(dirname $1)

# Configuration file to use.
config_file=$1

backup_script="/dba_share/scripts/mysql/backup/mysql_backup.sh $config_file"
log_dir=logs
log_file="mysql_backup_`date +'%Y%m%d_%H%M%S'`.log"


################################################################################
# Functions
################################################################################

function clean_up
{
	# Function to remove temporary files and other housekeeping
	# No arguments
	rm -f ${TEMP_FILE}
}

function graceful_exit
{
	# Function called for a graceful exit
	# No arguments
	clean_up
	exit
}

function error_exit 
{
	# Function for exit due to fatal program error
	# Accepts 1 argument
	#	string containing descriptive error message
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	clean_up
	exit 1
}

function term_exit
{
	# Function to perform exit if termination signal is trapped
	# No arguments
	echo "${PROGNAME}: Terminated"
	clean_up
	exit
}

function int_exit
{
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

cd $WORKING_DIR || error_exit "Error on line $LINENO. Cannot change directory."

# If log directory does not exist then create it.
if [[ ! -d $log_dir ]]; then
	mkdir $log_dir
	chmod 770 $log_dir
fi

# Check if configuration file is readable.
if [[ ! -r $config_file ]]; then
	error_exit "Error on line $LINENO. Cannot read from configuration file."
fi

# Read configuration file.
email_subject=$(cat $config_file | grep '^email_subject=' | awk -F'=' '{print $2}')
email_address=$(cat $config_file | grep '^email_address=' | awk -F'=' '{print $2}')

log_dir=logs
log_file="mysql_backup_`date +'%Y%m%d_%H%M%S'`.log"

touch $log_dir/$log_file
chmod 660 $log_dir/$log_file
$backup_script > $log_dir/$log_file 2>&1
status=$?

if [ "$status" = "0" ]; then
	email_subject="AUTOREPORT: Success - $email_subject"
else
	email_subject="AUTOREPORT: Failure - $email_subject"
fi

mail -s "$email_subject" $email_address < $log_dir/$log_file || error_exit "Error on line $LINENO. Cannot send email."

graceful_exit
