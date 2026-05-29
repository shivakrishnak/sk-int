---
layout: default
title: "System Design - L2 Data Patterns"
parent: "System Design"
grand_parent: "SK Interview"
nav_order: 4
permalink: /system-design/l2-data-patterns/
---

# System Design - L2 Data Patterns

---

# Database Sharding and Partitioning

---
id: SSD-009
title: Database Sharding and Partitioning
category: System Design
difficulty: ★★☆
interview_weight: high
asked_at: Senior/Staff
seniority: senior
tags: #sharding, #partitioning, #shard-key, #horizontal-scaling, #consistent-hashing
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Sharding horizontally partitions data across multiple databases - each shard
> holds a subset. The shard key determines which shard stores a record.
> A good shard key: evenly distributes data, minimizes cross-shard queries,
> and doesn't create hot spots. Common strategies: hash-based (even distribution,
> random access), range-based (range queries efficient, hot spots risk),
> geographic (data locality). The cost: cross-shard queries require scatter-gather,
> cross-shard transactions need distributed coordination.

**3 minutes:**
> Sharding vs partitioning: partitioning divides data within one database
> (horizontal partitioning = rows split across tables; vertical = columns split).
> Sharding is horizontal partitioning across multiple physical databases.
>
> Why shard: single DB write throughput ceiling (~10-100K writes/second),
> single DB storage ceiling (practical: ~10-20TB for reasonable performance),
> single DB connection ceiling (1000-5000 connections). Sharding removes all three.
>
> Shard key design is the critical decision. Bad shard key: user_created_timestamp
> - all new users land on the same shard (write hot spot). Good shard key:
> user_id hash - uniform distribution. For reads: if you always query by user_id,
> hash(user_id) is perfect (all user data on one shard, no scatter-gather).
> If you also query by email: email lookup requires scatter-gather (all shards)
> unless you maintain a separate lookup table (email -> user_id -> shard).

**Blank Mind Recovery:**

**(1) Restate:** "Sharding splits a big database into smaller pieces across
multiple servers so no single server holds all the data."

**(2) First principles:** "One database can hold X GB and handle Y writes/second.
To go beyond: split data. User IDs 0-9: shard 1. User IDs 10-19: shard 2.
Now two databases, double the capacity."

**(3) The problem:** Cross-shard queries are expensive. Cross-shard transactions
are very hard. Choose your shard key to minimize both.

---

### 📘 Concept Explanation

**Sharding strategies:**

```
Hash-based sharding:
  shard_id = hash(user_id) % num_shards
  User 1001: hash(1001) % 4 = 1 -> Shard 1
  User 1002: hash(1002) % 4 = 2 -> Shard 2
  User 1003: hash(1003) % 4 = 3 -> Shard 3

  Pros: uniform distribution (good hash = even spread)
        good for write-heavy workloads
  Cons: range queries = scatter-gather (all shards)
        resharding requires rehashing most data

Range-based sharding:
  Shard 1: user_id 1 - 10M
  Shard 2: user_id 10M - 20M
  Shard 3: user_id 20M - 30M

  Pros: range queries on shard key = single shard
        easy to reshard (split shard range)
  Cons: hot spots (e.g., sequential IDs -> all writes to last shard)
        uneven data distribution if ranges fill unevenly

Directory-based sharding:
  Lookup service maps entity -> shard
  User 1001 -> Shard 2 (stored in routing table)
  User 1002 -> Shard 1

  Pros: flexible (move entities between shards)
        easy resharding
  Cons: routing table = SPOF, bottleneck, must be HA + fast

Geographic sharding:
  US users -> US shard
  EU users -> EU shard
  APAC users -> APAC shard

  Pros: data locality (low latency), GDPR compliance
        (EU data stays in EU)
  Cons: cross-region queries expensive
        user travel = wrong shard?

Consistent hashing:
  Virtual ring of 2^32 positions
  Each shard owns an arc on the ring
  Key: hash -> position -> clockwise to shard

  Adding shard: only 1/N keys move (not all)
  Removing shard: only that shard's keys move
  Standard modulo: adding shard -> rehash N/(N+1) keys
  Use: cache rings (Redis Cluster), distributed KV stores
```

**Cross-shard queries:**

```
Query: SELECT * FROM orders WHERE created_at > '2024-01-01'
  orders sharded by user_id
  created_at != shard key
  -> Scatter-gather: query ALL shards in parallel
  -> Merge results (sort, paginate)
  -> Expensive: O(N) where N = shard count

Secondary index approaches:
  Option 1: Global secondary index
    Separate DB: created_at -> (user_id, order_id) -> shard
    Lookup: index lookup -> user_id -> correct shard
    Cost: extra DB, replication lag between shards and index

  Option 2: Local secondary index
    Each shard has created_at index
    Query: scatter-gather all shards
    Merge: in application layer

  Option 3: Dual write
    Write order to user shard AND time-series shard
    Time-series shard: orders by created_at (single shard range)
    Time query: time-series shard (no scatter-gather)
    Cost: 2x storage, 2x write complexity
```

---

### 💻 Code Example

```java
// BAD: no shard key consideration (all-to-one)
@Entity
public class UserEvent {
    @Id
    @GeneratedValue  // auto-increment: all writes to last shard
    private Long id;
    private Long userId;
    private String type;
    private Instant createdAt;  // not the shard key
}

// Problem with range sharding on auto-increment:
//   Shard 1: id 1-1M  (old, low write volume)
//   Shard 2: id 1M-2M (old, low write volume)
//   Shard 3: id 2M+   (ALL new writes go here -> hot spot)

// GOOD: shard key designed for even write distribution
@Entity
public class UserEvent {
    // Shard key = userId (hash sharding)
    // All events for userId on same shard
    // Writes distributed by user hash
    @Id
    private String id;  // "{userId}-{uuid}" (composite)
    private Long userId;  // shard key
    private String type;
    private Instant createdAt;
}

// Routing logic (simplified):
@Repository
public class ShardedUserEventRepository {

    private final Map<Integer, DataSource> shards;
    private final int shardCount;

    public void save(UserEvent event) {
        int shardId = getShardId(event.getUserId());
        DataSource ds = shards.get(shardId);
        // execute insert on correct shard's DataSource
        JdbcTemplate jdbc = new JdbcTemplate(ds);
        jdbc.update(
            "INSERT INTO user_events VALUES (?,?,?,?)",
            event.getId(), event.getUserId(),
            event.getType(), event.getCreatedAt());
    }

    public List<UserEvent> findByUser(Long userId) {
        // Single shard lookup (optimal)
        int shardId = getShardId(userId);
        DataSource ds = shards.get(shardId);
        JdbcTemplate jdbc = new JdbcTemplate(ds);
        return jdbc.query(
            "SELECT * FROM user_events WHERE user_id = ?",
            userEventRowMapper, userId);
    }

    private int getShardId(Long userId) {
        // Consistent hash for stable routing
        return (int) (Math.abs(userId.hashCode()) % shardCount);
    }
}
```

