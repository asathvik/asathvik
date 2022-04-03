#!/bin/bash
################################################################################
 
#	 
#
# Purpose:
#	Runs shell script on any server in any data center or network by going 
#	through "jump servers". Script must be run under mysql user. SSH host 
#	key has to be verified before running this script. Be careful with 
#	scripts that output files to /dba_share, since /dba_share is different 
#	between SATC and LVDC.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	2011-12-14 -  
#	Script created based on /dba_share/scripts/mysql/utils/run_sql_script_anywhere.sh.
#	2011-12-16 -  
#	Added support for passing arguments to the script being executed 
#	remotely.
#	2012-12-05 -  
#	Added --connectivity-test option.
#	2012-12-06 -  
#	Added --verbose option.
#   2013-02-26 - jbenner
#   Commented 'LVDC' functionality
#   Added hosts: faclsna01smet05 
#                faclsna01vfic12
#                faclsna01vfic13
#                faclsna01vfic22
#                faclsna01vfic23
#   2013-03-19 - jbenner
#   Added Data Ops, Dallas hosts. Firewall changes are made,
#   /etc/hosts updated. mysql accounts with .ssh added where necessary.
#   Access to Data Ops servers works 100% and is complete.
#   Outstanding issues 2013-03-19 - still issues with Dallas hosts:
#   fada1sdb32/fada1sdb35/facldal01vfic32/facldal01vfic33 all have correctly configured 'mysql' accounts 
#   and accept password-less ssh now, but fada1sdb32/fada1sdb35 immediately close connection. Unknown why. 
#   Because fada1sdb35 is the jump server, it is essential that the close connection
#   problem be resolved before we can access the entire Dallas network and its 4 servers under our management.
#
#   faclsna01vbld01 is a deprecated server and is being removed from this script.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

## 2013-02-26 jbenner - comment LVDC functionality
# Array of LVDC hosts.
## lvdc_hosts=( atone-db02 data001 data002 data003 data004 data005 data006 data007 data009 data010 data011 data012 data013 data014 data015 data016 data017 data020 data101 data102 data103 data104 r5-db-perf )
# Array of SATC prod hosts.
satc_prod_hosts=( faclsna01sadb01 faclsna01sddb01 faclsna01sddb02 faclsna01sddb03 faclsna01sddb04 faclsna01sddb05 faclsna01sddb06 faclsna01sfcr01 faclsna01sfcr02 faclsna01slap01 faclsna01slap02 faclsna01slap03 faclsna01slap04 faclsna01slap05 faclsna01slap06 faclsna01slap07 faclsna01sldb01 faclsna01sldb02 faclsna01sldb03 faclsna01sldb04 faclsna01sldb05 faclsna01sldb06 faclsna01sldb07 faclsna01sldb08 faclsna01sldb09 faclsna01slsd01 faclsna01slsd02 faclsna01slsd03 faclsna01slsd04 faclsna01smdb01 faclsna01smdb02 faclsna01smdb03 faclsna01smdb04 faclsna01smdb05 faclsna01smdb06 faclsna01smdb07 faclsna01smdb08 faclsna01smdb09 faclsna01smdb10 faclsna01smdb11 faclsna01smdb12 faclsna01smdb13 faclsna01smdb14 faclsna01smdb15 faclsna01smdb16 faclsna01smdb17 faclsna01smdb18 faclsna01smdb19 faclsna01smdb20 faclsna01smdb21 faclsna01smdb22 faclsna01smdb23 faclsna01smdb24 faclsna01smdb25 faclsna01smdb26 faclsna01smdb27 faclsna01smdb28 faclsna01smdb29 faclsna01smdb30 faclsna01smdb31 faclsna01smdb32 faclsna01smdb33 faclsna01smdb34 faclsna01smdb35 faclsna01smdb36 faclsna01smdb37 faclsna01smdb38 faclsna01vmdb01 faclsna01vmdb02 faclsna01vmdb03 faclsna01vmdb04 faclsna01vmdb05 faclsna01vmdb06 faclsna01vmdb07 faclsna01vmdb08 faclsna01vmdb09 faclsna01vmdb10 faclsna01vmdb11 faclsna01vmdb12 faclsna01vmdb13 faclsna01vmdb14 faclsna01vmdb15 faclsna01vmdb16 faclsna01vmdb17 faclsna01vfic12 faclsna01vfic13 )
# Array of SATC qad hosts.
satc_qad_hosts=( faclsna01sdba01 faclsna01sdba02 faclsna01sdsd01 faclsna01sdsd02 faclsna01sdsd03 faclsna01sdsd04 faclsna01smpf01 faclsna01smpf02 faclsna01smpf03 faclsna01smpf04 faclsna01smpf05 faclsna01smrd01 faclsna01smrd02 faclsna01smrd03 faclsna01smrd04 faclsna01smrd05 faclsna01smrd06 faclsna01smrd07 faclsna01smrd08 faclsna01smsd01 faclsna01smsd02 faclsna01smsd03 faclsna01smsd04 faclsna01smsd05 faclsna01smet05 faclsna01vfic22 faclsna01vfic23 )
## 2013-03-05 jbenner - Add Data Ops, Dallas hosts.
satc_data_ops_hosts=( faclsna01vcpp05 faclsna01vmet05 )
dtc_hosts=( facldal01vfic32 facldal01vfic33 fada1sdb32 fada1sdb35 )

