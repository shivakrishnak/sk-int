---
layout: default
title: "Design Patterns - Structural"
parent: "Design Patterns"
grand_parent: "Interview Mastery"
nav_order: 2
permalink: /interview/design-patterns/structural/
topic: Design Patterns
subtopic: Structural
keywords:
  - Adapter
  - Decorator
  - Proxy
  - Facade
  - Composite
difficulty_range: mixed
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Adapter](#adapter)
- [Decorator](#decorator)
- [Proxy](#proxy)
- [Facade](#facade)
- [Composite](#composite)

# Adapter

**TL;DR** - Adapter converts the interface of a class into another interface clients expect, allowing incompatible interfaces to work together without modifying either.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your analytics system processes data from `DataSource` objects with a `getData()` method. A new vendor provides a superior analytics library, but it expects `Stream` objects with a `read()` method. The two interfaces are incompatible. You can't change the vendor library. You can't rewrite every DataSource implementation. You're stuck between two systems that should work together but can't.

**THE BREAKING POINT:**
You create a wrapper class that copies data from DataSource to a temporary buffer, then feeds it to Stream. The wrapper duplicates logic, is fragile, and breaks when either interface evolves. Every new data source requires a new wrapper.

**THE INVENTION MOMENT:**
"This is exactly why Adapter was created."

**EVOLUTION:**
The GoF formalized Adapter in 1994 with two variants: class adapter (inheritance) and object adapter (composition). Java's `Arrays.asList()` is a classic adapter - it adapts an array to the `List` interface. Modern usage includes Spring's `HandlerAdapter`, SLF4J (adapting any logging framework to one interface), and REST API adapters that translate between API versions.
---

### 📘 Textbook Definition

Adapter is a structural design pattern that allows objects with incompatible interfaces to collaborate. It wraps one interface and translates calls to the format expected by the other, acting as a bridge between two incompatible systems without modifying either.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
A translator between two incompatible interfaces.

**One analogy:**

> A power adapter for international travel. Your laptop has a US plug. The outlet in Europe is different. The adapter sits between them, translating one shape to another. Neither the laptop nor the outlet is modified.

**One insight:**
Adapter is about reuse, not abstraction. You have existing code that works. You have new code that needs a different interface. Adapter lets you use both without rewriting either. It's the pattern of practical integration.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. The client expects one interface (the target)
2. The adaptee provides functionality through a different interface
3. The adapter translates between the two without modifying either

**DERIVED DESIGN:**
The adapter implements the target interface. It holds a reference to the adaptee. Each method in the target interface delegates to the appropriate method(s) in the adaptee, translating parameters and return values as needed.

**THE TRADE-OFFS:**
**Gain:** Reuse existing code with incompatible interfaces, single point of translation, client code unchanged
**Cost:** One more layer of indirection, can mask poor interface design if overused

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Interface translation requires code somewhere - the mapping logic is inherent
**Accidental:** In languages with duck typing (Python, Go), many Adapter use cases disappear because interfaces are implicit
---

### 🧠 Mental Model / Analogy

> Think of Adapter as a human translator at a UN meeting. The speaker talks in French. The listener understands only English. The translator sits between them, converting French to English in real time. Neither the speaker nor the listener changes how they communicate.

- "Speaker" -> adaptee (existing system)
- "Listener" -> client (expecting target interface)
- "Translator" -> adapter class
- "Languages" -> incompatible interfaces

Where this analogy breaks down: A human translator can handle ambiguity; an Adapter maps method signatures precisely and fails on any mismatch.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Adapter is a wrapper that makes one thing look like another. Like a phone case that adds a headphone jack to a phone that only has USB-C.

**Level 2 - How to use it (junior developer):**
Create a class that implements the interface your code expects. Inside that class, hold a reference to the old object and translate method calls. `Arrays.asList(array)` is an adapter: it makes an array look like a `List`.

**Level 3 - How it works (mid-level engineer):**
Two forms exist: **Object Adapter** (composition - holds a reference to the adaptee, more flexible, preferred) and **Class Adapter** (inheritance - extends the adaptee, only works with single inheritance). Object Adapter can adapt multiple adaptees; Class Adapter is limited to one but avoids delegation overhead. In Java, SLF4J is a massive adapter system: `slf4j-log4j12.jar` adapts SLF4J calls to Log4j, `slf4j-jdk14.jar` adapts to JUL. Same client code, different backends.

**Level 4 - Mastery (senior/staff+ engineer):**
Adapter is the pattern of pragmatic integration. In microservices, anti-corruption layers are essentially Adapters between bounded contexts. When integrating legacy systems, the Adapter layer isolates your domain model from the legacy data model. In API versioning, a v2-to-v1 adapter allows old clients to work with a new API. The key design decision is where to place the Adapter: at the boundary of your system (clean architecture ports), not deep inside. Over-adapting (adapting adapters) is a code smell indicating you should redesign the interfaces instead.




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
[Client] --> [Target Interface]
                   |
            [Adapter implements Target]
                   |
            [Delegates to Adaptee]
                   |
            [Adaptee.specificMethod()]
```

1. Client calls target interface method
2. Adapter receives the call
3. Adapter translates parameters
4. Adapter calls adaptee's method
5. Adapter translates the return value
6. Client receives the expected response
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
[Client code] -> [adapter.targetMethod() <- YOU ARE HERE]
  -> [adaptee.differentMethod(translated args)]
  -> [result translated back]
  -> [Client receives expected type]
```

**FAILURE PATH:**

```
[Adaptee method throws unexpected exception]
  -> [Adapter must translate exception too]
  -> [Client sees unfamiliar error type]
  -> [Fix: map adaptee exceptions to target exceptions]
```

**WHAT CHANGES AT SCALE:**
At scale, adapter layers become performance bottlenecks if they perform complex data transformations. Use object pooling or caching in the adapter for expensive translations. In distributed systems, API gateways act as network-level adapters, translating protocols (REST to gRPC, GraphQL to REST).
---

### 💻 Code Example

**Example 1 - BAD: Direct coupling to third-party API**

```java
// BAD: Client code coupled to vendor's interface
public class ReportService {
    public Report generate(VendorDataProvider vendor) {
        // Directly uses vendor's method names
        RawData raw = vendor.fetchRawMetrics();
        // If vendor changes API, all callers break
        return processRaw(raw);
    }
}
```

**Example 2 - GOOD: Adapter pattern**

```java
// GOOD: Client uses its own interface
public interface DataProvider {
    MetricData getMetrics(DateRange range);
}

// Adapter translates between interfaces
public class VendorAdapter implements DataProvider {
    private final VendorDataProvider vendor;

    public VendorAdapter(VendorDataProvider vendor) {
        this.vendor = vendor;
    }

    @Override
    public MetricData getMetrics(DateRange range) {
        // Translate our DateRange to vendor's format
        var vendorRange = new VendorDateRange(
            range.start().toEpochMilli(),
            range.end().toEpochMilli());
        // Call vendor's differently-named method
        RawData raw = vendor.fetchRawMetrics(vendorRange);
        // Translate vendor's response to our type
        return MetricData.fromRaw(raw);
    }
}

// Client code never changes, even if vendor changes
public class ReportService {
    private final DataProvider provider;

    public ReportService(DataProvider provider) {
        this.provider = provider;
    }

    public Report generate(DateRange range) {
        MetricData data = provider.getMetrics(range);
        return process(data);
    }
}
```

**How to test / verify correctness:**
Unit test the adapter by mocking the adaptee, verifying parameter translation. Integration test with the real adaptee to verify end-to-end data flow.
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

1. Adapter translates between incompatible interfaces without modifying either side
2. Prefer object adapter (composition) over class adapter (inheritance) for flexibility
3. Place adapters at system boundaries, not deep inside your domain

**Interview one-liner:**
"Adapter wraps an incompatible interface to make it conform to what the client expects - I use it at integration boundaries, like wrapping third-party APIs behind our own interfaces so vendor changes don't ripple through the codebase."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

SLF4J, the logging facade used by virtually every Java application, is the most successful Adapter pattern implementation in the Java ecosystem. It doesn't log anything itself - it adapts any logging framework (Log4j, Logback, JUL) to a single API. The genius is that the Adapter is the product. Most developers use SLF4J daily without realizing they're using an Adapter pattern.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Adapter. Otherwise remove this section.]
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

**Q1: What's the difference between Adapter, Decorator, and Proxy? They all wrap objects.**

_Why they ask:_ Tests ability to distinguish structurally similar patterns by intent.

**Answer:**
All three wrap an object, but their intent is completely different:

| Pattern   | Intent                               | Interface change? | Behavior change? |
| --------- | ------------------------------------ | ----------------- | ---------------- |
| Adapter   | Convert one interface to another     | Yes (different)   | No               |
| Decorator | Add behavior to existing interface   | No (same)         | Yes (enhanced)   |
| Proxy     | Control access to existing interface | No (same)         | Yes (controlled) |

**Adapter:** `SquarePeg -> RoundHole`. Different interface, same behavior.
**Decorator:** `BufferedInputStream(FileInputStream)`. Same interface, enhanced behavior (buffering).
**Proxy:** `CachedUserService(RealUserService)`. Same interface, controlled behavior (caching, access control).

The test: If the wrapper changes the interface, it's Adapter. If it adds functionality, it's Decorator. If it controls access, it's Proxy.

---

**Q2: How would you use Adapter in an anti-corruption layer between microservices?**

_Why they ask:_ Tests real-world architecture skills.

**Answer:**
When Service A (our domain) depends on Service B (legacy or external), an anti-corruption layer prevents B's model from leaking into A:

```java
// Our domain model
public record Order(String id, Money total,
                    List<LineItem> items) {}

// Legacy service returns different structure
public record LegacyOrder(int orderNum,
    double amt, String currency,
    List<Map<String, Object>> lines) {}

// Anti-corruption adapter
public class OrderAdapter {
    private final LegacyOrderClient legacy;

    public Order getOrder(String id) {
        LegacyOrder lo = legacy.fetch(
            Integer.parseInt(id));
        return new Order(
            String.valueOf(lo.orderNum()),
            Money.of(lo.amt(), lo.currency()),
            lo.lines().stream()
                .map(this::toLineItem)
                .toList());
    }
}
```

The adapter sits at the service boundary. If the legacy system changes its data model, only the adapter changes. Our domain code remains clean. This is a DDD principle: the adapter protects our bounded context from external models.

---

**Q3: When would Adapter be the wrong choice?**

_Why they ask:_ Tests critical judgment about pattern applicability.

**Answer:**
Adapter is wrong when:

1. **You control both interfaces:** If you can change the source or target interface, do that instead. Adapter is for situations where at least one side is immutable.

2. **The semantic gap is too large:** If translating between interfaces requires complex business logic (not just mechanical mapping), the adapter becomes a hidden service layer. Extract that logic into a proper domain service.

3. **Performance-critical paths:** Each adapter call adds a stack frame, object creation, and data copying. In hot loops, the overhead matters. Profile first, then decide.

4. **Adapting adapters:** If you're wrapping an adapter in another adapter, the design has gone wrong. Redesign the interfaces or introduce a proper abstraction layer.

The smell: if your adapter is longer than 50 lines and contains conditional logic, it's no longer an adapter - it's a translation service that should be a first-class component.
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

# Decorator

**TL;DR** - Decorator attaches additional responsibilities to an object dynamically by wrapping it, providing a flexible alternative to subclassing for extending behavior.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your coffee shop application has a base `Coffee` class. Customers want extras: milk, sugar, whipped cream, caramel. You create subclasses: `CoffeeWithMilk`, `CoffeeWithSugar`, `CoffeeWithMilkAndSugar`, `CoffeeWithMilkAndSugarAndWhippedCream`. With 5 add-ons, you need 2^5 = 32 subclasses. Adding a 6th add-on doubles it to 64. The class hierarchy explodes.

**THE BREAKING POINT:**
A customer wants double whipped cream. Your rigid hierarchy doesn't support quantity. Another wants milk in their tea, not just coffee. The subclass explosion is unmanageable.

**THE INVENTION MOMENT:**
"This is exactly why Decorator was created."

**EVOLUTION:**
The GoF formalized Decorator in 1994. Java's I/O streams are the classic example: `new BufferedReader(new InputStreamReader(new FileInputStream(file)))`. Each wrapper adds behavior. Modern usage includes Spring's `@Transactional` (decorating method calls with transaction management), middleware pipelines in Express.js, and Python's `@decorator` syntax (syntactic sugar for function wrapping).
---

### 📘 Textbook Definition

Decorator is a structural design pattern that lets you attach new behaviors to objects by placing them inside wrapper objects that contain the behaviors. It provides a flexible alternative to subclassing for extending functionality, supporting the Open/Closed Principle by allowing behavior composition at runtime.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Wrap an object to add behavior without changing its interface.

**One analogy:**

> Decorating a Christmas tree. The tree is the base object. Each ornament (lights, tinsel, star) adds visual behavior. You can add or remove ornaments freely. The tree is still a tree regardless of decorations.

**One insight:**
Decorator is not about decoration - it's about composition over inheritance. Instead of creating 32 subclasses for every combination, you create 5 decorators and compose them at runtime. The key: the decorator has the same interface as the object it wraps, so clients don't know they're talking to a decorated version.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Decorators implement the same interface as the component they wrap
2. Decorators hold a reference to a component (composition)
3. Multiple decorators can be stacked (chained)

**DERIVED DESIGN:**
The decorator forwards calls to the wrapped component and adds behavior before/after the delegation. Since it implements the same interface, it's substitutable for the original component. This enables recursive composition: a decorator can wrap another decorator.

**THE TRADE-OFFS:**
**Gain:** Runtime behavior composition, avoids subclass explosion, follows Open/Closed Principle
**Cost:** Many small objects, debugging through decorator chains is complex, ordering can matter

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Combining behaviors requires some composition mechanism - the wrapping pattern is inherent
**Accidental:** Java's I/O stream API makes simple operations verbose (`new BufferedReader(new InputStreamReader(...))`) - this is an API design choice, not a pattern limitation
---

### 🧠 Mental Model / Analogy

> Think of Decorator as Russian nesting dolls (Matryoshka). Each doll wraps the one inside it. They all look the same from the outside (same interface). Each layer adds something (decoration). You can add or remove layers without breaking the structure.

- "Inner doll" -> original component
- "Each outer doll" -> decorator adding behavior
- "Same shape" -> same interface
- "Stackable" -> decorators can wrap decorators

Where this analogy breaks down: Matryoshka dolls are purely visual; Decorators actively modify or enhance behavior on each method call.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Decorator wraps something to add extras without changing the original. Like putting a phone case on your phone - the phone still works the same way, but now it's protected and maybe has a card holder.

**Level 2 - How to use it (junior developer):**
Create an interface (`Component`). Create a base class (`ConcreteComponent`). Create a decorator class that implements `Component`, holds a `Component` reference, and adds behavior. Example: `LoggingService` wraps `UserService` - it logs every call then delegates to the real service.

**Level 3 - How it works (mid-level engineer):**
Java I/O is the textbook example. `InputStream` is the component interface. `FileInputStream` is the concrete component. `BufferedInputStream`, `DataInputStream`, `GZIPInputStream` are decorators. You compose them: `new DataInputStream(new BufferedInputStream(new GZIPInputStream(new FileInputStream(f))))`. Each layer adds one responsibility: decompression, buffering, data type reading. The order matters - buffering before decompression is different from decompression before buffering.

**Level 4 - Mastery (senior/staff+ engineer):**
Decorator is the foundational pattern behind middleware, interceptors, and aspect-oriented programming. Spring's `@Transactional` generates a proxy that decorates your bean with transaction management. Servlet filters are decorators on the request/response pipeline. In functional programming, function composition (`f(g(x))`) is Decorator without the object-oriented ceremony. The key architectural insight: Decorator enforces the Single Responsibility Principle for cross-cutting concerns (logging, caching, retry, metrics) without polluting business logic. In production, I've used it for: circuit breaker wrappers around HTTP clients, audit logging decorators on repository interfaces, and rate-limiting decorators on API handlers.




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
Client -> [Component interface]
              |
    +---------+---------+
    |                   |
[ConcreteComp]    [Decorator (abstract)]
                        |
              +---------+---------+
              |                   |
        [LoggingDeco]       [CachingDeco]

Call chain:
[Client] -> [CachingDeco]
              -> check cache
              -> [LoggingDeco]
                   -> log call
                   -> [ConcreteComp]
                        -> real work
                   <- log result
              <- store in cache
           <- return to client
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
[Client] -> [Decorator A (caching)]
  -> [Decorator B (logging) <- YOU ARE HERE]
  -> [ConcreteComponent (real logic)]
  -> [Result bubbles back through chain]
```

**FAILURE PATH:**

```
[ConcreteComponent throws exception]
  -> [Each decorator must handle or propagate]
  -> [Logging decorator captures error]
  -> [Caching decorator skips caching]
  -> [Client receives exception]
```

**WHAT CHANGES AT SCALE:**
At scale, decorator chains can become performance bottlenecks due to deep call stacks. Profiling shows N extra method calls per operation (one per decorator). In high-throughput systems, consider inlining critical decorators or using AOP byte-code weaving (AspectJ) to avoid the runtime overhead of object wrapping.
---

### 💻 Code Example

**Example 1 - BAD: Subclass explosion**

```java
// BAD: Every combination = new class
class Coffee { double cost() { return 2.0; } }
class CoffeeWithMilk extends Coffee {
    double cost() { return 2.5; }
}
class CoffeeWithMilkAndSugar extends Coffee {
    double cost() { return 2.7; }
}
// 5 add-ons = 32 classes. Unmanageable.
```

**Example 2 - GOOD: Decorator pattern**

```java
// GOOD: Compose at runtime, any combination
public interface Beverage {
    double cost();
    String description();
}

public class Espresso implements Beverage {
    public double cost() { return 2.0; }
    public String description() { return "Espresso"; }
}

public abstract class BeverageDecorator
        implements Beverage {
    protected final Beverage wrapped;
    protected BeverageDecorator(Beverage b) {
        this.wrapped = b;
    }
}

public class MilkDecorator extends BeverageDecorator {
    public MilkDecorator(Beverage b) { super(b); }
    public double cost() {
        return wrapped.cost() + 0.50;
    }
    public String description() {
        return wrapped.description() + " + Milk";
    }
}

// Usage: compose freely at runtime
Beverage order = new MilkDecorator(
    new SugarDecorator(new Espresso()));
// "Espresso + Sugar + Milk" -> $2.70
```

**Example 3 - GOOD: Production decorator for services**

```java
// GOOD: Add logging to any service transparently
public class LoggingUserService implements UserService {
    private final UserService delegate;
    private final Logger log = LoggerFactory
        .getLogger(LoggingUserService.class);

    public LoggingUserService(UserService delegate) {
        this.delegate = delegate;
    }

    @Override
    public User findById(String id) {
        log.info("Finding user: {}", id);
        long start = System.nanoTime();
        try {
            User u = delegate.findById(id);
            log.info("Found user {} in {}ms", id,
                (System.nanoTime() - start) / 1_000_000);
            return u;
        } catch (Exception e) {
            log.error("Failed to find user {}", id, e);
            throw e;
        }
    }
}
```

**How to test / verify correctness:**
Test each decorator independently with a mock component. Test decorator stacking order. Verify the original component is called exactly once per decorated call.
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

1. Decorator wraps an object with the same interface to add behavior without subclassing
2. Java I/O streams are the canonical example: `BufferedReader(InputStreamReader(FileInputStream))`
3. Use for cross-cutting concerns (logging, caching, retry) - keeps business logic clean

**Interview one-liner:**
"Decorator wraps an object to add behavior dynamically while keeping the same interface - I use it for cross-cutting concerns like logging, caching, and circuit breaking, where inheritance would cause a class explosion."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Python's `@decorator` syntax, used millions of times daily, is technically function composition, not the GoF Decorator pattern. `@log def foo()` replaces `foo` with `log(foo)`. It doesn't implement a shared interface or use object wrapping. Yet it achieves the same goal: adding behavior without modifying the original. This shows that patterns transcend their original OOP formulation - the principle is universal even when the implementation looks nothing like the GoF diagram.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Decorator. Otherwise remove this section.]
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

**Q1: How does Decorator differ from inheritance for extending behavior?**

_Why they ask:_ Tests understanding of composition vs inheritance trade-offs.

**Answer:**
Inheritance is static and compiled in. Decorator is dynamic and composed at runtime.

| Aspect       | Inheritance                   | Decorator               |
| ------------ | ----------------------------- | ----------------------- |
| When decided | Compile time                  | Runtime                 |
| Combinations | One per subclass (2^N)        | Compose freely          |
| Modification | Change base class affects all | Each decorator isolated |
| Testing      | Must test full hierarchy      | Test each independently |
| Coupling     | Tight (extends)               | Loose (implements)      |

Inheritance breaks when: (1) you need multiple independent extensions combined (2) you need to add/remove behavior at runtime (3) the base class is `final` or from a third-party library.

Decorator breaks when: (1) the interface has many methods (every decorator must implement all of them) (2) decorator order matters and is hard to control (3) identity checks (`instanceof`) don't see the wrapped type.

In practice, I default to Decorator for cross-cutting concerns and use inheritance only for genuine "is-a" relationships.

---

**Q2: You need to add retry, circuit breaking, and metrics to an HTTP client. How would you structure this using Decorator?**

_Why they ask:_ Tests practical production architecture skills.

**Answer:**

```java
public interface HttpClient {
    Response execute(Request req);
}

// Stack from outside in:
HttpClient client = new MetricsDecorator(
    new CircuitBreakerDecorator(
        new RetryDecorator(
            new RealHttpClient(),
            RetryConfig.ofDefaults()),
        CircuitBreakerConfig.ofDefaults()),
    meterRegistry);
```

Order matters here:

1. **Metrics** (outermost): measures total time including retries
2. **Circuit breaker**: prevents calls when failure rate is high
3. **Retry** (innermost): retries on transient failures

If we put retry outside circuit breaker, retries would trigger even when the circuit is open - wasting time on calls that are guaranteed to fail.

Each decorator is independently testable. In Spring, I'd register each as a `@Bean` and compose them in a `@Configuration` class. For more complex scenarios, I'd use Resilience4j which already implements these as composable decorators.

---

**Q3: What are the pitfalls of using Decorator in production?**

_Why they ask:_ Tests real-world experience with pattern limitations.

**Answer:**

1. **Identity confusion:** `decoratedService instanceof RealService` returns `false`. Code that relies on `instanceof` checks breaks with decorators. Solution: check for the interface type, not the concrete class.

2. **Decorator ordering bugs:** If caching wraps logging, you don't see cache hits in logs. If logging wraps caching, every cache hit is logged. The "correct" order depends on requirements but is not enforced by the type system.

3. **Stack depth:** With 5 decorators, every method call traverses 5 stack frames. In high-throughput systems (100K+ calls/sec), this adds measurable latency. Profile before and after.

4. **Interface bloat:** If the component interface has 20 methods, every decorator must implement all 20 (delegating most). This is tedious and error-prone. Use abstract base decorators that delegate everything, then override specific methods.

5. **Spring proxy conflicts:** Spring already proxies beans for `@Transactional`, `@Cacheable`, etc. Wrapping a proxied bean in a manual Decorator can create confusing double-proxying. Use Spring's AOP consistently instead of mixing approaches.
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

# Proxy

**TL;DR** - Proxy provides a surrogate or placeholder for another object to control access to it, adding behavior like lazy loading, caching, or access control.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your application loads a high-resolution image gallery. Each image is 50MB. Loading all 100 images at startup consumes 5GB of memory and takes 30 seconds. The user only views 3-4 images per session. 96% of the loaded data is wasted.

**THE BREAKING POINT:**
Adding access control means modifying the image loading code directly. Adding caching means another modification. Each cross-cutting concern pollutes the core logic.

**THE INVENTION MOMENT:**
"This is exactly why Proxy was created."

**EVOLUTION:**
The GoF described several proxy types in 1994: virtual (lazy loading), protection (access control), remote (network access). Java's `java.lang.reflect.Proxy` and Spring's AOP proxies are language/framework-level implementations. Modern usage includes Hibernate's lazy-loading proxies, API gateway proxies, and service mesh sidecar proxies.
---

### 📘 Textbook Definition

Proxy is a structural design pattern that provides a substitute or placeholder for another object. A proxy controls access to the original object, allowing you to perform something either before or after the request reaches the original object.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
A stand-in that controls access to the real object.

**One analogy:**

> A celebrity's personal assistant. Fans don't talk to the celebrity directly. The assistant screens requests, schedules meetings, and filters out spam. The assistant provides the same "communication" interface but adds access control.

**One insight:**
Proxy and Decorator look identical in structure (both wrap an object with the same interface). The difference is intent: Decorator adds behavior, Proxy controls access. A caching proxy decides WHETHER to call the real object. A logging decorator ALWAYS calls the real object and adds logging.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Proxy implements the same interface as the real subject
2. Proxy controls access to the real subject
3. The client doesn't know it's talking to a proxy

**DERIVED DESIGN:**
The proxy holds a reference to the real subject. It intercepts calls and can: defer creation (virtual proxy), check permissions (protection proxy), add caching (caching proxy), or handle remote communication (remote proxy). The real subject is created or accessed only when needed.

**THE TRADE-OFFS:**
**Gain:** Lazy initialization, access control, caching, remote access transparency
**Cost:** Added latency from proxy layer, complexity in debugging (which object is actually called?), potential for proxy chain confusion

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Controlling access requires interception - some proxy-like mechanism is unavoidable
**Accidental:** Java's reflection-based dynamic proxies are slow compared to compile-time generated proxies (like those from ByteBuddy or AspectJ)
---

### 🧠 Mental Model / Analogy

> Think of Proxy as an ATM machine. The bank vault holds your money (real subject). The ATM (proxy) provides the same withdrawal interface but adds: authentication (PIN check), balance verification, transaction logging, and withdrawal limits - all before touching the vault.

- "ATM" -> proxy
- "Bank vault" -> real subject
- "PIN check" -> protection proxy behavior
- "Same withdrawal interface" -> shared interface

Where this analogy breaks down: ATMs are physically separate from vaults; in software, proxies and real subjects often exist in the same process.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
A proxy is a stand-in. Instead of talking to the real thing directly, you talk to a representative that decides how and when to involve the real thing.

**Level 2 - How to use it (junior developer):**
Common proxy types: **Virtual Proxy** - creates expensive objects only when first accessed (Hibernate lazy loading). **Protection Proxy** - checks permissions before allowing access. **Caching Proxy** - returns cached results for repeated requests. **Remote Proxy** - represents an object on another server (RMI, gRPC stubs).

**Level 3 - How it works (mid-level engineer):**
Java provides two proxy mechanisms: (1) **Static proxy** - you write a class that implements the interface and delegates. Simple but requires a class per subject. (2) **Dynamic proxy** - `java.lang.reflect.Proxy.newProxyInstance()` creates a proxy at runtime using reflection. All method calls go through an `InvocationHandler`. Spring uses CGLIB or JDK dynamic proxies for `@Transactional`, `@Cacheable`, and `@Async`. CGLIB creates a subclass of the target (works without interfaces); JDK proxy requires an interface.

**Level 4 - Mastery (senior/staff+ engineer):**
In Spring, every `@Transactional` bean is a proxy. This has critical implications: (1) **Self-invocation doesn't trigger the proxy** - calling `this.method()` bypasses the proxy, so `@Transactional` on the called method is ignored. (2) **Private methods can't be proxied** (CGLIB limitation). (3) **Final classes can't be proxied** (CGLIB can't subclass them). Understanding proxy mechanics is essential for debugging "why isn't my @Transactional working?" issues. In distributed systems, service mesh sidecars (Envoy, Istio) are network-level proxies: they intercept traffic, add mTLS, retry, and circuit breaking without modifying application code.




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
[Client] -> [Proxy (same interface)]
               |
          [Access control check]
               |
          [Cache lookup]
               |  cache miss
               v
          [Real Subject.method()]
               |
          [Cache result]
               |
          [Return to client]
```

Types of proxy behavior:

- Virtual: create real subject on first call
- Protection: check permissions before delegating
- Caching: return cached result if available
- Remote: serialize call, send over network
- Logging: record call details around delegation
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
[Client] -> [Proxy.operation() <- YOU ARE HERE]
  -> [Check access / cache / lazy init]
  -> [RealSubject.operation()]
  -> [Post-processing (cache, log)]
  -> [Return result to client]
```

**FAILURE PATH:**

```
[Proxy self-invocation in Spring]
  -> [this.method() bypasses proxy]
  -> [@Transactional/@Cacheable silently ignored]
  -> [Data inconsistency or performance issue]
  -> [Fix: inject self or extract to separate bean]
```

**WHAT CHANGES AT SCALE:**
At scale, proxy chains (API gateway -> service mesh -> application proxy) add latency at each layer. Each proxy adds 0.1-1ms. With 5 proxy layers, that's 0.5-5ms per call - significant at thousands of requests per second. Monitor proxy overhead separately from business logic.
---

### 💻 Code Example

**Example 1 - BAD: Eagerly loading expensive resources**

```java
// BAD: All images loaded on construction
public class ImageGallery {
    private final List<Image> images;

    public ImageGallery(List<String> paths) {
        // Loads 100 images (5GB) at startup
        images = paths.stream()
            .map(Image::loadFromDisk)
            .toList();
    }
}
```

**Example 2 - GOOD: Virtual proxy (lazy loading)**

```java
// GOOD: Proxy loads image only when displayed
public interface Image {
    void display();
    int getWidth();
}

public class LazyImageProxy implements Image {
    private final String path;
    private Image realImage;  // null until needed

    public LazyImageProxy(String path) {
        this.path = path;  // No I/O here
    }

    private Image getRealImage() {
        if (realImage == null) {
            realImage = RealImage.loadFromDisk(path);
        }
        return realImage;
    }

    @Override
    public void display() {
        getRealImage().display();  // Load on first use
    }

    @Override
    public int getWidth() {
        return getRealImage().getWidth();
    }
}

// Gallery holds 100 proxies (lightweight)
// Only 3-4 real images loaded when displayed
```

**How to test / verify correctness:**
Verify that the real subject is not created until first access. Verify that subsequent accesses reuse the same instance. Test thread safety if proxies are shared.
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

1. Proxy controls access; Decorator adds behavior - same structure, different intent
2. Spring's `@Transactional` uses proxies - self-invocation bypasses them (most common debugging issue)
3. Types: virtual (lazy), protection (security), caching, remote (network)

**Interview one-liner:**
"Proxy provides a surrogate that controls access to the real object - in Spring, I'm aware that AOP proxies mean self-invocation bypasses @Transactional, which is the most common gotcha in enterprise Java."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Hibernate's lazy loading, which has caused more `LazyInitializationException` bugs than any other feature, is a Proxy pattern implementation. Hibernate generates a CGLIB proxy subclass of your entity. The proxy holds only the entity ID. When you access any field, the proxy triggers a database query. This is elegant in theory but dangerous in practice: accessing a lazy field outside a transaction throws an exception, and N+1 query problems occur when iterating collections of proxied entities. Understanding that "it's just a proxy" makes the entire behavior predictable.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Proxy. Otherwise remove this section.]
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

**Q1: Why does `@Transactional` not work when calling a method from within the same class?**

_Why they ask:_ Tests understanding of Spring proxy mechanics - a critical production skill.

**Answer:**
Spring implements `@Transactional` using proxies. When you inject `UserService`, you actually get a proxy that wraps the real `UserService`. The proxy intercepts calls and manages transactions.

When `methodA()` calls `this.methodB()` within the same class, `this` refers to the real object, not the proxy. The call bypasses the proxy entirely, so `@Transactional` on `methodB()` is never activated.

```java
@Service
public class UserService {
    @Transactional
    public void methodA() {
        // this.methodB() bypasses proxy!
        this.methodB(); // NO transaction for B
    }

    @Transactional(propagation = REQUIRES_NEW)
    public void methodB() {
        // Expected new transaction, but runs
        // in A's transaction (or none)
    }
}
```

Solutions:

1. **Extract to separate bean:** Move `methodB()` to a different `@Service`. Injection goes through the proxy.
2. **Self-injection:** Inject the bean into itself (`@Lazy private UserService self;`) and call `self.methodB()`.
3. **`AopContext.currentProxy()`:** Access the proxy programmatically (requires `exposeProxy=true` in config).

I prefer option 1 because it's the cleanest and most maintainable.

---

**Q2: Compare JDK Dynamic Proxy vs CGLIB Proxy in Spring.**

_Why they ask:_ Tests understanding of Spring's proxy implementation details.

**Answer:**
| Aspect | JDK Dynamic Proxy | CGLIB Proxy |
| -------------- | ------------------------ | ------------------------- |
| Mechanism | Implements interfaces | Creates subclass |
| Requirement | Bean must have interface | No interface needed |
| Final classes | N/A (uses interface) | Cannot proxy |
| Final methods | N/A | Cannot intercept |
| Performance | Faster creation | Faster invocation |
| Spring default | When interface exists | Spring Boot default |

Spring Boot 2.x+ defaults to CGLIB even when interfaces exist (configurable via `spring.aop.proxy-target-class`). CGLIB creates a subclass at runtime using bytecode generation, which is why `final` classes and methods can't be proxied.

In practice, the choice rarely matters for application developers. It matters when: (1) you have `final` service classes (CGLIB fails), (2) you're doing `instanceof` checks (CGLIB proxy is a subclass; JDK proxy is not), (3) you're optimizing startup time (JDK proxies are faster to create).
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

# Facade

**TL;DR** - Facade provides a simplified interface to a complex subsystem, reducing the learning curve and decoupling clients from internal complexity.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your application needs to process a video: decode the source, apply filters, adjust audio levels, encode to target format, and write to disk. Each step uses a different library with its own API: `FFmpegDecoder`, `FilterEngine`, `AudioProcessor`, `H264Encoder`, `DiskWriter`. Every client that processes video must learn 5 APIs, handle 5 initialization sequences, and manage 5 error types.

**THE BREAKING POINT:**
Three different teams write video processing code. Each team sequences the steps differently. One team forgets to close the decoder, causing memory leaks. Another team applies filters before decoding, crashing the application.

**THE INVENTION MOMENT:**
"This is exactly why Facade was created."

**EVOLUTION:**
The GoF formalized Facade in 1994 as one of the simplest patterns. Java's `javax.faces` (JSF) is named after this pattern. Modern usage includes Spring's `JdbcTemplate` (facade over raw JDBC), REST API controllers (facade over business logic), and SDK client libraries (facade over raw HTTP APIs).
---

### 📘 Textbook Definition

Facade is a structural design pattern that provides a simplified interface to a library, framework, or complex set of classes. It defines a higher-level interface that makes the subsystem easier to use by wrapping complexity behind a cohesive API.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
A simple front door to a complex system.

**One analogy:**

> A hotel concierge. Instead of booking restaurants, arranging transport, and finding attractions yourself (dealing with each service directly), you tell the concierge what you want and they handle everything. One person, many services behind them.

**One insight:**
Facade doesn't add functionality - it simplifies access. The subsystem classes still exist and are still usable directly. Facade provides a shortcut for the 80% common use case while leaving the 20% of complex scenarios to direct subsystem access.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Facade provides a simplified interface to a complex subsystem
2. Facade does not hide the subsystem - direct access remains possible
3. Facade coordinates subsystem interactions on behalf of the client

**DERIVED DESIGN:**
The facade knows which subsystem classes to invoke and in what order. It translates client requests into the correct sequence of subsystem calls. The subsystem classes have no knowledge of the facade - the dependency is one-directional.

**THE TRADE-OFFS:**
**Gain:** Reduced complexity for clients, decoupling from subsystem internals, consistent usage patterns
**Cost:** Can become a god object if too many responsibilities are added, may limit access to advanced features

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Complex subsystems exist for good reasons - someone must orchestrate them
**Accidental:** The orchestration logic could be in a library, a script, or inline - Facade just formalizes it
---

### 🧠 Mental Model / Analogy

> Think of a car ignition system. Turning the key (facade) triggers a complex sequence: battery engages starter motor, fuel pump activates, spark plugs fire, engine turns over, onboard computer initializes. You don't interact with each subsystem. The key is your facade.

- "Turning the key" -> facade method call
- "Battery, fuel pump, spark plugs" -> subsystem classes
- "Correct sequence" -> facade coordinates order
- "Driver doesn't need to know internals" -> simplified interface

Where this analogy breaks down: Car ignition is a single operation; Facades typically expose multiple methods covering different use cases.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Facade gives you one simple button to do something complicated. Instead of pressing 10 buttons in the right order, you press one.

**Level 2 - How to use it (junior developer):**
Create a class with simple methods that coordinate complex subsystem calls. Spring's `JdbcTemplate` is a facade over JDBC: instead of managing `Connection`, `PreparedStatement`, `ResultSet`, and exception handling yourself, you call `template.query(sql, mapper)`.

**Level 3 - How it works (mid-level engineer):**
Facade is the simplest structural pattern. It has no special mechanisms - it's just a well-designed API wrapper. The value is in deciding what to expose and what to hide. A good facade exposes the 80% use case simply and provides escape hatches for the 20% that needs direct subsystem access. In layered architectures, each layer is a facade for the layers below it: Controller -> Service -> Repository -> Database.

**Level 4 - Mastery (senior/staff+ engineer):**
The danger of Facade is becoming a god object. If your `OrderFacade` has 30 methods touching 15 subsystems, it's no longer simplifying - it's centralizing. The fix: one facade per use case or bounded context. In microservices, the API Gateway is a system-level facade: it presents a unified API to external clients while routing to internal services. BFF (Backend for Frontend) is a client-specific facade. The key architectural decision: facade should be thin (orchestration only, no business logic) or it becomes a maintenance bottleneck.




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
[Client] --> [Facade]
                |
    +-----------+-----------+
    |           |           |
[Subsystem A] [Subsystem B] [Subsystem C]

Facade.processVideo(input, output):
  1. decoder = SubsystemA.decode(input)
  2. filtered = SubsystemB.applyFilters(decoder)
  3. encoded = SubsystemC.encode(filtered)
  4. write(encoded, output)
  5. cleanup(decoder, filtered, encoded)
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
[Client] -> [Facade.simpleMethod() <- YOU ARE HERE]
  -> [SubsystemA.init()]
  -> [SubsystemB.process()]
  -> [SubsystemC.finalize()]
  -> [Result returned to client]
```

**FAILURE PATH:**

```
[SubsystemB.process() fails]
  -> [Facade must rollback SubsystemA]
  -> [Facade must clean up resources]
  -> [Client receives single, clear error]
```

**WHAT CHANGES AT SCALE:**
At scale, facades often become the bottleneck point for adding new features. Every new requirement goes through the facade, which grows endlessly. Split facades by domain or use case before they exceed 10-15 methods.
---

### 💻 Code Example

**Example 1 - BAD: Client manages complex subsystem directly**

```java
// BAD: Every client must know the sequence
public class OrderProcessor {
    public void process(Order order) {
        var inv = new InventorySystem();
        inv.connect();
        inv.checkStock(order.getItems());

        var pay = new PaymentGateway();
        pay.initialize(order.getPaymentMethod());
        pay.authorize(order.getTotal());

        var ship = new ShippingService();
        ship.calculateRate(order.getAddress());
        ship.createShipment(order);

        // What if payment fails AFTER inventory
        // was reserved? Manual cleanup needed.
        inv.disconnect();
    }
}
```

**Example 2 - GOOD: Facade coordinates subsystems**

```java
// GOOD: Simple interface, complex coordination
public class OrderFacade {
    private final InventorySystem inventory;
    private final PaymentGateway payment;
    private final ShippingService shipping;

    public OrderFacade(InventorySystem inv,
            PaymentGateway pay, ShippingService ship) {
        this.inventory = inv;
        this.payment = pay;
        this.shipping = ship;
    }

    public OrderResult processOrder(Order order) {
        // Facade handles sequencing and cleanup
        inventory.reserve(order.getItems());
        try {
            var payResult = payment.charge(
                order.getTotal());
            var shipment = shipping.create(order);
            return OrderResult.success(
                payResult, shipment);
        } catch (PaymentException e) {
            inventory.release(order.getItems());
            throw new OrderFailedException(
                "Payment failed", e);
        }
    }
}

// Client code: simple and clean
var result = orderFacade.processOrder(order);
```

**How to test / verify correctness:**
Mock all subsystems and verify the facade calls them in the correct order. Test error handling by making each subsystem throw and verifying cleanup happens.
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

1. Facade simplifies a complex subsystem behind a clean interface
2. It doesn't hide the subsystem - direct access is still available for advanced cases
3. Don't let it become a god object - split by domain when it grows beyond 10-15 methods

**Interview one-liner:**
"Facade provides a simplified interface to a complex subsystem - like Spring's JdbcTemplate wrapping raw JDBC - I use it to give clients a clean 80% API while keeping full subsystem access available for the 20% of advanced cases."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Every REST API controller is a Facade. It presents a simplified HTTP interface to complex business logic, database operations, and external service calls. Most developers create facades daily without recognizing the pattern. The pattern is so natural that it's invisible - which is actually the highest compliment to a design pattern.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Facade. Otherwise remove this section.]
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

**Q1: How do you decide what goes in a Facade vs what stays in the subsystem?**

_Why they ask:_ Tests API design judgment.

**Answer:**
My heuristic: the facade exposes use cases, not capabilities.

- **In the facade:** Operations that clients actually perform. `orderFacade.processOrder()`, `orderFacade.cancelOrder()`. These are complete workflows.
- **In the subsystem:** Granular operations that the facade orchestrates. `inventory.reserve()`, `payment.charge()`. These are building blocks.

The test: if a client needs to call two facade methods in sequence to accomplish one task, the facade is too granular. If a facade method has conditional logic based on the caller's needs, it's trying to serve too many use cases - split it.

---

**Q2: What's the difference between Facade and API Gateway?**

_Why they ask:_ Tests ability to connect code patterns to distributed architecture.

**Answer:**
An API Gateway is a Facade at the network level. The concepts map directly:

| Aspect      | Facade (in-process)           | API Gateway (network)        |
| ----------- | ----------------------------- | ---------------------------- |
| Clients     | Classes in the application    | External clients/apps        |
| Subsystem   | Internal classes/modules      | Internal microservices       |
| Protocol    | Method calls                  | HTTP/gRPC                    |
| Added value | Orchestration, simplification | Routing, auth, rate limiting |
| Examples    | Spring `JdbcTemplate`         | Kong, AWS API Gateway        |

Both simplify access to complex internals. The API Gateway adds network concerns (TLS termination, load balancing, request transformation) that don't exist in an in-process Facade.
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

# Composite

**TL;DR** - Composite lets you compose objects into tree structures and treat individual objects and compositions uniformly through a shared interface.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your file system browser needs to calculate the size of a directory. A directory contains files and other directories. Files have a fixed size. A directory's size is the sum of everything it contains, recursively. Without a uniform interface, you need `if (item instanceof File) ... else if (item instanceof Directory) ...` at every operation site. Every new operation (delete, search, display) needs the same conditional.

**THE BREAKING POINT:**
A new requirement: symbolic links (which can point to files or directories). The `instanceof` chain grows. Some operations need to follow links, others don't. The conditional logic becomes the largest source of bugs.

**THE INVENTION MOMENT:**
"This is exactly why Composite was created."

**EVOLUTION:**
The GoF formalized Composite in 1994. It's fundamental to GUI frameworks (Swing's `JComponent`, JavaFX's `Node`), XML/HTML DOM trees, and expression parsers. React's component tree is a Composite: `<App>` contains `<Header>`, which contains `<Nav>`, which contains `<Link>`s. Each can be rendered uniformly.
---

### 📘 Textbook Definition

Composite is a structural design pattern that lets you compose objects into tree structures to represent part-whole hierarchies. Composite lets clients treat individual objects (leaves) and compositions (nodes) uniformly through a common interface.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Treat single objects and groups of objects the same way.

**One analogy:**

> Military organization. An army general gives an order. The order flows down: to divisions, to brigades, to battalions, to individual soldiers. A division doesn't execute the order itself - it passes it to its components. An individual soldier executes it. The same "execute order" interface works at every level.

**One insight:**
Composite eliminates the distinction between "one" and "many." When you can treat a single file and an entire directory tree with the same interface, every algorithm that works on one works on the other. This is the power of recursive composition.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Leaf nodes and composite nodes share the same interface
2. Composite nodes hold children and delegate operations to them
3. The structure forms a tree (part-whole hierarchy)

**DERIVED DESIGN:**
A common interface declares operations like `getSize()`, `print()`, or `execute()`. Leaf nodes implement the operation directly. Composite nodes iterate over their children and aggregate results. Since composites and leaves share the interface, composites can contain other composites - enabling recursive trees of arbitrary depth.

**THE TRADE-OFFS:**
**Gain:** Uniform treatment of simple and complex structures, easy to add new component types, recursive operations are natural
**Cost:** Type safety is weakened (leaf operations like `add()` don't make sense), can make design overly general

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Tree structures require recursive traversal - this is inherent to the data structure
**Accidental:** The debate about whether `add(child)` should be in the base interface or only in Composite nodes is a language limitation
---

### 🧠 Mental Model / Analogy

> Think of a Russian nesting doll (Matryoshka) family tree. Each doll either contains other dolls (composite) or is the smallest doll (leaf). When you paint all dolls, you paint the outer one, then recursively paint everything inside. "Paint all" works whether you have one doll or a hundred nested ones.

- "Outer doll" -> composite node
- "Smallest doll" -> leaf node
- "Paint all" -> uniform operation
- "Contains others" -> children collection

Where this analogy breaks down: Matryoshka are strictly linear (one inside another); Composite supports branching trees (one node containing multiple children).
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Composite lets you treat a group of things exactly like a single thing. A box can contain items or other boxes. You calculate the total weight the same way regardless.

**Level 2 - How to use it (junior developer):**
Create an interface with your operation (e.g., `getPrice()`). Leaf classes implement it directly (return their price). Composite classes hold a list of children and implement it by summing children's prices. You can nest composites arbitrarily deep.

**Level 3 - How it works (mid-level engineer):**
The pattern has a design tension: should `add(child)` / `remove(child)` be in the base interface or only in composites? GoF put it in the base interface for maximum uniformity (leaves throw `UnsupportedOperationException`). Modern practice puts it only in the Composite class for type safety. In practice, Composite appears in: UI component trees, organization charts, menu systems, expression parsers (AST), and build dependency graphs.

**Level 4 - Mastery (senior/staff+ engineer):**
Composite is the foundation of the Interpreter pattern (ASTs), the Visitor pattern (traversing composite structures), and recursive descent parsers. In React, the entire virtual DOM is a Composite tree. In Spring Security, `AuthenticationManager` uses Composite: `ProviderManager` holds a list of `AuthenticationProvider`s and tries each one. The pattern is most powerful when combined with Visitor (separate operations from structure) or Iterator (standardize traversal). Watch for performance: naive recursive operations on deep trees can overflow the stack. Use iterative traversal with an explicit stack for production trees deeper than ~1000 levels.




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
[FileSystem Component]
        |
  +-----+-----+
  |           |
[File]    [Directory]
(leaf)    (composite)
             |
    +--------+--------+
    |        |        |
  [File]  [File]  [Directory]
                     |
                  [File]

getSize():
  File -> return this.size
  Directory -> children.sum(c -> c.getSize())
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
[Client] -> [root.getSize() <- YOU ARE HERE]
  -> [dir1.getSize()]
     -> [file1.getSize()] = 100
     -> [file2.getSize()] = 200
     = 300
  -> [dir2.getSize()]
     -> [file3.getSize()] = 150
     = 150
  = 450 (total)
```

**FAILURE PATH:**

```
[Circular reference: dir1 contains dir2,
 dir2 contains dir1]
  -> [Infinite recursion]
  -> [StackOverflowError]
  -> [Fix: cycle detection during add()]
```

**WHAT CHANGES AT SCALE:**
With millions of nodes, recursive `getSize()` is slow. Solutions: cache computed values at each composite node, invalidate on child changes (observer pattern), or use lazy evaluation. UI frameworks like React solve this with virtual DOM diffing - only recompute changed subtrees.
---

### 💻 Code Example

**Example 1 - BAD: Type-checking everywhere**

```java
// BAD: instanceof checks for every operation
public int calculatePrice(Object item) {
    if (item instanceof Product p) {
        return p.getPrice();
    } else if (item instanceof Bundle b) {
        int total = 0;
        for (Object child : b.getItems()) {
            total += calculatePrice(child); // Recursion
        }
        return total;
    }
    throw new IllegalArgumentException();
}
```

**Example 2 - GOOD: Composite pattern**

```java
// GOOD: Uniform interface, no type checking
public interface PricedItem {
    int getPrice();
    String getName();
}

public class Product implements PricedItem {
    private final String name;
    private final int price;

    public Product(String name, int price) {
        this.name = name;
        this.price = price;
    }

    public int getPrice() { return price; }
    public String getName() { return name; }
}

public class Bundle implements PricedItem {
    private final String name;
    private final List<PricedItem> items =
        new ArrayList<>();

    public Bundle(String name) {
        this.name = name;
    }

    public void add(PricedItem item) {
        items.add(item);
    }

    public int getPrice() {
        return items.stream()
            .mapToInt(PricedItem::getPrice)
            .sum();
    }

    public String getName() { return name; }
}

// Usage: compose freely
var bundle = new Bundle("Gaming Setup");
bundle.add(new Product("Monitor", 500));
bundle.add(new Product("Keyboard", 100));
var subBundle = new Bundle("Peripherals");
subBundle.add(new Product("Mouse", 50));
subBundle.add(new Product("Mousepad", 20));
bundle.add(subBundle);
// bundle.getPrice() = 670 (recursive sum)
```

**How to test / verify correctness:**
Test leaf nodes return their value directly. Test composites with one level of children. Test deep nesting (3+ levels). Test empty composites return zero/identity. Test that adding/removing children updates results.
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

1. Composite lets you treat individual objects and collections uniformly
2. It creates tree structures where operations recurse naturally
3. Watch for circular references (infinite recursion) and deep trees (stack overflow)

**Interview one-liner:**
"Composite composes objects into tree structures and lets clients treat leaves and branches uniformly - I've used it in menu systems, org hierarchies, and anywhere a part-whole relationship needs recursive operations."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

React's entire rendering model is a Composite pattern. Every React component is either a leaf (renders HTML) or a composite (renders other components). The `render()` method is the uniform interface. JSX syntax (`<Parent><Child/></Parent>`) is just syntactic sugar for building a Composite tree. The virtual DOM diffing algorithm is a Composite tree traversal. Understanding this makes React's reconciliation algorithm, `shouldComponentUpdate`, and `React.memo` immediately understandable.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Composite. Otherwise remove this section.]
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

**Q1: Where does Composite appear in the Java standard library?**

_Why they ask:_ Tests awareness of patterns in existing frameworks.

**Answer:**
Several places:

1. **`java.awt.Component` / `java.awt.Container`:** `Container` extends `Component` and holds child `Component`s. Paint, layout, and event handling propagate through the tree.

2. **`javax.swing.JComponent`:** Same tree structure. `JPanel` contains `JButton`, `JLabel`, etc. `repaint()` recurses through children.

3. **`java.io.File`:** A file system node that can be a file (leaf) or directory (composite). `listFiles()` returns children. `length()` returns size (for files) - though it doesn't recursively sum directory sizes automatically.

4. **`org.w3c.dom.Node`:** XML DOM tree. `Element` contains child `Node`s. Operations like `getTextContent()` recurse through children.

5. **`java.util.Map.Entry`:** In `TreeMap`, entries form a tree structure that's a Composite internally.

The pattern is so fundamental to UI and document processing that it's the default data structure for hierarchical information.

---

**Q2: How would you implement a permission system using Composite?**

_Why they ask:_ Tests ability to apply the pattern to real business problems.

**Answer:**

```java
public interface Permission {
    boolean hasAccess(String resource, String action);
}

// Leaf: single permission rule
public class SimplePermission implements Permission {
    private final String resource;
    private final Set<String> actions;

    public boolean hasAccess(String res, String act) {
        return resource.equals(res)
            && actions.contains(act);
    }
}

// Composite: role with multiple permissions
public class Role implements Permission {
    private final List<Permission> permissions =
        new ArrayList<>();

    public void add(Permission p) {
        permissions.add(p);
    }

    public boolean hasAccess(String res, String act) {
        return permissions.stream()
            .anyMatch(p -> p.hasAccess(res, act));
    }
}
```

A `Role` can contain `SimplePermission`s and other `Role`s (role inheritance). `admin.hasAccess("users", "delete")` checks all nested permissions recursively. This models how RBAC actually works in enterprise systems.
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
