#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Create MySQL instance with custom version. This script creates all 
#	instance directories, configuration files, and instance scripts. This 
#	script utilizes create_mysql_instance_files_5.5.sh script. Supports having 
#	multiple MySQL versions on same server.
#
# Usage:
#	create_mysql_instance_5.5.sh mysql_version base_dir engine instance_number
#
# Revisions:
#	07/07/2009 - Dimitriy Alekseyev
#	Script created.
#	09/14/2010 - Dimitriy Alekseyev
#	Modified script to support having multiple versions of MySQL on the 
#	same server.
#	07/08/2011 - Dimitriy Alekseyev
#	Modified script to have more configuration options via variables.
#	Modified script to output to screen and log file at the same time.
#	07/11/2011 - Dimitriy Alekseyev
#	Changed options for find command to avoid a warning in SuSE 11. Fixed 
#	symbolic link path to use the variable instead of using hard coded value.
#	07/12/2011 - Dimitriy Alekseyev
#	Revised script to pass the main directory parameter to a called script.
#	Added copying of latest /etc/init.d/mysql script and populating 
#	/etc/profile.local with instance creation.
#	06/29/2012 - Dimitriy Alekseyev
#	Now sorting the list of available MySQL versions.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=$(basename $0)
# Script directory.
script_dir=`dirname $(readlink -f $0)`

# MySQL version to install, it is a full name of the directory were certain version of MySQL binaries is located.
mysql_ver=$1
# Base directory, where instance and data files will be stored.
base_dir=$2
# MySQL database engine to use for initial configuration.
engine=$3
# Instance number to create.
inst=$4
# Operating System user account to use for MySQL administration.
os_user=mysql
# Main directory to use for sybolic links and other things.
main_dir=/mysql
# Directory where different versions of MySQL binaries are located.
mysql_bin_dir=$main_dir/bin
mysql_bin_dir_and_ver=$mysql_bin_dir/$mysql_ver
# MySQL administrator username.
db_admin_user=dbauser
# MySQL administrator password.
db_admin_pass=surfb0ard
# MySQL monitoring username.
db_mon_user=dbmon
# MySQL monitoring password.
db_mon_pass=w4tch0db


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
	echo "	$0 mysql_version base_dir {myisam | innodb} instance_number"
	echo "Example:"
	echo "	$0 mysql-advanced-gpl-5.1.50-linux-x86_64-glibc23 /san01 innodb 7"
	echo
	echo "MySQL versions available on this server:"
	find $mysql_bin_dir -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | awk '{print "        "$1}' | sort
	clean_up
	exit 1
}

