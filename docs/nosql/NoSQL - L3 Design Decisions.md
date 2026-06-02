---
layout: default
title: "NoSQL - L3 Design Decisions"
parent: "NoSQL"
nav_order: 8
permalink: /nosql/l3-design-decisions/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [NoSQL Anti-patterns and Misuse](#nosql-anti-patterns-and-misuse) | ★★☆ |
| 2 | [Polyglot Persistence Decision Framework](#polyglot-persistence-decision-framework) | ★★☆ |

---

# NoSQL Anti-patterns and Misuse

---

### 🎯 Model Answer

**30 seconds:**
> The most common NoSQL anti-patterns: using MongoDB as a relational database (creating
> references everywhere and joining in application code), using Redis as a primary database
> without persistence, using Cassandra with poorly chosen partition keys causing hot nodes,
> treating NoSQL as "schema-less" and ignoring data modeling, and using NoSQL for
> workloads that actually need ACID transactions. Each anti-pattern causes either
> correctness problems, performance degradation, or operational failures.

**3 minutes (Senior):**
> The five most dangerous NoSQL anti-patterns: (1) Relational thinking in MongoDB -
> normalizing data and doing application-level joins; defeats the performance purpose of
> embedding; creates N+1 query problems. (2) Using `ALLOW FILTERING` in Cassandra - full
> cluster scan; acceptable for maintenance queries, fatal for application queries. (3)
> Unbounded arrays in MongoDB - embedding arrays that grow forever; documents hit the
> 16 MB limit; updates require rewriting the entire document. (4) Missing partition key
> distribution in Cassandra/DynamoDB - using a low-cardinality key (date, status, country)
> concentrates writes to a few hot partitions. (5) Using NoSQL for complex transactions -
> implementing saga patterns manually for operations that could be a single SQL transaction;
> adds complexity and creates consistency windows.

**Framework:** Anti-pattern -> Root cause -> Symptom -> Fix

**Blank Mind Recovery:**

**(1) Restate:** "Top 5 anti-patterns: 1) MongoDB with joins (N+1 queries), 2) Cassandra
ALLOW FILTERING (full scan), 3) Unbounded arrays (document too large), 4) Bad partition
key (hot nodes), 5) NoSQL for transactions (inconsistency)."

**(2) First principles:** "NoSQL databases trade query flexibility for performance and
scale. Each NoSQL system has one key constraint: MongoDB requires a good index;
Cassandra requires the partition key; DynamoDB requires the sort key. Violating these
constraints converts the system from optimized to scanning."

**(3) Bridge:** "A NoSQL anti-pattern is like using a hammer to drive a screw. The
hammer (NoSQL database) can technically do it (drive the screw in with brute force /
ALLOW FILTERING), but it is slow, damages the screw (data model), and creates problems
later. Use the right tool (screwdriver / partition key design)."

---

### 📘 Concept Explanation

**The Top 5 Anti-patterns:**

```text
ANTI-PATTERNS TAXONOMY:

  CATEGORY 1: RELATIONAL THINKING IN NoSQL
  ----------------------------------------
  BAD: MongoDB with normalized data + joins
    posts: { _id, author_id, content }
    users: { _id, name, email }
    -> need 2 queries for every post display
    -> O(N) queries for N posts (N+1 problem)

  GOOD: Embed what is always read together
    posts: { _id, author: {name, avatar},
             content, comment_count }

  CATEGORY 2: UNBOUNDED ARRAYS
  ----------------------------
  BAD: { user_id, activity_log: [...] }
    -> log grows forever
    -> 16 MB document limit
    -> full document written on every update

  GOOD: Separate collection with TTL
    activity_events: { user_id, event, time }
    -> index on (user_id, time)
    -> TTL on event time

  CATEGORY 3: CASSANDRA QUERY VIOLATIONS
  --------------------------------------
  BAD: ALLOW FILTERING on large tables
    -> full cluster scan
    -> O(N partitions) latency

  BAD: Low-cardinality partition key
    date as partition key
    -> one hot node per day

  GOOD: Table per query pattern
    + high-cardinality partition key
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the taxonomy of NoSQL anti-patterns
> organized by category with BAD/GOOD comparisons for each. (2) HOW TO READ IT: each
> category shows the anti-pattern (BAD) and its consequence, followed by the correct
> approach (GOOD). (3) KEY RELATIONSHIP: each anti-pattern violates a fundamental NoSQL
> constraint (MongoDB: document size limit; Cassandra: partition key requirement; both:
> relational thinking). (4) EDGE CASE: the N+1 query problem in MongoDB is sometimes
> acceptable; if the embedded data changes frequently and the embedded snapshot would
> become stale, referencing is correct despite the extra query. (5) INSIGHT: a senior
> engineer recognizes that most NoSQL anti-patterns come from applying relational database
> instincts to NoSQL systems; the solution is always to learn the specific constraints
> of the chosen NoSQL system and design accordingly.

---

### 💻 Code Example

```javascript
// BAD: N+1 queries in MongoDB
// (relational thinking - normalizing post author)
const posts = await db.posts.find({}).toArray();

// N+1 problem: one query per post to get the author
const postsWithAuthors = await Promise.all(
  posts.map(async post => {
    const author = await db.users.findOne(
      { _id: post.author_id }
    );
    return { ...post, author };
  })
);
// 1 + N queries where N = number of posts
// For 100 posts: 101 database round-trips
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the N+1 query anti-pattern where each post
> requires a separate database query to fetch the author. (2) KEY MECHANISM: 100 posts
> require 101 database round-trips (1 for posts + 100 for authors); each round-trip adds
> network latency; at 1ms per round-trip, 100 posts take 100ms just for author lookups.
> (3) WHY IT MATTERS: this pattern is extremely common when developers with SQL background
> use MongoDB; they normalize data instinctively and then join in application code. (4)
> WHAT BREAKS: at scale (1000 posts, 1000 concurrent users), this creates 1 million
> database queries per second for author lookups alone. (5) TAKEAWAY: if you find yourself
> iterating over a MongoDB result set and making individual queries for each item, you have
> the N+1 problem; the fix is embedding or using `$lookup` in an aggregation pipeline.

```javascript
// GOOD: Embed author snapshot (no extra query needed)
// Author data embedded at post creation time
const createPost = async (authorId, content) => {
  const author = await db.users.findOne(
    { _id: authorId },
    { projection: { name: 1, avatar: 1 } }
  );
  await db.posts.insertOne({
    author: {           // embedded snapshot
      _id: authorId,
      name: author.name,      // denormalized
      avatar: author.avatar   // denormalized
    },
    content,
    created_at: new Date(),
    comment_count: 0
  });
};

// Query: no join needed
const posts = await db.posts.find({})
  .sort({ created_at: -1 })
  .limit(20)
  .toArray();
// All author data included in each post document
// 1 query, 0 additional lookups
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the correct solution - embedding the author's
> name and avatar as a snapshot in the post document at creation time. (2) KEY MECHANISM:
> `name` and `avatar` are copied into the post at insert time; this is a denormalized
> snapshot; if the author changes their name later, historical posts still show the
> original name (correct for historical records). (3) WHY IT MATTERS: a single query
> returns all 20 posts with complete author information; no additional queries; 1 round-
> trip instead of 21. (4) WHAT BREAKS: if the author profile picture changes and the
> application must show the current avatar (not historical), this pattern is wrong; use
> a `$lookup` aggregation or accept the stale avatar. (5) TAKEAWAY: embed author data
> when it represents the historical state at post time; reference author when the post
> must show current author information.

```python
# ANTI-PATTERN 2: DynamoDB without partition key planning
# (using a date as partition key)

