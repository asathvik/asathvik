#!/bin/sh
#
# This script logs in to each specified MySQL port and checks for blocked processes 
# by long running process and sends a warning to receipients. It also checks for
# replication latency and sends a warning when latency passes a given threshold.
# Note: This script needs to be run on a host that has MySQL installed.
#
# Author       : Anil Kumar. Alpati
# Last Modified: 09/05/2014

. /var/mysql/dba/environment/global_stuff

# set USAGE
USAGE="usage: `basename $0` -H MySQL_local_port_dir [ -P 'port1 port2 port3 ...' | -F port_listing_filename ] [ -X number_of_processes_blocked | -L latency ] [ -Y show_process_list 'Y' ] [ -K kill_process 'Y' ] [ -N number_of_process_count ] [ -U user_account ] [ -M 'email1 email2 email3 ...' ]"
USAGE1="usage: MySQL Port Has to be Specified in the Form of machine_name:port_number"
USAGE2="usage: -X and -N can only be a positive number"
USAGE3="usage: Can only specify either -X or -N option -- not both"
USAGE4="usage: -L can only be a positive number"
USAGE5="usage: -L option cannot be specified together with -X or -L option"
USAGE6="usage: -Y and -K can only take Y as argument"
USAGE7="usage: Both -N and -U options need to be specified as arguments"
USAGE8="usage: -X option cannot be specified together with -U option"

#null ARGS
PORT=
FILE=
MAIL_LIST=
NUMBER_OF_BLOCKS=0
LATENCY=0
SHOW_PROCESSLIST=
KILL=
NUMBER_OF_PROCESS_COUNT=0
count=0
NUM_PROC=0
USER=
MYSQL_LOCAL_PORT=
UPTIME=70

# getopts ARGS
while getopts H:P:F:X:L:Y:K:N:U:M: VAR
do
   case $VAR in
      H) MYSQL_LOCAL_PORT=$OPTARG
         ;;
      P) PORT=$OPTARG
         ;;
      F) FILE=$OPTARG
         ;;
      X) NUMBER_OF_BLOCKS=$OPTARG
         ;;
      L) LATENCY=$OPTARG
         ;;
      Y) SHOW_PROCESSLIST=$OPTARG
         ;;
      K) KILL=$OPTARG
         ;;
      N) NUMBER_OF_PROCESS_COUNT=$OPTARG
         ;;
      U) USER=$OPTARG
         ;;
      M) MAIL_LIST=$OPTARG
         ;;
      *) $ECHO
         $ECHO $USAGE
         $ECHO $USAGE1
         $ECHO $USAGE2
         $ECHO $USAGE3
         $ECHO $USAGE4
         $ECHO $USAGE5
         $ECHO $USAGE6
         $ECHO $USAGE7
         $ECHO $USAGE8
         exit 1
         ;;
   esac
done

if [ "$PORT" = "" -a \
     "$FILE" = "" ]; then
   $ECHO
   $ECHO $USAGE
   $ECHO $USAGE1
   exit 2
fi

if [ "$NUMBER_OF_PROCESS_COUNT" != 0 -a \
     "$USER" = "" ]; then
   $ECHO   
   $ECHO $USAGE7
   exit 3
elif [ "$NUMBER_OF_BLOCKS" != 0 -a \
       "$USER" != "" ]; then
   $ECHO   
   $ECHO $USAGE8
   exit 4
fi

if [ "$LATENCY" != 0 ]; then
   if [ "$NUMBER_OF_BLOCKS" != 0 -o \
        "$NUMBER_OF_PROCESS_COUNT" != 0 ]; then
      $ECHO
      $ECHO $USAGE
      $ECHO $USAGE5
      exit 5
   fi
fi

if [ "$NUMBER_OF_BLOCKS" != 0 -a \
     "$NUMBER_OF_PROCESS_COUNT" != 0 ]; then
   $ECHO   
   $ECHO $USAGE
   $ECHO $USAGE3
   exit 6
fi

if [ "$MYSQL_LOCAL_PORT" = "" ]; then
   $ECHO
   $ECHO $USAGE
   exit 7
elif ! [ -d $MYSQL_LOCAL_PORT ]; then
   $ECHO
   $ECHO "\nWarning!!! Directory $MYSQL_LOCAL_PORT Not Found!\n"
   exit 8
