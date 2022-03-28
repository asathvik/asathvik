#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Create MySQL instance with custom version. This script creates all 
#	instance directories, configuration files, and instance scripts. This 
#	script utilizes create_mysql_instance_files2.sh script. Supports having 
#	multiple MySQL versions on same server.
#
# Usage:
#	create_mysql_instance_5.1.sh mysql_version base_dir engine instance_number
#
# Revisions:
#	07/07/2009 - Dimitriy Alekseyev
#	Script created.
#	09/14/2010 - Dimitriy Alekseyev
#	Modified script to support having multiple versions of MySQL on the 
#	same server.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

mysql_ver=$1
base_dir=$2
engine=$3
inst=$4

# Directory where different versions of MySQL binaries are located.
mysql_bin_dir=/mysql/bin

mysql_bin_dir_and_ver=$mysql_bin_dir/$mysql_ver

# Instance number with the leading zero if it is less than 10.
inst_wlz="0$inst"
inst_wlz=${inst_wlz:${#inst_wlz}-2:2}


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
	find $mysql_bin_dir -type d -maxdepth 1 -mindepth 1 -exec basename {} \; | awk '{print "	"$1}'
	clean_up
	exit 1
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

# Check if user is mysql.
if [[ "`id -un`" != mysql ]]; then
	error_exit "Error on line $LINENO. You have to be 'mysql' user."
fi

# Check if /mysql directory exists.
if [[ ! -d /mysql ]]; then
	error_exit "Error on line $LINENO. /mysql directory does not exist."
fi

# Check if MySQL version exists.
if [[ ! -d $mysql_bin_dir_and_ver ]]; then
	error_exit "Error on line $LINENO. MySQL version specified does not exist."
fi

# Check if base_dir directory exists.
if [[ ! -d "$base_dir" ]]; then
	error_exit "Error on line $LINENO. $base_dir directory does not exist."
fi

# Check if enginge is myisam or innodb
if [[ "$engine" != myisam && "$engine" != innodb ]]; then
    usage
fi

# Check if instance directory exists.
if [[ -d /mysql/$inst_wlz ]]; then
	error_exit "Error on line $LINENO. Instance directory already exists."
fi

# Get MySQL version in short format.
mysql_ver_short=$($mysql_bin_dir_and_ver/bin/mysqld --version 2> /dev/null | awk '{print $3}' | awk -F- '{print $1}')

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
ln -s $base_dir/mysql_$inst_wlz /mysql/$inst_wlz || error_exit "Error on line $LINENO."
echo

echo "Creating binlogs, data, logs, tmp directories and bin symbolic link..."
mkdir /mysql/$inst_wlz/binlogs || error_exit "Error on line $LINENO."
mkdir /mysql/$inst_wlz/data || error_exit "Error on line $LINENO."
mkdir /mysql/$inst_wlz/logs || error_exit "Error on line $LINENO."
mkdir /mysql/$inst_wlz/tmp || error_exit "Error on line $LINENO."
ln -s $mysql_bin_dir_and_ver/bin /mysql/$inst_wlz/bin || error_exit "Error on line $LINENO."
chmod -R 770 /mysql/$inst_wlz/ || error_exit "Error on line $LINENO."
echo

echo "Creating instance files..."
cd /mysql/$inst_wlz || error_exit "Error on line $LINENO."
echo /dba_share/scripts/mysql/install/create_mysql_instance_files2.sh $mysql_bin_dir_and_ver $mysql_ver_short $engine $inst #DEBUG
/dba_share/scripts/mysql/install/create_mysql_instance_files2.sh $mysql_bin_dir_and_ver $mysql_ver_short $engine $inst || error_exit "Error on line $LINENO."
mv m${inst}.sh m${inst}c.sh m${inst}_passwd.txt m${inst}start.sh m${inst}stop.sh /usr/local/bin/mysql/ || error_exit "Error on line $LINENO."
echo

echo "**************************************************"
echo "Creating mysql schema..."
$mysql_bin_dir_and_ver/scripts/mysql_install_db --basedir=$mysql_bin_dir_and_ver --defaults-file=/mysql/$inst_wlz/my.cnf || error_exit "Error on line $LINENO."
rmdir /mysql/$inst_wlz/data/test || error_exit "Error on line $LINENO."
chmod 770 /mysql/$inst_wlz/data/mysql || error_exit "Error on line $LINENO."
echo "**************************************************"
echo

echo "Starting instance..."
/etc/init.d/mysql start $inst || error_exit "Error on line $LINENO."
echo

echo "Setting up privileges for system users..."
$mysql_bin_dir_and_ver/bin/mysql --socket=/mysql/$inst_wlz/mysql.sock --user=root -vv < /dba_share/scripts/mysql/security/setup_system_users2.sql > /dba_share/scripts/mysql/security/logs/`date '+%Y%m%d_%H%M%S'`_`hostname`_m${inst_wlz}_mysql_setup_system_users.log || error_exit "Error on line $LINENO."
echo

echo "**************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "**************************************************"

graceful_exit
