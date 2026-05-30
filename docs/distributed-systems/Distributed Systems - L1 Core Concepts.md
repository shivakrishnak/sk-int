---
layout: default
title: "Distributed Systems - L1 Core Concepts"
parent: "Distributed Systems"
grand_parent: "SK Interview"
nav_order: 2
permalink: /distributed-systems/l1-core-concepts/
render_with_liquid: false
---

# CAP Theorem

**TL;DR:** The CAP Theorem states that a distributed data store can
provide at most two of three guarantees simultaneously: Consistency
(every read returns the most recent write), Availability (every request
receives a response), and Partition Tolerance (the system continues
operating despite network partitions). Since network partitions are
unavoidable in real systems, the practical choice is always
CP (consistent but may reject requests) vs AP (available but may
return stale data).

---

### 🎯 Model Answer

**30 seconds:**
> CAP Theorem: in a distributed system you can have at most two of
> three properties: Consistency (reads always return the latest write),
> Availability (the system always responds), and Partition Tolerance
> (the system keeps working when nodes cannot communicate). Since
> network partitions happen in practice - you cannot opt out - the
> real choice is between CP (sacrifice availability to stay consistent)
> and AP (sacrifice consistency to stay available).

**3 minutes:**
> CAP was formally proven by Eric Brewer and Gilbert/Lynch in 2002.
> Here is the core trade-off: when a network partition happens - two
> halves of a cluster cannot communicate - you must choose. Do you
> allow both sides to serve requests (AP: available, but they may
> diverge and return different data)? Or do you block requests until
> the partition heals (CP: consistent, but some requests get rejected)?
>
> The non-obvious insight: you can NEVER choose CA (consistent AND
> available without partition tolerance) because network partitions
> are not optional in real distributed systems. Packets get dropped.
> Data center links fail. A CA system is just a single-node system.
>
> Real-world examples: Cassandra, DynamoDB = AP. They prioritize
> availability - writes always succeed, but a reader may see stale
> data. HBase, ZooKeeper, etcd = CP. They prioritize consistency -
> they reject requests or stall operations when the cluster cannot
> reach consensus. The choice depends entirely on your use case:
> a shopping cart can tolerate stale data (AP is fine). A bank balance
> cannot (CP required).

**Blank Mind Recovery:**

**(1) Restate:** "CAP Theorem - the trade-off between consistency,
availability, and partition tolerance in distributed databases."

**(2) First principles:** "Two database nodes can only communicate
over a network. Networks fail. When they cannot communicate, which
do I prefer: both respond (possibly with different data) or neither
responds until we agree?"

**(3) Bridge:** "Think of two ATMs in a bank: if the network between
them fails, should each ATM still allow withdrawals (available but
could both overdraw the account = inconsistent) or refuse all
transactions until the network is restored (consistent but unavailable)?"

---

### 📘 Concept Explanation

**What it is:**
A theorem stating that distributed data stores can guarantee at most
two of: Consistency, Availability, Partition Tolerance.

**The problem it solves:**
Before CAP was formalized, engineers claimed their distributed databases
were "consistent AND highly available AND resilient." CAP proves this
is impossible during network partitions. It gives a rigorous framework
for understanding the fundamental trade-offs.

**How it works:**

Definitions:
- **C (Consistency):** Every read returns the most recent write
  (or an error). All nodes see the same data at the same time.
- **A (Availability):** Every request receives a non-error response
  (though not necessarily the most recent write).
- **P (Partition Tolerance):** The system continues operating when
  network partitions occur (nodes cannot communicate).

The proof sketch: if a partition happens and node A accepts a write,
node B cannot replicate it before responding. If B returns the pre-write
value: violates C. If B refuses to respond: violates A. No third option.

**The key insight:**
P is not a design choice - network partitions happen in real systems.
Therefore the actual choice is CP vs AP. "CA" systems exist only in
single-node environments.

**When to use it:**
Use CAP as a tool to classify databases and understand their guarantees.
When choosing a database: identify whether your use case requires CP
or AP, then select accordingly.

**When NOT to use it:**
CAP is often over-applied. Most operations on a healthy (non-partitioned)
cluster are not affected by CAP trade-offs - the trade-off only manifests
during actual network partitions, which are relatively rare. The PACELC
theorem extends CAP to also consider the latency/consistency trade-off
during normal operation (no partition), which is often more relevant
day-to-day.

**Alternatives:**
- PACELC: extends CAP with latency vs consistency trade-off during
  normal operation
- BASE: Basically Available, Soft state, Eventually consistent -
  a philosophy for AP systems (contrast with ACID)

**First-principles derivation:**
"Two nodes sharing data can only sync over a network. Given a partition:
(A) let both respond independently = available but potentially diverged.
(B) block one until sync is possible = consistent but unavailable.
No other options exist. This is the CAP trade-off."

---

### 💻 Code Example

