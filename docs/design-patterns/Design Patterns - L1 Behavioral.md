---
layout: default
title: "Design Patterns - L1 Behavioral"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 4
permalink: /design-patterns/l1-behavioral/
---

# Observer Pattern

---
id: DP-010
title: Observer Pattern
category: Design Patterns
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #design-patterns, #observer, #behavioral, #events, #publish-subscribe
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Observer defines a one-to-many dependency: when one object (Subject)
> changes state, all its dependents (Observers) are notified and updated
> automatically. The Subject holds a list of Observers through an interface;
> Observers register themselves and receive notifications without being
> hard-coded into the Subject. It is the foundation of every event-driven
> system: GUI events, Spring ApplicationEvents, reactive streams.

**3 minutes (Senior):**
> The problem Observer solves: tight coupling between the thing that
> changes and the things that react. Without Observer, the Subject
> must know every consumer and call each one directly. Adding a new
> consumer means modifying the Subject. With Observer, the Subject
> knows only an `Observer` interface - any number of consumers can
> register without the Subject changing.
>
> Production context: Spring's `ApplicationEventPublisher` is Observer.
> Swing and JavaFX GUI event listeners are Observer. JPA entity lifecycle
> callbacks (`@PostPersist`, `@PostUpdate`) are Observer. Reactive streams
> (Project Reactor, RxJava) are an asynchronous, backpressure-aware
> evolution of Observer.
>
> The critical failure mode: if one Observer throws an unhandled exception
> in a synchronous notification loop, all subsequent Observers are silently
> skipped. Production code always wraps each Observer call in try/catch.

**Blank Mind Recovery:**

**(1) Restate:** "Observer - the pattern where one object notifies many
others when its state changes."

**(2) First principles:** "Problem: object A changes, and N other objects
need to react. A should not know who those N objects are. Solution: A
maintains a list of registered 'watchers' and notifies them through
an interface."

**(3) Bridge:** "Like a newsletter: you publish, subscribers receive.
You do not know who is subscribed. Subscribers register themselves.
Adding a new subscriber does not change the publisher."

---

### 📘 Concept Explanation

**What it is:**
Observer defines a one-to-many dependency between objects: when one
object (Subject) changes state, it notifies all registered Observers,
who update themselves accordingly.

**The problem it solves:**
When a state change in one object requires updating others, and you do
not want the Subject to be tightly coupled to the set of Observers
(because the set changes, or you do not know it at design time).

**How it works:**

```
Subject (Observable):
  - observers: List<Observer>
  + attach(observer: Observer)
  + detach(observer: Observer)
  + notify():
      for each observer:
          observer.update(this)

Observer interface:
  + update(subject: Subject)

ConcreteSubject extends Subject:
  - state: T
  + setState(value: T):
      this.state = value
      notify()   // triggers all observers

ConcreteObserverA implements Observer:
  + update(subject):
      read subject.getState()
      react to change

ConcreteObserverB implements Observer:
  + update(subject): // independent reaction
```

Two notification styles:
- **Push**: Subject includes the changed data in the notification
  (`update(newState)`). Simpler but Subject must anticipate what
  Observers need.
- **Pull**: Subject sends itself as the notification; Observer queries
  what it needs (`update(subject)` then `subject.getState()`). More
  flexible but Observers must know what to query.

**The key insight:**
Observer inverts the dependency direction. Without Observer, Subject
depends on Observers (knows their types). With Observer, Observers
depend on Subject (Subject stays ignorant of Observer types). This
is the Dependency Inversion Principle applied to notification.

**When to use it:**
- When a state change in one object requires notification of
  potentially many others
- When the number and types of observers are unknown at design time
- When you want loose coupling between the notifying object and
  the reacting objects

**When NOT to use it:**
- When the notification chain is complex: use Mediator to centralize
  coordination
- When performance is critical and synchronous notification of many
  observers is a bottleneck: use asynchronous messaging
- When observers depend on notification order: this is an anti-pattern;
  refactor to make observers independent

**Alternatives:**
- **Event bus (Spring ApplicationEventPublisher, Guava EventBus)** -
  framework Observer with decoupled event types
- **Reactive streams (Project Reactor, RxJava)** - async, backpressure-
  aware evolution of Observer
- **Message queue (Kafka, RabbitMQ)** - distributed Observer with
  durability and decoupling across service boundaries

**First-principles derivation:**
Given: component A changes, N components B1..Bn need to react.
Options: (A) A calls B1..Bn directly - tight coupling, closed to extension.
(B) A publishes to a queue, B1..Bn subscribe - decoupled but adds
infrastructure. (C) A maintains a list of registered observers, calls
through interface - in-process Observer.

---

### 💻 Code Example

```java
// Observer interface
public interface StockObserver {
    void onPriceChange(String symbol, double newPrice);
}

// Subject
public class StockTicker {
    private final Map<String, Double> prices = new HashMap<>();
    // Thread-safe observer list
    private final List<StockObserver> observers =
        new CopyOnWriteArrayList<>();

    public void addObserver(StockObserver obs) {
        observers.add(obs);
    }

    public void removeObserver(StockObserver obs) {
        observers.remove(obs);
    }

    public void updatePrice(String symbol, double price) {
        prices.put(symbol, price);
        notifyObservers(symbol, price);
    }

    private void notifyObservers(String symbol, double price) {
        for (StockObserver observer : observers) {
            try {
                // Per-observer try/catch: one bad observer
                // does not block the rest
                observer.onPriceChange(symbol, price);
            } catch (Exception e) {
                log.error("Observer failed for {}: {}",
                    observer.getClass().getSimpleName(), e);
            }
        }
    }
}

// Observers
public class AlertService implements StockObserver {
    public void onPriceChange(String symbol, double price) {
        if (price < threshold) sendAlert(symbol, price);
    }
}

public class PortfolioTracker implements StockObserver {
    public void onPriceChange(String symbol, double price) {
        recalculatePortfolioValue();
    }
}
```

