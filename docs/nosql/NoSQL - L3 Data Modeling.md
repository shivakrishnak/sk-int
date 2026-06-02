---
layout: default
title: "NoSQL - L3 Data Modeling"
parent: "NoSQL"
nav_order: 6
permalink: /nosql/l3-data-modeling/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [NoSQL Data Modeling Patterns and Denormalization](#nosql-data-modeling-patterns-and-denormalization) | ★★☆ |
| 2 | [Consistency Levels in Distributed NoSQL](#consistency-levels-in-distributed-nosql) | ★★☆ |

---

# NoSQL Data Modeling Patterns and Denormalization

---

### 🎯 Model Answer

**30 seconds:**
> NoSQL data modeling is query-first: identify every read query the application needs,
> then design one table/collection structure per query. Data is duplicated across
> multiple structures to serve each query efficiently. This is the opposite of
> relational normalization (which models data once and queries it flexibly). The core
> patterns are: embedding (denormalize into one document/row), referencing (separate
> documents with manual joins in application code), and the bucket pattern (aggregate
> multiple rows into one to reduce I/O).

**3 minutes (Senior):**
> The five core NoSQL data modeling patterns: (1) Embedding - nest related data into
> one document; eliminates joins; good when embedded data is always read with the parent
> and never accessed independently; bad for unbounded arrays (document grows forever).
> (2) Referencing - separate documents with a stored ID reference; application joins in
> code; good for large or independently-accessed subdocuments; adds extra query. (3)
> Bucket pattern - group time-series events into one document by hour/day; reduces
> document count by 60-3600x; good for write-heavy time-series. (4) Computed pattern -
> pre-compute and cache aggregates (count, sum) in a field; eliminates runtime aggregation
> queries; requires updating on write. (5) Polymorphic pattern - store different entity
> types in one collection; add a `type` discriminator field; good for inheritance
> hierarchies. Decision rule: model data for the queries you have, not the data you
> have; if you need different queries, you need different models.

**Framework:** Query-First -> Embedding vs Referencing -> Bucket Pattern (time-series) -> Computed Pattern (aggregates) -> Polymorphic (inheritance)

**Blank Mind Recovery:**

**(1) Restate:** "NoSQL modeling: start from queries. Embed for co-read data.
Reference for large/independent data. Bucket for time-series. Compute aggregates at
write. Polymorphic for mixed types."

**(2) First principles:** "NoSQL databases cannot join at query time (or it is
expensive). The application must encode the join into the data structure. Data
modeling is the art of pre-computing the join at write time."

**(3) Bridge:** "Relational modeling is like having one master spreadsheet with
strict normalization. NoSQL modeling is like having 10 specialized printouts,
each arranged exactly for one dashboard - but you must update all 10 printouts
when data changes."

---

### 📘 Concept Explanation

**Embedding vs Referencing Decision Tree:**

```text
EMBEDDING vs REFERENCING:

  Start: Is the subdocument ALWAYS read with the parent?
         |
        YES                         NO
         |                           |
  Is it BOUNDED in size?     Does it GROW unboundedly?
         |                           |
        YES          NO             YES          NO
         |            |              |            |
      EMBED      REFERENCE       REFERENCE    CONSIDER both
    (optimal)  (to avoid      (array will   (evaluate access
               large docs)    overflow)      frequency)

  EMBEDDING EXAMPLES (good):
    - Order + line items (always together, bounded)
    - User + address (one address, always returned)
    - Post + author name (snapshot, denormalized)

  REFERENCING EXAMPLES (good):
    - User + comments (unbounded comments, independent access)
    - Product + reviews (thousands of reviews, paginated)
    - Order + customer (customer accessed independently)

  ANTI-PATTERN: deeply nested arrays
    { user: { orders: [ { items: [ { variants: [...] } ] } ] }}
    -> document size grows unboundedly
    -> update atomicity for inner arrays is complex
    -> use references for inner arrays beyond 2 levels deep
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the decision tree for choosing between
> embedding and referencing in document databases. (2) HOW TO READ IT: start at the
> top with the primary question (always read together?); follow the branches based on
> boundedness and access frequency; the leaves show the recommended approach. (3) KEY
> RELATIONSHIP: embedding optimizes read performance by co-locating data; referencing
> optimizes write flexibility by isolating independently-changing data; the decision
> trades off read simplicity vs write/storage efficiency. (4) EDGE CASE: "bounded" is
> a hard question; user comments start bounded but grow over years; add a max-array-
> size rule (e.g., embed only the last 10 comments, reference all others) to avoid
> unbounded growth. (5) INSIGHT: a senior engineer recognizes that the anti-pattern
> (deep nesting) is common in code-first modeling where developers model the object
> graph directly; always model from the queries, not from the object hierarchy.

**The Bucket Pattern for Time-Series:**

```text
BUCKET PATTERN:

  BAD: one document per event
  { device_id: "d1", time: T1, temp: 23.1 }
  { device_id: "d1", time: T2, temp: 23.3 }
  ... (1 million documents per device per day)

  GOOD: bucket by hour
  {
    device_id: "d1",
    bucket_start: "2024-01-15T14:00:00Z",
    count: 3600,
    data: [
      { offset_seconds: 0, temp: 23.1 },
      { offset_seconds: 1, temp: 23.3 },
      ... (3600 entries, one per second)
    ],
    min_temp: 21.0,
    max_temp: 25.2,
    avg_temp: 23.1
  }

  RESULT: 1 million events -> 24 documents (per device/day)
  Query "last 2 hours": read 2 documents instead of 7200
  Aggregates (min, max, avg) precomputed in the document
  MongoDB time-series collections do this automatically (5.0+)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Bucket Pattern comparing one-document-
> per-event (bad) vs one-document-per-hour-bucket (good) for time-series IoT data. (2)
> HOW TO READ IT: the top shows the naive approach creating millions of tiny documents;
> the bottom shows the bucket approach with pre-computed aggregates and an array of
> offsets within each bucket. (3) KEY RELATIONSHIP: reducing 1 million documents to 24
> reduces index size, document count overhead, and query round-trips; pre-computed
> aggregates (min, max, avg) in the bucket document eliminate aggregation pipeline queries
> for common summary statistics. (4) EDGE CASE: writes to an in-progress bucket (the
> current hour) require an array append + aggregate update as an atomic operation;
> MongoDB supports this with `$push` + `$inc` in a single update; without atomicity,
> the pre-computed aggregates can become stale. (5) INSIGHT: a senior engineer recognizes
> that MongoDB 5.0+ Time-Series collections implement this pattern automatically with
> columnar storage; for new projects, use time-series collections instead of manual
> bucketing.

---

### 💻 Code Example

```javascript
// MongoDB data modeling patterns
const { MongoClient } = require("mongodb");
const client = new MongoClient("mongodb://localhost:27017");
const db = client.db("ecommerce");

// PATTERN 1: EMBEDDING (order + line items)
// Query: "get order with all items" (always together)
const orderEmbedded = {
  _id: "order123",
  user_id: "user456",
  created_at: new Date(),
  status: "pending",
  items: [              // embedded (bounded array)
    {
      product_id: "p1",
      product_name: "Laptop",  // denormalized snapshot
      quantity: 1,
      price_at_purchase: 999.00
    },
    {
      product_id: "p2",
      product_name: "Mouse",
      quantity: 2,
      price_at_purchase: 29.99
    }
  ],
  total: 1058.98
};
await db.collection("orders").insertOne(orderEmbedded);
```

> **Code walkthrough:** (1) WHAT IT SHOWS: an order document with embedded line items
> - the "always read together" pattern where items are never accessed independently
> of their order. (2) KEY MECHANISM: `product_name` and `price_at_purchase` are
> deliberately denormalized from the products collection; this is a snapshot of the
> product at purchase time; if the product name changes later, the historical order
> still shows the original name. (3) WHY IT MATTERS: a single document read returns
> the entire order with all items; no additional query needed; the read performance
> is optimal. (4) WHAT BREAKS: if `items` array is unbounded (a user adds 10,000
> items to one order over time), the document size grows and update performance
> degrades; MongoDB's maximum document size is 16 MB; bounded arrays (orders typically
> have 1-100 items) are safe. (5) TAKEAWAY: denormalize name and price-at-purchase in
> order items; this is correct and intentional - it preserves the historical state
> at order time; the alternative (referencing product by ID) would require a join and
> would return the CURRENT product name, not the one at purchase time.

