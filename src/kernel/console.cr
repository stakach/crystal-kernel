require "./spinlock"
require "./console/*"

module Console
  extend self

  @@enabled = true
  class_property enabled

  def init(width, height, frame_buffer_base, frame_buffer_size)
    VideoBuffer.init(width, height, frame_buffer_base, frame_buffer_size)
  end

  def width
    width = 0
    lock do |state|
      width = state.cwidth
    end
    width
  end

  def height
    height = 0
    lock do |state|
      height = state.cheight
    end
    height
  end

  def print(*args)
    args.each do |arg|
      arg.to_s self
    end
  end

  private def putchar(state, ch : UInt8)
    if ch == '\r'.ord.to_u8
      return
    elsif ch == '\n'.ord.to_u8
      state.newline
      return
    elsif ch == 8u8
      state.backspace
      state.putc(state.cx, state.cy, ' '.ord.to_u8)
      return
    end
    if state.cy >= state.cheight
      state.scroll
    end
    state.putc(state.cx, state.cy, ch)
    state.advance
  end

  def putc(ch : UInt8)
    lock do |state|
      ansi_handler = state.ansi_handler
      if ansi_handler.nil?
        putchar(state, ch)
      else
        seq = ansi_handler.parse ch
        case seq
        when AnsiHandler::CsiSequence
          case seq.type
          when AnsiHandler::CsiSequenceType::EraseInLine
            if seq.arg_n == 0_u8 && state.cy < state.cwidth - 1
              x = state.cx
              while x < state.cwidth
                state.putc(x, state.cy, ' '.ord.to_u8)
                x += 1
              end
            end
          when AnsiHandler::CsiSequenceType::MoveCursor
            if (arg_m = seq.arg_m) && (arg_n = seq.arg_n)
              state.cx = Math.clamp(arg_m.to_u32 - 1, 0_u32, state.cwidth)
              state.cy = Math.clamp(arg_n.to_u32 - 1, 0_u32, state.cheight)
            end
          end
        when UInt8
          putchar(state, seq)
        end
      end
    end
  end

  @@lock = Spinlock.new

  def lock(&block)
    @@lock.with do
      yield VideoBuffer
    end
  end

  def locked?
    @@lock.locked?
  end
end
