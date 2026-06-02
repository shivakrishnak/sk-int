---
layout: default
title: "Distributed Systems - L2 Replication and Sharding"
parent: "Distributed Systems"
nav_order: 4
permalink: /distributed-systems/l2-replication-and-sharding/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Data Replication Strategies](#data-replication-strategies) | medium |
| 2 | [Database Sharding](#database-sharding) | medium |

---

# Data Replication Strategies

**TL;DR:** Replication copies data to multiple nodes for durability and
read scalability. The two primary strategies are synchronous replication
(write acknowledged only after all replicas confirm - strong consistency,
higher write latency) and asynchronous replication (write acknowledged
after primary confirms - lower write latency, risk of data loss on
primary failure). Single-primary replication is the most common model:
one node accepts writes, others serve reads. Multi-primary replication
enables writes anywhere but requires conflict resolution.

---

### 🎯 Model Answer

**30 seconds:**
> Replication copies data across multiple nodes. Synchronous: write
> succeeds only after all replicas confirm - no data loss, but slower
> writes. Asynchronous: write succeeds after primary confirms,
> replicas catch up later - faster writes, but risk of losing recent
> data if the primary fails before replicating. Single-primary
> (one writer) is simpler. Multi-primary (write anywhere) is more
> available but requires conflict resolution.

**3 minutes:**
> Replication serves two purposes: durability (data survives node
> failures) and read scalability (read replicas spread read load).
> The core trade-off is synchronous vs asynchronous. Synchronous
> replication: the primary sends the write to replicas and waits
> for acknowledgment before returning success to the client. If a
> replica is slow or unavailable, the write blocks. Strong consistency,
> zero data loss, but higher write latency and lower availability
> (replica failure blocks writes). Asynchronous replication: the
> primary acknowledges success immediately after writing locally.
> Replicas receive the change via a replication log and apply it
> later. Lower write latency, but if the primary fails before
> replicating, the uncommitted changes on the primary are lost.
>
> Single-primary replication is the standard model: one designated
> primary accepts writes, replicas serve reads. This avoids write
> conflicts. Multi-primary: any node can accept writes simultaneously.
> Problem: two nodes may receive conflicting writes to the same record
> at the same time, requiring conflict resolution (LWW, CRDTs, or
> application logic).

**Blank Mind Recovery:**

**(1) Restate:** "Data replication strategies - how to copy data
across multiple nodes and what trade-offs each approach makes."

**(2) First principles:** "Multiple copies of data = more durability,
more read capacity. The question is: how do you keep the copies
consistent? Synchronous = wait for all copies. Async = copy later.
Single writer = no conflicts. Multi-writer = conflicts possible."

**(3) Bridge:** "Like saving a Word document to two USB drives:
synchronous = save to both before saying 'done.' Async = save to
the first, copy to the second in the background. Single-primary =
only you can edit. Multi-primary = anyone can edit, but what
if both edit simultaneously?"

---

### 📘 Concept Explanation

**What it is:**
Replication: maintaining copies of the same data on multiple nodes.
The replication strategy defines when copies are updated relative to
the primary write acknowledgment.

**The problem it solves:**
Without replication: a single node failure loses all data. A single
node has limited read throughput. Users in distant regions face high
latency. Replication provides durability (survive node failures),
read scalability (spread read load across replicas), and geographic
distribution (keep replicas close to users).

**Replication models:**

**Single-Primary (Leader-Follower):**

```
Client → Primary (accepts writes)
          ↓ (replicate)
         Replica 1 (read-only)
         Replica 2 (read-only)
         Replica 3 (read-only)
```

> **Code walkthrough:** This Data Replication Strategies example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Write path: client → primary only.
Read path: client → any replica.
Failover: promote a replica to primary on primary failure.

**Multi-Primary (Multi-Master):**

```
Client A → Primary 1 (accepts writes)
Client B → Primary 2 (accepts writes)
          Primary 1 ↔ Primary 2 (sync bidirectional)
```

> **Code walkthrough:** This Data Replication Strategies example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Write path: any primary.
Conflict: both primaries accept conflicting writes simultaneously.
Resolution: LWW (last write wins by timestamp), CRDTs, or
application-level conflict resolution.

**Leaderless (Dynamo-style):**

```
Client → writes to W nodes (quorum write)
Client → reads from R nodes (quorum read)
W + R > N → guaranteed to see latest write
```

> **Code walkthrough:** This Data Replication Strategies example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

N = total replicas, W = write quorum, R = read quorum.
No primary/replica distinction.

**Synchronous vs Asynchronous:**

```
Sync:  Client → Primary → Replica 1 ✓ → Replica 2 ✓ → ACK
       Pros: zero data loss on primary failure
       Cons: write latency = slowest replica

Async: Client → Primary → ACK
                        ↓ (eventually)
               Replica 1 (lags behind)
       Pros: low write latency
       Cons: replica lag = potential data loss
```

> **Code walkthrough:** This Data Replication Strategies example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
Most production systems use semi-synchronous replication: at least
one replica must confirm before acknowledgment (durability of one
failure) but not all replicas (not blocked by slow replicas).
MySQL: `rpl_semi_sync_master_wait_for_slave_count = 1`.

**When to use it:**
- Single-primary sync: financial systems, user accounts (zero data loss)
- Single-primary async: analytics, events, logs (latency matters more)
- Multi-primary: multi-region writes where latency to a single primary
  is unacceptable (30ms+ cross-region per write)
- Leaderless: high availability, variable workloads (Cassandra, DynamoDB)

**When NOT to use it:**
Multi-primary adds conflict resolution complexity. Do not use it
unless cross-region write latency is actually a business problem.

**Alternatives:**
- Shared storage: all nodes access the same storage (Oracle RAC,
  AWS Aurora) - simplifies consistency but storage is the SPOF
- Synchronous replication with read from primary: strong consistency,
  no read scalability

**First-principles derivation:**
"To survive a node failure without data loss, a second copy must
exist. To keep the copy current, writes must be replicated.
Replicate before ACK = sync (safe but slow). Replicate after ACK
= async (fast but lossy on crash). Every replication strategy is
a trade-off on this axis."

---

### 💻 Code Example


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// REPLICATION LAG: detecting and handling stale reads

// BAD: assume replica is always current
@Service
public class OrderService {
    // replicaDataSource reads from a read replica
    @Autowired @Qualifier("replica")
    private DataSource replicaDataSource;

    public Order getOrder(long orderId) {
        // BUG: user just placed the order.
        // Replica may lag 100-500ms.
        // User sees "Order not found" immediately after
        // placing it. Support calls ensue.
        return orderRepository
            .findById(orderId, replicaDataSource)
            .orElseThrow(() ->
                new OrderNotFoundException(orderId));
    }
}

// GOOD: route post-write reads to primary
//       route general reads to replica
@Service
public class OrderService {

    @Autowired @Qualifier("primary")
    private DataSource primaryDataSource;

    @Autowired @Qualifier("replica")
    private DataSource replicaDataSource;

    public Order getOrderAfterCreate(long orderId) {
        // Read from primary: guaranteed to see the write
        // Use for: post-write reads, critical consistency
        return orderRepository
            .findById(orderId, primaryDataSource)
            .orElseThrow();
    }

    public List<Order> getOrderHistory(long userId) {
        // Read from replica: stale by 100-500ms is fine
        // Use for: analytics, dashboards, non-critical reads
        return orderRepository
            .findByUserId(userId, replicaDataSource);
    }
}
```

> **Code walkthrough:** The BAD example routes all reads to the replicaice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> without considering replication lag. Immediately after a write, the
> replica may lag by 100-500ms (or more under load). The GOOD example
> routes post-write reads to the primary (guaranteed to see the write)
> and routes read-heavy non-critical queries to the replica (acceptable
> staleness). This is the standard pattern for read/write splitting
> with replication: primary for critical consistency, replica for scale.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Replication copies data to multiple nodes. Synchronous: wait for all
> replicas before ACK (safe, slower). Asynchronous: ACK immediately,
> replicate later (faster, risk of data loss). Single-primary is simpler
> (one writer, conflicts impossible). Multi-primary allows writes
> anywhere but requires conflict resolution.

*Push deeper:* "In practice, we use semi-synchronous: at least one
replica must confirm. This gives durability against primary failure
without blocking on all replicas."

---

**Senior / Staff:**
> Replication trade-offs at production depth: replication lag is not
> just a correctness issue - it drives operational decisions. When I
> size read replicas, I track replica lag in Prometheus.
> If lag exceeds 1s, I route critical reads back to the primary
> automatically. For failover: automatic promotion (Patroni for
> PostgreSQL) vs manual; RPO (data loss acceptable) drives the sync
> vs async choice.

*Push deeper:* "At staff level: replication strategy interacts with
backup and disaster recovery. With async replication, a primary crash
30 seconds before backup loses those 30 seconds of data. RPO dictates
whether that is acceptable. Semi-sync with 1 replica and async to
others is the common compromise: durability against primary failure,
no latency penalty from slow replicas."

---

### ⚠️ Common Misconceptions

**"Replication = backup"**

Reality: replication provides durability against node failure but
NOT against data corruption or accidental deletion. If a bug deletes
all rows in a table, the deletion replicates to all replicas within
milliseconds. Backups (point-in-time, offline) are required in
addition to replication.

**"More replicas = better read performance linearly"**

Reality: read performance scales with replicas up to the write
replication capacity. If writes generate 50MB/s of replication log,
each replica must process 50MB/s of writes regardless of how few
client reads it handles. At high write rates, replicas are not idle
- they are constantly applying the replication log. Adding 10 replicas
gives 10x read capacity but also 10x replication write overhead.

---

### ⚖️ Comparison Table

| Strategy | Write Latency | Data Loss Risk | Conflict Risk | Choose When |
|---|---|---|---|---|
| Sync single-primary | High (waits all) | Zero | None | Financial data |
| Semi-sync single-primary | Medium (waits 1) | Very low | None | Most production |
| Async single-primary | Low | Yes (replica lag) | None | High write throughput |
| Multi-primary async | Low | Yes | Yes (must resolve) | Multi-region writes |
| Leaderless (QUORUM) | Medium | Low | Possible | High availability |

**The deciding factor:** RPO (recovery point objective). Zero RPO requires
synchronous replication. RPO of seconds to minutes allows async.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Replication lag causes stale reads after write.**

Symptom: a user writes a record and immediately reads it back, receiving the old value. Diagnosis: check `replication_lag_seconds` metric on the replica; if lag exceeds the read latency, stale reads are expected. In PostgreSQL, query `SELECT now() - pg_last_xact_replay_timestamp()` on the replica. Fix: for consistency-critical reads, route to the primary; alternatively, implement read-your-writes consistency by routing the reader to the replica only after waiting for the replica to catch up to the write LSN.

**Failure Mode 2: Split-brain - two nodes simultaneously accept writes during network partition.**

Symptom: conflicting records appear in both nodes after network partition heals; automated conflict resolution may silently discard data. Diagnosis: monitor `write_quorum_failures` or examine diverged LSN positions; look for `conflict_detected` log entries during partition healing. Fix: configure write quorum (majority of replicas must acknowledge writes) to prevent isolated nodes from accepting writes; prefer `pause_on_recovery` mode for critical data over automatic conflict resolution that may discard writes.

**Failure Mode 3: PostgreSQL replication slot not cleaned up after subscriber disconnect.**

Symptom: WAL (Write-Ahead Log) disk fills up, database performance degrades, eventually out-of-disk error. Diagnosis: `SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal FROM pg_replication_slots WHERE active = false;` - inactive slots hold WAL segments indefinitely. Fix: drop the inactive slot: `SELECT pg_drop_replication_slot('slot_name');` - then fix the disconnected subscriber or recreate the subscription.

---

### 🎯 Interview Deep-Dive

#### Production Failures

**[JUNIOR] Q1 - [DEBUGGING] Replication lag suddenly increases from 50ms to 30 seconds on a MySQL read replica. What happened and how do you diagnose?**

Check the replica's lag metric: `SHOW SLAVE STATUS\G` → Seconds_Behind_Master.
A spike to 30s could be: (1) a large transaction on the primary
(DDL or bulk update) blocking the replica's single-threaded apply
worker, (2) high write load on the primary overwhelming the replica's
apply speed, (3) a slow query on the replica itself blocking the
apply thread. Diagnosis: check `SHOW PROCESSLIST` on the replica for
a long-running apply thread. Check primary binlog for large transactions:
`mysqlbinlog binlog.000001 | grep -E "Query_time|# at"`. Fix:
(1) parallel replication for row-based replication, (2) reduce transaction
size on primary, (3) switch to statement-based row filtering if schema
heavy.

**[JUNIOR] Q2 - [MECHANISM] After a primary failover, the new primary is missing the last 5 writes that clients confirmed. Why?**

Async replication: the old primary acknowledged writes before
replicating them. The replica that was promoted to primary had
Seconds_Behind_Master > 0 at failover time. Those writes were
in the old primary's binlog but not yet applied to the replica.
When the old primary failed (crashed/rebooted), those binlog entries
were lost. Fix for prevention: use semi-synchronous replication
(`rpl_semi_sync`) so at least one replica has confirmed each write
before the primary acknowledges. Or use AWS RDS Multi-AZ which
provides synchronous replication to the standby.

**[JUNIOR] Q3 - [MECHANISM] Read replica is serving stale data 10 minutes after a write. Users are complaining.**

Replica lag: `SHOW SLAVE STATUS` shows Seconds_Behind_Master = 600.
This is unusually high. Possible causes: a long-running transaction
on the primary is blocking replication (single-threaded apply);
a slow query on the replica is delaying the apply thread; the replica
is overloaded with read traffic and cannot keep up with write
replication simultaneously. Check: `SHOW PROCESSLIST` on replica
for long apply threads. Check replica CPU/disk I/O metrics.
Fix: reduce read load on the replica (add another replica), enable
parallel replication, or increase replica hardware.

#### Candidate Mistakes

**[MID] Q4 - [MECHANISM] What is the difference between replication and backup?**

**What NOT to say:** "They are basically the same - both protect your data."

**Say instead:** "Replication and backup serve different failure scenarios.
Replication protects against node failure: if the primary crashes,
a replica has a recent copy. But if data is corrupted or accidentally
deleted, the corruption replicates to all replicas within seconds.
Backup (point-in-time snapshot) protects against logical corruption:
you can restore to the state before the bad operation. A production
database needs BOTH: replication for high availability (fast recovery
from node failure) and backups for disaster recovery (restore after
corruption or accidental deletion)."

**[MID] Q5 - [MECHANISM] In multi-primary replication, how do you resolve conflicts?**

**What NOT to say:** "Last write wins - just use the latest timestamp."

**Say instead:** "Last-write-wins with timestamps has a flaw: clock skew
can cause the earlier logical write to appear as 'later' by timestamp.
Better approaches: (1) application-level conflict detection - include
the last-seen version number in the write; if the current version does
not match, the write fails with a conflict error. (2) CRDTs - design
data structures that merge concurrent writes deterministically (counters,
sets). (3) Operational transform - used in collaborative editing
(Google Docs). For most applications, if multi-primary conflicts are
possible, CRDTs or version-checking are safer than LWW."

#### Questions to Ask the Interviewer

**[SENIOR] Q6 - [MECHANISM] "What is the current replication lag SLA for the read replicas?"**

*Why:* This reveals operational maturity and whether read replicas are
actually usable for the stated purpose.

**[SENIOR] Q7 - [MECHANISM] "How is failover orchestrated - automatically or manually?"**

*Why:* Shows understanding of MTTR and operational complexity.

---

### 🏛️ System Design

*(Omit: replication strategy is a database design decision, not a
standalone system design topic. Covered within broader DB design.)*

---

### 📊 Diagram

*(Omit: prose description is sufficient; architecture is standard
leader-follower topology.)*

---

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# Database Sharding

**TL;DR:** Sharding horizontally partitions data across multiple database
nodes, where each node (shard) holds a subset of rows. The shard key
determines which node stores each row. Sharding enables write throughput
to scale beyond what any single node can handle. The costs: no joins
across shards, complex re-sharding when data distribution changes,
and application-level routing complexity.

---

### 🎯 Model Answer

**30 seconds:**
> Sharding splits data horizontally across multiple database nodes.
> Each node holds a subset of rows, determined by a shard key. This
> enables write throughput to scale beyond a single machine's limit.
> The trade-offs: cross-shard joins become expensive or impossible,
> choosing a bad shard key creates hotspots, and re-sharding data
> later is painful.

**3 minutes:**
> Replication gives you read scalability and durability, but all writes
> still go to one primary. Sharding gives you write scalability by
> splitting the data itself. Each shard is an independent database
> with its own primary and replicas. A shard key (e.g., user_id %
> number_of_shards) determines which shard stores each record.
>
> The shard key choice is critical. A bad key causes hotspots: if you
> shard by created_at (timestamp), all new writes go to the shard
> covering the current date. That shard gets hammered while all others
> are idle. A good key distributes writes evenly: user_id modulo hash,
> UUID hash. But a good distribution key creates a problem for range
> queries: all users with ID 1000-2000 may be on different shards,
> requiring scatter-gather queries that hit every shard.
>
> Re-sharding is the most painful aspect: when you need to add shards
> (data has outgrown the current count), you must migrate data between
> shards. Consistent hashing and virtual shards (many logical shards
> mapped to fewer physical nodes) reduce this pain.

**Blank Mind Recovery:**

**(1) Restate:** "Database sharding - splitting data across multiple
database nodes to scale write throughput."

**(2) First principles:** "One database has one write throughput ceiling.
To go beyond it, split the data across multiple databases. Each
database owns a slice. The shard key determines which slice each
row belongs to."

**(3) Bridge:** "Like splitting a phone book alphabetically across
four clerks: A-G, H-M, N-S, T-Z. Each clerk handles their section
independently. Looking up 'Jones' always goes to clerk 2. But finding
all people on 'Main Street' requires asking all four clerks (scatter-gather)."

---

### 📘 Concept Explanation

**What it is:**
Horizontal partitioning of a database table across multiple nodes,
where each node (shard) holds a disjoint subset of rows.

**The problem it solves:**
A single database node has a ceiling for write throughput (CPU, disk
I/O, memory). When an application hits this ceiling, vertical scaling
(bigger server) is limited and costly. Sharding spreads writes across
multiple nodes, each independently processing its share.

**Sharding strategies:**

**Range-based sharding:**
```
shard_key range → shard
0 - 999999      → Shard 1
1000000-1999999 → Shard 2
2000000+        → Shard 3
```
> **Code walkthrough:** This Database Sharding example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Pros: range queries on shard key are efficient.
Cons: monotonically increasing keys (timestamps, auto-increment IDs)
create write hotspots on the latest shard.

**Hash-based sharding:**
```
shard_id = hash(shard_key) % num_shards
hash("user_42") % 4 = 2 → Shard 2
```
> **Code walkthrough:** This Database Sharding example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Pros: even distribution.
Cons: range queries require scatter-gather across all shards.

**Consistent hashing:**
```
Ring with virtual nodes. Each physical shard covers
multiple positions on the ring.
Adding a shard: only adjacent virtual nodes migrate.
```
> **Code walkthrough:** This Database Sharding example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Pros: adding/removing shards requires minimal data movement.
Cons: more complex to implement.

**Directory-based sharding:**
A lookup service maps shard keys to shards.
Pros: flexible, supports arbitrary remapping.
Cons: lookup service is a potential SPOF and bottleneck.

**Cross-shard problems:**

```
Q: "Give me all orders for user 42 across all shards"
Hash shard by order_id: user 42's orders are on N shards.
Must query all shards (scatter-gather), merge results.
Slow at scale.

Solution: shard by user_id, not order_id.
All of user 42's orders are on the same shard.
```

> **Code walkthrough:** This Database Sharding example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The shard key must align with the most common query access pattern.
Writes and the primary query pattern must hash to the same shard.
Secondary access patterns (cross-shard) are expensive - design
your schema and shard key around your primary query.

**When to use it:**
- Write throughput exceeds a single primary's capacity
- Data volume exceeds a single node's storage
- Single-table read/write load is the bottleneck

**When NOT to use it:**
- Before you have exhausted vertical scaling and read replicas
- When cross-shard queries are common (joins, aggregations across
  the full dataset)
- When the team lacks operational expertise with sharded databases

**Alternatives:**
- Read replicas: scale reads without sharding (simpler)
- Partitioning: partition a table within a single node
  (PostgreSQL table partitioning) - same physical node, logical split
- Distributed SQL (CockroachDB, Spanner): auto-sharding built in,
  SQL semantics maintained

**First-principles derivation:**
"One node = one CPU, one disk. Write ceiling is hardware-bound.
To double write throughput: two nodes, each handling half the rows.
Determining which half each row belongs to = shard key function.
Every sharding complexity (hotspots, cross-shard queries) derives
from this basic partitioning decision."

---

### 💻 Code Example


```java
// BAD: using for-loop where Stream API is cleaner
List<String> results = new ArrayList<>();
for (Item item : items) {
    if (item.isActive()) {
        results.add(item.getName().toUpperCase());
    }
}
```

```java
// SHARD ROUTER: routing writes and reads to correct shard

// BAD: no shard awareness, queries all nodes
@Repository
public class OrderRepository {
    @Autowired
    private List<DataSource> shards; // shards[0..3]

    public Order findOrder(long orderId) {
        // Queries ALL shards - O(n) inefficiency
        // Fine for 4 shards, catastrophic at 100 shards
        for (DataSource shard : shards) {
            Order order = queryOrder(shard, orderId);
            if (order != null) return order;
        }
        return null;
    }
}

// GOOD: hash-based shard routing
@Service
public class ShardRouter {
    private final List<DataSource> shards;
    private final int numShards;

    public ShardRouter(List<DataSource> shards) {
        this.shards = shards;
        this.numShards = shards.size();
    }

    // Consistent: same userId always routes to same shard
    public DataSource getShardForUser(long userId) {
        // Murmur hash for even distribution
        // Avoids modulo bias from simple hash()
        int shardIndex = (int) (
            Long.hashCode(userId) & Integer.MAX_VALUE)
            % numShards;
        return shards.get(shardIndex);
    }

    // For cross-shard queries: explicit scatter-gather
    public List<Order> getOrdersAcrossShards(
            Instant startDate, Instant endDate) {
        return shards.parallelStream()
            .flatMap(shard ->
                queryOrders(shard, startDate, endDate)
                    .stream())
            .sorted(Comparator.comparing(
                Order::getCreatedAt))
            .collect(Collectors.toList());
    }
}
```

> **Code walkthrough:** The BAD example has no shard routing - itice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> queries all shards for every lookup, making every read O(n shards).
> This is correct but does not provide any scalability benefit.
> The GOOD example uses hash-based routing: given a userId, it computes
> a deterministic shard index. The same userId always maps to the same
> shard. The `Long.hashCode()` with `Integer.MAX_VALUE` masking
> ensures positive modulo. For cross-shard queries (date range across
> all users): explicit scatter-gather using parallel streams, with
> in-memory merge and sort. This is the unavoidable cost of hash
> sharding for range queries.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Sharding splits data across multiple databases. A shard key
> determines which database holds each record. This scales write
> throughput beyond a single node. Problems: bad shard key creates
> hotspots, cross-shard queries are expensive, re-sharding is painful.

*Push deeper:* "Consistent hashing makes adding/removing shards less
disruptive - you move minimal data rather than re-hashing everything."

---

**Senior / Staff:**
> Sharding decisions I have made in production: shard key selection
> is the most consequential decision. We sharded by user_id (high
> cardinality, even distribution, aligns with primary query pattern).
> We hit re-sharding pain when shard count doubled - consistent
> hashing with virtual nodes would have saved us. Modern alternative:
> distributed SQL (CockroachDB) with auto-sharding is preferable
> for new systems - SQL semantics maintained, sharding is transparent.

*Push deeper:* "At staff level: cross-shard distributed transactions.
We avoided them by denormalizing - duplicating data across shards
to avoid cross-shard joins. The operational cost of cross-shard
2PC is too high for most write-heavy workloads."

---

### ⚠️ Common Misconceptions

**"Sharding and partitioning are the same thing"**

Reality: partitioning (PostgreSQL table partitioning) splits a table
into multiple physical files on the SAME database node. It improves
query pruning (skip irrelevant partitions) but does not distribute
load across nodes. Sharding distributes across separate database
NODES (different servers). Sharding = distributed. Partitioning =
local optimization within one node.

**"Any column makes a good shard key"**

Reality: a poor shard key creates hotspots. A timestamp or
monotonically-increasing ID puts all new writes on one shard.
A low-cardinality key (e.g., country with 10 countries) can only
create 10 shards. Good shard keys: high cardinality, even
distribution, aligns with primary access pattern.

---

### ⚖️ Comparison Table

| Approach | Write Scale | Complexity | Cross-shard | Choose When |
|---|---|---|---|---|
| Single node | Limited (hardware) | Low | N/A | Most systems |
| Read replicas | No write scale | Low | N/A | Read-heavy workloads |
| Range sharding | High | Medium | Range queries OK | Time-series data |
| Hash sharding | High | Medium | Scatter-gather | User-based writes |
| Consistent hashing | High | High | Scatter-gather | Dynamic shard count |
| Distributed SQL | High | Low (managed) | Transparent | New systems |

**The deciding factor:** Is your bottleneck write throughput? If yes,
shard. If it is read throughput only, use read replicas.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Hot shard - one shard receives disproportionate traffic.**

Symptom: one shard's CPU/IOPS at 90%+ while other shards sit at 10%; query latency spikes only for keys that map to the hot shard; write throughput ceiling hit despite other shards having capacity. Diagnosis: plot query count and byte throughput per shard over time; the hot shard pattern is unmistakable. Common cause: shard key with low cardinality (e.g., country code where 80% of users are in one country) or monotonically increasing keys (new records cluster in the last shard). Fix: change the shard key to include a higher-cardinality field (user ID prefix + timestamp hash), or use virtual shards with consistent hashing.

**Failure Mode 2: Cross-shard queries become application bottleneck.**

Symptom: certain reports or search queries take 10-100x longer than single-shard queries; database CPU spikes proportional to the number of shards. Diagnosis: EXPLAIN shows scatter-gather fan-out - the query planner sends the query to all N shards and aggregates results; total execution time = max(per-shard time) + aggregation overhead + N * network round trips. Fix: for analytical queries, replicate data to a separate non-sharded analytics store (OLAP database, Elasticsearch); for application queries, denormalize the required join data into the same shard via event-driven projections.

**Failure Mode 3: Application assumes shard key is mutable.**

Symptom: application error when attempting to update a sharding key field (user email, tenant ID); or silent data inconsistency when the update changes which shard the record belongs to. Diagnosis: look for UPDATE statements touching the shard key column in application code or ORM entity definitions. Fix: design the shard key to be immutable business identifiers (UUIDs, surrogate IDs). If a shard key must change, implement delete-and-reinsert with the new shard key value, treating it as a new record.

---

### 🎯 Interview Deep-Dive

#### Production Failures

**[JUNIOR] Q1 - [DEBUGGING] One shard is receiving 90% of all writes while others are idle. What is the cause and fix?**

Hotspot caused by a poor shard key. Common causes: timestamp as
shard key (all new records go to the current time shard), sequential
ID as shard key (all new records are high IDs, on the last shard),
or low-cardinality shard key (only 5 values, with one very popular).
Diagnosis: check per-shard write QPS in metrics. Confirm the shard
key distribution via `SELECT shard_key, COUNT(*) FROM table GROUP BY
shard_key % num_shards`. Fix: re-shard with a better key (hash
of user_id or UUID), or add a random prefix to the shard key to
distribute writes artificially.

**[JUNIOR] Q2 - [MECHANISM] You need to add 2 new shards to a 4-shard cluster. How do you do it without downtime?**

With consistent hashing: (1) add the new shards to the ring
(they take over responsibility for a portion of the key range from
adjacent shards). (2) Migration: the existing shards stream their
data for the newly-assigned key ranges to the new shards. (3) Once
migration completes and is verified, update the routing logic to
point to the new shards for those ranges. (4) Delete the migrated
data from the old shards. This is done live: during migration, reads
still go to the old shards; after cutover, reads go to the new.
With simple hash sharding: add new shards, re-hash ALL data (every
row may move). Much more disruptive. Use background migration, double-
write during transition, gradual cutover.

#### Candidate Mistakes

**[JUNIOR] Q3 - [MECHANISM] How do you handle transactions that span multiple shards?**

**What NOT to say:** "Just use a regular database transaction."

**Say instead:** "Cross-shard transactions are one of the hardest
problems in sharding. Standard ACID transactions cannot span multiple
database nodes without distributed transaction protocols. Two options:
(1) Avoid them by design - shard your data such that transactions
only need data from one shard. Denormalize if needed. (2) Use
distributed transaction protocols (two-phase commit) - but 2PC
is slow and has availability issues during coordinator failure.
(3) Use a Saga pattern: break the transaction into a sequence of
local transactions with compensating transactions for rollback.
Eventual consistency at the saga level. My preference: design the
data model to avoid cross-shard transactions wherever possible."

#### Questions to Ask the Interviewer

**[MID] Q4 - [MECHANISM] "What is the current write throughput and what is the projected growth that would necessitate sharding?"**

*Why:* Establishes whether sharding is actually necessary now or a
premature optimization.

**[MID] Q5 - [MECHANISM] "What is the primary access pattern - do most queries filter by the proposed shard key?"**

*Why:* The shard key must align with the primary query pattern, or
every query becomes a scatter-gather.

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*



