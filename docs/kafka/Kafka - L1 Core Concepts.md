---
layout: default
title: "Kafka - L1 Core Concepts"
parent: "Kafka"
grand_parent: "SK Interview"
nav_order: 2
permalink: /kafka/l1-core-concepts/
---

# Kafka - L1 Core Concepts

---

# Topic

---
id: KFK-004
title: Topic
category: Kafka
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #kafka, #topic, #partition, #event-streaming
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical — the first Kafka concept every interviewer
covers. A weak definition signals shallow Kafka knowledge.

---

### 🎯 Model Answer

**30 seconds:**
> A Kafka topic is a named, ordered log of events - like a category or channel
> where producers write and consumers read. Topics are split into partitions
> for parallelism and distribution across brokers. Once written, records are
> immutable; they are retained for a configured period regardless of whether
> they have been read.

**3 minutes (Senior):**
> A Kafka topic is the fundamental unit of data organization in Kafka - a
> named, logical grouping of related events. Under the hood, a topic is split
> into one or more partitions, each of which is an ordered, immutable sequence
> of records stored on disk. Each record in a partition gets a unique,
> monotonically increasing offset. When you create a topic, you set the
> partition count and replication factor - partition count controls parallelism
> (more partitions = more consumers in parallel), and replication factor
> controls durability (3 is standard for production). Topics are write-once,
> read-many: the log is immutable and retained for a configurable period.
> Retention is independent of consumption - Kafka does not delete a record
> when a consumer reads it. The partition count decision is critical and hard
> to reverse: too few limits throughput and consumer parallelism; too many
> increases broker overhead in file handles, replication cost, and leader
> election time.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* At senior level, discuss topic retention policies (time vs
size), log compaction as an alternative, and the partition count trade-offs.

*Adapting down:* "A topic is like a folder in a filing system - you write
related events to it and consumers read from it."

**Blank Mind Recovery:**

**(1) Restate:** "So you are asking about Kafka topics - let me think through
what problem they solve."

**(2) First principles:** "You need a way to organize events by category and
store them durably in order. A topic is that named, ordered store."

**(3) Bridge:** "This reminds me of a database table - but instead of rows
that can be updated, it is an immutable append-only log where consumers track
their reading position with an offset."

---

### 📘 Concept Explanation

**What it is:**
A Kafka topic is a named, partitioned, replicated log of events. It is the
primary unit of data organization - producers write to topics and consumers
read from them.

**The problem it solves:**
Without topics, all Kafka events would be in a single undifferentiated stream.
Topics provide logical separation - orders, payments, and user events live in
different topics so consumers subscribe only to what they need.

**How it works:**

```
Topic: "orders" (partitions=3, replication-factor=2)

Partition 0: [0]order-A [1]order-D [2]order-G [3]order-J  <- append
Partition 1: [0]order-B [1]order-E [2]order-H  <- append
Partition 2: [0]order-C [1]order-F [2]order-I  <- append

Each partition = ordered log, stored as segment files on disk.
Records within a partition: totally ordered by offset.
Records ACROSS partitions: NO ordering guarantee.
```

**The key insight:**
Partition count determines maximum consumer parallelism. A consumer group
can have at most one active consumer per partition. Setting partition count
too low at creation time is a painful and disruptive change later - increasing
partitions breaks per-key ordering because existing records stay in their
original partitions while new records may land in new ones.

**When to use it:**
- Separate logical event types (orders vs payments vs inventory)
- Different retention requirements (7 days vs 90 days vs indefinite)
- Different access control - some consumers should not see all data
- Different replication factors based on business criticality

**When NOT to use it:**
- Do not create one topic per tenant in a multi-tenant system (use partitioning)
- Do not create topics for every microservice internal state change

**Alternatives:**
- Topic per event type → clean separation, more topics to manage
- Single topic with event type field → fewer topics, consumer must filter
- Topics by domain → balance between cohesion and separation

**First-principles derivation:**
You need to write heterogeneous events to a distributed log. Without namespacing,
all consumers receive all events and must filter - wasted network and CPU. A
topic is the namespace that solves this. Partitioning within the topic adds
horizontal scale: no single sequential log handles millions of events/sec, so
the topic is sharded into partitions each handling its share independently.

---

### 💻 Code Example

**Example 1: Creating a topic programmatically**

```java
Properties adminProps = new Properties();
adminProps.put("bootstrap.servers", "localhost:9092");

try (AdminClient admin = AdminClient.create(adminProps)) {
    NewTopic ordersTopic = new NewTopic(
        "orders",   // topic name
        6,          // partition count: based on expected consumers
        (short) 3   // replication factor: 3 for production
    );
    ordersTopic.configs(Map.of(
        "retention.ms", "604800000",  // 7 days in milliseconds
        "cleanup.policy", "delete"    // time-based deletion
    ));
    admin.createTopics(List.of(ordersTopic)).all().get();
}
```

> **Code walkthrough:** `AdminClient` creates topics without needing a CLI.
> The partition count (6) sets the maximum consumer group parallelism. The
> replication factor (3) means data survives 2 broker failures. The
> `retention.ms` config controls how long records are kept - without it,
> Kafka uses the broker-level default (often 7 days). Getting partition count
> wrong at creation requires disruptive repartitioning later.

**Example 2: Partition count decision (BAD vs GOOD)**

