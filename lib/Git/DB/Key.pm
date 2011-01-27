
package Git::DB::Key;

use Moose;

# what do we know about a key?

# it belongs to a class
has 'class' =>
	is => "rw",
	isa => "Git::DB::Class",
	writer => "_set_class",
	weak_ref => 1,
	;

# it has a unique name (or index, really)
has 'name' =>
	is => "ro",
	isa => "Str",
	;

# use MooseX::NaturalKey;
# natural key => qw(class name);

# it may or may not allow duplicate values; if it doesn't, then it is
# not a constraint on the class it refers to, it is just an index for
# performance.
has 'unique' =>
	is => "ro",
	isa => "Bool",
	;

# if "primary" is set, then the data in the rows is the row data: any
# un-normalised data eg JSON, plus any normalised columns.

# if "primary" is not set, then the data in the rows are the primary
# key columns of the row that it refers to.
has 'primary' =>
	is => "ro",
	isa => "Bool",
	;

# If a Key is stored, then it must be stored in the schema.  This
# makes replication faster at the expense of a larger transmitted data
# set.
has 'stored' =>
	is => "ro",
	isa => "Bool",
	;

# whether or not this key also applies to inherited tables.  Postgres
# doesn't do this.  When used on a primary key it implies the ability
# to do polymorphic retrieval.
has 'heritable' =>
	is => "ro",
	isa => "Bool",
	;

# 'inherits' implies that the row data includes the class of object in
# the store.  This can be a simple Int; it refers to the primary key
# of the class.

# it may or may not have a predicate... later.
# has 'predicate' =>
#      is => "ro",
#      isa => "Git::DB::Expr",
#      ;

# a key has an ordered list of normalized data components / attributes
has 'attr' =>
	is => "ro",
	isa => "ArrayRef[Git::DB::Attr]",
	auto_deref => 1,
	;

has 'chain' =>
	is => "ro",
	isa => "Git::DB::Key::Chain",
	lazy => 1,
	default => \&make_key_chain,
	;

# which might map to attributes in another table, if this is a foreign
# key.  We might also do this by constraint name, not column number.
has 'foreign_attr' =>
	is => "ro",
	isa => "ArrayRef[Git::DB::Attr]",
	;

# returns a linked list of various functions...
use Git::DB::Key::Chain;
sub make_key_chain {
	my $self = shift;
	my $chain;
	for my $attr ( reverse $self->attr ) {
		$chain = Git::DB::Key::Chain->new(
			attr => $attr,
			scan_func => $attr->scan_func,
			print_func => $attr->print_func,
			cmp_func => $attr->cmp_func,
			($chain ? (next => $chain) : ()),
		);
	}
	$chain;
}

1;
