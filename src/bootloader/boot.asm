; Bootloader for IDKOS
; Author Felix Dahmen (texotek)

KERNEL_LOCATION equ 0x1000
KERNEL_SEGMENT equ 0

%define endl 0x0d, 0x0a

org 0x7c00  ; BIOS loads first sector at 0x7c00
bits 16     ; Set execution mode to 16 bit

; FAT12 headers https://wiki.osdev.org/FAT12#FAT_12
jmp short main  ; Jump to main execution
nop             ; NOP because of these r

dfh_oem_name:             db "IDKOS0.1"     ; 8 bytes
dfh_bytes:                dw 512            ; Bytes per sector
dfh_sectors_per_cluster:  db 1              ; How much sectors there are for every cluster
dfh_reserverd_sectors:    dw 1              ; 1 Sector reserved for 
dfh_fat_count:            db 2              ; File allocation table redundency count
dfh_dir_entry_count:      dw 0xe0           ; 224
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

; main execution
main:
    ; setup data segments
    mov ax, 0                   ; can't set ds/es directly
    mov ds, ax
    mov es, ax

    ; setup stack
    mov ss, ax
    mov sp, 0x7c00              ; stack grows downwards from where we are loaded in memory

    mov [ebr_drive_number], dl

    ; Here I am calculating where the root directory is
    mov ax, [dfh_sectors_per_fat]
    mov dx, [dfh_fat_count]
    xor dh, dh
    mul dx ; as = Calculate fat sector count
    add ax, [dfh_reserverd_sectors] ; Add reserved sectors to ax
    push ax

    ; Now I will calulate the size of the root directory
    ; Formula (numberOfEntries * 32) / bytes_per_sector
    mov ax, [dfh_dir_entry_count]
    mov dx, 32
    mul dx

    div word [dfh_bytes]
    test dx, dx
    jz .read_root
    inc ax

.read_root:
    mov cx, 0
    mov cx, ax
    pop ax
    mov dl, [ebr_drive_number]
    mov bx, buffer

    call disk_read
    xor bx, bx
    mov di, buffer

.search_kernel:
    mov si, kernel_file_name
    mov cx, 11

    push di
    repe cmpsb
    pop di
    je .found_kernel 
    add di, 32
    inc bx
    cmp bx, [dfh_dir_entry_count]
    je kernel_not_found
    jmp .search_kernel
.found_kernel:

    ; di still has kernel location
    ; di offset by 26 bytes is the first cluster location
    mov ax, [di + 26]
    mov [kernel_sector], ax

    mov ax, [dfh_reserverd_sectors]
    mov bx, buffer
    mov cx, [dfh_sectors_per_fat]

    call disk_read

    mov bx, KERNEL_SEGMENT
    mov es, bx
    mov bx, KERNEL_LOCATION
.reading_kernel:

    ; Here I am calculating the logical block address of the kernel sector
    mov ax, [kernel_sector]
    add ax, 31

    ;mov dl, [dfh_sectors_per_cluster]
    ;xor dh, dh
    ;mul dx
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read

    add bx, [dfh_bytes] ; must be fixed later

    ; compute next cluster
    mov ax, [kernel_sector]
    mov cx, 3
    mul cx

    mov cx, 2
    div cx

    mov si, buffer
    add si, ax
    mov ax, [ds:si]

    or dx, dx
    jz .even

.odd:
    shr ax, 0x0fff
    jmp .nextcluster
.even:
    and ax, 0x0fff
.nextcluster:
    cmp ax, 0x0FF8
    jae .read_finish

    mov [kernel_sector], ax
    jmp .reading_kernel
.read_finish:

    mov dl, [ebr_drive_number]
    xor dh, dh

    mov ax, KERNEL_SEGMENT
    mov ds, ax
    mov ss, ax


    jmp KERNEL_SEGMENT:KERNEL_LOCATION

    jmp wait_key_and_reboot

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

;
; Disk routines
;

;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx memory address where to store read data
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
; Error handlers
;

floppy_error:
    mov si, msg_read_failed             
    call print                          ; Prints error
    jmp wait_key_and_reboot
kernel_not_found:
    mov si, msg_kernel_not_found
    call print                          ; Prints error
    jmp wait_key_and_reboot

wait_key_and_reboot:            ; Reboots the machine when pressing a key
    mov ah, 0
    int 0x16                    ; wait for keypress
    jmp 0xffff:0                ; jump to beginning of BIOS, should reboot
    cli                         ; disable interrupts, this way CPU can't get out of "halt" state
    hlt

;
; Messages and data
;

msg_read_failed:        db 'Read from disk failed!', endl, 0
msg_kernel_not_found:   db 'Kernel could not be found!', endl, 0
msg_hello:              db 'Hello my friend', endl, 0

kernel_file_name:       db 'KERNEL  BIN'
kernel_sector:          dw 0

times 510-($-$$) db 0
dw 0xaa55

buffer:
