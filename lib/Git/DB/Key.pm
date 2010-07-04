
package Git::DB::Key;

use Mouse;

# what do we know about a key?

# it belongs to a class
has 'class' =>
	is => "ro",
	isa => "Git::DB::Class",
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

# it may or may not be "primary"; for us that probably implies that is
# the key that is how the table is accessed.
has 'primary' =>
	is => "ro",
	isa => "Bool",
	;

# If a Key is stored, then it must be stored in the schema.  This
# makes distributed data merging faster at the expense of a larger
# transmitted data set.
has 'stored' =>
	is => "ro",
	isa => "Bool",
	;

# if "primary" is set, then the data in the rows is the row data: any
# un-normalised data eg JSON, plus any normalised columns.

# if "primary" is not set, then the data in the rows are the primary
# key columns of the row that it refers to.

# whether or not this key also applies to inherited tables.  Postgres
# doesn't do this.  When used on a primary key it implies the ability
# to do polymorphic retrieval.
has 'heritable' =>
	is => "ro",
	isa => "Bool",
	;

# 'inherits' implies that the row data includes the class of object in
# the store.  This can be a simple Int;

# it may or may not have a predicate... later.
# has 'predicate' =>
#      is => "ro",
#      isa => "Git::DB::Expr",
#      ;

# a key has an ordered list of normalized data components / attributes
has 'attr' =>
	is => "ro",
	isa => "ArrayRef[Git::DB::Attr]",
	;

# which might map to attributes in another table, if this is a foreign
# key.  We might also do this by constraint name, not column number.
has 'foreign_attr' =>
	is => "ro",
	isa => "ArrayRef[Git::DB::Attr]",
	;

1;
