---
layout: default
title: "Async and Background Processing - Patterns"
parent: "Async and Background Processing"
grand_parent: "Interview Mastery"
nav_order: 3
permalink: /interview/async-background/patterns/
topic: Async and Background Processing
subtopic: Patterns
keywords:
  - Event-Driven Architecture
  - Saga Pattern
  - Outbox Pattern
  - Backpressure
  - CQRS with Events
  - Priority Queues
  - Async API Design
difficulty_range: mixed
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Event-Driven Architecture](#event-driven-architecture)
- [Saga Pattern](#saga-pattern)
- [Outbox Pattern](#outbox-pattern)
- [Backpressure](#backpressure)
- [CQRS with Events](#cqrs-with-events)
- [Priority Queues](#priority-queues)
- [Async API Design](#async-api-design)

# Event-Driven Architecture (EDA)

**TL;DR** - Event-Driven Architecture structures applications around producing, detecting, and reacting to events, decoupling components so they communicate through events rather than direct calls.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT EDA:**
Order service calls shipping service (HTTP). Shipping service calls inventory service. Inventory service calls notification service. Each call is synchronous. If shipping is down, order fails. If inventory is slow, everything is slow. Adding a new analytics service means modifying the order service to call it. Every service knows about every other service.

**THE KEY INSIGHT:**
"Order placed" is a fact about the world. Multiple services need to react to this fact. The order service shouldn't know or care who reacts. It should announce the event and move on.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
TRADITIONAL (request-driven):
[Order] -> HTTP -> [Shipping]
       -> HTTP -> [Inventory]
       -> HTTP -> [Notification]
       -> HTTP -> [Analytics]
  Order knows all downstream services

EVENT-DRIVEN:
[Order] -> publishes -> [OrderCreated event]
                            |
              +------+------+------+
              |      |      |      |
          [Shipping] [Inv] [Notif] [Analytics]
              (subscribe independently)
  Order knows nothing about consumers
```

**Three styles:**

1. **Event Notification:** "Something happened." Consumers query for details. Minimal coupling.
2. **Event-Carried State Transfer:** Event contains all data consumers need. No callback queries.
3. **Event Sourcing:** Events are the source of truth. Current state is derived by replaying events.
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```java
// Event definition
public record OrderCreatedEvent(
    String orderId, String userId,
    List<LineItem> items, BigDecimal total,
    Instant timestamp) {}

// Producer: publishes event, doesn't know consumers
@Service
public class OrderService {
    private final KafkaTemplate<String, Object> kafka;

    @Transactional
    public Order createOrder(CreateOrderCommand cmd) {
        Order order = Order.from(cmd);
        orderRepo.save(order);
        kafka.send("order-events",
            order.getId(),
            new OrderCreatedEvent(order));
        return order;
    }
}

// Consumers: independent, decoupled
@Component
public class ShippingEventHandler {
    @KafkaListener(topics = "order-events",
        groupId = "shipping")
    public void handle(OrderCreatedEvent event) {
        shippingService.prepareShipment(event);
    }
}

@Component
public class AnalyticsEventHandler {
    @KafkaListener(topics = "order-events",
        groupId = "analytics")
    public void handle(OrderCreatedEvent event) {
        analyticsService.recordOrder(event);
    }
}
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. EDA decouples producers from consumers through events (facts about the world)
2. Adding new consumers requires zero changes to the producer
3. Trade-off: loose coupling vs harder debugging (no single request trace)

**Interview one-liner:**
"Event-Driven Architecture lets services communicate by publishing events rather than making direct calls - I use it to decouple services so new consumers can subscribe without modifying producers, accepting the trade-off of more complex debugging with distributed tracing."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Event-Driven Architecture (EDA). Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: What are the challenges of Event-Driven Architecture?**

_Why they ask:_ Tests awareness of trade-offs beyond the happy path.

**Answer:**

1. **Debugging complexity:** No single request/response trace. Event flows span multiple services asynchronously. Solution: distributed tracing (Jaeger, Zipkin) with correlation IDs.

2. **Eventual consistency:** After publishing an event, consumers haven't processed it yet. The order service shows "created" while shipping still doesn't know. Solution: design UIs to show pending states.

3. **Event ordering:** If "order updated" arrives before "order created," consumers break. Solution: partition by entity ID (all events for order-123 go to same partition, preserving order).

4. **Schema evolution:** Changing event structure breaks consumers. Solution: schema registry (Avro, Protobuf) with backward/forward compatibility.

5. **Debugging "who consumes what":** No single place shows all consumers of an event. Solution: event catalog, AsyncAPI documentation, consumer registration.
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Saga Pattern

**TL;DR** - Saga manages distributed transactions across multiple services by breaking them into a sequence of local transactions, each with a compensating action for rollback.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT SAGA:**
Order processing spans 4 services: create order, reserve inventory, charge payment, schedule shipping. If payment fails after inventory is reserved, you need to undo the reservation. In a monolith, a database transaction handles this. In microservices, there's no distributed transaction (2PC is too slow). How do you ensure all-or-nothing across services?
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
CHOREOGRAPHY (event-driven):
[Order] -> OrderCreated event
  -> [Inventory] reserves stock
    -> StockReserved event
      -> [Payment] charges card
        -> PaymentCharged event
          -> [Shipping] schedules delivery

COMPENSATION (on failure):
[Payment] fails -> PaymentFailed event
  -> [Inventory] releases stock (compensate)
  -> [Order] marks as failed (compensate)

ORCHESTRATION (central coordinator):
[Saga Orchestrator]
  -> Step 1: Create order
  -> Step 2: Reserve inventory
  -> Step 3: Charge payment (FAILS)
  -> Compensate Step 2: Release inventory
  -> Compensate Step 1: Cancel order
```

**Two approaches:**

| Aspect               | Choreography            | Orchestration         |
| -------------------- | ----------------------- | --------------------- |
| Coordination         | Events between services | Central orchestrator  |
| Coupling             | Lower                   | Higher (orchestrator) |
| Visibility           | Hard to see full flow   | Clear in orchestrator |
| Complexity           | Simple for 3-4 steps    | Better for 5+ steps   |
| Single failure point | No                      | Orchestrator          |
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```java
// Orchestration-based Saga
@Service
public class OrderSaga {
    public OrderResult execute(CreateOrderCmd cmd) {
        // Step 1: Create order
        Order order = orderService.create(cmd);
        try {
            // Step 2: Reserve inventory
            inventoryService.reserve(
                order.getItems());
            try {
                // Step 3: Charge payment
                paymentService.charge(
                    order.getUserId(),
                    order.getTotal());
                // Step 4: Schedule shipping
                shippingService.schedule(order);
                return OrderResult.success(order);
            } catch (PaymentException e) {
                // Compensate Step 2
                inventoryService.release(
                    order.getItems());
                order.markFailed("Payment failed");
                return OrderResult.failed(order);
            }
        } catch (InventoryException e) {
            // Compensate Step 1
            order.markFailed("Out of stock");
            return OrderResult.failed(order);
        }
    }
}
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Saga replaces distributed transactions with local transactions + compensating actions
2. Choreography: services coordinate via events (simpler); Orchestration: central coordinator (clearer flow)
3. Every step needs a compensating action - design compensations before the forward flow

**Interview one-liner:**
"Saga manages distributed transactions by breaking them into local transactions with compensating actions - I choose choreography for simple 3-4 step flows and orchestration for complex workflows where visibility of the full saga state matters."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Saga Pattern. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: What are the failure modes of the Saga pattern?**

_Why they ask:_ Tests deep understanding of distributed transaction challenges.

**Answer:**

1. **Compensation failure:** What if the compensating action itself fails? (Payment charged, shipping fails, inventory release fails.) Solution: retry compensations with exponential backoff. Store compensation state. Use a dead letter queue for failed compensations.

2. **Intermediate states:** Between steps, data is temporarily inconsistent. (Order created, inventory not yet reserved.) Users might see stale data. Solution: use saga status fields ("PENDING," "PROCESSING," "COMPLETED") and design UI for intermediate states.

3. **Idempotency:** If a step is retried, it must be idempotent. Charging payment twice is catastrophic. Solution: idempotency keys on every step.

4. **Ordering:** In choreography, events might arrive out of order. Solution: include saga ID and step number in events. Consumers validate ordering.
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Outbox Pattern

**TL;DR** - Outbox Pattern ensures reliable event publishing by writing events to a database table (outbox) in the same transaction as the business operation, then asynchronously polling and publishing them to the broker.
---

### 🔥 The Problem This Solves

**THE DUAL-WRITE PROBLEM:**

```
@Transactional
public void createOrder(Order order) {
    orderRepo.save(order);        // DB write
    kafka.send("order-events",    // Broker write
        new OrderCreatedEvent(order));
}
```

What if the DB write succeeds but the Kafka send fails? The order exists but no event is published. What if Kafka succeeds but the transaction rolls back? An event is published for a non-existent order. You can't atomically write to a database AND a message broker.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
STEP 1: Single atomic transaction
  [Business Table]  [Outbox Table]
  INSERT order      INSERT event
  (same transaction - atomic)

STEP 2: Async relay (polling or CDC)
  [Outbox Table] -> [Relay] -> [Kafka]
  Read unpublished events
  Publish to Kafka
  Mark as published

STEP 3: Cleanup
  Delete published events (or archive)
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```java
// Step 1: Write business data + event atomically
@Transactional
public Order createOrder(CreateOrderCmd cmd) {
    Order order = Order.from(cmd);
    orderRepo.save(order);

    // Same transaction - atomic with order
    outboxRepo.save(new OutboxEvent(
        UUID.randomUUID().toString(),
        "OrderCreated",
        "order-events",
        objectMapper.writeValueAsString(
            new OrderCreatedEvent(order)),
        Instant.now()));

    return order;
}

// Step 2: Relay publishes outbox events to Kafka
@Scheduled(fixedDelay = 1000)
@Transactional
public void publishOutboxEvents() {
    var events = outboxRepo
        .findByPublishedFalse();
    for (OutboxEvent event : events) {
        kafka.send(event.getTopic(),
            event.getPayload());
        event.setPublished(true);
        outboxRepo.save(event);
    }
}

// Alternative: Debezium CDC (Change Data Capture)
// reads database WAL, publishes to Kafka
// No polling needed, lower latency
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Outbox solves the dual-write problem (DB + broker can't be atomic)
2. Write events to a DB table in the same transaction as business data
3. Two relay approaches: polling (simple) or CDC/Debezium (lower latency)

**Interview one-liner:**
"Outbox pattern solves the dual-write problem by writing events to a database outbox table in the same transaction as business data, then asynchronously relaying them to the message broker - either by polling or CDC with Debezium."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Outbox Pattern. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Backpressure

**TL;DR** - Backpressure is a mechanism where a consumer signals to the producer to slow down when it can't keep up with the incoming data rate, preventing system overload.
---

### 🔥 The Problem This Solves

Producer generates 10,000 events/sec. Consumer processes 5,000/sec. Without backpressure: memory fills with buffered events, GC thrashes, OOM crash. The fast producer kills the slow consumer.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
WITHOUT BACKPRESSURE:
[Producer 10K/s] =====> [Buffer FULL] X [Consumer 5K/s]
                            OOM crash

WITH BACKPRESSURE:
[Producer] <-- "slow down" -- [Consumer]
[Producer 5K/s] ====> [Buffer OK] ===> [Consumer 5K/s]
                        balanced
```

**Strategies:**

1. **Drop:** Discard newest/oldest messages when buffer is full (acceptable for metrics)
2. **Buffer:** Expand buffer dynamically (defers the problem)
3. **Block:** Producer blocks until consumer catches up (simplest, but blocks upstream)
4. **Rate limit:** Producer sends at consumer's declared rate
5. **Reactive pull:** Consumer requests N items when ready (Reactive Streams)
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```java
// Reactive Streams backpressure (Project Reactor)
Flux.range(1, 1_000_000)
    .onBackpressureBuffer(1000) // Buffer up to 1000
    .publishOn(Schedulers.boundedElastic())
    .subscribe(
        item -> slowProcess(item),       // Slow consumer
        error -> log.error("Error", error),
        () -> log.info("Done"));

// Kafka consumer backpressure (implicit)
// Consumer calls poll() when ready
// max.poll.records controls batch size
// Consumer controls its own pace
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Backpressure prevents fast producers from overwhelming slow consumers
2. Strategies: drop, buffer, block, rate-limit, or reactive pull
3. Kafka has natural backpressure (consumer pulls); push-based systems need explicit mechanisms

**Interview one-liner:**
"Backpressure lets consumers signal producers to slow down when overwhelmed - I use reactive streams for in-process backpressure and Kafka's pull-based consumption for distributed backpressure."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Backpressure. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# CQRS with Events

**TL;DR** - CQRS separates read and write models, using events to keep the read model synchronized with the write model, enabling independent optimization of each.
---

### 🔥 The Problem This Solves

Your e-commerce system has a normalized write model (orders, line_items, products - 3 tables with JOINs). Reads need a denormalized view (order with full product details, customer info, shipping status). The same model can't be optimal for both: normalized for writes (avoid anomalies) and denormalized for reads (avoid JOINs).
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
WRITE SIDE:
[Command] -> [Command Handler] -> [Write DB]
                    |
             [Publish Event]
                    |
READ SIDE:          v
[Event] -> [Event Handler] -> [Read DB/Cache]
                                    |
[Query] -> [Query Handler] --------+
```

**Key principles:**

1. Write model: normalized, optimized for consistency and validation
2. Read model: denormalized, optimized for query patterns
3. Events synchronize write -> read (eventually consistent)
4. Commands change state. Queries return state. Never mix.
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```java
// WRITE SIDE
@Service
public class OrderCommandHandler {
    @Transactional
    public void handle(CreateOrderCommand cmd) {
        Order order = Order.from(cmd);
        orderRepo.save(order); // Normalized DB
        eventPublisher.publish(
            new OrderCreatedEvent(order));
    }
}

// READ SIDE - Event Handler builds read model
@Component
public class OrderReadModelUpdater {
    @EventListener
    public void on(OrderCreatedEvent event) {
        // Denormalized view for fast reads
        OrderView view = OrderView.builder()
            .orderId(event.orderId())
            .customerName(
                customerService.getName(
                    event.userId()))
            .items(event.items())
            .total(event.total())
            .status("CREATED")
            .build();
        orderViewRepo.save(view); // Read DB/Redis
    }
}

// QUERY SIDE - Fast reads from denormalized model
@Service
public class OrderQueryHandler {
    public OrderView getOrder(String id) {
        return orderViewRepo.findById(id); // No JOINs
    }
}
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. CQRS separates write model (normalized) from read model (denormalized)
2. Events synchronize write -> read (eventually consistent)
3. Use when read and write patterns differ significantly; skip for simple CRUD

**Interview one-liner:**
"CQRS separates read and write models, using events to sync them - I use it when read patterns differ significantly from write patterns, accepting eventual consistency for the benefit of independently optimized models."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for CQRS with Events. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Priority Queues

**TL;DR** - Priority queues process messages based on priority level rather than arrival order, ensuring critical tasks are handled before routine ones.
---

### 🔥 The Problem This Solves

Your support ticket system processes tickets first-come-first-served. A critical production outage ticket waits behind 500 password reset tickets. The outage takes 3 hours to reach a human because the queue doesn't distinguish urgency.
---

### Implementation Approaches

```
APPROACH 1: Multiple queues (recommended)
[High Priority Queue]   -> [Workers] (dedicated)
[Medium Priority Queue]  -> [Workers] (shared)
[Low Priority Queue]     -> [Workers] (shared)

APPROACH 2: Broker-level priority (RabbitMQ)
[Single Queue with priority 0-9]
  -> Broker delivers highest priority first
  -> Only RabbitMQ supports this natively

APPROACH 3: Weighted consumption
  Read 5 from high, 3 from medium, 1 from low
  per polling cycle
```
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```java
// Multiple queues approach (recommended)
@RabbitListener(queues = "tickets-critical")
public void handleCritical(Ticket ticket) {
    // Dedicated fast-track processing
    processImmediately(ticket);
}

@RabbitListener(queues = "tickets-normal")
public void handleNormal(Ticket ticket) {
    processStandard(ticket);
}

// Routing by priority at publish time
public void submitTicket(Ticket ticket) {
    String queue = switch (ticket.getPriority()) {
        case CRITICAL -> "tickets-critical";
        case HIGH -> "tickets-high";
        case NORMAL -> "tickets-normal";
        case LOW -> "tickets-low";
    };
    rabbitTemplate.convertAndSend(queue, ticket);
}
```
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Multiple queues with dedicated workers is the simplest and most reliable approach
2. RabbitMQ supports native message priority (0-9); Kafka and SQS do not
3. Avoid priority inversion: ensure low-priority messages aren't starved completely

**Interview one-liner:**
"I implement priority processing with separate queues per priority level and dedicated workers for critical queues - this is simpler and more reliable than broker-level priority."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Priority Queues. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Async API Design

**TL;DR** - Async APIs accept requests immediately, process them in the background, and provide status endpoints or callbacks for clients to get results.
---

### 🔥 The Problem This Solves

Your API generates a financial report that takes 45 seconds. The HTTP connection times out at 30 seconds. The client gets an error even though the report was being generated. You can't make a 45-second operation synchronous.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
SYNC API (broken for slow operations):
POST /reports -> [Process 45s] -> Timeout Error

ASYNC API (correct):
POST /reports -> 202 Accepted {jobId: "abc123"}
GET /jobs/abc123 -> {status: "processing", progress: 60%}
GET /jobs/abc123 -> {status: "complete", result: {...}}

ASYNC API with webhook:
POST /reports {callbackUrl: "https://me/hook"}
  -> 202 Accepted
  -> [Process in background]
  -> POST https://me/hook {result: {...}}
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 💻 Code Example

```java
// Async API - Submit + Poll pattern
@PostMapping("/reports")
public ResponseEntity<JobResponse> createReport(
        @RequestBody ReportRequest req) {
    String jobId = reportService.submitAsync(req);
    return ResponseEntity
        .status(HttpStatus.ACCEPTED)
        .header("Location", "/jobs/" + jobId)
        .body(new JobResponse(jobId, "QUEUED"));
}

@GetMapping("/jobs/{id}")
public ResponseEntity<JobStatus> getJobStatus(
        @PathVariable String id) {
    JobStatus status = jobService.getStatus(id);
    if (status.isComplete()) {
        return ResponseEntity.ok(status);
    }
    return ResponseEntity.ok()
        .header("Retry-After", "5")
        .body(status);
}

// Webhook callback (alternative to polling)
@Service
public class ReportWorker {
    public void process(ReportJob job) {
        try {
            Report report = generateReport(job);
            if (job.getCallbackUrl() != null) {
                httpClient.post(
                    job.getCallbackUrl(),
                    new WebhookPayload(
                        job.getId(), report));
            }
        } catch (Exception e) {
            jobService.markFailed(
                job.getId(), e.getMessage());
        }
    }
}
```
---

### Design Decisions

| Pattern   | Use when                          | Client complexity |
| --------- | --------------------------------- | ----------------- |
| Polling   | Simple clients, web browsers      | Low               |
| Webhooks  | Server-to-server, real-time needs | Medium            |
| WebSocket | Real-time progress updates        | Higher            |
| SSE       | One-way server push, progress     | Medium            |
---

### 📌 Quick Reference Card

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Return 202 Accepted with a job ID for async operations
2. Provide a status endpoint (GET /jobs/{id}) with `Retry-After` header
3. Support both polling and webhooks for different client needs

**Interview one-liner:**
"For operations exceeding request timeout, I return 202 Accepted with a job ID, process in the background, and provide both polling endpoints and webhook callbacks - the Location header points to the status URL."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Async API Design. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]
