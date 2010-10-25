#!/usr/bin/env perl

use Scriptalicious
    -progname => 'update-pod';

=head1 NAME

update-pod.pl - update POD on intranet

=head1 SYNOPSIS

update-pod.pl [options]

=head1 DESCRIPTION

Builds all of the Perl module documentation for a set of modules
found under a path into a directory.

=head1 COMMAND LINE OPTIONS

=over

=item B<-h, --help>

Display a program usage screen and exit.

=item B<-V, --version>

Display program version and exit.

=item B<-v, --verbose>

Verbose command execution, displaying things like the
commands run, their output, etc.

=item B<-q, --quiet>

Suppress all normal program output; only display errors and
warnings.

=item B<-d, --debug>

Display output to help someone debug this script, not the
process going on.

=back

=cut

use strict;
use warnings;
our $VERSION = '1.00';

use constant ROOT    => "/docs";
use constant CSS     => "/styles/pod.css";
use File::Find;
use Pod::Html;

#---------------------------------------------------------------------
#  scan_podules(PATH) : LIST
# Scans a given path for .pod and .pm files, not returning .pm files
# where a corresponding .pod exists
#---------------------------------------------------------------------
sub scan_podules {
    my $base = shift;
    my @pod_files;
    find( sub {
	      (my $relative = $File::Find::name) =~ s{^\Q$base\E/}{};
	      if ( /^blib$/ ) {
		  $File::Find::prune = 1;
	      }
	      elsif ( /^.*\.pod\z/s ) {
		  push @pod_files, $relative;
	      }
	      elsif ( /^.*\.pm\z/s ) {
		  (my $pod_file = $_) =~ s{pm$}{pod};
		  if ( -f $pod_file ) {
		      whisper "skipping $_ - .pod file exists";
		  } else {
		      push @pod_files, $relative;
		  }
	      }
	  }, map { "$base/$_" } @_);
    @pod_files;
}

#=====================================================================
#  MAIN SECTION STARTS HERE
#=====================================================================
my $modules_dir = ".";
my $output_dir  = "pod";
getopt("modules|m=s" => \$modules_dir,
       "output|o=s"  => \$output_dir,
      );

#chdir(MODULES) or abort "failed to change to ${\(MODULES)}; $!";

my @dirs;
if (!@ARGV) {
    @dirs = glob("$modules_dir/*/lib");
} else {
    while ( my $dir = shift ) {
        if ( -d "$modules_dir/$dir" )  {
            push @dirs, $dir."/lib";
        } else {
            abort "$dir is not a directory";
        }
    }
}
say "scanning for Perl modules in $modules_dir: @dirs";

my @pod_files = scan_podules($modules_dir, @dirs);

say "extracting POD from ".@pod_files." file(s)";
for my $pod_file ( @pod_files ) {
    say "processing $pod_file";

    (my $dest_file = $pod_file) =~ s{\.(pod|pm)$}{.html};
    $dest_file =~ s{.*/lib/}{};

    if ( $dest_file =~ m{/} ) {
	(my $dirname = $dest_file) =~ s{/[^/]*$}{};
	$dirname = $output_dir."/".$dirname;

	( -d $dirname ) or run "mkdir", "-p", $dirname;
    }

    pod2html( "--htmlroot=".ROOT,
	      "--css=".CSS,
	      "--libpods=perlfunc:perlguts:perlvar:perlrun:perlop",
	      "--infile=".$modules_dir."/".$pod_file,
	      "--outfile=".$output_dir."/$dest_file",
	    );
}