fi

if [ "$SHOW_PROCESSLIST" != ""  -a \
     "$SHOW_PROCESSLIST" != "Y" ]; then
   $ECHO
   $ECHO $USAGE6
   exit 9
fi

if [ "$KILL" != ""  -a \
     "$KILL" != "Y" ]; then
   $ECHO
   $ECHO $USAGE6
   exit 10
fi

myuser
mypasswd

if [ "$PORT" != "" ]; then
   for item in `$ECHO $PORT`
   do
      TMP=/tmp/`/bin/basename $0`_$$.out.0
      TMP1=/tmp/`/bin/basename $0`_$$.out.1
      TMP2=/tmp/`/bin/basename $0`_$$.out.2
      TMP3=/tmp/`/bin/basename $0`_$$.out.3
      TMP4=/tmp/`/bin/basename $0`_$$.out.4
      TMP5=/tmp/`/bin/basename $0`_$$.out.5
      /bin/cp /dev/null $TMP
      /bin/cp /dev/null $TMP1
      /bin/cp /dev/null $TMP2
      /bin/cp /dev/null $TMP3
      /bin/cp /dev/null $TMP4
      /bin/cp /dev/null $TMP5

      MACHINE=`$ECHO $item | /bin/cut -f1 -d ':'`
      PORT=`$ECHO $item | /bin/cut -f2 -d ':'`

      $ECHO "\nLogging on to Port: $PORT on Host: $MACHINE..."

      $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "select now()" > $TMP

      SIZE=`/bin/cat $TMP | /usr/bin/wc -l`

      if [ "$SIZE" -eq 0 ]; then
         if [ "$MAIL_LIST" != "" ]; then
            $MAIL -s "Failed to Connect to Port $item!!" $MAIL_LIST < /dev/null
         else
            $ECHO "\nFailed to Connect to Port $item!!\n"
         fi

         /bin/rm -f $TMP $TMP1 $TMP2 $TMP3 $TMP4 $TMP5

         continue
      fi

      $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show global status like 'uptime';" | /bin/grep -i uptime | /bin/grep -v '|' | /bin/awk '{print $2}'> $TMP

      if [ `/bin/cat $TMP` -lt "$UPTIME" ]; then
         /bin/ps -ef | /bin/grep mysqld | /bin/egrep -v "grep|mysqld_safe" > $TMP

         if [ "$MAIL_LIST" != "" ]; then
            $MAIL -s "Warning!! Port $item Just Got Restarted A Minute Ago!!" $MAIL_LIST < $TMP
         else
            $ECHO "\nWarning!! Port $item Just Got Restarted A Minute Ago!!\n"
            /bin/cat $TMP
         fi
      fi

      /bin/cp /dev/null $TMP

      if [ "$NUMBER_OF_PROCESS_COUNT" != 0 -o "$NUMBER_OF_BLOCKS" != 0 ]; then
         count=`$MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "select count(*) from information_schema.PROCESSLIST where USER = '$USER'" | /bin/grep -v count`

         if [ "$NUMBER_OF_PROCESS_COUNT" != 0 ]; then
            if [ "$count" -gt "$NUMBER_OF_PROCESS_COUNT" ]; then
               if [ "$MAIL_LIST" != "" ]; then
                  $ECHO "Number of $USER Processes on Port $item is $count Which Has Exceeded the Limit -- $NUMBER_OF_PROCESS_COUNT.\n" >> $TMP
                  $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "select * from information_schema.PROCESSLIST where USER = '$USER'" >> $TMP
                  $MAIL -s "Number of $USER Processes on Port $item Has Exceeded the Limit -- $NUMBER_OF_PROCESS_COUNT" $MAIL_LIST < $TMP
               else
                  $ECHO "\nNumber of $USER Processes on Port $item is $count Which Has Exceeded the Limit -- $NUMBER_OF_PROCESS_COUNT.\n"
                  $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "select * from information_schema.PROCESSLIST where USER = '$USER'"
               fi
            fi
         else
            $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show full processlist;" >> $TMP

            if [ `/bin/cat $TMP | /bin/egrep -e 'table level lock|Locked|preparing' | /usr/bin/wc -l` -gt $NUMBER_OF_BLOCKS ]; then
               /bin/cp /dev/null $TMP
               /bin/sleep 15
   
               $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show full processlist;" >> $TMP

               if [ `/bin/cat $TMP | /bin/egrep -e 'table level lock|Locked|preparing' | /usr/bin/wc -l` -gt $NUMBER_OF_BLOCKS ]; then
                  /bin/cp /dev/null $TMP
                  /bin/sleep 15
   
                  $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show full processlist;" >> $TMP

                  if [ `/bin/cat $TMP | /bin/egrep -e 'table level lock|Locked|preparing' | /usr/bin/wc -l` -gt $NUMBER_OF_BLOCKS ]; then
                     /bin/cat $TMP >> $TMP1
                     /bin/cat $TMP | /bin/egrep -e 'Sending data|Sorting result|Sorting for group|Copying to tmp table|Writing to net|update|updating|cleaning up|statistics|end|Waiting for global read lock' | /bin/egrep -v -e "updated|show full processlist|binlog|NULL|table level lock|Locked" >> $TMP2
                   fi
               fi
            else
               /bin/cp /dev/null $TMP
            fi

            SIZE=`/bin/cat $TMP1 | /usr/bin/wc -l`

            if [ "$SIZE" -gt 10 ]; then
               /bin/cp /dev/null $TMP
     
               $ECHO "\nProcesses Are Getting Blocked on Port $item.\n" >> $TMP
               /bin/cat $TMP1 >> $TMP
     
               SIZE=`/bin/cat $TMP2 | /usr/bin/wc -l`

               if [ "$SIZE" -gt 0 ]; then
                  $ECHO "\nThe Following Process(es) May be the Culprit(s):\n" >> $TMP
                  /bin/cat $TMP2 >> $TMP

                  if [ "$KILL" = "Y" ]; then
                     $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show slave status\G" >> $TMP5

                     if `/bin/cat $TMP5 | /bin/egrep -e 'Seconds_Behind_Master' > /dev/null`; then
                        if [ `/bin/cat $TMP5 | /bin/egrep -e 'Seconds_Behind_Master' | /bin/awk '{print $2}'` != "NULL" ]; then
                           NUM_MIN=`/bin/cat $TMP5 | /bin/egrep -e 'Seconds_Behind_Master' | /bin/awk '{print $2}'`

                           if [ $NUM_MIN -gt 180 ]; then
                              if `/bin/cat $TMP2 | /bin/egrep -e "SELECT  " > /dev/null`; then
                                 /bin/cat $TMP2 | /bin/egrep -e "SELECT  " | /bin/awk '{print $1}' >> $TMP3

                                 $ECHO "\nKilling Offending Process(es) on Port $item.\n" >> $TMP4
                                 /bin/cat $TMP2 | /bin/egrep -e "SELECT  " >> $TMP4

                                 for id in `/bin/cat $TMP3`
                                 do
                                    $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "kill $id;"
                                 done
                              fi
                           fi
                        fi
                     fi
                  fi
               fi
            fi

            SIZE=`/bin/cat $TMP | /usr/bin/wc -l`

            if [ "$SIZE" -gt 0 ]; then
               if [ "$MAIL_LIST" != "" ]; then
                  if [ "$KILL" = "Y" ]; then
                     SIZE=`/bin/cat $TMP4 | /usr/bin/wc -l`

                     if [ "$SIZE" -gt 100 ]; then
                        $MAIL -s "Processes Are Getting Blocked on Port $item" $MAIL_LIST < $TMP
                        $MAIL -s "Blocking Process(es) on Port $item Has Been Killed Off" $MAIL_LIST < $TMP4
                     fi
                  else
                     $MAIL -s "Processes Are Getting Blocked on Port $item" $MAIL_LIST < $TMP
                  fi
               else
                  if [ "$KILL" = "Y" ]; then
                     SIZE=`/bin/cat $TMP4 | /usr/bin/wc -l`
 
                     if [ "$SIZE" -gt 100 ]; then
                        $ECHO "\nProcesses Are Getting Blocked on Port $item.\n"
                        /bin/cat $TMP
                        $ECHO "\nBlocking Process(es) on Port $item Has Been Killed Off.\n"
                        /bin/cat $TMP4
                     fi
                  else
                     $ECHO "\nProcesses Are Getting Blocked on Port $item.\n"
                     /bin/cat $TMP
                  fi
               fi
            fi
         fi
      else
         if [ "$SHOW_PROCESSLIST" = "Y" ]; then
            $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show slave status\Gshow full processlist;" >> $TMP
         else
            $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show slave status\G" >> $TMP
         fi

         if `/bin/cat $TMP | /bin/egrep -e 'Seconds_Behind_Master' > /dev/null`; then
            if [ `/bin/cat $TMP | /bin/egrep -e 'Seconds_Behind_Master' | /bin/awk '{print $2}'` != "NULL" ]; then
               if [ `/bin/cat $TMP | /bin/egrep -e 'Seconds_Behind_Master' | /bin/awk '{print $2}'` -gt "$LATENCY" ]; then
                  let NUM_MINS=`expr $LATENCY \/ 60`

                  if [ "$MAIL_LIST" != "" ]; then
                     $MAIL -s "Warning!! Replication on Port $item is More Than $NUM_MINS Min(s) Behind Master!" $MAIL_LIST < $TMP
                  else
                     $ECHO "\nWarning!! Replication on Port $item is More Than $NUM_MINS Min(s) Behind Master!\n" >> $TMP1
                     /bin/cat $TMP >> $TMP1
                     /bin/cat $TMP1
                  fi
               else         
                  if [ "$MAIL_LIST" = "" ]; then
                     $ECHO "\nNo Significant Latency Found on Replication Status for Port $item.\n"
                  fi
               fi
            else
               if [ "$MAIL_LIST" != "" ]; then
                  $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show slave status\G" > $TMP5
                  $MAIL -s "Slave Is Currently Not Running on Port $item" $MAIL_LIST < $TMP5
               else
                  $ECHO "\nSlave Is Currently Not Running on Port $item.\n"
                  $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show slave status\G"
               fi
            fi
         fi
      fi
   
      /bin/rm -f $TMP $TMP1 $TMP2 $TMP3 $TMP4 $TMP5
   done
