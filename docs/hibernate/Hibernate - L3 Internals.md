---
layout: default
title: "Hibernate - L3 Internals"
parent: "Hibernate"
nav_order: 5
permalink: /hibernate/l3-internals/
---

# Hibernate - L3 Internals

Deep Hibernate internals: entity state machine, dirty
checking, optimistic and pessimistic locking, and cascade
semantics. For engineers who need to understand what
Hibernate does automatically.

---

# Hibernate Session States

**Interview Weight:** intermediate - Entity state transitions
are a common interview topic. Candidates must articulate
the four states and when transitions occur.

---

### 🎯 Model Answer

**30 seconds:**

> Hibernate entities have four states: TRANSIENT (new object,
> not in any session), PERSISTENT (in a session, tracked
> for changes), DETACHED (was persistent, session is now
> closed), REMOVED (scheduled for deletion). Transitions:
> `persist()` = TRANSIENT -> PERSISTENT, `detach()` or
> session close = PERSISTENT -> DETACHED, `merge()` =
> DETACHED -> PERSISTENT (new managed instance), `remove()`
> = PERSISTENT -> REMOVED.

---

### 📘 Concept Explanation

**Entity state machine:**

```
  TRANSIENT                 PERSISTENT
  (new object)              (in session, tracked)
  new Order()    persist()  session.get()
  id = null    ---------->  session tracks all changes
                            first-level cache entry

  PERSISTENT   session     DETACHED
               close()  -> session closed
  or detach()             entity still in memory
               <------     can be reattached via merge()
               merge()

  PERSISTENT   remove()   REMOVED
               -------->  DELETE queued at flush
                          entity still in first-level
                          cache until flush
```

---

### 💻 Code Example

**State transitions and their implications**

```java
@Service
public class OrderStateService {

    @Transactional
    public void demonstrateStates() {
        // TRANSIENT: not associated with any session
        Order order = new Order();
        order.setTotal(BigDecimal.valueOf(100));
        // order is NOT in the L1 cache
        // changes to 'order' not tracked

        // TRANSIENT -> PERSISTENT (via persist)
        em.persist(order);
        // Now: order IS in L1 cache
        // INSERT queued (will execute at flush)
        // order.getId() populated (for SEQUENCE strategy)

        // Modification while PERSISTENT
        order.setStatus(OrderStatus.CONFIRMED);
        // Dirty checking marks this change
        // UPDATE queued for flush (no explicit save() needed)

        // PERSISTENT -> REMOVED
        em.remove(order);
        // DELETE queued at flush
        // order is still in L1 cache but marked REMOVED
    }  // Transaction ends: flush, commit, session closes

    // Detached entity scenario (cross-transaction)
    @Transactional(readOnly = true)
    public Order loadOrder(Long id) {
        return em.find(Order.class, id);
        // PERSISTENT while inside this transaction
    }  // Transaction ends: entity becomes DETACHED

    @Transactional
    public Order updateDetached(Order detachedOrder) {
        // detachedOrder is DETACHED (from a previous session)
        // merge: creates a new PERSISTENT copy
        Order managedOrder = em.merge(detachedOrder);
        // managedOrder: PERSISTENT (in current session)
        // detachedOrder: STILL DETACHED
        managedOrder.setLastModified(LocalDateTime.now());
        // Only managedOrder changes are tracked!
        return managedOrder;
    }
}
```

> **Code walkthrough:** The state transitions follow a
> clear lifecycle. `persist` moves from TRANSIENT to
> PERSISTENT - the entity enters the L1 cache and Hibernate
> starts tracking it. Changes while PERSISTENT are automatically
> detected by dirty checking - no explicit `save()` needed.
> `remove` moves to REMOVED - DELETE is queued but the
> entity stays in the L1 cache until flush (to handle
> further operations in the same transaction). The detached
> scenario illustrates a common mistake: after `merge()`,
> the original `detachedOrder` is still detached. Modifying
> it has no effect. Only `managedOrder` (the return value
> of `merge`) is tracked.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> The DETACHED state is the source of most Hibernate
> confusion. Entities returned from `@Transactional(readOnly = true)`
> methods are detached when the method returns. If the
> caller tries to access a lazy association on the detached
> entity: `LazyInitializationException`. Fix: load required
> associations within the transaction.
>
> The `merge()` return value is often ignored. Callers
> do `em.merge(order)` and then continue working with
> the original `order` (which is still detached). Changes
> to the detached `order` after merge are invisible to
> Hibernate. Always use the return value of `merge()`.

