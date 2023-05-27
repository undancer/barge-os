#!/bin/bash
set -e -x

IMAGES=$1

ISO=${IMAGES}/iso

mkdir -p ${ISO}/boot
cp ${IMAGES}/bzImage ${ISO}/boot/bzImage

ROOTFS=/tmp/root
mkdir -p ${ROOTFS}
tar xJf ${IMAGES}/rootfs.tar.xz -C ${ROOTFS}
cd ${ROOTFS}
find | cpio -H newc -o | xz -9 -C crc32 -c > ${ISO}/boot/initrd

mkdir -p ${ISO}/boot/isolinux
# cp /usr/lib/syslinux/isolinux.bin ${ISO}/boot/isolinux/
# cp /usr/lib/syslinux/linux.c32 ${ISO}/boot/isolinux/ldlinux.c32
cp /usr/lib/ISOLINUX/isolinux.bin ${ISO}/boot/isolinux/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 ${ISO}/boot/isolinux/ldlinux.c32

cp /build/configs/isolinux.cfg ${ISO}/boot/isolinux/

# Make an ISO
cd ${ISO}
xorriso \
  -publisher "A.I. <ailis@paw.zone>" \
  -as mkisofs \
  -l -J -R -V "BARGE" \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -b boot/isolinux/isolinux.bin \
  -c boot/isolinux/boot.cat \
  -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
  -no-pad -o ${IMAGES}/barge.iso $(pwd)

  # -b boot/isolinux/isolinux.bin \
  # -isohybrid-mbr /usr/lib/syslinux/isohdpfx.bin \

# Make a bootable disk image
IMAGE=${IMAGES}/barge.img
DISK=${IMAGES}/disk
ISO=${IMAGES}/ISO

df -h .

mkdir -p ${ISO}
loop0=$(losetup -f)
losetup $loop0 ${IMAGES}/barge.iso
mount $loop0 ${ISO}

SIZE=$(du -s ${ISO} | awk '{print $1}')

dd if=/dev/zero of=${IMAGE} bs=1024 count=$((${SIZE}+68+${SIZE}%2))
loop1=$(losetup -f)
losetup $loop1 ${IMAGE}
(echo c; echo n; echo p; echo 1; echo; echo; echo t; echo 4; echo a; echo w;) | fdisk $loop1 || true

loop2=$(losetup -f)
losetup -o 32256 $loop2 ${IMAGE}
mkfs -t vfat -F 16 $loop2

mkdir -p ${DISK}
mount -t vfat $loop2 ${DISK}

mkdir -p ${DISK}/boot/syslinux
cp ${ISO}/boot/bzImage ${DISK}/boot/
cp ${ISO}/boot/initrd ${DISK}/boot/
cp ${ISO}/boot/isolinux/isolinux.cfg ${DISK}/boot/syslinux/syslinux.cfg
umount ${ISO}
umount ${DISK}

syslinux -i -d /boot/syslinux $loop2 2> ${IMAGES}/error.log
cat ${IMAGES}/error.log >&2
losetup -d $loop2
# dd if=/usr/lib/syslinux/mbr.bin of=$loop1 bs=440 count=1
dd if=/usr/lib/SYSLINUX/mbr.bin of=$loop1 bs=440 count=1
losetup -d $loop1
losetup -d $loop0

if [ -s ${IMAGES}/error.log ]; then
  echo "----------SIGN----------"
  cat ${IMAGES}/error.log
  echo "----------SIGN----------"
  exit 1
fi