```java
// BAD: single partition - one consumer max, write bottleneck
NewTopic bad = new NewTopic("orders", 1, (short) 1);
// RF=1 = no durability, data loss if broker dies

// GOOD: partitions = 2x expected consumer group size
// Replication factor 3 for critical topics
NewTopic good = new NewTopic("orders", 6, (short) 3);
// 6 partitions = up to 6 parallel consumers
// RF=3 = survives 2 concurrent broker failures
```

> **Code walkthrough:** The BAD pattern creates a single-partition topic that
> limits the system to exactly one consumer and one write-path broker. This
> becomes a bottleneck under any real load. The GOOD pattern uses 6 partitions
> (2x expected consumer count of 3), providing room to scale. The RF=3 ensures
> no single broker failure causes data loss - critical for any production
> pipeline carrying business-critical events.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A Kafka topic is a named category for events - like a database table but as
> an ordered, immutable log. Producers write to topics and consumers read from
> them. Topics are split into partitions for parallelism.

*Push deeper:* Explain that partition count determines maximum consumer
parallelism in a consumer group, and that the partition count decision is
important to get right at creation.

---

**Senior / Staff (5+ years):**
> A topic is a named, partitioned, replicated append-only log. The partition
> count decision is the most operationally significant choice when creating a
> topic - it sets the maximum consumer parallelism for that topic's consumer
> groups. I use 2-3x the expected consumer count as a starting point, tuned
> by expected throughput. Replication factor of 3 is standard for production.
> The retention policy choice - time-based deletion vs log compaction - depends
> on whether consumers need full history (use time retention) or only the
> latest state per key (use compaction, e.g., for a user profile store).

*Push deeper:* At staff level, discuss the partition count increase trade-off:
increasing partitions breaks per-key ordering because existing records stay
in their original partitions while new records may land in new ones. A safer
approach for ordering-sensitive cases is to blue-green deploy to a new topic.

---

### ⚠️ Common Misconceptions

**Misconception 1: A Kafka topic is equivalent to a database table.**

A database table persists records indefinitely and supports random access by primary key, updates, and deletes. A Kafka topic is an append-only ordered log with time-based or size-based retention (default 7 days). Topics support sequential reads by offset only - there is no equivalent of `SELECT * WHERE id = 123`. The correct mental model: a topic is a durable event log, not a queryable store. For query-friendly access to topic data, project it into a database (via Kafka Streams or Kafka Connect) rather than reading the topic directly.

**Misconception 2: Topic retention is linked to consumer acknowledgment.**

Topic retention is completely independent of consumer state. Retention governs how long Kafka keeps messages based on time (`retention.ms`) or size (`retention.bytes`) - not whether messages were consumed. A consumer group that commits all offsets does NOT cause message deletion; the messages stay until retention expires. Conversely, an offline consumer that reconnects after its retention window has elapsed will have missed messages permanently - there is no "hold until consumed" semantics without a dedicated queue system.

**Misconception 3: You can rename a Kafka topic.**

Kafka has no `RENAME TOPIC` operation. The only path is: create a new topic with the desired name, mirror messages from old to new (using MirrorMaker 2 or a custom consumer-producer bridge), migrate all consumers and producers to the new topic, then delete the old topic after verifying all consumers have caught up to the end of the new topic. This is a multi-day migration for active, high-volume topics.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Topic retention too short causes consumer to miss messages after slow processing.**

Symptom: consumer lag grows during a processing spike; when the consumer catches up, it discovers that the earliest available offset on some partitions is ahead of its last committed offset; messages in the gap are permanently lost. Diagnosis: `kafka-consumer-groups --describe --group <group>` shows LAG and CURRENT-OFFSET; compare against `kafka-log-dirs --describe` to find the earliest available offset per partition; if current-offset < earliest-offset, data was lost. Fix: increase `retention.ms` on affected topics to provide enough buffer for the consumer's worst-case processing lag; set retention to at least 3x the consumer's SLA (if the consumer must process within 6 hours, set retention to 18+ hours); add an alert when consumer lag exceeds 50% of retention time.

**Failure Mode 2: Topic partition count increase breaks per-key ordering guarantees.**

Symptom: after a partition count increase, a consumer sees events for the same key arriving out of order across partitions; an event for key `user-123` at T=10 is in partition 3, but a later event at T=20 is in partition 7 (new partition), processed by a different consumer. Diagnosis: compare partition count history using `kafka-topics --describe`; identify whether key-based ordering is a requirement for the affected topic; check whether the partition count was increased after initial messages were written. Fix: design partition count at topic creation to avoid increases; if increase is required, implement a consumer-side reordering buffer keyed by the business entity ID; use a timestamp or sequence number in the message payload to detect and reorder out-of-sequence deliveries.

**Failure Mode 3: Under-replicated partitions block producer writes when `min.insync.replicas` is set.**

Symptom: producers receive `NotEnoughReplicasException`; topic write throughput drops to zero; the cluster health shows under-replicated partitions in the management UI. Diagnosis: `kafka-topics --describe --topic <topic> --under-replicated-partitions`; check which brokers are down or lagging; compare ISR size against `min.insync.replicas` (default 1, recommended 2 for `acks=all`). Fix: ensure the cluster has at least `replication.factor` brokers online and in-sync; for `replication.factor=3` and `min.insync.replicas=2`, the cluster can tolerate 1 broker down; losing 2 brokers blocks all writes; restore the failed broker or reduce `min.insync.replicas` temporarily (accepting durability risk).

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is a Kafka topic?"
- "How is a Kafka topic different from a queue?"

