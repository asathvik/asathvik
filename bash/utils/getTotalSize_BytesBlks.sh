# 2013.06
# original author: Bob Waites
# further modified by: Jeff Benner
bout=/tmp/_`basename $0`_bytes
Bout=/tmp/_`basename $0`_blocks

if [[ -z $1 || ! -d $1 || $# -ne 1 ]]
then
   echo "Purpose of this script: report different ways of aggregating filesize for a"
   echo "directory. Shows filesize in bytes, 512-byte blocks and also du output."
   echo "Used to compare source and target during rsync operations to validate that"
   echo "the rsync was successful. "
   echo "usage: `basename $0` start_path    start_path must be a directory"
   exit 1
fi

echo "Totaling size of each file (bytes and 512-byte blocks)..."
stotal=0
btotal=0
find $1 \( -type f -or -type l \) -printf "%s %b\n" | while read s b 
do 
   ((stotal = stotal + s))
   ((btotal = btotal + b))
   echo $stotal > $bout
   echo $btotal > $Bout
done

echo "Getting 'du' results..."
duBytes=`du -sb $1 | awk '{print $1}'`
duBlks=`du -sB 512 $1 | awk '{print $1}'`

echo "Totals for $1"
printf "%-7s %16s %16s\n" "Method" "Bytes" "Blocks"
printf "%-7s %16s %16s\n" "FileSum" `cat $bout` `cat $Bout`
printf "%-7s %16s %16s\n" "Use_du" $duBytes $duBlks

rm -f $bout $Bout
