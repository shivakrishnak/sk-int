# N+1 Select Anti-Pattern

**Interview Weight:** critical - N+1 is the most common
JPA performance problem in production. Every JPA
interview will have at least one N+1 question.

---

### 🎯 Model Answer

**30 seconds:**

> N+1 selects: 1 query fetches N entities, then N
> additional queries each fetch a related collection.
> 100 orders + loading each order's items = 1 + 100 =
> 101 queries. Fix: JOIN FETCH in JPQL (single query
> with JOIN), @EntityGraph (declarative JOIN FETCH),
> or batch fetching (Hibernate IN clause). Lazy loading
> is not the problem - triggering lazy loading in a loop
> is the problem.

**3 minutes (Senior):**

> N+1 pattern (most common cause):
>
> ```java
> List<Order> orders = orderRepo.findAll();
> // Query 1: SELECT * FROM orders (100 rows)
>
> orders.forEach(o -> {
>   o.getItems().size(); // N queries!
>   // Query 2..101: SELECT * FROM items
>   //               WHERE order_id = ?
> });
> ```
>
> N+1 doesn't require a loop. Any code that touches a
> lazy collection outside its loading context produces
> N+1.
>
> Fixes (each with trade-offs):
>
> 1. JOIN FETCH in @Query:
>    "SELECT DISTINCT o FROM Order o
>     JOIN FETCH o.items WHERE o.status = :s"
>    → Single query. Risk: Cartesian product with
>      multiple collections. Use DISTINCT.
>
> 2. @EntityGraph:
>    @EntityGraph(attributePaths = {"items"})
>    → Declarative JOIN FETCH on any repository method
>    → Cannot nest multiple @EntityGraph levels easily
>
> 3. Hibernate @BatchSize:
>    @BatchSize(size = 25) on the collection
>    → Items loaded in batches:
>      SELECT * FROM items WHERE order_id IN (?,?,...,?)
>    → N/25 queries instead of N queries
>    → Still multiple queries but manageable
>
> 4. @Fetch(FetchMode.SUBSELECT):
>    SELECT * FROM items
>    WHERE order_id IN (SELECT id FROM orders WHERE ...)
>    → 2 queries regardless of N
>
> 5. DTOs with @Query:
>    NEW constructor in JPQL selects only needed fields
>    → No entity loaded, no lazy loading possible

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the N+1 select
problem in JPA - too many database queries caused by
lazy loading in loops."

**(2) First principles:** "Each database query has
overhead (network round-trip, query planning). N+1
accumulates that overhead N+1 times instead of once."

**(3) Bridge:** "N+1 is like grocery shopping: instead
of going to the store once with a list (1 query for
all items), you make a separate trip for each item
on the list (N queries). JOIN FETCH is the shopping
list pattern."

---

### 💻 Code Example

```java
// BAD: Classic N+1 - don't do this
@Transactional
public List<OrderDto> getAllOrdersNPlus1() {
    List<Order> orders = orderRepo.findAll();
    // Query 1: SELECT * FROM orders LIMIT 100

    return orders.stream().map(o -> {
        // BAD: triggers lazy load inside loop
        int itemCount = o.getItems().size();
        // Query 2, 3, 4... for each order!
        return new OrderDto(o.getId(), itemCount);
    }).collect(toList());
}

// GOOD: Fix with @EntityGraph
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    @EntityGraph(attributePaths = {"items"})
    List<Order> findAll();
    // SELECT o.*, i.* FROM orders o
    // LEFT JOIN items i ON i.order_id = o.id
    // 1 query - no N+1
}

// GOOD: Fix with @Query JOIN FETCH
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    @Query("SELECT DISTINCT o FROM Order o "
        + "JOIN FETCH o.items "
        + "WHERE o.status = :status")
    List<Order> findByStatusWithItems(
        @Param("status") String status);
}

// GOOD: @BatchSize for collection (config-time)
@Entity
public class Order {
    @OneToMany(mappedBy = "order",
               fetch = FetchType.LAZY)
    @BatchSize(size = 25)
    private List<Item> items;
}
// 100 orders → 4 batches of 25 = 4 queries (not 100)

// Diagnose N+1 with statistics
@Bean
public DataSource dataSource() {
    return new ProxyDataSourceBuilder()
        .dataSource(originalDataSource)
        .name("DS-Proxy")
        .logQueryToSysOut()  // logs all queries
        .countQuery()        // counts per request
        .build();
}
// Or: spring.jpa.show-sql=true + count queries
```

> **Code walkthrough:** The BAD case loads 100 orders
> then triggers a separate SELECT for each order's items.
> The @EntityGraph fix adds a LEFT JOIN on items in the
> single findAll() query. JOIN FETCH with DISTINCT prevents
> Cartesian product duplicates (without DISTINCT, a
> 5-item order generates 5 rows). @BatchSize doesn't
> eliminate the problem but reduces it (100 queries to 4).
> Diagnosis: count SQL queries per request; if count
> approaches entity count, it's N+1.

---

