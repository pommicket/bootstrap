#ifndef _STDIO_H
#define _STDIO_H

#include <stdc_common.h>
#include <stdarg.h>

int printf(const char *, ...);

/* ---  snprintf, adapted from github.com/nothings/stb   stb_sprintf.h */

#ifndef STB_SPRINTF_MIN
#define STB_SPRINTF_MIN 512 // how many characters per callback
#endif
typedef char *_STBSP_SPRINTFCB(const char *buf, void *user, int len);

// internal float utility functions
static int32_t _stbsp__real_to_str(char const **start, uint32_t *len, char *out, int32_t *decimal_pos, double value, uint32_t frac_digits);
static int32_t _stbsp__real_to_parts(int64_t *bits, int32_t *expo, double value);
#define STBSP__SPECIAL 0x7000

static char _stbsp__period = '.';
static char _stbsp__comma = ',';
static struct
{
   short temp; // force next field to be 2-byte aligned
   char pair[201];
} _stbsp__digitpair =
{
  0,
   "00010203040506070809101112131415161718192021222324"
   "25262728293031323334353637383940414243444546474849"
   "50515253545556575859606162636465666768697071727374"
   "75767778798081828384858687888990919293949596979899"
};

#define STBSP__LEFTJUST 1
#define STBSP__LEADINGPLUS 2
#define STBSP__LEADINGSPACE 4
#define STBSP__LEADING_0X 8
#define STBSP__LEADINGZERO 16
#define STBSP__INTMAX 32
#define STBSP__TRIPLET_COMMA 64
#define STBSP__NEGATIVE 128
#define STBSP__METRIC_SUFFIX 256
#define STBSP__HALFWIDTH 512
#define STBSP__METRIC_NOSPACE 1024
#define STBSP__METRIC_1024 2048
#define STBSP__METRIC_JEDEC 4096

static void _stbsp__lead_sign(uint32_t fl, char *sign)
{
   sign[0] = 0;
   if (fl & STBSP__NEGATIVE) {
      sign[0] = 1;
      sign[1] = '-';
   } else if (fl & STBSP__LEADINGSPACE) {
      sign[0] = 1;
      sign[1] = ' ';
   } else if (fl & STBSP__LEADINGPLUS) {
      sign[0] = 1;
      sign[1] = '+';
   }
}

static uint32_t _stbsp__strlen_limited(char const *s, uint32_t limit)
{
   char const * sn = s;

   // get up to 4-byte alignment
   for (;;) {
      if (((uintptr_t)sn & 3) == 0)
         break;

      if (!limit || *sn == 0)
         return (uint32_t)(sn - s);

      ++sn;
      --limit;
   }

   // scan over 4 bytes at a time to find terminating 0
   // this will intentionally scan up to 3 bytes past the end of buffers,
   // but becase it works 4B aligned, it will never cross page boundaries
   // (hence the STBSP__ASAN markup; the over-read here is intentional
   // and harmless)
   while (limit >= 4) {
      uint32_t v = *(uint32_t *)sn;
      // bit hack to find if there's a 0 byte in there
      if ((v - 0x01010101) & (~v) & 0x80808080UL)
         break;

      sn += 4;
      limit -= 4;
   }

   // handle the last few characters to find actual size
   while (limit && *sn) {
      ++sn;
      --limit;
   }

   return (uint32_t)(sn - s);
}

