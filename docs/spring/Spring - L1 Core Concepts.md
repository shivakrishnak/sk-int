---
layout: default
title: "Spring - L1 Core Concepts"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 2
permalink: /spring/l1-core-concepts/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Spring - L1 Core Concepts](#spring---l1-core-concepts) | medium |
| 2 | [Dependency Injection](#dependency-injection) | medium |
| 3 | [Spring Bean](#spring-bean) | medium |
| 4 | [ApplicationContext](#applicationcontext) | medium |

---

# Dependency Injection

---
id: SPR-004
title: Dependency Injection
category: Spring
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #spring, #dependency-injection, #ioc, #design-pattern
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical - foundational concept tested in every Spring
interview. Cannot skip this.

---

### 🎯 Model Answer

**30 seconds:**
> Dependency Injection is a design pattern where an object's dependencies are
> provided to it from the outside rather than the object creating them itself.
> In Spring, the IoC container creates your objects and injects the dependencies
> they need at construction time. The key benefit is that your code depends on
> abstractions (interfaces) instead of concrete classes, making it testable and
> loosely coupled.

**3 minutes (Senior):**
> Dependency Injection is the runtime implementation of the Dependency Inversion
> Principle (the D in SOLID). The idea is simple: instead of writing
> `new PaymentService()` inside OrderService, you declare that OrderService
> needs a PaymentService in its constructor, and the Spring container wires the
> right implementation in at startup.
>
> There are three injection styles: constructor injection (preferred - makes
> dependencies explicit and final), setter injection (for optional dependencies),
> and field injection (via @Autowired on fields - convenient but hides
> dependencies and breaks non-Spring tests).
>
> The trade-off is a shift in where configuration lives: instead of your code
> controlling what it uses, a central configuration (Spring context) controls
> what gets wired where. This makes the whole wiring graph visible in one place
> but requires understanding the container to debug wiring errors.
>
> The non-obvious insight: DI is not just about testing. It is about making the
> dependency graph of your entire application explicit and manageable. In a large
> system, the wiring graph tells you everything about how components interact.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers discuss DI containers vs service locators
(the anti-pattern DI replaced), and the implications for cyclic dependency
detection at startup.

*Adapting down:* Junior - "Instead of your class creating its own helpers,
Spring creates and provides them. Makes testing easy because you can swap
in fakes."

**Blank Mind Recovery:**

**(1) Restate:** "So you are asking about Dependency Injection - let me think
through what problem it solves."

**(2) First principles:** "Every object needs collaborators. The question is
who creates them. If the object creates its own, it is tightly coupled. If
something external provides them, the object is loosely coupled."

**(3) Bridge:** "This reminds me of a restaurant kitchen. A chef (your object)
needs ingredients (dependencies). The chef could go buy them (tight coupling),
or the kitchen manager (Spring) provides them (DI)."

---

### 📘 Concept Explanation

**What it is:**
Dependency Injection is the mechanism by which an object receives its required
collaborators (dependencies) from an external source rather than creating them
internally. In Spring, the ApplicationContext (IoC container) is that external
source.

**The problem it solves:**
When objects create their own dependencies, changes cascade - modifying
PaymentService's constructor breaks every class that calls `new PaymentService()`.
Testing is impossible without real dependencies. Alternatives are hard to swap in.
DI solves this by moving dependency creation to a central configuration point and
injecting through interfaces, not concrete types.

**How it works:**

```
Without DI (tight coupling):
  OrderService:
    private PaymentSvc ps = new PaymentSvc(); <- hardcoded

With DI (loose coupling):
  OrderService:
    private final PaymentSvc ps; // declared need

  Spring container:
    reads: "OrderService needs PaymentSvc"
    finds: @Service PaymentSvcImpl implements PaymentSvc
    creates: both objects
    injects: passes PaymentSvcImpl to OrderService constructor
    result: wired, testable object graph
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Three injection styles:
1. **Constructor injection**: dependencies in constructor signature (preferred)
2. **Setter injection**: @Autowired on setter method (optional dependencies)
3. **Field injection**: @Autowired on field (avoid - hides dependencies)

**The key insight:**
DI inverts the direction of dependency creation. The caller no longer reaches
out to find what it needs - the container delivers what is needed to the caller.
This inversion is why it's called Inversion of Control (IoC).

**When to use it:**
- All application code that has dependencies on other components
- When testability with mock dependencies is required
- When the implementation of a dependency might change (e.g., swap database)

**When NOT to use it:**
- Value objects, DTOs, simple data holders - these are created with `new`
- Objects with state that varies per request (use request-scoped beans, or
  create inside a method, not in the container)

**Alternatives:**
- Service Locator -> objects look up dependencies from a registry; still
  couples to the registry; harder to test than DI
- Factory pattern -> manual wiring; verbose but explicit; no container needed
- Dependency Injection Framework without Spring -> Guice, Dagger for Android

**First-principles derivation:**
If object A needs object B, one of three things must happen: A creates B
(tight coupling), A looks up B (service locator - still coupling to the
registry), or someone else creates B and gives it to A (DI). DI is the only
option that gives A complete independence from how B is created or configured.

---

### 💻 Code Example

```java
// BAD: Service locator anti-pattern (worse than new)
public class OrderService {
    public void placeOrder(Order o) {
        // Coupled to the locator - can't test without it
        PaymentService ps =
            ServiceLocator.get(PaymentService.class);
        ps.charge(o);
    }
}
```

> **Code walkthrough:** Service locator is the anti-pattern DI replaced. The
> class hides its dependency behind a static lookup, making it impossible to
> see what OrderService needs just by reading its constructor. Tests must
> configure the ServiceLocator before running. DI makes dependencies visible
> and eliminates this hidden coupling.

```java
// GOOD: Constructor injection (Spring's preferred style)
@Service
public class OrderService {
    private final PaymentService paymentService;
    private final InventoryService inventoryService;

    // All dependencies explicit in constructor signature
    public OrderService(
            PaymentService paymentService,
            InventoryService inventoryService) {
        this.paymentService = paymentService;
        this.inventoryService = inventoryService;
    }

    public OrderResult placeOrder(Order order) {
        inventoryService.reserve(order);
        return paymentService.charge(order);
    }
}
```

> **Code walkthrough:** Constructor injection makes all dependencies explicit
> and allows them to be final. Any developer reading this class immediately
> knows it needs a PaymentService and InventoryService. Spring finds beans
> matching those types and injects them. In tests, `new OrderService(mockPay,
> mockInv)` works without any Spring context.

```java
// Production: three injection styles compared
@Service
public class NotificationService {

    // Style 1: Constructor (PREFERRED - explicit, final)
    private final EmailSender emailSender;

    // Style 2: Setter (for optional collaborators)
    private SmsSender smsSender;

    // Style 3: Field (AVOID - hides dependency)
    @Autowired
    private AuditLogger auditLogger;

    public NotificationService(EmailSender emailSender) {
        this.emailSender = emailSender;
    }

    @Autowired(required = false)
    public void setSmsSender(SmsSender smsSender) {
        this.smsSender = smsSender;
    }

    public void notify(String message) {
        emailSender.send(message);
        if (smsSender != null) smsSender.send(message);
        auditLogger.log(message);
    }
}
```

> **Code walkthrough:** All three styles in one class. Constructor injection
> handles the mandatory EmailSender - it is final and always set. Setter
> injection handles optional SmsSender (required = false). Field injection
> on auditLogger is shown to illustrate the anti-pattern - it hides the
> dependency and requires Spring to set a private field via reflection,
> breaking plain instantiation outside Spring.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Dependency Injection means your class declares what it needs in its
> constructor, and Spring creates and provides those dependencies automatically.
> Instead of writing `new PaymentService()` inside OrderService, you put
> PaymentService in the constructor, annotate with @Service, and Spring
> handles the rest. This makes unit testing easy because you can pass in mock
> objects directly.

*Push deeper:* Explain the three injection types (constructor, setter, field)
and why constructor injection is preferred: makes dependencies visible, allows
final fields, and works outside Spring in tests.

---

**Senior / Staff (5+ years):**
> Dependency Injection is the runtime implementation of the Dependency Inversion
> Principle. Spring's container builds a directed acyclic graph of objects at
> startup by analyzing constructor signatures and @Autowired annotations. The
> container handles ordering - beans are created in dependency order. The
> key benefit is not just testability: DI makes the architectural dependency
> graph of your entire application explicit and auditable. Running
> `context.getBeanDefinitionNames()` gives you a complete map of your
> application's component wiring.

*Push deeper:* Discuss circular dependency detection - Spring detects dependency
cycles at startup with constructor injection (fails fast) but can defer them
with setter/field injection (can cause issues). Spring Boot 2.6+ by default
prohibits circular dependencies - you must explicitly allow them.

---

### ⚠️ Common Misconceptions

**Misconception 1: "DI and IoC are the same thing."**
IoC (Inversion of Control) is the broad principle - inverting who controls
object lifecycle. DI is one specific mechanism implementing IoC. Other IoC
patterns exist (Service Locator, Event-driven). In Spring, the container
uses DI to implement IoC.

**Misconception 2: "Field injection is fine, it is easier."**
Field injection hides dependencies (you can't tell what a class needs without
reading the whole class), prevents final fields, and requires Spring's reflection
to set private fields. A class with field injection cannot be tested with
plain `new`. Constructor injection is superior in every measurable way.

**Misconception 3: "You must use @Autowired for injection to work."**
Since Spring 4.3, if a class has exactly one constructor, Spring uses it for
injection without @Autowired. @Autowired is only needed for setter/field
injection, or when there are multiple constructors and you need to designate
which one Spring uses.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: NoSuchBeanDefinitionException on startup**
Symptom: "No qualifying bean of type 'X' available."
Cause: The bean is not in the Spring context.
Diagnosis: Check if the class is annotated with @Component/@Service, that it
is in the component scan path, and no @Conditional excluded it.
Fix: Add annotation or add @Bean factory method in @Configuration.

**Failure 2: Circular dependency at startup**
Symptom: "The dependencies of some of the beans in the application context
form a cycle."
Cause: A -> B -> A dependency cycle in constructor injection.
Diagnosis: Spring prints the full cycle in the error message.
Fix: Extract a shared dependency to break the cycle, or use @Lazy on one
injection point to defer resolution.

**Failure 3: NullPointerException in test for @Autowired field**
Symptom: Service method throws NPE because a field is null in a unit test.
Cause: @Autowired field injection - Spring sets the field; plain new doesn't.
Fix: Switch to constructor injection so `new Service(mock)` works in tests.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - What is the difference between DI and IoC?

IoC (Inversion of Control) is the broad principle: instead of application
code controlling the creation and lifecycle of its dependencies, control is
inverted to a container or framework. DI (Dependency Injection) is the most
common implementation of IoC: the container injects dependencies into your
objects.

Other IoC patterns include: Service Locator (objects look up dependencies),
Template Method (framework calls your hook methods), Event Listeners (framework
calls your handlers). DI is the cleanest because it leaves your objects with
no coupling to the container.

*What separates good from great:* The Service Locator is also IoC but is an
anti-pattern because objects still reach out to the container to get
dependencies - the coupling shifts from "new ConcreteType" to "registry.get
(AbstractType)" but is still coupling. DI eliminates the coupling entirely.

---

#### Q2 - Why is constructor injection preferred over field injection?

Four concrete reasons:
1. **Explicit dependencies**: constructor signature shows all required
   dependencies. Field injection hides them.
2. **Immutability**: constructor-injected fields can be final. Field-injected
   fields cannot.
3. **Testability**: `new MyService(mockDep)` works without any framework.
   Field injection requires Spring or Mockito's @InjectMocks to set fields.
4. **Fail-fast**: circular dependencies detected at startup. Field injection
   defers detection.

Constructor injection is the official Spring team recommendation (documented
in Spring's own style guide).

*What separates good from great:* Lombok's @RequiredArgsConstructor generates
a constructor for all final fields, eliminating the constructor boilerplate
while keeping constructor injection semantics.

---

#### Q3 - What is a circular dependency and how do you fix it?

A circular dependency exists when Bean A depends on Bean B and Bean B depends
on Bean A (directly or transitively). With constructor injection, Spring
detects this at startup and throws BeanCurrentlyInCreationException.

Detection: the error message names the full cycle.

Fixes:
1. **Redesign**: extract a shared dependency C that A and B both depend on.
   This is the best fix - circular dependencies often indicate a design smell.
2. **@Lazy on one injection**: defer one side's initialization.
   `OrderService(@Lazy PaymentService ps)` - PaymentService is created on
   first use rather than at startup.
3. **Setter injection on one side**: Spring can use setter injection to
   break constructor cycles by first creating both objects (without full
   wiring) then calling setters.

*What separates good from great:* Spring Boot 2.6+ prohibits circular
dependencies by default. You can re-enable them with
spring.main.allow-circular-references=true, but the right answer is to
redesign to remove the cycle.

---

#### Q4 - What is @Qualifier and when do you use it?

@Qualifier disambiguates when Spring finds multiple beans of the same type
and does not know which to inject. You annotate the injection point with
@Qualifier("beanName") to specify which bean to use.

```java
@Autowired
@Qualifier("fastPaymentService")
private PaymentService paymentService;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

@Qualifier can also be used on bean definitions:
```java
@Bean
@Qualifier("fastPaymentService")
public PaymentService fastPaymentService() { ... }
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Alternative to @Qualifier: @Primary marks one bean as the default choice
without requiring injection-point annotations.

*What separates good from great:* Custom qualifier annotations are more
type-safe: create `@FastPayment` as a meta-annotation of @Qualifier. This
gives you compile-time safety vs string-based @Qualifier("fastPayment").

---

#### Q5 - How does Spring resolve which bean to inject when there are multiple candidates?

Spring's resolution algorithm in order:
1. Type match: find all beans matching the declared type.
2. @Primary: if one candidate is @Primary, use it.
3. @Qualifier: if injection point has @Qualifier, filter by name.
4. Name match: if the field/parameter name matches a bean name, prefer it.
5. Exception: if still ambiguous, throw NoUniqueBeanDefinitionException.

If no bean matches the type at all: NoSuchBeanDefinitionException.

*What separates good from great:* In practice, relying on name-matching
(step 4) is fragile - refactoring the field name breaks the wiring silently.
Always use @Primary or @Qualifier for explicit disambiguation in production
code.

---

#### Q6 - Can you inject a list of all beans of the same type?

Yes. Declare `List<SomeInterface>` as the injection point and Spring injects
all beans implementing that interface.

```java
@Service
public class NotificationDispatcher {
    private final List<NotificationChannel> channels;

    public NotificationDispatcher(
            List<NotificationChannel> channels) {
        this.channels = channels;
    }

    public void notifyAll(String message) {
        channels.forEach(c -> c.send(message));
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Spring collects all beans implementing NotificationChannel (EmailChannel,
SmsChannel, PushChannel, etc.) and injects them as a list. Adding a new
channel requires only creating a new @Service that implements the interface -
no changes to the dispatcher.

*What separates good from great:* You can inject Map<String, Interface> to
get a map from bean name to bean. Useful when you need to select a strategy
by name at runtime.

---

#### Q7 - What is @Autowired(required = false) used for?

@Autowired(required = false) marks an optional dependency. If no matching bean
exists, Spring leaves the field null rather than throwing
NoSuchBeanDefinitionException.

Use cases:
- Optional features: SMS notification only if an SmsSender bean is configured
- Backwards compatibility: new dependency added to an existing service that
  some deployments may not have configured

```java
@Autowired(required = false)
private MetricsReporter metricsReporter;

public void process(Order order) {
    // work...
    if (metricsReporter != null) {
        metricsReporter.record("order.processed");
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The modern alternative to @Autowired(required
= false) is using Optional<T> as the injection type:
`Optional<SmsSender> smsSender`. This forces you to explicitly handle the
absent case and makes the optionality visible in the type signature.

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# Spring Bean

---
id: SPR-005
title: Spring Bean
category: Spring
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
tags: #spring, #bean, #ioc, #container, #component
status: draft
sd: false
version: 1
---

🎯 Interview Weight: Critical - "What is a Spring bean?" is asked in every
Spring interview to gauge foundational understanding.

---

### 🎯 Model Answer

**30 seconds:**
> A Spring bean is simply a Java object that is created, configured, and
> managed by the Spring IoC container. Any class annotated with @Component
> (or its specializations @Service, @Repository, @Controller) becomes a
> bean candidate. The container instantiates it, injects its dependencies,
> and manages its lifecycle from creation to destruction.

**3 minutes (Senior):**
> A Spring bean is an object instance whose lifecycle - creation, dependency
> injection, initialization, use, and destruction - is managed by the Spring
> ApplicationContext. Beans are registered by annotating classes with
> @Component and its specializations, or by declaring @Bean factory methods
> in @Configuration classes.
>
> Every bean has a scope: singleton (default - one instance per context),
> prototype (new instance per request), request, session. Singleton is by
> far the most common - most Spring services are stateless and safe to share.
>
> Beans have a name (defaulting to the class name in camelCase) and a type.
> Spring's type-safe injection matches beans by type first, name second.
>
> The non-obvious thing: the bean registry is separate from bean instances.
> The registry holds BeanDefinition objects (metadata). Actual instances are
> created lazily or eagerly depending on scope and configuration. Understanding
> this two-phase model (definitions vs instances) explains why startup errors
> happen at definition time (duplicate names) vs injection time (type
> mismatches).

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff level - bean definitions can be modified by
BeanFactoryPostProcessors before instances are created. This is how
PropertySourcesPlaceholderConfigurer resolves @Value expressions.

*Adapting down:* Junior - "A Spring bean is any Java class that Spring knows
about and manages for you. Add @Service or @Component and Spring creates it
and wires it for you."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking what a Spring bean is - let me start from
what the container does."

**(2) First principles:** "Spring's core job is managing Java objects. Any
object Spring manages - creates, wires, and destroys - is a bean."

**(3) Bridge:** "Think of beans as Spring's managed inventory. The
ApplicationContext is the warehouse; beans are the items in it."

---

### 📘 Concept Explanation

**What it is:**
A Spring bean is any Java object instantiated and managed by the Spring IoC
container. The container owns the lifecycle: it creates the bean, injects
dependencies, calls initialization callbacks, serves it for the application's
use, and calls destruction callbacks on shutdown.

**The problem it solves:**
Without a container, every application needs boilerplate code to create
objects in the right order, wire their dependencies, and manage their
lifecycle. Beans let you declare what you need (via annotations or @Bean
methods) and let the container handle all the plumbing.

**How it works:**

```
Bean registration (startup):
  classpath scan -> finds @Component classes
  @Configuration -> reads @Bean methods
  XML -> reads <bean> elements
  -> creates BeanDefinition for each

Bean instantiation (startup for singletons):
  for each singleton BeanDefinition:
    1. instantiate (call constructor / factory method)
    2. inject dependencies
    3. call BeanPostProcessors (pre-init)
    4. call @PostConstruct / afterPropertiesSet()
    5. call BeanPostProcessors (post-init) -> AOP proxy
    6. register in singleton cache

Application use:
  context.getBean(OrderService.class)
    -> returns cached singleton instance

Shutdown:
  1. call @PreDestroy / destroy()
  2. release resources
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**
The singleton cache is the core. Spring creates singleton beans once at
startup and returns the same instance for every injection. This is why
Spring singletons must be thread-safe: they are shared across all threads.
Stateful data must never be stored in fields of singleton beans.

**When to use it:**
- All application components: services, repositories, controllers, config
- Infrastructure beans: DataSource, EntityManagerFactory, transaction manager
- Any object with complex initialization that benefits from lifecycle management

**When NOT to use it:**
- Value objects and DTOs: created with `new` where needed
- Per-request state: use local variables or request-scoped beans
- Heavy objects created frequently: use a prototype factory pattern

**Alternatives:**
- Plain Java factories: more control, less magic, more boilerplate
- Guice @Inject: Google's lightweight DI alternative
- CDI @ApplicationScoped: Jakarta EE equivalent of Spring singleton bean

**First-principles derivation:**
An application needs objects. Objects have three concerns: creation (who
creates them and with what args), wiring (who provides collaborators), and
lifecycle (who calls init/destroy). Centralising all three in a container
(the bean model) is the simplest design that handles all three.

---

### 💻 Code Example

```java
// BAD: Manual lifecycle management (what beans replace)
public class AppConfig {
    // Must create in right order manually
    public static OrderService orderService() {
        DataSource ds = new HikariDataSource(/* config */);
        OrderRepository repo = new OrderRepositoryImpl(ds);
        PaymentService ps = new PaymentServiceImpl();
        return new OrderService(repo, ps);
    }
    // On shutdown: must call close() manually
}
```

> **Code walkthrough:** Manual wiring is what Spring replaces. It requires
> knowing the dependency order (DataSource before Repository before Service),
> manually passing references, and handling lifecycle (calling close on
> DataSource on shutdown). For 5 objects this is manageable; for 500 objects
> it becomes maintenance nightmare.

```java
// GOOD: Spring bean declaration (three styles)

// Style 1: Component scanning (most common)
@Service  // Implicitly @Component - Spring discovers this
public class OrderService {
    public OrderService(OrderRepository repo,
                        PaymentService ps) { /* ... */ }
}

// Style 2: @Bean factory method (for third-party classes)
@Configuration
public class DataConfig {
    @Bean
    public DataSource dataSource(
            @Value("${db.url}") String url) {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl(url);
        return ds;
    }
}

// Style 3: @Bean with lifecycle callbacks
@Configuration
public class CacheConfig {
    @Bean(initMethod = "start",
          destroyMethod = "stop")
    public CacheManager cacheManager() {
        return new HazelcastCacheManager();
    }
}
```

> **Code walkthrough:** Three ways to register beans. @Service is the most
> common - use it for classes you write. @Bean factory methods are necessary
> for third-party library classes (like HikariDataSource) that you cannot
> annotate yourself. The destroyMethod ensures the cache manager is cleanly
> stopped on application shutdown, preventing resource leaks.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A Spring bean is any Java object that Spring creates and manages for you.
> You mark a class with @Service, @Repository, or @Component, and Spring
> registers it as a bean. Spring creates one instance (by default), injects
> all its dependencies, and it is ready to use. The container stores all
> beans and returns the same instance every time it is needed.

*Push deeper:* Explain the default scope (singleton) and that all Spring
services should be stateless to be thread-safe when shared.

---

**Senior / Staff (5+ years):**
> A bean is a managed object in the Spring ApplicationContext - its full
> lifecycle (instantiation, DI, initialization, destruction) is controlled
> by the container. Beans start as BeanDefinitions (metadata objects
> describing how to create them). Singleton beans are instantiated at context
> refresh; prototype beans are created fresh on each getBean() call. The
> important production implication is that singleton beans are shared across
> all threads - they must be stateless. Any request-specific state must live
> in local variables or request-scoped beans, not in singleton fields.

*Push deeper:* BeanDefinitions can be modified by BeanFactoryPostProcessors
before any bean is instantiated. This is how placeholder resolution
(@Value with property references) works - PropertySourcesPlaceholderConfigurer
is a BFPP that substitutes ${...} in BeanDefinitions before the beans are
created.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Spring creates a new bean instance for every request."**
By default (singleton scope), Spring creates ONE instance per ApplicationContext
and returns the same instance on every injection. A new instance is only
created with prototype scope or request/session scope in web applications.

**Misconception 2: "@Bean and @Component do the same thing."**
Both register beans, but differently. @Component (and @Service etc.) triggers
classpath scanning to discover the annotated class. @Bean is a factory method
inside a @Configuration class - used when you need programmatic control over
bean creation or when the class you want as a bean is a third-party class you
cannot annotate.

**Misconception 3: "All Spring beans are singleton design pattern singletons."**
Spring's singleton scope means one bean per ApplicationContext - not one bean
per JVM. In tests, each test context may have its own set of singletons.
If you have multiple ApplicationContexts (rare), you can have multiple instances
of the same bean class.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: State pollution across requests in a singleton bean**
Symptom: Request A's data appears in Request B's response. Data corruption.
Cause: Singleton bean stores request-specific state in an instance field.
Diagnosis: Thread dump showing shared field being written by multiple threads.
Fix: Move per-request state to local variables (method parameters), or use
a request-scoped bean (@Scope("request")).

**Failure 2: Prototype bean injected into singleton acts as singleton**
Symptom: New prototype instances are expected per use but the same instance
is always returned.
Cause: A singleton bean has a prototype bean injected in its constructor.
Since the singleton is created once, the prototype is also created once and
stored.
Fix: Use ApplicationContext.getBean() to fetch the prototype each time,
or use @Lookup method injection, or ObjectFactory<MyPrototypeBean>.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - What is a Spring bean?

A Spring bean is any Java object whose full lifecycle is managed by the Spring
IoC container. "Managed" means Spring creates it, injects its dependencies,
calls initialization callbacks, serves it during the application's runtime,
and calls destruction callbacks on shutdown.

Any class annotated with @Component (or @Service, @Repository, @Controller)
is auto-discovered by classpath scanning and registered as a bean. Classes
returned by @Bean methods in @Configuration classes are also registered.

*What separates good from great:* The key distinction is managed vs unmanaged.
Your domain objects (Order, Customer, Product) are typically created with `new`
and are NOT beans. Your infrastructure and service classes ARE beans. The rule
of thumb: if Spring should manage the lifecycle, make it a bean.

---

#### Q2 - What is the default bean scope and why?

The default scope is **singleton**: one instance per Spring ApplicationContext.
Every request for that bean type returns the same instance.

Why singleton is the default: services are typically stateless (they hold
no request-specific data, only collaborators). A stateless service is safe
to share across all threads. Creating a new service instance per request would
waste memory and add GC pressure without any benefit.

The contract: singleton beans MUST be thread-safe because they are shared.
This means no mutable instance fields that vary per request.

*What separates good from great:* Mention that Spring's singleton is per-
ApplicationContext, not per-JVM. In a test suite where each test creates its
own ApplicationContext (rare), you can have multiple "singleton" instances
of the same type across tests.

---

#### Q3 - How do you register a bean in Spring?

Three ways, in order of preference:

1. **@Component scanning** (most common for classes you own):
   - Annotate with @Component / @Service / @Repository / @Controller
   - Ensure the class is in a package covered by @ComponentScan
   (Spring Boot's @SpringBootApplication scans the main class package)

2. **@Bean method** (for programmatic control or third-party classes):
   - Declare in a @Configuration class
   - Method name becomes bean name; return type becomes bean type
   - Full control over construction arguments

3. **XML** (legacy - avoid in new code):
   - `<bean id="..." class="..."/>` in applicationContext.xml

The difference matters: @Component relies on reflection to instantiate; @Bean
gives you explicit control and is required for classes you cannot annotate
(e.g., HikariDataSource, JdbcTemplate).

*What separates good from great:* @Bean methods in @Configuration are proxied
by Spring - calling one @Bean method from another @Bean method does NOT create
a new instance; it returns the registered singleton. This is how Spring prevents
you from accidentally creating multiple DataSource instances.

---

#### Q4 - What happens to a bean on application shutdown?

On shutdown (when ApplicationContext.close() is called or the JVM receives
SIGTERM with a registered shutdown hook):

1. Spring publishes a ContextClosedEvent.
2. For each singleton bean (in reverse dependency order):
   a. Calls @PreDestroy method if present.
   b. Calls DisposableBean.destroy() if implemented.
   c. Calls custom destroy-method if specified in @Bean(destroyMethod).
3. Bean instances are removed from the singleton cache.

Spring Boot registers a shutdown hook automatically. @PreDestroy is the
cleanest way to release resources (close connections, cancel timers,
flush buffers).

*What separates good from great:* Prototype beans are NOT destroyed by
Spring. Since Spring does not track prototype instances after handing them
out, it cannot call @PreDestroy on them. You are responsible for destroying
prototype beans. This is a critical production gotcha for connection
management.

---

#### Q5 - What is @PostConstruct and when do you use it?

@PostConstruct marks a method to be called after dependency injection is
complete but before the bean is put into service. It runs after all @Autowired
dependencies have been injected.

Common use cases:
- Validate configuration (throw if required config is missing)
- Pre-load a cache (populate in-memory cache from database at startup)
- Establish connections (connect to external system and verify)
- Register the bean with an external system

```java
@Service
public class ProductCacheService {
    private final ProductRepository repository;
    private Map<Long, Product> cache;

    public ProductCacheService(
            ProductRepository repository) {
        this.repository = repository;
    }

    @PostConstruct
    public void initCache() {
        // Runs after repository is injected
        this.cache = repository.findAll().stream()
            .collect(toMap(Product::getId,
                           Function.identity()));
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* @PostConstruct runs inside the
singleton creation process, before the bean is exposed to other beans.
This means slow @PostConstruct methods delay startup. For background
warm-up tasks, use ApplicationReadyEvent or CommandLineRunner instead
so they run after the context is fully initialized.

---

#### Q6 - What is the difference between @Bean and @Component?

**@Component** (and @Service, @Repository, @Controller):
- Applied to the class itself
- Discovered via classpath scanning
- Spring calls the constructor using reflection
- Use when you own and can annotate the class

**@Bean**:
- Applied to a method in a @Configuration class
- Programmatic bean creation
- You write the creation code explicitly
- Use for: third-party classes, conditional creation, complex initialization,
  multiple beans of the same type with different configuration

Key difference: @Bean gives you full control over how the object is created.
@Component surrenders that control to Spring's reflection-based instantiation.

*What separates good from great:* @Configuration classes themselves are beans
(Spring subclasses them via CGLIB for proxy purposes). This is why @Bean
methods called from other @Bean methods return the singleton - the call goes
through the CGLIB proxy which intercepts it and returns the registered bean.

---

#### Q7 - What is a BeanDefinition?

A BeanDefinition is the metadata object that describes how to create a bean -
before any instance is actually created. It contains: the bean class name, scope,
constructor arguments, property values, init method name, destroy method name,
and whether it is lazy or eager.

Spring creates BeanDefinitions at startup (during context refresh, before
singleton instantiation). BeanFactoryPostProcessors can modify BeanDefinitions
at this stage - for example, replacing ${placeholder} values with actual
property values from application.properties.

Understanding BeanDefinitions explains why errors at startup happen in two
phases: BeanDefinition errors (duplicate bean names, invalid configuration)
happen before any object is created; bean instantiation errors happen during
the singleton creation phase.

*What separates good from great:* You can register BeanDefinitions
programmatically using `BeanDefinitionRegistryPostProcessor`. This is the
mechanism Spring Boot's auto-configuration uses: conditional logic decides
which BeanDefinitions to register, and then the normal instantiation process
creates the beans.

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# ApplicationContext

---
id: SPR-006
title: ApplicationContext
category: Spring
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: all
tags: #spring, #application-context, #ioc-container, #bean-factory
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High - understanding the ApplicationContext is the key
to understanding all Spring behaviour.

---

### 🎯 Model Answer

**30 seconds:**
> The ApplicationContext is Spring's IoC container - it holds all your beans,
> manages their lifecycle, and provides them to other beans and your application
> code. When a Spring Boot application starts, it creates an ApplicationContext,
> scans for beans, instantiates them in dependency order, and the app is ready.
> Understanding the ApplicationContext is understanding how Spring works.

**3 minutes (Senior):**
> The ApplicationContext is an extension of BeanFactory that adds enterprise
> features: AOP support, event publishing, internationalization, and annotation
> processing. It is the central hub of a Spring application.
>
> The context lifecycle has three phases. In the refresh phase, it reads all
> configuration (annotations, @Configuration classes, XML), creates
> BeanDefinitions, runs BeanFactoryPostProcessors (which can modify
> BeanDefinitions), instantiates all non-lazy singletons, and runs
> BeanPostProcessors (which create AOP proxies).
>
> After refresh, the context is live: getBean() returns singletons from the
> cache, new beans created programmatically are wired. On close, destruction
> callbacks fire in reverse dependency order.
>
> The non-obvious insight: the ApplicationContext itself is a bean in the
> context. You can inject it anywhere with @Autowired or by implementing
> ApplicationContextAware. This allows dynamic lookups, though it is usually
> a smell - prefer constructor injection.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers discuss parent-child ApplicationContext
hierarchies (how Spring MVC uses a child context for the servlet layer),
context caching in tests, and AOT compilation in Spring Boot 3+.

*Adapting down:* Junior - "The ApplicationContext is where Spring keeps all
your beans. When the app starts, Spring creates it and puts all your beans
inside it."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the ApplicationContext - Spring's
central container."

**(2) First principles:** "A DI container needs to hold all the managed
objects and provide them on request. The ApplicationContext is that holder."

**(3) Bridge:** "Think of the ApplicationContext as a very intelligent registry.
It doesn't just store objects - it knows how to create them, in what order,
and how to wire them together."

---

### 📘 Concept Explanation

**What it is:**
The ApplicationContext is Spring's central IoC container. It extends BeanFactory
with full enterprise features including: eager singleton instantiation, event
publishing, annotation processing, AOP auto-proxy creation, and internationalization
support.

**The problem it solves:**
Applications need a place to store and access managed objects. The ApplicationContext
is that place - it is the single source of truth for all Spring-managed beans,
their configuration, and their wiring. It removes the need for manual object
graph management.

**How it works:**

```
ApplicationContext lifecycle:
  1. CREATION
     new AnnotationConfigServletWebServerApplicationContext()
     (Spring Boot creates this automatically)

  2. REFRESH (spring.refresh() call)
     a) prepareContext - set environment, add listeners
     b) obtainFreshBeanFactory - create internal BeanFactory
     c) prepareBeanFactory - register default BPPs/BFPPs
     d) invokeBeanFactoryPostProcessors - run BFPPs
        (this is where @Configuration classes are processed,
         component scanning happens, @Value resolved)
     e) registerBeanPostProcessors - collect all BPPs
     f) initMessageSource, initApplicationEventMulticaster
     g) onRefresh - start embedded server (Boot apps)
     h) registerListeners
     i) finishBeanFactoryInitialization
        <- instantiates all non-lazy singletons
        <- calls @PostConstruct on each
     j) finishRefresh - publish ContextRefreshedEvent

  3. RUNNING
     getBean(type) -> returns from singleton cache

  4. CLOSE
     destroySingletons (reverse order)
     -> calls @PreDestroy
     -> publishes ContextClosedEvent
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**
The ApplicationContext refresh is the critical startup phase. Every non-lazy
singleton is created, wired, and initialized before the application accepts
traffic. Slow bean initialization slows startup - and errors in any bean
fail the entire startup. This fail-fast design ensures you never have a
half-configured application in production.

