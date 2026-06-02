---
layout: default
title: "Spring - L2 Bean Mechanics"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 4
permalink: /spring/l2-bean-mechanics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Spring - L2 Bean Mechanics](#spring---l2-bean-mechanics) | medium |
| 2 | [Bean Scopes](#bean-scopes) | medium |
| 3 | [Bean Lifecycle](#bean-lifecycle) | medium |

---

# Bean Scopes

---
id: SPR-010
title: Bean Scopes
category: Spring
difficulty: ★★☆
interview_weight: high
asked_at: All
seniority: mid
tags: #spring, #bean-scopes, #singleton, #prototype, #request-scope
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High - "What are the Spring bean scopes?" is asked in
mid-to-senior interviews to probe understanding of bean lifecycle and
thread-safety.

---

### 🎯 Model Answer

**30 seconds:**
> Spring has five main bean scopes. Singleton (default) creates one instance
> per ApplicationContext shared across all requests - must be stateless.
> Prototype creates a new instance every time the bean is requested. Request
> and Session create new instances per HTTP request or session - only valid
> in web applications. Application scope creates one instance per
> ServletContext. The key interview point is that singleton beans must be
> thread-safe because they are shared.

**3 minutes (Senior):**
> Singleton is the right choice for stateless services - one shared instance
> has zero per-request overhead. It is the default because most Spring beans
> (services, repositories) hold only collaborators in their fields, not
> request-specific state. The critical rule: never store mutable per-request
> state in singleton fields.
>
> Prototype is for stateful beans or objects that should not be shared: a
> command object, a stateful workflow object. Spring creates a new instance
> each time you request the bean. The trap: if you inject a prototype bean
> into a singleton, the prototype is only created once (at singleton creation
> time) and the singleton holds that one instance forever. Use ObjectFactory
> or @Lookup to get a fresh prototype each time.
>
> Request and Session scope are only meaningful in web applications. They use
> ThreadLocal under the hood (bound to the request/session) and are cleaned
> up automatically after the request/session ends. They are useful for storing
> the authenticated user's context.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff level - custom scopes are possible by implementing the
Scope interface. Spring Cloud's @RefreshScope is a custom scope that destroys
and recreates beans when configuration refreshes.

*Adapting down:* Junior - "Singleton means one shared instance. Prototype
means a new instance each time. Everything else is less common."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Spring bean scopes - how many instances
Spring creates and their lifetime."

**(2) First principles:** "Every container must decide: one shared instance or
many? For stateless services, one shared instance is efficient. For stateful
objects, a new instance per use is required."

**(3) Bridge:** "This is like connection pooling vs new connection. Singleton
is like a pooled connection shared by all threads. Prototype is like creating
a new connection for each transaction."

---

### 📘 Concept Explanation

**What it is:**
Bean scope defines how many instances Spring creates for a bean definition
and how long those instances live. Spring provides five built-in scopes plus
support for custom scopes.

**The problem it solves:**
Not all beans should be singletons. Stateful objects need fresh instances per
use. Request-specific data should be scoped to the request. Scopes give you
the right lifecycle semantics for each type of bean.

**How it works:**

```
Spring Bean Scopes:

SINGLETON (default)
  - 1 instance per ApplicationContext
  - Created at context refresh (eager)
  - Shared across ALL threads
  - Must be THREAD-SAFE
  - @Service, @Repository, @Controller are singletons

PROTOTYPE
  - New instance EVERY TIME requested (getBean or injected)
  - Spring does NOT track or destroy prototype instances
  - @PreDestroy NOT called - YOU manage lifecycle
  - Use for: stateful beans, non-thread-safe objects

REQUEST (web only)
  - 1 instance per HTTP request
  - Created on first access within the request
  - Destroyed when request ends
  - Thread-safe by nature (one request per thread)
  - Use for: request-specific context, form data

SESSION (web only)
  - 1 instance per HTTP session
  - Lives as long as the session
  - Destroyed when session invalidated or expires
  - Use for: shopping cart, user preferences

APPLICATION (web only)
  - 1 instance per ServletContext (shared across all sessions)
  - Similar to singleton but web-aware
  - Rarely used; prefer singleton

WEBSOCKET (web only)
  - 1 instance per WebSocket session
```

> **Code walkthrough:** This Bean Scopes example demonstrates a key concept in practice using Spring annotation. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The prototype-in-singleton problem is the most important scope gotcha.
A singleton bean injected with a prototype bean gets ONE prototype instance
(created at singleton startup) - not a new one each time. Use ObjectFactory,
ApplicationContext.getBean(), or @Lookup method injection to get a fresh
prototype on each call.

**When to use it:**
- Singleton: all stateless services, repositories, controllers (99% of beans)
- Prototype: stateful workflow objects, non-thread-safe helpers, parsers
- Request: authenticated user context, request-specific validators
- Session: shopping cart, multi-step wizard state

**When NOT to use it:**
- Do not use prototype for beans that are expensive to create frequently
- Do not use request/session scope outside web contexts

**Alternatives:**
- ThreadLocal: manually scope data to a thread (what Spring uses internally
  for request/session scopes)
- CDI @RequestScoped, @SessionScoped: Jakarta EE equivalent

**First-principles derivation:**
An instance has a scope defined by when it is created and when it is destroyed.
Singleton: created at context start, destroyed at context close. Prototype:
created on demand, destroyed by the caller. Request: created on request start,
destroyed at request end. The scope is just the lifecycle policy.

---

### 💻 Code Example

```java
// BAD: storing per-request state in singleton - BUG!
@Service  // singleton - one instance, all threads
public class OrderProcessor {
    // WRONG: currentUser is shared across all threads!
    private User currentUser;

    public void processOrder(Order order, User user) {
        this.currentUser = user; // Thread A sets this
        // Thread B might process a different user here
        // but currentUser is still Thread A's user
        validate(order); // uses currentUser - WRONG
    }
}
```

> **Code walkthrough:** This is the most dangerous Spring singleton bug.
> currentUser is an instance field on a singleton bean. Thread A sets
> currentUser to User Alice. Before Thread A calls validate(), Thread B
> sets currentUser to User Bob. Thread A's validate() now sees Bob's data.
> This is a race condition that only manifests under concurrent load.

```java
// GOOD: stateless singleton - no mutable instance fields
@Service  // singleton - thread-safe by design
public class OrderProcessor {
    private final OrderRepository repository;
    private final PaymentService payment;

    // Only collaborators in instance fields - never data
    public OrderProcessor(OrderRepository repository,
                          PaymentService payment) {
        this.repository = repository;
        this.payment = payment;
    }

    public void processOrder(Order order, User user) {
        // user is a method parameter - thread-local
        validateOrder(order, user); // safe
        repository.save(order);     // safe
        payment.charge(order, user);// safe
    }
}

// Request-scoped bean for per-request data
@Component
@Scope(value = WebApplicationContext.SCOPE_REQUEST,
       proxyMode = ScopedProxyMode.TARGET_CLASS)
public class RequestContext {
    private User currentUser;
    private String correlationId;
    // Getters and setters
}

// Singleton service uses request-scoped bean
@Service
public class SecurityService {
    private final RequestContext requestCtx;

    // Spring injects a PROXY here, not the real bean
    // The proxy delegates to the request-scoped instance
    public SecurityService(RequestContext requestCtx) {
        this.requestCtx = requestCtx;
    }

    public boolean isAuthorized(String action) {
        // Gets the current request's instance
        User user = requestCtx.getCurrentUser();
        return user.hasPermission(action);
    }
}
```

> **Code walkthrough:** The request-scoped bean stores per-request stateice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> safely. The key is proxyMode = TARGET_CLASS - Spring injects a CGLIB proxy
> into the singleton SecurityService. When the singleton calls requestCtx
> methods, the proxy looks up the actual RequestContext for the CURRENT request
> (stored in a ThreadLocal by Spring's RequestContextHolder) and delegates.
> Without proxyMode, injecting a request-scoped bean into a singleton would
> fail at startup.

```java
// Prototype scope: fresh instance each time
@Component
@Scope("prototype")
public class CsvParser {
    private final List<String> errors = new ArrayList<>();
    // Mutable state - safe because each use gets fresh instance

    public ParseResult parse(String csv) {
        // ...
        return new ParseResult(rows, errors);
    }
}

// Singleton using prototype - WRONG (gets same instance)
@Service
public class ImportService {
    @Autowired
    private CsvParser csvParser; // WRONG: same parser always

    public void importFile(String csv) {
        // csvParser is the SAME instance injected at startup
        csvParser.parse(csv); // errors from previous calls accumulate!
    }
}

// CORRECT: use ObjectFactory to get fresh prototype each time
@Service
public class ImportServiceCorrect {
    private final ObjectFactory<CsvParser> parserFactory;

    public ImportServiceCorrect(
            ObjectFactory<CsvParser> parserFactory) {
        this.parserFactory = parserFactory;
    }

    public void importFile(String csv) {
        CsvParser parser = parserFactory.getObject(); // fresh instance
        parser.parse(csv);
        // parser goes out of scope - garbage collected
    }
}
```

> **Code walkthrough:** The prototype-in-singleton trap is illustrated andice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> fixed. The broken ImportService gets ONE CsvParser instance injected at
> startup. Since CsvParser maintains a mutable errors list, errors from
> previous imports accumulate. The fix uses ObjectFactory<CsvParser> which
> Spring auto-creates - calling getObject() creates a fresh prototype instance.
> This is the standard pattern for prototype beans inside singletons.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring has five scopes. Singleton (default) creates one shared instance -
> good for stateless services but you must not store per-request data in fields.
> Prototype creates a new instance every time. Request and Session scopes create
> new instances per HTTP request or session, scoped to the web layer. The most
> important rule is that singleton beans must be thread-safe.

*Push deeper:* Explain that singleton beans storing mutable state in instance
fields cause race conditions under concurrent load.

---

**Senior / Staff (5+ years):**
> Scope defines instance cardinality and lifetime. Singleton is the right
> default for stateless services - one shared instance, zero per-request
> overhead. The prototype-in-singleton problem is the critical gotcha: injecting
> a prototype into a singleton causes the prototype to act as a singleton (created
> once at startup, never refreshed). The solution is ObjectFactory<T> or @Lookup
> method injection to get a fresh prototype on demand. Request scope uses
> Spring's RequestContextHolder (ThreadLocal) under the hood. The ScopedProxy
> wrapping mechanism allows request/session scoped beans to be injected into
> singletons without startup errors.

*Push deeper:* Spring Cloud's @RefreshScope is a custom scope implementation
that destroys and recreates beans when the configuration changes (via
/actuator/refresh). Understanding that custom scopes are possible by implementing
the Scope interface explains how this works.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Prototype beans are destroyed by Spring."**
Spring does NOT call @PreDestroy or track prototype beans after creation.
Once Spring hands out a prototype instance, it has no further interest in it.
The caller is responsible for lifecycle management. This is documented but
often missed.

**Misconception 2: "Request scope is only for controllers."**
Request-scoped beans can be injected into any bean (services, repositories)
as long as a web request is active. The proxy mechanism handles the thread-
local lookup transparently.

**Misconception 3: "Singleton scope is like the Singleton design pattern."**
Spring singleton scope means one instance per ApplicationContext - not per JVM.
Multiple ApplicationContexts (in tests, in some Spring MVC setups) can have
multiple instances of the same singleton-scoped bean.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Race condition in singleton with mutable state**
Symptom: Intermittent data corruption or wrong results under concurrent load.
Cause: Singleton bean stores request-specific data in an instance field.
Diagnosis: Thread dump showing multiple threads in the same bean method;
instance field contains data from a different request.
Fix: Move per-request state to method parameters, ThreadLocal, or request-
scoped beans.

**Failure 2: Prototype bean stale in singleton**
Symptom: Prototype bean state accumulates across multiple calls; expected
fresh instance not created.
Cause: Prototype bean injected directly into singleton via field/constructor.
Fix: Use ObjectFactory<PrototypeBean> and call getObject() on each use.

**Failure 3: ScopeNotActiveException in tests**
Symptom: "No Scope registered for scope name 'request'" in unit tests.
Cause: Request-scoped bean accessed outside a web request context.
Fix: Add @WebMvcTest or use MockHttpServletRequest with
RequestContextHolder.setRequestAttributes() to simulate a request in tests.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What are the Spring bean scopes?**

Five built-in scopes:
1. **Singleton** (default): one instance per ApplicationContext. Shared
   across all threads. Must be stateless/thread-safe.
2. **Prototype**: new instance for each call to getBean() or each injection
   point. Spring does not manage lifecycle after handoff.
3. **Request** (web): one instance per HTTP request. Destroyed when request
   ends. Uses RequestContextHolder (ThreadLocal) internally.
4. **Session** (web): one instance per HTTP session. Lives until session
   expires or is invalidated.
5. **Application** (web): one instance per ServletContext. Like singleton
   but web-aware.

Plus WebSocket scope for WebSocket sessions.

*What separates good from great:* Custom scopes via the Scope interface.
Spring Cloud @RefreshScope is the most well-known example: a custom scope
that destroys and recreates beans on config refresh.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What is the difference between singleton and prototype scope?**

Singleton:
- One instance per ApplicationContext
- Created eagerly at context refresh
- Returned from singleton cache on every getBean() call
- Thread-safe requirement: mandatory
- @PreDestroy called on context close

Prototype:
- New instance on every getBean() call or injection
- Created lazily (only when requested)
- Spring does NOT cache or destroy prototype instances
- Thread-safe requirement: none (each caller has its own)
- @PreDestroy NOT called (Spring does not track prototypes)

Decision: if the bean holds state that varies per use, prototype. If it holds
only collaborators, singleton.

*What separates good from great:* The @PreDestroy caveat for prototypes is
often forgotten. If prototype beans hold resources (connections, file handles),
you MUST close them yourself. Spring will not do it.

---

**[JUNIOR] Q3 - [CONCEPTUAL] How do you inject a prototype bean into a singleton?**

The naive approach (direct injection) gives you one prototype instance,
created at singleton startup - defeating the purpose of prototype scope.

Three correct approaches:

1. **ObjectFactory<T>** (cleanest):
   ```java
   @Autowired ObjectFactory<MyPrototype> factory;
   // In method: factory.getObject() returns fresh instance
   ```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

2. **@Lookup method injection**:
   ```java
   @Service public abstract class MyService {
       public void process() {
           MyPrototype p = createPrototype();
       }
       @Lookup public abstract MyPrototype createPrototype();
   }
   ```
> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

   Spring generates a CGLIB subclass implementing createPrototype()
   as a getBean() call.

3. **ApplicationContext.getBean()**:
   Direct context access; Service Locator anti-pattern but explicit.

*What separates good from great:* @Lookup is the most elegant for cases where
you need the fresh prototype frequently. ObjectFactory is preferred when you
want to be explicit about getting a new instance at the call site.

---

**[MID] Q4 - [CONCEPTUAL] How does proxyMode work for request and session scoped beans?**

When you declare a request-scoped bean, Spring needs to inject it into singleton
beans. The problem: the singleton is created at startup, but request-scoped
beans don't exist yet (no request at startup).

Solution: Spring injects a PROXY (CGLIB subclass or JDK proxy) that looks up
the real scoped instance on each method call. The proxy delegates to the current
request's real instance via RequestContextHolder (ThreadLocal).

```java
@Component
@Scope(
  value = WebApplicationContext.SCOPE_REQUEST,
  proxyMode = ScopedProxyMode.TARGET_CLASS
)
public class RequestContext { ... }
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

ScopedProxyMode.TARGET_CLASS: CGLIB proxy for concrete classes.
ScopedProxyMode.INTERFACES: JDK proxy for interfaces.

Without proxyMode: injecting a request-scoped bean into a singleton throws
BeanCreationException at startup.

*What separates good from great:* The proxy mechanism is the same mechanism
Spring uses for @Transactional and @Async - the proxy intercepts calls and
adds behaviour. Understanding that proxies are the universal Spring extension
mechanism explains many Spring behaviours.

---

**[MID] Q5 - [CONCEPTUAL] What is the @RefreshScope in Spring Cloud?**

@RefreshScope is a custom Spring scope that allows beans to be refreshed
(destroyed and recreated) when configuration changes.

When /actuator/refresh is called:
1. The refresh scope cache is cleared.
2. Next time a @RefreshScope bean is accessed, Spring creates a new instance.
3. The new instance picks up the latest configuration values.

This is how Spring Cloud Config Server works: change a value in the config
repository, call /actuator/refresh, and beans get the new values without
restarting the application.

Implementation: RefreshScope implements the Scope interface. It maintains a
cache of instances keyed by bean name. On refresh, it clears the cache.
The ScopedProxy mechanism ensures that singleton beans holding references
to refresh-scoped beans always go through the proxy, which checks the cache.

*What separates good from great:* @RefreshScope only refreshes the specific
bean - it does not restart the entire context. Beans that receive their
configuration via @Value need @RefreshScope to pick up new values. Beans
using Environment.getProperty() always get fresh values without @RefreshScope.

---

**[MID] Q6 - [CONCEPTUAL] What is the Application scope and when would you use it?**

Application scope creates one bean instance per ServletContext. In a standard
Spring Boot application with one embedded server, application scope is
functionally identical to singleton scope.

Application scope is meaningful when:
- Multiple Spring ApplicationContexts share the same ServletContext (rare)
- You need a bean visible to both Spring and the raw servlet context
  (via servlet context attributes)

In practice, application scope is rarely used. Singleton suffices for all
application-wide shared state. Application scope's main use case is legacy
integration with servlet-level code that accesses beans via
servletContext.getAttribute().

*What separates good from great:* Application scope beans are stored as
ServletContext attributes, not in Spring's singleton cache. This means they
can be accessed by non-Spring code via ServletContext, which singleton beans
cannot. For greenfield Spring Boot applications, this distinction does not matter.

---

**[SENIOR] Q7 - [CONCEPTUAL] How do you declare a custom scope?**

```java
// 1. Implement the Scope interface
public class TenantScope implements Scope {
    // Map of tenant ID -> bean instances
    private Map<String, Map<String, Object>> tenantBeans
        = new ConcurrentHashMap<>();

    @Override
    public Object get(String name,
                      ObjectFactory<?> factory) {
        String tenantId = TenantContext.currentTenantId();
        return tenantBeans
            .computeIfAbsent(tenantId, k -> new HashMap<>())
            .computeIfAbsent(name, k -> factory.getObject());
    }

    @Override
    public Object remove(String name) { /* ... */ }
    // ... other interface methods
}

// 2. Register the custom scope
@Configuration
public class TenantScopeConfig {
    @Bean
    public static CustomScopeConfigurer scopeConfigurer() {
        CustomScopeConfigurer configurer =
            new CustomScopeConfigurer();
        configurer.addScope("tenant", new TenantScope());
        return configurer;
    }
}

// 3. Use the custom scope
@Component
@Scope(value = "tenant",
       proxyMode = ScopedProxyMode.TARGET_CLASS)
public class TenantConfig { ... }
```

> **Code walkthrough:** This Unknown example demonstrates contract definition using Spring annotation. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **TAKEAWAY: interfaces define contracts; prefer them over abstract classes for unrelated types.**

*What separates good from great:* Custom scopes unlock powerful patterns:
per-tenant isolation, per-job state in batch processing, per-WebSocket session
state. Spring Cloud's @RefreshScope and @RequestScope are both implemented
as custom scopes. The Scope interface is small (4 methods) and straightforward
to implement.

---

**[SENIOR] Q8 - [CONCEPTUAL] What happens when a singleton bean depends on a wider-scoped bean**
       (request/session)?

Without proxyMode on the narrower-scoped bean: Spring throws BeanCreationException
at startup because it tries to inject a non-existent request-scoped bean into
a singleton during context refresh (before any request exists).

With proxyMode: Spring injects a CGLIB/JDK proxy into the singleton. The proxy
is created at startup time. On each method call to the proxy, it:
1. Gets the current scope identifier (request ID, session ID)
2. Looks up the real scoped instance in the scope's storage
3. Delegates the method call to that instance

This allows singletons to "use" narrower-scoped beans transparently.

*What separates good from great:* The opposite case (wide scope in narrow scope)
is not a problem - a singleton injected into a request-scoped bean works fine
because the singleton is always available. The problem is only narrow->wide
dependency direction.

---

**[SENIOR] Q9 - [CONCEPTUAL] How do you test beans with non-singleton scopes?**

For request-scoped beans in tests:

1. **@WebMvcTest**: creates a web test context with request scope active.

2. **MockHttpServletRequest**: manually create a request context:
   ```java
   @BeforeEach
   void setUp() {
       MockHttpServletRequest request
           = new MockHttpServletRequest();
       RequestContextHolder.setRequestAttributes(
           new ServletRequestAttributes(request));
   }
   @AfterEach
   void tearDown() {
       RequestContextHolder.resetRequestAttributes();
   }
   ```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

3. **@SpringBootTest(webEnvironment=MOCK)**: creates a mock web environment
   with request scope support.

For prototype beans: just use `new` or ApplicationContext.getBean() - no
special setup needed.

*What separates good from great:* @Scope("request") beans in unit tests are
often replaced with mocks rather than activating request scope. If the bean
under test depends on a request-scoped bean, mock the request-scoped bean
with @MockBean or provide it via constructor injection - the test does not
need a full web context.

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


# Bean Lifecycle

---
id: SPR-011
title: Bean Lifecycle
category: Spring
difficulty: ★★☆
interview_weight: high
asked_at: All
seniority: mid
tags: #spring, #bean-lifecycle, #postconstruct, #predestroy, #init
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High - bean lifecycle questions appear regularly at
mid-to-senior level to probe understanding of Spring initialization order.

---

### 🎯 Model Answer

**30 seconds:**
> The Spring bean lifecycle goes through these phases: instantiation (constructor
> called), dependency injection (@Autowired fields set), then BeanPostProcessors
> run (pre-initialization), then @PostConstruct runs (your custom init code),
> then BeanPostProcessors run again (post-initialization where AOP proxies are
> created), then the bean is ready for use. On shutdown, @PreDestroy runs before
> the bean is removed. The key insight is that AOP proxies are created AFTER
> your initialization code, which explains many Spring behaviours.

**3 minutes (Senior):**
> The lifecycle matters because it determines what you can and cannot do at
> each phase. @PostConstruct is safe to use because all dependencies are
> injected before it runs. It is the right place to pre-load caches, validate
> configuration, or establish connections.
>
> The critical insight is step order: BeanPostProcessors run before @PostConstruct
> (pre-init phase) and after @PostConstruct (post-init phase). The post-init
> phase is where @Transactional and @Async proxies are created. This is why
> @Transactional does not work when called from a constructor or @PostConstruct
> method - the proxy has not been created yet.
>
> For shutdown, @PreDestroy is the right place to release resources: close
> connections, cancel scheduled tasks, flush buffers. Spring calls it in
> reverse dependency order (leaf beans first). Note that prototype bean
> @PreDestroy methods are NEVER called - Spring does not track prototype
> instances.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff engineers discuss BeanPostProcessor and BeanFactoryPostProcessor
and how to use them for custom framework extensions.

*Adapting down:* Junior - "When your bean is created, Spring first sets up all
dependencies, then calls @PostConstruct for any setup code you wrote. When the
app shuts down, Spring calls @PreDestroy for any cleanup code."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the Spring bean lifecycle - what happens
from bean creation to destruction."

**(2) First principles:** "Any managed object needs creation, setup, use, and
teardown. The bean lifecycle is Spring's protocol for each phase."

**(3) Bridge:** "Think of it like employee onboarding: hired (instantiated),
trained (dependencies injected), orientation (PostConstruct), work (usage),
exit interview (PreDestroy), departure (destruction)."

---

### 📘 Concept Explanation

**What it is:**
The bean lifecycle is the sequence of events from when Spring creates a bean to
when it destroys it. Understanding this sequence is essential for writing correct
initialization and cleanup code.

**The problem it solves:**
Applications often need custom initialization (pre-load caches, validate config,
connect to external systems) and cleanup (close connections, flush buffers) tied
to the bean's lifecycle. The lifecycle callbacks provide well-defined hooks for
this without requiring you to extend framework classes.

**How it works:**

```
Bean Lifecycle (singleton bean, full sequence):

  1. INSTANTIATION
     Spring calls constructor (or @Bean factory method)
     Object exists but fields are null

  2. DEPENDENCY INJECTION
     Spring sets @Autowired fields/methods
     All declared dependencies are now available

  3. AWARE CALLBACKS (if implemented)
     BeanNameAware.setBeanName(name)
     ApplicationContextAware.setApplicationContext(ctx)

  4. BeanPostProcessor PRE-INIT
     All BPP.postProcessBeforeInitialization() called
     This is where @Validated, @Async setup happens

  5. INIT CALLBACKS (in this order)
     a) @PostConstruct method
     b) InitializingBean.afterPropertiesSet()
     c) @Bean(initMethod = "init") custom method

  6. BeanPostProcessor POST-INIT   <- KEY PHASE
     All BPP.postProcessAfterInitialization() called
     THIS IS WHERE AOP PROXIES ARE CREATED
     (@Transactional, @Async, @Cacheable proxies here)
     The bean registered in context may be the PROXY,
     not your original object

  7. BEAN READY FOR USE
     Stored in singleton cache
     Returned on every getBean() call

  On ApplicationContext.close():
  8. DESTROY CALLBACKS (reverse dependency order)
     a) @PreDestroy method
     b) DisposableBean.destroy()
     c) @Bean(destroyMethod = "cleanup") custom method
