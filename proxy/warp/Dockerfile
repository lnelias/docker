FROM ubuntu:20.04

RUN apt-get update && apt-get clean &&  DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y \
    wget \
    x11-apps \
    libavcodec-extra \
    ffmpeg \
    pulseaudio \
    pulseaudio-utils \
    alsa-base alsa-utils libasound2 \
    ca-certificates wget expect iproute2 curl procps libnm0 gettext-base gnupg \
    screen dnsutils socat sudo vim

# Cloudflare inst
ENV OS_CodeName=focal
RUN curl https://pkg.cloudflareclient.com/pubkey.gpg | apt-key add - \
    && echo "deb http://pkg.cloudflareclient.com/ ${OS_CodeName} main" | tee /etc/apt/sources.list.d/cloudflare-client.list \
    && apt update \
    && apt install cloudflare-warp -y

RUN apt-get install -y netcat
COPY entrypoint.sh .
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
