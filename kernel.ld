
mmio        = 0xfffffffff5000000;
fb          = 0xfffffffff9000000;
bootboot    = 0xfffffffffe000000;
environment = 0xfffffffffe002000;
initstack   = 0x4000;

PHDRS
{
  /* one single loadable segment */
  boot PT_LOAD;
}

SECTIONS
{
  . = 0xffffffffff000000;
  _KERNEL_START = .;

  .text : ALIGN (4K) {
    _TEXT_START = .;
    *(.text*)
    . = ALIGN(4K);
    _TEXT_END = .;

    _DATA_START = .;
    *(.data .data.*)
    . = ALIGN(4K);
    _DATA_END = .;

    _RODATA_START = .;
    *(.rodata .rodata.*)
    *(.gcc_except_table)
    *(.got*)

    /** pointers to various sections of this file. */
    text_start = .; QUAD(_TEXT_START)
    text_end = .;   QUAD(_TEXT_END)

    data_start = .; QUAD(_DATA_START)
    data_end = .;   QUAD(_DATA_END)

    rodata_start = .; QUAD(_RODATA_START)
    rodata_end = .;   QUAD(_RODATA_END)

    bss_start = .; QUAD(_BSS_START)
    bss_end = .;   QUAD(_BSS_END)

    kernel_start = .; QUAD(_KERNEL_START)
    kernel_end = .; QUAD(_KERNEL_END)

    . = ALIGN(4K);
    _RODATA_END = .;
  } :boot

  .bss (NOLOAD) : ALIGN (4K) {
    _BSS_START = .;
    *(COMMON)
    *(.bss*)
    . = ALIGN(4K);
    _BSS_END = .;
  } :boot

  _KERNEL_END = .;

  .debug (NOLOAD) : {
    *(.debug*)
  }

  /DISCARD/ : { *(.eh_frame_hdr) *(.eh_frame) *(.comment) }
}
