
require Module::CoreList;
our @maybe_required;
for my $fn (sort keys %INC) {
        no strict 'refs';
        my $mod = $fn;
        $mod =~ s{\.pm$}{};
        $mod =~ s{/}{::}g;
        if ( defined ${$mod."::VERSION"} ) {
                my $core = Module::CoreList->first_release("$mod");
                if ( !$core or $core > 5.010 ) {
                        push @maybe_required,
                            [ $mod => ${$mod.'::VERSION'} ]
                }
        }
}

use FindBin;
my $modroot = $FindBin::Bin;
until ( -d "$modroot/lib" ) {
        $modroot =~ s{/[^/]+$}{};
}
for my $req (@maybe_required) {
        my ($mod, $version) = @$req;
        system("grep -rq \"use $mod\" $modroot/lib $modroot/bin");
        if ( $? ) {
                system("grep -rq \"use $mod\" $modroot/t");
                if ( !$? ) {
                        print "test_requires \"$mod\" => $version;\n";
                }
        }
        else {
                print "requires \"$mod\" => $version;\n";
        }
}
1;