# Default values.
connectivity_test=false
verbosity_level=0


################################################################################
# Functions
################################################################################

function clean_up {
	# Function to remove temporary files and other housekeeping
	# No arguments
	rm -f ${tmp_file}
}

function graceful_exit {
	# Function called for a graceful exit
	# No arguments
	clean_up
	exit
}

function error_exit {
	# Function for exit due to fatal program error
	# Accepts 1 argument
	#	string containing descriptive error message
	echo "${progname}: ${1:-"Unknown Error"}" 1>&2
	clean_up
	exit 1
}

function term_exit {
	# Function to perform exit if termination signal is trapped
	# No arguments
	echo "${progname}: Terminated"
	clean_up
	exit 1
}

function int_exit {
	# Function to perform exit if interrupt signal is trapped
	# No arguments
	echo "${progname}: Aborted by user"
	clean_up
	exit 1
}

function usage {
	# Function to show usage
	# No arguments
	echo "USAGE"
	echo "	$progname -h hostname < script.sh &> logfile.log"
	echo
	echo "EXAMPLE"
	echo "	$progname -h faclsna01sdba01 < script.sh &> logfile.log"
	echo
	echo "OPTIONS"
	echo "	-h, --host"
	echo "		Establish remote connection to this host."
	echo "	-c, --connectivity-test"
	echo "		Useful for verifying connectivity between servers."
	echo "		Runs in test mode only, does not execute actual commands."
	echo "	-v, --verbose"
	echo "		Verbose mode. Produces more information in output."
	echo "		Could be specified multiple times."

	clean_up
	exit 1
}

function ssh_connect {
	# Function to establish ssh connection
	# No arguments
	if $connectivity_test; then
		for host in "${ssh_connect_path[@]}"; do
			cmd="ssh $host echo "'"Connected ok."'
			cmdprev="$cmdprev $cmdnext"
			cmdnext="ssh -q $host"
			cmdfinal="$cmdprev $cmd"
			echo "Connecting to $host..."
			echo $cmdfinal
			$cmdfinal || error_exit "Error on line $LINENO. Error connecting to server."
			echo
		done
	else
		for host in "${ssh_connect_path[@]}"; do
			cmd="ssh -q $host bash -s - "
			cmdprev="$cmdprev $cmdnext"
			cmdnext="ssh -q $host"
			cmdfinal="$cmdprev $cmd"
		done
		$cmdfinal $arguments <&0 || error_exit "Error on line $LINENO. Error connecting to server."
	fi
}


################################################################################
# Program starts here
################################################################################

