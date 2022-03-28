#!/bin/bash

################################################################################
# Purpose:
#	Shell script for running another script and sending an email about
#	sucess or failure.
#
# Author:
#	Dimitriy Alekseyev
#
# Usage:
#	check_replication_run.sh check_replication.ini
#
# Revisions:
#	11/14/2006 - Dimitriy Alekseyev
#	File created.
#	12/05/2006 - Dimitriy Alekseyev
#	Cleaned up the script a little.
#	12/29/2009 - Dimitriy Alekseyev, Ravi Koka
#	Modified to use configuration file (*.ini).
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Configuration file to use.
config_file=$1

script="/dba_share/scripts/mysql/replication/check_replication.sh $config_file"

log=check_replication.log


################################################################################
# Internal Variables
################################################################################

PROGNAME=$(basename $0)

WORKING_DIR=$(dirname $config_file)


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

function error_exit 
{
	#####
	# 	Function for exit due to fatal program error
	# 	Accepts 1 argument
	#		string containing descriptive error message
	#####

	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
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

cd $WORKING_DIR || error_exit "Error on line $LINENO. Cannot change directory."

# Check if configuration file is readable.
if [[ ! -r $config_file ]]; then
	error_exit "Error on line $LINENO. Cannot read from configuration file."
fi

# Read configuration file.
email_subject=$(cat $config_file | grep '^email_subject=' | awk -F'=' '{print $2}')
email_address=$(cat $config_file | grep '^email_address=' | awk -F'=' '{print $2}')

$script > $log 2>&1
status=$?
chmod 660 $log
chown :dba $log

if [ "$status" == "1" ]; then
	email_subject="AUTOREPORT: Failure - $email_subject"
	mail -s "$email_subject" $email_address < $log || error_exit "Error on line $LINENO. Cannot send email."
fi

graceful_exit
