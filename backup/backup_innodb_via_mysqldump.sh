# Dimitriy Alekseyev
# Created: 2013-03-28

# Draft
# Script for creating mysqldump backup with gzip.

(mysqldump --socket=/mysql/05/mysql.sock --user=dbauser --password=`cat /usr/local/bin/mysql/m5_passwd.txt` --no-data --single-transaction --flush-logs --master-data=2 --all-databases --extended-insert --quick --routines 2>&4 | gzip > orders_schema_dump.sql.gz) > orders_schema_dump.err 4>&1 2>&1

(mysqldump --socket=/mysql/05/mysql.sock --user=dbauser --password=`cat /usr/local/bin/mysql/m5_passwd.txt` --single-transaction --flush-logs --master-data=2 --all-databases --extended-insert --quick --routines 2>&4 | gzip > orders_dump.sql.gz) > orders_dump.err 4>&1 2>&1

The Task: Come up with an approach for transferring data from one table with more than a million rows, to another table - both tables are on different machines. Your approach must take into account performance, tuning and other considerations. The method should have logging, restart, failure-recognition and exception handling mechanisms.

Looking forward in hearing from you.



I'm considering following are my server configurations -

RAM: 120 GigsArchitecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Architecture:          x86_64
No. of cores : 24

Following options can used -

Considering InnoDB TABLE


Method 1:Via mysqldump

Dump
- only schema
(mysqldump --socket=mysql.sock --user=user --password=password --no-data --single-transaction --flush-logs --master-data=2 --extended-insert --quick --routines dbname tablename 2>&4 | gzip > schema_dump.sql.gz) > schema_dump.err 4>&1 2>&1

- only data
(mysqldump --socket=mysql.sock --user=user --password=password --no-create-info --single-transaction --flush-logs --master-data=2 --extended-insert --quick --routines dbname tablename 2>&4 | gzip > data_dump.sql.gz) > data_dump.err 4>&1 2>&1

copy the dump files to destination via scp or winscp

Or 

Direct restore via network 

mysqldump --socket=mysql.sock --user=user --password=password --no-data --single-transaction --flush-logs --master-data=2 --extended-insert --quick --routines --databases dbname tablename | mysql --host=remotehost  --port=port# --user=user --password=password dbname 

mysqldump --socket=mysql.sock --user=user --password=password --no-create-info --single-transaction --flush-logs --master-data=2 --extended-insert --quick --routines dbname tablename | mysql --host=remotehost  --port=port# --user=user --password=password dbname 


Performance boosting and tuning parameters

-max_allowed_packet=265
-net_read_timeout=90 (defualt 30)
-net_write_timeout=120 (default 60)
-wait_timeout=28800 (This is default value - 8 hrs, it should be sufficient if table size is < 20Gigs


Method 2:Via LOAD DATA 
(Before table schema should be created on destination DB)
Export : SELECT INTO OUTFILE 
INFILE : LOAD DATA INFILE


Performance boosting and tuning parameters
-tmpdir=25G (make sure tmp location has sufficient space)
-wait_timeout=28800 (This is default value - 8 hrs, it should be sufficient if table size is < 20Gigs
-lock_wait_timeout=120
-Disable foriegn key constraint keys 
foreign_key_checks=OFF;


Method 3:

Via Percona Xtrabackup or Partial Backup
 
