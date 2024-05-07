#!/bin/sh

ARTIFACTORY_REPO=$1
ARTIFACTORY_USERNAME=$2
ARTIFACTORY_TOKEN=$3
SHORT_ID=$(echo "$4" | tr '[:lower:]' '[:upper:]')
LOCATION=$(echo "$5" | tr '[:lower:]' '[:upper:]')
OS=$(echo "$6" | tr '[:lower:]' '[:upper:]')
HARDWARE=$(echo "$7" | tr '[:lower:]' '[:upper:]')
SWF_CERT=$8
SWF_KEY=$9

FILE=conf/test10Mb.dat
AWS_REGION="eu-central-1"
LOG_GROUP="netbench"
LOG_STREAM="$SHORT_ID"
SEQUENCE=""

iperf3 -f m -c server -4 -R -P4 -t 10 --json 