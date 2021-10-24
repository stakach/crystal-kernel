require "./ansi_handler"
require "./font"

module Console
  private module VideoBuffer
    extend self

    FB_ASCII_FONT_WIDTH    =                        8
    FB_ASCII_FONT_HEIGHT   =                        8
    FB_BACK_BUFFER_POINTER = 0xFFFF_8700_0000_0000u64

    @@cx = 0_u32
    @@cy = 0_u32
    @@fg = 0_u32
    @@bg = 0_u32
    class_property cx
    class_property cy
    class_property fg
    class_property bg

    @@ansi_handler = AnsiHandler.new
    class_getter ansi_handler

    def advance
      if @@cx >= @@cwidth
        newline
      else
        @@cx += 1
      end
    end

    def backspace
      if @@cx == 0 && @@cy > 0
        @@cx = @@cwidth
        @@cy -= 1
      elsif @@cx > 0
        @@cx -= 1
      end
    end

    def newline
      if @@cy == @@cheight
        wrapback
      end
      @@cx = 0_u32
      @@cy += 1
    end

    def wrapback
      @@cx = 0_u32
      @@cy = @@cheight - 1
    end

    @@cwidth = 0_u32
    @@cheight = 0_u32
    @@width = 0_u32
    @@height = 0_u32
    class_getter cwidth, cheight
    class_getter width, height

    # physical framebuffer location
    @@buffer = Slice(UInt32).null
    class_getter buffer

    def init(@@width, @@height, frame_buffer_base, frame_buffer_size)
      @@cwidth = (@@width // FB_ASCII_FONT_WIDTH) - 1
      @@cheight = (@@height // FB_ASCII_FONT_HEIGHT) - 1
      @@buffer = Slice.new(Pointer(UInt32).new(frame_buffer_base), frame_buffer_size)
      memset(@@buffer.to_unsafe.as(UInt8*), 0u64,
        @@width.to_usize * @@height.to_usize * sizeof(UInt32).to_usize)
    end

    def offset(x, y)
      y * @@width + x
    end

    def putc(x, y, ch : UInt8)
      return if x > @@cwidth || x < 0
      return if y > @@height || y < 0
      bitmap = FONT[ch]?
      return unless bitmap

      FB_ASCII_FONT_WIDTH.times do |cx|
        FB_ASCII_FONT_HEIGHT.times do |cy|
          dx = x * FB_ASCII_FONT_WIDTH + cx
          dy = y * FB_ASCII_FONT_HEIGHT + cy
          lookup = bitmap[cy]
          if lookup && (lookup & (1 << cx)) != 0
            @@buffer[offset dx, dy] = 0x00FFFFFF
          else
            @@buffer[offset dx, dy] = 0x0
          end
        end
      end
    end

    def scroll
      ((@@cheight - 1) * FB_ASCII_FONT_HEIGHT).times do |y|
        (@@cwidth * FB_ASCII_FONT_WIDTH).times do |x|
          if value = @@buffer[offset x, (y + FB_ASCII_FONT_HEIGHT)]
            @@buffer[offset x, y] = value
          end
        end
      end
      FB_ASCII_FONT_HEIGHT.times do |y|
        @@width.times do |x|
          dx, dy = x, ((@@cheight - 1) * FB_ASCII_FONT_HEIGHT + y)
          @@buffer[offset dx, dy] = 0x0_u32
        end
      end
      wrapback
    end
  end
end
