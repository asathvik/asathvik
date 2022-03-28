#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	List all MySQL databases on a server.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	2012-09-24 - Dimitriy Alekseyev
#	Script created.
#	2012-09-25 - Dimitriy Alekseyev
#	Revised mysqld version information output.
#	2012-11-01 - Dimitriy Alekseyev
#	Added table format for display of data. Revised database list display 
#	to show on one line. Added display of instance status - running or not.
#	2012-11-01 - Dimitriy Alekseyev
#	Added support for MySQL databases with old directory structure. Added 
#	hostname and instance with no leading zero to the list of possible 
#	outputs.
#	2012-11-01 - Dimitriy Alekseyev
#	Added instance disk utilization information. Added instance path 
#	information.
#	2012-11-05 - Dimitriy Alekseyev
#	Replaced underscore to dash in option names. Renamed some options. 
#	Moved version case statement to a function.
#	2012-12-03 - Dimitriy Alekseyev
#	Made table formatting the default. Added an option for getting the old 
#	default format - list output. Made instance with no leading zero the 
#	default. Created display_instance_info_header function.
#	2012-12-05 - Dimitriy Alekseyev
#	Added ability to filter by specific instance or instances. Added 
#	option to skip column names.
#	2013-02-25 - Dimitriy Alekseyev
#	Added mount point information to the list of possible outputs.
#	2013-03-01 - Dimitriy Alekseyev
#	Fixed some typos/bugs related to mount point information. Fixed an 
#	issue related to df output being split across multiple lines for one 
#	mount point.
#	2013-07-15 - Dimitriy Alekseyev
#	Renamed option --skip-column-names to --no-column-names.
#
# Todo:
#	Add ability to reorder output columns.
#	Add support for CSV and Tab delimited output formats of table layout.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# Main MySQL directory to use for sybolic links and other things.
main_dir=/mysql

# Default option values.
format_table=true
human_readable=false
output=iprd
version_mysqld_level=4
no_column_names=false


################################################################################
# Functions
################################################################################

function usage {
	# Function to show usage
	# No arguments
	echo "USAGE
	$progname [options]

EXAMPLE
	$progname -i 3 -t -o iprdD -h

OPTIONS
	-i, --instance
		List information for specified instance or instances only.
		If listing more than one instance, then enclose by quotes and separate with space.
	-t, --format-table
		Format output as a table. Default option.
	-l, --format-list
		Format output as a list of properties.
	-o, --output {[h][i][I][p][r][d][P][D][v]}
		Specify output columns. Provide one or more options. Default is iprd.
		h = hostname
		i = instance (instance with no leading zero)
		I = instance_wlz (instance with leading zero)
		p = port
		r = running (whether mysql instance is running or not)
		d = databases
		P = path (path to mysql instance directory)
		m = mount point
		D = disk_utilization (shown in KB by default)
		v = version
	-h, --human-readable
		Print sizes in human readable format (e.g. 125K, 13M, 47G).
	-N, --no-column-names
		Do not display column names in results.
	-v, --version-mysqld #
		Configures how detailed mysqld version information will be. Default: 4. Range: 1 to 6.
	-?, --help
		Show this help."
	
	exit 1
}

function display_instance_info_header {
	if ! $no_column_names; then
		if [[ $output == *h* ]]; then header="${header}hostname "; fi
		if [[ $output == *i* ]]; then header="${header}instance "; fi
		if [[ $output == *I* ]]; then header="${header}instance_wlz "; fi
		if [[ $output == *p* ]]; then header="${header}port "; fi
		if [[ $output == *r* ]]; then header="${header}running "; fi
		if [[ $output == *d* ]]; then header="${header}databases "; fi
		if [[ $output == *P* ]]; then header="${header}path "; fi
		if [[ $output == *m* ]]; then header="${header}mount_point "; fi
		if [[ $output == *D* ]]; then header="${header}disk_utilization "; fi
		if [[ $output == *v* ]]; then header="${header}version "; fi
		echo $header
	fi
}