```javascript
// PATTERN 2: COMPUTED PATTERN (pre-computed counts)
// Query: "display post with comment count" (frequent)
const postWithCount = {
  _id: "post789",
  title: "NoSQL Modeling",
  content: "...",
  author_id: "user456",
  comment_count: 0,   // pre-computed, updated on write
  like_count: 0
};

// On new comment: increment counter atomically
await db.collection("posts").updateOne(
  { _id: "post789" },
  { $inc: { comment_count: 1 } }  // atomic increment
);

// Query: get post (comment_count is already there)
const post = await db.collection("posts").findOne(
  { _id: "post789" },
  { projection: { comment_count: 1, title: 1 } }
);
// No $lookup or count() aggregation needed
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Computed Pattern where a `comment_count`
> field is maintained in the post document and incremented atomically with each new
> comment. (2) KEY MECHANISM: `$inc` is an atomic server-side increment; it reads and
> increments the counter in a single database operation; no read-modify-write race
> condition. (3) WHY IT MATTERS: the alternative (`db.comments.countDocuments({ post_id:
> "post789" })`) scans all comments for every post display; on a page showing 20 posts
> with thousands of comments each, that is 20 separate count queries; the Computed
> Pattern reduces this to zero extra queries. (4) WHAT BREAKS: if a comment is deleted
> and the `$dec` update fails, the counter becomes inconsistent; add a periodic
> reconciliation job to recount from the comments collection and correct the counter
> if needed. (5) TAKEAWAY: use the Computed Pattern for any aggregate that is read
> more often than it changes; the write overhead of one `$inc` is negligible; the
> read savings are substantial.

```javascript
// PATTERN 3: POLYMORPHIC (mixed entity types)
// Problem: athletes with different sport attributes

// BAD: separate collections with nearly identical queries
// footballPlayers.find(), basketballPlayers.find()

// GOOD: one collection with type discriminator
const athletes = db.collection("athletes");

await athletes.insertMany([
  {
    _id: "a1",
    type: "football",
    name: "Alex Smith",
    position: "quarterback",
    passing_yards: 32000     // football-specific
  },
  {
    _id: "a2",
    type: "basketball",
    name: "Sam Jones",
    position: "center",
    points_per_game: 24.3    // basketball-specific
  }
]);

// Query all athletes (polymorphic)
const allAthletes = await athletes.find(
  {},
  { projection: { name: 1, type: 1, position: 1 } }
).toArray();

// Query type-specific fields
const footballers = await athletes.find(
  { type: "football" },
  { projection: { name: 1, passing_yards: 1 } }
).toArray();
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Polymorphic Pattern where different entity
> types (football and basketball athletes) are stored in one collection using a `type`
> discriminator field. (2) KEY MECHANISM: MongoDB's flexible schema means different
> documents can have different fields; the `type` field enables filtering by entity
> type; fields not present in a document are simply absent (not null, not undefined);
> queries on absent fields return no results for those documents. (3) WHY IT MATTERS:
> a single collection enables queries that span all athletes regardless of type (e.g.,
> "find all athletes named Smith"); separate collections require client-side union of
> multiple query results. (4) WHAT BREAKS: without indexes on `type`, a query for all
> football athletes scans the entire collection; add a sparse index on `type` and on
> any sport-specific field that is frequently queried. (5) TAKEAWAY: use the Polymorphic
> Pattern when entities share a majority of fields and differ in a minority; use
> separate collections when entities are fundamentally different and rarely queried
> together.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> NoSQL modeling starts from queries. For MongoDB: embed data that is always read
> together (orders + items). Reference data that is large or accessed independently
> (posts + comments). Never embed unbounded arrays. Duplicate data across collections
> for different access patterns (one collection per query). The Computed Pattern
> pre-computes aggregates at write time so reads are fast. These patterns replace
> normalization and joins.

---

**Senior / Staff (5+ years):**
> NoSQL modeling decisions with production consequences: (1) Embedding vs referencing
> - the snapshot problem: always denormalize stable data (product name at purchase);
> reference mutable shared data (user profile); snapshotting prevents stale data in
> historical records but requires a migration if the schema changes. (2) Bucket pattern
> for time-series - calculate the bucket partition size before implementing: 1000
> writes/second, 200 bytes each, 1-hour buckets = 720 MB per bucket - too large;
> use 1-minute buckets = 12 MB. (3) The dual-write problem - writing to multiple
> denormalized structures atomically; use MongoDB multi-document transactions if all
> structures are in the same replica set; for cross-cluster denormalization, use an
> idempotent event-driven sync (Kafka + exactly-once semantics). (4) Schema migration -
> NoSQL "schema-less" is a myth; the schema is in the application code; versioning
> the schema in a `schema_version` field and handling both old and new versions in
> the application is the correct migration approach (lazy migration pattern).

---

### ⚠️ Common Misconceptions

**Misconception 1: "NoSQL is schema-less, so I don't need to design the data model."**

NoSQL databases do not enforce schema at the database level, but the schema is in
the application code. Every `insertOne()` call encodes the expected document structure.
If the schema changes (add a field, rename a field, change a type), the application
must handle both old and new formats. The schema must be versioned and migrated, just
as in relational databases. The difference: NoSQL migrations can be lazy (migrate on
read) instead of requiring a blocking ALTER TABLE; but the design discipline is the same.
Schema-less means the database does not validate; it does not mean the schema does not
exist.

**Misconception 2: "I should always embed to minimize queries."**

Maximum embedding is not always optimal. Embedding everything into one giant document
causes: (1) MongoDB document size limit (16 MB) can be exceeded; (2) Reading a small
field requires transferring the entire large document over the network; (3) Atomic
updates of an inner array element require the entire array to be rewritten; (4) Index
selectivity decreases when all data is in one collection. The correct approach is
selective embedding: embed when the subdocument is always read with the parent, bounded
in size, and updated together with the parent.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Document exceeding the 16 MB limit (MongoDB).**

Symptom: `BSONObj too large` or `Document too large` error on insert or update.
Root cause: an array that was designed as a bounded embed has grown unbounded
(e.g., a `comments` array in a post document receiving unlimited comments).
Diagnosis: `db.collection.stats()` shows average document size; run
`db.collection.find().sort({_id:-1}).limit(10)` and check document sizes in
`Object.bsonsize()`.
Fix: change the array from embedded to referenced; create a separate `comments`
collection; maintain only the 10 most recent comments as an embedded snapshot
with a `comment_count` computed field.

**Failure Mode 2: Stale denormalized data causing inconsistency.**

Symptom: product names in historical orders show current name, not name at purchase;
or user display names in posts show a deleted user's current name.
Root cause: referencing instead of snapshotting for data that should be historical.
Diagnosis: compare order documents' embedded product name with the current product
in the products collection; discrepancy confirms referencing where snapshotting
was needed.
Fix: change to snapshot pattern; write the product name at purchase time as an
immutable field in the order item; do not reference the product by ID for display
in historical contexts.

---

### ⚖️ Comparison Table

| Pattern | When to Use | Trade-off |
|---|---|---|
| Embedding | Data always read together, bounded size | Fast read; large document updates |
| Referencing | Data accessed independently, unbounded | Flexible; extra query needed |
| Bucket Pattern | Time-series, high-frequency events | Fewer documents; complex writes |
| Computed Pattern | Frequent aggregate reads | Fast reads; write overhead; reconciliation |
| Polymorphic | Multiple types, shared queries | Single collection; sparse fields |

---

### 🏛️ System Design

*(Omit: L3 keyword; data modeling in full system context in L5 Architecture entry.)*

---

### 📊 Diagram

