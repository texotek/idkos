; Bootloader for IDKOS
; Author Felix Dahmen (texotek)

org 0x7c00  ; BIOS loads first sector at 0x7c00
bits 16     ; Set execution mode to 16 bit

%define endl 0x0d, 0x0a

; FAT12 headers
jmp short main
nop

dfh_oem_name:             db "IDKOS0.1"     ; 8 bytes
dfh_bytes:                dw 512            ; Bytes per sector
dfh_sectors_per_cluster:  db 1
dfh_reserverd_sectors:    dw 1
dfh_fat_count:            db 2              ; File allocation table redundency count
dfh_dir_entry_count:      dw 0xe0           ; 244
dfh_total_sectors:        dw 2880
dfh_media_descriptor:     db 0xf0
dfh_sectors_per_fat:      dw 9
dfh_sectors_per_track:    dw 18
dfh_heads:                dw 2
dfh_hidden_sectors:       dd 0
dfh_large_sector_count:   dd 0

; extended boot record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd, useless
                            db 0                    ; reserved
ebr_signature:              db 0x29
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; serial number
ebr_volume_label:           db 'IDKOS      '        ; 11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '           ; 8 bytes

; Code goes here
main:
    ; setup data segments
    mov ax, 0                   ; can't set ds/es directly
    mov ds, ax
    mov es, ax
    
    ; setup stack
    mov ss, ax
    mov sp, 0x7c00              ; stack grows downwards from where we are loaded in memory

    mov [ebr_drive_number], dl

    mov si, msg_hello
    call print

    cli                         ; disable interrupts, this way CPU can't get out of "halt" state
    hlt

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

; Disk routines
;

;
; Converts an LBA address to a CHS address
; Parameters:
;   - ax: LBA address
; Returns:
;   - cx [bits 0-5]: sector number
;   - cx [bits 6-15]: cylinder
;   - dh: head
;

lba_to_chs:

    push ax
    push dx

    xor dx, dx                          ; dx = 0
    div word [dfh_sectors_per_track]    ; ax = LBA / SectorsPerTrack
                                        ; dx = LBA % SectorsPerTrack

    inc dx                              ; dx = (LBA % SectorsPerTrack + 1) = sector
    mov cx, dx                          ; cx = sector

    xor dx, dx                          ; dx = 0
    div word [dfh_heads]                ; ax = (LBA / SectorsPerTrack) / Heads = cylinder
                                        ; dx = (LBA / SectorsPerTrack) % Heads = head
    mov dh, dl                          ; dh = head
    mov ch, al                          ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           ; put upper 2 bits of cylinder in CL

    pop ax
    mov dl, al                          ; restore DL
    pop ax
    ret


;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;
disk_read:

    push ax                             ; save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx                             ; temporarily save CL (number of sectors to read)
    call lba_to_chs                     ; compute CHS
    pop ax                              ; AL = number of sectors to read
    
    mov ah, 0x02
    mov di, 3                           ; retry count

.retry:
    pusha                               ; save all registers, we don't know what bios modifies
    stc                                 ; set carry flag, some BIOS'es don't set it
    int 0x13                             ; carry flag cleared = success
    jnc .done                           ; jump if carry not set

    ; read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; all attempts are exhausted
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax                             ; restore registers modified
    ret

;
; Resets disk controller
; Parameters:
;   dl: drive number
;
disk_reset:
    pusha
    mov ah, 0
    stc
    int 0x13
    jc floppy_error
    popa
    ret

;
; Error handlers
;

floppy_error:
    mov si, msg_read_failed
    call print
    jmp wait_key_and_reboot

wait_key_and_reboot:
    mov ah, 0
    int 0x16                    ; wait for keypress
    jmp 0FFFFh:0                ; jump to beginning of BIOS, should reboot

.halt:
    cli                         ; disable interrupts, this way CPU can't get out of "halt" state
    hlt


;
; Messages
;

msg_read_failed:        db 'Read from disk failed!', endl, 0
msg_hello:              db 'Hello my friend', endl, 0

times 510-($-$$) db 0
dw 0xaa55