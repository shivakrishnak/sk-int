---
layout: default
title: "Messaging - L1 Foundations"
parent: "Messaging and Event-Driven"
grand_parent: "SK Interview"
nav_order: 2
permalink: /messaging/l1-foundations/
---

# Message Queue Fundamentals

🎯 Interview Weight: high - Message queue internals underpin
all messaging system knowledge.

---

### 🎯 Model Answer

**30 seconds:**
> A message queue is a buffer that temporarily stores messages
> between a producer and a consumer. Properties: durability
> (messages survive broker restart), ordering (usually FIFO within
> a queue), acknowledgment (consumer confirms processing before
> message is deleted), backpressure (queue depth signals producer
> to slow down). Core guarantees: at-least-once delivery (default),
> at-most-once, or exactly-once (harder, higher cost).

**3 minutes (Senior):**
> Message queue internals:
>
> Message lifecycle:
> 1. Producer sends message to queue.
> 2. Broker persists message (disk or memory based on config).
> 3. Consumer fetches message (push or pull model).
> 4. Consumer processes message.
> 5. Consumer acknowledges (ACK) or rejects (NACK).
> 6. On ACK: broker deletes message.
> 7. On NACK or timeout: message returns to queue for retry.
>    After N retries: moves to dead-letter queue (DLQ).
>
> Durability options:
> Durable queue: survives broker restart (messages on disk).
> Transient queue: lost on restart (messages in memory).
> Production always uses durable queues.
>
> Acknowledgment modes:
> Auto-ack: message deleted immediately when delivered.
> At-most-once delivery. If consumer crashes after delivery
> but before processing: message is lost.
> Manual-ack: consumer explicitly ACKs after processing.
> At-least-once delivery. If consumer crashes after processing
> but before ACK: message is redelivered (duplicate processing
> is possible). Make consumers idempotent.
>
> Prefetch count (consumer batching):
> How many unacknowledged messages a consumer can hold.
> Prefetch=1: consumer takes one message at a time.
> Fair distribution among workers. Lower throughput.
> Prefetch=100: consumer batches 100 messages.
> Higher throughput. Risk: if consumer dies with 100
> unacknowledged messages, they all return to queue.

**Blank Mind Recovery:**

**(1) Restate:** "Queue: buffer between producer and consumer.
ACK = delete message. NACK = retry. DLQ = poison messages."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Message lifecycle + ACK/NACK mechanics |
| Senior | 7 min | Durability + prefetch + idempotent consumers |

---

---

# Apache Kafka Core Concepts

🎯 Interview Weight: very high - Kafka is the dominant event
streaming platform. Deep knowledge expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Kafka is a distributed commit log. Topics are divided into
> partitions. Messages within a partition are ordered and
> assigned a sequential offset. Producers write to partitions.
> Consumers in a consumer group each own one or more partitions.
> Kafka retains messages for a configurable duration (days/weeks)
> regardless of whether they have been consumed. Consumers track
> their position (offset) independently.

**3 minutes (Senior):**
> Kafka architecture:
>
> Brokers: Kafka cluster consists of multiple brokers (servers).
> Each broker stores a subset of partitions.
> ZooKeeper (pre-3.0) / KRaft (3.0+): manages cluster metadata,
> leader election, and broker registration.
>
> Topics and partitions:
> Topic: logical grouping of related events (orders, payments).
> Partition: ordered, immutable sequence of messages on disk.
> Each message has an offset (monotonically increasing ID).
> Partitions enable parallelism: N partitions = N consumers
> can process in parallel.
>
> Replication:
> Each partition has one leader (handles reads and writes) and
> N-1 replicas (followers). Replication factor typically 3.
> ISR (In-Sync Replicas): replicas caught up with the leader.
> Producer `acks=all`: message acknowledged only when all ISR
> replicas have written it. Durability guarantee.
>
> Consumer offset management:
> Consumers commit their current offset to `__consumer_offsets`
> topic (internal Kafka topic). On restart: consumer resumes
> from last committed offset. `auto.offset.reset=earliest/latest`:
> what to do when no committed offset exists.
>
> Message retention:
> By time: `retention.ms=604800000` (7 days default).
> By size: `retention.bytes=-1` (unlimited by default).
> Compact: `cleanup.policy=compact` - keeps only last value
> per key. Good for event sourcing snapshots.

**Blank Mind Recovery:**

**(1) Restate:** "Kafka: distributed log. Partitions = parallelism.
Offsets = consumer position. Retention = replay history."

---

### 💻 Code Example

