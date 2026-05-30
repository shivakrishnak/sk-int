---
layout: default
title: "Spring - L2 Data and Configuration"
parent: "Spring"
grand_parent: "SK Interview"
nav_order: 6
permalink: /spring/l2-data-and-configuration/
render_with_liquid: false
---

# Spring - L2 Data and Configuration

---

# Spring Data JPA Repository

---
id: SPR-014
title: Spring Data JPA Repository
category: Spring
difficulty: ★★☆
interview_weight: high
asked_at: All
seniority: mid
tags: #spring-data, #jpa, #repository, #query-methods
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High — Spring Data JPA is used in almost every Spring
Boot application with a database. Understanding repositories, query derivation,
and when to write JPQL is essential.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Data JPA provides repository interfaces that eliminate boilerplate
> CRUD code. You define an interface extending JpaRepository<Entity, ID>,
> and Spring generates the implementation at startup. You can derive queries
> from method names (findByEmailAndStatus), write JPQL with @Query, or use
> native SQL. Spring also manages transactions automatically for repository
> methods.

**3 minutes (Senior):**
> Spring Data JPA works through JDK dynamic proxies. At startup, the
> JpaRepositoryFactoryBean scans for repository interfaces, creates proxy
> implementations that delegate to JpaRepositoryImplementation, and registers
> them as beans. Method calls on derived query methods are parsed by Spring's
> PartTree parser at startup - the method name is tokenized into Subject
> (find/count/exists) + Predicate (ByEmailAndStatus).
>
> The generated query is a JPQL query that gets compiled by Hibernate. This
> means findByCustomerEmailAndStatusOrderByCreatedAtDesc generates valid JPQL
> at startup or fails early (not at runtime when the query is first executed).
>
> Performance considerations: eager fetching N+1 is the classic JPA problem.
> When a query returns Orders and you access order.getItems(), Hibernate
> executes one extra query per Order. Fix: @EntityGraph, JOIN FETCH in JPQL,
> or a DTO projection. DTO projections are the most performant - they avoid
> loading entities you don't need.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - discuss @QueryHints for pessimistic/optimistic locking,
custom repository implementations, and the Specification pattern for dynamic queries.

*Adapting down:* Junior - "JpaRepository gives you save, findById, findAll,
delete for free. You add methods by naming them correctly - findByEmail just works."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking how Spring Data JPA repositories work - how
you get CRUD for free without writing SQL."

**(2) First principles:** "Every application needs basic database operations.
Rather than writing them every time, Spring generates them from a standard
interface. The contract is in the interface; the implementation is generated."

**(3) Bridge:** "Think of JpaRepository as a universal CRUD contract - Spring
provides the SQL translator. You declare what you want; Spring figures out how."

---

### 📘 Concept Explanation

**What it is:**
Spring Data JPA repositories are interfaces that Spring implements automatically
at application startup. They provide data access operations (CRUD, pagination,
sorting, custom queries) without requiring you to write implementation code.

**The problem it solves:**
Every DAO (Data Access Object) in a traditional Spring application contained
identical save(), findById(), findAll(), delete() implementations with only
the entity type changing. Spring Data JPA eliminates this repetition by
generating the implementation from the interface contract.

**How it works:**

```
Spring Data JPA - Repository Architecture:

Your interface:
  public interface OrderRepository
      extends JpaRepository<Order, Long> {
    List<Order> findByCustomerEmail(String email);
  }

At startup (context refresh):
  JpaRepositoriesAutoConfiguration
    -> JpaRepositoryFactoryBean
    -> scans for Repository interfaces
    -> Creates JDK proxy for each interface
    -> Proxy delegates to SimpleJpaRepository
       for standard methods
    -> Derived methods: PartTree parser generates JPQL
       findByCustomerEmail
       -> "SELECT o FROM Order o
            WHERE o.customerEmail = ?1"
    -> @Query methods: uses literal JPQL/SQL
    -> Registers proxy as Spring bean

At runtime (method call):
  orderRepository.findByCustomerEmail("a@b.com")
  -> Proxy intercepts
  -> Routes to QueryExecutorMethodInterceptor
  -> Executes generated/literal query via EntityManager
  -> Returns result

JpaRepository hierarchy:
  JpaRepository
    -> ListCrudRepository (CRUD)
    -> ListPagingAndSortingRepository (pagination)
    -> JpaSpecificationExecutor (dynamic queries)
```

**The key insight:**
Query method derivation happens at application startup. If the method name
is invalid (incorrect property name, wrong syntax), Spring throws an exception
during context refresh - not at runtime. This fail-fast behavior is a key
advantage over raw JPQL strings that only fail when the query executes.

**When to use it:**
- Derived queries: simple conditions based on entity fields
- @Query: complex JPQL when method names become too long
- Native @Query: PostgreSQL-specific features, complex joins not possible in JPQL
- Specification: dynamic predicates built at runtime (search forms)

**When NOT to use it:**
- Reporting queries with many joins and aggregations: use @Query with native SQL
  or a separate query tool (jOOQ, QueryDSL)
- Batch operations on millions of rows: JPA entity tracking overhead is too high;
  use JdbcTemplate or spring-batch

**Alternatives:**
- JdbcTemplate: lower-level, SQL-first, no ORM overhead
- jOOQ: type-safe SQL DSL, good for complex queries
- QueryDSL: type-safe predicate builder on top of JPA
- Mybatis: explicit SQL mapping, good for complex legacy schemas