```

> **Code walkthrough:** This Bean Lifecycle example demonstrates a key concept in practice using @Transactional. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
Step 6 is the critical insight. AOP proxies wrap your bean AFTER initialization.
This means: @Transactional does NOT protect code in @PostConstruct (the proxy
is not created yet). It also means: the object in the context may not be your
class but a CGLIB subclass proxy. When you inject OrderService, you receive
the proxy, not the actual OrderService instance.

**When to use it:**
- @PostConstruct: pre-load caches, validate required configuration, warm up
  connections, register listeners
- @PreDestroy: close connections, cancel timers, flush pending writes, unregister

**When NOT to use it:**
- @PostConstruct for long-running tasks: it blocks startup. Use
  ApplicationReadyEvent or CommandLineRunner for async warm-up.
- @PostConstruct for @Transactional operations: the proxy is not yet created.
  Use ApplicationReadyEvent listener instead.

**Alternatives:**
- ApplicationReadyEvent: fires after full context refresh; all proxies in place;
  safe for @Transactional calls
- CommandLineRunner / ApplicationRunner: runs after full application startup

**First-principles derivation:**
Managed objects need initialization after construction but before use. Java
constructors cannot call interface methods on injected fields (fields are not
set yet). Therefore, a post-construction callback called after injection is
necessary. Spring's @PostConstruct fills this gap cleanly without requiring
framework inheritance.

---

### 💻 Code Example

```java
// BAD: initialization in constructor - dependencies not injected yet
@Service
public class CacheService {
    @Autowired
    private ProductRepository repository;

