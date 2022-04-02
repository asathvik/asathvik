#!/bin/sh
#
# This script executes Percona 'pt-stalk' against MySQL instance locally as a daemon.
# It monitors various conditions based on different parameters that are being specified.
#
# Author       : Anil Kumar. Alpati
# Last Modified: 09/05/2014

. /var/mysql/dba/environment/global_stuff

HOSTNAME=`/bin/hostname -s`

LOGFILE=$LOGS/pt_stalk_$$

START_TIME=`/bin/date '+%Y-%m-%d %H:%M'`

$ECHO "\nRunning pt-stalk on $HOSTNAME at $START_TIME. Please wait...\n" > $LOGFILE

myuser
mypasswd

nohup /usr/bin/pt-stalk	--function status --threshold 500 --cycles 1 --dest=$LOGS/pt-stalk --disk-pct-free 10 --retention-time 60 --daemonize --notify-by-email DGC-APO-Corporate-ClassroomDBA@apollo.edu -u $USER -p $PASSWD -h localhost -P 3306 &

exit 0
