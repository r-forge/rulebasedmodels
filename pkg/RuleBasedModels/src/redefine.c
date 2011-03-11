#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>

#include "redefine.h"
#include "strbuf.h"

/* Don't want to include R.h which has conflicts */
extern void Rprintf(const char *, ...);

/*
 * Not sure what value to use, but it will be automatically increased
 * if necessary, so the initial value is not critical.
 */
#define STRBUF_LEN 100

/* Used by rbm_initexit and rbm_exit */
jmp_buf rbm_buf;

/* Need to keep this in sync with strbufv and exts */
#define STRBUFV_LEN 7

/*
 * This is used to save the contents of files that have been
 * created and written.  We only use the file extension to do
 * this, since all files created by cubist on a given run
 * use the same "file stem".
 */
static STRBUF *strbufv[STRBUFV_LEN] = { NULL };

static char *exts[STRBUFV_LEN] = {
    ".pred", ".model", ".names", ".data", ".tmp", ".test", ".stdout"
};

static char *id2ext(int id)
{
    if (id < 0 || id >= STRBUFV_LEN)
        return NULL;

    return exts[id];
}

/* Used to determine index into strbufv */
static int ext2id(const char *ext)
{
    int i;
    int id = -1;

    if (ext != NULL) {
        for (i = 0; i < STRBUFV_LEN; i++) {
            if (strcmp(ext, exts[i]) == 0) {
                id = i;
                break;
            }
        }
    }

    return id;
}

/* This is similar to rbm_fopen */
int rbm_register(STRBUF *sb, const char *filename, int force)
{
    int id = ext2id(strrchr(filename, '.'));

    Rprintf("rbm_register: registering file: %s\n", filename);

    if (id == -1) {
        Rprintf("rbm_register: error: bad file extension: %s\n", filename);
        return -1;
    }

    if (strbufv[id] != NULL) {
        if (force) {
            Rprintf("rbm_register: warning: file already registered: %s\n",
                    filename);
        } else {
            Rprintf("rbm_register: error: file already registered: %s\n",
                    filename);
            return -1;
        }
    }

    /* XXX Should I provide an "isopen" function for STRBUF? */
    if (sb->open) {
        Rprintf("rbm_register: error: cannot register an open file: %s\n",
                filename);
        return -1;
    }

    strbufv[id] = sb;

    return 0;
}

/* This is similar to rbm_remove, but doesn't destroy the STRBUF */
int rbm_deregister(const char *filename)
{
    int id = ext2id(strrchr(filename, '.'));

    Rprintf("rbm_deregister: deregistering file: %s\n", filename);

    if (id == -1) {
        Rprintf("rbm_deregister: error: bad file extension: %s\n", filename);
        return -1;
    }

    if (strbufv[id] == NULL) {
        Rprintf("rbm_deregister: error: file not registered: %s\n", filename);
        return -1;
    }

    /* Remove the reference to the STRBUF */
    strbufv[id] = NULL;

    return 0;
}

STRBUF *rbm_lookup(const char *filename)
{
    int id;

    Rprintf("rbm_lookup: looking up file: %s\n", filename);

    id = ext2id(strrchr(filename, '.'));
    if (id == -1) {
        Rprintf("rbm_lookup: error: no file registered: %s\n", filename);
        return NULL;
    }

    return strbufv[id];
}

FILE *rbm_fopen(const char *filename, const char *mode)
{
    STRBUF *sb;
    int id = ext2id(strrchr(filename, '.'));

    /* Only the "w" mode is currently supported */
    if (strcmp(mode, "w") == 0) {
        Rprintf("rbm_fopen: opening file to write: %s\n", filename);
        sb = strbuf_create_empty(STRBUF_LEN);
        if (id == -1) {
            Rprintf("rbm_fopen: warning: unable to register bad file extension: %s\n", filename);
        } else {
            if (strbufv[id] != NULL) {
                Rprintf("rbm_fopen: warning: destroying previous STRBUF: %s\n", filename);
                strbuf_destroy(strbufv[id]);
            }
            strbufv[id] = sb;
        }
    } else {
        Rprintf("rbm_fopen: opening file to read: %s\n", filename);
        if (id == -1) {
            Rprintf("rbm_fopen: error: bad file extension: %s\n", filename);
            sb = NULL;
        } else {
            sb = strbufv[id];
            if (sb != NULL) {
                if (sb->open) {
                    Rprintf("rbm_fopen: error: file already open: %s\n", filename);
                    sb = NULL;
                } else {
                    strbuf_open(sb);
                    strbuf_rewind(sb);
                }
            } else {
                Rprintf("rbm_fopen: error: no such file: %s\n", filename);
            }
        }
    }

    return (FILE *) sb;
}

int rbm_fclose(FILE *stream)
{
    return strbuf_close((STRBUF *) stream);
}

int rbm_fflush(FILE *stream)
{
    /* Nothing to do */
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

int rbm_remove(const char *path)
{
    STRBUF *sb = rbm_lookup(path);

    if (sb == NULL) {
        return -1;
    }

    rbm_deregister(path);
    strbuf_destroy(sb);

    return 0;
}

/*
 * This is called at the beginning a cubist run to clear out all "files"
 * generated on the previous run.
 */
void rbm_removeall()
{
    int id;
    STRBUF *sb;

    for (id = 0; id < STRBUFV_LEN ; id++) {
        sb = strbufv[id];
        if (sb != NULL)
            strbuf_destroy(sb);
        strbufv[id] = NULL;
    }
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
