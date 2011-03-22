#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "hash.h"

#define MAXKEY 2048

enum valuetype { VOIDTYPE, STRTYPE, INTTYPE, DOUBLETYPE, FLOATTYPE };

typedef struct _ht_entry *ht_entryptr;
typedef struct _ht_entry {
    char key[MAXKEY];
    void *value;
    ht_entryptr next;
    enum valuetype type;
} ht_entry;

typedef struct _ht_table {
    ht_entryptr *entries;
    int size;
    int eindex;        /* Used for iteration */
    ht_entryptr eptr;  /* Used for iteration */
} ht_table;

unsigned int hashCode(const char *key)
{
    unsigned char *ukey = (unsigned char *) key;
    unsigned int result = 17;

    while (*ukey != '\0') {
        result = 31 * result + *ukey++;
    }

    return result;
}

void *ht_new(int size)
{
    ht_table *table;

    if (size <= 0) {
        return NULL;
    }

    table = malloc(sizeof(ht_table));

    if (table != NULL) {
        ht_entryptr *entries = malloc(sizeof(ht_entryptr) * size);

        if (entries != NULL) {
            /* Initialize entries to NULL */
            int i;

            for (i = 0; i < size; i++) {
                entries[i] = NULL;
            }

            /* Initialize table */
            table->entries = entries;
            table->size = size;
            table->eindex = -1;
            table->eptr = NULL;
        } else {
            /* Don't leak memory if the second malloc fails */
            free(table);
            table = NULL;
        }
    }

    return table;
}

/* This is used to iterate through all of the hash entries */
void *ht_next(void *ht)
{
    ht_table *table = ht;
    ht_entryptr e = table->eptr;

    while (e == NULL && table->eindex < (int) table->size - 1) {
        e = table->entries[++table->eindex];
    }

    if (e != NULL) {
        table->eptr = e->next;
    }

    return e;
}

/* This allows you to reset, or rewind, the iteration */
void ht_reset(void *ht)
{
    ht_table *table = ht;
    table->eindex = -1;
    table->eptr = NULL;
}

void ht_destroy(void *ht)
{
    int i;
    ht_table *table = ht;
    ht_entryptr e, n;

    /* XXX What if the entry values were dynamically allocated? */
    for (i = 0; i < table->size; i++) {
        for (e = table->entries[i]; e != NULL; e = n) {
            n = e->next;
            free(e);
        }
    }

    free(table->entries);
    table->entries = NULL;
    table->size = -1;
    free(table);
}

static int ht_set(void *ht, const char *key, void *value, enum valuetype type)
{
    ht_entryptr entry;

    if (strlen(key) >= MAXKEY) {
        return -1;
    }

    entry = ht_lookup(ht, key);

    if (entry == NULL) {
        ht_table *table = ht;
        int i = hashCode(key) % table->size;
        entry = malloc(sizeof(ht_entry));

        if (entry == NULL) {
            return -1;
        }

        memset(entry->key, 0, sizeof(entry->key));
        strncpy(entry->key, key, sizeof(entry->key));
        assert(i >= 0 && i < table->size);
        entry->next = table->entries[i];
        table->entries[i] = entry;
    }

    entry->value = value;
    entry->type = type;

    return 0;
}

int ht_delete(void *ht, const char *key)
{
    ht_table *table = ht;
    int i = hashCode(key) % table->size;
    ht_entryptr *p;

    assert(i >= 0 && i < table->size);

    for (p = &(table->entries[i]); *p != NULL; p = &((*p)->next)) {
        if (strcmp((*p)->key, key) == 0) {
            ht_entryptr entry = *p;
            *p = entry->next;
            free(entry);
            return 0;
        }
    }

    return -1;
}

void *ht_lookup(void *ht, const char *key)
{
    ht_table *table = ht;
    int i = hashCode(key) % table->size;
    ht_entryptr entry;

    assert(i >= 0 && i < table->size);

    for (entry = table->entries[i]; entry != NULL; entry = entry->next) {
        if (strcmp(entry->key, key) == 0) {
            return entry;
        }
    }

    return NULL;
}

char *ht_key(void *entry)
{
    return ((ht_entryptr) entry)->key;
}

void *ht_value(void *entry)
{
    return ((ht_entryptr) entry)->value;
}

int ht_setvoid(void *ht, const char *key, void *value)
{
    return ht_set(ht, key, value, VOIDTYPE);
}

int ht_setint(void *ht, const char *key, int value)
{
    return ht_set(ht, key, (void *) value, INTTYPE);
}

int ht_setstr(void *ht, const char *key, char *value)
{
    return ht_set(ht, key, (void *) value, STRTYPE);
}

void *ht_getvoid(void *ht, const char *key, void *defval, void *errval)
{
    ht_entryptr entry = ht_lookup(ht, key);
    if (entry == NULL) {
        return defval;
    }

    if (entry->type != VOIDTYPE) {
        return errval;
    }

    return entry->value;
}

int ht_getint(void *ht, const char *key, int defval, int errval)
{
    ht_entryptr entry = ht_lookup(ht, key);
    if (entry == NULL) {
        return defval;
    }

    if (entry->type != INTTYPE) {
        return errval;
    }

    return (int) entry->value;
}

char *ht_getstr(void *ht, const char *key, char *defval, char *errval)
{
    ht_entryptr entry = ht_lookup(ht, key);
    if (entry == NULL) {
        return defval;
    }

    if (entry->type != STRTYPE) {
        return errval;
    }

    return (char *) entry->value;
}
