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
#	check_replication_status_run.sh
#
# Revisions:
#	11/14/2006 - Dimitriy Alekseyev
#	File created.
#	12/05/2006 - Dimitriy Alekseyev
#	Cleaned up the script a little.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

EMAIL_SUBJECT='lv_data020 orders slave - Check Replication Status'

EMAIL_ADDRESS='dalekseyev@corelogic.com dba@corelogic.com'

SCRIPT=check_replication_status.sh

LOG=check_replication_status.log


################################################################################
# Internal Variables
################################################################################

PROGNAME=$(basename $0)

WORKING_DIR=$(dirname $0)


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

./$SCRIPT > $LOG 2>&1
status=$?
chmod 770 $LOG
chown :dba $LOG

if [ "$status" == "1" ]; then
	EMAIL_SUBJECT="AUTOREPORT: Failure - $EMAIL_SUBJECT"
	mail -s "$EMAIL_SUBJECT" $EMAIL_ADDRESS < $LOG || error_exit "Error on line $LINENO. Cannot send email."
fi

graceful_exit