# Trap TERM, HUP, and INT signals and properly exit.
trap term_exit TERM HUP
trap int_exit INT

# Read parameters.
while [ "$1" != "" ]; do
	case $1 in
	-h | --host )
		shift
		host=$1;;
	-c | --connectivity-test )
		connectivity_test=true;;
	-v | --verbose )
		verbosity_level=$((verbosity_level + 1));;
	-? | --help )
		usage;;
	* )
		arguments="$@"
		break
	esac
	shift
done

# If required parameters are missing, then exit.
if [[ -z "$host" ]]; then
    echo "ERROR: Not all required parameters were passed in."
    usage
fi

if [[ "$verbosity_level" -ge 1 ]]; then
	if [[ "$verbosity_level" -ge 2 ]]; then
		echo "************************************************************"
		echo "* Time started:" `date +'%F %T %Z'`
		echo "************************************************************"
		echo
	fi
	echo "host:" $host
	if [[ "$verbosity_level" -ge 2 ]]; then
		echo
	fi
fi

# Identify source network.
ip=$(host $HOSTNAME | awk '{print $NF}' | sed 's/\.[0-9]*$//')
case $ip in
    192.168.60 | 192.168.62 )
        network_source=satc_qad
        ;;
    10.183.100 | 10.183.28 )
        network_source=satc_prod
        ;;
## 2013-03-05 jbenner - Add Data Ops, Dallas hosts.
    10.184.131 )
        network_source=satc_data_ops
        ;;
    10.141.61 | 10.128.210 )
        network_source=dtc
        ;;
    * )
        error_exit "Error on line $LINENO. Unknown source network!"
esac

# Identify target network.
for item in "${satc_prod_hosts[@]}"; do
    if [[ $item == $host ]]; then
        network_target=satc_prod
    fi
done
if [[ -z "$network_target" ]]; then
	for item in "${satc_qad_hosts[@]}"; do
	    if [[ $item == $host ]]; then
	        network_target=satc_qad
	    fi
	done
fi
## 2013-03-05 jbenner - Add Data Ops, Dallas hosts.
if [[ -z "$network_target" ]]; then
	for item in "${satc_data_ops_hosts[@]}"; do
	    if [[ $item == $host ]]; then
	        network_target=satc_data_ops
	    fi
	done
fi
if [[ -z "$network_target" ]]; then
	for item in "${dtc_hosts[@]}"; do
	    if [[ $item == $host ]]; then
	        network_target=dtc
	    fi
	done
fi
## 2013-02-26 jbenner - comment LVDC functionality
## if [[ -z "$network_target" ]]; then
	## for item in "${lvdc_hosts[@]}"; do
	    ## if [[ $item == $host ]]; then
	        ## network_target=lvdc
	    ## fi
	## done
## fi

# Execute script through a jump server if necessary.
case $network_target in
## 2013-02-26 jbenner - comment LVDC functionality
    ## lvdc )
	## case $network_source in
	    ## satc_prod )
	        ## # Using data020 as jump server.
	        ## ssh_connect_path=(192.168.140.138 $host)
	        ## ssh_connect
		## ;;
	    ## satc_qad )
	        ## # Using data020 as jump server.
	        ## ssh_connect_path=(192.168.140.138 $host)
	        ## ssh_connect
		## ;;
	    ## * )
		## error_exit "Error on line $LINENO. Undefined jump server!"
	## esac
        ## ;;
    satc_prod )
        case $network_source in
	    satc_prod )
	    	ssh_connect_path=($host)
	        ssh_connect
		;;
	    satc_qad )
	        # Using faclsna01smsd05 and faclsna01sldb04 as jump servers.
	        ssh_connect_path=(faclsna01smsd05 faclsna01sldb04 $host)
	        ssh_connect
		;;