> **Code walkthrough:** Three production patterns in this code.
> (1) `CopyOnWriteArrayList` for thread-safe observer iteration:
> observers can be added/removed while iteration is in progress.
> (2) Per-observer try/catch: if `AlertService` throws, `PortfolioTracker`
> still receives the notification. (3) The Subject calls observers with
> a push notification (`symbol, price`) - observers do not need to
> query back. This is the production-safe Observer implementation.

```java
// PRODUCTION: Spring ApplicationEvent (framework Observer)
// Event class
public class OrderPlacedEvent extends ApplicationEvent {
    private final Order order;

    public OrderPlacedEvent(Object source, Order order) {
        super(source);
        this.order = order;
    }

    public Order getOrder() { return order; }
}

// Publisher (Subject)
@Service
public class OrderService {
    @Autowired
    private ApplicationEventPublisher eventPublisher;

    public Order placeOrder(OrderRequest request) {
        Order order = createOrder(request);
        eventPublisher.publishEvent(
            new OrderPlacedEvent(this, order));
        return order;
    }
}

// Observers - any number, in any package
@Component
public class EmailNotificationListener {
    @EventListener
    public void handleOrderPlaced(OrderPlacedEvent event) {
        sendConfirmationEmail(event.getOrder());
    }
}

@Component
public class InventoryListener {
    @EventListener
    public void handleOrderPlaced(OrderPlacedEvent event) {
        reserveInventory(event.getOrder().getItems());
    }
}
```

> **Code walkthrough:** Spring's `ApplicationEventPublisher` implements
> Observer at the framework level. `OrderService` (Subject) publishes
> an event without knowing who listens. `@EventListener` methods
> (Observers) register automatically through component scanning.
> Adding a new reaction (analytics, fraud check) means creating a new
> `@Component` with `@EventListener` - zero changes to `OrderService`.
> For async execution, add `@Async` to the listener.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Observer is the pattern where one object notifies others when it
> changes. The Subject has a list of observers (registered through an
> interface) and calls each one when its state changes. In Spring,
> this is `ApplicationEventPublisher`: one service publishes an event,
> any number of `@EventListener` methods receive it automatically.

*Push deeper:* "The critical production detail: wrap each observer call
in try/catch. One bad observer should not prevent all subsequent
observers from receiving the notification."

---

**Senior / Staff (5+ years):**
> Observer is the foundation of event-driven architecture. The in-process
> form (Subject/Observer in the same JVM) is for synchronous reactions.
> When you need cross-service reactions (one microservice publishes,
> other microservices react), the same pattern scales to a message queue:
> Kafka topic = Subject, consumer groups = Observers. The interface is
> the event schema instead of a Java interface.
>
> The production tension: synchronous Observer is simple but couples
> the Subject's performance to Observer performance. If one Observer
> does a slow database write during the notification, the Subject blocks.
> Spring's `@Async` on `@EventListener` moves the observer to a thread
> pool, decoupling performance. At scale: that thread pool can exhaust,
> and the message is lost if the process crashes. The fully durable
> solution is Kafka: the event is persisted before processing, consumers
> can lag without losing messages.

*Push deeper:* "Reactive streams (Project Reactor's `Flux`/`Mono`) are
a generalization of Observer with: backpressure (observer can signal
how many items it can handle), error propagation, and composition
operators (map, filter, flatMap). If you see 'reactive' in a job
description, understanding Observer is the prerequisite."

---

### ⚠️ Common Misconceptions

**Misconception 1: Observer and Pub/Sub are the same pattern.**

Observer has a direct reference between Subject and Observer - subjects know their observers. When the subject calls `notifyObservers()`, it directly invokes each observer's `update()` method. Pub/Sub introduces a broker (message channel) between publisher and subscriber - publishers and subscribers don't know about each other and communicate via topic/event type. Observer is tightly coupled (subject and observer must be in the same process); Pub/Sub is loosely coupled (publisher and subscriber can be in different processes or systems).

**Misconception 2: Observers always need to be deregistered manually.**

Failing to deregister observers causes memory leaks in languages without garbage collection finalization OR in languages where the observed subject holds a strong reference to the observer. In Java, if `Subject` holds `List<Observer>` with strong references, registered observers are never garbage collected even when no other code references them. Solutions: use `WeakReference<Observer>` in the subject's list (Java), use a lifecycle-aware observer that deregisters on component destruction, or use event buses that manage weak references automatically.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Memory leak from underegistered observers.**

Symptom: heap memory grows monotonically over time; heap dump shows growing list of Observer objects that should have been garbage collected. Root cause: Observers registered with a long-lived Subject are never deregistered; the Subject's strong reference list prevents GC. Diagnosis: take heap dump, search for Observer lists; check if Observer objects exist longer than their logical lifetime (e.g., UI components persisting after screen close). Fix: add deregistration in observer lifecycle cleanup (close(), dispose(), onDestroy()); use WeakReference in the observer list for non-critical notifications.

**Failure Mode 2: Observer notification ordering causes cascading mutations.**

Symptom: observer A's update() modifies the subject's state, triggering a second notification cycle; observers see inconsistent intermediate state; StackOverflowError from infinite notification loop. Root cause: observer mutates the subject during `update()`, triggering re-notification. Diagnosis: add logging to `update()` and `notifyObservers()` to detect recursive calls; check for observer-to-subject mutations. Fix: complete all state changes before calling `notifyObservers()`; use a change-batching mechanism that coalesces multiple state changes into one notification; prevent re-entrancy with a `notifying` flag.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Observer pattern?"
- "What is the difference between push and pull notification?"

🗣️ "Observer defines a one-to-many dependency: when the Subject changes
state, all registered Observers are notified. Two notification styles:
push - the Subject sends the new state as a parameter to `update(newState)`;
the Observer gets the data directly. Pull - the Subject sends itself to
`update(subject)`, and each Observer queries what it needs. Push is simpler
for homogeneous Observers that all need the same data. Pull is more flexible
when Observers need different parts of the Subject's state, but it requires
Observers to know the Subject's interface."

