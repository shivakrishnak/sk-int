---
layout: default
title: "JPA - L2 Fetch Strategies"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 4
permalink: /jpa/l2-fetch-strategies/
render_with_liquid: false
---

# JPA - L2 Fetch Strategies

## Lazy vs Eager Loading: FetchType and LazyInitializationException

### 🎯 Model Answer

**30 seconds:**
> `FetchType.LAZY` (default for collections): related entities loaded on first access.
> `FetchType.EAGER` (default for `@ManyToOne`, `@OneToOne`): loaded with the parent immediately.
> Problem with EAGER: always loads, even when not needed (N+1 or JOIN overhead). Problem with LAZY:
> `LazyInitializationException` when accessed outside a transaction. Fix: use LAZY everywhere,
> load eagerly per-query with `JOIN FETCH` when the data is actually needed.

**3 minutes (Senior):**
> Fetch strategy design:
>
> 1. **EAGER is a global setting**: `@ManyToOne(fetch = FetchType.EAGER)` means EVERY query that
>    loads the parent entity also loads the related entity, regardless of whether it's needed.
>    If `User.address` is EAGER: `userRepository.findAll()` joins `addresses` for every user, every
>    time. If address is rarely needed: wasted JOIN on every query.
>
> 2. **LAZY is per-query**: with LAZY, loading the parent doesn't touch the related entity. Only
>    when you call `user.getOrders()` does Hibernate execute `SELECT * FROM orders WHERE user_id = ?`.
>    Within a transaction: fine. After transaction ends: persistence context closed, proxy can't
>    load -> `LazyInitializationException`.
>
> 3. **Open-Session-In-View (OSIV)**: Spring Boot enables OSIV by default for web applications.
>    OSIV: keeps the persistence context open for the entire HTTP request lifecycle (including the
>    view rendering). Lazy collections: can be accessed in the view (template/serializer).
>    Cost: keeps a DB connection open for the full request duration. Disable OSIV in production:
>    `spring.jpa.open-in-view=false`.
>
> 4. **Best practice**: all associations: LAZY. Load eagerly per query with `JOIN FETCH` when
>    the association is needed. OSIV disabled. Services return DTOs (not entities) to the web layer.

**Blank Mind Recovery:**

**(1) Restate:** "EAGER: always loads (even if not needed). LAZY: loads on access (within transaction). LazyInitializationException: accessed outside transaction. Fix: LAZY everywhere + JOIN FETCH per query. Disable OSIV."

**(2) First principles:** "Fetching is I/O. I/O should be done when needed, not speculatively. EAGER is speculative I/O (load even if never used). LAZY is on-demand I/O. Load what you need, when you need it."

**(3) Bridge:** "EAGER is like loading all emails in your inbox when you open the app - even emails from 2015 you'll never read. LAZY is like loading only the inbox list; emails loaded on click. Better for performance but requires the connection to still be open when you click."

---

### 📘 Concept Explanation

