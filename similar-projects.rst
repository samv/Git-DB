Similar Projects to Git DB
==========================

This page is something of a collection of notes about similar projects
that people have been working on.

First, there are categories of technologies, like RDF, which attempt
to describe the shape and nature of data.

Secondly, there are projects which are approaching the same space;

1. There's a Drizzle DB back-end that makes use of Google
   ProtocolBuffers for its table format (ht: Mark Atwood)

2. Projects such as Diaspora exist; also Locker; this class of
   application driving a social network is called a **Personal Data
   Router**

3. MySQL's Volt DB does distributed database, but it's not ACID, it's
   BASE.

Projects which are more like "direct competitors":

1. Apache AVRO
2. Thrift

The main differences in this spec being the emphasis on ACID and
distributed transactions, and the in-store storage of 'meta' storage
information (to facilitate generic data browsers).