### ⚖️ Comparison Table

| Fix | Queries | Entities loaded | Cartesian risk | Use case |
|---|---|---|---|---|
| JOIN FETCH + DISTINCT | 1 | Yes | Yes (multiple collections) | Single collection fetch |
| @EntityGraph | 1 | Yes | Yes | Declarative JOIN FETCH |
| @BatchSize(n) | N/n | Yes | No | Many collections, less config |
| @Fetch(SUBSELECT) | 2 | Yes | No | All same collection fetched |
| DTO @Query | 1 | No (DTO) | No | Read-only, best performance |

---

### 🎓 Answers by Seniority

**Junior:** "N+1 is when loading N entities triggers
N more queries for related data. Fix: JOIN FETCH to
load in one query."

**Senior:** "N+1 fixes have trade-offs: JOIN FETCH
with multiple collections causes Cartesian product
(use separate @EntityGraph calls or @BatchSize). I
profile with Hibernate statistics or p6spy to count
queries per use case before and after fix. DTO
projections are the best fix for read-only use cases:
no entity, no lazy loading, no N+1 possible."

**Staff:** "N+1 is architectural, not just a query
annotation. Fix at the right level: entity-returning
methods use JOIN FETCH; read-only use cases use DTO
projections. Measure with production load, not just
unit test. Hibernate statistics report in staging
should show max queries per request. If any endpoint
shows query count proportional to result count, it
has N+1."

---

### 🚨 Failure Modes and Diagnosis

**Failure: Endpoint takes 3+ seconds under load**

Symptom: /orders/active is fast with 1 user, slow in
production with 100 active orders.

Root cause: N+1 - 100 orders × 1 items query per order
= 101 queries × 10ms each = 1 second minimum.

Diagnosis:
```
spring.jpa.properties.hibernate.generate_statistics=true
# Or p6spy proxy datasource
```
Log shows: 101 SELECT statements for one request.

Fix: @EntityGraph(attributePaths={"items"}) on the
findAll method.

Post-fix verification: 101 queries → 1 query.
Endpoint: 3s → 30ms.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Cause, fixes, Cartesian product trap |
| Staff | 12 min | Architectural fix strategy, measurement, DTO projection |

---

**[SENIOR] Q1 - Why can JOIN FETCH produce duplicate
results and how do you fix it?**

*Why they ask:* JOIN FETCH is the fix, but the Cartesian
product trap is the next level.

When an Order has 5 Items, a JOIN produces 5 rows
(Cartesian product):

```sql
SELECT o.*, i.* FROM orders o
JOIN items i ON i.order_id = o.id
WHERE o.id = 1
-- Result: 5 rows, all with o.id=1, different i.id
```

JPA receives 5 rows, creates 5 Order objects from
the same order row → List<Order> has 5 duplicate Order
references.

Fix: DISTINCT in JPQL:
```java
@Query("SELECT DISTINCT o FROM Order o "
    + "JOIN FETCH o.items")
```
JPQL DISTINCT doesn't add SQL DISTINCT (which would
prevent fetching all columns). It deduplicates in
memory by JPA.

Hibernate 6 handles this differently (uses DISTINCT
at the memory level by default for collection fetches).

Second problem: multiple JOIN FETCH collections:
```java
// INVALID - MultipleBagFetchException
@Query("SELECT DISTINCT o FROM Order o "
    + "JOIN FETCH o.items "
    + "JOIN FETCH o.discounts")
```
Two unindexed collections (List) = Hibernate throws
MultipleBagFetchException. Fix: use Set<> for one
collection, or use @BatchSize for the second collection.

*What separates good from great:* JPQL DISTINCT works
in-memory not SQL; MultipleBagFetchException with List
+ multiple JOIN FETCH.

**[STAFF] Q2 - How do you detect N+1 in production
before it impacts users?**

*Why they ask:* Proactive performance engineering.

1. **Staging: Hibernate statistics**
   Enable and assert in integration tests:
   ```java
   Statistics stats =
       sessionFactory.getStatistics();
   stats.setStatisticsEnabled(true);
   // After request:
   assertThat(stats.getPrepareStatementCount())
       .isLessThanOrEqualTo(5);
   ```

2. **Staging: Datasource proxy**
   p6spy or datasource-proxy count SQL per request.
   Assert max queries in performance tests.

3. **Production: slow query log**
   Database slow query log shows repeated identical
   queries with different ID parameters.
   Pattern: same query structure, 50+ executions
   per second = N+1 indicator.

4. **APM: query count per transaction**
   Datadog, New Relic, etc. trace query count per
   HTTP request. Alert when queries > threshold.

5. **Code review: repository findAll() + getXxx()
   in loops** are red flags for N+1. Block in PR.

*What separates good from great:* Automated assertions
on query count in integration tests as the earliest
detection point.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | N+1 cause, JOIN FETCH, DISTINCT trap. |
| Hiring Manager | N+1 = production outage risk. Every JPA app has it. |
| Bar Raiser | Cartesian product, MultipleBagFetchException, detection strategy, DTO projection. |
| Peer Engineer | "I assert query count in every service integration test. Caught 3 N+1s before they hit production this quarter." |