function display_instance_info {
	# Display instance information.
	if $format_table; then
		detail=""
		if [[ $output == *h* ]]; then detail="${detail}${HOSTNAME} "; fi
		if [[ $output == *i* ]]; then detail="${detail}$inst "; fi
		if [[ $output == *I* ]]; then detail="${detail}$inst_wlz "; fi
		if [[ $output == *p* ]]; then detail="${detail}$port "; fi
		if [[ $output == *r* ]]; then detail="${detail}$running "; fi
		if [[ $output == *d* ]]; then detail="${detail}[$databases] "; fi
		if [[ $output == *P* ]]; then detail="${detail}$path "; fi
		if [[ $output == *m* ]]; then detail="${detail}$mount_point "; fi
		if [[ $output == *D* ]]; then detail="${detail}$disk_utilization "; fi
		if [[ $output == *v* ]]; then detail="${detail}\"$version\" "; fi
		echo $detail
	else
		if [[ $output == *h* ]]; then echo "hostname: ${HOSTNAME}"; fi
		if [[ $output == *i* ]]; then echo "instance: $inst"; fi
		if [[ $output == *I* ]]; then echo "instance_wlz: $inst_wlz"; fi
		if [[ $output == *p* ]]; then echo "port: $port"; fi
		if [[ $output == *r* ]]; then echo "running: $running"; fi
		if [[ $output == *d* ]]; then echo "databases: $databases"; fi
		if [[ $output == *P* ]]; then echo "path: $path"; fi
		if [[ $output == *m* ]]; then echo "path: $mount_point"; fi
		if [[ $output == *D* ]]; then echo "disk_utilization: $disk_utilization"; fi
		if [[ $output == *v* ]]; then echo "version: $version"; fi
		echo
	fi
}

function version_format {
	case $version_mysqld_level in
	1 ) version="$version_short";;
	2 ) version="$version_dist";;
	3 ) version="$version_dist $version_short";;
	4 ) version="$version_detail";;
	5 ) version="$version_mysqld";;
	6 ) version="$version_full";;
	* ) version="?"
	esac
}


################################################################################
# Program starts here
################################################################################

# Read parameters.
while [ "$1" != "" ]; do
	case $1 in
	-i | --instance )
		shift
		instance_filter=$1;;
	-o | --output )
		shift
		output=$1;;
	-t | --format-table )
		format_table=true;;
	-l | --format-list )
		format_table=false;;
	-h | --human-readable )
		human_readable=true;;
	-N | --no-column-names )
		no_column_names=true;;
	-v | --version-mysqld )
		shift
		version_mysqld_level=$1;;
	-? | --help )
		usage;;
	* )
		echo "ERROR: Incorrect parameters were passed in."
		usage
	esac
	shift
done

