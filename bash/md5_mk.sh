#!/bin/bash
################################################################################
#       Author:                                               #
# Date Created: 09/21/2005                                                     #
# Date Updated: 09/30/2005                                                     #
#      Purpose: Creates a file with md5 checksums so that the integrity of     #
#               files copied over network can be verified later.               #
################################################################################

################################################################################
# USAGE INFORMATION                                                            #
################################################################################
if [ "$1" == "" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
    echo "USAGE:"
    echo "$0 DIRECTORY"
    echo "EXAMPLE:"
    echo "$0 FA_DD_COMPRESSED"
    exit 1
fi

################################################################################
# CREATE MD5 CHECKSUM FILE                                                     #
################################################################################
dir_exec=$1
dir_work=`pwd`
file_md5=md5.${dir_exec}.txt

echo "Creating MD5 checksum file..."
echo "Started: `date`"
cd $dir_exec
md5sum *.MYD *.MYI *.frm > $file_md5
chmod 775 $file_md5
chown mysql:dba $file_md5
cd $dir_work
echo "Finished: `date`"

exit 0
