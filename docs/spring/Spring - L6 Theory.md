---
layout: default
title: "Spring - L6 Theory"
parent: "Spring"
nav_order: 9
permalink: /spring/l6-theory/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Spring - L6 Theory](#spring---l6-theory) | medium |
| 2 | [Inversion of Control Principle](#inversion-of-control-principle) | architect |
| 3 | [Spring Container Design Internals](#spring-container-design-internals) | architect |

---

# Spring - L6 Theory

Theoretical foundations of the Spring Framework: the
Inversion of Control principle and its software
engineering significance; Spring Container internals
and the refresh lifecycle. For architects who need to
understand not just how Spring works but *why* it was
designed this way.

---

# Inversion of Control Principle

**Interview Weight:** architect / theory - IoC is the
foundational design principle of the Spring Framework.
Candidates at the L5+ level must articulate: what IoC
is, how DI implements IoC, the Hollywood Principle,
why IoC improves testability, and the comparison with
Service Locator. Senior interviews rarely ask this
directly; staff/architect interviews do.

---

### 🎯 Model Answer

**30 seconds:**

> Inversion of Control is a design principle where a
> framework calls your code rather than your code calling
> the framework. In Spring: instead of a class creating
> its own dependencies (`new OrderRepository()`), the IoC
> container creates the dependency and injects it. This
> inverts the flow of control from the class to the
> container. The Hollywood Principle: "Don't call us, we
> will call you." Dependency Injection is the most common
> implementation of IoC in Java.

**3 minutes (Senior):**

> IoC in depth:
>
> **Traditional flow (no IoC)**:
> ```java
> class OrderService {
>     OrderRepository repo = new OrderRepository();
>     //  ^ OrderService controls which impl it uses
>     //  ^ Impossible to replace with a test double
> }
> ```
>
> **IoC flow (DI)**:
> ```java
> class OrderService {
>     private final OrderRepository repo;
>     OrderService(OrderRepository repo) { this.repo = repo; }
>     //  ^ Caller (Spring container) decides the impl
>     //  ^ Easy to inject MockOrderRepository in tests
> }
> ```
>
> IoC enables: testability (inject mocks), configurability
> (swap implementations at runtime), decoupling (classes
> depend on interfaces not implementations).
>
> **Service Locator vs DI**:
> Both implement IoC. Service Locator: the class calls
> the locator to obtain its dependencies (`ServiceLocator
> .get(OrderRepository.class)`). DI: the container
> pushes dependencies into the class.
>
> Why DI is better than Service Locator:
> - DI dependencies are explicit (visible in constructor
>   signature)
> - Service Locator hides dependencies (what does this
>   class need? Have to read its body)
> - Service Locator requires a running locator to test
>   (harder to test in isolation)

**Framework:** CONTROL FLOW INVERTED (framework calls code) →
HOLLYWOOD PRINCIPLE (don't call us) →
DI IMPLEMENTS IOC (push dependencies) →
SERVICE LOCATOR vs DI (explicit vs hidden dependencies) →
TESTABILITY (mock injection enabled)

*Adapting up:* Discuss Martin Fowler's 2004 paper "Inversion
of Control Containers and the Dependency Injection Pattern"
where he coined the term Dependency Injection (previously
called IoC by the community). Discuss IoC as part of the
larger SOLID principles ecosystem (D = Dependency Inversion
Principle, closely related to IoC).

*Adapting down:* IoC = "someone else is in charge". Before
Spring, your code was in charge: `new OrderRepository()`.
With Spring: Spring is in charge. You declare what you
need; Spring creates it and hands it to you. Like a
restaurant vs cooking at home: you declare "I want a steak"
(the dependency), the restaurant (Spring) prepares and
delivers it.

---

### 📘 Concept Explanation

**Control flow comparison:**

```
  WITHOUT IOC (traditional)
  OrderService controls its own dependencies:

  OrderService
    --> new OrderRepository()  [creates]
    --> new EmailService()     [creates]
    --> new AuditLogger()      [creates]

  Problem: OrderService is tightly coupled to
  concrete implementations. Cannot test without
  real database, real email service.

  WITH IOC (Spring DI)
  Spring container controls dependency creation:

  Spring Container
    --> new OrderRepository()  [creates]
    --> new EmailService()     [creates]
    --> new AuditLogger()      [creates]
    --> new OrderService(repo, email, logger)  [injects]

  Result: OrderService only knows about interfaces.
  Container decides the concrete implementations.
  Tests inject mock implementations.
```

**Service Locator vs Dependency Injection:**

```
  SERVICE LOCATOR (IoC via pull)
  class OrderService {
    void placeOrder() {
      // Class pulls what it needs
      OrderRepository repo = ServiceLocator.get(OrderRepository.class);
      EmailService email = ServiceLocator.get(EmailService.class);
    }
  }
  Hidden dependencies: can't tell what OrderService
  needs without reading its code.

  DEPENDENCY INJECTION (IoC via push)
  class OrderService {
    OrderService(OrderRepository repo, EmailService email) {
      // Dependencies declared up front - explicit
    }
  }
  Explicit dependencies: constructor signature is the
  complete dependency contract.
```

---

### 💻 Code Example

**Wrong vs Right: tight coupling vs IoC/DI**

```java
// BAD: class controls its own dependencies
// (violates IoC, untestable)
public class OrderService {

    // Hardcoded concrete impl - impossible to mock
    private final OrderRepository repo =
        new JpaOrderRepository(
            new HikariDataSource(dbConfig));

    public void placeOrder(Order order) {
        repo.save(order);  // Always hits real DB
    }
}

// BAD: Service Locator (hides dependencies)
public class OrderService {
    public void placeOrder(Order order) {
        // What does OrderService depend on?
        // Must read the entire method body to find out.
        OrderRepository repo =
            ServiceLocator.get(OrderRepository.class);
        repo.save(order);
    }
}
```

```java
// GOOD: Constructor injection - explicit, testable, IoC
public class OrderService {

    private final OrderRepository repo;
    private final EventPublisher eventPublisher;

    // Dependencies declared in constructor signature
    // Spring injects concrete impls at runtime
    // Tests inject mocks directly - no Spring needed
    public OrderService(
        OrderRepository repo,
        EventPublisher eventPublisher) {
        this.repo = repo;
        this.eventPublisher = eventPublisher;
    }

    public void placeOrder(Order order) {
        repo.save(order);
        eventPublisher.publish(new OrderPlacedEvent(order));
    }
}

// Test: no Spring, no database, pure unit test
@Test
void placeOrder_savesAndPublishesEvent() {
    OrderRepository mockRepo = mock(OrderRepository.class);
    EventPublisher mockPublisher = mock(EventPublisher.class);
    OrderService service =
        new OrderService(mockRepo, mockPublisher);

    service.placeOrder(new Order("ORD-001"));

    verify(mockRepo).save(any(Order.class));
    verify(mockPublisher).publish(any(OrderPlacedEvent.class));
}
```

> **Code walkthrough:** The Service Locator BAD pattern
> hides dependencies inside method bodies - the class
> signature gives no indication of what it needs. The
> constructor injection GOOD pattern exposes all dependencies
> as constructor parameters. The test illustrates why this
> matters: the test creates `OrderService` with two mocks,
> no Spring context required. This is pure unit testing:
> fast (no startup), deterministic (mocks return predictable
> values), and isolated (no real database). IoC enables
> this by removing the class's control over which
> implementations it uses.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**

> IoC is the foundational principle of Spring and a broader
> design principle for any well-structured object-oriented
> system. It's closely related to the Dependency Inversion
> Principle from SOLID: high-level modules should not
> depend on low-level modules; both should depend on
> abstractions.
>
> The practical consequence: a class that controls its
> own dependencies has an inherent testing problem. To test
> `OrderService`, you need a real `JpaOrderRepository`,
> which needs a real database connection. This cascading
> dependency is broken by IoC.
>
> Why DI over Service Locator: Service Locator is a form
> of IoC but introduces a hidden dependency on the locator
> itself. In a microservices context with Docker/K8s, the
> service locator is often unavailable in the CI test
> environment. Constructor injection has zero external
> dependencies: just create objects with your test doubles.
>
> Martin Fowler's 2004 paper "Inversion of Control
> Containers and the Dependency Injection Pattern" is worth
> reading. It coined the term DI and articulated exactly
> why constructor injection is the best DI mechanism.

*Push deeper:* Discuss field injection (`@Autowired`) vs
constructor injection and why field injection violates IoC
(it uses Spring's reflection-based injection, making the
class dependent on Spring even for tests).

---

### ⚖️ Comparison Table

| Mechanism | Dependencies | Testability | Spring Required |
|---|---|---|---|
| New in constructor (no IoC) | Hidden inside class | Hard (real deps needed) | No |
| Service Locator | Hidden in method bodies | Medium (need locator) | Partially |
| Field injection (@Autowired) | Implicit (reflection) | Medium (Spring needed for tests) | Yes |
| Constructor injection (DI) | Explicit (constructor) | Easy (no Spring needed) | No (for tests) |

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | IoC and DI are the same thing | IoC is the principle (control is inverted). DI is one implementation of IoC. Service Locator is another. IoC is the "what"; DI is the "how". | Candidates who say "IoC means dependency injection" miss the broader design principle |
| 2 | Field injection (@Autowired on fields) is fine for production | Field injection couples the class to Spring's reflection mechanism. It cannot be tested without a Spring context (or Mockito's @InjectMocks, which has its own issues). Constructor injection is universally preferred. | Large codebases with field injection become hard to test and hidden dependency issues emerge |
| 3 | IoC only applies to Spring | IoC is a general software design principle. Jakarta EE CDI, Guice, and even ASP.NET Core use IoC containers. Any framework where the framework calls your code (event handlers, callbacks, lifecycle hooks) is IoC. | Spring-centric thinking misses the principle's broad applicability |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Field injection breaks testing**

Symptom: Unit tests fail with `NullPointerException` on
field-injected dependencies, even though Spring works fine.

Root cause: Field injection (`@Autowired` on private fields)
requires Spring's reflection-based injection. In a pure
unit test without a Spring context, the field is `null`.

Fix: migrate to constructor injection:
```java
// BAD: field injection (NullPointerException in unit tests)
@Service
public class OrderService {
    @Autowired
    private OrderRepository repo;  // null in unit tests
}

// GOOD: constructor injection (testable without Spring)
@Service
public class OrderService {
    private final OrderRepository repo;

    public OrderService(OrderRepository repo) {
        this.repo = repo;
    }
}
```

---

### 🎯 Interview Deep-Dive

**[STAFF] Q1: Why does the Dependency Inversion Principle
(SOLID) relate to Inversion of Control?** [THEORY]

*Why they ask:* Tests knowledge of design principles beyond
the Spring framework.

*Likely follow-up:* "When would you use a Service Locator instead of DI?"

Dependency Inversion Principle (DIP): high-level modules
should not depend on low-level modules. Both should depend
on abstractions (interfaces). Abstractions should not depend
on details; details should depend on abstractions.

IoC is the runtime enforcement of DIP. DIP says: "depend
on OrderRepository (interface)". IoC says: "the container
will inject the concrete implementation at runtime".
Together: `OrderService` depends on `OrderRepository`
(interface). The IoC container injects `JpaOrderRepository`
(implementation). `OrderService` never knows which concrete
implementation it gets.

Without IoC, even if you use interfaces, you still need
`new JpaOrderRepository()` somewhere in `OrderService`.
IoC removes that. The container is the only place where
interfaces are bound to implementations (`@Bean` methods,
`@Component` scanning).

Service Locator is valid when:
- Building a plugin system where plugins are loaded dynamically
- Framework code that needs to look up beans by type
  (e.g., Spring's own internals)
- When injecting into a class that the IoC container cannot
  instantiate (e.g., JPA entities, which are created by
  Hibernate, not Spring)

*What separates good from great:* Connecting DIP to IoC
shows understanding of why IoC is not just a Spring
convenience but an architectural necessity for SOLID design.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with IoC principle definition and DI as implementation. |
| Hiring Manager | Lead with testability benefits of constructor injection. |
| Bar Raiser | Lead with DIP-IoC connection and Service Locator trade-offs. |
| Peer Engineer | "Field injection vs constructor injection - the first code review fight in every Spring project..." |

---

---

# Spring Container Design Internals

**Interview Weight:** architect / theory - Spring container
internals are asked at the Staff/Principal level to assess
deep framework knowledge. Key concepts: ApplicationContext
refresh lifecycle (12-step process), BeanFactory vs
ApplicationContext, circular dependency resolution via
three-level cache, singleton vs prototype scope
implementation, eager vs lazy initialization strategy.

---

### 🎯 Model Answer

**30 seconds:**

> The Spring `ApplicationContext` is built on top of
> `BeanFactory`. The `refresh()` method is the core
> lifecycle: it loads bean definitions, applies
> `BeanFactoryPostProcessor`s (e.g., PropertyPlaceholderConfigurer),
> registers `BeanPostProcessor`s, then instantiates all
> non-lazy singletons. Circular dependency between singleton
> beans is resolved via a three-level cache: `singletonObjects`
> (fully initialized), `earlySingletonObjects` (partially
> constructed), and `singletonFactories` (object factories
> for early exposure).

**3 minutes (Senior):**

> Spring container refresh lifecycle (simplified):
>
> Phase 1: Build bean definitions
> - Parse `@Configuration` classes or XML
> - Register `BeanDefinition` objects (metadata about beans)
> - No instantiation yet
>
> Phase 2: Apply `BeanFactoryPostProcessor`s
> - `PropertyPlaceholderConfigurer` resolves `${...}` in
>   bean definitions before instantiation
> - `ConfigurationClassPostProcessor` processes
>   `@Configuration` and `@Bean` methods
>
> Phase 3: Register `BeanPostProcessor`s
> - `AutowiredAnnotationBeanPostProcessor` (handles
>   `@Autowired`)
> - `CommonAnnotationBeanPostProcessor` (handles `@PostConstruct`)
>
> Phase 4: Instantiate non-lazy singletons
> - Creates all `singleton` scoped beans
> - Applies `BeanPostProcessor`s after each instantiation
>   (`postProcessBeforeInitialization`, `postProcessAfterInitialization`)
> - Runs `@PostConstruct` methods
>
> Circular dependency resolution (setter injection only):
> - Singleton A depends on B; B depends on A
> - Spring creates A's instance (before full initialization)
> - Puts A in `singletonFactories` (level 3 cache)
> - Starts creating B; B needs A
> - A is found in level 3 cache as a factory
> - A's early reference is put in `earlySingletonObjects`
>   (level 2 cache)
> - B is created with A's early reference
> - A is fully initialized, moved to `singletonObjects`
>   (level 1 cache)
> - Note: constructor injection circular deps fail (no
>   early exposure possible before constructor runs)

**Framework:** REFRESH LIFECYCLE (load defs → BFPP → BPP → instantiate) →
THREE-LEVEL CACHE (early exposure for circular deps) →
BEANFACTORY vs APPLICATIONCONTEXT (lazy vs eager) →
SCOPE IMPLEMENTATION (singleton = cached, prototype = new each time)

*Adapting up:* Discuss the `DefaultListableBeanFactory`
internal class hierarchy, how `AnnotationConfigApplicationContext`
processes `@Configuration` via CGLIB proxy (the configuration
class is subclassed to intercept `@Bean` method calls for
singleton caching), and how `SmartInitializingSingleton`
enables post-processing after all singletons are initialized.

*Adapting down:* The Spring container is like a factory
that remembers what it has built. First call: builds and
caches the bean. All subsequent calls: returns the cached
instance. That is the singleton scope.

---

### 📘 Concept Explanation

**ApplicationContext refresh lifecycle:**

```
  refresh() PHASES

  1. prepareRefresh()
     - Set startup time, active flag, validate properties

  2. obtainFreshBeanFactory()
     - Parse @Configuration/@Bean, XML
     - Create BeanDefinition objects
     - No beans instantiated yet

  3. prepareBeanFactory(beanFactory)
     - Register standard BPPs (Aware interfaces, etc.)

  4. postProcessBeanFactory(beanFactory)
     - Hook for subclasses (e.g., web-specific bean scopes)

  5. invokeBeanFactoryPostProcessors(beanFactory)
     - BFPPs run: PropertyPlaceholderConfigurer,
       ConfigurationClassPostProcessor
     - @Bean methods processed, @Import resolved

  6. registerBeanPostProcessors(beanFactory)
     - AutowiredAnnotationBeanPostProcessor registered
     - CommonAnnotationBeanPostProcessor registered

  7. initMessageSource()
  8. initApplicationEventMulticaster()

  9. onRefresh()
     - Subclass hook (e.g., web: create DispatcherServlet)

  10. registerListeners()
      - @EventListener methods registered

  11. finishBeanFactoryInitialization(beanFactory)
      - Instantiate all non-lazy singleton beans
      - For each bean: create, BPP, @PostConstruct, cache

  12. finishRefresh()
      - Publish ContextRefreshedEvent
```

**Three-level cache for circular dependency:**

```
  Level 1: singletonObjects
    -> Fully initialized beans (final state)

  Level 2: earlySingletonObjects
    -> Early-exposed beans (under construction)

  Level 3: singletonFactories
    -> ObjectFactory for creating early references
```

---

### 💻 Code Example

**Production Example: observing container lifecycle**

```java
// Bean lifecycle hooks in order
@Component
public class OrderRepository implements InitializingBean {

    @Value("${db.pool.size:10}")
    private int poolSize;

    // Runs after @Value injection (BPP post-process)
    @PostConstruct
    public void validateConfig() {
        // Phase: postProcessBeforeInitialization done
        // @Value fields are injected
        // This is the safe place for post-injection init
        if (poolSize < 1) {
            throw new IllegalStateException(
                "db.pool.size must be >= 1");
        }
        log.info("OrderRepository init: pool={}", poolSize);
    }

    // Runs after @PostConstruct (InitializingBean is lower
    // priority than @PostConstruct but still before bean
    // is placed in singletonObjects)
    @Override
    public void afterPropertiesSet() {
        // Use @PostConstruct in preference to this
    }

    @PreDestroy
    public void shutdown() {
        // Runs during context close (before singletonObjects cleared)
        // Safe place for connection pool shutdown
    }
}
```

```java
// Observing BeanFactory vs ApplicationContext difference
@Test
void demonstrateEagerVsLazyInit() {
    // BeanFactory (GenericBeanFactory): lazy
    // Beans are NOT created until first getBean() call
    DefaultListableBeanFactory factory =
        new DefaultListableBeanFactory();
    // factory.registerBeanDefinition(...)
    // At this point: no beans exist yet
    // factory.getBean(OrderService.class) <-- creates then

    // ApplicationContext: eager (non-lazy singletons)
    // All non-lazy singletons created during refresh()
    ApplicationContext ctx =
        new AnnotationConfigApplicationContext(AppConfig.class);
    // At this point: ALL singleton beans already created
    // ctx.getBean(OrderService.class) returns cached instance
}
```

```java
// Diagnosing circular dependency in constructor injection
// This FAILS because Spring cannot provide an early reference
// before the constructor runs

// BAD: mutual constructor injection - fails at startup
@Component
public class ServiceA {
    public ServiceA(ServiceB b) { ... }  // Needs B
}

@Component
public class ServiceB {
    public ServiceB(ServiceA a) { ... }  // Needs A
}
// Error: UnsatisfiedDependencyException: circular reference

// GOOD: break the cycle with @Lazy or refactoring
@Component
public class ServiceA {
    public ServiceA(@Lazy ServiceB b) { ... }
    // @Lazy: injects a proxy for B; real B created on first use
}
```

> **Code walkthrough:** The `@PostConstruct` method runs
> after all `@Value` and `@Autowired` injections are
> complete - it is part of the `BeanPostProcessor` phase.
> `AutowiredAnnotationBeanPostProcessor` injects fields in
> `postProcessBeforeInitialization`, then `@PostConstruct`
> runs in `CommonAnnotationBeanPostProcessor.postProcessBeforeInitialization`.
> The `@PreDestroy` method runs when the `ApplicationContext`
> is closed, before the singleton cache is cleared - making
> it the safe place for resource cleanup. The `@Lazy` fix
> for circular constructor injection injects a proxy object
> that delegates to the real bean on first method call,
> breaking the circular instantiation chain.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**

> Understanding the container's refresh lifecycle is essential
> for diagnosing startup failures. The most common issue:
> `@Value` fields are `null` in `@Bean` method parameters
> because `BeanFactoryPostProcessor`s run before most
> `@Value` injection (BPPs run after). If you need a property
> value in a `@BeanFactoryPostProcessor`, use the `Environment`
> interface directly.
>
> The three-level cache for circular dependencies:
> only `setter` and `field` injection circular deps can be
> resolved. Constructor injection circular deps fail at
> startup because there is no way to provide an early
> reference before the constructor completes. The fix is
> either to refactor (remove the circular dependency) or
> use `@Lazy` on one injection point.
>
> `@Configuration` class internals: Spring subclasses
> `@Configuration` classes via CGLIB. When you call one
> `@Bean` method from another, Spring intercepts the call
> and returns the cached singleton from `singletonObjects`
> rather than creating a new instance. This is why `@Bean`
> methods in `@Configuration` classes return singleton
> instances. In `@Component` classes (lite mode), no CGLIB
> proxy - calling one `@Bean` method from another creates
> a new instance.

*Push deeper:* Discuss the `SmartInstantiationAwareBeanPostProcessor`
interface and how `AbstractAutoProxyCreator` (AOP proxy
creation) hooks into the three-level cache to create AOP
proxies as the "early reference" for beans involved in
circular dependencies.

---

### ⚖️ Comparison Table

| Feature | BeanFactory | ApplicationContext |
|---|---|---|
| Bean initialization | Lazy (on first getBean()) | Eager (during refresh()) |
| I18n / MessageSource | No | Yes |
| Event publishing | No | Yes (@EventListener) |
| AOP auto-proxy | No | Yes |
| Environment / Properties | Limited | Full @Value, @PropertySource |
| Startup cost | Low (no eager init) | Higher (all singletons created) |
| When to use | Embedded, resource-constrained | All standard Spring apps |

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | @Configuration beans are plain Java objects | @Configuration classes are CGLIB-proxied by default. Calling one @Bean method from another returns the cached singleton. Use @Configuration(proxyBeanMethods=false) only when @Bean methods don't call each other (enables faster startup, smaller bytecode). | Disabling proxyBeanMethods breaks singleton behavior for inter-@Bean calls |
| 2 | Circular dependencies always fail | Setter/field injection circular deps between singletons are resolved by the three-level cache. Only constructor injection circular deps fail. Spring 6 (Boot 3) started requiring explicit opt-in for circular deps: `spring.main.allow-circular-references=true`. | Hidden circular deps can cause startup failures after Boot 3 upgrade |
| 3 | Bean instantiation order is deterministic | Spring guarantees that beans are instantiated after their dependencies but does not guarantee instantiation order among independent beans. Order between beans of the same type or without dependency relationships can vary. | Code that assumes Bean A always initializes before Bean B (without a declared dependency) may fail intermittently |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - @Value is null in @Bean method**

Symptom: `@Value("${prop}")` field in a `@Configuration`
class is `null` when a `@Bean` method uses it.

Root cause: `BeanFactoryPostProcessor`s run before most
beans are instantiated. If a `@Configuration` class
implements `BeanFactoryPostProcessor`, it is instantiated
very early (before property injection).

Fix: do NOT inject `@Value` in classes that implement
`BeanFactoryPostProcessor`. Use `Environment` directly:

```java
@Component
public class EarlyProcessor implements BeanFactoryPostProcessor {

    // BAD: null because BFPPs run before @Value injection
    // @Value("${feature.enabled}") private boolean enabled;

    // GOOD: use Environment for early access
    @Autowired
    private Environment env;

    @Override
    public void postProcessBeanFactory(
        ConfigurableListableBeanFactory factory) {
        boolean enabled =
            env.getProperty("feature.enabled", Boolean.class,
                false);
    }
}
```

---

### 🎯 Interview Deep-Dive

**[STAFF] Q1: How does Spring resolve circular dependencies
between singleton beans, and why does constructor injection
fail?** [THEORY + INTERNALS]

*Why they ask:* Tests deep container knowledge and design reasoning.

*Likely follow-up:* "How does the three-level cache interact with AOP proxy creation?"

**Why setter injection circular deps succeed:**

Spring creates bean A: `A = new A()` (no args constructor
runs). A is not fully initialized yet but has an instance.
Spring stores an `ObjectFactory` for A in `singletonFactories`
(level 3 cache).

Spring starts creating bean B. B needs A.
Spring finds A's factory in level 3 cache.
Spring calls the factory, gets A's early reference.
Spring stores early A in `earlySingletonObjects` (level 2).
B is fully created with early-reference A.

Spring returns to finishing A: injects B into A's setter.
A is fully initialized. Moved to `singletonObjects` (level 1).

Both beans are complete. A references B (fully initialized).
B references A (now fully initialized, same instance as early ref).

**Why constructor injection fails:**

Spring tries to create A: needs B for constructor.
Spring starts creating B: needs A for constructor.
Spring tries to create A again: already being created.
Circular dependency detected - exception thrown.

Constructor injection fails because there is no "instance
without running the constructor" concept. The three-level
cache requires an early instance reference, which is only
possible after the constructor runs successfully.

**AOP proxy interaction (Staff level):**
When AOP wraps a bean involved in a circular dep, the
`AbstractAutoProxyCreator.getEarlyBeanReference()` method
creates the proxy early and puts it in `earlySingletonObjects`.
This ensures the other bean gets a reference to the proxy
(not the raw target) - critical for AOP advice to work
on all callers.

*What separates good from great:* Understanding that the
three-level cache serves two purposes: circular dependency
resolution AND ensuring AOP-proxied beans get the proxy
(not the target) as the early reference. Missing the AOP
aspect is a common gap.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with the three levels and what each stores. |
| Hiring Manager | Lead with what can go wrong and how to diagnose it. |
| Bar Raiser | Lead with constructor injection limitation, AOP proxy interaction, and @Configuration CGLIB internals. |
| Peer Engineer | "The 'circular reference after Spring Boot 3 upgrade' bug that only appears in the test profile but not in prod..." |

---

