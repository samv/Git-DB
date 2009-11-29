
package Git::DB::Column;

has 'type' =>
	is => "ro",
	isa => "Git::DB::Type",
	required => 1,
	;

has 'name' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'index' =>
	is => "rw",
	isa => "Int",
	;

has 'required' =>
	is => "ro",
	isa => "Bool",
	;

1;

__END__

=head1 NAME

Git::DB::Column - a class(table) property(column) in a Git::DB

=head1 SYNOPSIS

 my $column = Git::DB::Column->new(
     type => Git::DB::Type->new( name => "text" ),
     name => "prop_name",
     );

=head1 DESCRIPTION

This schema metaclass represents column attributes.  It roughly
corresponds to the C<pg_attribute> table in Postgres.

=head2 ATTRIBUTES

=over

=item B<name>

The name of the property or column.  Columns are numbered internally -
and numbers are not re-used - but in the schema, the logical names are
mapped to the column numbers.

=item B<type>

This indicates the type of this column, as a C<Git::DB::Type> object.
These are potentially custom types defined in the schema.

=item B<index>

The column number of the column.  A prototype number is automatically
assigned when the column is attached to a L<Git::DB::Class>; this will
be renumbered on connection to an actual database instance.

=item B<required>

Column value may not be 'null'.  Bool, default is false (B<null> may
be present).

=back

=cut

