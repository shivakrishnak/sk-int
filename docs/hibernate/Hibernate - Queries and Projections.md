---
layout: default
title: "Hibernate - Queries and Projections"
parent: "Hibernate"
grand_parent: "Interview Mastery"
nav_order: 6
permalink: /interview/hibernate/queries-and-projections/
topic: Hibernate
subtopic: Queries and Projections
keywords:
  - Spring Data Derived Queries
  - Criteria API
  - DTO Projections
  - Native Queries and ResultSet Mapping
  - Pagination and Sorting
difficulty_range: medium to hard
status: complete
version: 3
---

**Keywords covered in this file:**

- [Spring Data Derived Queries](#spring-data-derived-queries)
- [Criteria API](#criteria-api)
- [DTO Projections](#dto-projections)
- [Native Queries and ResultSet Mapping](#native-queries-and-resultset-mapping)
- [Pagination and Sorting](#pagination-and-sorting)

# Spring Data Derived Queries

**TL;DR** - Spring Data JPA generates JPQL from method names (`findByStatusAndAgeGreaterThan`) - eliminating boilerplate query code for simple lookups while supporting pagination, sorting, and custom return types, but becoming unreadable for complex conditions (use `@Query` instead).

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every simple query requires writing JPQL or SQL, creating a method, and mapping parameters. Finding users by email: 5 lines of boilerplate. Finding by status and age: 8 lines. 80% of repository queries are simple property lookups that follow predictable patterns.

---

### 📘 Textbook Definition

Spring Data derived queries parse repository method names into JPQL at application startup. The method name is split into subject (`findBy`, `countBy`, `deleteBy`), property expressions (`Status`, `AgeGreaterThan`), and connectors (`And`, `Or`). Spring Data validates the method name against the entity model and generates the query implementation automatically. If the method name does not match entity properties, startup fails with a clear error.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Name the method `findByEmail` and Spring Data writes the query for you.

**One insight:**
Derived queries are validated at startup. If you rename an entity field and forget to update the method name, the application fails to start (not at runtime). This is safer than string-based JPQL.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
public interface UserRepository
    extends JpaRepository<User, Long> {

    // Simple property
    List<User> findByEmail(String email);
    // -> WHERE u.email = ?1

    // Multiple conditions
    List<User> findByStatusAndAgeGreaterThan(
        String status, int age);
    // -> WHERE u.status = ?1
    //    AND u.age > ?2

    // Ordering
    List<User> findByStatusOrderByNameAsc(
        String status);

    // Limiting
    List<User> findTop10ByStatus(
        String status);

    // Existence
    boolean existsByEmail(String email);

    // Counting
    long countByStatus(String status);

    // Deletion
    void deleteByStatus(String status);
}
```

**Level 3 - Advanced features (mid-level):**

Property traversal:

```java
// Navigate relationships
List<Order> findByUserEmail(
    String email);
// -> JOIN o.user u WHERE u.email = ?1

// Ambiguity: user_email field
// vs user.email navigation?
// Underscore separates: findByUser_Email
// means user.email (explicit)
```

Pagination and return types:

```java
// Page (with total count)
Page<User> findByStatus(
    String status, Pageable pageable);

// Slice (no count query)
Slice<User> findByStatus(
    String status, Pageable pageable);

// Stream (cursor-based)
@QueryHints(
    @QueryHint(
        name = HINT_FETCH_SIZE,
        value = "50"))
Stream<User> findByStatus(
    String status);
// Must be used in @Transactional
// Close the stream!
```

**Level 4 - Mastery (senior/staff+):**

When to switch to @Query:

```java
// Derived query readability limit:
List<User>
  findByStatusAndAgeGreaterThanAndEmailContainingAndDepartmentNameOrderByCreatedAtDesc(
    String s, int a, String e, String d);
// Unreadable! Switch to @Query:

@Query("SELECT u FROM User u "
    + "JOIN u.department d "
    + "WHERE u.status = :status "
    + "AND u.age > :age "
    + "AND u.email LIKE %:email% "
    + "AND d.name = :dept "
    + "ORDER BY u.createdAt DESC")
List<User> findFiltered(
    @Param("status") String status,
    @Param("age") int age,
    @Param("email") String email,
    @Param("dept") String dept);
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `findBy` methods for everything."

**A Staff says:** "I use derived queries for simple 1-2 property lookups (validated at startup, zero boilerplate). I switch to `@Query` for 3+ conditions (readability). I use `Slice` instead of `Page` when total count is not needed (avoids extra COUNT query). I use `Stream` for large result sets to avoid loading all into memory."

---

### 💻 Code Example

**BAD over-long derived query vs GOOD @Query:**

```java
// BAD - unreadable method name
List<User>
    findByStatusAndRoleAndDeptName(
    String s, String r, String d);
// Already at readability limit

// GOOD - explicit @Query
@Query("SELECT u FROM User u "
    + "WHERE u.status = :status "
    + "AND u.role = :role "
    + "AND u.dept.name = :dept")
List<User> findFiltered(
    @Param("status") String status,
    @Param("role") String role,
    @Param("dept") String dept);
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Method-name-to-JPQL generation in Spring Data repositories.

**KEY INSIGHT:** Validated at startup (field rename = startup failure). Use for simple lookups only.

**ANTI-PATTERN:** 4+ property derived queries (unreadable). Page when Slice suffices.

**ONE-LINER:** "Simple lookups = derived query. Complex = @Query. 3+ conditions = switch."

**If you remember only 3 things:**

1. Method names are validated against entity model at startup
2. Switch to @Query for 3+ conditions (readability)
3. Slice avoids COUNT query; Stream for large results

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: How do Spring Data derived queries work?**

_Why they ask:_ Core Spring Data knowledge.
_Likely follow-up:_ "What happens if the field name is wrong?"

**Answer:**
Spring Data parses the method name at startup: `findByStatusAndAge` splits into `findBy` (subject), `Status` (property), `And` (connector), `Age` (property). It validates these against the entity model and generates JPQL.

If a field name is wrong (e.g., `findByState` when the field is `status`), the application fails to start with: `No property 'state' found for type 'User'`. This is safer than runtime JPQL string errors.

Supports: `GreaterThan`, `LessThan`, `Between`, `Like`, `In`, `OrderBy`, `Top/First`, `Distinct`, `Count`, `Exists`, `Delete`.

_What separates good from great:_ The startup validation safety and when to switch to @Query.

---

### 🔗 Related Keywords

**Prerequisites:** Spring Data JPA, JPQL

**Builds on:** Pagination, DTO Projections

**Related:** Querydsl, Specification pattern

---

---

# Criteria API

**TL;DR** - The JPA Criteria API builds type-safe, dynamic queries programmatically using `CriteriaBuilder`, `CriteriaQuery`, and `Predicate` objects - ideal for search screens with optional filters where JPQL string concatenation would be error-prone and vulnerable to injection.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
A search page with 8 optional filters. Using JPQL, you conditionally concatenate `WHERE` clauses: `if (name != null) jpql += "AND u.name = :name"`. Error-prone, hard to read, and risky for injection if you forget parameterization.

---

### 📘 Textbook Definition

The JPA Criteria API is a programmatic, type-safe query construction API. `CriteriaBuilder` creates query components (predicates, expressions, orders). `CriteriaQuery` defines the query structure (SELECT, FROM, WHERE, ORDER BY). `Root` represents the queried entity. `Predicate` represents WHERE conditions. Combined with JPA Metamodel (`User_` generated classes), queries are compile-time validated against entity fields.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Build queries in Java code instead of strings - type-safe, dynamic, and immune to typos.

**One insight:**
The Criteria API is verbose for simple queries (10 lines vs 1 line JPQL). Its value is in DYNAMIC queries with optional filters. For static queries, prefer JPQL or derived query methods.

---

### 📶 Gradual Depth

**Level 2 - Basic query (junior):**

```java
CriteriaBuilder cb =
    em.getCriteriaBuilder();
CriteriaQuery<User> cq =
    cb.createQuery(User.class);
Root<User> root = cq.from(User.class);

cq.select(root)
    .where(cb.equal(
        root.get("status"), "ACTIVE"));

List<User> users =
    em.createQuery(cq).getResultList();
```

**Level 3 - Dynamic filters (mid-level):**

```java
public List<User> search(
        UserFilter filter) {
    CriteriaBuilder cb =
        em.getCriteriaBuilder();
    CriteriaQuery<User> cq =
        cb.createQuery(User.class);
    Root<User> root =
        cq.from(User.class);

    List<Predicate> predicates =
        new ArrayList<>();

    if (filter.getName() != null) {
        predicates.add(cb.like(
            root.get("name"),
            "%" + filter.getName() + "%"));
    }
    if (filter.getStatus() != null) {
        predicates.add(cb.equal(
            root.get("status"),
            filter.getStatus()));
    }
    if (filter.getMinAge() != null) {
        predicates.add(
            cb.greaterThanOrEqualTo(
            root.get("age"),
            filter.getMinAge()));
    }

    cq.where(predicates.toArray(
        new Predicate[0]));
    cq.orderBy(cb.asc(root.get("name")));

    return em.createQuery(cq)
        .getResultList();
}
```

Spring Data Specification (cleaner):

```java
public interface UserRepository
    extends JpaRepository<User, Long>,
    JpaSpecificationExecutor<User> {}

// Usage:
Specification<User> spec =
    (root, query, cb) -> {
    List<Predicate> preds =
        new ArrayList<>();
    if (name != null)
        preds.add(cb.like(
            root.get("name"),
            "%" + name + "%"));
    if (status != null)
        preds.add(cb.equal(
            root.get("status"),
            status));
    return cb.and(
        preds.toArray(new Predicate[0]));
};

Page<User> results =
    userRepo.findAll(spec, pageable);
```

**Level 4 - Mastery (senior/staff+):**

Type-safe with JPA Metamodel:

```java
// Generated: User_.java
@StaticMetamodel(User.class)
public class User_ {
    public static volatile
        SingularAttribute<User, String>
        name;
    public static volatile
        SingularAttribute<User, String>
        status;
}

// Type-safe query:
cq.where(cb.equal(
    root.get(User_.status), "ACTIVE"));
// Compile error if field removed!
```

Composable specifications:

```java
public class UserSpecs {
    public static Specification<User>
            hasStatus(String status) {
        return (root, query, cb) ->
            cb.equal(
                root.get("status"),
                status);
    }

    public static Specification<User>
            nameLike(String name) {
        return (root, query, cb) ->
            cb.like(
                root.get("name"),
                "%" + name + "%");
    }
}

// Compose:
userRepo.findAll(
    hasStatus("ACTIVE")
    .and(nameLike("John")),
    pageable);
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use Criteria API for dynamic queries."

**A Staff says:** "I use Spring Data `Specification` (wraps Criteria API) for dynamic queries. I compose specifications from reusable building blocks. I use JPA Metamodel for compile-time safety. For simple queries, JPQL is cleaner. Criteria API's value is composability and type safety for search screens."

---

### 💻 Code Example

**BAD dynamic JPQL string vs GOOD Specification:**

```java
// BAD - string concatenation
public List<User> search(
        UserFilter f) {
    String jpql = "SELECT u FROM User u "
        + "WHERE 1=1 ";
    if (f.getName() != null)
        jpql += "AND u.name LIKE :name ";
    if (f.getStatus() != null)
        jpql += "AND u.status = :status ";
    // Error-prone, hard to test
    // No compile-time validation
}

// GOOD - composable Specification
Page<User> results = userRepo.findAll(
    hasStatus(f.getStatus())
    .and(nameLike(f.getName())),
    pageable);
// Type-safe, composable, testable
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Programmatic, type-safe query builder for JPA.

**KEY INSIGHT:** Criteria API is for dynamic queries. For static queries, use JPQL.

**ANTI-PATTERN:** Criteria API for simple static queries (verbose). Dynamic JPQL concatenation.

**ONE-LINER:** "Dynamic filters = Specification. Static queries = JPQL. Never concatenate JPQL."

**If you remember only 3 things:**

1. Spring Data Specification wraps Criteria API (cleaner)
2. Compose specifications for reusable filter building blocks
3. JPA Metamodel adds compile-time field validation

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: When would you use Criteria API over JPQL?**

_Why they ask:_ Query strategy decision.
_Likely follow-up:_ "What about Querydsl?"

**Answer:**
Criteria API for **dynamic** queries: search screens with optional filters. Building JPQL strings with conditional concatenation is error-prone.

JPQL for **static** queries: fixed structure, clear and readable.

In Spring Data, I use `JpaSpecificationExecutor` with composable `Specification` objects. Each specification is a reusable filter (e.g., `hasStatus`, `nameLike`) that composes with `.and()` and `.or()`.

Alternative: Querydsl provides a more fluent API (`QUser.user.status.eq("ACTIVE")`) but requires a build plugin.

_What separates good from great:_ The composable Specification pattern and Querydsl alternative.

---

### 🔗 Related Keywords

**Prerequisites:** JPQL, Spring Data JPA

**Builds on:** Search functionality, Dynamic Filtering

**Alternatives:** Querydsl, JOOQ

---

---

# DTO Projections

**TL;DR** - DTO projections select only needed columns (not full entities) from the database, avoiding persistence context overhead and lazy loading traps - using interface projections (`interface UserSummary { String getName(); }`), class projections (`SELECT NEW ...`), or Tuple results.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
A list page needs only name and email, but `findAll()` loads full entities with all 30 columns into the persistence context. Snapshots are created for dirty checking. Lazy associations risk N+1. Memory wasted, CPU wasted, all for two columns.

**THE BREAKING POINT:**
A dashboard loading 1000 users: 1000 entities x 30 columns x snapshots = massive memory. The page only displays name and email.

---

### 📘 Textbook Definition

DTO projections are query results that return only selected columns instead of full managed entities. They bypass the persistence context (no dirty checking, no snapshots, no lazy loading). Three approaches: (1) Interface-based projections (Spring Data generates proxy), (2) Class-based projections (`SELECT NEW dto.UserSummary(u.name, u.email)`), (3) Tuple projections (`Object[]` or `Tuple`). Spring Data supports projections as return types on repository methods.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Select only the columns you need; skip the persistence context entirely.

**One insight:**
Interface projections are the simplest in Spring Data but can cause N+1 if they include associations. Spring Data executes a full entity query and then extracts fields. Class-based projections with `SELECT NEW` in JPQL are true SQL-level projections (only selected columns queried).

---

### 📶 Gradual Depth

**Level 2 - Interface projections (junior):**

```java
// Define projection interface
public interface UserSummary {
    String getName();
    String getEmail();
}

// Use as return type
public interface UserRepository
    extends JpaRepository<User, Long> {
    List<UserSummary> findByStatus(
        String status);
}
// Spring Data generates proxy
// implementing UserSummary
// SQL: SELECT name, email FROM users
//   WHERE status = ?
```

**Level 3 - Class-based projections (mid-level):**

```java
// DTO class
public record UserSummary(
    String name, String email) {}

// JPQL constructor expression
@Query("SELECT NEW com.app.dto"
    + ".UserSummary(u.name, u.email) "
    + "FROM User u "
    + "WHERE u.status = :status")
List<UserSummary> findSummaries(
    @Param("status") String status);
// True SQL-level projection
// Only name, email columns queried
// No entity in persistence context
```

Comparison:

| Approach    | SQL-Level     | Context | Best For         |
| ----------- | ------------- | ------- | ---------------- |
| Interface   | Sometimes\*   | No      | Simple read      |
| Class (NEW) | Yes           | No      | Explicit columns |
| Tuple       | Yes           | No      | Ad-hoc queries   |
| Entity      | No (all cols) | Yes     | Write operations |

\*Interface projections may load full entity depending on Spring Data version and query type.

**Level 4 - Mastery (senior/staff+):**

Open vs closed projections:

```java
// Closed projection (SQL-optimized)
public interface UserSummary {
    String getName();  // Direct mapping
    String getEmail(); // Direct mapping
}
// SQL: SELECT name, email FROM users

// Open projection (loads full entity!)
public interface UserSummary {
    @Value("#{target.name + ' ' "
        + "+ target.email}")
    String getDisplayName();
}
// SQL: SELECT * FROM users
// SpEL requires full entity load!
```

Nested projections:

```java
public interface OrderSummary {
    String getStatus();
    UserSummary getUser(); // Nested

    interface UserSummary {
        String getName();
    }
}
// Loads Order + User
// But still lighter than full entities
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use projections for read-only queries."

**A Staff says:** "I use closed interface projections for simple reads (Spring optimizes SQL). I use class-based `SELECT NEW` for explicit column control. I avoid open projections (SpEL loads full entities). For dashboards and list pages, projections eliminate persistence context overhead entirely."

---

### 💻 Code Example

**BAD full entity for list view vs GOOD projection:**

```java
// BAD - full entity for list page
List<User> users =
    userRepo.findByStatus("ACTIVE");
// Loads ALL 30 columns per user
// All entities in persistence context
// Dirty checking runs at flush
// Only needed: name + email

// GOOD - projection for list page
List<UserSummary> users =
    userRepo.findByStatus("ACTIVE");
// Loads only name + email
// No persistence context overhead
// No dirty checking
// No lazy loading traps
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Query results returning only selected columns, skipping persistence context.

**KEY INSIGHT:** Closed interface projections optimize SQL. Open projections load full entities.

**ANTI-PATTERN:** Loading full entities for read-only list views. Open projections with SpEL.

**ONE-LINER:** "Read-only view? Use projection. Write operation? Use entity."

**If you remember only 3 things:**

1. Projections skip persistence context (no dirty checking, no snapshots)
2. Closed interface = SQL-optimized. Open interface (SpEL) = loads full entity
3. Use `SELECT NEW` for guaranteed SQL-level column selection

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: When and why would you use DTO projections?**

_Why they ask:_ Performance optimization.
_Likely follow-up:_ "What types of projections exist?"

**Answer:**
Use projections for read-only queries where you do not need all entity fields. Benefits: no persistence context overhead (no dirty checking, no snapshots), reduced network transfer (fewer columns), no lazy loading traps.

Types:

1. **Interface (closed):** Define getters matching entity fields. Spring generates proxy. SQL selects only those columns.
2. **Class-based (SELECT NEW):** Explicit constructor in JPQL. Guaranteed SQL-level projection.
3. **Tuple:** `Object[]` results for ad-hoc queries.

Avoid: open projections with `@Value`/SpEL (loads full entity despite looking like a projection).

Rule: read-only views (lists, dashboards) = projections. Write operations = entities.

_What separates good from great:_ The open vs closed distinction and when each is truly SQL-optimized.

---

### 🔗 Related Keywords

**Prerequisites:** JPQL, Spring Data JPA

**Builds on:** Performance Optimization, API Design

**Related:** GraphQL projections, JOOQ type-safe columns

---

---

# Native Queries and ResultSet Mapping

**TL;DR** - Native queries execute raw SQL via `@Query(nativeQuery = true)` or `em.createNativeQuery()` for database-specific features (window functions, CTEs, full-text search) that JPQL cannot express - with results mapped via `@SqlResultSetMapping`, constructor result mapping, or manual `Object[]` extraction.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
JPQL lacks window functions (`ROW_NUMBER()`, `RANK()`), CTEs (`WITH RECURSIVE`), full-text search (`tsvector`), JSON operators (`->>`), and database-specific hints. For these features, you need raw SQL.

---

### 📘 Textbook Definition

Native queries execute raw SQL against the database, bypassing JPQL's entity-oriented query model. In JPA, they are created via `em.createNativeQuery(sql)` or `@Query(value = "...", nativeQuery = true)`. Results can be mapped to entities (if the query returns all entity columns), DTOs (via `@SqlResultSetMapping` or `@ConstructorResult`), or raw `Object[]` arrays. Native queries are database-specific and not portable.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
When JPQL cannot do it, use native SQL - but map results carefully and accept database lock-in.

**One insight:**
Native queries that return entity columns populate managed entities in the persistence context (tracked for changes). If you do not need managed entities, use DTO result mapping or `Object[]` to avoid context overhead.

---

### 📶 Gradual Depth

**Level 2 - Basic native query (junior):**

```java
// Spring Data
@Query(value =
    "SELECT * FROM users "
    + "WHERE email = :email",
    nativeQuery = true)
User findByEmailNative(
    @Param("email") String email);

// EntityManager
List<Object[]> results =
    em.createNativeQuery(
    "SELECT name, COUNT(*) "
    + "FROM users "
    + "GROUP BY name")
    .getResultList();

for (Object[] row : results) {
    String name = (String) row[0];
    Long count = ((Number) row[1])
        .longValue();
}
```

**Level 3 - Result mapping (mid-level):**

```java
// @SqlResultSetMapping
@Entity
@SqlResultSetMapping(
    name = "UserSummaryMapping",
    classes = @ConstructorResult(
        targetClass = UserSummary.class,
        columns = {
            @ColumnResult(
                name = "name",
                type = String.class),
            @ColumnResult(
                name = "total_orders",
                type = Long.class)
        }))
public class User { }

// Usage:
List<UserSummary> results =
    em.createNativeQuery(
    "SELECT u.name, COUNT(o.id) "
    + "AS total_orders "
    + "FROM users u "
    + "LEFT JOIN orders o "
    + "ON o.user_id = u.id "
    + "GROUP BY u.name",
    "UserSummaryMapping")
    .getResultList();
```

**Level 4 - Mastery (senior/staff+):**

Database-specific features:

```java
// PostgreSQL full-text search
@Query(value =
    "SELECT * FROM articles "
    + "WHERE to_tsvector('english', "
    + "title || ' ' || body) "
    + "@@ plainto_tsquery(:query)",
    nativeQuery = true)
List<Article> fullTextSearch(
    @Param("query") String query);

// Window function
@Query(value =
    "SELECT *, RANK() OVER "
    + "(PARTITION BY dept_id "
    + "ORDER BY salary DESC) AS rnk "
    + "FROM employees",
    nativeQuery = true)
List<Object[]> employeeRanking();
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use native queries when JPQL is insufficient."

**A Staff says:** "I use native queries for: window functions, CTEs, full-text search, JSON operators, database-specific optimizations. I map results to DTOs (not entities) when I do not need change tracking. I document database portability implications. I parameterize all inputs to prevent SQL injection."

---

### 💻 Code Example

**BAD unsafe concatenation vs GOOD parameterized:**

```java
// BAD - SQL injection risk!
@Query(value =
    "SELECT * FROM users "
    + "WHERE name = '" + name + "'",
    nativeQuery = true)
// NEVER concatenate user input!

// GOOD - parameterized
@Query(value =
    "SELECT * FROM users "
    + "WHERE name = :name",
    nativeQuery = true)
List<User> findByName(
    @Param("name") String name);
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Raw SQL execution bypassing JPQL for database-specific features.

**KEY INSIGHT:** Results can be managed entities (tracked) or DTOs (not tracked). Choose wisely.

**ANTI-PATTERN:** String concatenation (injection). Native query for portable queries (use JPQL).

**ONE-LINER:** "JPQL cannot do it? Native SQL. Always parameterize. Map to DTO."

**If you remember only 3 things:**

1. Use for: window functions, CTEs, full-text search, JSON ops
2. Always parameterize (:param) - never concatenate
3. Map to DTO when you do not need change tracking

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: When would you use a native query instead of JPQL?**

_Why they ask:_ Query strategy decision.
_Likely follow-up:_ "How do you map results?"

**Answer:**
Native SQL when JPQL cannot express the query: window functions (RANK, ROW_NUMBER), CTEs (WITH RECURSIVE), full-text search (tsvector), JSON operators (->>, @>), database-specific hints (FORCE INDEX), and complex aggregations.

Result mapping: `@SqlResultSetMapping` + `@ConstructorResult` for DTOs, entity class for managed entities, `Object[]` for ad-hoc.

Trade-offs: no database portability, no compile-time validation, persistence context behavior differs (entity results are managed; DTO results are not).

Always parameterize inputs (`:param`) to prevent SQL injection.

_What separates good from great:_ Specific examples of when JPQL is insufficient and result mapping options.

---

### 🔗 Related Keywords

**Prerequisites:** SQL, JPQL

**Builds on:** Database-Specific Features, Full-Text Search

**Alternatives:** JOOQ (type-safe SQL), Querydsl

---

---

# Pagination and Sorting

**TL;DR** - Spring Data JPA's `Pageable` parameter enables SQL-level pagination (`LIMIT/OFFSET`) and sorting via `PageRequest.of(page, size, Sort)` - returning `Page` (with total count), `Slice` (without count), or `List` results, with performance implications for each choice.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Loading 100K users to display 20 per page. Without pagination: `SELECT * FROM users` returns all rows, Java filters to page 5. Memory: 100K objects. Response time: 10 seconds. With pagination: `SELECT * FROM users LIMIT 20 OFFSET 80`. Memory: 20 objects. Response time: 10ms.

---

### 📘 Textbook Definition

Spring Data pagination uses `Pageable` to pass page number, page size, and sort direction to repository methods. The framework generates SQL with `LIMIT/OFFSET` (or database equivalent). Return types: `Page<T>` (includes total element count via additional COUNT query), `Slice<T>` (no count query, knows if next page exists), `List<T>` (no pagination metadata). `Sort` specifies ordering by entity properties.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
`PageRequest.of(0, 20, Sort.by("name"))` -> SQL adds `LIMIT 20 OFFSET 0 ORDER BY name`.

**One insight:**
`Page` executes TWO queries: the data query + `SELECT COUNT(*)`. For large tables, the COUNT query can be expensive. Use `Slice` when you only need "has next page?" (infinite scroll pattern). Use keyset pagination for deep pages.

---

### 📶 Gradual Depth

**Level 2 - Basic usage (junior):**

```java
// Controller
@GetMapping("/users")
Page<User> getUsers(
    @RequestParam(defaultValue = "0")
        int page,
    @RequestParam(defaultValue = "20")
        int size) {
    Pageable pageable =
        PageRequest.of(page, size,
            Sort.by("name").ascending());
    return userRepo.findAll(pageable);
}

// Response includes:
// content: [...20 users...]
// totalElements: 1000
// totalPages: 50
// number: 0 (current page)
// size: 20
```

**Level 3 - Page vs Slice vs List (mid-level):**

| Return Type | COUNT Query | Metadata     | Use Case                |
| ----------- | ----------- | ------------ | ----------------------- |
| Page<T>     | Yes         | Total, pages | Table with page numbers |
| Slice<T>    | No          | hasNext only | Infinite scroll         |
| List<T>     | No          | None         | Simple limit            |

```java
// Slice - no COUNT query
Slice<User> findByStatus(
    String status, Pageable pageable);
// SQL: SELECT ... LIMIT 21 OFFSET 0
// Fetches size+1 to determine hasNext
// No SELECT COUNT(*) -> faster

// Deep page problem:
// OFFSET 100000 LIMIT 20
// DB must scan and skip 100K rows!
// Solution: keyset pagination
```

**Level 4 - Mastery (senior/staff+):**

Keyset pagination (cursor-based):

```java
// Instead of OFFSET (O(N) skip):
@Query("SELECT u FROM User u "
    + "WHERE u.id > :lastId "
    + "ORDER BY u.id ASC")
List<User> findNextPage(
    @Param("lastId") Long lastId,
    Pageable pageable);
// O(1) - seeks directly to lastId
// No skipping rows
// Works at any depth
```

Pagination with JOIN FETCH (warning):

```java
// BAD - pagination in memory!
@Query("SELECT o FROM Order o "
    + "JOIN FETCH o.items")
Page<Order> findAll(Pageable p);
// HHH90003004: applying in memory!
// Loads ALL rows, pages in Java!

// GOOD - two-query approach
@Query("SELECT o.id FROM Order o")
Page<Long> findIds(Pageable p);
// Then batch-load with JOIN FETCH:
@Query("SELECT o FROM Order o "
    + "JOIN FETCH o.items "
    + "WHERE o.id IN :ids")
List<Order> findByIds(
    @Param("ids") List<Long> ids);
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `Page` with `PageRequest`."

**A Staff says:** "I use `Slice` for infinite scroll (no COUNT). I use keyset pagination for deep pages (O(1) vs O(N) OFFSET). I never combine JOIN FETCH with Page (pagination in memory). For paginated collections, I use the two-query approach: page IDs first, then batch-load with JOIN FETCH."

---

### 💻 Code Example

**BAD deep OFFSET vs GOOD keyset:**

```java
// BAD - deep page OFFSET
PageRequest.of(5000, 20);
// OFFSET 100000 LIMIT 20
// DB scans 100K rows to skip them!

// GOOD - keyset pagination
@Query("SELECT u FROM User u "
    + "WHERE u.id > :cursor "
    + "ORDER BY u.id")
Slice<User> findAfter(
    @Param("cursor") Long cursor,
    Pageable pageable);
// Seeks directly to cursor position
// O(1) regardless of page depth
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** SQL-level pagination with LIMIT/OFFSET and total count metadata.

**KEY INSIGHT:** Page = COUNT query. Slice = no COUNT. Keyset = O(1) deep pages.

**ANTI-PATTERN:** Page for infinite scroll (unnecessary COUNT). JOIN FETCH + Page (in-memory).

**ONE-LINER:** "Table pagination = Page. Infinite scroll = Slice. Deep pages = keyset."

**If you remember only 3 things:**

1. Page runs COUNT query; Slice does not (use Slice for infinite scroll)
2. Keyset pagination for deep pages (OFFSET scales poorly)
3. Never combine JOIN FETCH with Page (pages in memory, not SQL)

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: Page vs Slice - when to use each?**

_Why they ask:_ Performance trade-off.
_Likely follow-up:_ "What about deep pagination?"

**Answer:**
`Page` executes two queries: data + COUNT. Returns total elements, total pages. Use for: table UIs with page numbers ("Page 3 of 50").

`Slice` executes one query (fetches size+1 to check hasNext). No COUNT. Use for: infinite scroll, "load more" patterns where total count is unnecessary.

For large tables, COUNT can take seconds. If the UI does not need total count, Slice is always better.

Deep pagination (page 5000): both Page and Slice use OFFSET, which requires the DB to scan and skip rows. Solution: keyset pagination (`WHERE id > :lastSeenId ORDER BY id`) - seeks directly, O(1) regardless of depth.

_What separates good from great:_ The size+1 trick for hasNext and keyset pagination for deep pages.

---

### 🔗 Related Keywords

**Prerequisites:** SQL LIMIT/OFFSET, Spring Data JPA

**Builds on:** API Design, Performance Optimization

**Related:** Cursor-based pagination (GraphQL), Elasticsearch scroll
