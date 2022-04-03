#  
# Date: 2013-08-29

cd ~/monitor/ps_with_mem

# Show ps output for mysqld processes.
ls | xargs cat | egrep 'Timestamp: |UID |/usr/sbin/mysqld ' | awk '/Timestamp: / {ts=$2} /UID / {print "Timestamp", $0} /mysqld / {print substr(ts,1,4) "-" substr(ts,5,2) "-" substr(ts,7,2) "T" substr(ts,10,2) ":" substr(ts,12,2) ":" substr(ts,14,2), $0}' > ../ps_with_mem_analyze.txt


# Show ps output and take out redundant header lines.
cat ps_with_mem_analyze.txt | awk 'NR == 1; NR > 1 && !/^Timestamp/' | less

# Show ps output filtered by instance 3 (instance with old directory stucture).
cat ps_with_mem_analyze.txt | awk 'NR == 1; NR > 1 && !/^Timestamp/' | egrep 'Timestamp |mysql_data ' | less

# Show ps output with limited columns.
cat ps_with_mem_analyze.txt | awk 'NR == 1; NR > 1 && !/^Timestamp/' | egrep 'Timestamp |mysql_data ' | awk '{print $1, $6, $8, $9, $13, $14}' | less

# Show ps output with comma delimited format.
cat ps_with_mem_analyze.txt | awk 'NR == 1; NR > 1 && !/^Timestamp/' | egrep 'Timestamp |mysql_data ' | awk '{print $1, $6, $8, $9, $14}' | sed 's/ /,/g; 1 s/$/Instance/; 2,/end/ s/T/ /; s|--basedir=/mysql_||' | less