---

### ⚖️ Comparison Table

| State | In Session? | Tracked? | DB Action |
|---|---|---|---|
| TRANSIENT | No | No | None |
| PERSISTENT | Yes | Yes (dirty checking) | INSERT/UPDATE at flush |
| DETACHED | No | No | None until re-merged |
| REMOVED | Yes | Yes | DELETE at flush |

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: What is the difference between detach and
evict in Hibernate?** [INTERNALS]

*Why they ask:* Tests knowledge of session state management.

`em.detach(entity)` (JPA): removes a specific entity from
the current persistence context (session). Entity transitions
from PERSISTENT to DETACHED. Changes made after detach are
not tracked. Lazy associations cannot be loaded after detach
(no session).

`session.evict(entity)` (Hibernate): same as `detach` but
Hibernate-specific API.

`em.clear()` (JPA): evicts ALL entities from the persistence
context. All become DETACHED. Used in batch processing to
prevent memory buildup.

`em.detach` vs `em.clear`:
- `detach`: selective (one entity). Use when you want to
  stop tracking a specific entity while keeping others managed.
- `clear`: bulk (all entities). Use in batch loops to free
  memory after processing each chunk.

*What separates good from great:* Knowing that `detach`
is selective and `clear` is bulk, and that both require
preceding `flush()` to persist any pending changes before
detaching.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with state machine and merge semantics. |
| Hiring Manager | Lead with practical implications (detached LazyInitializationException). |
| Bar Raiser | Lead with detach vs clear in batch processing and merge return value requirement. |

---

---

# Dirty Checking and Automatic Flush

**Interview Weight:** intermediate (★★★) - Dirty checking
is Hibernate's core auto-update mechanism. Questions test:
how dirty checking works, flush modes, and when to use
manual flushing.

---

### 🎯 Model Answer

**30 seconds:**

> Dirty checking: Hibernate snapshots the entity state
> when it enters the session. At flush time, it compares
> current state to the snapshot. If any field changed:
> UPDATE issued. This is automatic - no explicit `save()`
> needed. Flush modes: `AUTO` (flush before queries in
> the same session to ensure visibility), `COMMIT` (flush
> only at commit), `MANUAL` (explicit flush only). Default:
> `AUTO`.

**3 minutes:**

> Dirty checking mechanism:
> 1. Entity loaded into session -> snapshot stored
>    (deep copy of all primitive and value fields)
> 2. Entity fields modified by application code
> 3. At flush time: compare current state with snapshot
> 4. For each changed field: include in UPDATE statement
>
> Performance implication: dirty checking scans all PERSISTENT
> entities in the session at flush time. Sessions with many
> entities have O(n) dirty checking overhead. For large batch
> operations: flush and clear periodically.
>
> Flush modes:
> - `AUTO` (default): flushes when necessary to maintain
>   consistency. Specifically: before a query that might
>   read data modified in the current session.
> - `COMMIT`: flushes only at transaction commit. Faster
>   but risk of reading your own uncommitted data in the
>   same transaction if you query before flush.
> - `MANUAL`: flushes only when explicitly called. Use
>   for read-only sessions where you explicitly want
>   no auto-flushing.

---

### 📘 Concept Explanation

**Dirty checking mechanism:**

```
  When entity enters session (persist or load):
  SNAPSHOT: {id=1, status=PENDING, total=100.00}

  Application modifies entity:
  order.setStatus(COMPLETED)
  order.setTotal(new BigDecimal("95.00"))

  At flush time (dirty check):
  Current: {id=1, status=COMPLETED, total=95.00}
  Snapshot: {id=1, status=PENDING, total=100.00}
  DIFF:     status changed, total changed

  SQL generated:
  UPDATE orders SET status=?, total=? WHERE id=?
  (only changed fields - or all non-null in Hibernate 5,
   only changed in Hibernate 6 with @DynamicUpdate)
```

