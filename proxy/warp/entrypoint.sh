#!/usr/bin/bash
# by Leo Elias

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

#
# Main()
#

function init(){
    if sysctl net.ipv6.conf.all.disable_ipv6=0 >>/bootstrap.log 2>&1; then
        log INFO "IPv6 successfully enabled"
    else
        log ERROR "IPv6 not set properly"    
        exit 1
    fi

    if sudo screen -dmS warp-svc warp-svc; then
        log INFO "Warp-SVC launched"
        sleep 5 # just to make sure it took its time start
    else
        log ERROR "Warp-SVC failed to launch"    
        exit 1
    fi

    sleep 3 

    if warp-cli --accept-tos register >>/bootstrap.log 2>&1; then
        log INFO "Warp Registered"
    else
        log ERROR "Warp failed to register"    
        exit 1
    fi

    if sudo warp-cli --accept-tos set-mode proxy >>/bootstrap.log 2>&1; then
        log INFO "Warp set to PROXY mode."
    else
        log ERROR "Warp FAILED to set PROXY mode"    
        exit 1
    fi

    if sudo warp-cli --accept-tos enable-always-on >>/bootstrap.log 2>&1; then
        log INFO "Warp set to always on."
        sleep 5
    else
        log ERROR "Warp FAILED to set always on"    
        exit 1
    fi

    if warp-cli --accept-tos connect >>/bootstrap.log 2>&1 ; then
        log INFO "Warp Connected."
    else
        log ERROR "Failed to Connect"
    fi

    # sleep 1
    # pkill screen >>/bootstrap.log 2>&1; then
    #     log INFO "Screen Killed"
    # else
    #     log ERROR "Failed to kill Screen"
    # fi
  
}

function socatinit () {
    if screen -dmS socat socat -d -d TCP4-LISTEN:3128,reuseaddr,fork TCP4:127.0.0.1:40000; then
        log INFO "SOCAT set on port 3128."
    else
        log ERROR "Failed to bind using socat"
    fi
}

function delete (){
    if sudo warp-cli --accept-tos delete >>/bootstrap.log 2>&1 ; then
        log INFO "Warp deleted to ensure new register"
    else
        log ERROR "Warp failed to delete"    
        #exit 1
    fi
}

delete
init
socatinit

# #__local_ip="`sudo grep `hostname` /etc/hosts | awk '{print $1}'`"
__warp_ip="`http_proxy=socks5://127.0.0.1:40000 curl -s ifconfig.fi`"
log INFO "Warp IP is ${__warp_ip}"

while true; do
    if nc -nzvw 1 127.0.0.1 40000 >>/dev/null 2>&1; then
        if warp-cli --accept-tos status | grep Connected >>/dev/null 2>&1; then
            sleep 1
        else
            log ERROR "Warp CLI is open on 127.0.0.1:40000 but tunnel is showing disconnected"
            exit 1
        fi
    else
        log ERROR "Failed to connect to warp on 127.0.0.1:40000"
        exit 1
    fi
done

