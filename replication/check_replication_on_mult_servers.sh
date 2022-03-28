#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Check replication status on multiple servers. Uses db_tracking to find 
#	slaves.
#
# Usage:
#	Run the script on faclsna01slap07 server where db_tracking is located.
#
# Revisions:
#	2012-08-08 - Dimitriy Alekseyev
#	Script created.
#       2013-04-01 - Dimitriy Alekseyev
#	Fixed script by adding -N option to mysql client.
#
# Todo:
#
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`


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
	exit 1
}

function int_exit {
	# Function to perform exit if interrupt signal is trapped
	# No arguments
	echo "${progname}: Aborted by user"
	clean_up
	exit 1
}

function usage {
	# Function to show usage
	# No arguments
	echo "USAGE"
	echo "	$progname port"
	echo
	echo "EXAMPLE"
	echo "	$progname 3365"

	clean_up
	exit 1
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT

echo "************************************************************"
echo "* Check Replication Status"
echo "* Time started:" `date +'%F %T %Z'`
echo "************************************************************"
echo
echo "Hostname:" `hostname`
echo

echo "USE db_tracking; SELECT host_name, port, GROUP_CONCAT(db_name), GROUP_CONCAT(db_environment) FROM vw_actv_host_inst_db WHERE rdbms = 'mysql' AND db_role = 'ha' AND network_env = 'prod' GROUP BY host_name, port ORDER BY db_environment;" | m13.sh -BN | while read line; do set -- $line; echo $1:$2 $3; echo "$(echo 'SHOW SLAVE STATUS\G' | mysql -h $1 -P $2 -u dbauser -psurfb0ard | egrep 'Slave_IO_Running|Slave_SQL_Running|Seconds_Behind_Master')"; echo; done

echo
echo "************************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "************************************************************"

graceful_exit
