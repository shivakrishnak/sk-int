---
layout: default
title: "Messaging - L3 Event Patterns"
parent: "Messaging and Event-Driven"
grand_parent: "SK Interview"
nav_order: 5
permalink: /messaging/l3-event-patterns/
---

# Event Sourcing Pattern

🎯 Interview Weight: very high - Event sourcing is a Staff+
architectural pattern that every senior must know deeply.

---

### 🎯 Model Answer

**30 seconds:**
> Event Sourcing: instead of storing current state (current balance),
> store the sequence of events that led to it (Deposited $100,
> Withdrew $30, Deposited $50). Current state is derived by
> replaying events. Benefits: complete audit trail, temporal queries
> (state at any past time), event replay for new projections.
> Trade-offs: eventual consistency, projection latency, snapshot
> management for long event histories.

**3 minutes (Senior):**
> Event sourcing mechanics:
>
> Event store vs relational database:
> Relational DB: `accounts` table with `balance=120`.
> Write: `UPDATE accounts SET balance=120`.
> History: lost (only current state visible).
>
> Event store: `account_events` table.
> Events: `AccountCreated{id=1}`, `Deposited{amount=100}`,
> `Withdrew{amount=30}`, `Deposited{amount=50}`.
> Current state: replay all events for `account_id=1`.
> `balance = 0 + 100 - 30 + 50 = 120`.
>
> Command vs Event:
> Command: intent to do something (DepositMoney command).
> Can be rejected (insufficient funds).
> Event: something that happened (MoneyDeposited).
> Immutable. Cannot be rejected (it already happened).
>
> Projection (read model):
> Replaying all events for every read is too slow at scale.
> Projection: a materialized view computed from events.
> `balance_projection` table: updated as events arrive.
> Reads from projection = fast. Events are the write-path.
>
> Snapshot:
> Account with 10 years of events has 100,000 events.
> Replaying all 100,000 to compute balance is slow.
> Snapshot: periodically save computed state as a snapshot.
> On replay: start from latest snapshot (e.g., event 90,000)
> and replay only the remaining 10,000 events.
>
> Event store options:
> EventStoreDB: purpose-built event store with streams.
> PostgreSQL: `events` table with `aggregate_id`, `sequence`,
> `event_type`, `payload`. Works for moderate scale.
> Kafka: topics as event streams. Limited querying.

**Blank Mind Recovery:**

**(1) Restate:** "Event sourcing: events ARE the data. State is derived
by replay. Benefits: audit trail + temporal queries. Cost: snapshot complexity."

---

### 💻 Code Example

```java
// BAD: traditional state update loses history
@Transactional
public void deposit(String accountId, BigDecimal amount) {
    Account account = repo.findById(accountId);
    account.setBalance(account.getBalance().add(amount));
    repo.save(account);
    // LOST: who deposited, when, what transaction ID
}

// GOOD: event sourcing - store the event, derive state
@Transactional
public void deposit(String accountId, BigDecimal amount,
                    String transactionId) {
    // 1. Load current state from events
    Account account = reconstitute(
        eventStore.getEvents(accountId)
    );

    // 2. Apply business rules
    account.validateDeposit(amount);  // throws if invalid

    // 3. Create and persist the event
    MoneyDeposited event = new MoneyDeposited(
        accountId, amount, transactionId,
        Instant.now(), account.nextSequence()
    );
    eventStore.append(accountId, event);

    // 4. Update projection asynchronously (eventual)
    eventPublisher.publish(event);
}

// Event handler updates the read projection
@EventHandler
public void on(MoneyDeposited event) {
    AccountSummary summary = summaryRepo.findById(
        event.getAccountId()
    );
    summary.setBalance(
        summary.getBalance().add(event.getAmount())
    );
    summaryRepo.save(summary);
}
```

> **Code walkthrough:** The bad example overwrites state and
> loses all history. The good example appends an immutable event
> to the event store. The `reconstitute` call replays all events
> for the account to derive current state before the command runs.
> After persisting the event, an event handler updates the
> read projection asynchronously (eventual consistency).
> The immutability of events means any audit, compliance, or
> debugging query can be answered by replaying from any point.

---

### ⚖️ Comparison Table

