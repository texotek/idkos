ASM=nasm

SRC_DIR=src
BUILD_DIR=build

$(BUILD_DIR)/boot.bin: $(SRC_DIR)/boot.asm
	$(ASM) $(SRC_DIR)/boot.asm -f bin -o $(BUILD_DIR)/boot.bin