int __vsprintfcb(_STBSP_SPRINTFCB *callback, void *user, char *buf, char const *fmt, va_list va)
{
   static char hex[] = "0123456789abcdefxp";
   static char hexu[] = "0123456789ABCDEFXP";
   char *bf;
   char const *f;
   int tlen = 0;

   bf = buf;
   f = fmt;
   for (;;) {
      int32_t fw, pr, tz;
      uint32_t fl;

      // macros for the callback buffer stuff
      #define stbsp__chk_cb_bufL(bytes)                        \
         {                                                     \
            int len = (int)(bf - buf);                         \
            if ((len + (bytes)) >= STB_SPRINTF_MIN) {          \
               tlen += len;                                    \
               if (0 == (bf = buf = callback(buf, user, len))) \
                  goto done;                                   \
            }                                                  \
         }
      #define stbsp__chk_cb_buf(bytes)    \
         {                                \
            if (callback) {               \
               stbsp__chk_cb_bufL(bytes); \
            }                             \
         }
      #define stbsp__flush_cb()                      \
         {                                           \
            stbsp__chk_cb_bufL(STB_SPRINTF_MIN - 1); \
         } // flush if there is even one byte in the buffer
      #define stbsp__cb_buf_clamp(cl, v)                \
         cl = v;                                        \
         if (callback) {                                \
            int lg = STB_SPRINTF_MIN - (int)(bf - buf); \
            if (cl > lg)                                \
               cl = lg;                                 \
         }

      // fast copy everything up to the next % (or end of string)
      for (;;) {
         while (((uintptr_t)f) & 3) {
         schk1:
            if (f[0] == '%')
               goto scandd;
         schk2:
            if (f[0] == 0)
               goto endfmt;
            stbsp__chk_cb_buf(1);
            *bf++ = f[0];
            ++f;
         }
         for (;;) {
            // Check if the next 4 bytes contain %(0x25) or end of string.
            // Using the 'hasless' trick:
            // https://graphics.stanford.edu/~seander/bithacks.html#HasLessInWord
            uint32_t v, c;
            v = *(uint32_t *)f;
            c = (~v) & 0x80808080;
            if (((v ^ 0x25252525) - 0x01010101) & c)
               goto schk1;
            if ((v - 0x01010101) & c)
               goto schk2;
            if (callback)
               if ((STB_SPRINTF_MIN - (int)(bf - buf)) < 4)
                  goto schk1;
            {
                *(uint32_t *)bf = v;
            }
            bf += 4;
            f += 4;
         }
      }
   scandd:

      ++f;

      // ok, we have a percent, read the modifiers first
      fw = 0;
      pr = -1;
      fl = 0;
      tz = 0;

      // flags
      for (;;) {
         switch (f[0]) {
         // if we have left justify
         case '-':
            fl |= STBSP__LEFTJUST;
            ++f;
            continue;
         // if we have leading plus
         case '+':
            fl |= STBSP__LEADINGPLUS;
            ++f;
            continue;
         // if we have leading space
         case ' ':
            fl |= STBSP__LEADINGSPACE;
            ++f;
            continue;
         // if we have leading 0x
         case '#':
            fl |= STBSP__LEADING_0X;
            ++f;
            continue;
         // if we have thousand commas
         case '\'':
            fl |= STBSP__TRIPLET_COMMA;
            ++f;
            continue;
         // if we have kilo marker (none->kilo->kibi->jedec)
         case '$':
            if (fl & STBSP__METRIC_SUFFIX) {
               if (fl & STBSP__METRIC_1024) {
                  fl |= STBSP__METRIC_JEDEC;
               } else {
                  fl |= STBSP__METRIC_1024;
               }
            } else {
               fl |= STBSP__METRIC_SUFFIX;
            }
            ++f;
            continue;
         // if we don't want space between metric suffix and number
         case '_':
            fl |= STBSP__METRIC_NOSPACE;
            ++f;
            continue;
         // if we have leading zero
         case '0':
            fl |= STBSP__LEADINGZERO;
            ++f;
            goto flags_done;
         default: goto flags_done;
         }
      }
   flags_done:

      // get the field width
      if (f[0] == '*') {
         fw = va_arg(va, uint32_t);
         ++f;
      } else {
         while ((f[0] >= '0') && (f[0] <= '9')) {
            fw = fw * 10 + f[0] - '0';
            f++;
         }
      }
      // get the precision
      if (f[0] == '.') {
         ++f;
         if (f[0] == '*') {
            pr = va_arg(va, uint32_t);
            ++f;
         } else {
            pr = 0;
            while ((f[0] >= '0') && (f[0] <= '9')) {
               pr = pr * 10 + f[0] - '0';
               f++;
            }
         }
      }

      // handle integer size overrides
      switch (f[0]) {
      // are we halfwidth?
      case 'h':
         fl |= STBSP__HALFWIDTH;
         ++f;
         if (f[0] == 'h')
            ++f;  // QUARTERWIDTH
         break;
      // are we 64-bit (unix style)
      case 'l':
         fl |= ((sizeof(long) == 8) ? STBSP__INTMAX : 0);
         ++f;
         if (f[0] == 'l') {
            fl |= STBSP__INTMAX;
            ++f;
         }
         break;
      // are we 64-bit on intmax? (c99)
      case 'j':
         fl |= (sizeof(size_t) == 8) ? STBSP__INTMAX : 0;
         ++f;
         break;
      // are we 64-bit on size_t or ptrdiff_t? (c99)
      case 'z':
         fl |= (sizeof(ptrdiff_t) == 8) ? STBSP__INTMAX : 0;
         ++f;
         break;
      case 't':
         fl |= (sizeof(ptrdiff_t) == 8) ? STBSP__INTMAX : 0;
         ++f;
         break;
      // are we 64-bit (msft style)
      case 'I':
         if ((f[1] == '6') && (f[2] == '4')) {
            fl |= STBSP__INTMAX;
            f += 3;
         } else if ((f[1] == '3') && (f[2] == '2')) {
            f += 3;
         } else {
            fl |= ((sizeof(void *) == 8) ? STBSP__INTMAX : 0);
            ++f;
         }
         break;
      default: break;
      }

      // handle each replacement
      switch (f[0]) {
         #define STBSP__NUMSZ 512 // big enough for e308 (with commas) or e-307
         char num[STBSP__NUMSZ];
         char lead[8];
         char tail[8];
         char *s;
         char const *h;
         uint32_t l, n, cs;
         uint64_t n64;
         double fv;
         int32_t dp;
         char const *sn;

      case 's':
         // get the string
         s = va_arg(va, char *);
         if (s == 0)
            s = (char *)"null";
         // get the length, limited to desired precision
         // always limit to ~0u chars since our counts are 32b
         l = _stbsp__strlen_limited(s, (pr >= 0) ? pr : ~0u);
         lead[0] = 0;
         tail[0] = 0;
         pr = 0;
         dp = 0;
         cs = 0;
         // copy the string in
         goto scopy;

      case 'c': // char
         // get the character
         s = num + STBSP__NUMSZ - 1;
         *s = (char)va_arg(va, int);
         l = 1;
         lead[0] = 0;
         tail[0] = 0;
         pr = 0;
         dp = 0;
         cs = 0;
         goto scopy;

      case 'n': // weird write-bytes specifier
      {
         int *d = va_arg(va, int *);
         *d = tlen + (int)(bf - buf);
      } break;

      case 'A': // hex float
      case 'a': // hex float
         h = (f[0] == 'A') ? hexu : hex;
         fv = va_arg(va, double);
         if (pr == -1)
            pr = 6; // default is 6
         // read the double into a string
         if (_stbsp__real_to_parts((int64_t *)&n64, &dp, fv))
            fl |= STBSP__NEGATIVE;

         s = num + 64;

         _stbsp__lead_sign(fl, lead);

         if (dp == -1023)
            dp = (n64) ? -1022 : 0;
         else
            n64 |= (((uint64_t)1) << 52);
         n64 <<= (64 - 56);
         if (pr < 15)
            n64 += ((((uint64_t)8) << 56) >> (pr * 4));
// add leading chars
         lead[1 + lead[0]] = '0';
         lead[2 + lead[0]] = 'x';
         lead[0] += 2;
         *s++ = h[(n64 >> 60) & 15];
         n64 <<= 4;
         if (pr)
            *s++ = _stbsp__period;
         sn = s;

         // print the bits
         n = pr;
         if (n > 13)
            n = 13;
         if (pr > (int32_t)n)
            tz = pr - n;
         pr = 0;
         while (n--) {
            *s++ = h[(n64 >> 60) & 15];
            n64 <<= 4;
         }

         // print the expo
         tail[1] = h[17];
         if (dp < 0) {
            tail[2] = '-';
            dp = -dp;
         } else
            tail[2] = '+';
         n = (dp >= 1000) ? 6 : ((dp >= 100) ? 5 : ((dp >= 10) ? 4 : 3));
         tail[0] = (char)n;
         for (;;) {
            tail[n] = '0' + dp % 10;
            if (n <= 3)
               break;
            --n;
            dp /= 10;
         }

         dp = (int)(s - sn);
         l = (int)(s - (num + 64));
         s = num + 64;
         cs = 1 + (3 << 24);
         goto scopy;

      case 'G': // float
      case 'g': // float
         h = (f[0] == 'G') ? hexu : hex;
         fv = va_arg(va, double);
         if (pr == -1)
            pr = 6;
         else if (pr == 0)
            pr = 1; // default is 6
         // read the double into a string
         if (_stbsp__real_to_str(&sn, &l, num, &dp, fv, (pr - 1) | 0x80000000))
            fl |= STBSP__NEGATIVE;

         // clamp the precision and delete extra zeros after clamp
         n = pr;
         if (l > (uint32_t)pr)
            l = pr;
         while ((l > 1) && (pr) && (sn[l - 1] == '0')) {
            --pr;
            --l;
         }

         // should we use %e
         if ((dp <= -4) || (dp > (int32_t)n)) {
            if (pr > (int32_t)l)
               pr = l - 1;
            else if (pr)
               --pr; // when using %e, there is one digit before the decimal
            goto doexpfromg;
         }
         // this is the insane action to get the pr to match %g semantics for %f
         if (dp > 0) {
            pr = (dp < (int32_t)l) ? l - dp : 0;
         } else {
            pr = -dp + ((pr > (int32_t)l) ? (int32_t) l : pr);
         }
         goto dofloatfromg;

      case 'E': // float
      case 'e': // float
         h = (f[0] == 'E') ? hexu : hex;
         fv = va_arg(va, double);
         if (pr == -1)
            pr = 6; // default is 6
         // read the double into a string
         if (_stbsp__real_to_str(&sn, &l, num, &dp, fv, pr | 0x80000000))
            fl |= STBSP__NEGATIVE;
      doexpfromg:
         tail[0] = 0;
         _stbsp__lead_sign(fl, lead);
         if (dp == STBSP__SPECIAL) {
            s = (char *)sn;
            cs = 0;
            pr = 0;
            goto scopy;
         }
         s = num + 64;
         // handle leading chars
         *s++ = sn[0];

         if (pr)
            *s++ = _stbsp__period;

         // handle after decimal
         if ((l - 1) > (uint32_t)pr)
            l = pr + 1;
         for (n = 1; n < l; n++)
            *s++ = sn[n];
         // trailing zeros
         tz = pr - (l - 1);
         pr = 0;
         // dump expo
         tail[1] = h[0xe];
         dp -= 1;
         if (dp < 0) {
            tail[2] = '-';
            dp = -dp;
         } else
            tail[2] = '+';
         n = (dp >= 100) ? 5 : 4;
         tail[0] = (char)n;
         for (;;) {
            tail[n] = '0' + dp % 10;
            if (n <= 3)
               break;
            --n;
            dp /= 10;
         }
         cs = 1 + (3 << 24); // how many tens
         goto flt_lead;

      case 'f': // float
         fv = va_arg(va, double);
      doafloat:
         // do kilos
         if (fl & STBSP__METRIC_SUFFIX) {
            double divisor;
            divisor = 1000.0f;
            if (fl & STBSP__METRIC_1024)
               divisor = 1024.0;
            while (fl < 0x4000000) {
               if ((fv < divisor) && (fv > -divisor))
                  break;
               fv /= divisor;
               fl += 0x1000000;
            }
         }
         if (pr == -1)
            pr = 6; // default is 6
         // read the double into a string
         if (_stbsp__real_to_str(&sn, &l, num, &dp, fv, pr))
            fl |= STBSP__NEGATIVE;
      dofloatfromg:
         tail[0] = 0;
         _stbsp__lead_sign(fl, lead);
         if (dp == STBSP__SPECIAL) {
            s = (char *)sn;
            cs = 0;
            pr = 0;
            goto scopy;
         }
         s = num + 64;

         // handle the three decimal varieties
         if (dp <= 0) {
            int32_t i;
            // handle 0.000*000xxxx
            *s++ = '0';
            if (pr)
               *s++ = _stbsp__period;
            n = -dp;
            if ((int32_t)n > pr)
               n = pr;
            i = n;
            while (i) {
               if ((((uintptr_t)s) & 3) == 0)
                  break;
               *s++ = '0';
               --i;
            }
            while (i >= 4) {
               *(uint32_t *)s = 0x30303030;
               s += 4;
               i -= 4;
            }
            while (i) {
               *s++ = '0';
               --i;
            }
            if ((int32_t)(l + n) > pr)
               l = pr - n;
            i = l;
            while (i) {
               *s++ = *sn++;
               --i;
            }
            tz = pr - (n + l);
            cs = 1 + (3 << 24); // how many tens did we write (for commas below)
         } else {
            cs = (fl & STBSP__TRIPLET_COMMA) ? ((600 - (uint32_t)dp) % 3) : 0;
            if ((uint32_t)dp >= l) {
               // handle xxxx000*000.0
               n = 0;
               for (;;) {
                  if ((fl & STBSP__TRIPLET_COMMA) && (++cs == 4)) {
                     cs = 0;
                     *s++ = _stbsp__comma;
                  } else {
                     *s++ = sn[n];
                     ++n;
                     if (n >= l)
                        break;
                  }
               }
               if (n < (uint32_t)dp) {
                  n = dp - n;
                  if ((fl & STBSP__TRIPLET_COMMA) == 0) {
                     while (n) {
                        if ((((uintptr_t)s) & 3) == 0)
                           break;
                        *s++ = '0';
                        --n;
                     }
                     while (n >= 4) {
                        *(uint32_t *)s = 0x30303030;
                        s += 4;
                        n -= 4;
                     }
                  }
                  while (n) {
                     if ((fl & STBSP__TRIPLET_COMMA) && (++cs == 4)) {
                        cs = 0;
                        *s++ = _stbsp__comma;
                     } else {
                        *s++ = '0';
                        --n;
                     }
                  }
               }
               cs = (int)(s - (num + 64)) + (3 << 24); // cs is how many tens
               if (pr) {
                  *s++ = _stbsp__period;
                  tz = pr;
               }
            } else {
               // handle xxxxx.xxxx000*000
               n = 0;
               for (;;) {
                  if ((fl & STBSP__TRIPLET_COMMA) && (++cs == 4)) {
                     cs = 0;
                     *s++ = _stbsp__comma;
                  } else {
                     *s++ = sn[n];
                     ++n;
                     if (n >= (uint32_t)dp)
                        break;
                  }
               }
               cs = (int)(s - (num + 64)) + (3 << 24); // cs is how many tens
               if (pr)
                  *s++ = _stbsp__period;
               if ((l - dp) > (uint32_t)pr)
                  l = pr + dp;
               while (n < l) {
                  *s++ = sn[n];
                  ++n;
               }
               tz = pr - (l - dp);
            }
         }
         pr = 0;

         // handle k,m,g,t
         if (fl & STBSP__METRIC_SUFFIX) {
            char idx;
            idx = 1;
            if (fl & STBSP__METRIC_NOSPACE)
               idx = 0;
            tail[0] = idx;
            tail[1] = ' ';
            {
               if (fl >> 24) { // SI kilo is 'k', JEDEC and SI kibits are 'K'.
                  if (fl & STBSP__METRIC_1024)
                     tail[idx + 1] = "_KMGT"[fl >> 24];
                  else
                     tail[idx + 1] = "_kMGT"[fl >> 24];
                  idx++;
                  // If printing kibits and not in jedec, add the 'i'.
                  if (fl & STBSP__METRIC_1024 && !(fl & STBSP__METRIC_JEDEC)) {
                     tail[idx + 1] = 'i';
                     idx++;
                  }
                  tail[0] = idx;
               }
            }
         };

      flt_lead:
         // get the length that we copied
         l = (uint32_t)(s - (num + 64));
         s = num + 64;
         goto scopy;

      case 'B': // upper binary
      case 'b': // lower binary
         h = (f[0] == 'B') ? hexu : hex;
         lead[0] = 0;
         if (fl & STBSP__LEADING_0X) {
            lead[0] = 2;
            lead[1] = '0';
            lead[2] = h[0xb];
         }
         l = (8 << 4) | (1 << 8);
         goto radixnum;

      case 'o': // octal
         h = hexu;
         lead[0] = 0;
         if (fl & STBSP__LEADING_0X) {
            lead[0] = 1;
            lead[1] = '0';
         }
         l = (3 << 4) | (3 << 8);
         goto radixnum;

      case 'p': // pointer
         fl |= (sizeof(void *) == 8) ? STBSP__INTMAX : 0;
         pr = sizeof(void *) * 2;
         fl &= ~STBSP__LEADINGZERO; // 'p' only prints the pointer with zeros
                                    // fall through - to X

      case 'X': // upper hex
      case 'x': // lower hex
         h = (f[0] == 'X') ? hexu : hex;
         l = (4 << 4) | (4 << 8);
         lead[0] = 0;
         if (fl & STBSP__LEADING_0X) {
            lead[0] = 2;
            lead[1] = '0';
            lead[2] = h[16];
         }
      radixnum:
         // get the number
         if (fl & STBSP__INTMAX)
            n64 = va_arg(va, uint64_t);
         else
            n64 = va_arg(va, uint32_t);

         s = num + STBSP__NUMSZ;
         dp = 0;
         // clear tail, and clear leading if value is zero
         tail[0] = 0;
         if (n64 == 0) {
            lead[0] = 0;
            if (pr == 0) {
               l = 0;
               cs = 0;
               goto scopy;
            }
         }
         // convert to string
         for (;;) {
            *--s = h[n64 & ((1 << (l >> 8)) - 1)];
            n64 >>= (l >> 8);
            if (!((n64) || ((int32_t)((num + STBSP__NUMSZ) - s) < pr)))
               break;
            if (fl & STBSP__TRIPLET_COMMA) {
               ++l;
               if ((l & 15) == ((l >> 4) & 15)) {
                  l &= ~15;
                  *--s = _stbsp__comma;
               }
            }
         };
         // get the tens and the comma pos
         cs = (uint32_t)((num + STBSP__NUMSZ) - s) + ((((l >> 4) & 15)) << 24);
         // get the length that we copied
         l = (uint32_t)((num + STBSP__NUMSZ) - s);
         // copy it
         goto scopy;

      case 'u': // unsigned
      case 'i':
      case 'd': // integer
         // get the integer and abs it
         if (fl & STBSP__INTMAX) {
            int64_t i64 = va_arg(va, int64_t);
            n64 = (uint64_t)i64;
            if ((f[0] != 'u') && (i64 < 0)) {
               n64 = (uint64_t)-i64;
               fl |= STBSP__NEGATIVE;
            }
         } else {
            int32_t i = va_arg(va, int32_t);
            n64 = (uint32_t)i;
            if ((f[0] != 'u') && (i < 0)) {
               n64 = (uint32_t)-i;
               fl |= STBSP__NEGATIVE;
            }
         }

         if (fl & STBSP__METRIC_SUFFIX) {
            if (n64 < 1024)
               pr = 0;
            else if (pr == -1)
               pr = 1;
            fv = (double)(int64_t)n64;
            goto doafloat;
         }
         
         // convert to string
         s = num + STBSP__NUMSZ;
         l = 0;

         for (;;) {
            // do in 32-bit chunks (avoid lots of 64-bit divides even with constant denominators)
            char *o = s - 8;
            if (n64 >= 100000000) {
               n = (uint32_t)(n64 % 100000000);
               n64 /= 100000000;
            } else {
               n = (uint32_t)n64;
               n64 = 0;
            }
            if ((fl & STBSP__TRIPLET_COMMA) == 0) {
               do {
                  s -= 2;
                  *(uint16_t *)s = *(uint16_t *)&_stbsp__digitpair.pair[(n % 100) * 2];
                  n /= 100;
               } while (n);
            }
            while (n) {
               if ((fl & STBSP__TRIPLET_COMMA) && (l++ == 3)) {
                  l = 0;
                  *--s = _stbsp__comma;
                  --o;
               } else {
                  *--s = (char)(n % 10) + '0';
                  n /= 10;
               }
            }
            if (n64 == 0) {
               if ((s[0] == '0') && (s != (num + STBSP__NUMSZ)))
                  ++s;
               break;
            }
            while (s != o)
               if ((fl & STBSP__TRIPLET_COMMA) && (l++ == 3)) {
                  l = 0;
                  *--s = _stbsp__comma;
                  --o;
               } else {
                  *--s = '0';
               }
         }

         tail[0] = 0;
         _stbsp__lead_sign(fl, lead);

         // get the length that we copied
         l = (uint32_t)((num + STBSP__NUMSZ) - s);
         if (l == 0) {
            *--s = '0';
            l = 1;
         }
         cs = l + (3 << 24);
         if (pr < 0)
            pr = 0;

      scopy:
         // get fw=leading/trailing space, pr=leading zeros
         if (pr < (int32_t)l)
            pr = l;
         n = pr + lead[0] + tail[0] + tz;
         if (fw < (int32_t)n)
            fw = n;
         fw -= n;
         pr -= l;

         // handle right justify and leading zeros
         if ((fl & STBSP__LEFTJUST) == 0) {
            if (fl & STBSP__LEADINGZERO) // if leading zeros, everything is in pr
            {
               pr = (fw > pr) ? fw : pr;
               fw = 0;
            } else {
               fl &= ~STBSP__TRIPLET_COMMA; // if no leading zeros, then no commas
            }
         }

         // copy the spaces and/or zeros
         if (fw + pr) {
            int32_t i;
            uint32_t c;

            // copy leading spaces (or when doing %8.4d stuff)
            if ((fl & STBSP__LEFTJUST) == 0)
               while (fw > 0) {
                  stbsp__cb_buf_clamp(i, fw);
                  fw -= i;
                  while (i) {
                     if ((((uintptr_t)bf) & 3) == 0)
                        break;
                     *bf++ = ' ';
                     --i;
                  }
                  while (i >= 4) {
                     *(uint32_t *)bf = 0x20202020;
                     bf += 4;
                     i -= 4;
                  }
                  while (i) {
                     *bf++ = ' ';
                     --i;
                  }
                  stbsp__chk_cb_buf(1);
               }

            // copy leader
            sn = lead + 1;
            while (lead[0]) {
               stbsp__cb_buf_clamp(i, lead[0]);
               lead[0] -= (char)i;
               while (i) {
                  *bf++ = *sn++;
                  --i;
               }
               stbsp__chk_cb_buf(1);
            }

            // copy leading zeros
            c = cs >> 24;
            cs &= 0xffffff;
            cs = (fl & STBSP__TRIPLET_COMMA) ? ((uint32_t)(c - ((pr + cs) % (c + 1)))) : 0;
            while (pr > 0) {
               stbsp__cb_buf_clamp(i, pr);
               pr -= i;
               if ((fl & STBSP__TRIPLET_COMMA) == 0) {
                  while (i) {
                     if ((((uintptr_t)bf) & 3) == 0)
                        break;
                     *bf++ = '0';
                     --i;
                  }
                  while (i >= 4) {
                     *(uint32_t *)bf = 0x30303030;
                     bf += 4;
                     i -= 4;
                  }
               }
               while (i) {
                  if ((fl & STBSP__TRIPLET_COMMA) && (cs++ == c)) {
                     cs = 0;
                     *bf++ = _stbsp__comma;
                  } else
                     *bf++ = '0';
                  --i;
               }
               stbsp__chk_cb_buf(1);
            }
         }

         // copy leader if there is still one
         sn = lead + 1;
         while (lead[0]) {
            int32_t i;
            stbsp__cb_buf_clamp(i, lead[0]);
            lead[0] -= (char)i;
            while (i) {
               *bf++ = *sn++;
               --i;
            }
            stbsp__chk_cb_buf(1);
         }

         // copy the string
         n = l;
         while (n) {
            int32_t i;
            stbsp__cb_buf_clamp(i, n);
            n -= i;
            while (i >= 4) {
               *(uint32_t volatile *)bf = *(uint32_t volatile *)s;
               bf += 4;
               s += 4;
               i -= 4;
            }
            while (i) {
               *bf++ = *s++;
               --i;
            }
            stbsp__chk_cb_buf(1);
         }

         // copy trailing zeros
         while (tz) {
            int32_t i;
            stbsp__cb_buf_clamp(i, tz);
            tz -= i;
            while (i) {
               if ((((uintptr_t)bf) & 3) == 0)
                  break;
               *bf++ = '0';
               --i;
            }
            while (i >= 4) {
               *(uint32_t *)bf = 0x30303030;
               bf += 4;
               i -= 4;
            }
            while (i) {
               *bf++ = '0';
               --i;
            }
            stbsp__chk_cb_buf(1);
         }

         // copy tail if there is one
         sn = tail + 1;
         while (tail[0]) {
            int32_t i;
            stbsp__cb_buf_clamp(i, tail[0]);
            tail[0] -= (char)i;
            while (i) {
               *bf++ = *sn++;
               --i;
            }
            stbsp__chk_cb_buf(1);
         }

         // handle the left justify
         if (fl & STBSP__LEFTJUST)
            if (fw > 0) {
               while (fw) {
                  int32_t i;
                  stbsp__cb_buf_clamp(i, fw);
                  fw -= i;
                  while (i) {
                     if ((((uintptr_t)bf) & 3) == 0)
                        break;
                     *bf++ = ' ';
                     --i;
                  }
                  while (i >= 4) {
                     *(uint32_t *)bf = 0x20202020;
                     bf += 4;
                     i -= 4;
                  }
                  while (i--)
                     *bf++ = ' ';
                  stbsp__chk_cb_buf(1);
               }
            }
         break;

      default: // unknown, just copy code
         s = num + STBSP__NUMSZ - 1;
         *s = f[0];
         l = 1;
         fw = fl = 0;
         lead[0] = 0;
         tail[0] = 0;
         pr = 0;
         dp = 0;
         cs = 0;
         goto scopy;
      }
      ++f;
   }
endfmt:

   if (!callback)
      *bf = 0;
   else
      stbsp__flush_cb();

done:
   return tlen + (int)(bf - buf);
}

