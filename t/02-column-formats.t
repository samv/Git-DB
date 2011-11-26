#!/usr/bin/perl -w

use strict;
use Test::More qw(no_plan);
use boolean;

# The column format.
use_ok("Git::DB::ColumnFormat", ":all");
ok(defined(&column_format), "exported column_format OK");

# eg, type 0 = BER ints
use_ok("Git::DB::ColumnFormat::VarInt");
my $cf = Git::DB::ColumnFormat::VarInt->new;

use IO::Scalar;
my $buffer = "";
my $io = IO::Scalar->new(\$buffer);

# test emitting; basics on the int type
my $type = $cf->type_num;
is($type, 0, "VarInt: type OK");
$cf->write_col($io, 42);
is(unpack("H*",$buffer), "2a", "VarInt: out OK");

# test reading
my $cf_class = column_format(0);
$buffer = pack("H*", "56");
$io->seek(0,0);
my $val = $cf_class->read_col($io);
is($val, -42, "VarInt: in OK");

require Math::BigRat;

my @TESTS = (
	# type, encoded => value,

	# type=0 => VarInt tests (see 01-encode.t for more tests)
	0, "0x2a"       =>  42,
	0, "0x7f"       =>  -1,
	0, "0xbfffff7f" =>  2**27-1,

	# type=1 => Float tests (see 01-encode.t for more tests)
	1, "0x0000" => 0,
	1, "0x0001" => 1,
	1, "0x0801" => 256,
	1, "0x7f00" => "-inf",
	1, "0x0200" => "nan",

	# type=2 => Bytes tests (see 01-encode.t for more tests)
	2, "0x053132333435" => "12345",
	2, "0x40".("78"x64) => "x" x 64,

	# type=3 => Decimal tests
	3, "0x7f2a" => 4.20,
	3, "0x012a" => 420,
	3, "0x142a" => 42e20,
	3, "0x6c2a" => 42e-20,
	3, "0x7f56" => -4.20,
	3, "0x0156" => -420,
	3, "0x1456" => -42e20,
	3, "0x6c56" => -42e-20,
	3, "0x7e8325" => 4.21,
	3, "0x7b93962f" => 3.14159,
	3, "0x7bece951" => -3.14159,

	# type=4 => Rational tests
	4, "0x7f2a" => Math::BigRat->new("-1/42"),
	4, "0x7b93962f" => Math::BigRat->new("-5/314159"),
	4, "0x81e7e7e3b6a6994ac9e4e8f8f6b331"
		=> Math::BigRat->new("1019514486099146/324521540032945"),

	# type=5,6 => Boolean tests
	5, "" => false,
	6, "" => true,

	# type=7 => LOB tests - later
	#7, "0x14257cc5642cb1a054f08cc83f2d943e56fd3ebe99" => "foo\n",

	# type=9 => NULL test
	9, "", undef,
       );

my %done_type_test = ( 0 => 1 );

while ( my ($type, $encoded, $value) = splice @TESTS, 0, 3 ) {
	my $cf = column_format($type);
	(my $test_name = $cf) =~ s{.*::}{};
	is($cf->type_num, $type, "$test_name: type OK")
		unless $done_type_test{$type}++;

	$test_name .= ": ".($value//"(undef)");
	my $buffer = "";
	my $io = IO::Scalar->new(\$buffer);
	$cf->write_col($io, $value);

	$encoded =~ s{^0x}{};
	is(unpack("H*",$buffer), $encoded, "$test_name: out OK");

	# test reading
	$io->seek(0,0);
	$buffer = pack("H*", $encoded);
	my $read_back = $cf->read_col($io);
	is($read_back, $value, "$test_name: in OK");
}

require t::ShowDeps;
