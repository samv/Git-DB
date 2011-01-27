#!/usr/bin/perl
#
# the Git::DB::Class

use Test::More no_plan;
use strict;
use warnings;

use t::Mock;

BEGIN { use_ok("Git::DB::Class") }

use Git::DB::Type qw(get_type);
use Git::DB::Type::Basic;
use Git::DB::Attr;
use Git::DB::Key;

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

# TODO: encode_object, read_object
