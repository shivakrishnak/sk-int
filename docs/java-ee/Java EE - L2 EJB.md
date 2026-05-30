---
layout: default
title: "Java EE - L2 EJB"
parent: "Java EE"
nav_order: 5
permalink: /java-ee/l2-ejb/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 12 | [EJB Types and Lifecycle](#ejb-types-and-lifecycle) | ★★☆ |
| 13 | [EJB Transaction Management](#ejb-transaction-management) | ★★☆ |

---

# EJB Types and Lifecycle

**Interview Weight:** ★★☆ - Working. EJBs underpin
transaction management in Java EE applications.
Every Java EE senior engineer must know the EJB
types, their lifecycle, and when to choose each.

---

### 🎯 Model Answer

**30 seconds:**

> EJB (Enterprise JavaBeans) defines four component types:
> Stateless Session Bean (pooled, no state between calls),
> Stateful Session Bean (per-client conversational state),
> Singleton Session Bean (one instance for the application),
> and Message-Driven Bean (asynchronous JMS consumer).
> The container manages their lifecycle: creation, pooling,
> passivation, activation, and destruction. The primary
> reason to use EJB in modern Jakarta EE is container-managed
> transactions - though @Transactional on CDI beans
> replaces this need in Jakarta EE 10+.

**3 minutes:**

> EJB types and their lifecycle:
>
> **@Stateless Session Bean:**
> - No conversational state between method calls
> - Container maintains a pool (configurable size)
> - Any pool instance handles any client call
> - Lifecycle: Created -> Ready (in pool) -> Destroyed
> - Thread safety: single thread per instance (pool ensures this)
> - Use for: service methods, REST resources, stateless operations
>
> **@Stateful Session Bean:**
> - Maintains state for one specific client across calls
> - One instance per client session
> - Lifecycle: Created -> Active -> Passivated -> Active -> Destroyed
> - Container passivates idle SFSBs to free memory
> - Risk: memory bloat with many concurrent clients
> - Use for: multi-step wizards (legacy pattern)
>
> **@Singleton:**
> - One instance for the entire application
> - Initialized at deploy time if @Startup
> - Container manages concurrency: @Lock(WRITE) or @Lock(READ)
> - Use for: application cache, startup init, shared config
>
> **Message-Driven Bean (MDB):**
> - Asynchronous JMS consumer
> - Stateless; container manages a pool
> - Activated by JMS message arrival
> - Use for: async processing, event handling

**Blank Mind Recovery:**

**(1) Restate:** "Stateless = pooled, no state. Stateful = one
per client, has state. Singleton = one for whole app.
MDB = JMS consumer."

**(2) First principles:** "Enterprise components need different
lifecycle management. Stateless = scale horizontally.
Stateful = conversational. Singleton = global state."

**(3) Bridge:** "Spring equivalents: @Service = Stateless.
No direct Spring equivalent for Stateful. @Singleton
= Spring @Component (singleton by default)."

---

### 📘 Concept Explanation

**What it is:**

EJB is the Jakarta EE component model for enterprise
business logic. The container manages lifecycle,
pooling, transactions, security, and concurrency
based on EJB type and annotations.

**The problem it solves:**

Business components need transaction management,
security enforcement, and lifecycle control without
boilerplate code. EJB provides container-managed
infrastructure via annotations.

**EJB lifecycle states:**

```
STATELESS SESSION BEAN:

  [new] -> [@PostConstruct] -> [POOL]
                                 |
              request -> [BUSY] -> return to POOL
                                 |
          undeploy -> [@PreDestroy] -> [gone]

  Pool: min/max configurable per server
  Thread safety: guaranteed (one thread per instance)

STATEFUL SESSION BEAN:

  Client call -> [CREATE] -> [ACTIVE]
                               |
                   idle -> [PASSIVATED]
                               |
             client call -> [ACTIVE]
                               |
       @Remove or timeout -> [DESTROYED]

SINGLETON SESSION BEAN:

  Deploy -> [@PostConstruct] -> [READY]
                                    |
           all calls -> [READY] (container applies @Lock)
                                    |
           Undeploy -> [@PreDestroy] -> [gone]
```

**Key code patterns:**

```java
// @Stateless: service layer
@Stateless
public class OrderService {
    @PersistenceContext EntityManager em;

    public Order save(Order o) {
        em.persist(o);
        return o; // TX commits at method boundary
    }
}

// @Singleton: application cache
@Singleton
@Startup
@Lock(LockType.READ) // default for read methods
public class ProductCache {
    private Map<Long, Product> cache = new HashMap<>();

    @PostConstruct
    public void load() { /* fill cache on deploy */ }

    @Lock(LockType.WRITE)
    public void refresh() {
        /* exclusive write - readers wait */
    }
}

// @Stateful: multi-step wizard
@Stateful
@StatefulTimeout(value = 15,
    unit = java.util.concurrent.TimeUnit.MINUTES)
public class CheckoutSession {
    private List<Object> items = new ArrayList<>();

    public void addItem(Object item) {
        items.add(item);
    }

    @Remove // container destroys bean after this call
    public Object confirm() {
        return processItems(items);
    }
}
```

---

### 💻 Code Example

```java
// Production patterns for each EJB type

// 1. @Stateless with transaction boundary
@Stateless
public class OrderServiceBean {

    @PersistenceContext
    private EntityManager em;

    @Inject
    private PaymentService paymentService;

    // Default: @TransactionAttribute(REQUIRED)
    // Joins existing TX or starts new one
    public Order placeOrder(CreateOrderRequest req) {
        Order order = new Order();
        order.setCustomerId(req.getCustomerId());
        order.setTotal(req.getTotal());
        em.persist(order);

        // paymentService also @Stateless - joins this TX
        paymentService.charge(order);

        return order;
        // Container commits here if no exception
    }
}

// 2. @Singleton with @Startup initialization
@Singleton
@Startup
public class ConfigCache {
    private Map<String, String> config;

    @Inject
    private ConfigRepository configRepo;

    @PostConstruct // runs once at deploy
    public void initialize() {
        config = configRepo.loadAll()
            .stream()
            .collect(Collectors.toMap(
                Config::getKey,
                Config::getValue
            ));
    }

    @Lock(LockType.READ)
    public String get(String key) {
        return config.getOrDefault(key, "");
    }

    @Lock(LockType.WRITE)
    public void reload() {
        config = configRepo.loadAll()
            .stream()
            .collect(Collectors.toMap(
                Config::getKey,
                Config::getValue
            ));
    }
}

// 3. MDB: async JMS processing
@MessageDriven(activationConfig = {
    @ActivationConfigProperty(
        propertyName = "destinationType",
        propertyValue = "jakarta.jms.Queue"
    ),
    @ActivationConfigProperty(
        propertyName = "destination",
        propertyValue = "java:/jms/queue/order-events"
    ),
    @ActivationConfigProperty(
        propertyName = "maxSession",
        propertyValue = "10"  // 10 concurrent consumers
    )
})
public class OrderEventMdb
        implements jakarta.jms.MessageListener {

    @Inject
    private NotificationService notificationService;

    @Override
    public void onMessage(jakarta.jms.Message message) {
        try {
            String orderId =
                ((jakarta.jms.TextMessage) message)
                .getText();
            notificationService.sendOrderConfirmation(
                Long.parseLong(orderId)
            );
        } catch (Exception e) {
            // RuntimeException -> rollback -> retry
            throw new RuntimeException(
                "Failed to process order event", e
            );
        }
    }
}
```

> **Code walkthrough:** Three EJB types in production
> patterns. `OrderServiceBean` is `@Stateless` - pooled,
> transactional. The `paymentService.charge(order)`
> call joins the same transaction because both are REQUIRED
> (default). If charge() throws RuntimeException, the
> entire transaction including `em.persist(order)` rolls
> back. `ConfigCache` is `@Singleton @Startup`: the
> `@PostConstruct` runs at deployment, not on first request.
> `@Lock(READ)` allows concurrent reads; `@Lock(WRITE)`
> blocks all readers and writers until reload() completes.
> Without `@Lock`, concurrent calls to HashMap.put()
> inside reload() cause data corruption (HashMap is not
> thread-safe). The MDB shows the retry contract:
> throwing RuntimeException from `onMessage()` causes
> the JMS transaction to roll back, redelivering the message.
> Swallow exceptions (catch without rethrow) only for
> non-retryable business errors; rethrow for infrastructure
> failures where a retry might succeed.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "@Stateless is pooled - no state between calls. Best
> for service layer. @Stateful keeps state per client
> for multi-step workflows. @Singleton has one instance
> for the whole app - use it for caches and startup
> initialization. MDB listens to JMS queues asynchronously.
> The container manages lifecycle, transactions, and
> security for all EJB types."

---

**Senior / Staff:**

> "In modern Jakarta EE 10+, I avoid EJB unless I
> specifically need @Singleton with @Lock for concurrent
> cache access, @Schedule for timer tasks, or @MessageDriven
> for JMS. For everything else, CDI beans with @Transactional
> provide equivalent transaction management without EJB
> overhead. The EJB I still see most in legacy code is
> @Stateful - frequently the wrong choice because it
> creates sticky session requirements in a cluster. The
> modern pattern: replace @Stateful with a stateless
> service + client-side state in the request body or
> a database draft record."

---

### ⚠️ Common Misconceptions

**Misconception: "@Stateless beans are created fresh
for each request."**

`@Stateless` beans are pooled. The container maintains
a pool of pre-created instances and reuses them across
requests. A method call picks an available instance
from the pool; after the call, the instance returns
to the pool. The container may create new instances
if the pool is exhausted. "Stateless" means the instance
has no state that carries over from one method call
to the next - not that a new instance is created each
time. Instance variables must be treated as uninitialized
between calls: the instance could have been used by
any previous request.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Stateful Session Bean memory leak in production**

*Symptom:* Server memory grows until OutOfMemoryError.
Heap dump shows large numbers of @Stateful bean instances.

*Root cause:*
1. Clients start a stateful session but never call @Remove.
2. @StatefulTimeout not configured.
3. High traffic creates thousands of abandoned sessions.

*Diagnosis:*
```bash
# WildFly CLI: check stateful bean count
/subsystem=ejb3:read-resource(recursive=true)

# Heap dump analysis
jmap -dump:live,format=b,file=heap.hprof <pid>
# Analyze with Eclipse MAT: look for CheckoutSession count
```

*Fix:*
```java
// Always add timeout to @Stateful beans
@Stateful
@StatefulTimeout(
    value = 15,
    unit = java.util.concurrent.TimeUnit.MINUTES
)
public class CheckoutSession { ... }
```

Consider replacing @Stateful with a database draft
record pattern: persist partial state as a draft entity;
any server can resume the workflow without sticky sessions.

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| EJB type comparison | 3-4 min |
| @Stateless pool behavior | 2-3 min |
| @Stateful lifecycle and @Remove | 3 min |
| @Singleton concurrency control | 3-4 min |
| MDB and retry behavior | 2-3 min |
| EJB vs CDI in Jakarta EE 10+ | 3-4 min |
| @Stateful memory leak diagnosis | 3 min |
| @Schedule timers | 2-3 min |
| @Asynchronous EJB method | 2-3 min |

---

**[MID] Q1 - When would you use a @Stateful Session
Bean versus client-side state?**

*Why they ask:* Modern EJB relevance assessment.

Modern alternatives to @Stateful:
- JWT payload: embed current wizard state in the token
- Request body: client sends accumulated state each call
- Database draft record: persist partial state as a draft

@Stateful is still valid when:
- Complex in-memory state too large for JWT/cookie
- Existing legacy applications (migration cost)
- Container features like bean-managed cross-call transactions

Real cost of @Stateful:
- Sticky sessions in a cluster (or full replication)
- Cloud auto-scaling adds instances without existing beans
- Memory: each active client holds one bean instance

*What separates good from great:* "I'd replace @Stateful with a draft order pattern: persist partial state to the database with a DRAFT status. Any server in the cluster can resume the wizard. A background job deletes stale drafts. No sticky sessions, cloud-native, debuggable in SQL."

---

**[MID] Q2 - How does @Lock work in @Singleton beans?**

*Why they ask:* Concurrent access control.

`@Singleton` has one instance shared by all threads.
Without concurrency control, concurrent method calls
can corrupt state (HashMap is not thread-safe).

`@Lock` declares concurrency semantics:
```java
@Singleton
public class ProductCache {

    private Map<Long, Product> cache = new HashMap<>();

    // Multiple threads can read concurrently
    @Lock(LockType.READ)
    public Product get(Long id) {
        return cache.get(id);
    }

    // Exclusive access: all readers and writers wait
    @Lock(LockType.WRITE)
    public void put(Long id, Product p) {
        cache.put(id, p);
    }

    // Class-level default: all methods are READ
    // unless overridden
}
```

Container implements READ/WRITE with a read-write lock
internally. Multiple `@Lock(READ)` calls proceed
concurrently; a `@Lock(WRITE)` call waits for all
readers to finish, then acquires exclusive access.

Access timeout: if the lock can't be acquired:
```java
@Lock(LockType.WRITE)
@AccessTimeout(value = 5000) // ms
public void refresh() { ... }
// Throws ConcurrentAccessTimeoutException after 5 seconds
```

*What separates good from great:* "The default concurrency management for @Singleton is CONTAINER (the container manages @Lock). You can also use @ConcurrencyManagement(BEAN) to manage your own synchronization with synchronized blocks. Bean-managed concurrency is only appropriate when the container's lock granularity doesn't match your needs."

---

**[MID] Q3 - How does the MDB retry mechanism work?**

*Why they ask:* Async error handling pattern.

When `onMessage()` throws a RuntimeException:
1. JMS transaction is rolled back
2. Message is redelivered (up to max redelivery attempts)
3. After max attempts: message moves to Dead Letter Queue (DLQ)

```java
@Override
public void onMessage(Message message) {
    try {
        processOrderEvent(message);
    } catch (BusinessException e) {
        // Anticipated failure: swallow, consume message
        // Message is NOT requeued
        log.warn("Business error: " + e.getMessage());
    } catch (InfrastructureException e) {
        // Transient failure: rethrow to trigger retry
        throw new RuntimeException(
            "Transient failure", e
        );
    }
}
```

Configure redelivery (WildFly):
```xml
<address-setting match="jms.queue.order-events">
  <dead-letter-address>
    jms.queue.DLQ
  </dead-letter-address>
  <max-delivery-attempts>3</max-delivery-attempts>
</address-setting>
```

Monitor DLQ: messages that can't be processed after
retries land there. Operations must have a process
to review and reprocess DLQ messages.

*What separates good from great:* "Poison messages - messages that always fail (bad data format, missing required field) - loop through all retries and end in the DLQ. This costs time and resources. Validate message format immediately on receipt: if it's clearly invalid data, log and consume it (don't retry). Only retry transient infrastructure failures."

---

**[MID] Q4 - What is @Asynchronous on an EJB method?**

*Why they ask:* EJB async feature.

`@Asynchronous` makes an EJB method execute in a
separate container-managed thread:
```java
@Stateless
public class NotificationService {

    @Asynchronous
    public void sendEmailAsync(String to, String body) {
        // Runs in container thread pool, not caller's thread
        emailGateway.send(to, body);
        // Caller returns immediately
    }

    @Asynchronous
    public Future<Report> generateReport(String type) {
        Report report = buildReport(type); // takes time
        return new AsyncResult<>(report);
    }
}

// Caller:
@Inject
private NotificationService notificationService;

public void placeOrder(Order order) {
    // Fire and forget - does not wait for email
    notificationService.sendEmailAsync(
        order.getCustomerEmail(),
        "Order confirmed: " + order.getId()
    );
}
```

Critical: `@Asynchronous` starts a NEW transaction context.
It does NOT inherit the caller's transaction.

*What separates good from great:* "@Asynchronous doesn't inherit the caller's transaction - this is the most common bug. The caller persists an order, fires an async notification that needs to read that order. The async method starts a new transaction; the order isn't committed yet (outer TX still open), so the read returns null."

---

**[MID] Q5 - How do you schedule tasks with @Schedule?**

*Why they ask:* EJB timer service.

`@Schedule` creates a cron-like timer on a `@Singleton`
or `@Stateless` EJB:
```java
@Singleton  // Not @Stateless - avoids multiple instances
public class ReportScheduler {

    @Inject
    private ReportService reportService;

    // Every day at 2:00 AM
    @Schedule(hour = "2", minute = "0", second = "0",
              persistent = false)
    public void generateDailyReport() {
        reportService.generateDailyReport();
    }

    // Every 5 minutes
    @Schedule(minute = "*/5", hour = "*",
              persistent = false)
    public void checkStaleOrders() {
        orderService.timeoutStaleOrders();
    }
}
```

`persistent = true` (default): timer stored in DB,
survives restart. `persistent = false`: recreated
from @Schedule on each deploy; lost if server crashes
between fires.

Use `@Singleton` for scheduled tasks: a `@Stateless`
pool creates one timer per pool instance (multiple firings).

*What separates good from great:* "@Schedule in a @Stateless EJB is a bug: each bean in the pool creates its own timer. With pool size 5, the job fires 5 times per interval. Always put @Schedule in a @Singleton."

---

**[MID] Q6 - What is EJB passivation?**

*Why they ask:* @Stateful bean lifecycle.

Passivation: container serializes @Stateful bean state
to persistent storage and removes it from memory.
Activation: restoring the state.

When it happens:
- SFSB cache is full (memory pressure)
- Bean idle for configured period
- Before cluster failover

Requirements:
- Bean implements `Serializable`
- All instance fields serializable
- Mark non-serializable fields `transient`

Callbacks:
```java
@Stateful
public class CheckoutSession implements Serializable {
    private transient Connection dbConn; // non-serializable

    @PrePassivate
    public void onPassivate() {
        // Close non-serializable resources
        closeQuietly(dbConn);
        dbConn = null;
    }

    @PostActivate
    public void onActivate() {
        // Reinitialize after deserialization
        dbConn = dataSource.getConnection();
    }
}
```

*What separates good from great:* "Passivation failure (non-serializable field) causes the container to throw an EJBException and lose the client's session. The symptom in production: random ConversationExpiredException or session errors for a subset of users. Check for @Stateful beans that hold EntityManager, Connection, or Socket references without marking them transient."

---

**[SENIOR] Q7 - What replaced EJB in modern
Jakarta EE and Spring Boot?**

*Why they ask:* Architecture evolution.

| EJB Feature | Jakarta EE 10+ | Spring Boot |
|---|---|---|
| CMT Transactions | @Transactional (CDI) | @Transactional |
| @Stateless pooling | @ApplicationScoped | @Service (singleton) |
| @Asynchronous | ManagedExecutorService | @Async |
| @Schedule | @Schedule (EJB still) | @Scheduled |
| Remote EJB | REST / gRPC | REST / gRPC |
| @MessageDriven | JMS MessageListener | @JmsListener |
| @RolesAllowed | @RolesAllowed + CDI | @PreAuthorize |

Minimal migration from EJB to CDI:
```java
// Before (EJB):
@Stateless
public class OrderService {
    @PersistenceContext EntityManager em;
    public void save(Order o) { em.persist(o); }
}

// After (CDI + @Transactional):
@ApplicationScoped
@Transactional
public class OrderService {
    @PersistenceContext EntityManager em;
    public void save(Order o) { em.persist(o); }
}

// Also replace:
// @EJB -> @Inject
// @TransactionAttribute -> @Transactional(TxType.*)
```

*What separates good from great:* "CDI @Transactional in Jakarta EE 10+ is implemented by a CDI interceptor - the same mechanism as Spring @Transactional. The main remaining EJB use case: @Singleton with @Lock - CDI ApplicationScoped beans don't have built-in read/write lock semantics."

---

**[SENIOR] Q8 - How does EJB pooling work and
what are its performance implications?**

*Why they ask:* Production tuning.

The container maintains a pool of @Stateless EJB instances.
Call arrives: take from pool. Call completes: return
to pool. Pool exhausted: wait up to timeout.

WildFly pool configuration:
```xml
<strict-max-pool
  name="slsb-strict-max-pool"
  max-pool-size="20"
  instance-acquisition-timeout="5"
  instance-acquisition-timeout-unit="MINUTES"/>
```

Monitoring (WildFly CLI):
```bash
/subsystem=ejb3/stateless-session-bean=OrderService\
:read-attribute(name=pool-current-size)
/subsystem=ejb3/stateless-session-bean=OrderService\
:read-attribute(name=pool-available-count)
```

Implications:
- Pool exhaustion: callers wait up to `instance-acquisition-timeout`
- Pool as backpressure: prevents overload but causes latency spikes
- @PostConstruct: runs once per pool instance, not per request
- Instance variables: may have stale state from previous call
  (treat as uninitialized on every method entry)

*What separates good from great:* "Pool size tuning: match to the database connection pool. If the DB pool is 20, an EJB pool of 200 still creates only 20 concurrent DB operations. The EJB pool should be >= DB pool to avoid EJB pool exhaustion when DB pool is the bottleneck."

---

**[SENIOR] Q9 - How do you diagnose @Stateful
bean memory leaks?**

*Why they ask:* Production memory management.

Symptoms: heap grows over time, OutOfMemoryError
under sustained load.

Diagnosis:
```bash
# 1. Heap dump
jmap -dump:live,format=b,file=heap.hprof <pid>

# 2. Eclipse MAT: check for large SFSB counts
# "List Objects" -> search for @Stateful class name

# 3. WildFly: check SFSB count via management API
curl -X POST http://admin:pass@localhost:9990/management \
  -H "Content-Type: application/json" \
  -d '{"operation":"read-resource",
       "address":["subsystem","ejb3"]}'

# 4. Enable SFSB debug logging
# Add to standalone.xml:
# <logger category="org.jboss.ejb.client">
#   <level name="DEBUG"/>
# </logger>
```

Fix options:
1. Add `@StatefulTimeout`: leaked sessions expire
2. Always call `@Remove` method when done
3. Replace @Stateful with database draft record pattern:
   ```java
   // Instead of @Stateful bean:
   public class OrderDraft {
       @Id Long id;
       String status = "DRAFT";
       @Lob String stateJson; // serialized wizard state
       Instant lastUpdated;
   }
   // Background job deletes stale drafts:
   DELETE FROM order_draft
   WHERE status = 'DRAFT'
   AND last_updated < NOW() - INTERVAL '30 minutes'
   ```

*What separates good from great:* "The database draft pattern has another advantage: it survives server restarts and cluster failures. The @Stateful bean survives neither (unless you configure full session replication, which is expensive)."

---

---

# EJB Transaction Management

**Interview Weight:** ★★☆ - Working. Transaction management
is why many Java EE applications chose EJB. Understanding
transaction propagation, isolation, and rollback rules
is critical for every senior Java EE interview.

---

### 🎯 Model Answer

**30 seconds:**

> EJB container-managed transactions (CMT) use
> @TransactionAttribute to declare how each method
> participates in transactions. The default is REQUIRED:
> join existing transaction; start new if none exists.
> The container automatically commits on normal return
> or rolls back on unchecked exception. Checked exceptions
> do NOT automatically trigger rollback - that is the
> most common bug. For manual control, use BMT with
> injected UserTransaction.

**3 minutes:**

> CMT transaction attributes:
> - REQUIRED (default): join existing or start new
> - REQUIRES_NEW: suspend existing, start new (independent TX)
> - MANDATORY: must have existing TX; throws if none
> - NEVER: must NOT be in TX; throws if one exists
> - SUPPORTS: join if exists; no TX if none
> - NOT_SUPPORTED: suspend any TX for this call
>
> Rollback rules (critical):
> - Unchecked (RuntimeException, Error): automatic rollback
> - Checked exception: NO automatic rollback by default!
> - Fix: @ApplicationException(rollback=true) on checked exceptions
> - Manual flag: sessionContext.setRollbackOnly()
>
> BMT: use @TransactionManagement(BEAN) + inject UserTransaction.
> Useful for batch processing (one TX per record, not per batch).

**Blank Mind Recovery:**

**(1) Restate:** "REQUIRED = default, join or start. REQUIRES_NEW
= always new, suspends existing. Unchecked = rollback.
Checked = NO rollback (danger!)."

**(2) First principles:** "Transaction = atomic unit. CMT
declares the boundary. RuntimeException = something broke.
Checked = anticipated, maybe partial success is OK."

**(3) Bridge:** "Same as Spring @Transactional(propagation=REQUIRED).
Spring also rolls back only on RuntimeException by default."

---

### 📘 Concept Explanation

**What it is:**

EJB CMT is a declarative transaction management system.
The container wraps EJB method calls in transaction
boundaries, handling begin/commit/rollback automatically
based on @TransactionAttribute.

**The problem it solves:**

Manual JDBC transaction management: begin()/commit()/rollback()
duplicated across every service method. CMT: annotate
the method, the container handles the lifecycle.

**TransactionAttributeType behavior:**

```
Attribute      Has TX?  Result
-------------- -------- ---------------------------
REQUIRED       No       New TX started
               Yes      Joins existing TX
REQUIRES_NEW   No       New TX started
               Yes      Existing suspended, new TX
MANDATORY      No       EJBTransactionRequiredException
               Yes      Joins existing TX
NEVER          No       No TX (runs without TX)
               Yes      EJBException thrown
SUPPORTS       No       Runs without TX
               Yes      Joins existing TX
NOT_SUPPORTED  No       Runs without TX
               Yes      Existing suspended, no TX

"Has TX?" = is there an active transaction at the call site?
```

**Rollback rules:**

```java
@Stateless
public class PaymentService {

    // BAD: checked exception does NOT roll back
    public void charge(Payment p)
            throws ChargeFailedException {
        em.persist(p);  // persisted
        throw new ChargeFailedException("Declined");
        // Transaction COMMITS! Payment record saved!
        // The exception propagates but TX is committed.
    }

    // GOOD: annotate checked exception
    @ApplicationException(rollback = true)
    public static class ChargeFailedException
            extends Exception {
        ChargeFailedException(String msg) { super(msg); }
    }
    // Now: throw new ChargeFailedException -> ROLLBACK

    // GOOD: force rollback explicitly
    @Resource
    private SessionContext ctx;

    public void chargeWithRollback(Payment p)
            throws ChargeFailedException {
        em.persist(p);
        ctx.setRollbackOnly(); // mark for rollback
        throw new ChargeFailedException("Declined");
        // TX will roll back when method returns
    }
}
```

---

### 💻 Code Example

```java
// Production transaction pattern: order placement

@Stateless
public class OrderService {

    @PersistenceContext
    private EntityManager em;

    @Inject
    private InventoryService inventoryService;

    @Inject
    private AuditService auditService;

    @Resource
    private SessionContext sessionContext;

    // REQUIRED (default): join caller TX or start new
    public Order placeOrder(CreateOrderRequest req)
            throws OrderException {
        // 1. Reserve inventory (joins this TX)
        inventoryService.reserve(req.getItems());

        // 2. Create order
        Order order = new Order(req);
        em.persist(order);

        // 3. Audit in INDEPENDENT transaction
        // Even if main TX later rolls back,
        // audit record is preserved
        auditService.logAttempt(order);

        return order;
        // Container commits here if no exception
    }

    // BMT for batch: each record is independent TX
    // (see BatchOrderProcessor below)
}

@Stateless
public class InventoryService {
    @PersistenceContext EntityManager em;

    // Default REQUIRED: joins caller's TX
    // If this throws, caller's TX rolls back too
    public void reserve(List<OrderItem> items)
            throws InsufficientStockException {
        for (OrderItem item : items) {
            Product p = em.find(
                Product.class, item.getProductId()
            );
            if (p.getStock() < item.getQuantity()) {
                throw new InsufficientStockException(
                    "Insufficient stock for product "
                    + item.getProductId()
                );
            }
            p.setStock(p.getStock() - item.getQuantity());
        }
    }
}

@Stateless
public class AuditService {
    @PersistenceContext EntityManager em;

    // REQUIRES_NEW: always independent TX
    // Audit persists regardless of outer TX outcome
    @TransactionAttribute(
        TransactionAttributeType.REQUIRES_NEW
    )
    public void logAttempt(Order order) {
        AuditLog log = new AuditLog();
        log.setAction("ORDER_PLACE");
        log.setOrderId(order.getId());
        log.setTimestamp(java.time.Instant.now());
        em.persist(log);
        // Commits independently when this method returns
    }
}

// BMT batch processor: one TX per record
@Stateless
@TransactionManagement(
    TransactionManagementType.BEAN
)
public class BatchOrderProcessor {

    @Resource
    private UserTransaction utx;

    @PersistenceContext
    private EntityManager em;

    public BatchResult processBatch(
            List<OrderRequest> requests) {
        int success = 0, failed = 0;

        for (OrderRequest req : requests) {
            try {
                utx.begin();
                Order order = new Order(req);
                em.persist(order);
                utx.commit();
                success++;
            } catch (Exception e) {
                rollbackQuietly();
                failed++;
                // Continue: one failure doesn't stop batch
            }
        }
        return new BatchResult(success, failed);
    }

    private void rollbackQuietly() {
        try {
            utx.rollback();
        } catch (Exception ignored) {}
    }
}
```

> **Code walkthrough:** Four components showing transaction
> propagation in a real order flow. `OrderService.placeOrder`
> uses REQUIRED (default): it creates a transaction and
> both `inventoryService.reserve()` and `em.persist(order)`
> join that same transaction. If reserve() throws
> `InsufficientStockException` (a checked exception),
> there is NO automatic rollback - the order record that
> was already persisted would commit! The fix: annotate
> `InsufficientStockException` with `@ApplicationException(rollback=true)`.
> `AuditService.logAttempt()` uses `REQUIRES_NEW`: it
> suspends the outer transaction and commits the audit
> log independently. The `BatchOrderProcessor` uses BMT
> (Bean-Managed Transactions): `utx.begin()` / `utx.commit()`
> are explicit. Each record is its own transaction;
> failure of one record doesn't affect others - the
> pattern for batch jobs where partial success is acceptable.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> "CMT uses @TransactionAttribute to control transaction
> behavior. REQUIRED (default) joins existing TX or starts
> new. REQUIRES_NEW always starts a new independent TX.
> Unchecked exceptions cause rollback; checked exceptions
> do NOT by default. Mark checked exceptions with
> @ApplicationException(rollback=true) or use
> setRollbackOnly() to force rollback."

---

**Senior / Staff:**

> "The checked exception / no-rollback behavior is the
> most dangerous EJB default. A service that throws a
> checked exception for business failure (InsufficientFundsException)
> commits partial state by default. In legacy Java EE
> codebases, I've seen payments recorded but orders not
> created because of this. The safe rule: every domain
> exception that represents a failure should be annotated
> @ApplicationException(rollback=true). Also, REQUIRES_NEW
> with access to the same rows as the outer TX is a
> deadlock waiting to happen: the outer TX has a lock,
> the inner TX waits for the lock, and the outer TX
> is waiting for the inner TX to complete."

---

### ⚠️ Common Misconceptions

**Misconception: "Any exception from an EJB method
causes rollback."**

Only unchecked exceptions (RuntimeException subclasses
and Error) trigger automatic rollback in CMT. Checked
exceptions do NOT - the transaction commits despite
the exception. This is one of the most dangerous
defaults in Java EE and causes data integrity bugs
in production. The safe practices: (1) use only
RuntimeException for all conditions that should roll
back, (2) annotate checked business exceptions with
`@ApplicationException(rollback=true)`, or (3) call
`sessionContext.setRollbackOnly()` before throwing.
Spring @Transactional has the same behavior by default:
only RuntimeException triggers rollback; use `rollbackFor`
attribute to override.

---

### 🚨 Failure Modes and Diagnosis

**Failure: RollbackException at TX commit despite
caught exception**

*Symptom:* `jakarta.transaction.RollbackException:
ARJUNA016053: Could not commit transaction. It has
been rolled back.` - but the application caught all exceptions.

*Root cause:* A nested EJB method threw RuntimeException,
which marked the transaction `rollback-only`. The outer
code caught the exception - but catching an exception
does not un-mark a rollback-only transaction. When the
outer method tries to commit, the container sees the
rollback-only flag and throws RollbackException.

*Diagnosis:*
```bash
# WildFly: enable transaction manager logging
grep "setRollbackOnly\|rollback-only\|RollbackException" \
  standalone/log/server.log

# Look for the original exception that triggered rollback:
# It often appears BEFORE the RollbackException in the log
```

*Fix:*
```java
// Pattern 1: Don't use REQUIRED if you want to catch
// and continue. Use REQUIRES_NEW to isolate.

// Pattern 2: If you need to catch and handle a failure
// without rolling back the outer TX, the sub-call must
// be in its own REQUIRES_NEW transaction:
@TransactionAttribute(TransactionAttributeType.REQUIRES_NEW)
public void tryOptionalOperation() {
    // If this throws, only THIS TX rolls back
    // Outer TX is unaffected
}
```

---

### 🎯 Interview Deep-Dive

| Question Type | Est. Time |
|---|---|
| TransactionAttribute types | 3-4 min |
| Checked exception rollback rule | 3-4 min |
| REQUIRES_NEW use cases and risks | 3-4 min |
| CMT vs BMT | 2-3 min |
| setRollbackOnly behavior | 2-3 min |
| JTA multi-resource transactions | 3 min |
| Transaction propagation debugging | 3 min |
| @ApplicationException(rollback) | 2 min |
| Transaction timeout configuration | 2-3 min |

---

**[MID] Q1 - What happens when a checked exception
escapes an EJB method?**

*Why they ask:* Rollback rule knowledge.

By default: transaction COMMITS. The exception propagates
to the caller but the database changes in the transaction
are committed.

This is intentional by design: checked exceptions
represent anticipated failures. "Declining a credit
card" is a known business outcome, not a system failure.
The data written before the exception may be valid
partial state.

However, for most real applications this default is
dangerous:

```java
// DANGEROUS default:
public void createOrder(Order o) throws InsufficientStockException {
    em.persist(o);              // persisted
    inventory.reserve(o);      // throws InsufficientStockException
    // TX COMMITS: order is saved, inventory not reserved!
}

// SAFE: annotate the exception
@ApplicationException(rollback = true)
public class InsufficientStockException extends Exception {}
// Now: throw -> ROLLBACK

// SAFE: convert to RuntimeException
public void createOrder(Order o) {
    try {
        inventory.reserve(o);
    } catch (InsufficientStockException e) {
        throw new IllegalStateException(
            "Insufficient stock", e
        ); // RuntimeException -> rollback
    }
}
```

*What separates good from great:* "I audit all checked exceptions in EJB service layers. Any checked exception thrown at a transaction boundary should either: (1) be annotated @ApplicationException(rollback=true) if it represents a failure, or (2) explicitly not roll back if partial state is valid. Never rely on the default without thinking about it."

---

**[MID] Q2 - When should you use REQUIRES_NEW?**

*Why they ask:* Transaction isolation use cases.

REQUIRES_NEW starts a completely independent transaction:
1. Suspends the caller's transaction
2. New transaction starts, executes, commits/rolls back
3. Caller's transaction resumes

Valid use cases:
- Audit logging: audit must persist even if main TX fails
- Error logging: log the failure in its own TX
- Independent operations that should commit regardless
- Calls where you want the caller to continue if the inner call fails

```java
// CORRECT: audit persists even if outer TX rolls back
@TransactionAttribute(REQUIRES_NEW)
public void logAudit(AuditEntry entry) {
    em.persist(entry);
    // Commits independently
}

// INCORRECT: used just to avoid joining the outer TX
// This means a 1000-item loop creates 1000 transactions
@TransactionAttribute(REQUIRES_NEW)
public void processItem(Item item) { ... }
// Creates 1000 transactions instead of 1 - very slow
```

Deadlock risk with REQUIRES_NEW:
- Outer TX locks row R
- REQUIRES_NEW sub-call tries to read/update row R
- Sub-call waits for the lock
- Outer TX waits for sub-call to complete
- DEADLOCK

*What separates good from great:* "REQUIRES_NEW is appropriate for cross-cutting concerns that need their own commit lifecycle (audit, error logs). Using REQUIRES_NEW for performance isolation (wanting the sub-call to not interfere with outer TX) is usually a design problem. If you need isolation, design the operations to not share data."

---

**[MID] Q3 - How do you use UserTransaction in BMT?**

*Why they ask:* BMT knowledge.

BMT: `@TransactionManagement(TransactionManagementType.BEAN)` on the class.
Inject `UserTransaction` via `@Resource`:

```java
@Stateless
@TransactionManagement(TransactionManagementType.BEAN)
public class ManualTxService {

    @Resource
    private UserTransaction utx;

    @PersistenceContext
    private EntityManager em;

    public void processWithManualTx(List<Item> items)
            throws Exception {
        utx.begin();
        try {
            for (Item item : items) {
                em.persist(item);
            }
            utx.commit();
        } catch (Exception e) {
            try {
                utx.rollback();
            } catch (Exception rollbackEx) {
                // Log rollback failure but propagate original
                log.error("Rollback failed", rollbackEx);
            }
            throw e;
        }
    }
}
```

Rules for BMT:
- Transaction MUST be committed or rolled back before method returns
- Container throws EJBException if method returns with open TX
- Cannot use @TransactionAttribute (ignored in BMT)

*What separates good from great:* "BMT is more error-prone than CMT: you must handle every exception path and ensure the transaction is always ended. A try/catch that misses one exception path leaves an open transaction that the container closes with an EJBException. Use BMT only when CMT cannot express what you need."

---

**[SENIOR] Q4 - How do you debug a transaction
that commits when you expect a rollback?**

*Why they ask:* Production debugging.

The commit-when-expecting-rollback scenario almost
always has one root cause: a checked exception.

Debugging steps:
1. Confirm which exception was thrown:
   ```java
   // Add logging at the top of the CMT method
   try {
       doWork();
   } catch (Exception e) {
       log.error("Exception type: " +
           e.getClass().getName());
       // Is it checked or unchecked?
       log.error("Is RuntimeException: " +
           (e instanceof RuntimeException));
       throw e;
   }
   ```

2. Check @ApplicationException on the exception class:
   ```bash
   grep -r "@ApplicationException" src/
   # No result for the failing exception class?
   # That's the bug: it's a checked exception with no rollback rule
   ```

3. Verify @TransactionAttribute on the method:
   ```bash
   grep -A5 "public void failingMethod" src/**/*.java
   # Is it REQUIRED? SUPPORTS? NOT_SUPPORTED?
   ```

4. Check SessionContext.setRollbackOnly() calls:
   ```bash
   grep -r "setRollbackOnly" src/
   # Is it called in the failure path?
   ```

*What separates good from great:* "The diagnostic shortcut: check the exception class hierarchy. If the exception you're throwing extends Exception (not RuntimeException), you have a checked exception and you need @ApplicationException(rollback=true) on it."

---

**[SENIOR] Q5 - What is JTA and how does it
extend beyond a single database?**

*Why they ask:* Distributed transaction understanding.

JTA (Jakarta Transaction API) extends transaction
management to multiple XA resources:
- Two databases simultaneously
- Database + JMS message queue atomically
- Database + JCA connector

XA Protocol (2PC):
1. Phase 1 (Prepare): TM asks all resources to prepare
   (write to redo log, vote commit or abort)
2. Phase 2 (Commit): All voted yes = commit all;
   Any voted no = rollback all

```java
@Stateless
public class OrderWithNotificationService {

    @PersistenceContext  // XA EntityManager
    private EntityManager em;

    @Inject
    @JMSConnectionFactory("java:/JmsXA")  // XA JMS
    private JMSContext jmsCtx;

    @TransactionAttribute(REQUIRED)
    public void placeOrder(Order order) {
        em.persist(order);           // DB write in JTA TX
        jmsCtx.createProducer()
            .send(orderConfirmQueue, // JMS in SAME TX
                order.getId().toString());
        // Both commit atomically via 2PC
        // If JMS fails: DB also rolls back
    }
}
```

Cost of JTA 2PC:
- Multiple round trips to all resources
- Holding locks during 2PC (blocking other transactions)
- Recovery process for crashed participants

*What separates good from great:* "For new systems I avoid distributed JTA transactions. The Outbox Pattern: persist the order AND a pending notification in one local database transaction. A separate process reads pending notifications and sends to JMS. One resource, one transaction, no 2PC. If the notification process fails, it retries independently."

---

**[SENIOR] Q6 - How does transaction propagation
interact with EJB exception handling?**

*Why they ask:* Advanced propagation edge cases.

The rollback-only flag propagation:

When B throws RuntimeException into A:
```java
@Stateless
public class ServiceA {
    @Inject ServiceB b;

    public void methodA() {
        try {
            b.methodB(); // throws RuntimeException
        } catch (RuntimeException e) {
            // Transaction is ALREADY marked rollback-only here
            // Catching the exception does NOT clear the flag
            log.error("B failed, continuing...");
            // But when methodA returns, commit fails!
            // Container throws RollbackException
        }
    }
}

@Stateless
public class ServiceB {
    public void methodB() {
        throw new RuntimeException("Error in B");
        // Marks the SHARED transaction as rollback-only
    }
}
```

The fix: use REQUIRES_NEW for B if you want A to
continue despite B's failure:
```java
@TransactionAttribute(REQUIRES_NEW)
public void methodB() {
    throw new RuntimeException("Error in B");
    // ONLY the REQUIRES_NEW TX rolls back
    // A's TX is unaffected
}
```

*What separates good from great:* "This is the most confusing transaction bug in Java EE: you catch the exception, the code looks correct, but you get RollbackException on commit. The key insight: catching an exception does not undo the rollback-only flag. REQUIRES_NEW is the only way to isolate B's failures from A's transaction."

---

**[SENIOR] Q7 - How do you configure transaction
timeout per method?**

*Why they ask:* Production transaction management.

Standard EJB has no per-method timeout annotation.
Options:

1. WildFly-specific annotation:
   ```java
   @Stateless
   public class LongRunningService {
       @TransactionTimeout(
           value = 120, unit = TimeUnit.SECONDS
       )
       public void processLargeExport() { ... }
   }
   ```

2. Programmatic (BMT):
   ```java
   @Resource
   private UserTransaction utx;

   public void methodWithTimeout() throws Exception {
       utx.setTransactionTimeout(120); // seconds
       utx.begin();
       try {
           doWork();
           utx.commit();
       } catch (Exception e) {
           utx.rollback();
           throw e;
       }
   }
   ```

3. Server-wide default (standalone.xml):
   ```xml
   <coordinator-environment default-timeout="300"/>
   ```

When timeout fires: `TransactionRolledbackException`.
All locks released.

*What separates good from great:* "A transaction that runs for 60+ seconds is usually doing too much in one TX: loading thousands of entities, doing complex calculations, or calling a slow external service. Fix the root cause first. Increasing timeout is a band-aid. Set timeout to 30-60 seconds as a safety net, then investigate anything that approaches it."

---

**[SENIOR] Q8 - What is the difference between
JTA REQUIRED and REQUIRED on a CDI @Transactional?**

*Why they ask:* EJB vs CDI transaction comparison.

Functionally equivalent for most use cases:

EJB CMT REQUIRED:
- Container intercepts the method call
- Joins existing JTA TX or starts new one
- Runtime/system exception: rollback
- Application exception (checked, no annotation): commit

CDI @Transactional(TxType.REQUIRED):
- CDI interceptor (@Priority 200) handles transaction
- Same semantics: join or start
- Same rollback rules for unchecked
- `rollbackOn` attribute: `@Transactional(rollbackOn=MyException.class)`

```java
// EJB CMT:
@Stateless
public class OrderService {
    // Default REQUIRED, auto rollback on RuntimeException
    public void save(Order o) { em.persist(o); }
}

// CDI @Transactional:
@ApplicationScoped
@Transactional  // REQUIRED by default
public class OrderService {
    public void save(Order o) { em.persist(o); }
    // Same behavior, no EJB required
}
```

Key difference: CDI @Transactional requires no
application server EJB support - works in CDI containers
without full Jakarta EE. Also: `rollbackOn` is more
explicit than @ApplicationException.

*What separates good from great:* "In Quarkus and modern Payara/WildFly, I use CDI @Transactional exclusively. It's explicit, portable, and the rollbackOn attribute is cleaner than @ApplicationException. The only reason to use EJB @Stateless is for the connection pooling behavior or legacy compatibility."

---

**[SENIOR] Q9 - How do you implement idempotent
transactions for retry safety?**

*Why they ask:* Distributed systems resilience.

Problem: network timeouts cause clients to retry
operations. If the first request succeeded (committed)
but the response was lost, the retry creates a duplicate.

Idempotency key pattern:
```java
@Entity
public class IdempotencyKey {
    @Id String key;          // client-provided UUID
    String result;           // serialized response
    Instant createdAt;
    boolean processed;
}

@Stateless
public class PaymentService {

    @PersistenceContext EntityManager em;

    @TransactionAttribute(REQUIRED)
    public PaymentResult chargeIdempotent(
        String idempotencyKey,
        PaymentRequest req
    ) {
        // Check if already processed
        IdempotencyKey existing = em.find(
            IdempotencyKey.class, idempotencyKey
        );
        if (existing != null && existing.isProcessed()) {
            // Return cached result, no duplicate charge
            return deserialize(existing.getResult());
        }

        // Process payment
        PaymentResult result = chargeGateway(req);

        // Save result
        IdempotencyKey record = new IdempotencyKey();
        record.setKey(idempotencyKey);
        record.setResult(serialize(result));
        record.setProcessed(true);
        em.persist(record);

        return result;
        // Both charge and idempotency record commit atomically
    }
}
```

*What separates good from great:* "The idempotency key and the business operation must commit in the same transaction. If they're separate transactions, a crash between commit 1 (business) and commit 2 (key record) means the next retry processes the payment again. Single transaction = atomicity guarantee."

---
