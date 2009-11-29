
package Git::DB::ColumnFormat::Boolean;

use Moose::Role;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnFormat';

method type_class( Bool $data ) {
	$data ? "Git::DB::ColumnFormat::True" : "Git::DB::ColumnType::False";
}

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::Boolean - Compact boolean representation

=head1 DESCRIPTION

This type is actually a role; there are two types, one for true and
one for false.  This allows a boolean column to be encoded as a single
byte.

=cut

