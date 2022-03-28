#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Clears MySQL MyISAM related files from OS cache.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	2013-01-23 - Dimitriy Alekseyev
#	Script created.
#	2013-09-19 - Dimitriy Alekseyev
#	Added ability to clear cache for 1 instance, instead of all instances.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=$(basename $0)

# MySQL instance number.
inst=$1


################################################################################
# Functions
################################################################################

function usage {
	# Function to show usage
	# No arguments
	echo "USAGE"
	echo "	$progname [instance]"
	echo
	echo "EXAMPLE"
	echo "	$progname 3"
	echo "	or"
	echo "	$progname"
	echo
	echo "DESCRIPTION"
	echo "	Clears MySQL MyISAM related files from OS cache. If instance number is not "
	echo "	supplied, then script assumes all instances should be processed."
	
	exit
}


################################################################################
# Program starts here
################################################################################

# Read parameters.
while [ "$1" != "" ]; do
	case $1 in
	-? | --help )
		usage
	esac
	shift
done

if [[ -z $inst ]]; then
	inst_dir="??"
else
	# Instance number with the leading zero if it is less than 10.
	inst_wlz="0$inst"
	inst_wlz=${inst_wlz:${#inst_wlz}-2:2}
	
	inst_dir=$inst_wlz
fi

echo "Stop MySQL instance(s)."
/etc/init.d/mysql stop $inst

echo
echo "Clear files from OS cache."
/dba_share/software/fadvise/fadvise -dontneed /mysql/$inst_dir/*/*/*

echo
echo "Check if any files are still cached in OS."
/dba_share/software/fincore/fincore /mysql/$inst_dir/*/*/* | grep -v 'no incore pages'

echo
echo "Start MySQL instance(s)."
/etc/init.d/mysql start $inst
