
package Git::DB::ColumnFormat::Null;

use Moose;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnFormat';

use Git::DB::RowFormat qw(BER read_BER)

sub type_num { 5 };

method to_row( $data ) {
	die if defined($data);
}

method read_col( IO::Handle $data ) {
	undef;
}

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::Null - Encode a NULL

=head1 DESCRIPTION

A representation to allow for explicit representation of a NULL
column.

This is intended for when joining two streams using the "reset row
counter" column meta-type.

=cut

