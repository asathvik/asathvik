#!/bin/bash
################################################################################
# Author:
#	Dimitriy Alekseyev
#
# Purpose:
#	Runs SQL script on any server in any data center or network by going 
#	through "jump servers". Script must be run under mysql user. SSH host 
#	key has to be verified before running this script.
#
# Usage:
#	Run script with -? or --help option to get usage information.
#
# Revisions:
#	11/09/2011 - Dimitriy Alekseyev
#	Script created.
#	11/23/2011 - Dimitriy Alekseyev
#	Added new network source and made other small changes.
#	12/14/2011 - Dimitriy Alekseyev
#	Added new network source. Added -q (quite) option to ssh commands.
################################################################################


################################################################################
# Constants and Global Variables
################################################################################

# Program name.
progname=`basename $0`

# Array of LVDC hosts.
lvdc_hosts=( atone-db02 data001 data002 data003 data004 data005 data006 data007 data009 data010 data011 data012 data013 data014 data015 data016 data017 data020 data101 data102 data103 data104 r5-db-perf )
# Array of SATC prod hosts.
satc_prod_hosts=( faclsna01vbld01 faclsna01sadb01 faclsna01sddb01 faclsna01sddb02 faclsna01sddb03 faclsna01sddb04 faclsna01sddb05 faclsna01sddb06 faclsna01sfcr01 faclsna01sfcr02 faclsna01slap01 faclsna01slap02 faclsna01slap03 faclsna01slap04 faclsna01slap05 faclsna01slap06 faclsna01slap07 faclsna01sldb01 faclsna01sldb02 faclsna01sldb03 faclsna01sldb04 faclsna01sldb05 faclsna01sldb06 faclsna01sldb07 faclsna01sldb08 faclsna01sldb09 faclsna01slsd01 faclsna01slsd02 faclsna01slsd03 faclsna01slsd04 faclsna01smdb01 faclsna01smdb02 faclsna01smdb03 faclsna01smdb04 faclsna01smdb05 faclsna01smdb06 faclsna01smdb07 faclsna01smdb08 faclsna01smdb09 faclsna01smdb10 faclsna01smdb11 faclsna01smdb12 faclsna01smdb13 faclsna01smdb14 faclsna01smdb15 faclsna01smdb16 faclsna01smdb17 faclsna01smdb18 faclsna01smdb19 faclsna01smdb20 faclsna01smdb21 faclsna01smdb22 faclsna01smdb23 faclsna01smdb24 faclsna01smdb25 faclsna01smdb26 faclsna01smdb27 faclsna01smdb28 faclsna01smdb29 faclsna01smdb30 faclsna01smdb31 faclsna01smdb32 faclsna01smdb33 faclsna01smdb34 faclsna01smdb35 faclsna01smdb36 faclsna01smdb37 faclsna01smdb38 faclsna01vmdb01 faclsna01vmdb02 faclsna01vmdb03 faclsna01vmdb04 faclsna01vmdb05 faclsna01vmdb06 faclsna01vmdb07 faclsna01vmdb08 faclsna01vmdb09 faclsna01vmdb10 faclsna01vmdb11 faclsna01vmdb12 faclsna01vmdb13 faclsna01vmdb14 faclsna01vmdb15 faclsna01vmdb16 faclsna01vmdb17 )
# Array of SATC qad hosts.
satc_qad_hosts=( faclsna01sdba01 faclsna01sdba02 faclsna01sdsd01 faclsna01sdsd02 faclsna01sdsd03 faclsna01sdsd04 faclsna01smpf01 faclsna01smpf02 faclsna01smpf03 faclsna01smpf04 faclsna01smpf05 faclsna01smrd01 faclsna01smrd02 faclsna01smrd03 faclsna01smrd04 faclsna01smrd05 faclsna01smrd06 faclsna01smrd07 faclsna01smrd08 faclsna01smsd01 faclsna01smsd02 faclsna01smsd03 faclsna01smsd04 faclsna01smsd05 )


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

