---
layout: default
title: "Spring - META Patterns"
parent: "Spring"
nav_order: 10
permalink: /spring/meta-patterns/
---

# Spring - META Patterns

Transferable thinking patterns for mastering Spring and
any IoC/DI framework: recognizing framework magic,
diagnosing proxy-related failures, and using the right
mental model for configuration decisions.

---

# Spring Anti-Pattern Catalog

**Interview Weight:** high for staff/architect - Anti-patterns
reveal production experience. This keyword consolidates
the most dangerous Spring anti-patterns. Questions test
whether candidates recognize patterns they should avoid
and can explain why each fails in production.

---

### 🎯 Model Answer

**30 seconds:**

> The Spring anti-pattern catalog: (1) Transactional self-
> invocation: calling `@Transactional` methods from within
> the same bean bypasses the proxy. (2) Field injection:
> couples code to Spring, hides dependencies, untestable
> in isolation. (3) God Configuration classes: one `@Configuration`
> with hundreds of `@Bean` methods - unstructured, slow
> to load, hard to test. (4) Catching and swallowing
> exceptions inside `@Transactional` methods: Spring cannot
> roll back a transaction it cannot see. (5) Mutable
> singleton state: shared mutable fields in singleton beans
> cause race conditions.

**3 minutes (Senior):**

> The five most expensive Spring anti-patterns in production:
>
> **1. Transactional self-invocation**:
> `orderService.submitOrder()` calls `this.validateOrder()`
> inside the same class. If `validateOrder` is
> `@Transactional`, the proxy is bypassed - no transaction
> boundary is applied. Fix: extract the `@Transactional`
> method to a separate bean.
>
> **2. Catching exceptions inside @Transactional**:
> ```java
> @Transactional
> void process() {
>     try { repo.save(order); }
>     catch (Exception e) { log.error("failed"); }
>     // Transaction NOT rolled back - data corruption
> }
> ```
> Spring's `@Transactional` rolls back on unchecked exceptions.
> If you catch the exception and don't rethrow, Spring
> sees success, commits the partial transaction.
>
> **3. Mutable singleton state**:
> A singleton `@Service` bean with a mutable field
> (`private List<Request> cache`) is shared across all
> threads. Two concurrent requests can corrupt the list.
> Fix: use stateless services (no mutable fields) or
> thread-safe collections.
>
> **4. @Autowired field injection in production code**:
> Private field injection couples the class to Spring.
> In unit tests: field is null (no Spring context).
> Fix: constructor injection always.
>
> **5. Transaction inside a loop**:
> Calling a `@Transactional` method inside a loop opens
> and commits a new transaction per iteration. For 10,000
> items: 10,000 transactions. Fix: collect items and save
> in one transaction.

**Framework:** TRANSACTIONAL SELF-INVOKE (proxy bypass) →
EXCEPTION SWALLOWING (silent commit) →
MUTABLE SINGLETON (thread safety) →
FIELD INJECTION (hidden deps) →
TRANSACTION PER LOOP (performance)

*Adapting up:* Discuss `@TransactionalEventListener` vs
`@EventListener` (transactional events published before
commit are lost if the listener runs outside the transaction;
the listener should run after commit with `phase = AFTER_COMMIT`).

*Adapting down:* Anti-patterns are "traps that look right
but fail in production." They are the answers to "why did
this work in our tests but fail in production?"

---

### 📘 Concept Explanation

**Transactional self-invocation (most common):**

```
  EXTERNAL CALL (works - proxy intercepts)
  Client --> OrderServiceProxy.submit()
               --> opens transaction
               --> OrderService.submit()
               --> closes transaction

  SELF-INVOCATION (fails - proxy bypassed)
  Client --> OrderServiceProxy.submit()
               --> opens transaction
               --> OrderService.submit()
                    --> this.validate()
                         ^ no proxy involved
                         ^ @Transactional on validate() IGNORED
```

**Exception swallowing kills transaction integrity:**