---

### 💻 Code Example

**Dirty checking patterns and performance**

```java
// AUTOMATIC dirty checking (no save() needed)
@Transactional
public void updateOrderStatus(Long id, OrderStatus status) {
    Order order = em.find(Order.class, id);
    order.setStatus(status);  // Modifying a managed entity
    // No em.merge(), no em.save() needed!
    // At commit: Hibernate detects change and issues UPDATE
}

// @DynamicUpdate: only update changed columns
// (useful for wide tables with many columns)
@Entity
@DynamicUpdate  // Hibernate-specific annotation
public class Order {
    // Without @DynamicUpdate:
    // UPDATE orders SET col1=?, col2=?, ..., col50=? WHERE id=?
    // (all columns included even if only 1 changed)

    // With @DynamicUpdate:
    // UPDATE orders SET status=? WHERE id=?
    // (only changed column)
}

// FlushMode control for read-only sessions
@Service
public class ReportingService {

    @Transactional(readOnly = true)
    public List<OrderSummary> generateReport() {
        // readOnly=true: Spring sets FlushMode.NEVER
        // Hibernate will not dirty check - no accidental UPDATEs
        // Faster: no snapshot comparison overhead

        // Safe: even if you accidentally modify an entity,
        // no UPDATE is issued
        return em.createQuery(
            "SELECT o FROM Order o JOIN FETCH o.customer",
            Order.class)
            .getResultList()
            .stream()
            .map(OrderSummary::from)
            .collect(toList());
    }
}
```

> **Code walkthrough:** `@DynamicUpdate` is a Hibernate
> optimization for entities with many columns. Without it:
> Hibernate uses a prepared statement that updates ALL columns
> (Hibernate caches the UPDATE statement per entity class).
> With `@DynamicUpdate`: Hibernate generates a new UPDATE
> statement per flush that includes only changed columns.
> The trade-off: `@DynamicUpdate` prevents prepared statement
> caching (a new statement is built each time), adding
> slight overhead. Worthwhile for very wide tables or when
> only 1-2 fields change frequently. `@Transactional(readOnly=true)`:
> Spring sets the Hibernate flush mode to `MANUAL`/`NEVER`.
> No dirty checking at all - better performance for read-only
> operations.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> The `@Transactional(readOnly=true)` optimization is
> underused. It tells Hibernate: "this transaction will
> not modify entities." Hibernate skips dirty checking
> at flush time and does not take out write locks. This
> is a significant performance improvement for read-heavy
> services. Always use `readOnly=true` on `@Transactional`
> methods that only read data.
>
> Snapshot memory: Hibernate stores a snapshot (copy of
> all primitive/value fields) for each PERSISTENT entity.
> For 10,000 entities in a long-running session: 10,000
> snapshots in memory. This is an additional reason to
> use `flush()`+`clear()` in batch operations.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: What is FlushMode.COMMIT vs FlushMode.AUTO,
and when would you use COMMIT?** [INTERNALS + TRADE-OFF]

`AUTO` (default): Hibernate flushes before any query that
might read data dirtied in the current session. This ensures
that if you persist an entity and then query for it in
the same session, you see the persisted data.

Example where AUTO flushes:
```java
em.persist(new Order(...));  // INSERT queued
// AUTO: flush before the next query on orders
// to ensure the new order is visible:
List<Order> orders = em.createQuery("FROM Order").getResultList();
// new order IS in the result
```

`COMMIT`: flushes only at transaction commit. Does NOT
flush before queries. Faster but: queries in the same
session may NOT see entities persisted/modified earlier
in that session.

When to use COMMIT:
- Batch jobs where you modify entities and never query
  the same entities in the same session
- Reduces flush frequency: faster for write-heavy sessions
  where you commit at the end

When NOT to use COMMIT:
- If you persist data and then query it in the same session,
  the query will not see the new data (still unflushed)

