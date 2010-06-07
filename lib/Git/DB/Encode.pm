
package Git::DB::Encode;

# this module provides functions for marshalling data types to byte
# streams.

use strict;
use bytes;
use Encode;
use Carp;
use utf8;
use 5.010;
use Math::BigInt try => "GMP";
use Scalar::Util qw(blessed);

use Git::DB::Defines qw(MAX_INT MAX_NV_INT MANTISSA_BITS MAX_NEG);

use Sub::Exporter -setup => {
	exports => [qw(encode_string decode_string
		       encode_int decode_int read_int
		       encode_uint decode_uint read_uint
		       encode_float decode_float
		     )],
	};

# utf-8 or nothing for this module
sub encode_string {
	my $str = shift;
	if ( utf8::is_utf8 ) {
		Encode("utf8", $str);
	}
	else {
		$str;
	}
}

# but alway return in utf8
sub decode_string {
	my $str = shift;
	utf8::upgrade($str);
	$str;
}

sub _pack_w {
	my $num = shift;
	if ( abs($num) > MAX_NV_INT and blessed $num ) {
		pack("w", "$num");
	}
	else {
		pack("w", $num);
	}
}

# a bit like Perl's pack("w", "*") but always packs a 2's complement
# number.
sub encode_int {
	my $x = shift;
	given ($x) {
		when ($_<0) {
			my $bnot = ~$x;
			my $x = ~_pack_w($bnot);
			if ( !vec(substr($x,0,1), 6, 1) ) {
				# would look positive, make longer
				#vec($x, 6, 1) = 0;
				$x = chr(0x7f).$x;
			}
			for (my $i=0;$i<length($x);$i++) {
				vec($x,$i*8+7,1)^=1;
			}
			return $x;
		}
		default {
			my $x = _pack_w($x);
			if ( vec(substr($x,0,1), 6, 1) ) {
				# would look negative, make longer
				#vec($x, 6, 1) = 0;
				return chr(0x80).$x;
			}
			else {
				return $x;
			}
		}
	}
}

sub decode_int {
	my $ber = shift;
	my $neg = vec(substr($ber,0,1),6,1);
	if ( $neg ) {
		$ber = ~$ber;
		for (my $i=0;$i<length($ber);$i++) {
			vec($ber,$i*8+7,1)^=1;
		}
		my $num = unpack("w", $ber);
		if ( $num > abs(MAX_NEG)-1 ) {
			return Math::BigInt->new("-$num")-1
		}
		else {
			return -$num-1;
		}
	}
	else {
		decode_uint($ber);
	}
}

sub encode_uint {
	my $uint = shift;
	croak "$uint is negative" if $uint < 0;
	_pack_w($uint);
}

sub decode_uint {
	my $ber = shift;
	my $num = unpack("w", $ber);
	if ( $num > MAX_INT ) {
		return Math::BigInt->new($num)
	}
	else {
		return $num;
	}
}

=for searching

# looking for: ?
sub read_int {
sub read_uint {

=cut

BEGIN {
	no strict 'refs';
	for my $type ( qw(int uint) ) {
		my $cb = \&{"decode_$type"};
		*{"read_$type"} = sub {
			my $handle = shift;
			my $ber = "";
			my $x;
			do {
				$handle->read($x, 1);
				$ber .= $x;
			} while ( vec($x,7,1) );
			$cb->($ber);
		}
	}
}


use Git::DB::Float qw(float_to_intpair intpair_to_float);

sub encode_float {
	my $float = shift;

	join "",
		map { encode_int($_) }
			float_to_intpair( $float );
}

sub decode_float {
	my $ber_float = shift;
	intpair_to_float
		map { decode_int($_) }
			split /(?<=[\0-\177])/, $ber_float;
}

sub read_float {
	my $handle = shift;
	my $exp = read_int($handle);
	my $multiplicand = read_int($handle);
	intpair_to_float($exp, $multiplicand);
}

1;

__END__

=head1 NAME

Git::DB::Encode - encodings for the Git DB format

=head1 SYNOPSIS

 use Git::DB::Encode qw(:all);

 # -- Integers --
 # this is a version of pack("w", $int) which works on ints
 # of any size and sign.
 my $ber = encode_int($int);

 # similarly unpack("w", $ber)
 my $int = decode_int($ber);

 # a version that works on filehandles
 my $int = read_int($fh);

 # -- Strings --
 my $bytes = encode_string($string);

 my $string = decode_string($bytes);

=head1 DESCRIPTION



=cut

