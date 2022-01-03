require "./entry_point/*"

lib LibCrystalMain
  fun __crystal_main(argc : Int32, argv : UInt8**)
end

# this is the kernel ELF file entry point
fun kernel_main : Void
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
