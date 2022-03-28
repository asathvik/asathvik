#!/bin/sh
#This scripts returns all the tables in a database that contains same field

. /var/mysql/dba/environment/global_stuff

myuser
mypasswd

function usage
{
$ECHO "Usage: $0 USER DB COLUMN"
}

function ExistsColumn
{
local DB=$1
local TABLE=$2
local COLUMN=$3

SEARCH_RESULT=$(mysqlshow -u $USER -p$PASSWD $DB $TABLE $COLUMN | /bin/awk '{ if ( NR == 5) print $2 }')

if [ "$COLUMN" = "$SEARCH_RESULT" ]; then
   $ECHO "true";
else
   $ECHO "false";
fi
}

function main
{
local DB=$1
local TABLE=$2
local COLUMN=$3

if [[ "$DB" = "" || "$COLUMN" = "" ]]; then
   usage
   exit 1
fi

all_tables=$(mysqlshow -u $USER -p$PASSWD $DB | /bin/awk '{ if (NR >4 ) print $_}' | /bin/sed -e 's/[|+-]//g; /^$/d ' | xargs )

#$ECHO "all_tables = "$all_tables
$ECHO "\nHere's a List of Tables With Column '$COLUMN':\n"

for TABLE in $all_tables; do
   if [ "true" = "$(ExistsColumn $DB $TABLE $COLUMN)" ]; then
      $ECHO $TABLE
   fi
done
}

main $*
