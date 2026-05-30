---
layout: default
title: "Distributed Systems - L2 Coordination Basics"
parent: "Distributed Systems"
grand_parent: "SK Interview"
nav_order: 6
permalink: /distributed-systems/l2-coordination-basics/
---

# Leader Election

**TL;DR:** Leader election designates one node among a group of peers
to serve as the coordinator (primary). The elected leader handles
write requests, coordinates distributed operations, or owns a
responsibility exclusively. Leader election uses consensus protocols
(Raft, ZooKeeper ZAB) to guarantee that exactly one leader is elected
at any time, preventing split-brain. The key invariant: only one leader
per epoch.

---

### 🎯 Model Answer

**30 seconds:**
> Leader election picks one node from a cluster to act as the
> coordinator. Only the leader accepts writes or coordinates
> operations. This prevents conflicts. The hard requirement: exactly
> one leader must exist at all times (split-brain = two leaders =
> data corruption). Consensus algorithms (Raft, Paxos) provide this
> guarantee. ZooKeeper and etcd are commonly used as the election
> infrastructure.

**3 minutes:**
> Many distributed systems need one node in charge: Kafka has a
> partition leader that accepts writes. Databases have a primary that
> serves writes. Distributed cron schedulers elect a leader to
> prevent duplicate job execution. The role is asymmetric: only the
> leader does the special work; followers replicate or wait.
>
> Why is election hard? When a leader fails, all nodes must agree
> on the same new leader. Without consensus, two nodes might both
> believe they are the leader (split-brain), each accepting writes
> independently, creating diverged state. The solution: use a
> quorum (majority). A node can only claim leadership if acknowledged
> by a majority of the cluster. In a 5-node cluster, a node needs
> 3 votes. If the cluster partitions into a 2 and 3 node group,
> only the 3-node group can elect a leader (has quorum). No split-brain.
>
> Epoch/term fencing: each election period has a unique epoch number.
> The leader tags every action with its epoch. If an old leader
> reconnects after being deposed (network partition healed), replicas
> reject any write tagged with the old epoch. This prevents "zombie
> leaders" from causing harm.

**Blank Mind Recovery:**

**(1) Restate:** "Leader election - picking exactly one node as the
coordinator in a distributed cluster."

**(2) First principles:** "Without a designated coordinator, multiple
nodes might try to do the same thing simultaneously. That causes
conflicts. One leader = one writer = no conflicts."

**(3) Bridge:** "Like a classroom: chaos when everyone speaks at once.
The teacher (leader) controls who speaks. When the teacher leaves
(node fails), the class elects a new one. The rule: only one teacher
at a time."

---

### 📘 Concept Explanation

**What it is:**
The process by which distributed nodes agree on exactly one member
of the group to serve as the leader (coordinator/primary) for a
given epoch.

**The problem it solves:**
Without a leader, multiple nodes might simultaneously accept writes,
execute the same scheduled job, or coordinate the same distributed
transaction, creating conflicts. Leader election ensures exclusive
ownership of a responsibility.

**Election algorithms overview:**

**Bully algorithm (simple, not quorum-based):**
Each node has an ID. On leader failure, the node with the highest
ID that is available declares itself leader. Simple but not
partition-safe - can produce split-brain.

**Ring algorithm:**
Nodes are logically arranged in a ring. An election message travels
the ring; each node adds its ID. After a full ring trip, the highest
ID wins. Also not partition-safe.

**Raft leader election (modern, quorum-based):**
```
Term: the unit of leadership (monotonically increasing)

States: Follower → Candidate → Leader

1. Followers wait for heartbeat from leader
2. If no heartbeat (timeout): follower → candidate
3. Candidate increments term, requests votes
4. Candidate needs votes from majority
5. Majority vote → candidate becomes leader
6. Leader sends heartbeats to prevent new elections
```

**ZooKeeper-based election:**
```
1. All nodes create ephemeral sequential znodes:
   /election/node-0000000001
   /election/node-0000000002
   /election/node-0000000003

2. Node with smallest sequence number = leader

3. Each non-leader watches the node just before it
   (avoids thundering herd)

4. When leader's znode disappears (session expires):
   next node becomes leader automatically
```

**Fencing tokens:**
```
Leader is given a monotonically increasing epoch/token
when elected. All writes include this token.
Storage/replicas reject any write with token < latest_known.
Prevents zombie leaders from writing stale data.
```

**The key insight:**
Leader election must be combined with epoch fencing. Winning the
election is not sufficient - the leader must ensure old leaders
cannot interfere via their own writes. Fencing tokens enforce this.

**When to use it:**
- Database primary election (PostgreSQL with Patroni)
- Kafka partition leader
- Distributed scheduler (prevent duplicate job execution)
- Distributed lock that auto-releases on failure

**When NOT to use it:**
When you can design the system to be leaderless (Cassandra dynamo-style,
CRDTs). Leader election adds complexity; if the use case supports
it, a leaderless design is simpler.

**Alternatives:**
- Leaderless replication (quorum reads+writes): no election needed
- Distributed lock services: ZooKeeper, Redis SETNX for simpler cases

**First-principles derivation:**
"Exclusive access to a resource in a single process = mutex lock.
In a distributed system = the same resource must be accessible to
only one process across the network. Leader election is the distributed
mutex for 'which node has authority to act.'"

---

### 💻 Code Example

```java
// LEADER ELECTION WITH ZOOKEEPER (Curator framework)

import org.apache.curator.framework.CuratorFramework;
import org.apache.curator.framework.recipes.leader
    .LeaderSelector;
import org.apache.curator.framework.recipes.leader
    .LeaderSelectorListenerAdapter;

public class JobSchedulerLeader
        extends LeaderSelectorListenerAdapter {

    private final String nodeName;
    private final LeaderSelector leaderSelector;

    public JobSchedulerLeader(
            CuratorFramework client, String nodeName) {
        this.nodeName = nodeName;
        // Curator manages ZooKeeper ephemeral node creation
        // and re-queues this node for re-election after
        // losing leadership
        this.leaderSelector = new LeaderSelector(
            client, "/scheduler/leader", this);
        leaderSelector.autoRequeue();
    }

    public void start() {
        leaderSelector.start();
    }

    @Override
    public void takeLeadership(CuratorFramework client)
            throws Exception {
        System.out.printf(
            "Node %s is now the leader%n", nodeName);
        try {
            // This method blocks while this node is leader.
            // Run exclusive leader operations here:
            runJobSchedulerLoop(); // blocks until interrupted
        } finally {
            // When this method returns, leadership is released
            // Another node will be elected
            System.out.printf(
                "Node %s lost leadership%n", nodeName);
        }
    }

    private void runJobSchedulerLoop() throws Exception {
        while (!Thread.currentThread().isInterrupted()) {
            checkAndRunDueJobs();
            Thread.sleep(1000); // poll every second
        }
    }
}
```

