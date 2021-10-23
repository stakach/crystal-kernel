# :nodoc:
struct Enum
  def ==(other)
    value == other.value
  end

  def !=(other)
    value != other.value
  end

  def ===(other)
    value == other.value
  end

  def |(other : self)
    self.class.new(value | other.value)
  end

  def &(other : self)
    self.class.new(value & other.value)
  end

  def ~
    self.class.new(~value)
  end

  def includes?(other : self)
    (value & other.value) != 0
  end

  def to_s(io)
    {% if @type.has_attribute?("Flags") %}
      if value == 0
        io.print "None"
      else
        found = false
        {% for member in @type.constants %}
          {% if member.stringify != "All" %}
            if {{@type}}::{{member}}.value != 0 && (value & {{@type}}::{{member}}.value) != 0
              io.print " | " if found
              io.print {{member.stringify}}
              found = true
            end
          {% end %}
        {% end %}
        io.print value unless found
      end
    {% else %}
      case value
      {% for member in @type.constants %}
      when {{@type}}::{{member}}.value
        io.print {{member.stringify}}
      {% end %}
      else
        io.print value
      end
    {% end %}
  end
end
