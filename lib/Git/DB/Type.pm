
package Git::DB::Type;

use Moose;

use Sub::Exporter -setup => {
	exports => [ qw(register_type get_func) ],
};

has 'type_name' =>
	is => "ro",
	isa => "Str",
	required => 1,
	;

has 'type_formats' =>
	is => "ro",
	isa => "Int",
	required => 1,
	lazy => 1,
	default => \&_def_fmt,
	;

has 'choose_func' =>
	is => "ro",
	isa => "Maybe[Str]",
	lazy => 1,
	default => sub { _def_func($_[0], "choose_func", "_has_choose_func") },
	predicate => "_has_choose_func",
	;

sub has_choose_func {
	my $self = shift;
	$self->_has_choose_func && $self->choose_func;
}

has 'dump_func' =>
	is => "ro",
	isa => "Str",
	required => 1,
	lazy => 1,
	default => sub { _def_func($_[0], "dump_func") },
	;

has 'read_func' =>
	is => "ro",
	isa => "Str",
	required => 1,
	lazy => 1,
	default => sub { _def_func($_[0], "read_func") },
	;

has 'print_func' =>
	is => "ro",
	isa => "Str",
	required => 1,
	lazy => 1,
	default => sub { _def_func($_[0], "print_func") },
	;

has 'scan_func' =>
	is => "ro",
	isa => "Str",
	required => 1,
	lazy => 1,
	default => sub { _def_func($_[0], "scan_func") },
	;

has 'cmp_func' =>
	is => "ro",
	isa => "Str",
	required => 1,
	lazy => 1,
	default => sub { _def_func($_[0], "cmp_func") },
	;

use constant FUNCS => qw(choose dump read print scan cmp);

our (@VALID_TYPES, %VALID_TYPES);

# a simple type validator which does not support extension, but
# validates that functions are being called appropriately.
sub BUILD {
	my $self = shift;
	# needs to check self against @VALID_TYPES

	my $proposed_type_name = $self->type_name;
	my $type_def = $VALID_TYPES{$proposed_type_name};
	if ( !defined $type_def ) {
		die "unknown/illegal type '$proposed_type_name'";
	}
	elsif ( ref $type_def eq "SCALAR" ) {
		# chicken and egg case.
		undef($type_def);
	}

	for my $func ( FUNCS ) {
		my $func_func = "${func}_func";
		if ( my $proposed_func_name = $self->$func_func ) {
			next unless $type_def;
			my $supposed_func_name = $type_def->$func_func;
			if ( $proposed_func_name ne $supposed_func_name ) {
				die "'$proposed_func_name' set for $func_func, but I only allow '$supposed_func_name' for type '$proposed_type_name'";
			}
		}
	}

	return unless $type_def;

	my $def_formats = $type_def->type_formats;
	my $formats = $self->type_formats // $def_formats;
	if ( my $unknown = $formats & (~$def_formats) ) {
		my $bitwise = unpack("B*", pack("N", $unknown));
		my $bad_bit = length($bitwise) - index($bitwise, "1") - 1;
		die "My definition of '$proposed_type_name' can't do format $bad_bit";
	}
	my $bitwise = unpack("B*", pack("N", $formats));
	my $bits_set = $bitwise =~ tr/1/1/;
	if ( $bits_set == 0 ) {
		die "Invalid type definition for '$proposed_type_name'; no formats specified";
	}

	if ( !$self->has_choose_func ) {
		if ( $bits_set > 1 ) {
			die "Multiple formats specified in '$proposed_type_name', but no chooser function is available";
		}
	}
}

sub _def_func {
	my $self = shift;
	my $what = shift;
	my $pred = shift;
	my $def = $VALID_TYPES{$self->type_name};
	if ( !$def or ref $def eq "SCALAR" ) {
		# initial definition of a type
		if ( $pred ) {
			return;
		}
		else {
			die "what about '$what' in ".$self->type_name." ?";
		}
	}
	else {
		if ( $pred and !$def->$pred ) {
			return;
		}
		$def->$what;
	}
}

sub _def_fmt {
	my $self = shift;
	my $def = $VALID_TYPES{$self->type_name};
	if ( !$def or ref $def eq "SCALAR" ) {
		die "what about 'type_format' ?";
	}
	return $def->type_formats;
}

no strict 'refs';

sub register_type {
	my $pkg = shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my $type_name = shift;
	my $props = shift;

	$pkg ||= __PACKAGE__;

	my @opts = (
		type_name => $type_name,
		type_formats => $props->{formats},
	);

	for my $func ( FUNCS ) {
		if ( my $x = $props->{$func} ) {
			my ($func_name, $func_code) = @{ $x };
			*{"Git::DB::Func::$func_name"} = $func_code
				if $func_code;
			push @opts, "${func}_func" => $func_name;
		}
	}
	$VALID_TYPES{$type_name} = \undef;
	my $type = $pkg->new( @opts );
	push @VALID_TYPES, $type;
	$VALID_TYPES{$type_name} = $type;
}

sub get_func {
	my $pkg = shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my $func_name = shift or return undef;
	\&{"Git::DB::Func::$func_name"};
}

sub choose {
	my $self = shift;
	if ( $self->has_choose_func ) {
		get_func($self->choose_func)->(@_);
	}
	else {
		my $fmt = $self->type_formats;
		my $i = 0;
		while ( !( $fmt & 1 ) ) {
			$fmt >>= 1;
			$i++;
		}
		$i;
	}
}

BEGIN {
	for my $func ( FUNCS ) {
		next if $func eq "choose";
		my $func_func = "${func}_func";
		*$func = sub {
			my $self = shift;
			get_func($self->$func_func)->(@_);
		};
	}
}

1;

__END__

=head1 NAME

Git::DB::Type - Concrete Types in a Data Store

=head1 SYNOPSIS

=head1 DESCRIPTION

A Git::DB::Type describes a column type; roughly corresponding to the
function of the C<pg_types> table in Postgres.  It maps from the types
you use in for a column to the representations used in the row format.

Types are different to Classes, which are more like tables in a
traditional DB sense.  See L<Git::DB::Class> for information on those.
Some day, user-defined types may be classes, in which the value in the
column is a version of that object, and the value in the column on
disk is a nested row of that class.

There are a set of built-in types, and these do not need to be listed
explicitly in the schema section of the store; however, they can be
listed in order to to restrict the column formats for some datatypes,
if desired.

=head1 

=cut

