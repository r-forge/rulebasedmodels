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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "tcl.h"
#include "stdioctcl.h"
#include "stdioctclredef.h"

#define FN_ENTRY(item) { #item ,&item }

typedef struct iofuncs {
	fopenPtr fopen_;
	fclosePtr fclose_;
	fflushPtr fflush_;
	feofPtr feof_;
	fgetcPtr fgetc_;
	fgetsPtr fgets_;
	fprintfPtr fprintf_;
	fputcPtr fputc_;
	fputsPtr fputs_;
	freadPtr fread_;
	putcharPtr putchar_ ;
	fwritePtr fwrite_;
	getcPtr getc_;
	rewindPtr rewind_;
} iofuncs;

typedef struct {
	char *name;
	int (*func)();
} func;

int LINE_MAX = 4096;
char * TESTDATAWRITEPATH = "testdata/dataout";
char * testdatapath = "";

static void myperror(const char *template ,...) {
	int errno2 = errno;
	size_t ssize;
	int status;
	va_list ap;
	va_start(ap ,template);
		ssize = vsnprintf(NULL ,0 ,template ,ap) + 1;
	va_end(ap);
	char *msg = ckalloc(ssize);
	va_start(ap ,template);
		status = vsnprintf(msg ,ssize ,template ,ap);
	va_end(ap);
	errno = errno2;
	if (status < 1) {
		perror(NULL);
	} else {
		perror(msg);
	}
	ckfree(msg);
}

int (*lookup(char *name ,func *funcs, size_t funcslength))() {
	int i;
	for (i=0 ;i<funcslength ;i++) {
		if (!strcmp(name ,funcs[i].name)) {
			return funcs[i].func;
		}

	}
	return NULL;
}

FILE *opendata(iofuncs *io ,char *fname, char* mode) {
	FILE * fh;
	if ((fh = io->fopen_(fname ,mode)) == NULL) {
		myperror("opendata: %s, mode: %s" ,fname ,mode);
		exit(1);
	}
	return fh;
}

int readfile_fread(Tcl_DString *result ,FILE *fh ,iofuncs *iofuncs) {
	int max = 3;
	char line[max];
	int count = 0;
	int readcount = 0;
	/*
	assume there are less than a million characters in test data 
	*/

	while (count < 1000000) {
		readcount = iofuncs->fread_(line ,sizeof(unsigned char) ,max ,fh);
		if (readcount) {
			Tcl_DStringAppend(result ,line ,readcount);
			count += readcount;
		} else if (iofuncs->feof_(fh)){
			break;
		}
	}
	return 0;
}

int test_fgetc(iofuncs *iofuncs) {
	FILE *fh = opendata(iofuncs ,testdatapath ,"r");
	int i;
	for (i=0; i<10;i++) {
		printf("%c", iofuncs->fgetc_(fh));
	}
	iofuncs->fclose_(fh);
	return 0;
}

int test_fgets_basic(iofuncs *iofuncs) {
	FILE *fh = opendata(iofuncs ,testdatapath ,"r");
	char line[LINE_MAX]; 
	printf("%s", iofuncs->fgets_(line ,LINE_MAX ,fh));
	printf("%s", iofuncs->fgets_(line ,LINE_MAX ,fh));
	iofuncs->fclose_(fh);
	return 0;
}

int test_feof(iofuncs *iofuncs) {
	FILE *fh = opendata(iofuncs ,testdatapath ,"r");
	char line[LINE_MAX]; 
	while (!iofuncs->feof_(fh)) {
		iofuncs->fgets_(line ,LINE_MAX ,fh);
	}
	libc_fprintf(libc_stdout ,"%d" ,iofuncs->feof_(fh));
	iofuncs->fgets_(line ,LINE_MAX ,fh);
	libc_fprintf(libc_stdout ,"%d" ,iofuncs->feof_(fh));
	return 0;
}


int test_fflush(iofuncs *iofuncs) {
	/*
	FILE *fh = fopen() ;
	*/
}

