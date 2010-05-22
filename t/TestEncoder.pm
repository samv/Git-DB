
package TestEncoder;

use base qw(Exporter);BEGIN { @EXPORT=(qw(test_encoder)) }
use strict;

# eevil prototypes
sub test_encoder(&&@) {
	my $encode_sub = shift;
	my $decode_sub = shift;
	my $skip_sub;
	if ( ref $_[0] ) {
		$skip_sub = shift;
	}
	my @TESTS = @_;
	my $test_name = pop @TESTS if @TESTS & 1;
	$test_name ||= join(":",((caller)[1,2]));

	my $num = 0;
	while ( my ($encoded, $value) = splice @TESTS, 0, 2 ) {

		++$num;
		next if $skip_sub and $skip_sub->($encoded, $value);

		(my $hex_digits = $encoded) =~ s{0x}{};
		my $binary = pack("H*", $hex_digits);

		main::is(
			lc(unpack("H*",$encode_sub->($value))),
			lc($hex_digits),
			"encode - $test_name test $num ($value)",
		       );

		main::is_deeply(
			$decode_sub->($binary),
			$value,
			"decode - $test_name test $num ($hex_digits)",
		       );
	}
}

1;
