
package Git::DB::ColumnFormat;

use Moose::Role;

requires 'type_num';
requires 'to_row';
requires 'read_col';

1;

__END__

=head1 NAME

Git::DB::ColumnFormat - Role for column formats

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

This role and set of associated classes (C<Git::DB::ColumnFormat::*>)
represent the serialized form of columns in a data set.

These are slightly different from data types, which may be
user-defined.  A given data type may also map to multiple column
formats - for instance, a column of type Num may be stored as a float,
an integer, or a rational number.

Column Formats are a fixed part of the standard - however data types
are the real 

=cut

