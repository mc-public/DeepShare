#ifndef WEBASSEMBLY_BUILD_UEXIT
#define WEBASSEMBLY_BUILD_UEXIT

#ifdef __cplusplus
extern "C" {
#endif

#ifndef KPSE_FILE_EXIT_CODE
#define KPSE_FILE_EXIT_CODE -100
#endif

#ifndef KPSE_MEMORY_EXIT_CODE
#define KPSE_MEMORY_EXIT_CODE -200
#endif

#ifndef KPSE_TEX_INTERNAL_EXIT_CODE
#define KPSE_TEX_INTERNAL_EXIT_CODE -300
#endif

#ifndef KPSE_TEX_NO_DVI_OUTPUT
#define KPSE_TEX_NO_DVI_OUTPUT 1000
#endif

#ifndef KPSE_TEX_NO_PDF_OUTPUT
#define KPSE_TEX_NO_PDF_OUTPUT 2000
#endif

#ifndef KPSE_TEX_SUCCESS_CODE
#define KPSE_TEX_SUCCESS_CODE 0
#endif

#ifndef IS_KPSE_TEX_HAS_NORMAL_ERROR
#define  IS_KPSE_TEX_HAS_NORMAL_ERROR(c) ((c>0)&&(c<=10))
#endif

#ifndef RETURN_IF_NULL_MALLOC_POINTER
#define RETURN_IF_NULL_MALLOC_POINTER(ptr) \
do { \
    if ((ptr) == NULL) { \
        fprintf(stderr, "Memory Allocate: Failed"); \
        return KPSE_MEMORY_EXIT_CODE; \
    } \
} while (0)
#endif

#define exit uexit
void uexit(int code);

#ifdef __cplusplus
}
#endif

#endif /* WEBASSEMBLY_BUILD_UEXIT */