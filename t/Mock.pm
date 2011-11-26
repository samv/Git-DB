
package Mock;

sub isa {
        1;
}

sub AUTOLOAD {
}

sub new {
        my $class = shift;
        bless {@_}, $class;
}

package Mock::Git::DB::Class;

@ISA = "Mock";

1;
