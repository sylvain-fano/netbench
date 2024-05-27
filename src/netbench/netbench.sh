#!/bin/bash

VERSION="0.1.1"

ARTIFACTORY_REPO=$1
ARTIFACTORY_USERNAME=$2
ARTIFACTORY_TOKEN=$3
SHORT_ID=$(echo "$4" | tr '[:lower:]' '[:upper:]')
LOCATION=$(echo "$5" | tr '[:lower:]' '[:upper:]')
OS=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
HOSTNAME=$(hostname)
SWF_CERT=$6
SWF_KEY=$7

AWS_REGION="eu-central-1"
LOG_GROUP="/swf/netbench"
LOG_STREAM="$SHORT_ID"

SLEEP=900 # runs every 15 minutes

# FILENAME="$SHORT_ID-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)"
FILENAME="$SHORT_ID"
dd if=/dev/urandom of="/tmp/$FILENAME" bs=1M count=100 status=none

# Check if the client CERT or KEY is empty
if [ -z "$6" ] || [ -z "$7" ]; then
  CONTEXT=INTRANET
  IPERF_SERVER="-c 53.13.80.189 -p 443"
  MTR_SERVER="artifact.swf.i.mercedes-benz.com -P 443"
else
  CONTEXT=INTERNET
  IPERF_SERVER="-c speedtest.wtnet.de -p 5200"
  MTR_SERVER="artifact.swf.i.mercedes-benz.com -P 443"
fi

# Check if log stream exists, if not, create it
if ! aws logs describe-log-streams --region $AWS_REGION --log-group-name "$LOG_GROUP" --log-stream-name-prefix "$LOG_STREAM" --query 'logStreams[?logStreamName==`'$LOG_STREAM'`]' --output text | grep -q "$LOG_STREAM"; then
  aws logs create-log-stream --region $AWS_REGION --log-group-name "$LOG_GROUP" --log-stream-name "$LOG_STREAM"
fi

SEQUENCE=""
i=1
while true
do

