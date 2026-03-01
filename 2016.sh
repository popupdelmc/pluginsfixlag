#!/bin/bash
# Lemem Windows Server bootstrap - FIXED VERSION

set -e

user_passwd="$(echo "$HOSTNAME" | sed 's+-.*++g')"
egg_mode=true
alpine_hostname="lemem"
proot_url="https://proot.gitlab.io/proot/bin/proot"

get_arch() {
  case "$(uname -m)" in
    x86_64) echo "x86_64" ;;
    aarch64) echo "aarch64" ;;
    *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
  esac
}

get_latest_alpine_version() {
  curl -s "https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/$(get_arch)/" | \
    grep -oP 'alpine-minirootfs-\K[0-9]+\.[0-9]+\.[0-9]+(?=-'"$(get_arch)"')' | \
    sort -V | tail -n1
}

arch="$(get_arch)"
alpine_version="$(get_latest_alpine_version)"
mirror_alpine="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/$arch/alpine-minirootfs-$alpine_version-$arch.tar.gz"

install_path="$HOME"

die() {
  echo -e "\n\033[41m A FATAL ERROR HAS OCCURED \033[0m\n"
  exit 1
}

bootstrap_system() {

  echo "Extracting Alpine rootfs..."
  curl -L "$mirror_alpine" -o rootfs.tar.gz || die
  mkdir -p "$install_path"
  tar -xzf rootfs.tar.gz -C "$install_path" || die
  rm rootfs.tar.gz

  echo "Downloading proot..."
  curl -L "$proot_url" -o "$install_path/alpine" || die
  chmod +x "$install_path/alpine"

  mkdir -p "$install_path/home/container/shared"

  echo "$alpine_hostname" > "$install_path/etc/hostname"
  cp /etc/resolv.conf "$install_path/etc/resolv.conf" || true
  cp /etc/hosts "$install_path/etc/hosts" || true

  echo "Installing packages inside Alpine..."

  "$install_path/alpine" -r "$install_path" \
    -b /dev -b /sys -b /proc -b /tmp \
    -w /home/container /bin/sh -c "

    apk update &&
    apk add --no-cache \
      bash curl wget git python3 py3-pip \
      xorg-server xvfb xterm \
      qemu-system-x86_64 qemu-img \
      mesa-dri-gallium virtualgl &&

    git clone https://github.com/h3l2f/noVNC1 /home/container/noVNC1 &&

    cd /home/container/noVNC1 &&
    cp vnc.html index.html &&

    pip install websockify --break-system-packages &&

    wget -O /home/container/disk.qcow2 https://pub-cc2caec4959546c9b98850c80420b764.r2.dev/win2019.qcow2 &&
    wget -O /home/container/OVMF.fd https://cdn.bosd.io.vn/OVMF.fd
  " || die

  echo "Creating qemu password file..."

  echo "change vnc password" > "$install_path/home/container/qemu_cmd.txt"
  echo "$user_passwd" >> "$install_path/home/container/qemu_cmd.txt"

  echo "Bootstrap completed."
}

DOCKER_RUN="$install_path/alpine --kill-on-exit -r $install_path \
  -b /dev -b /proc -b /sys -b /tmp \
  -w /home/container /bin/sh -c"

run_system() {

  echo "Starting noVNC..."

  "$install_path/alpine" -r "$install_path" \
    -b /dev -b /proc -b /sys -b /tmp \
    -w /home/container/noVNC1 \
    /bin/sh -c "./utils/novnc_proxy --vnc 0.0.0.0:5901 --listen 0.0.0.0:$SERVER_PORT" &

  sleep 3

  echo "Server ready:"
  echo "http://$(curl -s checkip.pterodactyl-installer.se):$SERVER_PORT"
  echo "VNC password: $user_passwd"

  if [ ! -f "$install_path/home/container/qemu_cmd.txt" ]; then
    echo "Missing qemu_cmd.txt"
    exit 1
  fi

  echo "Starting VM..."

  $DOCKER_RUN "
    qemu-system-x86_64 \
      -device qemu-xhci \
      -device usb-tablet \
      -cpu host \
      -smp $(nproc) \
      -m ${VM_MEMORY:-2048} \
      -drive file=disk.qcow2,if=virtio \
      -drive file=OVMF.fd,format=raw,readonly=on,if=pflash \
      -device virtio-gpu-pci \
      -netdev user,id=n0 \
      -device virtio-net-pci,netdev=n0 \
      -display vnc=0.0.0.0:1,password \
      -monitor stdio < qemu_cmd.txt
  "
}

cd "$install_path"

if [ -f "$install_path/bin/sh" ]; then
  run_system
else
  bootstrap_system
fi
