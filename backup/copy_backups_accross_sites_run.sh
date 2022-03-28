#!/bin/bash

################################################################################
# Purpose:
#	Shell script for running another script and sending an email about
#	sucess or failure of it.
#
# Author:
#	Dimitriy Alekseyev
#
# Usage:
#	copy_backups_to_secondary_san_run.sh
#
# Revisions:
#	06/01/2006 - Dimitriy Alekseyev
#		File created
#	09/29/2006 - Dimitriy Alekseyev
#		Added backup script and log variables.
#	10/13/2006 - Dimitriy Alekseyev
#		Changed the way it checks for errors in backup script that gets
#		executed by this script.
#	10/11/2007 - Dimitriy Alekseyev
#		Updated script to fit new purpose.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

PROGNAME=$(basename $0)

WORKING_DIR=$(dirname $0)

EMAIL_SUBJECT='Copy MySQL backups accross sites'

EMAIL_ADDRESS='dalekseyev@corelogic.com'

BACKUP_SCRIPT=copy_backups_accross_sites.sh

LOG=logs/`date +'%F'`_copy_backups_accross_sites.log


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

./$BACKUP_SCRIPT > $LOG 2>&1
status=$?
chmod 775 $LOG
chown :dba $LOG

if [ "$status" = "0" ]; then
	EMAIL_SUBJECT="AUTOREPORT: Success - $EMAIL_SUBJECT"
else
	EMAIL_SUBJECT="AUTOREPORT: Failure - $EMAIL_SUBJECT"
fi

mail -s "$EMAIL_SUBJECT" $EMAIL_ADDRESS < $LOG || error_exit "Error on line $LINENO. Cannot send email."

graceful_exit
