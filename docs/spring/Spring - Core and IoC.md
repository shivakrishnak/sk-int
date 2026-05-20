---
layout: default
title: "Spring - Core and IoC"
parent: "Spring"
grand_parent: "Interview Mastery"
nav_order: 2
permalink: /interview/spring/core-and-ioc/
topic: Spring
subtopic: Core and IoC
keywords:
  - IoC Container and Dependency Injection
  - ApplicationContext
  - Bean Lifecycle
  - Bean Scopes
  - Circular Dependencies
difficulty_range: easy to medium
status: complete
version: 3
---

**Keywords covered in this file:**

- [IoC Container and Dependency Injection](#ioc-container-and-dependency-injection)
- [ApplicationContext](#applicationcontext)
- [Bean Lifecycle](#bean-lifecycle)
- [Bean Scopes](#bean-scopes)
- [Circular Dependencies](#circular-dependencies)

# IoC Container and Dependency Injection

**TL;DR** - The framework creates and wires all objects instead of your code doing it, giving you loose coupling, testability, and runtime flexibility for free.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every class creates its own dependencies: `new UserRepository(new DataSource(new ConnectionPool(...)))`. Changes cascade everywhere. Testing requires rewriting construction logic. Swapping implementations requires modifying every consumer.

**THE BREAKING POINT:**
Switching from MySQL to PostgreSQL requires changing 47 files that construct `MySqlDataSource`. Unit testing a service requires standing up a full database because the service directly instantiates the repository.

**THE INVENTION MOMENT:**
"This is exactly why IoC and Dependency Injection were created."

**EVOLUTION:**
Direct construction (`new`) -> Factory Pattern -> Service Locator -> Dependency Injection (Spring 2003) -> CDI (Java EE 6) -> Spring Boot auto-configuration (2014).

---

### 📘 Textbook Definition

**Inversion of Control (IoC)** is a design principle where the framework controls object creation and lifecycle, inverting the traditional flow where application code manages everything. **Dependency Injection (DI)** is the mechanism that implements IoC: dependencies are provided to an object from outside (via constructor, setter, or field) rather than created internally. Spring's IoC container resolves the complete dependency graph and injects all collaborators automatically at startup.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
You declare what you need; Spring creates it and hands it to you.

**One analogy:**

> Ordering at a restaurant instead of cooking. You say "I want pasta" (declare a dependency), the kitchen (container) prepares it, and the waiter (DI) brings it to your table. You never enter the kitchen.

**One insight:**
DI does not eliminate dependencies - it externalizes them. Your class still NEEDS a repository; it just does not know the concrete implementation or how it was created. This is why swapping, mocking, and reconfiguring become trivial.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. An object never creates its own collaborators. The container is the sole authority for creation, wiring, and lifecycle.
2. Dependencies are declared, not resolved. A bean states what it needs (constructor parameters), never how to find it.
3. The container builds a complete dependency graph before any bean is used. If the graph is unsatisfiable, startup fails immediately.

**DERIVED DESIGN:**
From invariant 1: all objects are container-managed beans, enabling proxy interception (AOP, transactions). From invariant 2: swapping implementations requires only configuration, not code changes. From invariant 3: production never encounters a missing-dependency error after a successful startup.

**THE TRADE-OFFS:**

**Gain:** Loose coupling, testability (inject mocks via constructor), runtime flexibility (swap beans via profiles).

**Cost:** Indirection (hard to trace "who created this?"), startup time (entire graph resolved eagerly), hidden magic (annotations obscure wiring from newcomers).

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Any non-trivial application needs a central registry of objects and their relationships - something must wire collaborators.

**Accidental:** XML configuration (Spring 1.x/2.x) was accidental complexity eliminated by annotations and Java config. Component scanning magic is accidental but widely accepted.

---

### 🧠 Mental Model / Analogy

> A casting director on a movie set. Actors (beans) never recruit their own co-stars. The casting director (container) reads the script (configuration), assigns every role (@Component, @Service), and ensures each actor meets their co-stars (dependencies) before filming begins. If a role is unfilled, the director halts production (startup failure) rather than discovering mid-scene.

- "Casting director" -> ApplicationContext
- "Script" -> @Configuration classes + component scanning
- "Actors" -> Bean instances
- "Co-stars" -> Constructor-injected dependencies
- "Halting production" -> BeanCreationException at startup

Where this analogy breaks down: Real directors do not manage actor lifecycles through destruction callbacks.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Instead of each part of your program creating the other parts it needs, a central manager creates everything and connects them together. If something is missing, the manager tells you immediately rather than letting you discover it later.

**Level 2 - How to use it (junior developer):**

```java
@Service
public class OrderService {
    private final OrderRepo repo;
    private final PaymentGateway pay;

    // Spring injects both automatically
    public OrderService(
            OrderRepo repo,
            PaymentGateway pay) {
        this.repo = repo;
        this.pay = pay;
    }
}
```

Single constructor = auto-wired since Spring 4.3. No `@Autowired` needed.

**Level 3 - How it works (mid-level engineer):**

Spring's DI resolution:

1. Component scan finds `@Component`/`@Service`/`@Repository`
2. BeanDefinition created for each (metadata)
3. Dependency graph resolved (topological sort)
4. Beans instantiated in dependency order
5. Dependencies injected via constructor
6. BeanPostProcessors run (AOP proxies created)
7. `@PostConstruct` callbacks invoked

Three injection types:

```java
// 1. Constructor (PREFERRED - immutable)
@Service
public class UserService {
    private final UserRepo repo;
    public UserService(UserRepo repo) {
        this.repo = repo;
    }
}

// 2. Setter (optional dependencies only)
@Autowired(required = false)
public void setCache(CacheManager c) {
    this.cache = c;
}

// 3. Field (AVOID - untestable)
@Autowired
private UserRepo repo; // can't mock easily
```

**Level 4 - Mastery (senior/staff+ engineer):**

Why constructor injection wins:

1. Fields are `final` (immutable, thread-safe)
2. Object fully initialized after constructor
3. Testable without Spring: `new Service(mockRepo)`
4. Dependency explosion visible (too many args = SRP violation)
5. Circular deps fail fast at startup

Resolution algorithm:

- By type first -> if ambiguous: `@Qualifier` -> then name -> `@Primary` wins -> else startup fails

**The Senior-to-Staff Leap:**

**A Senior says:** "Always use constructor injection because it makes beans immutable and testable."

**A Staff says:** "I design module boundaries around DI contexts. Each bounded context owns a `@Configuration`, exposes only interface-typed beans, and I use `@ComponentScan` filters to enforce architectural layering. For serverless, I switch to programmatic registration or Spring AOT to cut reflection."

**The difference:** Staff engineers wield DI as an architectural boundary tool, not just a wiring convenience.

**Level 5 - Distinguished (expert thinking):**
DI containers are the Hollywood Principle ("don't call us, we'll call you") recurring across all frameworks: React props flow down, Kubernetes controllers reconcile desired state, event-driven handlers register rather than poll. If redesigning Spring today, compile-time DI (Dagger, Micronaut) would replace reflection entirely - type safety and startup speed outweigh minor flexibility loss. At extreme scale (5000+ beans), custom `BeanFactoryPostProcessor`s enforce naming conventions, detect unused beans, and auto-wire cross-cutting concerns without polluting business code.

---

### ⚙️ How It Works

```
  @SpringBootApplication.main()
       |
  SpringApplication.run()
       |
  Create ApplicationContext
       |
  Component scan: find @Component,
  @Service, @Repository, @Controller
       |
  Build BeanDefinitions
  (class, scope, dependencies)
       |
  Resolve dependency graph
  (topological sort)
       |
  Instantiate in dependency order
       |
  Inject via constructor
       |
  BeanPostProcessors run
  (AOP proxies, @Transactional)
       |
  @PostConstruct callbacks
       |
  ApplicationContext READY
```

Internally, `DefaultListableBeanFactory` stores metadata in `ConcurrentHashMap<String, BeanDefinition>` and caches singletons in `ConcurrentHashMap<String, Object>`. Bean lookup is O(1). On first request for a missing singleton, the factory resolves dependencies recursively, instantiates, wraps in proxies (CGLIB or JDK dynamic), and caches the result.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  JVM starts
       |
  SpringApplication.run()
       |
  Environment prepared
  (profiles, properties)
       |
  ApplicationContext created <- HERE
       |
  Beans instantiated + wired
       |
  ApplicationReadyEvent
       |
  HTTP requests served by
  injected controller beans
```

**FAILURE PATH:**
Missing bean -> `NoSuchBeanDefinitionException` at startup. Ambiguous bean -> `NoUniqueBeanDefinitionException`. Circular constructor dep -> `BeanCurrentlyInCreationException`. All fail-fast: app never starts in an invalid state.

**WHAT CHANGES AT SCALE:**
At 100 beans: startup < 1s. At 1000 beans: 3-8s, scanning dominates. At 5000+ beans: 30-60s, teams split into multiple contexts or migrate to Spring AOT (compile-time graph, 50-80% faster startup).

---

### 💻 Code Example

**Example 1 - BAD field injection vs GOOD constructor injection:**

```java
// BAD - field injection
@Service
public class PaymentService {
    @Autowired
    private PaymentGateway gateway;
    @Autowired
    private AuditLogger logger;
    // Can't make fields final
    // Can't instantiate without Spring
    // Can't inject mocks easily
}

// GOOD - constructor injection
@Service
public class PaymentService {
    private final PaymentGateway gateway;
    private final AuditLogger logger;

    public PaymentService(
            PaymentGateway gateway,
            AuditLogger logger) {
        this.gateway = gateway;
        this.logger = logger;
    }
}

// Test without Spring:
@Test
void testPayment() {
    var svc = new PaymentService(
        mockGateway, mockLogger);
    svc.process(order);
    verify(mockGateway).charge(order);
}
```

**Example 2 - Disambiguating multiple implementations:**

```java
interface PaymentGateway {}

@Component
class StripeGateway
        implements PaymentGateway {}

@Primary          // wins by default
@Component
class PayPalGateway
        implements PaymentGateway {}

// Option A: @Primary wins automatically
@Service
class CheckoutService {
    CheckoutService(PaymentGateway gw) {
        // PayPalGateway injected
    }
}

// Option B: @Qualifier for explicit choice
@Service
class RefundService {
    RefundService(
        @Qualifier("stripeGateway")
        PaymentGateway gw) {
        // StripeGateway injected
    }
}

// Option C: inject all implementations
@Service
class GatewayRouter {
    GatewayRouter(
        List<PaymentGateway> all) {
        // [StripeGateway, PayPalGateway]
    }
}
```

**How to test / verify correctness:**
Write a `@SpringBootTest` that asserts the correct bean is injected. For unit tests, construct the service directly with mocks - no container needed.

---

### 📌 Quick Reference Card

**WHAT IT IS:** A container that creates, wires, and manages all application objects using dependency injection.

**PROBLEM IT SOLVES:** Eliminates hard-coded `new` calls, making code loosely coupled and testable.

**KEY INSIGHT:** DI externalizes dependencies - classes declare needs without knowing implementations.

**USE WHEN:** Any Spring application. It is the default architecture.

**AVOID WHEN:** Tiny scripts or performance-critical hot paths where container overhead matters.

**ANTI-PATTERN:** Field injection - hides dependencies, prevents `final` fields, breaks testability.

**TRADE-OFF:** Loose coupling and testability vs. indirection and startup cost.

**ONE-LINER:** "Declare what you need; the container provides it."

**KEY NUMBERS:** Singleton scope default. Auto-wired single constructor since 4.3. ~1ms/bean startup.

**TRIGGER PHRASE:** "Framework creates and wires all dependencies."

**OPENING SENTENCE:** "IoC inverts object creation from your code to the Spring container, which uses DI to inject collaborators at construction time - enabling loose coupling, testability, and runtime flexibility."

**If you remember only 3 things:**

1. IoC = framework controls creation; DI = framework injects dependencies
2. Always constructor injection (immutable, testable, explicit)
3. Spring resolves by type -> qualifier -> name -> @Primary

**Interview one-liner:**
"IoC inverts who creates objects - the container, not your code. DI is the mechanism: constructor injection preferred for immutability and testability. Spring resolves the full graph at startup, failing fast on any missing or ambiguous dependency."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Draw the DI resolution flow (scan -> BeanDefinition -> topological sort -> instantiate -> inject -> proxy) on a whiteboard in 2 minutes
2. **DEBUG:** Given `NoSuchBeanDefinitionException`, trace to the missing `@Component` or wrong `@ComponentScan` base package in under 60 seconds
3. **DECIDE:** Choose constructor vs setter vs `@Bean` method injection for a given scenario with clear rationale
4. **BUILD:** Configure a multi-module app with per-module `@Configuration`, `@Import`, and `@ComponentScan` filters enforcing layer boundaries
5. **EXTEND:** Apply the DI principle to non-Spring systems (React context, Terraform modules, Kubernetes operator pattern)

---

### 💡 The Surprising Truth

Since Spring 4.3, a class with exactly one constructor gets its dependencies injected automatically - no `@Autowired`, no `@Inject`, nothing. Most developers still add `@Autowired` out of habit, but it is redundant. The cleanest Spring service class has zero Spring annotations on its body: just a plain Java class with a constructor. The only Spring annotation needed is `@Service` (or `@Component`) on the class declaration for scanning.

---

### ⚖️ Comparison Table

| Dimension  | Spring DI            | CDI (Jakarta)     | Guice           | Dagger           |
| ---------- | -------------------- | ----------------- | --------------- | ---------------- |
| Resolution | Runtime (reflection) | Runtime           | Runtime         | Compile-time     |
| Config     | Annotations + Java   | Annotations + XML | Java modules    | Java + codegen   |
| Startup    | Medium (scan)        | Medium            | Low             | Zero             |
| Ecosystem  | Massive              | Jakarta EE        | Standalone      | Android          |
| AOP        | Built-in proxies     | Interceptors      | AOP Alliance    | None             |
| Testing    | @SpringBootTest      | Arquillian        | Custom injector | Compile verified |

**Rapid Decision Tree (30 seconds):**
IF enterprise Java with full ecosystem -> Spring DI
ELSE IF Jakarta EE server -> CDI
ELSE IF Android -> Dagger
ELSE IF minimal standalone DI -> Guice

---

### ⚠️ Common Misconceptions

| #   | Misconception                            | Reality                                                                                                                                                        |
| --- | ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | "DI and IoC are the same thing"          | IoC is the principle (framework controls flow). DI is one implementation. Service Locator is another. DI is preferred because dependencies are explicit.       |
| 2   | "Spring creates all objects"             | Spring only manages beans (annotated or declared via `@Bean`). Objects created with `new` are invisible to the container - no injection, no AOP, no lifecycle. |
| 3   | "Field injection is fine for production" | It hides dependencies, prevents `final`, requires reflection for testing. Constructor injection is always preferred. Field injection only in test classes.     |
| 4   | "`@Autowired` is always required"        | Since 4.3, single-constructor classes auto-wire without annotation. Multi-constructor classes still need it for disambiguation.                                |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: NoSuchBeanDefinitionException**

**Symptom:** Startup fails: `No qualifying bean of type 'com.app.UserRepo'`.

**Root Cause:** Class not annotated with `@Component`/`@Repository`, or outside `@ComponentScan` base package.

**Diagnostic:**

```bash
curl localhost:8080/actuator/beans | \
  jq '.contexts[].beans | keys[]' | \
  grep -i userrepo
```

**Fix:**

BAD: `@ComponentScan("")` scanning everything.

GOOD: Add `@Repository` to the class, or move it under the main app's package.

**Prevention:** Keep all classes under or below the `@SpringBootApplication` class package.

**Failure Mode 2: NoUniqueBeanDefinitionException**

**Symptom:** `expected single matching bean but found 2: stripeGw, paypalGw`.

**Root Cause:** Two beans implement the same interface, no disambiguation configured.

**Diagnostic:**

```bash
curl localhost:8080/actuator/beans | \
  jq '.contexts[].beans | to_entries[]
  | select(.value.type
  | contains("PaymentGateway"))'
```

**Fix:**

BAD: Removing one implementation.

GOOD: `@Primary` on the default, `@Qualifier` at specific injection points.

**Prevention:** Always designate a `@Primary` when multiple implementations exist.

**Failure Mode 3: BeanCurrentlyInCreationException**

**Symptom:** `Requested bean is currently in creation: Is there an unresolvable circular reference?`

**Root Cause:** Bean A's constructor needs B, B's constructor needs A.

**Diagnostic:**

```bash
# Exception message names both beans:
# "Error creating bean 'serviceA':
#  Requested bean 'serviceB' is
#  currently in creation"
```

**Fix:**

BAD: `@Lazy` on one injection point (hides design flaw).

GOOD: Extract shared logic into a third bean both depend on.

**Prevention:** Circular deps signal a design problem. Break the cycle architecturally.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: What is Dependency Injection and why does Spring use it?**

_Why they ask:_ Tests foundational understanding - can you explain the WHY, not just the WHAT.
_Likely follow-up:_ "What are the different types of injection?"

**Answer:**
Dependency Injection means a class receives its collaborators from outside rather than creating them internally. Instead of `new UserRepository()` inside `UserService`, the constructor declares `UserService(UserRepo repo)` and the Spring container provides the instance.

Spring uses DI because it solves three problems:

1. **Coupling:** Without DI, changing an implementation means editing every consumer
2. **Testing:** With DI, you pass a mock to the constructor - no container needed
3. **Configuration:** Swap implementations via profiles without code changes

```java
// Without DI - tightly coupled
class OrderService {
    private final MysqlRepo repo =
        new MysqlRepo(); // hardcoded
}

// With DI - loosely coupled
class OrderService {
    private final OrderRepo repo;
    OrderService(OrderRepo repo) {
        this.repo = repo; // injected
    }
}
```

The key insight: DI does not remove the dependency - `OrderService` still needs a repo. It removes the responsibility of _creating_ that dependency.

_What separates good from great:_ Mentioning that DI enables the Open/Closed Principle - classes are open for extension (swap implementations) without modification.

---

**Q2 [JUNIOR]: What are the three types of DI and which do you prefer?**

_Why they ask:_ Tests best-practice knowledge and reasoning ability.
_Likely follow-up:_ "When would you use setter injection?"

**Answer:**

| Type        | Mechanism          | Pros                | Cons          |
| ----------- | ------------------ | ------------------- | ------------- |
| Constructor | Constructor param  | Immutable, testable | Verbose       |
| Setter      | Setter method      | Optional deps       | Mutable state |
| Field       | `@Autowired` field | Concise             | Untestable    |

Constructor injection is always preferred:

- Fields are `final` -> thread-safe, immutable
- Object never partially constructed
- Testable without Spring: `new Service(mock)`
- Too many params = class doing too much (design signal)
- Circular deps fail at startup, not runtime

Setter injection only for truly optional dependencies (`@Autowired(required = false)`). Field injection only in test classes where convenience outweighs purity.

_What separates good from great:_ Noting that since Spring 4.3, `@Autowired` is implicit on a single constructor - the cleanest code has zero Spring annotations on the service body.

---

**Q3 [MID]: How does Spring resolve ambiguous dependencies?**

_Why they ask:_ Tests understanding of the resolution algorithm under real-world conditions.
_Likely follow-up:_ "What happens if two beans have `@Primary`?"

**Answer:**
When multiple beans match a required type, Spring follows this resolution order:

1. **`@Primary`** - if one candidate is marked `@Primary`, it wins
2. **`@Qualifier("name")`** - explicit selection at the injection point
3. **Parameter name matching** - `PaymentGateway stripeGateway` matches bean named `stripeGateway`
4. **If still ambiguous** -> `NoUniqueBeanDefinitionException`

```java
@Primary @Component
class StripeGateway implements PaymentGw {}

@Component
class PayPalGateway implements PaymentGw {}

// StripeGateway injected (primary)
Service(PaymentGw gw) {}

// Override with qualifier
Service(@Qualifier("payPalGateway")
        PaymentGw gw) {}

// Get all implementations
Service(List<PaymentGw> all) {}
```

If two beans both have `@Primary`, Spring throws `NoUniqueBeanDefinitionException` - there can only be one primary per type.

_What separates good from great:_ Mentioning `List<T>` injection to get all implementations, which is useful for strategy patterns and plugin architectures.

---

**Q4 [MID]: What is the difference between BeanFactory and ApplicationContext?**

_Why they ask:_ Tests container hierarchy understanding and awareness of the framework's design.
_Likely follow-up:_ "When would you use BeanFactory directly?"

**Answer:**
`BeanFactory` is the root interface - minimal DI container with lazy bean creation. `ApplicationContext` extends it with enterprise services:

- Event publication (`ApplicationEvent`)
- Internationalization (`MessageSource`)
- Resource loading (classpath, URL, file)
- AOP integration and automatic proxy creation
- Eager singleton initialization at startup
- Automatic `BeanPostProcessor` registration

In practice, you always use `ApplicationContext`. `BeanFactory` is an internal abstraction you never interact with directly. Spring Boot's `SpringApplication.run()` returns an `ApplicationContext`.

The design split exists for framework modularity: lightweight environments (like testing) could theoretically use `BeanFactory` alone, though this is almost never done in practice.

_What separates good from great:_ Knowing that `ApplicationContext` eagerly creates all singletons at startup (fail-fast), while `BeanFactory` is lazy (fail-at-use).

---

**Q5 [MID]: You see NoSuchBeanDefinitionException in production. Walk through your diagnosis.**

_Why they ask:_ Tests systematic debugging skills under pressure.
_Likely follow-up:_ "How would you prevent this from happening again?"

**Answer:**
Step-by-step diagnosis:

1. **Read the exception message** - it names the missing type and the injection point: `"No qualifying bean of type 'com.app.PaymentRepo' available: expected at least 1 bean"`

2. **Check the class annotation** - is `PaymentRepo` annotated with `@Repository` or `@Component`?

3. **Check package hierarchy** - is the class under the `@SpringBootApplication` class package? Component scanning only covers that package and below

4. **Check conditional annotations** - is there a `@ConditionalOnProperty` or `@Profile` that excludes it?

5. **Verify via actuator:**

```bash
curl localhost:8080/actuator/beans | \
  jq '.contexts[].beans | keys[]' \
  | sort | grep -i payment
```

6. **Check for typos in `@Qualifier`** - if using named injection, verify the bean name matches

Most common root cause: the class is in a sibling package not covered by `@ComponentScan`. Fix: move it under the main app package, or add an explicit `@ComponentScan("com.app.payments")`.

_What separates good from great:_ Immediately checking actuator/beans to see what IS registered, rather than guessing what is not.

---

**Q6 [SENIOR]: How would you design DI boundaries in a modular monolith?**

_Why they ask:_ Tests architectural thinking and ability to use DI beyond simple wiring.
_Likely follow-up:_ "How do you enforce these boundaries?"

**Answer:**
In a modular monolith, each bounded context (module) should:

1. **Own its `@Configuration`** - module-specific beans declared here
2. **Expose only interfaces** - the module's public API is interface-typed beans
3. **Hide internals** - `@ComponentScan(includeFilters = ...)` restricts visibility
4. **Use `@Import`** for explicit cross-module wiring

```
orders-module/
  OrderModuleConfig.java  (@Configuration)
  api/
    OrderService.java     (interface - exposed)
  internal/
    OrderServiceImpl.java (@Service - hidden)
    OrderRepo.java        (internal)

payments-module/
  PaymentModuleConfig.java
  api/
    PaymentGateway.java   (interface - exposed)
```

Enforcement:

- ArchUnit tests verify no cross-module internal imports
- Each module's `@Configuration` is the sole entry point
- `@ComponentScan` with `excludeFilters` prevents accidental scanning

At scale (50+ modules), teams use Spring Modulith which provides module boundary detection, event-based inter-module communication, and dependency verification at test time.

_What separates good from great:_ Mentioning Spring Modulith and explaining that module boundaries in code mirror team boundaries (Conway's Law), making DI an organizational tool.

---

**Q7 [SENIOR]: Tell me about a time you debugged a DI issue in production.**

_Why they ask:_ Tests real experience vs textbook knowledge (behavioral).
_Likely follow-up:_ "What did you change to prevent recurrence?"

**Answer:**

**Situation:** After a deployment, our order service started failing with `NoUniqueBeanDefinitionException` for `PaymentGateway`.

**Task:** Diagnose why the bean resolution broke when it worked before the deploy.

**Action:** Checked the diff - a new team had added a second `PaymentGateway` implementation in a library we depended on. Their `@Component` was picked up by our broad `@ComponentScan("com.company")`. I verified via `/actuator/beans` - two candidates registered.

**Result:** Immediate fix: added `@Primary` to our implementation. Long-term: narrowed `@ComponentScan` to `"com.company.orders"` and added an ArchUnit test that fails if external packages introduce beans into our context. Reduced blast radius of future library additions.

Key learning: broad component scanning is a latent bug. Narrow your scan to your own package hierarchy.

_What separates good from great:_ The prevention step - narrowing scan scope AND adding an automated test to catch future violations.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- Java Interfaces - DI depends on coding to interfaces for loose coupling
- Design Patterns (Factory, Strategy) - DI automates what these patterns do manually

**Builds on this (learn these next):**

- ApplicationContext - the actual container that manages all beans
- Bean Lifecycle - what happens between creation and destruction
- Spring AOP - how DI proxies enable cross-cutting concerns

**Alternatives / Comparisons:**

- Google Guice - lighter DI without the Spring ecosystem
- Dagger - compile-time DI, prefer for Android or startup-critical apps
- CDI (Jakarta EE) - standard DI when locked into Jakarta EE

---

---

# ApplicationContext

**TL;DR** - The central container that creates, configures, and manages every bean in your application while providing enterprise services like events, environment, and resource loading.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
No single place knows about all objects, their configurations, lifecycle, and relationships. Each component bootstraps itself, leading to scattered initialization, no unified environment access, and no way to publish events across the application.

**THE BREAKING POINT:**
You need to switch between dev/staging/prod configurations. Without a central context, every component reads its own config file. Changing a database URL means editing 12 classes.

**THE INVENTION MOMENT:**
"This is exactly why ApplicationContext was created."

**EVOLUTION:**
Java JNDI (lookup-based) -> Spring BeanFactory (lazy, minimal) -> ApplicationContext (eager, full-featured, 2004) -> Spring Boot auto-configured context (2014) -> Spring AOT pre-computed context (2022).

---

### 📘 Textbook Definition

`ApplicationContext` is the central interface of the Spring IoC container, extending `BeanFactory` with enterprise services: bean lifecycle management, event publication (`ApplicationEventPublisher`), internationalization (`MessageSource`), resource loading (`ResourceLoader`), and environment abstraction (`Environment`). It eagerly instantiates all singleton beans at startup, serving as the single source of truth for the application's object graph and configuration.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
The master registry that creates, wires, and manages every object in your Spring app.

**One analogy:**

> A hotel front desk. It knows every room (bean), every guest's reservation (configuration), handles wake-up calls (lifecycle events), and coordinates room service (dependency injection). You never manage rooms directly.

**One insight:**
ApplicationContext is not just a bean container - it is the application's runtime backbone. Events, properties, profiles, resource loading, and AOP proxy creation all flow through it. Understanding its startup sequence is the key to debugging 90% of Spring problems.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. The context is the single authority for bean creation, configuration, and lifecycle. No bean manages itself.
2. All singleton beans are eagerly instantiated at startup. If any bean fails, the entire context fails (fail-fast).
3. The context is immutable after `refresh()`. No new bean definitions can be added without restarting.

**DERIVED DESIGN:**
From invariant 1: all creation goes through the context, enabling proxying and lifecycle hooks. From invariant 2: all wiring errors surface at startup, never at runtime. From invariant 3: the app operates on a fixed, validated object graph.

**THE TRADE-OFFS:**

**Gain:** Centralized management, fail-fast validation, rich services (events, environment, resources), AOP integration.

**Cost:** Startup time grows with bean count. Eager init means slow starts for large apps. Context holds references to all singletons (memory).

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Any application needs a registry of components and relationships - ApplicationContext makes this explicit.

**Accidental:** Hierarchical contexts (parent/child from Spring MVC) were accidental complexity that Boot simplified away.

---

### 🧠 Mental Model / Analogy

> A city's utility grid. The grid (context) provides electricity (dependencies), water (configuration), and communication lines (events) to every building (bean). Buildings do not generate their own power. When a new building connects, the grid verifies capacity before opening day (startup validation). If the grid fails, all buildings lose service (context shutdown).

- "Utility grid" -> ApplicationContext
- "Buildings" -> Bean instances
- "Electricity" -> Dependency injection
- "Water" -> Configuration properties
- "Communication lines" -> Application events

Where this analogy breaks down: Real grids add buildings dynamically; ApplicationContext is fixed after `refresh()`.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Spring's master registry - it knows every object in your application, how to create them, and how they connect.

**Level 2 - How to use it (junior developer):**

```java
@SpringBootApplication
public class App {
    public static void main(String[] args) {
        ApplicationContext ctx =
            SpringApplication.run(
                App.class, args);

        // Rarely needed - prefer injection
        UserService svc =
            ctx.getBean(UserService.class);
    }
}
```

**Level 3 - How it works (mid-level engineer):**

Startup sequence:

1. Create Environment (properties, profiles)
2. Component scan + BeanDefinition registration
3. Invoke `BeanFactoryPostProcessor`s (modify definitions)
4. Instantiate singleton beans in dependency order
5. Invoke `BeanPostProcessor`s (proxy creation, AOP)
6. Publish `ContextRefreshedEvent`
7. Application ready

Common implementations:

- `AnnotationConfigApplicationContext` - Java config
- `GenericWebApplicationContext` - web apps
- `SpringApplication` (Boot) - auto-configured

**Level 4 - Mastery (senior/staff+ engineer):**

`BeanPostProcessor` is where the magic happens:

- `@Autowired` -> `AutowiredAnnotationBPP`
- `@Transactional` -> `AbstractAutoProxyCreator`
- `@Scheduled` -> `ScheduledAnnotationBPP`
- `@Async` -> `AsyncAnnotationBPP`

The context is hierarchical: child sees parent beans, not vice versa. Used in Spring MVC (root + servlet context).

**The Senior-to-Staff Leap:**

**A Senior says:** "ApplicationContext manages beans and provides DI."

**A Staff says:** "I use the context lifecycle to orchestrate application behavior - `BeanFactoryPostProcessor`s for dynamic definition, `ApplicationEvent`s for decoupled module communication, and context hierarchies for module isolation in modular monoliths."

**The difference:** Staff engineers leverage the context as an architectural orchestration tool, not just a bean factory.

**Level 5 - Distinguished (expert thinking):**
ApplicationContext implements Service Locator + Event Bus + Config Server combined. At extreme scale, split into hierarchies or use Spring Modulith's module-scoped contexts. If redesigning today: lazy initialization default (like Micronaut) with compile-time resolution (Spring AOT). The event system is the embryo of event-driven architecture - teams mastering `ApplicationEvent` naturally evolve toward Kafka/event sourcing.

---

### ⚙️ How It Works

```
  AnnotationConfigApplicationContext
       |
  new DefaultListableBeanFactory()
       |
  register(@Configuration classes)
       |
  refresh()                  <- CORE
       |
  invokeBFPPs()
  (ConfigurationClassPostProcessor
   processes @ComponentScan,
   @Import, @Bean methods)
       |
  registerBPPs()
  (AutowiredAnnotationBPP,
   CommonAnnotationBPP,
   AbstractAutoProxyCreator)
       |
  finishBeanFactoryInit()
  (instantiate all singletons
   in dependency order)
       |
  finishRefresh()
  (publish ContextRefreshedEvent,
   start lifecycle beans)
       |
  CONTEXT READY
```

The `refresh()` method executes 12 ordered steps in `AbstractApplicationContext`. `BeanFactoryPostProcessor`s run first to modify definitions (e.g., resolving `${property}` placeholders). Then `BeanPostProcessor`s wrap beans in proxies. The entire sequence is synchronized - no bean is accessible until refresh completes.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  JVM starts
       |
  SpringApplication.run()
       |
  Create Environment
  (profiles, properties)
       |
  ApplicationContext <- HERE
       |
  refresh() - 12 steps
       |
  All singletons instantiated
       |
  ContextRefreshedEvent
       |
  Embedded server starts
       |
  ApplicationReadyEvent
       |
  Accepting requests
```

**FAILURE PATH:**
Missing bean -> `NoSuchBeanDefinitionException` in `finishBeanFactoryInit()`. Invalid `@Value` -> `BeanCreationException`. Circular constructor dep -> `BeanCurrentlyInCreationException`. All abort `refresh()` - app never starts.

**WHAT CHANGES AT SCALE:**
100 beans: < 1s startup. 1000 beans: 3-8s, scanning and proxy creation dominate. 5000+ beans: 30-90s. Teams use Spring AOT (compile-time graph), `@Lazy` for non-critical paths, or split into multiple contexts.

---

### 💻 Code Example

**Example 1 - BAD getBean() vs GOOD injection:**

```java
// BAD - Service Locator anti-pattern
@Service
public class OrderService {
    @Autowired
    private ApplicationContext ctx;

    public void process(Order o) {
        // Fetching bean manually
        PaymentGw gw = ctx.getBean(
            PaymentGw.class);
        gw.charge(o);
    }
}

// GOOD - constructor injection
@Service
public class OrderService {
    private final PaymentGw gw;

    OrderService(PaymentGw gw) {
        this.gw = gw;
    }

    public void process(Order o) {
        gw.charge(o);
    }
}
```

**Example 2 - Custom ApplicationEvent for decoupled modules:**

```java
// Define event
public class OrderPlacedEvent
        extends ApplicationEvent {
    private final String orderId;
    public OrderPlacedEvent(
            Object source, String id) {
        super(source);
        this.orderId = id;
    }
    public String getOrderId() {
        return orderId;
    }
}

// Publish
@Service
public class OrderService {
    private final ApplicationEventPublisher
        pub;

    OrderService(
        ApplicationEventPublisher pub) {
        this.pub = pub;
    }

    public void place(Order o) {
        // save order...
        pub.publishEvent(
            new OrderPlacedEvent(
                this, o.getId()));
    }
}

// Listen (decoupled - no direct dep)
@Component
public class InventoryListener {
    @EventListener
    public void onOrder(
            OrderPlacedEvent e) {
        reserveStock(e.getOrderId());
    }
}
```

**How to test / verify correctness:**
`@SpringBootTest` with `@EventListener` on a test component that captures events. Assert the event was published with correct data.

---

### 📌 Quick Reference Card

**WHAT IT IS:** Spring's central IoC container managing all beans plus enterprise services.

**PROBLEM IT SOLVES:** Centralizes object management, configuration, events, and lifecycle.

**KEY INSIGHT:** Not just DI - it is the runtime backbone (events, environment, resources, AOP).

**USE WHEN:** Every Spring app. Boot creates it automatically via `SpringApplication.run()`.

**AVOID WHEN:** Serverless functions where startup speed is critical (consider Micronaut/Quarkus).

**ANTI-PATTERN:** Calling `getBean()` in application code (Service Locator pattern).

**TRADE-OFF:** Rich services and fail-fast validation vs. startup cost and eager memory allocation.

**ONE-LINER:** "The backbone that knows every bean and validates the entire graph at startup."

**KEY NUMBERS:** 12 steps in `refresh()`. Singleton cache is ConcurrentHashMap. ~1-50ms/bean depending on proxies.

**TRIGGER PHRASE:** "Central container managing all beans and lifecycle."

**OPENING SENTENCE:** "ApplicationContext extends BeanFactory with enterprise services - eager singleton init, event publication, environment abstraction, and AOP proxy creation - serving as the runtime backbone of every Spring application."

**If you remember only 3 things:**

1. ApplicationContext = IoC container + events + environment + resources
2. Startup: scan -> definitions -> post-process defs -> instantiate -> post-process beans -> ready
3. BeanPostProcessors create proxies for @Transactional, @Async, @Scheduled

**Interview one-liner:**
"ApplicationContext is Spring's central container - it eagerly creates all singletons at startup, validates the entire dependency graph, and provides enterprise services like event publication and environment abstraction, failing fast on any misconfiguration."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Draw the 12-step `refresh()` sequence and explain BeanFactoryPostProcessor vs BeanPostProcessor roles
2. **DEBUG:** Given a `BeanCreationException` stack trace, identify whether root cause is missing bean, circular dep, or failed `@Value` resolution
3. **DECIDE:** Choose between `AnnotationConfigApplicationContext`, Boot auto-config, and programmatic builder based on deployment model
4. **BUILD:** Configure parent/child contexts for a modular app with shared infrastructure beans in parent
5. **EXTEND:** Apply the "central registry with lifecycle hooks" pattern to Kubernetes controllers or plugin architectures

---

### 💡 The Surprising Truth

`ApplicationContext.refresh()` is not just initialization - it is a complete reset. Calling `refresh()` on a running context destroys all singletons and rebuilds from scratch. This is why Boot apps must never call `refresh()` manually. It also means the context is not incrementally buildable - you cannot add a single bean without rebuilding everything. This all-or-nothing design guarantees the graph is always consistent and validated.

---

### ⚖️ Comparison Table

| Dimension | ApplicationContext     | BeanFactory      | Micronaut         | Quarkus Arc |
| --------- | ---------------------- | ---------------- | ----------------- | ----------- |
| Init      | Eager (all singletons) | Lazy (on demand) | Compile-time      | Build-time  |
| Events    | Built-in               | None             | Built-in          | CDI events  |
| AOP       | Runtime proxies        | Manual           | Compile-time      | Build-time  |
| Startup   | Slower (reflection)    | Faster           | Fast (no reflect) | Fast        |
| Ecosystem | Massive                | Minimal          | Growing           | Jakarta EE  |

**Rapid Decision Tree (30 seconds):**
IF enterprise Java, largest ecosystem -> ApplicationContext (Boot)
ELSE IF startup critical (serverless) -> Micronaut or Quarkus
ELSE IF minimal DI only -> BeanFactory (almost never)

---

### ⚠️ Common Misconceptions

| #   | Misconception                                         | Reality                                                                                                                   |
| --- | ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| 1   | "ApplicationContext and BeanFactory are the same"     | AppContext extends BeanFactory adding events, resources, eager init, and auto BPP registration.                           |
| 2   | "Beans are created when first requested"              | Singletons are eagerly created during `refresh()`. Only prototype and `@Lazy` beans are on-demand.                        |
| 3   | "You should use `getBean()` to retrieve dependencies" | `getBean()` is Service Locator anti-pattern. Use constructor injection. `getBean()` only for bootstrap or framework code. |
| 4   | "Context can be modified at runtime"                  | After `refresh()`, context is frozen. New bean definitions require full refresh (destroys all beans).                     |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: UnsatisfiedDependencyException at startup**

**Symptom:** `Error creating bean 'orderService': Unsatisfied dependency through constructor parameter 0`.

**Root Cause:** Required bean missing - not annotated or outside scan path.

**Diagnostic:**

```bash
curl localhost:8080/actuator/beans | \
  jq '.contexts[].beans | keys[]' \
  | sort | grep -i payment
```

**Fix:**

BAD: `@ComponentScan("")` to scan everything.

GOOD: Add `@Repository` annotation, or ensure package is under main app class.

**Prevention:** Keep all app classes under `@SpringBootApplication` package hierarchy.

**Failure Mode 2: Self-invocation bypasses proxy**

**Symptom:** `@Transactional` does not roll back. `@Cacheable` misses. `@Async` runs synchronously.

**Root Cause:** Bean calls its own method internally - bypasses the AOP proxy.

**Diagnostic:**

```java
log.info("Type: {}",
    service.getClass().getName());
// "com.app.Service" = NO proxy
// "com.app.Service$$SpringCGLIB$$0"
//   = proxy active
```

**Fix:**

BAD: `@Autowired Service self` (self-injection hack).

GOOD: Extract the annotated method into a separate bean.

**Prevention:** Never call `@Transactional`/`@Async` methods from within the same class.

**Failure Mode 3: Slow startup (30+ seconds)**

**Symptom:** Deployment health checks time out. Pods killed by Kubernetes liveness probe.

**Root Cause:** Too many beans (1000+), expensive `@PostConstruct`, or broad classpath scanning.

**Diagnostic:**

```bash
java -jar app.jar \
  --spring.main.startup-tracking=true
# Or use ApplicationStartup:
# app.setApplicationStartup(
#   new BufferingApplicationStartup(
#     2048))
# GET /actuator/startup
```

**Fix:**

BAD: Increasing health check timeout to mask the problem.

GOOD: Spring AOT for compile-time resolution, `@Lazy` for non-critical beans, split into modules.

**Prevention:** Monitor startup time in CI. Set a budget (< 10s) and alert on regression.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: Explain the Spring Boot startup sequence.**

_Why they ask:_ Tests understanding of the bootstrap process.
_Likely follow-up:_ "Where would you add custom initialization logic?"

**Answer:**

```
SpringApplication.run()
  |-> Create ApplicationContext
  |-> Load Environment
  |    (application.yml, env vars)
  |-> Component scan +
  |    auto-configuration
  |    (@EnableAutoConfiguration)
  |-> BeanDefinition registration
  |-> BeanFactoryPostProcessors
  |    (resolve ${placeholders},
  |     process @Configuration)
  |-> Singleton instantiation
  |-> BeanPostProcessors
  |    (proxies, @Transactional)
  |-> ContextRefreshedEvent
  |-> Embedded server starts
  |-> ApplicationReadyEvent
```

Auto-configuration classes are just `@Configuration` classes conditionally enabled by `@ConditionalOnClass`, `@ConditionalOnProperty`, etc. They live in `META-INF/spring/AutoConfiguration.imports`.

Custom init logic: use `@PostConstruct` for per-bean init, `@EventListener(ApplicationReadyEvent.class)` for post-startup logic (after proxies are active).

_What separates good from great:_ Knowing that `@PostConstruct` runs before proxies, so `@Transactional` methods called from `@PostConstruct` have no transaction.

---

**Q2 [JUNIOR]: What is the difference between @Component, @Service, @Repository, and @Controller?**

_Why they ask:_ Tests stereotype annotation understanding.
_Likely follow-up:_ "Is there any functional difference?"

**Answer:**
Functionally, `@Service`, `@Repository`, and `@Controller` are all `@Component` - they're all detected by scanning and create beans:

```java
@Component  // generic
@Service    // business logic
@Repository // data access
@Controller // web layer
```

The ONLY runtime difference: `@Repository` enables persistence exception translation (`DataAccessException` hierarchy).

Semantic benefits:

- **Code clarity:** communicates class role
- **AOP targeting:** apply aspects to all `@Repository` beans
- **Future hooks:** Spring can add behavior per stereotype

Use the right annotation for intent, not because it changes behavior.

_What separates good from great:_ Knowing that `@Repository` is the only one with actual runtime behavior (exception translation).

---

**Q3 [MID]: Your @Transactional method is not rolling back. Diagnose.**

_Why they ask:_ Tests debugging ability with a very common production issue.
_Likely follow-up:_ "How would you prevent this systemically?"

**Answer:**
Top 3 causes in order of likelihood:

1. **Self-invocation** - calling the `@Transactional` method from within the same class bypasses the proxy:

```java
@Service
public class OrderService {
    public void process(Order o) {
        save(o); // direct call, no proxy!
    }

    @Transactional
    public void save(Order o) { ... }
}
// Fix: extract save() to separate bean
```

2. **Checked exception** - by default, `@Transactional` only rolls back on unchecked exceptions:

```java
// BAD: checked exception, no rollback
@Transactional
void transfer() throws BankException {}

// GOOD: explicit rollback rule
@Transactional(
    rollbackFor = BankException.class)
void transfer() throws BankException {}
```

3. **Not a Spring-managed bean** - class created with `new` instead of injected

Diagnostic: log the class type to verify proxy is active:

```java
log.info("{}",
    this.getClass().getName());
// Should show $$SpringCGLIB$$
```

_What separates good from great:_ Immediately checking for self-invocation first (most common) and knowing that checked exceptions do not trigger rollback by default.

---

**Q4 [SENIOR]: How would you optimize a Spring Boot app with 30-second startup?**

_Why they ask:_ Tests production optimization skills.
_Likely follow-up:_ "What are the trade-offs of lazy initialization?"

**Answer:**
Systematic approach, ordered by impact:

1. **Profile startup** - use `/actuator/startup` to find the slowest beans
2. **Spring AOT** (Boot 3.x) - compile-time bean resolution, eliminates reflection scanning. 50-80% startup reduction
3. **`@Lazy`** on non-critical beans - defer init until first use
4. **Narrow `@ComponentScan`** - scan only your packages, not transitive deps
5. **Remove unused auto-configurations** - `spring.autoconfigure.exclude` in properties
6. **GraalVM native image** - sub-second startup, but limited reflection support

Trade-offs of lazy init: faster startup but first request hits initialization cost. Wiring errors surface at runtime instead of startup (loses fail-fast).

For Kubernetes: increase `initialDelaySeconds` on liveness probe as a temporary measure while optimizing. Never increase it permanently.

_What separates good from great:_ Starting with profiling (`/actuator/startup`) instead of guessing, and mentioning Spring AOT as the highest-impact solution.

---

**Q5 [SENIOR]: Design an event-driven module boundary using ApplicationContext events.**

_Why they ask:_ Tests architectural use of the context beyond basic DI.
_Likely follow-up:_ "When would you switch from ApplicationEvent to Kafka?"

**Answer:**
Use `ApplicationEventPublisher` for intra-process module decoupling:

```java
// Orders module publishes
@Service
class OrderService {
    private final ApplicationEventPublisher
        pub;
    void place(Order o) {
        repo.save(o);
        pub.publishEvent(
            new OrderPlacedEvent(o.id()));
    }
}

// Inventory module listens
@Component
class InventoryListener {
    @TransactionalEventListener(
        phase = AFTER_COMMIT)
    void onOrderPlaced(
            OrderPlacedEvent e) {
        reserveStock(e.orderId());
    }
}
```

Key design decisions:

- `@TransactionalEventListener` ensures listener runs only after publisher's TX commits
- Use `@Async` on listener to avoid blocking the publisher
- Modules share only event classes (DTOs), not service interfaces

Switch to Kafka when:

- Events must survive process restarts (durability)
- Multiple consumer groups need independent processing
- Cross-service communication required
- Event replay needed for debugging or rebuilding state

_What separates good from great:_ Using `@TransactionalEventListener(phase = AFTER_COMMIT)` instead of `@EventListener`, which would fire even if the transaction rolls back.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- IoC Container and Dependency Injection - the foundational concept ApplicationContext implements
- Java Reflection - context uses reflection for scanning and instantiation

**Builds on this (learn these next):**

- Bean Lifecycle - detailed sequence inside the context
- Spring AOP - how the context creates proxies via BeanPostProcessors
- Spring Boot Auto-Configuration - how Boot configures the context automatically

**Alternatives / Comparisons:**

- Micronaut ApplicationContext - compile-time DI, prefer for serverless
- Quarkus Arc - CDI-based, prefer for Kubernetes-native apps

---

---

# Bean Lifecycle

**TL;DR** - Every Spring bean follows a precise lifecycle: instantiation, dependency injection, initialization callbacks, active use, and destruction callbacks - giving you hooks at each stage for custom logic.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You cannot run initialization logic after all dependencies are injected (the constructor runs before injection completes in setter/field injection). You cannot validate configuration post-wiring. You cannot clean up resources (close connections, stop schedulers) on shutdown. Every component implements its own ad-hoc init/cleanup with no ordering guarantees.

**THE BREAKING POINT:**
A cache service needs to pre-warm after its Redis client is injected. A Kafka consumer must stop gracefully before the connection pool closes. Without lifecycle hooks, you resort to `static` initializers and `Runtime.addShutdownHook()` - fragile, unordered, untestable.

**THE INVENTION MOMENT:**
"This is exactly why Bean Lifecycle callbacks were created."

**EVOLUTION:**
Manual init/cleanup -> `InitializingBean`/`DisposableBean` (Spring 1.x) -> `@PostConstruct`/`@PreDestroy` (JSR-250, Spring 2.5) -> `SmartLifecycle` (ordered startup/shutdown, Spring 3.0) -> `ApplicationReadyEvent` (Boot).

---

### 📘 Textbook Definition

The Spring bean lifecycle is the sequence of phases every container-managed object passes through: instantiation via constructor, property population (dependency injection), initialization callbacks (`@PostConstruct`, `InitializingBean.afterPropertiesSet()`, custom init-method), active service, and destruction callbacks (`@PreDestroy`, `DisposableBean.destroy()`, custom destroy-method). `BeanPostProcessor` hooks intercept before and after initialization, enabling proxy creation (AOP, transactions).

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Beans have a birth, a life, and a death - Spring gives you hooks at each stage.

**One analogy:**

> An employee onboarding process. Hired (instantiated), given equipment and badge (dependencies injected), attends orientation (post-construct), works (active), goes through offboarding (pre-destroy), badge deactivated (destroyed). HR (container) controls every step.

**One insight:**
`@PostConstruct` runs BEFORE AOP proxies are created. This means calling `@Transactional` methods from `@PostConstruct` has no transaction behavior - a bug that bites almost every team once.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. A bean is never partially initialized when handed to consumers. The container guarantees all dependencies injected and all init callbacks complete before any other bean receives a reference.
2. Destruction callbacks are invoked in reverse creation order. Beans created last are destroyed first, ensuring dependencies outlive their dependents.
3. `BeanPostProcessor` hooks wrap the initialization phase, not the constructor. This is why proxies exist after init but not during construction.

**DERIVED DESIGN:**
From invariant 1: constructor + injection + init is atomic from the consumer's perspective. From invariant 2: shutdown is safe - a service is destroyed before its database connection pool. From invariant 3: `@PostConstruct` sees the raw object, not the proxy - explaining the `@Transactional`-from-init trap.

**THE TRADE-OFFS:**

**Gain:** Predictable ordering, clean resource management, extensibility via `BeanPostProcessor`.

**Cost:** Complex callback sequence (12 steps), easy to misorder. `@PostConstruct` vs `ApplicationReadyEvent` confusion.

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Any managed object system needs creation, init, and cleanup hooks.

**Accidental:** Having three ways to define init (`@PostConstruct`, `InitializingBean`, custom method) is historical baggage from Spring's evolution.

---

### 🧠 Mental Model / Analogy

> A rocket launch sequence. The rocket (bean) is assembled (instantiated), fueled (dependencies injected), runs pre-flight checks (BeanPostProcessor.before), engines tested (@PostConstruct), final inspection (BeanPostProcessor.after - proxy wrapping), then launched (ready for use). On mission end, engines shut down (@PreDestroy) in reverse order of activation.

- "Assembly" -> Constructor invocation
- "Fueling" -> Dependency injection
- "Pre-flight checks" -> BeanPostProcessor.postProcessBeforeInitialization
- "Engine test" -> @PostConstruct
- "Final inspection" -> BeanPostProcessor.postProcessAfterInitialization (proxy wrap)
- "Shutdown" -> @PreDestroy

Where this analogy breaks down: Rockets are not reused; singleton beans serve requests for the entire application lifetime.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Every object managed by Spring goes through birth, setup, work, and cleanup. Spring lets you run custom code at each stage - like plugging into a conveyor belt at specific stations.

**Level 2 - How to use it (junior developer):**

```java
@Service
public class CacheService {
    private final RedisClient client;

    CacheService(RedisClient client) {
        this.client = client;
    }

    @PostConstruct
    public void warmUp() {
        // Runs AFTER constructor + injection
        client.connect();
        loadFrequentKeys();
    }

    @PreDestroy
    public void shutdown() {
        // Runs on app shutdown
        client.disconnect();
    }
}
```

**Level 3 - How it works (mid-level engineer):**

Complete sequence (12 steps):

```
 1. Instantiate (constructor)
 2. Populate properties (@Autowired)
 3. BeanNameAware.setBeanName()
 4. BeanFactoryAware.setBeanFactory()
 5. ApplicationContextAware.setCtx()
 6. BPP.postProcessBefore()
 7. @PostConstruct
 8. InitializingBean.afterPropertiesSet()
 9. Custom init-method
10. BPP.postProcessAfter()
    (AOP proxies created HERE!)
11. === Bean is ready for use ===
12. @PreDestroy / DisposableBean /
    custom destroy
```

**Level 4 - Mastery (senior/staff+ engineer):**

Critical insight: `@PostConstruct` runs at step 7, but proxies are created at step 10. So `this` inside `@PostConstruct` is the raw object:

```java
@Service
public class DataLoader {
    @PostConstruct
    public void init() {
        loadData(); // No TX! Raw this
    }

    @Transactional
    public void loadData() { /* ... */ }
}

// Fix: use ApplicationReadyEvent
@EventListener(ApplicationReadyEvent.class)
public void onReady() {
    loadData(); // Called on proxy -> TX
}
```

`SmartLifecycle` for ordered startup/shutdown:

```java
@Component
public class KafkaConsumer
        implements SmartLifecycle {
    public int getPhase() { return 10; }
    // Higher = starts later, stops first
    public void start() {
        consumer.subscribe();
    }
    public void stop() {
        consumer.close();
    }
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `@PostConstruct` for initialization and `@PreDestroy` for cleanup."

**A Staff says:** "I design shutdown ordering using `SmartLifecycle` phases - consumers stop before producers, producers drain before connection pools close. And I never put transactional logic in `@PostConstruct` because proxies are not yet active."

**The difference:** Staff engineers think about lifecycle as an orchestration problem across multiple beans, not just per-bean init/cleanup.

**Level 5 - Distinguished (expert thinking):**
The bean lifecycle is an instance of the Template Method pattern applied at the container level. The same pattern appears in Servlet lifecycle (`init`/`service`/`destroy`), Android Activity lifecycle, and React component lifecycle (`mount`/`update`/`unmount`). If redesigning today, a single `@Lifecycle` annotation with phase enum would replace the three overlapping init mechanisms. At extreme scale, `SmartLifecycle` ordering becomes critical for zero-downtime deployments: graceful shutdown must drain requests, deregister from service discovery, stop consumers, then close pools - all in precise order.

---

### ⚙️ How It Works

```
  Container creates bean
       |
  Constructor called
       |
  @Autowired fields/setters injected
       |
  Aware interfaces called
  (BeanNameAware, etc.)
       |
  BPP.postProcessBefore()
  (CommonAnnotationBPP finds
   @PostConstruct)
       |
  @PostConstruct runs
       |
  InitializingBean.afterPropertiesSet()
       |
  Custom init-method (XML/@Bean)
       |
  BPP.postProcessAfter()      <- HERE
  (AbstractAutoProxyCreator
   wraps in CGLIB/JDK proxy)
       |
  Bean is READY (proxy returned)
       |
  ... application runs ...
       |
  Context closing:
  @PreDestroy -> DisposableBean
  -> custom destroy-method
  (reverse creation order)
```

The `CommonAnnotationBeanPostProcessor` handles `@PostConstruct`/`@PreDestroy`. The `AbstractAutoProxyCreator` handles proxy wrapping. Because BPPs execute in order, proxy creation always happens after user init code.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  ApplicationContext.refresh()
       |
  BeanDefinitions registered
       |
  finishBeanFactoryInit()
       |
  For each singleton:
    construct -> inject -> init
       |
  Bean Lifecycle <- HERE
  (steps 1-10 per bean)
       |
  All singletons ready
       |
  ContextRefreshedEvent
       |
  ApplicationReadyEvent
```

**FAILURE PATH:**
`@PostConstruct` throws -> `BeanCreationException` -> context fails to start. `@PreDestroy` throws -> logged as warning, next bean's destroy still runs (best-effort cleanup).

**WHAT CHANGES AT SCALE:**
At 100 beans: lifecycle is transparent. At 1000 beans: expensive `@PostConstruct` methods (cache warming, schema migration) dominate startup. Solution: make heavy init `@Lazy` or move to `ApplicationReadyEvent` (async). Shutdown at scale: `SmartLifecycle` ordering prevents cascading failures.

---

### 💻 Code Example

**Example 1 - BAD @PostConstruct with @Transactional vs GOOD ApplicationReadyEvent:**

```java
// BAD - @Transactional ignored
@Service
public class DataLoader {
    @PostConstruct
    void init() {
        loadData(); // no proxy, no TX!
    }

    @Transactional
    public void loadData() {
        repo.saveAll(seedData());
    }
}

// GOOD - event fires after proxies exist
@Service
public class DataLoader {
    @EventListener(
        ApplicationReadyEvent.class)
    @Transactional
    public void loadData() {
        repo.saveAll(seedData());
    }
}
```

**Example 2 - Ordered shutdown with SmartLifecycle:**

```java
@Component
public class GracefulShutdown
        implements SmartLifecycle {
    private volatile boolean running;

    @Override
    public int getPhase() {
        // Integer.MAX_VALUE = stops first
        return Integer.MAX_VALUE;
    }

    @Override
    public void start() {
        running = true;
    }

    @Override
    public void stop(Runnable callback) {
        // 1. Deregister from load balancer
        deregister();
        // 2. Drain in-flight requests
        drainRequests(Duration.ofSeconds(
            30));
        // 3. Signal completion
        running = false;
        callback.run();
    }

    @Override
    public boolean isRunning() {
        return running;
    }
}
```

**How to test / verify correctness:**
Use `@SpringBootTest` with `ConfigurableApplicationContext.close()` to trigger shutdown. Assert `@PreDestroy` side effects (e.g., connection closed, flag set).

---

### 📌 Quick Reference Card

**WHAT IT IS:** The 12-step sequence every Spring bean passes through from creation to destruction.

**PROBLEM IT SOLVES:** Provides predictable init/cleanup hooks and extensibility via BeanPostProcessors.

**KEY INSIGHT:** Proxies are created AFTER `@PostConstruct` - transactional methods called from init have no TX.

**USE WHEN:** Any bean needing post-injection setup (cache warming, connection opening) or cleanup (resource release).

**AVOID WHEN:** Simple stateless beans with no resources to manage - do not add empty lifecycle methods.

**ANTI-PATTERN:** Heavy initialization in `@PostConstruct` blocking startup; `@Transactional` inside `@PostConstruct`.

**TRADE-OFF:** Structured lifecycle management vs. complexity of a 12-step callback sequence.

**ONE-LINER:** "Birth, setup, work, cleanup - hooks at every stage, proxies created after init."

**KEY NUMBERS:** 12 lifecycle steps. `@PostConstruct` at step 7, proxy at step 10. Destroy in reverse order.

**TRIGGER PHRASE:** "PostConstruct runs before proxies exist."

**OPENING SENTENCE:** "Spring beans follow a 12-step lifecycle where BeanPostProcessors intercept between initialization and proxy creation, which is why @PostConstruct cannot leverage @Transactional and why SmartLifecycle ordering is critical for graceful shutdown."

**If you remember only 3 things:**

1. @PostConstruct = step 7, Proxy = step 10 -> no TX in init
2. Destruction runs in reverse creation order (deps outlive dependents)
3. SmartLifecycle.getPhase() controls startup/shutdown ordering

**Interview one-liner:**
"Beans go through construct, inject, BPP-before, @PostConstruct, BPP-after (proxy wrapping), then active use, then @PreDestroy in reverse order. The critical gotcha: proxies do not exist during @PostConstruct, so @Transactional calls from init are silently ignored."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Draw the 12-step lifecycle sequence and explain why proxy creation happens after `@PostConstruct`
2. **DEBUG:** Given "@Transactional not working on init," diagnose the proxy timing issue and fix with `ApplicationReadyEvent`
3. **DECIDE:** Choose between `@PostConstruct`, `SmartLifecycle`, and `ApplicationReadyEvent` for a given initialization scenario
4. **BUILD:** Implement ordered graceful shutdown (consumers first, then producers, then pools) using `SmartLifecycle` phases
5. **EXTEND:** Recognize the Template Method lifecycle pattern in Servlet, Android Activity, and React components

---

### 💡 The Surprising Truth

`@PreDestroy` is best-effort, not guaranteed. If the JVM is killed with `SIGKILL` (kill -9) or crashes, `@PreDestroy` never runs. This means you cannot rely on destruction callbacks for critical operations like flushing data to disk. Instead, design for crash safety: write-ahead logs, idempotent operations, and external health checks. `@PreDestroy` is for graceful cleanup (releasing connections, deregistering from discovery) during normal `SIGTERM` shutdowns.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                      | Reality                                                                                                                                 |
| --- | -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | "@PostConstruct runs on the proxy"                 | It runs on the raw object (step 7). Proxies are created at step 10. Self-calls to @Transactional methods from init have no transaction. |
| 2   | "Destruction order is random"                      | Beans are destroyed in reverse creation order. Dependencies are guaranteed to outlive their dependents.                                 |
| 3   | "@PreDestroy always runs"                          | Only on graceful shutdown (SIGTERM). SIGKILL, OOM kills, and JVM crashes skip it entirely.                                              |
| 4   | "InitializingBean and @PostConstruct are the same" | @PostConstruct is JSR-250 standard (portable). InitializingBean is Spring-specific. Both run, but @PostConstruct first.                 |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: @Transactional ignored in @PostConstruct**

**Symptom:** Data not persisted during startup init. No rollback on exception.

**Root Cause:** `@PostConstruct` runs before AOP proxy wrapping (step 7 vs step 10).

**Diagnostic:**

```java
@PostConstruct
void init() {
    log.info("Class: {}",
        this.getClass().getName());
    // Will show raw class, not CGLIB
}
```

**Fix:**

BAD: Calling `@Transactional` from `@PostConstruct`.

GOOD: Use `@EventListener(ApplicationReadyEvent.class)` which fires after all proxies are active.

**Prevention:** Rule: never call proxied methods from lifecycle callbacks.

**Failure Mode 2: Bean destruction order causes NPE on shutdown**

**Symptom:** `NullPointerException` in `@PreDestroy` when accessing a dependency that is already destroyed.

**Root Cause:** Custom destroy logic accesses a bean that was destroyed earlier due to incorrect ordering.

**Diagnostic:**

```bash
# Enable debug logging for destruction
logging.level.org.springframework\
  .beans.factory=DEBUG
# Watch for "Destroying singletons" log
# showing the actual destruction order
```

**Fix:**

BAD: Adding null checks in `@PreDestroy` (masking the ordering bug).

GOOD: Implement `SmartLifecycle` with correct phase ordering so the dependent bean shuts down first.

**Prevention:** Design shutdown with explicit phase ordering via `SmartLifecycle`.

**Failure Mode 3: Startup blocked by expensive @PostConstruct**

**Symptom:** Application takes 60+ seconds to start. Health check times out.

**Root Cause:** `@PostConstruct` method doing expensive work (loading large cache, connecting to slow external service).

**Diagnostic:**

```bash
# Profile startup timing
java -jar app.jar \
  -Dspring.main.startup-tracking=true
# Check /actuator/startup for slow beans
```

**Fix:**

BAD: Increasing health check timeout.

GOOD: Move heavy init to `@Async @EventListener(ApplicationReadyEvent.class)` so startup completes and heavy work runs in background.

**Prevention:** Set a startup time budget. CI fails if exceeded.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: What are the Spring bean lifecycle phases?**

_Why they ask:_ Tests fundamental understanding of container management.
_Likely follow-up:_ "Where do AOP proxies get created?"

**Answer:**
The lifecycle has 12 steps grouped into 4 phases:

**Creation:** Constructor called, dependencies injected via `@Autowired`.

**Initialization:** `BeanPostProcessor.postProcessBefore()` runs, then `@PostConstruct`, then `InitializingBean.afterPropertiesSet()`, then `BeanPostProcessor.postProcessAfter()` (where AOP proxies are created).

**Active use:** Bean serves requests for the application's lifetime (if singleton).

**Destruction:** On context close - `@PreDestroy`, then `DisposableBean.destroy()`, in reverse creation order.

The critical detail: proxy creation at step 10 means `@PostConstruct` (step 7) sees the raw unwrapped object. This is why `@Transactional` methods called from `@PostConstruct` have no transaction.

_What separates good from great:_ Explaining the proxy timing gap and its practical consequence.

---

**Q2 [MID]: @PostConstruct vs ApplicationReadyEvent vs SmartLifecycle - when do you use each?**

_Why they ask:_ Tests nuanced understanding of initialization timing.
_Likely follow-up:_ "What about CommandLineRunner?"

**Answer:**

| Hook                     | When it runs                   | Use case                      |
| ------------------------ | ------------------------------ | ----------------------------- |
| `@PostConstruct`         | After injection, before proxy  | Per-bean init (no TX needed)  |
| `SmartLifecycle.start()` | After context refresh, ordered | Ordered startup (consumers)   |
| `ApplicationReadyEvent`  | After everything, incl. server | Post-startup logic needing TX |
| `CommandLineRunner`      | After context refresh          | CLI apps, one-time scripts    |

Decision framework:

- Need TX or proxied methods? -> `ApplicationReadyEvent`
- Need startup ordering? -> `SmartLifecycle` with phases
- Simple per-bean init (no TX)? -> `@PostConstruct`
- One-time script? -> `CommandLineRunner`

```java
// Phase ordering example:
// Phase 1: DB migration (SmartLifecycle)
// Phase 5: Cache warm-up (SmartLifecycle)
// Phase 10: Start Kafka consumer
// ApplicationReadyEvent: send "I'm alive"
```

_What separates good from great:_ Knowing that `SmartLifecycle` provides both startup AND shutdown ordering, while `@PostConstruct`/`@PreDestroy` only control per-bean timing.

---

**Q3 [MID]: How would you implement graceful shutdown for a service processing Kafka messages?**

_Why they ask:_ Tests production-readiness and lifecycle design.
_Likely follow-up:_ "What happens to in-flight messages?"

**Answer:**
Use `SmartLifecycle` with phase ordering:

```java
@Component
public class KafkaShutdown
        implements SmartLifecycle {
    private final KafkaConsumer consumer;
    private volatile boolean running;

    public int getPhase() {
        return Integer.MAX_VALUE; // stop 1st
    }

    public void stop(Runnable callback) {
        log.info("Stopping consumer...");
        consumer.wakeup();
        // Wait for in-flight processing
        awaitInflight(Duration.ofSeconds(
            30));
        running = false;
        callback.run();
    }
}
```

Shutdown order (phases, high stops first):

1. Stop accepting new requests (deregister from LB)
2. Stop Kafka consumers (`wakeup()`)
3. Drain in-flight messages (bounded wait)
4. Close producers (flush pending)
5. Close connection pools

For Kubernetes: `preStop` hook + `terminationGracePeriodSeconds` (default 30s) ensures pods get time to drain.

_What separates good from great:_ Using `SmartLifecycle.stop(Runnable callback)` with the callback to signal completion, not `stop()` which blocks the shutdown thread.

---

**Q4 [SENIOR]: You see NPE in @PreDestroy during shutdown. Diagnose.**

_Why they ask:_ Tests understanding of destruction ordering and dependency management.
_Likely follow-up:_ "How would you redesign to prevent this?"

**Answer:**
Root cause: the bean's `@PreDestroy` method accesses a dependency that was already destroyed.

Diagnosis steps:

1. Check which bean throws NPE and which dependency is null
2. Determine creation order (debug log: `Destroying singletons in ...`)
3. The dependency was created AFTER the current bean, so it gets destroyed BEFORE

```bash
# Enable destruction logging
logging.level.org.springframework\
  .beans.factory=DEBUG
# Look for "Destroying singletons"
```

Fix: implement `SmartLifecycle` with explicit phase ordering. The bean that depends on the pool should have a HIGHER phase (stops first), completing its cleanup while the pool is still alive.

Alternative: use `@DependsOn("connectionPool")` to force creation order, which also fixes destruction order (reverse of creation).

_What separates good from great:_ Knowing that destruction is the reverse of creation, and that `@DependsOn` affects both orders.

---

**Q5 [SENIOR]: Describe a production incident caused by bean lifecycle misunderstanding.**

_Why they ask:_ Tests real experience (behavioral).
_Likely follow-up:_ "What safeguard did you add?"

**Answer:**

**Situation:** Our payment service silently processed orders without saving audit records during a 2-hour window after deployment.

**Task:** Audit records were written by a `@PostConstruct` method that called `auditService.initialize()` which was `@Transactional`.

**Action:** The `@Transactional` annotation was silently ignored because `@PostConstruct` runs before proxy wrapping. The audit table was empty but no exceptions were thrown (the method succeeded without a real transaction, and the SQL was auto-committed row-by-row instead of batched).

**Result:** Moved initialization to `@EventListener(ApplicationReadyEvent.class)` with `@Transactional`. Added a startup health check that verifies the audit table has a boot record. Added a team-wide rule: no `@Transactional` in `@PostConstruct`.

_What separates good from great:_ The prevention - adding an automated verification that catches the issue at startup, not in production.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- IoC Container and Dependency Injection - lifecycle hooks only apply to container-managed beans
- ApplicationContext - the context orchestrates the entire lifecycle sequence

**Builds on this (learn these next):**

- Spring AOP - proxy creation at step 10 is the foundation of AOP
- Bean Scopes - prototype beans have a different lifecycle (no destruction)

**Alternatives / Comparisons:**

- Jakarta CDI lifecycle (`@PostConstruct`/`@PreDestroy`) - same JSR-250 annotations, similar lifecycle
- Micronaut bean lifecycle - compile-time, no reflection-based BPP chain

---

---

# Bean Scopes

**TL;DR** - Bean scope controls how many instances the container creates: singleton (one per context, default), prototype (new instance every time), plus web scopes (request, session) for HTTP-bound state.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every object is either a singleton you manage manually (static fields, double-checked locking) or a new instance every time. No middle ground for request-scoped state, session-scoped carts, or conversation-scoped wizards. You build custom scoping mechanisms for each use case.

**THE BREAKING POINT:**
Your shopping cart service is a singleton. User A's cart items leak into User B's cart because the singleton holds mutable state. Thread safety becomes a nightmare.

**THE INVENTION MOMENT:**
"This is exactly why Bean Scopes were created."

**EVOLUTION:**
Manual singleton pattern -> Spring singleton (container-managed) -> prototype scope -> web scopes (request, session - Spring 2.0) -> custom scopes -> refresh scope (Spring Cloud).

---

### 📘 Textbook Definition

A bean scope defines the lifecycle and visibility of a bean instance within the Spring container. The `singleton` scope (default) creates one instance per ApplicationContext, shared across all injection points. The `prototype` scope creates a new instance for every injection or `getBean()` call. Web scopes (`request`, `session`, `application`) bind instance lifetime to HTTP request, HTTP session, or `ServletContext` respectively. Custom scopes can be registered for specialized lifetime management.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Scope decides how many instances exist and how long each one lives.

**One analogy:**

> Singleton is like a shared office printer - one for everyone. Prototype is like paper cups at the water cooler - new one each time. Request scope is like a visitor badge - created on entry, destroyed on exit.

**One insight:**
The trap: injecting a shorter-lived bean into a longer-lived one. A prototype injected into a singleton is created once and reused forever - defeating the purpose. You need a `Provider<T>` or `ObjectFactory<T>` to get fresh instances.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Singleton beans are created once per ApplicationContext and cached forever (until context closes).
2. Prototype beans have no container-managed destruction. The container creates them and hands them off - no `@PreDestroy` call.
3. Scope mismatch (shorter-scoped bean injected into longer-scoped one) silently breaks expectations unless proxied via `@Scope(proxyMode = ScopedProxyMode.TARGET_CLASS)`.

**DERIVED DESIGN:**
From invariant 1: singletons must be stateless or thread-safe (shared across requests). From invariant 2: prototype beans that hold resources require manual cleanup. From invariant 3: request-scoped beans injected into singletons must use scoped proxies.

**THE TRADE-OFFS:**

**Gain:** Flexible instance management without manual lifecycle code.

**Cost:** Scope mismatch bugs are silent and subtle. Prototype has no auto-destruction.

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Applications need different instance lifetimes (shared service vs per-request state).

**Accidental:** The scoped proxy mechanism (`ScopedProxyMode.TARGET_CLASS`) is a workaround for a type-system limitation.

---

### 🧠 Mental Model / Analogy

> A restaurant kitchen. The head chef (singleton) is always the same person. Each plate (prototype) is made fresh per order. The waiter assigned to your table (request scope) serves only your visit. Your frequent-diner loyalty card (session scope) persists across visits until it expires.

- "Head chef" -> Singleton bean (one instance, shared)
- "Plate" -> Prototype bean (new each time)
- "Waiter for your table" -> Request-scoped bean
- "Loyalty card" -> Session-scoped bean

Where this analogy breaks down: In a restaurant, the waiter knows all tables; in Spring, a request-scoped bean is invisible to other concurrent requests.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Scope is "how many copies exist." Singleton = one copy shared by everyone. Prototype = a fresh copy every time someone asks. Request = one copy per web request.

**Level 2 - How to use it (junior developer):**

```java
@Component
@Scope("prototype")
public class ShoppingCart {
    private final List<Item> items =
        new ArrayList<>();
    public void add(Item i) {
        items.add(i);
    }
}

// Inject prototype correctly:
@Service
public class CheckoutService {
    private final ObjectProvider<
        ShoppingCart> cartProvider;

    CheckoutService(
            ObjectProvider<ShoppingCart>
            cartProvider) {
        this.cartProvider = cartProvider;
    }

    public void checkout() {
        ShoppingCart cart =
            cartProvider.getObject();
        // new instance each call
    }
}
```

**Level 3 - How it works (mid-level engineer):**

| Scope       | Instances            | Lifecycle        | Destruction         |
| ----------- | -------------------- | ---------------- | ------------------- |
| singleton   | 1 per context        | Context lifetime | @PreDestroy         |
| prototype   | New per request      | Caller manages   | NO auto-destroy     |
| request     | 1 per HTTP req       | Request lifetime | Auto at req end     |
| session     | 1 per HTTP session   | Session lifetime | Auto at session end |
| application | 1 per ServletContext | App lifetime     | Auto                |

Scope mismatch trap:

```java
// BUG: prototype injected into singleton
@Service // singleton by default
public class OrderService {
    private final ShoppingCart cart;
    // cart created ONCE, reused forever!
    OrderService(ShoppingCart cart) {
        this.cart = cart;
    }
}
```

**Level 4 - Mastery (senior/staff+ engineer):**

Solutions for scope mismatch:

```java
// Option 1: ObjectProvider (preferred)
@Service
public class OrderService {
    private final ObjectProvider<
        ShoppingCart> carts;
    public void process() {
        ShoppingCart c =
            carts.getObject(); // fresh
    }
}

// Option 2: Scoped proxy
@Component
@Scope(value = "request",
    proxyMode =
    ScopedProxyMode.TARGET_CLASS)
public class RequestContext {
    // CGLIB proxy injected into singleton
    // Delegates to real request-scoped
    // instance at call time
}
```

Spring Cloud's `@RefreshScope` re-creates the bean when `/actuator/refresh` is called - useful for dynamic config without restart.

**The Senior-to-Staff Leap:**

**A Senior says:** "Use singleton for stateless services and prototype for stateful objects."

**A Staff says:** "I design scope boundaries around data ownership. Request scope for per-request audit context, `@RefreshScope` for dynamic configuration, and custom scopes for tenant isolation in multi-tenant systems. I enforce statelessness in singletons via code review and architecture tests."

**The difference:** Staff engineers design custom scope strategies aligned with business boundaries, not just picking from the default list.

**Level 5 - Distinguished (expert thinking):**
Bean scopes are the container's answer to the same lifetime management problem that exists everywhere: React `useState` (component scope), database connection pools (application scope), thread-local variables (thread scope). Custom scopes in Spring (e.g., tenant scope for multi-tenancy) are implemented via the `Scope` interface - just `get()`, `remove()`, and a backing store (usually `ThreadLocal` or `ConcurrentHashMap` keyed by tenant ID). At extreme scale, session scope becomes problematic (sticky sessions break horizontal scaling) - replaced by external session stores (Redis) or stateless JWT tokens.

---

### ⚙️ How It Works

```
  Bean requested
       |
  Check scope type
       |
  singleton?
    -> Check singleton cache
       (ConcurrentHashMap)
    -> Return cached or create once
       |
  prototype?
    -> Create new instance
    -> Inject dependencies
    -> Return (no caching)
       |
  request/session?
    -> Check scope-specific store
       (RequestAttributes /
        HttpSession)
    -> Return existing or create
    -> Register destruction callback
       |
  Bean returned to caller
```

Singleton cache: `DefaultSingletonBeanRegistry` stores instances in `ConcurrentHashMap<String, Object> singletonObjects`. Prototype has no cache - the factory creates and forgets. Request/session scopes use `RequestContextHolder.getRequestAttributes()` to access the HTTP-bound store.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  Dependency injection point
       |
  Container resolves bean
       |
  Scope.get(beanName) <- HERE
       |
  singleton: return cached
  prototype: create new
  request: get from request attrs
       |
  Bean returned to injection point
```

**FAILURE PATH:**
Request-scoped bean accessed outside HTTP context -> `IllegalStateException: No thread-bound request found`. Prototype injected into singleton -> silently becomes a singleton (stale state).

**WHAT CHANGES AT SCALE:**
Singleton: no scaling issue (one instance, thread-safe by design contract). Session scope: problematic at scale (sticky sessions, memory per session). Solution: externalize sessions to Redis, or go stateless with JWTs. Prototype: GC pressure at high throughput (new object per call).

---

### 💻 Code Example

**Example 1 - BAD scope mismatch vs GOOD ObjectProvider:**

```java
// BAD - prototype into singleton
@Service
public class NotificationService {
    // Created once! Reused for ALL calls
    private final Template template;

    NotificationService(Template t) {
        this.template = t;
    }
}

// GOOD - get fresh prototype each time
@Service
public class NotificationService {
    private final ObjectProvider<Template>
        templates;

    NotificationService(
            ObjectProvider<Template> t) {
        this.templates = t;
    }

    public void send(User u) {
        Template t =
            templates.getObject();
        t.setRecipient(u);
        t.send();
    }
}
```

**Example 2 - Request-scoped bean with scoped proxy:**

```java
@Component
@Scope(value =
    WebApplicationContext.SCOPE_REQUEST,
    proxyMode =
    ScopedProxyMode.TARGET_CLASS)
public class AuditContext {
    private String userId;
    private String traceId;

    public void init(String uid, String t) {
        this.userId = uid;
        this.traceId = t;
    }

    public String getUserId() {
        return userId;
    }
}

// Singleton controller safely uses it
@RestController
public class OrderController {
    // CGLIB proxy, delegates to
    // request-scoped real instance
    private final AuditContext audit;

    OrderController(AuditContext audit) {
        this.audit = audit;
    }

    @GetMapping("/orders")
    public List<Order> list() {
        // audit.getUserId() hits the
        // current request's instance
        log.info("User: {}",
            audit.getUserId());
        return orderService.findAll();
    }
}
```

**How to test / verify correctness:**
For prototype: assert `ctx.getBean(T.class) != ctx.getBean(T.class)`. For request scope: use `MockHttpServletRequest` in tests or `@WebMvcTest`.

---

### 📌 Quick Reference Card

**WHAT IT IS:** Controls how many bean instances exist and how long they live.

**PROBLEM IT SOLVES:** Eliminates manual singleton management and enables HTTP-bound state.

**KEY INSIGHT:** Injecting a shorter-scoped bean into a longer-scoped one silently breaks - use `ObjectProvider` or scoped proxies.

**USE WHEN:** Stateful per-request data (audit context), per-session state (cart), or fresh instances (prototype).

**AVOID WHEN:** Making everything prototype "for safety" - singletons are correct for stateless services and far more efficient.

**ANTI-PATTERN:** Mutable state in singleton beans (shared across threads without synchronization).

**TRADE-OFF:** Flexible lifetime management vs. subtle scope mismatch bugs.

**ONE-LINER:** "Singleton = one for all; prototype = fresh each time; request = one per HTTP request."

**KEY NUMBERS:** Singleton is default. Prototype has no `@PreDestroy`. 5 built-in scopes + custom.

**TRIGGER PHRASE:** "Scope mismatch: shorter into longer breaks silently."

**OPENING SENTENCE:** "Bean scope controls instance count and lifetime - singleton (default, one per context), prototype (new each time, no auto-destroy), and web scopes (request, session) - with the critical gotcha that injecting a shorter-scoped bean into a longer-scoped one silently defeats the scope unless you use ObjectProvider or scoped proxies."

**If you remember only 3 things:**

1. Singleton = default, one instance, must be thread-safe
2. Prototype into singleton = silent bug (use ObjectProvider)
3. Prototype has NO @PreDestroy (container creates and forgets)

**Interview one-liner:**
"Singleton is the default (one per context, must be stateless). The biggest trap: injecting a prototype into a singleton creates it once and reuses forever. Fix with ObjectProvider or scoped proxy. And prototype beans get no @PreDestroy - the container forgets them after creation."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Draw a table of all 5 scopes with instance count, lifetime, and destruction behavior
2. **DEBUG:** Given "user A sees user B's data," diagnose mutable state in a singleton bean
3. **DECIDE:** Choose between prototype + ObjectProvider vs request scope for a per-request audit context
4. **BUILD:** Implement a custom tenant scope backed by `ThreadLocal` for multi-tenant isolation
5. **EXTEND:** Recognize scope lifetime patterns in React (component state), HTTP (request context), and database (connection pooling)

---

### 💡 The Surprising Truth

Prototype beans have no container-managed destruction. When you declare `@Scope("prototype")`, Spring creates a new instance for each request but never calls `@PreDestroy`. The container literally forgets the bean after handing it off. If your prototype holds resources (connections, file handles), you must close them manually. This surprises developers who assume all Spring-managed beans get lifecycle callbacks - prototypes are the exception.

---

### ⚖️ Comparison Table

| Dimension    | Singleton          | Prototype         | Request          | Session       |
| ------------ | ------------------ | ----------------- | ---------------- | ------------- |
| Instances    | 1 per context      | New each time     | 1 per HTTP req   | 1 per session |
| Default?     | Yes                | No                | No               | No            |
| Cached?      | Yes (HashMap)      | No                | Request attrs    | HttpSession   |
| @PreDestroy? | Yes                | **No**            | Yes              | Yes           |
| Thread-safe? | Must be            | N/A (not shared)  | N/A (single req) | Must be       |
| Use case     | Stateless services | Stateful per-call | Per-request data | User session  |

**Rapid Decision Tree (30 seconds):**
IF stateless service -> singleton (default)
ELSE IF need fresh mutable instance per call -> prototype + ObjectProvider
ELSE IF per-HTTP-request state -> request scope
ELSE IF per-user across requests -> session scope (or Redis + stateless)

---

### ⚠️ Common Misconceptions

| #   | Misconception                               | Reality                                                                                |
| --- | ------------------------------------------- | -------------------------------------------------------------------------------------- |
| 1   | "Prototype beans get @PreDestroy"           | No. Container creates and forgets. You must clean up manually.                         |
| 2   | "Singleton means one per JVM"               | One per ApplicationContext. Multiple contexts = multiple instances.                    |
| 3   | "Injecting prototype into singleton works"  | It creates the prototype ONCE. Use ObjectProvider or scoped proxy for fresh instances. |
| 4   | "Request scope works in background threads" | No. Requires HTTP request context. Background threads throw IllegalStateException.     |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Scope mismatch - stale prototype in singleton**

**Symptom:** Data from a previous call leaks into the current call. Users see each other's data.

**Root Cause:** Prototype bean injected directly into singleton via constructor - created once, never replaced.

**Diagnostic:**

```java
log.info("Cart identity: {}",
    System.identityHashCode(cart));
// Same hash on every request = stale
```

**Fix:**

BAD: Making the singleton prototype-scoped too (creates everything fresh, wasteful).

GOOD: Inject `ObjectProvider<ShoppingCart>` and call `getObject()` per request.

**Prevention:** Code review rule: never inject `@Scope("prototype")` directly into singleton.

**Failure Mode 2: IllegalStateException - no request context**

**Symptom:** `No thread-bound request found` when accessing request-scoped bean from async thread.

**Root Cause:** Request-scoped beans are bound to the HTTP thread via `ThreadLocal`. Async threads have no request context.

**Diagnostic:**

```java
// Check if request context exists
boolean hasCtx = RequestContextHolder
    .getRequestAttributes() != null;
log.info("Has request: {}", hasCtx);
```

**Fix:**

BAD: Propagating `RequestAttributes` to async threads manually (fragile).

GOOD: Copy needed data from request-scoped bean into the async task before launching.

**Prevention:** Never pass request-scoped beans to `@Async` methods. Pass the data values instead.

**Failure Mode 3: Thread-safety bug in singleton**

**Symptom:** Intermittent wrong results. Race conditions under load. Data corruption.

**Root Cause:** Singleton bean with mutable instance fields accessed by concurrent requests.

**Diagnostic:**

```bash
# Thread dump to detect contention
jcmd <pid> Thread.print | \
  grep -A5 "BLOCKED"
# Or use JFR:
jcmd <pid> JFR.start duration=30s \
  filename=dump.jfr
```

**Fix:**

BAD: Adding `synchronized` to every method (kills throughput).

GOOD: Make the bean stateless (no mutable fields) or use `ThreadLocal` / request scope for per-thread state.

**Prevention:** Enforce rule: singleton beans must have only `final` fields pointing to other singletons or immutable values.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: What are the Spring bean scopes and what is the default?**

_Why they ask:_ Foundational knowledge check.
_Likely follow-up:_ "What happens if you inject a prototype into a singleton?"

**Answer:**
Five built-in scopes:

| Scope                   | Instances            | Lifetime         |
| ----------------------- | -------------------- | ---------------- |
| **singleton** (default) | 1 per context        | App lifetime     |
| prototype               | New per injection    | Caller manages   |
| request                 | 1 per HTTP request   | Request duration |
| session                 | 1 per HTTP session   | Session duration |
| application             | 1 per ServletContext | App lifetime     |

Singleton is the default and correct choice for 90%+ of beans (stateless services, repositories, controllers). Only use other scopes when you need per-call or per-request state.

_What separates good from great:_ Immediately mentioning that prototype has no auto-destruction and that scope mismatch is the #1 trap.

---

**Q2 [MID]: What happens when you inject a prototype-scoped bean into a singleton?**

_Why they ask:_ The most common scope trap - tests practical understanding.
_Likely follow-up:_ "How do you fix it?"

**Answer:**
The prototype bean is created ONCE during singleton initialization and reused forever. It effectively becomes a singleton, defeating its purpose.

```java
// Bug: cart is created once, shared
@Service // singleton
class OrderService {
    private final ShoppingCart cart;
    OrderService(ShoppingCart cart) {
        this.cart = cart; // created once!
    }
}
```

Three fixes:

1. **ObjectProvider** (preferred):

```java
private final ObjectProvider<
    ShoppingCart> carts;
void process() {
    ShoppingCart c =
        carts.getObject(); // new each time
}
```

2. **Scoped proxy** - CGLIB proxy delegates to correct scope at call time
3. **`@Lookup`** method injection (less common)

_What separates good from great:_ Explaining WHY it happens (constructor injection runs once at singleton creation) and recommending `ObjectProvider` over the proxy approach for clarity.

---

**Q3 [MID]: When would you use request scope vs prototype scope?**

_Why they ask:_ Tests decision-making between similar-seeming options.
_Likely follow-up:_ "What about thread safety in request scope?"

**Answer:**
Key difference: request scope = one instance shared across the entire request processing chain. Prototype = new instance every time it is requested.

Use **request scope** when:

- Multiple beans in the same request need to share state (audit context, trace ID)
- State should be automatically cleaned up at request end
- You want `@PreDestroy` called automatically

Use **prototype** when:

- You need a fresh mutable object for a unit of work (builder, template)
- The bean is not tied to HTTP (works in CLI, batch, messaging)
- Different parts of the same request need separate instances

Thread safety: request-scoped beans are inherently thread-safe IF you do not pass them to other threads. Each request has its own instance.

_What separates good from great:_ Noting that request scope is HTTP-bound (fails in async threads) while prototype works anywhere.

---

**Q4 [SENIOR]: Design a multi-tenant scope for a SaaS application.**

_Why they ask:_ Tests ability to extend the framework and design for real-world constraints.
_Likely follow-up:_ "How do you handle scope mismatch with singletons?"

**Answer:**
Implement the `Scope` interface:

```java
public class TenantScope implements Scope {
    private final ThreadLocal<
        Map<String, Object>> store =
        ThreadLocal.withInitial(
            HashMap::new);

    public Object get(String name,
            ObjectFactory<?> factory) {
        Map<String, Object> s =
            store.get();
        return s.computeIfAbsent(
            name, k -> factory.getObject());
    }

    public Object remove(String name) {
        return store.get().remove(name);
    }
}

// Register
@Configuration
class ScopeConfig {
    @Bean
    static CustomScopeConfigurer
            tenantScope() {
        var c =
            new CustomScopeConfigurer();
        c.addScope("tenant",
            new TenantScope());
        return c;
    }
}

// Use
@Component
@Scope("tenant")
class TenantConfig {
    private String dbUrl;
    // One instance per tenant per thread
}
```

The `ThreadLocal` is set at the start of each request by a filter that reads the tenant ID from the JWT/header.

For scope mismatch with singletons: use scoped proxies (`proxyMode = TARGET_CLASS`) so the singleton gets a proxy that delegates to the current tenant's instance at call time.

_What separates good from great:_ Mentioning the cleanup requirement - `ThreadLocal.remove()` must be called at request end to prevent memory leaks in thread pools.

---

**Q5 [SENIOR]: You see "User A's data appearing for User B." How do you diagnose?**

_Why they ask:_ Classic production bug testing systematic debugging.
_Likely follow-up:_ "How do you prevent this class of bugs?"

**Answer:**
Top 3 causes:

1. **Mutable state in singleton** - most common

```java
@Service
class UserService {
    private User currentUser; // BUG!
    // Shared across all requests
}
```

Fix: remove mutable fields, use request scope or method parameters.

2. **Scope mismatch** - prototype into singleton
   Diagnostic: log `System.identityHashCode(bean)` across requests - same hash = stale bean.

3. **ThreadLocal not cleared** - previous request's data bleeds into reused thread
   Diagnostic: log tenant/user ID at request start and end. If start shows wrong value, ThreadLocal was not cleaned.

Systematic approach:

1. Reproduce with two concurrent users
2. Add logging of `identityHashCode` for suspected bean
3. If same hash across users -> singleton with state
4. If ThreadLocal -> check filter cleanup

Prevention: architectural rule - singleton beans must have zero mutable instance fields. Enforce via ArchUnit test.

_What separates good from great:_ The three-pronged diagnosis approach and mentioning the ArchUnit prevention test.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- IoC Container and Dependency Injection - scopes are a DI concept
- Bean Lifecycle - singleton lifecycle differs from prototype lifecycle

**Builds on this (learn these next):**

- Circular Dependencies - scope affects circular dependency resolution
- Spring Cloud RefreshScope - dynamic re-creation of config beans

**Alternatives / Comparisons:**

- CDI scopes (Jakarta EE) - similar but with `@Dependent` instead of prototype
- React component state - UI framework's answer to scope management

---

---

# Circular Dependencies

**TL;DR** - A circular dependency occurs when Bean A needs Bean B and Bean B needs Bean A, creating an unresolvable cycle that causes startup failure with constructor injection - always a design smell that should be fixed architecturally.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Without circular dependency detection, the container would loop forever trying to create A (which needs B, which needs A, which needs B...). Or worse, it would inject a partially constructed object, leading to NPEs at runtime.

**THE BREAKING POINT:**
`OrderService` depends on `InventoryService` for stock checks. `InventoryService` depends on `OrderService` for order history. Neither can be constructed first. The application enters an infinite creation loop.

**THE INVENTION MOMENT:**
"This is exactly why circular dependency detection was created."

**EVOLUTION:**
Undetected loops (crashes) -> Spring setter injection workaround (partial construction) -> `@Lazy` proxies (deferred resolution) -> Spring Boot 2.6+ default to disallowing circular refs -> architectural refactoring as the recommended fix.

---

### 📘 Textbook Definition

A circular dependency exists when two or more beans form a cycle in the dependency graph: A depends on B, and B depends on A (directly or transitively). With constructor injection, this is unresolvable - neither can be instantiated first. Spring detects this at startup and throws `BeanCurrentlyInCreationException`. Prior to Spring Boot 2.6, setter-injected cycles were allowed via partial object injection; since 2.6, all circular references are rejected by default.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Two beans that need each other to be created - a deadlock in the dependency graph.

**One analogy:**

> Two people each holding a door for the other. Neither will go through first. The solution is not to find a trick to go simultaneously - it is to redesign so only one door is needed.

**One insight:**
Circular dependencies are never a framework problem - they are always a design problem. They signal that two classes have entangled responsibilities that should be separated by extracting a third class or using events.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. A bean must be fully constructed before being injected into another bean. Partial injection violates the object's contract.
2. A dependency cycle means no valid topological ordering exists - it is mathematically impossible to satisfy all constructors.
3. Every workaround (`@Lazy`, setter injection) defers the cycle rather than resolving it - the coupling remains.

**DERIVED DESIGN:**
From invariant 1: constructor injection makes cycles immediately visible (fail-fast). From invariant 2: the cycle must be broken by removing one edge in the dependency graph. From invariant 3: `@Lazy` is a band-aid that masks a design problem.

**THE TRADE-OFFS:**

**Gain:** Constructor injection + strict cycle detection forces clean architecture.

**Cost:** Requires refactoring coupled classes, which takes more upfront design effort.

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Some domains have inherently bidirectional relationships (order <-> inventory). The complexity of decoupling them is essential.

**Accidental:** Spring's historical allowance of setter-based cycles gave teams a false sense that cycles were acceptable. Boot 2.6 corrected this by disallowing them.

---

### 🧠 Mental Model / Analogy

> Circular dependencies are like a chicken-and-egg problem in a factory. Machine A cannot start without output from Machine B. Machine B cannot start without output from Machine A. The factory cannot open. The solution: redesign so Machine A uses raw materials directly, and Machine B consumes A's output later. Alternatively, introduce a shared stockpile (third bean) that both machines can access independently.

- "Machine A" -> Bean A
- "Machine B" -> Bean B
- "Cannot start" -> Constructor injection deadlock
- "Shared stockpile" -> Extracted third service

Where this analogy breaks down: In software, the "redesign" is usually extracting shared logic into a separate class, which is cheaper than redesigning physical machines.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
Two components that need each other to be created - like two puzzle pieces that each require the other to be placed first. The solution is to redesign so one does not need the other directly.

**Level 2 - How to use it (junior developer):**

The error you will see:

```
BeanCurrentlyInCreationException:
Error creating bean 'orderService':
Requested bean 'inventoryService'
is currently in creation: Is there
an unresolvable circular reference?
```

Quick fix (temporary):

```java
@Service
public class OrderService {
    OrderService(
        @Lazy InventoryService inv) {
        // Proxy injected, real bean
        // resolved on first use
    }
}
```

Proper fix: extract shared logic.

**Level 3 - How it works (mid-level engineer):**

How Spring detects cycles:

```
Creating OrderService
  -> needs InventoryService
     -> creating InventoryService
        -> needs OrderService
           -> OrderService is
              "currently in creation"
           -> FAIL: circular ref
```

Spring maintains a `Set<String>` of beans currently being created. If a bean is requested that is already in this set, the cycle is detected.

Boot 2.6+ behavior:

- `spring.main.allow-circular-references=false` (default)
- Constructor cycles: always fail
- Setter cycles: also fail by default since 2.6

**Level 4 - Mastery (senior/staff+ engineer):**

Three ways to break cycles, ranked by quality:

1. **Extract shared logic** (BEST):

```java
// Before: A <-> B
// After: A -> C, B -> C
@Service
class SharedLogic { /* extracted */ }
@Service
class OrderService {
    OrderService(SharedLogic shared) {}
}
@Service
class InventoryService {
    InventoryService(SharedLogic shared) {}
}
```

2. **Use events** (GOOD for loose coupling):

```java
// OrderService publishes event
publisher.publishEvent(
    new OrderPlacedEvent(orderId));

// InventoryService listens
@EventListener
void onOrder(OrderPlacedEvent e) {
    reserveStock(e.orderId());
}
// No direct dependency!
```

3. **`@Lazy`** (LAST RESORT - masks the problem):

```java
OrderService(@Lazy InventoryService i){}
// Proxy injected, real bean resolved
// on first method call
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Add `@Lazy` to break the cycle."

**A Staff says:** "A circular dependency means these two classes have entangled responsibilities. I analyze which direction of the dependency is essential and which is incidental, then extract the incidental coupling into an event or a mediator service."

**The difference:** Staff engineers treat cycles as architecture feedback, not framework problems.

**Level 5 - Distinguished (expert thinking):**
Circular dependencies in code mirror circular dependencies in team organization (Conway's Law). Two teams whose services depend on each other bidirectionally will have coordination overhead proportional to the coupling. The architectural fix (events, mediator) reduces team coupling too. At extreme scale, all bidirectional dependencies should become unidirectional via events - this is the fundamental insight behind event-driven architecture and CQRS.

---

### ⚙️ How It Works

```
  Container resolving bean A
       |
  A needs B (constructor param)
       |
  Container starts creating B
       |
  B needs A (constructor param)
       |
  Check "currently creating" set
       |
  A is in the set!
       |
  BeanCurrentlyInCreationException
       |
  Startup fails (fail-fast)
```

The `DefaultSingletonBeanRegistry` maintains `singletonsCurrentlyInCreation` (a `Set<String>`). Before creating a bean, Spring adds its name. After creation completes, it removes it. If during creation, a dependency request finds the bean already in this set, the circular reference is detected.

With `@Lazy`: Spring injects a CGLIB proxy instead of the real bean. The proxy does not trigger creation until the first method call, by which time both beans are fully constructed.

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  Dependency graph resolution
       |
  Topological sort
       |
  Create beans in order <- HERE
       |
  If cycle detected:
    BeanCurrentlyInCreation
    Exception -> startup fails
       |
  If no cycle:
    all singletons created
       |
  Context ready
```

**FAILURE PATH:**
Circular ref detected -> `BeanCurrentlyInCreationException` -> context fails to start -> application never serves traffic. This is the desired behavior: fail-fast.

**WHAT CHANGES AT SCALE:**
At small scale (20 beans): cycles are obvious and easy to fix. At 500+ beans: transitive cycles emerge (A -> B -> C -> D -> A) that are hard to spot. Solution: use ArchUnit or Spring Modulith to detect dependency cycles at test time before they reach production.

---

### 💻 Code Example

**Example 1 - BAD @Lazy workaround vs GOOD extraction:**

```java
// BAD - @Lazy masks the design problem
@Service
public class OrderService {
    OrderService(
            @Lazy InventoryService inv) {
        this.inv = inv;
    }
    public void place(Order o) {
        inv.reserve(o); // proxy -> real
    }
}

@Service
public class InventoryService {
    InventoryService(OrderService orders) {
        this.orders = orders;
    }
    public List<Order> lowStockOrders() {
        return orders.findLowStock();
    }
}

// GOOD - extract + events
@Service
public class OrderService {
    private final StockChecker stock;
    private final EventPublisher events;

    public void place(Order o) {
        stock.verify(o);
        events.publish(
            new OrderPlacedEvent(o));
    }
}

@Service
public class InventoryService {
    private final StockChecker stock;

    @EventListener
    void onOrder(OrderPlacedEvent e) {
        stock.reserve(e.order());
    }
}

@Service  // shared, no cycle
public class StockChecker {
    private final InventoryRepo repo;
    public boolean verify(Order o) {
        return repo.hasStock(o.items());
    }
}
```

**Example 2 - Detecting cycles with ArchUnit:**

```java
@AnalyzeClasses(
    packages = "com.app")
class ArchitectureTest {
    @ArchTest
    static final ArchRule noCycles =
        slices()
            .matching("com.app.(*)..")
            .should().beFreeOfCycles();
}
```

**How to test / verify correctness:**
Run the ArchUnit test in CI. It fails if any package-level dependency cycle exists, catching the problem before it becomes a runtime `BeanCurrentlyInCreationException`.

---

### 📌 Quick Reference Card

**WHAT IT IS:** Two or more beans that depend on each other, forming an unresolvable cycle.

**PROBLEM IT SOLVES:** Spring detects cycles at startup and fails fast instead of silently injecting partial objects.

**KEY INSIGHT:** Circular deps are always a design problem, never a framework limitation.

**USE WHEN:** N/A - you never want circular dependencies. Detect and eliminate them.

**AVOID WHEN:** N/A - always avoid.

**ANTI-PATTERN:** Using `@Lazy` to suppress the cycle without fixing the underlying coupling.

**TRADE-OFF:** Strict detection (constructor injection, Boot 2.6+ defaults) vs. workarounds that hide design issues.

**ONE-LINER:** "If two beans need each other, extract the shared logic into a third."

**KEY NUMBERS:** Boot 2.6+ disallows by default. `@Lazy` defers but does not resolve.

**TRIGGER PHRASE:** "Design problem, not framework problem."

**OPENING SENTENCE:** "A circular dependency is a cycle in the bean graph where A needs B and B needs A - unresolvable with constructor injection. The fix is never @Lazy or setter injection; it is extracting shared logic into a third service or decoupling via events."

**If you remember only 3 things:**

1. Constructor injection makes circular deps fail fast (good!)
2. `@Lazy` is a band-aid, not a fix - the coupling remains
3. Extract shared logic into a third bean or decouple via events

**Interview one-liner:**
"Circular dependencies mean A needs B and B needs A - impossible with constructor injection. Spring fails fast with BeanCurrentlyInCreationException. The fix is architectural: extract shared logic into a mediator, or decouple with ApplicationEvents. @Lazy is a temporary workaround that masks the design issue."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Draw a circular dependency and show three ways to break it (extraction, events, @Lazy) with trade-offs
2. **DEBUG:** Given `BeanCurrentlyInCreationException`, trace the cycle by reading the exception message and propose a fix in 2 minutes
3. **DECIDE:** Choose between extracting a mediator service vs event-based decoupling based on the coupling type
4. **BUILD:** Refactor a real circular dependency into a clean unidirectional architecture
5. **EXTEND:** Apply cycle detection to team architecture (Conway's Law) and system dependencies (service mesh)

---

### 💡 The Surprising Truth

Spring Boot 2.6 changed the default to disallow ALL circular references - including setter-injected ones that previously worked. Many teams upgrading from 2.5 to 2.6 saw startup failures in code that had worked for years. These were latent design problems that Spring had been silently tolerating. The setting `spring.main.allow-circular-references=true` restores old behavior but should be treated as migration debt, not a permanent solution.

---

### ⚠️ Common Misconceptions

| #   | Misconception                           | Reality                                                                                                                          |
| --- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| 1   | "`@Lazy` fixes circular dependencies"   | It defers resolution to first use but the coupling remains. The design problem persists and will cause maintenance pain.         |
| 2   | "Setter injection avoids circular deps" | It allows partial object injection (fragile), and since Boot 2.6, is also disallowed by default.                                 |
| 3   | "Circular deps are a Spring limitation" | They are a design problem. Any DI container would face the same issue. The cycle exists in your architecture, not the framework. |
| 4   | "Small cycles are okay"                 | Even A <-> B cycles indicate entangled responsibilities that grow worse over time as both classes accumulate more shared logic.  |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: BeanCurrentlyInCreationException**

**Symptom:** Startup fails: `Error creating bean 'orderService': Requested bean 'inventoryService' is currently in creation`.

**Root Cause:** Direct constructor cycle: OrderService -> InventoryService -> OrderService.

**Diagnostic:**

```bash
# Exception message names both beans.
# Draw the dependency path from the
# stack trace:
# OrderService -> InventoryService
#   -> OrderService (CYCLE!)
```

**Fix:**

BAD: `@Lazy` on one constructor parameter.

GOOD: Extract shared logic (`StockChecker`) that both depend on. Or decouple via `ApplicationEvent`.

**Prevention:** ArchUnit cycle detection test in CI.

**Failure Mode 2: Transitive cycle not obvious**

**Symptom:** Same exception, but the cycle involves 3+ beans: A -> B -> C -> A.

**Root Cause:** Indirect coupling through intermediate beans.

**Diagnostic:**

```bash
# Read the full exception chain:
# "Error creating bean 'a':
#  ...nested: Error creating bean 'b':
#  ...nested: Error creating bean 'c':
#  Requested bean 'a' is currently..."
# Cycle: a -> b -> c -> a
```

**Fix:**

BAD: Adding `@Lazy` to one link.

GOOD: Identify which edge in the cycle is incidental (not essential) and replace it with an event or mediator.

**Prevention:** `slices().should().beFreeOfCycles()` in ArchUnit.

**Failure Mode 3: Cycle hidden by @Lazy in legacy code**

**Symptom:** No startup failure, but mysterious NPEs or stale data. The `@Lazy` proxy resolves too late or in unexpected order.

**Root Cause:** `@Lazy` was added to suppress `BeanCurrentlyInCreationException` without fixing the design.

**Diagnostic:**

```bash
# Search for @Lazy in the codebase
grep -rn "@Lazy" src/main/java/ | \
  grep -v test
# Each @Lazy is a potential hidden cycle
```

**Fix:**

BAD: Leaving `@Lazy` in place.

GOOD: Remove `@Lazy`, let the cycle surface, then refactor (extract or use events).

**Prevention:** Ban `@Lazy` on constructor parameters via custom ArchUnit rule.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: What is a circular dependency and how does Spring handle it?**

_Why they ask:_ Tests understanding of DI fundamentals.
_Likely follow-up:_ "How would you fix one?"

**Answer:**
A circular dependency is when Bean A requires Bean B and Bean B requires Bean A - forming a cycle. With constructor injection, neither can be created first.

Spring detects this during startup: it maintains a set of beans currently being created. If a bean under construction is requested again, Spring throws `BeanCurrentlyInCreationException` and the application fails to start.

This fail-fast behavior is intentional and correct. It forces you to fix the design rather than running with partial objects.

Since Spring Boot 2.6, even setter-injected cycles are rejected by default.

_What separates good from great:_ Saying "it is a design problem, not a framework problem" and suggesting extraction rather than `@Lazy`.

---

**Q2 [MID]: Compare three ways to break a circular dependency. Which do you prefer?**

_Why they ask:_ Tests ability to evaluate trade-offs.
_Likely follow-up:_ "When would events be better than extraction?"

**Answer:**

| Approach             | Quality | Coupling      | Complexity |
| -------------------- | ------- | ------------- | ---------- |
| Extract shared logic | Best    | Eliminated    | Low        |
| ApplicationEvent     | Great   | Decoupled     | Medium     |
| `@Lazy` proxy        | Poor    | Still coupled | Low        |

**1. Extract:** Move the shared logic into a third service. Both depend on it, neither on each other. Coupling eliminated.

**2. Events:** Publisher fires event, listener reacts. No compile-time dependency. Best when the interaction is "notify" rather than "request-response."

**3. `@Lazy`:** Injects a proxy that defers resolution. The cycle still exists; it is just hidden. I only use this as a temporary measure during migration.

I prefer extraction for synchronous operations and events for asynchronous "fire and forget" scenarios.

_What separates good from great:_ Framing the choice based on the interaction pattern (request-response vs notification) rather than just listing options.

---

**Q3 [MID]: You inherit a codebase with 15 @Lazy annotations on constructors. What is your approach?**

_Why they ask:_ Tests practical refactoring skills.
_Likely follow-up:_ "How do you prioritize which to fix first?"

**Answer:**
Each `@Lazy` is likely hiding a circular dependency. My approach:

1. **Audit:** `grep -rn "@Lazy" src/main/java/ | grep -v test` to list all occurrences
2. **Test:** Remove one `@Lazy` at a time, run app - if `BeanCurrentlyInCreationException`, the cycle is confirmed
3. **Prioritize:** Fix cycles in critical paths first (payment, auth). Non-critical cycles can wait
4. **Refactor:** For each cycle:
   - Draw the dependency graph
   - Identify which direction is incidental
   - Extract or use events

5. **Prevent recurrence:** Add ArchUnit test: `slices().should().beFreeOfCycles()`

I would NOT remove all `@Lazy` at once - incremental migration, one cycle at a time, with tests validating each change.

_What separates good from great:_ The incremental approach and adding the ArchUnit prevention test.

---

**Q4 [SENIOR]: When is @Lazy actually acceptable?**

_Why they ask:_ Tests nuance - not everything is black and white.
_Likely follow-up:_ "What is the risk?"

**Answer:**
`@Lazy` is acceptable in two specific scenarios:

1. **Expensive bean deferred until needed:**

```java
@Service
class ReportService {
    ReportService(@Lazy PdfEngine pdf) {}
    // PdfEngine is heavy (loads fonts,
    // templates) but only used for
    // one endpoint. Defer creation.
}
```

No circular dependency - purely for performance.

2. **Temporary migration debt** with a tracked ticket:
   During migration from Boot 2.5 to 2.6, `@Lazy` can temporarily suppress cycles while the team refactors. The `@Lazy` annotation should have a `// TODO: JIRA-1234 fix cycle` comment and be tracked.

`@Lazy` is NOT acceptable for:

- Permanently hiding circular dependencies
- "It works, do not touch it" attitude
- Avoiding design discussions

Risk: `@Lazy` proxies resolve on first method call. If that call happens in a path where the dependency is not yet fully initialized (rare race condition during startup), you get an NPE or partial state.

_What separates good from great:_ Distinguishing lazy-for-performance (legitimate) from lazy-for-cycles (technical debt).

---

**Q5 [SENIOR]: A service has grown to where OrderService, InventoryService, and NotificationService all depend on each other. How do you untangle this?**

_Why they ask:_ Tests architectural refactoring ability.
_Likely follow-up:_ "How do you ensure the refactoring does not break existing behavior?"

**Answer:**
Step 1: Draw the dependency graph and identify each edge's purpose:

- Order -> Inventory: "check stock" (synchronous, essential)
- Order -> Notification: "notify customer" (async, incidental)
- Inventory -> Order: "get pending orders" (read-only, can be inverted)
- Notification -> Order: "get order details" (read-only, can use event payload)

Step 2: Classify each edge:

- **Essential synchronous**: keep as direct dependency (Order -> Inventory via `StockChecker`)
- **Incidental async**: replace with events (Order publishes `OrderPlacedEvent`, Notification listens)
- **Read-only inverse**: replace with query (Inventory calls a `OrderQueryService` or reads from shared DB view)

Step 3: Refactor incrementally:

1. Extract `StockChecker` (Order -> StockChecker, Inventory -> StockChecker)
2. Replace Order -> Notification with `OrderPlacedEvent`
3. Replace Notification -> Order with event payload containing order details
4. Remove direct Inventory -> Order edge via `OrderQueryService`

Result: zero cycles, all dependencies unidirectional, each service has a single clear purpose.

_What separates good from great:_ Classifying each edge as essential vs incidental before deciding the fix, rather than applying a single pattern to all edges.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- IoC Container and Dependency Injection - circular deps are a DI graph problem
- Bean Lifecycle - understanding creation order explains why cycles deadlock

**Builds on this (learn these next):**

- Spring AOP - proxies add invisible edges to the dependency graph
- Event-Driven Architecture - the primary architectural solution to cycles

**Alternatives / Comparisons:**

- Mediator Pattern - explicit middle-man that breaks bidirectional deps
- CQRS - separate read/write models eliminate many bidirectional dependencies
