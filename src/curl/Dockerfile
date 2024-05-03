# Use a base image
FROM alpine:latest

# Install tools
RUN apk --no-cache add curl

COPY conf /conf
COPY curl.sh /

RUN chmod +x /curl.sh

ENTRYPOINT [ "/curl.sh" ]
