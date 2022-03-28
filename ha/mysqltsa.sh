#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Support failover from MySQL master to slave replicate in case master
#	goes down.
#
# Usage:
#	mysqltsa.sh
#
# Revisions:
#	08/06/2007 - Dimitriy Alekseyev
#	Script created with basic functionality. Need to add error handling.
#	Also need to add variables, instead of using constant values.
#	08/29/2007 - Dimitriy Alekseyev
#	Added code to check if relay logs have been read. Added a lot error
#	checking to the script.
################################################################################


################################################################################
# Global Variables and Constants
################################################################################

# Database name.
database=clsdpmst

# Master information. Do not put domain name for host.
master_host=data010
master_port=3315
master_user=dbauser
master_pass=surfb0ard

# Slave information. Do not put domain name for host.
slave_host=data011
slave_port=3315
slave_user=dbauser
slave_pass=surfb0ard

# Email subject.
email_subject="MySQL TSA"

# Email address.
email_address="dalekseyev@corelogic.com"

# Directory name where program is located.
directory=`dirname $0`

# Log file.
log=${directory}/mysqltsa.log

# Run file. When this file is created by this script, it means the slave has been promoted to master.
run_file=${directory}/mysqltsa.run

# Program name.
progname=`basename $0`

case $master_port in
	3310 ) master_instance=1 ;;
	3315 ) master_instance=2 ;;
	3320 ) master_instance=3 ;;
	3325 ) master_instance=4 ;;
	3330 ) master_instance=5 ;;
	3335 ) master_instance=6 ;;
	3340 ) master_instance=7 ;;
	3345 ) master_instance=8 ;;
	3350 ) master_instance=9 ;;
	*    ) master_instance=0 ;;
esac

case $slave_port in
	3310 ) slave_instance=1 ;;
	3315 ) slave_instance=2 ;;
	3320 ) slave_instance=3 ;;
	3325 ) slave_instance=4 ;;
	3330 ) slave_instance=5 ;;
	3335 ) slave_instance=6 ;;
	3340 ) slave_instance=7 ;;
	3345 ) slave_instance=8 ;;
	3350 ) slave_instance=9 ;;
	*    ) slave_instance=0 ;;
esac

master_connection="mysql --socket=/mysql_0${master_instance}/mysql.sock --port=$master_port --user=$master_user\
 --password=$master_pass"

slave_connection="mysql --socket=/mysql_0${slave_instance}/mysql.sock --port=$slave_port --user=$slave_user\
 --password=$slave_pass"

# Temporary files.
tmp1=/tmp/progname.$$.tmp1
tmp_file="$tmp1"

# TSA status states.
TSA_STATE_UNKNOWN=0
TSA_STATE_ONLINE=1
TSA_STATE_OFFLINE=2
TSA_STATE_FAILED_OFFLINE=3
TSA_STATE_STUCK_ONLINE=4
TSA_STATE_PENDING_ONLINE=5
TSA_STATE_PENDING_OFFLINE=6

# TSA start/stop command states.
TSA_CMD_SUCCESS=0
TSA_CMD_FAIL=1


################################################################################
# Functions
################################################################################

function clean_up
{
	#####
	#	Function to remove temporary files and other housekeeping
	#	No arguments
	#####

	rm -f ${tmp_file}
}

function status_fail
{
	#####
	# 	Function for exit due to fatal program error
	# 	Accepts 1 argument
	#		string containing descriptive error message
	#####

	echo "${progname}: ${1:-"Unknown Error"}" 1>&2

	clean_up
	exit $TSA_STATE_UNKNOWN
}

function start_fail
{
	#####
	# 	Function for exit due to fatal program error
	# 	Accepts 1 argument
	#		string containing descriptive error message
	#####

	echo "${progname}: ${1:-"Unknown Error"}" 1>&2

	# Restore stdout and stderr to normal and close file descriptors.
	exec 1>&4 4>&- 2>&5 5>&-

	mail -s "$email_subject" "$email_address" < $log || echo "Cannot send email." >&2
	chown :dba $log

	clean_up
	exit $TSA_CMD_FAIL
}

function stop_fail
{
	#####
	# 	Function for exit due to fatal program error
	# 	Accepts 1 argument
	#		string containing descriptive error message
	#####

	echo "${progname}: ${1:-"Unknown Error"}" 1>&2

	# Restore stdout and stderr to normal and close file descriptors.
	exec 1>&4 4>&- 2>&5 5>&-

	mail -s "$email_subject" "$email_address" < $log || echo "Cannot send email." >&2
	chown :dba $log

	clean_up
	exit $TSA_CMD_FAIL
}

function usage
{
	#####
	#	Function to show usage
	#	No arguments
	#####

	echo "USAGE"
	echo "	$progname OPTIONS"
	echo
	echo "SYNOPSIS"
	echo "	$progname {start|stop|status} | [-?|--help]"
	echo
	echo "OPTIONS"
	echo "	start"
	echo "		Start MySQL failover to slave."
	echo
	echo "	stop"
	echo "		Not implemented at the moment. No action is taken."
	echo
	echo "	status"
	echo "		Not implemented at the moment. No action is taken."
	echo
	echo "EXAMPLE"
	echo "	$progname start"

	clean_up
	exit 99
}


