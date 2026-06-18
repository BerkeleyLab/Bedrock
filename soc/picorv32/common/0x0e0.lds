/*
 * Linker script which reserves the first 0xE0 bytes for the bootloader,
 * such that the user program always starts from a fixed address
 */

MEMORY{
    blockRam (RWXAI) : ORIGIN = 0x00000000, LENGTH = BLOCK_RAM_SIZE
}

ENTRY(start);

SECTIONS {
    .bootloader : {
        KEEP(*bootloader.o(.text));
         . = 0xE0;
    }

    .text : {
        . = ALIGN(4);
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
        . = ALIGN(4);
        _bss_end = .;
    }

    .rodata : {
        . = ALIGN(4);
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
    }

    .data : {
        . = ALIGN(4);
        *(.data .data.*)
        *(.sdata .sdata.*)
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
        See comments in 0x000.lds
        */
        __tls_base = .;
        *(*);
        . = ALIGN(4);
    }
}
