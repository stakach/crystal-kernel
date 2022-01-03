lib BootBoot
  enum FrameBufferType : UInt8
    ARGB = 0 # Addressable RGB
    RGBA = 1 # RGB with an Alpha channel
    ABGR = 2
    BGRA = 3
  end

  enum ProtocolLevel : UInt8
    Minimal = 0
    Static  = 1
    Dynamic = 2
  end

  enum LoaderType : UInt8
    BIOS        = 0
    UEFI        = 1
    RaspberryPi = 2
    CoreBoot    = 3
  end

  # check this flag in the protocol byte
  PROTOCOL_BIG_ENDIAN = 0x80_u8

  struct MemoryMapEntry
    address : UInt64
    flags : UInt64
  end

  struct Info
    magic : UInt32   # 'BOOT' magic
    size : UInt32    # length of bootboot structure, minimum 128
    protocol : UInt8 # a packed structure (ProtocolLevel + LoaderType << 2)
    framebuffer_type : FrameBufferType
    cpu_core_count : UInt16         # number of processor cores
    bootstrap_processor_id : UInt16 # Local APIC Id on x86_64, CPU that should setup the kernel
    timezone : Int16                # in minutes -1440..1440
    datetime : Tuple(               # in BCD yyyymmddhhiiss UTC
UInt8,                              # year high
UInt8,                              # year low
UInt8,                              # month
UInt8,                              # day
UInt8,                              # hour
UInt8,                              # mins
UInt8,                              # seconds
UInt8                               # daylight savings
)
    initrd_ptr : UInt64 # ramdisk image position and size
    initrd_size : UInt64
    frame_buffer_ptr : UInt64 # framebuffer pointer and dimensions
    frame_buffer_size : UInt32
    frame_buffer_width : UInt32
    frame_buffer_height : UInt32
    frame_buffer_scanline : UInt32

    {% if flag?(:x86_64) %}
      acpi_ptr : UInt64
      smbi_ptr : UInt64
      efi_ptr : UInt64
      mp_ptr : UInt64
      unused0 : UInt64
      unused1 : UInt64
      unused2 : UInt64
      unused3 : UInt64
    {% elsif flag?(:aarch64) %}
      acpi_ptr : UInt64
      mmio_ptr : UInt64
      efi_ptr : UInt64
      unused0 : UInt64
      unused1 : UInt64
      unused2 : UInt64
      unused3 : UInt64
      unused4 : UInt64
    {% else %}
      {% raise "architecture not currently supported" %}
    {% end %}

    # More entries follow this one
    # until you reach bootboot.size, while(mmap_entry < bootboot + bootboot.size)
    memory_map : MemoryMapEntry
  end

  $bootboot : Info
end