---

---

# Open Session in View Anti-Pattern

**Interview Weight:** critical - OSIV is enabled by
default in Spring Boot and is a production scalability
risk. Senior candidates must know what it is, why it's
dangerous, and how to disable it.

---

### 🎯 Model Answer

**30 seconds:**

> Open Session in View (OSIV) keeps the JPA persistence
> context (session) open for the entire HTTP request
> lifecycle - including serialization (view rendering).
> It's enabled by default in Spring Boot. Danger:
> the database connection is held open during view
> rendering and lazy loading in the view layer. At
> high load, connection pool exhaustion occurs.
> Fix: spring.jpa.open-in-view=false and load all
> data in the service layer within @Transactional.

**3 minutes (Senior):**

> OSIV in Spring Boot:
>
> Enabled by default:
>   spring.jpa.open-in-view=true (default)
>
> What it does:
>   - OpenEntityManagerInViewInterceptor runs
>   - Opens EntityManager at HTTP request start
>   - EntityManager stays open until response sent
>   - Lazy collections load successfully during view
>     rendering (no LazyInitializationException)
>
> Why it's dangerous:
>   1. DB connection held for entire request duration
>      including time in controller, serialization,
>      and view rendering
>   2. Long response times = many connections held
>   3. Connection pool (20 connections) exhausted at
>      20 concurrent slow requests
>   4. Database connection time includes JSON/Thymeleaf
>      rendering time
>
> Why developers enable it:
>   Lazy collections load in the view layer without
>   LazyInitializationException. It's "convenient"
>   but hides the real problem (not pre-loading needed
>   data in service).
>
> Fix:
>   spring.jpa.open-in-view=false
>   → LazyInitializationException in view = good!
>     It reveals where data should be loaded.
>   → Load all needed data in the service layer
>     within @Transactional scope

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Open Session in
View - the JPA pattern that keeps the database session
open beyond the transaction boundary."

**(2) First principles:** "A database connection is
a shared, limited resource. Holding it open during view
rendering (which doesn't need the DB) wastes it."

**(3) Bridge:** "OSIV is like holding a taxi (DB
connection) while you're in a restaurant (rendering
HTML). The taxi waits doing nothing. Other passengers
(requests) can't get a taxi. The fix: use the taxi
to arrive (fetch data in service), then let it go.
Take a new taxi when you need it next."

---

### 💻 Code Example

```java
// BAD: OSIV enabled (default) - works but is dangerous
// application.properties: spring.jpa.open-in-view=true

@RestController
public class OrderController {

    @GetMapping("/orders/{id}")
    public OrderResponse getOrder(@PathVariable Long id) {
        Order order = orderService.findById(id);
        // Service method is @Transactional
        // But EntityManager stays open!

        // This works (lazy loading in controller):
        int count = order.getItems().size();
        // BUT: DB connection held during entire
        // controller execution, serialization, etc.
    }
}

// GOOD: OSIV disabled
// application.properties: spring.jpa.open-in-view=false

@Service
public class OrderService {

    @Transactional(readOnly = true)
    public OrderDetailDto getOrderDetail(Long id) {
        Order order = orderRepo.findById(id)
            .orElseThrow(NotFoundException::new);

        // Load EVERYTHING in @Transactional scope:
        List<Item> items = order.getItems();
        items.size();  // force load in transaction
        // DB connection released after @Transactional ends

        return new OrderDetailDto(
            order.getId(),
            order.getStatus(),
            items.stream()
                .map(ItemDto::from)
                .collect(toList())
        );
        // Controller gets a complete DTO
        // No DB connection held during rendering
    }
}

// Or use JOIN FETCH - cleaner
@Transactional(readOnly = true)
public OrderDetailDto getOrderDetail(Long id) {
    return orderRepo.findByIdWithItems(id)
        .map(OrderDetailDto::from)
        .orElseThrow(NotFoundException::new);
    // JOIN FETCH loads items in one query
    // DTO is fully built while in transaction
}
```

> **Code walkthrough:** With OSIV enabled, lazy
> loading in the controller works but holds the DB
> connection the entire time. With OSIV disabled,
> LazyInitializationException forces all data loading
> into the @Transactional service method. The controller
> receives a DTO with all data pre-populated. DB
> connection is released immediately after the service
> method returns.

---

### ⚖️ Comparison Table

| | OSIV enabled | OSIV disabled |
|---|---|---|
| Spring Boot default | Yes | No |
| Lazy loading in controller | Works | LazyInitializationException |
| DB connection held | Full request duration | @Transactional scope only |
| Connection pool risk | High under load | Low |
| Forces good design | No | Yes (error = load in service) |
| Production recommendation | No | Yes |

---

### 🎓 Answers by Seniority

**Junior:** "OSIV keeps the JPA session open for the
whole HTTP request. Spring Boot enables it by default.
It causes database connection issues under load."

