---
layout: default
title: "Hibernate - L1 Foundations"
parent: "Hibernate"
nav_order: 2
permalink: /hibernate/l1-foundations/
---

# Hibernate - L1 Foundations

Core Hibernate vocabulary: SessionFactory, Session, entity
mapping, basic CRUD, and HQL. The building blocks used
in every Hibernate application.

---

# SessionFactory and Session

**Interview Weight:** foundational - `SessionFactory` vs
`Session` is the "thread safety 101" question for Hibernate.
Confusing them causes production thread safety issues.

---

### 🎯 Model Answer

**30 seconds:**

> `SessionFactory` is a thread-safe, heavyweight singleton
> created once at startup. It represents the database
> connection pool and entity mapping metadata. `Session`
> is a lightweight, non-thread-safe, short-lived object
> representing a unit of work. One `Session` per request
> or transaction. The `Session` is the first-level cache.
> In Spring: `SessionFactory` is a Spring bean; `Session`
> is obtained per transaction via `@Transactional`.

**3 minutes:**

> `SessionFactory` responsibilities:
> - Parses entity mappings (`@Entity` annotations, XML)
> - Configures the connection pool (HikariCP)
> - Provides `Session` instances
> - Holds the second-level cache (if configured)
> - Heavyweight: takes 2-5 seconds to create. Created ONCE.
>
> `Session` responsibilities:
> - Represents one transaction/unit of work
> - Holds the first-level cache (identity map: one object
>   per primary key per session)
> - Tracks entity state changes (dirty checking)
> - Queues SQL until flush
> - Must be closed after use (resource: DB connection leased)
>
> Thread safety:
> - `SessionFactory`: thread-safe. Share freely.
> - `Session`: NOT thread-safe. Never share between threads.
>   One session per thread (Spring's `@Transactional` binds
>   sessions to threads via `TransactionSynchronizationManager`).

---

### 📘 Concept Explanation

**SessionFactory vs Session:**

```
  APPLICATION STARTUP (once)
  SessionFactory
    - Parses @Entity classes
    - Configures connection pool
    - Holds L2 cache
    - IMMUTABLE after creation
    [THREAD-SAFE: share across all threads]

  PER REQUEST/TRANSACTION (short-lived)
  Session = EntityManager
    - One unit of work
    - First-level cache
      (identity map: id -> entity instance)
    - Dirty tracking
    - Queues SQL changes
    - Must be closed (releases DB connection)
    [NOT THREAD-SAFE: one per thread]
```

---

### 💻 Code Example

**Wrong vs Right: Session usage**

```java
// BAD: shared Session across threads (data corruption)
@Service
public class OrderService {
    // NEVER store Session as a field
    private Session sharedSession;  // race condition!

    public Order findOrder(Long id) {
        return sharedSession.get(Order.class, id);
        // Thread A and B both access sharedSession:
        // first-level cache corruption
    }
}
```

```java
// GOOD: Session per transaction (via @Transactional)
@Service
@RequiredArgsConstructor
public class OrderService {

    private final EntityManager entityManager;
    // EntityManager (JPA) wraps Hibernate Session
    // Spring injects a thread-local proxy:
    // each thread gets its own Session

    @Transactional(readOnly = true)
    public Order findOrder(Long id) {
        return entityManager.find(Order.class, id);
        // Session opened for this @Transactional scope
        // Closed and connection returned when tx ends
    }

    // Access to native Hibernate Session when needed:
    @Transactional
    public void flushSpecific() {
        Session session = entityManager.unwrap(Session.class);
        session.flush();
    }
}
```

