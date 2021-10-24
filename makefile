.PHONY : uefi_kernel
uefi_kernel : bin/kernel.elf

CRFLAGS= \
        --release \
        --no-debug \
        -Dkernel \
				--cross-compile \
				--target x86_64-unknown-linux-elf \
				--prelude ./prelude.cr \
				--error-trace \
				--mcmodel large \
				-Ddisable_overflow

# we want to use clang and output a PE/COFF formatted file
# these are the zig flags
CC = clang

# we want a freestanding executable with access to the full x64 address space
# https://eli.thegreenplace.net/2012/01/03/understanding-the-x64-code-models
CFLAGS+= \
        -target x86_64-unknown-linux-elf \
        -ffreestanding \
				-mcmodel=large \
				-fno-pic       \
				-O2            \
				-Wall          \
				-Wextra

# force use of LLVM Linker and output a PE/COFF formatted file
LDFLAGS+= \
        -target x86_64-unknown-linux-elf \
        -nostdlib               \
				-static                 \
				-ffreestanding          \
				-O2                     \
				-T kernel.ld            \
				-z max-page-size=0x1000 \
        -Wl,-ekernel_main       \
        -fuse-ld=lld

KERNEL_SRC=$(wildcard src/*.cr src/*/*.cr)

bin/kernel.elf : bin/kernel.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

bin/kernel.o : $(KERNEL_SRC)
	crystal build $(CRFLAGS) src/kernel.cr -o bin/kernel
