#!/bin/bash

NS1="ns1"
NS2="ns2"
RELNS1=1
RELNS2=1
LEVEL="warn"

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

RETURN=$STATE_UNKNOWN
OUTPUT="UNKNOWN: cannot test"

function usage() {
	cat << EOF
Usage: $0 <OPTIONS>
Checks DNS zone serial numbers 
Options:
-z DNS zone
-l Notification level (warn or crit, defaults to warn)
-M NS1 (absolute)
-S NS2 (absolute)
-m NS1 (relative, defaults to $NS1, cannot be used with -M)
-s NS2 (relative, defaults to $NS2, cannot be used with -S)
-h Prints this help message
Example: $0 -z example.com -n ns.example.com -b ns1 -l crit 
EOF
}

function quit {
	echo $OUTPUT
	exit $RETURN
}

while getopts "hz:l:M:S:m:s:" OPTION; do
	case $OPTION in
	h)
		usage
		exit 1
		;;
	z)
		ZONE="$OPTARG"
		;;
	l)
		LEVEL="$OPTARG"
		;;
	M)
		NS1="$OPTARG"
		RELNS1=0
		;;
	S)
		NS2="$OPTARG"
		RELNS2=0
		;;
	m)
		NS1="$OPTARG"
		;;
	s)
		NS2="$OPTARG"
		;;
	*)
		echo "Invalid option"
		usage
		exit 1;
		;;
	?)
		usage
		exit 0
		;;
	esac
done

[ -n "$ZONE" ] || { echo "No zone specified." ; exit $STATE_UNKNOWN; }
[ -n "$NS1" ] || { echo "No NS1 specified." ; exit $STATE_UNKNOWN; }
[ -n "$NS2" ] || { echo "No NS2 specified." ; exit $STATE_UNKNOWN; }
[ -n "$LEVEL" ] || { echo "No notification level specified." ; exit $STATE_UNKNOWN; }

if [ "$RELNS1" = 1 ]; then
	NS1="$NS1.$ZONE"
fi

if [ "$RELNS2" = 1 ]; then
	NS2="$NS2.$ZONE"
fi

SERIAL1=$(dig @$NS1 $ZONE soa +short | cut -d' ' -f3)
SERIAL2=$(dig @$NS2 $ZONE soa +short | cut -d' ' -f3)

if [ -z "$SERIAL1" ]; then
	RETURN=$STATE_UNKNOWN
	OUTPUT="UNKNOWN: cannot get serial from $NS1"
	quit
fi

if [ -z "$SERIAL2" ]; then
	RETURN=$STATE_UNKNOWN
	OUTPUT="UNKNOWN: cannot get serial from $NS2"
	quit
fi

if [ "$SERIAL1" = "$SERIAL2" ]; then
	RETURN=$STATE_OK
	OUTPUT="OK: serial $SERIAL1"
else 
	if [ "$LEVEL" = "crit" ]; then
		RETURN=$STATE_CRITICAL
		OUTPUT="CRITICAL: serial $SERIAL1 [$NS1] differs from $SERIAL2 [$NS2]"
	else
		RETURN=$STATE_WARNING
		OUTPUT="WARNING: serial $SERIAL1 [$NS1] differs from $SERIAL2 [$NS2]"
	fi
fi

quit