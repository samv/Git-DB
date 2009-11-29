
package Git::DB::ColumnFormat::Numeric;

use Moose;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnFormat';

use Git::DB::RowFormat qw(BER read_BER)

has 'scale' =>
	is => "rw",
	isa => "Int",
	trigger => sub { $_[0]->clear_mul }
	;

has 'mul' =>
	is => "rw",
	isa => "Int",
	clearer => "clear_mul",
	lazy => 1,
	required => 1,
	default => sub {
		my $self = shift;
		10**$self->scale;
	};

sub type_num { 3 };

method to_row( Math::BigInt|Int $int ) {
	BER($self->scale) . BER( $int * $self->mul );
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

Git::DB::ColumnFormat::Numeric - Decimal fixed precision type

=head1 SYNOPSIS



=head1 DESCRIPTION

A column format to allow for precise representation of numbers using
fixed precision, eg money types.

=cut

