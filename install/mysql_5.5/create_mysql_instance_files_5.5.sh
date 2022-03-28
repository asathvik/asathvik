#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Create MySQL instance files for starting, stopping, and other functions.
#	Files are created in current directory. Supports having multiple MySQL 
#	versions on same server. This script is to be called by another script.
#	To be used for MySQL 5.1.3 and up.
#
# Usage:
#	Run script with -? or --help option to get usage information.
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
#	09/14/2010 - Dimitriy Alekseyev
#	Modified script to support having multiple versions of MySQL on the 
#	same server.
#	07/08/2011 - Dimitriy Alekseyev
#	Changed variables for administrator username and password to parameters. 
#	Changed the prompt to display more informatino for MySQL client script.
#	07/12/2011 - Dimitriy Alekseyev
#	Removed change ownership (chown) commands from the script as this allows 
#	it to be run on other team's servers where user and group are not mysql:dba.
#	Added main directory parameter.
#       09/13/2011 - Dimitriy Alekseyev
#	Modified MySQL prompt. Newline in the prompt was creating issues when 
#	going through command history.
#       10/22/2011 - Dimitriy Alekseyev
#	Revised and added many new InnoDB settings.
#       10/27/2011 - Dimitriy Alekseyev
#	Revised some option settings as MySQL does not always take ON/OFF setting.
#       11/22/2011 - Dimitriy Alekseyev
#	Removed --force and --skip-reconnect options from client connection 
#	scripts. Removing --force halts execution on failed statement and 
#	provides a return error code from the client. Having --skip-reconnect 
#	was causing issues for John with long running LOAD DATA commands. Added 
#	newline back into the prompt since the issue was not caused by newline, 
#	but by MySQL comiling with editline instead of readline library.
#       01/09/2012 - Dimitriy Alekseyev
#	Added 'log-warnings=2' option to my.cnf file.
#	06/29/2012 - Dimitriy Alekseyev
#	Removed "--comments" option from m${inst}c.sh script. It was causing 
#	log files to bloat with junk.
#	04/24/2013 - Dimitriy Alekseyev
#	Added "max_allowed_packet=16M" option and made some other changes.
#
# Todo:
#	Revise some more option settings as it is not recommended to use ON/OFF 
#	settings in my.cnf for now.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

mysql_bin_dir_and_ver=$1
mysql_ver_short=$2
# MySQL database engine to use for initial configuration.
engine=$3
# Instance number to create.
inst=$4
# Main directory to use for sybolic links and other things.
main_dir=$5
# MySQL administrator username.
db_admin_user=$6
# MySQL administrator password.
db_admin_pass=$7