| Aspect | Traditional CRUD | Event Sourcing |
|--------|-----------------|---------------|
| Storage | Current state | All events |
| History | None | Complete |
| Temporal query | Complex (audit tables) | Native |
| Read performance | Fast | Projection required |
| Complexity | Low | High |
| Use when | Standard CRUD | Financial, audit-heavy |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Event vs command + projection + snapshot |
| Staff | 12 min | EventStoreDB vs Kafka + eventual consistency implications |

**[BEHAVIORAL] Tell me about a situation where you would NOT
use event sourcing.**
`[STAFF]`

*Why they ask:* Tests judgment - most engineers who know event
sourcing over-apply it.

*Likely follow-up:* "What are the operational challenges you
experienced?"

Event sourcing is not appropriate for:
(1) CRUD-heavy systems with no audit requirements. A product
catalog where products are simply updated has no need for a
history of all updates. Event sourcing adds complexity for
no benefit.
(2) Simple read-heavy systems. If the primary use case is
displaying data from a DB, event sourcing adds latency
(projection updates) without benefit.
(3) Small teams without operational maturity. Event sourcing
requires snapshot management, projection rebuilding, schema
evolution for events (immutable events must be versioned),
and debugging of projection consistency bugs. A 2-person team
will spend more time managing the event store than building
features.
(4) When strong consistency is required for reads. Projections
are eventually consistent. If a read immediately after a write
must reflect the write: event sourcing requires synchronous
projection updates (negating the benefits) or accepting
the consistency window.

Event sourcing is compelling when:
- Full audit trail is a compliance requirement (financial, healthcare).
- Temporal queries are needed ("what was the state 3 months ago?").
- The system has multiple read models that are added over time
  (replay events to build new projections retroactively).

*What separates good from great:* Knowing that event sourcing
is a specialized tool, not a default architecture.

---

---

# Outbox Pattern

🎯 Interview Weight: very high - Outbox pattern solves the
dual-write problem. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> The dual-write problem: you need to write to your database
> AND publish a message atomically. If you write to DB first and
> the message broker fails: DB updated but event not published.
> Downstream systems miss the event. Outbox pattern: write the
> event to an `outbox` table in the same DB transaction as the
> business data. A separate process (outbox relay) reads from
> the outbox table and publishes to the broker. Guarantees: DB
> write and event publish succeed or both fail together.

**3 minutes (Senior):**
> Outbox pattern implementation:
>
> The problem:
> ```java
> orderRepo.save(order);          // DB write
> kafkaProducer.send(event);      // Kafka send - can fail!
> ```
> If Kafka is temporarily unavailable: order is saved but
> event never published. Payment service never triggered.
>
> Outbox solution:
> ```java
> @Transactional
> public void createOrder(Order order) {
>     orderRepo.save(order);
>     // Write event to outbox in SAME transaction
>     outboxRepo.save(new OutboxEvent("OrderPlaced", order));
> }
> // ACID: either both succeed or both roll back
> ```
>
> Outbox relay (separate process):
> Option A: polling-based relay.
> Background thread polls `outbox` table every 100ms.
> Fetches unprocessed events. Publishes to Kafka.
> Marks as processed. Low latency (100ms overhead).
> Simple but polling overhead on DB.
>
> Option B: Debezium (Change Data Capture):
> Reads from PostgreSQL WAL (write-ahead log).
> Every INSERT to `outbox` table is captured as a CDC event.
> Debezium publishes to Kafka. No polling. Low overhead.
> Sub-second latency. Kafka Connect connector.
>
> Idempotency consideration:
> Relay may publish the same event twice (at-least-once).
> Include a unique `event_id` in every published event.
> Consumers must be idempotent.
>
> Outbox cleanup:
> Processed events accumulate. Periodically delete processed
> outbox events older than 7 days.

**Blank Mind Recovery:**

**(1) Restate:** "Outbox: write event to DB table in same transaction.
Relay publishes from DB to broker. Solves dual-write atomicity."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Dual-write problem + Outbox implementation |
| Staff | 10 min | Debezium CDC + idempotency + cleanup strategy |

---

---

# Saga Pattern for Distributed Transactions

🎯 Interview Weight: very high - Sagas are the primary pattern
for distributed transactions in microservices.

---

### 🎯 Model Answer

**30 seconds:**
> A Saga is a sequence of local transactions, each publishing an
> event that triggers the next step. If a step fails, compensating
> transactions undo previous steps. Two implementations:
> Choreography (event-driven, services react to events) and
> Orchestration (central coordinator directs services).
> Sagas achieve eventual consistency without distributed
> 2-phase commit (which is impractical in microservices).