// cleanup
#undef STBSP__LEFTJUST
#undef STBSP__LEADINGPLUS
#undef STBSP__LEADINGSPACE
#undef STBSP__LEADING_0X
#undef STBSP__LEADINGZERO
#undef STBSP__INTMAX
#undef STBSP__TRIPLET_COMMA
#undef STBSP__NEGATIVE
#undef STBSP__METRIC_SUFFIX
#undef STBSP__NUMSZ
#undef stbsp__chk_cb_bufL
#undef stbsp__chk_cb_buf
#undef stbsp__flush_cb
#undef stbsp__cb_buf_clamp

// ============================================================================
//   wrapper functions

int sprintf(char *buf, char const *fmt, ...)
{
   int result;
   va_list va;
   va_start(va, fmt);
   result = __vsprintfcb(0, 0, buf, fmt, va);
   va_end(va);
   return result;
}

typedef struct stbsp__context {
   char *buf;
   int count;
   int length;
   char tmp[STB_SPRINTF_MIN];
} stbsp__context;

static char *stbsp__clamp_callback(const char *buf, void *user, int len)
{
   stbsp__context *c = (stbsp__context *)user;
      
   c->length += len;

   if (len > c->count)
      len = c->count;

   if (len) {
      if (buf != c->buf) {
         const char *s, *se;
         char *d;
         d = c->buf;
         s = buf;
         se = buf + len;
         do {
            *d++ = *s++;
         } while (s < se);
      }
      c->buf += len;
      c->count -= len;
   }

   if (c->count <= 0)
      return c->tmp;
   return (c->count >= STB_SPRINTF_MIN) ? c->buf : c->tmp; // go direct into buffer if you can
}