**Senior:** "I always set spring.jpa.open-in-view=false.
The LazyInitializationExceptions it reveals show where
data should be loaded in the service layer. OSIV is
convenient during development but is a connection pool
bomb in production."

**Staff:** "OSIV is a team discipline issue. Developers
rely on it to avoid LazyInitializationException without
thinking about connection consumption. The architectural
rule: service layer returns fully populated DTOs or
entities with needed associations loaded. Controllers
and views get DTOs, not entities. Zero lazy loading
outside transaction scope."

---

### 🚨 Failure Modes and Diagnosis

**Failure: Connection pool exhaustion under load**

Symptom: "Unable to acquire JDBC Connection" errors
under sustained load. Works fine with 1-5 users.

Root cause: OSIV holds DB connection for entire HTTP
request. 20 connection pool + 20 slow requests (300ms
response) = all connections busy, 21st request fails.

Diagnosis:
1. Check: spring.jpa.open-in-view (true = problem)
2. Measure connection hold duration vs query duration
3. Compare: connection pool utilization vs request rate

Fix:
1. spring.jpa.open-in-view=false
2. Fix resulting LazyInitializationExceptions in service
3. Load all needed data in @Transactional scope
4. Return DTOs from service

Result: DB connection released immediately after service
method returns. View rendering (typically 50-200ms)
no longer holds connection.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | OSIV mechanics, connection pool risk, disable + fix |
| Staff | 10 min | Architectural impact, DTO pattern, connection math |

---

**[STAFF] Q1 - How do you migrate a codebase from
OSIV-enabled to OSIV-disabled without breaking every
endpoint?**

*Why they ask:* Large-scale architectural migration.

Migration strategy:

1. **Enable OSIV=false in staging first.** Run full
   integration test suite. Every LazyInitializationException
   reveals a missing load point.

2. **Categorize failures:** list all failing endpoints.
   Group by: lazy collection in controller, lazy
   association in serialization (Jackson calls getters).

3. **Fix patterns:**
   - Simple case: add JOIN FETCH to the repository query
   - Multiple collections: use @BatchSize or separate queries
   - Controller accessing lazy data: move logic to service,
     return DTO
   - Serializer accessing lazy data: add @JsonIgnore or
     use DTO (not entity) for serialization

4. **Don't fix globally:** don't add EAGER to all
   relationships. EAGER is permanent and affects all
   queries. Fix per use case.

5. **Roll out by service module:** fix one module at a
   time in production (feature flag per module).

6. **Verify connection hold time:** use p6spy or APM
   to confirm connections are released before response
   sending.

*What separates good from great:* "Never change fetch
type to EAGER as a fix. That's trading one production
risk for another."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | OSIV mechanics, LazyInitializationException, open-in-view config. |
| Hiring Manager | OSIV = connection pool risk. Disable it. |
| Bar Raiser | Connection math, migration strategy, DTO pattern, EAGER as anti-fix. |
| Peer Engineer | "We disabled OSIV on every microservice. Took 2 sprints but connection pool issues disappeared." |

---

---

# Persistence Context Size Management

**Interview Weight:** critical - Large persistence
contexts (thousands of entities) degrade performance.
Interviewers test batch processing patterns and the
importance of em.clear().

---

### 🎯 Model Answer

**30 seconds:**

> JPA persistence context holds all loaded and modified
> entities in memory. It grows without bound until the
> transaction ends. For batch processing (10,000+ entities):
> flush + clear periodically (every 50-100 rows) to
> release memory. Large persistence contexts slow
> dirty checking (Hibernate scans all managed entities
> on flush). Not clearing = OutOfMemoryError for large
> batches. Pattern: flush + clear + count in batches.

**3 minutes (Senior):**

> Persistence context bloat in batch processing:
>
> Each em.persist() / em.find() adds entity to PC.
> Flush: Hibernate iterates ALL managed entities to
> detect dirty changes. O(n) per flush where n = PC size.
>
> 10,000 entities in PC + flush at the end:
> - Memory: ~100MB depending on entity size
> - Dirty check: 10,000 entity comparisons per flush
> - GC pressure: large heap objects
>
> Fix: flush + clear periodically:
>   if (i % 100 == 99) {
>     em.flush();   // write pending SQL
>     em.clear();   // detach all entities, free memory
>   }
>
> After em.clear():
> - All entities detached (unmanaged)
> - Dirty checking only runs for re-loaded entities
> - Memory freed for GC
>
> Spring Batch + JPA:
>   JpaPagingItemReader: reads in pages, clears PC
>   between pages automatically
>   JpaItemWriter: writes in chunks, flushes chunk,
>   handles PC automatically
>
> Stateless session (Hibernate-specific):
>   StatelessSession: no persistence context, no
>   dirty checking, no caching. Direct DB operations.
>   For bulk processing where entity lifecycle tracking
>   is not needed.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about persistence context
size in JPA - managing memory in batch operations."

**(2) First principles:** "The persistence context is
a working memory area. Like a work desk: it accumulates
papers (entities) until cleared. A full desk slows
work and eventually runs out of space."

