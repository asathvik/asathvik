#!/bin/bash
################################################################################
# Author:
#	Anil Kumar Alpati
#
# Purpose:
#	Shell script for backing up MySQL master and slave databases at file 
#	system level.
#
# Usage:
#	mysql_backup.sh mysql_backup.ini
#
# Note:
#	Use database and table level backups for MyISAM databases only.
#
################################################################################
#
################################################################################
# Constants and Global Variables
################################################################################

PROGNAME=$(basename $0)

# Configuration file to use.
CONFIG=$1

# Boolean constants.
TRUE=true
FALSE=false

start_time=`date +'%F %T %Z'`
backup_date=`date -d "$start_time" +'%Y%m%d_%H%M%S'`

working_dir=`pwd`

tmp1=/tmp/mysql_backup.$$.tmp1
tmp2=/tmp/mysql_backup.$$.tmp2
tmp3=/tmp/mysql_backup.$$.tmp3
temp_file="$tmp1 $tmp2 $tmp3"

################################################################################
# Functions
################################################################################

function clean_up {
	# Function to remove temporary files and other housekeeping
	# No arguments
	rm -f ${temp_file}
	if [[ ! -z "$backup_ind" ]]; then
		if [[ -e $working_dir/$backup_ind ]]; then
			# Remove offline backup in progress indicator file.
			rm $working_dir/$backup_ind
		fi
	fi
}

function graceful_exit {
	# Function called for a graceful exit
	# No arguments
	clean_up
	exit
}

function error_exit {
	# Function for exit due to fatal program error
	# Accepts 1 argument
	#	string containing descriptive error message
	echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
	date +'Time of error: %F %T %Z'
	clean_up
	exit 1
}

function term_exit {
	# Function to perform exit if termination signal is trapped
	# No arguments
	echo "${PROGNAME}: Terminated"
	clean_up
	exit
}

function int_exit {
	# Function to perform exit if interrupt signal is trapped
	# No arguments
	echo "${PROGNAME}: Aborted by user"
	clean_up
	exit
}

################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit
trap term_exit TERM HUP
trap int_exit INT

# Check if configuration file is readable.
if [[ ! -r $CONFIG ]]; then
	error_exit "Error on line $LINENO. Cannot read from configuration file."
fi


# Read configuration file.

mysql_db=$(cat $CONFIG | grep '^mysql_db=' | awk -F'=' '{print $2}')
slave=$(cat $CONFIG | grep '^slave=' | awk -F'=' '{print $2}')
mysql_user=$(cat $CONFIG | grep '^mysql_user=' | awk -F'=' '{print $2}')
mysql_pass=$(cat $CONFIG | grep '^mysql_pass=' | awk -F'=' '{print $2}')
backup_dir=$(cat $CONFIG | grep '^backup_dir=' | awk -F'=' '{print $2}')
num_daily_bkups=$(cat $CONFIG | grep '^num_daily_bkups=' | awk -F'=' '{print $2}')
num_weekly_bkups=$(cat $CONFIG | grep '^num_weekly_bkups=' | awk -F'=' '{print $2}')
num_monthly_bkups=$(cat $CONFIG | grep '^num_monthly_bkups=' | awk -F'=' '{print $2}')
weekly_monthly_bkup_day=$(cat $CONFIG | grep '^weekly_monthly_bkup_day=' | awk -F'=' '{print $2}')
backup_ind=$(cat $CONFIG | grep '^backup_ind=' | awk -F'=' '{print $2}')
backup_mode=$(cat $CONFIG | grep '^backup_mode=' | awk -F'=' '{print $2}')
backup_level=$(cat $CONFIG | grep '^backup_level=' | awk -F'=' '{print $2}')
backup_tables=$(cat $CONFIG | grep '^backup_tables=' | awk -F'=' '{print $2}')

if [[ -z "$mysql_db" || -z "$slave" || -z "$mysql_user" || -z "$mysql_pass" || -z "$backup_dir" || -z "$num_daily_bkups" || -z "$num_weekly_bkups" || -z "$num_monthly_bkups" || -z "$weekly_monthly_bkup_day" || -z "$backup_ind" || -z "$backup_mode" || -z "$backup_level" ]]; then
	error_exit "Error on line $LINENO. Not all required configuration options were provided."
