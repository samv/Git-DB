
package Git::DB::ColumnFormat::Rational;

use Mouse;

use Git::DB::Encode qw(encode_int read_int encode_uint read_uint);

sub type_num { 4 };

use Math::BigRat try => 'GMP';

sub to_row {
	my $inv = shift;
	my $rat = shift;
	if ( blessed $rat ) {
		encode_int( $rat->numerator ),
			encode_uint( $rat->denominator );
	}
	else {
		die "must be passed blessed objects for Rational";
	}
}

sub read_col {
	my $inv = shift;
	my $data = shift;
	my $numerator = read_int($data);
	my $denominator = read_uint($data);
	Math::BigRat->new("$numerator / $denominator");
}

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::Rational - Precise Rational type

=head1 SYNOPSIS



=head1 DESCRIPTION

A representation to allow for precise representation

=cut

