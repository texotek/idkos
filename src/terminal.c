#include <io.h>
#include <terminal.h>
#include <stdint.h>
#include <stdarg.h>

static void write_int(int);

static const int vga_height = 20;
static const int vga_width = 80; 

int terminal_row = 0;
int terminal_column = 0;

void move_cursor(unsigned short position) {
    outb(0x3d4, 14);
    outb(0x3d5, ((position >> 8) & 0x00FF));
    outb(0x3d4, 15);
    outb(0x3d5, position & 0x00FF);
}

void printf(const char* format, ...) {

    va_list args;
    va_start(args, format);

    while (*format != 0) {
        if(*format != '%') {
            putc(*format++);
        }
        else {
            switch (*++format) {
                char *sval;
                case 'i':
                case 'd':
                    write_int(va_arg(args, int));
                    break;
                case 's':
                    for (sval = va_arg(args, char *); *sval; sval++) {
                        putc(*sval);
                    }
                    break;
            }
            format++;
        }
    }
    va_end(args);
}

static void write_int(int num) {
    char buffer[100];
    char isNegative = 0;
    int i = 0;

    if(num < 0) {
        isNegative = 1;
        num = -num;
    }
    do {
        buffer[i++] = 0x0f << 8 | ((num % 10) + '0');
        num = (num - num % 10) / 10;
    } while (num > 0);

    if(isNegative) putc('-');
    while (i > 0) putc(buffer[--i]);

}

void putc(unsigned char c) {
    volatile unsigned short *video_memory = (volatile unsigned short *)0xb8000;
    if (c == '\n' || terminal_column > 80) {
        terminal_column = 0;
        terminal_row++;
        move_cursor(vga_width * terminal_row + terminal_column);
        return;
    }
    *(video_memory + vga_width * terminal_row + terminal_column++) = 0x0f << 8 | c;
    move_cursor(vga_width * terminal_row + terminal_column);
}
void terminal_init(void) {
    volatile unsigned short *video_memory = (volatile unsigned short*)0xb8000;
    for (int i = 0; i < vga_height; i++) {
        for (int j = 0; j < vga_width; j++) {
            video_memory[vga_width * i + j] = 0x0f << 8 | 0x20 ;
        }
    }
}
