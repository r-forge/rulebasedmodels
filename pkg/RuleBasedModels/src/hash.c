#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "hash.h"

#define MAXKEY 2048

enum valuetype { VOIDTYPE, STRTYPE, INTTYPE };

typedef struct _ht_entry *ht_entryptr;

typedef struct _ht_entry {
    char key[MAXKEY];      /* Key of entry */
    void *value;           /* Value of entry */
    ht_entryptr next;      /* Pointer to next entry in linked list */
    enum valuetype type;   /* Type of value */
} ht_entry;

typedef struct _ht_table {
    ht_entryptr *entries;  /* Pointers to linked lists */
    int size;              /* Size of "entries" */
    int eindex;            /* Used for iteration */
    ht_entryptr eptr;      /* Used for iteration */
} ht_table;

/* Compute the hash value of the specified key */
unsigned int hashCode(const char *key)
{
    unsigned char *ukey = (unsigned char *) key;
    unsigned int result = 17;

    while (*ukey != '\0') {
        result = 31 * result + *ukey++;
    }

    return result;
}

/* Create a hash table of the specified size */
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
            table = NULL;  /* Make sure we return NULL */
        }
    }

    return table;
}

/* Destroy, or finalize, a hash table */
void ht_destroy(void *ht)
{
    int i;
    ht_table *table = ht;
    ht_entryptr entry, next;

    /* Deallocate all of the entries in the hash table */
    /* XXX What if the entry values were dynamically allocated? */
    for (i = 0; i < table->size; i++) {
        for (entry = table->entries[i]; entry != NULL; entry = next) {
            next = entry->next;
            entry->next = NULL;  /* in case anyone has a pointer to this */
            free(entry);
        }
        table->entries[i] = NULL;  /* more paranoia */
    }

    /* Deallocate the entries array and the table itself */
    free(table->entries);
    table->entries = NULL;  /* even more paranoia */
    table->size = -1;
    free(table);
}

/* Return the next entry from the specified hash table */
void *ht_next(void *ht)
{
    ht_table *table = ht;
    ht_entryptr entry = table->eptr;

    while (entry == NULL && table->eindex < table->size - 1) {
        entry = table->entries[++table->eindex];
    }

    if (entry != NULL) {
        table->eptr = entry->next;
    }

    return entry;
}

/* Reset, or rewind, the iteration variables of a hash table */
void ht_reset(void *ht)
{
    ht_table *table = ht;
    table->eindex = -1;
    table->eptr = NULL;
}

/* Set the value and type of an entry in a hash table */
static int ht_set(void *ht, const char *key, void *value, enum valuetype type)
{
    ht_table *table = ht;
    ht_entryptr entry;

    /* Sanity check the key name */
    if (strlen(key) >= MAXKEY) {
        return -1;
    }

    /* See if there is already an entry with this key */
    entry = ht_lookup(ht, key);

    if (entry == NULL) {
        /* Compute the index of the linked list to add this entry to */
        int i = hashCode(key) % table->size;

        /* Allocate memory for this new entry */
        entry = malloc(sizeof(ht_entry));
        if (entry == NULL) {
            return -1;
        }

        /* Write the key name to the entry */
        memset(entry->key, 0, sizeof(entry->key));
        strncpy(entry->key, key, sizeof(entry->key));

        /* Add this new entry to the head of the appropriate list */
        assert(i >= 0 && i < table->size);
        entry->next = table->entries[i];
        table->entries[i] = entry;
    }

    /* Set these whether this is a new or old entry */
    entry->value = value;
    entry->type = type;

    /* Setting an entry always resets iteration */
    ht_reset(table);

    return 0;
}

/* Delete an entry from a hash table */
int ht_delete(void *ht, const char *key)
{
    ht_table *table = ht;
    int i = hashCode(key) % table->size;
    ht_entryptr *p;

    assert(i >= 0 && i < table->size);

    /* Search for the key such that we can delete the entry */
    for (p = &(table->entries[i]); *p != NULL; p = &((*p)->next)) {
        if (strcmp((*p)->key, key) == 0) {
            ht_entryptr entry = *p;
            *p = entry->next;
            entry->next = NULL;  /* in case anyone has a pointer to this */
            free(entry);
            ht_reset(table);
            return 0;
        }
    }

    /* Reset iteration even if delete was unsuccessful */
    ht_reset(table);

    return -1;
}

/* Lookup an entry in a hash table */
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

/* Return the key of the specified entry */
char *ht_key(void *entry)
{
    return ((ht_entryptr) entry)->key;
}

/* Return the value of the specified entry */
void *ht_value(void *entry)
{
    return ((ht_entryptr) entry)->value;
}

/* Set the value of an entry to a void pointer */
int ht_setvoid(void *ht, const char *key, void *value)
{
    return ht_set(ht, key, value, VOIDTYPE);
}

/* Set the value of an entry to an integer value */
int ht_setint(void *ht, const char *key, int value)
{
    return ht_set(ht, key, (void *) value, INTTYPE);
}

/* Set the value of an entry to a string */
int ht_setstr(void *ht, const char *key, char *value)
{
    return ht_set(ht, key, (void *) value, STRTYPE);
}

/* Get the "void *" value of an entry in the hash table */
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

/* Get the "int" value of an entry in the hash table */
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

/* Get the "char *" value of an entry in the hash table */
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
