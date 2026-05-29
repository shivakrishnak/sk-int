---
layout: default
title: "Design Patterns - L3 Anti-patterns"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 10
permalink: /design-patterns/l3-anti-patterns/
---

# Design Pattern Anti-patterns

---
id: DP-023
title: Design Pattern Anti-patterns
category: Design Patterns
difficulty: ★★☆
interview_weight: high
asked_at: Senior+
seniority: senior
tags: #design-patterns, #anti-patterns, #over-engineering, #design-smell
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Design pattern anti-patterns are the misuse of patterns: applying them
> where they add complexity without benefit, or applying them incorrectly.
> The most common: pattern fetishism (using patterns for their own sake),
> premature patterning (adding patterns before the need exists), and
> pattern overload (applying 5 patterns to solve a 5-line problem). The
> antidote: patterns are solutions to recurring problems. No problem,
> no pattern.

**3 minutes (Senior):**
> The most dangerous anti-patterns in enterprise Java: (1) Over-engineering
> with patterns. A Singleton for a configuration object that could be
> a static field. A Factory for `new SomeService()` that is called once.
> A Strategy for a method that never has more than one implementation.
> Each adds indirection, testing complexity, and maintenance cost.
> (2) The God Class / God Object - one class doing everything. Often
> emerges when patterns are applied incorrectly: a Facade that grows
> into a 5000-line service with business logic, database access, and
> external API calls mixed together. (3) Pattern mimicry - code that
> looks like a pattern but is not. A "Factory" that does complex business
> logic. An "Adapter" that includes validation. Code labeled as "Strategy"
> where only one implementation ever exists.
>
> The production diagnostic: if you need to explain why a pattern is
> there during code review, it is probably wrong. Good patterns are
> self-evident from the problem they solve.

**Blank Mind Recovery:**

**(1) Restate:** "Pattern anti-patterns - using design patterns where
they add complexity without solving a problem."

**(2) First principles:** "Patterns solve problems. If there is no problem,
the pattern is overhead. Ask: what problem does this pattern solve here?
If the answer is vague, remove it."

**(3) Bridge:** "Like over-engineering a bridge to cross a puddle:
you do not need suspension cables for a stepping stone. The tool should
match the problem."

---

### 📘 Concept Explanation

**What it is:**
Design pattern anti-patterns are patterns applied incorrectly, excessively,
or to problems they do not solve. They create unnecessary complexity,
obscure intent, and impede maintenance.

**The problem it solves:**
(This section describes what the anti-patterns cause, so you recognize them.)
Anti-patterns cause: increased complexity without proportional benefit,
difficulty testing and debugging, resistance to future change (ironic for
patterns meant to enable change), and confusion for future maintainers.

**How anti-patterns emerge:**

```
Pattern fetishism path:
  Developer reads GoF / reads blog post
  -> "I should use patterns everywhere"
  -> Applies Singleton/Factory/Strategy to every class
  -> Code now has 40% more classes, same functionality
  -> Maintenance is harder, not easier

Over-design path:
  System designer anticipates many variations
  -> "We might need to support 3 providers someday"
  -> Adds Abstract Factory, Strategy, Registry, Plugin system
  -> Actual product ships with 1 provider, 3 years later still 1
  -> YAGNI (You Ain't Gonna Need It) violated

God Class path:
  Service layer grows organically
  -> No refactoring of large services
  -> One class accumulates all business logic
  -> "Everything depends on OrderService"
  -> Hard to test, hard to extend, low cohesion
```

**The canonical anti-patterns:**

