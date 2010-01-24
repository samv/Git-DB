
package Git::DB::Meta::Attr;

use Moose::Role;
use MooseX::Method::Signatures;

has 'gitdb_name' =>
	is => "ro",
	isa => "Str",
	;

has 'gitdb_out' =>
	is => "ro",
	isa => "Str",
	;

has 'gitdb_out' =>
	is => "ro",
	isa => "Str",
	;

has 'gitdb_none' =>
	is => "ro",
	isa => "Bool",
	;

has 'gitdb_type' =>
	is => "ro",
	isa => "Str",
	;

package Moose::Meta::Attribute::Custom::Trait::Git::DB;
sub register_implementation { "Git::DB::Meta::Attr" }

1;

=head1 NAME

Git::DB::Meta::Attr - pepper classes with normalization hints

=head1 SYNOPSIS

 package Aubergine;
 use Moose -traits => ["Git::DB"];

 # customise the 'spam' column, to use the 'LOB' mapping.
g has spam =>
     is => "ro",
     isa => "Str",
     traits => ["Git::DB"],
     gitdb_type => "LOB",
     ;

=head1 DESCRIPTION

A database table is a series of columns, and an object is a series of
properties.  There may be a one to one mapping of these, but then
again there may just as easily not be, too.

In the case where there is a one to one mapping, with no surprises
then 'auto attributes' may be selected, as described on the
L<Git::DB::Meta::Class> pod page.  Mapping is carried out
corresponding to the rules described in L<Database: Slave or Master?,
Vilain (2006)>.

The Git DB Meta-Attribute trait allows this to be customised.
Conceptually, a normalized mapping of an object is a mapping of:

  (Class, Column, Object) -> Value

The L<Git::DB::Class> and L<Git::DB::Column> objects, which are stored
in the database and loaded at connection time, describe the valid
values for C<Class> and C<Column>, and the forms that C<Value> may
take.  However the C<Object> is fully under your control.

=head2 Marshalling out (dump/freeze) rules

Here's how it works.  During marshalling out, a method corresponding
to the declared name of the attribute is called on the object.  This
is independent to the C<reader> defined for the attribute (see
L<Class::MOP::Attribute>).  The value that this function returns is
passed to the function listed in the C<Git::DB::Type> mapping for the
column of the same name, which returns a serialized form of the value.
You can override the method called by specifying the C<gitdb_out>
property, and the logical column by specifying C<gitdb_name>.

You can mark properties as not for marshalling via C<gitdb> using the
C<gitdb_none> boolean property; this is normally a good idea when a
property is not for serialization, and is a hint to
L<Git::DB::Meta::Class> not to automatically promote the particular
Moose property to a L<Git::DB::Column> which can hold the value.
However, once the Git DB meta-class has been constructed, new
properties added will not be automatically mapped.  You can also mark
a class as not for automatic mapping.

This is not the implementation, and is not quite correct, but it is a
way to understand what this means:

  ($Class, $Column, $Object) -> $Value

  # what method do we marshall out with?
  my ($outfunc) =
      map { $_->gitdb_out // $_->name }
         grep { ($_->gitdb_name//$_->name) eq $Column }
             $Class->meta->get_all_attributes;

  # fetch the "Internal" value
  $Value = $Object->$outfunc;

  # fetch the "Official" name of the class
  my $Schema_Class_Name = $Class->gitdb_name // $Class->name;

  # get the Schema's Git::DB::Class object
  my $Schema_Class = $Schema->class->get($Schema_Class_Name);

  # get the "dump" function of the column
  my $Dumper = $Schema_Class->columns->get($Column)->dump;

  # call the method - value is marshalled out
  my $marshalled = $Dumper->($Value);

=head2 Marshalling in (load/thaw) rules

Marshalling in is very similar.  Here the function is slightly
different;

  (Class, Column, Value) -> ($Value)

During marshalling in, the logical column is paired up with a property
name using the C<gitdb_name> or the real attribute name.  This is
passed to the constructor, so if you want to fiddle on the way in with
that, you'll have to use BUILD or BUILDARGS.

In Semi-Psuedocode:

  # get the "load" function of the column
  my $Loader = $Schema_Class->columns->get($Column)->load;

  # marshall in
  my $Value = $Loader->($marshalled);

  # find the appropriate property
  my ($inpropname) =
      map { $_->name }
          grep { ($_->gitdb_name//$_->name) eq $Column }
              $Class->meta->get_all_attributes;

  $Schema_Class->name->new(
       $inpropname => $Value,
  );

=head2 Auto-Schema rules

The C<gitdb_type> and C<gitdb_none> properties are hints to the
automatic schema building.

When connecting to a GitDB store, there comes a time to match the
L<Git::DB::Column> object in the schema part of the store to a
L<Git::DB::Meta::Attr> in the class.  This is done by name.  Once a
column of a particular name is deleted from a store, it cannot be
re-created; instead, the C<gitdb_name> facility must be used with a
column name such as C<1:tomato>.

Once they have been matched, the types are compared.  If they are
different, then a schema change is required before the connection can
complete.

=cut

