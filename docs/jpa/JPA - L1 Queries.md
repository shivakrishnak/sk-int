---
layout: default
title: "JPA - L1 Queries"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 3
permalink: /jpa/l1-queries/
---

# JPA - L1 Queries

## JPQL Fundamentals: Entity Queries and Named Queries

### 🎯 Model Answer

**30 seconds:**
> JPQL (Jakarta Persistence Query Language): SQL-like language that operates on entities and their
> fields, not table and column names. Translated by the JPA provider (Hibernate) into SQL for the
> target dialect. Supports `SELECT`, `WHERE`, `JOIN`, `GROUP BY`, `ORDER BY`, `UPDATE`, `DELETE`.
> `JOIN FETCH`: load related entities in one query (eliminates N+1).

**3 minutes (Senior):**
> JPQL vs SQL:
>
> 1. **Entity-centric**: JPQL references entity class names and field names, not table/column names.
>    `SELECT u FROM User u WHERE u.email = :email` - `User` is the class name, `email` is the field.
>    Hibernate translates to: `SELECT u.id, u.email, u.name FROM users u WHERE u.email = ?`.
>
> 2. **JOIN FETCH**: eager-load an association in the same query. Without `JOIN FETCH`: loading
>    10 users, then accessing each user's orders = 11 queries (N+1). With `JOIN FETCH`: one query
>    with a JOIN. Only valid for collection associations that will be accessed. Eagerly fetching
>    associations that won't be accessed: wastes bandwidth.
>
> 3. **Named queries**: pre-compiled JPQL queries defined at class level. Validated at startup
>    (fail-fast for JPQL syntax errors). Slightly faster than ad-hoc queries (compiled once).
>    Spring Data `@Query`: more convenient, but not named queries (compiled per-call, not cached).
>
> 4. **JPQL limitations**: no `INSERT`, no `MERGE UPSERT`, no window functions, no recursive CTEs.
>    For these: native SQL query (`nativeQuery = true`) or JDBC directly.

**Blank Mind Recovery:**

**(1) Restate:** "JPQL: SQL over entities (not tables). Field names, not column names. JOIN FETCH: avoids N+1 by loading association in same query. Named queries: pre-compiled, validated at startup. Limitations: no INSERT/UPSERT/window functions -> use native SQL."

**(2) First principles:** "A query language must be abstract enough to work with any SQL dialect (MySQL, PostgreSQL, Oracle). JPQL: entity-centric abstraction. Hibernate maps entity/field names to table/column names and adds dialect-specific SQL. Result: portable queries without rewriting per DB."

**(3) Bridge:** "JPQL is like asking for 'the customer's orders' in English. Hibernate translates this to SQL for your specific database (the French/German/Spanish equivalent). You speak entities; Hibernate speaks SQL dialects."

---

### 📘 Concept Explanation

**JPQL syntax and patterns:**
```
BASIC JPQL SYNTAX:

  Alias is required in JPQL (unlike SQL WHERE without FROM alias):
  
  // SELECT:
  SELECT u FROM User u WHERE u.active = true
  SELECT u.name, u.email FROM User u  // field projection (no entity returned)
  SELECT DISTINCT o.status FROM Order o
  
  // Parameters:
  // Named parameters (preferred):
  SELECT u FROM User u WHERE u.email = :email
  // Positional parameters:
  SELECT u FROM User u WHERE u.email = ?1
  
  // JOIN:
  SELECT u FROM User u JOIN u.address a WHERE a.city = :city
  // Implicit join (via dot notation):
  SELECT u FROM User u WHERE u.address.city = :city
  // Both generate: INNER JOIN addresses a ON a.id = u.address_id WHERE a.city = ?
  
  // LEFT JOIN:
  SELECT u FROM User u LEFT JOIN u.orders o WHERE o IS NULL
  // Returns users with no orders.
  
  // JOIN FETCH (eager load for this query only):
  SELECT u FROM User u LEFT JOIN FETCH u.orders
  WHERE u.id IN :ids
  // One SQL with a JOIN: loads users and their orders in a single query.
  // Without JOIN FETCH: N queries (one per user's orders).

JPQL AGGREGATE FUNCTIONS:

  SELECT COUNT(u) FROM User u WHERE u.active = true
  SELECT AVG(o.totalAmount) FROM Order o WHERE o.status = 'CONFIRMED'
  SELECT MAX(p.price), MIN(p.price) FROM Product p WHERE p.category = :cat
  
  // GROUP BY:
  SELECT u.status, COUNT(u) FROM User u GROUP BY u.status
  // Returns: Object[] {status, count}
  
  // GROUP BY with HAVING:
  SELECT c, COUNT(o) FROM Customer c JOIN c.orders o
  GROUP BY c HAVING COUNT(o) > 5
  // Returns customers with more than 5 orders.

JPQL UPDATE AND DELETE:

  // Bulk UPDATE (does NOT trigger dirty checking or lifecycle callbacks):
  @Modifying
  @Query("UPDATE User u SET u.active = false WHERE u.lastLoginAt < :cutoff")
  int deactivateInactiveUsers(@Param("cutoff") Instant cutoff);
  
  // Bulk DELETE:
  @Modifying
  @Query("DELETE FROM OrderItem oi WHERE oi.order.id = :orderId")
  int deleteItemsByOrderId(@Param("orderId") Long orderId);
  
  // Important: bulk UPDATE/DELETE bypasses first-level cache.
  // After bulk update: cached entities still have old values.
  // Fix: @Modifying(clearAutomatically = true) -> clears persistence context after.

NAMED QUERIES:

  @Entity
  @NamedQuery(
      name = "User.findByEmail",
      query = "SELECT u FROM User u WHERE u.email = :email"
  )
  @NamedQuery(
      name = "User.findActiveWithOrders",
      query = "SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.orders " +
              "WHERE u.active = true"
  )
  public class User { ... }
  
  // Usage:
  TypedQuery<User> q = em.createNamedQuery("User.findByEmail", User.class);
  q.setParameter("email", email);
  User user = q.getSingleResult();
  
  // Named queries: validated at startup (ApplicationReadyEvent).
  // Bad JPQL: EntityManagerFactory creation fails with ParseException.
  // Advantage: fail fast vs runtime JPQL errors.
  
  // Spring Data: @NamedQuery on entity + method in repository (same name):
  Optional<User> findByEmail(String email);  // Spring looks for User.findByEmail
```

