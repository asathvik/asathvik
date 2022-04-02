#!/bin/bash
################################################################################
# Author:
#	Anil
#
################################################################################
# Constants and Global Variables
################################################################################

# Exit code.
exit_code=0


################################################################################
# Program starts here
################################################################################
# Get a list of SAN mounts.
san_mounts=$( egrep 'mysql|log' /etc/fstab | gawk '{print $2}')


echo 'host                        san_mount        read_write'

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
	fi
        exit_code=1
	#Display results.
	echo "$HOSTNAME $san_mount $read_write"
done

exit $exit_code