> **Code walkthrough:** Spring's `EntityManager` injection
> gives a thread-local proxy. Each thread that calls a
> `@Transactional` method gets its own `Session` bound
> to its thread. When the transaction ends, the session
> is closed and the database connection is returned to
> the pool. The `entityManager.unwrap(Session.class)` call
> exposes the Hibernate-specific `Session` when Hibernate
> extensions are needed. The proxied `EntityManager` is
> thread-safe because it routes each call to the calling
> thread's bound session.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> The `SessionFactory = EntityManagerFactory` equivalence
> is important. In a Spring Boot app, you configure one
> `DataSource`, and Spring creates one `EntityManagerFactory`
> (which is backed by Hibernate's `SessionFactory`). You
> rarely interact with `SessionFactory` directly - Spring
> Data JPA and `@Transactional` manage the session lifecycle.
>
> When you DO need direct access: use `entityManager.unwrap
> (Session.class)` for Hibernate-specific features. Never
> store a `Session` in a field or singleton. Always close
> it (or let `@Transactional` close it).

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | EntityManager is the same as Session | EntityManager is the JPA interface. Session is Hibernate's interface. They have the same scope and lifecycle (one per transaction). Spring injects a proxy that delegates to the current thread's Session. `entityManager.unwrap(Session.class)` gets the underlying Session. | Candidates who conflate them miss the JPA/Hibernate layering |
| 2 | SessionFactory can be created per request | SessionFactory initialization is expensive (2-5 seconds, parses all mappings, configures pool). Creating it per request would add 2-5 seconds to every request. Always create once at startup. | Performance disaster |

---

### 🎯 Interview Deep-Dive

**[JUNIOR] Q1: What is the difference between SessionFactory and Session?**

`SessionFactory`: singleton, created once at startup,
heavyweight (parses mappings, configures pool), thread-safe.
`Session`: short-lived, one per transaction/request,
lightweight, NOT thread-safe.

`Session` = first-level cache: within a session, loading
the same entity twice (same ID) returns the same Java
object. Avoids redundant SELECT queries within a transaction.

Spring manages the session lifecycle via `@Transactional`:
opens session, binds to thread, executes your code, closes
session. You never open/close sessions manually in Spring apps.

*What separates good from great:* Mentioning that the
`EntityManager` Spring injects is a thread-local proxy -
the same `EntityManager` reference is safe to share as
a field because it routes to the calling thread's session.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with thread safety and lifecycle. |
| Hiring Manager | Lead with Spring integration (no manual session management). |
| Bar Raiser | Lead with SessionFactory as EntityManagerFactory and the thread-local proxy mechanism. |

---

---

# Entity Mapping with @Entity and @Id

**Interview Weight:** foundational - Basic mapping is
assumed knowledge. Questions focus on: ID generation
strategies, column mapping nuances, and Hibernate-specific
annotations beyond the JPA standard.

---

### 🎯 Model Answer

**30 seconds:**

> `@Entity` marks a class as a Hibernate-managed entity.
> `@Id` marks the primary key. `@GeneratedValue` with a
> strategy controls ID generation: `IDENTITY` (database
> auto-increment), `SEQUENCE` (database sequence, more
> efficient), `AUTO` (Hibernate chooses). `@Table`,
> `@Column`, `@Temporal`, and `@Enumerated` customize
> table and column mappings.

---

### 📘 Concept Explanation

**ID generation strategies:**

```
  ID GENERATION STRATEGIES

  IDENTITY: database auto-increment
    INSERT INTO orders (total) VALUES (?)
    -> DB returns generated id
    -> Hibernate sets id on entity
    Downside: requires a DB round-trip per INSERT
    (prevents batch INSERTs)

  SEQUENCE: database sequence object
    SELECT nextval('order_seq')  <- Hibernate pre-fetches
    INSERT INTO orders (id, total) VALUES (?, ?)
    Advantage: can batch-allocate IDs (allocationSize=50)
    Default for PostgreSQL when using SEQUENCE strategy

  TABLE: emulated sequence via a table
    (avoid - slow, lock contention)

  UUID: application-generated UUID
    No DB round-trip for ID generation
    Better for distributed systems
    Larger storage (16 bytes vs 8 for BIGINT)
```

---

### 💻 Code Example

**Production entity mapping with best practices**

```java
@Entity
@Table(name = "orders",
    indexes = {
        @Index(name = "idx_orders_customer",
               columnList = "customer_id"),
        @Index(name = "idx_orders_status",
               columnList = "status,created_at")
    })
public class Order {

    @Id
    // SEQUENCE: allows batch INSERT, no extra round-trip
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
        generator = "order_seq")
    @SequenceGenerator(
        name = "order_seq",
        sequenceName = "order_id_seq",
        allocationSize = 50)  // pre-allocates 50 IDs
    private Long id;

    @Column(name = "status", nullable = false,
            length = 20)
    @Enumerated(EnumType.STRING)  // store "PENDING" not 0
    private OrderStatus status;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal total;

    @Column(name = "created_at", nullable = false,
            updatable = false)  // never updated after insert
    private LocalDateTime createdAt;

    @Version  // optimistic locking (covered in L3)
    private Long version;
}
```

> **Code walkthrough:** `SEQUENCE` strategy with `allocationSize=50`
> pre-allocates 50 IDs from the database sequence in one
> round-trip. Hibernate uses them for 50 consecutive INSERTs
> without additional DB calls - enabling batch INSERT performance.
> `@Enumerated(EnumType.STRING)` stores the enum name as a
> string ("PENDING", "COMPLETED") - readable and safe when
> enum values are reordered. `EnumType.ORDINAL` (the default)
> stores an integer position - breaks when enum values are
> reordered. `updatable = false` on `createdAt` prevents
> Hibernate from including this column in UPDATE statements.
> `@Index` creates database indexes for common query patterns.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> ID generation strategy choice matters for batch insert
> performance. `IDENTITY` requires a separate SELECT for
> the generated ID after each INSERT - this prevents JDBC
> batch INSERT. `SEQUENCE` with `allocationSize=50` allows
> Hibernate to generate IDs without extra DB round-trips
> and enables JDBC batch INSERT. For PostgreSQL: use
> `SEQUENCE`. For MySQL: `IDENTITY` is standard (MySQL
> uses AUTO_INCREMENT). For distributed systems: consider
> UUID with `@UuidGenerator` (Hibernate 6) or application-
> generated ULIDs for sortable UUIDs.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: Why is EnumType.ORDINAL dangerous and when
would you use it?** [TRADE-OFF]

`EnumType.ORDINAL` stores the enum's position (0, 1, 2...)
as a number. It is dangerous because: if you reorder enum
values or insert a new value in the middle, all existing
database rows become incorrect. Example: adding `PROCESSING`
between `PENDING` (0) and `COMPLETED` (1) makes all old
"COMPLETED" (1) records become "PROCESSING".

`EnumType.STRING` stores the enum name as text. It is:
safe for reordering, safe for adding new values, and
readable in the database. The cost: slightly more storage
(varchar vs tinyint). For enums with a small number of
values (< 20), the storage difference is negligible.

Use `ORDINAL` only when: strict storage requirements,
large tables (millions of rows), and enum values are
guaranteed never to be reordered (e.g., an enum mapped
to a fixed external protocol value).

*What separates good from great:* Recommending `@Enumerated
(EnumType.STRING)` as the default for all new entities
without being asked, and knowing the exact failure mode
of `ORDINAL`.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with ID generation strategies and batch INSERT implications. |
| Hiring Manager | Lead with mapping best practices. |
| Bar Raiser | Lead with UUID vs sequence for distributed systems and EnumType.ORDINAL failure mode. |

---

---

# Basic CRUD with Hibernate

**Interview Weight:** foundational - CRUD operations are
assumed knowledge. Questions focus on: what Hibernate
does automatically vs explicitly, dirty checking, and
the difference between `save`, `persist`, `merge`.

---

### 🎯 Model Answer

**30 seconds:**

> Hibernate CRUD: `session.persist(entity)` for insert
> (schedules INSERT), `session.get(Class, id)` or
> `entityManager.find()` for read, modify a managed entity
> within a transaction for update (dirty checking issues
> UPDATE automatically on flush), `session.remove(entity)`
> for delete. In Spring: use `EntityManager` via `@Transactional`.
> The key: there is no explicit "update" call - Hibernate
> detects changes via dirty checking and issues the UPDATE
> at flush time.

---

### 📘 Concept Explanation

**CRUD operations and what Hibernate does:**

```
  CREATE: session.persist(entity)
    -> Entity added to first-level cache (PERSISTENT state)
    -> INSERT queued
    -> Executed at flush (before commit)

  READ: entityManager.find(Order.class, id)
    -> Check first-level cache (is it already loaded?)
    -> If not: SELECT * FROM orders WHERE id = ?
    -> Store in first-level cache
    -> Return entity (PERSISTENT state)

  UPDATE: (no explicit call needed)
    Order order = em.find(Order.class, id);
    order.setStatus(COMPLETED);  // entity is managed
    // At flush: Hibernate detects change
    // Issues: UPDATE orders SET status=? WHERE id=?

  DELETE: entityManager.remove(entity)
    -> Entity marked for deletion
    -> DELETE queued
    -> Executed at flush
```

---

### 💻 Code Example

**Wrong vs Right: save vs persist vs merge**

```java
// BAD: using incorrect operation for the context
@Transactional
public void badCreate(Order order) {
    // merge() for a new entity: works but creates
    // a copy (different object). Not the same
    // semantics as persist().
    Order savedOrder = entityManager.merge(order);
    // 'order' is NOT in persistent state after this!
    // 'savedOrder' is the persistent version.
}
```

```java
// GOOD: use the right operation for each case
@Service
@RequiredArgsConstructor
public class OrderCrudService {

    private final EntityManager em;

    // CREATE: persist schedules INSERT
    @Transactional
    public void createOrder(Order order) {
        em.persist(order);
        // After flush: order.getId() is populated
        // (for IDENTITY strategy: after the INSERT)
    }

    // READ: find uses first-level cache
    @Transactional(readOnly = true)
    public Optional<Order> findOrder(Long id) {
        return Optional.ofNullable(
            em.find(Order.class, id));
    }

    // UPDATE: dirty checking - no explicit save needed
    @Transactional
    public void updateStatus(Long id, OrderStatus status) {
        Order order = em.find(Order.class, id);
        if (order != null) {
            order.setStatus(status);
            // No em.merge() or em.save() needed!
            // Hibernate detects the change at flush.
        }
    }

    // UPDATE DETACHED entity: use merge
    @Transactional
    public Order updateDetached(Order detachedOrder) {
        // 'detachedOrder' came from outside transaction
        // merge: copies state to a managed entity
        return em.merge(detachedOrder);
    }

    // DELETE: remove requires managed entity
    @Transactional
    public void deleteOrder(Long id) {
        Order order = em.find(Order.class, id);
        if (order != null) {
            em.remove(order);
            // DELETE issued at flush
        }
    }
}
```

> **Code walkthrough:** Hibernate's dirty checking means
> you never call an explicit "update" method for managed
> entities. The `updateStatus` method is clean: find the
> entity (managed state), modify it (Hibernate tracks the
> change), commit (Hibernate flushes the UPDATE). The
> `updateDetached` method uses `merge` for entities that
> came from outside the transaction (e.g., from a REST
> request body, deserialized from JSON). `merge` copies
> the state of the detached entity to a managed entity
> and returns the managed version. The input object remains
> detached. This subtle behavior (`merge` returns a new
> object) is a common source of bugs if the caller uses
> the original detached object after `merge`.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> In Spring Data JPA, `save(entity)` calls `persist`
> if the entity has no ID, `merge` if it has an ID.
> This works correctly for most cases. The edge case:
> if you set the ID manually before persisting (e.g.,
> UUID generated in the constructor), `save()` will call
> `merge` instead of `persist`, which issues a SELECT
> first to check if the row exists. For performance
> optimization with manual IDs: implement `Persistable<T>`
> and override `isNew()` to tell Spring Data whether to
> call `persist` or `merge`.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: What is the difference between persist, merge, and save in Hibernate/JPA?** [FOUNDATION]

`persist(entity)`: attaches a new (transient) entity to
the session. Entity transitions from TRANSIENT to PERSISTENT.
INSERT queued. The passed-in entity is now managed.

`merge(entity)`: for detached entities (entity with an ID
that is not in the current session). Copies the state to
a new managed entity. The original entity remains detached.
Returns the managed entity. Internally: checks the first-
level cache for the ID, then issues a SELECT, then copies
state.

`save()` (Spring Data JPA's `JpaRepository.save()`): calls
`persist` if `isNew()` returns true (no ID); calls `merge`
if `isNew()` returns false (has ID). Simple and works for
most cases.

Why this matters: if you call `save()` on a detached
entity, it does a SELECT before INSERT (the merge path).
For performance-critical bulk imports with known IDs:
use `persist` directly to avoid the SELECT.

*What separates good from great:* Knowing that `merge`
issues a SELECT first (via `find()` on the session)
and that the returned entity (not the input) is the
managed one.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with dirty checking and merge vs persist distinction. |
| Hiring Manager | Lead with Spring Data JPA `save()` and normal usage. |
| Bar Raiser | Lead with `Persistable<T>` and performance optimization for bulk imports. |

---

---

# HQL Hibernate Query Language

**Interview Weight:** working - HQL is the primary query
language for Hibernate. Questions test: HQL vs JPQL
vs native SQL, JOIN FETCH for N+1 elimination, and
aggregate queries.

---

### 🎯 Model Answer

**30 seconds:**

> HQL (Hibernate Query Language) is an object-oriented
> query language. It queries entity classes and their
> properties (not tables and columns). HQL is a superset
> of JPQL - it adds Hibernate-specific extensions. Use
> HQL/JPQL for standard queries; use native SQL for
> database-specific features and complex analytics. The
> most important HQL pattern: `JOIN FETCH` to eliminate
> N+1 queries by loading associations in one query.

---

### 📘 Concept Explanation

**HQL vs SQL vs JPQL:**

```
  SQL (table/column centric):
  SELECT o.id, o.total, c.name
  FROM orders o
  JOIN customers c ON c.id = o.customer_id
  WHERE o.status = 'PENDING'

  JPQL/HQL (entity/field centric):
  SELECT o FROM Order o
  JOIN FETCH o.customer
  WHERE o.status = :status
  -- "o.customer" is the entity field, not the FK column
  -- Hibernate generates the JOIN ON clause automatically

  HQL extensions over JPQL:
  -- INSERT INTO SELECT
  -- UPDATE/DELETE with subqueries
  -- More functions (str(), cast(), etc.)
```

---

### 💻 Code Example

**Production HQL patterns**

```java
// N+1 elimination: JOIN FETCH loads association in one query
@Repository
public class OrderRepository {

    @PersistenceContext
    private EntityManager em;

    // BAD: N+1 - loads orders, then 1 query per customer
    public List<Order> findPendingBad() {
        return em.createQuery(
            "SELECT o FROM Order o WHERE o.status = :s",
            Order.class)
            .setParameter("s", OrderStatus.PENDING)
            .getResultList();
        // For 100 orders: 1 + 100 customer queries = 101
    }

    // GOOD: JOIN FETCH - 1 query for all orders + customers
    public List<Order> findPendingWithCustomer() {
        return em.createQuery(
            "SELECT o FROM Order o " +
            "JOIN FETCH o.customer " +
            "WHERE o.status = :s",
            Order.class)
            .setParameter("s", OrderStatus.PENDING)
            .getResultList();
        // 1 query with JOIN - all data loaded
    }

    // Projection: select only needed fields (faster)
    public List<OrderSummary> findOrderSummaries() {
        return em.createQuery(
            "SELECT NEW com.example.OrderSummary(" +
            "  o.id, o.total, o.customer.name) " +
            "FROM Order o " +
            "WHERE o.createdAt >= :since",
            OrderSummary.class)
            .setParameter("since",
                LocalDate.now().minusDays(30))
            .getResultList();
        // Loads only 3 fields, no full entity
    }

    // Bulk UPDATE (bypasses dirty checking - efficient)
    @Transactional
    public int cancelOldOrders(LocalDateTime cutoff) {
        return em.createQuery(
            "UPDATE Order SET status = :cancelled " +
            "WHERE status = :pending " +
            "AND createdAt < :cutoff")
            .setParameter("cancelled", OrderStatus.CANCELLED)
            .setParameter("pending", OrderStatus.PENDING)
            .setParameter("cutoff", cutoff)
            .executeUpdate();
    }
}
```

> **Code walkthrough:** `JOIN FETCH o.customer` is the
> most important HQL pattern to know. It adds an SQL
> `JOIN` to include the customer table in the same query.
> Without it: Hibernate issues one `SELECT` per customer
> reference (N+1). The `NEW OrderSummary(...)` constructor
> expression creates DTO objects from query results without
> loading full entities. This is a significant performance
> gain for list endpoints where you only need a few fields.
> `executeUpdate()` for bulk modifications issues one
> `UPDATE` statement - it bypasses entity loading and
> dirty checking completely. Remember: bulk UPDATE/DELETE
> bypasses the first-level and second-level caches -
> evict affected cache regions after bulk operations.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> My HQL decision tree: (1) simple CRUD - use Spring Data
> JPA derived queries (`findByStatus`). (2) Relationship
> fetching needed - use HQL with `JOIN FETCH`. (3) Projection
> (only some fields needed) - use `NEW DTO(...)` constructor
> expression or interface projection. (4) Aggregation (SUM,
> COUNT, GROUP BY) - HQL or native SQL. (5) Complex analytics,
> window functions, CTEs - native SQL.
>
> The `SELECT NEW` pattern is underused. Loading full entities
> for list views that only display id, name, and date is
> wasteful. For large lists: `SELECT NEW` reduces data
> transfer significantly.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: How does JOIN FETCH differ from a regular
JOIN in HQL, and when would you use each?** [TRADE-OFF]

Regular `JOIN` in HQL: used to filter by an association.
The associated entity is NOT loaded into memory unless
also in the `SELECT` clause.

`JOIN FETCH`: loads the association into memory as part
of the query. The resulting entity has the association
pre-loaded (not lazy proxy).

When to use each:
- `JOIN`: filtering. `FROM Order o JOIN o.tags t WHERE t.name = 'urgent'` - filter orders by tag name. Tags are not loaded.
- `JOIN FETCH`: loading. `FROM Order o JOIN FETCH o.customer` - load orders and their customers. No lazy loading needed.
- Both together: `FROM Order o JOIN FETCH o.customer JOIN o.tags t WHERE t.name = 'urgent'` - filter by tag but load customer.

Caution with `JOIN FETCH` and collections:
```java
// BAD: multiple JOIN FETCH on collections
// creates a Cartesian product in the result set
// FROM Order o JOIN FETCH o.items JOIN FETCH o.tags
// Results: order_count * items_count * tags_count rows

// GOOD: use @BatchSize or subselect fetching
// for multiple collections
```

*What separates good from great:* Warning about the
Cartesian product issue with multiple `JOIN FETCH` on
collections - this is a real production performance trap.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with JOIN FETCH for N+1 elimination. |
| Hiring Manager | Lead with HQL as the standard query language and native SQL fallback. |
| Bar Raiser | Lead with SELECT NEW projection and Cartesian product trap with multiple JOIN FETCHes. |

---

---

# Hibernate Configuration and Dialects

**Interview Weight:** working - Dialect configuration
and key Hibernate properties are expected knowledge.
Questions test: why dialects exist, key properties
(`show_sql`, `hbm2ddl.auto`), and the risks of
`update` vs `validate` in production.

---

### 🎯 Model Answer

**30 seconds:**

> Hibernate Dialect tells Hibernate which SQL syntax to
> generate for a specific database (PostgreSQL, MySQL,
> Oracle). In Spring Boot: auto-detected from the JDBC
> URL. Key properties: `show_sql` (log every SQL, dev
> only), `hbm2ddl.auto` (schema management - NEVER use
> `create` or `update` in production), `format_sql` (pretty
> print), `default_batch_fetch_size` (batch lazy loading).

**3 minutes:**

> Critical `hbm2ddl.auto` values:
>
> - `none`: Hibernate does nothing with the schema (correct
>   for production). Use Flyway/Liquibase for schema management.
> - `validate`: Hibernate validates that entity mappings
>   match the database schema at startup. Fails fast if
>   there is a mismatch. Safe for production, but use
>   Flyway in preference.
> - `update`: Hibernate adds missing columns/tables at
>   startup. DANGEROUS in production: it never drops columns
>   (data is not lost but schema diverges), it does not
>   handle all migrations (index changes, column type
>   changes), and in multi-instance deployments, parallel
>   `update` runs can cause race conditions.
> - `create`: drops and recreates all tables at startup.
>   DEV/TEST only. Destroys production data.
> - `create-drop`: creates on startup, drops on shutdown.
>   For integration tests.

---

### 📘 Concept Explanation

**Key Hibernate configuration properties:**

```
  # application.yml (Spring Boot)
  spring.jpa.show-sql=true          # Log SQL (dev only)
  spring.jpa.properties.hibernate
    .format_sql=true                # Pretty-print SQL
    .hbm2ddl.auto=validate          # Schema validation
    .default_batch_fetch_size=25    # Batch lazy loading
    .jdbc.batch_size=50             # JDBC batch inserts
    .order_inserts=true             # Batch optimization
    .order_updates=true             # Batch optimization
    .generate_statistics=false      # Stats (prod monitoring)

  # Dialect (auto-detected by Spring Boot)
  spring.jpa.database-platform=
    org.hibernate.dialect.PostgreSQLDialect
```

---

### 💻 Code Example

**Production Hibernate configuration**

```yaml
# application.yml - Production settings
spring:
  jpa:
    show-sql: false        # OFF in production
    open-in-view: false    # ALWAYS disable in prod
    properties:
      hibernate:
        hbm2ddl:
          auto: validate   # validate mapping vs schema
        # Batch INSERT optimization
        jdbc:
          batch_size: 50
        order_inserts: true
        order_updates: true
        # Second-level cache (Ehcache/Redis)
        cache:
          use_second_level_cache: true
          region:
            factory_class: org.hibernate.cache.jcache
              .internal.JCacheRegionFactory
        # Statistics for monitoring (optional)
        generate_statistics: false

---
# application-dev.yml - Development settings
spring:
  jpa:
    show-sql: true
    properties:
      hibernate:
        format_sql: true
        hbm2ddl:
          auto: validate
          # Use Flyway for actual migrations even in dev
```

> **Code walkthrough:** `open-in-view: false` is critical
> for production. When `true` (Spring Boot's default!),
> Hibernate keeps a session open for the entire HTTP
> request lifecycle, including view rendering. This holds
> a database connection for the full request duration -
> pool exhaustion under load. Always disable in REST APIs.
> `batch_size: 50` with `order_inserts: true` enables JDBC
> batch INSERT: Hibernate groups 50 INSERT statements into
> one JDBC batch, dramatically reducing round-trips for
> bulk operations. `hbm2ddl.auto: validate` is the safe
> production default - it confirms the schema matches the
> entity mappings but never modifies the database.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> Three Hibernate properties I check in every production
> deployment: (1) `open-in-view: false` - connection pool
> exhaustion under load when true. (2) `hbm2ddl.auto:
> validate` or `none` - never `update` in production.
> (3) `batch_size: 50` + `order_inserts: true` - required
> for INSERT-heavy workloads.
>
> Schema management in production: always use Flyway or
> Liquibase. Never rely on `hbm2ddl.auto: update`. Flyway
> gives: version-controlled migrations, audit trail,
> repeatable execution, team coordination.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: Why is hbm2ddl.auto=update dangerous in
production, and what should you use instead?** [TRADE-OFF]

`update` is dangerous because:

1. It never drops columns: if you rename a field, the old
   column remains in the schema. Over time: schema diverges
   from entity mappings. Old columns waste storage and
   confuse developers.

2. Multi-instance race condition: in a rolling deployment
   with 10 instances starting simultaneously, all 10
   attempt schema modifications. Database-level locking
   prevents corruption but may cause startup failures.

3. Cannot handle all migrations: column type changes,
   index modifications, constraint changes are often not
   handled by `update`.

Use Flyway instead:
- Migrations as SQL scripts (`V1__initial.sql`,
  `V2__add_column.sql`)
- Version controlled alongside application code
- Flyway runs migrations in order, records completion
  in `flyway_schema_history`
- Only one Flyway instance runs migrations at a time
  (table-level lock). Other instances wait.
- Spring Boot auto-configures Flyway: add `flyway-core`
  dependency and put scripts in `db/migration/`.

*What separates good from great:* Mentioning the Flyway
lock mechanism - in a multi-instance deployment, Flyway
uses a database-level lock to ensure only one instance
runs migrations. Other instances wait and then proceed
after migration completes. This is the correct multi-
instance migration strategy.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with hbm2ddl.auto dangers and Flyway alternative. |
| Hiring Manager | Lead with open-in-view=false performance impact. |
| Bar Raiser | Lead with Flyway multi-instance migration lock and batch_size optimization. |
