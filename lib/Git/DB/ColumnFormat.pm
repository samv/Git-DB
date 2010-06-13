
package Git::DB::ColumnFormat;

use Mouse::Role;
use Module::Pluggable search_path => [__PACKAGE__];

requires 'type_num';
requires 'to_row';
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
	my ($cf_class) =
		grep { $_->can("type_num") && $_->type_num eq $column_format }
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
 package Git::DB::ColumnType::LengthDelimited;
 use Moose;
 use MooseX::Method::Signatures;
 with 'Git::DB::ColumnType';
 sub type_num { 2 };
 method to_row( $data ) {
     return encode_int(length($data)), $data;
 }
 method read_col( IO::Handle $data ) {
     my $length = read_int($data);
     my $data = read($data, $length);
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

=head2 Column types

The meaning of the 4-bit type field is given below.  Some of these
come from ProtocolBuffer.

 Type ♨  Type     Description                   Formulae
 ---- - -------- -------------------------   (Numeric Types)
   0  ␀  VarInt   Integer: N                        N
   1  ␁  Float    Floating point: E, M            M×2^E
   2  ␂  Bytes    Strings etc: len, data            N
   3  ␃  Decimal  Base 10: E, M                   M×10^E
   4  ␄  Rational Fractions: M, Q                  M/Q
   5  ␅  False    Boolean; False; no data
   6  ␆  True     Boolean; True; no data
   7  ␇  LOB      out-of-row values; length-delimited binary
                  hash follows
   8  ␈   -       reserved
   9  ␉  Null     Explicit NULL
   a  ␊  EOR      End of row
 x b  ␋  RowLeft  primary key over; int gives
                  length of remaining row
   c  ␌   -       reserved
 x d  ␍  Reset    Reset column index to 0
 x e  ␎  Group    Composite type group start
 x f  ␏  UnGroup  Composite type group end

The C<♨> column may contain unicode glyphs to help remind what ASCII
control character you will see if you end up directly inspecting heap
contents.  Columns prefixed with an C<x> are provisionally assigned
but will not be implemented initially.

=cut