char * stbsp__count_clamp_callback( const char * buf, void * user, int len )
{
   stbsp__context * c = (stbsp__context*)user;
   (void) sizeof(buf);

   c->length += len;
   return c->tmp; // go direct into buffer if you can
}

int vsnprintf( char * buf, int count, char const * fmt, va_list va )
{
   stbsp__context c;
   if ( (count == 0) && !buf )
   {
      c.length = 0;

      __vsprintfcb( stbsp__count_clamp_callback, &c, c.tmp, fmt, va );
   }
   else
   {
      int l;

      c.buf = buf;
      c.count = count;
      c.length = 0;

      __vsprintfcb( stbsp__clamp_callback, &c, stbsp__clamp_callback(0,&c,0), fmt, va );

      // zero-terminate
      l = (int)( c.buf - buf );
      if ( l >= count ) // should never be greater, only equal (or less) than count
         l = count - 1;
      buf[l] = 0;
   }

   return c.length;
}

int snprintf(char *buf, int count, char const *fmt, ...)
{
   int result;
   va_list va;
   va_start(va, fmt);

   result = vsnprintf(buf, count, fmt, va);
   va_end(va);

   return result;
}

int vsprintf(char *buf, char const *fmt, va_list va)
{
   return __vsprintfcb(0, 0, buf, fmt, va);
}

// =======================================================================
//   low level float utility functions

