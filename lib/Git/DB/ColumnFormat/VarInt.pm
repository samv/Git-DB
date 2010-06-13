
package Git::DB::ColumnFormat::VarInt;

use Mouse;
use Git::DB::Encode qw(encode_int read_int);

sub type_num { 0 };

sub to_row {
	my $inv = shift;
	my $num = shift;
	return encode_int($num);
}

sub read_col {
	my $inv = shift;
	my $data = shift;
	read_int($data);
}

with 'Git::DB::ColumnFormat';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::VarInt - Variable-length BER int

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

