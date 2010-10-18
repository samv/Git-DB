
/* the foo1 functions: for those happy machines with a bigger int than
 * their mantissa, eg 32-bit + ieee754 float, 64-bit + ieee754 double
 */
int encode_snan1(word_int mantissa, char* buf) {
	int w;
	mantissa += 3;
	w = encode_int(mantissa, buf);
	buf += w;
	*buf = '\0';
	return w+1;
}

#define _write1_special(num, exponent, mantissa, buf, max_exp) (	\
		(exponent == max_exp					\
		 ? (mantissa						\
		    ? (num.ieee_nan.quiet_nan				\
		       ? (*buf="\02\0",2)				\
		       : encode_snan1(num.ieee_nan.mantissa, buf)	\
			    )						\
		    : (num.ieee.negative				\
		       ? (*buf="\177\0",2)				\
		       : (*buf="\1\0",2)				\
			    )						\
			 )						\
		 : 0 )							\
		)
#define _write2_special(num, exponent, mantissa, buf, max_exp) (	\
		(exponent == max_exp					\
		 ? (mantissa						\
		    ? (num.ieee_nan.quiet_nan				\
		       ? (*buf="\02\0",2)				\
		       : encode_snan2(num.ieee_nan.mantissa, buf)	\
			    )						\
		    : (num.ieee.negative				\
		       ? (*buf="\177\0",2)				\
		       : (*buf="\1\0",2)				\
			    )						\
			 )						\
		 : 0 )							\
		)

#define _write_foo_special(num, exponent, mantissa, buf, max_exp, foo) (\
		(exponent == max_exp					\
		 ? (mantissa						\
		    ? (num.ieee_nan.quiet_nan				\
		       ? (*buf="\02\0",2)				\
		       : foo(num.ieee_nan.mantissa, buf)		\
			    )						\
		    : (num.ieee.negative				\
		       ? (*buf="\177\0",2)				\
		       : (*buf="\1\0",2)				\
			    )						\
			 )						\
		 : 0 )							\
		)
#define _write2_special_x(num, exponent, mantissa, buf, max_exp) \
	_write_foo_special(num, exponent, mantissa, buf, max_exp, encode_snan2)
#define _write1_special_x(num, exponent, mantissa, buf, max_exp) \
	_write_foo_special(num, exponent, mantissa, buf, max_exp, encode_snan1)

#define _neg_mant(num, mantissa) (num.ieee.negative ? -mantissa : mantissa)

#define _mant_or_bit(mantissa, exponent, dig) (	\
	exponent ? (mantissa & (1<<dig)) : mantissa	\
	)

int _write1_reduced(word_int exponent, word_int mantissa, char* buf)
{
	int w;
	/* shorten very simple floats (eg small integers and
	   pieces of eighths) */
	while (exponent > 7 && !(mantissa & 0x3f)) {
		mantissa >>= 7;
		exponent -= 7;
	}
	while (!(mantissa & 1)) {
		mantissa >>= 1;
		exponent --;
	}
	/* write exponent first */
	w = encode_int(exponent, buf);
	buf += w;
	/* then the mantissa */
	w += encode_int(mantisa, buf);
	return w;
}

#define _write1_normal(num, exponent, mantissa, buf, dig, bias) (	\
		_write1_reduced(					\
			exponent-bias,					\
			_neg_mant(					\
				num,					\
				_mant_or_bit(				\
					mantissa,			\
					exponent,			\
					dig				\
					)				\
				)					\
			)						\
		)

// machines with bigger native floats should not call this function :)
#if (FLT_MANT_DIG < __WORDSIZE)
int encode_float(float _num, char* buf)
{
	ieee754_float num;
	num.f = _num;

	word_int mantissa = num.ieee.mantissa;
	word_int exponent = num.ieee.exponent;
	int w = _write1_special(num, exponent, mantissa, buf, FLOAT_EXP_MAX);
	if (w)
		return w;

	return _write1_normal(num, exponent, mantissa, buf,
			      FLT_MANT_DIG, IEEE754_FLOAT_BIAS);
}

