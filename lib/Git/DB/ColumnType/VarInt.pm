
package Git::DB::ColumnType::VarInt;

use Moose;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnType';

use Git::DB::RowFormat qw(BER read_BER)

sub type_num { 0 };

method to_row( $data ) {
	return BER(int(0+$data));
}

method read_col( IO::Handle $data ) {
	read_BER($data);
}

1;

__END__

=head1 NAME

Git::DB::ColumnType::VarInt - Variable-length BER int

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

