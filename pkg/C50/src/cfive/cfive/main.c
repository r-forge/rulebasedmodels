/*************************************************************************/
/*									 */
/*  Copyright 2010 Rulequest Research Pty Ltd.				 */
/*  Copyright 2011 Nathan Coulter and others				 */
/*									 */
/*  This file is part of C5.0 GPL Edition, a single-threaded version	 */
/*  of C5.0 release 2.07.						 */
/*									 */
/*  C5.0 GPL Edition is free software: you can redistribute it and/or	 */
/*  modify it under the terms of the GNU General Public License as	 */
/*  published by the Free Software Foundation, either version 3 of the	 */
/*  License, or (at your option) any later version.			 */
/*									 */
/*  C5.0 GPL Edition is distributed in the hope that it will be useful,	 */
/*  but WITHOUT ANY WARRANTY; without even the implied warranty of	 */
/*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU	 */
/*  General Public License for more details.				 */
/*									 */
/*  You should have received a copy of the GNU General Public License	 */
/*  (gpl.txt) along with C5.0 GPL Edition.  If not, see 		 */
/*									 */
/*      <http://www.gnu.org/licenses/>.					 */
/*									 */
/*************************************************************************/

#include "defns.i"
#include "extern.i"
#include <signal.h>

#include <sys/unistd.h>
#include <sys/time.h>
/* cfivecheckheader/sys/resource.h undefines HAVE_SYS_RESOURCE_H  */
#include <sys/resource.h>

#define SetFOpt(V)	V = strtod(OptArg, &EndPtr);\
			if ( ! EndPtr || *EndPtr != '\00' ) break;\
			ArgOK = true
#define SetIOpt(V)	V = strtol(OptArg, &EndPtr, 10);\
			if ( ! EndPtr || *EndPtr != '\00' ) break;\
			ArgOK = true


