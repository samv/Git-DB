
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
use IO::Handle;

use Git::DB::Defines qw(:int :float);

use Sub::Exporter -setup => {
	exports => [ qw(
		encode_text decode_text read_text
		encode_bytes decode_bytes read_bytes
		encode_int decode_int read_int
		encode_uint decode_uint read_uint
		encode_float decode_float read_float
		encode_decimal
	)],
};

sub encode_bytes {
	my $bytes = shift;
	encode_uint(bytes::length($bytes)).$bytes;
}

sub decode_bytes {
	my $bytes = shift;
	my ($num, $val) = split /(?<=[\0-\177])/, $bytes, 2;
	decode_uint($num) == length($val) or die;
	$val;
}

sub read_bytes {
	my $io = shift;
	my $length = read_uint($io);
	$io->read( my $buf, $length );
	$buf;
}

sub encode_text {
	my $text = shift;
	utf8::upgrade($text);
	encode_bytes($text);
}

sub decode_text {
	my $stream = shift;
	decode("utf8", decode_bytes($stream));
}

sub read_text {
	my $io = shift;
	decode("utf8", read_bytes($io));
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
	my $x = 0+shift;
	given ($x) {
		when ($_<0) {
			my $bnot = ~$x;
			my $b = ~_pack_w($bnot);
			if ( !vec(substr($b,0,1), 6, 1) ) {
				# would look positive, make longer
				#vec($x, 6, 1) = 0;
				$b = chr(0x7f).$b;
			}
			for (my $i=0;$i<length($b);$i++) {
				vec($b,$i*8+7,1)^=1;
			}
			return $b;
		}
		default {
			my $b = _pack_w($x);
			if ( vec(substr($b,0,1), 6, 1) ) {
				# would look negative, make longer
				#vec($x, 6, 1) = 0;
				return chr(0x80).$b;
			}
			else {
				return $b;
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

sub encode_decimal {
	my $num = shift;
	$num="$num";
	($num =~ s{e\+?(-?\d+)}{});
	my $scale = $1 || 0;
	$num =~ s{^(-?\d+)(?:\.(\d+))?$}{$1.($2||"")}e;
	$scale -= length $2 if defined $2;
	if ( $num =~ s{(0+)$}{} ) {
		$scale += length $1;
	}
	join "", encode_int($scale), encode_int($num);
}

sub encode_type {
	use integer;
	my $offset = shift;
	my $col_fmt = shift;
	if ($col_fmt > 15 or $col_fmt < 0) {
		die "type '$col_fmt' is invalid";
	}
	return encode_varint($offset * 16 | $col_fmt);
}

sub decode_type {
	use integer;
	my $string = shift;
	my $type = decode_varint($string);
	my $col_fmt = $type & 15;
	my $offset = $type / 16;
	return ($offset, $col_fmt);
}

sub read_type {
	use integer;
	my $io = shift;
	my $type = read_int($io);
	my $col_fmt = $type & 15;
	my $offset = $type / 16;
	return ($offset, $col_fmt);
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
 my $bytes = encode_text($string);

 my $string = decode_text($bytes);

=head1 DESCRIPTION



=cut

