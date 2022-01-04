require "./boot_boot"

module EntryPoint
  struct MemoryMap
    enum MemoryType
      Reserved   = 0 # don't use
      FreeUsable = 1
      ACPI       = 2 # Advanced Configuration and Power Interface
      MMIO       = 3 # Memory-mapped Input/Output
    end

    getter entry : BootBoot::MemoryMapEntry

    def initialize(@entry : BootBoot::MemoryMapEntry)
    end

    def size
      entry.flags & 0xFFFFFFFFFFFFFFF0u64
    end

    def type
      MemoryType.from_value(entry.flags & 0xFu64)
    end

    def is_free?
      type.free_usable?
    end

    def address
      entry.address
    end
  end

  def self.memory_map
    start_address = pointerof(BootBoot.bootboot).address
    end_address = start_address + BootBoot.bootboot.size
    current_address = start_address + sizeof(BootBoot::Info)

    memory_map_size = sizeof(BootBoot::MemoryMapEntry)

    while current_address < end_address
      yield MemoryMap.new(Pointer(BootBoot::MemoryMapEntry).new(current_address).value)
      current_address += memory_map_size
    end
  end
end
