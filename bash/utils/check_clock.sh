   
# Date: 2013-03-01
# Updated: 2013-03-05

echo "USE db_tracking; SELECT host_name FROM vw_actv_host_inst_db WHERE host_os = 'linux' AND host_data_center = 'satc' AND network_env = 'prod' AND network_tier = 'sys' GROUP BY host_name ORDER BY host_name;" | m13.sh -BN | while read line; do set -- $line; echo -e $1'\t'$(date +'%s')'\t'$(date +'%F %T %Z')'\t# Time from '$(hostname); cmd="echo -e \$(hostname)'\t'\$(date +'%s')'\t'\$(date +'%F %T %Z')"; ssh -nq $1 "$cmd"; done > check_clock.log

echo "Hosts which have unknown time."
cat check_clock.log | awk '{print $1}' | uniq -c | grep '1 ' | awk 'BEGIN {print "hostname"} {print $2}'

echo "Hosts sorted by time difference."
cat check_clock.log | awk '{print $1, $2}' | awk 'function abs(x){return ((x < 0.0) ? -x : x)} {if ($1==host_p) {print $1, abs($2-sec_p)}; host_p=$1; sec_p=$2}' | sort -rnk 2 | sed '1i hostname time_diff_in_seconds'
