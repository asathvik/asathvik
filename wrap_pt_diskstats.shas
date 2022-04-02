#!/bin/sh
#
# This script uses Percona 'pt-diskstats' tool to check response time on read and write operations,
# and sends a warning to specified recipients when it sees response time of either operation exceeds
# a specified threshold level.
#
# Author       : Anil Kumar. Alpati
# Last Modified: 10/14/2014

. /var/mysql/dba/environment/global_stuff

# Set usage
USAGE="Usage: `basename $0` -X threshold [ -M email1 email2 email3... ]"
USAGE1="Usage: Please Specify Threshold Level in Milisecond."

THRESHOLD=
MAIL_LIST=
FLAG_1=0
FLAG_2=0
REPORT_1=0
REPORT_2=0
STATUS=0

# Command line options.
while getopts "X:M:" options; do
   case $options in
      X) THRESHOLD=$OPTARG
         ;;
      M) MAIL_LIST=$OPTARG
         ;;
      *) $ECHO
         $ECHO $USAGE
         exit 1
         ;;
   esac
done

if [ "$THRESHOLD" = "" ]; then
   $ECHO
   $ECHO $USAGE
   $ECHO $USAGE1
   exit 2
fi

HOSTNAME=`/bin/hostname -s`

LOGFILE=$LOGS/pt-diskstats_"$HOSTNAME"_`/bin/date '+%m-%d-%y_%H:%M:%S'`
LOGFILE1=$LOGS/pt-diskstats_"$HOSTNAME_$$"
LOGFILE2_1=$LOGS/pt-diskstats_"$HOSTNAME"_1
LOGFILE2_2=$LOGS/pt-diskstats_"$HOSTNAME"_2

START_TIME=`/bin/date '+%Y-%m-%d %H:%M'`

$ECHO "\nChecking Response Time For Read and Write Operations on $HOSTNAME at $START_TIME. Please Wait...\n"

myuser
mypasswd

/usr/bin/pt-diskstats --devices-regex=sd --columns 'rd_s|rd_mb_s|rd_avkb|rd_rt|rd_mrg|wr_s|wr_mb_s|wr_avkb|wr_rt|wr_mrg|qtime|stime|ios_s|await|busy' --iterations=1 --interval=59  > $LOGFILE

/bin/cat $LOGFILE | /bin/grep -v device | /bin/awk '{print $7}' > $LOGFILE1

for item in `/bin/cat $LOGFILE1`
do
   STATUS=`/bin/echo "$item > $THRESHOLD" | /usr/bin/bc`

   if [ "$STATUS" = 1 ]; then
      FLAG_1=1
   fi
done

if [ "$FLAG_1" = 1 ]; then
   if [ ! -f $LOGFILE2_1 ]; then
      $ECHO "1" > $LOGFILE2_1
   else
      if [ `/bin/cat $LOGFILE2_1` -eq 2 ]; then
         REPORT_1=1
      else
         $ECHO "2" > $LOGFILE2_1
       fi
   fi
fi

/bin/cat $LOGFILE | /bin/grep -v device | /bin/awk '{print $12}' > $LOGFILE1

for item in `/bin/cat $LOGFILE1`
do
   STATUS=`/bin/echo "$item > $THRESHOLD" | /usr/bin/bc`

   if [ "$STATUS" = 1 ]; then
      FLAG_2=1
   fi
done
 
if [ "$FLAG_2" = 1 ]; then
   if [ ! -f $LOGFILE2_2 ]; then
      $ECHO "1" > $LOGFILE2_2
   else
      if [ `/bin/cat $LOGFILE2_2` -eq 2 ]; then
         REPORT_2=1
      else
         $ECHO "2" > $LOGFILE2_2
      fi
   fi
fi

if [ "$MAIL_LIST" != "" ]; then
   if [ "$REPORT_1" = 1 ]; then
      TITLE="Warning!! Read or Write Response Time on Following Device(s) Have Exceeded Threshold Level of $THRESHOLD Miliseconds on $HOSTNAME"
      $MAIL -s "$TITLE" $MAIL_LIST < $LOGFILE

      /bin/rm -f $LOGFILE2_1
   elif [ "$REPORT_2" = 1 ]; then
      TITLE="Warning!! Read or Write Response Time on Following Device(s) Have Exceeded Threshold Level of $THRESHOLD Miliseconds on $HOSTNAME"
      $MAIL -s "$TITLE" $MAIL_LIST < $LOGFILE

      /bin/rm -f $LOGFILE2_2
   fi
else
   if [ "$REPORT_1" = 1 ]; then
      $ECHO "\nWarning!! Read or Write Response Time on Following Device(s) Has Exceeded Threshold Level of $THRESHOLD Miliseconds on $HOSTNAME.\n"
      /bin/cat $LOGFILE

      /bin/rm -f $LOGFILE2_1
   elif [ "$REPORT_2" = 1 ]; then
      $ECHO "\nWarning!! Read or Write Response Time on Following Device(s) Has Exceeded Threshold Level of $THRESHOLD Miliseconds on $HOSTNAME.\n"
      /bin/cat $LOGFILE

      /bin/rm -f $LOGFILE2_2
   fi
fi

/bin/rm -f $LOGFILE $LOGFILE1

exit 0