```
  @Transactional void process()
    --> save(A)  [success, in transaction]
    --> save(B)  [throws exception]
    --> catch (Exception e) { log.error }  [swallowed]
    --> method returns normally
    --> Spring commits transaction
    --> A saved, B not saved: INCONSISTENT STATE
```

---

### 💻 Code Example

**Wrong vs Right: the five critical anti-patterns**

```java
// ANTI-PATTERN 1: Transactional self-invocation
@Service
public class OrderService {

    // BAD: this.submitOrder() is NOT proxied
    @Transactional
    public void processAll(List<Order> orders) {
        for (Order o : orders) {
            this.submitOrder(o);  // proxy bypassed!
        }
    }

    @Transactional(propagation = REQUIRES_NEW)
    public void submitOrder(Order o) {
        // This transaction boundary is NEVER applied
        repo.save(o);
    }
}

// ANTI-PATTERN 2: exception swallowing
@Service
public class PaymentService {
    @Transactional
    public void processPayment(Payment p) {
        try {
            chargeCard(p);
            updateBalance(p);
        } catch (PaymentException e) {
            log.error("payment failed: {}", e.getMessage());
            // Spring sees normal return: COMMITS partial state
        }
    }
}
```

```java
// GOOD: extract self-invoked @Transactional to separate bean
@Service
@RequiredArgsConstructor
public class OrderService {

    private final OrderSubmitter submitter;  // separate bean

    public void processAll(List<Order> orders) {
        for (Order o : orders) {
            submitter.submitOrder(o);  // proxy intercepts
        }
    }
}

@Service
public class OrderSubmitter {
    @Transactional(propagation = REQUIRES_NEW)
    public void submitOrder(Order o) {
        repo.save(o);  // independent transaction per order
    }
}

// GOOD: don't swallow exceptions inside @Transactional
@Service
public class PaymentService {
    @Transactional
    public void processPayment(Payment p) {
        chargeCard(p);   // throws on failure - rolls back
        updateBalance(p);
    }

    // Handle at calling layer (outside @Transactional)
    public PaymentResult tryProcessPayment(Payment p) {
        try {
            processPayment(p);
            return PaymentResult.success();
        } catch (PaymentException e) {
            log.error("payment failed", e);
            return PaymentResult.failure(e.getMessage());
        }
    }
}
```

> **Code walkthrough:** The self-invocation fix is
> architectural: extract the `@Transactional` method into
> a separate Spring-managed bean. When `processAll` calls
> `submitter.submitOrder`, it goes through `submitter`'s
> proxy - the `REQUIRES_NEW` transaction boundary is
> correctly applied per order. The exception swallowing
> fix separates concerns: `processPayment` is a pure
> transactional boundary (let exceptions propagate for
> rollback). `tryProcessPayment` is the caller-friendly
> wrapper that handles the exception at the service boundary
> where transaction management is already complete.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**

> In production codebases, transactional self-invocation
> is the most common Spring bug I've seen. It's dangerous
> because tests often don't catch it: unit tests mock the
> dependency and don't go through the proxy; integration
> tests with `@SpringBootTest` only catch it if the test
> calls the method from outside the bean (as a client would).
>
> Mutable singleton state is the second most dangerous -
> it's a concurrency bug that only appears under load. A
> singleton `@Service` with a field like `private int counter`
> used to track request counts will produce race conditions
> under concurrent requests. Spring singletons are shared
> across all threads. Use `AtomicInteger`, `ThreadLocal`,
> or better: make the service stateless and move state to
> the database or cache.

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | @Transactional always prevents partial data | @Transactional only works if: (a) the proxy intercepts the call, (b) exceptions propagate (not swallowed). Both conditions can silently fail leaving partial data committed. | Silent data corruption in production |
| 2 | Thread-safety in Spring beans is automatic | Spring manages bean lifecycle (creation, dependency injection) but does NOT manage thread safety of bean fields. Singleton beans shared across threads require explicit thread safety (stateless design, concurrent collections, AtomicXxx). | Race conditions on mutable singleton fields |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - @Transactional REQUIRES_NEW not creating new transaction**

