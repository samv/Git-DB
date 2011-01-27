#!/usr/bin/perl
#
# the Git::DB::Key and Git::DB::Key::Chain classes

use Test::More no_plan;
use strict;
use warnings;

use t::Mock;

BEGIN { use_ok("Git::DB::Key") }

use Git::DB::Type qw(get_type);
use Git::DB::Type::Basic;
use Git::DB::Attr;

my $class = Mock::Git::DB::Class->new();

my @attr = map { Git::DB::Attr->new( { class => $class, @$_ }) }
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
	class => $class,
	name => "someclass_pkey",
	unique => 1,
	primary => 1,
	type => get_type("text"),
	attr => [ $attr[0] ],
);
ok($key, "made a simple, single-column primary key");

my $chain = $key->chain;
ok($chain, "it has a 'chain'");
ok(!$chain->next, "no 'next' link in chain");

is($chain->scan_func->("hello"), "hello", "key 'chain' scan func");
is($chain->print_func->("hello"), "hello", "key 'chain' print func");

is($chain->cmp_func->("hello", "hi"), -1, "key 'chain' cmp func (lt)");
is($chain->cmp_func->("hi", "hi"), 0, "key 'chain' cmp func (eq)");
is($chain->cmp_func->("hi", "hello"), 1, "key 'chain' cmp func (gt)");
