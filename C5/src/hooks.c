#include "defns.h"
#include "extern.h"

extern char *PropVal;
extern RuleNo *Active;

/*************************************************************************/
/*									 */
/*	Deallocate the space used to perform classification		 */
/*									 */
/*************************************************************************/


void FreeGlobals()
/*   -----------  */
{
    /*  Free memory allocated for classifier  */

    if ( RULES )
    {
	ForEach(Trial, 0, TRIALS-1)
	{
	     FreeRules(RuleSet[Trial]);
	}
	free(RuleSet);

	FreeUnlessNil(Active);
	FreeUnlessNil(RulesUsed);
	FreeUnlessNil(MostSpec);
    }
    else
    {
	ForEach(Trial, 0, TRIALS-1)
	{
	     FreeTree(Pruned[Trial]);
	}
	free(Pruned);
    }

    FreeUnlessNil(PropVal);

    /*  Free memory allocated for cost matrix  */

    if ( MCost )
    {
        FreeVector((void **) MCost, 1, MaxClass);
    }

    /*  Free memory for names etc  */

    FreeNames();
    FreeUnlessNil(IgnoredVals);

    free(ClassSum);
    free(Vote);
}