```java
// BAD: no error handling, sync send blocks the thread
Properties props = new Properties();
props.put("bootstrap.servers", "localhost:9092");
producer = new KafkaProducer<>(props);
producer.send(new ProducerRecord<>("orders", key, value));
// No acks config = at-most-once delivery
// No exception handling = silent message loss

// GOOD: async send with callback, proper acks config
Properties props = new Properties();
props.put("bootstrap.servers", "kafka:9092");
props.put("acks", "all");          // wait for all ISR
props.put("retries", "3");
props.put("enable.idempotence", "true"); // exactly-once
props.put("key.serializer",
  "org.apache.kafka.common.serialization.StringSerializer");
props.put("value.serializer",
  "io.confluent.kafka.serializers.KafkaAvroSerializer");

KafkaProducer<String, Order> producer =
    new KafkaProducer<>(props);

producer.send(
    new ProducerRecord<>("orders", order.getId(), order),
    (metadata, exception) -> {
        if (exception != null) {
            log.error("Failed to send order {}: {}",
                order.getId(), exception.getMessage());
            // retry or dead-letter logic here
        } else {
            log.debug("Sent order {} to partition {} offset {}",
                order.getId(),
                metadata.partition(),
                metadata.offset());
        }
    }
);
```

> **Code walkthrough:** The bad example omits `acks` config
> (defaults to `acks=1` which risks data loss if leader fails
> before replication) and does not handle send failures.
> The good example sets `acks=all` (waits for all ISR replicas),
> `enable.idempotence=true` (deduplicates retries on the broker
> side), and uses an async callback to log errors without
> blocking the producer thread. Avro serializer integrates
> with Schema Registry for schema evolution safety.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | Topic/partition/offset model + consumer groups |
| Senior | 8 min | Replication + ISR + acks levels + offset management |
| Staff | 12 min | KRaft + exactly-once semantics + retention policies |

---

---

# RabbitMQ Core Concepts

🎯 Interview Weight: high - RabbitMQ is the dominant task queue
broker. Expected at mid-senior level.

---

### 🎯 Model Answer

**30 seconds:**
> RabbitMQ is a message broker with a publish/subscribe model
> based on exchanges and queues. Producers send messages to
> exchanges. Exchanges route messages to queues based on
> routing rules. Consumers subscribe to queues. Exchange types:
> direct (exact key match), fanout (broadcast to all bound queues),
> topic (wildcard key match), headers (attribute-based routing).

**3 minutes (Senior):**
> RabbitMQ routing model:
>
> Exchange types:
> Direct: message with routing key "order.placed" goes only
> to queues bound with that exact key.
> Fanout: message delivered to all bound queues regardless
> of routing key. Used for broadcast notifications.
> Topic: routing key matches wildcard patterns.
> "order.*" matches "order.placed" and "order.cancelled".
> "order.#" matches any number of words after "order.".
> Headers: routing based on message headers (not routing key).
>
> Queue durability and persistence:
> Durable queue + persistent message = survives RabbitMQ restart.
> Both must be set (durable queue + delivery-mode=2 property).
> If queue is durable but message is not persistent: message
> survives restart but with no guarantee of full durability.
>
> Consumer ACK:
> manual ACK after processing: `channel.basicAck(deliveryTag, false)`
> NACK without requeue: send to DLQ if configured.
> NACK with requeue: message returns to front of queue.
> Risk of infinite loop if message is always failing.
>
> Prefetch (QoS):
> `channel.basicQos(1)`: receive at most 1 unacknowledged message.
> Fair dispatch: busy workers take fewer messages.
> High prefetch: higher throughput but larger in-flight set.

**Blank Mind Recovery:**

**(1) Restate:** "RabbitMQ: producer -> exchange -> queue -> consumer.
Exchange type determines routing. ACK = delete, NACK = retry."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Exchange types + routing keys |
| Senior | 7 min | Durability + ACK mechanics + prefetch |

---

---

# Message Serialization Formats

🎯 Interview Weight: medium-high - Schema evolution is a
production challenge every messaging system faces.

---

### 🎯 Model Answer

**30 seconds:**
> Message serialization formats: JSON (human-readable, schema-less,
> large size), Avro (compact binary, schema required, schema evolution
> built-in), Protobuf (compact binary, strongly typed, code generation),
> MessagePack (binary JSON, smaller than JSON). For Kafka + Schema
> Registry: Avro is the most common. For gRPC: Protobuf. For
> simple REST-like messaging: JSON.

**3 minutes (Senior):**
> Avro + Schema Registry pattern (Kafka standard):
>
> Schema Registry: central repository of Avro/Protobuf/JSON
> schemas. Each topic has a subject (key or value schema).
> Schema ID is stored in the first 5 bytes of every message.
> Consumer looks up schema ID -> fetches schema -> deserializes.
>
> Schema evolution rules (Avro):
> Backward compatible: new schema can read old messages.
> New field with default value = backward compatible.
> Forward compatible: old schema can read new messages.
> Removing a field = forward compatible (if consumer ignores unknowns).
> Full compatible: both. Required for zero-downtime upgrades.
>
> Evolution example:
> V1: `{name, email}`
> V2: `{name, email, phone: default=null}` -> backward compatible.
> Old consumers reading V2 messages ignore `phone`.
> New consumers reading V1 messages use `null` for `phone`.
>
> Incompatible changes (breaking):
> Removing a field without default.
> Changing type (int to string).
> Breaking changes require a new topic (parallel run period).
>
> Format comparison:
> JSON: flexible, human-readable, 2-5x size overhead vs Avro.
> Avro: compact, schema evolution, requires Schema Registry.
> Protobuf: more compact than Avro, backward compatible by
> field number, used in gRPC.

