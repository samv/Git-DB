#!/usr/bin/perl
#
# the Git::DB::Class

use Test::More no_plan;
use strict;
use warnings;

use t::Mock;
use t::TestEncoder qw(perl_print_string);

BEGIN { use_ok("Git::DB::Class") }

use Git::DB::Type qw(get_type);
use Git::DB::Type::Basic;
use Git::DB::Attr;
use Git::DB::Key;
use Storable qw(dclone);

my @attr = map { Git::DB::Attr->new( @$_ ) }
	[
		name => "code",
		type => get_type("text"),
	],
	[
		name => "description",
		type => get_type("text"),
	],
	;
my @rattr = reverse map { dclone $_ } @attr;

my $key = Git::DB::Key->new(
	name => "someclass_pkey",
	unique => 1,
	primary => 1,
	type => get_type("text"),
	attr => [ $attr[0] ],
);

my $class = Git::DB::Class->new(
	name => "someclass",
	attr => \@attr,
	primary_key => $key,
);

is($attr[0]->index, 0, "attr_index [1/2]");
is($attr[1]->index, 1, "attr_index [2/2]");

is($key->class, $class, "BUILD : backrefs linked");

my $object = bless {
	code => "abc",
	description => "Easy as",
}, "someclass";
my $encoded = join "", $class->encode_object($object, $key->chain);

is(perl_print_string($encoded),
   perl_print_string("\002\003abc\002\007Easy as"),
   "encode_object (simple)");

$key = Git::DB::Key->new(
	name => "someclass_pkey",
	unique => 1,
	primary => 1,
	type => get_type("text"),
	attr => [ $rattr[1] ],
);
my $class2 = Git::DB::Class->new(
	name => "someclass",
	attr => \@rattr,
	primary_key => $key,
);

$encoded = join "", $class2->encode_object($object);

is(perl_print_string($encoded),
   perl_print_string("\022\003abc\x{62}\007Easy as"),
   "encode_object (check primary key columns encode first)");

#TODO: read_object
