#!/bin/bash
################################################################################
#       Author: AK                                             #
# Date Created: 07/07/2006                                                     #
# Date Updated: 02/21/2007                                                     #
#      Purpose: Compress MySQL tables.                                         #
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
    echo "	Use '.MYI' extenstion! Wild cards may be used. Multiple tables may be listed."
    exit 1
fi

tables=$@

echo "****************************************"
date +'Start Compress: %F %T %Z'
echo "****************************************"

myisampack --force --tmpdir=/tmp -v $tables

echo
echo "****************************************"
date +'Start Rebuild Indexes: %F %T %Z'
echo "****************************************"

myisamchk --force --recover --quick --tmpdir=/tmp -vvv $tables

echo
echo "****************************************"
date +'Start Analyze: %F %T %Z'
echo "****************************************"

myisamchk --analyze --tmpdir=/tmp -vvv $tables

echo
echo "****************************************"
date +'End: %F %T %Z'
echo "****************************************"

ls -l /tmp/*.TMD
#rm -f /tmp/*.TMD
#The above remove is not safe to use if more than one compress script is running on the same server.
#MySQL 5.0 probably cleans up *.TMD files automatically.