################################################################################
# Program starts here
################################################################################

case $1 in
	start )
		if [[ "`hostname`" = "$master_host" ]]; then
			operation=start_master
		elif [[ "`hostname`" = "$slave_host" ]]; then
			operation=start_slave
		fi
		;;
	stop )
		if [[ "`hostname`" = "$master_host" ]]; then
			operation=stop_master
		elif [[ "`hostname`" = "$slave_host" ]]; then
			operation=stop_slave
		fi
		;;
	status )
		if [[ "`hostname`" = "$master_host" ]]; then
			operation=status_master
		elif [[ "`hostname`" = "$slave_host" ]]; then
			operation=status_slave
		fi
		;;
	-? | --help | * )
		usage
esac

if [[ -z "operation" ]]; then
	echo "Make sure proper command was passed in or that master and slave hostnames are correctly set."
	echo
	usage
fi

if [[ "$operation" = "status_master" ]]; then
	if [[ -e $run_file ]]; then
		exit $TSA_STATE_ONLINE
	else
		exit $TSA_STATE_OFFLINE
	fi
fi

if [[ "$operation" = "status_slave" ]]; then
	if [[ -e $run_file ]]; then
		exit $TSA_STATE_ONLINE
	else
		exit $TSA_STATE_OFFLINE
	fi
fi

echo "" > $log
# Link file descriptor #4 with stdout.
exec 4>&1
# Link file descriptor #5 with stderr.
exec 5>&2
# stdout and stderr replaced with log file.
exec 1>> $log
exec 2>> $log

echo "**************************************************"
echo "* MySQL TSA Operation: $operation"
echo "* Time started:" `date +'%F %T %Z'`
echo "**************************************************"
echo
echo "   Database: $database"
echo "Master host: $master_host"
echo "Master port: $master_port"
echo " Slave host: $slave_host"
echo " Slave port: $slave_port"
echo

if [[ "$operation" = "start_master" ]]; then
	echo "Checking if master instance is available..."
	$master_connection -e "USE $database; SELECT 1;" > $tmp1 \
	 || start_fail "Error on line $LINENO. Test query failed."
	echo "Done."
	echo

	echo "Checking read-only option..."
	$master_connection -e "SHOW VARIABLES LIKE 'read_only';" > $tmp1 \
	 || start_fail "Error on line $LINENO. Could not get system variable."
	cat $tmp1
	if [[ "`cat $tmp1 | grep 'read_only' | grep 'OFF' | wc -l`" != 1 ]]; then
		start_fail "Error on line $LINENO. Read-only option might not be set to off."
	fi
	echo "Done."
	echo

	touch $run_file || start_fail "Error on line $LINENO. Could not create file."
fi

if [[ "$operation" = "stop_master" ]]; then
	rm -f $run_file || stop_fail "Error on line $LINENO. Could not delete file."
fi