fi

if [[ "$backup_level" = "table" && -z "$backup_tables" ]]; then
	error_exit "Error on line $LINENO. backup_tables option was not provided in configuration file."
fi


if [[ "$backup_level" = "table" && "$backup_mode" = "offline" ]]; then
        error_exit "Error on line $LINENO. backing up the tables in offline is not recommended and enabled"
	exit 1
fi


# Instance directory.
inst_dir=/u01/mysql_data

# Socket file.
mysql_socket=$inst_dir/mysql.sock

# Port
mysql_port=3306

# MySQL client full path.
# MySQL Bin
bin_dir=/usr/bin

if [[ -e $bin_dir/mysql ]]; then
	mysql="$bin_dir/mysql"
	
else
	mysql=mysql
fi
# Connection string.
mysql_connection="$mysql --user=$mysql_user --password=$mysql_pass --port=$mysql_port --socket=$mysql_socket"
mysqldump_connection="$bin_dir/mysqldump --user=$mysql_user --password=$mysql_pass --port=$mysql_port --socket=$mysql_socket --single-transaction --master-data=1"

# MySQL version.
mysql_version=$($mysql_connection -e "show variables like 'version'" | sed '1d' | gawk '{print $2}')


echo "**************************************************"
echo "* Backup Database"
echo "* Time started: $start_time"
echo "**************************************************"
echo
echo "Database         = $mysql_db"
echo "Hostname         = `hostname -A`"
echo "MySQL user       = $mysql_user"
echo "Backup directory = $backup_dir"
echo "Is slave         = $slave"
echo "MySQL version    = $mysql_version"
echo "Back-up mode     = $backup_mode"
echo "Back-up level    = $backup_level"
echo
sleep 10

# Create backup in-progress indicator file.
#touch $working_dir/$backup_ind || error_exit "Error on line $LINENO. Cannot create file."
touch /tmp/$backup_ind || error_exit "Error on line $LINENO. Cannot create file."

# Determine uncompressed file size
if [[ "$backup_level" = "instance" ]]; then
	echo "Size of files to be backed up:" `du -shL $inst_dir | awk -F ' ' '{print $1}'`
elif [[ "$backup_level" = "database" ]]; then
	echo "Size of files to be backed up:" \
	`du -cshL $inst_dir/$mysql_db/ $inst_dir/mysql | tail -1 | gawk '{print $1}'`
elif [[ "$backup_level" = "table" ]]; then
	cd $inst_dir/$mysql_db/ || error_exit "Error on line $LINENO. Cannot change directory."
	du -lhs "$backup_tables.*"
	echo "Size of files to be backed up:" \
	`du -cshL $backup_tables.* $inst_dir/mysql | tail -1 | gawk '{print $1}'`
fi

# Go into main backup directory. Create directory if it does not exist.
if [[ ! -d $backup_dir ]]; then
	mkdir $backup_dir || error_exit "Error on line $LINENO. Cannot create directory."
	chmod 770 $backup_dir
fi
cd $backup_dir || error_exit "Error on line $LINENO. Cannot change directory."

echo
echo "Backup directory disk space:"
df -h $backup_dir || error_exit "Error on line $LINENO. Cannot get directory disk space available."

# Show slave status if this is a slave.
if [[ $slave = $TRUE ]]; then
	echo
	echo "Getting slave status..."
	temp_file="$temp_file /tmp/show_slave_status.$$.tmp"
	$mysql_connection -e "SHOW SLAVE STATUS\G;" > /tmp/show_slave_status.$$.tmp || error_exit "Error on line $LINENO."
	cat /tmp/show_slave_status.$$.tmp || error_exit "Error on line $LINENO."
fi