import boto3
from datetime import date

dynamo = boto3.resource("dynamodb")
table = dynamo.Table("sensor_readings")

# BAD: date as partition key -> hot partition
table.put_item(Item={
    "date": str(date.today()),    # partition key
    "sensor_id": "sensor-001",   # sort key
    "temperature": 23.5
})
# ALL reads/writes for today go to one partition!
# That one partition lives on one DynamoDB node.
# All other nodes are idle -> hot partition.

# GOOD: sensor_id as partition key
table.put_item(Item={
    "sensor_id": "sensor-001",  # partition key
    "reading_time": "2024-01-15T10:00:00Z",  # sort key
    "temperature": 23.5
})
# Each sensor_id hashes to a different partition
# Distribution is uniform across thousands of sensors
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the DynamoDB hot partition anti-pattern using
> `date` as the partition key vs the correct pattern using `sensor_id`. (2) KEY MECHANISM:
> DynamoDB partitions data by the hash of the partition key; all items with the same
> partition key are stored on the same partition server; using `date` means all readings
> for today go to one server; using `sensor_id` distributes readings across many servers.
> (3) WHY IT MATTERS: a DynamoDB partition has a maximum of 3,000 RCUs and 1,000 WCUs;
> if all writes for today exceed 1,000 WCUs, DynamoDB throttles the writes with
> `ProvisionedThroughputExceededException`; the hot partition is the bottleneck even if
> total table capacity is sufficient. (4) WHAT BREAKS: increasing table-level throughput
> does not fix a hot partition; DynamoDB distributes capacity by partition; if all
> writes go to one partition, that partition is throttled regardless of total table
> capacity. (5) TAKEAWAY: the partition key in DynamoDB/Cassandra must have high
> cardinality AND uniform write distribution; never use a time-based value as the sole
> partition key for a write-heavy table.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> The most common NoSQL anti-patterns: in MongoDB, avoid N+1 queries by embedding
> data that is always read together. Avoid unbounded arrays - if an array can grow
> forever, use a separate collection. In Cassandra/DynamoDB, never use `ALLOW FILTERING`
> in application code - it scans all data. Choose partition keys with high cardinality
> (many distinct values). Do not use NoSQL for data that requires ACID transactions
> across multiple entities - use a relational database instead.

---

**Senior / Staff (5+ years):**
> Anti-patterns with production consequences: (1) MongoDB unbounded arrays - the document
> hits the 16 MB limit; but the more common problem is update performance; updating a
> single field in a document requires writing the entire document; a large document (many
> embedded items) means high write amplification; solution: embed only the most recent
> N items with a computed count, store older items in a separate collection. (2) DynamoDB
> scan instead of query - a `scan` operation reads all items in a table; at table
> capacity, this exhausts read capacity; a filter expression applied after scan still
> reads all items before filtering; never use `scan` in application code; always use
> `query` with a partition key. (3) Redis without maxmemory policy - if Redis fills up
> without a maxmemory policy (`noeviction` default), Redis returns `OOM command not
> allowed` for all write operations; the application crashes; always configure
> `maxmemory` and a policy appropriate for the use case.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Schema-less means I don't need to think about the data model."**

"Schema-less" means the database does not enforce a schema. The schema still exists - it
is in the application code. The difference from SQL: in SQL, the database rejects invalid
data at insert time. In MongoDB, the database accepts any document structure; invalid
or inconsistent data is accepted silently. Schema validation can be added to MongoDB
with JSON Schema validators, but it is opt-in. In practice, "schema-less" databases
require MORE careful data modeling, not less, because inconsistency is not caught at the
database layer.

**Misconception 2: "NoSQL scales better than SQL for every workload."**

This is a popular marketing claim that is false. NoSQL systems scale better for specific
workloads: high-write time-series (Cassandra), key-value caching (Redis), document
storage with flexible queries (MongoDB). For analytics (complex JOINs, aggregations),
PostgreSQL or purpose-built OLAP databases outperform most NoSQL systems. For moderate
write loads (< 100,000/second) with complex queries, PostgreSQL with proper indexing
often outperforms the same workload on MongoDB. The statement should be: "NoSQL scales
write throughput more easily at extreme scale for specific access patterns."

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: MongoDB document exceeds 16 MB limit.**

Symptom: `BSONObj too large` on insert or update; application receives error when
writing a specific document.
Root cause: an embedded array has grown unboundedly over time (activity logs,
chat messages, click events).
Diagnosis: `db.collection.find().sort({ _id: -1 }).limit(10)` to find recent large
documents; check `Object.bsonsize(doc)` against 16 MB limit.
Fix: migrate to a separate collection with the embedded array items as individual
documents; use TTL index to auto-expire old items; embed only the most recent N items
(with a computed count) and reference the rest.

**Failure Mode 2: DynamoDB `ProvisionedThroughputExceededException` on one table.**

Symptom: `ProvisionedThroughputExceededException` errors for one partition key value;
other partition key values are unaffected; CloudWatch shows `ThrottledRequests` metric.
Root cause: hot partition - one partition key value receives more requests per second
than the per-partition limit (3,000 RCU / 1,000 WCU).
Diagnosis: enable DynamoDB Contributor Insights to see which partition key values are
most read/written; confirm hotspot.
Fix: redesign the partition key to add a suffix (bucket number 0-9); distribute writes
across 10 partitions; aggregate reads across the 10 partitions.

---

### ⚖️ Comparison Table

| Anti-pattern | Database | Symptom | Root Cause | Fix |
|---|---|---|---|---|
| N+1 queries | MongoDB | Slow listing pages | Normalized data + no embed | Embed or `$lookup` |
| ALLOW FILTERING | Cassandra | Slow/timeout queries | Non-PK WHERE clause | Table per query |
| Unbounded array | MongoDB | 16 MB error | Infinite embedded growth | Separate collection |
| Hot partition | DynamoDB/Cassandra | Throttling on one PK | Low-cardinality key | Add bucket suffix |
| Scan over query | DynamoDB | Table-wide RCU usage | No query design | Add sort key |

---

### 🏛️ System Design

*(Omit: L3 keyword; anti-patterns in production context covered in L4 and L5 entries.)*

---

### 📊 Diagram