---

### 💻 Code Example

> **Code walkthrough:** The JOIN FETCH vs no JOIN FETCH comparison is the most important JPQL
> pattern to understand. The projection query shows how to avoid loading full entities when only
> a few fields are needed.

```java
// JPQL JOIN FETCH vs N+1:

// BAD: N+1 queries:
@Query("SELECT u FROM User u WHERE u.active = true")
List<User> findActiveUsers();

// When caller accesses orders:
List<User> users = userRepository.findActiveUsers();  // 1 query
for (User u : users) {
    System.out.println(u.getOrders().size());  // N queries (lazy load per user)
}
// Total: 1 + N queries (N = number of users).

// GOOD: JOIN FETCH (1 query):
@Query("SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.orders " +
       "WHERE u.active = true")
List<User> findActiveUsersWithOrders();

// 1 SQL query with JOIN:
// SELECT DISTINCT u.*, o.* FROM users u
// LEFT JOIN orders o ON o.user_id = u.id
// WHERE u.active = true
// All orders loaded. No additional queries.

// GOOD: DTO projection (when you only need a few fields):
// Never load full entities when only a summary is needed:
@Query("SELECT new com.example.UserSummary(u.id, u.name, COUNT(o)) " +
       "FROM User u LEFT JOIN u.orders o " +
       "WHERE u.active = true " +
       "GROUP BY u.id, u.name")
List<UserSummary> findActiveSummaries();

// Java DTO:
public class UserSummary {
    private final Long id;
    private final String name;
    private final long orderCount;
    
    public UserSummary(Long id, String name, long orderCount) {
        this.id = id;
        this.name = name;
        this.orderCount = orderCount;
    }
}
// Only 3 fields fetched from DB. No entity loading, no lazy collections.
```

> **Code walkthrough:** The N+1 version executes 1 query for users then N queries for orders (one
> per user). The `JOIN FETCH` version executes 1 SQL with a JOIN, loading all data at once.
> `DISTINCT` is needed because the JOIN multiplies rows (one row per order). The DTO projection
> is even better when only summary data is needed: it fetches only `id`, `name`, and `COUNT(orders)`
> without loading entity objects or any lazy associations.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> JPQL: entity field names, not column names. JOIN FETCH: prevents N+1. Named parameters: `:email`
> (not `?`). `@Modifying` for UPDATE/DELETE queries. DTO projection: `new ClassName(...)` in JPQL
> SELECT when you don't need the full entity.

---

**Senior / Staff (5+ years):**
> JPQL limitations are real: no UPSERT, no window functions, no recursive CTEs. Don't force these
> into JPQL via workarounds. Use native SQL. Named queries: useful for frequently-executed queries
> with startup validation. `@Modifying(clearAutomatically=true)`: mandatory for bulk UPDATE/DELETE
> to prevent stale first-level cache entries. DTO projections for read-only endpoints: eliminates
> entity state management overhead and reduces data transferred.

---

### ⚠️ Common Misconceptions

**Misconception: "JPQL JOIN FETCH can be used with pagination (`Pageable`)."**
Using `JOIN FETCH` with Spring Data's `Pageable` triggers a Hibernate warning: "HHH90003004:
firstResult/maxResults specified with collection fetch; applying in memory." Hibernate cannot apply
`LIMIT`/`OFFSET` to the JOIN result set (because the JOIN multiplies rows). Instead: Hibernate
loads ALL matching rows into memory, then paginates in Java memory. For large datasets: this causes
OOM errors. Fix: two-query approach: (1) paginated query for entity IDs, (2) JOIN FETCH query for
the IDs from step 1. Or: use `@BatchSize` on the collection instead of JOIN FETCH (compatible with
pagination).

