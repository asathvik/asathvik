#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Run SQL task on multiple servers and/or databases. Uses db_tracking to 
#	find servers, ports, and databases.
#
# Usage:
#	Run script with -? or --help option to get usage information.
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
#	2013-09-11 - Dimitriy Alekseyev
#	Added support for configuration file and moved variables into 
#	configuration file.
#	Added ability to run ssh commands.
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
	echo "USAGE
	Run SQL tasks remotely on multiple servers and/or databases. Uses 
	db_tracking to find servers, ports, and databases. Script does not run 
	bash commands remotely. SQL tasks will not hit remote MySQL server if 
	the firewall is blocking the port.

	Make a copy of config file for this script, modify copied version, and run this 
	script on faclsna01slap07 server where db_tracking is located. Be sure 
	to test your script well, for example first run commands that do not 
	modify anything, such as 'select 1'.
	
	Alternatively, you could use a command such as the one below instead of 
	using this script:
	"
cat - <<COMMENT
echo "USE db_tracking; SELECT host_name, port, GROUP_CONCAT(db_name), GROUP_CONCAT(db_environment) FROM vw_actv_host_inst_db WHERE rdbms = 'mysql' AND db_environment = 'prod' AND db_name IN ('realcore') GROUP BY host_name, port ORDER BY db_environment;" | m13.sh -BN | while read line; do set -- $line; echo $1:$2 $3; sql="show variables like 'long_query_time';"; cmd="echo \"$sql\" | mysql -h $1 -P $2 -u dbauser -psurfb0ard"; eval $cmd; echo; done
COMMENT

echo "
SYNOPSIS
	$progname [options]

EXAMPLE
	$progname -c run_mysql_task_on_mult_servers.cfg

OPTIONS
	-c, --config-file
		Configuration file to use.
	-t, --test-only
		Query db_tracking database only, do not execute any SQL tasks.
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
	-c | --config-file )
		shift
		config_file=$1;;
	-t | --test-only )
		test_only=true;;
	-? | --help )
		usage;;
	* )
		error_exit "ERROR on line $LINENO. Incorrect parameters were passed in. Please check usage."
	esac
	shift
done

if [[ -f $config_file ]]; then
	. $config_file
else
	error_exit "ERROR on line $LINENO. Configuration file not found."
fi

echo "************************************************************"
echo "* Run task on multiple servers."
echo "* Time started:" `date +'%F %T %Z'`
echo "************************************************************"

echo
echo "db_tracking query:"
echo "$db_tracking_query"
echo
echo "db_tracking query result:"
$myc_db_tracking -B -D db_tracking -e "$db_tracking_query"
echo
echo "Informational output:"
echo "$info"
echo
echo "SQL statement:"
echo "$sql"
echo
echo "Bash command:"
echo "$cmd"

if [[ $test_only != true ]]; then
	echo
	echo
	echo
	while read line; do
		set -- $line
		eval "echo $info"
		eval "$cmd"
		echo
	done < <($myc_db_tracking -B -N -D db_tracking -e "$db_tracking_query")
fi

echo
echo "************************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "************************************************************"

graceful_exit
