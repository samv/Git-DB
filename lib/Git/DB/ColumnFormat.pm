
package Git::DB::ColumnFormat;

use Moose::Role;
use Module::Pluggable search_path => [__PACKAGE__];

requires 'type_num';
requires 'write_col';
requires 'read_col';

use Memoize;
sub column_format {
	my $column_format = shift;
	our @plugins;
	unless ( @plugins ) {
		@plugins = __PACKAGE__->plugins;
		#print STDERR "Plugins: @plugins\n";
		for my $plugin (@plugins) {
			unless ( eval "use $plugin; 1" ) {
				warn "Error loading plugin $plugin: $@";
			}
		}
	}
	# XXX - 'Text' vs 'Bytes' is not a distinct type num.
	my ($cf_class) =
		grep { $_->can("type_num") && $_->type_num eq $column_format }
			grep {
				my $class = $_;
				!( grep { $_ ne __PACKAGE__ &&
						  $_->isa(__PACKAGE__) }
					   $class->meta->superclasses);
			}
			@plugins;

	$cf_class;
}

use Sub::Exporter -setup => {
	exports => [qw(column_format)],
};

BEGIN {
	memoize "column_format";
	#print STDERR "Formats:\n",
		#map {
			#sprintf("  %2d : %s\n",
				#$_, column_format($_)||"-" )
	#} (0..15);
}

1;

__END__

=head1 NAME

Git::DB::ColumnFormat - Role for column formats

=head1 SYNOPSIS

 # sub-class API
 package Git::DB::ColumnFormat::Foo;
 use Mouse;
 with 'Git::DB::ColumnFormat';
 sub type_num { 2 };
 sub write_col {
     my $inv = shift;
     my $io = shift;
     my $value = shift;
     #my $row = shift;
     print { $io } encode_uint(bytes::length($value)), $value;
 }
 sub read_col {
     my $inv = shift;
     my $io = shift;
     my $length = read_uint($io);
     my $data = read($io, $length);
     return $data;
 }

=head1 DESCRIPTION

This role and set of associated classes (C<Git::DB::ColumnFormat::*>)
implement the serialized form of columns in a data set.

These are slightly different from data types, which may be
user-defined and uninterpretable.  A given data type may also permit
multiple column formats - for instance, a column of type Num may be
stored as a decimal quantity, a float, an integer, or a rational
number.

By comparison, a column format already knows the encoding which will
be used and is only concerned with turning a value into that encoding
or reading the expected encoding type and returning a value.

The C<$row> object is passed to C<write_col> for the benefit of the
LOB type.

=cut