## 2013-03-05 jbenner - Add Data Ops, Dallas hosts.
	    satc_data_ops )
	        # Using faclsna01vcpp05 and faclsna01sldb04 as jump servers.
	        ssh_connect_path=(faclsna01vcpp05 faclsna01sldb04 $host)
	        ssh_connect
		;;
	    dtc )
	        # Using fada1sdb35 and faclsna01sldb04 as jump servers.
	        ssh_connect_path=(fada1sdb35 faclsna01sldb04 $host)
	        ssh_connect
		;;
	    * )
		error_exit "Error on line $LINENO. Undefined jump server!"
	esac
        ;;
    satc_qad )
        case $network_source in
	    satc_prod )
	        # Using faclsna01sldb04 and faclsna01smsd05 as jump servers.
	        ssh_connect_path=(faclsna01sldb04 faclsna01smsd05 $host)
	        ssh_connect
		;;
	    satc_qad )
	    	ssh_connect_path=($host)
	        ssh_connect
		;;
## 2013-03-05 jbenner - Add Data Ops, Dallas hosts.
	    satc_data_ops )
	        # Using faclsna01vcpp05, faclsna01sldb04 and faclsna01smsd05 as jump servers.
	        ssh_connect_path=(faclsna01vcpp05 faclsna01sldb04 faclsna01smsd05 $host)
	        ssh_connect
		;;
	    dtc )
	        # Using fada1sdb35, faclsna01sldb04 and faclsna01smsd05 as jump servers.
	        ssh_connect_path=(fada1sdb35 faclsna01sldb04 faclsna01smsd05 $host)
	        ssh_connect
		;;
	    * )
		error_exit "Error on line $LINENO. Undefined jump server!"
	esac
        ;;
## 2013-03-05 jbenner - Add Data Ops, Dallas hosts.
    satc_data_ops )
        case $network_source in
	    satc_prod )
	        # Using faclsna01sldb04 and faclsna01vcpp05 as jump servers.
	        ssh_connect_path=(faclsna01sldb04 faclsna01vcpp05 $host)
	        ssh_connect
		;;
	    satc_qad )
	        # Using faclsna01smsd05, faclsna01sldb04 and faclsna01vcpp05 as jump servers.
	        ssh_connect_path=(faclsna01smsd05 faclsna01sldb04 faclsna01vcpp05 $host)
	        ssh_connect
		;;
	    satc_data_ops )
	    	ssh_connect_path=($host)
	        ssh_connect
		;;
	    dtc )
	        # Using fada1sdb35, faclsna01sldb04 and faclsna01vcpp05 as jump servers.
	        ssh_connect_path=(fada1sdb35 faclsna01sldb04 faclsna01vcpp05 $host)
	        ssh_connect
		;;
	    * )
		error_exit "Error on line $LINENO. Undefined jump server!"
	esac
        ;;
    dtc )
        case $network_source in
	    satc_prod )
	        # Using faclsna01sldb04 and fada1sdb35 as jump servers.
	        ssh_connect_path=(faclsna01sldb04 fada1sdb35 $host)
	        ssh_connect
		;;
	    satc_qad )
	        # Using faclsna01smsd05, faclsna01sldb04 and fada1sdb35 as jump servers.
	        ssh_connect_path=(faclsna01smsd05 faclsna01sldb04 fada1sdb35 $host)
	        ssh_connect
		;;
	    satc_data_ops )
	        # Using faclsna01vcpp05, faclsna01sldb04 and fada1sdb35 as jump servers.
	        ssh_connect_path=(faclsna01vcpp05 faclsna01sldb04 fada1sdb35 $host)
	        ssh_connect
		;;
	    dtc )
	    	ssh_connect_path=($host)
	        ssh_connect
		;;
	    * )
		error_exit "Error on line $LINENO. Undefined jump server!"
	esac
        ;;
    * )
        error_exit "Error on line $LINENO. Unknown target network!"
esac

if [[ "$verbosity_level" -ge 2 ]]; then
	echo
	echo "************************************************************"
	echo "* Time completed:" `date +'%F %T %Z'`
	echo "************************************************************"
fi

graceful_exit