# Port number.
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
	echo "	$0 {myisam | innodb} instance_number db_admin_user db_admin_pass"
	echo "Example:"
	echo "	$0 innodb 7 dbauser dbapassword"
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
if [[ $# -ne 7 ]]; then
	echo "Error: Incorrect number of parameters."
	echo
	usage
fi

# Check if enginge is myisam or innodb.
if [[ $engine != myisam && $engine != innodb ]]; then
    usage
fi

cat << EOF > m${inst}start.sh
/etc/init.d/mysql start $inst
EOF

cat << EOF > m${inst}stop.sh
/etc/init.d/mysql stop $inst
EOF

cat << EOF > m${inst}_passwd.txt
$db_admin_pass
EOF

cat << EOF > m${inst}c.sh
$mysql_bin_dir_and_ver/bin/mysql --socket=$main_dir/$inst_wlz/mysql.sock --user=$db_admin_user -p\`cat /usr/local/bin/mysql/m${inst}_passwd.txt\` --prompt="MySQL:$mysql_ver_short Host:\`hostname\` Inst:$inst_wlz Port:$port DB:\d Date:\D\nmysql> " --table --unbuffered --verbose --verbose --verbose --show-warnings --auto-rehash "\$@"
EOF

cat << EOF > m${inst}.sh
$mysql_bin_dir_and_ver/bin/mysql --socket=$main_dir/$inst_wlz/mysql.sock --user=$db_admin_user -p\`cat /usr/local/bin/mysql/m${inst}_passwd.txt\` --prompt="MySQL:$mysql_ver_short Host:\`hostname\` Inst:$inst_wlz Port:$port DB:\d Date:\D\nmysql> " "\$@"
EOF


# Create my.cnf file with myisam settings.
if [[ "$engine" = myisam ]]; then
cat << EOF > my.cnf
[mysqld_safe]
ledir=${mysql_bin_dir_and_ver}/bin

[mysqld]
port=${port}
datadir=$main_dir/${inst_wlz}/data
basedir=$main_dir/${inst_wlz}/bin/..
tmpdir=$main_dir/${inst_wlz}/tmp
socket=$main_dir/${inst_wlz}/mysql.sock
pid-file=$main_dir/${inst_wlz}/${HOSTNAME}_${inst_wlz}.pid
#init-file=$main_dir/${inst_wlz}/init_${inst_wlz}.sql
lower_case_table_names=1
sql_mode=ANSI,TRADITIONAL

max_connections=500
table_open_cache=500
#join_buffer_size=2M
#sort_buffer_size=2M
#read_buffer_size=128K
#read_rnd_buffer_size=256K
#tmp_table_size=1M
max_allowed_packet=16M

### Error log options
log-error=$main_dir/${inst_wlz}/logs/${HOSTNAME}_${inst_wlz}.err
log-warnings=2
### General log options
general_log=OFF
general_log_file=$main_dir/${inst_wlz}/logs/general_query.log
### Slow query log options
slow_query_log=OFF
slow_query_log_file=$main_dir/${inst_wlz}/logs/slow_query.log
#log-queries-not-using-indexes
#log-slow-admin-statements
#log-slow-slave-statements
long_query_time=1
### General and slow query log options
log-output=FILE

########################################
# MyISAM Storage Engine
########################################
default-storage-engine=myisam
ignore-builtin-innodb
key_buffer_size=500M
myisam_sort_buffer_size=2G
#bulk_insert_buffer_size=8M
EOF
fi


# Create my.cnf file with innodb settings.
if [[ "$engine" = innodb ]]; then
cat << EOF > my.cnf
[mysqld_safe]
ledir=${mysql_bin_dir_and_ver}/bin

[mysqld]
port=${port}
datadir=$main_dir/${inst_wlz}/data
basedir=$main_dir/${inst_wlz}/bin/..
tmpdir=$main_dir/${inst_wlz}/tmp
socket=$main_dir/${inst_wlz}/mysql.sock
pid-file=$main_dir/${inst_wlz}/${HOSTNAME}_${inst_wlz}.pid
#init-file=$main_dir/${inst_wlz}/init_${inst_wlz}.sql
lower_case_table_names=1
sql_mode=ANSI,TRADITIONAL

max_connections=100
#table_open_cache=64
#join_buffer_size=2M
#sort_buffer_size=2M
#read_buffer_size=128K
#read_rnd_buffer_size=256K
#tmp_table_size=1M
max_allowed_packet=16M

### Error log options
log-error=$main_dir/${inst_wlz}/logs/${HOSTNAME}_${inst_wlz}.err
log-warnings=2
### General log options
general_log=OFF
general_log_file=$main_dir/${inst_wlz}/logs/general_query.log
### Slow query log options
slow_query_log=OFF
slow_query_log_file=$main_dir/${inst_wlz}/logs/slow_query.log
#log-queries-not-using-indexes
#log-slow-admin-statements
#log-slow-slave-statements
long_query_time=1
### General and slow query log options
log-output=FILE

### Replication options
server-id=1
#read-only
log-bin=$main_dir/${inst_wlz}/binlogs/binlog_${HOSTNAME}_${inst_wlz}
max-binlog-size=100M
log-slave-updates
expire_logs_days=14
relay-log=$main_dir/${inst_wlz}/binlogs/relaylog_${HOSTNAME}_${inst_wlz}
max-relay-log-size=50M
report-host=${HOSTNAME}
report-port=${port}

########################################
# InnoDB Storage Engine
########################################
default-storage-engine=innodb
# Whether InnoDB returns errors rather than warnings for certain conditions. Default is OFF.
innodb_strict_mode=ON
#plugin-load=

### Buffer settings
# Define size of buffer pool used for data and indexes.
innodb_buffer_pool_size=128M
# The number of regions that the InnoDB buffer pool is divided into.
innodb_buffer_pool_instances=1
# Define size of memory pool used to store data dictionary and other internal structures.
innodb_additional_mem_pool_size=8M
# The size in bytes of the buffer that InnoDB uses to write to the log files on disk. The default value is 8MB.
innodb_log_buffer_size=8M
# The main thread in InnoDB tries to write pages from the buffer pool so that the percentage of dirty pages will not exceed this value.
innodb_max_dirty_pages_pct=75

### Tablespace settings
# If disabled (the default), InnoDB creates tables in the system tablespace. If enabled, InnoDB creates each new table in its own tablespace.
innodb_file_per_table=1
# Define single shared system tablespace.
innodb_data_file_path=shared.ibd:10M:autoextend
# Maximum number of .ibd files that InnoDB can keep open at one time. The minimum value is 10. The default value is 300.
innodb_open_files=300
# The increment size (in MB) for extending the size of an auto-extending shared tablespace file when it becomes full. The default value is 8.
innodb_autoextend_increment=8
# The file format to use for new InnoDB tables. Currently, Antelope and Barracuda are supported.
innodb_file_format=Barracuda
# This variable can be set to 1 or 0 at server startup to enable or disable whether InnoDB checks the file format tag in the shared tablespace.
innodb_file_format_check=1
# At server startup, InnoDB sets the value of innodb_file_format_max to the file format tag in the shared tablespace (for example, Antelope or Barracuda).
innodb_file_format_max=Antelope

### Log file settings
# Set log file size and number of log files.
innodb_log_file_size=25M
innodb_log_files_in_group=4

### Threading, concurrency, and locking settings
# The number of threads that can commit at the same time.
# A value of 0 (the default) allows any number of transactions to commit simultaneously.
innodb_commit_concurrency=0
# InnoDB tries to keep the number of operating system threads concurrently inside InnoDB less than or equal to the limit given by this variable.
# A value of 0 (the default) is interpreted as infinite concurrency (no concurrency checking).
innodb_thread_concurrency=0
# If enabled, a transaction timeout causes InnoDB to abort and roll back the entire transaction. By default only the last statement is rolled back.
innodb_rollback_on_timeout=ON
# The timeout in seconds an InnoDB transaction waits for a row lock before giving up. The default value is 50 seconds.
innodb_lock_wait_timeout=50

### Flushing, writing, and syncing
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
# If the value is 0, the log buffer is written out to the log file once per second and the
# flush to disk operation is performed on the log file, but nothing is done at a transaction commit.
# When the value is 1 (the default), the log buffer is written out to the log file at each
# transaction commit and the flush to disk operation is performed on the log file.
innodb_flush_log_at_trx_commit=1
# When the variable is 1 (the default), InnoDB support for two-phase commit in XA transactions
# is enabled, which causes an extra disk flush for transaction preparation. Set to 0 to disable.
# Having innodb_support_xa enabled on a replication master - or on any MySQL server where binary
# logging is in use - ensures that the binary log does not get out of sync compared to the table data.
innodb_support_xa=1
# An upper limit on the I/O activity performed by the InnoDB background tasks, such as flushing pages from the buffer pool and merging data from the insert buffer.
innodb_io_capacity=200
# The number of I/O threads for write operations in InnoDB. The default value is 4.
innodb_write_io_threads=4

### Other
# Controls whether InnoDB creates a file named innodb_status.<pid> in the MySQL data directory.
innodb_status_file=ON
# When this variable is enabled, InnoDB updates statistics during metadata statements such as SHOW TABLE STATUS or SHOW INDEX, or when accessing the INFORMATION_SCHEMA tables TABLES or STATISTICS.
innodb_stats_on_metadata=OFF
# The number of index pages to sample for index distribution statistics such as are calculated by ANALYZE TABLE. The default value is 8.
innodb_stats_sample_pages=8
# Only set this variable greater than 0 in an emergency situation, to dump your tables from a corrupt database.
innodb_force_recovery=0
# If a problem with the asynchronous I/O subsystem in the OS prevents InnoDB from starting, start the server with this variable disabled.
innodb_use_native_aio=1
EOF
fi


chmod 770 m${inst}start.sh m${inst}stop.sh m${inst}c.sh m${inst}.sh
chmod 660 m${inst}_passwd.txt my.cnf

graceful_exit