function usage
{
	# Function to show usage
	# No arguments
	echo "USAGE"
	echo "	$progname -h hostname { -i instance | -p port } < script.sql &> logfile.log"
	echo
	echo "EXAMPLE"
	echo "	$progname -h faclsna01sdba01 -i 1 < script.sql &> logfile.log"

	clean_up
	exit 1
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
            host=$1
            ;;
        -i | --instance )
            shift
            instance=$1
            ;;
        -p | --port )
            shift
            port=$1
            ;;
        -? | --help | * )
            usage
    esac
    shift
done

# If required parameters are missing, then exit.
if [[ -z "$host" || (-z "$instance" && -z "$port") ]]; then
    echo "ERROR: Not all required parameters were passed in."
    usage
fi

echo "************************************************************"
echo "* Time started:" `date +'%F %T %Z'`
echo "************************************************************"
echo

# Calculate instance number based on port number.
if [[ ! -z "$port" ]]; then
    instance_calc=$(( ($port - 3305) / 5 ))
    echo instance_calc: $instance_calc
    if [[ -z "$instance" ]]; then
        instance=$instance_calc
    else
        if [[ "$instance" != "$instance_calc" ]]; then
	    error_exit "Error on line $LINENO. Instance and port provided do not match!"
	fi
    fi
fi

# Calculate port number based on instance number.
port=$(( 3305 + $instance * 5 ))

echo "Host:" $host
echo "Instance:" $instance
echo "Port:" $port
echo

# Identify source network.
ip=$(host $HOSTNAME | awk '{print $NF}' | sed 's/\.[0-9]*$//')
case $ip in
    192.168.60 | 192.168.62 )
        network_source=satc_qad
        ;;
    10.183.100 | 10.183.28 )
        network_source=satc_prod
        ;;
    * )
        error_exit "Error on line $LINENO. Unknown source network!"
esac

# Identify target network.
for item in "${lvdc_hosts[@]}"; do
    if [[ $item == $host ]]; then
        network_target=lvdc
    fi
done
for item in "${satc_prod_hosts[@]}"; do
    if [[ $item == $host ]]; then
        network_target=satc_prod
    fi
done
for item in "${satc_qad_hosts[@]}"; do
    if [[ $item == $host ]]; then
        network_target=satc_qad
    fi
done

# Execute script through a jump server if necessary.
case $network_target in
    lvdc )
	case $network_source in
	    satc_prod )
	        # Using data020 as jump server.
		ssh -q 192.168.140.138 ssh -q $host /usr/local/bin/mysql/m${instance}c.sh <&0 || error_exit "Error on line $LINENO."
		;;
	    satc_qad )
	        # Using data020 as jump server.
		ssh -q 192.168.140.138 ssh -q $host /usr/local/bin/mysql/m${instance}c.sh <&0 || error_exit "Error on line $LINENO."
		;;
	    * )
		error_exit "Error on line $LINENO. Undefined jump server!"
	esac
        ;;
    satc_prod )
        case $network_source in
	    satc_prod )
		ssh -q $host /usr/local/bin/mysql/m${instance}c.sh <&0 || error_exit "Error on line $LINENO."
		;;
	    satc_qad )
	        # Using faclsna01smsd05 and faclsna01sldb04 as jump servers.
		ssh -q faclsna01smsd05 ssh -q faclsna01sldb04 ssh -q $host /usr/local/bin/mysql/m${instance}c.sh <&0 || error_exit "Error on line $LINENO."
		;;
	    * )
		error_exit "Error on line $LINENO. Undefined jump server!"
	esac
        ;;
    satc_qad )
        case $network_source in
	    satc_prod )
	        # Using faclsna01sldb04 and faclsna01smsd05 as jump servers.
		ssh -q faclsna01sldb04 ssh -q faclsna01smsd05 ssh -q $host /usr/local/bin/mysql/m${instance}c.sh <&0 || error_exit "Error on line $LINENO."
		;;
	    satc_qad )
		ssh -q $host /usr/local/bin/mysql/m${instance}c.sh <&0 || error_exit "Error on line $LINENO."
		;;
	    * )
		error_exit "Error on line $LINENO. Undefined jump server!"
	esac
        ;;
    * )
        error_exit "Error on line $LINENO. Unknown target network!"
esac

echo
echo "************************************************************"
echo "* Time completed:" `date +'%F %T %Z'`
echo "************************************************************"

graceful_exit
