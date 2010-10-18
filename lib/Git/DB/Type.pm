
package Git::DB::Type;

use Moose;

has 'name' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'formats' =>
	is => "ro",
	isa => "ArrayRef[Bool]",
	default => sub{[]},
	;

has 'dump' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'load' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

1;

__END__

=head1 NAME

Git::DB::Type - Concrete Types in a Data Store

=head1 SYNOPSIS

=head1 DESCRIPTION

A Git::DB::Type describes a column type; roughly corresponding to the
function of the C<pg_types> table in Postgres.  It maps from the types
you use in for a column to the representations used in the row format.

Types are different to Classes, which are more like tables in a
traditional DB sense.  See L<Git::DB::Class> for information on those.
Some day, user-defined types may be classes, in which the value in the
column is a version of that object, and the value in the column on
disk is a nested row of that class.

There are a set of built-in types, and these do not need to be listed
explicitly in the schema section of the store; however, they can be
listed in order to to restrict the column formats for some datatypes,
if desired.

The definition of a type includes:

=over

=item B<name>

I<Str>: the name of the type, eg C<bool>, C<char>, C<varchar>, C<int>,
C<text>, C<uuid>, C<timestamp>, C<interval>, C<money>, C<inet>, etc.
These names will be shamelessly stolen from Postgres where
appropriate.

=item B<formats>

I<Int>: bit-wise map of allowable column formats in the store for this
type.

* format_supported() or db-known conversion functions.

=item B<thaw_format: column_format("type")>

For this type, given the name of a type, return the appropriate Column
Format.

In the schema, this is stored as a mapping from a type name to a
column type (by thaw function)

ColumnFormat
The name of a function which converts a value in your program to a
value in the column.

Using this function, and the function below, you can define truly
custom types - and deliver them using a L<Git::DB::Function> schema
object - but this may tie your application to a particular language or
platform until a standard method for representing functions is
established.

=item B<load>

The name of a function which converts a value in the column to value
in your program.

=back

=cut


1;

