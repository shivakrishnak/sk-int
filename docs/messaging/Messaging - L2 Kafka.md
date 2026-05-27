---
layout: default
title: "Messaging - L2 Kafka"
parent: "Messaging and Event-Driven"
grand_parent: "SK Interview"
nav_order: 3
permalink: /messaging/l2-kafka/
---

# Kafka Producers and Consumer API

🎯 Interview Weight: very high - Kafka producer/consumer API
is the day-to-day working knowledge for Java backend engineers.

---

### 🎯 Model Answer

**30 seconds:**
> Kafka producer sends messages to topics, selecting partitions
> by key hash or round-robin. Key settings: `acks`, `retries`,
> `enable.idempotence`, `linger.ms`, `batch.size`. Consumer
> polls in a loop, processes messages, commits offsets. Key
> settings: `group.id`, `auto.offset.reset`, `max.poll.records`,
> `enable.auto.commit`. Spring Kafka wraps both in `KafkaTemplate`
> and `@KafkaListener`.

**3 minutes (Senior):**
> Producer internals:
>
> Partitioner: which partition does this message go to?
> Default: hash(key) % numPartitions. Same key -> same partition
> (preserves ordering for a given entity).
> Null key: round-robin across partitions.
>
> Batching and compression:
> Producer accumulates messages in a batch for `linger.ms`
> milliseconds (default 0 = send immediately).
> Once batch is full (`batch.size`) or `linger.ms` elapses: send.
> Compression: snappy/gzip/lz4/zstd. Reduces network bandwidth.
> Tradeoff: latency (linger.ms) vs throughput (batching).
>
> Producer reliability settings:
> `acks=0`: fire and forget. No acknowledgment. Fastest.
> Possible data loss.
> `acks=1`: leader acks. Message can be lost if leader
> fails before replication.
> `acks=all` (`acks=-1`): all ISR replicas ack. Strongest
> durability. Slightly higher latency.
> `enable.idempotence=true`: requires `acks=all`. Prevents
> duplicate messages during retry (broker assigns sequence
> numbers per producer, deduplicates on receipt).
>
> Consumer internals:
> `poll()`: fetches up to `max.poll.records` from assigned
> partitions. Returns immediately if no records.
> `max.poll.interval.ms`: if consumer doesn't poll within
> this interval, it's considered dead. Triggers rebalance.
> Default: 5 minutes. If processing takes longer than 5 min:
> rebalance kicks in mid-processing (duplicate processing).
>
> Offset commit strategies:
> `enable.auto.commit=true`: commits every `auto.commit.interval.ms`.
> Risk: commits before processing completes if commit interval
> fires during processing.
> `enable.auto.commit=false`: manual commit.
> `consumer.commitSync()`: blocks until committed.
> `consumer.commitAsync()`: non-blocking.
> Best: `commitSync()` after processing all records in a poll batch.

**Blank Mind Recovery:**

**(1) Restate:** "Producer: key -> partition, batch + acks.
Consumer: poll loop, manual commit after processing."

---

### 💻 Code Example

```java
// Spring Kafka - @KafkaListener with manual offset commit

@Component
public class OrderConsumer {

    @KafkaListener(
        topics = "orders",
        groupId = "payment-service",
        containerFactory = "kafkaListenerContainerFactory"
    )
    public void processOrder(
        ConsumerRecord<String, Order> record,
        Acknowledgment ack
    ) {
        try {
            log.info("Processing order {} from partition {} offset {}",
                record.value().getId(),
                record.partition(),
                record.offset()
            );

            paymentService.process(record.value());

            // Ack ONLY after successful processing
            ack.acknowledge();

        } catch (RecoverableException e) {
            // Do NOT ack - message will be redelivered
            log.warn("Recoverable error, will retry: {}",
                e.getMessage());
        } catch (PoisonMessageException e) {
            // Ack to prevent infinite loop - send to DLQ
            dlqService.send(record);
            ack.acknowledge();
        }
    }
}
```

```yaml
# application.yaml - Kafka consumer configuration
spring:
  kafka:
    consumer:
      group-id: payment-service
      auto-offset-reset: earliest
      enable-auto-commit: false   # manual commit via Acknowledgment
      max-poll-records: 100       # batch size per poll
      properties:
        max.poll.interval.ms: 300000  # 5 min processing budget
    listener:
      ack-mode: MANUAL_IMMEDIATE   # Acknowledgment.acknowledge()
      concurrency: 3               # 3 threads, 3 partitions
```

> **Code walkthrough:** The `@KafkaListener` receives a
> `ConsumerRecord` (access to offset, partition, headers) and
> an `Acknowledgment` for manual commit control. The consumer
> only calls `ack.acknowledge()` after successful processing -
> guaranteeing at-least-once delivery. For recoverable errors
> (transient DB failure): not acknowledging causes Kafka to
> redeliver after `max.poll.interval.ms`. For poison messages
> (always fail): sends to DLQ and acks to prevent the consumer
> from being stuck on one message.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | Consumer poll loop + offset commit modes |
| Senior | 8 min | Producer acks + idempotence + max.poll.interval.ms |
| Staff | 12 min | Rebalance impact + cooperative rebalancing |