```java
// CP vs AP: what they look like in application code

// CP system (e.g., ZooKeeper / etcd):
// Returns error during partition - sacrifices availability
public String readConfig(String key) throws Exception {
    try {
        // ZooKeeper requires quorum to read
        // If majority of nodes unreachable: throws exception
        return zkClient.getData().forPath("/config/" + key);
    } catch (ConnectionLossException e) {
        // CP: tells caller honestly "I cannot answer right now"
        // The system sacrifices availability to maintain
        // consistency guarantees
        throw new ServiceUnavailableException(
            "Cannot read config: cluster unreachable", e);
    }
}

// AP system (e.g., Cassandra with ONE consistency level):
// Returns potentially stale data - never refuses
public String readUserEmail(String userId) {
    // Consistency.ONE: read from any single replica
    // Even if that replica has not seen the latest write:
    // it still returns a value (stale, but available)
    ResultSet result = session.execute(
        QueryBuilder.selectFrom("users")
            .column("email")
            .whereColumn("id").isEqualTo(
                QueryBuilder.literal(userId))
            .build()
            .setConsistencyLevel(ConsistencyLevel.ONE));
    Row row = result.one();
    // May return email from 500ms ago - but always returns
    return row == null ? null : row.getString("email");
}
```

> **Code walkthrough:** The CP example (ZooKeeper) throws an exception
> when the cluster cannot reach a quorum - it sacrifices availability
> to maintain the guarantee that returned data is correct. The AP
> example (Cassandra with ONE consistency level) reads from any single
> available replica, even if that replica lags behind the latest write.
> It never throws a partition exception; it returns potentially stale
> data. The choice between these patterns is the CAP trade-off
> concretely expressed in application code.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> CAP Theorem: a distributed system can guarantee at most two of
> Consistency, Availability, and Partition Tolerance. Since partition
> tolerance is required (networks fail), the real choice is CP
> (consistent, may reject during partition) vs AP (available, may
> return stale data). Examples: Cassandra = AP, ZooKeeper = CP.

---

### ⚠️ Common Misconceptions

**"You get to choose two out of three freely"**

Reality: Partition tolerance is mandatory in any real distributed
system. You do not "choose CA" - you are just describing a single-node
system. The real design choice is CP vs AP during partition events.

**"CAP means the system is always in one mode"**

Reality: most databases allow tunable consistency per operation.
Cassandra can operate as CP (QUORUM level) or AP (ONE level)
depending on the consistency level set per query. The CAP choice
is not fixed at the system level in many modern databases.

---

### 🚨 Failure Modes and Diagnosis

**Using AP system for data requiring CP semantics:**
Symptom: inventory system shows 10 units in stock across two replicas
simultaneously; two customers both purchase the last unit; both
purchases succeed; inventory goes negative.
Diagnosis: the write used eventual consistency (AP) without a
compare-and-swap or transaction. Both replicas accepted the write
before syncing. Fix: use a CP system or add application-level
optimistic locking (check-and-set) at the write layer.

**Overusing CP causing availability issues:**
Symptom: during a brief network hiccup, 30% of reads fail because
the CP cluster lost quorum.
Diagnosis: cluster has only 3 nodes; losing 2 = quorum lost.
Fix: add more replicas to increase quorum margin; or switch to
PREFER_ONE consistency for reads where stale data is acceptable.

---

### 🎯 Interview Deep-Dive

**Q1: Explain CAP Theorem in one minute.**

🗣️ "CAP: a distributed data store can guarantee at most two of:
Consistency (reads always return the most recent write), Availability
(every request gets a response), Partition Tolerance (system works
during network failures). Since network partitions are unavoidable
in real systems, you always have P. The real choice is CP versus AP.
CP: during a partition, reject some requests rather than return stale
data. ZooKeeper, HBase, CockroachDB are CP. AP: during a partition,
respond to every request, even if the response is stale. Cassandra,
DynamoDB, CouchDB are AP. The choice depends on your use case: bank
transactions need CP. Social media likes can tolerate AP."

**Q2: What does it mean that 'CA' is not a valid choice in CAP?**

🗣️ "'CA' means consistent and available but NOT partition tolerant.
This is impossible to guarantee in a real distributed system because
network partitions are not optional - they happen due to cable faults,
switch failures, BGP routing issues, or congestion. A 'CA' system is
just a single-node system. As soon as you have two nodes connected
by a network, you have accepted the risk of partition - and at that
point you must choose CP or AP. Some textbooks list single-node
relational databases as 'CA' - which is technically true since they
have no partition to tolerate, but that is not a meaningful distributed
systems design choice."

**Q3: How does the PACELC theorem extend CAP?**

🗣️ "PACELC (Daniel Abadi, 2012) extends CAP to include the latency
vs consistency trade-off during NORMAL operation (no partition).
CAP only describes the trade-off during partition events. PACELC adds:
during normal operation (else = E), you still trade off Latency vs
Consistency. A system that requires quorum reads for consistency has
higher latency than one that reads from a single replica. PACELC gives
a richer characterization: a database can be 'PA/EL' (partition:
available; else: low latency) or 'PC/EC' (partition: consistent; else:
consistent). Cassandra is PA/EL. ZooKeeper is PC/EC. This better
describes real-world databases where the latency-consistency trade-off
matters every request, not just during partitions."