int c50_main(int Argc, char *Argv[])
/*  ----  */
{

	/* begin globals */

/*************************************************************************/
/*									 */
/*		Parameters etc						 */
/*									 */
/*************************************************************************/

VERBOSITY=0,	/* verbosity level (0 = none) */
		TRIALS=1,	/* number of trees to be grown */
		FOLDS=10,	/* crossvalidation folds */
		UTILITY=0;	/* rule utility bands */

SUBSET=0,	/* subset tests allowed */
		BOOST=0,	/* boosting invoked */
		PROBTHRESH=0,	/* to use soft thresholds */
		RULES=0,	/* rule-based classifiers */
		XVAL=0,		/* perform crossvalidation */
		NOCOSTS=0,	/* ignoring costs */
		WINNOW=0,	/* attribute winnowing */
		GLOBAL=1;	/* use global pruning for trees */

MINITEMS=2,	/* minimum cases each side of a cut */
		LEAFRATIO=0;	/* leaves per case for boosting */

CF=0.25,	/* confidence limit for tree pruning */
		SAMPLE=0.0;	/* sample training proportion */

LOCK=false;	/* sample locked */


/*************************************************************************/
/*									 */
/*		Attributes and data					 */
/*									 */
/*************************************************************************/

ClassAtt=0,	/* attribute to use as class */
		LabelAtt=0,	/* attribute to use as case ID */
		CWtAtt=0;	/* attribute to use for case weight */

AvCWt;		/* average case weight */

ClassName=0,	/* class names */
		AttName=0,	/* att names */
		AttValName=0;	/* att value names */

IgnoredVals=0;	/* values of labels and atts marked ignore */
IValsSize=0,	/* size of above */
		IValsOffset=0;	/* index of first free char */

MaxAtt,		/* max att number */
		MaxClass,	/* max class number */
		MaxDiscrVal=3,	/* max discrete values for any att */
		MaxLabel=0,	/* max characters in case label */
		LineNo=0,	/* input line number */
		ErrMsgs=0,	/* errors found */
		AttExIn=0,	/* attribute exclusions/inclusions */
		TSBase=0;	/* base day for time stamps */

MaxAttVal=0;	/* number of values for each att */

SpecialStatus=0;/* special att treatment */

AttDef=0;	/* definitions of implicit atts */
AttDefUses=0;	/* list of attributes used by definition */

SomeMiss=Nil,	/* att has missing values */
		SomeNA=Nil,	/* att has N/A values */
		Winnowed=0;	/* atts have been winnowed */

ClassThresh=0;	/* thresholded class attribute */

MaxCase=-1;	/* max data case number */

Case=0;	/* data cases */

SaveCase=0;

FileStem="undefined";

/*************************************************************************/
/*									 */
/*		Trees							 */
/*									 */
/*************************************************************************/

Raw=0,		/* unpruned trees */
		Pruned=0,	/* pruned trees */
		WTree=0;	/* winnow tree */

Confidence,	/* set by classify() */
		SampleFrac=1,	/* fraction used when sampling */
		Vote=0,	/* total votes for classes */
		BVoteBlock=0,	/* boost voting block */
		MCost=0,	/* misclass cost [pred][real] */
		NCost=0,	/* normalised MCost used for rules */
		WeightMul=0;	/* prior adjustment factor */

MostSpec=0;	/* most specific rule for each class */

UnitWeights=1,	/* all weights are 1.0 */
		CostWeights=0;	/* reweight cases for costs */

Trial,		/* trial number for boosting */
		MaxTree=0;	/* max tree grown */

TrialPred=0;	/* predictions for each boost trial */

ClassFreq=0,	/* ClassFreq[c] = # cases of class c */
		DFreq=0;	/* DFreq[a][c*x] = Freq[][] for attribute a */

Gain=0,	/* Gain[a] = info gain by split on att a */
		Info=0,	/* Info[a] = max info from split on att a */
		EstMaxGR=0,	/* EstMaxGR[a] = est max GR from folit on a */
		ClassSum=0;	/* class weights during classification */

Bar=0;		/* Bar[a]  = best threshold for contin att a */

GlobalBaseInfo,	/* base information before split */
		Bell=0;	/* table of Bell numbers for subsets */

Tested=0;	/* Tested[a] = att a already tested */

Subset=0;	/* Subset[a][s] = subset s for att a */
Subsets=0;	/* Subsets[a] = no. subsets for att a */

GEnv;		/* environment block */

/*************************************************************************/
/*									 */
/*		Rules							 */
/*									 */
/*************************************************************************/

Rule=0;	/* current rules */

NRules,		/* number of rules */
		RuleSpace;	/* space currently allocated for rules */

RuleSet=0;	/* rulesets */

Default;	/* default class associated with ruleset or
				   boosted classifier */

Fires=Nil,	/* Fires[r][*] = cases covered by rule r */
		CBuffer=Nil;	/* buffer for compressing lists */

CovBy=Nil,	/* entry numbers for Fires inverse */
		List=Nil;	/* temporary list of cases or rules */

AttTestBits,	/* average bits to encode tested attribute */
		BranchBits=0;	/* ditto attribute value */
AttValues=0,	/* number of attribute values in the data */
		PossibleCuts=0;/* number of thresholds for an attribute */

LogCaseNo=0,	/* LogCaseNo[i] = log2(i) */
		LogFact=0;	/* LogFact[i] = log2(i!) */

UtilErr=0,	/* error by utility band */
		UtilBand=0;	/* last rule in each band */
UtilCost=0;	/* cost ditto */


/*************************************************************************/
/*									 */
/*		Misc							 */
/*									 */
/*************************************************************************/

KRInit=0,	/* KRandom initializer for SAMPLE */
		Now=0;		/* current stage */

TRf=0;		/* file pointer for tree and rule i/o */
Fn[FN_SIZE]=0;	/* file name */

Of=0;		/* output file */

	/* end globals */

    /* reset function-static variables */
	GlobalReset = 1;
    ProcessOption(0 ,0 ,"");
	CheckFile("" ,0);
	Progress(0);
	CrossVal();
	GlobalReset = 0;
	 /* end reset function-static variables */

    int			o;
    extern String	OptArg, Option;
    char		*EndPtr;
    Boolean		FirstTime=true, ArgOK;
    double		StartTime;
    FILE		*F;
    CaseNo		SaveMaxCase;
    Attribute		Att;

#ifdef HAVE_SYS_RESOURCE_H
    struct rlimit RL;

    /*  Make sure there is a largish runtime stack  */

    getrlimit(RLIMIT_STACK, &RL);

    RL.rlim_cur = Max(RL.rlim_cur, 20 * 1024 * 1024);

    if ( RL.rlim_max > 0 )	/* -1 if unlimited */
    {
	RL.rlim_cur = Min(RL.rlim_max, RL.rlim_cur);
    }

    setrlimit(RLIMIT_STACK, &RL);
#endif /* HAVE_SYS_RESOURCE_H*/

    /*  Check for output to be saved to a file  */

    if ( Argc > 2 && ! strcmp(Argv[Argc-2], "-o") )
    {
	Of = fopen(Argv[Argc-1], "w");
	Argc -= 2;
    }

    if ( ! Of )
    {
	Of = stdout;
    }

    KRInit = time(0) & 07777;

    PrintHeader("");

    /*  Process options  */

    while ( (o = ProcessOption(Argc, Argv, "f+bpv+t+sm+c+S+I+ru+egX+wh")) )
    {
	if ( FirstTime )
	{
	    fprintf(Of, T_OptHeader);
	    FirstTime = false;
	}

	ArgOK = false;

	switch (o)
	{
	case 'f':   FileStem = OptArg;
		    fprintf(Of, T_OptApplication, FileStem);
		    ArgOK = true;
		    break;
	case 'b':   BOOST = true;
		    fprintf(Of, T_OptBoost);
		    if ( TRIALS == 1 ) TRIALS = 10;
		    ArgOK = true;
		    break;
	case 'p':   PROBTHRESH = true;
		    fprintf(Of, T_OptProbThresh);
		    ArgOK = true;
		    break;
#ifdef VerbOpt
	case 'v':   SetIOpt(VERBOSITY);
		    fprintf(Of, "\tVerbosity level %d\n", VERBOSITY);
		    ArgOK = true;
		    break;
#endif
	case 't':   SetIOpt(TRIALS);
		    fprintf(Of, T_OptTrials, TRIALS);
		    Check(TRIALS, 3, 1000);
		    BOOST = true;
		    break;
	case 's':   SUBSET = true;
		    fprintf(Of, T_OptSubsets);
		    ArgOK = true;
		    break;
	case 'm':   SetFOpt(MINITEMS);
		    fprintf(Of, T_OptMinCases, MINITEMS);
		    Check(MINITEMS, 1, 1000000);
		    break;
	case 'c':   SetFOpt(CF);
		    fprintf(Of, T_OptCF, CF);
		    Check(CF, 0, 100);
		    CF /= 100;
		    break;
	case 'r':   RULES = true;
		    fprintf(Of, T_OptRules);
		    ArgOK = true;
		    break;
	case 'S':   SetFOpt(SAMPLE);
		    fprintf(Of, T_OptSampling, SAMPLE);
		    Check(SAMPLE, 0.1, 99.9);
		    SAMPLE /= 100;
		    break;
	case 'I':   SetIOpt(KRInit);
		    fprintf(Of, T_OptSeed, KRInit);
		    KRInit = KRInit & 07777;
		    break;
	case 'u':   SetIOpt(UTILITY);
		    fprintf(Of, T_OptUtility, UTILITY);
		    Check(UTILITY, 2, 10000);
		    RULES = true;
		    break;
	case 'e':   NOCOSTS = true;
		    fprintf(Of, T_OptNoCosts);
		    ArgOK = true;
		    break;
	case 'w':   WINNOW = true;
		    fprintf(Of, T_OptWinnow);
		    ArgOK = true;
		    break;
	case 'g':   GLOBAL = false;
		    fprintf(Of, T_OptNoGlobal);
		    ArgOK = true;
		    break;
	case 'X':   SetIOpt(FOLDS);
		    fprintf(Of, T_OptXval, FOLDS);
		    Check(FOLDS, 2, 1000);
		    XVAL = true;
		    break;
	}

	if ( ! ArgOK )
	{
	    if ( o != 'h' )
	    {
		fprintf(Of, T_UnregnizedOpt,
			    Option,
			    ( ! OptArg || OptArg == Option+2 ? "" : OptArg ));
		fprintf(Of, T_SummaryOpts);
	    }
	    fprintf(Of, T_ListOpts);
	    Goodbye(1);
	}
    }

    if ( UTILITY && BOOST )
    {
	fprintf(Of, T_UBWarn);
    }

    StartTime = ExecTime();

    /*  Get information on training data  */

    if ( ! (F = GetFile(".names", "r")) ) Error(NOFILE, "", "");
    GetNames(F);

    if ( ClassAtt )
    {
	fprintf(Of, T_ClassVar, AttName[ClassAtt]);
    }

    NotifyStage(READDATA);
    Progress(-1.0);

    /*  Allocate space for SomeMiss[] and SomeNA[] */

    SomeMiss = AllocZero(MaxAtt+1, Boolean);
    SomeNA   = AllocZero(MaxAtt+1, Boolean);

    /*  Read data file  */

    if ( ! (F = GetFile(".data", "r")) ) Error(NOFILE, "", "");
    GetData(F, true, false);
    fprintf(Of, TX_ReadData(MaxCase+1, MaxAtt, FileStem));

    if ( XVAL && (F = GetFile(".test", "r")) )
    {
	SaveMaxCase = MaxCase;
	GetData(F, false, false);
	fprintf(Of, TX_ReadTest(MaxCase-SaveMaxCase, FileStem));
    }

    /*  Check whether case weight attribute appears  */

    if ( CWtAtt )
    {
	fprintf(Of, T_CWtAtt);
    }

    if ( ! NOCOSTS && (F = GetFile(".costs", "r")) )
    {
	GetMCosts(F);
	if ( MCost )
	{
	    fprintf(Of, T_ReadCosts, FileStem);
	}
    }

    /*  Note any attribute exclusions/inclusions  */

    if ( AttExIn )
    {
	fprintf(Of, "%s", ( AttExIn == -1 ? T_AttributesOut : T_AttributesIn ));

	ForEach(Att, 1, MaxAtt)
	{
	    if ( Att != ClassAtt &&
		 Att != CWtAtt &&
		 ( StatBit(Att, SKIP) > 0 ) == ( AttExIn == -1 ) )
	    {
		fprintf(Of, "    %s\n", AttName[Att]);
	    }
	}
    }

    /*  Build decision trees  */

    if ( ! BOOST )
    {
	TRIALS = 1;
    }

    InitialiseTreeData();
    if ( RULES )
    {
	RuleSet = AllocZero(TRIALS+1, CRuleSet);
    }

    if ( WINNOW )
    {
	NotifyStage(WINNOWATTS);
	Progress(-MaxAtt);
	WinnowAtts();
    }

    if ( XVAL )
    {
	CrossVal();
    }
    else
    {
	ConstructClassifiers();

	/*  Evaluation  */

	fprintf(Of, T_EvalTrain, MaxCase+1);

	NotifyStage(EVALTRAIN);
	Progress(-TRIALS * (MaxCase+1.0));

	Evaluate(CMINFO | USAGEINFO);

	if ( (F = GetFile(( SAMPLE ? ".data" : ".test" ), "r")) )
	{
	    NotifyStage(READTEST);
	    fprintf(Of, "\n");

	    FreeData();
	    GetData(F, false, false);

	    fprintf(Of, T_EvalTest, MaxCase+1);

	    NotifyStage(EVALTEST);
	    Progress(-TRIALS * (MaxCase+1.0));

	    Evaluate(CMINFO);
	}
    }

    fprintf(Of, T_Time, ExecTime() - StartTime);

#ifdef VerbOpt
    Cleanup();
#endif

    return 0;
}

