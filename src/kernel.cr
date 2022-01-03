lib Kernel
  # These pointers are configured in `kernel.ld`
  $kernel_start : Void*
  $kernel_end : Void*

  # kernel executable code
  $text_start : Void*
  $text_end : Void*

  # static variables
  $data_start : Void*
  $data_end : Void*

  # read only variables
  $rodata_start : Void*
  $rodata_end : Void*

  # uninitialized variables
  $bss_start : Void*
  $bss_end : Void*
end

require "./entry_point"
require "./kernel/console"
require "./kernel/architecture"

boot_info = BootBoot.bootboot

Console.init(
  boot_info.frame_buffer_width,
  boot_info.frame_buffer_height,
  boot_info.frame_buffer_ptr,
  boot_info.frame_buffer_size
)
Console.print "-- booting crystal kernel --\n"
Console.print "* init console... [done]\n"

# Print some boot information
Console.print "\nBOOT INFO\n"
Console.print "       CPU Cores: ", boot_info.cpu_core_count, "\n"
Console.print "          CPU ID: ", Architecture::CPUID.cpu_core_id, ", Bootstrap CPU ID: ", boot_info.bootstrap_processor_id, "\n"
Console.print "    Frame Buffer: ", boot_info.frame_buffer_width, "x", boot_info.frame_buffer_height, " @ 32bits\n\n"

Console.print "* init architecture...\n"
Architecture.init
Console.print "* init architecture... [done]\n"

Architecture.halt_processor
