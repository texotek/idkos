org 0x7c00
bits 16

%define endl 0xd, 0xa

jmp short main
nop

; FAT HEADERS
dfh_oem_name:             db "IDKOS0.1"     ; 8 bytes
dfh_bytes:                dw 512
dfh_sectors_per_cluster:  db 1
dfh_reserverd_sectors:    dw 1
dfh_fat_count:            db 2
dfh_dir_entry_count:      dw 0xe0
dfh_total_sectors:        dw 2880
dfh_media_descriptor:     db 0xf0
dfh_sectors_per_fat:      dw 9
dfh_sectors_per_track:    dw 18
dfh_heads:                dw 2
dfh_hidden_sectors:       dd 0
dfh_large_sector_count:   dd 0

; extended boot record
ebr_drive_number:       db 0                ; 0x00 floppy
                        db 0
ebr_signature:          db 0x29             
ebr_volume_id:          dd 0x12,0x34,0x56,0x78       ; Serial number
ebr_volume_label:       db "IDKOS      "    ; 11 bytes
ebr_volume_type:        db "FAT12   "       ; 8 bytes


main:
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