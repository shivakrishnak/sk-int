---
layout: default
title: "Software Architecture - L2 Event Patterns"
parent: "Software Architecture"
grand_parent: "SK Interview"
nav_order: 7
permalink: /software-architecture/l2-event-patterns/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| #   | Keyword | Weight |
| --- | ------- | ------ |
| 1   | [Event-Driven Architecture](#event-driven-architecture) | critical |
| 2   | [CQRS - Command Query Responsibility Segregation](#cqrs---command-query-responsibility-segregation) | high |

---

# Event-Driven Architecture

🎯 Interview Weight: critical - foundational distributed systems
pattern tested across all levels; essential for microservices,
streaming, and reactive system design.

---

### 🎯 Model Answer

**30 seconds:**
> Event-Driven Architecture (EDA) is a pattern where services
> communicate by producing and consuming events - asynchronous
> messages representing facts that happened. The producer publishes
> the event to a broker (Kafka, RabbitMQ) without knowing who
> consumes it. Consumers subscribe and react independently. EDA
> enables loose coupling, independent scalability, and resilience
> at the cost of eventual consistency and increased operational
> complexity.

**3 minutes (Senior):**
> EDA consists of three roles: producers (publish events), consumers
> (subscribe to events), and a broker (stores and routes events).
> The key property: producers and consumers are decoupled - the
> producer does not know who is listening, and consumers can be
> added without changing the producer.
>
> Three event types serve different purposes. Notification events:
> thin messages that say "something happened" (order ID: 42 was
> placed) - consumers must call back to get details. Event-Carried
> State Transfer: the event contains all the data consumers need
> (full order payload) - consumers are self-contained. Event
> Sourcing: events are the source of truth, and current state is
> rebuilt by replaying the event log.
>
> The trade-offs: EDA provides loose coupling (add a new consumer
> without changing the producer), independent scalability (scale
> consumers independently), resilience (broker absorbs spikes),
> and natural audit trail (event log). It costs: eventual consistency
> (consumers process asynchronously), harder debugging (flow spans
> multiple services), increased operational complexity (broker
> management, dead-letter queues).
>
> The critical failure mode: the "event flood." A producer
> publishes 1000 events/second. One consumer processes 100/second.
> The consumer falls behind - the lag grows without limit. Solutions:
> consumer scaling, backpressure, or circuit breaker to shed load.

*Adapting up:* Staff adds: "EDA does not eliminate complexity -
it redistributes it. Request-response: complexity lives in the
caller (handle all errors synchronously). EDA: complexity lives
in the consumer (handle out-of-order events, idempotency, retry
storms, consumer lag). Choose EDA when the loose coupling benefit
outweighs the operational complexity cost."

*Adapting down:* Junior: "Event-Driven Architecture means services
communicate by posting messages to a queue/topic. Service A publishes
'OrderPlaced.' Service B and C subscribe and react to it. Neither
service knows about the other - they only know about the event
topic."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Event-Driven Architecture -
the pattern where services communicate via events through a broker."

**(2) First principles:** "Services need to communicate. Direct
calls couple the caller to the callee (caller waits, both must be
up). Events decouple: publisher posts the event and moves on.
Consumers react at their own pace."

**(3) Bridge:** "EDA is like a newspaper. The publisher (journalist)
writes the article and moves on. Readers (subscribers) read at
their own pace. The journalist does not know who is reading. EDA
is this model for service communication."

---

### 📘 Concept Explanation

**What it is:**
Event-Driven Architecture is an architectural pattern where
components communicate by producing and consuming events via a
message broker. Events are immutable facts that happened: `OrderPlaced`,
`PaymentProcessed`, `InventoryUpdated`.

**The problem it solves:**
In direct synchronous communication (REST calls), services are
tightly coupled: caller must know the callee's address, both must
be available simultaneously, the caller blocks waiting for a response.
Under load spikes, the callee becomes the bottleneck. EDA decouples
producers from consumers and enables asynchronous processing.

**How it works:**

```
EVENT-DRIVEN ARCHITECTURE

PRODUCER           BROKER              CONSUMERS
                  (Kafka/RMQ)
[OrderSvc] ----> [orders.placed] --+-> [InventoryService]
   |              (Topic/Exchange)  +-> [NotificationService]
   |                                +-> [AnalyticsService]
   |
   +-----------> [orders.cancelled] --> [InventoryService]
                                    --> [NotificationService]

BROKER GUARANTEES (varies by broker):
 - At-least-once delivery (Kafka, RabbitMQ default)
 - Exactly-once (Kafka transactions, with overhead)
 - Ordering (Kafka: within partition by key)
 - Replay (Kafka: consumers rewind offset)
```

**Three event types:**

| Type | Contents | Use Case |
|---|---|---|
| Notification | Event happened + minimal info (entity ID) | Consumers call back for details |
| Event-Carried State Transfer | Full payload (all data) | Consumers self-contained, no callbacks |
| Event Sourcing | Append-only event log as source of truth | Rebuild state by replaying |

**The key insight:**
Events are asynchronous by nature. This means consumers process
them at a different time than they are produced. Any state read
by a consumer is potentially stale. Designs must embrace eventual
consistency or explicitly handle it with coordination patterns.

**When to use EDA:**
When loose coupling between services is a priority. When producers
and consumers scale independently. When an audit trail of events
is valuable (event sourcing). When workflows span multiple services
(saga pattern).

**When NOT to use EDA:**
When the caller needs an immediate response to continue its own
operation. When exactly-once processing is required and the cost
of deduplication/transactions is too high. When the team cannot
manage broker operations. Simple CRUD applications with no
cross-service workflows.

**Alternatives:**
- Request/Response (REST): synchronous, immediate, tightly coupled
- gRPC streaming: bidirectional streaming but still point-to-point
- Message passing (actor model): actors + mailboxes, similar semantics

---

### 💻 Code Example

```java
// BAD: Synchronous chain - tight coupling
@RestController
public class OrderController {
    private final InventoryService inventoryService;
    private final NotificationService notifService;
    private final AnalyticsService analyticsService;

    @PostMapping("/orders")
    public Order placeOrder(@RequestBody PlaceOrderRequest r) {
        Order order = orderService.create(r);
        // Synchronous calls - coupling + failure propagation
        inventoryService.reserve(order);      // Can fail
        notifService.notifyCustomer(order);   // Can fail
        analyticsService.trackOrder(order);   // Can fail
        return order;
        // If notifService is down -> order fails!
        // If analyticsService is slow -> user waits!
    }
}
// Problem: order placement fails if notification service
// is down. User waits for analytics call to finish.
// Adding a new "loyalty points" step requires changing
// this controller.
```

> **Code walkthrough:** The synchronous chain couples order placement
> to three downstream services. If `notifService` is down, the entire
> order fails - the customer cannot place an order because the
> notification service is unavailable, which is unacceptable.
> If `analyticsService` is slow (100ms per call), the user waits
> 300ms extra for non-critical processing. Adding a new "loyalty
> points" step requires modifying this controller and its test suite.
> This is tight coupling in action.

```java
// GOOD: Event-driven - loose coupling

// Producer: publishes event and moves on
@Service
public class OrderService {
    private final OrderRepository orderRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public Order placeOrder(PlaceOrderCommand cmd) {
        Order order = Order.create(cmd);
        orderRepository.save(order);
        // Publish event - not send to specific service
        // Transactional outbox ensures delivery
        eventPublisher.publishEvent(
            new OrderPlacedEvent(order.getId(),
                order.getCustomerId(),
                order.getTotal())
        );
        return order;
        // Returns immediately after saving order.
        // Downstream services process asynchronously.
    }
}

// Consumer 1: InventoryService reacts independently
@Component
public class InventoryReservationHandler {
    @EventListener  // or @KafkaListener for distributed
    @Async
    public void on(OrderPlacedEvent event) {
        inventoryService.reserve(
            event.getOrderId(), event.getLines()
        );
        // Failure here does NOT fail the order placement.
        // Dead-letter queue handles failures.
    }
}

// Consumer 2: NotificationService reacts independently
@Component
public class CustomerNotificationHandler {
    @EventListener
    @Async
    public void on(OrderPlacedEvent event) {
        notificationService.notifyCustomer(
            event.getCustomerId(),
            "Your order has been placed"
        );
    }
}
// Adding "loyalty points" = new handler class.
// Zero changes to OrderService or existing handlers.
```

> **Code walkthrough:** `OrderService` saves the order and publishes
> a single `OrderPlacedEvent`. It returns immediately - the order
> is placed from the customer's perspective. Downstream services
> react asynchronously in their own handlers. If `CustomerNotificationHandler`
> fails, the order is already saved and the user already has a
> response. A dead-letter queue retries the failed notification.
> Adding "loyalty points" means creating a new `LoyaltyPointsHandler`
> class with zero changes to `OrderService` or existing handlers.
> This is loose coupling through events.

```java
// FAILURE EXAMPLE: Consumer lag without monitoring

// Producer: publishes 1000 events/second
// Consumer: processes 100 events/second

// Consumer (Kafka listener)
@KafkaListener(topics = "orders.placed",
               concurrency = "1")  // Single thread!
public void handleOrderPlaced(OrderPlacedEvent event) {
    // Complex processing: DB lookup + external API call
    // Avg 10ms per event = 100 events/second capacity
    inventoryClient.reserve(event.getOrderId());
}

// SYMPTOM: kafka consumer group lag grows unbounded
// kafka-consumer-groups.sh \
//   --bootstrap-server localhost:9092 \
//   --describe --group inventory-service
// GROUP  TOPIC         PARTITION  CURRENT-OFFSET  OFFSET  LAG
// inv-svc orders.placed 0         100000          200000  100000 <<<

// FIX: scale consumers (up to partition count)
@KafkaListener(topics = "orders.placed",
               concurrency = "10")  // 10 parallel consumers
// OR: optimize the processing (batch, cache, async IO)
// OR: partition by key for ordered processing
```

> **Code walkthrough:** The consumer processes 100 events/second
> but the producer generates 1000/second. The lag grows by 900
> events/second indefinitely. `kafka-consumer-groups.sh` shows the
> growing lag. Fix: increase `concurrency` to scale consumers (up
> to the number of partitions). For ordered processing requirements,
> partition by `orderId` key - Kafka guarantees order within a
> partition. The monitoring alert: "consumer lag > 10000" triggers
> a scale-out action.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Event-Driven Architecture means services communicate by posting
> events to a message broker (Kafka, RabbitMQ) instead of calling
> each other directly. Service A publishes `OrderPlaced`. Services
> B and C subscribe and react independently. The services are
> decoupled - neither knows about the other, only about the event.
> The trade-off: asynchronous processing means eventual consistency
> (the inventory update happens shortly after the order is placed,
> not simultaneously).

---

**Senior / Staff (5+ years):**
> EDA's core trade-off: loose coupling and scalability vs operational
> complexity and eventual consistency.
>
> Producer-consumer decoupling enables adding new consumers without
> changing producers. Kafka's log retention enables event replay -
> if a new service needs historical data, it replays from offset 0.
> Each consumer scales independently based on its own throughput
> needs.
>
> The hard parts: idempotency (at-least-once delivery means the same
> event can arrive twice; consumers must be idempotent), consumer
> lag monitoring (unbounded lag means the consumer is overwhelmed),
> and dead-letter queue handling (failed events must be retried or
> explicitly discarded with alerts). I always instrument consumer
> lag as a first-class SLI in EDA systems.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| EDA means exactly-once processing | Most brokers provide at-least-once by default. Exactly-once requires idempotent consumers and/or broker transactions (e.g., Kafka transactions) with overhead |
| Event-Driven means asynchronous everywhere | Some operations still need synchronous responses. EDA for background workflows; REST/gRPC for immediate responses |
| Kafka = EDA | Kafka is a broker that enables EDA, not EDA itself. You can have EDA with RabbitMQ, AWS SNS/SQS, or Azure Service Bus |
| More consumers = more throughput | Consumers cannot exceed partition count (Kafka). Adding consumers beyond partition count leaves extras idle |
| EDA eliminates coupling | EDA eliminates temporal coupling (availability) but introduces schema coupling (event contract) |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Message ordering violation**

*Symptom:* `OrderCancelled` processed before `OrderPlaced` for the
same order. Inventory reservation applied to a cancelled order.

*Root cause:* Events published to different partitions or topics.
Kafka guarantees order only within a partition.

*Diagnostic:*
```bash
# Check partition assignment for an order
kafka-console-consumer.sh \
  --topic orders \
  --from-beginning \
  --property print.partition=true \
  --property print.offset=true | grep "orderId:42"
# If OrderPlaced is on partition 2 and
# OrderCancelled is on partition 7 -> ordering violation
```

*Fix:* Use a consistent partition key: `orderId` as the Kafka
message key. Kafka guarantees ordered delivery within a partition
for the same key.

**Failure 2: Poison message blocking the consumer**

*Symptom:* Consumer stops processing. All downstream services
stop receiving events. Consumer lag grows to millions.

*Root cause:* A single malformed event causes the consumer to
throw an exception. Default behavior: retry the same message
indefinitely. Consumer is stuck on the poison message.

*Diagnostic:*
```bash
# Consumer log shows repeated exceptions
# "DeserializationException: Unexpected character at position 42"
# Consumer lag: 1M events and growing

# Check dead-letter topic
kafka-console-consumer.sh \
  --topic orders.placed.DLT \
  --from-beginning
```

*Fix:* Configure error handler with dead-letter queue:
```java
@Bean
public ConcurrentKafkaListenerContainerFactory factory() {
    factory.setCommonErrorHandler(
        new DefaultErrorHandler(
            new DeadLetterPublishingRecoverer(template),
            new FixedBackOff(1000L, 3)  // 3 retries
        )
    );
    return factory;
}
```

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 25 minutes |
| Core themes | Producer-consumer decoupling, event types, ordering, idempotency |
| Seniority signal | Junior: pub/sub concept; Senior: at-least-once + idempotency; Staff: EDA trade-off decision |
| Common trap | Assuming exactly-once; ignoring consumer lag |
| Staff differentiator | When NOT to use EDA |

---

**Q1 [JUNIOR]: What is Event-Driven Architecture?**

*Why they ask:* Foundational pattern for all distributed systems work.

*Likely follow-up:* "What is a message broker?"

Event-Driven Architecture is a pattern where services communicate
by producing and consuming events - immutable facts about things
that happened. Instead of Service A calling Service B directly,
Service A publishes an `OrderPlaced` event to a broker. Service B
(and C, D, etc.) subscribe to the event and react independently.

The three roles: Producer (publishes events), Broker (stores and
routes events - Kafka, RabbitMQ, SQS), Consumer (subscribes and
reacts to events).

The key benefit: producers and consumers are decoupled. `OrderService`
does not know that `InventoryService` and `NotificationService` exist.
It only knows about the `orders.placed` topic. Adding a new consumer
requires zero changes to the producer.

The trade-off: communication is asynchronous, so the consumer
processes the event at a later time. The system is eventually
consistent - the inventory is updated shortly after the order is
placed, not at the exact same instant.

*What separates good from great:* Most candidates describe pub/sub.
Great candidates name the three roles, explain the coupling benefit
explicitly (adding consumers without changing producers), and name
the eventual consistency trade-off.

---

**Q2 [MID]: What are the three types of events in EDA and when
do you use each?**

*Why they ask:* Tests depth of knowledge beyond basic pub/sub.

*Likely follow-up:* "What are the pros/cons of Event-Carried State Transfer?"

Notification events: the minimum event - "this thing happened" with
just an identifier. `{ "type": "OrderPlaced", "orderId": "42" }`.
Consumers must call back to get the full order details. Use when:
the consumer needs fresh data anyway (the event might be stale by
the time it is processed), or when the event payload would be large.
Risk: thundering herd - many consumers calling back simultaneously
(N+1 query problem at scale).

Event-Carried State Transfer (ECST): the event contains all data
the consumer needs. `{ "type": "OrderPlaced", "orderId": "42",
"customerId": "7", "lines": [...], "total": 99.99 }`. Consumers
are self-contained (no callback needed). Use when: consumers need
the data to process the event without latency from a callback,
or when decoupling from the producer's database is a priority.
Risk: large event payloads, schema coupling between producer and
consumer.

Event Sourcing: events are not messages sent to consumers - they
are the primary source of truth. Current state is rebuilt by
replaying all events in order. The Aggregate's current state is
a projection of its event history. Use when: complete audit history
is required, temporal queries ("what was the state on date X")
are needed, or debugging through event replay is valuable. Risk:
significant complexity (snapshotting for performance, schema
migration for old events).

*What separates good from great:* Most candidates know notification
events. Great candidates distinguish all three, give the thundering
herd risk for notification events, the schema coupling risk for ECST,
and the snapshot requirement for event sourcing at scale.

---

**Q3 [SENIOR]: How do you handle at-least-once delivery in EDA?**

*Why they ask:* At-least-once is the reality of most brokers;
idempotent consumers are required.

*Likely follow-up:* "What is an idempotent consumer?"

Most message brokers guarantee at-least-once delivery by default:
the same message might be delivered more than once (network failure
after processing but before ack, broker redelivery on consumer
restart). Exactly-once processing requires either exactly-once
broker semantics (Kafka transactions, high overhead) or idempotent
consumers.

An idempotent consumer: processing the same event twice produces
the same result as processing it once. Two strategies:

Natural idempotency: the operation is inherently idempotent.
`SET inventory_count = 50` is idempotent; `UPDATE inventory SET
count = count - 1` is not.

Deduplication with idempotency key: store processed event IDs in
a dedup table. Before processing, check if the event ID was already
processed. If yes, skip. The check + process + mark-as-processed
must be atomic (one transaction).

```java
@Transactional
public void handleOrderPlaced(OrderPlacedEvent event) {
    if (idempotencyStore.isDuplicate(event.getEventId())) {
        log.info("Duplicate event, skipping: {}",
                 event.getEventId());
        return;
    }
    // Process the event
    inventoryService.reserve(event.getOrderId());
    // Mark as processed in same transaction
    idempotencyStore.markProcessed(event.getEventId());
}
```

The window: idempotency keys must be retained for the expected
redelivery window (typically 24-72 hours, matching broker retention).

*What separates good from great:* Most candidates know idempotency
exists. Great candidates describe the two strategies (natural
idempotency and dedup table), give the atomicity requirement (check
+ process + mark in one transaction), and specify the key retention
window.

---

**Q4 [STAFF]: How do you design for event ordering and
out-of-order event handling?**

*Why they ask:* Ordering is a fundamental challenge in distributed
event streams.

*Likely follow-up:* "How does Kafka's partition model provide ordering?"

Kafka guarantees ordering only within a partition for the same
consumer group. Events with different keys may land in different
partitions and be processed out of order.

Design for ordered processing: use a consistent partition key for
events that must be ordered relative to each other. All events
for `orderId=42` are published with key `"42"` - Kafka routes all
to the same partition, guaranteeing order for that order.

Design for out-of-order events: not all scenarios can guarantee
order. Strategies:

Optimistic locking with version number: each event carries a
version number. Consumer rejects events with version < current
state version. `OrderCancelled(version=2)` applied to state at
version 3 is rejected (already superseded).

Event resequencer pattern: buffer events and wait for missing
sequence numbers before processing. Adds latency but ensures order.

State machine that handles out-of-order transitions: the domain
model's state machine defines valid transitions. `OrderCancelled`
on a `DELIVERED` order is simply rejected (invalid state transition)
without corrupting state.

Idempotent + commutative operations: if operations can be designed
to be both idempotent and commutative, ordering does not matter.
`SET status = CANCELLED` is idempotent (same result applied twice).
But it is not commutative with `SET status = DELIVERED`.

*What separates good from great:* Most candidates say "use Kafka
partition keys." Great candidates describe multiple strategies for
out-of-order handling (version check, state machine, resequencer)
and give the condition under which each applies.

---

**Q5 [SENIOR]: What is the dead-letter queue pattern and when is
it essential?**

*Why they ask:* Operational resilience - a common gap in EDA
implementations.

*Likely follow-up:* "What happens if the DLQ itself is not monitored?"

A Dead-Letter Queue (DLQ) is a separate topic/queue where messages
are sent when they cannot be processed successfully after N retries.
Without a DLQ, poison messages block the consumer indefinitely
or are silently dropped.

The pattern: consumer fails to process message. Retry with
exponential backoff (e.g., 1s, 2s, 4s, up to 3 retries). After
all retries exhausted, publish the message to the DLQ. Consumer
continues processing the next message (not blocked by the poison message).

Essential when: consumer processing can fail for transient reasons
(downstream service unavailable) or permanent reasons (malformed
message, schema mismatch). Transient failures should retry and
succeed. Permanent failures should go to DLQ for manual inspection.

The DLQ alert: unmonitored DLQ is as bad as no DLQ. If messages
pile up in the DLQ without alerts, data loss occurs silently.
Required: (1) alert when DLQ message count > threshold, (2) runbook
for reprocessing DLQ messages after fix, (3) DLQ message retention
long enough for on-call response.

Kafka Dead-Letter Topic with Spring Kafka:
```java
@Bean
public DefaultErrorHandler errorHandler(
    KafkaTemplate<?, ?> template
) {
    var dlrr = new DeadLetterPublishingRecoverer(template);
    // Publishes to <topic>.DLT automatically
    return new DefaultErrorHandler(
        dlrr, new FixedBackOff(1000L, 3L)
    );
}
```

*What separates good from great:* Most candidates know what a DLQ
is. Great candidates describe the retry-then-DLQ flow, the distinction
between transient and permanent failures, and the monitoring/runbook
requirement - the DLQ without monitoring is not a solution.

---

**Q6 [STAFF]: When should you NOT use Event-Driven Architecture?**

*Why they ask:* Staff signal: architectural judgment, not just
pattern knowledge.

*Likely follow-up:* "What is the right communication pattern for a checkout flow?"

EDA is not always the right choice. Avoid EDA when:

Immediate response is required by the business flow: a checkout
flow where the user must receive a payment confirmation before
the page completes cannot be event-driven for the payment step.
The payment result must be synchronous (REST or gRPC). EDA for
payment can be the "payment processed" event published after
the synchronous confirmation - not the payment itself.

Exactly-once semantics are required with high volume: financial
transactions requiring exactly-once ("never double-charge") with
millions of events per second. Exactly-once in Kafka has significant
overhead. At this scale, a synchronous transaction with a database
UNIQUE constraint is simpler and more reliable.

The team cannot operate the broker: Kafka requires operational
expertise (partition management, consumer group monitoring, lag
alerting, schema registry). If the team cannot invest in this
expertise, a simpler HTTP-based API with an async job queue
(database-backed) is more reliable.

Simple workflows without cross-service coordination: a single-service
CRUD application gains nothing from EDA. Adding a broker introduces
latency, operational overhead, and eventual consistency for no benefit.

Simple data pipelines: a scheduled batch job that reads from
database A and writes to database B does not need an event broker.
Direct database-to-database ETL is simpler.

*What separates good from great:* Most candidates always recommend
EDA for decoupling. Great candidates give specific counter-indicators
(synchronous payment confirmation, exactly-once requirements,
team capability, simple workflows) and explain why simpler
alternatives are better in each case.

---

**Q7 [SENIOR]: How do you implement the Saga pattern with
Event-Driven Architecture?**

*Why they ask:* Cross-service transactions are a critical EDA topic.

*Likely follow-up:* "Choreography vs Orchestration sagas - which do you prefer and why?"

A Saga is a sequence of local transactions across multiple services
where each step publishes an event that triggers the next step.
If a step fails, compensating transactions undo the previous steps.

Choreography saga (EDA-native): each service publishes events
and subscribes to events from the previous step. `OrderService`
publishes `OrderCreated`. `PaymentService` subscribes, processes
payment, publishes `PaymentProcessed`. `InventoryService` subscribes,
reserves inventory, publishes `InventoryReserved`. `OrderService`
subscribes to `InventoryReserved` and confirms the order.

Compensation: if `InventoryService` publishes `InventoryReservationFailed`,
`PaymentService` subscribes and publishes `PaymentRefunded`.
`OrderService` subscribes and publishes `OrderCancelled`.

Choreography advantages: loose coupling, no central coordinator.
Disadvantages: saga flow is distributed (hard to debug, no single
place to see the full flow). With N services, the compensating
logic is distributed across N services.

Orchestration saga: a central Saga Orchestrator knows the full
workflow. It calls each service via command messages and waits
for reply messages. The orchestrator tracks state and decides the
next step. If a step fails, the orchestrator sends compensating
commands.

Orchestration advantages: the workflow is visible in one place.
Easier to debug (one log to check). Easier to implement compensation
(orchestrator tracks what needs to be undone).

The choice: choreography for simple sagas (2-3 steps, simple
compensation). Orchestration for complex sagas (5+ steps,
complex compensation, monitoring requirements).

*What separates good from great:* Most candidates describe sagas
conceptually. Great candidates describe both patterns with their
compensating logic, give the debugging complexity of choreography
(flow distributed), the bottleneck risk of orchestration, and the
decision criteria (simplicity vs visibility).

---

**Q8 [STAFF]: How do you handle schema evolution in event-driven
systems?**

*Why they ask:* Long-running EDA systems have schema evolution problems;
tests production experience.

*Likely follow-up:* "What is a schema registry and when do you need one?"

Event schemas evolve. Consumers may be at different versions.
The event produced by v2 of the producer must be readable by v1
and v3 consumers (backward and forward compatibility).

Backward compatibility rules (consumers at older version read newer
events): adding new optional fields is safe (old consumers ignore
them - tolerant reader pattern). Removing required fields, changing
field types, or changing field semantics is breaking.

Forward compatibility rules (consumers at newer version read older
events): adding required fields breaks forward compatibility (old
events don't have the new required field). Use optional fields
with defaults.

Schema Registry (Confluent Schema Registry, AWS Glue): producers
register their schema. The registry enforces compatibility rules
before allowing a new schema to be published. Consumers know the
schema version of every message (schema ID in the message header).
Avro/Protobuf are the common schema formats (binary, backward-
compatible by design).

The breaking change process: if a breaking change is unavoidable,
publish to a new topic (v2). Both producer and consumer support
both versions simultaneously. Migrate consumers to v2. Decommission
v1 topic when no consumers remain.

*What separates good from great:* Most candidates know "add optional
fields." Great candidates describe the Schema Registry enforcement
mechanism, the Avro/Protobuf compatibility rules, and the versioned
topic strategy for breaking changes.

---

**Q9 [STAFF]: How would you design an EDA system to handle a
"replay" requirement?**

*Why they ask:* Replay is a Kafka-specific capability that tests
architectural thinking.

*Likely follow-up:* "What are the challenges with replaying events
for a new consumer?"

Kafka's log retention means consumers can rewind their offset and
replay all events from the beginning (or from a specific timestamp).
This enables powerful patterns: a new service can "catch up" on
all historical events, or a buggy consumer can be fixed and replayed
from before the bug occurred.

Designing for replay:

Events must be self-contained (Event-Carried State Transfer):
if an event is a notification event (just an ID), replaying it
requires the corresponding data to still exist in the producer's
database. If the order was deleted, replay fails. ECST events are
safe to replay because all data is in the event.

Consumer idempotency is critical for replay: replaying events
processes them again. The consumer must handle duplicate events
without double-processing. The idempotency key ensures duplicate
events are skipped.

Snapshot strategy for event sourcing replay: replaying from the
beginning of time is slow for long-running systems. Snapshots
capture the aggregate state at a point in time. Replay starts
from the most recent snapshot + events after it.

Careful with side effects: replaying `OrderPlaced` might re-send
customer emails. Flag replay mode in the consumer context. During
replay, skip side effects (external API calls, email sends).

Partitioned consumers can replay in parallel: assign different
partition ranges to different consumer threads for fast replay.

*What separates good from great:* Most candidates say "rewind
Kafka offset." Great candidates describe self-contained events,
idempotency requirements, snapshot strategy, and side-effect
suppression during replay as the complete design.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | At-least-once handling, idempotency, partition ordering |
| Hiring Manager | When EDA adds value vs when it adds complexity |
| Bar Raiser | Schema evolution, replay design, consumer lag monitoring |
| Peer Engineer | Practical: Kafka listener setup, DLQ, consumer lag metrics |

---

### ⚖️ Comparison Table

| Property | Event-Driven (EDA) | Request/Response (REST/gRPC) |
|---|---|---|
| Coupling | Temporal: loose (no direct dependency) | Temporal: tight (both must be available) |
| Consistency | Eventual (consumer processes async) | Immediate (response confirms state) |
| Scalability | Consumer scales independently | Caller and callee scale together |
| Observability | Hard (flow distributed) | Easy (request traces end-to-end) |
| Error handling | Complex (retry, DLQ, idempotency) | Simple (retry the HTTP call) |
| New consumers | Zero producer change | New caller must know producer's address |
| Throughput | High (broker absorbs spikes) | Callee is the bottleneck under spikes |
| Debugging | Requires distributed tracing, event log | Request/response logs are sufficient |
| Best for | Background workflows, audit trails, loose coupling | User-facing operations needing immediate response |

---

---

# CQRS - Command Query Responsibility Segregation

🎯 Interview Weight: high - common at architect and senior levels;
often combined with Event Sourcing questions; tests understanding
of read vs write model separation.

---

### 🎯 Model Answer

**30 seconds:**
> CQRS separates the write model (Commands - operations that change
> state) from the read model (Queries - operations that return data).
> Instead of one model serving both reads and writes, you have a
> Command side (write-optimized, enforces domain invariants) and a
> Query side (read-optimized projections for specific use cases).
> The trade-off: enables independent scaling of reads and writes
> and optimized read models, at the cost of eventual consistency
> between write and read models and significant architectural complexity.

**3 minutes (Senior):**
> CQRS is based on Bertrand Meyer's CQS principle (Command Query
> Separation): a method either changes state (command) or returns
> data (query), never both. CQRS applies this at the architectural
> level: separate classes, data stores, and scaling paths for
> commands and queries.
>
> The Command side: Command objects express user intent (`PlaceOrder`,
> `CancelOrder`). A Command Handler validates the command, loads
> the Aggregate from the write store, invokes domain logic, and
> persists the result. The write store is normalized (relational,
> transaction-optimized).
>
> The Query side: Read Models (projections) are pre-computed
> views optimized for specific query use cases. `OrderSummaryView`
> for the order list page, `OrderDetailView` for the order detail
> page, `OrderAnalyticsView` for reporting. Each is a denormalized
> view in a read-optimized store (document DB, Redis, search index).
>
> Synchronization: when the Command side persists state, it publishes
> Domain Events. Query-side Projection Handlers subscribe and update
> the Read Models. The read models are eventually consistent with
> the write model (typically milliseconds to seconds lag).
>
> When to use CQRS: when read and write scalability requirements
> differ significantly (99% reads, 1% writes), when multiple
> read models are needed for different use cases, or when combined
> with Event Sourcing. When NOT to use: simple CRUD with similar
> read/write volumes - CQRS adds substantial complexity for no benefit.

*Adapting up:* Staff adds: "CQRS is frequently over-applied. For
most services, a well-indexed SQL table serves both reads and writes
adequately. CQRS is justified when the read and write models are
genuinely different shapes - the write model needs normalization
for integrity, and the read model needs denormalization for
performance. If your read and write models are the same shape,
CQRS adds architectural complexity without benefit."

*Adapting down:* Junior: "CQRS means you have separate code for
'save data' (Commands) and 'read data' (Queries). The read side
can have a different database or format than the write side,
optimized for how the data is read."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CQRS - Command Query
Responsibility Segregation - the pattern that separates write and
read models."

**(2) First principles:** "Reading data and writing data have
different requirements. Writes need ACID transactions and
normalization. Reads need performance and specific shapes for each
UI view. Separating them allows optimizing each independently."

**(3) Bridge:** "CQRS is like a library with a catalog and physical
shelves. The catalog (read model) is organized for fast search
by author, title, genre. The physical shelves (write model) are
organized for safe storage and retrieval. A card catalog is not
how you store books - it is how you find them. CQRS gives you
both optimized separately."

---

### 📘 Concept Explanation

**What it is:**
CQRS (Greg Young, 2010) separates read and write responsibilities
into distinct models. Commands change state; Queries return state.
The write model enforces domain invariants. Read models are
denormalized projections optimized for specific query use cases.

**The problem it solves:**
A single data model that serves both reads and writes requires
compromises: normalized enough for write integrity, but normalized
data is slow to query (many joins). Read performance requires
denormalization or indexes, but these complicate writes. CQRS
eliminates this compromise by having separate models.

**How it works:**

```
CQRS ARCHITECTURE

COMMAND SIDE (Write)
  [Client] --Command--> [Command Handler]
                              |
                    [Domain Aggregate]
                              |
                   [Write Store: SQL]
                   (normalized, ACID)
                              |
                   [Domain Event Published]
                              |
QUERY SIDE (Read)             |
                   [Projection Handler] <--+
                              |
                  [Read Models (multiple)]
                  - OrderSummary (Redis)
                  - OrderDetail (MongoDB)
                  - OrderAnalytics (Elastic)
                              ^
  [Client] ---Query-----------|
  (reads from read model directly,
   no domain logic, no joins needed)
```

**The key insight:**
Read and write models optimize for different things. The write
model optimizes for consistency and invariant enforcement (normalized,
transactional). Read models optimize for query performance
(denormalized, query-specific projections).

**When to use CQRS:**
When reads and writes have significantly different scalability needs.
When multiple query shapes are needed for different UI views.
When combined with Event Sourcing (natural pairing). When the
read model needs a different technology (Redis for caching, Elasticsearch
for full-text search).

**When NOT to use CQRS:**
Simple CRUD applications with uniform read/write load. Small teams
where the complexity cost outweighs benefits. When reads and writes
have the same model shape. When eventual consistency between write
and read is not acceptable for any use case.

**Relationship to Event Sourcing:**
CQRS and Event Sourcing are independent patterns but frequently
combined. Event Sourcing stores events as the write store; projections
(read models) are built from events. CQRS without Event Sourcing:
commands update a traditional database and publish events to update
projections.

---

### 💻 Code Example

```java
// BAD: Single model serving reads and writes - compromise
@Entity
@Table(name = "orders")
public class Order {
    @Id private Long id;
    @OneToMany private List<OrderLine> lines;
    @ManyToOne private Customer customer;
    // 30 fields to serve every read use case
    // Normalized for write integrity
    // BUT: every read joins 5 tables
}

@Repository
public interface OrderRepository
    extends JpaRepository<Order, Long> {
    // This query joins orders + lines + customer + address
    // + shipping + payment - slow for list pages
    @Query("SELECT o FROM Order o LEFT JOIN FETCH " +
           "o.lines l LEFT JOIN FETCH o.customer c " +
           "WHERE o.customerId = :cid ORDER BY " +
           "o.createdAt DESC")
    List<Order> findByCustomerIdForListPage(
        @Param("cid") Long customerId
    );
    // Different read use cases need different queries
    // All on the same model = compromise
}
```

> **Code walkthrough:** The single `Order` entity serves both
> writes (domain logic, invariant enforcement) and reads (list pages,
> detail pages, reports). The list page query joins 5 tables and
> loads 30 fields when it only needs 5 (id, status, total, date,
> customer name). Adding an index for the write model slows queries;
> adding an index for reads may slow writes. The model shape is
> a compromise that is not optimal for either purpose.

```java
// GOOD: CQRS with separate write and read models

// COMMAND SIDE: write model enforces domain invariants
public class Order {  // Domain aggregate - no JPA here
    private OrderId id;
    private OrderStatus status;
    private List<OrderLine> lines;

    public void place() {
        if (lines.isEmpty()) throw new EmptyOrderException();
        this.status = PENDING;
        // Raise event - projection handler updates read model
        raise(new OrderPlaced(id, customerId, total()));
    }
}

// Command handler: orchestrates the write side
@Service
public class PlaceOrderHandler {
    @Transactional
    public void handle(PlaceOrderCommand cmd) {
        Order order = orderRepo.findById(cmd.getOrderId());
        order.place();
        orderRepo.save(order);
        // Events published from aggregate via outbox
    }
}

// QUERY SIDE: read models - separate from domain model
// Projection: optimized for ORDER LIST PAGE
public class OrderSummaryView {
    private Long orderId;
    private String customerName;  // pre-joined
    private String status;
    private BigDecimal total;
    private LocalDate orderDate;
    // Only 5 fields needed for list - no joins in query
}

// Projection Handler: updates read model from events
@Component
public class OrderSummaryProjection {
    @EventHandler  // Listens to OrderPlaced event
    public void on(OrderPlaced event) {
        OrderSummaryView view = new OrderSummaryView(
            event.getOrderId(),
            customerCache.getName(event.getCustomerId()),
            "PENDING",
            event.getTotal(),
            LocalDate.now()
        );
        orderSummaryRepository.save(view);  // Redis or SQL
    }

    @EventHandler
    public void on(OrderStatusChanged event) {
        OrderSummaryView view =
            orderSummaryRepository
                .findById(event.getOrderId());
        view.setStatus(event.getNewStatus());
        orderSummaryRepository.save(view);
    }
}

// Query handler: reads directly from optimized view
@Service
public class OrderListQueryHandler {
    // No joins! Read model has pre-joined data
    public List<OrderSummaryView> getOrdersForCustomer(
        Long customerId
    ) {
        return orderSummaryRepository
            .findByCustomerId(customerId);
    }
}
```

> **Code walkthrough:** The command side has a pure domain `Order`
> aggregate with no persistence annotations. It raises `OrderPlaced`
> when placed. The `OrderSummaryProjection` listens to `OrderPlaced`
> and creates a pre-joined, read-optimized `OrderSummaryView`.
> The query handler reads directly from this view with no joins.
> The read model can be in Redis (for fast caching), a materialized
> view, or a separate document. Adding a new read use case (analytics
> view, mobile API view) means creating a new projection class with
> zero changes to the command side. Eventual consistency: the read
> model updates milliseconds after the command completes.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> CQRS separates operations that change data (Commands) from
> operations that read data (Queries). The Command side has the
> domain model with business rules. The Query side has optimized
> read models (projections) that are pre-computed views of the data
> for specific use cases. Changes on the Command side update the
> Query side asynchronously via events.

---

**Senior / Staff (5+ years):**
> CQRS is frequently justified by the "N+1 problem at the model
> level": one model cannot be optimally shaped for both writes
> (normalized for ACID, enforcing invariants) and reads (denormalized
> for specific query shapes).
>
> Where CQRS genuinely helps: a high-read e-commerce catalog where
> 99% of traffic is reads. The read model is a pre-joined JSON
> document in Redis. Writes update the document asynchronously.
> Read latency drops from 100ms (SQL with joins) to 1ms (Redis GET).
>
> Where CQRS is over-applied: a backoffice admin service with 5
> users and 10 writes/day. Adding CQRS doubles the codebase for
> no measurable benefit. A well-indexed SQL table serves both reads
> and writes adequately.

---

### ⚠️ Common Misconceptions

| Misconception | Reality |
|---|---|
| CQRS requires Event Sourcing | CQRS and Event Sourcing are independent. CQRS with a traditional SQL write store and asynchronous projections is valid |
| CQRS means two databases | CQRS means two models. They can be in the same database (e.g., different tables in PostgreSQL) |
| Queries never modify state | Queries must not modify business state but can update technical state (read counters, last-seen timestamps) |
| CQRS eliminates eventual consistency | CQRS introduces eventual consistency between write and read models. If the UI must show the write result immediately, the application must account for this |
| CQRS is needed for microservices | CQRS is a within-service pattern. Many microservices do not need CQRS |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Stale read after write - user confusion**

*Symptom:* User places an order (command succeeds). User navigates
to order list (query). Order does not appear. User re-submits.
Duplicate order.

*Root cause:* Projection lag. The `OrderSummary` read model has
not been updated yet when the user queries.

*Diagnostic:*
```
# Check projection lag (event timestamp vs projection update time)
SELECT MAX(last_updated) as projection_lag
FROM order_summary_views;
# Compare to last OrderPlaced event time
```

*Fix 1 (client-side):* After command success, temporarily show
the result from the command response (optimistic UI). Do not wait
for the read model.

*Fix 2 (causal consistency):* Return a version number with the
command response. The query endpoint waits for the projection to
reach that version before returning.

*Fix 3 (user guidance):* Show "Your order is being processed"
with a spinner and poll for the read model update.

**Failure 2: Projection divergence - read model out of sync**

*Symptom:* Read model shows incorrect data. Some orders show wrong
status. Reads do not match writes.

*Root cause:* Projection handler failed to process some events.
Dead-letter queue accumulated events that were never reprocessed.

*Diagnostic:*
```sql
-- Check for gaps in processed events
SELECT event_id FROM processed_events
ORDER BY event_id;
-- Look for gaps (missing event IDs)
```

*Fix:* Rebuild the projection from scratch by replaying all events
from the event store. This is the "read model repair" capability -
a key advantage of the CQRS + Event Sourcing combination.

---

### 🎯 Interview Deep-Dive

| Preparation | Target |
|---|---|
| Time to prep | 20 minutes |
| Core themes | Write vs read model separation, projection handlers, eventual consistency |
| Seniority signal | Junior: concept; Senior: projection + consistency; Staff: when NOT to use CQRS |
| Common trap | Assuming CQRS requires Event Sourcing |
| Staff differentiator | Pragmatic judgement: CQRS overhead vs benefit |

---

**Q1 [JUNIOR]: What is CQRS?**

*Why they ask:* Pattern name and concept understanding.

*Likely follow-up:* "What is the difference between CQRS and CQS?"

CQRS (Command Query Responsibility Segregation) separates operations
that change state (Commands) from operations that return data (Queries).

CQS (Command Query Separation, Bertrand Meyer): at the method level,
a method either changes state or returns data, never both. `getOrder()`
returns data (query). `placeOrder()` changes state and returns
nothing (command). Don't do: `placeOrderAndReturnId()`.

CQRS applies CQS at the architectural level: separate classes,
data stores, and scaling paths for Commands and Queries. The write
model (command side) handles all state changes through domain
aggregates. The read model (query side) has pre-computed projections
optimized for specific read use cases.

*What separates good from great:* Most candidates describe CQRS
as having two databases. Great candidates explain the CQS origin,
describe the projection mechanism (how the read model is kept in
sync), and distinguish CQRS (architectural) from CQS (method-level).

---

**Q2 [MID]: How does the read model stay in sync with the write model?**

*Why they ask:* Projection mechanics are the core of CQRS implementation.

*Likely follow-up:* "What happens to the read model if the projection
handler fails?"

The synchronization mechanism: when the write model changes state,
it publishes Domain Events. Projection Handlers subscribe to these
events and update the read models.

The flow:
1. Command: `PlaceOrderCommand` arrives.
2. Command Handler: loads `Order` aggregate, calls `order.place()`.
3. Domain Event: `Order.place()` raises `OrderPlaced`.
4. Write side persists: `Order` saved to write store.
5. Event published: `OrderPlaced` published to event bus (or outbox).
6. Projection Handler: subscribes to `OrderPlaced`, updates `OrderSummaryView`.
7. Read model updated: `OrderSummaryView` now reflects the placed order.

The failure case: if the Projection Handler fails at step 6, the
read model is stale. With a dead-letter queue and retry, the
projection catches up when the handler recovers. With Event Sourcing,
the projection can be rebuilt by replaying all events.

The lag: steps 5-7 introduce a small delay (milliseconds to seconds).
The read model is eventually consistent with the write model.

*What separates good from great:* Most candidates describe the flow
at a high level. Great candidates describe the outbox pattern for
reliable event delivery, the DLQ for failed projections, and event
sourcing as the ultimate recovery mechanism (full rebuild from event
log).

---

**Q3 [SENIOR]: What is the relationship between CQRS and Event
Sourcing?**

*Why they ask:* These two patterns are often conflated or incorrectly
made interdependent.

*Likely follow-up:* "Can you have CQRS without Event Sourcing?"

CQRS and Event Sourcing are independent patterns that complement
each other but neither requires the other.

CQRS without Event Sourcing: the write model is a traditional
relational database. Commands update the `orders` table via
`UPDATE`. Domain Events are published (not stored as the source
of truth - they are side effects of the database update). Projections
subscribe to events and update read models. This is valid CQRS.

Event Sourcing without CQRS: the event store is the source of
truth. Every command appends events to the log. Current state is
rebuilt by replaying. But there is only one query model - no
separate optimized read projections. This is valid Event Sourcing.

CQRS + Event Sourcing: the natural pairing. Event Sourcing provides
the reliable event stream for building projections. Projections
define the read models. Rebuilding a broken projection means
replaying from the event store. This is the most powerful combination
but also the most complex.

The decision: start with CQRS without Event Sourcing. Add Event
Sourcing only if you need: complete audit history, temporal queries,
the ability to rebuild projections from scratch, or replaying
events for debugging.

*What separates good from great:* Most candidates say "CQRS uses
Event Sourcing." Great candidates clearly separate the two as
independent patterns, describe each combination (CQRS only, ES
only, CQRS+ES), and give the adoption criteria for adding Event
Sourcing.

---

**Q4 [STAFF]: When should you NOT use CQRS?**

*Why they ask:* Staff signal: architectural judgment over pattern
dogmatism.

*Likely follow-up:* "What is the complexity cost of CQRS?"

CQRS adds substantial complexity: separate command and query models,
projection handlers, eventual consistency management, and potentially
separate data stores. This complexity is only justified when the
benefit is proportional.

Do NOT use CQRS when:

Read and write models are the same shape: if the data you write is
the data you read (user profile: write full profile, read full
profile), CQRS adds complexity for no benefit. A single JPA entity
with appropriate indexes is simpler and sufficient.

Uniform read/write volume: if reads and writes are balanced (a
backoffice system with 50/50 reads and writes), separate scaling
paths provide no benefit.

Small team without EDA expertise: CQRS requires understanding of
eventual consistency, projection handlers, DLQ management, and
read model repair. A 2-person startup team may not have the
bandwidth to manage this.

Strong consistency requirements between read and write: CQRS
introduces eventual consistency. If the business requirement is
"every read returns the most up-to-date write result with no lag,"
CQRS makes this harder, not easier.

The test: "Does my use case have significantly different read and
write requirements?" If yes (1000 reads/second, 10 writes/second;
or multiple different read shapes), CQRS helps. If no, it is
premature optimization.

*What separates good from great:* Most candidates always recommend
CQRS for scalability. Great candidates give specific counter-indicators
(same model shape, uniform volume, small team, strong consistency
need) and the decision test.

---

**Q5 [SENIOR]: How do you handle the "read-your-own-writes"
consistency problem in CQRS?**

*Why they ask:* Practical operational problem that arises from
eventual consistency.

*Likely follow-up:* "How does Amazon handle this with DynamoDB?"

"Read-your-own-writes": a user issues a command (places an order)
and immediately queries (views order list). The projection lag
means the order may not appear yet. User is confused and re-submits.

Solutions:

Optimistic UI: the client optimistically adds the new item to the
UI from the command response without waiting for the read model.
When the projection eventually updates, the UI is already showing
correct data. The most user-friendly solution.

Version-based read model wait: the command returns a version number.
The query API accepts an optional `minimumVersion` parameter and
waits until the projection reaches that version before responding.
Adds latency but ensures consistency from the user's perspective.

Client-side cache invalidation: after issuing a command, the client
invalidates its read cache for the affected entity. The next read
goes to the server (read model may still be stale, but the round
trip gives the projection more time).

Same-session read from write model: for the specific user who just
issued the command, route the immediate next read to the write
model (bypassing the projection). Adds complexity but gives strong
consistency for the issuing user.

*What separates good from great:* Most candidates describe the
problem. Great candidates give multiple solutions and compare their
trade-offs (optimistic UI = best UX, version-based = adds latency,
same-session write read = most complex).

---

**Q6 [STAFF]: How do you rebuild a CQRS projection after a bug?**

*Why they ask:* Practical operational capability that separates
architecturally mature CQRS from a theoretical exercise.

*Likely follow-up:* "How does this differ between CQRS with and
without Event Sourcing?"

With Event Sourcing: replay is the answer. The projection is
discarded (DELETE FROM order_summary_views). The Projection Handler
is fixed. The event log is replayed from the beginning (or from
the earliest event affected by the bug). The projection is rebuilt
in the correct state. This is the primary operational advantage
of CQRS + Event Sourcing.

```bash
# Kafka: reset consumer group to beginning
kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group projection-order-summary \
  --reset-offsets \
  --to-earliest \
  --execute \
  --topic order-events
# Restart projection service - it rebuilds from scratch
```

Without Event Sourcing: the write store holds current state, not
event history. Rebuilding from scratch may not be possible unless
you also store events separately. Fallback: write a reconciliation
job that reads from the write store and populates the read model.
This is why CQRS + Event Sourcing is the recommended combination.

The key design requirement: the projection must be rebuilable.
Every handler must be idempotent (rebuilding replays all events,
including already-processed ones). The rebuild operation must
be tested regularly (not only when you have a production bug).

*What separates good from great:* Most candidates describe the
replay conceptually. Great candidates give the Kafka reset command,
describe the difference between ES-backed (full replay) and non-ES
(reconciliation job), and state the idempotency and regular testing
requirements.

---

**Q7 [STAFF]: How does CQRS interact with microservices boundaries?**

*Why they ask:* Tests understanding of where CQRS applies.

*Likely follow-up:* "Should every microservice implement CQRS?"

CQRS is a within-service pattern. The command and query separation
happens inside a service boundary. It is not an inter-service pattern.

Each microservice decides independently whether to implement CQRS.
A simple CRUD microservice (user preferences, configuration) does
not need CQRS. A high-traffic catalog service with complex read
models might benefit.

The cross-service interaction: a service's read models may include
data from other services. `OrderSummaryView` shows `customerName`
from the Customer service. The projection handler subscribes to
`CustomerNameUpdated` events from the Customer service and updates
`OrderSummaryView` accordingly. Each service's read models are
maintained by that service's projection handlers, which consume
events from other services.

The anti-pattern: a "CQRS API" where the query side of Service A
directly queries the database of Service B. This violates service
autonomy. The correct approach: Service A subscribes to Service B's
events and maintains its own read model with the data it needs
from Service B.

The practical rule: CQRS makes sense within a service when its read
and write requirements genuinely differ. It makes no sense as a
cross-service API pattern.

*What separates good from great:* Most candidates say "CQRS and
microservices go together." Great candidates describe CQRS as a
within-service pattern, explain cross-service read model population
via event subscription, and identify the anti-pattern of cross-service
database reads.

---

**Q8 [SENIOR]: Compare CQRS with the Repository pattern approach
in traditional layered architecture.**

*Why they ask:* Tests understanding of the trade-off vs simpler
alternatives.

*Likely follow-up:* "When would you choose one over the other?"

Traditional layered architecture with Repository: one domain model
serves reads and writes. The Repository abstracts data access.
Queries use the same model as commands. Read requirements are
served by adding query methods to repositories with appropriate
indexes and joins.

Advantages: simple, single model, no eventual consistency, easy
to understand for new developers.

Disadvantages: as read requirements diversify, the model becomes
a compromise. Reporting queries require complex joins. The model
accumulates "reporting fields" that have no domain meaning.

CQRS: separate models. Reads are optimized independently. New read
use cases are new projections (additive change). The domain model
stays clean and focused on invariants.

Advantages: each model is optimized for its purpose. Independent
scaling. Clean domain model.

Disadvantages: eventual consistency, two codebases to maintain,
higher operational complexity.

The decision criteria: repository pattern for up to ~5 read use
cases with similar shapes and moderate volume. CQRS when read
models diverge significantly in shape, when read volume far exceeds
write volume, or when multiple teams need different views of the
same data.

*What separates good from great:* Most candidates say "CQRS is better."
Great candidates compare on complexity vs benefit dimensions, give
the threshold criteria (read model shape divergence, volume ratio),
and recommend repository pattern as the starting point.

---

**Q9 [STAFF]: How do you test a CQRS system?**

*Why they ask:* Tests operational maturity and testing discipline
for CQRS implementations.

*Likely follow-up:* "How do you test projections?"

Command side testing: unit tests for Aggregate domain logic
(no infrastructure needed: create aggregate, call command, assert
on raised events). Integration tests for Command Handlers (with
real database, assert on persisted state and published events).

```java
@Test
void placeOrder_raisesOrderPlacedEvent() {
    Order order = Order.create(customerId);
    order.addLine(product, 2, Money.of(50, USD));
    order.place();
    // Assert on domain events - no database needed
    assertThat(order.pullEvents())
        .hasSize(1)
        .first()
        .isInstanceOf(OrderPlaced.class);
}
```

Projection handler testing: publish an event, verify the read
model was updated correctly. Use an in-memory or real database
for the projection store.

```java
@Test
void orderPlacedEvent_updatesOrderSummaryView() {
    var event = new OrderPlaced(orderId, customerId, total);
    projection.on(event);
    var view = summaryRepo.findById(orderId);
    assertThat(view.getStatus()).isEqualTo("PENDING");
    assertThat(view.getTotal()).isEqualTo(total);
}
```

End-to-end CQRS test: issue a command, wait for the projection
to update (poll with timeout), assert on the read model. This
tests the full pipeline including eventual consistency.

Projection rebuild test: mandatory operational test. Replay all
events into a fresh projection. Assert the result matches the
production projection. This verifies the projection is rebuilable
and idempotent.

*What separates good from great:* Most candidates describe command
side testing. Great candidates also describe projection handler
testing (event-in, view-out), the end-to-end test with eventual
consistency handling, and the projection rebuild test as a required
operational verification.

---

### ⚖️ Comparison Table

| Property | CQRS | Traditional CRUD (Repository) |
|---|---|---|
| Write model | Normalized, domain-optimized | Same as read model |
| Read model | Denormalized projections per use case | Query methods on the same model |
| Consistency | Eventual (projection lag) | Immediate |
| Scalability | Read and write scale independently | Scale together |
| Complexity | High (two models, projections, events) | Low (one model, repositories) |
| New read use case | New projection (zero write changes) | New query method + potential index |
| Recovery from bug | Replay events to rebuild projection | Re-run reconciliation job |
| Best for | High read/write ratio, diverse read shapes | Uniform load, simple read requirements |
| Team requirement | EDA expertise, eventual consistency comfort | Basic ORM knowledge |
