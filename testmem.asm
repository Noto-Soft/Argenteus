bits 16

jmp main

print_hex:
    pusha
    mov ah, 0x0e
    mov bh, 0
    mov [.bl], bl
    shr bl, 4
    and bl, 0xf
    mov si, bx
    lea di, [bp+.hexdigits]
    add si, di
    mov al, [si]
    int 0x10
    mov bl, [.bl]
    and bl, 0xf
    mov si, bx
    add si, di
    mov al, [si]
    int 0x10
    popa
    ret
.hexdigits: db "0123456789ABCDEF"
.bl: db 0

main:
    int 0x12

    mov bl, ah
    call print_hex
    mov bl, al
    call print_hex

    ret