mov ax, 10

jmp $
times 510-($-$$) db 0
db 0x55, 0xaa
