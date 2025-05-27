org 0x7c00
bits 16

%define ENDL 0x0d, 0x0a

jmp short start
nop

nsfs16_header:
drive: db 0
sectors_per_track: dw 0
heads: dw 0
nsfs_size: db NSFS_SIZE_C

start:
    jmp main

;
; subroutines
;

lba_to_chs:
    push ax
    push dx

    xor dx, dx
    div word [sectors_per_track]
    
    inc dx
    mov cx, dx

    xor dx, dx
    div word [heads]
    
    mov dh, dl
    mov ch, al
    shl ah, 6
    or cl, ah

    pop ax
    mov dl, al
    pop ax
    ret

disk_read:
    pusha

    push cx
    call lba_to_chs
    pop ax

    mov ah, 0x02
    mov di, 3
.attempt:
    pusha
    stc
    int 0x13
    jnc .done
    popa

    call disk_reset

    dec di
    test di, di
    jnz .attempt
.fail:
    jmp floppy_error
.done:
    popa

    popa
    ret

disk_reset:
    pusha
    mov ah, 0
    stc
    int 13h
    jc floppy_error
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
    inc si
    int 0x10
    jmp .loop
.done:
    popa
    ret

get_file:
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

    jmp fs_error ; no file found
.next:
    add si, 16
    jmp .loop
.found:
    mov ax, [si+11]
    mov bx, [si+13]
    mov cl, [si+15]
    mov [.result], ax
    mov [.result+2], bx
    mov [.result+4], cl
.done:
    popa
    mov ax, [.result]
    mov bx, [.result+2]
    mov cl, [.result+4]
    ret
.result:
    dw 0 ; lba on the floppy, relative to the end of the nsfs sector(s), so remember to add the value (1+nsfs_size) to the lba
    dw 0 ; offset from the start of the sector
    db 0 ; how many sectors required to be loaded

read_file:
    pusha
    push bx
    xor bh, bh
    mov bl, [nsfs_size]
    add ax, bx
    inc ax
    mov dl, [drive]
    pop bx
    call disk_read
    popa
    ret

;
; idk main stuff
;

main:
    mov [drive], dl
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov sp, 0x7c00

    push es
    mov ah, 08h
    int 13h
    jc floppy_error
    pop es

    and cl, 0x3F
    xor ch, ch
    mov [sectors_per_track], cx

    inc dh
    mov [heads], dh

    mov ah, 0x0
    mov al, 0x3
    int 0x10

    mov ax, 1
    mov cl, [nsfs_size]
    mov dl, [drive]
    mov bx, 0x500
    call disk_read

    mov di, kernel_name
    call get_file
    mov bx, 0xc000
    call read_file

    lea si, [nsfs16_header]

    jmp 0x0000:0xc000

floppy_error:
    mov si, msg_err.floppy
    call puts
    mov ah, 0
    int 16h
    jmp 0FFFFh:0

fs_error:
    mov si, msg_err.file
    call puts
    mov si, di
    call puts
    mov ah, 0
    int 16h
    jmp 0FFFFh:0

msg_err:
.floppy: db "Error reading from floppy", 0
.file: db "File not found:", 0

kernel_name: db "AG      BIN", 0

times 510-($-$$) db 0
dw 0xaa55

dw 5

db "AG      BIN"
dw 0
dw 0
db 4

db "COMMAND COM"
dw 6
dw 0
db 4

db "LORE    TXT"
dw 4
dw 0
db 1

db "PITS    TXT"
dw 10
dw 0
db 1

db "TESTMEM COM"
dw 5
dw 0
db 1

NSFS_SIZE_C equ 5
times (512+(512*NSFS_SIZE_C))-($-$$) db 0