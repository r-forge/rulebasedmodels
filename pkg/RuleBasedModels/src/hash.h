#ifndef _HASH_H_
#define _HASH_H_

/* Core functions */
extern void *ht_new(int size);
extern void ht_destroy();
extern void *ht_next(void *ht);
extern void ht_reset(void *ht);
extern int ht_delete(void *ht, const char *key);
extern void *ht_lookup(void *ht, const char *key);
extern char *ht_key(void *ht);
extern void *ht_value(void *ht);

/* Convenience functions */
extern int ht_setvoid(void *ht, const char *key, void *value);
extern int ht_setint(void *ht, const char *key, int value);
extern int ht_setstr(void *ht, const char *key, char *value);
extern void *ht_getvoid(void *ht, const char *key, void *defval, void *errval);
extern int ht_getint(void *ht, const char *key, int defval, int errval);
extern char *ht_getstr(void *ht, const char *key, char *defval, char *errval);

#endif
