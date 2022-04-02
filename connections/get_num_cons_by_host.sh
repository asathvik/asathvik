#!/bin/bash
################################################################################
# Author:
#	AK
#
# Purpose:
#	Get number of connections to MySQL database grouped by host.
#
# Usage:
#	Optionally pass in instance number as a first parameter, otherwise info 
#	for all instances will be shown.
#
# Revisions:
#	2012-11-04 - AK
#	Script created.
#	2013-07-16 - AK
#	Added ability to accept instance number as parameter.
################################################################################


instance=$1
if [[ ! -z $instance ]]; then
	extra_option="-i $instance"
fi

for inst in $(/dba_share/scripts/mysql/utils/mysql_list_dbs.sh -N -t -o i $extra_option)
do
	echo "instance: $inst"
	echo "  count host"
	echo "show processlist" | /usr/local/bin/mysql/m${inst}c.sh | grep '|' | gawk -F'|' '{print $4}' | gawk '{print $1}' | sed '1d' | gawk -F':' '{print $1}' | sort | uniq -c
	echo
done