float decode_float(char* buf)
{
	word_int decode_int
}
#else
#   error No machine has a wordsize smaller than FLT_MANT_DIG, surely?
#endif

#if (DBL_MANT_DIG < __WORDSIZE)
int encode_double(double _num, char* buf)
{
	ieee754_double num;
	num.d = _num;

	word_int mantissa = ((word_int)num.ieee.mantissa0 << 32
			     + num.ieee.mantissa1);
	word_int exponent = num.ieee.exponent;
	int w = _write1_special(num, exponent, mantissa, buf,
				DOUBLE_EXP_MAX);
	if (w)
		return w;

	return _write1_normal(num, exponent, mantissa, buf,
			      DBL_MANT_DIG, IEEE754_DOUBLE_BIAS);
}

ieee_float decode_double(char* buf)
{
	
}
#else
#if (DBL_MANT_DIG < __WORDSIZE*2)
// 'long int' is hopefully big enough...
int encode_snan2(long int mantissa, char* buf) {
	int w;
	mantissa += 3;
	/* argh, we need encode_longint too :) */
	w = encode_longint(mantissa, buf);
	buf += w;
	*buf = '\0';
	return w+1;
}
int encode_double(double _num, char* buf)
{
	ieee754_double num;
	num.d = _num;

	long int mantissa = ((long int)num.ieee.mantissa0 << 32
			     + num.ieee.mantissa1);
	word_int exponent = num.ieee.exponent;
	int w = _write2_special(num, exponent, mantissa, buf, DOUBLE_EXP_MAX);
	if (w)
		return w;

	return _write2_normal(num, exponent, mantissa, buf,
			      DBL_MANT_DIG, IEEE754_DOUBLE_BIAS);
}

/* copied from _write1_reduced */
int _write2_reduced(word_int exponent, long int mantissa, char* buf)
{
	int w;
	/* shorten very simple floats (eg small integers and
	   pieces of eighths) */
	while (exponent > 7 && !(mantissa & 0x3f)) {
		mantissa >>= 7;
		exponent -= 7;
	}
	while (!(mantissa & 1)) {
		mantissa >>= 1;
		exponent --;
	}
	/* write exponent first */
	w = encode_int(exponent, buf);
	buf += w;
	/* then the mantissa */
	w += encode_longint(mantisa, buf);
	return w;
}

#define _write2_normal(num, exponent, mantissa, buf, dig, bias) (	\
		_write2_reduced(					\
			exponent-bias,					\
			_neg_mant(					\
				num,					\
				_mant_or_bit(				\
					mantissa,			\
					exponent,			\
					dig				\
					)				\
				)					\
			)						\
		)

int encode_double(double _num, char* buf)
{
	ieee754_double num;
	num.d = _num;

	long int mantissa = ((long int)num.ieee.mantissa0 << 32
			     + num.ieee.mantissa1);
	word_int exponent = num.ieee.exponent;
	int w = _write2_special(num, exponent, mantissa, buf,
				LONG_DOUBLE_EXP_MAX);
	if (w)
		return w;

	return _write2_normal(num, exponent, mantissa, buf,
			      LDBL_MANT_DIG, IEEE754_LONG_DOUBLE_BIAS);
}

ieee_float decode_double(char* buf)
{
	
}

#else
#   error no double function yet for sorry 16-bit platforms
#endif

#ifdef ENCODE_HAVE_LONG_DOUBLE
#if (LNG_DBL_MANT_DIG <= __WORDSIZE)
int encode_long_double(long double, char* buf)
{
	ieee754_double num;
	num.d = _num;

	word_int mantissa = ((word_int)num.ieee.mantissa0 << 32
			     + num.ieee.mantissa1);
	word_int exponent = num.ieee.exponent;
	int w = _write1_special(num, exponent, mantissa, buf, FLOAT_EXP_MAX);
	if (w)
		return w;

	return _write1_normal(num, exponent, mantissa, buf,
			      FLOAT_MANT_DIG, IEEE754_FLOAT_BIAS);
}

long double decode_long_double(char*)
{

}
#endif
