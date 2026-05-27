---
layout: default
title: "Messaging - META Patterns"
parent: "Messaging and Event-Driven"
grand_parent: "SK Interview"
nav_order: 10
permalink: /messaging/meta-patterns/
---

# Event-Driven Decision Framework

🎯 Interview Weight: very high - A decision framework for
choosing between synchronous and asynchronous communication
is expected at Staff level.

---

### 🎯 Model Answer

**30 seconds:**
> Use events when: the producer does not need an immediate
> response, multiple consumers need the same data, operations
> are idempotent and safe to retry, or high availability of
> the producer matters more than immediate side-effect execution.
> Use synchronous calls when: the caller needs the response
> to proceed, the operation must be atomic (both succeed or
> both fail), or the user is waiting for feedback.

**3 minutes (Senior):**
> The decision framework - questions to ask:
>
> Q1: Does the caller need the result to continue?
> YES -> synchronous (REST/gRPC).
> NO -> candidate for async (events).
>
> Q2: Are there multiple consumers for this event?
> YES -> events (fan-out, pub/sub).
> NO -> direct call may be simpler (no broker overhead).
>
> Q3: Can the consumer be temporarily unavailable?
> YES (broker buffers) -> events.
> NO (user waiting) -> synchronous with circuit breaker.
>
> Q4: Does the operation have side effects that are hard to undo?
> YES (send email, charge card) -> events with idempotency + DLQ.
> NO -> either approach works.
>
> Q5: Is ordering important across multiple entities?
> YES for same entity -> Kafka same partition key.
> YES globally -> single partition (throughput sacrifice).
> NO -> events with multiple partitions.
>
> Q6: Is the team comfortable debugging async systems?
> NO -> synchronous is operationally simpler.
> YES -> async provides scalability + resilience benefits.
>
> Hybrid decision:
> Most production systems use both:
> User-facing operations: synchronous for immediate feedback.
> Background processing: async for decoupled, scalable side effects.
> Example: `POST /orders` (sync) returns order ID.
> Order fulfillment workflow (payment, inventory, shipping):
> all async via events.
>
> Anti-pattern to avoid:
> "We use events everywhere" or "We use REST everywhere."
> Dogmatic messaging approaches ignore the trade-offs.
> The right tool depends on the specific interaction requirements.

**Blank Mind Recovery:**

**(1) Restate:** "Events: no response needed + fan-out + resilience.
Sync: user needs response + atomic operation. Hybrid = best of both."

---

### ⚖️ Comparison Table

| Criterion | Choose Sync | Choose Events |
|-----------|------------|--------------|
| Response needed | Yes | No |
| Multiple consumers | No | Yes |
| Consumer availability | Required | Not required |
| Ordering | Not needed | Per-entity (same partition key) |
| Complexity tolerance | Low | High |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Decision criteria + trade-offs |
| Staff | 10 min | Hybrid design + when to say no to events |

**[TRADE-OFF] A product manager asks you to make the checkout
flow faster by making payment processing asynchronous. How
do you evaluate this proposal?**
`[STAFF]`

*Why they ask:* Tests the ability to critically evaluate an
architectural change proposal, not just implement it.

*Likely follow-up:* "The PM says competitors do this - how do
you make the final recommendation?"

Evaluate the trade-offs systematically:

User experience impact:
Async payment means: user submits checkout, sees "processing..."
UI, gets a notification when payment is done (email/push).
This IS used by some e-commerce platforms (Amazon for some
payment methods, B2B invoicing). However, most consumer
checkout flows show immediate confirmation: "Payment accepted."
Users expect immediate feedback. Async adds a new UI state
(pending) and more failure states (payment declined after
checkout - how do you handle order state?).

Technical complexity:
Async payment requires: outbox pattern (DB + event atomic),
saga for compensation (payment failed = cancel order + restore
inventory), DLQ for failed payments, UI polling or WebSocket
for payment status updates. The complexity multiplies.

