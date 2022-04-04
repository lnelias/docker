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

a2enmod ssl
a2ensite default-ssl
a2enmod proxy proxy_connect proxy_http

log INFO "Adjusting config"
cp /default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf
sed -i 's/^Listen 80/#Listen 80/' /etc/apache2/ports.conf
echo "ServerSignature Off" >> /etc/apache2/apache2.conf
echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
echo "FileETag None" >> /etc/apache2/apache2.conf
echo "TraceEnable off" >> /etc/apache2/apache2.conf


_keyout=/etc/ssl/private/apache-selfsigned.key
_out=/etc/ssl/certs/apache-selfsigned.crt
if [ ! -f /conf/apache-selfsigned.key ] && [ ! -f /conf/apache-selfsigned.crt ]; then
    log WARN "No TLS cert found."
    log INFO "To use your own cert map key to /conf/apache-selfsigned.key and crt to /conf/apache-selfsigned.crt and restart/wipe container"
    log INFO "Generating self signed cert"
    openssl req -x509 -nodes -days 365 -newkey rsa:8192 -keyout ${_keyout} -out ${_out} \
        -subj "/C=US/ST=Florida/L=Miami/O=DevNull/OU=IT Department/CN=inbinarywetrust.com"
else 
    log INFO "Copying pushed cert to apache"
    cp /conf/apache-selfsigned.key ${_keyout}
    cp /conf/apache-selfsigned.crt ${_out}

fi

service apache2 start
log INFO "Apache Started"

# query certificate
log INFO "Querying server certificate"
_host=127.0.0.1:443
yes | openssl s_client -showcerts -connect ${_host} 2> /dev/null | sed -n "/BEGIN/, /END/p"
yes | openssl s_client -showcerts -connect ${_host} 2> /dev/null | sed -n "/BEGIN/, /END/p" > /conf/cert.out

if [ ! -f /conf/.htpasswd ]; then
    log WARN "No .htpasswd found."
    log INFO "To use your own htpasswd map your file to /conf/.htpasswd"
    log INFO "Generating .htpasswd... not safe at all."
    htpasswd -b -c /var/www/html/.htpasswd leo buceta123
else
    log INFO "Copying pushed htpasswd to apache"
    cp /conf/.htpasswd /var/www/html/.htpasswd
fi


while true; do
    if service apache2 status > /dev/null ; then
        sleep 5
    else
        exit 1
    fi
done
log ERROR "Restarting container"