**Blank Mind Recovery:**

**(1) Restate:** "JSON=simple. Avro=compact+schema evolution.
Protobuf=compact+typed. Schema Registry enforces compatibility."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | JSON vs Avro vs Protobuf |
| Senior | 7 min | Schema evolution + Schema Registry + breaking changes |

---

---

# Message Delivery Guarantees

🎯 Interview Weight: very high - Delivery guarantees are
a core interview topic for all messaging systems.

---

### 🎯 Model Answer

**30 seconds:**
> Three delivery guarantees:
> At-most-once: message delivered 0 or 1 times. Fast, no retries.
> Messages can be lost. Acceptable: telemetry, non-critical metrics.
> At-least-once: message delivered 1 or more times. Retries on
> failure. Duplicates possible. Requires idempotent consumers.
> Most common in production. Exactly-once: message delivered
> exactly once. Highest cost, requires transactional semantics.
> Kafka Streams, RabbitMQ with transactions.

**3 minutes (Senior):**
> Delivery guarantee mechanics:
>
> At-most-once (Kafka auto-commit, RabbitMQ auto-ack):
> Consumer receives message and immediately acks before
> processing. If consumer crashes after ack but before
> processing: message is lost forever. Kafka: `enable.auto.commit=true`
> with short commit interval implements this.
>
> At-least-once (most production systems):
> Consumer processes message, then acks. If consumer crashes
> after processing but before acking: message is redelivered.
> Consumer processes it again. Duplicate processing occurs.
> Fix: idempotent consumer (same message ID = same result).
> Kafka: `enable.auto.commit=false`, manual commit after processing.
>
> Exactly-once in Kafka:
> Producer side: `enable.idempotence=true` - deduplicates
> retries. Each producer has a unique ID; broker rejects
> duplicates using sequence numbers.
> Transaction API: producer groups multiple sends in a
> transaction. All succeed or all fail atomically.
> Used in Kafka Streams for read-process-write exactly-once.
> Consumer side: read-process-write in a Kafka transaction
> = exactly-once semantics (EOS).
>
> The idempotency pattern for at-least-once:
> Include a unique idempotency key in every message.
> Consumer stores processed IDs in a deduplication store
> (Redis, DB with unique constraint).
> Before processing: check if ID already processed.
> If yes: skip. If no: process + store ID in same transaction.

**Blank Mind Recovery:**

**(1) Restate:** "At-most-once: may lose. At-least-once: may
duplicate. Exactly-once: expensive. At-least-once + idempotent consumer = practical solution."

---

### ⚖️ Comparison Table

| Guarantee | Message Loss | Duplicates | Performance | Use Case |
|-----------|-------------|-----------|-------------|---------|
| At-most-once | Possible | None | Highest | Metrics, logs |
| At-least-once | No | Possible | High | Most production |
| Exactly-once | No | No | Lowest | Financial transactions |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 5 min | Three guarantees + trade-offs |
| Senior | 8 min | Kafka exactly-once mechanics + idempotent consumer pattern |
| Staff | 12 min | Distributed exactly-once across systems (Outbox pattern) |

**[DEBUGGING] Your service is processing messages twice in
production. How do you diagnose and fix it?**
`[MID]`

*Why they ask:* Duplicate processing is the most common
messaging production bug. Tests understanding of at-least-once.

*Likely follow-up:* "How do you fix this without stopping the service?"

Step 1: Confirm duplicates. Look for duplicate processing
side effects (duplicate database rows, duplicate emails sent).
Check consumer logs for the same message offset being processed
more than once.

Step 2: Identify the cause. Common causes:
(a) Consumer commits offset too late / never commits.
    Consumer processes the message and crashes before committing
    the offset. On restart: message is reprocessed from last
    committed offset.
(b) Rebalance: consumer group rebalances while a message is
    in-flight. The partition moves to a new consumer which
    reprocesses from the last committed offset.
(c) Manual ack failure: consumer processes but NACK/exception
    before ack. Message returns to queue.

Step 3: Fix options:
Option A: make the consumer idempotent.
Add a `processed_events` table with `event_id UNIQUE`.
Before processing: check if event_id exists.
If exists: skip. If not: process and insert event_id in the
same transaction.
Option B: commit offsets more frequently (reduces re-processing
window after crash).
Option C: use Kafka transactions for read-process-write atomicity.

*What separates good from great:* Knowing that idempotency
is the robust solution, not trying to prevent duplicates
(which is impossible in at-least-once systems).

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Delivery guarantees mechanics |
| System Design | When to use which guarantee |
| Bar Raiser | Idempotency patterns + exactly-once trade-offs |
