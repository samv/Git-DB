
package Git::DB::Type;

use Moose;

has 'schema' =>
	is => "ro",
	isa => "Git::DB::Schema",
	;

has 'name' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

# use MooseX::NaturalKey
# natural key => qw(schema name);

has 'formats' =>
	is => "ro",
	isa => "ArrayRef[Bool]",
	default => sub{[]},
	;

has 'choose_func' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'dump_func' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'load_func' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'to_rowname_func' =>
	is => "ro",
	isa => "Str",
	required => 0,
	;

has 'rowname_sort_func' =>
	is => "ro",
	isa => "Str",
	required => 0,
	;

has 'from_rowname_func' =>
	is => "ro",
	isa => "Str",
	required => 0,
	;

no strict;

# Git::DB::Type::Foo plug-ins will provide these named functions into
# a global namespace of type in/out function names.

our @TYPES = (
# NAME      SCALEOK          FORMATS  CHOOSE    DUMP        LOAD
#                 fedcba9876543210

###
  void,           f,             0,            'die',      'die',
#---

###
  bool,           f,     0b1100000,   is_tf,   '!!',        '!!',
#----

###strings and text
  bytea,          t,    0b10000100,   is_big,  bytesout,   bytesin,
## mongrel utf8
  text,           t,    0b10000100,   is_big,  textout,    textin,
## normalized utf8's
  nfctext,        t,    0b10000100,   is_big,  nfctextout, nfctextin,
  nfdtext,        t,    0b10000100,   is_big,  nfdtextout, nfdtextin,
  nfkctext,       t,    0b10000100,   is_big,  nfkctextout, nfkctextin,
  nfkdtext,       t,    0b10000100,   is_big,  nfkdtextout, nfkdtextin,

## cargo cult from teh SQL:
  char,           t,        0b0100,   undef,   textout,    textin,
  varchar,        t,        0b0100,   undef,   textout,    textin,
## cargo culting from Postgres:
  bit             t,        0b0100,   undef,   bytesout,   bytesin,
  varbit,         f,             1,   undef,   intout,     intin,

###
# number types
#----

# float: scale can be set, eg 23=ieee32, 53=ieee64, 64=ieee80
  float,          t,       0b11111,   flutter,   floatout, floatin,
  money,          t,    0b00011111,   beancount, moneyout, moneyin,

# numeric: is actually the decimal type really.  any number type is valid
  numeric,        t,    0b00011011,   numpack,   numout,   numin,
  'int',          f,    0b00001011,   intpack,   intout,   intin,

###
# calendar types
#----

# seconds today since midnight or ISO-8601 valid time as str
  time,         f,    0b00011111,  timewarp,  timeout,  timein,
  timetz,       f,    0b00011111,  timetzwarp, timetzout, timetzin,

# *days since 1969 on Greg. or ISO-8601 valid date as str
  date,         f,    0b00011111,  datewarp, dateout, datein,

# a moment on the UTC clock as a number, or as a Str, a timestamp with
# time zone
  timestamptz,  f,    0b00011111,  localtimewarp, localtimeout, localtimein,

# a moment on the UTC clock as a number, or as a Str, a timestamp with
# no timezone (but implied TZ of UTC)
  abstime,      f,    0b00011111,  gmtimewarp, gmtimeout, gmtimein,

# a moment on the Gregorian calendar, without the implication of timezone
  timestamp,    f,    0b00011111,  timestampwarp, timestampout, timestampin,

# note to W3C XML Schema spec designers: notice how Postgres does not
# have a datetz type.  Postgres knows it doesn't make sense.

# an interval, δtime, eg seconds
  interval,     f,      0b00011111,  tintwarp, tintout, tintin,

# δtime, timestamp - ISO-8601 Str form only atm
  reltime,      f,      0b00000100,  undef, reltimeout, reltimein,

###
# other important types
#----

# inet: can be int;
# if a <=128-bit number, then a v6 address (eg 2401::1)
# if a <=32-bit number, then a v4 address (eg 192.168.2.1)
# if a <=24-bit number, then a v6 address (eg ::1)
# or just ntoa representation as Str
  inet,         f,      0b00000101,  inet_is_raw, inetout, inetin,

# cidr: str-only
  cidr,         f,      0b00100,  cidr_is_raw,  cidrout, cidrin,

# UUID must always be a byte string, scale is probably more like UUID
# version
  uuid,         t,      0b100,  undef,  uuidout, uuidin,

# other structured types
  json,         f, 0b10000100,  is_big,  jsondump, jsonload,
  yaml,         f, 0b10000100,  is_big,  yamldump, yamlload,
  xml,          f, 0b10000100,  is_big,  libxmlout, libxmlin,
);

@TYPES % 6 and die "invalid length of @TYPES array - likely type";

my @t = @TYPES;
while (my ($typnam, $typscales, $typmask,
	   $typchoose, $typoutfunc, $typinfunc,
	  ) = splice @t, 0, 5 ) {
	
}

# higher order types?
## array[`T]            0b10000101    mk`arrayout  mk`arrayin
1;

__END__

=head1 NAME

Git::DB::Type - Concrete Types in a Data Store

=head1 SYNOPSIS

=head1 DESCRIPTION

A Git::DB::Type describes a column type; roughly corresponding to the
function of the C<pg_types> table in Postgres.  It maps from the types
you use in for a column to the representations used in the row format.

Types are different to Classes, which are more like tables in a
traditional DB sense.  See Git::DB::Class for information on those.
Some day, user-defined types may be classes, in which the value in the
column is a version of that object, and the value in the column on
disk is a nested row of that class.

There are a set of built-in types, and these do not need to be listed
explicitly in the schema section of the store; however, they can be
listed in order to to restrict the column formats for some datatypes,
if desired.

The definition of a type includes:

=over

=item B<name>

The name of the type, eg C<bool>, C<char>, C<varchar>, C<int>,
C<text>, C<uuid>, C<timestamp>, C<interval>, C<money>, C<inet>, etc.
These names will be shamelessly stolen from Postgres where
appropriate.

=item B<formats>

This is an C<bitarray> column, containing a list of the allowable
column formats.

=item B<dump>

The name of a function which converts a value in your program to a
value in the column.

Using this function, and the function below, you can define truly
custom types - and deliver them using a L<Git::DB::Function> schema
object - but this may tie your application to a particular language or
platform until a standard method for representing functions is
established.

=item B<load>

The name of a function which converts a value in the column to value
in your program.

=back

=cut

