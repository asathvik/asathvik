#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Run any task on multiple servers. Uses db_tracking to find servers.
#
# Usage:
#	Make a copy of this script, modify copied version, and run copied 
#	script on faclsna01slap07 server where db_tracking is located. Be sure 
#	to test your script well, for example first run commands that do not 
#	modify anything, such as "hostname" or "date".
#
# Revisions:
#	2012-08-08 - Dimitriy Alekseyev
#	Script created.
#	2012-11-27 - Dimitriy Alekseyev
#	Script copied from check_replication_on_mult_servers.sh to make it more 
#	generic.
#	2013-03-19 - Dimitriy Alekseyev
#	Revised script to add usage info and an option to run in "query-only" 
#	mode.
#	2013-04-01 - Dimitriy Alekseyev
#	Converted script from run_mysql_task_on_mult_servers.sh to 
#	run_bash_task_on_mult_servers.sh.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# db_tracking connection.
dbt=m13.sh

# db_tracking query - find a list of servers and databases to run a task against.
db_tracking_query="SELECT host_name FROM vw_actv_host_inst_db WHERE host_data_center='satc' AND rdbms = 'mysql' AND network_env = 'prod' /*AND db_environment = 'prod'*/ AND host_name NOT IN ('faclsna01vbld01', 'faclsna01slap07', 'faclsna01sldb04', 'faclsna01slsd03') AND host_name NOT LIKE 'faclsna01sldb%' GROUP BY host_name ORDER BY host_name;"
#db_tracking_query="SELECT * FROM vw_actv_host_inst_db WHERE host_data_center='satc' AND rdbms = 'mysql' AND db_environment <> 'prod' GROUP BY host_name ORDER BY host_name;"

# Informational output.
info="hostname:\$host_name"

# Command to execute against each server.
read -r -d '' cmd << COMMAND
if ! grep '. /dba_share/scripts/bash/profile/dba_global_profile.sh' /etc/profile.local >/dev/null
then
	echo 'MISSING ENTRY'
	echo '. /dba_share/scripts/bash/profile/dba_global_profile.sh' >> /etc/profile.local
else
	echo 'GOOD'
fi
COMMAND


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
	echo "USAGE
	$progname [options]

EXAMPLE
	$progname

OPTIONS
	-q, --query-only
		Query db_tracking database only, do not execute any tasks.
	-?, --help
		Show this help."

	clean_up
	exit 1
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT

# Read parameters.
while [ "$1" != "" ]; do
	case $1 in
	-q | --query-only )
		query_only=true;;
	-"?" | --help )
		usage;;
	* )
		error_exit "ERROR: Incorrect parameters were passed in. Please check usage."
	esac
	shift
done

echo "************************************************************"
echo "* Time started:" `date +'%F %T %Z'`
echo "************************************************************"

echo
echo "db_tracking query:"
echo "$db_tracking_query"
echo
echo "db_tracking query result:"
$dbt -B -D db_tracking -e "$db_tracking_query"
echo
echo "Informational output:"
echo "$info"
echo
echo "Bash command:"
echo "$cmd"

if [[ $query_only != true ]]; then
	echo
	echo
	echo
	#$dbt -B -N -D db_tracking -e "$db_tracking_query" | while read line; do set -- $line; eval "echo $info"; ssh -q $1 "$cmd"; echo; done
	for host_name in $($dbt -B -N -D db_tracking -e "$db_tracking_query")
	do
		eval "echo $info"
		ssh -q $host_name "$cmd"
		echo
	done
fi

echo
echo "************************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "************************************************************"

graceful_exit