---

---

# Kafka Topics Partitions and Offsets

🎯 Interview Weight: very high - Partitions are the unit of
Kafka parallelism and ordering. Core concept.

---

### 🎯 Model Answer

**30 seconds:**
> A Kafka topic is divided into partitions. Partitions are the
> unit of parallelism: N partitions = N consumers can process
> in parallel. Each message in a partition has an incrementing
> offset. Ordering is guaranteed within a partition but NOT
> across partitions. A message key determines the partition
> (hash). Same key always goes to the same partition - guarantees
> ordering for all events of a given entity (e.g., order ID).

**3 minutes (Senior):**
> Partition design decisions:
>
> How many partitions?
> Rule: partitions >= desired consumer parallelism.
> Too few: cannot scale (3 partitions = max 3 consumers in a group).
> Too many: overhead (leader election, replication, metadata).
> Common: 12-48 partitions for moderate-throughput topics.
> Changing partitions after creation: possible but breaks key-based
> partitioning (same key may now go to a different partition).
>
> Key selection strategy:
> Purpose: group related messages in the same partition.
> Good key: entity ID (user_id, order_id). All events for
> the same order arrive to the same consumer in order.
> Bad key: static value (e.g., service name) - all messages
> go to one partition, no parallelism.
> Bad key: highly unique value (UUID) - even distribution but
> no ordering guarantee (different partitions for related events).
>
> Offset semantics:
> Each partition is an independent, append-only log.
> Offset: unique per partition (not globally unique).
> Consumer stores offset per partition: {topic, partition, offset}.
> On restart: consumer seeks to stored offset and resumes.
> Replaying: set offset to 0 or to a specific timestamp.
>
> Log retention and compaction:
> Time-based: delete records older than 7 days.
> Size-based: delete oldest records when topic exceeds N GB.
> Compacted: keep only the latest value per key.
> Tombstone: `null` value for a key = delete this key from
> compacted log. Used for event sourcing state snapshots.

**Blank Mind Recovery:**

**(1) Restate:** "Partitions = parallelism units. Key = partition selector.
Offset = position. Same key = same partition = ordered."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Partition model + key selection |
| Senior | 7 min | Partition count decision + compaction + replay |

---

---

# Consumer Groups and Rebalancing

🎯 Interview Weight: very high - Consumer group rebalancing is
the source of most Kafka performance issues in production.

---

### 🎯 Model Answer

**30 seconds:**
> A consumer group is a set of consumers that collectively consume
> a topic. Each partition is assigned to exactly one consumer
> in the group at a time. If a consumer joins or leaves,
> partitions are redistributed - this is a rebalance. During a
> rebalance: all consumers in the group stop consuming (stop-the-world
> pause). Rebalance causes consumer lag and processing delays.
> Minimize rebalances: stable consumer count, fast processing,
> cooperative rebalancing (K8s rolling updates).

**3 minutes (Senior):**
> Consumer group mechanics:
>
> Group Coordinator: a Kafka broker that manages group membership.
> Consumer heartbeats to coordinator every `heartbeat.interval.ms`
> (default 3s). If coordinator doesn't receive heartbeat within
> `session.timeout.ms` (default 10s): consumer declared dead,
> rebalance triggered.
>
> Rebalance triggers:
> - Consumer joins the group (pod start).
> - Consumer leaves the group (pod stop, SIGTERM).
> - Consumer is considered dead (session timeout, max.poll.interval exceeded).
> - Topic partition count changes.
>
> Eager rebalancing (default pre-Kafka 2.4):
> ALL consumers stop, revoke ALL partitions, then reassign from scratch.
> Duration: all partitions un-assigned for 2-10 seconds.
> Kafka lag grows during this window.
>
> Cooperative rebalancing (Kafka 2.4+):
> Only the partitions that need to be moved are revoked.
> Other partitions continue processing without interruption.
> Set: `partition.assignment.strategy=CooperativeStickyAssignor`
> Enables zero-downtime rolling restarts (Kubernetes).
>
> max.poll.interval.ms pitfall:
> Consumer must call `poll()` within `max.poll.interval.ms`
> (default 5 minutes). If processing one batch takes 6 minutes:
> consumer is ejected from the group. Rebalance. The in-progress
> batch is reprocessed by the new consumer.
> Fix: reduce batch size (`max.poll.records`) or increase
> `max.poll.interval.ms` or move heavy processing to async threads.

**Blank Mind Recovery:**

**(1) Restate:** "Consumer group = shared partition ownership.
Rebalance = redistribution on membership change = processing pause."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Consumer group model + partition assignment |
| Senior | 8 min | Rebalance causes + cooperative rebalancing + max.poll.interval |
| Staff | 12 min | Graceful rolling restarts + sticky assignment |

---

---

# Kafka Configuration and Tuning