**(3) Bridge:** "JPA batch processing without clear()
is like cooking for 1,000 people without clearing
the kitchen between dishes. You run out of counter
space (memory). Clear the kitchen every 100 dishes."

---

### 💻 Code Example

```java
// BAD: Batch insert without flush+clear
@Transactional
public void importOrders(List<OrderData> data) {
    for (int i = 0; i < data.size(); i++) {
        Order order = new Order(data.get(i));
        em.persist(order);
        // PC grows with every persist
        // If data.size() = 100,000:
        // - 100,000 Order objects in memory
        // - Dirty check on all at commit
        // - Likely OutOfMemoryError
    }
}

// GOOD: Flush + clear every N records
@Transactional
public void importOrders(List<OrderData> data) {
    int batchSize = 50;

    for (int i = 0; i < data.size(); i++) {
        Order order = new Order(data.get(i));
        em.persist(order);

        if ((i + 1) % batchSize == 0) {
            em.flush();  // SQL INSERT batch sent to DB
            em.clear();  // detach all, free memory
            // PC now empty, ready for next batch
        }
    }
    // Final flush for remaining records
    em.flush();
    em.clear();
}

// GOOD: Spring Batch handles PC automatically
@Bean
public JpaPagingItemReader<OrderData> reader() {
    return new JpaPagingItemReaderBuilder<OrderData>()
        .name("orderReader")
        .entityManagerFactory(emf)
        .queryString("FROM OrderData o")
        .pageSize(50)
        // After each page: em.clear() called automatically
        .build();
}

// GOOD: Stateless session (Hibernate direct)
StatelessSession session =
    sessionFactory.openStatelessSession();
Transaction tx = session.beginTransaction();
for (OrderData data : dataList) {
    session.insert(new Order(data));
    // No PC, no dirty checking, maximum throughput
}
tx.commit();
session.close();
```

> **Code walkthrough:** BAD: grows the PC indefinitely.
> 100K entities = memory exhaustion and slow dirty
> checking. GOOD: flush + clear every 50 records.
> em.flush() sends pending INSERTs to DB as a batch.
> em.clear() detaches all entities and resets the PC.
> Memory stays bounded regardless of dataset size.
> Spring Batch JpaPagingItemReader handles this
> automatically. StatelessSession bypasses the PC
> entirely for maximum bulk insert throughput.

---

### 🎓 Answers by Seniority

**Junior:** "The persistence context grows when you
persist or load entities. For batch processing, flush
and clear periodically to avoid memory issues."

**Senior:** "For bulk operations: flush every 50-100
entities and clear to free memory. Spring Batch
JpaPagingItemReader handles this automatically. For
very high throughput bulk inserts: Hibernate StatelessSession
bypasses the PC entirely."

---

### 🚨 Failure Modes and Diagnosis

**Failure: OutOfMemoryError in batch job**

Symptom: Batch import job crashes with OutOfMemoryError
at high record counts.

Root cause: PC accumulates thousands of entities without
clear(). Each entity + dirty checking overhead.

Diagnosis: Check batch job for em.persist() in loop
without em.flush() + em.clear(). Heap dump: large
number of entity objects.

Fix: Add flush+clear every 50-100 records. Or use
Spring Batch JpaPagingItemReader.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Flush+clear pattern, OutOfMemoryError, Spring Batch |
| Staff | 8 min | Dirty checking O(n), StatelessSession, throughput math |

---

**[SENIOR] Q1 - Why does Hibernate dirty checking
get slower as the persistence context grows?**

*Why they ask:* Understanding of why flush+clear matters.

Dirty checking at flush: Hibernate compares every
managed entity's current state with the snapshot taken
at load time. For each entity: compare field by field.

Complexity: O(n * f) where n = entities in PC,
f = fields per entity.

10 entities × 20 fields = 200 comparisons per flush.
10,000 entities × 20 fields = 200,000 comparisons.
50,000 entities: 1,000,000 comparisons per flush.

The flush at transaction commit (which scans everything)
gets proportionally slower with PC size.

Additionally: dirty checking holds entity snapshots
in memory (two copies: current + snapshot). Memory
doubles.

Fix: flush + clear to reset the comparison set to
size 0 after each batch. Each flush only compares
the current batch.

*What separates good from great:* The snapshot + O(n)
dirty check cost, not just "PC uses memory."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | flush+clear pattern, PC lifecycle. |
| Hiring Manager | PC management = batch job stability. |
| Bar Raiser | Dirty checking O(n), snapshot memory, StatelessSession trade-off. |
| Peer Engineer | "Our import job went from 20 minutes to 2 minutes after adding flush+clear every 100 records." |

---

---

# JPA Performance Tuning Strategies

**Interview Weight:** critical - Performance tuning
is a Staff/Senior level topic. Interviewers look for
a systematic approach: measure, identify, fix, verify.

---

### 🎯 Model Answer

**30 seconds:**