// copies d to bits w/ strict aliasing (this compiles to nothing on /Ox)
#define STBSP__COPYFP(dest, src)  { *(long *)&dest = *(long *)&src; }
/*
                                    \
   {                                               \
      int cn;                                      \
      for (cn = 0; cn < 8; cn++)                   \
         ((char *)&dest)[cn] = ((char *)&src)[cn]; \
   }
*/

// get float info
int32_t _stbsp__real_to_parts(int64_t *bits, int32_t *expo, double value)
{
   double d;
   int64_t b = 0;

   // load value and round at the frac_digits
   d = value;

   STBSP__COPYFP(b, d);

   *bits = b & ((((uint64_t)1) << 52) - 1);
   *expo = (int32_t)(((b >> 52) & 2047) - 1023);

   return (int32_t)((uint64_t) b >> 63);
}

static double const stbsp__bot[23] = {
   1e+000, 1e+001, 1e+002, 1e+003, 1e+004, 1e+005, 1e+006, 1e+007, 1e+008, 1e+009, 1e+010, 1e+011,
   1e+012, 1e+013, 1e+014, 1e+015, 1e+016, 1e+017, 1e+018, 1e+019, 1e+020, 1e+021, 1e+022
};
static double const stbsp__negbot[22] = {
   1e-001, 1e-002, 1e-003, 1e-004, 1e-005, 1e-006, 1e-007, 1e-008, 1e-009, 1e-010, 1e-011,
   1e-012, 1e-013, 1e-014, 1e-015, 1e-016, 1e-017, 1e-018, 1e-019, 1e-020, 1e-021, 1e-022
};
static double const stbsp__negboterr[22] = {
   -5.551115123125783e-018,  -2.0816681711721684e-019, -2.0816681711721686e-020, -4.7921736023859299e-021, -8.1803053914031305e-022, 4.5251888174113741e-023,
   4.5251888174113739e-024,  -2.0922560830128471e-025, -6.2281591457779853e-026, -3.6432197315497743e-027, 6.0503030718060191e-028,  2.0113352370744385e-029,
   -3.0373745563400371e-030, 1.1806906454401013e-032,  -7.7705399876661076e-032, 2.0902213275965398e-033,  -7.1542424054621921e-034, -7.1542424054621926e-035,
   2.4754073164739869e-036,  5.4846728545790429e-037,  9.2462547772103625e-038,  -4.8596774326570872e-039
};
static double const stbsp__top[13] = {
   1e+023, 1e+046, 1e+069, 1e+092, 1e+115, 1e+138, 1e+161, 1e+184, 1e+207, 1e+230, 1e+253, 1e+276, 1e+299
};
static double const stbsp__negtop[13] = {
   1e-023, 1e-046, 1e-069, 1e-092, 1e-115, 1e-138, 1e-161, 1e-184, 1e-207, 1e-230, 1e-253, 1e-276, 1e-299
};
static double const stbsp__toperr[13] = {
   8388608.,
   6.8601809640529717e+028,
   -7.253143638152921e+052,
   -4.3377296974619174e+075,
   -1.5559416129466825e+098,
   -3.2841562489204913e+121,
   -3.7745893248228135e+144,
   -1.7356668416969134e+167,
   -3.8893577551088374e+190,
   -9.9566444326005119e+213,
   6.3641293062232429e+236,
   -5.2069140800249813e+259,
   -5.2504760255204387e+282
};
static double const stbsp__negtoperr[13] = {
   3.9565301985100693e-040,  -2.299904345391321e-063,  3.6506201437945798e-086,  1.1875228833981544e-109,
   -5.0644902316928607e-132, -6.7156837247865426e-155, -2.812077463003139e-178,  -5.7778912386589953e-201,
   7.4997100559334532e-224,  -4.6439668915134491e-247, -6.3691100762962136e-270, -9.436808465446358e-293,
   8.0970921678014997e-317
};

static uint64_t const stbsp__powten[20] = {
   1,
   10,
   100,
   1000,
   10000,
   100000,
   1000000,
   10000000,
   100000000,
   1000000000,
   10000000000ULL,
   100000000000ULL,
   1000000000000ULL,
   10000000000000ULL,
   100000000000000ULL,
   1000000000000000ULL,
   10000000000000000ULL,
   100000000000000000ULL,
   1000000000000000000ULL,
   10000000000000000000ULL
};
#define stbsp__tento19th (1000000000000000000ULL)

#define stbsp__ddmulthi(oh, ol, xh, yh)                            \
   {                                                               \
      double ahi = 0, alo, bhi = 0, blo;                           \
      int64_t bt;                                             \
      oh = xh * yh;                                                \
      STBSP__COPYFP(bt, xh);                                       \
      bt &= ((~(uint64_t)0) << 27);                           \
      STBSP__COPYFP(ahi, bt);                                      \
      alo = xh - ahi;                                              \
      STBSP__COPYFP(bt, yh);                                       \
      bt &= ((~(uint64_t)0) << 27);                           \
      STBSP__COPYFP(bhi, bt);                                      \
      blo = yh - bhi;                                              \
      ol = ((ahi * bhi - oh) + ahi * blo + alo * bhi) + alo * blo; \
   }

#define stbsp__ddtoS64(ob, xh, xl)          \
   {                                        \
      double ahi = 0, alo, vh, t;           \
      ob = (int64_t)xh;                \
      vh = (double)ob;                      \
      ahi = (xh - vh);                      \
      t = (ahi - xh);                       \
      alo = (xh - (ahi - t)) - (vh + t);    \
      ob += (int64_t)(ahi + alo + xl); \
   }

#define stbsp__ddrenorm(oh, ol) \
   {                            \
      double s;                 \
      s = oh + ol;              \
      ol = ol - (s - oh);       \
      oh = s;                   \
   }

#define stbsp__ddmultlo(oh, ol, xh, xl, yh, yl) ol = ol + (xh * yl + xl * yh);

#define stbsp__ddmultlos(oh, ol, xh, yl) ol = ol + (xh * yl);

static void stbsp__raise_to_power10(double *ohi, double *olo, double d, int32_t power) // power can be -323 to +350
{
   double ph, pl;
   if ((power >= 0) && (power <= 22)) {
      stbsp__ddmulthi(ph, pl, d, stbsp__bot[power]);
   } else {
      int32_t e, et, eb;
      double p2h, p2l;

      e = power;
      if (power < 0)
         e = -e;
      et = (e * 0x2c9) >> 14; /* %23 */
      if (et > 13)
         et = 13;
      eb = e - (et * 23);

      ph = d;
      pl = 0.0;
      if (power < 0) {
         if (eb) {
            --eb;
            stbsp__ddmulthi(ph, pl, d, stbsp__negbot[eb]);
            stbsp__ddmultlos(ph, pl, d, stbsp__negboterr[eb]);
         }
         if (et) {
            stbsp__ddrenorm(ph, pl);
            --et;
            stbsp__ddmulthi(p2h, p2l, ph, stbsp__negtop[et]);
            stbsp__ddmultlo(p2h, p2l, ph, pl, stbsp__negtop[et], stbsp__negtoperr[et]);
            ph = p2h;
            pl = p2l;
         }
      } else {
         if (eb) {
            e = eb;
            if (eb > 22)
               eb = 22;
            e -= eb;
            stbsp__ddmulthi(ph, pl, d, stbsp__bot[eb]);
            if (e) {
               stbsp__ddrenorm(ph, pl);
               stbsp__ddmulthi(p2h, p2l, ph, stbsp__bot[e]);
               stbsp__ddmultlos(p2h, p2l, stbsp__bot[e], pl);
               ph = p2h;
               pl = p2l;
            }
         }
         if (et) {
            stbsp__ddrenorm(ph, pl);
            --et;
            stbsp__ddmulthi(p2h, p2l, ph, stbsp__top[et]);
            stbsp__ddmultlo(p2h, p2l, ph, pl, stbsp__top[et], stbsp__toperr[et]);
            ph = p2h;
            pl = p2l;
         }
      }
   }
   stbsp__ddrenorm(ph, pl);
   *ohi = ph;
   *olo = pl;
}

