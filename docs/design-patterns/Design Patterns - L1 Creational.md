---
layout: default
title: "Design Patterns - L1 Creational"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 2
permalink: /design-patterns/l1-creational/
---

# Singleton Pattern

---
id: DP-004
title: Singleton Pattern
category: Design Patterns
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #design-patterns, #singleton, #creational, #thread-safety
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Singleton ensures a class has only one instance and provides a global
> access point to it. The classic Java implementation uses a private
> constructor, a static holder field, and a static `getInstance()` method.
> The key interview point: the naive version is not thread-safe, and
> Singleton is widely considered an anti-pattern in modern code because
> it is global mutable state that makes testing and reasoning hard.

**3 minutes (Senior):**
> I distinguish three versions of Singleton. The naive version (check
> null, create if null) breaks under multithreading - two threads can
> both see null simultaneously and create two instances. The double-checked
> locking version (check null outside synchronized, check again inside)
> was broken before Java 5 due to memory model issues; after Java 5 with
> the `volatile` keyword it is safe. The best Java implementation is the
> Initialization-on-demand holder (LazyHolder) idiom: a static inner class
> holds the instance; Java's class loading guarantee provides thread-safety
> with zero synchronization cost.
>
> The production reality: Singleton is most often the wrong tool. What you
> actually want is a single shared instance managed by a DI container.
> Spring `@Bean` methods are singleton-scoped by default. That gives you
> a single instance without global state or testability problems.

**Blank Mind Recovery:**

**(1) Restate:** "Singleton - the pattern that ensures exactly one
instance of a class exists."

**(2) First principles:** "The problem: some resources should exist
only once (configuration, connection pool, log writer). The naive
solution: a global variable. The OO solution: the class controls its
own instantiation, exposes one access point."

**(3) Bridge:** "This is similar to a database connection pool: you
want one pool shared by all users, not one pool per request."

---

### 📘 Concept Explanation

**What it is:**
Singleton is a Creational pattern that restricts instantiation of a
class to a single object and provides a global access point to that
instance.

**The problem it solves:**
Some objects should exist exactly once: configuration files, logging
infrastructure, connection pools, hardware interfaces. Without Singleton,
every caller might create its own instance, wasting resources and causing
inconsistency.

**How it works:**

```
1. Private constructor: prevents external instantiation
   private Singleton() {}

2. Static instance field: holds the one instance
   private static Singleton instance;

3. Static access method: creates on first call, returns same after
   public static Singleton getInstance() {
       if (instance == null) instance = new Singleton();
       return instance;
   }
```

Thread-safe implementations in order of preference:

```java
// 1. Enum Singleton (BEST: serialization-safe, reflection-safe)
public enum AppConfig {
    INSTANCE;
    private final String dbUrl = "jdbc:postgresql://...";
    public String getDbUrl() { return dbUrl; }
}
// Use: AppConfig.INSTANCE.getDbUrl()
```

```java
// 2. Initialization-on-demand holder (GOOD: lazy, thread-safe)
public class Singleton {
    private Singleton() {}

    private static class Holder {
        // Class loaded on first use of Singleton.getInstance()
        // Class loading is thread-safe by JVM spec
        static final Singleton INSTANCE = new Singleton();
    }

    public static Singleton getInstance() {
        return Holder.INSTANCE;
    }
}
```

```java
// 3. Double-checked locking (OK with volatile, Java 5+)
public class Singleton {
    // volatile: ensures visibility of partially constructed object
    private static volatile Singleton instance;
    private Singleton() {}

    public static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {        // second check
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```

**The key insight:**
The best Singleton implementations leverage language/runtime guarantees
rather than explicit synchronization: Enum leverages serialization
guarantees; the Holder idiom leverages class loading order; both avoid
synchronization overhead.

**When to use it:**
- Truly shared resources where one instance is a genuine requirement
  (logging, metrics sink, hardware driver)
- When you cannot use DI and need the instance globally accessible
- Enum Singleton for configuration constants

**When NOT to use it:**
- When a DI container (Spring) is available: use `@Bean` scope instead
- For services and repositories: they should be injected, not global
- When you need testability: Singleton with global state prevents
  test isolation

**Alternatives:**
- **Spring `@Bean` (default singleton scope)** - one instance per
  application context, injectable and mockable
- **Dependency Injection** - inject a shared instance rather than
  using global access
- **Module-level variable** (in languages with modules) - often simpler

**First-principles derivation:**
Given: you need one shared instance of a resource. Options: (A) global
variable - breaks encapsulation, not OO. (B) pass it as a parameter
everywhere - verbose, requires all callers to know. (C) let the class
manage its own uniqueness - Singleton. Option C in modern code becomes
(D) let the DI container manage uniqueness - even better.

---

### 💻 Code Example

```java
// BAD: naive Singleton - not thread-safe
public class ConfigManager {
    private static ConfigManager instance;
    private Properties props;

    private ConfigManager() {
        props = loadFromFile();  // expensive
    }

    // Two threads can both see null and create two instances
    public static ConfigManager getInstance() {
        if (instance == null) {
            instance = new ConfigManager();  // RACE CONDITION
        }
        return instance;
    }
}
```

> **Code walkthrough:** Thread A and Thread B both call `getInstance()`
> at the same time. Both see `instance == null`. Both create a new
> `ConfigManager`. Thread A's instance becomes unreachable but Thread B's
> `ConfigManager` loaded different configuration state. Result: two
> instances, one immediately garbage collected, inconsistent state.

