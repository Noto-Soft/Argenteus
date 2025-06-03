bits 16

%define ENDL 0x0d, 0x0a

; this is here to get the address where the program is loaded.
; In this case it doesn't matter because the bp is already used to absolute-call this program by command.com,
;   but since that isn't guranteed to be the case, we still have this here.
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
    lea si, [bp+message]
    call puts

    ret

message: db "This is a program running from disk!", ENDL, 0