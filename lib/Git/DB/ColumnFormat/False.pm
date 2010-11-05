
package Git::DB::ColumnFormat::False;

use Moose;

use Git::DB::Defines qw(ENCODING_FALSE);

sub type_num { ENCODING_FALSE };

sub write_col {
	die "value true" if $_[2];
}

sub read_col {
	return "";
}

with 'Git::DB::ColumnFormat';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::False - Encode a false value.

=head1 DESCRIPTION

Compact represenation of a false boolean value.  See
L<Git::DB::ColumnFormat::Boolean>.  For perl, due to long-standing
Boolean convention this is always restored as ''.

=cut