```text
ANTI-PATTERN DECISION TREE:

  Query is slow?
    |
    Is it a full table scan? (COLLSCAN/ALLOW FILTERING)
    YES -> Add index / redesign table
    NO  |
        |
    Returning too many results per query?
    YES -> Check pagination (cursor-based)
    NO  |
        |
    Latency per query is high?
    YES |
        |
        Multiple queries for one logical request?
        YES -> N+1 problem -> embed or use $lookup
        NO  |
            |
            Large document being transferred?
            YES -> Projection to return only needed fields
            NO  |
                |
                Check network / index saturation
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a decision tree for diagnosing slow
> MongoDB/NoSQL queries, leading to specific anti-patterns and their fixes. (2) HOW
> TO READ IT: start at the top with "Query is slow?" and follow the YES/NO branches;
> each branch narrows down to a specific root cause and fix. (3) KEY RELATIONSHIP: most
> slow NoSQL queries fall into one of five categories: missing index, pagination issues,
> N+1 queries, over-fetching (large projections), or infrastructure (network, I/O). (4)
> EDGE CASE: a query can be slow for multiple reasons simultaneously; fix the most
> impactful one first (usually missing index or N+1), then re-measure before fixing
> the next. (5) INSIGHT: a senior engineer uses `explain("executionStats")` (MongoDB)
> or `nodetool cfhistograms` (Cassandra) before following any decision tree; measurement
> before optimization prevents spending effort on the wrong root cause.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | N+1 problem, hot partition |
| Application | 2 | MongoDB embedding fix, DynamoDB key design |
| Trade-off | 2 | Denormalization vs normalization, NoSQL vs SQL for transactions |
| Scenario | 2 | Unbounded array, throttling |
| Mechanism | 1 | DynamoDB partition limits |

---

**[MID] Q1 (Definition): What is the N+1 query problem in MongoDB? How do you fix it?**

The N+1 query problem: fetching a list of N items requires 1 query for the list + N
additional queries for related data on each item.

Example: display 20 blog posts with author names.
- 1 query: `db.posts.find().limit(20)` -> returns 20 posts with `author_id`.
- 20 queries: `db.users.findOne({ _id: author_id })` for each post -> 20 author lookups.
- Total: 21 queries per page load.

This is not a MongoDB-specific problem; it is common in any database where related data
is normalized and fetched lazily. In MongoDB, the standard fixes are:

Fix 1 - Embedding (denormalize author into post):
Write the author's name and avatar into the post document at creation time. A single
`find()` returns posts with author data. Zero extra queries.

Fix 2 - `$lookup` (aggregation pipeline join):
Use `$lookup` in an aggregation pipeline to join posts with users in the database.
Two database accesses (posts + users) instead of 1 + N. Better than embedding when
the author data changes and the post must show current information.

Fix 3 - Application-level batch:
Collect all unique `author_id` values from the 20 posts; run one query
`db.users.find({ _id: { $in: authorIds } })`; map results by ID.
Two queries total (posts + batch authors lookup). Useful when embedding is not
appropriate but N+1 is unacceptable.

*What separates good from great:* The DataLoader pattern. The batch lookup (Fix 3)
is the foundation of the DataLoader pattern used in GraphQL and other API layers.
DataLoader collects all individual lookups within one tick of the event loop and
sends one batched query. This transparently converts N+1 into 1+1 without changing
the calling code. For production APIs, DataLoader (or equivalent) should be a standard
part of the data access layer.

---

**[MID] Q2 (Application): A MongoDB collection stores user comments as an embedded array. After 2 years, some documents are failing to insert. What happened and how do you fix it?**

Root cause: the embedded `comments` array is unbounded; after 2 years of comments,
some documents have grown beyond MongoDB's 16 MB document size limit; writes fail with
`BSONObj too large`.

Diagnosis:

```javascript
// Find the largest documents
db.posts.find().sort({ "comments": -1 }).limit(5).forEach(doc => {
  const size = Object.bsonsize(doc);
  console.log(doc._id, size, doc.comments.length);
});
// Identify documents near or over 16MB limit
```

> **Code walkthrough:** (1) WHAT IT SHOWS: finding the largest post documents by sorting on the `comments` array length and checking the BSON size. (2) KEY MECHANISM: `Object.bsonsize()` returns the BSON size of a document in bytes; the 16 MB limit = 16,777,216 bytes; any document approaching this limit is at risk. (3) WHY IT MATTERS: identifying the largest documents quantifies the scope of the problem and confirms the root cause. (4) WHAT BREAKS: `sort({ "comments": -1 })` sorts by array length only if `comments` is indexed; without an index, this is a full collection scan. (5) TAKEAWAY: run this diagnostic query periodically for any collection with embedded arrays; alert when maximum document size exceeds 10 MB.\n\nMigration plan: (1) Create new `comments` collection. (2) Migrate all embedded comments to the new collection with the `post_id` reference. (3) Add a TTL index on `created_at`. (4) Update the application to write to `comments` collection on new comments. (5) Remove the `comments` array from the `posts` documents.

*What separates good from great:* The migration atomicity concern. During the migration
(step 2-5), the application may write new comments. If new comments go to the old
embedded array (before the code change), they are not in the new collection. If new
comments go to the new collection (after the code change), they are not in the old
array. The migration must be coordinated with the code change. Strategy: write to both
(old array + new collection) during the transition; remove old array writes once
migration is confirmed complete; use a feature flag to control the transition.

---

**[SENIOR] Q3 (Mechanism): Explain DynamoDB partition-level throughput limits. Why does hot partition cause throttling even when table-level capacity is sufficient?**

DynamoDB internally partitions data using consistent hashing. Each partition is an
independent storage node. DynamoDB automatically distributes capacity across partitions.

Partition throughput limits (per partition, not per table):
- 3,000 Read Capacity Units (RCUs) per second per partition.
- 1,000 Write Capacity Units (WCUs) per second per partition.

Table-level vs partition-level capacity:
- Table-level capacity is the sum of all partitions.
- DynamoDB distributes table capacity evenly across partitions.
- If a table has 100 partitions and 10,000 WCUs, each partition gets 100 WCUs.
- The 100-WCU partition limit is independent of the table total.

Hot partition scenario:
- 90% of writes go to partition key `"status:active"` (low-cardinality key).
- That partition receives 900 WCUs/second.
- The partition limit is 1,000 WCUs; the table limit is 10,000 WCUs.
- The partition becomes throttled; `ProvisionedThroughputExceededException`.
- The other 99 partitions are nearly idle (receiving 1% of writes each).
- Increasing table WCUs to 20,000 does NOT help; the hot partition now has
  200 WCUs but still receives 90% of writes = 900 WCUs -> still throttled.

Fix: distribute the writes across 10 logical partitions:
- Instead of `"status:active"`, use `"status:active:0"` through `"status:active:9"`.
- Assign a random suffix per write (0-9).
- Reads must query all 10 partition key variants and merge results.

*What separates good from great:* DynamoDB Adaptive Capacity. DynamoDB now has
"Adaptive Capacity" that automatically shifts throughput from underutilized partitions
to hot partitions. This reduces but does not eliminate hot partition throttling. Adaptive
Capacity helps with burst traffic but not sustained hot partitions; if a partition
consistently receives more than its capacity limit, even Adaptive Capacity cannot fully
compensate. The correct long-term fix remains partition key design.

---

**[SENIOR] Q4 (Trade-off): When should you NOT use NoSQL and stick with a relational database?**

Use a relational database when:

1. **Complex, ad-hoc queries**: analytics, reporting, data exploration. SQL's JOIN,
   GROUP BY, window functions, and arbitrary WHERE clauses handle these naturally.
   NoSQL requires data to be pre-modeled for specific queries; unforeseen queries
   require schema changes.

2. **ACID multi-entity transactions**: transferring money between accounts, booking
   a seat while decrementing inventory - operations that must be atomic across multiple
   entities. SQL handles this with a single transaction. NoSQL requires application-level
   sagas which are complex to implement correctly.

3. **Strong referential integrity**: if deleting a product should be prevented if orders
   reference it, SQL foreign keys enforce this. NoSQL does not have foreign key constraints;
   orphaned references are not detected automatically.

4. **Moderate write scale**: for applications with < 100,000 writes/second, PostgreSQL
   with proper indexing handles the load. The operational complexity of NoSQL (partition
   key design, consistency levels, compaction) is not justified below this scale.

5. **Changing query requirements**: in early-stage products, query patterns evolve
   rapidly. SQL allows new queries without schema changes. NoSQL may require new tables/
   collections for each new query pattern.

*What separates good from great:* The "use NoSQL for NoSQL's strengths" principle. NoSQL
is not a replacement for SQL; it is a supplement for specific use cases. Most production
systems benefit from polyglot persistence: PostgreSQL for transactional data, Redis for
caching and session state, Cassandra or DynamoDB for high-write event data. The common
mistake is choosing one database for everything (all-SQL is too rigid for cache; all-
NoSQL loses ACID for transactions). The correct approach is to identify each data access
pattern and choose the best database for that pattern.

---

**[SENIOR] Q5 (Application): A Cassandra cluster is responding slowly to reads. The cause is identified as tombstone accumulation. What led to this and how do you fix it?**

Root cause: the application is using explicit DELETE operations on time-series data
instead of TTL.

Tombstone lifecycle:
1. `DELETE FROM events WHERE user_id = 'u1' AND event_time < now() - 30d`
   -> Creates tombstones for all deleted rows.
2. Tombstones persist until `gc_grace_seconds` (default: 10 days) after the deletion.
3. During reads, Cassandra must scan through tombstones to find live rows.
4. With millions of tombstones per partition, reads time out.

Diagnosis:

```bash
# Check tombstone count in table stats
nodetool tablestats keyspace.events | \
  grep -i tombstone
