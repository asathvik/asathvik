#!/bin/sh
read -p 'Username: ' USERNAME
read -p 'Password: ' PASSWORD
echo

USER=$USERNAME
PASSWD=$PASSWORD
port=3306

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
bold=`tput bold`

myremconn="mysql -u$USER -p$PASSWD --connect-timeout=5 --enable-cleartext-plugin"


for i in `sudo mysql -ss -e"show slave hosts;" | awk -F' ' '{print $2}'`
do
        status=`$myremconn -ss -h$i -e"show slave status\G"| egrep -i "Master_Host|Master_Port|Slave_IO_Running|Slave_SQL_Running|SQL_Remaining_Delay|Slave_SQL_Running_State"`
        if [  -z "$status" ]
        then
        echo "Its Either Master or not Reachable"
	fi
	echo -e $GREEN $i :$NC
        echo -e "$RED $status $NC"
	for j in `$myremconn -ss -h$i -e"show slave hosts;" | awk -F' ' '{print $2}'`
		do
			echo "leaf replica and clone source";
			status_leaf_replica=`$myremconn -ss -h$i -e"show slave status\G"| egrep -i "Master_Host|Master_Port|Slave_IO_Running|Slave_SQL_Running|SQL_Remaining_Delay|Slave_SQL_Running_State"`
		        if [  -z "$status_leaf_replica" ]
        		then
       				 echo "Its Either Master or not Reachable"
        		fi
			echo -e $GREEN $i :$NC
		        echo -e $RED $status_leaf_replica $NC

		done
	echo
	echo
done
