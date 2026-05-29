---
layout: default
title: "System Design - L4 Event-Driven"
parent: "System Design"
grand_parent: "SK Interview"
nav_order: 8
permalink: /system-design/l4-event-driven/
---

# System Design - L4 Event-Driven

---

# Event Sourcing and CQRS

---
id: SSD-016
title: Event Sourcing and CQRS
category: System Design
difficulty: ★★★
interview_weight: high
asked_at: Senior/Staff/Principal
seniority: staff
tags: #event-sourcing, #cqrs, #domain-events, #event-store, #read-model
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Event Sourcing: store state as a sequence of immutable events, not current state.
> Current state = replay all events. CQRS: separate the write model (commands)
> from the read model (queries). Combined: command side appends events to the event
> store; query side builds optimized read projections from those events.
> Benefits: full audit log, time travel (state at any point in time), multiple
> read models, easy event-driven integration. Costs: eventual consistency in
> read projections, replay performance, schema evolution complexity.

**3 minutes:**
> Traditional CRUD: store current state, overwrite on update. Lost: what changed,
> when, why. Event Sourcing: append events (OrderPlaced, ItemAdded, PaymentProcessed).
> Current state: fold all events. History: permanent and queryable.
>
> CQRS separates concerns: the write side handles commands (validate, produce events);
> the read side handles queries (pre-computed projections optimized for specific UI needs).
> A single write event can update multiple projections: the order-by-customer view,
> the order-by-status view, the revenue-by-product view - all from the same event.
>
> Production use: DDD aggregates (single consistent unit, event-sourced), axon framework,
> event store DB. Event log as integration bus: services subscribe to the event store
> for integration events (debezium CDC pattern, Kafka as persistent event log).

**Blank Mind Recovery:**

**(1) Restate:** "Event sourcing = don't save current state, save everything that
happened. Current state = replay all events from beginning."

**(2) Why CQRS?** "Writing and reading need different models. Write: validates
business rules. Read: needs fast queries with joins across tables. Separate them."

**(3) Tradeoff:** "Benefit: perfect audit log, multiple read models, events for
integration. Cost: eventual consistency, event schema changes are hard."

---

### 📘 Concept Explanation

**Event Sourcing fundamentals:**

```
Traditional state model:
  Current state: orders table
  UPDATE orders SET status='shipped', shipped_at=NOW()
  WHERE id = 123
  - What was the status before?
  - When was it changed?
  - Why was it changed?
  - By whom?
  -> All lost (unless you add separate audit table)

Event Sourcing model:
  Events append-only log:
  [
    {id:1, type:"OrderPlaced", orderId:123, items:[...], at:"10:00"},
    {id:2, type:"ItemAdded", orderId:123, itemId:456, at:"10:05"},
    {id:3, type:"PaymentProcessed", orderId:123, amount:99.99, at:"10:10"},
    {id:4, type:"OrderShipped", orderId:123, carrier:"FedEx", at:"11:00"}
  ]

  Current state = fold(events):
    start with empty order
    apply OrderPlaced: {status: "placed", items: [...]}
    apply ItemAdded: {items: [..., newItem]}
    apply PaymentProcessed: {paid: true, amount: 99.99}
    apply OrderShipped: {status: "shipped", carrier: "FedEx"}

  State at 10:07: replay events 1-2 only
    {status: "placed", items: [..., newItem], paid: false}

Benefits:
  Complete history: every state transition is recorded
  Time travel: state at any point in time
  Audit log: who changed what when (built-in)
  Event replay: rebuild projections from scratch
  Multiple projections: different views from same events
  Event-driven integration: publish events to other services
```

**CQRS architecture:**

```
Without CQRS:
  Single model handles:
    Writes: business validation + persistence
    Reads: complex joins, aggregations, pagination
  Problem: write model (normalized, validated) != read model (denormalized, fast)
  Tradeoffs: optimize for write -> slow reads, optimize for read -> write risk

With CQRS:
  Write side (Command side):
    Receives commands: PlaceOrder, AddItem, ProcessPayment
    Validates: business rules, invariants
    Produces: domain events (OrderPlaced, ItemAdded, PaymentProcessed)
    Stores: events to event store (append-only)

  Read side (Query side):
    Reads events from event store (or message bus)
    Builds projections (materialized views):
      orders-by-customer: {customerId -> [order summaries]}
      orders-by-status: {status -> count}
      revenue-by-day: {date -> total revenue}
    Stores projections in read-optimized stores:
      Elasticsearch: full-text search projection
      Redis: current order status (fast lookup)
      PostgreSQL: complex reporting queries

  Separate stores:
    Write store: event store (append-only, optimized for writes)
    Read store: projections (optimized for specific query patterns)

  Eventual consistency:
    Event: emitted by write side
    Projection update: asynchronous (consumer processes event)
    Gap: 10-500ms typically (depends on consumer throughput)
    Trade-off: read may show stale data briefly after write
```

---

### 💻 Code Example

