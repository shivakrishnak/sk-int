---
layout: default
title: "Messaging - L3 Advanced Integration"
parent: "Messaging and Event-Driven"
grand_parent: "SK Interview"
nav_order: 6
permalink: /messaging/l3-advanced-integration/
---

# Kafka Streams Processing

🎯 Interview Weight: high - Kafka Streams is Java-native stream
processing without external dependencies. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Kafka Streams is a Java library (not a cluster) for stateful
> stream processing on top of Kafka. A Kafka Streams application
> is a regular Java process that reads from input topics, applies
> transformations (map, filter, join, aggregate), and writes to
> output topics. State is stored locally (RocksDB) and backed up
> to Kafka changelog topics. Scales horizontally: add more instances.

**3 minutes (Senior):**
> Kafka Streams topology:
>
> Source processor: reads from a Kafka topic.
> Stream processor: stateless (filter, map) or stateful (aggregations).
> Sink processor: writes to a Kafka topic.
>
> Stateless operations:
> `stream.filter(order -> order.getTotal() > 100)`: keep records
> matching predicate.
> `stream.mapValues(order -> order.toSummary())`: transform values.
> `stream.flatMapValues(order -> order.getItems())`: one-to-many.
>
> Stateful operations (require local state store):
> `stream.groupByKey().windowedBy(TimeWindows.of(Duration.ofMinutes(5)))
>        .count()`: count events per key in 5-minute tumbling window.
> `stream.join(otherStream, ...)`: join two streams on key.
>
> RocksDB state store:
> Stateful operations store intermediate state in RocksDB
> (embedded key-value store). Fast local reads.
> State is also written to a Kafka changelog topic (backup).
> On application restart: state is restored from the changelog
> (not from scratch).
>
> Scaling:
> Kafka Streams scales by adding more application instances.
> Each instance is assigned a subset of partitions.
> State for each partition is co-located with its processor
> instance (local state store).
> Reassignment on instance join/leave triggers state migration.
>
> Exactly-once in Kafka Streams:
> `StreamsConfig.EXACTLY_ONCE_V2`: read from input, process,
> write output, commit offset - all in one atomic Kafka transaction.
> Prevents duplicate processing even after failures.

**Blank Mind Recovery:**

**(1) Restate:** "Kafka Streams: Java library for stream processing.
Read topics, transform, write topics. State in RocksDB + changelog backup."

---

### 💻 Code Example

```java
// Order stream processing: enrich + aggregate

StreamsBuilder builder = new StreamsBuilder();

// Source: incoming order events
KStream<String, Order> orders = builder.stream("orders");

// Stateless: filter large orders
KStream<String, Order> largeOrders = orders.filter(
    (orderId, order) -> order.getTotal().compareTo(
        BigDecimal.valueOf(1000)) > 0
);

// Stateful: count orders per customer per 5 minutes
KTable<Windowed<String>, Long> orderCounts = orders
    .groupBy((orderId, order) -> order.getCustomerId())
    .windowedBy(
        TimeWindows.ofSizeWithNoGrace(Duration.ofMinutes(5))
    )
    .count(Materialized.as("order-counts-store"));

// Sink: write enriched orders to output topic
largeOrders.to("large-orders",
    Produced.with(Serdes.String(), orderSerde));

// Sink: write count alerts
orderCounts.toStream()
    .filter((windowedKey, count) -> count > 10)
    .map((windowedKey, count) -> KeyValue.pair(
        windowedKey.key(),
        new OrderRateAlert(windowedKey.key(), count)
    ))
    .to("order-rate-alerts");

KafkaStreams streams = new KafkaStreams(
    builder.build(),
    streamsConfig
);
streams.start();
```

> **Code walkthrough:** The topology reads from the `orders`
> topic, filters for orders over $1000 (stateless), and counts
> orders per customer in 5-minute tumbling windows (stateful,
> backed by RocksDB store named `order-counts-store`). Large
> orders are written to a dedicated topic. When a customer
> places more than 10 orders in 5 minutes, an alert is emitted
> to `order-rate-alerts`. The entire topology runs as a single
> Java process - no Spark or Flink cluster required.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Stateless vs stateful + RocksDB state + scaling |
| Staff | 10 min | Exactly-once + windowing + state restoration |

---

---

# Schema Evolution with Avro and Protobuf

🎯 Interview Weight: very high - Schema evolution is a
production challenge for every event-driven system.

---

### 🎯 Model Answer

**30 seconds:**
> Schema evolution: changing message structure over time without
> breaking existing producers or consumers. Avro: evolution
> via adding fields with defaults (backward compatible) or
> removing non-required fields (forward compatible). Protobuf:
> evolution via field number stability (never reuse/change field
> numbers). Schema Registry (Confluent) enforces compatibility
> rules and stores schema versions. Breaking changes require
> a migration strategy: new topic or parallel run period.

