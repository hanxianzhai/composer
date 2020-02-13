#!/bin/sh
set -eu

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 | head -n 1)" != "$1" ]
}
# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}


if expr "$1" : "apache" 1>/dev/null || [ "$1" = "supervisord" ] || [ "$1" = "php-fpm" ] || [ "${UPDATE:-0}" -eq 1 ]; then 
    installed_version="0.0.0.0"
    if [ -f /var/www/html/version.php ]; then
        # shellcheck disable=SC2016
        installed_version="$(php -r 'require "/var/www/html/version.php"; echo implode(".", $OC_Version);')"
    fi
    # shellcheck disable=SC2016
    image_version="$(php -r 'require "/usr/src/weengine/version.php"; echo implode(".", $OC_Version);')"

    if version_greater "$installed_version" "$image_version"; then
        echo "Can't start weengine because the version of the data ($installed_version) is higher than the docker image version ($image_version) and downgrading is not supported. Are you sure you have pulled the newest image version?"
        exit 1
    fi

    if version_greater "$image_version" "$installed_version"; then
        echo "Initializing weengine $image_version ..."
        if [ "$installed_version" != "0.0.0.0" ]; then
            echo "Upgrading weengine from $installed_version ..."
            
        fi
        if [ "$(id -u)" = 0 ]; then
            rsync_options="-rlDog --chown www-data:root"
        else
            rsync_options="-rlD"
        fi
        rsync $rsync_options --delete --exclude-from=/upgrade.exclude /usr/src/weengine/ /var/www/html/

        for dir in addons; do
            if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
                rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/weengine/ /var/www/html/
            fi
        done
        rsync $rsync_options --include '/version.php' --exclude '/*' /usr/src/weengine/ /var/www/html/
        echo "Initializing finished"

        #install
        if [ "$installed_version" = "0.0.0.0" ]; then
            rsync $rsync_options /usr/src/weengine/ /var/www/html/
        fi
    fi    
fi

exec "$@"