**FetchType behavior and OSIV:**
```
DEFAULT FETCH TYPES:

  @ManyToOne:   EAGER by default (JPA spec default)
  @OneToOne:    EAGER by default
  @OneToMany:   LAZY by default
  @ManyToMany:  LAZY by default
  
  Recommendation: override ALL to LAZY explicitly:
  @ManyToOne(fetch = FetchType.LAZY)  // override EAGER default
  @OneToOne(fetch = FetchType.LAZY)   // override EAGER default
  @OneToMany: already LAZY (default is fine)

EAGER LOADING PROBLEMS:

  @Entity
  public class Order {
      @ManyToOne(fetch = FetchType.EAGER)  // BAD default override
      private Customer customer;
      
      @ManyToOne(fetch = FetchType.EAGER)  // BAD
      private ShippingAddress address;
      
      @ManyToOne(fetch = FetchType.EAGER)  // BAD
      private PaymentMethod paymentMethod;
  }
  
  Query: List<Order> orders = orderRepository.findAll();
  Generated SQL:
    SELECT o.*, c.*, a.*, p.*
    FROM orders o
    INNER JOIN customers c ON c.id = o.customer_id
    INNER JOIN addresses a ON a.id = o.address_id
    INNER JOIN payment_methods p ON p.id = o.payment_method_id
  
  Even if you only need order IDs: all JOINs execute.
  "Hibernate will always produce a cross product when fetching eager associations."
  More EAGER associations on the entity: more JOINs on every query.
  Compounding effect: each eager association's eager associations are also loaded.

LAZY LOADING AND LAZYINITIALIZATIONEXCEPTION:

  @Entity
  public class Order {
      @OneToMany(mappedBy = "order", fetch = FetchType.LAZY)
      private List<OrderItem> items;  // loaded only when accessed
  }
  
  @Service
  public class OrderService {
      // Transaction ends when method returns.
      @Transactional(readOnly = true)
      public Order findOrder(Long id) {
          return orderRepository.findById(id).orElseThrow();
          // Order is returned. Transaction committed. EM closed.
          // order.items: Hibernate proxy, uninitialized.
      }
  }
  
  // Controller:
  Order order = orderService.findOrder(orderId);
  order.getItems().size();  // LAZYINITIALIZATIONEXCEPTION!
  // Hibernate proxy: tries to load items but no active session.
  
  Fix 1: JOIN FETCH in the query:
  @Query("SELECT o FROM Order o LEFT JOIN FETCH o.items WHERE o.id = :id")
  Optional<Order> findByIdWithItems(@Param("id") Long id);
  
  Fix 2: return a DTO (not the entity):
  @Transactional(readOnly = true)
  public OrderDto findOrder(Long id) {
      Order o = orderRepository.findByIdWithItems(id).orElseThrow();
      return new OrderDto(o.getId(), o.getStatus(),
          o.getItems().stream().map(ItemDto::new).toList());
      // DTO assembled within transaction. No proxy access after transaction.
  }

OPEN-SESSION-IN-VIEW (OSIV):

  Spring Boot default: spring.jpa.open-in-view=true
  
  OSIV: binds an EntityManager to the HTTP request thread for the full duration.
  Lifecycle: HTTP request starts -> EM opened -> service method -> transaction -> commit
             -> view/serializer phase -> lazy collections accessed (no exception!) -> HTTP response
  
  Benefit: lazy collections can be accessed in Jackson serializer or Thymeleaf templates.
           No LazyInitializationException in the web layer.
  
  Cost: a DB connection is held from request start to response sent.
        Connection held even during JSON serialization (no DB work happening).
        Under load: connections exhausted while serialization is slow.
  
  Recommendation: disable OSIV:
    spring.jpa.open-in-view=false
  
  Then: any LazyInitializationException becomes visible (not hidden by OSIV).
  Fix them properly (JOIN FETCH or DTO projection) instead of masking with OSIV.
  
  OSIV warning in Spring Boot startup log (default):
    "spring.jpa.open-in-view is enabled by default. Therefore, database queries may be
    performed during view rendering. Explicitly configure spring.jpa.open-in-view to
    disable this warning."
```

---

### 💻 Code Example

> **Code walkthrough:** The DTO approach is the correct fix for `LazyInitializationException`.
> It assembles all needed data within the transaction and returns a plain Java object.

```java
// BAD: Entity returned from service (lazy access in web layer):

@Transactional(readOnly = true)
public Order findOrder(Long id) {
    return orderRepository.findById(id).orElseThrow();
    // Transaction ends. Lazy collections: inaccessible.
}

// Controller/Jackson: order.getItems() -> LazyInitializationException.
// If OSIV is enabled: exception masked. Connection held. Hidden problem.

// GOOD: DTO approach (assembles data within transaction):

@Transactional(readOnly = true)
public OrderResponseDto findOrder(Long id) {
    Order order = orderRepository.findByIdWithItems(id).orElseThrow();
    // items loaded via JOIN FETCH - no lazy access needed.
    
    return OrderResponseDto.builder()
        .id(order.getId())
        .status(order.getStatus())
        .totalAmount(order.getTotalAmount())
        .items(order.getItems().stream()
            .map(item -> ItemDto.builder()
                .productName(item.getProductName())
                .quantity(item.getQuantity())
                .unitPrice(item.getUnitPrice())
                .build())
            .toList())
        .build();
    // All data assembled. DTO has no Hibernate proxies.
    // Controller receives DTO. No transaction needed. No lazy risk.
}

// REPOSITORY:
@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    @Query("SELECT o FROM Order o LEFT JOIN FETCH o.items WHERE o.id = :id")
    Optional<Order> findByIdWithItems(@Param("id") Long id);
}
```