    public CacheService() {
        // WRONG: repository is null here!
        // @Autowired hasn't run yet
        this.cache = loadCache(repository);
    }
}
```

> **Code walkthrough:** The constructor runs before @Autowired injection.
> At constructor time, repository is still null (field injection has not run).
> This causes NullPointerException. The fix is @PostConstruct - it runs AFTER
> all dependencies are injected.

```java
// GOOD: use @PostConstruct for post-injection setup
@Service
public class CacheService {
    private final ProductRepository repository;
    private Map<Long, Product> cache;

    // Constructor injection - repository always set here
    public CacheService(ProductRepository repository) {
        this.repository = repository;
    }

    @PostConstruct
    public void initCache() {
        // All dependencies injected - safe to use
        log.info("Loading product cache...");
        this.cache = repository.findAll()
            .stream()
            .collect(toMap(Product::getId,
                           Function.identity()));
        log.info("Cache loaded: {} products",
                 cache.size());
    }

    @PreDestroy
    public void evictCache() {
        log.info("Clearing product cache");
        if (cache != null) cache.clear();
    }

    public Optional<Product> findById(Long id) {
        return Optional.ofNullable(cache.get(id));
    }
}
```

> **Code walkthrough:** @PostConstruct runs after all dependencies are injected.
> The repository is available and the cache is loaded before the bean enters
> service. @PreDestroy clears the cache on shutdown. Note that this is
> synchronous - a very large cache load would delay startup. For large warm-up
> tasks, use ApplicationReadyEvent instead.

```java
// Lifecycle order demonstration
@Component
public class LifecycleDemo
        implements BeanNameAware, InitializingBean,
                   DisposableBean {
    private String beanName;
    private final SomeService someService;

    public LifecycleDemo(SomeService someService) {
        this.someService = someService;
        log.info("1. Constructor called");
    }

    @Override
    public void setBeanName(String name) {
        this.beanName = name;
        log.info("3. BeanNameAware: name={}", name);
    }

    @PostConstruct
    public void postConstruct() {
        log.info("5. @PostConstruct - deps injected");
    }

    @Override
    public void afterPropertiesSet() {
        log.info("6. InitializingBean.afterPropertiesSet");
    }

    @PreDestroy
    public void preDestroy() {
        log.info("7. @PreDestroy");
    }

    @Override
    public void destroy() {
        log.info("8. DisposableBean.destroy");
    }
}
// Output order:
// 1. Constructor called
// 2. (Spring injects dependencies)
// 3. BeanNameAware: name=lifecycleDemo
// 4. (BPP pre-init runs)
// 5. @PostConstruct - deps injected
// 6. InitializingBean.afterPropertiesSet
// 7. (BPP post-init runs - proxy created here)
// --- bean in service ---
// 8. (context.close() called)
// 7. @PreDestroy
// 8. DisposableBean.destroy
```

> **Code walkthrough:** This demonstrates all callback types in order. Inice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> practice, you should only use @PostConstruct and @PreDestroy (standard
> annotations). InitializingBean and DisposableBean are Spring-specific
> interfaces that increase coupling. BeanNameAware is only for infrastructure
> code. The practical lesson: use @PostConstruct for setup, @PreDestroy for
> teardown, and nothing else.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring beans go through: constructor (created), dependency injection (Spring
> fills in @Autowired fields), @PostConstruct (your setup code runs after
> dependencies are ready), then the bean is used. On shutdown, @PreDestroy
> runs before the bean is removed. Key rule: put setup code in @PostConstruct,
> not in the constructor, because dependencies are not available in the
> constructor.

*Push deeper:* Explain why you cannot call @Transactional methods from
@PostConstruct - the transaction proxy is created after @PostConstruct runs.

---

**Senior / Staff (5+ years):**
> The lifecycle's critical phase is BeanPostProcessor post-initialization (step
> 6). This is where AOP proxies for @Transactional, @Async, and @Cacheable are
> created. Any initialization code that needs transaction support must run after
> this phase - use ApplicationReadyEvent listener or CommandLineRunner. Code in
> @PostConstruct or @Bean initMethod runs BEFORE proxies are created, so
> transactional methods called from there execute without a transaction.
> Understanding this ordering explains why @Transactional methods must be called
> through the injected proxy (from outside the bean), never directly from within.

*Push deeper:* BeanFactoryPostProcessors modify BeanDefinitions before any
bean is instantiated. BeanPostProcessors process bean INSTANCES after
instantiation. The order: BFPPs run first (can modify definitions), then
singletons are created with BPPs applied to each. Writing a custom BPP
(e.g., to scan for a custom annotation) requires implementing
BeanPostProcessor and registering it as a bean - Spring discovers it early
in the refresh cycle.

---

### ⚠️ Common Misconceptions

**Misconception 1: "@PostConstruct methods can use @Transactional."**
@Transactional works by wrapping the bean in a proxy that intercepts method
calls and manages transactions. The proxy is created in the BPP post-init
phase, which runs AFTER @PostConstruct. Calling a @Transactional method from
@PostConstruct calls it on the raw object, bypassing the proxy - no transaction
is started.

**Misconception 2: "InitializingBean.afterPropertiesSet() and @PostConstruct
are the same."**
Both run at the same lifecycle phase (after dependency injection). The order
is: @PostConstruct first, then afterPropertiesSet(). @PostConstruct is preferred
because it is a standard Java annotation (not Spring-specific). afterPropertiesSet
is legacy.

**Misconception 3: "@PreDestroy is called for all beans."**
@PreDestroy is NOT called for prototype-scoped beans. Spring does not track
prototype instances after handing them out. Only singleton-scoped beans receive
@PreDestroy callbacks.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: @Transactional not working in @PostConstruct**
Symptom: Database operations in @PostConstruct run without a transaction;
no rollback on exception.
Cause: @Transactional proxy is created AFTER @PostConstruct runs.
Fix: Move the transactional initialization code to an ApplicationReadyEvent
listener:
```java
@EventListener(ApplicationReadyEvent.class)
@Transactional
public void initWithTransaction() { ... }
```

> **Code walkthrough:** This Unknown example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

**Failure 2: @PostConstruct blocking startup**
Symptom: Application startup takes very long; @PostConstruct is loading large
datasets.
Cause: @PostConstruct runs synchronously during context refresh.
Fix: Use ApplicationReadyEvent with async execution for non-critical warm-up:
```java
@EventListener(ApplicationReadyEvent.class)
@Async
public void warmUpCache() { ... } // Runs in a thread pool
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**Failure 3: @PreDestroy not called for prototype beans**
Symptom: Resources (connections, file handles) not released for prototype beans.
Cause: Spring does not track prototype beans after creation.
Fix: Implement Closeable and close the prototype explicitly, or use
try-with-resources, or use DisposableBeanAdapter and manage it explicitly.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What is the full Spring bean lifecycle?**

