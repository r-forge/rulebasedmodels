#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#include "rulebasedmodels.h"
#include "strbuf.h"
#include "redefine.h"

extern void c50main();
extern void samplemain(double *outputv);

static void c50(char **namesv,
                char **datav,
                char **costv,
                int *subset,
                int *rules,
                int *bands,
                int *trials,
                int *winnow,
                double *sample,
                int *seed,
                int *noGlobalPruning,
                double *CF,
                int *minCases,
                int *fuzzyThreshold,
                char **treev,
                char **rulesv,
                char **outputv)
{
    int val;  /* Used by setjmp/longjmp for implementing rbm_exit */

    // Announce ourselves for testing
    Rprintf("c50 called\n");

    // Initialize the globals to the values that the c50
    // program would have at the start of execution
    initglobals();

    // Set globals based on the arguments.  This is analogous
    // to parsing the command line in the c50 program.
    setglobals(*subset, *rules, *bands, *trials, *winnow, *sample,
               *seed, *noGlobalPruning, *CF, *minCases, *fuzzyThreshold);

    // Handles the strbufv data structure
    rbm_removeall();

    // XXX Should this be controlled via an option?
    Rprintf("Calling setOf\n");
    setOf();

    // Create a strbuf using *namesv as the buffer.
    // Note that this is a readonly strbuf since we can't
    // extend *namesv.
    STRBUF *sb_names = strbuf_create_full(*namesv, strlen(*namesv));

    // Register this strbuf using the name "undefined.names"
    rbm_register(sb_names, "undefined.names", 1);

    // Create a strbuf using *datav and register it as "undefined.data"
    STRBUF *sb_datav = strbuf_create_full(*datav, strlen(*datav));
    // XXX why is sb_datav copied? was that part of my debugging?
    // XXX or is this the cause of the leak?
    rbm_register(strbuf_copy(sb_datav), "undefined.data", 1);

    // Create a strbuf using *costv and register it as "undefined.cost"
    STRBUF *sb_costv = strbuf_create_full(*costv, strlen(*costv));
    // XXX should sb_costv be copied?
    rbm_register(sb_costv, "undefined.cost", 1);

    /*
     * We need to initialize rbm_buf before calling any code that
     * might call exit/rbm_exit.
     */
    if ((val = setjmp(rbm_buf)) == 0) {
        // Real work is done here
        Rprintf("Calling c50main\n");
        c50main();

        Rprintf("c50main finished\n");

        if (*rules == 0) {
            // Get the contents of the the tree file
            STRBUF *treebuf = rbm_lookup("undefined.tree");
            if (treebuf != NULL) {
                char *treeString = strbuf_getall(treebuf);
                char *treeObj = R_alloc(strlen(treeString) + 1, 1);
                strcpy(treeObj, treeString);

                // I think the previous value of *treev will be garbage collected
                *treev = treeObj;
            } else {
                // XXX Should *treev be assigned something in this case?
                // XXX Throw an error?
            }
        } else {
            // Get the contents of the the rules file
            STRBUF *rulesbuf = rbm_lookup("undefined.rules");
            if (rulesbuf != NULL) {
                char *rulesString = strbuf_getall(rulesbuf);
                char *rulesObj = R_alloc(strlen(rulesString) + 1, 1);
                strcpy(rulesObj, rulesString);

                // I think the previous value of *rulesv will be garbage collected
                *rulesv = rulesObj;
            } else {
                // XXX Should *rulesv be assigned something in this case?
                // XXX Throw an error?
            }
        }
    } else {
        Rprintf("c50 code called exit with value %d\n", val - JMP_OFFSET);
    }

    // Close file object "Of", and return its contents via argument outputv
    char *outputString = closeOf();
    char *output = R_alloc(strlen(outputString) + 1, 1);
    strcpy(output, outputString);
    *outputv = output;

    // We reinitialize the globals on exit out of general paranoia
    initglobals();
}

static void predictions(char **casev,
                        char **namesv,
                        char **datav,
                        char **modelv,
                        double *predv,
                        char **outputv)
{
    int val;  /* Used by setjmp/longjmp for implementing rbm_exit */

    // Announce ourselves for testing
    Rprintf("predictions called\n");

    // Initialize the globals
    initglobals();

    // Handles the strbufv data structure
    rbm_removeall();

    // XXX Should this be controlled via an option?
    Rprintf("Calling setOf\n");
    setOf();

    STRBUF *sb_cases = strbuf_create_full(*casev, strlen(*casev));
    rbm_register(sb_cases, "undefined.cases", 1);

    STRBUF *sb_names = strbuf_create_full(*namesv, strlen(*namesv));
    rbm_register(sb_names, "undefined.names", 1);

    STRBUF *sb_datav = strbuf_create_full(*datav, strlen(*datav));
    /* XXX why is sb_datav copied? */
    rbm_register(strbuf_copy(sb_datav), "undefined.data", 1);

    STRBUF *sb_modelv = strbuf_create_full(*modelv, strlen(*modelv));
    /* XXX should sb_modelv be copied? */
    rbm_register(sb_modelv, "undefined.model", 1);

    /*
     * We need to initialize rbm_buf before calling any code that
     * might call exit/rbm_exit.
     */
    if ((val = setjmp(rbm_buf)) == 0) {
        // Real work is done here
        Rprintf("Calling samplemain\n");
        samplemain(predv);

        Rprintf("samplemain finished\n");
    } else {
        Rprintf("sample code called exit with value %d\n", val - JMP_OFFSET);
    }

    // Close file object "Of", and return its contents via argument outputv
    char *outputString = closeOf();
    char *output = R_alloc(strlen(outputString) + 1, 1);
    strcpy(output, outputString);
    *outputv = output;

    // We reinitialize the globals on exit out of general paranoia
    initglobals();
}

// Declare the type of each of the arguments to the c50 function
static R_NativePrimitiveArgType c50_t[] = {
    STRSXP,   // namesv
    STRSXP,   // datav
    STRSXP,   // costv
    LGLSXP,   // subset
    LGLSXP,   // rules
    INTSXP,   // bands
    INTSXP,   // trials
    LGLSXP,   // winnow
    REALSXP,  // sample
    INTSXP,   // seed
    INTSXP,   // noGlobalPruning
    REALSXP,  // CF
    INTSXP,   // minCases
    LGLSXP,   // fuzzyThreshold
    STRSXP,   // treev
    STRSXP,   // rulesv
    STRSXP    // outputv
};

// Declare the type of each of the arguments to the c50 function
// XXX Using the cubist version of predictions still
static R_NativePrimitiveArgType predictions_t[] = {
    STRSXP,   // casev
    STRSXP,   // namesv
    STRSXP,   // datav
    STRSXP,   // modelv
    REALSXP,  // predv
    STRSXP    // outputv
};

// Declare the c50 function
static const R_CMethodDef cEntries[] = {
    {"C50", (DL_FUNC) &c50, 17, c50_t},
    // XXX Not converted yet
    {"predictions", (DL_FUNC) &predictions, 6, predictions_t},
    {NULL, NULL, 0}
};

// Initialization function for this shared object
void R_init_C50(DllInfo *dll)
{
    // Announce ourselves for testing
    Rprintf("R_init_C50 called\n");

    // Register the functions "c50" and "predictions"
    R_registerRoutines(dll, cEntries, NULL, NULL, NULL);

    // This should help prevent people from accidentally accessing
    // any of our global variables, or any functions that are not
    // intended to be called from R.  Only the functions "c50"
    // and predictions  can be accessed, since they're the only ones
    // we registered.
    R_useDynamicSymbols(dll, FALSE);
}
