#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

install_debian="YES"

if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                      DEBIAN INSTALLER"
  echo "#"
  echo "#######################################################################################"
fi

case $install_debian in
  [yY][eE][sS])
    echo "Downloading Debian..."

    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.xz \
      "https://deb.debian.org/debian/dists/bookworm/main/installer-${ARCH_ALT}/current/images/netboot/netboot.tar.gz"

    echo "Extracting..."
    tar -xf /tmp/rootfs.tar.xz -C $ROOTFS_DIR
    ;;
  *)
    echo "Skipping Debian installation."
    ;;
esac

if [ ! -e $ROOTFS_DIR/.installed ]; then
  mkdir -p $ROOTFS_DIR/usr/local/bin

  echo "Downloading proot..."
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot \
    "https://proot.gitlab.io/proot/bin/proot"

  chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

if [ ! -e $ROOTFS_DIR/.installed ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.xz
  touch $ROOTFS_DIR/.installed
fi

clear
echo "Debian Ready!"

$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc \
  -b /etc/resolv.conf \
  /bin/bash