**Q4: How do you use CAP to choose a database for a given use case?**

🗣️ "The decision tree: (1) Does the data have strong consistency
requirements - would returning stale data cause data corruption, money
loss, or business-critical failures? If yes: choose CP (PostgreSQL,
CockroachDB, MySQL with synchronous replication). (2) Is high
availability more important than consistency - can the application
tolerate reading slightly stale data? If yes: choose AP (Cassandra,
DynamoDB). (3) Is this metadata/coordination data (config, locks,
leader election)? Choose a purpose-built CP store (etcd, ZooKeeper).
Practical examples: e-commerce shopping cart = AP (stale cart is fine,
brief data loss is acceptable). Inventory available-for-sale count =
CP (overselling is a business problem). User profile = AP (seeing
2-second-old profile data is fine)."

**Q5: Does a database have to be permanently CP or AP?**

🗣️ "No. Most distributed databases allow tunable consistency per
operation. Cassandra has consistency levels: ALL (every replica must
agree = CP), QUORUM (majority = CP-ish), ONE (single replica = AP).
DynamoDB has eventually consistent reads and strongly consistent reads
as options per request. MongoDB has read concern levels. This means
the same database cluster can behave as CP for critical writes and AP
for analytical reads. My pattern: write with QUORUM (ensure durability),
read with eventual consistency for bulk analytics, read with QUORUM
for financial operations. One database, different CAP behaviors
depending on the consistency level you choose per operation."

**Q6: What are real-world examples of CP vs AP failures?**

🗣️ "CP failure example: ZooKeeper cluster loses quorum (majority of
nodes unreachable). Kafka, Hadoop, and any service using ZooKeeper
for coordination stops processing until quorum is restored. This
happened at many companies when a data center went partially offline.
The system was consistent (no wrong answers) but unavailable (no
answers at all). AP failure example: Cassandra with eventual consistency
during a rolling restart. Some replicas have the new data, others
have old data. A user who updated their email and immediately reads
their profile might see the old email. The system was available
(responded to every request) but inconsistent (returned stale data).
Both failures are real; which is worse depends entirely on the
use case."

**Q7: How does the CAP theorem apply to microservices?**

🗣️ "In microservices, each service owns its database. Cross-service
data consistency requires distributed transactions (2PC or Saga).
The CAP question: if Service A's database is CP and Service B's is AP,
what is the consistency guarantee of a cross-service operation?
It is effectively the weaker of the two. Saga pattern: each step
writes to its own CP database, but the overall saga is eventually
consistent - intermediate steps complete but compensating transactions
are needed for rollback. This is AP at the saga level. The practical
implication: strong consistency guarantees at the service level
do not guarantee strong consistency at the application level if
the operation spans multiple services."

---

---

# Consistency Models

**TL;DR:** Consistency models define what values a distributed system
is allowed to return from a read after a write. Strong consistency:
reads always return the latest write. Eventual consistency: reads
may return stale data, but all replicas converge eventually. Causal
consistency: if you wrote A and then B, any reader who sees B must
also see A. The model you choose determines your system's correctness
guarantees and its performance.

---

### 🎯 Model Answer

**30 seconds:**
> Consistency models define what values a distributed system can
> return from reads after writes. Strong consistency: always return
> the most recent write. Eventual consistency: may return stale data,
> but all nodes eventually agree. Causal consistency: preserve the
> order of causally related writes. Strong = correct, slow.
> Eventual = fast, but users may see stale data.

**3 minutes:**
> There is a spectrum of consistency models from weakest (eventual)
> to strongest (linearizability). Understanding where each database
> sits on this spectrum is essential for predicting how your application
> will behave. At the strongest end: linearizability (external
> consistency, used by Spanner). Every operation appears to execute
> atomically at some point between start and end - the system looks
> like a single machine. At the weakest end: eventual consistency
> (Cassandra, DynamoDB default). Replicas may lag behind; a read
> might return data that is seconds old; but all replicas will
> eventually converge to the same value if writes stop. In between:
> causal consistency (operations that are causally related are seen
> in the right order), read-your-writes (you always see your own
> writes), and monotonic reads (you never see older data after seeing
> newer data in the same session). The practical impact: using eventual
> consistency for a financial balance is a bug. Using linearizability
> for a social media feed is unnecessary overhead.

**Blank Mind Recovery:**

**(1) Restate:** "Consistency models - the rules for what a distributed
system can return from reads."

**(2) First principles:** "Multiple nodes hold copies of data.
Writes go to one node. How long until other nodes reflect the write?
Consistency models define the answer."

**(3) Bridge:** "It is like updating a shared document and asking:
can another reader see the update instantly (strong consistency),
or might they see the old version for a few seconds (eventual)?"

---

### 📘 Concept Explanation

**What it is:**
A specification of what values a distributed system is permitted
to return in response to read operations, relative to prior write
operations.

