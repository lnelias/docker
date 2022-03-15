#!/usr/bin/bash
# by Leo Elias
__socks_host=haproxy
__socks_port=3128
__ssh_server=96.47.227.5
__ssh_user=leo
__local_socks_bind=1080
__hev_socks_server_port=1081
__hev_socks_server_local_port=2081
__timeout=2

FontColor_Red="\033[31m"
FontColor_Red_Bold="\033[1;31m"
FontColor_Green="\033[32m"
FontColor_Green_Bold="\033[1;32m"
FontColor_Yellow="\033[33m"
FontColor_Yellow_Bold="\033[1;33m"
FontColor_Purple="\033[35m"
FontColor_Purple_Bold="\033[1;35m"
FontColor_Suffix="\033[0m"

#
# Functions
#

# checkWarp() {
#     warpOn="`curl -s https://www.cloudflare.com/cdn-cgi/trace/ | grep warp`"
#     if [ "$warpOn" == "warp=on" ]; then
#         log INFO "Warp connected!"
#     else
#         log ERROR "Warp not working..."
#         exit 1
#     fi
# }


log() {
    local LEVEL="$1"
    local MSG="$2"
    __Date="`date +%y/%m/%d_%H:%M:%S`"
    case "${LEVEL}" in
    INFO)
        local LEVEL="[${FontColor_Green}${LEVEL}${FontColor_Suffix}]"
        local MSG="${LEVEL} ${__Date} :: ${MSG}"
        ;;
    WARN)
        local LEVEL="[${FontColor_Yellow}${LEVEL}${FontColor_Suffix}]"
        local MSG="${LEVEL} ${__Date} :: ${MSG}"
        ;;
    ERROR)
        LEVEL="FAIL"
        local LEVEL="[${FontColor_Red}${LEVEL}${FontColor_Suffix}]"
        local MSG="${LEVEL} ${__Date} :: ${MSG}"
        ;;
    *) ;;
    esac
    echo -e "${MSG}"
}


log INFO "Launching ssh tunnel"
ssh -N -4 -o ConnectTimeout=${__timeout} -D ${__socks_port} -g -L ${__hev_socks_server_local_port}:127.0.0.1:${__hev_socks_server_port} ${__ssh_user}@${__ssh_server} -o "ProxyCommand=/usr/bin/nc -X 5 -x ${__socks_host}:${__socks_port} %h %p"
log INFO "Cycling ssh tunnel"

