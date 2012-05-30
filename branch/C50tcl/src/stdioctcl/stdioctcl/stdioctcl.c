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

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

#include "tcl.h"
#include "stdioctcl.h"

static mode_t read_umask(void);

static Tcl_Interp *interp = NULL;

FILE * stdioctcl_stdin;
FILE * stdioctcl_stdout;
FILE * stdioctcl_stderr;
static int libc_initialized = 0;

int stdioctcl_libc_init () {
	libc_stdin = stdin; 
	libc_stdout = stdout;
	libc_stderr = stderr;
	libc_initialized = 1;

	libc_fopen = fopen;
	libc_fclose = fclose;
	libc_feof = feof;
	libc_fflush = fflush;
	libc_fgetc = fgetc;
	libc_fgets = fgets;
	libc_fprintf = fprintf;
	libc_fputc = fputc;
	libc_fputs = fputs;
	libc_fread = fread;
	libc_fwrite = fwrite;
	libc_getc = getc;
	libc_putchar = putchar;
	libc_rewind = rewind;
	libc_snprintf = snprintf;

}

int stdioctcl_io_tcl_init() {
	if (!libc_initialized) {
		stdioctcl_libc_init();
	}
	stdioctcl_stdin = (FILE *) Tcl_GetStdChannel(TCL_STDIN);
	stdioctcl_stdout = (FILE *) Tcl_GetStdChannel(TCL_STDOUT);
	stdioctcl_stderr = (FILE *) Tcl_GetStdChannel(TCL_STDERR);

	return 0;
}

int stdioctcl_set_stdin (Tcl_Channel chan) {
	stdioctcl_stdin = (FILE *) chan;
}

int stdioctcl_set_stdout (Tcl_Channel chan) {
	stdioctcl_stdout = (FILE *) chan;
}

int stdioctcl_set_stderr (Tcl_Channel chan) {
	stdioctcl_stderr = (FILE *) chan;
}



Tcl_Interp *stdioctcl_interp_get() {
	return interp;
}

Tcl_Interp *stdioctcl_interp_set(Tcl_Interp *new) {
	interp = new;
	return interp;
}

int stdioctcl_fclose(FILE *stream) {
	if (Tcl_Close(interp ,(Tcl_Channel) stream) != TCL_OK) {
		return EOF;
	}
	return 0;
}

int stdioctcl_fflush(FILE *stream) {
	if (stream == NULL) {
		return libc_fflush(NULL);
	}
	if (Tcl_Flush((Tcl_Channel) stream) != TCL_OK) {
		return EOF;
	}
	return 0;
}

int stdioctcl_fgetc(FILE *stream) {
	int count;
	static Tcl_Obj *readObjPtr = NULL;
	if (readObjPtr == NULL) {
		readObjPtr = Tcl_NewObj();
		Tcl_IncrRefCount(readObjPtr);
	}
	Tcl_Channel s = (Tcl_Channel) stream;
	//Todo: retrieve posix error code when necessary
	if ((count = Tcl_ReadChars(s ,readObjPtr ,1 ,0)) < 1) {
		if (stdioctcl_feof(stream)) {
			return EOF;
		} else {
			return EOF;
		}
	}
	/*
	char *res = Tcl_GetStringFromObj(readObjPtr ,NULL);
	*/
	int reslength;
	char *res = Tcl_GetByteArrayFromObj(readObjPtr ,&reslength);

	/* object is in a static variable; don't decrement the reference */
	/* Tcl_DecrRefCount(readObjPtr); */
	return (int)res[0];
}

char *stdioctcl_fgets(char *s ,int count ,FILE *stream) {
	/* leave the last index for the null character */
	count -= 1;
	int i;
	if (stdioctcl_feof(stream)) {
		return NULL;
	}
	for (i=0 ;i<count;i++) {
		if ((s[i] = stdioctcl_fgetc(stream)) == EOF) {
			if (!i) {
				return NULL;
			}
			break;
		} else if (s[i]  == '\n') {
			i++;
			break;
		}
	}
	s[i] = '\0';
	return s;
}

