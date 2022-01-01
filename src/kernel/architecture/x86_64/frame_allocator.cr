module Architecture::FrameAllocator
  extend self

  private struct Region
    @base_addr = 0u64
    @length = 0u64
    getter base_addr, length

    @frames = BitArray.null
    getter frames
    protected setter frames

    @search_from = 0

    @next_region = Pointer(Region).null
    property next_region

    def _initialize(@base_addr : UInt64, @length : UInt64)
      nframes = (@length // 0x1000).to_i32
      @frames = BitArray.pmalloc nframes
    end

    def to_s(io)
      @base_addr.to_s io, 16
      io.print ':'
      @length.to_s io, 16
    end

    private def index_for_address(addr : UInt64)
      ((addr - @base_addr) // 0x1000).to_i32
    end

    def initial_claim(addr : UInt64)
      idx = index_for_address(addr)
      return false if @frames[idx]
      @frames[idx] = true
      true
    end

    @lock = Spinlock.new

    def lock
      @lock.with do
        yield
      end
    end

    def claim
      idx, iaddr = @frames.first_unset_from @search_from
      @search_from = Math.max idx, @search_from
      return nil if iaddr == -1
      @frames[iaddr] = true
      {% if false %}
        addr = iaddr.to_usize * 0x1000 + @base_addr
        Console.print "claim: ", Pointer(Void).new(addr), '\n'
      {% end %}
      iaddr
    end

    def claim_with_addr
      if (iaddr = claim).nil?
        return
      end
      iaddr = iaddr.not_nil!
      addr = iaddr.to_usize * 0x1000 + @base_addr
      addr
    end

    def declaim_addr(addr : UInt64)
      unless @base_addr <= addr < (@base_addr + @length)
        return false
      end
      {% if false %}
        Console.print "declaim: ", Pointer(Void).new(addr), '\n'
      {% end %}
      idx = index_for_address(addr)
      @search_from = Math.min idx, @search_from
      @frames[idx] = false
      true
    end
  end

  @@first_region = Pointer(Region).null
  @@last_region = Pointer(Region).null

  @@is_paging_setup = false
  class_property is_paging_setup

  @@used_blocks = 0u64
  class_getter used_blocks

  @@lock = Spinlock.new

  def add_region(base_addr : UInt64, length : UInt64)
    region = PermaAllocator.malloca_t(Region)
    region.value._initialize(base_addr, length)
    if @@first_region.null?
      @@first_region = region
      @@last_region = region
    else
      @@last_region.value.next_region = region
      @@last_region = region
    end
  end

  private def each_region(&block)
    region = @@first_region
    while !region.null?
      if @@is_paging_setup
        new_addr = region.address | Paging::IDENTITY_MASK
        region = Pointer(Region).new new_addr
      end
      yield region.value
      region = region.value.next_region
    end
  end

  def update_inner_pointers
    region = @@first_region
    while !region.null?
      new_addr = region.value.frames.to_unsafe.address | Paging::IDENTITY_MASK
      size = region.value.frames.size
      region.value.frames = BitArray.new(Pointer(UInt32).new(new_addr), size)
      region = region.value.next_region
    end
  end

  def initial_claim(addr : UInt64)
    if @@first_region.value.initial_claim addr
      @@used_blocks += 1
    end
  end

  def claim
    each_region do |region|
      region.lock do
        if frame = region.claim
          @@used_blocks += 1
          return frame
        end
      end
    end
    abort "no more physical memory!"
    0
  end

  def declaim_addr(addr : UInt64)
    each_region do |region|
      region.lock do
        if region.declaim_addr addr
          @@used_blocks -= 1
          return
        end
      end
    end
    abort "unknown address"
  end

  def claim_with_addr
    each_region do |region|
      region.lock do
        if frame = region.claim_with_addr
          @@used_blocks += 1
          return frame
        end
      end
    end
    abort "no more physical memory!"
    0u64
  end
end