Complete sequence for a singleton bean:
1. Constructor (object created, fields null)
2. Dependency injection (all @Autowired satisfied)
3. Aware callbacks (BeanNameAware, ApplicationContextAware if implemented)
4. BeanPostProcessor.postProcessBeforeInitialization() for all registered BPPs
5. @PostConstruct method
6. InitializingBean.afterPropertiesSet() (if implemented)
7. Custom initMethod (if @Bean(initMethod="...") specified)
8. BeanPostProcessor.postProcessAfterInitialization() <- AOP proxies created here
9. Bean ready; stored in singleton cache

On shutdown:
10. @PreDestroy method
11. DisposableBean.destroy() (if implemented)
12. Custom destroyMethod

*What separates good from great:* The reason step 8 is critical: after this
step, the bean reference in the context may be a proxy (not your original
object). When other beans inject this bean, they receive the proxy.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What is the difference between @PostConstruct and @Bean(initMethod)?**

Both run after dependency injection. The difference:

@PostConstruct:
- Annotation on a method inside the bean class
- Standard JSR-250 annotation (not Spring-specific)
- Works for any Spring-managed bean (component-scanned or @Bean)
- Cannot be used for third-party classes you cannot annotate

@Bean(initMethod = "initMethodName"):
- Specified on the @Bean factory method in @Configuration
- Required for third-party classes that have init methods but are not
  Spring-annotated
