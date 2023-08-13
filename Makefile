AS=nasm
ASFLAGS=-felf32
CC=i686-elf-gcc
CFLAGS=-std=gnu99 -ffreestanding -O2 -Wall -Wextra -nostdlib -nostdinc -I $(INCLUDE_DIR)

SRC_DIR=src
BUILD_DIR=build
INCLUDE_DIR=src/include

ASSEMBLY_FILES := $(wildcard $(SRC_DIR)/*.s)
C_FILES := $(wildcard $(SRC_DIR)/*.c)

ASSEMBLY_OBJECTS := $(patsubst $(SRC_DIR)/%.s,$(BUILD_DIR)/%.o,$(ASSEMBLY_FILES))
C_OBJECTS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(C_FILES))

KERNEL = idkos.bin

all: $(BUILD_DIR)/$(KERNEL)

$(BUILD_DIR)/$(KERNEL): $(ASSEMBLY_OBJECTS) $(C_OBJECTS)
	$(CC) -T $(SRC_DIR)/linker.ld -o $@ $(CFLAGS) $^ -lgcc

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.s
	mkdir -p $(BUILD_DIR)
	$(AS) $(ASFLAGS) $< -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	mkdir -p $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR)/*
bear:
	make clean && CC=/opt/homebrew/Cellar/i686-elf-gcc/13.1.0/bin/i686-elf-gcc bear -- make CC=cc
run: all
	qemu-system-i386 -kernel build/idkos.bin
	