// given a float value, returns the significant bits in bits, and the position of the
//   decimal point in decimal_pos.  +/-INF and NAN are specified by special values
//   returned in the decimal_pos parameter.
// frac_digits is absolute normally, but if you want from first significant digits (got %g and %e), or in 0x80000000
static int32_t _stbsp__real_to_str(char const **start, uint32_t *len, char *out, int32_t *decimal_pos, double value, uint32_t frac_digits)
{
   double d;
   int64_t bits = 0;
   int32_t expo, e, ng, tens;

   d = value;
   STBSP__COPYFP(bits, d);
   expo = (int32_t)((bits >> 52) & 2047);
   ng = (int32_t)((uint64_t) bits >> 63);
   if (ng)
      d = -d;

   if (expo == 2047) // is nan or inf?
   {
      *start = (bits & ((((uint64_t)1) << 52) - 1)) ? "NaN" : "Inf";
      *decimal_pos = STBSP__SPECIAL;
      *len = 3;
      return ng;
   }

   if (expo == 0) // is zero or denormal
   {
      if (((uint64_t) bits << 1) == 0) // do zero
      {
         *decimal_pos = 1;
         *start = out;
         out[0] = '0';
         *len = 1;
         return ng;
      }
      // find the right expo for denormals
      {
         int64_t v = ((uint64_t)1) << 51;
         while ((bits & v) == 0) {
            --expo;
            v >>= 1;
         }
      }
   }

   // find the decimal exponent as well as the decimal bits of the value
   {
      double ph, pl;

      // log10 estimate - very specifically tweaked to hit or undershoot by no more than 1 of log10 of all expos 1..2046
      tens = expo - 1023;
      tens = (tens < 0) ? ((tens * 617) / 2048) : (((tens * 1233) / 4096) + 1);

      // move the significant bits into position and stick them into an int
      stbsp__raise_to_power10(&ph, &pl, d, 18 - tens);

      // get full as much precision from double-double as possible
      stbsp__ddtoS64(bits, ph, pl);

      // check if we undershot
      if (((uint64_t)bits) >= stbsp__tento19th)
         ++tens;
   }

   // now do the rounding in integer land
   frac_digits = (frac_digits & 0x80000000) ? ((frac_digits & 0x7ffffff) + 1) : (tens + frac_digits);
   if ((frac_digits < 24)) {
      uint32_t dg = 1;
      if ((uint64_t)bits >= stbsp__powten[9])
         dg = 10;
      while ((uint64_t)bits >= stbsp__powten[dg]) {
         ++dg;
         if (dg == 20)
            goto noround;
      }
      if (frac_digits < dg) {
         uint64_t r;
         // add 0.5 at the right position and round
         e = dg - frac_digits;
         if ((uint32_t)e >= 24)
            goto noround;
         r = stbsp__powten[e];
         bits = bits + (r / 2);
         if ((uint64_t)bits >= stbsp__powten[dg])
            ++tens;
         bits /= r;
      }
   noround:;
   }

   // kill long trailing runs of zeros
   if (bits) {
      uint32_t n;
      for (;;) {
         if (bits <= 0xffffffff)
            break;
         if (bits % 1000)
            goto donez;
         bits /= 1000;
      }
      n = (uint32_t)bits;
      while ((n % 1000) == 0)
         n /= 1000;
      bits = n;
   donez:;
   }

   // convert to string
   out += 64;
   e = 0;
   for (;;) {
      uint32_t n;
      char *o = out - 8;
      // do the conversion in chunks of U32s (avoid most 64-bit divides, worth it, constant denomiators be damned)
      if (bits >= 100000000) {
         n = (uint32_t)(bits % 100000000);
         bits /= 100000000;
      } else {
         n = (uint32_t)bits;
         bits = 0;
      }
      while (n) {
         out -= 2;
         *(uint16_t *)out = *(uint16_t *)&_stbsp__digitpair.pair[(n % 100) * 2];
         n /= 100;
         e += 2;
      }
      if (bits == 0) {
         if ((e) && (out[0] == '0')) {
            ++out;
            --e;
         }
         break;
      }
      while (out != o) {
         *--out = '0';
         ++e;
      }
   }

   *decimal_pos = tens;
   *start = out;
   *len = e;
   return ng;
}

#undef stbsp__ddmulthi
#undef stbsp__ddrenorm
#undef stbsp__ddmultlo
#undef stbsp__ddmultlos
#undef STBSP__SPECIAL
#undef STBSP__COPYFP

// these are the constants that gnu uses, but they don't really matter for us
#define _IOFBF 0
#define _IOLBF 1
#define _IONBF 2
#define BUFSIZ 8192


#define EOF (-1)
#define FILENAME_MAX 4096
#define FOPEN_MAX 16
typedef long fpos_t;
#define L_tmpnam 20
#define SEEK_CUR 1
#define SEEK_END 2
#define SEEK_SET 0
#define TMP_MAX 500

long lseek(int fd, long offset, int whence) {
	return __syscall(8, fd, offset, whence, 0, 0, 0);
}

size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream) {
	size_t count;
	if (nmemb > 0xffffffffffffffff / size) {
		stream->err = 1;
		return 0;
	}
	count = size * nmemb;
	while (count > 0) {
		long n = write(stream->fd, ptr, count);
		if (n <= 0) break;
		count -= n;
		ptr = (char *)ptr + n;
	}
	if (count > 0) stream->err = 1;
	return nmemb - count / size;
}

size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream) {
	size_t count;
	long n = 1;
	if (nmemb > 0xffffffffffffffff / size) {
		stream->err = 1;
		return 0;
	}
	if (size == 0 || nmemb == 0) return 0;
	
	count = size * nmemb;
	
	if (stream->has_ungetc) {
		*(char *)ptr = stream->ungetc;
		stream->has_ungetc = 0;
		ptr = (char *)ptr + 1;
		--count;
	}
	if (stream->eof) return 0;
	
	while (count > 0) {
		n = read(stream->fd, ptr, count);
		if (n <= 0) break;
		count -= n;
		ptr = (char *)ptr + n;
	}
	if (n == 0) stream->eof = 1;
	if (n < 0) stream->err = 1;
	return nmemb - count / size;
}

static char *__fprintf_callback(const char *buf, void *user, int len) {
	FILE *fp = user;
	fwrite(buf, 1, len, fp);
	return buf;
}

int vfprintf(FILE *fp, const char *fmt, va_list args) {
	char buf[STB_SPRINTF_MIN];
	return __vsprintfcb(__fprintf_callback, fp, buf, fmt, args);
}

int fprintf(FILE *fp, const char *fmt, ...) {
	va_list args;
	int ret;
	va_start(args, fmt);
	ret = vfprintf(fp, fmt, args);
	va_end(args);
	return ret;
}

int vprintf(const char *fmt, va_list args) {
	return vfprintf(stdout, fmt, args);	
}

int printf(const char *fmt, ...) {
	va_list args;
	int ret;
	va_start(args, fmt);
	ret = vfprintf(stdout, fmt, args);
	va_end(args);
	return ret;
}

#define O_RDONLY    0
#define O_WRONLY    1
#define O_RDWR      2
#define O_CREAT     0100
#define O_TRUNC     01000
#define O_APPEND    02000
#define O_DIRECTORY 0200000
#define __O_TMPFILE   020000000
#define O_TMPFILE  (__O_TMPFILE | O_DIRECTORY)
int open(const char *path, int flags, int mode) {
	return __syscall(2, path, flags, mode, 0, 0, 0);
}

int close(int fd) {
	return __syscall(3, fd, 0, 0, 0, 0, 0);
}


int _fopen_flags_from_mode(const char *mode) {
	int flags;
	if (mode[1] == '+' || (mode[1] && mode[2] == '+')) {
		// open for updating
		flags = O_RDWR;
		switch (mode[0]) {
		case 'r': break;
		case 'w': flags |= O_TRUNC | O_CREAT; break;
		case 'a': flags |= O_APPEND | O_CREAT; break;
		default: return -1;
		}
	} else {
		switch (mode[0]) {
		case 'r': flags = O_RDONLY; break;
		case 'w': flags = O_WRONLY | O_TRUNC | O_CREAT; break;
		case 'a': flags = O_WRONLY | O_APPEND | O_CREAT; break;
		default: return -1;
		}
	}
	return flags;
}

FILE *_FILE_from_fd(int fd) {
	FILE *fp = calloc(1, sizeof(FILE));
	fp->fd = fd;
	return fp;
}

FILE *fopen(const char *filename, const char *mode) {
	int flags = _fopen_flags_from_mode(mode);
	if (flags < 0) return NULL;
	int fd;
	
	fd = open(filename, flags, 0644);
	if (fd < 0) return NULL;
	return _FILE_from_fd(fd);
}

