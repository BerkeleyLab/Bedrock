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
        *(*);
        . = ALIGN(4);
    }
}
