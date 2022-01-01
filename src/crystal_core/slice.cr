struct Slice(T)
  getter size : UInt64
  @size : UInt64

  def initialize(@buffer : Pointer(T), size : Int)
    @size = size.to_u64
  end

  def self.null
    new Pointer(T).null, 0
  end

  def null?
    @buffer.null?
  end

  def self.malloc(sz : Int)
    new Pointer(T).malloc(sz.to_u64), sz
  end

  def self.malloc_atomic(sz : Int)
    new Pointer(T).malloc_atomic(sz.to_u64), sz
  end

  def self.mmalloc_a(sz, allocator)
    new allocator.malloc(sz * sizeof(T)).as(T*), sz
  end

  def [](idx : Int)
    return nil if idx >= @size || idx < 0
    @buffer[idx]
  end

  @[AlwaysInline]
  def []=(idx : Int, value : T)
    return value if idx >= @size || idx < 0
    @buffer[idx] = value
  end

  def [](range : Range(Int, Int))
    raise "Slice: out of range" if range.begin > range.end
    Slice(T).new(@buffer + range.begin, range.size)
  end

  def to_unsafe
    @buffer
  end

  def each(&block)
    i = 0
    while i < @size
      yield @buffer[i]
      i += 1
    end
  end

  def hash(hasher)
    hasher.hash self
  end

  def ==(other : String)
    other == self
  end

  def to_s(io)
    io.print "Slice(", @buffer, " ", @size, ")"
  end
end
