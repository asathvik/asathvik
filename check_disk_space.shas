#!/bin/sh
#
# This script checks available disk space on local host and sends a warning when it
# falls below a threshold level.
#
# Author       : Anil Kumar. Alpati
# Last Modified: 07/31/2014

. /var/mysql/dba/environment/global_stuff

# set USAGE
USAGE="usage: `basename $0` -X threshold_level [ -M 'email1 email2 email3 ...' ]"
USAGE1="usage: Threshold Level Has to be a Positive #"

#null ARGS
THRESHOLD=0
MAIL_LIST=
RESULT=
RESULT1=0
FLAG=0

OUTFILE=$LOGS/`/bin/basename $0`_$$.out
OUTFILE1=$LOGS/`/bin/basename $0`_$$.out.1

/bin/rm -f $OUTFILE
/bin/rm -f $OUTFILE1

# getopts ARGS
while getopts X:M: VAR
do
   case $VAR in
      X) THRESHOLD=$OPTARG
         ;;
      M) MAIL_LIST=$OPTARG
         ;;
      *) $ECHO
         $ECHO $USAGE
         $ECHO $USAGE1
         exit 1
         ;;
   esac
done

if [ $THRESHOLD = 0 -o \
     $THRESHOLD -lt 0 ]; then
   $ECHO
   $ECHO $USAGE
   $ECHO $USAGE1
   exit 2
fi

RESULT=`/bin/df -h | /bin/awk '{print $5}' | /bin/cut -c 1-3`

for item in `$ECHO $RESULT`
do
   if [ "$item" != "Use" ]; then
      RESULT1=${item%?}

      if [ $RESULT1 -gt $THRESHOLD ]; then
         /bin/df -h | /bin/egrep -e $item >> $OUTFILE
         FLAG=1
      fi
   fi
done

if [ $FLAG = 1 ]; then
   SIZE=`/bin/ls -al $OUTFILE | /bin/awk '{print $5}'`

   if [ $SIZE -gt 0 ]; then
      TITLE="Warning!! Disk Space Usage on `/bin/hostname` Has Exceeded Threshold Level ($THRESHOLD%)"

      if [ "$MAIL_LIST" = "" ]; then
         $ECHO "\n$TITLE\n"
         /bin/df -h | /usr/bin/head -1
         /bin/cat $OUTFILE
      else
          $ECHO "Following is Current Disk Space Usage on `/bin/hostname`\n" >> $OUTFILE1
          /bin/df -h | /usr/bin/head -1 >> $OUTFILE1
          /bin/cat $OUTFILE >> $OUTFILE1
         
          $MAIL -s "$TITLE" $MAIL_LIST < $OUTFILE1
      fi

      /bin/rm -f $OUTFILE
      /bin/rm -f $OUTFILE1
   fi
fi

exit 0
