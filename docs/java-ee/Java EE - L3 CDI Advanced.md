---
layout: default
title: "Java EE - L3 CDI Advanced"
parent: "Java EE"
nav_order: 8
permalink: /java-ee/l3-cdi-advanced/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 18 | [CDI Events and Producers](#cdi-events-and-producers) | ★★☆ |
| 19 | [CDI Interceptors and Decorators](#cdi-interceptors-and-decorators) | ★★☆ |

---

# CDI Events and Producers

**Interview Weight:** ★★☆ - Intermediate.

---

### 🎯 Model Answer

**30 seconds:**

> CDI Events provide a type-safe publish-subscribe mechanism
> within one JVM: fire an event with Event.fire(), and any
> bean with @Observes for that event type receives it.
> Observers execute synchronously in the same transaction
> by default. CDI Producers are factory methods that create
> beans CDI cannot instantiate itself. Both mechanisms
> keep CDI beans decoupled from each other and from
> external APIs.

**3 minutes:**

> CDI Events:
>
> - Event source: inject Event<T> and call .fire(payload)
> - Observer: any method annotated @Observes T payload
> - Synchronous: all observers run before .fire() returns
> - Asynchronous: .fireAsync() returns CompletionStage;
>   observers run in a managed executor
> - Qualifiers: narrow events to specific observers
> - Transaction scoping: @Observes(during=AFTER_SUCCESS)
>   runs observer only if TX committed
>
> CDI Producers:
>
> - @Produces on a method: CDI calls this to satisfy
>   injection points of the return type
> - @Disposes: companion method for cleanup
> - Common uses: Logger, configuration values,
>   third-party objects CDI cannot instantiate

**Blank Mind Recovery:**

**(1) Restate:** "Events: fire() - observers run. Producers:
@Produces method - CDI calls it to create beans.
Both patterns for loose coupling."

**(2) First principles:** "Decoupling = sender doesn't know
receivers. Events = decoupled notification. Producers =
decoupled factory."

**(3) Bridge:** "Spring: ApplicationEventPublisher (events),
@Bean factory methods (producers)."

---

### 📘 Concept Explanation

**What it is:**

CDI Events: type-safe publish-subscribe within the CDI
container. No JMS, no message broker - method calls
orchestrated by CDI.

CDI Producers: factory mechanism. Enables injection
of objects CDI cannot instantiate directly.

**Event lifecycle:**

```
event.fire(new OrderPlaced(order));
  -> CDI finds all @Observes(OrderPlaced) methods
  -> Calls each observer synchronously
  -> fire() returns after all observers complete
  -> Any observer throws: propagates to caller
```

**Qualifier narrowing:**

```java
@Qualifier @Retention(RUNTIME)
@Target({METHOD, FIELD, PARAMETER, TYPE})
public @interface Updated {}

@Inject @Updated Event<Order> updatedEvent;
updatedEvent.fire(order); // only @Updated observers

public void onUpdate(@Observes @Updated Order o) { }
// No @Updated qualifier = receives ALL Order events
```

**Producer method:**

```java
@ApplicationScoped
public class LoggerProducer {
    @Produces @Dependent
    public Logger createLogger(InjectionPoint ip) {
        return Logger.getLogger(
            ip.getMember()
              .getDeclaringClass().getName()
        );
    }
}
// Any bean: @Inject Logger log; -> class-specific
```

---

### 💻 Code Example

```java
// CDI Events: order notification pipeline

public class OrderPlaced {
    private final Long orderId;
    private final String customerEmail;
    public OrderPlaced(Long id, String email) {
        orderId = id; customerEmail = email;
    }
    public Long getOrderId() { return orderId; }
    public String getCustomerEmail() {
        return customerEmail;
    }
}

@Stateless
public class OrderService {
    @PersistenceContext EntityManager em;
    @Inject Event<OrderPlaced> orderPlacedEvent;

    public Order placeOrder(CreateOrderRequest req) {
        Order order = new Order(req);
        em.persist(order);
        // Synchronous: all observers run before return
        orderPlacedEvent.fire(
            new OrderPlaced(
                order.getId(),
                req.getCustomerEmail()
            )
        );
        return order;
    }
}

@ApplicationScoped
public class EmailNotificationService {
    // No dependency on OrderService
    public void sendConfirmation(
            @Observes OrderPlaced event) {
        log.info("Email for order: " +
            event.getOrderId());
    }
}

// AFTER_SUCCESS: only if TX committed
@ApplicationScoped
public class AnalyticsService {
    public void trackOrder(
            @Observes(during =
                TransactionPhase.AFTER_SUCCESS)
            OrderPlaced event) {
        log.info("Analytics: " + event.getOrderId());
    }
}

// Producer: Logger per injecting class
@ApplicationScoped
public class LoggerProducer {
    @Produces @Dependent
    public Logger createLogger(InjectionPoint ip) {
        return Logger.getLogger(
            ip.getMember()
              .getDeclaringClass().getName()
        );
    }
}

// Producer: config value
@ApplicationScoped
public class ConfigProducer {
    @Inject ConfigService config;

    @Produces @ApplicationScoped
    @Named("maxRetries")
    public int maxRetries() {
        return Integer.parseInt(
            config.getValue("app.max.retries", "3")
        );
    }

    public void disposeConnection(
            @Disposes Connection conn) {
        try {
            if (!conn.isClosed()) conn.close();
        } catch (Exception e) {
            log.warn("Close failed: " + e.getMessage());
        }
    }
}

// Usage: @Inject @Named("maxRetries") int maxRetries;
```

> **Code walkthrough:** OrderService fires an OrderPlaced
> event without knowing any observers - complete decoupling.
> EmailNotificationService and AnalyticsService observe
> independently with no import of OrderService.
> AnalyticsService uses AFTER_SUCCESS: only runs if the
> JTA transaction commits, preventing analytics for
> rolled-back orders. LoggerProducer uses InjectionPoint
> to determine the injecting class name, creating a
> class-specific Logger with zero configuration at the
> injection site. If any synchronous observer throws,
> the exception propagates through fire() to the caller,
> potentially marking the transaction rollback-only.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "CDI Events let one bean fire an event and all other
> beans with @Observes receive it - no direct dependency.
> Event.fire() is synchronous: all observers run before
> it returns. CDI Producers are @Produces-annotated methods
> that create objects CDI cannot instantiate directly -
> like Logger with the injection point class name, or
> configuration values from external config."

---

**Senior / Staff:**

> "@Observes(during=AFTER_SUCCESS) is critical for side
> effects that must not happen for failed transactions:
> analytics, email, external API calls. Without it,
> observers run before commit and execute for data that
> may never persist. CDI Producers solve the abstraction
> problem for external APIs: inject Logger, EntityManager
> per-context, or configuration values with full CDI
> type safety. InjectionPoint in producer methods enables
> context-sensitive creation."

---

### ⚠️ Common Misconceptions

**Misconception: "CDI Events can replace JMS for
cross-service messaging."**

CDI Events are intra-JVM only: fire-and-observe within
one application. No persistence, no delivery guarantee,
no cross-JVM delivery. If the JVM crashes after fire()
but before all observers complete, the event is lost.
For cross-service or durable delivery, use JMS or a
message broker. CDI Events complement JMS but do not
replace it.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Observer exception rolls back transaction**

*Symptom:* Business logic succeeds but transaction
rolls back. Exception message references an observer.

*Root cause:* Synchronous @Observes method threw an
unchecked exception. fire() is synchronous so the
exception propagates to the method that called fire(),
marking the transaction rollback-only.

*Diagnosis:*
```bash
grep -E "Observer|fire" server.log | grep -i exception
/subsystem=weld:write-attribute(name=development-mode,
  value=true)
```

*Fix:*
```java
// GOOD: catch in observer, do not propagate
public void onOrderPlaced(@Observes OrderPlaced e) {
    try {
        sendEmail(e);
    } catch (Exception ex) {
        log.error("Email failed: " + ex.getMessage());
        // TX not affected
    }
}

// ALSO GOOD: async events for full isolation
event.fireAsync(new OrderPlaced(order));
// @ObservesAsync exceptions do NOT affect caller's TX
```

---

### ⚖️ Comparison Table

| Aspect | CDI Events | JMS | Spring Events |
|--------|-----------|-----|---------------|
| Scope | Intra-JVM | Cross-JVM/durable | Intra-JVM |
| Sync/Async | Both | Async default | Both |
| Durability | None | Durable | None |
| Type safety | Full | No (bytes) | Full |
| TX integration | @Observes(during=) | TX listener | @TransactionalEventListener |
| Setup | Zero config | Broker required | Zero config |

*(System Design: omit - not a ★★★ entry)*

### 📊 Diagram

```
CDI EVENT DISPATCH:

OrderService     CDI Container      Observers
     |                |                 |
     |--fire(event)-->|                 |
     |                |--sendConfirm--->| EmailService
     |                |<-complete-------|
     |                |--updateSnap---->| InventoryService
     |                |<-complete-------|
     |<-fire returns--|                 |
     TX commits       |                 |
     |                |--trackOrder---->| AnalyticsService
     |                |  (AFTER_SUCCESS)|
```

```mermaid
sequenceDiagram
    participant OS as OrderService
    participant CDI as CDI Container
    participant ES as EmailService
    participant IS as InventoryService
    participant AS as AnalyticsService(AFTER_SUCCESS)
    OS->>CDI: event.fire(OrderPlaced)
    CDI->>ES: sendConfirmation(event)
    ES-->>CDI: done
    CDI->>IS: updateSnapshot(event)
    IS-->>CDI: done
    CDI-->>OS: fire() returns
    note over CDI,AS: JTA TX commits
    CDI->>AS: trackOrder(event)
```

> **Diagram walkthrough:** fire() dispatches each observer
> synchronously before returning. OrderService has no
> knowledge of observers. AnalyticsService with AFTER_SUCCESS
> runs after the JTA transaction commits - a separate
> dispatch triggered by the transaction lifecycle. If the
> TX rolls back, AnalyticsService is never called, which
> prevents analytics for failed operations.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| CDI Events fire/observe basics | 2-3 min |
| Event qualifiers | 2-3 min |
| Transaction phases for observers | 3-4 min |
| Async events | 2-3 min |
| Producer methods | 3-4 min |
| @Disposes cleanup | 2 min |
| CDI vs JMS events | 3-4 min |
| Observer exception handling | 3-4 min |
| InjectionPoint in producers | 2-3 min |

---

**[MID] Q1 - How do you narrow CDI events to
specific observers using qualifiers?**

*Why they ask:* Event qualifier usage.

```java
@Qualifier @Retention(RUNTIME)
@Target({METHOD, FIELD, PARAMETER, TYPE})
public @interface Updated {}

@Inject @Updated Event<Order> updatedEvent;
updatedEvent.fire(order); // only @Updated observers

public void onUpdate(@Observes @Updated Order o) {} // yes
public void onAny(@Observes Order o) {}
// receives ALL Order events (including @Updated)
```

*What separates good from great:* "An observer without
a qualifier receives ALL events of that type, including
those fired with qualifiers. Use qualifiers consistently."

---

**[MID] Q2 - What is TransactionPhase in @Observes
and why is it important?**

*Why they ask:* Transaction-scoped event handling.

- IN_PROGRESS (default): during TX, before commit
- AFTER_SUCCESS: only if TX committed
- AFTER_FAILURE: only if TX rolled back
- AFTER_COMPLETION: always after TX ends

```java
public void sendEmail(
        @Observes(during = TransactionPhase.AFTER_SUCCESS)
        OrderPlaced event) {
    // Guaranteed: order is committed to DB
}
```

*What separates good from great:* "Default IN_PROGRESS
runs before commit. Data may never persist if TX rolls
back. Always use AFTER_SUCCESS for external notifications."

---

**[MID] Q3 - What is a CDI producer method?**

*Why they ask:* CDI producer knowledge.

@Produces: CDI calls the method to satisfy injection
points of the return type.

```java
@Produces @Dependent
public Logger logger(InjectionPoint ip) {
    return Logger.getLogger(
        ip.getMember().getDeclaringClass().getName()
    );
}
// @Inject Logger log; -> class-specific logger
```

*What separates good from great:* "InjectionPoint gives
the producer context about where injection happens.
The Logger producer is the textbook example."

---

**[SENIOR] Q4 - How do CDI fireAsync events work?**

*Why they ask:* Async events and thread safety.

fireAsync() dispatches to managed executor, returns
CompletionStage. Caller continues immediately.

```java
event.fireAsync(new OrderPlaced(order.getId()))
    .exceptionally(t -> {
        log.error("Observer failed: " + t.getMessage());
        return null;
    });

// @ObservesAsync (not @Observes) for async observer
public void sendEmail(@ObservesAsync OrderPlaced e) {
    emailClient.send(e.getCustomerEmail(), ...);
}
```

Async observer exceptions do NOT affect caller's TX.

*What separates good from great:* "Use fireAsync for I/O
in observers (email, HTTP) to avoid slowing the main
request. The caller's TX may commit before observers
run: they see committed data, which is correct."

---

**[SENIOR] Q5 - What is @Disposes and when is it needed?**

*Why they ask:* Producer cleanup.

@Disposes: CDI calls it when the produced bean's scope
ends. Matched to @Produces by parameter type.

```java
@Produces @RequestScoped
public Connection createConnection() throws SQLException {
    return dataSource.getConnection();
}

public void close(@Disposes Connection conn) {
    try { if (!conn.isClosed()) conn.close(); }
    catch (SQLException e) { log.warn("Close", e); }
}
```

*What separates good from great:* "Forgetting @Disposes
for resource-producing methods causes leaks."

---

**[SENIOR] Q6 - How do CDI observers interact with
JTA transactions?**

*Why they ask:* TX + event interaction.

Default IN_PROGRESS observers run in the SAME TX:
em.persist() in the observer participates in caller's TX.

AFTER_SUCCESS: no TX from fire(). Need to create
new TX if DB writes are needed.

*What separates good from great:* "IN_PROGRESS observer
RuntimeException rolls back main TX. Use AFTER_SUCCESS
for external notifications so email failure doesn't
roll back the business operation."

---

**[SENIOR] Q7 - How would you implement an event-driven
pipeline with CDI?**

*Why they ask:* Architecture with CDI events.

Each step observes previous event and fires next:

```java
// Step 2 observes and fires next event:
public class InventoryProcessor {
    @Inject Event<InventoryReserved> reserved;
    public void onOrder(@Observes OrderPlaced e) {
        inventory.reserve(e.getOrderId());
        reserved.fire(
            new InventoryReserved(e.getOrderId())
        );
    }
}
```

All in one TX: if any step fails, all roll back.

*What separates good from great:* "Elegant for simple
pipelines. For resilient pipelines with partial retry,
use JMS + Outbox: each step has its own transaction."

---

**[SENIOR] Q8 - What thread-safety implications
exist for CDI producers?**

*Why they ask:* Producer scope and concurrency.

Scope controls sharing. @ApplicationScoped: one instance,
must be thread-safe. @RequestScoped: one per request.

Producer method runs on the enclosing bean instance.
Avoid mutable state in @ApplicationScoped producer classes.

*What separates good from great:* "The produced bean's
scope and producer class scope are independent. A
@Dependent producer method in @ApplicationScoped class
creates new instance per injection, but producer method
itself runs on the shared @ApplicationScoped instance."

---

**[SENIOR] Q9 - How do you test CDI events?**

*Why they ask:* Testability.

Unit test - mock Event<T>:
```java
@Mock Event<OrderPlaced> orderPlacedEvent;
@InjectMocks OrderService orderService;

@Test
void test() {
    orderService.placeOrder(req);
    verify(orderPlacedEvent).fire(any(OrderPlaced.class));
}
```

*What separates good from great:* "Integration tests
catch AFTER_SUCCESS observer issues that unit tests miss.
Quarkus @TestTransaction is simplest for transactional
observer testing."

---

---

# CDI Interceptors and Decorators

**Interview Weight:** ★★☆ - Intermediate.

---

### 🎯 Model Answer

**30 seconds:**

> CDI Interceptors add cross-cutting behavior (logging,
> security, metrics) around method calls without changing
> business logic. CDI Decorators wrap a specific interface
> to extend its business behavior. Interceptors = infrastructure
> concerns. Decorators = business concerns. Both are
> implemented as separate classes and applied declaratively.

**3 minutes:**

> Interceptors:
>
> - Define @InterceptorBinding annotation (e.g., @Logged)
> - Create @Interceptor class with the binding annotation
> - @AroundInvoke method: receives InvocationContext,
>   calls proceed() to invoke the real method
> - Enable via @Priority (global) or beans.xml
> - Multiple interceptors: applied in @Priority order
>
> Decorators:
>
> - Implement the same interface as the bean to decorate
> - Annotated @Decorator
> - Inject @Delegate for the actual bean instance
> - Override specific methods; delegate the rest
> - Enable via @Priority or beans.xml
>
> Key difference: interceptors don't know the business
> type (InvocationContext is generic). Decorators are typed
> and aware of the business interface.

**Blank Mind Recovery:**

**(1) Restate:** "Interceptors = cross-cutting (logging,
security). Decorators = business extension. Interceptors
generic, decorators typed."

**(2) First principles:** "AOP without bytecode weaving:
interceptors = @Around advice. Decorators = wrapper
pattern on a specific interface."

**(3) Bridge:** "Spring @Aspect/@Around = CDI Interceptor.
Spring has no direct Decorator equivalent."

---

### 📘 Concept Explanation

**What it is:**

CDI Interceptors: reusable cross-cutting concerns
attached to beans via binding annotations. CDI proxy
wraps the bean at deployment - no bytecode weaving.

CDI Decorators: typed wrappers for specific CDI beans.
Extend business behavior by wrapping the interface.

**Interceptor call chain:**

```
Client -> CDI Proxy:
  -> Interceptor1 (@Priority 1000) entry
  -> Interceptor2 (@Priority 1001) entry
  -> Bean method()
  <- Interceptor2 exit
  <- Interceptor1 exit
Client <- result
```

**Decorator call chain:**

```
Client -> Decorator.placeOrder()
          calls @Delegate.placeOrder()
          -> Real Bean.placeOrder()
          <- result
       <- result (possibly modified)
```

**Self-invocation bypass:**

CDI uses proxies. `this.method()` inside a bean bypasses
the CDI proxy - interceptors on that method do not fire.

---

### 💻 Code Example

```java
// 1. Interceptor binding annotation
@Inherited
@InterceptorBinding
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.TYPE, ElementType.METHOD})
public @interface Audited { }

// 2. Interceptor implementation
@Audited
@Interceptor
@Priority(Interceptor.Priority.APPLICATION + 10)
public class AuditInterceptor {

    @Inject AuditService auditService;

    @AroundInvoke
    public Object auditMethodCall(
            InvocationContext ctx) throws Exception {
        String method = ctx.getMethod().getName();
        String clazz = ctx.getTarget()
            .getClass().getSimpleName();
        long start = System.currentTimeMillis();
        Throwable error = null;

        try {
            return ctx.proceed(); // invoke real method
        } catch (Exception e) {
            error = e;
            throw e;
        } finally {
            auditService.record(
                clazz, method,
                System.currentTimeMillis() - start,
                error
            );
        }
    }
}

// 3. Apply to a bean
@Stateless
public class OrderService {

    @Audited  // intercepted by AuditInterceptor
    public Order placeOrder(CreateOrderRequest req) {
        return createOrder(req);
    }

    private Order createOrder(CreateOrderRequest req) {
        return new Order(req);
    }
}

// BAD: inheritance for extension
// CDI proxy of a subclass = double proxying issues
public class LoggingOrderService
        extends DefaultOrderService {
    @Override
    public Order placeOrder(CreateOrderRequest req) {
        log.info("Placing order...");
        return super.placeOrder(req);
    }
}

// GOOD: CDI Decorator
public interface OrderProcessor {
    Order placeOrder(CreateOrderRequest req);
}

@Stateless
public class DefaultOrderProcessor
        implements OrderProcessor {
    @PersistenceContext EntityManager em;

    @Override
    public Order placeOrder(CreateOrderRequest req) {
        Order o = new Order(req);
        em.persist(o);
        return o;
    }
}

@Decorator
@Priority(Interceptor.Priority.APPLICATION)
public class PremiumOrderDecorator
        implements OrderProcessor {

    @Inject @Delegate @Any
    private OrderProcessor delegate;

    @Inject CustomerService customerService;

    @Override
    public Order placeOrder(CreateOrderRequest req) {
        if (customerService.isPremium(
                req.getCustomerId())) {
            req.applyDiscount(0.10);
        }
        Order order = delegate.placeOrder(req);
        if (customerService.isPremium(
                req.getCustomerId())) {
            customerService.addLoyaltyPoints(
                req.getCustomerId(), order.getTotal()
            );
        }
        return order;
    }
}
```

> **Code walkthrough:** AuditInterceptor is pure
> infrastructure: no domain imports, no business logic.
> @AroundInvoke wraps every @Audited method. ctx.proceed()
> invokes the next interceptor or real method. try/finally
> ensures audit records are written even on exception.
> PremiumOrderDecorator is business logic: premium discounts
> and loyalty points extend OrderProcessor without modifying
> DefaultOrderProcessor. @Delegate injects the real
> implementation (or next decorator in the chain).
> The bad pattern shows why inheritance breaks CDI:
> proxies require no-arg constructors and non-final methods.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "CDI Interceptors add behavior around method calls
> using @InterceptorBinding annotations. Mark a method
> with @Logged and an interceptor class wraps it.
> @AroundInvoke gets InvocationContext; call ic.proceed()
> to invoke the real method. CDI Decorators wrap a
> specific interface to extend its business behavior:
> implement the same interface, inject @Delegate for
> the real bean, override specific methods."

---

**Senior / Staff:**

> "The interceptor/decorator distinction matters for
> design: interceptors should have no domain imports.
> If your interceptor contains business if-statements
> about Order or Customer, it's a decorator in disguise.
> CDI proxy model means self-invocation (this.method())
> bypasses interceptors - same issue as Spring @Transactional.
> Fix: extract the method to a separate injected CDI bean.
> Interceptor execution order is @Priority: lower value
> runs outer first on the way in, last on the way out."

---

### ⚠️ Common Misconceptions

**Misconception: "CDI interceptors intercept
self-invocation."**

CDI uses a proxy-based model. Client calls go through
the CDI proxy which applies interceptors. When a bean
calls `this.anotherMethod()`, the call goes directly
to the object, bypassing the proxy. Interceptors on
that method do not fire. Fix: move anotherMethod() to
a separate CDI bean (injected into the current bean).
CDI does not support EJB-style self-injection to work
around this.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Interceptor not executing**

*Symptom:* Logging, metrics, or transaction management
from an interceptor doesn't happen. No error thrown.

*Root causes:*
1. No @Priority and not in beans.xml
2. Self-invocation bypassing proxy
3. @InterceptorBinding not @Inherited
4. Bean is not CDI-managed
5. Method is private, static, or final

*Diagnosis:*
```bash
grep -r "interceptor" src/main/resources/META-INF/beans.xml
grep -r "@Priority" src/main/java/
-Dorg.jboss.cdi.DEBUG=true
```

*Fix:*
```java
// Enable via @Priority (no beans.xml needed):
@Audited @Interceptor
@Priority(Interceptor.Priority.APPLICATION + 10)
public class AuditInterceptor { ... }

// Self-invocation: extract to separate bean
@Inject NotificationService notification;
notification.send(order); // goes through CDI proxy
```

---

### ⚖️ Comparison Table

| Aspect | CDI Interceptor | CDI Decorator | EJB Interceptor |
|--------|----------------|---------------|-----------------|
| Concern type | Infrastructure | Business extension | Infrastructure |
| Type awareness | Generic (InvocationContext) | Typed (implements interface) | Generic |
| Activation | @Priority or beans.xml | @Priority or beans.xml | beans.xml only |
| Self-invocation | Not intercepted | Not intercepted | Not intercepted |
| Interface required | No | Yes | No |

*(System Design: omit - not a ★★★ entry)*

### 📊 Diagram

```
INTERCEPTOR vs DECORATOR CHAINS:

INTERCEPTOR (infrastructure, untyped):
Client -> Proxy -> I1(P:1000) -> I2(P:1001) -> Bean
                             <-             <-
      <- result

DECORATOR (business, typed, same interface):
Client -> Decorator -> @Delegate -> Real Bean
       <-          <-           <-
```

```mermaid
flowchart LR
    Client --> Proxy["CDI Proxy"]
    subgraph IC["Interceptor Chain"]
        I1["@Logged P:1000"]
        I2["@Audited P:1001"]
    end
    Proxy --> I1 --> I2 --> Bean["Bean Method"]
    C2["Client"] --> Dec["Decorator\n(Business Logic)"]
    Dec -->|"@Delegate"| RB["Real Bean"]
```

> **Diagram walkthrough:** Two parallel chains serve
> different purposes. The interceptor chain is infrastructure:
> each interceptor in @Priority order wraps the call,
> each calling ic.proceed(). Interceptors are untyped
> (InvocationContext is generic). The decorator chain is
> business: the decorator implements the same interface
> and explicitly delegates to the real bean via @Delegate.
> Decorators override specific methods with business logic.
> Both are transparent to the client.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| Interceptor vs Decorator differences | 3-4 min |
| @AroundInvoke mechanics | 2-3 min |
| Interceptor execution order | 2-3 min |
| Self-invocation bypass | 3-4 min |
| Activation (beans.xml vs @Priority) | 2-3 min |
| Decorator @Delegate pattern | 3-4 min |
| Lifecycle interceptors @PostConstruct | 2-3 min |
| Interceptor testing | 2-3 min |
| Anti-patterns | 3 min |

---

**[MID] Q1 - What is the difference between
@AroundInvoke and @AroundConstruct?**

*Why they ask:* Interceptor scope knowledge.

@AroundInvoke: wraps method invocations.
@AroundConstruct: wraps bean constructor creation.

```java
@AroundInvoke
public Object timeMethod(InvocationContext ctx)
        throws Exception {
    long start = System.nanoTime();
    try { return ctx.proceed(); }
    finally { record(ctx.getMethod().getName(),
        System.nanoTime() - start); }
}

@AroundConstruct
public Object timeConstruction(InvocationContext ctx)
        throws Exception {
    long start = System.nanoTime();
    try { return ctx.proceed(); }
    finally { record(
        ctx.getConstructor().getDeclaringClass()
            .getName(),
        System.nanoTime() - start); }
}
```

*What separates good from great:* "@AroundConstruct
is useful for diagnosing expensive @ApplicationScoped
bean initialization. Slow startup becomes visible
in construction timing metrics."

---

**[MID] Q2 - How do you control execution order
of multiple interceptors?**

*Why they ask:* Multi-interceptor ordering.

@Priority value: lower = outer (runs first in, last out).

```java
@Logged @Interceptor @Priority(1000)
public class LoggingInterceptor { ... }

@Audited @Interceptor @Priority(1001)
public class AuditInterceptor { ... }

// Chain: Logging(in) -> Audit(in) -> method()
//        method() -> Audit(out) -> Logging(out)
```

*What separates good from great:* "Security interceptors
run outermost (lower priority): fail early, no TX started.
Transaction interceptors run closer to the method."

---

**[MID] Q3 - How do you enable a CDI Decorator?**

*Why they ask:* Decorator configuration.

```java
@Decorator
@Priority(Interceptor.Priority.APPLICATION)
public class ValidationDecorator
        implements OrderProcessor {

    @Inject @Delegate @Any
    private OrderProcessor delegate;

    @Override
    public Order placeOrder(CreateOrderRequest req) {
        if (req.getItems().isEmpty()) {
            throw new IllegalArgumentException(
                "Order must have items"
            );
        }
        return delegate.placeOrder(req);
    }
}
```

*What separates good from great:* "Multiple decorators
stack in @Priority order. Each @Delegate gets the
next decorator or real bean."

---

**[SENIOR] Q4 - How does self-invocation bypass
interceptors and what are the fixes?**

*Why they ask:* CDI proxy limitation.

self-call: `this.method()` bypasses CDI proxy.
Interceptors on that method do not fire.

Fix: extract to separate CDI bean:
```java
@Inject NotificationService notification;
public void processOrder(Order o) {
    em.persist(o);
    notification.send(o); // through CDI proxy - intercepted
}
```

*What separates good from great:* "Most common interceptor
bug. Methods needing their own TX boundary or cross-cutting
behavior belong in separate beans - architecturally correct."

---

**[SENIOR] Q5 - What is @PostConstruct in the
context of CDI interceptors?**

*Why they ask:* Lifecycle interceptor.

@PostConstruct on interceptor: runs before bean's own
@PostConstruct. ctx.proceed() runs bean's @PostConstruct.

```java
@PostConstruct
public void registerBean(InvocationContext ctx)
        throws Exception {
    ctx.proceed(); // run bean's @PostConstruct
    metrics.registerBean(
        ctx.getTarget().getClass().getName()
    );
}
```

*What separates good from great:* "Lifecycle interceptors
are useful for bean registration in metrics and service
discovery frameworks."

---

**[SENIOR] Q6 - How do you test interceptors?**

*Why they ask:* Testing cross-cutting concerns.

Unit test: mock InvocationContext:
```java
@Mock InvocationContext ctx;
when(ctx.getMethod())
    .thenReturn(OrderService.class
        .getMethod("placeOrder",
            CreateOrderRequest.class));
when(ctx.proceed()).thenReturn(new Order());
interceptor.auditMethodCall(ctx);
verify(auditService).record(
    eq("OrderService"), eq("placeOrder"),
    anyLong(), isNull()
);
```

*What separates good from great:* "Integration tests
catch self-invocation bypasses that unit tests miss."

---

**[SENIOR] Q7 - When should you use a CDI Decorator
vs a CDI Interceptor?**

*Why they ask:* Design decision framework.

Interceptor: infrastructure, applies to many types,
no domain knowledge.

Decorator: business logic, typed, extends one contract.

Decision rule:
- Imports Order or Customer? -> Decorator
- Applies to 10+ different types? -> Interceptor
- Contains business if-statements? -> Decorator

*What separates good from great:* "Interceptors with
business logic are decorators in disguise. If removing
the interceptor changes business behavior (not just
infrastructure behavior), it should be a decorator."

---

**[SENIOR] Q8 - How do interceptors interact
with CDI scopes?**

*Why they ask:* Scope + interceptor interaction.

Interceptors are @Dependent: one instance per target
bean. For @ApplicationScoped: one interceptor instance
for app lifetime.

- @ApplicationScoped + interceptor: interceptor state
  persists for app lifetime (AtomicLong accumulates)
- @RequestScoped: interceptor recreated per request

*What separates good from great:* "Interceptor state
lifetime = target bean scope. Useful for per-bean
metrics with @ApplicationScoped beans."

---

**[SENIOR] Q9 - What CDI interceptor anti-patterns
should you avoid?**

*Why they ask:* Common mistake awareness.

Anti-pattern 1: Business logic in interceptor
```java
// BAD: business rule in infrastructure
Order order = (Order) ctx.getParameters()[0];
if (order.getTotal() > 10000) {
    order.requiresApproval = true; // domain logic!
}
// GOOD: use a Decorator
```

Anti-pattern 2: Swallowing exceptions
```java
// BAD:
try { return ctx.proceed(); }
catch (Exception e) { return null; } // hides errors

// GOOD: log and rethrow, or handle specifically
```

Anti-pattern 3: Not calling ctx.proceed() without documentation
(legitimate for circuit breaker/cache patterns, but
must be explicitly documented)

*What separates good from great:* "Cleanest interceptors:
one responsibility, no domain imports, always call
ctx.proceed() unless intentionally bypassing."

---