> **Code walkthrough:** Apache Curator wraps ZooKeeper's leader
> election recipe. The `LeaderSelector` creates an ephemeral sequential
> znode for this instance. The node with the smallest sequence number
> becomes the leader and `takeLeadership` is called. The method blocks
> for as long as this node wants to retain leadership. If the ZooKeeper
> session expires (network partition, process crash), the ephemeral
> znode disappears and another node is elected automatically.
> `autoRequeue()` means that after losing leadership, this node
> re-queues for election rather than giving up - it will become leader
> again eventually if the current leader fails. The critical pattern:
> exclusive work runs only inside `takeLeadership`.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Leader election picks one node to coordinate. Only the leader
> accepts writes or runs exclusive operations. Prevents conflicts.
> The hard requirement: exactly one leader (quorum voting prevents
> split-brain). ZooKeeper and etcd provide election primitives.
> Fencing tokens prevent old leaders from causing harm.

*Push deeper:* "Raft uses heartbeat timeouts: followers become
candidates if they do not hear from the leader within an election
timeout. First candidate to get majority votes wins."

---

**Senior / Staff:**
> In production: leader election latency matters for failover.
> Raft election timeout is configurable - too short causes spurious
> elections on network hiccup, too long delays failover. Patroni for
> PostgreSQL uses etcd for election with a configurable TTL. The
> fencing token (timeline ID) ensures old leaders' WAL writes are
> rejected by replicas.

*Push deeper:* "Split-brain prevention in practice: the storage
layer must reject writes from superseded leaders. In Kafka: ZooKeeper
epoch ensures old partition leaders cannot produce to brokers that
have already switched to the new leader's epoch."

---

### ⚠️ Common Misconceptions

**"The node with the highest uptime should be the leader"**

Reality: uptime is not a reliable leadership criterion. A long-lived
node might have more state but might also be the node most in need
of restart. Leadership should be based on quorum agreement and explicit
voting, not uptime heuristics.

**"Leader election guarantees exactly-once execution of leader tasks"**

Reality: leader election guarantees at-most-one leader per epoch
(during normal operation). But during a network partition with a
slow leader and a new election, there is a window where two nodes
believe they are the leader simultaneously. Fencing tokens (combined
with storage-layer rejection of old-epoch writes) are needed to
prevent duplicate execution even in this window.

---

### ⚖️ Comparison Table

| Method | Partition Safe | Latency | Complexity | Choose When |
|---|---|---|---|---|
| Bully / Ring | No | Fast | Low | Toy/non-critical |
| ZooKeeper ZAB | Yes | ~100ms | Medium | Established infrastructure |
| etcd / Raft | Yes | ~150ms | Medium | Kubernetes, new systems |
| Redis SETNX | Partial | ~1ms | Low | Low-stakes, best-effort |
| Consul sessions | Yes | ~100ms | Medium | Service discovery + election |

**The deciding factor:** Is split-brain catastrophic (financial data,
exclusive job runner)? Use quorum-based (ZooKeeper, etcd). For
best-effort (cache warm-up, low-stakes coordination): Redis SETNX.

---

### 🎯 Interview Deep-Dive

#### Production Failures

Q: Two nodes both believe they are the leader simultaneously.
How did this happen and how do you fix it?

A: Split-brain: a network partition isolated the old leader from the
majority. The majority elected a new leader. The old leader's
session has not yet expired (still within the ZooKeeper/etcd TTL).
Both write simultaneously. Fix: (1) implement fencing tokens -
each leader operation includes the election epoch; storage rejects
operations with outdated epochs. (2) reduce the session TTL so the
old leader's session expires faster. (3) use Raft (built-in fencing
via term numbers) rather than custom ZooKeeper recipes. Immediate
mitigation: manually expire the old leader's session in ZooKeeper.

Q: Leader failover is taking 45 seconds, causing service outage.
Target is under 5 seconds. How do you reduce it?

A: 45 seconds suggests: the old leader's ZooKeeper/etcd session
TTL is set to 45 seconds (common default). The new leader is not
elected until the TTL expires. Fix: reduce the session TTL (e.g.,
10 seconds). Set the election timeout shorter (e.g., 3 seconds).
But trade-off: shorter TTL = more spurious elections on network
hiccups. Tune carefully: monitor election frequency before and after.
Also check: health check frequency (how quickly the load balancer
detects and stops routing to the old leader).

#### Candidate Mistakes

Q: How do you prevent two processes from running the same scheduled
job simultaneously in a distributed environment?

**What NOT to say:** "Use a database flag to mark the job as running."

**Say instead:** "A database flag is a start, but it has a race condition:
two processes can both read 'not running' and both start. A better
approach: (1) Leader election - only the elected leader node executes
the scheduler. Other nodes are standby. Job uniqueness follows from
leader uniqueness. (2) Distributed lock: before running the job,
acquire a distributed lock (ZooKeeper, Redis Redlock) with a TTL.
Only the lock holder executes. If the holder crashes, the TTL expires
and another instance can acquire the lock. (3) Database row locking
with SELECT FOR UPDATE and a conditional UPDATE - idiomatic for
low-scale scheduling. The choice depends on the scale and the
criticality of exactly-once execution."

---

---

# Distributed Locking

