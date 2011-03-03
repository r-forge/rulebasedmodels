#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#include "defns.i"
#include "extern.i"

/* XXX Fake */
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
    Rprintf("Hello, world\n");
    char *namesString = namesv[0];
    char *model = R_alloc(strlen(namesString) + 1, 1);
    strcpy(model, namesString);
    modelv[0] = model;
}

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

static const R_CMethodDef cEntries[] = {
    {"cubist", (DL_FUNC) &cubist, 11, cubist_t},
    {NULL, NULL, 0}
};

void R_init_RuleBasedModels(DllInfo *dll)
{
    Rprintf("R_init_RuleBasedModels called\n");
    R_registerRoutines(dll, cEntries, NULL, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}

/*
 * Reset all global variables to their initial value
 */
void initglobals(void)
/*   ---------- */
{
/*************************************************************************/
/*                                                                       */
/*              General data for Cubist                                  */
/*              -----------------------                                  */
/*                                                                       */
/*************************************************************************/


    ClassAtt = 0;
    LabelAtt = 0;
    CWtAtt = 0;

    IgnoredVals = 0;
    IValsSize = 0;
    IValsOffset = 0;

    MaxAtt;
    MaxDiscrVal = 3;
    Precision;
    MaxLabel = 0;
    LineNo = 0;
    ErrMsgs = 0;
    AttExIn = 0;
    TSBase = 0;

    MaxCase = -1;

    Case;

    SaveCase = Nil;
    Blocked = Nil;
    SaveMaxCase;

    MaxAttVal = Nil;
    Modal = Nil;

    SpecialStatus = Nil;

    AttDef = Nil;
    AttDefUses = Nil;

    AttName = Nil;
    AttValName = Nil;

    Of = 0;
    FileStem = "undefined";

    AttMean = Nil;
    AttSD = Nil;
    AttMaxVal = Nil;
    AttMinVal = Nil;
    AttPref = Nil;
    Ceiling;
    Floor;
    AvCWt;

    ErrReduction = 1;

    AttUnit = Nil;

    AttPrec = Nil;

    Instance = Nil;
    Ref;
    MaxInstance = -1;
    KDTree = Nil;

    GNNEnv;
    RSPredVal = Nil;


/*************************************************************************/
/*                                                                       */
/*        Global data for Cubist used for building model trees           */
/*        ----------------------------------------------------           */
/*                                                                       */
/*************************************************************************/


    GEnv;

    TempMT = Nil;

    SRec = Nil;

    GlobalMean;
    GlobalSD;
    GlobalErr;

    Fn;

    Mf = 0;
    Pf = 0;


/*************************************************************************/
/*                                                                       */
/*      Global data for constructing and applying rules                  */
/*      -----------------------------------------------                  */
/*                                                                       */
/*************************************************************************/


    Rule = Nil;
    NRules;
    RuleSpace;

    Cttee = Nil;


/*************************************************************************/
/*                                                                       */
/*              Global parameters for Cubist                             */
/*              ----------------------------                             */
/*                                                                       */
/*************************************************************************/


    VERBOSITY = 0;
    FOLDS = 10;
    NN = 0;
    MEMBERS = 1;

    MAXD;

    XVAL = 0;
    CHOOSEMODE = 0;
    USEINSTANCES = 0;
    UNBIASED = 0;

    SAMPLE = 0.0;
    KRInit = 0;
    LOCK = false;

    MINITEMS;
    MAXRULES = 100;

    EXTRAP = 0.1;
}

/*
 * Set global variables in preparation for creating a model
 */
void setglobals(int unbiased, int composite, int neighbors, int committees,
                double sample, int seed, int rules, double extrapolation)
{
    UNBIASED = unbiased != 0 ? true : false;

    /* What to do with composite? */

    NN = neighbors;
    MEMBERS = committees;
    SAMPLE = sample;
    KRInit = seed;
    MAXRULES = rules;
    EXTRAP = extrapolation;
}
