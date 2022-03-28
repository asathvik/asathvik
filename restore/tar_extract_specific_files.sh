#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Script showing example usage of extracting files from tar archive.
#
# Revisions:
#	04/12/2012 - Dimitriy Alekseyev
#	Script created.
################################################################################


################################################################################
# Sample commands
################################################################################

# Example of extracting specific files. This command for some reason does not preserve permissions of the directory (maybe a tar bug?).
nohup time tar -xzvpf /mysql_bkup/mysql_oltp_bkup/realcore_faclsna01sldb09_master/20120404_122217.daily/binlogs.tar.gz --wildcards 'binlogs/binlog*.index' > extract.log &

# Example of how to just list the contents of an archive.
nohup time tar -tzvf /mysql_bkup/mysql_oltp_bkup/wordpressblog_faclsna01smdb33_slave/20120411_230002.daily/data.tar.gz > listing.log &
