#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include "strbuf.h"

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

/* Declare all local functions */
static int extend(STRBUF *sb, unsigned int nlen);

/*
 * Create a STRBUF with the specified initial length.
 */
STRBUF *strbuf_create_empty(unsigned int len)
{
    STRBUF *sb;

    /* Allocate memory for the STRBUF */
    sb = (STRBUF *) malloc(sizeof(STRBUF));
    if (sb == NULL)
        return NULL;

    /* Allocate memory for the buffer */
    sb->buf = (unsigned char *) malloc(len);
    if (sb->buf == NULL)
        return NULL;

    /* Finish initializing the STRBUF */
    sb->i = 0;
    sb->n = 0;
    sb->len = len;
    sb->own = TRUE;

    /* Return a pointer to the STRBUF */
    return sb;
}

/*
 * Create a STRBUF from a buffer.  This can't be extended, because
 * it doesn't assume that the memory has been dynamically allocated.
 * The data buffer is neither reallocated or freed for any reason.
 */
STRBUF *strbuf_create_full(unsigned char *data, unsigned int len)
{
    STRBUF *sb;

    /* Allocate memory for the STRBUF */
    sb = (STRBUF *) malloc(sizeof(STRBUF));
    if (sb == NULL)
        return NULL;

    /* Finish initializing the STRBUF */
    sb->buf = data;
    sb->i = 0;
    sb->n = len;
    sb->len = len;
    sb->own = FALSE;

    /* Return a pointer to the STRBUF */
    return sb;
}

/*
 * Reset the position to the beginning of the buffer.
 */
int strbuf_rewind(STRBUF *sb)
{
    /* Set the current position to 0 */
    sb->i = 0;

    return 0;
}

/*
 * Reset the the data size to the current position.
 */
int strbuf_truncate(STRBUF *sb)
{
    /* Set the current data size to the current position */
    sb->n = sb->i;

    return 0;
}

/*
 * Deallocate the STRBUF and the buffer (if we should).
 */
void strbuf_destroy(STRBUF *sb)
{
    /* Deallocate the buffer if we own it */
    if (sb->own)
        free(sb->buf);

    /* Clear the STRBUF (not necessary) */
    sb->buf = NULL;
    sb->i = -1;
    sb->n = 0;
    sb->len = 0;

    /* Deallocate the STRBUF */
    free(sb);
}

/*
 * Write the specified amount of data to the STRBUF.
 */
int strbuf_write(STRBUF *sb, const unsigned char *data, unsigned int n)
{
    unsigned int nlen = sb->i + n;

    /* If the new string won't fit, extend sb */
    if (nlen > sb->len)
        if (extend(sb, 2 * nlen) != 0)
            return -1;

    /* Copy the data into the buffer, and update the position and size */
    memcpy(sb->buf + sb->i, data, n);
    sb->i += n;
    if (sb->i > sb->n)
        sb->n = sb->i;

    return 0;
}

int strbuf_printf(STRBUF *sb, const unsigned char *format, ...)
{
    va_list ap;
    int status;

    va_start(ap, format);
    status = strbuf_vprintf(sb, format, ap);
    va_end(ap);

    return status;
}

int strbuf_vprintf(STRBUF *sb, const unsigned char *format, va_list ap)
{
    int status;
    char *ret;

    /* Let vasprintf format the arguments to a dynamically allocated string */
    status = vasprintf(&ret, format, ap);

    /*
     * If vasprintf succeeded, write the result to the STRBUF,
     * and then deallocate the memory allocated by vasprintf.
     */
    if (status != -1) {
        strbuf_puts(sb, ret);
        free(ret);
    }

    return status;
}

