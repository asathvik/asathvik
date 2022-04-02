#!/bin/sh
################################################################################
#
# Author:
#       Anil Alpati
#
# Purpose:
#       Shell script for getting MySQL Database Size from DB level
#
# Usage:
#      ./mysql_get_db_size.sh
#
# Date Created:
#       28/01/2015
#
################################################################################
# Constants and Global Variables
################################################################################
. /var/mysql/dba/environment/global_stuff

PROGNAME=$(basename $0)

working_dir=$(dirname $0)
myuser
mypasswd

HOST=`hostname`
port=3306
################################################################################
# Functions
################################################################################
function clean_up
{
        #####
        #       Function to remove temporary files and other housekeeping
        #       No arguments
        #####
        echo
        rm -f ${TEMP_FILE}
        echo
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
echo "Content-type: text/html"
echo 'subject: AUTOREPORT: MySQL Query Results'
echo "To: anil.alpati@apollo.edu"
echo "<html><head><title>Query Rresults"
echo "</title></head><body>"
echo "<h3> <font color="blue"> MySQL Query Results </font> </h3>"
echo "<pre>"
echo "************************************************************"
echo
echo "* Time Started:" `date +'%F %T %Z'`
echo
echo "************************************************************"

        echo
        #echo "<b> <font color="green">Hostname: $HOST ,Port: $port </font></b>"
        echo "SELECT 1" | mysql   --host=$HOST --user=$USER --password=$PASSWD --port=$port --force --table --unbuffered --verbose --verbose > /dev/null 2> /dev/null || error_exit "Error on line $LINENO. Failed database connectivity test on host[$HOST]:[$port]"
        #echo "SELECT NOW();USE DISCUSSIONS;SELECT DATABASE();SELECT NOW();" | mysql   --host=$HOST --user=$USER --password=$PASSWD --port=$port --force --table --html 2> /dev/null || error_exit "Error on line $LINENO. Failed to fetch the resultset."
#        mysql   --host=$HOST --user=$USER --password=$PASSWD --port=$port --force --table --html < q.sql 2> /dev/null || error_exit "Error on line $LINENO. Failed to fetch the resultset."
        mysql   --host=$HOST --user=$USER --password=$PASSWD --port=$port --force -vvv --html   < q.sql 2> /dev/null || error_exit "Error on line $LINENO. Failed to fetch the resultset."

echo
echo "**************************************************"
echo
echo "* Time Completed:" `date +'%F %T %Z'`
echo
echo "**************************************************"
echo "</pre></body></html>"
graceful_exit

