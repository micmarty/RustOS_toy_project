; Copyright 2015 Philipp Oppermann. See the README.md
; file at the top-level directory of this distribution.
;
; Licensed under the Apache License, Version 2.0 <LICENSE-APACHE or
; http://www.apache.org/licenses/LICENSE-2.0> or the MIT license
; <LICENSE-MIT or http://opensource.org/licenses/MIT>, at your
; option. This file may not be copied, modified, or distributed
; except according to those terms.

global start
extern long_mode_start;etykieta w innym pliku zeby wykonac far jump, tam bedzie 64 bitowy kod

section .text
bits 32
start:
    mov esp, stack_top

    call set_up_page_tables
    call enable_paging
    lgdt [gdt64.pointer] ;stworzenie i zaladowanie gdt (patrz etykieta)

    ; gdt nie jest jesszcze w 64 bitowym trybie, musimy akutalizowac zawartosci selektorow
    mov ax, gdt64.data  ; 8 bajt to segment kodu, 16 to segment danych
    mov ss, ax  ; stack selector
    mov ds, ax  ; data selector
    mov es, ax  ; extra selector
    jmp gdt64.code:long_mode_start  ;tzw daleki skok, far jump do innego pliku, bo long_mode_start jest externowany

    ;wyswietl OK
    mov dword [0xb8000], 0x2f4b2f4f
    hlt


;wyswietla OK na ekran przez bufor VGA
error:
    mov dword [0xb8000], 0x4f524f45; ;'R','E'
    mov dword [0xb8004], 0x4f3a4f52  ;':', 'R'
    mov dword [0xb8008], 0x4f204f20  ;dwie spacje
    mov byte  [0xb800a], al          ;znak bledu
    hlt


;skopiowalem z osdev
; Check for SSE and enable it. If it's not supported throw error "a".
set_up_SSE:
        ; check for SSE
        mov eax, 0x1
        cpuid
        test edx, 1<<25
        jz .no_SSE

        ; enable SSE
        mov eax, cr0
        and ax, 0xFFFB      ; clear coprocessor emulation CR0.EM
        or ax, 0x2          ; set coprocessor monitoring  CR0.MP
        mov cr0, eax
        mov eax, cr4
        or ax, 3 << 9       ; set CR4.OSFXSR and CR4.OSXMMEXCPT at the same time
        mov cr4, eax

        ret
.no_SSE:
        mov al, "a" ;kod bledu ktory wyswietlimy na ekranie
        jmp error

set_up_page_tables:
;podepnij adres P3 do pierwszego wpisu w tablicy P4
    mov eax, p3_table   ;adres przestrzeni tablicy P3
    or eax, 0b11        ;ustaw flage: present(strona w pamieci) i writable(mozliwosc edycji strony)
    mov [p4_table], eax ;wstaw do p4 wskaznik(adres) do tablicy P3

;podepnij adres P2 do pierwszego wpisu w tablicy P3
;analogicznie jak powyzej
    mov eax, p2_table
    or eax, 0b11
    mov [p3_table], eax

;kazdy wpis p2 podepnij pod kolejny ciag 2MB w przestrzeni (512 x 2MB = 1GB)
    mov ecx, 0  ;licznik petli
    .map_p2_table:
        mov eax, 2 << 20                ; 2^10 to 1024B, 2^20 = 2^10 * 2^10 = 1024*1024 co daje 2MB
        mul ecx ;mnozy licznik razy 2MB, czyli skacze w kazdym obiegu co 2MB
        or eax, 0b11000001              ;present, writable, huge
        mov [p2_table + ecx * 8], eax   ;mapuj 8bajtowe wpisy w p2 na 2 megowe strony w pamieci fizycznej
        inc ecx
        cmp ecx, 512                    ;warunek ze skonczylismy mapowanie 512 segmentow
        jne .map_p2_table               ;loopuj do etykiety
        ret

enable_paging:
    ;wpychamy adres P4 do CR3 -> specjalny rejestr, potrzebny CPU do mapowania
    mov eax, p4_table
    mov cr3, eax

    ;wlaczamy PAE dla trybu long mode -> Physical Address Extension
    mov eax, cr4
    or eax, 1 << 5  ;ustawiamy odpowiednia flage na 1
    mov cr4, eax

    ;wlaczamy long mode
    mov ecx, 0xC0000080 ;trzymamy adres do rejestru EFER
    rdmsr   ;czytaj z msr'a, korzystaj z 64 rejestru jakby czyli polaczony eax i ecx
    or eax, 1 << 8  ;ustaw flage
    wrmsr   ;write do msr'a

    ;uruchom stronnicowanie wreszcie
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax

    ret

section .rodata
;strefa readonly
gdt64:
    dq 0    ;wymagany wpis zerowy(0 entry) na poczatku tablicy gdt64

    ;https://puu.sh/sv1bt/f90fd50198.png
    ;segment kodu -> bity ustawione na: descriptor(44), present(47), read/write(41), executable(43), 64-bitowy segment(53)
.code: equ $ - gdt64    ;offset wzgledem poczatku (8 bajtow)
    dq (1<<44) | (1<<47) | (1<<41) | (1<<43) | (1<<53)
    ;segment danych -> descriptor(44), present(47), read/write(41)
.data: equ $ - gdt64    ;offset wzgledem poczatku (16 bajtow)
    dq (1<<44) | (1<<47) | (1<<41)

    ;chcemy wepchnac miejsce w pamieci tej tablicy strukturze lgdt (instrukcja load gdt)
.pointer:
    dw $ - gdt64 - 1    ;dlugosc strefy tablicy GDT $ to w sumie adres etykiety .pointer
    dq gdt64            ;adres poczatkowy tablicy GDT

section .bss
align 4096  ;wyrownanie do pelnej strony
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
p1_table:
    resb 4096
stack_bottom:
    resb 64
stack_top:
