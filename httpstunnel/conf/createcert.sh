openssl req -x509 -nodes -days 365 -newkey rsa:8192 -keyout apache-selfsigned.key -out apache-selfsigned.crt \
        -subj "/C=US/ST=Texas/L=Dakkas/O=DevNull/OU=IT Department/CN=iwanttogoback.com"
