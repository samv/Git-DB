
package Git::DB::Attr;

use Moose; # -traits => ["NaturalKey", "Constraint"];
use Scalar::Util qw(reftype);

# these are actually backref columns from its relationship with class;
# officially RO
has 'class' =>
	is => "rw",
	isa => "Git::DB::Class",
	writer => "_set_class",
	weak_ref => 1,
	;

has 'index' =>
	is => "ro",
	isa => "Int",
	lazy => 1,
	default => sub {
		my $self = shift;
		my $class = $self->class;
		$class->attr_index($self);
	},
	required => 1,
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
	#coerce => 1,
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

# this might belong in Git::DB::Meta::Attr in principle, but to be
# pragmatic it's probably a useful protocol for associating with
# non-Moose classes, too.

sub get_value {
	my $self = shift;
	my $object = shift;
	my $name = $self->name;
	if ( my $coderef = $object->can("gidb_get_".$name) ) {
		$coderef->($object);
	}
	elsif ( $coderef = $object->can($name) ) {
		$coderef->($object);
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

use Git::DB::Type qw(get_func);

# the 'read' function assumes that we're building a constructor
# argument list.
sub read {
	my $self = shift;
	my $io = shift;
	my $type = shift;
	($self->name => scalar($self->type->read($io, $type)));
}

sub scan {
	my $self = shift;
	
}

BEGIN {
	no strict 'refs';
	# we don't use 'handles' on the type slot, because the
	# functionality is slightly different; foo_func returns the
	# actual coderef, and ->foo() takes the object and gets the
	# value from the slot to pass to the actual function.
	for my $func ( Git::DB::Type::FUNCS ) {
		my $func_func = "${func}_func";
		*$func_func = sub {
			get_func($_[0]->type->$func_func);
		};
		*$func = sub {
			my $self = shift;
			my $object = shift;
			$self->type->$func( $self->get_value($object) );
		}
			unless defined &$func;
	}
}

# pg_attrdef: specifies default values...

1;

__END__

=head1 NAME

Git::DB::Attr - a class(table) attribute(column) in a Git::DB

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