```java
// Event Sourcing with Axon Framework (Spring Boot)
// Domain model: Order aggregate

// Commands (intent to change state):
public record PlaceOrderCommand(
    @TargetAggregateIdentifier String orderId,
    String customerId,
    List<OrderItem> items) {}

public record AddItemCommand(
    @TargetAggregateIdentifier String orderId,
    OrderItem item) {}

// Domain events (what happened):
public record OrderPlacedEvent(
    String orderId,
    String customerId,
    List<OrderItem> items,
    Instant placedAt) {}

public record ItemAddedEvent(
    String orderId,
    OrderItem item,
    Instant addedAt) {}

// Aggregate: handles commands, emits events, applies events to state
@Aggregate
public class OrderAggregate {

    @AggregateIdentifier
    private String orderId;
    private String customerId;
    private List<OrderItem> items = new ArrayList<>();
    private OrderStatus status;

    @CommandHandler
    public OrderAggregate(PlaceOrderCommand cmd) {
        // Validate
        if (cmd.items().isEmpty()) {
            throw new IllegalArgumentException(
                "Order must have at least one item");
        }
        // Emit event (not directly change state)
        AggregateLifecycle.apply(new OrderPlacedEvent(
            cmd.orderId(),
            cmd.customerId(),
            cmd.items(),
            Instant.now()));
    }

    @CommandHandler
    public void handle(AddItemCommand cmd) {
        if (status != OrderStatus.PLACED) {
            throw new IllegalStateException(
                "Cannot add item to order in status: " + status);
        }
        AggregateLifecycle.apply(new ItemAddedEvent(
            orderId, cmd.item(), Instant.now()));
    }

    // Event sourcing handlers: rebuild state from events
    @EventSourcingHandler
    public void on(OrderPlacedEvent event) {
        this.orderId = event.orderId();
        this.customerId = event.customerId();
        this.items = new ArrayList<>(event.items());
        this.status = OrderStatus.PLACED;
    }

    @EventSourcingHandler
    public void on(ItemAddedEvent event) {
        this.items.add(event.item());
    }
}
```

> **Code walkthrough:** The OrderAggregate embodies Event Sourcing + CQRS write side.
> Commands (PlaceOrderCommand) represent intent. The @CommandHandler validates
> business rules (items not empty, status allows operation) and calls
> `AggregateLifecycle.apply()` to emit an event - NOT to directly change state.
> The @EventSourcingHandler methods rebuild state by applying events in sequence.
> Axon Framework stores the emitted events to the event store; on aggregate load,
> it replays all events through the @EventSourcingHandler methods to reconstruct
> current state. This separation ensures the state machine is deterministic:
> same events always produce same state.

```java
// CQRS Read side: event handler builds projection

@Component
@ProcessingGroup("order-projection")
public class OrderProjectionHandler {

    private final OrderSummaryRepository summaryRepo;
    private final RedisTemplate<String, String> redis;

    // Handles events from the event store, builds projections
    @EventHandler
    public void on(OrderPlacedEvent event) {
        // Build order summary for order-list view
        OrderSummary summary = OrderSummary.builder()
            .orderId(event.orderId())
            .customerId(event.customerId())
            .itemCount(event.items().size())
            .totalAmount(calculateTotal(event.items()))
            .status("PLACED")
            .placedAt(event.placedAt())
            .build();

        summaryRepo.save(summary);  // PostgreSQL read model

        // Also update Redis cache for fast status checks
        redis.opsForValue().set(
            "order:status:" + event.orderId(),
            "PLACED",
            Duration.ofHours(24));
    }

    @EventHandler
    public void on(ItemAddedEvent event) {
        // Update projection with new item
        summaryRepo.findByOrderId(event.orderId())
            .ifPresent(summary -> {
                summary.setItemCount(summary.getItemCount() + 1);
                summary.setTotalAmount(
                    summary.getTotalAmount()
                    .add(event.item().getPrice()));
                summaryRepo.save(summary);
            });
    }
}

// Query service (read side):
@Service
public class OrderQueryService {

    private final OrderSummaryRepository summaryRepo;
    private final RedisTemplate<String, String> redis;

    // Simple status query: Redis (fast)
    public String getOrderStatus(String orderId) {
        String cached = redis.opsForValue()
            .get("order:status:" + orderId);
        if (cached != null) return cached;
        return summaryRepo.findByOrderId(orderId)
            .map(OrderSummary::getStatus)
            .orElseThrow(() -> new OrderNotFoundException(orderId));
    }

    // Complex query: orders by customer, paginated
    public Page<OrderSummary> getOrdersByCustomer(
            String customerId, Pageable pageable) {
        return summaryRepo
            .findByCustomerIdOrderByPlacedAtDesc(
                customerId, pageable);
    }
}
```

> **Code walkthrough:** The projection handler is the glue between write and read
> sides. It listens to events from the event store (Axon: @EventHandler, Kafka
> topic, or event bus). When OrderPlacedEvent arrives: it creates a denormalized
> OrderSummary (optimized for list queries) in PostgreSQL AND a Redis cache entry
> for fast status lookups. Same event produces two projections. The query service
> reads projections only (never the event store directly). Consistency is eventual:
> after `PlaceOrderCommand` succeeds, there is a short delay before the projection
> is updated. If the user's next request reads the order list immediately: they
> might not see the new order yet. Design choice: accept this 100-500ms inconsistency
> or use techniques like "read your own writes" (pass the command's event sequence
> number to the query; wait until projection has processed up to that sequence).