> JPA performance tuning priorities (in order):
> 1. Detect N+1 (Hibernate stats, query count per request)
> 2. Fix N+1 with JOIN FETCH or DTO projections
> 3. Check slow individual queries (missing indexes,
>    Cartesian products)
> 4. Second-level cache for frequently-read static data
> 5. Read-only transactions (readOnly=true)
> 6. Batch operations for bulk writes
> Never tune before measuring.

**3 minutes (Senior):**

> Systematic JPA performance tuning:
>
> Step 1: Measure (always first)
>   hibernate.generate_statistics=true
>   Statistics per request:
>   - getQueryExecutionCount(): total queries
>   - getEntityLoadCount(): entities loaded
>   - getCollectionFetchCount(): lazy collections loaded
>   p6spy or datasource-proxy for query logging
>
> Step 2: Identify hot paths
>   High query count per request → N+1
>   Single slow query → missing index or Cartesian
>   High entity count per query → over-fetching
>
> Step 3: Fix (in order of impact)
>   a. N+1: JOIN FETCH, @EntityGraph, @BatchSize
>   b. Over-fetching: DTO projections
>   c. Slow queries: native query with index hint,
>      or DB-specific optimization
>   d. Hot reference data: L2 cache (Ehcache/Caffeine)
>   e. Bulk writes: JDBC batch insert (spring.jpa.properties
>      .hibernate.jdbc.batch_size=50)
>   f. readOnly transactions: skip dirty checking on
>      flush for read-only paths
>
> Step 4: Verify (after each change)
>   Measure again. Regression-test. Don't optimize
>   what's already fast.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about a systematic
approach to JPA performance optimization."

**(2) First principles:** "Performance tuning without
measurement is guessing. Measure first, tune highest
impact, measure again."

**(3) Bridge:** "JPA performance tuning is like
debugging: you need diagnostics before solutions.
Hibernate statistics is the debugger for query behavior."

---

### 💻 Code Example

```java
// Enable Hibernate statistics
// application.properties:
// spring.jpa.properties.hibernate.generate_statistics
//   = true
// logging.level.org.hibernate.stat=DEBUG

// Programmatic statistics check in tests
@Autowired
private EntityManagerFactory emf;

@Test
public void noNPlus1ForOrderList() {
    SessionFactory sf =
        emf.unwrap(SessionFactory.class);
    Statistics stats = sf.getStatistics();
    stats.setStatisticsEnabled(true);
    stats.clear();

    orderService.findAllActive();

    long queryCount =
        stats.getPrepareStatementCount();
    // Assert: not more than 2 queries
    // (1 for orders, 1 for items via JOIN or batch)
    assertThat(queryCount).isLessThanOrEqualTo(2);
}

// JDBC batch inserts
// application.properties:
// spring.jpa.properties.hibernate.jdbc.batch_size=50
// spring.jpa.properties.hibernate.order_inserts=true
// spring.jpa.properties.hibernate.order_updates=true

// readOnly=true skips dirty checking at flush
@Transactional(readOnly = true)
public List<OrderSummary> findAllSummaries() {
    return orderRepo.findAllProjectedBy();
    // FlushMode.MANUAL - no flush needed
    // No dirty check overhead
    // DB hints: read-only cursor where supported
}

// Second-level cache for reference data
@Entity
@Cache(
    usage = CacheConcurrencyStrategy.READ_ONLY)
@Cacheable
public class Country {
    // READ_ONLY: never changes, safe to cache
    // Cached by Ehcache/Caffeine/Infinispan
    // em.find(Country, "US") → L2 cache hit
}
```

> **Code walkthrough:** Statistics assertion in tests
> is the earliest N+1 detection point. Asserting
> queryCount <= 2 fails if N+1 appears. JDBC batch
> inserts require batch_size + order_inserts (Hibernate
> groups same-type INSERTs together for JDBC batch).
> readOnly=true sets FlushMode.MANUAL, eliminating
> dirty checking overhead on read paths. @Cache with
> READ_ONLY caches country/category reference data
> permanently (until JVM restart).

---

### 🎓 Answers by Seniority

**Junior:** "Enable Hibernate statistics to see query
counts. Fix N+1 with JOIN FETCH. Use readOnly=true
for read-only transactions."

**Senior:** "JPA performance in order: (1) fix N+1
first (usually the biggest win), (2) use DTO projections
for read APIs, (3) JDBC batch for bulk writes, (4) L2
cache for reference data. Assert query count per request
in integration tests to catch regressions."

**Staff:** "Performance budget per request: define
maximum query count (e.g., 5 for list endpoints, 3
for detail endpoints). Enforce with Statistics assertions
in integration tests. CI fails on regression. L2 cache
only for genuinely stable data (write-rarely entities).
Cache invalidation in distributed systems is complex -
prefer read replicas over L2 cache for read scaling."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Measurement tools, N+1 fix, readOnly, JDBC batch |
| Staff | 12 min | Budget enforcement, L2 cache risks, distributed cache |

---