fi

if [ "$FILE" != "" ]; then
   if ! [ -f $FILE ]; then
      if [ "$MAIL_LIST" != "" ]; then
         $MAIL -s "$FILE Not Found!! Cancelling Monitor Process for Port(s) Listed in $FILE" $MAIL_LIST < /dev/null
      else
         $ECHO "\n$FILE Not Found!! Cancelling Monitor Process for Port(s) Listed in $FILE.\n"
      fi
   else
      SIZE=`/bin/cat $FILE | /usr/bin/wc -l`

      if [ "$SIZE" -gt 0 ]; then
         for item in `/bin/cat $FILE`
         do
            TMP=/tmp/`/bin/basename $0`_$$.out.0
            TMP1=/tmp/`/bin/basename $0`_$$.out.1
            TMP2=/tmp/`/bin/basename $0`_$$.out.2
            TMP3=/tmp/`/bin/basename $0`_$$.out.3
            TMP4=/tmp/`/bin/basename $0`_$$.out.4
            TMP5=/tmp/`/bin/basename $0`_$$.out.5
            /bin/cp /dev/null $TMP
            /bin/cp /dev/null $TMP1
            /bin/cp /dev/null $TMP2
            /bin/cp /dev/null $TMP3
            /bin/cp /dev/null $TMP4
            /bin/cp /dev/null $TMP5

            MACHINE=`$ECHO $item | /bin/cut -f1 -d ':'`
            PORT=`$ECHO $item | /bin/cut -f2 -d ':'`

            $ECHO "\nLogging on to Port: $PORT on Machine: $MACHINE..."
 
            $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "select now()" > $TMP

            SIZE=`/bin/cat $TMP | /usr/bin/wc -l`

            if [ "$SIZE" -eq 0 ]; then
               if [ "$MAIL_LIST" != "" ]; then
                  $MAIL -s "Failed to Connect to Port $item!!" $MAIL_LIST < /dev/null
               else
                  $ECHO "\nFailed to Connect to Port $item!!\n"
               fi

               /bin/rm -f $TMP $TMP1 $TMP2 $TMP3 $TMP4 $TMP5

               continue
            fi

            $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show global status like 'uptime';" | /bin/grep -i uptime | /bin/grep -v '|' | /bin/awk '{print $2}'> $TMP

            if [ `/bin/cat $TMP` -lt "$UPTIME" ]; then
               /bin/ps -ef | /bin/grep mysqld | /bin/egrep -v "grep|mysqld_safe" > $TMP
      
               if [ "$MAIL_LIST" != "" ]; then
                  $MAIL -s "Warning!! Port $item Just Got Restarted A Minute Ago!!" $MAIL_LIST < $TMP
               else
                  $ECHO "\nWarning!! Port $item Just Got Restarted A Minute Ago!!\n"
                  /bin/cat $TMP
               fi
            fi

            /bin/cp /dev/null $TMP

            if [ "$NUMBER_OF_PROCESS_COUNT" != 0 -o "$NUMBER_OF_BLOCKS" != 0 ]; then
               count=`$MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "select count(*) from information_schema.PROCESSLIST where USER = '$USER'" | /bin/grep -v count`

               if [ "$NUMBER_OF_PROCESS_COUNT" != 0 ]; then
                  if [ "$count" -gt "$NUMBER_OF_PROCESS_COUNT" ]; then
                     if [ "$MAIL_LIST" != "" ]; then
                        $ECHO "Number of $USER Processes on Port $item is $count Which Has Exceeded Limit -- $NUMBER_OF_PROCESS_COUNT.\n" >> $TMP
                        $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "select * from information_schema.PROCESSLIST where USER = '$USER'" >> $TMP
                        $MAIL -s "Number of $USER Processes on Port $item Has Exceeded Limit -- $NUMBER_OF_PROCESS_COUNT" $MAIL_LIST < $TMP
                     else
                        $ECHO "\nNumber of $USER Processes on Port $item is $count Which Has Exceeded Limit -- $NUMBER_OF_PROCESS_COUNT.\n"
                        $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "select * from information_schema.PROCESSLIST where USER = '$USER'"
                     fi
                  fi
               else
                  $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show full processlist;" >> $TMP

                  if [ `/bin/cat $TMP | /bin/egrep -e 'table level lock|Locked|preparing' | /usr/bin/wc -l` -gt $NUMBER_OF_BLOCKS ]; then
                     /bin/cp /dev/null $TMP
                     /bin/sleep 15
         
                     $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show full processlist;" >> $TMP
             
                     if [ `/bin/cat $TMP | /bin/egrep -e 'table level lock|Locked|preparing' | /usr/bin/wc -l` -gt $NUMBER_OF_BLOCKS ]; then
                        /bin/cp /dev/null $TMP
                        /bin/sleep 15
         
                        $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show full processlist;" >> $TMP
   
                        if [ `/bin/cat $TMP | /bin/egrep -e 'table level lock|Locked|prepaing' | /usr/bin/wc -l` -gt $NUMBER_OF_BLOCKS ]; then
                           /bin/cat $TMP >> $TMP1
                           /bin/cat $TMP | /bin/egrep -e 'Sending data|Sorting result|Sorting for group|Copying to tmp table|Writing to net|update|updating|cleaning up|statistics|end|Waiting for global read lock' | /bin/egrep -v -e "updated|show full processlist|binlog|NULL|table level lock|Locked" >> $TMP2
                        fi
                     fi
                  else
                     /bin/cp /dev/null $TMP
                  fi

                  SIZE=`/bin/cat $TMP1 | /usr/bin/wc -l`

                  if [ "$SIZE" -gt 10 ]; then
                     /bin/cp /dev/null $TMP
           
                     $ECHO "\nProcesses Are Getting Blocked on Port $item.\n" >> $TMP
                     /bin/cat $TMP1 >> $TMP
             
                     SIZE=`/bin/cat $TMP2 | /usr/bin/wc -l`
   
                     if [ "$SIZE" -gt 0 ]; then
                        $ECHO "\nThe Following Process(es) May be the Culprit(s):\n" >> $TMP
                        /bin/cat $TMP2 >> $TMP

                        if [ "$KILL" = "Y" ]; then
                           $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show slave status\G" >> $TMP5

                           if `/bin/cat $TMP5 | /bin/egrep -e 'Seconds_Behind_Master' > /dev/null`; then
                              if [ `/bin/cat $TMP5 | /bin/egrep -e 'Seconds_Behind_Master' | /bin/awk '{print $2}'` != "NULL" ]; then
                                 NUM_MIN=`/bin/cat $TMP5 | /bin/egrep -e 'Seconds_Behind_Master' | /bin/awk '{print $2}'`

                                 if [ $NUM_MIN -gt 180 ]; then
                                    if `/bin/cat $TMP2 | /bin/egrep -e "SELECT  " > /dev/null`; then
                                       /bin/cat $TMP2 | /bin/egrep -e "SELECT  " | /bin/awk '{print $1}' >> $TMP3

                                       $ECHO "\nKilling Offending Process(es) on Port $item.\n" >> $TMP4
                                       /bin/cat $TMP2 | /bin/egrep -e "SELECT  " >> $TMP4

                                       for id in `/bin/cat $TMP3`
                                       do
                                          $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "kill $id;"
                                       done
                                    fi
                                 fi
                              fi
                           fi
                        fi
                     fi
                  fi

                  SIZE=`/bin/cat $TMP | /usr/bin/wc -l`

                  if [ "$SIZE" -gt 0 ]; then
                     if [ "$MAIL_LIST" != "" ]; then
                        if [ "$KILL" = "Y" ]; then
                           SIZE=`/bin/cat $TMP4 | /usr/bin/wc -l`
 
                           if [ "$SIZE" -gt 100 ]; then
                              $MAIL -s "Processes Are Getting Blocked on Port $item" $MAIL_LIST < $TMP
                              $MAIL -s "Blocking Process(es) on Port $item Has Been Killed Off" $MAIL_LIST < $TMP4
                           fi
                        else
                           $MAIL -s "Processes Are Getting Blocked on Port $item" $MAIL_LIST < $TMP
                        fi
                     else
                        if [ "$KILL" = "Y" ]; then
                           SIZE=`/bin/cat $TMP4 | /usr/bin/wc -l`
 
                           if [ "$SIZE" -gt 100 ]; then
                              $ECHO "\nProcesses Are Getting Blocked on Port $item.\n"
                              /bin/cat $TMP
                              $ECHO "\nBlocking Process(es) on Port $item Has Been Killed Off.\n"
                              /bin/cat $TMP4
                           fi
                        else
                           $ECHO "\nProcesses Are Getting Blocked on Port $item.\n"
                           /bin/cat $TMP
                        fi
                     fi
                  fi
               fi
            else
               if [ "$SHOW_PROCESSLIST" = "Y" ]; then
                  $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show slave status\Gshow full processlist;" >> $TMP
               else
                  $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT -e "show slave status\G" >> $TMP
               fi
 
               if `/bin/cat $TMP | /bin/egrep -e 'Seconds_Behind_Master' > /dev/null`; then
                  if [ `/bin/cat $TMP | /bin/egrep -e 'Seconds_Behind_Master' | /bin/awk '{print $2}'` != "NULL" ]; then
                     if [ `/bin/cat $TMP | /bin/egrep -e 'Seconds_Behind_Master' | /bin/awk '{print $2}'` -gt "$LATENCY" ]; then
                        let NUM_MINS=`expr $LATENCY \/ 60`

                        if [ "$MAIL_LIST" != "" ]; then
                           $MAIL -s "Warning!! Replication on Port $item is More Than $NUM_MINS Min(s) Behind Master!" $MAIL_LIST < $TMP
                        else
                           $ECHO "\nWarning!! Replication on Port $item is More Than $NUM_MINS Min(s) Behind Master!\n" >> $TMP1
                           /bin/cat $TMP >> $TMP1
                           /bin/cat $TMP1
                        fi
                     else
                        if [ "$MAIL_LIST" = "" ]; then
                           $ECHO "\nNo Significant Latency Found on Replication Status for Port $item.\n"
                        fi
                     fi
                  fi
               fi
            fi

            /bin/rm -f $TMP $TMP1 $TMP2 $TMP3 $TMP4 $TMP5
         done
      else
         if [ "$MAIL_LIST" != "" ]; then
             $MAIL -s "$FILE is Empty!! Cancelling Monitor Process for Port(s) Listed in $FILE" $MAIL_LIST < /dev/null
         else
             $ECHO "\n$FILE is Empty!! Cancelling Monitor Process for Port(s) Listed in $FILE.\n"
         fi
      fi
   fi
fi

exit 0
