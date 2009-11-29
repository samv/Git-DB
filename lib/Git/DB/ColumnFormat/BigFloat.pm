
package Git::DB::ColumnFormat::BigFloat;

use Moose;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnFormat';

sub type_num { 6 };

method to_row( $data ) {
	return pack("D>", 0+$data);
}

method read_col( IO::Handle $data ) {
	my $float_bin = $data->read(16);
	return unpack("D>", $float_bin);
}

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::VarInt - Variable-length BER int

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

