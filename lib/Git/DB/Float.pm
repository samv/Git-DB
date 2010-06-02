
package Git::DB::Float;

# this package prototypes the float to signed BER int conversion.

#  eg 0

# here's the idea:
#  - convert mantissa and exponent to BER ints
#  - sign of mantissa is stripped
#  - remaining number is real mantissa bits

use strict;
use constant DEBUG => 1;
our $ieee64_bs;
use POSIX qw(ceil);
use Git::DB::Defines qw(MANTISSA_BITS MANTISSA_2XXBITS);

sub intpair_to_float {
	my ($exp, $mant) = @_;
	if ( $mant == 0 ) {
		if ( $exp ) {
			if ( $exp == 1 ) {
				return "inf";
			}
			elsif ( $exp == -1 ) {
				return "-inf";
			}
			else {
				"nan";
			}
		}
		else {
			0;
		}
	}
	else {
		$mant * 2**$exp;
	}
}

sub mant_pow { MANTISSA_2XXBITS/(2**$_[0]) }
use Memoize;
use POSIX qw(floor);
memoize qw(mant_pow);

sub float_to_intpair {
	my $num = shift;
	my $sign = $num < 0;
	$num = abs($num);
	if ( $num == 0 ) {
		return (0, 0);
	}
	elsif ( $num >= "inf" ) {
		return ($sign ? -1 : 1, 0);
	}
	elsif ( $num != $num ) {
		return (2, 0);
	}
	else {
		my $scale = int(log($num) / log(2));
		$num = $num * mant_pow($scale);
		my $exp = int($scale) - MANTISSA_BITS;
		#$num *= 2**(-$exp);
		while ( int($num) != $num ) {
			#print STDERR "Had to make num bigger: $num\n";
			$num *= 2;
			$exp --;
		}
		#this might not work on all number platforms ... FIXME
		while ( floor( ($num+254)/256 ) == int($num/256) ) {
			#print STDERR "Had to make num smaller (bigeven): $num\n";
			$num /= 256;
			$exp += 8;
		}
		while ( int( ($num+1)/2 ) == int($num/2) ) {
			#print STDERR "Had to make num smaller (even): $num\n";
			$num /= 2;
			$exp ++;
		}
		return ($exp, $sign?-$num:$num);
	}
}

use Sub::Exporter -setup => {
	exports => [qw{float_to_intpair intpair_to_float}],
};

1;

__END__

=for later redevelopment in XS, the first idea - use ieee64 and ieee128.