**The problem it solves:**
Without a consistency model, application developers cannot reason
about what their code will do. "Will reading my user's balance after
a debit always return the updated value?" Without a defined model,
the answer is "maybe."

**The consistency spectrum:**

```
Weakest                                        Strongest
|                                                      |
Eventual  Causal  Read-your  Monotonic  Sequential  Linearizable
                  -writes    reads
```

Key models:
1. **Eventual Consistency:** Replicas may diverge temporarily; given
   no new writes, all replicas converge to the same value eventually.
   Used by Cassandra (default), DNS.

2. **Read-Your-Writes:** After you write a value, you always read
   at least that value. Other readers may not. Common in session-
   scoped consistency.

3. **Monotonic Reads:** Once you have seen a value, you will never
   see an older value. Prevents time-traveling backwards in
   session state.

4. **Causal Consistency:** Operations that are causally related
   (A caused B) are observed in that order by all nodes. Unrelated
   operations may be seen in different orders. Used by MongoDB
   causal sessions.

5. **Sequential Consistency:** All nodes see operations in the same
   order, but not necessarily the real-time order. Stronger than
   causal, weaker than linearizable.

6. **Linearizability:** The gold standard. Every operation appears
   to execute atomically at a single point in real time. All observers
   agree on the order. Used by ZooKeeper, etcd, Spanner.

**The key insight:**
Stronger consistency = more coordination required = higher latency.
Weaker consistency = less coordination = lower latency but more
surprising behavior. The model is a trade-off, not a flaw.

**When to use it:**
- Financial systems: linearizability or sequential consistency
- User-facing reads where stale is fine: eventual
- "Did I see this message?" in chat: causal
- User's own profile reads: read-your-writes

**When NOT to use it:**
Do not use stronger consistency than you need - it costs latency and
reduces availability. Do not use eventual consistency where business
logic requires reading your own writes (e.g., post a comment then
immediately read the page).

**Alternatives:**
ACID transactions (single-node) provide linearizability as a guarantee
per-transaction - the strongest model, but only within a single
database.

**First-principles derivation:**
"Multiple replicas of data can only sync over a network. Network
adds latency. You can either wait for sync before responding (strong)
or respond immediately with what you have (weak). Every consistency
model is a point on this wait/respond spectrum."

---

### 💻 Code Example

```java
// DEMONSTRATING CONSISTENCY LEVEL IMPACT

// BAD: eventual consistency for a balance check
// A user deposits $100, immediately checks balance
// With eventual consistency: may see old balance
public BigDecimal getBalance(String accountId) {
    // ONE = read from any single replica
    // That replica may not have seen the deposit yet
    return session.execute(
        SimpleStatement.newInstance(
            "SELECT balance FROM accounts WHERE id = ?",
            accountId)
            .setConsistencyLevel(ConsistencyLevel.ONE))
        .one().getBigDecimal("balance");
    // User sees $900 instead of $1000 - confusing!
}

// GOOD: read-your-writes via stronger consistency
public BigDecimal getBalance(String accountId) {
    // QUORUM = majority of replicas must agree
    // Ensures you see the latest committed write
    return session.execute(
        SimpleStatement.newInstance(
            "SELECT balance FROM accounts WHERE id = ?",
            accountId)
            .setConsistencyLevel(ConsistencyLevel.QUORUM))
        .one().getBigDecimal("balance");
    // User always sees their deposit reflected
}

// ALSO GOOD: route post-write reads to same node
// Read-your-writes via session token / routing
public BigDecimal getBalance(String accountId) {
    // After a write, the session tracks the replica
    // and routes subsequent reads to ensure
    // read-your-writes consistency
    return cassandraSession.execute(
        SimpleStatement.newInstance(
            "SELECT balance FROM accounts WHERE id = ?",
            accountId)
            .setConsistencyLevel(
                ConsistencyLevel.LOCAL_QUORUM))
        .one().getBigDecimal("balance");
}
```

> **Code walkthrough:** The BAD example uses `ONE` consistency -
> the fastest option but one that reads from a single, potentially
> lagging replica. After a write, the user may see stale data.
> For balances, this is a user-experience bug. The GOOD example uses
> `QUORUM` - a majority of replicas must agree, ensuring the read
> sees any commit that a quorum write acknowledged. The second GOOD
> alternative uses `LOCAL_QUORUM` for the same guarantee but only
> requires quorum within the local data center, reducing cross-region
> coordination overhead.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Consistency models define what a distributed system can return
> from a read. Strong consistency (linearizability) always returns
> the latest write. Eventual consistency may return stale data.
> In between: causal (causally related writes are ordered),
> read-your-writes (you always see your own writes). Stronger =
> slower; weaker = faster but surprising.

---

### ⚠️ Common Misconceptions

**"Eventual consistency means the data is always wrong"**

Reality: eventual consistency means data converges to the correct
value given no new writes. In practice, "eventually" is usually
milliseconds to a few seconds. For many use cases (social media
feeds, user profiles, product catalogs), this is perfectly acceptable.
The problem is using eventual consistency where correctness matters
immediately (financial transactions, inventory counts).