**TL;DR:** A distributed lock ensures only one process across a cluster
can execute a critical section at a time. Unlike a mutex (single
process), a distributed lock must survive process crashes (use TTL),
prevent split-brain (use fencing tokens), and handle network issues
(use quorum-based lock stores). Redis SETNX is common for low-stakes
locks; ZooKeeper/etcd provide stronger guarantees for critical locks.

---

### 🎯 Model Answer

**30 seconds:**
> A distributed lock prevents multiple processes across different
> servers from executing the same critical section simultaneously.
> The key requirements: the lock must expire if the holder crashes
> (TTL prevents deadlock), and fencing tokens must prevent zombie
> processes from using an expired lock. Redis SETNX is common but
> has edge cases. ZooKeeper provides stronger guarantees.

**3 minutes:**
> In a single process, a mutex prevents concurrent execution of
> critical sections. In a distributed system, you need the equivalent
> across multiple nodes on a network. Distributed locks are harder
> because: (1) the lock holder can crash while holding the lock -
> use TTL so the lock auto-expires. (2) network partition can separate
> the lock holder from the lock store - the holder thinks it still
> has the lock, but the store has expired it and given it to another
> process. Fencing tokens solve this: the lock store issues a
> monotonically increasing token with each lock grant. Protected
> resources reject any operation with a token less than the highest
> known token. (3) the lock store itself can fail.
>
> Redis SETNX + TTL is the simplest implementation: `SET lock_key
> unique_value NX EX 30`. Atomic acquisition. TTL auto-expires on
> crash. But if Redis is a single node, it is a SPOF. Redlock (Redis'
> multi-node algorithm) uses 5 Redis nodes for quorum but has been
> debated (Martin Kleppmann argued Redlock has edge cases with clock
> drift). ZooKeeper/etcd provide stronger CP guarantees for distributed
> locks at the cost of more infrastructure.

**Blank Mind Recovery:**

**(1) Restate:** "Distributed lock - a mutex that works across
multiple servers in a distributed system."

**(2) First principles:** "A mutex inside a process uses shared memory.
Across processes, shared state is the network and the lock store.
The problem: lock holder can crash. TTL prevents infinite deadlock.
Fencing prevents zombie holders."

**(3) Bridge:** "Like a hotel key card - the front desk gives you
one at check-in and the room can only be opened by that key. If
you lose the card (crash), the desk can issue a new one after your
checkout time (TTL expires)."

---

### 📘 Concept Explanation

**What it is:**
A mechanism that ensures exclusive access to a shared resource
across multiple distributed processes, using a shared lock store.

**The problem it solves:**
Without a distributed lock, multiple instances of a service might
simultaneously: update the same database record, send the same email,
execute the same scheduled job, or write to the same file - causing
incorrect behavior.

**Core requirements:**

1. **Mutual exclusion:** only one holder at any time
2. **Deadlock-free:** auto-expire (TTL) if holder crashes
3. **Fault tolerant:** lock store failure should not prevent all
   progress
4. **Fencing:** expired lock holders cannot cause harm

**Implementation: Redis SETNX:**

```
Acquire:
  SET lock_name unique_id NX EX ttl_seconds
  Returns OK (acquired) or nil (already locked)

Release:
  if GET lock_name == my_unique_id:
    DEL lock_name  // only delete my own lock
  (use Lua script for atomicity)

TTL: lock auto-expires if holder crashes before release
unique_id: prevents releasing another process's lock
```

**The fencing token problem:**

```
Process A acquires lock, gets token=1
Process A pauses (GC, network delay) for 35 seconds
Lock expires (TTL=30s)
Process B acquires lock, gets token=2
Process B writes to storage with token=2
Process A resumes, still thinks it has the lock
Process A writes to storage with token=1
Storage MUST check: token=1 < latest=2 → REJECT
This is fencing. Redis SETNX alone does NOT provide
fencing - you must implement it at the storage layer.
```

**ZooKeeper-based distributed lock:**

```
1. Create ephemeral sequential znode:
   /locks/resource-0000000042

2. Check if this is the lowest-numbered znode
   for this resource.

3. If yes: you have the lock

4. If no: watch the znode with the next smaller
   number. When it disappears, re-check.

5. Release: delete your znode (session expiry
   auto-deletes if you crash).

The monotonically increasing znode sequence
number IS the fencing token.
```

**The key insight:**
A distributed lock with TTL but without fencing is not safe.
The lock can expire while the holder is executing, and a new holder
takes over. If the old holder completes its operation (late, after
GC pause), both operations execute on the protected resource.
Fencing prevents this at the resource level.

**When to use it:**
- Exactly-once execution of critical operations (debit account)
- Coordinating distributed workers (job scheduler)
- Rate limiting with atomic counter (per-IP rate limit across nodes)
- Cache stampede prevention (only one process regenerates cache)

**When NOT to use it:**
- For long-duration locks (minutes) - use a workflow engine (saga)
  instead
- When the latency of lock acquisition is in the hot path
- When you can design around it (idempotent writes + optimistic
  locking is often simpler and more scalable)

**Alternatives:**
- Optimistic locking: read with version, write if version matches
  (no lock held, conflict detected at write time)
- Database SELECT FOR UPDATE: database-level row lock (works, but
  ties lock lifetime to DB connection)
- Idempotency key: deduplication instead of exclusion

**First-principles derivation:**
"Exclusive access in a single process = shared memory mutex.
Across processes on one machine = OS semaphore, file lock.
Across machines on a network = need a shared service that all nodes
can reach, with atomic compare-and-set semantics and auto-expiry.
This is what Redis SETNX and ZooKeeper provide."

---

### 💻 Code Example

