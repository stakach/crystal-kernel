require "./interrupt_handlers"
require "./pic"

module Architecture::Idt
  extend self

  INTERRUPT_GATE      = 0x8Eu16
  KERNEL_CODE_SEGMENT = 0x08u16
  EX_PAGEFAULT        =      14

  lib Data
    @[Packed]
    struct Idt
      limit : UInt16
      base : UInt64
    end

    @[Packed]
    struct IdtEntry
      offset_1 : UInt16 # offset bits 0..15
      selector : UInt16 # a code segment selector in GDT or LDT
      ist : UInt8
      type_attr : UInt8 # type and attributes
      offset_2 : UInt16 # offset bits 16..31
      offset_3 : UInt32 # offset bits 32..63
      zero : UInt32
    end
  end

  alias InterruptHandler = -> Nil

  # initialize
  IRQ_COUNT = 16
  @@irq_handlers = uninitialized InterruptHandler[IRQ_COUNT]

  # table init
  IDT_SIZE = 256
  @@idtr = uninitialized Data::Idt
  @@idt = uninitialized Data::IdtEntry[IDT_SIZE]

  def init_table
    @@idtr.limit = sizeof(Data::IdtEntry) * IDT_SIZE - 1
    @@idtr.base = @@idt.to_unsafe.address

    # cpu exception handlers
    {% for i in 0..31 %}
      init_idt_entry {{ i }}, KERNEL_CODE_SEGMENT,
        (->kernel_cpu_exception{{ i.id }}).pointer.address,
        INTERRUPT_GATE
    {% end %}

    # hardware interrupts
    {% for i in 0..15 %}
      init_idt_entry {{ i + 32 }}, KERNEL_CODE_SEGMENT,
        (->kernel_interrupt_request{{ i + 32 }}).pointer.address,
        INTERRUPT_GATE
    {% end %}

    asm("lidt ($0)" :: "r"(pointerof(@@idtr)) : "volatile")
  end

  def init_idt_entry(num : Int32, selector : UInt16, offset : UInt64, type : UInt16)
    idt = Data::IdtEntry.new
    idt.offset_1 = (offset & 0xFFFF)
    idt.ist = 1
    idt.selector = selector
    idt.type_attr = type
    idt.offset_2 = (offset >> 16) & 0xFFFF
    idt.offset_3 = (offset >> 32)
    idt.zero = 0
    @@idt[num] = idt
  end

  # handlers
  class_getter irq_handlers

  def register_irq(idx : Int, handler : InterruptHandler)
    @@irq_handlers[idx] = handler
  end

  # status
  @@status_mask = false
  class_getter status_mask

  {% if flag?(:record_cli) %}
    @@disabled_at = 0x0u64
    class_getter disabled_at
  {% end %}

  @[NoInline]
  def enable
    if !@@status_mask
      asm("sti" ::: "volatile")
    end
  end

  @[NoInline]
  def disable
    if !@@status_mask
      asm("cli" ::: "volatile")
    end
  end

  def disable(reenable = false, &block)
    if @@status_mask
      return yield
    end
    disable
    @@status_mask = true

    {% if flag?(:record_cli) %}
      asm("lea (%rip), $0" : "=r"(@@disabled_at) :: "volatile")
    {% end %}
    begin
      retval = yield
    ensure
      @@status_mask = false
      enable if reenable
      retval
    end
  end

  def check_if
    check = 0
    asm("pushfq; popq %rax" : "={rax}"(check) :: "volatile")
    abort "IF is set" if (check & 0x200) != 0
  end

  @@last_frame = Pointer(CPU::Registers).null
  class_getter last_frame

  @@locked = false
  class_getter locked

  @@switch_processes = false
  class_property switch_processes

  private def handle_unmasked(frame : CPU::Registers*)
    irq_number = frame.value.int_no - 32
    Console.print "interrupt ", frame.value.int_no, " (IRQ ", irq_number, ") fired\n"
    # dump_frame(frame)

    PIC.eoi irq_number

    if @@irq_handlers[irq_number].pointer.null?
      Console.print "no handler for ", irq_number, "\n"
    else
      @@irq_handlers[irq_number].call
    end

    if irq_number == 0 && @@switch_processes
      # preemptive multitasking...
      # if (current_process = Multiprocessing::Scheduler.current_process)
      #  if current_process.sched_data.time_slice > 0
      #    current_process.sched_data.time_slice -= 1
      #    return
      #  end
      # end
      # Multiprocessing::Scheduler.switch_process(frame)
    end
  end

  def handle(frame : CPU::Registers*)
    @@locked = true
    @@status_mask = true
    @@last_frame = frame

    handle_unmasked frame

    @@last_frame = Pointer(CPU::Registers).null
    @@status_mask = false
    @@locked = false
  end

  private def handle_exception_unmasked(frame : CPU::Registers*)
    Console.print "exception ", frame.value.int_no, " fired\n"

    errcode = frame.value.errcode
    # unless process = Multiprocessing::Scheduler.current_process
    #  dump_frame(frame)
    #  Console.print "segfault from pre-startup kernel code?"
    #  while true; end
    # end
    # process = process.not_nil!
    case frame.value.int_no
    when EX_PAGEFAULT
      faulting_address = 0u64
      asm("mov %cr2, $0" : "=r"(faulting_address) :: "volatile")
      # faulting_page = Paging.aligned_floor faulting_address

      present = (errcode & 0x1) != 0
      rw = (errcode & 0x2) != 0
      user = (errcode & 0x4) != 0
      reserved = (errcode & 0x8) != 0
      id = (errcode & 0x10) != 0

      Console.print Pointer(Void).new(faulting_address), " from ", Pointer(Void).new(frame.value.rip) # , " proc ", process.name, '\n'

      # if process.kernel_process?
      #  panic "segfault from kernel process"
      # elsif frame.value.rip > Multiprocessing::KERNEL_INITIAL
      #  panic "segfault from kernel"
      # else
      #  process.udata.mmap_list.each do |node|
      #    if node.contains_address? faulting_address
      #      if node.handle_page_fault(present, rw, user, faulting_page)
      #        return
      #      else
      #        panic "unhandled fault"
      #      end
      #    end
      #  end
      # end

      dump_frame(frame)
      panic "unhandled fault"
    else
      dump_frame(frame)
      # Console.print "process: ", process.name, '\n'
      interrupt = frame.value.int_no
      if interrupt < 32
        details = EXCEPTIONS[interrupt]
        Console.print "unhandled cpu exception: ", frame.value.int_no, ' ', errcode, " (", details[1], "): ", details[3], '\n'
      else
        Console.print "unhandled cpu exception: ", frame.value.int_no, ' ', errcode, " (interrupt out of range)\n"
      end
      Architecture.halt_processor
    end
  end

  def handle_exception(frame : CPU::Registers*)
    @@locked = true
    @@status_mask = true
    @@last_frame = frame

    handle_exception_unmasked frame

    @@last_frame = Pointer(CPU::Registers).null
    @@status_mask = false
    @@locked = false
  end
end

private def dump_frame(frame : Architecture::CPU::Registers*)
  {% for id in [
                 "ds",
                 "rbp", "rdi", "rsi",
                 "r15", "r14", "r13", "r12", "r11", "r10", "r9", "r8",
                 "rdx", "rcx", "rbx", "rax",
                 "int_no", "errcode",
                 "rip", "cs", "rflags", "userrsp", "ss",
               ] %}
    Console.print {{ id }}, "="
    frame.value.{{ id.id }}.to_s Console, 16
    Console.print "\n"
  {% end %}
end

{% if flag?(:record_cli) %}
  fun __record_cli : UInt64
    Idt.disabled_at
  end
{% end %}
