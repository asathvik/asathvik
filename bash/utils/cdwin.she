#!/bin/bash
################################################################################
 
#	 
#
# Purpose:
#	Script for converting Windows dba_share path (mapped to S: drive) to 
#	Linux path and changing directory to that path.
#
# Usage:
#	Script has to be sourced.
#	It is easier to use this script with an alias such as this:
#	alias cdwin='. /dba_share/scripts/bash/utils/cdwin.sh'
#	Example: cdwin 'S:\dbs\lsalerts\mysql\db_maint\B-14589\prod'
#
# Revisions:
#	11/28/2011 -  
#	Script created.
#	11/29/2011 -  
#	Script now handles conversions both ways from Windows to Linux and from 
#	Linux to Windows paths.
#	12/01/2011 -  
#	Added some error checking.
#	04/25/2012 -  
#	Added display of SVN path.
#	05/16/2012 -  
#	Added display of SVN workspace path.
#	02/28/2012 -  
#	Added error message when script is run without being sourced. Looks 
#	like $BASH_SOURCE and $BASH_SUBSHELL are supported from version 3 of 
#	bash and we have 2.05.
#
# Todo:
#	Allow to run in "print" mode only, so that path is only displayed, but not changed.
#	Allow unquoted paths to be passed in. In this case the slashes will disappear, but we can use some logic to guess the correct path.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`


################################################################################
# Program starts here
################################################################################

# Exit script if an uninitialised variable is used.
set -o nounset

# If no parameters were passed in, assume current directory is meant.
if [[ $# == 0 ]]; then
    path=$(pwd)
else
    path="$@"
fi

if [[ $(echo "$path" | grep '/dba_share') ]]; then
    # Perform conversion from Linux to Windows.
    path_linux=$path
    path_svn=$(echo $path | sed 's|/dba_share|[dba-dares]/trunk|')
    path_windows=$(echo $path | sed 's|/dba_share|S:|;s|/|\\|g')
    path_svn_ws=$(echo $path_windows | sed 's|S:|C:\\svn\\dba-dares\\trunk|')
    echo "Linux path:   $path_linux"
    echo "SVN path:     $path_svn"
    echo "SVN WS path:  $path_svn_ws"
    echo "Windows path: $path_windows"
elif [[ $(echo "$path" | grep 'S:') || $(echo "$path" | grep 'T:') ]]; then
    # Perform conversion from Windows to Linux.
    path_linux=$(echo $path | sed 's|S:|/dba_share|;s|\\|/|g')
    path_svn=$(echo $path_linux | sed 's|/dba_share|[dba-dares]/trunk|')
    path_windows=$path
    path_svn_ws=$(echo $path_windows | sed 's|S:|C:\\svn\\dba-dares\\trunk|')
    echo "Linux path:   $path_linux"
    echo "SVN path:     $path_svn"
    echo "SVN WS path:  $path_svn_ws"
    echo "Windows path: $path_windows"
    cd $path_linux
else
    echo "ERROR: Cannot convert non dba_share paths." >&2
    return 1 || echo "ERROR: Please make sure to run the script by sourcing it." >&2; exit 1
fi

return 0 || echo "ERROR: Please make sure to run the script by sourcing it." >&2; exit 1
