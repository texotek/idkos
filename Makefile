ASM=nasm
CC=i686-elf-gcc

SRC_DIR=src
BUILD_DIR=build

all: boot.s kernel.c io.s
	$(CC) -T $(SRC_DIR)/linker.ld -o $(BUILD_DIR)/idkos.bin -ffreestanding -O2 -nostdlib $(BUILD_DIR)/boot.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/io.o -lgcc
	# grub-mkrescue -o $(BUILD_DIR)/idkos.iso grub.cfg 

kernel.c:
	$(CC) -c $(SRC_DIR)/kernel.c -o $(BUILD_DIR)/kernel.o -std=gnu99 -ffreestanding -O2 -Wall -Wextra
boot.s:
	$(ASM) -felf32 $(SRC_DIR)/boot.s -o $(BUILD_DIR)/boot.o
io.s:
	$(ASM) -felf32 $(SRC_DIR)/io.s -o $(BUILD_DIR)/io.o

always:
	mkdir -p $(BUILD_DIR)
clean:
	rm -rf $(BUILD_DIR)/*
