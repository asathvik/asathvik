#!/bin/sh
#
# This script logs on to specified MySQL port and generates schemas for all types of objects --
# db, table, procedure, function, trigger, and view in each specified db. 
#
# Author       : Anil Kumar. Alpati
# Last Modified: 02/05/2015

. /var/mysql/dba/environment/global_stuff

# set USAGE
USAGE="usage: `basename $0` -H MySQL_local_port_dir -P port_number [ -D 'db_name1 db_name2 db_name3...' ] -T dir_location"
USAGE1="usage: MySQL Port Has to be Specified in the Form of machine_name:port_number"

#null ARGS
DB_NAME=
PORT=
MYSQL_LOCAL_PORT=
DIR_LOC=

# getopts ARGS
while getopts H:P:D:T: VAR
do
   case $VAR in
      H) MYSQL_LOCAL_PORT=$OPTARG
         ;;
      P) PORT=$OPTARG
         ;;
      D) DB_NAME=$OPTARG
         ;;
      T) DIR_LOC=$OPTARG
         ;;
      *) $ECHO
         $ECHO $USAGE
         $ECHO $USAGE1
         exit 1
         ;;
   esac
done

if [ "$MYSQL_LOCAL_PORT" = "" ]; then
   $ECHO
   $ECHO $USAGE
   exit 2
elif ! [ -d $MYSQL_LOCAL_PORT ]; then
   $ECHO
   $ECHO "\nWarning!!! Directory $MYSQL_LOCAL_PORT Not Found!\n"
   exit 3
fi

if [ "$PORT" = "" ]; then
   $ECHO
   $ECHO $USAGE
   $ECHO $USAGE1
   exit 4
fi

if [ "$DIR_LOC" = "" ]; then
   $ECHO
   $ECHO $USAGE
   $ECHO $USAGE1
   exit 5
fi

myuser
mypasswd

MACHINE=`$ECHO $PORT | /bin/cut -f1 -d ':'`
PORT_NUMBER=`$ECHO $PORT | /bin/cut -f2 -d ':'`

$ECHO "\nLogging on to Port: $PORT_NUMBER on Host: $MACHINE To Generate Schemas. Please Wait...\n"

TMP11=$LOGS/`/bin/basename $0`_$$.out.5
/bin/cp /dev/null $TMP11

if [ "$DB_NAME" = "" ]; then
   $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D information_schema -e "select SCHEMA_NAME from SCHEMATA where SCHEMA_NAME not in ('backup', 'dump', 'information_schema', 'percona', 'performance_schema', 'openv', 'test', 'temp') and SCHEMA_NAME not like '#%' order by SCHEMA_NAME;" | /bin/grep -v SCHEMA_NAME >> $TMP11
   
   for item in `/bin/cat $TMP11`
   do
      DB_NAME=$DB_NAME" "$item" "
   done
fi

/bin/rm -f $TMP11