*What separates good from great:* Providing a concrete
example where `COMMIT` mode causes incorrect results
(persist then query = missing the newly persisted data)
and the specific batch job context where COMMIT is safe.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with dirty checking mechanism and snapshot. |
| Hiring Manager | Lead with readOnly=true performance benefit. |
| Bar Raiser | Lead with FlushMode.COMMIT vs AUTO and @DynamicUpdate trade-off. |

---

---

# Optimistic Locking with @Version

**Interview Weight:** intermediate (★★★) - Optimistic
locking is the preferred concurrency strategy for
read-heavy workloads. Questions test: how @Version works,
OptimisticLockException handling, and comparison with
pessimistic locking.

---

### 🎯 Model Answer

**30 seconds:**

> `@Version` enables optimistic locking: a version column
> (integer or timestamp) is incremented on each UPDATE.
> If two transactions read the same entity and both try
> to update it, the second UPDATE fails because the version
> no longer matches: `OptimisticLockException`. No database
> locks held during the transaction. Best for read-heavy
> workloads with rare conflicts. The application must handle
> `OptimisticLockException` (retry or user-facing error).

**3 minutes:**

> Optimistic locking workflow:
> 1. Transaction A reads Order#1: `{version=1, status=PENDING}`
> 2. Transaction B reads Order#1: `{version=1, status=PENDING}`
> 3. Transaction A updates: `UPDATE orders SET status=CONFIRMED, version=2 WHERE id=1 AND version=1`
>    -> success (version matched)
> 4. Transaction B updates: `UPDATE orders SET status=CANCELLED, version=2 WHERE id=1 AND version=1`
>    -> 0 rows affected (version is now 2, not 1)
>    -> Hibernate throws `OptimisticLockException`
>
> The WHERE clause `AND version = ?` is the lock mechanism.
> No row-level locks are held. Concurrent reads are never
> blocked.
>
> Timestamp version: use `@Version private Instant lastModified`
> for audit + optimistic locking in one field. Risk: timestamp
> granularity (two transactions in the same millisecond
> may not conflict correctly). Integer version is more
> reliable.

---

### 💻 Code Example

**@Version optimistic locking with retry**

```java
@Entity
public class Order {
    @Id @GeneratedValue private Long id;

    @Version
    private Long version;  // incremented by Hibernate on UPDATE

    private OrderStatus status;
    private BigDecimal total;
}

// Service: handle OptimisticLockException with retry
@Service
public class OrderService {

    @Retryable(
        value = OptimisticLockException.class,
        maxAttempts = 3,
        backoff = @Backoff(delay = 100,
                           multiplier = 2))
    @Transactional
    public void confirmOrder(Long orderId) {
        Order order = em.find(Order.class, orderId);
        if (order.getStatus() != OrderStatus.PENDING) {
            throw new IllegalStateException(
                "Order not in pending state");
        }
        order.setStatus(OrderStatus.CONFIRMED);
        // At flush: UPDATE orders SET status=?, version=?
        //           WHERE id=? AND version=?
        // If version mismatch: OptimisticLockException
        // -> @Retryable retries up to 3 times
    }

    @Recover
    public void recoverConfirmOrder(
        OptimisticLockException ex, Long orderId) {
        // Called after all retries exhausted
        throw new ConcurrentModificationException(
            "Order " + orderId + " modified concurrently",
            ex);
    }
}
```

> **Code walkthrough:** `@Version` on `Long version` is
> the simplest and most reliable optimistic locking setup.
> Hibernate automatically includes `AND version = ?` in
> every UPDATE and increments the version on success.
> The `@Retryable` from Spring Retry catches
> `OptimisticLockException` and retries the entire
> `@Transactional` method. On retry: the entity is loaded
> fresh (new session, new version), avoiding the stale
> state that caused the conflict. After 3 failed retries:
> `@Recover` handles the case and throws a user-friendly
> exception. The retry-with-reload pattern is the correct
> response to optimistic lock conflicts for non-interactive
> operations.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**