```java
// Event Store: replaying events for projection rebuild

@Service
public class ProjectionRebuildService {

    private final EventStore eventStore;
    private final OrderProjectionHandler handler;
    private final OrderSummaryRepository repo;

    /**
     * Rebuild order projection from scratch.
     * Use when: projection schema changed, data corrupted,
     * adding new projection type.
     */
    public void rebuildOrderProjection() {
        // Truncate existing projection
        repo.deleteAll();

        // Replay ALL OrderPlacedEvent and ItemAddedEvent
        // from the beginning of time
        DomainEventStream stream = eventStore.readEvents(
            "order", // aggregate type
            TrackingToken.createHead());  // from beginning

        stream.forEachRemaining(event -> {
            if (event.getPayload() instanceof OrderPlacedEvent e) {
                handler.on(e);
            } else if (event.getPayload()
                    instanceof ItemAddedEvent e) {
                handler.on(e);
            }
        });

        log.info("Projection rebuild complete");
    }
}
```

> **Code walkthrough:** Projection rebuild is a unique Event Sourcing capability.
> When the read model schema changes (add a new column to OrderSummary): truncate
> the projection table, replay all events. The same events flow through the updated
> projection handler, producing the new schema. No manual data migration needed.
> This is also used when adding a new projection: replay all history, new projection
> catches up from the beginning. The tradeoff: replay time scales with event history
> size. 10M events at 100K events/second = 100 seconds rebuild. During rebuild:
> read model shows stale data. Solution: maintain old projection while rebuilding
> new one; swap atomically when rebuild is complete.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Event Sourcing means instead of saving the current state of an object, you save
> every change that happened. Like a bank account: instead of storing "balance: $100",
> you store "deposited $50, withdrew $30, deposited $80". Current balance = add them all up.
> CQRS separates the code for changing data (commands) from the code for reading data
> (queries). They can use different databases optimized for their specific use.

**Senior / Staff:**
> The operational challenge I've seen teams underestimate: event schema evolution.
> In CRUD: add a column, the schema is updated. In Event Sourcing: events are
> immutable and permanent. If you change an event schema, all historical events
> must be handled. Three strategies: upcasting (transform old format to new on read,
> Axon supports this natively), event versioning (OrderPlacedEventV1, V2 as separate
> types, handlers for both), tombstoning (soft-delete GDPR-sensitive events by
> encrypting per-user and deleting the key). The GDPR + event sourcing tension:
> "right to be forgotten" vs immutable history. Solution: encrypt user-sensitive
> fields with a per-user key; GDPR deletion = delete the key (crypto-shredding).
> Historical events remain but are unreadable.

---

### ⚠️ Common Misconceptions

**Misconception: "CQRS requires Event Sourcing."**
CQRS (separate write model from read model) is independent of Event Sourcing.
You can have CQRS with traditional CRUD: write model normalizes and validates,
read model is a set of pre-computed views (materialized views in PostgreSQL,
Elasticsearch index). Event Sourcing is independent too: you can event-source
without CQRS (one model that both stores events and derives current state from
them). They complement each other well (most Event Sourcing implementations use
CQRS for read projections) but are not the same pattern.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Projection falls behind event store (consumer lag)**
Symptom: user sees stale data (order placed but list still shows old orders);
read model lag > 10 seconds in monitoring.
Cause: projection consumer is slower than event production rate, or consumer
crashed and is catching up from a backlog.
Diagnosis: check consumer group lag in Kafka/event bus. Check event handler
processing time. Check for slow DB writes in projection handler.
Fix: scale out projection consumers (if projections are independent per partition);
optimize projection update queries (bulk updates); add DB indexes for projection
writes. Alert on: consumer lag > 1000 events (or lag > acceptable staleness window).

---

### 🎯 Interview Deep-Dive

**Timing:** Hard ★★★ - 12 questions.

---

#### Q1 - What problem does Event Sourcing solve that traditional CRUD can't?

```
Problems with CRUD state model:

1. Lost history:
  UPDATE orders SET status = 'cancelled' WHERE id = 123
  Before: status was 'shipped'? 'placed'? When? Who?
  Gone. Only today's state survives.

2. Audit is an afterthought:
  Added separately: audit_log table
  Maintained independently: easy to miss in some code paths
  Not authoritative: state + audit can diverge

3. Temporal queries impossible:
  "What was our inventory on Black Friday 2023?"
  CRUD: impossible (state overwritten)
  Event Sourcing: replay events up to that date

4. Integration via state (polluted):
  Other services: poll the DB for changes (slow, coupled)
  Event Sourcing: events are the change notification

Event Sourcing solves:
  Built-in audit log: every event is a record of change
  Time travel: replay to any point
  Event-driven integration: events flow to subscribers
  Projection freedom: derive any view from the events

What CRUD still beats Event Sourcing at:
  Simplicity: CRUD is easier to reason about
  Query flexibility: events need projections (eventual consistency)
  Event schema evolution: hard (events are immutable forever)
  Storage: events grow without bound vs current state (static size)
```

*What separates good from great:* The "storage grows without bound" concern is
real at scale. An order aggregate might have 10-20 events over its lifetime.
At 1M orders/day: 10-20M events/day. After 3 years: 10-20B events. Storage:
at 1KB per event: 10-20TB. Solutions: (1) snapshotting - periodically save
current state as a snapshot; on load, use latest snapshot + events since snapshot
(reduces replay time from all events to events since last snapshot). (2) archiving:
move old events to cold storage (S3 Glacier) after some period; only recent
events stay hot. (3) event store partitioning: different retention per aggregate type.

