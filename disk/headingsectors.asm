bits 16

times 512 db 0

dw 1

db "TEST    TXT"
dw 0
dw 0
db 1

%include "nsfs.inc"
times (512+(512*NSFS_SIZE_C))-($-$$) db 0