🗣️ "A Kafka topic is a named, ordered, immutable log of events. Unlike a
queue where messages are deleted after consumption, a topic retains records
for a configured period. Multiple consumer groups can read the same topic
independently by tracking their own offset - no message duplication required."

#### Mechanism
- "How is a Kafka topic stored on disk?"
- "What happens when you increase the partition count of a topic?"

🗣️ "A topic is stored as partition directories on each broker that holds a
replica. Each partition is a sequence of segment files - Kafka writes to the
active segment and rolls to a new file when the segment reaches a size or
time limit. When you increase partition count, existing records stay in their
original partitions. New records distribute across all partitions including
new ones, which breaks per-key ordering guarantees for keys that had records
in the old partitions."

#### Comparison
- "When would you use one topic per event type vs a single topic with all events?"
- "What is the difference between topic deletion and topic compaction?"

🗣️ "One topic per event type is cleaner for access control and independent
retention policies - orders can be kept 30 days, logs only 1 day. A single
topic with all events reduces the number of topics to manage but forces
consumers to filter. I default to one topic per logical event type. Topic
deletion removes records after a time or size threshold - right for event
logs. Log compaction keeps only the latest record per key - right for state
projections like a user profile or inventory count."

#### Scenario
- "How would you design topics for an order processing system?"
- "A topic has 2 partitions and you need 6 consumers in parallel. What do you do?"

🗣️ "For order processing, I would use separate topics per event type:
order-placed, order-paid, order-shipped. Each topic keyed by order ID
ensures per-order ordering. I would start with 12-24 partitions to allow
future scaling. For the 2-partition vs 6-consumer problem, I increase the
partition count to at least 6. For ordering-sensitive cases, the safer
approach is a new topic with the right partition count, backfill from the
old topic, then switch producers - this avoids the transient ordering break
that comes from in-place partition increases."

#### Debugging
- "Consumer lag is growing on one partition but not others. What is wrong?"
- "A topic is taking much more disk than expected. What do you check?"

🗣️ "Growing lag on one partition usually means a hot partition - one partition
receives disproportionately more data because the key is skewed. I check
partition sizes with kafka-log-dirs.sh and confirm the write distribution.
The fix is a custom partitioner or adding randomization to the partition key.
For unexpected disk usage, I check retention.ms and retention.bytes
configuration - without explicit limits, Kafka uses broker defaults which may
be long. I also check if log compaction is enabled but the compaction cycle
is falling behind, causing temporary disk bloat."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with partition mechanics and per-key ordering guarantees |
| Hiring Manager | Lead with organizational benefit - topics as team contracts |
| Bar Raiser | Lead with partition count decision and operational risks |
| Peer Engineer | Collaborative - "The partition count decision is one I wish could be changed painlessly after the fact..." |

---

---

# Partition

---
id: KFK-005
title: Partition
category: Kafka
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #kafka, #partition, #parallelism, #ordering, #offset
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical — partition mechanics are foundational to
understanding Kafka throughput, ordering guarantees, and consumer parallelism.

---

### 🎯 Model Answer

**30 seconds:**
> A Kafka partition is an ordered, immutable sequence of records - the physical
> unit of storage and parallelism. A topic is divided into partitions so multiple
> producers can write and multiple consumers can read in parallel. Records within
> a partition are strictly ordered by offset; records across partitions have no
> ordering guarantee. The partition count sets the maximum degree of consumer
> parallelism.

**3 minutes (Senior):**
> A partition is both a unit of storage and a unit of parallelism. Each is an
> ordered log - records are appended sequentially and assigned a monotonically
> increasing offset that permanently identifies their position. Records within
> a partition are totally ordered: if record A was written before record B in
> the same partition, all consumers see A before B. Across partitions, there is
> no ordering - if you need globally ordered events, you must use a single
> partition, sacrificing all parallelism. The partition count determines the
> maximum number of consumers in a single group that can process data in parallel
> - if a topic has 6 partitions and a consumer group has 10 members, 4 will be
> idle because each partition can only be assigned to one consumer at a time.
> Physically, a partition is stored as a directory of segment files. The active
> segment receives all writes; older segments are candidates for deletion or
> compaction based on the topic's retention policy.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* At senior level, discuss partition assignment algorithms
(range vs round-robin vs sticky), the ISR set, and the impact of partition
count on leader election time and replication cost.

*Adapting down:* "A partition is like a lane on a highway - more lanes means
more parallel traffic, but each car in a lane is ordered."

**Blank Mind Recovery:**

**(1) Restate:** "So you are asking about Kafka partitions - let me think
through what problem they solve."

**(2) First principles:** "A single ordered log cannot scale beyond one writer.
Partitioning is the standard solution: split the log into shards, distribute
across servers, and process each shard independently."

**(3) Bridge:** "This reminds me of database table sharding - you split a
table across multiple servers for scale. A partition is Kafka's equivalent
of a database shard."

---

### 📘 Concept Explanation

**What it is:**
A partition is an ordered, append-only, immutable sequence of records that
is the physical storage and parallelism unit of a Kafka topic.

