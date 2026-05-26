---
layout: default
title: "Hibernate - L2 Caching and Fetching"
parent: "Hibernate"
nav_order: 4
permalink: /hibernate/l2-caching-and-fetching/
---

# Hibernate - L2 Caching and Fetching

Fetch strategies, the first and second-level caches,
N+1 detection, and query caching. The most impactful
area for Hibernate performance in production.

---

# Eager vs Lazy Loading

**Interview Weight:** working - Fetch strategy is the
most important performance decision in Hibernate. Questions
target: default fetch types, when eager is dangerous,
and how to control fetching.

---

### 🎯 Model Answer

**30 seconds:**

> Lazy loading: associations are loaded only when accessed
> (proxy object until then). Eager loading: associations
> are loaded with the parent entity immediately. Defaults:
> `@ManyToOne` and `@OneToOne` are EAGER (change to LAZY!),
> `@OneToMany` and `@ManyToMany` are LAZY (correct). Always
> make all associations LAZY by default. Load eagerly only
> for specific queries using `JOIN FETCH` or `@EntityGraph`.

**3 minutes:**

> The lazy loading mechanism: Hibernate replaces your
> association with a proxy object (CGLIB subclass). When
> you access any field on the proxy, Hibernate issues
> a SELECT to load the real data. This is transparent to
> calling code.
>
> Why EAGER is dangerous:
> ```java
> // @ManyToOne(fetch = EAGER) on Order.customer
> Order order = session.get(Order.class, id);
> // ^^^ Loads Order AND Customer (EAGER join)
> // Even if you never access order.getCustomer()
> // In a list: 100 orders = 100 customer loads
> ```
>
> Why LAZY + JOIN FETCH is better:
> ```java
> // @ManyToOne(fetch = LAZY) (explicit)
> Order order = session.get(Order.class, id);
> // ^^^ Loads ONLY Order
>
> // When customer is needed:
> session.createQuery("FROM Order o JOIN FETCH o.customer WHERE o.id = :id")
> // ^^^ One query with JOIN, loads both
> ```
>
> The LazyInitializationException trap: accessing a lazy
> association outside the Hibernate session throws
> `LazyInitializationException`. Always access associations
> within the transaction. Never serialize lazy entities
> to the view layer (the Open Session in View anti-pattern
> works around this but causes connection pool exhaustion).

**Framework:** LAZY DEFAULT (all associations) →
EAGER for specific queries (JOIN FETCH / @EntityGraph) →
NEVER eager globally →
@Transactional scope is the safe zone for lazy access

---

### 📘 Concept Explanation

**Lazy vs Eager fetch comparison:**

```
  LAZY LOADING (default recommendation)

  session.get(Order.class, 1L)
    --> SELECT * FROM orders WHERE id = 1
        (customer NOT loaded - proxy created)

  order.getCustomer().getName()
    --> SELECT * FROM customers WHERE id = ?
        (triggered by proxy access)

  EAGER LOADING (dangerous default on @ManyToOne)

  session.get(Order.class, 1L)
    --> SELECT o.*, c.*
        FROM orders o
        JOIN customers c ON c.id = o.customer_id
        WHERE o.id = 1
        (customer always loaded, even if not needed)
```

---

### 💻 Code Example

**Wrong vs Right: fetch type defaults**

```java
// BAD: default EAGER on @ManyToOne (it IS the default!)
@Entity
public class Order {

    // DANGEROUS: default is FetchType.EAGER
    // Every Order load triggers Customer load
    @ManyToOne  // <- implicit EAGER!
    @JoinColumn(name = "customer_id")
    private Customer customer;

    // DANGEROUS: default is FetchType.EAGER
    @OneToOne   // <- implicit EAGER!
    @JoinColumn(name = "shipping_id")
    private ShippingInfo shipping;
}
```

```java
// GOOD: explicit LAZY for all associations by default
@Entity
public class Order {

    // LAZY: only loads when accessed, explicit intent
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    private Customer customer;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shipping_id")
    private ShippingInfo shipping;
}

// Load with required associations for specific use case:
// Option 1: JOIN FETCH
@Repository
public class OrderRepository {
    public Order findOrderWithCustomer(Long id) {
        return em.createQuery(
            "SELECT o FROM Order o " +
            "JOIN FETCH o.customer " +
            "WHERE o.id = :id",
            Order.class)
            .setParameter("id", id)
            .getSingleResult();
    }
}

// Option 2: @EntityGraph (Spring Data JPA)
public interface OrderRepository
    extends JpaRepository<Order, Long> {

    @EntityGraph(attributePaths = {"customer", "items"})
    Optional<Order> findById(Long id);
    // Loads Order, Customer, and Items in one query
}
```

