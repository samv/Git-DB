==========================
TreeFormat: arranging data
==========================

TreeFormat basics
=================

The starting point of the design is to use the schema name at the top
level, table/relation name next, and then within those, a zero-padded
sort number, a space and a UTF-8 representation of the value of the
primary key(s) of the row (or a UUID if there is no primary key) as
the filename within the tree for the relation.

eg

..

   tracker/ticket/1 1
   tracker/ticket/2 2

The exact mechanism for converting from a value to the above
representation is type-dependent, and covered by the <a
href="[%link('design/filenames.tt')%]">Filename format</a>).  The
mechanism to know what the directory names mean is covered by the <a
href="[%link('design/meta.tt')%]">MetaFormat</a>.  To solve the
re-entrancy problem, a "meta" directory exists at the top level which
contains fixed directories such as "class", "types" and "attr".

Dividing large directories
================================

For relations with a lot of contents, trees can be used.  This is
equivalent to use of nodes in a B-Tree.  The name of a tree can either
be a single value or a range.

..

   tracker/ticket/1 1-1000/1 1
   tracker/ticket/2 1001-2000/1 1001

If it is a value, it must correspond to an entire key column (and
there must be subsequent primary key columns).

The problem of deciding when to divide a large directory, and when to
"rebalance" the tree, so as to try to ensure an even depth of index,
are long-standing data management problems which this specification
will not try to wave a magic wand to make go away.  More on that in
the below section.

Sort numbers
================================

One of the things that this specification tries to ensure is that the
back-end as a whole has good enough design performance to be used for
a live database back-end.

As such, the method described above for allowing arbitrary division of
directories into smaller fragments, makes the structure as a whole a
B+ tree, or depending on the rebalancing style, a more advanced form
such as a B* tree.  These types of trees are widely used internally in
databases to record row locations and for ordered indexes, because
they are well understood, and generally thought to be about as fast as
you can get and still allow very large scalability.

In Git DB, the git tree objects are the 'nodes' in the B+ tree, and
the blobs are the 'leaves'.

However for B+trees to work, a couple of conditions must hold true for
the nodes:

1. Nodes should be fast to locate entries in

2. Nodes should be fast to scan in order

Typically, the "fan out" of a B+ tree is of the order of about a 100
in each directory before it is "split" into two or three balanced
children.  The B* tree performs a partial rebalancing at this point to
make the neighbours also relatively balanced with each other.

Assuming such a large fan-out, random access needs to be fast, but
unless the entries in the tree are in order, it is impossible to use
binary search to locate the item or range you are looking for.
Hash-based solutions solve the problems, but can't be used for all
cases.

Unfortunately, there is no way to specify the order of entries in a
git tree.  They are always sorted by string value.  And only a very
few types will naturally sort correctly after conversion and escaping.

To solve this problem, the sort number is introduced.  It is designed
to override the filename, so that the entries will always be stored in
the correct order.  When writing a tree for the first time, the
appropriate number of digits are used, zero padded, and starting at 1.

eg

..

   role/voter/1 Jones,Bob
   role/voter/2 MacDonald,Ronald
   role/voter/3 Mace,The
   role/voter/4 MacGuyver,James
   role/voter/5 Nelson,Willie

Let's say that a new entry, "Woody Allen" comes along.  We need to
insert a new number at the beginning.  At this point, one of two
things happens:

* If it makes an implementation simpler, it can renumber all of the
  entries in that tree.  This can still be fast enough and is simple
  string operations to enact.  It only affects the tree which is being
  inserted into, which has to be re-written back to the object
  database anyway:

  ..

     role/voter/1 Allen,Woody
     role/voter/2 Jones,Bob
     role/voter/3 MacDonald,Ronald
     role/voter/4 Mace,The
     role/voter/5 MacGuyver,James
     role/voter/6 Nelson,Willie

* However if it does matter, because either there is an index which
  would otherwise have to be updated and recursively moved sub-entries
  around, or perhaps just it is desired to make directories which
  delta more efficiently, then it can insert a new entry before: ..

   role/voter/05 Allen,Woody
   role/voter/1 Jones,Bob
   role/voter/2 MacDonald,Ronald
   role/voter/3 Mace,The
   role/voter/4 MacGuyver,James
   role/voter/5 Nelson,Willie

  This works, of course, because "``05 xxx``" sorts before "``1
  yyy``", regardless of the values of "``xxx``" and "``yyy``".  So, as
  you can see, there are an infinite number of numbers before and
  after every non-zero number you can summon... 

  If the primary key of the table is a hash or UUID, or its type
  otherwise guarantees that its filename representation matches the
  sort order of the type, then the sort numbers may be safely omitted.
  They are enabled or disabled in the schema.

Official row filenames
======================

As noted in the `Filename layer`_, the "official" filename of the row
is that which is stripped of all of these divisions (and sort numbers)
along the way.  This is important for heirarchical references to rows,
which are always by the "official" filename.

Row format
==========

The format of the actual rows is described in the ColumnFormat_.

If any columns are specified completely in the directory path of the
row, then those columns may be omitted in the stored row(s).  Tree
rebalancers beware.

This does not affect column numbering; the first column is likely to
have a non-zero increment value.

Page format
===========

Especially if there is a lot of relatively static rows (ie, OLAP
systems), it may make sense to write out "pages", which are a single
emission of packed rows.

This is indicated in the tree by a filename which is a range, but
which is a blob (file) and not a tree (folder/directory).  Another
possibility is that the filename does not completely have all the keys
in the schema listed yet; eg if there are 3 primary key columns, and
you encounter the blob while scanning:

..

  myschema/mytable/customerid,projectid

The third key is still expected and so the system knows that the blob
is a page and contains the remaining columns.

For bulk inserts, emitting pages as you go is fair game.

If a row in a page needs to be removed, or a value in between added,
then the page must be split or rewritten.  Most random writers will
use the split policy; rewriting a page for an update should be
considered the same problem as tree rebalancing; don't overdo it,
because it wins you relatively little and slows updates down
tremendously.

.. _Filename layer:
   ./filenames.rst

.. _ColumnFormat:
   ./columnformat.rst
