#!/bin/bash
set -e
source /build/buildconfig
set -x

## Install init process.
cp /build/bin/my_init /sbin/
chmod 750 /sbin/my_init
mkdir -p /etc/my_init.d
mkdir -p /etc/container_environment
touch /etc/container_environment.sh
touch /etc/container_environment.json
chmod 700 /etc/container_environment

groupadd -g 8377 docker_env
chown :docker_env /etc/container_environment.sh /etc/container_environment.json
chmod 640 /etc/container_environment.sh /etc/container_environment.json
ln -s /etc/container_environment.sh /etc/profile.d/

## Install runit.
$minimal_apt_get_install runit

## Install a syslog daemon.
$minimal_apt_get_install syslog-ng-core
mkdir /etc/service/syslog-ng
cp /build/runit/syslog-ng /etc/service/syslog-ng/run
chmod +x /etc/service/syslog-ng/run
mkdir -p /var/lib/syslog-ng
cp /build/config/syslog_ng_default /etc/default/syslog-ng
touch /var/log/syslog
chmod u=rw,g=r,o= /var/log/syslog
cp /build/config/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf

## Install syslog to "docker logs" forwarder.
mkdir /etc/service/syslog-forwarder
cp /build/runit/syslog-forwarder /etc/service/syslog-forwarder/run
chmod +x /etc/service/syslog-forwarder/run

## Install logrotate.
$minimal_apt_get_install logrotate
cp /build/config/logrotate_syslogng /etc/logrotate.d/syslog-ng

## Install cron daemon.
$minimal_apt_get_install cron
mkdir /etc/service/cron
chmod 600 /etc/crontab
cp /build/runit/cron /etc/service/cron/run
chmod +x /etc/service/cron/run

## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
rm -f /etc/cron.daily/standard
rm -f /etc/cron.daily/upstart
rm -f /etc/cron.daily/dpkg
rm -f /etc/cron.daily/password
rm -f /etc/cron.weekly/fstrim 

apt-get clean
rm -rf /build
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup
