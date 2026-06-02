---
layout: default
title: "NoSQL - L5 Migration"
parent: "NoSQL"
nav_order: 14
permalink: /nosql/l5-migration/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [NoSQL Migration Strategies from Relational Databases](#nosql-migration-strategies-from-relational-databases) | ★★★ |

---

# NoSQL Migration Strategies from Relational Databases

---

### 🎯 Model Answer

**30 seconds:**
> Migrating from a relational database to NoSQL requires three phases: (1) Data model
> transformation - relational normalization must be denormalized for NoSQL (MongoDB
> embeds related data; Cassandra designs tables per query pattern). (2) Dual-write
> migration - run both databases in parallel; write to both; read from the old database
> until the new one is verified. (3) Cutover - switch reads to the new database;
> validate; decommission the old database. The most common failure: migrating the
> relational schema directly to NoSQL without redesigning for NoSQL access patterns.

**3 minutes (Senior):**
> Four migration phases with specific risks: (1) Schema analysis and NoSQL data model
> design - this is the hardest phase; relational schemas normalized to 3NF must be
> completely redesigned around NoSQL access patterns; migrating the relational schema
> 1:1 to MongoDB (one collection per table) produces a MongoDB that behaves exactly
> like a slow relational database (application-level joins, no referential integrity
> errors). (2) Data migration - bulk export from RDBMS, transform, bulk import to NoSQL;
> for large datasets (> 1 TB), use parallel bulk loading; keep transformation idempotent
> for retries. (3) Dual-write period - both databases receive all writes; reads from old
> database; delta verification shows both databases are consistent; zero-downtime
> migration requires this phase. (4) Traffic cutover - reads switch to new database; use
> feature flags to roll back if issues appear; keep the old database in read-only mode
> for 30 days as a rollback option. Risk: transaction rollback during dual-write; a
> write to the new database fails after succeeding in the old; compensating logic needed.

**Framework:** Analyze -> Redesign -> Migrate Data -> Dual-Write -> Verify -> Cutover

**Blank Mind Recovery:**

**(1) Restate:** "RDBMS to NoSQL migration: (1) redesign data model (NOT 1:1 schema
copy). (2) Bulk migrate data. (3) Dual-write period (both DBs get writes). (4) Verify
consistency. (5) Cut over reads to NoSQL. (6) Keep RDBMS in read-only 30 days."

**(2) First principles:** "Relational schemas are normalized to eliminate redundancy.
NoSQL schemas are denormalized to eliminate joins. These are opposite design philosophies.
A 1:1 relational-to-NoSQL migration produces a denormalized schema that still requires
application-level joins - the worst of both worlds. The migration must redesign the
schema from scratch around the application's actual query patterns."

**(3) Bridge:** "Migrating a relational schema to MongoDB is like moving furniture
from a house to a boat without considering that a boat requires different furniture.
You can put a sofa on a boat, but you won't have room to walk around. NoSQL schemas
are purpose-built for their environment; relational schemas must be redesigned, not
transported."

---

### 📘 Concept Explanation

**Relational to NoSQL Schema Transformation:**

```text
RELATIONAL SCHEMA (normalized, 3NF):

  users table:
  +------+--------+-------+
  | id   | name   | email |
  +------+--------+-------+
  | 1    | Alice  | a@x   |

  orders table:
  +----+---------+--------+-----------+
  | id | user_id | status | total_amt |
  +----+---------+--------+-----------+
  | 10 | 1       | paid   | 99.99     |

  order_items table:
  +---------+------------+-----+-----+
  | orderId | product_id | qty | prc |
  +---------+------------+-----+-----+
  | 10      | 42         | 2   | 9.5 |

  Query: get order with items for user Alice
  SELECT o.*, oi.*
  FROM users u
  JOIN orders o ON o.user_id = u.id
  JOIN order_items oi ON oi.order_id = o.id
  WHERE u.email = 'a@x' AND o.id = 10

  WRONG MONGODB MIGRATION (1:1 mapping):
  {collection: "orders", doc: {id: 10, user_id: 1}}
  {collection: "order_items", doc: {order_id: 10, ...}}
  -> Application must do 2 round-trip queries
  -> No referential integrity in MongoDB
  -> Slower than relational for this pattern!

  CORRECT MONGODB MIGRATION (query-driven):
  {collection: "orders", doc: {
    "_id": 10,
    "user_id": 1,
    "user_email": "a@x",  <- denormalized from users
    "status": "paid",
    "total_amount": 99.99,
    "items": [            <- embedded array
      {"product_id": 42, "qty": 2, "price": 9.50}
    ]
  }}
  Query: db.orders.findOne({_id: 10})
  -> Single document, no joins, 1 round-trip
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the transformation from a normalized
> relational schema (users, orders, order_items tables) to the correct MongoDB document
> model (single orders collection with embedded items and denormalized user data). (2)
> HOW TO READ IT: the top shows the relational schema requiring a 3-table JOIN; the middle
> shows the wrong migration (1:1 table-to-collection copy that still needs multiple
> queries); the bottom shows the correct MongoDB document that satisfies the primary
> query pattern in a single round-trip. (3) KEY RELATIONSHIP: the embedded items array
> eliminates the need for a separate collection and a cross-collection lookup; the
> denormalized `user_email` eliminates the user lookup at read time. (4) EDGE CASE:
> embedding items works when orders have a bounded number of items (< 1,000); if orders
> can have millions of items (unusual), embedding causes document size to exceed MongoDB's
> 16 MB limit; in that case, use a reference instead of embedding. (5) INSIGHT: a senior
> engineer's first migration question is "what queries does the application actually run?"
> not "what tables exist?"; the NoSQL schema should match the query, not the existing
> schema.

**Dual-Write Migration Architecture:**

```text
DUAL-WRITE MIGRATION PHASES:

  Phase 1: SHADOW WRITE
  Application -> PostgreSQL (primary)
  Application -> MongoDB (shadow, writes only)
  Reads still from PostgreSQL
  Purpose: fill MongoDB with new data;
           verify writes don't fail

  Phase 2: DATA BACKFILL
  Migration job reads PostgreSQL
  Transforms and writes to MongoDB
  (for historical data before Phase 1 started)
  Run idempotently; can restart if interrupted

  Phase 3: VERIFICATION
  Reconciliation job: compare PostgreSQL vs MongoDB
  Check row counts, checksums, sample records
  Fix discrepancies
  Confirm: MongoDB has all data PostgreSQL has

  Phase 4: READ SHADOW
  Some reads routed to MongoDB (canary)
  Compare MongoDB response vs PostgreSQL response
  Find discrepancies in read path
  Gradually increase MongoDB read %

  Phase 5: CUTOVER
  100% reads to MongoDB
  PostgreSQL set to read-only
  Feature flag: can instantly revert to PostgreSQL

  Phase 6: DECOMMISSION (30+ days later)
  PostgreSQL reads stop; monitor for issues
  Take final backup
  Decommission PostgreSQL cluster
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the six-phase dual-write migration
> strategy for zero-downtime database migration with rollback capability at each phase.
> (2) HOW TO READ IT: phases proceed left-to-right over days to months; each phase adds
> confidence before the next; the rollback option exists at every phase by reverting
> the feature flag. (3) KEY RELATIONSHIP: the verification phase (Phase 3) is the critical
> gate; any discrepancy found here must be resolved before proceeding to read traffic;
> a discrepancy indicates either a transformation bug or a write path inconsistency. (4)
> EDGE CASE: during Phase 1 (shadow write), if the MongoDB write fails (network error,
> write conflict), the write must NOT fail the primary PostgreSQL write; MongoDB write
> failures are logged and retried asynchronously; the shadow write is best-effort. (5)
> INSIGHT: a senior engineer allocates the most time to Phase 2 (data backfill) for large
> datasets; a 1 TB database backfill at 100 MB/s takes 2.8 hours; with transformation
> overhead, 8-12 hours is typical; plan the maintenance window accordingly.

---

### 💻 Code Example

```python
# BAD: Direct 1:1 schema migration (anti-pattern)
# Migrates relational schema to MongoDB without redesign

def migrate_orders_wrong(pg_conn, mongo_db):
    """
    Anti-pattern: migrates PostgreSQL tables to MongoDB
    collections with the same structure.
    """
    cursor = pg_conn.cursor()
    # Migrate orders table directly
    cursor.execute("SELECT * FROM orders")
    for row in cursor:
        # Column names from PostgreSQL
        mongo_db.orders.insert_one({
            "id": row[0],
            "user_id": row[1],  # foreign key stored as-is
            "status": row[2],
            "created_at": row[3]
        })

    # Migrate order_items as a separate collection
    # (same as relational - still needs application join)
    cursor.execute("SELECT * FROM order_items")
    for row in cursor:
        mongo_db.order_items.insert_one({
            "order_id": row[0],  # foreign key
            "product_id": row[1],
            "quantity": row[2],
            "price": row[3]
        })
    # Result: MongoDB with relational structure
    # Reading an order still requires 2 queries
    # No benefit from MongoDB's document model
    # WORSE: no relational integrity guarantees
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the wrong migration approach - copying the
> relational schema 1:1 into MongoDB, preserving foreign keys as fields and creating
> separate collections for each table. (2) KEY MECHANISM: the `order_items` collection
> stores `order_id` as a foreign key reference, exactly as in PostgreSQL; reading an
> order still requires two queries: one for `orders`, one for `order_items` where
> `order_id` matches; this is an application-level join, which is slower than a
> database JOIN. (3) WHY IT MATTERS: this pattern produces a system that is slower
> than PostgreSQL for reads (no optimizer, no native joins), has no referential integrity
> (can insert `order_items` with non-existent `order_id`), and has none of the
> performance benefits of MongoDB's document model. (4) WHAT BREAKS: MongoDB has no
> concept of foreign key constraints; orphaned `order_items` records are possible; data
> integrity must be enforced at the application layer. (5) TAKEAWAY: before migrating
> any schema to NoSQL, audit every query the application runs; for each query, design
> the NoSQL schema to answer it in one round-trip without application-level joins.

```python
# BAD: (see above - 1:1 relational schema migration without query-driven redesign)
# GOOD: Query-driven schema design + idempotent bulk migration

from pymongo import MongoClient, UpdateOne
import psycopg2
from datetime import datetime

def migrate_orders_correct(
    pg_conn,
    mongo_db,
    batch_size: int = 1000
):
    """
    Correct approach: denormalize and embed for
    the primary access pattern.
    Idempotent: can be re-run safely.
    """
    cursor = pg_conn.cursor()

    # Fetch orders with all related data in one SQL query
    # (use the relational database's join capability
    #  to produce the denormalized document)
    cursor.execute("""
        SELECT
            o.id,
            o.status,
            o.created_at,
            o.total_amount,
            u.id AS user_id,
            u.email AS user_email,
            u.name AS user_name,
            json_agg(json_build_object(
                'product_id', oi.product_id,
                'quantity',   oi.quantity,
                'price',      oi.price
            )) AS items
        FROM orders o
        JOIN users u ON u.id = o.user_id
        JOIN order_items oi ON oi.order_id = o.id
        GROUP BY o.id, u.id
        ORDER BY o.id
    """)

    # Batch insert for efficiency
    operations = []
    for row in cursor:
        doc = {
            "_id": str(row[0]),
            "status": row[1],
            "created_at": row[2],
            "total_amount": float(row[3]),
            "user": {
                "id": str(row[4]),
                "email": row[5],
                "name": row[6]
            },
            "items": row[7]
        }
        # Upsert: idempotent (safe to re-run)
        operations.append(UpdateOne(
            {"_id": doc["_id"]},
            {"$set": doc},
            upsert=True
        ))

        if len(operations) >= batch_size:
            mongo_db.orders.bulk_write(operations)
            operations = []

    if operations:
        mongo_db.orders.bulk_write(operations)

    print(f"Migration complete: {cursor.rowcount} orders")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the correct migration - using PostgreSQL's
> JOIN capability to produce denormalized documents during migration, then bulk-upserting
> into MongoDB with idempotent upsert operations. (2) KEY MECHANISM: `json_agg()` in
> PostgreSQL aggregates all order items into a JSON array in the SQL query; the migration
> script receives complete orders (with embedded items) rather than separate rows; each
> MongoDB document is the complete order as it should appear. The `UpdateOne` with
> `upsert=True` is idempotent: running the migration twice produces the same result,
> no duplicate documents. (3) WHY IT MATTERS: the resulting MongoDB collection has
> one document per order with embedded items; reading an order is a single `findOne(_id)`
> call; the primary access pattern requires no joins. (4) WHAT BREAKS: the `json_agg`
> subquery requires PostgreSQL 9.4+; for very large orders (thousands of items), the
> JSON aggregation may run out of memory in PostgreSQL; add a row count check per order
> and fall back to separate queries for orders exceeding a threshold. (5) TAKEAWAY:
> always use the relational database's power (joins, aggregations) during migration to
> produce the denormalized NoSQL documents; avoid fetching related data in application
> code during migration (multiple round-trips make large dataset migrations slow).

```python
# Dual-write shim: writes to both PostgreSQL and MongoDB
# during migration Phase 1

from contextlib import contextmanager

class DualWriteOrderRepository:
    """
    Writes to PostgreSQL (primary) and MongoDB (shadow).
    MongoDB failures do not fail the primary write.
    """

    def __init__(self, pg_session, mongo_db, enabled: bool):
        self.pg = pg_session
        self.mongo = mongo_db
        self.dual_write_enabled = enabled

    def create_order(self, order_data: dict) -> dict:
        # PRIMARY write: PostgreSQL (must succeed)
        pg_order = self._write_to_postgres(order_data)

        # SHADOW write: MongoDB (best-effort)
        if self.dual_write_enabled:
            try:
                self._write_to_mongodb(pg_order)
            except Exception as e:
                # Log and continue; never fail primary write
                # for shadow write failure
                print(
                    f"MongoDB shadow write failed: {e} "
                    f"order_id={pg_order['id']}"
                )
                # Queue for async retry
                self._queue_for_retry(pg_order)

        return pg_order

    def _write_to_postgres(self, order_data):
        # Standard PostgreSQL write
        order = Order(**order_data)
        self.pg.add(order)
        self.pg.commit()
        return order.to_dict()

    def _write_to_mongodb(self, pg_order):
        # Transform PostgreSQL row format to MongoDB document
        doc = self._transform_to_document(pg_order)
        self.mongo.orders.update_one(
            {"_id": doc["_id"]},
            {"$set": doc},
            upsert=True
        )
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the dual-write shim pattern - a repository
> class that writes to PostgreSQL first (primary) and then to MongoDB (shadow) with
> explicit error isolation between the two writes. (2) KEY MECHANISM: the `try/except`
> block around the MongoDB write ensures that MongoDB failures (network error, timeout,
> document validation failure) NEVER propagate to the caller; the PostgreSQL write succeeds;
> the MongoDB write failure is logged and queued for async retry. (3) WHY IT MATTERS:
> during the dual-write migration phase, MongoDB may have configuration issues or schema
> mismatches; if MongoDB failures caused primary write failures, the migration would create
> outages; the shadow write is explicitly best-effort. (4) WHAT BREAKS: if MongoDB writes
> fail silently and the retry queue is not monitored, MongoDB falls behind; when the team
> switches reads to MongoDB, data is missing; always monitor the retry queue length and
> alert when it exceeds a threshold. (5) TAKEAWAY: the dual-write shim is a temporary
> component; it should be code-reviewed and removed as soon as the migration cutover is
> complete; leaving dual-write code in production indefinitely creates confusion about
> which database is authoritative.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> Migrating from PostgreSQL to MongoDB requires three steps: (1) Redesign the schema
> for MongoDB's document model (embed related data, denormalize for reads). (2) Migrate
> existing data (write a migration script that reads from PostgreSQL and writes to
> MongoDB). (3) Switch the application to read from MongoDB. The most important thing:
> do NOT copy the relational schema directly to MongoDB. MongoDB documents should be
> designed around the application's queries, not the existing database tables.

---

**Senior / Staff (5+ years):**
> NoSQL migration risk matrix: (1) Data model mismatch - relational 3NF to NoSQL
> requires complete redesign; test the new data model with production query patterns
> before migration; validate read latency improvement. (2) Consistency during dual-write
> - MongoDB write failures must not fail primary writes; retry queues must be monitored;
> reconciliation jobs verify consistency before cutover. (3) Schema evolution - MongoDB
> is schemaless but applications expect a schema; establish a schema validation policy
> at the application layer; use JSON Schema validation in MongoDB for production. (4)
> Rollback plan - keep the relational database in read-only mode for 30+ days after
> cutover; maintain the dual-write capability as a fast rollback mechanism; test the
> rollback procedure before cutover. (5) Performance validation - benchmark the NoSQL
> database with production data volume and access patterns before cutover; do not assume
> MongoDB is faster than PostgreSQL without measuring.

---

### ⚠️ Common Misconceptions

**Misconception 1: "NoSQL databases are always faster than relational databases."**

NoSQL databases are optimized for specific access patterns, not universally faster.
Benchmarks that compare PostgreSQL with MongoDB on document inserts show MongoDB
faster - but those benchmarks use single-document writes, MongoDB's optimal pattern.
Benchmarks on aggregations with multiple related entities show PostgreSQL faster -
because PostgreSQL's query optimizer, indexes, and join algorithms are mature and highly
optimized. Before migrating from PostgreSQL to MongoDB for "performance," benchmark
both systems with YOUR application's actual queries on YOUR data volume. Teams that
migrate without benchmarking frequently discover MongoDB is slower for their specific
use case due to: application-level joins (worse than SQL joins), lack of secondary
indexes on all necessary fields, or document scans on large collections.

**Misconception 2: "Cassandra can replace PostgreSQL for any workload if we design the right schema."**

Cassandra's design makes it fundamentally unsuitable for certain workloads regardless
of schema design:
(1) Complex aggregations: Cassandra has no GROUP BY, SUM, or JOIN; aggregations require
application-level processing.
(2) Multi-partition transactions: Cassandra's Lightweight Transactions (LWT) use Paxos
and work only within a single partition; cross-partition atomicity is not possible.
(3) Ad-hoc queries: Cassandra requires knowing queries at schema design time; adding
a new access pattern requires a new table (data model redesign); PostgreSQL's query
planner handles ad-hoc queries efficiently.
(4) Low-throughput, high-complexity queries: Cassandra is optimized for high-throughput
simple queries; at low throughput with complex requirements, PostgreSQL is more suitable.
A database migration decision must start with the specific access patterns that are
exceeding PostgreSQL's capacity, not with a blanket assumption that any NoSQL database
handles all workloads better.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Data loss during migration due to non-idempotent transformation.**

Symptom: after migration and cutover, some records in MongoDB have missing fields
or incorrect values; the data was correct in PostgreSQL before migration.
Root cause: the transformation script had a bug (null pointer exception, incorrect
field mapping) that silently skipped or corrupted some records; the script was not
idempotent, so re-running it produced different results.

Diagnosis:

```bash
# Reconciliation: count records in both databases
psql -U postgres -c "SELECT COUNT(*) FROM orders;"
# count: 4,523,891

