[org 0x7c00]

; In this program I will attempt to read from disk
; It will use the interrupt 0x13 function 0x02
; We address the sector with CHS addressing

; C=0, H=0, S=2
mov ah, 2 ; function 2
mov al, 1 ; number of sectors to be read
mov bx, 0x7e00 ; Where we load the sector
mov ch, 0 ; Cylinder 0
mov cl, 2 ; Sector number 2
mov dh, 0 ; Head number 0
; mov dl, [disknumber] ; Disk number
push 0
pop es
int 0x13

jc printError ; Jump if error

; Print out 0x7e00
mov ah, 0xe
mov al, [0x7e00]
int 0x10

jmp $

printError:
    db "Error: Disk read failed", 0
    mov bx, printError
    mov ah, 0xe
    printErrorLoop:
    mov al, [bx]
    cmp al, 0
    je end
    int 0x10
    inc bx
    jmp printErrorLoop
end:
times 510-($-$$) db 0
db 0x55, 0xaa
times 512 db 'A'
