/*************************************************************************/
/*									 */
/*  Copyright 2010 Rulequest Research Pty Ltd.				 */
/*  Copyright 2011 Nathan Coulter and others				 */
/*									 */
/*  This file is part of C5.0 GPL Edition, a single-threaded version	 */
/*  of C5.0 release 2.07.						 */
/*									 */
/*  C5.0 GPL Edition is free software: you can redistribute it and/or	 */
/*  modify it under the terms of the GNU General Public License as	 */
/*  published by the Free Software Foundation, either version 3 of the	 */
/*  License, or (at your option) any later version.			 */
/*									 */
/*  C5.0 GPL Edition is distributed in the hope that it will be useful,	 */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of	 */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU	 */
/*  General Public License for more details.				 */
/*									 */
/*  You should have received a copy of the GNU General Public License	 */
/*  (gpl.txt) along with C5.0 GPL Edition.  If not, see 		 */
/*									 */
/*      <http://www.gnu.org/licenses/>.					 */
/*									 */
/*************************************************************************/

/*************************************************************************/
/*									 */
/*	Main routine, C5.0						 */
/*	------------------						 */
/*									 */
/*************************************************************************/

#include <setjmp.h>
#include <stdioctcl.h>
#ifdef USE_STDIOCTCL_REDEFINE
#include <stdioctclredef.h>
#include <tcl.h>
#endif /* USE_STDIOCTCL_REDEFINE */

jmp_buf cfive_jmp_fail;

int main(int Argc, char *Argv[]) {
	int status;
	#ifdef USE_STDIOCTCL_REDEFINE
	Tcl_Interp *tcl_interp = Tcl_CreateInterp();
	Tcl_FindExecutable(Argv[0]);
	stdioctcl_io_libc_init();
	if (tcl_interp == NULL) {
		libc_fprintf(libc_stderr ,"Could not create interpreter!\n");
		goto fail_tcl;
	}
	if (Tcl_Init(tcl_interp) != TCL_OK) {
		libc_fprintf(libc_stderr ,"Error initializing TCL");
		goto fail_tcl;
	}
	stdioctcl_interp_set(tcl_interp);
	stdioctcl_io_tcl_init();
	#endif /* USE_STDIOCTCL_REDEFINE */
	goto succeed_tcl;
	fail_tcl:
		#ifdef USE_STDIOCTCL_REDEFINE
		Tcl_Finalize();
		#endif /* USE_STDIOCTCL_REDEFINE */
		return 1;
	succeed_tcl:
		if (status = setjmp(cfive_jmp_fail)) {
		} else {
			status = c50_main(Argc ,Argv);
		}
		#ifdef USE_STDIOCTCL_REDEFINE
		Tcl_Finalize();
		#endif /* USE_STDIOCTCL_REDEFINE */
		return status; 
}
