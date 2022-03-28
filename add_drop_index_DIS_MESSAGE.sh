#!/bin/sh

. /var/mysql/dba/environment/global_stuff

myuser
mypasswd

SQLFILE="/var/mysql/dba/scripts/add_index_DIS_MESSAGE.sql"
#SQLFILE="/var/mysql/dba/scripts/drop_index_DIS_MESSAGE.sql"

LOGFILE=$LOGS/add_index_DIS_MESSAGE.log
ERRFILE=$LOGS/add_index_DIS_MESSAGE.err

$ECHO "\nAdding INDEX to DIS_MESSAGE Table on `hostname` Starting on `date`. Please Wait...\n" > $LOGFILE

$MYSQL -u $USER -p$PASSWD -hqlxddisc001 -vv --tab -D discussions < $SQLFILE >> $LOGFILE 2> $ERRFILE

$ECHO "\nAdding INDEX to DIS_MESSAGE Table on `hostname` Has Completed on `date`." >> $LOGFILE

exit 0

