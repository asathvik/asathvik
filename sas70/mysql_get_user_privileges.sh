#!/bin/bash
################################################################################
#
# Author:
#	Ravi Koka
#
# Purpose:
#	
#
# Revisions:
#	10/22/2009 - Ravi Koka
#	Created script. Modified to allow the MySQL console 
#	10/22/2009 - Dimitriy Alekseyev
#	Added host name to the report.
#	11/01/2010 - Dimitriy Alekseyev
#	Added working directory variable. Added show grants SQL to SQL 
#	statement. Made other improvements.
################################################################################

# Program name.
progname=`basename $0`

# Working directory.
workdir=`dirname $0`

# Data Center
dc=$1

# Network Environment
netenv=$2

# Server and port list.
server_port_list=mysql_server_port_list.txt

# Input SQL script.
sql_script=mysql_get_user_privileges.sql

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

function error_exit {
	# Function for exit due to fatal program error
	# Accepts 1 argument
	#	string containing descriptive error message
	echo "${progname}: ${1:-"Unknown Error"}" 1>&2
	clean_up
	exit 1
}

################################################################################
# Program starts here
################################################################################

if [[ -z "$dc" || -z "$netenv" ]]; then
	error_exit "Error on line $LINENO. Not all required parameters were provided."
fi

echo "************************************************************"
echo "SCRIPT START"
date +"Time: %F %T %Z"
echo "************************************************************"

for server_port in `cat $workdir/$server_port_list`
do
	server=`echo $server_port | awk -F: '{ print $1 }'`
	ip=`echo $server_port | awk -F: '{ print $2 }'`
	port=`echo $server_port | awk -F: '{ print $3 }'`
	datacenter=`echo $server_port | awk -F: '{ print $4 }'`
	network=`echo $server_port | awk -F: '{ print $5 }'`
	user=`echo $server_port | awk -F: '{ print $6 }'`
	pw=`echo $server_port | awk -F: '{ print $7 }'`

	if [[ "$dc" = "$datacenter" && "$netenv" = "$network" ]]; then
		echo
		echo "************************************************************"
		echo "Server: $server"
		echo "IP:     $ip"
		echo "Port:   $port"
		echo "************************************************************"
		echo

		# MySQL connection string.
		myc="mysql --host=$ip --port=$port --user=$user --password=$pw"
		
		$myc --table -v -e 'SHOW DATABASES; SELECT host, user, password FROM mysql.user;'
		echo
		$myc -Bse "SELECT CONCAT('SHOW GRANTS FOR \'', user ,'\'@\'', host, '\';') FROM mysql.user" | $myc -Bsr | sed 's/$/;/g'
	fi
done

echo
echo "************************************************************"
echo "SCRIPT END"
date +"Time: %F %T %Z"
echo "************************************************************"
