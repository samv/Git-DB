# -*- perl -*-
#
#  Test utility module to set up a Git DB repository for testing.  The
#  repository it sets up will be more and more sophisticated as time
#  goes on...

package t::TestDB;
use File::Path qw(make_path remove_tree);

our $repo_path;
our $bare;

sub import {
        my $class = shift;
        $bare = grep m{bare}, @_;
        ($repo_path = $0) =~ s{\.t$}{} or die;
        $repo_path =~ s{.*/}{};
        $repo_path = "t/$repo_path";
        remove_tree($repo_path) if ( -d $repo_path );
        make_path($repo_path.($bare?"":"/.git"));
        system("GIT_DIR=$repo_path git init >/dev/null");
        make_test_files()
}

sub make_file {
        my $filename = shift;
        my @hex_data = split "\n", shift;
        my $fh;
        if ( $bare ) {
                die "bare not supported yet...";
        }
        else {
                ($path = $filename) =~ s{/[^/]*$}{};
                ( -d "$repo_path/$path" ) or
                    make_path("$repo_path/$path");
                open $fh, ">", "$repo_path/$filename";
                binmode $fh;
        }
        while ( my $line = shift @hex_data ) {
                my $data = substr $line, 12, 39;
                $data =~ s{\s}{}g;
                print { $fh } pack("H*", $data);
        }
        close $fh;
}

sub make_test_files {
        make_file(
                "meta/schema/http：／／github.com／samv／Git-DB,0.1",
                <<HEX
  00000000  021d 6874 7470 3a2f 2f67 6974 6875 622e  ␂␝http://github.
  00000010  636f 6d2f 7361 6d76 2f47 6974 2d44 4203  com/samv/Git-DB␃
  00000020  7f01 0204 6d65 7461                      ␡␁␂␄meta
HEX
            );
}

END {
        unless ( $ENV{KEEP} ) {
                remove_tree($repo_path);
        }
};

1;
