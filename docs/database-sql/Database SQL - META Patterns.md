---
layout: default
title: "Database SQL - META Patterns"
parent: "Database and SQL"
grand_parent: "SK Interview"
nav_order: 10
permalink: /database-sql/meta-patterns/
---

# Database Selection Decision Framework

🎯 Interview Weight: very high - Database selection is a
foundational system design and staff-level engineering decision.

---

### 🎯 Model Answer

**30 seconds:**
> Database selection framework: match the data model, access
> patterns, consistency requirements, and scale characteristics
> to the right storage engine. Relational (PostgreSQL, MySQL):
> structured data, complex queries, ACID transactions. Document
> (MongoDB): flexible schema, hierarchical data, fast iteration.
> Key-value (Redis, DynamoDB): simple lookups, high throughput.
> Column-family (Cassandra): write-heavy, time-series, wide partitions.
> Search (Elasticsearch): full-text search, analytics. Graph
> (Neo4j): relationship traversal. Do not default to PostgreSQL
> for everything - match the tool to the access pattern.

**3 minutes (Senior/Staff):**
> Full decision framework:
>
> Step 1 - Model the access patterns:
> What queries will run 95% of the time?
> Single row by ID: key-value, relational, or document.
> Range scan by time: relational with B-tree index or column-family.
> Full-text search: Elasticsearch or PostgreSQL `tsvector`.
> Relationship traversal (3-4 hops): graph DB.
> Aggregations over large datasets: column-oriented (ClickHouse,
> Redshift) or relational with proper indexing.
>
> Step 2 - Consistency requirements:
> Strict ACID (financial transactions, inventory): PostgreSQL, MySQL.
> Eventual consistency acceptable (social feed, analytics):
> Cassandra, DynamoDB with BASE model.
> Mixed: PostgreSQL for transactional core, Redis for cache,
> Elasticsearch for search. Polyglot persistence.
>
> Step 3 - Scale characteristics:
> Read-heavy (10:1 read/write): any relational with read replicas,
> or document DB with horizontal sharding.
> Write-heavy (millions of writes/second): Cassandra, DynamoDB,
> Kafka (event log). Relational cannot sustain this at single-node scale.
> Large binary objects (images, video): object storage (S3),
> not a database. Store metadata in DB, object in S3.
>
> Step 4 - Team and operational considerations:
> Team expertise matters. A PostgreSQL expert will outperform
> a MongoDB deployment in almost any workload due to better tuning.
> Operational overhead: managed services (RDS, Atlas, Dynamo)
> reduce ops burden. Self-hosted requires expertise.
> Ecosystem: ORM support, tooling, monitoring integration.
>
> Decision matrix - common choices:
> E-commerce orders: PostgreSQL (ACID, complex joins).
> User sessions: Redis (TTL, fast reads/writes).
> Product catalog: MongoDB (flexible schema, nested objects).
> Activity feed (write-heavy): Cassandra.
> Search and discovery: Elasticsearch.
> Fraud graph analysis: Neo4j.
> Analytics and reporting: ClickHouse or BigQuery.
>
> Anti-pattern - premature NoSQL migration:
> "We moved from PostgreSQL to MongoDB for flexibility."
> Result: lost ACID transactions, no joins, rebuilt features.
> Rule: start relational. Migrate only when you hit a concrete
> limitation (not a theoretical one).

**Blank Mind Recovery:**

**(1) Restate:** "Database selection: model access patterns, consistency needs,
write volume, then team expertise. Start relational. Migrate when you have a real problem."

---

### ⚖️ Comparison Table

| Database Type | Best For | Avoid When | Examples |
|--------------|---------|-----------|---------|
| Relational | ACID, joins, complex queries | Massive write throughput | PostgreSQL, MySQL |
| Document | Flexible schema, hierarchical data | Complex joins | MongoDB, Firestore |
| Key-Value | Fast lookups, sessions, cache | Rich queries | Redis, DynamoDB |
| Column-Family | Write-heavy, time-series | Complex transactions | Cassandra, HBase |
| Search | Full-text, faceting, analytics | Transactional writes | Elasticsearch |
| Graph | Relationship traversal | High-volume flat queries | Neo4j, Amazon Neptune |
| Time-Series | Metrics, IoT data streams | General purpose | InfluxDB, TimescaleDB |

---

### ⚠️ Common Misconceptions

**Misconception 1:** NoSQL = more scalable than SQL.
**Reality:** PostgreSQL with proper indexing, partitioning, and read
replicas handles billions of rows. The bottleneck is almost never
SQL itself - it is schema design, index design, or connection pooling.
DynamoDB's unlimited scale comes with significant trade-offs: no joins,
limited query patterns, eventual consistency by default.

