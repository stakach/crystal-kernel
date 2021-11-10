require "./entry_point.cr"
require "./kernel/arch/mem.cr"
require "./kernel/console.cr"

boot_info = UEFI.boot_info.value
memory_map = Slice.new(Pointer(UEFI::MemoryDescriptor).new(boot_info.memory_map_ptr.address), boot_info.memory_map_size)

graphics = boot_info.graphics.value
graphics_mode = graphics.mode_info.value

frame_buffer = Slice.new(Pointer(UInt32).new(graphics.frame_buffer_base), graphics.frame_buffer_size)
width = graphics_mode.horizontal_resolution
height = graphics_mode.vertical_resolution

Console.init(width, height, graphics.frame_buffer_base, graphics.frame_buffer_size)
Console.print "-- booting crystal kernel --\n"
Console.print "* init console... [done]"

while true
  asm("hlt")
end
