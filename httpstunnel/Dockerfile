FROM ubuntu:20.04

RUN apt-get update && apt-get clean &&  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y \
    wget \
    ca-certificates wget curl netcat \
    vim apache2
COPY entrypoint.sh .
COPY conf/default-ssl.conf .
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]


