#include "defns.i"
#include "extern.i"
#include "rulebasedmodels.h"

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
void setglobals(int unbiased, char *composite, int neighbors, int committees,
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

void setOf()
{
    // XXX This should use a different name everytime it's called
    Of = fopen("rulebasedmodels.tmp", "w");
}

void closeOf()
{
    if (Of)
        fclose(Of);
}

void RBM_GetNames(char *names)
{
    // XXX TODO
}

void RBM_GetData(char *data)
{
    // XXX TODO
}

void rulebasedmodels()
{
    // XXX Should check value of CWtAtt
    AvCWt = 1;

    // Build and evaluate cubist model
    Rprintf("Calling InitialiseEnvData\n");
    InitialiseEnvData();

    // XXX We don't support XVAL yet
    Rprintf("Skipping call to SingleCttee\n");
    // SingleCttee();

    Rprintf("rulebasedmodels finished\n");
}