> `@Version` is my default for all entities that are
> modified concurrently. It is free to read (no lock),
> rarely fails in practice (most updates are non-conflicting),
> and the failure is recoverable (retry or user feedback).
>
> Pessimistic locking is better when: conflict probability
> is high (multiple workers competing for the same task),
> retry is expensive or not possible (user-interactive
> update with complex form state), or operation time is
> very short (low cost to hold the lock).
>
> The timestamp version pitfall: clock skew in distributed
> systems can cause timestamp version conflicts to be missed
> if two nodes have slightly different clocks. Integer version
> is monotonically increasing and immune to clock skew.

---

### ⚖️ Comparison Table

| Strategy | Lock Held? | Read Blocked? | Best For |
|---|---|---|---|
| Optimistic (@Version) | No | No | Read-heavy, rare conflicts |
| Pessimistic (WRITE) | Yes (row lock) | Depends on isolation | High conflict, short ops |
| Pessimistic (READ) | Shared lock | No | Prevent concurrent writes |
| No locking | No | No | Read-only data |

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: What happens when an OptimisticLockException
is thrown mid-transaction?** [FAILURE MODE]

`OptimisticLockException` is thrown during flush (when
Hibernate issues the UPDATE and receives 0 rows affected).
At this point:

1. The current `EntityManager`/session is marked as rolled
   back. It CANNOT be used further. Any subsequent operation
   on the same EM throws `IllegalStateException`.
2. The transaction is rolled back.
3. The application must start a NEW transaction with a
   NEW `EntityManager`.

This is why `@Retryable` works: Spring creates a new
transaction and new `EntityManager` on each retry attempt.
The retried transaction loads fresh entity state (new version
number from DB).

Common mistake: catching `OptimisticLockException` and
continuing in the same transaction:
```java
// BAD: session is poisoned after OptimisticLockException
try {
    order.setStatus(CONFIRMED);
    em.flush();  // throws OptimisticLockException
} catch (OptimisticLockException e) {
    order.setStatus(PENDING);  // session is invalid!
    em.flush();  // IllegalStateException
}
```

Fix: catch at the `@Transactional` boundary, start a
new transaction for retry.

*What separates good from great:* Knowing that the session
is "poisoned" after an `OptimisticLockException` and
cannot be reused - requiring a new transaction and new
EM for retry.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with @Version mechanism and WHERE version=? clause. |
| Hiring Manager | Lead with retry strategy and user experience on conflict. |
| Bar Raiser | Lead with session poisoning after exception and the new transaction requirement for retry. |

---

---

# Pessimistic Locking Strategies

**Interview Weight:** intermediate (★★★) - Pessimistic
locking is for high-conflict scenarios. Questions test:
LockModeType options, when to use PESSIMISTIC_WRITE vs
READ, deadlock prevention, and timeout.

---

### 🎯 Model Answer

**30 seconds:**

> Pessimistic locking acquires a database-level lock on
> the row. `PESSIMISTIC_WRITE`: exclusive lock, no concurrent
> reads OR writes. `PESSIMISTIC_READ`: shared lock, concurrent
> reads allowed, no concurrent writes. Use pessimistic
> locking when: conflict rate is high, operation duration
> is short, and you cannot tolerate the retry cost of
> optimistic locking. Always set a lock timeout to avoid
> indefinite blocking.

---

### 💻 Code Example

**Pessimistic locking with timeout**

```java
@Service
public class InventoryService {

    // PESSIMISTIC_WRITE: exclusive lock
    // Use case: inventory deduction (high conflict, short op)
    @Transactional
    public void reserveInventory(Long productId, int qty) {
        Product product = em.find(
            Product.class, productId,
            LockModeType.PESSIMISTIC_WRITE,
            Map.of("javax.persistence.lock.timeout", 3000L));
            // timeout: 3000ms - fail fast if locked
        // Row is now exclusively locked: no other tx can
        // read OR write this row until this tx commits

        if (product.getQuantity() < qty) {
            throw new InsufficientInventoryException();
        }
        product.setQuantity(product.getQuantity() - qty);
        // Unlock when transaction commits
    }

    // Spring Data JPA: pessimistic lock in repository
    @Repository
    public interface ProductRepository
        extends JpaRepository<Product, Long> {

        @Lock(LockModeType.PESSIMISTIC_WRITE)
        @Query("SELECT p FROM Product p WHERE p.id = :id")
        Optional<Product> findByIdForUpdate(
            @Param("id") Long id);
    }
}
```