**3 minutes (Senior):**
> Order fulfillment Saga example:
>
> Steps: CreateOrder -> ReserveInventory -> ChargePayment ->
>        SendConfirmation -> COMPLETED
>
> Compensation on failure:
> If ChargePayment fails:
> - CompensateInventory (release reserved stock)
> - CancelOrder (mark order as cancelled)
>
> Choreography implementation:
> OrderService: emits `OrderCreated`. No central coordinator.
> InventoryService: consumes `OrderCreated`, reserves stock,
> emits `InventoryReserved`.
> PaymentService: consumes `InventoryReserved`, charges card,
> emits `PaymentCharged` or `PaymentFailed`.
> On `PaymentFailed`: InventoryService compensates by releasing stock.
> OrderService marks order cancelled.
> Pros: no single point of failure, simple.
> Cons: hard to track overall saga state, debugging complex.
>
> Orchestration implementation:
> OrderOrchestrator (state machine) manages the flow.
> Calls InventoryService -> waits for response.
> Calls PaymentService -> waits for response.
> On failure: calls compensation endpoints explicitly.
> Pros: clear saga state, easy to debug, one place to change flow.
> Cons: orchestrator is a coordination bottleneck.
>
> Saga pitfalls:
> Partially applied saga: compensation fails. Need idempotent
> compensations and retry with Outbox.
> Read isolation: mid-saga state is visible (order created but
> not yet paid). Handle with a "pending" state in the UI.
> Long-running saga: multi-minute sagas may leave resources
> locked. Add timeouts and compensating transactions.

**Blank Mind Recovery:**

**(1) Restate:** "Saga: sequential local transactions with compensation
on failure. Choreography = events. Orchestration = central coordinator."

---

### ⚖️ Comparison Table

| Aspect | Choreography | Orchestration |
|--------|-------------|--------------|
| Coordination | Distributed (events) | Centralized (orchestrator) |
| Debugging | Hard (trace events) | Easy (orchestrator state) |
| Coupling | Loose | Moderate |
| Failure visibility | Low | High |
| Single point of failure | No | Orchestrator |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Choreography vs orchestration + compensation |
| Staff | 12 min | Saga state management + partial failure recovery |

---

---

# CQRS with Event-Driven Architecture

🎯 Interview Weight: high - CQRS is commonly paired with Event
Sourcing and EDA. Expected at senior level.

---

### 🎯 Model Answer

**30 seconds:**
> CQRS (Command Query Responsibility Segregation) separates
> the write model (commands: create, update) from the read model
> (queries: projections, views). Write model: optimized for
> consistency (single source of truth, normalized). Read model:
> optimized for queries (denormalized, pre-joined). Events from
> the write model update the read model asynchronously. Result:
> reads are fast (query optimized), writes are consistent.

**3 minutes (Senior):**
> CQRS implementation with event-driven updates:
>
> Write side (command model):
> Handles commands: `PlaceOrder`, `CancelOrder`, `UpdateAddress`.
> Validates business rules. Writes to normalized DB (or event store).
> Publishes domain events on state changes.
>
> Read side (query model):
> Multiple read models optimized for different queries:
> `order_summary_view`: denormalized order with customer name,
> total, status. Used for order list UI.
> `order_detail_view`: full order with all items, shipments.
> Used for order detail page.
> Updated by consuming domain events from the write side.
>
> Example flow:
> 1. `PlaceOrder` command -> OrderService (write side).
> 2. OrderService validates, writes to orders DB.
> 3. Publishes `OrderPlaced` event to Kafka.
> 4. OrderProjectionService consumes `OrderPlaced`.
> 5. Updates `order_summary_view` and `order_detail_view`.
> 6. UI reads from `order_summary_view` (fast, no joins).
>
> Read model options:
> Same DB, different tables: simple, transactionally consistent.
> Separate read DB (Elasticsearch, Redis): optimized for search
> or caching. Accepted eventual consistency on read side.
>
> CQRS without event sourcing:
> CQRS and event sourcing are independent patterns.
> CQRS with a traditional DB: write to normalized tables,
> maintain denormalized read views (updated in same transaction
> or via CDC).

**Blank Mind Recovery:**

