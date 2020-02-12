#!/bin/sh
set -eu

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

if expr "$1" : [ "$1" = "supervisord" ] ]; then   
    if [ -z "$(ls -A "/var/www/html")" ]; then
       cd /var/www/html
       echo "DownLoad WeEngine online install file ..."
       curl -L -O https://github.com/hanxianzhai/composer/blob/master/WeEngine-v2.5.4.zip && unzip WeEngine-v2.5.4.zip && rm -rf WeEngine-v2.5.4.zip
       
       #curl -L -O https://cdn.w7.cc/download/WeEngine-Laster-Online.zip && unzip WeEngine-Laster-Online.zip && rm -f WeEngine-Laster-Online.zip
       chown -R www-data:root /var/www
       chmod -R g=u /var/www
    else
       echo "WeEngine is ready,Now start it ..."
    fi
else 
    echo "Wrong parameters,Only supervisord parameters are supported ..."   
    exit 1
fi
exec "$@"