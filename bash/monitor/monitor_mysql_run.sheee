   
# Created: 2012-10-17

# Run various monitoring scripts on MySQL database server.
# Sample usage:
# mysql@faclsna01sldb09:~/monitor> /dba_share/scripts/bash/monitor/monitor_mysql.sh

path=~/monitor/

mkdir -p $path

nohup /dba_share/scripts/bash/monitor/vmstat_with_ts.sh 60 4320 &> $path/vmstat_with_ts.txt &
nohup /dba_share/scripts/bash/monitor/iostat.sh 60 4320 &> $path/iostat.txt &
nohup /dba_share/scripts/bash/monitor/ps_with_mem.sh 60 4320 &> $path/ps_with_mem.log &
nohup /dba_share/scripts/bash/monitor/mysql_processlist.sh 60 4320 &> $path/mysql_processlist.log &
nohup /dba_share/scripts/bash/monitor/lsof_mysql.sh 60 4320 &> $path/lsof_mysql.log &
