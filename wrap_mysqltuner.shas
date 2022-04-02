#!/bin/sh
#
# This script executes 'mysqltuner.sh' against MySQL instance.
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

LOGFILE=$LOGS/mysqltuner_"$HOSTNAME"_`/bin/date '+%m-%d-%y_%H:%M:%S'`
LOGFILE1=$LOGS/mysqltuner.out

START_TIME=`/bin/date '+%Y-%m-%d %H:%M'`

$ECHO "\nRunning MySQL Tuner on $HOSTNAME at $START_TIME. Please wait...\n"

myuser
mypasswd

$SCRIPTS/mysqltuner.pl --user $USER --pass $PASSWD --port 3306 --nocolor > $LOGFILE

while read line
do
   for item in `/bin/echo $line`
   do
      if [ "$item" = "[--]" -o "$item" = "[!!]" -o "$item" = "[OK]" ]; then
         $ECHO $line"\n" >> $LOGFILE1
      elif [ "$item" = "----" ]; then
         $ECHO "\n\n"$line >> $LOGFILE1
      else
         $ECHO $line >> $LOGFILE1
      fi
      break
   done
done < $LOGFILE

if [ "$MAIL_LIST" != "" ]; then
   TITLE="Here's Summary from MySQL Tuner on $HOSTNAME"
   $MAIL -s "$TITLE" $MAIL_LIST < $LOGFILE1
else
   /bin/cat $LOGFILE1
fi

/bin/rm -f $LOGFILE1

exit 0
