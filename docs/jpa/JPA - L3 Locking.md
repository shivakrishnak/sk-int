---
layout: default
title: "JPA - L3 Locking"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 7
permalink: /jpa/l3-locking/
render_with_liquid: false
---

# JPA - L3 Locking

## Optimistic Locking: @Version and Conflict Resolution

### 🎯 Model Answer

**30 seconds:**
> Optimistic locking: assume no conflict. Load entity, modify, try to save. On save: check that the
> version column hasn't changed since load. If changed: someone else modified it - throw
> `OptimisticLockException`. Use `@Version` field (integer or timestamp). Best for low-contention
> scenarios: reads >> writes on the same row.

**3 minutes (Senior):**
> How `@Version` works:
>
> 1. **Load**: `SELECT id, name, version FROM products WHERE id = 1`. Returns version=5.
>
> 2. **Modify**: change fields in memory.
>
> 3. **Flush**: Hibernate generates: `UPDATE products SET name=?, version=6 WHERE id=1 AND version=5`.
>    The WHERE clause includes the version check. This is the optimistic lock.
>
> 4. **If rows updated = 1**: success. Version bumped to 6.
>
> 5. **If rows updated = 0**: someone else updated the row (version changed). Hibernate throws
>    `OptimisticLockException` (wraps `StaleObjectStateException`). Spring: rethrows as
>    `ObjectOptimisticLockingFailureException`.
>
> 6. **Conflict resolution**: caller must catch the exception and decide: retry with fresh data,
>    merge the changes (application-level), or fail with user-facing error.
>
> Timestamp vs integer version: integer (auto-increment): reliable (DB handles increment).
> Timestamp: granularity issues (two updates in the same millisecond: no conflict detected).
> Prefer integer.

**Blank Mind Recovery:**

**(1) Restate:** "@Version adds version column. UPDATE ... WHERE id=? AND version=N. Rows=0: conflict -> OptimisticLockException. Retry or fail. Integer @Version preferred over Timestamp."

**(2) First principles:** "Read-modify-write cycle. Between read and write: another writer may have changed the row. Optimistic locking: detect this at write time (compare version). Cheaper than pessimistic locking (no DB locks held during user think time)."

**(3) Bridge:** "Optimistic locking is like two people editing a Google Doc while offline. When you sync: 'this section was edited since you last synced' conflict. You resolve and try again."

---

### 📘 Concept Explanation

**@Version mechanics and conflict resolution strategies:**
```
@VERSION SETUP AND BEHAVIOR:

  @Entity
  public class Product {
      @Id @GeneratedValue Long id;
      String name;
      BigDecimal price;
      
      @Version
      private int version;  // managed by Hibernate: DO NOT set manually
  }
  
  // Load:
  // SELECT id, name, price, version FROM products WHERE id = 1
  // Returns: Product(id=1, name="Widget", price=9.99, version=5)
  
  // Concurrent scenario:
  //   Session A: loads Product(version=5). Sets price=10.99.
  //   Session B: loads Product(version=5). Sets price=8.99.
  //   Session A commits:
  //     UPDATE products SET price=10.99, version=6 WHERE id=1 AND version=5
  //     Rows updated: 1. Success. DB: version=6, price=10.99.
  //   Session B commits:
  //     UPDATE products SET price=8.99, version=6 WHERE id=1 AND version=5
  //     Rows updated: 0. CONFLICT! version changed from 5 to 6.
  //     Hibernate: throws OptimisticLockException.

EXCEPTION HANDLING:

  @Transactional
  public Product updatePrice(Long id, BigDecimal newPrice) {
      Product p = productRepository.findById(id).orElseThrow();
      p.setPrice(newPrice);
      return productRepository.save(p);
      // If concurrent modification: OptimisticLockException on commit.
  }
  
  // Caller: handle conflict with retry:
  public Product updatePriceWithRetry(Long id, BigDecimal price, int maxRetries) {
      for (int attempt = 0; attempt < maxRetries; attempt++) {
          try {
              return updatePrice(id, price);
          } catch (ObjectOptimisticLockingFailureException e) {
              if (attempt == maxRetries - 1) throw e;
              // Wait with exponential backoff:
              try {
                  Thread.sleep(50L * (1L << attempt));  // 50ms, 100ms, 200ms...
              } catch (InterruptedException ie) {
                  Thread.currentThread().interrupt();
                  throw new RuntimeException(ie);
              }
          }
      }
      throw new IllegalStateException("Should not reach here");
  }

OPTIMISTIC LOCKING FOR DETACHED ENTITIES (REST API pattern):

  // REST pattern: client loads entity, user edits, client submits.
  // Between load and submit: another user may have modified the entity.
  
  // Response DTO includes version:
  public record ProductDto(Long id, String name, BigDecimal price, int version) {}
  
  // Update endpoint:
  @PutMapping("/products/{id}")
  public ResponseEntity<ProductDto> updateProduct(
          @PathVariable Long id,
          @RequestBody ProductDto dto) {
      try {
          Product updated = productService.updateProduct(id, dto);
          return ResponseEntity.ok(ProductDto.from(updated));
      } catch (ObjectOptimisticLockingFailureException e) {
          // 409 Conflict: tell client to reload and retry:
          return ResponseEntity.status(HttpStatus.CONFLICT)
              .header("X-Conflict-Reason", "Product modified by another user")
              .build();
      }
  }
  
  // Service: apply version from DTO before merge:
  @Transactional
  public Product updateProduct(Long id, ProductDto dto) {
      Product p = productRepository.findById(id).orElseThrow();
      if (p.getVersion() != dto.version()) {
          // Version already changed: fail fast (no need to wait for flush):
          throw new ObjectOptimisticLockingFailureException(Product.class, id);
      }
      p.setName(dto.name());
      p.setPrice(dto.price());
      // On commit: Hibernate checks version again in the UPDATE WHERE clause.
      return p;
  }
```