```java
// GOOD: Enum Singleton (preferred for constants)
public enum DatabaseConfig {
    INSTANCE;

    private final String url;
    private final int poolSize;

    DatabaseConfig() {
        // reads from environment / system properties
        this.url = System.getenv("DB_URL");
        this.poolSize = Integer.parseInt(
            System.getenv().getOrDefault("DB_POOL_SIZE", "10"));
    }

    public String url() { return url; }
    public int poolSize() { return poolSize; }
}

// Usage: DatabaseConfig.INSTANCE.url()
// Serialization-safe: enum serialization returns the same instance
// Reflection-safe: cannot call constructor via reflection on enums
```

> **Code walkthrough:** Enum Singleton is the canonical modern Java
> implementation. The JVM guarantees one instance per enum constant.
> It is safe against serialization (which can create a second instance
> by calling the constructor via `readObject` - Enum bypasses this).
> It is safe against reflection attacks (cannot invoke constructor
> on enums). The initialization runs once when the enum class is loaded.

```java
// GOOD: Holder idiom (preferred for lazy initialization)
public class HeavyResourceManager {
    private HeavyResourceManager() {
        // expensive initialization
    }

    // Inner class loaded only on first call to getInstance()
    private static class Holder {
        static final HeavyResourceManager INSTANCE =
            new HeavyResourceManager();
    }

    public static HeavyResourceManager getInstance() {
        return Holder.INSTANCE;
    }

    // In tests, use a separate instance via constructor
    // Better: inject through interface
}
```

> **Code walkthrough:** The Holder idiom exploits JVM class loading:
> `Holder` is loaded the first time `getInstance()` is called, and
> class loading is guaranteed to be thread-safe. No synchronization
> overhead on subsequent calls. The inner class is private so external
> code cannot instantiate `Holder` directly.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Singleton ensures only one instance of a class exists. You make the
> constructor private, hold the instance in a static field, and return
> it from a static `getInstance()` method. The naive version is not
> thread-safe. The best implementation for most cases is the Enum
> Singleton or the Holder idiom - both are thread-safe without explicit
> synchronization.

*Push deeper:* "In real Spring applications I rarely implement Singleton
manually - `@Bean`-annotated methods are singleton-scoped by default.
The DI container manages the single instance and injects it wherever
needed, which is cleaner than global access."

---

**Senior / Staff (5+ years):**
> Singleton is the most over-used GoF pattern in enterprise Java. What
> most code actually needs is a single shared instance managed by a DI
> container, not a class that polices its own uniqueness through a static
> field.
>
> The problems with classic Singleton: it is global mutable state,
> which makes tests order-dependent and hard to isolate. It holds a
> static reference, which in web applications can cause classloader
> leaks (the old class stays in memory even after a hot deploy). The
> DI container solves all of this: Spring's `@Bean` creates one instance
> per `ApplicationContext`, makes it injectable and mockable, and cleans
> it up with the context lifecycle.

*Push deeper:* "Enum Singleton is still valid for true constants that
have no mutable state and no lifecycle: configuration values, named
algorithm implementations, state machine transitions. For anything
with mutable state or lifecycle: use DI."

---

### ⚠️ Common Misconceptions

**Misconception 1: Singleton guarantees thread-safe single-instance creation automatically.**

The naive `if (instance == null) instance = new Singleton()` check has a race condition in multi-threaded environments: two threads can both pass the null check and create two instances. Thread-safe options: double-checked locking with a `volatile` field (Java), class-level initialization (Java's class loader guarantees single init), or the Initialization-on-demand holder idiom. In Java, the enum Singleton pattern is the safest - the JVM guarantees single initialization and prevents serialization attacks.

**Misconception 2: Singleton is appropriate whenever you need a single instance.**

Singleton makes testing nearly impossible: you cannot inject a mock implementation without modifying production code. It introduces global mutable state - any code anywhere can modify the singleton's state and affect every other user. "Single instance at runtime" is often better achieved through dependency injection (configure one instance in the DI container, inject it everywhere it's needed) which gives you the same runtime behavior with full testability and zero global state.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Singleton causes test pollution - test A's state affects test B.**

Symptom: tests pass in isolation but fail when run together; test execution order matters; debug reveals shared state in a static Singleton field. Root cause: Singleton persists state across tests because its lifecycle is tied to the JVM, not the test framework. Diagnosis: search for `static` fields holding mutable state; run tests in different orders and compare results. Fix: use dependency injection to inject a fresh instance per test; or add a `reset()` method to reinitialize state (common in legacy code migration).

**Failure Mode 2: Singleton prevents horizontal scaling in distributed systems.**

Symptom: singleton-stored state (cache, counter, session data) is inconsistent across application server instances; users see different data depending on which instance handles their request. Root cause: Singleton state is per-JVM; in a cluster of 5 servers, there are 5 independent singleton instances with divergent state. Diagnosis: identify any singleton that stores mutable data used across requests. Fix: move shared state to an external store (Redis, distributed cache); the singleton pattern itself is fine for stateless utilities (logger, config reader) but not for shared mutable state.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Singleton pattern?"
- "What makes the naive Singleton implementation non-thread-safe?"

🗣️ "Singleton restricts a class to one instance and provides a global
access point. The naive implementation: private constructor, static
instance field, static `getInstance()` that checks null. The thread-safety
issue: two threads can both see `instance == null` before either creates
the instance, resulting in two objects. The fix in modern Java: Enum
Singleton (leverages JVM guarantee of one enum instance), or the Holder
idiom (leverages class loading thread-safety), or double-checked locking
with `volatile`."

