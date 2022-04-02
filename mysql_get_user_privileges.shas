#!/bin/bash
################################################################################
#
# Author:
#       Anil Alpati
#
# Purpose:
#       Get MySQL User privileges
#
# Date:
#       08-DEC-2014
################################################################################

# Program name.
progname=`basename $0`

# Working directory.
workdir=`dirname $0`

# Server and port list.
server_port_list=mysql_server_port_list.txt

# SQL script.
sql_script=mysql_get_user_privileges.sql

# User Access Directory
user_access_list=$workdir/user_access_list

# Date info.
date=$(date +'%F %T %Z')
year=$(date +'%Y' -d "$date")
month_numeric=$(date +'%m' -d "$date")
month_abbr=$(date +'%b' -d "$date")

################################################################################
# Functions
################################################################################


function clean_up
{
        #####
        #       Function to remove temporary files and other housekeeping
        #       No arguments
        #####

        rm -f ${TEMP_FILE}
}

function graceful_exit
{
        #####
        #       Function called for a graceful exit
        #       No arguments
        #####

        clean_up
        exit
}

function error_exit {
        # Function for exit due to fatal program error
        # Accepts 1 argument
        #       string containing descriptive error message
        echo "${progname}: ${1:-"Unknown Error"}" 1>&2
        clean_up
        exit 1
}


if [[ -d $user_access_list ]]; then
        echo "Directory exists"

else
        echo "Directory doesn\'t exists"
        echo "Creating directory"
        mkdir -p $user_access_list
        echo "Done."
fi

################################################################################
# Program starts here
################################################################################
echo "************************************************************"
echo "SCRIPT START"
date +"Time: %F %T %Z"
echo "************************************************************"

