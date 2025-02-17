#include "synctexdir/synctex-common.h"
#ifndef MIN_PDFTEX_TEXMFMP
#define MIN_PDFTEX_TEXMFMP
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <assert.h>
#include <errno.h>
#include <stdarg.h>
#include <ctype.h>
#include <limits.h>
#include <stddef.h>
#include "xmemory.h"
#include <zlib.h>


//Typedef
typedef int integer;
typedef int boolean;
typedef long longinteger;
typedef const char* constcstring;
typedef char* cstring;
typedef int cinttype;
typedef signed char schar;
typedef char* string;
typedef const char* const_string;
typedef FILE* text;
typedef double real;
typedef double glueratio;
typedef long long longword;
#define false 0
#define true 1


//File
#define FOPEN_W_MODE "wb"
#define FOPEN_R_MODE "rb"
#define FOPEN_RBIN_MODE "rb"
#define FOPEN_WBIN_MODE "wb"
#define kpseinnameok	kpse_in_name_ok
#define recorderchangefilename	recorder_change_filename
#define ISDIRSEP	IS_DIR_SEP
#define IS_DIR_SEP(ch) ((ch) == '/')
#define WRITE_OUT(a, b)							\
  if ((size_t) fwrite ((char *) &OUT_BUF[a], sizeof (OUT_BUF[a]),       \
                    (size_t) ((size_t)(b) - (size_t)(a) + 1), OUT_FILE) \
      != (size_t) ((size_t) (b) - (size_t) (a) + 1))                    \
    fprintf (stderr, "fwrite failed");

#define aopenin(f,p) open_input (&(f), p, FOPEN_RBIN_MODE)
#define aopenout(f)  open_output (&(f), FOPEN_WBIN_MODE)
#define aclose close_file
#define bopenin(f)	open_input (&(f), kpse_tfm_format, FOPEN_RBIN_MODE)
#define bopenout(f)	open_output (&(f), FOPEN_WBIN_MODE)
#define bclose		aclose
#define wopenin(f)	open_input (&(f), DUMP_FORMAT, FOPEN_RBIN_MODE)
#define wopenout	bopenout
#define wclose		aclose
#define Fputs(f,s) (void) fputs (s, f)
#define	inputln(stream, flag) input_line (stream)

#include "kpseemu.h"

#define	dumpint(x)							\
  do									\
    {									\
      integer x_val = (x);						\
      generic_dump (x_val);						\
    }									\
  while (0)

#define	undumpint generic_undump
#define generic_dump(x) dumpthings (x, 1)
#define generic_undump(x) undumpthings (x, 1)
#define DUMP_FILE fmtfile
#define	dumpthings(base, len) \
  do_dump ((char *) &(base), sizeof (base), (int) (len), DUMP_FILE)
#define	undumpthings(base, len) \
  do_undump ((char *) &(base), sizeof (base), (int) (len), DUMP_FILE)
#define dumpwd   generic_dump
#define dumphh   generic_dump
#define dumpqqqq generic_dump
#define undumpwd   generic_undump
#define undumphh   generic_undump
#define	undumpqqqq generic_undump
#ifndef PRIdPTR
#define PRIdPTR "ld"
#endif
#ifndef PRIxPTR
#define PRIxPTR "lx"
#endif
#define LONGINTEGER_TYPE long
#define LONGINTEGER_PRI "l"
  
#define undumpcheckedthings(low, high, base, len)			\
  do {                                                                  \
    unsigned i;                                                         \
    undumpthings (base, len);                                           \
    for (i = 0; i < (len); i++) {                                       \
      if ((&(base))[i] < (low) || (&(base))[i] > (high)) {              \
        fprintf (stderr, "Item %u (=%" PRIdPTR ") of .fmt array at %" PRIxPTR    \
                " <%" PRIdPTR " or >%" PRIdPTR,                         \
                i, (uintptr_t) (&(base))[i], (uintptr_t) &(base),       \
                (uintptr_t) low, (uintptr_t) high);                     \
      }                                                                 \
    }									\
  } while (0)

/* Like undump_checked_things, but only check the upper value. We use
   this when the base type is unsigned, and thus all the values will be
   greater than zero by definition.  */
#define undumpuppercheckthings(high, base, len)				\
  do {                                                                  \
    unsigned i;                                                         \
    undumpthings (base, len);                                           \
    for (i = 0; i < (len); i++) {                                       \
      if ((&(base))[i] > (high)) {              			\
        fprintf (stderr, "Item %u (=%" PRIdPTR ") of .fmt array at %" PRIxPTR    \
                " >%" PRIdPTR,                                          \
                i, (uintptr_t) (&(base))[i], (uintptr_t) &(base),       \
                (uintptr_t) high);                         		\
      }                                                                 \
    }									\
  } while (0)