**Misconception 2:** MongoDB is faster than PostgreSQL.
**Reality:** MongoDB is faster for flexible-schema document storage and
certain document-retrieval patterns. PostgreSQL is faster for aggregations,
joins, and queries that benefit from B-tree or hash indexes. Benchmark
your actual access patterns, not synthetic tests.

**Misconception 3:** Always choose a managed database.
**Reality:** Managed databases (RDS, Atlas) are correct for most teams.
But managed costs 3-5x more than self-hosted at scale. At high volume
(10TB+, millions of queries/hour), self-hosted with a DBA may be cheaper.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Wrong database for the write pattern.**
Symptom: PostgreSQL insert throughput plateauing at 50,000 inserts/second.
CPU is not the bottleneck - WAL write latency is.
Diagnosis: `pg_stat_bgwriter`, `pg_stat_wal`. WAL writes are saturating.
Fix: batch inserts, use COPY for bulk load, or migrate write-heavy
time-series data to TimescaleDB or Cassandra.

**Failure 2: Using Redis as a primary database.**
Symptom: Redis OOM (out of memory). Data loss on restart.
Root cause: Redis data exceeds `maxmemory`. Eviction policy removes
data that should be durable. Redis is an in-memory cache with optional
persistence, not a primary data store for critical data.
Fix: set `maxmemory-policy allkeys-lru` for cache use. For durable
data: use PostgreSQL + Redis cache pattern, not Redis alone.

**Failure 3: MongoDB schema flexibility becomes schema chaos.**
Symptom: 47 different document shapes for the same "product" collection.
Developers insert whatever they want. Queries fail on missing fields.
Fix: Mongoose schema validation (application layer) or MongoDB
JSON Schema validation (DB layer). Flexibility is a feature, not
a license to ignore data modeling.

---

### 🎓 Answers by Seniority

**Junior/Mid:**
"I would choose the database based on: do we need ACID transactions?
Is the data structured or flexible? How much volume are we expecting?
For most web apps, PostgreSQL is the right starting point."

**Senior/Staff:**
"Database selection starts with access pattern modeling. I draw the
five most frequent query types, their latency requirements, and their
consistency requirements. I then map those to the database characteristics
that serve those patterns best. I also factor in team expertise and
operational overhead. I default to PostgreSQL and only migrate when
we hit a concrete, measured limitation - not a theoretical one.
Polyglot persistence (PostgreSQL + Redis + Elasticsearch) is common
at scale, each serving its specific pattern."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | Basic database types + selection criteria |
| Senior | 9 min | Access pattern modeling + polyglot persistence |
| Staff | 12 min | Full decision framework + anti-patterns + cost model |

**[TRADE-OFF]** When would you choose MongoDB over PostgreSQL?

