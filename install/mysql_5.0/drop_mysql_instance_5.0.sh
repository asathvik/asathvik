#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Drop MySQL instance by stopping the instance and deleting all database 
#	files and scripts for this instance. This script works with MySQL 5.0 
#	instances.
#
# Usage:
#	drop_mysql_instance_5.0.sh instance_number
#
# Revisions:
#	08/18/2011 - Dimitriy Alekseyev
#	Script created from drop_mysql_instance_5.5.sh script.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=$(basename $0)
# Script directory.
script_dir=`dirname $(readlink -f $0)`

# Instance number to drop.
inst=$1
# Operating System user account to use for MySQL administration.
os_user=mysql
# Main directory to use for sybolic links and other things.
main_dir=/mysql


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
	echo "	$0 instance_number"
	echo "Example:"
	echo "	$0 7"
	echo
	echo "MySQL instances on this server:"
	# Get a list of all instances.
	ls -d $main_dir/??/ | xargs -n 1 -i basename {} | grep '[0-9][0-9]' | sed 's/^0//' | tr '\n' ' '
	echo
	clean_up
	exit 1
}

function main {
	# Function for main program execution
	# No arguments

	# Check if running under correct user.
	if [[ `id -un` != $os_user ]]; then
		error_exit "Error on line $LINENO. You have to be '$os_user' user."
	fi

	# Check if instance directory does not exist.
	if [[ ! -d $main_dir/$inst_wlz ]]; then
		error_exit "Error on line $LINENO. Instance directory does not exist."
	fi

	# Check if symbolic link does not exist.
	if [[ $(basename $(ls --classify $main_dir/$inst_wlz)) != $inst_wlz@ ]]; then
		error_exit "Error on line $LINENO. Symbolic link does not exist."
	fi

	echo "**************************************************"
	echo "* Drop MySQL instance"
	echo "* Time started:" `date +'%F %T %Z'`
	echo "**************************************************"
	echo
	echo "Hostname:           " `hostname`
	echo "Instance:           " $inst_wlz
	echo

	echo "Stopping instance if it is running..."
	# Check if instance is running.
	if [[ $(/etc/init.d/mysql status $inst | grep running | wc -l) == "1" ]]; then
		/etc/init.d/mysql stop $inst || error_exit "Error on line $LINENO."
	fi
	echo

	echo "Deleting instance scripts..."
	cd /usr/local/bin/mysql/ || error_exit "Error on line $LINENO."
	rm -v m${inst}c.sh m${inst}_passwd.txt m${inst}start.sh m${inst}stop.sh m${inst}_client_parms.cnf
	echo

	echo "Deleting instance directory and all content within the directory..."
	rm -rfv $(readlink $main_dir/$inst_wlz)
	echo

	echo "Deleting symbolic link..."
	rm -v $main_dir/$inst_wlz
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
if [[ $# -ne 1 ]]; then
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
log=$script_dir/logs/`date '+%Y%m%d_%H%M%S'`_`hostname`_m${inst_wlz}_drop_mysql_instance.log

# Execute main function and output to both screen and log file.
main 2>&1 | tee -a $log

graceful_exit