**"Linearizability is too slow for production use"**

Reality: Google Spanner provides external consistency (stronger than
linearizability) at global scale. CockroachDB, FaunaDB, and newer
distributed SQL databases provide linearizable semantics with
acceptable latency. "Linearizable = slow" was true for early
distributed databases but is not universally true now.

---

### 🚨 Failure Modes and Diagnosis

**Read-your-writes violation:**
Symptom: user posts a comment; refreshes the page; comment is not
visible. User reports "the app lost my data."
Diagnosis: the write went to a replica with QUORUM; the subsequent
read went to a different replica that had not yet synced.
Fix: route session reads to the same replica or region after a
write (sticky sessions), or increase read consistency level.

**Stale read causing business logic error:**
Symptom: two users simultaneously see the same seat as available
and both book it; both bookings succeed; oversell occurs.
Diagnosis: using eventual consistency reads for seat availability
check; read-modify-write pattern without atomicity.
Fix: use compare-and-swap (CAS) or a CP database for
the seat reservation; treat availability check as non-binding
and enforce uniqueness at write time.

---

### 🎯 Interview Deep-Dive

**Q1: What is the difference between eventual consistency and
causal consistency?**

🗣️ "Eventual consistency makes one guarantee: given no new writes,
all replicas converge to the same value. It says nothing about order.
You might see a reply to a post before seeing the post itself.
Causal consistency adds an ordering guarantee for causally related
operations: if write A happened before write B (A caused B), then
any reader who sees B must also have seen A. You always see a post
before its reply. Unrelated operations (two posts from different users)
can still be seen in different orders on different replicas.
Causal consistency is stronger than eventual but weaker than sequential.
MongoDB's causal sessions implement this: within a session, reads
are causally consistent - you see your own writes and their causal
consequences."

**Q2: What is linearizability and why is it the gold standard?**

🗣️ "Linearizability means every operation appears to execute atomically
at a single indivisible point in time, and these points are consistent
with real-time ordering. If operation A completes before operation B
starts, then in the linearized history, A appears before B. This
makes a distributed system behave exactly like a single-threaded
single-node system from the caller's perspective. Why it is the gold
standard: it is the easiest model to reason about (no anomalies, no
surprises), it enables correct concurrent algorithms (distributed
locks, leader election), and it allows clients to make strong
assumptions about state. The cost: higher latency (requires quorum
acknowledgment) and lower availability during partitions (CP in CAP
terms)."

**Q3: What is read-your-writes consistency and when is it essential?**

🗣️ "Read-your-writes (also called monotonic read consistency for
your own writes) guarantees that after a write, the same client
will always see that write in subsequent reads. Other clients may
still see the old value (eventual consistency for them). This is
essential when users make a change and then immediately see the
result of that change. Examples: user updates their profile photo
and sees their own profile. User moves an item to a cart and
immediately sees the cart. User sends a message and sees it in
the chat. Without read-your-writes: the user's action appears to
have no effect (they see the old state), which is deeply confusing
and appears to be a bug. Implementation: route the user's session
reads to the same replica that received their write, or use sticky
sessions, or read with a session token that carries the write's
logical timestamp."

**Q4: What are the practical performance implications of choosing
stronger consistency?**

🗣️ "Stronger consistency requires more coordination. Linearizable
reads require contacting a quorum of replicas (typically majority)
to confirm the latest value. In a 5-node cluster with QUORUM (3/5),
every read waits for 3 acknowledgments vs 1 for eventual. Cross-region:
if replicas span US-East and EU-West (70ms round-trip), a QUORUM
read must wait 70ms for the cross-region acknowledgment vs 1ms for
a local replica read. At Google's scale (Spanner), TrueTime allows
linearizable reads with a confidence window - the system waits a
few milliseconds (the clock uncertainty) rather than a full quorum
round-trip. For most applications: choose QUORUM within a single
region (low added latency), and eventual consistency for cross-region
reads unless the use case demands otherwise."

**Q5: How does an application implement session-level consistency
guarantees?**

🗣️ "Several approaches: (1) Sticky sessions: route all of a user's
requests to the same replica. Simple to implement, but loses load
balancing benefits and fails if the replica goes down. (2) Session
token: after a write, the server returns a session token containing
the write's logical timestamp. Subsequent reads send this token;
the replica checks that its local state is at least at that timestamp
before responding. DynamoDB uses this approach. (3) Synchronous
replication: write to all replicas before acknowledging success.
Read from any replica (all are current). Simple but slow (latency =
slowest replica). (4) Causal metadata: each operation carries a
vector clock representing its causal dependencies. Replicas delay
a read until all its causal dependencies are applied. MongoDB
causal sessions use this approach."

**Q6: What is the BASE acronym and how does it relate to
consistency models?**

