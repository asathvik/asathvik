#!/bin/bash
################################################################################
# Date Created: 09/21/2005                                                     #
# Date Updated: 10/03/2005                                                     #
#      Purpose: Verifies md5 checksums of files copied over network against a  #
#               file with md5 checksums.                                       #
################################################################################

################################################################################
# USAGE INFORMATION                                                            #
################################################################################
if [ "$1" == "" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
    echo "USAGE:"
    echo "$0 DIRECTORY"
    echo "EXAMPLE:"
    echo "$0 FIRSTAM_NEW"
    exit 1
fi

################################################################################
# VERIFY AGAINST MD5 CHECKSUM FILE                                             #
################################################################################
dir_exec=$1
dir_work=`pwd`

echo "Verifying against MD5 checksum file(s)..."
echo "Started: `date`"
cd $dir_exec
cat md5.*.txt | sort > md5.tmp1
md5sum *.MYD *.MYI *.frm | sort > md5.tmp2
diff --side-by-side --suppress-common-lines md5.tmp1 md5.tmp2 > md5.tmp3

if [ `ls -Al md5.tmp3 | awk -F' ' '{print $5}'` -gt "0" ]
then
    # Size of differences file is greater than 0, so there are differences.
    differences=Yes
else
    # Size of differences file is not greater than 0, so there are no differences.
    differences=No
fi

echo "Differences: $differences"
cat md5.tmp3
rm md5.tmp1 md5.tmp2 md5.tmp3
cd $dir_work
echo "Finished: `date`"

exit 0
