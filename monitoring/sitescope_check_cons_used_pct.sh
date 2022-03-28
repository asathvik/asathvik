#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Get percent of connections made to max connections available in MySQL.
#
# Usage:
#	Pass in instance number as a first parameter.
#
# Revisions:
#	2013-07-15 - Dimitriy Alekseyev
#	Script has been cloned from get_cons_used_pct.sh for use with 
#	SiteScope. Removed dependency on list_mysql_dbs.sh script.
#
# Todo:
#	Add error handling.
################################################################################


set -e

inst=$1
if [[ -z $inst ]]; then
	echo "ERROR: Please provide an instance number." 1>&2
	exit 1
fi

results=$(echo "show global status like 'Threads_connected'; show global variables like 'max_connections';" | /usr/local/bin/mysql/m${inst}c.sh | egrep 'Threads_connected|max_connections' | grep '^|')
threads_connected=$(echo "$results" | grep Threads_connected | gawk -F'| ' '{print $4}')
max_connections=$(echo "$results" | grep max_connections | gawk -F'| ' '{print $4}')
echo $(( 100 * $threads_connected / $max_connections ))
