%define endl 0x0d, 0x0a

org 0x1000
bits 16

main:
    mov si, msg_hello
    call print

    cli
    hlt

msg_hello: db 'Welcome to kernel', endl, 0

;
; Prints a string to the screen
; Params:
;   - ds:si points to string
;
print:
    ; save registers we will modify
    push si
    push ax
    push bx

.loop:
    lodsb               ; loads next character in al
    or al, al           ; verify if next character is null?
    jz .done

    mov ah, 0x0E        ; call bios interrupt
    mov bh, 0           ; set page number to 0
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si    
    ret