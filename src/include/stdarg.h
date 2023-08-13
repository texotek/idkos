#ifndef _STDARG_H
#define _STDARG_H

/* Define the necessary types */
typedef char* va_list;

/* Define the necessary macros */
#define va_start(ap, param) ((ap) = (va_list)&param + sizeof(param))
#define va_arg(ap, type) (*(type*)((ap) += sizeof(type), (ap) - sizeof(type)))
#define va_end(ap) ((void)0)

#endif /* _STDARG_H */