- The method can have any name matching the bean's actual method

Example: `@Bean(initMethod = "start", destroyMethod = "stop")` for
a HazelcastInstance which has start/stop lifecycle methods.

*What separates good from great:* For classes you own, prefer @PostConstruct.
For third-party classes, use @Bean initMethod. Never implement InitializingBean
in new code - it's Spring-specific and @PostConstruct achieves the same result.

---

**[JUNIOR] Q3 - [CONCEPTUAL] Why does @Transactional not work in @PostConstruct?**

The AOP proxy that implements @Transactional is created in BeanPostProcessor
post-initialization (step 8 in lifecycle). @PostConstruct runs at step 5 -
BEFORE the proxy exists.

When @PostConstruct calls a @Transactional method on `this`, it calls the
real object directly, not through the proxy. No transaction is started.
If the @Transactional method fails, no rollback occurs.

Solution: Use ApplicationReadyEvent listener for transactional initialization:
```java
@EventListener(ApplicationReadyEvent.class)
@Transactional
public void transactionalInit() {
    // Called via proxy - transaction works correctly
}
```

> **Code walkthrough:** This Unknown example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

ApplicationReadyEvent fires after full context refresh including proxy creation.

*What separates good from great:* This is the same root cause as the self-
invocation problem: calling this.transactionalMethod() bypasses the proxy.
Whether from @PostConstruct or from another method in the same class, the
result is the same: the proxy is bypassed.

