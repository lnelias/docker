#!/usr/bin/bash
# by Leo Elias
_status="null"
_current_host="`hostname`"
sleep 60
while true; do
    if nc -w 1 ${_current_host} 1080; then
        _status="`http_proxy=socks5://${_current_host}:1080 curl -v http://client3.google.com/generate_204 2>&1 | grep '< HTTP/1.1' | awk '{print $3}'`"
        if [ "${_status}" != "204" ]; then
            pkill ssh
        fi
    else
        pkill ssh
    fi
    sleep 600
done