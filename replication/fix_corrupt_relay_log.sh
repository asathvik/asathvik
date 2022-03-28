# Dimitriy Alekseyev
# 2013-06-03

inst=1
inst_wlz=01

show_slave_status=$(echo "SHOW SLAVE STATUS\G" | m${inst}c.sh | egrep 'Master_Host:|Master_User:|Master_Port:|Relay_Master_Log_File:|Exec_Master_Log_Pos:')
master_password=$(sed -n '6p' /mysql/${inst_wlz}/data/master.info)

# echo "$show_slave_status"
# echo $master_password
# echo

master_host=$(echo "$show_slave_status" | grep 'Master_Host:' | awk -F': ' '{print $2}')
master_port=$(echo "$show_slave_status" | grep 'Master_Port:' | awk -F': ' '{print $2}')
master_user=$(echo "$show_slave_status" | grep 'Master_User:' | awk -F': ' '{print $2}')
master_log_file=$(echo "$show_slave_status" | grep 'Relay_Master_Log_File:' | awk -F': ' '{print $2}')
master_log_pos=$(echo "$show_slave_status" | grep 'Exec_Master_Log_Pos:' | awk -F': ' '{print $2}')

echo "SHOW SLAVE STATUS\G"
echo "STOP SLAVE;"
echo "CHANGE MASTER TO"
echo "MASTER_HOST='$master_host',"
echo "MASTER_PORT=$master_port,"
echo "MASTER_USER='$master_user',"
echo "MASTER_PASSWORD='$master_password',"
echo "MASTER_LOG_FILE='$master_log_file',"
echo "MASTER_LOG_POS=$master_log_pos;"
echo "START SLAVE;"
echo "SHOW SLAVE STATUS\G"