**When to use it:**
- Understanding is necessary for debugging startup failures
- Accessing the context programmatically for dynamic bean lookups
- Writing infrastructure code (custom BeanPostProcessors, listeners)

**When NOT to use it:**
- Injecting ApplicationContext into business beans to look up other beans
  is the Service Locator anti-pattern. Use constructor injection instead.

**Alternatives:**
- Spring TestContext Framework: caches ApplicationContext across tests
- Guice Injector: Google's equivalent; no lifecycle events
- Weld: CDI reference implementation; similar lifecycle model

**First-principles derivation:**
A DI container needs four capabilities: registration (add beans), retrieval
(get bean by type/name), lifecycle (init/destroy), and extension points
(modify beans after creation). ApplicationContext provides all four plus
enterprise extras (events, i18n). The design is layered: BeanFactory provides
1-2; ApplicationContext adds 3-4 and enterprise features.

---

### 💻 Code Example

```java
// How Spring Boot creates and starts the ApplicationContext
@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        // Creates ApplicationContext, refreshes it,
        // starts embedded Tomcat, accepts connections
        ConfigurableApplicationContext ctx =
            SpringApplication.run(Application.class, args);

        // The context is now fully initialized
        // All beans are created and wired
        OrderService orderService =
            ctx.getBean(OrderService.class);
    }
}
```

