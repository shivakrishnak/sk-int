---
layout: default
title: "System Design - Patterns"
parent: "System Design"
grand_parent: "Interview Mastery"
nav_order: 4
permalink: /interview/system-design/patterns/
topic: System Design
subtopic: Patterns
keywords:
  - Hexagonal and Clean Architecture
  - Domain-Driven Design
  - Saga Pattern
  - Event Sourcing
  - Strangler Fig Pattern
  - Sidecar and Service Mesh
difficulty_range: medium to hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Hexagonal and Clean Architecture](#hexagonal-and-clean-architecture)
- [Domain-Driven Design](#domain-driven-design)
- [Saga Pattern](#saga-pattern)
- [Event Sourcing](#event-sourcing)
- [Strangler Fig Pattern](#strangler-fig-pattern)
- [Sidecar and Service Mesh](#sidecar-and-service-mesh)

# Hexagonal and Clean Architecture

**TL;DR** - Hexagonal (Ports and Adapters) architecture isolates business logic from infrastructure by defining ports (interfaces) that adapters (implementations) connect to. Clean Architecture formalizes this with concentric dependency rings: domain at the center depends on nothing; everything else depends inward.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Business logic is tangled with database queries, HTTP controllers, and message queue code. Changing from PostgreSQL to DynamoDB requires rewriting business rules. Unit testing requires a running database. Framework upgrades break domain logic.
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
Put your business rules in the center. Everything external (database, web framework, message queue) plugs in around it like adapters. You can swap any adapter without touching the business rules.

**Level 2 - How to use it (junior developer):**

**Hexagonal Architecture (Ports and Adapters):**

```
        [REST Controller]   [gRPC Handler]
              |                   |
          (Inbound Ports - interfaces)
              |                   |
        +---------------------------+
        |     APPLICATION CORE      |
        |  Domain Model + Use Cases |
        +---------------------------+
              |                   |
          (Outbound Ports - interfaces)
              |                   |
        [PostgreSQL Repo]  [Kafka Publisher]
        [Redis Cache]      [SMTP Sender]
```

- **Inbound ports:** How the outside world talks to your app (interfaces like `OrderService`)
- **Outbound ports:** How your app talks to infrastructure (interfaces like `OrderRepository`)
- **Adapters:** Implementations of ports (`PostgresOrderRepository`, `KafkaEventPublisher`)

**Level 3 - How it works (mid-level engineer):**

**Clean Architecture layers (Dependency Rule: always point inward):**

```
Outermost: Frameworks & Drivers
  (Spring, PostgreSQL driver, Kafka client)
    |
    v
Interface Adapters
  (Controllers, Repositories, Presenters)
    |
    v
Application (Use Cases)
  (PlaceOrderUseCase, CancelOrderUseCase)
    |
    v
Innermost: Domain Entities
  (Order, Payment, ShippingRule)
```

```java
// Domain (innermost - no framework imports)
public class Order {
    private OrderId id;
    private List<LineItem> items;
    private OrderStatus status;

    public Money calculateTotal() {
        return items.stream()
            .map(LineItem::subtotal)
            .reduce(Money.ZERO, Money::add);
    }
}

// Outbound Port (interface in domain layer)
public interface OrderRepository {
    Order findById(OrderId id);
    void save(Order order);
}

// Use Case (application layer)
public class PlaceOrderUseCase {
    private final OrderRepository repo;
    private final PaymentPort payment;

    public OrderId execute(PlaceOrderCommand cmd) {
        Order order = Order.create(cmd.items());
        payment.charge(order.calculateTotal());
        repo.save(order);
        return order.getId();
    }
}

// Adapter (infrastructure layer)
@Repository
public class JpaOrderRepository
        implements OrderRepository {
    @PersistenceContext
    private EntityManager em;

    public Order findById(OrderId id) {
        // JPA-specific code here
        // Domain layer has NO idea this is JPA
    }
}
```

**Level 4 - Mastery (senior/staff+ engineer):**

**When it's worth the complexity:**

| Use when...                                      | Avoid when...            |
| ------------------------------------------------ | ------------------------ |
| Complex business domain                          | Simple CRUD              |
| Multiple adapters needed (test, prod, migration) | Single DB, single API    |
| Long-lived project (5+ years)                    | Short-lived prototype    |
| Team > 5 developers                              | Solo developer           |
| Domain experts available                         | Purely technical project |

**Package structure (enforced boundaries):**

```
com.company.order/
  domain/
    model/       (Order, LineItem, Money)
    port/in/     (PlaceOrderUseCase - interface)
    port/out/    (OrderRepository - interface)
  application/
    service/     (PlaceOrderService - use case impl)
  adapter/
    in/web/      (OrderController)
    in/grpc/     (OrderGrpcHandler)
    out/jpa/     (JpaOrderRepository)
    out/kafka/   (KafkaEventPublisher)
```

**Testing benefit:** Domain and use case layers are 100% unit testable with mocks. No Spring context, no database, no containers. Test execution: milliseconds, not seconds.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
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

1. Dependency Rule: everything depends inward toward domain. Domain depends on nothing external.
2. Ports = interfaces (in domain), Adapters = implementations (in infrastructure)
3. Benefit: swap infrastructure (DB, queue, framework) without touching business logic
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

[TODO: Include if 2+ named alternatives exist for Hexagonal and Clean Architecture. Otherwise remove this section.]
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

**Q1: How would you structure a microservice using Hexagonal Architecture? Show the package layout.**

_Why they ask:_ Tests practical architecture application, not just theory.

_Strong answer:_

For an Order Service:

```
order-service/
  domain/
    model/Order.java, LineItem.java, Money.java
    event/OrderCreatedEvent.java
    port/
      in/PlaceOrderPort.java (interface)
      in/CancelOrderPort.java
      out/OrderStore.java (interface)
      out/PaymentGateway.java (interface)
      out/EventPublisher.java (interface)

  application/
    PlaceOrderService.java (implements PlaceOrderPort)
    CancelOrderService.java

  adapter/
    in/
      rest/OrderController.java
      grpc/OrderGrpcService.java
      kafka/OrderEventConsumer.java
    out/
      persistence/JpaOrderStore.java
      payment/StripePaymentGateway.java
      messaging/KafkaEventPublisher.java

  config/
    OrderServiceConfig.java (wires adapters to ports)
```

Key rules:

- `domain/` has ZERO framework imports (no Spring, no JPA annotations)
- `application/` imports domain only
- `adapter/` imports everything (bridges framework to domain)
- Tests: domain and application tested with plain JUnit + mocks. Adapters tested with integration tests.
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

# Domain-Driven Design

**TL;DR** - Domain-Driven Design (DDD) is a software design approach that models complex business domains by aligning code structure with business language (Ubiquitous Language) and organizing around Bounded Contexts. It reduces the gap between business requirements and code.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Developers model the domain using technical concepts (tables, services, DTOs) instead of business concepts. Business experts say "loan origination" but code has `LoanService.process()`. When requirements change, developers can't map business rules to code. Every domain change is a treasure hunt through technical layers.
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
Write code using the same words the business uses. If business says "Place Order," code has `placeOrder()`. If they say "Order is Fulfilled," code has `OrderStatus.FULFILLED`. No translation layer between business and code.

**Level 2 - How to use it (junior developer):**

**Key DDD concepts:**

| Concept             | What                                    | Example                           |
| ------------------- | --------------------------------------- | --------------------------------- |
| Entity              | Has identity, lifecycle                 | `Order` (has orderId)             |
| Value Object        | Defined by attributes, immutable        | `Money(100, USD)`, `Address`      |
| Aggregate           | Cluster of entities, one root           | `Order` (root) + `LineItems`      |
| Repository          | Persistence abstraction                 | `OrderRepository`                 |
| Domain Service      | Logic that doesn't belong to one entity | `PricingService`                  |
| Domain Event        | Something that happened                 | `OrderPlacedEvent`                |
| Ubiquitous Language | Shared vocabulary                       | "Place Order" not "Insert Record" |

**Level 3 - How it works (mid-level engineer):**

**Aggregate design rules:**

```java
// Aggregate Root: Order
// Only access LineItems THROUGH Order
public class Order {  // Aggregate Root
    private OrderId id;
    private List<LineItem> items;  // child entity
    private Money total;           // value object
    private OrderStatus status;

    // Invariant enforced by aggregate
    public void addItem(Product product, int qty) {
        if (status != DRAFT)
            throw new IllegalStateException(
                "Cannot modify confirmed order");
        items.add(new LineItem(product, qty));
        total = recalculate();
    }

    // Transactional boundary = one aggregate
    public void confirm() {
        if (items.isEmpty())
            throw new IllegalStateException(
                "Cannot confirm empty order");
        status = CONFIRMED;
        registerEvent(new OrderConfirmedEvent(id));
    }
}

// BAD: Accessing child entity directly
lineItemRepository.save(lineItem); // NO!

// GOOD: Always through aggregate root
order.addItem(product, 2);
orderRepository.save(order); // Saves entire aggregate
```

**Key rules:**

1. One transaction = one aggregate (don't span aggregates in one TX)
2. Reference other aggregates by ID only (not direct object reference)
3. Aggregate root enforces all invariants
4. Keep aggregates small (1 root + few children)

**Level 4 - Mastery (senior/staff+ engineer):**

**Strategic DDD (system-level design):**

**Context Map for e-commerce:**

```
+-----------+     +------------+
| Ordering  |---->| Payments   |
| Context   |     | Context    |
+-----------+     +------------+
     |                  |
     v                  v
+-----------+     +------------+
| Inventory |     | Shipping   |
| Context   |     | Context    |
+-----------+     +------------+
     |
     v
+-----------+
| Catalog   |
| Context   |
+-----------+
```

**Anti-Corruption Layer (ACL):**
When integrating with a legacy system or external API whose model doesn't match yours:

```java
// External payment API uses different terms
public class StripePaymentAdapter
        implements PaymentPort {

    public PaymentResult charge(Money amount,
            CustomerId customer) {
        // Translate OUR domain model
        // to Stripe's model (ACL)
        StripeCharge charge = new StripeCharge();
        charge.setAmountCents(
            amount.toCents());
        charge.setCustomer(
            stripeCustomerMap.get(customer));

        // Call Stripe
        StripeResponse resp =
            stripeClient.charge(charge);

        // Translate Stripe's response
        // back to OUR domain model (ACL)
        return toPaymentResult(resp);
    }
}
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
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

1. Ubiquitous Language: code uses the same words as the business domain
2. Aggregate = transactional boundary. One TX = one aggregate. Reference others by ID.
3. Bounded Context = service boundary where a domain model has consistent meaning
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

[TODO: Include if 2+ named alternatives exist for Domain-Driven Design. Otherwise remove this section.]
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

**Q1: How do you decide aggregate boundaries? What's the consequence of making aggregates too large?**

_Why they ask:_ Tests practical DDD application.

_Strong answer:_

**Aggregate boundary decision criteria:**

1. **Invariant scope:** What data must be consistent in a single transaction? That's one aggregate.
2. **Concurrency boundary:** One aggregate = one lock. Large aggregate = more contention.
3. **Size:** Prefer small. If in doubt, split.

**Example - Order with 10,000 line items:**

```
// BAD: Order aggregate contains all line items
// Loading Order loads 10K items into memory
// Any item change locks entire Order
Order -> [10,000 LineItems]

// GOOD: Separate aggregates
// Order has summary (itemCount, total)
// Each LineItem is its own aggregate
// Referenced by orderId
Order { orderId, status, total, itemCount }
LineItem { lineItemId, orderId, sku, qty, price }

// Trade-off: cross-aggregate consistency
// is eventual, not transactional
// Order.total updated via domain event
// when LineItem changes
```

**Too-large aggregate consequences:**

- Memory: loading one entity loads entire graph
- Concurrency: one lock per aggregate = serialized access
- Performance: saving one change persists entire aggregate
- Latency: cross-context references become slow

Rule of thumb: If an aggregate regularly exceeds 100 child entities, it's too large. Split by extracting children into their own aggregates with ID references.
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

**TL;DR** - The Saga pattern manages distributed transactions by breaking them into a sequence of local transactions, each with a compensating action for rollback. Unlike 2PC, sagas don't hold locks across services, trading atomicity for availability and performance.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Microservices each own their database. You can't use a single ACID transaction across 4 databases in 4 services. 2PC holds locks and blocks on coordinator failure. You need a way to maintain data consistency across services without distributed locks.
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
Instead of one big transaction, execute a chain of small transactions. If step 3 fails, undo steps 2 and 1 with compensating actions (like refunding a payment if shipping fails).

**Level 2 - How to use it (junior developer):**

**Two saga styles:**

**Choreography (event-driven, decentralized):**

```
Order Svc: Create order -> publish OrderCreated
  -> Inventory Svc: Reserve stock
     -> publish StockReserved
       -> Payment Svc: Charge card
          -> publish PaymentCharged
            -> Shipping Svc: Create shipment

If Payment fails:
  -> publish PaymentFailed
    -> Inventory Svc: Release stock (compensate)
    -> Order Svc: Mark order failed (compensate)
```

**Orchestration (central coordinator):**

```
Saga Orchestrator:
  1. Tell Inventory: reserve stock
     - Success -> continue
     - Fail -> mark order failed, done
  2. Tell Payment: charge card
     - Success -> continue
     - Fail -> tell Inventory: release, done
  3. Tell Shipping: create shipment
     - Success -> mark order complete
     - Fail -> tell Payment: refund,
               tell Inventory: release, done
```

**Level 3 - How it works (mid-level engineer):**

**Choreography vs Orchestration:**

| Aspect     | Choreography                      | Orchestration               |
| ---------- | --------------------------------- | --------------------------- |
| Coupling   | Loose (events only)               | Central coordinator         |
| Visibility | Hard to see full flow             | Full saga state visible     |
| Complexity | Grows exponentially with steps    | Linear growth               |
| Debugging  | Follow events across services     | Check orchestrator state    |
| Best for   | 2-3 step sagas                    | 4+ step complex sagas       |
| Risk       | Cyclic dependencies, event storms | Coordinator is single point |

**Orchestrator implementation:**

```java
public class OrderSagaOrchestrator {

    public void execute(OrderRequest req) {
        SagaState state = SagaState.create(req);

        try {
            // Step 1
            state.markStep("RESERVE_STOCK");
            inventoryClient.reserve(req.items());

            // Step 2
            state.markStep("CHARGE_PAYMENT");
            paymentClient.charge(
                req.paymentInfo(), req.total());

            // Step 3
            state.markStep("CREATE_SHIPMENT");
            shippingClient.createShipment(
                req.address(), req.items());

            state.markComplete();
        } catch (Exception e) {
            compensate(state);
        }
    }

    private void compensate(SagaState state) {
        // Compensate in reverse order
        List<String> completed =
            state.completedSteps();
        Collections.reverse(completed);

        for (String step : completed) {
            switch (step) {
                case "CREATE_SHIPMENT":
                    shippingClient.cancel();
                    break;
                case "CHARGE_PAYMENT":
                    paymentClient.refund();
                    break;
                case "RESERVE_STOCK":
                    inventoryClient.release();
                    break;
            }
        }
        state.markFailed();
    }
}
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Saga state machine (robust implementation):**

```
States:
  STARTED -> STOCK_RESERVED -> PAYMENT_CHARGED
    -> SHIPMENT_CREATED -> COMPLETED

  Any state -> COMPENSATING -> COMPENSATED -> FAILED

Persistence:
  saga_instances table tracks:
  - saga_id, current_step, status
  - compensation_stack (JSON)
  - created_at, updated_at, retry_count
```

**Critical requirements:**

1. **Every step must be idempotent** (safe to retry)
2. **Every step needs a compensating action** (undo)
3. **Saga state must be persisted** (survive crashes)
4. **Compensations must also be idempotent** (might run multiple times)

**What sagas CANNOT guarantee:**

- Isolation: other transactions see intermediate states
  - Order is "pending" while payment processes
  - Workaround: semantic locks (status field as soft lock)
- Read consistency: queries during saga see partial updates




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
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

1. Choreography for simple sagas (2-3 steps), Orchestration for complex (4+)
2. Every step needs an idempotent compensating action
3. Sagas sacrifice isolation (intermediate states visible) for availability
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

**Q1: Design a saga for a travel booking (flight + hotel + car rental). What happens when the hotel booking fails after the flight is confirmed?**

_Why they ask:_ Tests compensation design in multi-step transactions.

_Strong answer:_

**Orchestrated Saga:**

```
TravelBookingSaga:
  Step 1: Book flight (compensate: cancel flight)
  Step 2: Book hotel (compensate: cancel hotel)
  Step 3: Book car (compensate: cancel car rental)
  Step 4: Charge payment (compensate: refund)
  Step 5: Send confirmation email
```

**Hotel fails after flight confirmed:**

```
Step 1: Book flight -> SUCCESS (confirmed)
Step 2: Book hotel -> FAILED (no rooms)
-> Compensate:
  Cancel flight booking (reverse step 1)

Compensation challenges:
- Flight cancellation may have fees
- Flight was already confirmed (can't just undo)
- Need business rules for cancellation policy
```

**Design considerations:**

1. **Reservation vs Confirmation:** Book flight as "tentative" first. Only confirm after all steps succeed. Tentative bookings auto-expire (TTL).

2. **Compensation isn't always free:** Cancellation fees, partial refunds. The saga must model business compensation, not just technical rollback.

3. **Timeout-based compensation:** If hotel doesn't respond in 60s, assume failure and compensate flight.

4. **Parallel execution:** Flight and hotel can be booked in parallel (independent). Car depends on both (same city). Payment depends on all three.

```
Optimized flow:
  [Flight] + [Hotel] (parallel)
    -> Both succeed -> [Car]
      -> Success -> [Payment]
        -> Success -> [Confirm all + Email]
    -> Either fails -> compensate completed ones
```

5. **Dead letter handling:** If compensation fails (can't cancel flight due to airline API down), put in dead letter queue. Ops dashboard for manual resolution. Alert + SLA for resolution.
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

# Event Sourcing

**TL;DR** - Event Sourcing stores every state change as an immutable event rather than overwriting current state. Current state is derived by replaying events. This provides a complete audit trail, temporal queries ("what was the state at 3pm?"), and enables event-driven architectures.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Database stores only current state: `balance = $500`. How did it get there? Who changed it? What was it yesterday at 3pm? Traditional databases lose this history. Audit requirements force you to build separate logging. Bugs in state calculation are unrecoverable.
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
Instead of recording "bank balance is $500," record every transaction: "deposited $1000," "withdrew $300," "deposited $200," "withdrew $400." Current balance is always derivable: $1000 - $300 + $200 - $400 = $500.

**Level 2 - How to use it (junior developer):**

```java
// Traditional: store current state
UPDATE accounts SET balance = 500
    WHERE id = 'acc-1';
// History lost!

// Event Sourced: store events
INSERT INTO events (aggregate_id, type, data)
VALUES
  ('acc-1', 'AccountOpened', '{"owner":"Alice"}'),
  ('acc-1', 'MoneyDeposited', '{"amount":1000}'),
  ('acc-1', 'MoneyWithdrawn', '{"amount":300}'),
  ('acc-1', 'MoneyDeposited', '{"amount":200}'),
  ('acc-1', 'MoneyWithdrawn', '{"amount":400}');

// Current state = replay events:
// 0 + 1000 - 300 + 200 - 400 = 500
```

**Level 3 - How it works (mid-level engineer):**

**Event Store structure:**

```
events table:
| seq | aggregate_id | type            | data              | timestamp           |
|-----|-------------|-----------------|-------------------|---------------------|
| 1   | order-42    | OrderCreated    | {items:[...]}     | 2024-01-15 10:00:00 |
| 2   | order-42    | ItemAdded       | {sku:"ABC",qty:2} | 2024-01-15 10:01:00 |
| 3   | order-42    | OrderConfirmed  | {total:150.00}    | 2024-01-15 10:05:00 |
| 4   | order-42    | PaymentReceived | {method:"card"}   | 2024-01-15 10:06:00 |
| 5   | order-42    | OrderShipped    | {tracking:"XYZ"}  | 2024-01-16 14:00:00 |
```

**Rebuilding state:**

```java
public class Order {
    private OrderId id;
    private List<LineItem> items = new ArrayList<>();
    private OrderStatus status;
    private Money total;

    // Rebuild from events
    public static Order fromEvents(
            List<DomainEvent> events) {
        Order order = new Order();
        for (DomainEvent event : events) {
            order.apply(event);
        }
        return order;
    }

    private void apply(DomainEvent event) {
        switch (event) {
            case OrderCreated e ->
                this.id = e.orderId();
            case ItemAdded e ->
                this.items.add(e.toLineItem());
            case OrderConfirmed e -> {
                this.status = CONFIRMED;
                this.total = e.total();
            }
            case OrderShipped e ->
                this.status = SHIPPED;
        }
    }
}
```

**Snapshots (performance optimization):**

```
Problem: Order with 10,000 events takes
  10,000 replays to rebuild state.

Solution: Periodic snapshot
  Every 100 events, store current state:

  Snapshot at event 9900: {balance: $4500}
  Then replay only events 9901-10000

  Rebuild = load snapshot + replay 100 events
  Instead of replaying 10,000
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Schema evolution (events are immutable but schemas change):**

```java
// v1 event:
{ "type": "AddressChanged",
  "address": "123 Main St" }

// v2 event (structured address):
{ "type": "AddressChanged",
  "street": "123 Main St",
  "city": "NYC", "zip": "10001" }

// Upcaster: transforms v1 -> v2 on read
public class AddressChangedUpcaster {
    public DomainEvent upcast(JsonNode raw) {
        if (!raw.has("street")) {
            // Parse v1 format into v2
            return parseV1Address(
                raw.get("address").asText());
        }
        return parseV2(raw);
    }
}
```

**When to use Event Sourcing:**

| Good fit                        | Bad fit                       |
| ------------------------------- | ----------------------------- |
| Financial systems (audit trail) | Simple CRUD apps              |
| Complex domain with rich events | Read-heavy, write-light       |
| Temporal queries needed         | No audit requirements         |
| Event-driven architecture       | Team unfamiliar with patterns |
| Regulatory compliance           | Short-lived data              |




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
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

1. Store events (facts), derive state by replay. Events are immutable.
2. Snapshots solve replay performance (snapshot every N events)
3. Schema evolution via upcasters - transform old events to new schema on read
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

[TODO: Include if 2+ named alternatives exist for Event Sourcing. Otherwise remove this section.]
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

**Q1: Design an event-sourced banking system. How do you handle a balance check before withdrawal?**

_Why they ask:_ Tests understanding of commands, events, and consistency.

_Strong answer:_

**Command flow:**

```
WithdrawCommand { accountId, amount: 300 }

1. Load account aggregate:
   - Load latest snapshot (if exists)
   - Replay events since snapshot
   - Current state: balance = $500

2. Validate command against current state:
   - balance ($500) >= withdrawal ($300)? YES
   - Account active? YES

3. Emit event:
   MoneyWithdrawn { accountId, amount: 300,
                    newBalance: 200 }

4. Persist event to event store
   (append-only, optimistic concurrency)

5. Update read model (projection):
   Account balance view: $200
```

**Concurrency control (two simultaneous withdrawals):**

```
Account balance: $500
Withdraw A: $400  (concurrent)
Withdraw B: $300  (concurrent)

Without protection: both see $500, both succeed
  -> balance = $500 - $400 - $300 = -$200 (overdraft!)

Solution: Optimistic concurrency on event store
  - Each event has expected_version
  - Withdraw A: append event version 5 -> SUCCESS
  - Withdraw B: append event version 5 -> CONFLICT
  - Withdraw B retries: reload (balance=$100)
    $100 < $300 -> REJECTED
```

```java
// Optimistic concurrency
void appendEvent(String aggregateId,
        DomainEvent event,
        long expectedVersion) {
    int rows = jdbcTemplate.update(
        "INSERT INTO events (...) " +
        "SELECT ... WHERE version = ?",
        expectedVersion);
    if (rows == 0)
        throw new ConcurrencyException(
            "Aggregate modified concurrently");
}
```
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

# Strangler Fig Pattern

**TL;DR** - The Strangler Fig pattern incrementally replaces a legacy system by building new functionality alongside it, gradually routing traffic from old to new until the legacy system can be decommissioned. Named after strangler fig trees that grow around a host tree.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
"Big bang rewrite" - rebuild the entire system from scratch, then switch over. Takes 18-24 months. During that time, the old system still needs maintenance (double the work). On switch day, everything breaks because the new system wasn't tested with real traffic. 70%+ of big-bang rewrites fail.
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
Instead of replacing the whole system at once, replace it one piece at a time. New features go to the new system. Old features migrate gradually. The old system slowly "dies" as traffic shifts away.

**Level 2 - How to use it (junior developer):**

```
Phase 1: Intercept
  [Users] -> [Proxy/Router] -> [Legacy System]

Phase 2: Strangle (piece by piece)
  [Users] -> [Proxy/Router] -> /orders/* -> [New Service]
                             -> /products/* -> [Legacy]
                             -> /users/* -> [Legacy]

Phase 3: More strangling
  [Users] -> [Proxy/Router] -> /orders/* -> [New Service]
                             -> /products/* -> [New Service]
                             -> /users/* -> [Legacy]

Phase 4: Complete
  [Users] -> [New System]  (Legacy decommissioned)
```

**Level 3 - How it works (mid-level engineer):**

**Implementation steps:**

1. **Add a proxy:** Place a reverse proxy (Nginx, API Gateway) in front of the legacy system. Initially routes 100% to legacy.

2. **Build new service for one feature:** Start with a bounded context that's well-isolated and high-value.

3. **Shadow traffic (optional):** Send copies of real requests to the new service, compare responses. Don't return new service responses to users yet.

4. **Canary route:** Route 5% of traffic for that feature to new service. Monitor errors, latency.

5. **Gradual rollout:** 5% -> 25% -> 50% -> 100% for that feature.

6. **Repeat** for next feature.

**Data migration strategy:**

```
Option A: Shared database (temporary)
  Both old and new services read/write same DB
  Risk: schema coupling
  Use when: quick win, plan to split later

Option B: Database per service + sync
  New service has own DB
  CDC (Change Data Capture) syncs from legacy DB
  New service writes to own DB
  Eventually: stop syncing, decommission legacy DB

Option C: API integration
  New service calls legacy API for data
  Gradually migrates data to own store
  Least risky, most gradual
```

**Level 4 - Mastery (senior/staff+ engineer):**

**Decision framework: What to strangle first:**

| Factor           | Strangle first        | Strangle last                |
| ---------------- | --------------------- | ---------------------------- |
| Change frequency | Changes weekly        | Stable for years             |
| Business value   | High-value feature    | Low-impact utility           |
| Coupling         | Few dependencies      | Core shared module           |
| Data complexity  | Simple, isolated data | Complex joins across domains |
| Risk tolerance   | Low blast radius      | Payment processing           |

**Anti-Corruption Layer (ACL) between old and new:**

```java
// New service speaks its own domain language
// ACL translates legacy model <-> new model

public class LegacyOrderAdapter
        implements OrderPort {

    private final LegacyOrderApi legacyApi;

    public Order getOrder(OrderId id) {
        // Legacy uses different model
        LegacyOrderRecord legacy =
            legacyApi.fetch(id.toString());

        // Translate to new domain model
        return Order.builder()
            .id(OrderId.of(legacy.getOrderNum()))
            .status(mapStatus(legacy.getStatCd()))
            .items(mapItems(legacy.getLineItems()))
            .build();
    }

    private OrderStatus mapStatus(String code) {
        return switch (code) {
            case "A" -> OrderStatus.ACTIVE;
            case "C" -> OrderStatus.COMPLETED;
            case "X" -> OrderStatus.CANCELLED;
            default -> OrderStatus.UNKNOWN;
        };
    }
}
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
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

1. Replace piece by piece through a routing proxy - never big-bang rewrite
2. Start with high-value, low-coupling features first
3. Use Anti-Corruption Layer to translate between legacy and new domain models
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

[TODO: Include if 2+ named alternatives exist for Strangler Fig Pattern. Otherwise remove this section.]
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

**Q1: You're migrating a 15-year-old monolith to microservices. Walk through your strangler fig strategy.**

_Why they ask:_ Tests practical migration planning.

_Strong answer:_

**Phase 0 - Preparation (2-4 weeks):**

- Map all monolith endpoints and their traffic volume
- Identify bounded contexts within the monolith
- Place API Gateway in front of monolith (routes 100% to monolith)
- Set up observability (distributed tracing, metrics) on gateway

**Phase 1 - First extraction (4-8 weeks):**

- Choose: Notification service (low risk, high isolation, async)
- Build notification microservice with own DB
- Shadow traffic: send copies to new service, compare behavior
- Canary: 5% -> 25% -> 100% over 2 weeks
- Decommission notification code in monolith

**Phase 2-N - Iterate:**

- Next: Authentication (well-defined boundary)
- Then: Product Catalog (read-heavy, easy to separate)
- Last: Order Processing (core domain, most coupled)

**Data strategy per phase:**

```
Phase 1 (Notifications):
  Own DB from day 1 (no shared state)

Phase 2 (Auth):
  Shared DB temporarily -> migrate users table
  -> Split DB after traffic fully routed

Phase 3 (Catalog):
  CDC from monolith DB -> new catalog DB
  Eventually: monolith reads FROM catalog service

Phase N (Orders - last):
  Most complex, most coupling
  By this point, most dependencies already extracted
  Order service becomes the "last monolith module"
```

**Risk mitigation:**

- Feature flags for routing (instant rollback)
- Shadow testing before live traffic
- Runbook for each migration phase
- Data reconciliation scripts (compare old and new)
- Keep monolith deployable until full migration complete
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

# Sidecar and Service Mesh

**TL;DR** - A sidecar is a co-deployed proxy that handles cross-cutting concerns (mTLS, retries, observability) for a service without modifying its code. A service mesh (Istio, Linkerd) is a dedicated infrastructure layer of sidecars that manages all service-to-service communication.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every microservice must implement: TLS, retries, circuit breakers, tracing, metrics, rate limiting, access control. 50 services in 5 languages = implementing these patterns 50 times. Library updates require redeploying all services.
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
A sidecar is a helper container that runs alongside your service and handles networking concerns. Instead of your Java/Python/Go code doing retries and encryption, the sidecar does it transparently.

**Level 2 - How to use it (junior developer):**

```
Without mesh:
  Service A -> HTTP -> Service B
  (A handles TLS, retries, tracing, auth)

With mesh:
  Service A -> localhost -> Sidecar A
    -> mTLS, retry, trace -> Sidecar B
      -> localhost -> Service B

  Services know nothing about networking.
  Mesh handles everything.
```

**What the sidecar handles:**

- **mTLS:** Encrypt all traffic between services (zero-trust)
- **Retries + Timeouts:** Automatic retry with backoff
- **Circuit breaking:** Stop calling failing services
- **Load balancing:** Client-side, topology-aware
- **Observability:** Metrics, traces, access logs (automatic)
- **Traffic management:** Canary deploys, A/B routing
- **Access control:** Service-to-service authorization

**Level 3 - How it works (mid-level engineer):**

**Istio architecture:**

```
Data Plane (per-pod sidecars):
  [App] <-> [Envoy proxy] -- mTLS -- [Envoy] <-> [App]

Control Plane (istiod):
  - Distributes config to all Envoys
  - Issues TLS certificates
  - Collects telemetry
```

**Traffic management (Istio VirtualService):**

```yaml
# Canary deployment: 90% to v1, 10% to v2
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: order-service
spec:
  hosts:
    - order-service
  http:
    - route:
        - destination:
            host: order-service
            subset: v1
          weight: 90
        - destination:
            host: order-service
            subset: v2
          weight: 10
```

**Level 4 - Mastery (senior/staff+ engineer):**

**When to use a service mesh (not always!):**

| Use when...                              | Avoid when...                        |
| ---------------------------------------- | ------------------------------------ |
| 20+ services in production               | < 10 services                        |
| Multiple languages/frameworks            | Homogeneous stack (all Spring Boot)  |
| Zero-trust security required             | Internal network trusted             |
| Complex traffic management (canary, A/B) | Simple deployments                   |
| Compliance requires mTLS everywhere      | Latency-critical (adds ~1ms per hop) |

**Cost of a service mesh:**

- **Latency:** +0.5-2ms per hop (sidecar processing)
- **Resource:** Each sidecar uses ~50-100MB RAM, ~0.1 CPU
- **Complexity:** Another infrastructure layer to operate
- **Debugging:** Network issues may be mesh config, not app code

**Alternatives to full mesh:**

- **Shared libraries** (Resilience4j, Spring Cloud): if single language
- **Ambient mesh** (Istio ambient): no sidecar, uses node-level proxy
- **eBPF-based** (Cilium): kernel-level networking, lower overhead




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
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

1. Sidecar = per-service proxy handling mTLS, retries, tracing automatically
2. Service mesh = coordinated fleet of sidecars + control plane
3. Adds ~1ms latency and ~100MB RAM per pod. Only worth it at 20+ services.
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

[TODO: Include if 2+ named alternatives exist for Sidecar and Service Mesh. Otherwise remove this section.]
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

**Q1: Your company has 50 microservices in 3 languages. How do you implement zero-trust networking?**

_Why they ask:_ Tests practical service mesh justification and design.

_Strong answer:_

**Problem:** 50 services, 3 languages. Need mTLS everywhere, service-to-service authorization, and audit logging. Can't implement in each service (150 implementations).

**Solution:** Istio service mesh.

**Implementation plan:**

1. **Install Istio** on K8s cluster (istioctl install)
2. **Enable sidecar injection** per namespace (gradual rollout)
3. **mTLS mode:** Start with `PERMISSIVE` (accepts both plain and mTLS), then switch to `STRICT` after all services have sidecars
4. **Authorization policies:** Define which services can talk to which

```yaml
# Only Order Service can call Payment Service
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: payment-access
  namespace: production
spec:
  selector:
    matchLabels:
      app: payment-service
  rules:
    - from:
        - source:
            principals:
              - "cluster.local/ns/production/sa/order-service"
      to:
        - operation:
            methods: ["POST"]
            paths: ["/api/charge"]
```

5. **Observability:** Automatic distributed tracing (Jaeger), metrics (Prometheus), access logs

**Rollout strategy:**

- Week 1: Install mesh, inject sidecars in staging
- Week 2-3: Inject in production (PERMISSIVE mode)
- Week 4: Switch to STRICT mTLS
- Week 5+: Add authorization policies service by service

**Why mesh over library approach:**

- 3 languages = 3 mTLS implementations to maintain
- Certificate rotation automated by mesh
- Authorization policies are infrastructure, not application code
- New services get zero-trust networking automatically
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
