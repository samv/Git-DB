
package t::TestEncoder;

use base qw(Exporter);BEGIN { @EXPORT=(qw(test_encoder perl_print_string)) }
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
			"decode - $test_name test $num (0x$hex_digits)",
		       );
	}
}

sub perl_print_string {
	my $raw = shift;
	(my $perl_form = $raw)
		=~ s{([^\0-\177])}{"\\x"."{".sprintf("%x",(ord($1)))."}"}eg;
	$perl_form =~ s{([\0-\037\177])}{sprintf("\\%.3o",ord($1))}eg;
	#print STDERR "perl_print_string: $raw => $perl_form\n";
	return $perl_form;
}

1;