**The problem it solves:**
A single sequential log cannot handle millions of writes per second on one
machine. Partitioning splits the log into independent shards distributed
across brokers, allowing parallel writes and parallel reads.

**How it works:**

```
Topic "orders" - 3 partitions

Partition 0 (Broker 1 leader, Broker 2 follower):
offset: [0]A [1]D [2]G [3]J  <- append newest here

Partition 1 (Broker 2 leader, Broker 3 follower):
offset: [0]B [1]E [2]H  <- append newest here

Partition 2 (Broker 3 leader, Broker 1 follower):
offset: [0]C [1]F [2]I  <- append newest here

ROUTING:
  key="order-123" -> hash(key) % 3 = always same partition
  key=null        -> round-robin across all partitions
```

1. Producer sends a record with a key (e.g., order ID).
2. Partition selected: `hash(key) % numPartitions` (default partitioner).
3. Record appended to the active segment of that partition.
4. Sequential offset assigned.
5. Follower replicas fetch and replicate asynchronously.
6. Consumers poll their assigned partition in offset order.

**The key insight:**
Per-partition ordering is the unit of ordering guarantee. All records with
the same key go to the same partition, so per-key ordering is guaranteed
even across multiple producer threads. Cross-partition ordering requires
application-level sequencing because Kafka does not provide it.

**When to use many partitions:**
- High throughput requirements (more = more parallelism)
- Large consumer group needing many parallel members
- Data naturally sharded by key without hot-partition risk

**When to limit partitions:**
- Ordering across ALL records is required (use 1 partition)
- Broker has limited file handle capacity
- Topic count is already high (many partitions * many topics = overhead)

**Alternatives:**
- Single partition → total ordering, 0 parallelism
- Hash of key → default, good for key-affinity
- Custom partitioner → when default hash creates hot keys

**First-principles derivation:**
Given the constraint that a single sequential log is a throughput bottleneck,
partition by a hash of the record key. Records with the same key go to the
same shard, preserving per-entity ordering. Records with different keys go
to different shards, processing in parallel. Partition count is the degree
of parallelism - more partitions = higher max throughput but higher metadata
overhead per broker.

---

### 💻 Code Example

**Example 1: How key determines partition**

```java
// Default partitioner: partition = murmur2(key) % numPartitions
// Same key ALWAYS goes to same partition -> per-key ordering

ProducerRecord<String, String> record1 =
    new ProducerRecord<>("orders", "customer-42", "{...}");
// customer-42 -> always same partition
// all events for customer-42 are in total order

ProducerRecord<String, String> record2 =
    new ProducerRecord<>("orders", null, "{...}");
// null key -> round-robin (sticky batch partitioner in newer clients)
// no ordering guarantee relative to other null-key records
```

> **Code walkthrough:** Key selection drives partition affinity. Using a
> business entity ID (customer ID, order ID) as the key means all events
> for that entity are co-located in one partition and delivered in order.
> A null key distributes load evenly but sacrifices any ordering guarantee.
> This is a critical design decision - choose based on whether consumers
> need per-entity sequential processing.

**Example 2: Hot partition avoidance (BAD vs GOOD)**

```java
// BAD: key="VIP" sends all VIP orders to one partition
// -> hot partition, one consumer handles all VIP load
ProducerRecord<String, String> bad =
    new ProducerRecord<>("orders", "VIP", bigOrderPayload);

// GOOD: combine key with suffix to distribute load
// Only use when per-VIP ordering is not required
String balancedKey = "VIP-" + (System.currentTimeMillis() % 3);
ProducerRecord<String, String> good =
    new ProducerRecord<>("orders", balancedKey, bigOrderPayload);
// Distributes VIP orders across 3 partitions
// Trade-off: breaks total per-VIP ordering
```

> **Code walkthrough:** The BAD pattern uses a low-cardinality key ("VIP")
> that maps all high-volume traffic to one partition. That partition's leader
> becomes the bottleneck - no amount of consumer scaling helps because there
> is only one partition to assign. The GOOD pattern adds a modular suffix to
> distribute the load, at the cost of losing per-VIP ordering. Use this only
> when ordering is genuinely not required for the hot key.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A partition is the physical storage unit of a Kafka topic - an ordered,
> immutable log of records. Each record gets a sequential offset. Records with
> the same key go to the same partition, ensuring per-key ordering. More
> partitions means more consumers can read in parallel.

*Push deeper:* Explain that consumer group parallelism is bounded by partition
count - if you have more consumers than partitions, some consumers are idle.

---

**Senior / Staff (5+ years):**
> A partition is both the unit of ordering and the unit of parallelism. Within
> a partition, records are totally ordered by offset. Across partitions, there
> is no ordering guarantee. The partition count sets the ceiling on consumer
> group parallelism. The partition decision I watch most carefully is key design
> - a key with high cardinality and even distribution prevents hot partitions.
> A key with low cardinality (like a boolean or a status with few values) will
> concentrate traffic on one or two partitions, creating a performance bottleneck
> no amount of consumer scaling can fix.

*Push deeper:* At staff level, discuss the ISR set and how it interacts with
partition leadership for durability guarantees, and the replication lag
implications for consumer visibility under heavy write load.

---

### ⚠️ Common Misconceptions

**Misconception 1: More partitions always means better throughput.**

