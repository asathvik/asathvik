#!/bin/sh
#
# This script executes Percona 'pt-summary' and 'pt-mysql-summary' against MySQL instance locally
# to summarize both local host and MySQL system information. 
#
# Author       : Anil Kumar. Alpati
# Last Modified: 09/05/2014

. /var/mysql/dba/environment/global_stuff

# Set usage
USAGE="Usage: `basename $0` [ -M email1 email2 email3... ]"

MAIL_LIST=

# Command line options.
while getopts "M:" options; do
   case $options in
      M) MAIL_LIST=$OPTARG
         ;;
      *) $ECHO
         $ECHO $USAGE
         exit 1
         ;;
   esac
done

HOSTNAME=`/bin/hostname -s`

LOGFILE=$LOGS/pt-summary_"$HOSTNAME"_`/bin/date '+%m-%d-%y_%H:%M:%S'`

START_TIME=`/bin/date '+%Y-%m-%d %H:%M'`

$ECHO "\nRunning pt-summary and pt-mysql-summary on $HOSTNAME at $START_TIME. Please wait...\n"

myuser
mypasswd

/usr/bin/pt-summary --summarize-mounts > $LOGFILE
/usr/bin/pt-summary --summarize-network >> $LOGFILE
/usr/bin/pt-summary --summarize-processes >> $LOGFILE

$ECHO "\n" >> $LOGFILE

/usr/bin/pt-mysql-summary --user $USER -password $PASSWD --host localhost --port 3306 >> $LOGFILE

if [ "$MAIL_LIST" != "" ]; then
   TITLE="Here's Summary from pt-summary and pt-mysql-summary on $HOSTNAME"
   $MAIL -s "$TITLE" $MAIL_LIST < $LOGFILE
else
   /bin/cat $LOGFILE
fi

exit 0