---

### 🚨 Failure Modes and Diagnosis

**Failure: JPQL JOIN FETCH + Pageable causes OutOfMemoryError.**
```
Symptom: endpoint with @PageableDefault returns correctly but heap grows unboundedly.
  Eventually: OutOfMemoryError: GC overhead limit exceeded.
  
  Root cause: JOIN FETCH + Pageable.
  Hibernate log: HHH90003004: firstResult/maxResults specified with collection fetch.
  Hibernate loads ALL rows into memory (no DB LIMIT applied).
  Page 1: loads all 1M rows into heap, returns first 20.
  Page 2: same. All 1M rows every time.

Fix - two-query pagination:
  @Query(
      value = "SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.orders " +
              "WHERE u.active = true",
      countQuery = "SELECT COUNT(DISTINCT u) FROM User u WHERE u.active = true"
  )
  Page<User> findActiveWithOrders(Pageable pageable);
  // This STILL has the issue (JOIN FETCH with pageable = warning).
  
  // Real fix: separate the ID page from the entity load:
  @Query("SELECT u.id FROM User u WHERE u.active = true")
  Page<Long> findActiveUserIds(Pageable pageable);  // DB pagination (correct)
  
  @Query("SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.orders WHERE u.id IN :ids")
  List<User> findByIdsWithOrders(@Param("ids") List<Long> ids);
  
  // Service:
  Page<Long> idPage = userRepository.findActiveUserIds(pageable);  // correct pagination
  List<User> users = userRepository.findByIdsWithOrders(idPage.getContent());
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| JPQL vs SQL | 1 minute |
| JOIN FETCH purpose | 2 minutes |
| N+1 with JOIN FETCH | 2 minutes |
| JPQL limitations | 1 minute |
| Named queries | 1 minute |
| DTO projections | 1 minute |
| JOIN FETCH + Pageable problem | 1 minute |

---

**Q1 (jpql): What is JOIN FETCH and when should you use it?**

A: `JOIN FETCH` in JPQL: loads a related association (collection or single entity) in the same
SQL query as the parent entity. Without `JOIN FETCH`: if a User has a `@OneToMany List<Order> orders`
with lazy loading, accessing `user.getOrders()` for each of 100 users triggers 100 additional queries.
This is the N+1 problem. `JOIN FETCH`: `SELECT u FROM User u LEFT JOIN FETCH u.orders WHERE u.id IN :ids`
generates one SQL with a JOIN, loading all users and their orders in a single roundtrip. Use when:
the related collection will always be accessed in the same transaction. Don't use when: the collection
is rarely accessed (JOIN wastes bandwidth loading unneeded data) or when using pagination (causes in-memory
pagination, potential OOM).

*What separates good from great:* The "Cartesian product" risk with multiple JOIN FETCHes. Fetching
`User` with `JOIN FETCH u.orders JOIN FETCH u.addresses`: if a user has 10 orders and 3 addresses,
the SQL result has 30 rows (10 * 3). Hibernate de-duplicates these into one User with 10 orders and
3 addresses. But the network transfer is 30 rows. For 100 users with 100 orders and 100 addresses:
1 million rows transferred. This is the Cartesian product explosion. Fix: load one collection per query.
Query 1: users + orders (`JOIN FETCH u.orders`). Query 2: same users + addresses (`JOIN FETCH u.addresses`).
Hibernate's first-level cache: the users from Query 1 and Query 2 are the same Java instances, so
Hibernate merges the collections into the existing objects. Total: 2 queries, no Cartesian product.

---

---

## Criteria API Basics: Type-Safe Dynamic Queries

### 🎯 Model Answer

**30 seconds:**
> Criteria API: programmatic query construction via Java code (not string JPQL). Type-safe:
> compile-time checking of field names via metamodel. Useful for dynamic queries with variable
> conditions (search forms with optional filters). Downside: verbose and hard to read compared
> to JPQL. Use JPQL for static queries, Criteria API for dynamic multi-condition queries.

**3 minutes (Senior):**
> Criteria API usage:
>
> 1. **When to use**: queries where conditions are dynamically added at runtime. Example: a search
>    form with 10 optional fields. With JPQL: you'd need 2^10 query variants or dynamic string
>    concatenation (unsafe). With Criteria API: build the predicate list dynamically and combine.
>
> 2. **JPA Metamodel**: static classes generated by the JPA annotation processor that represent
>    entity attributes as type-safe `Attribute` objects. `User_` (generated) has `User_.email`
>    (a `SingularAttribute<User, String>`) instead of the string `"email"`. If `User.email` is
>    renamed: `User_.email` causes a compile error. Plain JPQL string `"u.email"`: no compile error.
>
> 3. **Specifications (Spring Data)**: Spring Data JPA's `Specification<T>` wraps a Criteria
>    predicate. Composable: `spec1.and(spec2)`, `spec1.or(spec2)`. Repository extends
>    `JpaSpecificationExecutor<T>`. More readable than raw Criteria API.
>
> 4. **Alternatives**: QueryDSL, JOOQ. Both provide type-safe query construction with better
>    readability than the Criteria API. In practice: Specifications or QueryDSL are preferred over
>    raw Criteria API for complex dynamic queries.

**Blank Mind Recovery:**

**(1) Restate:** "Criteria API: programmatic, type-safe JPQL via Java code. Metamodel (User_): compile-time field names. Use for dynamic multi-condition queries. Verbose. Spring Specifications: wrapper around Criteria, composable."

**(2) First principles:** "Dynamic SQL is hard with string concatenation (SQL injection risk, type errors). Programmatic API: build the query as a tree of conditions, each condition type-safe. The API is verbose but eliminates string manipulation."

**(3) Bridge:** "Criteria API is like building a sentence with Lego bricks (typed, snap-fit pieces) instead of writing the sentence by hand. More setup, but can't create an ungrammatical sentence (wrong field name, type mismatch)."

---

### 📘 Concept Explanation

**Criteria API and Specifications:**
```
RAW CRITERIA API:

  // Find products by optional category, min price, max price:
  public List<Product> search(String category, BigDecimal minPrice,
                               BigDecimal maxPrice) {
      CriteriaBuilder cb = em.getCriteriaBuilder();
      CriteriaQuery<Product> cq = cb.createQuery(Product.class);
      Root<Product> root = cq.from(Product.class);
      
      List<Predicate> predicates = new ArrayList<>();
      
      if (category != null) {
          predicates.add(cb.equal(root.get("category"), category));
          // Type-safe with metamodel: root.get(Product_.category)
      }
      if (minPrice != null) {
          predicates.add(cb.greaterThanOrEqualTo(
              root.get("price"), minPrice));
      }
      if (maxPrice != null) {
          predicates.add(cb.lessThanOrEqualTo(
              root.get("price"), maxPrice));
      }
      
      cq.where(predicates.toArray(new Predicate[0]));
      cq.orderBy(cb.asc(root.get("name")));
      
      return em.createQuery(cq).getResultList();
  }

