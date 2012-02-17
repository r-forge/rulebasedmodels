#include <setjmp.h>
#include <tcl.h>
#include <cfive.h>

char *MODE_STDIN = "stdin";
char *MODE_STDOUT = "stdout";
char *MODE_STDERR = "stderr";

jmp_buf cfive_jmp_fail;

static int tclcfive_cfive(ClientData clientdata ,Tcl_Interp *interp ,int objc 
	,Tcl_Obj *const objv[]) {

	/* pick up any changes made to tcl stdio channels */
	int i;
	int status;
	char *c5args[objc];
	for (i=0 ;i<objc ;i++) {
		c5args[i] = Tcl_GetStringFromObj(objv[i] ,NULL);
	}
	if (status = setjmp(cfive_jmp_fail)) {
	} else {
		status = c50_main(objc, c5args);
	}
	Tcl_SetObjResult(interp ,Tcl_NewIntObj(status));
	if (status) {
		return TCL_ERROR;
	} else {
		return TCL_OK;
	}
}

/*
caveat: when setting a new stdout, references to the previous channel persist
the workaround here is to use stdioctcl_set_stdout instead.

https://sourceforge.net/tracker/index.php?func=detail&aid=3307281&group_id=10894&atid=110894

*/
static int cfive_stdio(ClientData clientdata ,Tcl_Interp *interp ,int objc
	,Tcl_Obj *const objv[]) {
	char *mode = Tcl_GetStringFromObj(objv[1] ,NULL);
	Tcl_Channel chan;
	Tcl_Obj *result;
	chan = Tcl_GetChannel(interp ,Tcl_GetStringFromObj(
		objv[2] ,NULL) ,NULL);
	if (!strcmp(mode ,MODE_STDOUT)) {
		stdioctcl_set_stdout(chan);
	} else if (!strcmp(mode ,MODE_STDERR)) {
		stdioctcl_set_stderr(chan);
	} else {
		result = Tcl_NewStringObj("bad stdio mode: " ,-1);
		Tcl_AppendToObj(result ,mode ,-1);
		Tcl_SetObjResult(interp , result);
		return TCL_ERROR;
	}
	return TCL_OK; 
}

int Cfive_Init(Tcl_Interp *interp) {
	if (NULL == Tcl_InitStubs(interp ,TCL_VERSION ,0)) {
		return TCL_ERROR;
	}
	stdioctcl_io_libc_init();
	stdioctcl_interp_set(interp);
	stdioctcl_io_tcl_init();
	Tcl_CreateObjCommand(interp ,"cfive" ,tclcfive_cfive ,NULL ,NULL);
	Tcl_CreateObjCommand(interp ,"cfive_stdio" ,cfive_stdio ,NULL ,NULL);
	return TCL_OK;
}