/* Saving this in case vasprintf doesn't work out */
int strbuf_printf_SAVE(STRBUF *sb, unsigned char *format, ...)
{
    unsigned char buffer[128];  /* Used for converting numbers to strings */
    unsigned char *p;
    va_list ap;
    va_start(ap, format);

    for (p = format; *p != '\0'; p++) {
        if (*p == '%') {
            switch (*(p + 1)) {
            case '%':
                strbuf_putc(sb, (int) '%');
                p++;
                break;
            case 'c':
                strbuf_putc(sb, va_arg(ap, int));
                p++;
                break;
            case 'd':
                sprintf(buffer, "%d", va_arg(ap, int));
                strbuf_puts(sb, buffer);
                p++;
                break;
            case 'f':
                sprintf(buffer, "%f", va_arg(ap, double));
                strbuf_puts(sb, buffer);
                p++;
                break;
            case 'g':
                sprintf(buffer, "%g", va_arg(ap, double));
                strbuf_puts(sb, buffer);
                p++;
                break;
            case 's':
                strbuf_puts(sb, va_arg(ap, char *));
                p++;
                break;
            default:
                strbuf_putc(sb, (int) '%');
                break;
            }
        } else {
            strbuf_putc(sb, (int) *p);
        }
    }

    va_end(ap);
    return 0;
}

/*
 * Write a null-terminated string to the STRBUF.
 */
int strbuf_puts(STRBUF *sb, const unsigned char *s)
{
    return strbuf_write(sb, s, strlen(s));
}

/*
 * Write a character to the STRBUF.
 */
int strbuf_putc(STRBUF *sb, int c)
{
    unsigned int nlen = sb->i + 1;

    /* If the new character won't fit, extend sb */
    if (nlen > sb->len)
        if (extend(sb, 2 * nlen) != 0)
            return -1;

    /* Put the character into the buffer, and update the position and size */
    sb->buf[sb->i++] = (unsigned char) c;
    if (sb->i > sb->n)
        sb->n = sb->i;

    return 0;
}

/*
 * Read a string from the STRBUF.
 */
unsigned char *strbuf_gets(STRBUF *sb, unsigned char *s, unsigned int n)
{
    int c = -1;
    int i, j;

    for (i = 0, j = sb->i; i < n - 1 && j < sb->n && c != '\n'; i++, j++) {
        /* XXX Does this need to be case to a char? */
        s[i] = sb->buf[j];
        c = sb->buf[j];
    }

    /* XXX What if n is 0?  Do we return NULL? */
    if (i == 0) {
        return NULL;
    }

    /* Null terminate the user's string and update position if success */
    s[i] = '\0';
    sb->i = j;

    return s;
}

/*
 * Read a character from the STRBUF.
 */
int strbuf_getc(STRBUF *sb)
{
    int c = (sb->i < sb->n) ? sb->buf[sb->i++] : EOF;

    return c;
}

/*
 * Return the entire buffer.
 * Be careful, because it's not null-terminated!
 */
unsigned char *strbuf_getall(STRBUF *sb)
{
    /* Make sure there is enough memory to null-terminate the data
    if (sb->n == sb->len)
        if (extend(sb, 2 * sb->n) != 0)
            return NULL;
    /*
     * Write an EOS immediately after the data.  This allows the caller
     * to treat the data as a standard null-terminated string.
     */
    sb->buf[sb->n] = '\0';

    return sb->buf;
}

/*
 * Increase the allocated size of the buffer to the specified size.
 */
static int extend(STRBUF *sb, unsigned int nlen)
{
    unsigned char *buf;

    /* Do nothing if nlen isn't larger than the current size */
    if (nlen <= sb->len)
        return -1;  /* Not sure if this should be called an error or not */

    /* Return an error if we don't own the buffer */
    if (! sb->own)
        return -1;

    /* Try to reallocate the buffer */
    buf = (unsigned char *) realloc(sb->buf, nlen);
    if (buf == NULL)
        return -1;  /* Note that sb is untouched */

    /* Success, so update the STRBUF */
    sb->buf = buf;
    sb->len = nlen;

    return 0;
}
