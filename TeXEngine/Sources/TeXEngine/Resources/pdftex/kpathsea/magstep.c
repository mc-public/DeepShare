#include "magstep.h"
#include <stdio.h>
#include <math.h>

int magstep (int n,  int bdpi)
{
   double t;
   int step;
   int neg = 0;

   if (n < 0)
     {
       neg = 1;
       n = -n;
     }

   if (n & 1)
     {
       n &= ~1;
       t = 1.095445115;
     }
    else
      t = 1.0;

   while (n > 8)
     {
       n -= 8;
       t = t * 2.0736;
     }

   while (n > 0)
     {
       n -= 2;
       t = t * 1.2;
     }

   /* Unnecessary casts to shut up stupid compilers. */
   step = (int)(0.5 + (neg ? bdpi / t : bdpi * t));
   return step;
}


unsigned
kpse_magstep_fix ( unsigned dpi,  unsigned bdpi,  int *m_ret)
{
  int m;
  int mdpi = -1;
  unsigned real_dpi = 0;
  int sign = dpi < bdpi ? -1 : 1; /* negative or positive magsteps? */


  for (m = 0; !real_dpi && m < MAGSTEP_MAX; m++) /* don't go forever */
    {
      mdpi = magstep (m * sign, bdpi);
      if (ABSL (mdpi - (int) dpi) <= 1) /* if this magstep matches, quit */
        real_dpi = mdpi;
      else if ((mdpi - (int) dpi) * sign > 0) /* if gone too far, quit */
        real_dpi = dpi;
    }

  /* If requested, return the encoded magstep (the loop went one too far).  */
  /* More unnecessary casts. */
  if (m_ret)
    *m_ret = real_dpi == (unsigned)(mdpi ? (m - 1) * sign : 0);

  /* Always return the true dpi found.  */
  return real_dpi ? real_dpi : dpi;
}