for db_name in `$ECHO $DB_NAME`
do
   if [ ! -d $DIR_LOC ]; then
      $ECHO "\n$DIR_LOC Not Found! Cancelling Generate Schema Process.\n"
      break
   fi

   #Create db schema
   TMP0=$LOGS/CREATE_DATABASE_$db_name.sql
   /bin/cp /dev/null $TMP0

   $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -Ee "SHOW CREATE DATABASE $db_name;" | /bin/egrep -v "row|ERROR" | /bin/sed 1d | /bin/sed 's/Create Database:/ /g' | /bin/sed 's/*\//*\/;/g' >> $TMP0

   SIZE=`/bin/cat $TMP0 | /usr/bin/wc -l`

   if [ "$SIZE" -eq 0 ]; then
      $ECHO "\nDatabase $db_name Not Found! Cancelling Genarate Schema Process.\n"
      /bin/rm -f $TMP0
      break
   else
      /bin/mkdir -p -m 755 $DIR_LOC/$db_name

      if [ "$?" -ne "0" ]; then
         $ECHO "\nFailed to Create Sub-directory under $DIR_LOC. Cancelling Generate Schema Process.\n"
         break
      fi

      /bin/mkdir -p -m 755 $DIR_LOC/$db_name/db
      
      if [ "$?" -ne "0" ]; then
         $ECHO "\nFailed to Create Sub-directory under $DIR_LOC. Cancelling Generate Schema Process.\n"
         break
      else
         DB_DIR=$DIR_LOC/$db_name/db
         TMP=$DB_DIR/CREATE_DATABASE_$db_name.sql
         /bin/cp /dev/null $TMP

         $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -Ee "SHOW CREATE DATABASE $db_name;" | /bin/egrep -v "row|ERROR" | /bin/sed 1d | /bin/sed 's/Create Database:/ /g' | /bin/sed 's/*\//*\/;/g' >> $TMP
      fi
   fi

   /bin/rm -f $TMP0

   #Create table schema
   TMP1=$LOGS/`/bin/basename $0`_$$.out.0
   /bin/cp /dev/null $TMP1

   $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D information_schema -e "SELECT CONCAT('SHOW CREATE TABLE ', TABLE_NAME, ';') from TABLES where TABLE_SCHEMA = '$db_name' and TABLE_TYPE = 'BASE TABLE' order by TABLE_NAME;" | /bin/grep -v CONCAT >> $TMP1

   SIZE=`/bin/cat $TMP1 | /usr/bin/wc -l`

   if [ "$SIZE" -eq 0 ]; then
      $ECHO "\nNo Table Found in Database $db_name!\n"
   else
      /bin/mkdir -p -m 755 $DIR_LOC/$db_name/table
      
      if [ "$?" -ne "0" ]; then
         $ECHO "\nFailed to Create Sub-directory under $DIR_LOC. Cancelling Generate Schema Process.\n"
         break
      else
         TABLE_DIR=$DIR_LOC/$db_name/table

         while read line
         do
            TMP2=$TABLE_DIR/`$ECHO $line | /bin/sed 's/SHOW //g' | /bin/sed 's/ /_/g' | /bin/sed 's/;//g'`.sql
            /bin/cp /dev/null $TMP2

            $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D $db_name -Ee "$line" | /bin/egrep -v "\*|  Table" | /bin/sed 's/Create Table:/ /g' >> $TMP2
         done < $TMP1
      fi
   fi

   /bin/rm -f $TMP1

   #Create procedure schema
   TMP3=$LOGS/`/bin/basename $0`_$$.out.1
   /bin/cp /dev/null $TMP3

   $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D information_schema -Ee "SELECT CONCAT('SHOW CREATE PROCEDURE ', SPECIFIC_NAME, '\\\G') from ROUTINES where ROUTINE_SCHEMA = '$db_name' AND ROUTINE_TYPE = 'PROCEDURE' order by ROUTINE_NAME;" | /bin/egrep -v "\*" | /bin/cut -f2 -d ':' >> $TMP3

   SIZE=`/bin/cat $TMP3 | /usr/bin/wc -l`

   if [ "$SIZE" -eq 0 ]; then
      $ECHO "\nNo Procedure Found in Database $db_name!\n"
      /bin/rm -f $TMP3
   else
      /bin/mkdir -p -m 755 $DIR_LOC/$db_name/procedure
      
      if [ "$?" -ne "0" ]; then
         $ECHO "\nFailed to Create Sub-directory under $DIR_LOC. Cancelling Generate Schema Process.\n"
         break
      else
         PROC_DIR=$DIR_LOC/$db_name/procedure

         while read -r line
         do
            TMP4=$PROC_DIR/`$ECHO $line | /bin/sed 's/SHOW //g' | /bin/sed 's/ /_/g' | /bin/sed 's/\\\G//g'`.sql
            /bin/cp /dev/null $TMP4

            $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D $db_name -Ee "$line" | /bin/egrep -v "\*|row in set" | /bin/sed 's/Create Procedure: //g' | /bin/egrep -v "Procedure:|sql_mode|character_set_client:|collation_connection:|Database Collation:" >> $TMP4
         done < $TMP3
      fi
   fi

   /bin/rm -f $TMP3

   #Create function schema
   TMP5=$LOGS/`/bin/basename $0`_$$.out.2
   /bin/cp /dev/null $TMP5

   $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D information_schema -Ee "SELECT CONCAT('SHOW CREATE FUNCTION ', SPECIFIC_NAME, '\\\G') from ROUTINES where ROUTINE_SCHEMA = '$db_name' AND ROUTINE_TYPE = 'FUNCTION' order by ROUTINE_NAME;" | /bin/egrep -v "\*" | /bin/cut -f2 -d ':' >> $TMP5

   SIZE=`/bin/cat $TMP5 | /usr/bin/wc -l`

   if [ "$SIZE" -eq 0 ]; then
      $ECHO "\nNo Function Found in Database $db_name!\n"
   else
      /bin/mkdir -p -m 755 $DIR_LOC/$db_name/function
      
      if [ "$?" -ne "0" ]; then
         $ECHO "\nFailed to Create Sub-directory under $DIR_LOC. Cancelling Generate Schema Process.\n"
         break
      else
         FUNCT_DIR=$DIR_LOC/$db_name/function

         while read -r line
         do
           TMP6=$FUNCT_DIR/`$ECHO $line | /bin/sed 's/SHOW //g' | /bin/sed 's/ /_/g' | /bin/sed 's/\\\G//g'`.sql
           /bin/cp /dev/null $TMP6

           $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D $db_name -Ee "$line" | /bin/egrep -v "\*|row in set" | /bin/sed 's/ Create Function: //g' | /bin/egrep -v "Function:|sql_mode|character_set_client:|collation_connection:|Database Collation:" >> $TMP6
         done < $TMP5
      fi
   fi

   /bin/rm -f $TMP5

   #Create trigger schema
   TMP7=$LOGS/`/bin/basename $0`_$$.out.3
   /bin/cp /dev/null $TMP7

   $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D information_schema -Ee "SELECT CONCAT('SHOW CREATE TRIGGER ', TRIGGER_NAME, '\\\G') from TRIGGERS where TRIGGER_SCHEMA = '$db_name' order by TRIGGER_NAME;" | /bin/egrep -v "\*" | /bin/cut -f2 -d ':' >> $TMP7

   SIZE=`/bin/cat $TMP7 | /usr/bin/wc -l`

   if [ "$SIZE" -eq 0 ]; then
      $ECHO "\nNo Trigger Found in Database $db_name!\n"
   else
      /bin/mkdir -p -m 755 $DIR_LOC/$db_name/trigger
      
      if [ "$?" -ne "0" ]; then
         $ECHO "\nFailed to Create Sub-directory under $DIR_LOC. Cancelling Generate Schema Process.\n"
         break
      else
         TRIG_DIR=$DIR_LOC/$db_name/trigger

         while read -r line
         do
           TMP8=$TRIG_DIR/`$ECHO $line | /bin/sed 's/SHOW //g' | /bin/sed 's/ /_/g' | /bin/sed 's/\\\G//g'`.sql
           /bin/cp /dev/null $TMP8

           $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D $db_name -Ee "$line" | /bin/egrep -v "\*|row in set|Trigger:|sql_mode:|character_set_client:|collation_connection:|Database Collation:" | /bin/sed s'/SQL Original Statement: //g' >> $TMP8
         done < $TMP7
      fi
   fi

   #Create view schema
   TMP9=$LOGS/`/bin/basename $0`_$$.out.4
   /bin/cp /dev/null $TMP9

   $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D information_schema -Ee "SELECT CONCAT('SHOW CREATE VIEW ', TABLE_NAME, '\\\G') from VIEWS where TABLE_SCHEMA = '$db_name' order by TABLE_NAME;" | /bin/egrep -v "\*" | /bin/cut -f2 -d ':' >> $TMP9

   SIZE=`/bin/cat $TMP9 | /usr/bin/wc -l`

   if [ "$SIZE" -eq 0 ]; then
      $ECHO "\nNo View Found in Database $db_name!\n"
   else
      /bin/mkdir -p -m 755 $DIR_LOC/$db_name/view
      
      if [ "$?" -ne "0" ]; then
         $ECHO "\nFailed to Create Sub-directory under $DIR_LOC. Cancelling Generate Schema Process.\n"
         break
      else
         VIEW_DIR=$DIR_LOC/$db_name/view

         while read -r line
         do
           TMP10=$VIEW_DIR/`$ECHO $line | /bin/sed 's/SHOW //g' | /bin/sed 's/ /_/g' | /bin/sed 's/\\\G//g'`.sql
           /bin/cp /dev/null $TMP10

           $MYSQL -u $USER -p$PASSWD -h$MACHINE -P$PORT_NUMBER -D $db_name -Ee "$line" | /bin/sed s'/Create View: //g' | /bin/egrep -v "\*|row in set|View:|character_set_client:|collation_connection:|Database Collation:" >> $TMP10
         done < $TMP9
      fi
   fi

   /bin/rm -f $TMP9
done

exit 0