---

#### Q2 - How do you handle eventual consistency in CQRS from a user experience perspective?

Eventual consistency in CQRS UI: the read model lags behind the write model.

```
Problem:
  User: places order (command side processes, writes event)
  User: immediately navigates to "my orders" page
  Query: reads from projection (which hasn't processed event yet)
  Result: new order not shown (seems like it failed)
  User: confused, frustrated, re-submits

Solutions:

1. Optimistic UI update (client-side):
  Client: on command success, immediately add order to local state
  UI: shows the new order with "pending confirmation" state
  Projection catches up: UI reconciles from server state
  User sees: instant feedback, smooth experience
  Cost: UI becomes stateful (more complex)

2. Polling until consistent:
  After command: poll "is my projection up to date?" endpoint
  Server: returns event_sequence_number processed by projection
  Client: polls until sequence >= command's sequence
  Then: fetch full result
  Cost: extra round trips, complex client logic

3. "Read-your-own-writes" with version tracking:
  Command API response: includes event_id or sequence_number
  Query API: accepts expected_min_sequence parameter
  Query side: waits until projection has processed up to that sequence
  Returns result only when consistent for this user
  Cost: query side must track processed sequence per request

4. Synchronous projection update for critical reads:
  Designate some queries as "strong consistent":
    GET /orders/{id} (directly after creation: need to show it)
  For strong consistent queries: read from command side (write DB)
    or wait for projection to catch up synchronously
  Eventual consistency only for list views / reports

Design principle:
  Identify: which operations NEED read-your-own-writes?
  (User creates resource, then views it immediately)
  Only those: apply consistency solution
  Others: accept eventual consistency (background refresh)
```

*What separates good from great:* The Optimistic UI approach (client manages
its own state locally) is the most user-friendly solution and doesn't add
server-side complexity. The key insight: from the user's perspective, "eventual
consistency" happens in the background while they see the local state. When the
server catches up: the local state is confirmed or corrected (if the command
actually failed). This is the pattern used by Google Docs, Trello, Linear -
all optimistic UI over eventually consistent backends. The failure case (command
failed but UI showed success): show an error notification and revert the local
state. Rare, but must be handled gracefully.

---

#### Q3 - How do you evolve event schemas over time?

Event schema evolution: events are immutable and permanent - changes are hard.

```
Event versioning strategies:

Strategy 1: Upcasting (transform on read)
  Old event (V1):
    OrderPlacedEvent { orderId, customerId, items }
  New event (V2):
    OrderPlacedEvent { orderId, customerId, items, currency }

  Upcaster: converts V1 to V2 when reading from event store
    function upcast(v1: OrderPlacedEventV1): OrderPlacedEventV2 {
      return { ...v1, currency: "USD" }  // default value for old events
    }

  Event handler: only handles V2 (upcaster handles transformation)
  Axon Framework: built-in upcaster chain support

  When to use: additive changes (new optional fields with defaults)

Strategy 2: Event versioning (separate types)
  OrderPlacedEventV1: keep old handler
  OrderPlacedEventV2: new handler with new behavior
  Both handlers active simultaneously
  Existing event store: V1 events stay as V1
  New events: written as V2

  When to use: structural changes (renamed fields, type changes)

Strategy 3: Ignore unknown fields (forward compatibility)
  Jackson: @JsonIgnoreProperties(ignoreUnknown = true)
  New fields: ignored by old handlers (don't break)
  Removed fields: old handlers get null (must be nullable)

Strategy 4: Weak schema (schemaless)
  Events: store as JSON, no enforced schema
  Handler: reads only fields it knows, ignores rest
  Pro: maximum flexibility
  Con: no compile-time safety, data quality risks

Breaking changes to avoid:
  - Rename a field (remove old name, add new: breaks old handlers)
  - Change a field type (string -> int: breaks old handlers)
  - Remove a required field (old handlers may NPE)
  Always add, never remove or rename.
```

*What separates good from great:* The discipline of "always add, never remove
or rename" fields in events is the non-negotiable rule for event sourcing at scale.
Breaking changes require version migration: either an upcaster that transforms
old events to new format on read, or a versioned event type with both old and
new handlers. The Avro schema registry (Confluent) enforces schema compatibility
rules: registered schemas must be backward-compatible (new consumers can read
old data) or forward-compatible (old consumers can read new data). Event
sourcing without a schema registry in production is technical debt: eventually
a breaking change is made accidentally, and replaying history fails.

---

#### Q4 - How do you handle GDPR and the "right to be forgotten" with Event Sourcing?

GDPR + Event Sourcing tension: immutable events vs right to erasure.

