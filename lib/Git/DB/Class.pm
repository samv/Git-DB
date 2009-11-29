
package Git::DB::Class;

use Moose;

has 'class' =>
	is => "rw",
	isa => "Class::MOP::Class",
	;

has 'isa' =>
	is => "rw",
	isa => "Str",
	;

has 'has' =>
	is => "rw",
	isa => "HashRef[Git::DB::Column]",
	;

has 'auto_attrs' =>
	is => "ro",
	isa => "Bool",
	;

no Moose;

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