Partitions improve throughput by enabling parallel consumption - but only up to the consumer group size and broker capacity. Each partition adds overhead: a file descriptor pair on each broker replica, 50 bytes of metadata on every client connected to the cluster, and one goroutine/thread per consumer assigned to the partition. Beyond 1,000-4,000 partitions per broker, Kafka's own metadata management becomes the bottleneck: leader election after a broker failure can take tens of seconds when thousands of partitions need new leaders. Target 1 partition per 10 MB/s of required throughput, not more.

**Misconception 2: Increasing partition count redistributes existing messages to the new partitions.**

Adding partitions to an existing topic affects ONLY new messages. Existing messages remain in their original partitions and are never moved. For producers using key-based partitioning: after increasing partition count, the same key will be routed to a DIFFERENT partition (because the hash modulo changes), breaking the ordering guarantee for that key - new messages and old messages for the same key are now in different partitions. Plan partition count at topic creation time; consider increasing it only during low-traffic windows with consumer-side idempotency.

**Misconception 3: Consumers can read from any replica, not just the leader.**

Before Kafka 2.4, ALL reads went to the partition leader, even if a follower replica was on the same rack or AZ. Followers only replicated - they never served reads. Kafka 2.4+ added follower reads via the `RackAwareReplicaSelector` - a client can read from the nearest replica in the same AZ, reducing cross-AZ data transfer costs. This must be explicitly enabled: `client.rack` must be set on each consumer and `replica.selector.class=org.apache.kafka.common.replica.RackAwareReplicaSelector` on brokers.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Too many partitions causes slow leader election after broker failure.**

Symptom: after a broker fails, recovery takes minutes rather than seconds; all partitions with their leader on the failed broker are unavailable during that window; producer errors spike and consumer lag grows. Diagnosis: check total partition count: `kafka-topics --list | wc -l` combined with `kafka-topics --describe`; if the cluster has >4,000 partitions per broker, leader election after failure becomes slow; check the controller election duration metric `kafka.controller:type=KafkaController,name=ActiveControllerCount`. Fix: keep partition count at or below 1,000-4,000 per broker; use KRaft mode which improves metadata management at scale; if many partitions are from old/unused topics, delete them; reduce replication factor for low-priority topics to decrease leader election work.

**Failure Mode 2: Key-based partitioning with a skewed key space overloads one partition.**

Symptom: one partition accumulates far more messages than others - a "hot partition"; the consumer instance assigned to that partition is the throughput bottleneck; other consumers in the group are idle. Diagnosis: check per-partition message rate: `kafka-log-dirs --describe --topic <topic>`; compare partition sizes; identify whether a high-volume key dominates the key space (e.g., messages keyed by country and 80% are from one country). Fix: add a random suffix or salt to the partition key for hot keys; use a custom partitioner that explicitly routes hot keys across multiple target partitions; split the topic by region with a separate topic per high-volume key value.

**Failure Mode 3: Consumer group with more instances than partitions wastes resources.**

Symptom: a consumer fleet has 20 instances but the topic has 10 partitions; 10 consumers are permanently idle and assigned no partitions; resource cost doubles with no throughput benefit. Diagnosis: `kafka-consumer-groups --describe --group <group>` shows some consumer instances with no PARTITION assignments; the CONSUMER-ID column shows idle instances. Fix: scale consumer instances to match partition count or a multiple thereof; to increase throughput beyond partition count, increase the partition count itself; add automation that sets consumer replica count to `min(desired_consumers, partition_count)`.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is a Kafka partition?"
- "Why does Kafka partition topics?"

🗣️ "A partition is an ordered, immutable log - the physical storage and
parallelism unit of a Kafka topic. Topics are partitioned to allow parallel
writes from multiple producers and parallel reads by multiple consumers.
Each partition is an independent log with its own offset sequence."

#### Mechanism
- "How does Kafka determine which partition a record goes to?"
- "What happens if you have more consumer instances than partitions?"

🗣️ "The default partitioner hashes the record key using murmur2 and takes
the result modulo the partition count. Same key always maps to the same
partition, guaranteeing per-key ordering. Records with a null key are
distributed round-robin. If you have more consumer instances in a group than
partitions, the excess consumers are idle - Kafka assigns at most one consumer
per partition within a group."

#### Comparison
- "What is the difference between partition count and replication factor?"
- "When would you use a single-partition topic?"

🗣️ "Partition count controls parallelism - how many consumers can process in
parallel. Replication factor controls durability - how many copies exist across
brokers. They are independent: 6 partitions with RF=1 is high parallelism but
no durability; 1 partition with RF=3 is no parallelism but high durability.
I use a single-partition topic only when total ordering across all records is
required - for example, a global sequence of configuration changes where every
consumer must apply them in exact order."

#### Scenario
- "A topic gets 1M records/sec but consumers are falling behind. How do you scale?"
- "You need per-user ordering guarantees. How do you design the partitioning?"

🗣️ "To scale consumers for a high-throughput topic, first check partition
count. If it has 6 partitions, adding more than 6 consumer instances gives no
benefit. I increase partition count first, then add consumer instances. For
per-user ordering, I key all events by user ID - the default partitioner
ensures all events for the same user go to the same partition, and within a
partition, records are always processed in offset order. Hot users generating
many events may create hot partitions - I monitor partition size distribution
and add a secondary randomization suffix if needed."