---

### 💻 Code Example

> **Code walkthrough:** The REST API pattern shows how the `version` field travels in the DTO.
> The service does an early version check before modifying (fail-fast) and Hibernate does a final
> check on commit (the UPDATE WHERE version=N). Two layers of protection.

```java
// WRONG: Updating without version tracking:
@Transactional
public Product updatePriceWrong(Long id, BigDecimal price) {
    Product p = productRepository.findById(id).orElseThrow();
    p.setPrice(price);
    return p;
    // No @Version on Product.
    // Concurrent update: last write wins. No conflict detected. Silent data loss.
}

// RIGHT: With @Version and conflict handling:
@Entity
public class Product {
    @Id @GeneratedValue Long id;
    String name;
    BigDecimal price;
    
    @Version int version;  // Hibernate manages this
}

@Transactional
public Product updatePrice(Long id, BigDecimal price) {
    Product p = productRepository.findById(id).orElseThrow();
    p.setPrice(price);
    return p;
    // On commit: UPDATE products SET price=?, version=N+1 WHERE id=? AND version=N
    // Rows=0: OptimisticLockException. Concurrent write detected.
}

// Application retry loop:
@Retryable(
    value = ObjectOptimisticLockingFailureException.class,
    maxAttempts = 3,
    backoff = @Backoff(delay = 100, multiplier = 2))
public Product updateWithRetry(Long id, BigDecimal price) {
    return updatePrice(id, price);
}
// Spring-retry: @Retryable handles the exception, retries up to 3 times.
// Requires: spring-retry + @EnableRetry on config class.
```

> **Code walkthrough:** The `@Entity` with `@Version int version` is the complete setup - Hibernate
> handles incrementing the version automatically. The `@Retryable` annotation from Spring Retry
> is an elegant alternative to manual retry loops: it intercepts `ObjectOptimisticLockingFailureException`
> and retries the method with exponential backoff. The `updateWithRetry` method is clean because the
> retry logic is declarative (annotation), not inline.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Add `@Version int version` to the entity. Hibernate adds `AND version=N` to UPDATE statements.
> If concurrent modification: `ObjectOptimisticLockingFailureException`. Catch in the controller:
> return HTTP 409 Conflict. Good for: read-heavy data with occasional writes. Bad for: hot rows
> with many concurrent writers (constant conflicts, constant retries).

---