**First-principles derivation:**
CRUD + query operations are predictable. An interface specifies the contract;
a standard implementation can be generated. Method names encode the query
predicate - the parser extracts entity property names and operators. This is
convention-over-configuration: follow the naming convention, get the query free.

---

### 💻 Code Example

```java
// Entity
@Entity
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String customerEmail;

    @Enumerated(EnumType.STRING)
    private OrderStatus status;

    @Column(nullable = false)
    private BigDecimal total;

    @OneToMany(
        mappedBy = "order",
        fetch = FetchType.LAZY)  // ALWAYS lazy
    private List<OrderItem> items;

    // ... constructors, getters
}

// Repository - all standard operations are free
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    // Derived query - Spring generates JPQL
    List<Order> findByCustomerEmail(String email);

    // Multiple conditions
    List<Order> findByCustomerEmailAndStatus(
        String email, OrderStatus status);

    // Pagination + sorting
    Page<Order> findByStatus(
        OrderStatus status, Pageable pageable);

    // Exists check
    boolean existsByCustomerEmail(String email);

    // Count
    long countByStatus(OrderStatus status);
}
```

> **Code walkthrough:** The repository interface extends JpaRepository<Order, Long>
> - the entity type and ID type. Spring generates all CRUD methods (save, findById,
> findAll, delete, etc.) plus the custom derived methods. The method names follow
> the naming convention: findBy + PropertyName + Condition. All queries are
> generated at startup - invalid property names fail immediately.

```java
// BAD: N+1 query problem - classic JPA trap
public List<OrderDto> getOrdersWithItems(String email) {
    List<Order> orders = orderRepository
        .findByCustomerEmail(email);
    // 1 query for orders, then N queries for items!
    return orders.stream()
        .map(o -> new OrderDto(o.getId(),
            o.getItems().size())) // triggers N queries
        .toList();
}

// GOOD: JOIN FETCH to avoid N+1
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    @Query("SELECT o FROM Order o " +
           "LEFT JOIN FETCH o.items " +
           "WHERE o.customerEmail = :email")
    List<Order> findByCustomerEmailWithItems(
        @Param("email") String email);
}

// BEST: DTO projection - only load needed data
public interface OrderSummary {
    Long getId();
    String getCustomerEmail();
    BigDecimal getTotal();
    int getItemCount(); // derived in query
}

public interface OrderRepository
        extends JpaRepository<Order, Long> {

    @Query("SELECT o.id AS id, " +
           "o.customerEmail AS customerEmail, " +
           "o.total AS total, " +
           "SIZE(o.items) AS itemCount " +
           "FROM Order o " +
           "WHERE o.customerEmail = :email")
    List<OrderSummary> findSummariesByEmail(
        @Param("email") String email);
}
```

> **Code walkthrough:** The N+1 problem is the most common JPA performance
> issue. The BAD example loads orders (1 query), then for each order calls
> getItems() (N queries). At scale (1000 orders), this is 1001 queries.
> The JOIN FETCH version uses one query with a SQL JOIN. The DTO projection
> is the best: it loads only the fields needed, does the aggregation in the
> database, and returns a flat interface instead of loading full entity graphs.

```java
// Dynamic queries with Specification pattern
public interface OrderRepository extends
        JpaRepository<Order, Long>,
        JpaSpecificationExecutor<Order> { }

// Build predicates dynamically
public class OrderSpecifications {
    public static Specification<Order> hasEmail(
            String email) {
        return (root, query, cb) ->
            email == null ? null :
            cb.equal(root.get("customerEmail"),
                     email);
    }

    public static Specification<Order> hasStatus(
            OrderStatus status) {
        return (root, query, cb) ->
            status == null ? null :
            cb.equal(root.get("status"), status);
    }

    public static Specification<Order> afterDate(
            LocalDate date) {
        return (root, query, cb) ->
            date == null ? null :
            cb.greaterThanOrEqualTo(
                root.get("createdAt"), date);
    }
}

// Usage - combine specifications dynamically
public Page<Order> search(OrderSearchRequest req,
                          Pageable pageable) {
    Specification<Order> spec =
        where(hasEmail(req.getEmail()))
        .and(hasStatus(req.getStatus()))
        .and(afterDate(req.getAfterDate()));
    return orderRepository.findAll(spec, pageable);
}
```

> **Code walkthrough:** The Specification pattern enables building JPQL predicates
> dynamically at runtime. Each specification is a lambda returning a JPA Predicate.
> Null specifications are handled by returning null (which Spring Data ignores).
> This is the correct solution for search forms where any combination of filters
> might be active. Without specifications, you would need 2^N repository methods
> for N optional filters.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> JpaRepository gives you save, findById, findAll, delete, and more for free.
> Add custom methods by naming them according to the convention: findByEmail,
> findByEmailAndStatus, findByTotalGreaterThan. Spring generates the SQL
> automatically. For complex queries use @Query with JPQL. The main pitfall
> is N+1 queries - when you load a list of entities and access their lazy
> collections, you get one extra query per entity.

*Push deeper:* Explain how to diagnose N+1 with spring.jpa.show-sql=true and
how to fix it with JOIN FETCH or @EntityGraph.

---

**Senior / Staff (5+ years):**
> Spring Data JPA repositories are JDK proxies generated at startup. Derived
> query methods are parsed by PartTree at startup - invalid names fail fast.
> The N+1 problem is the most important performance concern: always check
> spring.jpa.show-sql=true in development to verify query counts. DTO
> projections are the best performance optimization - they avoid loading
> entity graphs you don't use. For dynamic queries, Specification (JPA Criteria)
> is clean; for very complex reports, native @Query or jOOQ is appropriate.
> @Transactional on @Service methods (not repository methods) is the correct
> transactional boundary.

