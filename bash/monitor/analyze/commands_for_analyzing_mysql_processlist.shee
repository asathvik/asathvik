#  
# Date: 2013-08-20

# Commands for analyzing MySQL processlist logs.
# Copy and paste commands into bash shell to run them.


cd ~/monitor/mysql_processlist

# Show list of connections and total number of connections while excluding sleeping and "show full processlist" connections.
ls | xargs cat | awk '{if($1 == "***************************") {row=$2; sub(/\./, "", row); print "--DIVIDER--"} else if($0 ~ row" rows in set") {print "--DIVIDER--"; print "Connections: " row; print "--DIVIDER--"} else print $0}' | awk '{if($1=="inst_script:") {inst_script=$2; sub(/\/usr\/local\/bin\/mysql\/m/, "", inst_script); sub(/c.sh/, "", inst_script)} if($1=="Timestamp:") timestamp=$0} !/^inst_script:|^Timestamp:/ {if($1=="Id:" || $1=="Connections:") {print "Instance: " inst_script; print timestamp; print $0;} else print $0}' | awk 'BEGIN {RS="--DIVIDER--"; FS="\n"; ORS="--DIVIDER--"} /Instance: / {print $0}' | awk 'BEGIN {RS="--DIVIDER--"; FS="\n"; ORS="--DIVIDER--"} !/Command: Sleep/ {print $0}' | awk 'BEGIN {RS="--DIVIDER--"; FS="\n"; ORS="--DIVIDER--"} !/Info: SHOW FULL PROCESSLIST/ {print $0}' | grep -v '^$' > mysql_processlist_analyze.txt


# Show list of connections while excluding sleeping and "show full processlist" connections.
cat mysql_processlist_analyze.txt | awk 'BEGIN {RS="--DIVIDER--"; FS="\n"; ORS=""} !/Connections: / {print $0}' | sed '1{/^$/d}' | less

# Show list of connections while excluding sleeping and "show full processlist" connections. Filter by instance.
cat mysql_processlist_analyze.txt | awk 'BEGIN {RS="--DIVIDER--"; FS="\n"; ORS="--DIVIDER--"} !/Connections: / {print $0}' | awk 'BEGIN {RS="--DIVIDER--"; FS="\n"; ORS=""} /Instance: 3/ {print $0}' | sed '1{/^$/d}' | less

# Show list of connections and take out newlines from queries.
cat mysql_processlist_analyze.txt | awk 'BEGIN {RS="--DIVIDER--"; FS="\n"; ORS="--DIVIDER--"} !/Connections: / {print $0}' | awk '/Instance: /,/State: / {ORS="\n"; print $0} /Info: /,/--DIVIDER--/ {ORS=""; OFS="\n"; print $0}' | sed 's/--DIVIDER--/\n\n/' | less

# Show total number of connections.
cat mysql_processlist_analyze.txt | awk 'BEGIN {RS="--DIVIDER--"; FS="\n"; ORS=""} !/Command: / {print $0}' | less

# Show total number of connections in table format.
cat mysql_processlist_analyze.txt | awk 'BEGIN {RS="--DIVIDER--"; FS="\n"; ORS=""} !/Command: / {print $0}' | awk -f t.awk | less

# Show total number of connections in table format excluding instance 1.
cat mysql_processlist_analyze.txt | awk 'BEGIN {RS="--DIVIDER--"; FS="\n"; ORS=""} !/Command: / {print $0}' | awk -f t.awk | grep -v '^1' | less
