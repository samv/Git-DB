README for git db
~~~~~~~~~~~~~~~~~
git db is an experimental research project, aiming to combine a number
of emergent technologies to enable a new platform of social-networking
building, buzzword-coining computing.

Seriously though, its essence is a hybrid/relational data store, built
to run on top of the git source control management system.  It
consists of;

 1. a set of binary encoding formats for some basic types like
    Integers, Floats, Strings, etc,

 2. a binary row packaging encoding standard, to combine those items
    into binary sequences representing lists of columns,

 3. a pretty-printing row packaging standard, for filename-izing a
    series of columns, to refer to those binary encoded rows,

 4. a basic filesystem structure for arranging similarly typed
    pretty-printed packaged rows in git trees,

 5. a metamodel which can express basic schemas, including itself,
    which can be stored in the filesystem structure,

 6. a proposal for a mechanism of recording locks in the git commit
    message, such that ACID-level consistency guarantees could be
    available, if you chose to use them - and speculations on how to
    use this data to achieve it.

This system is designed to support a wide variety of use cases,
hopefully the basics simple enough to be a useful back-end for SQLite
or embedded uses, but also be a backing store that a traditional
multi-user RDBMS might want to use; distributed computing in all three
CAP modes, as well as sharding and map/reduce.

It could also be used for a new type of computing that this author
labels as "democratic computing", a proposed mode of computing with a
cluster of multi-master nodes, where no node is trusted fully but
every node is trusted equally; a voting system is used to resolve
possible conflicts and auditing is possible.  Other novel areas of
application include "decentralised social networks"; holding the
databases that people collaboratively edit with each other, be it a
friends list or a photo collection catalogue.

There are almost certainly going to be domain-specific areas which the
above doesn't cover, and certainly certain applications will remain
vapourware until someone actually implements them.

Implementation Status
---------------------
It's not entirely vapourware; see the below table.

                        Spec   Code   Tested  See
  1. Encodings:         done    yes    yes    lib/Git/DB/Encode.pm
  2. Row Packaging:     done    ...     -     lib/Git/DB/ColumnFormat.pm
  3. Filename format:  started   -      -     lib/Git/DB/ColumnFormat.pm
  4. Filesystem:          -      -      -     various POD references
  5. metamodel:        rev. 1    -      -     lib/Git/DB/Tables.pod
  6. TX model:         started   -      -     lib/Git/DB/Tx.pm

Nothing is really complete until prototype code tests pass of course.
Some ideas are still quite hazy, and the project is full of various
brainfarts that were written along the way of formation of the ideas.

The first major milestone of the project will be to boot-strap the
metamodel; that is, get the first 1-5 parts of the system nailed down
far enough that the system can store a schema for itself.

Once the Transaction Model has been proven, then it should already be
an extremely useful and general purpose system; hopefully, of internet
protocol standing.