#### Mechanism
- "Walk me through the Observer notification sequence."
- "How do you handle concurrent modification of the Observer list?"

🗣️ "Notification sequence: Subject calls `notify()`, which iterates
the observer list and calls `update()` on each. In the synchronous form,
this is a sequential call on the calling thread. Concurrent modification:
if Thread A iterates the list while Thread B adds an observer, a
`ConcurrentModificationException` throws. Solution: `CopyOnWriteArrayList`
for the observer list (safe iteration; copies the list on each write).
Alternative: synchronize on the list during iteration, but this creates
a lock contention point. For high-throughput cases: copy the list before
iterating (snapshot under lock, iterate the snapshot)."

#### Comparison
- "Compare Observer vs Publish/Subscribe (Event Bus)."

🗣️ "Observer: Subject knows the Observer interface and calls it directly.
Observers register with the Subject. Tight(er) coupling - Observers and
Subject share the same interface type. Pub/Sub (Event Bus): Subject
publishes to an event channel by event type; Observers subscribe to
channel/event type. Neither knows the other. Looser coupling - Subject
and Observer share only the event type. The trade-off: Observer is simpler
and synchronous; Pub/Sub scales better (Subject and Observer in different
threads, different services, different machines). Spring's
`ApplicationEventPublisher` is closer to Pub/Sub: Subject publishes by
event type, Observers subscribe by type with `@EventListener`. Kafka is
Pub/Sub at the distributed system level."

#### Scenario
- "Design a real-time dashboard that shows metrics from multiple services."
- "How would you implement order status notifications?"

🗣️ "For order status notifications: OrderService publishes an
`OrderStatusChanged` event (Spring ApplicationEvent or Kafka event).
Observers: EmailNotifier sends an email on `ORDER_SHIPPED`,
SMSNotifier sends SMS on `ORDER_DELIVERED`, WebSocketNotifier pushes
real-time update to the client browser. Each observer is independent
and can be added or removed without changing OrderService. For cross-service
notification (microservices), the Kafka topic acts as the Subject:
OrderService publishes to `order-status-events`; notification services
consume. The schema of the Kafka event is the 'Observer interface' at
the distributed level."

#### Debugging
- "An Observer is not receiving notifications. How do you debug it?"
- "Notifications are being received in the wrong order. How do you fix it?"

🗣️ "For an Observer not receiving notifications: check registration.
Add logging in the Subject's `attach()` method - is this observer being
registered? Check timing: is the observer registered before the first
notification fires? (Common: observer registers after startup event.)
Check for unintended `detach()` calls. For Spring `@EventListener`:
check that the component is in the scan path and that the event type
in the method parameter exactly matches the published type (including
generics). For notification ordering: Observer pattern does not guarantee
notification order. If observers depend on order, that is an anti-pattern.
Refactor: use a Saga or Command sequence where the first step explicitly
triggers the second."

#### Deep Dive
- "How does Java's Observer/Observable relate to the GoF pattern?"
- "How does reactive programming extend Observer?"

🗣️ "Java had built-in `Observer` interface and `Observable` class
(java.util package) since Java 1.0, but they were deprecated in Java 9.
Problems: `Observable` is a class (not an interface), forcing your Subject
to extend it rather than extending your domain class. The `update()`
method receives `Object`, not a typed event. Thread-safety is the
caller's responsibility. Spring's `ApplicationEvent`/`ApplicationEventPublisher`
and the GoF pattern implemented manually (as in the StockTicker example)
are preferred.
Reactive programming: Project Reactor's `Flux` is an asynchronous Observer
sequence. Three additions beyond GoF Observer: (1) backpressure - observer
signals how many items it can handle per time unit; publisher adapts.
(2) Error propagation - the stream carries errors as first-class events,
not unhandled exceptions. (3) Operators - map, filter, flatMap compose
stream transformations. The key is that the Observer relationship is now
a composable pipeline, not just a notification list."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Implement thread-safe Observer with per-listener exception handling; compare to Spring events. |
| Hiring Manager | "Observer is the pattern behind all our event-driven workflows. OrderService publishes, everyone else listens." |
| Bar Raiser | "How does Observer scale to distributed systems? What does Kafka add over in-process Observer?" |
| Peer Engineer | "I use @EventListener for everything that crosses service boundaries within the same JVM. Kafka for cross-service." |

---

# Strategy Pattern

---
id: DP-011
title: Strategy Pattern
category: Design Patterns
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #design-patterns, #strategy, #behavioral, #open-closed, #polymorphism
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Strategy defines a family of algorithms, encapsulates each one, and
> makes them interchangeable. The context class holds a reference to a
> strategy interface and delegates the algorithm to it. The algorithm
> can be changed at runtime without modifying the context. It is the
> pattern behind every plugin, every configurable behavior, and every
> `Comparator` in Java.

**3 minutes (Senior):**
> The problem Strategy solves: a class needs to perform a behavior that
> varies. Without Strategy, you write if/else or switch blocks: if the
> discount type is PREMIUM, apply 20%; if it is STANDARD, apply 10%.
> Adding a third discount type requires modifying this class. With
> Strategy, each discount type is a separate class implementing
> `DiscountStrategy`. Adding a third: create a new class, inject it.
> The context class never changes.
>
> Production context: Strategy is everywhere in Java. `Comparator` is
> a strategy for comparison. `Runnable` is a strategy for execution.
> `javax.servlet.Filter` is a strategy for request processing.
> Spring's `PasswordEncoder` hierarchy (BCrypt, Argon2, SCrypt) is
> a Strategy family. Every functional interface in Java 8+ is a potential
> Strategy.

**Blank Mind Recovery:**

**(1) Restate:** "Strategy - the pattern where an algorithm is extracted
into an interchangeable object."