---

**[MID] Q4 - [HANDS-ON] What is a BeanPostProcessor and when would you write one?**

A BeanPostProcessor is a Spring extension point that processes every bean
instance before and after initialization. It receives every bean in the context
and can:
- Return the original bean (no-op)
- Return a different object (the proxy mechanism works this way)
- Throw an exception to veto bean creation

Two methods:
- postProcessBeforeInitialization(bean, beanName): called before @PostConstruct
- postProcessAfterInitialization(bean, beanName): called after @PostConstruct

AbstractAutoProxyCreator (which creates @Transactional proxies) is a BPP. All
Spring AOP works through BPPs.

When to write a custom BPP: custom annotation processing (scan all beans for
a custom annotation and apply behaviour), bean validation, custom metric
registration, custom lifecycle tracking.

*What separates good from great:* BPPs must be registered as beans themselves.
Spring detects them early in the refresh cycle (before other beans are created)
so they are available to process all beans. Creating a BPP that depends on
another bean can cause issues because Spring must create the BPP before the
dependency is available.

---

**[MID] Q5 - [CONCEPTUAL] What is the BeanFactoryPostProcessor and how is it different from BeanPostProcessor?**

BeanFactoryPostProcessor (BFPP) operates on BeanDefinitions BEFORE any bean
instance is created. BeanPostProcessor (BPP) operates on bean INSTANCES during
their lifecycle.

