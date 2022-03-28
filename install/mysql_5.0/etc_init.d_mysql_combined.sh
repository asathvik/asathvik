#!/bin/bash
################################################################################
# Author:
#	Dave Wong, Dimitriy Alekseyev
#	Parts of the script were taken from original MySQL start/stop script.
#
# Purpose:
#	MySQL server instance start/stop script. This script is to replace the 
#	default "/etc/init.d/mysql" script on the server. This script is to be 
#	used in situations where a mix of old and new directory structures are 
#	used, like /mysql_01 and /mysql/02.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	05/09/2006 - Dave Wong, Dimitriy Alekseyev
#	Script created.
#	09/14/2007 - Dimitriy Alekseyev
#	Made improvements to the script. Also added a check to see if MySQL 
#	process is running or not during start up, instead of just failing if 
#	PID file is present.
#	09/28/2007 - Dimitriy Alekseyev
#	Updated to check for username to be root or mysql before running script.
#	Modified the script so that it will stop all running instances, instead 
#	of just stopping auto start instances when instance number is not 
#	passed in.
#	10/16/2007 - Dimitriy Alekseyev
#	Updated script to work with instances higher than 9 by including code 
#	which takes care of leading zeroes.
#	12/29/2009 - Dimitriy Alekseyev
#	Modified script to handle both new and old MySQL directory structure by 
#	calling the new script for instances with new directory structure. For 
#	now instance numbers that are new are hard coded.
#	10/23/2011 - Dimitriy Alekseyev
#	Revised script to start appropriate instances when more than one 
#	instance is supplied as a parameter.
#	01/10/2013 - Dimitriy Alekseyev
#	Removed errors from showing up when there are no instances set up with 
#	new directory structure. Same thing for situations when there are no 
#	instances with old directory structure.
#	01/18/2013 - Dimitriy Alekseyev
#	Fixed script to not operate on all new instances when a non-existent 
#	instance number is supplied. Fixed other related issues.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Default list of instances to be operated on.
# At server boot up, these instances are auto started.
# Enclose in single or double quotes and separate multiple instances with space.
instlist_default='1 2 3 4'

# Mode of operation - start, stop, or restart.
mode=$1

# Instance list passed in as an argument.
shift; instlist=$@

# Hostname.
host=`hostname`

# Exit status.
exit_status=0


################################################################################
# Program starts here
################################################################################

# Get a list of all instances with new directory structure.
all_new_instances=$(ls -d /mysql/??/ 2> /dev/null | xargs -n 1 -i basename {} | grep '[0-9][0-9]' | sed 's/^0//' | tr '\n' ' ' | sed 's/ $//')
# Get a list of all instances with old directory structure.
all_old_instances=$(ls -d /mysql_??/ 2> /dev/null | sed 's!/mysql_!!' | sed 's!/!!' | grep '[0-9][0-9]' | sed 's/^0//' | tr '\n' ' ' | sed 's/ $//')

# Find instances matching new directory structure.
for inst1 in $instlist; do
	for inst2 in $all_new_instances; do
		if [[ $inst1 = $inst2 ]]; then
			instlist_new=$instlist_new" "$inst1
			break
		fi
	done
done

# Find instances matching old directory structure.
for inst1 in $instlist; do
	for inst2 in $all_old_instances; do
		if [[ $inst1 = $inst2 ]]; then
			instlist_old=$instlist_old" "$inst1
			break
		fi
	done
done

# Execute appropriate scripts.
if [[ ! -z $instlist_new && -z $instlist_old ]]; then
	# Execute new script only.
	/etc/init.d/mysql_new $mode $instlist_new
	exit $?
elif [[ ! -z $instlist_old && -z $instlist_new ]]; then
	# Execute old script only.
	:
elif [[ -z $instlist_new && -z $instlist_old && ! -z $instlist ]]; then
	# Do not execute any scripts.
	echo "ERROR: No such instance(s)."
	exit 1
