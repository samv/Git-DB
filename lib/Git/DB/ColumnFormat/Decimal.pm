
package Git::DB::ColumnFormat::Decimal;

use Mouse;

use Git::DB::Encode qw(encode_int read_int);

has 'scale' =>
	is => "rw",
	isa => "Int",
	trigger => sub { $_[0]->clear_mul },
	predicate => "has_scale",
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

sub to_row {
	my $self = shift;
	my $num = shift;
	if ( ref $self and $self->has_scale ) {
		# fixed scale: eg monetary
		my $scale = $self->scale;
		encode_int($scale),
			encode_int( int($num * _pow10($scale)) );
	}
	else {
		# use ieee754 rules by stringifying
		$num="$num";
		$DB::single = 1;
		($num =~ s{e\+?(-?\d+)}{});
		my $scale = $1 || 0;
		$num =~ s{^(-?\d+)(?:\.(\d+))?$}{$1$2};
		$scale -= length $2 if length $2;
		encode_int($scale), encode_int($num);
	}
}

sub _pow10 {
	my $e = shift;
	10 ** $e;
}

use Memoize;
BEGIN {
	memoize "_pow10";
}

sub read_col {
	my $self = shift;
	my $data = shift;
	my $scale = read_int($data);
	my $value = read_int($data);
	$value*_pow10($scale)
}

with 'Git::DB::ColumnFormat';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::Decimal - Decimal fixed precision type

=head1 SYNOPSIS



=head1 DESCRIPTION

A column format to allow for precise representation of numbers using
fixed precision, eg money types.

=cut

