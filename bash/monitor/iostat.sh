
   
# Created: 2012-10-19

# Monitor disk I/O activity.

delay=$1
count=$2

iostat -x -t $delay $count
