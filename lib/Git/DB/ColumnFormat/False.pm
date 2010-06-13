
package Git::DB::ColumnFormat::False;

use Mouse;

sub type_num { 5 };

sub to_row {
	my $inv = shift;
	my $data = shift;
	die "value true" if $data;
	"";
}

sub read_col {
	my $inv = shift;
	my $data = shift;
	return "";
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

