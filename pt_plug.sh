#!/bin/bash

. /var/mysql/dba/environment/global_stuff

trg_plugin() {
mysqladmin $EXT_ARGV ping &> /dev/null mysqld_alive=$?

if [[ $mysqld_alive == 0 ]]
then
   Threads_running=$(mysql -e "show global status like 
   'Threads_running';" | grep -i "Threads_running" | awk '{print $2}') 
   $ECHO $Threads_running
else 
   $ECHO 1 
fi }

# Uncomment below to test that trg_plugin function works as expected 
#trg_plugin

exit 0
