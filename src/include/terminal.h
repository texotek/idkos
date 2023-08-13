#ifndef INCLUDE_TERMINAL_H
#define INCLUDE_TERMINAL_H

void putc(unsigned char c);
void move_cursor(unsigned short position);
void terminal_init(void);
void write_string(const char* string);
void printf(const char* format, ...);

#endif
