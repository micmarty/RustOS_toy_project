global long_mode_start

section .text
bits 64
long_mode_start:
    ;startujemy maina w rusta
    extern rust_main    ;wiemy ze jest w osobnym pliku
    call rust_main

    ; print `OKAY` to screen
    mov rax, 0x2f472f4e2f4f2f4c
    mov qword [0xb8000], rax
    hlt