🗣️ "BASE stands for Basically Available, Soft state, Eventually
consistent. It is the design philosophy of AP systems, contrasted
with ACID (Atomicity, Consistency, Isolation, Durability) for CP
single-node databases. Basically Available: the system remains
functional (returns responses) even during partial failures.
Soft state: the system state may change over time even without
input, as replicas sync. Eventually consistent: the model of
convergence we already described. BASE is not a formal theorem
like CAP - it is a characterization of the design philosophy
behind systems like Cassandra, DynamoDB, and CouchDB. When a
developer says 'we are using a BASE system,' they are communicating:
we have accepted eventual consistency as the trade-off to gain
availability and write performance."

**Q7: How do you explain consistency models to a non-technical
stakeholder?**

🗣️ "I use a bank account analogy. Strong consistency: you deposit $100.
You check your balance on any ATM, anywhere, and it shows the deposit
immediately. Every ATM is synchronized in real time. Eventual
consistency: you deposit $100. If you check your balance at the same
ATM, you see the deposit. But if you check at a different ATM across
town, it might show the old balance for a few seconds while the
information propagates. Most of the time this is fine. Read-your-writes:
you always see your own deposit immediately, but your friend checking
your balance might still see the old number for a moment. I then ask:
for THIS specific data in our system, which behavior is acceptable?
That determines the consistency model to choose."

---

---

# Availability and Fault Tolerance Fundamentals

**TL;DR:** Availability is the fraction of time a system is operational.
Fault tolerance is the ability to continue operating when components
fail. High availability requires redundancy (multiple replicas),
fast failure detection, and automatic failover. The nine-nines
language (99.9% = 8.7 hours/year downtime; 99.99% = 52 minutes/year)
quantifies availability goals. Achieving higher nines requires
eliminating every single point of failure.

---

### 🎯 Model Answer

**30 seconds:**
> Availability is what percentage of time a system is operational.
> Fault tolerance is the ability to keep working when parts fail.
> You achieve both through redundancy - multiple copies of every
> component - and automatic failover - detecting failures and
> switching to replicas without human intervention. The key metric:
> how many nines? 99.9% = 8.7 hours of downtime per year.
> 99.99% = 52 minutes per year.

**3 minutes:**
> Availability is typically expressed as uptime percentage.
> 99.9% sounds great but allows 8.7 hours of downtime annually.
> 99.99% allows 52 minutes. 99.999% (five nines) allows 5 minutes.
> Moving from three nines to five nines requires eliminating every
> single point of failure and typically requires 3x the infrastructure
> and 5x the operational complexity. The components of high
> availability: redundancy (multiple instances of every component -
> load balancers, app servers, database replicas), health checking
> (constantly monitoring all components and detecting failures in
> seconds), automatic failover (routing traffic away from failed
> nodes without human intervention), and graceful degradation
> (when a dependency fails, the system degrades gracefully rather
> than failing completely). Fault tolerance vs high availability:
> fault tolerance means the system continues working correctly
> (no data loss, no incorrect results) when components fail.
> High availability means the system continues responding. A system
> can be available (responding with errors) but not fault tolerant
> (the errors indicate data inconsistency).

**Blank Mind Recovery:**

**(1) Restate:** "Availability and fault tolerance - how distributed
systems stay running when components fail."

**(2) First principles:** "Any component can fail. To stay up, have
redundant copies. To stay consistent, coordinate failover. That
is the core of high availability."

**(3) Bridge:** "Like an airplane: two engines means one can fail
and you keep flying. The airplane is highly available. Fault tolerant:
even if an engine fails in a specific way (partial failure), the
instruments still read correctly - no incorrect data."

---

### 📘 Concept Explanation

**What it is:**
Availability: the probability that a system is operational at a given
moment. Fault tolerance: the property of continuing correct operation
despite component failures.

**The problem it solves:**
Every component has a mean time between failures (MTBF). Without
redundancy, a single component failure takes down the entire service.
High availability design eliminates single points of failure so that
any individual component failure is invisible to users.

**Availability math:**

```
Availability = MTBF / (MTBF + MTTR)

MTBF = mean time between failures
MTTR = mean time to repair/recover

Nines table:
99%      = 3.65 days/year downtime
99.9%    = 8.76 hours/year
99.99%   = 52 minutes/year
99.999%  = 5 minutes/year
99.9999% = 31 seconds/year
```

**Redundancy patterns:**

Active-Active: multiple nodes serving traffic simultaneously.
Any node can fail without service interruption.

Active-Passive: one primary serves traffic, one hot standby.
On primary failure, standby promotes. Brief interruption during
promotion (seconds to minutes).

Geographic redundancy: nodes in multiple regions. Survives
entire data center or region failure.

**Failure detection mechanisms:**
- Health check endpoints: `GET /health` returns 200 OK or 503
- Heartbeat: node sends periodic "I am alive" signals
- TCP connection monitoring: load balancer detects connection drops
- Application-level checks: verify database connectivity, cache
  connectivity, dependent service connectivity

**The key insight:**
MTTR is as important as MTBF. A system that fails rarely but takes
hours to recover has lower availability than one that fails often
but recovers in seconds. Automating failover reduces MTTR from
"time for an engineer to wake up and fix it" to "time for a
Kubernetes pod to restart and pass health checks."

