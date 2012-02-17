/*
 Copyright (C) 2011-2012, Nathan Coulter and others 

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 2 of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#include "tcl.h"

#ifndef _STDIOCTCL

FILE * libc_stdin;
FILE * libc_stdout;
FILE * libc_stderr;

FILE * stdioctcl_stdin;
FILE * stdioctcl_stdout;
FILE * stdioctcl_stderr;

int stdioctcl_set_stdin (Tcl_Channel chan);
int stdioctcl_set_stdout (Tcl_Channel chan);
int stdioctcl_set_stderr (Tcl_Channel chan);

typedef FILE *(*fopenPtr)(__const char *__restrict __filename,
	__const char *__restrict __modes);
fopenPtr libc_fopen = fopen;

typedef int (*fclosePtr)(FILE*stream);
fclosePtr libc_fclose = fclose;
typedef int (*feofPtr)(FILE *stream);
feofPtr libc_feof = feof;
typedef int (*fflushPtr)(FILE *stream);
fflushPtr libc_fflush = fflush;
typedef int (*fgetcPtr)(FILE * stream);
fgetcPtr libc_fgetc = fgetc;
typedef char *(*fgetsPtr)
	(char *__restrict __s, int __n, FILE *__restrict __stream);
fgetsPtr libc_fgets = fgets;
typedef int (*fprintfPtr)(FILE *stream ,const char *template ,...);
fprintfPtr libc_fprintf = fprintf;
typedef int (*fputcPtr)(int c ,FILE *stream);
fputcPtr libc_fputc = fputc;
typedef int (*fputsPtr)(const char *S ,FILE *stream);
fputsPtr libc_fputs = fputs;
typedef size_t (*fwritePtr)
	(const void *data ,size_t size ,size_t count ,FILE *stream);
typedef size_t (*freadPtr)(void *data ,size_t size ,size_t count ,FILE *stream);
freadPtr libc_fread = fread;
fwritePtr libc_fwrite = fwrite;
typedef int (*getcPtr)(FILE *stream);
getcPtr libc_getc = getc;
typedef int (*putcharPtr)(int c);
putcharPtr libc_putchar = putchar;
typedef void (*rewindPtr)(FILE *stream);
rewindPtr libc_rewind = rewind;
typedef int (*snprintfPtr)(char *s ,size_t size ,const char * template ,...);
snprintfPtr libc_snprintf = snprintf;

int stdioctcl_init ();
Tcl_Interp *stdioctcl_interp_get();
Tcl_Interp *stdioctcl_interp_set(Tcl_Interp *new);
FILE * stdioctcl_fopen(const char *filename ,const char *opentype);
int stdioctcl_fclose(FILE *stream);
int stdioctcl_feof(FILE *stream);
int stdioctcl_fflush(FILE *stream);
int stdioctcl_fgetc(FILE *stream);
#define stdioctcl_getc stdioctcl_fgetc 
char * stdioctcl_fgets(char *s ,int count ,FILE *stream);
int stdioctcl_fprintf(FILE *stream ,const char *template ,...);
int stdioctcl_fprintf_ap(FILE *stream ,const char *template ,va_list ap);
int stdioctcl_fputc(int c ,FILE *stream);
int stdioctcl_fputs (const char *s ,FILE *stream);
size_t stdioctcl_fread(void *data ,size_t size ,size_t count ,FILE *stream);
size_t stdioctcl_fwrite(
	const void *data ,size_t size ,size_t count ,FILE *stream);
/* TODO:
stdioctcl_freopen
int stdioctcl_snprintf(char *s ,size_t size ,const char * template ,...);
*/
int stdioctcl_putchar(int c);
void stdioctcl_rewind(FILE *stream);
#define _STDIOCTCL
#endif

