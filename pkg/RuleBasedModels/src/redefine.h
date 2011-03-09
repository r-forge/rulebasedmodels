#ifndef _REDEFINE_H_
#define _REDEFINE_H_

#include <stdio.h>

#define restrict

FILE *rbm_fopen(const char *restrict filename, const char *restrict mode);
int rbm_fclose(FILE *stream);
int rbm_fflush(FILE *stream);
void rbm_rewind(FILE *stream);
int rbm_fgetc(FILE *stream);
int rbm_getc(FILE *stream);
char *rbm_fgets(char *restrict s, int n, FILE *restrict stream);
int rbm_fprintf(FILE *restrict stream, const char *restrict format, ...);
int rbm_fputc(int c, FILE *stream);
int rbm_putc(int c, FILE *stream);
int rbm_fputs(const char *restrict s, FILE *restrict stream);
size_t rbm_fwrite(const void *restrict ptr, size_t size, size_t nitems, FILE *restrict stream);
void rbm_remove(const char *fname);
void rbm_exit(int status);

#endif
