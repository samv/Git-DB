
package Git::DB::ColumnFormat::LOB;

use Mouse;

#use Git::DB::RowFormat qw(read_charz);
#use Git::DB::Index qw(write_blob add_index_entry get_index_oid);

extends 'Git::DB::ColumnFormat::Bytes';

sub type_num { 7 };

has 'lob_dir' =>
	is => "rw",
	isa => "Str",
	default => "/_lobs",
	;

has 'lob_width' =>
	is => "rw",
	isa => "Int",
	default => 12,
	;

has 'lob_fanout' =>
	is => "rw",
	isa => "Int",
	default => 2,
	;

sub write_blob {
	my $data = shift;
	#...
}

sub read_blob {
	my $oid = shift;
	#
}

sub register_blob {
	my $oid = shift;
	#...
}

around to_row => sub {
	my $orig = shift;
	my $self = shift;
	my $data = shift;
	if ( blessed $data and $data->isa("Git::DB::LOB") ) {
		$self->$orig($data->hash);
	}
	else {
		# write out object and return $oid
		my $oid = write_blob($data);

		#... ok so we will need these passed in ...
		my $row = shift;
		my $column = shift;
		# ... wave hands ...
		register_blob($oid, $row, $column);

		$self->$orig($oid);
	}
};

around read_col => sub {
	my $self = shift;
	my $data = shift;
	my $oid = super($data);
	return Git::DB::LOB->new(hash => $oid);
};

with 'Git::DB::ColumnFormat';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::LOB - Large OBject

=head1 DESCRIPTION

A representation to allow for columns which are just too bloody big to
go in the regular row store.

They are stored in the git store without any extra headers or
suchlike, and by default placed under eg '/_lobs/ab/cdef123455', where
the hex ID is the ID of the actual git blob (the leading digits).
Collisions are detected, but there is not necessarily a guarantee that
the filename stored under will uniquely identify the LOB.

=cut

