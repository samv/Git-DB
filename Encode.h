
#include <stdint.h>

# define ENCODE_WORD_BITS __WORDSIZE
   
# if __WORDSIZE == 64
typedef int64_t word_int;
typedef uint64_t word_uint;
# else
#   if __WORDSIZE == 32
typedef int32_t word_int;
typedef uint32_t word_uint;
#   else
#     error - strange word size
#   endif
# endif

int encode_int(word_int, char* buf);
int encode_uint(word_uint, char* buf);

word_int decode_int(char*);
word_uint decode_uint(char*);

#include <ieee754.h>
#include <float.h>

#define FLOAT_EXP_MAX (IEEE754_FLOAT_BIAS<<1+1)
#define DOUBLE_EXP_MAX (IEEE754_DOUBLE_BIAS<<1+1)
#define LONG_DOUBLE_EXP_MAX (IEEE754_LONG_DOUBLE_BIAS<<1+1)

# if FLT_MANT_DIG >= 22 && FLT_MANT_DIG <= 24
/* floats on this platform are single precis. */
typedef ieee_float ieee754_float;
# endif

int encode_float(float, char* buf);
float decode_float(char*);

# if FLT_MANT_DIG >= 52 && FLT_MANT_DIG <= 54
    /* floats on this platform are doubles */
typedef float ieee_double;
# else
#   if DBL_MANT_DIG >= 52 && DBL_MANT_DIG <= 54
      /* doubles on this platform are doubles */
typedef double ieee_double;
#   else
typedef ieee754_double ieee_double;
#   endif
# endif

int encode_double(double, char* buf);
double decode_double(char*);

# if FLT_MANT_DIG >= 63 && FLT_MANT_DIG <= 65
    /* floats on this platform are long doubles (ieee854) */
typedef float ieee_long_double;
#   define ENCODE_HAVE_LONG_DOUBLE
# else
#   if DBL_MANT_DIG >= 63 && DBL_MANT_DIG <= 65
      /* doubles on this platform are long doubles */
typedef double ieee_long_double;
#     define ENCODE_HAVE_LONG_DOUBLE
#   else
#     if LDBL_MANT_DIG >= 63 && LDBL_MANT_DIG <= 65
        /* doubles on this platform are long doubles */
typedef long double ieee_long_double;
#       define ENCODE_HAVE_LONG_DOUBLE
#     endif
#   endif
# endif

#ifdef ENCODE_HAVE_LONG_DOUBLE
int encode_long_double(long double, char* buf);
long double decode_long_double(char*);


#endif
