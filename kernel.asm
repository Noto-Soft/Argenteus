org 0xc000
bits 16
%define ENDL 0x0d, 0x0a
jmp short start
nop
nsfs16_header:
drive: db 0
sectors_per_track: dw 0
heads: dw 0
nsfs_size: db 2
drive_c_header:
    dw 0
    dw 0
    dw 0
start:
    jmp setup
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
read_file_data:
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
read_file:
    pusha
    push bx
    call get_file
    pop bx
    call read_file_data
    popa
    ret
;
; idk main stuff
;
setup:
    mov al, [si]
    mov bx, [si+1]
    mov cx, [si+3]
    mov dl, [si+5]
    mov [drive], al
    mov [sectors_per_track], bx
    mov [heads], cx
    mov [nsfs_size], dl
    mov ax, [nsfs16_header]
    mov [drive_c_header], ax
    mov ax, [nsfs16_header+2]
    mov [drive_c_header+2], ax
    mov ax, [nsfs16_header+4]
    mov [drive_c_header+4], ax
main:
    mov di, test_file_name
    mov bx, 0x3000
    call read_file
    
    mov si, 0x3000
    call puts
    mov di, testmem_filename
    mov bx, 0x3000
    call read_file
    call 0x3000
.command_com:
    mov di, commandcom_filename
    mov bx, 0x3000
    call read_file
    push 0
.loop:
    pop dx
    call 0x3000
    push dx
    cmp dl, 0x14
    je switch_drive
    cmp dl, 69
    je reboot
    call read_file
    jmp .loop
    jmp $
switch_drive:
    cmp dh, 0x0a
    je .drive_a
    cmp dh, 0x0c
    je .drive_c
    jmp main.loop
.drive_a:
    mov dl, 1
    mov [drive], dl
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
    jmp .exit
.drive_c:
    mov ax, [drive_c_header]
    mov [nsfs16_header], ax
    mov ax, [drive_c_header+2]
    mov [nsfs16_header+2], ax
    mov ax, [drive_c_header+4]
    mov [nsfs16_header+4], ax
    jmp .exit
.exit:
    mov ax, 1
    mov cl, [nsfs_size]
    mov dl, [drive]
    mov bx, 0x500
    call disk_read
    jmp main.loop
reboot:
    mov ax, [drive_c_header]
    mov [nsfs16_header], ax
    mov ax, [drive_c_header+2]
    mov [nsfs16_header+2], ax
    mov ax, [drive_c_header+4]
    mov [nsfs16_header+4], ax
    mov ax, 0
    mov es, ax
    mov bx, 0x7c00
    mov dl, [drive]
    mov cl, 1
    call disk_read
    jmp 0xffff:0x0000
floppy_error:
    mov si, msg_err.floppy
    call puts
    mov sp, 0x7c00
    jmp main.command_com
fs_error:
    mov si, msg_err.file
    call puts
    mov si, di
    call puts
    mov sp, 0x7c00
    jmp main.command_com
msg_err:
.floppy: db "Error reading from floppy", 0
.file: db "File not found:", 0
test_file_name: db "LORE    TXT", 0
testmem_filename: db "TESTMEM COM", 0
commandcom_filename: db "COMMAND COM", 0
times (512*4)-($-$$) db 0