**(2) First principles:** "Problem: a behavior varies across contexts.
Hard-coding it with if/else closes the system to extension. Solution:
extract the varying behavior into an interface, inject the correct
implementation."

**(3) Bridge:** "Like a GPS navigation system: the destination is fixed
but the routing strategy varies - fastest route, shortest route, avoid
tolls. Each is a Strategy injected into the same Navigator context."

---

### 📘 Concept Explanation

**What it is:**
Strategy encapsulates a family of algorithms in separate classes, all
implementing the same interface, so they are interchangeable. The context
delegates to the strategy rather than implementing the behavior itself.

**The problem it solves:**
When the same class needs to perform a behavior that differs based on
configuration, runtime state, or user choice - and when adding new
variations should not require modifying the class.

**How it works:**

```
Context:
  - strategy: Strategy   (the injected algorithm)
  + setStrategy(s: Strategy)
  + executeOperation():
      strategy.execute(context data)  // delegates

Strategy interface:
  + execute(data): Result

ConcreteStrategyA implements Strategy:
  + execute(data): uses algorithm A

ConcreteStrategyB implements Strategy:
  + execute(data): uses algorithm B

ConcreteStrategyC implements Strategy:
  + execute(data): uses algorithm C

// Selection happens outside the context:
context.setStrategy(new ConcreteStrategyA())
// or via DI:
new Context(new ConcreteStrategyB())
```

**The key insight:**
The strategy selection is separated from the strategy execution. The
context does not choose the algorithm - the caller or DI container does.
This separation means: the context is closed for modification, and the
strategy family is open for extension. Adding a new algorithm is adding
a new class, not modifying the context.

**When to use it:**
- When a class should be configurable with one of several related behaviors
- When you want to eliminate complex conditionals (if/else chains) based
  on behavior type
- When different variations of an algorithm need to be tested or replaced
  independently

**When NOT to use it:**
- When there is only one algorithm that never varies: plain method is
  simpler
- When the algorithm needs access to private state of the context: the
  interface forces public access or parameter passing that adds coupling
- In Java 8+, for simple single-method strategies: use a functional
  interface and lambdas (no Strategy class hierarchy needed)

**Alternatives:**
- **Lambda / functional interface** - in Java 8+, `Comparator`, `Predicate`,
  `Function` replace simple Strategy class hierarchies
- **Template Method** - defines the algorithm skeleton in a base class,
  lets subclasses fill in specific steps (inheritance-based Strategy)
- **Command** - encapsulates an action (not just an algorithm) with
  optional undo, history, and queueing

**First-principles derivation:**
Given: a method that needs different behavior based on type. Options:
(A) if/else in the method - closed to extension. (B) override in subclass
(Template Method) - inheritance, one hierarchy. (C) inject an algorithm
object - Strategy: no inheritance, composable, testable in isolation.

---

### 💻 Code Example

```java
// BAD: switch statement for algorithm selection
public class PaymentProcessor {

    public void process(Order order, String paymentType) {
        // Must modify this class to add a new payment type
        switch (paymentType) {
            case "CREDIT_CARD":
                // 50 lines of credit card processing
                break;
            case "PAYPAL":
                // 50 lines of PayPal processing
                break;
            case "CRYPTO":
                // 50 lines of crypto processing
                break;
            // Adding a 4th type: edit this class
        }
    }
}
```

> **Code walkthrough:** Every new payment type requires editing this
> class. The class grows unboundedly. Each case branch has entirely
> different logic that cannot be tested independently. A change to
> credit card processing risks breaking PayPal (same compilation unit).

```java
// GOOD: Strategy pattern
public interface PaymentStrategy {
    PaymentResult charge(Order order);
    boolean supports(String paymentType);
}

public class CreditCardStrategy implements PaymentStrategy {
    public PaymentResult charge(Order order) { ... }
    public boolean supports(String t) {
        return "CREDIT_CARD".equals(t);
    }
}

public class PayPalStrategy implements PaymentStrategy {
    public PaymentResult charge(Order order) { ... }
    public boolean supports(String t) {
        return "PAYPAL".equals(t);
    }
}

// Context: delegates to whichever strategy supports the type
@Service
public class PaymentProcessor {
    private final List<PaymentStrategy> strategies;

    // All strategies injected by Spring (open for extension:
    // add a new bean, zero changes to PaymentProcessor)
    public PaymentProcessor(List<PaymentStrategy> strategies) {
        this.strategies = strategies;
    }

    public PaymentResult process(Order order) {
        return strategies.stream()
            .filter(s -> s.supports(order.getPaymentType()))
            .findFirst()
            .map(s -> s.charge(order))
            .orElseThrow(() -> new UnsupportedPaymentException(
                order.getPaymentType()));
    }
}
```

> **Code walkthrough:** Adding a new payment type: create a new
> `@Component` implementing `PaymentStrategy`, Spring auto-injects it
> into the `List<PaymentStrategy>`. `PaymentProcessor` never changes.
> Each strategy is independently testable (no switch case, no other
> strategies in scope). The `supports()` method is the strategy
> selection predicate - it can be any condition: config flag, user
> tier, geographic region.

```java
// JAVA 8+: Lambda as Strategy
// Comparator IS a Strategy (single-method interface)
List<Employee> employees = ...;

// Three strategies as lambdas - no Strategy classes needed
employees.sort(Comparator.comparing(Employee::getSalary));
employees.sort(Comparator.comparing(Employee::getHireDate)
    .reversed());
employees.sort(Comparator.comparing(Employee::getDepartment)
    .thenComparing(Employee::getName));

// Custom strategy as lambda - no separate class
SortingService sortService = new SortingService(
    (a, b) -> a.getPerformance() - b.getPerformance());
```

> **Code walkthrough:** In Java 8+, any functional interface is a
> Strategy interface. `Comparator` is the canonical example. Strategies
> are expressed as lambdas - no separate classes needed for simple
> single-expression algorithms. For complex algorithms with multiple
> methods or state, a dedicated class is still appropriate.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Strategy is the pattern where you extract the varying algorithm into
> an interface, and inject the specific algorithm from outside. Instead
> of if/else in the class, you call `strategy.execute()`. Adding a new
> algorithm: create a new class implementing the strategy interface, no
> changes to the context. In Java 8+ I often use a functional interface
> with lambdas instead of a class hierarchy for simple strategies.

