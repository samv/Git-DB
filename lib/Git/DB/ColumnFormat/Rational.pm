
package Git::DB::ColumnFormat::Rational;

use Moose;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnFormat';

use Git::DB::RowFormat qw(BER read_BER)

sub type_num { 4 };

method to_row( Math::BigRat $int ) {
	BER($self->numerator) . BER( $self->denominator );
}

method read_col( IO::Handle $data ) {
	my $scale = read_BER($data);
	my $value = read_BER($data);
	if ( $scale == $self->scale ) {
		$value / $self->mul
	}
	else {
		$value / 10**$scale;
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