mongosh --eval "db.orders.countDocuments({})"
# 4,521,453  <- 2,438 records missing!

# Find missing order IDs
psql -U postgres -c "
  SELECT id FROM orders
  ORDER BY id
" > /tmp/pg_ids.txt

mongosh --eval "
  db.orders.find({}, {_id: 1}).forEach(
    o => print(o._id)
  )
" > /tmp/mongo_ids.txt

diff <(sort /tmp/pg_ids.txt) <(sort /tmp/mongo_ids.txt) \
  | grep '^<' | head -20
# Lines starting with '<' are in PG but not MongoDB
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnosing record loss after migration by comparing record counts and finding specific missing IDs using set difference between PostgreSQL and MongoDB. (2) KEY MECHANISM: `psql COUNT(*)` vs `countDocuments()` reveals the count discrepancy (2,438 missing records); the diff command finds the exact PostgreSQL IDs that have no corresponding MongoDB document. (3) WHY IT MATTERS: 2,438 missing records means customers whose orders fall in those IDs receive errors when viewing their order history in the new system; this is a P1 production issue post-cutover. (4) WHAT BREAKS: sorting 4.5 million IDs in-process (writing to /tmp files) is memory-intensive; for very large datasets, use streaming cursor-based comparison instead of loading all IDs into memory. (5) TAKEAWAY: run automated reconciliation before every migration cutover; never cut over until reconciliation reports 100% parity; 99.9% parity means thousands of missing records in a large dataset.

Fix: run the migration script for missing IDs only (filtered re-run); ensure the script
is idempotent (upsert, not insert) so re-running does not create duplicates.

**Failure Mode 2: MongoDB write amplification during dual-write causing PostgreSQL latency.**

Symptom: after enabling dual-write, PostgreSQL write latency increases from 5ms to
50ms; MongoDB write latency is 45ms due to replica set acknowledgment.
Root cause: the dual-write shim waits for MongoDB acknowledgment synchronously on the
request path; PostgreSQL write latency is now P90-of-max(PostgreSQL, MongoDB).

Diagnosis:

```bash
# Check application latency traces for order creation
# (requires distributed tracing: Jaeger, Datadog APM, etc.)
# Look for: postgres_write + mongodb_write in the same trace span

# Check MongoDB write concern level
# w:1 = acknowledge from primary only (~5ms)
# w:"majority" = acknowledge from majority replica set (~45ms)
# w:0 = fire-and-forget (0ms acknowledgment, no durability)

# In MongoDB shell:
mongosh --eval "db.orders.getWriteConcern()"
# {w: 'majority', wtimeout: 0} <- majority ack causes latency!
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnosing dual-write latency regression caused by MongoDB's write concern setting - `w:"majority"` requires acknowledgment from the majority of replica set members, adding 45ms to every order creation. (2) KEY MECHANISM: during dual-write, the application writes to PostgreSQL and MongoDB sequentially; if MongoDB write concern is `majority` (which is the safe default), the application waits for replica set consensus; this adds inter-node latency to every write. (3) WHY IT MATTERS: the write latency regression affects all API calls that create orders; user-visible impact is 10x slower order placement (5ms to 50ms). (4) WHAT BREAKS: reducing write concern to `w:1` or `w:0` for the shadow write reduces durability; `w:0` means MongoDB acknowledges before writing to disk; if MongoDB crashes after acknowledgment, the write is lost; acceptable for a shadow write (PostgreSQL is the source of truth), not for production use. (5) TAKEAWAY: for shadow writes during dual-write migration, use `w:0` (fire-and-forget); this eliminates latency impact from MongoDB; missing writes are detected by reconciliation and backfilled; durability is not required for the shadow database.

Fix: change dual-write MongoDB write concern to `w:0` (fire-and-forget);
validate missing writes via reconciliation; accept that shadow writes may be lost
(PostgreSQL is the source of truth during dual-write phase).

---

### ⚖️ Comparison Table

| Migration Pattern | Risk | Downtime | Rollback | Best For |
|---|---|---|---|---|
| Big Bang (stop-the-world) | Highest | Hours/days | Difficult | Small datasets, maintenance window allowed |
| Dual Write + Cutover | Medium | Zero | Easy (feature flag) | Production systems, large datasets |
| Strangler Fig (gradual) | Low | Zero | Very easy | Microservices, incremental migration |
| CDC-based sync | Low | Zero | Easy | When CDC pipeline already exists |

---

### 🏛️ System Design

**Zero-Downtime Migration: PostgreSQL Orders to MongoDB:**

Timeline overview for a 50 GB orders database with 100K writes/day:

Phase 1 (Week 1-2): Schema design and testing.
- Map all application queries to MongoDB documents.
- Create MongoDB schema with appropriate indexes.
- Load test MongoDB with 10x production volume.
- Validate read latency meets SLO.

Phase 2 (Week 3): Dual-write deployment.

```bash
# Feature flag to enable dual-write
# flags.yml:
# dual_write_orders: true
# mongo_orders_read_enabled: false

# Deploy application with dual-write disabled
# Enable dual-write via flag (no deployment needed)
curl -X POST flags/dual_write_orders \
  -d '{"enabled": true, "rollout_percentage": 100}'