#### Debugging
- "How do you detect a hot partition?"
- "Partition lag is uneven across partitions in a consumer group. What do you investigate?"

🗣️ "To detect a hot partition, I compare partition sizes using kafka-log-dirs.sh
--describe --bootstrap-server localhost:9092. If one partition is significantly
larger, it is receiving more records. I also check JMX MessagesInPerSec broken
down by partition. For uneven consumer lag: I check whether processing time per
record varies (some records may be heavier), whether the consumer assigned to
the lagging partition has lower CPU or memory, or whether it is receiving
disproportionately more records. Consumer thread dumps help identify if
processing is blocked on a downstream call."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with offset semantics and per-key ordering guarantee |
| Hiring Manager | Lead with parallelism - how partition count affects consumer scale |
| Bar Raiser | Lead with hot partition risk and key design considerations |
| Peer Engineer | Collaborative - "The hot partition problem caught us when one customer generated 90% of traffic..." |

---

---

# Broker

---
id: KFK-006
title: Broker
category: Kafka
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: all
tags: #kafka, #broker, #cluster, #replication, #leader, #ISR
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High — broker mechanics verify that candidates
understand how Kafka stores data, replicates it, and handles failures.

---

### 🎯 Model Answer

**30 seconds:**
> A Kafka broker is a server that stores topic partitions and serves producer
> and consumer requests. Each partition has one leader broker that handles all
> reads and writes, and one or more follower brokers that replicate the data
> for durability. A Kafka cluster is a group of brokers coordinated by
> ZooKeeper or KRaft.

**3 minutes (Senior):**
> A broker is the core server process in a Kafka cluster. Each broker holds
> some partitions on disk - distributed by the partition assignment algorithm
> to balance load. For each partition, exactly one broker is the leader and
> all others holding replicas are followers. All producer writes and consumer
> reads go through the leader. Followers fetch from the leader asynchronously
> to stay in sync. The in-sync replica (ISR) set is the set of replicas that
> are caught up within replica.lag.time.max.ms. If the leader fails, the
> controller elects a new leader from the ISR - fast in KRaft mode, typically
> under a second. Brokers expose metrics via JMX: UnderReplicatedPartitions
> is the most critical - a non-zero value means some replicas are falling
> behind, which is an early warning of replication trouble before a failure
> causes data loss or availability impact.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* At senior level, discuss broker configuration for throughput
(num.network.threads, num.io.threads), the impact of too many partitions per
broker, and the difference between controller and follower broker roles.

*Adapting down:* "A broker is like a server in a distributed database - it
holds some of the data and handles requests for that data."

**Blank Mind Recovery:**

**(1) Restate:** "So you are asking about Kafka brokers - let me think through
what role they play."

**(2) First principles:** "A distributed system needs servers to store data.
Kafka's server unit is the broker. For failures, data is replicated across
multiple brokers with a leader-follower model."

**(3) Bridge:** "This reminds me of a database replica set - one primary handles
writes, secondaries replicate and take over if the primary fails. A Kafka broker
is the same pattern applied to partitions."

---

### 📘 Concept Explanation

**What it is:**
A Kafka broker is a JVM process that stores topic partition data, handles
producer write requests, and serves consumer fetch requests within a cluster.

**The problem it solves:**
A single server cannot store all events reliably or handle full load. The
broker model allows data to be distributed and replicated across multiple
machines for scale and fault tolerance.

**How it works:**

```
Kafka Cluster (3 brokers)

Broker 1              Broker 2              Broker 3
orders-P0 [L]         orders-P1 [L]         orders-P2 [L]
orders-P1 [F]         orders-P2 [F]         orders-P0 [F]
payments-P0 [L]       payments-P1 [L]       payments-P0 [F]

L=Leader  F=Follower
Leader handles ALL reads and writes for its partition
Followers replicate from leader continuously
ISR = set of replicas within replica.lag.time.max.ms
```

1. **Partition assignment:** When a topic is created, Kafka distributes
   partition leaders across brokers evenly to balance load.
2. **Leader/follower:** Each partition has one leader. All producer writes
   and consumer reads go through the leader. Followers replicate asynchronously.
3. **ISR:** In-Sync Replicas - those within the configured lag threshold.
   Only ISR members are eligible for leader election.
4. **Controller broker:** One broker is the controller (manages partition
   leadership, broker joins/leaves). In KRaft mode this uses embedded Raft.
5. **Fetch protocol:** Consumers issue FetchRequest specifying offset and
   max bytes. Broker returns available records from the partition log.

**The key insight:**
All traffic for a partition flows through one broker (the leader). If partition
leaders concentrate on one broker (after restarts or failures), that broker
becomes the hot spot. Kafka's preferred leader election mechanism rebalances
leaders - run kafka-leader-election.sh to trigger rebalancing.

**When to add brokers:**
- Disk filling up and you cannot reduce retention
- Network throughput saturated on existing brokers
- Replication overhead too high on a small cluster
- You want to increase replication factor for more durability

**When NOT to add brokers first:**
- Consumer lag can be fixed by increasing partitions + consumer instances
- Throughput issues may be in consumer code, not the broker
- Under-replicated partitions may be a network issue, not capacity

**Alternatives:**
- Self-managed Kafka cluster → full control, high operational overhead
- Confluent Cloud → managed Kafka, less ops, higher cost
- Amazon MSK → managed Kafka on AWS, good AWS integration
- Redpanda → Kafka-compatible, C++, lower latency and resource use

