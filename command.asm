bits 16

call ipget
ipget:
    pop bp
    sub bp, ipget

lea si, [bp + linebreak]
times 2 call puts

lea si, [bp + command]
call puts

loop:
    mov ah, 0x0
    int 0x16
    cmp al, ("q" & ~(0x60))
    je return
    call putc
    jmp loop

return:
    ret

putc:
    pusha
    mov ah, 0x0e
    mov bh, 0
    int 0x10
    popa
    ret

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
    mov [.bl], bl
    shr bl, 4
    and bl, 0xf
    mov si, bx
    add si, .hexdigits
    mov al, [si]
    int 0x10
    mov bl, [.bl]
    and bl, 0xf
    mov si, bx
    add si, .hexdigits
    mov al, [si]
    int 0x10
    popa
    ret
.hexdigits: db "0123456789ABCDEF"
.bl: db 0

commbuffer: times 150 db 0
bufferlen equ $-commbuffer
commpos: db 0

linebreak: db 0x0a, 0x0d, 0
command: db "$ ", 0

times (512*4)-($-$$) db 0