#!/bin/bash

ROOTFS_DIR=$(pwd)
export PATH=$PATH:$HOME/.local/usr/bin
max_retries=50
timeout=15
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: %s\n" "$ARCH"
  exit 1
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "#######################################################################################"
  echo "#                                                                                     #"
  echo "#                                      Proot INSTALLER                                #"
  echo "#                                                                                     #"
  echo "#                                    Copyright (C) 2024                               #"
  echo "#                                                                                     #"
  echo "#                                                                                     #"
  echo "#######################################################################################"
  printf "Do you want to install Ubuntu? (YES/no): "
  read install_ubuntu

  case $install_ubuntu in
    [yY][eE][sS])
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
        "http://cdimage.ubuntu.com/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.4-base-${ARCH_ALT}.tar.gz"

      if [ ! -f /tmp/rootfs.tar.gz ]; then
        echo "Download failed"
        exit 1
      fi

      tar -xf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
      ;;
    *)
      echo "Skipping Ubuntu installation."
      ;;
  esac

  mkdir -p "$ROOTFS_DIR/usr/local/bin"

  wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" \
    "https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm -rf "$ROOTFS_DIR/usr/local/bin/proot"
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" \
      "https://raw.githubusercontent.com/Mytai20100/freeroot/main/proot-${ARCH}"
    sleep 1
  done

  chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"

  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" > "$ROOTFS_DIR/etc/resolv.conf"

  rm -rf /tmp/rootfs.tar.gz /tmp/rootfs.tar.xz /tmp/sbin

  touch "$ROOTFS_DIR/.installed"
fi

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"
CYAN="\033[0;36m"
WHITE="\033[0;37m"
RESET_COLOR="\033[0m"

OS_VERSION=$(lsb_release -ds 2>/dev/null || echo "N/A")
CPU_NAME=$(lscpu 2>/dev/null | awk -F: '/Model name:/ {print $2}' | sed 's/^ //')
CPU_ARCH=$(uname -m)
CPU_USAGE=$(top -bn1 2>/dev/null | awk '/Cpu\(s\)/ {print $2 + $4}')
TOTAL_RAM=$(free -h --si 2>/dev/null | awk '/^Mem:/ {print $2}')
USED_RAM=$(free -h --si 2>/dev/null | awk '/^Mem:/ {print $3}')
DISK_SPACE=$(df -h / 2>/dev/null | awk 'NR==2 {print $2}')
USED_DISK=$(df -h / 2>/dev/null | awk 'NR==2 {print $3}')
PORTS=$(ss -tunlp 2>/dev/null | tail -n +2 | wc -l)
IP_ADDRESS=$(hostname -I 2>/dev/null | awk '{print $1}')

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e "           ${CYAN}-----> Mission Completed ! <----${RESET_COLOR}"
}

display_version() {
  echo -e "${WHITE}_______________________________________________________________________${RESET_COLOR}"
  echo -e "${CYAN}OS:${RESET} $OS_VERSION"
  echo -e "${CYAN}CPU:${RESET} $CPU_NAME [$CPU_ARCH]"
  echo -e "${CYAN}Used CPU:${RESET} ${CPU_USAGE}%"
  echo -e "${GREEN}RAM:${RESET} $USED_RAM / $TOTAL_RAM"
  echo -e "${YELLOW}Disk:${RESET} $USED_DISK / $DISK_SPACE"
  echo -e "${RED}Ports:${RESET} $PORTS"
  echo -e "${RED}IP:${RESET} $IP_ADDRESS"
  echo -e "${WHITE}_______________________________________________________________________${RESET_COLOR}"
}

clear
display_version
echo ""
display_gg

exec "$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="$ROOTFS_DIR" \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  --kill-on-exit