**First-principles derivation:**
Given N partitions that together exceed one machine's capacity, distribute
across K brokers so each holds N/K partitions. For fault tolerance, replicate
each partition to RF-1 additional brokers. The leader handles all traffic and
followers replicate asynchronously within the ISR threshold. This is the
standard primary-replica model adapted for partitioned, append-only logs.

---

### 💻 Code Example

**Example 1: Checking broker health and partition distribution**

```bash
# Check which broker is leader for each partition
kafka-topics.sh --describe --topic orders \
  --bootstrap-server localhost:9092
# Output: Leader column shows broker ID for each partition

# CRITICAL metric: under-replicated partitions (URP)
# Any non-zero count = replication problem, cluster at risk
kafka-topics.sh --describe \
  --under-replicated-partitions \
  --bootstrap-server localhost:9092
```

> **Code walkthrough:** `--describe` reveals the partition distribution and
> leader/follower assignments. The `--under-replicated-partitions` flag is the
> most important health check - any result here means some replicas are falling
> behind the leader. If the leader fails while replicas are behind, the cluster
> must choose between availability (elect an out-of-sync follower, risk data
> loss) or consistency (wait for a replica to catch up, reduce availability).
> Monitor this metric continuously in production.

**Example 2: Rebalancing partition leaders after a restart**

```bash
# After a broker restart, leaders may concentrate unevenly
# Check current leader distribution
kafka-topics.sh --describe --topic orders \
  --bootstrap-server localhost:9092 | \
  grep "Leader:" | sort | uniq -c

# Trigger preferred leader election to rebalance
kafka-leader-election.sh \
  --bootstrap-server localhost:9092 \
  --election-type PREFERRED \
  --all-topic-partitions
# Reassigns leaders to their preferred broker without moving data
```

> **Code walkthrough:** After broker restarts or failures, partition leaders
> can concentrate on fewer brokers - one broker ends up handling far more
> traffic than others. The preferred leader election reassigns each partition's
> leader back to its designated "preferred" broker (the first in the replica
> list) without any data movement. This is a zero-downtime rebalancing
> operation that should run automatically but can be triggered manually
> after maintenance events.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A Kafka broker is a server in the cluster that stores partitions and handles
> reads and writes. Each partition has one leader broker that processes all
> traffic and follower brokers that replicate the data for durability. A cluster
> typically has 3+ brokers so if one fails, the others continue serving.

*Push deeper:* Explain the ISR set - in-sync replicas that are eligible for
leader election if the current leader fails.

---

**Senior / Staff (5+ years):**
> A broker stores partition segments on disk and processes producer and consumer
> requests. The leader-follower model routes all traffic for a partition through
> one broker - intentional to avoid consistency complexity of allowing followers
> to serve reads. The ISR is the health indicator: any broker within
> replica.lag.time.max.ms is in ISR; the rest are out of sync. The acks=all
> producer setting combined with min.insync.replicas=2 ensures a record is
> acknowledged only after 2 ISR members write it, providing durability against
> a single broker failure. The metric I watch most is UnderReplicatedPartitions
> - any non-zero value means replication is lagging and the cluster is at risk.

*Push deeper:* Discuss rack-awareness - configuring broker.rack to spread
replicas across physical racks or availability zones, ensuring a single rack
failure does not take out all replicas of any partition.

---

### ⚠️ Common Misconceptions

**Misconception 1: A Kafka broker is just a message server that stores messages.**

A Kafka broker serves multiple simultaneous roles: partition leader (serving all reads and writes for its leader partitions), follower replica coordinator (replicating data from other brokers), group coordinator (managing consumer group membership and offset commits for groups assigned to it), and transaction coordinator (for exactly-once semantics). One broker in the cluster holds the controller role (elected via ZooKeeper or KRaft), managing cluster metadata: broker registration, topic/partition state, and leader election. Broker failure thus impacts multiple system functions simultaneously.

**Misconception 2: ZooKeeper is required to run a Kafka cluster.**

ZooKeeper was Kafka's external dependency for metadata management until Kafka 2.8 (preview) and 3.3 (production-ready KRaft). KRaft mode moves leader election and metadata management into Kafka itself via a Raft consensus protocol among a dedicated set of controller brokers. New Kafka deployments should use KRaft mode; ZooKeeper mode is deprecated and will be removed in Kafka 4.0. Existing ZooKeeper-based clusters should plan migration using the KIP-833 rolling upgrade process.

**Misconception 3: Kafka replication is equivalent to a backup.**

Replication provides HIGH AVAILABILITY: if a broker fails, another broker with a replica copy takes over as leader. It does NOT provide data protection against application-level errors: if a producer accidentally deletes a topic, corrupts messages with wrong serialization, or produces malformed data, replication propagates the error to all replicas immediately. True backup requires: Kafka log segment archival to cold storage (Confluent Tiered Storage, Kafka Connect S3 Sink with segment-level export) for recovery beyond the retention window and for disaster recovery after data corruption events.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Broker disk full halts all partition writes on that broker.**

