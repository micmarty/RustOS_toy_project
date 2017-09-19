section .multiboot_header
header_start:
    dd 0xe85250d6                ; standard multiboota
    dd 0                         ; tryb chroniony i386
    dd header_end - header_start ; powinno byc 24 bajty
    dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start));checksum
    ; -> trick 2^32 - (suma magic i flag) = 0
    ; z dokumentacji
    ;The field ‘checksum’ is a 32-bit unsigned value which,
    ;when added to the other magic fields
    ;(i.e. ‘magic’ and ‘flags’),
    ;must have a 32-bit unsigned sum of zero.


    ;tag konczacy
    dw 0
    dw 0
    dd 8
header_end:
