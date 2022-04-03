#!/bin/bash
################################################################################
# Purpose:
#	Test disk read/write/copy performance.
#
# Usage:
#	Make sure you have disk space to hold two copies of the specified file 
#	size. Run script and pass the configuration file name to it.
#
# Example:
#	cd /san01/disk_perf_test
#
#	# Copy over and edit configuration file as needed.
#	cp -p /dba_share/scripts/bash/disk/disk_perf_test.cfg .
#	vi disk_perf_test.cfg
#
#	# If you want to track disk I/O metrics.
#	nohup iostat -x -t 60 120 > $(hostname).iostat.$(date '+%Y%m%d'_%H%M%S).log &
#	or
#	nohup iostat -D -R -T -l 60 120 > `hostname`.iostat.$(date '+%Y%m%d'_%H%M%S).txt &
#
#	nohup /dba_share/scripts/bash/disk/disk_perf_test.sh disk_perf_test.cfg > disk_perf_test.$(date '+%Y%m%d'_%H%M%S).err &
#
# Revisions:
#	2012-12-06 -  
#	Script created.
#	2012-12-12 -  
#	Added copy file test.
#	2012-12-13 -  
#	Added read and remove file tests.
#	2012-12-19 -  
#	Added duration information.
#	2012-12-26 -  
#	Fixed precision of duration output. Added random write test.
#	2012-12-26 -  
#	Cleaned up the script. Added random read test.
#	2012-12-28 -  
#	Cleaned up the script. Removed scale option when calculating ts_diff, 
#	so that we do not get division by zero error when calculating speed.
#	2013-06-19 -  
#	Revised script to use functions for clarity.
#	Revised script to use configuration file.
#	Revised script to support parallel tests on multiple file systems.
#
# Todo:
#	Some options like iflag/oflag or conv=fsync, do not work in dd version 
#	5.2.1. Find the vesion which supports this options and run with this 
#	options when newer version is available on the system.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

PROGNAME=$(basename $0)

# Fadvise path.
fadvise=/dba_share/scripts/linux/page_cache_utilities/pcu-fadvise

# Seed random number generator from PID of script.
RANDOM=$$

# Configuration file to use.
config_file=$1


################################################################################
# Functions
################################################################################

