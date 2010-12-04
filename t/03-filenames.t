#!/usr/bin/perl

BEGIN { binmode STDOUT, ":utf8"; binmode STDERR, ":utf8"; }
use Test::More no_plan;
use strict;
use warnings;

BEGIN{ use_ok("Git::DB::Filenames", ":all") }
use Git::DB::Defines qw/MANTISSA_BITS/;
use Math::BigRat;
use Encode;

my @NUM_TESTS = (
	1234, "1234",
	-1, "-1",
	1.234, "1.234",
	1e23, "1e+23",
	1.2, "1.2",
	-0.000016, "-1.6e-05",
	Math::BigRat->new("123812/7"), qr/^17687\.42/,
);

while ( my ($num, $filename) = splice @NUM_TESTS, 0, 2 ) {

	my $fn_form = print_number($num);
	if ( $filename =~ m{^\(} ) {
		like($fn_form, $filename, "print_number: $num");
	}
	else {
		is($fn_form, $filename, "print_number: $num");
		$fn_form = $filename;
	}
	my $rescan = scan_number($fn_form);
	my $diff = abs($rescan - $num);
	if ( $diff / $num < 2**-(MANTISSA_BITS-5) ) {
		pass("scan_number: $fn_form");
	}
	else {
		is($rescan, $num, "scan_number: $fn_form");
		diag("difference/num = ".($diff/$num));
	}
}

is(print_bool(1), "t", "print_bool: 1");
is(print_bool(0), "f", "print_bool: 0");
is(scan_bool("f"), "", "scan_bool: f");
is(scan_bool("t"), "1", "scan_bool: t");

# print_text and scan_text are no-ops atm; will add tests when there
# is logic to test (eg utf8 validity)

my @TEXT_TESTS = (
	"-1", "\x{ff0d}1", "negative int",
	"-1e-23", "\x{ff0d}1e\x{ff0d}23", "negative tiny number",
	"1234", "1234", "normal text",
	"\0", "\x{2400}", "ASCII NUL",
	"foo-bar", "foo\x{ff0d}bar", "text with hyphen",
	"foo/bar", "foo\x{ff0f}bar", "text with slash",
	"foo\bar", "foo\x{2408}ar", "text with backspace",
	'foo\bar', "foo\x{ff3c}bar", "text with backslash",
	"foo\x{ff3c}bar", "foo\\\x{ff3c}bar",
		"text with fullwidth backslash",
	',', "\x{ff0c}", "comma",
	'|', "\x{ff5c}", "pipe", # this is not a pipe!
	':', "\x{ff1a}", "colon",
	"\r", "\x{240d}", "carriage return",
	"\t", "\x{2409}", "horizontal tab",
	"\177", "\x{2421}", "delete char",
	"\x{2400}", "\\\x{2400}", "ASCII control representation",
	"\x{2401}", "\\\x{2401}", "ASCII control representation",
	"\x{2420}", "\\\x{2420}", "ASCII control representation",
	"\x{2421}", "\\\x{2421}", "ASCII control representation",
	"\x{ff01}", "\\\x{ff01}", "Fullwidth form",
	"\x{ff25}", "\\\x{ff25}", "Fullwidth form",
	"\x{244a}", "\\\x{244a}", "Unicode escape character",
);

sub perl_print_string {
	my $raw = shift;
	(my $perl_form = $raw)
		=~ s{([^\0-\177])}{"\\x"."{".sprintf("%x",(ord($1)))."}"}eg;
	$perl_form =~ s{([\0-\037\177])}{sprintf("\\%.3o",ord($1))}eg;
	#print STDERR "perl_print_string: $raw => $perl_form\n";
	return $perl_form;
}

while ( my ($raw, $cooked, $label) = splice @TEXT_TESTS, 0, 3 ) {
	my $safe = perl_print_string($raw);
	my $fn_form = escape_val($raw);
	is(perl_print_string($fn_form),
	   perl_print_string($cooked), "escape_val: $label ($safe)");
	my $uncooked = unescape_val($cooked);
	is(perl_print_string($uncooked),
	   $safe, "unescape_val: $label ($safe)");
}

# The type for the primary key of a given table is translated to a set
# of transform functions, via the types information.

# In this test, we supply pre-mapped lists of functions, and test the
# marshalling of types to columns.

use utf8;
my @SPLIT_TESTS =
	({ scan => [ qw(scan_number scan_text scan_text) ],
	   print => [ qw(print_number print_text print_text) ],
	   examples => [
		   [ "42,foo,bar", 42, "foo", "bar" ],
		   [ "－1.6e－05,：q!,／， fiddle",
		     -0.000016, ":q!", "/, fiddle" ],
	   ]},
	 { scan => [ qw(scan_number scan_bool) ],
	   print => [ qw(print_number print_bool) ],
	   examples => [
		   [ "－inf,t", 0+"-inf", 1 ],
		   [ "nan,f", 0+"nan", "" ],
	   ]},
    );

for my $test_set ( @SPLIT_TESTS ) {
	for my $example ( @{ $test_set->{examples} } ) {
		my $filename = shift @{ $example };
		my @split = split_row_id_filename(
			$test_set->{scan},
			$filename,
		);
		my $safe = perl_print_string($filename);
		is_deeply(\@split, $example, "split ($safe)");
		my $repacked = make_row_id_filename(
			$test_set->{print},
			@$example,
		);
		is(perl_print_string($repacked),
		   perl_print_string($filename),
		   "repack ($safe)");
	}
}
