#!/usr/bin/perl

use strict;
use Scriptalicious;
use Cwd;

=head1 NAME

podsucker.pl -  Suck pod

=head1 SYNOPSIS

 podsucker.pl [options] sourcedir [destdir]

=head1 DESCRIPTION

Extracts out all the POD from sourcedir and writes them to destdir.

=head1 COMMAND LINE OPTIONS

=over

=item B<-h, --help>

This help page

=back

=cut

my $srcdir = shift @ARGV or abort "need a source directory";
my $destdir = shift || "docs/pod";

my $cwd = cwd;
( chdir $destdir ) or barf "destination $destdir: $!";
$destdir=cwd;
chdir $cwd;
( chdir $srcdir ) or barf "source $destdir: $!";
$srcdir=cwd;

crawl(1, $srcdir, $destdir);

sub crawl {
  my ($depth, $srcdir, $destdir) = @_;

  unless (-e $srcdir) {
    barf "$srcdir doesn't exist" unless $srcdir and $destdir;
  }

  unless (-e $destdir) {
    mkdir $destdir || barf "can't mkdir $destdir: $!";
  }

  opendir(DIR, $srcdir) || die "can't opendir $srcdir: $!";
  my @contents = readdir(DIR);
  closedir(DIR);

  my @html = grep { /\.html$/ && -f "$srcdir/$_" } @contents;
  my @dirs = grep { !/^\./ && -d "$srcdir/$_" } @contents;

  #print STDERR join ", ", @dirs;
  #print STDERR "\n";

  undef $/;
  my $cwd = cwd;
  foreach (@html) {
    chdir $srcdir or die "can't chdir $srcdir: $!";
    open(FILE, $_) or die "can't open $_: $!";
    my $file = <FILE>;
    close(FILE);

    $file =~ m(<title>(.*)</title>);
    my $title = $1;
    my $top = "../" x $depth;
    $title =~ s{(['\\])}{\\$1}g;
    my $header = "[% top = '$top' %]\n[% title = 'POD: $title' %]\n[% INCLUDE header.tt %]\n";
    my $footer = "[% INCLUDE footer.tt %]\n";
    $file =~ s(.*<body>)($header)si;
    $file =~ s(</body>.*)($footer)si;

    chdir $destdir or die "can't chdir $destdir: $!";
    open(FILE, ">$_.tt") or die $!;
    print FILE $file;
    close(FILE);

    print STDERR "Created $destdir/$_.tt\n";

  }

  $depth++;
  foreach (@dirs) {
    print STDERR "crawl($depth, $srcdir/$_, $destdir/$_)\n";
    crawl($depth, $srcdir."/".$_, $destdir."/".$_);
  }
}

undef $/;
open(FILE, "$destdir/podtoc.html") or die "can't open podtoc.html: $!";
my $podtoc = <FILE>;
close(FILE);

$podtoc =~ s{</table>.*}{<table><tr><td colspan="2">&nbsp;</td></tr><tr><td class="PODTOC_NAME"><a class="POD_NAVLINK" href="podindex.html">Documentation index</a></td><td class="PODTOC_DESC"></td></tr></table>}s;
$podtoc =~ s{.*<table>}{}s;

open(FILE, ">".$destdir."/podtoc.tt") or die "can't open $destdir/podtoc.html: $!";
print FILE $podtoc;
close(FILE);