```
Problem:
  Event Sourcing: events are immutable and permanent
  GDPR: user can request deletion of their personal data
  Conflict: OrderPlacedEvent contains name, email, address
  Deleting or modifying events: violates Event Sourcing principles

Solutions:

1. Crypto-shredding (most common, recommended):
  Each user: unique encryption key stored in key management (KMS)
  PII in events: encrypted with user's key before storing
  Event store: stores encrypted PII (ciphertext)
  Normal operation: decrypt on event read (KMS call)

  GDPR deletion request:
    Delete user's encryption key from KMS
    Events remain in event store (structure intact)
    PII: permanently unreadable (crypto-shredded)
    Logs and projections: clear as well

  Implementation:
    User created: KMS.createKey(userId) -> keyId
    Event storage: encrypt(pii_fields, KMS.getKey(userId))
    Event read: decrypt(encrypted_pii, KMS.getKey(userId))
    GDPR request: KMS.deleteKey(userId)

  Tradeoffs:
    Pro: events remain in store (no structural change)
    Pro: audit log intact (minus PII which is legally correct)
    Con: every event read requires KMS call (latency)
    Optimize: cache decrypted fields (TTL = user session)

2. Separate PII store (pointer pattern):
  Events: store only non-PII + pointer to PII record
    OrderPlacedEvent { orderId, userId,
                       piiRef: "pii:user:123" }
  PII store: separate DB with user personal data
  GDPR: delete from PII store -> events have dangling references
  Event handler: follows reference (may get null post-deletion)

  Tradeoff: simpler than crypto-shredding, but breaks event completeness
```

*What separates good from great:* Crypto-shredding is the production pattern
recommended by Martin Kleppmann and used by companies like Zalando (who published
their approach). The key management service (AWS KMS, HashiCorp Vault) stores
the per-user keys with their own access controls and audit logs. When the user
requests deletion: the key is deleted; all their encrypted PII in the event
store becomes garbage. This satisfies GDPR "right to erasure" because the data
is practically unreadable without the key. Document this in your privacy policy:
"We permanently erase your data by destroying the encryption key used to protect
your personal information in our event logs." This is legally defensible.

---

#### Q5 - How do you design snapshots for Event Sourcing?

Snapshots: optimization for aggregates with long event histories.

```
Problem:
  Order aggregate: 500 events (complex order with many changes)
  On every command: replay 500 events -> slow (seconds)
  High-traffic aggregate: performance bottleneck

Solution: periodic snapshots
  Snapshot: saved state of aggregate at a point in time
  Load process:
    1. Find latest snapshot (closest to current)
    2. Load events AFTER snapshot sequence number
    3. Apply events to snapshot state
    Result: current state (much faster)

  Before snapshot:
    Load: events 1-500 -> apply all 500 -> current state
  After snapshot (at event 400):
    Load: snapshot(400) + events 401-500 -> apply 100 -> current state

Snapshot trigger:
  Every N events (e.g., every 50 events):
    if (aggregate.lastEventSequence % 50 == 0) takeSnapshot()
  Time-based: every 24 hours, snapshot all active aggregates
  On shutdown: snapshot all dirty aggregates

Axon Framework snapshot:
  @Component
  public class OrderSnapshotTrigger {
    @Bean
    public SnapshotTriggerDefinition orderSnapshots() {
      // Snapshot every 50 events
      return new EventCountSnapshotTriggerDefinition(
          snapshotter, 50);
    }
  }

Snapshot storage:
  Same event store (as special event type)
  Or separate snapshot table/collection

Snapshot versioning:
  Snapshot taken with v1 aggregate code
  Code updated: aggregate fields changed
  Snapshot may be incompatible
  Solution: version snapshots
    Snapshot {version: 1, state: {...}}
    On load: if snapshot.version != current: ignore snapshot, replay all
    Or: upcaster for snapshots (same as events)
```

*What separates good from great:* Snapshot invalidation after code deployment
is the operational gotcha. If you deploy new aggregate code that changes state
fields, existing snapshots may be incompatible. The safe approach: version
your snapshots alongside your aggregate code. When you change the aggregate
significantly (new fields, renamed fields): increment the snapshot version.
On load: if snapshot version doesn't match current aggregate version, discard
the snapshot and replay from the beginning. The performance hit (one slow load
after deployment for each active aggregate) is better than corrupted state from
applying a new event handler to an old-format snapshot.

---

#### Q6 - How does Event Sourcing interact with microservices?

Event Sourcing in microservices: events as integration contracts.

```
Domain events vs integration events:
  Domain events: internal to aggregate (OrderAggregate.ItemAdded)
    Purpose: rebuild state within the aggregate
    Scope: private to the bounded context
    Schema: can change freely (not exposed externally)

  Integration events: published to other services
    Purpose: notify other services of significant state changes
    Scope: published API (must be stable, versioned)
    Schema: backward-compatible evolution required
    Examples: OrderShipped, PaymentProcessed, UserRegistered

  Pattern: domain events -> integration events
    Command handler: applies domain events
    Saga/process manager: listens to domain events
    Saga: publishes integration events (after domain logic completes)
    Separation: domain model is isolated from integration concerns

Event publishing patterns:

1. Transactional Outbox:
  Command handler:
    - Write event to event store (main transaction)
    - Write integration event to outbox table (same transaction)
    Both: same DB transaction (atomic)
  Outbox publisher:
    - Polls outbox table
    - Publishes to Kafka
    - Marks as published
  Guarantee: events are published if and only if the command succeeded

2. Event store as message bus:
  Event store: append events
  Subscribers: consume from event store directly
  (EventStoreDB, Axon Server: support subscriptions)
  No separate Kafka needed for internal events
  Kafka: only for external integration (different SLA)

3. Saga (Process Manager) pattern:
  Multi-service workflow: OrderPlaced -> Reserve Inventory
                          -> Process Payment -> Ship Order
  Saga: listens to events, sends commands to coordinate
  Each step: produces event (either success or failure)
  Compensating transactions: on failure, undo previous steps
  OrderPlaced -> InventoryReserveFailed: cancel order + notify customer
```