# Check if this is a slave.
if [[ $slave = $TRUE ]]; then
	# Stop slave and loop while slave open temp tables is not 0.
	# Should not stop MySQL slave instance until open temp tables is 0.
	slave_open_tmp_tbls=1
	while [ "$slave_open_tmp_tbls" != "0" ]
	do
		echo
		echo "Stopping slave service..."
		$mysql_connection -e "STOP SLAVE;" || error_exit "Error on line $LINENO. 'STOP SLAVE' failed."
	
		echo
		echo "Getting status..."
		$mysql_connection -e "SHOW STATUS\G;" > $tmp1 || error_exit "Error on line $LINENO."
	
		slave_running=`grep --after-context=1 'Variable_name: Slave_running' $tmp1 \
		 | grep 'Value:' | gawk -F': ' '{print $2}'` || error_exit "Error on line $LINENO."
	
		echo "Slave_running: $slave_running"
	
		if [ "$slave_running" != "OFF" ]; then
			error_exit "Error on line $LINENO. 'STOP SLAVE' failed."
		fi
	
		slave_open_tmp_tbls=`grep --after-context=1 'Variable_name: Slave_open_temp_tables' $tmp1 \
		 | grep 'Value:' | gawk -F': ' '{print $2}'` || error_exit "Error on line $LINENO."
	
		echo "Slave_open_temp_tables: $slave_open_tmp_tbls"
	
		if [ "$slave_open_tmp_tbls" != "0" ]; then
			echo
			echo "There are open temp tables, starting slave service..."
			$mysql_connection -e "START SLAVE;" || error_exit "Error on line $LINENO. 'START SLAVE' failed."
	
			echo
			echo "Sleeping for 1 second..."
			sleep 1
		fi
	done
fi

# Check if binary logging is enabled.
echo
binary_logging=`$:1
tion -e "SHOW VARIABLES LIKE 'log_bin';" | grep 'log_bin' | awk '{print $2}'`
if [[ -z "$binary_logging" ]]; then
	error_exit "Error on line $LINENO. Failed to get MySQL system variable."
fi
echo "Binary logging is: $binary_logging"
if [[ "$binary_logging" != "OFF" ]]; then
	echo "Getting Binary Log File position..."
	$mysql_connection -e "SHOW MASTER STATUS\G;" | egrep 'File:|Position:' \
	 || error_exit "Error on line $LINENO. Failed to get Binary Log File position."
	$mysql_connection -e "SHOW MASTER STATUS\G;" > /tmp/$mysql_db.binarylogs.txt \
	|| error_exit "Error on line $LINENO. Failed to get Binary Log File position."

fi

# Stop instance if offline backup mode / Flush tables if online backup mode
echo
if [[ "$backup_mode" = "offline" ]]; then 
	/etc/init.d/mysql stop || error_exit "Error on line $LINENO. Failed to stop MySQL instance."
	##### ToDo: fix init.d/mysql to return error codes properly ####
	#echo "Return Code $?"
elif [[ "$backup_mode" = "online" ]]; then
	echo "Flushing tables..."
	if [[ "$backup_level" = "instance" ]]; then
		$mysql_connection -e "flush tables;" || error_exit "Error on line $LINENO. Flush tables failed." 
	elif [[ "$backup_level" = "database" ]]; then
		$mysql_connection -e "use $mysql_db; show tables;" > $tmp2 || error_exit "Error on line $LINENO. Show tables failed."
		sed '1d' $tmp2 > $tmp3
		for table in `cat $tmp3`
		do
			$mysql_connection -e "flush table $mysql_db.$table" || error_exit "Error on line $LINENO. Flushing tables failed."
		done
	elif [[ "$backup_level" = "table" ]]; then
			$mysql_connection -e "flush table $mysql_db.$backup_tables" || error_exit "Error on line $LINENO. Flushing tables failed."
	fi
fi

# Decide what kind of backup to perform: daily, weekly, or monthly.
if [ $weekly_monthly_bkup_day == "$(date +'%w')" ]; then
	temp_file="$temp_file /tmp/monthly_backup_list.$$.tmp"
	if [ $(ls -d *.monthly 2> /dev/null | tail -1) ]; then
		ls -d *.monthly > /tmp/monthly_backup_list.$$.tmp || error_exit "Error on line $LINENO."
	else
		touch /tmp/monthly_backup_list.$$.tmp || error_exit "Error on line $LINENO."
	fi

	last_monthly_bkup=$(tail -1 /tmp/monthly_backup_list.$$.tmp | cut -c1-6)
	current_monthly_bkup=$(echo $backup_date | cut -c1-6)
	
	# If there is already a monthly backup done for this month then we need weekly backup, else monthly backup.
	if [ "$last_monthly_bkup" == "$current_monthly_bkup" ]; then
		backup_type=weekly
		num_bkups=$num_weekly_bkups
	else
		backup_type=monthly
		num_bkups=$num_monthly_bkups
	fi