//Misc
#define translatefilename translate_filename
#define promptfilenamehelpmsg "(Press Enter to retry, or Control-D to exit"
#define stringcast(x) ((string) (x))
#define maxint 0x3FFFFFFF
#define ucharcast(x) ((unsigned char) (x))
#define conststringcast(x) ((const_string) (x))
#define printcstring(STR)        \
  do {                           \
    const_string ch_ptr = (STR); \
    while (*ch_ptr)              \
      printchar(*(ch_ptr++));    \
  } while (0)
#define OUT_FILE dvifile
#define OUT_BUF dvibuf
#define writedvi WRITE_OUT 
#define secondsandmicros(i,j) get_seconds_and_micros (&(i), &(j))
#define WEB2C_NORETURN
#define	Xchr(x) xchr[x]
#define incr(x) ++(x)
#define decr(x) --(x)
#define odd(x)		((x) & 1)


#define putbyte(x,f) \
 do { if (putc ((char) (x) & 255, f) == EOF) \
        fprintf (stderr, "putbyte(%ld) failed", (long) x); } while (0)
#define addressof(x) (&(x))
#define nil NULL
#define chr(x)		(x)
#define TEXMFENGINENAME "pdftex"
#define	dateandtime(i,j,k,l) get_date_and_time (&(i), &(j), &(k), &(l))
//Function Define
//File Function
extern boolean input_line (FILE *);
extern void recorder_change_filename (string new_name);
extern void recorder_record_input (const_string name);
extern void recorder_record_output (const_string name);
extern boolean dir_p (string fn);
extern boolean open_output (FILE **, const_string fopen_mode);
extern boolean open_input (FILE **, int, const_string fopen_mode);
extern boolean bibopenout (FILE **,  const_string name);
extern boolean bibopenin (FILE **, int, const_string name);
extern void close_file (FILE *);
extern void topenin (void);
extern  boolean kpse_in_name_ok (const_string fname);
extern  boolean kpse_out_name_ok (const_string fname);
extern boolean eof (FILE *);
extern void do_dump (char *, int, int, FILE *);
extern void do_undump (char *, int, int, FILE *);
extern int xfclose ( FILE * stream, const_string filename );
extern FILE * xfopen (const_string filename,  const_string mode);
extern void xfseek (FILE *fp, long offset, int wherefrom, const_string filename);
extern long xftell (FILE *f,  const_string filename);
extern long xftello (FILE *f,  const_string filename);
extern void xfseeko (FILE *f,  off_t offset,  int wherefrom,  const_string filename);

//Misc Function
extern void get_seconds_and_micros (integer *, integer *);
extern void getcreationdate(void);
extern void getfilemoddate(integer s);
extern void getfilesize(integer s);
extern void getfiledump(integer s, int offset, int length);
extern void uexit(int code);
extern int runsystem(const char *);
extern string concat3 (const_string s1,  const_string s2,  const_string s3);
extern string concat3_noexit (const_string s1,  const_string s2,  const_string s3);

extern char *makecstring(integer s);
extern char *makecfilename(integer s);

extern void kpse_init_prog (const_string prefix,  unsigned dpi,  const_string mode,
                const_string fallback);
extern void kpse_set_program_enabled (kpse_file_format_type fmt,
                                         boolean value, kpse_src_type level);
extern string kpse_find_file(const_string name, kpse_file_format_type format,  boolean must_exist);
//extern string kpse_find_pk(const_string passed_fontname,  unsigned int dpi);
extern boolean kpse_absolute_p (const_string filename, boolean relative_ok);
extern void readtcxfile (void);
extern void initstarttime(void);
extern int loadpoolstrings (integer);
extern void setupboundvariable (integer *, const_string, integer);
extern void get_date_and_time (integer *, integer *, integer *, integer *);
extern string xstrdup (const_string s);
extern const char* ptexbanner;
extern char start_time_str[];
extern string translate_filename;
extern string versionstring;
extern int tfmtemp, texinputtype, kpse_make_tex_discard_errors;
extern string fullnameoffile, output_directory;
extern boolean texmfyesno(const_string var);
extern char *generic_synctex_get_current_name (void);
extern void convertStringToHexString(const char *in, char *out, int lin);
extern string find_input_file(integer s);
#define DIR_SEP_STRING "/"
#endif
