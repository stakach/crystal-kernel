require "./entry_point.cr"
require "./kernel/arch/mem.cr"
require "./kernel/console.cr"

def draw_triangle(buffer, hres, center_x, center_y, width, color : UInt32)
  index = hres * (center_y - width // 2) + center_x - width // 2

  row = 0
  while row < width // 2
    col = 0
    while col < width - row * 2
      buffer[index] = color
      index += 1
      col += 1
    end

    index += hres - col

    col = 0
    while col < width - row * 2
      buffer[index] = color
      index += 1
      col += 1
    end

    index += hres - col + 1
    row += 1
  end
end

boot_info = UEFI.boot_info.value
memory_map = Slice.new(Pointer(UEFI::MemoryDescriptor).new(boot_info.memory_map_ptr.address), boot_info.memory_map_size)

graphics = boot_info.graphics.value
graphics_mode = graphics.mode_info.value

frame_buffer = Slice.new(Pointer(UInt32).new(graphics.frame_buffer_base), graphics.frame_buffer_size)
width = graphics_mode.horizontal_resolution
height = graphics_mode.vertical_resolution
draw_triangle(frame_buffer, width, width // 2, height // 2 - 25, 120, 0x00119911_u32)

Console.init(width, height, graphics.frame_buffer_base, graphics.frame_buffer_size)
Console.print "Booting crystal kernel...\n"

while true
  asm("hlt")
end