# "SSTable Tombstone Droppable Ratio: 0.95"
# 95% tombstones -> serious accumulation
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Cassandra `nodetool tablestats` command showing tombstone accumulation via the `SSTable Tombstone Droppable Ratio` metric. (2) KEY MECHANISM: "droppable" tombstones have exceeded `gc_grace_seconds` and can be removed by compaction; a ratio near 1.0 means almost all tombstones are ready to be dropped but compaction has not yet run. (3) WHY IT MATTERS: until compaction removes the tombstones, reads must scan through them; a 0.95 ratio means 95% of the SSTable entries are tombstones; reads effectively scan 20x more data than necessary. (4) WHAT BREAKS: `nodetool compact` forces compaction but requires I/O resources; running it during peak hours can impact read/write performance. (5) TAKEAWAY: schedule `nodetool compact` during off-peak hours after confirming high tombstone ratios; do not wait for scheduled compaction in production emergencies.

Fix:
1. Run `nodetool compact keyspace events` to force tombstone cleanup.
2. Change the data model: use `USING TTL` on inserts instead of explicit DELETEs.
3. Switch compaction strategy to TWCS (TimeWindowCompactionStrategy):
   `ALTER TABLE keyspace.events WITH compaction = {'class': 'TWCS', ...}`
4. TWCS ensures time-expired data is cleaned up efficiently without tombstone accumulation.

*What separates good from great:* The repair interaction with tombstones. Before reducing
`gc_grace_seconds` to speed up tombstone cleanup, ensure all nodes have received the
tombstones through repair (`nodetool repair`). If a node was down when the DELETE was
processed, it missed the tombstone; if `gc_grace_seconds` is too short, the tombstone
is removed before the lagging node gets it; when the lagging node rejoins, it
"resurrects" the deleted data (the tombstone is gone but the original data is still
there). Always run `nodetool repair` before reducing `gc_grace_seconds`.

---

**[SENIOR] Q6 (Scenario): A development team is building a new e-commerce system and proposes using MongoDB for everything - products, orders, payments, and inventory. What concerns do you raise?**

Key concerns:

1. **Payment and financial data**: payments require ACID guarantees across multiple
   documents (debit account, credit merchant, create payment record). MongoDB transactions
   work within a single replica set but the complexity of handling failures and retries
   correctly is high. Consider whether the payment logic truly needs cross-document
   transactions; if so, evaluate whether a relational database for the payment service
   is more appropriate.

2. **Inventory management**: preventing overselling requires reading inventory count
   and decrementing atomically. MongoDB's `findOneAndUpdate` with `ConditionExpression`
   equivalent (`filter: { count: { $gt: 0 } }`) handles this; multi-item inventory
   updates (one order, multiple products) require MongoDB transactions.

3. **Product catalog**: good fit for MongoDB - flexible schema handles varying product
   attributes (electronics have voltage, clothing has size/color). Embedding variant
   arrays is appropriate for bounded variants.

4. **Order management**: mixed. Orders with embedded line items are a natural MongoDB
   fit. Order status updates requiring consistency with payment state need careful
   transaction design.

5. **Analytics and reporting**: MongoDB aggregation pipeline can handle many analytics
   queries, but complex cross-collection JOINs and window functions are more natural in
   SQL. Consider a separate OLAP database or export to a SQL analytics database.

*What separates good from great:* The "MongoDB for everything" trap. Teams choose MongoDB
for all data because it is the simplest operational choice (one database to manage).
This is a valid concern (operational simplicity matters). The mitigation: use MongoDB for
most data but design the schema carefully for transactional operations; use multi-document
transactions for financial operations (accepting the latency cost); and accept the
limitation that complex analytics requires aggregation pipelines (or export to SQL). The
wrong mitigation: adding SQL for payments, NoSQL for products, Redis for sessions from
day one; premature polyglot persistence creates operational complexity before the team
has validated the product.

---

**[SENIOR] Q7 (Trade-off): Explain the difference between Cassandra `BATCH` for atomicity and MongoDB multi-document transactions. When does each fall short?**

Cassandra `LOGGED BATCH`:
- Provides atomicity for write operations within the batch.
- The batch log is written to two nodes before execution.
- If any node fails during execution, the batch log ensures the remaining writes complete.
- Limitation: all writes in the batch must be to the same logical operation.
- Does NOT provide isolation: other operations can read partially-applied batches.
- Does NOT prevent concurrent conflicting writes; two batches updating the same rows
  can interleave.
- Cross-partition batches add significant overhead (coordinator must contact all
  partition nodes).
- Falls short for: read-modify-write (the read is not in the batch; concurrent
  modifications are not prevented).

MongoDB multi-document transactions:
- Provide full ACID guarantees within a replica set (or sharded cluster).
- Snapshot isolation: the transaction sees a consistent snapshot of all involved
  documents.
- Serializable isolation (with `readConcern: snapshot` + `writeConcern: majority`).
- Limitation: transactions are expensive (6-10x slower than non-transactional writes);
  keep transactions short (< 1000 operations); long-running transactions cause lock
  contention.
- Falls short for: very high-throughput updates (e.g., updating 1 million orders per
  second); multi-shard transactions in MongoDB require 2-phase commit, adding latency.

*What separates good from great:* The Cassandra LWT (Lightweight Transaction) option.
For Cassandra operations that need read-modify-write atomicity (e.g., register a username
only if it does not exist), use LWT with `IF NOT EXISTS` or `IF condition`. LWT uses
Paxos consensus for linearizable reads and writes; it prevents concurrent conflicting
writes. The cost is significant (4-8x higher latency); use LWT only for operations that
truly need compare-and-set semantics, not for all writes. For most operations, Cassandra's
LWW (Last-Write-Wins) with QUORUM is the correct consistency choice.

---

---

# Polyglot Persistence Decision Framework

---

### 🎯 Model Answer

**30 seconds:**
> Polyglot persistence means using different databases for different data within one
> system, choosing the best tool for each use case. Typical combination: PostgreSQL for
> transactional data (orders, payments), Redis for caching and sessions, Cassandra or
> DynamoDB for event/time-series data, Elasticsearch for full-text search. The decision
> framework: identify access patterns, consistency requirements, and scale requirements
> for each data type; then match to the database whose strengths align.

