#!/bin/sh
#
# This script logs on to a specified master port and runs checksum process on each table
# in each user db, and compares it with checksum results on each of the slaves in that
# tier. If it finds any difference between the two checksum results, it'll send a report
# to a specified email distribution list.
#
# Note: This script needs to be run on a host that has MySQL client installed.
#
# Author       : Anil Kumar. Alpati
# Last Modified: 11/10/2014

. /var/mysql/dba/environment/global_stuff

# set USAGE
USAGE="usage: `basename $0` -H MySQL_local_dir -P port_name [ -D 'db1 db2 db3...' ] [ -M 'email1 email2 email3 ...' ]"
USAGE1="usage: MySQL Port Has to be Specified in the Form of machine_name:port_number"

#null ARGS
PORT_NAME=
DB_NAME=
MAIL_LIST=
MYSQL_LOCAL_DIR=

# getopts ARGS
while getopts H:P:D:M: VAR
do
   case $VAR in
      H) MYSQL_LOCAL_DIR=$OPTARG
         ;;
      P) PORT_NAME=$OPTARG
         ;;
      D) DB_NAME=$OPTARG
         ;;
      M) MAIL_LIST=$OPTARG
         ;;
      *) $ECHO
         $ECHO $USAGE
         $ECHO $USAGE1
         $ECHO
         exit 1
         ;;
   esac
done

if [ "$PORT_NAME" = "" ]; then
   $ECHO
   $ECHO $USAGE
   $ECHO $USAGE1
   $ECHO
   exit 2
else
   if `$ECHO $PORT_NAME | /bin/egrep -e ':' > /dev/null`; then
      MACHINE=`$ECHO $PORT_NAME | /bin/cut -f1 -d ':'`
      PORT=`$ECHO $PORT_NAME | /bin/cut -f2 -d ':'`
   else
      $ECHO
      $ECHO $USAGE
      $ECHO $USAGE1
      $ECHO
      exit 3
   fi
fi

if [ "$MYSQL_LOCAL_DIR" = "" ]; then
   $ECHO
   $ECHO $USAGE
   $ECHO $USAGE1
   $ECHO
   exit 4
elif [ "$MYSQL_LOCAL_DIR" != "" ]; then
   if ! [ -d $MYSQL_LOCAL_DIR ]; then
      $ECHO "\nWarning!!! Directory $MYSQL_LOCAL_DIR Not Found on $MACHINE! Cancelling Checksum Process.\n"
      exit 5
   elif ! [ -f $MYSQL ]; then
      $ECHO "\nWarning!!! $MYSQL Not Found on $MACHINE! Cancelling Checksum Process.\n"
      exit 6
   fi
fi

myuser
mypasswd