> **Code walkthrough:** The BAD example uses auto-increment IDs as the primary
> key for a range-sharded table. All new records go to the last shard (highest ID).
> This creates a permanent write hot spot. The GOOD example shards by userId:
> all events for a user are on the same shard (single-shard user queries),
> and writes are distributed evenly across shards by the hash function.
> The routing layer (ShardedUserEventRepository) knows the shard count and
> maps user ID to the correct DataSource. In production: use Vitess (MySQL)
> or Citus (Postgres) which provide transparent sharding at the proxy layer,
> avoiding custom routing code.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Sharding splits database data across multiple servers. Each server holds
> a portion (shard) of the data. When you query by the shard key, it goes
> to one server (fast). When you query by something else, it must check all
> servers (slower - scatter-gather). The shard key choice determines whether
> writes are evenly distributed or concentrated on one server.

**Senior / Staff:**
> Shard key selection is an irreversible architectural decision that's expensive
> to change. I evaluate it on four dimensions: (1) cardinality - enough distinct
> values to distribute evenly, (2) write distribution - no sequential patterns
> that cause temporal hot spots, (3) query patterns - the most common queries
> use the shard key to avoid scatter-gather, (4) cross-shard transactions - zero
> or minimal. If the access patterns conflict (need to query by user AND by date
> efficiently), consider dual-write to a separate analytics shard or a CQRS
> pattern where the write model is sharded by user and the read model is built
> by date in a separate store. Vitess (used by YouTube, GitHub) handles this
> at the infrastructure layer with VSchema routing rules.

---

### ⚠️ Common Misconceptions

**Misconception: "Sharding and partitioning are the same thing."**
Partitioning = dividing data within one database (one physical machine).
Postgres table partitioning: one table split into multiple physical files,
but still managed by one Postgres instance, one connection pool.
Sharding = partitioning across multiple physical databases on separate machines.
Different scalability implications: partitioning improves query performance
(partition pruning) on one machine; sharding distributes load across machines.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Shard hot spot (uneven distribution)**
Symptom: one DB server at 90% CPU, others at 10%.
Cause: shard key has low cardinality or temporal pattern.
Diagnosis: measure writes per shard over time; plot heat map.
Fix: re-shard with better key, add virtual nodes (consistent hashing),
     or split hot shard into sub-shards.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - How do you shard a users table at Twitter scale?

Twitter scale context: 400M users, 500M tweets/day, 6000 reads/sec peak.

```
Users table sharding:
  Shard key: user_id (snowflake ID)
  Strategy: consistent hashing
  Shard count: 1000 virtual nodes (1000 / physical shards)

  Snowflake ID: 64-bit
    41 bits: timestamp (milliseconds since epoch)
    10 bits: machine ID
    12 bits: sequence number

  Snowflake distributes writes (machine ID distributes to machines)
  Consistent hashing: user_id -> hash ring -> shard

  Problem: "find users by username" (not user_id)
  Solution: separate username -> user_id lookup table
    username: "jack" -> user_id: 12345
    Lookup table: MySQL single table, fits in memory
    Or: sharded by first 2 chars of username

  Timeline assembly problem:
  User A follows 1000 users:
    "Get A's home timeline"
    Without sharding: 1 DB query (JOIN followers + tweets)
    With sharding: tweets on different shards by user_id
    Option 1: scatter-gather (1000 queries to 1000 user shards)
    Option 2: fanout-on-write (write tweet to each follower's timeline)
    Twitter uses fanout for normal users (<1M followers)
```

*What separates good from great:* Twitter's actual architecture evolved from
MySQL + scatter-gather to fanout-on-write to hybrid (celebrities skip fanout,
regular users get fanout). The shard key decision at Twitter was driven by
the timeline assembly problem: user_id sharding is optimal for "get all tweets
by user X" but terrible for "get all tweets by people A follows." There's no
single shard key that makes all queries efficient. The hybrid fanout approach
is the real-world solution: denormalize timeline data (write to followers' timeline
shards on tweet creation) to make reads fast. This is the write amplification
trade-off: 1000 followers = 1000 writes on tweet creation.

---

#### Q2 - How does database resharding work and why is it hard?

Resharding: changing shard count (adding shards to reduce load per shard).

```
Simple modulo sharding (hash % N):
  Current: 4 shards, hash(user_id) % 4
  Adding shard 5: hash(user_id) % 5
  Result: almost all data must move (4/5 = 80% of keys!)
  Why: different modulo -> different shard for most keys

Consistent hashing resharding:
  Ring: 2^32 positions
  Current: 4 shards, each owns 1/4 of ring
  Adding shard 5: placed between shard 2 and shard 3
  Result: only shard 2's keys nearest to new shard move
  Amount moved: ~1/N = ~20% (much less than simple modulo)

Resharding process (online, zero-downtime):
  1. Start new shard
  2. Dual-write: write to old shard AND new shard
  3. Background copy: migrate old data to new shard
  4. Once migration complete: verify data integrity
  5. Switch reads to new shard
  6. Stop dual-write to old shard

  Tools: Vitess resharding, Citus rebalancer,
         custom ETL with consistent hashing

Duration: hours to days (depends on data volume)
Risk: bugs in migration logic cause data loss or duplication
Testing: run migration in staging first, verify checksums
```

*What separates good from great:* Online resharding is complex enough that most
teams use a shard proxy (Vitess, PlanetScale) that handles it transparently.
Manual resharding: use consistent hashing from day 1 (not simple modulo),
accept that adding shards is still a multi-day operation. The alternative:
pre-shard (allocate many more logical shards than physical shards). Start with
64 logical shards on 4 physical databases (16 logical per physical). To scale:
move some logical shards to a new physical database. Only data for moved logical
shards migrates (not all data). Logical shard count never changes; physical
shard count grows. This is how Google's Spanner and many large systems work.

---

#### Q3 - What is the difference between vertical and horizontal partitioning?

