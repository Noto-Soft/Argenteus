bits 16
%define ENDL 0x0d, 0x0a
call ipget
ipget:
    pop bp
    sub bp, ipget
jmp main
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
main:
    mov ah, 0x0
    mov al, 0x3
    int 0x10
    call update_colors
    lea si, [bp+typer]
    call puts
.loop:
    mov ah, 0x0
    int 0x16
    cmp al, "\"
    je .return
    call putc
    jmp .loop
.return:
    mov ah, 0x0
    mov al, 0x3
    int 0x10
    call update_colors
    ret
typer: db "Typer: type whatever :)", ENDL, "backslash to exit", 0
times 512-($-$$) db 0