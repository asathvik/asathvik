#!/bin/sh

#
# Created: 2015-05-19

# Monitor open file activity for commands beginning with "mysql" string.

delay=$1
count=$2
path=~/monitor/lsof_mysql

mkdir -p $path

n=0
while true
do
	ts=$(date +'%Y%m%d_%H%M%S')
	echo "Timestamp: $ts" > $path/${ts}.txt
	lsof -c mysql >> $path/${ts}.txt
	n=$(( n + 1 ))
	if [[ $n -eq $count ]]; then
		exit
	fi
	sleep $delay
done
