#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Generate MySQL monthly security report.
#
# Usage:
#	nohup ./mysql_monthly_security_report.sh > mysql_monthly_security_report.log &
#
# Revisions:
#	11/01/2010 - Dimitriy Alekseyev
#	Script created.
#	01/10/2011 - Dimitriy Alekseyev
#	Made improvements to the script. More detail is now provided in the 
#	log. Automated the process some more, so that the zipping is done 
#	automatically.
#   20/08/2013 - Anil Kumar Alpati
#	Made changes to exclude LVDC servers reports. LVDC has been decommissioned 
#   and we no longer have any databases there.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# sas70 directories in different data centers.
satc_dir=/dba_share/scripts/mysql/sas70
#lvdc_dir=/satc_dba_share/scripts/mysql/sas70

# Date info.
date=$(date +'%F %T %Z')
year=$(date +'%Y' -d "$date")
month_numeric=$(date +'%m' -d "$date")
month_abbr=$(date +'%b' -d "$date")

# Reports subdirectory.
reports_dir=audit_reports/${year}_${month_numeric}

# Server and port list.
server_port_list=mysql_server_port_list.txt

# MySQL client connection to db_tracking database.
myc_dbtrack="mysql --host=10.183.28.25 --port=3370 --connect_timeout=30 --user=dbauser --password=surfb0ard --database=db_tracking"

tmp_file=


################################################################################
# Functions
################################################################################

function clean_up {
	# Function to remove temporary files and other housekeeping
	# No arguments
	rm -f ${tmp_file}
}

function graceful_exit {
	# Function called for a graceful exit
	# No arguments
	clean_up
	exit
}

function error_exit {
	# Function for exit due to fatal program error
	# Accepts 1 argument
	#	string containing descriptive error message
	echo "${progname}: ${1:-"Unknown Error"}" 1>&2
	clean_up
	exit 1
}

function term_exit {
	# Function to perform exit if termination signal is trapped
	# No arguments
	echo "${progname}: Terminated"
	clean_up
	exit
}

function int_exit {
	# Function to perform exit if interrupt signal is trapped
	# No arguments
	echo "${progname}: Aborted by user"
	clean_up
	exit
}

function usage
{
	# Function to show usage
	# No arguments
	echo "Either usage information was requested or not all required parameters were passed in."
	echo
	echo "USAGE"
	echo "	$progname port"
	echo
	echo "EXAMPLE"
	echo "	$progname 3365"

	clean_up
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT
# Exit script if an uninitialised variable is used.
set -o nounset

# Check if user is mysql.
if [[ "`id -un`" != mysql ]]; then
	error_exit "Error on line $LINENO. You have to be 'mysql' user."
fi

echo "************************************************************"
echo "* Generating MySQL Monthly Security Report"
echo "* Time started:" $date
echo "************************************************************"
echo
echo "Hostname:" `hostname`
echo

cd $satc_dir || error_exit "Error on line $LINENO. Could not perform action."

echo "Getting a list of servers and ports..."
$myc_dbtrack -se "
SELECT
	CONCAT_WS(':', h.host_name, h.host_ip, i.port, h.host_data_center, h.network_env, 'dbauser', 'surfb0ard')
FROM
	host AS h, instance AS i
WHERE
	h.host_id = i.host_id
	AND h.host_active_yn = 'y'
	AND i.instance_active_yn = 'y'
	AND i.rdbms = 'mysql'
;" > $satc_dir/$server_port_list
chmod 660 $satc_dir/$server_port_list
echo "Done."
echo

mkdir --parents $reports_dir || error_exit "Error on line $LINENO. Could not create directory."
chmod 770 $reports_dir

echo "Generating security report for SATC prod network..."
$satc_dir/mysql_get_user_privileges.sh satc prod > $satc_dir/$reports_dir/mysql_security_report_satc_prod_network.txt
chmod 660 $satc_dir/$reports_dir/mysql_security_report_satc_prod_network.txt
echo "Security report is located here: $satc_dir/$reports_dir/mysql_security_report_satc_prod_network.txt"
echo "Done."
echo

echo "Generating security report for SATC qa network..."
# Due to firewalls, we are making two ssh hops.
ssh faclsna01sldb05 ssh faclsna01smsd05 $satc_dir/mysql_get_user_privileges.sh satc qa > $satc_dir/$reports_dir/mysql_security_report_satc_qa_network.txt
chmod 660 $satc_dir/$reports_dir/mysql_security_report_satc_qa_network.txt
echo "Security report is located here: $satc_dir/$reports_dir/mysql_security_report_satc_qa_network.txt"
echo "Done."
echo

#echo "Generating security report for LVDC prod network..."
# Making ssh connection to LVDC server.
#ssh 192.168.140.138 $lvdc_dir/mysql_get_user_privileges.sh lvdc prod > $satc_dir/$reports_dir/mysql_security_report_lvdc_prod_network.txt
#chmod 660 $satc_dir/$reports_dir/mysql_security_report_lvdc_prod_network.txt
#echo "Security report is located here: $satc_dir/$reports_dir/mysql_security_report_lvdc_prod_network.txt"
#echo "Done."
#echo

echo "Zipping reports..."
cd $satc_dir/$reports_dir || error_exit "Error on line $LINENO. Could not perform action."
#zip "MySQL_Security_Report_${year}_${month_abbr}.zip" mysql_security_report_lvdc_prod_network.txt mysql_security_report_satc_prod_network.txt mysql_security_report_satc_qa_network.txt
zip "MySQL_Security_Report_${year}_${month_abbr}.zip" mysql_security_report_satc_prod_network.txt mysql_security_report_satc_qa_network.txt
echo "Done."
#echo "Zipped file has been moved to the following directory: "
echo

echo "************************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "************************************************************"

graceful_exit
