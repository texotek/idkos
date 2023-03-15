[org 0x7c00]

mov bp, 0x8000
mov sp, bp

readString:
    call __read

    ; Print out
    mov ah, 0xe
    int 0x10

    ; Push to stack
    push ax

    cmp al, 0xd ; check if enter was pressed
    jne readString ; return up

    call __print_crlf
printStringloop:
    ; Pop character
    sub bp, 2
    mov al, [bp]

    ; See if String has ended
    cmp al, 0xd
    je end

    ; Print character
    call __print

    ; loop
    jmp printStringloop

__read:
    mov ah, 0x0
    int 0x16
    ret

__print:
    mov ah, 0xe
    int 0x10
    ret

__print_crlf:
    pusha
    mov al, 0x0a
    call __print
    mov al, 0x0d
    call __print
    popa
    ret

__print16bit:
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
    call __print
    test cx, cx
    jnz printDigits
    ret
end:
jmp $

times 510-($-$$) db 0
db 0x55, 0xaa
