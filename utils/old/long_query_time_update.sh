#/bin/sh
################################################################################
# Author:
#	Anil Kumar Alpati
#
# Purpose:
#	Change MySQL configuration. The script udpates my.cnf file and global 
#	dynamic variable.
#
# Revisions:
#	2012-11-20 - Anil Kumar Alpati
#	Script created.
################################################################################

if [ $# -ne 1 ];
then
echo 'Please pass the argument for updating long_query_time value';
echo '		Usage: ./scriptname.sh [numericvalue]	';
echo '		Example: ./s.sh 1 		'
exit 1
fi

passphrase="surfb0ard";
#GETINSTANCELIST=`ls /mysql`
GETINSTANCELIST="60 61 70 71"
for INST_LIST in $GETINSTANCELIST

do
        if [ "/mysql/bin" == "/mysql/$INST_LIST" ] || [ "/mysql/mysqlmonagent" == "/mysql/$INST_LIST" ] || [ "/mysql/mysqlmon" == "/mysql/$INST_LIST"  ] || [ "/mysql/memagent" == "/mysql/$INST_LIST" ];
        then
                exit 0
        else

	echo ;
        echo $INST_LIST
	MYFINAL_INSTLIST=$INST_LIST

	for INT_NO in $MYFINAL_INSTLIST
	do 
		CONFIG_FILE=/mysql/$INT_NO/my.cnf			
        	CHECK_CONFIG_FILE=$(cat $CONFIG_FILE | grep '^long_query_time=') 
		if [ -z $CHECK_CONFIG_FILE ];
		then 
			echo "File and long_query param doesn't exists";
			echo "========================================";	
		else
			echo "Config file and long query param exists"
			echo "========================================";	
			CONFIG_TIME_VALUE=$(cat $CONFIG_FILE | grep '^long_query_time=' | awk -F'=' '{print $2}')
			DB_TIME_VALUE=$(mysql -udbauser -p$passphrase --socket=/mysql/$INT_NO/mysql.sock -s --skip-column-names -e "show variables like 'long_query_time'" | awk -F ' ' '{ print $2}');
				echo "OLD : current_db_value=$DB_TIME_VALUE  AND current_config_value:$CONFIG_TIME_VALUE"	
			if [ $CONFIG_TIME_VALUE == 1 ] && [ $DB_TIME_VALUE == 1 ];
			then 
				echo 'Params are up-to-date';
				echo "No change required"
			else 
				echo "Need to update value";
				echo "====================";	
				echo "UPDATING Config and DB params";
				echo $CONFIG_FILE
				echo 'Backup the config file'
				cp -f $CONFIG_FILE /tmp/my_${INT_NO}_bkpup.cnf
				if [ $? == 0 ];
				then
				echo "Copy Done."
				fi
	                        cat $CONFIG_FILE | sed "s/long_query_time=$CONFIG_TIME_VALUE/long_query_time=$1/" > temp.file
				echo 'Moving.....';
				 mv temp.file /mysql/$INT_NO/my.cnf 
                       		DB_UPDATE=$(mysql -udbauser -p$passphrase --socket=/mysql/$INT_NO/mysql.sock -s --skip-column-names -e "set global long_query_time=$1;");
			echo $DB_UPDATE;
			NEW_CONFIG_TIME_VALUE=$(cat $CONFIG_FILE | grep '^long_query_time=' | awk -F'=' '{print $2}')
			NEW_DB_TIME_VALUE=$(mysql -udbauser -p$passphrase --socket=/mysql/$INT_NO/mysql.sock -s --skip-column-names -e "show variables like 'long_query_time'" | awk -F ' ' '{ print $2}');
			echo "NEW : current_db_value=$NEW_DB_TIME_VALUE  AND current_config_value:$NEW_CONFIG_TIME_VALUE"	
			fi
		fi
	done	
      fi
done