BFPP lifecycle:
- All BFPPs run during context refresh before singleton instantiation
- Can modify, add, or remove BeanDefinitions
- Cannot create regular beans (no DI available yet)

BPP lifecycle:
- Runs during bean instantiation, once per bean
- Can wrap beans in proxies or validate them
- Has access to the fully-initialized container

Key BFPP implementations: ConfigurationClassPostProcessor (processes
@Configuration, @ComponentScan, @Import), PropertySourcesPlaceholderConfigurer
(resolves ${...} in BeanDefinitions).

*What separates good from great:* Both are beans discovered early. The
critical difference is timing: BFPP modifies the recipe (BeanDefinitions);
BPP modifies the cooked dish (bean instances). If you need to change how a
bean is configured (change a property value, add a new @Bean definition),
use BFPP. If you need to wrap or validate bean instances, use BPP.

---

**[MID] Q6 - [CONCEPTUAL] What happens if @PostConstruct throws an exception?**

If @PostConstruct throws, Spring throws BeanCreationException and the entire
application context refresh fails. The application does not start.

This is intentional: Spring considers an application with a failed initialization
to be in an invalid state that should not serve traffic. Fail-fast at startup
is better than a partially initialized application accepting requests.

Best practices:
- Use @PostConstruct for assertions and validation that must pass
- Wrap recoverable errors in try-catch if startup should continue
- Do not use @PostConstruct for non-essential warm-up (use ApplicationReadyEvent)
- Log clearly what failed so operations can diagnose quickly

