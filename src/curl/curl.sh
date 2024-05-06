#!/bin/sh

ARTIFACTORY_REPO=$1
ARTIFACTORY_USERNAME=$2
ARTIFACTORY_TOKEN=$3
SHORT_ID=$4
SWF_CERT=$5
SWF_KEY=$6

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
  
  upload=$(echo "{\"loop\": $i, \"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\", $(curl -w @conf/curl-upload.conf --cert $SWF_CERT --key $SWF_KEY --user $ARTIFACTORY_USERNAME:$ARTIFACTORY_TOKEN -X PUT -T $FILE $ARTIFACTORY_REPO/$FILE -o /dev/null --silent --no-buffer)}" | jq tostring)
  echo $upload
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$upload}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)

  # echo $SEQ
  SEQUENCE=" --sequence-token $SEQ"

  
  download=$(echo "{\"loop\": $i, \"datetime\": \"$(date --utc '+%Y-%m-%d %H:%M:%S')\", $(curl -w @conf/curl-download.conf --cert $SWF_CERT --key $SWF_KEY --user $ARTIFACTORY_USERNAME:$ARTIFACTORY_TOKEN -X PUT -T $FILE $ARTIFACTORY_REPO/$FILE -o /dev/null --silent --no-buffer)}" | jq tostring)
  echo $download
  SEQ=$(aws logs put-log-events \
    --region $AWS_REGION \
    --log-group-name $LOG_GROUP \
    --log-stream-name $LOG_STREAM \
    --log-events "{\"timestamp\":$(date +%s000),\"message\":$download}" \
    $SEQUENCE | jq .nextSequenceToken --raw-output)

  # echo $SEQ
  SEQUENCE=" --sequence-token $SEQ"

  i=$(($i+1))
  sleep 10
done