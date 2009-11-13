
package Git::DB::ColumnType::LengthDelimited;

use Moose;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnType';

use Git::DB::RowFormat qw(BER read_BER)

sub type_num { 2 };

method to_row( $data ) {
	return BER(length($data)).$data;
}

method read_col( IO::Handle $data ) {
	my $length = read_BER($data);
	my $data = $data->read($length);
	return $data;
}

1;

__END__

=head1 NAME

Git::DB::ColumnType::LengthDelimited - data store for strings etc

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

