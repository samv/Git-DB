
package Git::DB::Float;

# this package prototypes the float to signed BER int conversion.

#  eg 0

# here's the idea:
#  - convert mantissa and exponent to BER ints
#  - sign of mantissa is stripped
#  - remaining number is real mantissa bits

use strict;
use constant DEBUG => 1;
our $ieee64_bs;
use POSIX qw(ceil);
use Git::DB::Defines qw(:float :encode);

sub intpair_to_float {
	my ($exp, $mant) = @_;
	if ( $mant == 0 ) {
		if ( $exp ) {
			if ( $exp == 1 ) {
				return "inf";
			}
			elsif ( $exp == -1 ) {
				return "-inf";
			}
			else {
				"nan";
			}
		}
		else {
			0;
		}
	}
	else {
		$mant * 2**$exp;
	}
}

sub mant_pow { MANTISSA_2XXBITS/(2**$_[0]) }
use Memoize;
use POSIX qw(floor);
memoize qw(mant_pow);

sub float_to_intpair {
	my $num = 0+shift;
	my $sign = $num < 0;
	$num = abs($num);
	if ( $num == 0 ) {
		return (0, 0);
	}
	elsif ( $num >= "inf" ) {
		return ($sign ? -1 : 1, 0);
	}
	elsif ( $num != $num ) {
		return (2, 0);
	}
	else {
		my $scale = int(log($num) / log(2));
		$num = $num * mant_pow($scale);
		my $exp = int($scale) - MANTISSA_BITS;
		#$num *= 2**(-$exp);
		while ( int($num) != $num ) {
			#print STDERR "Had to make num bigger: $num\n";
			$num *= 2;
			$exp --;
		}

		#this might not work as intended on all number
		#platforms/rounding rules ... FIXME
		while ( floor( ($num+126)/128 ) == int($num/128) ) {
			#print STDERR "Had to make num smaller (bigeven): $num\n";
			$num /= 128;
			$exp += 7;
		}
		while ( int( ($num+1)/2 ) == int($num/2) ) {
			#print STDERR "Had to make num smaller (even): $num\n";
			$num /= 2;
			$exp ++;
		}
		return ($exp, $sign?-$num:$num);
	}
}

use Scalar::Util qw(blessed);

# this is a function which looks at the numeric value passed, and
# tries to pick the best encoding format for it, without actually
# performing the respective encodings.
sub pick_numeric_encoding {
	my $value = shift;
	if ( blessed $value and $value->can("denominator") ) {
		return ENCODING_RATIONAL;
	}
	elsif ( $value == int($value) and $value < MAX_NV_INT ) {
		if ( !$value ) {
			return ENCODING_VARINT;
		}
		if ( $value =~ m{0{3,}$} ) {
			return ENCODING_DECIMAL;
		}
		elsif ( int($value/128) == $value/128 ) {
			return ENCODING_FLOAT;
		}
		else {
			return ENCODING_VARINT;
		}
	}
	else {
		my $decimal= "".$value;
		$decimal =~ s{^0+|[\.\-]|0*e.*|0+$}{}g;

		# for some values, such as 65535/128, this still makes
		# a sub-optimal choice, but it does so whilst
		# maintaining precision and values like that are
		# probably still outliers.
		if ( length $value < MANTISSA_PRECISION-2 ) {
			return ENCODING_DECIMAL;
		}
		else {
			return ENCODING_FLOAT;
		}
	}
}

use Sub::Exporter -setup => {
	exports => [qw{float_to_intpair intpair_to_float
		       pick_numeric_encoding}],
};

1;
