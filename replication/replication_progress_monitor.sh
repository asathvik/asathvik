#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Simple replication progress monitor.
#
# Usage:
#	Modify instance number, then copy and paste the statement to run.
#
# Revisions:
#	2011-06-10 - Dimitriy Alekseyev
#	Script created, approximate date based on file timestamp.
#	2012-09-17 - Dimitriy Alekseyev
#	Updated script to output additional information. Modified to take 
#	parameters for instance number and interval.
################################################################################


# Quick replication progress monitor, for pasting to command line.
# while true; do echo "show slave status\G" | m1c.sh | grep Seconds_Behind_Master | gawk -F': ' '{print "Slave is behind by: " $2 " seconds \tor  " $2/60 " minutes \tor  " $2/60/60 " hours \tor  " $2/60/60/24 " days"}'; sleep 10; done


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# Instance number (no leading zero).
instance=$1
# Interval in number of seconds.
interval_sec=$2
# Default interval in number of seconds.
interval_default_sec=300


################################################################################
# Functions
################################################################################

function usage {
	# Function to show usage
	# No arguments
	echo "USAGE"
	echo "	$progname instance [interval]"
	echo
	echo "EXAMPLE"
	echo "	$progname 1"
	echo "	OR"
	echo "	$progname 11 300"
	echo
	echo "NOTE"
	echo "	If interval in seconds is not supplied, then a default value of 300 seconds (5 minutes) is used."

	#clean_up
	exit 1
}


################################################################################
# Program starts here
################################################################################

# If required parameters are missing, then show usage.
if [[ -z "$instance" || "$instance" == "--help" ]]; then
    usage
fi

if [[ -z "$interval_sec" ]]; then
    interval_sec=$interval_default_sec
fi

while true; do echo "show slave status\G" | m${instance}c.sh | grep Seconds_Behind_Master | gawk -F': ' '{print "Slave is behind by: " $2 " seconds \tor  " $2/60 " minutes \tor  " $2/60/60 " hours \tor  " $2/60/60/24 " days"}'; sleep $interval_sec; done
