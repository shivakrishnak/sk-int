---
layout: default
title: "Design Patterns - Creational"
parent: "Design Patterns"
grand_parent: "Interview Mastery"
nav_order: 1
permalink: /interview/design-patterns/creational/
topic: Design Patterns
subtopic: Creational
keywords:
  - Singleton
  - Factory Method
  - Abstract Factory
  - Builder
  - Prototype
difficulty_range: mixed
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Singleton](#singleton)
- [Factory Method](#factory-method)
- [Abstract Factory](#abstract-factory)
- [Builder](#builder)
- [Prototype](#prototype)

# Singleton

**TL;DR** - Singleton ensures a class has exactly one instance and provides a global access point to it, solving uncontrolled instantiation of shared resources.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every time your application needs a database connection pool, a logger, or a configuration manager, a new instance is created. Ten threads create ten connection pools, each opening 50 connections. The database server hits its connection limit of 100 within seconds. Memory usage spikes. Objects that should share state maintain separate, inconsistent copies.

**THE BREAKING POINT:**
Two configuration objects load the same file but one gets modified at runtime. Half the application sees the old config, half sees the new one. Bugs appear that are impossible to reproduce because they depend on which instance was used.

**THE INVENTION MOMENT:**
"This is exactly why Singleton was created."

**EVOLUTION:**
The GoF formalized it in 1994, but the concept existed in Smalltalk before that. Early implementations used eager initialization. Java's memory model issues led to the double-checked locking debate. Modern implementations use enum-based singletons (Java) or module-level instances (Python). The pattern has become controversial - many now consider it an anti-pattern when overused, preferring dependency injection for testability.
---

### 📘 Textbook Definition

Singleton is a creational design pattern that restricts the instantiation of a class to exactly one object. It provides a global point of access to that instance. The class itself is responsible for keeping track of its sole instance and ensuring that no other instance can be created.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
One instance, one access point, guaranteed by the class itself.

**One analogy:**

> A country has exactly one president at any time. You don't create a new president when you need one - you access the existing one through an established channel (the office). The office ensures there's always exactly one.

**One insight:**
The key insight is not "only one instance" - it's "controlled access to shared state." The real value is coordination. When you need a single source of truth that multiple components access, Singleton provides the guarantee. The danger is when you use it as a glorified global variable.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Exactly one instance exists during the application lifecycle
2. The instance is globally accessible
3. The class controls its own instantiation (self-regulated)

**DERIVED DESIGN:**
The constructor must be private (preventing external `new`). A static method provides the access point. The instance is stored as a static field. Thread safety must be explicitly handled in concurrent environments because the "check if null, then create" operation is not atomic.

**THE TRADE-OFFS:**
**Gain:** Guaranteed single instance, controlled access to shared resources, lazy initialization possible
**Cost:** Global state (harder to test), hidden dependencies, tight coupling, concurrency complexity

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Ensuring exactly one instance in a concurrent environment requires synchronization - no implementation avoids this
**Accidental:** The testability problems come from the pattern conflating "single instance" with "global access" - DI containers solve this by managing the lifecycle externally
---

### 🧠 Mental Model / Analogy

> Think of Singleton as a government-issued ID office. There is only one office in your district. Everyone must go to the same office. The office controls who gets served and when. You can't build your own ID office.

- "One office" -> one instance
- "Everyone goes there" -> global access point
- "Can't build your own" -> private constructor
- "Office controls access" -> thread-safe getInstance()

Where this analogy breaks down: Unlike a government office, Singleton doesn't queue requests - concurrent access happens simultaneously and must be synchronized.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Singleton is a rule that says: "There can be only one." When your program needs a shared resource like a printer manager, Singleton ensures everyone uses the same manager instead of creating their own separate ones.

**Level 2 - How to use it (junior developer):**
Make the constructor private. Create a static method called `getInstance()` that returns the single instance. The first call creates it; subsequent calls return the same object. Use it for connection pools, loggers, and configuration managers. Never put mutable business state in a Singleton.

**Level 3 - How it works (mid-level engineer):**
Thread safety is the critical concern. Naive implementations break under concurrent access:

- **Eager initialization:** Instance created at class loading time. Safe but wastes memory if never used.
- **Synchronized method:** Thread-safe but slow - every call pays the synchronization cost.
- **Double-checked locking:** Check null, synchronize, check null again. Requires `volatile` in Java to prevent instruction reordering.
- **Enum singleton (Java):** JVM guarantees single instance, handles serialization, and prevents reflection attacks. Considered the gold standard.
- **Bill Pugh (holder pattern):** Uses a static inner class. Lazy, thread-safe, no synchronization overhead.

**Level 4 - Mastery (senior/staff+ engineer):**
Singleton is the most misused pattern. The real question isn't "how to implement it" but "should you use it at all?" In modern applications, dependency injection containers manage object lifecycles. Spring's `@Scope("singleton")` is the default bean scope - it provides Singleton semantics without the testability problems. The pattern becomes an anti-pattern when: (1) it's used to avoid passing dependencies, (2) it holds mutable business state, (3) it makes unit testing require complex workarounds. In distributed systems, "singleton per JVM" is meaningless - you need distributed locks or leader election for true system-wide singletons. The enum approach in Java survives serialization, reflection, and cloning attacks - all of which break naive implementations.




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
Thread A calls getInstance()     Thread B calls
  |                               getInstance()
  v                                  |
[Check: instance == null?]           v
  | YES                    [Check: instance == null?]
  v                          | YES (race condition!)
[Synchronized block]         v
  |                    [Blocked - waiting for lock]
  v                          |
[Create instance]            |
[Release lock]               v
  |                    [Synchronized block]
  v                    [Check again: null? NO]
[Return instance] <--- [Return same instance]
```

The double-checked locking pattern:

1. First check without synchronization (fast path)
2. Synchronize only if instance might be null
3. Second check inside synchronized block
4. `volatile` prevents seeing partially constructed object
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
[App starts] -> [Class loaded]
  -> [getInstance() called <- YOU ARE HERE]
  -> [Instance created (once)]
  -> [Same instance returned to all callers]
  -> [App shuts down] -> [Instance garbage collected]
```

**FAILURE PATH:**

```
[Two threads call getInstance() simultaneously]
  -> [Without proper sync: two instances created]
  -> [Different parts of app use different instances]
  -> [Inconsistent state, subtle bugs]
```

**WHAT CHANGES AT SCALE:**
In a distributed system, each JVM has its own Singleton. With 50 microservice instances, you have 50 "singletons." True global uniqueness requires distributed coordination (ZooKeeper, Redis-based locks, or database-backed leader election). At scale, the Singleton pattern shifts from a code pattern to an infrastructure pattern.
---

### 💻 Code Example

**Example 1 - BAD: Broken under concurrency**

```java
// BAD: Race condition - two threads can create
// two instances simultaneously
public class ConfigManager {
    private static ConfigManager instance;

    private ConfigManager() {
        // Load config from file (slow)
    }

    public static ConfigManager getInstance() {
        if (instance == null) {      // Thread A here
            // Thread B also enters here
            instance = new ConfigManager();
        }
        return instance;  // Different instances!
    }
}
```

**Example 2 - GOOD: Enum Singleton (Java gold standard)**

```java
// GOOD: Thread-safe, serialization-safe,
// reflection-safe - guaranteed by JVM
public enum ConfigManager {
    INSTANCE;

    private final Properties config = new Properties();

    ConfigManager() {
        try (var in = getClass()
                .getResourceAsStream("/app.properties")) {
            config.load(in);
        } catch (IOException e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    public String get(String key) {
        return config.getProperty(key);
    }
}

// Usage:
String dbUrl = ConfigManager.INSTANCE.get("db.url");
```

**Example 3 - GOOD: Bill Pugh / Holder pattern**

```java
// GOOD: Lazy, thread-safe, no synchronization
public class ConnectionPool {
    private ConnectionPool() {
        // Initialize pool
    }

    // Inner class not loaded until accessed
    private static class Holder {
        private static final ConnectionPool INSTANCE =
            new ConnectionPool();
    }

    public static ConnectionPool getInstance() {
        return Holder.INSTANCE;
    }
}
```

**How to test / verify correctness:**
Use a concurrent test with `CountDownLatch` to have N threads call `getInstance()` simultaneously, then assert all returned references are `==` (same object). For DI-managed singletons, verify scope in integration tests.
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

1. Enum singleton is the safest Java implementation - handles serialization, reflection, and threading
2. Singleton is about controlled access to shared state, not about saving memory
3. In modern apps, prefer DI container scoping over hand-coded Singletons

**Interview one-liner:**
"Singleton guarantees one instance per JVM with controlled access - I prefer enum implementation in Java for safety, but in Spring applications I rely on the container's singleton scope for testability."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Most developers think Singleton's purpose is memory savings. In reality, the GoF intended it for coordination - ensuring a single point of control. The irony is that in distributed systems, the pattern that guarantees "only one" actually creates "one per node," which is the opposite of its intent. This is why distributed singletons require entirely different mechanisms (leader election, distributed locks) that have nothing to do with the original pattern.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Singleton. Otherwise remove this section.]
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

**Q1: What are the different ways to implement Singleton in Java, and which do you recommend?**

_Why they ask:_ Tests depth of implementation knowledge and awareness of thread-safety concerns.

**Answer:**
There are five main approaches, each with distinct trade-offs:

1. **Eager initialization:** Instance created when class loads. Simple and thread-safe (JVM handles class loading synchronization), but wastes memory if the instance is never used.

2. **Synchronized `getInstance()`:** Thread-safe but every call pays synchronization overhead, even after the instance exists. Performance degrades under high concurrency.

3. **Double-checked locking:** Checks null without synchronization first (fast path), then synchronizes only on first creation. The `volatile` keyword is essential - without it, Java's memory model allows threads to see a partially constructed object due to instruction reordering.

4. **Bill Pugh (static inner holder class):** The inner class isn't loaded until `getInstance()` is called, giving lazy initialization. Thread safety is guaranteed by the JVM's class loading mechanism. No synchronization overhead on subsequent calls.

5. **Enum singleton:** My recommended approach. The JVM guarantees exactly one instance, handles serialization (returns the same instance on deserialization), prevents reflection-based attacks (`IllegalArgumentException` thrown if you try to reflectively construct), and is thread-safe by specification.

In production, I use enum for standalone singletons and Spring's `@Scope("singleton")` (the default) for managed beans. The DI approach gives you the "single instance" guarantee without the testability problems of static access.

---

**Q2: Why is Singleton considered an anti-pattern by many developers?**

_Why they ask:_ Tests critical thinking about design patterns and awareness of modern best practices.

**Answer:**
Singleton conflates two concerns: lifecycle management (one instance) and access mechanism (global static access). This conflation creates several problems:

**Testing:** Singleton state persists across tests. Test A modifies the Singleton, Test B gets contaminated. You end up writing `reset()` methods or using reflection to clear state between tests - both are code smells.

**Hidden dependencies:** When a class calls `DatabasePool.getInstance()`, that dependency is invisible in the constructor signature. You can't tell from the API what a class depends on. This makes refactoring dangerous.

**Tight coupling:** Every caller is coupled to the concrete Singleton class. You can't substitute a mock, a different implementation, or a test double without modifying the Singleton class itself (adding interfaces, factory methods, etc.).

**Concurrency assumptions:** Singleton assumes "one per process." In containerized deployments with multiple instances, "one per JVM" is not "one per system."

The solution isn't to avoid single instances - it's to separate the concern. A DI container can manage a single instance while still allowing constructor injection, making dependencies explicit and testable.

---

**Q3: How would you design a thread-safe Singleton that supports lazy initialization with minimal performance overhead?**

_Why they ask:_ Tests understanding of concurrency, memory models, and performance trade-offs.

**Answer:**
The Bill Pugh pattern is the optimal choice for lazy, thread-safe Singleton without synchronization overhead:

```java
public class ExpensiveService {
    private ExpensiveService() {
        // Heavy initialization
    }

    private static class Holder {
        static final ExpensiveService INSTANCE =
            new ExpensiveService();
    }

    public static ExpensiveService getInstance() {
        return Holder.INSTANCE;
    }
}
```

Why this works: The JVM specification guarantees that a class is not loaded until it's first referenced. `Holder` is only referenced when `getInstance()` is called. At that point, the JVM loads `Holder` and initializes its static field. Class initialization is guaranteed to be thread-safe by the JVM (it acquires a lock per class, so concurrent threads wait).

The result: lazy initialization (instance created only when needed), thread safety (guaranteed by JVM class loading), and zero synchronization overhead on subsequent calls (it's just a field read).

If the object needs to survive serialization, use the enum approach instead, since it automatically handles `readResolve()`.

---

**Q4: In a microservices architecture with 20 instances of the same service, how does Singleton behavior change?**

_Why they ask:_ Tests understanding of distributed systems and the limits of in-process patterns.

**Answer:**
Each JVM instance has its own Singleton - so you have 20 "singletons," which defeats the purpose if you need true system-wide uniqueness.

This matters for scenarios like:

- **Rate limiting:** If each instance has its own counter, a client can make 20x the intended limit
- **ID generation:** Each instance might generate colliding IDs
- **Leader election:** Only one instance should perform a scheduled task

Solutions depend on the coordination need:

1. **Distributed cache (Redis):** Use `SETNX` for distributed locks or atomic counters. The Singleton becomes a thin wrapper around a Redis client.

2. **Database-based:** Use `SELECT FOR UPDATE` or optimistic locking. Simple but adds database load.

3. **ZooKeeper/etcd:** Purpose-built for distributed coordination. Leader election via ephemeral nodes. More complex to operate but battle-tested.

4. **Kubernetes lease objects:** For leader election in K8s, use the `coordination.k8s.io/v1` Lease API. Spring Cloud Kubernetes has built-in support.

The key insight: Singleton is a process-level pattern. For system-level uniqueness, you need a distributed coordination primitive - and the design looks nothing like the GoF pattern.

---

**Q5: You're reviewing code that has 15 Singletons in a Spring Boot application. What's your recommendation?**

_Why they ask:_ Tests ability to identify anti-patterns and propose practical refactoring strategies.

**Answer:**
This is a red flag. In a Spring Boot application, every `@Component`, `@Service`, `@Repository`, and `@Controller` bean is already a singleton by default (Spring's singleton scope). Having 15 hand-coded Singletons means the developer is bypassing the DI container.

My audit approach:

1. **Categorize each Singleton:** Is it holding configuration, managing resources, or storing mutable state? Configuration and resource management are legitimate use cases; mutable state singletons are the dangerous ones.

2. **Check for `getInstance()` calls in Spring beans:** Any Spring bean calling `SomeSingleton.getInstance()` should be refactored to inject the dependency through the constructor.

3. **Identify testing friction:** If tests are failing intermittently or require `reset()` calls between test methods, Singleton state leakage is the likely cause.

4. **Refactoring plan:**
   - Convert each Singleton to a Spring bean with `@Component`
   - Replace `getInstance()` calls with constructor injection
   - Remove the static instance field and private constructor
   - If the Singleton is shared across non-Spring code, create a `@Bean` method in a `@Configuration` class
   - For third-party Singletons you can't modify, wrap them in a Spring bean

5. **Validate:** After conversion, ensure the application context has the expected bean count and that each former Singleton is created exactly once (verify with `@PostConstruct` logging or Actuator's `/beans` endpoint).

The goal isn't zero Singletons - it's zero hand-coded Singletons. Let the framework manage lifecycle.
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

# Factory Method

**TL;DR** - Factory Method defines an interface for creating objects but lets subclasses decide which class to instantiate, decoupling creation logic from usage code.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your logistics application ships products. Initially, everything goes by truck. Your `Logistics` class directly creates `Truck` objects everywhere: `new Truck()` appears in 47 places. Now the business wants to add sea freight. You need to touch all 47 locations, add conditionals, and test every code path. Every new transport type means modifying every creation site.

**THE BREAKING POINT:**
A new requirement for air freight arrives. The `if-else` chain in every creation site grows to three branches. A developer adds air freight to 46 of 47 locations. The 47th silently creates trucks for air shipments. The bug reaches production.

**THE INVENTION MOMENT:**
"This is exactly why Factory Method was created."

**EVOLUTION:**
Factory Method was formalized by the GoF in 1994 but the concept of virtual constructors existed in Smalltalk. Java's `Collection.iterator()` is a classic example - each collection returns its own iterator type. Modern usage includes static factory methods (Bloch's Effective Java), Spring's `FactoryBean`, and functional approaches where lambdas replace subclass hierarchies.
---

### 📘 Textbook Definition

Factory Method is a creational design pattern that defines an interface for creating an object but lets subclasses alter the type of objects that will be created. The pattern delegates instantiation to subclasses, enabling a class to defer object creation to its children while maintaining a uniform interface.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Let subclasses decide what to create while the parent defines how to use it.

**One analogy:**

> A restaurant menu says "Today's soup" without specifying which soup. Each chef (subclass) decides what soup to make. Customers (client code) just order "today's soup" - they don't care if it's tomato or mushroom.

**One insight:**
Factory Method isn't about factories - it's about the Open/Closed Principle. You can add new product types by creating new subclasses without modifying existing code. The creation decision moves from the caller to the hierarchy, making the system extensible at the type level.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. A method in the parent class returns an interface/abstract type
2. Subclasses override this method to return concrete types
3. Client code works with the interface, never the concrete type

**DERIVED DESIGN:**
The parent class defines the algorithm that uses the product. The "factory method" is the single point where the concrete type is chosen. This separates "what to do with an object" from "which object to create." New types require new subclasses, not modifications to existing code.

**THE TRADE-OFFS:**
**Gain:** Open/Closed Principle - add new types without modifying existing code; polymorphic creation
**Cost:** Class hierarchy grows (one subclass per product type); indirection makes debugging harder

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** You need some mechanism to map a creation decision to a concrete type - that mapping logic must exist somewhere
**Accidental:** The subclass explosion can be mitigated with parameterized factories or lambdas, but the core inheritance-based pattern requires it
---

### 🧠 Mental Model / Analogy

> Think of Factory Method as a franchise restaurant chain. Corporate headquarters (parent class) defines the menu, service process, and quality standards. Each franchise location (subclass) sources ingredients from local suppliers (creates specific products). Customers get the same experience everywhere, but the actual products differ by location.

- "Corporate headquarters" -> abstract creator class
- "Menu and standards" -> template method using the product
- "Local suppliers" -> concrete factory method returning specific type
- "Customer doesn't know the supplier" -> client uses interface

Where this analogy breaks down: In the pattern, the subclass relationship is fixed at compile time, while franchise locations can change suppliers dynamically.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Instead of writing `new SpecificThing()` everywhere, you call a method that creates the right thing for you. Different situations return different things, but your code doesn't need to know which one.

**Level 2 - How to use it (junior developer):**
Define an interface for your products (e.g., `Transport`). Create a base class with a method that returns `Transport` (the factory method). Each subclass overrides that method to return a specific type (`Truck`, `Ship`). Your code calls the factory method and works with the `Transport` interface.

**Level 3 - How it works (mid-level engineer):**
Factory Method is the intersection of inheritance and polymorphism applied to object creation. The creator class often has a template method that calls the factory method. For example, `Logistics.planDelivery()` calls `createTransport()` internally. Subclasses override `createTransport()` but not `planDelivery()`, giving you polymorphic creation within a fixed algorithm. In Java, `Collection.iterator()` is a factory method - `ArrayList` returns `ArrayList$Itr`, `HashSet` returns `HashMap$KeyIterator`.

**Level 4 - Mastery (senior/staff+ engineer):**
The classic GoF Factory Method using subclasses is now relatively rare in modern code. What survived and thrived are three variations: (1) Static factory methods (`List.of()`, `Optional.of()`) that control construction without subclassing, (2) Parameterized factories that use a discriminator parameter instead of subclasses, (3) Functional factories using `Supplier<T>` or lambdas. The core principle - decouple creation from usage - remains universally applicable. In framework design, Factory Method is everywhere: Spring's `BeanFactory`, JPA's `EntityManagerFactory`, JDBC's `DriverManager.getConnection()`. The pattern is most valuable when you're designing a framework or library where users extend your code by providing their own types.




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
Client code          Creator hierarchy
    |                      |
    v                      v
[logistics           [Logistics (abstract)]
 .planDelivery()]  -> [createTransport()] *abstract
    |                      |
    |              [RoadLogistics]  [SeaLogistics]
    |                 |                  |
    |              override:          override:
    |              return new Truck   return new Ship
    |                 |                  |
    v                 v                  v
[transport.deliver()] -> polymorphic dispatch
```

1. Client calls a method on the creator
2. Creator's algorithm calls the factory method
3. The factory method (overridden) returns a concrete product
4. The algorithm uses the product through its interface
5. Client never knows which concrete product was created
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
[Client] -> [Creator.operation()]
  -> [Creator.factoryMethod() <- YOU ARE HERE]
  -> [ConcreteProduct created]
  -> [Product used via interface]
  -> [Result returned to client]
```

**FAILURE PATH:**

```
[Factory method returns wrong type]
  -> [ClassCastException or wrong behavior]
  -> [Debug: check which creator subclass is active]
```

**WHAT CHANGES AT SCALE:**
At scale, factory methods are often combined with dependency injection. Spring's `FactoryBean<T>` interface is essentially a factory method that the container calls. In plugin architectures, factory methods load classes dynamically, which requires careful error handling for `ClassNotFoundException` and version mismatches.
---

### 💻 Code Example

**Example 1 - BAD: Direct instantiation everywhere**

```java
// BAD: Adding a new notification type requires
// modifying every place that creates notifications
public class AlertService {
    public void sendAlert(String type, String msg) {
        if ("email".equals(type)) {
            EmailNotification n = new EmailNotification();
            n.send(msg);
        } else if ("sms".equals(type)) {
            SmsNotification n = new SmsNotification();
            n.send(msg);
        }
        // Adding "push" means changing THIS code
    }
}
```

**Example 2 - GOOD: Factory Method pattern**

```java
// GOOD: New notification types = new subclass only
public interface Notification {
    void send(String message);
}

public abstract class NotificationService {
    // Factory method - subclasses decide the type
    protected abstract Notification createNotification();

    // Template method - uses the factory method
    public void sendAlert(String message) {
        Notification n = createNotification();
        n.format(message);
        n.send(message);
        n.logDelivery();
    }
}

public class EmailNotificationService
        extends NotificationService {
    @Override
    protected Notification createNotification() {
        return new EmailNotification();
    }
}

// Adding push: just create PushNotificationService
// Zero changes to existing code
```

**Example 3 - GOOD: Modern functional factory**

```java
// GOOD: Lambda-based factory avoids subclass explosion
public class NotificationService {
    private final Supplier<Notification> factory;

    public NotificationService(
            Supplier<Notification> factory) {
        this.factory = factory;
    }

    public void sendAlert(String message) {
        Notification n = factory.get();
        n.send(message);
    }
}

// Usage:
var emailService = new NotificationService(
    EmailNotification::new);
var pushService = new NotificationService(
    PushNotification::new);
```

**How to test / verify correctness:**
Test each factory subclass returns the correct product type. Test the template method works with each product via integration tests. For functional factories, pass `Supplier<MockNotification>` in unit tests.
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

1. Factory Method separates "which type to create" from "how to use it"
2. It enables the Open/Closed Principle - extend by adding subclasses, not modifying code
3. Modern Java uses `Supplier<T>` lambdas instead of subclass hierarchies

**Interview one-liner:**
"Factory Method delegates object creation to subclasses so the parent class can define an algorithm that works with any product type - I use it when I need polymorphic creation, especially in framework code, though in modern Java I often prefer functional factories with Supplier."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Factory Method is the most common design pattern in the Java standard library, but most developers don't recognize it. Every `Collection.iterator()` call, every `DriverManager.getConnection()`, every `NumberFormat.getInstance()` is a factory method. You've been using it daily without knowing it. The pattern is so fundamental that it's invisible - it's the default way frameworks let you customize behavior.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Factory Method. Otherwise remove this section.]
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

**Q1: What's the difference between Factory Method and Simple Factory?**

_Why they ask:_ Tests precision of pattern knowledge and GoF understanding.

**Answer:**
A Simple Factory is not a GoF pattern - it's a common idiom. The distinction is about where the creation decision lives:

**Simple Factory:** A single class with a method (often static) that takes a parameter and returns different types based on it:

```java
public static Transport create(String type) {
    return switch (type) {
        case "truck" -> new Truck();
        case "ship" -> new Ship();
        default -> throw new IllegalArgumentException();
    };
}
```

This centralizes creation but violates Open/Closed - adding a type means modifying the factory's switch statement.

**Factory Method:** The creation decision is deferred to subclasses. The base class defines an abstract method, and each subclass provides its own implementation. Adding a new type means adding a new subclass - no existing code changes.

The trade-off: Simple Factory is simpler for small, stable type sets. Factory Method is better when the type set grows over time or is extended by users you don't control (frameworks, plugins).

---

**Q2: When would you choose Factory Method over constructor injection in a Spring application?**

_Why they ask:_ Tests ability to choose the right pattern in a real-world context.

**Answer:**
In Spring, constructor injection is the default and preferred approach. Factory Method is warranted when:

1. **The type to create depends on runtime data:** If which implementation to use depends on a request parameter, user role, or configuration flag that changes at runtime, you need a factory. Spring's `@Autowired List<Strategy>` + a factory method that selects based on a discriminator is the idiomatic pattern.

2. **Complex construction logic:** If creating an object requires multi-step initialization, validation, or conditional configuration that doesn't belong in a constructor, a `@Bean` method in a `@Configuration` class is essentially a factory method.

3. **Third-party library integration:** When you need to create objects from a library that doesn't use Spring, a `FactoryBean<T>` or `@Bean` factory method bridges the gap.

4. **Prototype-scoped beans with parameters:** Spring can't inject runtime parameters into prototype beans automatically. A factory method (or `ObjectFactory<T>`) solves this.

For most cases, constructor injection with Spring's built-in singleton management is simpler and preferred. Use Factory Method when the creation logic itself is the variable part.

---

**Q3: You're building a plugin system where third parties add new document exporters (PDF, Excel, CSV). How would you design this using Factory Method?**

_Why they ask:_ Tests ability to apply patterns to real architectural decisions.

**Answer:**
I'd use a combination of Factory Method with service discovery:

```java
public interface DocumentExporter {
    byte[] export(Document doc);
    String getFormat(); // "pdf", "xlsx", "csv"
}

// Core module defines the interface
// Plugin jars implement it

// Discovery via ServiceLoader (SPI):
public class ExporterRegistry {
    private final Map<String, DocumentExporter> map;

    public ExporterRegistry() {
        map = new HashMap<>();
        ServiceLoader.load(DocumentExporter.class)
            .forEach(e -> map.put(e.getFormat(), e));
    }

    // Factory method
    public DocumentExporter getExporter(String fmt) {
        var exp = map.get(fmt);
        if (exp == null) throw new UnsupportedFormat(fmt);
        return exp;
    }
}
```

Third parties implement `DocumentExporter`, register via `META-INF/services`, and drop the JAR into the classpath. The registry discovers and manages instances. This gives you:

- Open/Closed: new formats without modifying core code
- Runtime extension: plugins loaded at startup
- Type safety: all exporters conform to the interface
- Testability: mock exporters can be registered in tests

In a Spring Boot context, I'd use `@Autowired List<DocumentExporter>` instead of `ServiceLoader`, and a `@Bean` factory method to build the registry.

---

**Q4: How does Factory Method relate to the Open/Closed Principle and Dependency Inversion?**

_Why they ask:_ Tests understanding of SOLID principles and pattern relationships.

**Answer:**
Factory Method is one of the primary mechanisms for achieving both SOLID principles:

**Open/Closed Principle:** The parent class defines the algorithm (closed for modification). New product types are added by creating new subclasses (open for extension). The parent never changes when new types are added.

**Dependency Inversion:** High-level modules (the parent class algorithm) depend on abstractions (the product interface), not concretions. The factory method is the mechanism that produces the concrete type while the algorithm only sees the abstraction.

These three concepts form a triangle:

```
    [Open/Closed]
       /    \
      /      \
[Factory]--[Dependency
 Method]    Inversion]
```

Without Factory Method (or a similar pattern), you can't fully achieve either principle for object creation. Direct `new` calls create concrete dependencies that violate DIP and require modification to support new types (violating OCP).

---

**Q5: What are the real-world pitfalls of using Factory Method?**

_Why they ask:_ Tests production experience and awareness of pattern limitations.

**Answer:**

1. **Parallel class hierarchies:** For every product type, you need a creator subclass. With 10 product types, you have 10 creator subclasses plus 10 product classes = 20 classes. This "class explosion" makes the codebase harder to navigate.

2. **Over-engineering for stable types:** If your type set is small and unlikely to change (e.g., exactly two payment methods), a simple `if-else` or `switch` is clearer and more maintainable than a full Factory Method hierarchy.

3. **Debugging indirection:** When a bug occurs in creation, the stack trace goes through abstract methods and polymorphic dispatch. New team members struggle to trace "what actually gets created here?"

4. **Framework conflict:** In Spring/CDI environments, the DI container already manages creation. Hand-coded factory methods can conflict with or duplicate the container's lifecycle management, leading to bugs where some instances are managed and others aren't.

5. **Testing partial mocks:** If the factory method and the algorithm are in the same class, you need to partially mock the class to test the algorithm with a different product. This is fragile and a sign that creation and usage should be in separate classes.

Mitigation: In modern Java, use functional factories (`Supplier<T>`, `Function<Config, T>`) to avoid class explosion, and let the DI container manage factory beans to avoid lifecycle conflicts.
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

# Abstract Factory

**TL;DR** - Abstract Factory provides an interface for creating families of related objects without specifying their concrete classes, ensuring consistency across product variants.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your UI framework needs to render buttons, text fields, and checkboxes. On Windows, they look one way. On macOS, another. On Linux, another. Each component is created independently: `new WindowsButton()`, `new MacOSTextField()`, `new LinuxCheckbox()`. A developer accidentally mixes `WindowsButton` with `MacOSTextField` in the same dialog. The UI looks broken and inconsistent.

**THE BREAKING POINT:**
With 10 components and 3 platforms, you have 30 concrete classes. Without a mechanism to enforce consistency, mixing components from different families is a constant source of bugs. Code reviews catch some mismatches, but not all.

**THE INVENTION MOMENT:**
"This is exactly why Abstract Factory was created."

**EVOLUTION:**
Formalized by the GoF in 1994, inspired by systems like ET++ and InterViews. The pattern was critical in the era of platform-specific UI toolkits. Today, it's used in cross-platform frameworks, theming systems, and anywhere you need to ensure a consistent family of objects. Modern examples include Java's `UIManager` (Look and Feel), Spring's `AbstractFactoryBean`, and cloud SDK clients that produce platform-specific request/response objects.
---

### 📘 Textbook Definition

Abstract Factory is a creational design pattern that provides an interface for creating families of related or dependent objects without specifying their concrete classes. It ensures that products created by a single factory are compatible with each other, enforcing consistency within a product family.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Create families of related objects that belong together, guaranteed consistent.

**One analogy:**

> Think of furniture shopping at IKEA. You choose a style - "Modern" or "Victorian." Once you pick a style, all furniture (chair, sofa, table) comes from that collection. You can't accidentally buy a Victorian chair with a Modern table from the same catalog page.

**One insight:**
The key difference from Factory Method is "family." Factory Method creates one product. Abstract Factory creates a coordinated set of products that must work together. If your system only creates one type of object, you don't need Abstract Factory.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Products within a family are designed to work together
2. The factory guarantees family consistency - you can't mix families
3. Adding a new family requires zero changes to existing client code

**DERIVED DESIGN:**
One factory interface declares methods for creating each product type. Each concrete factory implements all methods, producing products from the same family. Client code receives a factory and uses it to create all products - it never calls `new` directly. The factory acts as a constraint that prevents inconsistent combinations.

**THE TRADE-OFFS:**
**Gain:** Guaranteed family consistency, easy to swap entire product families, client code is decoupled from concrete products
**Cost:** Adding a new product type to the family requires changing the factory interface and ALL concrete factories; significant upfront design

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Coordinating multiple related objects requires some grouping mechanism - families must be enforced somewhere
**Accidental:** The interface rigidity (can't add a new product type without modifying all factories) is a limitation of the static type system; languages with duck typing avoid this
---

### 🧠 Mental Model / Analogy

> Think of a car manufacturing plant. When you set the assembly line to "Sedan," every station produces sedan parts: sedan doors, sedan engine, sedan interior. When you switch to "SUV," every station switches to SUV parts. You never get a sedan door on an SUV body.

- "Assembly line setting" -> concrete factory selection
- "Each station" -> each factory method
- "Sedan parts together" -> products from one family
- "Can't mix SUV door with sedan body" -> family consistency

Where this analogy breaks down: In software, switching families is instant (swap the factory reference), while reconfiguring an assembly line takes days.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Abstract Factory is like choosing a theme for your entire room. When you pick "Modern," everything - furniture, lighting, decor - comes in the modern style. You can't accidentally mix vintage with modern.

**Level 2 - How to use it (junior developer):**
Create an interface with methods like `createButton()`, `createTextField()`, `createCheckbox()`. Implement it twice: `WindowsUIFactory` and `MacOSUIFactory`. Each returns platform-specific components. Your application receives the factory at startup and uses it everywhere. All components are guaranteed to match.

**Level 3 - How it works (mid-level engineer):**
Abstract Factory is an aggregation of Factory Methods. Each method in the factory interface is a Factory Method. The factory enforces that all products come from the same family. In Java, `javax.xml.parsers.DocumentBuilderFactory` is an Abstract Factory - it produces `DocumentBuilder` instances configured for a specific XML parser implementation (Xerces, Saxon, etc.), and all related objects (error handlers, entity resolvers) come from the same implementation family.

**Level 4 - Mastery (senior/staff+ engineer):**
Abstract Factory shines in exactly one scenario: when you have multiple product types that must be used together consistently, and you have multiple families (variants) of those products. If you only have one product type, use Factory Method. If families don't need consistency guarantees, use individual factories. The pattern's weakness - adding a new product type forces changes across all factories - makes it best suited for stable product interfaces with varying implementations. In modern practice, DI containers and configuration profiles often replace explicit Abstract Factories. Spring's `@Profile` mechanism achieves the same family-switching behavior without the pattern's boilerplate.




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
Client -> [AbstractFactory]
              |
    +---------+---------+
    |                   |
[WindowsFactory]  [MacOSFactory]
    |                   |
    +-createButton()    +-createButton()
    +-createField()     +-createField()
    +-createCheckbox()  +-createCheckbox()
    |                   |
    v                   v
[WinButton,         [MacButton,
 WinField,           MacField,
 WinCheckbox]        MacCheckbox]
```

1. Client receives a factory (injected or configured)
2. Client calls factory methods to create products
3. All products come from the same family
4. Client works with product interfaces only
5. Swapping the factory swaps the entire product family
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
[Config/Runtime] -> [Select factory <- YOU ARE HERE]
  -> [Factory creates product A, B, C]
  -> [Client uses A, B, C via interfaces]
  -> [All products are from same family]
```

**FAILURE PATH:**

```
[Wrong factory selected for environment]
  -> [Products render incorrectly]
  -> [Debug: check factory selection logic]
```

**WHAT CHANGES AT SCALE:**
At scale, Abstract Factory often evolves into a registry pattern where factories are dynamically loaded. Plugin systems register their factory implementation, and the runtime selects based on configuration. In cloud environments, the "family" might be a cloud provider (AWS vs Azure vs GCP), with each factory producing provider-specific clients.
---

### 💻 Code Example

**Example 1 - BAD: Mixed product families**

```java
// BAD: Nothing prevents mixing families
public class Dialog {
    public void render(String os) {
        Button b;
        TextField t;
        if ("windows".equals(os)) {
            b = new WindowsButton();
        } else {
            b = new MacOSButton();
        }
        // Oops: forgot to check os for TextField
        t = new WindowsTextField(); // Always Windows!
        b.render();
        t.render(); // Inconsistent UI
    }
}
```

**Example 2 - GOOD: Abstract Factory guarantees consistency**

```java
// GOOD: Factory ensures all products match
public interface UIFactory {
    Button createButton();
    TextField createTextField();
}

public class MacOSFactory implements UIFactory {
    public Button createButton() {
        return new MacOSButton();
    }
    public TextField createTextField() {
        return new MacOSTextField();
    }
}

public class Dialog {
    private final UIFactory factory;

    public Dialog(UIFactory factory) {
        this.factory = factory;  // Injected
    }

    public void render() {
        Button b = factory.createButton();
        TextField t = factory.createTextField();
        // Guaranteed same family
        b.render();
        t.render();
    }
}
```

**How to test / verify correctness:**
Create a `TestUIFactory` that returns mock products. Verify that `Dialog` calls the correct factory methods. Integration test each concrete factory to verify products are compatible.
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

1. Abstract Factory creates families of objects that must work together
2. The factory prevents inconsistent mixing of product variants
3. Adding a new product type is expensive (all factories change); adding a new family is cheap (one new factory)

**Interview one-liner:**
"Abstract Factory guarantees consistency across a family of related products by encapsulating creation behind an interface - I use it when mixing product variants would cause bugs, like cross-platform UI or multi-cloud SDK abstractions."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Abstract Factory is often confused with Factory Method, but they solve fundamentally different problems. Factory Method creates one product with polymorphic behavior. Abstract Factory coordinates multiple products into a consistent family. You can use Factory Method without Abstract Factory, but every Abstract Factory internally uses Factory Methods. The relationship is compositional, not hierarchical.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Abstract Factory. Otherwise remove this section.]
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

**Q1: When would you use Abstract Factory over Factory Method?**

_Why they ask:_ Tests ability to distinguish closely related patterns.

**Answer:**
Use Abstract Factory when you have two or more product types that must be used together consistently. Use Factory Method when you have a single product type with multiple variants.

The decision checklist:

- **One product type, multiple variants:** Factory Method. Example: `createLogger()` returns `FileLogger` or `CloudLogger`.
- **Multiple product types, multiple consistent families:** Abstract Factory. Example: UI toolkit that produces buttons, text fields, and checkboxes that must all be from the same OS family.
- **Multiple independent product types, no consistency requirement:** Separate Factory Methods. No need for Abstract Factory's coupling overhead.

A common mistake is using Abstract Factory for a single product - that's over-engineering. Another mistake is using separate Factory Methods when products must be consistent - that risks the mixing bug Abstract Factory prevents.

---

**Q2: How does Abstract Factory apply in a multi-cloud architecture?**

_Why they ask:_ Tests real-world architectural application.

**Answer:**
In a multi-cloud system, each cloud provider is a "family":

```java
public interface CloudFactory {
    ObjectStorage createStorage();
    MessageQueue createQueue();
    ComputeService createCompute();
}

public class AWSFactory implements CloudFactory {
    public ObjectStorage createStorage() {
        return new S3Storage(awsConfig);
    }
    public MessageQueue createQueue() {
        return new SQSQueue(awsConfig);
    }
    public ComputeService createCompute() {
        return new LambdaCompute(awsConfig);
    }
}
```

The application code works with `ObjectStorage`, `MessageQueue`, and `ComputeService` interfaces. Switching from AWS to GCP means swapping `AWSFactory` for `GCPFactory`. All services switch together - you never accidentally mix S3 with Cloud Pub/Sub.

In production, I'd combine this with Spring profiles: `@Profile("aws")` on `AWSFactory`, `@Profile("gcp")` on `GCPFactory`. Environment variables control which profile is active, and the entire cloud provider family switches with a config change.

---

**Q3: What's the biggest weakness of Abstract Factory and how would you mitigate it?**

_Why they ask:_ Tests critical thinking and practical problem-solving.

**Answer:**
The biggest weakness is the **closed product interface problem.** If you need to add a new product type (e.g., add `createNotificationService()` to the factory), you must modify the factory interface AND every concrete factory implementation.

With 5 families and 1 new product type, that's 6 files changed (1 interface + 5 implementations). This violates Open/Closed for new product types.

Mitigation strategies:

1. **Parameterized factory:** Use a generic `create(Class<T> type)` method instead of specific methods. More flexible but loses compile-time type safety.

2. **Registry-based factory:** Each factory maintains a `Map<Class<?>, Supplier<?>>`. New product types can be registered without modifying the interface.

3. **Module system:** Split each product type into its own module with its own factory. Compose them at the application level rather than in one monolithic factory.

4. **Accept the trade-off:** If the product set is stable (defined by a spec or standard), the rigidity is actually a feature - it prevents partial implementations.

In my experience, if you're adding product types frequently, Abstract Factory is the wrong pattern. Use a service registry or plugin architecture instead.
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

# Builder

**TL;DR** - Builder separates the construction of a complex object from its representation, allowing the same construction process to create different representations step by step.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your `User` class has 15 fields: name, email, phone, address, preferences, notification settings, roles, etc. The constructor takes 15 parameters. Callers pass `null` for optional fields. A developer swaps the phone and email parameters (both are strings), and the bug passes compilation. Telescoping constructors multiply: `User(name)`, `User(name, email)`, `User(name, email, phone)` - 10 constructor overloads.

**THE BREAKING POINT:**
A new field is added. Every constructor overload needs updating. Three developers make the same change in three branches. Merge conflicts everywhere. One merge accidentally drops a parameter check.

**THE INVENTION MOMENT:**
"This is exactly why Builder was created."

**EVOLUTION:**
The GoF Builder (1994) focused on constructing complex objects step-by-step with a director. Bloch's Effective Java (2001) popularized a simpler variant: the static inner class builder, which provides a fluent API for object construction. Modern Java uses Lombok's `@Builder`, Kotlin's data classes with named/default parameters, and record builders. The pattern evolved from "separate construction and representation" to "provide a readable, type-safe construction API."
---

### 📘 Textbook Definition

Builder is a creational design pattern that separates the construction of a complex object from its representation so that the same construction process can create different representations. It provides a step-by-step approach to building objects, allowing for fine-grained control over the construction process.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Build complex objects step by step with a readable, mistake-proof API.

**One analogy:**

> Ordering a custom pizza: you start with dough, then add sauce, then cheese, then toppings - one choice at a time. You don't have to specify all 12 options in one breath. You can skip mushrooms. The pizza is assembled only when you say "done."

**One insight:**
Builder isn't just about avoiding long constructors. It's about making invalid objects impossible to construct. A well-designed Builder can enforce invariants: requiring an email before building, preventing conflicting options, validating at build time. It shifts validation from runtime errors to compile-time constraints.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Construction is separate from the final object
2. Each step is independent and optional (or enforced)
3. The final object is immutable after construction

**DERIVED DESIGN:**
The builder accumulates state through method calls. Each method returns the builder itself (fluent API). The `build()` method validates accumulated state and constructs the final immutable object. The separation allows the same builder interface to produce different representations.

**THE TRADE-OFFS:**
**Gain:** Readable construction, immutable objects, validation at build time, self-documenting code
**Cost:** More code (builder class mirrors the product class), slight runtime overhead for the builder object

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Complex objects need a construction mechanism that handles optional fields, defaults, and validation
**Accidental:** The boilerplate of writing the builder class - Lombok and IDE generators eliminate this
---

### 🧠 Mental Model / Analogy

> Think of Builder as a meal ordering kiosk. You select items one by one: burger (required), fries (optional), drink (optional), sauce (optional). The kiosk validates your order before sending it to the kitchen. You can't order a combo without a main item. The final order is sealed and can't be modified.

- "Kiosk" -> Builder class
- "Selecting items" -> fluent method calls
- "Validation before sending" -> build() validates
- "Sealed order" -> immutable final object

Where this analogy breaks down: A kiosk allows changing your mind before submitting; Builder methods are typically additive - you don't "undo" a setter.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Instead of cramming 15 settings into one confusing line, Builder lets you set each option by name, one at a time, in any order. When you're done, it creates the final object.

**Level 2 - How to use it (junior developer):**
Create a static inner class `Builder` with the same fields as the product. Each setter returns `this` for chaining: `new User.Builder().name("Alice").email("a@b.com").build()`. Mark required fields as constructor parameters of the Builder. Make the product class constructor private so it can only be created through the Builder.

**Level 3 - How it works (mid-level engineer):**
The Bloch Builder pattern uses a static inner class that mirrors the product's fields. The Builder accumulates state, the `build()` method creates an immutable instance. For complex validation (fields that depend on each other), `build()` is the checkpoint. In Java records, the canonical constructor handles validation, but Builder still adds value for objects with many optional fields. Lombok's `@Builder` generates the entire pattern at compile time with zero boilerplate.

**Level 4 - Mastery (senior/staff+ engineer):**
Advanced Builder patterns include: (1) **Step Builder** - compile-time enforcement of required fields using interfaces for each step (`UserBuilder.name("x")` returns `WithName` interface that has `email()`, preventing calling `build()` before email is set). (2) **Generic self-referencing builder** for inheritance hierarchies using `T extends Builder<T>`. (3) **DSL-style builders** for configuration objects where the builder creates a domain-specific language. In practice, I evaluate Builder vs other options: Kotlin named parameters + default values eliminate most Builder use cases; Java records with Wither methods offer an alternative for simple cases; and for DTOs, Jackson's `@JsonDeserialize(builder=...)` integrates Builder with deserialization.




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
Client code:
  User user = new User.Builder("Alice")  // required
      .email("alice@example.com")   // optional
      .phone("+1-555-0100")         // optional
      .role(Role.ADMIN)             // optional
      .build();                     // validate + create

Builder internals:
  [Builder created with required fields]
       |
  [.email() -> sets field, returns this]
       |
  [.phone() -> sets field, returns this]
       |
  [.build() -> validates all fields]
       |
  [new User(this) -> immutable object]
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
[Client] -> [Builder("required")]
  -> [.optional1() .optional2() <- YOU ARE HERE]
  -> [.build()]
  -> [Validation passes]
  -> [Immutable object created]
```

**FAILURE PATH:**

```
[.build() called with invalid state]
  -> [IllegalStateException thrown]
  -> [Message: "email required when role=ADMIN"]
```

**WHAT CHANGES AT SCALE:**
At scale, Builders are used to construct complex configuration objects for frameworks (Spring `WebClient.builder()`, OkHttp `Request.Builder`). In microservices, request/response DTOs often use Builders. With code generation (Lombok, AutoValue, Immutables), the boilerplate cost drops to zero, making Builder the default for any object with more than 3-4 fields.
---

### 💻 Code Example

**Example 1 - BAD: Telescoping constructor**

```java
// BAD: Which String is which? Easy to swap args
public class HttpRequest {
    public HttpRequest(String url, String method,
            String body, String contentType,
            String auth, int timeout,
            boolean followRedirects) {
        // 7 parameters, 3 are Strings
    }
}

// Caller: is "POST" the method or the body?
var req = new HttpRequest(
    "https://api.example.com",
    "POST", "{}", "application/json",
    "Bearer token", 30000, true);
```

**Example 2 - GOOD: Builder pattern**

```java
// GOOD: Self-documenting, mistake-proof
public class HttpRequest {
    private final String url;
    private final String method;
    private final String body;
    private final String contentType;
    private final int timeout;

    private HttpRequest(Builder b) {
        this.url = b.url;
        this.method = b.method;
        this.body = b.body;
        this.contentType = b.contentType;
        this.timeout = b.timeout;
    }

    public static class Builder {
        private final String url;    // required
        private String method = "GET";
        private String body;
        private String contentType = "application/json";
        private int timeout = 30_000;

        public Builder(String url) {
            this.url = Objects.requireNonNull(url);
        }

        public Builder method(String m) {
            this.method = m; return this;
        }
        public Builder body(String b) {
            this.body = b; return this;
        }
        public Builder timeout(int ms) {
            this.timeout = ms; return this;
        }

        public HttpRequest build() {
            if (body != null && "GET".equals(method)) {
                throw new IllegalStateException(
                    "GET requests cannot have a body");
            }
            return new HttpRequest(this);
        }
    }
}

// Usage: clear, readable, validated
var req = new HttpRequest.Builder("https://api.com")
    .method("POST")
    .body("{\"key\": \"value\"}")
    .timeout(5000)
    .build();
```

**How to test / verify correctness:**
Test that `build()` throws on invalid combinations. Test that default values work when optional fields are omitted. Test immutability - the product should not change when the builder is reused.
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

1. Builder makes complex object construction readable and mistake-proof
2. `build()` is the validation checkpoint - enforce invariants here
3. The final object should be immutable; the Builder is the only way to set fields

**Interview one-liner:**
"Builder provides a fluent, step-by-step API for constructing complex immutable objects - I use it for any class with more than 3-4 parameters, especially when some are optional, and in modern Java I use Lombok's @Builder to eliminate the boilerplate."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Builder pattern's original GoF purpose was not about avoiding long constructors. It was about using the same construction process to create different representations - like parsing an RTF document and producing either a PDF or an ASCII text output. The "Effective Java" variant that developers use daily is a simplified adaptation that dropped the Director and focused on fluent APIs. Most "Builder pattern" interviews test a pattern that isn't quite what the GoF described.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Builder. Otherwise remove this section.]
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

**Q1: What's the difference between the GoF Builder and the Effective Java Builder?**

_Why they ask:_ Tests depth of pattern knowledge beyond surface-level usage.

**Answer:**
The GoF Builder has four participants: Builder (interface), ConcreteBuilder, Director, and Product. The Director orchestrates the construction steps in a specific order. Multiple ConcreteBuilders produce different Products from the same construction process. The emphasis is on "same process, different output."

The Effective Java (Bloch) Builder is simpler: a static inner class that provides a fluent API for constructing a single class. No Director. No multiple builders. The emphasis is on "readable construction of complex objects with many optional parameters."

The GoF version is still relevant in scenarios like document converters (parse once, output in multiple formats), SQL query builders (same query structure, different SQL dialects), and serialization frameworks. But 95% of "Builder pattern" in daily development is the Bloch variant.

---

**Q2: How would you handle required fields in a Builder?**

_Why they ask:_ Tests practical implementation skill and awareness of validation strategies.

**Answer:**
Three strategies, each with trade-offs:

1. **Constructor parameters on the Builder:**

```java
new User.Builder("email@x.com", Role.ADMIN)
    .phone("555")
    .build();
```

Pros: compile-time enforcement. Cons: if you have 5 required fields, the Builder constructor becomes the same problem you're solving.

2. **Validation in `build()`:**

```java
public User build() {
    if (email == null)
        throw new IllegalStateException(
            "email is required");
    return new User(this);
}
```

Pros: simple, flexible. Cons: runtime error instead of compile-time.

3. **Step Builder (type-safe):**

```java
User.builder()
    .email("x@y.com")   // returns WithEmail
    .role(Role.ADMIN)    // returns WithRole
    .build();            // only available after all
                         // required steps
```

Pros: compile-time safety, IDE autocomplete guides the user. Cons: interface explosion (one per required step).

In practice, I use option 1 for 1-2 required fields and option 2 for more. Option 3 is worth it for public APIs where compile-time safety justifies the complexity.

---

**Q3: When would you NOT use Builder?**

_Why they ask:_ Tests critical judgment and pattern appropriateness.

**Answer:**
Don't use Builder when:

1. **Few parameters (1-3):** A constructor or static factory method is simpler. `Point.of(x, y)` beats `new Point.Builder().x(1).y(2).build()`.

2. **Mutable objects:** If the object has setters and is meant to be modified after creation, Builder adds nothing. JavaBeans pattern (getters/setters) is fine.

3. **Kotlin/Scala:** Named parameters and default values eliminate most Builder use cases: `User(name = "Alice", email = "a@b.com")`.

4. **DTOs with frameworks:** Jackson, MapStruct, and similar frameworks can construct objects directly from data. Adding a Builder layer between the framework and the object is redundant.

5. **Performance-critical hot paths:** Builder creates an intermediate object that's immediately discarded. In tight loops processing millions of items, this generates garbage pressure. Use direct construction instead.

The general rule: use Builder when the construction API would otherwise be confusing, error-prone, or unsafe. If construction is straightforward, don't add the pattern.
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

# Prototype

**TL;DR** - Prototype creates new objects by cloning an existing instance, avoiding costly initialization when objects share most of their configuration.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Your game engine creates thousands of enemy objects per level. Each enemy requires loading a 3D model, parsing animation data, calculating physics bounds, and setting default stats - a process that takes 200ms per enemy. Creating 100 enemies from scratch takes 20 seconds. The level takes forever to load.

**THE BREAKING POINT:**
A new requirement adds customizable enemies - same base model with slight variations (different colors, weapons). Rebuilding from scratch for each variation wastes 95% of the initialization work since only 5% differs.

**THE INVENTION MOMENT:**
"This is exactly why Prototype was created."

**EVOLUTION:**
The GoF formalized Prototype in 1994, though the concept of cloning existed in Lisp and Smalltalk. JavaScript's prototype-based inheritance is built on this pattern. Java's `Cloneable` interface is a language-level implementation (though widely considered broken). Modern usage includes `Object.assign()` in JavaScript, `copy()` in Kotlin data classes, and prototype registries in game engines and document editors.
---

### 📘 Textbook Definition

Prototype is a creational design pattern that specifies the kind of objects to create using a prototypical instance, and creates new objects by copying this prototype. It delegates the cloning process to the actual objects that are being cloned, avoiding coupling to their concrete classes.
---

### ⏱️ Understand It in 30 Seconds

**One line:**
Clone an existing object instead of building from scratch.

**One analogy:**

> Photocopying a filled-out form. Instead of filling out each field from scratch for every new employee, you photocopy a completed template and just change the name and employee ID. 95% of the content is identical.

**One insight:**
Prototype is not just about performance. It's about creating objects when you don't know their concrete class at compile time. If you receive an object through an interface, you can't call `new` on it (you don't know the class). But you can call `clone()`. Prototype enables polymorphic object creation without knowing the concrete type.
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. New objects are created by copying existing ones
2. The clone operation is delegated to the object itself
3. The client doesn't need to know the concrete class to create a copy

**DERIVED DESIGN:**
Each clonable class implements a `clone()` method that creates a copy of itself. A prototype registry can store pre-configured objects that are cloned on demand. The pattern requires a decision between shallow copy (references shared) and deep copy (independent copies of all referenced objects).

**THE TRADE-OFFS:**
**Gain:** Faster creation when initialization is expensive, polymorphic cloning without knowing concrete types, avoids subclass explosion for variants
**Cost:** Deep cloning is complex (circular references, immutable vs mutable fields), `Cloneable` in Java is broken by design

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** Copying object state requires knowing which fields to deep-copy vs shallow-copy - this decision is domain-specific
**Accidental:** Java's `Cloneable` interface has no `clone()` method, the `Object.clone()` return type is `Object`, and the specification is vague about deep vs shallow copy
---

### 🧠 Mental Model / Analogy

> Think of Prototype as cell division in biology. A cell doesn't get built from scratch using a blueprint (constructor). It clones itself, creating a near-identical copy. The copy can then differentiate (be modified) for a specific purpose.

- "Original cell" -> prototype object
- "Cell division" -> clone() method
- "Differentiation" -> modifying the clone
- "No blueprint needed" -> no constructor call

Where this analogy breaks down: Biological cells share no memory after division; software clones may share references to the same objects (shallow copy) unless explicitly deep-copied.
---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Instead of making something from scratch, you copy an existing one and change what's different. Like using a template instead of starting from a blank page.

**Level 2 - How to use it (junior developer):**
Implement a `clone()` method that returns a copy of the object. Use it when creating an object from scratch is expensive or when you need variations of a preconfigured object. In Java, avoid `Cloneable` - use a copy constructor or a static factory method instead.

**Level 3 - How it works (mid-level engineer):**
The critical decision is shallow vs deep copy. Shallow copy copies field values - for primitives, this creates independent copies, but for objects, both original and clone share the same reference. Deep copy recursively copies all referenced objects. In Java, `Object.clone()` performs a shallow copy by default. For deep copies, you can use serialization (`serialize then deserialize`), copy constructors, or libraries like Apache Commons' `SerializationUtils.clone()`. Each approach has performance and correctness implications.

**Level 4 - Mastery (senior/staff+ engineer):**
Prototype is most powerful in systems where you don't know concrete types at compile time. A document editor stores a palette of shapes (circle, rectangle, custom). The user drags a shape onto the canvas - the system calls `shape.clone()` without knowing if it's a `Circle` or `CustomShape`. This is polymorphic creation without factories. In JavaScript, the entire object system is prototype-based (`Object.create(proto)`), which shows the pattern elevated to a language feature. In production systems, I've used prototype registries for: configuring complex request objects (clone a baseline config, modify per-request), game entities (clone base enemy, vary attributes), and test data builders (clone a valid baseline, break one field per test).




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
[Prototype Registry]
    |
    +-- "enemy-warrior"  -> [WarriorPrototype]
    +-- "enemy-mage"     -> [MagePrototype]
    +-- "enemy-boss"     -> [BossPrototype]
    |
[Client requests "enemy-warrior"]
    |
    v
[WarriorPrototype.clone() <- YOU ARE HERE]
    |
    v
[New Warrior instance (deep copy)]
    |
    v
[Modify: position, color, difficulty]
    |
    v
[Fully configured enemy in the game]
```
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
[Registry lookup] -> [prototype.clone() <- YOU ARE HERE]
  -> [Deep copy created]
  -> [Clone customized]
  -> [Clone used independently]
```

**FAILURE PATH:**

```
[Shallow copy used when deep needed]
  -> [Clone and original share references]
  -> [Modifying clone changes original]
  -> [Subtle, hard-to-debug corruption]
```

**WHAT CHANGES AT SCALE:**
At scale, prototype cloning must be thread-safe. If the prototype is mutable and shared across threads, cloning a partially-modified prototype produces inconsistent objects. Solutions include immutable prototypes (safest), copy-on-write semantics, or per-thread prototype instances.
---

### 💻 Code Example

**Example 1 - BAD: Expensive repeated creation**

```java
// BAD: Full initialization for every instance
public class GameLevel {
    public Enemy createEnemy(String type) {
        // Each call: 200ms to load model, parse
        // animations, calculate physics
        Enemy e = new Enemy();
        e.loadModel(type + ".obj");     // Slow I/O
        e.parseAnimations(type + ".anim");
        e.calculateBounds();
        return e;
    }
}
// 100 enemies = 20 seconds of loading
```

**Example 2 - GOOD: Prototype cloning**

```java
// GOOD: Clone pre-initialized prototypes
public interface GameEntity {
    GameEntity deepClone();
}

public class Enemy implements GameEntity {
    private Mesh model;
    private Animation[] anims;
    private BoundingBox bounds;
    private Vector3 position;

    // Copy constructor for deep clone
    public Enemy(Enemy source) {
        this.model = source.model;       // Immutable
        this.anims = source.anims.clone();
        this.bounds = new BoundingBox(source.bounds);
        this.position = new Vector3(0, 0, 0);
    }

    @Override
    public GameEntity deepClone() {
        return new Enemy(this);
    }
}

// Registry: initialize prototypes once at startup
public class EntityRegistry {
    private final Map<String, GameEntity> protos =
        new HashMap<>();

    public void register(String key, GameEntity e) {
        protos.put(key, e);
    }

    public GameEntity create(String key) {
        return protos.get(key).deepClone();
    }
}

// Usage: clone takes <1ms vs 200ms creation
var registry = new EntityRegistry();
registry.register("warrior", loadWarrior());
Enemy e = (Enemy) registry.create("warrior");
e.setPosition(new Vector3(10, 0, 5));
```

**How to test / verify correctness:**
Test that modifying a clone does not affect the original (deep copy verification). Test that clone equals the original in all fields (correctness). Performance test: measure clone time vs constructor time.
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

1. Clone existing objects instead of expensive re-creation
2. Deep copy vs shallow copy is the critical decision - get it wrong and objects corrupt each other
3. In Java, use copy constructors instead of `Cloneable` - it's safer and more explicit

**Interview one-liner:**
"Prototype creates objects by cloning a pre-configured instance, which is essential when initialization is expensive or when you need to create objects without knowing their concrete type - I always use copy constructors over Cloneable for safety."
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

Java's `Cloneable` interface is one of the most broken APIs in the language. It has no methods (it's a marker interface), but `Object.clone()` checks for it and throws `CloneNotSupportedException` if it's missing. The `clone()` method returns `Object`, requiring a cast. And the specification doesn't define whether the copy should be shallow or deep. Joshua Bloch, who helped design the Java collections framework, calls it "a moderately broken design" in Effective Java. This is why modern Java code uses copy constructors or `static CopyOf()` methods instead.
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Prototype. Otherwise remove this section.]
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

**Q1: What's the difference between shallow copy and deep copy, and when does each cause problems?**

_Why they ask:_ Tests fundamental understanding of object references and memory.

**Answer:**
**Shallow copy** copies field values directly. For primitives (`int`, `boolean`), this creates independent copies. For object references, both original and clone point to the same object.

**Deep copy** recursively copies all referenced objects, creating a completely independent object graph.

Problems with shallow copy:

```java
Enemy clone = original.shallowClone();
clone.getWeapon().setDamage(100);
// original.getWeapon().getDamage() is now 100!
// They share the same Weapon reference
```

Problems with deep copy:

- **Circular references:** Object A references B, B references A. Naive deep copy enters infinite recursion. Solution: maintain a visited-set during cloning.
- **Performance:** Deep copying a large object graph is expensive. If parts of the graph are immutable, they can be safely shared.
- **External resources:** Deep copying a database connection or file handle is meaningless or dangerous.

The practical rule: deep copy mutable objects, share immutable ones. For mutable objects that are expensive to copy, use copy-on-write semantics.

---

**Q2: How would you implement a prototype registry for a configuration-driven system?**

_Why they ask:_ Tests ability to apply the pattern to real architecture.

**Answer:**
A prototype registry stores pre-configured objects loaded from configuration and clones them on demand:

```java
public class ConfigPrototypeRegistry {
    private final Map<String, Configurable> protos;

    public ConfigPrototypeRegistry(Config config) {
        protos = new ConcurrentHashMap<>();
        for (var entry : config.getTemplates()) {
            Configurable proto = buildFromConfig(entry);
            protos.put(entry.getName(), proto);
        }
    }

    @SuppressWarnings("unchecked")
    public <T extends Configurable> T create(String key) {
        Configurable proto = protos.get(key);
        if (proto == null)
            throw new UnknownTemplate(key);
        return (T) proto.deepClone();
    }
}
```

Key design decisions:

1. **Thread safety:** Use `ConcurrentHashMap`. Prototypes are immutable after registration.
2. **Configuration reload:** Replace the entire map atomically on config change (double-buffer pattern).
3. **Validation:** Validate prototypes at registration time, not at clone time.
4. **Memory:** If prototypes hold large data (images, models), consider lazy loading with placeholder objects that load on first access after cloning.

---

**Q3: In what real-world scenarios have you used or would you use the Prototype pattern?**

_Why they ask:_ Tests practical experience and ability to identify pattern applicability.

**Answer:**
Three production scenarios where Prototype proved valuable:

1. **Test data builder:** A base `ValidUser` prototype with all required fields set correctly. Each test clones it and breaks one field to test validation: `validUser.clone().withEmail(null)`. This avoids 50-line test setup per test method and makes tests self-documenting.

2. **Email template system:** Pre-configured email objects (headers, footers, styling, sender) stored as prototypes. Each send clones the template and sets recipient-specific content. Cloning is faster than reconstructing from the template engine each time, and ensures consistency.

3. **Kubernetes manifest generation:** Base YAML manifests stored as prototypes. For each microservice deployment, clone the base and modify the image, replicas, and environment variables. This ensures all services share the same resource limits, health checks, and security contexts unless explicitly overridden.

The common thread: Prototype shines when objects are "mostly the same" with small variations, and the base configuration is expensive or error-prone to recreate.
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
