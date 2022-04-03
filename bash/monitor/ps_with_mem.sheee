#!/bin/sh
#
# Created: 2015-05-19
# Monitor memory usage and process activity.

delay=$1
count=$2

# Working directory.
workdir=`dirname $0`

path=$workdir/monitor/ps_with_mem

mkdir -p $path

n=0
while true
do
	ts=$(date +'%Y%m%d_%H%M%S')
	echo "Timestamp: $ts" > $path/${ts}.txt
	ps -eo uid,pid,ppid,c,%cpu,%mem,rss,vsz,size,sz,start_time,args >> $path/${ts}.txt
	n=$(( n + 1 ))
	if [[ $n -eq $count ]]; then
		exit
	fi
	sleep $delay
done