SPRING DATA SPECIFICATIONS (preferred over raw Criteria API):

  // Specification: a reusable predicate builder:
  public class ProductSpecifications {
      
      public static Specification<Product> hasCategory(String category) {
          return (root, query, cb) -> 
              category == null ? cb.conjunction()  // always-true (ignore this filter)
                               : cb.equal(root.get("category"), category);
      }
      
      public static Specification<Product> priceBetween(BigDecimal min,
                                                         BigDecimal max) {
          return (root, query, cb) -> {
              List<Predicate> p = new ArrayList<>();
              if (min != null) p.add(cb.greaterThanOrEqualTo(root.get("price"), min));
              if (max != null) p.add(cb.lessThanOrEqualTo(root.get("price"), max));
              return cb.and(p.toArray(new Predicate[0]));
          };
      }
      
      public static Specification<Product> isActive() {
          return (root, query, cb) -> cb.isTrue(root.get("active"));
      }
  }
  
  // Repository:
  public interface ProductRepository extends JpaRepository<Product, Long>,
      JpaSpecificationExecutor<Product> {
  }
  
  // Usage: compose specs dynamically:
  public List<Product> search(SearchRequest req) {
      Specification<Product> spec = Specification
          .where(ProductSpecifications.isActive())
          .and(ProductSpecifications.hasCategory(req.getCategory()))
          .and(ProductSpecifications.priceBetween(req.getMinPrice(), req.getMaxPrice()));
      
      return productRepository.findAll(spec, Sort.by("name"));
      // Spring Data: compiles spec to Criteria predicates -> SQL WHERE clause.
  }
  
  // With pagination:
  Page<Product> productPage = productRepository.findAll(spec,
      PageRequest.of(0, 20, Sort.by("name")));

METAMODEL GENERATION:

  // pom.xml (for compile-time metamodel):
  <dependency>
      <groupId>org.hibernate.orm</groupId>
      <artifactId>hibernate-jpamodelgen</artifactId>
      <scope>provided</scope>
  </dependency>
  
  // Generated (in target/generated-sources):
  @StaticMetamodel(Product.class)
  public abstract class Product_ {
      public static volatile SingularAttribute<Product, Long> id;
      public static volatile SingularAttribute<Product, String> name;
      public static volatile SingularAttribute<Product, String> category;
      public static volatile SingularAttribute<Product, BigDecimal> price;
      public static volatile SingularAttribute<Product, Boolean> active;
  }
  
  // Type-safe usage:
  root.get(Product_.category)  // compile error if Product.category is removed
  // vs string-based:
  root.get("category")         // only fails at runtime