function main {
	# Check if running under correct user.
	if [[ `id -un` != $os_user ]]; then
		error_exit "Error on line $LINENO. You have to be '$os_user' user."
	fi

	# Check if main directory exists.
	if [[ ! -d $main_dir ]]; then
		error_exit "Error on line $LINENO. $main_dir directory does not exist."
	fi

	# Check if MySQL version exists.
	if [[ ! -d $mysql_bin_dir_and_ver ]]; then
		error_exit "Error on line $LINENO. MySQL version specified does not exist."
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
	if [[ -d $main_dir/$inst_wlz ]]; then
		error_exit "Error on line $LINENO. Instance directory already exists."
	fi

	# Get MySQL version in short format.
	mysql_ver_short=$($mysql_bin_dir_and_ver/bin/mysqld --version 2> /dev/null | awk '{print $3}' | awk -F- '{print $1}')
	if [[ -z $mysql_ver_short ]]; then
		error_exit "Error on line $LINENO. Trouble running 'mysqld --version' for the MySQL version specified."
	fi

	echo "**************************************************"
	echo "* Create MySQL instance"
	echo "* Time started:" `date +'%F %T %Z'`
	echo "**************************************************"
	echo
	echo "Hostname:           " `hostname`
	echo "MySQL version:      " $mysql_ver
	echo "MySQL version short:" $mysql_ver_short
	echo "Base dir:           " $base_dir
	echo "Enginge:            " $engine
	echo "Instance:           " $inst_wlz
	echo

	echo "Creating $base_dir/mysql_$inst_wlz directory..."
	mkdir $base_dir/mysql_$inst_wlz || error_exit "Error on line $LINENO."
	echo

	echo "Creating symbolic link..."
	ln -s $base_dir/mysql_$inst_wlz $main_dir/$inst_wlz || error_exit "Error on line $LINENO."
	echo

	echo "Creating binlogs, data, logs, tmp directories, and bin symbolic link..."
	mkdir $main_dir/$inst_wlz/binlogs || error_exit "Error on line $LINENO."
	mkdir $main_dir/$inst_wlz/data || error_exit "Error on line $LINENO."
	mkdir $main_dir/$inst_wlz/logs || error_exit "Error on line $LINENO."
	mkdir $main_dir/$inst_wlz/tmp || error_exit "Error on line $LINENO."
	ln -s $mysql_bin_dir_and_ver/bin $main_dir/$inst_wlz/bin || error_exit "Error on line $LINENO."
	chmod -R 770 $main_dir/$inst_wlz/ || error_exit "Error on line $LINENO."
	echo

	echo "Creating instance scripts and files..."
	cd $main_dir/$inst_wlz || error_exit "Error on line $LINENO."
	$script_dir/create_mysql_instance_files_5.5.sh $mysql_bin_dir_and_ver $mysql_ver_short $engine $inst $main_dir $db_admin_user $db_admin_pass || error_exit "Error on line $LINENO."
	mv m${inst}.sh m${inst}c.sh m${inst}_passwd.txt m${inst}start.sh m${inst}stop.sh /usr/local/bin/mysql/ || error_exit "Error on line $LINENO."
	echo

	echo "**************************************************"
	echo "Creating mysql schema..."
	$mysql_bin_dir_and_ver/scripts/mysql_install_db --basedir=$mysql_bin_dir_and_ver --defaults-file=$main_dir/$inst_wlz/my.cnf || error_exit "Error on line $LINENO."
	rmdir $main_dir/$inst_wlz/data/test || error_exit "Error on line $LINENO."
	chmod 770 $main_dir/$inst_wlz/data/mysql || error_exit "Error on line $LINENO."
	echo "**************************************************"
	echo

	echo "Starting instance..."
	# Copy the latest version of /etc/init.d/mysql script.
	cp -p $script_dir/etc_init.d_mysql.sh /etc/init.d/mysql || error_exit "Error on line $LINENO."
	chmod 770 /etc/init.d/mysql || error_exit "Error on line $LINENO."
	
	# If missing, add entries to /etc/profile.local file.
	OLD_IFS=$IFS
	IFS=$'\n'
	lines=($(cat << EOF
export PATH=\$PATH:/usr/local/bin/mysql
export UMASK=0660
export UMASK_DIR=0770
EOF))
	for line in "${lines[@]}"
	do
        if ! grep -q "$line" /etc/profile.local; then echo $line >> /etc/profile.local; fi
	done
	IFS=$OLD_IFS
	
	# Load settings from /etc/profile.local file.
	. /etc/profile.local

	# Start MySQL instance.
	/etc/init.d/mysql start $inst || error_exit "Error on line $LINENO."
	echo

	echo "Deleting existing privileges and setting up administrative users..."
	cat << EOF | mysql --socket=$main_dir/$inst_wlz/mysql.sock --user=root -tvv || error_exit "Error on line $LINENO."
DELETE FROM mysql.procs_priv;
DELETE FROM mysql.columns_priv;
DELETE FROM mysql.tables_priv;
DELETE FROM mysql.host;
DELETE FROM mysql.db;
DELETE FROM mysql.user;

FLUSH PRIVILEGES;

GRANT ALL ON *.* TO '$db_admin_user'@'%' IDENTIFIED BY '$db_admin_pass' WITH GRANT OPTION;
SHOW GRANTS FOR '$db_admin_user';

GRANT SELECT ON *.* TO '$db_mon_user'@'%' IDENTIFIED BY '$db_mon_pass';
SHOW GRANTS FOR '$db_mon_user';
EOF
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
if [[ $# -ne 4 ]]; then
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
log=$script_dir/logs/`date '+%Y%m%d_%H%M%S'`_`hostname`_m${inst_wlz}_create_mysql_instance.log

# Execute main function and output to both screen and log file.
main 2>&1 | tee -a $log

graceful_exit
