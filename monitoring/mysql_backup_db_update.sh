#!/bin/bash
################################################################################
# Purpose:
#   The purpose of this Shell script is to store backup status information
#   in db_tracking database and table is backup_status
#
# Developed by:
# Anil Kumar Alpati
#
# Usage:
#   ./mysql_backup_db_update.sh
# 
# Created:
# 2013-05-23 - Anil Kumar Alpati
# Script Created
# 2013-09-13 - Anil Kumar Alpati
# adeded conversion support for bytes, KB, MB, and TB
################################################################################
# Variables Declarations
#################################################################################
MINUS_DATE=`date  --date="1 days ago" +%Y%m%d`
user_name=`id -u -n`

if [ $user_name != "mysql" ]; 
then
	echo
	echo "You must be 'mysql' user not $user_name user";
	echo
	exit 1
fi


if [ $# == 0 ];
then
	echo
	echo "Please pass the filepath for logfiles - backlist.txt"
	echo
	exit 1
fi


LOG_FILES=$(cat $1)
#LOG_FILES=$(cat backlist.txt)
################################################################################
# Functions
################################################################################

function clean_up {
    # Function to remove temporary files and other housekeeping
    # No arguments
    rm -f ${tmp_file}
}

function graceful_exit {
    # Function called for a graceful exit
    # No arguments
    clean_up
    exit
}

################################################################################
# Database Connectivity
################################################################################

mycdbtrack="mysql --host=192.168.60.19 --port=3370 --user=dbauser --password=surfb0ard --database=db_tracking"
#mycdbtrack="mysql --host=10.183.28.25 --port=3370 --user=dbauser --password=surfb0ard --database=db_tracking"


for backupinfo in $LOG_FILES
do
	CURRENT_BACKUP_DIR=$(dirname $backupinfo)
	cd $CURRENT_BACKUP_DIR/logs

	log_file=$(ls -Str *$MINUS_DATE* | tail -1)
	if [  -z $log_file ]; 
	then
	        echo
		echo
		echo '****************************************************************************************'
		echo "`date +'%F %T %Z'` -- $CURRENT_BACKUP_DIR : - File not found!"
	        echo "`date +'%F %T %Z'` -- Backup activity is not started yet"
		echo '****************************************************************************************'	
		echo
		echo
	else
		echo
		echo '----------------------------------------------------------------------------------------'
		echo "`date +'%F %T %Z'` -- $CURRENT_BACKUP_DIR : - File found! - $log_file"
        backup_host_name=$(grep '^Hostname' $log_file | awk -F' ' '{print $3}')
		backup_instance_id=NULL;
		backup_instance_name=$(grep '^Instance' $log_file | awk -F' ' '{print $3}')
		backup_db_name=$(grep '^Database' $log_file | awk -F' ' '{print $3}')
		backup_starttime=$(grep '^* Time started' $log_file | awk -F' ' '{print $4" "$5}')
		backup_endtime=$(grep '^* Time completed' $log_file | awk -F' ' '{print $4" "$5}')

		source_size=$(grep 'Size of files' $log_file | awk -F':' '{print $2}'|tr -d ' ')
		s_type_check=$(echo "$source_size"|tr -d '.''0-9'' ')	

        if [[ $s_type_check  = "K" ]]
        then
            source_size=$(grep 'Size of files' $log_file | awk -F':' '{print $2}'|tr -d A-Za-z' ')
            source_size=$(echo "scale=10; $source_size/1024/1024" |bc)	
		elif [[ $s_type_check  = "M" ]]
        then
            source_size=$(grep 'Size of files' $log_file | awk -F':' '{print $2}'|tr -d A-Za-z' ')
            source_size=$(echo "scale=10; $source_size/1024" |bc)
		elif [[ $s_type_check  = " " ||  $s_type_check  = NULL ]]
        then
            source_size=$(grep 'Size of files' $log_file | awk -F':' '{print $2}'|tr -d A-Za-z' ')
            source_size=$(echo "scale=10; $source_size/1024/1024/1024" |bc)
	    else
            source_size=$(grep 'Size of files' $log_file | awk -F':' '{print $2}'|tr -d A-Za-z' ')
         fi

		backup_size=$(grep 'Size of compress' $log_file | awk -F':' '{print $2}'|tr -d ' ')
		b_type_check=$(echo "$backup_size"|tr -d '.''0-9'' ')
        if [[ $b_type_check  = "K" ]]
        then
            backup_size=$(grep 'Size of compress' $log_file | awk -F':' '{print $2}'|tr -d A-Za-z' ')
            backup_size=$(echo "scale=10; $backup_size/1024/1024" |bc)
	elif [[ $b_type_check  = "M" ]]
        then
            backup_size=$(grep 'Size of compress' $log_file | awk -F':' '{print $2}'|tr -d A-Za-z' ')
            backup_size=$(echo "scale=10; $backup_size/1024" |bc)
        elif [[ $b_type_check  = " " ||  $b_type_check  = NULL ]]
        then
            backup_size=$(grep 'Size of compress' $log_file | awk -F':' '{print $2}'|tr -d A-Za-z' ')
            backup_size=$(echo "scale=10; $backup_size/1024/1024/1024" |bc)
        else
            backup_size=$(grep 'Size of compress' $log_file | awk -F':' '{print $2}'|tr -d A-Za-z' ')
         fi


	
if [[ -z "$backup_host_name" && -z "$backup_instance_name" && -z "$backup_db_name" && -z "$backup_starttime" && -z "$source_size" && -z "$backup_size" && -z $backup_endtime ]]; 
	then
		echo
		echo '****************************************************************************************'
		echo 'Not all required parameters were parsed.' 
		echo '...looks backjob is still in progress... '
		echo '****************************************************************************************'
		echo
		exit 1
	fi

### check endtime status 
        if [[ -z "$backup_endtime" ]];
        then
                backup_endtime=NULL;
		fi
		  if [[ -z "$backup_size" || "$backup_size" == "" ]];
		then
				backup_size=NULL;
				echo $backup_size;
		fi

### check back status y/n
mysql_ind="mysql_backup"
	if [[ -z "$backup_endtime" || "$backup_endtime" == "NULL" || -e $CURRENT_BACKUP_DIR/$mysql_ind ||  -z "$backup_size" || "$backup_size" == "NULL" ]];
	then
		sucess_yn="n"
		 echo $backup_host_name "--" $backup_instance_name "--" $backup_db_name "--" $backup_starttime "--" $backup_endtime "--" $source_size "--" $backup_size "--" $sucess_yn
	$mycdbtrack -e "insert into backup_status (host_name,instance_name,db_name,start_ts,stop_ts,sucess_yn,source_size_gb,backup_size_gb) values ('$backup_host_name','$backup_instance_name','$backup_db_name','$backup_starttime',$backup_endtime,'$sucess_yn','$source_size',$backup_size)"
	else 
		sucess_yn="y"
		echo $backup_host_name "--" $backup_instance_name "--" $backup_db_name "--" $backup_starttime "--" $backup_endtime "--" $source_size "--" $backup_size "--" $sucess_yn
	$mycdbtrack -e "insert into backup_status (host_name,instance_name,db_name,start_ts,stop_ts,sucess_yn,source_size_gb,backup_size_gb) values ('$backup_host_name','$backup_instance_name','$backup_db_name','$backup_starttime','$backup_endtime','$sucess_yn','$source_size','$backup_size')"
		echo
	fi
   fi
done

graceful_exit