*Push deeper:* "I use Strategy when I see a switch or if/else that
selects behavior by type. That switch is always a sign that Strategy
or polymorphism would be cleaner."

---

**Senior / Staff (5+ years):**
> Strategy is my first refactoring target when I see behavior-selecting
> conditionals. The smell: `if type == A do this else if type == B do that`.
> The refactoring: extract each branch to a strategy class, put them in
> a list or map, look up the right one at runtime.
>
> The production pattern: inject a `List<SomeStrategy>` into the context.
> Spring collects all `@Component` implementations of `SomeStrategy` into
> the list. Adding a new strategy is deploying a new class - the existing
> code is unchanged. This is the plugin pattern: the strategy list is
> the plugin registry.

*Push deeper:* "Strategy vs Template Method: Strategy uses composition
(algorithm is injected as a field). Template Method uses inheritance
(algorithm steps are methods in subclasses). Strategy is preferred in
modern Java: it enables the algorithm to be replaced at runtime and is
more testable (inject a mock strategy). Template Method locks you into
an inheritance hierarchy."

---

### ⚠️ Common Misconceptions

**Misconception 1: Strategy requires defining a separate class for every algorithm variant.**

In languages with first-class functions (Java 8+, Python, JavaScript), a Strategy is just a functional interface or lambda - no separate class required. `sorter.setStrategy(list -> Collections.sort(list))` uses a lambda as the strategy. The class-per-strategy approach is the pre-lambda Java convention. Modern Strategy implementations often use method references (`String::compareTo`) or lambdas directly, dramatically reducing the ceremony while preserving the pattern's structural benefits.

**Misconception 2: Strategy and State patterns are structurally identical and interchangeable.**

Both patterns use an interface with swappable implementations held by a context. The difference is INTENT and WHO changes the strategy: in Strategy, the CLIENT chooses and sets the algorithm (sort by name? sort by date?); in State, the OBJECT itself transitions between states based on internal events. An object that switches from PendingState to ProcessingState to CompletedState based on business events is using State (autonomous transitions). An object whose sorting algorithm is set externally by the caller is using Strategy (externally controlled behavior).

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Strategy not set before use causes NullPointerException.**

Symptom: `NullPointerException` when context tries to invoke the strategy; occurs when context has no default strategy and the strategy was never set by the caller. Diagnosis: check for null before calling strategy methods; trace back to where strategy assignment is expected. Fix: provide a sensible default strategy (NullObject pattern for no-op default, or a reasonable default algorithm); validate that a strategy is set in the context constructor or provide a factory method that requires it.

**Failure Mode 2: Strategy carries shared mutable state causing race conditions.**

Symptom: intermittent incorrect results when the same strategy instance is used by multiple threads or multiple context objects simultaneously. Root cause: strategy implementation stores mutable state (counters, buffers, intermediate results) in instance fields that are modified during `execute()`. Diagnosis: check strategy implementations for instance fields that change during execution; look for non-final fields in strategy classes. Fix: strategies should be stateless - pure functions of their input; move any necessary state to parameters or return values, or create a new strategy instance per context.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Strategy pattern?"
- "What is the difference between Strategy and if/else?"

🗣️ "Strategy defines a family of algorithms, encapsulates each one in
a class implementing the same interface, and makes them interchangeable.
The context class uses the interface, not any concrete algorithm.
Difference from if/else: if/else embeds the algorithm selection and
the algorithms in the same class, which is closed to extension (adding
a new branch requires modifying the class). Strategy externalizes each
algorithm: adding a new one means creating a new class (open to extension)
with zero changes to the context (closed to modification). This is
Open/Closed Principle applied to algorithm selection."

#### Mechanism
- "How is the strategy selected at runtime?"
- "How does Spring inject the correct strategy?"

🗣️ "Strategy selection happens outside the context. Three common patterns.
Constructor injection: `new OrderProcessor(new CreditCardStrategy())` -
the caller decides. Setter injection: `processor.setStrategy(strategy)` -
can change at runtime. Registry/list: Spring injects all implementations
of the strategy interface into a list; the context finds the correct one
using a predicate (`strategy.supports(type)`). The registry pattern is
the most flexible: adding a new implementation automatically registers
it via Spring's component scanning."

#### Comparison
- "Compare Strategy vs Template Method."
- "Compare Strategy vs Command."

🗣️ "Strategy vs Template Method: both handle algorithm variation. Strategy
uses composition - the algorithm is in a separate object injected into
the context. Template Method uses inheritance - the algorithm skeleton
is in the base class, specific steps are overridden in subclasses. Strategy
is preferred for independent algorithm selection and testing. Template
Method is appropriate when the skeleton is the same and only specific
steps vary.
Strategy vs Command: Strategy encapsulates an algorithm (how to do something).
Command encapsulates an operation (what to do), potentially with undo,
history, and queueing. A Command usually has a single `execute()` method
and models an intent. A Strategy models a replaceable algorithm for
how to accomplish a result."

#### Scenario
- "Design a discount system using Strategy."

🗣️ "I define a `DiscountStrategy` interface with `double calculate(Order)`.
Implementations: `PremiumDiscount` (20% off), `StandardDiscount` (10% off),
`BulkDiscount` (15% off orders over 10 items), `NoDiscount` (0% for
new accounts in trial). A `DiscountFactory` or Spring DI injects the
correct strategy based on customer tier. `OrderService` calls
`discountStrategy.calculate(order)` to compute the final price. Adding
a seasonal discount: create `SeasonalDiscount` class, register as a
`@Component` - done. Zero changes to `OrderService`."

#### Debugging
- "The wrong strategy is being selected. How do you investigate?"

