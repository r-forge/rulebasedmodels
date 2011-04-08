#include "defns.i"
#include "extern.i"


/*************************************************************************/
/*									 */
/*	Main                                                             */
/*									 */
/*************************************************************************/


int samplemain(double *outputv)
/*  ----------  */
{
    RRuleSet            *CubistModel;
    double              pval;
    FILE		*F;
    CaseNo		i;

    /*  Read information on attribute names and values  */

    if ( ! (F = GetFile(".names", "r")) ) Error(0, Fn, "");
    GetNames(F);  /* GetNames closes the file */

    /*  Read the model file that defines the ruleset and sets values
	for various global variables such as USEINSTANCES  */

    CubistModel = GetCommittee(".model");

    if ( USEINSTANCES )
    {
	if ( ! (F = GetFile(".data", "r")) ) Error(0, Fn, "");
	GetData(F, true, false);  /* GetData closes the file */

	/*  Prepare the file of instances and the kd-tree index  */

	InitialiseInstances(CubistModel);

	/*  Reorder instances to improve caching  */

	CopyInstances();

        // XXX This causes seg faults - fix it
	// ForEach(i, 0, MaxCase)
	// {
	//     Free(Case[i]);
	// }
	// Free(Case);
    }

    if ( ! (F = GetFile(".cases", "r")) ) Error(0, Fn, "");

    /* Not training, but allow unknown target */
    GetData(F, false, true);  /* GetData closes the file */

    FindPredictedValues(CubistModel, 0, MaxCase);

    ForEach(i, 0, MaxCase)
    {
        outputv[i] = PredVal(Case[i]);
    }

    /*  Free allocated memory  */

    FreeCttee(CubistModel);

    if ( USEINSTANCES )
    {
        // XXX Getting doubly freed errors when USEINSTANCES is true
	// FreeInstances();
	// FreeUnlessNil(RSPredVal);
    }

    // FreeNamesData();
    // FreeUnlessNil(IgnoredVals);

    return 0;
}
