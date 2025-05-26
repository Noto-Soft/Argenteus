bits 16

call ipget
ipget:
    pop bp
    sub bp, ipget

lea si, [bp+linebreak]
times 2 call puts

lecommandthing:
    lea si, [bp+command]
    call puts

    lea di, [bp+commbuffer]
    mov bx, 0

    mov byte [di], 0
loop:
    mov ah, 0x0
    int 0x16
    cmp al, ("q" & ~(0x60))
    je return
    cmp al, 0x0d
    je runcomm
    call putc
    mov [di+bx], al
    inc bx
    mov byte [di+bx], 0
check_if_full:
    cmp bx, bufferlen
    jl loop

    lea si, [bp+toolong]
    call puts

    jmp lecommandthing

runcomm:
    lea si, [bp+linebreak]
    call puts

    lea si, [bp+commbuffer]
    lea di, [bp+commands.dir]
    call strcmp
    test ax, ax
    jz dir

    jmp lecommandthing

dir:
    mov si, 0x502
    lea di, [bp+.tmp]
    mov cx, [0x500]
.loop:
    push si
    push di
    push cx
    mov cx, 11
    rep movsb
    pop cx
    pop di
    lea si, [bp+.tmp]
    call puts
    pop si
    add si, 16
    loop .loop
.done:
    jmp lecommandthing
.tmp: times 11 db 0
        db 0x0a, 0x0d, 0

return:
    ret

putc:
    pusha
    mov ah, 0x0e
    mov bh, 0
    int 0x10
    popa
.done:
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

strcmp:
    push si
    push di
.loop:
    mov al, [si]
    mov ah, [di]
    inc si
    inc di
    cmp al, ah
    jne .notequal
    cmp al, 0
    je .endofstring
    jmp .loop
.endofstring:
    xor ax, ax
    jmp .done
.notequal:
    mov ax, 1
    jmp .done
.done:
    pop di
    pop si
    ret

bufferlen equ 64
commbuffer: times bufferlen db 0

linebreak: db 0x0a, 0x0d, 0
command: db "$ ", 0
toolong: db 0x0a, 0x0d, "Too long!", 0x0a, 0x0d, 0

commands:
.dir: db "dir", 0

times (512*4)-($-$$) db 0