int fclose(FILE *stream) {
	int ret = close(stream->fd);
	free(stream);
	return ret;
}

int fflush(FILE *stream) {
	// we don't buffer anything	
	return 0;
}

FILE *freopen(const char *filename, const char *mode, FILE *stream) {
	int flags = _fopen_flags_from_mode(mode);
	close(stream->fd);
	if (flags < 0) return NULL;
	stream->eof = stream->err = 0;
	stream->fd = open(filename, flags, 0644);
	return stream;
}

int unlink(const char *pathname) {
	return __syscall(87, pathname, 0, 0, 0, 0, 0);
}

int rmdir(const char *pathname) {
	return __syscall(84, pathname, 0, 0, 0, 0, 0);
}

int remove(const char *filename) {
	return rmdir(filename)
		? unlink(filename)
		: 0;
}

int rename(const char *old, const char *new) {
	return __syscall(82, old, new, 0, 0, 0, 0);
}

char *tmpnam(char *s) {
	struct timespec t = {0};
	do {		
		clock_gettime(CLOCK_MONOTONIC, &t); // use clock as a source of randomness
		sprintf(s, "/tmp/C_%06u", t.tv_nsec % 1000000);
	} while (access(s, F_OK) == 0); // if file exists, generate a new name
	return s;
}

FILE *tmpfile(void) {
	int fd = open("/tmp", O_TMPFILE | O_RDWR, 0600);
	if (fd < 0) return NULL;
	return _FILE_from_fd(fd);
}

int getc(FILE *stream) {
	unsigned char c;
	long n;
	if (stream->eof) return EOF;
	n = fread(&c, 1, 1, stream);
	if (n != 1) return EOF;
	return c;
}

int fgetc(FILE *stream) {
	return getc(stream);
}

char *fgets(char *s, int n, FILE *stream) {
	char *p = s, *end = p + (n-1);
	
	if (stream->eof) return NULL;
	
	while (p < end) {
		size_t n = fread(p, 1, 1, stream);
		if (n != 1) {
			if (p == s) {
				// end of file reached, and no characters were read
				return NULL;
			}
			break;
		}
		if (*p == '\n') {
			++p;
			break;
		}
		++p;
	}
	*p = '\0';
	return s;
}

int putc(int c, FILE *stream) {
	size_t n = fwrite(&c, 1, 1, stream);
	if (n == 1) return c;
	return EOF;
}

int fputc(int c, FILE *stream) {
	return putc(c, stream);
}

int fputs(const char *s, FILE *stream) {
	size_t n = strlen(s);
	if (fwrite(s, 1, n, stream) == n)
		return n;
	return EOF;
}

int getchar(void) {
	return getc(stdin);
}

char *gets(char *s) {
	char *p;
	fgets(s, 1l<<20, stdin);
	if (*s) {
		p = s + strlen(s) - 1;
		// remove newline
		if (*p == '\n')
			*p = '\0';
	}
	return s;
}

int putchar(int c) {
	return putc(c, stdout);
}

int puts(const char *s) {
	fputs(s, stdout);
	putchar('\n');
}

int ungetc(int c, FILE *stream) {
	if (c == EOF || stream->has_ungetc) return EOF;
	stream->has_ungetc = 1;
	stream->ungetc = c;
	stream->eof = 0;
	return c;
}


int fgetpos(FILE *stream, fpos_t *pos) {
	long off = lseek(stream->fd, 0, SEEK_CUR);
	if (off < 0) {
		errno = EIO;
		return EIO;
	}
	*pos = off;
	return 0;
}

int fsetpos(FILE *stream, const fpos_t *pos) {
	long off = lseek(stream->fd, *pos, SEEK_SET);
	if (off < 0) {
		errno = EIO;
		return EIO;
	}
	stream->eof = 0;
	return 0;
}

int fseek(FILE *stream, long int offset, int whence) {
	long off = lseek(stream->fd, offset, whence);
	if (off < 0) {
		return EIO;
	}
	stream->eof = 0;
	return 0;
}

long int ftell(FILE *stream) {
	long off = lseek(stream->fd, 0, SEEK_CUR);
	if (off < 0) {
		errno = EIO;
		return -1L;
	}
	return off;
}

void rewind(FILE *stream) {
	fseek(stream, 0, SEEK_SET);
	stream->err = 0;
}

void clearerr(FILE *stream) {
	stream->err = 0;
}

int feof(FILE *stream) {
	return stream->eof;
}

int ferror(FILE *stream) {
	return stream->err;
}

// we don't buffer anything
// we're allowed to do this: "The contents of the array at any time are indeterminate." C89 § 4.9.5.6
void setbuf(FILE *stream, char *buf) {
}

int setvbuf(FILE *stream, char *buf, int mode, size_t size) {
	return 0;
}

typedef int _VscanfNextChar(void *, long *);
typedef int _VscanfPeekChar(void *);
int _str_next_char(void *dat, long *pos) {
	const char **s = dat;
	int c = **s;
	if (c == '\0') return c;
	++*pos;
	++*s;
	return c;
}
int _file_next_char(void *dat, long *pos) {
	int c = getc(dat);
	if (c == EOF) return c;
	++*pos;
	return c;
}
int _str_peek_char(void *dat) {
	const char **s = dat;
	return **s;
}
int _file_peek_char(void *dat) {
	int c = getc(dat);
	ungetc(c, dat);
	return c;
}

int _clamp_long_to_int(long x) {
	if (x < INT_MIN) return INT_MIN;
	if (x > INT_MAX) return INT_MAX;
	return x;
}

short _clamp_long_to_short(long x) {
	if (x < SHRT_MIN) return SHRT_MIN;
	if (x > SHRT_MAX) return SHRT_MAX;
	return x;
}

unsigned _clamp_ulong_to_uint(unsigned long x) {
	if (x > UINT_MAX) return UINT_MAX;
	return x;
}

unsigned short _clamp_ulong_to_ushort(unsigned long x) {
	if (x > USHRT_MAX) return USHRT_MAX;
	return x;
}

void _bad_scanf(void) {
	fprintf(stderr, "bad scanf format.\n");
	abort();
}

char _parse_escape_sequence(char **p_str) {
	char *str = *p_str;
	if (*str == '\\') {
		++str;
		switch (*str) {
		case 'n': *p_str = str + 1; return '\n';
		case 'v': *p_str = str + 1; return '\v';
		case 't': *p_str = str + 1; return '\t';
		case 'a': *p_str = str + 1; return '\a';
		case 'f': *p_str = str + 1; return '\f';
		case 'r': *p_str = str + 1; return '\r';
		case 'b': *p_str = str + 1; return '\b';
		case 'x':
			++str;
			return (char)strtoul(str, p_str, 16);
		case '0':case '1':case '2':case '3':case '4':case '5':case '6':case '7': {
			int c = *str++ - '0';
			if (_isdigit_in_base(*str, 8)) c = (c << 3) + *str - '0', ++str;
			if (_isdigit_in_base(*str, 8)) c = (c << 3) + *str - '0', ++str;
			return c;
		} break;
		default: *p_str = str + 1; return *str;
		}
	} else {
		*p_str += 1;
		return *str;	
	}
}

