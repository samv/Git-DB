
package Git::DB::Encode;

# this module provides functions for marshalling data types to byte
# streams.

use bytes;
use Encode;
use utf8;
use 5.010;

use Sub::Exporter -setup => {
	exports => [qw(to_bytes from_bytes encode_BER
		       decode_BER read_BER)],
	};

# utf-8 or nothing for this module
sub to_bytes {
	my $str = shift;
	if ( utf8::is_utf8 ) {
		Encode("utf8", $str);
	}
	else {
		$str;
	}
}

# but alway return in utf8
sub from_bytes {
	my $str = shift;
	utf8::upgrade($str);
	$str;
}

use Math::BigInt try => "GMP";
#use Math::BigInt;
use Scalar::Util qw(blessed);

use constant MAX_INT => (-1<<1)+1;
use constant MAX_NEG => (MAX_INT>>1)+1;
use constant MAX_NV_INT => 2**52;

sub _pack_w {
	my $num = shift;
	if ( abs($num) > MAX_NV_INT and blessed($num) ) {
		pack("w", "$num");
	}
	else {
		pack("w", $num);
	}
}

# a bit like Perl's pack("w", "*") but always packs a 2's complement
# number.
sub encode_BER {
	my $x = shift;
	given ($x) {
		when ($_<0) {
			my $bnot = ~$x;
			my $x = ~_pack_w($bnot);
			if ( !vec($x, 6, 1) ) {
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
			if ( vec($x, 6, 1) ) {
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

sub decode_BER {
	my $ber = shift;
	my $neg = vec($ber,6,1);
	if ( $neg ) {
		$ber = ~$ber;
		for (my $i=0;$i<length($ber);$i++) {
			vec($ber,$i*8+7,1)^=1;
		}
		my $num = unpack("w", $ber);
		if ( $num > abs(MAX_NEG)-1 ) {
			$DB::single = 1;
			return Math::BigInt->new("-$num")-1
		}
		else {
			return -$num-1;
		}
	}
	else {
		 my $num = unpack("w", $ber);
		 if ( $num > MAX_INT ) {
			 return Math::BigInt->new($num)
		 }
		 else {
			 return $num;
		 }
	 }
}

sub read_BER {
	my $handle = shift;
	my $ber = "";
	do {
		$handle->read(my $x, 1);
		$ber .= $x;
	} while ( vec($x,7,1) );
	decode_BER($ber);
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
 my $ber = encode_BER($int);

 # similarly unpack("w", $ber)
 my $int = decode_BER($ber);

 # a version that works on filehandles
 my $int = read_BER($fh);

 # -- Strings --
 my $bytes = to_bytes($string);

 my $string = from_bytes($bytes);

=head1 DESCRIPTION



=cut