**(1) Restate:** "CQRS: write model = consistency, read model = query speed.
Events bridge the two. Reads are eventually consistent."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Write vs read model separation + event updates |
| Staff | 8 min | Multiple read models + read model technology choices |

---

---

# Exactly-Once Semantics

🎯 Interview Weight: very high - Exactly-once is the hardest
distributed systems guarantee. Deep understanding expected.

---

### 🎯 Model Answer

**30 seconds:**
> Exactly-once semantics means each message is processed exactly
> once - no loss, no duplicates. Achievable within Kafka Streams
> (read-process-write in one Kafka transaction). NOT easily
> achievable across external systems (Kafka + PostgreSQL + Stripe)
> without additional design. The practical solution: at-least-once
> delivery + idempotent consumers = effectively exactly-once
> from a business logic perspective.

**3 minutes (Senior):**
> Exactly-once in Kafka:
>
> Idempotent producer:
> `enable.idempotence=true`: broker assigns a sequence number
> to each producer + partition. Duplicate sends (retries) are
> detected and discarded. Exactly-once from producer to broker.
>
> Transactional producer:
> `producer.beginTransaction()` + `producer.commitTransaction()`.
> Groups multiple sends (and offset commits) in a single atomic
> transaction. Either all writes happen or none.
>
> Kafka Streams exactly-once:
> Read from input topic, process, write to output topic.
> All in one Kafka transaction. If write fails: transaction
> rolled back, input offset not committed. Message reprocessed.
> No duplicate output records.
>
> Exactly-once with external systems (the hard part):
> Processing a Kafka message and writing to PostgreSQL:
> Cannot wrap Kafka offset commit and PostgreSQL INSERT in a
> single atomic transaction (different systems, no XA).
> Solution: Outbox + idempotency.
> Write to PostgreSQL with a unique event_id.
> If reprocessed: PostgreSQL constraint rejects the duplicate
> (idempotent write). Same business effect.
> This is "effectively exactly-once" - not mathematically
> exactly-once but correct from a business perspective.
>
> Two-phase commit (XA) - why not used:
> XA transactions span multiple systems (Kafka + DB).
> Slow (synchronous coordination), operationally complex,
> rarely supported in modern cloud databases.
> Practical systems avoid XA entirely.

**Blank Mind Recovery:**

**(1) Restate:** "True exactly-once: within Kafka only (transactions).
Cross-system: use at-least-once + idempotent consumer = effectively exactly-once."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 6 min | Kafka EOS + transactional producer |
| Staff | 12 min | Cross-system exactly-once + XA trade-offs |

**[TRADE-OFF] When would you choose exactly-once semantics in
Kafka over at-least-once?**
`[SENIOR]`

*Why they ask:* Exactly-once has real overhead. Tests whether
candidate knows when the cost is justified.

*Likely follow-up:* "What is the performance impact of enabling
transactions?"

Exactly-once is justified when:
(1) Financial calculations that must not be doubled.
Processing account balance updates: duplicate credit/debit
has real-world monetary impact. Idempotency with DB unique
constraints works, but Kafka EOS provides the guarantee at
the messaging layer without DB involvement.
(2) Kafka Streams aggregations (stateful). Counting events,
summing totals in a windowed aggregation: duplicates corrupt
the aggregate. Kafka Streams with exactly-once is the correct choice.
(3) The consumer is not easily made idempotent. Some side
effects (calling a third-party API that charges per call,
sending an SMS) cannot be made idempotent. Kafka EOS
prevents the message from being reprocessed after successful output.

When to stick with at-least-once:
(1) High-throughput pipelines where the performance cost
of transactions (10-30% throughput reduction) is significant.
(2) Consumers that are naturally idempotent (upsert to DB,
setting absolute values not incrementing).
(3) Cross-system flows (Kafka + external DB) where Kafka EOS
cannot cover the full operation anyway.

Performance impact: enabling `exactly_once` on Kafka Streams
reduces throughput by approximately 10-30% in benchmarks.
The coordination overhead (transaction markers, EpochID) is
the cost.

*What separates good from great:* Knowing that exactly-once
within Kafka does not help if the downstream write is to an
external system - you need idempotency there regardless.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Event sourcing mechanics + outbox implementation |
| System Design | Saga choreography vs orchestration |
| Bar Raiser | Exactly-once internals + CQRS trade-offs |
