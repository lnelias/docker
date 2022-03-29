FROM ubuntu:20.04

RUN apt-get update && apt-get clean &&  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y \
    wget vim python3 python3-pip netcat sudo
RUN pip3 install pproxy python-daemon
RUN apt-get install -y screen 

COPY entrypoint.sh .

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
