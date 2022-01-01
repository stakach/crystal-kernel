{% if flag?(:x86_64) %}
  require "./architecture/x86_64"
{% else %}
  {% raise "architecture not currently supported" %}
{% end %}

fun memcmp(s1 : UInt8*, s2 : UInt8*, n : Int32) : Int32
  while n > 0 && (s1.value == s2.value)
    s1 += 1
    s2 += 1
    n -= 1
  end
  return 0 if n == 0
  (s1.value - s2.value).to_i32
end

fun memmove(dst : UInt8*, src : UInt8*, n : USize) : Void*
  if src.address < dst.address
    src += n.to_i64
    dst += n.to_i64
    until n == 0
      dst -= 1
      src -= 1
      dst.value = src.value
      n -= 1
    end
  else
    memcpy dst, src, n
  end
  dst.as(Void*)
end
