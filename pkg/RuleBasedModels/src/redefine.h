#ifndef _REDEFINE_H_
#define _REDEFINE_H_

#include <stdio.h>
#include <setjmp.h>

#define JMP_OFFSET 100
extern jmp_buf rbm_buf;

FILE *rbm_fopen(const char *filename, const char *mode);
int rbm_fclose(FILE *stream);
int rbm_fflush(FILE *stream);
void rbm_rewind(FILE *stream);
int rbm_fgetc(FILE *stream);
int rbm_getc(FILE *stream);
char *rbm_fgets(char *s, int n, FILE *stream);
int rbm_fprintf(FILE *stream, const char *format, ...);
int rbm_fputc(int c, FILE *stream);
int rbm_putc(int c, FILE *stream);
int rbm_fputs(const char *s, FILE *stream);
size_t rbm_fwrite(const void *ptr, size_t size, size_t nitems, FILE *stream);
void rbm_remove(const char *fname);
void rbm_exit(int status);

#endif
