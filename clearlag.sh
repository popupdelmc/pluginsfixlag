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

# 👇 MẶC ĐỊNH LUÔN LÀ YES
install_ubuntu="YES"

if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                      Ubuntu INSTALLER"
  echo "#"
  echo "#                           Copyright (C) 2025"
  echo "#"
  echo "#######################################################################################"
fi

case $install_ubuntu in
  [yY][eE][sS])
    echo "Downloading Ubuntu..."
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      "https://cdimage.ubuntu.com/ubuntu-base/releases/22.04.5/release/ubuntu-base-22.04.5-base-${ARCH_ALT}.tar.gz"

    echo "Extracting..."
    tar -xzf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
    ;;
  *)
    echo "Skipping Ubuntu installation."
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
  rm -rf /tmp/rootfs.tar.gz
  touch $ROOTFS_DIR/.installed
fi

clear
echo "Ubuntu Ready!"

$ROOTFS_DIR/usr/local/bin/proot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc \
  -b /etc/resolv.conf \
  /bin/bash
