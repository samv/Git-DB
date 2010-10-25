#!/usr/bin/env perl

use 5.008005;

use strict;
use warnings;
use File::Find;
use FindBin qw($Bin);
use Storable qw(dclone);
use Getopt::Long;

BEGIN { chdir("$Bin/.."); ( -d "var" or mkdir "var", 0777) }

use Template;
use MooseX::TimestampTZ qw(gmtimestamptz);
use threads;
use threads::shared;
#use XML::Atom::SimpleFeed;
use autodie;

GetOptions(
	"d|delete" => \(my $delete),
	"j|jobs" => \(my $threads),
	);

our $last_runo = (stat("update-templates.stamp"))[9];

our @libs = map { s{lib/}{}; $_ } glob("lib/*.tt");
our %libs = map { $_ => (stat "lib/$_")[9] } @libs;
our @ext  = qw(html css js);
our $ext_re = qr{(${\(join "|", @ext)})};

our $name_transform = sub {
  my $dest = shift;
  if ($dest =~ s{\.tt$}{}) {
    if ($dest !~ m{\.$ext_re}) {
      $dest .= ".html";
    }
  }
  $dest;
};

our @templates;
our @templates_new;
share(@templates_new) if $threads;

our (%mod_time, %post_time);
share(%mod_time);
share(%post_time);

sub wanted {
  ($File::Find::prune=1), return if $_ eq "lib" or $_ eq "var";
  return unless m{\.tt$};

  my $src = $File::Find::name;
  $src =~ s{^\./}{};
  my $dest = $name_transform->($src);
  push @templates, [ $src => $dest ];
}

find(\&wanted, ".");

if ($delete) {
  unlink map { $_->[1] } @templates;
  exit;
}

@templates = sort { $a->[0] cmp $b->[0] } @templates;
for my $t (@templates) {
  my $dest_mtime = (stat $t->[1])[9];
  my $src_mtime = (stat $t->[0])[9];
  if ( !$dest_mtime or $src_mtime > $dest_mtime
       or grep { $_ > $dest_mtime } values %libs ) {

    push @templates_new, @$t;

  }
}

my $config =
  { INCLUDE_PATH => ".:lib",
    INTERPOLATE  => 0,
    POST_CHOMP   => 0,
    PRE_PROCESS  => "config.tt",
    PROCESS      => "layout.tt",
    OUTPUT_PATH  => ".",
    COMPILE_DIR  => "var",
    FILTERS      =>
    {
	autobr => sub {
	    my $x = shift; $x =~ s{\r?\n\r?\n(?!(?i:<p))}{\n<p>}gs; $x;
	},
	autotrim => sub {
	    my $x = shift;
	    # trim to 1200 chars... on word boundaries
	    my $trimmed = $x =~ s{\A(.{0,600})[ \t.,;:!-?\n\r/|()]\s*\S.*}{$1}s;
	    # trim off partial XML entities
	    $x =~ s{<[^>]*\Z}{}s;
	    $x =~ s{&\w+\Z}{};
	    # then balance tags
	    my @stack;
	    my @debug;
	    my $count;
	    while (scalar($x =~ m{\G<(/?)(\w+)[^/>]*(/?)\s*>|<!--.*?-->|[^<]*}gs)) {
		$count++;
		my ($close,$tag,$empty)=($1,$2,$3);
		next if $empty;
		next unless $tag;
		push @debug, "<$close$tag>";
		if ($close) {
		    if (!grep { $_ eq $tag } @stack) {
			# ... pfft, ignore...
			next;
		    }
		    until (@stack and $stack[-1] eq $tag) {
			pop @stack;
		    }
		    pop @stack;
		}
		else {
		    push @stack, $tag;
		}
		push @debug, "(@stack)";
	    }
	    $x.(@stack? join("", "\n<!-- balancing tags follow -->",
			     (map { "</$_>" } grep !/^(p)$/i, reverse @stack),
			     "<!-- end of balancing tags -->"):"")
		.($trimmed?"<!--<...>-->":"");

	},
    },
  };

my $html_template = Template->new($config);
my $vars =
  {
   templates => \@templates,
  };
my %functions =
    ( mod_time => \&mod_time,
      post_time => \&post_time,
      new_feed => \&new_feed,
      add_to_feed => \&add_to_feed,
    );