> **Code walkthrough:** The DTO approach assembles all data within the `@Transactional` method.
> The `findByIdWithItems` query uses `LEFT JOIN FETCH` to load items in the same SQL statement,
> avoiding lazy loading entirely. The returned `OrderResponseDto` is a plain Java object with no
> Hibernate state - it can be serialized by Jackson or returned from REST endpoints without any
> transaction or session context.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Use `FetchType.LAZY` for all associations. Use `JOIN FETCH` in queries when you need the
> associated data. `LazyInitializationException`: accessed lazy collection outside transaction.
> Fix: add `JOIN FETCH` to the query or move the access inside `@Transactional`. Disable OSIV
> (`spring.jpa.open-in-view=false`) to catch these early.

---

**Senior / Staff (5+ years):**
> OSIV is an anti-pattern for high-traffic APIs: it holds DB connections during serialization.
> Disable it. Return DTOs from service methods: eliminates lazy access in the web layer, makes
> the service API explicit (callers know exactly what data they get). Hibernate `@BatchSize` as
> an alternative to JOIN FETCH for collections: instead of N queries, loads in batches of N.
> Compatible with pagination (unlike JOIN FETCH). Use when the Cartesian product of JOIN FETCH
> would be too large.

---

### ⚠️ Common Misconceptions

