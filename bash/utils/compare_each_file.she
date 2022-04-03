#!/bin/sh
# compare_each_file.sh - after an rsync, if you see aggregate filecount differences,
# identify the files which have a filesize or existence discrepancy.
# 2013.06.03 - jbenner
# USAGE: compare_each_file.sh <source directory> <target directory>

if [ $# -ne 2 ]; then
  echo "Purpose of this script: should be used in tandem with getTotalSize_BytesBlks.sh"
  echo "to validate a rsync operation (typically a move of a directory from one NAS or storage"
  echo "device to another). If getTotalSize_BytesBlks.sh shows a byte difference, this script"
  echo "will show the source of the difference. "
  echo "USAGE: compare_each_file.sh <source directory> <target directory>"
  exit 0
fi

if [ ! -d $1 ]; then
  echo "Directory $1 does not exist."
  exit 1
fi

if [ ! -d $2 ]; then
  echo "Directory $2 does not exist."
  exit 1
fi

find $1 \( -type f -or -type l \) -printf "%s %p\n" | while read s p 
do
  p_truncate=`echo $p | sed "s%^$1%%g"`
  target_p=$2${p_truncate}
  if [ -f "$target_p" -o -L "$target_p" ]; then
    target_s=`du -b "$target_p" | cut -f1`
    if [[ $s -ne $target_s ]]; then
      echo ""
      echo "Source size = " $s
      echo "Target size = " $target_s
      echo "Source file = " $p
      echo "Target file = " $target_p
    fi
  else
    echo ""
    echo "Target file or link does not exist: " $target_p
    echo "Source file: " $p
  fi
done
