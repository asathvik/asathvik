#!/bin/bash
################################################################################
# Purpose:
#      This script is used to get Database table counts from MySQL DB 
#
# Author:
#       Anil A
#
# Usage:
#
#  ./mysql_get_db_table_counts.sh [all]
#  ./mysql_get_db_table_counts.sh [single] [db_name]
#
################################################################################


################################################################################
# Constants and Global Variables
################################################################################
. /var/mysql/dba/environment/global_stuff

PROGNAME=$(basename $0)

working_dir=$(dirname $0)
 
echo $LOGS
myuser
mypasswd

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

if [[ $# -le 0 ]];then
       
	echo 'Usage :'
 	echo
	echo '  ./mysql_get_db_table_counts.sh [all]'
	echo '  ./mysql_get_db_table_counts.sh [single] [db_name]'
	error_exit "Error on line $LINENO Please pass required parameters"	 
fi

################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit
trap term_exit TERM HUP
trap int_exit INT

# Database Directory
inst_dir=/u01/mysql_data
# Socket file.
mysql_socket=$inst_dir/mysql.sock

# Date & Time
date_time=`date +'%F_%H_%M'`
echo $date_time
# Port
mysql_port=3306

# Verify database connectivity.
#echo "SELECT 1" | mysql   --host=`hostname` --user=$USER --password=$PASSWD --port=$mysql_port --force --table --unbuffered --verbose --verbose > /dev/null || error_exit "Error on line $LINENO. Failed database connectivity test."

myc="mysqlshow --host=`hostname` --user=$USER --password=$PASSWD --port=$mysql_port"


echo "**************************************************"
echo
echo "* Script Execution Started"
echo "* Time started: `date +'%F %T %Z'`"
echo
echo "**************************************************"
echo

inputparam=$1

if [[ $inputparam == "all" ]]; then

mydblist=$(mysql -h`hostname` -u$USER -p$PASSWD -P$mysql_port -e "use information_schema;select distinct TABLE_SCHEMA from TABLES where TABLE_SCHEMA not in ('mysql','performance_schema','temp','innodb','information_schema') order by 1;" |grep -v TABLE_SCHEMA |awk '{print $1}')

for dbs in $mydblist
do 
	#$myc --verbose  --count -t  $dbs | tee -a $dbs.DBtable.counts.$date_time.log 
	$myc --verbose  --count -t  $dbs | tee -a $LOGS/$inputparam.databases_rowcounts.`date -I`.log
done
$MAIL -s "`hostname` :Database[$inputparam] Table Row Counts " anil.alpati@apollo.edu < $LOGS/$inputparam.databases_rowcounts.`date -I`.log

elif [[ $inputparam == "single" ]]; then
	
	echo "Single Database table counts"
	if [[ -z $2 ]];then
	error_exit "Error on line $LINENO please input DB name as second argument"
	fi	
	$myc --verbose  --count -t  $2 | tee $LOGS/$inputparam.$2_rowcounts.`date -I`.log
	$MAIL -s "`hostname` :Database[$2] Table Row Counts " $DBA < $LOGS/$inputparam.$2_rowcounts.`date -I`.log
fi

echo
echo "**************************************************"
echo
echo "* Time completed: `date +'%F %T %Z'`"
echo
echo "**************************************************"
echo 

graceful_exit
