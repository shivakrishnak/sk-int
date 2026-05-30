---
layout: default
title: "Hibernate - L2 Transactions"
parent: "Hibernate"
grand_parent: "SK Interview"
nav_order: 5
permalink: /hibernate/l2-transactions/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| # | Keyword | Weight |
| --- | --- | --- |
| 1 | [Transaction Management and Isolation Levels](#transaction-management-and-isolation-levels) | critical |
| 2 | [Schema Generation and DDL Validation](#schema-generation-and-ddl-validation) | medium |

---

# Transaction Management and Isolation Levels

**TL;DR** - `@Transactional` demarcates transaction boundaries in Spring,
propagation controls how nested calls share transactions, isolation level
controls what dirty/phantom reads are permitted, and `@Version` provides
optimistic locking for concurrent updates.

---

### 🎯 Model Answer

**30 seconds:**
> `@Transactional` on a service method wraps everything inside in one
> database transaction: all SQL in the method either commits or rolls
> back together. Propagation controls what happens when one
> `@Transactional` method calls another - the default `REQUIRED`
> joins the existing transaction. Isolation level controls concurrent
> read visibility: READ_COMMITTED prevents dirty reads; REPEATABLE_READ
> additionally prevents non-repeatable reads; SERIALIZABLE prevents
> phantom reads at the cost of throughput.

**3 minutes (Senior):**
> Spring's `@Transactional` is the AOP-based declarative transaction
> management layer over JPA's EntityTransaction. When a `@Transactional`
> method is called, Spring's proxy intercepts the call, begins a
> transaction on the EntityManager, calls the method, then either
> commits or rolls back. This only works for Spring-managed beans
> called through the proxy - calling a @Transactional method on
> `this` bypasses the proxy and the transaction.
>
> Propagation is the coordination mechanism between nested
> @Transactional calls. REQUIRED (default): join the existing
> transaction, or start one if none exists. REQUIRES_NEW: always
> suspend the current transaction and start a new one - useful for
> audit logging that must commit even when the parent rolls back.
> SUPPORTS: join if a transaction exists, proceed without one if not.
> NOT_SUPPORTED: always suspend the transaction for this method.
> MANDATORY: must have an existing transaction, throw if not.
> NEVER: must NOT have a transaction.
>
> Isolation levels are the per-transaction setting that controls
> which concurrency anomalies are prevented:
> - READ_UNCOMMITTED: dirty reads allowed (almost never used)
> - READ_COMMITTED: dirty reads prevented (PostgreSQL default)
> - REPEATABLE_READ: non-repeatable reads prevented (MySQL InnoDB default)
> - SERIALIZABLE: phantom reads prevented (maximum isolation, minimum throughput)
>
> For most applications: READ_COMMITTED with optimistic locking
> (`@Version`) is the right combination. READ_COMMITTED allows high
> throughput; `@Version` prevents lost updates without locking rows
> for the duration of the transaction.

*Adapting up:* Hibernate's optimistic locking with `@Version` throws
`OptimisticLockException` (or `StaleObjectStateException`) when two
transactions try to update the same version. The application must
handle this: retry the transaction (recommended for automated jobs) or
show a conflict error to the user (recommended for user-facing updates).

*Adapting down:* "@Transactional means the whole method is one database
transaction. Isolation level controls what data you can see from other
concurrent transactions."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about transaction management -
how Hibernate and Spring manage database transactions and isolation."

**(2) First principles:** "From first principles, multiple concurrent
database operations must either be isolated from each other (to prevent
reading partial writes) or coordinated (to prevent lost updates).
Isolation levels and locking are the two mechanisms."

**(3) Bridge:** "Think of a transaction like a checkout counter: the
cashier scans all items before payment. Either everything is scanned
and paid (commit), or the whole transaction is voided (rollback).
Isolation level controls whether other customers can see items being
scanned at your checkout before you pay."

---

### 📘 Concept Explanation

**What it is:**
Transaction management in Hibernate/Spring JPA controls the boundaries
within which database operations are atomic, consistent, isolated, and
durable (ACID). `@Transactional` is the Spring AOP annotation that
declares these boundaries declaratively.

**The problem it solves:**
Without explicit transaction management, each SQL statement executes
in its own auto-commit transaction. Multi-step operations (debit
account A, credit account B) can leave data in inconsistent states
if the process crashes between steps. Transactions group related
operations into an atomic unit.

**How it works:**

```
Spring @Transactional proxy interception:

Caller
  │
  ▼
TransactionInterceptor (Spring AOP proxy)
  ├─ Look up existing transaction (ThreadLocal)
  ├─ Propagation=REQUIRED:
  │    existing? JOIN it  no? BEGIN new
  ▼
Service.method() executes
  ├─ EntityManager operations
  ├─ SQL batched (Hibernate)
  │
  ├─ Normal return → commit (flush + commit)
  └─ RuntimeException → rollback

Isolation Levels (DB enforces):
  READ_COMMITTED:
    T1 reads row → gets committed value only
    T2 updates+commits row → T1 re-reads: sees T2's value
    (non-repeatable read: allowed at READ_COMMITTED)

  REPEATABLE_READ:
    T1 reads row → snapshot taken
    T2 updates+commits row → T1 re-reads: still sees snapshot
    (non-repeatable read: prevented)
```

**The key insight:**
`@Transactional` is a method-level AOP interceptor. It works because
Spring wraps your bean in a proxy. Direct calls to `this.method()`
inside the same bean bypass the proxy - the transaction is never started.

**When to use it:**
- Every service method that modifies the database: `@Transactional`
- Read-only methods: `@Transactional(readOnly = true)` - performance
  hint to Hibernate (disables dirty checking, allows DB replicas)
- Event-sourcing audit log that must commit independently: REQUIRES_NEW

**When NOT to use it:**
- Do not put `@Transactional` on controller methods - service layer
  is the correct boundary
- Do not use at DAO/repository level alone - transactions belong at
  the service layer where business operations are composed

**Alternatives:**
- Programmatic transactions: `TransactionTemplate` for fine-grained
  control within a single method
- JTA: distributed transactions across multiple resources (rarely needed)

---

### 💻 Code Example

```java
// BAD: @Transactional bypassed by self-call
@Service
public class OrderService {
    @Transactional // this annotation has NO EFFECT
    // when called as this.processOrder()
    public void processOrder(Order order) {
        // transaction not started!
    }

    public void submitOrder(Order order) {
        // BUG: calling @Transactional method on 'this'
        this.processOrder(order); // bypasses proxy!
        // No transaction: each SQL is auto-committed
    }
}
```

> **Code walkthrough:** Spring `@Transactional` works via a proxy
> that wraps the bean. `this.processOrder()` calls the real object
> method directly - the proxy is bypassed and no transaction is
> started. This is one of the most common Spring @Transactional
> bugs and is completely silent: no error, just no transaction.

```java
// GOOD: Transaction at service layer, readOnly for reads
@Service
@Transactional // class-level default: all methods transactional
public class OrderService {

    private final OrderRepository orderRepo;
    private final InventoryService inventoryService;

    // Read-only: Hibernate skips dirty checking, allows replicas
    @Transactional(readOnly = true)
    public OrderDTO getOrder(Long orderId) {
        return orderRepo.findById(orderId)
            .map(orderMapper::toDTO)
            .orElseThrow(OrderNotFoundException::new);
    }

    // Default: REQUIRED - joins calling transaction if present
    @Transactional
    public void placeOrder(CreateOrderCommand cmd) {
        Order order = new Order(cmd.getCustomerId());
        cmd.getItems().forEach(item -> {
            // Both updates in same transaction
            order.addItem(item);
            inventoryService.reserve(item.getProductId(),
                item.getQuantity());
        });
        orderRepo.save(order);
        // Commit: both order and inventory changes committed
        // Rollback: if inventoryService throws, both rolled back
    }
}
```

> **Code walkthrough:** `@Transactional` at class level sets a default
> for all methods. `readOnly = true` is a performance optimization:
> Hibernate disables dirty checking on flush (no snapshot comparison)
> and allows the JPA provider to use a read replica if configured.
> The `placeOrder` method uses a single transaction for both order
> creation and inventory reservation - if inventory throws, the entire
> operation rolls back atomically.

```java
// GOOD: Optimistic locking with @Version
@Entity
public class Product {
    @Id Long id;
    String name;
    BigDecimal price;

    @Version // Hibernate manages: reads on load, checks on update
    Long version;
}

// Optimistic lock flow:
// Thread A: load Product{id=1, version=5, price=100}
// Thread B: load Product{id=1, version=5, price=100}
// Thread A: update price to 110, version becomes 6
// Thread B: tries to update price to 90, version=5
//   → UPDATE products SET price=90, version=6
//     WHERE id=1 AND version=5  -- 0 rows updated
//   → Hibernate throws OptimisticLockException

@Service
@Transactional
public class ProductService {
    public void updatePrice(Long id, BigDecimal newPrice) {
        try {
            Product product = productRepo.findById(id)
                .orElseThrow();
            product.setPrice(newPrice); // dirty flag set
            // Flush: UPDATE ... WHERE id=? AND version=?
        } catch (OptimisticLockException e) {
            // Retry or surface conflict to user
            throw new ConcurrentUpdateException(
                "Product updated concurrently, please retry");
        }
    }
}
```

> **Code walkthrough:** `@Version` adds a version column to the table.
> Hibernate reads the version on load and adds `AND version = ?` to
> every UPDATE. If another transaction committed an update between
> our load and our update, the version check fails (0 rows updated)
> and Hibernate throws `OptimisticLockException`. This prevents the
> "lost update" problem without holding a row lock for the duration
> of the transaction, allowing much higher concurrency than pessimistic
> locking.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `@Transactional` makes everything in the method one database
> transaction: either all SQL commits or all rolls back. The default
> propagation is REQUIRED: if there's already a transaction, join it;
> if not, start a new one. Isolation level controls what concurrent
> transactions can see: READ_COMMITTED (PostgreSQL default) prevents
> dirty reads. I use `@Version` on entities for optimistic locking:
> it adds a version number and if two updates clash, an
> `OptimisticLockException` is thrown rather than silently losing
> one update.

*Push deeper:* "The @Transactional proxy bypass: calling a
@Transactional method on `this` inside the same class does not
start a transaction. This is a very common bug."

---

**Senior / Staff (5+ years):**
> My transaction design principles: @Transactional belongs at the
> service layer, not the DAO layer. The service layer defines the
> business operation boundary - the transaction should encompass the
> entire operation, not individual DB calls.
>
> For propagation: REQUIRED for 95% of cases. REQUIRES_NEW for
> independent audit/event operations that must commit regardless of
> parent transaction outcome - for example, audit log entries should
> persist even when the audited operation fails. MANDATORY for
> database operations that must never run outside a transaction
> (useful as a design contract check).
>
> For isolation: READ_COMMITTED + optimistic locking is the right
> default for transactional systems. REPEATABLE_READ is sometimes
> necessary when you need to read a row multiple times in a transaction
> and must see consistent data. SERIALIZABLE is almost never correct
> in production - it severely limits concurrency and causes serialization
> failures that require application-level retry logic.
>
> The `@Transactional(readOnly = true)` is not just a hint - it
> prevents flushing entirely (no dirty checking on commit) and can
> route to a read replica if your DataSource is configured as a
> routing DataSource. Always mark read-only queries explicitly.

*Push deeper:* "The Spring transaction synchronization mechanism
allows registering callbacks on transaction commit/rollback:
`TransactionSynchronizationManager.registerSynchronization()`.
I use this to send domain events ONLY after a successful commit -
not before commit where the transaction might still roll back."

---

### ⚠️ Common Misconceptions

| Misconception | Reality | Danger Level |
|---|---|---|
| "@Transactional on private methods works" | Spring AOP proxies cannot intercept private methods - @Transactional has no effect | Critical |
| "this.transactionalMethod() creates a transaction" | Self-calls bypass the Spring proxy - no transaction | Critical |
| "REQUIRES_NEW suspends and reuses the outer connection" | REQUIRES_NEW requires a new database connection from the pool - can cause pool exhaustion | High |
| "readOnly=true is only a hint with no effect" | Hibernate disables dirty-check flush; DataSource routing can redirect to read replica | Medium |
| "OptimisticLockException means data corruption" | It means a concurrent update conflict was detected and prevented - the application must retry | Medium |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Transaction Not Rolling Back on Checked Exception**

*Symptom:* A checked exception is thrown, but the transaction
commits and the partial update persists in the database.

*Root cause:* Spring's default is to roll back on RuntimeException
only. Checked exceptions do NOT trigger rollback unless explicitly
declared:
```java
@Transactional // only rolls back on RuntimeException by default
public void process() throws BusinessException {
    repo.save(entity); // persisted even if BusinessException thrown
    throw new BusinessException("invalid"); // no rollback!
}
```

*Fix:*
```java
@Transactional(rollbackFor = BusinessException.class)
public void process() throws BusinessException { ... }
// OR: make BusinessException extend RuntimeException
```

---

**Failure 2: Connection Pool Exhaustion from REQUIRES_NEW**

*Symptom:* Under load, `HikariPool-1 - Connection is not available,
request timed out after 30000ms` in logs.

*Root cause:* REQUIRES_NEW suspends the outer transaction but
HOLDS its connection. The new transaction acquires a second connection.
With a pool of 10 and 8 concurrent requests, each using REQUIRES_NEW,
all 16 required connections exceed the pool of 10.

*Diagnostic:*
```properties
logging.level.com.zaxxer.hikari.pool.HikariPool=DEBUG
# Shows: "waiting for connection"
```

*Fix:* Increase pool size or refactor REQUIRES_NEW out of
high-concurrency code paths. Move the REQUIRES_NEW operation
(e.g., audit log) to an async context where it runs after
the parent transaction releases its connection.

---

**Failure 3: StaleObjectStateException in Batch Job**

*Symptom:* Nightly batch job updating product prices fails
intermittently with `StaleObjectStateException` on Product entities.

*Root cause:* `@Version` detects concurrent modification. The batch
job loaded a product, a concurrent user update committed a new
version, and the batch update's version check fails.

*Fix:*
```java
// Option 1: Load with pessimistic lock in batch
Product p = productRepo.findById(id,
    LockModeType.PESSIMISTIC_WRITE);
// Option 2: Catch and retry
try { ... } catch (OptimisticLockException e) {
    // reload and re-apply the price update
}
// Option 3: Bulk UPDATE bypassing @Version check
@Modifying @Query(
    "UPDATE Product p SET p.price = :price WHERE p.id = :id")
void updatePriceDirectly(Long id, BigDecimal price);
// WARNING: this bypasses @Version - use only when intended
```

---

### 🎯 Interview Deep-Dive

| Timing | Seniority | Focus |
|--------|-----------|-------|
| 2 min | Junior | What @Transactional does, rollback rules |
| 3 min | Mid | Propagation types, proxy bypass bug |
| 5 min | Senior | Isolation levels, optimistic vs pessimistic |
| 7 min | Staff | Transaction design for complex workflows |
| 10 min | FAANG | Distributed transaction alternatives |

---

**Q1 [JUNIOR] - DEFINITION**
When does `@Transactional` NOT roll back?

*Why they ask:* The default rollback-only-on-RuntimeException
behavior catches many developers off guard.

*Likely follow-up:* "How do you force rollback on a checked exception?"

**Answer:**
Spring `@Transactional` rolls back automatically for unchecked
exceptions (subclasses of `RuntimeException` and `Error`) by default.
It does NOT roll back for:

1. Checked exceptions (subclasses of `Exception` that are not
   RuntimeException). If your method declares `throws IOException`
   and throws it, the transaction commits and the exception propagates.

2. Exceptions caught within the method: if the exception is
   caught and handled inside the `@Transactional` method, Spring's
   interceptor never sees it and no rollback decision is made.

3. When `noRollbackFor` is specified: `@Transactional(noRollbackFor =
   ValidationException.class)` prevents rollback for ValidationException
   even though it is a RuntimeException.

To roll back on a checked exception, declare it explicitly:
```java
@Transactional(rollbackFor = {IOException.class,
    BusinessException.class})
public void process() throws IOException, BusinessException {
    // IOException or BusinessException = rollback
}
```

The easiest pattern is to make business exceptions extend
`RuntimeException`, which causes automatic rollback without
`rollbackFor`.

*What separates good from great:* Mentioning `noRollbackFor` as
the inverse - you can also PREVENT rollback for specific
RuntimeExceptions that you want the transaction to commit despite.

---

**Q2 [MID] - MECHANISM**
What is the difference between REQUIRED and REQUIRES_NEW
propagation? When would you use each?

*Why they ask:* Propagation is the most important configuration
after the default, and REQUIRES_NEW has a significant gotcha.

*Likely follow-up:* "What is the connection pool implication of REQUIRES_NEW?"

**Answer:**
REQUIRED (default): if a transaction is already active on the
current thread, join it. If not, start a new one. The inner
@Transactional method participates in the outer transaction. If
the inner method throws and the outer catches it, both are still
in the SAME transaction - the rollback mark is set, and the outer
transaction cannot commit (it will roll back even if the outer
catches the exception).

REQUIRES_NEW: always start a new transaction, regardless of any
existing transaction. The outer transaction is SUSPENDED (its
database connection is held but not used). The inner method gets
its own independent transaction that commits or rolls back
independently.

Use REQUIRES_NEW for: operations that must commit independently
of the calling transaction. The canonical example is an audit log:
```java
@Service
public class AuditService {
    @Transactional(propagation = REQUIRES_NEW)
    public void log(String action, Long entityId) {
        auditRepo.save(new AuditEntry(action, entityId));
    }
    // This audit entry commits even if the calling
    // transaction rolls back - which is what you want
    // for accurate audit trails of failed operations
}
```

The connection pool implication: REQUIRES_NEW acquires a SECOND
database connection while the outer transaction holds the first.
With a connection pool of size 10, a high-concurrency code path
using REQUIRES_NEW can cause all connections to be held in pairs
and exhaust the pool.

*What separates good from great:* The two-connection requirement
for REQUIRES_NEW and the pool exhaustion risk - this is the most
dangerous production consequence of overusing REQUIRES_NEW.

---

**Q3 [SENIOR] - DEBUGGING**
A service method marked `@Transactional` is not rolling back.
Walk me through the systematic diagnosis.

*Why they ask:* @Transactional not working is a very common
production issue with multiple root causes.

*Likely follow-up:* "How does CGLIB proxying differ from JDK proxying?"

**Answer:**
Systematic diagnosis has five checks, in order of likelihood:

Check 1: Self-call. Is the @Transactional method called via
`this.method()` inside the same class? If yes, the proxy is
bypassed and no transaction starts. Fix: inject the service into
itself (`@Autowired OrderService self; self.method()`) or
restructure to use a separate class.

Check 2: Exception type. Is the exception a checked exception?
Spring only rolls back on RuntimeException by default. Add
`rollbackFor = YourCheckedException.class` or change the exception
to extend RuntimeException.

Check 3: Exception caught. Is the exception caught inside the
method? If so, Spring's interceptor never sees it. The transaction
commit/rollback decision is made when the method returns, not
when an exception is thrown inside it.

Check 4: Proxy type. Is the class final? CGLIB-based proxies
(default in Spring Boot) cannot subclass final classes. The bean
would not be wrapped in a proxy. Fix: remove `final` keyword.
Is the method final or private? Same issue.

Check 5: Transaction propagation. If the method uses `NOT_SUPPORTED`
or `NEVER` propagation, no transaction is started intentionally.
Check the @Transactional parameters.

Check 6: Multiple DataSources. Is the @Transactional on the wrong
DataSource's transaction manager? With multiple DataSources, you
must specify: `@Transactional("primaryTransactionManager")`.

*What separates good from great:* Listing all six causes
systematically rather than guessing at self-call alone.

---

**Q4 [SENIOR] - TRADE-OFF**
Compare optimistic locking vs pessimistic locking. When do you
use each?

*Why they ask:* Locking strategy is a core architectural decision
for concurrent access.

*Likely follow-up:* "What is the difference between @Version
(application-level) and SELECT FOR UPDATE (database-level)?"

**Answer:**
Optimistic locking assumes conflicts are rare. It does not hold
a database lock during the transaction. At commit time, it checks
whether the data changed since it was read. If changed, it throws
an exception and the application must retry or surface the conflict.
Hibernate's `@Version` implements this with a version column.

Pessimistic locking assumes conflicts are likely. It holds a
database row lock from the moment of read until commit (or rollback).
Other transactions that try to write to the locked row block until
the lock is released. Hibernate uses `LockModeType.PESSIMISTIC_WRITE`
which generates `SELECT ... FOR UPDATE`.

Optimistic locking wins when:
- Conflicts are rare (< 5% of operations)
- Read-to-write ratio is high (many reads, few competing writes)
- Throughput is critical (no blocking waits)
- The cost of a retry on conflict is acceptable

Pessimistic locking wins when:
- Conflicts are frequent (> 20% of operations)
- The operation cannot be retried (external side effects before
  the DB operation, like a payment charge)
- Lock duration is very short (< 100ms)

Example where pessimistic is mandatory: booking a seat on a flight.
Optimistic locking would allow 10 users to add the last seat to
their cart, then fail 9 of them at checkout - a terrible user
experience. Pessimistic locking serializes the selection phase
and only shows the seat as available to one user at a time.

The hybrid: optimistic locking with a bounded retry loop is the
standard production pattern for most CRUD operations. Pessimistic
locking is reserved for inventory/seat/appointment booking scenarios.

*What separates good from great:* The seat booking example as
the clear case where pessimistic is mandatory due to UX constraints.

---

**Q5 [MID] - MECHANISM**
What isolation anomalies does each isolation level prevent?

*Why they ask:* Isolation level selection requires understanding
what each level prevents.

*Likely follow-up:* "Which isolation level does PostgreSQL use by default?"

**Answer:**
The four isolation levels each prevent a specific set of anomalies:

READ_UNCOMMITTED: prevents nothing. Allows dirty reads (reading
another transaction's uncommitted changes). Almost never used in
production because any uncommitted data could be rolled back,
giving readers phantom data.

READ_COMMITTED: prevents dirty reads. Each read within the
transaction sees only committed data. But a second read of the
same row in the same transaction may see different data if another
transaction committed between the two reads (non-repeatable read).
PostgreSQL default.

REPEATABLE_READ: prevents dirty reads AND non-repeatable reads.
A row read once in the transaction is locked (or snapshotted - depends
on MVCC implementation) - a second read returns the same data
regardless of concurrent commits. MySQL InnoDB default. But new
rows matching a WHERE clause can appear between reads (phantom reads).

SERIALIZABLE: prevents all anomalies including phantom reads.
Transactions behave as if they run serially, one after another.
Highest isolation, lowest throughput. Any operation that would
cause a serialization anomaly results in a `serialization failure`
that the application must retry.

For most web applications: READ_COMMITTED (PostgreSQL) or
REPEATABLE_READ (MySQL) is the correct level. Increasing isolation
level reduces throughput due to more locking or MVCC overhead.
Use SERIALIZABLE only for financial calculations where exact
read-consistency across multiple reads is mandatory.

*What separates good from great:* Explaining that PostgreSQL implements
REPEATABLE_READ and SERIALIZABLE using MVCC (snapshot isolation)
rather than row locks - so these levels in PostgreSQL do NOT block
concurrent reads the way they do in databases that use lock-based
isolation.

---

**Q6 [JUNIOR] - MECHANISM**
What does `@Transactional(readOnly = true)` actually do?

*Why they ask:* Many developers add readOnly without understanding
what it actually changes.

*Likely follow-up:* "Does readOnly = true prevent writes?"

**Answer:**
`readOnly = true` has three effects:

First, Hibernate optimization: disables dirty-checking (snapshot
comparison) at flush time. When a session ends, Hibernate normally
compares every loaded entity to its snapshot to detect changes.
With readOnly, it skips this comparison, saving CPU and memory
for large read operations.

Second, Hibernate flush mode: sets the flush mode to NEVER on the
Session. This means no automatic flushes during the transaction.
If you accidentally call a write operation (save, delete) in a
readOnly transaction, it will either be silently ignored or throw
a `TransactionSystemException` depending on the database and
Hibernate version. It is NOT a strict enforcement in all cases.

Third, database routing (optional): if you configure an
AbstractRoutingDataSource to separate read and write DataSources
(read replica pattern), the `readOnly` flag on the transaction
can be used to route the connection to the read replica:
```java
class ReadWriteRoutingDataSource
    extends AbstractRoutingDataSource {
    @Override
    protected Object determineCurrentLookupKey() {
        return TransactionSynchronizationManager
            .isCurrentTransactionReadOnly()
            ? "READ" : "WRITE";
    }
}
```

So readOnly = true is part performance optimization, part contract
(this method should not write), and part routing hint.

*What separates good from great:* The routing DataSource pattern -
readOnly enables read replica routing in production architectures.

---

**Q7 [STAFF] - BEHAVIORAL**
Describe a distributed transaction problem you encountered and
how you solved it without distributed transactions.

*Why they ask:* Distributed transactions (2PC/XA) are rarely the
right solution. Staff engineers design around them.

*Likely follow-up:* "What are the trade-offs of the Saga pattern?"

**Answer:**
**S (Situation):** We had an order service that needed to reserve
inventory in an inventory service and charge the customer's payment
method in a payment service atomically. Initial design used XA
transactions across three databases. We abandoned this because XA
coordinator failures left transactions in doubt for minutes,
blocking rows across all three databases.

**T (Task):** Redesign the order workflow to be consistent without
distributed transactions.

**A (Action):** I implemented the Saga pattern using choreography.
Each service publishes an event on success and listens for
compensating events on failure.

```
Order Service:      → OrderCreated event
Inventory Service:  → ReservationMade event (success)
                    OR ReservationFailed event (no stock)
Payment Service:    → PaymentCharged event (success)
                    OR PaymentFailed event (card declined)

On PaymentFailed:
  Inventory Service listens → fires ReleaseReservation
  Order Service listens → marks order FAILED
```

For the local transactional safety of event publishing, I used
the Transactional Outbox pattern: the event is written to an
`outbox` table in the SAME local transaction as the entity change.
A separate process reads the outbox and publishes to Kafka.
This guarantees: if the business operation commits, the event
is eventually published. No event is published if the business
operation rolls back.

**R (Result):** Eliminated the XA coordinator. Each service has
simple local transactions. The system is eventually consistent
(inventory reservation and payment are separate steps with a
brief window of inconsistency). Compensating transactions handle
failures explicitly. We added idempotency keys to handle duplicate
events. Mean time to consistency: < 2 seconds for happy path,
< 30 seconds for failure recovery.

*What separates good from great:* The Transactional Outbox pattern
detail - this is the key to atomically persisting the entity change
AND guaranteeing the event is published.

---

### ⚖️ Comparison Table

| Aspect | Optimistic (@Version) | Pessimistic (SELECT FOR UPDATE) | SERIALIZABLE isolation |
|--------|----------------------|---------------------------------|------------------------|
| Lock held? | No | Yes (row lock) | Snapshot/predicate lock |
| Throughput | High | Lower (blocking) | Lowest |
| Conflict rate | Best for rare conflicts | Best for frequent conflicts | Prevents all anomalies |
| Application retry? | Required on conflict | Not needed (blocks) | Required on serial failure |
| Best for | Web CRUD, low contention | Booking, inventory | Financial calculations |

**The deciding factor:**
Default to optimistic locking. Use pessimistic for booking/allocation
scenarios where optimistic would cause poor UX (retrying after "you
thought you had the seat").

*(Omit: System Design - ★★☆ keyword)*

*(Omit: Diagram - prose and table are sufficient)*

---

---

# Schema Generation and DDL Validation

**TL;DR** - `spring.jpa.hibernate.ddl-auto` controls how Hibernate
manages database schema: `none` in production, `validate` in staging,
`create-drop` in tests; Flyway or Liquibase is the correct tool for
production schema migration.

---

### 🎯 Model Answer

**30 seconds:**
> Hibernate's `ddl-auto` property controls whether Hibernate creates,
> updates, or validates the database schema on startup. In production,
> this must be `none` or `validate` - never `update` or `create`. The
> correct production pattern is to manage schema migrations with Flyway
> or Liquibase (versioned migration scripts) and let Hibernate
> only validate that the schema matches the entity mappings.

**3 minutes (Senior):**
> The five ddl-auto options have dramatically different safety profiles.
> `create` drops and recreates all tables on startup - loses all data.
> `create-drop` drops tables on startup AND on shutdown - only for
> unit tests. `update` alters tables to add new columns or new tables -
> sounds useful but is unsafe in production because it cannot drop
> columns (to avoid data loss), cannot change column types safely,
> and can cause problems in multi-node deployments where multiple
> nodes start simultaneously. `validate` compares the entity mappings
> to the existing schema and throws an error on mismatch but makes no
> changes. `none` does nothing.
>
> The production pattern: `ddl-auto = validate` (or `none` if you
> trust your deployment), with Flyway or Liquibase for all schema
> changes. Flyway is simpler: numbered SQL migration scripts that run
> in order, tracking which have been applied in a `flyway_schema_history`
> table. Liquibase is more powerful but more complex: XML/YAML/JSON
> changesets that can be rolled back. Both integrate with Spring Boot
> and run before the application starts (or via separate migration
> commands before deployment).
>
> The CI/CD pattern: migration scripts are applied in the deployment
> pipeline BEFORE new application code starts. This means migrations
> must be backward-compatible with the PREVIOUS version of the
> application (for zero-downtime deployments): add-only (new columns
> nullable or with defaults), never drop columns until the next
> deployment cycle.

*Adapting up:* The expand-contract (blue-green) migration pattern:
Expand (add the new column, keep the old), deploy new code that
writes both, Contract (remove the old column after all traffic
is on the new code). This is the zero-downtime migration pattern.

*Adapting down:* "Never use `update` in production. Use Flyway with
numbered SQL scripts and `validate` in the app config."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about schema management - how Hibernate
and tools like Flyway manage database table structure."

**(2) First principles:** "From first principles, a database schema must
evolve with the application. Ad-hoc schema changes are unsafe and
untrackable. Version-controlled migration scripts give the same
reproducibility to schema changes that source control gives to code."

**(3) Bridge:** "Think of Flyway migration scripts like git commits for
the database schema. Each script is a version, applied in order, and
the schema history table is the git log - it records what was applied
and when."

---

### 📘 Concept Explanation

**What it is:**
Hibernate's `ddl-auto` (configured via `spring.jpa.hibernate.ddl-auto`
in Spring Boot) controls how Hibernate manages the database schema on
application startup. It ranges from no-op (`none`) to destructive
(`create-drop`). Flyway and Liquibase are database migration frameworks
that manage schema changes as versioned, ordered scripts.

**The problem it solves:**
Without schema management, database structures are changed ad-hoc by
developers with direct DB access. This causes: schema drift between
environments, inability to reproduce schema from scratch, no audit
trail of changes, inconsistent schemas between production replicas,
and failed deployments when the application assumes a schema that has
not been applied.

**How it works:**

```
ddl-auto options:
none → Hibernate does nothing to schema
validate → Hibernate reads schema, throws if mismatch
update → Hibernate issues ALTER TABLE to add missing things
          (cannot drop columns or change types safely)
create → DROP + CREATE all tables on startup (LOSES DATA)
create-drop → DROP + CREATE on startup, DROP on shutdown

Flyway integration:
  startup:
    1. Connect to DB
    2. Check flyway_schema_history table
    3. Apply any unapplied V001__.sql, V002__.sql...
    4. Update history table
  → DB schema is at correct version
  → App starts (Hibernate validates against current schema)
```

**The key insight:**
`ddl-auto = update` is "almost safe" which makes it dangerous. It
adds columns and tables but cannot safely remove them (data loss risk).
In multi-node deployments, two nodes starting simultaneously both try
to apply the same ALTER TABLE, causing race conditions. Flyway/Liquibase
use a lock to prevent this.

**When to use it:**
- `create-drop`: unit tests with in-memory H2
- `validate`: staging/production alongside Flyway
- `none`: production when using Flyway with 100% confidence in sync
- `create`: never in production; development-only against throwaway DBs

**When NOT to use it:**
- Never `update` in production
- Never `create` or `create-drop` against any database with real data

**Alternatives:**
- Flyway: SQL-first, simple, widely used
- Liquibase: XML/YAML/JSON changesets, more powerful, rollback support
- Manual DBA migrations: enterprise environments with DBA approval gates

---

### 💻 Code Example

```properties
# BAD: update in production (common mistake in Spring Boot tutorials)
spring.jpa.hibernate.ddl-auto=update
# Risks:
# - Race condition on multi-node startup
# - Cannot drop removed columns (schema drift)
# - Cannot change column types safely
# - No migration history/audit trail
```

> **Code walkthrough:** `ddl-auto=update` feels safe but is a production
> anti-pattern. It applies only additive changes and cannot handle
> column type changes, column removals, or constraint changes. Two nodes
> starting simultaneously can both execute the same ALTER TABLE causing
> failures. There is no record of what changed or when.

```properties
# GOOD: validate in production with Flyway managing migrations
# application.properties:
spring.jpa.hibernate.ddl-auto=validate
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
spring.flyway.baseline-on-migrate=false
```

```java
// GOOD: Flyway migration script naming convention
// src/main/resources/db/migration/

// V1__Create_users_table.sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP
);

// V2__Add_roles_table.sql
CREATE TABLE roles (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE user_roles (
    user_id BIGINT NOT NULL
        REFERENCES users(id) ON DELETE CASCADE,
    role_id BIGINT NOT NULL
        REFERENCES roles(id),
    granted_at TIMESTAMP NOT NULL
        DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id)
);

// V3__Add_users_department.sql
-- Backward-compatible (nullable allows old app to run)
ALTER TABLE users
    ADD COLUMN department_id BIGINT;
-- Note: no FK yet - add in next version after data backfill
```

> **Code walkthrough:** Flyway migration scripts are named
> `V{version}__{description}.sql` (two underscores). They execute
> in version order and are never re-executed (Flyway checks the checksum
> in `flyway_schema_history`). The V3 migration adds a nullable column -
> this is backward-compatible: the old version of the application can
> still run (ignores the new column) while the new version reads it.
> This is the expand phase of expand-contract migration.

```java
// GOOD: Integration test with create-drop (isolated, no data leakage)
// application-test.properties:
// spring.jpa.hibernate.ddl-auto=create-drop
// spring.datasource.url=jdbc:h2:mem:testdb

@SpringBootTest
@TestPropertySource(locations = "classpath:application-test.properties")
class UserRepositoryTest {
    @Autowired UserRepository userRepo;

    @Test
    void shouldSaveAndLoadUser() {
        User user = new User("Alice", "alice@example.com");
        userRepo.save(user);
        Optional<User> found = userRepo.findByEmail(
            "alice@example.com");
        assertThat(found).isPresent();
        assertThat(found.get().getName()).isEqualTo("Alice");
    }
}
// create-drop: table created on context start,
// dropped on context close - clean per test run
```

> **Code walkthrough:** `create-drop` is the correct setting for
> integration tests against in-memory H2. The schema is created
> fresh for each test context and dropped when the context closes.
> This ensures test isolation: no data from previous test runs
> affects current tests. Never use `create-drop` against a real
> database.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `ddl-auto` controls whether Hibernate modifies the database schema
> on startup. The options from least to most dangerous: `none` (do
> nothing), `validate` (compare mappings to schema, throw if mismatch),
> `update` (add missing things - unsafe in production), `create` (drop
> and recreate all tables - loses all data), `create-drop` (create on
> start, drop on shutdown - tests only). In production I use `validate`
> with Flyway managing all schema changes as versioned SQL scripts.
> Flyway runs the scripts in order on startup and tracks which have
> been applied.

*Push deeper:* "The key advantage of Flyway over `ddl-auto=update` is
the migration history: Flyway records every migration in
`flyway_schema_history` with timestamp and checksum, giving a full
audit trail of schema changes."

---

**Senior / Staff (5+ years):**
> My standard production setup: `ddl-auto=validate` + Flyway, where
> migrations are applied in the CI/CD pipeline before deployment, not
> at application startup in production. Applying migrations at startup
> means a multi-node deployment has multiple nodes racing to apply
> the same migration - Flyway handles this with a DB lock, but it
> still means node startup waits for migration. Better: apply
> migrations as a pre-deployment step and restart nodes after.
>
> For zero-downtime deployments, migrations must be backward-compatible
> with the PREVIOUS version of the code. The expand-contract pattern:
> Expand phase (deploy migration, add new column nullable or with
> default - old code ignores it, new code reads it). Deploy new code.
> Contract phase (deploy migration to add constraints, drop old column).
> Two deployment cycles per schema change, but zero downtime.
>
> The Flyway repair command is critical operational knowledge: when a
> migration fails midway, it is marked as failed in the history table.
> The next startup refuses to run until repaired. `flyway:repair` clears
> the failed state. For failed migrations that partially executed,
> you need to manually roll back the partial change in the DB before
> repairing.

*Push deeper:* "Flyway Callbacks (beforeMigrate, afterMigrate) are
useful for environment-specific operations: disable foreign key checks
before a large migration on MySQL, re-enable after. Or send a Slack
notification when production migration completes."

---

### ⚠️ Common Misconceptions

| Misconception | Reality | Danger Level |
|---|---|---|
| "ddl-auto=update is safe for production" | Cannot drop/change columns, causes race conditions on multi-node startup, no audit trail | Critical |
| "validate catches all schema mismatches" | Hibernate validate checks column types and nullability but may miss index differences, FK constraints, or stored procedures | Medium |
| "Flyway runs migrations atomically" | Each migration script runs in its own transaction (if DB supports DDL transactions) but multi-statement scripts may partially execute | High |
| "create-drop is safe for staging" | create-drop drops tables on application shutdown - any staging with real data is wiped on every restart | Critical |
| "Flyway and Liquibase are interchangeable" | Flyway is SQL-first (simpler for most teams); Liquibase supports database-agnostic changesets and rollback (more complex) | Low |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Multi-Node Migration Race Condition**

*Symptom:* On deployment with 3 nodes restarting simultaneously,
one node completes migration, two nodes fail with
`flyway.exception.FlywayException: Found non-empty schema(s)
without schema history table!` or duplicate migration errors.

*Root cause:* Without Flyway's distributed lock properly configured,
or with `ddl-auto=update` instead of Flyway, multiple nodes try
to apply the same schema change simultaneously.

*Fix:* Ensure Flyway is used (not ddl-auto=update). Flyway uses
`flyway_schema_history` with a row-level lock to serialize
migration across nodes. Alternatively, run migrations in a separate
pre-deployment job before any nodes start.

---

**Failure 2: Hibernate Validate Fails After Flyway Migration**

*Symptom:* After adding a new column via Flyway, the application
fails to start: `org.hibernate.tool.schema.spi.SchemaManagementException:
Schema-validation: missing column [department_id] in table [users]`

*Root cause:* The Flyway migration ran but the entity class was
not updated to map the new column. Or vice versa: the entity
has a field but the Flyway migration has not been added.

*Fix:* Entity class and Flyway migration must be deployed together.
The migration adds the column, the entity adds the field. If
deploying migration before code (zero-downtime), the entity field
must be optional (`@Column(nullable=true)`) to match the migration's
nullable column. Hibernate validate succeeds because the column exists.

---

**Failure 3: Flyway Checksum Mismatch After Editing a Migration**

*Symptom:* Startup fails: `Validate failed: Detected resolved
migration not applied to database: V3__Add_column.sql.
Migration checksum mismatch for migration version 3.`

*Root cause:* A developer edited an already-applied Flyway migration
script. Flyway detects the checksum change and refuses to start.

*Fix:*
```pwsh
# Development: if migration hasn't run in production
flyway repair  # resets checksum in history table to match file

# Production: NEVER edit applied migrations
# Instead: create V4 to correct V3's mistake
```
The rule: never edit a migration script after it has been applied
to ANY environment. Always create a new version to correct mistakes.

---

### 🎯 Interview Deep-Dive

| Timing | Seniority | Focus |
|--------|-----------|-------|
| 2 min | Junior | ddl-auto options, which to use where |
| 3 min | Mid | Flyway basics, migration naming |
| 5 min | Senior | Zero-downtime migration strategy |
| 7 min | Staff | Migration in CI/CD pipeline |
| 10 min | FAANG | Large-scale schema migration strategy |

---

**Q1 [JUNIOR] - DEFINITION**
What does `spring.jpa.hibernate.ddl-auto=update` do and why
is it dangerous in production?

*Why they ask:* `update` is the most commonly misused setting.

*Likely follow-up:* "What should you use instead?"

**Answer:**
`ddl-auto=update` tells Hibernate to compare the entity mappings
to the current database schema and ALTER the tables to match.
Specifically, it ADDS missing columns and creates missing tables.
It never drops anything (to avoid data loss).

Why it is dangerous in production:

First, it cannot safely handle all schema changes. Adding a column
with a NOT NULL constraint and no default fails on tables with
existing data. Changing a column type (VARCHAR to TEXT) is not
applied. Removing a field from an entity does NOT drop the column.
Over time, the schema drifts from what `update` would produce.

Second, multi-node startup race condition. In a 3-node deployment
where all nodes restart simultaneously, all three execute the same
ALTER TABLE at the same time. In the best case, one succeeds and
two get errors. In the worst case, partial DDL execution leaves
the schema in an inconsistent state.

Third, no audit trail. There is no record of what changed, when,
or by whom. Debugging a production schema issue without history
is very difficult.

The correct alternative: Flyway or Liquibase for production.
`ddl-auto=validate` to verify Hibernate entities match the
Flyway-managed schema. `ddl-auto=create-drop` in unit tests.

*What separates good from great:* All three dangers listed clearly:
limited operation support, race condition, no audit trail.

---

**Q2 [MID] - MECHANISM**
How does Flyway know which migrations have already been run?

*Why they ask:* Tests understanding of Flyway's state management.

*Likely follow-up:* "What happens if the flyway_schema_history table is missing?"

**Answer:**
Flyway maintains a `flyway_schema_history` table (called
`schema_version` in older versions) in the target database.
Every successfully applied migration is recorded with:
- Version number (from the filename: V3 from `V3__Add_column.sql`)
- Description (from filename: "Add column")
- Type (SQL, Java, etc.)
- Checksum (CRC32 of the script content)
- Installed_on timestamp
- Success flag

On each startup, Flyway:
1. Reads all migration files from the configured location
2. Reads the history table
3. Finds migrations NOT in the history table = pending
4. Applies them in version order
5. Records each applied migration in the history table

If a migration is already in the history table with success=true,
it is skipped.

The checksum mechanism: if a migration script's content changes
after it was applied, Flyway detects the checksum mismatch and
refuses to start. This is a safety mechanism: you cannot silently
edit an already-applied migration.

If the `flyway_schema_history` table is missing:
- `baseline-on-migrate=false` (default): Flyway creates the table
  and applies all migrations from V1
- `baseline-on-migrate=true`: Flyway creates the table with a
  baseline record (V1 marked as applied) and applies from V2+.
  Used when adding Flyway to an existing database.

*What separates good from great:* The `baseline-on-migrate` flag
for the "adding Flyway to an existing database" scenario - this
is a real production migration task.

---

**Q3 [SENIOR] - TRADE-OFF**
How do you design a zero-downtime database migration for a
column that must be renamed?

*Why they ask:* Column rename is a common schema change that
cannot be done atomically in a single deployment.

*Likely follow-up:* "What is the expand-contract migration pattern?"

**Answer:**
A direct column rename (`ALTER TABLE users RENAME COLUMN name TO full_name`)
cannot be done zero-downtime in a single deployment because:
- If you rename before deploying new code: old code reads `name`,
  new column is `full_name` - errors immediately
- If you deploy new code first: new code reads `full_name`, column
  is still `name` - errors immediately

The expand-contract pattern solves this with two deployments:

Phase 1 (Expand - Migration V5):
```sql
-- Add new column alongside old column
ALTER TABLE users ADD COLUMN full_name VARCHAR(255);
-- Backfill existing data
UPDATE users SET full_name = name;
-- Trigger to keep both in sync during migration window
CREATE OR REPLACE FUNCTION sync_name()
RETURNS TRIGGER AS $$
BEGIN
    NEW.full_name = NEW.name;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER after_users_update
BEFORE INSERT OR UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION sync_name();
```

Deploy code that writes to BOTH columns and reads from `full_name`.
Both old and new code work: old reads `name` (still populated),
new reads `full_name` (populated by trigger).

Phase 2 (Contract - Migration V6, next deployment):
```sql
-- Drop the sync trigger (no longer needed)
DROP TRIGGER after_users_update ON users;
DROP FUNCTION sync_name();
-- Drop the old column (safe: new code only uses full_name)
ALTER TABLE users DROP COLUMN name;
-- Add constraints now if needed
ALTER TABLE users ALTER COLUMN full_name SET NOT NULL;
```

This requires two deployment cycles but guarantees zero downtime.

*What separates good from great:* The trigger to keep both columns
in sync during the migration window - this is what makes the
transition truly zero-downtime for existing writes.

---

**Q4 [SENIOR] - DEBUGGING**
After a production deployment, `ddl-auto=validate` fails with
a schema mismatch. How do you diagnose and safely recover?

*Why they ask:* Schema validation failure in production is a
critical incident requiring rapid diagnosis.

*Likely follow-up:* "How do you prevent this from happening in CI?"

**Answer:**
Diagnosis:

Step 1: Read the full exception message. It tells you exactly
what mismatched: missing column, wrong type, missing table. Example:
```
Schema-validation: missing column [email_verified]
in table [users]
```

Step 2: Check the entity diff. The entity has `@Column` on
`emailVerified` but the migration script was not included in the
deployment. OR the migration script was included but failed
silently.

Step 3: Check Flyway migration history:
```sql
SELECT * FROM flyway_schema_history
ORDER BY installed_on DESC LIMIT 10;
```
Was the migration marked as applied? If not: Flyway never ran it.
If yes with success=false: the migration failed and needs repair.

Recovery options depending on the cause:

Cause A - Migration not included in deployment:
Temporarily switch `ddl-auto=none` to allow startup without
validation. Add the migration script, redeploy with `validate`.

Cause B - Migration failed midway:
Manually apply the DDL that succeeded (or roll it back). Run
`flyway repair` to reset the failed migration state. Re-run
Flyway.

Prevention: add a Flyway + Hibernate validate check to the
CI pipeline on a test database that exactly mirrors production
schema. This catches migration-entity mismatches before deployment.

*What separates good from great:* The CI check against a test
database that mirrors production - this is how you prevent this
scenario rather than just recovering from it.

---

**Q5 [MID] - COMPARISON**
When would you choose Liquibase over Flyway?

*Why they ask:* Tests awareness of the ecosystem and trade-off reasoning.

*Likely follow-up:* "Can you roll back a Flyway migration?"

**Answer:**
Flyway and Liquibase solve the same problem with different philosophies.

Choose Flyway when:
- The team is comfortable with SQL and prefers SQL migrations
- Simplicity is valued: Flyway is easy to set up and understand
- Rollback is not required (most teams do forward-only migrations)
- Single database target: Flyway works best with one database type

Choose Liquibase when:
- Database-agnostic changesets are needed: Liquibase generates
  SQL for multiple database types from one XML/YAML changeset
  (useful for products that support PostgreSQL, MySQL, Oracle)
- Rollback support is required: Liquibase changesets declare
  both forward and rollback SQL; Flyway only supports rollback
  in the paid version
- The team uses Liquibase's diff and update commands in development
  to auto-generate migration scripts from entity changes
- Enterprise environments that require detailed change documentation
  (Liquibase changesets support author, comment, labels, contexts)

Flyway rollback: standard Flyway Community Edition does not
support SQL rollback scripts. The pattern for "rollback" in Flyway
is to write a new forward migration (V4) that undoes V3's change.
This is the "always forward" philosophy that many teams find safe.

*What separates good from great:* The database-agnostic changeset
use case for Liquibase - this is a real differentiator for
multi-database products.

---

**Q6 [JUNIOR] - DEBUGGING**
Your Spring Boot application fails to start with
`javax.validation.ValidationException: HV000183:
Unable to load 'javax.el.ExpressionFactory'`. Is this a
schema issue?

*Why they ask:* Tests ability to distinguish between Hibernate
ORM schema validation and Bean Validation framework issues.

*Likely follow-up:* "What is the difference between Hibernate schema validation and Bean Validation?"

**Answer:**
No, this is not a schema issue. This is a Bean Validation
dependency problem unrelated to Hibernate schema management.

The error `Unable to load 'javax.el.ExpressionFactory'` means
the Jakarta EL (Expression Language) library is missing from
the classpath. Bean Validation (Hibernate Validator) needs
EL for constraint message interpolation.

Fix: add the dependency:
```xml
<dependency>
    <groupId>org.glassfish</groupId>
    <artifactId>jakarta.el</artifactId>
</dependency>
```
Or in a pure Spring Boot app that should already have this,
check for dependency exclusions that removed `tomcat-embed-el`.

Hibernate schema validation errors look different:
```
SchemaManagementException:
  Schema-validation: missing column [X] in table [Y]
  Schema-validation: missing table [Y]
  Schema-validation: wrong column type encountered in column [X]
```

These are startup failures from `ddl-auto=validate` when the
entity mapping does not match the database schema.

Bean Validation (`@NotNull`, `@Size`, `@Email` on entity fields)
validates data values at runtime - not at startup. Schema validation
and Bean Validation are entirely separate concerns in Hibernate.

*What separates good from great:* Clearly distinguishing the three
types of "Hibernate validation": schema validation (ddl-auto=validate),
Bean Validation (Hibernate Validator, @NotNull etc.), and Hibernate
entity mapping validation (missing @Column mappings, etc.).

---

**Q7 [STAFF] - BEHAVIORAL**
How would you migrate a critical production table of 500 million
rows to add a NOT NULL column with a default value?

*Why they ask:* Large-table migrations require careful planning
to avoid production downtime.

*Likely follow-up:* "What tools would you use to verify the
migration succeeded without data corruption?"

**Answer:**
Adding a NOT NULL column with a default to a 500M row table is
a multi-step operation in most databases - a direct ALTER TABLE
on PostgreSQL <11 rewrites the entire table (minutes of table lock).

The safe approach for PostgreSQL 11+ (which stores default values
in metadata without rewriting):
```sql
-- In PostgreSQL 11+: this is instant (no table rewrite)
-- because the default is stored in catalog, not in rows
ALTER TABLE orders
    ADD COLUMN processed_at TIMESTAMP
    DEFAULT NULL; -- NOT NULL later, after backfill
-- Note: add as nullable first
```

For PostgreSQL <11 or MySQL (which rewrites the table):

Step 1 (Expand - Migration V10):
```sql
-- Add as nullable (instant, no table rewrite)
ALTER TABLE orders ADD COLUMN processed_at TIMESTAMP;
```

Step 2 (Backfill - Application Code):
```sql
-- Batch UPDATE to avoid locking the table for minutes
-- Process 10,000 rows at a time
UPDATE orders SET processed_at = created_at
WHERE id BETWEEN :startId AND :endId
  AND processed_at IS NULL;
-- Run in loop with 100ms sleep between batches
-- to let other queries run
```

Step 3 (Contract - Migration V11, after backfill verified):
```sql
-- Verify: SELECT COUNT(*) FROM orders WHERE processed_at IS NULL
-- Should return 0
ALTER TABLE orders
    ALTER COLUMN processed_at SET NOT NULL;
-- Adds constraint only - instant if no NULLs remain
```

Verification:
```sql
SELECT COUNT(*) FROM orders WHERE processed_at IS NULL;
-- Must be 0 before adding NOT NULL constraint
-- Compare sample rows: processed_at should equal created_at
SELECT id, created_at, processed_at FROM orders
ORDER BY RANDOM() LIMIT 100;
```

For 500M rows, the batch UPDATE takes hours. Run it during off-peak
hours, monitor progress, and ensure no locks are held between batches.

*What separates good from great:* The multi-step expand-contract
approach with batched backfill, monitoring for lock contention,
and explicit verification before adding the NOT NULL constraint.

---

### ⚖️ Comparison Table

| Setting | Creates Tables | Drops Tables | Production Safe | Best For |
|---------|---------------|--------------|-----------------|----------|
| none | No | No | Yes | Pure Flyway management |
| validate | No | No | Yes | Flyway + verification |
| update | Yes | No | Never | Dev only |
| create | Yes | Yes (on start) | Never | Tests |
| create-drop | Yes | Yes (on stop) | Never | Tests only |

**The deciding factor:**
Production: `validate` + Flyway. Tests: `create-drop` with H2.
Development: `create` against a throwaway Docker database,
or `validate` + Flyway against a dev database for full fidelity.

*(Omit: System Design - ★★☆ keyword)*

*(Omit: Diagram - table and prose are sufficient for schema management)*
