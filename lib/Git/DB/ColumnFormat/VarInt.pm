
package Git::DB::ColumnFormat::VarInt;

use Moose;
use Git::DB::Encode qw(encode_int read_int);

use Git::DB::Defines qw(ENCODE_VARINT);

sub type_num { ENCODE_VARINT };

sub write_col {
	my $inv = shift;
	my $io = shift;
	my $num = shift;
	print {$io} encode_int($num);
}

sub read_col {
	my $inv = shift;
	my $io = shift;
	read_int($io);
}

with 'Git::DB::ColumnFormat';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::VarInt - Variable-length BER int

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