int test_fgets_partial(iofuncs *iofuncs) {
	FILE *fh = opendata(iofuncs ,testdatapath ,"r");
	int LINE_MAX = 7;
	char line[LINE_MAX]; 
	char *result;
	int length;
	int count = 0;
	int i;
	while (1) {
		result = iofuncs->fgets_(line ,LINE_MAX ,fh);
		printf("%s", result);
		printf("XXX");
		length = strlen(result);
		if (result[length-1] == '\n') {
			count += 1;
			if (count > 1) {
				break;
			}
		}
	}
	iofuncs->fclose_(fh);
	return 0;
}

int test_fread(iofuncs *iofuncs) {
	FILE *fh = opendata(iofuncs ,testdatapath ,"r");
	int max = 27;
	char buf[max];
	iofuncs->fread_(&buf ,max-1 ,1 ,fh);
	buf[max-1] = '\0';
	libc_fprintf(libc_stdout ,"%s" ,buf);
	return 0;
}

int test_fwrite(iofuncs *iofuncs) {
	FILE *fh = opendata(iofuncs ,TESTDATAWRITEPATH ,"w");
	int res;
	res = iofuncs->fwrite_("conceited characters" ,1 ,20 ,fh);
	libc_fprintf(libc_stdout ,"%d" ,res);
	iofuncs->fclose_(fh);
	return 0;
}

int test_readfile_fgetc (iofuncs *iofuncs) {
	FILE *fh = opendata(iofuncs ,testdatapath ,"r");
	Tcl_DString res;
	Tcl_DStringInit(&res);
	int nextchar;
	int count;
	/*
	assume there are less than a million lines in the test data
	*/

	for (count = 0 ;count < 1000000 ;count++) {
		if ((nextchar = iofuncs->fgetc_(fh)) == EOF) {
			break;
		}
		Tcl_DStringAppend(&res ,(const char *)&nextchar ,1);
	}
	libc_fprintf(libc_stdout ,"%d\n" ,count);
	libc_fprintf(libc_stdout ,"%s\n" , Tcl_DStringValue(&res));
}

int test_readfile_fgets (iofuncs *iofuncs) {
	FILE *fh = opendata(iofuncs ,testdatapath ,"r");
	Tcl_DString res;
	Tcl_DStringInit(&res);
	int max = 3;
	char line[max];
	int count;
	/*
	assume there are less than a million lines in the test data
	*/

	for (count = 0 ;count < 1000000 ;count++) {
		if (iofuncs->fgets_(line ,max ,fh) == NULL) {
			break;
		}
		Tcl_DStringAppend(&res ,line ,-1);
	}
	libc_fprintf(libc_stdout ,"%d\n" ,count);
	libc_fprintf(libc_stdout ,"%s\n" , Tcl_DStringValue(&res));
}

int test_readfile_fread (iofuncs *iofuncs) {
	int count = 0;
	FILE *fh = opendata(iofuncs ,testdatapath ,"r");
	Tcl_DString res;
	Tcl_DStringInit(&res);
	count = readfile_fread(&res ,fh ,iofuncs);
	libc_fprintf(libc_stdout ,"%d\n" ,count);

	int i;
	int j = Tcl_DStringLength(&res);
	char * s1 = Tcl_DStringValue(&res);
	for (i=0 ;i<j ;i++) {
		libc_fputc(s1[i], libc_stdout);
	}
	/*
	libc_fprintf(libc_stdout ,"%s\n" , Tcl_DStringValue(&res));
	*/
	Tcl_DStringFree(&res);
	return 0;
}

int test_putchar (iofuncs *iofuncs) {
	int count;
	FILE *fh = opendata(iofuncs ,testdatapath ,"r");
	Tcl_DString res;
	Tcl_DStringInit(&res);
	count = readfile_fread(&res ,fh ,iofuncs);
	libc_fprintf(libc_stdout ,"%d\n" ,count);

	int i;
	int j = Tcl_DStringLength(&res);
	char * s1 = Tcl_DStringValue(&res);
	for (i=0 ;i<j ;i++) {
		putchar(s1[i]);
	}
	/*
	libc_fprintf(libc_stdout ,"%s\n" , Tcl_DStringValue(&res));
	*/
	Tcl_DStringFree(&res);
	return 0;
}

