#ifndef _RULEBASEDMODELS_H_
#define _RULEBASEDMODELS_H_

void initglobals(void);
void setglobals(int unbiased, char *composite, int neighbors, int committees,
                double sample, int seed, int rules, double extrapolation);
void setOf(void);
void closeOf(void);
void RBM_GetNames(char *names);
void RBM_GetData(char *data);
void rulebasedmodels(void);

#endif
