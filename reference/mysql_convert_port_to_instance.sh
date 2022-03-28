#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Convert MySQL port number to instance number. Basically this script helps 
#	you find out what MySQL instance would be running on certain port.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	10/07/2009 - Dimitriy Alekseyev
#	Script created.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

tmp_file=""

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

function usage
{
	# Function to show usage
	# No arguments
	echo "Either usage information was requested or not all required parameters were passed in."
	echo
	echo "USAGE"
	echo "	$progname port"
	echo
	echo "EXAMPLE"
	echo "	$progname 3365"

	clean_up
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT
# Exit script if an uninitialised variable is used.
set -o nounset

port=$1

# If required parameters are missing, then exit.
if [[ -z "$port" ]]; then
    usage
fi

inst=$(( (port - 3310) / 5 + 1 ))

echo "Instance: $inst"
echo "Port:     $port"

graceful_exit
