#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Automated restore of database from production backup to SDLC 
#	non-replicated environment. Preserves MySQL privileges of SDLC 
#	database. Instance has to exist prior to running this restore script.
#
# Usage:
#	Run with "--help" option to get usage info.
#
# Revisions:
#	2010-09-27 - Dimitriy Alekseyev
#	Script created.
#	2010-09-28 - Dimitriy Alekseyev
#	Modified mysql_db_restore_to_sdlc.sh script into this one. Rearranged 
#	the sequence of events, so that the original database is deleted before 
#	the backup is extracted. Added option to run a SQL script after refresh.
#	2011-11-11 - Dimitriy Alekseyev
#	Modified script to take parameters and automatically log output.
#	2012-09-25 - Dimitriy Alekseyev
#	Added target host information to the output.
#	2013-05-28 - Dimitriy Alekseyev
#	Added data file existence check.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`
# Script directory.
script_dir=`dirname $(readlink -f $0)`

# Instance number of the target location. No leading zeros should be supplied.
inst=$1
# Main backup directory - script will pick a backup from this directory.
backup_dir=$2
# Supply specific backup to restore or leave blank to restore the latest backup.
backup_chosen=$3

# SQL script to execute after the refresh is complete. Optional.
sql_script=


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
	echo "	$0 target_instance path_to_main_backup_directory [backup_directory_with_specific_timestamp]"
	echo "Examples:"
	echo "	$0 7 /mysql_bkup/mysql_oltp_bkup/lsalerts_faclsna01smdb36_slave"
	echo "	$0 7 /mysql_bkup/mysql_oltp_bkup/lsalerts_faclsna01smdb36_slave 20100927_105716.daily"
	echo "Description:"
	echo "	Script has to be run under mysql user. Specify just target_instance and main_backup_directory parameters if you want the latest backup to be selected automatically. Output is both logged and displayed to the screen automatically."
	clean_up
	exit 1
}

function main {
	# Check if user is mysql.
	if [[ "`id -un`" != mysql ]]; then
		error_exit "Error on line $LINENO. You have to be 'mysql' user."
	fi

	# Check if instance directory exists.
	if [[ ! -d /mysql/$inst_wlz ]]; then
		error_exit "Error on line $LINENO. Instance directory does not exist."
	fi

	# If no backup is chosen then use the latest backup in backup directory.
	if [[ -z "$backup_chosen" ]]; then
		cd $backup_dir || error_exit "Error on line $LINENO. Could not cd into backup directory."
		backup_chosen=$(ls | sort | tail -1)	
	fi
	
	# Check if back up data file exists.
	if [[ ! -e $backup_dir/$backup_chosen/data.tar.gz ]]; then
		error_exit "Error on line $LINENO. Backup data file does not exist: '$backup_dir/$backup_chosen/data.tar.gz'."
	fi

	echo "**************************************************"
	echo "* Restore database from backup"
	echo "* Time started:" `date +'%F %T %Z'`
	echo "**************************************************"
	echo
	echo "Target host:      " $(hostname)
	echo "Target instance:  " $inst
	echo "Backup directory: " $backup_dir
	echo "Restore backup:   " $backup_chosen
	echo "SQL script to run:" $sql_script
	echo

	mkdir /mysql/$inst_wlz/tmp/auto_restore || error_exit "Error on line $LINENO. Could not create auto_restore directory."
	chmod 770 /mysql/$inst_wlz/tmp/auto_restore

	echo "Disk space available before deleting original database:"
	cd /mysql/$inst_wlz/tmp/auto_restore || error_exit "Error on line $LINENO."
	df -h .
	echo

	m${inst}stop.sh
	echo

	echo "Deleting original database..."
	mv -v /mysql/$inst_wlz/data/mysql /mysql/$inst_wlz/tmp/auto_restore/mysql_orig || error_exit "Error on line $LINENO."
	rm -rfv /mysql/$inst_wlz/data/* || error_exit "Error on line $LINENO."
	echo

	echo "Disk space available after deleting original database:"
	df -h .
	echo

	echo "Extracting backup files..."
	tar -xzpvf $backup_dir/$backup_chosen/data.tar.gz || error_exit "Error on line $LINENO."
	echo

	echo "Deleting unnecessary extracted files..."
	rm -v /mysql/$inst_wlz/tmp/auto_restore/data/master.info || error_exit "Error on line $LINENO."
	rm -v /mysql/$inst_wlz/tmp/auto_restore/data/relay-log.info || error_exit "Error on line $LINENO."
	rm -rfv /mysql/$inst_wlz/tmp/auto_restore/data/mysql || error_exit "Error on line $LINENO."
	echo

	echo "Restoring..."
	mv -v /mysql/$inst_wlz/tmp/auto_restore/data/* /mysql/$inst_wlz/data/ || error_exit "Error on line $LINENO."
	mv -v /mysql/$inst_wlz/tmp/auto_restore/mysql_orig /mysql/$inst_wlz/data/mysql || error_exit "Error on line $LINENO."
	echo

	echo "Cleaning up..."
	cd /mysql/$inst_wlz || error_exit "Error on line $LINENO."
	rm -rfv /mysql/$inst_wlz/tmp/auto_restore || error_exit "Error on line $LINENO."
	echo

	m${inst}start.sh || error_exit "Error on line $LINENO. Could not start MySQL instance."
	echo

	echo "Disk space available after restore:"
	df -h .
	echo

	echo "Running simple query to verify that MySQL is up..."
	echo 'SELECT NOW();' | m${inst}c.sh || error_exit "Error on line $LINENO."
	echo

	if [[ ! -z "$sql_script" ]]; then
		echo "Exectuing SQL script..."
		m${inst}c.sh < $sql_script
		echo
	fi

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

# If required parameters are missing, then show usage.
if [[ -z "$inst" || -z "$backup_dir" ]]; then
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
log=$script_dir/logs/$(date '+%Y%m%d_%H%M%S')_restore_to_${HOSTNAME}_${inst_wlz}.log

# Execute main function and output to both screen and log file.
main 2>&1 | tee -a $log

graceful_exit
