
package Git::DB::Attr;

use Moose; # -traits => ["NaturalKey", "Constraint"];

has 'class' =>
	is => "rw",
	isa => "Git::DB::Class",
	required => 1,
	writer => "_set_class",
	;

# this is actually a backref column from its relationship with class
has 'index' =>
	is => "rw",
	isa => "Int",
	writer => "_set_index",
	;

#__PACKAGE__->meta->keys(qw(class index));
has 'name' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

#__PACKAGE__->meta->unique(qw(class name));
has 'type' =>
	is => "ro",
	isa => "Git::DB::Type",
	coerce => 1,
	required => 1,
	;

has 'required' =>
	is => "ro",
	isa => "Bool",
	;

has 'default' =>
	is => "ro",
	;

has 'deleted' =>
	is => "ro",
	isa => "Bool",
	;

# some types have a scale/length and a precision which can be set.
has 'scale' =>
	is => "ro",
	isa => "Int",
	;

has 'precision' =>
	is => "ro",
	isa => "Int",
	;

sub fetch_value {
	my $self = shift;
	my $object = shift;
	my $name = $self->name;
	if ( my $coderef = $object->can("save_".$name) ) {
		$coderef->($object);
	}
	elsif ( $object->can($name) ) {
		$coderef->$name;
	}
	elsif ( $object->can("meta") and
			$object->meta->has_attribute($name) ) {
		$object->meta->get_attribute($name)->get_value($object);
	}
	elsif ( reftype $object eq "HASH" ) {
		$object->{$name};
	}
	else {
		die "don't know how to fetch $name from $object";
	}
}

sub encode_attr {
	my $self = shift;
	my $rel_index = shift;
	my $value = shift;

	my $type = $self->type;
}

# pg_attrdef: specifies default values...

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

