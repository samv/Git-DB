
package Git::DB::ColumnFormat::Bytes;

use Mouse;

use Git::DB::Encode qw(encode_uint read_uint);

sub type_num { 2 };

use bytes;

sub to_row {
	my $inv = shift;
	my $data = shift;
	encode_uint(length($data)), $data;
}

sub read_col {
	my $inv = shift;
	my $io = shift;
	my $length = read_uint($io);
	$io->read( my $buf, $length );
	die "short read; expecting $length bytes but read ".length($buf)
		unless length($buf) == $length;
	return $buf;
}

with 'Git::DB::ColumnFormat';
1;

__END__

=head1 NAME

Git::DB::ColumnFormat::LengthDelimited - data store for strings etc

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

