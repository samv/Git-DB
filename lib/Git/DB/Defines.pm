
package Git::DB::Defines;

use strict;

# what is the precision of the ints on this machine?
use constant MAX_INT => (-1<<1)+1;
use constant MAX_NEG => (MAX_INT>>1)+1;
use constant INT_BITS => log(MAX_INT)/log(2);

use constant DEBUG_DEFINES => 0;
BEGIN {
	print "Int size is ".INT_BITS."\n" if DEBUG_DEFINES;
};

# ok, so do we have more or less precision with floats?  Assume we
# have at least 32 bits of mantissa and push it until it breaks.
our $bits;
BEGIN {
	$bits = INT_BITS > 32 ? 32 : INT_BITS;
	++$bits while ( ((2**$bits)+1) != (2**$bits) );
	$bits;
}
use constant MANTISSA_BITS => $bits;
use constant MANTISSA_2XXBITS => 2**MANTISSA_BITS;
use constant MAX_NV_INT => 2**(MANTISSA_BITS-2)-1;
use constant MANTISSA_PRECISION => int(log(MANTISSA_2XXBITS)/log(10));

BEGIN {
	print "Float size is ".MANTISSA_BITS."\n" if DEBUG_DEFINES;
	print "num is ".MANTISSA_2XXBITS."\n" if DEBUG_DEFINES;
	print "MAX_NV_INT is ".MAX_NV_INT."\n" if DEBUG_DEFINES;
	print "MANTISSA_PRECISION is ".MANTISSA_PRECISION."\n" if DEBUG_DEFINES;
};

use constant ENCODING_VARINT => 0;
use constant ENCODING_FLOAT => 1;
use constant ENCODING_STRING => 2;
use constant ENCODING_DECIMAL => 3;
use constant ENCODING_RATIONAL => 4;
use constant ENCODING_FALSE => 5;
use constant ENCODING_TRUE => 6;
use constant ENCODING_LOB => 7;
#use constant ENCODING_XXX8 => 8;
use constant ENCODING_NULL => 9;
use constant ENCODING_EOR => 10;
use constant ENCODING_ROWLEFT => 11;
#use constant ENCODING_XXX12 => 12;
use constant ENCODING_RESET => 13;
#use constant ENCODING_PUSH => 14;
#use constant ENCODING_POP => 15;

#  e☠port section
no strict 'refs';
our @constants;

BEGIN {
	@constants = grep !/[a-z]/,
		grep { defined &$_ }
			keys %{__PACKAGE__."::"};
}

use Sub::Exporter -setup => {
	exports => \@constants,
	groups => {
		int => [ grep /INT|NEG/, @constants ],
		float => [ grep /NV|MANTISSA/, @constants ],
		encode => [ grep /ENCODING/, @constants ],
	       },
};

1;
