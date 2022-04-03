# On same filesystem.

ts_start=$(date '+%s.%N')
ts_filename=$(date '+%Y%m%d'_%H%M%S)
/dba_share/scripts/bash/disk/disk_perf_test.sh > disk_perf_test.$ts_filename.1.log &
/dba_share/scripts/bash/disk/disk_perf_test.sh > disk_perf_test.$ts_filename.2.log &
/dba_share/scripts/bash/disk/disk_perf_test.sh > disk_perf_test.$ts_filename.3.log &
wait
ts_end=$(date '+%s.%N')
ts_diff=$(echo "$ts_end - $ts_start" | bc)
echo "duration: $ts_diff seconds"


exit


# On different filesystems.

ts_start=$(date '+%s.%N')
ts_filename=$(date '+%Y%m%d'_%H%M%S)
cd /san02/disk_perf_test
/dba_share/scripts/bash/disk/disk_perf_test.sh > disk_perf_test.$ts_filename.1.log &
cd /san03/disk_perf_test
/dba_share/scripts/bash/disk/disk_perf_test.sh > disk_perf_test.$ts_filename.2.log &
cd /san04/disk_perf_test
/dba_share/scripts/bash/disk/disk_perf_test.sh > disk_perf_test.$ts_filename.3.log &
wait
ts_end=$(date '+%s.%N')
echo "duration: $ts_diff seconds"
