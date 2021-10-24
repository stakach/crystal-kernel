struct Spinlock
  @value = Atomic(Int32).new 0

  private def lock
    i = 0
    while true
      _, changed = @value.compare_and_set(0, 1)
      return if changed
      i += 1
    end
  end

  private def unlock
    @value.compare_and_set(1, 0)
  end

  def locked?
    @value.get != 0
  end

  def with(&block)
    lock
    begin
      retval = yield
    ensure
      unlock
    end
    retval
  end
end
