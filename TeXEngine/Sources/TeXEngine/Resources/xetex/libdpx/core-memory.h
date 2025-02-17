/* tectonic/core-memory.h: basic dynamic memory helpers
   Copyright 2016-2018 the Tectonic Project
   Licensed under the MIT License.
*/

#ifndef TECTONIC_CORE_MEMORY_H
#define TECTONIC_CORE_MEMORY_H

#include "core-foundation.h"

BEGIN_EXTERN_C

char *dpx_strdup (const char *s);
void *dpx_malloc (size_t size);
void *dpx_realloc (void *old_address, size_t new_size);
void *dpx_calloc (size_t nelem, size_t elsize);

static inline void *mfree(void *ptr) {
    free(ptr);
    return NULL;
}

END_EXTERN_C

#endif /* not TECTONIC_CORE_MEMORY_H */