else
	# Execute both scripts.
	/etc/init.d/mysql_new $mode $instlist_new
	exit_status=$((exit_status + $?))
fi

# Make sure that we do not use an empty list of old instances.
if [[ -z $instlist_old ]]; then
	instlist=$all_old_instances
else
	instlist=$instlist_old
fi

# Make sure that we do not have any old instances that match a new instance.
instlist_old=""
for inst1 in $instlist; do
	is_new=0
	for inst2 in $all_new_instances; do
		if [[ $inst1 = $inst2 ]]; then
			is_new=1
			break
		fi
	done
	if [[ $is_new = 0 ]]; then
		instlist_old=$instlist_old" "$inst1
	fi
done

# Exit if there are no old instances.
if [[ -z $instlist_old ]]; then
	exit $exit_status
fi
instlist=$instlist_old

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

# Check if user is root or mysql.
if [[ ("`id -un`" != root) && ("`id -un`" != mysql) ]]; then
	log_failure_msg "You have to be 'root' or 'mysql' user!"
	exit 1
fi

case `echo "testing\c"`,`echo -n testing` in
    *c*,-n*) echo_n=   echo_c=     ;;
    *c*,*)   echo_n=-n echo_c=     ;;
    *)       echo_n=   echo_c='\c' ;;
esac

wait_for_pid () {
  i=0
  while test $i -lt 35 ; do
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

case "$mode" in
  'start')    # Start daemon
	# If instance list is empty, then operate on default instance list.
	if [[ -z "$instlist" ]]; then
		instlist=$instlist_default
	fi
	for inst in $instlist
	do
		# Instance number with the leading zero if it is less than 10.
		inst_wlz="0$inst"
		inst_wlz=${inst_wlz:${#inst_wlz}-2:2}
	
		# PID file name.
		pid_file=/mysql_${inst_wlz}/$host.pid${inst}
		
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
		/usr/bin/mysqld_multi --no-log start $inst >/dev/null 2>&1
		wait_for_pid created
	done
  ;;

  'stop')    # Stop daemon
	# Check if instance list is empty.
	if [[ -z "$instlist" ]]; then
		# Check if there are any running instances.
		if ls /mysql_??/`hostname`.pid* &> /dev/null; then
			# Get a list of all running instances.
			instlist=`ls /mysql_??/$host.pid* | gawk -F'pid' '{print $2}' | tr '\n' ' '`
		else
			# Nothing needs to be stopped.
			echo "There are no running MySQL instances."
			exit $exit_status
		fi
	fi
	for inst in $instlist
        do
		# Instance number with the leading zero if it is less than 10.
		inst_wlz="0$inst"
		inst_wlz=${inst_wlz:${#inst_wlz}-2:2}
		
		# PID file name.
		pid_file=/mysql_${inst_wlz}/$host.pid${inst}

		# Check if PID file size is greater than zero.
		if [[ -s "$pid_file" ]]; then
			echo $echo_n "Stopping MySQL instance $inst"
			kill `cat $pid_file`
			wait_for_pid removed
		else
			log_failure_msg "Cannot stop MySQL instance $inst. MySQL PID file doesn't exist!"
			exit_status=$((exit_status + 1))
		fi
	done
  ;;

  'restart')
	# If instance list is empty, then operate on default instance list.
	if [[ -z "$instlist" ]]; then
		instlist=$instlist_default
	fi
	# Stop the service and regardless of whether it was
	# running or not, start it again.
	$0 stop $2
	$0 start $2
  ;;

  *)
	# usage
	echo "Usage:"
	echo "    $0 start|stop|restart [instance# [instance# [...]]]"
	echo "    If the instance# is not specified, then defaults will be used."
	echo "    The defaults are inside $0 script, in 'instlist_default' variable."
	echo "Examples:"
	echo "    $0 start"
	echo "    $0 stop 3 5"
	echo "    $0 restart 1"
	exit 1
  ;;
esac

exit $exit_status