**[STAFF] Q1 - What are the risks of using Hibernate
second-level cache in a distributed system?**

*Why they ask:* Cache invalidation is a classic hard
problem.

L2 cache in a distributed system (multiple JVM instances):

1. **Cache coherence problem:**
   Instance A updates Country entity.
   Instance B has the old Country in its L2 cache.
   Requests to Instance B get stale data.

2. **Solutions:**
   a. READ_ONLY cache: only for entities that truly
      never change in production. Zero staleness risk.
   b. TRANSACTIONAL cache (with distributed lock):
      Cache provider (Infinispan) handles invalidation.
      Complex, adds latency, still has edge cases.
   c. READ_WRITE with region invalidation:
      Update invalidates across all nodes. Network
      overhead per write.
   d. Distributed cache (Redis): all JVMs share one
      cache. No coherence problem. Network call per
      hit (vs in-memory L2). Different trade-off.

3. **Recommendation:**
   Use L2 cache only for READ_ONLY reference data.
   For anything that changes: use a read replica, not
   L2 cache. Read replicas are simpler and reliable.

*What separates good from great:* "READ_ONLY L2 cache
is safe. READ_WRITE L2 cache in distributed systems
is complex and dangerous. Prefer read replicas."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Statistics, JDBC batch, readOnly. |
| Hiring Manager | Performance tuning = systematic, not random. |
| Bar Raiser | Budget enforcement, L2 cache coherence, read replica. |
| Peer Engineer | "JDBC batch_size=50 + order_inserts took our bulk import from 20s to 2s with zero code changes." |

---

---

# JPA Security Native Queries and Data Exposure

**Interview Weight:** critical - Security in JPA is
a required topic for senior-level interviews. SQL
injection via native queries and unintended data exposure
through entities are the primary risks.

---

### 🎯 Model Answer

**30 seconds:**

> JPA SQL injection risk: native @Query with string
> concatenation instead of bind parameters. Fix: always
> use @Param named parameters (:name), never string
> concatenation in JPQL or native queries. Data exposure:
> serializing JPA entities directly to JSON exposes
> all fields (including sensitive ones). Fix: use DTO
> projections with explicit field selection. Mass
> assignment: @RequestBody binding to entity directly
> allows callers to set any field. Fix: use separate
> Request DTOs.

**3 minutes (Senior):**

> JPA security threat catalog:
>
> 1. SQL Injection via native queries:
>    "SELECT * FROM orders WHERE status = '"
>    + status + "'" ← VULNERABLE
>    Fix: bind parameter (always)
>
> 2. JPQL Injection (rare but possible):
>    JPQL is parameterized, but dynamic query building
>    via string concatenation is vulnerable to JPQL
>    injection (different from SQL injection - targets
>    entity graph, not SQL directly).
>    Fix: never concatenate into JPQL; use parameters.
>
> 3. Mass assignment via entity @RequestBody:
>    POST /orders with {"id":1,"status":"PAID","total":0}
>    If Order is bound directly from @RequestBody,
>    caller controls ALL entity fields.
>    Fix: use OrderCreateRequest DTO, map to entity.
>
> 4. Over-exposure via entity serialization:
>    Returning entities directly exposes all fields
>    including internal fields, audit fields, and
>    potentially sensitive data.
>    Fix: DTO projections, @JsonIgnore for sensitive
>    fields, or Jackson @JsonView.
>
> 5. IDOR (Insecure Direct Object Reference):
>    GET /orders/{id} without checking ownership.
>    Caller passes any ID and gets any order.
>    Fix: check order.getCustomerId() == currentUser.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about security
vulnerabilities specific to JPA - SQL injection,
data exposure, and mass assignment."

**(2) First principles:** "JPA abstracts SQL but doesn't
eliminate SQL injection when you bypass the abstraction.
Entity exposure is a data leakage risk."

**(3) Bridge:** "JPA security is 'trust nothing from
the caller.' Parameters come in through bind parameters
(never concatenated). Data goes out through explicit
DTOs (never full entities)."

---

### 💻 Code Example

