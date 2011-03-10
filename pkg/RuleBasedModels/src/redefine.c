#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>

#include "redefine.h"
#include "strbuf.h"

/*
 * Not sure what value to use, but it will be automatically increased
 * if necessary, so the initial value is not critical.
 */
#define STRBUF_LEN 100

/* Used by rbm_initexit and rbm_exit */
jmp_buf rbm_buf;

FILE *rbm_fopen(const char *filename, const char *mode)
{
    STRBUF *sb;

    /* Only the "w" mode is currently supported */
    if (strcmp(mode, "w") == 0) {
        sb = strbuf_create_empty(STRBUF_LEN);
    } else {
        sb = NULL;
    }

    return (FILE *) sb;
}

int rbm_fclose(FILE *stream)
{
    return 0;
}

int rbm_fflush(FILE *stream)
{
    return 0;
}

void rbm_rewind(FILE *stream)
{
    strbuf_rewind((STRBUF *) stream);
}

int rbm_fgetc(FILE *stream)
{
    return strbuf_getc((STRBUF *) stream);
}

int rbm_getc(FILE *stream)
{
    return strbuf_getc((STRBUF *) stream);
}

char *rbm_fgets(char *s, int n, FILE *stream)
{
    return strbuf_gets((STRBUF *) stream, s, n);
}

int rbm_fprintf(FILE *stream, const char *format, ...)
{
    va_list ap;
    int status;

    va_start(ap, format);
    status = strbuf_vprintf((STRBUF *) stream, format, ap);
    va_end(ap);

    return status;
}

int rbm_fputc(int c, FILE *stream)
{
    return strbuf_putc((STRBUF *) stream, c);
}

int rbm_putc(int c, FILE *stream)
{
    return strbuf_putc((STRBUF *) stream, c);
}

int rbm_fputs(const char *s, FILE *stream)
{
    return strbuf_puts((STRBUF *) stream, s);
}

size_t rbm_fwrite(const void *ptr, size_t size, size_t nitems, FILE *stream)
{
    return strbuf_write((STRBUF *) stream, ptr, nitems * size);
}

void rbm_remove(const char *fname)
{
    /* Do nothing */
}

/*
 * The jmp_buf needs to be initialized before calling this.
 * Also, this must be called further down the stack from the
 * code that called setjmp to initialize rbm_buf.
 * That's why we can't have a function that initialize the
 * jmp_buf, but must use a macro instead.
 */
void rbm_exit(int status)
{
    /* This doesn't return */
    longjmp(rbm_buf, status + JMP_OFFSET);
}