> **Code walkthrough:** The `@ManyToOne` default is `EAGER`
> - this is one of Hibernate's most criticized design
> decisions. The BAD example has two `EAGER` associations.
> Loading a list of 100 orders: each order triggers a load
> of its Customer and ShippingInfo. Even if the endpoint
> only returns the order total. The GOOD example makes all
> associations `LAZY`. For the specific endpoint that needs
> customer data: `JOIN FETCH` loads both in one SQL query.
> `@EntityGraph` in Spring Data JPA is a clean way to
> specify which associations to fetch for a specific query
> method without writing custom HQL.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> My rule: all `@ManyToOne` and `@OneToOne` explicitly
> `FetchType.LAZY`. All `@OneToMany` and `@ManyToMany`
> are already LAZY by default. Then: use `JOIN FETCH` in
> queries or `@EntityGraph` for Spring Data repositories
> to load associations when needed.
>
> Never use `FetchType.EAGER` on any mapping. If an
> endpoint always needs the customer with an order: write
> a specific repository method with `JOIN FETCH`. Other
> endpoints that don't need the customer: they get the
> lazy proxy, no extra SELECT.

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | @ManyToOne default is LAZY | @ManyToOne default is EAGER. This is a historical JPA design decision. Always specify FetchType.LAZY explicitly. | Silent performance issues from unexpected eager loading |
| 2 | Lazy loading works everywhere in the application | Lazy loading requires an open Hibernate session. Outside a @Transactional scope (e.g., after the method returns), the session is closed. Accessing a lazy association throws LazyInitializationException. | LazyInitializationException in serialization or view layer code |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - LazyInitializationException**

Symptom: `LazyInitializationException: could not
initialize proxy - no Session` when accessing a field
on an entity.

Root cause: entity was loaded in a `@Transactional` method,
passed to a layer outside the transaction (e.g., to a
controller that then calls `entity.getLazyAssociation()`),
where the session is already closed.

Fix:
1. Load the required association within the transaction:
   use `JOIN FETCH` or `@EntityGraph`
2. Use a DTO projection: don't pass entities to the
   presentation layer
3. Do NOT use `spring.jpa.open-in-view: true` (the
   "fix" that causes connection pool exhaustion)

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: What is the Open Session in View anti-pattern
and why is it dangerous?** [FAILURE MODE]

*Why they ask:* Tests knowledge of a common "solution" that
creates a worse problem.

*Likely follow-up:* "What is the correct solution?"

Spring Boot sets `spring.jpa.open-in-view=true` by default.
This extends the Hibernate session lifecycle across the
entire HTTP request, including view rendering. Purpose:
prevent `LazyInitializationException` when the view
accesses lazy associations.

Why it is dangerous:
- The Hibernate session holds a database connection for
  the full request duration (including network latency,
  view rendering time)
- Connection pool exhaustion under load: each concurrent
  request holds a connection for 100-500ms (full request)
  instead of just the DB query time (~5ms)
- Hidden lazy loading: views trigger lazy loads silently,
  making N+1 detection difficult

Correct solution: disable `open-in-view` and fix at the
source:
- Use DTOs: never pass entities to the presentation layer
- Use `JOIN FETCH` or `@EntityGraph` for needed associations
- Load all required data within `@Transactional`

`spring.jpa.open-in-view=false` in all production apps.

*What separates good from great:* Quantifying the impact:
a Spring Boot app with OIAV=true and 50 concurrent users
with 200ms average response time holds 50 DB connections
for 200ms each. A connection pool of 20 causes queuing.
With OIAV=false: connections held for ~10ms query time,
pool of 20 handles hundreds of concurrent requests.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with fetch type defaults and JOIN FETCH as the solution. |
| Hiring Manager | Lead with Open Session in View anti-pattern and production risk. |
| Bar Raiser | Lead with connection pool exhaustion math and the correct DTO-based solution. |

---

---

# First-Level Cache Session Cache

**Interview Weight:** working - First-level cache is the
identity map. Questions test: what it guarantees, when it
is flushed, and when it causes problems (stale data in
long sessions).

---

### 🎯 Model Answer

**30 seconds:**

> The first-level cache (Session cache) is an identity map:
> within one Hibernate session (transaction), loading the
> same entity twice (same class, same ID) returns the same
> Java object - no second SELECT. This guarantees identity
> consistency within a transaction. Caveat: the cache is
> only valid for one session. Long-running sessions with
> stale data (entity modified by another transaction) will
> not see the updated data. Fix: call `session.refresh(entity)`
> or `session.evict(entity)` to force a reload.