**Misconception: "`FetchType.EAGER` prevents `LazyInitializationException`."**
EAGER does prevent the exception (the data is loaded immediately). But it introduces a worse problem:
loading data that is never needed on every query. An entity with 5 EAGER associations: every `findById`
joins 5 tables. If only the entity itself is needed: 5 unnecessary JOINs. If any of the 5 associations
also have EAGER associations: more JOINs. This "EAGER cascade" causes the "monster SELECT" problem:
one `findById` generates a SELECT joining 15 tables. The correct fix for `LazyInitializationException`
is NOT to switch to EAGER. It is: (1) use JOIN FETCH to load the needed association in the specific
query, or (2) return a DTO assembled within the transaction.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `LazyInitializationException` in production but not in local tests.**
```
Symptom: exception in production, works in local development.

Root cause: OSIV enabled locally, disabled in production.
  Local: spring.jpa.open-in-view=true (Spring Boot default).
         Lazy collections accessible in view layer (no exception).
  Production: spring.jpa.open-in-view=false (configured by platform team).
              Lazy access outside transaction -> exception.

Diagnosis:
  spring.jpa.open-in-view: check value in both environments.
  Stack trace: LazyInitializationException shows which collection and where.
  
Fix:
  1. Disable OSIV in local dev too (match production):
     spring.jpa.open-in-view=false in application.properties
  2. Catch all LazyInitializationException in local dev immediately.
  3. Fix: JOIN FETCH or DTO projection in the service method.
  
Prevention:
  Never rely on OSIV. OSIV was introduced as a convenience but is a well-known anti-pattern.
  Service layer should return DTOs or fully-loaded entities (JOIN FETCH).
  Controller should never access entity lazy collections.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| LAZY vs EAGER | 2 minutes |
| LazyInitializationException | 2 minutes |
| OSIV pattern and risk | 2 minutes |
| JOIN FETCH fix | 1 minute |
| DTO approach | 1 minute |
| EAGER cascade problem | 1 minute |
| @BatchSize alternative | 1 minute |

---

**Q1 (osiv): What is Open-Session-In-View and why is it an anti-pattern?**

A: OSIV: Spring's mechanism for keeping an EntityManager (Hibernate Session) open for the entire
HTTP request lifecycle, not just within `@Transactional` method boundaries. Benefit: lazy collections
can be accessed in Jackson serializers, Thymeleaf templates, and REST controllers without
`LazyInitializationException`. Why anti-pattern: (1) A DB connection is held from request arrival
to response sent. During Jackson serialization (CPU work, no DB needed): the connection is held idle.
Under high load: connection pool exhausted while connections are held during non-DB work. (2) Lazy
access in the view layer: implicit queries triggered by serialization, invisible without SQL logging.
Hard to find N+1 queries that only manifest during serialization. (3) Masks problems: `LazyInitializationException`
is a useful signal (tells you the service/query design is wrong). OSIV silences it. Disable OSIV:
`spring.jpa.open-in-view=false`. Fix lazy access properly.

*What separates good from great:* The connection pool starvation pattern: OSIV + slow HTTP clients.
A client making a slow request (mobile on 3G, downloading a large JSON response): the OSIV-held
connection is occupied for the full download duration (maybe 5 seconds). With a pool of 20 connections:
20 simultaneous slow clients = all connections occupied. New requests: wait for a connection.
Perceived behavior: application performance degrades for ALL clients when a few slow clients are
active. This is a real production incident pattern. The fix: OSIV disabled, DTOs, and connections
released immediately after the service method returns (well before the HTTP response is fully sent).

---

---

## N+1 Problem: Detection, Diagnosis, and Fix

### 🎯 Model Answer

**30 seconds:**
> N+1: loading N parent entities then executing N additional queries to load related data for each
> parent. Example: load 100 orders (1 query) then load items for each order (100 queries) = 101
> queries. Fix: `JOIN FETCH` (1 query) or `@BatchSize` (M queries, where M = N/batch_size).
> Detect with: `spring.jpa.show-sql=true` or Hibernate statistics.

**3 minutes (Senior):**
> N+1 is the most common JPA performance problem:
>
> 1. **Cause**: lazy collections accessed in a loop. `orders.forEach(o -> o.getItems().size())`
>    where `items` is lazy: 1 query per order = N queries after the initial 1. Total = N+1.
>
> 2. **Detection in development**: `spring.jpa.show-sql=true`: all SQL in the log. Pattern: the
>    same `SELECT ... WHERE order_id = ?` repeated N times is N+1. Alternatively: Hibernate statistics
>    (`hibernate.generate_statistics=true`) shows query count per request.
>
> 3. **Fix with JOIN FETCH**: `SELECT o FROM Order o LEFT JOIN FETCH o.items`. One SQL with a JOIN.
>    All items loaded. No N+1. Caveat: cannot paginate with JOIN FETCH (in-memory pagination issue).
>
> 4. **Fix with @BatchSize**: `@BatchSize(size=50)` on the collection. On first lazy access: loads
>    items for up to 50 orders at once. Remaining lazy loads: batched similarly. Total queries =
>    ceil(N/50). Compatible with pagination. Good alternative to JOIN FETCH.
>
> 5. **Fix with DTO projection**: load a flat result with GROUP BY or a subquery count. No entity
>    with lazy collections loaded. No N+1 possible.

**Blank Mind Recovery:**

**(1) Restate:** "N+1: 1 query for parents + N queries for children = N+1 total. Fix: JOIN FETCH (1 query) or @BatchSize (N/batch queries). Detect: show-sql or Hibernate stats. DTO projection: eliminates entity loading entirely."

**(2) First principles:** "Every DB query is a network roundtrip. N queries = N roundtrips. At 1ms per roundtrip: 100 queries = 100ms of DB roundtrip overhead (before actual query time). JOIN FETCH: 1 roundtrip. 99ms saved."

**(3) Bridge:** "N+1 is like visiting a library. 1 trip to get a list of book titles (1 query). Then 100 trips to get the author info for each book (100 queries). Better: get titles AND authors in one trip (JOIN FETCH). Or: get authors in batches of 10 (@BatchSize)."

---

### 📘 Concept Explanation

**N+1 patterns and fixes:**
```
N+1 MANIFESTATIONS:

  1. OneToMany collection in loop:
  
     List<Author> authors = authorRepository.findAll();  // 1 query
     for (Author a : authors) {
         System.out.println(a.getBooks().size());  // 1 query per author
     }
     // Total: 1 + N queries.
  
  2. ManyToOne in loop (loaded lazily - if overridden):
  
     List<Book> books = bookRepository.findAll();  // 1 query, author_id loaded
     for (Book b : books) {
         System.out.println(b.getAuthor().getName()); // 1 query per book (if lazy)
     }
     // @ManyToOne default is EAGER; if changed to LAZY: N+1 for each author.
  
  3. Repository call in loop (explicit N+1):
  
     List<Long> orderIds = getOrderIds();  // some list
     for (Long id : orderIds) {
         Order o = orderRepository.findById(id).orElseThrow();  // N queries!
         processOrder(o);
     }
     // Fix: orderRepository.findAllById(orderIds)  // 1 query: IN clause

