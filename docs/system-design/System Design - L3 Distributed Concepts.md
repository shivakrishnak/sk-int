---
layout: default
title: "System Design - L3 Distributed Concepts"
parent: "System Design"
grand_parent: "SK Interview"
nav_order: 5
permalink: /system-design/l3-distributed-concepts/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [System Design - L3 Distributed Concepts](#system-design---l3-distributed-concepts) | medium |
| 2 | [CAP Theorem](#cap-theorem) | medium |
| 3 | [Eventual Consistency](#eventual-consistency) | medium |

---

# CAP Theorem

---
id: SSD-011
title: CAP Theorem
category: System Design
difficulty: ★★☆
interview_weight: high
asked_at: Senior/Staff
seniority: senior
tags: #cap-theorem, #consistency, #availability, #partition-tolerance, #distributed-systems
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> CAP theorem states a distributed system can only provide 2 of 3 guarantees:
> Consistency (every read sees the most recent write), Availability (every
> request gets a response), Partition Tolerance (system works despite network
> failures). Since network partitions are unavoidable in distributed systems,
> you effectively choose between Consistency and Availability during a partition.
> CP systems (HBase, ZooKeeper) reject requests during partition to prevent
> inconsistency. AP systems (Cassandra, DynamoDB) return possibly stale data
> rather than reject requests.

**3 minutes:**
> CAP is about what happens during a network partition - when nodes can't
> communicate. This isn't a "never happens" scenario; networks fail regularly.
> A cluster split into two halves: each half must decide: accept writes
> (available, possibly inconsistent) or reject writes (consistent, unavailable).
>
> The nuanced version: CAP is often misapplied. "C" in CAP is linearizability
> (strong consistency) - not eventual consistency. Many systems described as
> "eventual consistency" don't claim linearizability but aren't fully AP either;
> they offer tunable consistency (Cassandra's consistency levels). PACELC
> extends CAP: Even when there's no partition (P), there's a tradeoff between
> Latency (L) and Consistency (C). This is the more useful model for most
> day-to-day design decisions.
>
> Practical application: for financial data (account balance), choose CP
> (returning an error is better than showing wrong balance). For social feeds,
> product listings: choose AP (slightly stale is fine). This choice propagates
> through your entire database and architecture selection.

**Blank Mind Recovery:**

**(1) Restate:** "CAP: in a distributed system, during network failure, you
choose: keep it consistent (reject requests) or available (serve possibly stale data)."

**(2) The real choice:** "Partition tolerance isn't optional - networks fail.
So the real choice: CP (consistent but may be unavailable) vs AP (available but
may be inconsistent)."

**(3) Practical:** "Financial data = CP (wrong balance is worse than 'try again').
Social feeds = AP (5 seconds stale = fine)."

---

### 📘 Concept Explanation

**CAP definitions:**

```
C - Consistency (Linearizability):
  After a write completes, ALL reads see that write
  No node returns stale data
  Equivalent to: the system acts as if there's one copy of data

A - Availability:
  Every request receives a response (not just "try later")
  Response may be stale (but there IS a response)
  No timeouts or connection refused

P - Partition Tolerance:
  System continues operating when the network between nodes fails
  Nodes can't communicate but must decide how to behave

The CAP impossibility:
  Network partition occurs: Node A can't reach Node B
  Client writes to Node A
  Client reads from Node B

  Option 1: B rejects read (unavailable but consistent)
    -> Consistency: Node B won't return stale data
    -> Availability: violated (B returned error, not response)

  Option 2: B returns its local data (available but inconsistent)
    -> Availability: B responded
    -> Consistency: violated (B may not have Node A's write yet)

  Cannot have both: must choose.

Real-world examples:
  CP systems:
    HBase: reads/writes fail during ZooKeeper partition
    ZooKeeper: requests rejected if quorum unavailable
    MongoDB (strong): reads fail if primary unreachable
    Postgres sync replication: writes fail if standby down

  AP systems:
    Cassandra: serves stale data during partition
    DynamoDB: eventually consistent reads enabled by default
    CouchDB: serves local data during partition

  Neither (single-node or non-distributed):
    MySQL single primary: not distributed -> no CAP concerns
```

> **Code walkthrough:** This CAP Theorem example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**PACELC model (more practical):**

```
PACELC: "If Partition: choose between Availability and Consistency.
         Else (no partition): choose between Latency and Consistency"

  PA/EL: AP in partition + low latency normally
    -> Cassandra (default), DynamoDB
    -> Accept staleness for low latency always

  PC/EC: CP in partition + strong consistency normally
    -> HBase, ZooKeeper, Spanner (with tradeoffs)
    -> Pay latency for consistency always

  PA/EC: AP in partition + strong consistency normally
    -> MongoDB (depends on configuration)
    -> Most distributed DBs with tunable consistency

Latency vs Consistency (no partition):
  Strong consistency: must synchronize all replicas before returning
    -> Latency = network round trip to all replicas
  Eventual consistency: return local value, sync in background
    -> Latency = local access only
  The tradeoff exists even when network is healthy
```

> **Code walkthrough:** This CAP Theorem example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

```java
// Demonstrating CP vs AP behavior with Spring Data

// CP: strong consistency read (from primary only)
// Mongo example with ReadPreference.primary()
@Repository
public class AccountRepository {

    private final MongoTemplate mongoTemplate;

    public Account findBalance(String accountId) {
        // ReadPreference.primary() = only read from primary
        // If primary unavailable: throws exception (CP behavior)
        Query query = new Query(
            Criteria.where("id").is(accountId));
        query.withHint("{ $readPreference: { mode: 'primary' } }");
        return mongoTemplate.findOne(query, Account.class);
    }
}

// AP: eventual consistency read (from any replica)
@Repository
public class FeedRepository {

    private final CassandraTemplate cassandraTemplate;

    // ConsistencyLevel.ONE = read from one replica
    // Fast, but may return stale data (AP behavior)
    public List<FeedItem> getFeed(String userId) {
        return cassandraTemplate.selectAll(
            FeedItem.class);  // ConsistencyLevel.ONE default
    }
}

// Configurable consistency (Cassandra tunable):
@Repository
public class OrderRepository {

    private final CassandraTemplate cassandraTemplate;

    // ConsistencyLevel.QUORUM = read from majority
    // Consistent within the data center
    public Optional<Order> findOrder(UUID orderId) {
        return Optional.ofNullable(
            cassandraTemplate.selectOne(
                Select.builder()
                    .where(Criteria.where("id").is(orderId))
                    .build(),
                Order.class));
    }
}
```

> **Code walkthrough:** These three examples show the CP/AP choice at the codeice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> level. Account balance uses MongoDB primary-read preference: any failure of
> the primary returns an exception (not stale data). This is CP - the system
> chooses consistency over availability. The feed repository uses Cassandra ONE -
> any replica responds; stale feed items are acceptable. This is AP. The order
> repository uses QUORUM - reads from majority of replicas, ensuring strong
> consistency within the datacenter. In Cassandra's model: QUORUM reads + QUORUM
> writes with RF=3 gives strong consistency even without a single primary.
> The key design decision is made at the persistence layer, not the service layer.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> CAP theorem says you can't have perfect consistency, availability, and partition
> tolerance all at once in a distributed system. When the network fails (partition),
> you have to choose: do you want the system to stay consistent (return errors rather
> than stale data) or available (return whatever data it has, even if old)?
> For a bank account: choose consistency - returning a wrong balance is worse
> than a "service unavailable" error. For a social media feed: choose availability
> - slightly old posts are fine.

**Senior / Staff:**
> The practical value of CAP is the conversation it forces about failure behavior.
> Before CAP, engineers might not explicitly decide what their system does during
> a network partition. CAP forces that decision. The PACELC extension is more
> useful: even without a partition, you're trading consistency for latency on
> every write. Cassandra at QUORUM is consistent but slower; at ONE, it's fast
> but eventually consistent. Google Spanner provides external consistency
> (stronger than linearizability: across multiple machines globally) using GPS
> and atomic clocks for synchronized timestamps. It pays in latency: ~1-10ms
> per cross-region transaction. The CAP conversation should end with: "For this
> specific data type in our system, we accept [staleness X] in exchange for
> [latency/availability Y], and here's how we'll handle the edge cases."

---

### ⚠️ Common Misconceptions

**Misconception: "You can avoid choosing between C and A by avoiding partitions."**
Network partitions happen regardless of design: hardware failures, software
bugs, network upgrades, overloaded switches, misconfigured firewalls. You can
minimize their frequency but not eliminate them. For intra-datacenter systems,
partitions are rare (milliseconds, quickly resolved). For multi-region systems,
they're more common and longer. CAP says: you must decide your behavior for
when they occur, even if that's rarely. "We'll deal with it when it happens"
is a costly plan when "it" is 2 AM and money is involved.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Stale reads in AP system cause business logic errors**
Symptom: user clicks "buy" when item shows as available (stale read from AP replica),
but item was already sold (primary has it as sold out). Order processed, item not
available: oversell.
Diagnosis: log consistency level on each critical read; audit reads of inventory
state.
Fix: use strong consistency (QUORUM) reads for inventory check before purchase.
Accept AP staleness for display (product listing) but use CP for transactional
reads (inventory reservation).

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] How do HBase and Cassandra exemplify CP vs AP?**

**HBase (CP):**
```plaintext
Architecture:
  Writes go to RegionServer (process that owns the data region)
  RegionServer determined by ZooKeeper (distributed coordinator)

During partition:
  ZooKeeper unavailable or RegionServer unreachable:
  HBase: returns error (service unavailable)
  Reason: cannot guarantee consistency without knowing
          current state of RegionServer

  During partition: reads MAY succeed (from local region servers)
  but certain operations (region splits, compaction) stall
  Strong consistency: if you can read, it's correct

Why CP:
  HBase used for: financial data, metadata for HDFS,
                  time-series data where correctness matters
  Stale data in HBase = incorrect analytics = business impact
  Design choice: error is better than wrong answer
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Cassandra (AP):**
```
Architecture:
  No single master; any node can handle any request
  Data: RF=3 copies across 3 nodes
  Consistency level ONE: read from nearest replica

During partition:
  Node A is partitioned from nodes B and C
  Client writes to Node A: success (available)
  Client reads from Node B: returns old data (stale)
  -> Available but inconsistent

  After partition heals:
  Read repair: when nodes B/C see Node A's write,
               they update to latest version
  Anti-entropy: background sync to reconcile divergence

Why AP:
  Cassandra used for: social media (likes, comments, feeds),
                      IoT time-series, product catalogs
  "Like count slightly off during partition": acceptable
  "Service down during partition": unacceptable
  Design choice: availability is the priority
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The choice isn't just about partition behavior
but about the operational model. Cassandra requires no single primary, so there's
no failover (any node can take reads/writes). HBase requires ZooKeeper for
coordination, adding operational complexity (ZooKeeper quorum management). In
practice: teams choose HBase for analytics in the Hadoop ecosystem and Cassandra
for high-write-rate operational workloads. The CAP classification is a guide,
not the only criterion.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What is linearizability and how does it relate to CAP's "C"?**

```plaintext
Linearizability (CAP's "C"):
  The strongest consistency model
  Requirement: every operation appears to take effect
               at a single point in time between its start and end

  Example:
    T=0: Writer A starts writing value X=100
    T=1: Reader B starts reading X
    T=2: Writer A finishes write
    T=3: Reader B finishes read

    Linearizability: Reader B at T=3 must see X=100
    (write completed at T=2, before read finished at T=3)

  Guarantee: the system looks like a single computer
             with a single copy of data

Weaker consistency models:
  Sequential consistency:
    Operations appear in some sequential order
    Order consistent with each process's program order
    But: reads may not see writes from other processes immediately

  Causal consistency:
    Causally related operations appear in causal order
    "If A caused B, everyone sees A before B"
    Unrelated operations may appear in different orders

  Eventual consistency:
    All replicas converge to same value eventually
    No guarantees on timing or intermediate reads
    "Eventually" = milliseconds to hours depending on system

  Read-your-writes (session consistency):
    You always see your own writes
    Others may not see your writes yet
    Weaker than linearizability, stronger than eventual
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Spanner achieves external consistency (stronger
than linearizability) across globally distributed shards using TrueTime (GPS +
atomic clocks for synchronized timestamps). Each transaction gets a timestamp;
reads are consistent at a timestamp. This allows "read at time T" queries that
return a globally consistent snapshot even across multiple regions. The price:
Spanner's Paxos-based writes with TrueTime delays add 10-30ms per cross-region
write. For most use cases: linearizability per-region (Postgres synchronous
standby) is sufficient. Global linearizability (Spanner) is needed only for
truly global, strongly consistent data.

---

**[JUNIOR] Q3 - [CONCEPTUAL] How does Google Spanner "solve" CAP?**

Spanner: globally distributed, strongly consistent database.

```plaintext
Spanner claim: "externally consistent" (equivalent to linearizability)
               across globally distributed shards

How it achieves this:

TrueTime API:
  Google's time service with GPS + atomic clocks
  Returns time interval: [earliest, latest]
  Uncertainty: typically <10ms globally

Timestamp ordering:
  Every read and write gets a TrueTime timestamp
  All transactions ordered by commit timestamp
  Two transactions: T1 before T2 if T1.latest < T2.earliest

Commit wait:
  After Spanner chooses a commit timestamp:
  It WAITS until TrueTime uncertainty resolves
  (until current_time > commit_timestamp)
  Wait = ~10ms (typical TrueTime uncertainty)
  Purpose: ensures no other transaction can have EARLIER timestamp
           in a different region

Result:
  Any subsequent read sees all committed transactions with earlier timestamps
  Global causal ordering maintained
  Reads from any region: consistent (no stale reads)

Does this "violate" CAP?
  No: during partition, Spanner blocks (chooses CP)
  The achievement: when NOT partitioned (99.99% of time):
                   low-latency reads WITH strong consistency
  PACELC perspective: Spanner chose PC/EC
                      (consistent + higher latency, no partition vs latency tradeoff)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Spanner doesn't violate CAP. During partition,
it blocks (unavailable). What Spanner achieves: strong consistency without
requiring all nodes to communicate on every read (using timestamp-based reads).
Most strongly-consistent systems require quorum reads (contact majority of nodes).
Spanner's reads are cheap when the data is "old enough" (older than TrueTime
uncertainty). This makes Spanner practical where other CP systems would be too slow.
The practical insight: Google built custom hardware (TrueTime) to solve a
software problem. Most companies cannot replicate this; they use Spanner as
a service (Cloud Spanner) instead.

---

**[MID] Q4 - [TRADE-OFF] When would you choose AP over CP for a real system?**

AP trade-off decisions in practice:

```plaintext
Choose AP (eventual consistency) when:

  Product catalog:
    "Product is in stock" from 5 seconds ago = fine
    User sees "in stock" but item sold out in last 5 sec
    Worst case: order fails at checkout (handled by CP inventory check)
    AP for display: read from replica (fast)
    CP for transaction: strong-consistent inventory reservation

  Social media likes:
    Post shows 1,500 likes (actual: 1,502)
    User clicks like: see "1,501" immediately (optimistic update)
    Actual count eventually syncs to all replicas
    Business: 0.1% stale like count = not a problem

  User session data:
    User's theme preference stored in session
    Two replicas have slightly different last-seen session
    Stale: user sees old theme for 1 second
    Not critical: not financial, not safety-critical

  DNS:
    DNS record updated: new IP for myapp.com
    DNS propagates over minutes to hours (by design)
    Users may resolve old IP for hours
    AP by design: DNS prioritizes availability (always returns something)
    Consistency: not required (old IP will fail, retry)

Choose CP (strong consistency) when:

  Bank balance:
    User sees $100, withdraws $80, sees $20 (correct)
    With stale read: sees $100, withdraws $80 on two devices
    Both succeed (stale: both saw $100), balance goes to -$60
    Business: unacceptable (regulatory + financial loss)

  Inventory reservation:
    Last item: only one customer should get it
    AP: two customers see "1 available", both buy
    Both receive confirmation (oversell)
    CP: second buyer gets "out of stock" immediately
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The nuanced answer: most systems use both
AP and CP for different operations. Display operations (showing product prices,
counts, listings): AP (fast, good UX, stale is fine). Transactional operations
(checkout, payment, inventory deduction): CP (correctness required). This hybrid
approach is called "BASE for reads, ACID for writes." The product catalog reads
from Cassandra (AP), but the inventory reservation writes to Postgres (CP). The
architectural boundary: CQRS separates the read model (AP, denormalized,
eventually consistent) from the write model (CP, normalized, strongly consistent).

---

**[MID] Q5 - [ARCHITECTURE] How does distributed consensus (Paxos, Raft) relate to CP systems?**

CP systems need consensus to elect a leader and agree on state:

```
Why consensus:
  In a CP system during partition: one partition must "win"
  Can't have two nodes both acting as primary (split-brain)
  Need: agree on which node is leader
  Problem: distributed agreement is hard (Byzantine generals)

Raft algorithm (simpler than Paxos):
  Roles: leader, follower, candidate
  Term: monotonically increasing election period

  Leader election:
    No heartbeat received -> follower starts election
    Sends RequestVote to all nodes
    If majority votes yes -> becomes leader
    New leader: all writes go through it

  Log replication:
    Leader: receives write, appends to log
    Leader: sends AppendEntries to followers
    Majority ACK: entry committed (safe to apply)
    Minority ACK: wait (retries until majority)

  Partition behavior:
    Network splits: [Leader + 2 followers] vs [2 followers]
    Minority partition: no new leader (can't get majority)
    Majority partition: leader continues (has quorum)
    Result: minority = unavailable (CP: consistency preserved)

  Systems using Raft:
    etcd (Kubernetes state store)
    CockroachDB
    TiKV
    Consul
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Raft's design principle: understandability
over efficiency. Paxos is theoretically elegant but notoriously hard to implement
correctly. Raft separates concerns (leader election + log replication) and uses
randomized timers for election (simpler than Paxos's multi-round protocol).
In practice: most distributed system practitioners now prefer Raft. The etcd
and Consul implementations of Raft are production-proven at massive scale.
The failure mode that requires deep understanding: Raft leader election under
high CPU load (timers fire late -> false leader elections). Tuning: increase
heartbeat timeout for loaded systems. etcd defaults: heartbeat 100ms, election
timeout 1000ms; increase for loaded systems.

---

**[MID] Q6 - [CONCEPTUAL] How would you explain CAP to a product manager?**

Non-technical CAP explanation:

```plaintext
Analogy: Bank branch during network outage

  Scenario: bank's central server is down
  Branch has local records (possibly outdated)

  Option CP (bank closes teller windows):
    "Sorry, our systems are down. We can't process
    transactions until connection is restored."
    -> You get consistent (no stale data)
    -> You are unavailable (no service)

  Option AP (bank uses local records):
    "We can process with our local records.
    Some recent transactions may not be reflected."
    -> You are available (service continues)
    -> Data may be stale (missing recent transactions)

For a product manager:
  Question: "When our database servers can't communicate
             with each other (network problem), what should
             the app do?"

  Option A: "Show an error, don't let users proceed"
    -> Correct data, but users are blocked (CP)

  Option B: "Keep working with possibly outdated info,
             fix discrepancies later"
    -> Users can proceed, but some actions may be wrong (AP)

  Answer depends on: what's the cost of an error?
    Banking: wrong = costly (choose CP)
    Shopping cart: wrong = annoying but recoverable (choose AP)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The CP vs AP choice should be visible in
the product's error messages. A CP system during partition: "Service temporarily
unavailable. Please try again." A AP system: "Your request was submitted.
It may take a few moments to appear." Product managers must understand this
because it affects UX design. "Why does the app sometimes show a loading error?"
-> CP system. "Why does my like count sometimes flicker?" -> AP system.
Making these tradeoffs explicit in product design (not just in backend architecture)
leads to better UX and fewer "bug" reports about expected system behavior.

---

**[SENIOR] Q7 - [DEBUGGING] What is the PACELC theorem and why is it more useful than CAP?**

PACELC: extends CAP to cover normal (non-partition) operation.

```
CAP limitation:
  Only describes partition scenarios
  Most of the time (99.9%+): no partition
  But: there IS still a latency vs consistency tradeoff
  CAP doesn't model this

PACELC formulation:
  If Partition (P):
    Choose Availability (A) or Consistency (C)
  Else (E):
    Choose Latency (L) or Consistency (C)

Four quadrants:
  PA/EL: AP in partition + low latency normally
    Dynamo, Cassandra, Riak
    Sacrifice consistency always (partition or not)
    Choose: speed and availability over correctness

  PC/EC: CP in partition + high consistency normally
    HBase, Spanner (mostly), Postgres sync standby
    Pay latency always for correctness
    Choose: correctness over speed

  PC/EL: CP in partition + low latency normally
    Mongo, MySQL async replicas
    During partition: consistent (reject)
    Normal: fast (async replicas can serve stale)
    Middle ground

  PA/EC: AP in partition + strong consistency normally
    Rare in practice (if AP during partition, hard to ensure
    consistency without partition)

Why PACELC is more useful:
  Real-world question: "My system is healthy (no partition).
  Is my DB adding latency for consistency checks?"
  Cassandra at QUORUM: yes, reads are slower
  Cassandra at ONE: no, reads are fastest (but stale)
  CAP can't answer this; PACELC can
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* PACELC reframes the design question from
"what do we do during failure?" to "what is our ongoing consistency vs latency
tradeoff?" This is more actionable. In a Cassandra deployment: "We're using
LOCAL_ONE for reads (PA/EL) because our SLO is P99 < 5ms and we accept eventual
consistency." This is a conscious PACELC decision. CAP-only thinking might lead
to: "We use Cassandra because it's AP." That statement doesn't describe the
normal-operation behavior. PACELC forces the follow-up question: "And for normal
operation: latency or consistency?"

---

**[SENIOR] Q8 - [ARCHITECTURE] How do vector clocks resolve conflicts in AP systems?**

Vector clocks: track causality to resolve write conflicts.

```plaintext
Problem: AP system, two concurrent writes, which wins?

  User A (on server 1): updates profile name to "Alice"
  User B (on server 2): updates same profile to "Bob"
  Partition: servers 1 and 2 can't communicate

  After partition heals: which value is correct?
  Last-write-wins: compare timestamps
    Risk: clock skew -> wrong winner
    Clocks on distributed systems not perfectly synchronized

Vector clock approach:
  Every update tagged with a vector clock
  Clock = map of {node_id: counter}

  Initial: Profile: {name: "Original", vc: {}}

  User A writes "Alice" on server 1:
    vc: {server1: 1} -> "Alice"

  User B writes "Bob" on server 2 (concurrently, partition):
    vc: {server2: 1} -> "Bob"

  After partition heals, server 1 and 2 must merge:
    {server1: 1} and {server2: 1} are concurrent (incomparable)
    Neither happened before the other
    -> Conflict: application must resolve

  Conflict resolution options:
    Last-write-wins by application timestamp: "Alice" if Alice wrote later
    Merge: combine both (good for shopping cart: union of items)
    Ask user: "You have two versions, which to keep?" (Amazon cart strategy)
    Domain-specific: CRDT types auto-resolve (G-Counter, LWW-Register)

  If User B had seen User A's write first (no partition):
    User B reads "Alice" (vc: {server1:1})
    User B writes "Bob" (vc: {server1:1, server2:1})
    -> server2's write causally follows server1's
    -> No conflict: Bob wins clearly
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Vector clocks track causality, not just time.
They tell you: "Did writer B know about writer A's write when B wrote?" If yes:
B's write causally supersedes A's (no conflict). If no: concurrent (conflict).
This is strictly more accurate than timestamp comparison (which requires perfect
clock sync, impossible in distributed systems). Amazon Dynamo uses vector clocks
for its shopping cart. When conflicts occur: Dynamo returns both versions to the
client and asks the client to resolve (merge). The Amazon engineering insight:
the client (user's browser or application) has the business context to resolve
the conflict (union of shopping cart items = correct merge for most cases).

---

**[SENIOR] Q9 - [ARCHITECTURE] How does the CAP theorem apply to designing a payment processing system?**

Payment processing: CAP analysis for a money-critical system.

```
Payment operations and their CAP requirements:

1. Show account balance (display):
   Staleness tolerance: LOW (user expects accurate balance)
   Choice: CP reads (from primary, no replicas)
   Rationale: showing $100 when balance is $20 causes overdraft

2. Initiate payment:
   Choice: CP (strongly consistent)
   Process:
     a. Check balance (CP read from primary)
     b. Debit account (CP write with distributed lock)
     c. Credit recipient (CP write)
   Failure mode: if step c fails: saga compensation (re-credit)

3. Payment history (list of transactions):
   Staleness tolerance: HIGH (5-minute old list = fine)
   Choice: AP reads from replica
   Rationale: display only, no transactional decision made

4. Fraud detection:
   Choice: CP or AP depending on approach
   Real-time rule evaluation: AP ok (rule triggers async alert)
   Block fraudulent payment: CP (must be before authorization)

System architecture:
  Core payment ledger: CP (Postgres sync replication, ACID)
  Balance cache: AP with short TTL (Redis for fast reads)
  Transaction history: AP (read replicas or Cassandra)
  Fraud rules: event streaming (Kafka), near-real-time, AP

Pattern: CP core (ledger) + AP periphery (everything else)
  Money in motion: CP always
  Informational reads: AP for performance
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using Kafka messaging. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Payment systems don't use a single database
with a single consistency level. The money-critical path (debit, credit, reserve)
uses ACID transactions with CP reads. The informational path (history, analytics,
notifications) uses AP. This is standard practice at Stripe, PayPal, and all
payment processors. The architectural boundary between CP and AP paths is
carefully defined: any operation that affects a monetary balance crosses the CP
boundary. Any read-only or informational operation can use AP. The team tests
this boundary explicitly: "If the AP replica returns stale data here, what is
the worst-case business outcome?" If the answer is "a wrong debit or credit":
that operation must be on the CP path.

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


# Eventual Consistency

---
id: SSD-012
title: Eventual Consistency
category: System Design
difficulty: ★★☆
interview_weight: high
asked_at: Senior/Staff
seniority: senior
tags: #eventual-consistency, #base, #conflict-resolution, #crdt, #convergence
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Eventual consistency means that if no new updates are made, all replicas will
> converge to the same value. Writes don't wait for all replicas to confirm;
> replicas sync asynchronously. The application must tolerate reading stale values
> for short periods. BASE (Basically Available, Soft state, Eventually consistent)
> is the alternative to ACID for systems that prioritize availability. Handling
> eventual consistency: design operations to be idempotent, use last-write-wins
> or CRDTs for conflict resolution, and distinguish display operations (AP ok)
> from transactional operations (need strong consistency).

**3 minutes:**
> Eventual consistency is a liveness guarantee, not a safety guarantee. It says:
> "you'll get there eventually" but doesn't say when. The practical question:
> what is the convergence time? In Cassandra with fast anti-entropy: milliseconds
> to seconds. In a system with poor network connectivity: minutes. In a sync-on-next-read
> system: never if the key is never read again.
>
> Conflict resolution is the hard part. If two replicas accept writes to the
> same key before syncing, they diverge. Resolution strategies: last-write-wins
> (simple, risk of clock skew), multi-value (return all versions, let client pick),
> CRDT (data structures that auto-merge without conflict). CRDTs are the elegant
> solution: counters (G-Counter: increment-only, no conflict), sets (G-Set:
> union is conflict-free), registers (LWW-Register: timestamp-based).
>
> The common mistake: treating eventual consistency as "it'll be fine eventually"
> without explicitly handling the intermediate stale state. Applications must be
> designed to tolerate and communicate uncertainty during the convergence window.

**Blank Mind Recovery:**

**(1) Restate:** "Eventual consistency: all copies of data will eventually agree,
but at any moment some copies may be stale."

**(2) First principles:** "Replicas sync in the background. Between writes and sync:
different replicas have different values. This is the 'eventual' window."

**(3) Three issues:** (a) how long is eventual? (b) how to resolve conflicts?
(c) what to show users during the window?

---

### 📘 Concept Explanation

**Consistency models spectrum:**

```plaintext
Strongest:                              Weakest:
Linearizability -> Sequential -> Causal -> Read-your-writes -> Eventual

Linearizability:
  All operations have a global total order
  Reads always see the latest write (globally)
  Cost: all reads/writes must coordinate globally

Sequential consistency:
  All operations appear in some consistent sequential order
  Each node's operations in program order
  Reads may see slightly stale values (not guaranteed to see latest)

Causal consistency:
  Causally related operations appear in causal order
  "If A caused B, everyone sees A before B"
  Unrelated operations may appear in different orders per node

Read-your-writes (session consistency):
  A session always sees its own writes
  Other sessions may not see your writes yet
  Common: user expects to see their own posts immediately

Eventual consistency:
  If no new updates: all replicas converge to same value
  No guarantee on: intermediate reads, convergence time
  Weakest useful guarantee in distributed systems
  Examples: DNS propagation, social feeds, shopping carts
```

> **Code walkthrough:** This Eventual Consistency example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**BASE vs ACID:**

```
ACID (traditional relational DBs):
  Atomicity: transaction is all-or-nothing
  Consistency: transaction brings DB from valid to valid state
  Isolation: concurrent transactions don't interfere
  Durability: committed data persists

BASE (eventual consistency systems):
  Basically Available: system is available most of the time
                       (degraded if needed, but not down)
  Soft state: state may change without input (due to replication)
             "my local cache may be stale; it's soft"
  Eventually consistent: all nodes will converge to same state
                          given sufficient time without new updates

Not mutually exclusive:
  Cassandra: BASE by default
             QUORUM reads+writes: effectively ACID-like
  Mongo: BASE by default
         Transactions (v4+): ACID within a session

The spectrum: pure BASE <-------> pure ACID
  Cassandra ONE: BASE
  Cassandra QUORUM: weak ACID
  Postgres async replica: mostly ACID primary, BASE reads
  Postgres sync replica: ACID everywhere
```

> **Code walkthrough:** This Eventual Consistency example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// Eventual consistency example: distributed counter
// BAD: non-idempotent counter increment
@Service
public class CounterService {
    private final RedisTemplate<String, Long> redis;

    public void incrementLikes(Long postId) {
        // Not idempotent: if message delivered twice -> count++twice
        redis.opsForValue().increment("likes:" + postId);
    }
}
// Problem: in at-least-once delivery, message may be delivered
//          twice -> like count inflated
// Network retry: client retries -> double increment

// GOOD: idempotent operation (set instead of increment)
@Service
public class LikeService {
    private final RedisTemplate<String, String> redis;

    // Track WHO liked (set), not just count (number)
    public void like(Long postId, Long userId) {
        // Set add: idempotent (adding same element twice = no change)
        redis.opsForSet().add(
            "likes:" + postId,
            userId.toString());
    }

    public void unlike(Long postId, Long userId) {
        redis.opsForSet().remove(
            "likes:" + postId,
            userId.toString());
    }

    public Long getLikeCount(Long postId) {
        return redis.opsForSet().size("likes:" + postId);
    }
}
// Set membership is idempotent: same user can "like" twice
// Result: counted once (no duplicates)
// This is a simple CRDT: G-Set (Grow-only Set)
// Convergence: if all nodes have the same set of user IDs who liked,
// the count converges correctly
```

```java
// Conflict resolution with last-write-wins + version
@Entity
public class UserProfile {
    @Id
    private Long id;
    private String name;
    private String photo;

    // Version for optimistic concurrency
    @Version  // JPA managed: incremented on each write
    private Long version;

    // Timestamp for LWW conflict resolution
    private Instant updatedAt;
}

// Conflict resolution service:
@Service
public class ProfileSyncService {

    // Called when two replicas have conflicting updates
    public UserProfile resolveConflict(
            UserProfile local, UserProfile remote) {
        // Last-Write-Wins: take the most recent update
        if (remote.getUpdatedAt().isAfter(local.getUpdatedAt())) {
            return remote;
        }
        // LWW limitations: requires synchronized clocks
        // NTP keeps clocks within ~5ms; good enough for most cases
        return local;
    }
}

// Better: CRDT-based merge for collaborative docs
@Service
public class DocumentMergeService {

    // Merge two versions: take union of all changes
    public Document merge(Document v1, Document v2) {
        // Operational transform or CRDT merge
        // Key principle: no change is lost in conflict resolution
        // Both v1 and v2 additions appear in merged result
        return Document.merge(v1, v2);  // CRDT merge
    }
}
```

> **Code walkthrough:** The BAD counter increments a number non-idempotently.
> If the increment message is delivered twice (at-least-once delivery in Kafka):
> count is wrong. The GOOD approach tracks WHO liked (Set) instead of count.
> Redis sets are idempotent: `SADD likes:42 userId` twice = set has userId once.
> Count = set size. This is a G-Set CRDT. The conflict resolution example shows
> last-write-wins with timestamps. LWW works for most user-facing data (profile
> updates) but fails when concurrent updates are both valid (collaborative editing).
> For collaborative editing: operational transforms (Google Docs) or CRDTs (Figma).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Eventual consistency means that all copies of data will end up being the same
> eventually, but at any given moment some copies might have older data. It's like
> syncing your phone - your phone has old data until it connects to the server.
> This is fine for non-critical data like social media likes or product descriptions,
> but not for financial transactions where you need accurate data right now.

**Senior / Staff:**
> The failure mode of eventual consistency is subtle: stale reads in business
> logic, not just display. The common mistake: use an eventually consistent read
> to check inventory ("is this item in stock?"), then do a strongly consistent
> write to debit the balance. The inventory check might be stale (item is sold,
> but replica shows it's available). The write succeeds. Now you've sold an item
> you don't have. Fix: inventory reservation must be strongly consistent (read
> and write within the same ACID transaction or using compare-and-swap). Rule:
> never make a transactional decision based on an eventually consistent read.
> The display (showing "in stock" on product page) can be eventually consistent.
> The reservation (actually holding the item for purchase) cannot.

---

### ⚠️ Common Misconceptions

**Misconception: "Eventual consistency means data may never be consistent."**
"Eventually" means: given no new updates and a working network, replicas WILL
converge. This typically happens in milliseconds to seconds in modern systems.
The "stale window" is short. The concern isn't permanent divergence but
the brief window where replicas disagree. Systems measure this as "replication lag"
(milliseconds). Divergence grows only if the network is partitioned (broken)
or if the conflict resolution algorithm is flawed. Well-designed eventual
consistency systems converge reliably and quickly.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Phantom reads from stale cache causing double-spend**
Symptom: user balance shows $100 on two devices simultaneously (replication lag),
user initiates two $80 withdrawals from both devices, both succeed, balance -$60.
Root cause: balance read from AP replica (stale), debit logic doesn't use
compare-and-swap or serializable transaction.
Fix: balance debit must use optimistic locking (check balance at transaction time
using SELECT FOR UPDATE or CAS: UPDATE account SET balance = balance - 80
WHERE balance >= 80 AND id = X - rows updated = 0 -> fail), never rely on
pre-read balance from possibly stale source.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] How does anti-entropy repair work in Cassandra?**

Anti-entropy: background process to ensure replicas converge.

```
Problem:
  RF=3: data on 3 nodes
  Node 2 was down for 1 hour (hardware issue)
  During downtime: writes went to Nodes 1 and 3 only
  Node 2 misses those writes (hint delivery may have failed)
  After recovery: Node 2 has stale data

Anti-entropy mechanisms:

1. Hinted Handoff (short-term):
  If Node 2 is down during write:
  Coordinator stores "hint" (deferred write for Node 2)
  When Node 2 comes back: coordinator delivers hints
  Window: hints stored for `max_hint_window_in_ms` (3 hours default)
  After 3 hours: hints discarded (too old)

2. Read Repair (continuous):
  On every read: Cassandra reads from multiple replicas
  If replicas return different values: repairthe stale one
  Inconsistency_chance: % of reads that do background repair
  Default: 10% (10% of reads trigger full repair check)

3. Full Repair (manual/scheduled):
  nodetool repair: compares all data on two nodes
  Algorithm: Merkle tree hash comparison
    Build Merkle tree of data on each node
    Compare trees: different subtrees = different data
    Exchange only differing segments (efficient)
  Cost: high CPU and I/O during repair
  Frequency: run every `max_hint_window_in_ms` / 2
             (before hints expire)

Repair failure:
  Node 2 down for > max_hint_window_in_ms (3 hours)
  Hints discarded
  Node 2 rejoins with stale data
  Without repair: reads from Node 2 return stale results
  With repair: full repair brings Node 2 up to date
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Anti-entropy repair is operationally critical
in Cassandra deployments but often neglected. The common failure: nodes miss hints
(down > 3 hours), come back with stale data, and nobody runs repair. Result: stale
reads gradually appear without clear cause. Best practice: run `nodetool repair`
on every node, on a rotating schedule, once per `max_hint_window_in_ms / 2`.
Tools: Cassandra's built-in scheduled repair (Cassandra 4.0+) or Reaper (open source).
Monitor: `nodetool compactionstats` and repair history. A Cassandra cluster that
has never been repaired is accumulating staleness silently.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What are CRDTs and which problems do they solve?**

CRDT (Conflict-free Replicated Data Type): data structures that auto-merge.

```
Core insight: for some data types, concurrent writes can be merged
              without conflict, without coordination

Classic CRDTs:

G-Counter (Grow-only Counter):
  Each node has its own counter
  Node 1: {node1: 5, node2: 0, node3: 2}
  Node 2: {node1: 4, node2: 3, node3: 2} (stale node1 count)
  Merge: take max per node: {node1: 5, node2: 3, node3: 2}
  Value: sum = 10
  Operation: only increment (no decrement)
  Use: page views, event counts

PN-Counter (increment/decrement counter):
  Two G-Counters: P (positive) and N (negative)
  Value = sum(P) - sum(N)
  Merge: merge both G-Counters independently
  Use: inventory levels, votes (+1/-1)

G-Set (Grow-only Set):
  Set that supports only add (no remove)
  Merge: union of both sets
  Conflict-free: adding element twice = element once (idempotent)
  Use: tags, likes, unique visitors

2P-Set (add and remove):
  Two G-Sets: A (added) and R (removed)
  Value: A - R (elements in A but not in R)
  Limitation: once removed, can't re-add
  Use: shopping cart (add + remove items)

LWW-Element-Set:
  Each element has a timestamp
  LWW wins: if add_timestamp > remove_timestamp -> element in set
  Use: distributed user presence (online/offline)

OR-Set (Observed-Remove Set):
  Unique tag per add operation
  Remove: only removes specific tag (not all occurrences)
  Allows add-remove-add cycle
  Use: shopping cart, todo list
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* CRDTs are now in production at major scale.
Redis CRDT (Redis Enterprise): multi-master Redis with CRDT data types.
Riak: pioneered CRDT usage in databases. Figma uses CRDTs for collaborative
real-time editing. The limitations: CRDTs work for the specific operations
they support (add, remove, increment). For general-purpose conflict resolution
(arbitrary field updates), CRDTs aren't applicable. The engineering
decision: if the data type's operations can be modeled as a CRDT, use it
(eliminates all conflict resolution code). If not: need last-write-wins,
multi-value, or operational transform.

---

**[JUNIOR] Q3 - [CONCEPTUAL] How does the read-repair process work and what are its limitations?**

Read repair: correct inconsistencies on-the-fly during reads.

```
Read repair in Cassandra (default):

Step 1: Coordinator receives read request
  Coordinator: sends read to enough replicas (per consistency level)
  Example QUORUM (N=3): reads from 2 replicas

Step 2: Digest read (efficient comparison)
  Coordinator: reads full data from 1 replica
  Coordinator: reads digest (hash of data) from other replicas
  Compare: if digest matches -> no repair needed (fast path)
  If digest mismatch -> inconsistency detected

Step 3: Full repair
  Coordinator: reads full data from all replicas
  Coordinator: determines latest version (by timestamp)
  Coordinator: sends WriteRequest to stale replica
  Stale replica: updates to latest value

Two repair modes:
  Blocking read repair:
    Repair happens synchronously
    Client waits for repair to complete
    Higher latency (waits for write to stale replica)
    Consistency level: ALL triggers this

  Background read repair:
    Repair happens asynchronously
    Client gets response immediately
    Stale replica updated in background
    Consistency level: QUORUM, ONE

Limitations:
  Read repair only repairs data that is READ
  Rows never read: never repaired by read repair
  Solution: nodetool repair for unread data

  Read repair requires reading multiple replicas
  For large rows: digest mismatch -> read full data from all
  Large row inconsistency: expensive repair (multiple large reads)

  Tombstones: deleted data (tombstones) must also be repaired
  Without repair: deleted tombstones may resurface after GC grace period
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The GC grace period in Cassandra is the
most subtle consistency issue. When data is deleted: a tombstone is written.
Tombstones are kept for `gc_grace_seconds` (default 10 days) before being
garbage collected. During 10 days: deleted data appears as "not present" but
tombstone is there to inform other replicas. After 10 days: tombstone is GC'd.
If a replica was down during delete and comes back after GC: it has the data
without the tombstone. Without repair: it serves the "deleted" data again as
if it's present. This is the Cassandra resurrection bug. Fix: run repair on all
nodes within gc_grace_seconds of the delete. This is why regular repair is
non-negotiable in production Cassandra clusters.

---

**[MID] Q4 - [ARCHITECTURE] How does the saga pattern implement eventual consistency for distributed transactions?**

Saga: sequence of local transactions with compensating rollbacks.

```
Saga vs 2PC:
  2PC: locks resources, synchronous, blocking
  Saga: local transactions, async events, compensating transactions

Choreography Saga:
  No central coordinator
  Each service listens for events and reacts

  Order Saga (checkout flow):
  1. OrderService: create order (PENDING) -> publish "OrderCreated"
  2. PaymentService: on "OrderCreated" -> charge payment
      -> success: publish "PaymentConfirmed"
      -> failure: publish "PaymentFailed"
  3. InventoryService: on "PaymentConfirmed" -> reserve inventory
      -> success: publish "InventoryReserved"
      -> failure: publish "InventoryFailed"
  4. OrderService: on "InventoryReserved" -> update order CONFIRMED
  5. NotificationService: on "InventoryReserved" -> send email

  Compensation (if InventoryFailed):
  4a. PaymentService: on "InventoryFailed" -> refund payment
      -> publish "PaymentRefunded"
  4b. OrderService: on "PaymentRefunded" -> cancel order
      -> publish "OrderCancelled"

  Intermediate state:
    After step 1: order PENDING (exists), payment not yet charged
    After step 2: payment charged, inventory not reserved
    User CAN see this intermediate state (eventually consistent)
    Final state: either CONFIRMED or CANCELLED

Orchestration Saga:
  Central saga orchestrator manages the workflow
  OrderSagaOrchestrator: calls each service, handles failures
  Pros: centralized error handling, easier to debug
  Cons: more coupling, orchestrator is a SPOF
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Idempotency is critical in saga implementations.
Events can be delivered more than once (at-least-once delivery in Kafka). If
PaymentService charges the payment twice: double charge. Fix: idempotency key
on every saga step. PaymentService: before charging, check if payment already
made for this order_id. If yes: skip (return already-confirmed result). The
idempotency key (order_id + saga_step) stored in the service's DB. `INSERT INTO
processed_events (id) VALUES (order_id) ON CONFLICT DO NOTHING` - if row exists,
skip processing. This pattern ensures that re-delivered messages don't cause
duplicate operations.

---

**[MID] Q5 - [ARCHITECTURE] How do you handle user sessions in an eventually consistent system?**

Session management with eventual consistency:

```
Scenario: user logs in (session created), makes request
  Request may go to any server
  Server must know the user is authenticated

Option 1: Session affinity (sticky sessions) - avoid this
  LB routes same user to same server
  Server stores session in memory
  Problem: defeats horizontal scaling, server failure = logout

Option 2: Centralized session store (Redis)
  Login: write session to Redis
  Request: check Redis for session token
  Consistency: Redis is single-node (not eventually consistent for writes)
  But reads: can use replica (eventually consistent)
  Risk: if read from replica, session created 50ms ago may not be visible

  Solution: read-your-writes for session tokens
    Login response: include session token + server-side timestamp
    Subsequent requests: read from Redis primary for first N requests
    After warmup: read from replica

Option 3: JWT (stateless sessions)
  Login: server issues JWT (signed token)
  JWT contains: user_id, roles, expiry (embedded in token)
  Request: server verifies JWT signature (no DB lookup!)
  Eventually consistent: no replicas, no lag, no session store
  Problem: cannot invalidate JWT before expiry
           (logout doesn't truly log out; token still valid until expiry)
  Solution: short expiry (15 minutes) + refresh token
            or: JWT revocation list in Redis (small set)

Option 4: Eventual consistency for non-critical session data
  User preferences (theme, language): eventual consistency OK
  Stored in replica: user sees old theme for 5 seconds after change
  Auth token: never eventually consistent (must be strongly consistent)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The JWT vs server-side session debate is
about the consistency vs revocation trade-off. JWT is stateless (no DB lookup
= fast, truly stateless), but revocation requires either short TTLs or a
revocation list (which is a distributed system problem again). Server-side
sessions (Redis) require a lookup on every request but support instant revocation
(delete the session key). For high-security applications (banking, healthcare):
server-side sessions with Redis, short session lifetime, force re-auth on
sensitive operations. For consumer applications: JWT with 15-minute access tokens
and 7-day refresh tokens. The refresh token rotation invalidates compromised tokens
within one use cycle.

---

**[MID] Q6 - [CONCEPTUAL] What consistency guarantees does AWS DynamoDB provide?**

DynamoDB consistency options:

```
DynamoDB reads - two modes:

Eventually Consistent Read (default):
  Returns data from any replica
  May reflect writes made <1 second ago
  Uses: 1 read capacity unit for up to 4KB
  Response time: ~1-2ms typically
  Good for: most application reads

Strongly Consistent Read:
  Returns data reflecting all writes prior to the read
  Always reads from primary
  Uses: 2 read capacity units (2x cost)
  Response time: slightly higher (~2-5ms)
  Good for: financial, inventory, any "read your own writes"

DynamoDB Transactions (conditional writes):
  TransactWriteItems: atomic write of up to 25 items
  TransactGetItems: strongly consistent read of up to 25 items
  Cost: 2x normal read/write capacity
  Use: order creation (decrement inventory + create order)
       must succeed or fail atomically

DynamoDB Streams:
  Change data capture: every write -> stream event
  At-least-once delivery to Lambda
  Use: trigger async downstream updates (search index, cache)
  Consistency: eventual (stream events after write commits)

Global Tables (multi-region):
  Active-active multi-region: writes accepted in any region
  Conflict resolution: last-writer-wins (by DynamoDB timestamp)
  Reads: eventually consistent with other regions
         (replicate asynchronously, typically <1 second)
  Strongly consistent reads: within local region only
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* DynamoDB's Global Tables + last-writer-wins
has a known limitation: concurrent writes to the same item from two regions
(within the replication lag window) can result in one write being lost silently.
Most applications avoid this by routing writes for the same user to the same
region (by user's home region). If conflicting cross-region writes can happen:
DynamoDB Transactions with conditional expressions (e.g., expected version)
detect conflicts and fail one of them. The application handles the failure
(typically by re-reading and re-trying). This is the optimistic concurrency
pattern at the DynamoDB level.

---

**[SENIOR] Q7 - [HANDS-ON] How do you implement a distributed cache that handles eventual consistency correctly?**

Distributed cache consistency challenges:

```
Problem: multiple services + shared Redis cache
  Service A updates product price in DB
  Service A deletes product cache key
  (milliseconds later)
  Service B reads product from cache
  -> Cache miss, fetches from DB
  -> Populates cache with new price
  -> All good in this scenario

Race condition:
  Service A: reads product from DB (old price, for other purpose)
  Service B: writes new price to DB, deletes cache key
  Service A: populates cache with OLD price (stale!)
  Now cache has stale price, TTL not expired

  Timeline:
  T=0: Service A reads product (old price $10)
  T=1: Service B writes new price ($20) to DB
  T=2: Service B deletes cache key
  T=3: Service A populates cache with $10 (stale!)
  T=4: User reads product -> cache hit -> $10 (wrong)
  Window: T=3 to TTL expiry

Solution 1: Short TTL
  TTL=30s: stale for at most 30 seconds
  Acceptable for product display; not for checkout

Solution 2: Write invalidation with versioning
  Cache key: "product:{id}:{version}"
  Write: increment DB version -> new cache key
  Old key: eventually expires (TTL)
  Reads: fetch version from DB, look up versioned key
  Accurate but adds DB read for version

Solution 3: Refresh-ahead with locking
  Background job: refresh cache before TTL expires
  Uses distributed lock to prevent stampede
  Only one job refreshes at a time (lock holder)

Solution 4: Accept eventual consistency
  Cache may be stale for up to TTL (by design)
  Document: "Product display price may lag up to N seconds"
  Build checkout path without relying on cached price
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The "write then delete" invalidation pattern
has the race condition described above (Service A populates stale after Service B
deletes). The "delete then write" pattern avoids it: if the cache is empty, the
next reader fetches fresh from DB. The safest cache invalidation: just delete
the key; let the next reader populate from DB. Combined with short TTLs: stale
window is bounded. The complex patterns (versioned keys, refresh-ahead) are for
very high-traffic keys where even brief staleness has significant business impact.
For 99% of cases: delete-on-write + short TTL is sufficient.

---

**[SENIOR] Q8 - [CONCEPTUAL] How does Kafka ensure eventually consistent event delivery?**

Kafka's consistency model: at-least-once delivery (eventually consistent).

```
Kafka delivery guarantees:

At-most-once:
  Producer: fire and forget (no acks)
  Consumer: auto-commit before processing
  Data loss possible (process crash after commit, before processing)
  Use: metrics, non-critical events

At-least-once (default):
  Producer: acks=1 or acks=all (waits for broker ack)
  Consumer: commit after processing
  Duplicates possible (crash after processing, before commit)
  Use: most event-driven applications
  Requirement: idempotent consumers (handle duplicates)

Exactly-once (Kafka transactions):
  Producer: transactions (begin, send, commit/abort)
  Consumer: read_committed isolation
  No duplicates, no loss
  Cost: ~2x latency, ~20% throughput reduction
  Use: financial events, exactly-once counts

Idempotent consumer pattern:
  Every event: unique event_id
  Consumer: before processing, check if event_id already processed
  If processed: skip (return success)
  If new: process, record event_id, commit

  DB implementation:
  INSERT INTO processed_events(event_id, processed_at)
  VALUES (?, now())
  ON CONFLICT (event_id) DO NOTHING
  RETURNING event_id;
  -- If RETURNING returns null: already processed, skip
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Exactly-once in Kafka solves the duplicate
delivery problem at the infrastructure level. But exactly-once only applies
to Kafka-to-Kafka paths (producer + broker + consumer in the same Kafka cluster).
If the consumer writes to an external system (database, API), the external system
must also be idempotent to achieve end-to-end exactly-once. Most teams implement
at-least-once + idempotent consumers because it's simpler than Kafka transactions
and achieves the same end result. The decision: if the cost of re-processing is
low (idempotent operation): at-least-once. If re-processing is expensive
(external payment API charge): exactly-once or deduplication at the API level.

---

**[SENIOR] Q9 - [PRODUCTION] How do you detect and fix consistency bugs in production?**

Detecting consistency bugs: monitoring, auditing, reconciliation.

```
Detection methods:

1. Audit log comparison:
  Write an audit log for every state change
  Periodically: compare audit log state with DB state
  Mismatch: consistency bug detected
  Example: payment audit log shows $100 debit;
           account balance doesn't reflect it
  Tool: batch reconciliation job (daily, hourly)

2. Heartbeat / canary records:
  Write a known value to the system every N seconds
  Read it back from all replicas
  Measure time to see the write on each replica
  = Real replication lag measurement
  Alert: if any replica shows >30 second lag

3. Hash-based consistency check:
  Compute hash of all records per shard
  Compare hashes across replicas
  Different hash = different data
  Like nodetool repair in Cassandra but custom

4. Business metric anomalies:
  Sudden spike in "item not found" errors after purchase:
    -> Inventory state inconsistency
  Payment confirmed but order not appearing:
    -> Eventual consistency window longer than expected
  Double charges in refund reports:
    -> Non-idempotent event processing

Fixing consistency bugs in production:

  Idempotent replay:
    Re-process events from beginning (Kafka offset reset)
    Idempotent consumers: safe to replay (skip duplicates)
    Fixes: missed events, incorrect processing

  Reconciliation job:
    Periodic: compare expected state vs actual state
    Correct discrepancies (backfill missing, correct wrong)
    Schedule: nightly or continuous low-priority background

  Manual correction (last resort):
    Write compensation transactions
    Document: what happened, what was fixed, why
    Root cause fix: prevent recurrence
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using Kafka messaging. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Consistency bugs in production are often
discovered through business audits, not technical monitoring. "The books don't
balance at month end" is a consistency bug. Proactive monitoring (heartbeat,
audit log reconciliation) catches these before they become financial discrepancies.
The pattern: design every state change to produce an audit event. An append-only
audit log is the source of truth for "what should have happened." Regular
reconciliation: does the operational DB match the audit log? If not: investigate
and fix. This dual-write pattern (operational DB + audit log) is standard in
financial systems. The audit log is the insurance policy against consistency bugs.

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