```

> **Code walkthrough:** (1) WHAT IT SHOWS: enabling the dual-write feature flag remotely without a deployment, allowing instant rollback by flipping the flag. (2) KEY MECHANISM: feature flags decouple deployment from feature activation; the dual-write code is deployed to all instances simultaneously; enabling the flag activates it without downtime or rolling deploy. (3) WHY IT MATTERS: if dual-write causes unexpected PostgreSQL latency (as in Failure Mode 2 above), the flag can be turned off instantly, reverting to single-write PostgreSQL; no redeployment required. (4) WHAT BREAKS: feature flag systems have consistency windows (flags are cached per-instance for N seconds); during the flag propagation window, some instances may write to MongoDB while others do not; this creates a brief period of partial dual-write that reconciliation will catch. (5) TAKEAWAY: use feature flags for all migration control points; never hardcode migration state in the application code; the flag is the migration control plane.

Phase 3 (Week 4-5): Bulk data backfill.
- Run migration script during low-traffic hours.
- Process in 10,000-record batches.
- Monitor reconciliation dashboard for parity progress.
- Target: 100% parity before cutover.

Phase 4 (Week 6): Read cutover (1% -> 10% -> 50% -> 100% over 3 days).

Phase 5 (Week 7-12): PostgreSQL in read-only mode (rollback window).

Phase 6 (Week 12+): PostgreSQL decommission.

---

### 📊 Diagram

```text
MIGRATION RISK VS SPEED TRADE-OFF:

  HIGH RISK
  ^
  |  Big Bang          <- Stop, migrate, start
  |  (hours/days)         High risk, fast
  |
  |  Blue-Green        <- New DB deployed alongside
  |  Migration            old; instant cutover
  |                       Medium risk, medium speed
  |
  |  Dual Write        <- Both DBs live; gradual
  |  + Feature Flag       Low risk, slower
  |
  |  Strangler Fig     <- Incremental service migration
  |  (months)             Very low risk, very slow
  |
  LOW RISK
  +----------------------------> TIME

  DUAL WRITE DECISION MATRIX:
  Dataset < 10 GB  AND maintenance window available
    -> Big Bang (fastest, acceptable risk)
  Dataset 10-500 GB, production system
    -> Dual Write + Feature Flag (recommended)
  Dataset > 500 GB, microservices
    -> Strangler Fig (service-by-service migration)
  Existing CDC pipeline
    -> CDC-based sync (lowest operational overhead)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the migration risk-speed trade-off space
> with four strategies positioned by risk level and time required, plus a decision matrix
> for choosing the appropriate strategy. (2) HOW TO READ IT: the y-axis is risk (high at
> top); the x-axis is time (fast on left); each strategy occupies a position based on its
> risk and duration; lower-right is the ideal (low risk, fast) but is not achievable;
> all strategies involve trade-offs. (3) KEY RELATIONSHIP: time and risk are inversely
> related; faster migrations require more downtime or more risk; slower migrations reduce
> risk through validation at each step. (4) EDGE CASE: Blue-Green deployment for databases
> is more complex than for stateless services; the "blue" (old) database must stay in sync
> with the "green" (new) during the transition; this requires dual-write or CDC, which adds
> the complexity of both Blue-Green and dual-write simultaneously. (5) INSIGHT: a senior
> engineer matches the migration strategy to the dataset size, availability requirement,
> and team capacity; choosing Dual Write for a 1 GB dataset is over-engineering; choosing
> Big Bang for a 1 TB production database is reckless.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | migration phases, schema transformation |
| Mechanism | 2 | dual-write, idempotency |
| Debugging | 2 | data loss diagnosis, latency regression |
| Trade-off | 3 | migration strategies, NoSQL schema design, consistency |
| Application | 2 | Cassandra migration, backfill at scale |
| Scenario | 1 | production migration incident |

---

**[SENIOR] Q1 (Definition): What are the phases of a relational-to-NoSQL migration and what are the key risks in each phase?**

A production relational-to-NoSQL migration has six phases:

Phase 1 - Schema analysis and NoSQL data model design:
- Audit all queries the application runs against the relational database.
- For each query pattern, design the optimal NoSQL document or table structure.
- Risk: incomplete query audit; discovering unexpected access patterns after migration
  requires schema redesign and re-migration.
- Mitigation: enable PostgreSQL query logging for 2 weeks; analyze `pg_stat_statements`
  for all query patterns; involve the entire application team in the schema review.

Phase 2 - New database provisioning and indexing:
- Deploy the NoSQL cluster; configure replication, backups, and monitoring.
- Create collections/tables with appropriate indexes.
- Risk: insufficient capacity planning; NoSQL cluster undersized for production volume.
- Mitigation: load test with 2x anticipated production volume before proceeding.

Phase 3 - Data backfill (historical data migration):
- Export from relational database, transform, import to NoSQL.
- Risk: transformation bugs causing data loss or corruption.
- Mitigation: implement idempotent migration scripts; run reconciliation after each batch.

Phase 4 - Dual-write deployment:
- Application writes to both databases simultaneously.
- Risk: MongoDB write failures causing application errors or latency regression.
- Mitigation: shadow writes are best-effort (errors logged, not propagated); write
  concern `w:0` for shadow writes; monitor retry queue.

Phase 5 - Gradual read cutover:
- Feature flag controls percentage of reads to NoSQL database.
- Risk: subtle query result differences cause application behavior changes.
- Mitigation: compare NoSQL vs relational responses for a sample of reads (shadow reads);
  alert on any differences before increasing cutover percentage.

Phase 6 - Decommission:
- Relational database set to read-only; then archived.
- Risk: unexpected application component still reading from the relational database.
- Mitigation: monitor relational database connection count and query count during decommission
  period; any traffic indicates an application component that was not migrated.

*What separates good from great:* The "strangler fig" migration as an alternative to
migrating the entire database. Instead of migrating all services at once, migrate
service by service. Start with the service whose data model most naturally fits the
target NoSQL database. Migrate only that service's data and queries; leave all other
services on PostgreSQL. The strangler fig approach reduces risk by limiting migration
scope; failures affect only one service, not the entire application.

---

**[SENIOR] Q2 (Mechanism): How do you design an idempotent data migration for a 100M record PostgreSQL table to Cassandra?**

Idempotency requirements: the migration script must produce the same result whether
run once or multiple times; no duplicate records, no missing records, correct data.

Idempotency mechanisms for Cassandra:

1. Upsert semantics (Cassandra's INSERT is an upsert):
Cassandra's `INSERT INTO` is inherently an upsert: if a row with the same primary key
exists, it is updated with the new values. This means re-running an INSERT for a row
that was already migrated simply overwrites it with the same data - idempotent.

2. Checkpoint-based resumption:

```python
import cassandra.cluster
import psycopg2

def migrate_users_idempotent(
    pg_conn,
    cass_session,
    checkpoint_file: str = "migration_checkpoint.txt"
):
    """
    Migrates users from PostgreSQL to Cassandra.
    Resumes from last checkpoint on restart.
    """
    # Read checkpoint (last successfully migrated user_id)
    last_id = 0
    try:
        with open(checkpoint_file) as f:
            last_id = int(f.read().strip())
        print(f"Resuming from user_id > {last_id}")
    except FileNotFoundError:
        print("Starting fresh migration")

    cursor = pg_conn.cursor()
    cursor.execute("""
        SELECT id, email, created_at
        FROM users
        WHERE id > %s
        ORDER BY id
    """, (last_id,))

    insert_stmt = cass_session.prepare("""
        INSERT INTO users (id, email, created_at)
        VALUES (?, ?, ?)
    """)

    batch_count = 0
    for row in cursor:
        user_id, email, created_at = row
        cass_session.execute(insert_stmt,
                             (user_id, email, created_at))

        batch_count += 1
        if batch_count % 10_000 == 0:
            # Checkpoint every 10,000 records
            with open(checkpoint_file, 'w') as f:
                f.write(str(user_id))
            print(f"Checkpoint: {user_id} ({batch_count})")

    print(f"Migration complete: {batch_count} users")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a checkpoint-based migration script for Cassandra that can resume from the last successfully written user_id if interrupted, and uses Cassandra's upsert semantics for idempotency. (2) KEY MECHANISM: the checkpoint file stores the last successfully written `user_id`; on restart, the PostgreSQL query uses `WHERE id > last_id` to skip already-migrated records; checkpointing every 10,000 records limits re-processing to at most 10,000 records on restart. (3) WHY IT MATTERS: a 100M record migration at 50,000 records/second takes 33 minutes; if it fails at record 95M (30 minutes in), a non-resumable script would require re-running all 95M records; the checkpoint reduces restart overhead to < 1 minute. (4) WHAT BREAKS: storing the checkpoint in a file is fragile; if the migration runs on multiple machines, file-based checkpoints are not shared; use a PostgreSQL table as the checkpoint store for multi-node migrations. (5) TAKEAWAY: every large data migration script must implement checkpoint-based resumption; a 100M record migration that cannot resume is not production-ready; checkpointing at 10K-100K records balances overhead and granularity.

*What separates good from great:* The parallel migration for 100M records. A single-
threaded migration at 50,000 records/second takes 33 minutes. With 10 parallel workers
partitioned by `user_id % 10`, each worker handles 10M records, completing in 3.3 minutes.
Partition the migration by primary key range or by modulo:

```python
# Parallel migration with 10 workers
# Worker 0: user_id % 10 = 0
# Worker 1: user_id % 10 = 1
# ...etc
cursor.execute("""
    SELECT id, email, created_at
    FROM users
    WHERE id > %s AND id %% %s = %s
    ORDER BY id
""", (last_id, total_workers, worker_id))
```

> **Code walkthrough:** (1) WHAT IT SHOWS: partitioning the migration query by `id % total_workers` to enable parallel migration across multiple worker processes. (2) KEY MECHANISM: each worker handles a disjoint subset of records (no overlap); `id %% total_workers = worker_id` selects 1/N of all records; workers run in parallel, each with its own checkpoint file. (3) WHY IT MATTERS: parallel migration reduces wall-clock time linearly with worker count (up to Cassandra write throughput limits); 10 workers = 10x faster migration. (4) WHAT BREAKS: the modulo partitioning assumes IDs are uniformly distributed; if IDs are sequential with gaps, some workers handle more records than others; use range partitioning for truly even distribution. (5) TAKEAWAY: design migrations for parallelism from the start; the checkpoint + parallel worker pattern is the production standard for large-scale data migrations.

---

**[SENIOR] Q3 (Trade-off): What are the pros and cons of using MongoDB vs DynamoDB for migrating a PostgreSQL user profiles table?**

Context: a `users` table with 50M records, primarily accessed by user_id (exact lookup)
and email (exact lookup), with occasional updates to profile fields.

MongoDB evaluation:
- Schema flexibility: add new profile fields without schema migrations; MongoDB handles
  heterogeneous documents (different fields per user based on account type).
- Query flexibility: any field can be queried with an index; ad-hoc queries supported.
- Aggregations: MongoDB Aggregation Pipeline can replace many SQL analytics queries.
- Self-managed: requires cluster provisioning, backup management, monitoring setup.
- Multi-document transactions: MongoDB 4.0+ supports ACID transactions across documents
  (at higher latency cost).
- Indexes: secondary indexes on `email`, `phone`, or any field are supported.
- Migration cost: schema can be designed to match existing PostgreSQL structure with
  minimal transformation.

DynamoDB evaluation:
- Fully managed: no operational overhead; AWS handles backups, replication, scaling.
- Auto-scaling: handles traffic spikes without capacity planning.
- Cost model: pay per request; unpredictable costs at scale; potentially expensive for
  high-read workloads.
- Query limitations: primary access pattern must be defined at table creation (partition
  key + sort key); secondary access patterns require GSIs (Global Secondary Indexes),
  which have higher cost and consistency lag.
- Schema rigidity: adding a new primary access pattern requires a new GSI; DynamoDB
  is NOT as flexible as MongoDB for ad-hoc queries.
- No complex aggregations: DynamoDB has no aggregation framework; analytics require
  exporting to S3 + Athena or another system.

Decision matrix:

Choose MongoDB when:
- Multiple secondary access patterns are needed (query by email, phone, region).
- The team needs aggregation capabilities.
- Schema flexibility is required (different user types with different fields).
- The team has MongoDB expertise and can manage a cluster.

Choose DynamoDB when:
- The team uses AWS and wants zero operational overhead.
- The primary access pattern is by user_id (exact lookup) - DynamoDB's optimal use case.
- Cost predictability is less important than operational simplicity.
- The scale is very large (billions of users) and DynamoDB's auto-scaling is preferred.

*What separates good from great:* The DynamoDB access pattern commitment. DynamoDB
requires specifying the partition key and sort key at table creation time; these cannot
be changed later. If the application later needs a new primary access pattern (e.g.,
querying users by company_id), a GSI must be created (additional cost, eventual
consistency for GSI reads). MongoDB's flexible indexing allows adding new access patterns
without pre-planning. For a user profiles use case where access patterns may evolve,
MongoDB's flexibility reduces the risk of a painful DynamoDB access pattern migration
later.

---

**[SENIOR] Q4 (Debugging): A team migrated their PostgreSQL orders database to MongoDB 3 months ago. Users are now reporting "missing orders" that they can see in the old PostgreSQL backup. What caused this?**

Root cause analysis (most likely candidates):

Candidate 1 - Non-idempotent migration script skipped records:
If the migration script used `insert_one` (not upsert) and crashed mid-migration, some
records were not migrated. Re-running without cleanup created duplicate key errors for
already-migrated records, masking the fact that some records between the crash point
and restart point were skipped.

Candidate 2 - Dual-write MongoDB failures not retried:
During the dual-write phase, MongoDB write failures were caught and logged but not retried.
The retry queue was not monitored. Over 3 months, thousands of failed writes accumulated
in the retry queue (or were discarded if the queue had a max size); those orders were
never written to MongoDB.

Candidate 3 - Reconciliation not run before cutover:
The team cut over reads to MongoDB without running a full reconciliation to verify 100%
parity; the discrepancy existed at cutover but was not detected.

Diagnosis:

```bash
# Count discrepancy between backup and current MongoDB
psql -U postgres -f pg_backup.sql -h backup_db
psql -U postgres -c "SELECT COUNT(*) FROM orders" backup_db
# 4,523,891

mongosh --eval "db.orders.countDocuments({})"
# 4,512,834  <- 11,057 missing orders (problem confirmed)

# Find the time range of missing orders
psql -U postgres -c "
  SELECT MIN(created_at), MAX(created_at)
  FROM orders
  WHERE id NOT IN (
    SELECT CAST(order_id AS BIGINT)
    FROM mongo_order_ids  -- need to export from MongoDB
  )
"
# Could reveal: missing orders from specific time range
# (suggests crash during migration or dual-write period)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnosing missing orders by comparing record counts between the PostgreSQL backup and MongoDB, then finding the time range of missing records to identify when the gap occurred. (2) KEY MECHANISM: count comparison immediately confirms the 11,057 missing records; the time range query identifies whether the missing records are from the initial migration (all historical) or from the dual-write period (recent); this determines the root cause. (3) WHY IT MATTERS: the time range of missing records is the key diagnostic insight; missing records from before the migration start date = migration script bug; missing records from after the dual-write phase started = dual-write retry queue failure. (4) WHAT BREAKS: the subquery approach (`NOT IN` with millions of MongoDB IDs) is extremely slow; use a set difference approach (export all IDs to files and use `comm` or Python set operations). (5) TAKEAWAY: this incident confirms the mandatory pre-cutover reconciliation requirement; 11,057 missing orders affecting real customers could have been caught and fixed before cutover with a 30-minute reconciliation job.

Fix: backfill missing orders from PostgreSQL backup using the order IDs identified in
the reconciliation; implement monitoring to detect future discrepancies before users
notice.

*What separates good from great:* The compliance implication. For an orders database,
11,057 missing orders may represent regulatory compliance violations (PCI DSS, SOX
for financial services). The incident investigation must determine: were any of the
missing orders for completed transactions? If so, the accounting ledger may be
inconsistent with the database. The migration incident requires not just a technical
fix but a compliance review to determine if any reporting obligations were affected.
This is why production database migrations require a compliance review before
cutover, not just a technical review.

---

**[SENIOR] Q5 (Trade-off): Should you migrate from PostgreSQL to Cassandra for a user activity feed that has 10K writes/second?**

Analysis framework: measure first, then decide.

Current state - Measure PostgreSQL write latency:

```sql
-- Check current write throughput and latency
SELECT schemaname, relname,
  n_tup_ins as inserts,
  n_tup_upd as updates,
  n_tup_del as deletes
FROM pg_stat_user_tables
WHERE relname = 'user_activity';

-- Check for write contention
SELECT wait_event_type, wait_event, count(*)
FROM pg_stat_activity
WHERE state = 'active'
GROUP BY wait_event_type, wait_event
ORDER BY count DESC;
```

> **Code walkthrough:** (1) WHAT IT SHOWS: querying PostgreSQL's own statistics tables to measure actual write throughput and identify any write contention before deciding to migrate. (2) KEY MECHANISM: `pg_stat_user_tables` shows cumulative insert/update/delete counts for each table; comparing counts over time reveals the current write rate; `pg_stat_activity` with `wait_event` shows if writes are blocked on locks or I/O, which indicates a genuine bottleneck. (3) WHY IT MATTERS: 10K writes/second is within PostgreSQL's capacity with correct configuration (WAL tuning, partitioning, proper hardware); measuring whether PostgreSQL is actually bottlenecked prevents an unnecessary migration. (4) WHAT BREAKS: `pg_stat_user_tables` shows cumulative counts since the last stats reset; to get the current rate, sample the counter twice with a 1-second interval and compute the difference. (5) TAKEAWAY: always measure the current system before proposing a migration; the question is not "can Cassandra handle 10K writes/second?" (yes, easily) but "is PostgreSQL failing to handle 10K writes/second for THIS specific use case?" (often not).

10K writes/second assessment:
- PostgreSQL with WAL-E, SSD, and proper connection pooling handles 50,000-100,000
  simple INSERTs/second on modern hardware.
- 10K writes/second is well within PostgreSQL's range IF: (1) the writes are not
  contending on locks, (2) the hardware has SSD storage, (3) connection pooling
  is configured (PgBouncer).
- Only migrate to Cassandra if: (1) PostgreSQL is provably bottlenecked on writes,
  (2) the feed table has unbounded growth (no TTL), (3) the data must be distributed
  across multiple geographic regions.

When Cassandra IS the right choice:
- 10K writes/second is a current baseline, and growth is projected to 500K-1M writes/
  second in 12 months.
- The feed data must be geographically distributed (multi-region Cassandra replication).
- Time-based TTL data cleanup is needed (TWCS eliminates tombstone accumulation).

*What separates good from great:* The PostgreSQL table partitioning alternative.
Before migrating to Cassandra, evaluate PostgreSQL range partitioning by date. A
`user_activity` table partitioned monthly (12 partitions per year) with each partition
stored separately allows dropping old partitions instantly (`DROP TABLE user_activity_2024_01`)
instead of DELETE-based cleanup. Partition pruning makes queries that filter by date
100x faster by scanning only relevant partitions. Partitioned PostgreSQL can handle
100K+ writes/second with correct tuning. Cassandra is rarely necessary below 1M
writes/second with modern PostgreSQL and proper schema design.

---

**[SENIOR] Q6 (Application): How do you validate that a MongoDB collection is fully consistent with the PostgreSQL table it was migrated from?**

Three-level validation approach:

Level 1 - Count validation (fast, coarse):

```python
pg_count = pg_cursor.execute(
    "SELECT COUNT(*) FROM orders"
).fetchone()[0]
mongo_count = db.orders.count_documents({})

if pg_count != mongo_count:
    print(f"COUNT MISMATCH: PG={pg_count} "
          f"Mongo={mongo_count} "
          f"diff={pg_count - mongo_count}")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the first and fastest validation step - comparing total record counts between PostgreSQL and MongoDB. (2) KEY MECHANISM: count comparison is O(1) (using index statistics); any discrepancy immediately confirms data loss or duplication. (3) WHY IT MATTERS: a count discrepancy fails the migration; no need to proceed to deeper validation until counts match. (4) WHAT BREAKS: `count_documents({})` without a filter performs a full collection scan in older MongoDB versions; in MongoDB 4.0+, `estimatedDocumentCount()` is faster (uses metadata) but may be inaccurate after a crash; use `count_documents({})` for authoritative counts. (5) TAKEAWAY: count validation takes seconds; run it after every batch of backfill records; alert immediately on any discrepancy.

Level 2 - Primary key coverage (medium depth):

```python
# Export all primary keys from both systems
pg_ids = set(row[0] for row in pg_cursor.execute(
    "SELECT id FROM orders ORDER BY id"
))
mongo_ids = set(doc["_id"]
    for doc in db.orders.find({}, {"_id": 1}))

missing = pg_ids - mongo_ids
extra   = mongo_ids - pg_ids
if missing or extra:
    print(f"Missing from Mongo: {len(missing)}")
    print(f"Extra in Mongo: {len(extra)}")
    print(f"Sample missing: {list(missing)[:10]}")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: comparing all primary keys between PostgreSQL and MongoDB to find specific missing or extra records. (2) KEY MECHANISM: Python set operations `pg_ids - mongo_ids` finds records in PostgreSQL but not in MongoDB (missing); `mongo_ids - pg_ids` finds records in MongoDB but not in PostgreSQL (orphaned); both are correctness violations. (3) WHY IT MATTERS: count validation can show 100% match even with data corruption (a deleted record replaced by a duplicate); primary key coverage catches net-zero data loss (delete + duplicate). (4) WHAT BREAKS: loading all primary keys into Python memory requires RAM proportional to the number of records; for 100M records at 8 bytes per UUID, this is 800 MB; use database-side set operations for very large datasets. (5) TAKEAWAY: primary key coverage validation at 50M records takes ~2 minutes using Python sets; build this into the migration runbook as a required step before Phase 5 (read cutover).

Level 3 - Field-level checksum (deep validation, sample-based):

```python
import hashlib

def compute_row_checksum(row: dict) -> str:
    # Canonical JSON for consistent hashing
    canonical = json.dumps(row, sort_keys=True,
                           default=str)
    return hashlib.md5(
        canonical.encode()
    ).hexdigest()

# Sample 10,000 records and compare checksums
for order_id in random.sample(list(pg_ids), 10_000):
    pg_row = pg_cursor.execute(
        "SELECT * FROM orders WHERE id = %s",
        (order_id,)
    ).fetchone()
    mongo_doc = db.orders.find_one({"_id": str(order_id)})

    pg_checksum = compute_row_checksum(
        transform_to_document(pg_row)
    )
    mongo_checksum = compute_row_checksum(mongo_doc)

    if pg_checksum != mongo_checksum:
        print(f"CHECKSUM MISMATCH: order_id={order_id}")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: field-level validation using MD5 checksums of canonical JSON representations for a sample of 10,000 records to detect data corruption. (2) KEY MECHANISM: `json.dumps(sort_keys=True, default=str)` produces canonical JSON (consistent key ordering, serialized non-JSON types like dates); the MD5 checksum of the canonical JSON detects any field-level difference. (3) WHY IT MATTERS: a record may have the correct primary key but corrupted field values (truncated strings, incorrect date conversion, null fields); count and key coverage validations miss these; checksum comparison catches them. (4) WHAT BREAKS: checksum comparison requires the transformation function applied during migration to be deterministic; non-deterministic transformations (e.g., including a migration timestamp) cause checksum mismatches even for correctly migrated records. (5) TAKEAWAY: run field-level checksum validation on a 10,000-record sample before each read cutover phase increase; address all mismatches before proceeding to 100% traffic.

*What separates good from great:* The continuous reconciliation approach. Instead of a
one-time pre-cutover reconciliation, implement a daily reconciliation job that runs
forever (even in production). It compares a random sample of records between PostgreSQL
(source of truth) and MongoDB; any discrepancy triggers a page. This catches issues
introduced by post-migration application bugs (a new code path that writes to MongoDB
incorrectly), not just migration-time bugs. Continuous reconciliation is the production
standard for polyglot systems; it provides ongoing confidence that derived stores
are consistent with the source of truth.

---

**[STAFF] Q7 (Mechanism): Explain the Strangler Fig pattern for migrating a monolithic PostgreSQL-backed application to a microservices architecture with NoSQL databases.**

The Strangler Fig pattern (Martin Fowler) incrementally replaces a monolithic application
by routing new features through a new system, gradually moving existing functionality,
until the old system can be retired.

Application to database migration:

Start state: monolithic application using PostgreSQL for everything.

Step 1 - Identify bounded contexts:
Analyze the monolith's domain model. Identify areas with cohesive data (user profiles,
orders, notifications, analytics). Each bounded context is a candidate for a separate
microservice with its own database.

Step 2 - Extract the first context (lowest risk, clearest boundaries):

```text
STRANGLER FIG MIGRATION (Orders example):

  Before:
  Monolith -> PostgreSQL (orders + users + products)

  During:
  Monolith -> PostgreSQL (still reads/writes orders here)
              |
              +-> ALSO writes to Order Service
                  Order Service -> MongoDB (orders only)

  Traffic routing:
  API Gateway:
  GET /orders -> Monolith (reads from PostgreSQL)
  POST /orders -> Monolith AND Order Service (dual write)

  After validation:
  GET /orders -> Order Service (reads from MongoDB)
  POST /orders -> Order Service only
  Monolith no longer owns orders
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the three phases of Strangler Fig migration for the orders bounded context - before extraction, during dual-write, and after cutover. (2) HOW TO READ IT: the API Gateway is the routing control plane; during migration, the gateway duplicates writes to both the monolith and the new Order Service; once MongoDB is validated, GET routes shift to the Order Service. (3) KEY RELATIONSHIP: the API Gateway's routing rules are the migration control plane; changing a routing rule is the cutover mechanism; no application redeployment is required. (4) EDGE CASE: cross-context reads (the monolith reading orders data that is now owned by the Order Service) require a service API call instead of a direct database query; this forces proper service boundary definitions. (5) INSIGHT: the Strangler Fig pattern's key insight is that the migration never stops the existing system; the monolith continues to function throughout; the new system proves itself before traffic is shifted; rollback is always available by reverting the routing rule.

Benefits for NoSQL migration:
- Risk is limited to one bounded context at a time.
- If MongoDB is wrong for the orders use case, only orders need to be reverted.
- The remaining monolith continues to function normally.
- The team learns NoSQL operations on a non-critical context before migrating critical ones.

*What separates good from great:* The data ownership transfer protocol. When the
Order Service takes ownership of orders from the monolith, the monolith's code that
reads orders directly from PostgreSQL must be changed to call the Order Service API.
This is "foreign key removal" at the service level: the monolith's PostgreSQL database
can no longer have a `orders` table that other services query directly. Enforcing this
boundary requires: (1) removing the `orders` table from the monolith's PostgreSQL after
cutover, or (2) adding a database firewall rule that blocks the monolith's service account
from querying `orders`. Without enforcement, the monolith bypasses the service API and
reads directly from the old table, creating a hidden coupling that defeats the migration
purpose.

---

**[STAFF] Q8 (Trade-off): How does the CAP theorem change the data migration strategy when migrating to an AP database like Cassandra?**

When migrating from a CP database (PostgreSQL with synchronous replication) to an AP
database (Cassandra with eventual consistency), the consistency guarantees change
fundamentally:

Before migration (PostgreSQL):
- A read always returns the most recently committed write (SERIALIZABLE or READ COMMITTED).
- Cross-row transactions are ACID.
- Application code can rely on: "if I write X, the next read returns X."

After migration (Cassandra with eventual consistency):
- A read may return a stale version of a recently written record.
- Cassandra has no cross-partition transactions.
- Application code must handle: "a recent write may not be immediately visible."

Migration strategy implications:

1. Application code changes are required (not just data):
The application must be re-written to handle eventual consistency. This is not a
migration; it is a re-architecture. Teams that treat the migration as a data migration
without changing application code will encounter subtle correctness bugs post-migration.

2. Dual-write validation must check consistency semantics:
During dual-write, the reconciliation compares PostgreSQL (consistent reads) with
Cassandra (eventually consistent reads). The reconciliation should be run after waiting
for Cassandra convergence (10-100ms after the last write); running it immediately
after writes will show false discrepancies due to replication lag.

3. Use cases must be re-evaluated:
Any use case relying on linearizable reads (e.g., inventory count: "check if
available before reserving") must be redesigned for Cassandra. Cassandra's LWT
(Lightweight Transactions) provides compare-and-swap for single-partition operations,
but at high latency (Paxos round-trips). Most inventory use cases are incompatible
with Cassandra's eventual consistency and should remain in PostgreSQL.

*What separates good from great:* The "re-migration" risk. Migrating from PostgreSQL
to Cassandra, then discovering that the application cannot tolerate eventual consistency
for the primary use case, requires migrating BACK to PostgreSQL (or a different CP
database). This is a failure mode that affects real teams. Prevent it by: (1) explicitly
listing all consistency requirements before migration, (2) testing the application with
artificially introduced Cassandra replication lag (using `nodetool setstreamthroughput
1` to slow replication), and (3) signing off from the product team that eventual
consistency is acceptable. A signed-off consistency requirement prevents the expensive
re-migration.

---

**[STAFF] Q9 (Application): Design a migration plan for moving a 10 TB PostgreSQL analytics database to Apache Cassandra. What challenges are unique to this scale?**

Scale-specific challenges at 10 TB:

Challenge 1 - Migration throughput: at 100 MB/s migration bandwidth, migrating
10 TB takes 28 hours. Single-threaded Python migration scripts are insufficient.
Solution: parallel migration with 20-50 workers; use Apache Spark for distributed
transformation; use Cassandra bulk loader (`cassandra-loader` or DSBulk) for maximum
ingest throughput.

Challenge 2 - Schema transformation at scale: PostgreSQL aggregate functions (GROUP BY,
SUM, COUNT) produce the normalized form; transforming to Cassandra's denormalized model
requires running aggregations on PostgreSQL during migration. For a 10 TB database,
these aggregations take hours.
Solution: pre-compute aggregated views in PostgreSQL (`CREATE MATERIALIZED VIEW`)
before migration starts; migrate from the materialized view, not the raw tables.

Challenge 3 - Network bandwidth: at 10 TB, the migration requires moving data from
PostgreSQL to transformation nodes to Cassandra; network saturation is a risk.
Solution: co-locate the migration workers with the PostgreSQL database; run the
Cassandra cluster in the same data center; avoid cross-datacenter migration bandwidth.

Challenge 4 - Cassandra write burst: 10 TB at maximum write speed creates a sustained
write burst that may saturate Cassandra's compaction capacity.
Solution: throttle ingest to 50-70% of Cassandra's maximum write throughput; monitor
`pending_compactions`; pause ingest if compaction lag exceeds 100 tasks.

Challenge 5 - Verification at scale: comparing 10 TB of data between PostgreSQL and
Cassandra using record-by-record comparison takes days.
Solution: use checksum-based sampling (1% of records = 100 GB verification); combine
with count validation at the partition level.

*What separates good from great:* The migration tooling choice. For 10 TB migrations,
purpose-built tools outperform custom Python scripts by orders of magnitude:
- Apache Spark: reads from PostgreSQL via JDBC, transforms in-memory, writes to
  Cassandra via the spark-cassandra-connector; handles 10 TB in 2-4 hours with a 10-node
  Spark cluster.
- DataStax Bulk Loader (DSBulk): designed specifically for Cassandra; 10-100x faster
  than CQL INSERT for bulk loads; uses Cassandra's native protocol efficiently.
- Debezium (initial snapshot): for ongoing CDC after the initial bulk load, Debezium
  provides the initial snapshot feature that reads PostgreSQL consistently at a point in
  time; this is the starting point for a hybrid bulk-load + CDC migration strategy.

Choosing the right tooling reduces migration time from days to hours and reduces risk
of data loss from custom script bugs.

---

**[STAFF] Q10 (Scenario): Three months post-migration from PostgreSQL to MongoDB, the team discovers MongoDB is slower than PostgreSQL for the 3 most critical queries. What do you do?**

This is a data model failure: the MongoDB schema was not designed for the actual
query patterns.

Diagnosis - identify the slow queries:

```javascript
// Enable MongoDB profiler for slow queries
db.setProfilingLevel(1, { slowms: 50 });
// Wait 30 minutes
db.system.profile.find().sort({millis:-1}).limit(10)
// Returns: slowest queries with millis, nReturned,
//          keysExamined, docsExamined
// High docsExamined with low nReturned = missing index
// OR: accessing nested documents without index = collection scan
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using MongoDB's built-in query profiler to capture slow queries (> 50ms) and identify whether they are collection scans (missing indexes) or structural issues (wrong document design). (2) KEY MECHANISM: `setProfilingLevel(1)` captures all queries slower than `slowms`; `system.profile` contains query execution statistics including `docsExamined` (documents scanned) and `nReturned` (documents matched); a high ratio of examined to returned confirms a missing index or inefficient query pattern. (3) WHY IT MATTERS: the profiler reveals whether the performance issue is fixable (add an index) or structural (requires data model redesign). (4) WHAT BREAKS: the profiler adds overhead to all database operations; disable it in production after diagnosis with `db.setProfilingLevel(0)`. (5) TAKEAWAY: always run the MongoDB profiler before concluding that the data model is wrong; 80% of MongoDB performance issues are resolved by adding the correct index; only 20% require data model changes.

Three scenarios and responses:

Scenario A - Missing indexes (fixable in hours):
`docsExamined = 10M, nReturned = 1` for a query by `user_email`.
Fix: `db.orders.createIndex({"user.email": 1})`.
Timeline: index created in background during off-peak hours; queries fast within hours.

Scenario B - Wrong document structure (fixable in days):
The 3 critical queries all use `$lookup` (MongoDB join) because related data was not
embedded during migration.
Fix: restructure documents to embed related data; run re-migration script for the
affected fields; no downtime required (MongoDB supports live schema evolution).

Scenario C - Fundamentally wrong database choice (weeks to fix):
The 3 critical queries are complex multi-table JOIN aggregations with GROUP BY that
PostgreSQL's query optimizer handled efficiently; MongoDB has no equivalent.
Fix: add the Aggregation Pipeline for MongoDB equivalents; if aggregation is too slow,
consider: (1) pre-computed views in MongoDB (materialized computed fields), (2) migrate
the analytics queries back to PostgreSQL while keeping transactional data in MongoDB.

*What separates good from great:* The "accept the loss" option. In some cases, MongoDB
is genuinely the wrong database for the access patterns, and re-migrating back to
PostgreSQL is the correct decision. This is a failure but not a catastrophe. The correct
framing: the team validated a hypothesis (MongoDB is better for this use case) and the
validation result is "no." The cost of the failed migration is the cost of the experiment.
The correct response is to re-migrate to PostgreSQL (or to a different database that
actually fits the patterns), not to optimize forever around a fundamentally wrong
architecture. Post-mortem action: add the access pattern benchmark requirement to the
migration checklist to prevent repeat failures.

---

**[STAFF] Q11 (Mechanism): How does schema versioning work in a polyglot environment during a migration? What happens when the PostgreSQL schema changes during the dual-write period?**

Schema changes during a dual-write period are the most operationally complex part of
a database migration. The core problem: if PostgreSQL adds a column (`ALTER TABLE orders
ADD COLUMN discount_code VARCHAR(50)`) while the dual-write shim is writing to MongoDB,
the new field must be handled correctly in both systems.

Three scenarios:

Scenario 1 - Additive schema change (new column with default null):
PostgreSQL adds `discount_code VARCHAR(50) DEFAULT NULL`.
New orders have `discount_code` set; historical orders have it as null.
MongoDB impact: the transformation function must include `discount_code` in new order
documents; historical MongoDB documents do not have the field (MongoDB is schemaless -
this is fine); queries on `discount_code` must handle documents without the field
(`{discount_code: {$exists: true}}`).

Scenario 2 - Breaking schema change (column renamed):
PostgreSQL renames `amount` to `total_amount`.
This breaks the transformation function: if the code still maps `row["amount"]` to
`doc["total_amount"]`, it fails when the PostgreSQL column is renamed.
Fix: deploy the application update (including new field mapping) before the schema
change; the new code handles both old (`amount`) and new (`total_amount`) column names
during a rolling deploy.

Scenario 3 - Structural change (column moved to a different table):
PostgreSQL extracts `user_preferences` from `users` to a new `user_settings` table.
MongoDB impact: the embedded `settings` sub-document in the user collection must be
backfilled from `user_settings` table; the dual-write shim must JOIN with `user_settings`
when writing to MongoDB.

Migration protocol for schema changes during dual-write:

```text
SCHEMA CHANGE PROTOCOL:
1. Announce change 1 week in advance
2. Update transformation function to handle
   both old and new schema (backward-compatible)
3. Deploy updated application code
4. Apply PostgreSQL schema change
5. Run reconciliation to verify MongoDB updated
6. Remove backward compatibility code after 1 week
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the protocol for safely handling a PostgreSQL schema change during the dual-write migration period, with backward-compatible transformation as the key step. (2) HOW TO READ IT: the protocol proceeds in order with a 1-week advance notice window; step 2 (backward-compatible transformation) is the critical step that prevents the schema change from breaking the dual-write. (3) KEY RELATIONSHIP: the transformation function is the schema contract between PostgreSQL and MongoDB; it must be updated before the schema change is applied; never apply a breaking schema change before updating the transformation. (4) EDGE CASE: if the backward-compatible code is not removed after 1 week, it accumulates indefinitely; old transformation code for schema changes from 6 months ago creates confusion; always track backward compatibility removals in the same ticket as the schema change. (5) INSIGHT: a senior engineer treats schema changes during dual-write as the highest-risk operations of the migration; each schema change requires its own mini-migration protocol; schedule a schema freeze period immediately before the final cutover to reduce complexity.

*What separates good from great:* The schema registry for polyglot environments.
In a mature polyglot system, a schema registry (Apache Avro with Confluent Schema
Registry, or Protobuf with a custom registry) enforces compatibility rules for all
schema changes. Producers (PostgreSQL via CDC) register schemas; consumers (MongoDB
transformers) read schemas; the registry blocks backward-incompatible changes at the
schema level, not at runtime. This prevents schema-induced dual-write failures entirely.
Implementing a schema registry adds operational complexity; only justified for long-
running polyglot architectures with frequent schema changes.

---

**[STAFF] Q12 (Scenario): A team is migrating a mission-critical financial ledger database from PostgreSQL to a NoSQL database. The CTO insists on "zero data loss" and "zero downtime." Walk through the migration architecture.**

This is a constrained migration problem. The constraints (zero data loss + zero downtime)
significantly increase the migration complexity.

Assessment: the "right" answer may be not to migrate.

Financial ledger databases require:
(1) ACID transactions: `BEGIN; UPDATE accounts SET balance = balance - 100 WHERE id=1;
  UPDATE accounts SET balance = balance + 100 WHERE id=2; COMMIT;` - atomic double-entry.
(2) Linearizable reads: a read of an account balance must return the most recently
  committed value; in a distributed NoSQL database, a read may return a stale version.
(3) Audit trail: every row-level change must be logged; financial regulators require
  immutable audit logs.
(4) Constraint enforcement: account balance must not go negative; this requires a
  read-modify-write cycle with isolation.

No current NoSQL database satisfies all four requirements at financial ledger scale:
- DynamoDB: supports transactions within a transaction (but across-partition transactions
  are more complex); lacks linearizable reads in multi-region active-active.
- Cassandra: no cross-partition transactions; eventual consistency is incompatible
  with financial ledger.
- MongoDB: ACID transactions in 4.0+ but with higher latency; distributed transactions
  across shards have additional overhead.

Recommended response to CTO: do not migrate the ledger to NoSQL.

If migration is mandatory (regulatory or vendor decision):

```text
MIGRATION ARCHITECTURE FOR FINANCIAL LEDGER:

  Zero Data Loss:
  - CDC with Debezium captures every transaction
  - Kafka topic retention: 30 days (safety net)
  - Reconciliation: every 5 minutes, not daily
  - Reconcile: transaction count, total balance,
    individual balance checksums
  - ZERO CUTOVER TOLERANCE: any discrepancy = halt

  Zero Downtime:
  - Blue-green deployment at the application layer
  - API Gateway routes reads/writes to PostgreSQL (blue)
  - MongoDB (green) receives dual-writes via CDC
  - Cutover: routing rule change in API Gateway
    (<1 second, no service restart)

  Financial-Grade Consistency in MongoDB:
  - Use MongoDB multi-document ACID transactions
    for double-entry accounting
  - Enable majority read concern
    (read_concern="majority")
  - Enable majority write concern
    (write_concern=WriteConcern("majority"))
  - Validate: test read-after-write consistency
    explicitly in staging

  Rollback Protocol:
  - PostgreSQL in read-only mode for 90 days (not 30)
  - Automated reconciliation runs continuously
  - Any discrepancy: auto-rollback within 30 seconds
  - Human approval required to decommission PostgreSQL
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the zero-data-loss, zero-downtime migration architecture for a financial ledger with specific choices for each constraint. (2) HOW TO READ IT: three parallel tracks (data consistency, operational continuity, financial-grade semantics) must all be satisfied simultaneously; each track has specific implementation requirements. (3) KEY RELATIONSHIP: the reconciliation frequency (every 5 minutes) is the critical difference from a non-financial migration; any discrepancy must halt the migration immediately; financial data errors compound over time. (4) EDGE CASE: the 90-day PostgreSQL retention (vs 30 days for non-financial) provides a longer investigation window if financial discrepancies are discovered post-cutover; regulatory audits may occur weeks after the migration. (5) INSIGHT: a senior architect's most important contribution to this migration is advocating for "do not migrate the financial ledger to NoSQL" - sometimes the best architecture decision is not to change.

*What separates good from great:* The regulatory pre-approval. Financial services
companies operating under SOX, PCI DSS, or Basel III must notify regulators of material
changes to core financial systems. A database migration that changes the data storage
layer for ledger data may require regulatory pre-approval in some jurisdictions. The
architecture document must include a regulatory review step before any cutover; a
technical team that proceeds without regulatory review faces compliance risk that is
more serious than any technical risk.