```java
// DISTRIBUTED LOCK WITH REDIS (Redisson)

// BAD: lock without TTL (deadlocks on crash)
// and without fencing token
public void processPayment(String paymentId) {
    String lockKey = "payment:" + paymentId;
    // BAD: SET lockKey "locked" NX - no TTL!
    // If this process crashes: lock never released
    // Payment stuck forever (deadlock)
    if (!redis.setnx(lockKey, "locked")) {
        throw new LockException("Already processing");
    }
    try {
        doProcessPayment(paymentId);
    } finally {
        redis.del(lockKey); // never called on crash
    }
}

// GOOD: TTL + unique value + atomic release
@Service
public class PaymentProcessor {
    private final RedissonClient redisson;

    public void processPayment(String paymentId) {
        // RLock is a fair reentrant lock backed by Redis
        // Automatically uses TTL + unique lock value
        RLock lock = redisson.getLock(
            "payment:" + paymentId);
        // Wait max 5s to acquire, hold max 30s
        // 30s TTL: auto-releases if process crashes
        boolean acquired = lock.tryLock(
            5, 30, TimeUnit.SECONDS);
        if (!acquired) {
            throw new LockException(
                "Payment already being processed");
        }
        try {
            doProcessPayment(paymentId);
        } finally {
            // Only releases if this thread still holds it
            // Redisson checks the unique owner value
            if (lock.isHeldByCurrentThread()) {
                lock.unlock();
            }
        }
    }
}
```

> **Code walkthrough:** The BAD example uses `SETNX` without a TTL.
> If the process crashes between acquiring the lock and releasing it,
> the lock key remains in Redis forever - a deadlock. Every future
> attempt to process the same payment will fail. The GOOD example
> uses Redisson, which wraps Redis with proper distributed lock
> semantics: TTL (30 seconds) prevents deadlock on crash, a unique
> owner value prevents releasing another process's lock, and
> `isHeldByCurrentThread()` before unlock prevents a common bug
> where a process releases a lock it no longer holds (TTL expired
> during a long operation).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> A distributed lock prevents multiple servers from executing the
> same critical section simultaneously. Redis SETNX + TTL is the
> common implementation. TTL = auto-expiry prevents deadlock on crash.
> Fencing tokens prevent an expired lock holder from causing harm.
> ZooKeeper provides stronger guarantees for critical operations.

*Push deeper:* "The fencing token is the part most candidates miss.
Without it, an expired lock holder (after a GC pause) can still
write to the protected resource after another process has acquired
the lock."

---

**Senior / Staff:**
> Distributed locks are a last resort - I try to avoid them.
> Idempotent writes with optimistic locking (version check on update)
> scale better and have no lock contention. I reach for distributed
> locks only when: the operation has side effects that cannot be made
> idempotent (external API call, email), or the conflict probability
> is high and optimistic lock retries would be too expensive.

*Push deeper:* "Martin Kleppmann's critique of Redlock: with clock
drift on Redis nodes, the lock can expire silently before the holder
expects. The TTL calculation is based on physical time which can
jump. For truly critical locks, use ZooKeeper (session-based, not
time-based expiry) or etcd with lease-based locks."

---

### ⚠️ Common Misconceptions

**"Redis SETNX is reliable enough for all distributed locks"**

Reality: single-node Redis SETNX has two problems: (1) Redis is a SPOF;
if Redis fails, no locks can be acquired. (2) There is no built-in
fencing token. Redlock (multi-node Redis) improves the SPOF issue
but has clock-drift edge cases. For critical financial operations,
use ZooKeeper or etcd (CP systems) which provide session-based
(not time-based) lock expiry.

**"A long TTL is safer than a short TTL"**

Reality: a long TTL delays recovery after a holder crash. If the TTL
is 10 minutes and the holder crashes immediately after acquiring the
lock, the protected resource is blocked for 10 minutes. Short TTLs
(10-30 seconds) are better: quicker recovery, but requires that the
critical section completes within the TTL. If the operation might
take longer: implement TTL renewal (heartbeat from the lock holder
to extend the TTL while it is still active).

---

### ⚖️ Comparison Table

| Implementation | Partition Safe | Fencing | SPOF | Use When |
|---|---|---|---|---|
| Redis SETNX | No | Manual | Single Redis | Low-stakes, simple |
| Redlock (5 nodes) | Partial | Manual | No | Medium-stakes |
| ZooKeeper | Yes (CP) | Built-in (seq) | No (quorum) | Critical locks |
| etcd Lease | Yes (CP) | Built-in (lease ID) | No (quorum) | New systems, K8s |
| DB SELECT FOR UPDATE | Yes (DB) | DB transaction | DB is SPOF | Same DB as data |

**The deciding factor:** Can you tolerate a brief window of
split-brain (two processes both believe they have the lock)?
If no: ZooKeeper/etcd. If tolerable with fencing: Redis.

---

### 🎯 Interview Deep-Dive

#### Production Failures

Q: A distributed lock is being held indefinitely. Requests are
queuing. What happened and how do you recover?

A: The lock holder crashed without releasing the lock, AND the lock
was created without a TTL (or with an excessively long TTL).
Immediate recovery: manually delete the lock key in Redis
(`DEL lock_key`) or forcibly expire the ZooKeeper znode
(`deleteData /locks/resource`). Once cleared, the next waiting
process acquires the lock. Prevention: always set a TTL. Add
monitoring/alerting on lock acquisition wait time - if it exceeds
2x the expected critical section duration, alert.

Q: Two processes are both executing the same critical section despite
using a distributed lock. How is this possible?

A: The fencing token problem. Process A acquired the lock, started
a long GC pause (or was stopped by the OS). The lock TTL expired.
Process B acquired the lock and started. Process A resumed, still
believing it holds the lock (no mechanism to notify it of expiry),
and continued its critical section. Both processes are in the critical
section simultaneously. Fix: implement fencing at the protected
resource. Include the lock token (Redis version or ZooKeeper sequence)
in every write operation. The resource rejects writes with tokens
older than the last accepted token.

#### Candidate Mistakes

Q: How do you safely release a distributed Redis lock?

**What NOT to say:** "Just call DEL lock_key."

**Say instead:** "DEL without checking ownership is dangerous. If
your TTL expired while you were working, another process has acquired
the lock. Calling DEL would delete THEIR lock, leaving the resource
unprotected. Safe release requires an atomic check-and-delete:
(1) GET the lock key. (2) If the value equals YOUR unique ID: delete it.
(3) Do this atomically in a Lua script:
`if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) else return 0 end`.
The Lua script is atomic in Redis - no other command can interleave
between the GET and the DEL."

### 🚨 Failure Modes and Diagnosis

**Split-brain (two simultaneous leaders):**