for server_port in `cat $workdir/$server_port_list`
do
        server=`echo $server_port | awk -F: '{ print $1 }'`
        ip=`echo $server_port | awk -F: '{ print $2 }'`
        port=`echo $server_port | awk -F: '{ print $3 }'`
        env=`echo $server_port | awk -F: '{ print $4 }'`
        network=`echo $server_port | awk -F: '{ print $5 }'`
        user=`echo $server_port | awk -F: '{ print $6 }'`
        pw=`echo $server_port | awk -F: '{ print $7 }'`
        echo "env is $env and network is $network";
        if [[ $env = "devapollogrp.edu" && "$network" = "dev" ]]; then
                echo
                echo "************************************************************"
                echo "Server: $server"
                echo "IP:     $ip"
                echo "Port:   $port"
                echo "Env: $env"
                echo "Network: $network"
                echo "************************************************************"
                echo
                # MySQL connection string.
                myc="mysql --host=$server --port=$port --user=$user --password=$pw"
                echo  "MySQL User Access on $server"  > $user_access_list/DB_UserAccount_$server.sql
                echo  "MySQL User Access on $server"
                #$myc --table -v -e "SHOW DATABASES; SELECT host, user, password FROM mysql.user where user not in('root','newrelic',' ','splunk');"  >> $user_access_list/DB_UserAccount_$server.sql
                $myc --table -v -e "SELECT host, user FROM mysql.user where user not in('root','newrelic',' ','splunk') ;"  >> $user_access_list/DB_UserAccount_$server.sql
        #       $myc --table -v -e "SHOW DATABASES; SELECT host, user, password FROM mysql.user where user not in('root','newrelic',' ','splunk');"
        #       echo
        #       $myc -Bse "SELECT CONCAT('SHOW GRANTS FOR \'', user ,'\'@\'', host, '\';') FROM mysql.user where user not in('root','newrelic',' ','splunk')" | $myc -Bsr | sed 's/$/;/g' >> $user_access_list/DB_UserAccount_$server.sql
        #       $myc -Bse "SELECT CONCAT('SHOW GRANTS FOR \'', user ,'\'@\'', host, '\';') FROM mysql.user where user not in('root','newrelic',' ','splunk')" | $myc -Bsr | sed 's/$/;/g'
         elif [[ $env = "qaapollogrp.edu" && "$network" = "qa" ]]; then
                echo
                echo "************************************************************"
                echo "Server: $server"
                echo "IP:     $ip"
                echo "Port:   $port"
                echo "Env: $env"
                echo "Network: $network"
                echo "************************************************************"
                echo
                # MySQL connection string.
                myc="mysql --host=$server --port=$port --user=$user --password=$pw"
                echo  "MySQL User Access on $server"  > $user_access_list/DB_UserAccount_$server.sql
                echo $myc
                echo  "MySQL User Access on $server"
                #$myc --table -v -e "SHOW DATABASES; SELECT host, user, password FROM mysql.user where user not in('root','newrelic',' ','splunk');"  >> $user_access_list/DB_UserAccount_$server.sql
                $myc --table -v -e "SELECT host, user FROM mysql.user where user not in('root','newrelic',' ','splunk');"  >> $user_access_list/DB_UserAccount_$server.sql
           #     $myc --table -v -e "SHOW DATABASES; SELECT host, user, password FROM mysql.user where user not in('root','newrelic',' ','splunk');"
                echo
          #      $myc -Bse "SELECT CONCAT('SHOW GRANTS FOR \'', user ,'\'@\'', host, '\';') FROM mysql.user where user not in('root','newrelic',' ','splunk')" | $myc -Bsr | sed 's/$/;\n/g' >> $user_access_list/DB_UserAccount_$server.sql
          #      $myc -Bse "SELECT CONCAT('SHOW GRANTS FOR \'', user ,'\'@\'', host, '\';') FROM mysql.user where user not in('root','newrelic',' ','splunk')" | $myc -Bsr | sed 's/$/;/g'
          elif [[ $env = "apollogrp.edu" && "$network" = "prd" ]]; then
                echo
                echo "************************************************************"
                echo "Server: $server"
                echo "IP:     $ip"
                echo "Port:   $port"
                echo "Env: $env"
                echo "Network: $network"
                echo "************************************************************"
                echo
                # MySQL connection string.
                myc="mysql --host=$server --port=$port --user=$user --password=$pw"
                echo  "MySQL User Access on $server"  > $user_access_list/DB_UserAccount_$server.sql
                echo $myc
                echo  "MySQL User Access on $server"
                #$myc --table -v -e "SHOW DATABASES; SELECT host, user, password FROM mysql.user where user not in('root','newrelic',' ','splunk');"  >> $user_access_list/DB_UserAccount_$server.sql
                $myc --table -v -e "SELECT host, user FROM mysql.user where user not in('root','newrelic',' ','splunk');"  >> $user_access_list/DB_UserAccount_$server.sql
           #     $myc --table -v -e "SHOW DATABASES; SELECT host, user, password FROM mysql.user where user not in('root','newrelic',' ','splunk');"
                echo
           #        $myc -Bse "SELECT CONCAT('SHOW GRANTS FOR \'', user ,'\'@\'', host, '\';') FROM mysql.user where user not in('root','newrelic',' ','splunk')" | $myc -Bsr | sed 's/$/;\n/g' >> $user_access_list/DB_UserAccount_$server.sql
           #      $myc -Bse "SELECT CONCAT('SHOW GRANTS FOR \'', user ,'\'@\'', host, '\';') FROM mysql.user where user not in('root','newrelic',' ','splunk')" | $myc -Bsr | sed 's/$/;/g'
      fi
done
echo "Zipping reports..."
cd $user_access_list || error_exit "Error on line $LINENO. Could not perform action."
zip "MySQL_Security_Report_${year}_${month_abbr}.zip" *.sql
echo "Done."
echo

echo
echo "************************************************************"
echo "SCRIPT END"
date +"Time: %F %T %Z"
echo "************************************************************"


graceful_exit

