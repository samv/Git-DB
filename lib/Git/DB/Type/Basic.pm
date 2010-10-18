
package Git::DB::Type::Basic;

use strict;

use Git::DB::Type qw(register_func);

# 3 types of function may be defined:
#  1. choose.  take a value, return a column type.
#  2. load($bytes, $val): returns 
sub as_is { $_[0] }

# bool
use Git::DB::ColumnFormat::True;
use Git::DB::ColumnFormat::False;

use constant true => Git::DB::ColumnFormat::True->type_num;
use constant false => Git::DB::ColumnFormat::False->type_num;

sub is_tf { $_[0] ? true : false }
sub boolin { $_[1] == true ? 1 : $_[1] == false ? '' : die }
sub boolout { ($_[1]) }

register_func qw(bool choose is_tf) => \&is_tf;
register_func qw(bool dump boolout) => \&boolout;
register_func qw(bool load boolin) => \&boolin;

# int types: simple semantics
use Git::DB::Encode qw(:all);
register_func qw(int dump encode_int) => \&encode_int;
register_func qw(int load decode_int) => \&decode_int;
register_func qw(uint dump encode_uint) => \&encode_uint;
register_func qw(uint load decode_uint) => \&decode_uint;

# float: simple semantics
use Git::DB::Encode qw(:all);
register_func qw(float dump encode_float) => \&encode_float;
register_func qw(float load decode_float) => \&decode_float;

# utf8 strings
register_func qw(text dump encode_str) => \&encode_str;
register_func qw(text load decode_str) => \&decode_str;

# byte arrays
register_func qw(bytea dump encode_str) => \&encode_str;
register_func qw(bytea load as_is) => \&as_is;
