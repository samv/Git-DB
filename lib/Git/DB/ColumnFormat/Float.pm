
package Git::DB::ColumnFormat::Float;

use Moose;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnFormat';

sub type_num { 1 };

method to_row( $data ) {
	return pack("d>", 0+$data);
}

method read_col( IO::Handle $data ) {
	my $float_bin = $data->read(8);
	return unpack("d>", $float_bin);
}

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::VarInt - Variable-length BER int

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

