   
# Created: 2012-10-17

# Display MySQL processlist for each instance.

delay=$1
count=$2
path=~/monitor/mysql_processlist

mkdir -p $path

n=0
while true
do
	ts=$(date +'%Y%m%d_%H%M%S')
	
	for inst_script in $(ls /usr/local/bin/mysql/m*c.sh)
	do
		echo "inst_script: $inst_script" >> $path/${ts}.txt
		echo "Timestamp: $(date +'%Y-%m-%d %H:%M:%S')" >> $path/${ts}.txt
		echo "SHOW FULL PROCESSLIST\G" | $inst_script >> $path/${ts}.txt
		echo >> $path/${ts}.txt
	done
	
	n=$(( n + 1 ))
	if [[ $n -eq $count ]]; then
		exit
	fi
	sleep $delay
done
