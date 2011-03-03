#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#include "rulebasedmodels.h"

/* XXX Fake version for testing */
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
    Rprintf("Calling RBM_GetNames\n");
    RBM_GetNames(*namesv);
    Rprintf("Calling RBM_GetData\n");
    RBM_GetData(*datav);

    // Real work is done here
    Rprintf("Calling rulebasedmodels\n");
    rulebasedmodels();

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

    // We reinitialize the globals on exit out of general paranoia
    initglobals();
}

// Declare the type of each of the arguments to the cubist function
static const R_NativePrimitiveArgType cubist_t[] = {
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