FIXES:

  FIX 1: JOIN FETCH (best for non-paginated queries):
  
    @Query("SELECT a FROM Author a LEFT JOIN FETCH a.books WHERE a.active = true")
    List<Author> findActiveWithBooks();
    // 1 SQL: SELECT a.*, b.* FROM authors a LEFT JOIN books b ON b.author_id = a.id
    // All data in one roundtrip.
    // DISTINCT may be needed: author with 3 books -> 3 rows in result (same author).
    @Query("SELECT DISTINCT a FROM Author a LEFT JOIN FETCH a.books WHERE a.active = true")
    List<Author> findActiveWithBooks();
  
  FIX 2: @BatchSize (compatible with pagination):
  
    @Entity
    public class Author {
        @OneToMany(mappedBy = "author", fetch = FetchType.LAZY)
        @BatchSize(size = 50)  // Hibernate: loads books for up to 50 authors at once
        private List<Book> books;
    }
    
    List<Author> authors = authorRepository.findAll(pageable).getContent();  // 1 query
    for (Author a : authors) {
        a.getBooks().size();  // Hibernate loads books for all 50 authors in this batch
    }
    // Total: 1 + ceil(N/50) queries. For N=100: 3 queries instead of 101.
    
    // Global BatchSize (application.properties):
    spring.jpa.properties.hibernate.default_batch_fetch_size=50
    // Applies to ALL lazy collections (no per-entity annotation needed).
    
  FIX 3: DTO PROJECTION (no entity loaded at all):
  
    @Query("SELECT new com.example.AuthorSummary(a.id, a.name, COUNT(b)) " +
           "FROM Author a LEFT JOIN a.books b GROUP BY a.id, a.name")
    List<AuthorSummary> findAllSummaries();
    // 1 SQL with COUNT. No entity loading. No lazy risk.
    // Result: just the aggregate count, not individual books.
    // Use when only count/aggregate is needed, not full book data.
  
  FIX 4: findAllById (for explicit N+1 in loops):
  
    // BAD: N queries in a loop:
    for (Long id : ids) {
        Order order = orderRepository.findById(id).orElseThrow();
    }
    
    // GOOD: 1 query with IN clause:
    List<Order> orders = orderRepository.findAllById(ids);
    // SQL: SELECT * FROM orders WHERE id IN (?, ?, ?, ...)

DETECTING N+1 IN PRODUCTION:

  Hibernate statistics (add to application.properties):
    spring.jpa.properties.hibernate.generate_statistics=true
    logging.level.org.hibernate.stat=DEBUG
  
  Log output per request:
    Session Metrics {
        6728 nanoseconds spent acquiring 1 JDBC connections;
        ...
        101 flushes as part of work in 1 dirty checking queries;
        ...
        101 queries executed to database;  // <-- N+1 visible here
    }
  
  DataSource proxy (p6spy): logs all SQL with query count.
  New Relic / Datadog: query count per transaction (alert on > 20 queries/request).
