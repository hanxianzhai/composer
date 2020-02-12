#!/bin/sh
set -eu

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

run_as() {
    if [ "$(id -u)" = 0 ]; then
        su -p www-data -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}



if expr "$1" : [ "$1" = "supervisord" ] || [ "$1" = "php-fpm" ] ]; then
    
    if [ -z "$(ls -A "/var/www/html")" ]; then
       cd /var/www/html
       echo "DownLoad WeEngine online install file ..."
       
       #curl -L -O https://cdn.w7.cc/download/WeEngine-Laster-Online.zip && unzip WeEngine-Laster-Online.zip && rm -f WeEngine-Laster-Online.zip
       elif [-f /var/www/html/install.php]; then
       echo "file install.php is ready ..."
       exit 1
       fi
    fi
fi

    if version_greater "$image_version" "$installed_version"; then
        echo "Initializing nextcloud $image_version ..."
        if [ "$installed_version" != "0.0.0.0" ]; then
            echo "Upgrading nextcloud from $installed_version ..."
            
            run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
        fi
        if [ "$(id -u)" = 0 ]; then
            rsync_options="-rlDog --chown www-data:root"
        else
            rsync_options="-rlD"
        fi
        rsync $rsync_options --delete --exclude-from=/upgrade.exclude /usr/src/nextcloud/ /var/www/html/

        for dir in config data custom_apps themes; do
            if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
                rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ /var/www/html/
            fi
        done
        rsync $rsync_options --include '/version.php' --exclude '/*' /usr/src/nextcloud/ /var/www/html/
        echo "Initializing finished"

exec "$@"