*What separates good from great:* In Kubernetes, a failed startup causes the
container to restart (CrashLoopBackOff). A clear startup error log message
with the configuration issue is the difference between a 5-minute fix and
a 2-hour investigation. @PostConstruct validation methods should throw
exceptions with descriptive messages: "Required property 'api.key' is missing"
not just NullPointerException.

---

**[SENIOR] Q7 - [CONCEPTUAL] What is the order of initialization callbacks?**

Within one bean, the order is:
1. @PostConstruct method (may have multiple - all called)
2. InitializingBean.afterPropertiesSet()
3. Custom initMethod specified in @Bean(initMethod="...")

For multiple beans: Spring initializes beans in dependency order (dependencies
first). You can also use @DependsOn to express initialization dependencies
that are not reflected in @Autowired.

Between @PostConstruct methods in the same bean: if multiple @PostConstruct
methods exist, the order is not guaranteed by Spring. If order matters, use
a single @PostConstruct that calls other methods in the desired order.

*What separates good from great:* @Order and @Priority affect AOP advisor
ordering and event listener ordering, but NOT bean initialization order.
Bean initialization order is determined by dependency graph, not @Order.
If you want one bean to initialize before another, declare an explicit
@Autowired dependency or use @DependsOn.

---

**[SENIOR] Q8 - [CONCEPTUAL] What is @DependsOn and when do you use it?**

@DependsOn forces Spring to initialize one bean before another, even when
there is no @Autowired dependency between them. This is for implicit dependencies
that cannot be expressed via injection.

Examples:
1. A service that requires a database schema to exist, but the schema
   migration bean (Flyway) is not in its dependency chain.
2. A bean that registers itself with a global registry during @PostConstruct -
   other beans that use the registry need it initialized first.

```java
@Bean
@DependsOn("flywayInitializer")
public OrderRepository orderRepository() {
    return new OrderRepositoryImpl(dataSource());
}

@Bean("flywayInitializer")
public Flyway flyway() {
    return Flyway.configure()
        .dataSource(dataSource())
        .load();
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Spring annotation. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* @DependsOn is a code smell in most cases.
Implicit dependencies that require @DependsOn usually indicate a design issue:
the ordering constraint should be expressed as an explicit bean dependency.
Legitimate use cases: legacy code integration, third-party library initialization,
global registries.

---

**[SENIOR] Q9 - [CONCEPTUAL] How does ApplicationReadyEvent differ from ContextRefreshedEvent**
       for post-startup initialization?

ContextRefreshedEvent:
- Fires when the ApplicationContext is refreshed (all beans created and wired)
- Fires on EVERY refresh (multiple times in web applications - parent and child
  context each refresh)
- @Transactional works at this point (proxies are created)
- No embedded server started yet

ApplicationReadyEvent (Spring Boot only):
- Fires after the entire application is ready to serve requests
- Fires exactly ONCE per application startup
- Embedded server is started and accepting connections
- Fired AFTER CommandLineRunner and ApplicationRunner beans have run

For most post-startup tasks: prefer ApplicationReadyEvent for Spring Boot
applications. It fires once, after everything is ready. For ContextRefreshedEvent,
check event.getApplicationContext() to avoid double-processing.

*What separates good from great:* ApplicationStartedEvent fires after
CommandLineRunner/ApplicationRunner beans have run. ApplicationReadyEvent fires
after Spring Boot's lifecycle management. For true "ready to serve traffic"
initialization (e.g., connect to external services), ApplicationReadyEvent is
semantically correct.

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



