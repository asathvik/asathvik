#!/bin/sh
# Script created by Dimitriy Alekseyev on 2012-10-10.
# Used source code from: http://stackoverflow.com/questions/1272675/how-to-grab-an-arbitrary-chunk-from-a-file-on-unix-linux/1280828#1280828

bs=1048576
infile=$1
skip=$2
length=$3

(
  dd bs=1 skip=$skip count=0
  dd bs=$bs count=$(($length / $bs))
  dd bs=$(($length % $bs)) count=1
) < "$infile"
