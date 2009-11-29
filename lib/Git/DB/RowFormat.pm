
package Git::DB::RowFormat;

has 'columns' =>
	is => 'rw',
	isa => "ArrayRef[Git::DB::Type]",
	;

1;

__END__

=head1 NAME

Git::DB::RowFormat - Document and implement the GitDB Row Format

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

Firstly, ASN.1 BER integers are preferred to the format for encoding
arbitrary length numbers in ProtocolBuffer.  This encoding is very
similar, but supports negative numbers in a more "natural" fashion -
by treating the most significant bit as a sign bit and extending it.

Another change is to use four instead of three bits to encode the
column type to allow for future expansion and allow more compact
representation of common types such as booleans.  Yet another is to
use relative column number indexing instead of absolute.  These are
all minor changes which should hopefully enhance the compressibility
of row data by huffman-style coding.

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

A variety of types are assigned to various value types to allow for
flexibility of representation.  In "Normative Representation" this is
not the case and a single type is always represented with a particular
value type; this implies some loss of information as the rigid schema
(round hole) is applied to the data (square peg).  An example of this
is timestamp types.  Should a timestamp type be indicated for a column
in the schema, it would be assumed to be a quantity of seconds from
the epoch.

Encountering an integer (type 0) would indicate a traditional `time_t`
epoch time.
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

=head2 Column types

The meaning of the 4-bit type field is given below.  Some of these
come from ProtocolBuffer.

 Type   Meaning     Used For
 ----   -------     --------
   0     Varint      Any integer type (BER int follows)
   1     float       64-bit float/timestamp
   2     Length-     Strings etc. BER int N follows, then N
         delimited   bytes of data.
   3     numeric     Two BER ints follow to denote scale
                     (base 10) and value.
   4     rational    Two BER ints follow to denote a
                     rational number - scalar and quotient
   5      -          reserved
   6     bigfloat    128-bit float/timestamp
   7     lob         null-terminated path to value follows
   8     false       Boolean; False; no data follows
   9     true        Boolean; True; no data follows
   a     EOR         End of row
   b     length      BER int follows with length of remaining row.
   c     NULL        Explicit NULL
   d     Reset       Reset column index to 0; expect 1st
                     column next
   e      -          reserved
   f      -          reserved

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
necessarily linked from the filesystem level as well; in a 'toast'
relation, these would typically be arbitrarily named with a special
filename form for the necessary back-references required for garbage
management.

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


