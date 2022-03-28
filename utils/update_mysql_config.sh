#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Change MySQL configuration. The script udpates my.cnf file and global 
#	dynamic variable.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	2012-11-28 - Dimitriy Alekseyev
#	Script created.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

update_config_variable=long_query_time
update_config_value=1

error_encountered=0


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
	echo "${progname}: ${1:-"Errors were encountered while running this script."}" 1>&2
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
	echo "	$progname -i instance"
	echo "	or"
	echo "	$progname -i \"instance_list\""
	echo
	echo "EXAMPLE"
	echo "	$progname -i 3"
	echo "	or"
	echo "	$progname -i \"2 3 4\""
	echo
	echo "OPTIONS"
	echo "	-i, --instance"
	echo "		Tells the script what instance to operate on."
	
	clean_up
	exit 1
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT
# Exit script if an uninitialised variable is used.
#set -o nounset

# Read parameters.
while [ "$1" != "" ]; do
    case $1 in
    	-i | --instance )
    	    shift
    	    instance_list=$1
    	    ;;
        -? | --help )
            usage
            ;;
        * )
            echo "ERROR: Incorrect parameters were passed in."
            echo
            usage
    esac
    shift
done

if [[ -z $instance_list ]]; then
	echo "ERROR: Incorrect parameters were passed in."
	echo
	usage
fi

# Check if running under correct user.
if [[ $(id -un) != mysql ]]; then
        error_exit "ERROR: You have to be 'mysql' user!"
fi

echo "update_config_variable: $update_config_variable"
echo "update_config_value: $update_config_value"
echo

for inst in $instance_list
do
	# Instance number with the leading zero if it is less than 10.
	inst_wlz="0$inst"
	inst_wlz=${inst_wlz:${#inst_wlz}-2:2}
	
	# Instance number - no leading zero.
	inst=$(echo "$inst_wlz" | sed 's/^0//')
	
	echo "instance: $inst"
	
	if [[ -e /mysql/$inst_wlz/my.cnf ]]; then
		mysqlc="mysql -S /mysql/$inst_wlz/mysql.sock -u dbauser -p$(cat /usr/local/bin/mysql/m${inst}_passwd.txt)"
		
		echo "old_or_new config_value dynamic_value"
		
		# Get current config and dynamic values.
		current_config_value=$(grep "$update_config_variable" /mysql/$inst_wlz/my.cnf | gawk -F'=' '{print $2}')
		current_dynamic_value=$($mysqlc -N -e "show global variables like '$update_config_variable'" | gawk '{print $2}')
		echo "old $current_config_value $current_dynamic_value"
		
		if [[ "$update_config_value" != "$current_config_value" ]]; then
			echo "Updating config variable."
			ts=$(date +'%Y%m%d_%H%M%S')
			sed -i.${ts}.bak "/^$update_config_variable=/c\\$update_config_variable=$update_config_value" /mysql/$inst_wlz/my.cnf || (echo "Error while updating my.cnf file."; error_encountered=1)
		fi
		
		if [[ "$update_config_value" != "$current_dynamic_value" ]]; then
			echo "Updating dynamic variable."
			$mysqlc -e "set global $update_config_variable = $update_config_value;" || (echo "Error while updating dynamic variable."; error_encountered=1)
		fi
		
		# Get new config and dynamic values.
		new_config_value=$(grep "$update_config_variable" /mysql/$inst_wlz/my.cnf | gawk -F'=' '{print $2}')
		new_dynamic_value=$($mysqlc -N -e "show global variables like '$update_config_variable'" | gawk '{print $2}')
		echo "new $new_config_value $new_dynamic_value"
	else
		echo "Error: my.cnf file not found. This could be because of unsupported directory structure or because instance does not exist."
		error_encountered=1
	fi
	
	echo
done

if [[ $error_encountered -ne 0 ]]; then
	error_exit
fi

graceful_exit
