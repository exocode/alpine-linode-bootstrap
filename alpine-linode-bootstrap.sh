#!/bin/sh

HOST=${HOST:-alpine}
INTERFACES="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
  hostname $HOST
"

ALPINE_VER=${ALPINE_VER:-"latest-stable"}
APK_TOOLS_VER=${APK_TOOLS_VER:-"2.6.8-r2"}
ARCH=$(uname -m)
MIRROR="http://nl.alpinelinux.org/alpine"

BOOT_DEV="/dev/sda"
ROOT_DEV="/dev/sdb"
SWAP_DEV="/dev/sdc"

mkdir /alpine
mount $ROOT_DEV /alpine
cd /alpine
mkdir boot
mkdir etc
mount $BOOT_DEV /alpine/boot

echo "calling: $MIRROR/$ALPINE_VER/main/$ARCH/apk-tools-static-${APK_TOOLS_VER}.apk"

curl -s $MIRROR/$ALPINE_VER/main/$ARCH/apk-tools-static-${APK_TOOLS_VER}.apk | tar xz
./sbin/apk.static --repository $MIRROR/$ALPINE_VER/main/ --update-cache --allow-untrusted --root /alpine --initdb add alpine-base alpine-mirrors



cat << EOF > /alpine/etc/fstab
$ROOT_DEV    /   ext4    defaults,noatime    0   0
$BOOT_DEV    /boot   ext4    defaults,noatime    0  1
$SWAP_DEV    swap    swap    defaults    0   0
EOF

cat << EOF > /alpine/etc/inittab
# /etc/inittab
    
::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default
    
# Put a getty on the serial port
ttyS0::respawn:/sbin/getty -L ttyS0 115200 vt100
    
# Stuff to do for the 3-finger salute
::ctrlaltdel:/sbin/reboot
    
# Stuff to do before rebooting
::shutdown:/sbin/openrc shutdown
EOF

mkdir /alpine/boot/grub
cat << EOF > /alpine/boot/grub/grub.cfg
set root=(hd0)
set default="Alpine Linux"
set timeout=0
    
menuentry "Alpine Linux" {
          linux /vmlinuz-grsec root=/dev/sdb modules=sd-mod,usb-storage,ext4 console=ttyS0 quiet
          initrd /initramfs-grsec
}
EOF

mkdir /alpine/etc/mkinitfs
cat << EOF > /alpine/etc/mkinitfs/mkinitfs.conf
features="ata ide scsi virtio base ext4"
EOF

cp /etc/resolv.conf /alpine/etc/resolv.conf

echo ttyS0 >> /alpine/etc/securetty

# This is only a "hack" because of this issue:
# http://bugs.alpinelinux.org/issues/6488
cat << EOF > /alpine/etc/init.d/ip-resolve-hack
#!/sbin/openrc-run
start() {
        ebegin "Resolving IP address"
        eindent
        ifdown -f eth0 && ifup -f eth0
        eend
}
EOF


mount --bind /proc /alpine/proc
mount --bind /dev /alpine/dev

chroot /alpine /bin/sh<<CHROOT

setup-apkrepos -r
apk update

setup-hostname -n $HOST
printf "hostname: $HOST "
printf "$INTERFACES" | setup-interfaces -i

rc-update add networking boot
rc-update add urandom boot
rc-update add crond
rc-update add ip-resolve-hack boot

apk add linux-grsec

CHROOT