**When to use it:**
Every production service should have an availability target.
Design for the required number of nines from the start - retrofitting
HA onto a monolith is much harder than designing for it initially.

**When NOT to use it:**
Development and staging environments do not need five-nines HA.
Internal tools with human-hours-only usage do not need 99.99%.
Match the availability investment to the business requirement.

**Alternatives:**
- Chaos engineering (Chaos Monkey): proactively inject failures
  to test that the system is actually fault tolerant
- Blue-green deployment: two environments for zero-downtime deploys

**First-principles derivation:**
"Any system with a single instance of a component has a SPOF.
SPOF MTBF = component MTBF. To increase availability: add redundancy.
With N instances, probability all fail = P(fail)^N. For each additional
nine: need N roughly doubling. Five nines is ~10x the infrastructure
complexity vs three nines."

---

### 💻 Code Example

```java
// HEALTH CHECK ENDPOINT: foundation of automatic failover

// BAD: no health check - load balancer cannot detect failure
// Traffic continues to dead instance until manually removed
@RestController
public class ProductController {
    // No /health endpoint - load balancer has no signal
    @GetMapping("/products")
    public List<Product> getProducts() {
        return productService.findAll();
    }
}

// GOOD: comprehensive health check endpoint
@RestController
public class HealthController {

    private final DataSource dataSource;
    private final RedisTemplate<String,?> redis;

    // Kubernetes liveness probe: is the process alive?
    @GetMapping("/health/live")
    public ResponseEntity<String> liveness() {
        // Returns 200 if the process is running
        // Kubernetes restarts the pod if this fails
        return ResponseEntity.ok("OK");
    }

    // Kubernetes readiness probe: can this pod serve traffic?
    @GetMapping("/health/ready")
    public ResponseEntity<String> readiness() {
        try {
            // Check database connectivity
            dataSource.getConnection()
                .prepareStatement("SELECT 1").execute();
            // Check cache connectivity
            redis.getConnectionFactory()
                .getConnection().ping();
            // Only route traffic to this pod if BOTH pass
            return ResponseEntity.ok("READY");
        } catch (Exception e) {
            // 503: load balancer will stop sending traffic here
            return ResponseEntity.status(503)
                .body("NOT READY: " + e.getMessage());
        }
    }
}
```

> **Code walkthrough:** The BAD example has no health endpoint, so
> a load balancer or Kubernetes has no way to detect that this instance
> is unhealthy. Traffic continues to flow to it even when the database
> connection is broken. The GOOD example separates liveness (is the
> process alive? - if not, restart it) from readiness (can it serve
> traffic? - if not, stop routing to it). The readiness probe checks
> actual dependencies (database, cache) so that traffic is only routed
> to instances that can handle it. This is the foundation of automatic
> failover: the load balancer uses readiness probes to implement
> fault-tolerant routing without human intervention.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Availability is how often a system is operational. Fault tolerance
> is staying correct when parts fail. High availability requires
> redundancy (multiple copies), health checks (detect failure fast),
> and automatic failover (route around failures without human
> intervention). The metric: nines (99.9% = 8.7h/year downtime,
> 99.99% = 52min/year).

---

### ⚠️ Common Misconceptions

**"99.9% is good enough for everything"**

Reality: it depends on the service. An internal analytics dashboard
at 99.9% is fine. A payment processing API at 99.9% means 8.7 hours
of failed transactions per year - millions in lost revenue. Match
the availability target to the business impact of downtime.

**"Redundancy automatically makes a system fault tolerant"**

Reality: redundancy is necessary but not sufficient. Without proper
health checks and failover logic, a failed node might continue
receiving traffic (load balancer does not know it is down) or the
system might not promote a replica correctly (data loss during
failover). Fault tolerance requires redundancy AND correct detection
AND correct failover logic.

---

### 🚨 Failure Modes and Diagnosis

**Thundering herd on recovery:**
Symptom: service recovers from an outage but immediately crashes
again under the rush of retried requests.
Diagnosis: all clients retried simultaneously when the service came
back; the instantaneous load spike exceeds capacity.
Fix: exponential backoff with jitter in all clients; gradual traffic
ramp-up on recovery; rate limiting at the gateway.

**False readiness (premature failover):**
Symptom: a new pod passes its readiness probe but serves errors
because a downstream dependency is still starting up.
Diagnosis: readiness probe checks process liveness only, not actual
dependency health.
Fix: readiness probe must check all critical dependencies
(database connectivity, required config loaded); add startup probe
for slow-starting dependencies.

---

### 🎯 Interview Deep-Dive

**Q1: What is the difference between high availability and fault
tolerance?**

🗣️ "High availability means the system responds to requests with high
uptime. Fault tolerance means the system continues operating CORRECTLY
when components fail - no data loss, no incorrect results. A system
can be highly available but not fault tolerant: it responds to
every request (available) but returns incorrect data because two
replicas have diverged (not fault tolerant). A system can also be
fault tolerant but not always available: it refuses requests during
a partition to maintain consistency (CP in CAP). The gold standard
is both: respond to every request AND return correct data.
Achieving this requires both redundancy (for availability) and
correct consistency protocols (for fault tolerance during failures)."

