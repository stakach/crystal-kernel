lib BootBoot
  enum FrameBufferType : UInt8
    ARGB = 0 # Addressable RGB
    RGBA = 1 # RGB with an Alpha channel
    ABGR = 2
    BGRA = 3
  end

  enum ProtocolLevel : UInt8
    Minimal = 0
    Static = 1
    Dynamic = 2
  end

  enum LoaderType : UInt8
    BIOS = 0
    UEFI = 1
    RaspberryPi = 2
    CoreBoot = 3
  end

  # check this flag in the protocol byte
  PROTOCOL_BIG_ENDIAN = 0x80_u8

  struct Info
    magic : UInt32 # 'BOOT' magic
    size : UInt32  # length of bootboot structure, minimum 128
    protocol : UInt8 # a packed structure (ProtocolLevel + LoaderType << 2)
    framebuffer_type : FrameBufferType
    cpu_core_count : UInt16 # number of processor cores
    bootstrap_processor_id : UInt16 # Local APIC Id on x86_64, CPU that should setup the kernel
    timezone : Int16 # in minutes -1440..1440
    datetime : UInt64 # in BCD yyyymmddhhiiss UTC (independent to timezone)
    initrd_ptr : UInt64 # ramdisk image position and size
    initrd_size : UInt64
    frame_buffer_ptr : UInt64 # framebuffer pointer and dimensions
    frame_buffer_size : UInt32
    frame_buffer_width : UInt32
    frame_buffer_height : UInt32
    frame_buffer_scanline : UInt32
  end

  $bootboot : Info
end