Symptom: conflicting writes, data inconsistency, two nodes both
believe they are primary.

Cause: network partition; old leader is isolated from quorum but
does not know. New leader is elected by the majority partition.
Both accept writes.

Diagnosis: check leader epoch in both leaders' logs. If they differ,
split-brain occurred.

Fix: fencing tokens at the storage layer (storage rejects writes
with old epoch). Reduce session TTL so the isolated old leader's
session expires faster. Partition-aware monitoring that alerts on
two active leaders.

**Thundering herd on leader failure:**

Symptom: all follower nodes send vote requests simultaneously,
causing network congestion and repeated failed elections.

Cause: all followers have the same election timeout.

Fix: Raft's randomized election timeout (150ms-300ms random range).
ZooKeeper Curator recipe's "watch predecessor" pattern - each node
only watches the node just before it, not all nodes watching the
leader directly.

**Leader oscillation:**

Symptom: leadership changes rapidly, services cannot keep up with
leader discovery updates.

Cause: election timeout too short; network has periodic latency
spikes that trigger re-elections.

Fix: tune election timeout. Add hysteresis to leader failover
detection. Monitor election frequency - alert if more than 1
election per minute.

---

### 🏛️ System Design

*(Omit: leader election is a component-level coordination pattern.
The system design aspects are covered in the Concept Explanation
and Code Example sections. For full distributed system design
incorporating leader election, see L4 Raft Consensus and L5
Partition Tolerance files.)*

---

### 📊 Diagram

*(Omit: leader election is a protocol/algorithm; the relevant
state transitions are described in the Concept Explanation.
Diagram coverage is in the Raft Consensus (L4) file which shows
the full visual state machine.)*

---

### 🎯 Interview Deep-Dive

| Question Type | Count | Timing |
|---|---|---|
| Conceptual | 3 | 2 min each |
| Trade-off | 2 | 3 min each |
| Debugging | 2 | 3 min each |
| Behavioral | 1 | 4 min |
| Scale | 1 | 3 min |

---

**Q1 (Conceptual): What is the purpose of the fencing token in
leader election, and what happens without it?**

The fencing token (also called epoch, term, or generation number)
is a monotonically increasing integer issued to each newly elected
leader. Every operation the leader performs includes this token.
The protected resource (storage, database) tracks the highest token
it has seen and rejects any operation with a lower token.

Without it: suppose a leader pauses for a GC stop-the-world pause
of 40 seconds while holding the lock. The election timeout fires,
a new leader is elected with a higher token, and the new leader
starts writing. When the old leader resumes from its pause, it is
unaware that leadership has changed - it has no mechanism to detect
this. It continues to write with its old (now stale) token. Without
fencing, the storage accepts these stale writes, corrupting data.

With fencing: the storage holds `max_seen_token = 2` (new leader's
token). The old leader presents token = 1. Storage rejects: `1 < 2`.
The old leader fails its write and discovers it is no longer the leader.

*What separates good from great:* Great candidates explain that
fencing is enforced at the RESOURCE level, not the leader level.
The leader cannot self-enforce: it does not know its TTL has expired.
Only the resource, which sees all tokens, can enforce monotonic
ordering. This is why "check if you still have the lock before
writing" does NOT solve the problem.

---

**Q2 (Conceptual): Compare Bully, Ring, and Raft election
algorithms. When is each appropriate?**

Bully algorithm: the node with the highest ID wins. When a node
detects leader failure, it broadcasts an election message. If a
node hears from a higher-ID node, it steps down. The highest
surviving ID claims leadership. Simple to implement but not
partition-safe: in a network partition, the highest-ID node in
EACH partition claims leadership → split-brain. Appropriate only
for toy systems or single-network-segment deployments.

Ring algorithm: nodes are logically arranged in a ring. An election
token travels the ring, each node appending its ID. After a full
trip, the highest ID wins. Same partition-safety problem as Bully.
Latency is O(n) ring traversal.

Raft election: uses randomized timeouts to prevent simultaneous
candidacy. Requires majority quorum to win. Term numbers provide
fencing. After partition heals, the term comparison ensures only
one leader. Appropriate for production systems where partition
safety is required.

*What separates good from great:* Great candidates note that Bully
and Ring are included in textbooks as educational algorithms, not
production patterns. Production systems use Raft, ZAB (ZooKeeper),
or Viewstamped Replication. The textbook algorithms illustrate
the concepts but are not used in real systems.

---

**Q3 (Conceptual): How does ZooKeeper's ephemeral sequential znode
approach provide built-in fencing for leader election?**

Each candidate creates an ephemeral sequential znode under a
parent path: `/election/leader-0000000042`. ZooKeeper auto-increments
the sequence number. The candidate with the lowest sequence number
is the leader. Non-leaders watch the znode with the next smaller
sequence number (not the leader directly) - this avoids the
thundering herd problem.

Fencing comes from the sequence number itself: it is monotonically
increasing and guaranteed unique by ZooKeeper. When the leader
passes its sequence number to the storage layer as the fencing
token, writes tagged with lower sequence numbers are rejected.
Additionally, ephemeral znodes auto-delete when the ZooKeeper session
expires (process crash, network partition), so the next-lowest node
automatically becomes the new leader without any election protocol
overhead.

*What separates good from great:* Great candidates distinguish
between the leader election (which node has the lowest sequence)
and the fencing mechanism (using the sequence number as a token at
the storage layer). ZooKeeper makes this clean because the sequence
number is globally unique and monotonically increasing.

---

**Q4 (Trade-off): What are the trade-offs between short and long
election timeouts in Raft?**

Short timeout (e.g., 50ms): faster leader failover - the cluster
detects and resolves leader failure quickly. But spurious elections
happen on network hiccups. A 100ms network latency spike causes all
followers to timeout and start an election. Frequent elections cause
brief unavailability windows and overhead. In production, this can
cause cascading instability.

Long timeout (e.g., 10s): stable during network jitter - a
100ms spike does not cause an election. But leader failover takes
up to 10 seconds, which may be unacceptable for availability SLOs.