```

---

### 💻 Code Example

> **Code walkthrough:** The comparison shows the SQL count difference between the N+1 version and
> the JOIN FETCH fix.

```java
// N+1 DEMONSTRATION AND FIX:

// BAD: N+1 via lazy collection access:
@Transactional(readOnly = true)
public List<AuthorWithBookCount> getAuthorReports() {
    List<Author> authors = authorRepository.findAll();  // Query 1
    
    return authors.stream().map(author -> {
        int count = author.getBooks().size();  // Query N (per author!)
        return new AuthorWithBookCount(author.getName(), count);
    }).toList();
    
    // For 100 authors: 101 queries. For 1000: 1001.
}

// GOOD: DTO projection (1 query, no entities loaded):
@Transactional(readOnly = true)
public List<AuthorWithBookCount> getAuthorReports() {
    return authorRepository.findAuthorBookCounts();
    // 1 SQL: SELECT a.name, COUNT(b.id) FROM authors a LEFT JOIN books b ON b.author_id = a.id
    //        GROUP BY a.id, a.name
}

@Repository
public interface AuthorRepository extends JpaRepository<Author, Long> {
    
    // JOIN FETCH for full book data:
    @Query("SELECT DISTINCT a FROM Author a LEFT JOIN FETCH a.books " +
           "WHERE a.active = true")
    List<Author> findActiveWithBooks();
    
    // DTO projection for count only:
    @Query("SELECT new com.example.AuthorWithBookCount(a.name, COUNT(b)) " +
           "FROM Author a LEFT JOIN a.books b GROUP BY a.id, a.name")
    List<AuthorWithBookCount> findAuthorBookCounts();
}

// DIAGNOSE N+1 AT STARTUP (integration test):
@SpringBootTest
class N1DetectionTest {
    @Autowired AuthorService service;
    @PersistenceContext EntityManager em;
    
    @Test
    void authorReports_shouldNotHaveN1() {
        // Enable statistics:
        SessionFactory sf = em.getEntityManagerFactory()
            .unwrap(SessionFactory.class);
        sf.getStatistics().setStatisticsEnabled(true);
        sf.getStatistics().clear();
        
        service.getAuthorReports();
        
        long queryCount = sf.getStatistics().getQueryExecutionCount();
        assertThat(queryCount)
            .as("Expected 1 query but got N+1 (%d queries)", queryCount)
            .isLessThanOrEqualTo(3);  // 1 + a few batch loads is acceptable
    }
}
```

> **Code walkthrough:** The `getAuthorReports` N+1 version accesses `author.getBooks()` inside a
> stream, triggering a lazy load per author. The DTO projection version executes one SQL with
> `COUNT` and `GROUP BY`, avoiding entity loading entirely. The `N1DetectionTest` uses Hibernate
> statistics to fail a test if query count exceeds the threshold - this is a pattern for catching
> N+1 regressions in CI.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> N+1: 1 query + N per-child queries. Fix: JOIN FETCH. Detect: enable `show-sql`. Pattern:
> repeated SELECT with changing parameter = N+1. `@BatchSize(size=50)` global setting reduces
> N+1 to N/50 queries automatically.

---

**Senior / Staff (5+ years):**
> `spring.jpa.properties.hibernate.default_batch_fetch_size=25` is a near-zero-effort global fix
> that reduces most N+1 to ceil(N/25) without JOIN FETCH rewrites. For critical paths: use DTO
> projections (no entity loading). Add Hibernate statistics assertions in integration tests for
> critical service methods. N+1 is always a design issue: the caller expects the association to be
> loaded; the service doesn't declare what it loads. DTOs make the contract explicit.

---

### ⚠️ Common Misconceptions

**Misconception: "JOIN FETCH always fixes N+1."**
JOIN FETCH fixes N+1 for loading a collection, but cannot be used with pagination. Using
`findAll(Pageable)` with a `JOIN FETCH` query: Hibernate applies pagination in memory (not in SQL).
For a million rows: Hibernate loads all rows into memory, then takes the page. OOM risk. The correct
fix for paginated collections: `@BatchSize` or two queries (ID pagination first, then JOIN FETCH for
the IDs). Also: JOIN FETCH with multiple collections creates a Cartesian product (multiplicative row
count). `@BatchSize` avoids this for both pagination and multiple collections.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Application performs well with 10 users but fails at 1,000 users.**
```
Symptom: at 1,000 users in the DB: endpoint takes 45 seconds.
  At 10 users: < 100ms.
  DB query log: 1,001 queries per request.

