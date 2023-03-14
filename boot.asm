[org 0x7c00]
mov cx, 0
mov bx, string

read:
    ; read char
    mov ah, 0
    int 0x16

    ;mov ah, 0xe
    ;int 0x10
    
    ; save in string
    mov [bx], al
    inc bx

    ; see if string is full
    inc cx
    cmp cx, 31

    ; Jump
    je print
    jmp read

string:
    times 32 db 0

print:
    mov bx, string
    mov ah, 0xe
loop:
    mov al, [bx]
    cmp al, 0
    je end
    int 0x10
    inc bx
    jmp loop
end:

times 510-($-$$) db 0
db 0x55, 0xaa
