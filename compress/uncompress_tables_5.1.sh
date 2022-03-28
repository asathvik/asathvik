#!/bin/bash
################################################################################
#       Author: Dimitriy Alekseyev                                             #
# Date Created: 08/02/2006                                                     #
# Date Updated: 01/26/2007                                                     #
#      Purpose: Uncompress MySQL tables.                                       #
################################################################################

################################################################################
# USAGE INFORMATION                                                            #
################################################################################
if [ "$1" == "" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ] ; then
    echo "USAGE:"
    echo "	$0 /path/table_name.MYI"
    echo "EXAMPLE:"
    echo "	$0 /mysql_01/ivpro/wage_index.MYI"
    echo "	$0 /mysql_01/ivpro/*.MYI"
    echo "NOTE:"
    echo "	Wild cards may be used. Extension may be omitted when wild cards are not used."
    exit 1
fi

tables=$@

echo "****************************************"
date +'Start Uncompress: %F %T %Z'
echo "****************************************"

/software/mysql-5.1.24-rc-linux-x86_64-glibc23/bin/myisamchk --unpack $tables

echo "****************************************"
date +'End: %F %T %Z'
echo "****************************************"
