ENTRY(start)    /*  label od ktorego startujemy(linker szuka w plikch wejsciowych)  */

SECTIONS {
    . = 1M;     /*  podobno konwencja   */

    /*  miejsce na start kernela -> GRUB    */
    .boot :
    {
        /*  pierwszy w boot musi byc naglowek multiboot */
        /*  KEEP zapobiega usunieciu przez gc-sections w procesie linkowania    */
        KEEP(*(.multiboot_header))
    }

    /*  miejsce na kernel   */
    .text :
    {
        *(.text)
    }
}
