===============================
Transactions: recording changes
===============================

Snapshot states of the database correspond precisely with commits.

Transactions have a *base commit*, that corresponds to the 'parent' in
the git commit.  They have a *tree* which corresponds to the data as
described in TreeFormat_, including a MetaFormat_\ -compliant
``meta/`` directory.

If two transactions operate in isolation, then there may also be
commits which merge their state.  This will be a *merge commit*,
and may include the results of application-specific conflict merging
(BASE operation).

Implementing Isolation Levels: the transaction in progress
==========================================================

*warning:* this section is a foray into what might and might not
be possible to achieve easily in terms of transaction isolation using
the assumptions made and is generally highly speculative.

A transaction in progress in the Git DB is an index/cache/staging area
which represents the current state to be committed.

When the transaction is committed, information is stored into the
commit object text to record the rows that were read (and hence,
possibly affecting the transaction result).  This is the first phase
of commit, and in the distributed level of isolation, will always
succeed.

The second phase is to move HEAD (or whichever branch this transaction
is committing to) from the old commitid to the new one.  This may
involve writing a merge commit, or forcing a ROLLBACK if this is not
possible.

Which parts of this process are locked, and which are negotiated over
a quorum of participants are all relevant questions to the
`distribution layer`_.

Isolation Levels
-------------------

As far as I'm aware, there are no real definitions of what acceptable
behaviour is when there are multiple actors on the database running on
different isolation levels.  Some of the levels have implied intents;
compromises not for speed but for avoiding having to recompute
results, trading off isolation in return for avoiding ROLLBACK.  This
can only work in the situation where all the nodes can have a shared
index; in distributed scenarios, such isolation levels will not behave
as expected.

To assist in debugging this process, all transactions will log the
isolation level that they used in the commit log.

READ UNCOMMITTED
^^^^^^^^^^^^^^^^^^^^^^

In this mode, transactions are supposed to be able to see results
which are in progress by other transactions, before they are
committed.

This could possibly be achieved using a common index between threads,
which is locked for each update.

However each transaction still requires its own transaction-private
index which holds its own updates only, in order to avoid committing
the work of other transactions; and then, when it wants to commit, it
will still need to merge its changes with the committed state.

It's entirely possible that this will be a useless isolation level;
the overhead of locking the index for every update could easily
outweigh the speed benefits from using a single index.  But for some

applications it may be useful.

READ COMMITTED
^^^^^^^^^^^^^^^^^^^^^^

Here, the private index is used to collect writes as above - but reads
happen from the shared index, which is updated when transactions are
committed.

To avoid ROLLBACK, this level also requires a mechanism for locking
individual rows when a transaction selects them FOR UPDATE (or writes
to them).  A lock system must be employed, capable of detecting
deadlocks.

In this mode, no information is appended to the commit log to record
which rows were read (and therefore may have affected the transaction
result).  As a result, transactions may not be repeatable.

Merging in this mode is relatively simple.  If all threads are using
this mode, then merging should always succeed.  The only situation
(other than a deadlock) where you will be forced to ROLLBACK is when a
row that you changed in this transaction was changed by another
transaction (even if the same result was obtained; two transactions
both adding $10 will write the same balance out - but that result is
not correct).  This can only happen if some other writers were using
the REPEATABLE READ level or higher, or some other source of commits
exists, perhaps in a distributed system.

This mode is recommended for single-master systems, where dealing with
rollback is particularly inconvenient - and the occasional failure of
a writer due to the above corner cases is acceptable.

REPEATABLE READ
^^^^^^^^^^^^^^^^^^^^^^

In this mode, the private index also caches information on which rows
have been returned - partially or in full, but not aggregated -
relative to the *base commit*.  As private information is available
on which objects were read, starting at this level you will see
information put in the commit object, indicating which objects were
read from.

The locking protocol will insert entries like this into the commit
record:

..

    Locks: /foobar/1015,1050,1329,1950

This would indicate that four rows were read, but not updated - in the
'foobar' class (actually, the class which maps to the '/foobar'
directory), the rows with the four primary keys listed were locked.
This does not require rows to be selected FOR UPDATE (a hint purely
for the READ COMMITTED level).

The protocol also allows for ranges to be specified;

..

    Locks: /foobar/1000-1019

This isolation level will emit rows such as this, if the entire range
of legal values were returned; it is just a short-hand notation.

In addition to checking that the same rows were not updated by the
transaction being merged, merging in this level checks that no rows
listed in read locks for the commits being merged in matched changed
rows in this transaction; and that no read locks in our transaction
match changed rows in the transactions being merged.

SERIALIZABLE
^^^^^^^^^^^^^^^^^^^^^^

This level solves the problem of "phantom rows".  This is a
requirement that extends beyond simple recording of read and write
access, and requires that selects of multiple rows by ID lock rows
that were not present.

What this means is that if a query is issued - searching over a range
of primary keys - that range of rows are locked.

..

     Locks: /foobar/1000-2000

This doesn't mean that 1,001 rows were returned - it just means that
there was a search by range of primary keys, with the range specified
as between 1000 and 2000.

It is a specific fix for a particular example of where REPEATABLE READ
is not quite enough to not ruin your day every once in a blue moon.
However, as noted in the Postgres manual, it is not the only way to
end up with results which are not repeatable.

Merging in this isolation level proceeds as with REPEATABLE READ.

This is the recommended level for OLTP use, where it is can be
relatively easy to deal with a ROLLBACK (ie, by re-applying the
transaction).  It provides a highly repeatable level of isolation, and
therefore scales to distributed writers well.  With the addition of a
quorum/voting system, 2N+1 nodes of equal trust can even form a useful
multi-master system.

Distributed isolation level
=================================

All row ID ranges *read* or *queried* are listed in the
commit text, not just rows locked for update.

It is an open question whether this is truly a new isolation level, or
merely a distributed implementation of SERIALIZABLE.

.. _TreeFormat:
   /design/treeformat

.. _MetaFormat:
   /design/metaformat

.. _distribution layer:
   /design/distribution
