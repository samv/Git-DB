
package Git::DB;

use Moose;
use Moose::Util::TypeConstraints;

# specify the path if you like.
has 'git_dir' =>
	is => "ro",
	isa => "Str",
	;

# passing in a Git object is also OK
has 'git' =>
	is => "rw",
	isa => "Git",
	;

subtype "Git::DB::objectid"
	=> as "Str",
	=> where {
		m{^[a-f0-9]{40}$};
	};

subtype "Git::DB::commitid" => as "Git::DB::objectid";
subtype "Git::DB::treeid"   => as "Git::DB::objectid";
subtype "Git::DB::blobid"   => as "Git::DB::objectid";
subtype "Git::DB::tagid"    => as "Git::DB::objectid";


1;

__END__

=head1 NAME

Git::DB - a hybrid data storage system for Git

=head1 SYNOPSIS

 # connect to an existing store
 my $db = Git::DB->connect( git_dir => $GIT_DIR );

 # typical document-based / schema-less use:
 my $object = $db->fetch_any( $uuid );

 # equivalent to:
 my $object = $db->fetch_by_pkey( "Object", $uuid );

 # example, using natural keys
 my $domain = $db->fetch_by_pkey( "Domain", $zone, $entry );

 # equivalent example, using 'storage object' search interface
 my $wanted_domain = $db->query_object("Domain");
 my $query = ( ( $wanted_domain->{zone} == $zone )  &
               ( $wanted_domain->{entry} == $entry ) );
 ($domain) = $db->find($query);

 # update it; using whatever API your class uses:
 $domain->locked(1);

 # you can also use "insert" or "update"
 $db->upsert($domain);

 # committing - note autocommit is OFF by default
 $db->commit($audit_comment);
 $db->rollback;

 # savepoints, or "private" commits
 $db->savepoint($name, $audit_comment);
 $db->rollback($name);

=head1 DESCRIPTION

B<Note:> the entire B<Git::DB> system is currently a design in
progress.  Nothing is yet implemented, what is currently here is
limited to being a design.

The purpose of this module is to prototype the use of Git - in its
capacity as a content-addressed filesystem - as a structured storage
back-end for table data.

It is mostly intended to document a storage convention for relational
data, and prove the transaction protocol.  The storage convention is
designed with both complex RDBMS's like MySQL and Postgres and simpler
ones like SQLite or even CouchDB in mind.  The transaction protocol is
designed to be able to be able to prove that a wide variety of
concurrent updates did not conflict with each other, and would have
produced the same result if run serially as they did in parallel.

A simple interface for accessing the store from Perl is also shipped
which may prove sufficient for many applications.  However, the
underlying API should also be sufficiently flexible and fine-grained
enough to allow integration with other Perl storage systems, such as
L<Prophet>, L<KiokuDB>, etc.  If you try to integrate L<Git::DB> with
such a storage system and encounter difficulties, please contact the
author for assistance.

=head2 Why are you using a Version Control System as a Database?

In functional programming - which fits hand in hand with declarative
languages such as SQL, and the relational database paradigm based on
the mathematical concepts of Set Theory - B<immutable data> is a key
concept.  Once you have the result of some computation, it shouldn't
be able to change.

Git's content-store is just that.  A given computing result shouldn't
change - and a crypto-checksum of a computational state provides just
this behaviour.

Relational data has a long history of generally being capable of
representing any computational state; it has stood the test of time as
a flexible general purpose platform.  Therefore, if we can express
relational data in terms of a filesystem, then we can combine the
successes of these two technologies.

B<Replication> will be a much simpler undertaking with this
technology.

B<Auditing> of changes is much simpler if you can trace the history of
changes.

B<Parallel processing> will be much simpler to implement, though
subject to the underlying constraints of underlying contention in the
computations being undertaken.

=cut

