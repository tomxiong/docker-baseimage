#!/bin/bash
set -e
source /build/buildconfig
set -x

apt-get clean
rm -rf /build
rm -rf /tmp/* /var/tmp/*
rm -rf /var/lib/apt/lists/*
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup
# removing more stuff
rm -rf /usr/share/man /usr/share/groff /usr/share/info
rm -rf /usr/share/lintian /usr/share/linda /var/cache/man
(( find /usr/share/doc -depth -type f ! -name copyright|xargs rm || true ) && ( find /usr/share/doc -empty|xargs rmdir || true ))
