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

    def size
      entry.flags & 0xFFFFFFFFFFFFFFF0u64
    end

    def type
      MemoryType.from_value(entry.flags & 0xFu64)
    end

    def is_free?
      type.free_usable?
    end
  end
end