> **Code walkthrough:** SpringApplication.run() creates the right
> ApplicationContext subclass (web vs non-web), populates it from all
> @Configuration classes and @Component-scanned classes, refreshes it
> (which creates all singleton beans), then returns the live context.
> The context is ready to serve immediately after run() returns.

```java
// ApplicationContextAware (for infrastructure code only)
@Component
public class DynamicBeanLookup
        implements ApplicationContextAware {
    private ApplicationContext ctx;

    @Override
    public void setApplicationContext(
            ApplicationContext ctx) {
        this.ctx = ctx;
    }

    // Used when bean type is only known at runtime
    public <T> T getBean(Class<T> type) {
        return ctx.getBean(type);
    }
}

// Better: constructor injection (for business code)
@Service
public class OrderService {
    // Inject specific dependencies directly
    // Do NOT inject ApplicationContext here
    private final PaymentService paymentService;

    public OrderService(PaymentService ps) {
        this.paymentService = ps;
    }
}
```

> **Code walkthrough:** ApplicationContextAware is an interface for
> infrastructure code that needs dynamic runtime bean lookup. For business
> code, always use constructor injection - injecting the context itself is
> the service locator anti-pattern. The comparison shows the correct and
> incorrect usage of the context in application code.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> The ApplicationContext is Spring's container - it holds all your beans and
> makes them available to each other. When a Spring Boot app starts, it creates
> the ApplicationContext, scans for @Service and @Component classes, creates
> those objects, and wires them together. After that, beans are accessible via
> injection or by asking the context directly.