if [[ "$operation" = "start_slave" ]]; then
	# Show slave status.
	echo "Show slave status:"
	$slave_connection -e "SHOW SLAVE STATUS\G;" > $tmp1 \
	 || start_fail "Error on line $LINENO. Could not get slave status."
	cat $tmp1
	echo "Done."
	echo

	# Check if slave SQL thread is running.
	slave_sql_thread=`cat $tmp1 | grep 'Slave_SQL_Running:' | awk -F': ' '{print $2}'`
	if [[ "$slave_sql_thread" != "Yes" ]]; then
		start_fail "Error on line $LINENO. Slave SQL thread is not running."
	fi

	# Stop slave IO thread.
	echo "Stop slave IO thread..."
	$slave_connection -e "STOP SLAVE IO_THREAD;" \
	 || start_fail "Error on line $LINENO. Could not stop slave IO thread."
	slave_io_thread=`$slave_connection -e "SHOW SLAVE STATUS\G;" | grep 'Slave_IO_Running:' | awk -F': ' '{print $2}'`
	if [[ "$slave_io_thread" != "No" ]]; then
		start_fail "Error on line $LINENO. Could not stop slave IO thread."
	fi
	echo "Done."
	echo

	# Wait up to 5 minutes until relay logs have been processed.
	echo -n "Checking if all relay logs have been processed.."
	i=0
	while test $i -lt 300 ; do
		$slave_connection -e "SHOW SLAVE STATUS\G;" > $tmp1 \
		 || start_fail "Error on line $LINENO. Could not get slave status."

		read_master_log_file=`cat $tmp1 | grep 'Master_Log_File:' | \
		 grep -v 'Relay_Master_Log_File:' | awk -F': ' '{print $2}'`
		read_master_log_pos=`cat $tmp1 | grep 'Read_Master_Log_Pos:' | awk -F': ' '{print $2}'`
		exec_master_log_file=`cat $tmp1 | grep 'Relay_Master_Log_File:' | awk -F': ' '{print $2}'`
		exec_master_log_pos=`cat $tmp1 | grep 'Exec_Master_Log_Pos:' | awk -F': ' '{print $2}'`

		if [[ -z "$read_master_log_file" \
		   || -z "$read_master_log_pos" \
		   || -z "$exec_master_log_file" \
		   || -z "$exec_master_log_pos" \
		]]; then
			start_fail "Error on line $LINENO. Could not get one of the slave status variables."
		fi

		echo -n "."
		if [[ "$read_master_log_file" = "$exec_master_log_file" ]]; then
			if [[ "$read_master_log_pos" = "$exec_master_log_pos" ]]; then
				break
			fi
		fi

		i=$((i + 1))
		sleep 1
	done
	echo
	if [[ "$read_master_log_file" != "$exec_master_log_file" ]]; then
		start_fail "Error on line $LINENO. Slave read log file does not match executed log file."
	fi
	if [[ "$read_master_log_pos" != "$exec_master_log_pos" ]]; then
		start_fail "Error on line $LINENO. Slave read log position does not match executed log position."
	fi
	echo "Done."
	echo

	# Stop slave SQL thread.
	echo "Stop slave SQL thread..."
	$slave_connection -e "STOP SLAVE SQL_THREAD;" \
	 || start_fail "Error on line $LINENO. Could not stop slave SQL thread."
	slave_sql_thread=`$slave_connection -e "SHOW SLAVE STATUS\G;" \
	 | grep 'Slave_SQL_Running:' | awk -F': ' '{print $2}'`
	if [[ "$slave_sql_thread" != "No" ]]; then
		start_fail "Error on line $LINENO. Could not stop slave SQL thread."
	fi
	echo "Done."
	echo

	# Show slave status.
	echo "Show slave status:"
	$slave_connection -e "SHOW SLAVE STATUS\G;" > $tmp1 \
	 || start_fail "Error on line $LINENO. Could not get slave status."
	cat $tmp1
	echo "Done."
	echo

	# Promote slave to master.
	echo "Promote slave to master..."
	$slave_connection -e "CHANGE MASTER TO MASTER_HOST='';" \
	 || start_fail "Error on line $LINENO. Promoting slave to master failed."
	$slave_connection -e "SHOW SLAVE STATUS\G;" > $tmp1 \
	 || start_fail "Error on line $LINENO. Could not get slave status."
	if [[ "`cat $tmp1 | wc -l`" != "0" ]]; then
		start_fail "Error on line $LINENO. Promoting slave to master failed."
	fi
	echo "Done."
	echo

	# Disable dynamic read-only option.
	echo "Set read_only variable to OFF..."
	$slave_connection -e "SET GLOBAL read_only = OFF;" \
	 || start_fail "Error on line $LINENO. Could not disable read-only option."
	$slave_connection -e "SHOW VARIABLES LIKE 'read_only';" > $tmp1 \
	 || start_fail "Error on line $LINENO. Could not get system variable."
	cat $tmp1
	if [[ "`cat $tmp1 | grep 'read_only' | grep 'OFF' | wc -l`" != 1 ]]; then
		start_fail "Error on line $LINENO. Could not disable read-only option."
	fi
	echo "Done."
	echo

	# Disable read-only option at start up.
	echo "Set read_only variable to OFF in MySQL init file, in case new master MySQL instance gets restarted..."
	init_file=/usr/local/bin/mysql/m${slave_instance}_init.sql
	echo "SET GLOBAL read_only = OFF;" >> $init_file \
	 || start_fail "Error on line $LINENO. Could not write to MySQL init file."
	echo "Output of $init_file:"
	cat $init_file
	echo "Done."
	echo

	#### Add code to replay binary logs which have not been processed from master.
	#### This will depend on mounting master's SAN disk.

	# Show master status.
	echo "Show master status:"
	$slave_connection -e "SHOW MASTER STATUS\G;" \
	 || start_fail "Error on line $LINENO. Could not get master status."
	echo "Done."
	echo

	touch $run_file || start_fail "Error on line $LINENO. Could not create file."
fi

if [[ "$operation" = "stop_slave" ]]; then
	# Enable dynamic read-only option.
	echo "Set read_only variable to ON..."
	$slave_connection -e "SET GLOBAL read_only = ON;" \
	 || stop_fail "Error on line $LINENO. Could not enable read-only option."
	$slave_connection -e "SHOW VARIABLES LIKE 'read_only';" > $tmp1 \
	 || stop_fail "Error on line $LINENO. Could not get system variable."
	cat $tmp1
	if [[ "`cat $tmp1 | grep 'read_only' | grep 'ON' | wc -l`" != 1 ]]; then
		stop_fail "Error on line $LINENO. Could not enable read-only option."
	fi
	echo "Done."
	echo

	echo "Manually syncronize slave with the master and remove read-only option settings from MySQL init file."
	echo

	rm -f $run_file || stop_fail "Error on line $LINENO. Could not delete file."
fi

echo "**************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "**************************************************"

# Restore stdout and stderr to normal and close file descriptors.
exec 1>&4 4>&- 2>&5 5>&-

mail -s "$email_subject" "$email_address" < $log || echo "Cannot send email." >&2
chown :dba $log

clean_up
exit $TSA_CMD_SUCCESS
