FROM alpine:latest

# Install iperf3
RUN apk --no-cache add iperf3

# Set the default environment variables for iperf3 duration and additional parameters
ENV IPERF3_DURATION=60
ENV IPERF3_INTERVAL=10
ENV IPERF3_SERVER=localhost
ENV TESTER_EMAIL=sylvain.fanomezanarizaka@demicon.de
ENV COUNTRY=FRANCE
ENV OS=WSL


# Run iperf3 client to connect to the iperf3 daemon server
# CMD ["sh", "-c", "iperf3 -c $IPERF3_SERVER -t $IPERF3_DURATION -i $IPERF3_INTERVAL $IPERF3_ADDITIONAL_PARAMS | grep Mbits | tail -1 | sed 's/\s\s*/ /g' | cut -d' ' -f6 | awk '{print `iperf-download,tester=`$TESTER_EMAIL`,origin-country=`$COUNTRY`,os=`$OS`,destination=server value=`$1}'"]
CMD ["sh", "-c", "iperf3 -c $IPERF3_SERVER -t $IPERF3_DURATION -i $IPERF3_INTERVAL $IPERF3_ADDITIONAL_PARAMS | grep Mbits | tail -1 | sed 's/\s\s*/ /g' | cut -d' ' -f6 | awk '{print \"iperf-download,tester=sylvain,origin-country=france,os=windows,destination=test,value=\"$1}'"]
