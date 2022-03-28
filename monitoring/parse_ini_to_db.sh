#!/bin/bash
################################################################################
# Developed by:
# Anil Kumar Alpati
#
# Created:
# 2013-05-30 - Anil Kumar Alpati
#
################################################################################
# Variables Declarations
#################################################################################
user_name=`id -u -n`
if [ $user_name != "mysql" ]; then
echo "You must be 'mysql' user not $user_name user";
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
	echo
	echo "`date +'%F %T %Z'` : $backupinfo"
	echo
 
	ini_host_name=$(grep '^email_subject' $backupinfo | awk -F'=' '{print $2}' | cut -d' ' -f1 | sed "s/'//g") 
	ini_instance_name=$(grep '^mysql_instance' $backupinfo | awk -F'=' '{print $2}')
	ini_db_name=$(grep '^mysql_db' $backupinfo | awk -F'=' '{print $2}')
	ini_slave_yn=$(grep '^slave' $backupinfo | awk -F'=' '{print $2}')
	ini_user=$(grep '^mysql_user' $backupinfo | awk -F'=' '{print $2}')
	ini_password=$(grep '^mysql_pass' $backupinfo | awk -F'=' '{print $2}')
	ini_backup_dir=$(grep '^backup_dir' $backupinfo | awk -F'=' '{print $2}')
	ini_num_daily_bkups=$(grep '^num_daily_bkups' $backupinfo | awk -F'=' '{print $2}')
	ini_num_weekly_bkups=$(grep '^num_weekly_bkups' $backupinfo | awk -F'=' '{print $2}')
	ini_num_monthly_bkups=$(grep '^num_monthly_bkups' $backupinfo | awk -F'=' '{print $2}')
	ini_weekly_monthly_bkup_day=$(grep '^weekly_monthly_bkup_day' $backupinfo | awk -F'=' '{print $2}')
	ini_backup_ind=$(grep '^backup_ind' $backupinfo | awk -F'=' '{print $2}')
	ini_backup_mode=$(grep '^backup_mode' $backupinfo | awk -F'=' '{print $2}')
	ini_backup_level=$(grep '^backup_level' $backupinfo | awk -F'=' '{print $2}')
	ini_backup_tables=$(grep '^backup_tables' $backupinfo | awk -F'=' '{print $2}')
	ini_email_subject=$(grep '^email_subject' $backupinfo | awk -F'=' '{print $2}'| sed "s/'//g")
	ini_email_address=$(grep '^email_address' $backupinfo | awk -F'=' '{print $2}')
	ini_instance_id=NULL;

### check slave status y/n - true -> y and false -> n
        if [[ "$ini_slave_yn" == "true" ]];
        then
        	ini_slave_yn=Y;
	else
		ini_slave_yn=N;
	fi

### check backup mode status y/n Online -> y and Offline -> n -[Offline/Online Backup Mode. Values are: offline or online.]
        if [[ "$ini_backup_mode" == "Online" ]];
        then
                ini_backup_mode=Y;
        else
                ini_backup_mode=N;
        fi

	$mycdbtrack -e"INSERT INTO DB_TRACKING.MYSQL_BACKUP_JOBS (host_name,mysql_instance,mysql_dbname,slave_yn,mysql_user,mysql_password,backup_dir,num_daily_bkups,num_weekly_bkups,num_monthly_bkups,weekly_monthly_bkup_day,backup_ind,backup_online_yn,backup_level,backup_tables,email_subject,email_address) VALUES ('$ini_host_name','$ini_instance_name','$ini_db_name','$ini_slave_yn','$ini_user','$ini_password','$ini_backup_dir','$ini_num_daily_bkups','$ini_num_weekly_bkups','$ini_num_monthly_bkups','$ini_weekly_monthly_bkup_day','$ini_backup_ind','$ini_backup_mode','$ini_backup_level','$ini_backup_tables','$ini_email_subject','$ini_email_address')";


	echo -e "`date +'%F %T %Z'` " $ini_host_name "||" $ini_instance_name "||" $ini_db_name "||" $ini_slave_yn "||" $ini_user "||"  $ini_password "||" $ini_backup_dir "||" $ini_num_daily_bkups "||"  $ini_num_weekly_bkups "||" $ini_num_monthly_bkups "||"  $ini_weekly_monthly_bkup_day "||"   $ini_backup_ind "||"  $ini_backup_mode "||"  $ini_backup_level "||" $ini_backup_tables "||"  $ini_email_subject "||"   $ini_email_address
done

graceful_exit