FILE * stdioctcl_fopen(const char *filename ,const char *opentype) {
	char * tclerrno;
	Tcl_Obj *pathPtr = Tcl_NewStringObj(filename, strlen(filename));
	Tcl_IncrRefCount(pathPtr);
	Tcl_Channel res = Tcl_FSOpenFileChannel(interp ,pathPtr ,opentype ,
		(S_IRUSR|S_IWUSR
		#ifdef S_IRGRP
		|S_IRGRP
		#endif
		#ifdef S_IWGRP
		|S_IWGRP
		#endif
		#ifdef S_IROTH
		|S_IROTH
		#endif
		#ifdef S_IWOTH
		|S_IWOTH
		#endif
		)&(~read_umask()));
	if (!res) {
		int errno2 = Tcl_GetErrno();
		/*
		char *msgtemplate = "stdioctcl_fopen: %s";
		char errmsg[strlen(msgtemplate) + strlen(filename)];
		sprintf(errmsg ,msgtemplate , filename);
		*/
		errno = errno2;
		/*
		perror(errmsg);
		*/
		return NULL;
	}
	Tcl_DecrRefCount(pathPtr);
	if (Tcl_SetChannelOption(interp ,res ,"-translation" ,"binary") != TCL_OK) {
		fprintf(stderr ,
			"stdioctcl_fopen: error setting %s to %s\n" ,"-translation" ,"binary");
		return NULL;
	}
	return (FILE *) res;
}

int stdioctcl_feof(FILE *stream) {
	return Tcl_Eof((Tcl_Channel) stream);
}

int stdioctcl_fprintf(FILE *stream ,const char *template ,...) {
	va_list ap;
	int status;
	va_start(ap ,template);
	status = stdioctcl_vfprintf(stream ,template ,ap);
	va_end(ap);
	return status;
}

int stdioctcl_vfprintf(FILE *stream ,const char *template ,va_list ap) {
	size_t ssize;
	va_list apcopy;
	va_copy(apcopy ,ap);
	ssize = vsnprintf(NULL ,0 ,template ,apcopy) + 1;
	char *out = ckalloc(ssize);
	if (!out) {
		libc_fprintf(libc_stderr 
			,"stdioctcl: memory allocation error in stdioctcl_vfprintf\n");
		return -1;
	}
	int status = vsnprintf(out ,ssize ,template ,ap);
	if (status < 1) {
		return 1;
	}
	status = Tcl_WriteChars((Tcl_Channel) stream ,out ,-1);
	ckfree(out);
	return status;
}

int stdioctcl_fputc(int c ,FILE *stream) {
	if (Tcl_WriteChars((Tcl_Channel) stream ,(char *) &c ,1) < 0) {
		return EOF;
	}
	return c;
}

int stdioctcl_fputs(const char *s ,FILE *stream){
	return Tcl_WriteChars((Tcl_Channel) stream ,s ,-1);
}

size_t stdioctcl_fread(void *data ,size_t size ,size_t count ,FILE *stream) {
	if ((!size) || (!count)) {
		return 0;
	}
	size_t size1 = size * count;
	int status;
	/* might read a partial object into data, but caller still knows how many
		complete objects were read
	*/
	status = Tcl_Read((Tcl_Channel) stream ,data ,size1);
	if (status < 0) {
		libc_fprintf(libc_stderr ,"stdioctcl: error in stdioctcl_fread!\n");
		return 0;
	}
	if (status) {
		status = status / size;
	}
	return status;
}

size_t stdioctcl_fwrite(
	const void *data ,size_t size ,size_t count ,FILE *stream) {

	size_t chars = size * count;
	Tcl_WriteChars((Tcl_Channel) stream ,data ,chars);
	return count;
}

int stdioctcl_putchar(int c) {
	return stdioctcl_fputc(c ,stdioctcl_stdout);
}

void stdioctcl_rewind(FILE *stream) {
	Tcl_WideInt result;
	if ((result = Tcl_Seek((Tcl_Channel) stream ,SEEK_SET ,0)) <0) {
		/* empty for now */
	}
	return;
}

/* ******** utility functions ******** */

mode_t read_umask(void) {
	mode_t mask = umask(0);
	umask(mask);
	return mask;
}
