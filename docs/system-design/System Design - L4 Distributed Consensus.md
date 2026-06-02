---
layout: default
title: "System Design - L4 Distributed Consensus"
parent: "System Design"
grand_parent: "SK Interview"
nav_order: 7
permalink: /system-design/l4-distributed-consensus/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [System Design - L4 Distributed Consensus](#system-design---l4-distributed-consensus) | medium |
| 2 | [Distributed Consensus and Leader Election](#distributed-consensus-and-leader-election) | medium |

---

# Distributed Consensus and Leader Election

---
id: SSD-015
title: Distributed Consensus and Leader Election
category: System Design
difficulty: ★★★
interview_weight: high
asked_at: Senior/Staff/Principal
seniority: staff
tags: #consensus, #raft, #paxos, #leader-election, #split-brain, #zookeeper
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Distributed consensus: getting multiple nodes to agree on a value despite
> failures. The FLP impossibility proves no deterministic algorithm can guarantee
> consensus in an asynchronous system where even one node can fail. Practical
> solutions (Paxos, Raft) add assumptions (partial synchrony) to make consensus
> achievable. Leader election is a specific consensus problem: agree on which
> node is the leader. Raft separates leader election from log replication, making
> it easier to understand and implement correctly than Paxos.

**3 minutes:**
> Consensus is the foundation of all CP distributed systems: agreeing on a value
> before committing ensures all nodes see the same state. Without consensus:
> two nodes might think they're both leaders, accepting conflicting writes
> (split-brain). The correctness properties: safety (all nodes agree on the same
> value - never two different answers) and liveness (eventually an answer is
> reached - no permanent blocking).
>
> Raft's approach: elect a leader, all writes through the leader, leader replicates
> to followers, commit when majority (quorum) acknowledges. The leader holds a
> "term" number; if it crashes, a new election happens with a higher term.
> Any node receiving a message from a lower term rejects it - prevents ghost
> leaders (recovered stale primaries) from competing.
>
> Practical use: ZooKeeper (Zab protocol, similar to Paxos) is the coordination
> service used by Kafka (topic partition leadership), HBase (region assignment),
> Hadoop (NameNode HA). etcd (Raft) is used by Kubernetes (all cluster state).
> Consul (Raft) for service discovery + distributed locks. Every distributed
> system that needs "one primary" uses one of these.

**Blank Mind Recovery:**

**(1) Restate:** "Consensus = getting nodes to agree. Leader election = agree on
which node is in charge."

**(2) The problem:** "Two nodes both think they're leader. Both accept writes.
Writes conflict. Data corrupted. Consensus prevents this."

**(3) Raft in plain English:** "Candidate asks for votes. Majority votes yes ->
leader. Leader sends heartbeats. No heartbeat -> new election. Higher term number
always wins."

---

### 📘 Concept Explanation

**Why consensus is hard:**

```
Byzantine Generals Problem:
  N generals must agree to attack or retreat
  Some generals may be traitors (send contradictory messages)
  Byzantine fault: node can send arbitrary messages (lie, corrupt)
  Byzantine fault tolerance: requires 3f+1 nodes to tolerate f traitors
  Most distributed systems: assume crash-stop faults (not Byzantine)
  (Node crashes and stays crashed, doesn't send bad messages)

FLP Impossibility (Fischer, Lynch, Paterson 1985):
  Theorem: No deterministic consensus algorithm can guarantee
           termination in an asynchronous system
           if even one process can fail

  Asynchronous: no bounds on message delivery time
  Implication: you can't tell if a node crashed or is just slow

  Practical resolution:
    Assumption: partial synchrony
    (Most of the time: messages arrive within some bound)
    (Even if we can't guarantee it)
    Paxos, Raft: assume partial synchrony -> solve consensus

The two safety properties:
  Safety: If a value is chosen, no other value is ever chosen
          (agreement: all correct nodes decide the same value)
          (validity: the decided value was proposed by some node)
  Liveness: Eventually, a value is chosen
            (termination: every correct node eventually decides)

  Note: safety vs liveness tradeoff
    CP systems: prioritize safety (may never terminate under partition)
    AP systems: prioritize liveness (may decide different values)
```

> **Code walkthrough:** This Distributed Consensus and Leader Election example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Raft consensus algorithm:**

```
Raft roles:
  Leader: handles all client requests, replicates log entries
  Follower: passive, responds to requests from leader/candidates
  Candidate: seeking election, transitions from follower

Raft terms:
  Monotonically increasing counter
  Each term: at most one leader
  Term number in every message
  If node receives message with higher term: update term, become follower

Leader election:
  1. Follower: no heartbeat for election timeout (150-300ms random)
  2. Follower: increments term, becomes Candidate
  3. Candidate: votes for self, sends RequestVote to all nodes
  4. RequestVote includes: term, candidate_id, last_log_index, last_log_term
  5. Follower votes yes if:
     - candidate's term >= own term
     - candidate's log is at least as up-to-date as own log
     - hasn't voted in this term yet
  6. Candidate receives majority: becomes leader
  7. Leader: sends empty AppendEntries (heartbeat) immediately

Log replication:
  1. Client: request to leader
  2. Leader: appends entry to local log (uncommitted)
  3. Leader: sends AppendEntries to all followers
  4. Follower: appends to local log, responds OK
  5. Leader: receives majority ACK -> commits entry
  6. Leader: responds to client (committed)
  7. Leader: notifies followers of commit in next AppendEntries

Safety guarantee:
  Leader has all committed entries (guaranteed)
  Election: won't vote for candidate whose log is less up-to-date
  -> Leader always has the full committed history
  -> No data loss on leader election
```

> **Code walkthrough:** This Distributed Consensus and Leader Election example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Split-brain prevention:**

```
Split-brain: two nodes both believe they are leader

Scenario:
  3-node cluster: [A(leader), B, C]
  Network partition: A isolated from B and C
  B and C can communicate: elect new leader (B)
  A: still thinks it's leader (no failure notification)
  -> Two leaders: A and B

Raft prevention:
  A: receives no heartbeat ACKs (B and C don't respond)
  A: eventually steps down (can't commit without majority)
  B and C: quorum (2/3) -> elect B as leader

  A can't commit: needs majority (2/3), only has 1 (itself)
  All A's writes: never committed (client gets no response)
  After partition heals: A becomes follower, syncs from B

  Fence: old leader (A) might still send stale heartbeats to clients
  Solution: term numbers
  B has higher term: clients reject A's stale responses (lower term)

Fencing with epoch:
  Leader election: epoch/term number assigned
  Client operations include epoch
  Old leader (lower epoch): client rejects
  -> Prevents old leader from serving stale data to clients
  Used in: Apache Kafka (epoch per partition leader)
           ZooKeeper (epoch per session)
```

> **Code walkthrough:** This Distributed Consensus and Leader Election example demonstrates a key concept in practice using Kafka messaging. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

```java
// Distributed lock with leader election using Curator (ZooKeeper)
@Service
public class LeaderElectionService {

    private final CuratorFramework curator;
    private LeaderLatch leaderLatch;

    @PostConstruct
    public void start() throws Exception {
        leaderLatch = new LeaderLatch(
            curator,
            "/election/my-service",  // ZooKeeper path
            getHostname());

        leaderLatch.addListener(new LeaderLatchListener() {
            @Override
            public void isLeader() {
                log.info("Became leader: {}", getHostname());
                startLeaderTasks();
            }

            @Override
            public void notLeader() {
                log.info("Lost leadership: {}", getHostname());
                stopLeaderTasks();
            }
        });

        leaderLatch.start();
    }

    public boolean isLeader() {
        return leaderLatch.hasLeadership();
    }

    // Only leader executes scheduled task:
    @Scheduled(fixedDelay = 60000)
    public void scheduledTask() {
        if (!isLeader()) {
            return;  // silently skip on non-leaders
        }
        // Only runs on the leader instance
        performLeaderOnlyTask();
    }

    @PreDestroy
    public void stop() throws IOException {
        leaderLatch.close();
        // ZooKeeper: ephemeral node deleted -> next leader elected
    }
}
```

```java
// Implementing distributed consensus for two-phase commit
// using Redis (simplified, not production-grade)
@Service
public class TwoPhaseCommitCoordinator {

    private final RedisTemplate<String, String> redis;

    /**
     * Two-Phase Commit across multiple participants
     * Phase 1: ask all to prepare
     * Phase 2: commit if all prepared, else abort
     */
    public boolean executeDistributedTransaction(
            String txId,
            List<Participant> participants) {
        // Phase 1: Prepare
        List<Boolean> prepared = participants.stream()
            .map(p -> prepare(p, txId))
            .collect(Collectors.toList());

        boolean allPrepared = prepared.stream()
            .allMatch(b -> b);

        // Phase 2: Commit or Abort
        if (allPrepared) {
            participants.forEach(p -> commit(p, txId));
            return true;
        } else {
            participants.forEach(p -> abort(p, txId));
            return false;
        }
    }

    private boolean prepare(Participant p, String txId) {
        // Record prepare decision in Redis
        // (allows recovery if coordinator crashes)
        String key = "2pc:" + txId + ":" + p.getId();
        try {
            boolean success = p.prepare(txId);
            redis.opsForValue().set(key,
                success ? "PREPARED" : "ABORT",
                Duration.ofMinutes(5));
            return success;
        } catch (Exception e) {
            redis.opsForValue().set(key, "ABORT",
                Duration.ofMinutes(5));
            return false;
        }
    }

    // Recovery: on restart, check Redis for in-progress transactions
    // PREPARED state: complete the commit
    // ABORT state: send abort to all
    public void recover(String txId,
                         List<Participant> participants) {
        String stateKey = "2pc:" + txId + ":state";
        String state = redis.opsForValue().get(stateKey);

        if ("COMMITTED".equals(state)) {
            // Complete: send commit to any that didn't receive it
            participants.forEach(p -> p.commit(txId));
        } else if ("ABORTED".equals(state)) {
            participants.forEach(p -> p.abort(txId));
        }
        // PREPARED but no commit/abort: coordinator crashed
        // Policy: abort (pessimistic) or commit (optimistic)
    }
}
```

> **Code walkthrough:** The Curator LeaderLatch uses ZooKeeper ephemeral nodes.
> When a service instance starts, it creates an ephemeral sequential node under
> the election path. ZooKeeper orders them; the instance with the smallest
> sequence number becomes leader. If the leader crashes: its ephemeral node is
> deleted (ZooKeeper detects session expiry). The next node in sequence becomes
> the watcher's trigger, starting the new leader. The listener pattern cleanly
> separates leader and follower behavior. The @Scheduled task pattern is the
> most common use: scheduled jobs that must run on exactly one instance.
> The 2PC coordinator shows why coordinator crash recovery is hard: if the
> coordinator crashes after preparing participants but before sending commit,
> participants are stuck in "prepared" state. The recovery mechanism (read from
> Redis, complete the transaction) requires the coordinator to be idempotent.

```java
// Etcd-based leader election (Kubernetes-style)
@Component
public class EtcdLeaderElection {

    private final io.etcd.jetcd.Client etcdClient;
    private final String serviceName = "my-service";

    public void startElection() throws Exception {
        Election election = etcdClient.getElectionClient();
        ByteSequence electionName =
            ByteSequence.from(("/election/" + serviceName)
                .getBytes());
        ByteSequence proposal =
            ByteSequence.from(getHostname().getBytes());

        // Campaign: blocks until this instance becomes leader
        // (Raft ensures only one campaigns at a time)
        election.campaign(electionName, proposal).get();

        // If we reach here: this instance is the leader
        log.info("Won election: {}", getHostname());

        try {
            performLeaderDuties();
        } finally {
            // Resign: allows another instance to become leader
            // (e.g., for graceful shutdown)
            election.resign(electionName).get();
        }
    }

    // Watch for leadership changes
    public void watchLeaderChanges() {
        Election election = etcdClient.getElectionClient();
        ByteSequence electionName =
            ByteSequence.from(("/election/" + serviceName)
                .getBytes());

        election.observe(electionName,
            new Election.Listener() {
                @Override
                public void onNext(LeaderResponse response) {
                    String currentLeader = response
                        .getKv().getValue().toString();
                    log.info("Current leader: {}", currentLeader);
                }

                @Override
                public void onError(Throwable t) {
                    log.error("Election watch error", t);
                }

                @Override
                public void onCompleted() { }
            });
    }
}
```

> **Code walkthrough:** etcd's Election API uses Raft under the hood. Theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `campaign()` call tries to become leader: it creates an ephemeral key with
> a lease. If another instance already holds the key: this instance blocks
> (watches and waits). When the current leader's lease expires (crash) or
> it resigns (graceful): the next campaigner wins. The Raft log ensures only
> one campaign succeeds per term. The `observe()` watch allows non-leader
> instances to track who the current leader is (useful for routing: "send
> this request to the leader"). This is the production pattern for single-writer
> jobs: only one instance performs writes, others remain ready to take over.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Leader election solves the problem of multiple servers all wanting to be the
> "primary" that handles writes. If two servers both think they're primary and
> accept writes simultaneously: you get conflicting data (split-brain). Leader
> election algorithms like Raft use a voting system: one node asks all others
> to vote for it; if the majority vote yes, it becomes leader. Distributed
> systems like Kafka and Kubernetes use etcd (which uses Raft) to elect leaders.

**Senior / Staff:**
> The practical failure mode to understand is the partial partition: a leader
> can reach some followers but not all. If it can reach a majority: it stays
> leader (Raft). If it can't reach a majority: it can't commit new entries
> (waits). This is the "minority partition becomes unavailable" guarantee in
> CP systems. The operational challenge: misconfigured timeouts can cause
> frequent leader elections under load. If follower election timeout is too short
> (100ms), and a leader is briefly slow due to CPU spike: followers start
> elections, term numbers increment, old leader loses leadership. The system
> thrashes: constant elections, no progress. Fix: election timeout >> heartbeat
> interval (heartbeat 100ms, election timeout 1000ms minimum). etcd default:
> heartbeat 100ms, election 1000ms. Adjust based on observed leader election rate.

---

### ⚠️ Common Misconceptions

**Misconception: "Consensus means all nodes agree all the time."**
Consensus means: once a value is COMMITTED (majority ack'd), it's permanent.
During the process: nodes may temporarily disagree (follower hasn't received
the entry yet). Safety is about committed values, not in-flight values.
Liveness is about eventually committing. A node that crashes before committing
the leader's entry: will catch up when it rejoins (Raft log synchronization).
"All nodes agree all the time" would require synchronous replication to all nodes
before committing - that's not Raft's model.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Network partition causing dual-leader and data divergence**
Symptom: two instances of the service each believe they are leader; writes to
both; data inconsistency detected in reconciliation.
Root cause: failed to implement proper leader election (e.g., each instance
checked a different Redis key instead of using a consensus system).
Also: ZooKeeper session expiry ignored (instance continued as "leader" after
session expired because no monitoring on session state).
Fix: always use a consensus system (ZooKeeper, etcd, Consul) for leader election.
Monitor: session state. On session expiry: immediately stop leader duties.

---

### 🎯 Interview Deep-Dive

**Timing:** Hard ★★★ - 12 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] Walk me through the Raft leader election process step by step.**

```plaintext
Initial state:
  3-node cluster: [A, B, C], all followers, term 0

Step 1: Election timeout fires (A first, random 150-300ms)
  A: increments term: term 0 -> term 1
  A: transitions to Candidate
  A: votes for itself

Step 2: A sends RequestVote to B and C
  RequestVote {
    term: 1,
    candidateId: A,
    lastLogIndex: 0,   (empty log)
    lastLogTerm: 0
  }

Step 3: B receives RequestVote
  B checks:
    term 1 >= B's term 0? YES (B updates term to 1)
    B has voted in term 1? NO
    A's log (0,0) >= B's log (0,0)? YES (at least as up-to-date)
  B: grants vote -> response {term:1, voteGranted: true}

Step 4: C receives RequestVote
  C: same checks, grants vote

Step 5: A receives majority (B + C = 2/3 + itself = 3/3)
  A: becomes Leader for term 1

Step 6: A sends heartbeat (empty AppendEntries) to B and C
  AppendEntries { term: 1, leaderId: A, ... }
  B and C: reset election timeout
  Cluster: stable with A as leader

Step 7: Client write arrives at A
  A: append to local log as uncommitted entry
  A: sends AppendEntries to B and C (with the entry)
  B and C: append to local log, respond OK
  A: receives 2 OKs (majority) -> commit entry
  A: responds to client: success
  A: sends next heartbeat indicating commit_index increased
  B and C: mark entry as committed on next heartbeat
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The election safety property: Raft ensures
only nodes with the most complete log can win elections. If A crashes after
committing an entry but B and C haven't received the commit notification yet:
they still have the entry in their logs (just uncommitted). In the next election:
B or C can win (both have the entry). If a new candidate C has log [0,0] and
B has log [1, term 1]: C can't win (B rejects vote because C's log is less
up-to-date). This log completeness check in voting is the key safety mechanism:
the new leader always has all committed entries.

---

**[JUNIOR] Q2 - [DEBUGGING] How does Raft handle log conflicts after a leader crash?**

Log inconsistencies can arise when a leader crashes mid-replication:

```
Scenario: leader crashes before replication completes

Cluster: [L(leader), F1, F2]
  L's log: [1, 2, 3, 4, 5]  (entries 4-5 not yet replicated)
  F1's log: [1, 2, 3, 4]    (entry 4 replicated but not 5)
  F2's log: [1, 2, 3]       (entries 4-5 not replicated)

L crashes. F1 wins election (log [1,2,3,4], most complete).
F1 becomes new leader for term 2.

F1 must ensure F2's log matches F1's:
  F1: send AppendEntries to F2
  AppendEntries includes: prevLogIndex=4, prevLogTerm=term1
  F2: checks: my log at index 4? MISSING
  F2: responds: fails (log inconsistency)

  F1: backs up: try prevLogIndex=3, prevLogTerm=term1
  F2: checks: my log at index 3? EXISTS, term matches
  F2: responds: OK, but my log index 3 is the last
  F1: sends entries [4] to F2 (fills the gap)
  F2: appends entry 4

  F1: also check: does F2 have any extra entries?
  (Can happen if F2 had uncommitted entries from old leader)
  F1: F2's log [1,2,3,4]: OK, matches F1's

What about entry 5 (on old L, never replicated)?
  Entry 5 was only on crashed L's log
  It was never replicated to majority -> never committed
  Client never received acknowledgment for entry 5 (L crashed)
  Entry 5: lost (as if never happened)
  Raft guarantee: ONLY committed entries are durable
                  (in the majority before crash)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The truncation of uncommitted entries is
the key safety mechanism. Raft's invariant: an entry is committed only when
a majority of nodes have it. If an entry was only on the crashed leader: it
wasn't committed, so it's safe to discard. The new leader overwrites any
follower's log entries that conflict with its own (followers always copy the
leader). This is why Raft clients must handle "commit pending, then reconnect
to new leader" - the operation may or may not have been committed before the
crash. The client should retry; if the operation was idempotent: safe. If not:
use a unique operation ID and let the server deduplicate.

---

**[JUNIOR] Q3 - [CONCEPTUAL] What is the difference between Paxos and Raft?**

```plaintext
Paxos (Lamport, 1989):
  Original consensus algorithm
  Phases: Prepare -> Promise -> Accept -> Accepted
  Single-decree: agrees on ONE value
  Multi-Paxos: extended for log replication (not formally specified)

  Properties:
    Safety: proven formally by Lamport
    Liveness: not guaranteed (can livelock under contention)
    Understanding: notoriously difficult

  "The Most Widely Misunderstood Algorithm":
    Multi-Paxos has many variants; each implementation different
    No single canonical implementation
    Google Chubby: uses Paxos (unreleased, internal)
    ZooKeeper: uses Zab (similar to Paxos, different details)

Raft (Ongaro & Ousterhout, 2014):
  Designed for understandability
  Key design choice: strong leader (all decisions through leader)
  Separates: leader election + log replication + safety
  Formally specified, tested, extensively deployed

  Properties:
    Safety: equivalent to Paxos
    Liveness: random timeouts prevent livelock
    Understanding: explicitly designed to be simpler
    Implementations: etcd, CockroachDB, TiKV, Consul

Practical differences:
  Paxos: any node can be proposer (more concurrent)
  Raft: only leader proposes (simpler, but single bottleneck)

  Multi-Paxos: leader may not be strictly required for reads
  Raft: all reads go through leader (strong consistency)
         or followers with ReadIndex protocol (more efficient)

  Paxos variants: Multi-Paxos, Fast Paxos, Cheap Paxos
  Raft: one canonical algorithm (easier to understand + implement)

When to choose:
  Most new systems: Raft (better documented, proven implementations)
  Legacy Paxos systems: ZooKeeper (Zab), Chubby
  Special constraints (very high throughput): customized Paxos variants
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The Raft paper's key contribution wasn't
correctness (Paxos was already correct) but testability. Raft's design allows
systematic correctness testing through formal verification and fault injection.
The etcd and CockroachDB teams have extensively tested Raft with Jepsen (network
partition + concurrent operations + linearizability checker). TLA+ (formal
specification language) verification of Raft finds subtle bugs before
implementation. The operational lesson: use a well-tested implementation
(etcd, Consul) rather than implementing Raft yourself. The algorithm is
simple to understand but subtle to implement correctly (leader read protocol,
log term comparison, election timeout tuning).

---

**[MID] Q4 - [CONCEPTUAL] How does ZooKeeper use consensus for distributed coordination?**

ZooKeeper: distributed coordination service using Zab (Zookeeper Atomic Broadcast).

```
ZooKeeper architecture:
  Ensemble: 3 or 5 ZooKeeper nodes (odd number for quorum)
  Leader: elected using Zab (similar to Paxos)
  Followers: serve reads, forward writes to leader

  All writes: go through leader -> Zab replication -> committed
  Reads: any node (may be slightly stale)
  Strict read (strong consistency): force read through leader

ZooKeeper data model:
  Hierarchical znodes: /election/my-service/node-0001
  Ephemeral znodes: deleted when client session expires
  Sequential znodes: guaranteed monotonically increasing number

Leader election using ephemeral sequential znodes:
  1. Client creates: /election/my-service/node-0001 (ephemeral + sequential)
  2. All clients: list children of /election/my-service
  3. Client with smallest number: IS the leader
  4. Other clients: watch the node just before them (not the leader directly)

  Client A: created node-0001, smallest -> A is leader
  Client B: created node-0002, watches node-0001 (A)
  Client C: created node-0003, watches node-0002 (B)

  A crashes: node-0001 deleted (ephemeral + session expiry)
  B receives watch: I was watching node-0001, it's gone
  B: re-checks, am I smallest? node-0002 is smallest -> B is leader
  C: still watches node-0002 (now B), no action needed

  This pattern: no thundering herd
  Only ONE client notified per leader failure (the next in line)
  Without this: all clients watch the leader -> N-1 notifications on failure

ZooKeeper guarantees:
  Linearizable writes
  FIFO client ordering (client's requests in submission order)
  Atomic broadcast: all or none of followers see each update
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The watch-predecessor pattern (each client
watches only the node immediately before it) is the key optimization in ZooKeeper
leader election. A naive implementation (all clients watch the leader) creates
a thundering herd: leader fails, N-1 clients all wake up simultaneously, all
check if they're leader, all contact ZooKeeper at once. N=100 clients = 100
simultaneous ZooKeeper requests. The predecessor-watch pattern: exactly one
client is notified per leader failure (the next in sequence). This scales to
thousands of clients. The same pattern is used for ZooKeeper-based distributed
queues (first node in queue = current processor; each client watches predecessor).

---

**[MID] Q5 - [HANDS-ON] How do distributed databases use consensus for write operations?**

Consensus in distributed databases: correctness for every write.

```plaintext
CockroachDB (Raft per range):
  Data: sharded into "ranges" (contiguous key ranges)
  Each range: replicated to 3 nodes via Raft
  Write to key K:
    1. Route to range containing K
    2. Find Raft leader for that range
    3. Leader replicates to followers (majority = committed)
    4. Return to client

  Range leadership:
    Each range has its own Raft group
    Many ranges: many Raft leaders (distributed load)
    Single hotspot key: one range leader -> can be bottleneck

  Cross-range transactions:
    CockroachDB uses 2PC + Paxos-based timestamps
    Parallel Commits: one-round optimization for most transactions
    True time: HLC (Hybrid Logical Clocks) for global ordering

Spanner (Paxos per shard group):
  Shards: replicated across multiple zones via Paxos
  Transactions: two-phase, coordinator uses Paxos
  TrueTime: commits acquire timestamps outside TrueTime uncertainty
  Result: externally consistent (global linearizability)

Cosmos DB (multiple consistency levels):
  Underlying: Paxos per partition group
  Session model: consistency = Strong, Bounded Staleness, Session,
                               Consistent Prefix, Eventual
  Strong: uses Paxos synchronously (reads from primary)
  Eventual: reads from any replica (Paxos async)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* CockroachDB's per-range Raft groups mean
that adding nodes increases total write throughput (more ranges can have leaders
on new nodes). A single Raft group (one leader for the entire DB) becomes
a write bottleneck as the system scales. Distributing leadership across many
Raft groups scales linearly. The challenge: a query that spans many ranges
requires coordination across multiple Raft groups (cross-range transaction).
CockroachDB's Parallel Commits optimization commits in one round instead of
two for most transactions, reducing the latency overhead of multi-Raft coordination.

---

**[MID] Q6 - [TRADE-OFF] What is the quorum size trade-off in distributed systems?**

Quorum: minimum nodes that must acknowledge for an operation to succeed.

```
Quorum formula: Q > N/2 (majority)
  N=3: Q=2 (majority of 3)
  N=5: Q=3 (majority of 5)
  N=7: Q=4 (majority of 7)

Failure tolerance:
  N=3, Q=2: can tolerate 1 failure (3-1=2=Q still available)
  N=5, Q=3: can tolerate 2 failures (5-2=3=Q still available)
  N=7, Q=4: can tolerate 3 failures

  Rule: tolerate F failures -> need 2F+1 nodes
    F=1: 3 nodes
    F=2: 5 nodes
    F=3: 7 nodes

Write quorum vs Read quorum:
  Write: write to W nodes, succeed when W nodes ACK
  Read: read from R nodes, return latest value
  Consistency: W + R > N (overlap ensures freshest read)

  N=3, W=2, R=2: W+R=4 > 3 -> consistent
    Write succeeds: majority (2/3)
    Read: reads from 2/3 -> must include at least 1 writer
  N=5, W=3, R=3: W+R=6 > 5 -> consistent
    Write succeeds: majority (3/5)
    Read: reads from 3/5 -> guaranteed overlap

Availability vs consistency:
  W=1, R=N: high write availability, strong read consistency
  W=N, R=1: strong write consistency, high read availability
  W=Q, R=Q (quorum): balanced
  W=1, R=1: high availability, weak consistency (AP)

  Cassandra: tunable (W and R per query)
  Raft: W=majority, R=leader (no explicit quorum for reads)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The quorum selection affects both throughput
and fault tolerance. N=5, Q=3 (majority): write throughput = limited by 3
replicas acknowledging. If 3 of 5 are slow: write latency is the slow one.
N=3, Q=2: only 2 must ack -> lower write latency. Lower fault tolerance (only
1 failure tolerated). For most production systems: N=3, Q=2 (majority) is
the sweet spot. N=5 is used when you need to tolerate 2 simultaneous failures
(maintenance + unexpected failure, or two AZs failing). The decision: "How many
nodes can we afford to lose simultaneously without losing availability?"
That number + 1 is your quorum; 2 * (failures) + 1 is your cluster size.

---

**[SENIOR] Q7 - [CONCEPTUAL] How does etcd ensure strong consistency for Kubernetes?**

etcd: distributed key-value store for Kubernetes cluster state.

```plaintext
Kubernetes uses etcd for:
  All cluster state: pods, services, deployments, config maps
  Desired state: what the user wants
  Actual state: read by controllers from etcd, written back

etcd guarantees:
  Linearizable reads: every read sees the latest committed write
  Serializable transactions: multiple keys, atomic update
  Watch: real-time notifications on key changes

How Kubernetes uses etcd:
  kubectl apply -> API server -> etcd write (desired state)
  Scheduler: watches etcd for unscheduled pods -> assigns node
  Kubelet: watches etcd for pods scheduled to its node -> starts them
  Controller: watches etcd for desired state -> reconciles with actual

Strong consistency for scheduling:
  Two schedulers: both see unscheduled pod, both try to bind to node
  etcd: only one write succeeds (optimistic concurrency: check pod.nodeName ==...
  Second: write fails (pod already scheduled)
  -> Exactly one scheduler wins

etcd performance:
  Throughput: 10,000-100,000 operations/second
  Latency: <10ms P99 (SSD + fast network)
  Kubernetes: typically 200-2000 etcd operations/second
              well within limits

etcd reliability:
  Raft: 3 or 5 etcd nodes for HA
  Kubernetes: 3-node etcd cluster (tolerate 1 failure)
  Production: 5-node for large clusters (tolerate 2 failures)
  Backup: snapshot + WAL backup for disaster recovery
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* etcd performance under Kubernetes load depends
on disk I/O. etcd fsync's every Raft log entry before acknowledging. SSD (NVMe)
etcd: ~10,000 ops/second. HDD etcd: ~1,000 ops/second (10x slower). Large
Kubernetes clusters (1000+ nodes, many controllers writing state) can overwhelm
slow etcd. The warning: `etcd cluster is unavailable` in Kubernetes events.
The fix: use fast NVMe SSDs for etcd. Kubernetes best practice: dedicated etcd
nodes (not co-located with control plane) with NVMe SSDs. Monitoring: watch
`etcd_disk_wal_fsync_duration_seconds` histogram. P99 > 100ms = concerning.
P99 > 1000ms = degraded Kubernetes control plane.

---

**[SENIOR] Q8 - [DEBUGGING] How do you debug a split-brain situation?**

Diagnosing split-brain: two leaders concurrently.

```
Symptoms:
  Two instances both logging "I am the leader"
  Duplicate job execution (job ran twice on the same trigger)
  Data inconsistency (two conflicting writes, both acknowledged)
  Two separate ZooKeeper leader paths created

Diagnosis steps:

1. Identify both "leaders":
  Search logs: grep "became leader" -> timestamps, hostnames
  Two hostnames within same election term = split-brain

2. Determine when split started:
  When did the second node elect itself?
  What network event preceded it?
  ZooKeeper session expired? Network partition?

3. Verify ZooKeeper/etcd state:
  ZooKeeper: ls /election/my-service -> list znodes
    Two znodes with both hosts = two leaders
  etcd: etcdctl get /election/my-service -> one key, one value
    If two keys: configuration error

4. Identify conflicting writes:
  Compare DB write timestamps from both instances
  Find rows where two conflicting values were written in same time window
  Use transaction IDs or sequence numbers to identify order

5. Recovery:
  Step 1: stop both instances (prevent further conflicting writes)
  Step 2: determine correct state (audit log, timestamps)
  Step 3: reconcile DB (apply correct state manually)
  Step 4: fix root cause (configuration, network, ZooKeeper setup)
  Step 5: restart with correct single leader
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Split-brain post-mortems reveal common root
causes: (1) ZooKeeper session timeout too short (network blip expires session
before connection recovery), (2) not checking session validity before performing
leader duties (continued as "leader" after session expired), (3) using Redis
SET NX as the "consensus system" (Redis SET NX is not linearizable under
network partition). Fix (1): increase ZooKeeper session timeout (60 seconds vs
default 30 seconds). Fix (2): check `leaderLatch.hasLeadership()` before every
leader operation, not just at startup. Fix (3): use a real consensus system
(ZooKeeper, etcd, Consul), not Redis, for leader election.

---

**[SENIOR] Q9 - [DEBUGGING] How does Kafka use ZooKeeper (and why is it migrating away)?**

Kafka's ZooKeeper dependency (KIP-500 migration):

```plaintext
Kafka with ZooKeeper (traditional):
  ZooKeeper stores:
    Broker metadata (which brokers are alive)
    Topic metadata (partitions, replication factors)
    Consumer group offsets (legacy, now in __consumer_offsets)
    Partition leader assignments

  Kafka broker startup:
    Register ephemeral node in ZooKeeper: /brokers/ids/{broker_id}
    ZooKeeper: broker list always reflects alive brokers

  Partition leadership:
    ZooKeeper: elects "Controller" broker (using ephemeral node + watch)
    Controller: assigns leaders for all partitions
    Partition leader crash: ZooKeeper detects (ephemeral node deleted)
    Controller: re-elects partition leader (another replica)

  Problems with ZooKeeper:
    Scalability: ZooKeeper struggles with 100K+ partitions
    Operational: separate system to deploy, monitor, maintain
    Latency: metadata changes require ZooKeeper round-trip
    Brain split: ZooKeeper network partition vs Kafka partition = complex

KRaft (Kafka Raft Metadata):
  Built-in Raft replaces ZooKeeper
  3+ "controller" nodes: run Raft for metadata
  Metadata: stored in Kafka's own topic (__cluster_metadata)
  No external dependency: Kafka self-contained

  Advantages:
    Scales to millions of partitions (Kafka's own optimized storage)
    One system to operate
    Faster metadata propagation (Kafka log, not ZooKeeper)
    Simpler deployment (no ZooKeeper cluster)

  Migration (Kafka 3.3+ production-ready):
    Kafka 2.8: KRaft in preview
    Kafka 3.3: production-ready for most use cases
    Kafka 3.7: full feature parity with ZooKeeper mode
    Timeline: ZooKeeper mode deprecated, removed in future major version
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The KRaft migration demonstrates a real-world
system replacing its external consensus dependency with a self-hosted implementation.
The performance motivation: ZooKeeper stores all partition metadata; at 200K
partitions (large Kafka cluster), ZooKeeper watch callbacks on partition changes
create massive bursts of ZooKeeper traffic. KRaft stores this in Kafka's own
log (optimized for this access pattern), dramatically improving scaling.
The correctness motivation: Kafka's partition leader election needed to be
coordinated with ZooKeeper's leader state. Two separate consensus systems
(Kafka's ISR-based election + ZooKeeper's Controller election) needed to agree.
Unifying them eliminates the coordination complexity.

---

**[STAFF] Q10 - [CONCEPTUAL] What is the role of timeouts in distributed consensus?**

Timeouts: detection mechanism for leader failure.

```
Election timeout:
  Follower: if no heartbeat for election_timeout: start election
  Too short: false elections under load (leader briefly slow)
  Too long: slow failure detection (long downtime on real crash)
  Raft recommendation: 150-300ms (random to prevent ties)
  Production etcd: 1000ms (prevents false elections under load)

Heartbeat interval:
  Leader: sends heartbeat every heartbeat_interval
  Must be << election_timeout to prevent false elections
  Rule: heartbeat_interval << election_timeout
  Ratio: at least 3-5x (heartbeat at 100ms, election at 500-1000ms)

Effects of timeout misconfiguration:

  Election timeout too short (50ms):
    Normal GC pause (200ms stop-the-world in Java)
    Followers don't receive heartbeat during GC
    Election timeout fires: false election
    Leader recovers from GC: new leader already elected
    Old leader: steps down (higher term from new leader)
    System: wasted election time, brief unavailability
    Fix: ensure election_timeout > max expected GC pause

  Election timeout too long (10s):
    Leader crashes: detected after 10 seconds
    New leader elected: +100ms (fast)
    Total downtime: 10 seconds
    Fix: tune to match acceptable downtime window

  Network-based detection:
    TCP keepalive: detects dead TCP connections
    But: TCP doesn't detect network partition (both nodes alive, can't communicate)
    Heartbeat over application protocol: detects partition
    Raft heartbeat: application-level -> detects partition correctly
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The interaction between JVM GC pauses and Raft
election timeouts is a real production issue. A Java-based Raft implementation
(or a Java service that holds a Raft leadership) during a major GC pause may fail
to send heartbeats. If the election timeout is shorter than the GC pause:
followers start an election, overthrow the still-alive leader. The JVM-specific
fix: tune G1GC or use ZGC (sub-10ms pauses), and set election_timeout > max_gc_pause.
The language choice: etcd and CockroachDB use Go (no stop-the-world GC) precisely
to avoid this interaction. For Java services using ZooKeeper: tune ZooKeeper
session timeout to be longer than max JVM GC pause.

---

**[STAFF] Q11 - [ARCHITECTURE] How do you design a distributed lock with fencing tokens?**

Distributed lock correctness: preventing stale lock holders from causing harm.

```plaintext
Problem: stale lock holder thinks it still holds the lock

Timeline:
  T=1: Client A acquires lock (via ZooKeeper/Redis)
  T=2: Client A: STW GC pause (30 seconds)
  T=3: Lock expires: timeout after 10 seconds
  T=4: Client B acquires the same lock
  T=5: Client B: performs protected operation (writes to DB)
  T=6: Client A: GC finishes, thinks it still has lock
  T=7: Client A: performs protected operation (ALSO writes to DB)
  T=8: Data corruption (both clients wrote to "protected" resource)

Fencing token solution:
  Lock service: issues monotonically increasing token on lock acquisition
  Client A: acquires lock with token 15
  Client B: acquires lock with token 16
  Resource (DB): accepts writes with token >= last seen token
  Client A: tries to write with token 15
  DB: last seen token = 16 (from Client B) -> reject Client A's write
  No corruption

Implementation:
  ZooKeeper: zxid (ZooKeeper transaction ID) as fencing token
  Redis Redlock: uses lock key version as token
  etcd: use lease revision as fencing token

  Client writes to DB:
  UPDATE orders SET ... WHERE id = ?
  AND lock_token > (SELECT lock_token FROM lock_table WHERE id = ?)

  The DB atomically checks the fencing token
  Outdated lock holder's writes: silently rejected
  Client must handle: "0 rows updated" = lock was stolen

Without fencing tokens:
  Any lock implementation can have the stale-lock-holder problem
  Network delays, GC pauses, OS scheduling: all cause stale lock behavior
  Fencing tokens make the critical section safe even with stale holders
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The fencing token pattern is described in
detail in Martin Kleppmann's "Designing Data-Intensive Applications" and his
blog post critiquing Redlock. The key insight: a distributed lock alone can't
prevent a stale lock holder from operating (the lock holder's clock can lie).
The resource (DB, file, service) must participate in the protocol by checking
the fencing token. This requires the resource to store the "last seen token"
and reject operations with older tokens. The pattern works for any resource
that can compare tokens atomically: SQL (version column), ZooKeeper (write with
expected version), S3 (conditional PUT with etag). Without this: distributed
locks provide a false sense of safety.

---

**[STAFF] Q12 - [ARCHITECTURE] How would you design a distributed election for a payment processing primary?**

System design: highly available payment processor with leader election.

```
Requirements:
  Only ONE instance processes payments at a time (exactly-once guarantee)
  Failover < 30 seconds on primary crash
  No data loss (every payment attempt logged)
  No duplicate payment processing

Architecture:

1. Election layer:
   3-node cluster (payment-processor-1,2,3)
   ZooKeeper or etcd for leader election
   Election timeout: 10 seconds (detect crash)
   Znode TTL / etcd lease: 15 seconds

2. Payment processing (leader only):
   Leader: polls payment queue (Kafka topic)
   Leader: processes one payment at a time
   Non-leaders: standby (ready to take over)

3. Idempotency:
   Payment queue: each payment has unique payment_id
   DB: INSERT INTO processed_payments (payment_id, ...)
       ON CONFLICT (payment_id) DO NOTHING
   Leader crash mid-processing:
     New leader: reads same payment from queue (not committed)
     Processes: INSERT fails (already partial? No: auto-rollback)
     Processes successfully or skips (idempotent)

4. Fencing token integration:
   ZooKeeper: assigns epoch on each election
   Leader: includes epoch in all payment DB writes
   DB check: is this epoch the current leader's epoch?
     SELECT current_epoch FROM election_state
     If epoch < current: reject write (stale leader)
   Prevents: stale leader resuming from GC pause

5. Monitoring:
   Leader heartbeat: Prometheus metric (leader_status 1/0)
   Alert: leader_changes_per_hour > 3 (unstable election)
   Alert: no leader for > 30 seconds (election failure)
   Alert: payment processing lag > SLO (leader is slow)

Recovery scenario:
  Leader crashes T=0
  Crash detected: T=10 (election timeout)
  New election: T=11 (fast, quorum available)
  New leader elected: T=12
  New leader starts processing: T=13
  Total downtime: 13 seconds (within 30s SLO)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The combination of leader election + idempotency +
fencing tokens provides the "exactly-once" guarantee for payment processing.
Leader election ensures one primary. Idempotency ensures re-processing is safe
(if the new leader picks up a partially processed payment). Fencing tokens ensure
stale leaders can't corrupt data. Any two of the three is insufficient. Without
idempotency: duplicate payment charges on leader failover. Without fencing tokens:
stale leader resuming from GC pause overrides new leader's writes. Without leader
election: two instances process the same payment. This three-layer approach is
standard in production payment systems. The interview question tests whether the
candidate knows all three layers are needed, not just leader election.

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