#### Mechanism
- "Explain double-checked locking. Why does it need `volatile`?"
- "How does the Holder idiom achieve thread safety without synchronization?"

🗣️ "Double-checked locking uses two null checks: one outside the
synchronized block (fast path for the common case when instance already
exists), one inside (race condition protection for first creation).
Without `volatile`, the Java memory model allows the JVM to publish a
partially-constructed object - Thread A assigns the reference before
completing construction; Thread B sees a non-null but half-initialized
object. `volatile` adds a happens-before guarantee that the write to
the reference only becomes visible after construction completes.
The Holder idiom avoids all this: the JVM class loading guarantee
says a class is initialized exactly once, before any thread can access
its static members. `Holder.INSTANCE` is initialized when the `Holder`
class is loaded, which happens only on the first call to `getInstance()`.
Zero synchronization needed."

#### Comparison
- "Compare Singleton vs Spring `@Bean` singleton scope."
- "When would you use Singleton pattern vs a static class?"

🗣️ "Singleton pattern and Spring singleton scope both produce one instance,
but the management differs. Classic Singleton: the class polices its own
uniqueness, global static access, no lifecycle management, hard to test.
Spring `@Bean`: the container manages uniqueness, injected via DI,
full lifecycle (init/destroy methods), easily mocked in tests by
swapping the bean. I prefer Spring singleton scope whenever a container
is available.
Singleton vs static class: a static class (all static methods, no
instantiation) is appropriate for pure utility functions with no state.
Singleton is appropriate when you need an instance with state, object
identity, or polymorphism (an interface the Singleton implements). If
you need to mock it or replace it - Singleton behind an interface, not
a static class."

#### Scenario
- "Design a logging framework using Singleton."
- "How do you handle Singleton in a multi-tenant application?"

🗣️ "For a logging framework: Enum Singleton holds the configuration
(log level, output target). Mutable state like the log queue: I would
avoid Singleton here and use a DI-managed single instance instead, so
tests can inject a no-op logger. For multi-tenant applications, classic
Singleton is almost always wrong: each tenant needs its own configuration,
own transaction context, own state. Per-tenant instances should be
managed by the DI container with tenant-scoped beans or stored in a
map keyed by tenant ID - not a static global."

#### Debugging
- "You suspect multiple instances of a 'Singleton' are being created.
  How do you investigate?"
- "A Singleton is holding stale data in production. How do you diagnose?"

🗣️ "For multiple instances: I add a unique ID (UUID assigned in the
constructor) logged at creation and at access time. If two different
IDs appear, two instances exist. Root causes: serialization (readObject
calls the constructor, bypassing private check), reflection (setAccessible
bypasses private), or classloader isolation (two classloaders each load
the class independently, creating one instance each - common in app
servers with per-webapp classloaders). For stale data: I check whether
the Singleton holds a reference to something that should be refreshed -
a cached configuration that was loaded at startup but not updated when
the file changed. Solution: add a refresh method, or use a TTL-based
cache rather than an eternal Singleton field."

#### Deep Dive
- "Why is Singleton considered an anti-pattern?"
- "How does the JVM class loader guarantee enable the Holder idiom?"

🗣️ "Singleton is an anti-pattern in most modern contexts because it is
global mutable state with a fancy name. Global state creates hidden
dependencies between components that share the instance: Component A
mutates the Singleton; Component B reads the mutated state; the
dependency is invisible in A's or B's constructor or method signatures.
This breaks encapsulation and makes reasoning about state difficult.
Testing is hard because tests share the global state and run
order-dependently. The fix is DI: make the dependency explicit.
The JVM classloader guarantee: the JVM specification (JLS 12.4) says
a class is initialized at most once, before the first active use. An
active use of `Holder` is accessing `Holder.INSTANCE`. The class
loader holds an initialization lock for `Holder` during initialization.
Any other thread trying to access `Holder` while initialization is in
progress blocks until initialization completes. No explicit synchronized
block needed."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Explain thread-safety of all three implementations; demonstrate volatile necessity. |
| Hiring Manager | "Singleton as global state causes testing problems - DI is the modern alternative." |
| Bar Raiser | "Where does Singleton fail in distributed or multi-classloader environments?" |
| Peer Engineer | "I replaced our manual Singletons with Spring-managed beans years ago. The tests became much cleaner." |

---

# Factory Method Pattern

---
id: DP-005
title: Factory Method Pattern
category: Design Patterns
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #design-patterns, #factory-method, #creational, #open-closed
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Factory Method is a Creational pattern that defines an interface for
> creating an object but lets subclasses decide which class to instantiate.
> The creator class calls a factory method instead of calling `new` directly.
> The result: you can add new types without modifying the creator. It
> implements the Open/Closed Principle for object creation.

**3 minutes (Senior):**
> The problem Factory Method solves: a class needs to create objects but
> should not be bound to the concrete class of those objects. For example,
> a cross-platform UI framework creates buttons, but whether it creates
> Windows buttons or Mac buttons depends on the platform - not on the
> button consumer.
>
> The structure: `Creator` has a `createProduct()` method (the factory
> method) that returns a `Product` interface. Concrete creators override
> `createProduct()` to return specific implementations. The creator's
> business logic uses the `Product` interface and never sees the concrete
> type.
>
> The production context: the pattern is widely used in Java standard
> library and Spring. `Calendar.getInstance()`, `NumberFormat.getInstance()`,
> `Logger.getLogger()` are all Factory Method variants. Spring's
> `BeanFactory.getBean()` is Abstract Factory. In Spring Data,
> `JpaRepositoryFactory` creates repository implementations without
> the caller knowing which concrete class.

