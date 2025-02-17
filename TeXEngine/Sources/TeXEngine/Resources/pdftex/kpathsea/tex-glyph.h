#ifndef KPSE_TEX_GLYPH_HEAD
#define KPSE_TEX_GLYPH_HEAD
#define KPSE_BITMAP_TOLERANCE(r) ((r) / 500.0 + 1)
#include <stdbool.h>
#include <strings.h>
#include "kpseemu.h"
bool
kpse_bitmap_tolerance (double dpi1,  double dpi2);

typedef struct
{
  const char* name;            /* font name found */
  unsigned dpi;                 /* size found, for glyphs */
} kpse_glyph_file_type;       


char *kpse_find_glyph (const char *passed_fontname,  unsigned dpi, kpse_file_format_type format, kpse_glyph_file_type *glyph_file);

/// The following function is implement in js
/// The last par is always `kpse_pk_format`(1)
extern void kpse_find_glyph_js_begin (const char *passed_fontname,  unsigned dpi, kpse_file_format_type format);

extern const char *kpse_get_glyph_name_js (void);
extern unsigned kpse_get_glyph_dpi_js (void);

extern void kpse_find_glyph_js_end (void);

#define kpse_find_pk(font_name, dpi, glyph_file) \
  kpse_find_glyph (font_name, dpi, kpse_pk_format, glyph_file)



#define FILESTRCASEEQ(s1,s2) ((s1) && (s2) && (strcasecmp (s1, s2) == 0))
#define FILESTRNCASEEQ(s1,s2,l) ((s1) && (s2) && (strncasecmp (s1,s2,l) == 0))
#define FILECHARCASEEQ(c1,c2) (toupper (c1) == toupper (c2))

#endif