---

### 📘 Concept Explanation

**First-level cache behavior:**

```
  WITHIN ONE SESSION/TRANSACTION:

  session.get(Order.class, 1L)
    --> SELECT * FROM orders WHERE id = 1
        result: Order@abc123 {id=1, total=100}
        stored in L1 cache: {Order#1 -> Order@abc123}

  session.get(Order.class, 1L)  (same id)
    --> NO SELECT (L1 cache hit)
        returns same object: Order@abc123

  ACROSS SESSIONS (no cache sharing):

  Session A: session.get(Order.class, 1)  -> Order {total=100}
  Session B: UPDATE orders SET total=200 WHERE id=1
  Session A: session.get(Order.class, 1)  -> Order {total=100}
  ^^ Still 100! Session A's L1 cache is stale.
  session.refresh(order) -> SELECT ... total=200 (refreshed)
```

---

### 💻 Code Example

**First-level cache scenarios**

```java
@Transactional
public void demonstrateL1Cache() {
    // First load: SELECT issued
    Order order1 = em.find(Order.class, 1L);

    // Second load: NO SQL - returns same instance
    Order order2 = em.find(Order.class, 1L);

    // True: same Java object (identity guarantee)
    assert order1 == order2;  // reference equality

    // Modify via one reference
    order1.setStatus(COMPLETED);
    // order2.getStatus() is also COMPLETED
    // (same object in memory)
}

@Transactional
public void handleStaleData(Long orderId) {
    Order order = em.find(Order.class, orderId);
    // ... some logic ...

    // Another transaction may have updated this order
    // Reload from DB (bypasses L1 cache)
    em.refresh(order);
    // Now: order reflects current DB state

    // Or: evict from L1 cache (next find() will SELECT)
    // em.detach(order);
    // Order fresh = em.find(Order.class, orderId);
}

// Clearing the entire L1 cache:
@Transactional
public void bulkProcessWithClear() {
    for (int i = 0; i < 10000; i++) {
        Order order = processNextOrder();
        em.persist(order);

        // Flush and clear every 100 to avoid
        // L1 cache growing unboundedly
        if (i % 100 == 0) {
            em.flush();   // write to DB
            em.clear();   // clear L1 cache (free memory)
        }
    }
}
```

> **Code walkthrough:** The identity guarantee is shown:
> loading the same ID twice returns `==` (same object).
> This prevents inconsistency within a transaction (you
> cannot have two different Java objects representing the
> same database row in the same session). The stale data
> handling shows `em.refresh(entity)`: issues a SELECT,
> overwrites the entity's state with DB state. The bulk
> processing `flush`+`clear` pattern is critical for batch
> jobs: without `clear()`, the L1 cache grows to hold
> all 10,000 entities in memory. `flush()` writes pending
> changes to DB; `clear()` detaches all entities, freeing
> memory. This is the correct pattern for Hibernate batch
> processing.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> The L1 cache is both a feature and a trap. The identity
> guarantee is valuable for domain logic within a transaction.
> The trap: batch processing without `flush`+`clear`. I've
> seen OutOfMemoryError in batch jobs that process 100,000
> entities - the L1 cache grew to hold all of them.
>
> Another trap: long-running transactions in event
> consumers. A Kafka consumer that processes messages in
> a long transaction will have a growing L1 cache and
> stale data for entities loaded early in the transaction.
> Fix: either short transactions (one message = one
> transaction) or periodic `flush`+`clear`.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: What happens to the first-level cache when
you call session.flush() vs session.clear()?** [INTERNALS]

`flush()`: synchronizes the first-level cache state with
the database. Pending INSERTs, UPDATEs, and DELETEs are
sent to the database. The entities remain in the L1 cache
after flush (still PERSISTENT state, still tracked).

`clear()`: empties the first-level cache. All entities
become DETACHED. No more dirty checking. No more automatic
flushing.

`flush()` + `clear()` together (the batch pattern):
1. `flush()`: write all pending changes to DB (batch
   persisted up to this point)
2. `clear()`: evict all entities from L1 cache (free memory)
3. Next `session.get()`/`em.find()` will issue a SELECT
   (cache is empty)

Without `clear()` in batch processing: L1 cache grows to
hold all processed entities. Dirty checking at flush time
scans all cached entities (O(n) per flush). OOM for large
batches.

*What separates good from great:* Knowing that `flush()`
alone does not free memory - only `clear()` releases the
entity references. For batch jobs: always flush AND clear.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with identity guarantee and flush/clear semantics. |
| Hiring Manager | Lead with batch processing OOM prevention. |
| Bar Raiser | Lead with dirty checking scan cost at flush time and the impact of large L1 cache. |

