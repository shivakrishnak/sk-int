---
layout: default
title: "JPA - L2 Querying"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 4
permalink: /jpa/l2-querying/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [JPQL Advanced Queries](#jpql-advanced-queries) | medium |
| 2 | [JPA Criteria API](#jpa-criteria-api) | medium |
| 3 | [Named Queries](#named-queries) | easy |
| 4 | [Native Queries and Result Mapping](#native-queries-and-result-mapping) | medium |
| 5 | [DTO Projections](#dto-projections) | medium |

---

# JPQL Advanced Queries

**Interview Weight:** medium - Advanced JPQL covers JOIN
types, aggregate queries, and JPQL bulk operations.
Tests if candidates can build complex queries without
falling back to native SQL.

---

### 🎯 Model Answer

**30 seconds:**

> Advanced JPQL includes JOIN FETCH (eager loading to
> avoid N+1), aggregate functions (COUNT, SUM, AVG with
> GROUP BY/HAVING), constructor expressions (SELECT NEW
> Dto() for DTOs), subqueries, and bulk UPDATE/DELETE.
> The key difference from SQL: navigate object graph
> (o.customer.address) instead of explicit JOINs. JOIN
> without FETCH is for filtering; JOIN FETCH is for
> loading.

**3 minutes (Senior):**

> Advanced JPQL patterns:
>
> JOIN types:
> - JOIN: for WHERE filtering (doesn't load the join)
> - JOIN FETCH: for loading the relationship
> - LEFT JOIN / LEFT JOIN FETCH: includes entities with
>   no match on the join
>
> Constructor expressions:
>   SELECT NEW com.example.OrderSummary(o.id, o.total,
>   c.name) FROM Order o JOIN o.customer c
>   Returns OrderSummary DTOs directly
>
> Aggregate with GROUP BY:
>   SELECT c, COUNT(o), SUM(o.total) FROM Order o
>   JOIN o.customer c GROUP BY c HAVING COUNT(o) > 5
>   Returns Object[] with [Customer, count, sum]
>
> Subqueries:
>   SELECT o FROM Order o WHERE o.total > (SELECT
>   AVG(o2.total) FROM Order o2)
>   Note: FROM clause subqueries not supported in JPQL
>
> Bulk UPDATE/DELETE (bypasses PC):
>   UPDATE Order o SET o.status = 'ARCHIVED'
>   WHERE o.createdAt < :cutoff
>   Call em.clear() after to avoid stale entities.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about advanced JPQL
patterns beyond simple SELECT...WHERE."

**(2) First principles:** "JPQL is object-oriented SQL.
All SQL patterns (aggregation, JOIN, subquery, bulk
update) have JPQL equivalents - but operating on
entities and their fields, not tables and columns."

**(3) Bridge:** "JOIN FETCH is JPQL's most important
advanced feature: it's the N+1 cure. Constructor
expressions are the DTO shortcut. These two patterns
cover 90% of performance-related JPQL questions."

---

### 💻 Code Example

```java
// Advanced JPQL examples

// 1. JOIN FETCH with alias for filtering
List<Order> orders = em.createQuery(
    "SELECT DISTINCT o FROM Order o "
    + "JOIN FETCH o.items i "
    + "WHERE i.quantity > 2",
    Order.class)
    .getResultList();
// DISTINCT needed when JOIN FETCH returns
// duplicate parent rows (one per item)

// 2. Constructor expression for DTO
List<OrderSummaryDto> summaries = em.createQuery(
    "SELECT NEW com.example.OrderSummaryDto("
    + "o.id, o.status, o.total, c.name) "
    + "FROM Order o "
    + "JOIN o.customer c "
    + "WHERE o.status = :status",
    OrderSummaryDto.class)
    .setParameter("status", "PAID")
    .getResultList();

// 3. Aggregate with GROUP BY
List<Object[]> stats = em.createQuery(
    "SELECT c.name, COUNT(o), SUM(o.total) "
    + "FROM Order o JOIN o.customer c "
    + "GROUP BY c.name "
    + "HAVING COUNT(o) >= :minOrders",
    Object[].class)
    .setParameter("minOrders", 5L)
    .getResultList();
for (Object[] row : stats) {
    String name = (String) row[0];
    Long count = (Long) row[1];
    BigDecimal total = (BigDecimal) row[2];
}

// 4. Bulk UPDATE (bypasses persistence context)
int updated = em.createQuery(
    "UPDATE Order o SET o.status = 'ARCHIVED' "
    + "WHERE o.createdAt < :cutoff")
    .setParameter("cutoff",
        LocalDate.now().minusYears(2))
    .executeUpdate();
em.clear(); // clear stale managed entities
```

> **Code walkthrough:** Four patterns: (1) JOIN FETCH
> with filter on the joined entity - DISTINCT prevents
> duplicate parent rows in the result; (2) constructor
> expression for efficient DTOs (no entity proxy
> overhead, only needed columns); (3) aggregate query
> returning Object[] - cast each element manually;
> (4) bulk UPDATE bypasses the PC, so em.clear() is
> required to avoid stale managed entities. Each pattern
> solves a specific problem: N+1, load efficiency,
> reporting, bulk modification.

---

### ⚖️ Comparison Table

| JPQL Pattern | SQL equivalent | Notes |
|---|---|---|
| JOIN FETCH | JOIN (with SELECT *) | Loads the relationship |
| NEW Dto(...) | SELECT col1, col2 | Returns DTO, no entity overhead |
| GROUP BY + COUNT | GROUP BY + COUNT(*) | Returns Object[] |
| Bulk UPDATE | UPDATE ... WHERE | Bypasses PC, need em.clear() |
| Subquery | Subquery in WHERE | No FROM subquery support |

---

### 🎓 Answers by Seniority

**Junior:** "JOIN FETCH loads the relationship. Constructor
expression returns DTOs. GROUP BY works like SQL."

**Senior:** "Three rules: (1) use DISTINCT with JOIN
FETCH collections to avoid duplicate parents. (2) use
constructor expressions for read-only projections.
(3) call em.clear() after bulk UPDATE/DELETE. These
three rules prevent the most common JPQL bugs."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | JOIN FETCH, constructor expression |
| Senior | 6 min | DISTINCT with JOIN FETCH, bulk update PC impact |

---

**[SENIOR] Q1 - Why do you need DISTINCT when using
JOIN FETCH with a collection?**

*Why they ask:* Common JPQL bug in production.

When you JOIN FETCH a @OneToMany collection, the SQL
JOIN produces one row per child entity. For an Order
with 3 items, the JOIN produces 3 rows all with the
same Order data. JPA maps these 3 rows into 3 Order
instances in the result list - but they're the same
Order (same ID, same PC entity).

Without DISTINCT: getResultList() returns [Order1,
Order1, Order1, Order2, Order2, ...] - duplicates.

With DISTINCT: JPA deduplicates by entity identity -
returns [Order1, Order2, ...] with items fully loaded.

In JPQL, DISTINCT is a hint to JPA to deduplicate
in-memory, not necessarily an SQL DISTINCT.

Spring Data JPA workaround: use @Query with DISTINCT
or findDistinctBy... method naming.

*What separates good from great:* "DISTINCT in JPQL
is an in-memory deduplication hint, not always SQL-
level DISTINCT."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | JOIN vs JOIN FETCH, constructor expression, GROUP BY. |
| Hiring Manager | Advanced JPQL = complex queries without SQL. |
| Bar Raiser | DISTINCT with JOIN FETCH, bulk update PC clearing, FROM subquery limitations. |
| Peer Engineer | "I spent a whole morning debugging duplicate results from JOIN FETCH. DISTINCT was the one-word fix." |

---

---

# JPA Criteria API

**Interview Weight:** medium - Criteria API enables
type-safe dynamic queries. Interviewers ask about
Criteria API for queries that build predicates
conditionally.

---

### 🎯 Model Answer

**30 seconds:**

> The JPA Criteria API provides a type-safe, programmatic
> way to build JPQL queries. Instead of string-based
> JPQL, it uses Java objects: CriteriaBuilder creates
> predicates, CriteriaQuery defines the query, Root
> is the entity root. Use it for dynamic queries where
> the WHERE clause depends on user input (search filters).
> Metamodel (generated by Hibernate) provides type-safe
> field references.

**3 minutes (Senior):**

> Criteria API components:
> - CriteriaBuilder: creates predicates (cb.equal,
>   cb.like, cb.gt, cb.and, cb.or)
> - CriteriaQuery<T>: defines SELECT type and structure
> - Root<Order>: the entity being queried (FROM clause)
> - Predicate: WHERE condition
> - Metamodel class (Order_): generated by annotation
>   processor, provides type-safe access to field names
>
> Criteria API shines for:
> - Dynamic search forms (0-N optional filters)
> - Building predicates in multiple steps
>   (separate validation from query building)
> - Type-safe refactoring (rename entity field →
>   compiler error in Criteria code)
>
> Downsides:
> - Verbose (10x more code than JPQL string)
> - Hard to read/review
> - Test overhead
>
> Spring Data JPA alternative: Specification<T>
> wraps a Predicate, composable with .and()/.or().
> JpaSpecificationExecutor adds findAll(Specification).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the JPA Criteria
API for building dynamic, type-safe queries."

**(2) First principles:** "String-based JPQL is fragile:
rename a field and the query breaks at runtime. Criteria
API makes query building programmatic - you can
conditionally add WHERE clauses and get compile-time
safety."

**(3) Bridge:** "Criteria API is to JPQL what StringBuilder
is to String. You build the query piece by piece,
adding conditions dynamically. The metamodel adds
type-safety: Order_.status is a reference to the
'status' field, not a string 'status'."

---

### 💻 Code Example

```java
// JPQL string - breaks at runtime if field renamed
List<Order> orders = em.createQuery(
    "SELECT o FROM Order o "
    + "WHERE o.status = :s AND o.total > :t",
    Order.class)
    .setParameter("s", status)
    .setParameter("t", minTotal)
    .getResultList();

// Criteria API - type-safe, dynamic
public List<Order> search(
        String status, BigDecimal minTotal,
        Long customerId) {
    CriteriaBuilder cb =
        em.getCriteriaBuilder();
    CriteriaQuery<Order> cq =
        cb.createQuery(Order.class);
    Root<Order> root = cq.from(Order.class);

    List<Predicate> predicates = new ArrayList<>();

    if (status != null) {
        predicates.add(
            cb.equal(root.get(Order_.status),
                status));
    }
    if (minTotal != null) {
        predicates.add(
            cb.greaterThan(
                root.get(Order_.total), minTotal));
    }
    if (customerId != null) {
        predicates.add(
            cb.equal(
                root.get(Order_.customerId),
                customerId));
    }

    cq.where(predicates.toArray(new Predicate[0]));
    cq.orderBy(cb.desc(root.get(Order_.createdAt)));

    return em.createQuery(cq).getResultList();
}

// Spring Data JPA Specification (cleaner alternative)
Specification<Order> byStatus(String status) {
    return (root, query, cb) ->
        status == null ? cb.conjunction()
            : cb.equal(root.get("status"), status);
}

// Usage
orderRepo.findAll(
    byStatus("PAID").and(byMinTotal(new BigDecimal("100")))
);
```

> **Code walkthrough:** The Criteria API builds the
> query by conditionally adding Predicates to a list.
> Only non-null parameters add predicates - this is
> the dynamic query advantage. Order_ is the generated
> metamodel class (by Hibernate's annotation processor)
> providing type-safe access to field names. Spring
> Data JPA's Specification is a cleaner alternative:
> each condition is a lambda, composable with .and()
> and .or(), tested independently.

---

### ⚖️ Comparison Table

| Aspect | JPQL String | Criteria API | Specification |
|---|---|---|---|
| Type-safe | No | Yes (with metamodel) | Partial |
| Dynamic (optional conditions) | Awkward | Yes | Yes |
| Readability | High | Low | Medium |
| Verbosity | Low | High | Medium |
| Refactoring-safe | No | Yes | No (string names) |
| Best for | Fixed queries | Complex dynamic | Spring Data dynamic |

---

### 🎓 Answers by Seniority

**Junior:** "Criteria API builds queries programmatically.
Good for dynamic search where some filter conditions
are optional."

**Senior:** "I prefer Spring Data JPA Specification
over raw Criteria API - less verbose, composable,
testable. Raw Criteria API for complex queries that
Spring Data can't handle. The metamodel is the key
to type-safety: Order_.status instead of the string
'status'."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | When to use Criteria, basic structure |
| Senior | 6 min | Specification pattern, metamodel, vs Querydsl |

---

**[SENIOR] Q1 - How do Specifications compare to
raw Criteria API for dynamic queries?**

*Why they ask:* Spring Data JPA Specification is the
production alternative.

Specifications wrap a single predicate. They're:
1. Composable: spec1.and(spec2), spec1.or(spec2)
2. Reusable: OrderSpec.byStatus("PAID") can be used
   in multiple queries
3. Testable: each Specification is a single condition
   unit-testable without an entity
4. Less verbose: lambda syntax vs 15 lines of Criteria

The JpaSpecificationExecutor interface (extend from
it in your repository) adds:
- findOne(Specification<T>)
- findAll(Specification<T>)
- findAll(Specification<T>, Pageable)

For very complex queries, Querydsl is even better:
- Generated QOrder.order.status.eq("PAID") syntax
- Supports joins, subqueries, EXISTS
- Maven/Gradle annotation processor generates Q classes

*What separates good from great:* Naming Querydsl as
the upgrade path from Specification for complex cases.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | CriteriaBuilder, Root, Predicate components. |
| Hiring Manager | Criteria API = safe dynamic search without SQL injection. |
| Bar Raiser | Specification composition, Querydsl, metamodel type-safety. |
| Peer Engineer | "Raw Criteria API is unreadable. Specifications are the right abstraction. Learn Querydsl once you need joins." |

---

---

# Named Queries

**Interview Weight:** easy - Named queries are tested
as a basic JPA feature. Interviewers check understanding
of validation at startup.

---

### 🎯 Model Answer

**30 seconds:**

> @NamedQuery defines a static JPQL query on the entity
> class, validated at application startup. It has a
> name and a query string. Usage: em.createNamedQuery(
> "Order.findByStatus", Order.class). Benefits: JPQL
> validated at startup (syntax errors fail fast, not
> at runtime), can be cached by provider, centralizes
> query strings on the entity. Spring Data JPA alternative:
> @Query on repository methods.

**3 minutes (Senior):**

> Named query features:
> - @NamedQuery and @NamedQueries on entity class
> - Validated at startup: JPQL syntax error → application
>   doesn't start (fail fast)
> - Hibernate caches the parsed query plan
>   (performance benefit for frequently executed queries)
> - @NamedNativeQuery for named native SQL queries
> - Convention: EntityClass.queryName (e.g., Order.findPaid)
>
> Named queries vs @Query (Spring Data JPA):
> - @Query: on repository method, easier to maintain,
>   no entity coupling
> - @NamedQuery: on entity, validated at startup,
>   name-based lookup via createNamedQuery()
>
> JPA 2.1+: @NamedEntityGraph to define entity graphs
> for controlled lazy/eager loading alongside named queries.
>
> In Spring Boot: JPA validates all @NamedQuery
> at EntityManagerFactory creation time. A JPQL error
> in a @NamedQuery fails the entire application startup.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about named queries
in JPA - pre-defined queries registered on entities."

**(2) First principles:** "Pre-defined queries are
validated once (at startup) instead of every time
they're built (at runtime). This shifts error detection
from runtime to startup."

**(3) Bridge:** "@NamedQuery is like pre-defined stored
procedures in the ORM layer: register them once, use
them by name. The validation guarantee makes them
safer than dynamic JPQL strings."

---

### 💻 Code Example

```java
// Named queries defined on the entity
@Entity
@NamedQueries({
    @NamedQuery(
        name = "Order.findByStatus",
        query = "SELECT o FROM Order o "
            + "WHERE o.status = :status "
            + "ORDER BY o.createdAt DESC"),
    @NamedQuery(
        name = "Order.countByCustomer",
        query = "SELECT COUNT(o) FROM Order o "
            + "WHERE o.customerId = :customerId")
})
public class Order {
    @Id @GeneratedValue
    private Long id;
    private String status;
    private Long customerId;
}

// Usage with EntityManager
@Service
@Transactional
public class OrderService {

    public List<Order> findByStatus(String status) {
        return em.createNamedQuery(
                "Order.findByStatus", Order.class)
            .setParameter("status", status)
            .getResultList();
    }

    public Long countByCustomer(Long customerId) {
        return em.createNamedQuery(
                "Order.countByCustomer", Long.class)
            .setParameter("customerId", customerId)
            .getSingleResult();
    }
}

// Spring Data JPA: @Query is the modern alternative
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    @Query("SELECT o FROM Order o "
        + "WHERE o.status = :status "
        + "ORDER BY o.createdAt DESC")
    List<Order> findByStatusOrdered(
        @Param("status") String status);
    // Validated at startup (same benefit)
    // Defined near the usage (better locality)
}
```

> **Code walkthrough:** @NamedQuery on the entity class
> registers named queries validated at startup. The
> query name follows the convention EntityName.queryName.
> createNamedQuery() looks up by name and returns a
> TypedQuery. The Spring Data JPA @Query alternative
> provides the same startup validation while keeping
> the query near the repository method (better
> locality, easier to find during code review).

---

### 🎓 Answers by Seniority

**Junior:** "@NamedQuery registers a JPQL query on
the entity, accessible by name. Validated at startup
so syntax errors fail fast."

**Senior:** "In Spring Boot, @Query on repository
methods is the preferred approach - same startup
validation, better locality (query is near the usage).
@NamedQuery is useful in non-Spring environments or
when centralizing queries on the entity makes sense."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | @NamedQuery definition, createNamedQuery usage |
| Senior | 4 min | @NamedQuery vs @Query, startup validation |

---

**[JUNIOR] Q1 - When does @NamedQuery validation occur
and what happens if there's a syntax error?**

*Why they ask:* The startup validation benefit is the
main reason to use @NamedQuery.

JPA validates @NamedQuery JPQL at EntityManagerFactory
creation time, which happens during application startup.

If there's a JPQL syntax error (misspelled entity name,
invalid field reference):
- JPA throws a PersistenceException during startup
- Spring Boot application context fails to start
- The application is dead before serving any request

This is fail-fast behavior: better to fail at startup
than to serve requests successfully until the specific
query is hit at runtime (which might be rare or in
an edge case).

Contrast with string JPQL: em.createQuery("invalid JPQL")
- validated when executed, not at startup.

*What separates good from great:* "Fail-fast at startup
is the main benefit. A wrong @NamedQuery crashes the
app during deployment, not during production traffic."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @NamedQuery placement, startup validation, createNamedQuery. |
| Hiring Manager | Fail-fast = bugs caught during deployment. |
| Bar Raiser | @NamedQuery vs @Query tradeoffs, locality principle. |
| Peer Engineer | "I once had a production query fail because a field was renamed. @NamedQuery would have caught it at deploy." |

---

---

# Native Queries and Result Mapping

**Interview Weight:** medium - Native queries are tested
to see if candidates can break out of JPA for complex
SQL, and understand the result mapping mechanisms.

---

### 🎯 Model Answer

**30 seconds:**

> JPA native queries execute raw SQL via
> em.createNativeQuery(). For simple cases, the result
> is an Object[] per row. For entity mapping, pass the
> entity class: em.createNativeQuery(sql, Order.class).
> For complex result shapes (multiple entities, scalar
> values), use @SqlResultSetMapping or @NamedNativeQuery
> with @SqlResultSetMapping. Native queries are the
> escape hatch for complex SQL that JPQL can't express:
> window functions, CTEs, database-specific functions.

**3 minutes (Senior):**

> Native query patterns:
>
> 1. Simple entity result:
>    createNativeQuery("SELECT * FROM orders WHERE id=?",
>    Order.class) - Hibernate maps columns to entity fields
>
> 2. Object[] result (default):
>    createNativeQuery("SELECT id, status FROM orders")
>    - Returns List<Object[]>, cast manually
>
> 3. @SqlResultSetMapping: maps complex results
>    (multiple entities, scalar columns) to Java objects
>
> 4. Spring Data JPA: @Query(nativeQuery=true)
>    for native queries in repository methods
>
> 5. DTO projections with native queries:
>    Use interface projections or @NamedNativeQuery
>    with @ConstructorResult
>
> Security risk: native queries with string concatenation
> = SQL injection risk. Always use named parameters:
>   createNativeQuery("SELECT * FROM orders WHERE id=:id")
>   .setParameter("id", orderId)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about running raw SQL
in JPA and mapping the results back to Java objects."

**(2) First principles:** "JPQL is powerful but has
limits (no window functions, no CTEs, no DB-specific
syntax). Native queries are the safety valve: use
the full power of SQL when JPQL isn't enough."

**(3) Bridge:** "Native queries are JPA's 'override'
mode: you provide the SQL, JPA provides the result
mapping. Use when JPQL's abstraction is in your way."

---

### 💻 Code Example

```java
// BAD: string concatenation SQL injection risk
public List<Order> findByStatus(String status) {
    return em.createNativeQuery(
        "SELECT * FROM orders WHERE status = '"
        + status + "'",  // SQL injection!
        Order.class)
        .getResultList();
}

// GOOD: named parameter (no injection)
public List<Order> findByStatus(String status) {
    return em.createNativeQuery(
        "SELECT * FROM orders "
        + "WHERE status = :status",
        Order.class)
        .setParameter("status", status)
        .getResultList();
}

// GOOD: complex query with @SqlResultSetMapping
@Entity
@SqlResultSetMapping(
    name = "OrderStats",
    columns = {
        @ColumnResult(name = "customer_id",
                      type = Long.class),
        @ColumnResult(name = "order_count",
                      type = Long.class),
        @ColumnResult(name = "total_spend",
                      type = BigDecimal.class)
    }
)
public class Order { /* ... */ }

// Usage
List<Object[]> stats = em.createNativeQuery(
    "SELECT customer_id, "
    + "COUNT(*) as order_count, "
    + "SUM(total) as total_spend "
    + "FROM orders "
    + "GROUP BY customer_id "
    + "HAVING COUNT(*) > :min",
    "OrderStats")  // references the mapping name
    .setParameter("min", 5)
    .getResultList();

// GOOD: Spring Data JPA native query with DTO interface
public interface OrderStatsProjection {
    Long getCustomerId();
    Long getOrderCount();
    BigDecimal getTotalSpend();
}

@Query(value = "SELECT customer_id as customerId, "
    + "COUNT(*) as orderCount, "
    + "SUM(total) as totalSpend "
    + "FROM orders GROUP BY customer_id",
    nativeQuery = true)
List<OrderStatsProjection> getOrderStats();
// Spring Data JPA maps columns by name to interface
```

> **Code walkthrough:** The BAD version concatenates
> user input directly into SQL - SQL injection vulnerability.
> The GOOD named parameter version is safe. For complex
> result mapping, @SqlResultSetMapping defines type-safe
> column-to-Java-type mappings. The Spring Data JPA
> interface projection is the cleanest approach:
> column names (aliased with AS) map to getter names
> (camelCase to snake_case automatically), returning
> a type-safe proxy.

---

### ⚖️ Comparison Table

| Result Type | API | Best for |
|---|---|---|
| Entity objects | createNativeQuery(sql, Entity.class) | When result matches entity exactly |
| Raw Object[] | createNativeQuery(sql) | Ad hoc, one-off queries |
| Typed mapping | @SqlResultSetMapping | Complex multi-column results |
| DTO interface | Spring Data @Query projection | Read models, report queries |
| DTO class | @ConstructorResult | Immutable DTOs |

---

### 🎓 Answers by Seniority

**Junior:** "em.createNativeQuery() for raw SQL. Pass
the entity class to map results to entities. Use named
parameters to avoid SQL injection."

**Senior:** "For complex analytics, I use native queries
with Spring Data JPA interface projections. Column
aliases in SQL map to getter names automatically.
Named parameters ALWAYS - never string concatenation.
After native bulk UPDATE, call em.clear() to avoid
stale managed entities."

---

### 🚨 Failure Modes and Diagnosis

**Failure: SQL injection via string concatenation
in native query**

Symptom: Security vulnerability. Malicious input like
status = "' OR '1'='1" returns all rows.

Root cause: String concatenation in native query:
"WHERE status = '" + status + "'"

Diagnosis: Code review - check for string + in query
construction.

Fix: ALWAYS use named parameters or positional parameters:
setParameter("status", status). The parameter is
escaped by the JDBC driver.

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | createNativeQuery, named parameters |
| Senior | 6 min | @SqlResultSetMapping, projection interfaces, SQL injection |

---

**[SENIOR] Q1 - How do interface projections work
for native query results?**

*Why they ask:* Spring Data JPA interface projections
for native SQL is a modern, clean pattern.

Interface projections for native queries:
1. Define an interface with getters:
   interface OrderStats { Long getOrderCount(); }
2. SQL aliases must match getter names (camelCase to
   snake_case: orderCount → order_count):
   SELECT COUNT(*) as order_count FROM orders
3. Spring Data JPA generates a proxy that implements
   the interface, backed by the query result

Column name matching: Spring Data converts getter names
to expected column names. getOrderCount() expects
order_count column alias.

Limitation: interface projections are read-only proxies.
They can't be modified and passed back to repositories.
For mutable DTOs, use class-based projections with
@Value("#{target.columnName}") or class-based DTO
constructor expressions.

*What separates good from great:* Knowing the camelCase-
to-snake_case alias convention and read-only limitation.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | createNativeQuery variants, @SqlResultSetMapping. |
| Hiring Manager | Native queries fill JPQL gaps for complex SQL. |
| Bar Raiser | SQL injection prevention, interface projections, stale PC after bulk ops. |
| Peer Engineer | "Interface projections for native queries are underused. They're cleaner than Object[] casting." |

---

---

# DTO Projections

**Interview Weight:** medium - DTO projections are the
recommended way to fetch only needed data. Tested for
read optimization and avoiding the full entity overhead.

---

### 🎯 Model Answer

**30 seconds:**

> JPA DTO projections fetch only specific columns
> instead of full entity graphs. Three approaches:
> (1) JPQL constructor expressions: SELECT NEW com.
> example.OrderDto(o.id, o.total) - maps to a class
> constructor; (2) Spring Data JPA interface projections:
> define an interface with getters, Spring maps column
> values to the interface; (3) Spring Data JPA class-
> based projections: define a class with @Value for
> SpEL mapping. Interface projections are the most
> flexible and work with both JPQL and native SQL.

**3 minutes (Senior):**

> DTO projection types:
>
> 1. JPQL constructor expression:
>    SELECT NEW pkg.OrderDto(o.id, o.status, o.total)
>    Pros: explicit, type-safe, no Spring requirement
>    Cons: verbose, class must have matching constructor
>
> 2. Spring Data JPA interface projection (closed):
>    interface OrderView { Long getId(); String getStatus(); }
>    Pros: minimal boilerplate, works with JPQL + native
>    Cons: read-only proxy, no modification
>
> 3. Spring Data JPA interface projection (open):
>    Supports @Value("#{target.firstName + ' ' + ...}")
>    Computed properties via SpEL
>    Cons: creates full entity as backing object (no
>    column reduction benefit)
>
> 4. Class-based projection (@Value):
>    Similar to interface but uses a class with @Value
>    for SpEL expressions
>
> Performance: Closed interface projections generate
>   SQL with only the needed columns. Open projections
>   load the full entity (no performance benefit).
>   Constructor expressions generate SQL with only
>   the constructor-specified columns.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about returning only
specific columns from JPA queries instead of full
entities."

**(2) First principles:** "Loading a full entity when
you only need 2 of 20 columns wastes memory and
bandwidth. Projections select only needed columns."

**(3) Bridge:** "DTO projections are like custom lenses:
instead of the full photograph (entity), you get a
cropped view with only what you need. Interface
projections are dynamic lenses - you define the shape,
Spring provides the view."

---

### 💻 Code Example

```java
// Method 1: JPQL Constructor Expression
public class OrderSummaryDto {
    private final Long id;
    private final String status;
    private final BigDecimal total;

    public OrderSummaryDto(Long id,
                           String status,
                           BigDecimal total) {
        this.id = id;
        this.status = status;
        this.total = total;
    }
    // getters...
}

List<OrderSummaryDto> results = em.createQuery(
    "SELECT NEW com.example.OrderSummaryDto("
    + "o.id, o.status, o.total) "
    + "FROM Order o WHERE o.status = :status",
    OrderSummaryDto.class)
    .setParameter("status", "PAID")
    .getResultList();
// SQL: SELECT o.id, o.status, o.total
//      FROM orders WHERE status='PAID'
// No SELECT *, no mapping to entity

// Method 2: Interface Projection (Spring Data)
public interface OrderSummary {
    Long getId();
    String getStatus();
    BigDecimal getTotal();

    // Computed property (open projection)
    @Value("#{target.total * 0.1}")
    BigDecimal getTax();
    // Warning: open projection loads full entity!
}

public interface OrderRepository
        extends JpaRepository<Order, Long> {
    List<OrderSummary> findByStatus(String status);
    // Spring Data generates: SELECT id, status, total
    // FROM orders WHERE status=?
    // Maps results to proxy implementing OrderSummary
}
```

> **Code walkthrough:** Constructor expression generates
> SQL that selects ONLY the 3 constructor columns
> (id, status, total) - no full entity load. Interface
> projection (closed, without @Value) also generates
> SQL with only the getter-defined columns. The @Value
> computed property makes it an "open projection" which
> loads the full entity as a backing object (losing the
> column reduction benefit) - use sparingly. Interface
> projections are dynamic proxies implementing the
> interface, reading values from query results.

---

### ⚖️ Comparison Table

| Projection Type | SQL columns | Mutable | SpEL | Spring Data |
|---|---|---|---|---|
| Constructor expression | Only constructor params | No | No | No (JPQL) |
| Closed interface projection | Only getter columns | No | No | Yes |
| Open interface (@Value) | Full entity | No | Yes | Yes |
| Class-based projection | Only needed | Via @Value | Yes | Yes |
| Entity (no projection) | All columns | Yes | No | Yes |

---

### 🎓 Answers by Seniority

**Junior:** "Interface projections return only the
columns defined in the interface, instead of the full
entity. I define an interface with getters, and Spring
Data JPA generates the query automatically."

**Senior:** "Closed interface projections for read-
only views (SELECT only needed columns), constructor
expressions for immutable DTOs, entities only when
I need to modify and save. Open projections are a trap:
they load the full entity, defeating the purpose.
For reports with aggregations, native SQL with interface
projections is the most efficient."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Interface projection, constructor expression |
| Senior | 6 min | Open vs closed projection, column reduction |

---

**[SENIOR] Q1 - When does a Spring Data JPA interface
projection NOT reduce the SQL columns selected?**

*Why they ask:* Open vs closed projection distinction
is a common misconception.

Open projection: Any projection interface method
annotated with @Value("#{target.field}") makes it an
"open projection." Spring Data loads the FULL entity
as the backing target, then applies SpEL. No column
reduction.

This is counter-intuitive: adding @Value to an interface
that looks like a DTO actually causes MORE data to
be loaded, not less.

Diagnostic: Enable SQL logging. If you see SELECT *
for a projection query, it's an open projection.

Fix: Remove @Value from the interface if column reduction
is needed. Compute derived values in the service layer
or use a class-based DTO instead.

Rule: if any method in the interface has @Value, ALL
methods load the full entity.

*What separates good from great:* Knowing that a single
@Value makes the whole interface an open projection
(loads full entity).

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Interface vs constructor projections, column reduction. |
| Hiring Manager | Projections = faster queries, less data transfer. |
| Bar Raiser | Open vs closed projection, @Value trap, native SQL projections. |
| Peer Engineer | "I once 'optimized' a query by adding a projection interface, then measured the same SQL as before. One @Value was the culprit." |