int _vscanf(_VscanfNextChar *__next_char, _VscanfPeekChar *__peek_char, int terminator, void *data, const char *fmt, va_list args) {
	long pos = 0; // position in file/string (needed for %n)
	int assignments = 0;
	char number[128], *p_number;
	unsigned char charset[256];
	int i;
	
	#define _next_char() (__next_char(data, &pos))
	#define _peek_char() (__peek_char(data))
	while (*fmt) {
		if (*fmt == '%') {
			int base = 10;
			int assign = 1;
			long field_width = LONG_MAX;
			int modifier = 0;
			char *end;
			
			++fmt;
			if (*fmt == '*') assign = 0, ++fmt; // assignment suppression
			if (*fmt >= '0' && *fmt <= '9')
				field_width = strtol(fmt, &fmt, 10); // field width
			if (*fmt == 'l' || *fmt == 'L' || *fmt == 'h')
				modifier = *fmt, ++fmt;
			switch (*fmt) {
			case 'd': {
				while (isspace(_peek_char())) _next_char();
				// signed decimal integer
				++fmt;
				if (field_width > 100) field_width = 100; // max number length
				if (field_width == 0) goto vscanf_done; // number can't have size 0
				int c = _peek_char();
				p_number = number;
				if (c == '-' || c == '+') {
					if (field_width == 1) goto vscanf_done;
					*p_number++ = _next_char();
				}
				while ((p_number - number) < field_width && isdigit(_peek_char()))
					*p_number++ = _next_char();
				*p_number = 0;
				long value = strtol(number, &end, 10);
				if (end == number) goto vscanf_done; // bad number
				if (assign) {
					switch (modifier) {
					case 0: *va_arg(args, int*) = _clamp_long_to_int(value); break;
					case 'h': *va_arg(args, short*) = _clamp_long_to_short(value); break;
					case 'l': *va_arg(args, long*) = value; break;
					default: _bad_scanf(); break;
					}
					++assignments;
				}
			} break;
			case 'i': {
				while (isspace(_peek_char())) _next_char();
				// signed integer
				long value = 0;
				++fmt;
				if (field_width > 100) field_width = 100; // max number length
				if (field_width == 0) goto vscanf_done; // number can't have size 0
				int c = _peek_char();
				p_number = number;
				if (c == '-' || c == '+') {
					if (field_width == 1) goto vscanf_done;
					*p_number++ = _next_char();
					c = _peek_char();
				}
				if (c == '0') {
					*p_number++ = _next_char();
					if ((p_number - number) < field_width) {
						c = _peek_char();
						if (c == 'x') {
							if ((p_number - number) < field_width-1)
								*p_number++ = _next_char(), base = 16;
							else
								goto emit_value; // e.g. 0x... width field width 2
						} else {
							base = 8;
						}
					} else goto emit_value;
				}
				while ((p_number - number) < field_width && _isdigit_in_base(_peek_char(), base))
					*p_number++ = _next_char();
				*p_number = 0;
				value = strtol(number, &end, 0);
				if (end == number) goto vscanf_done; // bad number
				emit_value:
				if (assign) {
					switch (modifier) {
					case 0: *va_arg(args, int*) = _clamp_long_to_int(value); break;
					case 'h': *va_arg(args, short*) = _clamp_long_to_short(value); break;
					case 'l': *va_arg(args, long*) = value; break;
					default: _bad_scanf(); break;
					}
					++assignments;
				}
			} break;
			case 'o': base = 8; goto vscanf_unsigned;
			case 'u': goto vscanf_unsigned;
			case 'p': modifier = 'l', base = 16; goto vscanf_unsigned;
			case 'x': case 'X': base = 16; goto vscanf_unsigned;
			vscanf_unsigned:{
				while (isspace(_peek_char())) _next_char();
				// unsigned integers
				++fmt;
				if (field_width > 100) field_width = 100; // max number length
				if (field_width == 0) goto vscanf_done;
				int c = _peek_char();
				p_number = number;
				if (c == '+') *p_number++ = _next_char();
				while ((p_number - number) < field_width && _isdigit_in_base(_peek_char(), base))
					*p_number++ = _next_char();
				*p_number = 0;
				unsigned long value = strtoul(number, &end, base);
				if (end == number) goto vscanf_done; // bad number
				if (assign) {
					switch (modifier) {
					case 0: *va_arg(args, unsigned*) = _clamp_ulong_to_uint(value); break;
					case 'h': *va_arg(args, unsigned short*) = _clamp_ulong_to_ushort(value); break;
					case 'l': *va_arg(args, unsigned long*) = value; break;
					default: _bad_scanf(); break;
					}
					++assignments;
				}
			} break;
			case 'e':
			case 'f':
			case 'g':
			case 'E':
			case 'G': {
				while (isspace(_peek_char())) _next_char();
				// floats
				++fmt;
				if (field_width > 100) field_width = 100; // max number length
				if (field_width == 0) goto vscanf_done;
				int c = _peek_char();
				p_number = number;
				if (c == '-' || c == '+') {
					if (field_width == 1) goto vscanf_done;
					*p_number++ = _next_char();
					c = _peek_char();
				}
				if (c != '.' && !isdigit(c))
					goto vscanf_done;
				while ((p_number - number) < field_width && isdigit(_peek_char()))
					*p_number++ = _next_char();
				if ((p_number - number) < field_width && _peek_char() == '.') {
					*p_number++ = _next_char();
					while ((p_number - number) < field_width && isdigit(_peek_char()))
						*p_number++ = _next_char();
				}
				c = _peek_char();
				if ((p_number - number) < field_width && c == 'e' || c == 'E') {
					*p_number++ = _next_char();
					c = _peek_char();
					if ((p_number - number) < field_width && c == '+')
						*p_number++ = _next_char();
					else if ((p_number - number) < field_width && c == '-')
						*p_number++ = _next_char();
					
					while ((p_number - number) < field_width && isdigit(_peek_char()))
						*p_number++ = _next_char();
				}
				double value = strtod(number, &end);
				if (end == number) goto vscanf_done; // bad number
				if (assign) {
					switch (modifier) {
					case 0: *va_arg(args, float*) = value; break;
					case 'l': case 'L': *va_arg(args, double*) = value; break;
					default: _bad_scanf(); break;
					}
					
					++assignments;
				}
			} break;
			case 's': {
				while (isspace(_peek_char())) _next_char();
				// string of non-whitespace characters
				++fmt;
				char *str = assign ? va_arg(args, char*) : NULL, *p = str;
				for (i = 0; i < field_width && !isspace(_peek_char()); ++i) {
					int c = _next_char();
					if (c == terminator) break;
					if (p) *p++ = c;
				}
				if (i == 0) goto vscanf_done; // empty sequence
				if (p) {
					*p = 0;
					++assignments;
				}
			} break;
			case '[': {
				// string of characters in charset
				int complement = 0;
				++fmt;
				if (*fmt == '^') {
					complement = 1;
					++fmt;
				}
				memset(charset, complement, sizeof charset);
				do { // NB: this is a do-while loop and not a while loop, because []] matches strings of ]'s.
					charset[(unsigned char)_parse_escape_sequence(&fmt)] = !complement;
				} while (*fmt != ']');
				++fmt; // skip ]
				char *str = assign ? va_arg(args, char*) : NULL, *p = str;
				for (i = 0; i < field_width && charset[(unsigned char)_peek_char()]; ++i) {
					int c = _next_char();
					if (c == terminator) break;
					if (p) *p++ = c;
				}
				if (i == 0) goto vscanf_done; // empty sequence
				if (p) {
					*p = 0;
					++assignments;
				}
			} break;
			case 'c': {
				// string of characters
				++fmt;
				char *str = assign ? va_arg(args, char*) : NULL, *p = str;
				if (field_width == LONG_MAX) field_width = 1;
				for (i = 0; i < field_width; ++i) {
					int c = _next_char();
					if (c == terminator) break;
					if (p) *p++ = c;
				}
				if (i < field_width) goto vscanf_done; // end of file encountered
				if (p) {
					++assignments;
				}
			} break;
			case 'n':
				++fmt;
				switch (modifier) {
				case 0: *va_arg(args, int *) = pos; break;
				case 'h': *va_arg(args, short *) = pos; break;
				case 'l': *va_arg(args, long *) = pos; break;
				default: _bad_scanf(); break;
				}
				break;
			default:
				_bad_scanf();
				break;
			}
		} else if (isspace(*fmt)) {
			// skip spaces in input
			++fmt;
			while (isspace(_peek_char())) _next_char();
		} else {
			if (_peek_char() == *fmt) {
				// format character matches input character
				++fmt;
				_next_char();
			} else {
				// format character doesn't match input character; stop parsing
				break;
			}
		}
	}
	vscanf_done:
	if (_peek_char() == terminator && assignments == 0) return EOF;
	return assignments;
	#undef _next_char
	#undef _peek_char
}

int fscanf(FILE *stream, const char *format, ...) {
	va_list args;
	va_start(args, format);
	int ret = _vscanf(_file_next_char, _file_peek_char, EOF, stream, format, args);
	va_end(args);
	return ret;
}

int sscanf(const char *s, const char *format, ...) {
	va_list args;
	va_start(args, format);
	int ret = _vscanf(_str_next_char, _str_peek_char, 0, &s, format, args);
	va_end(args);
	return ret;
}

int scanf(const char *format, ...) {
	va_list args;
	va_start(args, format);
	int ret = _vscanf(_file_next_char, _file_peek_char, EOF, stdin, format, args);
	va_end(args);
	return ret;	
}


void perror(const char *s); // @TODO

#undef STB_SPRINTF_MIN

#endif // _STDIO_H