Root cause: N+1. The query count is linear with N (user count).
  At 10 users: 11 queries * 5ms = 55ms (acceptable).
  At 1,000 users: 1,001 queries * 5ms = 5 seconds (unacceptable).
  At 10,000 users: 10,001 queries * 5ms = 50 seconds (timeout).
  
  N+1 degrades linearly with data size. The problem hides in small datasets.

Diagnosis:
  Enable hibernate.generate_statistics=true.
  Request to the endpoint: check query count. If count ~ user count: N+1.
  Identify the collection: look for repeated SELECT with changing id in the SQL log.

Fix:
  Option 1: default_batch_fetch_size=50 (global, low effort):
    spring.jpa.properties.hibernate.default_batch_fetch_size=50
    Queries: ceil(1000/50) = 20 queries (vs 1001). Still O(N) but much lower constant.
    
  Option 2: JOIN FETCH (1 query):
    @Query("SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.orders")
    List<User> findAllWithOrders();
    For paginated: use two-query pattern.
    
  Option 3: DTO projection (no lazy loading possible):
    @Query("SELECT new com.example.UserSummary(u.id, u.name, COUNT(o)) " +
           "FROM User u LEFT JOIN u.orders o GROUP BY u.id, u.name")
    List<UserSummary> findAllSummaries();
    1 query regardless of user count.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| N+1 definition | 1 minute |
| N+1 manifestation in code | 2 minutes |
| JOIN FETCH fix | 2 minutes |
| @BatchSize fix | 2 minutes |
| DTO projection fix | 1 minute |
| Detection methods | 1 minute |
| JOIN FETCH + pagination issue | 1 minute |

---

**Q1 (n1): Describe the N+1 problem and your preferred fix strategy.**

A: N+1: loading N parent entities with one query, then executing N additional queries to load
related associations for each parent. Cause: lazy collection access in a loop. Example: loading
100 users, then accessing `user.getOrders()` for each: 101 total queries. Fix strategy: (1) If
data is always needed and not paginated: `JOIN FETCH` in JPQL (1 query). (2) If paginated or if
JOIN FETCH creates a Cartesian product (multiple collections): `@BatchSize` or
`default_batch_fetch_size` (reduces N+1 to N/batch queries, compatible with pagination). (3) If
only aggregate data is needed: DTO projection with `COUNT` and `GROUP BY` (1 query, no entities).
My default: set `spring.jpa.properties.hibernate.default_batch_fetch_size=25` globally (catches
most N+1 automatically), then apply JOIN FETCH or DTO projections to high-traffic endpoints.

*What separates good from great:* The N+1 variants beyond the classic: (1) Repository N+1: calling
`findById(id)` in a loop instead of `findAllById(ids)`. Fix: batch find. (2) JSON serialization N+1:
Jackson serializes an entity's lazy collection (if OSIV is enabled): triggers N queries during HTTP
response writing. Not visible in service-layer SQL logs (happens in the framework layer). Fix: OSIV
disabled + DTO. (3) Spring AOP N+1: `@Cacheable` on a method that loads entities with lazy
collections; cache stores the proxy state. On cache hit: entity returned from cache but session
closed. First access to lazy collection: exception. Fix: cache DTOs, not entities.

