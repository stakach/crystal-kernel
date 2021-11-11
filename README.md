# Crystal Kernel

Extending on the work started with https://github.com/ffwff/lilith/

## Usage

* this kernel is designed to work with [UEFI Bootstrap](https://github.com/stakach/uefi-bootstrap) to keep the boot process simple


## Building

The kernel is expected to be a standard ELF executable

* Segments need to be 4kb aligned - for paging support
* the entry point takes no params and returns void
* the boot_info structure is going to be stored at address 1MB

to build run `./build.sh`


## Development on macOS

Install some base tools

```
brew install crystal
brew install qemu
brew install zig
brew install gdb
```

Download the [UEFI BIOS](https://www.kraxel.org/repos/jenkins/edk2/), extract using something like 7zip to get the OVMF-pure-efi.fd

### Running the kernel using QEMU

build the kernel

```
./build.sh
```

Can run the VM in a [few different ways](https://wiki.gentoo.org/wiki/QEMU/Options)

* View the VM using [VNC](https://www.realvnc.com/en/connect/download/viewer/)
  * `qemu-system-x86_64 -cpu qemu64 -bios OVMF-pure-x64-efi.fd -drive file=./crystal_kernel/disk.cdr,if=ide -display vnc=127.0.0.1:0`
  * connect to it using `localhost` (uses default port)
* With GDB debugging support:
  * `qemu-system-x86_64 -cpu qemu64 -bios OVMF-pure-x64-efi.fd -drive file=./crystal_kernel/disk.cdr,if=ide -display vnc=127.0.0.1:0 -s -S`
  * it waits for GDB to connect before starting

```
gdb
file ./bin/kernelx64.elf
target remote tcp::1234
continue
```
