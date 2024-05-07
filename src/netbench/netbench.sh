#!/bin/sh

ARTIFACTORY_REPO=$1
ARTIFACTORY_USERNAME=$2
ARTIFACTORY_TOKEN=$3
SHORT_ID=$(echo "$4" | tr '[:lower:]' '[:upper:]')
LOCATION=$(echo "$5" | tr '[:lower:]' '[:upper:]')
OS=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
HOSTNAME=$(hostname)
SWF_CERT=$6
SWF_KEY=$7

FILE=conf/test10Mb.dat
AWS_REGION="eu-central-1"
LOG_GROUP="netbench"
LOG_STREAM="$SHORT_ID"
SEQUENCE=""


# Check if log stream exists, if not, create it
if ! aws logs describe-log-streams --region $AWS_REGION --log-group-name "$LOG_GROUP" --log-stream-name-prefix "$LOG_STREAM" --query 'logStreams[?logStreamName==`'$LOG_STREAM'`]' --output text | grep -q "$LOG_STREAM"; then
  aws logs create-log-stream --region $AWS_REGION --log-group-name "$LOG_GROUP" --log-stream-name "$LOG_STREAM"
fi

i=1
while true
do
 curl_download=$(echo "{ \
    \"loop\": $i, \
    \"test\": \"curl\", \
    \"direction\": \"download\", \
    \"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\", \
    \"location\": \"$LOCATION\", \
    \"os\": \"$OS\", \
    \"hostname\": \"$HOSTNAME\", \
    $(curl -w @conf/curl-download.conf --cert $SWF_CERT --key $SWF_KEY --user $ARTIFACTORY_USERNAME:$ARTIFACTORY_TOKEN $ARTIFACTORY_REPO/$FILE -o /dev/null --silent --no-buffer)}" | jq tostring)
  echo $curl_download | jq .
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$curl_download}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)
  SEQUENCE=" --sequence-token $SEQ"

  ##################################################################################  

  curl_upload=$(echo "{ \
    \"loop\": $i, \
    \"test\": \"curl\", \
    \"direction\": \"upload\", \
    \"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\", \
    \"location\": \"$LOCATION\", \
    \"os\": \"$OS\", \
    \"hostname\": \"$HOSTNAME\", \
    $(curl -w @conf/curl-upload.conf --cert $SWF_CERT --key $SWF_KEY --user $ARTIFACTORY_USERNAME:$ARTIFACTORY_TOKEN -X PUT -T $FILE $ARTIFACTORY_REPO/$FILE -o /dev/null --silent --no-buffer)}" | jq tostring)
  echo $curl_upload | jq .
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$curl_upload}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)
  SEQUENCE=" --sequence-token $SEQ"

  ##################################################################################

  iperf_download=$(iperf3 -c speedtest.wtnet.de -p 5200 -4 --json -t 10 -R | \
    jq " \
      {\"loop\": $i} + \
      {\"test\": \"iperf3\"} + \
      {\"direction\": \"download\"} + \
      {\"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\"} + \
      {\"location\": \"$LOCATION\"} + \
      {\"os\": \"$OS\"} + \
      {\"hostname\": \"$hostname\"} + \
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

  ##################################################################################
 
  iperf_upload=$(iperf3 -c speedtest.wtnet.de -p 5200 -4 --json -t 10 | \
    jq " \
      {\"loop\": $i} + \
      {\"test\": \"iperf3\"} + \
      {\"direction\": \"upload\"} + \
      {\"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\"} + \
      {\"location\": \"$LOCATION\"} + \
      {\"os\": \"$OS\"} + \
      {\"hostname\": \"$hostname\"} + \
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

  ##################################################################################
  

  i=$(($i+1))
  sleep 10
done