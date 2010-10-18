
package Git::DB::ColumnFormat::Object;

use Moose;
use MooseX::Method::Signatures;
with 'Git::DB::ColumnFormat';

use Git::DB::RowFormat qw(read_charz);
use Git::DB::Index qw(write_blob add_index_entry get_index_oid);

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

method to_row( $data ) {
	if ( ref $data and $data->isa("Git::DB::BOD") ) {
		$data->path."\0";
	}
	else {
		#... generate LOB path ...
		my $oid = write_blob($data);
		my $short_oid = substr $oid, 0, $self->lob_width;
		my $generated_path =
			join("/", $self->lob_dir,
			     substr($short_oid, 0, $self->lob_fanout),
			     substr($short_oid, $self->lob_fanout) );
		my $w = $self->lob_width;
		my $found;
		while ( $found = get_index_oid($generated_path) ) {
			if ( $found ne $oid ) {
				$generated_path .= substr($oid, $w++, 1);
			}
			else {
				goto ok;
			}
		}
		add_index_entry($generated_path, $oid) unless $found;
	ok:
		"$generated_path\0";
	}
}

method read_col( IO::Handle $data ) {
	my $path = read_charz($data);
	return Git::DB::BOD->new(path => $path);
}

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

