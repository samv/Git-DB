
package Git::DB::ColumnFormat::LOB;

use Moose;

#use Git::DB::RowFormat qw(read_charz);
#use Git::DB::Index qw(write_blob add_index_entry get_index_oid);

use Git::DB::Encode qw(encode_uint read_uint read_str);

use Git::DB::Defines qw(ENCODE_LOB);

sub type_num { ENCODE_LOB };

use bytes;

sub write_col {
	my $inv = shift;
	my $io = shift;
	my $data = shift;
	my $extra = shift;

	my $blobid;
	if ( blessed $data and $data->can("git_db_blobid") ) {
		$blobid = $data->git_db_blobid;
	}
	else {
		# not already encoded..
		my ($store, $row, $col_idx)
			= $extra->("store", "row", "column_idx");

		$blobid = join ",",
			$store->rowid_filename($row), $col_idx;

		my ($schema_idx, $class_idx)
			= $extra->("schema_idx", "class_idx");

		my $lob = Git::DB::LOB->new(
			blobid => $blobid,
			data => $data,
			schema_idx => $schema_idx,
			class_idx => $class_idx,
		);
		$store->insert($lob);
	}
	print { $io } encode_uint(length($blobid)),
		$blobid;
}

sub read_col {
	my $inv = shift;
	my $io = shift;
	my $extra = shift;
	my ($schema_idx, $class_idx, $store)
		= $extra->("schema_idx", "class_idx", "store");
	my $length = read_uint($io);
	my $blobid = read_str($io);
	Git::DB::LOB->new(
		blobid => $blobid,
		store => $store,
		schema_idx => $schema_idx,
		class_idx => $class_idx,
	);
}

with 'Git::DB::ColumnFormat';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat::LOB - Large OBject

=head1 DESCRIPTION

A representation to allow for columns which are just too bloody big to
go in the regular row store.

It has custom write and read rules which lazily marshall the value
through the L<Git::DB::LOB> class to storage and back.

=cut