*Push deeper:* Explain the startup sequence: scan -> create beans -> inject
dependencies -> run @PostConstruct methods -> app is ready.

---

**Senior / Staff (5+ years):**
> The ApplicationContext refresh is where all the important startup work
> happens: classpath scanning, @Configuration processing, BFPP execution,
> singleton instantiation, BPP execution (which creates AOP proxies), and
> lifecycle callbacks. The refresh order explains many Spring behaviours:
> @Transactional works because the BPP runs after bean creation and wraps
> beans in proxy objects. @Value works because BFPP runs before instantiation
> and substitutes placeholder values in BeanDefinitions. Understanding the
> refresh phases lets you diagnose any startup problem systematically.

*Push deeper:* Parent-child ApplicationContext hierarchies: Spring MVC uses
a child context for the web layer (controllers) with a parent context for
services and data. Beans in the parent are visible to the child; beans in
the child are NOT visible to the parent. This was the classical Spring MVC
setup - Spring Boot collapsed this into a single context for simplicity.

---

### ⚠️ Common Misconceptions

**Misconception 1: "ApplicationContext and BeanFactory are interchangeable."**
BeanFactory is the minimal container interface - lazy bean creation, basic DI.
ApplicationContext extends BeanFactory and adds: eager singleton instantiation,
AOP auto-proxy creation, event publishing, annotation processing, and more.
In practice, always use ApplicationContext; BeanFactory is the interface you
program against in infrastructure code.