**3 minutes (Senior):**
> Polyglot persistence decision framework: (1) What are the read/write access patterns?
> (key-value = Redis; document = MongoDB; time-series = Cassandra; relational = SQL).
> (2) What consistency is required? (strong = SQL/MongoDB with majority; eventual ok =
> DynamoDB/Cassandra eventual). (3) What scale? (< 10K writes/second = SQL fine; > 100K
> writes/second = Cassandra/DynamoDB). (4) What query flexibility is needed? (ad-hoc =
> SQL; predefined patterns = Cassandra/DynamoDB). (5) What is the team's expertise and
> operational capacity? (fewer database types = simpler operations). The cost of polyglot
> persistence: each additional database adds operational complexity (monitoring, backups,
> expertise, connections). Start with a monolithic relational database; add polyglot
> databases incrementally when specific bottlenecks emerge.

**Framework:** Access Pattern -> Consistency -> Scale -> Flexibility -> Operations -> Database Choice

**Blank Mind Recovery:**

**(1) Restate:** "Polyglot persistence: right database for each data type. PostgreSQL
for ACID transactions. Redis for cache/sessions. Cassandra for time-series. Elasticsearch
for search. Start simple (one DB), add others when needed."

**(2) First principles:** "Different data has different access patterns, consistency
requirements, and scale needs. No single database is optimal for all patterns. The goal
is matching each data access pattern to the database optimized for that pattern."

**(3) Bridge:** "Polyglot persistence is like using specialized tools. A Swiss Army
knife (one SQL database) can do everything but not optimally. Professional kitchens
(polyglot systems) have a bread knife for bread, a chef's knife for vegetables, a
cleaver for bones - each optimal for its task, at the cost of more tools to manage."

---

### 📘 Concept Explanation

**Database Selection Criteria Matrix:**

```text
DATABASE SELECTION MATRIX:

  Data Type           Best DB         Why
  ----------------    -------         ---
  User sessions       Redis           TTL, fast O(1), HA
  Shopping cart       Redis           Fast reads/writes,
                                      TTL
  User profiles       MongoDB/PG      Flexible schema/
                                      ACID
  Orders/Payments     PostgreSQL      ACID transactions
  Product catalog     MongoDB/PG      Flexible schema
  IoT sensor data     Cassandra       High write throughput
  Event logs          Cassandra/ES    Time-series + search
  Leaderboards        Redis           Sorted sets
  Full-text search    Elasticsearch   Inverted index
  Graph relations     Neo4j           Graph traversal
  Analytics/OLAP      Redshift/BQ     Columnar scan

  DECISION RULE HIERARCHY:
  1. ACID needed? -> PostgreSQL
  2. Extreme write scale (>100K/s)? -> Cassandra
  3. Full-text search? -> Elasticsearch
  4. Cache/session (volatile ok)? -> Redis
  5. Document/flexible schema? -> MongoDB
  6. Otherwise -> PostgreSQL
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a database selection matrix mapping
> data types to the optimal database and the reason for the choice. (2) HOW TO READ IT:
> find the data type in the left column; the middle column shows the recommended database;
> the right column shows the primary reason. (3) KEY RELATIONSHIP: each database is
> recommended for a specific type of data access pattern; the Decision Rule Hierarchy
> at the bottom provides a simplified decision algorithm. (4) EDGE CASE: the matrix shows
> one optimal database per type; in practice, borderline cases exist (product catalog
> works in MongoDB or PostgreSQL); the decision rule hierarchy breaks ties. (5) INSIGHT:
> a senior engineer notices that PostgreSQL appears in 4 data types (user profiles,
> orders, product catalog, and the default); PostgreSQL is the most versatile database;
> for most systems under moderate scale, starting with PostgreSQL-only is the right call
> and adding specialist databases only when needed.

---

### 💻 Code Example

```python
# Polyglot Persistence Example: E-commerce system
# PostgreSQL for orders, Redis for sessions/cart,
# Elasticsearch for product search

import psycopg2
import redis
import json
from elasticsearch import Elasticsearch

# Connection setup
pg_conn = psycopg2.connect(
    host="postgres",
    database="ecommerce",
    user="app_user",
    password="..."
)
redis_client = redis.Redis(
    host="redis", port=6379, db=0
)
es_client = Elasticsearch(["http://elasticsearch:9200"])
```

> **Code walkthrough:** (1) WHAT IT SHOWS: three database connections in one application
> - PostgreSQL for transactional data, Redis for fast volatile data, Elasticsearch for
> full-text search. (2) KEY MECHANISM: each connection uses the appropriate client library;
> the application selects which database to query based on the operation type, not a single
> universal database. (3) WHY IT MATTERS: each database is used for what it does best;
> product search uses Elasticsearch's inverted index; sessions use Redis's O(1) key-value;
> orders use PostgreSQL's ACID transactions. (4) WHAT BREAKS: managing three database
> connections increases code complexity; connection pooling must be configured for each;
> monitoring requires three separate systems. (5) TAKEAWAY: polyglot persistence adds
> operational overhead; only introduce each database when the performance or functional
> benefit justifies the cost.

```python
# Session management: Redis (fast, TTL, no ACID needed)
def save_session(session_id: str, user_data: dict):
    """Save user session to Redis with 30-min TTL."""
    redis_client.setex(
        f"session:{session_id}",
        1800,  # TTL: 30 minutes
        json.dumps(user_data)
    )

def get_session(session_id: str) -> dict:
    """Get user session from Redis."""
    data = redis_client.get(f"session:{session_id}")
    if data is None:
        return None
    # Reset TTL on access (sliding expiry)
    redis_client.expire(f"session:{session_id}", 1800)
    return json.loads(data)

# Order processing: PostgreSQL (ACID transaction required)
def place_order(user_id: int, cart: list):
    """Place an order atomically."""
    cur = pg_conn.cursor()
    try:
        # All or nothing: insert order + decrement inventory
        cur.execute(
            "INSERT INTO orders (user_id, status) "
            "VALUES (%s, %s) RETURNING id",
            (user_id, "pending")
        )
        order_id = cur.fetchone()[0]

        for item in cart:
            cur.execute(
                "INSERT INTO order_items "
                "(order_id, product_id, quantity, price) "
                "VALUES (%s, %s, %s, %s)",
                (order_id, item["product_id"],
                 item["quantity"], item["price"])
            )
            # Atomic inventory decrement
            cur.execute(
                "UPDATE products "
                "SET inventory = inventory - %s "
                "WHERE id = %s AND inventory >= %s",
                (item["quantity"], item["product_id"],
                 item["quantity"])
            )
            if cur.rowcount == 0:
                raise Exception(
                    f"Insufficient stock: {item['product_id']}"
                )

        pg_conn.commit()
        return order_id
    except Exception as e:
        pg_conn.rollback()
        raise e
```

> **Code walkthrough:** (1) WHAT IT SHOWS: sessions stored in Redis (fast, TTL) and
> orders stored in PostgreSQL (ACID transaction across multiple tables). (2) KEY
> MECHANISM: `redis_client.setex` stores the session with automatic expiry; the
> sliding expiry pattern (`expire` on read) extends the session on activity; the
> `place_order` function uses a PostgreSQL transaction to atomically insert the order,
> line items, and decrement inventory. (3) WHY IT MATTERS: using Redis for sessions
> avoids database queries for every HTTP request (high frequency, low stakes); using
> PostgreSQL for orders ensures that a partial order (some items inserted but inventory
> not decremented) is rolled back (high stakes). (4) WHAT BREAKS: if Redis is down,
> session lookups fail; the application must handle `ConnectionError` from Redis and
> fall back to the database if Redis is unavailable. (5) TAKEAWAY: design each database
> access with its failure mode in mind; Redis is a fast volatile store, not a reliable
> primary store; always plan for Redis unavailability in session-dependent operations.

```python
# Product search: Elasticsearch (full-text, facets)
def search_products(
    query: str,
    category: str = None,
    min_price: float = None,
    max_price: float = None,
    page: int = 0,
    size: int = 20
):
    """Search products with full-text + filters."""
    must_clauses = [
        {
            "multi_match": {
                "query": query,
                "fields": [
                    "name^3",       # name is 3x more relevant
                    "description",
                    "brand^2"
                ],
                "type": "best_fields"
            }
        }
    ]
    filter_clauses = []

    if category:
        filter_clauses.append(
            {"term": {"category.keyword": category}}
        )
    if min_price or max_price:
        price_range = {}
        if min_price:
            price_range["gte"] = min_price
        if max_price:
            price_range["lte"] = max_price
        filter_clauses.append(
            {"range": {"price": price_range}}
        )

    search_body = {
        "query": {
            "bool": {
                "must": must_clauses,
                "filter": filter_clauses
            }
        },
        "from": page * size,
        "size": size
    }

    return es_client.search(
        index="products",
        body=search_body
    )
