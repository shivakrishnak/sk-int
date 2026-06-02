---
layout: default
title: "NoSQL - L5 Architecture"
parent: "NoSQL"
nav_order: 13
permalink: /nosql/l5-architecture/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Polyglot Persistence Architecture](#polyglot-persistence-architecture) | ★★★ |

---

# Polyglot Persistence Architecture

---

### 🎯 Model Answer

**30 seconds:**
> Polyglot persistence means using different databases for different services or data
> types, choosing the optimal database for each data access pattern. A typical e-commerce
> system: PostgreSQL for orders and inventory (ACID, complex queries), Redis for sessions
> and caching (low-latency key-value), Elasticsearch for product search (full-text,
> facets), Cassandra for clickstream data (high-write time-series), and S3 for media
> files. The cost: each database is a separate operational burden - backup, monitoring,
> failover, and developer expertise multiplied by the number of databases chosen.

**3 minutes (Senior):**
> Polyglot persistence trade-off framework: (1) Access pattern alignment - no single
> database is optimal for all access patterns; PostgreSQL's B-tree indexes are excellent
> for range queries and joins but poor for full-text search; Elasticsearch excels at full-
> text but lacks ACID transactions; choosing the right database per pattern provides
> 10-100x better performance than forcing all patterns into one database. (2) Operational
> cost - each additional database adds monitoring, backup, failover, upgrade, and
> developer expertise costs; teams often underestimate this; start with one database
> and migrate when the pain of the wrong database is proven (not anticipated). (3) Data
> consistency across stores - synchronizing data between two databases is fundamentally
> a distributed systems problem; the Dual Write Problem: writing to DB1 and DB2 in
> sequence is not atomic; if the process crashes between writes, the stores are
> inconsistent; solutions: Change Data Capture (CDC, event-driven sync), Saga pattern
> (compensating transactions), or accepting eventual consistency. (4) Selection criteria
> per use case - use the CAP theorem and access pattern as filters; then evaluate
> operational maturity of the database for the team.

**Framework:** Identify Access Patterns -> Score Databases -> Estimate Operational Cost -> Choose Minimum Required Set

**Blank Mind Recovery:**

**(1) Restate:** "Polyglot persistence: use the best database for each job. PostgreSQL
for transactions, Redis for cache, Elasticsearch for search, Cassandra for time-series.
Problem: each database = more operations work. Consistency between databases requires
CDC or Saga. Don't add databases speculatively."

**(2) First principles:** "A database is optimized for specific access patterns. A
hash index is O(1) for exact lookup but O(N) for range queries. An LSM tree is optimal
for writes but not for complex joins. No single data structure is optimal for all
operations. Polyglot persistence acknowledges this and assigns each data type to the
database with the optimal internal structure."

**(3) Bridge:** "Polyglot persistence is like choosing the right tool from a toolbox.
A hammer is not wrong for every job - it's wrong for screws. A relational database is
not wrong - it's wrong for a 10TB clickstream that needs to be queried by time range
across millions of devices. Using the right tool reduces effort; using the wrong tool
increases effort and creates fragility."

---

### 📘 Concept Explanation

**The Access Pattern Matrix:**

```text
DATABASE SELECTION BY ACCESS PATTERN:

  Pattern: Transactional / ACID
  Examples: Orders, Payments, Inventory
  Need: Strong consistency, joins, complex queries
  Best: PostgreSQL, MySQL
  Avoid: MongoDB (limited transactions),
         Cassandra (no joins, eventual consistency)

  Pattern: Key-Value Lookup (sub-ms latency)
  Examples: Sessions, Feature Flags, Rate Limiting
  Need: <1ms reads, high throughput, TTL support
  Best: Redis, DynamoDB
  Avoid: PostgreSQL (5-10ms), Cassandra (1-2ms)

  Pattern: Full-Text Search / Faceted
  Examples: Product Search, Log Search, Autocomplete
  Need: Inverted index, relevance scoring, aggregations
  Best: Elasticsearch, OpenSearch, Apache Solr
  Avoid: PostgreSQL LIKE (no relevance scoring),
         Redis (no inverted index)

  Pattern: Time-Series (high-write, time-range queries)
  Examples: Metrics, Clickstream, IoT Sensor Data
  Need: High write throughput, time-range scans
  Best: Cassandra (TWCS), TimescaleDB, InfluxDB
  Avoid: PostgreSQL (index bloat at scale),
         MongoDB (slow range queries)

  Pattern: Graph Traversal
  Examples: Recommendations, Fraud Detection,
            Social Networks
  Need: Multi-hop traversal, relationship queries
  Best: Neo4j, Amazon Neptune
  Avoid: All relational (joins do not scale to
         6+ hops), Cassandra (no traversal)

  Pattern: Large Object / Binary Storage
  Examples: Images, Videos, Documents, Backups
  Need: Cheap storage, CDN integration, durability
  Best: S3, Google Cloud Storage, Azure Blob
  Avoid: PostgreSQL (bytea column, kills performance),
         Redis (in-memory, expensive)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a decision matrix mapping six access
> patterns to their optimal and anti-pattern database choices with specific reasoning.
> (2) HOW TO READ IT: each row represents an access pattern with examples, required
> capabilities, best-fit database, and common anti-patterns to avoid. (3) KEY RELATIONSHIP:
> the "Avoid" column is as important as the "Best" column; most polyglot persistence
> mistakes come from using a familiar database for a new access pattern where it performs
> poorly. (4) EDGE CASE: DynamoDB can serve multiple patterns (key-value, time-series)
> but requires careful partition key design for each; the access pattern must be known at
> table design time; DynamoDB's GSIs enable secondary access patterns at the cost of
> write amplification. (5) INSIGHT: a senior architect's first step is auditing all access
> patterns before choosing databases; adding a database for 5% of access patterns that
> could "acceptably" run in an existing database is not justified by the operational cost.

**The Dual Write Problem and Solutions:**

```text
DUAL WRITE PROBLEM:

  Goal: Update PostgreSQL + Elasticsearch consistently

  NAIVE DUAL WRITE (UNSAFE):
  1. Write to PostgreSQL:  SUCCESS
  2. Write to Elasticsearch: CRASH HERE
  -> PostgreSQL has product, Elasticsearch does not
  -> Search returns no results for existing products
  -> Silent inconsistency; hard to detect

  SOLUTION 1: CHANGE DATA CAPTURE (CDC)
  PostgreSQL -> Debezium -> Kafka -> Elasticsearch
        WAL log     publish   consume  index

  Write to PostgreSQL ONLY
  Debezium reads WAL (Write-Ahead Log)
  Publishes change event to Kafka
  Elasticsearch consumer reads Kafka
  Indexes the new product
  Eventual consistency: 100ms - 5 seconds
  Source of truth: PostgreSQL
  Elasticsearch is a DERIVED VIEW

  SOLUTION 2: TRANSACTIONAL OUTBOX PATTERN
  Application writes to PostgreSQL:
    - products table: new product row
    - outbox table: {event: "PRODUCT_CREATED",
                     data: {...}, status: "pending"}
  Relay process reads outbox, publishes to Elasticsearch
  On success: marks outbox row "processed"
  On failure: relay retries (at-least-once delivery)
  Deduplication in Elasticsearch consumer required
  Stronger: uses same ACID transaction; no split-brain

  SOLUTION 3: SAGA PATTERN
  For multi-step operations across services
  Compensating transactions on failure
  Complex; use only when CDC/outbox are insufficient
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Dual Write Problem and three solutions
> for synchronizing data between two databases without introducing inconsistency. (2) HOW
> TO READ IT: the top shows why naive dual write fails; the three solutions below show
> progressively more complex but more robust approaches. (3) KEY RELATIONSHIP: all three
> solutions acknowledge that only one database can be the source of truth; the other is a
> derived view; this framing simplifies consistency reasoning. (4) EDGE CASE: CDC with
> Debezium requires the PostgreSQL WAL to be retained long enough for Debezium to consume
> it; if Debezium falls behind and WAL segments are purged, CDC must restart from a
> full snapshot; WAL segment retention must be configured (`wal_keep_size` in PostgreSQL).
> (5) INSIGHT: a senior architect chooses CDC (Debezium) for most polyglot scenarios
> because it is operationally proven, handles schema changes, and is battle-tested at
> companies like LinkedIn and Airbnb; the transactional outbox is preferred when Kafka
> is not available in the stack.

---

### 💻 Code Example

```java
// BAD: Naive dual write (race condition + inconsistency risk)
@Service
public class ProductService {

    @Transactional
    public void createProduct(Product product) {
        // Write 1: persist to PostgreSQL
        productRepository.save(product);
        // COMMIT happens here (Spring @Transactional)

        // Write 2: index in Elasticsearch
        // If this fails:
        // - PostgreSQL has the product (visible to DB queries)
        // - Elasticsearch doesn't (invisible to search)
        // - NO automatic rollback of PostgreSQL write
        elasticsearchClient.index(
            i -> i.index("products")
                  .id(product.getId().toString())
                  .document(toDocument(product))
        );
        // Any exception here: data inconsistency!
        // No compensation; PostgreSQL write is committed
    }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the classic dual write anti-pattern in Spring
> - a `@Transactional` method that writes to PostgreSQL (inside the transaction) and then
> writes to Elasticsearch (outside any transaction). (2) KEY MECHANISM: `@Transactional`
> commits the PostgreSQL write at the method boundary; the Elasticsearch write happens
> after the commit; if the JVM crashes, the network is interrupted, or Elasticsearch is
> unavailable, the PostgreSQL write is committed but Elasticsearch has no record. (3) WHY
> IT MATTERS: product searches return no results for newly created products; support
> tickets accumulate ("I just created a product but I can't find it in search"); data
> reconciliation requires a full re-index scan, which is expensive. (4) WHAT BREAKS:
> this pattern is so common that most teams do not realize they are doing it wrong until
> they see search results missing recent data; the inconsistency window is the time between
> the PostgreSQL commit and the Elasticsearch index call. (5) TAKEAWAY: never write to
> a second datastore after committing to the first unless you have a compensating
> mechanism; the correct pattern is CDC or transactional outbox.

```java
// BAD: (see above - naive dual write without outbox)
// GOOD: Transactional Outbox pattern
// Atomic write to PostgreSQL (product + outbox in same tx)

@Entity
@Table(name = "outbox_events")
public class OutboxEvent {
    @Id
    private UUID id;
    private String aggregateType;  // "PRODUCT"
    private String aggregateId;    // product UUID
    private String eventType;      // "PRODUCT_CREATED"
    @Column(columnDefinition = "jsonb")
    private String payload;        // JSON of product
    private Instant createdAt;
    private boolean processed;
}

@Service
public class ProductService {

    @Transactional
    public void createProduct(Product product) {
        // Write 1: persist to PostgreSQL
        productRepository.save(product);

        // Write 2: write to outbox (SAME TRANSACTION)
        // If either fails, BOTH are rolled back
        // No inconsistency possible
        OutboxEvent event = OutboxEvent.builder()
            .id(UUID.randomUUID())
            .aggregateType("PRODUCT")
            .aggregateId(product.getId().toString())
            .eventType("PRODUCT_CREATED")
            .payload(toJson(product))
            .createdAt(Instant.now())
            .processed(false)
            .build();
        outboxRepository.save(event);
        // COMMIT: product + outbox event saved atomically
    }
}

// Separate relay: polls outbox, publishes to Elasticsearch
@Scheduled(fixedDelay = 100) // Every 100ms
@Transactional
public void relayOutboxEvents() {
    List<OutboxEvent> pending = outboxRepository
        .findByProcessedFalse(PageRequest.of(0, 100));
    for (OutboxEvent event : pending) {
        elasticsearchClient.index(/* ... */);
        event.setProcessed(true);
    }
    outboxRepository.saveAll(pending);
    // If Elasticsearch is down: relay retries next poll
    // Products in PostgreSQL; eventually indexed
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Transactional Outbox pattern - writing
> both the product and the outbox event in the same ACID transaction, then having a
> separate relay process publish the outbox event to Elasticsearch. (2) KEY MECHANISM:
> the `@Transactional` boundary encompasses both `productRepository.save(product)` and
> `outboxRepository.save(event)`; either both commit or both roll back; the relay reads
> the outbox and indexes to Elasticsearch; on failure, the relay retries until success.
> (3) WHY IT MATTERS: the product and its outbox event are atomically linked; no product
> is created without an outbox event; no outbox event exists without a committed product;
> the relay guarantees at-least-once delivery to Elasticsearch. (4) WHAT BREAKS: the relay
> must deduplicate Elasticsearch writes (set `processed = true` after successful index);
> if the relay crashes after Elasticsearch index but before marking `processed = true`,
> it retries and Elasticsearch receives a duplicate; the Elasticsearch index operation
> is idempotent if the document ID is the product ID, so duplicates are safe. (5) TAKEAWAY:
> the outbox table is the coupling point between the transactional database and the
> eventual datastore; monitor outbox event age (alert if unprocessed events are > 30
> seconds old); this indicates relay failure.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> Polyglot persistence means using different databases for different data types. For
> example: PostgreSQL for user profiles and orders (needs ACID), Redis for sessions
> (needs fast key-value), Elasticsearch for product search (needs full-text). The benefit
> is each database is optimized for its use case. The challenge is keeping data consistent
> across databases when data is duplicated. Use the Transactional Outbox or CDC pattern
> to synchronize data reliably.

---

**Senior / Staff (5+ years):**
> Polyglot persistence architecture decision framework: (1) Identify ALL access patterns
> (not just the current ones; project 18-month growth). (2) Score each database against
> each pattern (not just the primary one). (3) Estimate operational cost per database
> (who maintains backups, handles failover, performs upgrades, debugs performance?).
> (4) Compare the performance gain from the specialized database against the operational
> cost. (5) Choose the minimum set that covers all access patterns with acceptable
> performance and operational burden.
>
> When NOT to add a new database: when the existing database can handle the pattern at
> acceptable (not optimal) performance AND the operational cost of a new database exceeds
> the developer time saved by the performance improvement AND the team does not already
> have expertise with the new database.
>
> Data consistency strategy: designate one database as the "source of truth" per entity.
> All reads for consistency-critical operations use the source of truth. Other databases
> are derived views synchronized via CDC (Debezium + Kafka) or outbox pattern. Never
> treat two databases as equal peers for the same entity.

---

### ⚠️ Common Misconceptions

**Misconception 1: "More databases = more scalability."**

Additional databases introduce coordination overhead, consistency challenges, and
operational complexity that often reduce overall system reliability. A single well-tuned
PostgreSQL instance with proper indexing handles tens of thousands of queries per second.
Adding Redis for caching only improves performance if the bottleneck is database query
time, not network, application logic, or cache miss rate. Teams sometimes add databases
to appear architecturally sophisticated rather than because performance data justifies
it. The correct process: measure the bottleneck; if it is database read latency,
profile whether the query can be optimized (index added, query rewritten); if not
improvable within the existing database, then evaluate a specialized database.

**Misconception 2: "CDC (Change Data Capture) provides immediate consistency between databases."**

CDC via Debezium + Kafka provides eventual consistency with typical lag of 100ms to
5 seconds under normal load. Under high write load, Kafka consumer lag can increase
to minutes. During Debezium restarts or schema migrations, CDC pauses until the
connector re-synchronizes. Applications that read from Elasticsearch immediately after
writing to PostgreSQL (sub-second reads) will see the old state during the CDC lag
window. For applications that require a newly created entity to be immediately searchable,
CDC alone is insufficient; the application must either: (1) read from PostgreSQL for
the immediate post-creation request, (2) use a "write-through" dual write for the
initial index with CDC for subsequent updates, or (3) implement a cache-aside pattern
that caches the new entity in Redis to serve reads during the CDC lag window.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: CDC replication lag causes stale search results.**

Symptom: newly created or updated products do not appear in search for 30+ seconds;
users report searching for items they just created or edited and seeing old results
or no results.
Root cause: Elasticsearch consumer lag; Kafka consumer group falling behind the
producer (Debezium).

Diagnosis:

```bash
# Check Kafka consumer group lag for Elasticsearch consumer
kafka-consumer-groups.sh \
  --bootstrap-server kafka:9092 \
  --describe --group elasticsearch-consumer
# GROUP              TOPIC         PARTITION  LAG
# elasticsearch-consumer  products  0          45,231

# 45,231 messages behind = minutes of lag under high write load

# Check Debezium connector status
curl -s http://kafka-connect:8083/connectors/postgres-source/status \
  | python3 -m json.tool
# "state": "RUNNING" <- connector is healthy
# If "FAILED": connector needs restart

# Check PostgreSQL WAL retention
psql -U postgres -c "SELECT pg_wal_lsn_diff(
  pg_current_wal_lsn(),
  confirmed_flush_lsn) AS replication_lag_bytes
FROM pg_replication_slots WHERE slot_name = 'debezium';"
# Very large number = WAL growing faster than Debezium reads
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnosing CDC replication lag by checking Kafka consumer group lag, Debezium connector status, and PostgreSQL WAL slot backlog. (2) KEY MECHANISM: `kafka-consumer-groups.sh --describe` shows the lag (number of messages the consumer is behind the latest offset) for each partition; 45,231 messages behind at 100 messages/second = 452 seconds (7.5 minutes) of lag. (3) WHY IT MATTERS: a 7.5 minute lag means search results are 7.5 minutes out of date; user-visible staleness causes support tickets and distrust of the search feature. (4) WHAT BREAKS: increasing Kafka consumer parallelism helps only if the lag is caused by consumer processing speed (Elasticsearch indexing); if the lag is caused by PostgreSQL WAL segment rotation (WAL purged before Debezium reads it), adding consumers does not help; the WAL slot must be tuned. (5) TAKEAWAY: monitor Kafka consumer group lag as a primary CDC health metric; alert when lag > 10,000 messages (or equivalent to > 30 seconds at current write rate); this provides early warning before user-visible staleness.

Fix: increase Elasticsearch consumer parallelism; investigate slow indexing operations;
consider Read-Your-Writes pattern: after a write, direct the immediate read to
PostgreSQL, not Elasticsearch.

---

### ⚖️ Comparison Table

| Database Pattern | Strength | Weakness | Use For | Operational Cost |
|---|---|---|---|---|
| PostgreSQL | ACID, complex queries, joins | Full-text search, high-write throughput | Orders, profiles, config | Low |
| Redis | Sub-ms, TTL, pub/sub | No complex queries, in-memory only | Cache, sessions, rate limiting | Medium |
| Cassandra | High write throughput, time-series | No joins, eventual consistency | Clickstream, IoT, feeds | High |
| Elasticsearch | Full-text search, aggregations | Not a source of truth, eventual | Search, analytics, logs | High |
| DynamoDB | Managed, elastic scale | Expensive, limited query patterns | Serverless, unpredictable traffic | Low (managed) |

---

### 🏛️ System Design

**E-Commerce Polyglot Architecture:**

System components and database assignments:

```text
CLIENT -> API GATEWAY -> Microservices:

  Order Service  -> PostgreSQL  (ACID, complex joins)
  Session Service-> Redis       (sub-ms, TTL)
  Product Search -> Elasticsearch (full-text, facets)
  Analytics       -> Cassandra   (high-write, time-range)
  Media Store    -> S3           (cheap, CDN)

  SYNCHRONIZATION:
  PostgreSQL
     |
  Debezium (CDC)
     |
  Kafka
     |
  +--+---+--+
  |         |
  ES         Cassandra
  Consumer   Consumer
  (search    (analytics
   index)     events)

  CONSISTENCY BOUNDARIES:
  - Orders/Payments: PostgreSQL ONLY (source of truth)
  - Product catalog: PostgreSQL -> ES (eventual, 1-5s lag)
  - Sessions: Redis ONLY (cache; PostgreSQL for backup)
  - Analytics: Cassandra ONLY (write-only, no joins)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a complete e-commerce polyglot persistence
> architecture with database assignments per microservice and the synchronization flow
> from PostgreSQL to Elasticsearch and Cassandra via Debezium + Kafka. (2) HOW TO READ IT:
> each microservice box shows its database choice with the rationale; the bottom section
> shows the CDC synchronization pipeline that keeps derived views (ES, Cassandra) in sync
> with the source of truth (PostgreSQL). (3) KEY RELATIONSHIP: PostgreSQL is always the
> source of truth for product and order data; ES and Cassandra are derived views; this
> eliminates split-brain; when a conflict arises, PostgreSQL wins. (4) EDGE CASE: if
> Kafka is unavailable, Debezium cannot deliver CDC events; the outbox pattern (using
> the outbox table in PostgreSQL) provides durability until Kafka recovers; the relay
> process reads the outbox after Kafka recovery. (5) INSIGHT: a senior architect's first
> question when reviewing a polyglot design is: "what is the source of truth for each
> entity?" Without a clear answer, data conflicts are unresolvable; the architecture
> must designate a single authoritative store per entity.

Key design decisions:
- One Kafka topic per entity type (products, orders, events).
- Consumer groups: `elasticsearch-consumer`, `cassandra-consumer`.
- Each consumer is independently deployable; lag in one does not affect the other.
- Dead letter queue for failed consumer messages (Elasticsearch index failures due to
  mapping errors).

---

### 📊 Diagram

```text
POLYGLOT PERSISTENCE DECISION FLOW:

  Start: New Data Access Pattern
         |
  Can existing DB handle it?
  (acceptable performance, not optimal)
         |
    YES  |  NO
     |   |   |
     v   |   v
  Keep   | Is there a 10x+ performance gain
  existing|  from specialized DB?
     |   |   |
     |   |  YES  NO
     |   |   |    |
     |   v   |    v
     |  Does team  Keep
     |  have/can   existing
     |  learn it?  DB
     |   |
    YES  NO
     |    |
     v    v
  Add   Plan
  DB    training
         |
  Who owns ops?  <- Critical question!
  (backup, failover, monitoring)
         |
  Team owns: Add DB
  No owner: Don't add (yet)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a decision flowchart for evaluating
> whether to add a new database to a polyglot architecture, with operational ownership
> as the final gate. (2) HOW TO READ IT: start at the top with the new access pattern;
> follow the decision tree; only proceed to a new database if the existing database
> cannot handle the pattern at acceptable performance AND there is a 10x+ gain AND
> the team has the skills AND someone owns the operational burden. (3) KEY RELATIONSHIP:
> the "Who owns ops?" question is the most frequently skipped step; teams add databases
> without assigning operational ownership; the database fails at 2 AM and nobody knows
> how to respond. (4) EDGE CASE: "10x+ performance gain" is the threshold; a 2x gain
> does not justify a new database's operational overhead; a 100x gain (e.g., Elasticsearch
> full-text search vs PostgreSQL LIKE queries) clearly does. (5) INSIGHT: a senior
> architect treats the decision flowchart as a forcing function for honesty; when a
> team says "we should add Elasticsearch," running them through the flowchart often
> reveals that PostgreSQL `tsvector` full-text search is sufficient for their scale,
> and operational ownership has not been assigned.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | polyglot persistence definition, dual write |
| Mechanism | 2 | CDC mechanics, outbox pattern |
| Debugging | 2 | CDC lag, consistency violation diagnosis |
| Trade-off | 3 | operational cost, consistency models, database selection |
| Application | 2 | e-commerce design, microservices data ownership |
| Scenario | 1 | consistency incident response |

---

**[SENIOR] Q1 (Definition): What is polyglot persistence and when should a team adopt it?**

Polyglot persistence is the practice of using multiple, purpose-built databases within
a single application or system, where each database is chosen for its optimal fit with
a specific data access pattern, rather than using one general-purpose database for all
data.

The term was coined by Martin Fowler and Pramod Sadalage. The motivation: as applications
grow, different data requirements emerge that no single database handles optimally.
A relational database provides ACID transactions and complex joins but is not designed
for full-text search, graph traversal, or high-throughput time-series ingestion.

When to adopt polyglot persistence:

Clear criteria FOR adoption:
- A specific access pattern is creating measurable performance problems in the existing
  database that cannot be resolved with query optimization, indexing, or hardware scaling.
- The specialized database provides a quantifiable improvement (10x+ latency reduction,
  100x+ throughput increase).
- The team has or can hire operational expertise for the new database.
- The additional operational complexity is justified by business impact (faster product
  searches = higher conversion rate, measured).

Criteria AGAINST adoption:
- The existing database is not the actual bottleneck (application code, network, or
  cache miss rate is the bottleneck).
- The team is small (< 5 engineers) and cannot afford to operate multiple databases.
- The performance problem is anticipated but not yet measured (speculative optimization).
- No clear ownership exists for the new database's operational responsibilities.

*What separates good from great:* The "PostgreSQL first" principle. Many access patterns
that teams believe require a specialized database can be served by PostgreSQL with the
right extensions: `pg_trgm` for fuzzy text search, `TimescaleDB` for time-series,
`PostGIS` for geospatial queries, `pgvector` for vector similarity search. PostgreSQL
with extensions often delays the need for polyglot persistence by years. A senior
architect's default is: "can we solve this with PostgreSQL?" before evaluating a new
database. This keeps the operational footprint minimal and avoids introducing distributed
consistency problems prematurely.

---

**[SENIOR] Q2 (Mechanism): Explain Change Data Capture (CDC) with Debezium. How does it work at the database level?**

CDC captures every change (INSERT, UPDATE, DELETE) made to a database table and
publishes it as a stream of events that other systems can consume. Debezium is the
most widely deployed CDC framework, supporting PostgreSQL, MySQL, MongoDB, and others.

Debezium PostgreSQL mechanism:
1. PostgreSQL Write-Ahead Log (WAL): every change to PostgreSQL is first written to
   the WAL (a sequential log file) before being applied to the actual data pages. The
   WAL is the authoritative change log.
2. Logical Replication: PostgreSQL exposes the WAL as a stream of logical changes
   via the `pgoutput` or `wal2json` plugin. Debezium connects to PostgreSQL as a
   logical replication client.
3. Replication Slot: Debezium creates a persistent replication slot in PostgreSQL.
   The slot tracks which WAL position Debezium has consumed. PostgreSQL retains WAL
   segments until the slot confirms consumption. This prevents WAL from being deleted
   before Debezium reads it.
4. Event publishing: Debezium reads WAL changes and publishes them as JSON events
   to Kafka topics. Each event contains: operation type (c=create, u=update, d=delete),
   before and after state of the row, transaction timestamp, and LSN (Log Sequence Number).

Event structure example:

```json
{
  "op": "c",
  "ts_ms": 1705344000000,
  "before": null,
  "after": {
    "id": "abc123",
    "name": "Widget Pro",
    "price": 29.99
  },
  "source": {
    "db": "ecommerce",
    "table": "products",
    "lsn": 12345678
  }
}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Debezium CDC event format for a product INSERT captured from the PostgreSQL WAL. (2) KEY MECHANISM: `"op": "c"` indicates a CREATE (insert); `"before": null` confirms no prior state; `"after"` contains the new row data; `"lsn"` is the WAL position that allows Debezium to resume from this exact point after a restart. (3) WHY IT MATTERS: downstream consumers (Elasticsearch, Cassandra) receive this event and can update their indexes/tables accordingly; the `lsn` allows exactly-once processing semantics. (4) WHAT BREAKS: if the `after` block is missing (Debezium misconfiguration or REPLICA IDENTITY not set on the table), consumers receive incomplete events; for DELETE operations, only `before` is populated; consumers must handle null fields. (5) TAKEAWAY: set `REPLICA IDENTITY FULL` on PostgreSQL tables being monitored by Debezium; this includes the full row in both `before` and `after` for updates and deletes; without it, DELETE events only contain the primary key.

*What separates good from great:* The replication slot retention risk. The PostgreSQL
replication slot prevents WAL segments from being deleted, even if Debezium falls
behind. If Debezium is offline for an extended period (days) or crashes and cannot
reconnect, the replication slot retains ALL WAL segments since Debezium last consumed.
This can fill the PostgreSQL disk completely, causing a complete PostgreSQL outage.
Monitor `pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)` for the Debezium
slot; alert when lag exceeds 1 GB of WAL. If Debezium is offline for > 24 hours,
consider dropping and recreating the slot (accept data loss in the derived store and
re-sync from a full snapshot).

---

**[SENIOR] Q3 (Trade-off): Compare the Transactional Outbox pattern vs CDC with Debezium for synchronizing PostgreSQL and Elasticsearch. When would you choose each?**

Transactional Outbox:
- Mechanism: write to outbox table in the same ACID transaction as the primary data;
  a relay process polls the outbox and sends to the downstream store.
- Consistency: at-least-once delivery; relay retries on failure; downstream must
  deduplicate.
- Infrastructure: requires only PostgreSQL (no Kafka, no Debezium); relay is a simple
  background thread/cron.
- Latency: depends on relay polling interval (100ms-1s typical).
- Complexity: low; one additional table, one background process.
- Failure isolation: if Elasticsearch is down, unprocessed outbox rows accumulate in
  PostgreSQL; PostgreSQL continues to function; relay retries when ES recovers.
- Drawback: polling adds load to PostgreSQL; requires `NOT processed` index on outbox
  table; does not scale beyond thousands of events per second without multiple relay
  workers.

CDC with Debezium + Kafka:
- Mechanism: Debezium reads PostgreSQL WAL; publishes to Kafka; consumers read Kafka.
- Consistency: exactly-once delivery (with Kafka Transactions + idempotent producers).
- Infrastructure: requires Kafka cluster, Kafka Connect, Debezium connector; 3-5
  additional services to operate.
- Latency: 100ms typical; 1-5 seconds under high load.
- Complexity: high; multiple moving parts; requires Kafka expertise.
- Failure isolation: Kafka provides buffering; if ES is down, Kafka retains events
  until ES recovers; no PostgreSQL impact.
- Advantage: scales to millions of events per second; captures ALL changes including
  DDL (schema changes) via Debezium Schema Registry; multiple independent consumers
  (fan-out).

Choose Outbox when:
- Team does not have Kafka expertise or infrastructure.
- Event volume is < 10,000 events per second.
- Only one downstream consumer (no fan-out needed).
- Operational simplicity is a priority.

Choose CDC + Kafka when:
- Team already has Kafka in the stack.
- Multiple independent consumers need the same change stream.
- Event volume exceeds outbox relay capacity.
- Real-time audit log or event sourcing is a requirement.

*What separates good from great:* The Debezium schema evolution challenge. When a
PostgreSQL table schema changes (a column is added or removed), Debezium's Avro schema
in the Schema Registry must be updated. If the schema change is not backward-compatible
(removing a required field), existing consumers fail. Managing schema evolution across
producers and consumers is a significant operational challenge with CDC. The outbox
pattern avoids this: the outbox payload is a JSON string; the relay controls the JSON
schema; consumers decode the JSON they understand and ignore new fields. Schema evolution
in the outbox pattern is additive-only (new fields), which is naturally backward-compatible.

---

**[SENIOR] Q4 (Debugging): Users report that after editing a product, search results show the old product data for several minutes. How do you diagnose this?**

This is a CDC lag or outbox relay lag issue:

Step 1 - Determine the synchronization mechanism:

```bash
# Find which approach is being used
grep -r "debezium\|outbox\|kafka" application.yml config/
# Debezium connector found -> CDC lag
# OutboxRelayService found -> outbox polling lag
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using grep to quickly identify whether the system uses CDC (Debezium) or the Transactional Outbox pattern, which determines the diagnosis path. (2) KEY MECHANISM: the configuration files reveal the synchronization mechanism; Debezium appears in connector configuration or dependencies; the outbox relay appears as a scheduled service or job class. (3) WHY IT MATTERS: the diagnosis and fix differ completely between CDC and outbox; identifying the mechanism first avoids wasted investigation. (4) WHAT BREAKS: if neither pattern is used and the team confirms they use "dual write", the investigation reveals the root anti-pattern that needs to be fixed long-term. (5) TAKEAWAY: document the data synchronization pattern in the architecture decision record (ADR) for each microservice; this documentation allows on-call engineers to diagnose issues faster.

Step 2 - If CDC: check Kafka consumer group lag:

```bash
kafka-consumer-groups.sh \
  --bootstrap-server kafka:9092 \
  --describe --group elasticsearch-consumer
# Look for LAG column for products topic
# LAG: 0 -> immediate (inconsistency from different cause)
# LAG: 5000 -> consumer is behind by 5000 messages
# At 100 writes/sec: 5000 messages = 50 seconds lag
```

> **Code walkthrough:** (1) WHAT IT SHOWS: checking Kafka consumer group lag for the Elasticsearch consumer to quantify how far behind the consumer is relative to the latest events from Debezium. (2) KEY MECHANISM: `--describe` shows the current offset, log end offset, and lag for each partition; LAG is the difference; at 100 writes/second, 5000 messages of lag = 50 seconds of stale data in Elasticsearch. (3) WHY IT MATTERS: this directly explains the user observation (several minutes of stale data); the fix is to increase consumer parallelism or scale the Elasticsearch cluster to reduce indexing latency. (4) WHAT BREAKS: LAG of 0 with stale data indicates the issue is not Kafka lag; check Elasticsearch indexing failures (documents rejected due to mapping conflicts) or document refresh interval (`refresh_interval` in Elasticsearch defaults to 1 second). (5) TAKEAWAY: monitor Kafka consumer lag as a primary observable for CDC-based polyglot sync; a lag alert fires well before users notice stale data.

*What separates good from great:* The Elasticsearch `refresh_interval` red herring.
Even when CDC delivers updates with zero lag, Elasticsearch documents are not
immediately searchable. Elasticsearch buffers indexed documents and makes them
searchable during a "refresh" operation. The default `refresh_interval` is 1 second,
meaning indexed documents become searchable within 1 second. This is often confused
with CDC lag. To distinguish: after a product update, if the CDC consumer confirms
the event was indexed (logged), but the document is still not searchable, the cause is
the refresh interval, not CDC lag. For near-real-time requirements: `PUT /products/_settings`
`{"refresh_interval": "100ms"}`. For bulk indexing (not real-time): `{"refresh_interval":
"-1"}` (disable auto-refresh; call `POST /products/_refresh` manually after bulk loads).

---

**[SENIOR] Q5 (Trade-off): How does the CAP theorem guide database selection in a polyglot architecture?**

CAP theorem states that in a distributed system, you can guarantee at most two of three
properties: Consistency (all nodes see the same data simultaneously), Availability
(every request receives a response), Partition tolerance (the system continues operating
if network partitions occur between nodes).

Modern systems that operate in networks MUST tolerate partitions (network failures
are inevitable); therefore, the practical choice is CA (during normal operation) vs
the CP vs AP trade-off during a network partition.

CAP in polyglot database selection:

CP databases (prefer consistency over availability during partitions):
- HBase, Zookeeper, etcd, Redis Cluster (with certain configurations).
- Behavior: during partition, write operations fail (refuse to accept writes if quorum
  is unavailable).
- Use for: configuration data, leader election, distributed locks - any data where
  stale reads are worse than unavailability.

AP databases (prefer availability over consistency during partitions):
- Cassandra (configurable), CouchDB, DynamoDB (eventual consistency mode).
- Behavior: during partition, continue accepting writes; reads may return stale data;
  conflicts resolved after partition heals.
- Use for: user-generated content, caches, any data where availability is more
  important than immediate consistency.

CA databases (assume no partitions; reject partition tolerance):
- Traditional relational databases (PostgreSQL, MySQL) in single-master mode.
- Behavior: with synchronous replication, a replica failure causes write failures;
  consistent but not partition-tolerant.
- Use for: financial data, inventory, any data requiring strong consistency.

*What separates good from great:* PACELC extends CAP beyond the partition scenario.
PACELC states: If Partition, choose between Availability and Consistency; ELSE (no
partition, during normal operation), choose between Latency and Consistency. This
captures a real trade-off that CAP misses: Cassandra with `ONE` consistency has
lower latency than `QUORUM` even when no partition exists. Elasticsearch's
near-real-time refresh (1 second) is an ELSE trade-off (latency favored). PACELC is
a more complete framework for polyglot database selection than CAP alone.

---

**[SENIOR] Q6 (Application): A startup is building a social media app. They want to use PostgreSQL, Redis, Cassandra, Elasticsearch, and S3 from day 1. Advise them.**

The technical advice: DO NOT use all five databases from day 1.

Starting with 5 databases on day 1 of a startup is an architectural anti-pattern.
The reasoning:

Operational maturity: a team of 3-5 engineers cannot reliably operate 5 databases
while also building product features. Each database requires: backup and restore
procedures, failover testing, security patching, performance monitoring, query
optimization, and incident response runbooks. Five databases = 5x the operational
surface area. This kills engineering velocity.

Premature optimization: at launch, a social media app has zero users. Cassandra is
needed when there are millions of daily active users writing clickstream data. At
zero users, PostgreSQL handles all use cases, including time-series data for analytics.
The "we might need it later" argument is the enemy of shipping product.

Unknown access patterns: access patterns only become clear after real user behavior
is observed. Building five specialized data models before understanding real usage
patterns leads to data models that are well-optimized for the wrong queries.

Recommended starting point: PostgreSQL + Redis.
- PostgreSQL: profiles, posts, follows, likes (ACID, complex queries).
- Redis: sessions, feed caches, rate limiting (sub-ms).
- Migrate when: PostgreSQL shows measurable performance bottlenecks for specific
  access patterns.

Migration milestones:
- 100K MAU: evaluate Elasticsearch for post search (if PostgreSQL FTS is inadequate).
- 1M MAU: evaluate Cassandra for activity feeds (if PostgreSQL cannot keep up with writes).
- 5M MAU: evaluate S3 for media (if database BLOB storage is causing I/O issues).

*What separates good from great:* The Strangler Fig pattern for migration. When the
startup grows and genuinely needs a new database, the correct migration pattern is
Strangler Fig: implement the new access pattern in the new database for new data while
leaving existing data in PostgreSQL; gradually migrate older data in the background;
switch reads to the new database when migration is complete. This avoids a "big bang"
migration that introduces risk and requires downtime. For example: adding Elasticsearch
for product search means writing new products to both PostgreSQL and Elasticsearch
(dual write with outbox) while the existing products are batch-re-indexed into
Elasticsearch. Once re-indexing is complete, search reads switch to Elasticsearch.

---

**[STAFF] Q7 (Trade-off): How do you handle distributed transactions across multiple databases in a polyglot architecture?**

Distributed transactions are the hardest problem in polyglot persistence. Options:

Two-Phase Commit (2PC):
- Mechanism: a coordinator asks all participating databases to prepare (lock resources
  and confirm readiness), then sends commit or rollback to all.
- Consistency: ACID across all databases.
- Availability: if any participant is unavailable, the entire transaction blocks or
  aborts.
- Performance: high latency (2 round-trips across all databases); locks held during
  the prepare phase block concurrent operations.
- Use when: regulatory requirement for ACID across systems (rare, usually indicates
  architecture design problem).

Saga Pattern:
- Mechanism: a sequence of local transactions, each publishing an event; if a step
  fails, compensating transactions run in reverse order to undo the effects.
- Consistency: eventual consistency; each local transaction commits independently.
- Availability: each step can fail independently; compensating transactions handle
  partial failures.
- Types: Choreography (services react to events); Orchestration (a central saga
  orchestrator coordinates steps).
- Use for: order processing, booking workflows, any multi-step operation across services.

Recommendation: avoid distributed transactions entirely.
The most common architectural recommendation is to design the data model so that
transactions span only one database. Example: instead of a distributed transaction
between the Order service (PostgreSQL) and the Inventory service (also PostgreSQL),
check inventory BEFORE creating the order (optimistic locking), not in a distributed
transaction that locks both simultaneously.

*What separates good from great:* The idempotency key for Saga compensating transactions.
Compensating transactions in a Saga can be called multiple times if the orchestrator
retries (at-least-once delivery). Each compensating transaction must be idempotent: if
"refund payment" is called twice for the same order (due to retry), the customer should
not be refunded twice. Implement idempotency keys (a unique transaction ID) for all
compensating actions. Store the key in the database and reject duplicate calls with
the same key. This is the most commonly missed implementation detail in Saga pattern
implementations.

---

**[STAFF] Q8 (Scenario): Your team proposes adding a graph database (Neo4j) for recommendation queries. Walk through how you would evaluate this decision.**

Evaluation framework for adding a new database to a polyglot architecture:

Step 1 - Measure the current problem:

```python
# Benchmark current PostgreSQL recursive CTE query
# for "users who liked posts that user X also liked"
import time
import psycopg2

conn = psycopg2.connect("...")
cursor = conn.cursor()

start = time.time()
cursor.execute("""
    WITH liked_posts AS (
        SELECT post_id FROM likes WHERE user_id = %s
    ),
    similar_users AS (
        SELECT DISTINCT user_id FROM likes
        WHERE post_id IN (SELECT post_id FROM liked_posts)
        AND user_id != %s
        LIMIT 100
    )
    SELECT user_id FROM similar_users
""", (target_user_id, target_user_id))

results = cursor.fetchall()
elapsed = time.time() - start
print(f"PostgreSQL: {elapsed*1000:.0f}ms for {len(results)} results")
# PostgreSQL: 2,340ms for 50 results (too slow!)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: benchmarking the current PostgreSQL recursive CTE query for collaborative filtering to establish the baseline latency that justifies evaluating Neo4j. (2) KEY MECHANISM: the query performs two sequential lookups: first `likes` to find posts liked by the target user, then a second `likes` scan for users who liked the same posts; at scale, this is O(N*M) in query complexity. (3) WHY IT MATTERS: 2,340ms is too slow for a recommendation API; the benchmark establishes a quantified baseline; Neo4j must provide at least 10x improvement (< 234ms) to justify its operational cost. (4) WHAT BREAKS: this benchmark must run on production data volumes (not development data); a query that takes 50ms on 1,000 users may take 2,340ms on 1 million users; always benchmark with production-scale data. (5) TAKEAWAY: never propose a new database without first benchmarking the current solution; the benchmark quantifies the problem; without it, the decision is based on intuition, not data.

Step 2 - Benchmark the proposed solution (Neo4j):

Run the equivalent Cypher query on Neo4j with production-scale data:

```cypher
MATCH (target:User {id: $userId})-[:LIKED]->(post:Post)
      <-[:LIKED]-(similar:User)
WHERE similar.id <> $userId
RETURN similar.id, count(*) AS shared_likes
ORDER BY shared_likes DESC
LIMIT 50
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the equivalent graph traversal query in Cypher - find all users who liked the same posts as the target user. (2) KEY MECHANISM: Neo4j traverses the graph natively; each `LIKED` relationship is stored as a pointer in the graph; traversal is O(degree) not O(N); for a user with 1,000 liked posts, Neo4j checks only the neighbors of those 1,000 posts, not the full users table. (3) WHY IT MATTERS: if this query runs in 50ms on Neo4j vs 2,340ms on PostgreSQL, that is a 47x improvement; clearly justifies the operational cost. (4) WHAT BREAKS: Neo4j performance depends on graph shape; if the likes graph is extremely dense (every user is connected to every other user through popular posts), traversal becomes slow; benchmark with the actual graph topology. (5) TAKEAWAY: always benchmark both systems on production-scale data before making the decision; the Cypher query elegance is not a reason to add Neo4j; only the performance differential on real data matters.

Step 3 - Operational cost assessment:
- Who owns Neo4j operations? (backups, upgrades, monitoring, failover)
- How does data stay in sync between PostgreSQL and Neo4j?
- What is the CDC approach for syncing LIKES events from PostgreSQL to Neo4j?
- What is the Neo4j cluster cost (Enterprise license is expensive)?

Step 4 - Decision:
If Neo4j is 10x+ faster on production data AND the team has Neo4j expertise AND an
operational owner is designated AND the CDC sync is implementable: proceed.
Otherwise: optimize the PostgreSQL query (partial indexes on `likes`, connection to
specialized PostgreSQL extensions like `pg_cron` for pre-computation), or use a
PostgreSQL materialized view for the recommendation data.

*What separates good from great:* The pre-computed recommendation alternative. Graph
databases are most valuable for real-time, ad-hoc traversals. But recommendations do
not require real-time computation: pre-compute recommendations for each user every hour
and store the results in a simple key-value store (Redis: `user:{id}:recommendations`).
The pre-computation job runs against PostgreSQL; the result is cached in Redis; reads
are sub-millisecond. This eliminates the need for Neo4j entirely for most recommendation
use cases; only real-time recommendation requirements (immediate response to the current
page's content) justify the graph database overhead.

---

**[STAFF] Q9 (Mechanism): How does eventual consistency in polyglot persistence affect user-facing features? Give specific examples.**

Eventual consistency means that after a write to the source of truth, derived stores
(caches, search indexes, analytics) will converge to the same state, but not immediately.
During the convergence window, reads from derived stores return stale data.

User-facing impact examples:

Example 1 - Search results lag (Elasticsearch):
User creates a product listing. Searches for their own listing immediately after.
Product does not appear in search results.
Impact: user thinks product creation failed; submits duplicate listings.
Mitigation: after product creation, redirect to the product detail page (reads from
PostgreSQL, always consistent); show search results only for discovery; add a banner:
"Your listing will appear in search within 30 seconds."

Example 2 - Inventory count lag (cache inconsistency):
User A purchases the last item in stock. Inventory in PostgreSQL = 0.
Redis cache still shows inventory = 1 (cache TTL = 5 minutes).
User B sees inventory = 1 and adds to cart. At checkout, inventory check fails
(reads PostgreSQL): "This item is out of stock."
Impact: frustrated checkout abandonment.
Mitigation: use cache invalidation on inventory UPDATE (not TTL-only); write to Redis
`DEL inventory:item:123` in the same transaction as the PostgreSQL inventory decrement
(using the outbox pattern to ensure both happen atomically).

Example 3 - Profile update lag (multi-region Redis):
User updates their display name in US-East region (PostgreSQL + US-East Redis).
User's friend views their profile from EU-West region (reads EU-West Redis, stale).
Friend sees old display name for up to N seconds (Redis replication lag).
Impact: minor UX inconsistency; usually acceptable.
Mitigation: for critical data (security-sensitive profile fields), read directly from
PostgreSQL instead of cache; accept the latency trade-off for correctness.

*What separates good from great:* The Read-Your-Writes consistency guarantee. Many
eventual consistency issues affect only the WRITER, not other users (e.g., you cannot
see your own new post in your feed immediately). The Read-Your-Writes consistency
guarantee ensures the user who performed the write immediately sees its effects,
while other users see the eventually consistent view. Implementation: after a write,
store the write's timestamp or sequence number in the user's session. On subsequent
reads, if the user's session shows a pending write, read from the source of truth (not
the cache) until the CDC lag window closes. This solves the most common user complaint
about eventual consistency ("I just updated my profile but I still see the old data")
without requiring full synchronous consistency.

---

**[STAFF] Q10 (Application): Design the data architecture for a real-time analytics dashboard that shows user engagement metrics for 10M daily active users. What databases would you use and why?**

Requirements:
- 10M DAU generating 1 billion events per day (10K events/second average, 100K peak).
- Dashboard shows: events per minute for the last hour, total events per user per day,
  top 10 users by engagement today, and events by type for the last 7 days.

Database selection:

Ingestion layer - Cassandra:
- 10K events/second is well within Cassandra's write throughput.
- Schema: `CREATE TABLE events (user_id UUID, event_time TIMESTAMP, event_type TEXT,
  PRIMARY KEY ((user_id, date_bucket), event_time)) WITH CLUSTERING ORDER BY
  (event_time DESC)`.
- `date_bucket = current_date` prevents wide partitions by bucketing per day.
- TWCS with 24-hour windows matches the date_bucket pattern.

Pre-aggregation layer - Apache Flink (stream processor):
- Real-time: events per minute for the last 60 minutes (Flink tumbling window, 1 minute).
- Near-real-time: events per user per day (Flink session window, reset at midnight).
- Output: pre-aggregated counters to Redis for dashboard reads.

Read layer - Redis:
- Key: `metrics:events_per_minute:{minute_timestamp}`.
- Value: counter (INCR).
- TTL: 2 hours (only last hour displayed).
- Serve all dashboard reads from Redis (sub-ms latency for 10M DAU dashboard).

Historical layer - Apache Parquet on S3 + Amazon Athena:
- Raw events older than 7 days: Cassandra -> Kafka -> Parquet on S3.
- 7-day trend queries run against Athena (SQL on S3, no server to maintain).

*What separates good from great:* The lambda vs kappa architecture trade-off. Lambda
architecture uses both a real-time (speed) layer and a batch (batch) layer, merging
results for queries. Kappa architecture uses only a single stream processor (Flink)
for both real-time and historical reprocessing. For analytics dashboards, kappa is
preferred: a single Flink job handles both real-time aggregation and backfills from
Kafka topic replay. Lambda is complex (two codepaths to maintain); kappa requires
Kafka to retain events for the maximum historical query window (7 days in this case,
requiring Kafka topic retention of 7 days). The operational choice: kappa if the team
has Flink expertise and can afford Kafka storage; lambda if the team already has a
data warehouse (Snowflake, BigQuery) as the batch layer and does not want to introduce
a new stream processing system.

---

**[STAFF] Q11 (Debugging): A polyglot architecture starts showing silent data inconsistencies between PostgreSQL and Elasticsearch. Some products exist in PostgreSQL but not in Elasticsearch. How do you find and fix these inconsistencies?**

This is a CDC reliability problem: some CDC events were dropped or not consumed.

Step 1 - Quantify the inconsistency:

```python
# Reconciliation script: compare PostgreSQL vs Elasticsearch
import psycopg2
from elasticsearch import Elasticsearch

pg = psycopg2.connect("...")
es = Elasticsearch(["http://elasticsearch:9200"])

# Get all product IDs from PostgreSQL
pg.execute("SELECT id FROM products WHERE deleted_at IS NULL")
pg_ids = {row[0] for row in pg.fetchall()}

# Get all product IDs from Elasticsearch
es_ids = set()
for hit in helpers.scan(es, index="products",
                         _source=["id"], size=1000):
    es_ids.add(hit["_source"]["id"])

# Find discrepancies
missing_in_es = pg_ids - es_ids
extra_in_es   = es_ids - pg_ids

print(f"Missing in ES: {len(missing_in_es)}")
print(f"Extra in ES:   {len(extra_in_es)}")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a reconciliation script that compares all product IDs between PostgreSQL (source of truth) and Elasticsearch (derived view) to quantify the inconsistency. (2) KEY MECHANISM: fetching all IDs from both systems and computing set differences reveals the gap; `missing_in_es` are products in PostgreSQL but not in ES; `extra_in_es` are products deleted from PostgreSQL but not removed from ES (delete CDC events dropped). (3) WHY IT MATTERS: quantifying the inconsistency establishes the scope; if 100 out of 10 million products are missing, this is a minor backfill; if 100,000 are missing, there is a systemic CDC failure. (4) WHAT BREAKS: fetching all product IDs from Elasticsearch with `helpers.scan` performs a full index scan; at 10 million products, this takes minutes; schedule this reconciliation job during off-peak hours. (5) TAKEAWAY: run automated reconciliation jobs daily; publish a "consistency score" (percentage of PostgreSQL records present in ES) as a health metric; alert when it drops below 99.9%; this catches CDC issues before users notice.

Step 2 - Backfill missing products:

```python
# Re-index missing products from PostgreSQL
for product_id in missing_in_es:
    product = pg.fetchone("SELECT * FROM products WHERE id=%s",
                          (product_id,))
    es.index(index="products",
             id=str(product_id),
             document=product_to_doc(product))
    print(f"Re-indexed: {product_id}")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: re-indexing missing products by reading them from PostgreSQL (source of truth) and writing them to Elasticsearch. (2) KEY MECHANISM: each missing product is fetched from PostgreSQL and indexed to Elasticsearch; this is a direct read-write without going through CDC; the fix bypasses the CDC pipeline entirely to correct the inconsistency immediately. (3) WHY IT MATTERS: the backfill restores consistency for users who were experiencing missing search results; it is a tactical fix; the CDC root cause must be investigated separately. (4) WHAT BREAKS: if Elasticsearch is at capacity (disk full, circuit breaker open), the indexing will fail; check Elasticsearch cluster health before running the backfill. (5) TAKEAWAY: always read from the source of truth for reconciliation backfills; never use the derived store as the source of truth, even for re-indexing.

Step 3 - Root cause: check CDC dead letter queue:

```bash
# Check if CDC consumer is writing to dead letter queue
kafka-consumer-groups.sh \
  --bootstrap-server kafka:9092 \
  --describe --group elasticsearch-consumer
# Check "products.DLT" (Dead Letter Topic) for failed messages
kafka-console-consumer.sh \
  --bootstrap-server kafka:9092 \
  --topic products.DLT --from-beginning --max-messages 10
```

> **Code walkthrough:** (1) WHAT IT SHOWS: checking the Kafka Dead Letter Topic (DLT) for CDC consumer failures - messages that could not be processed and were routed to the DLT instead of being retried indefinitely. (2) KEY MECHANISM: when a Kafka consumer fails to process a message after N retries, Spring Kafka (and other frameworks) routes the message to a DLT; examining the DLT shows the exact events that caused failures and the exception messages. (3) WHY IT MATTERS: DLT messages are the direct cause of missing products in Elasticsearch; each DLT message is a CDC event that was not applied to ES; examining the exception reveals the root cause (mapping error, ES timeout, deserialization failure). (4) WHAT BREAKS: if no DLT is configured, failed messages are retried indefinitely and block the consumer; the consumer falls behind for all products, not just the failing ones; always configure DLT for Kafka consumers. (5) TAKEAWAY: configure DLT for all Kafka consumers in a polyglot architecture; add a DLT message count metric; alert when DLT receives any messages; each DLT message is a consistency violation waiting to be discovered.

*What separates good from great:* The Elasticsearch mapping exception as the most
common DLT cause. If PostgreSQL adds a column with a new data type and the Elasticsearch
index mapping does not match, the Debezium event contains a field that conflicts with
the existing Elasticsearch mapping. The consumer throws a `MapperParsingException`; the
message lands in the DLT. All subsequent products with the new column are also rejected.
Fix: update the Elasticsearch index mapping (add the new field) before applying the
PostgreSQL schema change. This requires coordinated schema migrations: update ES mapping
first, then add the PostgreSQL column. The Debezium Schema Registry helps manage this
by alerting when the source schema changes, giving downstream consumers time to update.

---

**[STAFF] Q12 (Scenario): An organization is evaluating replacing their PostgreSQL + Elasticsearch + Cassandra + Redis stack with a single database (SingleStore, YugabyteDB, or CockroachDB). Evaluate this proposal.**

The proposal: replace 4 databases with 1 "do everything" NewSQL database.

Arguments FOR the proposal:
- Eliminates the Dual Write Problem entirely (single ACID database for all writes).
- Dramatically reduces operational complexity (one cluster to manage, backup, monitor).
- SQL interface for all data access patterns (familiar to all developers).
- Distributed by design (handles sharding that PostgreSQL + Citus cannot).
- SingleStore: columnar storage for analytics in the same database as OLTP rows.

Arguments AGAINST the proposal:

Performance trade-offs:
- Sub-millisecond key-value lookups: Redis wins; no NewSQL database matches Redis's
  in-memory latency for simple key-value operations; Redis at 100,000 operations/second
  with < 0.1ms latency cannot be matched by any ACID database.
- Full-text search: Elasticsearch's inverted index with BM25 scoring; no NewSQL database
  provides comparable relevance scoring; SQL `LIKE` queries or `MATCH AGAINST` do not
  provide Elasticsearch-quality relevance.
- Time-series high throughput: Cassandra at 1 million writes/second with TWCS; NewSQL
  databases with RAFT consensus have higher write latency per operation.

Operational risk:
- Migrating from 4 production databases to 1 is a multi-year, high-risk project.
- The "single database" still requires expertise; it is just different expertise.
- During migration, both old and new systems must run; operational complexity
  temporarily doubles.

Recommendation: a nuanced evaluation per use case.
- Replace PostgreSQL + Cassandra: potentially viable if write throughput requirement
  is < 100K writes/second and TWCS-level compaction efficiency is not required.
- Replace Redis: NOT recommended; NewSQL latency for key-value reads (1-5ms) does not
  match Redis (< 0.1ms); sessions and rate limiting require sub-millisecond operations.
- Replace Elasticsearch: NOT recommended; full-text search relevance and query DSL
  are not replicated by SQL full-text search extensions; faceted search at scale
  requires Elasticsearch's distributed inverted index.

*What separates good from great:* The operational debt vs migration cost analysis.
The polyglot architecture accumulated operational debt: 4 databases to manage.
Paying this debt with a full migration to a NewSQL database has a migration cost
(2-3 years of engineering effort, risk of data loss, user-visible downtime if done
incorrectly). The analysis must compare: ongoing operational cost per year (4 databases)
vs migration cost + post-migration operational cost (1 database). For most organizations,
the migration cost exceeds the operational debt; incremental consolidation (eliminate
one database at a time when the case is clear) is preferable to a "big bang" migration
to a single NewSQL database.
