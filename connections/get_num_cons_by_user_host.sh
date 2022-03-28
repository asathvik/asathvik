#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Get number of connections to MySQL database grouped by user and host.
#
# Usage:
#	Optionally pass in instance number as a first parameter, otherwise info 
#	for all instances will be shown.
#
# Revisions:
#	2012-11-04 - Dimitriy Alekseyev
#	Script created.
#	2013-07-16 - Dimitriy Alekseyev
#	Added ability to accept instance number as parameter.
################################################################################


instance=$1
if [[ ! -z $instance ]]; then
	extra_option="-i $instance"
fi

for inst in $(/dba_share/scripts/mysql/utils/mysql_list_dbs.sh -N -t -o i $extra_option)
do
	echo "instance: $inst"
	echo "  count user host"
	echo "show processlist" | /usr/local/bin/mysql/m${inst}c.sh | grep '|' | gawk -F'|' '{print $3, $4}' | gawk '{print $1, $2}' | sed '1d; s/:[0-9]*$//' | sort | uniq -c
	echo
done
