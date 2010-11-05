
package Git::DB::ColumnFormat::Decimal;

use Moose;

use Git::DB::Encode qw(encode_int read_int);
use Git::DB::Defines qw(ENCODING_DECIMAL);

sub type_num { ENCODING_DECIMAL };

sub write_col {
	my $self = shift;
	my $io = shift;
	my $num = shift;
	# just stringify
	$num="$num";
	($num =~ s{e\+?(-?\d+)}{});
	my $scale = $1 || 0;
	$num =~ s{^(-?\d+)(?:\.(\d+))?$}{$1$2};
	$scale -= length $2 if defined $2;
	print { $io } encode_int($scale), encode_int($num);
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
	my $io = shift;
	my $scale = read_int($io);
	my $value = read_int($io);
	$value*_pow10($scale)
}

with 'Git::DB::ColumnFormat';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::Decimal - Decimal representation

=head1 SYNOPSIS



=head1 DESCRIPTION

A column format to allow for precise representation of numbers using
fixed precision, eg money types.

=cut

