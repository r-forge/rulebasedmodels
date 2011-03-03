#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

/* XXX Fake version for testing */
void cubist(char **namesv,
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
    Rprintf("Hello, world\n");

    // Get namesString out of the char **
    char *namesString = namesv[0];

    // Copy namesString into allocated memory.
    // This memory will be deallocated by ".C" when it returns.
    char *model = R_alloc(strlen(namesString) + 1, 1);
    strcpy(model, namesString);

    // I think the previous value of modelv[0] will be garbage collected
    modelv[0] = model;
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
