#!/bin/bash
################################################################################
 
#       Jeffrey Benner
#
# Purpose:
#       Developed for the safe movement of large numbers of files
#       from Tier 2 NAS to Tier 3 NAS. Incorporates validation and
#       safe removal of source files when validation is complete.

#       This script when executed will copy files from source to
#       target using rsync, which internally validates the copy by checksum.
#       Using rsync there is no need for subsequent checksum validation.
#       This script will not delete files on the source directory. You 
#       will want to do this yourself after validating this script has successfully
#       completed.
#
#       You may need to run this as root to prevent permission conflicts.
#
#       This script will generate 2 files:
#        - move_directory_safely.<timestamp>.log
#        - move_directory_safely.<timestamp>.err
#
# Usage:
#       archive_directory.sh <source directory> <target directory>
# Example:
#       archive_directory.sh /db2_bkup/archive /tier3_sac_nas
# 
# Revisions:
#       2013.05.16 - Jeffrey Benner
#       Script created.


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# Temporary files.
tmp1=/tmp/$progname.$$.tmp1
# if more than one tmp, this should be a space delimited string
tmp_file="$tmp1" 

# timestamp string
TS=`date +'%Y%m%d%H%M%S'`

logfile=./archive_directory.$TS.log
errfile=./archive_directory.$TS.err

################################################################################
# Functions
################################################################################

function clean_up {
        # Function to remove temporary files and other housekeeping
        # No arguments
        rm -f ${tmp_file}
}

function graceful_exit {
        # Function called for a graceful exit
        # No arguments
        clean_up
        exit
}

function error_exit {
        # Function for exit due to fatal program error
        # Accepts 1 argument
        #       string containing descriptive error message
        echo "`date +'%Y%m%d-%H:%M:%S: '`${progname}: ${1:-"Unknown Error"}" 
        clean_up
        exit 1
}

function term_exit {
        # Function to perform exit if termination signal is trapped
        # No arguments
        echo "`date +'%Y%m%d-%H:%M:%S: '`${progname}: Terminated"
        clean_up
        exit
}

function int_exit {
        # Function to perform exit if interrupt signal is trapped
        # No arguments
        echo "`date +'%Y%m%d-%H:%M:%S: '`${progname}: Aborted by user"
        clean_up
        exit
}

################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT

if [ $# -ne 2 ]; then
  echo "Usage: move_directory_safely.sh <source directory> <target directory>"
  echo "Please create the full target directory name, this script will not archive to a subdirectory."
  echo "Please put a trailing backslash on the source directory name."
  echo "For example, ./archive_directory.sh /db2_bkup/archive/ /tier3_sac_nas/archive"
  echo "Please create the intended target directory and set correct ownership and permission first." 
  exit
fi

if [ ! -d $1 ]; then
	echo "Script parameter #1 - source directory does not exist: $1"
	error_exit
fi

if [ ! -d $2 ]; then
	echo "Script parameter #2 - target directory does not exist: $2"
	error_exit
fi

echo "copy operation beginning at: $(date)" > $logfile
echo "Source: $1" >> $logfile
echo "Target: $2" >> $logfile
echo "SOURCE REPORTS" >> $logfile
echo "Summary file size of source directory (bytes) (du -sb):" >> $logfile
du -sb $1 >> $logfile 2>> $errfile
echo "===========" >> $logfile
echo "du -ab report:" >> $logfile
du -ab $1 >> $logfile 2>> $errfile
echo "===========" >> $logfile
echo "ls -lR report:" >> $logfile
ls -lR $1 >> $logfile 2>> $errfile
echo "===========" >> $logfile
echo "Beginning rsync now" >> $logfile
rsync -av $1 $2 >> $logfile 2>> $errfile
echo "===========" >> $logfile
echo "rsync operation has ended at $(date)" >> $logfile
echo "TARGET REPORTS" >> $logfile
echo "Summary file size of source directory (bytes) (du -sb):" >> $logfile
du -sb $2 >> $logfile 2>> $errfile
echo "===========" >> $logfile
echo "du -ab report:" >> $logfile
du -ab $2 >> $logfile 2>> $errfile
echo "===========" >> $logfile
echo "ls -lR report:" >> $logfile
ls -lR $2 >> $logfile 2>> $errfile
echo "===========" >> $logfile

echo "Script has completed at $(date)" >> $logfile
echo "Review error output file: $errfile" >> $logfile

graceful_exit
