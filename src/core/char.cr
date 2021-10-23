# :nodoc:
struct Char
  def to_s(io)
    io.putc self.ord.to_u8
  end

  def ===(other)
    self == other
  end
end