```
Vertical Partitioning (column splitting):
  Before:
    users table:
      id, name, email, bio, profile_photo,
      last_login, created_at, preferences_json

  After vertical partition:
    users_core: id, name, email, last_login (hot data)
    users_profile: id, bio, profile_photo, preferences_json
                   (cold data, read less often)

  Benefit:
    users_core rows = smaller (fit more in memory/cache)
    users_core queries = less I/O (smaller row = more rows/page)
    users_profile: stored separately, slower storage OK

  Use cases:
    - Table with many columns, only a few accessed per query
    - Separate hot/cold columns
    - Different access control per column group

Horizontal Partitioning (row splitting):
  Before:
    orders table: ALL orders for ALL time

  After horizontal partition:
    orders_2023: orders from 2023
    orders_2024: orders from 2024
    orders_2025: orders from 2025

  Benefit:
    Query "orders in 2024": only scans orders_2024 (partition pruning)
    Archive: move orders_2023 to cold storage when done
    Indexes: smaller per-partition (faster)

  Postgres range partitioning:
    CREATE TABLE orders (
      id BIGINT, user_id BIGINT, created_at TIMESTAMPTZ
    ) PARTITION BY RANGE (created_at);

    CREATE TABLE orders_2024
      PARTITION OF orders
      FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

*What separates good from great:* Postgres native partitioning (PARTITION BY RANGE)
is transparent to the application - queries to `orders` automatically route to
the correct partition. The optimizer uses partition pruning: `WHERE created_at > 2024`
scans only orders_2024 and orders_2025, not previous years. This is the correct
first step before sharding for time-series data. Partition pruning + local indexes
per partition often eliminates the need for sharding entirely. Only shard when
the write volume exceeds what one primary can handle AND when table-level
partitioning is insufficient.

---

#### Q4 - How do you handle cross-shard transactions?

Distributed transactions across shards: hard to do correctly.

```
Two-Phase Commit (2PC):
  Phase 1 (Prepare):
    Coordinator -> Shard A: "Can you commit?"
    Coordinator -> Shard B: "Can you commit?"
    Both respond: "Yes, prepared"

  Phase 2 (Commit):
    Coordinator -> Shard A: "Commit"
    Coordinator -> Shard B: "Commit"
    Both commit

  Problem:
    Coordinator fails after Phase 1, before Phase 2:
    Both shards are "stuck" in prepared state (blocking protocol)
    Manual intervention required

  Performance:
    2 round trips + locks held during both phases
    Throughput: 10x lower than single-shard

Saga Pattern (avoid 2PC):
  Choreography saga:
    Service A: debit wallet
    Service A: publish "wallet-debited" event
    Service B: on event -> create order
    Service B: publish "order-created" event
    Service C: on event -> reserve inventory

  Compensation (rollback):
    Inventory fails -> publish "inventory-failed"
    Order service: on "inventory-failed" -> cancel order
    Wallet service: on "order-cancelled" -> refund wallet

  Benefits: no distributed lock, async
  Costs: eventual consistency, complex compensations

Avoid cross-shard transactions (design):
  Design shard key so related data lives on same shard
  Order + order_items: both sharded by order_id
  User + user_profile: both sharded by user_id
  -> Transaction within one shard (local ACID)
  This is the preferred solution
```

*What separates good from great:* The Saga pattern is the production answer to
distributed transactions, not 2PC. 2PC is blocking (locks held across network)
and not suitable for high-throughput systems. Saga is non-blocking (async events,
compensating transactions), but accepts eventual consistency and requires
idempotent event handlers (event may be delivered more than once). Most modern
microservice architectures use Sagas for cross-service operations. The key
engineering discipline: design the data model to minimize cross-shard operations
by co-locating related entities on the same shard. When you find yourself
constantly doing cross-shard queries: reconsider the shard key.

---

#### Q5 - How does Vitess enable transparent MySQL sharding?

Vitess (used by YouTube, GitHub, Slack): MySQL sharding layer.

```
Architecture:
  Application -> VTGate (proxy) -> VTTablet -> MySQL

  VTGate:
    - SQL routing: parse query, identify shard from WHERE clause
    - Scatter-gather: execute on multiple shards, merge results
    - Connection pooling: thousands of app connections -> few MySQL
    - Read/write splitting: SELECT -> read replica
                            INSERT/UPDATE -> primary

  VTTablet:
    - Per-MySQL-instance agent
    - Health checks, query rewriting, connection management

  VSchema:
    - Defines: which table is sharded by which column
    - Vitess uses VSchema to route queries

VSchema definition:
  {
    "sharded": true,
    "vindexes": {
      "hash": { "type": "hash" }
    },
    "tables": {
      "users": {
        "columnVindexes": [{
          "column": "user_id",
          "name": "hash"
        }]
      }
    }
  }
  -> Vitess hashes user_id -> routes to correct shard
  -> Application writes normal SQL: SELECT * FROM users WHERE user_id = 42
  -> Vitess adds WHERE clause AND routes to correct shard

Resharding with Vitess:
  vreplication: stream changes from old to new shards
  Online resharding: zero downtime, tested in production
```

*What separates good from great:* Vitess abstracts the sharding complexity that
would otherwise require significant custom application code. The application
writes standard MySQL SQL; Vitess handles routing, connection pooling, and
resharding. The practical cost: Vitess adds ~1ms to query latency (proxy hop).
For most workloads: acceptable. For ultra-low-latency queries: the proxy overhead
matters. Also: Vitess doesn't support all MySQL features (some complex JOINs
across shards require scatter-gather which changes query behavior). Evaluate
cross-shard query patterns before adopting Vitess.

---

#### Q6 - How do you shard a global social graph (like LinkedIn connections)?

Social graph: users as nodes, connections as edges.

```
Naive sharding (by user_id):
  User A: shard 1
  User B: shard 3
  Connection A-B: which shard?

  Option: connection stored on both shards
  When A queries "my connections": shard 1 has them
  When B queries "my connections": shard 3 has them
  Update: write to both (dual-write, eventual consistency)

Graph partition problem:
  Ideal: connected users on same shard (minimize cross-shard edges)
  Real: impossible for dense graphs (everyone connects to everyone)
  Solution: accept cross-shard edges with scatter-gather