**Blank Mind Recovery:**

**(1) Restate:** "Factory Method - the pattern where object creation
is delegated to a method that subclasses can override."

**(2) First principles:** "The problem: a class needs objects but
should not hard-code which class to instantiate. Solution: extract
the `new` call into a method that can be overridden."

**(3) Bridge:** "This is like a hiring agency: the company (Creator)
asks for a worker (Product) but the agency (factory method) decides
which specific worker to provide."

---

### 📘 Concept Explanation

**What it is:**
Factory Method defines a method for creating an object in a base class
or interface, allowing subclasses or implementations to control the
actual type of object created.

**The problem it solves:**
A class needs to create product objects but should be independent of
how those products are created, composed, and represented. The creation
logic changes across subclasses or configurations.

**How it works:**

```
Creator (abstract or interface)
  + factoryMethod(): Product    <-- returns interface
  + businessLogic():
      product = factoryMethod() <-- calls factory method
      product.doWork()          <-- uses interface only

ConcreteCreatorA extends Creator
  + factoryMethod(): ProductA   <-- creates specific type

ConcreteCreatorB extends Creator
  + factoryMethod(): ProductB   <-- creates different type

Product (interface)
  + doWork()

ProductA implements Product
ProductB implements Product
```

Data flow:
1. Client creates `ConcreteCreatorA` or `ConcreteCreatorB`
2. Calls `businessLogic()`
3. `businessLogic()` calls `factoryMethod()` - gets the right product
4. Uses `product.doWork()` through the interface
5. Never knows or cares which concrete `Product` it received

**The key insight:**
Factory Method moves the `new` keyword from the business logic into a
dedicated method. This single change makes the class open for extension
(add a new `ConcreteCreator`) and closed for modification (existing
`Creator` code unchanged). That is Open/Closed Principle applied to
object creation.

**When to use it:**
- When the exact type of object to create is determined by a subclass
  or configuration
- When you want to provide a way to extend the types a framework
  creates without modifying the framework
- When object creation logic is complex and should be isolated

**When NOT to use it:**
- When there is only one concrete type that never varies: plain `new`
  is simpler
- When the creation logic is trivial and adding an interface adds
  more complexity than it removes
- For simple value objects with no polymorphism

**Alternatives:**
- **Abstract Factory** - creates families of related objects (multiple
  factory methods together)
- **Builder** - step-by-step construction of a complex object
- **Spring `@Bean` / `@Configuration`** - factory methods managed by
  the DI container (the method annotated `@Bean` is a factory method)

**First-principles derivation:**
Given: a class calls `new ConcreteType()`. The problem: adding a new
type requires modifying this class. Solution: replace `new ConcreteType()`
with a method call `createProduct()`. Now subclasses can override
`createProduct()` to return different types. The parent class gains
extensibility without modification.

---

### 💻 Code Example

```java
// BAD: Creator knows the concrete type - hard to extend
public class OrderProcessor {
    public void process(Order order) {
        // Hard-coded: cannot add email notifier without modifying
        SmsNotifier notifier = new SmsNotifier();
        notifier.send(order.getConfirmationMsg());
    }
}
```

> **Code walkthrough:** Adding email or push notification means editing
> `OrderProcessor`. Every change risks breaking existing behavior.
> The class violates Open/Closed Principle.

```java
// GOOD: Factory Method - open for extension
public abstract class OrderProcessor {
    // Factory method: subclasses decide which notifier
    protected abstract Notifier createNotifier();

    // Business logic: uses interface only
    public void process(Order order) {
        Notifier notifier = createNotifier();
        notifier.send(order.getConfirmationMsg());
    }
}

public interface Notifier {
    void send(String message);
}

public class SmsOrderProcessor extends OrderProcessor {
    protected Notifier createNotifier() {
        return new SmsNotifier(config.smsApiKey());
    }
}

public class EmailOrderProcessor extends OrderProcessor {
    protected Notifier createNotifier() {
        return new EmailNotifier(config.smtpHost());
    }
}
```

> **Code walkthrough:** `OrderProcessor.process()` never calls `new`
> directly. It calls `createNotifier()` which is overridden by each
> subclass. Adding push notifications: create `PushOrderProcessor`,
> override `createNotifier()`, zero changes to `OrderProcessor`. The
> factory method is the only variation point; business logic is
> reused unchanged across all subclasses.

```java
// PRODUCTION: Spring @Bean as factory method
@Configuration
public class NotifierConfig {

    @Bean  // This IS a Factory Method
    public Notifier notifier(
            @Value("${notify.channel}") String channel) {
        return switch (channel) {
            case "sms"   -> new SmsNotifier(smsProperties());
            case "email" -> new EmailNotifier(emailProperties());
            case "push"  -> new PushNotifier(pushProperties());
            default -> throw new IllegalArgumentException(
                "Unknown channel: " + channel);
        };
    }
}

// Injected wherever needed - caller does not know the type
@Service
public class OrderService {
    private final Notifier notifier; // injected by Spring

    public OrderService(Notifier notifier) {
        this.notifier = notifier;
    }
}
```

