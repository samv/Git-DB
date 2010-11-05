
package Git::DB::ColumnFormat::Rational;

use Moose;

use Git::DB::Encode qw(encode_int read_int encode_uint read_uint);
use Git::DB::Float qw(float_to_intpair);
use Git::DB::Defines qw(ENCODING_RATIONAL);

sub type_num { ENCODING_RATIONAL };

use Math::BigRat try => 'GMP';

sub write_col {
	my $inv = shift;
	my $io = shift;
	my $rat = shift;
	my ($numerator, $denominator);
	if ( blessed $rat and $rat->can("numerator") ) {
		$numerator = $rat->numerator;
		$denominator = $rat->denominator;
	}
	elsif ( int($rat) == $rat ) {
		$numerator = $rat;
		$denominator = 1;
	}
	else {
		my ($scale, $mantissa) = float_to_intpair($rat);
		my ($numerator, $denominator);
		if ( $scale < 0 ) {
			$numerator = $mantissa;
			$denominator = 2**-$scale;
		}
	}
	if ( $denominator < 0 ) {
		$numerator = -$numerator;
		$denominator = -$denominator;
	}
	print { $io } encode_int( $numerator ),
		encode_uint( $denominator );
}

sub read_col {
	my $inv = shift;
	my $data = shift;
	my $numerator = read_int($data);
	my $denominator = read_uint($data);
	if ( $denominator == 1 ) {
		return $numerator;
	}
	else {
		Math::BigRat->new("$numerator / $denominator");
	}
}

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::Rational - Precise Rational type

=head1 SYNOPSIS



=head1 DESCRIPTION

A representation to allow for precise representation

=cut