Risk assessment:
Async checkout introduces a new failure mode: user thinks
they ordered, but the payment fails later. The business must
decide: hold inventory during pending payment? If yes:
inventory is blocked while payment processes. If no: inventory
might run out between order and payment confirmation.

My recommendation:
Use async processing for non-critical side effects (email
confirmation, analytics, loyalty points). Keep payment
synchronous for the checkout confirmation screen. If payment
takes >3 seconds (performance issue): optimize the payment
service or use a pre-authorization approach (instant card check,
full charge async). This gives perceived speed without
the async failure state complexity.

*What separates good from great:* Evaluating the user experience,
technical complexity, and business risk - not just the
architectural feasibility.

---

---

# Messaging Pattern Selection Model

🎯 Interview Weight: high - Knowing which messaging pattern
to apply to which problem is a Staff-level skill.

---

### 🎯 Model Answer

**30 seconds:**
> Messaging pattern selection: for task distribution use a
> work queue (point-to-point, multiple workers). For event
> notification use pub/sub (fan-out). For ordered workflows
> use sagas (orchestration or choreography). For full audit
> history use event sourcing. For read-optimized queries use
> CQRS. For cross-system atomicity use outbox. Each pattern
> solves a different problem - using the wrong one creates
> accidental complexity.

**3 minutes (Senior):**
> Pattern selection guide:
>
> Work queue (task distribution):
> Problem: distribute N tasks across M workers.
> Pattern: P2P queue with multiple consumers.
> Tool: RabbitMQ queue, SQS, Kafka consumer group (single partition
> per worker).
> Example: image resize jobs, email sending, report generation.
>
> Pub/sub (event notification):
> Problem: one event triggers reactions in multiple services.
> Pattern: topic with multiple consumer groups.
> Tool: Kafka topic, SNS, RabbitMQ fanout exchange.
> Example: OrderPlaced -> payment + inventory + email.
>
> Saga (distributed transaction):
> Problem: multi-service operation that must succeed or fully roll back.
> Pattern: orchestration or choreography with compensations.
> Tool: Temporal, custom state machine, AWS Step Functions.
> Example: order fulfillment across payment + inventory + shipping.
>
> Event sourcing (audit trail + temporal query):
> Problem: need full history of entity state changes.
> Pattern: store events, derive state by replay.
> Tool: EventStoreDB, PostgreSQL events table, Kafka (limited).
> Example: financial ledger, healthcare record changes.
>
> Outbox (cross-system atomicity):
> Problem: must write to DB AND publish an event atomically.
> Pattern: write event to outbox table in DB transaction,
> relay publishes to broker.
> Tool: Debezium (CDC), custom polling relay.
> Example: any service that writes to DB and publishes to Kafka.
>
> CQRS (read optimization):
> Problem: write model normalized, read model needs different
> shape for queries.
> Pattern: separate read model updated by events from write model.
> Tool: Kafka consumer updating Elasticsearch/Redis read store.
> Example: product search, order history, analytics dashboards.

**Blank Mind Recovery:**

**(1) Restate:** "Work queue = task distribution. Pub/sub = fan-out.
Saga = distributed transaction. Outbox = atomic DB + event."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Pattern selection for common scenarios |
| Staff | 10 min | Combining patterns (CQRS + event sourcing + outbox) |

---

---

# Eventual Consistency Mental Model

🎯 Interview Weight: very high - Eventual consistency is the
core trade-off of event-driven systems. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> Eventual consistency: after all updates stop, all replicas
> will eventually have the same state - but intermediate reads
> may see stale data. In event-driven systems: writing to the
> command model and reading from the read model (CQRS projection)
> involves a consistency window (milliseconds to seconds).
> During this window: the user who just submitted an order may
> see their order as "processing" in the order list even though
> they just confirmed it.

