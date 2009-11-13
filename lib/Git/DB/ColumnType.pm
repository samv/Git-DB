
package Git::DB::ColumnType;

use Moose::Role;

requires 'type_num';
requires 'to_row';
requires 'read_col';

1;

__END__

=head1 NAME

Git::DB::ColumnType - Role for numbered column types

=head1 SYNOPSIS

 # sub-class API
 package Git::DB::ColumnType::LengthDelimited;
 use Moose;
 use MooseX::Method::Signatures;
 with 'Git::DB::ColumnType';
 sub type_num { 2 };
 method to_row( $data ) {
     return BER(length($data)).$data;
 }
 method read_col( IO::Handle $data ) {
     my $length = read_ber_int($data);
     my $data = read($data, $length);
     return $data;
 }

=head1 DESCRIPTION



=cut

