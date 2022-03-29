FROM ubuntu:20.04

RUN apt-get update && apt-get clean &&  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y \
    wget \
    ca-certificates wget curl \
    screen dnsutils socat sudo vim openssh-client

RUN apt-get install -y netcat proxytunnel
COPY entrypoint.sh .
ADD ssh /root/.ssh
RUN chmod 700 /root/.ssh 

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
