bits 16

%define ENDL 0x0d, 0x0a

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
    call update_colors
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
    call update_colors
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
    call update_colors
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

strcmp_until_di_end:
    push si
    push di
.loop:
    mov al, [si]
    mov ah, [di]
    inc si
    inc di
    cmp ah, 0
    je .endofstring
    cmp al, ah
    jne .notequal
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

get_file:
    clc
    pusha
    mov cx, [0x500] ; the amount of files available
    ; di contains the wanted filename
    mov si, 0x502 ; location of first entry
.loop:
    push cx
    push si
    push di
    mov cx, 11
    rep cmpsb
    pop di
    pop si
    pop cx
    je .found
    loop .next ; if there are still files left to check, continue

    jmp .fs_error ; no file found
.next:
    add si, 16
    jmp .loop
.found:
    mov ax, [si+11]
    mov bx, [si+13]
    mov cl, [si+15]
    mov [bp+.result], ax
    mov [bp+.result+2], bx
    mov [bp+.result+4], cl
.done:
    popa
    mov ax, [.result]
    mov bx, [.result+2]
    mov cl, [.result+4]
    ret
.fs_error:
    popa
    stc
    ret
.result:
    dw 0 ; lba on the floppy, relative to the end of the nsfs sector(s), so remember to add the value (1+nsfs_size) to the lba
    dw 0 ; offset from the start of the sector
    db 0 ; how many sectors required to be loaded

capitalize:
    push bx
    mov bx, ax
    mov ah, al
    or ah, 0x20
    cmp ah, "a"
    jl .done
    cmp ah, "z"
    jg .done
    and al, ~(0x20)
.done:
    mov ah, bh
    pop bx
    ret

update_colors:
    pusha
    mov cx, 0
.loop:
    mov bx, cx
    shl bx, 1
    inc bx
    mov byte [fs:bx], 0x1f
    inc cx
    cmp cx, 80*25
    jne .loop
.done:
    popa
    ret

start:
    lea si, [bp+linebreak]
    times 2 call puts

lecommandthing:
    lea si, [bp+command]
    call puts

    lea di, [bp+commbuffer]
    mov bx, 0

    call reset_commbuffer
loop:
    mov ah, 0x0
    int 0x16
    cmp al, ("q" & ~(0x60))
    je return
    cmp al, 0x0d
    je runcomm
    cmp al, 0x08
    je backspace
    cmp bx, bufferlen-1
    jnl loop
    call putc
    mov [di+bx], al
    inc bx
    mov byte [di+bx], 0
    jmp loop
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
    call strcmp_until_di_end
    test ax, ax
    jz type

    lea si, [bp+commbuffer]
    lea di, [bp+commands.help]
    call strcmp
    test ax, ax
    jz help

    lea si, [bp+commbuffer]
    lea di, [bp+commands.echo]
    call strcmp_until_di_end
    test ax, ax
    jz echo

    lea si, [bp+commbuffer]
    lea di, [bp+commands.cls]
    call strcmp
    test ax, ax
    jz cls

    cmp bx, 0
    je lecommandthing

    lea si, [bp+msg_err.invalid_command]
    call puts

    jmp lecommandthing
backspace:
    cmp bx, 0
    jng loop

    call putc
    push ax
    mov al, " "
    call putc
    pop ax
    call putc

    dec bx
    mov byte [di+bx], 0
    
    jmp loop

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
    mov dl, 0x65
    jmp retrieve

retrieve:
    mov di, si
    add di, 5
    call get_file
    jc .not_exist
    mov bx, 0x8000
    ret
.not_exist:
    lea si, [bp+msg_err.file_not_found]
    call puts
    mov si, di
    call puts
    lea si, [bp+msg_err.file_not_found_suggestion]
    call puts
    jmp lecommandthing
.tmp: times 11 db 0
        db 0

echo:
    add si, 5
    call puts
    lea si, [bp+linebreak]
    call puts
    jmp lecommandthing

cls:
    mov ah, 0x0
    mov al, 0x3
    int 0x10
    lea si, [bp+msg.screen_cleared]
    call puts
    jmp lecommandthing

finish_type:
    xor dl, dl
    mov si, 0x8000
    call puts
    jmp lecommandthing

reset_commbuffer:
    pusha
    mov bx, bufferlen - 1
    lea di, [bp+commbuffer]
.loop:
    mov byte [di+bx], 0
    dec bx
    jnz .loop
    popa
    ret

return:
    ret

linebreak: db ENDL, 0
command: db "$ ", 0

msg:
.screen_cleared: db "Screen cleared.", ENDL, 0

msg_err:
.file_not_found: db "File not found: ", 0
.file_not_found_suggestion: db ENDL, "Use 'dir' to get a list of all available commands.", ENDL, 0
.invalid_command: db "THAT is not a command! Use 'help' stinky", ENDL, 0

commands: db "List of commands: cls, dir, echo, help, type", ENDL, 0
.cls: db "cls", 0
.dir: db "dir", 0
.echo: db "echo", 0
.help: db "help", 0
.type: db "type", 0

bufferlen equ 512
commbuffer: times bufferlen db 0

times (512*4)-($-$$) db 0