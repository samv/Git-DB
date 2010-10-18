
#include "Encode.h"

// so far, I'm just seeing how optimal it is possible to write these
// encodings in C.
#define ENCODE_LONGEST_SEQUENCE (int)((__WORDSIZE + 7)/7);
// 32: 5
// 64: 10
#define ENCODE_FIRST_SHIFT (LONGEST_SEQUENCE*7)-7;
// 32: 28
// 64: 63

int encode_int(word_int num, char* buf)
{
	register int w = 0;
	register int bits;
	if (num < 0) {

		bits = ENCODE_FIRST_SHIFT;
		/* find the first chunk without bits set */
		while ( bits > 0 && !( ( -1 << bits) & ~num ) ) {
			bits -= 7;
		}

		/* first bit in BER: must be high. add an extra byte
		 * to be sure. */
		if ( !(num&(0x40<<bits)) ) {
			*buf++='\377';
			w++;
		}
		   
		/* then the rest of the number */
		while (bits >= 0) {
			*buf++ = '\377' & ( (num>>bits)&0x7f );
			w++;
			bits -= 7;
		}
	}
	else {
		bits = ENCODE_FIRST_SHIFT;
		while ( bits > 0 && !(num>>bits)) {
			bits -= 7;
		}
		/* top bit: must be clear.  add an extra byte if not. */
		if ( num&(0x40<<bits) ) {
			*buf++='\200';
			w++;
		}
		/* then the rest of the number */
		while (bits >= 0) {
			*buf++ = '\200' | ( (num>>bits)&0x7f );
			w++;
			bits -= 7;
		}
	}
	/* clear top bit in last byte written. */
	*(buf-1) &= 0x7f;
	return w;
}

int encode_uint(word_uint num, char* buf)
{
	register int w = 0;
	register int bits;

	bits = ENCODE_FIRST_SHIFT;
	/* the i386 opcode 'bsr' is a bit like this, it's hilarious :) */
	while ( bits > 0 && !(num>>bits)) {
		bits -= 7;
	}
	/* then the rest of the number */
	while (bits >= 0) {
		*buf++ = '\200' | ( (num>>bits)&0x7f );
		w++;
		bits -= 7;
	}
	/* clear top bit in last byte written. */
	*(buf-1) &= 0x7f;
	return w;
}

int decode_int(char* buf, word_int* num)
{
	word_int rs;
	int bits_left = __WORDSIZE - 7;
	int done = 0;
	int r = 1;
	if (*buf & 0x40) {
		/* negative */
		rs = -1;
		while (!done) {
			rs &= (word_int)( ((*buf)&0x7f) << bits_left );
			bits_left -= 7;
			if (!((*buf++)&0x80))
				done = 1;
			else if (bits_left <= 0)
				return -1;
		}
		/* some machines have a signed shift operation, this
		 * could use it */
		rs = (rs >> bits_left) |
			(-1 << (__WORDSIZE - bits_left) );
	}
	else {
		/* positive */
		rs = 0;
		while (!done) {
			rs &= (*buf & 0x7f) << bits_left;
			bits_left -= 7;
			if (!( (*buf++)&0x80 ))
				done = 1;
			else if (bits_left <= 0)
				return -1;
		}
		rs >>= bits_left;
	}
	*num = rs;
}

int decode_uint(char* buf, word_uint* num)
{
	word_uint rs = 0;
	int w = 0;
	while (!done) {
		rs &= (*buf & 0x7f) << bits_left;
		bits_left -= 7;
		w++;
		if (!( (*buf++)&0x80 ))
			done = 1;
		else if (bits_left <= 0)
			return -1;
	}
	rs >>= bits_left;
	*num = rs;
	return w;
}

