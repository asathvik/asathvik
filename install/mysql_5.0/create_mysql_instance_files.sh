#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Create MySQL instance files for starting, stopping, and other functions.
#	Files are created in current directory.
#
# Usage:
#	create_mysql_instance_files.sh engine instance_number
#
# Revisions:
#	01/14/2008 - Dimitriy Alekseyev
#	Script created.
#	02/08/2008 - Dimitriy Alekseyev
#	Created working version of the script.
#	07/08/2008 - Dimitriy Alekseyev
#	Made minor improvements.
#	07/17/2008 - Dimitriy Alekseyev
#	Changed to take instance number as a parameter.
#	Updated script to work with instance numbers above 9.
#	06/20/2009 - Dimitriy Alekseyev
#	Updated script to create settings that could be pasted into my.cnf file for
#	each instance.
#	07/06/2009 - Dimitriy Alekseyev
#	Updated script to work with revised MySQL data paths. Added generation of 
#	myisam and innodb my.cnf template files.
#	01/10/2013 - Dimitriy Alekseyev
#	Made slight revisions to innodb my.cnf settings.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

user=dbauser
pass=surfb0ard

engine=$1
inst=$2
port=$((inst * 5 + 3305))

# Instance number with the leading zero if it is less than 10.
inst_wlz="0$inst"
inst_wlz=${inst_wlz:${#inst_wlz}-2:2}


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

function error_exit {
	# Function for exit due to fatal program error
	# Accepts 1 argument
	#	string containing descriptive error message
	echo "${progname}: ${1:-"Unknown Error"}" 1>&2
	clean_up
	exit 1
}

function term_exit {
	# Function to perform exit if termination signal is trapped
	# No arguments
	echo "${progname}: Terminated"
	clean_up
	exit
}

function int_exit {
	# Function to perform exit if interrupt signal is trapped
	# No arguments
	echo "${progname}: Aborted by user"
	clean_up
	exit
}

function usage {
	# Function to show usage
	# No arguments
	echo "Usage:"
	echo "	$0 {myisam | innodb} instance_number"
	echo "Example:"
	echo "	$0 innodb 7"
	clean_up
	exit 1
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT

# Check number of parameters.
if [[ $# -ne 2 ]]; then
	echo "Error: Incorrect number of parameters."
	echo
	usage
fi

# Check if enginge is myisam or innodb.
if [[ "$engine" != myisam && "$engine" != innodb ]]; then
    usage
fi

cat << EOF > m${inst}start.sh
/etc/init.d/mysql start $inst
EOF

cat << EOF > m${inst}stop.sh
/etc/init.d/mysql stop $inst
EOF

cat << EOF > m${inst}_passwd.txt
$pass
EOF

cat << EOF > m${inst}c.sh
mysql --host=localhost --port=$port --socket=/mysql/$inst_wlz/mysql.sock --user=$user --force --table --unbuffered --verbose --verbose --prompt='mysql $inst_wlz> ' -p\`cat /usr/local/bin/mysql/m${inst}_passwd.txt\`
EOF


# Create my.cnf file with myisam settings.
if [[ "$engine" = myisam ]]; then
cat << EOF > my.cnf_${inst_wlz}.txt
[mysqld]
basedir=/usr
datadir=/mysql/${inst_wlz}/data
socket=/mysql/${inst_wlz}/mysql.sock
port=${port}
pid-file=/mysql/${inst_wlz}/${HOSTNAME}_${inst_wlz}.pid
log-error=/mysql/${inst_wlz}/logs/${HOSTNAME}_${inst_wlz}.err
tmpdir=/mysql/${inst_wlz}/tmp
#init-file=/mysql/${inst_wlz}/init_${inst_wlz}.sql
skip-innodb
default-storage-engine=myisam

max_connections=500
table_cache=500
key_buffer_size=500M
#join_buffer_size=2000M
#sort_buffer_size=500M
#read_buffer_size=5M
#read_rnd_buffer_size=5M
#tmp_table_size=1000M
long_query_time=1
lower_case_table_names=1
sql_mode=ANSI,TRADITIONAL
EOF
fi


# Create my.cnf file with innodb settings.
if [[ "$engine" = innodb ]]; then
cat << EOF > my.cnf_${inst_wlz}.txt
[mysqld]
basedir=/usr
datadir=/mysql/${inst_wlz}/data
socket=/mysql/${inst_wlz}/mysql.sock
port=$port
pid-file=/mysql/${inst_wlz}/${HOSTNAME}_${inst_wlz}.pid
log-error=/mysql/${inst_wlz}/logs/${HOSTNAME}_${inst_wlz}.err
tmpdir=/mysql/${inst_wlz}/tmp
#init-file=/mysql/${inst_wlz}/init_${inst_wlz}.sql
innodb
default-storage-engine=innodb

max_connections=100
#table_cache=100
#key_buffer_size=500M
#join_buffer_size=2000M
#sort_buffer_size=500M
#read_buffer_size=5M
#read_rnd_buffer_size=5M
#tmp_table_size=1000M
long_query_time=1
lower_case_table_names=1
sql_mode=ANSI,TRADITIONAL

#
### Replication Settings
#
#read-only
server-id=1
log-bin=/mysql/${inst_wlz}/binlogs/binlog_${HOSTNAME}_${inst_wlz}
max-binlog-size=100M
log-slave-updates
expire_logs_days=14
relay-log=/mysql/${inst_wlz}/binlogs/relaylog_${HOSTNAME}_${inst_wlz}
max-relay-log-size=50M
report-host=${HOSTNAME}
report-port=$port

########################################
# InnoDB Settings
########################################

#
### Tablespace settings
#

# One tablespace per table
innodb_file_per_table

# Define single shared tablespace for information schema
innodb_data_file_path=shared.ibd:10M:autoextend

# Set size of tablespace auto increment
innodb_autoextend_increment=8M

#
### Buffer settings
#

# Define size of buffer pool used for data and indexes
innodb_buffer_pool_size=128M

# Define size of memory pool used to store data dictionary and other internal structures
innodb_additional_mem_pool_size=8M

# Set log buffer size. The default value is 1MB. Sensible values range from 1MB to 8MB.
innodb_log_buffer_size=8M

#
### Log file Settings
#

# Set log file size and number of log files
innodb_log_file_size=25M
innodb_log_files_in_group=4

# Enable 1 set of logs - no mirrored logs.
innodb_mirrored_log_groups=1

#
### Threading and Concurrency settings
#

# The number of threads that can commit at the same time.
# A value of 0 (the default) allows any number of transactions to commit simultaneously.
innodb_commit_concurrency=0

# Keep number of OS threads inside InnoDB less than or eqal to this value.
# The range of this variable is 0 to 1000.
# The default value: 8 (finite) from version 5.0.21 on.
innodb_thread_concurrency=8

#
### Flushing, writing and syncing
#

# Enables direct write
innodb_flush_method=O_DIRECT

# The InnoDB shutdown mode.
# By default, the value is 1, which causes a "fast" shutdown (the normal type of shutdown).
# If the value is 0, InnoDB does a full purge and an insert buffer merge before a shutdown.
# These operations can take minutes, or even hours in extreme cases.
# If the value is 1, InnoDB skips these operations at shutdown.
# If the value is 2, InnoDB will just flush its logs and then shut down cold, as if MySQL had crashed;
# no committed transaction will be lost, but crash recovery will be done at the next startup.
innodb_fast_shutdown=1

# The default value of sync_binlog is 0, which does no synchronizing to disk.
# Value of 1 means flush to disk after every txn. Very slow unless the disk has battery-backed cache.
sync_binlog=1

# If the value of is 0, the log buffer is written out to the log file once per second and the
# flush to disk operation is performed on the log file, but nothing is done at a transaction commit.
# When the value is 1 (the default), the log buffer is written out to the log file at each
# transaction commit and the flush to disk operation is performed on the log file.
innodb_flush_log_at_trx_commit=1

#
### Locking
#

# When the variable is 1 (the default), InnoDB support for two-phase commit in XA transactions
# is enabled, which causes an extra disk flush for transaction preparation. Set to 0 to disable.
# Having innodb_support_xa enabled on a replication master - or on any MySQL server where binary
# logging is in use - ensures that the binary log does not get out of sync compared to the table data.
innodb_support_xa=1

#
### Additional Admin Settings
#

# Max number of innodb open files. The minimum value is 10. The default value is 300.
innodb_open_files=300

# Turn on option for writing innodb status file
innodb_status_file
EOF
fi


chmod 770 m${inst}start.sh m${inst}stop.sh m${inst}c.sh
chown mysql:dba m${inst}start.sh m${inst}stop.sh m${inst}c.sh
chmod 660 m${inst}_passwd.txt my.cnf_${inst_wlz}.txt
chown mysql:dba m${inst}_passwd.txt my.cnf_${inst_wlz}.txt

graceful_exit
