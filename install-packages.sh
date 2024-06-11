#!/bin/bash
set -e -u

# Unpack cached apt archives if there are any.
if [[ -e /var-cache-apt-archives.tar ]]; then
    tar -C / -xf /var-cache-apt-archives.tar
fi

# Make some apt config changes so that deb files are cached so we can tar up
# those cached archives. 
mv /etc/apt/apt.conf.d/docker-clean /tmp
echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' \
    > /etc/apt/apt.conf.d/90-keep-downloads

# Install the OpenSCAD build prerequisites and some other things.
apt install -y vim libpulse-mainloop-glib0
/sources/scripts/uni-get-dependencies.sh

# Tar up the debian archives to prevent repeated `docker build` commands from
# downloading the archives every time.
tar cf /var-cache-apt-archives.tar /var/cache/apt/archives
md5sum /var-cache-apt-archives.tar \
    | awk '{print $1 " /host/var-cache-apt-archives.tar"}' \
    > /var-cache-apt-archives.tar.md5

# Put things back where we found them - restore the apt config.
rm /etc/apt/apt.conf.d/90-keep-downloads
mv /tmp/docker-clean /etc/apt/apt.conf.d/

# Remove the archives, since we no longer need them.
rm /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb >/dev/null 2>&1 || true

# Run OpenSCAD's dependency checker script to validate we have everything
# needed.
/sources/scripts/check-dependencies.sh