🗣️ "I trace the selection logic. In the registry pattern: log which
strategy wins for each call. Add `log.debug('Strategy selected: {}', strategy.getClass().getSimpleName())` in the context. If no strategy
is selected (throws or falls through): log all strategies and their
`supports()` result for the given input. Common bug: the strategy's
`supports()` method has a case-sensitivity issue (comparing 'PREMIUM'
to 'premium'). Another: Spring injects strategies in an undefined order;
if two strategies both claim to `support()` the same input, which one
wins depends on iteration order. Fix: make selections mutually exclusive,
or assign explicit priorities (`@Order` annotation)."

#### Deep Dive
- "How does the Strategy pattern relate to functional interfaces in Java 8+?"
- "Where does Strategy appear in the Java standard library?"

🗣️ "In Java 8+, every `@FunctionalInterface` is a Strategy interface.
`Comparator<T>` is a Strategy for comparison. `Predicate<T>` is a Strategy
for filtering. `Function<T,R>` is a Strategy for transformation.
`Runnable` is a Strategy for execution. The lambda syntax eliminates
the need for a separate Strategy class: you write the algorithm inline
as a lambda. For complex algorithms with state or multiple methods, a
dedicated Strategy class is still appropriate. Java 8 did not remove
the pattern - it made it a language primitive for the simple case.
In the standard library: `InputStream`'s `skip()` is effectively a
Strategy hook. `Arrays.sort(array, comparator)` is Strategy (Comparator).
`ExecutorService` is a Strategy for how to execute tasks."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Implement Strategy with Spring injection list; explain why List<Strategy> eliminates if/else. |
| Hiring Manager | "Strategy is how we support multiple payment providers without modifying the payment processor." |
| Bar Raiser | "When does Strategy become over-engineering? A single method with lambdas is simpler than a class hierarchy." |
| Peer Engineer | "Every time I see a switch on type, I refactor to Strategy. The List<Strategy> with supports() pattern is my go-to." |

---

# Template Method Pattern

---
id: DP-012
title: Template Method Pattern
category: Design Patterns
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: all
tags: #design-patterns, #template-method, #behavioral, #inheritance
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Template Method defines the skeleton of an algorithm in a base class
> and defers specific steps to subclasses. The base class controls the
> algorithm's structure and sequence; subclasses customize specific steps
> without changing the overall structure. It is the backbone of every
> framework hook system: Spring's `JdbcTemplate`, servlet lifecycle,
> JUnit test lifecycle.

**3 minutes (Senior):**
> The problem: multiple implementations share the same algorithm structure
> but differ in specific steps. Without Template Method, each implementation
> duplicates the structural skeleton and might implement the steps in a
> different order, creating inconsistency. With Template Method, the
> structure is written once in the base class (the template method),
> and only the variable steps are left as hooks for subclasses to fill in.
>
> Production examples: JUnit test lifecycle (`@BeforeAll`, `@BeforeEach`,
> test method, `@AfterEach`, `@AfterAll`) is a Template Method - the
> framework controls the sequence, your test methods fill the steps.
> Spring's `AbstractController.handleRequest()` is a Template Method.
> `AbstractList.add()` calls `add(index, element)` which is abstract -
> you implement the indexed add and the template method handles growing.
>
> The trade-off: Template Method uses inheritance, which is tighter
> coupling than Strategy's composition. You cannot change the skeleton
> at runtime. Prefer Strategy when you need runtime algorithm swapping;
> use Template Method when the skeleton is truly fixed and subclassing
> is the natural extension mechanism.

**Blank Mind Recovery:**

**(1) Restate:** "Template Method - the pattern where a base class
defines the algorithm structure and subclasses fill in specific steps."

**(2) First principles:** "Problem: multiple variants of the same
process differ only in a few steps. Duplicating the skeleton is error-
prone. Solution: put the skeleton in a base class, make the variable
steps abstract."

**(3) Bridge:** "Like a recipe with a fixed procedure but variable
ingredients: 'heat pan, add [ingredient], stir for 3 minutes, plate.'
The method is fixed; what you add varies."

---

### 📘 Concept Explanation

**What it is:**
Template Method defines the algorithm's skeleton in a method of a base
class, deferring some steps to subclasses. It lets subclasses redefine
specific steps of an algorithm without changing the overall structure.

**The problem it solves:**
Multiple subclasses share the same algorithmic structure but differ in
specific steps. Without Template Method, the structure would be duplicated,
risking divergence. With it, the structure is defined once.

**How it works:**

```
AbstractClass:
  + templateMethod() [FINAL - not overridable]:
      step1()        <-- concrete (shared, fixed)
      step2()        <-- abstract (deferred to subclass)
      step3()        <-- abstract (deferred)
      optionalHook() <-- hook (subclass may override)
      step4()        <-- concrete (shared, fixed)

  # step1(): fixed implementation
  # abstract step2()
  # abstract step3()
  # optionalHook(): default empty implementation
  # step4(): fixed implementation

ConcreteClassA extends AbstractClass:
  # step2(): implementation A
  # step3(): implementation A

ConcreteClassB extends AbstractClass:
  # step2(): implementation B
  # step3(): implementation B
  # optionalHook(): override with extra B behavior
```

Three types of methods in Template Method:
1. **Concrete methods** - fixed, shared implementation in base class
2. **Abstract methods** - must be overridden; the mandatory variable steps
3. **Hook methods** - optional override points; base class has a default
   (often empty) implementation

**The key insight:**
The template method (usually `final`) prevents subclasses from changing
the algorithm's structure. They can only customize the designated steps.
This is the Hollywood Principle: "Don't call us, we'll call you." The
base class calls the subclass's hook methods, not the other way around.

**When to use it:**
- When multiple classes share the same algorithm structure but differ in
  specific steps
- When a framework defines the process flow and you need to provide
  application-specific steps (servlet lifecycle, Spring batch ItemProcessor)
- When factoring common behavior from subclasses up to the base class
  to eliminate duplication