**Q2: Walk through how a load balancer implements automatic failover.**

🗣️ "The load balancer continuously sends health check requests to all
upstream instances - either HTTP GET /health or TCP connection checks.
On each check, an instance either responds with 200 OK (healthy) or
fails to respond (unhealthy). When a configurable number of consecutive
health checks fail (typically 2-3), the load balancer marks the
instance as unhealthy and stops routing new requests to it. Existing
long-lived connections may be drained (gradually shifted) rather than
abruptly cut. When the instance recovers and passes a configurable
number of consecutive successful health checks, it is added back to
the rotation. This is the core of automatic failover: human-free
detection and routing change in response to instance health.
MTTR is reduced to the health check interval times the failure threshold
- typically 10-30 seconds."

**Q3: How do you achieve database high availability?**

🗣️ "Three patterns. First: replication with automatic promotion.
Primary + read replicas, where a replica auto-promotes if the primary
fails (PostgreSQL with Patroni, AWS RDS Multi-AZ). MTTR: seconds to
a few minutes (replica must be elected and DNS updated). Second:
shared storage cluster (Galera Cluster for MySQL). Multiple active
nodes share the same data via synchronous replication. Any node can
accept writes. MTTR: near-zero (another node immediately takes over).
Cost: higher write latency (synchronous replication). Third: distributed
database with built-in HA (CockroachDB, Cassandra). Data partitioned
and replicated across nodes. Loss of minority of nodes is transparent
to clients. Each approach has different RTO (recovery time objective)
and RPO (recovery point objective - how much data can you lose)."

**Q4: What is the 'split brain' problem and how do you prevent it?**

🗣️ "Split brain occurs when two nodes each believe they are the primary/
leader and both accept writes independently. When the network partition
heals, they have diverged data that must be reconciled. This is
catastrophic for systems that cannot accept conflicting writes (financial
data). Prevention: quorum-based leader election. A node can only be
the leader if it receives acknowledgment from a majority (quorum) of
nodes. In a 5-node cluster, a node needs 3 votes to be leader. If
the cluster partitions into a 2-node group and a 3-node group: the
3-node group can elect a leader (has quorum), the 2-node group cannot
(does not have quorum). Only one leader exists at any time. Epoch
fencing: every write includes an epoch number (the leader's election
term). When the old leader reconnects, any writes with the old epoch
are rejected by the replicas - preventing stale writes."

**Q5: What is the relationship between MTBF, MTTR, and availability?**

🗣️ "Availability = MTBF / (MTBF + MTTR). MTBF is the average time
between failures. MTTR is the average time to detect and recover
from a failure. To improve availability, you can either increase
MTBF (make components fail less often - use more reliable hardware,
better software) or decrease MTTR (recover faster - automated failover,
faster deployment, better monitoring). In practice, decreasing MTTR
is more impactful and more controllable. Hardware MTBF is fixed by
the vendor. MTTR is within the engineering team's control: automated
health checks reduce detection time from minutes to seconds,
Kubernetes automatic pod restarts reduce recovery time to seconds,
pre-tested runbooks reduce manual intervention. For five-nines
availability: you need MTTR in seconds, not minutes."

**Q6: How do cascading failures occur and how do you prevent them?**

🗣️ "Cascading failure: Service A depends on Service B. Service B slows
down. Service A's threads queue waiting for B's responses. Service A
runs out of threads. Service A now fails to respond to C and D.
C and D start failing. The slowdown in B has cascaded to the entire
system. Prevention: circuit breakers - when B is slow or failing,
A stops sending new requests to B and immediately returns a fallback
response. This prevents A's thread pool from filling up. Timeouts:
every request to B has a strict timeout; threads are not held
indefinitely. Bulkhead: separate thread pools for different dependencies.
B's slowness fills the 'B thread pool' but the thread pool for C and
D is unaffected. Backpressure: when overloaded, services shed load
explicitly (return 429 Too Many Requests) rather than silently
degrading, allowing upstreams to adapt."

**Q7: What is RTO and RPO, and how do they guide HA design?**

🗣️ "RTO: Recovery Time Objective - how quickly must the system recover
after a failure? E.g., RTO = 1 minute means within 1 minute of a
failure, the system must be serving traffic again. RPO: Recovery Point
Objective - how much data can be lost? RPO = 0 means zero data loss
(synchronous replication). RPO = 5 minutes means the system can lose
up to 5 minutes of data (async replication is acceptable). These two
metrics drive the HA design completely. Low RTO (fast recovery):
requires hot standby (active-passive with rapid promotion) or
active-active (no failover needed). Zero RPO: requires synchronous
replication to all replicas before acknowledging writes (higher
write latency). The cost of both: money and complexity. Five nines
with zero RPO requires synchronous multi-region replication and
fast failover orchestration. Most businesses accept some RPO (5-15
minutes) and some RTO (1-5 minutes) to avoid the cost of
synchronous global replication."