```

---

### 💻 Code Example

> **Code walkthrough:** The Specification pattern is the practical production alternative to raw
> Criteria API. Each specification is a reusable, testable unit of filter logic.

```java
// PRODUCT SEARCH WITH COMPOSABLE SPECIFICATIONS:

@Service
public class ProductSearchService {
    
    private final ProductRepository productRepository;
    
    // Search with any combination of optional filters:
    public Page<Product> search(ProductSearchRequest req, Pageable pageable) {
        
        // Build specification from non-null filters:
        Specification<Product> spec = buildSpec(req);
        
        return productRepository.findAll(spec, pageable);
        // Spring Data: converts to Criteria predicates -> SQL WHERE + pagination.
    }
    
    private Specification<Product> buildSpec(ProductSearchRequest req) {
        return Specification
            .where(isActive())
            .and(hasCategory(req.getCategory()))
            .and(priceBetween(req.getMinPrice(), req.getMaxPrice()))
            .and(nameContains(req.getNameQuery()));
    }
    
    // Each specification: returns conjunction() when filter is absent (no-op predicate):
    private Specification<Product> isActive() {
        return (root, q, cb) -> cb.isTrue(root.get("active"));
    }
    
    private Specification<Product> hasCategory(String category) {
        return (root, q, cb) -> category == null
            ? cb.conjunction()
            : cb.equal(root.get("category"), category);
    }
    
