
package Git::DB::ColumnFormat::Boolean;

use Mouse::Role;

sub type_class {
	my $inv = shift;
	my $data = shift;
	$data ? "Git::DB::ColumnFormat::True" : "Git::DB::ColumnType::False";
}

with 'Git::DB::ColumnFormat';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::Boolean - Compact boolean representation

=head1 DESCRIPTION

This type is actually a role; there are two types, one for true and
one for false.  This allows boolean columns to be encoded as single
bytes.

=cut

