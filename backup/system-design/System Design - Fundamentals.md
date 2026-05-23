---
layout: default
title: "System Design - Fundamentals"
parent: "System Design"
grand_parent: "Interview Mastery"
nav_order: 1
permalink: /interview/system-design/fundamentals/
topic: System Design
subtopic: Fundamentals
keywords:
  - CAP Theorem and PACELC
  - Consistency Models
  - Consensus Algorithms
  - Distributed Transactions
  - Consistent Hashing
  - Back-of-Envelope Estimation
difficulty_range: medium to hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [CAP Theorem and PACELC](#cap-theorem-and-pacelc)
- [Consistency Models](#consistency-models)
- [Consensus Algorithms](#consensus-algorithms)
- [Distributed Transactions](#distributed-transactions)
- [Consistent Hashing](#consistent-hashing)
- [Back-of-Envelope Estimation](#back-of-envelope-estimation)

# CAP Theorem and PACELC

**TL;DR** - CAP states a distributed system can guarantee at most two of Consistency, Availability, and Partition tolerance simultaneously. Since network partitions are inevitable, the real choice is between CP (consistent but may reject requests) and AP (available but may return stale data). PACELC extends this: even without partitions, you trade latency for consistency.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Teams design distributed databases expecting to get strong consistency, 100% availability, AND partition tolerance. They're shocked when a network split causes their "highly available" system to return stale data, or their "consistent" system to reject writes.

**THE INVENTION MOMENT:**
Eric Brewer's 2000 conjecture (proven in 2002) formalized that this three-way guarantee is mathematically impossible - forcing architects to make explicit trade-off decisions.
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
When network connections between servers break, you must choose: either stop responding (to stay consistent) or keep responding (but risk serving outdated data).

**Level 2 - How to use it (junior developer):**

**The three guarantees:**

- **Consistency (C):** Every read sees the most recent write
- **Availability (A):** Every request gets a response (not an error)
- **Partition tolerance (P):** System works despite network failures between nodes

Since partitions WILL happen in production, the real decision is:

- **CP:** Refuse to answer rather than return stale data (e.g., ZooKeeper, HBase, MongoDB default)
- **AP:** Always answer, even if data might be stale (e.g., Cassandra, DynamoDB, CouchDB)

**Level 3 - How it works (mid-level engineer):**

**Real-world examples:**

| System              | Choice       | Behavior During Partition                |
| ------------------- | ------------ | ---------------------------------------- |
| ZooKeeper           | CP           | Minority nodes reject reads/writes       |
| etcd / Consul       | CP           | Leader-based, minority stalls            |
| Cassandra           | AP           | All nodes accept writes, reconcile later |
| DynamoDB            | AP (tunable) | Eventual consistency by default          |
| MongoDB             | CP (default) | Primary unavailable = no writes          |
| PostgreSQL (single) | CA           | No partitions (single node)              |

**PACELC extension:**

```
If Partition:
  Choose Consistency or Availability (PC or PA)
Else (normal operation):
  Choose Latency or Consistency (EL or EC)
```

| System    | P choice | E choice | Full                                 |
| --------- | -------- | -------- | ------------------------------------ |
| Cassandra | PA       | EL       | PA/EL                                |
| MongoDB   | PC       | EC       | PC/EC                                |
| DynamoDB  | PA       | EL       | PA/EL                                |
| Spanner   | PC       | EC       | PC/EC (but low latency via TrueTime) |

**Level 4 - Mastery (senior/staff+ engineer):**

**CAP misconceptions that trip up seniors:**

1. "CA systems exist" - Only for single-node systems. Any multi-node system MUST tolerate partitions.

2. "It's a permanent choice" - Many systems are tunable PER OPERATION:

```java
// DynamoDB: consistent read (CP for this call)
GetItemRequest.builder()
    .consistentRead(true)
    .build();

// Cassandra: tunable consistency per query
session.execute(
    SimpleStatement.builder(query)
        .setConsistencyLevel(QUORUM) // CP
        .build());
// vs LOCAL_ONE = AP
```

3. "Partition = network cable cut" - Partitions include: GC pauses > timeout, slow networks, asymmetric failures (A can reach B, B can't reach A).

**The Harvest/Yield model (more nuanced than CAP):**

- Harvest: fraction of data in the response (incomplete results)
- Yield: fraction of requests that succeed

A search engine can sacrifice harvest (return 95% of results) instead of choosing strictly between C and A.




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

1. Partitions are inevitable - the real choice is CP vs AP
2. Most production systems are tunable per operation, not globally locked
3. PACELC adds the normal-operation trade-off: Latency vs Consistency

**Interview one-liner:**
"CAP means during a partition you choose consistency or availability; PACELC extends this to normal operation where you trade latency for consistency. Most systems are tunable per-query, not a fixed choice."
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

[TODO: Include if 2+ named alternatives exist for CAP Theorem and PACELC. Otherwise remove this section.]
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

**Q1: Your system uses DynamoDB. A product manager says "I need every read to return the latest write." What do you tell them?**

_Why they ask:_ Tests practical application of CAP in real architecture decisions.

_Strong answer:_

DynamoDB is AP by default (eventually consistent reads, ~50ms propagation). Options:

1. **Consistent reads:** Set `ConsistentRead=true`. Doubles read latency and costs 2x RCU. Reads routed to leader node.

2. **DynamoDB Transactions:** `TransactGetItems` for multi-item consistent reads. 2x cost, higher latency.

3. **Design around it:** Many use cases don't actually need strong consistency:
   - Shopping cart: eventual is fine (user won't notice 100ms staleness)
   - Inventory count for display: eventual is fine
   - Inventory for checkout deduction: use conditional writes (optimistic locking)
   - Financial ledger: need transactions or switch to a CP system

4. **Hybrid approach:** Use DynamoDB for high-throughput AP reads, but route critical writes through a CP system (Aurora, single-leader Postgres) with DynamoDB as a read cache.

The real answer: "What's the cost of serving stale data for 100ms?" If low -> AP. If high -> CP for that specific path.

---

**Q2: How does Google Spanner achieve "effectively CA" in a distributed system?**

_Why they ask:_ Tests deep understanding of CAP nuances.

_Strong answer:_

Spanner is technically CP, but Google engineers made partitions so rare and so short that it appears CA:

1. **TrueTime (atomic clocks + GPS):** Every Google data center has atomic clocks synchronized to within ~7ms. This eliminates the need for consensus round-trips for read timestamps.

2. **Dedicated network:** Google's private fiber network between data centers has near-zero packet loss and sub-millisecond jitter. Partitions are extremely rare.

3. **Synchronous replication with Paxos:** Writes go to a quorum of replicas synchronously. Reads at a timestamp use TrueTime bounds to wait just long enough for consistency.

4. **Trade-off:** Higher write latency (commit-wait for TrueTime uncertainty). But reads are fast because TrueTime bounds are tight (~7ms).

It's still CP: during the rare partition, minority partitions become unavailable. But Google's infrastructure makes partitions so rare that users experience it as CA with low latency. Most companies can't replicate this (no TrueTime, no private global network).

---

**Q3: You're designing a distributed counter for "likes" on posts. Walk through CAP trade-offs.**

_Why they ask:_ Tests applied trade-off reasoning with a concrete scenario.

_Strong answer:_

Requirements analysis:

- Write volume: Potentially millions per second (viral post)
- Read accuracy needed: "1.2M likes" vs "1,200,001 likes" - users don't care about exact count
- Availability: Must always accept like clicks (can't show errors)

Design: AP system with eventual consistency

```
User clicks "Like"
  -> Write to local region's counter
  -> Async propagation to other regions
  -> Read shows locally-consistent count
  -> Periodic reconciliation across regions
```

Implementation options:

1. **Redis INCR per region + periodic sync:** Fast, AP, reconcile counts every 5-10s
2. **CRDT G-Counter:** Each node has its own counter, merge = sum of all. Conflict-free, eventually consistent.

```
Node A counter: 500
Node B counter: 300
Node C counter: 200
Total (any node): 1000
```

3. **If exact count needed** (e.g., "first 100 likes get a prize"): Use a single CP counter (Redis single-node, or DynamoDB conditional update). Trade-off: higher latency, potential unavailability.

Answer: Like counts are a textbook AP use case. Use G-Counter CRDT or per-region counters with async merge.
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

# Consistency Models

**TL;DR** - Consistency models define what guarantees clients get about the order and visibility of reads/writes in a distributed system. The spectrum ranges from linearizability (strongest, most expensive) through causal consistency to eventual consistency (weakest, cheapest). Choosing correctly is the #1 distributed system design decision.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Two users update the same document simultaneously. Which version wins? A user reads immediately after writing - do they see their own write? Without explicit consistency models, behavior is undefined and bugs are non-reproducible.
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
After writing data, how soon and from where can you read it back? Immediately from anywhere? Only from the same server? Eventually from everywhere?

**Level 2 - How to use it (junior developer):**

**The spectrum (strongest to weakest):**

| Model            | Guarantee                                              | Cost            |
| ---------------- | ------------------------------------------------------ | --------------- |
| Linearizability  | Every read returns the latest write globally           | Highest latency |
| Sequential       | All clients see same order (but not real-time)         | High            |
| Causal           | Causally related ops ordered; concurrent ops unordered | Medium          |
| Read-your-writes | You see your own writes immediately                    | Low             |
| Eventual         | All replicas converge eventually                       | Lowest latency  |

**Level 3 - How it works (mid-level engineer):**

**Linearizability (strongest):**

- As if there's a single copy of data
- Every operation takes effect at a single point in time
- Required for: leader election, distributed locks, uniqueness constraints

```
Timeline:    t1        t2        t3
Writer:      write(x=1)
Reader A:              read(x) -> must return 1
Reader B:                        read(x) -> must return 1
```

**Causal consistency:**

- If A causes B, everyone sees A before B
- Concurrent (independent) operations can be seen in different orders
- Required for: comment threads, message replies

```
Alice posts: "I got the job!"
Bob replies:  "Congrats!"
Carol must see Alice's post BEFORE Bob's reply
But she might see unrelated posts in any order
```

**Eventual consistency:**

- If no new writes, all replicas eventually converge
- No ordering guarantee during convergence
- Acceptable for: counters, caches, DNS, session stores

**Level 4 - Mastery (senior/staff+ engineer):**

**Choosing consistency model per data type:**

| Data Type         | Model Needed           | Why                               |
| ----------------- | ---------------------- | --------------------------------- |
| Bank balance      | Linearizable           | Can't overdraw                    |
| Inventory count   | Sequential or stronger | Prevent overselling               |
| User profile      | Read-your-writes       | User expects to see their edit    |
| Social feed       | Causal                 | Replies must follow posts         |
| Analytics counter | Eventual               | Approximate is fine               |
| DNS records       | Eventual               | TTL-based convergence             |
| Chat messages     | Causal                 | Order within conversation matters |

**Session consistency (read-your-writes) implementation:**

```java
// After write, include version token in session
String writeVersion = db.write(update);
session.setAttribute("minVersion", writeVersion);

// On read, ensure replica is at least this fresh
String minVersion = session.getAttribute("minVersion");
db.read(query, minReadVersion: minVersion);
// Routes to replica that has this version or waits
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

1. Linearizable = single-copy behavior (expensive). Eventual = converges later (cheap).
2. Most apps need different consistency per operation, not one global setting
3. Causal consistency is the sweet spot: preserves intuitive ordering without global coordination
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

[TODO: Include if 2+ named alternatives exist for Consistency Models. Otherwise remove this section.]
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

**Q1: A user updates their profile name. They refresh and see the old name. How do you fix this without making the entire system strongly consistent?**

_Why they ask:_ Tests practical consistency model application.

_Strong answer:_

This is a read-your-writes consistency violation. The user wrote to the leader but read from a stale replica.

Fixes (cheapest to most expensive):

1. **Sticky sessions:** Route user to the same replica they wrote to (set cookie with replica affinity)
2. **Read-after-write guarantee:** After write, include a "min version" marker. Read request waits for replica to catch up to that version.
3. **Read from leader for N seconds after write:** After any write, route reads to leader for 5-10 seconds, then back to replicas.
4. **Client-side merge:** Client caches the write locally and overlays it on stale reads until replica catches up.

```
// Implementation option 2:
POST /profile -> returns {version: 42}
// Client stores version
GET /profile?minVersion=42
// Backend: if replica < v42, either wait or
//          redirect to leader
```

Best practice: Apply read-your-writes only to the user who wrote. Other users can tolerate eventual consistency for profile reads.
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

# Consensus Algorithms

**TL;DR** - Consensus algorithms (Raft, Paxos, ZAB) allow a group of unreliable nodes to agree on a single value or sequence of operations despite crashes. They're the foundation of leader election, distributed locks, metadata stores, and replicated state machines.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
5 database replicas with no consensus: during a network partition, 2 nodes elect themselves as leader. Both accept writes. When the partition heals, you have divergent data with no way to reconcile. This is "split brain" - the worst failure mode in distributed systems.
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
5 servers need to agree on "who is the leader" even if 2 of them crash. Consensus protocols guarantee that all surviving servers agree on the same answer, even during failures.

**Level 2 - How to use it (junior developer):**

You rarely implement consensus yourself. You USE systems built on it:

| System        | Consensus Protocol | What It Decides                |
| ------------- | ------------------ | ------------------------------ |
| etcd          | Raft               | Key-value metadata, K8s state  |
| ZooKeeper     | ZAB (Zab)          | Leader election, config, locks |
| Consul        | Raft               | Service discovery, KV store    |
| CockroachDB   | Raft               | Transaction commit order       |
| Kafka (KRaft) | Raft               | Partition leader, metadata     |

**Level 3 - How it works (mid-level engineer):**

**Raft (most common, designed for understandability):**

Three roles: Leader, Follower, Candidate

```
Normal operation:
  Leader receives all writes
  Leader replicates to followers (AppendEntries)
  Majority acknowledge -> commit -> respond to client

Leader failure:
  Followers detect heartbeat timeout
  One becomes Candidate, requests votes
  Majority votes -> new Leader elected

  Term 1: Leader A  [-----crash-----]
  Term 2:            Candidate B -> Leader B
```

**Key safety guarantee:**

- Only a node with ALL committed entries can become leader
- Prevents data loss even with leader failure

**Quorum math:**

- 3 nodes: tolerates 1 failure (quorum = 2)
- 5 nodes: tolerates 2 failures (quorum = 3)
- 7 nodes: tolerates 3 failures (quorum = 4)
- Formula: tolerates `(N-1)/2` failures

**Level 4 - Mastery (senior/staff+ engineer):**

**Raft vs Paxos vs ZAB:**

| Aspect            | Raft                        | Multi-Paxos              | ZAB           |
| ----------------- | --------------------------- | ------------------------ | ------------- |
| Understandability | Designed for clarity        | Notoriously complex      | Moderate      |
| Leader            | Strong leader required      | Flexible                 | Strong leader |
| Log ordering      | Consecutive log entries     | May have gaps            | Consecutive   |
| Implementation    | etcd, Consul, CockroachDB   | Spanner, Chubby          | ZooKeeper     |
| Leader election   | Single round in common case | Multiple rounds possible | Epoch-based   |

**Why not use consensus for everything:**

- Consensus requires majority quorum = high latency (cross-DC round trips)
- Write throughput limited by slowest quorum member
- 2f+1 nodes to tolerate f failures = infrastructure cost
- Use it ONLY for metadata/coordination, not for user data at scale




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

1. Quorum: 2f+1 nodes tolerates f failures (3 nodes -> 1 failure, 5 -> 2)
2. Only use consensus for coordination/metadata, not bulk data (too expensive)
3. Raft: strong leader replicates log to majority, committed once majority acknowledges
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

[TODO: Include if 2+ named alternatives exist for Consensus Algorithms. Otherwise remove this section.]
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

**Q1: You need distributed locking for exactly-once payment processing. How do you implement it?**

_Why they ask:_ Tests practical consensus application.

_Strong answer:_

Use a consensus-based system for the lock (etcd, ZooKeeper, or Redis Redlock):

**Option 1: etcd lease-based lock:**

```
1. Acquire lock: PUT /locks/payment-{id}
   with lease TTL=30s
2. Process payment
3. Release lock: DELETE /locks/payment-{id}
4. If process crashes: lease expires after 30s
   -> lock auto-released
```

**Option 2: Redlock (Redis, weaker guarantee):**

```
1. Acquire lock on 5 independent Redis nodes
2. If majority (3+) grant lock within timeout
   -> lock acquired
3. Process payment
4. Release on all nodes
```

Critical safety considerations:

- **Fencing tokens:** Lock might expire while you're still processing (GC pause). Use monotonically increasing fencing tokens:

```
Lock acquired: token=42
Payment API: "Process payment, fencing=42"
Payment service: reject if token < last seen
```

- **Idempotency key:** Even with locks, design for at-least-once. Payment ID is the idempotency key.
- **Clock skew:** With Redlock, clock skew between nodes can violate safety. etcd/ZooKeeper are safer because they use Raft (no clock dependency).

Martin Kleppmann's critique: Redlock is not safe for correctness-critical locks. Use proper consensus (etcd, ZooKeeper) for anything involving money.

---

**Q2: Explain why a 3-node etcd cluster can handle 1 node failure but not 2.**

_Why they ask:_ Tests understanding of quorum math.

_Strong answer:_

Raft requires a **majority quorum** to commit any operation:

- 3 nodes: quorum = 2 (majority of 3)
- If 1 node fails: 2 remaining = quorum met -> cluster operates normally
- If 2 nodes fail: 1 remaining < quorum of 2 -> cluster becomes read-only (or unavailable)

Why majority (not all, not just one):

- All nodes required: any single failure stops the system (no fault tolerance)
- Just one node: split brain possible (two isolated nodes both accept writes)
- Majority: guarantees any two quorums overlap by at least one node -> prevents conflicting decisions

```
3 nodes: [A, B, C]
Quorum options: {A,B} or {A,C} or {B,C}
Any two quorums share at least 1 node
-> Can't have two leaders making different decisions
```

For 5 nodes: quorum = 3. Two quorums of 3 from 5 nodes always overlap by at least 1. This overlapping node prevents split brain.

Production tip: Use 5 nodes for production etcd (tolerates 2 failures). 3 nodes is minimum viable (tolerates 1). Never use even numbers (4 nodes tolerates only 1 failure, same as 3 but costs more).
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

# Distributed Transactions

**TL;DR** - Distributed transactions coordinate writes across multiple services/databases. Two-Phase Commit (2PC) provides strong consistency but blocks on coordinator failure. The Saga pattern provides eventual consistency through compensating transactions, trading atomicity for availability.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
An order service debits inventory AND charges payment. If payment succeeds but inventory update fails, you've charged the customer with nothing to ship. Without distributed transactions, partial failures corrupt business state across services.
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
When one business operation touches multiple databases/services, you need all of them to succeed or all of them to roll back. That coordination is a distributed transaction.

**Level 2 - How to use it (junior developer):**

**Two options in the microservices world:**

1. **2PC (Two-Phase Commit):** Strong consistency, but blocking
2. **Saga:** Eventual consistency, non-blocking, compensates on failure

```
SAGA - Order Processing:
  Step 1: Reserve inventory  (compensate: release)
  Step 2: Charge payment     (compensate: refund)
  Step 3: Create shipment    (compensate: cancel)

  If Step 2 fails:
    -> Compensate Step 1 (release inventory)
    -> Mark order as failed
```

**Level 3 - How it works (mid-level engineer):**

**Two-Phase Commit (2PC):**

```
Phase 1 - PREPARE:
  Coordinator -> All participants: "Can you commit?"
  Each participant: locks resources, writes to WAL
  Each participant -> Coordinator: "Yes" or "No"

Phase 2 - COMMIT/ABORT:
  If ALL said "Yes":
    Coordinator -> All: "COMMIT"
  If ANY said "No":
    Coordinator -> All: "ABORT"
```

**2PC problems:**

- Coordinator crashes between phases -> all participants BLOCKED (holding locks indefinitely)
- High latency (2 network round-trips minimum)
- Doesn't scale (locks held across services)

**Saga Pattern - Choreography:**

```
Order Service -> publish: OrderCreated
Inventory Service -> subscribe: OrderCreated
  -> reserve stock
  -> publish: InventoryReserved
Payment Service -> subscribe: InventoryReserved
  -> charge card
  -> publish: PaymentCompleted

On failure:
Payment Service -> publish: PaymentFailed
Inventory Service -> subscribe: PaymentFailed
  -> release stock (compensating transaction)
```

**Saga Pattern - Orchestration:**

```java
public class OrderSaga {
    public void execute(OrderRequest req) {
        try {
            inventoryService.reserve(req);
            paymentService.charge(req);
            shippingService.create(req);
        } catch (PaymentException e) {
            inventoryService.release(req); // compensate
            throw new OrderFailedException(e);
        } catch (ShippingException e) {
            paymentService.refund(req);    // compensate
            inventoryService.release(req); // compensate
            throw new OrderFailedException(e);
        }
    }
}
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Choreography vs Orchestration:**

| Aspect           | Choreography             | Orchestration            |
| ---------------- | ------------------------ | ------------------------ |
| Coupling         | Loose (events)           | Central coordinator      |
| Visibility       | Hard to track            | Clear saga state         |
| Complexity       | Grows with steps         | Linear                   |
| Failure handling | Distributed compensation | Centralized              |
| Best for         | Simple sagas (2-3 steps) | Complex sagas (4+ steps) |

**The Outbox Pattern (reliable saga events):**

```
Problem: Service commits to DB but crashes
before publishing event. Data inconsistent.

Solution: Write event to "outbox" table in
same DB transaction as business data.
Separate process polls outbox and publishes.

BEGIN TRANSACTION;
  UPDATE inventory SET qty = qty - 1;
  INSERT INTO outbox (event_type, payload)
    VALUES ('InventoryReserved', '...');
COMMIT;

-- Outbox relay (Debezium CDC or poll):
-- Reads outbox, publishes to Kafka, marks sent
```

**Idempotency is non-negotiable in Sagas:**
Every step and every compensation must be idempotent (safe to retry):

```java
// Idempotent charge:
public void charge(String idempotencyKey,
        BigDecimal amount) {
    if (paymentRepo.existsByIdempotencyKey(key)) {
        return; // Already processed
    }
    // Process payment...
    paymentRepo.save(key, result);
}
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

1. 2PC = strong consistency but blocks and doesn't scale. Saga = eventual consistency with compensation.
2. Every saga step needs a compensating action AND must be idempotent
3. Use Outbox Pattern to reliably publish events from DB transactions
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

[TODO: Include if 2+ named alternatives exist for Distributed Transactions. Otherwise remove this section.]
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

**Q1: Design the transaction flow for an e-commerce checkout across 4 services.**

_Why they ask:_ Tests distributed transaction design skills.

_Strong answer:_

Services: Order, Inventory, Payment, Shipping

**Orchestrated Saga with Outbox:**

```
OrderSaga Orchestrator:
  1. Create order (PENDING)
  2. Reserve inventory
     -> fail: mark order FAILED, done
  3. Charge payment
     -> fail: release inventory, mark FAILED
  4. Create shipment
     -> fail: refund payment, release inventory,
              mark FAILED
  5. Confirm order (COMPLETED)
```

Implementation details:

- Saga state stored in Order DB (survives orchestrator restart)
- Each service call is idempotent (retry-safe)
- Outbox pattern for event publishing
- Timeout on each step (e.g., payment gateway 30s)
- Dead letter queue for steps that fail after max retries

```java
@Entity
public class OrderSagaState {
    @Id private UUID orderId;
    @Enumerated(STRING)
    private SagaStep currentStep;
    private int retryCount;
    private String compensationStack; // JSON
    private Instant lastAttempt;
}
```

Key design decisions:

- **Timeout:** If payment service doesn't respond in 30s, assume failure and compensate
- **Retry:** 3 retries with exponential backoff before compensating
- **Observability:** Log saga state transitions, alert on stuck sagas
- **Manual intervention:** Dashboard for stuck sagas (human decides after N failures)
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

# Consistent Hashing

**TL;DR** - Consistent hashing distributes data across N nodes using a hash ring so that adding/removing a node only redistributes ~1/N of the data instead of reshuffling everything. Used by DynamoDB, Cassandra, CDNs, and load balancers for scalable, balanced distribution.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Simple modulo hashing (`key.hashCode() % N`) works until you add or remove a server. Changing N from 5 to 6 remaps ~80% of all keys. In a cache cluster with 100M keys, 80M cache misses hit simultaneously - a "cache stampede" that can take down the backend.
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
Imagine servers placed around a clock face. Each piece of data is hashed to a position on the clock, and stored on the next server clockwise. Adding a new server only steals data from its one clockwise neighbor - everything else stays put.

**Level 2 - How to use it (junior developer):**

```
Hash Ring (0 to 2^32):

        Node A (pos: 1000)
       /
  ----+---->  Node B (pos: 4000)
  |                          |
  |   Ring                   |
  |                          |
  <----+----  Node C (pos: 7000)

Key "user:42" hashes to 3500
  -> stored on Node B (next clockwise after 3500)

Key "order:99" hashes to 5000
  -> stored on Node C (next clockwise after 5000)
```

**Level 3 - How it works (mid-level engineer):**

**Problem: Uneven distribution with few nodes**
3 nodes on the ring creates large gaps. One node might own 60% of the keyspace.

**Solution: Virtual nodes (vnodes)**
Each physical node gets 100-200 positions on the ring:

```
Physical Node A -> Virtual: A1, A2, ... A150
Physical Node B -> Virtual: B1, B2, ... B150
Physical Node C -> Virtual: C1, C2, ... C150

450 points on ring -> much more even distribution
```

Adding Node D: place 150 virtual nodes. Each steals a tiny slice from nearby vnodes. Only ~1/4 of data moves.

**Replication:** Store each key on the next N clockwise nodes (e.g., N=3 for 3 replicas).

**Level 4 - Mastery (senior/staff+ engineer):**

**Implementation (simplified):**

```java
public class ConsistentHashRing<T> {
    private final TreeMap<Long, T> ring =
        new TreeMap<>();
    private final int vnodeCount;

    public void addNode(T node) {
        for (int i = 0; i < vnodeCount; i++) {
            long hash = hash(node + "#" + i);
            ring.put(hash, node);
        }
    }

    public T getNode(String key) {
        long hash = hash(key);
        // Find first node clockwise
        Map.Entry<Long, T> entry =
            ring.ceilingEntry(hash);
        if (entry == null) {
            entry = ring.firstEntry(); // wrap around
        }
        return entry.getValue();
    }

    public void removeNode(T node) {
        for (int i = 0; i < vnodeCount; i++) {
            ring.remove(hash(node + "#" + i));
        }
    }
}
```

**Real-world usage:**

- **DynamoDB:** Partition key hashed to a ring. Partitions automatically split when hot.
- **Cassandra:** Token ring with vnodes. Partition key determines primary replica.
- **CDN (Akamai):** Content hashed to edge server ring. Same content always served by same edge (cache-friendly).
- **Redis Cluster:** 16384 hash slots distributed across nodes.




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

1. Adding/removing a node moves only ~1/N of data (vs ~100% with modulo)
2. Virtual nodes solve uneven distribution (each physical node -> 100+ ring positions)
3. Used by Cassandra, DynamoDB, CDNs, Redis Cluster for scalable partitioning
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

[TODO: Include if 2+ named alternatives exist for Consistent Hashing. Otherwise remove this section.]
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

**Q1: Design a distributed cache with consistent hashing. What happens when a node dies?**

_Why they ask:_ Tests practical application and failure handling.

_Strong answer:_

Design: 5 cache nodes, 200 vnodes each, replication factor 2.

Normal operation:

- Key hashes to position -> stored on node at next clockwise vnode
- Also replicated to the node after that (RF=2)

Node failure:

```
Before: Key X -> Node B (primary), Node C (replica)
Node B dies:
  -> Node C has the data (replica)
  -> Ring removes B's vnodes
  -> B's keyspace redistributed to remaining nodes
  -> New replica created on Node D for keys now
     owned by C
```

Client behavior:

- Client library aware of ring topology (gossip-based updates)
- Detects B is dead (connection timeout or gossip)
- Routes to next node on ring (C has replica)

Cache stampede prevention:

- During redistribution, cache miss rate spikes for B's keys
- Mitigation: "Stale-while-revalidate" - serve expired cached value while fetching fresh
- Or: Use consistent hashing with bounded loads (Google's algorithm) to prevent hot spots during rebalancing
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

# Back-of-Envelope Estimation

**TL;DR** - Back-of-envelope estimation is the interview skill of quickly calculating system capacity requirements (QPS, storage, bandwidth, server count) using powers of 2, latency numbers, and simple arithmetic. It's the first 5 minutes of every system design interview.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
"Design Twitter" - but how many servers? How much storage? Without estimation, you can't make informed decisions about architecture. You might design a single-server solution for a billion-user system.
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
Quickly calculate: How much data? How many servers? How much bandwidth? Using rough numbers that are close enough to make architecture decisions.

**Level 2 - How to use it (junior developer):**

**Essential numbers to memorize:**

| Metric            | Value              |
| ----------------- | ------------------ |
| 1 day             | 86,400 sec (~100K) |
| 1 month           | ~2.5M sec          |
| 1 year            | ~30M sec           |
| 1 million req/day | ~12 req/sec        |
| 1 billion req/day | ~12,000 req/sec    |

**Storage:**
| Type | Size |
|------|------|
| 1 char (UTF-8) | 1-4 bytes |
| UUID | 16 bytes |
| Timestamp | 8 bytes |
| Average tweet | ~300 bytes |
| Average image | ~200 KB |
| Average video (1 min, 720p) | ~50 MB |

**Level 3 - How it works (mid-level engineer):**

**Latency numbers (2024 approximate):**

```
L1 cache reference:           1 ns
L2 cache reference:           4 ns
RAM reference:               100 ns
SSD random read:              16 us
HDD random read:              2 ms
Send 1KB over 1Gbps network: 10 us
Round trip same datacenter:  500 us
Round trip cross-continent:  150 ms
```

**Example: Design a URL shortener**

DAU: 100M, 10% create links, each creates 2/day

- Write QPS: 100M _ 0.1 _ 2 / 86400 = ~230 writes/sec
- Read QPS (100:1 read:write): ~23,000 reads/sec
- Peak (3x average): ~70,000 reads/sec

Storage (5 years):

- 20M new URLs/day _ 365 _ 5 = 36.5B URLs
- Each record: short_url(7B) + long_url(100B) + metadata(50B) = ~160B
- Total: 36.5B \* 160B = ~5.8 TB

Bandwidth:

- 23K reads/sec \* 160 bytes = ~3.7 MB/sec (trivial)

Servers:

- Single Redis: 100K ops/sec -> 1 server handles reads easily
- Storage: 5.8 TB -> distributed (or single large SSD)

**Level 4 - Mastery (senior/staff+ engineer):**

**The estimation framework for interviews:**

```
1. CLARIFY scope (features, users, growth)
2. ESTIMATE traffic (DAU -> QPS -> peak QPS)
3. ESTIMATE storage (per-record * count * retention)
4. ESTIMATE bandwidth (QPS * payload size)
5. DERIVE architecture (single server? distributed?)
```

**Pro tips:**

- Round aggressively: 86,400 -> 100K, 2.6M -> 3M
- Use powers of 10, not exact math
- State assumptions explicitly: "Assuming 10:1 read:write ratio"
- Calculate peak as 3-5x average
- Don't forget replication factor for storage (RF=3 -> triple)




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

1. 1M requests/day = ~12 QPS. 1B requests/day = ~12K QPS.
2. Framework: Clarify -> Traffic -> Storage -> Bandwidth -> Architecture
3. Round aggressively, state assumptions, multiply by replication factor
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

[TODO: Include if 2+ named alternatives exist for Back-of-Envelope Estimation. Otherwise remove this section.]
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

**Q1: Estimate the storage needed for a chat system serving 500M daily active users.**

_Why they ask:_ Tests systematic estimation skills.

_Strong answer:_

Assumptions:

- 500M DAU
- Average user sends 40 messages/day
- Average message: 100 bytes (text) + 50 bytes metadata = 150 bytes
- 10% of messages include an image (200KB avg)
- Retention: 5 years for text, 1 year for media

Text storage:

- Messages/day: 500M \* 40 = 20B messages/day
- Daily text: 20B \* 150B = 3TB/day
- 5 years: 3TB _ 365 _ 5 = ~5.5PB
- With RF=3: ~16.5PB

Media storage:

- Images/day: 20B \* 0.1 = 2B images/day
- Daily media: 2B \* 200KB = 400TB/day
- 1 year: 400TB \* 365 = ~146PB
- With RF=3: ~438PB (this is why chat apps use object storage + CDN)

QPS:

- Write: 20B / 86400 = ~230K msg/sec
- Peak (3x): ~700K msg/sec
- This requires sharding by conversation_id

Architecture implications:

- Text: Sharded database (Cassandra/Scylla) across 100+ nodes
- Media: Object storage (S3) with CDN
- Message delivery: WebSocket connections, partitioned by user_id
- Indexing: Only recent messages indexed for search
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