Symptom: producers receive `KafkaStorageException` for partitions on the full broker; consumer lag grows for those partitions; `df -h` on the broker shows 100% disk utilization. Diagnosis: check disk usage per broker: `df -h /var/lib/kafka`; check which topics are consuming the most space: `kafka-log-dirs --describe --bootstrap-server localhost:9092 | grep -E 'size|topic'`; identify topics with large retention settings or high write rates. Fix: immediately clean up old segments by reducing `retention.bytes` temporarily; delete unused topics; expand disk capacity (add volumes, migrate to larger instance type); set disk usage alerts at 70% and 85% to prevent recurrence; consider Tiered Storage for large topics.

**Failure Mode 2: Controller failover causes a brief window of unavailability during which producers block.**

Symptom: during a rolling broker upgrade, producer latency spikes to 30-90 seconds when the controller broker is restarted; clients cannot get updated metadata during controller election. Diagnosis: check controller broker identity: `kafka-topics --describe` will show `Leader: none` for partitions during election; check Kafka logs for `[Controller id=N] Resigned` and `[Controller id=M] Elected` messages; monitor `kafka.controller:type=KafkaController,name=ActiveControllerCount`. Fix: use KRaft mode with dedicated controller nodes to reduce controller failover impact; ensure controller broker restarts happen last in rolling upgrades; pre-warm client metadata by increasing `metadata.max.age.ms` so clients do not request metadata during the brief controller election window.

**Failure Mode 3: Unclean leader election causes data loss when `min.insync.replicas` is too low.**

Symptom: after a two-broker failure in a three-broker cluster, Kafka elects an out-of-sync replica as leader; producers had been using `acks=all` but data written after the ISR shrank to 1 is now present on the remaining broker only; after the failed broker elected as leader, those writes are missing. Diagnosis: check `unclean.leader.election.enable` setting (default false in Kafka 3.0+); check ISR history in Kafka controller logs; review `LogStartOffset` vs expected offset to quantify data loss. Fix: set `unclean.leader.election.enable=false` on critical topics to prevent data loss at the cost of availability; use `replication.factor=3` with `min.insync.replicas=2` to tolerate one broker failure safely; alert when ISR < replication factor for any partition as an early warning.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is a Kafka broker?"
- "What is the difference between a broker, a topic, and a partition?"

🗣️ "A Kafka broker is the server process that stores partition data and handles
requests. A topic is the logical name for a stream of related events. A partition
is the physical storage unit - each topic is split into partitions distributed
across brokers. The broker is the machine; the partition is the data unit it
stores."

#### Mechanism
- "How does Kafka handle a broker failure?"
- "What is the ISR set and why does it matter?"

🗣️ "When a broker fails, the controller detects it through a missed heartbeat
and triggers leader election for all partitions that had their leader on the
failed broker. The new leader is elected from the ISR - in-sync replicas caught
up within the configured lag. In KRaft mode this is typically under a second.
If no ISR member is available, Kafka must choose: wait for consistency or elect
an out-of-sync replica and risk data loss (unclean leader election). The ISR
matters because it determines the available pool of safe leaders - a shrinking
ISR is an early warning that replication is degraded."

#### Comparison
- "How does a Kafka broker differ from a Kafka controller?"
- "What is the difference between self-managed Kafka and Confluent Cloud MSK?"

🗣️ "Every broker stores data and handles requests. The controller is a special
role - one broker manages cluster-level metadata: partition leadership, broker
registration, and topic changes. In ZooKeeper mode, the controller was elected
via ZooKeeper. In KRaft mode, the controller nodes run the Raft consensus
protocol and can be dedicated or combined with broker role. Self-managed Kafka
gives full configuration control but requires operational expertise for upgrades,
scaling, and failure handling. Confluent Cloud eliminates that overhead at the
cost of higher per-unit pricing."

#### Scenario
- "A broker is receiving much more traffic than others. How do you fix it?"
- "You want to add a new broker to an existing cluster. What steps do you take?"

🗣️ "Uneven broker traffic usually means partition leaders are concentrated on
one broker. I run kafka-leader-election.sh with PREFERRED type to rebalance
leaders. If the imbalance is data volume rather than request count, I use
kafka-reassign-partitions.sh to move partitions to the underloaded broker.
Adding a new broker: Kafka does NOT automatically move existing partitions to it.
I generate a reassignment plan with kafka-reassign-partitions.sh, execute it,
and verify replication lag drops to zero before considering the migration
complete - data movement is network and disk intensive and can impact
production throughput."

#### Debugging
- "A broker is showing high CPU. What do you check?"
- "Why would a broker have UnderReplicatedPartitions > 0?"

🗣️ "High broker CPU typically comes from: network thread saturation (many small
messages from many clients), replication overhead (a broker behind on replication),
or excessive partition count. I check JMX: NetworkProcessorAvgIdlePercent below
30% signals network thread saturation. For UnderReplicatedPartitions: common
causes are a broker that recently restarted and is catching up, network issues
between brokers, or a slow disk that cannot keep up with replication. I run
kafka-topics.sh --describe --under-replicated-partitions to see which partitions
are affected and which replicas are out of sync, then correlate with broker logs
for the root cause."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with leader/follower model and ISR semantics |
| Hiring Manager | Lead with operational implications - broker sizing, cloud vs self-managed |
| Bar Raiser | Lead with failure modes - what happens when ISR shrinks below min.insync.replicas |
| Peer Engineer | Collaborative - "The UnderReplicatedPartitions metric saved us from a data loss incident when..." |
