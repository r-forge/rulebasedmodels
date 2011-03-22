#ifndef _HASH_H_
#define _HASH_H_

/* Used internally and for testing */
extern unsigned int hashCode(const char *key);

/* Constructor and destructor */
extern void *ht_new(int size);
extern void ht_destroy();

/* Hash table iteration functions */
extern void *ht_next(void *ht);
extern void ht_reset(void *ht);

/* Hash entry delete function */
extern int ht_delete(void *ht, const char *key);

/* Low level hash table accessor function */
extern void *ht_lookup(void *ht, const char *key);

/* Hash entry accessor functions */
extern char *ht_key(void *entry);
extern void *ht_value(void *entry);

/* Hash table setting functions */
extern int ht_setvoid(void *ht, const char *key, void *value);
extern int ht_setint(void *ht, const char *key, int value);
extern int ht_setstr(void *ht, const char *key, char *value);

/* Hash table accessor functions */
extern void *ht_getvoid(void *ht, const char *key, void *defval, void *errval);
extern int ht_getint(void *ht, const char *key, int defval, int errval);
extern char *ht_getstr(void *ht, const char *key, char *defval, char *errval);

#endif
