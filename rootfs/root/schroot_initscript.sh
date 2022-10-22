#!/bin/bash

apt-get update
apt -y full-upgrade
apt -y install /opt/linux-*.deb 

apt -y install openssh-server sudo wget unzip u-boot-tools systemd-timesyncd \
tmux lbzip2 pigz nmon htop iftop iptraf-ng git build-essential apt-file \
man-db nmap bash-completion rsync vim cmake distcc ccache psmisc schroot bc \
meson pkg-config evtest parted netcat-openbsd cargo curl pciutils usbutils dnsutils xfsprogs smartmontools \
tcpdump lsof strace kpartx initramfs-tools

# Generate initramfs
update-initramfs -k all -c

cd /boot
ln -s initrd.img-* initrd.img
ln -s vmlinuz-* vmlinuz
ln -s rk3568-odroid-m1.dtb dtb
./mkscr.sh

# flash-kernel initranfs-tools

#useradd -m "$uid" -p \$(echo "$pass" | openssl passwd -6 -stdin) -s /bin/bash
#echo "$uid ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$uid
#chmod 600 /etc/sudoers.d/$uid

