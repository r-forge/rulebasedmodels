#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#include "rulebasedmodels.h"
#include "strbuf.h"
#include "redefine.h"

extern void cubistmain();

static void cubist(char **namesv,
                   char **datav,
                   int *unbiased,
                   char **compositev,
                   int *neighbors,
                   int *committees,
                   double *sample,
                   int *seed,
                   int *rules,
                   double *extrapolation,
                   char **modelv,
                   char **outputv)
{
    int val;  /* Used by setjmp/longjmp for implementing rbm_exit */

    // Announce ourselves for testing
    Rprintf("cubist called\n");

    // Initialize the globals
    initglobals();

    // Set globals based on the arguments
    setglobals(*unbiased, *compositev, *neighbors, *committees,
               *sample, *seed, *rules, *extrapolation);

    // Handles the strbufv data structure
    rbm_removeall();

    // XXX Should this be controlled via an option?
    Rprintf("Calling setOf\n");
    setOf();

    STRBUF *sb_names = strbuf_create_full(*namesv, strlen(*namesv));
    rbm_register(sb_names, "undefined.names", 1);

    STRBUF *sb_datav = strbuf_create_full(*datav, strlen(*datav));
    rbm_register(strbuf_copy(sb_datav), "undefined.data", 1);

    /*
     * We need to initialize rbm_buf before calling any code that
     * might call exit/rbm_exit.
     */
    if ((val = setjmp(rbm_buf)) == 0) {
        // Real work is done here
        Rprintf("Calling cubistmain\n");
        cubistmain();

        Rprintf("cubistmain finished\n");

        // Get the contents of the the model file
        char *modelString = strbuf_getall(rbm_lookup("undefined.model"));
        char *model = R_alloc(strlen(modelString) + 1, 1);
        strcpy(model, modelString);

        // I think the previous value of *modelv will be garbage collected
        *modelv = model;
    } else {
        Rprintf("cubist code called exit with value %d\n", val - JMP_OFFSET);
    }

    // Close file object "Of", and return its contents via argument outputv
    char *outputString = closeOf();
    char *output = R_alloc(strlen(outputString) + 1, 1);
    strcpy(output, outputString);
    *outputv = output;

    // We reinitialize the globals on exit out of general paranoia
    initglobals();
}

// Declare the type of each of the arguments to the cubist function
static R_NativePrimitiveArgType cubist_t[] = {
    STRSXP,   // namesv
    STRSXP,   // datav
    LGLSXP,   // unbiased
    STRSXP,   // compositev
    INTSXP,   // neighbors
    INTSXP,   // committees
    REALSXP,  // sample
    INTSXP,   // seed
    INTSXP,   // rules
    REALSXP,  // extrapolation
    STRSXP,   // modelv
    STRSXP    // outputv
};

// Declare the cubist function
static const R_CMethodDef cEntries[] = {
    {"cubist", (DL_FUNC) &cubist, 12, cubist_t},
    {NULL, NULL, 0}
};

// Initialization function for this shared object
void R_init_RuleBasedModels(DllInfo *dll)
{
    // Announce ourselves for testing
    Rprintf("R_init_RuleBasedModels called\n");

    // Register the function "cubist"
    R_registerRoutines(dll, cEntries, NULL, NULL, NULL);

    // This should help prevent people from accidentally accessing
    // any of our global variables, or any functions that are not
    // intended to be called from R.  Only the function "cubist"
    // can be accessed, since that's the only one we registered.
    R_useDynamicSymbols(dll, FALSE);
}