```

> **Code walkthrough:** (1) WHAT IT SHOWS: product search using Elasticsearch with
> full-text relevance scoring across name, description, and brand fields, plus structured
> filters for category and price range. (2) KEY MECHANISM: `multi_match` performs
> full-text search across multiple fields with field boosting (`name^3` means the name
> field contributes 3x to relevance); `filter` clauses are applied after relevance
> scoring and do not affect the score; `bool` query combines relevance (`must`) with
> exact filters (`filter`). (3) WHY IT MATTERS: SQL `LIKE '%keyword%'` performs a full
> table scan without relevance; Elasticsearch's inverted index supports full-text search
> with millisecond latency; field boosting allows name matches to rank higher than
> description matches automatically. (4) WHAT BREAKS: Elasticsearch is an eventual-
> consistency search index; newly indexed products may not appear in search results for
> up to 1 second (the default index refresh interval); for real-time inventory status,
> always fetch the current state from PostgreSQL after a search, not from Elasticsearch.
> (5) TAKEAWAY: use Elasticsearch for relevance-ranked text search with filtering; use
> PostgreSQL for the authoritative product data; keep Elasticsearch synchronized with
> PostgreSQL via an event-driven sync (CDC + Kafka or similar).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Polyglot persistence means using the right database for each type of data. Common
> combinations: PostgreSQL for user data and transactions (needs ACID), Redis for
> sessions and caching (needs speed, not durability), Elasticsearch for search (needs
> full-text), Cassandra for logs and events (needs high write throughput). Start with
> one database (usually PostgreSQL) and add specialized databases only when you hit
> a specific bottleneck (search quality, caching latency, write throughput). Each extra
> database adds operational overhead - only add one when the benefit justifies the cost.

---

**Senior / Staff (5+ years):**
> Polyglot persistence with production complexity: (1) Data synchronization - when the
> same entity is in multiple databases (e.g., product in PostgreSQL and Elasticsearch),
> keeping them in sync requires CDC (Change Data Capture) or event-driven replication;
> the synchronization lag means the two systems are eventually consistent with each
> other; handle this in the application (read authoritative data from PostgreSQL after
> Elasticsearch search). (2) Transaction boundaries - in a polyglot system, there is
> no cross-database transaction; if an order is created in PostgreSQL and a search index
> updated in Elasticsearch, these cannot be atomic; use the Outbox Pattern (write to
> a PostgreSQL `outbox` table in the same transaction as the order, then a background
> process reads the outbox and updates Elasticsearch). (3) Operational overhead - each
> database requires monitoring, backup, disaster recovery, and team expertise; three
> databases means three backup strategies, three monitoring dashboards, three failure
> modes; don't introduce a database unless the team can operate it.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Polyglot persistence always improves performance."**

Polyglot persistence improves performance for the specific access patterns each database
is optimized for. However, the cross-database data synchronization (keeping Elasticsearch
in sync with PostgreSQL) adds latency, complexity, and failure modes. A PostgreSQL
database with proper indexes and full-text search (using `pg_trgm` or `tsvector`) can
handle most search workloads under moderate scale. Adding Elasticsearch for search is
only beneficial when PostgreSQL full-text search becomes a bottleneck (typically above
100 million documents or when relevance ranking is a core product requirement). Adding
Elasticsearch prematurely adds operational complexity without a commensurate benefit.

**Misconception 2: "Redis is a reliable persistent storage for important data."**

Redis is primarily an in-memory database. Even with AOF persistence, Redis is designed
for data that can tolerate at most 1 second of data loss on crash. For truly critical
data (financial balances, user accounts, order history), a dedicated durable database
(PostgreSQL) is the correct primary store. Use Redis as a fast-access layer in front of
the primary database, not as the primary database itself. The rule: if losing this data
would cause a business or compliance issue, it must be in a database with synchronous
durability (PostgreSQL with `synchronous_commit = on`), not Redis.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Elasticsearch index out of sync with PostgreSQL.**

Symptom: product search returns items that no longer exist in the catalog; or products
that should be in search results are missing.
Root cause: the sync mechanism between PostgreSQL and Elasticsearch has a gap; deleted
products are not removed from Elasticsearch; new products have not been indexed.
Diagnosis: compare `SELECT COUNT(*) FROM products` (PostgreSQL) with
`GET /products/_count` (Elasticsearch); significant difference indicates sync failure.
Fix: implement CDC using Debezium (reads PostgreSQL WAL, publishes changes to Kafka,
Elasticsearch consumer indexes changes); monitor consumer lag; alert when lag exceeds
30 seconds.

**Failure Mode 2: Redis cache stampede after cache miss.**

Symptom: Redis returns empty on cache miss; all concurrent requests hit PostgreSQL
simultaneously; PostgreSQL CPU spikes to 100%; some requests time out.
Root cause: many concurrent requests check the cache, all get a miss, all simultaneously
query PostgreSQL.
Diagnosis: monitor PostgreSQL query rate at cache expiry time; sudden spike in
`SELECT` queries for the same product/entity after a TTL expiry confirms stampede.
Fix: implement cache lock (probabilistic early expiry): recompute the cache slightly
before TTL expires; or use a mutex-based cache stampede prevention (first miss thread
acquires a lock and rebuilds; other threads wait for the lock and read the rebuilt cache).

---

### ⚖️ Comparison Table

| Database | Strengths | Weaknesses | When to Add |
|---|---|---|---|
| PostgreSQL | ACID, flexible queries, default | Write scale limit | Start here |
| Redis | O(1) reads/writes, TTL, pub/sub | In-memory limit, no complex queries | High-frequency reads, sessions |
| MongoDB | Flexible schema, rich queries | Weaker consistency by default | Variable-schema documents |
| Cassandra | Extreme write throughput | Query constraints, operational complexity | > 100K writes/second, time-series |
| Elasticsearch | Full-text search, relevance | Eventual sync required, RAM heavy | Search quality is a core requirement |

---

### 🏛️ System Design

*(Omit: L3 keyword; full polyglot architecture decisions in L5 Architecture entry.)*

---

### 📊 Diagram

```text
POLYGLOT PERSISTENCE: E-COMMERCE EXAMPLE

  [User Request]
       |
  [Application]
       |
  +----+----+------+----------+
  |    |    |      |          |
  PG  Redis  ES    PG         PG
  |    |    |      |          |
  |  Session | Product     Order/
  |  Cache  | Search     Payment
  |         |   (Sync via CDC)
  |         |
  User    Product
  Profile  Catalog
  (Auth)   (List page)

  DATA FLOWS:
  1. Login: auth in PG, session in Redis
  2. Browse: PG for list, Redis for cache
  3. Search: Elasticsearch
  4. Add to cart: Redis (ephemeral)
  5. Checkout: PG transaction
  6. Product update: PG -> CDC -> Elasticsearch

  CONSISTENCY BOUNDARIES:
  PG <-> Redis: eventual (cache invalidation)
  PG <-> ES:    eventual (CDC lag ~1 second)
  PG internal:  ACID (within transaction)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a polyglot persistence architecture for
