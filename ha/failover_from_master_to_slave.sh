#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
# Purpose:
#	Support failover from MySQL master to slave replicate in case master 
#	goes down.
# Usage:
#	failover_from_master_to_slave.sh
# Revisions:
#	08/06/2007 - Dimitriy Alekseyev
#	Script created with basic functionality. Need to add error handling.
#	Also need to add variables, instead of using constant values.
################################################################################


################################################################################
# Global Variables and Constants
################################################################################

# Program name.
progname=`basename $0`

database=clsdpmst

master_host=data010
master_port=3315
master_user=dbmon
master_pass=w4tch0db

slave_port=
slave_user=
slave_pass=


################################################################################
# Program starts here
################################################################################

echo "**************************************************"
echo "* Database Failover from Master to Slave"
echo "* Time started:" `date +'%F %T %Z'`
echo "**************************************************"
echo
echo "Database        =" $database
echo "Master host     =" $master_host
echo "Master port     =" $master_port
echo "Slave host      =" `hostname`.`dnsdomainname`
echo "Slave port      =" $slave_port
echo

echo "Checking if master is OK..."
/dba_share/mysql_scripts/nagios/check_mysql_database.sh -h $master_host -P 3315 -u $master_user -p $master_pass -d $database
if [ $? = 0 ]; then
	echo "Failover is not needed."
	echo
	echo "**************************************************"
	echo "* Time completed:" `date +'%F %T %Z'`
	echo "**************************************************"
	exit 0
fi

echo
echo "***** Initiating failover process. Master seems to be down. *****"

echo
echo "Show slave status:"
echo "SHOW SLAVE STATUS\G;" | m2c.sh

#### Add code which waits until relay log has been processed.

echo
echo "Stop the slave threads..."
echo "STOP SLAVE;" | m2c.sh
#### Add error handling.

echo
echo "Promote slave to master..."
echo "CHANGE MASTER TO MASTER_HOST='';" | m2c.sh
#### Add error handling.

echo
echo "Show slave status:"
echo "SHOW SLAVE STATUS\G;" | m2c.sh

echo
echo "Set read_only variable to OFF..."
echo "SET GLOBAL read_only = OFF;" | m2c.sh
echo "SHOW VARIABLES LIKE 'read_only';" | m2c.sh
#### Add error handling.

echo
echo "Set read_only variable to OFF at start up, in case slave MySQL instance gets restarted..."
echo "SET GLOBAL read_only = OFF;" >> /usr/local/bin/mysql/m2_init.sql
#### Add error handling.

echo "Output of m2_init.sql:"
cat /usr/local/bin/mysql/m2_init.sql

#### Add code to replay binary logs which have not been processed from master.

echo
echo "**************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "**************************************************"
