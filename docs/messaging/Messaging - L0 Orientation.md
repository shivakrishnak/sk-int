---
layout: default
title: "Messaging - L0 Orientation"
parent: "Messaging and Event-Driven"
grand_parent: "SK Interview"
nav_order: 1
permalink: /messaging/l0-orientation/
---

# Event-Driven Architecture Overview

🎯 Interview Weight: high - EDA is the architectural foundation
for all messaging systems. Every senior engineer needs this.

---

### 🎯 Model Answer

**30 seconds:**
> Event-Driven Architecture (EDA) is a design approach where
> services communicate by producing and consuming events rather
> than making direct synchronous calls. An event represents
> something that happened (OrderPlaced, PaymentProcessed).
> Producers emit events without knowing who consumes them.
> Consumers subscribe to events they care about. This creates
> loose coupling: producers and consumers evolve independently.

**3 minutes (Senior):**
> Event-Driven Architecture fundamentals:
>
> Core components:
> Event: immutable record of something that happened.
> Contains: event type, timestamp, source, payload.
> "OrderPlaced" event with order ID, customer ID, items, total.
>
> Event producer: service that detects state changes and
> emits events. The OrderService emits OrderPlaced after
> creating an order in its database.
>
> Event broker: durable, ordered log of events.
> Kafka, RabbitMQ, AWS SQS/SNS, Azure Service Bus.
> Decouples producers from consumers in time and space.
>
> Event consumer: service that subscribes to events and
> reacts. PaymentService consumes OrderPlaced and initiates
> payment. InventoryService consumes OrderPlaced and reserves stock.
> EmailService consumes OrderPlaced and sends confirmation.
>
> EDA vs REST/synchronous:
> REST: OrderService calls PaymentService directly.
> OrderService must wait for payment response (tight coupling).
> If PaymentService is down: OrderService call fails (cascading failure).
> EDA: OrderService emits OrderPlaced, returns immediately.
> PaymentService processes in its own time.
> If PaymentService is down: events accumulate in broker.
> When PaymentService recovers: processes queued events.
> No cascading failure.
>
> Benefits: loose coupling, independent scaling (PaymentService
> can scale to handle burst without changing OrderService),
> resilience (broker buffers events during consumer outage),
> audit trail (events are immutable history).
>
> Drawbacks: eventual consistency (order placed, payment not yet
> processed), debugging complexity (trace flows across services
> via correlation IDs), ordering guarantees limited (events from
> multiple producers may arrive out of order).

**Blank Mind Recovery:**

**(1) Restate:** "EDA: services talk via events through a broker.
Loose coupling, async processing, resilient to consumer failures."

**(2) First principles:** "Rather than calling someone directly,
you leave a message. They read it when they can. You are not
blocked waiting."

**(3) Bridge:** "Like email vs phone call. Phone call (REST)
requires both parties present. Email (EDA) is decoupled in time."

---

### ⚖️ Comparison Table

| Aspect | Synchronous (REST) | Event-Driven (EDA) |
|--------|-------------------|-------------------|
| Coupling | Tight (direct call) | Loose (via broker) |
| Availability | Cascades failures | Broker buffers events |
| Consistency | Immediate | Eventual |
| Debugging | Request trace | Correlation ID trace |
| Scalability | Both services must scale | Independent |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 3 min | EDA definition + producer/consumer model |
| Mid | 5 min | EDA vs REST trade-offs |
| Senior | 8 min | Failure modes + eventual consistency implications |

---

---

# Messaging Systems Landscape

🎯 Interview Weight: medium - Knowing the landscape helps make
technology selection decisions.

---

### 🎯 Model Answer

**30 seconds:**
> The major messaging systems: Apache Kafka (distributed log,
> high throughput, retention), RabbitMQ (traditional message
> queue, routing flexibility, lower throughput), AWS SQS
> (managed queue, at-least-once, simple), AWS SNS (pub/sub
> fan-out), Apache Pulsar (Kafka alternative with multi-tenancy).
> Kafka dominates for high-throughput event streaming.
> RabbitMQ dominates for complex routing and task queues.

**3 minutes (Senior):**
> Messaging systems by use case:
>
> Kafka - event streaming platform:
> Strengths: millions of messages/second, ordered partitions,
> durable retention (days/weeks/forever), consumer group offsets
> (replay from any point), exactly-once in Kafka Streams.
> Use when: high throughput, need to replay events, multiple
> independent consumers from same stream, event sourcing.
> Limitations: higher operational complexity, no per-message
> routing, all consumers receive all messages in a partition.
>
> RabbitMQ - traditional message broker:
> Strengths: flexible routing (direct, topic, fanout, headers
> exchange types), per-message acknowledgment, dead letter
> queues, priority queues, lower latency per message.
> Use when: task queues with work distribution, complex routing,
> request/reply patterns, low-to-medium throughput.
> Limitations: messages deleted after consumption (no replay),
> lower throughput than Kafka, clustering complexity.
>
> AWS SQS - managed queue:
> Strengths: fully managed, scales automatically, FIFO queues
> for ordering, dead-letter queues built in, no servers to manage.
> Use when: AWS-native stack, don't want to manage brokers,
> simple queue semantics, serverless architectures.
> Limitations: AWS lock-in, max message size 256KB, visibility
> timeout gotchas.
>
> Apache Pulsar:
> Combines Kafka-style persistent log with RabbitMQ-style queuing.
> Multi-tenancy, geo-replication built in. Operators are smaller
> (BookKeeper for storage, separate from brokers).
> Not yet as widely adopted as Kafka.