Symptom: `REQUIRES_NEW` not starting a new transaction;
method participates in outer transaction instead.

Root cause: self-invocation. `this.requiresNewMethod()`
bypasses the proxy; the propagation annotation is ignored.

Diagnosis: add logging to verify proxy is involved:
```java
// Check if current class is a proxy (should be)
log.info("Is proxy: {}",
    AopUtils.isAopProxy(this));
log.info("Current tx: {}",
    TransactionSynchronizationManager
        .getCurrentTransactionName());
```

Fix: extract to separate bean.

---

### 🎯 Interview Deep-Dive

**[STAFF] Q1: You join a team and their @Transactional
annotated methods are sometimes not rolling back on
exceptions. Walk through your diagnostic process.**
[DEBUGGING + BEHAVIORAL]

*Why they ask:* Tests real production debugging experience.

*Likely follow-up:* "What monitoring would you add to prevent this class of bug?"

Step 1: Determine if the proxy is being bypassed
- Is the `@Transactional` method being called from within
  the same class? (self-invocation)
- Add `log.info("in tx: {}", TransactionSynchronizationManager.isActualTransactionActive())`
  inside the method
- If `false`: proxy bypassed. Fix: extract to separate bean.

Step 2: Determine if exception is being swallowed
- Review the method body for `try/catch` that catches and
  doesn't rethrow
- Review callers: is someone catching the exception before
  Spring's proxy can see it?
- Add `@Transactional(rollbackFor = Exception.class)` if
  the method throws checked exceptions (Spring only rolls
  back unchecked by default)

Step 3: Check transaction propagation
- Is the method marked `@Transactional(propagation = NOT_SUPPORTED)` or `NEVER`?
- Is the calling method also `@Transactional(propagation = REQUIRES_NEW)`
  which suspends the outer transaction?

Step 4: Verify Spring's transaction manager is configured
- `@EnableTransactionManagement` present?
- `PlatformTransactionManager` bean registered?

Monitoring to prevent this class of bug:
- `TransactionSynchronizationManager.registerSynchronization`
  to log transaction lifecycle
- Integration tests for every `@Transactional` method
  that verify rollback on exception

*What separates good from great:* Starting with
`isActualTransactionActive()` diagnostic (eliminates proxy
bypass in 30 seconds) rather than reading code for hours.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with transactional proxy mechanics and diagnosis steps. |
| Hiring Manager | Lead with production impact (data corruption) and prevention. |
| Bar Raiser | Lead with monitoring strategy to detect transactional failures before data corruption occurs. |
| Peer Engineer | "The @Transactional method that worked in all tests but silently committed partial data in prod - every Spring team has one..." |

---

---

# Spring Interview Mental Model

**Interview Weight:** META - This keyword gives the cognitive
map for answering any Spring question. The mental model
for Spring: everything is a proxy, everything is a bean,
the container is the source of truth. When something fails:
ask "is the proxy involved?", "is the bean in scope?",
"is the container aware of this object?".

---

### 🎯 Model Answer

**30 seconds:**

> Spring is a "magic box" framework - it does a lot
> automatically. The mental model for mastering it: (1)
> Everything with @Transactional/@Cacheable/@Async is
> a proxy - if the proxy is not involved, the annotation
> does nothing. (2) Spring only manages objects it creates -
> if you `new SomeService()`, Spring knows nothing about it.
> (3) Context is king - beans are scoped to an Application
> Context; accessing a bean outside its scope causes errors.
> With these three rules, you can diagnose 90% of Spring
> issues.

**3 minutes:**

