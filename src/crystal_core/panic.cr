def abort(*args) : NoReturn
  # TODO: print call stack
  # Console.print *args
  while true
    Pointer(Int32).null.value = 0
  end
end

def panic(*args)
  # TODO::
  while true
  end
end

def raise(*args)
end

{% if flag?(:release) && false %}
  macro breakpoint
  end
{% else %}
  @[NoInline]
  fun breakpoint
    asm("nop")
  end
{% end %}
