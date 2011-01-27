
package Git::DB::Type::Basic;

use strict;

use Git::DB::Type qw(register_type);
use Git::DB::Encode qw(:all);
use Git::DB::Defines qw(:encode);

use Git::DB::ColumnFormat::True;
use Git::DB::ColumnFormat::False;

sub is_tf { $_[0] ? ENCODING_TRUE : ENCODING_FALSE }

sub FUNC { [ $_[0] => \&{$_[0]} ] }

sub as_is { $_[0] }
sub boolcmp_ft {
	(!$_[0] == !$_[1]) ? 0 :
	(!$_[0] && $_[1]) ? -1 : 1;
}
sub print_tf { $_[0] ? "t" : "f" }
sub scan_tf { $_[0] eq "t" ? 1 : $_[0] eq "f" ? '' : undef }
sub boolcmp_ft {
	my ($a, $b) = @_;
	( $a ? ( $b ? 0 : 1 ) : ( $b ? -1 : 0 ) );
}
sub read_bool { $_[1] == ENCODING_TRUE ? 1 : '' }
sub encode_bool { '' }

register_type "bool" => {
	formats => 0b1100000,
	choose => FUNC("is_tf"),
	print => FUNC("print_tf"),
	scan => FUNC("scan_tf"),
	cmp => FUNC("boolcmp_ft"),
	read => FUNC("read_bool"),
	dump => FUNC("encode_bool"),
};

sub cmp_number { $_[0] <=> $_[1] }
sub print_number { "$_[0]" }
sub scan_number {
	0+$_[0];
}

# number types with specific semantics
register_type "integer" => {
	formats => 0b1,
	print => FUNC("print_number"),
	scan => FUNC("scan_number"),
	cmp => FUNC("cmp_number"),
	read => FUNC("read_int"),
	dump => FUNC("encode_int"),
};

register_type "float" => {
	formats => 0b10,
	print => FUNC("print_number"),
	scan => FUNC("scan_number"),
	cmp => FUNC("cmp_number"),
	read => FUNC("read_float"),
	dump => FUNC("dump_float"),
};

register_type "decimal" => {
	formats => 0b1000,
	print => FUNC("print_number"),
	scan => FUNC("scan_number"),
	cmp => FUNC("cmp_number"),
	read => FUNC("read_decimal"),
	dump => FUNC("dump_decimal"),
};

register_type "rational" => {
	formats => 0b10000,
	print => FUNC("print_number"),
	scan => FUNC("scan_number"),
	cmp => FUNC("cmp_number"),
	read => FUNC("read_rational"),
	dump => FUNC("dump_rational"),
};

use Git::DB::Float qw(pick_numeric_encoding);

# the more general type which allows any encoding.
register_type "numeric" => {
	formats => 0b11011,
	choose => FUNC("pick_numeric_encoding"),
	print => FUNC("print_number"),
	scan => FUNC("scan_number"),
	cmp => FUNC("cmp_number"),
	read => FUNC("read_numeric"),
	dump => FUNC("dump_numeric"),
};

sub length_gt_2kiB {
	bytes::length($_[0]) > 2048 ? ENCODING_LOB : ENCODING_STRING;
}

sub cmp_text { $_[0] cmp $_[1] }
sub print_text { "$_[0]" }
sub scan_text { $_[0] }

# utf-8 strings.
register_type "text" => {
	formats => 0b1000100,
	choose => FUNC("length_gt_2kiB"),
	print => FUNC("print_text"),
	scan => FUNC("scan_text"),
	cmp => FUNC("cmp_text"),
	read => FUNC("read_text"),
	dump => FUNC("encode_text"),
};

sub print_bytes_hex {
	my $string = shift;
	pack("H*", $string);
}

sub scan_bytes_hex {
	my $packed = shift;
	unpack("H*", $packed);
}

register_type "bytes" => {
	formats => 0b1000100,
	choose => FUNC("length_gt_2kiB"),
	print => FUNC("print_bytes_hex"),
	scan => FUNC("scan_bytes_hex"),
	cmp => FUNC("cmp_text"),
	read => FUNC("read_bytes"),
	dump => FUNC("encode_bytes"),
};

1;

__END__

# Some more examples, primarily as a thought exercise.

# timestamp type: can be stored either as an iso8660 string, or as a
# numeric quantity.  The most significant impact of the epoch is that
# if it is too long ago, precision in recent times can be lost if you
# are not careful.

# You only get microsecond precision for 142.7 years from the epoch
# with double precision math.  Extended precision (64-bit mantissa) is
# much better at 292,277 years.

# common epochs include 1BC ("Anno Domini" / "Current Era" time), 1970
# (unix epoch), 1904 (MacOS X epoch?), Julian time starting at either
# 4712BC or 4713BC (depending on whether you believe in 0AD or not),
# and the Chinese calendar which has a similar off-by-one ambiguity
# and starts a thousand years or so after the Julian epoch.

# In addition to the epoch is the unit.  Really, having a fixed unit
# for time types is not representative of the number system that is
# used by the calendars.  The Radix varies by unit, like imperial
# measurements, and worse than imperial the number of divisions
# depends on the value of the fields above.  You cannot, for instance,
# convert "1 month" to seconds without knowing which month, perhaps of
# which year, the month refers to.

# Accordingly, using seconds for dates opens up the door for daylight
# savings confusion, which is a nasty sort of confusion.  So doing
# date math in Julian days is generally less confusing than dealing
# with epoch seconds.

# So.  Why not use the number of days since the Unix epoch.  It can be
# converted to UTC by multiplying by 86400 and to the Julian calendar
# by adding 2440588.

register_type "timestamp" => {
	formats => 0b11111,
	choose => FUNC("pick_date_encoding"),
	pack => FUNC("pack_julian_timestamp"),
	unpack => FUNC("unpack_julian_timestamp"),
	print => FUNC("print_iso8660"),
	scan => FUNC("print_iso8660"),
};

# following Postgres' lead, we'll make the timestamptz stored
# internally as an epoch adjusted time.  ie, the input value is stored
# as UTC and adjusted on the way out to local time.  This makes it
# harder to detect some types of bugs, but it allows the same
# functions to be used.
register_type "timestamptz" => {
	formats => 0b11111,
	choose => FUNC("pick_date_encoding"),
	pack => FUNC("pack_julian_timestamptz"),
	unpack => FUNC("unpack_julian_timestamptz"),
	print => FUNC("print_iso8660"),
	scan => FUNC("print_iso8660"),
};

# intervals.  if this is a numeric value it should almost certainly be
# in the same unit as the timestamp type.
register_type "interval" => {
}
