#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;

BEGIN { use_ok("Git::DB::TreeFormat::SortNumber", ":all"); }

sub test_thousand_inserts(&$) {
	my $generator = shift;
	my $test_name = "thousand_inserts: ".shift;
	my $failed;
	my @tree = (bisect_sort_numbers(undef, undef));
	for ( 1..1000 ) {
		my $idx = $generator->(\@tree);
		my $before = $tree[$idx-1] if $idx;
		my $after = $tree[$idx];
		my $new_num = bisect_sort_numbers($before, $after);
		if ( (defined $before and $new_num le $before)
		     or (defined $after and $new_num ge $after) ) {
			fail($test_name);
			diag("bisect_sort_numbers($before, $after) = $new_num");
			diag("Tree: ".join("\n", @tree));
			$failed++;
			last;
		}
		@tree = ( @tree[0..$idx-1], $new_num, @tree[$idx..$#tree] );
	}
	if ( !$failed ) {
		pass($test_name);
		diag("Tree:\n".join("\n", @tree));
	}
}

test_thousand_inserts { int(rand(@{$_[0]}+1)) } "random";
test_thousand_inserts { 0 } "beginning";
test_thousand_inserts { @{$_[0]} } "end";
