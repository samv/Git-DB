
package Git::DB::Filenames;

use Sub::Exporter -setup => {
	exports => [qw(escape_val unescape_val
		       print_text scan_text
		       print_number scan_number
		       print_bool scan_bool
		     )],
	};

# various functions for converting row values to filenames.  The
# function names in this namespace correspond to the 'type_print_func'
# and 'type_scan_func' function names in the meta.type table

# 'escape_val' and 'unescape_val' are applied to all values before
# they are packed into a filename.
our %ESCAPE_ASCII;
our $DOUBLE_ESCAPE;
our $ESCAPE_ASCII_RE;
BEGIN {
	%ESCAPE_ASCII = map { $_ => 1 } qw( , / | \ - : );
	if ($ENV{GIT_DB_ESCAPE_CHARS}) {
		for my $char ( split "", $ENV{GIT_DB_ESCAPE_CHARS} ) {
			$ESCAPE_ASCII{$char}=1;
		}
	}
	#print STDERR "ESCAPE_ASCII = @{[keys %ESCAPE_ASCII]}\n";
	$ESCAPE_ASCII_RE = join("", map { m{[\\\-\[\]]} ? "\\$_": $_}
				 keys %ESCAPE_ASCII);
	$ESCAPE_ASCII_RE = qr/[$ESCAPE_ASCII_RE]/;
	print STDERR "ear = $ESCAPE_ASCII_RE\n";

	$DOUBLE_ESCAPE = "\\";
	if ( my $esc = $ENV{GIT_DB_DOUBLE_ESCAPE} ) {
		$DOUBLE_ESCAPE = "\x{244a}" unless $esc eq "\\";
	}
}
sub escape_val {
	my $string = shift;
	$string =~ s{
		([\x{ff00}-\x{ff5f}\x{2400}-\x{2421}\x{244a}])
	|	($ESCAPE_ASCII_RE)
	|	([\000-\037])
	|	(\177)
	}{
		($1 ? "$DOUBLE_ESCAPE$1" :
		 $2 ? chr(ord($2)+0xFEE0) :
		 $3 ? chr(ord($3)+0x2400) :
			 "\x{2421}" )
	}xeg;
	return $string;
}

sub unescape_val {
	my $string = shift;
	$string =~ s{
		[\\\x{244a}](.)
	|	([\x{ff00}-\x{ff5f}])
	|	([\x{2400}-\x{2420}])
	|	\x{2421}
	}{
		($1 ? $1 :
		 $2 ? chr(ord($2)-0xFEE0) :
		 $3 ? chr(ord($3)-0x2400) : "\177")
	}xeg;
	return $string;
}

# Perl's unicode support is pretty much good enough to do
# make these two identify functions.
sub print_text {
	my $text = shift;
	"$text";
}

sub scan_text {
	my $unescaped = shift;
	$unescaped;
}

# the %g sprintf format code is useful for automatically using
# e-notation as appropriate; you just need to know how many decimal
# digits of precision you have.
use Git::DB::Defines qw(MANTISSA_PRECISION);
use constant NUMBER_FORMAT => "%.".MANTISSA_PRECISION."g";
sub print_number {
	my $number = shift;
	sprintf(NUMBER_FORMAT, $number);
}

# Perl gives you sscanf as 0+
sub scan_number {
	my $unescaped = shift;
	0+$unescaped;
}

sub print_bool {
	my $bool = shift;
	$bool ? "t" : "f";
}

sub scan_bool {
	my $unescaped = shift;
	($unescaped eq "t" ? 1 :
	 $unescaped eq "f" ? '' : die "can't scan '$unescaped' as bool'");
}


1;
