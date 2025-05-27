bits 16

call ipget
ipget:
    pop bp
    sub bp, ipget

jmp main

puts:
    pusha
    mov ah, 0x0e
    mov bx, 0
.loop:
    mov al, [si]
    cmp al, 0
    je .done
    int 0x10
    inc si
    jmp .loop
.done:
    popa
    ret

print_hex:
    pusha
    mov ah, 0x0e
    mov bh, 0
    mov [bp+.bl], bl
    shr bl, 4
    and bl, 0xf
    mov si, bx
    lea di, [bp+.hexdigits]
    add si, di
    mov al, [si]
    int 0x10
    mov bl, [bp+.bl]
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
    mov ah, 0x0e
    mov bh, 0
    mov al, "0"
    int 0x10
    mov al, "x"
    int 0x10

    int 0x12

    mov bl, ah
    call print_hex
    mov bl, al
    call print_hex
    lea si, [bp+kilobytes]
    call puts

    ret

kilobytes: db " kilobytes.", 0