> an e-commerce system showing which databases handle which operations and the data
> synchronization flows between them. (2) HOW TO READ IT: the top shows a user request
> arriving at the application; the bottom shows 4 databases and which data each stores;
> the DATA FLOWS section maps each user action to the database it uses. (3) KEY
> RELATIONSHIP: PostgreSQL is the authoritative source of truth for all persistent data;
> Redis is a fast access layer (cache) in front of PostgreSQL; Elasticsearch is a search
> index synchronized from PostgreSQL via CDC. (4) EDGE CASE: if the CDC pipeline fails,
> Elasticsearch falls out of sync with PostgreSQL; products added/updated/deleted in
> PostgreSQL are not reflected in search results; always monitor CDC consumer lag and
> alert on gaps. (5) INSIGHT: a senior engineer notices that the cart is in Redis
> (ephemeral) but the order is in PostgreSQL (durable); the transition from cart to
> order is the critical consistency boundary; the `checkout` operation reads from Redis,
> creates the order in PostgreSQL (ACID), and clears the cart in Redis; if the Redis
> clear fails, the cart still shows items, but the order is already created - a UX
> annoyance, not a data integrity issue.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Polyglot definition, database selection criteria |
| Application | 2 | E-commerce architecture, cache stampede |
| Trade-off | 2 | Operational complexity, synchronization lag |
| Scenario | 2 | Out-of-sync Elasticsearch, session loss |
| Mechanism | 1 | CDC synchronization |

---

**[MID] Q1 (Definition): What is polyglot persistence and when should you introduce it?**

Polyglot persistence: using multiple different database technologies within one system,
each optimized for a specific subset of the data and access patterns.

Examples:
- Sessions in Redis (fast TTL-based key-value) + orders in PostgreSQL (ACID).
- Product catalog in MongoDB (flexible schema) + search index in Elasticsearch.
- User activity events in Cassandra (high write throughput) + profiles in PostgreSQL.

When to introduce polyglot persistence:
1. A specific access pattern is a performance bottleneck in the current database.
   Example: full-text search in PostgreSQL is slow -> add Elasticsearch.
2. A data type has requirements that the current database cannot satisfy.
   Example: session management in PostgreSQL requires database queries per request -> add Redis.
3. Write throughput exceeds the current database's capacity.
   Example: event logging at 500,000 writes/second -> PostgreSQL cannot keep up -> add Cassandra.

When NOT to introduce it prematurely:
- Before demonstrating a bottleneck with measurement (add databases when needed, not when anticipated).
- When the team does not have expertise to operate the new database.
- When the synchronization complexity would create more bugs than the performance gain is worth.

*What separates good from great:* The incremental adoption path. Most systems start with
PostgreSQL and add databases incrementally: phase 1 - PostgreSQL only; phase 2 - add
Redis when session/cache queries become frequent (typically > 100 requests/second);
phase 3 - add Elasticsearch when product search quality becomes a product requirement;
phase 4 - add Cassandra/DynamoDB when write throughput exceeds PostgreSQL's capacity.
Each addition solves a specific measured problem, not a theoretical concern.

---

**[MID] Q2 (Application): Describe the role of Redis in a typical web application and what happens if Redis goes down.**

Redis roles in a web application:
1. Session store: each HTTP request looks up the session token in Redis; if found,
   the user is authenticated without a database query.
2. Cache: frequently-read data (product catalog, user profiles) cached in Redis;
   reduces database load.
3. Rate limiting: per-user or per-IP request counters stored in Redis with TTL.
4. Pub/Sub: publish/subscribe for real-time features (live notifications, presence).
5. Distributed locks: Redis-based locks for coordinating distributed processes.

What happens if Redis goes down:

Sessions: all active users are logged out (their session data is gone); they must
log in again. Mitigation: store sessions in PostgreSQL as a fallback; Redis is the
primary cache, PostgreSQL is the authoritative store.

Cache: all cache reads miss; every request hits the database; database CPU spikes
significantly. Mitigation: handle `ConnectionError` from Redis; fall back to database;
implement circuit breaker to stop trying Redis and use the database directly.

Rate limiting: rate limits are not enforced until Redis recovers; potential abuse window.
Mitigation: use Redis Sentinel/Cluster for HA; treat Redis rate limiting as best-effort.

Distributed locks: locks are released when Redis goes down; any process waiting for
a lock can re-acquire; there may be a brief window where two processes hold the
"same" lock. Mitigation: use Redlock algorithm with 3+ Redis nodes.

*What separates good from great:* The graceful degradation design. A well-architected
system treats Redis as a performance optimization, not a required dependency. Every
operation that uses Redis should have a fallback to the authoritative database. This is
the resilience pattern: Redis speeds things up but its unavailability never causes
functional failure, only performance degradation. Systems where Redis failure causes
complete application outage have incorrectly treated Redis as a required primary store.

---

**[SENIOR] Q3 (Mechanism): How do you keep Elasticsearch in sync with PostgreSQL in a production system?**

The synchronization challenge: PostgreSQL is the authoritative source; Elasticsearch
is a derived search index. When data changes in PostgreSQL, Elasticsearch must be
updated to reflect the change.

Approach 1 - Dual writes (application writes to both):
On insert/update/delete in PostgreSQL, the application also calls the Elasticsearch
API. Simple to implement; brittle - if the Elasticsearch write fails, data diverges;
no retry mechanism; atomicity is not guaranteed.

Approach 2 - Outbox pattern + background worker:
Insert an "update event" into a PostgreSQL `outbox` table in the same transaction as
the data change. A background worker reads the outbox and sends updates to Elasticsearch.
The outbox and data change are atomic (same transaction). The worker processes events
at-least-once (retries on failure). Elasticsearch updates are idempotent (same document
ID always results in the same Elasticsearch state).

Approach 3 - Change Data Capture (CDC) with Debezium:
Debezium reads the PostgreSQL WAL (Write-Ahead Log); every insert/update/delete is
captured as an event and published to Kafka; an Elasticsearch consumer reads from Kafka
and updates the index. Zero application code changes; the WAL is a reliable source of
all changes; Kafka provides durable message delivery and at-least-once processing.

Production recommendation: CDC with Debezium + Kafka for reliability and observability.

*What separates good from great:* The reindex strategy. When the Elasticsearch mapping
changes (add a new field, change a field type), the entire index must be rebuilt. A
full reindex takes hours for large indexes. Use index aliases: always write to an alias
(`products_v1 -> products`); when rebuilding, write to `products_v2` while reads go to
`products` (still `products_v1`); after reindex completes, atomically swap the alias
(`products -> products_v2`); zero-downtime reindex with no read interruption.

---

**[SENIOR] Q4 (Trade-off): What are the consistency challenges in a polyglot persistence system and how do you manage them?**

Cross-database consistency challenge: in a polyglot system, the same logical entity
may be stored in multiple databases. Making both changes atomically is impossible
without distributed transactions, which are expensive and complex.

Key consistency scenarios:

