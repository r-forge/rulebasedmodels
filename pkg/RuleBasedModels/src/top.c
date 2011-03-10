#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#include "rulebasedmodels.h"
#include "strbuf.h"
#include "redefine.h"

///////////////////////////////////////////////////////////
//
// Can't include defns.i because it conflicts with R.h.
// The following subset are necessary.  I'll decide how
// to resolve this later.

extern void GetNames(FILE *Nf);
extern void GetData(FILE *Df, unsigned char Train, unsigned char AllowUnknownTarget);
extern void NotifyStage(int);
extern void Progress(float);

#define READDATA 1

///////////////////////////////////////////////////////////

// XXX Slightly working now
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
                   char **modelv)
{
    int val;  /* Used by setjmp/longjmp for implementing rbm_exit */

    // Announce ourselves for testing
    Rprintf("cubist called\n");

    // Initialize the globals
    initglobals();

    // Set globals based on the arguments
    setglobals(*unbiased, *compositev, *neighbors, *committees,
               *sample, *seed, *rules, *extrapolation);

    // XXX Should this be controlled via an option?
    Rprintf("Calling setOf\n");
    setOf();

    /*
     * We need to initialize rbm_buf before calling any code that
     * might call exit/rbm_exit.
     */
    if ((val = setjmp(rbm_buf)) == 0) {
        Rprintf("Calling GetNames\n");
        STRBUF *sb_names = strbuf_create_full(*namesv, strlen(*namesv));
        GetNames((FILE *) sb_names);

        NotifyStage(READDATA);  /* This initializes global variable Uf */
        Progress(-1.0);

        Rprintf("Calling GetData\n");
        STRBUF *sb_datav = strbuf_create_full(*datav, strlen(*datav));
        GetData((FILE *) sb_datav, 1, 0);

        // Real work is done here
        Rprintf("Calling rulebasedmodels\n");
        rulebasedmodels();

        Rprintf("rulebasedmodels finished\n");

        // Get namesString out of the char **
        char *namesString = *namesv;

        // Copy namesString into allocated memory.
        // This memory will be deallocated by ".C" when it returns.
        char *model = R_alloc(strlen(namesString) + 1, 1);
        strcpy(model, namesString);

        // I think the previous value of *modelv will be garbage collected
        *modelv = model;

        // Close file object "Of"
        closeOf();
    } else {
        Rprintf("cubist code called exit with value %d\n", val - JMP_OFFSET);
    }

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
    STRSXP    // modelv
};

// Declare the cubist function
static const R_CMethodDef cEntries[] = {
    {"cubist", (DL_FUNC) &cubist, 11, cubist_t},
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
