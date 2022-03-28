#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Get percent of connections made to max connections available in MySQL.
#
# Usage:
#	Optionally pass in instance number as a first parameter, otherwise info 
#	for all instances will be shown.
#
# Revisions:
#	2013-07-15 - Dimitriy Alekseyev
#	Script created.
#
# Todo:
#	Add error handling.
################################################################################


set -e

instance=$1
if [[ ! -z $instance ]]; then
	extra_option="-i $instance"
fi

echo "instance connections_used_pct"
for inst in $(/dba_share/scripts/mysql/utils/mysql_list_dbs.sh -N -t -o i $extra_option)
do
	echo -n "$inst "
	results=$(echo "show global status like 'Threads_connected'; show global variables like 'max_connections';" | /usr/local/bin/mysql/m${inst}c.sh | egrep 'Threads_connected|max_connections' | grep '^|')
	threads_connected=$(echo "$results" | grep Threads_connected | gawk -F'| ' '{print $4}')
	max_connections=$(echo "$results" | grep max_connections | gawk -F'| ' '{print $4}')
	echo $(( 100 * $threads_connected / $max_connections ))
done