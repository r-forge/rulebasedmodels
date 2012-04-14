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


/*************************************************************************/
/*									 */
/*  Read a raw case from file Df.					 */
/*									 */
/*  For each attribute, read the attribute value from the file.		 */
/*  If it is a discrete valued attribute, find the associated no.	 */
/*  of this attribute value (if the value is unknown this is 0).	 */
/*									 */
/*  Returns the array of attribute values.				 */
/*									 */
/*************************************************************************/


#define XError(a,b,c)	Error(a,b,c)


DataRec GetDataRecAlt(FILE *Df, Boolean Train)
/*      -------------  */
{
    Attribute	Att;
    char	Name[1000], *EndName;
    int		Dv;
    DataRec	Dummy, DVec;
    ContValue	Cv;
    Boolean	FirstValue=true;


    if ( ReadName(Df, Name, 1000, '\00') )
    {
	Dummy = AllocZero(MaxAtt+2, AttValue);
	DVec = &Dummy[1];
	ForEach(Att, 1, MaxAtt)
	{
	    if ( AttDef[Att] )
	    {
		DVec[Att] = EvaluateDef(AttDef[Att], DVec);

		if ( Continuous(Att) )
		{
		    CheckValue(DVec, Att);
		}

		if ( SomeMiss )
		{
		    SomeMiss[Att] |= Unknown(DVec, Att);
		    SomeNA[Att]   |= NotApplic(DVec, Att);
		}

		continue;
	    }

	    /*  Get the attribute value if don't already have it  */

	    if ( ! FirstValue && ! ReadName(Df, Name, 1000, '\00') )
	    {
		XError(HITEOF, AttName[Att], "");
		FreeLastCase(DVec);
		return Nil;
	    }
	    FirstValue = false;

	    if ( Exclude(Att) )
	    {
		if ( Att == LabelAtt )
		{
		    /*  Record the value as a string  */

		    SVal(DVec,Att) = StoreIVal(Name);
		}
	    }
	    else
	    if ( ! strcmp(Name, "?") )
	    {
		/*  Set marker to indicate missing value  */

		DVal(DVec, Att) = UNKNOWN;
		if ( SomeMiss ) SomeMiss[Att] = true;
	    }
	    else
	    if ( Att != ClassAtt && ! strcmp(Name, "N/A") )
	    {
		/*  Set marker to indicate not applicable  */

		DVal(DVec, Att) = NA;
		if ( SomeNA ) SomeNA[Att] = true;
	    }
	    else
	    if ( Discrete(Att) )
	    {
		/*  Discrete attribute  */

		Dv = Which(Name, AttValName[Att], 1, MaxAttVal[Att]);
		if ( ! Dv )
		{
		    if ( StatBit(Att, DISCRETE) )
		    {
			if ( Train )
			{
			    /*  Add value to list  */

			    if ( MaxAttVal[Att] >= (long) AttValName[Att][0] )
			    {
				XError(TOOMANYVALS, AttName[Att],
					 (char *) AttValName[Att][0] - 1);
				Dv = MaxAttVal[Att];
			    }
			    else
			    {
				Dv = ++MaxAttVal[Att];
				AttValName[Att][Dv]   = strdup(Name);
				AttValName[Att][Dv+1] = "<other>"; /* no free */
			    }
			}
			else
			{
			    /*  Set value to "<other>"  */

			    Dv = MaxAttVal[Att] + 1;
			}
		    }
		    else
		    {
			XError(BADATTVAL, AttName[Att], Name);
			Dv = UNKNOWN;
		    }
		}
		DVal(DVec, Att) = Dv;
	    }
	    else
	    {
		/*  Continuous value  */

		if ( TStampVal(Att) )
		{
		    CVal(DVec, Att) = Cv = TStampToMins(Name);
		    if ( Cv >= 1E9 )	/* long time in future */
		    {
			XError(BADTSTMP, AttName[Att], Name);
			DVal(DVec, Att) = UNKNOWN;
		    }
		}
		else
		if ( DateVal(Att) )
		{
		    CVal(DVec, Att) = Cv = DateToDay(Name);
		    if ( Cv < 1 )
		    {
			XError(BADDATE, AttName[Att], Name);
			DVal(DVec, Att) = UNKNOWN;
		    }
		}
		else
		if ( TimeVal(Att) )
		{
		    CVal(DVec, Att) = Cv = TimeToSecs(Name);
		    if ( Cv < 0 )
		    {
			XError(BADTIME, AttName[Att], Name);
			DVal(DVec, Att) = UNKNOWN;
		    }
		}
		else
		{
		    CVal(DVec, Att) = strtod(Name, &EndName);
		    if ( EndName == Name || *EndName != '\0' )
		    {
			XError(BADATTVAL, AttName[Att], Name);
			DVal(DVec, Att) = UNKNOWN;
		    }
		}

		CheckValue(DVec, Att);
	    }
	}

	if ( ClassAtt )
	{
	    if ( Discrete(ClassAtt) )
	    {
		Class(DVec) = XDVal(DVec, ClassAtt);
	    }
	    else
	    if ( Unknown(DVec, ClassAtt) || NotApplic(DVec, ClassAtt) )
	    {
		Class(DVec) = 0;
	    }
	    else
	    {
		/*  Find appropriate segment using class thresholds  */

		Cv = CVal(DVec, ClassAtt);

		for ( Dv = 1 ; Dv < MaxClass && Cv > ClassThresh[Dv] ; Dv++ )
		    ;

		Class(DVec) = Dv;
	    }
	}
	else
	{
	    if ( ! ReadName(Df, Name, 1000, '\00') )
	    {
		XError(HITEOF, Fn, "");
		FreeLastCase(DVec);
		return Nil;
	    }

	    Class(DVec) = Dv = Which(Name, ClassName, 1, MaxClass);
	}

	return DVec;
    }
    else
    {
	return Nil;
    }
}
