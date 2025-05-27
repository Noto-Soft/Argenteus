bits 16

call ipget
ipget:
    pop bp
    sub bp, ipget

cmp dl, 0x65
je finish_type

jmp start

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

start:
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

    lea si, [bp+commbuffer]
    lea di, [bp+commands.type]
    call strcmp
    test ax, ax
    jz type

    lea si, [bp+commbuffer]
    lea di, [bp+commands.help]
    call strcmp
    test ax, ax
    jz help

    jmp lecommandthing

help:
    lea si, [bp+commands]
    call puts
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
    push bx
    mov bl, [si+15]
    call print_hex
    pop bx
    add si, 16
    push si
    lea si, [bp+linebreak]
    call puts
    pop si
    loop .loop
.done:
    jmp lecommandthing
.tmp: times 11 db 0
        db 0x20, 0

type:
    mov bx, 0
    lea di, [bp+.tmp]
.getfilenameloop:
    mov ah, 0x0
    int 0x16
    call putc
    mov [di+bx], al
    inc bx
    cmp bx, 11
    jne .getfilenameloop
    mov bx, 0x7c00
    mov dl, 0x65
    ret
.tmp: times 11 db 0
        db 0

finish_type:
    xor dl, dl
    mov si, 0x7c00
    call puts
    jmp lecommandthing

return:
    ret

bufferlen equ 64
commbuffer: times bufferlen db 0

linebreak: db 0x0a, 0x0d, 0
command: db "$ ", 0
toolong: db 0x0a, 0x0d, "Too long!", 0x0a, 0x0d, 0

commands: db "List of commands: dir, help, type", 0x0a, 0x0d, 0
.dir: db "dir", 0
.help: db "help", 0
.type: db "type", 0

times (512*4)-($-$$) db 0