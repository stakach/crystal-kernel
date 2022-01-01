module Architecture
  extend self

  def init
    Console.print "-> initializing gdtr... "
    GDT.init_table
    Console.print "[done]\n"

    Console.print "-> initializing paging... "
    GDT.init_table
    Console.print "[done]\n"

    # GDT.register_int_stack Kernel.int_stack_end
    # GDT.flush_tss
    # Kernel.ksyscall_setup
  end

  def zero_page(mem : UInt8*, npages : USize = 1)
    return if npages == 0
    count = npages * 0x200
    r0 = r1 = r2 = 0
    asm("cld\nrep stosq"
            : "={ax}"(r0), "={Di}"(r1), "={cx}"(r2)
            : "{ax}"(0), "{Di}"(mem), "{cx}"(count)
            : "volatile", "memory")
  end

  def halt_processor
    # GC.non_stw_cycle
    # @@status_mask = false
    # rsp = Kernel.int_stack_end
    # asm("mov $0, %rsp
    #      mov %rsp, %rbp
    #      sti" :: "r"(rsp) : "volatile", "{rsp}", "{rbp}")
    while true
      asm("hlt")
    end
  end
end

# require "./x86_64/*"
require "./x86_64/gdt"

fun memset(dst : UInt8*, c : USize, n : USize) : Void*
  r0 = r1 = r2 = 0
  asm(
    "cld\nrep stosb"
          : "={al}"(r0), "={Di}"(r1), "={cx}"(r2)
          : "{al}"(c.to_u8), "{Di}"(dst), "{cx}"(n)
          : "volatile", "memory"
  )
  dst.as(Void*)
end

fun memcpy(dst : UInt8*, src : UInt8*, n : USize) : Void*
  r0 = r1 = r2 = 0
  asm(
    "cld\nrep movsb"
          : "={Di}"(r0), "={Si}"(r1), "={cx}"(r2)
          : "{Di}"(dst), "{Si}"(src), "{cx}"(n)
          : "volatile", "memory"
  )
  dst.as(Void*)
end