Production tuning: typical values are 150-500ms for election timeout,
with randomization to prevent split votes. The heartbeat interval
must be significantly shorter than the election timeout (e.g.,
50ms heartbeat, 150-300ms election timeout). Match the timeout to
the expected network latency in your environment: lower in a LAN,
higher in WAN deployments.

*What separates good from great:* Great candidates note that Raft's
randomized timeout is not just a performance optimization - it is
a correctness mechanism. Simultaneous timeouts lead to split votes
(no majority), and the randomization breaks the symmetry.

---

**Q5 (Trade-off): Leader-based vs. leaderless replication: when
does each approach win?**

Leader-based: strong consistency (single write path, no conflicts),
simpler to reason about, easier to implement total order. Cost:
all writes must go through the leader - leader is a bottleneck.
Failover has a window of unavailability during election.

Leaderless (Dynamo-style): writes to any replica, quorum writes
(W out of N nodes confirm). No single bottleneck. No election
latency. Cost: eventual consistency, conflicts possible (require
resolution via LWW or CRDTs), more complex to reason about
correctness.

Hybrid (Raft with leader + read from follower): leader for writes,
followers serve stale reads. Common in etcd. Balances consistency
and read throughput.

*What separates good from great:* Great candidates connect this
to the specific access patterns. If the workload is write-heavy
and can tolerate eventual consistency (e-commerce cart, shopping
recommendations): leaderless. If the workload requires strong
consistency (financial ledger, distributed lock): leader-based.

---

**Q6 (Debugging): How would you debug a cluster that is failing
to elect a leader and is stuck in permanent candidate state?**

Permanent candidate state means no node can get a majority vote.
Possible causes:

1. Network partition: check if all nodes can communicate. Use
   `traceroute` / `netstat` between all node pairs. A 3-node cluster
   where node A can see B but not C, and B can see A but not C,
   and C is isolated: no majority is possible between A and B
   (they are only 2 of 3). Check firewall rules.

2. Misconfigured quorum: if the cluster config says 5 nodes but
   only 3 are running, and quorum requires 3 of 5: achievable.
   But if the config expects 5 and 3 are registered but only 2
   are reachable: stuck. Verify cluster membership config.

3. Clock skew causing repeated split votes: if election timeouts
   are all the same (not randomized): every node times out at
   the same time, every node becomes a candidate simultaneously,
   every election results in a split vote. Check if Raft timeouts
   are randomized.

4. Firewall blocking vote RPC: nodes can ping each other but
   firewall blocks the specific port used for Raft RPCs.

*What separates good from great:* Great candidates approach this
systematically: network connectivity first, then cluster
membership config, then protocol-level diagnostics (Raft logs,
vote request/response traces). They do not guess randomly.

---

**Q7 (Debugging): A ZooKeeper-based leader election is producing
frequent leadership changes. How do you investigate?**

Frequent leadership changes (leadership oscillation) indicate
the current leader's ZooKeeper session is repeatedly expiring.

Diagnostic steps:

1. Check ZooKeeper session timeout: `zkCli.sh stat /election`.
   If the session timeout is very short (e.g., 2000ms), any network
   hiccup causes expiry.

2. Check leader node GC logs: full GC pauses can exceed the session
   timeout. JVM stop-the-world GC of 3 seconds on a 2-second session
   timeout = session expires = leadership lost.

3. Check network latency between leader and ZooKeeper: even brief
   spikes matter. Leader must send heartbeats within the session TTL.

4. ZooKeeper server load: if ZooKeeper itself is overloaded, it may
   not process heartbeats in time, causing spurious session expiry.

Fix: increase the session timeout. Tune GC to reduce pause duration.
Ensure ZooKeeper cluster is not overloaded.

*What separates good from great:* Great candidates immediately think
of GC pauses as a common cause. This is a well-known operational
issue with JVM-based services using ZooKeeper - the service's JVM
pauses longer than the ZooKeeper session timeout, losing leadership.

---

**Q8 (Behavioral): Tell me about a time you debugged a coordination
or concurrency problem in a distributed system.**

*(Personalize from your experience. Structure: situation, what went
wrong, how you debugged it, root cause, fix.)*

Example structure: "In our payment service, we had two instances
both processing the same payment request during a brief period when
our primary database was failing over. The Redis-based distributed
lock was acquired by both because our lock key was not unique per
request - we were using a single global key instead of a per-payment
key. We saw duplicate charge events in Stripe logs. I identified
the issue by correlating payment IDs across two instances' logs and
noticing identical timestamps. Fix: per-payment-ID lock key, plus
idempotency check at the Stripe API level."

*What separates good from great:* Great candidates demonstrate
systematic debugging (logs, correlation), identify the root cause
precisely (not just "we had a race condition" but specifically
which code path and which invariant was violated), and discuss both
the immediate fix and the systemic improvement.

---

**Q9 (Scale): How does leader election change when you scale from
a 3-node cluster to 50-node or 1000-node clusters?**

At 3 nodes: quorum = 2 votes. Election is fast. Network messages
are O(n^2) = 9 total.

At 50 nodes: quorum = 26 votes. Still feasible with Raft.
Vote message fan-out = 50 messages. Raft leader can send heartbeats
to all 49 followers: O(n) messages per heartbeat interval. This
scales linearly but the leader becomes the bottleneck for heartbeats.

At 1000 nodes: heartbeat fan-out from leader = 999 messages every
150ms. This is millions of messages per minute. Raft does not
scale well to 1000 participants.

Solutions for large-scale: (1) Hierarchical election: elect regional
leaders who in turn elect a global leader. (2) Multi-Raft: partition
the problem into multiple independent Raft groups (TiKV, CockroachDB
use this). (3) Use a dedicated coordination service (etcd, ZooKeeper)
that is a small cluster; the 1000 application nodes do not run
the consensus protocol themselves - they delegate to the small cluster.

*What separates good from great:* Great candidates know that consensus
protocols like Raft have a practical scalability ceiling. The
production answer for large clusters is to NOT run consensus among
all nodes - use a small dedicated quorum cluster (etcd in Kubernetes:
typically 3-5 etcd nodes, no matter how large the Kubernetes cluster).

---

---

### 🚨 Failure Modes and Diagnosis

