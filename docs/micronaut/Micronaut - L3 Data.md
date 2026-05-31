---
layout: default
title: "Micronaut - L3 Data"
parent: "Micronaut"
grand_parent: "SK Interview"
nav_order: 5
permalink: /micronaut/l3-data/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Micronaut Data JDBC](#micronaut-data-jdbc) | critical |
| 2 | [Micronaut Data JPA](#micronaut-data-jpa) | high |
| 3 | [Micronaut Data Repositories and Criteria](#micronaut-data-repositories-and-criteria) | high |
| 4 | [Micronaut Transaction Management](#micronaut-transaction-management) | critical |
| 5 | [Micronaut Data Reactive Repositories](#micronaut-data-reactive-repositories) | high |

---

# Micronaut Data JDBC

**Interview Weight:** critical - Micronaut Data JDBC
is the preferred data access layer for compile-time
repository generation. Core to production Micronaut.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut Data JDBC uses annotation processing to
> generate JDBC repository implementations at compile
> time. No reflection at runtime for query execution.
> Define a repository interface extending JdbcRepository.
> Micronaut generates the SQL from method names or
> from explicit @Query annotations. Unlike JPA,
> no entity proxies - you get plain Java objects back.
> Faster startup, no Hibernate overhead.

**3 minutes (Senior):**

> Micronaut Data JDBC vs Hibernate:
>
> No entity lifecycle callbacks (PrePersist, etc.)
>   Plain data objects, no dirty checking
>   Explicit save required for updates
>
> Repository method name translation:
>   findById(Long id) → SELECT * FROM table WHERE id=?
>   findByStatusAndCreatedAtAfter(Status, Instant)
>     → WHERE status=? AND created_at>?
>   countByStatus(String status) → SELECT COUNT(*)
>   existsById(Long id) → SELECT COUNT(*) > 0
>   deleteByStatus(String status) → DELETE WHERE status=?
>
> Explicit queries:
>   @Query("SELECT * FROM orders WHERE tenant_id=:tenantId
>           AND status=:status")
>   List<Order> findByTenantAndStatus(
>     @Parameter("tenantId") Long tenantId,
>     @Parameter("status") String status);
>
> Pagination:
>   Return Page<T> with Pageable parameter.
>   Pageable.from(page, size) builds pagination.
>   Query and count queries generated together.
>
> Joins and projections:
>   @Join(value="customer", type=JOIN_FETCH)
>   Return DTO instead of entity for projections.
>
> Data types:
>   @MappedEntity on the entity class.
>   @Id for primary key.
>   @GeneratedValue for auto-increment.
>   @Column(name="..") for column mapping.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Micronaut Data
JDBC - compile-time generated JDBC repositories."

**(2) First principles:** "Repository = interface for
data access. Micronaut generates the implementation.
JDBC = direct SQL, no ORM overhead."

**(3) Bridge:** "Micronaut Data JDBC is like Spring
Data JPA minus the Hibernate layer. Method names become
SQL. Generated at compile time, not runtime."

---

### 💻 Code Example

```java
// Entity
@MappedEntity("orders")
public class Order {

    @Id
    @GeneratedValue(GeneratedValue.Type.SEQUENCE)
    private Long id;

    @Column(name="customer_id")
    private Long customerId;

    @Column(name="total_amount")
    private BigDecimal totalAmount;

    @Column(name="status")
    @TypeDef(type=DataType.STRING)
    private OrderStatus status;

    @DateCreated
    @Column(name="created_at")
    private Instant createdAt;

    @DateUpdated
    @Column(name="updated_at")
    private Instant updatedAt;

    // constructors, getters, setters
}

// Repository
@JdbcRepository(dialect = Dialect.POSTGRES)
public interface OrderRepository
        extends PageableRepository<Order, Long> {

    // Method name → SQL
    Optional<Order> findByIdAndCustomerId(
        Long id, Long customerId);

    List<Order> findByStatus(OrderStatus status);

    // Explicit query for complex join
    @Query("""
        SELECT o.*, c.name as customer_name
        FROM orders o
        JOIN customers c ON c.id=o.customer_id
        WHERE o.status=:status
          AND o.created_at > :since
        ORDER BY o.created_at DESC
        """)
    List<OrderWithCustomer> findRecentByStatus(
        @Parameter("status") String status,
        @Parameter("since") Instant since);

    // Pagination
    Page<Order> findByCustomerId(
        Long customerId, Pageable pageable);

    // Count
    long countByStatus(OrderStatus status);

    // Exists
    boolean existsByIdAndCustomerId(
        Long id, Long customerId);

    // Batch insert
    @Query("""
        INSERT INTO orders
          (customer_id, total_amount, status)
        VALUES (:customerId, :totalAmount, :status)
        """)
    void insertOrder(
        @Parameter("customerId") Long customerId,
        @Parameter("totalAmount") BigDecimal amount,
        @Parameter("status") String status);
}

// Service usage
@Singleton
public class OrderService {

    private final OrderRepository repo;
    private final TransactionOperations<?> tx;

    OrderService(
            OrderRepository repo,
            TransactionOperations<?> tx) {
        this.repo = repo;
        this.tx = tx;
    }

    public Order create(CreateOrderRequest req) {
        Order order = new Order();
        order.setCustomerId(req.getCustomerId());
        order.setTotalAmount(req.getTotal());
        order.setStatus(OrderStatus.PENDING);
        return repo.save(order);  // INSERT generated
    }

    public Order updateStatus(Long id, OrderStatus st) {
        Order order = repo.findById(id)
            .orElseThrow(() -> new NotFoundException(id));
        order.setStatus(st);
        return repo.update(order);  // UPDATE generated
    }
}
```

> **Code walkthrough:** @MappedEntity maps the class
> to the "orders" table. @DateCreated/@DateUpdated are
> automatically set by Micronaut on save/update - no
> DB trigger needed. The repository extends
> PageableRepository which provides save/update/delete/find.
> Method names like findByStatus generate
> `SELECT * FROM orders WHERE status=?` at compile time.
> The @Query with triple-quoted SQL is validated at
> compile time (parameter names matched). Page<Order>
> return with Pageable generates both the data query
> and a COUNT query.

---

### ⚖️ Comparison Table

| Feature | Micronaut Data JDBC | Spring Data JPA + Hibernate |
|---|---|---|
| Repository generation | Compile time | Runtime (reflection) |
| Entity proxies | No | Yes (lazy loading) |
| Dirty checking | No | Yes |
| Explicit save required | Yes | No (within session) |
| N+1 prevention | Manual @Join | Fetch strategies |
| Startup time | Fast | Slower (schema validation) |
| GraalVM native | Easy | Config needed |

---

### ⚠️ Common Misconceptions

**"Micronaut Data JDBC is JPA without the proxies":**
No. Micronaut Data JDBC has no persistence context,
no session, no dirty checking. Changes to an entity
after load do NOT persist automatically. You must call
repo.update(entity) explicitly.

**"Method names always generate SQL correctly":**
For complex queries, method names become unmaintainable.
Use @Query for anything beyond 2 conditions. Method
names are for simple lookups.

---

### 🚨 Failure Modes and Diagnosis

**Symptoms and Fixes:**

1. "No backing query for method" at startup:
   - Cause: method signature not translatable to SQL
   - Fix: use @Query with explicit SQL
   - Check: generate-query property in repository

2. Missing column error at runtime:
   - Cause: @MappedEntity column mismatch
   - Fix: add @Column(name="...") on field
   - Prevention: test with flyway migration enabled

3. Stale data after update:
   - Cause: no dirty checking - modified entity
     not saved
   - Fix: call repo.update(entity) explicitly
   - Pattern: always return the result of repo.save/update

---

### 🎓 Answers by Seniority

**Junior:** "Extend JdbcRepository. Method names generate
SQL. @Query for custom SQL. Save returns the saved entity."

**Senior:** "No dirty checking means you must call
repo.update(entity) explicitly. Page<T> generates a
count query alongside the data query. @Join on the
method avoids N+1 for joined entities."

**Staff:** "Micronaut Data JDBC is optimal for
microservices: compile-time SQL, no ORM overhead,
predictable query behavior. JPA is better when you
have complex domain objects with lifecycle events
and dirty tracking. Choose JDBC for read-heavy
services; JPA for write-heavy domain-heavy services."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Repository methods, @Query, pagination, dirty tracking |
| Staff | 12 min | JDBC vs JPA trade-offs, N+1, compile-time validation |

---

**[SENIOR] Q1 - How do you handle N+1 in Micronaut
Data JDBC when an Order has multiple OrderItems?**

*Why they ask:* N+1 is a classic data access bug.

Micronaut Data JDBC does not have JPA lazy loading.
Each entity is fetched independently by default.

N+1 scenario:
```java
// N+1: fetches orders, then N queries for items
List<Order> orders = repo.findAll();
orders.forEach(o -> {
    List<OrderItem> items =
        itemRepo.findByOrderId(o.getId());
    // Each call = 1 SQL query
});
// 1 + N SQL queries
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Solution 1: @Join on the repository method:
```java
@Join(value="items", type=JoinType.FETCH)
List<Order> findAllWithItems();
// Generates a LEFT JOIN
// 1 SQL query
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Solution 2: Batch loading:
```java
// Load all order IDs
List<Long> ids = orders.stream()
    .map(Order::getId)
    .collect(toList());
// Batch load all items
List<OrderItem> items =
    itemRepo.findByOrderIdIn(ids);
// 2 SQL queries total
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Solution 3: Explicit @Query with JOIN:
```java
@Query("""
    SELECT o.*, i.id as item_id, i.product_id,
           i.quantity
    FROM orders o
    LEFT JOIN order_items i ON i.order_id=o.id
    """)
List<OrderWithItems> findAllWithItems();
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* @Join as the
idiomatic Micronaut Data JDBC solution vs the manual
batch approach.

**[SENIOR] Q2 - What does Micronaut Data JDBC generate
at compile time? How can you inspect it?**

*Why they ask:* Debugging and understanding.

Micronaut generates a concrete repository class in:
`target/generated-sources/annotations/`
or compiled as:
`target/classes/$OrderRepository$Implementation.class`

The class contains:
- SQL strings computed from method names
- JDBC template calls (PreparedStatement creation)
- ResultSet mapping to entity class
- Pagination query and count query

To inspect:
```bash
# Find generated class
find target -name "*Repository*Implementation*"

# Decompile with javap
javap -p -c \
  target/classes/\
  com/example/$OrderRepository$Intercepted.class
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

You can see the exact SQL Micronaut will use without
running the application. Useful for debugging unexpected
query behavior.

*What separates good from great:* Inspect the
generated SQL at compile time - no need to run the app.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Repository interface, @Query, @Join, pagination. |
| Hiring Manager | Compile-time repositories = faster startup. |
| Bar Raiser | N+1 solutions, dirty tracking absence, JDBC vs JPA trade-off. |
| Peer Engineer | "Moved from JPA to Micronaut Data JDBC for our read-heavy service. Query latency dropped 30%. Added explicit update() calls - small change, big win." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Data JPA

**Interview Weight:** high - Many Micronaut applications
use JPA for complex domain models. Tested for integration
differences vs Spring Data JPA.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut Data JPA extends the Micronaut Data JDBC
> approach to JPA: repository interfaces are still
> generated at compile time, but the implementation
> delegates to Hibernate (or EclipseLink). JPA entities
> work as normal (@Entity, @OneToMany, etc.). The key
> difference from Spring Data JPA: Micronaut generates
> the repository class at compile time rather than
> creating a JDK proxy at runtime. Startup is faster.
> GraalVM native works with less configuration.

**3 minutes (Senior):**

> Micronaut Data JPA vs Spring Data JPA:
>
> Spring Data JPA:
>   Repository proxies created at runtime via reflection.
>   Hibernate Session created at startup (schema
>     validation, proxy class generation).
>   ClassLoader-intensive startup.
>
> Micronaut Data JPA:
>   Repository class generated at compile time.
>   Hibernate still used (entity proxies, lazy loading,
>     dirty checking, L2 cache - all present).
>   Startup: only Hibernate session factory (no
>     additional proxy generation).
>
> Repository definition:
>   interface OrderRepository
>     extends JpaRepository<Order, Long>
>   Same method names, same @Query syntax.
>
> JPA entity features (all present):
>   @OneToMany, @ManyToOne, @ManyToMany with lazy/eager
>   @EntityListeners (lifecycle callbacks)
>   @Cache (second level cache via Ehcache/Caffeine)
>   @Version (optimistic locking)
>   @NamedQuery, @NamedNativeQuery
>
> Configuration:
>   jpa.default.entity-scan.packages: list your packages
>   datasources.default: JDBC config
>   jpa.default.properties.hibernate.hbm2ddl.auto: validate/update

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about using JPA with
Micronaut - the full Hibernate ORM stack."

**(2) First principles:** "JPA = standard Java persistence
API backed by Hibernate. Micronaut Data wraps JPA
repositories with compile-time generation."

**(3) Bridge:** "Micronaut Data JPA gives you Hibernate
with compile-time repository generation. Spring Data
JPA gives you Hibernate with runtime proxy generation.
Same Hibernate, different plumbing."

---

### 💻 Code Example

```java
// JPA Entity (same as Spring)
@Entity
@Table(name="orders")
@Cache(usage=CacheConcurrencyStrategy.READ_WRITE)
public class Order {

    @Id
    @GeneratedValue(strategy=GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch=FetchType.LAZY)
    @JoinColumn(name="customer_id")
    private Customer customer;

    @OneToMany(
        mappedBy="order",
        cascade=CascadeType.ALL,
        orphanRemoval=true,
        fetch=FetchType.LAZY)
    private List<OrderItem> items =
        new ArrayList<>();

    @Version
    private Long version;  // Optimistic locking

    @CreatedDate
    private Instant createdAt;
}

// Repository: extends JpaRepository
@Repository
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    // Method name → JPQL
    List<Order> findByCustomerId(Long customerId);

    // JPQL query
    @Query("""
        SELECT DISTINCT o FROM Order o
        JOIN FETCH o.items i
        WHERE o.customer.id=:customerId
          AND o.status=:status
        """)
    List<Order> findWithItemsByCustomerAndStatus(
        @Parameter Long customerId,
        @Parameter OrderStatus status);

    // Pagination
    Page<Order> findByStatus(
        OrderStatus status,
        Pageable pageable);
}

// application.yml
// datasources:
//   default:
//     url: ${JDBC_URL}
//     username: ${DB_USER}
//     password: ${DB_PASS}
//     driver-class-name: org.postgresql.Driver
// jpa:
//   default:
//     entity-scan:
//       packages: com.example.domain
//     properties:
//       hibernate.hbm2ddl.auto: validate
//       hibernate.dialect: PostgreSQLDialect
//       hibernate.format_sql: true
```

> **Code walkthrough:** The @Entity and @OneToMany are
> standard JPA. @Cache(READ_WRITE) enables Hibernate
> L2 cache for Order entities - frequently-accessed
> orders served from memory. @Version provides optimistic
> locking - concurrent updates throw OptimisticLockException.
> The JOIN FETCH in @Query prevents N+1 for items.
> The repository extends JpaRepository which Micronaut
> Data implements at compile time, not runtime.

---

### 🎓 Answers by Seniority

**Junior:** "Micronaut Data JPA uses @Entity and extends
JpaRepository. Same as Spring Data JPA but the repository
implementation is generated at compile time."

**Senior:** "The main difference from Spring: repository
generated at compile time (not a JDK proxy). Hibernate
itself is unchanged - L2 cache, lazy loading, dirty
checking, optimistic locking all work identically.
For Micronaut Native: Hibernate has GraalVM support
since Hibernate 6.2. Reflection config mostly auto-generated."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Repository differences, entity lifecycle, L2 cache |
| Staff | 12 min | JPA vs JDBC trade-offs, native image with Hibernate |

---

**[SENIOR] Q1 - How does @Transactional work in
Micronaut Data JPA?**

*Why they ask:* Transaction management is critical.

Micronaut @Transactional (from micronaut-data-tx):
- Implemented via compile-time AOP (not Spring AOP)
- @Transactional at class level: all public methods
  are transactional
- Propagation/isolation: same semantics as Spring

Key difference from Spring:
- Self-invocation WORKS in Micronaut (compile-time
  interceptor, not proxy-based). Calling @Transactional
  method from same class creates a transaction.

```java
@Singleton
public class OrderService {

    @Transactional
    public Order createOrder(CreateOrderRequest req) {
        Order order = repo.save(
            Order.from(req));
        // Calling another @Transactional method
        inventoryService.reserve(req);
        // WORKS: joins existing transaction
        return order;
    }

    @Transactional(readOnly = true)
    public Optional<Order> findById(Long id) {
        // Read-only: no dirty checking flush
        // Performance optimization for queries
        return repo.findById(id);
    }

    @Transactional(
        propagation=Propagation.REQUIRES_NEW)
    public void logAudit(AuditEntry entry) {
        // New transaction: commits independently
        // Original transaction not affected if this fails
        auditRepo.save(entry);
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

readOnly=true optimization: Hibernate skips dirty
checking and flush at transaction end. Saves time
for read-heavy operations.

*What separates good from great:* Self-invocation works
in Micronaut @Transactional because it's compile-time
AOP. Spring requires self-injection workaround.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | JpaRepository, @Query, compile-time generation. |
| Hiring Manager | Full JPA for complex domain models. |
| Bar Raiser | Compile-time vs runtime repository, @Transactional self-invocation, native image. |
| Peer Engineer | "Micronaut Data JPA: 60% faster startup than Spring Data JPA on the same Hibernate config." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Data Repositories and Criteria

**Interview Weight:** high - Dynamic queries and
criteria-based filtering are common production needs.
Tested for Micronaut's approach to dynamic queries.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut Data supports Criteria API for dynamic
> queries where conditions are not known at compile
> time. JpaSpecificationExecutor (similar to Spring)
> allows building predicates programmatically. For
> simpler dynamic queries, use @Query with nullable
> parameters. For complex dynamic SQL, use a custom
> repository implementation with EntityManager.

**3 minutes (Senior):**

> Dynamic query options in Micronaut Data:
>
> Option 1: @Where annotation for conditional filters
>   @Where("status = 'ACTIVE'")
>   Applied globally to all queries on the entity.
>
> Option 2: Nullable parameters with @Query
>   @Query("SELECT o FROM Order o
>           WHERE (:status IS NULL
>                  OR o.status = :status)")
>   List<Order> findFiltered(
>     @Nullable String status);
>
> Option 3: Criteria Specification
>   Extend JpaSpecificationExecutor<T>
>   Build predicates with JPA Criteria API
>   Compose multiple predicates for complex filters
>
> Option 4: Custom repository implementation
>   Create OrderRepositoryCustom interface
>   Implement with EntityManager injection
>   Build CriteriaQuery programmatically
>   Extend both JpaRepository and custom interface
>
> Type-safe criteria (Micronaut Data 4+):
>   TypedSpecification<T> for compile-time checked
>   criteria expressions.
>
> Projections:
>   Return DTO instead of entity from @Query
>   @Query("SELECT new OrderSummaryDto(o.id, o.status)
>           FROM Order o")
>   Avoids loading full entity for list views.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about dynamic queries
in Micronaut Data - building conditions at runtime."

**(2) First principles:** "Some queries can't be written
at compile time because the conditions depend on
user input. Criteria API builds the query programmatically."

**(3) Bridge:** "Criteria-based queries in Micronaut
are like SQL WHERE clause builders: add conditions
as objects, Micronaut assembles the SQL."

---

### 💻 Code Example

```java
// Simple nullable filter
@Repository
public interface OrderRepository
        extends JpaRepository<Order, Long>,
                JpaSpecificationExecutor<Order> {

    // Nullable parameter: omits condition if null
    @Query("""
        SELECT o FROM Order o
        WHERE (:customerId IS NULL
               OR o.customer.id = :customerId)
          AND (:status IS NULL
               OR o.status = :status)
          AND (:since IS NULL
               OR o.createdAt >= :since)
        """)
    Page<Order> searchOrders(
        @Nullable @Parameter Long customerId,
        @Nullable @Parameter String status,
        @Nullable @Parameter Instant since,
        Pageable pageable);
}

// Specification-based dynamic criteria
public class OrderSpecifications {

    public static PredicateSpecification<Order>
            hasStatus(OrderStatus status) {
        return (root, criteriaBuilder) ->
            criteriaBuilder.equal(
                root.get("status"), status);
    }

    public static PredicateSpecification<Order>
            belongsToCustomer(Long customerId) {
        return (root, criteriaBuilder) ->
            criteriaBuilder.equal(
                root.get("customer")
                    .get("id"), customerId);
    }

    public static PredicateSpecification<Order>
            createdAfter(Instant since) {
        return (root, criteriaBuilder) ->
            criteriaBuilder.greaterThan(
                root.get("createdAt"), since);
    }
}

// Usage: compose specifications
@Singleton
public class OrderSearchService {

    private final OrderRepository repo;

    public Page<Order> search(
            OrderSearchRequest req,
            Pageable pageable) {

        PredicateSpecification<Order> spec =
            where(null);  // start with no condition

        if (req.getStatus() != null) {
            spec = spec.and(
                hasStatus(req.getStatus()));
        }
        if (req.getCustomerId() != null) {
            spec = spec.and(
                belongsToCustomer(
                    req.getCustomerId()));
        }
        if (req.getSince() != null) {
            spec = spec.and(
                createdAfter(req.getSince()));
        }

        return repo.findAll(spec, pageable);
    }
}

// DTO Projection: avoid loading full entity
@Query("""
    SELECT new io.example.dto.OrderSummary(
        o.id, o.status, o.totalAmount,
        c.name, c.email)
    FROM Order o
    JOIN o.customer c
    WHERE o.customer.id = :customerId
    """)
List<OrderSummary> findSummariesByCustomer(
    @Parameter Long customerId);
```

> **Code walkthrough:** The nullable parameter pattern
> uses SQL's `:param IS NULL OR column = :param` to
> conditionally include the filter. When customerId is
> null, `null IS NULL` is true, so the condition is
> effectively skipped. PredicateSpecification compose
> with .and()/.or() for complex runtime conditions.
> The DTO projection uses the JPA constructor expression
> to map query results directly to OrderSummary without
> loading the full Order entity.

---

### 🎓 Answers by Seniority

**Junior:** "For dynamic queries: @Query with nullable
parameters for simple cases, or implement JpaSpecificationExecutor
for programmatic criteria."

**Senior:** "The nullable parameter pattern is the
simplest dynamic query approach - no criteria API
overhead. For complex multi-condition search: Specification
composition is cleaner than @Query strings. DTO projections
(constructor expressions) are critical for list endpoints
where loading full entities with lazy associations
would be wasteful."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Nullable parameters, Specification, DTO projections |
| Staff | 12 min | Type-safe criteria, performance implications |

---

**[SENIOR] Q1 - What is the N+1 risk when using
Specification-based queries with JPA entities that
have @OneToMany?**

*Why they ask:* Production data access bugs.

Specification queries return a List<Order>. If Order
has @OneToMany List<OrderItems> with LAZY fetch:
- Accessing items for each order = 1 SQL per order.
- 100 orders = 101 SQL queries.

Fix: add FETCH JOIN to the specification:
```java
public static PredicateSpecification<Order>
        withItems() {
    return (root, cb) -> {
        root.fetch("items", JoinType.LEFT);
        return cb.conjunction();
        // No predicate, just forces fetch join
    };
}

// Combine with other specs:
spec = spec.and(withItems())
           .and(hasStatus(PENDING));
// Generates SELECT with JOIN FETCH items
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Or: use @EntityGraph on the repository method:
```java
@EntityGraph(attributePaths={"items"})
Page<Order> findAll(
    PredicateSpecification<Order> spec,
    Pageable pageable);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* FETCH JOIN inside
the specification (not just in the predicate). And
@EntityGraph as an alternative.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Nullable params, Specification, projections. |
| Hiring Manager | Dynamic search for REST APIs. |
| Bar Raiser | N+1 with Specification, @EntityGraph, DTO projection for list performance. |
| Peer Engineer | "Added constructor projection to the order list endpoint. DB reads dropped from 150ms to 20ms." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Transaction Management

**Interview Weight:** critical - Transaction handling
is non-negotiable for production applications. Tested
deeply at senior level.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut @Transactional uses compile-time AOP to
> wrap methods in a transaction. Key properties:
> propagation (REQUIRED default, REQUIRES_NEW,
> SUPPORTS), isolation (defaults to DB default),
> readOnly (optimization for reads). Micronaut's AOP
> means self-invocation works - no Spring proxy gotcha.
> For programmatic control: inject TransactionOperations
> and use execute(callback).

**3 minutes (Senior):**

> Transaction propagation:
>
> REQUIRED (default): join existing or create new.
>   Most common. Use for business methods.
>
> REQUIRES_NEW: always create new transaction.
>   Suspends current. Use for audit logging, events
>   that must commit regardless of caller transaction.
>
> SUPPORTS: join if exists, else no transaction.
>   Use for read-only service methods that can
>   optionally participate in transactions.
>
> MANDATORY: must join existing transaction.
>   Throws if none exists. Use to enforce caller
>   must provide a transaction context.
>
> NOT_SUPPORTED: run without transaction.
>   Suspends current if any. Use for non-transactional
>   operations that must not participate.
>
> NEVER: must run without transaction.
>   Throws if a transaction is active.
>
> Isolation levels (review, set sparingly):
>   READ_UNCOMMITTED: dirty reads possible (avoid)
>   READ_COMMITTED: default for most DBs
>   REPEATABLE_READ: consistent reads within transaction
>   SERIALIZABLE: full isolation (performance cost)
>
> Programmatic:
>   TransactionOperations.execute(status -> { ... })
>   Useful when method boundaries don't align with
>   transaction boundaries.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about transaction
management in Micronaut - how to ensure atomicity
of data operations."

**(2) First principles:** "Transaction = multiple
operations that succeed or fail together. Propagation =
what to do when a transaction already exists."

**(3) Bridge:** "Micronaut @Transactional is Spring
@Transactional with one key improvement: self-invocation
works because AOP is compile-time."

---

### 💻 Code Example

```java
// BAD: transaction not covering all operations
@Singleton
public class OrderService {
    void processOrder(Long id) {
        Order order = repo.findById(id)
            .orElseThrow();
        // Not @Transactional:
        // deductStock and createShipment are
        // in separate transactions
        // If createShipment fails, stock already deducted
        inventoryService.deductStock(id);
        shipmentService.createShipment(id);
    }
}

// GOOD: single transaction covering all operations
@Singleton
public class OrderService {

    @Transactional
    public void processOrder(Long id) {
        Order order = repo.findById(id)
            .orElseThrow();
        // All three ops in ONE transaction
        order.setStatus(PROCESSING);
        repo.update(order);
        inventoryService.deductStock(id);
        // deductStock is @Transactional(REQUIRED)
        // joins THIS transaction
        shipmentService.createShipment(id);
        // createShipment joins this transaction too
        // If any fails: ALL roll back
    }

    // Audit log MUST commit independently
    @Transactional(propagation=Propagation.REQUIRES_NEW)
    public void auditProcessed(Long orderId) {
        // Always commits even if outer tx rolls back
        // Use for: audit logs, external event publishing
        auditRepo.save(
            new AuditEntry("PROCESSED", orderId));
    }

    // Read-only optimization
    @Transactional(readOnly = true)
    public Page<Order> listForCustomer(
            Long customerId,
            Pageable pageable) {
        // readOnly=true:
        // - Hibernate skips dirty-check flush
        // - Database hint: read replica routing possible
        return repo.findByCustomerId(
            customerId, pageable);
    }

    // Programmatic transaction
    public void bulkProcess(
            List<Long> orderIds,
            TransactionOperations<?> tx) {

        orderIds.forEach(id ->
            tx.execute(status -> {
                try {
                    processOrder(id);
                } catch (Exception e) {
                    status.setRollbackOnly();
                    log.error(
                        "Failed: {}", id, e);
                }
                return null;
            })
        );
    }
}
```

> **Code walkthrough:** The BAD case has no @Transactional:
> each service call runs in its own transaction. If
> createShipment throws, inventory is already deducted
> with no rollback. The GOOD case wraps all three ops
> in one transaction - all roll back on failure. REQUIRES_NEW
> for audit: commits independently even if the caller
> rolls back. readOnly=true skips Hibernate's dirty
> checking at flush time - important for list queries.

---

### ⚠️ Common Misconceptions

**"@Transactional on a private method works in Micronaut":**
@Transactional requires the method to be visible to
the generated AOP wrapper. Private methods are NOT
intercepted. Use package-private or protected.

**"Checked exceptions don't cause rollback":**
By default, only unchecked exceptions (RuntimeException)
cause rollback. Use @Transactional(rollbackFor=
MyCheckedException.class) for checked exceptions.

---

### 🚨 Failure Modes and Diagnosis

**Symptoms and Fixes:**

1. "no transaction is in progress":
   - Cause: @Transactional not applied (private method,
     not going through DI)
   - Fix: verify method is not private; verify bean is
     injected (not newed)
   - Debug: enable transaction logging:
     logging.level.io.micronaut.transaction=DEBUG

2. Data not persisted after method completes:
   - Cause: no @Transactional; session closed before flush
   - Fix: add @Transactional to service method
   - Also: verify repo.save/update called explicitly
     for JDBC (no dirty checking)

3. Transaction spans too long (lock contention):
   - Cause: slow operations inside @Transactional
     (HTTP calls, file I/O)
   - Fix: move slow ops outside transaction
   - Pattern: prepare → open tx → data ops → commit → send

---

### 🎓 Answers by Seniority

**Junior:** "@Transactional makes a method transactional.
REQUIRED joins existing transaction. REQUIRES_NEW
creates a new one."

**Senior:** "Never put HTTP calls or slow I/O inside
a @Transactional method - it holds a DB connection
for the duration. readOnly=true is a free optimization
for all query methods. Private @Transactional methods
don't work (not intercepted by compile-time AOP)."

**Staff:** "Transaction boundary design is architecture:
the aggregate root's service method should be the
transaction boundary. If your transaction touches
multiple aggregates, that's a design signal to use
eventual consistency (outbox pattern, domain events)
instead of a distributed transaction."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 8 min | Propagation, isolation, readOnly, failure modes |
| Staff | 12 min | Transaction boundaries, outbox pattern, saga, lock contention |

---

**[SENIOR] Q1 - How do you implement the transactional
outbox pattern in Micronaut?**

*Why they ask:* Event-driven architecture with guaranteed
delivery.

Problem: persist an order AND publish a domain event.
If the event publish fails after commit, event is lost.
If we publish before commit, event fires for a rolled-back order.

Transactional Outbox:
1. Within the same transaction: INSERT order + INSERT outbox record.
2. Separate poller: reads outbox table, publishes event,
   marks as published.
3. If publisher fails: poller retries (idempotent consumers).

```java
@Transactional
public Order createOrder(CreateOrderRequest req) {
    Order order = repo.save(Order.from(req));

    // Same transaction: outbox record
    outboxRepo.save(new OutboxEvent(
        "ORDER_CREATED",
        objectMapper.writeValueAsString(order),
        order.getId()
    ));

    return order;
    // Both commit together
}

// Poller (separate scheduled service)
@Scheduled(fixedDelay = "1s")
@Transactional
public void processOutbox() {
    List<OutboxEvent> pending =
        outboxRepo.findByPublishedFalse();
    pending.forEach(event -> {
        eventPublisher.publish(event);
        event.setPublished(true);
        outboxRepo.update(event);
    });
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Outbox is a pattern,
not a feature. The transactional guarantee comes from
writing to the DB in the same transaction.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Propagation semantics, isolation levels, @Transactional self-invocation. |
| Hiring Manager | Transaction = data integrity. |
| Bar Raiser | REQUIRES_NEW for audit, readOnly optimization, outbox pattern, lock contention. |
| Peer Engineer | "Moved event publishing from inside the transaction to the outbox poller. Lost zero events in the last 6 months." |

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Micronaut Data Reactive Repositories

**Interview Weight:** high - Reactive data access
is required for full non-blocking Micronaut apps.
Tested for when to use reactive repositories and
how to integrate with R2DBC.

---

### 🎯 Model Answer

**30 seconds:**

> Micronaut Data supports reactive repositories via
> R2DBC (Reactive Relational Database Connectivity).
> Repository methods return Mono<T>, Flux<T>, Single<T>,
> or Flowable<T>. The entire request-to-database path
> is non-blocking - no threads blocked on I/O.
> Reactive repositories work only with R2DBC drivers
> (no blocking JDBC). Use reactive when your service
> is fully reactive; use JDBC with @Blocking for
> mixed codebases.

**3 minutes (Senior):**

> Reactive repository options:
>
> ReactiveStreamsCrudRepository<T,ID>:
>   findById returns Mono<T>
>   findAll returns Flux<T>
>   save returns Mono<T>
>
> RxJavaCrudRepository<T,ID>:
>   findById returns Maybe<T>
>   findAll returns Flowable<T>
>   save returns Single<T>
>
> Transaction management (reactive):
>   @Transactional works with reactive repositories.
>   Transaction bound to reactive chain, not thread.
>   Uses R2DBC transaction context.
>
> R2DBC configuration:
>   r2dbc.datasources.default.url=
>     r2dbc:postgresql://host/db
>   r2dbc.datasources.default.username=
>   r2dbc.datasources.default.password=
>
> Reactive vs JDBC trade-offs:
>   Reactive: high concurrency, non-blocking
>     - but: more complex code
>     - but: R2DBC ecosystem smaller than JDBC
>     - but: no JPA lazy loading support
>   JDBC + @Blocking: simpler code, well-tested
>     - but: threads blocked on I/O
>     - but: limits concurrent requests
>
> When to use reactive:
>   Expected concurrency > thread pool size (typically 200)
>   WebSocket or SSE endpoints
>   Streaming large result sets
>   Gateway services (many upstream calls)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about reactive data
access in Micronaut - non-blocking database queries."

**(2) First principles:** "Non-blocking DB = thread not
stuck waiting for query result. Thread free to handle
other requests while DB executes."

**(3) Bridge:** "Reactive repositories with R2DBC are
like reactive HTTP clients: you describe the operations,
and Micronaut executes them non-blocking."

---

### 💻 Code Example

```java
// R2DBC Entity (same @MappedEntity)
@MappedEntity("orders")
public class Order {
    @Id
    @GeneratedValue
    private Long id;
    private Long customerId;
    private BigDecimal totalAmount;
    private String status;
    // getters, setters
}

// Reactive repository
@Repository
public interface OrderRepository
        extends ReactiveStreamsCrudRepository<
            Order, Long> {

    // Returns Flux for multiple results
    Flux<Order> findByStatus(String status);

    // Returns Mono for single result
    Mono<Order> findByIdAndCustomerId(
        Long id, Long customerId);

    // Custom reactive query
    @Query("SELECT * FROM orders " +
           "WHERE customer_id=:customerId " +
           "ORDER BY created_at DESC " +
           "LIMIT :limit")
    Flux<Order> findRecentByCustomer(
        @Parameter Long customerId,
        @Parameter int limit);

    // Count
    Mono<Long> countByStatus(String status);
}

// Reactive service
@Singleton
public class OrderService {

    private final OrderRepository repo;

    OrderService(OrderRepository repo) {
        this.repo = repo;
    }

    public Mono<Order> findByIdAndCustomer(
            Long id, Long customerId) {
        return repo.findByIdAndCustomerId(
                id, customerId)
            .switchIfEmpty(
                Mono.error(new NotFoundException(id)));
    }

    // Reactive transaction
    @Transactional
    public Mono<Order> createOrder(
            CreateOrderRequest req) {
        Order order = new Order();
        order.setCustomerId(req.getCustomerId());
        order.setTotalAmount(req.getTotal());
        order.setStatus("PENDING");
        return repo.save(order);
        // Transaction committed when Mono completes
    }

    // Composing multiple reactive operations
    public Flux<OrderSummary> getCustomerSummary(
            Long customerId) {
        return repo.findRecentByCustomer(
                customerId, 100)
            .map(order -> OrderSummary.from(order))
            .onErrorResume(e -> {
                log.error(
                    "Error loading orders", e);
                return Flux.empty();
            });
    }
}

// Reactive controller
@Controller("/orders")
public class OrderController {

    private final OrderService service;

    @Get("/{id}")
    public Mono<HttpResponse<OrderDto>> findById(
            @PathVariable Long id,
            @QueryValue Long customerId) {
        return service
            .findByIdAndCustomer(id, customerId)
            .map(o -> HttpResponse.ok(
                OrderDto.from(o)))
            .defaultIfEmpty(
                HttpResponse.notFound());
    }

    @Get("/stream")
    @Produces(MediaType.APPLICATION_NDJSON)
    public Flux<OrderDto> stream(
            @QueryValue String status) {
        return service.streamByStatus(status)
            .map(OrderDto::from);
    }
}
```

> **Code walkthrough:** ReactiveStreamsCrudRepository
> provides reactive CRUD with Mono/Flux return types.
> All operations are non-blocking via R2DBC. @Transactional
> on Mono<Order> creates a reactive transaction - the
> transaction commits when the Mono completes, not when
> the method returns. switchIfEmpty() replaces Optional's
> map/orElseThrow pattern for reactive streams.
> The streaming endpoint returns Flux<OrderDto> directly -
> Netty writes each element as it arrives without buffering.

---

### ⚠️ Common Misconceptions

**"Reactive is always faster than JDBC":**
Not true. Reactive reduces thread usage under high
concurrency but doesn't reduce query latency.
For a service handling 100 req/s with 50ms queries:
JDBC with 20 threads is fine. Reactive helps at
10,000+ concurrent connections.

**"@Transactional works the same with reactive":**
Reactive @Transactional binds to the reactive chain,
not to a thread. Subscribing to the same Mono multiple
times creates multiple transactions. Always return the
reactive chain from @Transactional methods.

---

### 🎓 Answers by Seniority

**Junior:** "Reactive repositories return Mono/Flux.
Configure R2DBC instead of JDBC. @Transactional
still works."

**Senior:** "Use reactive when concurrent request
count exceeds your thread pool size (typically 200+).
R2DBC ecosystem is smaller than JDBC (fewer drivers,
less tooling). For services that are mostly read-heavy
with simple queries: reactive is often over-engineering."

**Staff:** "The decision: how many concurrent requests?
For most microservices: 50-500 concurrent, JDBC +
@Blocking is sufficient. Beyond 1000 concurrent (API
gateway, real-time services): reactive provides
tangible scaling. The code complexity cost of reactive
is real - weigh it against the actual concurrency
requirement."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Reactive repository types, @Transactional reactive, R2DBC config |
| Staff | 12 min | Reactive vs JDBC decision, backpressure, error handling |

---

**[STAFF] Q1 - How do you decide between reactive
repositories and JDBC + @Blocking for a new service?**

*Why they ask:* Architecture decision framework question.

Decision criteria:

1. Expected concurrent connections:
   - < 500: JDBC + thread pool is fine
   - 500-2000: either works, JDBC simpler
   - > 2000: reactive advantages clear

2. Code complexity budget:
   - Team unfamiliar with reactive: JDBC
   - Team with reactive experience: either

3. Upstream dependencies:
   - All dependencies are reactive: go reactive
   - Mixing reactive and blocking: use @Blocking

4. Use case type:
   - REST CRUD API: JDBC fine
   - WebSocket/SSE/real-time: reactive preferred
   - Stream processing: reactive required
   - Gateway aggregating many services: reactive preferred

5. R2DBC driver support:
   - PostgreSQL, MySQL, H2: good R2DBC support
   - Oracle, SQLServer: check R2DBC driver maturity

Decision matrix summary:
```
Concurrency > 2000  AND  Team knows reactive  AND
R2DBC driver stable → Reactive

Otherwise → JDBC + @Blocking
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Start with JDBC. Migrate to reactive if profiling
shows thread exhaustion under load.

*What separates good from great:* Not dogmatically
choosing reactive. Data-driven decision based on actual
concurrency requirements.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | ReactiveStreamsCrudRepository, R2DBC config, reactive chain. |
| Hiring Manager | Non-blocking for scalable services. |
| Bar Raiser | Reactive vs JDBC decision framework, @Transactional reactive semantics, backpressure. |
| Peer Engineer | "Added @Blocking to JDBC repositories first. Only migrated to R2DBC when profiling showed 400 threads blocked under peak load." |

---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*



