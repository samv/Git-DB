
package Git::DB::ColumnFormat::String;

use Moose;

use Git::DB::Encode qw(encode_uint read_uint);

use Git::DB::Defines qw(ENCODE_STRING);

sub type_num { ENCODE_STRING };

use bytes;

sub write_col {
	my $inv = shift;
	my $io = shift;
	my $data = shift;
	print { $io } encode_uint(length($data)), $data;
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

Git::DB::ColumnFormat::String - implement string column format

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