**Senior / Staff (5+ years):**
> Optimistic locking at scale: high contention on a row (e.g., a counter) causes high retry rates.
> Alternative: database-side increment (`UPDATE table SET count = count + 1 WHERE id = ?`), which
> is atomic without OCC. For the `version` field in REST APIs: include it in the GET response DTO
> and the PUT request body. The client is responsible for sending back the version it received.
> If omitted: the update silently bypasses the optimistic lock check (the Hibernate version check
> never happens because the entity was loaded fresh in the same transaction).

---

### ⚠️ Common Misconceptions

**Misconception: "Optimistic locking prevents all concurrent data issues."**
Optimistic locking prevents lost updates on a single entity row. It does NOT prevent: (1) phantom
reads (a query returning different row counts across reads in the same transaction - use
`SERIALIZABLE` isolation for that). (2) Write skew (transaction A reads rows X and Y, transaction B
reads rows X and Y, both modify different rows based on the combined read - requires `SERIALIZABLE`
to prevent). (3) Concurrent updates to different entities in the same aggregate (version is per
entity, not per aggregate). For aggregate-level consistency: place `@Version` on the aggregate root
and update the root version whenever any child entity changes.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Optimistic lock exception in UI - user sees "conflict" on every save.**
```
Symptom: users frequently see 409 Conflict errors even when editing different fields.
  Multiple users editing the same product at the same time: frequent failures.

Root cause: Single @Version field for the entire entity.
  User A edits name. User B edits description.
  Both load version=5. A commits (version=6). B commits:
    UPDATE ... WHERE version=5 -> version is 6. Conflict!
  Even though they edited DIFFERENT fields.

Solution options:

1. Accept the conflict and design UI for retry:
   "Another user modified this product. Reload and re-apply changes."
   Simple, correct. Users understand the concept.

2. Field-level versioning (custom):
   Version each major section separately.
   @Version int nameVersion; @Version int descriptionVersion;
   // Not native JPA. Complex. Usually not worth it.

3. Row-level sharding / decompose the entity:
   Split into ProductInfo (name, desc) and ProductPricing (price, SKU).
   Each has its own @Version.
   Edits to info: don't conflict with edits to pricing.

4. Use pessimistic locking for hot entities:
   If contention is guaranteed (multiple concurrent editors): use
   @Lock(LockModeType.PESSIMISTIC_WRITE) to serialize access.
   Simpler conflict resolution (no exception, just wait).
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| @Version mechanics | 2 minutes |
| Optimistic vs pessimistic locking | 2 minutes |
| REST API version propagation | 2 minutes |
| Conflict resolution strategies | 2 minutes |
| High-contention scenarios | 1 minute |
| Aggregate root versioning | 1 minute |
| Integer vs timestamp @Version | 1 minute |

---

**Q1 (design): When would you choose optimistic locking vs. pessimistic locking?**

A: Optimistic locking (OCC): choose when conflicts are rare (low contention). No DB locks held
between load and save. Scales well for read-heavy workloads. Conflict detection at commit time.
Requires retry logic in the application. Use for: user-facing update forms (user thinks for
10-30 seconds between load and save), low-traffic entities, any scenario where locks held during
user think time would be unacceptable. Pessimistic locking: choose when conflicts are expected
(high contention). DB row lock acquired at read time (`SELECT ... FOR UPDATE`). Concurrent transactions:
blocked waiting for the lock. No exception on commit; the conflict is serialized. Simpler application
logic (no retry needed). Use for: checkout flows (inventory decrement), financial transactions
(balance debit), any scenario where two concurrent operations would produce an incorrect combined
result and retries are expensive.

*What separates good from great:* The "stale read bypass" in long-running workflows. A user loads
an order form (optimistic locking with version=5). The user fills out the form for 10 minutes.
Another user (admin) updates the order during that time (version becomes 6). The first user submits:
OptimisticLockException. This is correct. But what if the order has been COMPLETED during those 10
minutes? The retry loop would retry, load the completed order, try to update a completed order,
and either fail at a business rule or accidentally re-open a completed order. Optimistic locking:
catches the version conflict. Business logic must handle the state conflict separately. The sequence:
(1) catch OptimisticLockException; (2) reload entity; (3) check current state (still editable?);
(4) if yes: re-apply and retry; (5) if no: return business error to user.

---

---

## Pessimistic Locking: LockModeType and Deadlock Avoidance

### 🎯 Model Answer

**30 seconds:**
> Pessimistic locking: `SELECT ... FOR UPDATE` at load time. Other transactions trying to lock the
> same row: blocked until the lock holder commits/rolls back. JPA: `@Lock(LockModeType.PESSIMISTIC_WRITE)`
> on repository methods. Use for high-contention scenarios (inventory, balance debit). Risk:
> deadlock if two transactions lock rows in different orders.

**3 minutes (Senior):**
> Pessimistic locking types in JPA:
>
> 1. **PESSIMISTIC_WRITE**: `SELECT ... FOR UPDATE`. Exclusive lock. No other transaction can
>    read-with-lock or write the row until this transaction ends.
>
> 2. **PESSIMISTIC_READ**: `SELECT ... FOR SHARE`. Shared lock. Multiple readers can hold the lock
>    simultaneously. Writers are blocked. Less common; often PESSIMISTIC_WRITE is used even for reads.
>
> 3. **PESSIMISTIC_FORCE_INCREMENT**: `SELECT ... FOR UPDATE` + bumps the `@Version` field.
>    Used to force a version increment even if no fields change (to block concurrent changes to
>    a related aggregate).
>
> 4. **Deadlock**: Transaction A locks row X then row Y. Transaction B locks row Y then row X.
>    Both block each other. DB detects deadlock, kills one transaction. Prevent: always lock rows
>    in the same order. Use consistent ID ordering (`ORDER BY id` before locking).

**Blank Mind Recovery:**

**(1) Restate:** "@Lock(PESSIMISTIC_WRITE): SELECT FOR UPDATE. Other transactions: wait. Deadlock: two transactions lock in opposite order. Prevent: always lock in same ID order."

**(2) First principles:** "Lock before read, hold until commit. No concurrent modification possible. Simple correctness. Cost: blocking. Deadlock: circular wait. Prevention: consistent lock ordering."

**(3) Bridge:** "Pessimistic locking is like a single-stall bathroom. One person at a time. Everyone else queues outside. Fast if the queue is short; slow if many people need it. Deadlock: two people each inside a stall waiting for the other stall to be free."

---

### 📘 Concept Explanation

**Pessimistic lock modes and deadlock prevention:**
```
PESSIMISTIC LOCKING WITH @LOCK:

  // Repository method with pessimistic lock:
  @Repository
  public interface InventoryRepository extends JpaRepository<Inventory, Long> {
      
      @Lock(LockModeType.PESSIMISTIC_WRITE)
      @Query("SELECT i FROM Inventory i WHERE i.productId = :productId")
      Optional<Inventory> findByProductIdForUpdate(@Param("productId") Long productId);
  }
  
  // Service: decrement inventory (must be exclusive):
  @Transactional
  public void decrementInventory(Long productId, int quantity) {
      // SELECT ... FOR UPDATE: acquires DB row lock.
      // Other transactions calling decrementInventory for the same productId:
      //   blocked here until this transaction commits or rolls back.
      Inventory inv = inventoryRepository
          .findByProductIdForUpdate(productId)
          .orElseThrow(() -> new NoInventoryException(productId));
      
      if (inv.getQuantity() < quantity) {
          throw new InsufficientStockException(productId, quantity);
      }
      inv.setQuantity(inv.getQuantity() - quantity);
      // No @Version needed: DB lock ensures exclusive access.
  }  // Transaction commits: lock released.

