# :nodoc:
struct Tuple
  def self.new(*args : *T)
    args
  end

  def each : Nil
    {% for i in 0...T.size %}
      yield self[{{i}}]
    {% end %}
  end

  def to_s(io)
    io.print "Tuple("
    each do |x|
      io.print x, ","
    end
    io.print ")"
  end

  def at(index : Int)
    at(index) { nil }
  end

  def at(index : Int)
    index += size if index < 0
    {% for i in 0...T.size %}
      return self[{{i}}] if {{i}} == index
    {% end %}
    yield
  end

  def [](index : Int)
    at(index)
  end

  def []?(index : Int)
    at(index) { nil }
  end

  def size
    {{T.size}}
  end
end
