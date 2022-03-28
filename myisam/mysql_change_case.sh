#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Change case of MySQL MyISAM table files either to all upper case or all 
#	lower case. Case of extension is left unchanged.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	08/28/2007 - Dimitriy Alekseyev
#	Script created.
#	11/28/2007 - Dimitriy Alekseyev
#	Updated script to rename the database directory along with table files.
################################################################################


################################################################################
# Functions
################################################################################

function clean_up
{
	#####
	#	Function to remove temporary files and other housekeeping
	#	No arguments
	#####

	rm -f ${tmp_file}
}

function graceful_exit
{
	#####
	#	Function called for a graceful exit
	#	No arguments
	#####

	clean_up
	exit
}

function error_exit
{
	#####
	# 	Function for exit due to fatal program error
	# 	Accepts 1 argument
	#		string containing descriptive error message
	#####

	echo "${progname}: ${1:-"Unknown Error"}" 1>&2
	clean_up
	exit 1
}

function term_exit
{
	#####
	#	Function to perform exit if termination signal is trapped
	#	No arguments
	#####

	echo "${progname}: Terminated"
	clean_up
	exit
}

function int_exit
{
	#####
	#	Function to perform exit if interrupt signal is trapped
	#	No arguments
	#####

	echo "${progname}: Aborted by user"
	clean_up
	exit
}

function usage
{
	#####
	#	Function to show usage
	#	No arguments
	#####

	echo "USAGE"
	echo "	$progname OPTION DIRECTORY"
	echo
	echo "SYNOPSIS"
	echo "	$progname {{-l | -u} DIRECTORY} | [-?|--help]"
	echo
	echo "OPTIONS"
	echo "	-l|--lower"
	echo "		Convert to lower case file names."
	echo
	echo "	-u|--upper"
	echo "		Convert to upper case file names."
	echo
	echo "EXAMPLE"
	echo "	$progname -l /mysql_01/miscdata"

	clean_up
	exit $STATE_UNKNOWN
}


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# Current directory.
directory_pwd=`pwd`

while [ "$1" != "" ]; do
    case $1 in
        -l | --lower )
            case=lower
            ;;
        -u | --upper )
            case=upper
            ;;
        -? | --help )
            usage
            ;;
        * )
            # Directory of MySQL table files.
            directory=$1
    esac
    shift
done

# If required parameters are missing, then exit.
if [[ -z "$case" || -z "$directory" ]]; then
    usage
fi


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit
trap term_exit TERM HUP
trap int_exit INT

echo "**************************************************"
echo "* Change case of MySQL MyISAM table files"
echo "* Time started:" `date +'%F %T %Z'`
echo "**************************************************"
echo
echo "Hostname.:" `hostname`.`dnsdomainname`
echo "Directory:" $directory
echo "Convert to: $case case"
echo


# Rename table files.

cd $directory || error_exit "Error on line $LINENO. Cannot change directory."
files=`ls *.MYI *.MYD *.frm 2> /dev/null`

if [[ -z "$files" ]] ; then
	echo "There were no table files to rename."
else
	for file_name_ext in $files
	do
		file_name=`echo $file_name_ext | awk -F'.' '{print $1}'`
		file_ext=`echo $file_name_ext | awk -F'.' '{print $2}'`
		
		if [[ "$case" = "upper" ]] ; then
			file_name_new=`echo $file_name | tr [a-z] [A-Z]`
		fi
		if [[ "$case" = "lower" ]] ; then
			file_name_new=`echo $file_name | tr [A-Z] [a-z]`
		fi
		
		# Only rename files which need to be renamed.
		if [[ "$file_name" != "$file_name_new" ]] ; then
			rename=yes
			echo "Renaming $file_name_ext to ${file_name_new}.$file_ext."
			mv "$file_name_ext" "${file_name_new}.$file_ext" || error_exit "Error on line $LINENO."
		fi
	done
	
	if [[ "$rename" != "yes" ]] ; then
		echo "No table files were renamed because they are already in $case case."
	fi
fi

echo

# Rename directory.

cd $directory_pwd || error_exit "Error on line $LINENO. Cannot change directory."

		directory_base=`basename $directory`
		directory_dir=`dirname $directory`

if [[ "$case" = "upper" ]] ; then
	directory_new=`echo $directory_base | tr [a-z] [A-Z]`
fi
if [[ "$case" = "lower" ]] ; then
	directory_new=`echo $directory_base | tr [A-Z] [a-z]`
fi

# Only rename directory which needs to be renamed.
if [[ "$directory_base" != "$directory_new" ]] ; then
	rename=yes
	echo "Renaming directory $directory_dir/$directory_base to $directory_dir/$directory_new."
	mv "$directory_dir/$directory_base" "$directory_dir/$directory_new" || error_exit "Error on line $LINENO."
fi


echo
echo "**************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "**************************************************"

graceful_exit
