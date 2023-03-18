org 0x7c00
bits 16

KERNEL_LOCATION equ 0x1000

DISK_NUM: db 0
mov [DISK_NUM], dl

mov ah, 2 ; Read from disk
mov al, 1 ; Read one sector

mov bx, 0x7e00 ; Where to read to

mov ch, 0 ; cylinder 0
mov cl, 2 ; Sector 2
mov dh, 0 ; Head 0
mov dl, DISK_NUM ; Disk number

int 0x13 ; Interrupt 0x13

mov ah, 0xe ; Print
mov al, [0x7e00]
int 0x10

jmp $

times 510-($-$$) db 0
dw 0xaa55
times 512 db 'A'