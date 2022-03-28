# Author: Dimitriy Alekseyev
# Created: 2012-09-21
# Updated: 2012-10-10

# Importing huge files can have some drawbacks. If the import fails for some reason midway, then the whole load transaction is rolled back.

# Virtually splitting import file into multiple files will help with this issue.

# First run script 1 in the background to create virtual "split file" symbolic link.
nohup ./1_mk_fifo.sh >> 1_mk_fifo.log 2>> 1_mk_fifo.err &

# Then run script 2 to iterate over this virtual "split file" until all records are loaded.
nohup ./2_load.sh >> 2_load.log 2>> 2_load.err &

# If the second script finishes before the first script, then run second script again.

# The following command could be used to sum up the number of records loaded so far.
grep -A4 'LOAD DATA INFILE' 2_load.log | grep Records | awk '{sum+=$2} END {print sum}'