**3 minutes (Senior):**
> Eventual consistency patterns:
>
> The "read your own writes" problem:
> User creates an order. Order is in the write DB.
> Event published. Projection updates asynchronously.
> User immediately loads the order list (reads from projection).
> Their new order is not there yet (projection not updated).
> User thinks the order was lost.
>
> Solutions to "read your own writes":
> Option 1: Read from write model for the just-created item.
> After creating order: redirect to `/orders/{id}` which reads
> from the write DB (not projection). Projection is used for
> list views.
> Option 2: Synchronous projection update for the creating user.
> After publishing event: wait for projection to confirm update
> (using a request ID as a barrier). Complex.
> Option 3: Optimistic UI. Frontend adds the new item to the
> local state immediately (without waiting for projection).
> Eventual consistency is hidden from the user by the UI.
>
> Consistency windows:
> Same DB, same node: milliseconds.
> Same DB, different replica: 1-100ms (replication lag).
> Kafka -> consumer -> projection update: 100ms - 5 seconds.
> Cross-region Kafka replication: 50ms - 2 minutes.
>
> Designing for eventual consistency:
> Make all read model queries idempotent (re-running produces
> same result).
> Make all projections rebuilable (can replay from event
> history if projection is corrupted).
> Monitor projection lag (Kafka consumer lag = proxy for
> projection staleness).
> Set SLOs on consistency windows (projection must be within
> 5 seconds of write model).
>
> When eventual consistency is NOT acceptable:
> Financial transactions where user expects immediate balance update.
> Inventory reservation where overselling must be prevented.
> Fix: use synchronous consistency for these operations (or
> distributed locks, or optimistic concurrency in the DB).

**Blank Mind Recovery:**

**(1) Restate:** "Eventual = consistent eventually, not immediately.
Handle read-your-own-writes via optimistic UI or direct write DB reads."

---

### ⚖️ Comparison Table

| Consistency Model | Latency | Availability | Use Case |
|------------------|---------|-------------|---------|
| Strong (sync) | Higher | Lower (cascades) | Financial, inventory |
| Eventual (async events) | Lower | Higher | Order lists, notifications |
| Causal (per-session) | Medium | Medium | User profile, shopping cart |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | What eventual consistency means in practice |
| Senior | 7 min | Read-your-own-writes + UI strategies + SLOs |
| Staff | 12 min | Designing systems that are correct under eventual consistency |

**[DEBUGGING] Users are reporting that orders they just placed
do not appear in their order history. The bug is intermittent.
How do you diagnose and fix it?**
`[SENIOR]`

*Why they ask:* Tests ability to connect eventual consistency
theory to a real production bug.

*Likely follow-up:* "The order eventually appears after 10 seconds.
Is this acceptable?"

Step 1: Reproduce. After placing an order, immediately poll
`GET /orders`. Check whether the new order is present.
If it appears after 5-10 seconds: this is an eventual
consistency window (projection lag), not data loss.

Step 2: Measure the consistency window.
Add a metric: time from order event publish to projection update.
`order_projection_lag_seconds` histogram.
Current P99 is 8 seconds. Spec says 3 seconds.

Step 3: Find the cause.
Kafka consumer lag: `kafka-consumer-groups.sh --describe
--group order-projection-service`.
If lag is growing: consumer is slow (slow DB writes or DB contention).
If lag is normal: projection write is slow (check DB connection pool).

Step 4: Fix the immediate user experience.
Add `read-your-own-writes` behavior:
After `POST /orders`, return the order ID.
`GET /orders/{id}` reads from the write DB (not projection).
The order list `GET /orders` continues to use the projection.
The user's just-placed order page shows immediate data.
The order list catches up within 3 seconds.

Step 5: Reduce projection lag.
Optimize the projection update: batch DB writes (100 events
at once vs 1 by 1). Use connection pool (HikariCP) correctly.
Target: projection lag < 1 second.

*What separates good from great:* Distinguishing between
"user sees stale data" (UX problem solvable by read-your-own-writes)
and "data is lost" (a real bug) - and fixing the root cause
(projection lag) while also improving the UX in the short term.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Pattern selection + decision framework |
| System Design | Eventual consistency design + CQRS + read-your-own-writes |
| Bar Raiser | Consistency models + systematic diagnosis methodology |