*Push deeper:* @QueryHints can add JPA hints for pessimistic locking
(@QueryHint(name = "javax.persistence.lock.timeout", value = "1000")),
query timeouts, and query plan cache usage. Also: custom repository
implementations using JpaRepositoryCustom interface.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Spring Data JPA uses Hibernate directly."**
Spring Data JPA is an abstraction over JPA (the specification). Hibernate is
the default JPA provider. Spring Data JPA uses EntityManager, not Hibernate's
Session directly. Code written against Spring Data JPA interfaces works with
any JPA 2.x provider.

**Misconception 2: "All repository methods run in a transaction."**
JpaRepository's built-in methods (save, findById, etc.) are @Transactional.
Your custom @Query methods are NOT automatically transactional unless you
annotate them. The recommended pattern is @Transactional on @Service methods
that call multiple repository operations.

**Misconception 3: "Derived query methods are slow because they are generated at runtime."**
Derived queries are generated at application startup. At runtime, the query
is a pre-compiled JPQL string. There is no derivation overhead at query
execution time.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: N+1 query problem**
Symptom: Application is slow; database slow query log shows hundreds of similar
queries for each request.
Diagnosis: spring.jpa.show-sql=true shows N+1 pattern; Hibernate statistics
show unexpectedly high query count.
Fix: Use JOIN FETCH in @Query, @EntityGraph on the method, or DTO projections.

**Failure 2: LazyInitializationException**
Symptom: "Could not initialize proxy - no Session" when accessing a lazy
collection outside a transaction.
Cause: Entity loaded in a @Transactional service method, transaction committed,
then lazy collection accessed in the controller or view.
Fix: Use JOIN FETCH or @EntityGraph to eagerly load needed associations within
the transaction boundary.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - How does Spring Data JPA generate repository implementations?

At application startup:
1. JpaRepositoriesAutoConfiguration activates (classpath: JPA, Spring Data JPA)
2. JpaRepositoryFactoryBean scans all repository interfaces
3. For each interface, it creates a JDK dynamic proxy
4. Standard methods (findAll, save, etc.) delegate to SimpleJpaRepository
5. Derived query methods: PartTree parser tokenizes the method name into
   Subject + Predicate, then builds a JPA Criteria query or JPQL string
6. @Query methods: literal JPQL/SQL validated by JPA provider at startup
7. The proxy is registered as a Spring bean

If a derived method name has an invalid property reference, Spring throws
PropertyReferenceException during context refresh - fail-fast, not at runtime.

*What separates good from great:* SimpleJpaRepository is the actual
implementation - you can read its source code to understand exactly what
each standard method does. For example, save() calls either persist() or
merge() based on isNew() check (entity has null ID or @Version is null).

---

#### Q2 - What is the N+1 query problem and how do you diagnose it?

N+1: loading N entities and then executing 1 additional query per entity
to load an associated collection.

```
1 query: SELECT * FROM orders WHERE email = 'a@b.com'
-> returns 100 orders

100 queries: SELECT * FROM order_items WHERE order_id = ?
-> executed for each order when items are accessed
```

Total: 101 queries instead of 1 or 2.

Diagnosis:
1. spring.jpa.show-sql=true: prints all executed queries
2. p6spy: intercepts JDBC calls, shows actual SQL with parameters
3. Hibernate statistics: hibernate.generate_statistics=true shows
   "Statements.prepared" count per request
4. In production: slow query log + application performance monitoring

Fix options (ranked by preference):
1. DTO projection: SELECT only what you need, no entity loading
2. JOIN FETCH: `SELECT o FROM Order o LEFT JOIN FETCH o.items WHERE ...`
3. @EntityGraph on repository method: `@EntityGraph(attributePaths = {"items"})`
4. Batch size: `@BatchSize(size=100)` on the collection - loads in batches

