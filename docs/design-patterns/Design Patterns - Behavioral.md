---
layout: default
title: "Design Patterns - Behavioral"
parent: "Design Patterns"
grand_parent: "Interview Mastery"
nav_order: 3
permalink: /interview/design-patterns/behavioral/
topic: Design Patterns
subtopic: Behavioral
keywords:
  - Strategy
  - Observer
  - Command
  - Template Method
  - State
  - Chain of Responsibility
difficulty_range: mixed
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Strategy](#strategy)
- [Observer](#observer)
- [Command](#command)
- [Template Method](#template-method)
- [State](#state)
- [Chain of Responsibility](#chain-of-responsibility)

# Strategy

**TL;DR** - Strategy defines a family of algorithms, encapsulates each one, and makes them interchangeable at runtime without changing the client code.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your e-commerce checkout calculates shipping costs. `if (method == "standard") cost = weight * 0.5; else if (method == "express") cost = weight * 1.5 + 10; else if (method == "overnight") cost = weight * 3.0 + 25;`. Adding "drone delivery" means modifying this class. Every pricing change requires changing core checkout logic. The conditional grows to 15 branches across 3 methods.

**THE BREAKING POINT:**
Different regions have different shipping rules. The US has standard/express/overnight. Europe has economy/priority. Asia has local/international. The if-else chain becomes a 200-line method that nobody dares to touch.

**THE INVENTION MOMENT:**
"This is exactly why Strategy was created."

**EVOLUTION:**
The GoF formalized Strategy in 1994. In Java, `Comparator` is the most widely used Strategy: `Collections.sort(list, comparator)`. Java 8 lambdas transformed Strategy from a pattern requiring full classes to a one-liner: `list.sort(Comparator.comparing(User::getName))`. Modern usage includes Spring's `AuthenticationStrategy`, validation strategies, and serialization strategies.
---

### 📘 Textbook Definition

Strategy is a behavioral design pattern that defines a family of algorithms, encapsulates each one in a separate class, and makes them interchangeable. Strategy lets the algorithm vary independently from the clients that use it.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Swap algorithms at runtime without changing the code that uses them.

**One analogy:**

> GPS navigation with route options. You choose "fastest," "shortest," or "avoid tolls." The navigation app doesn't change - it just uses a different routing algorithm based on your selection. You can switch strategies mid-trip.

**One insight:**
Strategy is the Open/Closed Principle applied to algorithms. The context (checkout) is closed for modification. New algorithms (shipping methods) are added without changing the context. The key: the algorithm is not just different logic - it's an entirely separate object with its own lifecycle.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. All strategies implement the same interface
2. The context delegates the algorithm to the strategy object
3. Strategies are interchangeable at runtime

**DERIVED DESIGN:**
The context holds a reference to a strategy interface. It calls the strategy's method when the algorithm is needed. The strategy can be swapped via constructor injection, setter, or method parameter. New strategies are added by implementing the interface - no context changes.

**THE TRADE-OFFS:**
**Gain:** Open/Closed for algorithms, runtime flexibility, each strategy is independently testable
**Cost:** Clients must know about strategies to select one, more objects in the system

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Selecting the right algorithm requires a decision point somewhere - Strategy moves that decision out of the algorithm
**Accidental:** In Java pre-8, each strategy required a class file; lambdas eliminated this boilerplate
---

### 🧠 Mental Model / Analogy

> Think of a taxi ride. You tell the driver the destination (context), but the driver chooses the route (strategy). You can request "avoid highways" or "fastest route" to change the strategy. The car and destination don't change - only the routing algorithm does.

- "Driver choosing route" -> strategy object
- "Destination" -> input to the algorithm
- "Car" -> context (unchanged)
- "Changing route preference" -> swapping strategy

Where this analogy breaks down: A taxi driver adapts dynamically; a Strategy object follows one algorithm strictly.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Strategy lets you change how something is done without changing what is done. Like choosing different payment methods at checkout - the purchase is the same, the payment mechanism differs.

**Level 2 - How to use it (junior developer):**
Define an interface (e.g., `ShippingCalculator`). Implement it for each algorithm (`StandardShipping`, `ExpressShipping`). Pass the implementation to your service via constructor. Call `calculator.calculate(order)` without knowing which implementation is running.

**Level 3 - How it works (mid-level engineer):**
Strategy eliminates conditional logic by replacing branches with polymorphism. Instead of `if/else`, you have a map of strategies: `Map<String, ShippingCalculator> strategies`. Look up the right one by key and call it. In Spring, inject all implementations as a `List<ShippingCalculator>` and build the map in `@PostConstruct`. Java 8+ makes simple strategies one-liners: `Function<Order, BigDecimal> calculator = order -> order.getWeight().multiply(rate);`.

**Level 4 - Mastery (senior/staff+ engineer):**
Strategy is the most common pattern in enterprise Java, often hidden behind frameworks. Spring's `AuthenticationManager` delegates to `AuthenticationProvider` strategies. Jackson's `SerializationFeature` selects serialization strategies. `java.util.Comparator` is a Strategy. The pattern's evolution: GoF (interface + classes) -> Java 8 (functional interfaces + lambdas) -> modern (strategy registry with auto-discovery). The decision framework: if you have 2-3 stable algorithms, if-else is fine. 4+ or frequently changing algorithms warrant Strategy. If the algorithm selection itself is complex, combine with Factory.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### ⚙️ How It Works

```
[Context]
    |
    +-- holds --> [Strategy interface]
    |                 |
    |        +--------+--------+
    |        |        |        |
    |    [StratA]  [StratB]  [StratC]
    |
    +-- context.execute()
         -> strategy.calculate(data)
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

**Example 1 - BAD: Conditional algorithm selection**

```java
// BAD: Adding new payment = modifying this class
public class PaymentService {
    public void pay(String type, BigDecimal amount) {
        if ("credit".equals(type)) {
            // 30 lines of credit card logic
        } else if ("paypal".equals(type)) {
            // 25 lines of PayPal logic
        } else if ("crypto".equals(type)) {
            // 20 lines of crypto logic
        }
    }
}
```

**Example 2 - GOOD: Strategy pattern**

```java
// GOOD: Each payment method is a strategy
public interface PaymentStrategy {
    PaymentResult pay(BigDecimal amount);
    String getType();
}

@Component
public class CreditCardPayment
        implements PaymentStrategy {
    public PaymentResult pay(BigDecimal amount) {
        // Credit card-specific logic
        return gateway.charge(amount);
    }
    public String getType() { return "credit"; }
}

@Service
public class PaymentService {
    private final Map<String, PaymentStrategy> strats;

    public PaymentService(
            List<PaymentStrategy> strategies) {
        strats = strategies.stream()
            .collect(Collectors.toMap(
                PaymentStrategy::getType,
                Function.identity()));
    }

    public PaymentResult pay(String type,
            BigDecimal amount) {
        var strategy = strats.get(type);
        if (strategy == null)
            throw new UnsupportedPayment(type);
        return strategy.pay(amount);
    }
}
```

**How to test / verify correctness:**
Test each strategy in isolation. Test the context with a mock strategy. Test strategy selection with unknown types.
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

1. Strategy extracts algorithms into interchangeable classes behind a common interface
2. `Comparator` is the most used Strategy in Java - you use it constantly
3. Spring's `@Autowired List<Strategy>` + map lookup is the modern idiomatic approach

**Interview one-liner:**
"Strategy encapsulates interchangeable algorithms behind a common interface - in Spring I use auto-discovered strategy beans with a registry map, which gives me Open/Closed compliance and zero switch statements."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

After Java 8, Strategy is the most common pattern in Java code - but developers don't recognize it. Every `Comparator`, every `Predicate`, every `Function` passed as a parameter is a Strategy. `stream.filter(x -> x.isActive())` uses a Strategy. The lambda revolution didn't kill Strategy - it made it so natural that it became invisible.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Strategy. Otherwise remove this section.]
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

**Q1: How would you implement a dynamic pricing engine using Strategy?**

_Why they ask:_ Tests practical application of the pattern to a real business problem.

**Answer:**
A pricing engine needs to apply different pricing rules based on customer segment, time of day, inventory level, and promotions. Each rule is a strategy:

```java
public interface PricingStrategy {
    BigDecimal calculatePrice(Product product,
        CustomerContext context);
    boolean appliesTo(CustomerContext context);
    int priority();
}
```

Strategies: `LoyaltyDiscount`, `BulkPricing`, `FlashSale`, `RegionalPricing`. The engine selects applicable strategies, sorts by priority, and applies them in order (or picks the best price). New rules are added as new strategy beans - zero changes to the engine.

The key insight: strategies can be composed. A `CompositePricingStrategy` chains multiple strategies, applying discounts sequentially. This turns a complex pricing matrix into a pipeline of simple, testable rules.

---

**Q2: Strategy vs if-else - when is if-else actually better?**

_Why they ask:_ Tests judgment about pattern appropriateness.

**Answer:**
If-else is better when:

1. **2-3 stable branches:** The overhead of creating interfaces, implementations, and registration isn't justified.
2. **The logic is trivial:** A 3-line branch doesn't need its own class.
3. **Performance-critical hot paths:** Polymorphic dispatch (virtual method call) is slower than a branch prediction-friendly if-else in tight loops.
4. **The variants are unlikely to change:** If your system only ever supports "metric" and "imperial," a simple if is clearer.

Strategy is better when:

1. **4+ variants** that grow over time
2. **Each variant has substantial logic** (10+ lines)
3. **Different teams own different variants**
4. **Runtime selection** is needed
5. **Testing requires isolation** of each algorithm

The smell: if your if-else chain is in a `switch` that you've modified 3+ times to add new cases, it's time for Strategy.
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

# Observer

**TL;DR** - Observer defines a one-to-many dependency between objects so that when one object changes state, all dependents are notified and updated automatically.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your stock trading application has a price feed. The dashboard, the alert system, the logging service, and the portfolio calculator all need to know when a price changes. Without Observer, each component polls the price feed every 100ms. With 50 components, that's 500 polls per second - most returning "no change." The price feed is overwhelmed with redundant requests.

**THE BREAKING POINT:**
A new component needs price updates. You modify the price feed class to call the new component directly. The price feed now depends on dashboard, alerts, logging, portfolio, and the new component. It's a tightly coupled monolith.

**THE INVENTION MOMENT:**
"This is exactly why Observer was created."

**EVOLUTION:**
The GoF formalized Observer in 1994. Java had `java.util.Observable` (deprecated in Java 9 - poorly designed). Modern incarnations include: event listeners in every GUI framework, `PropertyChangeListener` in JavaBeans, reactive streams (RxJava, Project Reactor), JavaScript's `addEventListener`, Spring's `ApplicationEventPublisher`, and message brokers (Kafka, RabbitMQ) as distributed observers.
---

### 📘 Textbook Definition

Observer is a behavioral design pattern that defines a subscription mechanism to notify multiple objects about any events that happen to the object they're observing. It establishes a one-to-many dependency between a subject and its observers, where the subject maintains a list of observers and notifies them of state changes.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
When something changes, everyone who cares gets notified automatically.

**One analogy:**

> A newspaper subscription. You subscribe once. Every morning, the newspaper is delivered to your door. You don't check the printing press every hour. When you lose interest, you unsubscribe. The newspaper doesn't know or care what you do with it.

**One insight:**
Observer decouples the "what happened" from the "who cares." The subject broadcasts events without knowing its observers. Observers react without knowing each other. This loose coupling is why event-driven architectures scale: producers and consumers can evolve independently.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Subject maintains a list of observers
2. Subject notifies all observers when state changes
3. Observers can subscribe and unsubscribe dynamically

**DERIVED DESIGN:**
The subject provides `subscribe(observer)` and `unsubscribe(observer)` methods. On state change, it iterates the observer list and calls each observer's update method. The observer decides what to do with the notification. Push model: subject sends the data. Pull model: subject sends "I changed," observer queries for data.

**THE TRADE-OFFS:**
**Gain:** Loose coupling, dynamic relationships, broadcast communication
**Cost:** Memory leaks (forgotten subscriptions), update ordering is undefined, debugging event chains is hard

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Someone must maintain the subscription list and trigger notifications - this coordination is inherent
**Accidental:** Memory leaks from forgotten unsubscribe calls - weak references or scoped subscriptions mitigate this
---

### 🧠 Mental Model / Analogy

> Think of Observer as a group chat. When someone posts a message, everyone in the group sees it. Members can join or leave the group anytime. The poster doesn't address individuals - they post to the group. Each member decides whether to read or ignore the message.

- "Group chat" -> subject
- "Members" -> observers
- "Posting a message" -> notifying observers
- "Join/leave group" -> subscribe/unsubscribe

Where this analogy breaks down: In a group chat, members can respond to each other; in Observer, observers typically don't interact - they only react to the subject.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Observer is like following someone on social media. When they post, you see it in your feed automatically. You don't need to check their profile every minute.

**Level 2 - How to use it (junior developer):**
Create a subject that maintains a `List<Observer>`. When the subject's state changes, call `observer.update()` for each observer. Observers implement the `update()` method to react. In Spring, use `@EventListener` and `ApplicationEventPublisher` instead of implementing the pattern from scratch.

**Level 3 - How it works (mid-level engineer):**
Two notification models: **Push** (subject sends data in the notification - observer gets everything) and **Pull** (subject sends a change signal, observer queries for what it needs - more flexible but requires the subject to expose state). Spring's event system is push-based: `publisher.publishEvent(new OrderCreatedEvent(order))`. Observers annotated with `@EventListener` receive the typed event. For async notification, add `@Async` to the listener.

**Level 4 - Mastery (senior/staff+ engineer):**
Observer at scale becomes event-driven architecture. In-process Observer (subject calling listeners) has limitations: synchronous by default, single JVM, no persistence, no replay. Distributed Observer (Kafka, RabbitMQ) adds: async delivery, persistence, replay, multiple consumers, backpressure. The pattern evolves from `subject.notify()` to `broker.publish(topic, event)`. Reactive Streams (Project Reactor, RxJava) formalize Observer with backpressure: the observer can signal how many events it can handle. This solves the "fast producer, slow consumer" problem that crashes naive Observer implementations.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### ⚙️ How It Works

```
[Subject]
    |
    +-- observers: List<Observer>
    +-- subscribe(obs)
    +-- unsubscribe(obs)
    +-- notifyAll()
    |       |
    |   for each observer:
    |       observer.update(state)
    |
    +-- setState(new)
         -> notifyAll()

[Observer A] <-- update(state) -- [Subject]
[Observer B] <-- update(state) --/
[Observer C] <-- update(state) -/
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

**Example 1 - BAD: Tight coupling**

```java
// BAD: Subject knows all its consumers
public class PriceFeed {
    private Dashboard dashboard;
    private AlertService alerts;
    private Logger logger;
    // Adding a new consumer = modifying this class

    public void updatePrice(String symbol, double p) {
        this.price = p;
        dashboard.refresh(symbol, p);
        alerts.check(symbol, p);
        logger.log(symbol, p);
    }
}
```

**Example 2 - GOOD: Observer pattern (Spring events)**

```java
// GOOD: Publisher knows nothing about consumers
public record PriceChangedEvent(
    String symbol, BigDecimal price,
    Instant timestamp) {}

@Service
public class PriceFeed {
    private final ApplicationEventPublisher pub;

    public PriceFeed(ApplicationEventPublisher pub) {
        this.pub = pub;
    }

    public void updatePrice(String symbol,
            BigDecimal price) {
        // Publish - don't know who listens
        pub.publishEvent(new PriceChangedEvent(
            symbol, price, Instant.now()));
    }
}

// Any component can listen - zero coupling
@Component
public class DashboardUpdater {
    @EventListener
    public void onPriceChange(PriceChangedEvent e) {
        refreshDisplay(e.symbol(), e.price());
    }
}

@Component
public class PriceAlertService {
    @Async
    @EventListener
    public void onPriceChange(PriceChangedEvent e) {
        checkAlertThresholds(e.symbol(), e.price());
    }
}
```

**How to test / verify correctness:**
Test the subject publishes events on state change. Test each observer independently with synthetic events. Test subscribe/unsubscribe lifecycle. Test that removing an observer stops it from receiving updates.
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

1. Observer decouples "something happened" from "who cares about it"
2. Memory leaks from forgotten subscriptions are the #1 production issue
3. At scale, Observer evolves into event-driven architecture (Kafka, Spring Events)

**Interview one-liner:**
"Observer establishes a publish-subscribe relationship where the subject notifies registered observers of state changes - in Spring I use ApplicationEventPublisher with @EventListener, adding @Async for non-blocking notification."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

The entire JavaScript DOM event system is an Observer pattern. Every `addEventListener('click', handler)` is subscribing an observer. Every `removeEventListener` is unsubscribing. Every DOM event that bubbles up is notification propagation. The browser runtime is essentially a massive Observer implementation managing millions of subscriptions. This is also why memory leaks in single-page applications are almost always caused by forgotten event listeners - the Observer pattern's classic failure mode.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Observer. Otherwise remove this section.]
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

**Q1: What's the difference between Observer and Pub/Sub?**

_Why they ask:_ Tests understanding of pattern evolution and distributed systems.

**Answer:**
| Aspect | Observer (GoF) | Pub/Sub |
| ----------- | --------------------------- | --------------------------- |
| Coupling | Subject knows observers | Producers don't know consumers |
| Broker | No intermediate | Message broker mediates |
| Location | Same process | Can be distributed |
| Delivery | Synchronous (default) | Asynchronous |
| Persistence | No | Messages can be persisted |
| Replay | No | Kafka allows replay |

Observer is the in-process version. Pub/Sub is Observer distributed across processes/machines with a broker in between. The evolution: Observer -> EventBus (in-process, decoupled) -> Pub/Sub (distributed, persistent).

In practice, I start with Spring's `ApplicationEventPublisher` (Observer) and graduate to Kafka (Pub/Sub) when I need cross-service communication, persistence, or replay.

---

**Q2: How do you prevent memory leaks with Observer?**

_Why they ask:_ Tests production awareness of the pattern's most common failure.

**Answer:**
Memory leaks occur when an observer subscribes but never unsubscribes. The subject holds a strong reference, preventing garbage collection.

Prevention strategies:

1. **Weak references:** Subject holds `WeakReference<Observer>`. When the observer is GC'd, the reference becomes null. Check for nulls during notification.
2. **Scoped subscriptions:** Tie observer lifecycle to a scope (HTTP request, session, component lifecycle). `@EventListener` in Spring is scoped to the bean lifecycle automatically.
3. **Subscription tokens:** `subscribe()` returns a `Subscription` object with a `cancel()` method. Callers must hold and cancel it.
4. **Reactive dispose:** In RxJava/Reactor, `Disposable d = flux.subscribe(...)` returns a disposable. Call `d.dispose()` in cleanup.
5. **Audit logging:** Log subscribe/unsubscribe events. Monitor observer count over time - it should be stable, not growing.
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

# Command

**TL;DR** - Command encapsulates a request as an object, allowing you to parameterize clients with operations, queue requests, log them, and support undo/redo.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your text editor has 20 operations: copy, paste, bold, italic, indent, etc. Each toolbar button directly calls the operation method. Now you need undo. You'd have to add undo logic to every one of the 20 button handlers. Then redo. Then macro recording. Then keyboard shortcuts that trigger the same operations as buttons. The coupling between UI triggers and operations becomes unmanageable.

**THE BREAKING POINT:**
A new requirement: audit logging of every operation. Without a unified abstraction for "an operation that was performed," you add logging code to every handler separately. Some get missed.

**THE INVENTION MOMENT:**
"This is exactly why Command was created."

**EVOLUTION:**
The GoF formalized Command in 1994. It's the foundation of undo/redo in every editor (VS Code, IntelliJ, Photoshop). Modern incarnations include: CQRS (commands separate from queries), event sourcing (commands become the event log), task queues (commands serialized and executed asynchronously), and transaction logs (WAL in databases is essentially a command log).
---

### 📘 Textbook Definition

Command is a behavioral design pattern that turns a request into a stand-alone object containing all information about the request. This transformation lets you pass requests as method arguments, delay or queue a request's execution, and support undoable operations.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Turn actions into objects so you can store, queue, undo, and replay them.

**One analogy:**

> A restaurant order slip. The waiter writes your order on a slip (command object). The slip can be queued (put on the order rail), executed later (chef cooks it), logged (receipt), or cancelled (torn up). The waiter doesn't cook - they just create command objects.

**One insight:**
Command's real power isn't executing operations - it's making operations into first-class citizens. Once an action is an object, you get an entire vocabulary for free: undo, redo, queue, schedule, retry, log, replay, batch. This is why event sourcing works: every state change is a command object stored forever.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. The command encapsulates all information needed to perform the action
2. The invoker triggers the command without knowing what it does
3. Commands can be stored, queued, and reversed

**DERIVED DESIGN:**
Each command implements an `execute()` method (and optionally `undo()`). The invoker holds command objects and calls `execute()` when triggered. Commands are decoupled from both the trigger (button, API call, schedule) and the receiver (the object that actually performs the work).

**THE TRADE-OFFS:**
**Gain:** Decouple trigger from action, enable undo/redo/replay, support queuing and scheduling
**Cost:** More classes (one per command), complexity for simple operations

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Undo requires storing the inverse of every operation - this state must live somewhere
**Accidental:** In functional languages, commands are just functions with closures - no class ceremony needed
---

### 🧠 Mental Model / Analogy

> Think of Command as a to-do list item. Writing "Buy groceries" on the list doesn't buy groceries - it creates a record of the intention. The list can be reordered (priority), delegated (someone else executes), postponed (scheduled), or crossed off (marked done). The list decouples "deciding what to do" from "doing it."

- "Writing the item" -> creating the command object
- "List" -> command queue
- "Crossing off" -> execute()
- "Erasing" -> undo()

Where this analogy breaks down: A to-do item doesn't contain all execution details; a Command object contains everything needed to execute.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Command turns an action into an object. Instead of immediately doing something, you create a "do this" object that can be stored, passed around, and executed later. Like writing a check instead of handing over cash directly.

**Level 2 - How to use it (junior developer):**
Create a `Command` interface with `execute()`. Each operation is a class: `BoldCommand`, `PasteCommand`. The button doesn't call the operation directly - it stores and triggers a Command. For undo, add an `undo()` method and keep a history stack. Pop the stack to undo.

**Level 3 - How it works (mid-level engineer):**
Command is the bridge between UI and business logic. In CQRS, "commands" (write operations) are literally Command objects: `CreateOrderCommand`, `UpdateInventoryCommand`. They're validated, authorized, and executed by command handlers. The separation from queries (read operations) allows independent scaling and optimization. Spring's `@Async` + command objects enables fire-and-forget execution. Combined with a message queue, commands can survive application restarts.

**Level 4 - Mastery (senior/staff+ engineer):**
Command + Event Sourcing is one of the most powerful architectural combinations. Every state change is a command that produces an event. The event log is the source of truth. You can replay events to reconstruct any past state, build new read models, or audit every action. The trade-off: eventual consistency and complex event versioning. In practice, I use Command for: (1) operations that need undo/redo, (2) operations that need audit logging, (3) operations that need queuing (background jobs), (4) CQRS write sides. For simple CRUD without these needs, Command adds unnecessary ceremony.




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### ⚙️ How It Works

```
[Invoker] -- triggers --> [Command]
                             |
                         execute()
                             |
                    [Receiver.action()]

Undo stack:
[Cmd1] [Cmd2] [Cmd3] <- top
                  |
              undo() -> reverse Cmd3
          [Cmd1] [Cmd2] <- new top
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

**Example 1 - BAD: Direct coupling between trigger and action**

```java
// BAD: Button directly calls editor methods
// No undo, no logging, no queuing possible
public class ToolbarButton {
    private TextEditor editor;

    public void onBoldClick() {
        editor.makeBold();  // Direct call
        // How to undo this? How to log it?
    }
}
```

**Example 2 - GOOD: Command pattern with undo**

```java
// GOOD: Operations as objects
public interface Command {
    void execute();
    void undo();
}

public class BoldCommand implements Command {
    private final TextEditor editor;
    private final Selection selection;
    private String previousState;

    public BoldCommand(TextEditor editor) {
        this.editor = editor;
        this.selection = editor.getSelection();
    }

    @Override
    public void execute() {
        previousState = editor.getState(selection);
        editor.makeBold(selection);
    }

    @Override
    public void undo() {
        editor.restoreState(selection, previousState);
    }
}

public class CommandHistory {
    private final Deque<Command> history =
        new ArrayDeque<>();

    public void execute(Command cmd) {
        cmd.execute();
        history.push(cmd);
    }

    public void undo() {
        if (!history.isEmpty()) {
            history.pop().undo();
        }
    }
}
```

**How to test / verify correctness:**
Test that `execute()` produces the expected state change. Test that `undo()` restores the previous state exactly. Test undo stack with multiple commands.
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

1. Command turns actions into objects, enabling undo, redo, queue, and logging
2. CQRS is Command pattern at the architecture level
3. Use it when you need operation history; skip it for simple CRUD

**Interview one-liner:**
"Command encapsulates an action as an object with execute() and undo() - it's the foundation of undo/redo systems, CQRS write models, and any system that needs to queue, log, or replay operations."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Every database transaction log (Write-Ahead Log / WAL) is a Command pattern implementation. Each log entry is a command: "insert row X," "update column Y." On crash recovery, the database replays the log to reconstruct state. PostgreSQL's WAL, MySQL's redo log, and Kafka's commit log all implement the same idea: commands stored as the source of truth, with the current state being a derived materialization. Event sourcing didn't invent this - databases have done it for decades.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Command. Otherwise remove this section.]
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

**Q1: How does Command relate to CQRS?**

_Why they ask:_ Tests understanding of the pattern at architectural scale.

**Answer:**
CQRS (Command Query Responsibility Segregation) is the Command pattern elevated to architecture:

- **Commands** = write operations. Each is a Command object: `CreateOrderCommand(userId, items)`. Validated by a command handler, persisted, and published as events.
- **Queries** = read operations. Separate models optimized for reading. No commands involved.

The benefits compound: commands can be queued (handle spikes), validated independently (security), logged (audit trail), replayed (debugging), and versioned (backward compatibility). The read model can be optimized for each query pattern (denormalized, cached, materialized views).

The cost: eventual consistency between write and read models, complexity of event handling, and the need for idempotent command handlers.

---

**Q2: When is Command pattern overkill?**

_Why they ask:_ Tests judgment about pattern appropriateness.

**Answer:**
Command is overkill when:

1. **Simple CRUD with no undo:** If your app just creates, reads, updates, and deletes without operation history, a direct service call is simpler and more maintainable.

2. **No queuing needed:** If operations are always executed immediately and synchronously, the Command object adds a layer of indirection without benefit.

3. **Trivial operations:** A command that just calls `repository.save(entity)` with no validation, no side effects, and no undo is unnecessary ceremony.

4. **Small team, simple domain:** The organizational benefit of Command (different teams own different commands) doesn't apply to a 3-person team.

Use Command when: operations need undo/redo, audit logging, queuing, scheduling, or when CQRS is warranted by scale requirements.
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

# Template Method

**TL;DR** - Template Method defines the skeleton of an algorithm in a superclass but lets subclasses override specific steps without changing the algorithm's structure.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your data import system processes CSV, JSON, and XML files. Each format follows the same steps: open file, parse records, validate, transform, store. But the parse step differs for each format. Without Template Method, you duplicate the 5-step algorithm three times, changing only the parse step. Bug fixes to validation must be applied in three places.

**THE BREAKING POINT:**
A new requirement adds logging between each step. You modify all three implementations. One developer adds it to CSV and JSON but misses XML. The bug is discovered in production a week later.

**THE INVENTION MOMENT:**
"This is exactly why Template Method was created."

**EVOLUTION:**
The GoF formalized it in 1994. Java uses it extensively: `AbstractList.get()` is abstract while `indexOf()` uses it. `HttpServlet.service()` dispatches to `doGet()`, `doPost()` - the template method. Spring's `JdbcTemplate`, `RestTemplate`, and `AbstractController` all use Template Method. Modern alternatives include Strategy (composition over inheritance) and functional hooks.
---

### 📘 Textbook Definition

Template Method is a behavioral design pattern that defines the skeleton of an algorithm in a base class and lets subclasses override specific steps without changing the overall algorithm structure. The base class controls the sequence; subclasses customize individual steps.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Define the algorithm's skeleton once; let subclasses fill in the specific steps.

**One analogy:**

> Building a house from a blueprint. The blueprint (template method) defines the sequence: foundation, framing, roofing, finishing. Each builder (subclass) uses different materials for each step, but the sequence never changes. You can't put the roof on before the frame.

**One insight:**
Template Method is the inverse of Strategy. Strategy says "the client chooses the algorithm." Template Method says "the superclass controls the algorithm; subclasses customize steps." Template Method uses inheritance; Strategy uses composition. The Hollywood Principle applies: "Don't call us, we'll call you" - the framework calls your overridden methods, not the other way around.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. The algorithm structure is defined in the superclass
2. Specific steps are abstract or overridable methods
3. The subclass cannot change the step sequence

**DERIVED DESIGN:**
The template method is a concrete method that calls a sequence of abstract/hook methods. Abstract methods must be overridden (required customization). Hook methods have default implementations (optional customization). The template method is typically `final` to prevent subclasses from altering the sequence.

**THE TRADE-OFFS:**
**Gain:** Code reuse for the algorithm skeleton, enforced step sequence, extension points for customization
**Cost:** Tight coupling through inheritance, limited to single inheritance in Java, can be confusing when the call flow bounces between parent and child

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** A fixed algorithm with variable steps requires some mechanism to enforce the sequence while allowing customization
**Accidental:** Inheritance-based implementation limits reuse to one hierarchy; composition-based alternatives (Strategy) are more flexible
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
The parent class defines the recipe steps. Subclasses fill in the details. The steps always run in the same order.

**Level 2 - How to use it (junior developer):**
Create an abstract class with a `final` method that calls steps in order. Make the variable steps `abstract`. Subclasses override only the steps they need to customize. Fixed steps stay in the parent.

**Level 3 - How it works (mid-level engineer):**
Template Method uses two types of extension points: **Abstract methods** (must override - `parseRecord()`) and **Hook methods** (may override - `afterValidation()` with empty default). Hooks are optional extension points for subclasses that need extra behavior at specific points. Spring's `AbstractController.handleRequestInternal()` is a template method: the framework handles request/response lifecycle, and you override one method for your logic.

**Level 4 - Mastery (senior/staff+ engineer):**
Template Method vs Strategy is the inheritance vs composition debate in pattern form. Template Method is better when: the algorithm is complex, the step sequence is critical, and you want to enforce it. Strategy is better when: you need runtime flexibility, multiple algorithms per object, or you want to avoid deep inheritance hierarchies. In modern Java, I often replace Template Method with a "Template Method as Strategy" approach: pass function callbacks for the variable steps instead of requiring subclassing.




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

### 💻 Code Example

**Example 1 - BAD: Duplicated algorithm**

```java
// BAD: Same steps duplicated, different parse
public class CsvImporter {
    public void importData(File f) {
        var raw = readFile(f);        // Same
        var records = parseCsv(raw);  // Different
        validate(records);            // Same
        transform(records);           // Same
        store(records);               // Same
    }
}
public class JsonImporter {
    public void importData(File f) {
        var raw = readFile(f);         // Same
        var records = parseJson(raw);  // Different
        validate(records);             // Same
        transform(records);            // Same
        store(records);                // Same
    }
}
```

**Example 2 - GOOD: Template Method**

```java
// GOOD: Algorithm defined once, parsing varies
public abstract class DataImporter {
    // Template method - controls the sequence
    public final void importData(File file) {
        String raw = readFile(file);
        List<Record> records = parse(raw);
        validate(records);
        beforeTransform(records); // Hook (optional)
        transform(records);
        store(records);
    }

    // Abstract - MUST override
    protected abstract List<Record> parse(String raw);

    // Hook - MAY override (empty default)
    protected void beforeTransform(
            List<Record> records) {}

    // Fixed steps
    private String readFile(File f) { /*...*/ }
    private void validate(List<Record> r) { /*...*/ }
    private void transform(List<Record> r) { /*...*/ }
    private void store(List<Record> r) { /*...*/ }
}

public class CsvImporter extends DataImporter {
    @Override
    protected List<Record> parse(String raw) {
        return CsvParser.parse(raw);
    }
}

public class JsonImporter extends DataImporter {
    @Override
    protected List<Record> parse(String raw) {
        return JsonParser.parse(raw);
    }
}
```

**How to test / verify correctness:**
Test the template method calls steps in order (use a spy/mock). Test each subclass's parse method independently. Test hook methods default behavior.
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

1. Template Method defines the algorithm skeleton; subclasses customize specific steps
2. Make the template method `final` to prevent subclasses from breaking the sequence
3. Prefer Strategy (composition) over Template Method (inheritance) when runtime flexibility matters

**Interview one-liner:**
"Template Method defines an algorithm skeleton in a base class with abstract steps that subclasses override - like Spring's JdbcTemplate where the framework controls the connection lifecycle and I provide only the query-specific logic."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Spring's `JdbcTemplate` is not actually a Template Method pattern despite its name. It uses Strategy (callback interfaces like `RowMapper`, `PreparedStatementCreator`) passed as parameters, not inheritance. The name comes from the fact that it provides a "template" for JDBC operations - but the implementation mechanism is composition, not the GoF Template Method. This naming confusion causes incorrect pattern identification in many interviews.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Template Method. Otherwise remove this section.]
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

**Q1: Template Method vs Strategy - when do you choose each?**

_Why they ask:_ Tests understanding of composition vs inheritance trade-offs.

**Answer:**
| Decision Factor | Template Method | Strategy |
| -------------------- | ------------------------ | ------------------------ |
| Variation mechanism | Inheritance (subclass) | Composition (inject) |
| Runtime flexibility | Fixed at compile time | Swappable at runtime |
| Code reuse | Shared in base class | No shared structure |
| Step sequence control | Enforced by base class | No sequence guarantee |
| Testing | Requires subclass mocks | Mock interface directly |
| Java limitation | Single inheritance only | No limit |

My rule: If the algorithm has a fixed skeleton with 1-2 variable steps, Template Method is clean. If I need runtime flexibility, multiple variable behaviors, or I'm already using injection, Strategy is better. In modern Java, I often combine both: a template method that delegates to injected strategies.
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

# State

**TL;DR** - State lets an object alter its behavior when its internal state changes, appearing to change its class by delegating behavior to state-specific objects.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your document editor has states: Draft, Review, Published, Archived. Each state allows different operations. `if (state == DRAFT) { allowEdit(); } else if (state == REVIEW) { allowComment(); } else if (state == PUBLISHED) { allowView(); }`. Every method has this conditional. Adding a "Scheduled" state means modifying every method. The state logic is scattered across 15 methods.

**THE BREAKING POINT:**
A developer adds the "Scheduled" state to 14 of 15 methods. The 15th method allows editing a scheduled document, corrupting data that was supposed to be frozen.

**THE INVENTION MOMENT:**
"This is exactly why State was created."

**EVOLUTION:**
The GoF formalized State in 1994. It's closely related to finite state machines (FSMs). Modern usage includes: workflow engines, TCP connection states, game entity behavior (idle/walking/attacking), and order processing (created/paid/shipped/delivered). Spring State Machine provides a framework implementation.
---

### 📘 Textbook Definition

State is a behavioral design pattern that lets an object alter its behavior when its internal state changes. The object appears to change its class. It encapsulates state-specific behavior in separate state objects and delegates behavior to the current state object.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Object behavior changes based on state, with each state as a separate class.

**One analogy:**

> A traffic light. When it's green, cars go. When it's red, cars stop. When it's yellow, cars slow down. The traffic light is the same physical object, but its behavior (what it signals) changes entirely based on its current state.

**One insight:**
State is a Strategy that switches itself. In Strategy, the client selects the algorithm. In State, the current state decides the next state through transitions. The object's behavior is determined by its internal state, and state transitions happen as side effects of operations.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Each state is a separate class implementing a common interface
2. The context delegates behavior to the current state object
3. State transitions are managed by state objects themselves

**DERIVED DESIGN:**
The context holds a reference to the current state object. All behavior methods delegate to the state. When a transition occurs, the context's state reference is updated to a new state object. Each state knows what transitions are valid from it.

**THE TRADE-OFFS:**
**Gain:** Eliminates state-dependent conditionals, each state is independently testable, transitions are explicit
**Cost:** More classes (one per state), state explosion for complex FSMs

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** State-dependent behavior requires the behavior-to-state mapping somewhere
**Accidental:** In simple cases (2-3 states), if-else is clearer than a full State pattern hierarchy
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
An object acts differently depending on its current situation. Like a vending machine: when it has coins, pressing the button dispenses a drink. When empty, pressing the button shows "Insert coins."

**Level 2 - How to use it (junior developer):**
Create a `State` interface with methods for each operation. Each concrete state class implements the behavior for that state and defines valid transitions. The context holds the current state and delegates all calls to it.

**Level 3 - How it works (mid-level engineer):**
State pattern is a finite state machine (FSM) implemented with OOP. Each state class encapsulates: (1) what operations are allowed, (2) what each operation does in this state, (3) what state to transition to after the operation. Invalid operations in a state throw exceptions or are no-ops. State transitions are explicit: `context.setState(new NextState())`.

**Level 4 - Mastery (senior/staff+ engineer):**
For complex workflows, manual State pattern implementation is error-prone. Use Spring State Machine or a DSL-based approach where states and transitions are declared, not coded. The pattern becomes critical in order processing (created -> paid -> shipped -> delivered -> returned), document workflows (draft -> review -> approved -> published), and connection management (connecting -> connected -> disconnecting -> disconnected). Guard conditions on transitions add another dimension: "transition from REVIEW to PUBLISHED only if all reviewers approved."




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

### 💻 Code Example

**Example 1 - BAD: State conditionals everywhere**

```java
// BAD: Every method checks state
public class Document {
    private String state = "DRAFT";

    public void edit(String content) {
        if ("DRAFT".equals(state)) {
            this.content = content;
        } else if ("REVIEW".equals(state)) {
            throw new IllegalStateException(
                "Cannot edit during review");
        } else if ("PUBLISHED".equals(state)) {
            throw new IllegalStateException(
                "Cannot edit published doc");
        }
    }

    public void publish() {
        if ("REVIEW".equals(state)) {
            state = "PUBLISHED";
        } else {
            throw new IllegalStateException(
                "Can only publish from review");
        }
    }
}
```

**Example 2 - GOOD: State pattern**

```java
// GOOD: Each state encapsulates its behavior
public interface DocState {
    void edit(Document doc, String content);
    void review(Document doc);
    void publish(Document doc);
}

public class DraftState implements DocState {
    public void edit(Document doc, String content) {
        doc.setContent(content); // Allowed
    }
    public void review(Document doc) {
        doc.setState(new ReviewState());
    }
    public void publish(Document doc) {
        throw new IllegalStateException(
            "Cannot publish a draft directly");
    }
}

public class ReviewState implements DocState {
    public void edit(Document doc, String content) {
        throw new IllegalStateException(
            "Cannot edit during review");
    }
    public void review(Document doc) { /* no-op */ }
    public void publish(Document doc) {
        doc.setState(new PublishedState());
    }
}

public class Document {
    private DocState state = new DraftState();

    public void setState(DocState s) {
        this.state = s;
    }
    public void edit(String c) {
        state.edit(this, c);
    }
    public void publish() {
        state.publish(this);
    }
}
```

**How to test / verify correctness:**
Test each state class independently: verify allowed operations succeed and invalid operations throw. Test state transitions: verify the context is in the correct state after each operation.
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

1. State eliminates state-dependent if-else chains by delegating to state objects
2. Each state knows its valid transitions - invalid operations fail explicitly
3. For complex workflows, use Spring State Machine instead of hand-coding

**Interview one-liner:**
"State pattern encapsulates state-specific behavior in separate classes so the object delegates to its current state - eliminating scattered conditionals and making transitions explicit and testable."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

State and Strategy have identical class diagrams. The UML is the same: context holds a reference to a strategy/state interface, concrete classes implement it. The difference is purely in intent and who controls switching. In Strategy, the client sets the strategy. In State, the states transition themselves. This makes State a self-modifying Strategy - the pattern changes its own algorithm based on the results of the previous execution.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for State. Otherwise remove this section.]
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

**Q1: State vs Strategy - they look the same. How do you tell them apart?**

_Why they ask:_ Tests ability to distinguish patterns by intent, not structure.

**Answer:**
The UML is identical. The distinction:

- **Strategy:** Client explicitly chooses and sets the algorithm. The strategy doesn't change itself. `paymentService.setStrategy(new CreditCardStrategy())`.
- **State:** The current state determines behavior AND triggers transitions to other states. The client doesn't choose the state directly - it results from operations. `document.publish()` transitions from ReviewState to PublishedState internally.

The test: If the "strategy" changes itself based on the operation's outcome, it's State. If the client explicitly sets it, it's Strategy.
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

# Chain of Responsibility

**TL;DR** - Chain of Responsibility passes a request along a chain of handlers, where each handler decides whether to process it or pass it to the next handler in the chain.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your customer support system handles tickets. Low-priority tickets go to junior agents. Medium tickets go to senior agents. High-priority tickets go to the team lead. Urgent tickets go to the VP. The routing code is a massive if-else chain that's coupled to every handler tier. Adding a new tier (e.g., AI triage) means modifying the central routing logic.

**THE BREAKING POINT:**
The business wants tickets to escalate automatically if not handled within SLA. The if-else chain doesn't support escalation - it makes a single routing decision. You need a chain where handlers can pass requests forward.

**THE INVENTION MOMENT:**
"This is exactly why Chain of Responsibility was created."

**EVOLUTION:**
The GoF formalized it in 1994. It's used extensively in: servlet filters (`FilterChain`), Spring Security's filter chain, middleware pipelines (Express.js, ASP.NET), exception handling (catch blocks are a chain), and logging frameworks (loggers delegate to parent loggers up the hierarchy).
---

### 📘 Textbook Definition

Chain of Responsibility is a behavioral design pattern that lets you pass requests along a chain of handlers. Upon receiving a request, each handler decides either to process it or to pass it to the next handler in the chain. The chain can be configured dynamically.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Pass a request through a chain of handlers until one processes it.

**One analogy:**

> An approval workflow. An employee submits an expense report. Their manager can approve up to $1000, the director up to $10,000, and the VP any amount. The request flows up the chain until someone has the authority to approve it.

**One insight:**
Chain of Responsibility is about decoupling the sender from the receiver. The sender doesn't know which handler will process the request. The handlers don't know about each other except for "the next one." This decoupling allows dynamic chain configuration and makes adding/removing handlers trivial.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Each handler has a reference to the next handler
2. Each handler decides: process or pass
3. The request may go unhandled (reaches end of chain)

**DERIVED DESIGN:**
Handlers implement a common interface with `handle(request)` and `setNext(handler)`. Two variants: (1) **Pure** - only one handler processes the request (first match). (2) **Pipeline** - every handler processes the request (like middleware). Servlet filters use the pipeline variant.

**THE TRADE-OFFS:**
**Gain:** Decoupled sender/receiver, dynamic chain configuration, easy to add/remove handlers
**Cost:** No guarantee of handling, debugging which handler processed a request requires logging, performance degrades with long chains

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Some mechanism must route requests to handlers - the chain is one of several options (the other being a dispatcher/router)
**Accidental:** Forgetting to call `next.handle()` in a pipeline chain silently drops the request
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
Chain of Responsibility is like passing a ball in a relay. Each person can either catch it (handle the request) or pass it to the next person. If nobody catches it, it falls on the ground (unhandled).

**Level 2 - How to use it (junior developer):**
Create a `Handler` abstract class with a `next` field and a `handle(request)` method. Each concrete handler checks if it can handle the request. If yes, process it. If no, call `next.handle(request)`. Chain them together at configuration time.

**Level 3 - How it works (mid-level engineer):**
Spring Security uses Chain of Responsibility extensively. The `SecurityFilterChain` contains filters like `AuthenticationFilter`, `AuthorizationFilter`, `CsrfFilter`. Each filter processes its concern and calls `chain.doFilter()` to pass to the next. This pipeline variant processes every filter (unlike the pure variant where the first match wins). Servlet `FilterChain` is the same pattern.

**Level 4 - Mastery (senior/staff+ engineer):**
The key architectural decision is pure chain vs pipeline. Pure chain (first handler wins) is for routing/dispatching. Pipeline (all handlers run) is for middleware/cross-cutting concerns. In microservices, API Gateway filter chains are pipelines: authentication, rate limiting, request transformation, routing - each runs in sequence. The pattern's weakness at scale: long chains add latency linearly. 20 filters at 1ms each = 20ms overhead per request. Monitor filter execution time and short-circuit when possible.




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

### 💻 Code Example

**Example 1 - BAD: Central routing with if-else**

```java
// BAD: Adding a new handler level requires
// modifying this method
public class TicketRouter {
    public void route(Ticket ticket) {
        if (ticket.getPriority() <= 1) {
            juniorAgent.handle(ticket);
        } else if (ticket.getPriority() <= 3) {
            seniorAgent.handle(ticket);
        } else if (ticket.getPriority() <= 5) {
            teamLead.handle(ticket);
        } else {
            vp.handle(ticket);
        }
    }
}
```

**Example 2 - GOOD: Chain of Responsibility**

```java
// GOOD: Handlers are decoupled and composable
public abstract class SupportHandler {
    private SupportHandler next;

    public SupportHandler setNext(SupportHandler h) {
        this.next = h;
        return h; // Enable chaining
    }

    public void handle(Ticket ticket) {
        if (canHandle(ticket)) {
            process(ticket);
        } else if (next != null) {
            next.handle(ticket);
        } else {
            throw new UnhandledTicketException(
                ticket.getId());
        }
    }

    protected abstract boolean canHandle(Ticket t);
    protected abstract void process(Ticket t);
}

public class JuniorAgent extends SupportHandler {
    protected boolean canHandle(Ticket t) {
        return t.getPriority() <= 1;
    }
    protected void process(Ticket t) {
        // Handle low priority
    }
}

// Configuration: build the chain
SupportHandler chain = new JuniorAgent();
chain.setNext(new SeniorAgent())
     .setNext(new TeamLead())
     .setNext(new VP());

// Usage: just call the first handler
chain.handle(ticket);
```

**How to test / verify correctness:**
Test each handler independently with requests it should and should not handle. Test the full chain processes requests correctly. Test that unhandled requests throw or have a fallback.
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

1. Chain of Responsibility decouples request sender from handler via a linked chain
2. Two variants: pure (first match wins) and pipeline (all handlers run, like servlet filters)
3. Spring Security's filter chain is the most common example in enterprise Java

**Interview one-liner:**
"Chain of Responsibility passes requests through a chain of handlers where each decides to process or delegate - I see it daily in Spring Security's filter chain and servlet filter pipelines."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Java's exception handling mechanism is a Chain of Responsibility. When an exception is thrown, the JVM walks up the call stack looking for a `catch` block that can handle it. Each stack frame is a "handler" that either catches (handles) or propagates (passes to next). If no handler is found, the thread terminates (end of chain, unhandled). The `throws` declaration is the handler's way of saying "I explicitly pass this to the next handler." Exception handling is the most used pattern you never recognize.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Chain of Responsibility. Otherwise remove this section.]
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

**Q1: How does Spring Security's filter chain work, and how would you add a custom filter?**

_Why they ask:_ Tests practical framework knowledge and pattern application.

**Answer:**
Spring Security builds a `SecurityFilterChain` - a pipeline of ordered filters. Key filters in order: `SecurityContextPersistenceFilter` (loads security context), `CsrfFilter` (CSRF protection), `UsernamePasswordAuthenticationFilter` (form login), `BasicAuthenticationFilter` (HTTP Basic), `AuthorizationFilter` (access decisions).

To add a custom filter:

```java
@Configuration
public class SecurityConfig {
    @Bean
    public SecurityFilterChain filterChain(
            HttpSecurity http) throws Exception {
        http.addFilterBefore(
            new CustomAuditFilter(),
            UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }
}

public class CustomAuditFilter
        extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(
            HttpServletRequest req,
            HttpServletResponse res,
            FilterChain chain) throws Exception {
        log.info("Audit: {} {}", req.getMethod(),
            req.getRequestURI());
        chain.doFilter(req, res); // MUST call next
    }
}
```

Critical: calling `chain.doFilter()` passes to the next filter. Forgetting it silently kills the request. The filter order matters - authentication must happen before authorization.
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
