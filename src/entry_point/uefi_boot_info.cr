lib UEFI
  struct PixelBitmask
    red_mask : UInt32
    green_mask : UInt32
    blue_mask : UInt32
    reserved_mask : UInt32
  end

  struct GraphicsMode
    version : UInt32
    horizontal_resolution : UInt32
    vertical_resolution : UInt32
    pixel_format : UInt32
    pixel_information : PixelBitmask
    pixels_per_scan_line : UInt32
  end

  struct GraphicsOutput
    max_mode : UInt32
    mode : UInt32
    mode_info : GraphicsMode*
    size_of_info : UInt64
    frame_buffer_base : UInt64
    frame_buffer_size : UInt64
  end

  enum MemoryType : UInt32
    # This enum variant is not used.
    Reserved = 0
    # The code portions of a loaded UEFI application.
    LoaderCode = 1
    # The data portions of a loaded UEFI applications,
    # as well as any memory allocated by it.
    LoaderData = 2
    # Code of the boot drivers.
    # Can be reused after OS is loaded.
    BootServicesCode = 3
    # Memory used to store boot drivers' data.
    # Can be reused after OS is loaded.
    BootServicesData = 4
    # Runtime drivers' code.
    RuntimeServicesCode = 5
    # Runtime services' code.
    RuntimeServicesData = 6
    # Free usable memory.
    Conventional = 7
    # Memory in which errors have been detected.
    Unusable = 8
    # Memory that holds ACPI tables.
    # Can be reclaimed after they are parsed.
    ACPIReclaim = 9
    # Firmware-reserved addresses.
    ACPINonVolatile = 10
    # A region used for memory-mapped I/O.
    MemoryMappedIO = 11
    # Address space used for memory-mapped port I/O.
    MemoryMappedPortSpace = 12
    # Address space which is part of the processor.
    PALCode = 13
    # Memory region which is usable and is also non-volatile.
    PersistentMemory = 14
  end

  @[Flags]
  enum MemoryAttributes : UInt64
    # Supports marking as uncacheable.
    Uncacheable = 0x1
    # Supports write-combining.
    WriteCombine = 0x2
    # Supports write-through.
    WriteThrough = 0x4
    # Support write-back.
    WriteBack = 0x8
    # Supports marking as uncacheable, exported and
    # supports the "fetch and add" semaphore mechanism.
    UncacheableExported = 0x10
    # Supports write-protection.
    WriteProtect = 0x1000
    # Supports read-protection.
    ReadProtect = 0x2000
    # Supports disabling code execution.
    ExecuteProtect = 0x4000
    # Persistent memory.
    NonVolatile = 0x8000
    # This memory region is more reliable than other memory.
    MoreReliable = 0x10000
    # This memory range can be set as read-only.
    ReadOnly = 0x20000
    # This memory must be mapped by the OS when a runtime service is called.
    Runtime = 0x8000_0000_0000_0000
  end

  struct MemoryDescriptor
    # Type of memory occupying this range.
    memory_type : MemoryType
    # Skip 4 bytes as UEFI declares items in structs should be naturally aligned
    padding : UInt32
    physical_start : UInt64
    virtual_start : UInt64
    # Number of 4 KiB pages contained in this range.
    number_of_pages : UInt64
    attributes : MemoryAttributes
  end

  struct BootInfo
    graphics : GraphicsOutput*
    memory_map_ptr : Void*
    memory_map_size : UInt64
    memory_map_descriptor_size : UInt64
  end

  $boot_info : BootInfo*
end