# Prepare instance filter for grep command.
for inst in $instance_filter
do
	# Instance number with the leading zero if it is less than 10.
	inst_wlz="0$inst"
	inst_wlz=${inst_wlz:${#inst_wlz}-2:2}
	
	if [[ -z "$instance_grep_filter_wlz" ]]; then
		instance_grep_filter_wlz="$inst_wlz"
	else
		instance_grep_filter_wlz="$instance_grep_filter_wlz|$inst_wlz"
	fi
done

# Display header if necessary.
if $format_table; then display_instance_info_header; fi

# Display instance information for instances with old style directory structure.
instance_list_old=$(ls -1d /mysql_?? 2> /dev/null | sed 's|/mysql_||' | egrep "$instance_grep_filter_wlz")
for inst_wlz in $instance_list_old
do
	# Instance number - no leading zero.
	inst=$(echo "$inst_wlz" | sed 's/^0//')
	
	path=/mysql_${inst_wlz}
	
	if [[ $output == *p* ]]; then
		port=$(egrep "^\[mysqld|^port=" /etc/my.cnf | grep -v mysqld_safe | grep -A 1 "^\[mysqld${inst}\]$" | tail -1 | cut -d'=' -f2)
		if [[ -z $port ]]; then port="none"; fi
	fi
	
	if [[ $output == *r* ]]; then
		running=no
		mysqld_pid=""
		pid_file=/mysql_${inst_wlz}/${HOSTNAME}.pid${inst}
		if [[ -s "$pid_file" ]]; then
			read mysqld_pid < $pid_file
			process=$(ps -p $mysqld_pid -o comm=)
			if [[ $process ]]; then running=yes; fi
		fi
	fi
	
	if [[ $output == *d* ]]; then
		databases=$(ls -F1 /mysql_${inst_wlz}/ | grep '/$' | egrep -v '^mysql/$|^performance_schema/$' | sed 's|/$||' | tr '\n' ' ' | sed 's/ $//')
	fi

	if [[ $output == *D* ]]; then
		if $human_readable; then
			disk_utilization=$(du -sh /mysql_${inst_wlz}/ | cut -f1)
		else
			disk_utilization=$(du -s /mysql_${inst_wlz}/ | cut -f1)
		fi
	fi

	if [[ $output == *m* ]]; then
		mount_point=$(df -hP /mysql_${inst_wlz}/ | gawk '{print $6}' | sed '1d')
	fi

	if [[ $output == *v* ]]; then
		# Probably MySQL RPM distribution
		version_full=$(/usr/sbin/mysqld --no-defaults --version)
		version_mysqld=$(echo $version_full | awk '{print $3}')
		version_short=$(echo $version_mysqld | awk -F'-' '{print $1}')
		if [[ $(echo $version_mysqld | grep enterprise) ]]; then
			version_dist="MySQL Enterprise"
			version_detail="MySQL Enterprise Server $version_short"
		else
			version_dist="MySQL Community"
			version_detail="MySQL Community Server $version_short"
		fi
		version_format
	fi
	display_instance_info
done

# Display instance information for instances with new style directory structure.
instance_list=$(ls -d $main_dir/??/ 2> /dev/null | xargs -n 1 -i basename {} | grep '[0-9][0-9]' | egrep "$instance_grep_filter_wlz")
for inst_wlz in $instance_list
do
	# Instance number - no leading zero.
	inst=$(echo "$inst_wlz" | sed 's/^0//')

	path=/mysql/$inst_wlz

	if [[ $output == *p* ]]; then
		port=$(grep "^port=" $main_dir/$inst_wlz/my.cnf | awk -F'=' '{print $2}')
		if [[ -z $port ]]; then port="none"; fi
	fi
	
	if [[ $output == *r* ]]; then
		running=no
		mysqld_pid=""
		pid_file=$main_dir/$inst_wlz/${HOSTNAME}_${inst_wlz}.pid
		if [[ -s "$pid_file" ]]; then
			read mysqld_pid < $pid_file
			process=$(ps -p $mysqld_pid -o comm=)
			if [[ $process ]]; then running=yes; fi
		fi
	fi
	
	if [[ $output == *d* ]]; then
		databases=$(ls -F1 $main_dir/$inst_wlz/data/ | grep '/$' | egrep -v '^mysql/$|^performance_schema/$' | sed 's|/$||' | tr '\n' ' ' | sed 's/ $//')
	fi

	if [[ $output == *D* ]]; then
		if $human_readable; then
			disk_utilization=$(du -sh /mysql/$inst_wlz/ | cut -f1)
		else
			disk_utilization=$(du -s /mysql/$inst_wlz/ | cut -f1)
		fi
	fi

	if [[ $output == *m* ]]; then
		mount_point=$(df -hP /mysql/$inst_wlz/ | gawk '{print $6}' | sed '1d')
	fi

	if [[ $output == *v* ]]; then
		# Get version information.
		ledir=$(grep '^ledir=' $main_dir/$inst_wlz/my.cnf | awk -F'=' '{print $2}')
		if [[ $ledir ]]; then	# Probably MySQL binary distribution
			version_full=$($(echo "${ledir}/mysqld --no-defaults --version"))
			version_mysqld=$(echo $version_full | awk '{print $3}')
			version_short=$(echo $version_mysqld | awk -F'-' '{print $1}')
			if [[ $(echo $ledir | grep -i percona) ]]; then
				version_dist="Percona"
				version_detail="Percona Server $version_short"
			elif [[ $(echo $version_mysqld | grep -i enterprise) ]]; then
				if [[ $(echo $version_mysqld | grep -i advanced) ]]; then
					version_dist="MySQL Enterprise"
					version_detail="MySQL Enterprise Server - Advanced Edition $version_short"
				else
					version_dist="MySQL Enterprise"
					version_detail="MySQL Enterprise Server $version_short"
				fi
			else
				version_dist="MySQL Community"
				version_detail="MySQL Community Server $version_short"
			fi
		else	# Probably MySQL RPM distribution
			version_full=$(/usr/sbin/mysqld --no-defaults --version)
			version_mysqld=$(echo $version_full | awk '{print $3}')
			version_short=$(echo $version_mysqld | awk -F'-' '{print $1}')
			if [[ $(echo $version_mysqld | grep enterprise) ]]; then
				version_dist="MySQL Enterprise"
				version_detail="MySQL Enterprise Server $version_short"
			else
				version_dist="MySQL Community"
				version_detail="MySQL Community Server $version_short"
			fi
		fi
		version_format
	fi
	display_instance_info
done
