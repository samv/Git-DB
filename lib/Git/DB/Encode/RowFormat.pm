
package Git::DB::Encode::Row;

use 5.010;
use strict;

use Git::DB::Encode::Int;

sub col_header {
	my $col_offset = 0+shift;
	my $type = 0+shift;
	encode_int($type & 0xf + $col_offset << 4);
}

sub write_row {
	my $class = shift;
	my $item  = shift;
	my $item_mc = $item->meta;
	my $i = 0;
	my @rv;
	my $col_offset = 0;
	while ( my $attr = $class->get_column($i) ) {

		my $reader = $item_mc->gidb_reader;
		my $val = $item->$reader if $reader;

		given ($attr->type) {
			when ($_->can("choose")) {
				my $type = $_->choose($val);
				push @rv, col_header($col_offset, $type);
				push @rv, $_->dump($val);
			}
			default {
				push @rv, col_header($col_offset, $_->type);
				push @rv, $_->dump($val);
			}
		}
		$i++;
		if ( $attr->deleted ) {
			$col_offset++;
		}
		else {
			$col_offset = 0;
		}
	}
}

1;

__END__

=head1 NAME

Git::DB::Encode::Row - rules for encoding rows etc

=head1 SYNOPSIS

 my $row_format = Git::DB::RowFormat->new
    ( columns => [ Git::DB::Type->new(...) ],
    );

=head1 DESCRIPTION

This class represents a row in a GitDB table store.

=head1 ROW FORMAT DESIGN DISCUSSION

An important consideration in the design is to be able to avoid
rewriting table data if a table's column definitions change, as such a
DDL change may result in a disastrously large update.

Google's ProtocolBuffer standard fits the bill closely, and is used
with some modifications.

Firstly, the integer store format is simplified.  It is always a 2's
complement integer, no ZigZag encoding, big endian.  The transform is
(example for a 16-bit machine word system):

  ( X[-1] ? 0xFFFF & (X>>N) : 0x0000 | (X>>N) )

X[-1] is the top bit, and always bit 2 of the first byte in the
sequence.  N is the number of bits short of a word you find yourself
at after combining and counting all the bytes of X.

Another change is to use four instead of three bits to encode the
column type, to allow for more basic types.  Yet another is to use
relative column number indexing instead of absolute.

There are 4 numeric storage formats, to cater for the varieties of
numeric quantities found as database value types with the least amount
of new ideas; Int (M), Float (M×2ⁿ), Decimal (M×10ⁿ) and finally
Rational (M÷N), all stored as pairs of ints.


A "page" is a blob - either for a single row, or for a sequence of
rows.  Each row in a page is a succession of columns, each introduced
with a BER integer.  The primary key columns are always written first,
followed by an optional (but in the "normative" encoding, pointless
and hence illegal) psuedo-column which says how long the rest of the
row is, for faster scanning through the page.  It's possible that
table schema changes would break that assumption; you can either have
normative coding of content or efficient incremental operation, not
both.

The lowest four bits of this are interpreted as an enumerated type
indicator for the value which follows; enough to scan the row without
a schema, but without the schema it is not possible to interpret the
value fully.

A variety of types are assigned to various numeric types to allow for
flexibility of representation.  In "Normative Representation" this is
not the case and a single type is always represented with a particular
value type; this implies some loss of information as the rigid schema
(round hole) is applied to the data (square peg).  An example of this
is timestamp types.  Should a timestamp type be indicated for a column
in the schema, it would be assumed to be a quantity of seconds from
the epoch.

Encountering an integer (type 0) would indicate a traditional `time_t`
epoch time, but with no y2038 problem.

Encountering a float (type 1) would indicate a floating point epoch
time.

Encountering a numeric (type 3) with a scale of 6 would indicate a
Postgres-style 64-bit integer date (number of microseconds since the
epoch).
A string (type 2) would indicate an ISO-9660 encoded date.

The top N bits of the number is a relative column offset.

Given that there are four bits for data type, one bit to indicate BER
extension and one bit for sign, that leaves only two bits to represent
value.
If this is '0' then it means the next column which is due.
This will be the case a lot of the time - always in the normative
form.
This repetition of byte values should increase compressibility of data
pages.
A number such as '2' means that the next two columns were NULL (or
dropped before this row was written) and that the third next column
follows.
A negative number means that the columns are appearing out of order;
for example, the primary key was not set to the first defined columns
in the original schema.
Rows can still be horizontally combined simply due to a special
psuedo-type that resets the expected column back to 1.

This means that no matter how many columns there are, only long (>3)
sequences of NULL columns involve multi-byte headers, instead of
all columns after the 15th as with ProtocolBuffer.
Also, groups of boolean columns will be efficiently stored with one
byte each, and generally in a form that will huffman code well.


As in ProtocolBuffer, well formed rows from two sources can be
combined by string concatenation, except using the ASCII carriage
return (CR) character between them, which encodes a 'Reset' column.
Normally it is not necessary to encode NULL column values; leaving
them out is equivalent, but in the context of combining rows this may
be useful.
Explicit NULL values should never appear on disk; it is reserved for
stream use in situations where it is required.
The "Normative" form never uses such facilities.

The 'length' type allows for skipping over row content to allow faster
lookup by by primary key.  Instead of decoding all columns in the rows
that precede it, columns can be skipped.
In the "normative" form, such a column appears only in pages
containing multiple rows, and follows the primary key columns.

For larger column values, they may have their data saved in their own
blob instead of stored in the page using the 'object' code.  These are
necessarily linked from the filesystem level as well; under
lob-columnname/primary,key - this allows for natural reference
counting of LOBs by git.

The 'dump' type is for schema-less operation.  Any data which can be
encoded in JSON form is allowed.  Additionally, links to other objects
in the database are permitted.  These are represented in the data
structure using a function:

  { "foo": "bar", "baz": link("Type", "key1", "key2") }

Most standard JSON serializers likely to choke on this, but
unfortunately without designating a "sentinel value", this is the
cleanest approach.

There is also another function, which may be used for dumping:
B<bless>.  It is called just like Perl's C<bless>, and is only
required when the dumper dumps a data object.

Both of these extended forms of JSON must be explicitly enabled for a
particular column; if the column type does now allow it, then they are
not permitted.