*What separates good from great:* The Transactional Outbox pattern solves the
dual-write problem: writing to the event store AND publishing to Kafka in the same
operation. Without it: event store write succeeds, Kafka publish fails -> event
lost (integration service never notified). With outbox: event store and outbox
are in the same transaction; outbox publisher is a retry-able operation that
guarantees eventual delivery. The outbox publisher uses debezium (CDC) or polling
to publish messages atomically from the outbox table. This is the production
pattern used by companies like Grab, Uber for their domain event pipelines.

---

#### Q7 - How do you build a projection efficiently for billions of events?

Large-scale projection building: performance at extreme event volumes.

```
Problem:
  Event store: 10 billion events accumulated over 5 years
  New projection needed (analytics for new feature)
  Naive replay: 10B events * 0.1ms each = 1 million seconds (11 days)

Optimization strategies:

1. Parallel replay:
  Partition events by aggregate ID (hash)
  Multiple consumers: each handles a partition
  N consumers: N times faster
  Example: 100 consumers -> 11 days / 100 = ~2.7 hours

  Caution: order within aggregate must be preserved
  Partition key: aggregate ID (not random)
  Each consumer: processes one aggregate's events in order

2. Event filtering:
  New projection only cares about OrderShippedEvent
  Don't replay: OrderPlacedEvent, ItemAddedEvent (irrelevant)
  Event store: support event type filtering
  EventStoreDB: $et-{EventType} stream (events by type)
  Result: 100M shipping events (vs 10B all events)

3. Batch processing:
  Projection update: bulk inserts (not one-by-one)
  Single event: INSERT -> 0.1ms
  Batch of 1000: INSERT (batch) -> 20ms (200x faster)
  Projection handler: collect 1000 events, bulk insert

4. Skip to snapshot:
  Take periodic aggregate snapshots
  Projection rebuild: start from latest snapshots + recent events
  Not from events 1-10B

5. Dedicated rebuild infrastructure:
  Rebuild: uses separate DB instance (not production read model)
  Rebuild completes: swap traffic to new projection
  Zero downtime, no impact on running system
```

*What separates good from great:* The key insight for large-scale projection
rebuild is that you don't have to rebuild from event zero. If you have
aggregate-level snapshots taken daily, and you need to rebuild a projection
that only cares about the last 30 days: load snapshots from 31 days ago +
only the last 31 days of events. The rebuild time is bounded by the most recent
snapshot interval. The engineering discipline: take regular snapshots of high-event-rate
aggregates as an operational hedge. When you need to rebuild projections or
add new ones: snapshot-based rebuild is 100x faster than full history replay.

---

#### Q8 - What is a Saga and how does it manage distributed transactions?

Saga: long-running distributed transaction using events and compensations.

```
Problem with 2-Phase Commit (2PC) in microservices:
  2PC: all services lock resources until coordinator commits
  Microservices: services owned by different teams, different DBs
  2PC across microservice boundaries: blocking, tight coupling
  Network partition: coordinator crash -> all services locked

Saga: alternative (no distributed lock)
  Decompose transaction into sequence of local transactions
  Each local transaction: publishes event on success
  On failure: execute compensating transactions (undo)

Choreography Saga (event-driven):
  Each service: listens to events, executes action, publishes next event
  No central coordinator
  Order Service: OrderCreated event
  Inventory Service: listens -> ReserveInventory -> InventoryReserved
  Payment Service: listens -> ProcessPayment -> PaymentProcessed
  Shipping Service: listens -> CreateShipment -> ShipmentCreated

  Failure:
  Payment Service: PaymentFailed
  Inventory Service: listens PaymentFailed -> ReleaseReservation
  Order Service: listens PaymentFailed -> CancelOrder

  Pro: decoupled services, no single point of failure
  Con: hard to track overall state (distributed across services)

Orchestration Saga (centralized):
  Saga Orchestrator: knows all steps, sends commands, awaits responses
  OrderSaga:
    1. Send: ReserveInventoryCommand -> await InventoryReservedEvent
    2. Send: ProcessPaymentCommand -> await PaymentProcessedEvent
    3. Send: CreateShipmentCommand -> await ShipmentCreatedEvent
    All done: OrderCompletedEvent

  On failure:
    PaymentFailed: send ReleaseInventoryCommand (compensate step 1)
    Send CancelOrderCommand (mark order cancelled)

  Pro: visible state machine (easy to monitor, debug)
  Con: orchestrator is a dependency (single point of logical coupling)

  Axon Saga:
    @Saga
    public class OrderFulfillmentSaga {
        @StartSaga
        @SagaEventHandler(associationProperty = "orderId")
        public void on(OrderPlacedEvent event) {
            commandGateway.send(
                new ReserveInventoryCommand(event.orderId()));
        }

        @SagaEventHandler(associationProperty = "orderId")
        public void on(InventoryReservedEvent event) {
            commandGateway.send(
                new ProcessPaymentCommand(event.orderId()));
        }

        @EndSaga
        @SagaEventHandler(associationProperty = "orderId")
        public void on(PaymentProcessedEvent event) {
            commandGateway.send(
                new CreateShipmentCommand(event.orderId()));
        }
    }
```

