lib Kernel
  # These pointers are configured in `kernel.ld`
  $kernel_start : UInt64
  $kernel_end : UInt64

  # kernel executable code
  $text_start : UInt64
  $text_end : UInt64

  # static variables
  $data_start : UInt64
  $data_end : UInt64

  # read only variables
  $rodata_start : UInt64
  $rodata_end : UInt64

  # uninitialized variables
  $bss_start : UInt64
  $bss_end : UInt64
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

EntryPoint.memory_map do |entry|
  Console.print "     Memory type: ", entry.type, " @ 0x"
  entry.address.to_s Console, 16
  Console.print ", Size: 0x"
  entry.size.to_s Console, 16
  Console.print " bytes\n"
end

Console.print "\n* init architecture...\n"
Architecture.init
Console.print "* init architecture... [done]\n"

Architecture.halt_processor