> **Code walkthrough:** Spring `@Bean` methods are factory methods.
> The `notifier()` method decides which concrete `Notifier` to create
> based on configuration. Callers inject `Notifier` - they never
> know whether it is `SmsNotifier`, `EmailNotifier`, or `PushNotifier`.
> Adding a new channel: add a case to the factory method, no changes
> elsewhere. This is the practical production form of Factory Method.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Factory Method is a pattern where a class has a method for creating
> objects, and subclasses override that method to decide which specific
> type to create. Instead of `new ConcreteClass()` in the business logic,
> you call `createProduct()` and let the subclass fill in the type. It
> makes it easy to add new types without changing the existing code.

*Push deeper:* "In Spring, `@Bean` methods are essentially factory
methods: the method returns an interface, the configuration decides
which implementation to create, and callers inject the interface type
without knowing the concrete class."

---

**Senior / Staff (5+ years):**
> Factory Method implements Open/Closed Principle for object creation:
> the `Creator` class is closed for modification and open for extension
> through subclassing or configuration. The practical production form
> is the Spring `@Configuration` class: a `@Bean` method is a factory
> method that decides which implementation to instantiate based on
> properties or environment.
>
> The subtlety: Factory Method is about a single type hierarchy. When
> you need to create families of related objects - "create a Windows
> Button AND a Windows Dialog AND a Windows Checkbox" - that is Abstract
> Factory: a group of factory methods together. The distinction matters
> when designing plugin architectures or cross-platform frameworks.

*Push deeper:* "The ServiceLoader API in Java SE is Factory Method at
the JVM level: `ServiceLoader.load(NotificationService.class)` returns
implementations found on the classpath via `META-INF/services`. The
factory method is the classloader mechanism itself."

---

### ⚠️ Common Misconceptions

**Misconception 1: Factory Method requires a separate Factory class.**

Factory Method is a method in the creator class that subclasses override to create different product types - the factory logic IS the method, not a separate class. A `Document.createPage()` method that `Resume` overrides to return `ResumePage` and `Report` overrides to return `ReportPage` IS Factory Method. A standalone `PaymentFactory` class with a `createPayment(type)` method is actually Simple Factory or Static Factory - a different (simpler, non-GoF) pattern.

**Misconception 2: Factory Method and Abstract Factory are the same pattern with different names.**

Factory Method creates ONE product through method overriding in subclasses. Abstract Factory creates FAMILIES of related products through a factory interface. If you need to create just `Button`, use Factory Method. If you need to create `Button + Checkbox + TextField` that must all be from the same UI theme (Windows vs Mac), use Abstract Factory. The key distinction: Abstract Factory coordinates the creation of multiple related objects; Factory Method defers creation of a single product type to a subclass.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Factory method bypassed by direct instantiation in client code.**

Symptom: new product types added to the factory are not used by all clients; some code still uses `new ConcreteProduct()` directly; switch to a new product type requires finding and changing all direct instantiation sites. Root cause: the factory method contract is not enforced - client code depends directly on concrete classes rather than the creator hierarchy. Diagnosis: grep for `new ConcreteProduct` in client code; verify that the creator and product hierarchies are used consistently. Fix: make `ConcreteProduct` package-private or use a module system to prevent direct instantiation outside the factory; enforce via code review.

**Failure Mode 2: Creator class becomes overloaded with unrelated factory methods.**

Symptom: the "creator" class has dozens of factory methods for unrelated product types; the class violates Single Responsibility Principle and becomes a God Object. Root cause: Factory Method pattern extended beyond its intended scope - each product family should have its own creator hierarchy. Diagnosis: count distinct product families in the creator; if there are more than 2-3, the pattern is being misapplied. Fix: extract separate creator hierarchies per product family or switch to Abstract Factory.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Factory Method pattern?"
- "What problem does it solve that plain `new` does not?"

🗣️ "Factory Method defines an interface for creating an object but
lets subclasses or implementations decide which concrete class to
instantiate. Plain `new` hard-codes the type: adding a new type requires
modifying the calling code. Factory Method extracts the `new` into an
overridable method: adding a new type means creating a new subclass or
implementation, with zero changes to the existing creator code. This is
the Open/Closed Principle applied specifically to object creation."

#### Mechanism
- "Walk me through the class structure of Factory Method."
- "How does the client use Factory Method without knowing the concrete type?"

🗣️ "The structure has four roles. Creator: the abstract class or
interface with the factory method, returns a Product interface, contains
business logic that uses the Product. ConcreteCreator: overrides the
factory method to return a specific ConcreteProduct. Product: the
interface that all created objects implement. ConcreteProduct: the
actual implementation. The client creates a ConcreteCreator and calls
the business logic method. The business logic calls the factory method
internally, gets a Product interface, uses it - never knowing the
concrete type."

#### Comparison
- "Compare Factory Method vs Abstract Factory."
- "Compare Factory Method vs Builder."

🗣️ "Factory Method creates a single product type via method override.
Abstract Factory creates a family of related product types via a group
of factory methods - you create an `AbstractFactory` for a whole
platform (WindowsFactory or MacFactory) that produces all the related
UI components consistently. Use Factory Method when one variable product
is needed; use Abstract Factory when a consistent family of related
products is needed.
Factory Method vs Builder: Factory Method creates the object in a
single method call (returns a Product). Builder assembles a complex
object step by step across multiple method calls before calling `build()`.
Use Factory Method for polymorphism across creation; use Builder for
configuring a complex object with many optional parts."

#### Scenario
- "How would you use Factory Method to support multiple payment providers?"