> The three-rule mental model for Spring debugging:
>
> **Rule 1: Annotations work through proxies.**
> `@Transactional`, `@Cacheable`, `@Async`, `@PreAuthorize`
> all work by wrapping your bean in a proxy. The proxy
> intercepts method calls and adds the behavior. If the
> proxy is bypassed (self-invocation, calling on an unwrapped
> reference), the annotation is silently ignored.
>
> **Rule 2: Spring only manages beans it creates.**
> If you call `new OrderService()`, Spring cannot inject
> dependencies, apply AOP, or manage lifecycle. This is
> the most common mistake in unit tests that accidentally
> use real objects instead of Spring-managed beans.
> In JPA: entities are created by Hibernate, not Spring.
> `@Autowired` on entity fields never works.
>
> **Rule 3: Context is king.**
> A Spring bean lives in an `ApplicationContext`. Accessing
> a request-scoped bean from a singleton requires a proxy.
> A bean created in one context cannot be injected into
> a bean in a different context. In tests: each
> `@SpringBootTest` creates a new context (unless cached).

*Adapting up:* Extend with Rule 4: "Configuration is
resolved before beans are created." `BeanFactoryPostProcessor`s
run before bean instantiation. Property resolution happens
before `@Value` injection. Any bug where a value is null
at startup maps to this ordering.

---

### 📘 Concept Explanation

**The three mental model rules visualized:**

```
  RULE 1: PROXY GOVERNS ANNOTATIONS

  Client
    |
    v
  Spring Proxy (CGLIB/JDK)
    --> @Transactional: opens tx
    --> @Cacheable: checks cache
    --> @Async: submits to executor
    |
    v
  Your Bean Method
    --> does real work
    |
    v
  Spring Proxy
    --> @Transactional: commits/rolls back
    --> @Cacheable: stores result

  SELF-INVOCATION: proxy is skipped:
  Client -> Proxy -> Bean.outerMethod()
                       -> this.innerMethod()
                       NO PROXY INVOLVEMENT
                       @Transactional on innerMethod IGNORED

  RULE 2: SPRING ONLY MANAGES ITS OWN BEANS

  Spring-managed:  @Component, @Bean, @Service etc.
  NOT managed:     new Service(),
                   Hibernate entities,
                   Objects created by external frameworks

  RULE 3: CONTEXT IS KING

  ApplicationContext
    -> BeanA (singleton)
    -> BeanB (request-scoped) <- accessed via proxy in singletons
    -> BeanC (prototype)      <- new instance each time
```

---

### 💻 Code Example

**Mental model applied to real debugging scenarios**

```java
// Rule 1 applied: check if proxy is involved
// Diagnostic snippet to add when @Transactional fails:

@Service
public class OrderService {

    @Autowired
    private ApplicationContext context;

    @Transactional
    public void processOrder(Order order) {
        // Verify I am being called via proxy
        // (should always be true for external calls)
        boolean inTransaction =
            TransactionSynchronizationManager
                .isActualTransactionActive();
        log.debug("In transaction: {}", inTransaction);

        // Verify the bean is a proxy (not raw)
        OrderService self = context.getBean(OrderService.class);
        boolean isProxy = AopUtils.isAopProxy(self);
        log.debug("Bean is proxy: {}", isProxy);
    }
}
```

```java
// Rule 2 applied: Spring cannot inject into new-ed objects
// BAD: @Autowired on manually created object is null
public class OrderController {
    @GetMapping("/orders")
    public List<Order> getOrders() {
        // Spring has no idea about this instance
        OrderService svc = new OrderService();
        return svc.findAll();  // NullPointerException:
        // svc.repo is null - Spring never injected it
    }
}

// GOOD: inject Spring-managed bean
@RestController
public class OrderController {
    private final OrderService orderService;

    // Spring manages orderService - all its deps injected
    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping("/orders")
    public List<Order> getOrders() {
        return orderService.findAll();  // deps injected, works
    }
}
```

> **Code walkthrough:** The `isActualTransactionActive()`
> check is the fastest proxy diagnostic: if it returns
> false in a `@Transactional` method, the proxy is not
> involved. `AopUtils.isAopProxy(self)` verifies the bean
> from the context is proxied (it should be for any bean
> with AOP annotations). The `new OrderService()` anti-pattern
> demonstrates Rule 2: Spring cannot inject dependencies
> into objects it did not create. The `repo` field is
> null because `AutowiredAnnotationBeanPostProcessor` never
> ran on this instance.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**