DEADLOCK SCENARIO AND PREVENTION:

  // BAD: inconsistent lock ordering -> deadlock risk:
  @Transactional
  public void transferBad(Long fromId, Long toId, int amount) {
      // Thread 1: from=1, to=2: locks account 1 first, then account 2.
      // Thread 2: from=2, to=1: locks account 2 first, then account 1.
      // Thread 1 holds account 1, waits for account 2.
      // Thread 2 holds account 2, waits for account 1.
      // DEADLOCK.
      Account from = accountRepo.findByIdForUpdate(fromId);  // locks first
      Account to = accountRepo.findByIdForUpdate(toId);      // locks second
      from.debit(amount);
      to.credit(amount);
  }
  
  // GOOD: always lock in ascending ID order -> no deadlock:
  @Transactional
  public void transfer(Long fromId, Long toId, int amount) {
      // Always lock lower ID first, regardless of transfer direction.
      Long firstId = Math.min(fromId, toId);
      Long secondId = Math.max(fromId, toId);
      
      // Both Thread 1 and Thread 2 lock in the same order (lower ID first).
      // No circular wait possible.
      Account first = accountRepo.findByIdForUpdate(firstId);
      Account second = accountRepo.findByIdForUpdate(secondId);
      
      Account from = (fromId.equals(firstId)) ? first : second;
      Account to = (toId.equals(firstId)) ? first : second;
      
      from.debit(amount);
      to.credit(amount);
  }

