/*
 * Linker script which does not reserve any space for the bootloader.
 */

MEMORY{
    blockRam (RWXAI) : ORIGIN = 0x00000000, LENGTH = MEM_SIZE
}

ENTRY(start);

SECTIONS {
    .bootloader : {
        KEEP(*bootloader.o(.text));
    }

    .text : {
        _startup_adr = .;
        KEEP(*startup.o(.text));
        KEEP(*startup_irq.o(.text));
        *(.text*);
    }

    /* uninitialized globals, set to zero by startup.S */
    .bss : {
        _bss_start = .;
        *(.sbss);
        *(.bss);
        _bss_end = .;
    }

    /* get rid of .riscv.attributes sections,
       which have been appearing since GNU Binutils 2.32
       ... absolutely no idea what they are used for. */
    ./DISCARD/ : {
        *(.riscv.attributes)
    }

    .theRest : { *(*); . = ALIGN(4); }
}
