[org 0x7c00]

; In this program we enter 32bit protected mode
; For that we have to first define a global descriptor table

CODE_SEG equ code_descriptor - GDT_Start
DATA_SEG equ data_descriptor - GDT_Start

cli ; DISABLE interupts
lgdt [GDT_Descriptor]
; change last bit of cr0 to 1
mov eax, cr0
or eax, 1
mov cr0, eax ; 32bit protected mode
; far jump
jmp CODE_SEG:start_protected

jmp $

GDT_Start:
    null_descriptor:
        dd 0x0 ; define four bytes
        dd 0x0 ; define four bytes
    code_descriptor:
        dw 0xffff ; limit
        dw 0x0 ; 16 bits +
        db 0x0 ; 8 bits = 24 bit
        ; pres, priv, type
        db 0b10011010
        ; Other + limit (last four bits)
        db 0b11001111
        db 0x0
        ; last 0 bits
    data_descriptor:
        dw 0xffff ; limit
        dw 0x0 ; 16 bits +
        db 0x0 ; 8 bits = 24 bit
        ; pres, priv, type
        db 0b10010010
        ; Other + limit (last four bits)
        db 0b11001111
        db 0x0
GDT_End:

GDT_Descriptor:
    dw GDT_End - GDT_Start - 1 ;
    dd GDT_Start


[bits 32]
start_protected:

end:
jmp $

times 510-($-$$) db 0
db 0x55, 0xaa
