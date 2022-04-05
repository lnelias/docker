#!/usr/bin/bash
# by Leo Elias
_root=/tmp
_socks5_server_address=${TORPROXY}
_socks5_server_port=${TORPROXY_PORT}
#_ssh_host=186.226.63.15
_ssh_host=96.47.227.5
_ssh_user=leo
_local_socks_bind=1080
_timeout=10
_https_tunnel=96.47.227.5
_https_tunnel_port=443


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
# Proxytunnel
#
__proxytunnel_daemon_pid="init"
function proxytunnel_daemon_launch() {
    pkill proxytunnel
    nohup proxytunnel -p ${SOCKS5_SERVER}:${SOCKS5_SERVER_PORT} -d ${_ssh_host}:${_https_tunnel_port} -a 8080 &
    __proxytunnel_daemon_pid="`echo $!`"
    if ps -p ${__proxytunnel_daemon_pid} > /dev/null; then
        log INFO "Proxytunnel is running"
    else
        log ERROR "Proxytunnel FAILED to launch"
    fi
}


function proxytunnel() {
    if [ "${__proxytunnel_daemon_pid}" == "init" ]; then
        proxytunnel_daemon_launch
    else
        if ps -p ${__proxytunnel_daemon_pid} > /dev/null; then
            log INFO "Proxytunnel is running"
        else
            log INFO "Proxytunnel is out, relaunching it."
            proxytunnel_daemon_launch
        fi
    fi

}

#
# Cerfificate 
#
function get_cert() {

    log INFO "Querying for remote certificate using ${_socks5_server_address}:${_socks5_server_port} "
    ssh root@${_https_tunnel} -o ConnectTimeout=${_timeout} -o "ProxyCommand=/usr/bin/nc -X 5 -x ${_socks5_server_address}:${_socks5_server_port} %h %p" "yes | openssl s_client -showcerts -connect ${_https_tunnel}:${_https_tunnel_port}" | sed -n "/BEGIN/, /END/p" > ${_root}/${_ssh_host}.reference.pubcert
    if [ ! -s ${_root}/${_ssh_host}.reference.pubcert ]; then
        log ERROR "Failed to query REFERENCE cert through socks5 proxy"
    fi

    
    log INFO "Querying remote pub cert presented through proxytunnel"
    yes | openssl s_client -showcerts -connect localhost:8080 | sed -n "/BEGIN/, /END/p" > /tmp/.${_ssh_host}.pubcert
    if [ ! -s /tmp/.${_ssh_host}.pubcert ]; then
        log ERROR "Failed to query remote cert through proxytunnel"
    fi
}

function certCheck() {
    get_cert 2>/dev/null
    if [ -f /tmp/.${_ssh_host}.pubcert ]; then
        __remote_hash="`md5sum /tmp/.${_ssh_host}.pubcert| awk '{print $1}'`"
        __reference_hash="`md5sum ${_root}/${_ssh_host}.reference.pubcert| awk '{print $1}'`"
        if [ "${__remote_hash}" == "${__reference_hash}" ]; then
            log INFO "Local Certificate matches remote."
            __cert_status='ok'
        else
            log ERROR "REMOTE CERT is not matching our reference !!"
            __cert_status='out'

        fi
        
    else
        log WARN "Could not find dumped certificate to compare to our reference"
    fi
}


#
# Main()
#


proxytunnel
get_cert
certCheck

log INFO "Cycling ssh tunnel"

if [ "${__cert_status}" == "ok" ]; then
    log INFO "---------------------------------------------"
    log INFO " Launching tunnel"
    log INFO "---------------------------------------------"
    ssh -N -4 -o ConnectTimeout=${_timeout} \
        -o ServerAliveInterval=10 \
        -o ServerAliveCountMax=2 \
        -D ${_local_socks_bind} \
        -g ${_ssh_user}@${_ssh_host} \
        -o "ProxyCommand=proxytunnel \
        -z -p ${SOCKS5_SERVER}:${SOCKS5_SERVER_PORT} \
        -r ${_https_tunnel}:${_https_tunnel_port} \
        -X -R ${proxy_user}:${proxy_pass} \
        -d %h:%p -v"
    log ERROR "Cycling ssh tunnel"
else
    log ERROR "Failed to launch tunnel..."
fi