1. PostgreSQL (source) + Elasticsearch (search index):
   - Write to PostgreSQL first (authoritative).
   - Sync to Elasticsearch asynchronously (CDC).
   - Read from Elasticsearch for search; read from PostgreSQL for authoritative data.
   - Consistency window: the Elasticsearch index lags PostgreSQL by CDC latency (typically
     < 1 second in normal operation, potentially longer during high load).
   - Resolution: accept eventual consistency for search; always show authoritative data
     from PostgreSQL for critical fields (price, availability).

2. PostgreSQL (source) + Redis (cache):
   - Write to PostgreSQL first.
   - Invalidate or update Redis cache after the write.
   - Read from Redis (fast); on miss, read from PostgreSQL and populate cache.
   - Consistency window: the time between write to PostgreSQL and Redis cache invalidation.
   - Resolution: use the Cache-Aside pattern with short TTLs (5-60 seconds); the cache
     becomes eventually consistent with the database.

3. Redis (session) + PostgreSQL (user state):
   - Session data in Redis may reference PostgreSQL state that has changed.
   - Example: user account suspended in PostgreSQL but session in Redis still valid.
   - Resolution: on each request, verify account status from PostgreSQL (or a fast cache
     with short TTL); do not rely solely on session data for authorization decisions.

*What separates good from great:* The Saga pattern for cross-database transactions.
When a business operation requires changes in multiple databases (create order in PostgreSQL,
send notification via Redis Pub/Sub, update search index in Elasticsearch), coordinate
these with a Saga: each step is an independent operation; failed steps trigger compensating
operations (rollback the order if notification fails, for example). The Saga pattern
explicitly models the consistency boundary and failure handling, making the eventual
consistency window and failure behavior visible and testable rather than hidden in
ad-hoc error handling.

---

**[SENIOR] Q5 (Scenario): Your application uses Redis for sessions. A Redis node fails and users are logged out. The business wants zero downtime. What do you implement?**

Current problem: Redis is a single point of failure for sessions; a Redis node failure
logs out all active users.

Solution architecture - Redis Sentinel for session HA:
1. Deploy 1 primary + 2 replicas + 3 Sentinel processes.
2. Sentinel monitors the primary; on failure, promotes a replica.
3. Sessions on the primary are replicated to replicas (async).
4. Failover time: 30-60 seconds (configurable with `down-after-milliseconds`).
5. During failover: users whose session is requested during the 30-60 second window
   get a session miss; they must log in again.

For near-zero downtime: reduce `down-after-milliseconds` to 2,000 ms; failover in ~5
seconds. Trade-off: increased false-positive detection rate (brief network glitches
cause unnecessary failover).

For true zero session loss: use Redis Cluster (data is sharded; one node failure only
affects sessions on that node's slots; other sessions are unaffected).

Session database fallback:
- Store sessions in both Redis and PostgreSQL (async shadow write to PostgreSQL).
- On Redis miss: check PostgreSQL; if found, re-populate Redis.
- Zero users logged out on Redis failure; slight latency increase for users hitting
  the PostgreSQL fallback.

*What separates good from great:* The session warm-up after failover. After Redis
promotion, the new primary has all replicated data. But the application's connection
pool is still trying to connect to the old primary address. A Sentinel-aware client
(redis-py's Sentinel) handles this automatically: on `ConnectionError`, it asks Sentinels
for the new primary address, reconnects, and retries the operation. The user experience:
a single request may fail or be slightly delayed during the failover; subsequent requests
succeed. For critical sessions (financial applications), implement client-side retry with
exponential backoff; a single failed session lookup should not log the user out; retry
2-3 times before falling back to the database.

---

**[SENIOR] Q6 (Application): How would you choose between PostgreSQL, MongoDB, and DynamoDB for a new B2B SaaS application?**

B2B SaaS characteristics: multi-tenant data isolation, complex per-tenant configuration,
tenant-specific features (different attributes per tenant), compliance requirements,
moderate scale (1,000-100,000 tenants), complex billing queries.

PostgreSQL advantages for B2B SaaS:
- Row-level security (RLS): isolate tenant data without separate schemas.
- ACID for billing: complex billing calculations require consistent reads.
- JSONB columns: store tenant-specific configuration as JSON within SQL.
- Flexible queries: ad-hoc analytics, custom reports per tenant.
- Foreign keys: enforce data integrity across tenant resources.
- Audit logging: `pgaudit` extension for compliance requirements.

MongoDB advantages:
- Flexible schema: each tenant can have different document structures.
- Multi-tenant: per-tenant collections or a tenant_id field with compound indexes.
- Good for: SaaS with highly variable per-tenant data models.

DynamoDB advantages:
- Serverless/per-request pricing: scales to zero for inactive tenants.
- Auto-scaling: handles tenant traffic spikes automatically.
- Global Tables: multi-region for international B2B customers.

Recommendation for most B2B SaaS:
- Start with PostgreSQL: best for complex queries, billing, compliance, moderate scale.
- Add Redis for caching and session state.
- Consider DynamoDB if: per-request pricing is important (long tail of inactive tenants),
  global distribution is a day-one requirement, or serverless architecture.
- Consider MongoDB if: the data model is highly variable across tenants and JSONB
  in PostgreSQL proves insufficient.

*What separates good from great:* The compliance and audit requirements consideration.
B2B SaaS often has SOC 2, GDPR, or HIPAA requirements. PostgreSQL has mature auditing
extensions (pgaudit), point-in-time recovery, and column-level encryption. MongoDB has
comparable auditing features in Atlas. DynamoDB has CloudTrail integration. However,
the team's ability to implement and demonstrate compliance controls is often as important
as the database's capabilities. PostgreSQL's maturity and the availability of compliance-
focused PostgreSQL hosting (RDS, Aurora) makes it the lower-risk choice for compliance-
heavy B2B applications.

---

**[SENIOR] Q7 (Trade-off): When is it a mistake to use Elasticsearch for search instead of PostgreSQL full-text search?**

PostgreSQL full-text search is sufficient when:
- Document count: < 10 million rows that need to be searched.
- Query complexity: keyword matching + category filtering + price range.
- Relevance: basic relevance ranking (PostgreSQL `ts_rank`) is adequate.
- Team size: small team that cannot afford to operate Elasticsearch.
- Operational simplicity: one database is simpler to back up, monitor, and scale.

When PostgreSQL full-text search falls short:
- Scale: > 50 million documents; index maintenance becomes slow.
- Relevance: BM25 relevance scoring, query expansion, synonyms, typo tolerance (fuzzy
  matching) - all built into Elasticsearch but complex to implement in PostgreSQL.
- Multi-language: stemming and language-specific analysis for global products.
- Faceted search: efficient counts per category/attribute for facet navigation.
- Autocomplete: suggest queries as the user types.
- Analytics: log analysis, monitoring, click-stream analysis alongside search.

PostgreSQL full-text search anti-pattern: using `LIKE '%keyword%'` instead of
`tsvector`/`tsquery`. `LIKE` cannot use an index; `to_tsvector` + `to_tsquery` with a
GIN index is 100-1000x faster.

*What separates good from great:* The hybrid approach. For most applications, start with
PostgreSQL full-text search (`tsvector` + GIN index); instrument and measure search
performance and relevance; if search quality or performance becomes a user-reported issue,
add Elasticsearch for the specific search use case. Do not add Elasticsearch
speculatively; add it when PostgreSQL search limitations are demonstrated with user
feedback or performance data. Many B2B SaaS applications with 1-10 million records run
excellent full-text search on PostgreSQL indefinitely, avoiding Elasticsearch's
operational overhead entirely.
