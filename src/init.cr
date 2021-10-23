lib LibCrystalMain
  fun __crystal_main(argc : Int32, argv : UInt8**)
end

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

  struct BootInfo
    graphics : GraphicsOutput*
    memory_map : Void*
    memory_map_size : UInt64
    memory_map_descriptor_size : UInt64
  end

  $boot_info : BootInfo*
end

fun kernel_main() : Void
  LibCrystalMain.__crystal_main(0, Pointer(UInt8*).null)
end

fun __crystal_once_init : Void*
  Pointer(Void).new 0
end

fun __crystal_once(state : Void*, flag : Bool*, initializer : Void*)
  unless flag.value
    # Proc(Void).new(initializer, Pointer(Void).new(0)).call
    flag.value = true
  end
end

fun __crystal_personality
end

@[Raises]
fun __crystal_raise(unwind_ex : Void*)
  while true
    asm("hlt")
  end
end

fun __crystal_raise_overflow
  while true
    asm("hlt")
  end
end

fun __crystal_get_exception(unwind_ex : Void*) : UInt64
  0u64
end