🗣️ "I would define a `PaymentProcessor` interface with a `charge()`
method. The factory method `createPaymentProcessor(config)` returns the
right implementation based on the payment configuration: Stripe, PayPal,
or Braintree. In Spring, this is a `@Bean` method in `PaymentConfig`:
it reads `payment.provider` from configuration and instantiates the
correct class. The `OrderService` injects `PaymentProcessor` and calls
`charge()` without any knowledge of which provider is active. Adding a
fourth provider: create the implementation class, add a case to the
factory method, no changes to `OrderService`."

#### Debugging
- "The wrong type of object is being created by the factory method.
  How do you investigate?"

🗣️ "I start by logging the return value's class name in the factory
method: `log.debug('Created: {}', product.getClass().getName())`.
If the wrong type is returned: check the factory method's decision
logic (is the configuration value being read correctly?) and the
class loading (in web applications, is the correct version of the
class on the classpath?). A common bug in Spring: a `@Bean` method
is in a `@Configuration` class that is not in the component scan
path, so Spring falls back to a default factory method elsewhere.
I verify the active `@Bean` method by checking `applicationContext
.getBeanDefinition('notifier').getBeanClass()`."

#### Deep Dive
- "Where does Factory Method appear in the Java standard library?"
- "How does Factory Method relate to the Open/Closed Principle?"

🗣️ "Factory Method is everywhere in the Java standard library.
`Calendar.getInstance()` returns a `GregorianCalendar` or a
`JapaneseImperialCalendar` depending on locale - you call the factory
method and get the right type without knowing which.
`NumberFormat.getInstance(locale)` returns a locale-specific formatter.
`Logger.getLogger(name)` returns a logger from the configured logging
framework. These are static factory methods rather than inherited ones,
but the pattern - caller requests a product, factory decides the type -
is the same.
Relationship to Open/Closed: the Creator class has a template method
(business logic) that calls the factory method. The template method
never changes. The factory method is the extension point: adding a
new product type means adding a new subclass (open for extension),
not modifying the existing Creator (closed for modification)."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Draw the class diagram; explain why the Creator is open for extension, closed for modification. |
| Hiring Manager | "Factory Method is how we support multiple payment providers without touching the order processing logic." |
| Bar Raiser | "Where does Factory Method appear in Spring? How does @Bean relate to this pattern?" |
| Peer Engineer | "I use @Bean factory methods constantly. The pattern is baked into Spring's design philosophy." |

---

# Builder Pattern

---
id: DP-006
title: Builder Pattern
category: Design Patterns
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: all
tags: #design-patterns, #builder, #creational, #fluent-api
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Builder separates the construction of a complex object from its
> representation, allowing the same construction process to create
> different representations. In Java, it most commonly appears as the
> fluent builder: a nested class with setter methods that return `this`,
> culminating in a `build()` method. It solves the telescoping constructor
> problem: a class with many optional fields would need an exponential
> number of constructors.

**3 minutes (Senior):**
> The classic Builder separates the builder object from the director:
> a `Director` controls the build sequence by calling methods on a
> `Builder` interface; different `ConcreteBuilder` implementations
> produce different products. This is how HTML parsers work: the same
> HTML parsing director calls builder methods that produce either a
> DOM tree or a plain-text document.
>
> In practice, the simplified fluent Builder is far more common in
> Java: `Person.builder().name("Alice").age(30).build()`. No Director,
> no Builder interface - just a nested class with method chaining.
> Lombok's `@Builder` generates this automatically.
>
> The key production benefit: it enforces required fields at the `build()`
> call rather than at construction, and it makes code that creates
> objects with many optional fields readable and self-documenting.

**Blank Mind Recovery:**

**(1) Restate:** "Builder - the pattern for constructing complex objects
step by step."

**(2) First principles:** "Problem: a class with 10 optional fields
needs constructors for every combination, or a constructor with 10
parameters where the caller must remember the order. Solution: a
builder object that accumulates settings, then produces the final
object."

**(3) Bridge:** "Like filling out a form: you fill each field you need,
leave others blank, then submit. The submit button is `build()`."

---

### 📘 Concept Explanation

**What it is:**
Builder separates object construction from the object's final form,
using a separate builder object to accumulate construction parameters
step by step before creating the product.

**The problem it solves:**
Classes with many parameters - especially many optional ones - create
two problems. Telescoping constructors: you need a constructor for
every parameter combination. Positional confusion: calling
`new Person("Alice", 30, true, false, null, "NYC", "")` - which
boolean is which? Builder names each step, making construction
readable and safe.

**How it works:**

```
Simple fluent builder (most common in Java):

  Person person = Person.builder()
      .name("Alice")       // required
      .age(30)             // required
      .city("New York")    // optional
      .newsletter(true)    // optional
      .build();            // validates and constructs

Structure:
  Product: the object being built (Person, HttpRequest, etc.)
  Builder (nested class or separate):
      - fields for all parameters
      - setter methods returning Builder (for chaining)
      - build() method: validates, creates Product

GoF full Builder (two-class form):
  Builder interface: abstract steps (buildWalls(), buildRoof())
  ConcreteBuilder: implements steps for specific product type
  Director: controls the sequence of builder calls
  Product: the constructed object
```

**The key insight:**
Builder separates WHAT is needed (the parameters) from HOW it is
assembled. This lets you make the assembly sequence explicit, validate
before constructing, and create objects that are immutable after `build()`
(all fields set in the constructor from the builder, no setters).

**When to use it:**
- Classes with 4+ constructor parameters, especially optional ones
- When you want to create immutable objects without telescoping constructors
- When multiple representations of the same data are needed (same build
  process, different concrete types)