*(For Distributed Locking)*

**Lock contention causing cascading timeouts:**

Symptom: lock acquisition times out throughout the system; service
latency spikes; thread pool exhaustion.

Cause: one slow lock holder is blocking many waiters. The lock
critical section is taking longer than expected (slow DB query,
external API call).

Diagnosis: monitor lock wait time. Add timing to lock acquisition
and release. Identify which operation holds the lock the longest.

Fix: reduce the critical section's execution time. Consider whether
the operation truly requires exclusive access or can use optimistic
locking instead. Add a circuit breaker around lock acquisition.

**Lock starvation:**

Symptom: one service instance consistently cannot acquire a lock
while others succeed.

Cause: unfair lock implementation. Redis SETNX is not fair - it is
a race. The fastest process (lowest latency to Redis) always wins.

Fix: use a fair lock (ZooKeeper sequential ephemeral nodes provide
fairness - FIFO order). Or add jitter to retry intervals to avoid
synchronized retries.

**Lock TTL too short (lock expires during operation):**

Symptom: two processes occasionally execute the same critical
section; "impossible" duplicate operations appear in logs.

Cause: the critical section sometimes takes longer than the TTL
(e.g., slow database under load). The lock expires, another process
acquires it, and both proceed.

Diagnosis: add timestamps to the operation log. Check if duplicates
correlate with high load periods. Compare critical section duration
to the lock TTL.

Fix: (1) increase TTL with safety margin (e.g., 2x the P99 critical
section duration). (2) Implement TTL renewal: the lock holder
periodically extends the TTL while it is still working. Redisson's
`RLock` does this via a watchdog thread. (3) Implement fencing at
the resource level so late writes from expired holders are rejected.

---

### 🏛️ System Design

*(Omit: distributed locking is a component-level pattern. System
design aspects are covered in the Concept Explanation and Code
Example. For full distributed system design using locking, see
L4 Failure Detection and L5 Partition Tolerance files.)*

---

### 📊 Diagram

*(Omit: distributed locking semantics are best expressed as
prose and code. The core protocol (acquire/release with TTL and
fencing) does not benefit from a diagram beyond the pseudocode
in the Concept Explanation section.)*

---

### 🎯 Interview Deep-Dive

| Question Type | Count | Timing |
|---|---|---|
| Conceptual | 3 | 2 min each |
| Trade-off | 2 | 3 min each |
| Debugging | 2 | 3 min each |
| Behavioral | 1 | 4 min |
| Scale | 1 | 3 min |

---

**Q1 (Conceptual): Why is `SET lock NX EX ttl` safer than
`SETNX` followed by `EXPIRE`?**

`SETNX` (SET if Not eXists) sets the key but does not set an
expiry. A separate `EXPIRE` command must be issued. This creates
a window between the two commands. If the process crashes after
`SETNX` succeeds but before `EXPIRE` executes, the key has no
TTL and the lock is held forever - a deadlock.

`SET lock_key value NX EX ttl` is a single atomic command:
the key is set AND the TTL is applied atomically. If the process
crashes immediately after this command: the TTL ticks down and
the lock automatically expires. No deadlock.

This is why all modern Redis lock implementations use the combined
`SET NX EX` form, not the two-command sequence.

*What separates good from great:* Great candidates generalize
this to the principle: "never use two commands where one atomic
command exists." Any non-atomic sequence has a crash window.
This extends to the release operation (Lua script for
check-and-delete).

---

**Q2 (Conceptual): What is the Redlock algorithm and what is
the controversy around it?**

Redlock was proposed by Antirez (Redis author) to provide a
more fault-tolerant distributed lock. It uses 5 independent Redis
nodes (not replicated - truly independent). To acquire a lock:
request the lock from all 5 in parallel. If a majority (3+) grant
the lock within a timeout: the lock is acquired. The effective TTL
is the original TTL minus the time taken to acquire from the
majority.