    private Specification<Product> priceBetween(BigDecimal min, BigDecimal max) {
        return (root, q, cb) -> {
            if (min == null && max == null) return cb.conjunction();
            List<Predicate> predicates = new ArrayList<>();
            if (min != null) predicates.add(
                cb.greaterThanOrEqualTo(root.get("price"), min));
            if (max != null) predicates.add(
                cb.lessThanOrEqualTo(root.get("price"), max));
            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
    
    private Specification<Product> nameContains(String query) {
        return (root, q, cb) -> query == null
            ? cb.conjunction()
            : cb.like(cb.lower(root.get("name")), "%" + query.toLowerCase() + "%");
    }
}
```

> **Code walkthrough:** Each specification is an independent lambda that takes `(root, query, cb)`
> and returns a `Predicate`. When the filter parameter is null: the specification returns
> `cb.conjunction()` (SQL equivalent: `1=1`, a no-op). The `Specification.where().and()` chain
> composes all predicates with AND. Spring Data JPA converts the composed specification to a
> Criteria query, then to SQL. The `nameContains` specification shows case-insensitive LIKE with
> `cb.lower()` and a pattern prefix/suffix.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Criteria API: programmatic query building for dynamic conditions. Spring Specifications: simpler
> alternative. Use `JpaSpecificationExecutor<T>` in your repository to accept Specifications.
> Compose with `.and()`, `.or()`, `.not()`. Static query: use JPQL `@Query`. Dynamic query:
> use Specifications.

---

**Senior / Staff (5+ years):**
> Specifications are sufficient for moderate complexity. For complex queries (subqueries, CTEs,
> window functions): use QueryDSL (better readability than Criteria API) or JOOQ (full SQL DSL
> with native SQL power + type safety). The metamodel (generated `Entity_` classes) adds a build
> step but eliminates all runtime field-not-found errors. Production recommendation: use
> Specifications for dynamic search, named JPQL for most other queries, native SQL for anything
> complex.

---

### ⚠️ Common Misconceptions

**Misconception: "Criteria API is type-safe by default."**
Criteria API with string-based `root.get("fieldName")` is NOT type-safe. `root.get("fieldName")`
is a String; if the field is renamed or doesn't exist: the error occurs at runtime (query execution),
not at compile time. The metamodel (JPA annotation processor generating `Entity_` classes) is what
provides compile-time type safety. Without the metamodel annotation processor configured in the build:
all Criteria API field references are strings, no more type-safe than JPQL strings. The metamodel
requires a build configuration step (`hibernate-jpamodelgen` as an annotation processor).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Specification produces SQL with a Cartesian product for join queries.**
```
Symptom: Specification that joins a related entity returns duplicate results.
  Expected: 100 products. Actual: 1500 results.

Root cause: Specification performs a JOIN but does not deduplicate.
  Specification joining Product with Tag:
    (root, query, cb) -> root.join("tags").get("name").in(tagNames);
  Product with 15 tags: appears 15 times in results.

Fix:
  Add DISTINCT to the query in the Specification:
    (root, query, cb) -> {
        query.distinct(true);  // adds DISTINCT to the SQL
        return root.join("tags").get("name").in(tagNames);
    }
  
  Or use a subquery:
    (root, query, cb) -> {
        Subquery<Long> sub = query.subquery(Long.class);
        Root<Tag> tag = sub.from(Tag.class);
        sub.select(tag.get("productId"))
           .where(tag.get("name").in(tagNames));
        return root.get("id").in(sub);
    }
  // Subquery: no JOIN on the outer query, no Cartesian product.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| When to use Criteria API | 1 minute |
| Spring Specifications | 2 minutes |
| Metamodel and type safety | 1 minute |
| Specification composition | 1 minute |
| Dynamic query patterns | 2 minutes |
| Criteria vs JPQL | 1 minute |
| Cartesian product in specs | 1 minute |

---

**Q1 (dynamic): When would you choose Criteria API/Specifications over JPQL?**

A: Use JPQL for static queries: queries where the structure is known at compile time (all conditions
always present). JPQL is readable, concise, and validated at startup if using named queries.
Use Criteria API/Specifications for dynamic queries: search forms with N optional filters, where
the SQL WHERE clause changes based on user input. With JPQL: you'd need dynamic string concatenation
(SQL injection risk) or 2^N query variants (combinatorial explosion). With Specifications: build
predicates conditionally and compose them. Example: a product search with category, price range,
name, active status, and tag filters (all optional): 5 optional fields = 32 possible JPQL variants.
With Specifications: 5 individual specs, composed dynamically. One code path handles all 32 cases.

*What separates good from great:* The "N+1 in Specifications" anti-pattern: a Specification that
calls `root.join("orders")` adds a JOIN to the query. If this Specification is OR'd with another
non-join spec: the JOIN may not be what you intended. Multiple Specifications with different JOINs:
may create a Cartesian product (users with 10 orders * 5 addresses = 50 rows per user). The fix:
`query.distinct(true)` in the Specification or using a subquery. This is a common source of
"wrong result count" bugs in Specification-based search: the developer adds a join for filtering
but doesn't account for the result set multiplication.

---

---

## Spring Data JPA: Repository and Query Method Derivation

### 🎯 Model Answer

**30 seconds:**
> Spring Data JPA: repository pattern implemented for JPA. `JpaRepository<T, ID>` provides CRUD
> methods (findById, save, delete, findAll with Pageable/Sort). Query derivation: method names
> like `findByEmailAndStatus` auto-generate JPQL. `@Query`: custom JPQL or native SQL. No
> implementation code required: Spring generates the implementation at runtime.

**3 minutes (Senior):**
> Spring Data JPA repository capabilities:
>
> 1. **JpaRepository hierarchy**: `JpaRepository` extends `PagingAndSortingRepository` extends
>    `CrudRepository`. Methods: `findById`, `findAll`, `save`, `saveAll`, `delete`, `count`,
>    `existsById`. `findAll(Pageable)`: paginated result with total count. `findAll(Sort)`: sorted.
>
> 2. **Query derivation rules**: `findBy`, `countBy`, `existsBy`, `deleteBy` as prefix.
>    Conditions: `FieldName` (equals), `FieldNameNot`, `FieldNameIn`, `FieldNameLike`,
>    `FieldNameContaining`, `FieldNameStartingWith`, `FieldNameBetween`, `FieldNameIsNull`.
>    Connectors: `And`, `Or`. Ordering: `OrderByFieldNameAsc/Desc`.
>
> 3. **@Query limitations**: JPQL `@Query` is validated at startup only with Hibernate's query
>    compilation. Native SQL `@Query(nativeQuery=true)`: NOT validated at startup (error at runtime).
>    Test native queries explicitly in integration tests.
>
> 4. **Transactionality**: repository methods: `findById`, `findAll` -> read-only transaction.
>    `save`, `delete` -> read-write transaction. `@Transactional(readOnly=true)` on `findAll`:
>    Hibernate skips dirty checking (performance). Override with `@Transactional` on calling method
>    to join an existing transaction.

**Blank Mind Recovery:**

**(1) Restate:** "JpaRepository: CRUD + pagination + sort. Query derivation: findByEmailAndStatus auto-generates JPQL. @Query: custom JPQL or native SQL. Pagination: findAll(Pageable) returns Page<T> with total count. @Transactional: read-only on finders (no dirty checking)."

**(2) First principles:** "A repository is a collection metaphor: add, find, remove entities as if from an in-memory collection. Spring Data generates the collection-management code from method signatures and annotations. No boilerplate code needed."

**(3) Bridge:** "Spring Data JPA is like a restaurant where you order by describing what you want: 'find me users by email.' The kitchen (Spring) figures out how to make it. You don't write the recipe (JPQL). Exception: complex orders need a recipe (@Query)."

---

### 📘 Concept Explanation

**Spring Data JPA capabilities:**
```
JPAREPOSITORY METHODS:

  // Spring Data auto-implements these:
  Optional<T> findById(ID id);
  List<T> findAll();
  List<T> findAll(Sort sort);
  Page<T> findAll(Pageable pageable);  // SQL: LIMIT + OFFSET + COUNT(*) query
  T save(T entity);                   // INSERT or UPDATE
  List<T> saveAll(Iterable<T> entities);
  void delete(T entity);
  void deleteById(ID id);
  long count();
  boolean existsById(ID id);

QUERY DERIVATION RULES:

  Method: findBy[Condition][And|Or][Condition][OrderBy[Field][Asc|Desc]]
  
  // Equality:
  findByEmail(String email)
  -> WHERE email = ?
  
  // Negation:
  findByEmailNot(String email)
  -> WHERE email != ?
  
  // In:
  findByStatusIn(List<Status> statuses)
  -> WHERE status IN (?)
  
  // Like/Contains:
  findByNameContaining(String term)  // %term%
  findByNameStartingWith(String prefix)  // prefix%
  findByNameEndingWith(String suffix)  // %suffix
  findByNameLike(String pattern)  // pattern (user provides % chars)
  findByNameContainingIgnoreCase(String term)  // case-insensitive
  
  // Null checks:
  findByEmailIsNull()  -> WHERE email IS NULL
  findByEmailIsNotNull() -> WHERE email IS NOT NULL
  
  // Boolean:
  findByActiveTrue()  -> WHERE active = true
  findByActiveFalse() -> WHERE active = false
  
  // Comparison:
  findByAgeBetween(int min, int max)  -> WHERE age BETWEEN ? AND ?
  findByAgeGreaterThan(int age)       -> WHERE age > ?
  findByAgeLessThanEqual(int age)     -> WHERE age <= ?
  
  // Ordering:
  findByActiveOrderByCreatedAtDesc()
  -> WHERE active = true ORDER BY created_at DESC
  
  // Combined:
  findByStatusAndAgeGreaterThanOrderByNameAsc(Status s, int age)
  -> WHERE status = ? AND age > ? ORDER BY name ASC
  
  // Count/exists:
  long countByStatus(Status s)
  boolean existsByEmail(String email)
  
  // Delete:
  @Transactional
  long deleteByStatus(Status s)

PAGINATION:

  // findAll(Pageable) returns Page<T>:
  Page<T> result = userRepository.findAll(
      PageRequest.of(0, 20, Sort.by(Sort.Direction.DESC, "createdAt")));
  
  result.getContent();    // List<T>: current page data
  result.getTotalElements(); // total matching rows (COUNT(*) query)
  result.getTotalPages(); // Math.ceil(total / pageSize)
  result.getNumber();     // current page number (0-based)
  result.hasNext();       // false on last page
  
  // Slice<T>: like Page but no COUNT(*) query (for infinite scroll):
  Slice<T> slice = userRepository.findByActive(true,
      PageRequest.of(0, 20));
  slice.hasNext();  // determined by "did we get pageSize results?"
  // Use Slice when total count is not needed (saves one COUNT(*) query).
  
  // Custom paginated query:
  @Query(value = "SELECT u FROM User u WHERE u.active = true",
         countQuery = "SELECT COUNT(u) FROM User u WHERE u.active = true")
  Page<User> findActive(Pageable pageable);
  // Separate countQuery: JPA knows what to count (needed for @Query with JOIN).
```

---

### 💻 Code Example

> **Code walkthrough:** The UserRepository shows the range of Spring Data JPA capabilities.
> The Slice vs Page distinction is a common interview topic.

```java
// COMPLETE SPRING DATA JPA REPOSITORY:

@Repository
public interface UserRepository extends JpaRepository<User, Long>,
    JpaSpecificationExecutor<User> {
    
    // Simple derivation:
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    
    // Complex derivation:
    List<User> findByActiveAndRoleIn(boolean active, List<Role> roles);
    
    // Paginated:
    Page<User> findByActive(boolean active, Pageable pageable);
    Slice<User> findByCreatedAtAfter(Instant since, Pageable pageable);
    
    // Custom JPQL:
    @Query("SELECT u FROM User u LEFT JOIN FETCH u.roles " +
           "WHERE u.id = :id")
    Optional<User> findByIdWithRoles(@Param("id") Long id);
    
    // DTO projection:
    @Query("SELECT new com.example.UserSummary(u.id, u.name, u.email) " +
           "FROM User u WHERE u.active = true")
    List<UserSummary> findAllActiveSummaries();
    
    // Modifying - bulk update:
    @Modifying(clearAutomatically = true)
    @Query("UPDATE User u SET u.active = false WHERE u.lastLoginAt < :cutoff")
    int deactivateInactiveUsers(@Param("cutoff") Instant cutoff);
    
    // Native SQL (for DB-specific queries):
    @Query(value = "SELECT * FROM users WHERE to_tsvector(name) @@ to_tsquery(:query)",
           nativeQuery = true)
    List<User> fullTextSearch(@Param("query") String query);
}

// SERVICE LAYER:
@Service
@Transactional
public class UserService {
    
    @Transactional(readOnly = true)
    public Page<User> getUsers(int page, int size) {
        return userRepository.findByActive(true,
            PageRequest.of(page, size, Sort.by("name")));
    }
    
    public User createUser(CreateUserRequest req) {
        if (userRepository.existsByEmail(req.getEmail())) {
            throw new DuplicateEmailException(req.getEmail());
        }
        return userRepository.save(new User(req.getName(), req.getEmail()));
    }
}
```

> **Code walkthrough:** The repository combines derived queries, custom JPQL, DTO projections,
> and native SQL in one interface. The `@Modifying(clearAutomatically=true)` on the bulk deactivation
> clears the persistence context after execution, preventing stale cached User instances that still
> show `active=true` after the bulk update. The `Slice<User>` for `findByCreatedAtAfter` avoids a
> COUNT query (useful for time-based feeds where total count is irrelevant).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Extend `JpaRepository<T, ID>` for CRUD. Derived queries cover simple cases. `@Query` for custom
> JPQL. `Pageable` for pagination. `Page<T>` has `getContent()`, `getTotalElements()`,
> `getTotalPages()`. Always use `findById().orElseThrow()` (not `getOne()`/`getReferenceById()` -
> those return proxies that throw on property access if not found).

---

**Senior / Staff (5+ years):**
> `Slice<T>` vs `Page<T>`: Slice skips the COUNT query (appropriate for infinite scroll, time-based
> feeds). `countQuery` parameter in `@Query`: required when the main query has JOINs (the auto-generated
> COUNT query from a JOIN-based query may return wrong counts). `@Modifying(clearAutomatically=true)`:
> mandatory for bulk updates to avoid stale cache. Native `@Query` not validated at startup: test
> in integration tests with the actual DB dialect.

---

### ⚠️ Common Misconceptions

**Misconception: "`save()` always triggers a DB INSERT."**
Spring Data JPA's `save()` checks `isNew()` on the entity to decide between INSERT and UPDATE. For
entities with `@GeneratedValue`: if `getId() == null` -> new entity -> INSERT. If `getId() != null`
-> existing entity -> `em.merge()` (load from DB + merge changes -> UPDATE). This means calling
`save()` on a detached entity with an existing ID: Hibernate executes a `SELECT` (to load the entity)
then an `UPDATE`. Two DB operations instead of one. For updates to managed entities (within a
transaction): don't call `save()` at all - dirty checking handles it. For detached entities: call
`save()` or implement `Persistable<ID>` to control the `isNew()` logic.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `save()` on existing entity generates an unexpected SELECT.**
```
Symptom: updating a user in a service method. SQL log shows:
  SELECT u.* FROM users WHERE id=1  (unexpected)
  UPDATE users SET name=? WHERE id=1

Root cause: em.merge() triggered by save() on detached entity.
  user = new User(existingId, "New Name");  // detached entity (not loaded from DB)
  userRepository.save(user);
  // save() -> getId() = existingId (not null) -> isNew() = false -> em.merge().
  // em.merge(): loads current DB state (SELECT), merges changes, generates UPDATE.

Fix option 1: use JPQL bulk update (no SELECT):
  @Modifying @Query("UPDATE User u SET u.name = :name WHERE u.id = :id")
  int updateName(@Param("id") Long id, @Param("name") String name);
  // Directly to DB. No SELECT. One operation.

Fix option 2: load, modify, commit (dirty checking, no extra SELECT needed):
  @Transactional
  public void updateName(Long id, String name) {
      User user = userRepository.findById(id).orElseThrow();  // 1 SELECT
      user.setName(name);  // dirty checking: UPDATE on commit
      // No save() needed.
  }
  // Total: 1 SELECT + 1 UPDATE. Same as the merge approach but clearer.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| JpaRepository basics | 1 minute |
| Query derivation | 2 minutes |
| Page vs Slice | 1 minute |
| @Query and countQuery | 1 minute |
| save() behavior | 2 minutes |
| @Modifying(clearAutomatically) | 1 minute |
| readOnly transaction optimization | 1 minute |

---

**Q1 (save): What does `save()` do in Spring Data JPA, and when should you NOT call it?**

A: `save()` calls `isNew()` on the entity. If `isNew() == true` (ID is null for `@GeneratedValue`
entities): calls `em.persist()` -> INSERT. If `isNew() == false` (ID already set): calls
`em.merge()` -> SELECT + UPDATE (loads current DB state, merges provided entity state, generates
UPDATE). When NOT to call `save()`: on managed entities within an active transaction. A managed
entity (loaded via `findById` within a `@Transactional` method) is already tracked by the persistence
context. Changes are automatically detected (dirty checking) and flushed at transaction commit.
Calling `save()` on a managed entity: either a no-op (if the entity is already managed) or triggers
a merge (more complex). The pattern: load entity -> mutate fields -> let the transaction commit
generate the UPDATE. No `save()` needed.

*What separates good from great:* The `Persistable<ID>` interface for controlling `isNew()`:
when entities use UUID or application-assigned IDs (not `@GeneratedValue`): `getId() != null` is
always true even for brand-new entities. Calling `save()` always triggers `em.merge()` (SELECT +
UPDATE attempt). Fix: implement `Persistable<UUID>` and maintain a `transient boolean isNew` flag.
Set it to true in the constructor. `isNew()` returns the flag. After persist/merge: flag is false
(via `@PostPersist`/`@PostLoad`). This gives the application full control over INSERT vs UPDATE
behavior regardless of the ID generation strategy.