**Misconception 2: "The context is available immediately after new."**
The context is not usable until after refresh() is called. Spring Boot calls
refresh() inside SpringApplication.run(). Never use a context before it is
refreshed.

**Misconception 3: "Injecting ApplicationContext is the cleanest way to
get beans."**
Injecting ApplicationContext to look up other beans is the Service Locator
anti-pattern. It hides dependencies, makes testing harder, and couples your
code to the container. Use constructor injection for all business code.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: ContextRefreshFailedException at startup**
Symptom: Application fails to start with errors in context refresh.
Cause: Any error during singleton instantiation - missing bean, failed
@PostConstruct, circular dependency, connection failure.
Diagnosis: Read the full stack trace - Spring nests the root cause. The
innermost cause is the real problem.
Fix: Address the specific root cause (missing bean, configuration error, etc.)

**Failure 2: Using context before it is refreshed**
Symptom: NullPointerException or IllegalStateException when accessing beans
programmatically.
Cause: Context created but refresh not yet called (or refresh failed partially).
Fix: Only access the context after SpringApplication.run() returns.

**Failure 3: Context caching in tests creating shared state**
Symptom: Test A modifies a singleton bean; Test B sees that modification.
Cause: Spring TestContext Framework caches ApplicationContexts by config
key to avoid recreating them for every test. Shared singleton state leaks
between tests.
Fix: Use @DirtiesContext on tests that modify shared state (marks context
for recreation after the test), or design beans to be stateless.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - What is the ApplicationContext and how does it differ from BeanFactory?