LOCK TIMEOUT:

  // Set lock timeout to avoid indefinite blocking:
  @Transactional
  public void decrementWithTimeout(Long productId, int quantity) {
      Map<String, Object> hints = new HashMap<>();
      // javax.persistence.lock.timeout (milliseconds):
      hints.put("javax.persistence.lock.timeout", 5000L);  // 5s timeout
      
      Inventory inv = em.find(
          Inventory.class,
          productId,
          LockModeType.PESSIMISTIC_WRITE,
          hints);
      
      if (inv == null) throw new NoInventoryException(productId);
      // If lock not acquired in 5s: PessimisticLockException (LockTimeoutException).
      // Application can: fail fast, return error, don't wait indefinitely.
      
      inv.decrement(quantity);
  }
```

---

### 💻 Code Example

> **Code walkthrough:** The consistent lock ordering prevents deadlocks by ensuring all threads
> acquire locks in the same sequence. The timeout pattern prevents indefinite blocking when a
> lock cannot be acquired.

```java
// PESSIMISTIC LOCKING FOR CHECKOUT FLOW:

// WRONG: no lock -> race condition (overselling):
@Transactional
public void checkoutWrong(Long productId, int qty, Long userId) {
    Inventory inv = inventoryRepo.findByProductId(productId);
    // Two threads both read inv.quantity = 5, qty = 3.
    // Both see sufficient stock and proceed.
    // Both decrement: inv goes to 2, then to 2 again (second update wins).
    // Result: 6 units sold from 5 units available. Oversold.
    if (inv.getQuantity() < qty) throw new InsufficientStockException();
    inv.setQuantity(inv.getQuantity() - qty);
    orderService.createOrder(productId, qty, userId);
}

// RIGHT: pessimistic write lock:
@Transactional
public void checkout(Long productId, int qty, Long userId) {
    // SELECT ... FOR UPDATE: only one thread proceeds at a time.
    Inventory inv = inventoryRepo.findByProductIdForUpdate(productId);
    
    if (inv.getQuantity() < qty) {
        throw new InsufficientStockException(productId, qty);
    }
    inv.setQuantity(inv.getQuantity() - qty);
    orderService.createOrder(productId, qty, userId);
    // Transaction commits: lock released.
    // Next thread: acquires lock, reads fresh quantity (already decremented).
}

// Repository:
public interface InventoryRepository extends JpaRepository<Inventory, Long> {
    
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM Inventory i WHERE i.productId = :productId")
    Optional<Inventory> findByProductIdForUpdate(@Param("productId") Long id);
}
```

> **Code walkthrough:** The wrong version has a classic check-then-act race condition: two threads
> both check the inventory, both see sufficient stock, and both proceed - overselling. The correct
> version uses `PESSIMISTIC_WRITE` to serialize access. `SELECT ... FOR UPDATE` ensures only one
> transaction reads the inventory row at a time; the second must wait until the first commits. After
> the first commits (inventory decremented), the second reads the updated quantity and may throw
> `InsufficientStockException`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `@Lock(LockModeType.PESSIMISTIC_WRITE)` on repository methods: generates `SELECT ... FOR UPDATE`.
> Prevents concurrent modification. Use for inventory decrement, balance operations. Risk: deadlocks
> if locking multiple rows in different orders. Use timeout to avoid indefinite waits.

---

**Senior / Staff (5+ years):**
> Pessimistic locking + `REQUIRES_NEW` propagation: the lock is held for the duration of the
> REQUIRES_NEW inner transaction only. Can be useful for fine-grained lock scoping. For
> microservices: pessimistic DB locking doesn't span services. Use saga pattern + compensating
> transactions for cross-service consistency. For dead-lock avoidance in complex scenarios: single
> dedicated "lock manager" table with row-level locks by resource ID (insert lock record with
> unique constraint, delete on release) as an alternative to table-level DB locks.

---

### ⚠️ Common Misconceptions

**Misconception: "Pessimistic locking is always worse than optimistic locking for performance."**
For read-heavy, low-conflict scenarios: true. Pessimistic locking acquires and holds DB locks,
reducing concurrency. But for high-contention scenarios (many concurrent writers on the same row):
optimistic locking produces constant `OptimisticLockException` + retry overhead. Each retry is a
full transaction: SELECT + processing + UPDATE + rollback on conflict. Under high load: a waterfall
of retrying transactions. Pessimistic locking: serializes access, one transaction at a time. No
exceptions, no retries, no rollback overhead. For a checkout flow with 100 concurrent purchases of
the same product: pessimistic locking is often more efficient (99 transactions wait their turn
orderly vs 99 transactions each doing 3-5 retries with rollbacks).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Application deadlock under production load.**
```
Symptom: periodic transaction failures with DeadlockLoserDataAccessException.
  Log: "Deadlock found when trying to get lock; try restarting transaction"
  Inconsistent: happens under load, not reproducible locally.

