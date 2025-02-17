#include <stdbool.h>
#include "tex-glyph.h"
bool
kpse_bitmap_tolerance (double dpi1,  double dpi2)
{
  unsigned tolerance = KPSE_BITMAP_TOLERANCE (dpi2);
  unsigned lower_bound = (int) (dpi2 - tolerance) < 0 ? 0 : dpi2 - tolerance;
  unsigned upper_bound = dpi2 + tolerance;
  return lower_bound <= dpi1 && dpi1 <= upper_bound;
}

char *kpse_find_glyph (const char *passed_fontname,  unsigned dpi, kpse_file_format_type format, kpse_glyph_file_type *glyph_file) {
    kpse_find_glyph_js_begin(passed_fontname, dpi, format);
    const char *name = kpse_get_glyph_name_js();
    unsigned actuall_dpi = kpse_get_glyph_dpi_js();
    glyph_file->name = name;
    glyph_file->dpi = actuall_dpi;
    kpse_find_glyph_js_end();
}