##################################################################################  
# CURL
##################################################################################  

  if [[ "$CONTEXT" == "INTERNET" ]]; then
    curl_upload=$(echo "{ \
      \"version\": \"$VERSION\", \
      \"loop\": $i, \
      \"test\": \"curl\", \
      \"direction\": \"upload\", \
      \"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\", \
      \"id\": \"$SHORT_ID\", \
      \"location\": \"$LOCATION\", \
      \"os\": \"$OS\", \
      \"hostname\": \"$HOSTNAME\", \
      \"context\": \"$CONTEXT\", \
      $(curl -w @conf/curl-upload.conf --cert $SWF_CERT --key $SWF_KEY --user $ARTIFACTORY_USERNAME:$ARTIFACTORY_TOKEN -X PUT -T /tmp/$FILENAME $ARTIFACTORY_REPO/$FILENAME -o /dev/null --silent --no-buffer)}" | jq tostring)
  else
    curl_upload=$(echo "{ \
      \"version\": \"$VERSION\", \
      \"loop\": $i, \
      \"test\": \"curl\", \
      \"direction\": \"upload\", \
      \"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\", \
      \"id\": \"$SHORT_ID\", \
      \"location\": \"$LOCATION\", \
      \"os\": \"$OS\", \
      \"hostname\": \"$HOSTNAME\", \
      \"context\": \"$CONTEXT\", \
      $(curl -w @conf/curl-upload.conf --user $ARTIFACTORY_USERNAME:$ARTIFACTORY_TOKEN -X PUT -T /tmp/$FILENAME $ARTIFACTORY_REPO/$FILENAME -o /dev/null --silent --no-buffer)}" | jq tostring)
  fi
  echo $curl_upload | jq .
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$curl_upload}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)
  SEQUENCE=" --sequence-token $SEQ"

  if [[ "$CONTEXT" == "INTERNET" ]]; then
    curl_download=$(echo "{ \
      \"version\": \"$VERSION\", \
      \"loop\": $i, \
      \"test\": \"curl\", \
      \"direction\": \"download\", \
      \"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\", \
      \"id\": \"$SHORT_ID\", \
      \"location\": \"$LOCATION\", \
      \"os\": \"$OS\", \
      \"hostname\": \"$HOSTNAME\", \
      \"context\": \"$CONTEXT\", \
      $(curl -w @conf/curl-download.conf --cert $SWF_CERT --key $SWF_KEY --user $ARTIFACTORY_USERNAME:$ARTIFACTORY_TOKEN $ARTIFACTORY_REPO/$FILENAME -o /dev/null --silent --no-buffer)}" | jq tostring)
  else
     curl_download=$(echo "{ \
      \"version\": \"$VERSION\", \
      \"loop\": $i, \
      \"test\": \"curl\", \
      \"direction\": \"download\", \
      \"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\", \
      \"id\": \"$SHORT_ID\", \
      \"location\": \"$LOCATION\", \
      \"os\": \"$OS\", \
      \"hostname\": \"$HOSTNAME\", \
      \"context\": \"$CONTEXT\", \
      $(curl -w @conf/curl-download.conf --user $ARTIFACTORY_USERNAME:$ARTIFACTORY_TOKEN $ARTIFACTORY_REPO/$FILENAME -o /dev/null --silent --no-buffer)}" | jq tostring)
  fi
  echo $curl_download | jq .
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$curl_download}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)
  SEQUENCE=" --sequence-token $SEQ"

  ##################################################################################
  # MTR 
  ##################################################################################
  mtr=$(mtr $MTR_SERVER -w -T -j | \
    jq " \
      {\"version\": \"$VERSION\"} + \
      {\"loop\": $i} + \
      {\"test\": \"mtr\"} + \
      {\"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\"} + \
      {\"id\": \"$SHORT_ID\"} + \
      {\"location\": \"$LOCATION\"} + \
      {\"os\": \"$OS\"} + \
      {\"hostname\": \"$HOSTNAME\"} + \
      {\"context\": \"$CONTEXT\"} + \
      . " \
    | jq tostring)
  echo $mtr | jq .
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$mtr}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)
  SEQUENCE=" --sequence-token $SEQ"

  ################################################################################## 
  # IPERF
  ################################################################################## 
  iperf_upload=$(iperf3 $IPERF_SERVER -4 --json -t 10 | \
    jq " \
      {\"version\": \"$VERSION\"} + \
      {\"loop\": $i} + \
      {\"test\": \"iperf3-tcp\"} + \
      {\"direction\": \"upload\"} + \
      {\"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\"} + \
      {\"id\": \"$SHORT_ID\"} + \
      {\"location\": \"$LOCATION\"} + \
      {\"os\": \"$OS\"} + \
      {\"hostname\": \"$HOSTNAME\"} + \
      {\"context\": \"$CONTEXT\"} + \
      . " \
    | jq tostring)
  echo $iperf_upload | jq .
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$iperf_upload}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)
  SEQUENCE=" --sequence-token $SEQ"

  iperf_download=$(iperf3 $IPERF_SERVER -4 --json -t 10 -R | \
    jq " \
      {\"version\": \"$VERSION\"} + \
      {\"loop\": $i} + \
      {\"test\": \"iperf3-tcp\"} + \
      {\"direction\": \"download\"} + \
      {\"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\"} + \
      {\"id\": \"$SHORT_ID\"} + \
      {\"location\": \"$LOCATION\"} + \
      {\"os\": \"$OS\"} + \
      {\"hostname\": \"$HOSTNAME\"} + \
      {\"context\": \"$CONTEXT\"} + \
      . " \
    | jq tostring)
  echo $iperf_download | jq .
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$iperf_download}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)
  SEQUENCE=" --sequence-token $SEQ"

  iperf_upload_udp=$(iperf3 $IPERF_SERVER -4 --json -t 10 -u | \
    jq " \
      {\"version\": \"$VERSION\"} + \
      {\"loop\": $i} + \
      {\"test\": \"iperf3-udp\"} + \
      {\"direction\": \"upload\"} + \
      {\"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\"} + \
      {\"id\": \"$SHORT_ID\"} + \
      {\"location\": \"$LOCATION\"} + \
      {\"os\": \"$OS\"} + \
      {\"hostname\": \"$HOSTNAME\"} + \
      {\"context\": \"$CONTEXT\"} + \
      . " \
    | jq tostring)
  echo $iperf_upload_udp | jq .
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$iperf_upload_udp}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)
  SEQUENCE=" --sequence-token $SEQ"
  
  iperf_download_udp=$(iperf3 $IPERF_SERVER -4 --json -t 10 -u -R | \
    jq " \
      {\"version\": \"$VERSION\"} + \
      {\"loop\": $i} + \
      {\"test\": \"iperf3-udp\"} + \
      {\"direction\": \"download\"} + \
      {\"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\"} + \
      {\"id\": \"$SHORT_ID\"} + \
      {\"location\": \"$LOCATION\"} + \
      {\"os\": \"$OS\"} + \
      {\"hostname\": \"$HOSTNAME\"} + \
      {\"context\": \"$CONTEXT\"} + \
      . " \
    | jq tostring)
  echo $iperf_download_udp | jq .
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$iperf_download_udp}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)
  SEQUENCE=" --sequence-token $SEQ"


  i=$(($i+1))
  sleep $SLEEP
done