
package Git::DB::Meta::Class;

use Moose::Role;
use MooseX::Method::Signatures;

has 'git_db_class' =>
	is => "ro",
	isa => "Git::DB::Class",
	lazy => 1,
	default => \&make_class,
	;

has 'auto_attrs' =>
	is => "ro",
	isa => "Bool",
	;

method make_class() {
	my @attributes = $self->get_all_attributes;
	if ( $self->auto_attrs ) {
	}
}

package Moose::Meta::Attribute::Custom::Trait::Git::DB;
sub register_implementation { "Git::DB::Meta::Attr" }
