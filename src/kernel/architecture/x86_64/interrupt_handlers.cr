module Architecture
  lib CPU
    struct Registers
      # Pushed by pushad:
      ds : UInt64
      rbp, rdi, rsi : UInt64
      r15, r14, r13, r12, r11, r10, r9, r8 : UInt64
      rdx, rcx, rbx, rax : UInt64
      # Interrupt number
      int_no, errcode : UInt64
      # Pushed by the processor automatically.
      rip, cs, rflags, userrsp, ss : UInt64
    end
  end

  # 64bit doesn't have a pusha instruction, unlike 32bit
  macro pusha64
    # gp registers
    asm("push %rax
         push %rbx
         push %rcx
         push %rdx
         push %r8
         push %r9
         push %r10
         push %r11
         push %r12
         push %r13
         push %r14
         push %r15" ::: "volatile")

    # scan registers
    asm("push %rsi
         push %rdi" ::: "volatile")

    # stack registers
    asm("push %rbp" ::: "volatile")

    # segment registers
    asm("mov %ds, %ax
         push %rax" ::: "volatile", "ax")
  end

  macro restore_segment
    # segment registers
    asm("pop %rax
         mov %ax, %ds
         mov %ax, %es" ::: "volatile")
  end

  macro popa64
    Architecture.restore_segment

    # stack registers
    asm("pop %rbp" ::: "volatile")

    # scan registers
    asm("pop %rdi
         pop %rsi" ::: "volatile")

    # gp registers
    asm("pop %r15
         pop %r14
         pop %r13
         pop %r12
         pop %r11
         pop %r10
         pop %r9
         pop %r8
         pop %rdx
         pop %rcx
         pop %rbx
         pop %rax" ::: "volatile")
  end

  macro interrupt(function_name, &block)
    fun {{function_name.id}}
      {{block.body}}
      asm("iret" :::)
    end
  end

  # adds the interrupt index to the stack, on top of what the CPU automatically pushed
  macro configure_interrupt(name, index, has_error_code)
    Architecture.interrupt :kernel_{{name.id}}{{ index.id }} do
      # null error code added for struct uniformity if this exception doesn't include an error
      {% if !has_error_code %}
        asm("push $$0" :::)
      {% end %}

      # push the interrupt index to the stack
      # hack to have string interpolation occur at compile time
      {% push_index = "push $$#{index.id}" %}
      asm({{ push_index }} :::)

      # we jump here as the stub will call iret
      asm("jmp kernel_interrupt_stub" :::)
    end
  end

  enum ExceptionType
    Abort
    Fault
    Trap
  end

  # exceptions 0-31 are reserved for the architechture. 32-255 are user definable
  # # https://wiki.osdev.org/Exceptions#Faults
  {% begin %}
    {% excepts = [
         # index, type, includes error code, description
         {0, ExceptionType::Fault, false, "Divide-by-zero Error"},
         {1, ExceptionType::Trap, false, "Debug"},
         {2, ExceptionType::Trap, false, "Non-maskable Interrupt"},
         {3, ExceptionType::Trap, false, "Breakpoint"},
         {4, ExceptionType::Trap, false, "Overflow"},
         {5, ExceptionType::Fault, false, "Bound Range Exceeded"},
         {6, ExceptionType::Fault, false, "Invalid Opcode"},
         {7, ExceptionType::Fault, false, "Device Not Available"},
         {8, ExceptionType::Abort, true, "Double Fault"},
         # When the FPU was still external to the processor, it had separate segment
         # checking in protected mode. Since the 486 this is handled by a General Protection Fault instead
         {9, ExceptionType::Fault, false, "Coprocessor Segment Overrun"},
         {10, ExceptionType::Fault, true, "Invalid TSS"},
         {11, ExceptionType::Fault, true, "Segment Not Present"},
         {12, ExceptionType::Fault, true, "Stack-Segment Fault"},
         {13, ExceptionType::Fault, true, "General Protection Fault"},
         {14, ExceptionType::Fault, true, "Page Fault"},
         {15, ExceptionType::Fault, false, "Reserved"},
         {16, ExceptionType::Fault, false, "x87 Floating-Point Exception"},
         {17, ExceptionType::Fault, true, "Alignment Check"},
         {18, ExceptionType::Abort, false, "Machine Check"},
         {19, ExceptionType::Fault, false, "SIMD Floating-Point Exception"},
         {20, ExceptionType::Fault, false, "Virtualization Exception"},
         {21, ExceptionType::Fault, true, "Control Protection Exception"},
         {22, ExceptionType::Fault, false, "Reserved"},
         {23, ExceptionType::Fault, false, "Reserved"},
         {24, ExceptionType::Fault, false, "Reserved"},
         {25, ExceptionType::Fault, false, "Reserved"},
         {26, ExceptionType::Fault, false, "Reserved"},
         {27, ExceptionType::Fault, false, "Reserved"},
         {28, ExceptionType::Fault, false, "Hypervisor Injection Exception"},
         {29, ExceptionType::Fault, true, "VMM Communication Exception"},
         {30, ExceptionType::Fault, true, "Security Exception"},
         {31, ExceptionType::Fault, false, "Reserved"},
       ] %}

    EXCEPTIONS = StaticArray{{excepts}}
    MACRO_EXCEPTIONS = {{excepts}}
  {% end %}
end

# this keeps the resulting binary DRY, making better use of the CPU caches
Architecture.interrupt kernel_interrupt_stub do
  # NOTE:: undo the stack frame added by the compiler, this is pretty fragile...
  asm("add $$24, %rsp" ::: "volatile")

  # push all the general purpose registers to the stack
  Architecture.pusha64
  # we could also `fxsave64` if we wanted, but we don't plan on clobbering the
  # FPU / MMX / SSE state

  # get the address of the stack
  frame_address = 0u64
  asm("cld
       mov %rsp, $0" : "=r"(frame_address) :: "volatile")

  # Process the exception in crystal land
  frame = Pointer(Architecture::CPU::Registers).new(frame_address)
  if frame.value.int_no < 32u64
    Architecture::Idt.handle_exception frame
  else
    Architecture::Idt.handle frame
  end

  # restore the state before returning
  Architecture.popa64
  # skip interrupt index and exception number pushed before the stub was called
  asm("add $$16, %rsp" ::: "volatile")
end

# add all the kernel exception functions
{% for exception in Architecture::MACRO_EXCEPTIONS %}
  Architecture.configure_interrupt "cpu_exception", {{exception[0]}}, has_error_code: {{exception[2]}}
{% end %}

{% for i in 0..15 %}
  Architecture.configure_interrupt "interrupt_request", {{i + 32}}, has_error_code: false
{% end %}
