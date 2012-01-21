
package Git::DB::Schema;

use Moose; # -traits => ["NaturalKey"]

# the URI of the schema is its start of authority.  No 'mob' schema
# changes should happen without changing this, and this way we can
# still avoid ugly UUIDs.
use Moose::Util::TypeConstraints;
use Regexp::Common qw/RE_URI/;
subtype "URI"
	=> as "Str"
	=> where \&RE_URI;

has 'ns_url' =>
	is => "ro",
	isa => "URI",
	;

# we can gracefully handle schema versioning by storing multiple
# incarnations of the schema objects in the store.  Any change in
# version means that a reschema is necessary.
has 'ns_rev' =>
	is => "ro",
	isa => "Num",
	default => 0.01,
	;

#natural key => qw(id version);
has 'classes' =>
	is => "rw",
	isa => "HashRef[Git::DB::Class]",
	# category => "name",
	;

# the "types" data is notes from the m²model, about what conversion
# functions are used for conversion of data types into the standard
# column format layout.  This is like a type library, though most
# languages will need only a few primitives implemented to cover it.
has 'types' =>
	is => "rw",
	isa => "HashRef[Git::DB::Type]",
	# category => "name",
	;

1;

__END__

=head1 NAME

Git::DB::Schema - represent schema (or lack thereof) of a Git::DB

=head1 SYNOPSIS

  # 'schema-less' operation a la CouchDB/prevayler
  my $schema = Git::DB::Schema->new(
      classes => {
          Object => Git::DB::Class->new(
              attrs => [
                  # schema-less stores use uuid as primary
                  # key
                  Git::DB::Column->new(
                      name => "oid",
                      type => "uuid",
                      default => "auto",
                  ),
                  # need to store the class name in a 'type'
                  # property; schemas which allow
                  # polymorphic retrieval often need this
                  Git::DB::Column->new(
                      name => "type",
                      type => "type",
                  ),
                  # the '_default' column; anything not
                  # serialized into a column is shoved in
                  # here, unless it itself can be a storage
                  # object.
                  Git::DB::Column->new(
                      name => "_default",
                      type => "data",
                  ),
              ],
              constraints => {
                  pkey => Git::DB::Constraint->new(
                      primary_key => 1,
                      columns => ["oid"],
                  ),
              }
          ),
      },
      # turn off promotion into a storage object; this means
      # all objects must be explicitly marked as a storage
      # object.
      detect_objects => 0,
  );

  # you don't need to supply the schema to connect to an
  # existing store, but 'create' needs it.
  my $store = Git::DB->create( schema => $schema );

  my $object = bless { hello => "world" }, "Greeting::String";
  my $uuid = $store->store($object);

  my $object2 = $store->fetch($uuid);

  # prints "Greeting::String world"
  print ref($object2), " ", $object->{hello};

=head1 DESCRIPTION

"Schema" is a bit of a dirty word these days.  Let's start with a
little, entirely anecdotal and completely un-footnoted story.  You can
shout C<[citation needed]> all you like, it's just a story.  However
any resemblence with true events is not entirely co-incidental.

Back when people started using computers to store data, one of the
early innovations was the B<heirarchical database>.  It's just a
nested data structure, see.  Start with some names to get into your
entry point, and there's your tree of data.  It was a natural and
basic extension of storing stuff on disks.

Well, anyway, as people used these things they figured out that often,
they wanted to refer from one part of it to another part which didn't
lie within the same heirarchy.  And so evolved the B<network
database>, which allowed B<links> between different heirarchies.  And
of course kept track of I<reference counts> for you.

But eventually the database programmers were getting tired of
debugging the business logic's programmers for them.  They wanted a
way to solve the problems which caused the biggest fudge-ups.  They
knew they could guarantee some things about their objects, such as
properties and their basic types.  And so came B<normalization> - the
B<first normal form> being this process of separating out known
properties from the otherwise free-form parts of the heirarchical
store.

Well, anyway, the next normal forms were built on that, to try and do
away with the problematic links, and replace them with B<relations>
and B<foreign-key constraints> instead.  At some point, people
realised that this was not only every bit as expressive as the
heirarchical model, but easier to reason with using mathematical
concepts such as B<set theory>.  And so, the B<relational database>
was born, leaving behind heirarchical models entirely.  Some databases
(eg DMS-II on Unisys A-Series systems) retained their hybrid nature.

Nowadays, this is all such ancient history that many programmers are
completely unaware of it.  Trendy new databases such as CouchDB, and
even MapReduce are really just "returning to the roots" of database
design - re-inventing the heirarchical and network database.  And
again you can see the same path of evolution occurring, with
technologies such as Amazon's SimpleDB, which is like CouchDB but with
nominated columns.

I see these efforts as like someone selling horse-back travel by
saying "look! it uses no petrol/gas at all!".  And SimpleDB is giving
the horse a carriage.  Amusingly this analogy seems to fit in terms of
raw speed and safety provisions, too.

So, anyway, there are lessons to be learned through all of this;

=over

=item 1.

B<Schema-less operation is often handy for prototyping> - not having
to describe everything long-hand, and have it "fixed in stone", can
let you get on and start writing code quickly.  There are development
methodologies which are often just as effective that start with
schema, but not everyone uses them - and perhaps they are not
appropriate for every occasion.

=item 2.

B<Normalization is re-inforcing assumptions> - This is all about the C
for Consistency in ACID.  Once you know something "for sure" about
your data, you can turn it into a column with a proper constraint, and
then it can be relied upon for later development.  This makes that
later development simpler, as it eliminates a possible error condition
- that you might have considered unlikely enough to never bother
coding for.

=item 3.

B<Neither approach is the be-all and end-all> - a holistic, hybrid
approach seems to be called for.

=back

And so, Git::DB has been built to allow for use with a generic schema,
and gradual marking of attributes as storage columns.

=head1 IN-STORE SCHEMA STORAGE

Like Postgres, information about the schema of a database is itself
stored inside the database.  There is no magic here - they are just
stored in the store as if they were other objects.  The "re-entrancy"
is 'solved' by there being a standard set of types and classes built
in to Git::DB.

So, when Git::DB connects to a store, it will use its internal
knowledge of what types exist, and what meta-classes are valid, and
start loading meta-objects from the store.  The version of the schema
in the store is compared to the passed-in schema (if one is passed
in).

In the store, schema objects are never removed; they are kept around
to assist with automatic upgrade of the store and/or to present views
of the database which are compatible with programs expecting an older
version.

=cut

