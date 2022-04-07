#!/bin/sh
################################################################################
# Purpose:
#       Shell script for invoking email for retrieving MySQL Database Size script
#
# Date Created:
#       28/01/2015
#
################################################################################
# Internal Variables
################################################################################
. /var/mysql/dba/environment/global_stuff

PROGNAME=$(basename $0)

WORKING_DIR=$(dirname $0)

script=/u01/accts/a.aalpati/scripts/sendemail.sh

log=/u01/accts/a.aalpati/scripts/sendemail.log
################################################################################
# Functions
################################################################################


function clean_up
{
        #####
        #       Function to remove temporary files and other housekeeping
        #       No arguments
        #####

        rm -f ${TEMP_FILE}
}

function graceful_exit
{
        #####
        #       Function called for a graceful exit
        #       No arguments
        #####

        clean_up
        exit
}

function error_exit
{
        #####
        #       Function for exit due to fatal program error
        #       Accepts 1 argument
        #               string containing descriptive error message
        #####

        echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        clean_up
        exit 1
}

function term_exit
{
        #####
        #       Function to perform exit if termination signal is trapped
        #       No arguments
        #####

        echo "${PROGNAME}: Terminated"
        clean_up
        exit
}

function int_exit
{
        #####
        #       Function to perform exit if interrupt signal is trapped
        #       No arguments
        #####

        echo "${PROGNAME}: Aborted by user"
        clean_up
        exit
}


SENDMAIL="/usr/sbin/sendmail"
email_address="anil.alpati@apollo.edu"
$script > $log 2>&1
status=$?
chmod 660 $log
if [ "$status" == "0" ]; then
        email_subject="AUTOREPORT: MySQL Query Results"
        $SENDMAIL -t "$email_subject" $email_address < $log || error_exit "Error on line $LINENO. Cannot send email."
        #cat $log | $SENDMAIL -i -v -- $email_address || error_exit "Error on line $LINENO. Cannot send email."

fi

graceful_exit

