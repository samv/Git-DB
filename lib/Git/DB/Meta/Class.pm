
package Git::DB::Meta::Class;

use Moose::Role;
use MooseX::Method::Signatures;

# later: expand api to include DB mapping 
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

__END__

=head1 NAME

Git::DB::Meta::Class - metarole mix-in: schema mapping for a DB class

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut

