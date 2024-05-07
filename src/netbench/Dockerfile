# Use AWS CLI official Docker image
FROM public.ecr.aws/aws-cli/aws-cli:latest

# Install curl and jq
RUN yum update -y && \
    yum install -y curl jq iperf3 && \
    yum clean all

# Set work directory
WORKDIR /aws

COPY conf /aws/conf
COPY netbench.sh .

RUN chmod +x netbench.sh

ENTRYPOINT [ "/aws/netbench.sh" ]
