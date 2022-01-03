require "./entry_point/*"

lib LibCrystalMain
  fun __crystal_main(argc : Int32, argv : UInt8**)
end

# this is the kernel ELF file entry point
fun kernel_main : Void
  # all the CPU cores call this function, we'll pause everything except the
  # bootstrap processor until we are ready for everything else.
  if Architecture::CPUID.cpu_core_id == BootBoot.bootboot.bootstrap_processor_id
    LibCrystalMain.__crystal_main(0, Pointer(UInt8*).null)
  else
    # TODO:: in the future we only want to 'pause' the processor here
    # then when we're ready for SMP we can use an interrupt to kick them into gear
    Architecture.halt_processor
  end
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
