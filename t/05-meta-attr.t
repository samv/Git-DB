#!/usr/bin/perl
#
# tests Git::DB::Attr

use Test::More no_plan;
use strict;
use warnings;

use t::Mock;

BEGIN { use_ok("Git::DB::Attr") }
use Git::DB::Type qw(get_type);
use Git::DB::Type::Basic;

my $class = Mock::Git::DB::Class->new;

my $attr = Git::DB::Attr->new(
	class => $class,
	name => "blah",
	type => get_type("text"),
);

# all we are concerned with initially is checking that an attribute
# knows how to fetch the value from a slot in an object being
# marshalled

my $simple = bless { "blah" => "xxx" }, "simple";
is( $attr->get_value( $simple ), "xxx", "get_value(simpleobj)" );

{
	package regular;
	sub blah { return $_[0]->{_blah} }
}
my $regular = bless { _blah => "xxy" }, "regular";
is( $attr->get_value( $regular ), "xxy", "get_value() - regular accessor" );

{
	package custom;
	sub blah { return $_[0]->{_blah} }
	sub gidb_get_blah { return "marshalled $_[0]->{_blah}" }
}
my $custom = bless { _blah => "xxz" }, "custom";
is( $attr->get_value( $custom ), "marshalled xxz",
    "get_value() - custom marshaller" );

{
	package moosey;
	use Moose;

	# fixme: this doesn't prove that we didn't just fetch the slot
	# from the HashRef, unless we use an ArrayRef-backed instance
	# type.
	has 'blah' => isa => "Str", accessor => "cheese";
}
my $moosey = moosey->new(blah => "xyx");
is( $attr->get_value( $moosey ), "xyx",
    "get_value() - custom marshaller" );