*What separates good from great:* Eager fetching (FetchType.EAGER) does NOT
fix N+1 - it moves it to a different query. EAGER runs a separate query per
entity at load time (even when you don't need the association). JOIN FETCH is
the correct fix for cases where you always need the association.

---

#### Q3 - What is the difference between @Query JPQL and native SQL?

**JPQL (@Query)**:
- Queries entity names and property names, not table/column names
- Database-agnostic (works with any JPA provider/database)
- JPA provider translates to SQL at startup (validated, fails fast)
- Supports entity associations naturally (LEFT JOIN FETCH o.items)

**Native SQL (@Query(nativeQuery = true))**:
- Raw SQL against actual table and column names
- Database-specific syntax (PostgreSQL, MySQL differences)
- Not validated by JPA - SQL errors manifest at runtime
- Required for database-specific features: JSON queries, full-text search,
  window functions, CTEs, LATERAL joins

Use JPQL for standard queries. Use native SQL for:
- Complex reporting requiring database-specific features
- Queries where JPA's abstraction adds overhead or complexity
- Performance-critical queries that need exact SQL control

*What separates good from great:* Native queries with DTO projections are the
most performant read path: exact SQL, exact columns selected, no entity
overhead. For high-throughput reporting (millions of rows), native SQL +
DTO is preferable to JPQL + entity loading.

---

#### Q4 - What is a DTO projection in Spring Data JPA?

A DTO projection is an interface (or class) with getters matching the fields
selected in the query. Spring Data JPA maps query results to the projection
interface automatically - no entity is instantiated.

Benefits:
1. Only requested columns loaded from database (smaller result set)
2. No Hibernate entity tracking overhead (no first-level cache entry)
3. No lazy loading surprises (projections are flat, no associations)
4. Can include computed fields from the query

Interface projection:
```java
public interface OrderSummary {
    Long getId();
    String getCustomerEmail();
    BigDecimal getTotal();
}
List<OrderSummary> findByStatus(OrderStatus s);
```

Class projection (DTO constructor):
```java
public record OrderSummary(Long id,
                           String customerEmail,
                           BigDecimal total) {}

@Query("SELECT new com.example.OrderSummary(o.id, " +
       "o.customerEmail, o.total) " +
       "FROM Order o WHERE o.status = :status")
List<OrderSummary> findSummariesByStatus(
    @Param("status") OrderStatus status);
```

*What separates good from great:* Interface projections use JDK proxies
(one proxy per result row). For large result sets, class projections (DTO with
constructor) are slightly faster because they create plain objects instead
of proxies. For millions of rows, use Stream<T> return type to avoid loading
all rows into memory at once.

---

#### Q5 - How does pagination work in Spring Data JPA?

Repository method returning Page<T>:
```java
Page<Order> findByStatus(OrderStatus status,
                         Pageable pageable);
```

Calling code:
```java
Pageable page = PageRequest.of(
    0,  // page number (0-based)
    20, // page size
    Sort.by("createdAt").descending()
);
Page<Order> result = orderRepository
    .findByStatus(PENDING, page);

result.getContent();      // List<Order> for this page
result.getTotalElements();// total rows (runs COUNT query)
result.getTotalPages();   // total pages
result.hasNext();         // more pages?
```

Page<T> executes TWO queries: one for data, one for COUNT. For large tables,
COUNT(*) can be expensive. Use Slice<T> instead of Page<T> when you only
need hasNext() (infinite scroll) - it avoids the COUNT query.

*What separates good from great:* The COUNT query generated by Spring Data is
often not optimal. For complex queries with JOINs, the COUNT query repeats the
full JOIN which is expensive. Use a custom countQuery in @Query:
`@Query(value="...", countQuery="SELECT COUNT(o.id) FROM Order o WHERE ...")`

---

#### Q6 - What is @Modifying and when do you need it?

@Modifying marks a @Query method as a write operation (UPDATE or DELETE).
Without it, Spring Data throws InvalidDataAccessApiUsageException for DML queries.

```java
@Modifying
@Transactional
@Query("UPDATE Order o SET o.status = :status " +
       "WHERE o.id = :id")
int updateStatus(@Param("id") Long id,
                 @Param("status") OrderStatus status);

@Modifying
@Transactional
@Query("DELETE FROM Order o " +
       "WHERE o.status = :status " +
       "AND o.createdAt < :cutoff")
int deleteOldOrdersByStatus(
    @Param("status") OrderStatus status,
    @Param("cutoff") LocalDateTime cutoff);
```

@Modifying(clearAutomatically = true): clears the first-level cache (persistence
context) after the update. Without this, the cache may contain stale data -
you updated via JPQL but the cached entity still has the old value.

*What separates good from great:* @Modifying bulk updates bypass Hibernate's
entity lifecycle callbacks (@PreUpdate, etc.) and the first-level cache. Use
clearAutomatically = true to ensure subsequent reads see updated data. For
entity validation and auditing, updating entities via save() is cleaner - bulk
@Modifying is for performance-critical mass updates.

---

#### Q7 - How does @Transactional interact with Spring Data repositories?

SimpleJpaRepository methods are @Transactional (read-only for queries,
read-write for save/delete). This means each call is its own transaction.

Problem: you need atomic multi-step operations:
```java
// BAD: two separate transactions
orderRepository.save(order); // TX1
paymentRepository.save(payment); // TX2
// If TX2 fails, TX1 is already committed - inconsistency!
```

Correct pattern: @Transactional on the service method:
```java
@Service
public class OrderService {
    @Transactional
    public void createOrderWithPayment(
            Order order, Payment payment) {
        orderRepository.save(order);    // in TX
        paymentRepository.save(payment);// in TX
        // If anything fails, both roll back
    }
}
```

With @Transactional on the service: Spring starts a transaction before the
method, repository calls join the existing transaction
(default propagation = REQUIRED), transaction commits or rolls back when
the service method returns.

*What separates good from great:* @Transactional only works on proxied method
calls. If OrderService.createOrderWithPayment() calls another @Transactional
method in the SAME class directly (this.otherMethod()), it bypasses the proxy
and the second @Transactional is ignored. This is the self-invocation problem.

---

#### Q8 - What is the Specification pattern and when do you use it?

The Specification pattern (Criteria API wrapper) enables building dynamic
predicates at runtime. Use it when query conditions are optional at runtime
(search forms with many optional filters).

```java
public interface OrderRepository extends
        JpaRepository<Order, Long>,
        JpaSpecificationExecutor<Order> {}

// Dynamic specifications
where(hasEmail(req.getEmail()))
    .and(hasStatus(req.getStatus()))
    .and(afterDate(req.getAfterDate()))
```

Pros: type-safe, composable, handles nulls via null predicate convention
Cons: verbose code compared to QueryDSL; complex queries can be hard to read

Alternatives:
- QueryDSL: generates metamodel from entities, type-safe predicate DSL
- @Query with JPQL: when conditions are known at compile time
- jOOQ: for complex SQL, generates type-safe DSL from database schema

*What separates good from great:* Specifications have an N+1 problem when
combining with collections (items in an order). The specification joins trigger
multiple rows per order (one per item), and the result set has duplicates.
Fix with query.distinct(true) in the specification.

---

#### Q9 - What are custom repository implementations?

For operations that don't fit derived queries, @Query, or Specification, you
can add custom implementation to a repository:

```java
// Custom interface
public interface OrderRepositoryCustom {
    List<Order> findWithComplexQuery(
        OrderSearchParams params);
}

// Implementation
public class OrderRepositoryImpl
        implements OrderRepositoryCustom {
    @PersistenceContext
    private EntityManager em;

    @Override
    public List<Order> findWithComplexQuery(
            OrderSearchParams params) {
        // Direct EntityManager - full JPA power
        CriteriaBuilder cb = em.getCriteriaBuilder();
        // ... complex criteria query
    }
}

// Repository interface combines both
public interface OrderRepository extends
        JpaRepository<Order, Long>,
        OrderRepositoryCustom {}
```

Spring Data detects the Impl suffix and wires them together. The proxy
delegates to OrderRepositoryImpl for the custom method.

*What separates good from great:* The Impl class can also use JdbcTemplate
for native SQL operations that are too complex for JPA. Injecting JdbcTemplate
into a custom repository implementation gives you full access to native SQL
within the clean repository abstraction.

---

# @ConfigurationProperties

---
id: SPR-015
title: "@ConfigurationProperties"
category: Spring
difficulty: ★★☆
interview_weight: high
asked_at: All
seniority: mid
tags: #spring-boot, #configuration, #properties, #config-binding
status: draft
sd: false
version: 1
---

🎯 Interview Weight: High — @ConfigurationProperties vs @Value is a common
interview question about Spring Boot configuration best practices.

---

### 🎯 Model Answer

**30 seconds:**
> @ConfigurationProperties binds a group of related properties from
> application.properties to a Java bean. Instead of injecting individual
> values with @Value, you declare a class with fields matching property names
> and annotate it with @ConfigurationProperties(prefix = "app"). Spring binds
> all app.* properties to the class. This is the recommended approach for
> structured configuration.

**3 minutes (Senior):**
> @ConfigurationProperties provides type-safe, validated, and IDE-supported
> configuration binding. The bound class is a plain Java bean registered in
> the context. JSR-303 validation annotations (@NotNull, @Min, @Max) on the
> fields are validated at startup - invalid configuration causes startup failure
> with a clear error message.
>
> The main advantage over @Value is organization and validation. @Value injects
> individual properties scattered across multiple classes. @ConfigurationProperties
> groups related properties into one class - a clear data structure for
> configuration. IDE support is excellent: Spring Boot's annotation processor
> generates metadata for autocomplete in application.properties.
>
> For refreshable configuration (Spring Cloud), @RefreshScope + @ConfigurationProperties
> allows beans to pick up new values without restart. @Value fields are refreshed
> automatically with @RefreshScope; @ConfigurationProperties requires both
> @RefreshScope and @ConfigurationProperties.

**Framework:** WHAT -> WHY -> HOW -> TRADE-OFF -> EXAMPLE

*Adapting up:* Staff - discuss configuration metadata generation for IDE
support, @ConfigurationPropertiesBinding for custom type converters, and
configuring separate profiles with YAML.

*Adapting down:* Junior - "@Value injects one property. @ConfigurationProperties
groups a set of related properties into one class. For more than 2-3 properties,
@ConfigurationProperties is cleaner."

**Blank Mind Recovery:**

**(1) Restate:** "You are comparing @Value vs @ConfigurationProperties for
injecting configuration properties."

**(2) First principles:** "Configuration is structured data. Binding it to a
structured Java class is more natural than injecting individual values into
scattered fields."

**(3) Bridge:** "Think of @Value as reading config line by line. @ConfigurationProperties
is reading the whole config section into a structured record."

---

### 📘 Concept Explanation

**What it is:**
@ConfigurationProperties binds externalized configuration (application.properties,
application.yml, environment variables, system properties) to a Java bean.
The bean's field names map to property keys under the specified prefix.

**The problem it solves:**
@Value injects individual properties, scattered across classes. When a service
has 5 configuration values, you get 5 @Value fields, each with a string path
that is hard to rename or track. @ConfigurationProperties groups all related
configuration into one class with IDE support, type conversion, and validation.

**How it works:**

```
application.properties:
  app.payment.url=https://pay.example.com
  app.payment.timeout=5000
  app.payment.retries=3
  app.payment.api-key=${PAYMENT_API_KEY}

@ConfigurationProperties class:
  @ConfigurationProperties(prefix = "app.payment")
  @Validated
  public class PaymentConfig {
      @NotEmpty
      private String url;

      @DurationUnit(ChronoUnit.MILLIS)
      private Duration timeout;

      @Min(1) @Max(10)
      private int retries;

      @NotEmpty
      private String apiKey; // kebab-case -> camelCase

      // getters + setters (or record)
  }

Binding mechanism:
  At startup: ConfigurationPropertiesBindingPostProcessor
    -> for each @ConfigurationProperties bean
    -> reads PropertySources (file, env vars, system props)
    -> resolves prefix + field names
    -> converts types (String -> Duration, String -> int)
    -> validates @Validated constraints
    -> if validation fails: BindException -> startup failure

Registration options:
  @EnableConfigurationProperties(PaymentConfig.class)
  OR
  @Bean on the class + @ConfigurationPropertiesScan
  OR
  @Component + @ConfigurationProperties (direct)
```

**The key insight:**
Relaxed binding is one of @ConfigurationProperties's most useful features.
`app.payment.api-key` in properties maps to `apiKey` in Java (kebab-case to
camelCase). `APP_PAYMENT_API_KEY` as an environment variable also works. This
makes it easy to follow both Java naming conventions in code and environment-
variable conventions in deployment.

**When to use it:**
- More than 2 related configuration properties
- Configuration that needs validation
- Configuration shared across multiple beans
- Configuration for an autoconfiguration library

**When NOT to use it:**
- Single property injection (@Value is simpler for one value)
- Properties that are not grouped or related

**Alternatives:**
- @Value: for single property injection with SpEL support
- Environment.getProperty(): programmatic property access without binding

**First-principles derivation:**
Configuration is structured data. A Java class models structure. Binding
configuration to a class is the same as deserializing JSON/YAML to a Java
object. @ConfigurationProperties is configuration deserialization with
validation, a pattern that makes configuration an explicit, documented,
validated part of the application's API.

---

### 💻 Code Example

```java
// BAD: scattered @Value annotations
@Service
public class PaymentService {
    @Value("${app.payment.url}")
    private String paymentUrl;

    @Value("${app.payment.timeout:5000}")
    private long timeoutMs;

    @Value("${app.payment.retries:3}")
    private int maxRetries;

    @Value("${app.payment.api-key}")
    private String apiKey;

    // Problems:
    // 1. Configuration scattered - hard to find all values
    // 2. No validation - null apiKey discovered at runtime
    // 3. No IDE autocomplete for property names
    // 4. Cannot share config between multiple services
}
```

> **Code walkthrough:** The @Value approach scatters configuration knowledge
> across classes. To find all payment configuration, you search the codebase
> for @Value annotations containing "payment". If apiKey is missing, you get
> IllegalArgumentException when Spring tries to resolve the placeholder - but
> only when this service is first used, not at startup.

```java
// GOOD: @ConfigurationProperties - grouped, validated, typed
@ConfigurationProperties(prefix = "app.payment")
@Validated  // enable JSR-303 validation on fields
public class PaymentProperties {
    @NotEmpty(message = "Payment URL is required")
    private String url;

    @NotNull
    @DurationUnit(ChronoUnit.MILLIS)
    private Duration timeout = Duration.ofSeconds(5);

    @Min(1) @Max(10)
    private int retries = 3;

    @NotEmpty(message = "Payment API key is required")
    private String apiKey;

    // Nested configuration
    private CircuitBreakerConfig circuitBreaker
        = new CircuitBreakerConfig();

    @Data  // Lombok
    public static class CircuitBreakerConfig {
        private int failureThreshold = 5;
        private Duration waitDuration
            = Duration.ofSeconds(30);
    }

    // Standard getters/setters or use @Data
}

// Register and enable
@Configuration
@EnableConfigurationProperties(PaymentProperties.class)
public class PaymentConfig {
    @Bean
    public PaymentService paymentService(
            PaymentProperties props) {
        return new PaymentService(
            props.getUrl(),
            props.getTimeout(),
            props.getRetries(),
            props.getApiKey());
    }
}

// application.properties:
// app.payment.url=https://pay.example.com
// app.payment.timeout=5000ms
// app.payment.retries=3
// app.payment.api-key=${PAYMENT_API_KEY}
// app.payment.circuit-breaker.failure-threshold=3
```

> **Code walkthrough:** @ConfigurationProperties groups all payment configuration
> in one class. @Validated enables JSR-303 validation - if api-key is missing or
> url is empty, Spring throws BindException at startup with a clear error message.
> Duration type: Spring Boot converts "5000ms" or "5s" to Duration automatically.
> Nested configuration models hierarchical properties. IDE autocomplete works for
> all app.payment.* properties. All tests that need PaymentProperties can create
> it directly without Spring context.

```java
// Modern: @ConfigurationProperties with Java records (Boot 2.6+)
@ConfigurationProperties("app.payment")
public record PaymentProperties(
    @NotEmpty String url,
    @NotNull Duration timeout,
    @Min(1) @Max(10) int retries,
    @NotEmpty String apiKey
) {
    // Default values via compact constructor
    public PaymentProperties {
        if (timeout == null) {
            timeout = Duration.ofSeconds(5);
        }
        if (retries < 1) retries = 3;
    }
}
// Records are immutable - constructor injection, all fields final
// No setters needed - constructor binding used automatically
```

> **Code walkthrough:** Spring Boot 2.6+ supports records with @ConfigurationProperties.
> Records are immutable - all fields final, no setters. Spring uses constructor
> binding, which is the immutable approach. Validation annotations work on record
> components. The compact constructor handles defaults. This is the cleanest modern
> configuration pattern: immutable, validated, minimal boilerplate.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> @Value injects one property. @ConfigurationProperties binds a group of related
> properties to a Java class. With @ConfigurationProperties, you declare a class
> with fields matching property names and annotate it with the prefix. Spring
> automatically fills in the values and validates them at startup. This is
> preferred when you have several related configuration values.

*Push deeper:* Explain that @Validated enables startup validation - missing or
invalid config causes startup failure rather than runtime errors.

---

**Senior / Staff (5+ years):**
> @ConfigurationProperties is configuration as a first-class domain object.
> It provides relaxed binding (kebab-case in properties, camelCase in Java, UPPER_SNAKE
> in environment variables - all map to the same field), type conversion (Duration,
> DataSize, etc.), and startup validation via @Validated + JSR-303. The Spring Boot
> annotation processor generates configuration metadata from @ConfigurationProperties
> classes, enabling IDE autocomplete for custom properties. For sealed libraries,
> shipping a spring-configuration-metadata.json allows users to get autocomplete
> in their projects for your library's configuration.

*Push deeper:* @ConfigurationPropertiesBinding allows registering custom
Converter<String, T> implementations for binding custom types. For example,
binding a CIDR notation string to an InetAddressRange object. This is how Spring
Boot's built-in converters for Duration and DataSize work.

---

### ⚠️ Common Misconceptions

**Misconception 1: "@Value is always simpler than @ConfigurationProperties."**
@Value is simpler for 1-2 properties. For 3+ related properties, @ConfigurationProperties
is cleaner. The maintenance cost of scattered @Value annotations grows linearly
with the number of properties.

**Misconception 2: "@ConfigurationProperties requires setters."**
Since Spring Boot 2.2, constructor binding is supported. Annotate with
@ConstructorBinding (or use a record in Boot 2.6+) for immutable configuration
classes. Spring uses the constructor to populate all fields.

**Misconception 3: "Properties must exactly match field names."**
Relaxed binding supports multiple conventions:
- Property file: app.api-key (kebab-case)
- Java: apiKey (camelCase)
- Env variable: APP_API_KEY (upper snake)
All map to the same field via relaxed binding.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: BindException at startup**
Symptom: "Failed to bind properties under 'app.payment' to ...PaymentProperties"
Cause: Validation failed (@NotEmpty on missing property, @Min violation) or
type conversion failed (invalid Duration format).
Diagnosis: Read the BindException message carefully - it names the property and
the constraint that failed.
Fix: Add the missing property to application.properties or correct the value.

**Failure 2: Property not binding (value remains null/default)**
Symptom: Configuration field remains null despite being set in properties.
Cause: Field name mismatch (relaxed binding can't match), wrong prefix in
@ConfigurationProperties, or @ConfigurationProperties class not registered.
Diagnosis: Add @Validated with @NotNull on the field - you'll see which fields
are null at startup.
Fix: Verify the prefix and field names; ensure class is registered via
@EnableConfigurationProperties or @ConfigurationPropertiesScan.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

#### Q1 - What is @ConfigurationProperties and how does it differ from @Value?

@ConfigurationProperties binds a group of properties with a common prefix to
a POJO. @Value injects individual property values.

Key differences:

| | @ConfigurationProperties | @Value |
|---|---|---|
| Scope | Group of related properties | Single property |
| Type safety | Full type conversion | String by default |
| Validation | @Validated + JSR-303 | None (runtime NPE) |
| IDE support | Full autocomplete | Limited |
| SpEL support | No | Yes (#{...}) |
| Immutability | Constructor binding | No |

When to use @Value: single property, SpEL expressions, conditional expressions
with defaults `${prop:default}`.

When to use @ConfigurationProperties: everything else.

*What separates good from great:* @ConfigurationProperties classes are plain
beans with no Spring dependencies. They can be instantiated and tested in
isolation: `new PaymentProperties(url, timeout, retries, key)`. This makes
configuration testing clean.

---

#### Q2 - How does relaxed binding work?

Spring Boot supports multiple naming conventions for the same property:

```
app.payment.api-key=secret        # kebab-case (recommended)
app.payment.apiKey=secret         # camelCase
app.payment.api_key=secret        # underscore
APP_PAYMENT_API_KEY=secret        # env var (UPPER_SNAKE)
```

All of these bind to the Java field `private String apiKey`.

Rules:
- Recommended in properties files: kebab-case
- Recommended in environment variables: UPPER_SNAKE_CASE
- Both work regardless of Java field name case

Relaxed binding applies to @ConfigurationProperties only, NOT @Value.
`@Value("${app.payment.api-key}")` uses the exact key - no relaxed binding.

*What separates good from great:* Environment variables use underscore as
separator because dots are reserved in many shell environments. SPRING_DATASOURCE_URL
in an environment variable maps to spring.datasource.url in properties.
This is how Kubernetes ConfigMap and Secret environment variables work
with Spring Boot configuration.

---

#### Q3 - How do you validate @ConfigurationProperties?

Add @Validated to the class and JSR-303 annotations to fields:

```java
@ConfigurationProperties("app")
@Validated
public class AppProperties {
    @NotEmpty
    @URL
    private String baseUrl;

    @NotNull
    @Positive
    private Integer maxConnections;

    @Valid   // cascade validation to nested
    private NestedConfig nested = new NestedConfig();
}
```

If validation fails at startup: BindException wraps the ConstraintViolations.
Spring Boot prints each failed constraint with the property name and invalid value.

*What separates good from great:* @Valid cascades validation to nested
configuration classes. Without @Valid, constraints on the nested class fields
are not evaluated. This is a common oversight when using nested configuration.

---

#### Q4 - What is constructor binding and how is it different from setter binding?

**Setter binding** (default):
- Spring creates the object using the default constructor
- Populates fields via setter methods
- Fields can be mutable (not final)

**Constructor binding** (`@ConstructorBinding` or Java record):
- Spring uses a constructor with all configuration fields as parameters
- Fields can be final (immutable configuration)
- Required for records
- Available since Spring Boot 2.2

```java
// Constructor binding - immutable
@ConfigurationProperties("server")
@ConstructorBinding  // required in Boot 2.x (not in 3.x)
public class ServerProperties {
    private final String host;
    private final int port;

    public ServerProperties(String host, int port) {
        this.host = host;
        this.port = port;
    }
}
```

In Spring Boot 3.x, constructor binding is detected automatically for classes
with a single constructor that has all properties - @ConstructorBinding is not
needed.

*What separates good from great:* Immutable configuration is inherently thread-safe
and easier to reason about. When configuration is final, you know it cannot
change after construction. Prefer constructor binding (or records) for all new
@ConfigurationProperties classes.

---

#### Q5 - How does @ConfigurationProperties support type conversion?

Spring Boot includes converters for many types:

- Duration: "5s", "100ms", "1h30m" -> Duration
- DataSize: "10MB", "500KB" -> DataSize  
- Period: "1y", "2m", "10d" -> Period
- File and Path: absolute or relative paths
- InetAddress: "192.168.1.1" or hostname

These are registered automatically via ApplicationConversionService.

Custom converter:
```java
@Bean
@ConfigurationPropertiesBinding
public Converter<String, MyType> myTypeConverter() {
    return source -> MyType.parse(source);
}
```

@ConfigurationPropertiesBinding marks the converter as intended for
@ConfigurationProperties binding (not MVC type conversion).

*What separates good from great:* DataSize is useful for configuring buffer
sizes, heap limits, etc.: `server.max-http-header-size=8KB`. Without this
type, you'd need to parse the string manually or use bytes. Type-safe
configuration values communicate intent and prevent units confusion
(milliseconds vs seconds).

---

#### Q6 - How do you use @ConfigurationProperties for multi-profile configuration?

application.yml with profiles:
```yaml
app:
  payment:
    url: https://sandbox.pay.com
    timeout: 10s  # generous in dev

---
spring:
  config:
    activate:
      on-profile: production
app:
  payment:
    url: https://pay.example.com
    timeout: 5s  # tighter in production
```

The @ConfigurationProperties class is the same - Spring loads different property
values based on active profile. No Java code changes needed.

For programmatic profile selection:
```java
@Component
@Profile("production")
public class ProductionPaymentProperties
        extends PaymentProperties { ... }
```

*What separates good from great:* application.yml's multi-document format
(---) allows profile-specific sections in one file. For complex configuration,
application-{profile}.properties files are cleaner: application-production.properties
overrides only the production-specific values.

---

#### Q7 - How do you test @ConfigurationProperties?

Option 1 - @SpringBootTest (integration):
```java
@SpringBootTest
@TestPropertySource(properties = {
    "app.payment.url=https://test.example.com",
    "app.payment.api-key=test-key"
})
class PaymentPropertiesTest {
    @Autowired
    PaymentProperties props;
    // Full Spring context - slow but realistic
}
```

Option 2 - @ConfigurationPropertiesTest (slice test):
```java
@ExtendWith(SpringExtension.class)
@EnableConfigurationProperties(PaymentProperties.class)
@TestPropertySource(properties = {
    "app.payment.url=https://test.example.com",
    "app.payment.api-key=test-key"
})
class PaymentPropertiesTest {
    @Autowired
    PaymentProperties props;
    // Minimal context - only binds properties
}
```

Option 3 - Direct constructor (unit test):
```java
// If using constructor binding or records
PaymentProperties props = new PaymentProperties(
    "https://test.example.com",
    Duration.ofSeconds(5),
    3,
    "test-key"
);
// No Spring needed at all
```

*What separates good from great:* Option 3 (direct construction) is the fastest
and most appropriate for unit testing your configuration class's logic
(compact constructor defaults, validation). Use @SpringBootTest for integration
tests that verify the full property binding chain.

---

#### Q8 - What is the difference between application.properties and application.yml?

Both serve the same purpose - externalized configuration. Differences:

**application.properties:**
- Key=value format: `app.payment.url=https://pay.com`
- Flat - nested properties expressed with dots
- Better for simple configurations
- No data structure features

**application.yml:**
- YAML format with indentation for nesting
- Natural for deeply nested configuration
- Multi-document format for profiles (---)
- Lists and maps more readable
- Watch out: YAML is indentation-sensitive (TabError if tabs instead of spaces)

Choose .yml for: complex nested configuration, multiple profiles in one file.
Choose .properties for: simple flat configuration, environments where YAML
parsing issues arise.

*What separates good from great:* When both application.properties and
application.yml exist, Spring Boot loads both. Properties file values override
YAML values with the same key. This is useful for defaults in YAML and
environment-specific overrides in properties.

---

#### Q9 - How do you access properties programmatically (without binding)?

Option 1 - Environment.getProperty():
```java
@Service
public class DynamicConfigService {
    private final Environment env;

    public String getConfig(String key) {
        return env.getProperty(key, "default");
    }
}
```

Option 2 - @PropertySource + @Value:
```java
@Configuration
@PropertySource("classpath:custom.properties")
public class CustomConfig {
    @Value("${custom.prop}")
    private String customProp;
}
```

Option 3 - ApplicationContext.getEnvironment():
```java
String value = applicationContext
    .getEnvironment()
    .getProperty("my.prop");
```

Environment.getProperty() is useful for: dynamic property lookup based on
runtime values, checking if a property exists without failing, accessing
properties in components that cannot use @ConfigurationProperties.

*What separates good from great:* Environment.getProperty() always returns
the latest value from the property sources. Unlike @Value fields (set at
injection time), Environment.getProperty() reflects changes if property
sources are refreshed (Spring Cloud Config Server scenarios).