**3 minutes (Senior):**
> Avro schema evolution rules:
>
> Backward compatible (new schema reads old data):
> Add field with default: `{"name": "phone", "type": "string",
> "default": ""}`. Old messages without `phone` use default.
> Remove field: old consumers that expected the field use
> the reader schema's default.
>
> Forward compatible (old schema reads new data):
> Add field without default: old schema ignores unknown fields.
> Keep all existing fields.
>
> Fully compatible: both backward and forward.
> Only add fields with defaults.
> Only remove fields that have defaults in the reader schema.
>
> Incompatible (breaking):
> Rename a field (no default, no alias) -> breaks consumers.
> Change type (int -> string) -> deserialization failure.
> Remove a field that consumers depend on.
>
> Protobuf schema evolution rules:
> Field numbers are permanent (wire format uses numbers, not names).
> Add new fields with new field numbers. Old code ignores unknowns.
> Never reuse field numbers (old code would misinterpret data).
> Rename fields freely (number is what matters in wire format).
> Remove fields: mark as `reserved` to prevent number reuse.
>
> Schema Registry compatibility modes:
> `BACKWARD`: new schema can read old messages. (Default)
> `FORWARD`: old schema can read new messages.
> `FULL`: both.
> `NONE`: no checks. Dangerous.
>
> Migration strategy for breaking changes:
> 1. Create a new topic with V2 schema.
> 2. New consumers subscribe to V2 topic.
> 3. Run a migration job: read old topic (V1), transform,
>    publish to V2 topic.
> 4. Decommission old topic after all consumers migrate.

**Blank Mind Recovery:**

**(1) Restate:** "Schema evolution: add fields with defaults = safe.
Breaking changes = new topic + migration. Schema Registry enforces rules."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Backward/forward compatibility + breaking change migration |
| Staff | 10 min | Schema Registry configuration + protobuf vs Avro trade-offs |

---

---

# Kafka Connect and Integration Patterns

🎯 Interview Weight: high - Kafka Connect is the standard data
integration layer in Kafka ecosystems.

---

### 🎯 Model Answer

**30 seconds:**
> Kafka Connect is a framework for streaming data between Kafka
> and external systems (databases, S3, Elasticsearch, etc.)
> without custom code. Source connectors: read from external
> systems, publish to Kafka (Debezium CDC, JDBC Source).
> Sink connectors: consume from Kafka, write to external systems
> (Elasticsearch Sink, S3 Sink, JDBC Sink). Runs as a distributed
> cluster with fault tolerance and automatic offset management.

**3 minutes (Senior):**
> Kafka Connect architecture:
>
> Workers: Kafka Connect runs as worker processes.
> Distributed mode: multiple workers form a cluster.
> Connectors are distributed across workers.
> A failing worker's connectors are reassigned to healthy workers.
>
> Source connector (Debezium example):
> Debezium reads PostgreSQL WAL (write-ahead log).
> Every INSERT, UPDATE, DELETE in PostgreSQL -> Kafka event.
> Events contain: before state, after state, operation type.
> No polling. Real-time change data capture.
> Use case: replicate DB changes to Kafka for downstream consumers
> (Elasticsearch, analytics, event sourcing).
>
> Sink connector (Elasticsearch example):
> Consumes from Kafka topics, writes to Elasticsearch indices.
> Handles batching, retries, dead-lettering automatically.
> Offset management: tracks consumer position.
> Exactly-once via idempotent writes (document ID = Kafka offset).
>
> Transforms (Single Message Transforms - SMT):
> Lightweight in-connector transformations.
> Examples: add timestamp field, route to different topics based
> on value, mask sensitive fields, flatten nested structures.
> Not for complex logic - use Kafka Streams instead.
>
> Connector REST API:
> `POST /connectors` to create connectors.
> `GET /connectors/{name}/status` to check connector health.
> `PUT /connectors/{name}/config` to update configuration.
> Integrates with Kubernetes (connector configs in ConfigMaps).

**Blank Mind Recovery:**

**(1) Restate:** "Kafka Connect: source (external -> Kafka) and
sink (Kafka -> external) connectors. Debezium = CDC source. No custom code."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Source vs sink + Debezium CDC |
| Staff | 8 min | Connect cluster architecture + transforms + REST API |

---

---

# Reactive Messaging with SmallRye

🎯 Interview Weight: medium - SmallRye Reactive Messaging is
the Quarkus/Microprofile messaging API.

---

### 🎯 Model Answer