delete $config->{PROCESS};
my $other_template = Template->new($config);

my $process_template_sub = sub {
	my ($src, $dest) = @_;
	return undef if not $src;
	print " [tt] $src => $dest\n";
	my $v = dclone($vars);
	%$v = (%$v, %functions);
	$v->{topdir} = ("../" x ($dest =~ tr{/}{/}));
	$v->{link} = sub {
		my $filename = shift;
		if ( ! -f $filename && ! -f "$filename.tt" ) {
			warn "bad link in $src to $filename\n";
			$v->{topdir}."err/404.html";
		}
		else {
			$v->{topdir}.$name_transform->($filename);
		}
	};
	my $template = $dest =~ m{\.(html|php)$} ?
		$html_template : $other_template;
	$template->process($src, $v, $dest)
		or die $template->error, "\n";
};

$| = 1;
print "Processing ".(@templates_new/2)." templates\n";
if ( $threads ) {
	my @thr;
	for my $threadid (1..$threads) {
		push @thr, threads->create(
			sub {
				while (my ($src, $dest) = do {
					lock(@templates_new);
					(shift @templates_new, shift @templates_new)
				}) {
					print "Thread #$threadid processing $src\n";
					$process_template_sub->($src, $dest) or last;
				}
			});
	}
	$_->join() for @thr;
}
else {
	while (my ($src, $dest) = splice @templates_new, 0, 2) {
		$process_template_sub->($src, $dest);
	}
}

sub mod_time {
    my $template = shift;
    lock(%mod_time);
    $mod_time{$template} ||= gmtimestamptz do {
	my $rev_list_out =
	    qx(git rev-list -1 --pretty="format:%at" HEAD -- $template);
	$rev_list_out =~ m{^(\d+)}m;
	$1;
    };
}

sub post_time {
    my $template = shift;
    lock(%post_time);
    $post_time{$template} ||= gmtimestamptz do {
	my $rev_list_out =
	    qx(git rev-list --reverse --pretty="format:%at" HEAD -- $template);
	$rev_list_out =~ m{^(\d+)}m;
	$1;
    };
}

sub new_feed {
    my $feed_options = shift;
    return bless ({ %$feed_options }, 'My::Feed');
}

sub add_to_feed {
    #use Data::Dumper;
    #print STDERR Dumper (@_);
    my $feed = shift;
    my $entry_options = shift;
    push @{ $feed->{entries} ||= [] }, $entry_options;
}

sub My::Feed::AUTOLOAD {
    my $self = shift;
    my $att = $My::Feed::AUTOLOAD;
    $att =~ s{.*::}{};
    if (@_) {
	$self->{$att} = shift;
    }
    else {
	$self->{$att};
    }
}

sub My::Feed::write {
    my $self = shift;
    my $feed_type = shift;
    my $feed_version = "";
    if ($feed_type =~ s{(\d+(?:\.\d+)?)$}{}) {
	$feed_version = $1;
    }
    my $output = $self->{self_link};
    $output =~ s{\Q$self->{base}\E}{};
    $output ||= "feed.atom";
    $output =~ s{\.atom$}{".".lc($feed_type.$feed_version)}e;
    my $xml_feed = XML::Feed->new
	($feed_type,
	 ($feed_version ? ("version" => $feed_version) : ())
	);
    # process entries first
    while (my ($k, $v) = each %$self) {
	next if $k eq "entries";
	next unless $xml_feed->can($k);
	$xml_feed->$k($v);
    }
    # add the entries..
    for my $entry_options (@{$self->{entries}||[]}) {
	my $entry = XML::Feed::Entry->new($feed_type);
	while (my ($k, $v) = each %$entry_options) {
	    next unless $entry->can($k);
	    $entry->$k($v);
	}
	$xml_feed->add_entry($entry);
    }
    # now write out
    (my $dirname = $output) =~ s{/?[^/]*$}{};
    warn "Writing feed to $output\n";
    if ( !$dirname or -d $dirname ) {
	open FEED, ">$output";
	print FEED $xml_feed->as_xml;
	close(FEED);
    }
    else {
	die "directory '$dirname' does not exist (output='$output')"
	    ." [self_link=$self->{self_link}, base=$self->{base}]";
    }
}

