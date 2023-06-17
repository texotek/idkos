#include <stdint.h>
#include <stddef.h>
#include "include/io.h"

static const size_t vga_height = 20;
static const size_t vga_width = 80; 

size_t terminal_row = 0;
size_t terminal_column = 0;
uint8_t terminal_color = 0x0f;
volatile unsigned char *video = (volatile unsigned char *)0xb8000;

void move_cursor(unsigned short position) {
    outb(FB_COMMAND_PORT, FB_HIGH_BYTE_COMMAND);
    outb(FB_DATA_PORT,    ((position >> 8) & 0x00FF));
    outb(FB_COMMAND_PORT, FB_LOW_BYTE_COMMAND);
    outb(FB_DATA_PORT,    position & 0x00FF);
}

void write_string(const char* string) {
    uint16_t *vga_memory = (uint16_t*)video;
    while(*string != 0) {
        if(terminal_column > vga_width || *string == '\n') {
            terminal_row++;
            terminal_column = 0;
            string++;
            move_cursor(terminal_row*vga_width+terminal_column);
            continue;
        }
        *(vga_memory + terminal_row * vga_width + terminal_column++) = terminal_color << 8 | *string++;
        move_cursor(terminal_row*vga_width+terminal_column);
    }
}

void terminal_init(void) {
    uint16_t *buffer = (uint16_t*)video;
    for (size_t i = 0; i < vga_height; i++) {
        for (size_t j = 0; j < vga_width; j++) {
            buffer[vga_width * i + j] = terminal_color << 8 | 0x20 ;
        }
    }
     
}

void kmain(void) 
{
    terminal_init();
    write_string("Guten tag\nWie geht es dir?");
}