**30 seconds:**
> SmallRye Reactive Messaging is the MicroProfile specification
> implementation for reactive, connector-based messaging in
> Quarkus and Micronaut. Uses `@Incoming` and `@Outgoing`
> annotations to declaratively connect message streams. Supports
> Kafka, RabbitMQ, JMS connectors. Integrates with Mutiny
> (reactive streams) for non-blocking message processing.
> Contrast with Spring Kafka: annotation-based but reactive-first.

**3 minutes (Senior):**
> SmallRye Reactive Messaging model:
>
> `@Incoming("orders")`: consume messages from the "orders" channel.
> `@Outgoing("processed-orders")`: publish messages to the channel.
> Channels map to Kafka topics or RabbitMQ queues via config.
>
> Processing patterns:
> Simple: `@Incoming` method processes and returns void.
> Transformation: `@Incoming + @Outgoing` in same method.
> Method return type = output message.
> Async: method returns `Uni<T>` (Mutiny) for non-blocking processing.
>
> Kafka connector configuration:
> `mp.messaging.incoming.orders.connector=smallrye-kafka`
> `mp.messaging.incoming.orders.topic=orders`
> `mp.messaging.incoming.orders.auto.offset.reset=earliest`
>
> Error handling:
> On exception: by default, message is NACK'd.
> With `@Incoming` and reactive types: configure failure strategy
> (fail, ignore, dead-letter).
> `mp.messaging.incoming.orders.failure-strategy=dead-letter-queue`
>
> Comparison with Spring Kafka:
> SmallRye: reactive-first, Mutiny integration, MicroProfile spec.
> Spring Kafka: imperative by default, reactive via Spring WebFlux
> integration, richer ecosystem.
> Spring Kafka is more mature and widely used in enterprise Spring shops.
> SmallRye is the natural choice for Quarkus microservices.

**Blank Mind Recovery:**

**(1) Restate:** "@Incoming + @Outgoing annotations route messages
through channels. Channels map to Kafka/RabbitMQ via config."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 3 min | @Incoming/@Outgoing model |
| Senior | 6 min | Reactive processing + Mutiny + error handling |

---

---

# Event Store Design and Implementation

🎯 Interview Weight: high - Event store is the persistence layer
for event sourcing. Staff-level design topic.

---

### 🎯 Model Answer

**30 seconds:**
> An event store is an append-only, ordered log of domain events.
> Requirements: append events atomically (optimistic concurrency),
> read events by aggregate ID and sequence range, subscribe to
> new events (for projections). Implementation options:
> EventStoreDB (purpose-built), PostgreSQL with `events` table,
> Kafka topics. Trade-offs: PostgreSQL = ACID + SQL queries but
> limited scalability. EventStoreDB = built for event sourcing,
> subscriptions, no polling.

**3 minutes (Senior):**
> Event store schema (PostgreSQL implementation):
>
> ```sql
> CREATE TABLE events (
>   id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
>   aggregate_id UUID NOT NULL,
>   event_type   VARCHAR(255) NOT NULL,
>   event_data   JSONB NOT NULL,
>   metadata     JSONB,
>   version      BIGINT NOT NULL,
>   occurred_at  TIMESTAMPTZ DEFAULT NOW(),
>   UNIQUE (aggregate_id, version)  -- optimistic concurrency
> );
> CREATE INDEX idx_events_aggregate ON events(aggregate_id, version);
> ```
>
> Optimistic concurrency control:
> Load: read events for aggregate, note last version (N).
> Validate: apply business rules to current state.
> Append: INSERT with version = N+1.
> If another process inserted N+1 first: UNIQUE constraint
> violation -> retry (re-load events, re-apply command).
>
> Subscription model (projection updater):
> After appending: notify subscribers (polling or notification).
> Option A: polling (`SELECT * FROM events WHERE id > lastSeen`).
> Option B: PostgreSQL LISTEN/NOTIFY for real-time push.
> Option C: Debezium reads WAL -> Kafka -> projections update.
>
> EventStoreDB advantages:
> Purpose-built: streams (per-aggregate log), subscriptions
> (persistent, competing consumers), projections (built-in
> query language). No application-level polling needed.
> Streams: `/streams/{aggregate_id}` = all events for that aggregate.
> Subscriptions: subscribe to a stream or category ($ce-orders
> = all events from all order streams).

**Blank Mind Recovery:**

**(1) Restate:** "Event store: append-only, ordered by sequence.
Optimistic concurrency via version. PostgreSQL or EventStoreDB."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Schema design + optimistic concurrency |
| Staff | 8 min | EventStoreDB subscriptions + PostgreSQL vs EventStoreDB |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Kafka Streams stateful processing |
| System Design | Schema evolution + event store design |
| Bar Raiser | Exactly-once across systems + CQRS + event store trade-offs |
