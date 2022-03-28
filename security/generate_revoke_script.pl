#!/usr/bin/perl
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Generate a shell script with revoke commands for MySQL database by querying 
#	mysql_privs table in db_tracking database.
#
# Usage:
#	# Modify query in $qry_get_list_of_privs variable in this script.
#	perl generate_revoke_script.pl
#
# Revisions:
#	07/13/2009 - Dimitriy Alekseyev
#	Script created.
#	07/16/2009 - Dimitriy Alekseyev
#	Modified to support granting table level privileges.
#	07/27/2009 - Dimitriy Alekseyev
#	Added a check to call "create user" section only once per database per 
#	unique user. Improved the selection query to allow filtering by any field 
#	in mysql_privs table and updated all the associated logic in this script.
#	07/28/2009 - Dimitriy Alekseyev
#	Changed tick marks to double quotes for grant statements to fix an issue 
#	shell substitution.
#	08/07/2009 - Dimitriy Alekseyev
#	Made improvements to perl script and the generated bash script.
#	08/14/2009 - Dimitriy Alekseyev
#	Added a section to handle SQL grants with *.* option.
#	08/17/2009 - Dimitriy Alekseyev
#	Fixed issue when creating a password with $ sign in it by escaping it.
#	08/21/2009 - Dimitriy Alekseyev
#	Converted generate_grant_script.pl into revoke script. Current version does 
#	not drop the user if all privileges are revoked.
#	04/27/2010 - Dimitriy Alekseyev
#	Updated location of db_tracking db. Updated get list of privileges query. 
#	Added SQL mode setting.
#	04/27/2010 - Dimitriy Alekseyev
#	Removed operation mode option from the script - this was adding to much 
#	complexity in maintaining two execution paths in different programming 
#	languages, one in bash and one in perl within this script. Separated out
#	where clause variables. Added connection check to see if a connection to 
#	database is possible from server where generated script will run. Added 
#	verification to revoke statement execution - if revoke fails, db_tracking 
#	update statements will not be printed by generated script.
#	09/24/2010 - Dimitriy Alekseyev
#	Added ordering by grant_datetime column to the query.
################################################################################

use strict;
use DBI;
use DBD::mysql;

# Program name.
my $prog_name = $0;

# MySQL connection string to db_tracking database.
my $dsn = 'dbi:mysql:db_tracking:faclsna01slap07:3370';

# Username and password for connecting to db_tracking.
my $dbt_user = 'dbauser';
my $dbt_pass = 'surfb0ard';

# Username and password for executing grants scripts.
my $user = 'dbauser';
my $pass = 'surfb0ard';

# Where clause values for query.
my $host_data_center = '%';
my $host_name = '%';
my $host_ip = '%';
my $db_environment = '%';
my $db_name = '%';
my $username = 'username';
my $schema = '%';

my $qry_get_list_of_privs = "
SELECT
	h.host_name,
	h.host_ip,
	i.port,
	d.db_id,
	d.db_name,
	d.db_environment,
	mp.mysql_privs_id,
	mp.username,
	mp.password,
	mp.access,
	mp.schema,
	mp.tables
FROM
	host AS h
	LEFT JOIN instance AS i ON i.host_id = h.host_id
	LEFT JOIN db AS d ON d.instance_id = i.instance_id
	INNER JOIN mysql_privs AS mp ON d.db_id = mp.db_id
WHERE
	h.host_active_yn = 'y' AND
	i.instance_active_yn = 'y' AND
	d.db_active_yn = 'y' AND
	mp.grant_datetime IS NOT NULL AND
	mp.revoke_datetime IS NULL AND
	i.rdbms = 'mysql' AND
	h.host_data_center like '$host_data_center' AND
	h.host_name like '$host_name' AND
	h.host_ip like '$host_ip' AND
	d.db_environment like '$db_environment' AND
	d.db_name like '$db_name' AND
	mp.username like '$username' AND
	mp.schema like '$schema'
ORDER BY
	h.host_name,
	i.port,
	d.db_name,
	mp.username,
	mp.grant_datetime
";

# Output file for the generated shell script.
my $generated_file = "revoke.sh";

# Connection timeout setting in seconds.
my $timeout = 5;

# Initialize variables.
my $last_db_id = '';


################################################################################
# Program starts here
################################################################################

my $dbh = DBI->connect($dsn, $dbt_user, $dbt_pass)
 or die "Can't connect to the DB: $DBI::errstr\n";

my $sth1 = $dbh->prepare($qry_get_list_of_privs)
 or die "Couldn't prepare statement: " . $dbh->errstr;
$sth1->execute() or die;