Root cause: two code paths lock the same rows in different orders.
  Path 1: createOrder() -> locks inventory, then locks account.
  Path 2: refundOrder() -> locks account, then locks inventory.
  Concurrent execution: deadlock.

Diagnosis:
  PostgreSQL: pg_locks + pg_stat_activity to see blocked sessions.
  MySQL: SHOW ENGINE INNODB STATUS -> "LATEST DETECTED DEADLOCK" section.
  Application: log stack traces for all DeadlockLoserDataAccessException.
    Examine the two stack traces: what rows were locked and in what order?

Fix:
  Enforce consistent lock ordering across ALL code paths:
    Always lock account before inventory (or vice versa, but consistently).
  Or: acquire all needed locks upfront in a single query:
    SELECT * FROM accounts, inventory WHERE ... FOR UPDATE
    (locks all rows in one operation: DB handles consistent ordering)
  Or: reduce the number of concurrent locks by redesigning the flow.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| PESSIMISTIC_WRITE mechanics | 2 minutes |
| Optimistic vs pessimistic tradeoffs | 2 minutes |
| Deadlock explanation | 2 minutes |
| Deadlock prevention strategies | 2 minutes |
| Lock timeout | 1 minute |
| Pessimistic locking in microservices | 1 minute |
| SELECT FOR UPDATE vs FOR SHARE | 1 minute |

---

**Q1 (deadlock): Explain how deadlocks happen in JPA/JDBC and how to prevent them.**

A: Deadlock: two transactions each hold a lock the other needs, causing circular wait. Example:
Transaction A holds lock on row X, waiting for row Y. Transaction B holds lock on row Y, waiting
for row X. Neither can proceed. The DB detects the cycle and kills one transaction (the "deadlock
loser"), which receives an error. Prevention strategies: (1) Consistent lock ordering - always
acquire locks on multiple rows in the same order (e.g., always ascending by ID). This eliminates
circular wait. (2) Lock timeout - set `javax.persistence.lock.timeout` (milliseconds). If lock
not acquired in time: fail fast rather than waiting indefinitely. (3) Short transactions - minimize
the time locks are held. Don't hold locks while doing external API calls or complex computations.
(4) Reduce lock contention - partition data to reduce concurrent access to the same rows. (5) Use
optimistic locking for low-contention paths - avoids holding DB locks during user think time.

*What separates good from great:* Deadlock retry as the fallback. Even with consistent lock ordering:
deadlocks can occur due to index-level locking (DB may lock more than just the target row) or due
to code you don't control (third-party libraries, ORM internal operations). Production-hardened code
treats `DeadlockLoserDataAccessException` like `OptimisticLockException`: catch and retry with
backoff. In Spring: `@Retryable(value = {DeadlockLoserDataAccessException.class, ObjectOptimisticLockingFailureException.class})`.
Retry 3 times with 100ms exponential backoff. This handles the "1% of edge cases" where deadlocks
occur despite best prevention. Monitoring: count deadlock retries in production. Rising retry rate
= a new code path locking in incorrect order. Find and fix the source.