**Blank Mind Recovery:**

**(1) Restate:** "Kafka: high-throughput streaming + replay.
RabbitMQ: flexible routing + task queues. SQS: managed simplicity."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Kafka vs RabbitMQ use cases |
| Senior | 7 min | Technology selection framework + trade-offs |

---

---

# Synchronous vs Asynchronous Communication

🎯 Interview Weight: high - Every system design interview touches
this. Core mental model for distributed systems.

---

### 🎯 Model Answer

**30 seconds:**
> Synchronous: caller waits for the callee to respond before
> continuing. REST HTTP calls are synchronous. Advantages:
> immediate feedback, simple error handling. Disadvantages:
> cascading failures, temporal coupling (both services must
> be up simultaneously).
>
> Asynchronous: caller sends a message and continues without
> waiting. Messaging systems are asynchronous. Advantages:
> decoupled availability, better scalability. Disadvantages:
> eventual consistency, harder error handling, debugging complexity.

**3 minutes (Senior):**
> Communication pattern decision guide:
>
> Choose synchronous (REST/gRPC) when:
> - You need an immediate response to make a decision.
>   ("Is the user authenticated?" - cannot proceed without answer)
> - The operation must complete before the caller can continue.
>   ("Create order AND return order ID to the user immediately")
> - Simple CRUD operations with a single service responsible.
> - User is waiting (interactive UI): async adds too much latency.
>
> Choose asynchronous (messaging) when:
> - Processing can happen after the response to the user.
>   (Order placed. Email notification sends afterward.)
> - Fan-out: one event triggers multiple downstream reactions.
>   (OrderPlaced -> payment + inventory + email + analytics)
> - Load leveling: downstream service cannot handle burst.
>   (Queue absorbs burst; worker processes at its own pace)
> - Services should not know about each other.
>   (OrderService should not depend on EmailService)
>
> Hybrid pattern (common in production):
> Synchronous for the command + asynchronous for side effects.
> `POST /orders` creates the order synchronously (DB write +
> return order ID). An event is emitted asynchronously for
> payment, inventory, and notifications. User gets their order ID
> immediately. Side effects happen in the background.

**Blank Mind Recovery:**

**(1) Restate:** "Sync: wait for answer. Async: fire and forget.
Sync for user-facing decisions, async for side effects."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | When to use each + trade-offs |
| Senior | 7 min | Hybrid patterns + eventual consistency implications |

---

---

# Pub/Sub vs Point-to-Point Queues

🎯 Interview Weight: medium - Core messaging topology decision.
Expected at mid-level.

---

### 🎯 Model Answer

**30 seconds:**
> Point-to-point (queue): one producer, one consumer per message.
> A message is delivered to exactly one consumer. Used for task
> distribution: multiple worker instances each process different
> messages. Pub/Sub: one producer, multiple consumers all receive
> a copy. Used for event fan-out: OrderPlaced goes to payment,
> inventory, AND email services. Kafka topics are pub/sub.
> RabbitMQ queues are point-to-point (but exchanges can fan-out).

**3 minutes (Senior):**
> Messaging topologies:
>
> Point-to-point queue:
> Producer -> Queue -> Consumer A (only this consumer gets it)
> Use case: work queues, task distribution.
> Example: image processing queue. 10 worker pods each pick
> one image to process. No duplicate processing.
> In RabbitMQ: queue with multiple consumers, round-robin delivery.
> In Kafka: consumer group with single partition assignment.
>
> Pub/sub (publish/subscribe):
> Producer -> Topic -> Consumer A (all consumers get a copy)
>                   -> Consumer B
>                   -> Consumer C
> Use case: event notification, audit logging, multi-system sync.
> Example: OrderPlaced topic consumed by payment, inventory,
> email, and analytics services - all independently.
>
> Kafka consumer groups (hybrid model):
> Within a consumer group: point-to-point (each partition
> assigned to one consumer instance - no duplicate processing).
> Across consumer groups: pub/sub (each group gets its own
> copy of all messages).
> This makes Kafka both a work queue AND a pub/sub system
> depending on how consumer groups are configured.
>
> RabbitMQ fan-out exchange:
> Publish to a fanout exchange -> message copied to all bound queues.
> Effectively implements pub/sub. Each service binds its own queue.
> Messages persist in each queue independently (consumer A lagging
> does not affect consumer B).

**Blank Mind Recovery:**

**(1) Restate:** "Queue (P2P): one consumer per message.
Pub/Sub: all consumers get every message. Kafka does both via consumer groups."

---

### ⚖️ Comparison Table

| Pattern | Delivery | Scaling | Use Case |
|---------|---------|---------|----------|
| Point-to-Point | One consumer | Work distribution | Task queues |
| Pub/Sub | All consumers | Fan-out | Event notification |
| Kafka Consumer Group | One instance per group | Both patterns | Universal |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | P2P vs pub/sub + Kafka consumer groups |
| Senior | 6 min | Architecture decisions for fan-out vs work queues |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | EDA fundamentals + messaging landscape |
| System Design | Sync vs async decision framework |
| Bar Raiser | EDA trade-offs + failure modes |
