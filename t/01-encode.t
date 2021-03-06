#!/usr/bin/perl -w

use strict;
BEGIN { binmode STDOUT, ":utf8"; };
use Test::More qw(no_plan);
use t::TestEncoder;

# part 1.  Encoding of data types

BEGIN { use_ok("Git::DB::Encode", ":all") }

# 1a. signed integers.
#
#   As well as actual integers, for types like rationals, and many
#   parts of the row format where an integer is called for, this is
#   used.
#
#   this is just a 2's complement form of the BER format used by perl
#   Testing strategy is to test key values around various boundaries -
#   in terms of bit size, and encoded size, to demonstrate the
#   "capacity" of the format and catch some foreseeable edge cases.
#
#   Later, a C version of this should be able to unpack most numbers
#   near the word size in a very small number of cycles on a
#   well-registered, pipelining and multiple execution unit processor,
#   perhaps one cycle per byte or less. Also, we should be able to
#   encode directly to BigInt-style objects without a decimal stage.

my $two = Math::BigInt->new(2);
my @TESTS = (
	# some 1 byte values
	"0x00" => 0,
	"0x01" => 1,
	"0x02" => 2,
	# ...
	"0x3d" => 61,
	"0x3e" => 62,
	"0x3f" => 63,
	# ...
	"0x40" => -64,
	"0x41" => -63,
	"0x42" => -62,
	# ...
	"0x7d" => -3,
	"0x7e" => -2,
	"0x7f" => -1,

	# some 2 byte values
	"0x8040" => 64,
	"0x8041" => 65,
	"0x8100" => 128,
	"0xbf7f" => 8191,
	"0xc000" => -8192,
	"0xfd00" => -384,
	"0xfe00" => -256,
	"0xfe1f" => -256+31,  #-225
	"0xfe3f" => -256+63,  #-193
	"0xfe7f" => -256+127,  #-129
	"0xff00" => -128,
	"0xff01" => -127,
	"0xff3f" => -65,

	#"0x803f" => 63,   # could 'reserve' ?
	#"0x803e" => 62,   # could 'reserve' ?
	#"0x803d" => 61,   # could 'reserve' ?
	#"0xff40" => -64,   # could 'reserve' ?
	#"0xff41" => -63,   # could 'reserve' ?
	#"0xff42" => -62,   # could 'reserve' ?

	"0xece951" => "-314159",

	# largest 4-byte values
	"0xbfffff7f" => 2**27-1,
	"0xc0808000" => -2**27,

	# next values
	"0x80c0808000" => 2**27,
	"0xffbfffff7f" => -2**27-1,

	# representing 32-bit signed, unsigned maxes - 5 bytes
	"0x8fffffff7f" => 2**32-1,
	"0xf880808000" => -2**31,

	# 6-7 byte numbers
	"0xbfffffffff7f" => $two**41-1,
	"0x80c08080808000" => $two**41,
	"0xc08080808000" => -$two**41,
	"0xffbfffffffff7f" => -$two**41-1,
	"0xbfffffffffff7f" => $two**48-1,
	"0xc0808080808000" => -$two**48,

	# 8-9 byte numbers
	"0xbfffffffffff7f" => $two**48-1,
	"0x80c0808080808000" => $two**48,
	"0xc0808080808000" => -$two**48,
	"0xffbfffffffffff7f" => -$two**48-1,
	"0x87ffffffffffff7f" => $two**52-1,

	# some 'big' numbers - all work on 64-bit
	"0x8fffffffffffff7f" => (1<<53)-1,
	"0xf080808080808000" => -(1<<53),
	"0x8fffffffffffff7f" => $two**53-1,
	"0xf080808080808000" => -$two**53,

	"0xbfffffffffffff7f" => (1<<55)-1,
	"0xc080808080808000" => -(1<<55),

	# we run out of mantissa here, and so pack("w", $BigNum) will
	# fail.  That's all good, we can use pack("w", "$BigNum")
	"0xbfffffffffffff7f" => ($two**55)-1,
	"0xc080808080808000" => -($two**55),

	"0x80ffffffffffffff7f" => (1<<56)-1,
	"0xff8080808080808000" => -(1<<56),

	"0x81ffffffffffffff7f" => (1<<57)-1,
	"0xfe8080808080808000" => -(1<<57),

	"0x83ffffffffffffff7f" => (1<<58)-1,
	"0xfc8080808080808000" => -(1<<58),

	"0x87ffffffffffffff7f" => (1<<59)-1,
	"0xf88080808080808000" => -(1<<59),

	"0x8fffffffffffffff7f" => (1<<60)-1,
	"0xf08080808080808000" => -(1<<60),

	"0x8fffffffffffffff7f" => ($two**60)-1,
	"0xf08080808080808000" => -($two**60),

	"0x9fffffffffffffff7f" => (1<<61)-1,
	"0xe08080808080808000" => -(1<<61),

	"0xbfffffffffffffff7f" => (1<<62)-1,
	"0xc08080808080808000" => -(1<<62),

	# signed 64-bit maxes
	"0x80ffffffffffffffff7f" => (1<<63)-1,
	"0xff808080808080808000" => -(1<<63),

	# unsigned big numbers and maxes (64 bit)
	"0x81808080808080808000" => (1<<63),
	"0x81808080808080808000" => $two**63,
	"0x81808080808080808001" => (1<<63)+1,
	"0x81808080808080808001" => $two**63+1,
	"0x81ffffffffffffffff7f" => (1<<63)-1+(1<<63),
	"0x81ffffffffffffffff7f" => $two**64-1,

	#"0xff8080808080808000" => -(1<<56),

	# >64-bit numbers
	"0x82808080808080808000" => $two**64,
	"0xfeffffffffffffffff7f" => -$two**63-1,
	"0xfe808080808080808000" => -$two**64,
	"0xfdffffffffffffffff7f" => -$two**64-1,
	"0xfc808080808080808001" => -$two**65+1,
	"0xf88080808080808080808001" => -$two**80+1,

	"0x80ffffffffffffffff7f" => ($two**63)-1,

	# A Mersenne Prime, discovered November 3, 1961 by Hurwitz,
	# using the IBM 7090 (this 1281 bit number is stored in 184
	# bytes - real ASN.1 BER would use 162)
	"0x80".("ff"x(int((1281-7)/7)))."7f" => $two**1281-1,

       );

