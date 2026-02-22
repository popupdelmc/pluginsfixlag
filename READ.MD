Run : ./usr/local/bin/proot --rootfs=. -0 -w /root -b /dev -b /sys -b /proc -b /etc/resolv.conf /bin/bash
Debian : curl -L -o /tmp/rootfs.tar.gz https://cdimage.ubuntu.com/ubuntu-base/releases/22.04.5/release/ubuntu-base-22.04.5-base-amd64.tar.gz
Debian 2 : tar -xzf /tmp/rootfs.tar.gz -C .
