require "./init.cr"

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

graphics = boot_info.graphics.value
graphics_mode = graphics.mode_info.value

frame_buffer = Slice.new(Pointer(UInt32).new(graphics.frame_buffer_base), graphics.frame_buffer_size)
hres = graphics_mode.horizontal_resolution
vres = graphics_mode.vertical_resolution
draw_triangle(frame_buffer, hres, hres // 2, vres // 2 - 25, 120, 0x00119911_u32)

while true
  asm("hlt")
end
