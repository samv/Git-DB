
package Git::DB::ColumnFormat::True;

use Mouse;

sub type_num { 6 };

sub to_row {
	my $inv = shift;
	my $data = shift;
	die "value not true" unless $data;
	"";
}

sub read_col {
	my $inv = shift;
	my $data = shift;
	return 1;
}

with 'Git::DB::ColumnFormat::Boolean';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::True - Encode a true value.

=head1 DESCRIPTION

Compact represenation of a true boolean value.  See
L<Git::DB::ColumnFormat::Boolean>.  This is always restored as '1'.

=cut

