#!/bin/bash
################################################################################
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
# Revisions:
#	05/30/2006 - Dimitriy Alekseyev
#	Script created.
#	10/02/2006 - Dimitriy Alekseyev
#	Added code for making a backup at file system level.
#	10/03/2006 - Dimitriy Alekseyev
#	Added code for making daily, weekly, monthly backups.
#	10/12/2006 - Dimitriy Alekseyev
#	Fixed a bug where the script would create monthly backups instead of
#	weekly backups.
#	11/14/2006 - Dimitriy Alekseyev
#	Added code to create a status file while backup script is running.
#	11/21/2006 - Dimitriy Alekseyev
#	Fixed problem with removing backup in progress indicator file.
#	11/28/2006 - Dimitriy Alekseyev
#	Added code for compressing backups.
#	07/16/2007 - Dimitriy Alekseyev
#	Made minor changes to the look of the report.
#	08/15/2007 - Dimitriy Alekseyev
#	Added code to support backup of both MySQL master and slave databases.
#	Made other minor improvements.
#	08/27/2007 - Dimitriy Alekseyev
#	Added logic to get binary log position only if binary logging is 
#	enabled.
#	08/28/2007 - Dimitriy Alekseyev
#	Added more error checking and made some other minor improvements.
#	03/17/2008 - John Jensen / Dimitriy Alekseyev
#	Added support for online back-up mode for MyISAM tables.
#	Added support for backing-up by instance, database, or specific tables.
#	Added support for following symbolic links when tar'ing
#	and determining disk usage.
#	Added display of MySQL version.
#	07/22/2008 - Dimitriy Alekseyev
#	Added support for instance numbers above 9.
#	10/01/2008 - Dimitriy Alekseyev
#	Modified script to read otions from configuration file.
#	12/10/2008 - Dimitriy Alekseyev
#	Added command to change permissions of the backup file.
#	12/15/2008 - Dimitriy Alekseyev
#	Fixed display of MySQL version so that the version is of the server, 
#	not of the client.
#	12/01/2009 - Dimitriy Alekseyev
#	Modified mysqld path for version information. On some servers it 
#	doesn't work without full path.
#	12/28/2009 - Dimitriy Alekseyev
#	Modified script to work with new MySQL instance directory path. Backup 
#	directory is now created with date and time to allow more than one 
#	backup to run per day.
#	11/29/2010 - Dimitriy Alekseyev
#	Fixed script to correctly choose between creating a weekly or monthly 
#	backup as logic was broken because the date format for backup names was 
#	changed (e.g. 2010-11-29 vs. 20101129).
#	03/18/2011 - Dimitriy Alekseyev
#	Added backup of individual my.cnf files, besides /etc/my.cnf.
#	02/09/2012 - Dimitriy Alekseyev
#	Removed host dnsdomainname from being displayed.
#	Fixed how MySQL version is derived. Old method does not work for MySQL 
#	installations with multiple versions.
#	Added another show slave status section that is displayed before the 
#	backup is taken.
#	04/10/2012 - Dimitriy Alekseyev
#	Removed slave status after backup and kept the one before the backup. 
#	Added a check for existence of main backup directory.
#	Displaying additional information with tar commands.
#
# Todo:
#	Support CSV Back-ups.
#	Do not fail if instance is down at beginning of script for offline 
#	backups.
#	Bring up instance if script fails in offline mode.
#	/etc/init.d/mysql script doesn't return proper error code on failure.
################################################################################


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

# Excel formula for generating below code:
# =A1 & "=$(cat $CONFIG | grep '^" & A1 & "=' | awk -F'=' '{print $2}')"

mysql_db=$(cat $CONFIG | grep '^mysql_db=' | awk -F'=' '{print $2}')
slave=$(cat $CONFIG | grep '^slave=' | awk -F'=' '{print $2}')
mysql_instance=$(cat $CONFIG | grep '^mysql_instance=' | awk -F'=' '{print $2}')
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