> *Why they ask:* Tests whether the candidate has principled
> decision-making or just cargo-culted preferences.
>
> *Full answer:* "I would choose MongoDB over PostgreSQL when
> the data model is genuinely hierarchical and variable: each
> document has a different schema that would require either a
> massive table with many nullable columns, or multiple joined
> tables for what is logically one object. A content management
> system with 20 different content types, each with different
> fields, is a good candidate.
>
> I would also choose MongoDB when the team is doing rapid
> iteration on a schema that changes weekly during early product
> development, and the overhead of migrations (ALTER TABLE) is
> causing friction.
>
> I would NOT choose MongoDB when: I need ACID transactions across
> multiple documents (MongoDB has multi-document transactions but
> they are slower and more limited than PostgreSQL's), when I need
> complex joins across multiple collections (MongoDB lookups are
> slower than relational joins), or when reporting and analytics
> queries are a core use case (PostgreSQL's query planner handles
> these better).
>
> The truth is: for 80% of web applications, PostgreSQL and MongoDB
> can both work. The differentiator is the 20% edge case -
> transactions vs. schema flexibility. Know which 20% you are in."
>
> *What separates good from great:* Gives a concrete use case
> (CMS with variable content types), not just abstract criteria.
> Acknowledges MongoDB's transaction support while identifying
> its limitations. Avoids tribalism.

**[DEBUGGING]** PostgreSQL is running slow. What is your diagnostic process?

> *Why they ask:* Tests practical database operations knowledge.
>
> *Full answer:* "Start with `pg_stat_statements` - shows the
> top queries by total time, mean time, and call count.
> The 5 most expensive queries by total time are responsible
> for 90% of the performance problem 90% of the time.
>
> For each expensive query: run `EXPLAIN (ANALYZE, BUFFERS)`.
> Look for: Seq Scan on large tables (missing index), nested
> loop with high row estimates (statistics stale, run ANALYZE),
> or Sort/Hash Join spilling to disk (work_mem too low).
>
> Check resource utilization: `pg_stat_activity` for currently
> running queries and lock waits. `pg_locks` joined with
> `pg_stat_activity` for lock chains.
>
> If the problem is system-level: check `pg_stat_bgwriter`
> for checkpoint frequency and buffer hit ratio. Hit ratio
> < 95% means not enough `shared_buffers` for the working set.
>
> Common root causes I've encountered: a missing index on a
> foreign key (developers forget to index the FK side of a join),
> `autovacuum` falling behind (dead tuples bloating tables),
> or connection pool exhaustion (500 connections all waiting
> on the same lock)."
>
> *What separates good from great:* Starts with `pg_stat_statements`
> not random guessing. Has a mental model of the most common
> root causes from real production experience.

**[BEHAVIORAL]** Describe a time you chose the wrong database and what you learned.

> *Why they ask:* Tests intellectual honesty and learning from mistakes.
>
> *Strong answer pattern:* "We chose Cassandra for a feature that we
> expected to be write-heavy. The actual access pattern turned out
> to be 70% reads with complex filtering - Cassandra's partition
> key model made those queries require full cluster scans.
> We spent 3 months fighting Cassandra before migrating back to
> PostgreSQL. Lesson: model your actual access patterns before
> choosing a database. Never choose based on what you think
> the access pattern will be - validate it with early prototyping
> or traffic analysis."
>
> *What separates good from great:* Owns the mistake. Extracts
> a clear, reusable lesson. Doesn't blame the database.

---

---

# Query Optimization Mental Model

🎯 Interview Weight: very high - Query optimization is a senior
engineering skill tested deeply in most data-intensive interviews.

---

### 🎯 Model Answer

**30 seconds:**
> Query optimization mental model: the database query planner
> converts SQL into an execution plan - a tree of operators
> (seq scan, index scan, hash join, sort, aggregate). Optimization
> is the art of understanding this plan and guiding the planner
> toward an efficient one. Core levers: indexes (remove full
> scans), statistics (ANALYZE for accurate row estimates), join
> order (smaller tables first), selectivity (filter early), and
> resource settings (work_mem for sorts and hash joins).

**3 minutes (Senior):**
> Query optimization layered model:
>
> Layer 1 - Read the EXPLAIN plan:
> `EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)` is the primary tool.
> Key signals:
> `Seq Scan` on a large table: needs an index.
> `Rows=10000` but actual `rows=1`: stale statistics.
> `Buffers: read=5000`: 5000 disk pages read (cache miss).
> `Buffers: hit=50000`: 50000 pages from shared_buffers (fast).
>
> Layer 2 - Index strategy:
> B-tree index: equality and range filters, ORDER BY.
> `CREATE INDEX ON orders(customer_id)` for `WHERE customer_id = ?`.
> Composite index: `(customer_id, created_at)` for
> `WHERE customer_id = ? AND created_at > ?` (prefix must match).
> Partial index: `CREATE INDEX ON orders(status) WHERE status = 'pending'`.
> Much smaller index, faster for queries filtering on `pending`.
> Covering index: include all columns in the index to enable
> index-only scan (no heap fetch).
> `CREATE INDEX ON orders(customer_id) INCLUDE (total, status)`.
>
> Layer 3 - Join optimization:
> Hash join: good for large table joins (build hash table of
> smaller table, probe with larger). Work_mem determines whether
> it fits in memory. Spill to disk = 10x slower.
> Nested loop + index: good for small outer result sets.
> `SELECT * FROM orders o JOIN customers c ON o.customer_id = c.id
> WHERE o.status = 'new'` - if `status = 'new'` is selective,
> nested loop with index lookup on customers is fast.
>
> Layer 4 - Statistics and planning:
> `ANALYZE` updates statistics. Planner uses row count estimates
> to choose join strategy. Stale statistics cause the planner to
> choose wrong join type (nested loop on 1M rows = catastrophic).
> `autovacuum` runs ANALYZE automatically but may lag behind.
> After bulk load: `ANALYZE orders` immediately.
>
> Layer 5 - Application-level optimization:
> N+1 query problem: 1 query to get orders, then N queries to
> get each customer. Fix: JOIN or prefetch in one query.
> SELECT *: fetches all columns, inflating buffer usage.
> Fix: select only needed columns.
> Pagination: `OFFSET 50000 LIMIT 10` is slow (scans 50,000 rows).
> Fix: keyset pagination: `WHERE id > last_seen_id LIMIT 10`.

**Blank Mind Recovery:**

**(1) Restate:** "Query optimization: EXPLAIN first, find the bottleneck
(Seq Scan / stale stats / sort spill), then fix with index or ANALYZE."

---

### 💻 Code Example

```sql
-- BAD: N+1 pattern - 1 + N queries
SELECT id FROM orders WHERE status = 'pending';
-- Then for each order ID:
SELECT * FROM customers WHERE id = ?;

-- GOOD: single JOIN query
SELECT o.id, o.total, c.name, c.email
FROM orders o
JOIN customers c ON o.customer_id = c.id
WHERE o.status = 'pending';

-- BAD: OFFSET-based pagination (scans 50,000 rows)
SELECT * FROM orders
ORDER BY created_at DESC
OFFSET 50000 LIMIT 10;

-- GOOD: keyset pagination (index seek only)
SELECT * FROM orders
WHERE created_at < :last_seen_ts
ORDER BY created_at DESC
LIMIT 10;
```

> **Code walkthrough:** The N+1 pattern sends N+1 round trips
> to the database - devastating at scale. The JOIN version
> sends one query and lets the database engine do the work
> efficiently with indexed lookups. The OFFSET pagination
> scans 50,000 rows to discard them. Keyset pagination uses
> an index seek directly to the starting position, making it
> O(log n) instead of O(n) regardless of page number.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | EXPLAIN basics + index types |
| Senior | 9 min | Join optimization + statistics + keyset pagination |
| Staff | 12 min | Full mental model + query planner internals |

**[DEBUGGING]** EXPLAIN ANALYZE shows `rows=1` estimated but `rows=50000` actual. Why?

> *Why they ask:* Tests deep understanding of the query planner.
>
> *Full answer:* "This is a statistics staleness problem. The planner
> estimated 1 row because `pg_statistic` (the statistics catalog
> updated by ANALYZE) still shows the old distribution for that column.
> If the table received a large insert of matching rows after the
> last ANALYZE, the planner does not know about them.
>
> The consequence: the planner chose a plan optimized for 1 row
> (likely a nested loop join or an index scan). With 50,000 actual
> rows, a hash join would be far more efficient.
>
> Fix: `ANALYZE orders` to update statistics immediately.
> Ensure `autovacuum` is configured with `autovacuum_analyze_scale_factor`
> set appropriately (default 0.2 means ANALYZE triggers when 20% of
> the table changes - too high for large tables with frequent writes).
> For a 100M-row table, lower it: `ALTER TABLE orders SET (autovacuum_analyze_scale_factor = 0.01)`.
>
> Prevention: after bulk data loads, always run ANALYZE on affected tables.
> Monitor with: `SELECT relname, n_live_tup, n_dead_tup, last_analyze
> FROM pg_stat_user_tables WHERE last_analyze < now() - interval '1 day'`."
>
> *What separates good from great:* Explains the root cause mechanism
> (pg_statistic staleness), not just the fix (ANALYZE). Knows how
> to tune autovacuum for large tables.

---

---

# Data Modeling Decision Patterns

🎯 Interview Weight: high - Data modeling determines long-term
database performance and maintainability.

---

### 🎯 Model Answer

**30 seconds:**
> Data modeling decisions: normalization vs denormalization,
> entity-relationship modeling, surrogate vs natural keys, and
> schema evolution strategy. Core trade-off: normalization
> eliminates redundancy and update anomalies (good for writes and
> consistency) but requires joins (slower reads). Denormalization
> reduces joins (faster reads) but creates redundancy (harder updates,
> potential inconsistency). Choose based on your read-to-write ratio
> and join complexity in production queries.

**3 minutes (Senior):**
> Data modeling patterns and decisions:
>
> Normalization levels:
> 1NF: no repeating groups (no array of values in one column).
> 2NF: no partial dependency (all non-key columns depend on the
> full primary key, not just part of it).
> 3NF: no transitive dependency (no non-key column depends on
> another non-key column).
> 3NF is the standard target for transactional systems.
> BCNF and higher: academic. Rarely needed in practice.
>
> When to denormalize:
> Read-heavy reporting query: 5-way join taking 3 seconds.
> Denormalize: create a read model (summary table) or materialized view.
> Updated by: trigger on the source tables, or batch job, or CDC.
> Trade-off: write amplification (one logical update hits multiple tables).
>
> Surrogate vs natural keys:
> Surrogate (UUID, serial): stable, no business meaning, can always
> change the natural identifier without cascading FK updates.
> Natural key (email, username): meaningful but problematic - users
> change email, causes cascade updates across all FKs.
> Recommendation: surrogate PK + unique constraint on natural identifier.
>
> Schema evolution:
> Additive changes (add column, add table): safe. Old code ignores new columns.
> Non-additive changes (rename column, change type): breaking.
> Require expand-contract pattern: add new column, migrate data,
> update application code, drop old column.
> Blue-green deployments require backward-compatible migrations.
>
> EAV anti-pattern (Entity-Attribute-Value):
> `(entity_id, attribute_name, attribute_value)` - "flexible schema in SQL."
> Symptom: finding all entities with `attribute = 'color' AND value = 'red'`
> requires a self-join or pivoting.
> Performance: catastrophic for any aggregation.
> Fix: use JSONB column (PostgreSQL) for flexible attributes, or
> use a document database if truly schema-less.
>
> Soft delete:
> `deleted_at TIMESTAMP NULL` instead of physical deletion.
> Pitfall: unique constraints silently break (two deleted users
> with the same email, then trying to reactivate one fails the
> unique constraint).
> Fix: partial unique index: `CREATE UNIQUE INDEX ON users(email)
> WHERE deleted_at IS NULL`.

**Blank Mind Recovery:**

**(1) Restate:** "Data modeling: 3NF as default. Denormalize for read-heavy paths.
Surrogate PKs. Additive migrations for zero-downtime deploys. Avoid EAV."

---

### 💻 Code Example

```sql
-- BAD: natural key as PK (fragile on user data change)
CREATE TABLE users (
    email VARCHAR(255) PRIMARY KEY,  -- email can change!
    name  VARCHAR(255)
);

CREATE TABLE orders (
    id         SERIAL PRIMARY KEY,
    user_email VARCHAR(255) REFERENCES users(email)
    -- FK to email: all orders must be updated if email changes
);

-- GOOD: surrogate PK + unique constraint on natural key
CREATE TABLE users (
    id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email      VARCHAR(255) UNIQUE NOT NULL,
    name       VARCHAR(255)
);

CREATE TABLE orders (
    id         UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id    UUID REFERENCES users(id),  -- stable FK
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Partial unique index for soft delete
CREATE UNIQUE INDEX users_email_active_uniq
    ON users(email) WHERE deleted_at IS NULL;
```

> **Code walkthrough:** The BAD pattern uses email as a primary key.
> Changing a user's email requires updating every orders row that
> references it - a cascading update across potentially millions of rows.
> The GOOD pattern uses a UUID surrogate key. The email unique constraint
> still enforces business rule integrity. The partial unique index
> for soft delete allows multiple deleted records with the same email
> while still enforcing uniqueness among active users - a subtle but
> critical production requirement.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Normalization + surrogate vs natural keys |
| Senior | 9 min | Schema evolution + EAV anti-pattern + denormalization |
| Staff | 12 min | Full data modeling strategy + event sourcing + CQRS |

**[TRADE-OFF]** When would you intentionally denormalize a relational schema?

> *Why they ask:* Tests understanding of the read-write trade-off.
>
> *Full answer:* "I would denormalize when I have a read-heavy query
> that is on the critical path (user-facing, latency-sensitive) and
> the normalized query requires multiple joins that cannot be
> eliminated with indexes alone.
>
> Classic example: a dashboard that shows orders with customer name,
> product names, and category names. Normalized: 4-5 joins. At
> high traffic this can be optimized with indexes and caching,
> but at scale the join overhead accumulates.
>
> My approach: first, add a materialized view. This is a denormalized
> snapshot refreshed on schedule or via trigger. No application code
> changes. If refresh latency is acceptable (seconds to minutes), this
> is the right answer.
>
> If real-time consistency is required: add a read-model table updated
> via application logic or database triggers. The write path updates
> both the normalized source tables and the denormalized read model.
>
> The cost: every write that affects the denormalized columns must
> update multiple tables. This increases write latency and adds
> failure modes (what if the read model update fails?).
>
> I never denormalize preemptively. Measure first - is the join
> query actually slow? Can it be fixed with an index? Denormalization
> should be the last resort after exhausting index optimization."
>
> *What separates good from great:* Knows the materialized view
> option (middle ground between normalized and fully denormalized).
> Quantifies the write cost. Refuses to denormalize without measurement.

| Interviewer Type | Emphasis |
|------------------|---------|
| System Design | Database selection framework + trade-offs |
| Technical Panel | Query optimization + EXPLAIN plan reading |
| Bar Raiser | Data modeling patterns + schema evolution strategy |
