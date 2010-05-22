#!/usr/bin/perl -w

use strict;
use Test::More qw(no_plan);
use lib "t";
use TestEncoder;

# part 1.  Encoding of data types

BEGIN { use_ok("Git::DB::Encode", ":all") }

# this is just a 2's complement form of the BER format used by perl
my $two = Math::BigInt->new(2);
my @TESTS = (
	# some 1 byte values
	"0x00" => 0,
	"0x01" => 1,
	"0x3f" => 63,
	"0x40" => -64,
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
	#"0xff40" => -64,   # could 'reserve' ?

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
	#"0xfe808080808080808000" => -$two**64-1,
       );

test_encoder
	sub { encode_BER($_[0]) },
	sub { decode_BER($_[0]) },
	sub { $_[1] =~ m{e+}i },
	@TESTS,
	"BER ints";

;
