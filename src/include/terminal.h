#ifndef INCLUDE_TERMINAL_H
#define INCLUDE_TERMINAL_H

/* The I/O ports */
#define FB_COMMAND_PORT         0x3D4
#define FB_DATA_PORT            0x3D5
/* The I/O port commands */
#define FB_HIGH_BYTE_COMMAND    14
#define FB_LOW_BYTE_COMMAND     15

void putc(unsigned char c);
void move_cursor(unsigned short position);
void terminal_init(void);
void write_string(const char* string);
void write_int(int num);

#endif
