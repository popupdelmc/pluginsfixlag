
## Setting up a Workspace
- Run No Root:
    - For Run: `./usr/local/bin/proot --rootfs=. -0 -w /root -b /dev -b /sys -b /proc -b /etc/resolv.conf /bin/bash`
    - Fix 'rm -rf /var/lib/ucf/*
mkdir -p /var/lib/ucf/cache
chmod -R 777 /var/lib/ucf'
    - End fix 'dpkg --configure -a'
- Sshx Setup
    - Download: 'curl -O https://sshx.io/get'
    - Run: 'sh get run'
