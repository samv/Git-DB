#!/usr/bin/perl
#
# tests Git::DB::Type

use Test::More no_plan;
use strict;
use warnings;

BEGIN { use_ok("Git::DB::Type", ":all") }

# check that types can be registered
register_type(
	"word" => {
		formats => 0b100,
		read => [ "read_word" => sub { $_[0] } ],
		dump => [ "dump_word" => sub { $_[0] } ],
		print => [ "print_word" => sub { $_[0] } ],
		scan => [ "scan_word" => sub { $_[0] } ],
		cmp => [ "cmp_word" => sub { $_[0] cmp $_[1] } ],
	},
);

no warnings 'once';
ok($Git::DB::Type::VALID_TYPES{"word"}, "defined the type OK");

my $word = Git::DB::Type->new(
	type_formats => 0b100,
	type_name => "word",
);
is($word->scan_func, "scan_word", "naming the type is enough");

register_type(
	"sentence" => {
		formats => 0b101,
		read => [ "read_sentence" => sub { $_[0] } ],
		dump => [ "dump_sentence" => sub { $_[0] } ],
		print => [ "print_sentence" => sub { $_[0] } ],
		scan => [ "scan_sentence" => sub { $_[0] } ],
		cmp => [ "cmp_sentence" => sub { $_[0] cmp $_[1] } ],
	},
);

ok($word, "made a type matching a defined type OK");

ok(!eval {
	Git::DB::Type->new(
		type_name => "word",
		type_formats => 0b100,
		print_func => "print_sentence",
		cmp_func => "cmp_word",
	);
}, "can't make a type with an illegal func");

ok(!eval {
	Git::DB::Type->new(
		type_name => "word",
		type_formats => 0,
	);
}, "can't make an type with no formats");

ok(!eval {
	Git::DB::Type->new(
		type_name => "word",
		type_formats => 0b101,
	);
}, "can't make an ambiguously marshalled type");

ok(!eval {
	Git::DB::Type->new(
		type_name => "word",
		type_formats => 0b010,
	);
}, "can't use unknown type formats");
like($@, qr/can't do format 1\b/, "correct error");

use_ok("Git::DB::Type::Basic");

use Git::DB::Defines qw(:encode);

my $bool = Git::DB::Type->new(type_name => "bool");
ok($bool, "bool type");
is($bool->choose(1), ENCODING_TRUE, "is_tf(1)");
is($bool->choose(0), ENCODING_FALSE, "is_tf(0)");
is($bool->choose(''), ENCODING_FALSE, "is_tf('')");
is($bool->choose('0 but true'), ENCODING_TRUE, "is_tf('0 but true')");
is($bool->print(1), 't', "bool - print - true");
is($bool->print(0), 'f', "bool - print - false");
is($bool->scan('t'), 1, "bool - scan - true");
is($bool->scan('f'), '', "bool - scan - false");

my $int = Git::DB::Type->new(type_name => "integer");
ok($int, "int type");
is($int->choose(1), ENCODING_VARINT, "dummy choose() for integer");
is($int->print(1), '1', "integer - print - 1");
is($int->print(0), '0', "integer - print - 0");
is($int->print(-5), '-5', "integer - print - -5");
is($int->scan('1'), 1, "integer - scan - 1");
is($int->scan('0'), 0, "integer - scan - 0");
is($int->scan('-5'), -5, "integer - scan - -5");

my $float = Git::DB::Type->new(type_name => "float");
ok($float, "float type");
is($float->print(1.1), '1.1', "float - print - 1.1");
is($float->scan("1.1"), 1.1, "float - scan - 1e50");
is($float->print(1e50), '1e+50', "float - print - 1e50");
is($float->scan("1e+50"), 1e50, "float - scan - 1e50");

my $decimal = Git::DB::Type->new(type_name => "decimal");
ok($decimal, "decimal type");
my $rat = Git::DB::Type->new(type_name => "rational");
ok($rat, "rational type");
my $num = Git::DB::Type->new(type_name => "numeric");
ok($num, "numeric type");
my $text = Git::DB::Type->new(type_name => "text");
ok($text, "text type");
my $bytes = Git::DB::Type->new(type_name => "bytes");
ok($bytes, "bytes type");