else
	backup_type=daily
	num_bkups=$num_daily_bkups
fi

# Check if there are old backups that need to be deleted.
temp_file="$temp_file /tmp/backup_list.$$.tmp"
if [ $(ls -d *.${backup_type} 2> /dev/null | tail -1) ]; then
	ls -d *.${backup_type} > /tmp/backup_list.$$.tmp || error_exit "Error on line $LINENO."
else
	touch /tmp/backup_list.$$.tmp || error_exit "Error on line $LINENO."
fi

while [ "$(cat /tmp/backup_list.$$.tmp | wc -l)" -gt "$num_bkups" ]
do
	old_backup=$(head -1 /tmp/backup_list.$$.tmp)
	
	echo
	echo "Deleting old backup:" $old_backup
	old_backup=$(echo $old_backup | gawk -F'.' '{print $1}')
	rm -rf $backup_dir/${old_backup}.${backup_type} || error_exit "Error on line $LINENO."
	
	ls -d *.${backup_type} > /tmp/backup_list.$$.tmp || error_exit "Error on line $LINENO."
done

echo
echo "Creating backup: $backup_dir"${backup_date}.${backup_type}
if [ -e $backup_dir/${backup_date}.${backup_type} ]; then
	error_exit "Error on line $LINENO. Backup directory already exists."
fi
mkdir $backup_dir/${backup_date}.${backup_type} || error_exit "Error on line $LINENO. Cannot create directory."
chmod -R 770 $backup_dir/${backup_date}.${backup_type} || error_exit "Error on line $LINENO."
chown -R :mysql $backup_dir/${backup_date}.${backup_type} || error_exit "Error on line $LINENO."

# Backup database.
echo "Backing up the database..."
cd $inst_dir || error_exit "Error on line $LINENO. Cannot change directory."

cp -rfvp /etc/my.cnf $backup_dir/${backup_date}.${backup_type}/etc.my.cnf || error_exit "Error on line $LINENO."
mv -fv /tmp/$mysql_db.binarylogs.txt $backup_dir/${backup_date}.${backup_type}/$mysql_db.binarylogs.txt
if [[ "$backup_level" = "instance" ]]; then
	tar --totals -czhf $backup_dir/${backup_date}.${backup_type}/full_db.tar.gz $inst_dir || error_exit "Error on line $LINENO."
elif [[ "$backup_level" = "database" ]]; then
	tar --totals -czhf $backup_dir/${backup_date}.${backup_type}/${mysql_db}.tar.gz $mysql_db mysql || error_exit "Error on line $LINENO."
elif [[ "$backup_level" = "table" ]]; then
	echo "$mysqldump_connection $mysql_db $backup_tables"
$mysqldump_connection $mysql_db $backup_tables > $mysql_db.$backup_tables.sql
	tar --totals -czhf $backup_dir/${backup_date}.${backup_type}/${mysql_db}.${backup_tables}.tar.gz $inst_dir/$mysql_db.$backup_tables.sql \
	 || error_exit "Error on line $LINENO."
fi
chmod 660 $backup_dir/${backup_date}.${backup_type}/*.tar.gz || error_exit "Error on line $LINENO."

echo "done"
echo
echo "Size of compressed backed up files:" `du -sh $backup_dir/${backup_date}.${backup_type} | awk -F ' ' '{print $1}'`

# Start MySQL instance if offline back-up mode.
if [[ "$backup_mode" = "offline" ]]; then
   echo
   /etc/init.d/mysql start || error_exit "Error on line $LINENO. Failed to start MySQL instance."
   echo
fi
echo "Getting current timestamp from MySQL..."
$mysql_connection -e "SELECT NOW() AS TIMESTAMP;" || error_exit "Error on line $LINENO."

echo
echo "**************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "**************************************************"

graceful_exit