ApplicationContext extends BeanFactory. BeanFactory provides the minimal
container: lazy bean creation and basic DI. ApplicationContext adds:
- Eager singleton instantiation at refresh time
- BeanPostProcessor auto-registration (for AOP proxies, annotation processing)
- ApplicationEvent publishing and listener registration
- MessageSource for internationalization
- ResourcePatternResolver for classpath scanning
- Environment and PropertySource abstraction

In practice, always work with ApplicationContext. BeanFactory is only used
in extremely resource-constrained environments where you need the bare minimum.

*What separates good from great:* Every web ApplicationContext
(AnnotationConfigServletWebServerApplicationContext) starts the embedded
server as part of the onRefresh() step during refresh. This is why
@SpringBootApplication can be run as a standalone jar.

---

#### Q2 - What happens during the ApplicationContext refresh?

The refresh is the most important phase of Spring startup. Key steps:

1. prepareBeanFactory: register default BPPs and processors
2. invokeBeanFactoryPostProcessors: run all BFPPs, which includes:
   - ConfigurationClassPostProcessor: processes all @Configuration classes,
     @ComponentScan, @Import, @Bean methods
   - PropertySourcesPlaceholderConfigurer: resolves @Value expressions
3. registerBeanPostProcessors: collect all BPPs (for later use)
4. finishBeanFactoryInitialization: instantiates all non-lazy singletons
   - For each: create, inject, call BPPs (pre-init), @PostConstruct,
     call BPPs (post-init where AOP proxies are created)