```java
// BAD: SQL injection vulnerability
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    // VULNERABLE - SQL injection
    @Query(value =
        "SELECT * FROM orders "
        + "WHERE status = '" + "#{#status}" + "'",
        nativeQuery = true)
    List<Order> findByStatusUnsafe(
        @Param("status") String status);
    // Caller sends: PAID' OR '1'='1
    // Returns ALL orders!

    // ALSO VULNERABLE - dynamic JPQL concatenation
    default List<Order> findDynamic(String col) {
        return em.createQuery(
            "FROM Order ORDER BY " + col)
            .getResultList();
        // col = "1; DROP TABLE orders --"
    }
}

// GOOD: Parameterized queries (always)
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    @Query(value =
        "SELECT * FROM orders WHERE status = :status",
        nativeQuery = true)
    List<Order> findByStatus(
        @Param("status") String status);
    // Bind parameter → not injectable
    // :status → ? in PreparedStatement
}

// BAD: Mass assignment - entity as request body
@PostMapping("/orders")
public Order createOrder(@RequestBody Order order) {
    // Caller sets order.id, order.total, order.status
    return orderRepo.save(order);
    // Any field can be set by caller!
}

// GOOD: Request DTO with explicit field mapping
@PostMapping("/orders")
public OrderDto createOrder(
        @Valid @RequestBody CreateOrderRequest req) {

    Order order = new Order();
    order.setCustomerId(getCurrentUserId());
    order.setItems(req.getItems());
    order.setTotal(calculateTotal(req.getItems()));
    order.setStatus("PENDING");
    // Caller cannot set id, status, or total
    return OrderDto.from(orderRepo.save(order));
}

// BAD: IDOR - missing ownership check
@GetMapping("/orders/{id}")
public Order getOrder(@PathVariable Long id) {
    return orderRepo.findById(id)
        .orElseThrow(NotFoundException::new);
    // Any user can see any order!
}

// GOOD: IDOR prevention
@GetMapping("/orders/{id}")
public OrderDto getOrder(
        @PathVariable Long id,
        Authentication auth) {

    Order order = orderRepo
        .findByIdAndCustomerId(
            id, getCurrentUserId(auth))
        .orElseThrow(NotFoundException::new);
    // findByIdAndCustomerId:
    // WHERE id=? AND customer_id=?
    // Different customer → no result → 404
    return OrderDto.from(order);
}
```

> **Code walkthrough:** The SQL injection BAD case:
> string concatenation in native query. PAID' OR '1'='1
> returns all rows. Fix: :status bind parameter →
> PreparedStatement with ? → not injectable. Mass
> assignment BAD: RequestBody to Order entity lets
> callers set total=0. Fix: CreateOrderRequest DTO
> controls which fields are set. IDOR fix: add
> customerId to the WHERE clause - unauthorized access
> returns 404 (same as not found, no information
> disclosure).

---

### 🎓 Answers by Seniority

**Junior:** "Use bind parameters in native queries,
not string concatenation. Never bind @RequestBody
to a JPA entity. Use DTOs."

**Senior:** "Four JPA security rules: (1) native
queries use :param (never concatenate), (2) request
bodies bind to DTOs not entities, (3) responses
return DTOs not entities, (4) ownership check in
WHERE clause for every user-owned resource query."

**Staff:** "Security review of a JPA codebase: search
for nativeQuery=true with string concatenation (injection
risk), search for @RequestBody mapping to @Entity
(mass assignment), check all findById() calls for
ownership enforcement (IDOR). These three searches
catch 90% of JPA security issues."

---

### 🚨 Failure Modes and Diagnosis

**Failure: SQL injection in native query**

Symptom: Attacker submits: status=' OR '1'='1&
order returns all orders of all users.

Root cause: String concatenation in native query.

Diagnosis: Search for nativeQuery=true + string
concatenation. OWASP ZAP scan for SQL injection.

Fix: Replace with :param named parameter. Never
concatenate user input into any query.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | SQL injection, mass assignment, IDOR |
| Staff | 10 min | Full JPA security review, threat catalog |

---

**[SENIOR] Q1 - How do you prevent SQL injection in
a native query that must build a dynamic WHERE clause?**

*Why they ask:* The harder case: dynamic queries
that can't use static :param.

Scenario: search endpoint where user can filter by
any combination of status, date range, and customer.

Options:

1. **JPA Criteria API (safe by design):**
   Criteria API builds the query programmatically.
   All predicates use cb.equal(field, :param) -
   parameterized by construction. No injection possible.

   ```java
   CriteriaBuilder cb = em.getCriteriaBuilder();
   CriteriaQuery<Order> q =
       cb.createQuery(Order.class);
   Root<Order> order = q.from(Order.class);

   List<Predicate> predicates = new ArrayList<>();
   if (status != null) {
       predicates.add(
           cb.equal(order.get("status"), status));
   }
   // Each predicate is automatically parameterized
   ```

2. **JPA Specifications (Spring Data):**
   Spring Data JPA Specification builds WHERE predicates.
   Same safety as Criteria API.

3. **QueryDSL:**
   Generates type-safe query predicates from entity
   metamodel. No string concatenation, compile-time
   safety.

4. **Whitelist approach for dynamic order-by:**
   If column name must be dynamic (ORDER BY clause
   cannot use bind parameter), whitelist valid
   column names:
   ```java
   Set<String> ALLOWED =
       Set.of("total", "createdAt", "status");
   if (!ALLOWED.contains(sortCol)) {
       throw new InvalidParameterException();
   }
   ```

*What separates good from great:* Criteria API/QueryDSL
as the injection-safe dynamic query solution.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Bind parameters, :param vs concatenation. |
| Hiring Manager | JPA doesn't prevent SQL injection if you bypass it. |
| Bar Raiser | Dynamic WHERE safety (Criteria API), IDOR pattern, mass assignment, full threat catalog. |
| Peer Engineer | "I add Criteria API to any endpoint with more than 2 optional filters. No more dynamic string building." |