> **Code walkthrough:** `PESSIMISTIC_WRITE` issues a
> `SELECT ... FOR UPDATE` (PostgreSQL/MySQL). This acquires
> a row-level exclusive lock. The lock is held until the
> transaction commits or rolls back. The 3000ms timeout
> prevents indefinite blocking: if the row is already
> locked by another transaction, this call fails after
> 3 seconds with `LockTimeoutException`. Without a timeout:
> the transaction waits indefinitely, consuming a thread
> and a connection. In high-concurrency scenarios, this
> leads to connection pool exhaustion. Always set a lock
> timeout.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> Deadlock prevention with pessimistic locks: always acquire
> multiple locks in the same order across all transactions.
> If Transaction A always locks Product before Inventory,
> and Transaction B also always locks Product before
> Inventory, there is no deadlock. If A locks Product then
> Inventory while B locks Inventory then Product: deadlock.
>
> Prefer optimistic locking for most scenarios. Pessimistic
> locking holds DB locks for the duration of the transaction,
> reducing throughput. Use it when: inventory deduction
> (concurrent reads + immediate deduction), seat reservation,
> or any operation where "read, check, then update atomically"
> is required with high concurrent contention.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: What is the difference between PESSIMISTIC_WRITE
and PESSIMISTIC_READ, and when would you use each?**
[TRADE-OFF]

`PESSIMISTIC_WRITE` (SELECT FOR UPDATE):
- Exclusive lock: no other transaction can read OR write
- Use when: you will update the row and need exclusive access
- Example: inventory deduction, balance update

`PESSIMISTIC_READ` (SELECT FOR SHARE / LOCK IN SHARE MODE):
- Shared lock: other transactions CAN read, but no transaction can write
- Use when: you need to ensure the row is not modified while you read it,
  but don't plan to update it yourself
- Example: reading a bank account balance that another
  service cannot modify while you make a decision

In practice: `PESSIMISTIC_WRITE` is more common because
it prevents both reads and writes from competing transactions.
`PESSIMISTIC_READ` is a niche use case where multiple
readers need to coordinate against a single potential writer.

*What separates good from great:* `PESSIMISTIC_FORCE_INCREMENT`
as a third option: like PESSIMISTIC_WRITE but also increments
the `@Version` field. Use when you need both pessimistic
locking AND audit trail via version increment.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with SELECT FOR UPDATE SQL and lock timeout. |
| Hiring Manager | Lead with use cases for pessimistic vs optimistic. |
| Bar Raiser | Lead with deadlock prevention (consistent lock ordering) and PESSIMISTIC_FORCE_INCREMENT. |

---

---

# Cascade Types and Orphan Removal

**Interview Weight:** intermediate - Cascade types determine
how operations propagate through relationships. Questions
target: each cascade type's effect, when `CascadeType.ALL`
is dangerous, and `orphanRemoval` semantics.

---

### 🎯 Model Answer

**30 seconds:**

> Cascade types: `PERSIST` (persist child when parent is
> persisted), `MERGE` (merge child when parent is merged),
> `REMOVE` (delete child when parent is deleted), `REFRESH`
> (refresh child when parent is refreshed), `DETACH`,
> and `ALL` (all of the above). `orphanRemoval = true`:
> if a child is removed from the parent's collection,
> Hibernate issues a DELETE for that child. Use `CascadeType.ALL`
> only for owned, private aggregates (OrderItem belongs
> to Order). Never cascade REMOVE to shared entities
> (deleting an Order should not delete the Customer).

---

### 💻 Code Example

**Cascade types with correct usage**

```java
// GOOD: CascadeType.ALL for owned private aggregate
@Entity
public class Order {

    // OrderItems are owned by Order: lifecycle tied to Order
    @OneToMany(mappedBy = "order",
               cascade = CascadeType.ALL,  // all operations
               orphanRemoval = true)  // remove from collection = DELETE
    private List<OrderItem> items = new ArrayList<>();

    // Adding an item: no explicit persist needed
    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);
        // CascadeType.PERSIST: when Order is persisted,
        // all items are also persisted
    }

    // Removing an item: orphanRemoval handles DELETE
    public void removeItem(OrderItem item) {
        items.remove(item);
        item.setOrder(null);
        // orphanRemoval: item is now orphaned
        // Hibernate issues DELETE for the removed item
    }
}

// BAD: CascadeType.REMOVE on shared entities
@Entity
public class Order {
    // DANGEROUS: deleting an Order would delete the Customer!
    @ManyToOne(cascade = CascadeType.REMOVE)  // NEVER DO THIS
    private Customer customer;
    // One customer has many orders.
    // CascadeType.REMOVE would delete the customer when any
    // order is deleted!
}

// CORRECT: no cascade on shared references
@Entity
public class Order {
    @ManyToOne(fetch = FetchType.LAZY)  // no cascade
    @JoinColumn(name = "customer_id")
    private Customer customer;
    // Customer has its own lifecycle; Order just references it
}
```

> **Code walkthrough:** `CascadeType.ALL` is correct for
> `OrderItem` because it is an owned component: it exists
> only as part of an `Order`. Persisting, merging, refreshing,
> or removing an `Order` should do the same to its items.
> `orphanRemoval = true` goes further: removing an item
> from the `items` collection (even without removing the
> `Order`) issues a DELETE for the orphaned item.
> The `CascadeType.REMOVE` on `@ManyToOne` to `Customer`
> is the classic dangerous mistake: deleting one order
> would cascade to delete the customer and then ALL the
> customer's orders (or fail with FK constraint violations).
> Never cascade REMOVE to shared entities.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> My rule for cascades: `CascadeType.ALL + orphanRemoval=true`
> only for private, owned aggregates where the child cannot
> exist without the parent and is not shared with anyone
> else. `PERSIST + MERGE` (without REMOVE) for cases where
> you want to automatically save children when saving the
> parent, but not delete them when deleting the parent.
>
> The difference between `CascadeType.REMOVE` and
> `orphanRemoval`: `REMOVE` cascades the `em.remove(parent)` call.
> `orphanRemoval` responds to collection membership changes.
> Both cause DELETE. `ALL` includes `REMOVE`. `ALL +
> orphanRemoval` is the most complete ownership model.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: What is the difference between CascadeType.REMOVE
and orphanRemoval = true?** [INTERNALS]

`CascadeType.REMOVE`: cascades the `em.remove(parentEntity)`
operation to child entities. If the parent entity is
explicitly removed, all children are also removed.

`orphanRemoval = true`: triggered when a child entity is
removed from the parent's collection (even without removing
the parent). The child becomes "orphaned" and Hibernate
issues a DELETE.

Example difference:
```java
Order order = em.find(Order.class, id);
OrderItem item = order.getItems().get(0);

// CascadeType.REMOVE (without orphanRemoval):
em.remove(order);  // -> DELETEs order AND items
order.getItems().remove(item);  // -> NO DELETE (just removes from collection)

// orphanRemoval = true:
em.remove(order);  // -> DELETEs order AND items
order.getItems().remove(item);  // -> DELETEs the item (orphan!)
```

When to use each:
- `CascadeType.REMOVE` only: parent deletion cascades,
  but removing from collection does not delete
- `orphanRemoval = true` alone: collection removal deletes,
  but parent deletion does not cascade to children
  (unusual combination, use `ALL + orphanRemoval` usually)
- `CascadeType.ALL + orphanRemoval`: full ownership -
  all operations cascade, and orphaned children are deleted

*What separates good from great:* The concrete example
showing that `CascadeType.REMOVE` does NOT respond to
collection removal - only `orphanRemoval` does. Candidates
who confuse the two give wrong answers about what causes
a DELETE.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with cascade type definitions and safe usage. |
| Hiring Manager | Lead with CascadeType.REMOVE on shared entities danger. |
| Bar Raiser | Lead with distinction between CascadeType.REMOVE and orphanRemoval with code examples. |
