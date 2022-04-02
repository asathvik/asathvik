#!/bin/bash

################################################################################
# Purpose:
#       Shell script for running another script and sending an email about
#       sucess or failure.
#
# Author:
#       Anil A
#
# Usage:
#       san_read_write_test_run.sh
#
################################################################################
# Constants and Global Variables
################################################################################

script="/var/mysql/dba/scripts/san_read_write_test.sh"

log=san_check.log


################################################################################
# Internal Variables
################################################################################

PROGNAME=$(basename $0)

WORKING_DIR=$(dirname $script)


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


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit
trap term_exit TERM HUP
trap int_exit INT

cd $WORKING_DIR || error_exit "Error on line $LINENO. Cannot change directory."

# Read configuration file.
email_address="anil.alpati@apollo.edu"

$script > $log 2>&1
chmod 660 $log

status=`cat $log | grep -i fail`

if [[ ! -z $status ]];then
        email_subject="AUTOREPORT: SAN Status check /u01/mysql_data and /log $email_address"
        mail -s "$email_subject" $email_address < $log || error_exit "Error on line $LINENO. Cannot send email."
fi


graceful_exit





