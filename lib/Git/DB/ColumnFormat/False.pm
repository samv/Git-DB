
package Git::DB::ColumnFormat::False;

use Moose;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnFormat::Boolean';

sub type_num { 8 };

method to_row( Bool $data ) {
	die if $data;
}

method read_col( IO::Handle $data ) {
	0;
}

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::False - Encode a false value.

=head1 DESCRIPTION

Compact represenation of a false boolean value.  See
L<Git::DB::ColumnFormat::False>.  This is always restored as '0'.

=cut

