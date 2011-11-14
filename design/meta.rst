
=====================================
MetaFormat: specifying data structure
=====================================

There is a special schema in the git db store which represents the
schema of the tables itself; these are identified with the
``meta.`` schema name.  Optionally there are rows in the schema
which represent the schema of the ``meta.`` store itself.

Meta Tables
===========

As the intrinsic storage building block, the ``meta.` Tables
have the following restrictions;

**column types**

    All columns *must* be defined in terms of primitive types; arrays
    and nested types are not permitted.  Instead, in this version of
    git db they are implemented using the traditional, relational
    approach using foreign keys and suchlike, called **slave tables**
    in this specification (see below).

**keys**

    All tables in ``meta.`` space *must* have a primary key.  Primary
    key columns must come first.  Keys are simple (ie, not functional)
    and unconditional (ie, not partial), unless one of the columns in
    the key is marked NULL.

    **Foreign key** constraints are present and *must* reference
    another table's primary key.
    
**unique constraints**

    Non-primary unique constraints *may* be implemented in terms of
    foreign key constraints to specially named tables.  These are
    effectively *indexes* and exist in regular databases but are not
    normally referencable.
    
Note that tables with a name after the ``:`` is a **slave
table** or **link table**; they are tables which always have a
foreign key relationship with the table they are slave to.

Sometimes, these are used for 1 to many relationships between
items. In later versions, arrays may be used for this purpose instead.

In other cases, they simply express constraints/proofs.  To help the
parts of it which express constraints and proofs slink into the
shadows cast by the lines which actually define interesting columns,
the interesting ones are shown in **bold**.  Currently that means
lines which define attributes, which are not merely columns used for
foreign keys in a slave table.

This is being presented like this in order to satisfy the
*bootstrapping* requirement of the schema; it should be able to
store itself, including all of the relevant constraints that you would
expect to operate on the data structure.

The "Schema" or "Namespace" table
=================================

..

  # a schema is like a namespace; it's what you connect to.
  meta.schema:
    ns_url text not null
    ns_rev num not null
    primary key (ns_url, ns_rev)
    ns_name str not null**
    unique key (ns_name)
 
  # this table is the schema name index.
  meta.schema:ns_name_idx
    ns_name str not null
    primary key (ns_name)

The "Class" or "Table" table
============================

..

  # a class essentially describes a table
  meta.class:
    **ns_url text not null**
    **ns_rev num not null**
    foreign key (ns_url, ns_rev)
            references meta.schema
    **class_index int not null**
    primary key (ns_url, ns_rev, class_index)
    **class_name text not null**
    unique key (ns_url, ns_rev, class_name)

  # this enforces the unique key above^ and is optional in the store
  meta.class:nameidx
    ns_url text not null
    ns_rev num not null
    class_name not null
    primary key (ns_url, ns_rev, class_name)
    class_index int not null
    foreign key (ns_url, ns_rev, class_index)
            references meta.class

  # only one revision of the schema may actually have tables at any
  # given time.  Also enforces that no two tables can have the same
  # name, and lets you figure out which class the filesystem paths
  # relate to.
  meta.class:ns_name_class_name
    ns_name not null
    foreign key (ns_name) references meta.schema:ns_name_idx
    class_name not null
    primary key (schema_name, class_name)
    ns_url text not null
    ns_rev num not null
    class_index int not null
    foreign key (ns_url, ns_rev, class_index)
            references meta.class

  # superclass heirarchy.  whole table is primary key! (link table)
  # many RDBMSes don't have this concept, but it's like postgres'
  # INHERITS option to CREATE TABLE
  meta.class:super
    **ns_url text not null**
    **ns_rev num not null**
    **class_index int not null**
    foreign key (ns_url, ns_rev, class_index)
            references meta.class
    **superclass_index int not null**
    foreign key (ns_url, ns_rev, superclass_index)
          references meta.class (ns_url, ns_rev, class_index)

The "Attributes" or "Columns" table
================================

  # this table records the list of attributes/columns of a
  # class/table.
  meta.attr:
    **ns_url text not null**
    **ns_rev num not null**
    **class_index int not null**
    foreign key (ns_url, ns_rev, class_index)
            references meta.class
    **attr_index int not null**
    primary key (ns_url, ns_rev, class_index, attr_index)
    # if attr_name is null, the column is deleted.
    **attr_name text null**
    unique key (ns_url, ns_rev, class_index, attr_name)
    **attr_type text not null**
    foreign key (ns_url, ns_rev, attr_type) references meta.type
         (ns_url, ns_rev, type_name)
    **attr_required bool not null**
    # a 'default' is somewhat problematic; *any* value can be placed
    # here, and it is not known how to interpret it without looking up
    # what the attr_type means; so, it may be seen as 'opaque'
    **attr_default item null**

  # for unique key in above
  meta.attr:attr_name_idx
    ns_url text not null
    ns_rev num not null
    class_index int not null
    name text not null
    primary key (ns_url, ns_rev, class_index, name)
    attr_index int not null
    foreign key (ns_url, ns_rev, class_index, attr_index)
            references meta.attr

Precision/scale modifiers, such as ``VARCHAR(2)`` etc are not
supported directly; they're something of a bodge when proper
generics/higher order type system is a more complete solution.  Done
properly, a generics system can also be the starting point for
features such as arrays (ARRAY [TYPE]) and composite types (eg TUPLE
[TYPE, TYPE, TYPE]); so this will be left out initially, and the
database will be fully arbitrary length throughout.

KEYS & KEY CONSTRAINTS
======================

..

  # the 'key' table describes unique and foreign key constraints as
  # well as listing recommended indexes (stored=false)
  meta.key:
    **ns_url text not null**
    **ns_rev num not null**
    **class_index int not null**
    foreign key (ns_url, ns_rev, class_index)
            references meta.class
    **key_name text not null**
    primary key (ns_url, ns_rev, class_index, key_name)
    **key_unique bool not null**
    **key_primary bool not null**
    **key_stored bool not null**
    # whether this key also restricts subclasses of the parent.
    # subclasses will have multiple key rows!
    **key_heritable bool not null**

  # this slave table links the key to the (ordered) list of attributes
  # which are a part of the key, and if the key is a foreign key, then
  # also the columns of the foreign key.
  meta.key:attr
    **ns_url text not null**
    **ns_rev num not null**
    **class_index int not null**
    **key_name text not null**
    foreign key (ns_url, ns_rev, class_index, key_name)
            references meta.key
    **key_pos int not null**
    primary key (ns_url, ns_rev, class_index, name, key_pos)
    attr_index int not null
    foreign key (ns_url, ns_rev, class_index, attr_index)
            references meta.attr
    foreign_class_index int null
    foreign key (ns_url, ns_rev, foreign_class_index)
            references meta.class (ns_url, ns_rev, class_index)
    foreign_attr_index int null
    foreign key (ns_url, ns_rev, foreign_class_index, foreign_attr_index)
            references meta.attr (ns_url, ns_rev, class_index, attr_index)

.. _types:

Types
=====

..

  # meta.type: this is basically a compatibility table and is optional
  # if using only predefined types.  'Functions' here are strings;
  # only the name, not the definition nor the function prototype are
  # represented.  They are to be well-known function names, but the
  # paranoid should prepare for them to be custom to the schema
  # ID/revision.
  meta.type:
    **ns_url text not null**
    **ns_rev num not null**
    foreign key (id, ns_rev) references meta.schema
    **type_name text not null**
    primary key (id, ns_rev, type_name)
    **type_formats int not null**
    **type_dump_func text null**
    **type_load_func text null**
    **type_choose_func text null**
    **type_cmp_func text null**
    **type_print_func text null**
    **type_scan_func text null**

``type_formats`` is an integer which is interpreted bitwise, and
represents the encodings which are allowed for that type in this
store.  The values for the standard types, below, represent all of the
encodings which are defined by this standard.  Using an encoding for a
type which is not permitted by the ``type_formats`` value in the
``meta.type`` table is a data consistency error.  ``type_formats``
roughly covers the ``INTERNALLENGTH`` and ``STORAGE`` properties in
the equivalent Postgres feature, ``CREATE TYPE``

The functions are described as below:

``type_choose_func``

    Some types get to choose the encoding based on the value to be
    encoded.  If that is true, this function will be defined,
    otherwise it will be null and only one ``type_formats`` bit may be
    set.
  
``type_dump_func``

    The name of a function which marshalls the value out.  The
    function will take the value, an encoding, and return a value
    valid for that encoding.  This is similar to the ``SEND`` function
    in Postgres.
  
``type_load_func``

    The reverse, but marshalls the value in.  The encoding is a formal
    parameter.  This corresponds to ``RECEIVE`` in Postgres.
  
``type_cmp_func``

    The name of a function which can compare two values.  For primary
    key sorting purposes.  This corresponds to the ``CREATE OPERATOR
    CLASS ... DEFAULT FOR TYPE ... USING BTREE`` command in Postgres.
  
``type_print_func``

    The name of a function which converts the value to a primary
    key-form string, like ``OUTPUT`` in Postgres.  This need not be
    reversible; if not, the standard types' function name starts with
    ``hash_``
  
``type_scan_func``

    The reverse of ``type_print_func``; turns a formatted string back
    into a value, like ``INPUT`` in Postgres.  If this is not
    reversible then the function will be converting the row value to a
    placeholder.
  
Types do not need to specify a hashing function as in Postgres; this
is considered an internal implementation detail.  As truly custom
types are not yet permitted, hashing may proceed on the basis of the
encoded value.

Standard Types
--------------

The *standard types* here represent a common set of well known
data types in use in databases and programming, and a corresponding
set of *well known functions* which perform the trivial IO
operations, and for which reference implementations will be provided.

Implementations need not support all types; however if opening a
store, this table may be checked to see that the understanding of all
parties as to the nature of the types is known.

.. list-table:
   :widths: 12 12 12 12 12 12 12 12

   * - ``type_name``
     - ``type_formats``
     - ``type_choose_func``
     - ``type_dump_func``
     - ``type_load_func``
     - ``type_cmp_func``
     - ``type_print_func``
     - ``type_scan_func``
   * - bool
     - 1100000b
     - is_tf
     - emit_bool
     - read_bool
     - false_first
     - fmt_bool
     - scan_bool
   * - integer
     - 1b
     - -
     - emit_varint
     - read_varint
     - cmp_num
     - fmt_int
     - scan_int
   * - real
     - 11011b
     - pack_real
     - emit_real
     - read_real
     - cmp_num
     - fmt_real
     - scan_real
   * - numeric
     - 1000b
     - -
     - emit_real
     - read_real
     - cmp_num
     - fmt_real
     - scan_real
   * - bytea
     - 1000100b
     - large_value
     - emit_bytea
     - read_bytea
     - cmp_bytes
     - fmt_bytea_hex
     - scan_bytea_hex
   * - text
     - 1000100b
     - large_value
     - emit_text
     - read_text
     - cmp_text
     - fmt_text
     - scan_text
   * - nkd_text
     - 1000100b
     - large_value
     - emit_nkd_text
     - read_nkd_text
     - cmp_nkd_text
     - fmt_nkd_text
     - scan_nkd_text
   * - nkc_text
     - 1000100b
     - large_value
     - emit_nkc_text
     - read_nkc_text
     - cmp_nkc_text
     - fmt_nkc_text
     - scan_nkc_text
   * - json
     - 1000100b
     - large_json
     - emit_json
     - read_json
     - cmp_struct_hash
     - hash_json
     - scan_hash

The functions are all described in detail in the reference
implementation.  Most are very simple.

If a ``type_name`` is used in the schema, but not listed in
``meta.types``, then the above definitions are used.
