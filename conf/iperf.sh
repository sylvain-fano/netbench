iperf3 -f m -c server -4 -R -P4 -t 10 | grep Mbits | tail -1 | sed 's/\s\s*/ /g' | cut -d' ' -f6 | awk '{print "iperf-download,tester=sylvain,origin-country=france,os=windows,destination=server,value="$1}'"

curl -w "@curl-format.conf" -o /dev/null -s $TARGET
