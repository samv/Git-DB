
package Git::DB::ColumnFormat::Null;

use Moose;
with 'Git::DB::ColumnFormat';

use Git::DB::Defines qw(ENCODING_NULL);

sub type_num { ENCODING_NULL };

sub write_col {
	die "can't use a defined value with a null column format"
		if defined $_[2];
}

sub read_col {
	undef;
}

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::Null - Encode a NULL

=head1 DESCRIPTION

A representation to allow for explicit representation of a NULL
column.

This is intended for when joining two streams using the "reset row
counter" column meta-type.

=cut

