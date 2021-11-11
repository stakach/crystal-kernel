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

echo "---------------------"
echo "-> building bootstrap"
echo "---------------------"
cd bootstrap
./build.sh || exit_code="$?"
cd ..
mv ./bootstrap/bin/efi ./bin/efi

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
hdiutil create -fs fat32 -ov -size 48m -volname CRYOS -format UDTO -srcfolder bin disk.cdr || exit_code="$?"

# TODO:: Linux
# create disk image (64MB)
# dd if=/dev/zero of=bin/disk.img bs=1048576 count=64

# format as FAT32 (this won't work as we need it to be a GPT format)
# mformat -F -i bin/disk.img ::

# add the required folders and files
# NOTE:: to list image files run `mdir -i bin/disk.img ::/efi/boot`
#mmd -i bin/disk.img efi
#mmd -i bin/disk.img efi/boot
#mcopy -i bin/disk.img bin/kernelx64.elf ::/kernelx64.elf
#mcopy -i bin/disk.img bin/efi/boot/bootx64.efi ::/efi/boot/bootx64.efi
#mcopy -i bin/disk.img bin/efi/boot/bootaa64.efi ::/efi/boot/bootaa64.efi

echo "### DONE!"
exit ${exit_code}