---

---

# Second-Level Cache

**Interview Weight:** expert (★★★) - Second-level cache
is a senior/architect-level topic. Questions test: what
it caches, cache regions, eviction strategies, invalidation
on bulk operations, and provider options (Ehcache, Redis,
Caffeine).

---

### 🎯 Model Answer

**30 seconds:**

> The second-level cache (L2 cache) is shared across
> all sessions and transactions. It caches entity state
> by ID (not instances - raw field values). When `session.get(Order.class, 1L)` is called in a new session,
> Hibernate checks the L2 cache first. If found: entity
> is reconstructed from cached data (no SELECT). Annotations:
> `@Cache(usage = READ_WRITE)` on the entity. Providers:
> Ehcache (in-process), Redis (distributed, for clusters).
> Critical: bulk UPDATE/DELETE bypass the L2 cache.
> Always evict affected cache regions after bulk operations.

**3 minutes:**

> L1 vs L2 cache:
> - L1 (Session cache): per-session, identity map, always on
> - L2 (Second-level cache): cross-session, configurable,
>   stores raw field values (not instances)
>
> L2 cache stores: entity data as a flat map of field values.
> When an entity is loaded from L2 cache, Hibernate
> constructs a new Java instance using the cached values.
> Two sessions loading the same entity get different Java
> objects (different instances) but with the same field values.
>
> Concurrency strategies:
> - `READ_ONLY`: cache entries never change (static data).
>   Most performant.
> - `NONSTRICT_READ_WRITE`: cache is updated after transaction
>   commits. Brief inconsistency window. For rarely-changing data.
> - `READ_WRITE`: soft locks during update. Consistent but
>   slower than NONSTRICT.
> - `TRANSACTIONAL`: full transaction support (JTA required).
>   Most consistent, most overhead.
>
> What breaks L2 cache:
> - Bulk UPDATE/DELETE (JPQL mutation queries)
> - Native SQL updates
> - Direct database updates (outside Hibernate)
>
> After any of these: `sessionFactory.getCache().evictEntityData(Order.class)`

---

### 📘 Concept Explanation

**L2 cache workflow:**

```
  SESSION A (commits)        L2 CACHE (shared)
  GET Order#1                MISS: not in cache
  SELECT FROM orders         -> {id=1, total=100, status=PENDING}
  COMMIT                     STORE: Order#1 -> {total=100,...}

  SESSION B (new)
  GET Order#1                HIT: found in L2 cache
  NO SELECT                  RECONSTRUCT new Order instance
  Returns Order{total=100}   (different object than Session A's)

  BULK UPDATE (bypasses L2!)
  UPDATE orders SET status=COMPLETED WHERE id=1
  -> L2 CACHE: Order#1 still cached as {status=PENDING}
  -> STALE CACHE!

  EVICT required:
  sessionFactory.getCache()
    .evictEntityData(Order.class, 1L);
```

---

### 💻 Code Example

**L2 cache configuration and usage**

```java
// Entity: opt-in to L2 caching
@Entity
@Cache(usage = CacheConcurrencyStrategy.READ_WRITE,
       region = "orders")  // named cache region
public class Order {
    @Id @GeneratedValue private Long id;
    private BigDecimal total;
    private OrderStatus status;

    // Cache the collection separately
    @OneToMany(mappedBy = "order")
    @Cache(usage = CacheConcurrencyStrategy.READ_WRITE,
           region = "order-items")
    private List<OrderItem> items = new ArrayList<>();
}

// Read-only entities: most aggressive caching
@Entity
@Cache(usage = CacheConcurrencyStrategy.READ_ONLY,
       region = "countries")  // immutable reference data
public class Country {
    @Id private String code;
    private String name;
}
```

```yaml
# application.yml: L2 cache with Caffeine
spring:
  jpa:
    properties:
      hibernate:
        cache:
          use_second_level_cache: true
          use_query_cache: false  # usually off (complex)
          region:
            factory_class:
              org.hibernate.cache.jcache.internal
                .JCacheRegionFactory
        javax:
          cache:
            provider:
              com.github.benmanes.caffeine.jcache
                .spi.CaffeineCachingProvider
```

