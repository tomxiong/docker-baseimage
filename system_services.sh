#!/bin/bash

export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive
minimal_apt_get_install='apt-get install -y --no-install-recommends'

minimal_apt_get_install update
minimal_apt_get_install upgrade

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

## Install cron daemon.
mkdir -p /etc/service/cron
mkdir -p /etc/service/cron/log
mkdir -p /var/log/cron
chmod 600 /etc/crontabs
cp /build/runit/cron /etc/service/cron/run
cp /build/runit/cron_log /etc/service/cron/log/run
cp /build/config/cron_log_config /var/log/cron/config
chown -R cron  /var/log/cron
chmod +x /etc/service/cron/run /etc/service/cron/log/run

## Remove useless cron entries.  Need to check if this still apply ... 
# Checks for lost+found and scans for mtab.
rm -f /etc/cron.daily/standard
rm -f /etc/cron.daily/upstart
rm -f /etc/cron.daily/dpkg
rm -f /etc/cron.daily/password
rm -f /etc/cron.weekly/fstrim 

## Often used tools.
$minimal_apt_get_install curl less nano psmisc wget

#cleanup
apt-get clean
rm -rf /build
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup
