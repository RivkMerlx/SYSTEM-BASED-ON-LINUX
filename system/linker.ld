ENTRY(KernelMain)
OUTPUT_FORMAT(elf32-i386)

SECTIONS
{
    . = 0x100000; /* Jądro ładowane w pamięci RAM pod adresem 1MB */

    .text : {
        *(.text)
    }
    .rodata : {
        *(.rodata)
    }
    .data : {
        *(.data)
    }
    .bss : {
        *(.bss)
    }
}