```java
// Evicting L2 cache after bulk operations
@Service
public class OrderBulkService {

    @Autowired
    private EntityManager em;

    @Autowired
    private EntityManagerFactory emf;

    @Transactional
    public int cancelOldOrders() {
        int updated = em.createQuery(
            "UPDATE Order SET status = :s " +
            "WHERE createdAt < :cutoff")
            .setParameter("s", OrderStatus.CANCELLED)
            .setParameter("cutoff", LocalDate.now()
                .minusDays(90))
            .executeUpdate();

        // CRITICAL: bulk UPDATE bypasses L2 cache
        // Evict affected entities to prevent stale reads
        emf.getCache().evict(Order.class);
        // Evicts all Order entries from L2 cache

        return updated;
    }
}
```

> **Code walkthrough:** `@Cache(usage = READ_WRITE)` opts
> the entity into the L2 cache with a concurrency strategy
> that uses soft locks to prevent dirty reads during updates.
> The `region` attribute is the cache key for provider
> configuration (size limits, TTL). `READ_ONLY` is appropriate
> for entities that never change (country codes, currency codes,
> product categories) - the most performant strategy because
> no locking or invalidation is needed. The bulk update eviction
> is critical: `executeUpdate()` issues a direct SQL UPDATE,
> bypassing Hibernate's entity management. The L2 cache holds
> stale data. `emf.getCache().evict(Order.class)` removes
> all Order entries from the L2 cache, forcing fresh loads.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**

