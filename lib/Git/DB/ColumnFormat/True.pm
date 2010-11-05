
package Git::DB::ColumnFormat::True;

use Moose;

use Git::DB::Defines qw(ENCODING_TRUE);

sub type_num { ENCODING_TRUE };

sub write_col {
	die "value not true" unless $_[2];
}

sub read_col {
	return 1;
}

with 'Git::DB::ColumnFormat';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::True - Encode a true value.

=head1 DESCRIPTION

Compact represenation of a true boolean value.  See
L<Git::DB::ColumnFormat::Boolean>.  This is always restored as '1'.

=cut

