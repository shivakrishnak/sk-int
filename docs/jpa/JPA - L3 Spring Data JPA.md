---
layout: default
title: "JPA - L3 Spring Data JPA"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 5
permalink: /jpa/l3-spring-data-jpa/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Repository Interface Hierarchy](#repository-interface-hierarchy) | medium |
| 2 | [Query Derivation Method Naming](#query-derivation-method-naming) | medium |
| 3 | [@Query and Custom JPQL](#query-and-custom-jpql) | medium |
| 4 | [Pagination and Sorting](#pagination-and-sorting) | medium |
| 5 | [Spring Data JPA Projections](#spring-data-jpa-projections) | critical |

---

# Repository Interface Hierarchy

**Interview Weight:** medium - Spring Data JPA repository
hierarchy is tested to verify understanding of the
abstraction layers and the right interface to extend.

---

### 🎯 Model Answer

**30 seconds:**

> Spring Data JPA's repository hierarchy: Repository
> (marker, no methods), CrudRepository (basic CRUD),
> PagingAndSortingRepository (adds pagination/sorting),
> JpaRepository (JPA-specific: flush, batch operations,
> @Query support). Extend JpaRepository for full Spring
> Data JPA features. Extend CrudRepository for minimal
> API surface. The right choice depends on which methods
> you need to expose.

**3 minutes (Senior):**

> Repository interface hierarchy:
>
> Repository<T, ID>: empty marker interface. No methods.
> Use to expose only custom @Query methods with nothing
> else (minimal API surface).
>
> CrudRepository<T, ID>: save(), findById(), findAll(),
> delete(), count(), existsById(). All basic CRUD.
>
> PagingAndSortingRepository<T, ID>: adds findAll(Sort)
> and findAll(Pageable).
>
> JpaRepository<T, ID>: extends Paging+Sorting + adds:
> - saveAll(Iterable): batch save
> - getById(ID): returns proxy (lazy reference)
> - flush(): explicit persistence context flush
> - saveAndFlush(): save + flush immediately
> - deleteAllInBatch(): bulk DELETE without loading entities
> - getReferenceById(ID): replaces deprecated getById
>
> Custom repository interfaces: create your own interface
> extending Repository with only the methods you want.
> This limits the API surface (callers can only call
> what you expose).
>
> Spring Data Commons vs Spring Data JPA:
> Repository, CrudRepository, PagingAndSortingRepository
> are in Spring Data Commons (used by Redis, MongoDB
> too). JpaRepository is JPA-specific.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the Spring Data
JPA repository interface hierarchy."

**(2) First principles:** "Repository is a data access
object. The hierarchy layers on more capabilities.
Each layer is a trade-off: more methods = more power,
less control over API surface."

**(3) Bridge:** "The hierarchy is like kitchen tools:
a knife (Repository), a chef's knife (CrudRepository),
a chef's knife with pairing blade (PagingAndSortingRepository),
a full chef's kit (JpaRepository). You choose based
on what the cook (service layer) needs."

---

### 💻 Code Example

```java
// Most common: JpaRepository for full features
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    // + findAll(Pageable), saveAll(), flush()...
    List<Order> findByStatus(String status);
}

// Minimal API: only expose what clients should use
public interface OrderReadRepository
        extends Repository<Order, Long> {

    // Only these methods visible to callers:
    Optional<Order> findById(Long id);
    List<Order> findByStatus(String status);
    // No save(), delete(), count() exposed
    // Hides mutating operations from read-only clients
}

// Performance: deleteAllInBatch vs deleteAll
orderRepository.deleteAll();
// Loads ALL orders into PC, then deletes one by one
// 1 SELECT + N DELETEs = terrible for large tables

orderRepository.deleteAllInBatch();
// DELETE FROM orders (no entity loading)
// Single SQL statement - production safe

// saveAndFlush for immediate write
Order savedOrder = orderRepository.saveAndFlush(order);
// Immediately writes to DB and increments version
// Use when downstream operations need the DB state
```

> **Code walkthrough:** JpaRepository is the standard
> choice. The custom Repository (no methods from parent)
> creates a narrower API: only explicitly declared methods
> are accessible. This is valuable for read-only
> repository interfaces (service A reads only, service
> B writes). deleteAllInBatch() is critical for production:
> deleteAll() loads all entities into the persistence
> context first (catastrophic for large tables).
> deleteAllInBatch() is a single SQL DELETE.

---

### ⚖️ Comparison Table

| Interface | Methods Added | Use when |
|---|---|---|
| Repository | None (marker) | Custom minimal API |
| CrudRepository | save, findById, delete, count | Basic CRUD only |
| PagingAndSortingRepository | Pageable, Sort | + pagination |
| JpaRepository | flush, saveAll, getReferenceById, deleteInBatch | Spring Data JPA default |

---

### 🎓 Answers by Seniority

**Junior:** "JpaRepository is the most common. It adds
pagination, batch operations, and flush. I extend it
for standard Spring Data JPA repositories."

**Senior:** "I extend Repository (not JpaRepository)
for read-only repository interfaces - this prevents
callers from calling save() or delete() accidentally.
deleteAllInBatch() vs deleteAll() is important in
production: deleteAll() loads entities, deleteAllInBatch()
does a single DELETE."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Hierarchy, JpaRepository methods |
| Senior | 5 min | Minimal API via Repository, deleteInBatch vs deleteAll |

---

**[SENIOR] Q1 - What is the difference between
getReferenceById() and findById()?**

*Why they ask:* Common Spring Data JPA method choice.

findById(id): Immediately executes SELECT. Returns
Optional<T>. The entity is in the persistence context
as Managed. Use when you need the entity's data.

getReferenceById(id) (previously getById, getOne):
Returns a Hibernate proxy (lazy reference). Does NOT
execute SELECT immediately. Use when you only need the
entity for an association (FK reference), not its data.

Example:
```java
// Use getReferenceById when you only need the FK:
Product product = productRepo.getReferenceById(productId);
// No SELECT yet!
OrderItem item = new OrderItem(order, product, qty);
// item.product = proxy with only the ID
// No SELECT for product's data

// Use findById when you need product data:
Product product = productRepo.findById(productId)
    .orElseThrow(NotFoundException::new);
// SELECT NOW - you need the name, price, etc.
```

If you access a proxy's field (other than getId()),
Hibernate executes the SELECT lazily.
If the entity doesn't exist, accessing the proxy throws
EntityNotFoundException (vs findById returning empty).

*What separates good from great:* Knowing getReferenceById
avoids a SELECT when you only need the FK reference.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Hierarchy methods, differences between interfaces. |
| Hiring Manager | Right interface = correct API surface for clients. |
| Bar Raiser | getReferenceById vs findById, deleteInBatch, minimal API pattern. |
| Peer Engineer | "getReferenceById saved us dozens of unnecessary SELECTs in batch processing. Learn it." |

---

---

# Query Derivation Method Naming

**Interview Weight:** medium - Method name query
derivation is a core Spring Data JPA feature tested
in interviews to verify fluency with the naming
conventions.

---

### 🎯 Model Answer

**30 seconds:**

> Spring Data JPA derives JPQL from method names by
> parsing keywords. findByLastName(String lastName)
> → WHERE last_name=?. Keywords: By (WHERE), And, Or,
> GreaterThan, Between, Like, IsNull, In, OrderBy.
> The method name starts with find, get, read, count,
> exists, delete, then By, then the field paths. Complex
> queries become unreadable method names - use @Query
> instead. The limit: methods are validated at startup
> (fail fast if field doesn't exist).

**3 minutes (Senior):**

> Method naming keywords (selection):
>
> Prefix: find/get/read (return entity/list),
>   count (return Long), exists (return boolean),
>   delete/remove (return void/count)
>
> Connectors: By (WHERE), And, Or
>
> Property conditions:
> - [Property]                → = ?
> - [Property]Not            → != ?
> - [Property]Like           → LIKE ?
> - [Property]StartingWith   → LIKE ?%
> - [Property]EndingWith     → LIKE %?
> - [Property]Containing     → LIKE %?%
> - [Property]IgnoreCase     → upper() = upper(?)
> - [Property]GreaterThan    → > ?
> - [Property]Between        → BETWEEN ?,?
> - [Property]In             → IN (?,?,?)
> - [Property]IsNull         → IS NULL
> - [Property]IsNotNull      → IS NOT NULL
>
> Sorting: OrderBy[Property]Asc/Desc
>
> Limiting: findTop3By..., findFirst5By...
>
> Nested navigation: findByCustomerAddress_City
>   → o.customer.address.city (__ separates path)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Spring Data JPA's
convention for generating queries from method names."

**(2) First principles:** "Spring Data JPA reads the
method name, parses it into a JPQL query, and generates
the implementation. The method name is the DSL."

**(3) Bridge:** "Method name derivation is reading
the method name like a sentence: 'find orders by
status and total greater than'. Spring Data translates
this sentence to SQL."

---

### 💻 Code Example

```java
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    // Basic condition
    List<Order> findByStatus(String status);
    // → WHERE status = ?

    // Multiple conditions
    List<Order> findByStatusAndCustomerId(
        String status, Long customerId);
    // → WHERE status = ? AND customer_id = ?

    // Comparison
    List<Order> findByTotalGreaterThan(
        BigDecimal minTotal);
    // → WHERE total > ?

    // Range
    List<Order> findByCreatedAtBetween(
        LocalDateTime from, LocalDateTime to);
    // → WHERE created_at BETWEEN ? AND ?

    // Null check
    List<Order> findByDispatchedAtIsNull();
    // → WHERE dispatched_at IS NULL

    // IN clause
    List<Order> findByStatusIn(
        Collection<String> statuses);
    // → WHERE status IN (?,?,?)

    // Top N
    List<Order> findTop5ByStatusOrderByTotalDesc(
        String status);
    // → WHERE status=? ORDER BY total DESC LIMIT 5

    // Count and exists
    long countByStatus(String status);
    // → SELECT COUNT(*) WHERE status=?

    boolean existsByOrderNumber(String orderNumber);
    // → SELECT COUNT(*) > 0 WHERE order_number=?

    // BAD: too long, unmaintainable
    List<Order> findByCustomerIdAndStatusAndTotalGreaterThanAndCreatedAtAfterOrderByCreatedAtDesc(
        Long customerId, String status,
        BigDecimal total, LocalDateTime after);
    // Use @Query instead for this complexity
}
```

> **Code walkthrough:** Method names map directly to
> JPQL predicates. findByStatusAndCustomerId generates
> a single query with two WHERE conditions. The naming
> is validated at startup: if Status or CustomerId
> don't exist as Order fields, the application fails
> to start. The last method is intentionally bad: names
> this long are unreadable, fragile (rename a field
> and the method name must change), and harder to review.
> Use @Query for any method with more than 3 conditions.

---

### ⚖️ Comparison Table

| Keyword | JPQL | Example |
|---|---|---|
| By | WHERE | findByStatus(s) |
| And | AND | findByStatusAndTotal |
| Or | OR | findByStatusOrTotal |
| GreaterThan | > | findByTotalGreaterThan(t) |
| Between | BETWEEN | findByDateBetween(s,e) |
| Like | LIKE | findByNameLike("%a%") |
| In | IN | findByStatusIn(list) |
| IsNull | IS NULL | findByDeletedAtIsNull |
| OrderBy | ORDER BY | findByStatusOrderByDate |

---

### 🎓 Answers by Seniority

**Junior:** "Method names are parsed to generate JPQL.
findByStatus(String) → WHERE status=?. Validated at
startup - typos fail fast."

**Senior:** "I limit derived query methods to 3 conditions
max. Beyond that, @Query with explicit JPQL is clearer,
reviewable, and refactoring-safe. Method names longer
than ~30 characters are a code smell."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Keywords, startup validation |
| Senior | 5 min | When to use @Query instead, findTop, existsBy |

---

**[JUNIOR] Q1 - What does findDistinctByStatusIn
(Collection<String> statuses) generate?**

*Why they ask:* Tests keyword combinations.

Generated JPQL: SELECT DISTINCT o FROM Order o WHERE
o.status IN (:statuses)

SQL: SELECT DISTINCT * FROM orders WHERE status IN (?,?,?)

The Distinct keyword adds SELECT DISTINCT. The In keyword
generates an IN clause. The parameter is a Collection
(list, set) which maps to a multi-value bind parameter.

Note: for large collections (100+ values), IN clauses
can be slow on some databases. Consider JPA batching
or a JOIN with a temp table for very large lists.

*What separates good from great:* Knowing the large
IN clause performance limitation.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Keyword list, JPQL generation, startup validation. |
| Hiring Manager | Method naming = no SQL for common queries. |
| Bar Raiser | Method length limits, @Query trade-offs, large IN clause limits. |
| Peer Engineer | "I use findByIdIn() for batch ID lookups. It's cleaner than a @Query for this case." |

---

---

# @Query and Custom JPQL

**Interview Weight:** medium - @Query enables full JPQL
control in Spring Data JPA repositories. Tested for
custom logic, JOIN FETCH, and modification queries.

---

### 🎯 Model Answer

**30 seconds:**

> @Query on a repository method defines a custom JPQL
> or native SQL query. It replaces the derived method
> name for complex conditions. JPQL @Query: uses entity
> names and fields (database-independent). Native @Query:
> uses table names (nativeQuery=true). For modification
> queries (UPDATE/DELETE), add @Modifying and @Transactional.
> @Modifying(clearAutomatically=true) clears the
> persistence context after the bulk operation.

**3 minutes (Senior):**

> @Query patterns:
>
> Basic @Query:
>   @Query("SELECT o FROM Order o WHERE o.total > :min")
>   List<Order> findLargeOrders(@Param("min") BigDecimal min);
>
> JOIN FETCH in @Query:
>   @Query("SELECT o FROM Order o JOIN FETCH o.items
>           WHERE o.id = :id")
>   Optional<Order> findByIdWithItems(@Param("id") Long id);
>   - Eagerly loads items in the query
>   - Avoids N+1 for this specific use case
>
> @Modifying with @Transactional:
>   @Modifying @Transactional
>   @Query("UPDATE Order o SET o.status = :status
>           WHERE o.id = :id")
>   int updateStatus(@Param("id") Long id,
>                    @Param("status") String status);
>   - Returns int (affected rows)
>   - Bypasses persistence context
>
> @Modifying(clearAutomatically=true):
>   Automatically calls em.clear() after the update.
>   Required when managed entities should reflect the
>   bulk change.
>
> Named parameters vs positional:
>   @Param("name") + :name → preferred
>   ?1, ?2 positional → avoid (fragile to order changes)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about @Query for
custom JPQL or SQL in Spring Data JPA repositories."

**(2) First principles:** "Derived queries work for
simple conditions. @Query is for everything else:
complex WHERE, JOIN FETCH, aggregation, bulk updates."

**(3) Bridge:** "@Query is the escape from method name
DSL to full JPQL. Derived names = sentence; @Query =
full paragraph."

---

### 💻 Code Example

```java
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    // JOIN FETCH to avoid N+1
    @Query("SELECT DISTINCT o FROM Order o "
        + "JOIN FETCH o.items "
        + "WHERE o.status = :status")
    List<Order> findByStatusWithItems(
        @Param("status") String status);

    // Aggregate query returning DTO
    @Query("SELECT NEW com.example.OrderStatsDto("
        + "o.customerId, COUNT(o), SUM(o.total)) "
        + "FROM Order o GROUP BY o.customerId "
        + "HAVING COUNT(o) >= :min")
    List<OrderStatsDto> getCustomerStats(
        @Param("min") long minOrders);

    // Bulk UPDATE - requires @Modifying
    @Modifying(clearAutomatically = true)
    @Transactional
    @Query("UPDATE Order o SET o.status = 'ARCHIVED' "
        + "WHERE o.createdAt < :cutoff")
    int archiveOldOrders(
        @Param("cutoff") LocalDate cutoff);

    // Native SQL for DB-specific features
    @Query(value =
        "SELECT o.*, ROW_NUMBER() OVER "
        + "(PARTITION BY o.customer_id "
        + "ORDER BY o.created_at DESC) AS rn "
        + "FROM orders o WHERE rn = 1",
        nativeQuery = true)
    List<Order> findLatestOrderPerCustomer();

    // Pagination with @Query
    @Query("SELECT o FROM Order o "
        + "WHERE o.status = :status")
    Page<Order> findPagedByStatus(
        @Param("status") String status,
        Pageable pageable);
    // Return Page<Order> to get total count
    // Return Slice<Order> to skip total count query
}
```

> **Code walkthrough:** Four patterns: (1) JOIN FETCH
> with DISTINCT for N+1 avoidance; (2) constructor
> expression for DTO results from aggregate queries;
> (3) bulk UPDATE with @Modifying + clearAutomatically
> (avoids stale managed entities in the persistence
> context); (4) native SQL for window functions (impossible
> in JPQL). Pagination with @Query works by appending
> LIMIT/OFFSET - Spring Data handles this automatically
> for Page<T> returns.

---

### ⚖️ Comparison Table

| Feature | Derived Method | @Query JPQL | @Query Native |
|---|---|---|---|
| Startup validation | Yes | Yes | Partially |
| JOIN FETCH | No | Yes | Via JOIN |
| Aggregate | Limited | Yes | Yes |
| Bulk UPDATE | No | Yes + @Modifying | Yes |
| DB-specific syntax | No | No | Yes |
| Readability | Low (long names) | High | Medium |

---

### 🎓 Answers by Seniority

**Junior:** "@Query lets me write custom JPQL. @Param
maps method parameters to named parameters. For updates
I add @Modifying and @Transactional."

**Senior:** "@Modifying(clearAutomatically=true) is
critical for bulk updates: it clears the persistence
context so stale managed entities don't hide the bulk
change. JOIN FETCH in @Query is my preferred N+1 fix
for entity-returning queries."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | @Query syntax, @Param, @Modifying |
| Senior | 6 min | clearAutomatically, JOIN FETCH, Slice vs Page |

---

**[SENIOR] Q1 - What is the difference between
returning Page<T> and Slice<T> from a @Query method?**

*Why they ask:* Pagination performance understanding.

Page<T>: Spring Data JPA executes TWO queries:
1. The main query (with LIMIT and OFFSET)
2. A COUNT(*) query to get the total number of elements

Why: Page<T> knows the total pages and total elements.
Cost: the COUNT query can be expensive for large tables.

Slice<T>: Spring Data JPA executes ONE query:
1. The main query (fetches pageSize + 1 elements)
   The extra element tells if there's a next page.

Why: Slice<T> only knows if there's a next page (yes/no).
No total count. Cost: no COUNT query.

Use Page<T> when: you need total pages/elements (UI
pagination with "Page 3 of 15").

Use Slice<T> when: you only need prev/next navigation
(infinite scroll, cursor pagination). More efficient
for large tables.

*What separates good from great:* Knowing that Page<T>
runs TWO queries and Slice<T> avoids the COUNT query.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @Query syntax, @Modifying, @Param. |
| Hiring Manager | Custom JPQL in repositories = no raw EntityManager. |
| Bar Raiser | Page vs Slice cost, clearAutomatically, JOIN FETCH. |
| Peer Engineer | "Switching from Page to Slice eliminated a 200ms COUNT(*) on a 50M row table." |

---

---

# Pagination and Sorting

**Interview Weight:** medium - Pagination is a core
feature of every data-access layer. Interviewers test
Spring Data JPA's Pageable abstraction and offset vs
cursor pagination.

---

### 🎯 Model Answer

**30 seconds:**

> Spring Data JPA supports pagination via Pageable
> parameter. Pass PageRequest.of(page, size) or
> PageRequest.of(page, size, Sort) to any repository
> method that accepts Pageable. Returns Page<T> (includes
> total count) or Slice<T> (no total count, just
> hasNext). Sorting via Sort.by("field").descending()
> or through Pageable. For large datasets, offset
> pagination is slow at deep pages; use cursor-based
> pagination (WHERE id > lastId) instead.

**3 minutes (Senior):**

> Pagination components:
>
> PageRequest.of(page, size): 0-based page index,
>   items per page (up to ~1000 max - larger sizes
>   are slow)
>
> PageRequest.of(page, size, Sort.by("total").descending()):
>   combines pagination with sorting
>
> Page<T>: result + metadata
>   - getContent(): List<T>
>   - getTotalElements(): count of all matching
>   - getTotalPages(): total pages
>   - hasNext() / hasPrevious()
>
> Slice<T>: result + hasNext only (no count)
>
> Sorting:
>   Sort.by("total")                     → ASC
>   Sort.by("total").descending()        → DESC
>   Sort.by(Sort.Direction.DESC, "total")
>   Sort.by("status", "total")           → multi-column
>
> Offset pagination limit:
>   Page 1000 with size 20 = OFFSET 20000
>   Database scans 20,020 rows, discards 20,000
>   Performance degrades linearly with page depth

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about pagination and
sorting in Spring Data JPA repositories."

**(2) First principles:** "Loading millions of records
at once is impractical. Pagination loads a subset at
a time. Sorting ensures consistent ordering. Without
consistent ordering, pagination returns random results."

**(3) Bridge:** "Pageable is a request for a page of
data. PageRequest specifies which page and how many.
Page<T> is the response with the page contents and
metadata."

---

### 💻 Code Example

```java
// Repository
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    Page<Order> findByStatus(
        String status, Pageable pageable);
    // Spring Data generates:
    // SELECT * FROM orders WHERE status=?
    //   ORDER BY ... LIMIT ? OFFSET ?
    // + SELECT COUNT(*) FROM orders WHERE status=?
}

// Service: offset pagination
@Service
public class OrderService {

    public Page<Order> getOrders(
            String status, int page, int size) {

        Sort sort = Sort.by("createdAt").descending();
        Pageable pageable =
            PageRequest.of(page, size, sort);

        return orderRepository.findByStatus(
            status, pageable);
    }

    // Cursor-based pagination (better at deep pages)
    public List<Order> getOrdersAfter(
            String status,
            Long lastId, int size) {
        return orderRepository
            .findByStatusAndIdGreaterThan(
                status, lastId,
                PageRequest.of(0, size,
                    Sort.by("id").ascending()))
            .getContent();
        // WHERE status=? AND id > lastId
        // ORDER BY id ASC LIMIT size
        // Constant cost regardless of page depth!
    }
}

// Spring MVC: Pageable from request
@GetMapping("/orders")
public Page<OrderDto> getOrders(
        @RequestParam String status,
        Pageable pageable) {
    // ?page=0&size=20&sort=total,desc
    // Spring auto-creates Pageable from params
    return orderService.findByStatus(
        status, pageable);
}
```

> **Code walkthrough:** findByStatus with Pageable
> generates two queries: the paginated SELECT and a
> COUNT(*). PageRequest combines page/size/sort. The
> cursor-based alternative uses WHERE id > lastId instead
> of OFFSET - it's index-friendly (uses the PK index)
> and constant cost regardless of depth. Spring MVC
> auto-binds ?page=0&size=20&sort=total,desc to a
> Pageable parameter via HandlerMethodArgumentResolver.

---

### ⚖️ Comparison Table

| Pagination Type | Offset | Cursor |
|---|---|---|
| Implementation | OFFSET ? | WHERE id > lastId |
| Performance deep pages | O(offset+limit) | O(1) |
| Total count | Yes | No |
| Random access | Yes (page 500) | No |
| Best for | Small-medium data | Large data, infinite scroll |
| UI compatibility | "Page X of Y" | Next/prev only |

---

### 🎓 Answers by Seniority

**Junior:** "Pageable parameter on repository methods
enables pagination. PageRequest.of(page, size) creates
the request. Page<T> contains the content and total
count."

**Senior:** "Offset pagination degrades at deep pages
(OFFSET 50,000 scans 50,000 rows). For deep pagination
or infinite scroll, use cursor-based: WHERE id > lastId
ORDER BY id LIMIT n. No COUNT, constant cost. Page<T>
for UI with total pages; Slice<T> or List<T> + cursor
for infinite scroll."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Pageable, PageRequest, Page return |
| Senior | 6 min | Offset vs cursor, Slice, MVC integration |

---

**[SENIOR] Q1 - Why does pagination fail to produce
consistent results without a sort on a unique column?**

*Why they ask:* Common data corruption bug.

Without deterministic sorting, the database can return
rows in any order (different per query due to query
plan, buffer state, parallel execution). Page 1 and
page 2 may overlap (same row returned on both pages)
or have gaps.

Example: unsorted pagination of 100 orders, page size 10:
- Page 1 query: returns rows 1-10 (in DB's current order)
- Insert of new order changes the DB order
- Page 2 query: returns rows 11-20 (shifted, row 10
  might appear again)

Fix: always sort by a stable, unique column:
- Sort.by("id").ascending() - always unique, stable
- Or composite: Sort.by("createdAt").descending()
  .and(Sort.by("id").ascending()) - tie-break with id

Spring Data JPA validates: if you try to use pageable
without sort, some databases may return inconsistent
results.

*What separates good from great:* The overlap/gap
mechanism and why a unique sort column is required.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | PageRequest, Page vs Slice, sort parameter. |
| Hiring Manager | Stable pagination = consistent user experience. |
| Bar Raiser | Cursor vs offset, pagination consistency, MVC auto-binding. |
| Peer Engineer | "Offset pagination at page 5,000 was taking 2 seconds. Switching to cursor pagination fixed it instantly." |

---

---

# Spring Data JPA Projections

**Interview Weight:** critical - Spring Data JPA
projections are the recommended pattern for read
optimization. Interviewers test understanding of
interface projections, DTO projections, and dynamic
projections.

---

### 🎯 Model Answer

**30 seconds:**

> Spring Data JPA projections return a subset of entity
> data. Three types: (1) Interface projection (closed):
> define an interface with getters → Spring Data selects
> only those columns. (2) Class-based DTO: @Value or
> constructor. (3) Dynamic projection: repository method
> takes a Class<T> parameter and returns different
> projection types at runtime. Use projections for read
> APIs to avoid loading full entity graphs.

**3 minutes (Senior):**

> Interface projection types:
>
> Closed projection: only interface-declared getters
>   → SQL selects ONLY those columns
>   → All getters map to column names (camelCase to snake_case)
>
> Open projection: has at least one @Value SpEL method
>   → loads FULL entity as backing object
>   → SpEL computed from entity fields
>   → No column reduction (performance loss)
>
> Dynamic projection:
>   <T> List<T> findByStatus(String s, Class<T> type);
>   → caller decides the projection at call time
>   → same repository method, different shapes
>
> Spring Data JPA uses Hibernate proxy for closed
> interface projections at runtime:
>   - Not a real class instantiation
>   - Immutable proxy backed by query results
>   - Null-safe: null fields return null from getter
>
> Nested projections:
>   interface OrderView {
>     CustomerName getCustomer();
>     interface CustomerName { String getName(); }
>   }
>   → Generates JOIN to customer table,
>     selects customer.name

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Spring Data JPA
projections - returning partial data instead of full
entities."

**(2) First principles:** "Full entities load all
columns even when only 2 are needed. Projections select
only needed columns, reducing DB I/O and memory."

**(3) Bridge:** "Projections are shaped windows onto
your data: each interface defines a different shape
(columns) to display through. The data source (table)
stays the same; the window (projection) changes per
use case."

---

### 💻 Code Example

```java
// Closed interface projection (efficient - selects few columns)
public interface OrderSummary {
    Long getId();
    String getStatus();
    BigDecimal getTotal();
    // No customer, items, etc.
}

// Open projection (inefficient - loads full entity)
public interface OrderWithTax {
    Long getId();
    BigDecimal getTotal();

    @Value("#{target.total * 0.1}")
    BigDecimal getTax();  // SpEL = open projection
    // Warning: target = full entity loaded!
}

// Repository with projections
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    // Closed projection: SELECT id, status, total
    //                     FROM orders WHERE status=?
    List<OrderSummary> findSummariesByStatus(
        String status);

    // Dynamic projection
    <T> List<T> findByStatus(
        String status, Class<T> projectionType);
}

// Usage: dynamic projection
orderRepository.findByStatus("PAID", OrderSummary.class);
orderRepository.findByStatus("PAID", Order.class);  // full entity

// Nested projection
public interface OrderWithCustomer {
    Long getId();
    CustomerName getCustomer();  // nested projection

    interface CustomerName {
        String getName();
        String getEmail();
    }
}
// → SELECT o.id, c.name, c.email
//    FROM orders o JOIN customers c
//    ON o.customer_id = c.id
// JPA generates JOIN automatically!
```

> **Code walkthrough:** Closed interface projection
> (OrderSummary) generates SELECT with ONLY the getter-
> mapped columns. Open projection (OrderWithTax with
> @Value) loads the full entity. Dynamic projection takes
> a Class<T> and returns the right shape. Nested projections
> auto-generate JOINs - the nested interface (CustomerName)
> triggers a JOIN on the customer relationship. This
> enables efficient multi-table reads without loading
> full entity graphs.

---

### ⚖️ Comparison Table

| Projection Type | SQL columns | @Value SpEL | Loads full entity | Mutable |
|---|---|---|---|---|
| Closed interface | Only getter columns | No | No | No |
| Open interface | All columns | Yes | Yes | No |
| Class-based DTO | Constructor params | No | No | Depends |
| Dynamic projection | Depends on type | N/A | N/A | N/A |
| Entity (no projection) | All columns | No | Yes | Yes |

---

### 🎓 Answers by Seniority

**Junior:** "Interface projections return only the
columns defined in the interface. Closed projections
are efficient - they reduce the SQL columns selected."

**Senior:** "I use closed interface projections for
all read-only APIs. Nested projections generate JOINs
automatically. Dynamic projections allow a single
repository method to return different shapes. The open
projection @Value trap: any @Value method makes Spring
load the full entity - it's a performance footgun."

**Staff:** "Projections are the domain read model.
Each read use case gets its own projection interface:
OrderSummary (list view), OrderDetail (full view),
OrderForAudit (audit view). This implements CQRS at
the repository level. No over-fetching; each query
returns exactly what the caller needs."

---

### 🚨 Failure Modes and Diagnosis

**Failure: Projection not reducing columns (still
SELECT *)**

Symptom: Projection query still shows SELECT * in logs.

Root cause: Open projection (has @Value method). Spring
loads full entity as backing object.

Diagnosis: Check the projection interface for any
@Value annotation. Enable SQL logging and count
columns selected.

Fix: Remove @Value methods. Compute derived fields
in the service layer instead.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Closed vs open projection, column reduction |
| Senior | 7 min | Open vs closed trap, nested projections, dynamic projections |

---

**[STAFF] Q1 - How do you design a read model using
Spring Data JPA projections for a CQRS architecture?**

*Why they ask:* Architectural application of projections.

CQRS read model design with projections:

1. **One projection per use case:**
   - OrderListView: id, status, total, customerName (for order list)
   - OrderDetailView: all fields + items + customer details
   - OrderExportView: fields for CSV export (different subset)
   - Never use a single fat DTO for everything

2. **Nested projections for joins:**
   ```java
   interface OrderDetailView {
       Long getId();
       String getStatus();
       List<ItemView> getItems();

       interface ItemView {
           String getProductName();
           int getQuantity();
           BigDecimal getPrice();
       }
   }
   ```
   Generates the right JOINs automatically.

3. **Dynamic projections for endpoints:**
   ```java
   <T> Optional<T> findById(Long id, Class<T> type);
   ```
   One repository method, multiple representations.

4. **Interface per API contract, not per entity:**
   The projection interface IS the API contract.
   API changes → change the interface.
   Entity changes → entity changes independently.

*What separates good from great:* "Projection interface
= API contract, not entity subset" - projections are
decoupled from entity structure.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Closed vs open, nested projections, dynamic projections. |
| Hiring Manager | Projections = efficient read APIs. |
| Bar Raiser | CQRS with projections, API contract design, one-projection-per-use-case. |
| Peer Engineer | "Every read endpoint gets its own projection interface. No shared fat DTOs." |
