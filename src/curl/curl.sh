#!/bin/sh

TARGET=$1
CERT=$2
KEY=$3
USERNAME=$4
TOKEN=$5
FILE=conf/test10Mb.dat

i=1

while true
do
  now=$(date)
  
  echo ""
  echo "$i - $now"
  curl -w @conf/curl-upload.conf -X PUT -T $FILE --cert $CERT --key $KEY --user $USERNAME:$TOKEN --silent $TARGET/$FILE -o /dev/null --no-buffer
  
  echo ""
  echo "$i - $now"
  curl -w @conf/curl-download.conf  --cert $CERT --key $KEY --user $USERNAME:$TOKEN $TARGET/$FILE -o /dev/null --silent --no-buffer
  
  i=$(($i+1))
  sleep 10
  # exit 0
done