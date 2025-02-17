#include "texmfmp.h"
#include "uexit.h"

char *backup_pool = 0;
unsigned int backupptr = 0;
// void*  dlmalloc(size_t);
// void*  dlrealloc(void*, size_t);
// void   dlfree(void*);

extern void kpse_show_memory_usage(void);


void *xmalloc(size_t newsize) {

  void *ptr = malloc(newsize);
  if (!ptr) {
    fprintf(stderr, "Malloc Failed");
    uexit(KPSE_MEMORY_EXIT_CODE);
    abort();
  }
  memset(ptr, 0, newsize);
//   kpse_show_memory_usage();
  // printf("malloc %p size %ld\n", ptr, newsize);
  return ptr;
}

void *xrealloc(void *oriptr, size_t newsize) {
  void *ptr = realloc(oriptr, newsize);
//   kpse_show_memory_usage();
  if (!ptr) {
    fprintf(stderr, "Realloc Failed");
    uexit(KPSE_MEMORY_EXIT_CODE);
    abort();
  }
  // fprintf(stderr, "realloc %p size %ld\n", ptr, newsize);
  return ptr;
}

void *xcalloc(size_t num, size_t size) {
  void *ptr = calloc(num, size);
//   kpse_show_memory_usage();
  if (!ptr) {
    fprintf(stderr, "Realloc Failed");
    uexit(KPSE_MEMORY_EXIT_CODE);
    abort();
  }
  // fprintf(stderr, "realloc %p size %ld\n", ptr, newsize);
  return ptr;
}

void xfree(void *ptr) { free(ptr);  }

char *xstrdup(const char* s) {
  char *new_string = (char *)malloc(strlen(s) + 1);
  if (!new_string) {
    uexit(KPSE_MEMORY_EXIT_CODE);
    return NULL;
  }
  return strcpy(new_string, s);
}