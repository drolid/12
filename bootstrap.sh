#!/bin/bash

[ -z "$1" -o ! -d "$1" ] && echo "./bootstrap.sh <mountpoint>" && exit 1

main() {

    local petitboot_label="Debian 12 [bookworm] - Main"
    local srcdir="$PWD"
    local dstdir="$1"

    # Basic checks   
    [ -f "initscript.sh" -a -d "rootfs" -a -d "schroot" -a -d "$dstdir" ] || { echo "Not in the script root, or files missing."; exit 0; }
    # check net

    local src_disk_uuid=$(lsblk -o UUID -n $(findmnt -T $srcdir -o source -n))

    local dst_disk=$(findmnt $dstdir -o source -n)
    [ -z $dst_disk ] && echo "Bad mount point: $dstdir." && exit 0
    local dst_disk_uuid=$(lsblk -o UUID -n $dst_disk)
    [ -z $dst_disk_uuid ] && echo "Bad uuid. Fatal error" && exit 0

    local dst_disk_type=$(findmnt $dstdir -o fstype -n)
    local dst_disk_size=$(findmnt $dstdir -o size -n)

    echo "src_disk_uuid: $src_disk_uuid"
    echo "dst_disk_uuid / type / size : $dst_disk_uuid / $dst_disk_type / $dst_disk_size"

    [ $src_disk_uuid == $dst_disk_uuid  ] && { echo "Error: src and dst on the same partition!"; exit 1; }

    # Prerequisites
    check_installed 'schroot' 'u-boot-tools' 'pv' 'wget' 'xz-utils'

    # Debootstrap
    # debootstrap --arch arm64 "bookworm" "$dstdir" 'https://deb.debian.org/debian/'

    # Generate boot.txt
    echo "----Boot Script---"
    echo "$(script_boot_txt "$dst_disk_uuid" true "$petitboot_label")" | tee rootfs/boot/boot.txt

    # fstab
    echo -e "UUID=$dst_disk_uuid\t$dst_disk_type\terrors=remount-ro\t0\t1" | tee rootfs/etc/fstab

    # schroot
    sch_cfg="schroot/chroot.d/odroid-m1-bookworm.conf"
    [ -f $sch_cfg ] && rm $sch_cfg
    echo "$(script_schroot $dstdir)" > schroot/chroot.d/odroid-m1-bookworm.conf

    # Copy configuration
    echo "----Config Files----"
    rsync -av rootfs/ $dstdir/


    ln -s $srcdir/schroot/chroot.d/odroid-m1-bookworm.conf /etc/schroot/chroot.d/
    ln -s $srcdir/schroot/odroid /etc/schroot/

    schroot -c m1root --directory /root schroot_initscript.sh
    sync
    umount $dstdir
    echo "done! - reboot"
}



# check if utility program is installed
check_installed() {
    local todo
    echo -n "Prerequisites installed: "
    for item in "$@"; do
        dpkg -l "$item" 2>/dev/null | grep -q "ii  $item" || todo="$todo $item"
        [ ! -z "$item" ] && echo -n "$item "
    done

    if [ ! -z "$todo" ]; then
        echo "this script requires the following packages:${bld}${yel}$todo${rst}"
        echo "   run: ${bld}${grn}apt update && apt -y install$todo${rst}\n"
        exit 1
    fi
    echo ""
}


script_boot_txt() {
    local uuid=$1
    local no_ipv6="$([ "$2" = "true" ] && echo ' ipv6.disable=1')"
    local petitboot_label=$3


    cat <<-EOF
# after modifying, run ./mkscr.sh

if test -z "\${variant}"; then
    setenv variant m1
fi

setenv board odroid\${variant}

setenv bootlabel "$petitboot_label"
setenv uuid "$uuid"

setenv bootargs "console=ttyS2,1500000 root=UUID=\${uuid} rw rootwait$no_ipv6 pci=nomsi"

if load \${devtype} \${devnum}:\${partition} \${kernel_addr_r} /boot/vmlinuz; then
    if load \${devtype} \${devnum}:\${partition} \${fdt_addr_r} /boot/dtb; then
        if load \${devtype} \${devnum}:\${partition} \${ramdisk_addr_r} /boot/initrd.img; then
            booti \${kernel_addr_r} \${ramdisk_addr_r}:\${filesize} \${fdt_addr_r};
        else
            booti \${kernel_addr_r} - \${fdt_addr_r};
        fi;
    fi;
fi
	EOF
}

script_schroot() {
  local dstdir="$1"

cat <<-EOF
[m1root]
description=Debian Bookworm
type=directory
directory=$dstdir
users=root
groups=root
root-groups=root
profile=odroid
EOF
}


main







