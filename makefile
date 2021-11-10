.PHONY : uefi_kernel
uefi_kernel : bin/kernelx64.elf

CRFLAGS= \
        --release               \
        --no-debug              \
        -Dkernel                \
        --cross-compile         \
        --target x86_64-unknown-linux-elf \
        --prelude ./prelude.cr  \
        --error-trace           \
        --mcmodel large         \
        -Ddisable_overflow

# We use clang to handle linking via LLD
CC = clang

# we want a freestanding executable with access to the full x64 address space
# https://eli.thegreenplace.net/2012/01/03/understanding-the-x64-code-models
CFLAGS+= \
        -target x86_64-unknown-linux-elf \
        -ffreestanding  \
        -mcmodel=large  \
        -fno-pic        \
        -O2             \
        -Wall           \
        -Wextra

# force use of LLVM Linker and output an ElF formatted file
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

bin/kernelx64.elf : bin/kernelx64.o
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

bin/kernelx64.o : $(KERNEL_SRC)
	crystal build $(CRFLAGS) src/kernel.cr -o bin/kernelx64