> The three-rule mental model works for 90% of Spring
> debugging. But mastery requires understanding the fourth
> rule: configuration ordering. When you see a null
> `@Value` field, an unexpected bean not being registered,
> or a `BeanCreationException` at startup, the issue is
> almost always ordering: BFPP > BPP > bean instantiation.
>
> The meta-skill is: before reading Spring source code,
> apply the rules in order. Is the proxy involved? Is
> the object Spring-managed? Is the context correct?
> Is the ordering correct? 95% of Spring issues are
> answered by these four questions.

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | @Transactional on a private method works | Spring's CGLIB proxy can only override public methods. @Transactional on private methods is silently ignored. The annotation is syntactically valid but has no effect. | Silent data corruption - method appears transactional, isn't |
| 2 | Spring manages all objects in the application | Spring manages only objects registered as beans in the ApplicationContext. JPA entities, DTOs, and any object created with `new` are not managed by Spring. | @Autowired on entity fields or DTOs is always null |

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: How would you mentor a junior developer to
debug Spring issues without reading the framework source?**
[BEHAVIORAL + MENTAL MODEL]

*Why they ask:* Tests communication of Spring knowledge and mentoring ability.

Teach the three-rule checklist as a debugging ritual:

**Step 1: Is the proxy involved?**
Ask: "Is this annotation (`@Transactional`, `@Cacheable`,
`@Async`) on a public method?" "Is the call coming from
outside the class?" Add `TransactionSynchronizationManager
.isActualTransactionActive()` to verify.

**Step 2: Is Spring managing this object?**
Ask: "Did I get this from the Spring context (injected)
or did I create it with `new`?" "Is this class annotated
with `@Component`, `@Service`, etc.?" Check: add a
`@PostConstruct` - if it runs, Spring manages it.

**Step 3: Is the bean in the right context/scope?**
Ask: "Is this a singleton accessing a request-scoped
bean?" "Is this test creating a separate ApplicationContext?"
Check: `context.getBeanDefinition(beanName).getScope()`

**Step 4: Is configuration ordered correctly?**
Ask: "Is this `@Value` null at startup?" "Is this BFPP
class that also has `@Value` fields?" Check: does the
issue go away if you remove `BeanFactoryPostProcessor`
from the class hierarchy?

Give them a Spring debugging checklist card to use for
their first 3 months. After 3 months, the checklist is
internalized.

*What separates good from great:* Giving concrete, actionable
diagnostic commands (not just "check if it's a proxy")
and a mental checklist that makes debugging predictable
rather than mysterious.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with proxy mechanics and the three-rule model. |
| Hiring Manager | Lead with mentoring approach and reducing debugging time for the team. |
| Bar Raiser | Lead with Rule 4 (configuration ordering) and connect to BeanFactoryPostProcessor lifecycle. |
| Peer Engineer | "The first time you explain the proxy model to a junior and watch the 'aha' moment when 3 months of Spring confusion resolves in 5 minutes..." |

---

---

# Framework Magic Decision Framework

**Interview Weight:** META - The "framework magic decision
framework" is the meta-skill for deciding when to embrace
Spring's automatic behavior vs when to be explicit. Staff
engineers are expected to have this framework articulated.
It also covers when NOT to use Spring (embedded systems,
ultra-low latency, command-line tools).

---

### 🎯 Model Answer

**30 seconds:**

> The Framework Magic Decision Framework: use Spring's
> automatic behavior (auto-configuration, `@Transactional`,
> `@Cacheable`) when the behavior is consistent with your
> intent and you can verify it works. Be explicit (manual
> `TransactionTemplate`, manual cache logic) when you need
> precise control, when the proxy may be bypassed, or when
> debugging requires visibility. Know when to NOT use
> Spring: command-line tools, serverless functions (cold
> start), ultra-low latency systems (GC pressure from
> context), and embedded systems.

**3 minutes (Senior):**

> The decision matrix for framework magic:
>
> **Use magic when:**
> - The behavior is well-understood and tested
> - The auto-configuration matches your infrastructure
>   (Spring Boot detects JDBC driver, configures DataSource)
> - The proxy will always be involved (public method,
>   called from outside the bean)
>
> **Be explicit when:**
> - You need precise transaction boundaries (use
>   `TransactionTemplate` for programmatic control)
> - You need to control cache behavior based on runtime
>   conditions (manual `Cache.get()` / `Cache.put()`)
> - You are inside a loop or conditional and need
>   fine-grained control
> - Debugging: add explicit transaction checks to verify
>   behavior before trusting the annotation
>
> **Don't use Spring when:**
> - Serverless (Lambda/Cloud Functions): Spring Boot's
>   ~2-second cold start is too slow. Use Quarkus/Micronaut
>   (build-time DI, native compilation)
> - Ultra-low latency (trading systems, HFT): Spring's
>   GC pressure from proxy object creation is unacceptable.
>   Use pure Java.
> - Simple CLI tools: Spring adds ~1s startup + memory
>   overhead. Use Picocli + manual DI.

**Framework:** MAGIC EMBRACE (auto-config, annotations) →
EXPLICIT CONTROL (programmatic tx, manual cache) →
KNOW THE LIMITS (when Spring adds more friction than value)

---

### 📘 Concept Explanation

**Framework magic decision matrix:**

```
  WHEN ANNOTATION MAGIC IS SAFE
  [Method public?] --yes--> [Called externally?]
     --yes--> [Tested with integration test?]
        --yes--> USE MAGIC (@Transactional, @Cacheable)

  WHEN TO USE PROGRAMMATIC CONTROL
  [Inside loop?] --yes--> USE TransactionTemplate
  [Conditional cache?] --yes--> USE CacheManager directly
  [Proxy may be bypassed?] --yes--> USE explicit API

  WHEN NOT TO USE SPRING
  [Serverless?] --> Quarkus/Micronaut (native image)
  [Ultra-low latency?] --> Pure Java
  [CLI tool < 1s startup?] --> Picocli + manual DI
  [Embedded device?] --> Pure Java or Micronaut