test_encoder
	sub { encode_int($_[0]) },
	sub { decode_int($_[0]) },
	sub { $_[1] =~ m{e+}i },
	@TESTS,
	"Signed BER ints";

# unsigned version - same as perl BER
@TESTS = (
	# some 1 byte values
	"0x00" => 0,
	"0x01" => 1,
	"0x02" => 2,
	# ...
	"0x3d" => 61,
	"0x3e" => 62,
	"0x3f" => 63,
	# ...
	"0x7d" => 125,
	"0x7e" => 126,
	"0x7f" => 127,
	"0x8100" => 128,
	"0x83ffffffffffff7f" => "2251799813685247",
	"0x8480808080808000" => "2251799813685248",
	"0x8480808080808001" => "2251799813685249",
	"0xffffffffffffffffff7f" => $two**70-1,
       );

test_encoder
	sub { encode_uint($_[0]) },
	sub { decode_uint($_[0]) },
	sub { $_[1] =~ m{e+}i },
	@TESTS,
	"Unsigned BER ints";

# Sam's signed BER float format - re-use signed variable length int
# format above, then (E, M):
#   0 * 2^E =>
#      E =  0 : 0
#      E =  1 : inf
#      E = -1 : inf
#      E =  2 : nan
#      E =  3+ : sig. nan (payload has 3 added to it)
#   M * 2^E => regular number
# subnormals are not required to be supported - the mantissa just
# gets smaller.
use Git::DB::Defines qw(:all);
@TESTS = (
	# specials - mantissa = 0
	"0x0000" => 0,
	"0x0100" => "inf",
	"0x0200" => "nan",
	"0x7f00" => "-inf",

	# normal numbers
	"0x0001" => 1,
	"0x0101" => 2,
	"0x0003" => 3,
	"0x0101" => 2,
	"0x0201" => 4,
	"0x0301" => 8,
	"0x0401" => 16,
	"0x0501" => 32,
	"0x0601" => 64,
	"0x0701" => 128,
	"0x0801" => 256,
	"0x008201" => 257,

	# negative
	"0x007f" => -1,
	"0x057f" => -32,
	"0x057d" => -96,
	"0x057b" => -160,

	# test a few pieces of eighth
	"0x7f01" => 0.5,
	"0x7f7f" => -0.5,
	"0x7e01" => 0.25,
	"0x7e7f" => -0.25,
	"0x7e7f" => -0.25,
	"0x7601" => 0.0009765625,
	"0x767f" => -0.0009765625,

	# stuff what might reasonably be in ints
	"0x1001" => 2**(16),
	"0x2001" => 2**(32),
	"0x3001" => 2**(48),
	"0x3f01" => 2**(63),
	"0x4001" => 2**(-64),
	"0x5001" => 2**(-48),
	"0x6001" => 2**(-32),
	"0x7001" => 2**(-16),

	# stuff what probably isn't on today's computers, but even if
	# NV is plain float then should be representable.
	"0x804001" => 2**(64),
	"0xff3f01" => 2**(-65),
	"0x806001" => 2**(96),
	"0x807f01" => 2**(127),
	"0xff2001" => 2**(-96),
	"0xff0101" => 2**(-127),

       );