1. **Singleton Abuse** - using Singleton for things that are not truly
   globally unique. Causes: hidden global state, testing difficulty
   (can't mock), initialization ordering problems.

2. **Factory Overuse** - creating a Factory class for simple object
   creation that never varies. Cost: extra indirection for no benefit.

3. **Strategy for One** - creating a Strategy interface with one
   implementation that never changes. This is just an interface wrapping
   a method.

4. **Observer Avalanche** - chained events where A fires event, B
   and C react, B fires another event, D and E react... producing
   unpredictable cascades that are hard to debug.

5. **God Class** (anti-pattern equivalent of Facade/Mediator gone wrong) -
   one class knowing and doing everything.

6. **Pattern Soup** - multiple patterns applied to a small problem,
   each layering more indirection.

7. **Premature Pattern** - applying the pattern before the requirement
   to vary exists.

**The key insight:**
Every pattern has a cost: more classes, more indirection, more complexity.
The cost is justified only when the problem the pattern solves exists.
YAGNI (You Ain't Gonna Need It) applied to patterns: add the pattern
when you have the problem, not in anticipation of a hypothetical future
need.

---

### 💻 Code Example

```java
// ANTI-PATTERN 1: Factory Overuse
// Problem: simple object creation that never varies
public interface UserCreator {
    User create(String name, String email);
}

public class UserFactory implements UserCreator {
    public User create(String name, String email) {
        return new User(name, email);  // just calls new
    }
}
// Why does UserFactory exist? There is no variation.
// The factory adds: 2 extra files, extra injection,
// no benefit unless User creation varies.
```

> **Code walkthrough:** `UserFactory` wraps a `new User()` with no
> variation, no complexity, no valid reason for the factory. The cost:
> two extra files, an extra dependency injection, mental overhead
> for every developer who asks "why is there a factory here?"
> The fix: `new User(name, email)` directly.

```java
// ANTI-PATTERN 2: Strategy for One
public interface EmailSender {
    void send(Email email);
}

public class SmtpEmailSender implements EmailSender {
    public void send(Email email) { /* SMTP send */ }
}

// Years pass. No other EmailSender ever exists.
// The interface adds:
// - extra file
// - mock complexity in tests (mock the interface, not needed)
// - confusion: "which implementations exist?"
// Fix: remove the interface if there's no variation.
// Add it back when a second implementation appears.
```

> **Code walkthrough:** The Strategy interface with one implementation
> is pure overhead. Interfaces are not free: they add indirection,
> increase the number of types a developer must understand, and imply
> extensibility that does not materialize. The pattern is premature -
> applied before the second implementation exists. YAGNI: add the
> interface when the second implementation arrives.

```java
// ANTI-PATTERN 3: Observer Avalanche
@EventListener
public void onOrderPlaced(OrderPlacedEvent e) {
    inventoryService.reserve(e.getOrder());
    // inventoryService publishes InventoryReservedEvent...
}

@EventListener
public void onInventoryReserved(InventoryReservedEvent e) {
    paymentService.charge(e.getOrder());
    // paymentService publishes PaymentCapturedEvent...
}

@EventListener
public void onPaymentCaptured(PaymentCapturedEvent e) {
    notificationService.notify(e.getOrder());
    // notificationService publishes NotificationSentEvent...
}
// Debugging: "why did the notification not send?"
// Trace: OrderPlaced -> InventoryReserved -> PaymentCaptured
//        -> NotificationSent? Check each link.
// Every link can fail silently.
// The cascading nature makes the flow invisible.
```

> **Code walkthrough:** Cascading events create implicit control flow.
> To understand what happens when an order is placed, you must trace
> 4+ event listeners across different files. A failure in any listener
> stops the cascade invisibly (if exceptions are caught). This is the
> Observer Avalanche: events cause events that cause events. Better:
> explicit orchestration in a Saga or OrderWorkflow class that makes
> the sequence visible.

```java
// ANTI-PATTERN 4: Pattern Soup
// Problem: display a greeting
// "Solution" with patterns:
public interface GreetingStrategy { String greet(String name); }
public class EnglishGreeting implements GreetingStrategy {
    public String greet(String name) { return "Hello, " + name; }
}
public abstract class GreetingFactory {
    public abstract GreetingStrategy create();
}
public class DefaultGreetingFactory extends GreetingFactory {
    public GreetingStrategy create() {
        return new EnglishGreeting();
    }
}
// Usage:
String msg = new DefaultGreetingFactory().create().greet("World");

// SIMPLE VERSION:
String msg = "Hello, World";
// The pattern soup adds 4 classes to replace 1 line.
```

> **Code walkthrough:** Four classes and two design patterns to produce
> a greeting string. This is pattern fetishism: patterns applied for
> their own sake, not to solve a problem. The test? "What problem does
> each pattern solve?" Strategy: no variation exists. Factory: no
> construction complexity. The simple version is the correct version.

```java
// GOOD: Recognize when patterns ARE warranted
// Before adding Strategy, ask: "Is there more than one algorithm?"
// Answer: YES (premium/standard/bulk discount) -> Strategy is right
public interface DiscountStrategy {
    double calculate(Order order);
}
// Three implementations exist -> Strategy justified

// Before adding Factory, ask: "Is construction complex or varying?"
// Answer: YES (DB config, test config differ) -> Factory justified
public interface DataSourceFactory {
    DataSource create();
}
// Two implementations exist (prod, test) -> Factory justified
```

> **Code walkthrough:** Patterns are justified when the variation
> they encapsulate exists. The test: "Show me the second implementation."
> If there is no second implementation and no imminent need for one,
> the pattern is premature. This is the Rule of Three: add an abstraction
> when you have three instances of the same pattern, not before two.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Anti-patterns are mistakes in applying design patterns. The most common
> mistake: using a pattern before you have the problem it solves. Adding
> a Factory when there is only one kind of object to create, adding a
> Strategy when there is only one algorithm. The rule: add the pattern
> when you have the problem, not to anticipate a hypothetical future.

*Push deeper:* "YAGNI - You Ain't Gonna Need It. Applied to patterns:
do not add a Strategy interface for one algorithm that never varies.
Add it when the second algorithm appears. Removing premature abstraction
later is harder than adding needed abstraction now."

---

**Senior / Staff (5+ years):**
> The most expensive anti-pattern I see in codebases: the God Service.
> An `OrderService` that is 4000 lines handling orders, inventory, payments,
> notifications, and reporting. It usually starts as a Facade and grows
> because the path of least resistance is "add to OrderService."
> Symptoms: the class has 30+ methods, it has 8+ injected dependencies,
> everything in the codebase depends on it.
>
> The fix is not another pattern - it is decomposition. Split by use case
> (OrderPlacementService, OrderFulfillmentService, OrderReportingService).
> Each becomes a focused Facade over a smaller set of dependencies.
> The test for right size: can you describe the class's responsibility in
> one sentence without using "and"?

*Push deeper:* "A useful heuristic: if a junior developer is intimidated
by how to test a class, the class is too complex. Good patterns should
make code more testable, not less. If the pattern makes testing harder
(Singleton with shared state, complex Factory hierarchies), it is being
misused."

---

### ❓ Questions You Will Be Asked

#### Definition
- "What are the most common design pattern anti-patterns?"

🗣️ "Five major ones. (1) Singleton Abuse: using Singleton for non-globally-
unique things, causing hidden global state and test difficulty. (2) Factory
Overuse: creating a factory for simple object creation that never varies.
(3) Strategy for One: defining a Strategy interface with one implementation
that never varies - pure overhead. (4) Observer Avalanche: events causing
events causing events, creating implicit control flow that is hard to debug.
(5) God Class: one class accumulating all functionality, violating single
responsibility. The underlying pattern: applying a pattern before the
problem it solves exists (YAGNI violation)."

#### Mechanism
- "How do you identify premature patterning in a codebase?"

🗣️ "Three diagnostic questions: (1) 'How many implementations of this
interface exist?' If one: the interface is likely premature. (2) 'What
problem does this pattern solve?' If the answer is vague or hypothetical
('we might need this later'), it is premature. (3) 'If I removed this
pattern, what would break?' If nothing would break (same behavior without
the indirection), the pattern adds only complexity. Code review signals:
a Factory that just calls `new`, a Strategy with one class, an Observer
that triggers another Observer. These are candidates for simplification."

#### Comparison
- "Compare the God Class anti-pattern to the Facade pattern."

🗣️ "A Facade is a thin, intentional simplification layer over a complex
subsystem. It is open to the subsystem: callers who need fine-grained
control can bypass the Facade. A God Class is an accidental accumulation:
it has high coupling (knows everything) and high complexity (does everything).
The Facade delegates and orchestrates without containing business logic.
The God Class contains business logic, presentation logic, data access,
and everything else. The diagnostic: size (God Class is typically 2000+
lines), number of dependencies (God Class has 10+), number of reasons to
change (God Class changes for any of its many responsibilities)."

#### Scenario
- "You find a 3000-line OrderService that does everything. How do you
  refactor it?"

🗣️ "Stepwise decomposition. First: identify distinct responsibilities.
A 3000-line OrderService typically contains: order creation and validation,
order payment processing, inventory management, fulfillment/shipping,
notifications, and reporting. Second: extract one responsibility at a time.
Start with the easiest to extract (notifications - fewest dependencies).
Create `NotificationService`, move those methods, update callers.
Third: for each extracted service, consider whether it is a leaf service
(calls a repository or external API) or a coordinating service (calls
other services). Coordinating services may be Facades; leaf services
should be simple. Fourth: ensure each new service has a single clear
responsibility expressible in one sentence. Rule: never extract if the
result is just as unclear."

#### Debugging
- "An Observer cascade is causing unexpected behavior. How do you trace it?"

🗣️ "Add distributed trace logging for the event chain. Every `@EventListener`
method logs at entry with a correlation ID. The correlation ID flows from
the initial event through all triggered events. With the log: filter by
correlation ID to see the full cascade for one trigger. Spring Sleuth
(Micrometer Tracing) can propagate trace IDs through Spring events
automatically. For the diagnosis: identify which listener in the chain
is causing the unexpected behavior. Options after finding the root: (1)
Break the cascade by making a step synchronous and explicit. (2) Replace
the cascade with an explicit Saga/workflow class. (3) Add guard conditions
to prevent loops."

#### Comparison Table

| Anti-Pattern | Root Cause | Symptom | Fix |
|---|---|---|---|
| Singleton Abuse | Non-unique state made global | Test isolation failures | Scope correctly (Spring bean scope) |
| Factory Overuse | Anticipated variation that never came | Extra files, no benefit | Remove factory, use new directly |
| Strategy for One | Premature abstraction | Interface with 1 implementation | Remove interface (add on 2nd impl) |
| God Class | Organic growth, no refactoring | 2000+ lines, 10+ dependencies | Extract by responsibility |
| Observer Avalanche | Event-driven overuse | Implicit control flow, debug nightmare | Explicit orchestration (Saga) |

---

### ⚖️ Comparison Table

| Factor | Correct Pattern Use | Anti-Pattern Use |
|---|---|---|
| Problem exists | Yes - the variation/problem is real | No - anticipated only |
| Implementation count | 2+ implementations/states exist | 1 implementation, never changes |
| Test complexity | Reduces or neutral | Increases |
| Code size | Justifiable by benefit | Net negative |
| Readability | Improves or neutral | Decreases |
| Reviewer reaction | "Makes sense" | "Why is this here?" |

---

### 🔥 Field Q&A

**Q: How do you convince a team that has "pattern fetishism" to simplify?**

A: Use objective metrics, not opinions. Measure: cyclomatic complexity,
lines per class, number of dependencies per class, test coverage difficulty.
Show before/after. Remove the over-engineered pattern, show the test is
simpler and just as correct. Frame it as YAGNI + Rule of Three: "We add
the abstraction when the third implementation arrives, not before."
Start with the smallest, most obvious win (the Factory that just calls `new`).
Once the team sees the benefit of simplification, larger refactors become
easier to propose. Never attack "patterns are bad" - they are not. Argue
"this specific pattern is solving a problem we don't have."

**Q: When does an Observer Avalanche become a distributed system problem?**

A: In a monolith: Observer cascades are implicit but debuggable with
trace logging. In a microservices system: an event published by Service A
triggers Service B (Kafka consumer), which publishes another event, consumed
by Service C, which triggers Service D. Now the cascade is across process
boundaries. Failures propagate with latency. Service B may succeed but
Service C's consumer may fail and retry, causing Service D to see the
event multiple times. The fix: idempotent consumers (Service D can
handle duplicate events safely) and distributed tracing (Jaeger, Zipkin)
to visualize the cross-service event flow. Orchestrated Sagas (explicit
steps, explicit compensation) are more debuggable than choreographed
event cascades at the microservices level.

---

# Singleton Anti-pattern

---
id: DP-024
title: Singleton Anti-pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: critical
asked_at: All
seniority: all
tags: #design-patterns, #singleton, #anti-pattern, #global-state, #testing
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Singleton is the most overused design pattern and one of the most
> commonly cited anti-patterns. It is legitimate for truly global, unique
> resources (a logging framework, a JVM-level registry). It is an anti-
> pattern when used to make stateful objects globally accessible, because
> it creates hidden dependencies, global mutable state, and test isolation
> failures. In Spring, the container's singleton bean scope replaces
> Singleton pattern while fixing all its problems.

**3 minutes (Senior):**
> The Singleton pattern and the Singleton anti-pattern look identical in
> code. The difference is in what the Singleton holds. Singleton is
> CORRECT for: a logger, a clock source, a configuration registry, a
> connection pool (one pool per application). Singleton is WRONG for:
> stateful business objects (OrderService, UserRepository), objects that
> should have different implementations in test vs production (payment
> gateway), objects that need to be replaced (swapped for testing).
>
> The test problem is the clearest diagnostic: if you cannot write a
> unit test for a class without the Singleton affecting the result, the
> Singleton is an anti-pattern in that context. A `DatabaseConnectionSingleton`
> used by every service means every unit test needs a real database
> or heroic mocking of a static `getInstance()` call.
>
> Spring's solution: scope all beans as singletons by default, but through
> the DI container. The container manages the single instance. You inject
> it via the constructor. In tests: inject a mock. The singleton lifecycle
> is managed without any class being tied to a `getInstance()` call.

**Blank Mind Recovery:**

**(1) Restate:** "Singleton anti-pattern - using Singleton for stateful
or test-sensitive objects, creating global state problems."

**(2) First principles:** "Singleton is just a global variable with
a fancy name. Global variables are problematic in large systems. Use
them only where genuinely necessary."

**(3) Bridge:** "Like a public bathroom: fine for the general purpose
it serves. But if you put the company's entire financial data in a public
bathroom, anyone can see and modify it. Singletons with mutable state
are the same: globally accessible, globally writable, no isolation."

---

### 📘 Concept Explanation

**What it is (pattern form):**
Singleton ensures a class has only one instance and provides a global
access point to it. The constructor is private; the single instance
is returned via `getInstance()`.

**What makes it an anti-pattern:**
When the Singleton holds mutable state accessible from anywhere in the
application. This is a hidden global variable with extra syntax. The
consequences: any code anywhere can modify the state; test isolation
is impossible without resetting the Singleton between tests; concurrent
access requires synchronization; the class cannot be replaced
(mocked/stubbed) in tests.

**Problems with the classic Singleton:**

```
// Classic Singleton - all problems visible
public class DatabaseSingleton {
    private static DatabaseSingleton instance;
    private Connection connection;

    private DatabaseSingleton() {
        connection = createConnection(); // hidden dependency
    }

    public static DatabaseSingleton getInstance() {
        if (instance == null) {  // Not thread-safe!
            instance = new DatabaseSingleton();
        }
        return instance;
    }
}

// Problem 1: Hidden dependency
class OrderService {
    public void process(Order o) {
        DatabaseSingleton.getInstance()
            .save(o);  // Hidden coupling
    }
    // OrderService constructor does not reveal DB dependency
}

// Problem 2: Test isolation failure
@Test
void test1() {
    DatabaseSingleton.getInstance().setState("A");
}
@Test
void test2() {
    // State is "A" from test1! Tests share the Singleton.
    // Order-dependent test failures.
}
```

**The thread-safety problem:**

```
// Classic: not thread-safe
if (instance == null) {            // Thread A checks: null
    instance = new Singleton();    // Thread B checks: null (same time!)
}                                  // Both create instances -> 2 singletons!

// Fix 1: synchronized - correct but slow (every call acquires lock)
public static synchronized Singleton getInstance() {
    if (instance == null) instance = new Singleton();
    return instance;
}

// Fix 2: Double-checked locking (correct in Java 5+)
private static volatile Singleton instance;
public static Singleton getInstance() {
    if (instance == null) {              // Fast path: no lock
        synchronized(Singleton.class) { // Slow path: lock
            if (instance == null) {      // Re-check under lock
                instance = new Singleton();
            }
        }
    }
    return instance;
}

// Fix 3: Initialization-on-demand holder (best)
private static class Holder {
    static final Singleton INSTANCE = new Singleton();
}
public static Singleton getInstance() {
    return Holder.INSTANCE;
}
// JVM class loading is thread-safe.
// Holder class loaded only when getInstance() first called.
```

> **Code walkthrough:** Three thread-safety solutions. `synchronized`
> on every `getInstance()` call creates lock contention on every access -
> wrong for high-concurrency systems. Double-checked locking with `volatile`
> is correct in Java 5+ (the `volatile` keyword ensures the write to
> `instance` is not reordered). Initialization-on-demand Holder is the
> cleanest: no explicit synchronization, leverages JVM class loading
> which is inherently thread-safe, lazy (only initialized when first
> accessed).

**When Singleton is correct:**
- Truly global, unique resources: a logging framework (one per JVM),
  a configuration store (one per application), a JVM-level registry
- Resources where creating multiple instances is wrong or impossible:
  a connection pool (one pool prevents over-provisioning), an OS-level
  resource handle
- Stateless utilities with no variation in implementation

**When Singleton is an anti-pattern:**
- Stateful services that need to be different in test vs production
- Any object that needs to be mocked or substituted
- Services that could logically have multiple instances (one per tenant,
  one per user, one per request)

**The Spring alternative:**
Spring's default bean scope is singleton - one instance per container.
This gives you the one-instance guarantee without the `getInstance()`
problem. The instance is accessed via dependency injection:
`@Autowired`, constructor injection. In tests: inject a mock via
`@MockBean`. No static method, no global state leak, full testability.

---

### 💻 Code Example

```java
// BAD: Classic Singleton for a configuration service
public class AppConfig {
    private static AppConfig instance;
    private final Map<String, String> properties
        = new HashMap<>();

    private AppConfig() {
        // Loads from file at construction
        load("application.properties");
    }

    public static AppConfig getInstance() {
        if (instance == null) {
            instance = new AppConfig();
        }
        return instance;
    }

    public String get(String key) {
        return properties.get(key);
    }
}

// Problem: any class can call AppConfig.getInstance()
// Unit test for PaymentService needs real application.properties
// Cannot inject a test config without resetting the static field
public class PaymentService {
    public void charge(Order order) {
        String apiKey = AppConfig.getInstance()
            .get("payment.api.key");  // hidden static dependency
        // Test for this needs real config file or static hacking
    }
}
```

> **Code walkthrough:** `AppConfig.getInstance()` is a hidden dependency.
> `PaymentService`'s constructor signature says it has zero dependencies,
> but it secretly reads from a global Singleton. Testing `PaymentService`
> requires a real `application.properties` file with `payment.api.key`.
> In CI/CD: every test environment needs this config. There is no way
> to inject a test config without reflection.

```java
// GOOD: Spring manages the singleton lifecycle
@Configuration
@ConfigurationProperties(prefix = "app")
public class AppConfig {
    private String paymentApiKey;
    // Spring reads from application.properties automatically
    // Setter injection by Spring
    public void setPaymentApiKey(String key) {
        this.paymentApiKey = key;
    }
    public String getPaymentApiKey() { return paymentApiKey; }
}

// Spring singleton - injected, not static
@Service
public class PaymentService {
    private final AppConfig config;

    // Explicit dependency: visible in constructor
    public PaymentService(AppConfig config) {
        this.config = config;
    }

    public void charge(Order order) {
        // Config injected - not a hidden static call
        String apiKey = config.getPaymentApiKey();
    }
}

// Test: inject test config easily
@SpringBootTest
class PaymentServiceTest {
    @MockBean
    AppConfig testConfig;

    @Test
    void test() {
        when(testConfig.getPaymentApiKey())
            .thenReturn("test-key-123");
        // PaymentService receives the mock config
        // No static singleton to reset
    }
}
```

> **Code walkthrough:** Spring manages `AppConfig` as a singleton bean.
> `PaymentService` declares its dependency via the constructor - it is
> visible to anyone reading the class. Tests inject a `@MockBean`
> replacement. The singleton guarantee (one instance per application)
> is preserved without any class calling `AppConfig.getInstance()`.
> This is the Spring solution to the Singleton anti-pattern: keep the
> one-instance guarantee, remove the global static access.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Singleton ensures one instance of a class. It is a pattern but also
> a well-known anti-pattern because it creates hidden global state. The
> main problems: hard to test (you cannot easily replace the Singleton
> with a test double), and state from one test leaks into another.
> In Spring, all beans are singletons by default but managed by the
> container - you inject them via constructors, not via `getInstance()`.
> This preserves the one-instance guarantee while keeping code testable.

*Push deeper:* "Thread safety: the classic double-check idiom `if (instance == null) { synchronized { if (instance == null) { instance = new Singleton(); } } }` requires `volatile` on the field in Java 5+.
The initialization-on-demand Holder is simpler and always correct."

---

**Senior / Staff (5+ years):**
> The Singleton pattern's problems are all manifestations of the same
> underlying issue: static access to mutable state. Static access breaks
> dependency inversion (you cannot inject a different implementation),
> makes dependencies invisible (not in the constructor), and prevents
> parallelization in tests (shared mutable state between tests).
>
> My rule: no static access to mutable state. Static utility methods
> (math functions, string manipulation) are fine - they are stateless.
> Static fields holding mutable state: never in production code unless
> explicitly justified (JVM-level resources). Spring's DI solves the
> Singleton pattern's problems by providing the same one-instance
> guarantee through injection rather than static access.

*Push deeper:* "There is a legitimate use for Singleton at the JVM level:
security and resource management. `Runtime.getRuntime()` is a legitimate
Singleton - there is exactly one JVM runtime. A connection pool should
be a singleton to prevent connection over-provisioning. The test: 'Would
two instances of this object in the same JVM be semantically incorrect?'
If yes: Singleton is appropriate. If the answer is 'we just want one for
convenience': use DI scope instead."

---

### ❓ Questions You Will Be Asked

#### Definition
- "Why is Singleton considered an anti-pattern? When is it legitimate?"

🗣️ "Singleton is both a pattern and an anti-pattern depending on use.
It is a pattern when: there is genuinely one resource (one JVM runtime,
one connection pool, one logging framework) and having two would be wrong.
It is an anti-pattern when: used for convenience to make any service
globally accessible. The problems: hidden dependencies (not visible in
constructors), global mutable state (any code anywhere can read/write),
test isolation failures (shared state across tests), and inability to
replace the implementation (you cannot inject a mock). In Spring:
all beans are singleton-scoped by default but accessed via injection,
not `getInstance()`. This preserves the one-instance guarantee and
eliminates all the anti-pattern problems."

#### Mechanism
- "Why is the double-checked locking pattern needed? Explain the race condition."

🗣️ "Classic non-synchronized `if (instance == null) { instance = new Singleton(); }`: Thread A checks, sees null. Thread B checks, sees null (before A's assignment).
Both create instances. The singleton guarantee is violated. Synchronized
method: correct but slow - every `getInstance()` call acquires and
releases the lock. Double-checked locking: first check without lock (fast
path for already-initialized case). Second check with lock (prevents
double initialization). In Java 4 and earlier, the JVM could reorder
memory operations such that a partially-constructed object was visible to
another thread, breaking the pattern. Java 5's memory model + the
`volatile` keyword on the field prevents this reordering. The Holder
idiom: uses JVM class loading, which is inherently thread-safe, for zero
explicit synchronization."

#### Comparison
- "Compare Singleton pattern vs Spring's singleton bean scope."

🗣️ "Both guarantee one instance. The mechanism and consequences differ.
Singleton pattern: the class itself ensures one instance via private
constructor and static `getInstance()`. Access is through static method.
Dependencies are hidden (not in constructor). Difficult to test or replace.
Spring singleton scope: the Spring container ensures one instance per
application context. Access is through injection. Dependencies are explicit
(constructor or field injection). Easy to replace in tests (`@MockBean`,
`@SpyBean`). The key distinction: Spring's singleton is a factory/container
concern, not a class-level concern. The class itself has a public constructor
and can be instantiated multiple times in tests if needed."

#### Scenario
- "You find that tests are interfering with each other because of a
  Singleton. How do you fix it?"

🗣️ "Diagnostic first: identify which Singleton is shared. If it is a
Spring bean: check if `@MockBean` resets between tests (it does if
`@SpringBootTest` reloads the context - use `@DirtiesContext` if not).
If it is a classic static Singleton: add a `reset()` package-private
method for tests that clears the static instance; call it in `@BeforeEach`.
This is a temporary fix. The real fix: refactor the Singleton to Spring
singleton scope with constructor injection. Update test code to inject
a mock. Remove the `reset()` hack. The long-term result: tests are
independent and parallel-safe."

#### Debugging
- "A Singleton is returning stale data. How do you diagnose?"

🗣️ "Stale data in a Singleton usually means: (1) The Singleton loaded
data at construction and the source has since changed, but the Singleton
never reloaded. (2) A thread wrote new data to the Singleton's fields,
but the `volatile` keyword is missing so another thread reads a cached
value. (3) The Singleton is a caching proxy and the TTL logic is wrong.
For (1): add a `refresh()` method or make the Singleton listen for
configuration change events. For (2): add `volatile` to mutable fields
or use `AtomicReference`. For (3): add logging to the cache hit/miss
path; log the cached value's age. The `volatile` issue is the trickiest:
it only manifests on multi-core machines under certain timing conditions,
making it hard to reproduce."

#### Comparison Table

| Aspect | Classic Singleton | Spring Singleton Bean | Static Field |
|---|---|---|---|
| One instance guarantee | Yes (within JVM classloader) | Yes (within Spring context) | Yes (within classloader) |
| Testability | Poor (static access, no mock) | Excellent (@MockBean) | Poor |
| Dependency visibility | Hidden | Explicit (injection) | Hidden |
| Multiple contexts | Same instance | Different per context | Same instance |
| Thread safety | Manual (volatile, DCL) | Managed by Spring | Manual |

---

### ⚖️ Comparison Table

| Factor | Singleton Pattern | Spring Singleton Scope | Thread-local |
|---|---|---|---|
| Instance per | JVM classloader | Spring application context | Thread |
| Access mechanism | Static getInstance() | Injection | ThreadLocal.get() |
| Testability | Poor | Excellent | Moderate |
| State isolation | None (shared) | Shared | Per-thread |
| Use case | JVM-level resources | Application services | Request context |

---

### 🔥 Field Q&A

**Q: An enum-based Singleton (a single-element enum) is often cited as the
best Singleton implementation. Why?**

A: `public enum MySingleton { INSTANCE; }` is the Joshua Bloch recommendation
(Effective Java). Benefits: (1) JVM guarantees exactly one instance of each
enum constant. No static initialization race condition. (2) The Singleton
property survives serialization: standard deserialization of enum returns
the canonical instance, not a new object. Classic Singleton `readResolve()`
must be manually implemented to prevent serialization from creating a second
instance. (3) Reflection attacks: `Constructor.newInstance()` cannot create
new enum instances (JVM prevents it). For a classic Singleton, reflection
can bypass the private constructor. (4) Concise. The limitations: enum
cannot extend another class (only implement interfaces). Spring cannot
manage enum beans the same way. For most production Java: Spring singleton
bean scope is preferred over enum-Singleton for testability.

**Q: What is the difference between a Singleton and the Monostate pattern?**

A: Singleton: enforces single instance via private constructor. Monostate:
allows multiple instances but all instances share the same static state.
`new MyMonostate()` and `new MyMonostate()` create two objects, but they
both read from and write to the same static fields. Monostate seems cleaner
(normal construction, no `getInstance()`) but has the same problems as
Singleton: global static state, test isolation failures, no mock injection.
Both are anti-patterns for mutable state in production code. Monostate is
arguably worse because it is invisible: the class looks like a normal class
but behaves like a global variable. At least the Singleton pattern is
explicitly communicating "only one instance."
