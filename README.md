# IDKOS
Author: Felix Dahmen

## 1. About this project
With this project I am trying to create my own os.

Currently I have learnt how to program a Bootloader which can:
- print text to the screen
- read sectors with logical block addressing
- navigate a fat12 filesystem and find a file that is stored in the root directory
- change the instruction pointer to that file and resume execution there
- have some error handling

It is not:
- nothing is written in C
- it doesn't boot in 32bit protected mode (for that i need a 2 stage bootloader)
- the kernel has no fuctionality

## 2. Requirements
### 2.1 MacOS (Homebrew)
```bash
brew install mtools     # For the mcopy command
\ dosfstools            # Make FAT 12 floppy
\ qemu                  # Virtualization for i386
\ make                  # make tool
\ nasm                  # Assembler
```
### 2.2 Linux (Arch Linux)
```bash
sudo pacman -S qemu     # Virtualization
\ make                  # make tool
\ nasm                  # Assembler
```
**IMPORTANT**: Change in the Makefile: `mkdosfs` to `mkfs.fat` when you are on Linux.
### 2.3 Windows
Why are you even using this?
Switch to Linux!

In reality, I don't know how to set this up on Windows.

## 3. Running the thing

### 3.1 Just run
```bash
git clone git@github.com:texotek/idkos
cd idoks
make && qemu-system-i386 -fda build/main_floppy.img
```
### 3.2 Debugging
**IMPORTANT**: You need the **bochs** debugger
```bash
cd idkos
make && bochs -f boch_config
```