sub float_to_intpair_pack {
	my $num = shift;
	my $ieee64 = pack("d", $num);

	$ieee64_bs = unpack("B*", pack("d>", $num));

	my $sign = vec($ieee64, 63, 1);
	if ( DEBUG ) {
		 print STDERR "SIGN $sign\n";
	}

	my ($IP_exp, $IP_mantissa);
	my ($IP_exp_str, $IP_mantissa_str);

	my $exp = (
		(vec($ieee64, 7, 8) & 127) << 4
			| (vec($ieee64, 6, 8) >> 4)
		       );

	my $exp_bs = substr($ieee_bs,1,11);
	my $via_oct = oct("0b$exp_bs");
	my $diff = $via_oct - $exp;

	print STDERR "EXP $exp_bs => unsigned: $via_oct"
		.($diff ? "( via vec: ".$exp.", diff = $diff)"
			  : "")."\n" if DEBUG;

	# we get 53 bits of mantissa from a double.
	my @mantissa = (
		# vec($x, N, X where { X > 8 }) is apparently
		# big-endian on little endian machines.
		(vec($ieee64, 6, 8) & 0xf)<<16 |
			(vec($ieee64, 5, 8) <<8) |
				(vec($ieee64, 4, 8) ),
		(vec($ieee64, 3, 8) <<24) |
			(vec($ieee64, 2, 8) <<16) |
				(vec($ieee64, 1, 8) <<8) |
					(vec($ieee64, 0, 8) ),
	       );

	my $mant_bs = substr($ieee_bs,53,16);
	print STDERR "MANT $mant_bs => unsigned: ".
		unpack("B*",$mant_bs)."\n" if DEBUG;

	# if a "real" mantissa is passed in, encode it.
	my $mantissa;

	if ( $exp == 0x7ff ) {
		# inf.
		if ( $sign ) {
			# -inf - ignore other bits
			# code as 0xff40 + 00
			$IP_exp_str = "\377\100";
			$IP_mantissa_str = "";
		}
		elsif ( $mant_bs =~ /^1/ ) {
			# q. nan - ignore other bits
			# code as 0x8001
			$IP_exp_str = "\200\101";
			$IP_mantissa_str = "";
		}
		elsif ( $mant_bs =~ /^1(.*)/ ) {
			# code as 0x8002 + mantissa
			# s. nan - encode mantissa
			$IP_exp_str = "\200\102";
			$mantissa = $1;
		}
		else {
			# +inf
			# code as 0x8000 + 00
			$IP_exp_str = "\200\100";
			$IP_mantissa_str = "";
		}
	}
	elsif ( $exp == 0 ) {
		# subnormal number
		$mantissa = $mant_bs;
		$IP_exp = 0;
	}
	else {
		# regular number - add the missing mantissa bit
		$mantissa = "1".$mant_bs;
		$IP_exp = $exp - 1023;
	}

	if ( defined $mantissa ) {
		# negative numbers - convert to 2's complement
		if ( $sign ) {
			# subtract 1... ok this is just silly
			for ( my $bit = length $mantissa - 1;
			      $bit >= 0;
			      $bit--;
			     ) {
				if ( substr($mantissa, $bit, 1) eq "1" ) {
					substr($mantissa, $bit, 1) = "0";
					last;
				}
				else {
					substr($mantissa, $bit, 1) = "1";
				}
			}
			# if there was a carry all the way, chop off
			# the extra 0
			$mantissa =~ s{^0}{};
			# before negating
			$mantissa =~ tr{01}{10};
		}

		# unbias the exponent.  This handles subnormals "fine"
		$exp -= 1023;

		# next, get rid of unnecessary precision.  "pad out"
		# first.
		if ( $IP_exp ) {
			$mantissa .= "0"x6;
			$IP_exp -= 6;
			$mantissa =~ s{^((?:.{7})+)?(0*)$}{$1};
			$IP_exp += length $2;
		}
	}

	if ( !defined $IP_exp_str ) {
		$IP_exp_str = encode_BER($IP_exp);
	}

	if ( !defined $IP_mantissa_str and defined $mantissa ) {
		my @sevens = $mantissa =~ m{(.{7})};
		$IP_mantissa_str = join(
			"",
			(map { oct("0b1".$_) } @sevens[0..$#sevens-1]),
			(map { oct("0b".$_) } $sevens[-1]),
		       );
	}

	($IP_exp_str, $IP_mantissa_str);
}

sub decode_quad_float {
	my $ieee128 = shift;
	if ( QUAD_FORMAT ) {
		unpack(QUAD_FORMAT, $num);
	}
	else {
		if ( DOUBLE_FORMAT eq "d>" ) {
			# little endian, need to swap bytes around for
			# vec(), though annoyingly it always uses big
			# endian when using chunk sizes > 8
			$ieee128 = reverse $ieee128;
		}
		$DB::single = 1;
		my $sign = vec($ieee128, 127, 1);
		my $exp = vec($ieee128, 15, 8) & 0x7f |
			vec($ieee128, 14, 8);
		my @mantissa = map {
			vec($ieee128, 2-$_, 32)
		} 0..2;
		$mantissa[0] &= 0xffff;
		print STDERR sprintf(
			"input: ".unpack("H*",$ieee64)
				." - sign: $sign exp: %x mant: %x %x\n",
			$exp, @mantissa,
		       );
		if ( $exp == 0x7fff ) {
			$exp = 0x7ff;
		}
		else {
			$exp = ($exp ? $exp + 16383 - 1023 : 0);
			if ( $exp < -52 ) {
				# underflow to 0
				return 0;
			}
			elsif ( $exp >= 0x7ff ) {
			overflow_out:
				# overflow
				return 0+($sign ? "-inf" : "inf");
			}
			# apply default rounding rule on lost bits
			my $frac = $mantissa[2] & 0xf0;
			my $round_up = $frac > 0x80 ||
				$frac == 0x80 && vec($double, 0, 1);
			# add with carry...
			if ( $round_up ) {
				add32_with_carry(\@mantissa, 0x100);
				if ( $mantissa[0] & 0x10000 ) {
					$mantissa[0] -= 0x10000;
					goto overflow_out
						if ++$exp >= 0x7ff;
				}
			}
		}
		my $double = "\0" x 8;
		vec($double, 7, 8) = ($sign ? 0x80 : 0) | $exp >> 4;
		vec($double, 6, 8) = ($exp & 0xf) << 8
			| $mantissa[0] >> 8;
		vec($double, 2, 16) = $mantissa[0] & 0xff
			| $mantissa[1] >> 24;
		vec($double, 0, 32) = $mantissa[1] & 0xffffff
			| $mantissa[2] >> 24;

		unpack("d", $double);
	}
}

=cut

1;

