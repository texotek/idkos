[org 0x7c00]
main:
    mov ax, 0x30
    call print16bit
    jmp $

print16bit:
    mov cx, 0 ; clear cx
    mov bx, 0x0a ; set divisor
    
convertNumber:
    mov dx, 0 ; clear dx
    div bx ; divide ax by 10 quotient -> al, remainder -> dx
    
    push dx ; push remainder to stack
    inc cx ; increment counter
    test ax, ax ; test if quotient is 0
    jnz convertNumber
    xor ax, ax 
printDigits:
    pop bx
    dec cx
    mov al, bl
    add al, '0'
    call print
    test cx, cx
    jnz printDigits
    ret
print:
    mov ah, 0xe
    int 0x10
    ret

;     push 0
; readString:
;     mov ah, 0x0
;     int 0x16
;
;     cmp al, 0xd
;     je printString
;
;     mov ah, 0xe
;     int 0x10
;
;     push ax
;     jmp readString
;
; printString:
;     pop ax
;     cmp ax, 0
;     je end
;     mov ah, 0xe
;     int 0x10
;     jmp printString

times 510-($-$$) db 0
db 0x55, 0xaa
