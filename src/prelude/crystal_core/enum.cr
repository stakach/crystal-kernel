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

  # Returns the enum member that has the given value, or `nil` if
  # no such member exists.
  #
  # ```
  # Color.from_value?(0) # => Color::Red
  # Color.from_value?(1) # => Color::Green
  # Color.from_value?(2) # => Color::Blue
  # Color.from_value?(3) # => nil
  # ```
  def self.from_value?(value : Int) : self?
    {% if @type.annotation(Flags) %}
      all_mask = {{@type}}::All.value
      return if all_mask & value != value
      return new(all_mask.class.new(value))
    {% else %}
      {% for member in @type.constants %}
        return new({{@type.constant(member)}}) if {{@type.constant(member)}} == value
      {% end %}
    {% end %}
    nil
  end

  # Returns the enum member that has the given value, or raises
  # if no such member exists.
  #
  # ```
  # Color.from_value(0) # => Color::Red
  # Color.from_value(1) # => Color::Green
  # Color.from_value(2) # => Color::Blue
  # Color.from_value(3) # raises Exception
  # ```
  def self.from_value(value : Int) : self
    from_value?(value) || raise "Unknown enum value"
  end

  def to_s(io) : Nil
    {% if @type.annotation(Flags) %}
      if value == 0
        io.print "None"
      else
        found = false
        {% for member in @type.constants %}
          {% if member.stringify != "All" %}
            if {{@type.constant(member)}} != 0 && value.bits_set? {{@type.constant(member)}}
              io.print " | " if found
              io.print {{member.stringify}}
              found = true
            end
          {% end %}
        {% end %}
        io.print value unless found
      end
    {% else %}
      io.print to_s
    {% end %}
    nil
  end

  def to_s
    {% if @type.annotation(Flags) %}
      value
    {% else %}
      # Can't use `case` here because case with duplicate values do
      # not compile, but enums can have duplicates (such as `enum Foo; FOO = 1; BAR = 1; end`).
      {% for member, i in @type.constants %}
        if value == {{@type.constant(member)}}
          return {{member.stringify}}
        end
      {% end %}

      value
    {% end %}
  end
end
