#ifndef _RULEBASEDMODELS_H_
#define _RULEBASEDMODELS_H_

#include <setjmp.h>

#define JMP_OFFSET 100
extern jmp_buf rbm_buf;

extern void initglobals(void);
extern void setglobals(int subset, int rules, int bands, int trials,
                      int winnow, double sample, int seed, 
                      int noGlobalPruning,
                      double CF, int minCases, int fuzzyThreshold,
                      int earlyStopping);
extern void setrules(int val);
extern void setOf(void);
extern char *closeOf(void);
int rpredictmain (int *trials ,int *outputv);
#endif
