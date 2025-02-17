#ifndef KPSE_MAGSTEP_HEAD
#define KPSE_MAGSTEP_HEAD

#ifdef __cplusplus
extern "C" {
#endif

int magstep (int n,  int bdpi);
#define MAGSTEP_MAX 40
#define ABSL(expr) ((expr) < 0 ? -(expr) : (expr))
unsigned
kpse_magstep_fix ( unsigned dpi,  unsigned bdpi,  int *m_ret);

#ifdef __cplusplus
}
#endif

#endif