**When NOT to use it:**
- When the algorithm structure varies (not just the steps) - use Strategy
- When the variation is complex with many steps - inheritance becomes deep
  and hard to follow
- When the subclass needs to call super() in a specific order - this is
  fragile and indicates misuse

**Alternatives:**
- **Strategy** - composition-based; algorithm is injected, not inherited;
  can change at runtime
- **Hook methods without abstract** - abstract class with all hooks having
  default empty implementations (visitor pattern style)
- **Functional composition** - chain of lambdas/functions (modern
  alternative to template inheritance)

**First-principles derivation:**
Given: N implementations that share a process structure but differ in
steps 2 and 3. Options: (A) duplicate the structure in each - divergence
risk. (B) put structure in base class with abstract methods for steps
2 and 3 - Template Method. (C) inject step objects (Strategy) - more
flexible, less inheritance.

---

### 💻 Code Example

```java
// Template Method for data export (CSV vs JSON)
public abstract class DataExporter {

    // Template method - final to protect the structure
    public final ExportResult export(List<Record> records) {
        ExportResult result = new ExportResult();

        prepare(result);             // hook: optional pre-processing
        result.setHeader(buildHeader());  // abstract: format-specific
        for (Record record : records) {
            result.addRow(formatRow(record));  // abstract: format-specific
        }
        result.setFooter(buildFooter());  // hook: optional footer
        finalize(result);            // hook: optional post-processing

        return result;
    }

    // Abstract methods: subclasses must implement
    protected abstract String buildHeader();
    protected abstract String formatRow(Record record);

    // Hook methods: subclasses may override (default: no-op)
    protected void prepare(ExportResult result) { }
    protected String buildFooter() { return ""; }
    protected void finalize(ExportResult result) { }
}

public class CsvExporter extends DataExporter {
    protected String buildHeader() {
        return "id,name,value\n";
    }

    protected String formatRow(Record r) {
        return r.getId() + "," + r.getName()
            + "," + r.getValue() + "\n";
    }
}

public class JsonExporter extends DataExporter {
    private final ObjectMapper mapper = new ObjectMapper();

    protected String buildHeader() { return "["; }

    protected String formatRow(Record r) {
        return mapper.writeValueAsString(r) + ",";
    }

    protected String buildFooter() { return "]"; }
}
```

> **Code walkthrough:** The `export()` template method is `final` -
> subclasses cannot change the overall process. `buildHeader()` and
> `formatRow()` are abstract - subclasses must provide these. Hook
> methods (`prepare`, `buildFooter`, `finalize`) have empty default
> implementations; subclasses override only what they need (JsonExporter
> overrides `buildFooter` to close the JSON array). The loop structure
> and the sequencing are fixed once in the base class.

```java
// PRODUCTION: Spring JdbcTemplate is Template Method
// JdbcTemplate.query() is the template method:
//   - acquire connection
//   - create prepared statement
//   - execute query
//   - map results (abstract step - YOU provide)
//   - close resources
// You provide the RowMapper (the abstract step):

List<Customer> customers = jdbcTemplate.query(
    "SELECT * FROM customers WHERE tier = ?",
    (rs, rowNum) -> {
        return Customer.builder()
            .id(rs.getLong("id"))
            .name(rs.getString("name"))
            .tier(rs.getString("tier"))
            .build();
    },
    "PREMIUM"
);
// The RowMapper lambda IS the abstract step
// JdbcTemplate controls connection/statement/close
```

> **Code walkthrough:** JdbcTemplate's `query()` is the template method.
> It manages the JDBC infrastructure (connection, prepared statement,
> exception translation, resource cleanup). You provide the `RowMapper`
> - the one step that varies per query. This is Template Method in
> production: the framework controls the skeleton (managing resources),
> you fill in the variable step (result mapping). Without this pattern,
> every query would need to manage JDBC resources manually.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Template Method defines the algorithm structure in a base class and
> lets subclasses fill in the specific steps. The base class has a
> method (the template) that calls abstract methods that subclasses
> must implement. A real example is JUnit: the framework calls
> `@BeforeEach`, then the test method, then `@AfterEach` - that is
> the template. You implement the test method and optionally the
> before/after steps.

*Push deeper:* "The template method is often `final` so subclasses
cannot change the overall structure - only the designated steps. This
is the Hollywood Principle: the base class calls you, you do not call
the base class."

---

**Senior / Staff (5+ years):**
> Template Method is the inheritance-based alternative to Strategy.
> Where Strategy injects the variable algorithm as an object (composition),
> Template Method embeds the variable steps in a subclass (inheritance).
> Spring uses Template Method extensively: `JdbcTemplate`, `RestTemplate`,
> `KafkaTemplate` - the "template" in the name literally refers to this
> pattern.
>
> The practical trade-off: Template Method makes the skeleton non-variable
> (the template method is often `final`). This is a feature for frameworks
> (you want the lifecycle fixed) but a limitation for application code
> (you cannot swap the skeleton at runtime). For application algorithms
> that need to be swapped: use Strategy. For framework extension points
> where the structure is sacred: use Template Method.

*Push deeper:* "The progression in modern Java: (1) Template Method with
abstract classes - works, but inheritance couples you to the base class.
(2) Template Method with hook default methods (Java 8 interface defaults) -
looser: implement the interface, override the hooks you need. (3) Functional
composition with lambdas - inject the variable steps as functions. All three
solve the same problem; the trade-off is inheritance depth vs. composition
flexibility."

---

### ⚠️ Common Misconceptions

**Misconception 1: Template Method requires abstract classes and inheritance.**

Template Method's core insight is "define the skeleton of an algorithm with steps that subclasses fill in." While the canonical implementation uses an abstract class with abstract methods, the same pattern appears via functional interfaces: a method that accepts lambda callbacks for each customizable step implements Template Method without inheritance. Spring's `JdbcTemplate.query()` is Template Method - it defines the connection acquisition, query execution, result iteration, and resource cleanup steps, with a `ResultSetExtractor` callback for the extraction step.

