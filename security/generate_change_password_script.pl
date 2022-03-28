#!/usr/bin/perl
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Generate a shell script with change password commands for MySQL 
#	database by querying mysql_privs table in db_tracking database.
#
# Usage:
#	# Modify query in $qry_get_list_of_privs variable in this script.
#	perl generate_change_password_script.pl
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
#	09/10/2009 - Dimitriy Alekseyev
#	Added set sql mode to 'ANSI,TRADITIONAL' so that same syntax would work 
#	across servers with different sql modes.
#	09/24/2009 - Dimitriy Alekseyev
#	Added connect_timeout option to mysql client so that connection does not 
#	hang endlessly when server is not reachable. Added a check to see if 
#	connection has failed.
#	09/24/2009 - Dimitriy Alekseyev
#	Added a check to see if grant has failed. When grant fails, we are not 
#	outputting db_tracking update queries.
#	10/05/2010 - Dimitriy Alekseyev
#	Converted this script from generating grant privileges script to 
#	generating a change password script.
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

# Username and password for connecting to MySQL databases.
my $user = 'dbauser';
my $pass = 'surfb0ard';

# Username for which the password is to be changed.
my $change_pw_user = 'bschroed';

# New password that we will be changing to for the selected user.
my $change_pw_pass = 'tbye4482';

# Where clause values for query.
my $host_data_center = 'satc';
my $host_name = '%';
my $host_ip = '%';
my $db_environment = 'fmrnd';
my $db_name = "'firstam', 'homedata', 'miscdata', 'cl'";

my $qry_get_list_of_dbids = "
SELECT
	h.host_name,
	h.host_ip,
	i.port,
	d.db_id,
	d.db_name,
	d.db_environment
FROM
	host AS h
	LEFT JOIN instance AS i ON i.host_id = h.host_id
	LEFT JOIN db AS d ON d.instance_id = i.instance_id
WHERE
	h.host_active_yn = 'y' AND
	i.instance_active_yn = 'y' AND
	d.db_active_yn = 'y' AND
	i.rdbms = 'mysql' AND
	h.host_data_center like '$host_data_center' AND
	h.host_name like '$host_name' AND
	h.host_ip like '$host_ip' AND
	d.db_environment like '$db_environment' AND
	d.db_name IN ($db_name)
GROUP BY
	d.db_id
ORDER BY
	h.host_name,
	i.port,
	d.db_name
";

# Output file for the generated shell script.
my $generated_file = "change_password.sh";

# Connection timeout setting in seconds.
my $timeout = 5;


################################################################################
# Program starts here
################################################################################

my $dbh = DBI->connect($dsn, $dbt_user, $dbt_pass)
 or die "Can't connect to the DB: $DBI::errstr\n";

my $sth1 = $dbh->prepare($qry_get_list_of_dbids)
 or die "Couldn't prepare statement: " . $dbh->errstr;
$sth1->execute() or die;

if (true) {
	open FILE, ">$generated_file" or die "Unable to open $generated_file $!";
	print FILE <<BASH_BEGIN_END;
#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Change password for a MySQL database user.
#
# Usage:
#	# To change password:
#	date=\$(date +'%F %T %Z'); file_date=\$(date -d "\$date" +'%Y%m%d_%H%M%S'); ./$generated_file &> /dba_share/scripts/mysql/security/logs/\${file_date}_mysql_change_password.log "\$date"
#
#	# To review log:
#	less /dba_share/scripts/mysql/security/logs/\${file_date}_mysql_change_password.log
#
#	# To extract information on where the password change was successful:
#	grep 'password changed:' /dba_share/scripts/mysql/security/logs/\${file_date}_mysql_change_password.log | gawk -F'password changed: ' '{print \$2}'
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
echo "* MySQL Change Password Script"
echo "* Time started: \$date_ftz"
echo "************************************************************"
echo
BASH_BEGIN_END

	while (my $tblhr1 = $sth1->fetchrow_hashref()) {

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

		my $change_pw_pass_escaped = $change_pw_pass;
		# Change '$' to '\$'.
		$change_pw_pass_escaped =~ s/\$/\\\$/g;

		print FILE <<BASH_BEGIN_END;
	change_pw="OK"
	cat << SQL_BEGIN_END | mysql --host=$tblhr1->{'host_ip'} --port=$tblhr1->{'port'} --user=$user --password=$pass --table -vv -n || change_pw="FAILED"
SET PASSWORD FOR '$change_pw_user'\@'%' = PASSWORD('$change_pw_pass_escaped');
SQL_BEGIN_END
	if [[ \$change_pw == "OK" ]]; then
		echo "password changed: host_name: $tblhr1->{'host_name'}; port: $tblhr1->{'port'}; db_name: $tblhr1->{'db_name'}; db_environment: $tblhr1->{'db_environment'}; username: $change_pw_user"
	fi
BASH_BEGIN_END

		# Print database end section.
		print FILE <<BASH_BEGIN_END;
fi
echo "************************************************************"
echo
BASH_BEGIN_END
	}

	print FILE <<BASH_BEGIN_END;
echo "************************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "************************************************************"
BASH_BEGIN_END

	close FILE;
}

$dbh->disconnect;