- When construction is a multi-step process that should be checkpointed

**When NOT to use it:**
- Objects with 2-3 required fields: a plain constructor is cleaner
- Value objects where record classes (Java 16+) suffice
- When all fields are required: a constructor with named parameters
  (Kotlin) or a compact record (Java) is simpler

**Alternatives:**
- **Constructor with named parameters** (Kotlin data class,
  Java record) - cleaner for small objects
- **`@Builder` (Lombok)** - generates the Builder automatically from
  field annotations, preferred in production Java code
- **Prototype** - copy an existing object and mutate the copy

**First-principles derivation:**
Given: an object with N optional fields. Options: (A) N! constructors
(factorial growth, unusable). (B) setters on the object - makes it
mutable, inconsistent state possible. (C) Builder object that
accumulates parameters, then creates an immutable product. Option C
is the Builder.

---

### 💻 Code Example

```java
// BAD: telescoping constructors
public class HttpRequest {
    public HttpRequest(String url) { ... }
    public HttpRequest(String url, String method) { ... }
    public HttpRequest(String url, String method,
                       Map<String,String> headers) { ... }
    public HttpRequest(String url, String method,
                       Map<String,String> headers,
                       String body) { ... }
    // ...grows exponentially with optional fields
}
```

> **Code walkthrough:** Every time a new optional field is added, the
> number of constructors required grows. Callers face positional
> confusion. The anti-pattern escalates: teams start adding `null`
> to skip parameters - `new HttpRequest(url, "GET", null, null)` -
> which is unreadable and fragile.

```java
// GOOD: Fluent Builder
public class HttpRequest {
    private final String url;       // required
    private final String method;    // required
    private final Map<String, String> headers;  // optional
    private final String body;      // optional
    private final int timeoutMs;    // optional, default 5000

    private HttpRequest(Builder builder) {
        this.url = builder.url;
        this.method = builder.method;
        this.headers = Map.copyOf(builder.headers);
        this.body = builder.body;
        this.timeoutMs = builder.timeoutMs;
    }

    // Immutable after build: no setters exposed

    public static Builder builder(String url, String method) {
        return new Builder(url, method);
    }

    public static class Builder {
        private final String url;
        private final String method;
        private Map<String, String> headers = new HashMap<>();
        private String body;
        private int timeoutMs = 5000;

        private Builder(String url, String method) {
            Objects.requireNonNull(url, "url required");
            Objects.requireNonNull(method, "method required");
            this.url = url;
            this.method = method;
        }

        public Builder header(String key, String value) {
            this.headers.put(key, value);
            return this;
        }

        public Builder body(String body) {
            this.body = body;
            return this;
        }

        public Builder timeoutMs(int ms) {
            this.timeoutMs = ms;
            return this;
        }

        public HttpRequest build() {
            if ("POST".equals(method) && body == null) {
                throw new IllegalStateException(
                    "POST requires a body");
            }
            return new HttpRequest(this);
        }
    }
}

// Usage - self-documenting, readable:
HttpRequest req = HttpRequest.builder("https://api.example.com", "POST")
    .header("Content-Type", "application/json")
    .body("{\"key\":\"value\"}")
    .timeoutMs(3000)
    .build();
```

> **Code walkthrough:** Four patterns in this builder. (1) Required
> fields passed to the `Builder` constructor, not via setters -
> you cannot create a builder without them. (2) Optional fields
> have defaults set in the `Builder` field declarations. (3) `build()`
> validates business rules (POST requires body) before constructing.
> (4) `HttpRequest` is immutable: the private constructor sets all
> fields from the builder; no setters exist. This is the production
> standard for complex value objects in Java.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Builder solves the problem of objects with many parameters. Instead
> of a constructor with 10 arguments where you have to remember the
> order, you use a builder: call setter methods named after each field,
> then call `build()`. In Java, Lombok's `@Builder` annotation generates
> the builder class automatically - I use that in production rather
> than writing the boilerplate by hand.

*Push deeper:* "The build() method can validate that required fields
are set and that business rules are satisfied before creating the
object. That is an advantage over constructors where you can call them
in any combination."

---

**Senior / Staff (5+ years):**
> The two problems Builder solves: telescoping constructors and
> positional confusion. But the deeper benefit is enabling immutable
> objects with optional fields. Once `build()` returns, the object is
> fully constructed and has no setters - it can be safely shared across
> threads.
>
> In production Java I use Lombok `@Builder` with `@NonNull` to mark
> required fields. The generated builder throws a `NullPointerException`
> on `build()` if required fields are null. For domain objects where I
> need to validate business rules (not just null checks), I write the
> `build()` method manually.

*Push deeper:* "The GoF full Builder pattern (with Director and Builder
interface) is less common in practice. You encounter it in XML/HTML
parsers (SAX parser pattern) and in test data builders where a Director
builds standard test scenarios. The two-class form is worth knowing for
interviews even if the simpler fluent form is what you use day-to-day."

---

### ⚠️ Common Misconceptions

**Misconception 1: Builder is only needed for objects with many optional parameters.**

Builder's primary purpose is to separate complex object CONSTRUCTION from REPRESENTATION - enabling the same construction process to produce different representations. The "many optional parameters" use case (Effective Java Item 2) is one application, but Builder also handles: multi-step object construction with validation at each step, building immutable objects with complex initialization, and creating objects where construction steps must occur in a specific order. Conflating Builder with "constructor with many arguments" misses the pattern's broader applicability.

