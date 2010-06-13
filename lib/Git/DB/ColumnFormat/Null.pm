
package Git::DB::ColumnFormat::Null;

use Mouse;
with 'Git::DB::ColumnFormat';

sub type_num { 9 };

sub to_row {
	my $inv = shift;
	my $data = shift;
	die "can't use a defined value with a null column format"
		if defined($data);
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

