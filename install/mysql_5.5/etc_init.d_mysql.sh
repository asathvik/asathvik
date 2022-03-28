#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#	Parts of the script were taken from original MySQL start/stop script.
#
# Purpose:
#	MySQL server instance start/stop script. This script is to replace the 
#	default "/etc/init.d/mysql" script on the server.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	07/06/2009 - Dimitriy Alekseyev
#	Created the script which would allow multiple instance support and read
#	my.cnf file from each mysql directory (i.e. from /mysql_01/my.cnf).
#	07/08/2009 - Dimitriy Alekseyev
#	Added status and version options to the script.
#	09/14/2010 - Dimitriy Alekseyev
#	Added support for running multiple MySQL versions on same server.
#	07/12/2011 - Dimitriy Alekseyev
#	Modified script to support path and username variables.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# At server boot up, listed instances are auto started.
# Enclose in single or double quotes and separate multiple instances with space.
# 'all' is used to specify that all instances are auto started.
auto_startup_instances='all'

# Program name.
progname=$(basename $0)

# Operating System user account to use for MySQL administration.
os_user=mysql
# Main MySQL directory to use for sybolic links and other things.
main_dir=/mysql
# Version number.
version=2.1
# Mode of operation - start, stop, or restart.
mode=$1
# Instance list passed in as an argument.
shift; instlist=$@
# Exit status.
exit_status=0
# Number of seconds to wait before giving up on a start/stop operation.
seconds=35


################################################################################
# Functions
################################################################################

wait_for_pid () {
  i=0
  while test $i -lt $seconds ; do
    sleep 1
    case "$1" in
      'created')
        test -s $pid_file && i='' && break
        ;;
      'removed')
        test ! -s $pid_file && i='' && break
        ;;
      *)
        echo "wait_for_pid () usage: wait_for_pid created|removed"
        exit 1
        ;;
    esac
    echo $echo_n ".$echo_c"
    i=`expr $i + 1`
  done

  if [[ -z "$i" ]]; then
    log_success_msg
  else
    log_failure_msg
    exit_status=$((exit_status + 1))
  fi
}


################################################################################
# Program starts here
################################################################################

# Use LSB init script functions for printing messages, if possible
lsb_functions="/lib/lsb/init-functions"
if [[ -f $lsb_functions ]]; then
  source $lsb_functions
else
  log_success_msg()
  {
    echo " SUCCESS! $@"
  }
  log_failure_msg()
  {
    echo " ERROR! $@"
  }
fi

case `echo "testing\c"`,`echo -n testing` in
	*c*,-n*) echo_n=   echo_c=     ;;
	*c*,*)   echo_n=-n echo_c=     ;;
	*)       echo_n=   echo_c='\c' ;;
esac

# Check if running under correct user.
if [[ (`id -un` != root) && (`id -un` != $os_user) ]]; then
	log_failure_msg "You have to be 'root' or '$os_user' user!"
	exit 1
fi

# Get a list of all instances.
all_instances=`ls -d $main_dir/??/ | xargs -n 1 -i basename {} | grep '[0-9][0-9]' | sed 's/^0//' | tr '\n' ' '`

# Evaluate auto start up instances.
if [[ "$auto_startup_instances" = "all" ]]; then
	auto_startup_instances="$all_instances"
fi