**Misconception 2: Using a Builder always produces an immutable object.**

Builder is a construction mechanism, not an immutability guarantee. The built object can be mutable or immutable depending on whether you provide setters. Lombok's `@Builder` generates a builder for classes that may still have setters. The decision to make the built object immutable is separate from the decision to use Builder for construction. When you do want immutability, Builder + final fields + no setters is a common and effective combination.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Builder allows building invalid objects by not validating at build() time.**

Symptom: objects created with the builder have null required fields or invalid state combinations; NullPointerExceptions occur at usage time, far from the construction site. Root cause: the `build()` method does not validate that required fields were set and that field combinations are consistent. Diagnosis: trace back NullPointerException stack traces to builder-created objects; check which fields have no explicit null check in `build()`. Fix: add precondition checks in `build()`: `Objects.requireNonNull(requiredField, "requiredField must not be null")`; throw `IllegalStateException` for invalid combinations.

**Failure Mode 2: Builder is not thread-safe when shared across threads.**

Symptom: intermittent null fields or data from different builder calls mixed together; occurs only under concurrent load. Root cause: a single Builder instance is shared across multiple threads - each thread calls setter methods concurrently, mixing each other's values. Diagnosis: check for static Builder instances or Builder objects stored in shared state; add thread-safety analysis. Fix: Builders are inherently not thread-safe and should not be shared. Create a new Builder instance per object construction call.

---

### 🎯 Interview Deep-Dive

#### Definition
- "What is the Builder pattern?"
- "What problem does it solve that constructors cannot?"

🗣️ "Builder separates the construction of a complex object from its
representation. The problem it solves: constructors do not scale when
a class has many optional parameters. Four parameters is manageable;
ten parameters creates a combinatorial explosion of constructor overloads
and forces callers to pass null for unused parameters. Builder names
each step explicitly, making the construction readable, and validates
completeness in `build()` before the object exists."

#### Mechanism
- "Walk me through the structure of a fluent Builder."
- "How does Builder enable immutable objects?"

🗣️ "The fluent Builder has a nested static class with fields matching
the product's fields. Setter methods on the builder return `this`,
enabling chaining. Required fields are typically set in the builder's
constructor. The `build()` method validates and calls the product's
private constructor with the builder as the argument. The product has
no public setters - all fields are final and set in the constructor
from the builder's values. Immutability is guaranteed: once `build()`
returns, no mutation is possible."

#### Comparison
- "Compare Builder vs Prototype."
- "When do you use Builder vs Lombok `@Builder`?"

🗣️ "Builder creates an object from scratch by accumulating parameters.
Prototype copies an existing object and modifies the copy - useful when
creation is expensive and you need many similar objects with small
variations. For objects with expensive initialization (large caches,
parsed configurations), Prototype is more efficient.
Lombok `@Builder` generates the boilerplate builder code at compile
time. I use `@Builder` for straightforward cases. I write the builder
manually when I need custom validation in `build()`, non-trivial defaults,
or a public API where the builder signature must be stable across
releases (Lombok's generated code changes if field names change)."

#### Scenario
- "Design an HTTP client configuration object using Builder."
- "How would you implement a test data builder for complex domain objects?"

🗣️ "For test data builders, I use the Builder pattern with sensible
defaults: `PersonBuilder.aValidPerson()` returns a builder with all
fields pre-filled with valid test data. Tests then override only the
field they care about: `PersonBuilder.aValidPerson().withAge(-1).build()`
to test age validation. This keeps tests focused on the variable under
test and prevents brittle tests that break when unrelated fields are
added to the class. The 'object mother' pattern extends this: a factory
class that returns pre-configured builders for common test scenarios."

#### Debugging
- "A Builder produces an object with default values instead of the
  values set by the caller. How do you diagnose?"

🗣️ "I check three common causes. First: the builder is not returned
from each setter method - a setter might not return `this`, breaking
the chain silently (the chain continues but on the wrong builder
reference). Second: the field is being set on the builder but not
copied to the product in the product's constructor - check that the
constructor reads `builder.fieldName`. Third: the product's field is
being set to a default in the product's constructor before reading
the builder value - order matters. I add debug logging in the product's
constructor to log all field values as received."

#### Deep Dive
- "How does Builder relate to the GoF Director concept?"
- "Compare Java Builder with Kotlin's named parameters and default values."

🗣️ "In the GoF full form, the Director encodes the construction
sequence: it calls `builder.buildWall()`, `builder.buildDoor()`,
`builder.buildRoof()` in a specific order. The Director knows the
'recipe' for constructing standard configurations; the Builder
knows how to create each component. In practice I see this in
parsers: the SAX parser is a Director that calls methods on a
ContentHandler (Builder interface) as it parses XML. The caller
registers a concrete ContentHandler to produce whatever output
they need.
Kotlin named parameters with defaults largely replace the need
for Builder in that language: `Person(name = 'Alice', age = 30)`.
No extra class needed. For immutability, Kotlin data classes with
`copy()` replace Prototype. Java gets closer with records (Java 14+)
but records cannot have optional fields with defaults in the same
way, so Builder remains necessary for complex construction in Java."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Implement a fluent Builder with required field validation; explain how immutability is achieved. |
| Hiring Manager | "Builder makes object construction readable and self-documenting in our codebase." |
| Bar Raiser | "Compare Lombok @Builder to hand-written Builder. When does the generated version fall short?" |
| Peer Engineer | "I always add aValidXxx() static factory methods to test builders for default scenarios." |