open FILE, ">$generated_file" or die "Unable to open $generated_file $!";
print FILE <<BASH_BEGIN_END;
#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Revoke privileges from MySQL databases.
#
# Usage:
#	# To revoke privileges:
#	date=\$(date +'%F %T %Z'); file_date=\$(date -d "\$date" +'%Y%m%d_%H%M%S'); ./$generated_file &> /dba_share/scripts/mysql/security/logs/\${file_date}_mysql_revoke_privs.log "\$date"
#
#	# To review log:
#	less /dba_share/scripts/mysql/security/logs/\${file_date}_mysql_revoke_privs.log
#
#	# To extract db_tracking queries:
#	grep 'db_tracking query:' /dba_share/scripts/mysql/security/logs/\${file_date}_mysql_revoke_privs.log | gawk -F'db_tracking query: ' '{print \$2}'
#
# Revisions:
#	This script was auto generated by $prog_name on .
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Date in `date +'%F %T %Z'` format.
date_ftz=\$1

# Date in `date +'%F %T` format.
date_ft=\$(date -d "\$date_ftz" +'%F %T')


################################################################################
# Program starts here
################################################################################

# Check number of parameters.
if [[ \$# -ne 1 ]]; then
	echo "Error: Incorrect number of parameters."
	echo
	exit 1
fi

echo "************************************************************"
echo "* MySQL Revoke Script"
echo "* Time started: \$date_ftz"
echo "************************************************************"
echo
BASH_BEGIN_END

	while (my $tblhr1 = $sth1->fetchrow_hashref()) {

		# Check if db_id is encountered first time.
		if ($last_db_id ne $tblhr1->{'db_id'}) {
			if ($last_db_id ne '') {
				# Print database end section.
				print FILE <<BASH_BEGIN_END;
fi
echo "************************************************************"
echo
BASH_BEGIN_END
			}
			# Print database begin section.
			print FILE <<BASH_BEGIN_END;
echo "************************************************************"
echo "Host name: $tblhr1->{'host_name'}"
echo "IP: $tblhr1->{'host_ip'}"
echo "Port: $tblhr1->{'port'}"
echo "Database: $tblhr1->{'db_name'}"
echo "Environment: $tblhr1->{'db_environment'}"

# Test connection to database.
connect="OK"
mysql --host=$tblhr1->{'host_ip'} --port=$tblhr1->{'port'} --user=$user --password=$pass --unbuffered --skip-column-names --connect_timeout=$timeout --execute='SELECT 1;' > /dev/null || connect="FAILED"

if [[ \$connect == "OK" ]]; then
BASH_BEGIN_END
		}

		# Check if revoking global, database, or table level privilege.
		my $dbname_tblname;
		if ($tblhr1->{'schema'} eq '*') {	# *.* menas global privileges.
			$dbname_tblname = qq^$tblhr1->{'schema'}.$tblhr1->{'tables'}^;
		} elsif ($tblhr1->{'tables'} eq '*') {	# 'dbname.*' means databse level privileges.
			my $schema_mysql_escaped = $tblhr1->{'schema'};
			# Change '_' to '\_'.
			$schema_mysql_escaped =~ s/_/\\_/g;
			$dbname_tblname = qq^"$schema_mysql_escaped".$tblhr1->{'tables'}^;
		} else {	# 'dbname.tablename' means table level privileges.
			$dbname_tblname = qq^"$tblhr1->{'schema'}"."$tblhr1->{'tables'}"^;
		}
		print FILE <<BASH_BEGIN_END;
	revoke="OK"
	cat << SQL_BEGIN_END | mysql --host=$tblhr1->{'host_ip'} --port=$tblhr1->{'port'} --user=$user --password=$pass --table -vv -n || revoke="FAILED"
SET sql_mode = 'ANSI,TRADITIONAL';
REVOKE $tblhr1->{'access'} ON $dbname_tblname FROM '$tblhr1->{'username'}'\@'%';
SQL_BEGIN_END
	if [[ \$revoke == "OK" ]]; then
		echo "db_tracking query: -- host_name: $tblhr1->{'host_name'}; port: $tblhr1->{'port'}; db_name: $tblhr1->{'db_name'}; db_environment: $tblhr1->{'db_environment'}; username: $tblhr1->{'username'}"
		echo "db_tracking query: UPDATE mysql_privs AS mp SET mp.revoke_datetime='\$date_ft' WHERE mp.mysql_privs_id=$tblhr1->{'mysql_privs_id'};"
	fi
BASH_BEGIN_END

		$last_db_id = $tblhr1->{'db_id'};
	}

	# Print final end section.
	print FILE <<BASH_BEGIN_END;
fi
echo "************************************************************"
echo
echo "************************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "************************************************************"
BASH_BEGIN_END

close FILE;

$dbh->disconnect;
