---
layout: default
title: "Hibernate - Locking and Advanced"
parent: "Hibernate"
grand_parent: "Interview Mastery"
nav_order: 7
permalink: /interview/hibernate/locking-and-advanced/
topic: Hibernate
subtopic: Locking and Advanced
keywords:
  - Optimistic Locking
  - Pessimistic Locking
  - Inheritance Mapping Strategies
  - Multi-Tenancy
  - Auditing with Envers and Spring Data
difficulty_range: hard
status: complete
version: 3
---

**Keywords covered in this file:**

- [Optimistic Locking](#optimistic-locking)
- [Pessimistic Locking](#pessimistic-locking)
- [Inheritance Mapping Strategies](#inheritance-mapping-strategies)
- [Multi-Tenancy](#multi-tenancy)
- [Auditing with Envers and Spring Data](#auditing-with-envers-and-spring-data)

# Optimistic Locking

**TL;DR** - Optimistic locking uses a `@Version` column (integer or timestamp) to detect concurrent modifications at commit time - Hibernate adds `WHERE version = N` to UPDATE statements, throwing `OptimisticLockException` if another transaction modified the row first, providing high concurrency without database locks.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Two users edit the same order simultaneously. User A reads price=$100. User B reads price=$100. User A updates price=$120. User B updates price=$90. User B's update silently overwrites User A's change. This is the "lost update" problem.

**THE BREAKING POINT:**
Financial system. Two traders modify the same position. One's trade is silently lost. Incorrect P&L. Audit shows two valid saves but final state matches only one.

**THE INVENTION MOMENT:**
"What if every row had a version counter, and updates only succeed if the version has not changed since you read it?"

---

### 📘 Textbook Definition

Optimistic locking assumes that conflicts are rare and detects them at write time rather than preventing them with locks. JPA's `@Version` annotation marks a field (integer, long, short, or timestamp) as a version counter. Hibernate includes `WHERE id = ? AND version = ?` in every UPDATE. If no rows are updated (version mismatch), an `OptimisticLockException` is thrown. The application catches this and retries or reports the conflict. No database locks are held during the transaction.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
A version counter on each row; UPDATE only succeeds if the version has not changed since you read it.

**One analogy:**

> An edit conflict on Google Docs. You edit a paragraph, but someone else edited it first. Instead of silently overwriting, the system says "conflict detected" and asks you to resolve it. That is optimistic locking.

**One insight:**
Optimistic locking holds NO database locks. Read and write transactions run freely in parallel. Conflicts are detected only at commit. This gives maximum concurrency for read-heavy workloads with rare write conflicts.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. **Version monotonically increases:** Every successful UPDATE increments the version by 1.
2. **Conflict detection at write:** `UPDATE ... WHERE id = ? AND version = ?`. If version changed, 0 rows updated -> exception.
3. **No locks held:** Unlike pessimistic locking, no database row locks are acquired during the transaction.

**THE TRADE-OFFS:**

**Gain:** Maximum read concurrency. No lock waits. No deadlocks.

**Cost:** Write conflicts cause exceptions requiring retry or user intervention. Under high write contention, retry storms can degrade performance.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is:**
A safety mechanism that prevents two people from accidentally overwriting each other's changes to the same database row.

**Level 2 - How to use (junior):**

```java
@Entity
public class Order {
    @Id
    @GeneratedValue
    private Long id;

    @Version
    private Long version;
    // Hibernate manages this field
    // Never set it manually!

    private BigDecimal price;
}
```

What Hibernate generates:

```sql
-- First update:
UPDATE orders
SET price = 120, version = 2
WHERE id = 1 AND version = 1;
-- 1 row updated -> success

-- Concurrent update:
UPDATE orders
SET price = 90, version = 2
WHERE id = 1 AND version = 1;
-- 0 rows updated -> version changed!
-- OptimisticLockException!
```

**Level 3 - How it works (mid-level):**

Version field types:

| Type        | Behavior            |
| ----------- | ------------------- |
| int/Integer | Incremented by 1    |
| long/Long   | Incremented by 1    |
| short/Short | Incremented by 1    |
| Timestamp   | Set to current time |

Handling the exception:

```java
@Transactional
public Order updatePrice(Long id,
        BigDecimal price) {
    try {
        Order order =
            orderRepo.findById(id)
            .orElseThrow();
        order.setPrice(price);
        return orderRepo.save(order);
    } catch (OptimisticLockException e) {
        // Option 1: retry
        // Option 2: return conflict
        throw new ConflictException(
            "Order was modified by "
            + "another user");
    }
}
```

REST API pattern:

```java
// Client sends version in request
@PutMapping("/orders/{id}")
ResponseEntity<Order> update(
    @PathVariable Long id,
    @RequestBody OrderDto dto) {
    Order order =
        orderRepo.findById(id)
        .orElseThrow();
    if (!order.getVersion()
            .equals(dto.getVersion())) {
        return ResponseEntity
            .status(409).build();
    }
    order.setPrice(dto.getPrice());
    return ResponseEntity.ok(
        orderRepo.save(order));
}
```

**Level 4 - Mastery (senior/staff+):**

Versioned merge (detached entity):

```java
// Detached entity with stale version
User detached = // from HTTP request
// detached.version = 3
// DB version = 4 (modified by other)
User managed = em.merge(detached);
em.flush();
// OptimisticLockException!
// merge copies version field
// UPDATE ... WHERE version = 3
// but DB has version = 4 -> 0 rows
```

Without @Version (compare all columns):

```java
@Entity
@DynamicUpdate
@OptimisticLocking(
    type = OptimisticLockType.DIRTY)
public class Order {
    // No @Version field
    // Hibernate compares only
    // CHANGED columns in WHERE clause
    // UPDATE orders SET price = 120
    //   WHERE id = 1 AND price = 100
}
```

Retry pattern with Spring:

```java
@Retryable(
    retryFor =
        OptimisticLockException.class,
    maxAttempts = 3,
    backoff = @Backoff(delay = 100))
@Transactional
public void updateWithRetry(
        Long id, BigDecimal price) {
    Order order =
        orderRepo.findById(id)
        .orElseThrow();
    order.setPrice(price);
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Add `@Version` for concurrent access."

**A Staff says:** "I use `@Version` for all entities exposed to concurrent writes. I implement retry with exponential backoff for automated systems and conflict response (HTTP 409) for user-facing APIs. I understand that detached entities carry stale versions through merge. Under high write contention, I evaluate pessimistic locking as an alternative."

---

### ⚙️ How It Works

```
  TX-A reads Order(id=1, version=1)
  TX-B reads Order(id=1, version=1)
       |
  TX-A: order.setPrice(120)
  TX-A: flush -> UPDATE orders
    SET price=120, version=2
    WHERE id=1 AND version=1
    -> 1 row updated -> SUCCESS
       |
  TX-B: order.setPrice(90)
  TX-B: flush -> UPDATE orders
    SET price=90, version=2
    WHERE id=1 AND version=1 <- HERE
    -> 0 rows updated!
    -> version is now 2, not 1
    -> OptimisticLockException!
```

---

### 💻 Code Example

**BAD no version vs GOOD versioned:**

```java
// BAD - lost update possible
@Entity
public class Account {
    @Id private Long id;
    private BigDecimal balance;
    // No @Version -> concurrent updates
    // silently overwrite each other
}

// GOOD - conflict detected
@Entity
public class Account {
    @Id private Long id;
    @Version private Long version;
    private BigDecimal balance;
    // Concurrent updates detected
    // OptimisticLockException thrown
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Version-based conflict detection at commit time. No database locks.

**KEY INSIGHT:** Maximum concurrency. Conflicts detected, not prevented. Requires retry strategy.

**ANTI-PATTERN:** No @Version on entities with concurrent writes. Ignoring the exception.

**ONE-LINER:** "@Version + WHERE version=N -> 0 rows = conflict."

**If you remember only 3 things:**

1. @Version adds `WHERE version = ?` to every UPDATE
2. Detached entities carry stale versions through merge
3. Implement retry (automated) or HTTP 409 (user-facing) for conflicts

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Silent lost updates**

**Symptom:** Data overwrites without errors.

**Root Cause:** Missing `@Version` on entity.

**Fix:** Add `@Version private Long version;`

**Failure Mode 2: OptimisticLockException storm**

**Symptom:** High retry rate, degraded performance under load.

**Root Cause:** High write contention on same rows (hot rows).

**Fix:** Reduce contention (shard data), increase retry backoff, or switch to pessimistic locking for hot rows.

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: How does optimistic locking work in JPA?**

_Why they ask:_ Core concurrency control.
_Likely follow-up:_ "When would you use pessimistic instead?"

**Answer:**
Add `@Version` (integer or timestamp) to the entity. Hibernate adds `AND version = ?` to every UPDATE. If another transaction modified the row (incrementing version), 0 rows are updated and `OptimisticLockException` is thrown.

No database locks are held. Maximum read concurrency. Conflicts detected at commit time, not prevented.

Use optimistic when: conflicts are rare (most applications). Use pessimistic when: conflicts are frequent (hot rows, financial transactions) or retry is unacceptable (exactlyonce semantics).

_What separates good from great:_ The decision framework for optimistic vs pessimistic.

---

**Q2 [SENIOR - DEBUGGING]: OptimisticLockException in a REST API - how to handle?**

_Why they ask:_ Real production scenario.
_Likely follow-up:_ "How does the client know about the conflict?"

**Answer:**
The entity version should be part of the API contract. Client sends version in the request body or ETag header. Server compares:

```java
if (!entity.getVersion()
        .equals(dto.getVersion())) {
    return ResponseEntity
        .status(HttpStatus.CONFLICT)
        .body("Entity modified by "
            + "another user");
}
```

For automated systems: implement retry with Spring Retry (`@Retryable`) and exponential backoff. For user-facing: return HTTP 409 Conflict with the current entity state so the user can review and re-submit.

ETag approach:

```
GET /orders/1 -> ETag: "3" (version)
PUT /orders/1
  If-Match: "3"
  -> 200 OK (version 4)
  -> or 412 Precondition Failed
```

_What separates good from great:_ The ETag/If-Match HTTP pattern for version negotiation.

---

### 🔗 Related Keywords

**Prerequisites:** ACID Transactions, Entity Lifecycle

**Builds on:** REST API design, Retry patterns

**Alternatives:** Pessimistic Locking (prevents conflicts)

---

---

# Pessimistic Locking

**TL;DR** - Pessimistic locking acquires database row locks (`SELECT ... FOR UPDATE`) when reading data, preventing other transactions from modifying locked rows until the lock is released at commit - guaranteeing no conflicts but reducing concurrency.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT (relying only on optimistic locking):**
A financial system processes account transfers. Two concurrent transfers read the same balance ($1000), each deducts $500, and both commit. Final balance: $500 (should be $0). Optimistic locking detects the conflict but requires retry. In financial systems, "retry" may be unacceptable.

**THE INVENTION MOMENT:**
"Lock the row when you read it. No one else can modify it until you are done."

---

### 📘 Textbook Definition

Pessimistic locking uses database-level row locks (usually `SELECT ... FOR UPDATE`) to prevent concurrent modifications. JPA provides `LockModeType.PESSIMISTIC_READ` (shared lock, allows concurrent reads), `PESSIMISTIC_WRITE` (exclusive lock, blocks reads and writes), and `PESSIMISTIC_FORCE_INCREMENT` (exclusive lock + version increment). Locks are held for the transaction duration and released at commit or rollback.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
`SELECT FOR UPDATE` locks the row so no other transaction can modify it until you commit.

**One analogy:**

> Locking a file on a shared drive. While you have it locked, others can see it exists but cannot edit it. When you close (commit), the lock is released. Others can then open and edit.

**One insight:**
Pessimistic locking trades concurrency for correctness. Under low contention, it is slightly slower than optimistic (lock overhead). Under high contention, it is faster (no retry storms). Decision: rare conflicts -> optimistic. Frequent conflicts or must-not-retry -> pessimistic.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
// EntityManager
User user = em.find(User.class, 1L,
    LockModeType.PESSIMISTIC_WRITE);
// SELECT * FROM users
//   WHERE id=1 FOR UPDATE
user.setBalance(
    user.getBalance().subtract(amount));
// Other TXs wait until this TX commits

// Spring Data
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("SELECT u FROM User u "
    + "WHERE u.id = :id")
Optional<User> findByIdForUpdate(
    @Param("id") Long id);
```

**Level 3 - Lock modes (mid-level):**

| LockModeType                | SQL                    | Blocks         |
| --------------------------- | ---------------------- | -------------- |
| PESSIMISTIC_READ            | FOR SHARE              | Writes only    |
| PESSIMISTIC_WRITE           | FOR UPDATE             | Reads + Writes |
| PESSIMISTIC_FORCE_INCREMENT | FOR UPDATE + version++ | Reads + Writes |

Lock timeout:

```java
Map<String, Object> hints =
    new HashMap<>();
hints.put(
    "javax.persistence.lock.timeout",
    5000); // 5 seconds
User user = em.find(User.class, 1L,
    LockModeType.PESSIMISTIC_WRITE,
    hints);
// Waits max 5s for lock
// Throws LockTimeoutException
// if not acquired
```

**Level 4 - Mastery (senior/staff+):**

Deadlock prevention:

```
  TX-A: lock User 1 -> lock Account 1
  TX-B: lock Account 1 -> lock User 1
  -> DEADLOCK!

  Prevention:
  1. Always lock in consistent order
     (User before Account, alphabetical)
  2. Use lock timeout (fail fast)
  3. Keep transactions short
```

```java
// Lock ordering convention:
@Transactional
public void transfer(Long fromId,
        Long toId, BigDecimal amount) {
    // Always lock lower ID first
    Long first = Math.min(fromId, toId);
    Long second = Math.max(fromId, toId);

    Account a = accountRepo
        .findByIdForUpdate(first);
    Account b = accountRepo
        .findByIdForUpdate(second);

    // Now process transfer
}
```

Skip locked (queue pattern):

```java
// Skip already-locked rows
@Query(value =
    "SELECT * FROM tasks "
    + "WHERE status = 'PENDING' "
    + "LIMIT 1 "
    + "FOR UPDATE SKIP LOCKED",
    nativeQuery = true)
Optional<Task> findNextTask();
// Multiple workers grab different
// tasks without blocking each other
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `FOR UPDATE` to prevent concurrent access."

**A Staff says:** "I use pessimistic locking for: hot rows, financial operations, exactly-once processing. I prevent deadlocks with consistent lock ordering. I set lock timeouts (5s) to fail fast. I use `SKIP LOCKED` for work queue patterns (multiple workers, no contention). I prefer optimistic for most entities and pessimistic only for high-contention or financial rows."

---

### 💻 Code Example

**BAD no lock on financial op vs GOOD pessimistic lock:**

```java
// BAD - race condition
@Transactional
public void transfer(Long fromId,
        Long toId, BigDecimal amt) {
    Account from =
        accountRepo.findById(fromId)
        .orElseThrow();
    Account to =
        accountRepo.findById(toId)
        .orElseThrow();
    from.debit(amt);
    to.credit(amt);
    // Concurrent transfer can read
    // stale balance -> double-spend!
}

// GOOD - locked
@Transactional
public void transfer(Long fromId,
        Long toId, BigDecimal amt) {
    Long first = Math.min(fromId, toId);
    Long second = Math.max(fromId, toId);
    Account a = accountRepo
        .findByIdForUpdate(first);
    Account b = accountRepo
        .findByIdForUpdate(second);
    if (fromId < toId) {
        a.debit(amt); b.credit(amt);
    } else {
        b.debit(amt); a.credit(amt);
    }
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Database row locks preventing concurrent modification during a transaction.

**KEY INSIGHT:** Trades concurrency for correctness. Use for high-contention or financial operations.

**ANTI-PATTERN:** Pessimistic everywhere (kills throughput). No lock timeout (deadlock risk). No lock ordering.

**ONE-LINER:** "FOR UPDATE = exclusive lock. Consistent ordering = no deadlocks. Timeout = fail fast."

**If you remember only 3 things:**

1. PESSIMISTIC_WRITE = FOR UPDATE (exclusive row lock)
2. Always lock in consistent order to prevent deadlocks
3. Set lock timeout (5s) and keep transactions short

---

### 🎯 Interview Deep-Dive

**Q1 [SENIOR]: Optimistic vs pessimistic locking - decision framework?**

_Why they ask:_ Architecture-level decision.
_Likely follow-up:_ "What about distributed systems?"

**Answer:**

| Factor      | Optimistic           | Pessimistic               |
| ----------- | -------------------- | ------------------------- |
| Contention  | Low (rare conflicts) | High (frequent conflicts) |
| Retries     | Acceptable           | Unacceptable              |
| Performance | Higher throughput    | Lower throughput          |
| Deadlocks   | Impossible           | Possible (prevent!)       |
| Complexity  | Retry logic          | Lock ordering             |

Decision: most entities -> optimistic (@Version). Financial/inventory hot rows -> pessimistic (FOR UPDATE). Distributed systems -> neither works across services; use application-level patterns (saga, idempotency keys).

_What separates good from great:_ The decision table and distributed systems caveat.

---

**Q2 [SENIOR - DEBUGGING]: Deadlock detected in production logs. Diagnose.**

_Why they ask:_ Real production problem.
_Likely follow-up:_ "How do you prevent it?"

**Answer:**
Diagnosis:

1. Check database deadlock log (MySQL: `SHOW ENGINE INNODB STATUS`, PostgreSQL: `pg_stat_activity`)
2. Identify the two transactions and the rows they locked
3. Find the lock ordering difference (TX-A: row 1 then row 2; TX-B: row 2 then row 1)

Fix:

1. **Consistent lock ordering:** always lock by ascending ID
2. **Lock timeout:** fail fast instead of waiting indefinitely
3. **Shorter transactions:** reduce lock hold time
4. **SKIP LOCKED:** for queue patterns (workers grab different rows)

_What separates good from great:_ The specific DB diagnostic commands and the lock ordering solution.

---

### 🔗 Related Keywords

**Prerequisites:** Database Locking, ACID Transactions

**Builds on:** Deadlock Prevention, Work Queue Patterns

**Alternatives:** Optimistic Locking (conflict detection)

---

---

# Inheritance Mapping Strategies

**TL;DR** - JPA offers three strategies to map class hierarchies to tables: **SINGLE_TABLE** (one table, discriminator column - best performance), **JOINED** (normalized tables with JOINs), and **TABLE_PER_CLASS** (separate tables, no JOINs but union for polymorphic queries) - each with distinct trade-offs in query performance, data integrity, and schema design.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
`CreditCardPayment`, `BankTransferPayment`, and `CryptoPayment` all extend `Payment`. How do you map this to relational tables? One table with NULLs for irrelevant columns? Separate tables that cannot be queried polymorphically? Normalized tables requiring JOINs?

---

### 📘 Textbook Definition

JPA inheritance mapping defines how an entity class hierarchy maps to database tables. Three strategies exist:

- **SINGLE_TABLE** (default): All classes map to one table with a discriminator column (`DTYPE`). Subclass-specific columns are nullable.
- **JOINED**: Each class maps to its own table. Subclass tables have FK to parent table. Polymorphic queries require JOINs.
- **TABLE_PER_CLASS**: Each concrete class maps to its own table with ALL columns (including inherited). Polymorphic queries use UNION ALL.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
SINGLE_TABLE = fastest queries, nullable columns. JOINED = normalized, JOIN overhead. TABLE_PER_CLASS = independent tables, UNION overhead.

**One insight:**
SINGLE_TABLE is almost always the right choice. The nullable columns feel wrong, but one-table queries are dramatically faster than multi-table JOINs or UNIONs at scale. Only use JOINED when you have strict NOT NULL constraints on subclass fields. Avoid TABLE_PER_CLASS (poor polymorphic query performance, no shared sequences).

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
// SINGLE_TABLE (default)
@Entity
@Inheritance(
    strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "type")
public abstract class Payment {
    @Id @GeneratedValue
    private Long id;
    private BigDecimal amount;
}

@Entity
@DiscriminatorValue("CARD")
public class CreditCardPayment
        extends Payment {
    private String cardNumber;
    private String expiry;
}

@Entity
@DiscriminatorValue("BANK")
public class BankTransferPayment
        extends Payment {
    private String iban;
}
```

Database schema:

```
  payments table:
  | id | type | amount | cardNumber |
  |    |      |        | expiry     |
  |    |      |        | iban       |

  CARD row: iban is NULL
  BANK row: cardNumber, expiry NULL
```

**Level 3 - All three strategies (mid-level):**

| Strategy        | Tables        | Polymorphic Query   | NOT NULL         |
| --------------- | ------------- | ------------------- | ---------------- |
| SINGLE_TABLE    | 1             | Fast (1 table)      | Only parent cols |
| JOINED          | N (per class) | JOIN parent + child | Full support     |
| TABLE_PER_CLASS | N (concrete)  | UNION ALL           | Full support     |

```java
// JOINED
@Entity
@Inheritance(
    strategy = InheritanceType.JOINED)
public abstract class Payment {
    @Id @GeneratedValue
    private Long id;
    private BigDecimal amount;
}

@Entity
public class CreditCardPayment
        extends Payment {
    // Own table: credit_card_payments
    // FK to payments.id
    @Column(nullable = false)
    private String cardNumber;
}

// Query: SELECT p.*, c.*
//   FROM payments p
//   JOIN credit_card_payments c
//   ON p.id = c.id
//   WHERE p.id = ?
```

**Level 4 - Mastery (senior/staff+):**

Performance comparison (1M rows):

```
  SINGLE_TABLE:
    findById -> 1 table scan
    findAll (polymorphic) -> 1 table scan
    INSERT -> 1 INSERT
    Fastest overall

  JOINED:
    findById -> 2 table JOIN
    findAll -> N table JOINs
    INSERT -> 2 INSERTs (parent + child)
    Slower as hierarchy deepens

  TABLE_PER_CLASS:
    findById(subclass) -> 1 table scan
    findAll(parent) -> UNION ALL N tables
    INSERT -> 1 INSERT
    Fast per-subclass, slow polymorphic
```

Alternative: @MappedSuperclass (no polymorphism):

```java
@MappedSuperclass
public abstract class BaseEntity {
    @Id @GeneratedValue
    private Long id;
    @CreationTimestamp
    private Instant createdAt;
}

@Entity
public class User extends BaseEntity {}
@Entity
public class Product extends BaseEntity {}
// No polymorphic queries possible
// No "find all BaseEntities"
// Just shared fields
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use JOINED for normalization."

**A Staff says:** "I default to SINGLE_TABLE for most hierarchies (best performance, simplest queries). I use JOINED only when subclass columns have strict NOT NULL constraints and the hierarchy is shallow (2 levels max). I avoid TABLE_PER_CLASS (poor polymorphic queries). For shared fields without polymorphism, `@MappedSuperclass` is sufficient."

---

### 💻 Code Example

**BAD deep JOINED hierarchy vs GOOD SINGLE_TABLE:**

```java
// BAD - 4-level JOINED hierarchy
// Every query JOINs 4 tables!
@Inheritance(strategy = JOINED)
class Vehicle {} // vehicles table
class Car extends Vehicle {} // + JOIN
class ElectricCar extends Car {} // + JOIN
class Tesla extends ElectricCar {} // +JOIN
// findById -> 4 table JOIN!

// GOOD - flat SINGLE_TABLE
@Inheritance(strategy = SINGLE_TABLE)
@DiscriminatorColumn(name = "type")
class Vehicle {}
class Car extends Vehicle {}
class ElectricCar extends Vehicle {}
// findById -> 1 table, 1 query
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Three strategies mapping class hierarchies to relational tables.

**KEY INSIGHT:** SINGLE_TABLE is almost always right. JOINED for strict NOT NULL. Avoid TABLE_PER_CLASS.

**ANTI-PATTERN:** Deep JOINED hierarchies (4+ JOINs). TABLE_PER_CLASS with polymorphic queries.

**ONE-LINER:** "SINGLE_TABLE = fast + nullable. JOINED = normalized + JOINs. Default to SINGLE_TABLE."

**If you remember only 3 things:**

1. SINGLE_TABLE: one table, discriminator column, best performance
2. JOINED: normalized, FK to parent, JOIN cost per query
3. Default to SINGLE_TABLE unless NOT NULL constraints require JOINED

---

### 🎯 Interview Deep-Dive

**Q1 [SENIOR]: Compare JPA inheritance strategies and when to use each.**

_Why they ask:_ Schema design decision.
_Likely follow-up:_ "What about @MappedSuperclass?"

**Answer:**

| Strategy        | Pros                    | Cons                     | Use When                   |
| --------------- | ----------------------- | ------------------------ | -------------------------- |
| SINGLE_TABLE    | Fastest queries, simple | Nullable subclass cols   | Default choice, most cases |
| JOINED          | Normalized, NOT NULL    | JOIN overhead, slow      | Strict constraints         |
| TABLE_PER_CLASS | Independent tables      | UNION ALL, no shared seq | Rarely                     |

Decision: Start with SINGLE_TABLE. Switch to JOINED only if: (1) subclass columns need NOT NULL, and (2) hierarchy is shallow (2 levels max).

`@MappedSuperclass`: no inheritance mapping at all. Shared fields (id, createdAt) across unrelated entities. No polymorphic queries. Use for base entity classes.

_What separates good from great:_ The decision framework and @MappedSuperclass distinction.

---

### 🔗 Related Keywords

**Prerequisites:** Entity Mapping, SQL Schema Design

**Builds on:** Polymorphism, Domain Modeling

**Related:** @MappedSuperclass, @DiscriminatorColumn

---

---

# Multi-Tenancy

**TL;DR** - Multi-tenancy isolates data between tenants (customers) in a shared application using one of three strategies: separate databases (strongest isolation), separate schemas (good isolation, shared DB), or shared table with discriminator column (lowest isolation, simplest) - implemented in Hibernate via `MultiTenantConnectionProvider` and `CurrentTenantIdentifierResolver`.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
A SaaS application serves 100 customers. Without multi-tenancy: deploy 100 separate application instances, each with its own database. 100x infrastructure cost. 100x deployment effort. 100x maintenance.

**THE INVENTION MOMENT:**
"One application instance, multiple customers, data isolation guaranteed."

---

### 📘 Textbook Definition

Multi-tenancy is an architecture pattern where a single application instance serves multiple tenants (customers) with data isolation between them. Hibernate supports three strategies: **DATABASE** (separate database per tenant), **SCHEMA** (separate schema per tenant in same database), **DISCRIMINATOR** (shared table with tenant_id column, Hibernate 6+). The framework routes queries to the correct tenant's data based on the current tenant identifier (typically from HTTP headers, JWT claims, or subdomain).

---

### ⏱️ Understand It in 30 Seconds

**One line:**
One app, many customers, data never leaks between them.

**One insight:**
Discriminator strategy (shared table with `tenant_id`) is the most scalable but has the highest risk: a missing `WHERE tenant_id = ?` clause leaks data. Database-per-tenant is safest but hardest to manage. Choose based on compliance requirements: financial/healthcare data often requires database-level isolation.

---

### 📶 Gradual Depth

**Level 2 - Architecture (junior):**

```
  DATABASE strategy:
    tenant_a_db -> all tables
    tenant_b_db -> all tables
    Strongest isolation. Separate backups.

  SCHEMA strategy:
    shared_db:
      tenant_a schema -> all tables
      tenant_b schema -> all tables
    Good isolation. Shared connection pool.

  DISCRIMINATOR strategy:
    shared_db, shared tables:
      users: id, tenant_id, name, ...
      orders: id, tenant_id, total, ...
    WHERE tenant_id = ? on every query.
    Weakest isolation. Simplest scaling.
```

**Level 3 - Implementation (mid-level):**

Tenant identifier resolver:

```java
@Component
public class TenantResolver
    implements
    CurrentTenantIdentifierResolver {

    @Override
    public String resolveCurrentTenant() {
        // From HTTP header, JWT, subdomain
        return TenantContext.getTenantId();
    }

    @Override
    public boolean
            validateExistingCurrentSessions() {
        return true;
    }
}
```

Thread-local tenant context:

```java
public class TenantContext {
    private static final
        ThreadLocal<String> CURRENT =
        new ThreadLocal<>();

    public static void set(String tid) {
        CURRENT.set(tid);
    }
    public static String getTenantId() {
        return CURRENT.get();
    }
    public static void clear() {
        CURRENT.remove();
    }
}
```

Filter to extract tenant:

```java
@Component
public class TenantFilter
        extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain chain)
            throws ServletException,
            IOException {
        String tenant = request
            .getHeader("X-Tenant-ID");
        TenantContext.set(tenant);
        try {
            chain.doFilter(
                request, response);
        } finally {
            TenantContext.clear();
        }
    }
}
```

**Level 4 - Mastery (senior/staff+):**

Discriminator strategy (Hibernate 6):

```java
@Entity
@FilterDef(name = "tenantFilter",
    parameters = @ParamDef(
        name = "tenantId",
        type = String.class))
@Filter(name = "tenantFilter",
    condition =
    "tenant_id = :tenantId")
public class User {
    @Id @GeneratedValue
    private Long id;

    @Column(name = "tenant_id")
    private String tenantId;

    private String name;
}
```

Migration strategy:

```
  Growth path:

  Start: Discriminator (simple, cheap)
    100 tenants, shared tables

  Grow: Schema (compliance need)
    Schema per enterprise tenant
    Discriminator for small tenants

  Scale: Database (regulated tenants)
    Database per financial tenant
    Schema for enterprise
    Discriminator for free tier
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use multi-tenancy to serve multiple customers."

**A Staff says:** "I choose the strategy based on compliance requirements: HIPAA/PCI -> database-level isolation. Enterprise SaaS -> schema. Consumer SaaS -> discriminator. I implement a hybrid approach for mixed-tier customers. I audit tenant isolation with integration tests that verify cross-tenant data is never returned."

---

### 💻 Code Example

**BAD missing tenant filter vs GOOD guaranteed:**

```java
// BAD - manual tenant filtering
// Developer might forget WHERE clause
@Query("SELECT u FROM User u "
    + "WHERE u.email = :email")
User findByEmail(String email);
// Returns ANY tenant's user!

// GOOD - automatic tenant filtering
// Hibernate @Filter applied to all
// queries on this entity
@Entity
@Filter(name = "tenantFilter",
    condition =
    "tenant_id = :tenantId")
public class User { }
// Every query automatically includes
// WHERE tenant_id = ?
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Data isolation for multiple customers in a shared application.

**KEY INSIGHT:** Database = safest. Schema = balanced. Discriminator = simplest. Choose by compliance.

**ANTI-PATTERN:** Discriminator without automatic filtering (data leak risk).

**ONE-LINER:** "One app, N tenants, zero data leaks. Strategy by compliance needs."

**If you remember only 3 things:**

1. Three strategies: Database (safest), Schema (balanced), Discriminator (simplest)
2. Choose by compliance: financial/healthcare -> database. General SaaS -> discriminator
3. Always use automatic tenant filtering (never manual WHERE tenant_id)

---

### 🎯 Interview Deep-Dive

**Q1 [SENIOR]: Compare multi-tenancy strategies. How do you choose?**

_Why they ask:_ Architecture decision.
_Likely follow-up:_ "How do you handle migrations?"

**Answer:**

| Strategy      | Isolation | Complexity   | Scaling                |
| ------------- | --------- | ------------ | ---------------------- |
| Database      | Strongest | High (N DBs) | Per-tenant backup      |
| Schema        | Good      | Medium       | Shared connection pool |
| Discriminator | Weakest   | Low          | Shared everything      |

Decision framework:

- Regulatory compliance (HIPAA, PCI): Database
- Enterprise SaaS with data residency: Schema
- Consumer SaaS, cost-sensitive: Discriminator

Hybrid: large enterprise tenants get dedicated schemas/databases. Free-tier tenants share discriminator tables. Migration path: start discriminator, promote tenants as they grow.

Schema migrations: DATABASE/SCHEMA require running migrations per tenant. Discriminator runs once.

_What separates good from great:_ The hybrid strategy and migration consideration.

---

### 🔗 Related Keywords

**Prerequisites:** Connection Pooling, Schema Design

**Builds on:** SaaS Architecture, Data Isolation

**Related:** Row-Level Security (PostgreSQL), Flyway multi-tenant

---

---

# Auditing with Envers and Spring Data

**TL;DR** - Spring Data JPA auditing (`@CreatedBy`, `@LastModifiedDate`) tracks who changed entities and when, while Hibernate Envers (`@Audited`) maintains a complete revision history in audit tables - enabling full temporal queries ("What was this entity's state at timestamp X?").

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
A user's address was changed. When? By whom? What was the previous value? Without auditing, this information is lost. Manual audit logging is error-prone, inconsistent, and easily bypassed.

---

### 📘 Textbook Definition

**Spring Data Auditing** automatically populates metadata fields: `@CreatedDate`, `@LastModifiedDate`, `@CreatedBy`, `@LastModifiedBy`. Enabled via `@EnableJpaAuditing`. Captures the "who" and "when" of the latest change only.

**Hibernate Envers** maintains a complete audit trail: every INSERT, UPDATE, and DELETE creates a revision record in a shadow audit table (e.g., `users_AUD`). Supports temporal queries: "What was User 42 at revision 5?" or "Which entities changed in revision 100?"

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Spring Data auditing = who/when of last change. Envers = complete revision history of all changes.

**One insight:**
Envers stores entity snapshots in `_AUD` tables. This doubles storage but provides complete history. For entities with frequent updates and strict audit requirements (financial, healthcare), Envers is non-negotiable. For simple tracking (createdAt/modifiedAt), Spring Data auditing is sufficient.

---

### 📶 Gradual Depth

**Level 2 - Spring Data Auditing (junior):**

```java
@Configuration
@EnableJpaAuditing
public class AuditConfig {
    @Bean
    AuditorAware<String> auditorProvider() {
        return () -> Optional.ofNullable(
            SecurityContextHolder
            .getContext()
            .getAuthentication())
            .map(Authentication::getName);
    }
}

@Entity
@EntityListeners(
    AuditingEntityListener.class)
public class User {
    @Id @GeneratedValue
    private Long id;

    @CreatedDate
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    @CreatedBy
    private String createdBy;

    @LastModifiedBy
    private String updatedBy;
}
```

**Level 3 - Hibernate Envers (mid-level):**

```java
// Add dependency:
// hibernate-envers

@Entity
@Audited
public class User {
    @Id @GeneratedValue
    private Long id;
    private String name;
    private String email;

    @NotAudited // Skip this field
    private String tempToken;
}

// Envers creates: users_AUD table
// | id | REV | REVTYPE | name | email |
// | 1  | 1   | 0 (ADD) | John | j@x   |
// | 1  | 2   | 1 (MOD) | Jane | j@x   |
// | 1  | 3   | 2 (DEL) | Jane | j@x   |
```

Querying revision history:

```java
AuditReader reader = AuditReaderFactory
    .get(em);

// Get entity at specific revision
User userAtRev2 = reader.find(
    User.class, userId, 2);

// Get all revisions for entity
List<Number> revisions =
    reader.getRevisions(
    User.class, userId);

// Query at a point in time
User userAtDate = reader.find(
    User.class, userId, dateInstant);
```

**Level 4 - Mastery (senior/staff+):**

Custom revision entity:

```java
@Entity
@RevisionEntity(
    CustomRevisionListener.class)
public class CustomRevision
        extends DefaultRevisionEntity {
    private String username;
    private String ipAddress;
    private String action;
}

public class CustomRevisionListener
    implements RevisionListener {
    @Override
    public void newRevision(
            Object revision) {
        CustomRevision rev =
            (CustomRevision) revision;
        Authentication auth =
            SecurityContextHolder
            .getContext()
            .getAuthentication();
        rev.setUsername(auth.getName());
        rev.setIpAddress(
            getClientIp());
    }
}
```

Performance considerations:

```
  Envers impact:
    Every INSERT -> 2 INSERTs
      (entity + AUD table)
    Every UPDATE -> 1 UPDATE + 1 INSERT
      (entity + AUD record)
    Storage: ~2x for audited entities

  Mitigation:
    @NotAudited on large/frequent fields
    Partition AUD tables by revision date
    Archive old revisions periodically
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use @CreatedDate for tracking."

**A Staff says:** "I use Spring Data auditing for basic metadata (created/modified). I use Envers for compliance-critical entities (financial records, healthcare data). I customize the revision entity to capture IP address and action. I partition AUD tables for performance. I use `@NotAudited` on fields that do not need history (tokens, caches)."

---

### 💻 Code Example

**BAD manual audit vs GOOD automatic:**

```java
// BAD - manual audit logging
@Transactional
public void updateUser(Long id,
        String name) {
    User user = userRepo.findById(id)
        .orElseThrow();
    String oldName = user.getName();
    user.setName(name);
    auditLogRepo.save(
        new AuditLog("User", id,
        "name", oldName, name,
        getCurrentUser()));
    // Easy to forget!
    // Inconsistent across entities
}

// GOOD - automatic with Envers
@Entity
@Audited
public class User {
    private String name;
    // Every change automatically
    // recorded in users_AUD
    // No manual logging needed
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Automatic change tracking: Spring Data (last change) + Envers (full history).

**KEY INSIGHT:** Spring Data = who/when. Envers = complete revision history. Choose by compliance.

**ANTI-PATTERN:** Manual audit logging (inconsistent). @Audited on everything (storage).

**ONE-LINER:** "CreatedDate/LastModifiedBy for basics. @Audited for full revision history."

**If you remember only 3 things:**

1. Spring Data @CreatedDate/@LastModifiedBy for basic audit metadata
2. Hibernate Envers @Audited for complete revision history (AUD tables)
3. Custom revision entity to capture username, IP, and action

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: Spring Data Auditing vs Hibernate Envers - when to use each?**

_Why they ask:_ Audit strategy decision.
_Likely follow-up:_ "How does Envers affect performance?"

**Answer:**

**Spring Data Auditing:** Lightweight. Captures last change only (createdAt, updatedAt, createdBy, lastModifiedBy). No history. Use for: general entities where you only need "who last touched this?"

**Hibernate Envers:** Full revision history. Every INSERT/UPDATE/DELETE creates an audit record in `_AUD` tables. Supports temporal queries ("What was this at revision N?"). Use for: compliance-critical entities (financial, healthcare, legal).

Performance: Envers roughly doubles write operations (entity + AUD INSERT). Mitigate with `@NotAudited` on non-critical fields and AUD table partitioning.

_What separates good from great:_ The compliance-driven decision and performance mitigation strategies.

---

### 🔗 Related Keywords

**Prerequisites:** Entity Lifecycle, Spring Security

**Builds on:** Compliance, Temporal Queries

**Related:** Event Sourcing (full event history), CDC (Change Data Capture)