case "$mode" in
  'start')    # Start daemon
	# If instance list is empty, then operate on "auto start up" instance list.
	if [[ -z "$instlist" ]]; then
		instlist=$auto_startup_instances
	fi
	for inst in $instlist; do
		# Instance number with the leading zero if it is less than 10.
		inst_wlz="0$inst"
		inst_wlz=${inst_wlz:${#inst_wlz}-2:2}

		# PID file name.
		pid_file=$main_dir/$inst_wlz/${HOSTNAME}_$inst_wlz.pid
		
		# Check if PID file size is greater than zero.
		if [[ -s "$pid_file" ]]; then
			pid="`cat $pid_file`"
			
			if ps --no-headers --pid=$pid | grep $pid &> /dev/null; then
				log_failure_msg "Cannot start MySQL instance $inst. MySQL is already running!"
				exit_status=$((exit_status + 1))
				continue
			fi
		fi

		echo $echo_n "Starting MySQL instance $inst"
		# If custom MySQL version is specified in my.cnf, then run custom version.
		ledir=$(sed '/^ledir/!d' $main_dir/$inst_wlz/my.cnf | awk -F= '{print $2}')
		if [[ $ledir ]]; then
			$ledir/mysqld_safe --defaults-file=$main_dir/$inst_wlz/my.cnf &> $main_dir/$inst_wlz/logs/mysqld_safe.log &
		else
			/usr/bin/mysqld_safe --defaults-file=$main_dir/$inst_wlz/my.cnf &> $main_dir/$inst_wlz/logs/mysqld_safe.log &
		fi
		wait_for_pid created
	done
  ;;

  'stop')    # Stop daemon
	# If instance list is empty, then operate on all running instances.
	if [[ -z "$instlist" ]]; then
		# Check if there are any running instances.
		if ls $main_dir/??/${HOSTNAME}_*.pid &> /dev/null; then
			# Get a list of all running instances.
			instlist=`ls $main_dir/??/${HOSTNAME}_*.pid | gawk -F"${HOSTNAME}\_" '{print $2}' 2> /dev/null | gawk -F'.' '{print $1}' | sed 's/^0//' | tr '\n' ' '`
		else
			# Nothing needs to be stopped.
			echo "There are no running MySQL instances."
			exit $exit_status
		fi
	fi
	for inst in $instlist; do
		# Instance number with the leading zero if it is less than 10.
		inst_wlz="0$inst"
		inst_wlz=${inst_wlz:${#inst_wlz}-2:2}
		
		# PID file name.
		pid_file=$main_dir/$inst_wlz/${HOSTNAME}_$inst_wlz.pid

		# Check if PID file size is greater than zero.
		if [[ -s "$pid_file" ]]; then
			echo $echo_n "Stopping MySQL instance $inst"
			read mysqld_pid < $pid_file
			kill $mysqld_pid
			wait_for_pid removed
		else
			log_failure_msg "Cannot stop MySQL instance $inst. MySQL PID file does not exist!"
			exit_status=$((exit_status + 1))
		fi
	done
  ;;

  'restart')
	# If instance list is empty, then operate on all instances.
	if [[ -z "$instlist" ]]; then
		instlist="$all_instances"
	fi
	# Stop the instance and regardless of whether it was running or not, start it again.
	$0 stop
	$0 start $instlist
  ;;

  'status')
	# If instance list is empty, then operate on all instances.
	if [[ -z "$instlist" ]]; then
		instlist="$all_instances"
	fi
	for inst in $instlist; do
		# Instance number with the leading zero if it is less than 10.
		inst_wlz="0$inst"
		inst_wlz=${inst_wlz:${#inst_wlz}-2:2}	

		# PID file name.
		pid_file=$main_dir/$inst_wlz/${HOSTNAME}_$inst_wlz.pid	
	
		# Check if PID file size is greater than zero.
		if [[ -s "$pid_file" ]]; then
			read mysqld_pid < $pid_file
			if kill -0 $mysqld_pid 2>/dev/null; then
				echo MySQL instance $inst_wlz is running.
			else
				echo MySQL instance $inst_wlz is stopped.
			fi
		else
			echo MySQL instance $inst_wlz is stopped.
		fi
	done
  ;;

  'version'|'--version')
	# If instance list is empty, then operate on default instance list.
	echo $0 Version $version
  ;;

  *)
	# usage
	echo "Usage:"
	echo "    $0 {start|stop|restart|status} [instance# [instance# [...]]]"
	echo "    If the instance# is not specified, then defaults will be used for start and restart."
	echo "    The defaults are inside $0 script, in 'auto_startup_instances' variable."
	echo "    Stop and status commands operate on all instances when no instance is specified."
	echo "Examples:"
	echo "    $0 start"
	echo "    $0 stop 3 5"
	echo "    $0 restart 1"
	exit 1
  ;;
esac

exit $exit_status
