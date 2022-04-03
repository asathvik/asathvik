#!/bin/bash
################################################################################
#
# Purpose:
#	Test whether san mount is readable and writable. Helps with 
#	troubleshooting read-only file system issues which sometimes happen 
#	when SAN path failover occurs.
#
# Usage:
# How to run this script against multiple servers?
#
# Example of running the script against sdlc network only. We would have to run the script in prod and sdlc.
#servers="faclsna01sdba01 faclsna01sdba02"
#for server in $servers; do echo $server:; ssh -q $server /dba_share/scripts/bash/disk/san_read_write_test.sh; echo; done 2>&1 | tee san_read_write_test.sdlc.log
#
# Example of running the script against sdlc and prod networks. Using this script is slower, depending on ldap and ssh performance.
# It also requires testing ahead of time to make sure ssh connections are allowed, since you may get "Are you sure you want to continue connecting (yes/no)?" question.
#servers="faclsna01sdba01 faclsna01sdba02 faclsna01vmdb09 faclsna01vmdb17"
#for server in $servers; do echo $server:; /dba_share/scripts/bash/utils/run_bash_script_anywhere.sh -h $server < /dba_share/scripts/bash/disk/san_read_write_test.sh; echo; done 2>&1 | tee san_read_write_test.log
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Exit code.
exit_code=0


################################################################################
# Program starts here
################################################################################

# Get a list of SAN mounts.
san_mounts=$(egrep 'san|mysql' /etc/fstab | egrep -v '/mysql_bkup|^#' | gawk '{print $2}')

# Display headers.
echo "host san_mount read_write"

for san_mount in $san_mounts; do
	# Try writing to a temporary file.
	(echo "Test" > $san_mount/san_read_write_test.$$.tmp) 2> /dev/null
	
	# Try reading from a temporary file.
	file_content=$(cat $san_mount/san_read_write_test.$$.tmp 2> /dev/null )
	
	# Remove temporary file.
	rm $san_mount/san_read_write_test.$$.tmp 2> /dev/null
	
	if [[ "$file_content" == "Test" ]]; then
		read_write=ok
	else
		read_write=fail
                exit_code=1
	fi
	
	# Display results.
	echo "$HOSTNAME $san_mount $read_write"
done

exit $exit_code