```

---

### 💻 Code Example

**Wrong vs Right: annotation magic vs explicit control**

```java
// BAD: @Transactional inside a loop
// Opens and commits a transaction per item (slow)
@Service
public class BulkOrderService {
    @Transactional
    public void processBulk(List<Order> orders) {
        for (Order o : orders) {
            submitSingle(o);  // @Transactional per call
        }
    }
    @Transactional
    public void submitSingle(Order o) {
        repo.save(o);  // NEW transaction per order
        // 10,000 orders = 10,000 transactions
    }
}
```

```java
// GOOD: programmatic transaction control for bulk
@Service
@RequiredArgsConstructor
public class BulkOrderService {

    private final TransactionTemplate txTemplate;
    private final OrderRepository repo;

    public void processBulk(List<Order> orders) {
        // One transaction per batch of 100 (configurable)
        Lists.partition(orders, 100).forEach(batch ->
            txTemplate.execute(status -> {
                batch.forEach(repo::save);
                return null;
            })
        );
        // 10,000 orders = 100 transactions (100x faster)
    }
}

// Configuration
@Configuration
public class TxConfig {
    @Bean
    public TransactionTemplate transactionTemplate(
        PlatformTransactionManager txManager) {
        TransactionTemplate template =
            new TransactionTemplate(txManager);
        template.setIsolationLevel(
            TransactionDefinition.ISOLATION_READ_COMMITTED);
        return template;
    }
}
```

> **Code walkthrough:** `TransactionTemplate` gives
> programmatic control over transaction boundaries. Instead
> of 10,000 transactions (one per `@Transactional` call),
> we batch into groups of 100 and wrap each batch in one
> transaction. `Lists.partition` (Guava) splits the list.
> `txTemplate.execute(status -> { ... })` is the transaction
> boundary. If any save in the batch fails, the entire
> batch is rolled back (the `TransactionStatus.setRollbackOnly()`
> or re-throwing from the lambda triggers rollback).
> This is 100x fewer transactions for 10,000 orders.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**

> My rule of thumb: use annotation magic as the default.
> It's declarative, readable, and Spring's proxy model
> is well-tested. Switch to programmatic when I need:
> (1) fine-grained boundaries (loops, batches), (2)
> conditional behavior (sometimes cache, sometimes not),
> (3) precise error handling (rollback-only vs throw vs
> retry).
>
> The "when not to use Spring" question is equally important.
> I've seen teams add Spring Boot to AWS Lambda functions
> that take 15 seconds to cold-start (unacceptable for
> 99th-percentile latency). The fix was Quarkus with native
> compilation (50ms cold start). Framework choice must
> account for the runtime environment, not just developer
> familiarity.

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | More @Transactional annotations = more transactional safety | Excessive @Transactional on every method creates long-running transactions that hold database locks, increase deadlock risk, and degrade performance. Use @Transactional at the service layer boundary, not on every repository method. | Long-running transactions cause database lock contention at scale |
| 2 | Spring is always the right choice for Java services | Spring adds 1-2 seconds startup time and significant memory overhead. For serverless, CLI tools, and ultra-low latency systems, lighter alternatives (Micronaut, Quarkus, Javalin) are better choices. | Over-use of Spring in contexts where its overhead is unacceptable |

---

### 🎯 Interview Deep-Dive

**[STAFF] Q1: When would you NOT use Spring for a Java
service, and what would you use instead?** [DECISION + TRADE-OFF]

*Why they ask:* Tests judgment on framework selection and knowledge of alternatives.

*Likely follow-up:* "How do you handle dependency injection in those cases?"

Use Spring when: long-running services (web APIs, batch
jobs, message consumers) where startup time is irrelevant
and you need the full ecosystem (security, data access,
testing support).

Do NOT use Spring when:

**Serverless (AWS Lambda, Google Cloud Functions)**:
Problem: Spring Boot cold start is 2-5 seconds. Lambda
invocations can time out or cause poor P99 latency.
Alternative: Quarkus or Micronaut (build-time DI, no
reflection at startup). GraalVM native image: 50ms cold
start. Alternatively: Spring Native (GraalVM integration
is maturing in Spring Boot 3).

**Ultra-low latency (trading, HFT, real-time)**:
Problem: Spring's proxy object creation generates garbage.
GC pauses (even with ZGC/G1) are unacceptable for
microsecond-level systems.
Alternative: Pure Java with manual DI, Chronicle Map for
off-heap state, mechanical sympathy patterns.

**Simple CLI tools (scripts, one-shot jobs)**:
Problem: Spring Boot adds ~1s startup + 200MB heap
overhead. For a script that runs in 100ms, this is
disproportionate overhead.
Alternative: Picocli (CLI framework) + manual constructor
injection. Or: use a `@SpringBootTest` for the heavy logic
and a plain main() for the CLI wrapper.

**Embedded systems / microcontrollers**:
Problem: Spring requires a JVM. Most embedded systems
don't have one.
Alternative: native C/C++ or Rust, or MicroEJ for Java
on embedded.

DI in non-Spring contexts: use constructor injection
manually (it's just passing objects). For larger projects:
Guice (Google, lighter than Spring), Dagger 2 (compile-
time DI, zero runtime overhead), or Micronaut (build-
time DI, native-image friendly).

*What separates good from great:* Recommending Spring Native
(GraalVM) as a path to fast startup while keeping the Spring
ecosystem - shows awareness that Spring is adapting to
address its startup time limitation.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with the decision matrix (magic vs explicit). |
| Hiring Manager | Lead with when not to use Spring and the business impact (cold start, latency). |
| Bar Raiser | Lead with Spring Native / GraalVM as the future path and DI alternatives. |
| Peer Engineer | "The Lambda function with 15 second cold start because someone added Spring Boot 'for familiarity'..." |
