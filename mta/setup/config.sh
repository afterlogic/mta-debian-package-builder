#!/bin/bash

# - nginx.yml

mkdir -p /opt/afterlogic/var/log/nginx/
chown afterlogic:afterlogic -R /opt/afterlogic/var/log/nginx/
chmod 0775 -R /opt/afterlogic/var/log/nginx/

rm -f /etc/nginx/sites-enabled/default
cp /opt/afterlogic/templates/php-fpm-nginx.conf.j2 /etc/nginx/conf.d/php-fpm.conf
cp /opt/afterlogic/templates/afterlogic-webmail.conf.j2 /etc/nginx/sites-enabled/afterlogic-webmail
cp /opt/afterlogic/templates/nginx.conf.j2 /etc/nginx/nginx.conf

# - php.yml

PHPVER=$(php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")
cp -r  /etc/php/`echo $PHPVER` /etc/php/`echo $PHPVER`_distr

mkdir -p /opt/afterlogic/run/php-fpm
chown afterlogic:afterlogic -R /opt/afterlogic/run/php-fpm
chmod 0775 -R /opt/afterlogic/run/php-fpm

mkdir -p /var/log/php-fpm
chown afterlogic:afterlogic -R /var/log/php-fpm
chmod 0775 -R /var/log/php-fpm

mkdir -p /opt/afterlogic/var/run/php-fpm
chown afterlogic:afterlogic -R /opt/afterlogic/var/run/php-fpm
chmod 0775 -R /opt/afterlogic/var/run/php-fpm

cp /opt/afterlogic/templates/php.ini.j2 /etc/php/`echo $PHPVER`/fpm/php.ini
cp /opt/afterlogic/templates/php-fpm.conf.j2 /etc/php/`echo $PHPVER`/fpm/php-fpm.conf
cp /opt/afterlogic/templates/www.conf.j2 /etc/php/`echo $PHPVER`/fpm/pool.d/www.conf
sed -i -e "s/#phpver#/$PHPVER/g" /etc/php/`echo $PHPVER`/fpm/php-fpm.conf

(crontab -l 2>/dev/null; cat /opt/afterlogic/templates/scripts/cron-root)| crontab -

/etc/init.d/php`echo $PHPVER`-fpm restart
/etc/init.d/nginx restart

# - dovecot

cp -r /etc/dovecot /etc/dovecot_distr
cp -r /opt/afterlogic/templates/dovecot /etc/
rm -rf /etc/dovecot/conf.d/15-mailboxes.conf
sed -i -e "s/#mypassword#/$1/g" /etc/dovecot/dovecot-sql.conf 
sed -i -e "s/#mypassword#/$1/g" /etc/dovecot/dovecot-user-quota-dict.conf 

mkdir -p /opt/afterlogic/var/log/dovecot/
chown afterlogic:afterlogic -R /opt/afterlogic/var/log/dovecot/
chmod 0775 -R /opt/afterlogic/var/log/dovecot/

cp -r /opt/afterlogic/templates/scripts /opt/afterlogic/
chown afterlogic:afterlogic -R /opt/afterlogic/scripts
chmod 0755 -R /opt/afterlogic/scripts

mkdir -p /opt/afterlogic/data
chown afterlogic:afterlogic -R /opt/afterlogic/data
chmod 0755 -R /opt/afterlogic/data

/etc/init.d/dovecot restart

# - exim

cp -r  /etc/exim4 /etc/exim4_distr
cp -r /opt/afterlogic/templates/exim4 /etc/
sed -i -e "s/#mypassword#/$1/g" /etc/exim4/exim4.conf

mkdir -p /var/spool/exim4
chown afterlogic:afterlogic -R /var/spool/exim4
chmod 0755 -R /var/spool/exim4

mkdir -p /opt/afterlogic/var/log/exim
chown afterlogic:afterlogic -R /opt/afterlogic/var/log/exim
chmod 0755 -R /opt/afterlogic/var/log/exim

/etc/init.d/exim4 restart
/etc/init.d/spamassassin restart
