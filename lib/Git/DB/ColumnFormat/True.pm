
package Git::DB::ColumnFormat::True;

use Moose;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnFormat::Boolean';

sub type_num { 9 };

method to_row( Bool $data ) {
	die unless $data;
}

method read_col( IO::Handle $data ) {
	1;
}

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::True - Encode a true value.

=head1 DESCRIPTION

Compact represenation of a true boolean value.  See
L<Git::DB::ColumnFormat::Boolean>.  This is always restored as '1'.

=cut

