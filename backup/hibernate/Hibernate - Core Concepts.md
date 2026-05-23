---
layout: default
title: "Hibernate - Core Concepts"
parent: "Hibernate"
grand_parent: "Interview Mastery"
nav_order: 3
permalink: /interview/hibernate/core-concepts/
topic: Hibernate
subtopic: Core Concepts
keywords:
  - Persistence Context and Entity Lifecycle
  - EntityManager Operations
  - JPQL and HQL
  - Entity Mapping Fundamentals
  - Dirty Checking and Flush Modes
difficulty_range: medium to hard
status: complete
version: 3
---

**Keywords covered in this file:**

- [Persistence Context and Entity Lifecycle](#persistence-context-and-entity-lifecycle)
- [EntityManager Operations](#entitymanager-operations)
- [JPQL and HQL](#jpql-and-hql)
- [Entity Mapping Fundamentals](#entity-mapping-fundamentals)
- [Dirty Checking and Flush Modes](#dirty-checking-and-flush-modes)

# Persistence Context and Entity Lifecycle

**TL;DR** - The persistence context is a first-level cache that tracks entity state transitions (New, Managed, Detached, Removed) and automatically synchronizes managed entities to the database at flush time - making the EntityManager the single gateway for all entity state changes.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every database interaction requires manual SQL: INSERT after creating an object, UPDATE after modifying, DELETE after removing. Developers track which objects changed, write SQL for each change, manage the order of operations to satisfy foreign key constraints, and handle rollbacks manually. Object state and database state drift apart silently.

**THE BREAKING POINT:**
A developer modifies an entity's name field, forgets to call UPDATE, and the change is lost. Another developer calls UPDATE twice, creating a duplicate. A third developer deletes a parent without deleting children first, violating foreign key constraints.

**THE INVENTION MOMENT:**
"What if the framework tracked every object's state and automatically synchronized changes to the database?"

**EVOLUTION:**
Raw JDBC (manual SQL) -> DAO pattern (structured CRUD) -> JDO (object-database mapping) -> Hibernate 1.0 (2001, persistence context) -> JPA 1.0 (2006, standardized persistence context) -> JPA 2.0 (Criteria API) -> JPA 3.0 (Jakarta namespace).

---

### 📘 Textbook Definition

The persistence context is a set of managed entity instances in which, for any persistent entity identity, there is a unique entity instance. It acts as a first-level cache and a unit of work that tracks entity state changes. Entities transition through four states: **New/Transient** (not associated with a persistence context), **Managed** (associated and tracked), **Detached** (was managed but the context is closed), and **Removed** (scheduled for deletion). The EntityManager is the API that manages the persistence context and drives state transitions via `persist()`, `merge()`, `remove()`, and `find()`.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
The persistence context tracks your entities and automatically writes changes to the database - you modify Java objects and Hibernate handles the SQL.

**One analogy:**

> A shopping cart at an online store. Items in your cart (managed entities) are tracked - you can change quantities (modify fields), add items (persist), or remove items (remove). When you checkout (flush), all changes are applied to the order (database) at once. Items not in your cart (transient/detached) are not tracked.

**One insight:**
The persistence context guarantees **identity equality**: calling `find(User.class, 42)` twice in the same context returns the exact same Java object reference (`==` is true). This is not object equality - it is identity. This guarantee is what makes dirty checking possible.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. **Identity guarantee:** For any entity type + primary key, there is at most ONE instance in the persistence context. `find(User.class, 1) == find(User.class, 1)` is always `true`.
2. **Automatic synchronization:** Managed entities are automatically compared to their original state (snapshot) at flush time. Changed fields generate UPDATE SQL.
3. **Transaction-scoped by default:** In Spring, the persistence context lives for the duration of the `@Transactional` method. When the transaction ends, all managed entities become detached.

**DERIVED DESIGN:**
From invariant 1: the persistence context is a Map<EntityKey, Entity>. From invariant 2: you never write UPDATE SQL for managed entities. From invariant 3: accessing lazy-loaded associations outside a transaction throws `LazyInitializationException`.

**THE TRADE-OFFS:**

**Gain:** No manual SQL for CRUD. Automatic change detection. Identity guarantee.

**Cost:** Memory overhead (snapshots of all managed entities). Dirty checking iterates all managed entities at flush. Large persistence contexts degrade performance.

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**

**Essential:** Object-relational impedance mismatch requires some mapping layer.

**Accidental:** The four entity states and their transition rules are complex and cause bugs (detached entity passed to merge vs persist).

---

### 🧠 Mental Model / Analogy

> The persistence context is like a version control staging area (Git index). **New** objects are untracked files. `persist()` is `git add` - the entity becomes **Managed** (staged). Modifications to managed entities are automatically detected (like `git diff`). `remove()` is `git rm`. `flush()` is `git commit` - all staged changes are written to the database. `detach()` or closing the context is like switching branches - the entities are no longer tracked.

- "Untracked file" -> New/Transient entity
- "Staged file" -> Managed entity
- "git diff" -> Dirty checking
- "git commit" -> Flush
- "Switching branches" -> Detach / close context

Where this analogy breaks down: Git allows multiple staged versions; the persistence context has exactly one instance per entity identity.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
When you load or create a database record in Java, Hibernate remembers it. If you change the Java object, Hibernate automatically saves those changes to the database. You do not write UPDATE statements manually.

**Level 2 - How to use it (junior developer):**

Entity states:

```java
// NEW (Transient) - not tracked
User user = new User("John");

// MANAGED - tracked by persistence ctx
entityManager.persist(user);
// INSERT scheduled

// Still MANAGED - changes auto-detected
user.setName("Jane");
// UPDATE will be generated at flush

// REMOVED - scheduled for deletion
entityManager.remove(user);
// DELETE scheduled

// DETACHED - after TX ends or detach()
// No longer tracked
```

**Level 3 - How it works (mid-level engineer):**

State transition diagram:

```
  new User()
       |
  [TRANSIENT] --persist()--> [MANAGED]
       |                        |
       |                   modify fields
       |                   (auto-detected)
       |                        |
       |                   flush(): SQL
       |                   INSERT/UPDATE
       |                        |
       |                   remove()
       |                        |
       |                   [REMOVED]
       |                        |
       |                   flush(): DELETE
       |
  merge() can bring back to MANAGED
       |
  [DETACHED] <--close()/clear()-- [MANAGED]
```

Persistence context internals:

```
  PersistenceContext:
    entityMap: {
      EntityKey(User, 1) -> User@abc
      EntityKey(Order, 5) -> Order@def
    }
    entitySnapshots: {
      EntityKey(User, 1) -> {
        name: "John",  // original
        email: "j@x.com"
      }
    }

  At flush:
    Compare User@abc.name ("Jane")
    vs snapshot.name ("John")
    -> Different! Generate UPDATE
```

**Level 4 - Mastery (senior/staff+ engineer):**

Extended persistence context (stateful session beans vs transaction-scoped):

```
  Transaction-scoped (Spring default):
    @Transactional
    void process() {
      User u = repo.findById(1); // MANAGED
      u.setName("Jane"); // auto-UPDATE
    } // TX commit -> flush -> detach all

  Extended (rarely used):
    @PersistenceContext(
      type = EXTENDED)
    EntityManager em;
    // Context survives across TX
    // Used in stateful conversation
```

Flush modes:

| FlushMode      | When SQL Executes              |
| -------------- | ------------------------------ |
| AUTO (default) | Before query + at commit       |
| COMMIT         | Only at commit                 |
| MANUAL         | Only when flush() called       |
| ALWAYS         | Before every query (Hibernate) |

Performance implication of large context:

```
  10,000 managed entities:
  - 10K snapshots stored in memory
  - Dirty checking iterates ALL 10K
    at flush time
  - Even if only 1 entity changed

  Fix: clear() after batch processing
  or use StatelessSession
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Hibernate tracks entities and auto-generates SQL."

**A Staff says:** "I understand the persistence context as a unit-of-work pattern with identity map. I control context size for batch operations (clear every 50 entities), choose `COMMIT` flush mode for read-heavy transactions to avoid unnecessary dirty checks before queries, and use `StatelessSession` for bulk imports where change tracking is overhead."

**The difference:** Staff engineers manage the persistence context as a performance-critical resource.

**Level 5 - Distinguished (expert thinking):**
The persistence context implements two patterns from Martin Fowler's PoEAA: **Identity Map** (one instance per key) and **Unit of Work** (track changes, batch SQL). These patterns are fundamental to all ORM frameworks: Hibernate, EclipseLink, Django ORM, SQLAlchemy, Entity Framework. Understanding them means understanding any ORM. The trade-off between tracking granularity and performance is universal - ORMs trade memory for developer convenience.

---

### ⚙️ How It Works

```
  em.persist(user) called
       |
  PersistenceContext:
    1. Generate EntityKey(User, id)
    2. Store user in entityMap
    3. Take snapshot of all fields
       |
  user.setName("Jane") called
       |
  Nothing happens yet (no SQL)
       |
  Flush triggered (query or TX commit):
    1. Iterate all managed entities
    2. Compare each to its snapshot
    3. user.name != snapshot.name
       -> Generate UPDATE SQL
    4. Execute SQL batch
    5. Update snapshots
```

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**

```
  @Transactional service method:
       |
  find(User.class, 1)
    -> Check 1st-level cache <- HERE
    -> Cache miss -> SELECT SQL
    -> Store in context + snapshot
       |
  user.setName("Jane")
    -> No SQL yet
       |
  TX commit -> auto flush:
    -> Dirty check: name changed
    -> UPDATE users SET name='Jane'
       WHERE id=1
    -> Commit TX
       |
  All entities become DETACHED
```

**FAILURE PATH:**
Transaction rolls back -> no SQL executed -> entities still have in-memory changes but database is unchanged. If the entity is reused after rollback (detached), its state may not match the database.

**WHAT CHANGES AT SCALE:**
At 10 entities: persistence context is invisible. At 10K entities: dirty checking becomes a bottleneck. At 100K: must use `StatelessSession` or native SQL. Batch processing requires `clear()` every 50-100 entities to prevent `OutOfMemoryError`.

---

### 💻 Code Example

**Example 1 - BAD manual SQL vs GOOD managed entity:**

```java
// BAD - manual update (misses fields)
public void updateUser(Long id,
        String name) {
    em.createQuery(
        "UPDATE User u SET u.name = :n "
        + "WHERE u.id = :id")
        .setParameter("n", name)
        .setParameter("id", id)
        .executeUpdate();
    // Bypasses persistence context
    // Other fields not updated
    // No version check (lost update)
}

// GOOD - managed entity
@Transactional
public void updateUser(Long id,
        String name) {
    User user = em.find(User.class, id);
    user.setName(name);
    // Automatic dirty check at flush
    // All fields consistent
    // Version check if @Version present
}
```

**Example 2 - Batch processing with context management:**

```java
// BAD - OOM with large batch
@Transactional
public void importUsers(
        List<UserDto> dtos) {
    for (UserDto dto : dtos) {
        em.persist(toEntity(dto));
        // 100K entities in context!
        // OOM inevitable
    }
}

// GOOD - clear context periodically
@Transactional
public void importUsers(
        List<UserDto> dtos) {
    int batchSize = 50;
    for (int i = 0; i < dtos.size(); i++) {
        em.persist(toEntity(dtos.get(i)));
        if (i % batchSize == 0) {
            em.flush();
            em.clear(); // Release memory
        }
    }
}
```

**How to test / verify correctness:**

```java
@DataJpaTest
class PersistenceContextTest {
    @Autowired TestEntityManager em;

    @Test
    void managedEntityAutoUpdates() {
        User user = em.persistAndFlush(
            new User("John"));
        user.setName("Jane");
        em.flush();
        User found = em.find(
            User.class, user.getId());
        assertThat(found.getName())
            .isEqualTo("Jane");
        // Same reference (identity)
        assertThat(found).isSameAs(user);
    }
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** First-level cache + unit of work that tracks entity state transitions and auto-generates SQL.

**PROBLEM IT SOLVES:** Eliminates manual INSERT/UPDATE/DELETE SQL for entity CRUD.

**KEY INSIGHT:** Identity guarantee: same PK = same Java object reference within a context.

**USE WHEN:** All JPA-based data access (default behavior).

**AVOID WHEN:** Bulk imports (use StatelessSession), read-only queries (use projections).

**ANTI-PATTERN:** Loading 10K+ entities into one context (OOM, slow dirty checking).

**TRADE-OFF:** Developer convenience vs memory overhead for snapshots.

**ONE-LINER:** "Modify the Java object; Hibernate writes the SQL."

**KEY NUMBERS:** 4 entity states. Dirty check iterates ALL managed entities. Clear every 50 in batch.

**TRIGGER PHRASE:** "First-level cache with identity map and unit of work."

**OPENING SENTENCE:** "The persistence context is a first-level cache implementing the Identity Map and Unit of Work patterns - guaranteeing one Java instance per entity identity and automatically detecting field changes via snapshot comparison at flush time."

**If you remember only 3 things:**

1. 4 states: Transient -> Managed -> Detached / Removed
2. Dirty checking compares managed entities to snapshots at flush
3. Clear the context in batch processing to prevent OOM

**Interview one-liner:**
"The persistence context is a first-level cache with identity guarantee - one instance per entity key. It snapshots managed entities and generates SQL by comparing current state to snapshots at flush. I manage context size for batch operations and choose flush modes based on read vs write patterns."

---

### ✅ Mastery Checklist

**You've mastered this when you can:**

1. **EXPLAIN:** Draw the 4-state lifecycle and describe each transition method
2. **DEBUG:** Given "detached entity passed to persist," identify the state mismatch
3. **DECIDE:** Choose between flush modes (AUTO vs COMMIT) for different workloads
4. **BUILD:** Implement batch processing with periodic flush/clear
5. **EXTEND:** Explain when to use StatelessSession vs managed context

---

### 💡 The Surprising Truth

Calling `user.setName("Jane")` on a managed entity generates an UPDATE for ALL columns, not just the changed one. Hibernate's default is `@DynamicUpdate(false)` - it pre-generates a single UPDATE statement with all columns at startup for performance (prepared statement caching). To update only changed columns, add `@DynamicUpdate` to the entity class. This matters for wide tables (50+ columns) or when triggers fire on column changes.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                      | Reality                                                                                  |
| --- | -------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| 1   | "persist() immediately inserts to DB"              | No. It makes the entity managed. INSERT happens at flush/commit.                         |
| 2   | "You need em.update() to save changes"             | No such method. Managed entities are auto-detected via dirty checking.                   |
| 3   | "Detached entities are still tracked"              | No. Changes to detached entities are invisible to the context. Use merge() to re-attach. |
| 4   | "The persistence context is shared across threads" | No. It is thread-local and transaction-scoped. NEVER share across threads.               |
| 5   | "find() always hits the database"                  | No. It checks the first-level cache first. Only queries the DB on cache miss.            |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: LazyInitializationException**

**Symptom:** `org.hibernate.LazyInitializationException: could not initialize proxy - no Session`

**Root Cause:** Accessing a lazy-loaded association on a detached entity (outside the transaction/session).

**Diagnostic:**

```java
// Trace: where was the entity loaded?
// Is the access inside @Transactional?
log.info("Session open: {}",
    em.isOpen());
```

**Fix:**

BAD: `spring.jpa.open-in-view=true` (keeps session open for entire HTTP request - N+1 risk).

GOOD: Use `JOIN FETCH` or `@EntityGraph` to load the association eagerly in the query.

**Prevention:** Always load needed associations within the transaction boundary.

**Failure Mode 2: OutOfMemoryError during batch processing**

**Symptom:** `java.lang.OutOfMemoryError: Java heap space` during large imports.

**Root Cause:** Persistence context holds snapshots of all persisted entities. 100K entities = 100K snapshots.

**Diagnostic:**

```bash
jmap -histo:live <pid> | grep EntityEntry
# Shows number of entity entries in memory
```

**Fix:**

BAD: Increasing heap size (delays the problem).

GOOD: `flush()` and `clear()` every 50-100 entities. Or use `StatelessSession`.

**Prevention:** Batch processing always uses periodic context clearing.

**Failure Mode 3: Detached entity passed to persist**

**Symptom:** `PersistentObjectException: detached entity passed to persist`

**Root Cause:** Calling `persist()` on an entity that already has an ID (was previously managed, now detached).

**Diagnostic:**

```java
// Check if entity has ID
log.info("ID: {}", entity.getId());
// Has ID = was persisted before = detached
```

**Fix:**

BAD: Setting ID to null before persist.

GOOD: Use `merge()` instead of `persist()` for detached entities.

**Prevention:** `persist()` for new entities, `merge()` for detached.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals               |
| ------------- | --------------- | --------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident     |
| Debugging     | 90-150 seconds  | Systematic diagnosis  |
| Architecture  | 120-180 seconds | Trade-off exploration |
| Trade-off     | 60-120 seconds  | Decision framework    |
| Behavioral    | 60-120 seconds  | Clear STAR structure  |

**Q1 [JUNIOR]: What are the four entity states in JPA?**

_Why they ask:_ Foundation knowledge for any Hibernate developer.
_Likely follow-up:_ "What triggers each transition?"

**Answer:**
Four states:

1. **Transient (New):** Created with `new`. No ID assigned. Not tracked. `persist()` transitions to Managed.
2. **Managed:** Associated with a persistence context. Tracked for changes. `find()` and `persist()` return managed entities. Changes are auto-detected at flush.
3. **Detached:** Was managed but the context closed (transaction ended) or `detach()` was called. Has an ID but is not tracked. Use `merge()` to re-attach.
4. **Removed:** Scheduled for deletion via `remove()`. DELETE SQL executes at flush.

Key: Managed entities do not need explicit UPDATE calls. Modifying a managed entity's fields is sufficient - Hibernate detects changes via dirty checking at flush time.

_What separates good from great:_ Explaining that managed entities are auto-tracked and that detached entities require `merge()` not `persist()`.

---

**Q2 [JUNIOR]: What is the persistence context?**

_Why they ask:_ Core ORM concept.
_Likely follow-up:_ "How is it related to the first-level cache?"

**Answer:**
The persistence context is:

1. **First-level cache:** A Map of `EntityKey(type, id)` to entity instance. `find()` checks this map before querying the database. Guarantees identity: same key always returns the same Java object reference.

2. **Unit of work:** Tracks all managed entities. At flush time, compares each entity to its original snapshot and generates SQL (INSERT/UPDATE/DELETE) for changes.

3. **Transaction-scoped (Spring default):** Lives for the duration of `@Transactional`. When the transaction ends, all entities become detached.

```java
User u1 = em.find(User.class, 1); // DB hit
User u2 = em.find(User.class, 1); // Cache
assertThat(u1 == u2).isTrue();    // Same ref
```

The persistence context is NOT shared across threads and NOT shared across transactions (in the default transaction-scoped mode).

_What separates good from great:_ Mentioning identity guarantee and snapshot-based dirty checking.

---

**Q3 [MID]: How does dirty checking work internally?**

_Why they ask:_ Tests deep understanding of ORM internals.
_Likely follow-up:_ "What is the performance impact?"

**Answer:**
When an entity becomes managed (`persist()` or `find()`), Hibernate takes a **snapshot** - a copy of all field values at that moment.

At flush time (before query execution or at transaction commit):

1. Iterate ALL managed entities in the persistence context
2. Compare each entity's current field values to its snapshot
3. For each difference: generate an UPDATE SQL statement
4. Execute all SQL in the correct order (respecting FK constraints)
5. Update snapshots to reflect new state

Performance implications:

- Dirty checking is O(N) where N = number of managed entities
- For 10K managed entities, Hibernate compares 10K snapshots even if only 1 changed
- Fix: keep the context small (`clear()` in batches), use `FlushMode.COMMIT` for read-heavy transactions (skips dirty check before queries), or use `@DynamicUpdate` for wide tables

Default behavior generates UPDATE for ALL columns (not just changed ones) because Hibernate pre-compiles the UPDATE statement at startup for prepared statement caching. `@DynamicUpdate` generates per-change SQL at the cost of no statement caching.

_What separates good from great:_ Explaining O(N) iteration, snapshot comparison, and the `@DynamicUpdate` trade-off.

---

**Q4 [MID]: What is the difference between persist() and merge()?**

_Why they ask:_ Common confusion point.
_Likely follow-up:_ "When would you use each?"

**Answer:**

`persist()`:

- Takes a **transient** entity (no ID, never persisted)
- Makes it **managed** in the current context
- The SAME object reference is now tracked
- Throws `PersistentObjectException` if entity has an ID (detached)

`merge()`:

- Takes a **detached** entity (has ID, was previously persisted)
- Copies its state into a NEW managed entity
- Returns the MANAGED copy (different reference!)
- The original detached entity is NOT tracked

```java
// persist: same reference
User user = new User("John");
em.persist(user);
// user IS the managed entity

// merge: different reference
User detached = getDetachedUser();
User managed = em.merge(detached);
// detached != managed
// managed is the tracked entity
```

Critical mistake: using the detached reference after merge. Always use the returned managed instance.

Spring Data `save()` calls `persist()` if `isNew()` is true, `merge()` otherwise.

_What separates good from great:_ Explaining that merge returns a DIFFERENT reference and the original is still detached.

---

**Q5 [MID]: Explain FlushMode options and when to use each.**

_Why they ask:_ Performance tuning knowledge.
_Likely follow-up:_ "What problems can COMMIT mode cause?"

**Answer:**

| Mode           | Flush Trigger           | Use Case      |
| -------------- | ----------------------- | ------------- |
| AUTO (default) | Before queries + commit | General use   |
| COMMIT         | Only at commit          | Read-heavy TX |
| MANUAL         | Only explicit flush()   | Full control  |

**AUTO:** Safest. Before any JPQL/SQL query, Hibernate flushes pending changes to ensure the query sees current data. Overhead: unnecessary dirty checks before read-only queries.

**COMMIT:** Flushes only at transaction commit. Skips dirty checking before queries. Risk: queries may return stale data if you modified an entity and then query for it.

```java
// COMMIT mode risk:
user.setName("Jane");
// Query below does NOT see "Jane"
// because no flush happened
em.createQuery(
    "SELECT u FROM User u "
    + "WHERE u.name = 'Jane'")
    .getResultList(); // Empty!
```

**MANUAL:** Developer controls all flushes. Use for complex operations where you need precise control over SQL execution order.

Decision: Use AUTO for mixed read-write. Use COMMIT for read-heavy transactions with `@Transactional(readOnly = true)`. Use MANUAL when you need full control.

_What separates good from great:_ The concrete example showing COMMIT mode's stale data risk.

---

**Q6 [SENIOR]: How do you handle batch processing with Hibernate to avoid OOM?**

_Why they ask:_ Real production problem.
_Likely follow-up:_ "When would you use StatelessSession?"

**Answer:**
Three strategies:

1. **Periodic flush/clear:**

```java
@Transactional
void importUsers(List<UserDto> dtos) {
    for (int i = 0; i < dtos.size();
            i++) {
        em.persist(toEntity(dtos.get(i)));
        if (i % 50 == 0) {
            em.flush();
            em.clear();
        }
    }
}
```

Pros: Works with managed entities, cascades, and version checks.
Cons: Still uses persistence context overhead per batch.

2. **StatelessSession (Hibernate):**

```java
StatelessSession session = sf
    .openStatelessSession();
Transaction tx = session.beginTransaction();
for (UserDto dto : dtos) {
    session.insert(toEntity(dto));
}
tx.commit();
session.close();
```

Pros: No persistence context, no dirty checking, no snapshots. Fastest.
Cons: No cascading, no lazy loading, no first-level cache.

3. **JDBC batch with Spring JDBC:**

```java
jdbcTemplate.batchUpdate(
    "INSERT INTO users (name, email) "
    + "VALUES (?, ?)",
    dtos, 1000,
    (ps, dto) -> {
        ps.setString(1, dto.getName());
        ps.setString(2, dto.getEmail());
    });
```

Pros: Fastest for pure inserts. No ORM overhead.
Cons: No entity mapping, no validation.

Decision: < 1K entities: flush/clear. 1K-100K: StatelessSession. > 100K: JDBC batch.

Monitor with `hibernate.generate_statistics=true`:

```
Session Metrics:
  entities loaded: 0
  entities inserted: 100000
  flush count: 2000
```

_What separates good from great:_ Three strategies with clear decision boundaries and monitoring.

---

**Q7 [SENIOR]: Explain the difference between transaction-scoped and extended persistence context.**

_Why they ask:_ Tests deep JPA knowledge.
_Likely follow-up:_ "Why is extended context rarely used in Spring?"

**Answer:**

**Transaction-scoped (default in Spring):**

- Persistence context lives for one `@Transactional` method
- When the transaction ends, all entities become detached
- Next transaction creates a new context
- Stateless, simple, predictable

**Extended persistence context:**

- Context survives across multiple transactions
- Entities remain managed between transactions
- Changes accumulate and flush at the next transaction
- Used in stateful conversational patterns (wizards, multi-step forms)

```java
// Extended context (JEE Stateful)
@Stateful
public class OrderWizard {
    @PersistenceContext(
        type = EXTENDED)
    EntityManager em;

    public void step1(OrderReq req) {
        Order order = new Order(req);
        em.persist(order);
        // No TX -> no flush -> no INSERT
    }

    @TransactionAttribute(REQUIRED)
    public void confirm() {
        // TX starts -> flush -> INSERT
    }
}
```

Why rarely used in Spring:

- Spring is stateless by default (HTTP request/response)
- Extended contexts hold memory between requests
- Risk of stale data (context not refreshed)
- Modern alternative: use DTOs between requests, re-attach with merge()

_What separates good from great:_ Explaining why extended context is an anti-pattern in stateless web apps.

---

**Q8 [SENIOR - DEBUGGING]: An application's memory grows continuously during a long-running batch job. Diagnose.**

_Why they ask:_ Real production problem.
_Likely follow-up:_ "How would you fix it without changing the ORM?"

**Answer:**
Diagnosis steps:

1. **Heap dump analysis:**

```bash
jmap -dump:live,format=b,file=heap.hprof \
  <pid>
# Open in Eclipse MAT or VisualVM
# Look for: EntityEntry, EntityKey,
# MutableEntityEntry objects
```

2. **Check persistence context size:**

```java
Session session = em.unwrap(
    Session.class);
SessionStatistics stats =
    session.getStatistics();
log.info("Managed entities: {}",
    stats.getEntityCount());
log.info("Collections: {}",
    stats.getCollectionCount());
// If entity count grows, context
// is not being cleared
```

3. **Enable Hibernate statistics:**

```yaml
spring:
  jpa:
    properties:
      hibernate:
        generate_statistics: true
```

Root cause: The batch job loads/creates entities without clearing the persistence context. Every entity stays managed with a snapshot copy.

Fix:

```java
if (i % 50 == 0) {
    em.flush();
    em.clear(); // Releases all entities
}
```

Or use `StatelessSession` for batch jobs.

_What separates good from great:_ Concrete diagnostic commands (heap dump, SessionStatistics) and the clear-every-50 pattern.

---

**Q9 [SENIOR - TRADE-OFF]: When would you bypass the persistence context entirely?**

_Why they ask:_ Tests trade-off reasoning.
_Likely follow-up:_ "What do you lose?"

**Answer:**
Bypass scenarios:

1. **Bulk updates:** `UPDATE User SET status = 'INACTIVE' WHERE lastLogin < :date`
   - JPQL bulk update bypasses context. Faster than loading 100K entities.
   - Loss: no dirty checking, no version increment, no cascade, context becomes stale.

2. **Read-only reporting:** Use DTO projections or native SQL.
   - No entities loaded into context. No snapshots. No memory overhead.
   - Loss: no lazy loading, no change tracking (not needed for reads).

3. **High-throughput writes:** Use `StatelessSession` or JDBC batch.
   - No persistence context overhead at all.
   - Loss: no first-level cache, no cascading, no automatic relationship management.

The key insight: the persistence context is a **convenience vs performance trade-off**. For CRUD operations (80%), the convenience is worth the overhead. For bulk operations and reporting (20%), bypass it.

After bypassing, the persistence context may contain stale data. Call `em.clear()` or `em.refresh(entity)` to synchronize.

_What separates good from great:_ The 80/20 framework and awareness that bulk operations stale the context.

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**

- JDBC and SQL - JPA sits on top of JDBC; understanding SQL helps debug generated queries
- Transaction Management - persistence context is transaction-scoped

**Builds on this (learn these next):**

- Dirty Checking and Flush Modes - deeper dive into change detection
- EntityManager Operations - API for driving state transitions
- Caching - first-level cache is the persistence context; second-level extends beyond

**Alternatives / Comparisons:**

- MyBatis - SQL-first mapper, no persistence context or change tracking
- JOOQ - type-safe SQL builder, no ORM state management
- Spring JDBC (JdbcTemplate) - no entity state management

---

---

# EntityManager Operations

**TL;DR** - The `EntityManager` is the JPA API for performing CRUD operations - `persist()` inserts, `find()` selects by PK, `merge()` re-attaches detached entities, `remove()` deletes, and `createQuery()` executes JPQL - all within the persistence context lifecycle.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Developers interact with the database through raw JDBC: create connections, prepare statements, set parameters, execute queries, map result sets to objects, close resources. Every DAO method is 20-30 lines of boilerplate for what should be a one-line operation.

**THE INVENTION MOMENT:**
"What if there was a single API that handled connections, SQL generation, result mapping, and change tracking?"

---

### 📘 Textbook Definition

`EntityManager` is the primary JPA interface for interacting with the persistence context. It manages entity lifecycle transitions (`persist`, `merge`, `remove`, `detach`, `refresh`), executes queries (`createQuery`, `createNativeQuery`, `createNamedQuery`), and provides cache management (`find`, `getReference`, `clear`, `flush`). In Spring, it is injected via `@PersistenceContext` or obtained through Spring Data JPA's repository abstraction.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
The EntityManager is your single API for all database operations - it manages entities, generates SQL, and coordinates with the persistence context.

**One analogy:**

> A concierge at a hotel. You say "check me in" (persist), "find my room" (find), "check me out" (remove). The concierge handles all the paperwork (SQL) and keeps the guest registry updated (persistence context). You never deal with the hotel's internal systems directly.

---

### 📶 Gradual Depth - Five Levels

**Level 2 - How to use it (junior):**

Core operations:

```java
// Create
User user = new User("John");
em.persist(user); // INSERT at flush

// Read (by PK)
User found = em.find(User.class, 1L);
// SELECT WHERE id = 1
// Returns null if not found

// Read (lazy reference)
User ref = em.getReference(
    User.class, 1L);
// No SELECT until accessed
// Throws EntityNotFoundException
// if not found when accessed

// Update (automatic for managed)
found.setName("Jane");
// UPDATE at flush (dirty checking)

// Delete
em.remove(found);
// DELETE at flush
```

**Level 3 - How it works (mid-level):**

`find()` vs `getReference()`:

| Method         | SQL Timing       | Not Found                         |
| -------------- | ---------------- | --------------------------------- |
| find()         | Immediate SELECT | Returns null                      |
| getReference() | Deferred (proxy) | EntityNotFoundException on access |

```java
// getReference is useful when you
// only need a reference for FK
Order order = new Order();
order.setUser(
    em.getReference(User.class, 1L));
// No SELECT for User!
// Just sets FK = 1
em.persist(order);
```

Query operations:

```java
// JPQL
List<User> users = em.createQuery(
    "SELECT u FROM User u "
    + "WHERE u.status = :status",
    User.class)
    .setParameter("status", "ACTIVE")
    .getResultList();

// Native SQL
List<Object[]> results =
    em.createNativeQuery(
    "SELECT name, COUNT(*) "
    + "FROM users GROUP BY name")
    .getResultList();

// Named query
@NamedQuery(
    name = "User.findActive",
    query = "SELECT u FROM User u "
        + "WHERE u.status = 'ACTIVE'")
List<User> active = em.createNamedQuery(
    "User.findActive", User.class)
    .getResultList();
```

**Level 4 - Mastery (senior/staff+):**

`merge()` deep dive:

```java
// merge() copies state into context
User detached = // from HTTP request
User managed = em.merge(detached);

// What merge does internally:
// 1. Find entity in context by ID
//    (or load from DB if not cached)
// 2. Copy ALL fields from detached
//    to managed entity
// 3. Return managed entity
// 4. Original detached is UNCHANGED

// WARNING: cascaded merge
// If User has @ManyToOne Address:
// merge(user) also merges
// user.getAddress()
// This can create unexpected UPDATEs
```

`refresh()` for stale data:

```java
// Force reload from database
// Overwrites in-memory changes
em.refresh(user);
// Useful after bulk JPQL UPDATE
// that bypassed the context
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `find()` to load and `persist()` to save."

**A Staff says:** "I use `getReference()` instead of `find()` when I only need a FK reference (saves a SELECT). I understand `merge()` returns a different instance and the original is still detached. I use Spring Data's `save()` which delegates to `persist()` or `merge()` based on `isNew()`, and I customize `isNew()` detection for entities with assigned IDs."

---

### 💻 Code Example

**BAD using merge for new entities vs GOOD choosing correctly:**

```java
// BAD - merge for new entity
// (unnecessary SELECT before INSERT)
public User create(UserDto dto) {
    User user = new User(dto);
    return em.merge(user);
    // merge checks DB for existing
    // entity -> SELECT + INSERT
}

// GOOD - persist for new entities
public User create(UserDto dto) {
    User user = new User(dto);
    em.persist(user);
    return user;
    // Direct INSERT, no SELECT
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** JPA API for CRUD operations and query execution within a persistence context.

**KEY INSIGHT:** `getReference()` avoids SELECT when you only need a FK. `merge()` returns a new reference.

**ANTI-PATTERN:** Using `merge()` for new entities. Ignoring `merge()`'s return value.

**ONE-LINER:** "persist() for new, find() for read, merge() for detached, remove() for delete."

**If you remember only 3 things:**

1. persist() = new entities. merge() = detached entities. Do not mix them.
2. find() returns null if not found. getReference() throws on access.
3. merge() returns the managed copy - always use the return value.

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals              |
| ------------- | --------------- | -------------------- |
| Conceptual    | 45-90 seconds   | Direct, confident    |
| Debugging     | 90-150 seconds  | Systematic diagnosis |
| Trade-off     | 60-120 seconds  | Decision framework   |

**Q1 [JUNIOR]: What is the difference between find() and getReference()?**

_Why they ask:_ Basic API knowledge.
_Likely follow-up:_ "When would you use getReference?"

**Answer:**
`find()` immediately executes a SELECT query and returns the entity or `null`. `getReference()` returns a proxy (no SQL) and defers the query until a non-ID field is accessed. If the entity does not exist, accessing the proxy throws `EntityNotFoundException`.

Use `getReference()` when you only need the entity as a foreign key reference (e.g., setting a `@ManyToOne` relationship) - it avoids an unnecessary SELECT.

```java
// Saves a SELECT query:
order.setUser(
    em.getReference(User.class, userId));
```

_What separates good from great:_ The FK reference optimization use case.

---

**Q2 [MID - DEBUGGING]: "detached entity passed to persist" - what happened?**

_Why they ask:_ Common real-world error.
_Likely follow-up:_ "How do you fix it?"

**Answer:**
This exception means you called `persist()` on an entity that already has an ID (it was previously persisted and is now detached).

Root causes:

1. Entity loaded in one transaction, modified, then `persist()` called in another transaction
2. Entity deserialized from JSON (has ID from client) passed to `persist()`
3. Entity loaded, session cleared, then `persist()` called

Fix: Use `merge()` instead of `persist()` for detached entities. `merge()` copies state into a managed entity (loading from DB if needed).

```java
// Wrong: persist detached
em.persist(detachedUser); // Exception!

// Right: merge detached
User managed = em.merge(detachedUser);
```

Spring Data's `save()` handles this automatically: calls `persist()` if `isNew()`, `merge()` otherwise.

_What separates good from great:_ Explaining the three root causes and Spring Data's automatic handling.

---

**Q3 [SENIOR - TRADE-OFF]: persist() vs merge() vs save() - decision framework.**

_Why they ask:_ Tests nuanced understanding.
_Likely follow-up:_ "What about assigned IDs?"

**Answer:**

| Method    | Input     | Returns      | SQL             | When                       |
| --------- | --------- | ------------ | --------------- | -------------------------- |
| persist() | Transient | void         | INSERT          | New entity, generated ID   |
| merge()   | Detached  | Managed copy | SELECT + UPDATE | Re-attach detached         |
| save()    | Either    | Managed      | Delegates       | Spring Data (auto-detects) |

Edge case: entities with assigned IDs (not `@GeneratedValue`). Spring Data's `isNew()` checks if ID is null. With assigned IDs, it is never null, so `save()` always calls `merge()` - causing an unnecessary SELECT.

Fix: implement `Persistable<ID>`:

```java
@Entity
public class Product
        implements Persistable<String> {
    @Id
    private String sku; // assigned

    @Transient
    private boolean isNew = true;

    public boolean isNew() {
        return isNew;
    }

    @PostLoad @PostPersist
    void markNotNew() { isNew = false; }
}
```

_What separates good from great:_ The assigned ID edge case and `Persistable` fix.

---

### 🔗 Related Keywords

**Prerequisites:** Persistence Context, JDBC

**Builds on:** JPQL and HQL, Spring Data JPA

**Alternatives:** Spring Data repositories (higher-level API)

---

---

# JPQL and HQL

**TL;DR** - JPQL (Java Persistence Query Language) queries entities and their fields using object-oriented syntax (`SELECT u FROM User u WHERE u.email = :email`), not tables and columns - providing database-independent queries that work with the persistence context and support joins across entity relationships.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
SQL queries reference tables and columns (`SELECT * FROM users WHERE email = ?`). If you rename a column, all queries break. Queries are database-specific (PostgreSQL vs MySQL syntax differences). Result sets are rows/columns that must be manually mapped to objects.

**THE INVENTION MOMENT:**
"What if queries referenced Java entities and fields instead of tables and columns?"

---

### 📘 Textbook Definition

JPQL is the query language defined by the JPA specification. It operates on entities and their persistent fields, not database tables. HQL (Hibernate Query Language) is Hibernate's superset of JPQL with additional features (e.g., `INSERT INTO ... SELECT`). JPQL queries are validated against the entity model at deployment time. Results are managed entities (tracked by the persistence context) unless projections or DTO constructors are used.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
SQL queries tables; JPQL queries Java entities. Same concepts, different abstraction level.

**One insight:**
JPQL query results are managed entities by default - they enter the persistence context and are tracked for changes. This means a JPQL SELECT followed by a field modification triggers an UPDATE at flush. For read-only queries, use DTO projections to avoid persistence context overhead.

---

### 📶 Gradual Depth - Five Levels

**Level 2 - How to use (junior):**

```java
// Basic query
List<User> users = em.createQuery(
    "SELECT u FROM User u "
    + "WHERE u.status = :status",
    User.class)
    .setParameter("status", "ACTIVE")
    .getResultList();

// Join across relationships
List<Order> orders = em.createQuery(
    "SELECT o FROM Order o "
    + "JOIN o.user u "
    + "WHERE u.email = :email",
    Order.class)
    .setParameter("email", "j@x.com")
    .getResultList();

// Aggregate
Long count = em.createQuery(
    "SELECT COUNT(u) FROM User u "
    + "WHERE u.age > :age",
    Long.class)
    .setParameter("age", 18)
    .getSingleResult();
```

**Level 3 - How it works (mid-level):**

JPQL vs SQL:

| JPQL                   | SQL Equivalent                     |
| ---------------------- | ---------------------------------- |
| `SELECT u FROM User u` | `SELECT * FROM users`              |
| `u.department.name`    | `JOIN departments d ON ... d.name` |
| `:param`               | `?` (positional)                   |
| `NEW UserDto(u.name)`  | Manual ResultSet mapping           |

JOIN FETCH (solve N+1):

```java
// Without JOIN FETCH: N+1 queries
List<Order> orders = em.createQuery(
    "SELECT o FROM Order o",
    Order.class).getResultList();
// 1 query for orders
// N queries for order.user (lazy)

// With JOIN FETCH: 1 query
List<Order> orders = em.createQuery(
    "SELECT o FROM Order o "
    + "JOIN FETCH o.user",
    Order.class).getResultList();
// 1 query with JOIN
```

**Level 4 - Mastery (senior/staff+):**

DTO projection (no managed entities):

```java
List<UserSummary> summaries =
    em.createQuery(
    "SELECT NEW com.app.dto"
    + ".UserSummary(u.name, u.email) "
    + "FROM User u "
    + "WHERE u.status = 'ACTIVE'",
    UserSummary.class)
    .getResultList();
// No entities in persistence context
// No dirty checking overhead
// No lazy loading traps
```

Bulk operations (bypass context):

```java
// Bulk UPDATE - no entity loading
int updated = em.createQuery(
    "UPDATE User u "
    + "SET u.status = 'INACTIVE' "
    + "WHERE u.lastLogin < :date")
    .setParameter("date", cutoff)
    .executeUpdate();
// WARNING: persistence context
// is now stale! Call em.clear()
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use JPQL instead of native SQL for portability."

**A Staff says:** "I use JPQL with JOIN FETCH for entity queries (solving N+1), DTO projections for read-only queries (avoiding context overhead), and bulk JPQL for mass updates (avoiding entity loading). I know when JPQL is insufficient (window functions, CTEs, DB-specific features) and switch to native SQL."

---

### 💻 Code Example

**BAD N+1 query vs GOOD JOIN FETCH:**

```java
// BAD - N+1 queries
@Query("SELECT o FROM Order o")
List<Order> findAll();
// Accessing o.getUser().getName()
// triggers N additional SELECTs

// GOOD - JOIN FETCH
@Query("SELECT o FROM Order o "
    + "JOIN FETCH o.user "
    + "JOIN FETCH o.items")
List<Order> findAllWithDetails();
// Single query with JOINs
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Object-oriented query language for JPA entities (not tables).

**KEY INSIGHT:** JPQL results are managed entities (tracked). Use DTO projections for read-only.

**ANTI-PATTERN:** Iterating entities to access lazy associations (N+1). Using JPQL for bulk analytics.

**ONE-LINER:** "JPQL queries entities; JOIN FETCH solves N+1; DTO projections avoid context overhead."

**If you remember only 3 things:**

1. JPQL operates on entities and fields, not tables and columns
2. JOIN FETCH loads associations in one query (prevents N+1)
3. DTO projections skip the persistence context (better for reads)

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: What is JPQL and how is it different from SQL?**

_Why they ask:_ Foundation knowledge.
_Likely follow-up:_ "Can you use SQL in JPA?"

**Answer:**
JPQL queries Java entities and their fields. SQL queries database tables and columns.

JPQL: `SELECT u FROM User u WHERE u.email = :email`
SQL: `SELECT * FROM users WHERE email = ?`

Key differences: JPQL uses entity names (not table names), field names (not column names), and supports object navigation (`u.department.name` auto-generates JOINs). JPQL is database-independent. For DB-specific features, use `@Query(nativeQuery = true)` with SQL.

_What separates good from great:_ Mentioning that JPQL results are managed entities.

---

**Q2 [MID]: How does JOIN FETCH solve the N+1 problem?**

_Why they ask:_ Most common JPA performance issue.
_Likely follow-up:_ "Can you JOIN FETCH multiple collections?"

**Answer:**
N+1 problem: 1 query loads N entities, then accessing a lazy association on each triggers N additional queries.

JOIN FETCH: `SELECT o FROM Order o JOIN FETCH o.user` generates a single SQL JOIN, loading both orders and users in one query.

Limitation: you cannot JOIN FETCH two collections (`@OneToMany`) simultaneously - Hibernate throws `MultipleBagFetchException`. Fix: use `Set` instead of `List`, or fetch one collection with JOIN FETCH and the other with `@BatchSize`.

_What separates good from great:_ The MultipleBagFetchException limitation.

---

### 🔗 Related Keywords

**Prerequisites:** SQL, Entity Mapping, Persistence Context

**Builds on:** Criteria API, DTO Projections, Spring Data derived queries

**Alternatives:** Native SQL, Criteria API, Querydsl, JOOQ

---

---

# Entity Mapping Fundamentals

**TL;DR** - JPA entity mapping uses annotations (`@Entity`, `@Table`, `@Column`, `@Id`, `@GeneratedValue`) to define the object-relational mapping between Java classes and database tables - controlling table names, column types, primary key generation strategies, and embedded value objects.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Developers manually map every Java field to a database column in every DAO method. Column name changes require finding and updating every SQL statement. Object graphs and table structures are connected by convention only - no validation.

---

### 📘 Textbook Definition

JPA entity mapping is the declarative specification of how Java classes map to relational database tables. `@Entity` marks a class as a persistent entity. `@Table` specifies the table name. `@Column` configures column name, type, constraints. `@Id` marks the primary key. `@GeneratedValue` defines key generation (IDENTITY, SEQUENCE, TABLE, UUID). `@Embeddable`/`@Embedded` maps value objects without their own table. `@Enumerated` maps enums. `@Temporal` maps dates. `@Lob` maps large objects.

---

### 📶 Gradual Depth - Five Levels

**Level 2 - How to use (junior):**

```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(
        strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "full_name",
        nullable = false, length = 100)
    private String name;

    @Column(unique = true)
    private String email;

    @Enumerated(EnumType.STRING)
    private Status status;

    @CreationTimestamp
    private Instant createdAt;

    @UpdateTimestamp
    private Instant updatedAt;
}
```

**Level 3 - How it works (mid-level):**

ID generation strategies:

| Strategy | Mechanism         | Batch Friendly         |
| -------- | ----------------- | ---------------------- |
| IDENTITY | DB auto-increment | No (INSERT to get ID)  |
| SEQUENCE | DB sequence       | Yes (pre-allocate IDs) |
| TABLE    | Sequence table    | Yes (portable)         |
| UUID     | Java UUID         | Yes (no DB call)       |

```java
// SEQUENCE (best for batch inserts)
@Id
@GeneratedValue(
    strategy = GenerationType.SEQUENCE,
    generator = "user_seq")
@SequenceGenerator(
    name = "user_seq",
    sequenceName = "user_sequence",
    allocationSize = 50)
private Long id;
// Pre-allocates 50 IDs at once
// No DB round-trip per INSERT
```

Embedded value objects:

```java
@Embeddable
public class Address {
    private String street;
    private String city;
    @Column(name = "zip_code")
    private String zipCode;
}

@Entity
public class User {
    @Embedded
    private Address address;
    // Maps to columns in users table:
    // street, city, zip_code
}
```

**Level 4 - Mastery (senior/staff+):**

Why IDENTITY breaks batching:

```
  IDENTITY strategy:
    em.persist(user1) -> INSERT -> get id
    em.persist(user2) -> INSERT -> get id
    em.persist(user3) -> INSERT -> get id
    // 3 round trips, no batching possible!

  SEQUENCE with allocationSize=50:
    SELECT nextval('seq') -> get 50 IDs
    em.persist(user1) -> uses pre-allocated
    em.persist(user2) -> uses pre-allocated
    ...
    em.flush() -> batch INSERT all 50
    // 1 round trip + 1 batch INSERT
```

`@Version` for optimistic locking:

```java
@Version
private Long version;
// Hibernate adds:
// WHERE id = ? AND version = ?
// to UPDATE statements
// Throws OptimisticLockException
// on concurrent modification
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `@Entity` and `@Id` to map classes to tables."

**A Staff says:** "I choose SEQUENCE over IDENTITY for batch-friendly inserts (allocationSize=50). I use `@Embedded` for value objects (DDD). I always add `@Version` for optimistic locking. I map enums as STRING (not ORDINAL) to prevent breakage when enum values are reordered."

---

### 💻 Code Example

**BAD ORDINAL enum vs GOOD STRING enum:**

```java
// BAD - ORDINAL (default)
@Enumerated(EnumType.ORDINAL)
private Status status;
// ACTIVE=0, INACTIVE=1, SUSPENDED=2
// If you reorder enum values,
// all existing data is corrupted!

// GOOD - STRING
@Enumerated(EnumType.STRING)
private Status status;
// Stored as "ACTIVE", "INACTIVE"
// Safe to reorder, add, remove values
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Annotation-based object-relational mapping for Java entities.

**KEY INSIGHT:** Use SEQUENCE over IDENTITY for batch inserts. STRING over ORDINAL for enums.

**ANTI-PATTERN:** ORDINAL enums. IDENTITY with batch processing. Missing @Version.

**ONE-LINER:** "@Entity + @Table + @Id + @GeneratedValue = the mapping foundation."

**If you remember only 3 things:**

1. SEQUENCE (allocationSize=50) for batch-friendly ID generation
2. @Enumerated(STRING) always - ORDINAL corrupts on reorder
3. @Version for optimistic locking on every entity

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: Why choose SEQUENCE over IDENTITY for ID generation?**

_Why they ask:_ Performance knowledge.
_Likely follow-up:_ "What is allocationSize?"

**Answer:**
IDENTITY forces an INSERT for every `persist()` call because the ID is generated by the database auto-increment. Hibernate cannot batch these INSERTs.

SEQUENCE allows pre-allocating IDs in blocks (allocationSize=50). Hibernate calls `SELECT nextval()` once, gets 50 IDs, assigns them in memory, and batches all 50 INSERTs in a single JDBC batch. For 10K inserts: IDENTITY = 10K round trips. SEQUENCE = 200 sequence calls + batch inserts.

_What separates good from great:_ The batching math and round-trip comparison.

---

**Q2 [SENIOR - TRADE-OFF]: @Embedded value objects vs separate entity - when?**

_Why they ask:_ Domain modeling decision.
_Likely follow-up:_ "How does it affect queries?"

**Answer:**

**@Embedded (value object):** No separate table. Columns in the parent table. No ID. No lifecycle. Use for: Address, Money, DateRange - things defined by value, not identity.

**Separate entity:** Own table, own ID, own lifecycle. Use for: things with independent identity that are shared or queried independently.

Decision: Does this concept have its own identity? Can two instances be "equal" by value? If yes to "value equality" - Embeddable. If it has independent identity - Entity.

DDD alignment: Value Object = @Embeddable. Entity = @Entity.

_What separates good from great:_ The DDD value object vs entity distinction.

---

### 🔗 Related Keywords

**Prerequisites:** SQL DDL, Java annotations

**Builds on:** Relationships, Inheritance Mapping

**Related:** Flyway/Liquibase (schema migration)

---

---

# Dirty Checking and Flush Modes

**TL;DR** - Dirty checking is Hibernate's mechanism to detect which managed entities have changed by comparing current field values against snapshots taken at load time - automatically generating UPDATE SQL at flush without explicit save calls, with flush timing controlled by FlushMode (AUTO, COMMIT, MANUAL).

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Developers must call `em.update(entity)` after every modification. If they forget, changes are lost. If they call it unnecessarily, redundant UPDATEs hit the database. There is no way to batch multiple changes into a single flush.

---

### 📘 Textbook Definition

Dirty checking is the process by which the persistence provider compares each managed entity's current state to its original snapshot (taken at the time the entity entered the persistence context). At flush time, for each entity where at least one field differs from the snapshot, an UPDATE statement is generated. By default, the UPDATE includes ALL columns (`@DynamicUpdate(false)`). FlushMode controls WHEN dirty checking and SQL execution occur: AUTO (before queries and at commit), COMMIT (only at commit), MANUAL (only when `flush()` is explicitly called).

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Hibernate remembers what your entity looked like when loaded and automatically generates UPDATE SQL for any fields you changed.

**One insight:**
Dirty checking iterates ALL managed entities at flush time, even if only one changed. With 10K entities in context, that is 10K comparisons. This is why batch processing needs periodic `clear()` and why `readOnly = true` transactions can skip dirty checking entirely.

---

### 📶 Gradual Depth

**Level 2 - How it works (junior):**

```java
@Transactional
void updateUser(Long id) {
    User user = repo.findById(id).get();
    // Snapshot taken: {name:"John"}

    user.setName("Jane");
    // No save() call needed!

    // At TX commit, flush triggers:
    // Compare: "Jane" != "John"
    // -> UPDATE users SET name='Jane'
    //    WHERE id=1
}
```

**Level 3 - How it works (mid-level):**

Flush triggers (AUTO mode):

```
  1. Before any JPQL/SQL query
     (ensures query sees current state)

  2. At transaction commit
     (ensures changes are persisted)

  3. Explicit em.flush() call
     (developer-controlled)

  NOT triggered by:
  - em.find() (PK lookup uses cache)
  - Entity field access
  - Spring Data findById()
```

@DynamicUpdate:

```java
// Default: UPDATE ALL columns
// UPDATE users SET name=?, email=?,
//   status=?, age=? WHERE id=?
// (even if only name changed)

@Entity
@DynamicUpdate
public class User {
    // UPDATE users SET name=?
    //   WHERE id=?
    // Only changed columns
    // But: no statement caching
}
```

**Level 4 - Mastery (senior/staff+):**

Read-only optimization:

```java
// Skip dirty checking entirely
@Transactional(readOnly = true)
public List<User> findActive() {
    return repo.findByStatus("ACTIVE");
    // Hibernate sets FlushMode.MANUAL
    // No dirty checking at all
    // No snapshots taken (Hibernate 6)
    // Faster + less memory
}
```

Bytecode enhancement (optional):

```xml
<!-- Hibernate 6 can use bytecode
     enhancement for field-level
     dirty checking instead of
     snapshot comparison -->
<plugin>
    <artifactId>
        hibernate-enhance-maven-plugin
    </artifactId>
    <configuration>
        <enableDirtyTracking>
            true
        </enableDirtyTracking>
    </configuration>
</plugin>
```

With bytecode enhancement, entities track their own changes via intercepted setters. No snapshot comparison needed. O(1) instead of O(N).

**The Senior-to-Staff Leap:**

**A Senior says:** "Hibernate detects changes automatically."

**A Staff says:** "I use `readOnly = true` for query transactions (skips dirty checking and snapshots). I choose `@DynamicUpdate` for wide tables with frequent partial updates. I understand the O(N) cost of snapshot comparison and manage context size accordingly. For batch operations, I use `StatelessSession` to avoid dirty checking entirely."

---

### 💻 Code Example

**BAD unnecessary flush vs GOOD read-only:**

```java
// BAD - dirty checking on read-only TX
@Transactional
public List<User> findAll() {
    return repo.findAll();
    // Entities are managed
    // Dirty checking runs at commit
    // Wasted CPU for read-only operation
}

// GOOD - skip dirty checking
@Transactional(readOnly = true)
public List<User> findAll() {
    return repo.findAll();
    // Hibernate sets MANUAL flush
    // No dirty checking
    // No snapshots (Hibernate 6)
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Snapshot-based change detection that auto-generates UPDATE SQL.

**KEY INSIGHT:** O(N) cost per flush. readOnly=true skips it entirely.

**ANTI-PATTERN:** Large persistence context with frequent flushes. Missing readOnly on queries.

**ONE-LINER:** "Snapshot at load, compare at flush, UPDATE if different."

**If you remember only 3 things:**

1. Dirty checking compares all managed entities to snapshots at flush
2. @Transactional(readOnly = true) skips dirty checking (FlushMode.MANUAL)
3. @DynamicUpdate for partial column updates on wide tables

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: How does Hibernate's dirty checking work?**

_Why they ask:_ Core ORM internals.
_Likely follow-up:_ "What is the performance impact?"

**Answer:**
When an entity becomes managed, Hibernate takes a snapshot of all field values. At flush time (before queries in AUTO mode, or at commit), it iterates ALL managed entities and compares each field to its snapshot. For any difference, it generates an UPDATE.

Performance: O(N) comparison where N = managed entity count. 10K entities = 10K comparisons per flush, even if only 1 changed. Mitigation: `readOnly = true` (skips entirely), `FlushMode.COMMIT` (reduces frequency), `clear()` in batches.

Default: UPDATE ALL columns. `@DynamicUpdate`: UPDATE only changed columns (no statement caching trade-off).

_What separates good from great:_ The O(N) cost analysis and three mitigation strategies.

---

**Q2 [SENIOR - TRADE-OFF]: @DynamicUpdate - when to use and when to avoid?**

_Why they ask:_ Performance trade-off.
_Likely follow-up:_ "How does it interact with statement caching?"

**Answer:**

**Use @DynamicUpdate when:**

- Wide tables (50+ columns) with frequent partial updates
- Database triggers fire on specific column changes
- Optimistic locking without version column (compare all columns)

**Avoid @DynamicUpdate when:**

- Narrow tables (< 10 columns) - overhead not worth it
- Write-heavy workloads relying on prepared statement caching
- Most updates touch most columns anyway

Trade-off: Without @DynamicUpdate, Hibernate pre-compiles one UPDATE statement per entity at startup (cacheable). With @DynamicUpdate, it builds a new statement per flush based on changed fields (not cacheable). For narrow tables, the caching benefit outweighs the reduced column count.

_What separates good from great:_ The prepared statement caching trade-off.

---

### 🔗 Related Keywords

**Prerequisites:** Persistence Context, Entity Lifecycle

**Builds on:** Transaction Management, Batch Processing

**Related:** @DynamicUpdate, @DynamicInsert, StatelessSession
