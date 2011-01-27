
package Git::DB::Class;

# corresponding to pg_class from postgres

use Moose;
#use MooseX::NaturalKey;

has 'schema' =>
	is => "rw",
	isa => "Git::DB::Schema",
	writer => "_set_schema",
	weak_ref => 1,
	;

# the index uniquely identifies the class.  We don't use a UUID or
# something here, because that would be CRAZY HORSES.
has 'index' =>
	is => "ro",
	isa => "Int",
	;

# the unique key of the class is the schema, and index
#natural key => qw(schema index);

# note: the first part of the class is the schema; when a compount
# object forms part of a primary key, this is equivalent to its
# natural key appearing in that point on our primary keys.  This could
# be mapped using an OID, like Postgres does in pg_class - the
# "relnamespace" column on pg_class.  however this requires surrogates
# which are evil and wrong.
has 'primary_key' =>
	is => "ro",
	isa => "Git::DB::Key",
	;

has 'name' =>
	is => "ro",
	isa => "Str",
	;

#use MooseX::UniqueKey;
#unique key => qw(schema name);

# attr for _this_ version
has 'attr' =>
	is => "ro",
	traits => ['Array'],
	isa => "ArrayRef[Maybe[Git::DB::Attr]]",
	# category => "index",
	handles => {
		get_attr => "get",
		num_attr => "count",
	},
	;

# helper method for making attr->index
sub attr_index {
	my $self = shift;
	my $attr = shift;
	my ($i, $num) = (0, $self->num_attr);
	while ( $i < $num ) {
		my $x = $self->get_attr($i);
		if ( $x == $attr ) {
			return $i;
		}
		$i++;
	}
	return undef;
}

sub BUILD {
	my $self = shift;
	my $pkey = $self->primary_key;
	if ( $pkey ) {
		$pkey->_set_class($self);
	}
	my ($i, $num) = (0, $self->num_attr);
	while ( $i < $num ) {
		my $x = $self->get_attr($i);
		$x->_set_class($self);
		$i++;
	}
}

# convert an object to a list of encoded field values
# TODO: not all columns may need to be stored, if the primary key was
# already in the path
sub encode_object {
	my $self = shift;
	my $object = shift;

	my @encoded;
	my $last_col = 0;
	for my $index ( 0 .. $self->num_attr-1 ) {
		my $attr = $self->get_attr($index);
		next if $attr->deleted;
		push @encoded, $attr->encode_value(
			($index - $last_col),
			$attr->fetch_value($object),
		       );
		$last_col = $index;
	}
}

sub read_object {
	my $self = shift;

	
}

1;

__END__

# Meta-y stuff lives below here...

# the Perl Mo[uo]se metaclass
has 'class' =>
	is => "rw",
	isa => "Str",
	#traits => [qw[Git::DB::None]],
	handles => {
		class_name => "name",
	},
	;

# makes the class automatically get a storage layout.
has 'auto_attrs' =>
	is => "ro",
	isa => "Bool",
	#traits => [qw[Git::DB::None]],
	;

no Moose;

# pg_inherits: more like haskell data classes; composes just the data
# type definitions but none of the behaviour (constraints, triggers,
# etc)

1;


__END__

=head1 NAME

Git::DB::Class - represent a class/table in a Git::DB Store

=head1 SYNOPSIS

 # typical use in a meta-programming aware language
 my $class = Git::DB::Class->new(
     class => Some::Class->meta,
     auto_attrs => 1,
     );

 # this is called by Git::DB->connect for you
 $class->migrate_from( $db );

 # Without meta-programming, you'd need to construct a lot
 # of schema stuff by hand.
 my $class = Git::DB::Class->new(
     isa => "Some::Class",
     has => {
         attr1 => Git::DB::Column->new(
             name => "attr1",
             type => "text",
         ),
     },
     );

=head1 DESCRIPTION

A B<Git::DB::Class> object represents a mapping from a Class to a
series of columns.

The principle operation of these objects is to produce a series of
functions which will together "consume" a row.  Similarly, there will
be a series of functions which operate on a list of extracted object
values passed in, and convert them to on-disk form.



=cut

