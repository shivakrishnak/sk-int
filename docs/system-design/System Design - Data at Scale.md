---
layout: default
title: "System Design - Data at Scale"
parent: "System Design"
grand_parent: "Interview Mastery"
nav_order: 3
permalink: /interview/system-design/data-at-scale/
topic: System Design
subtopic: Data at Scale
keywords:
  - Sharding and Partitioning
  - Replication Strategies
  - Write-Ahead Log
  - CRDTs
  - Distributed Locking
  - Database Indexing at Scale
difficulty_range: medium to hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Sharding and Partitioning](#sharding-and-partitioning)
- [Replication Strategies](#replication-strategies)
- [Write-Ahead Log](#write-ahead-log)
- [CRDTs](#crdts)
- [Distributed Locking](#distributed-locking)
- [Database Indexing at Scale](#database-indexing-at-scale)

# Sharding and Partitioning

**TL;DR** - Sharding (horizontal partitioning) distributes data across multiple database nodes so no single node holds all the data. It enables horizontal scaling of storage and throughput but introduces complexity in queries, joins, and rebalancing. The shard key choice is the most critical decision.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Single PostgreSQL server: 500GB storage, 10K writes/sec max. Your dataset is 5TB and growing 100GB/month. Vertical scaling (bigger server) is 10x more expensive and has a ceiling. You need to spread data across multiple machines.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Instead of one giant database, split the data across 10 smaller databases. Each holds a slice. Like splitting a phone book into A-F, G-L, M-R, S-Z volumes.

**Level 2 - How to use it (junior developer):**

**Sharding strategies:**

| Strategy        | How                            | Example                                 |
| --------------- | ------------------------------ | --------------------------------------- |
| Range-based     | Key ranges per shard           | Users A-F -> Shard 1, G-L -> Shard 2    |
| Hash-based      | hash(key) % N shards           | hash(userId) % 4 -> shard 0-3           |
| Directory-based | Lookup table maps key -> shard | Geo-based: US -> Shard 1, EU -> Shard 2 |

```
Hash-based sharding:
  userId = 42
  hash(42) % 4 = 2
  -> Route to Shard 2

  userId = 99
  hash(99) % 4 = 3
  -> Route to Shard 3
```

**Level 3 - How it works (mid-level engineer):**

**Shard key selection (the most important decision):**

| Good shard key                | Why                                        |
| ----------------------------- | ------------------------------------------ |
| userId                        | Queries scoped to one user hit one shard   |
| tenantId                      | Multi-tenant isolation, per-tenant scaling |
| orderId (derived from userId) | Orders co-located with user data           |

| Bad shard key     | Why                                      |
| ----------------- | ---------------------------------------- |
| timestamp         | All writes go to one shard (latest time) |
| country           | US shard has 10x more data (skew)        |
| auto-increment ID | Sequential = hot shard                   |

**Cross-shard queries (the pain):**

```sql
-- Single-shard query (fast):
SELECT * FROM orders
WHERE user_id = 42;
-- Routes to one shard, executes locally

-- Cross-shard query (expensive):
SELECT * FROM orders
WHERE created_at > '2024-01-01'
ORDER BY total DESC LIMIT 10;
-- Must query ALL shards, merge results
-- Called "scatter-gather"
-- Latency = slowest shard + merge time
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Rebalancing strategies:**

| Method                | How                                           | Disruption                |
| --------------------- | --------------------------------------------- | ------------------------- |
| Fixed partition count | Pre-allocate 1000 partitions, assign to nodes | Move partitions, not data |
| Dynamic splitting     | Split hot partition when too large            | One partition affected    |
| Consistent hashing    | Virtual nodes on hash ring                    | ~1/N data moves           |

**Compound shard key (avoiding hotspots):**

```
Problem: Celebrity user has 10M followers.
  Shard for that userId is overwhelmed.

Solution: Compound key = userId + salt
  Write: shard = hash(userId + random(0..9))
  Spread across 10 shards for hot user

  Read: query all 10 sub-shards, merge
  Trade-off: writes distributed, reads slower
```

**When NOT to shard:**

1. Data fits in one server (< 1TB for most workloads)
2. Read replicas solve your read scaling
3. Caching handles hot data
4. Partitioning within one DB (PostgreSQL table partitioning) is sufficient
5. Managed services handle sharding (DynamoDB, Spanner, CockroachDB)

Rule: Exhaust single-node optimizations before sharding. Sharding is a one-way door.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Shard key = most critical decision. Must match your dominant query pattern.
2. Cross-shard queries are scatter-gather (expensive). Design to avoid them.
3. Don't shard until you've exhausted read replicas, caching, and single-DB partitioning.
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Sharding and Partitioning. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: You're sharding a social media database. How do you handle the "celebrity problem" (one user has 100M followers)?**

_Why they ask:_ Tests hotspot mitigation in real-world sharding.

_Strong answer:_

The celebrity problem: If sharded by userId, the celebrity's data (posts, fan-out for notifications) overwhelms one shard.

**Fan-out approach (write-heavy):**

```
Celebrity posts -> fan out to all followers
100M followers = 100M writes to timeline shards
This is Twitter's original approach (abandoned)
```

**Fan-in approach (read-heavy, better):**

```
Celebrity posts -> stored once on celebrity's shard
Timeline read: merge celebrity posts + followed
  users' posts at read time
Trade-off: reads do more work, writes are cheap
This is Twitter's current approach for celebrities
```

**Hybrid approach:**

```
Regular users (< 10K followers): fan-out on write
  -> Follower timelines pre-built (fast reads)

Celebrities (> 10K followers): fan-in on read
  -> Post stored once, merged at read time

Detection: follower_count threshold (configurable)
```

**For celebrity's own shard:**

- Compound shard key: hash(userId + bucketId)
- Split celebrity data across N sub-shards
- Read: scatter-gather N sub-shards, merge
- Write: random bucket selection (distributed)
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Replication Strategies

**TL;DR** - Database replication copies data across multiple nodes for fault tolerance and read scaling. The three main strategies are single-leader (one writer, many readers), multi-leader (multiple writers, conflict resolution needed), and leaderless (quorum reads/writes). Each trades consistency, availability, and latency differently.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Single database server: if it dies, your data is gone and your system is down. No copies = no fault tolerance, no read scaling, no geographic distribution.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Keep copies of your data on multiple servers. If one dies, others have the data. Bonus: spread reads across copies for better performance.

**Level 2 - How to use it (junior developer):**

| Strategy      | Writers         | Readers      | Conflict? |
| ------------- | --------------- | ------------ | --------- |
| Single-leader | 1 (primary)     | N (replicas) | No        |
| Multi-leader  | N (each region) | N            | Yes       |
| Leaderless    | N (quorum)      | N (quorum)   | Yes       |

**Single-leader (most common):**

```
Writes -> [Primary] -> replication -> [Replica 1]
                                   -> [Replica 2]
Reads  -> [Replica 1] or [Replica 2]

Used by: PostgreSQL, MySQL, MongoDB (default),
         Redis (default)
```

**Level 3 - How it works (mid-level engineer):**

**Sync vs Async replication:**

| Type             | How                              | Trade-off                     |
| ---------------- | -------------------------------- | ----------------------------- |
| Synchronous      | Write waits for replica ACK      | Durable but slow (2x latency) |
| Asynchronous     | Write returns immediately        | Fast but replica may lag      |
| Semi-synchronous | Wait for 1 replica, others async | Balance (PostgreSQL default)  |

**Replication lag and its effects:**

```
Primary: write(x=5)  t=0ms
Replica: receives x=5  t=100ms (lag)

If user reads from replica at t=50ms:
  -> gets stale value (x=old_value)
  -> This is "read-your-writes" violation
```

**Failover process (single-leader):**

```
1. Primary fails (detected by heartbeat timeout)
2. Replica promoted to new primary
   (most up-to-date replica, or leader election)
3. Clients redirected to new primary
4. Old primary comes back
   -> becomes replica, syncs from new primary

Dangers:
- Split brain: old primary comes back, thinks it's
  still primary. Two primaries accept writes.
  Prevention: fencing tokens, consensus-based election
- Data loss: async replication means some writes
  may not have reached any replica before crash
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Multi-leader replication (cross-region):**

```
US Region: [Leader A] <--> [Leader B] :EU Region
  Each region accepts writes locally (low latency)
  Async replication between leaders
  Conflict when both update same record
```

**Conflict resolution strategies:**

| Strategy              | How                          | Drawback                 |
| --------------------- | ---------------------------- | ------------------------ |
| Last-write-wins (LWW) | Highest timestamp wins       | Clock skew loses writes  |
| Merge                 | Custom merge function        | Domain-specific, complex |
| CRDT                  | Conflict-free data types     | Limited data structures  |
| Manual                | Flag conflict, user resolves | Poor UX                  |

**Leaderless replication (Dynamo-style):**

```
Write: send to ALL N replicas
  Success if W replicas acknowledge
Read: read from ALL N replicas
  Success if R replicas respond
  Take value with highest version

Quorum: W + R > N guarantees overlap
  N=3, W=2, R=2: at least 1 node has latest

Tunable:
  W=1, R=3: fast writes, consistent reads
  W=3, R=1: durable writes, fast reads
  W=1, R=1: fastest, but may read stale data
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Single-leader: simple, no conflicts. Multi-leader: low-latency multi-region but conflicts. Leaderless: quorum-based tunable consistency.
2. Async replication = fast writes but possible data loss on leader failure
3. Quorum formula: W + R > N ensures at least one node has the latest write
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Replication Strategies. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Design the replication strategy for a global e-commerce platform with users in US, EU, and Asia.**

_Why they ask:_ Tests multi-region architecture design.

_Strong answer:_

**Requirements analysis:**

- Reads must be fast everywhere (< 50ms)
- Writes: user profile changes, orders
- Consistency: orders need strong consistency, profiles can be eventual

**Design: Hybrid per data type**

1. **User profiles: Multi-leader (one per region)**

```
US Leader <-> EU Leader <-> Asia Leader
  Writes go to local leader (low latency)
  Async replication to other regions (~200ms)
  Conflict resolution: LWW on profile fields
  Acceptable: profile photo update has 200ms lag
```

2. **Orders: Single-leader per user's home region**

```
US user -> orders go to US primary
  Replicated to EU + Asia (read replicas)
  Strong consistency for order writes
  Reads: local replica (eventual) or primary (strong)

  If US region goes down:
    Promote EU replica to primary for US users
    Possible data loss of last few async writes
    Acceptable with idempotency + retry on client
```

3. **Product catalog: Read replicas everywhere**

```
Single primary (US) for catalog updates
  Read replicas in all 3 regions
  Updates are infrequent (minutes between changes)
  CDN for product images
  Cache layer (Redis) in each region
```

4. **Inventory: Single leader per warehouse region**

```
US inventory -> US primary
EU inventory -> EU primary
Cross-region inventory queries -> scatter-gather
Reserve stock -> route to warehouse region's primary
```
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Write-Ahead Log

**TL;DR** - A Write-Ahead Log (WAL) is an append-only file where every change is written BEFORE it's applied to the actual database. This guarantees durability (data survives crashes) and enables replication, point-in-time recovery, and change data capture (CDC).
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Database writes directly to data files. Power fails mid-write: data file is partially written (corrupted). On restart, database state is inconsistent. No way to know what was committed vs partially applied.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Before changing the actual data, write "I'm about to do X" to a log file. If the system crashes, replay the log to see exactly what happened and finish any incomplete operations.

**Level 2 - How to use it (junior developer):**

```
Without WAL:
  1. UPDATE table SET x=5
  2. Write to data file on disk -> CRASH mid-write
  3. Restart: data file corrupted, state unknown

With WAL:
  1. UPDATE table SET x=5
  2. Write to WAL: "change x from 3 to 5" -> fsync
  3. ACK to client: "committed"
  4. Later: apply change to data file (background)
  5. CRASH at step 4? No problem:
     Replay WAL on restart -> apply change again
```

**Used everywhere:**

- PostgreSQL: WAL (Write-Ahead Log)
- MySQL InnoDB: Redo Log
- Kafka: Commit Log (the entire storage IS a log)
- etcd: Raft log
- SQLite: WAL mode
- LSM-tree databases (RocksDB, Cassandra): Write to memtable + WAL

**Level 3 - How it works (mid-level engineer):**

**WAL lifecycle in PostgreSQL:**

```
1. Transaction begins
2. Changes written to WAL buffer (in memory)
3. COMMIT -> WAL buffer flushed to WAL file (fsync)
4. Client receives "COMMIT OK"
5. Background: checkpoint process writes dirty pages
   from buffer cache to data files
6. Old WAL segments recycled after checkpoint

WAL file structure:
  [LSN 1: INSERT INTO orders (id=1, ...]
  [LSN 2: UPDATE inventory SET qty=9 ...]
  [LSN 3: COMMIT xid=42]
  [LSN 4: INSERT INTO orders (id=2, ...]
  ...
```

**Three uses of WAL:**

1. **Crash recovery:** Replay WAL from last checkpoint
2. **Replication:** Stream WAL to replicas (physical replication)
3. **CDC (Change Data Capture):** Debezium reads WAL to publish change events to Kafka

**Level 4 - Mastery (senior/staff+ engineer):**

**WAL performance tuning:**

```
Key trade-off: durability vs performance

fsync on every commit:
  - Maximum durability (zero data loss)
  - Higher latency (~2ms per commit on SSD)
  - PostgreSQL: synchronous_commit = on

Group commit (batch fsync):
  - Batch multiple commits into one fsync
  - ~10x throughput improvement
  - Tiny risk window (few ms of data loss)
  - PostgreSQL: commit_delay = 10ms

Async commit:
  - Don't fsync WAL on commit
  - Maximum throughput
  - Risk: lose last few ms of commits on crash
  - PostgreSQL: synchronous_commit = off
```

**Kafka's log = its entire architecture:**

```
Kafka IS a distributed WAL:
  Partition 0: [msg0, msg1, msg2, msg3, ...]
  Partition 1: [msg0, msg1, msg2, ...]

  Producers append to end (sequential write)
  Consumers read from any offset
  Retention: time-based or size-based

Why it's fast:
  - Sequential writes (disk-friendly)
  - Zero-copy (sendfile syscall)
  - Page cache (OS caches log in memory)
  - Batch writes (many messages per disk I/O)
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. WAL = write change to log FIRST, then to data files. Guarantees durability.
2. Three uses: crash recovery, replication, and CDC (change data capture)
3. Trade-off: fsync every commit (durable, slow) vs batch/async commit (fast, tiny loss window)
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Write-Ahead Log. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: How does PostgreSQL use WAL for replication? What's the difference between physical and logical replication?**

_Why they ask:_ Tests deep database internals knowledge.

_Strong answer:_

**Physical replication (streaming replication):**

```
Primary writes WAL -> streams WAL bytes to replica
Replica applies WAL bytes to its own data files
Replica is byte-for-byte identical to primary

Pros: Simple, fast, exact copy
Cons: Same PostgreSQL version required,
      all databases replicated (can't filter),
      replica is read-only

Use: High availability, read scaling
```

**Logical replication:**

```
Primary decodes WAL into logical changes:
  "INSERT INTO orders VALUES (1, 'pending')"
  "UPDATE users SET name='Bob' WHERE id=42"

Streams these as logical messages to subscriber
Subscriber applies as SQL operations

Pros: Cross-version, selective (per-table),
      subscriber can have different schema/indexes
Cons: More overhead (decode + apply),
      DDL not replicated automatically

Use: Zero-downtime migrations, CDC,
     selective replication
```

**CDC with Debezium:**

```
PostgreSQL WAL -> Debezium (reads logical
  replication slot) -> Kafka topics

Each table change -> Kafka event:
{
  "op": "u",  // update
  "before": {"id":42, "name":"Alice"},
  "after": {"id":42, "name":"Bob"},
  "source": {"lsn": "0/1A2B3C4"}
}

Consumers build: search index, cache,
  analytics, audit trail
```
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# CRDTs

**TL;DR** - Conflict-free Replicated Data Types (CRDTs) are data structures that can be replicated across multiple nodes, updated independently and concurrently, and always merge to a consistent state without coordination. They mathematically guarantee eventual consistency without conflict resolution logic.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Two users edit a shared document offline. When they reconnect, changes conflict. Traditional approaches: last-write-wins (loses data), custom merge logic (complex, error-prone), or locking (requires coordination, kills availability).
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Special data structures designed so that any combination of updates, in any order, always produces the same result. Like addition: 3+5+2 = 2+3+5 = 10, regardless of order.

**Level 2 - How to use it (junior developer):**

**Common CRDT types:**

| CRDT         | Purpose                 | Example Use            |
| ------------ | ----------------------- | ---------------------- |
| G-Counter    | Grow-only counter       | Like count, page views |
| PN-Counter   | Counter (inc + dec)     | Cart item quantity     |
| G-Set        | Grow-only set           | Tags added to a post   |
| OR-Set       | Add and remove set      | Shopping cart items    |
| LWW-Register | Last-write-wins value   | User profile field     |
| LWW-Map      | Last-write-wins per key | User preferences       |

**G-Counter example:**

```
3 nodes, each has own counter:
  Node A: 5
  Node B: 3
  Node C: 7

Total = sum of all nodes = 15

Node A increments by 2:
  Node A: 7
  Node B: 3
  Node C: 7
  Total = 17

Merge: take max per node
  {A:7, B:3, C:7} merged with {A:5, B:4, C:7}
  = {A:7, B:4, C:7} = 18

No conflicts, no coordination needed!
```

**Level 3 - How it works (mid-level engineer):**

**Mathematical properties that make CRDTs work:**

1. **Commutativity:** merge(A, B) = merge(B, A)
2. **Associativity:** merge(merge(A, B), C) = merge(A, merge(B, C))
3. **Idempotency:** merge(A, A) = A

These guarantee: no matter what order updates arrive, final state is the same.

**OR-Set (Observed-Remove Set) for shopping cart:**

```java
// Supports add AND remove without conflicts
public class ORSet<T> {
    // Each element has a unique tag per add
    private Map<T, Set<UUID>> elements;
    private Set<UUID> tombstones;

    public void add(T element) {
        UUID tag = UUID.randomUUID();
        elements.computeIfAbsent(element,
            k -> new HashSet<>()).add(tag);
    }

    public void remove(T element) {
        Set<UUID> tags = elements.get(element);
        if (tags != null) {
            tombstones.addAll(tags);
            elements.remove(element);
        }
    }

    public ORSet<T> merge(ORSet<T> other) {
        // Union of all tags, minus tombstones
        // Concurrent add + remove: add wins
        // (element re-added with new tag)
    }
}
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Real-world CRDT usage:**

| System        | CRDT Used          | Purpose                         |
| ------------- | ------------------ | ------------------------------- |
| Redis (CRDB)  | PN-Counter, OR-Set | Multi-region active-active      |
| Riak          | Various CRDTs      | Distributed KV store            |
| Figma         | Custom CRDTs       | Real-time collaborative design  |
| Apple Notes   | CRDTs              | Offline editing sync            |
| Automerge/Yjs | JSON CRDT          | Collaborative editing libraries |

**Limitations:**

- **Size overhead:** CRDTs store metadata (tombstones, vector clocks) that grows over time
- **Limited operations:** Not every data structure has a CRDT equivalent
- **Garbage collection:** Tombstones must be cleaned up (requires coordination, ironic)
- **Semantics:** "Add-wins" vs "remove-wins" is a design choice, not automatically correct




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. CRDTs merge without conflicts because operations are commutative, associative, and idempotent
2. G-Counter (sum of per-node counters) is the simplest CRDT - used for distributed counting
3. Used by Redis CRDB, Figma, and collaborative editing tools for multi-region/offline-first
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for CRDTs. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Design a collaborative shopping cart using CRDTs that works offline.**

_Why they ask:_ Tests practical CRDT application.

_Strong answer:_

**Data model: OR-Set (Observed-Remove Set)**

```
Cart = OR-Set of (productId, quantity) pairs

User on Phone (offline):
  Add item A (qty: 2)
  Remove item B
  Change item C qty from 1 to 3

User on Laptop (offline):
  Add item D (qty: 1)
  Add item B (qty: 5)  // readded after remove

Both reconnect -> merge:
  Item A: {qty: 2} (only on phone)
  Item B: conflict!
    Phone removed B, Laptop added B
    OR-Set semantics: add wins (new tag)
    Result: B is in cart (qty: 5)
  Item C: {qty: 3} (LWW for quantity)
  Item D: {qty: 1} (only on laptop)
```

**Implementation:**

- Each cart item = entry in OR-Set
- Quantity = LWW-Register (last write wins by timestamp)
- On reconnect: merge local state with server state
- Server: merge all client states together
- Result: deterministic, no conflicts, no data loss

**Trade-off:** "Add wins" over "remove wins." If user removed item B on phone but added it on laptop, B stays in cart. This is a UX decision - you could also use "remove wins" semantics (different CRDT variant).
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Distributed Locking

**TL;DR** - Distributed locking coordinates access to shared resources across multiple processes/nodes. Implementations range from database locks (simple, safe) through Redis/Redlock (fast, weaker guarantees) to consensus-based locks (ZooKeeper, etcd - strongest guarantees). The key challenge: locks can silently expire during processing.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Two payment processors both read "balance = $100," both approve a $75 withdrawal, both write "balance = $25." The real balance should be $25 (one approved) or -$50 (both approved - overdraft). Without distributed locking, both processes race to corrupt data.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
A "lock" that works across multiple servers. Only one server at a time can hold the lock and do the critical work. Others wait or fail fast.

**Level 2 - How to use it (junior developer):**

**Three approaches:**

| Approach       | Tool                 | Safety          | Speed  |
| -------------- | -------------------- | --------------- | ------ |
| Database lock  | SELECT FOR UPDATE    | Safe (ACID)     | Slow   |
| Redis lock     | SET NX EX            | Fast but weaker | Fast   |
| Consensus lock | etcd/ZooKeeper lease | Safest          | Medium |

```java
// Redis distributed lock (simplified)
boolean acquireLock(String key, String owner,
        Duration ttl) {
    // SET key owner NX EX ttl
    Boolean result = redis.opsForValue()
        .setIfAbsent(key, owner, ttl);
    return Boolean.TRUE.equals(result);
}

void releaseLock(String key, String owner) {
    // Only release if we still own it (atomic)
    String script =
        "if redis.call('get',KEYS[1])==ARGV[1] "
        + "then return redis.call('del',KEYS[1]) "
        + "else return 0 end";
    redis.execute(script, List.of(key), owner);
}
```

**Level 3 - How it works (mid-level engineer):**

**The GC pause problem (critical!):**

```
Process A acquires lock (TTL=30s)
Process A starts work...
Process A hits a 35-second GC pause
  -> Lock expires at 30s
  -> Process B acquires lock
  -> Process B starts work
Process A wakes up, thinks it has the lock
  -> Both processes in critical section!
```

**Solution: Fencing tokens**

```
Lock server gives monotonically increasing token:
  Process A acquires lock -> token=42
  Process A stalls (GC pause)...
  Lock expires, Process B acquires -> token=43

  Storage server checks token:
    Process B: write(data, token=43) -> ACCEPTED
    Process A: write(data, token=42) -> REJECTED
      (42 < 43, stale token)
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Redlock algorithm (Redis multi-node lock):**

```
5 independent Redis masters (not replicated)

Acquire:
  1. Get current time T1
  2. Try SET NX on all 5 nodes sequentially
     with same key, value, TTL
  3. Lock acquired if:
     - Majority (3+) nodes granted lock
     - Total time < TTL (lock not already expiring)
  4. Effective TTL = initial TTL - elapsed time

Release:
  Send DEL to ALL 5 nodes (even ones that didn't
  grant the lock)
```

**Martin Kleppmann's Redlock critique:**

- Clock skew between nodes can violate safety
- Process pauses (GC) can make lock expire silently
- Redlock assumes bounded clock drift (not guaranteed)
- Conclusion: For efficiency locks (prevent duplicate work), Redlock is fine. For correctness locks (prevent data corruption), use proper consensus (etcd, ZooKeeper).

**etcd distributed lock (strongest guarantee):**

```
etcd uses Raft consensus internally:
  1. Acquire: create key with lease (TTL)
     Lease is Raft-replicated -> majority agrees
  2. Hold: keep-alive refreshes lease
  3. Release: delete key or let lease expire
  4. Watch: other clients watch key for changes

  No clock dependency (Raft is logical time)
  Leader election built-in
  Linearizable reads (read latest value guaranteed)
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Fencing tokens are REQUIRED for correctness (GC pause can silently expire locks)
2. Redlock: fine for efficiency (prevent duplicate work), not for correctness (money/data)
3. etcd/ZooKeeper: consensus-based, strongest guarantees, use for critical sections
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Distributed Locking. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Design a distributed lock for deduplicating payment processing across 3 data centers.**

_Why they ask:_ Tests distributed locking for correctness-critical scenarios.

_Strong answer:_

**Requirements:** Exactly-once payment processing. Cannot double-charge. Cannot lose payment.

**Solution: etcd lock + fencing token + idempotency key**

```
Payment request: {paymentId: "pay-123", amount: $100}

Step 1: Acquire etcd lock
  Key: /locks/payment/pay-123
  Lease TTL: 30s
  Fencing token: 42 (from etcd revision)

Step 2: Check idempotency
  SELECT * FROM payments
    WHERE payment_id = 'pay-123';
  If exists -> return cached result (already processed)

Step 3: Process payment
  Call payment gateway with idempotency key

Step 4: Record result
  INSERT INTO payments (payment_id, result,
    fencing_token) VALUES ('pay-123', 'success', 42)
  ON CONFLICT DO NOTHING;
  // fencing_token must be >= last recorded

Step 5: Release lock
  Delete etcd key

Crash recovery:
  If crash after step 3 but before step 4:
    Lock expires (30s)
    Retry: step 2 checks payment gateway
    via idempotency key (already charged)
    Record result without re-charging
```

**Why not Redlock?**

- Payment = correctness-critical. Clock skew could allow two processors in critical section simultaneously.
- etcd uses Raft (no clock dependency), provides linearizable operations.
- Small latency cost (~5ms for etcd vs ~1ms for Redis) is acceptable for payments.
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Database Indexing at Scale

**TL;DR** - Database indexes are data structures (B-tree, hash, GIN, bitmap) that speed up queries by avoiding full table scans. At scale, index design is the #1 performance lever: the right index turns a 30-second query into 5ms. The wrong indexes waste storage and slow writes.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Table with 100M rows. `SELECT * FROM users WHERE email = 'alice@example.com'` requires scanning all 100M rows. On SSD: ~100 seconds. With a B-tree index on email: ~5ms (20,000x faster).
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Like a book's index: instead of reading every page to find "microservices," look up "microservices" in the index to find page 42. Go directly to page 42.

**Level 2 - How to use it (junior developer):**

| Index Type | Best For                         | Example                                   |
| ---------- | -------------------------------- | ----------------------------------------- |
| B-tree     | Range queries, sorting, equality | `WHERE age > 25 AND age < 35`             |
| Hash       | Exact equality only              | `WHERE id = 42`                           |
| GIN        | Full-text search, arrays, JSONB  | `WHERE tags @> '{"java"}'`                |
| Composite  | Multi-column queries             | `WHERE user_id = 1 AND status = 'active'` |

```sql
-- Single column index
CREATE INDEX idx_users_email
    ON users (email);

-- Composite index (column order matters!)
CREATE INDEX idx_orders_user_status
    ON orders (user_id, status);

-- Partial index (index only a subset)
CREATE INDEX idx_orders_pending
    ON orders (created_at)
    WHERE status = 'pending';
```

**Level 3 - How it works (mid-level engineer):**

**B-tree internals (how most indexes work):**

```
B-tree for emails (simplified):
         [M]
        /   \
    [D, H]   [R, V]
   / | \    / | \
  [A-C][E-G][I-L] [N-Q][S-U][W-Z]

Lookup "karen@example.com":
  Root: K < M -> go left
  Internal: H < K -> go right
  Leaf: scan [I-L] -> found!

  3 disk reads instead of 100M row scan
  O(log N) vs O(N)
```

**Composite index column order matters:**

```sql
-- Index: (user_id, status, created_at)

-- Uses full index (all 3 columns):
WHERE user_id = 1
  AND status = 'active'
  AND created_at > '2024-01-01'

-- Uses first 2 columns:
WHERE user_id = 1 AND status = 'active'

-- Uses first column only:
WHERE user_id = 1

-- CANNOT use index (skips first column):
WHERE status = 'active'  -- full table scan!
-- B-tree requires leftmost prefix
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Index-only scan (covering index):**

```sql
-- If your query only needs indexed columns,
-- the DB never reads the table (heap):
CREATE INDEX idx_cover
    ON orders (user_id, status)
    INCLUDE (total);

SELECT status, total FROM orders
WHERE user_id = 42;
-- Answered entirely from index (no heap access)
-- 10-100x faster for wide tables
```

**Write amplification (the hidden cost):**

```
Each index = separate B-tree maintained on every write.
Table with 8 indexes:
  1 INSERT = 1 table write + 8 index writes = 9 writes

At 10K inserts/sec with 8 indexes:
  90K disk writes/sec (9x amplification)

Rule: Every index slows writes.
  Audit indexes quarterly.
  Drop unused indexes.

PostgreSQL: pg_stat_user_indexes
  -> idx_scan = 0 means unused -> candidate to drop
```

**Partitioned indexes:**

```sql
-- Table partitioned by date:
CREATE TABLE events (
    id bigint,
    created_at timestamp,
    data jsonb
) PARTITION BY RANGE (created_at);

-- Each partition has its own index:
-- events_2024_01 -> idx_events_2024_01_id
-- events_2024_02 -> idx_events_2024_02_id

-- Query with partition key -> prune to 1 partition
-- Index lookup on smaller B-tree -> faster
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Composite index: leftmost prefix rule. Index (A,B,C) works for (A), (A,B), (A,B,C) but NOT (B,C)
2. Every index slows writes (write amplification). Drop unused indexes.
3. Covering indexes (INCLUDE) avoid heap reads - 10-100x faster for analytical queries.
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Database Indexing at Scale. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Your query `SELECT * FROM orders WHERE user_id=? AND status='pending' ORDER BY created_at DESC LIMIT 20` is slow on a 500M-row table. Design the optimal index.**

_Why they ask:_ Tests practical index design skills.

_Strong answer:_

**Optimal index:**

```sql
CREATE INDEX idx_orders_user_status_created
    ON orders (user_id, status, created_at DESC);
```

**Why this column order:**

1. `user_id` (equality) - narrows to one user's orders
2. `status` (equality) - narrows to 'pending' only
3. `created_at DESC` - already sorted, no sort step needed

**Execution plan with this index:**

```
Index Scan using idx_orders_user_status_created
  Index Cond: (user_id = 42 AND status = 'pending')
  Rows: 20 (LIMIT stops scan after 20)
  No sort needed (index is pre-sorted by created_at DESC)
```

**Even better - partial covering index:**

```sql
CREATE INDEX idx_orders_pending_user
    ON orders (user_id, created_at DESC)
    INCLUDE (order_total, item_count)
    WHERE status = 'pending';
```

Why better:

- Partial: only indexes 'pending' orders (~5% of data) = much smaller B-tree
- Covering: INCLUDE avoids heap lookup if SELECT only needs included columns
- Result: 50x smaller index, index-only scan, pre-sorted
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]