5. finishRefresh: publish ContextRefreshedEvent, start lifecycle beans

*What separates good from great:* The order explains Spring behaviours.
Component scanning happens in step 2 (BFPP phase), not at context creation.
AOP proxies are created in step 4's BPP post-init phase. Everything follows
from this order.

---

#### Q3 - What is the ContextRefreshedEvent and when is it fired?

ContextRefreshedEvent is published when the ApplicationContext refresh
is complete - all singletons are created, wired, and initialized, and the
context is ready to use.

Use case: tasks that must run after ALL beans are initialized but before
accepting external traffic.

```java
@Component
public class StartupValidator
        implements ApplicationListener<ContextRefreshedEvent> {
    @Override
    public void onApplicationEvent(
            ContextRefreshedEvent event) {
        // All beans are ready - validate invariants
        validateConfiguration();
    }
}
// Modern equivalent:
@Component
public class StartupValidator {
    @EventListener(ContextRefreshedEvent.class)
    public void validate() { validateConfiguration(); }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* In web applications, ContextRefreshedEvent
fires when the parent context refreshes AND again when the web (child) context
refreshes. Check event.getApplicationContext() to avoid double execution.
ApplicationReadyEvent (Spring Boot) fires only once after the full application
is ready including all lifecycle beans.

---

#### Q4 - What are the main ApplicationContext implementations?

Key implementations in order of use frequency:

1. **AnnotationConfigServletWebServerApplicationContext** (Spring Boot web):
   annotation-driven + embedded servlet server. Most common.

2. **AnnotationConfigApplicationContext**: annotation-driven, no web layer.
   Used for standalone apps, scheduled jobs, CLI tools.

3. **AnnotationConfigReactiveWebServerApplicationContext**
   (Spring Boot WebFlux): annotation-driven + embedded reactive server.

4. **ClassPathXmlApplicationContext**: XML configuration from classpath.
   Legacy - only in older projects.

5. **GenericApplicationContext** (Spring tests): programmatic context
   for unit-testing infrastructure code.

Spring Boot selects automatically based on classpath: spring-webmvc on
classpath -> servlet context; spring-webflux only -> reactive context;
neither -> non-web context.

*What separates good from great:* Mentioning how Spring Boot's auto-detection
works demonstrates understanding of the framework's internals vs just using
@SpringBootApplication as a magic annotation.

---

#### Q5 - How can you interact with the ApplicationContext programmatically?

Three legitimate use cases for programmatic context access:

1. **Dynamic bean lookup** (infrastructure code):
   `context.getBean(SomeService.class)` or `context.getBean("name", Class)`

2. **Publishing events**: `context.publishEvent(new MyEvent(this))`

3. **Registering beans dynamically** (rare):
   Cast to ConfigurableApplicationContext, get the BeanFactory,
   and register a BeanDefinition.

Accessing via injection:
- Implement ApplicationContextAware interface
- @Autowired ApplicationContext context (field or constructor)

When to use it: Only for infrastructure/framework code (custom starters,
plugin systems, test utilities). Business code should use constructor
injection exclusively.

*What separates good from great:* `context.getBeansOfType(Interface.class)`
returns a Map<String, Interface> of all beans implementing an interface.
Useful for plugin-style architectures where you want to discover all
registered implementations.

---

#### Q6 - How does Spring Boot's SpringApplication.run() work?

SpringApplication.run() is a factory that:
1. Deduces the ApplicationContext type from the classpath (web vs non-web).
2. Loads SpringApplicationRunListeners from spring.factories.
3. Creates the Environment and loads application.properties/yml.
4. Creates the ApplicationContext of the deduced type.
5. Calls context.refresh() which triggers the full startup lifecycle.
6. Calls all ApplicationRunner and CommandLineRunner beans.
7. Publishes ApplicationReadyEvent.
8. Returns the ready ApplicationContext.

The key: steps 5-7 happen synchronously before run() returns. When run()
returns, the application is fully started and ready to handle requests.

*What separates good from great:* spring-boot-autoconfigure's
spring.factories (or AutoConfiguration.imports in Boot 2.7+) is read in
step 5 during the BFPP phase. Each auto-configuration class is evaluated
for its @Conditional conditions - only matching ones create beans.

---

#### Q7 - What is context hierarchy and how is it used in Spring MVC?

A parent-child context hierarchy is two ApplicationContexts where the child
inherits beans from the parent but the parent cannot see the child's beans.

Classic Spring MVC setup (before Spring Boot):
- Root ApplicationContext (parent): services, repositories, data access
- Web ApplicationContext (child): controllers, view resolvers, MVC config

This separation allowed the web context to be reloaded without reloading
the service layer, and enforced separation of concerns.

Spring Boot collapses this into a single ApplicationContext for simplicity.
The hierarchy is only relevant when using Spring Boot with traditional WAR
deployment, or when building multi-module applications with explicit context
hierarchies.

*What separates good from great:* The hierarchy affects @Transactional - a
transactional annotation on a controller (in the child context) might not
see the transaction manager (in the parent context) depending on how BPPs
are configured. This was a classic Spring MVC gotcha that Boot's single
context eliminated.

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*



