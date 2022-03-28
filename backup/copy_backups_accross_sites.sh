#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	This script is for automating the copying of backups from one site to 
#	another.
#
# Usage:
#	copy_backups_accross_sites.sh
#
# Revisions:
#	10/11/2007 - Dimitriy Alekseyev
#	Script created.
#	10/12/2007 - Dimitriy Alekseyev
#	Added code to delete old backups at destination.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`


################################################################################
# Functions
################################################################################

function clean_up
{
	#####
	#	Function to remove temporary files and other housekeeping
	#	No arguments
	#####

	rm -f ${tmp_file}
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

function error_exit
{
	#####
	# 	Function for exit due to fatal program error
	# 	Accepts 1 argument
	#		string containing descriptive error message
	#####

	echo "${progname}: ${1:-"Unknown Error"}" 1>&2
	clean_up
	exit 1
}

function term_exit
{
	#####
	#	Function to perform exit if termination signal is trapped
	#	No arguments
	#####

	echo "${progname}: Terminated"
	clean_up
	exit
}

function int_exit
{
	#####
	#	Function to perform exit if interrupt signal is trapped
	#	No arguments
	#####

	echo "${progname}: Aborted by user"
	clean_up
	exit
}

function copy_accross_sites
{
	echo "**************************************************"
	echo "* $db database"
	echo "* Time:" `date +'%F %T %Z'`
	echo "**************************************************"
	
	cd $backup_source_dir1 || error_exit "Error on line $LINENO. Could not change directory."
	
	# Get latest backup source and destination subdirectory.
	backup_source_dir2=`ls -Ad * | tail -1`
	backup_dest_dir2=$backup_source_dir2
	
	echo "Backup source path: $backup_source_dir1/$backup_source_dir2"
	echo "Backup destination path: $backup_dest_dir1/$backup_dest_dir2"
	echo
	
	# Make sure that backup source directory exists.
	ls $backup_source_dir2 &> /dev/null || error_exit "Error on line $LINENO. Backup source directory does not exist."
	
	# Make sure that backup destination directory does not exist.
	ls $backup_dest_dir1/$backup_dest_dir2 &> /dev/null && error_exit "Error on line $LINENO. Backup destination directory already exists."
	
	echo "Copying $db MySQL database..."
	cp -rpv $backup_source_dir2 $backup_dest_dir1/ || error_exit "Error on line $LINENO. Copying failed."
	echo "Done."
	echo

	# Check if there are old backups that need to be deleted.
	
	cd $backup_dest_dir1 || error_exit "Error on line $LINENO. Could not change directory."
	
	tmp_file="$tmp_file /tmp/backup_list.$$.tmp"
	if [ "$(ls -d * 2> /dev/null | tail -1)" ] ; then
	    ls -d * > /tmp/backup_list.$$.tmp || error_exit "Error on line $LINENO."
	else
	    touch /tmp/backup_list.$$.tmp || error_exit "Error on line $LINENO."
	fi
	
	while [ "$(cat /tmp/backup_list.$$.tmp | wc -l)" -gt "$num_bkups_to_keep" ]
	do
	    old_backup="$(head -1 /tmp/backup_list.$$.tmp)"
	    
	    echo "Deleting old backup at destination:" $backup_dest_dir1/$old_backup
	    rm -rf $backup_dest_dir1/$old_backup || error_exit "Error on line $LINENO."
	    ls -d * > /tmp/backup_list.$$.tmp || error_exit "Error on line $LINENO."
	    echo "Done."
	    echo
	done
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT

echo "**************************************************"
echo "* Copy Backups Across Sites"
echo "* Time started:" `date +'%F %T %Z'`
echo "**************************************************"
echo
echo "Hostname:" `hostname`.`dnsdomainname`
echo


db=batch_tracking
num_bkups_to_keep=2
backup_source_dir1=/lv_db_backup1/mysql/batch_tracking_lv_data019_slave_bkup
backup_dest_dir1=/op_db_backup1/mysql/batch_tracking_lv_data019_slave_bkup
copy_accross_sites


db=clsdpmst
num_bkups_to_keep=2
backup_source_dir1=/lv_db_backup1/mysql/clsdpmst_lv_data019_slave_bkup
backup_dest_dir1=/op_db_backup1/mysql/clsdpmst_lv_data019_slave_bkup
copy_accross_sites


db=data_load_tracking
num_bkups_to_keep=2
backup_source_dir1=/op_db_backup1/mysql/data_load_tracking_op_datadba1_master_bkup
backup_dest_dir1=/lv_db_backup1/mysql/data_load_tracking_op_datadba1_master_bkup
copy_accross_sites


db=mq_workflow
num_bkups_to_keep=2
backup_source_dir1=/op_db_backup1/mysql/mq_workflow_data023_slave_bkup
backup_dest_dir1=/lv_db_backup1/mysql/mq_workflow_data023_slave_bkup
copy_accross_sites


db=orders
num_bkups_to_keep=2
backup_source_dir1=/op_db_backup1/mysql/orders_op_data012_slave_bkup
backup_dest_dir1=/lv_db_backup1/mysql/orders_op_data012_slave_bkup
copy_accross_sites


db=orders_archive
num_bkups_to_keep=2
backup_source_dir1=/lv_db_backup1/mysql/orders_archive_lv_data017_master_bkup
backup_dest_dir1=/op_db_backup1/mysql/orders_archive_lv_data017_master_bkup
copy_accross_sites


echo "**************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "**************************************************"

graceful_exit
