; ==============================================================================
; PLIK: boot.asm
; Zadanie: Inicjalizacja procesora x86, przejście w tryb 32-bit i start Pascala.
; ==============================================================================

BITS 32                         ; Informujemy asembler, że generujemy kod 32-bitowy
; --- 1. NAGŁÓWEK MULTIBOOT (Wymagany przez GRUB) -----------------------------
MBOOT_PAGE_ALIGN    equ 1
MBOOT_MEMORY_INFO   equ 2
MBOOT_HEADER_MAGIC  equ 0x1BADB002
MBOOT_HEADER_FLAGS  equ (MBOOT_PAGE_ALIGN + MBOOT_MEMORY_INFO)
MBOOT_CHECKSUM      equ (0 - (MBOOT_HEADER_MAGIC + MBOOT_HEADER_FLAGS))

section .multiboot
align 4
    dd 0x1BADB002               ; Bezpośrednia wartość Magic
    dd 0x00000003               ; Bezpośrednia wartość Flags (1 + 2)
    dd 0xE4524FFF               ; Wyliczona na sztywno suma kontrolna (Checksum)

; --- 2. DEKLARACJA SYMBOLI ZEWNĘTRZNYCH --------------------------------------
global _start                   ; Punkt startowy dla linkera (LD)
extern KernelMain               ; Informacja, że ta funkcja jest w pliku Pascala

; --- 3. REZERWACJA MIEJSCA NA STOS SYSTEMOWY ----------------------------------
section .bss
align 16
stack_bottom:
    resb 16384                  ; Rezerwujemy 16 KB pamięci RAM na stos jądra
stack_top:

; --- 4. SEKCJA KODU WYKONYWALNEGO -------------------------------------------
section .text

_start:
    ; Ustalamy wskaźnik stosu (ESP) na wierzchołek zarezerwowanej pamięci
    ; Bez tego Pascal wyłoży się na pierwszej próbie zapisu zmiennej
    mov esp, stack_top

    ; Resetujemy rejestr flag procesora
    push 0
    popf

    ; Ładujemy naszą tabelę segmentów GDT (Global Descriptor Table)
    ; GRUB co prawda ustawia swoją, ale dobre jądro zawsze definiuje własną
    lgdt [gdt_descriptor]

    ; Odświeżamy segmenty procesora nowymi wartościami z tabeli GDT
    mov ax, 0x10                ; 0x10 to offset segmentu danych w naszej GDT
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Wykonujemy tzw. "Far Jump" (daleki skok), aby przeładować segment kodu (CS)
    ; 0x08 to offset segmentu kodu w naszej GDT. Skaczemy do etykiety .flush
    jmp 0x08:.flush

.flush:
    ; --- 5. SKOK DO PASCALA ---
    ; W tym momencie procesor jest idealnie skonfigurowany pod środowisko Pascala.
    ; Przekazujemy w rejestrach ewentualne informacje od GRUB-a (struktura multiboot)
    push ebx                    ; Adres struktury informacyjnej Multiboot (opcjonalne)
    push eax                    ; Magiczna liczba Multiboot (0x2BADB002)

    call KernelMain             ; WYWOŁANIE GŁÓWNEGO JĄDRA W PASCALU!

    ; --- 6. AWARYJNE ZATRZYMANIE (Jeśli Pascal kiedykolwiek by skończył działanie) ---
_kernel_panic:
    cli                         ; Wyłącz przerwania sprzętowe
.hang:
    hlt                         ; Zatrzymaj procesor (tryb uśpienia)
    jmp .hang                   ; Jeśli jakimś cudem wstanie, uśpij go znowu


; --- 7. STRUKTURA GDT (Global Descriptor Table) ------------------------------
; Definiuje jak system widzi pamięć RAM (jako jeden wielki płaski obszar 4 GB)
align 4
gdt_start:

gdt_null:                       ; Obowiązkowy pusty segment początkowy
    dd 0x0
    dd 0x0

gdt_code:                       ; Segment Kodu (Base=0, Limit=4GB, Read/Execute)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10011010b
    db 11001111b
    db 0x00

gdt_data:                       ; Segment Danych (Base=0, Limit=4GB, Read/Write)
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Rozmiar tabeli GDT
    dd gdt_start                ; Dokładny adres tabeli GDT w pamięci RAM