```text
NOSQL DATA MODELING DECISION FLOW:

  1. Write down ALL application queries
     |
  2. For each query:
     -> equality fields = partition key (Cassandra)
        or compound index (MongoDB)
     -> range fields = clustering columns or
        index range
     |
  3. Choose embedding vs referencing:
     Always together + bounded?
     -> EMBED (snapshot stable data)
     Unbounded or independent access?
     -> REFERENCE (with lookup table if needed)
     |
  4. High-frequency aggregates?
     -> COMPUTED PATTERN ($inc on write)
     |
  5. Time-series events?
     -> BUCKET PATTERN (group by time window)
     |
  6. Multiple entity types in one query?
     -> POLYMORPHIC (type discriminator)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the decision flow for selecting a NoSQL
> data modeling pattern, starting from the application queries and ending at specific
> patterns. (2) HOW TO READ IT: follow the steps top to bottom; each step narrows down
> the pattern choice based on the query characteristics and data access patterns. (3) KEY
> RELATIONSHIP: every pattern choice is driven by a query requirement; the pattern is
> the implementation of the query; changing the query may require changing the pattern.
> (4) EDGE CASE: some applications have many queries, some conflicting; embedding for
> query A may create an unbounded array that breaks query B; resolve by creating two
> collections - one per access pattern - and maintaining both on write. (5) INSIGHT: a
> senior engineer applies this flow before writing any collection/table schema; junior
> developers model the object graph first and then wonder why queries are slow; the
> correct order is always query-first, then data model.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Embedding, Computed Pattern |
| Application | 2 | Schema design, Bucket Pattern |
| Trade-off | 2 | Embed vs reference, Normalization vs denormalization |
| Scenario | 2 | Unbounded array, stale data |
| Mechanism | 1 | Snapshot pattern |

---

**[MID] Q1 (Definition): What is the difference between embedding and referencing in MongoDB? When do you use each?**

Embedding: store related data inside the same document. The subdocument has no
independent existence; it is always read with the parent.

```javascript
// Embedding: order + items (always read together)
{
  _id: "order123",
  items: [
    { product_id: "p1", quantity: 1, price: 99.99 }
  ]
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: an embedded document where order items are stored inside the order document. (2) KEY MECHANISM: both the order and its items are stored as a single MongoDB document; a `findOne` on the order returns all items in one I/O operation. (3) WHY IT MATTERS: no second query needed; single atomic read. (4) WHAT BREAKS: if `items` grows beyond a few hundred elements, the document approaches MongoDB's 16 MB limit. (5) TAKEAWAY: embed when the subdocument is bounded and always read with the parent.

Referencing: store related data in a separate document; store the reference (the `_id`)
in the parent. The application issues a second query to fetch the referenced document.

```javascript
// Referencing: post + comments (comments grow unboundedly)
{ _id: "post123", comment_ids: ["c1", "c2", "c3"] }
// or
{ _id: "c1", post_id: "post123", text: "Great post!" }
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two referencing approaches - embedding an array of IDs vs using a foreign-key-style `post_id` on the comment. (2) KEY MECHANISM: the `post_id` pattern (child stores parent reference) scales to unbounded comment counts; the `comment_ids` array approach requires updating the post on every new comment. (3) WHY IT MATTERS: the `post_id` pattern allows paginated comment queries without updating the post document. (4) WHAT BREAKS: the `comment_ids` array grows unboundedly; the post document size grows with each comment. (5) TAKEAWAY: for unbounded one-to-many, store the reference on the many side (child), not the one side (parent).

When to embed:
- Subdocument is always read with the parent (e.g., order items, product variants).
- Subdocument is bounded in size (no more than a few hundred items).
- Subdocument is updated together with the parent.
- Subdocument represents a historical snapshot (product name at purchase time).

When to reference:
- Subdocument grows unboundedly (e.g., user's comment history).
- Subdocument is accessed independently (e.g., comments need their own page).
- Subdocument is shared across multiple parents (e.g., user profile referenced
  from many orders).
- Subdocument is large and not always needed (e.g., product description on a
  listing page that only shows name and price).

*What separates good from great:* The snapshot vs reference trade-off for mutable
shared data. An order references a product by `product_id`. If the product name
changes, should the order show the old name (historical truth) or new name (current
name)? For order history: embed the name at purchase time (snapshot). For "get
user's current shopping cart items": reference the product to show the current name
and price. The same entity (product) requires embedding or referencing depending
on the temporal context of the query.

---

**[MID] Q2 (Application): How would you model a MongoDB collection for a blog with posts and comments, where comments should be paginated?**

Requirements: posts have many comments (unbounded); comments are paginated (10 per
page); both posts and comments should be searchable; comments are authored by users.

Design:

```javascript
// Collection 1: posts
{
  _id: ObjectId("..."),
  title: "NoSQL Modeling",
  content: "...",
  author: {       // embedded (snapshot, stable)
    user_id: ObjectId("..."),
    name: "Alice",
    avatar_url: "/avatars/alice.jpg"
  },
  tags: ["nosql", "mongodb"],
  published_at: ISODate("2024-01-15"),
  comment_count: 47,  // Computed Pattern
  like_count: 120
}

// Collection 2: comments (separate, referenced)
{
  _id: ObjectId("..."),
  post_id: ObjectId("..."),  // reference to post
  author: {      // embedded snapshot
    user_id: ObjectId("..."),
    name: "Bob"
  },
  content: "Excellent article!",
  created_at: ISODate("2024-01-16T10:00:00Z"),
  like_count: 3
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the two-collection blog schema with an embedded author snapshot in the comments collection. (2) KEY MECHANISM: `author` is embedded as a snapshot in both posts and comments; if the user changes their display name, historical comments still show the original name at posting time. (3) WHY IT MATTERS: comments are in a separate collection (referenced) to support unbounded growth and pagination; author is embedded (snapshotted) to preserve historical accuracy. (4) WHAT BREAKS: adding a `comment_ids` array to the post document for referencing comments creates an unbounded array; use the `post_id` on the comment side instead. (5) TAKEAWAY: embed author snapshots for historical records; use a foreign-key reference (`post_id` on the comment) for the one-to-many relationship.

Indexes: `comments.post_id` (find comments by post); `comments.created_at`
(pagination sort); `posts.tags` (tag-based search).

Pagination query: `db.comments.find({ post_id: X }).sort({ created_at: -1 }).skip(page * 10).limit(10)`

Use cursor-based pagination for large comment counts: instead of `skip()` (which
scans from the start), use `{ created_at: { $lt: last_seen_date } }` to continue
from a cursor.

*What separates good from great:* The `skip()`-based pagination performance cliff.
`skip(N)` requires Cassandra to scan and discard N documents even with an index;
on page 100 (1000 skipped documents), the query scans 1000 rows before returning 10.
Cursor-based pagination (`created_at < last_cursor`) uses the index directly; it
goes directly to the cursor position and reads 10; performance is constant regardless
of page number. For any paginated list beyond page 10-20, cursor-based pagination
is required.

---

**[SENIOR] Q3 (Mechanism): Explain the Bucket Pattern. When does it apply and what are the trade-offs?**

The Bucket Pattern groups multiple time-series events into one document by a time window
(hour, day, or another interval). Instead of one document per event, one document contains
N events as an array.

Structure:

```javascript
// Bucket document (1 hour of sensor data)
{
  device_id: "sensor_42",
  bucket_start: ISODate("2024-01-15T14:00:00Z"),
  bucket_end:   ISODate("2024-01-15T15:00:00Z"),
  count: 3600,
  // Pre-computed aggregates (Computed Pattern)
  min_temp: 21.0, max_temp: 25.2, avg_temp: 23.1,
  // Time-offset array (saves bytes vs full timestamps)
  readings: [
    { s: 0, t: 23.1 },    // s = seconds offset
    { s: 1, t: 23.3 },
    // ... 3598 more
  ]
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a bucket document aggregating 3600 per-second sensor readings into one hourly document with pre-computed min/max/avg. (2) KEY MECHANISM: 3600 events collapse to 1 document; time offsets (seconds from bucket_start) reduce storage vs full timestamps; pre-computed aggregates eliminate aggregation pipeline queries. (3) WHY IT MATTERS: query for a 2-hour window reads 2 documents instead of 7200. (4) WHAT BREAKS: if pre-computed aggregates use a read-modify-write (compute avg in app, then write), concurrent inserts create race conditions; use `$inc` on `count` and `sum` atomically instead. (5) TAKEAWAY: store sum and count atomically with `$inc`; compute average at read time from sum/count to avoid race conditions.

Benefits:
- Document count reduced by the bucket size (3600 for hourly with per-second events).
- Index size reduced proportionally (less index overhead per event).
- Pre-computed aggregates eliminate aggregation pipeline queries.
- Time-range queries read complete buckets instead of individual events.

Trade-offs:
- Writes must update the current bucket (array push + aggregate update), not simple
  inserts; requires atomic `$push` + `$inc` or `$min`/`$max` operations.
- Reading specific events within a bucket requires array element access.
- Bucket boundaries must be chosen carefully: too large -> documents become huge;
  too small -> too many documents (bucket pattern not effective).

When to apply: IoT sensor data, user activity events, financial tick data, log
aggregation - any workload with high-frequency uniform events.

*What separates good from great:* The hot-path bucket update atomicity. On a write to
an in-progress bucket, you need to atomically push a new reading and update min/max/avg.
For min: `$min: { min_temp: newTemp }`. For avg: you cannot atomically update an average
with a new data point without storing the running sum; store `sum_temp` and `count` and
compute the average at read time. The Computed Pattern within the Bucket Pattern requires
careful thought about which aggregates can be maintained atomically vs which must be
computed at read time.

---

**[SENIOR] Q4 (Trade-off): Compare NoSQL denormalization vs relational normalization. What does the NoSQL approach sacrifice?**

Relational normalization:
- Data stored once; no duplication.
- Any query possible via JOINs.
- Updates affect one place; no inconsistency from stale copies.
- Schema enforced by database; data integrity guaranteed.
- Query flexibility: add new queries without changing the schema.

NoSQL denormalization:
- Data duplicated across multiple structures.
- Each structure serves specific queries efficiently.
- Updates must be propagated to all copies; risk of inconsistency.
- Application enforces schema and consistency; database does not.
- New queries may require new structures (schema change).

What NoSQL sacrifices:
1. **Write consistency**: updating "Alice"s username requires updating every
   document that embeds it (orders, posts, comments). Missed updates create
   stale copies. Relational: update users table once.
2. **Storage efficiency**: data is duplicated; storage cost increases with
   denormalization degree.
3. **Query flexibility**: adding an unforeseen query may require a new collection/
   table and a backfill of historical data.
4. **Data integrity**: no foreign key constraints; orphaned references (referencing
   a deleted document) are silently allowed.

What NoSQL gains:
1. **Read performance**: single document read for complex joined data.
2. **Write throughput**: no JOIN-required read before write; append-only paths.
3. **Horizontal scaling**: data is co-located per partition key; no cross-shard joins.
4. **Schema evolution flexibility**: add fields without ALTER TABLE; old and new
   formats coexist.

*What separates good from great:* The eventual consistency risk for embedded data.
Embedded usernames, product names, and category labels are snapshots; they diverge
from the source over time if not updated. The correct classification: data that must
reflect the current state (user's account status, product availability) should be
referenced; data that represents historical state (price at purchase, author at
post time) should be embedded as a snapshot. Confusing the two is the most common
NoSQL modeling error in production systems.

---

**[SENIOR] Q5 (Application): A MongoDB collection is slow when displaying product listings that need to show average rating. How do you fix this?**

Slow query root cause: each product page or listing executes an aggregation:

```javascript
db.reviews.aggregate([
  { $match: { product_id: "p123" } },
  { $group: { _id: null, avg_rating: { $avg: "$rating" } } }
]);
// Scans all reviews for this product on every page load
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the BAD pattern - computing average rating at query time by aggregating all reviews for a product on every page load. (2) KEY MECHANISM: `$match` filters to the product's reviews; `$group` computes the average; this scans all review documents for this product on every call. (3) WHY IT MATTERS: on a product with 10,000 reviews, every page load scans 10,000 documents for the average. (4) WHAT BREAKS: at high request rates (1000 page loads/second), this generates 10 million document scans per second for one product. (5) TAKEAWAY: pre-compute aggregates at write time using the Computed Pattern; eliminate runtime aggregation for frequently-read aggregates.

Fix: Computed Pattern - pre-compute and cache the average rating in the product
document:

```javascript
// Product document
{
  _id: "p123",
  name: "Laptop",
  price: 999.00,
  rating_count: 142,
  rating_sum: 596,
  rating_avg: 4.20  // cached = rating_sum / rating_count
}

// On new review submission:
db.products.updateOne(
  { _id: "p123" },
  {
    $inc: { rating_count: 1, rating_sum: newRating },
    $set: {
      rating_avg: (current_sum + newRating) /
                  (current_count + 1)
    }
  }
)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Computed Pattern caching average rating in the product document; `$set` on `rating_avg` requires knowing `current_sum` and `current_count` before the update - a read-modify-write pattern. (2) KEY MECHANISM: `$inc` atomically updates sum and count; `$set` sets the new average computed in application code; but this requires reading the current values first (not shown). (3) WHY IT MATTERS: the read-modify-write for `rating_avg` is a race condition; two concurrent reviews can both read count=142, both compute a wrong average. (4) WHAT BREAKS: the `rating_avg` can drift from the true average under concurrent writes. (5) TAKEAWAY: never compute the average in application code and `$set` it; instead store sum+count and compute avg at read time.

Better approach (avoid read-modify-write): store sum and count atomically, compute
average at read time:

```javascript
// On new review: atomic (no prior read needed)
db.products.updateOne(
  { _id: "p123" },
  { $inc: { rating_count: 1, rating_sum: newRating } }
);
// At read time: avg = rating_sum / rating_count
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the correct Computed Pattern using only atomic `$inc` operations; no read required before the write. (2) KEY MECHANISM: `$inc` is a server-side atomic operation; no read-modify-write; concurrent reviews each atomically increment count and sum; the average is computed at read time as `rating_sum / rating_count`. (3) WHY IT MATTERS: this is race-condition-free; 1000 concurrent reviews each atomically update sum and count; the final values are always correct. (4) WHAT BREAKS: if reviews can be deleted, `$inc` with negative values decrements; always pair insert with increment and delete with decrement. (5) TAKEAWAY: use `$inc` for counters and sums; compute derived values (average, percentage) at read time from the atomic source fields.

*What separates good from great:* The computed average drift problem. If reviews can
be updated or deleted, the `rating_sum` must be decremented correctly. Deleting a 5-star
review requires `$inc: { rating_count: -1, rating_sum: -5 }`. For updates (change a 4-
star to 3-star), use `$inc: { rating_sum: -1 }`. Store `sum` and `count` as the source
of truth; never directly store the average as the source because correcting it on delete
or update requires a read-modify-write; the atomic `$inc` on sum and count avoids
read-modify-write and is always correct.

---

**[SENIOR] Q6 (Scenario): You discover that an orders collection in MongoDB is very slow on "get all orders by a specific user, sorted by date." What are the steps to diagnose and fix this?**

Step 1 - Analyze the query:

```javascript
db.orders.find(
  { user_id: "u123" }
).sort({ created_at: -1 });
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the slow query that filters by `user_id` and sorts by `created_at` descending. (2) KEY MECHANISM: without an index on `user_id`, MongoDB performs a COLLSCAN (full collection scan) on every execution; with millions of orders, this scans all orders to find the few belonging to this user. (3) WHY IT MATTERS: a COLLSCAN on a large collection takes seconds; even with a `user_id` index, sorting may require an in-memory sort if the index does not include `created_at`. (4) WHAT BREAKS: a single-field index on `user_id` requires an in-memory sort on `created_at`; MongoDB has a 100 MB sort memory limit; large result sets fail with `Sort exceeded memory limit`. (5) TAKEAWAY: use a compound index `{ user_id: 1, created_at: -1 }` to serve both the filter and the sort from one index scan without an in-memory sort.

Step 2 - Run EXPLAIN:

```javascript
db.orders.find(
  { user_id: "u123" }
).sort({ created_at: -1 }).explain("executionStats");
// Check: winningPlan.stage
// COLLSCAN = no index -> full collection scan
// IXSCAN = index scan -> check index efficiency
// Check: totalDocsExamined vs nReturned
// 1000:10 ratio = scanning 100 docs per result
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `explain("executionStats")` on the slow query to diagnose the execution plan. (2) KEY MECHANISM: `winningPlan.stage: "COLLSCAN"` confirms no index is used; `totalDocsExamined` vs `nReturned` shows scan efficiency; a 1000:10 ratio means 100 documents scanned per result returned - very inefficient. (3) WHY IT MATTERS: `explain()` is the primary tool for MongoDB query diagnosis; it shows exact execution plan, index usage, documents examined, and execution time. (4) WHAT BREAKS: running `explain()` on a production primary can add load; use `explain()` on a secondary or in a staging environment for large queries. (5) TAKEAWAY: check `totalDocsExamined / nReturned` ratio; a ratio above 5:1 indicates an inefficient scan; target a ratio as close to 1:1 as possible with the right index.

Step 3 - Identify the problem: likely `COLLSCAN` with no index on `user_id`.

Step 4 - Add a compound index:

```javascript
// Index on (user_id, created_at DESC)
// covers both the filter and the sort
db.orders.createIndex(
  { user_id: 1, created_at: -1 },
  { background: true }  // non-blocking
);
```

> **Code walkthrough:** (1) WHAT IT SHOWS: creating a compound index on `(user_id, created_at DESC)` to serve the filter and sort in one index scan. (2) KEY MECHANISM: the compound index stores entries sorted by `user_id` first, then `created_at` descending within each user; MongoDB can satisfy `WHERE user_id=? ORDER BY created_at DESC` by scanning a contiguous range of the index; no in-memory sort needed. (3) WHY IT MATTERS: the compound index eliminates both the COLLSCAN and the in-memory sort; query time drops from O(N) to O(log N + result size). (4) WHAT BREAKS: `{ background: true }` builds the index without blocking writes; without it, the index build takes a write lock; on a large collection, this blocks all writes for minutes. (5) TAKEAWAY: always use `{ background: true }` for index creation on production collections; the index build still takes the same total time but does not block other operations.

Step 5 - Verify: re-run `explain("executionStats")`. Look for:
- `winningPlan.stage: "IXSCAN"`
- `totalDocsExamined` approximately equal to `nReturned`
- `executionTimeMillis` reduced by 10-100x

*What separates good from great:* The index selectivity analysis. After adding the
index, verify the index size vs the benefit: `db.orders.stats().indexSizes` shows
index size. If `user_id` has very high cardinality (each user has very few orders),
the index on `user_id` alone may be sufficient; the compound index on
`(user_id, created_at)` avoids an in-memory sort after the index scan. The compound
index covers the query entirely (no FETCH stage) only if the projection includes only
indexed fields; for full document retrieval, the FETCH stage is needed but the scan
is efficient. Understanding the execution plan stages (IXSCAN -> FETCH -> SORT)
and when each is triggered is the mark of senior-level MongoDB knowledge.

---

**[SENIOR] Q7 (Trade-off): What is the "lazy migration" pattern and when does it apply to NoSQL schema changes?**

Lazy migration: instead of running a bulk migration that updates all existing documents
at once, update documents from the old schema to the new schema on read (when the
document is accessed).

Implementation:

```javascript
// Old schema: { name: "Alice Smith" }
// New schema: { first_name: "Alice", last_name: "Smith" }

async function getUser(user_id) {
  let user = await db.users.findOne({ _id: user_id });

  // Lazy migration: upgrade on read
  if (user.name && !user.first_name) {
    const [first, ...rest] = user.name.split(" ");
    const last = rest.join(" ");
    await db.users.updateOne(
      { _id: user_id },
      {
        $set: { first_name: first, last_name: last },
        $unset: { name: "" }
      }
    );
    user.first_name = first;
    user.last_name = last;
  }
  return user;
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: lazy migration that upgrades documents from old schema (single `name` field) to new schema (`first_name`, `last_name`) on read. (2) KEY MECHANISM: the check `if (user.name && !user.first_name)` detects old-schema documents; the update writes the new fields and removes the old field; the in-memory user object is updated to return the new schema to the caller. (3) WHY IT MATTERS: the migration runs on demand without a blocking bulk update; large collections with 100M+ documents can migrate over weeks as each document is accessed. (4) WHAT BREAKS: adding a new index on `first_name` before the migration completes will not cover documents still on the old schema; queries using `first_name` return no results for unmigrated documents. (5) TAKEAWAY: lazy migration works when: (a) all queries tolerate partial migration, and (b) new indexes are added after migration completes or the application handles both schemas.

When to use:
- Very large collections where a bulk migration would lock production performance.
- Infrequently accessed documents where the migration overhead is small.
- Rolling deployments where old and new application versions must coexist.

When NOT to use:
- When the new schema field is required for queries (e.g., a new index on
  `first_name` will not cover unmigrated documents).
- When the schema change requires a backfill for business logic correctness.
- When the collection is small enough for an immediate migration.

*What separates good from great:* The schema version field. Add a `schema_version: 1`
(or `schema_version: 2`) field to every document. The application knows which migration
steps to apply based on the `schema_version`. Without a schema version, the migration
logic must detect the old schema by checking for the presence/absence of fields, which
becomes complex across multiple schema versions. A schema version field makes the
migration logic explicit, readable, and testable.

---

---

# Consistency Levels in Distributed NoSQL

---

### 🎯 Model Answer

**30 seconds:**
> Consistency in distributed NoSQL refers to whether a read returns the most recent
> write. The main models: strong consistency (every read sees the latest write),
> eventual consistency (reads eventually see the latest write, but may return stale
> data during a short window), and read-your-own-writes (you always see your own writes
> even if others see stale data). Cassandra and DynamoDB offer tunable consistency per
> operation; MongoDB offers per-operation read concern; Redis is strongly consistent
> for single-node, eventually consistent for async replication.

**3 minutes (Senior):**
> Consistency models from strongest to weakest: (1) Linearizable - reads reflect all
> writes, globally ordered; most expensive; Cassandra LWT, MongoDB with `j:true` +
> `w:majority`. (2) Sequential - operations appear in a global order but may lag;
> MongoDB with `readConcern: majority`. (3) Bounded staleness - reads may be up to N
> seconds stale; DynamoDB Global Tables with cross-region replication. (4) Session/
> monotonic - client sees its own writes; within a session, reads advance monotonically;
> common default for client-side drivers. (5) Eventual - reads may return any replica's
> state; DynamoDB with eventually consistent reads; Cassandra `ONE`. The trade-off:
> stronger consistency requires quorum coordination (more latency, less availability);
> weaker consistency allows local reads (less latency, more availability). Choose based
> on whether incorrect stale data would cause business logic errors.

**Framework:** Linearizable -> Sequential -> Bounded Staleness -> Session -> Eventual (strongest to weakest, most to least expensive)

**Blank Mind Recovery:**

**(1) Restate:** "Consistency levels: strong (see all writes), eventual (see writes
eventually), tunable (choose per query). Cassandra: QUORUM reads+writes = strong. MongoDB:
readConcern: majority = strong. DynamoDB: strongly consistent or eventually consistent
reads. Trade-off: latency vs correctness."

**(2) First principles:** "Distributed system: data on multiple nodes. Writes go to some
nodes. Reads from any node. If the read node hasn't received the write yet, you get stale
data. Strong consistency forces all reads to check recent writes (quorum); eventual
consistency allows reading from any node without coordination."

**(3) Bridge:** "Consistency levels are like newspaper printing. Eventual consistency:
read today's paper, some editions haven't received last-minute updates yet. Strong
consistency: wait until all printing presses confirm, then distribute; takes longer
but everyone gets the same news."

---

### 📘 Concept Explanation

**The Consistency Spectrum:**

```text
CONSISTENCY SPECTRUM:

  STRONGEST                         WEAKEST
       |                                |
  Linearizable  Sequential  Monotonic  Eventual
       |             |           |         |
  All reads     Global      Client     Any
  globally      order       sees own   replica
  ordered       (may lag)   writes     any time

  LATENCY:   HIGH         MEDIUM      LOW      LOWEST
  AVAIL:     LOW          MEDIUM      HIGH     HIGHEST

  DATABASE IMPLEMENTATIONS:
  Cassandra:
    QUORUM R + QUORUM W    -> Strong (de facto serial)
    LOCAL_QUORUM R+W       -> Strong within DC
    ONE                    -> Eventual

  MongoDB:
    w:majority + readConcern:majority -> Linearizable*
    w:majority + readConcern:local    -> Session
    w:1        + readConcern:local    -> Eventual

  DynamoDB:
    Strongly consistent read (2x cost) -> Strong
    Eventually consistent read (default)-> Eventual

  * MongoDB linearizable requires session-level
    causal consistency or readConcern:linearizable
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the consistency spectrum from
> linearizable (strongest) to eventual (weakest), with latency/availability trade-offs
> and specific database implementations mapped to the spectrum. (2) HOW TO READ IT:
> move left to right; each level weakens the consistency guarantee; the database
> implementations show how each system provides each level. (3) KEY RELATIONSHIP:
> stronger consistency requires more nodes to coordinate (quorum); more coordination
> means more latency and reduced availability when nodes are unreliable. (4) EDGE CASE:
> MongoDB's `readConcern: linearizable` requires that the read itself participates in
> consensus; it reads from the primary only and waits for a majority quorum; latency
> is 3-5x higher than a local read. (5) INSIGHT: a senior engineer notices that
> "session consistency" (monotonic reads and read-your-own-writes) is often sufficient
> for user-facing applications; the user always sees their own writes and sees an
> advancing timeline; other users' stale reads are acceptable; full linearizability
> is only required for distributed locks, account balance checks, and inventory
> management.

---

### 💻 Code Example

```python
import boto3
from pymongo import MongoClient, ReadPreference
from pymongo.read_concern import ReadConcern
from pymongo.write_concern import WriteConcern

# DynamoDB: strong vs eventual consistency read
dynamo = boto3.resource("dynamodb", region_name="us-east-1")
table = dynamo.Table("user_accounts")

# EVENTUALLY CONSISTENT READ (default, half the cost)
response = table.get_item(
    Key={"user_id": "u123"},
    # ConsistentRead defaults to False = eventual
)
user = response.get("Item")

# STRONGLY CONSISTENT READ (double the cost)
response = table.get_item(
    Key={"user_id": "u123"},
    ConsistentRead=True   # forces leader read
)
user = response.get("Item")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: DynamoDB's two read modes - eventually
> consistent (default) and strongly consistent (explicit flag) - and the cost difference.
> (2) KEY MECHANISM: eventually consistent reads can be served by any replica node in
> the DynamoDB storage layer; strongly consistent reads must go to the leader partition
> which has the most up-to-date data; DynamoDB uses a Paxos-based consensus for leader
> elections; the leader always has the latest committed write. (3) WHY IT MATTERS:
> DynamoDB charges per Read Capacity Unit; a strongly consistent read costs 2x because
> it uses more resources (must contact the leader); for read-heavy applications on
> eventually-consistent data, the 2x cost adds up. (4) WHAT BREAKS: using eventually
> consistent reads for account balance checks or inventory availability can return stale
> data; a user might see a balance that doesn't reflect their last deposit; always use
> strongly consistent reads for financial and inventory operations. (5) TAKEAWAY: default
> to eventually consistent reads for non-critical data (user profiles, product catalog);
> use strongly consistent reads only for operations where stale data causes business
> logic errors.

```python
# MongoDB: write concern + read concern pairing
# for strong consistency
client = MongoClient("mongodb://mongoprimary:27017")

# Strong consistency collection (financial transactions)
accounts = client.bank.get_collection(
    "accounts",
    write_concern=WriteConcern(w="majority", j=True),
    read_concern=ReadConcern("majority")
)

# Session-based causal consistency (user sees own writes)
with client.start_session() as session:
    session.start_transaction(
        write_concern=WriteConcern(w="majority"),
        read_concern=ReadConcern("snapshot")
    )
    try:
        # Debit sender (within transaction)
        accounts.update_one(
            { "user_id": "u1",
              "balance": { "$gte": 100 } },
            { "$inc": { "balance": -100 } },
            session=session
        )
        # Credit receiver
        accounts.update_one(
            { "user_id": "u2" },
            { "$inc": { "balance": 100 } },
            session=session
        )
        session.commit_transaction()
    except Exception as e:
        session.abort_transaction()
        raise e
```

> **Code walkthrough:** (1) WHAT IT SHOWS: MongoDB write concern `w:majority, j:true`
> paired with `readConcern: majority` for strong consistency on a bank accounts
> collection, and a multi-document transaction for an account transfer. (2) KEY
> MECHANISM: `w:majority` requires a majority of replica set members to write to their
> journal before acknowledging; `j:true` requires journal flush (durable to disk);
> `readConcern: majority` only returns data that has been confirmed by a majority; these
> two together ensure reads always return committed, durable data. (3) WHY IT MATTERS:
> without `w:majority`, a write to the primary can be lost if the primary fails before
> replicating; `readConcern: local` (default) can return data that is later rolled back
> during a replica set failover. (4) WHAT BREAKS: `w:majority` adds significant latency
> (must wait for secondary acknowledgment); for applications sensitive to write latency,
> use `w:1` for non-critical writes and `w:majority` only for financial operations. (5)
> TAKEAWAY: use `w:majority, j:true` + `readConcern:majority` as the default for any
> financial or inventory operation; accept the latency cost to prevent data loss; for
> general application data, `w:1` + `readConcern:local` is acceptable.

```python
# ANTI-PATTERN: reading own writes without session
# In a distributed system, read after write may hit
# a replica that has not yet received the write

# BAD: no causal consistency guarantee
async def update_user_profile_bad(user_id, new_name):
    await users_collection.update_one(
        { "_id": user_id },
        { "$set": { "name": new_name } }
    )
    # May return the OLD name if read hits a replica
    # that has not yet replicated the write
    user = await users_collection.find_one(
        { "_id": user_id }
    )
    return user["name"]  # might return old name!

# GOOD: use a session for causal consistency
async def update_user_profile_good(user_id, new_name):
    with client.start_session() as session:
        await users_collection.update_one(
            { "_id": user_id },
            { "$set": { "name": new_name } },
            session=session
        )
        # Session guarantees causal consistency:
        # this read will see the write above
        user = await users_collection.find_one(
            { "_id": user_id },
            session=session
        )
    return user["name"]  # always returns new_name
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the read-after-write consistency problem in
> MongoDB and the session-based causal consistency solution. (2) KEY MECHANISM: MongoDB
> replication is asynchronous; secondaries may lag behind the primary; a read routed to
> a secondary can return data before the latest write has replicated; a MongoDB session
> tracks a cluster time and operation time; reads within a session are guaranteed to
> see all writes from that session regardless of which replica serves the read. (3) WHY
> IT MATTERS: the BAD pattern causes a very subtle bug: the user updates their profile
> name and the confirmation UI shows the OLD name; this creates a confusing user
> experience; the bug is intermittent (only occurs when the read hits a lagging secondary)
> and hard to reproduce in testing. (4) WHAT BREAKS: sessions have overhead; do not
> create a new session per operation; reuse sessions per request/transaction; session
> pooling is managed by the driver. (5) TAKEAWAY: any "update, then read" operation that
> must show the updated data requires a MongoDB session for causal consistency; without
> a session, MongoDB does not guarantee read-after-write consistency on a replica set.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Eventual consistency means a read might return old data for a short time after a write.
> Strong consistency means a read always returns the latest write. DynamoDB default is
> eventual; set `ConsistentRead=True` for strong. Cassandra default depends on the
> consistency level; `QUORUM` reads + writes give strong consistency. MongoDB default is
> eventually consistent on replicas; use sessions for read-after-write. Use strong
> consistency for financial data, inventory, and anything where stale data causes errors.
> Use eventual consistency for counters, caches, and non-critical reads.

---

**Senior / Staff (5+ years):**
> Consistency level selection with production consequences: (1) The consistency vs
> availability trade-off (CAP theorem) - in a network partition, you cannot have both
> strong consistency and high availability; choose based on the use case: bank balance
> = consistency, social media likes = availability. (2) DynamoDB global tables -
> eventually consistent by default across regions; `ConsistentRead=True` only works
> within a region; cross-region reads are always eventually consistent with a typical
> lag of < 1 second but potentially longer during network issues. (3) MongoDB read
> preference - `primary` (always consistent), `primaryPreferred` (consistent if primary
> available, falls back to secondary), `secondary` (might be stale); most production
> read-heavy workloads use `primaryPreferred` and accept occasional stale reads. (4) The
> "read your own writes" guarantee - requires session causal consistency in MongoDB;
> requires `QUORUM` in Cassandra; requires strongly consistent reads in DynamoDB; failure
> to implement this causes confusing UX bugs that are hard to reproduce.

---

### ⚠️ Common Misconceptions

**Misconception 1: "NoSQL is always eventually consistent."**

This is historically true for early NoSQL systems but incorrect today. MongoDB with
`w:majority` + `readConcern:majority` provides strong consistency. Cassandra with
`QUORUM` reads and writes provides strong consistency. DynamoDB with `ConsistentRead=True`
provides strong consistency within a region. All major NoSQL systems offer tunable
consistency. The choice is per operation, not per database. The correct statement: NoSQL
defaults to weaker consistency modes for performance; stronger consistency is available
at higher cost.

**Misconception 2: "Eventual consistency means data can be wrong forever."**

Eventual consistency has a convergence guarantee: given no new writes, all replicas will
eventually converge to the same value. The "eventually" is typically milliseconds to
seconds, not minutes or hours. The risk is not that data is permanently wrong; the risk
is that a read immediately after a write may see the pre-write value. For most user-
facing applications (social media, product listings, analytics), returning a value from
100ms ago is acceptable; the user will not notice.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Read-after-write returning stale data (MongoDB).**

Symptom: user updates their display name; the profile page still shows the old name;
refreshing the page shows the new name; the bug is intermittent.
Root cause: the write goes to the primary; the read is routed to a secondary that has
not yet replicated the write.
Diagnosis: add logging for which replica serves each read; confirm that stale reads
come from secondaries.
Fix: use MongoDB sessions for causal consistency (read within the same session always
sees the session's writes); or set `readPreference: primary` for profile reads (all reads
go to the primary; adds load to the primary).

**Failure Mode 2: DynamoDB conditional write failure under contention.**

Symptom: `ConditionalCheckFailedException` in application logs; inventory counts
decrement incorrectly; some inventory is double-counted.
Root cause: multiple processes updating the same DynamoDB item using a conditional
expression (`ConditionExpression: "#count > :zero"`) without proper retry logic;
under high contention, most conditional writes fail.
Diagnosis: count `ConditionalCheckFailedException` in CloudWatch metrics; high failure
rate confirms contention.
Fix: implement exponential backoff retry on `ConditionalCheckFailedException`; use
DynamoDB atomic counters (`ADD` operation) for inventory decrements which do not
require conditional expressions; or use DynamoDB Transactions for multi-item
inventory operations.

---

### ⚖️ Comparison Table

| System | Default Consistency | Strong Consistency | Cost of Strong |
|---|---|---|---|
| Cassandra | Eventual (ONE) | QUORUM reads+writes | ~2x latency |
| MongoDB | Local (primary) | w:majority + readConcern:majority | ~3x latency |
| DynamoDB | Eventual | ConsistentRead=True | 2x read cost |
| Redis | Strong (single node) | N/A (single-threaded atomic) | No extra cost |
| Redis Cluster | Strong per slot | N/A | No extra cost |

---

### 🏛️ System Design

*(Omit: L3 keyword; full consistency strategy in distributed systems in L5 Architecture entry.)*

---

### 📊 Diagram

```text
QUORUM CONSISTENCY (Cassandra RF=3):

  Write (QUORUM = 2 of 3):
  Client -> Coordinator -> Node A (ACK)
                        -> Node B (ACK)  <- QUORUM met
                        -> Node C (slow)

  Read (QUORUM = 2 of 3):
  Client -> Coordinator -> Node A (v2)
                        -> Node B (v1)  <- QUORUM met
                        -> Node C (skip)

  Coordinator compares versions:
    v2 > v1 -> return v2 (latest)
    Trigger read repair: send v2 to Node B

  GUARANTEE: Write QUORUM (A, B) ∩ Read QUORUM (A, B)
  -> Overlap on Node A -> Node A has v2
  -> Read always returns v2 (or newer)

  FAILURE MODE (without QUORUM):
  Write ONE (only Node A): A=v2, B=v1, C=v1
  Read ONE (Node B): returns v1 (stale!)
  No overlap guaranteed -> stale read possible
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: how QUORUM reads and writes in Cassandra
> guarantee strong consistency by ensuring the read and write quorums always overlap on at
> least one replica. (2) HOW TO READ IT: the write quorum writes to A and B; the read
> quorum reads from A and B; A is in both quorums; A has the latest write; the coordinator
> returns the latest version and triggers read repair on any stale replica. (3) KEY
> RELATIONSHIP: the intersection of any write quorum and any read quorum on a set of RF
> replicas is always at least one replica; that replica has the latest data; this is the
> mathematical proof of strong consistency under QUORUM. (4) EDGE CASE: if the write
> quorum is not met (e.g., write to only ONE replica), the guarantee breaks; a read to a
> different ONE replica returns stale data; always pair read and write consistency levels
> at QUORUM for strong consistency. (5) INSIGHT: a senior engineer notes that
> `LOCAL_QUORUM` is preferred over `QUORUM` in multi-DC deployments; `QUORUM` counts
> replicas across all datacenters, increasing latency by the cross-DC round-trip time;
> `LOCAL_QUORUM` achieves strong consistency within the local datacenter without
> cross-DC coordination.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Eventual vs strong, QUORUM proof |
| Application | 2 | MongoDB session, DynamoDB consistent read |
| Trade-off | 2 | Consistency vs availability, cost |
| Scenario | 2 | Read-after-write bug, contention |
| Mechanism | 1 | QUORUM intersection proof |

---

**[MID] Q1 (Definition): What is eventual consistency and when is it acceptable?**

Eventual consistency: if no new writes are made to a data item, all replicas will
eventually converge to the same value. A read may return any replica's current value,
which may be slightly older than the most recent write. The convergence time is typically
milliseconds to low seconds in healthy systems.

When eventual consistency is acceptable:
- User preference data (theme, language) - a 1-second stale read is unnoticeable.
- Product catalog prices - acceptable if the price will be confirmed at checkout.
- Social media like counts - exact count matters less than approximate count.
- Analytics dashboards - aggregate metrics tolerate seconds of staleness.
- Cache data - caches are inherently stale; stale data is the expected behavior.
- Read-heavy content (articles, images) - content does not change frequently.

When eventual consistency is NOT acceptable:
- Account balance after a deposit - user must see updated balance.
- Inventory count at checkout - must not oversell.
- Reservation system - must not double-book.
- Two-factor authentication token - must see the latest invalidation.
- Session token revocation - must not allow access with a revoked token.

*What separates good from great:* The eventual consistency + idempotency pattern. Even
when eventual consistency is acceptable for reads, writes that modify shared state must
be idempotent to handle network retries. A write that is retried due to a timeout but
actually succeeded must not double-apply. Use a unique idempotency key (a client-generated
UUID) in every write operation; the server checks if the key was already processed before
applying the write. This pattern makes eventual consistency safe for state-modifying
operations.

---

**[MID] Q2 (Application): How does MongoDB's `readConcern` affect what data a query returns?**

`readConcern: local` (default): returns the most recent data on the queried node (primary
or secondary) without checking whether it has been replicated to a majority. This data
may be rolled back during a failover if the primary crashes before the write is replicated.
Best for: most application reads where a small risk of seeing pre-rollback data is
acceptable.

`readConcern: available`: similar to `local` but allows reading from any shard/node
without routing overhead. Used for sharded clusters where routing consistency is not
required.

`readConcern: majority`: only returns data that has been written to a majority of replica
set members. This data is durable and will not be rolled back. Best for: financial
transactions, inventory, and any data where reading a rolled-back state would cause
a business logic error.

`readConcern: linearizable`: only works with reads from the primary; ensures the read
reflects all writes globally ordered before the read starts. Requires the read itself
to participate in consensus. Best for: distributed locking, leader election.

`readConcern: snapshot`: reads data from a consistent snapshot at a given point in time;
used within multi-document transactions to provide isolation. Best for: transactions
that need a consistent view across multiple documents.

*What separates good from great:* The `readConcern: majority` + `writeConcern: majority`
pairing requirement. `readConcern: majority` only returns data committed to a majority;
if the write was done with `w:1` (only primary), the data may not be in the majority
read view yet; the read returns the old value. For strong consistency, the write must
use `w:majority` to ensure the data is in the majority state before the read can see it.
Always pair write and read concern levels to achieve the intended consistency guarantee.

---

**[SENIOR] Q3 (Mechanism): Prove mathematically why QUORUM reads + QUORUM writes guarantee strong consistency in Cassandra.**

Given:
- RF (Replication Factor) = 3: data stored on 3 nodes.
- QUORUM = RF/2 + 1 = 2: any QUORUM operation must touch 2 of the 3 nodes.

Write QUORUM: the write is confirmed on at least 2 of the 3 nodes (call them W_nodes).

Read QUORUM: the read queries at least 2 of the 3 nodes (call them R_nodes).

Intersection proof:
- |W_nodes| = 2 (write quorum)
- |R_nodes| = 2 (read quorum)
- |total nodes| = 3 (RF)
- By pigeonhole principle: |W_nodes ∪ R_nodes| <= 3 (total nodes)
- |W_nodes ∩ R_nodes| = |W_nodes| + |R_nodes| - |W_nodes ∪ R_nodes|
  >= 2 + 2 - 3 = 1

Therefore, at least one node is in both W_nodes and R_nodes. That node has the latest
write. The read coordinator receives responses from R_nodes and compares timestamps;
the response from the intersection node has the latest timestamp; the coordinator
returns the latest value.

This is the formal proof that QUORUM reads + QUORUM writes = strong consistency for any RF >= 2.

*What separates good from great:* The edge case: simultaneous QUORUM writes. If two
writes happen simultaneously (concurrent writes to the same row), both QUORUM writes
may succeed on different subsets of nodes. Cassandra resolves this using Last-Write-Wins
(LWW) with microsecond timestamps. If two writes happen at the same microsecond, the
tie-breaking is deterministic (column value hash). LWW means: if two clients write
simultaneously, one write is silently lost. For use cases that require compare-and-set
semantics (update only if current value is X), use Cassandra Lightweight Transactions
(Paxos) instead of LWW.

---

**[SENIOR] Q4 (Trade-off): When should you use DynamoDB strongly consistent reads vs eventually consistent reads?**

Eventually consistent reads (default, half the read cost):
- Product catalog pages - prices and descriptions can be seconds old.
- User profile display - profile picture and bio can be slightly stale.
- Aggregate dashboard metrics - staleness of seconds is acceptable.
- Non-critical preferences - UI settings, notification preferences.
- Shopping cart display (but not checkout total) - display can lag slightly.

Strongly consistent reads (2x read cost):
- Account balance after a transfer - must see the updated balance.
- Inventory count at checkout - must not oversell due to stale count.
- Reservation availability check - must not double-book.
- Authentication state (login/logout) - must see the latest revocation.
- Payment idempotency key check - must see if a payment was already processed.

Economic analysis: strongly consistent reads cost 2x in DynamoDB RCUs. For a system
performing 10,000 strongly consistent reads per second at 1 KB each: 10,000 RCUs/second.
At eventually consistent rates: 5,000 RCUs/second. Difference: 5,000 RCUs/second =
$2.59/hour at DynamoDB on-demand pricing. Annually: ~$22,700. For most systems, the
cost is justified for financial and inventory operations.

*What separates good from great:* The DynamoDB Global Table caveat. Strongly consistent
reads are only available in the local region for DynamoDB Global Tables. Cross-region
reads from a replica table are always eventually consistent regardless of `ConsistentRead`
setting. For multi-region applications with strong consistency requirements, writes must
go to the primary region, and strongly consistent reads must come from the same region
as the write. Application design must route reads and writes appropriately.

---

**[SENIOR] Q5 (Scenario): A DynamoDB application shows incorrect inventory counts after a checkout. Some checkouts proceed despite zero inventory. What is the root cause?**

Root cause analysis:

Step 1 - Identify the read type: the inventory check before checkout uses eventually
consistent reads (the default); the check reads from a replica that has not seen a
recent decrement from a concurrent checkout.

Step 2 - Confirm with CloudWatch: check `ConditionalCheckFailedRequests` metric on
the inventory table. Low failures despite concurrent checkouts confirm that the
conditional check is not using the latest data.

Step 3 - The specific failure:

```python
# BAD: eventually consistent read + conditional update (race)
response = table.get_item(
    Key={"product_id": "p1"}
    # ConsistentRead=False (default) -> stale data
)
count = response["Item"]["count"]  # might be stale

if count > 0:
    # Multiple threads can pass this check
    # if they all read the same stale count
    table.update_item(
        Key={"product_id": "p1"},
        UpdateExpression="SET #c = #c - :one",
        ExpressionAttributeNames={"#c": "count"},
        ExpressionAttributeValues={":one": 1}
    )
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the BAD pattern - reading inventory with an eventually consistent read then decrementing without a condition; multiple concurrent threads can all pass the `count > 0` check before any decrement is committed. (2) KEY MECHANISM: the `get_item` returns stale data (eventually consistent); 10 concurrent checkouts read `count=5`; all pass the check; all decrement; final count = -5 (sold more than available). (3) WHY IT MATTERS: this is the classic check-then-act race condition in distributed systems; the check and the act are not atomic. (4) WHAT BREAKS: inventory goes negative; customers receive confirmation emails for orders that cannot be fulfilled. (5) TAKEAWAY: never read then conditionally write in DynamoDB without using a `ConditionExpression`; the read and the conditional check must happen server-side atomically.

Fix: use a conditional update that checks and decrements atomically, with a strongly
consistent prior read or a conditional expression:

```python
# GOOD: atomic conditional decrement
try:
    table.update_item(
        Key={"product_id": "p1"},
        UpdateExpression="SET #c = #c - :one",
        ConditionExpression="#c > :zero",
        ExpressionAttributeNames={"#c": "count"},
        ExpressionAttributeValues={
            ":one": 1, ":zero": 0
        }
    )
except ConditionalCheckFailedException:
    raise OutOfStockError("Product is out of stock")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the correct DynamoDB pattern using `ConditionExpression` to atomically check inventory and decrement in a single operation. (2) KEY MECHANISM: `ConditionExpression="#c > :zero"` is evaluated server-side; if count is 0, the entire update is rejected; if count is positive, the decrement is applied atomically; no separate read is needed. (3) WHY IT MATTERS: atomic check-and-modify eliminates the race condition; 1000 concurrent checkouts can safely execute this; only as many succeed as the current inventory count. (4) WHAT BREAKS: not catching `ConditionalCheckFailedException` causes the exception to propagate as a generic error; always catch it specifically and return an appropriate business error. (5) TAKEAWAY: for any inventory or quota check-and-decrement in DynamoDB, use `ConditionExpression`; it is the standard pattern for optimistic concurrency control.

*What separates good from great:* The DynamoDB atomic counter difference. `update_item`
with a `ConditionExpression` is not the same as an atomic counter. The conditional
expression reads the current value at the DynamoDB storage layer (strongly consistent at
the cell level) and applies the update atomically if the condition is met. This prevents
race conditions even with concurrent updates. The key insight: DynamoDB conditional
expressions are evaluated server-side atomically; there is no read-modify-write race
condition in `update_item` with a conditional expression, even though the application
code looks like it has a TOCTOU (Time-Of-Check Time-Of-Use) pattern.

---

**[SENIOR] Q6 (Application): How does session-based causal consistency work in MongoDB and when do you need it?**

Causal consistency: within a session, reads always see all writes from that session
(and causally dependent writes from other sessions). The session tracks a cluster time
and operation time; the driver sends this to the server with each request; the server
waits until its replication state advances past the session's last write time before
serving the read.

When you need session causal consistency:

1. **Read-your-own-writes**: user updates profile; next read should show the update.
   Without a session, the read might go to a secondary that hasn't replicated yet.

2. **Monotonic reads**: user sees post with 10 comments; next read should show at least
   10 comments. Without a session, a read to a less-caught-up secondary might show
   9 comments.

3. **Multi-step business operations**: user adds item to cart, then fetches cart; the
   fetched cart must show the added item.

Implementation: reuse the same session within a request. Create a session at the start
of an HTTP request; use it for all database operations in that request; close it at
the end. This ensures within-request causal consistency.

*What separates good from great:* The session performance implication. Session-bound
reads include a `clusterTime` and `operationTime` that the server uses to wait for
replication to advance. A secondary that is 50ms behind the primary will wait up to
50ms before serving the session read. In a high-read system where reads are evenly
distributed across secondaries, sessions that require reading recently-written data
will have higher latency than non-session reads. For reads that do NOT require seeing
recent writes (user's post history from last week), skipping the session and using a
lower readPreference is valid and faster.

---

**[SENIOR] Q7 (Trade-off): Compare consistency guarantees in MongoDB, Cassandra, and DynamoDB. Which would you choose for a bank account balance system?**

Bank account requirements: never return stale balance; no double-spends; no lost writes;
ACID multi-account transfers.

MongoDB:
- `w:majority, j:true` + `readConcern:majority`: strong consistency for single-document
  reads and writes; writes are durable.
- Multi-document transactions with `readConcern:snapshot` + `w:majority`: ACID
  semantics across multiple account documents; snapshot isolation.
- Best fit for bank accounts: full ACID transactions across multiple accounts
  in one replica set; built-in transaction support.

Cassandra:
- `QUORUM` reads + `QUORUM` writes: strong consistency per partition.
- Lightweight Transactions (LWT): linearizable read-modify-write on one partition.
- Limitation: no multi-partition transactions; a transfer across two accounts requires
  application-level saga or two-phase commit.
- Complexity: significantly more complex to implement than MongoDB transactions.

DynamoDB:
- `ConsistentRead=True` + `TransactWriteItems`: ACID multi-item transactions.
- DynamoDB Transactions: up to 100 items, atomic all-or-nothing.
- Good fit: if the accounts are in one region and multi-item transactions cover
  the required scope.
- Limitation: cross-region Global Tables are eventually consistent; multi-region
  transactions require custom logic.

Recommendation for bank accounts: MongoDB for teams already using MongoDB (built-in
ACID transactions); DynamoDB for AWS-native teams (TransactWriteItems supports ACID);
avoid Cassandra unless team has deep Cassandra expertise and can implement saga pattern
correctly.

*What separates good from great:* The saga pattern for Cassandra multi-partition
transactions. Since Cassandra has no multi-partition transactions, a bank transfer
(debit A, credit B) must use the Saga pattern: (1) Write a "transfer pending" record
with a transaction ID; (2) Debit account A (LWT: balance >= amount, IF exists); (3)
Credit account B; (4) Mark the transfer record as complete. Each step uses a separate
LWT operation; compensating transactions handle failures. This is correct but significantly
more complex than MongoDB's single transaction block. The operational complexity of
distributed sagas is the primary reason to prefer MongoDB or DynamoDB for financial
systems unless the write throughput requirements demand Cassandra's scale.