🎯 Interview Weight: high - Configuration tuning is a production
engineering skill. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Key Kafka configurations: Producer - `acks=all`, `linger.ms`,
> `batch.size`, `compression.type`, `enable.idempotence`.
> Consumer - `max.poll.records`, `max.poll.interval.ms`,
> `session.timeout.ms`, `heartbeat.interval.ms`, `fetch.min.bytes`.
> Broker - `num.io.threads`, `log.retention.hours`,
> `min.insync.replicas`, `replication.factor`.

**3 minutes (Senior):**
> Producer tuning:
>
> Throughput optimization:
> `linger.ms=5-50`: wait up to 50ms to batch messages before send.
> Reduces number of requests. Increases latency slightly.
> `batch.size=65536` (64KB): larger batches = better compression.
> `compression.type=snappy`: good balance of CPU vs compression ratio.
>
> Latency optimization:
> `linger.ms=0`: send immediately, minimal batching.
> `acks=1`: faster than `acks=all` at cost of durability.
>
> Consumer tuning:
> `max.poll.records=500`: tune based on processing time per record.
> Target: process entire batch in 10-20 seconds max.
> `fetch.min.bytes=1024`: don't fetch until 1KB available.
> Reduces small fetch requests during low traffic.
>
> Broker tuning:
> `min.insync.replicas=2`: with `acks=all` and replication factor 3,
> ensures at least 2 replicas must ack (protects against one broker failure).
> `log.flush.interval.messages=10000`: flush to disk every N messages.
> Higher = more throughput but larger replay window on crash.
>
> JVM tuning for Kafka broker:
> `KAFKA_HEAP_OPTS=-Xmx6g -Xms6g`: large heap for buffer cache.
> GC: G1GC with `MaxGCPauseMillis=20` for low latency.
> OS page cache: Kafka relies heavily on OS page cache. Broker
> servers should have large RAM (32-64GB) allocated to page cache.

**Blank Mind Recovery:**

**(1) Restate:** "Throughput: batch + compress + linger. Latency:
no linger + acks=1. Durability: acks=all + min.insync.replicas=2."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Producer throughput vs latency trade-offs |
| Staff | 10 min | Full broker tuning + OS page cache + JVM |

---

---

# Message Ordering Guarantees in Kafka

🎯 Interview Weight: high - Ordering is a nuanced Kafka topic
that trips up many engineers.

---

### 🎯 Model Answer

**30 seconds:**
> Kafka guarantees ordering within a partition. All messages with
> the same key go to the same partition (default partitioner).
> Therefore: all events for a given order (same order_id key)
> are ordered. Events across different keys may interleave.
> Cross-partition ordering is NOT guaranteed. To guarantee
> global ordering: use a single partition (eliminates parallelism
> - rarely correct decision).

**3 minutes (Senior):**
> Ordering patterns and pitfalls:
>
> Within-partition ordering guarantee:
> Messages are appended in order. Consumer reads in offset order.
> This is only guaranteed if the consumer is not skipping offsets.
>
> Ordering break case 1 - producer retry:
> Producer sends message M1 (seq 1). Network error. Producer retries.
> Sends M2 (seq 2) in the meantime. M1 retry arrives after M2.
> Broker receives: M1 (seq 1), M2 (seq 2), M1 retry (seq 1 = duplicate).
> With `enable.idempotence=false`: M1 arrives out of order after M2.
> With `enable.idempotence=true`: broker deduplicates M1 retry,
> sequence numbers guarantee order (in-flight request limit=1).
> To preserve order with retries: set `max.in.flight.requests.per.connection=1`
> (no idempotence) OR `enable.idempotence=true` (allows up to 5
> in-flight, broker sequences ensure order).
>
> Ordering break case 2 - multiple partitions + different processing speed:
> Order events: OrderPlaced (partition 0) and OrderCancelled (partition 1).
> Consumer A processes partition 0 slowly. Consumer B processes
> partition 1 quickly. OrderCancelled may be processed before
> OrderPlaced if both consumers are running independently.
> Fix: use the same key (order_id) for all order events -> same partition.
>
> Ordering break case 3 - parallel consumer threads:
> One consumer reading partition 0 spawns 10 threads to process
> messages in parallel. Thread 5 finishes before Thread 3.
> Processing is out of order within the consumer.
> Fix: process records sequentially within a partition, OR
> ensure your processing logic does not assume sequential order.

**Blank Mind Recovery:**

**(1) Restate:** "Ordering: within partition yes, across partitions no.
Use same key for related events. Idempotence preserves order through retries."

---

### ⚖️ Comparison Table

| Ordering Scope | Guarantee | Requirement |
|----------------|----------|-------------|
| Global | None (multi-partition) | Single partition (kills parallelism) |
| Per-entity | Yes | Same key = same partition |
| Within-partition | Yes (offset order) | Single-threaded consumer |
| With retries | Yes | enable.idempotence=true |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Within-partition ordering + key selection |
| Senior | 7 min | Ordering breaks + idempotence fix + parallel processing pitfalls |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Consumer API + offset commit modes |
| System Design | Partition design + ordering guarantees |
| Bar Raiser | Rebalancing + idempotence internals |
