
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

=head2 Row Filename Formats

First a basic pretty printing of the value happens.  Row IDs are
always sorted using the natural sort order of the primary keys.

  Type     Type            Eg Value  Serialize As     Sort
 -------- ---------------- --------- --------------- ------
  VarInt   Integer           1234    1234             <=>
                               -1    -1

  Float    Floating point    1.234   1.234            <=>
                               -1    -1
                             10²³    10e+23

  Bytes    Strings etc      "1234"   0x3031323334     cmp

  Text     Text etc         "1234"   1234             cmp
                              "\0"   ␀                cmp
                               "1"   ␀                cmp

  Decimal  Base 10         10.2312   10.2312
  Rational Fractions    1234124/12   102843.6         cmp
  Boolean  Boolean              1    t          ($a cmp $b) and
                                ""   f           ($a ? 1 : -1)

  LOB      out-of-row vals; "huge.." \a123128312      cmp (data)

The LOB in the filename is problematic, as the blob behind that
filename needs to be reference counted, but the reference to the row
itself is problematic to arrange.

=head3 Conversion and Escaping rules

The driving principle of the conversion rules are;

=over

=item 1

They must be able to encode all possible values in path names which
are compatible with the git filesystem layout.

=item 2

they should be as straightforward and intuitive as possible.

=back

=cut

Firstly, columns in multi-column primary keys are delimited in the
path with a simple comma.

Columns which are 'integral numeric quantities' are converted to their
base 10 form.

Columns which are 'rational numeric quantities' are specified in base
10, to sufficient precision not to lose important bits (eg like
ieee754 decimal form)

Columns which are 'dates', 'timestamps' or 'intervals' are converted
to the corresponding ISO-8601 representation.

Columns which are 'booleans' are converted to `t` and `f`.

Columns which are 'strings' which have characters that are considered
special are escaped in various ways.
Entire ranges of control characters are indiscriminately escaped to
various pretty Unicode forms:

  - ASCII 0x0 through 0x1f are converted to their U+24xx escapes
  - Special ASCII characters (currently, ',', '-', '/' and '\') are
    converted to their fullwidth forms U+ffxx
  - Should the above unicode characters appear in a key, it is in turn
    escaped to `\x\{24xx\}` (where `24xx` is the Unicode codepoint)

Columns which cannot be reduced to any of the above forms are not
considered legal primary key candidates.



Row Pages
^^^^^^^^^
Multiple rows may be combined into single blobs; these are akin to
database "pages";

   ticket/1001-2000/1001-1100
   ticket/1001-2000/1101-1200

A drawback to using this style of update is that it must also be
possible to record deletes and updates to pages without deleting or
re-writing those pages; blobs which contain newer versions of rows
compared to existing blobs will be distinguished by a suffix.  The
highest suffix is the one used.

   ticket/1001-2000/1001-1100
   ticket/1001-2000/1006;1

In the above, 'select' can tell from the index that the file '1006;1'
contains a newer version of the row with PK = 1006; it has been
updated.

Deletes from combined blobs will be recorded with a different suffix;

   ticket/1001-2000/1001-1100
   ticket/1001-2000/1006;X

The decision whether to clean up these dead rows from the store is
akin to the decision to rebalance a B+ or B* Tree.

The "Row Page" feature is optional and may be disallowed on some
stores which prefer to keep the representation of a given set of data
content predictable.

Row pages are thought to be required to achieve compression of table
content, as otherwise the string matching and huffman coding features
of LZW compression used by gzip cannot use a very likely source of
string matches - the previous row!
=cut

