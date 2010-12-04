
package Git::DB::TreeFormat::SortNumber;

use strict;
use Sub::Exporter -setup => {
	exports => [qw(bisect_sort_numbers balanced_sort_numbers)],
	};

# the function for generating new sort numbers.
sub bisect_sort_numbers {
	my $num1 = shift;
	my $num2 = shift;

	my $dec = 0;

	# first case: only one number provided, some terminal rules.
	if ( !$num2 ) {
		if ( !$num1 ) {
			# no values at all?  go for 5.
			return 5;
		}
		# must add a new digit...
		elsif ( $num1 =~ /^9+$/ ) {
			# end extension case: add a 5.
			return $num1."5";
		}
		else {
			# otherwise pretend there's an entry at the end.
			$num2 = ("9" x length $num1)."9";
			$dec = 1;
		}
	}
	# a new number at the start..
	if ( !$num1 ) {
		if ( $num1 =~ m{^(0+)1$} ) {
			# beginning extension case: prepend a 0
			return $1."09";
		}
		else {
			# otherwise pretend there's a 0 value..
			$num1 = "0" x length($num2);
			$dec = -1;
		}
	}

	# next case: numbers are different lengths
	if ( length($num1) < length($num2) ) {

		# case where second number is just some extra digits
		# on first number.
		if ( substr($num2, 0, length($num1)) eq $num1 ) {
			return $num1.bisect_sort_numbers(
				undef, substr($num2, length($num1)),
			);
		}
		else {
			# if not, ignore the extra numbers on the
			# second.
			substr($num2, length($num1)) = "";
			$dec = 1;
		}
	}
	elsif ( length($num1) > length($num2) ) {

		# if the first is longer than the second, then the
		# second can't be a substring of the first, because
		# that would be out of order.  but we still have a
		# similar case if, the second number is the increment
		# of the first.
		if ( substr($num1, 0, length($num2)) + 1 == $num2 ) {
			return substr($num1, 0, length($num2)).
				bisect_sort_numbers(
					substr($num1, length($num2)),
					undef,
				);
		}
		else {
			# otherwise, again we can safely ignore the
			# extra numbers.
			substr($num1, length($num2)) = "";
			$dec = 1;
		}
	}

	# otherwise, bisection is simple: unless the numbers are
	# adjacent.
	if ( $num1 + 1 == $num2 ) {
		return $num1."5";
	}
	else {
		my $result;
		if ( $dec == 1 ) {
			$result = $num1+1;
		}
		elsif ( $dec == -1 ) {
			$result = $num2-1;
		}
		else {
			$result = ($num2+$num1)>>1;
		}
		my $len = length $num1;
		return sprintf("%.${len}d", $result);
	}
}

use POSIX qw(ceil);
sub balanced_sort_numbers {
	my $count = shift;
	my $digits = ceil(log($count*2)/log(10));
	my $frac = 10**$digits / ($count*1.1);  #10% of numbers won't work
	my $fmt = "%.${digits}d";
	my $i;
	return map {
		$i += $frac;
		my $rv = sprintf($fmt, $i);
		if ( $rv =~ m{0$} ) {
			$i = ++$rv;
		}
		$rv;
	     } 1..$count;
}

1;
