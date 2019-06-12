#!/bin/sh

if [ -z "$IN_CHROOT" ]; then
	echo "Error: don't run this directly!" >&2
	exit 1
fi

cat <<EOF > /etc/apt/sources.list
deb http://archive.ubuntu.com/ubuntu $DISTRO main
deb http://archive.ubuntu.com/ubuntu $DISTRO universe
EOF

apt-get update || exit 1

apt-get install -y --no-install-recommends $HOST_PACKAGES || exit 1
apt-get install -y --no-install-recommends $TARGET_PACKAGES || exit 1