diag("mantissa bits: ".MANTISSA_BITS.", int bits: ".INT_BITS);
diag("max_nv_int is: ".MAX_NV_INT.", mantissa_2xxbits: ".MANTISSA_2XXBITS);

if ( MANTISSA_BITS == 53 ) {
	# ieee64 systems.  Test some decimals.
	push @TESTS, (
		# the example in the encode doc
		"4a86b399cce6b3994d" => 0.2,

		# other random numbers
		"488fe6d9ffd3faed3f" => 0.123456,
		"48f099a680ac859241" => -0.123456,

		# 0.000976563 is 1/1024 from above, but rounded to 6
		# s.f.
		"4288808088cbc1be41" => 0.000976563,

		# round down instead - notice the mantissa (4rd hex
		# digit on) rolls around the 1/1024 boundary
		"4287fffff7b4bec13f" => 0.000976562,

		# more noticable with these numbers - these are at the
		# limit of the exact decimal representation.
		"42888080808080834d" => 0.0009765625000001,
		"4287fffffffffffc33" => 0.0009765624999999,

		"438480808080808017" => 0.00097656250000001,

		# this one loses precision, but we're very close to
		# using all of the mantissa up already.
		#"4287ffffffffffff69" => 0.00097656249999999,

		# a google
		"821792a4eba4d9a68d7a" => 10 ** 100,
	       );
}

test_encoder
	sub { encode_float($_[0]) },
	sub { decode_float($_[0]) },
	@TESTS,
	"float format";

# test utf8 strings
use utf8;
@TESTS = (
	"0x00" => "",
	"0x053132333435" => "12345",
	"0x40".("78"x64) => "x" x 64,
	"0x094672616ec3a7616973" => "Français",
	"0x074d61cc846f7269" => "Māori",
	"0x06e4b8ade59c8b" => "中國",
       );

test_encoder
	sub {
		my $x = encode_text($_[0]);
		$x
	},
	sub {
		my $x = decode_text($_[0]);
		$x
	},
	@TESTS,
;