> L2 cache is appropriate for: read-heavy entities that
> change rarely (product catalog, reference data), entities
> with expensive load operations (deep object graphs).
>
> L2 cache is NOT appropriate for: entities that change
> frequently (orders, payments), entities shared across
> many application nodes where consistency is critical
> (use Redis but be aware of network latency), entities
> subject to bulk operations (stale cache risk).
>
> In distributed deployments (multiple application nodes),
> an in-process L2 cache (Ehcache, Caffeine) is NOT shared.
> Node A caches Order#1 as PENDING. Node B updates Order#1
> to COMPLETED (invalidates Node B's cache). Node A still
> has PENDING. Fix: use a distributed cache (Redis via
> Redisson Hibernate Cache) for cross-node consistency,
> but accept the network latency trade-off.

---

### ⚖️ Comparison Table

| Strategy | Consistency | Performance | When |
|---|---|---|---|
| READ_ONLY | Perfect for static data | Highest | Immutable reference data |
| NONSTRICT_READ_WRITE | May have brief stale window | High | Rarely changing data |
| READ_WRITE | Consistent (soft locks) | Medium | General use |
| TRANSACTIONAL | Full tx consistency | Lower | Critical financial data |

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: When would you enable the Hibernate second-
level cache, and what are the risks?** [TRADE-OFF]

*Why they ask:* Tests knowledge of caching trade-offs in production.

Enable L2 cache for:
- High read-to-write ratios (10:1 or more)
- Entities that are expensive to load (deep object graphs)
- Reference data (lookup tables, country codes)

Risks:

1. Stale data: if an entity is modified outside Hibernate
   (direct SQL, another app), the L2 cache is not
   invalidated. Every cached entity may be stale.

2. Bulk operation bypass: `executeUpdate()` bypasses the
   L2 cache. Always evict after bulk mutations.

3. Distributed cache complexity: in-process caches per
   node are not consistent. Distributed caches (Redis)
   add latency and operational complexity.

4. Memory pressure: L2 caches are bounded. Monitor cache
   hit rate and eviction rate. Low hit rate = cache is
   not effective; high eviction rate = cache is too small.

When NOT to use L2 cache:
- Entities with frequent writes (orders, events, logs)
- Multi-writer environments where direct DB access is
  common (Hibernate does not see external writes)
- Entities requiring strict consistency (financial
  balances, inventory counts)

*What separates good from great:* Recommending cache
metrics monitoring (hit rate, miss rate, eviction rate)
as a prerequisite for declaring the cache effective.
A cache with 30% hit rate may add more overhead than
it saves.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with L2 cache config and bulk operation invalidation. |
| Hiring Manager | Lead with when to use L2 cache and operational risks. |
| Bar Raiser | Lead with distributed cache consistency problem and hit rate monitoring. |

---

---

# N+1 Problem Detection

**Interview Weight:** expert (★★★) - N+1 is the most
common Hibernate performance anti-pattern. Questions test:
how to detect it, how to fix it, and the trade-offs between
JOIN FETCH, @BatchSize, and @EntityGraph.

---

### 🎯 Model Answer

**30 seconds:**

> N+1: loading a list of N entities, then issuing 1 SELECT
> per entity for a lazy association = N+1 total queries.
> Detection: enable `show_sql=true` in dev and count the
> queries; use Hibernate Statistics; use `datasource-proxy`
> in tests to count queries. Fixes: `JOIN FETCH` (one query
> for all), `@BatchSize` (batch lazy loads into groups),
> `@EntityGraph` (Spring Data JPA). `JOIN FETCH` is the
> first choice; `@BatchSize` is good for collections with
> many associations.

**3 minutes:**

> N+1 is often invisible in tests (small data) but
> catastrophic in production (large data). Diagnostic
> tools:
>
> 1. `spring.jpa.show-sql=true` in dev: count SELECT
>    statements. If you see 50 SELECTs for a 50-item
>    list endpoint, you have N+1.
>
> 2. `Hibernate Statistics`: `hibernate.generate_statistics=true`.
>    Check `StatisticsService.getQueryExecutionCount()`.
>
> 3. `datasource-proxy` in tests: wraps the DataSource
>    to count queries. Assert query count in integration tests:
>    `assertThat(queryCount).isLessThan(5)`.
>
> Fix strategies:
> - `JOIN FETCH` in HQL: one query, all associations loaded.
>   Best for single associations.
> - `@BatchSize(size = 25)` on the association: lazy loads
>   are batched into groups of 25. 100 associations = 4
>   queries (100/25). Good for collections where JOIN FETCH
>   would cause a Cartesian product.
> - `@EntityGraph`: Spring Data JPA declarative JOIN FETCH.
>   Clean API for repository methods.
> - `default_batch_fetch_size` in config: applies @BatchSize
>   to all lazy associations globally.

---

### 📘 Concept Explanation

**N+1 visualized:**

```
  WITHOUT FIX:
  GET /orders?status=PENDING

  SELECT * FROM orders WHERE status = 'PENDING'
  -> [Order#1, Order#2, ..., Order#100]

  SELECT * FROM customers WHERE id = 1  (Order#1)
  SELECT * FROM customers WHERE id = 2  (Order#2)
  ...
  SELECT * FROM customers WHERE id = 100 (Order#100)

  Total: 101 SELECT statements

  WITH JOIN FETCH:
  SELECT o.*, c.* FROM orders o
  JOIN customers c ON c.id = o.customer_id
  WHERE o.status = 'PENDING'

  Total: 1 SELECT statement
```

---

### 💻 Code Example

**Wrong vs Right: detecting and fixing N+1**

```java
// BAD: triggers N+1
@Service
public class OrderService {
    @Transactional(readOnly = true)
    public List<OrderDto> getPendingOrders() {
        List<Order> orders = orderRepo.findByStatus(PENDING);
        // findByStatus: SELECT * FROM orders WHERE status=?
        return orders.stream()
            .map(o -> new OrderDto(
                o.getId(),
                o.getCustomer().getName(),  // N+1 HERE!
                o.getTotal()))
            .collect(toList());
    }
}
```

```java
// GOOD: Fix with @EntityGraph (Spring Data JPA)
public interface OrderRepository
    extends JpaRepository<Order, Long> {

    // Loads Order + Customer in one JOIN query
    @EntityGraph(attributePaths = {"customer"})
    List<Order> findByStatus(OrderStatus status);
}

// GOOD: Fix with JOIN FETCH in @Query
public interface OrderRepository
    extends JpaRepository<Order, Long> {
    @Query("SELECT o FROM Order o JOIN FETCH o.customer " +
           "WHERE o.status = :status")
    List<Order> findByStatusWithCustomer(
        @Param("status") OrderStatus status);
}
```

```java
// GOOD: @BatchSize for collection N+1
// (avoids Cartesian product from JOIN FETCH on collection)
@Entity
public class Order {
    @OneToMany(mappedBy = "order")
    @BatchSize(size = 25)  // load 25 items collections at once
    private List<OrderItem> items;
}
// For 100 orders with items:
// 1 SELECT for orders
// SELECT * FROM items WHERE order_id IN (1,2,...,25)  [4x]
// = 5 total queries instead of 101
```

```java
// DETECTION: query counting in integration tests
@SpringBootTest
class OrderServiceTest {

    @Autowired
    private DataSource dataSource;

    @Test
    void getPendingOrders_noNPlusOne() {
        // Use datasource-proxy or Hibernate stats
        SessionFactory sf = emf.unwrap(SessionFactory.class);
        sf.getStatistics().setStatisticsEnabled(true);
        sf.getStatistics().clear();

        orderService.getPendingOrders();

        long queryCount = sf.getStatistics()
            .getQueryExecutionCount();
        // With N+1 fix: should be 1 or 2, not 100+
        assertThat(queryCount)
            .as("Should not have N+1 queries")
            .isLessThan(5);
    }
}
```

> **Code walkthrough:** The BAD example has a classic
> N+1: `findByStatus` loads N orders, then `getCustomer()`
> on each order triggers N customer SELECTs inside the
> `map()`. The fix uses `@EntityGraph` which adds a
> `JOIN FETCH` to the `findByStatus` query. One SQL query
> loads all orders and their customers. The `@BatchSize(25)`
> fix is the right tool for collection N+1 where `JOIN FETCH`
> would cause a Cartesian product (100 orders x 10 items
> each = 1000-row result set). `@BatchSize` groups lazy
> loads: when any item collection is accessed, Hibernate
> fetches 25 collections in one `IN` query. The test
> demonstrates query count assertion - this should be in
> every service integration test to prevent N+1 regressions.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**

> N+1 is the most common Hibernate performance issue and
> the most preventable. My prevention strategy: query count
> assertions in every service integration test. A test
> that asserts "this endpoint issues fewer than 5 SQL
> queries" will catch any N+1 regression before it reaches
> production.
>
> The fix choice: `JOIN FETCH` for single associations
> (no Cartesian product risk). `@BatchSize` for collections
> (avoids Cartesian product: 100 orders x 10 items = 1000
> rows with JOIN FETCH). `spring.jpa.properties.hibernate.
> default_batch_fetch_size=25` as a global safety net
> (applies @BatchSize to all lazy associations without
> per-mapping annotations).

---

### ⚖️ Comparison Table

| Fix | Queries | Cartesian Risk | When |
|---|---|---|---|
| JOIN FETCH | 1 | Yes (for collections) | Single associations (@ManyToOne) |
| @BatchSize | N/batchSize + 1 | No | Collections, many associations |
| @EntityGraph | 1 | Yes (for collections) | Spring Data JPA convenience |
| default_batch_fetch_size | N/25 + 1 | No | Global safety net |

---

### 🎯 Interview Deep-Dive

**[STAFF] Q1: How would you add N+1 detection to a CI
pipeline to prevent regressions?** [PRODUCTION + DEBUGGING]

*Why they ask:* Tests whether candidate can operationalize
performance quality gates.

Three-layer defense:

**Layer 1: Integration test query counting**
```java
// QueryCounterExtension with datasource-proxy
@ExtendWith(QueryCounterExtension.class)
class OrderServiceTest {
    @Test
    @ExpectSelect(max = 3)  // custom annotation
    void listPendingOrders_maxThreeQueries() {
        orderService.getPendingOrders();
    }
}
```

**Layer 2: Hibernate statistics logging in staging**
Enable `generate_statistics=true` in staging environment.
Log `StatisticsService` metrics in a custom
`BeanFactoryPostProcessor` or Actuator endpoint.
Alert when `getEntityLoadCount()` exceeds expected
range for a request.

**Layer 3: APM (Application Performance Monitoring)**
In production: Datadog APM, New Relic, or Grafana Tempo
trace individual SQL queries per HTTP request. Alert when
query count per trace exceeds a threshold.

CI enforcement: `datasource-proxy` wraps the test DataSource.
Each test method that accesses the DB reports query count
to a listener. Fail the test if query count exceeds the
threshold. This is a 5-minute setup and prevents N+1
regressions from ever reaching production.

*What separates good from great:* Providing a concrete
implementation (datasource-proxy, custom annotation,
specific assertion) vs vague advice like "use monitoring."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with JOIN FETCH vs @BatchSize comparison. |
| Hiring Manager | Lead with CI detection strategy and prevention. |
| Bar Raiser | Lead with datasource-proxy test pattern and APM integration for production monitoring. |

---

---

# Query Cache

**Interview Weight:** working - Query cache is often
misunderstood: it caches result sets (IDs), not entities.
Questions target: when query cache helps vs hurts, the
timestamp cache mechanism, and why it is usually disabled.

---

### 🎯 Model Answer

**30 seconds:**

> The Hibernate query cache stores the result set of a
> named or cached query as a list of entity IDs. On subsequent
> calls, Hibernate returns the cached IDs and loads each
> entity from the L2 cache (or DB if not in L2 cache).
> The query cache is only useful when: the same query is
> executed frequently, query parameters are the same,
> and the result set changes rarely. The timestamp cache
> invalidates query cache entries when any entity in the
> query's tables is modified. High write rates to a table
> make the query cache ineffective (constant invalidation).

**3 minutes:**

> Query cache workflow:
>
> First execution: `SELECT * FROM orders WHERE status = 'PENDING'`
> - Query executed, result: [1L, 2L, 3L, ... 100L]
> - Query cache stores: `{query+params -> [1L, 2L, ..., 100L]}`
> - L2 cache: entities for all 100 IDs stored
>
> Second execution (same query + params):
> - Query cache hit: returns [1L, 2L, ..., 100L]
> - Load each entity from L2 cache (no DB SELECT for entities)
> - If any entity is NOT in L2 cache: individual SELECT
>
> Timestamp cache mechanism:
> - Each table has a "last modified" timestamp
> - When ANY row in `orders` is modified: timestamp updated
> - Query cache entry for any query on `orders` is invalidated
>
> Why query cache is usually disabled:
> - For tables with any write activity: queries are constantly
>   invalidated (no benefit, extra overhead)
> - Requires L2 cache to be effective (IDs alone are useless)
> - Only effective for truly static data (use `@Cache` on
>   the entity with `READ_ONLY` for static data instead)
> - Additional complexity without commensurate benefit
>   for most production workloads

---

### 💻 Code Example

**Query cache usage and when to avoid**

```java
// When query cache is useful:
// Read-only reference data queried with the same parameters

// Enable per-query:
@Repository
public class CountryRepository {
    @PersistenceContext
    private EntityManager em;

    public List<Country> findAllCountries() {
        return em.createQuery(
            "FROM Country ORDER BY name",
            Country.class)
            .setHint("org.hibernate.cacheable", true)
            .setHint("org.hibernate.cacheRegion",
                "countries-query")
            .getResultList();
        // Only useful because:
        // 1. Countries never change (READ_ONLY entity cache)
        // 2. Same query called frequently (all-countries list)
        // 3. No write activity on countries table
    }
}
```

```yaml
# application.yml: enable query cache (disabled by default)
spring:
  jpa:
    properties:
      hibernate:
        cache:
          use_second_level_cache: true
          use_query_cache: true  # disabled by default; enable only when needed
```

```java
// BAD: query cache on high-write tables (useless, adds overhead)
@Repository
public class OrderRepository {
    public List<Order> findPending() {
        return em.createQuery(
            "FROM Order WHERE status = 'PENDING'",
            Order.class)
            // BAD: orders are constantly modified
            // query cache is invalidated on every write
            // Cache overhead with no benefit
            .setHint("org.hibernate.cacheable", true)
            .getResultList();
    }
}
```

> **Code walkthrough:** The `findAllCountries` example
> is a valid use case for query cache: countries are loaded
> once (the `@Cache(READ_ONLY)` entity cache handles entity
> storage), and the same "all countries" query is called
> thousands of times. Query cache returns the cached ID
> list; entity cache provides the entities - zero DB queries
> after the first call. The `findPending` BAD example shows
> the anti-pattern: `orders` is a high-write table. Every
> INSERT, UPDATE, or DELETE on `orders` invalidates the
> query cache entry. The cache is constantly invalidated
> and immediately re-populated with the same data. Net
> result: higher overhead than without the cache.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> My default: query cache disabled. Enable it only for
> read-only reference data queried with the same parameters
> (country codes, currency list, product categories).
> For general entity queries: rely on the L2 entity cache
> (per-entity caching), not the query result cache.
>
> A better approach for frequently-queried static lists:
> Spring's `@Cacheable` at the service layer (Caffeine/Redis).
> Simpler: the service method result is cached by Spring,
> no Hibernate query cache configuration needed.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: What is the timestamp cache and how does
it affect query cache invalidation?** [INTERNALS]

Hibernate maintains a "timestamps cache" region with a
timestamp for each table. When any row in a table is
modified (INSERT, UPDATE, DELETE), the table's timestamp
is updated.

When a query cache entry is about to be returned,
Hibernate checks: is the query cache entry's timestamp
NEWER than the table's last-modified timestamp? If the
table was modified after the query was cached: cache entry
is invalid, re-execute the query.

This mechanism ensures query cache is consistent with
entity state. But it means: any write to the `orders`
table invalidates ALL query cache entries for queries on
`orders`, regardless of whether the changed row would
affect the cached query result.

Example: query `WHERE status = 'PENDING'` is cached.
A completed order is marked `COMPLETED` (not a pending
order). The timestamp for the `orders` table is updated.
The pending query cache entry is invalidated - even though
the changed row was not in the pending result set.

This coarse-grained invalidation is why query cache is
only effective for truly immutable data.

*What separates good from great:* Knowing the coarse-
grained nature of timestamp cache invalidation (table-level,
not row-level) explains why query cache is ineffective
for any table with write activity.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with query cache + entity cache interaction. |
| Hiring Manager | Lead with when query cache helps vs hurts. |
| Bar Raiser | Lead with timestamp cache mechanism and coarse invalidation. |
