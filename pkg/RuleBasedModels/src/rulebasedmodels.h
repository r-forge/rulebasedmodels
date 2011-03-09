#ifndef _RULEBASEDMODELS_H_
#define _RULEBASEDMODELS_H_

void initglobals(void);
void setglobals(int unbiased, char *composite, int neighbors, int committees,
                double sample, int seed, int rules, double extrapolation);
void setOf(void);
void closeOf(void);
void rulebasedmodels(void);

#endif
