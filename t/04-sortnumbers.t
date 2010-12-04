#!/usr/bin/perl

use Test::More no_plan;
use strict;
use warnings;
use List::Util qw(sum);

BEGIN { use_ok("Git::DB::TreeFormat::SortNumber", ":all"); }

use POSIX qw(ceil);

sub test_n_inserts(&$$) {
	my $generator = shift;
	my $number = shift;
	my $test_name = "n_inserts($number): ".shift;
	my $failed;
	my @tree = (bisect_sort_numbers(undef, undef));
	for ( 1..$number ) {
		my $idx = $generator->(\@tree);
		my $before = $tree[$idx-1] if $idx;
		my $after = $tree[$idx];
		my $new_num = bisect_sort_numbers($before, $after);
		if ( (defined $before and $new_num le $before)
		     or (defined $after and $new_num ge $after) ) {
			fail($test_name);
			diag("bisect_sort_numbers($before, $after) = $new_num");
			#diag("Tree: ".join("\n", @tree));
			$failed++;
			last;
		}
		my $max_len = ceil((log(@tree+1)/log(2)));
		if ( length($new_num) > $max_len ) {
			my $n = @tree + 1;
			#diag("entry ($new_num) too long (n=$n, max=$max_len), rebalancing");
			@tree = balanced_sort_numbers( $n );
			my $last;
			for ( @tree ) {
				if ( defined $last and $last == $_ ) {
					fail("balanced_sort_numbers($n) returned $_ twice");
					return;
				}
				if ( m{^0+$|0$} ) {
					fail("balanced_sort_numbers($n) returned $_");
					return;
				}
				if ( defined $last and $last gt $_ ) {
					fail("balanced_sort_numbers($n) returned $_ after $last");
					return;
				}
			}
			pass("rebalanced tree OK");
		}
		else {
			@tree = ( @tree[0..$idx-1], $new_num, @tree[$idx..$#tree] );
		}
	}
	if ( !$failed ) {
		my @lengths = sort { $a <=> $b } map { length } @tree;
		my $longest = $lengths[-1];
		my $average = sprintf("%.1f", sum( @lengths ) /$number);
		my $median = $lengths[$number>>1];
		pass($test_name);
		diag("Tree size: $number, max: $longest, avg: $average"
			.", median: $median");
		#diag(join("\n",@tree));
	}
}

# particular tests for failed examples...
cmp_ok(bisect_sort_numbers(91,undef), "gt", "91", "bisect_sort_numbers(91,undef)");

test_n_inserts { int(rand(@{$_[0]}+1)) } 1000, "random";
test_n_inserts { 0 } 1000, "beginning";
test_n_inserts { @{$_[0]} } 1000, "end";

my $c;
test_n_inserts { ( $c++ < 50 ? 0 : int(rand(@{$_[0]}+1)) ) }
	1000, "beginning, then random";

test_n_inserts { int(rand(@{$_[0]}+1)) } 20, "random20";
test_n_inserts { int(rand(@{$_[0]}+1)) } 50, "random50";
test_n_inserts { int(rand(@{$_[0]}+1)) } 100, "random100";
test_n_inserts { int(rand(@{$_[0]}+1)) } 200, "random200";
test_n_inserts { int(rand(@{$_[0]}+1)) } 300, "random300";
