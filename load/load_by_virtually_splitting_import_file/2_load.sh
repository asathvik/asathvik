#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Load a file into MySQL by using a virtual split file.
#
# Usage:
#	Manually update the script and run it after 1_mk_fifo.sh is running in 
#	the background. Disable unique key checks and foreign key checks only 
#	if you know what you are doing. Performance should be faster if those 
#	checks are disabled.
#
# Revisions:
#	2012-09-21 - Dimitriy Alekseyev
#	Script created.
#	2012-10-04 - Dimitriy Alekseyev
#	Added extra loop to catch situations where the script finishes early 
#	before processing the full file.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# Virtual split file.
virtual_split_file=/mysql/03/tmp/load/gr_res_recorder.fifo

# Target database name.
database=realcore
# Target table name.
table=gr_res_recorder


################################################################################
# Program starts here
################################################################################

while [ -e "$virtual_split_file" ]
do

	while [ -e "$virtual_split_file" ]
	do

		echo "
SELECT NOW() AS START;

SET UNIQUE_CHECKS=0;
SET FOREIGN_KEY_CHECKS=0;

LOAD DATA INFILE '$virtual_split_file' INTO TABLE $table;

SHOW COUNT(*) ERRORS;
SHOW ERRORS;
SHOW COUNT(*) WARNINGS;
SHOW WARNINGS;

SET UNIQUE_CHECKS=1;
SET FOREIGN_KEY_CHECKS=1;
SELECT NOW() AS STOP;
" | m3.sh --table --unbuffered --verbose --verbose --verbose --show-warnings --skip-auto-rehash -D $database || exit 1

	done

	# Debugging steps to see what causes the script to finish early.
	for seconds in 1 2 5 10 30 60 120
	do
		echo "sleep $seconds seconds..."
		sleep $seconds
		test -e $virtual_split_file || echo "Virtual split file is not present."
	done

done
