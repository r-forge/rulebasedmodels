#include "defns.i"
#include "extern.i"


/*************************************************************************/
/*									 */
/*	Main                                                             */
/*									 */
/*************************************************************************/


int Ymain(int Argc, char *Argv[])
/*  ----------  */
{
    RRuleSet            *CubistModel;
    double              pval;
    FILE		*F;
    int			o;
    extern String	OptArg, Option;
    CaseNo		i;

    /*  Process options  */

    while ( (o = ProcessOption(Argc, Argv, "f+")) )
    {
	switch (o)
	{
	case 'f':   FileStem = OptArg;
		    break;
	case '?':   printf("    **Unrecognised option %s\n", Option);
		    exit(1);
	}
    }

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
	ForEach(i, 0, MaxCase)
	{
	    Free(Case[i]);
	}
	Free(Case);
    }

    if ( ! (F = GetFile(".cases", "r")) ) Error(0, Fn, "");

    /* Not training, but allow unknown target */
    GetData(F, false, true);  /* GetData closes the file */

    FindPredictedValues(CubistModel, 0, MaxCase);

    printf("predicted values:\n");

    ForEach(i, 0, MaxCase)
    {
        pval = PredVal(Case[i]);
        printf("%f\n", pval);
    }

    /*  Free allocated memory  */
    
    FreeCttee(CubistModel);

    if ( USEINSTANCES )
    {
	FreeInstances();
	FreeUnlessNil(RSPredVal);
    }

    FreeNamesData();
    FreeUnlessNil(IgnoredVals);

    return 0;
}
