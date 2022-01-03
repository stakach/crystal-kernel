# :nodoc:
struct Char
  def to_s(io)
    io.putc self.ord.to_u8
  end

  def ===(other)
    self == other
  end

  @[Primitive(:convert)]
  def ord : Int32
  end

  {% for op, desc in {
                       "==" => "equal to",
                       "!=" => "not equal to",
                       "<"  => "less than",
                       "<=" => "less than or equal to",
                       ">"  => "greater than",
                       ">=" => "greater than or equal to",
                     } %}
    # Returns `true` if `self`'s codepoint is {{desc.id}} *other*'s codepoint.
    @[Primitive(:binary)]
    def {{op.id}}(other : Char) : Bool
    end
  {% end %}
end
