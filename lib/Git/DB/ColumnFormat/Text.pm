
package Git::DB::ColumnFormat::Text;

use Mouse;

extends 'Git::DB::ColumnFormat::Bytes';

use Encode qw(encode decode);
use utf8;

around to_row => sub {
	my $orig = shift;
	my $self = shift;
	my $text = shift;
	if ( utf8::is_utf8($text) ) {
		$self->$orig(encode("utf8", $text));
	}
	else {
		$self->$orig($text);
	}
};

around read_col => sub {
	my $orig = shift;
	my $self = shift;
	my $bytes = $self->$orig(shift);
	return decode("utf8", $bytes);
};

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::Text - type for UTF-8 valid data

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

