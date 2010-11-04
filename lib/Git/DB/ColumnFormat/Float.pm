
package Git::DB::ColumnFormat::Float;

use Moose;

use Git::DB::Encode qw(encode_float read_float);

use Git::DB::Defines qw(ENCODE_FLOAT);

sub type_num { ENCODE_FLOAT };

sub write_col {
	my $inv = shift;
	my $io = shift;
	my $data = shift;
	print {$io} encode_float($data);
}

sub read_col {
	my $inv = shift;
	my $io = shift;
	return read_float($io);
}

with 'Git::DB::ColumnFormat';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::Float - Variable-length ieee-convertible float

=head1 SYNOPSIS



=head1 DESCRIPTION

Floating point values are stored as pairs of signed ints (M, N) like
the other Numeric representation types.  The float is derived using
C<M * 2^N>.  Going the other way is more like

  M = X * 2**(int(log(X)/log(2)) + W)
  N = int(log(X)/log(2)) - W

Where W is the number of mantissa bits you are interested in storing.
M should never be even, except for 0 - if it is, you can reduce M and
N.

ieee754 was considered for representation but is less suitable; while
endian-ness issues can be worked around, it is fixed length (typically
6-12 or even 16 bytes).  ieee754 is a great fixed width format and
math system for processors, squeezing every last bit of precision out
of available space in the machine word.

The problem is that trying to keep things native as machines and
floating point precision changes; this approach still keeps the
usually expected level of precision (ie, only losing the last two bits
or so of mantissa) and is far more interoperable between different
machines, and much easier to understand.

As you can see above, the conversion can be performed accurately in
relatively few operations with standard ieee754 math if required.

Other implementations will choose to extract float fields directly
from the native representation used by the platform and pack them into
the target fields, an operation which can potentially be performed
without using the FPU (on some platforms such as Niagara, this is
important).

In the "normalized" form, the column specification will list the
maximum size of the mantissa (W above) in bits, and sub-infinities.

"Special" ieee754-2008 values, such as infinities, quiet and
signalling NaN's are represented with a mantissa of 0 and an exponent
other than 0.

"Subnormal" numbers do not need special handling with this approach;
they will be packed and unpacked transparently.  The only thing
relatively unusual about them is that their mantissas will be small
and their exponents high and negative.

Below is a table showing various ieee754 sizes and how large typical
values pack to in this format; though unless you are pushing the range
of your float type they would normally just be one or two bytes more
than the original size.

   Name       Common Name            Size   BER int size range
  binary16    half precision         2 bytes    2-3 bytes
  binary32    single precision       4 bytes    2-6 bytes
  binary64    double precision       8 bytes    2-11 bytes
  8087-80     "extended precision"  10 bytes    2-12 bytes
  binary128   quadruple precision   16 bytes    2-19 bytes

Of course, only numbers which are "round numbers" in binary, like 192,
0.125 and 16777216 will get the most compact end of the size range
regardless of the native float format.

For example, 0.2 (base 10) in binary will be a recurring number
expressed in binary (0.001100110011...) and cannot be converted
exactly to an integer times a power of two.

205 * 2^-10, the closest representation available in ieee16, is
already 0.200 - not bad for 16 bits.  In this format, at the same
precision, you're looking at 3 bytes.

3355443 * 2^-24, for ieee32, is already 5 bytes.  Only one more than
the original, and so long as the mantissa is expressable in 7 bits or
fewer, this will remain the case.  Values near the edge of the ieee32
range will be pushed out to the worst case, 6 bytes.

For double precision, which most machines will use, 3602879701896397 *
2^-54, at 9 bytes, again is only one byte larger than the ieee64
original, though it doesn't take much to push this one to 10 bytes
(eg, 0.0001 is 10 bytes).

For the die-hard 8087 80-bit format, 3689348814741910323 * 2^-64, at
10 bytes, is actually the same size as the original float, but the
worst case is more like 12 bytes.

1038459371706965525706099265844019 * 2^-112, for ieee128, is only two
more than the ieee format at 18 bytes, but this type could be as much
as 19 bytes for really huge numbers.

If it is being stored from a machine with a larger or smaller floating
point word size, it will end up as a different fraction, but be very
close.

There are better numeric representations for 0.2, such as the decimal
or rational types, both of which would encode this value with 2 bytes.
For things like monetary types, this approach is much preferrable.
