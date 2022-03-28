#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	SQL to SQL script to analyze all tables.
#
# Usage:
#	scripname.sh
#
# Revisions:
#	2010-09-03 - Dimitriy Alekseyev
#	Script created.
#	2013-03-21 - Dimitriy Alekseyev
#	Enabled unbeffered mode.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

password=`cat /usr/local/bin/mysql/m6_passwd.txt`
mysql_connection="mysql --host=localhost --port=3335 --socket=/mysql/06/mysql.sock --user=dbauser -p$(cat /usr/local/bin/mysql/m6_passwd.txt)"


################################################################################
# Program starts here
################################################################################

echo 'SQL script generated:'
$mysql_connection  --batch --silent --unbuffered -e "SELECT CONCAT('ANALYZE TABLE ', table_schema, '.', table_name, ';') AS script FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'mysql');"

echo
echo 'SQL script execution:'
$mysql_connection  --batch --silent --unbuffered -e "SELECT CONCAT('ANALYZE TABLE ', table_schema, '.', table_name, ';') AS script FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'mysql');" | $mysql_connection -vvv --unbuffered
