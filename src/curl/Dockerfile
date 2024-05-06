# Use AWS CLI official Docker image
FROM amazon/aws-cli:latest

# Install curl and jq
RUN yum update -y && \
    yum install -y curl jq && \
    yum clean all

# Set work directory
WORKDIR /aws

COPY conf /aws/conf
COPY curl.sh .

RUN chmod +x curl.sh

ENTRYPOINT [ "/aws/curl.sh" ]
