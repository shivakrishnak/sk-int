---
layout: default
title: "NoSQL - L2 Column Family Stores"
parent: "NoSQL"
nav_order: 5
permalink: /nosql/l2-column-family-stores/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Apache Cassandra Architecture and Data Model](#apache-cassandra-architecture-and-data-model) | ★★☆ |
| 2 | [Cassandra Query Language and Partition Design](#cassandra-query-language-and-partition-design) | ★★☆ |

---

# Apache Cassandra Architecture and Data Model

---

### 🎯 Model Answer

**30 seconds:**
> Apache Cassandra is a distributed wide-column store with no single point of failure.
> Data is distributed across nodes using consistent hashing on a partition key. Every
> node is equal (no master); replication is configurable per keyspace. Writes are always
> fast (appended to a commit log and memtable); reads may require reading multiple SSTables.
> The data model is a table with a compound primary key: partition key (determines which
> node) + clustering columns (determines sort order within a partition).

**3 minutes (Senior):**
> Cassandra's architecture: a ring of N nodes, each owning a range of the token space
> (0 to 2^63). The partition key is hashed to a token; the node whose range includes
> that token stores the data. Replication factor (RF) determines how many nodes store
> each partition (usually RF=3). Consistency level is configurable per query: `ONE`
> (any one replica), `QUORUM` (majority of replicas), `ALL` (all replicas). `QUORUM`
> reads + `QUORUM` writes guarantee strong consistency (the read always sees the latest
> write). Writes: append to commit log (WAL) + memtable (in-memory); memtable flushes
> to SSTable (immutable files); SSTables are compacted periodically. Reads: check
> memtable + bloom filter + SSTables. The data model is explicitly query-driven:
> create one table per query pattern; each table has a partition key (row grouping) and
> optional clustering columns (sort within partition).

**Framework:** Partition Key -> Token -> Ring Node -> Replication Factor -> Consistency Level

**Blank Mind Recovery:**

**(1) Restate:** "Cassandra: distributed ring of nodes. Partition key hashed to token
-> routes to node. RF=3 copies. Consistency: QUORUM for strong. Write: commit log +
memtable -> SSTable. Design: one table per query."

**(2) First principles:** "Cassandra achieves high availability by having no master
node. Every node is equal. Data is automatically distributed and replicated. The price
is limited query flexibility: you must model your data around your queries."

**(3) Bridge:** "Cassandra is like a distributed filing cabinet where each drawer
(partition) is stored on 3 different filing clerks (nodes). To find something, you
must know which drawer it is in (partition key). You cannot ask 'show me all records
with blue color' unless 'color' determines which drawer to open."

---

### 📘 Concept Explanation

**Cassandra Ring Architecture:**

```text
CASSANDRA RING (RF=3, 4 nodes):

  Tokens: 0 to 2^63

       Node A (0 - 25%)
      /
  ---A---D---
  |       |
  B       C
  ---B---C---
      \
       Node B (25 - 50%)
       Node C (50 - 75%)
       Node D (75 - 100%)

  Partition key "user:123" -> hash -> token 0x1A3F
  -> falls in A's range -> primary on A
  -> RF=3: also stored on B and C (next ring nodes)

  CONSISTENCY LEVELS (RF=3):
    ONE:    read/write 1 replica (fastest, weakest)
    TWO:    read/write 2 replicas
    QUORUM: read/write 2 of 3 (RF/2+1=2) (balanced)
    ALL:    read/write 3 of 3 (slowest, strongest)
    LOCAL_QUORUM: quorum within local datacenter only
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Cassandra consistent hash ring with 4
> nodes, token ranges, replication factor 3, and consistency level options. (2) KEY
> MECHANISM: each partition key is hashed using the Murmur3 hash function to a token;
> the coordinator node (whichever receives the request) routes the write to the node
> owning that token range (the primary replica) and the next RF-1 nodes clockwise on the
> ring; all writes happen in parallel to all replicas. (3) WHY IT MATTERS: the ring
> design means adding a new node simply requires redistributing token ranges; there is no
> shard map or metadata server to update; Cassandra re-balances automatically via
> vnodes. (4) WHAT BREAKS: choosing a partition key with low cardinality (e.g., country
> code with 5 values) concentrates all writes to a small number of partitions; those
> partitions become "hot partitions" on specific nodes; the nodes become bottlenecks while
> other nodes are idle. (5) TAKEAWAY: the partition key must have high cardinality and
> uniform distribution; a good partition key is one that distributes writes evenly across
> all nodes, not one that naturally groups data for reporting.

**Write Path:**

```text
CASSANDRA WRITE PATH:

  Client Write
      |
  Coordinator Node
      |
  +---+---+---+
  |   |   |   |
 N1  N2  N3   (parallel to all RF nodes)
      |
  Each node:
    1. Append to Commit Log (WAL, durable)
    2. Write to Memtable (in-memory)
    3. Return ACK

  Async (background):
    Memtable full -> flush to SSTable (immutable)
    Multiple SSTables -> Compaction -> merged SSTable
    Old SSTables deleted after compaction

  Why writes are always fast:
    - Sequential disk write (commit log)
    - In-memory update (memtable)
    - No immediate read before write
    - No locking
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Cassandra write path from client to
> coordinator to all replica nodes, including the commit log, memtable, and SSTable
> flush. (2) KEY MECHANISM: the coordinator receives the write and fans it out to all
> RF replica nodes in parallel; each replica appends to its commit log first (ensuring
> crash recovery), then updates its in-memory memtable; the write is acknowledged when
> enough replicas confirm based on the consistency level. (3) WHY IT MATTERS: writes
> are always sequential appends (commit log, SSTable); there is no random I/O on the
> write path; this is why Cassandra sustains millions of writes per second; random I/O
> is reserved for reads. (4) WHAT BREAKS: if the memtable grows faster than it can be
> flushed to disk (disk too slow), the commit log keeps growing; eventually Cassandra
> throttles writes; a slow disk is the primary cause of write performance degradation.
> (5) TAKEAWAY: optimize Cassandra write performance by using fast SSDs for the
> commit log and data directories; the commit log should be on a separate disk from
> data files to avoid I/O contention between writes and compaction.

---

### 💻 Code Example

```python
from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider
from cassandra.policies import (
    DCAwareRoundRobinPolicy,
    TokenAwarePolicy
)
from cassandra import ConsistencyLevel
from cassandra.query import SimpleStatement

# Connect to Cassandra cluster
auth = PlainTextAuthProvider(
    username="cassandra",
    password="cassandra"
)
cluster = Cluster(
    contact_points=["cassandra1", "cassandra2"],
    auth_provider=auth,
    load_balancing_policy=TokenAwarePolicy(
        DCAwareRoundRobinPolicy(
            local_dc="us-east-1"
        )
    )
)
session = cluster.connect()

# Create keyspace (RF=3, NetworkTopologyStrategy)
session.execute("""
    CREATE KEYSPACE IF NOT EXISTS myapp
    WITH replication = {
      'class': 'NetworkTopologyStrategy',
      'us-east-1': 3,
      'us-west-2': 3
    } AND durable_writes = true
""")
session.set_keyspace("myapp")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: connecting to a Cassandra cluster with
> TokenAwarePolicy routing and creating a keyspace with NetworkTopologyStrategy
> replication. (2) KEY MECHANISM: `TokenAwarePolicy` routes queries directly to the
> node that owns the queried partition, avoiding an extra network hop through a
> coordinator; `DCAwareRoundRobinPolicy` ensures queries go to nodes in the local
> datacenter first; `NetworkTopologyStrategy` distributes replicas across datacenters
> independently, ensuring each DC has its own RF=3 replicas. (3) WHY IT MATTERS:
> `TokenAwarePolicy` reduces latency by eliminating the coordinator hop for most
> queries; for a query with a known partition key, the driver calculates the token and
> routes directly to the correct node. (4) WHAT BREAKS: `SimpleStrategy` replication
> distributes replicas on consecutive ring nodes without datacenter awareness; adding
> a second datacenter with SimpleStrategy puts replicas in suboptimal locations; always
> use NetworkTopologyStrategy for production. (5) TAKEAWAY: always use `TokenAwarePolicy`
> + `DCAwareRoundRobinPolicy` in production; always use `NetworkTopologyStrategy` for
> keyspace replication; these two decisions have the largest impact on Cassandra
> cluster performance.

```python
# Create table for user events (query-first design)
# Access pattern: "get last N events for user"
session.execute("""
    CREATE TABLE IF NOT EXISTS user_events (
        user_id   UUID,
        event_time TIMESTAMP,
        event_type TEXT,
        data       TEXT,
        PRIMARY KEY (user_id, event_time)
    ) WITH CLUSTERING ORDER BY (event_time DESC)
    AND compaction = {
      'class': 'TimeWindowCompactionStrategy',
      'compaction_window_unit': 'HOURS',
      'compaction_window_size': 1
    }
""")

# Insert events (always fast, append-only)
prepared_insert = session.prepare("""
    INSERT INTO user_events
        (user_id, event_time, event_type, data)
    VALUES (?, ?, ?, ?)
    USING TTL 2592000
""")
# TTL 2592000 = 30 days auto-deletion

from uuid import UUID
from datetime import datetime

session.execute(prepared_insert, [
    UUID("550e8400-e29b-41d4-a716-446655440000"),
    datetime.utcnow(),
    "login",
    '{"ip": "1.2.3.4", "device": "mobile"}'
])
```

> **Code walkthrough:** (1) WHAT IT SHOWS: creating a Cassandra table designed for the
> "get last N events for user" access pattern, with `user_id` as the partition key and
> `event_time` as the clustering column in descending order. (2) KEY MECHANISM: `user_id`
> as the partition key means all events for a user are stored together on the same node
> (and its RF-1 replicas); `event_time DESC` clustering means the newest events are
> first in the partition; `TimeWindowCompactionStrategy` is optimal for time-series
> data (groups SSTables by time window for efficient TTL-based deletion). (3) WHY IT
> MATTERS: the `DESC` clustering order means `SELECT ... LIMIT 10` returns the 10 most
> recent events without a sort; Cassandra reads the partition in the stored order; an
> `ASC` order would require scanning the entire partition for the 10 most recent. (4)
> WHAT BREAKS: using a non-prepared statement for repeated inserts forces Cassandra to
> parse the CQL string on every execution; always use `session.prepare()` for statements
> executed more than once; prepared statements are parsed once and cached. (5) TAKEAWAY:
> use `USING TTL` for time-series data with a natural expiry; Cassandra handles cleanup
> automatically; without TTL, partitions grow indefinitely and compaction slows down.

```python
# Read events (query matches table design exactly)
prepared_read = session.prepare("""
    SELECT event_time, event_type, data
    FROM user_events
    WHERE user_id = ?
    LIMIT 50
""")

quorum_stmt = SimpleStatement(
    prepared_read,
    consistency_level=ConsistencyLevel.QUORUM
)

# Execute with LOCAL_QUORUM for read-your-own-writes
rows = session.execute(
    prepared_read,
    [UUID("550e8400-e29b-41d4-a716-446655440000")]
)
for row in rows:
    print(row.event_time, row.event_type)

# BAD: allow filtering scans all partitions
# session.execute("""
#   SELECT * FROM user_events
#   WHERE event_type = 'login'
#   ALLOW FILTERING
# """)
# PROBLEM: full cluster scan; never use in production
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the correct read query that matches the table
> design (WHERE on partition key + optional clustering column range), and the BAD pattern
> of `ALLOW FILTERING` which performs a full cluster scan. (2) KEY MECHANISM: Cassandra
> can execute `WHERE user_id = ?` efficiently because `user_id` is the partition key;
> the coordinator knows exactly which node holds the partition; `LIMIT 50` returns
> the first 50 rows in the clustering order (most recent, because of `DESC` ordering).
> (3) WHY IT MATTERS: `ALLOW FILTERING` forces Cassandra to scan every partition on
> every node to find matches; on a large cluster with millions of partitions, this
> takes seconds to minutes and consumes enormous cluster resources; it is essentially
> a full table scan. (4) WHAT BREAKS: any WHERE clause on a non-partition-key, non-
> clustering-key column without `ALLOW FILTERING` raises an error; Cassandra refuses
> queries it cannot serve efficiently; this is a feature, not a bug - it prevents
> accidental full cluster scans. (5) TAKEAWAY: if your application needs a query that
> Cassandra refuses without `ALLOW FILTERING`, the answer is to create a new table
> designed for that query pattern, not to add `ALLOW FILTERING`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Cassandra is a distributed database with no master node. Data is distributed across
> nodes by hashing the partition key. Every partition is stored on RF nodes (usually 3).
> The data model is table-based, but each table is designed for one specific query. You
> cannot join tables; you cannot query by arbitrary fields; you must know the partition
> key for all reads. Writes are always fast (sequential appends). Reads may touch
> multiple SSTables. Use Cassandra for high-write, time-series, and event data.

---

**Senior / Staff (5+ years):**
> Cassandra architecture decisions that matter: (1) Partition key choice - must have
> high cardinality and uniform distribution; bad partition keys create hot nodes; (2)
> Consistency level - `LOCAL_QUORUM` for strong consistency within a datacenter;
> `QUORUM` only if cross-DC consistency is needed (adds latency); (3) Compaction
> strategy - STCS for write-heavy random data, TWCS for time-series, LCS for read-
> heavy; (4) Partition size - keep partitions under 100 MB; large partitions cause
> read and compaction bottlenecks; use a composite partition key (add a bucket field)
> to split large partitions; (5) Tombstones - deletes generate tombstones; too many
> uncompacted tombstones slow reads; TWCS + TTL is the correct pattern for time-series
> data cleanup.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Cassandra is eventually consistent, so I cannot use it for strong consistency."**

Cassandra's consistency model is tunable per query. With `QUORUM` reads and `QUORUM`
writes on a cluster with RF=3, strong consistency is guaranteed: the read will see the
latest write because any two QUORUM operations must overlap on at least one replica.
The "eventual consistency" reputation refers to the behavior with lower consistency
levels (ONE/TWO), which is appropriate for use cases where eventual consistency is
acceptable (social media likes, view counts).

**Misconception 2: "Deletes in Cassandra free up space immediately."**

Cassandra uses tombstones for deletes. A tombstone is a marker that records the
deletion time; the data is not removed immediately. Tombstones are visible during reads
and count toward the query cost. Actual data removal happens during compaction. Until
compaction runs and the `gc_grace_seconds` (default: 10 days) expires, the deleted data
still occupies disk space. High tombstone rates (millions per partition) cause read
timeouts; use TTL for time-bounded data cleanup instead of explicit deletes.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Hot partition causing node bottleneck.**

Symptom: one node has significantly higher CPU and write latency than others; `nodetool
tpstats` shows write backpressure on one node.
Root cause: low-cardinality partition key (e.g., `date` as partition key) concentrates
all writes for a day to one partition on one node.
Diagnosis: `nodetool cfhistograms` to see partition size distribution; large maximum
partition size confirms the issue.
Fix: redesign the partition key with a higher-cardinality component (add user_id or a
hash bucket prefix); or add a "bucket" field: `date + bucket_id` where bucket_id is
`hash(user_id) % 20` to distribute one day's data across 20 partitions.

**Failure Mode 2: Read timeout due to tombstone accumulation.**

Symptom: reads return `ReadTimeoutException`; warning logs show "Scanned over X
tombstones during query".
Root cause: many delete operations created tombstones; compaction has not run to clean
them up; reads must scan through tombstones to find live data.
Diagnosis: `nodetool cfstats` to check `Live SS Table Count` and
`SSTables Scanned per Read`; high values indicate compaction backlog.
Fix: run `nodetool compact keyspace table` to force compaction; review tombstone
threshold settings; switch to TTL-based deletion for time-series data.

---

### ⚖️ Comparison Table

| Feature | Cassandra | MongoDB | Redis | HBase |
|---|---|---|---|---|
| **Data Model** | Wide-column | Document | Key-value | Wide-column |
| **Write Speed** | Excellent | Good | Excellent | Good |
| **Query Flexibility** | Low (partition key required) | High | Very Low | Low |
| **Consistency** | Tunable (QUORUM=strong) | Tunable (w:majority=strong) | Single-node strong | Strong |
| **Scaling** | Linear, masterless | Primary bottleneck | Cluster mode | HMaster coordinator |
| **Best For** | Time-series, events, IoT | General-purpose, documents | Caching, sessions | Hadoop-integrated analytics |

---

### 🏛️ System Design

*(Omit: L2 keyword; Cassandra production architecture in L4 entries.)*

---

### 📊 Diagram

```text
CASSANDRA READ PATH (RF=3, QUORUM):

  Client Query: SELECT WHERE user_id = 'u1'
        |
  [Coordinator Node]
        |
    hash(user_id) -> Token -> Node A is owner
        |
  +-----+-----+
  |     |     |
 [A]   [B]   [C]     (RF=3 replicas, parallel)
  |     |     |
  Check:
    memtable -> bloom filter -> SSTable

  QUORUM: wait for 2 of 3 responses
  If A responds with v2, B responds with v1
  -> Read repair: coordinator sends v2 to B
  -> Returns v2 to client (newest)

  Bloom filter: probabilistic check to skip
  SSTables that do not contain the partition
  False positive -> unnecessary SSTable read
  False negative -> impossible (never misses)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the Cassandra read path from client to
> coordinator to the three replica nodes, including the read-repair process when replicas
> have different versions of the data. (2) HOW TO READ IT: the coordinator routes the
> read to all RF nodes in parallel; each node checks its memtable first, then uses the
> bloom filter to skip SSTables that cannot contain the partition, then reads any matching
> SSTables; the coordinator waits for QUORUM responses and returns the newest version
> while triggering read-repair on stale replicas. (3) KEY RELATIONSHIP: QUORUM reads
> + QUORUM writes guarantee strong consistency because any QUORUM write (2 of 3) and
> any QUORUM read (2 of 3) must overlap on at least one replica; that replica has the
> latest data. (4) EDGE CASE: the bloom filter has a configurable false positive rate;
> a high false positive rate causes unnecessary SSTable reads; a very low false positive
> rate requires more memory for the bloom filter; tune `bloom_filter_fp_chance` per
> table based on read patterns and available memory. (5) INSIGHT: a senior engineer
> notices that the read path is significantly more complex than the write path; Cassandra
> optimizes for writes at the cost of read complexity; this is why Cassandra is most
> appropriate for write-heavy workloads and why read performance degrades as the number
> of SSTables grows before compaction.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Ring architecture, write path |
| Mechanism | 2 | Consistent hashing, SSTable |
| Application | 2 | Partition key design, consistency levels |
| Trade-off | 2 | Vs MongoDB, tunable consistency |
| Scenario | 1 | Hot partition diagnosis |

---

**[MID] Q1 (Definition): How does Cassandra distribute data across nodes?**

Cassandra uses consistent hashing on a ring. The entire token space (0 to 2^63 for
Murmur3 partitioner) is divided into ranges, one range per node (or virtual node/vnode).

When a partition key is written or read:
1. The partition key is hashed using Murmur3 to produce a token.
2. The coordinator node (whichever received the request) calculates which node owns the
   token range containing that token.
3. The write is sent to the primary replica node and the next RF-1 nodes clockwise on
   the ring (the replicas).
4. All RF nodes receive the write in parallel.

Virtual nodes (vnodes): by default, each Cassandra node owns 256 virtual token ranges
distributed around the ring. Vnodes allow new nodes to take responsibility for many
small ranges instead of one large contiguous range; this means adding a new node
redistributes data more evenly without a single "rebalancing" node.

The ring design means: any node can be the coordinator for any query; there is no
routing table to maintain; adding/removing nodes only affects the nodes adjacent on
the ring.

*What separates good from great:* The token awareness implication for hotspots. With
vnodes, Cassandra distributes the token space evenly across nodes. However, if the
partition key distribution is skewed (e.g., partition key is user_id and 1% of users
generate 50% of writes), the nodes holding those users' token ranges become hot spots.
Consistent hashing distributes partitions evenly; it does not distribute data volume
evenly if partition sizes are unequal. Choose partition keys where both partition count
AND data volume per partition are uniform.

---

**[MID] Q2 (Application): What is Cassandra's consistency level and how do you choose between ONE, QUORUM, and ALL?**

Consistency level controls how many replica nodes must acknowledge a read or write
before the operation is considered successful.

`ONE`: one replica must acknowledge. Fastest; lowest durability. The write could be
on only one of three replicas if the other two are slow; if that one node fails before
replication, the write is lost. Reads may return stale data if the fastest replica has
not yet received the latest write.

`QUORUM` (RF/2 + 1): a majority of replicas must acknowledge. With RF=3, 2 replicas
must respond. The intersection of any QUORUM write and QUORUM read must overlap on at
least one replica; strong consistency is guaranteed. The latency is bounded by the
second-fastest replica response time.

`ALL`: all RF replicas must acknowledge. Strongest consistency; highest availability
cost. If any replica is unavailable, the operation fails. Only use when every replica
must have the data (specific audit or compliance scenarios).

`LOCAL_QUORUM`: quorum within the local datacenter only. Used in multi-datacenter
deployments where writes are acknowledged locally without waiting for cross-DC
replication. This is the standard choice for multi-DC deployments.

Typical production configuration: writes at `LOCAL_QUORUM`, reads at `LOCAL_QUORUM`
for user-facing data; `ONE` for analytics and non-critical reads.

*What separates good from great:* The consistency level as a per-query setting.
Cassandra consistency level is configured per query (not per connection or per table).
This means the same application can use `LOCAL_QUORUM` for critical reads and `ONE`
for bulk analytics reads in the same codebase. This granularity allows trading off
consistency and latency at the query level; a wise use is applying `ONE` to analytics
queries that can tolerate stale data, preserving cluster capacity for the
`LOCAL_QUORUM` user-facing queries.

---

**[SENIOR] Q3 (Mechanism): Explain Cassandra's compaction process and why it matters for read performance.**

Cassandra's write path produces SSTable files (immutable). Multiple SSTables accumulate
over time: new writes, flushes from memtable, and updates all produce new SSTables.
Because data is immutable, an "update" in Cassandra is a new row with a newer timestamp;
both the old and new versions exist in separate SSTables until compaction.

Why compaction matters for reads: a read for a partition may need to check multiple
SSTables to find all versions of a row and determine the latest value. As SSTables
accumulate, read performance degrades (more files to check).

Compaction strategies:

Size-Tiered Compaction Strategy (STCS): merges SSTables of similar size. Good for
write-heavy workloads. Can temporarily double disk usage during compaction. Default.

Leveled Compaction Strategy (LCS): organizes SSTables into levels; each level is 10x
the size of the previous. After compaction, each partition exists in exactly one SSTable
per level. Excellent read performance; higher write amplification (data written multiple
times as it moves through levels).

TimeWindow Compaction Strategy (TWCS): groups SSTables by time window. Compacts
SSTables within the same time window; never merges windows. Ideal for time-series
data with TTL: expired time windows compact to empty and are deleted cleanly. Prevents
mixing old and new data in the same SSTable (which would prevent TTL cleanup).

*What separates good from great:* The compaction strategy selection impact. Choosing
STCS for a time-series workload leads to the "compaction write amplification trap":
old data (should be expired by TTL) is mixed with new data in the same large SSTABLE
after STCS compaction; the TTL cannot clear the old data until the entire SSTable's
data expires; disk usage grows continuously. TWCS solves this by keeping time windows
separate; when a window's data expires, the entire SSTable can be deleted. For any
time-series workload with TTL, TWCS is non-negotiable.

---

**[SENIOR] Q4 (Trade-off): How does Cassandra compare to MongoDB for an IoT time-series workload?**

IoT time-series requirements:
- Very high write throughput (millions of sensor readings per second).
- Time-range queries (get all readings for sensor X in the last hour).
- Automatic expiry of old data (30-day TTL).
- High availability (cannot lose readings).
- Linear scalability (write volume grows with sensor count).

Cassandra advantages for this workload:
- Write throughput: Cassandra sustains millions of writes per second without
  performance degradation; sequential commit log + memtable write path.
- Time-series table design: `PRIMARY KEY (sensor_id, reading_time)` with `DESC`
  clustering supports efficient range queries by sensor + time.
- TTL: native TTL per row; TWCS compaction cleans up expired data efficiently.
- Linear scaling: adding nodes increases write throughput proportionally.

MongoDB alternatives:
- Time-series collections (MongoDB 5.0+): columnar storage, automatic bucketing,
  efficient range queries; writes are good but not as fast as Cassandra at extreme
  scale.
- Manual bucket pattern: similar to Cassandra's approach but in MongoDB; manageable
  for moderate scale.

Decision:
- Choose Cassandra for: > 100,000 writes/second, need for linear write scaling,
  existing Cassandra operational experience.
- Choose MongoDB for: < 100,000 writes/second, mixed workload (IoT + document queries),
  team familiar with MongoDB, simpler operational model.

*What separates good from great:* The operational cost comparison. Cassandra requires
careful partition key design, consistency level management, and compaction strategy
selection; mistakes are costly (hot partitions, tombstone accumulation, compaction
storms). MongoDB's time-series collections abstract these concerns; the operational
complexity is lower. For a team without Cassandra expertise, MongoDB time-series may
be the better choice even at moderate scale where Cassandra would technically outperform.

---

**[SENIOR] Q5 (Application): How do you design a Cassandra partition key to avoid hot partitions?**

A hot partition occurs when a small number of partitions receive a disproportionate
share of reads or writes. The node holding those partitions becomes a bottleneck.

Causes:
- Low-cardinality partition key (day, country, status - only a few distinct values).
- Skewed distribution (a few "celebrity" users with vastly more activity than average).

Detection: `nodetool tablestats` shows partition size distribution; `nodetool cfhistograms`
shows the 75th/90th/99th percentile partition sizes; a large 99th percentile with a small
average indicates hot partitions.

Solutions:

1. Add cardinality with a time bucket:
   Instead of `date` as partition key (one hot partition per day), use
   `(date, bucket)` where bucket is `hash(user_id) % 20`; 20 partitions per day,
   distributed across nodes.

2. Use a more granular time unit:
   Instead of `date`, use `date_hour`; this creates 24 partitions per day instead
   of 1; each partition is 1/24 the size.

3. Add a bucket suffix:
   For celebrity users with extreme write rates, append a random bucket number
   (0-9) to the user_id partition key; distribute writes round-robin across the 10
   partitions; reads query all 10 partitions and merge results.

*What separates good from great:* The partition size limit. Cassandra's soft limit for
partition size is 100 MB; beyond this, compaction and repair become slow and may
cause GC pauses. For time-series data, calculate the expected partition size:
`partition_size = writes_per_second * record_size_bytes * seconds_per_time_unit`.
For 1000 writes/second, 200 bytes per record, hourly buckets: 1000 * 200 * 3600 =
720 MB per hour per sensor - far too large. Use minute-level buckets: 1000 * 200 * 60
= 12 MB per minute per sensor - acceptable. Partition size calculation must be done
before deploying to production; it is very difficult to re-partition an existing table.

---

**[SENIOR] Q6 (Mechanism): What are tombstones in Cassandra and how do they affect performance?**

A tombstone is a deletion marker. When a row or cell is deleted in Cassandra, the
delete is not applied immediately; instead, a tombstone (a special marker with the
deletion timestamp) is written to the commit log and SSTable. The original data remains
on disk until compaction.

Why tombstones exist: Cassandra is a distributed system; if a node is down when a
delete is applied, it must receive the deletion when it rejoins. The tombstone acts as
a distributed delete notification that persists until it is certain all replicas have
received it (determined by `gc_grace_seconds`, default: 10 days).

Impact on reads: when Cassandra reads a partition, it must scan all SSTables including
tombstones to determine the current state of each row. Each tombstone adds to the scan
cost. Millions of tombstones per partition cause reads to time out (`ReadTimeoutException`)
because the coordinator must scan them all before returning results.

Warning threshold: Cassandra logs a warning when more than 1,000 tombstones are scanned
per read. The read will fail if more than 100,000 tombstones are scanned (configurable).

Prevention:
- Use TTL instead of explicit deletes for time-bounded data; TTL-expired data
  is handled via TWCS compaction without creating tombstones.
- Use TWCS compaction for time-series data; old time windows are dropped entirely.
- Minimize range deletes; prefer row TTL over deleting individual columns.

*What separates good from great:* The `gc_grace_seconds` tuning. The default of 10 days
means tombstones persist for 10 days before compaction can remove them. In a heavily
write-heavy system with many deletions, this can accumulate billions of tombstones. For
systems with short delete-to-compact cycles (all nodes always up, compaction runs daily),
reducing `gc_grace_seconds` to 1-2 days reduces tombstone accumulation. The trade-off:
if a node is down for longer than `gc_grace_seconds`, it can miss tombstones and
"resurrect" deleted data; ensure node downtime is always shorter than `gc_grace_seconds`.

---

**[SENIOR] Q7 (Scenario): A Cassandra cluster has one node with 3x higher CPU than others. What do you do?**

This is a hot partition scenario.

Diagnosis:

Step 1 - Confirm the imbalance with `nodetool tpstats`:

```bash
nodetool tpstats -H NODE_IP
# Check: WriteStage pending tasks
# vs other nodes; 3x pending = hot node
```

> **Code walkthrough:** (1) WHAT IT SHOWS: checking the WriteStage pending tasks per node to confirm write imbalance. (2) KEY MECHANISM: `nodetool tpstats` shows thread pool statistics for each node; the WriteStage queue shows how many write requests are waiting; a node with 3x more pending tasks than others is receiving disproportionate write traffic. (3) WHY IT MATTERS: identifying the imbalanced node is the first step; without this confirmation, you cannot distinguish a hot partition from a general performance issue. (4) WHAT BREAKS: `nodetool` requires access to the node via JMX; firewalls blocking port 7199 prevent `nodetool` from running remotely. (5) TAKEAWAY: run `nodetool tpstats` on all nodes and compare; significant difference in WriteStage pending tasks confirms a hot partition.

Step 2 - Identify hot partitions with `nodetool tablestats`:

```bash
nodetool tablestats myapp.user_events
# Check: Maximum partition size vs Mean
# 100:1 max:mean ratio = hot partitions
```

> **Code walkthrough:** (1) WHAT IT SHOWS: checking partition size statistics for a specific table to confirm hot partitions. (2) KEY MECHANISM: `tablestats` reports the minimum, maximum, mean, and standard deviation of partition sizes; a maximum partition 100x larger than the mean indicates one or a few hot partitions. (3) WHY IT MATTERS: large partitions cause read and compaction slowdowns; the `Maximum` partition size shows the worst-case partition; anything above 100 MB requires investigation. (4) WHAT BREAKS: `tablestats` reports sizes at the time of the last compaction; very recent writes may not be reflected until the next memtable flush. (5) TAKEAWAY: combine `tpstats` (write imbalance) and `tablestats` (partition size) to confirm and quantify a hot partition; both together provide the evidence needed for a schema redesign decision.

Step 3 - Find which partition keys are hot:
Enable Cassandra's `nodetool toppartitions` (4.0+) or use the client-side slow query
log to identify which partition key values produce the largest or most-queried partitions.

Step 4 - Root cause analysis:
- Low-cardinality key: partition key has very few distinct values.
- Celebrity user: specific high-traffic users causing write concentration.
- Time-based key: partition key is a date/hour with high volume within one period.

Remediation:
- Add a bucket component to the partition key to split hot partitions.
- This requires creating a new table with the updated schema and migrating data.
- For emergency relief: move the hot partition key's token range to a temporary node
  using Cassandra's vnodes rebalancing.

*What separates good from great:* The proactive partition size monitoring. Set alerts on
partition size metrics using nodetool or JMX before a hot partition causes a production
incident. A partition growing beyond 50 MB should trigger investigation (the target is
<10 MB for healthy performance). By monitoring partition size trends, you can identify
and fix a growing hot partition before it impacts users.

---

---

# Cassandra Query Language and Partition Design

---

### 🎯 Model Answer

**30 seconds:**
> CQL (Cassandra Query Language) looks like SQL but behaves differently. Tables have a
> mandatory partition key in `PRIMARY KEY`; all queries MUST include the partition key
> in the WHERE clause. Clustering columns (the rest of the primary key) can be used for
> range queries and ordering. CQL forbids arbitrary filtering (no WHERE on non-key
> columns without `ALLOW FILTERING`). The design principle: create a table per query
> pattern, not normalize as in SQL.

**3 minutes (Senior):**
> CQL table design starts from the access pattern. For each query the application needs,
> design a table: the WHERE clause fields become the partition key (equality) and
> clustering columns (range); the ORDER BY field becomes the clustering column order.
> A data model in Cassandra often has 3-5x more tables than the equivalent SQL model,
> with data duplicated across tables for different access patterns. Key CQL patterns:
> `PARTITION KEY (field)` for single-field partitioning; `PARTITION KEY (f1, f2)` for
> composite partitioning; clustering columns `WITH CLUSTERING ORDER BY (c1 ASC, c2 DESC)`
> for ordering. Secondary indexes (materialized views) are available but have limitations:
> they are local per node (not global), add write overhead, and should be avoided for
> high-cardinality queries. For multiple access patterns on the same data, use Apache
> Spark + Cassandra or duplicate into multiple tables.

**Framework:** Query -> WHERE Clause -> Partition Key (equality) -> Clustering Columns (range/order) -> Table

**Blank Mind Recovery:**

**(1) Restate:** "CQL: SQL-like syntax but WHERE must include partition key. No arbitrary
filtering. Design: one table per query. Partition key = equality fields. Clustering columns
= range fields and ordering."

**(2) First principles:** "Cassandra can only query data it has co-located (same partition).
The partition key determines co-location. Any query that requires scanning multiple
partitions is a full cluster scan - forbidden. Design tables so every query hits one
partition."

**(3) Bridge:** "CQL table design is like designing a filing cabinet specifically for
one question. The partition key is the cabinet number; the clustering columns are the
folder tabs within. To answer a different question, you need a different filing cabinet
(different table). SQL has one universal cabinet with a universal search; Cassandra has
specialized cabinets per question."

---

### 📘 Concept Explanation

**CQL Primary Key Design Rules:**

```text
CQL PRIMARY KEY STRUCTURE:

  PRIMARY KEY (partition_key)
  - All data with same partition_key on same node
  - Queries MUST include partition_key in WHERE

  PRIMARY KEY (partition_key, clustering_col1)
  - partition_key: determines node (equality)
  - clustering_col1: sort order within partition
    (supports = and range: >, <, BETWEEN)

  PRIMARY KEY ((p1, p2), c1, c2)
  - Composite partition key: (p1, p2) together
    determine the node
  - c1, c2: clustering columns
  - WHERE must include p1=? AND p2=?

  TABLE DESIGN EXAMPLES:

  Query 1: "Get user by email"
  PRIMARY KEY (email)  -- email is partition key
  -> WHERE email = 'alice@...'  -- exact match

  Query 2: "Get N most recent posts by user"
  PRIMARY KEY (user_id, post_time)
  WITH CLUSTERING ORDER BY (post_time DESC)
  -> WHERE user_id = ? LIMIT 10

  Query 3: "Get orders by user in date range"
  PRIMARY KEY (user_id, order_date)
  -> WHERE user_id = ? AND order_date > ?
     AND order_date < ?
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the three primary key structures in CQL and
> concrete table design examples showing how query patterns map to primary key choices.
> (2) KEY MECHANISM: the partition key is hashed to determine which node stores the data;
> all rows with the same partition key are stored together on the same node (and its
> replicas) sorted by clustering columns; Cassandra can serve `WHERE partition_key = ?`
> with a single node lookup. (3) WHY IT MATTERS: designing the partition key based on
> the query's equality filter guarantees single-partition access for that query; any
> query that requires scanning multiple partitions requires `ALLOW FILTERING` or an
> anti-pattern approach. (4) WHAT BREAKS: using a timestamp as the partition key
> (`created_at` date) results in all writes for the same day going to one partition
> (hot partition); add user_id or a bucket field to the partition key to distribute the
> data across partitions. (5) TAKEAWAY: for every application query, write it out in
> natural language, identify the equality filters (partition key candidates), the range
> filters and ordering (clustering column candidates), and design the table accordingly.

---

### 💻 Code Example

```python
from cassandra.cluster import Cluster
from cassandra.query import PreparedStatement

session = Cluster(["cassandra1"]).connect("myapp")

# EXAMPLE 1: Messages by conversation
# Access pattern: "get messages in a conversation,
# sorted by time, most recent first"
session.execute("""
    CREATE TABLE messages (
        conversation_id UUID,
        message_time    TIMESTAMP,
        sender_id       UUID,
        content         TEXT,
        PRIMARY KEY (conversation_id, message_time)
    ) WITH CLUSTERING ORDER BY (message_time DESC)
    AND compaction = {
      'class': 'TimeWindowCompactionStrategy',
      'compaction_window_unit': 'DAYS',
      'compaction_window_size': 7
    }
    AND default_time_to_live = 2592000
""")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a messages table designed for the "get
> messages in a conversation" query, using `conversation_id` as the partition key and
> `message_time` as the clustering column in descending order. (2) KEY MECHANISM: all
> messages for a conversation are co-located in one partition; `DESC` ordering means the
> most recent messages are at the start of the partition; `LIMIT N` returns the N most
> recent messages without scanning the full partition; `default_time_to_live = 2592000`
> (30 days) automatically expires messages. (3) WHY IT MATTERS: this design serves the
> most common messaging app query (get recent messages) in a single partition read; the
> `LIMIT` clause is efficient because Cassandra stops reading after N records in the
> clustered order. (4) WHAT BREAKS: if a conversation has millions of messages (no TTL
> cleanup), the partition size grows without bound; the TTL and TWCS compaction work
> together to prevent this. (5) TAKEAWAY: always set TTL for time-series messaging data;
> use TWCS compaction to efficiently clean up expired time windows.

```python
# EXAMPLE 2: Query access pattern mismatch -> new table
# Need: "find all messages by sender_id globally"
# BAD: ALLOW FILTERING (full cluster scan)
# session.execute("""
#   SELECT * FROM messages
#   WHERE sender_id = ?
#   ALLOW FILTERING
# """)

# GOOD: Create a second table for this query pattern
session.execute("""
    CREATE TABLE messages_by_sender (
        sender_id       UUID,
        message_time    TIMESTAMP,
        conversation_id UUID,
        content         TEXT,
        PRIMARY KEY (sender_id, message_time)
    ) WITH CLUSTERING ORDER BY (message_time DESC)
""")

# Write to BOTH tables on insert
prepared_msg = session.prepare("""
    INSERT INTO messages
        (conversation_id, message_time,
         sender_id, content)
    VALUES (?, ?, ?, ?)
""")
prepared_by_sender = session.prepare("""
    INSERT INTO messages_by_sender
        (sender_id, message_time,
         conversation_id, content)
    VALUES (?, ?, ?, ?)
""")

from uuid import uuid4
from datetime import datetime

conv_id = uuid4()
sender = uuid4()
msg_time = datetime.utcnow()
content = "Hello, world!"

# Execute both inserts (or use a BATCH for atomicity)
session.execute(
    prepared_msg,
    [conv_id, msg_time, sender, content]
)
session.execute(
    prepared_by_sender,
    [sender, msg_time, conv_id, content]
)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the Cassandra "denormalization" pattern where
> the same message data is written to two tables - one partitioned by conversation (for
> "get conversation messages") and one by sender (for "get messages by user") - and the
> write path that keeps both tables synchronized. (2) KEY MECHANISM: Cassandra's query
> model requires that every query's WHERE clause matches the partition key; since one
> query partitions by conversation and another by sender, two separate tables are needed;
> both are written on every message insert. (3) WHY IT MATTERS: this duplication is
> intentional and correct in Cassandra; the alternative (`ALLOW FILTERING` or secondary
> indexes) performs poorly at scale; duplicating writes is the standard Cassandra pattern
> for multiple access patterns. (4) WHAT BREAKS: if the two tables diverge (e.g., the
> second insert fails), the data is inconsistent; use a Cassandra `BATCH` statement for
> atomicity or use an idempotent retry mechanism; note that a Cassandra `LOGGED BATCH`
> adds overhead and should only be used when multi-partition atomicity is required. (5)
> TAKEAWAY: in Cassandra, "one table per query pattern" is the correct design; accept
> data duplication as the price of high write throughput and query performance; design
> the write path to keep all tables in sync.

```python
# EXAMPLE 3: Secondary index (when acceptable)
# Secondary indexes are LOCAL per node, not global
# Acceptable for: low-cardinality, low-throughput queries

session.execute("""
    CREATE TABLE users (
        user_id  UUID PRIMARY KEY,
        email    TEXT,
        country  TEXT,
        tier     TEXT
    )
""")

# Secondary index on country (low cardinality)
# OK because: few queries, few distinct values
session.execute("""
    CREATE INDEX ON users (country)
""")

# BAD: secondary index on email (high cardinality)
# creates one index entry per user; each read
# queries ALL nodes; O(N_nodes) instead of O(1)
# GOOD: create a separate lookup table:
session.execute("""
    CREATE TABLE users_by_email (
        email    TEXT PRIMARY KEY,
        user_id  UUID
    )
""")
# Look up user_id, then fetch full user by user_id
```

> **Code walkthrough:** (1) WHAT IT SHOWS: when a secondary index is acceptable (low-
> cardinality, low-traffic queries like country lookup) vs when to use a lookup table
> (high-cardinality fields like email). (2) KEY MECHANISM: Cassandra secondary indexes
> are "local" - each node maintains an index only for the data it owns; a query using
> a secondary index must be broadcast to ALL nodes to find all matches; this is O(N_nodes)
> and not suitable for high-traffic queries. (3) WHY IT MATTERS: a secondary index on
> email effectively performs a full cluster scan on every email lookup; for an application
> that looks up users by email millions of times per day, this saturates the cluster. (4)
> WHAT BREAKS: using a secondary index for a high-cardinality column under load causes
> cluster-wide read pressure; every secondary index read broadcasts to all nodes;
> N concurrent reads * M nodes = N*M queries. (5) TAKEAWAY: use secondary indexes only
> for administrative/low-frequency queries on low-cardinality columns; for any query
> that runs frequently, create a dedicated table with the query field as the partition key.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> CQL looks like SQL but has a critical difference: WHERE clauses must include the
> partition key. You cannot query by arbitrary fields (without `ALLOW FILTERING` which
> is a full cluster scan). The solution is "one table per query": if you need to find
> messages by conversation and also by sender, you create two tables with different
> partition keys and write to both. Data is duplicated but queries are always fast.

---

**Senior / Staff (5+ years):**
> CQL design decisions that matter: (1) Partition key - must be the equality filter
> in the most common query; must have high cardinality; composite partition key
> `(user_id, date_bucket)` to split high-volume users; (2) Clustering columns -
> the range filter and ordering fields; the `WITH CLUSTERING ORDER BY` determines
> whether `LIMIT N` is efficient (reads N records) or requires scanning the full
> partition; (3) Table proliferation - Cassandra models often have 10-20+ tables for
> a domain; this is expected and correct; document the query-to-table mapping; (4)
> Write amplification - N tables means N writes per application write; measure and
> monitor write throughput accounting for all tables; (5) Materialized views - avoid;
> they have severe operational issues in Cassandra (out-of-sync, repair complexity).

---

### ⚠️ Common Misconceptions

**Misconception 1: "Cassandra secondary indexes are equivalent to SQL secondary indexes."**

SQL secondary indexes are global B-tree structures that efficiently find rows by any
indexed field. Cassandra secondary indexes are local per node: each node maintains an
index only for its own data. A query using a secondary index broadcasts to all nodes
and collects results from each. For a 20-node cluster, every secondary index read
becomes 20 parallel node queries. For low-traffic queries, this is acceptable. For
high-traffic queries, it saturates the cluster. Use dedicated lookup tables instead.

**Misconception 2: "Cassandra BATCH statements improve performance."**

In SQL, batching multiple inserts in one transaction improves performance by reducing
round-trips. In Cassandra, `LOGGED BATCH` has overhead: the coordinator writes the
batch log to two nodes before executing, ensuring atomicity across partitions. For
multi-partition batches, this adds latency and load. Use batches only when cross-partition
atomicity is required (rare). For bulk loading, use token-aware driver sessions and
parallel async inserts, not batch statements.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: "Cannot execute this query as it might involve data filtering" error.**

Symptom: application receives `InvalidRequest: Cannot execute this query as it might
involve data filtering and thus may have unpredictable performance`.
Root cause: the WHERE clause filters on a non-partition-key, non-clustering-key column
without `ALLOW FILTERING`; Cassandra refuses because it cannot execute the query
efficiently.
Fix: Do NOT add `ALLOW FILTERING`. Instead: (1) redesign the table with the filter
field as the partition key; (2) create a separate lookup table; (3) if the query is
truly low-frequency/administrative, add `ALLOW FILTERING` with explicit documentation
of the performance implication.

**Failure Mode 2: Large partitions causing read and repair timeouts.**

Symptom: queries against specific partition key values time out; `nodetool repair` fails
with timeout on specific partitions; `nodetool cfhistograms` shows maximum partition
size in gigabytes.
Root cause: partition has grown beyond the recommended 100 MB limit due to unbounded
data accumulation (missing TTL, bad bucket strategy).
Fix: emergency - increase read timeout and run `nodetool compact` for the specific
table; long-term - redesign the partition key to include a time bucket, add TTL to
new inserts, and migrate existing data to the new schema.

---

### ⚖️ Comparison Table

| Aspect | Cassandra CQL | SQL |
|---|---|---|
| **Query flexibility** | WHERE must include partition key | Any WHERE clause |
| **Joins** | Not supported (no cross-partition) | Supported |
| **Secondary index** | Local per node (limited) | Global B-tree (flexible) |
| **Design approach** | Query-first (one table per query) | Data-first (normalize then join) |
| **Data duplication** | Intentional (multiple tables) | Avoided (normalization) |
| **Sort on write** | Yes (clustering order fixed) | No (sort at read time) |

---

### 🏛️ System Design

*(Omit: L2 keyword; CQL design at scale covered in L3 entries.)*

---

### 📊 Diagram

```text
CQL QUERY-TO-TABLE MAPPING:

  APPLICATION QUERIES:
  Q1: "Get messages in conversation C,
       newest first, limit 50"
  Q2: "Get all messages sent by user U,
       newest first, limit 20"

  TABLE 1 (for Q1):
    messages_by_conversation
    PK: (conversation_id, message_time DESC)
    WHERE conversation_id = C LIMIT 50
    -> 1 node lookup, O(1)

  TABLE 2 (for Q2):
    messages_by_sender
    PK: (sender_id, message_time DESC)
    WHERE sender_id = U LIMIT 20
    -> 1 node lookup, O(1)

  WRITE PATH:
    new message -> INSERT into table 1
               -> INSERT into table 2
    Both writes; data duplicated; both O(1)

  COST: 2x write throughput, 2x storage
  BENEFIT: both queries are O(1) partition reads
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the CQL "one table per query" pattern
> applied to a messaging use case with two different queries requiring two separate tables.
> (2) HOW TO READ IT: the top shows two application queries; the middle shows the two
> tables designed for those queries; the bottom shows the write path that keeps both
> tables in sync; the cost/benefit tradeoff is quantified at the bottom. (3) KEY
> RELATIONSHIP: each query maps to exactly one table designed for that query; the partition
> key for each table matches the equality filter in the corresponding query; the clustering
> column matches the ordering requirement. (4) EDGE CASE: if the insert to Table 2 fails
> after Table 1 succeeds, the two tables are out of sync; Q1 returns the message, Q2 does
> not; use LOGGED BATCH for atomicity or an idempotent async retry pattern. (5) INSIGHT:
> a senior engineer recognizes that this data duplication is not a defect; it is the
> designed trade-off in Cassandra; the 2x write cost and 2x storage cost are the price
> of two independent O(1) read paths; at millions of reads per second, O(1) vs O(N)
> makes the trade-off worthwhile.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | CQL primary key, table design |
| Application | 2 | Schema for access patterns, secondary indexes |
| Trade-off | 2 | Duplication vs flexibility, BATCH overhead |
| Scenario | 2 | ALLOW FILTERING, partition size |
| Mechanism | 1 | Secondary index internals |

---

**[MID] Q1 (Definition): What is the difference between a partition key and clustering columns in Cassandra?**

Partition key: the field(s) that determine which node stores the data. All rows with
the same partition key value are stored on the same node (and its RF replicas). The
partition key is the hash input for token calculation. In `PRIMARY KEY (user_id, event_time)`,
`user_id` is the partition key.

Clustering columns: additional fields in the primary key that determine the sort order
of rows within a partition. In `PRIMARY KEY (user_id, event_time)`, `event_time` is
the clustering column. Rows with the same `user_id` are sorted by `event_time` within
the partition. Clustering columns support range queries (`event_time > ?`) and explicit
ordering (`WITH CLUSTERING ORDER BY (event_time DESC)`).

Together, partition key + clustering columns form the primary key; every row must have
a unique combination of all primary key fields. There can be only one row per (partition_key,
clustering_col1, clustering_col2, ...) combination.

Composite partition key: `PRIMARY KEY ((user_id, date), hour)` - `user_id + date`
together determine the node; `hour` is the clustering column. Use when a single
partition key field produces hot partitions.

*What separates good from great:* The static column concept. Cassandra supports
`STATIC` columns: columns that have one value per partition, not one value per row.
A static column is like a partition-level attribute. Example: in a `user_sessions`
table partitioned by `user_id`, the user's `display_name` is a static column (one
display_name per user, not one per session). Static columns avoid duplicating the
user's name in every session row; they are stored once per partition and returned
with any row read from that partition.

---

**[MID] Q2 (Application): Walk me through designing a Cassandra data model for a Twitter-like timeline.**

Requirements:
- A user has a home timeline showing tweets from people they follow.
- Timeline shows the most recent N tweets.
- Users can post tweets.
- Users follow/unfollow other users.

Step 1 - Identify access patterns:
- A: "Get home timeline for user U, newest first, limit 50."
- B: "Get tweets by user U, newest first, limit 20."
- C: "Get followers of user U."
- D: "Get users followed by user U."

Step 2 - Design tables per query:

```cql
-- Query A: Home timeline (fan-out on write)
CREATE TABLE home_timelines (
    follower_id  UUID,
    tweet_time   TIMESTAMP,
    poster_id    UUID,
    content      TEXT,
    tweet_id     UUID,
    PRIMARY KEY (follower_id, tweet_time)
) WITH CLUSTERING ORDER BY (tweet_time DESC);

-- Query B: User's own tweets
CREATE TABLE user_tweets (
    user_id    UUID,
    tweet_time TIMESTAMP,
    content    TEXT,
    tweet_id   UUID,
    PRIMARY KEY (user_id, tweet_time)
) WITH CLUSTERING ORDER BY (tweet_time DESC);

-- Query C: Followers of a user
CREATE TABLE followers (
    followed_id UUID,
    follower_id UUID,
    PRIMARY KEY (followed_id, follower_id)
);

-- Query D: Users followed by a user
CREATE TABLE following (
    follower_id UUID,
    followed_id UUID,
    PRIMARY KEY (follower_id, followed_id)
);
```

> **Code walkthrough:** (1) WHAT IT SHOWS: four Cassandra tables designed for four distinct access patterns in a Twitter-like application; each table has a partition key that matches the equality filter in its target query. (2) KEY MECHANISM: `home_timelines` uses `follower_id` as partition key so that getting one user's timeline is a single-partition read; `user_tweets` uses `user_id` so a user's own tweets are one partition; `followers` uses `followed_id` so finding all followers of a user is one partition; `following` uses `follower_id` so finding who a user follows is one partition. (3) WHY IT MATTERS: all four access patterns are served by single-partition reads; every query includes the partition key in the WHERE clause; no ALLOW FILTERING required. (4) WHAT BREAKS: if the access patterns change (e.g., add "get mutual followers"), a new table must be created; changing the primary key of an existing table requires data migration. (5) TAKEAWAY: identify all access patterns before writing a single CQL statement; the access patterns are the specification; the tables are the implementation.

Step 3 - Write path: when user U posts a tweet:
1. Insert into `user_tweets` (for U's profile).
2. Lookup U's followers from `followers` (or maintain in application cache).
3. Insert into `home_timelines` for each follower (fan-out on write).

*What separates good from great:* The celebrity user problem. Fan-out on write is
efficient for average users (100-500 followers). For celebrities with 10 million
followers, inserting into 10 million `home_timelines` partitions on every tweet is
impractical. Twitter's actual solution: fan-out on write for regular users; fan-out
on read for celebrities (merge celebrity tweets into the timeline at read time).
The threshold is approximately 1 million followers; above this, read-time fan-out
is more practical. Cassandra models must account for the "celebrity problem" at design
time.

---

**[SENIOR] Q3 (Mechanism): How does Cassandra's secondary index work and why is it unsuitable for high-cardinality columns?**

A Cassandra secondary index is a local index maintained by each node for its own data.
When you create `CREATE INDEX ON users (email)`, each node creates an index for the
email values of the rows it owns.

Write path with secondary index: each insert/update to `users` also writes an index
entry mapping email -> user_id to the local index. One extra write per indexed column
per insert.

Read path with secondary index: a query `WHERE email = 'alice@example.com'` cannot
be routed to a specific node (email is not the partition key); the coordinator broadcasts
the query to ALL nodes; each node checks its local index; results are collected and
merged.

High-cardinality problem: if `email` is unique per user, the index has one entry per
user per node. Broadcasting the query to N nodes to find one specific email causes N
parallel node queries, N disk reads, N result transmissions, and N result merges.
For a 20-node cluster with 100 million users and 10,000 email lookups per second:
10,000 queries * 20 nodes = 200,000 node queries per second just for email lookups.

Acceptable use case: low-cardinality columns with low query frequency. Example: querying
users by `country` for an admin report that runs once per day. With 5 distinct country
values and 1 query per day, the cluster-wide broadcast is acceptable.

*What separates good from great:* The Materialized Views alternative and its caveats.
Cassandra Materialized Views automatically maintain a denormalized table for a different
query pattern; writes to the base table automatically propagate to the view. This sounds
ideal - it eliminates the application-side dual-write. However, Materialized Views in
Cassandra have a reputation for operational issues: view updates are asynchronous and
can lag behind the base table; repair of materialized views is complex; in practice,
many production teams avoid them and implement the dual-write in application code for
better reliability and control.

---

**[SENIOR] Q4 (Trade-off): When should you choose Cassandra vs PostgreSQL for a new project?**

Cassandra excels at:
- Very high write throughput (> 100,000 writes/second): Cassandra scales writes
  linearly by adding nodes.
- Time-series / event data: append-mostly workloads with time-based queries.
- Always-on availability requirement: no single point of failure; tolerates multiple
  node failures; automatic failover.
- Geographic distribution: multi-datacenter replication with `LOCAL_QUORUM`.
- Predictable query patterns: the application has well-defined, stable query patterns
  that map to table designs.

PostgreSQL excels at:
- Complex queries: JOINs, subqueries, window functions, full-text search.
- Flexible querying: ad-hoc analytics, exploring data by arbitrary fields.
- ACID transactions: multi-row, multi-table transactions with rollback.
- Moderate scale: < 100,000 writes/second; < 1 TB of data.
- Relational integrity: foreign keys, constraints, referential integrity.
- Team familiarity: most developers are SQL-literate; the learning curve for CQL
  schema design is significant.

Decision matrix:
- Write throughput > 100K/s + linear scaling needed? Cassandra.
- ACID transactions + complex queries needed? PostgreSQL.
- Unknown or changing query patterns? PostgreSQL (more flexibility).
- Multi-datacenter active-active writes? Cassandra.
- Single-region with moderate scale? PostgreSQL (simpler operations).

*What separates good from great:* The "Cassandra for caching" anti-pattern. Some teams
use Cassandra as a cache in front of PostgreSQL because it "reads faster." This is
usually wrong: for simple key-value lookups (single partition reads), Cassandra and
PostgreSQL with proper indexing have comparable latency; Redis is a better choice
for caching. Cassandra's advantages are at very high write scale and multi-DC active-
active; for most caching use cases, Redis is simpler and faster.

---

**[SENIOR] Q5 (Application): How do you design a Cassandra schema for a leaderboard that shows top users by score?**

A leaderboard requires: fast write (score updates), fast top-N read (show top 100 users).

The challenge: Cassandra does not support `ORDER BY` on a non-clustering column. You
cannot do `SELECT * FROM scores ORDER BY score DESC LIMIT 100` unless score is a
clustering column.

Solution: design the partition with score as a clustering column:

```cql
-- Daily leaderboard: top users by score for today
CREATE TABLE leaderboard_daily (
    date        DATE,
    score       INT,
    user_id     UUID,
    display_name TEXT,
    PRIMARY KEY (date, score, user_id)
) WITH CLUSTERING ORDER BY (score DESC, user_id ASC);
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a daily leaderboard table with `date` as partition key and `score` as a descending clustering column, enabling efficient top-N queries. (2) KEY MECHANISM: `WITH CLUSTERING ORDER BY (score DESC)` stores rows in descending score order within the partition; `SELECT ... WHERE date = ? LIMIT 100` returns the top 100 scores directly without a sort; Cassandra reads the first 100 rows from the start of the partition. (3) WHY IT MATTERS: without the `DESC` clustering order, a top-N query would require reading the entire partition and sorting at the application; the `DESC` ordering makes `LIMIT N` efficient. (4) WHAT BREAKS: if a user's score changes and the old score entry is not deleted, the leaderboard contains both the old and new scores for that user; read your top-N and filter in the application, or use a separate lookup table to track the current score. (5) TAKEAWAY: use clustering order to encode sort requirements; the physical storage order is the sort order; changing the sort direction after table creation requires creating a new table.

Queries:
- `SELECT * FROM leaderboard_daily WHERE date = ? LIMIT 100` returns top 100 for today.
- Insert on every score change: insert current score; but Cassandra has no UPDATE ORDER,
  so old score entries remain. Use score as part of the primary key to create immutable
  entries; keep only the highest score per user by using `SELECT MAX` after reading
  user's entries, or separate the leaderboard from score tracking.

*What separates good from great:* The practical leaderboard pattern with a "current
score" lookup table. Maintain two tables:

1. `user_scores (user_id PK, current_score INT, display_name TEXT)` - fast single-user
   score update and lookup.
2. `leaderboard_daily (date PK, score CLUSTERING DESC, user_id CLUSTERING)` - top N
   query by date.

Write path: update `user_scores`; insert new entry into `leaderboard_daily`. Over time,
`leaderboard_daily` accumulates stale entries from score changes; use a background job
to reconcile, or accept that `LIMIT 100` reads may include stale lower scores that
get filtered in the application.

---

**[SENIOR] Q6 (Scenario): A Cassandra read consistently returns stale data. A write at t=0 is not visible in a read at t=1s. What could be wrong?**

Root cause analysis:

Scenario 1 - Consistency level mismatch:
If the write uses `ONE` and the read uses `ONE`, the read may go to a replica that has
not yet received the write. The write was acknowledged from replica A; the read goes
to replica B which hasn't replicated yet.
Fix: use `QUORUM` for both write and read; any QUORUM write + QUORUM read must overlap
on at least one replica.

Scenario 2 - Read from a lagging replica:
If the read explicitly uses `LOCAL_ONE` or `ONE`, the coordinator may route to the
fastest replica which happens to be behind.
Diagnosis: check read consistency level in application code.

Scenario 3 - Clock skew between nodes:
Cassandra uses client timestamps (LWT or wall clock) for conflict resolution. If the
reading client's clock is behind the writing client's clock, a read may return an older
version (lower timestamp) as "latest."
Diagnosis: check NTP synchronization on all Cassandra nodes; clock skew > 1 second
is dangerous; clock skew > `read_request_timeout_in_ms` can cause silent stale reads.
Fix: ensure NTP is synchronized across all nodes; use `USING TIMESTAMP` with explicit
timestamps from a single authoritative source if clock sync is unreliable.

Scenario 4 - Eventual consistency (by design):
If the application uses `ONE` consistency intentionally, stale reads within a few
seconds of a write are expected. If the application requires read-your-own-writes,
it must use `LOCAL_QUORUM` or session-level consistency guarantees.

*What separates good from great:* The Lightweight Transaction (LWT) option for read-
your-own-writes. Cassandra LWT (`IF EXISTS`, `IF NOT EXISTS`, conditional `IF field = ?`)
uses Paxos consensus to provide linearizable (strongly consistent) reads and writes at
the partition level. LWT reads always return the latest committed value, regardless of
replication lag. The cost is significant: LWT requires 4 round-trips (prepare, promise,
accept, commit) and is 4-8x slower than a normal read. Use LWT only for critical
compare-and-set operations (account creation, idempotent event processing), not for
general-purpose read-your-own-writes.

---

**[SENIOR] Q7 (Trade-off): What are the limitations of Cassandra's data model and how do you work around them?**

Limitation 1: No JOINs. Cassandra cannot join data across tables at the database level.
Workaround: denormalize by embedding joined data in the same row (snapshot pattern);
or join in the application layer (fetch from multiple tables and merge in code);
or use Apache Spark with Cassandra connector for analytics that require joins.

Limitation 2: No ORDER BY on non-clustering columns. `ORDER BY` in CQL only works on
clustering columns in the order they are defined.
Workaround: design the table with the sort field as a clustering column; create a
separate table if multiple sort orders are needed.

Limitation 3: No aggregations without full partition scan. `COUNT`, `SUM`, `AVG` on
a partition require reading all rows in the partition.
Workaround: use the Computed Pattern - maintain pre-computed aggregate columns (a
`count` column updated with `COUNTER` or a static column) that are incremented on write.

Limitation 4: Limited batch atomicity. Cassandra `LOGGED BATCH` provides atomicity
only for statements in the batch, not for multi-partition transactions.
Workaround: design for idempotency so that retried writes do not cause incorrect state;
use `IF NOT EXISTS` for insert deduplication; accept eventual consistency for cross-
partition operations.

Limitation 5: Schema changes are partial. Adding a column to a Cassandra table is
non-blocking, but changing a partition key requires creating a new table and migrating
data (no `ALTER TABLE` for primary key changes).
Workaround: design the primary key carefully upfront; consider all current and future
access patterns; a wrong partition key is a significant migration.

*What separates good from great:* The Apache Spark integration. For use cases that
require complex aggregations, joins, or arbitrary queries on Cassandra data, Apache
Spark with the `spark-cassandra-connector` is the standard approach. Spark can read
all Cassandra partitions in parallel (one Spark task per partition), join data from
multiple tables in Spark memory, and write results back to Cassandra. This creates
a HTAP (Hybrid Transaction/Analytical Processing) architecture: Cassandra for OLTP
(fast writes, key-value reads), Spark for OLAP (batch analytics). The connector is
token-aware and locality-preserving (Spark executors on the same nodes as Cassandra
reduce network traffic).