LinkedIn's approach (TAO/Mercury):
  Store all edges on one dedicated "edges" store
  User nodes: sharded by user_id
  Edges: stored twice (A->B and B->A) for bidirectional lookup
  "A's connections": single lookup in edge store (A's partition)
  "B's connections": single lookup (B's partition)
  Edge store sharded by source node_id (A for A->B edge)

Friend-of-friend queries (2 hops):
  "Friends of A's friends" = scatter-gather:
    1. Get A's friends (N users)
    2. For each friend: get their friends
    -> N queries to N different shards
    -> 10 friends: 10 parallel queries
    -> 100 friends: 100 parallel queries
    -> Very expensive for users with 1000+ connections
```

*What separates good from great:* Social graph traversal is a fundamentally
cross-shard problem. No sharding strategy eliminates it. Facebook's TAO system
handles this with a caching layer that absorbs the read traffic (80% of graph
queries from cache). The graph is sharded (writes go to appropriate shards),
but reads go through a regional cache that materializes results. For "friends of
friends" at scale: pre-compute and cache (offline graph processing with Spark or
Flink), serve materialized results, refresh periodically. Real-time computation
of deep graph traversals at scale is infeasible; pre-computation + cache is standard.

---

#### Q7 - What is tenant-based sharding in multi-tenant SaaS systems?

Multi-tenant SaaS: one system, many customers (tenants), data isolation.

```
Sharding strategies for multi-tenancy:

Silo (one DB per tenant):
  Tenant A: own DB (total isolation)
  Tenant B: own DB
  Pros: complete data isolation, easy compliance
  Cons: expensive (N DBs), hard to rebalance,
        schema updates must be applied to all DBs
  Use: enterprise customers, strict compliance

Bridge (schema per tenant, shared DB):
  Tenant A: schema_a.orders
  Tenant B: schema_b.orders
  Pros: moderate isolation, cheaper than silo
  Cons: single DB is still SPOF, schema updates complex
  Use: moderate tenant count, moderate isolation needs

Pool (shared tables, tenant_id column):
  All tenants: same orders table, tenant_id column
  Row-level security: WHERE tenant_id = {current_tenant}
  Pros: cheapest, easiest schema updates
  Cons: noisy neighbor (large tenant slows all),
        harder isolation, compliance concerns
  Use: many small tenants, performance not critical

Hybrid (pool + silo for large tenants):
  Small tenants: shared pool (tenant_id in row)
  Large tenants (high traffic): dedicated shard
  Benefit: cost-efficient for small tenants,
           isolation for large (prevent noisy neighbor)
  Used by: Salesforce, Slack, Shopify
```

*What separates good from great:* The "noisy neighbor" problem in pool sharding
is the most common production complaint. One large tenant runs expensive queries
that degrade performance for all pool tenants. Solutions: (1) hybrid (move large
tenants to dedicated shards), (2) resource limits per connection/query, (3)
query cancellation after timeout. Postgres row-level security enforces tenant
isolation at the DB layer (application bugs can't accidentally leak cross-tenant
data). The Postgres approach: SET app.current_tenant = 'tenant_a' at connection
time; RLS policy enforces WHERE tenant_id = current_setting('app.current_tenant').

---

#### Q8 - How do you ensure data consistency across shards?

Data consistency challenges with sharding:

```
Within-shard consistency:
  Full ACID: transactions work normally within one shard
  Simple, use standard DB transactions

Cross-shard consistency:

Option 1: Eventual consistency (most common)
  Each shard independently consistent
  Cross-shard: accept brief inconsistency
  Example: user balance updated in shard A
           pending transaction visible in shard B after replication lag
  Acceptable when: lag is short (ms-sec), business allows it

Option 2: Two-Phase Commit (strong consistency)
  Coordinator spans both shards
  Both shards locked until commit
  Slow: network round trips, long lock hold
  Use only for: financial operations, inventory (oversell = bad)

Option 3: Saga (eventual + compensating)
  Sequence of local transactions with compensations
  If step N fails: run compensations N-1 through 1
  Eventually consistent: intermediate state visible
  Use: checkout flows, order processing

Option 4: Design avoidance
  Make operations single-shard:
  "Transfer between accounts" -> shard by account_id?
  Both accounts on same shard IF same user_id -> OK
  Accounts of different users -> cross-shard
  Financial solution: ledger entries, not direct balance update
    Debit ledger entry in shard A
    Credit ledger entry in shard B
    Net balance = sum of ledger entries (eventual)
    Ledger entries are immutable (no update conflicts)
```

*What separates good from great:* The ledger pattern (append-only credit/debit
entries) avoids cross-shard UPDATE conflicts entirely. Instead of "UPDATE balance
SET balance = balance - 100 WHERE user_id = X" (update on shard A), write a
debit entry to shard A and a credit entry to shard B as separate inserts. Balance
= SUM(entries). No cross-shard transaction needed (inserts are idempotent if
using unique entry IDs). This is how financial systems like Stripe and PayPal
model accounts. The double-entry accounting principle makes it both correct
and auditable.

---

#### Q9 - How do you monitor a sharded database system?

Monitoring key metrics per shard:

```
Per-shard metrics:
  QPS (queries per second): detect hot shards
    Alert: one shard > 2x average QPS
  Latency (P99): detect slow shards
    Alert: one shard P99 > SLO
  Connections: detect pool exhaustion
    Alert: connections > 90% of max_connections
  Replication lag: detect read replica staleness
    Alert: lag > 30 seconds
  Storage: detect shard filling up
    Alert: disk > 80% full

Cross-shard metrics:
  Scatter-gather query rate: high = design issue
  Cross-shard transaction rate: high = design issue

Tooling:
  Each shard: Prometheus node_exporter + mysqld_exporter
  Grafana: per-shard dashboard, heat map of QPS per shard
  Alert: PagerDuty on hot shard, replication lag, disk full

Vitess: built-in monitoring dashboard
  VTGate query latency per shard
  Shard topology view
  Replication lag per tablet
```

*What separates good from great:* The heat map visualization is the key
diagnostic tool for sharding. A QPS heat map shows which shards are hot
and at what time. Time-correlated hot spots (same shard busy every morning)
indicate temporal hot spot in the shard key. User-correlated hot spots
(one shard always hot) indicate skewed data distribution. Both require
re-sharding or shard splitting. Monitoring without per-shard granularity
masks problems: aggregate DB CPU 40% looks fine; individual shard CPU 85%
is a warning. Always monitor per-shard, not just aggregate.

---

# Replication Strategies

---
id: SSD-010
title: Replication Strategies
category: System Design
difficulty: ★★☆
interview_weight: high
asked_at: Senior/Staff
seniority: senior
tags: #replication, #primary-replica, #read-replicas, #consistency, #failover
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Replication creates copies of data across multiple servers for high availability
> and read scaling. Primary-replica: one primary handles writes, replicas handle
> reads (async replication = eventual consistency). Multi-primary: any node handles
> writes (conflict resolution needed). Synchronous replication: writes wait for
> replica ack (no data loss, higher write latency). Asynchronous: writes complete
> without waiting (risk of data loss on primary failure, lower latency).

**3 minutes:**
> Replication serves two purposes: availability (failover if primary fails) and
> scale (distribute read load to replicas). These are often conflated but have
> different mechanisms.
>
> For availability: synchronous replication to at least one replica. If primary
> fails: promote replica with guaranteed no data loss. MySQL semi-sync replication:
> write waits for ACK from at least one replica before confirming to client.
> PostgreSQL synchronous standby: same. The cost: write latency increases by
> network round-trip to replica (~5ms intra-datacenter, ~150ms cross-region).
>
> For read scaling: async replicas. Replicas may lag primary (milliseconds to
> seconds). Read from replica: may return stale data. Trade-off: stale reads
> acceptable for most use cases (product listings, social feeds) but unacceptable
> for others (bank balance, inventory).

**Blank Mind Recovery:**

**(1) Restate:** "Replication keeps multiple copies of data in sync across servers.
Write to primary, replicate to replicas for reads."

**(2) Sync vs async:** Sync = wait for replica before confirming (safe, slow).
Async = confirm immediately, replicate later (fast, may lose data on crash).

**(3) Three decisions:** Sync vs async (consistency vs latency). How many replicas
(availability vs cost). Failover (manual vs automatic).

---

### 📘 Concept Explanation

**Replication topologies:**

```
Primary-Replica (single primary):
  [Primary]----writes----> [Replica 1]
                      \--> [Replica 2]
                      \--> [Replica 3]
  Reads: distributed to replicas
  Writes: all go to primary
  Primary failure: one replica promoted to primary
  (manual or automatic with orchestrator)

Multi-Primary (multi-master):
  [Primary 1] <-replication-> [Primary 2]
  Writes: accepted at any primary
  Conflict: same row updated on both -> conflict resolution
  Conflict resolution: last-write-wins (timestamp), custom logic
  Use: geographically distributed (writes in each region)
  Risk: split-brain (network partition -> both primaries accept writes)

Cascading Replication:
  [Primary] -> [Replica 1] -> [Replica 2] -> [Replica 3]
  Each replica replicates from the previous
  Reduces load on primary (only replicates to Replica 1)
  Replication lag increases: Replica 3 lags more than Replica 1
  Use: many replicas, primary replication bandwidth limited

Chain Replication:
  Write enters tail, propagates forward
  Read from head (most up-to-date)
  Failure handling: remove node from chain
  Used in: Amazon S3, Riak, Apache BookKeeper

Quorum Replication:
  W + R > N (write quorum + read quorum > total nodes)
  N=3, W=2, R=2: write to 2/3, read from 2/3 (overlap exists)
  Cassandra, DynamoDB use quorum
```

**Replication modes:**

```
Asynchronous:
  Primary: write -> commit -> respond to client
  Primary: separately -> replicate to replicas (fire and forget)
  Write latency: local disk write only
  Risk: primary crashes before replication -> data loss (lag)
  Acceptable lag: milliseconds to seconds in normal operation
  Use: read scaling when stale reads are OK

Synchronous:
  Primary: write -> wait for ACK from replica -> commit -> respond
  Write latency: local write + network round trip to replica
  Risk: if replica down -> primary write stalls (blocks)
  Semi-sync (MySQL): wait for at least 1 replica ACK
  Synchronous_commit=on (Postgres): wait for all sync standbys
  Use: financial data, no data loss acceptable

Quorum writes:
  Write to W of N replicas before confirming
  Read from R of N replicas, return latest version
  W + R > N = overlap -> no stale reads
  Cassandra: QUORUM = majority of replicas (ceil(N/2))
  Trade-off: W=N (all replicas) = highest durability, high latency
             W=1 (one replica) = low latency, risk of data loss
```

---

### 💻 Code Example

```java
// BAD: read from primary for all queries (no read scaling)
@Repository
public class ProductRepository {

    @Autowired
    private DataSource primaryDataSource;  // always primary

    public Product findById(Long id) {
        // All reads hit primary -> bottleneck
        return jdbcTemplate.queryForObject(
            "SELECT * FROM products WHERE id = ?",
            productRowMapper, id);
    }

    public List<Product> findAll() {
        // This doesn't need to be fresh
        // Could be served from replica
        return jdbcTemplate.query(
            "SELECT * FROM products",
            productRowMapper);
    }
}

// GOOD: read/write routing via Spring's LazyConnectionDataSourceProxy
@Configuration
public class DataSourceConfig {

    @Bean
    @Primary
    public DataSource routingDataSource(
            @Qualifier("primary") DataSource primary,
            @Qualifier("replica") DataSource replica) {
        ReadWriteRoutingDataSource routing =
            new ReadWriteRoutingDataSource();
        routing.setPrimary(primary);
        routing.setReplica(replica);
        return routing;
    }
}

// Routing data source (read vs write):
public class ReadWriteRoutingDataSource
        extends AbstractRoutingDataSource {

    private DataSource primary;
    private DataSource replica;

    @Override
    protected Object determineCurrentLookupKey() {
        // @Transactional(readOnly=true) -> replica
        // @Transactional (default) -> primary
        boolean readOnly =
            TransactionSynchronizationManager
                .isCurrentTransactionReadOnly();
        return readOnly ? "replica" : "primary";
    }
}

// Service layer:
@Service
public class ProductService {

    @Transactional(readOnly = true)  // -> replica
    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    @Transactional  // -> primary
    public Product updateProduct(Long id, ProductDto dto) {
        return productRepository.save(dto.toEntity(id));
    }
}
```

> **Code walkthrough:** The RoutingDataSource uses Spring's transaction context
> to determine which DataSource to use. @Transactional(readOnly=true) sets a
> flag in TransactionSynchronizationManager. The routing data source reads this
> flag and routes to the replica. Regular @Transactional routes to the primary.
> This way: product listings, catalog reads, reports - all go to replicas.
> Only writes (create, update, delete) hit the primary. The application code
> doesn't change: just annotate with readOnly=true for read operations. The data
> source routing is transparent. Drawback: if a write is followed immediately by
> a read in the same request, the replica read may be stale (replication lag).
> For "read your own writes" consistency: route post-write reads to primary.

```java
// Handling replication lag: "read your own writes"
@Service
public class OrderService {

    @Transactional
    public Order createOrder(CreateOrderRequest req) {
        Order order = orderRepository.save(req.toEntity());
        // Flag: route reads to primary for this session
        ReplicationContext.setReadFromPrimary(true);
        return order;
    }

    @Transactional(readOnly = true)
    public Order getOrder(Long id) {
        // If post-write: read from primary (no stale read)
        // Otherwise: read from replica
        return orderRepository.findById(id).orElseThrow();
    }
}

// ReplicationContext signals routing data source:
public class ReplicationContext {
    private static final ThreadLocal<Boolean> readFromPrimary =
        new ThreadLocal<>();

    public static void setReadFromPrimary(boolean value) {
        readFromPrimary.set(value);
    }

    public static boolean isReadFromPrimary() {
        return Boolean.TRUE.equals(readFromPrimary.get());
    }
}
```

> **Code walkthrough:** The "read your own writes" problem: user creates an order
> and immediately views it. If the GET request hits a replica with replication lag,
> the order isn't visible yet. The solution: after a write, set a thread-local flag
> that forces reads to the primary for the duration of the request. The routing
> data source checks this flag. After the request completes, the flag clears.
> Subsequent requests (after replication catches up) go back to the replica.
> This is the standard pattern for "post-write reads must be fresh" while
> maintaining replica-based read scaling for all other reads.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Replication copies data from a primary database to replica databases.
> The primary handles writes; replicas handle reads. This reduces load on
> the primary and allows read scaling. The main gotcha: replicas may be slightly
> behind the primary (replication lag), so reads from replicas may return data
> that's a few milliseconds to seconds old. For most reads (product listings,
> user profiles), this is fine. For critical data (bank balance), read from primary.

**Senior / Staff:**
> The replication design question is: what are the failure modes? Async replication:
> primary failure can lose recent writes (the lag window). To prevent: semi-sync
> replication (at least one replica acknowledges before primary confirms). But
> semi-sync with synchronous standby adds network RTT to every write (~5ms
> intra-datacenter). Multi-primary in different regions: every region has a
> primary, writes go to local region (low latency), replicate to other regions
> async. The failure mode: split-brain on network partition (both regions accept
> writes to same row). Conflict resolution: last-write-wins by timestamp (if clocks
> are synchronized), or CRDT data structures for counter types. The operational
> recommendation: avoid multi-primary unless write latency across regions is the
> demonstrated bottleneck.

---

### ⚠️ Common Misconceptions

**Misconception: "Replicas are always consistent with the primary."**
Async replication means replicas lag. Lag is normally milliseconds but can grow
to seconds or minutes under: primary overload (replication thread CPU-starved),
network congestion, large transactions (replicate only after commit = hold lag
for transaction duration). Monitor replication lag as a health metric.
Alert when lag > 10 seconds. Lag >60 seconds: degraded mode (consider routing
reads to primary temporarily to prevent stale data issues).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Replica promotion causes data loss (split-brain)**
Symptom: data inconsistency after failover; some writes missing in new primary.
Cause: primary fails with async replication lag; replica promoted without
catching up; lost writes (in primary's lag window) never applied.
Prevention: semi-sync replication (at least one replica must ACK each write).
Diagnosis: after failover, compare binlog positions between old primary
(if recoverable) and new primary. Compute lost transaction IDs.
Fix: replay missing transactions from binlog (if old primary recoverable),
or accept data loss and correct manually.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - How does Postgres streaming replication work?

Postgres streaming replication: binary WAL log shipped to standbys.

```
WAL (Write-Ahead Log):
  Every change in Postgres written to WAL first
  WAL is binary log of all page-level changes
  Crash recovery: replay WAL from last checkpoint

Streaming replication:
  Primary: writes WAL to disk + streams to standby
  Standby: receives WAL, replays it
  Standby: page-accurate copy of primary

Configuration (postgresql.conf on primary):
  wal_level = replica           (includes replication info)
  max_wal_senders = 5           (5 standbys max)
  synchronous_standby_names = 'standby1'  (sync standby)

Configuration (recovery.conf on standby):
  standby_mode = on
  primary_conninfo = 'host=primary port=5432 ...'
  trigger_file = '/tmp/failover.trigger'

Monitoring replication lag:
  On primary:
  SELECT client_addr,
         pg_wal_lsn_diff(pg_current_wal_lsn(),
                          flush_lsn) AS lag_bytes
  FROM pg_stat_replication;
  -> lag_bytes: how far behind standby is (in WAL bytes)
  -> Divide by write rate = approximate seconds of lag

Failover:
  Primary fails
  Ops: promote standby (pg_promote() or touch trigger file)
  Standby: becomes primary
  Old primary: if recovered, must be re-joined as standby
  Tools: Patroni, repmgr (automate failover)
```

*What separates good from great:* Patroni is the industry standard for Postgres
HA. It uses a distributed consensus system (etcd, ZooKeeper, or Consul) to
elect a single leader (primary). On primary failure: Patroni automatically
promotes one standby, updates the connection endpoint (DNS or load balancer),
and reconfigures other standbys to replicate from the new primary. Failover
time: 30-60 seconds (configurable). The key guard: Patroni prevents split-brain
by using distributed lock (etcd lease) that only the active primary holds.
If the primary loses the lock (etcd not reachable): it demotes itself. This
is the fencing mechanism that prevents two primaries simultaneously.

---

#### Q2 - What is the difference between synchronous and asynchronous replication trade-offs?

```
Async replication:
  Primary: commit -> immediately return success to client
  Primary: separately -> stream WAL to standby
  Standby: replay WAL async

  Write latency: minimal (no wait for standby)
  Throughput: maximum (not limited by standby speed)
  Data loss: up to "replication lag" seconds on primary failure
    If primary fails with 5-second lag: last 5 seconds of data lost

Synchronous replication:
  Primary: hold commit -> wait for standby WAL flush ack
  Primary: after standby ack: commit -> return success to client

  Write latency: local commit time + network RTT to standby
    Intra-datacenter: +5ms
    Cross-datacenter: +100-200ms
  Throughput: limited by slowest synchronous standby
  Data loss: zero (standby has all data at time of primary failure)

Semi-synchronous (MySQL):
  Primary: wait for ACK from at least 1 of N replicas
  If all replicas down: timeout -> fall back to async
  Balance: no-data-loss for normal operation
           no-downtime if replicas fail (falls back to async)

Multi-AZ trade-off:
  AWS RDS Multi-AZ:
    Synchronous replication to standby in different AZ
    Automatic failover: 60-120 seconds
    Write latency: +2-5ms (AZ-to-AZ network)
    Data loss: zero (synchronous)
  RDS Read Replica:
    Async replication
    Not automatic failover to read replica
    Lower latency writes, but stale reads
```

*What separates good from great:* The failover time matters as much as data
loss. Synchronous replication gives zero data loss but only matters if failover
is fast enough to detect the failure and promote the standby. If failover takes
5 minutes: users experience 5 minutes of downtime regardless of replication mode.
The combination: synchronous replication (no data loss) + automated failover with
external consensus (fast failover) = both goals. Patroni achieves sub-60-second
failover. With synchronous replication: no data loss + 60-second outage.
With async + fast failover: near-zero outage + possible small data loss.
Choose based on which failure mode is more acceptable for the business.

---

#### Q3 - How do you implement multi-region replication for global users?

Multi-region replication: data available near users in every continent.

```
Architecture:
  US-East: primary (all writes)
  EU-West: async replica (reads for EU users)
  APAC: async replica (reads for APAC users)

  Routing:
    EU user reads: EU-West replica
    EU user writes: US-East primary (cross-Atlantic!)
    APAC user reads: APAC replica
    APAC user writes: US-East primary (cross-Pacific)

  Write latency: primary is far from EU/APAC users
    EU write: +100-150ms round trip to US-East primary
    APAC write: +200ms round trip to US-East primary

Multi-primary (active-active):
  US-East primary: accepts writes from US users
  EU-West primary: accepts writes from EU users
  APAC primary: accepts writes from APAC users
  All: replicate to each other (bidirectional)

  Benefits: low write latency everywhere
  Costs: conflict resolution (same record written in two regions)
  Conflict resolution: last-write-wins by vector clock
                       or domain-specific resolution

Conflict-free:
  Global unique IDs (snowflake with region bit)
  No user writes to same record from two regions
  CRDT data types (counters, sets): mathematically conflict-free
  CRDTs used by: Redis, Riak, DynamoDB (CRDT counters)

Practical pattern (Slack):
  Data classification: user data (regional, stays in region)
                       shared data (global, replicated everywhere)
  User messages: stored in user's home region
  Enterprise workspaces: all data in enterprise's contracted region
```

*What separates good from great:* Multi-region active-active is complex to
implement correctly. Most companies don't need it until they have a global
user base AND have proven that cross-region write latency is hurting users
AND have the engineering team to manage conflict resolution. The simpler path:
single primary region + multi-region read replicas. EU reads are from the EU
replica (fast). EU writes go cross-Atlantic to US primary (slower, but most
users don't notice 150ms on write vs the 20ms with local primary). Implement
active-active only when write latency is a demonstrated user-facing problem.

---

#### Q4 - How do read replicas handle the "read after write" consistency problem?

Read after write: user writes data, immediately reads it, gets stale result.

```
Scenario:
  1. User updates profile photo (write to primary)
  2. User immediately views profile (read from replica)
  3. Replica hasn't received the write yet (lag)
  4. User sees old photo -> confusing user experience

Solutions:

1. Route post-write reads to primary:
   After write: for the next N seconds (or until known replica lag),
   route this user's reads to primary
   Implementation: set session flag, sticky LB rule
   Cost: more primary load for that user temporarily

2. Read from primary for own profile only:
   User reads own data: always primary
   User reads others' data: replica OK (stale for others = fine)
   Simple rule: "is this your own data?" -> primary

3. Monotonic read consistency:
   Track the write's WAL position (replication slot position)
   Read from any replica that has caught up to that position
   Skip replicas with earlier position
   Used by: DynamoDB (allows specifying read consistency level)

4. Short replication lag + accept occasional stale:
   Replication lag <100ms in normal operation
   "User may see old profile for up to 100ms"
   UX: show spinner briefly after update
   Cheap: no extra complexity, just accept it

Amazon Aurora:
  Tracks write LSN (log sequence number)
  Client can request "read after this LSN"
  Aurora routes to replica that has replayed that LSN
  Transparent to application: Aurora handles routing
```

*What separates good from great:* Most production systems handle this with a
combination of (1) short default TTL for cached user data and (2) route post-write
reads to primary for the first 500ms. The 500ms window is longer than typical
replication lag but short enough to not impact replica read scaling significantly.
The real-world frequency of "immediate read after write" is lower than it sounds -
the user doesn't typically read their profile again in the same sub-second. The
pattern: measure how often read-after-write actually shows stale data (add logging),
and implement a solution proportional to the actual frequency of the issue.

---

#### Q5 - How does Cassandra handle replication differently from relational databases?

Cassandra uses peer-to-peer replication (no single primary):

```
Cassandra replication:
  Data: distributed across all nodes (consistent hashing ring)
  Replication factor (RF): how many copies of each data item
  RF=3: each data item stored on 3 nodes

  Write path:
    Client -> any coordinator node
    Coordinator: determine which 3 nodes own this partition
    Coordinator: write to all 3 nodes simultaneously
    Consistency level QUORUM: wait for 2/3 ACK
    Return success to client

  Read path:
    Client -> any coordinator node
    Coordinator: determine which 3 nodes own this partition
    Consistency QUORUM: read from 2/3, return latest version
    (read repair: if 2 nodes return different versions, fix the stale one)

Consistency levels:
  ONE: 1 ACK (fastest, stale reads possible)
  QUORUM: majority ACK (balance: consistent + available)
  ALL: all replicas ACK (slowest, most consistent)
  LOCAL_QUORUM: quorum within local datacenter only

  Rule: write CL + read CL > RF
  RF=3, write QUORUM(2), read QUORUM(2): 2+2>3 -> consistent
  RF=3, write ONE(1), read ONE(1): 1+1=2, not >3 -> may be stale

Multi-datacenter:
  RF=3 per datacenter: 3 copies in US, 3 in EU
  LOCAL_QUORUM reads: read from local DC (fast)
  Write propagates to both DCs eventually
```

*What separates good from great:* Cassandra's replication model is fundamentally
different from primary-replica. There is no primary; any node can handle writes
for any partition. The consistency level is a per-query trade-off: QUORUM gives
strong consistency (reads always see the latest write) at the cost of latency.
ONE gives low latency but may return stale data. Most Cassandra use cases:
time-series data, IoT, logs - where eventual consistency (ONE) is acceptable.
For financial data in Cassandra: QUORUM reads and writes with RF >= 3 ensure
consistency. The hinted handoff feature: if a replica is down during write,
coordinator stores a "hint" and replays it when the replica recovers. This
prevents data loss without requiring synchronous writes.

---

#### Q6 - How do you monitor and alert on replication health?

Replication health monitoring:

```
Metrics to monitor:
  Replication lag (seconds or bytes):
    Postgres: pg_stat_replication.replay_lsn lag
    MySQL: SHOW SLAVE STATUS -> Seconds_Behind_Master
    Alert: lag > 30 seconds

  Replication throughput (bytes/second):
    Drop in throughput = replication thread stalled or slow
    Alert: < 50% of baseline throughput

  Connected replicas count:
    Primary has N replicas configured
    Alert: fewer than N replicas connected

  Replica errors:
    SHOW SLAVE STATUS -> Last_Errno (MySQL)
    Postgres: pg_stat_replication connection state
    Alert: any replica error

Prometheus exporters:
  mysqld_exporter: mysql_slave_status_seconds_behind_master
  postgres_exporter: pg_replication_slots_active, pg_stat_replication

Grafana dashboard:
  Graph: replication lag over time per replica
  Alert: PagerDuty when lag > 60 seconds for 5+ minutes

Synthetic monitoring:
  Write a test row to primary every minute
  Read that row from each replica
  Measure time to appear on each replica
  = Real replication lag measurement (not just WAL bytes)
```

*What separates good from great:* The synthetic monitoring approach gives the
true end-to-end replication lag as experienced by the application, not just
the WAL position lag. WAL bytes lag can be misleading (large transactions show
big byte lag that resolves instantly on commit; actual application-visible lag
is different). The synthetic test writes a timestamped row and reads it from
each replica until it appears, measuring the actual time. This matches what
users experience when they write and immediately read. Implement this as a
health check that's part of your canary deployment pipeline: if replication lag
is high after a deployment, roll back.

---

#### Q7 - What is logical replication and when do you use it over physical replication?

Two replication modes in Postgres:

```
Physical Replication (streaming):
  Replicates WAL (raw page changes)
  Exact byte-for-byte copy of primary
  Requirements: same Postgres version, same architecture
  Use: HA standby (promote on failure)
  Cannot: filter tables, replicate to different schema

Logical Replication:
  Replicates logical changes (INSERT, UPDATE, DELETE rows)
  Decoded from WAL into row-level operations
  Requirements: Postgres 10+, publisher-subscriber model
  Can: filter specific tables, replicate to different Postgres version
       replicate to different schema (same column names, different tables)
       replicate to different databases (cross-cluster)

  Configuration:
    Publisher (primary):
      CREATE PUBLICATION my_pub
        FOR TABLE products, orders;  (specific tables only)

    Subscriber (target):
      CREATE SUBSCRIPTION my_sub
        CONNECTION 'host=primary ...'
        PUBLICATION my_pub;

Use cases for logical replication:
  Zero-downtime Postgres version upgrade:
    1. Old version: create logical publication
    2. New version server: create logical subscription
    3. Wait for sync (replication catches up)
    4. Cut-over: switch application to new server
    5. No downtime: new server was already in sync

  Multi-master (bidirectional):
    A replicates changes to B
    B replicates changes to A
    Conflicts: avoided by not writing same rows on both

  Selective replication:
    Production -> Analytics DB: replicate subset of tables
    Analytics DB: additional columns, different schema
```

*What separates good from great:* Logical replication enables zero-downtime
major version upgrades - the most important operational use case. Before logical
replication (Postgres 10): major version upgrades required `pg_upgrade` and
downtime. With logical replication: run old and new version in parallel,
replicate changes, cut over when ready, zero downtime. This changed how
organizations approach Postgres upgrades from "dreaded annual event" to "routine
operation." The constraint: logical replication doesn't replicate DDL (schema
changes). Schema changes must be applied manually on both servers. Use
expand-contract pattern: add columns on both before deploying code that uses them.

---

#### Q8 - How does database failover work and what are the risks?

Failover: promoting a replica to primary after primary failure.

```
Manual failover (traditional):
  1. Primary fails (alerts fire)
  2. Ops team notified (PagerDuty: 2 AM)
  3. Ops identifies best replica (least lag)
  4. Promotes replica: pg_promote() or MySQL RESET MASTER
  5. Updates connection string in app config
  6. App restart or connection pool flush
  Total time: 5-30 minutes (human MTTR)

Automated failover with Patroni:
  1. Primary fails
  2. Patroni agents detect (heartbeat timeout: 30 seconds)
  3. Patroni: hold leader election via etcd
  4. Patroni: one replica wins election
  5. Winner: promoted to primary (pg_promote())
  6. Patroni: updates DCS (etcd) with new primary info
  7. VIP (floating IP) or HAProxy: updated to point to new primary
  8. App: reconnects (connection pool retry logic)
  Total time: 30-60 seconds

Risks during failover:

Split-brain:
  Old primary recovers (network partition resolves)
  Two primaries both accepting writes
  Prevention: STONITH (Shoot The Other Node In The Head)
    Patroni: revoke old primary's etcd lease -> it demotes itself
    Or: fence the node (reboot via IPMI, AWS ec2 terminate)

Data loss:
  Async replication: replica may be behind primary
  Promoted replica: missing last N transactions
  Prevention: semi-sync or synchronous replication

Application reconnection:
  Apps have cached connection to old primary (now dead)
  Need connection pool flush or reconnect logic
  Spring: `spring.datasource.hikari.connection-timeout=5s`
    -> Retry on connection failure
```

*What separates good from great:* The split-brain prevention is the most
critical correctness concern in automated failover. If the old primary recovers
and starts accepting writes while the new primary is already accepting writes:
both receive conflicting writes. Data diverges. This is worse than data loss
(at least with loss, you know what's missing; with divergence, you may not
know whose writes are correct). Patroni's STONITH approach: old primary loses
its etcd lease -> Patroni daemon on old primary sees it's no longer leader ->
voluntarily demotes itself. No human intervention needed. Test this regularly:
kill the primary in staging, verify automated failover completes, verify old
primary can re-join as standby.

---

#### Q9 - How do you handle schema migrations with replication?

Schema migrations on replicated databases require careful sequencing.

```
Problem: schema change timing
  If you add a column to primary THEN deploy code that reads it:
    Replica hasn't received the schema change yet
    Code on replica reads column: column doesn't exist -> error

  Correct order for adding a column:

  1. Apply migration to primary:
     ALTER TABLE users ADD COLUMN phone VARCHAR(20);
  2. Wait for replication to propagate to all replicas
     (check lag = 0 on all replicas)
  3. Deploy code that uses the column
  4. Both primary and all replicas have the column
  5. Code runs on any server: column exists

  Correct order for removing a column:

  1. Deploy code that stops using the column
     (no SELECT phone, no INSERT/UPDATE with phone)
  2. Verify no more references in production code
  3. Apply migration:
     ALTER TABLE users DROP COLUMN phone;
  4. Replicas receive drop (replicate after primary commits)

Zero-downtime (expand-contract):
  Adding new column with NOT NULL:
  1. Add column as nullable first:
     ALTER TABLE users ADD COLUMN phone VARCHAR(20);
     (replicate to standbys)
  2. Deploy code that writes new + old columns
  3. Backfill: UPDATE users SET phone = '' WHERE phone IS NULL;
  4. Add NOT NULL constraint:
     ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
  5. Deploy code that only writes new column
  6. Later: clean up if needed
```

*What separates good from great:* The Flyway / Liquibase migration timing is
the critical operationally. Many teams run migrations as part of the application
startup (before serving traffic). This can cause problems with replication:
if you deploy to one node and it runs the migration, replicas haven't received
it yet. If other nodes start before replication catches up: they query columns
that don't exist on replicas. Solution: run migrations as a separate step
in the deployment pipeline (not at startup), wait for replication lag = 0 on
all replicas after each migration, then proceed with application deployment.
Tools: Flyway's `flyway.outOfOrder=false` and a health check step in CI/CD.