**Misconception 2: Template Method hooks are always optional.**

Template Method has two types of steps: abstract steps (subclass MUST override) and hook steps (subclass MAY override with default behavior). Forgetting to declare mandatory steps as `abstract` means the base class compiles with an empty implementation, and a subclass that doesn't override it silently gets no-op behavior. The distinction between mandatory steps (abstract) and optional hooks (concrete with default) must be deliberate and documented.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Base class changes break all subclasses (fragile base class).**

Symptom: adding or reordering steps in the template method breaks multiple subclass implementations; subclasses rely on the specific order of base class step calls. Root cause: template method algorithm changed without coordinating with all subclasses; base class evolution is tightly coupled to subclass behavior. Diagnosis: count how many subclasses override each step; the more overrides, the more brittle the base class change. Fix: treat the template method signature as a public API - add new steps with default no-op implementations (hooks), never remove or reorder steps.

**Failure Mode 2: Template method calls overridable methods in constructor (incomplete initialization).**

Symptom: `NullPointerException` or incorrect behavior when overriding methods access fields initialized in subclass constructors but called during base class `initialize()`. Root cause: base class constructor calls the template method, which calls overridden steps that access subclass-specific resources not yet initialized. Diagnosis: trace the constructor call chain; check if the template method is called from a constructor. Fix: do not call overridable methods from constructors; use lazy initialization, a separate `initialize()` method called by client code, or a factory method.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Template Method pattern?"
- "What is a 'hook method' in Template Method?"

🗣️ "Template Method defines the skeleton of an algorithm in a base
class method, calling abstract methods (mandatory steps) and hook
methods (optional steps) that subclasses fill in. A hook method has
a default implementation in the base class (usually empty) that
subclasses may override. This distinguishes mandatory steps (abstract -
must override) from optional customization points (hooks - override if
needed). JUnit lifecycle methods like `@BeforeEach` are hook methods:
the test runner calls them if you define them; if not defined, the
lifecycle continues normally."

#### Mechanism
- "Walk me through Template Method vs Strategy for the same problem."

🗣️ "Same problem: exporting data to CSV or JSON. Template Method: create
`abstract class DataExporter` with a `final export()` method that calls
abstract `buildHeader()` and `formatRow()`. `CsvExporter` and `JsonExporter`
extend `DataExporter` and implement the abstract methods. The structure
(build header, iterate rows, close) is fixed in the base class.
Strategy: create `ExportStrategy` interface with `buildHeader()` and
`formatRow()`. `DataExporter` holds a `ExportStrategy` field and calls it.
Same result, different coupling. Template Method: subclassing, structure
fixed at compile time. Strategy: composition, can swap algorithm at runtime.
For a framework extension point (structure must never change): Template Method.
For runtime-configurable behavior: Strategy."

#### Comparison
- "Compare Template Method vs Strategy."

🗣️ "Template Method: inheritance-based algorithm variation. Structure is
fixed in the base class; subclasses fill in designated steps. The structure
cannot change at runtime. Strategy: composition-based algorithm variation.
The algorithm is a separate object injected into the context. The algorithm
can change at runtime. Both solve 'how to vary an algorithm.' Template Method
is appropriate when the skeleton is truly fixed (framework lifecycle, JDBC
resource management). Strategy is appropriate when the algorithm might need
to change at runtime (payment provider selection, discount calculation). In
modern Java, prefer Strategy (composition over inheritance) unless you are
building a framework extension point."

#### Scenario
- "Design a data validation pipeline using Template Method."

🗣️ "Base class `DataValidator` with `final validate(data)` template method:
(1) `prepareData(data)` (hook, default: no-op), (2) `validateRequired(data)`
(abstract), (3) `validateFormat(data)` (abstract), (4) `validateBusinessRules(data)`
(abstract), (5) `postValidation(result)` (hook, default: no-op). Returns
`ValidationResult`. `OrderValidator` extends `DataValidator` and implements
the three abstract methods for order-specific validation. `UserValidator`
implements for user-specific rules. The template ensures every validator
runs the same sequence; subclasses customize the actual checks."

#### Debugging
- "A Template Method is calling hooks in the wrong order. How do you fix it?"

🗣️ "This is usually a subclass breaking the contract. If the template
method is `final`, no subclass can reorder the steps - so if hooks run
in the wrong order, the bug is in the base class's template method itself
(a logic error in the sequence). If the template method is NOT `final`,
a subclass might have overridden it, changing the sequence. I check
whether the subclass overrides the template method (it should not). The
fix: make the template method `final` to prevent override. If the sequence
itself must vary, Template Method is the wrong pattern - use a builder
or a pipeline where the caller controls the step sequence."

#### Deep Dive
- "Where does Template Method appear in the Java collections framework?"
- "How does Java 8's interface default methods change Template Method?"

🗣️ "In `AbstractList`: `add(index, element)` is abstract; `add(element)`
is concrete and calls `add(size(), element)`. If you implement `add(index,
element)`, the non-indexed `add(element)` works automatically via the
template method. `AbstractMap.put()` is a template that calls `entrySet()`
which is abstract - you provide the entry set, the map behavior is derived.
Java 8 interface default methods change Template Method by removing the
requirement for abstract classes. An interface can define a template method
(default implementation with algorithm structure) that calls other methods
which implementors override. This is lighter-weight: no class hierarchy
required, and a class can implement multiple template interfaces. The result:
a form of Template Method without the single-inheritance limitation."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Implement a Template Method hierarchy; distinguish abstract methods from hook methods. |
| Hiring Manager | "JdbcTemplate, RestTemplate - the framework uses Template Method so you provide only the variable step." |
| Bar Raiser | "When would you refactor a Template Method to a Strategy? What signals tell you the structure is no longer fixed?" |
| Peer Engineer | "Template Method works great for framework extension. For business logic that varies, I reach for Strategy instead." |
