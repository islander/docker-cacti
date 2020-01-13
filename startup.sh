#!/bin/bash

set -e

if [ -f /etc/configured ]; then
        echo 'already configured'
else
        # code that need to run only one time ....
        SPINE_CONF=/usr/local/spine/etc/spine.conf
        [ -z "$MYSQL_ENV_USER" ] && MYSQL_ENV_USER="cacti"
        MYSQL_BIN="mysql -h ${MYSQL_ENV_HOST} -u ${MYSQL_ENV_USER} -p${MYSQL_ENV_USER_PASSWD}"
        MYSQL_BIN_ROOT="mysql -h ${MYSQL_ENV_HOST} -u root -p${MYSQL_ENV_ROOT_PASSWD}"

        init_cacti_db() {
            echo "CREATE DATABASE IF NOT EXISTS cacti" \
                    | $MYSQL_BIN_ROOT
            echo "GRANT ALL ON cacti.* TO cacti@'%' IDENTIFIED BY '${MYSQL_ENV_USER_PASSWD}'; FLUSH PRIVILEGES; " \
                    | $MYSQL_BIN_ROOT
            echo "GRANT SELECT ON mysql.time_zone_name TO cacti@'%' IDENTIFIED BY '${MYSQL_ENV_USER_PASSWD}'; FLUSH PRIVILEGES; " \
                    | $MYSQL_BIN_ROOT
            $MYSQL_BIN_ROOT cacti < /opt/cacti/cacti.sql
            echo "ALTER DATABASE cacti CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" \
                    | $MYSQL_BIN_ROOT cacti
        }

        # initialize database if not exists
        if [[ -z "${MYSQL_ENV_ROOT_PASSWD}" ]]
        then
                echo "no mysql root password, skipping initialization."
        else
                DBS="$(echo "SHOW DATABASES;" | $MYSQL_BIN_ROOT | grep -c cacti)"
                if [[ "${DBS}" -eq "0" ]]
                then
                        init_cacti_db
                fi
        fi

        # adjust spine MySQL configuration
        [ -z "$MYSQL_ENV_HOST" ] || sed -i -e "s/DB_Host.*/DB_Host\t\t${MYSQL_ENV_HOST}/" $SPINE_CONF
        [ -z "$MYSQL_ENV_DBNAME" ] || sed -i -e "s/DB_Database.*/DB_Database\t\t${MYSQL_ENV_DBNAME}/" $SPINE_CONF
        [ -z "$MYSQL_ENV_USER" ] || sed -i -e "s/DB_User.*/DB_User\t\t${MYSQL_ENV_USER}/" $SPINE_CONF
        [ -z "$MYSQL_ENV_USER_PASSWD" ] || sed -i -e "s/DB_Pass.*/DB_Pass\t\t${MYSQL_ENV_USER_PASSWD}/" $SPINE_CONF

        #to fix problem with data.timezone that appear at 1.28.108 for some reason
        sed  -i "s|\;date.timezone =|date.timezone = \"${TZ:-America/New_York}\"|" /etc/php/7.2/apache2/php.ini
        sed  -i "s|\;date.timezone =|date.timezone = \"${TZ:-America/New_York}\"|" /etc/php/7.2/cli/php.ini
        sed  -i 's!memory_limit = 128M!memory_limit = 512M!' /etc/php/7.2/apache2/php.ini
        sed  -i 's!max_execution_time = 30!max_execution_time = 60!' /etc/php/7.2/apache2/php.ini

        #needed for fix problem with ubuntu and cron
        update-locale 
        date > /etc/configured
fi
