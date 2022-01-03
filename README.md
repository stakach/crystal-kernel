# Crystal Kernel

Extending on the work started with https://github.com/ffwff/lilith/

## Usage

* this kernel is designed to work with [BOOTBOOT](https://gitlab.com/bztsrc/bootboot/) to keep the boot process simple


## Building

The kernel is expected to be a standard ELF executable

* BOOTBOOT expects a single loadable segment
* Internally virtual segments are maintained and 4kb aligned - for paging protection
* the entry point takes no params and returns void
* boot and machine information is provided at a specific location by BOOTBOOT

to build run `./build.sh`


## Development on macOS

Install some base tools

```
brew install crystal
brew install qemu
brew install gdb
```

Download the [UEFI BIOS](https://www.kraxel.org/repos/jenkins/edk2/), extract using something like 7zip to get

* OVMF-pure-efi.fd for x64
* QEMU_EFI-pflash.raw for aarch64


### Running the kernel using QEMU

build the kernel

```
./build.sh
```

Can run the VM in a [few different ways](https://wiki.gentoo.org/wiki/QEMU/Options)

* View the VM using [VNC](https://www.realvnc.com/en/connect/download/viewer/)
  * `qemu-system-x86_64 -cpu qemu64 -bios ../OVMF-pure-x64-efi.fd -drive file=./disk.cdr,if=ide -display vnc=127.0.0.1:0`
  * connect to it using `localhost` (uses default port)
* With GDB debugging support:
  * `qemu-system-x86_64 -cpu qemu64 -bios ../OVMF-pure-x64-efi.fd -drive file=./disk.cdr,if=ide -display vnc=127.0.0.1:0 -s -S`
  * it waits for GDB to connect before starting

```
gdb
file ./bin/bootboot/X86_64
target remote tcp::1234
continue
```

### Inspecting the ELF file output

* `objdump -s bin/bootboot/X86_64`
* `x86_64-elf-readelf -hls bin/bootboot/X86_64`
* http://www.sunshine2k.de/coding/javascript/onlineelfviewer/onlineelfviewer.html

To check for bootboot compatibility

* `./mkbootimg check bin/bootboot/X86_64`