Controversy: Martin Kleppmann (author of DDIA) argued that Redlock
is unsafe in the presence of clock drift or process pauses. The
TTL calculation uses wall clock time. If the Redis node clocks
drift, the TTL calculation is wrong. If the lock holder pauses
(GC) for a duration close to the TTL, the lock may have expired
(by the Redis nodes' clocks) while the holder believes it still
holds it. Without fencing tokens (which Redlock does not provide),
this leads to split-lock situations.

*What separates good from great:* Knowing the Kleppmann critique
shows depth. The conclusion: Redlock is a reasonable choice for
medium-stakes coordination where brief split-lock windows are
tolerable. For critical locks (financial operations): use
ZooKeeper or etcd with fencing tokens.

---

**Q3 (Conceptual): How would you implement distributed rate
limiting using a distributed lock or atomic Redis operations?**

The naive approach - check count, increment, check - is not atomic
and allows race conditions. The correct approaches:

1. **Redis INCR + EXPIRE:** Use `INCR counter_key` (atomic).
   On first increment, set `EXPIRE counter_key window_seconds`.
   If count exceeds limit: reject. Atomic increment prevents
   concurrent overcount. Limitation: the EXPIRE is not set
   atomically with the first INCR - use a Lua script:
   `local count = redis.call('INCR', KEYS[1]); if count == 1 then redis.call('EXPIRE', KEYS[1], ARGV[1]) end; return count`.

2. **Sliding window with sorted sets:** Store request timestamps
   in a Redis sorted set. On each request: remove elements older
   than `now - window`, count elements, if under limit add current
   timestamp. Atomic via Lua script. More memory but provides
   true sliding window semantics.

3. **Token bucket with Redis:** Store token count and last refill
   time. Atomic Lua script calculates tokens based on time elapsed.

*What separates good from great:* Great candidates go straight
to atomicity: "any non-atomic implementation allows concurrent
requests to all see the count before it is incremented."

---

**Q4 (Trade-off): When should you use a distributed lock vs.
optimistic locking vs. idempotency?**

**Distributed lock:** Use when: the operation has externally
visible side effects that cannot be undone or deduplicated
(external API call, email send). Use when: you need to prevent
work being duplicated, not just detect it after the fact.
Cost: lock contention, added latency, lock infrastructure.

**Optimistic locking:** Use when: conflicts are rare (low
contention), operations are retryable, you can detect conflicts
at the point of write (version number check on UPDATE). Scales
better than distributed locks. Cost: retry overhead on conflict.

**Idempotency key:** Use when: the operation can be made idempotent
by the caller including a unique key. The server deduplicates
based on the key (check-and-set in DB). Cost: storage for the
deduplication table. Benefit: no lock contention, works across
retries naturally.

*What separates good from great:* Great candidates express a
preference for avoiding distributed locks: "I reach for them last.
I first ask: can I make this idempotent? Can I use optimistic
locking? Distributed locks are expensive and have failure modes
(TTL, fencing) that are easy to get wrong."

---

**Q5 (Trade-off): Describe the trade-off between lock granularity
and throughput in distributed locking.**

Coarse-grained lock (e.g., lock the entire user account):
Simple to reason about. But all operations on the same account
are serialized. If many operations target the same account
(high-volume user), throughput is limited to 1 operation at a time.

Fine-grained lock (e.g., lock per field, per account balance):
Higher throughput - operations on different fields of the same
account proceed in parallel. But more complex: multiple locks
must be acquired atomically to prevent deadlock (always acquire
in the same order). Risk of deadlock: two operations, each waiting
for a lock held by the other.

For distributed systems, the recommendation is to make operations
as idempotent as possible and use the coarsest lock that prevents
the specific conflict you care about. Premature fine-graining adds
complexity without proportional benefit.

*What separates good from great:* Great candidates mention deadlock
ordering. "If you have multiple locks, always acquire them in a
canonical order (e.g., alphabetical by key name). This prevents
the circular wait that leads to deadlock."

---

**Q6 (Debugging): A distributed lock in Redis is being acquired
by a process but it cannot release it. What might be wrong?**

The process is trying to release a lock it no longer owns.
Possible causes:

1. The lock TTL expired during the critical section (slow
   operation). Redis auto-deleted the key. When the process calls
   DEL, it deletes the new lock holder's key.

2. The process is calling DEL without checking the owner value.
   If another process acquired the lock (after expiry), a simple
   DEL removes their lock.

Diagnosis: add structured logging at lock acquire time including
the unique value and at release time. Log the result of the Lua
release script (returns 1 if released, 0 if the key did not match).
A stream of 0 returns indicates consistent TTL-expiry-before-release.

Fix: (1) Implement TTL renewal via a watchdog thread that extends
the TTL while the operation is in progress. (2) Structure the
code so the critical section completes within the TTL with margin.
(3) Log and alert when the release returns 0 - this is a signal
that the critical section is running too long.

*What separates good from great:* Recognizing that `returns 0 on
release` is not just an error - it is data. If it happens frequently,
the TTL is too short for the operation's execution time. Tune the
TTL, do not just retry.

---

**Q7 (Debugging): Your team is seeing intermittent duplicate
emails being sent by a distributed notification service.
Distributed locks are already in use. How do you investigate?**

This is the fencing token problem. The distributed lock is being
used but without fencing. Investigation steps:

1. Enable verbose lock logging. Capture: lock acquisition time,
   lock release time, TTL. Do the duplicates correlate with lock
   TTL expiry (acquisition time + TTL close to release time)?

2. Check for GC pause logs on the notification service instances.
   Do duplicates correlate with GC pauses > TTL?

3. Add a database-level deduplication check. Before sending the
   email, check a `notifications_sent` table for the notification ID.
   If already present: skip. This is idempotency at the resource level.

4. Implement fencing at the email service level: include a
   monotonically increasing token with each send request. The
   email service stores the last accepted token per notification
   ID and rejects duplicates.

Root cause is almost always: lock TTL expiry + GC pause = two
holders simultaneously. Fix: (1) increase TTL + add watchdog
renewal, (2) implement idempotency at the email send level.

*What separates good from great:* Immediately identifying the
fencing problem shows depth. Most candidates focus on fixing
the lock TTL. Great candidates add idempotency at the resource
level as a defense-in-depth measure.

---

**Q8 (Behavioral): Tell me about a time a distributed lock caused
a production issue in your system.**

*(Personalize from your experience.)*

Example structure: "We used Redis SETNX for a distributed cron job.
One day, the job stopped running for 4 hours. Investigation showed
a Redis key with our lock name, with no expiry (TTL = -1). A deploy
had temporarily used an old code version that used SETNX without
EXPIRE. That instance acquired the lock and crashed before releasing
it. Without a TTL, the key was permanent. Fix: added TTL to the
SETNX pattern. Also added a monitoring alert: alert if the lock key
exists for longer than 5 minutes (our expected max job duration).
This would catch the issue in 5 minutes next time."

*What separates good from great:* Great answers include the
monitoring/detection fix, not just the code fix. A lock deadlock
that is not detected for 4 hours is a monitoring failure as much
as a code failure.

---

**Q9 (Scale): How does distributed lock performance change at
high request rates (10,000+ lock acquisitions per second)?**

At 10,000 lock/s with Redis: each acquisition is a round-trip
to Redis (~0.5-1ms LAN). At 10,000/s with a single Redis node,
the Redis node handles 10,000 commands/s easily (Redis can do
100,000+/s on modern hardware). But: if the critical section
lasts 50ms and there is high contention (many processes competing
for the same key), queuing builds up. The lock becomes a
serialization point.

Analysis: if 10,000 requests/s each hold the lock for 50ms, the
maximum throughput for that lock is 1000ms/50ms = 20 operations/s.
The 9,980 other requests/s are queuing. This is a throughput cliff.

Solutions: (1) Shard the lock: use per-entity-ID locks so different
entities do not contend. (2) Reduce critical section duration.
(3) Move to optimistic locking (no lock contention at all; conflicts
handled by retries). (4) Use a work queue: only one worker per
entity processes requests sequentially - no lock needed because
processing is already serialized per entity (actor model pattern).

*What separates good from great:* Doing the math on throughput
ceiling. "If the critical section takes 50ms, this lock can never
do more than 20/s no matter how fast the lock infrastructure is.
The bottleneck is the critical section, not the lock acquisition."