if [[ -z "$mysql_db" || -z "$slave" || -z "$mysql_instance" || -z "$mysql_user" || -z "$mysql_pass" || -z "$backup_dir" || -z "$num_daily_bkups" || -z "$num_weekly_bkups" || -z "$num_monthly_bkups" || -z "$weekly_monthly_bkup_day" || -z "$backup_ind" || -z "$backup_mode" || -z "$backup_level" ]]; then
	error_exit "Error on line $LINENO. Not all required configuration options were provided."
fi

if [[ "$backup_level" = "table" && -z "$backup_tables" ]]; then
	error_exit "Error on line $LINENO. backup_tables option was not provided in configuration file."
fi


# Instance number with the leading zero if it is less than 10.
inst_wlz="0$mysql_instance"
inst_wlz=${inst_wlz:${#inst_wlz}-2:2}

# Instance directory.
inst_dir=/mysql/$inst_wlz

# Socket file.
mysql_socket=$inst_dir/mysql.sock

# MySQL client full path.
if [[ -e $inst_dir/bin/mysql ]]; then
	mysql=$inst_dir/bin/mysql
else
	mysql=mysql
fi

# Connection string.
mysql_connection="$mysql --user=$mysql_user --password=$mysql_pass --socket=$mysql_socket"

# MySQL version.
mysql_version=$($mysql_connection -e "show variables like 'version'" | sed '1d' | gawk '{print $2}')


echo "**************************************************"
echo "* Backup Database"
echo "* Time started: $start_time"
echo "**************************************************"
echo
echo "Database         = $mysql_db"
echo "Hostname         = `hostname`"
echo "Instance         = $mysql_instance"
echo "MySQL user       = $mysql_user"
echo "Backup directory = $backup_dir"
echo "Is slave         = $slave"
echo "MySQL version    = $mysql_version"
echo "Back-up mode     = $backup_mode"
echo "Back-up level    = $backup_level"
echo

# Create backup in-progress indicator file.
touch $working_dir/$backup_ind || error_exit "Error on line $LINENO. Cannot create file."

# Determine uncompressed file size
if [[ "$backup_level" = "instance" ]]; then
	echo "Size of files to be backed up:" `du -shL $inst_dir | awk -F ' ' '{print $1}'`
elif [[ "$backup_level" = "database" ]]; then
	echo "Size of files to be backed up:" \
	`du -cshL $inst_dir/data/$mysql_db/ $inst_dir/data/mysql | tail -1 | gawk '{print $1}'`
elif [[ "$backup_level" = "table" ]]; then
	cd $inst_dir/data/$mysql_db/ || error_exit "Error on line $LINENO. Cannot change directory."
	for table in $backup_tables
	do
		tablefiles1="$tablefiles1 $table.*"
	done
	echo "Size of files to be backed up:" \
	`du -cshL $tablefiles1 $inst_dir/data/mysql | tail -1 | gawk '{print $1}'`
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
binary_logging=`$mysql_connection -e "SHOW VARIABLES LIKE 'log_bin';" | grep 'log_bin' | awk '{print $2}'`
if [[ -z "$binary_logging" ]]; then
	error_exit "Error on line $LINENO. Failed to get MySQL system variable."
fi
echo "Binary logging is: $binary_logging"
if [[ "$binary_logging" != "OFF" ]]; then
	echo "Getting Binary Log File position..."
	$mysql_connection -e "SHOW MASTER STATUS\G;" | egrep 'File:|Position:' \
	 || error_exit "Error on line $LINENO. Failed to get Binary Log File position."
fi

# Stop instance if offline backup mode / Flush tables if online backup mode
echo
if [[ "$backup_mode" = "offline" ]]; then 
	/etc/init.d/mysql stop $mysql_instance || error_exit "Error on line $LINENO. Failed to stop MySQL instance."
	##### ToDo: fix init.d/mysql to return error codes properly ####
	#echo "Return Code $?"
elif [[ "$backup_mode" = "online" ]]; then
	echo "Flushing tables..."
	if [[ "$backup_level" = "instance" ]]; then
		mysql_connection -e "flush tables;" || error_exit "Error on line $LINENO. Flush tables failed." 
	elif [[ "$backup_level" = "database" ]]; then
		$mysql_connection -e "use $mysql_db; show tables;" > $tmp2 || error_exit "Error on line $LINENO. Show tables failed."
		sed '1d' $tmp2 > $tmp3
		for table in `cat $tmp3`
		do
			$mysql_connection -e "flush table $mysql_db.$table" || error_exit "Error on line $LINENO. Flushing tables failed."
		done
	elif [[ "$backup_level" = "table" ]]; then
		for table in $backup_tables
		do
			$mysql_connection -e "flush table $mysql_db.$table" || error_exit "Error on line $LINENO. Flushing tables failed."
		done
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
echo "Creating backup:" ${backup_date}.${backup_type}
if [ -e $backup_dir/${backup_date}.${backup_type} ]; then
	error_exit "Error on line $LINENO. Backup directory already exists."
fi
mkdir $backup_dir/${backup_date}.${backup_type} || error_exit "Error on line $LINENO. Cannot create directory."
chmod -R 770 $backup_dir/${backup_date}.${backup_type} || error_exit "Error on line $LINENO."
chown -R :dba $backup_dir/${backup_date}.${backup_type} || error_exit "Error on line $LINENO."

# Backup database.
echo "Backing up the database..."
cd $inst_dir || error_exit "Error on line $LINENO. Cannot change directory."
cp -p /etc/my.cnf $backup_dir/${backup_date}.${backup_type}/etc.my.cnf || error_exit "Error on line $LINENO."
cp -p my.cnf $backup_dir/${backup_date}.${backup_type}/ || error_exit "Error on line $LINENO."
if [[ "$backup_level" = "instance" ]]; then
	## Note: need to make sure backup_mode is "offline", otherwise it might lock on mysql.sock file when copying
	##cp -rp $inst_dir/* $backup_dir/${backup_date}.${backup_type}/ || error_exit "Error on line $LINENO."
	echo -n "data: "
	tar --totals -czhf $backup_dir/${backup_date}.${backup_type}/data.tar.gz data || error_exit "Error on line $LINENO."
	echo -n "binlogs: "
	tar --totals -czhf $backup_dir/${backup_date}.${backup_type}/binlogs.tar.gz binlogs || error_exit "Error on line $LINENO."
	echo -n "logs: "
	tar --totals -czhf $backup_dir/${backup_date}.${backup_type}/logs.tar.gz logs || error_exit "Error on line $LINENO."
	echo -n "tmp: "
	tar --totals -czhf $backup_dir/${backup_date}.${backup_type}/tmp.tar.gz tmp || error_exit "Error on line $LINENO."
elif [[ "$backup_level" = "database" ]]; then
	tar --totals -czhf $backup_dir/${backup_date}.${backup_type}/${mysql_db}.tar.gz data/$mysql_db data/mysql || error_exit "Error on line $LINENO."
elif [[ "$backup_level" = "table" ]]; then
	for tables in $backup_tables
	do
		tablefiles="$tablefiles data/$mysql_db/$tables.*"
	done
	tar --totals -czhf $backup_dir/${backup_date}.${backup_type}/${mysql_db}.tar.gz $tablefiles data/mysql \
	 || error_exit "Error on line $LINENO."
fi
chmod 660 $backup_dir/${backup_date}.${backup_type}/*.tar.gz || error_exit "Error on line $LINENO."

echo "done"
echo
echo "Size of compressed backed up files:" `du -sh $backup_dir/${backup_date}.${backup_type} | awk -F ' ' '{print $1}'`

# Start MySQL instance if offline back-up mode.
if [[ "$backup_mode" = "offline" ]]; then
   echo
   /etc/init.d/mysql start $mysql_instance || error_exit "Error on line $LINENO. Failed to start MySQL instance."
   echo
fi
echo "Getting current timestamp from MySQL..."
$mysql_connection -e "SELECT NOW() AS TIMESTAMP;" || error_exit "Error on line $LINENO."

echo
echo "**************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "**************************************************"

graceful_exit
