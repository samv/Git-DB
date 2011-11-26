
package Git::DB::Util::CatPage;

use Moose;
use MooseX::Getopt;
use Git::DB::Defines qw(encode);
use Git::DB::Encode qw(read_int read_uint read_bytes read_type);
use Git::DB::Filenames qw(split_row_id_filename);
use Git::DB::ColumnFormat qw(column_format);
use boolean;

our $metaclass;
BEGIN {
        $metaclass = "MooseX::Getopt::Meta::Attribute";
}

has 'format' => (
        is => "ro",
        isa => "Str",
        default => "JSON",
        metaclass => $metaclass,
        cmd_aliases => [ "f" ],
);

has '_emit_func' => (
        is => "ro",
        isa => "CodeRef",
        default => sub {
                my $self = shift;
                no strict 'refs';
                my $require_name = "require_".lc($self->format);
                die "bad format '".$self->format."'"
                    unless defined &$require_name;
                $require_name->();
                my $func_name = "emit_".lc($self->format);
                return \&$func_name;
        },
        lazy => 1,
);

has 'tabledir' => (
        is => "ro",
        required => 0,
        isa => "Str",
        predicate => "has_tabledir",
        metaclass => $metaclass,
        cmd_aliases => [ "t" ],
);

use Fatal qw(:void open);

sub emit_row {
        my $self = shift;
        my @row = @_;
}

sub cat_page_file {
        my $self = shift;
        my $file = shift;
         my $input_fh;
        if ( -f $file ) {
                open $input_fh, $file;
        } else {
                open $input_fh, "-|", qw(git cat-file blob), "HEAD:$file";
        }
        binmode $input_fh;
        # FIXME - push this code into a PageFormat-type module
        if ( $self->has_tabledir ) {
                $file =~ s{^\Q$self->tabledir\E/?}{};
        }
         my @pk_cols = split_row_id_filename($file);
        $self->cat_page($input_fh, @pk_cols)
}

use constant EXPECT_COLUMN => do {
        my $a;
        for my $type_num ( 0..15 ) {
                if (column_format($type_num)) {
                        $a |= 1<<$type_num
                }
        }
        $a;
};

sub cat_page {
        my $self = shift;
        my $io = shift;
        my @pk_cols = @_;
        my ($next, $col_num, @row, $data_seen);
        my $new_row = sub {
                undef($next);
                $col_num = 0;
                @row = @pk_cols;
                undef($data_seen);
        };
        my @rows;
        my $end_row = sub {
                $self->emit_row(@row);
                $new_row->();
        };
        $new_row->();
        while ( ! eof $io ) {
                $data_seen = 1;
                if ( not $next ) {
                        my ($offset, $type) = read_type($io);
                        $col_num += $offset;
                        if ( EXPECT_COLUMN & (1<<$type) ) {
                                $next = column_format($type);
                        }
                        elsif ( $type == ENCODING_ROWLEFT ) {
                                my $bytes = read_uint($io);
                                # ... could skip ahead now, if scanning
                                # for now, ignore
                        }
                        elsif ( $type == ENCODING_EOR ) {
                                $end_row->();
                        }
                        elsif ( $type == ENCODING_RESET ) {
                                $col_num = 0;
                        }
                        else {
                                die "Unsupported column type '$type' "
                                    ."in row data";
                        }
                }
                else {
                        my $value = $next->read_col( $io );
                        $row[$col_num] = $value;
                        $col_num++;
                        undef($next);
                }
        }
        $end_row->() if $data_seen;
}

sub emit_row {
        my $self = shift;
        my @row = @_;
        $self->_emit_func->(@row);
}

sub require_json {
        require JSON;
        JSON->import("encode_json");
}
sub emit_json {
        print encode_json([\@_]);
}

sub require_yaml {
        no warnings 'once';
        if ( eval { require YAML::Any } ) {
                YAML::Any->import("Dump");
                $YAML::UseHeader = 0;
        }
        elsif ( eval { require YAML::XS } ) {
                YAML::XS->import("Dump");
                $YAML::XS::UseHeader = 0;
        }
        elsif ( eval { require YAML } ) {
                YAML->import("Dump");
                $YAML::UseHeader = 0;
        }
}
sub emit_yaml {
        print Dump([\@_]);
}

sub run {
        my $self = shift;
        my $files = $self->extra_argv;
        for my $file ( @$files ) {
                $self->cat_page_file($file);
        }
}

__END__

=head1 NAME

Git::DB::Util::CatPage - low-level display of gitdb row data

=head1 SYNOPSIS

 use Git::DB::Util::CatPage;

 my $script = Git::DB::Util::CatPage::new_with_options();
 $script->run();

=head1 DESCRIPTION

This program will take a list of filenames, which all must either
exist as files or in the index, and then print them out in the
selected format on stdout.



=cut

