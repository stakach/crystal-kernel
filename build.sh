#! /usr/bin/env bash

set -e

# this function is called when Ctrl-C is sent
function trap_ctrlc ()
{
    echo "### build cancelled..."
    exit 2
}

# initialise trap to call trap_ctrlc function
# when signal 2 (SIGINT) is received
trap "trap_ctrlc" 2

exit_code="0"
echo "### building kernel"
echo "-> cleaning bin folder"
rm -rf ./bin
mkdir bin


echo "-----------------------"
echo "-> configuring bootboot"
echo "-----------------------"
mkdir -p .tmp
FILE=./.tmp/bootboot.efi
if [ -f "$FILE" ]; then
    echo "* BOOTBOOT found"
else
    echo "* downloading BOOTBOOT..."
    curl "https://gitlab.com/bztsrc/bootboot/raw/master/dist/bootboot.efi" --output "$FILE"
fi
mkdir -p bin/efi/boot
mkdir -p bin/bootboot
cp ./.tmp/bootboot.efi ./bin/efi/boot/bootx64.efi

echo "-------------------------"
echo "-> building x86_64 kernel"
echo "-------------------------"
make || exit_code="$?"
rm bin/kernelx64.o

# Building images
# https://wiki.osdev.org/UEFI#Emulation_with_QEMU_and_OVMF
# https://github.com/tianocore/tianocore.github.io/wiki/How-to-run-OVMF

echo "----------------------"
echo "-> creating disk image"
echo "----------------------"
# TODO:: detect if running on MacOS
# hdiutil create -fs fat32 -ov -size 64m -volname CRYOS -format UDTO -srcfolder bin disk.cdr || exit_code="$?"

# Debian Linux: apt install systemd-container mtools binutils
# create disk image (64MB)
dd if=/dev/zero of=bin/disk.img bs=1M count=64

# create a fat32 partition
parted bin/disk.img < partition-cmds.txt

# format the disk, specifying start of the partition (2048s == 2048 x 512 byte sector)
mformat -F -i bin/disk.img@@2048s ::

# add the required folders and files
# NOTE:: to list image files run `mdir -i bin/disk.img@@2048s ::/efi/boot`
mmd -i bin/disk.img@@2048s efi
mmd -i bin/disk.img@@2048s efi/boot
mmd -i bin/disk.img@@2048s bootboot
mcopy -i bin/disk.img@@2048s bin/bootboot/X86_64 ::/bootboot/X86_64
mcopy -i bin/disk.img@@2048s bin/efi/boot/bootx64.efi ::/efi/boot/bootx64.efi
# mcopy -i bin/disk.img@@2048s bin/efi/boot/bootaa64.efi ::/efi/boot/bootaa64.efi

echo "### DONE!"
exit ${exit_code}
