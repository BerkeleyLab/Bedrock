/*
 * Linker script which does not reserve any space for the bootloader.
 */

MEMORY{
    blockRam (RWXAI) : ORIGIN = 0x00000000, LENGTH = BLOCK_RAM_SIZE
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
        . = ALIGN(4);
        _bss_start = .;
        *(.sbss);
        . = ALIGN(4);
        *(.bss);
        _bss_end = .;
    }

    /*
    get rid of some unneeded sections to save space
    */
    ./DISCARD/ : {
        *(.riscv.attributes);
        *(.comment);
    }

    .theRest : {
        . = ALIGN(4);
        /*
        We should peek at picolibc.ld to see how they construct an
        honest .tdata section.  Note that we don't actually use multiple
        threads; we're just trying to stay compatible with the copy of
        picolibc shipped by Debian in picolibc-riscv64-unknown-elf.
        This simple case is good enough for now, so random() can use
        some memory to hold its state.
        */
        __tls_base = .;
        *(*);
        . = ALIGN(4);
    }
}