int main(int argc, char *argv[]) {
	Tcl_Interp *interp = Tcl_CreateInterp();
	if (
#ifdef USE_TCL_STUBS
	Tcl_InitStubs(interp ,"8.3" ,0)
#else
	Tcl_PkgRequire(interp ,"Tcl" ,"8.3" ,0)
#endif
	== NULL) {
	    return TCL_ERROR;
	}
	stdioctcl_interp_set(interp);
	stdioctcl_io_tcl_init();
	if (argc < 2) {
		printf("not enough arguments!  Need at least 1!\n");
		exit(1);
	};

	func funclist[] = {
		FN_ENTRY(test_fgetc)
		, FN_ENTRY(test_feof)
		, FN_ENTRY(test_fgets_basic)
		, FN_ENTRY(test_fgets_partial)
		, FN_ENTRY(test_fread)
		, FN_ENTRY(test_fwrite)
		, FN_ENTRY(test_putchar)
		, FN_ENTRY(test_readfile_fgetc)
		, FN_ENTRY(test_readfile_fgets)
		, FN_ENTRY(test_readfile_fread)
	};
	size_t fllength = sizeof(funclist) / sizeof(func); 
	char * arg;
	int argidx = 1;
	for (argidx = 1 ;argidx < argc ;argidx++) {
		arg = argv[argidx];
		if (!strcmp(arg ,"--")) {
			argidx++;
			break;
		} else if (arg[0] == '-') {
			if (!strcmp(arg ,"-input")) {
				testdatapath = argv[++argidx];
			} else {
				myperror("bad option: %s" ,arg);
				/* TODO: replace with Tcl_Exit; */
				exit(1);
			}
			continue;
		} else {
			break;
		}
	}
	if (!strcmp(testdatapath, "")) {
		errno = 2;
		myperror("no path to data file specified");
		exit(1);
	}
	char *mode = argv[argidx++];

	iofuncs io;
	if (!strcmp(mode ,"stdioctcl")) {
		io.fopen_   = stdioctcl_fopen;
		io.fclose_  = stdioctcl_fclose;
		io.feof_    = stdioctcl_feof;
		io.fflush_  = stdioctcl_fflush;
		io.fgetc_   = stdioctcl_fgetc;
		io.fgets_   = stdioctcl_fgets;
		io.fprintf_ = stdioctcl_fprintf;
		io.fputc_   = stdioctcl_fputc;
		io.fputs_   = stdioctcl_fputs;
		io.getc_    = stdioctcl_getc;
		io.fread_   = stdioctcl_fread;
		io.fwrite_  = stdioctcl_fwrite;
		io.putchar_  = stdioctcl_putchar;
		io.rewind_  = stdioctcl_rewind;
	} else if (!strcmp(mode ,"libc")) {
		io.fopen_   =  libc_fopen;
		io.fclose_  =  libc_fclose;
		io.feof_     = libc_feof;
		io.fflush_  =  libc_fflush;
		io.fgetc_   =  libc_fgetc;
		io.fgets_   =  libc_fgets;
		io.fprintf_ =  libc_fprintf;
		io.fputc_   =  libc_fputc;
		io.fputs_   =  libc_fputs;
		io.fread_   =  libc_fread;
		io.fwrite_  =  libc_fwrite;
		io.getc_    =  libc_getc;
		io.putchar_  = libc_putchar;
		io.rewind_  =  libc_rewind;
	} else {
		printf("bad mode: %s\n" ,mode);
		exit(1);
	}
	char* funcname = argv[argidx++];
	int (*myfunc)(iofuncs *) = lookup(funcname ,funclist ,fllength);
	if (myfunc == NULL) {
		printf("no such function!: %s\n" ,funcname);
		exit(1);
	}
	(myfunc)(&io);
	return 0;
}