*What separates good from great:* Saga compensating transactions must be
idempotent. If the compensation command is sent twice (retry due to network issue):
the second execution should not double-compensate (don't release inventory twice,
don't charge the user twice). The idempotency key: use the original command ID.
"ReleaseInventoryCommand for orderId 123, caused by PaymentFailed event 456" is
idempotent: if the inventory was already released (second execution): no-op.
Also: compensating transactions can fail too. If ReleaseReservation fails: the
inventory is stuck reserved. Solution: retry with exponential backoff (Saga orchestrator
retries the compensating transaction until success), alerting on persistent failure,
manual intervention for edge cases.

---

#### Q9 - How do you test Event Sourcing systems?

Testing Event Sourcing: given/when/then format matches the model.

```
Aggregate unit testing (Given/When/Then):
  Given: previous events (aggregate's history)
  When: command is executed
  Then: new events emitted OR exception thrown

  Axon Test Fixture:
    @Test
    public void shouldAddItemToPlacedOrder() {
        fixture.given(
            new OrderPlacedEvent(
                "order123", "customer1",
                List.of(existingItem), NOW)
        ).when(
            new AddItemCommand("order123", newItem)
        ).expectSuccessfulHandlerExecution()
         .expectEvents(
            new ItemAddedEvent("order123", newItem, NOW)
         );
    }

    @Test
    public void shouldRejectAddItemToShippedOrder() {
        fixture.given(
            new OrderPlacedEvent(...),
            new OrderShippedEvent(...)  // already shipped
        ).when(
            new AddItemCommand("order123", newItem)
        ).expectException(IllegalStateException.class);
    }

Projection testing:
  Given: stream of events
  When: projection handler processes them
  Then: projection DB has expected state

  @Test
  public void shouldBuildOrderSummary() {
      // Send events to projection handler directly
      handler.on(new OrderPlacedEvent(
          "order123", "customer1",
          List.of(item1), NOW));

      // Assert projection state
      OrderSummary summary =
          repo.findByOrderId("order123").get();
      assertThat(summary.getItemCount()).isEqualTo(1);
      assertThat(summary.getStatus()).isEqualTo("PLACED");
  }

Integration/acceptance testing:
  Full stack: command -> event store -> projection -> query
  Test: place order, verify projection updated
  Async: use Awaitility to wait for projection to catch up

  @Test
  public void endToEnd_placeOrderAndQueryIt() {
      commandGateway.sendAndWait(placeOrderCommand);

      Awaitility.await()
          .atMost(5, SECONDS)
          .untilAsserted(() -> {
              OrderSummary result =
                  queryService.getOrderById("order123");
              assertThat(result).isNotNull();
              assertThat(result.getStatus()).isEqualTo("PLACED");
          });
  }
```

*What separates good from great:* The aggregate unit test pattern (Given/When/Then)
is the key testing technique for Event Sourcing. Unlike mock-based unit tests,
given-when-then tests the actual business logic: "given this history, when this
command, expect these events." This tests the invariant checks, the event emission,
and the state transitions all in one readable test. The test is also documentation:
a table of Given/When/Then scenarios is a precise specification of the aggregate's
behavior. Axon Test Fixture makes this idiomatic. The projection tests ensure
the read model correctly handles all event types. The end-to-end test verifies
the full pipeline with async assertion (Awaitility waits for the projection to
process the event).

---

#### Q10 - What are the costs and when should you NOT use Event Sourcing?

Event Sourcing is not always the right choice.

```
Real costs:

1. Eventual consistency complexity:
  Every UI that shows "the data I just wrote": needs careful design
  "Read your own writes" patterns: add complexity
  Testing: requires async testing patterns (Awaitility, polling)

2. Query complexity:
  CRUD: SELECT * FROM orders WHERE status='shipped' ORDER BY date
  Event Sourcing: need a projection for this query
    (projection must be built, maintained, kept up-to-date)
  Every new query pattern: potentially a new projection

3. Event schema evolution:
  Most complex part in practice
  Immutable events + changing code = upcasters needed
  Team discipline: additive changes only (hard to enforce)

4. Storage growth:
  Events accumulate: 10B events after 3 years
  Snapshots needed for performance
  Archiving strategy needed for storage cost

5. Learning curve:
  New team members: significant ramp-up time
  CRUD is universally understood, Event Sourcing is not
  More cognitive load in code review

When NOT to use Event Sourcing:
  Simple CRUD application: user profile, settings, config
  Report-heavy systems: heavy read queries (projections don't help much)
  High-throughput reference data: product catalog (updated rarely, read often)
  Small teams, fast iteration: complexity cost > benefit early on

When Event Sourcing is the right choice:
  Audit trail is a core product feature (financial, medical, legal)
  Complex domain with many state transitions
  Event-driven microservices (events are integration contracts)
  Multiple views of the same data needed (event drives all views)
  Time-series analysis (how did state evolve?)
```

*What separates good from great:* The "auditability is a core feature" criterion
is the most reliable indicator for Event Sourcing. Financial applications (every
transaction must be auditable), healthcare (every medication change must be logged),
legal (document changes must be traceable): these have regulatory requirements
that Event Sourcing satisfies architecturally. For a basic SaaS CRUD app with
a small team: Event Sourcing adds 3x complexity with little benefit. The team
spends more time building projections than features. Start with simple CRUD;
introduce Event Sourcing when you have specific requirements that justify it
(audit trail, complex domain, event-driven integration). Introduce it per bounded
context (not for the whole system at once).

---

#### Q11 - How does Event Sourcing support temporal queries?

Temporal queries: "What was the state at time T?"

```
Temporal query types:
  Point-in-time: state at specific timestamp
  Period-in-time: all changes within a time range
  As-of-version: state at event sequence N
  Comparison: diff between state at T1 and T2

Event Sourcing implementation:

Point-in-time query:
  All events: have a timestamp (part of event metadata)
  Replay: only events with timestamp <= T

  public OrderAggregate getOrderStateAt(
          String orderId, Instant at) {
      DomainEventStream events = eventStore.readEvents(orderId);
      OrderAggregate snapshot = new OrderAggregate();
      events.forEachRemaining(event -> {
          if (!event.getTimestamp().isAfter(at)) {
              snapshot.handle(event.getPayload());
          }
      });
      return snapshot;
  }

Period-in-time query:
  Events: filter by time range
  Return: all events between T1 and T2 for a given aggregate
  Use: "show me all changes to order 123 between Jan and March"

Projection-based temporal:
  Projection: includes event timestamp in read model
  Time-series projection: (orderId, status, timestamp) tuples
  Query: "how many orders were in 'processing' at any given time?"
    - GROUP BY time bucket, count by status transition

Audit log projection (natural use):
  Every event -> row in audit_log table:
    audit_log (event_id, aggregate_id, event_type, actor,
               payload_summary, occurred_at)
  Query: "all changes to order 123 by user X between date A and B"
    Simple SQL on audit_log table
  Possible only because of Event Sourcing (events are authoritative)
```

*What separates good from great:* Temporal queries are the "killer app" of Event
Sourcing for regulated industries. "What was the patient's medication at 3pm on
March 15th?" In a CRUD system: impossible (the current state overwrote history).
With Event Sourcing: replay events up to 3pm March 15th. In financial systems:
"what was the account balance at the close of business on Dec 31st for the year-end
report?" Trivial with Event Sourcing: replay up to that timestamp. The regulatory
compliance case (finance, healthcare, legal) is strong enough to justify Event
Sourcing's complexity for these domains even if no other benefit were present.

---

#### Q12 - Design an event-sourced e-commerce order system for 1M orders/day.

System design: high-scale event-sourced order processing.

```
Scale requirements:
  1M orders/day = ~12 orders/second average
  Peak: 100 orders/second (flash sale)
  Each order: 5-20 events over lifetime
  Total events: 5M-20M per day

Architecture:

Command side (write path):
  - API Gateway: validates input, routes to command handlers
  - Order command handlers: business validation
  - Event store: EventStoreDB or Axon Server (append-only)
    Write throughput: 10,000 events/sec (well within capacity)
    Storage: 1KB/event * 20M/day = 20GB/day
              Compressed: ~5GB/day
  - Outbox: for publishing integration events to Kafka

Event store choice:
  EventStoreDB: purpose-built event store, native subscriptions
  Kafka: persistent, high-throughput, but not aggregate-centric
  PostgreSQL + append-only table: simpler, good to 100M events

Projection consumers (read path):
  Kafka topic: order events (from outbox publisher)
  Multiple consumer groups (one per projection):
    - order-list-projection: PostgreSQL (customer's order list)
    - order-status-projection: Redis (fast status lookup)
    - analytics-projection: ClickHouse (order analytics)
    - search-projection: Elasticsearch (order search)

  Each consumer: independent, independently scalable
  Lag acceptable: 200-500ms for most projections

Snapshot strategy:
  Take snapshot every 50 events per aggregate
  Snapshot storage: same event store (special event type)
  Load: snapshot + events since snapshot
        (max 50 events to replay at any time)

GDPR:
  PII in events: encrypted with per-user KMS key
  Deletion request: delete user's KMS key
  Events remain: PII is unreadable

Monitoring:
  Event store write latency: P99 < 20ms
  Consumer group lag per projection: < 1000 events
  Snapshot age: no aggregate without snapshot > 100 events
  Alert: consumer lag > 5000 events (projection falling behind)
```

*What separates good from great:* The projection scaling independence is the
architectural strength. Each projection consumer (order-list, analytics, search)
scales independently based on its own throughput needs and backlog. Analytics
projection: might run on batch processing (hourly), accepting more lag. Search
projection: near-real-time (100ms lag). Status cache: real-time (50ms lag).
These different SLOs map to different scaling configurations. The single event
stream (Kafka topic) feeds all of them; no additional writes to the command
side are needed for new projections. When a new team needs "orders by warehouse
zone": they add a new consumer group, replay history for initial load, and
subscribe for ongoing updates. Zero coordination with the write side.