if [ "$PORT_NAME" != "" ]; then
   for item in `$ECHO $PORT`
   do
      TMP=$LOGS/`/bin/basename $0`_$$.out
      TMP1=$LOGS/`/bin/basename $0`_$$.out.1
      TMP2=$LOGS/`/bin/basename $0`_$$.out.2
      /bin/cp /dev/null $TMP
      /bin/cp /dev/null $TMP1
      /bin/cp /dev/null $TMP2

      $ECHO "\nLogging on to Port: $PORT on Host: $MACHINE...\n"

      if [ "$DB_NAME" != "" ]; then
         for db_name in `$ECHO $DB_NAME`
         do
            $MYSQL -u $USER -p$PASSWD -h $MACHINE -P $PORT -D $db_name -e "show tables;" | /bin/egrep -v "+-|Table|\||row" > $TMP

            SIZE=`/bin/cat $TMP | /usr/bin/wc -l`

            if [ "$SIZE" -gt 0 ]; then
               /usr/bin/pt-table-checksum --user=$USER --password=$PASSWD --port=$PORT --recursion-method=processlist --no-check-binlog-format --retries=5 --max-lag=15000 --max-load=Threads_connected:1000 --check-interval=60 --chunk-size=5000 --chunk-size-limit=0 --set-vars wait_timeout=172800 --quiet --databases=$db_name --host=$MACHINE > $TMP1 2>&1

               SIZE=`/bin/cat $TMP1 | /usr/bin/wc -l`

               if [ "$SIZE" -gt 0 ]; then
                  if `/bin/cat $TMP1 | /bin/egrep -e 'Skipping|problem|exist' > /dev/null`; then
                     if [ "$MAIL_LIST" != "" ]; then
                        $MAIL -s "Found Issue(s) While Checksumming Database $db_name on Port $MACHINE:$PORT" $MAIL_LIST < $TMP1
                     else
                        $ECHO "\nFound Issue(s) While Checksumming Database $db_name on Port $MACHINE:$PORT.\n"
                        /bin/cat $TMP1
                     fi

                     continue
                  else
                     if `/bin/cat $TMP1 | /bin/grep -v "TS ERRORS" | /bin/awk '{print $3}' | /bin/grep '1' > /dev/null`; then
                        if [ "$MAIL_LIST" != "" ]; then
                           $MAIL -s "Found Checksum Difference(s) for Database $db_name on Port $MACHINE:$PORT" $MAIL_LIST < $TMP1
                        else
                           $ECHO "\nFound Checksum Difference(s) for Database $db_name.\n" < $TMP1
                           /bin/cat $TMP1
                        fi
                     else
                        if [ "$MAIL_LIST" = "" ]; then
                           $ECHO "\nNo Checksum Difference Found for Database $db_name.\n"
                        fi
                     fi
                  fi

                  /bin/cp /dev/null $TMP1
               fi
            else
               $ECHO "\nNo Table Found in Database $db_name.\n"
            fi

            /bin/cp /dev/null $TMP
         done
      else
         $MYSQL -u $USER -p$PASSWD -h $MACHINE -P $PORT -e "show databases;" | /bin/egrep -v "+-|Database|\||row" | /bin/egrep -v "information_schema|performance_schema|percona|dump" > $TMP2

         for db_name in `/bin/cat $TMP2`
         do
	    if [ "$db_name" != "test" ]; then
               $MYSQL -u $USER -p$PASSWD -h $MACHINE -P $PORT -D $db_name -e "show tables;" | /bin/egrep -v "+-|Table|\||row" > $TMP

               SIZE=`/bin/cat $TMP | /usr/bin/wc -l`

               if [ "$SIZE" -gt 0 ]; then
                  /usr/bin/pt-table-checksum --user=$USER --password=$PASSWD --port=$PORT --recursion-method=processlist --no-check-binlog-format --retries=5 --max-lag=15000 --max-load=Threads_connected:1000 --check-interval=60 --chunk-size=5000 --chunk-size-limit=0 --set-vars wait_timeout=172800 --quiet --databases=$db_name --host=$MACHINE > $TMP1 2>&1

                  SIZE=`/bin/cat $TMP1 | /usr/bin/wc -l`
   
                  if [ "$SIZE" -gt 0 ]; then
                     if `/bin/cat $TMP1 | /bin/egrep -e 'Skipping|problem|exist' > /dev/null`; then
                        if [ "$MAIL_LIST" != "" ]; then
                           $MAIL -s "Found Issue(s) While Checksumming Database $db_name on Port $MACHINE:$PORT" $MAIL_LIST < $TMP1
                        else
                           $ECHO "\nFound Issue(s) While Checksumming Database $db_name on Port $MACHINE:$PORT.\n"
                           /bin/cat $TMP1
                        fi

                        continue
                     else
                        if `/bin/cat $TMP1 | /bin/grep -v "TS ERRORS" | /bin/awk '{print $3}' | /bin/grep '1' > /dev/null`; then
                           if [ "$MAIL_LIST" != "" ]; then
                              $MAIL -s "Found Checksum Difference(s) for Database $db_name on Port $MACHINE:$PORT" $MAIL_LIST < $TMP1
                           else
                              $ECHO "\nFound Checksum Difference(s) for Database $db_name.\n" < $TMP1
                              /bin/cat $TMP1
                           fi
                        else
                           if [ "$MAIL_LIST" = "" ]; then
                              $ECHO "\nNo Checksum Difference Found for Database $db_name.\n"
                           fi
                        fi
                     fi
   
                     /bin/cp /dev/null $TMP1
                  fi
               else
                  $ECHO "\nNo Table Found in Database $db_name.\n"
               fi

               /bin/cp /dev/null $TMP
            fi
         done
      fi
   done

   /bin/rm -f $TMP $TMP1 $TMP2
fi

exit 0
