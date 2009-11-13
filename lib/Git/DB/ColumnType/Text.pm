
package Git::DB::ColumnType::Text;

use Moose;

extends 'Git::DB::ColumnType::LengthDelimited';

use Encode qw(encode decode);
use utf8 qw(is_utf8);

method to_row( Str $text ) {
	if ( is_utf8($text) ) {
		$self->SUPER::to_row(encode("utf8", $text));
	}
	else {
		$self->SUPER::to_row($text);
	}
};

method read_col( IO::Handle $data ) {
	my $length = read_BER($data);
	my $data = $data->read($length);
	return decode("utf8", $data);
}

1;

__END__

=head1 NAME

Git::DB::ColumnType::Text - type for UTF-8 valid data

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

