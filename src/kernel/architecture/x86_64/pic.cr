require "./cpuio"

module Architecture::PIC
  extend self

  # Initializes the 8259 PIC with zero interrupt mask
  def init_interrupts
    CPUIO.outb 0x20, 0x11
    CPUIO.outb 0xA0, 0x11
    CPUIO.outb 0x21, 0x20
    CPUIO.outb 0xA1, 0x28
    CPUIO.outb 0x21, 0x04
    CPUIO.outb 0xA1, 0x02
    CPUIO.outb 0x21, 0x01
    CPUIO.outb 0xA1, 0x01
    CPUIO.outb 0x21, 0x0
    CPUIO.outb 0xA1, 0x0
  end

  # Sets the PIC mask for an IRQ, enabling interrupts from IRQ
  def enable(irq)
    if irq >= 8
      imr = CPUIO.inb 0xA1
      imr &= ~(1 << (irq - 8))
      CPUIO.outb 0xA1, imr
    else
      imr = CPUIO.inb 0x21
      imr &= ~(1 << irq)
      CPUIO.outb 0x21, imr
    end
  end

  # Clears the PIC mask for an IRQ, disabling interrupts from IRQ
  def disable(irq)
    if irq >= 8
      imr = CPUIO.inb 0xA1
      imr |= 1 << (irq - 8)
      CPUIO.outb 0xA1, imr
    else
      imr = CPUIO.inb 0x21
      imr |= 1 << irq
      CPUIO.outb 0x21, imr
    end
  end

  # Send EOI signal to the PIC for the `irq`.
  def eoi(irq : Int)
    if irq >= 8
      # send to slave
      CPUIO.outb 0xA0, 0x20
    end
    # send to master
    CPUIO.outb 0x20, 0x20
  end
end
