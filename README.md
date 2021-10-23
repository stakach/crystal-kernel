# Crystal Kernel

Extending on the work started with https://github.com/ffwff/lilith/

## Usage

* this kernel is designed to work with [UEFI Bootstrap](https://github.com/stakach/uefi-bootstrap) to keep the boot process simple


## Building

The kernel is expected to be a standard ELF executable

* Segments need to be 4kb aligned - for paging support
* the entry point takes no params and returns void
* the boot_info structure is going to be stored at address 1MB

to build run `make`

## Prerequisites

Very easy to test and run on Windows with [VirtualBox](https://www.virtualbox.org/)

* Compile on Win Linux layer, macOS or Linux
* Clang + LLVM toolchain
* requires [Zig lang](https://ziglang.org/download/) for the bootstrap
* require [Crystal lang](https://crystal-lang.org/install/) for the kernel
