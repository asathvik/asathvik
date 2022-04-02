#!/bin/sh
#
# This script executes Percona 'pt-duplicate-key-checker' against MySQL instance
# and checks for any duplicate index and foreign key.
#
# Author       : Anil Kumar. Alpati
# Last Modified: 09/05/2014

. /var/mysql/dba/environment/global_stuff

# Set usage
USAGE="Usage: `basename $0` -D database [ -M email1 email2 email3...]"

DATABASE=
MAIL_LIST=

# Command line options.
while getopts "D:M:" options; do
   case $options in
      D) DATABASE=$OPTARG
         ;;
      M) MAIL_LIST=$OPTARG
         ;;
      *) $ECHO 
         $ECHO $USAGE
         exit 1
         ;;
   esac
done

if [ "$DATABASE" = "" ]; then
   $ECHO
   $ECHO
   $ECHO $USAGE
   exit 2

fi

HOSTNAME=`/bin/hostname -s`

LOGFILE=$LOGS/pt_duplicate_key_checker_"$HOSTNAME"_`/bin/date '+%m-%d-%y_%H:%M:%S'`.out
LOGFILE1=$LOGS/pt_duplicate_key_checker_"$HOSTNAME"_`/bin/date '+%m-%d-%y_%H:%M:%S'`.out.1

/bin/rm -f $LOGFILE $LOGFILE1

START_TIME=`/bin/date '+%Y-%m-%d %H:%M'`

$ECHO "\nChecking for Duplicate Key in Database '$DATABASE' on $HOSTNAME on $START_TIME. Please wait...\n"

myuser
mypasswd

for db in `$ECHO $DATABASE`
do
   /usr/bin/pt-duplicate-key-checker --databases=$db u=$USER,p=$PASSWD,h=$HOSTNAME > $LOGFILE1

   if `/bin/cat $LOGFILE1 | /bin/egrep -e "Total Indexes  0" > /dev/null`; then 
      /bin/cp /dev/null $LOGFILE1

      $ECHO "No Duplicate Index Found in Database $db.\n"
   elif `/bin/cat $LOGFILE1 | /bin/egrep -e "ALTER TABLE" > /dev/null`; then
      SIZE=`/bin/ls -al $LOGFILE1 | /bin/awk '{print $5}'`
      
      if [ $SIZE -gt 0 ]; then
         TITLE="Warning!! There Are Duplicate Keys in Database $db on $HOSTNAME"
    
         /bin/cat $LOGFILE1 >> $LOGFILE
        
         if [ "$MAIL_LIST" != "" ]; then
            $MAIL -s "$TITLE" $MAIL_LIST < $LOGFILE 
         else
            /bin/cat $LOGFILE
         fi
      fi
   fi

   /bin/rm -f $LOGFILE $LOGFILE1
done

exit 0