function clean_up {
	# Function to remove temporary files and other housekeeping
	# No arguments
	rm -f ${temp_file}
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

function test_sequential_write {
	echo "test: sequential write"
	echo "timestamp: $(date +'%Y-%m-%d %H:%M:%S')"
	echo "test_directory: ${test_directory[$count]}"
	echo "file_size: ${file_size[$count]}"
	echo "block_size: ${block_size[$count]}"
	ts_start=$(date '+%s.%N')
	dd if=/dev/zero of=${test_filename1[$count]} bs=${block_size[$count]} count=${block_count[$count]} >& /dev/null
	sync
	ts_end=$(date '+%s.%N')
	ts_diff=$(echo "$ts_end - $ts_start" | bc)
	MBps=$(echo "scale=2; ${file_size[$count]} / $ts_diff / 1024 / 1024" | bc)
	echo "duration_sec: $ts_diff"
	$fadvise -a dontneed ${test_filename1[$count]}
	echo "speed_MBps: $MBps"
	echo
}

function test_sequential_read {
	echo "test: sequential read"
	echo "timestamp: $(date +'%Y-%m-%d %H:%M:%S')"
	echo "test_directory: ${test_directory[$count]}"
	echo "file_size: ${file_size[$count]}"
	echo "block_size: ${block_size[$count]}"
	ts_start=$(date '+%s.%N')
	dd if=${test_filename1[$count]} of=/dev/null bs=${block_size[$count]} >& /dev/null
	ts_end=$(date '+%s.%N')
	ts_diff=$(echo "$ts_end - $ts_start" | bc)
	MBps=$(echo "scale=2; ${file_size[$count]} / $ts_diff / 1024 / 1024" | bc)
	echo "duration_sec: $ts_diff"
	$fadvise -a dontneed ${test_filename1[$count]}
	echo "speed_MBps: $MBps"
	echo
}

function test_random_write {
	echo "test: random write"
	echo "timestamp: $(date +'%Y-%m-%d %H:%M:%S')"
	echo "test_directory: ${test_directory[$count]}"
	echo "file_size: ${file_size[$count]}"
	echo "block_size: ${block_size[$count]}"
	# Number of random writes to do.
	random_writes=$(( ${file_size[$count]} / ${block_size[$count]} / 100 ))
	# Have at least 10 random writes.
	(( random_writes = random_writes < 10 ? 10 : random_writes ))
	# Limit the number of random writes, since $RANDOM's range is between 0 and 32767.
	if [[ $random_writes -gt 32767 ]]; then random_writes=32767; fi
	echo "random_writes: $random_writes"
	ts_start=$(date '+%s.%N')
	for (( i=1; i <= $random_writes; i++ ))
	do
		seek=$(( RANDOM % (${file_size[$count]} / ${block_size[$count]}) ))
		dd if=/dev/zero of=${test_filename1[$count]} bs=${block_size[$count]} count=1 seek=$seek conv=notrunc >& /dev/null
	done
	sync
	ts_end=$(date '+%s.%N')
	ts_diff=$(echo "$ts_end - $ts_start" | bc)
	MBps=$(echo "scale=2; ${block_size[$count]} * $random_writes / $ts_diff / 1024 / 1024" | bc)
	echo "duration_sec: $ts_diff"
	$fadvise -a dontneed ${test_filename1[$count]}
	echo "speed_MBps: $MBps"
	echo
}

function test_random_read {
	echo "test: random read"
	echo "timestamp: $(date +'%Y-%m-%d %H:%M:%S')"
	echo "test_directory: ${test_directory[$count]}"
	echo "file_size: ${file_size[$count]}"
	echo "block_size: ${block_size[$count]}"
	# Number of random reads to do.
	random_reads=$(( ${file_size[$count]} / ${block_size[$count]} / 10 ))
	# Have at least 10 random reads.
	(( random_reads = random_reads < 10 ? 10 : random_reads ))
	# Limit the number of random reads, since $RANDOM's range is between 0 and 32767.
	if [[ $random_reads -gt 32767 ]]; then random_reads=32767; fi
	echo "random_reads: $random_reads"
	ts_start=$(date '+%s.%N')
	for (( i=1; i <= $random_reads; i++ ))
	do
		skip=$(( RANDOM % (${file_size[$count]} / ${block_size[$count]}) ))
		dd if=${test_filename1[$count]} of=/dev/null bs=${block_size[$count]} count=1 skip=$skip >& /dev/null
	done
	ts_end=$(date '+%s.%N')
	ts_diff=$(echo "$ts_end - $ts_start" | bc)
	MBps=$(echo "scale=2; ${block_size[$count]} * $random_reads / $ts_diff / 1024 / 1024" | bc)
	echo "duration_sec: $ts_diff"
	$fadvise -a dontneed ${test_filename1[$count]}
	echo "speed_MBps: $MBps"
	echo
}

function test_copy_file {
	echo "test: copy file"
	echo "timestamp: $(date +'%Y-%m-%d %H:%M:%S')"
	echo "test_directory: ${test_directory[$count]}"
	echo "file_size: ${file_size[$count]}"
	ts_start=$(date '+%s.%N')
	cp -p ${test_filename1[$count]} ${test_filename2[$count]}
	sync
	ts_end=$(date '+%s.%N')
	ts_diff=$(echo "$ts_end - $ts_start" | bc)
	MBps=$(echo "scale=2; ${file_size[$count]} / $ts_diff / 1024 / 1024" | bc)
	echo "duration_sec: $ts_diff"
	$fadvise -a dontneed ${test_filename1[$count]}
	echo "speed_MBps: $MBps"
	echo
}

function test_delete_file_1 {
	echo "test: delete file 1"
	echo "timestamp: $(date +'%Y-%m-%d %H:%M:%S')"
	echo "test_directory: ${test_directory[$count]}"
	echo "file_size: ${file_size[$count]}"
	ts_start=$(date '+%s.%N')
	rm ${test_filename1[$count]}
	sync
	ts_end=$(date '+%s.%N')
	ts_diff=$(echo "$ts_end - $ts_start" | bc)
	MBps=$(echo "scale=2; ${file_size[$count]} / $ts_diff / 1024 / 1024" | bc)
	echo "duration_sec: $ts_diff"
	echo "speed_MBps: $MBps"
	echo
}

function test_delete_file_2 {
	echo "test: delete file 2"
	echo "timestamp: $(date +'%Y-%m-%d %H:%M:%S')"
	echo "test_directory: ${test_directory[$count]}"
	echo "file_size: ${file_size[$count]}"
	ts_start=$(date '+%s.%N')
	rm ${test_filename2[$count]}
	sync
	ts_end=$(date '+%s.%N')
	ts_diff=$(echo "$ts_end - $ts_start" | bc)
	MBps=$(echo "scale=2; ${file_size[$count]} / $ts_diff / 1024 / 1024" | bc)
	echo "duration_sec: $ts_diff"
	echo "speed_MBps: $MBps"
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit
trap term_exit TERM HUP
trap int_exit INT

# Check if configuration file is readable.
if [[ ! -r $config_file ]]; then
	error_exit "Error on line $LINENO. Cannot read from configuration file."
fi

# Count how many test directories we have.
test_dir_count=$(grep '^test_directory=' $config_file | wc -l)

# Read configuration file.
log_file_date=$(date '+%Y%m%d'_%H%M%S)
count=0
while [[ $count -lt $test_dir_count ]]; do
	line_nbr=$((count + 1))
	
	test_directory[$count]=$(grep '^test_directory=' $config_file | sed -n ${line_nbr}p | awk -F'=' '{print $2}')
	file_size[$count]=$(echo "$(grep '^file_size=' $config_file | sed -n ${line_nbr}p | awk -F'=' '{print $2}')" | bc)
	block_size[$count]=$(echo "$(grep '^block_size=' $config_file | sed -n ${line_nbr}p | awk -F'=' '{print $2}')" | bc)
	block_count[$count]=$(echo "${file_size[$count]} / ${block_size[$count]}" | bc)
	file_size[$count]=$(echo "${block_size[$count]} * ${block_count[$count]}" | bc)
	test_filename1[$count]=${test_directory[$count]}/disk_perf_test.fs_${file_size[$count]}.bs_${block_size[$count]}.pid_$$.seq_${line_nbr}.tmp
	test_filename2[$count]=${test_directory[$count]}/disk_perf_test.fs_${file_size[$count]}.bs_${block_size[$count]}.pid_$$.seq_${line_nbr}.copy.tmp
	log_file[$count]=${test_directory[$count]}/disk_perf_test.$log_file_date.seq_${line_nbr}.log
	
	count=$((count + 1))
done

# Run tests.
tests="test_sequential_write test_sequential_read test_random_write test_random_read test_copy_file test_delete_file_1 test_delete_file_2"
for test in $tests; do
	count=0
	while [[ $count -lt $test_dir_count ]]; do
		$test >> ${log_file[$count]} &
		count=$((count + 1))
	done
	wait
done

graceful_exit
