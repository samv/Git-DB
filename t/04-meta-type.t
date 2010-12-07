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
		dump => [ "dump_word" => sub { print $_[0] } ],
		print => [ "print_word" => sub { print $_[0] } ],
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
		dump => [ "dump_sentence" => sub { print $_[0] } ],
		print => [ "print_sentence" => sub { print $_[0] } ],
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

#BEGIN { use_ok("Git::DB::Type::Basic") }
