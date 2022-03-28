#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Create MySQL instance. This script creates all instance directories, 
#	configuration files, and instance scripts. This script utilizes
#	create_mysql_instance_files.sh script.
#
# Usage:
#	create_mysql_instance.sh base_dir engine instance_number
#
# Revisions:
#	07/07/2009 - Dimitriy Alekseyev
#	Script created.
#	12/05/2011 - Dimitriy Alekseyev
#	Added script_dir variable, so that absolute path does not have to be 
#	used to reference helper script. Added automatic logging and outputting 
#	to screen at the same time.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=$(basename $0)
# Script directory.
script_dir=$(dirname $(readlink -f $0))

# Base directory, where instance and data files will be stored.
base_dir=$1
# MySQL database engine to use for initial configuration.
engine=$2
# Instance number to create.
inst=$3


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

function usage {
	# Function to show usage
	# No arguments
	echo "Usage:"
	echo "	$0 base_dir {myisam | innodb} instance_number"
	echo "Example:"
	echo "	$0 /san01 innodb 7"
	clean_up
	exit 1
}

function main {
	# Check if user is mysql.
	if [[ "`id -un`" != mysql ]]; then
		error_exit "Error on line $LINENO. You have to be 'mysql' user."
	fi

	# Check if /mysql directory exists.
	if [[ ! -d /mysql ]]; then
		error_exit "Error on line $LINENO. /mysql directory does not exist."
	fi

	# Check if base_dir directory exists.
	if [[ ! -d $base_dir ]]; then
		error_exit "Error on line $LINENO. $base_dir directory does not exist."
	fi

	# Check if enginge is myisam or innodb
	if [[ $engine != myisam && $engine != innodb ]]; then
		usage
	fi

	# Check if instance directory exists.
	if [[ -d /mysql/$inst_wlz ]]; then
		error_exit "Error on line $LINENO. Instance directory already exists."
	fi

	echo "**************************************************"
	echo "* Create MySQL instance"
	echo "* Time started:" `date +'%F %T %Z'`
	echo "**************************************************"
	echo
	echo "Hostname:" `hostname`
	echo "Base dir:" $base_dir
	echo "Enginge: " $engine
	echo "Instance:" $inst_wlz
	echo

	echo "Creating $base_dir/mysql_$inst_wlz directory..."
	mkdir $base_dir/mysql_$inst_wlz || error_exit "Error on line $LINENO."
	echo

	echo "Creating symbolic link..."
	ln -s $base_dir/mysql_$inst_wlz /mysql/$inst_wlz || error_exit "Error on line $LINENO."
	echo

	echo "Creating binlogs, data, logs, and tmp directories..."
	mkdir /mysql/$inst_wlz/binlogs || error_exit "Error on line $LINENO."
	mkdir /mysql/$inst_wlz/data || error_exit "Error on line $LINENO."
	mkdir /mysql/$inst_wlz/logs || error_exit "Error on line $LINENO."
	mkdir /mysql/$inst_wlz/tmp || error_exit "Error on line $LINENO."
	chmod -R 770 /mysql/$inst_wlz/ || error_exit "Error on line $LINENO."
	echo

	echo "Creating instance files..."
	cd /mysql/$inst_wlz || error_exit "Error on line $LINENO."
	$script_dir/create_mysql_instance_files.sh $engine $inst || error_exit "Error on line $LINENO."
	mv m${inst}c.sh m${inst}_passwd.txt m${inst}start.sh m${inst}stop.sh /usr/local/bin/mysql/ || error_exit "Error on line $LINENO."
	mv my.cnf_${inst_wlz}.txt my.cnf || error_exit "Error on line $LINENO."
	echo

	echo "**************************************************"
	echo "Creating mysql schema..."
	/usr/bin/mysql_install_db --defaults-file=/mysql/$inst_wlz/my.cnf || error_exit "Error on line $LINENO."
	rmdir /mysql/$inst_wlz/data/test || error_exit "Error on line $LINENO."
	chmod 770 /mysql/$inst_wlz/data/mysql || error_exit "Error on line $LINENO."
	echo "**************************************************"
	echo

	echo "Starting instance..."
	/etc/init.d/mysql start $inst || error_exit "Error on line $LINENO."
	echo

	echo "Setting up privileges for system users..."
	mysql --socket=/mysql/$inst_wlz/mysql.sock --user=root -vv < /dba_share/scripts/mysql/security/setup_system_users.sql > /dba_share/scripts/mysql/security/logs/$(date '+%Y%m%d_%H%M%S')_${HOSTNAME}_m${inst_wlz}_mysql_setup_system_users.log || error_exit "Error on line $LINENO."
	echo

	echo "**************************************************"
	echo "* Time completed:" `date +'%F %T %Z'`
	echo "**************************************************"
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT

# Check number of parameters.
if [[ $# -ne 3 ]]; then
	echo "Error: Incorrect number of parameters."
	echo
	usage
fi

# Instance number with the leading zero if it is less than 10.
inst_wlz="0$inst"
inst_wlz=${inst_wlz:${#inst_wlz}-2:2}

# Check if logs directory exists.
if [[ ! -d $script_dir/logs ]]; then
	mkdir $script_dir/logs || error_exit "Error on line $LINENO."
	chmod 770 $script_dir/logs
fi

# Log filename.
log=$script_dir/logs/$(date '+%Y%m%d_%H%M%S')_${HOSTNAME}_m${inst_wlz}_create_mysql_instance.log

# Execute main function and output to both screen and log file.
main 2>&1 | tee -a $log

graceful_exit
