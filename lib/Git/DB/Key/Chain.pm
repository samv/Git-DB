
# a Git::DB::Key::Chain is an immutable object that has the keys in a
# primary key arranged in a linked list of Git::DB::Key::Chain
# objects.

package Git::DB::Key::Chain;

use Moose;

has 'attr' =>
	is => "ro",
	isa => "Git::DB::Attr",
	;

has 'print_func' =>
	is => "ro",
	isa => "CodeRef",
	;

has 'scan_func' =>
	is => "ro",
	isa => "CodeRef",
	;

has 'cmp_func' =>
	is => "ro",
	isa => "CodeRef",
	;

has 'next' =>
	is => "ro",
	isa => __PACKAGE__,
	;

1;
