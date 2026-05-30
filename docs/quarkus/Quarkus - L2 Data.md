---
layout: default
title: "Quarkus - L2 Data"
parent: "Quarkus"
grand_parent: "SK Interview"
nav_order: 3
permalink: /quarkus/l2-data/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Quarkus Hibernate ORM and Panache](#quarkus-hibernate-orm-and-panache) | critical |
| 2 | [Quarkus Panache Active Record Pattern](#quarkus-panache-active-record-pattern) | medium |
| 3 | [Quarkus Hibernate Reactive](#quarkus-hibernate-reactive) | high |
| 4 | [Quarkus Flyway and Liquibase](#quarkus-flyway-and-liquibase) | medium |
| 5 | [Quarkus Redis and Caching](#quarkus-redis-and-caching) | medium |

---

# Quarkus Hibernate ORM and Panache

**Interview Weight:** critical - Panache is Quarkus's
primary ORM abstraction. Tested in every data-focused
interview.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus Hibernate ORM + Panache provides two patterns:
> Active Record (entity inherits PanacheEntity, exposes
> static persist/find/list methods) and Repository
> (PanacheRepository implementation injected as CDI bean).
> Panache simplifies Hibernate by generating common
> methods. Under the hood: full JPA/Hibernate with
> @Entity annotations, relationships, cascades, and
> second-level cache. Transactions via @Transactional
> (compile-time AOP).

**3 minutes (Senior):**

> Active Record pattern:
>
> @Entity
> class Order extends PanacheEntity {
>   Long customerId;
>   String status;
>
>   // Static methods via Panache:
>   static Order findByCustomerId(Long id) {}
>   static List<Order> listByStatus(String s) {}
> }
>
> Usage:
>   Order.persist(order);
>   Order.findById(1L);
>   Order.listAll();
>   Order.findByCustomerId(42L);
>   long count = Order.count("status", "PENDING");
>
> Repository pattern (separation of concerns):
>
> @Entity class Order { ... }  // POJO entity
>
> @ApplicationScoped
> class OrderRepository
>     implements PanacheRepository<Order> {
>   List<Order> findByStatus(String s) {
>     return list("status", s);
>   }
> }
>
> Panache queries:
>   Simplified HQL: list("status=?1", "PENDING")
>   Named params: find("status=:s", "s", "PENDING")
>   Raw JPQL: @Query or .find(jpql)
>   Stream: stream("status", "PENDING")
>     (lazy, must be within @Transactional)
>
> PanacheEntityBase:
>   For entities with custom @Id type.
>   PanacheEntity uses auto-generated Long id.
>   PanacheEntityBase: custom id type.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about data access in
Quarkus using Hibernate ORM and Panache."

**(2) First principles:** "ORM = map Java objects to
database rows. Panache = simpler API on top of JPA."

**(3) Bridge:** "Panache Active Record is like Spring
Data JPA's JpaRepository methods available as static
methods on the entity itself."

---

### 💻 Code Example

```java
// Active Record Pattern
@Entity
@Table(name = "orders")
public class Order extends PanacheEntity {
    // PanacheEntity provides:
    // Long id (auto-generated)
    // persist(), persistAndFlush()
    // static find, list, stream, count, delete, update

    @Column(name = "customer_id")
    public Long customerId;

    @Column(nullable = false)
    public String status;

    @Column(name = "total_amount")
    public BigDecimal totalAmount;

    @CreatedTimestamp
    public Instant createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id",
                insertable = false,
                updatable = false)
    public Customer customer;

    // Named query methods (optional helpers)
    public static List<Order> findByStatus(
            String status) {
        return list("status", status);
    }

    public static Order findByIdAndCustomer(
            Long id, Long customerId) {
        return find("id=?1 and customerId=?2",
            id, customerId)
            .firstResultOptional()
            .orElseThrow(() ->
                new NotFoundException(id));
    }

    public static long countPending() {
        return count("status", "PENDING");
    }

    public static void cancelByCustomer(
            Long customerId) {
        update("status='CANCELLED' " +
               "where customerId=?1 " +
               "and status='PENDING'",
               customerId);
    }
}

// Service using Active Record
@ApplicationScoped
public class OrderService {

    @Transactional
    public Order createOrder(
            CreateOrderRequest req) {
        Order order = new Order();
        order.customerId = req.getCustomerId();
        order.totalAmount = req.getTotal();
        order.status = "PENDING";
        order.persist();  // INSERT
        return order;
    }

    public Page<Order> findPaged(
            String status, int page, int size) {
        return Order.find("status", status)
            .page(page, size);
    }

    @Transactional
    public Order updateStatus(
            Long id, String newStatus) {
        Order order = Order.findById(id);
        if (order == null) {
            throw new NotFoundException(id);
        }
        order.status = newStatus;
        // No explicit save needed - dirty checking
        return order;
    }
}

// Repository Pattern (alternative)
@ApplicationScoped
public class OrderRepository
        implements PanacheRepository<Order> {

    public List<Order> findByCustomerId(
            Long customerId) {
        return list("customerId", customerId);
    }

    public Optional<Order> findByIdAndCustomer(
            Long id, Long customerId) {
        return find(
            "id=?1 and customerId=?2",
            id, customerId)
            .firstResultOptional();
    }

    public Page<Order> searchByStatus(
            String status, int page, int size) {
        return find("status", Sort.by("createdAt")
            .descending(), status)
            .page(page, size);
    }
}

// Using repository
@ApplicationScoped
public class OrderService {

    @Inject
    OrderRepository orderRepo;

    @Transactional
    public Order createOrder(
            CreateOrderRequest req) {
        Order order = Order.from(req);
        orderRepo.persist(order);
        return order;
    }
}
```

> **Code walkthrough:** PanacheEntity provides the Long
> id field and all static methods (find, list, count,
> persist, update, delete). The Active Record static methods
> use Panache's simplified HQL: "status" (field name),
> not "o.status" (table column). Dirty checking works
> in Active Record: modifying order.status inside @Transactional
> automatically generates an UPDATE at flush. The Repository
> pattern injects OrderRepository as a CDI bean - cleaner
> for testing (can mock the repository).

---

### ⚖️ Comparison Table

| Aspect | Active Record | Repository |
|---|---|---|
| Query location | Static methods on entity | Repository CDI bean |
| Testing | Requires DB or mock | Mock repository |
| Separation | Entity has data + query logic | Separate concerns |
| Hibernate features | Full JPA | Full JPA |
| Mutiny support | PanacheEntity with Reactive | PanacheRepository Reactive |
| Style familiarity | Ruby on Rails | Spring Data JPA |

---

### 🚨 Failure Modes and Diagnosis

**Symptoms and Fixes:**

1. "LazyInitializationException" accessing lazy relation:
   - Outside transaction: Hibernate session closed.
   - Fix: either join fetch, or annotate
     @Transactional on service method.

2. N+1 queries:
   - Order.listAll() then accessing order.customer
   - Fix: Order.find(...).query()
     .setHint("javax.persistence.fetchgraph", ...)
   - Or: HQL with JOIN FETCH

3. Panache update not persisted:
   - No @Transactional on service method.
   - Fix: add @Transactional.

---

### 🎓 Answers by Seniority

**Junior:** "Extend PanacheEntity for Active Record
pattern. Use PanacheRepository for repository pattern.
@Transactional on service methods."

**Senior:** "Choose repository over active record for
complex domains where entities have a lot of behavior.
Active record is faster for CRUD-heavy services.
N+1 with Panache: use JOIN FETCH or .with(HintItems)
for eager loading. Dirty checking works in active
record: just modify the field inside @Transactional."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Active Record vs Repository, N+1, transactions |
| Staff | 12 min | Pattern selection, Panache internals, Reactive Panache |

---

**[SENIOR] Q1 - How do you prevent N+1 queries
with Panache active record?**

*Why they ask:* Most common ORM performance bug.

Scenario: List 100 orders, each accessing customer.name.
Active Record: 1 query for orders + 100 queries for customers.

Fix 1: HQL JOIN FETCH in find query:
```java
public static List<Order> findAllWithCustomers() {
    return list(
        "SELECT o FROM Order o " +
        "LEFT JOIN FETCH o.customer " +
        "ORDER BY o.createdAt DESC");
    // 1 query with JOIN
}
```

Fix 2: @EntityGraph:
```java
// Repository pattern
public List<Order> findAllWithCustomers() {
    return find("from Order o " +
                "order by o.createdAt")
        .withHint(
            "jakarta.persistence.fetchgraph",
            // @NamedEntityGraph on entity
            em.createEntityGraph("Order.withCustomer"))
        .list();
}
```

Fix 3: Batch loading:
Configure Hibernate batch loading in application.properties:
```properties
quarkus.hibernate-orm.batch-fetch-size=25
```
Hibernate loads lazy associations in batches of 25
instead of 1 at a time. Reduces N+1 to ceil(N/25)+1.

*What separates good from great:* batch-fetch-size as
a low-config fix that reduces N+1 without code changes.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Active Record vs Repository, Panache query API. |
| Hiring Manager | Simplified ORM for faster development. |
| Bar Raiser | N+1 prevention, dirty checking, Panache internals. |
| Peer Engineer | "Set batch-fetch-size=25. Order list endpoint: 200 SQL queries → 5 queries. No code change." |

---

---

# Quarkus Panache Active Record Pattern

**Interview Weight:** medium - Active Record is
Quarkus's distinctive data access pattern. Tested
for understanding and trade-offs.

---

### 🎯 Model Answer

**30 seconds:**

> Active Record pattern: the entity class contains both
> data fields AND data access methods. In Quarkus,
> extending PanacheEntity gives the entity class static
> methods: persist(), findById(), list(), count(),
> delete(). The entity is both the domain object and
> the DAO. This reduces boilerplate for CRUD operations
> but couples persistence logic to the domain model.

**3 minutes (Senior):**

> Panache Active Record in detail:
>
> PanacheEntity: provides Long id + all static methods.
> PanacheEntityBase<IdType>: custom id type.
>
> Key static methods:
>   persist(entity): INSERT
>   update("status=?1 where id=?2", s, id): UPDATE
>   delete("customerId", id): DELETE WHERE
>   findById(id): SELECT BY ID
>   find("field", value): SELECT WHERE
>   list("field", value): SELECT WHERE (all results)
>   stream("field", value): SELECT WHERE (lazy stream)
>   count("field", value): COUNT WHERE
>   listAll(): SELECT * (use carefully)
>   page(page, size): pagination
>
> Simplified HQL (Panache query language):
>   "status" - field name shorthand for "status=?1"
>   "status=?1 and createdAt>?2" - positional params
>   "status=:s and createdAt>:d" - named params
>     (use with Parameters.with("s","P").and("d", now))
>
> Sort:
>   Sort.by("createdAt").descending()
>   Sort.by("status").and("createdAt").descending()
>
> Panache query builder:
>   Order.find("status", status)
>        .page(page, size)
>        .sortBy(Sort.by("createdAt"))
>        .list()
>
> Active Record limitation:
>   No transaction management in the entity.
>   Must annotate service methods @Transactional.
>   Entity has no awareness of transaction context.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the Active Record
pattern in Quarkus Panache - how entity classes include
data access."

**(2) First principles:** "Active Record = data + behavior
in one class. Repository = data in one class, access
in another."

**(3) Bridge:** "Panache Active Record is like Rails'
ActiveRecord: Order.where(status: 'PENDING') is
Order.list('status', 'PENDING') in Panache."

---

### 💻 Code Example

```java
@Entity
public class Order extends PanacheEntity {

    public Long customerId;
    public String status;
    public BigDecimal totalAmount;
    public Instant createdAt;

    // Encapsulated query methods
    public static List<Order> findByCustomer(
            Long customerId) {
        return list("customerId", customerId);
    }

    public static Page<Order> findPaged(
            String status,
            int page,
            int size) {
        return find(
            "status",
            Sort.by("createdAt").descending(),
            status)
            .page(page, size);
    }

    public static Map<String, Long> countByStatus() {
        // Custom aggregate query
        return getEntityManager()
            .createQuery(
                "SELECT o.status, COUNT(o) " +
                "FROM Order o " +
                "GROUP BY o.status",
                Object[].class)
            .getResultStream()
            .collect(Collectors.toMap(
                r -> (String) ((Object[]) r)[0],
                r -> (Long) ((Object[]) r)[1]));
    }

    // Domain method
    public boolean isCancellable() {
        return "PENDING".equals(status) ||
               "CONFIRMED".equals(status);
    }

    public void cancel() {
        if (!isCancellable()) {
            throw new InvalidStateException(
                "Cannot cancel order in " + status);
        }
        this.status = "CANCELLED";
        // Dirty checking: UPDATE generated at flush
    }
}

// Service: provides transaction boundary
@ApplicationScoped
public class OrderCommandService {

    @Transactional
    public Order cancel(Long orderId) {
        Order order = Order.findById(orderId);
        if (order == null) {
            throw new NotFoundException(orderId);
        }
        order.cancel();  // Domain method
        // dirty checking: no explicit save needed
        return order;
    }

    @Transactional
    public void bulkComplete(List<Long> orderIds) {
        // Batch update: single SQL
        Order.update(
            "status='COMPLETED' " +
            "where id in ?1 " +
            "and status='PROCESSING'",
            orderIds);
    }
}
```

> **Code walkthrough:** PanacheEntity adds static methods
> to the entity class. The find/list methods use Panache's
> simplified HQL. countByStatus() uses getEntityManager()
> for arbitrary JPQL - available on any PanacheEntity.
> cancel() is a domain method that modifies the entity
> state; dirty checking generates the UPDATE at transaction
> commit - no explicit order.persist() needed. The bulk
> update (Order.update()) generates a single SQL UPDATE
> statement, not one per order.

---

### 🎓 Answers by Seniority

**Junior:** "Entity extends PanacheEntity. Use Order.list(),
Order.findById(), Order.persist() directly. No separate
DAO class needed."

**Senior:** "Active Record trade-off: entity knows about
its persistence. Clean for CRUD, problematic for complex
domains where the entity should be pure domain logic.
Choose: Active Record for data-centric CRUD services,
Repository for domain-rich services."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Active Record vs Repository, Panache query syntax |
| Staff | 8 min | Pattern selection, DDD alignment, transaction handling |

---

**[SENIOR] Q1 - How does Panache Active Record work
with DDD aggregates?**

*Why they ask:* Design pattern compatibility.

Tension: DDD aggregates should not expose persistence
directly. Active Record couples domain to persistence.

Reconciliation options:

Option 1: Thin Active Record (Quarkus recommendation):
Entity has data + simple query helpers. Complex domain
logic in a service class. Repository pattern for complex
aggregates.

Option 2: Rich domain model with Repository:
```java
// Pure domain entity
@Entity
public class OrderAggregate {
    @Id
    private UUID aggregateId;
    // No static methods
    // Domain logic only

    public void confirm() { ... }
    public void cancel() { ... }
}

// Repository: separate persistence
@ApplicationScoped
public class OrderAggregateRepository
        implements PanacheRepository<OrderAggregate> {
    // Only query methods
    // Entity has no persistence awareness
}
```

The Repository pattern in Panache supports full DDD
separation. Use Active Record for simpler CRUD entities.

*What separates good from great:* Pattern selection
based on domain complexity, not framework default.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Panache query API, Active Record vs Repository. |
| Hiring Manager | Panache simplifies ORM code. |
| Bar Raiser | DDD compatibility, bulk operations, dirty checking. |
| Peer Engineer | "We use Active Record for reference data entities and Repository for order aggregates. Best of both." |

---

---

# Quarkus Hibernate Reactive

**Interview Weight:** high - Reactive data access is
critical for non-blocking Quarkus applications.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus Hibernate Reactive uses R2DBC (reactive database
> driver) with Hibernate ORM to provide non-blocking
> database access. Repository methods return Uni<T>
> (SmallRye Mutiny) for single results and Multi<T>
> for streams. All operations are non-blocking - no
> thread blocked during DB I/O. Use Panache Reactive
> (PanacheEntity with reactive = true or PanacheReactiveRepository)
> for the same convenient API as blocking Panache.

**3 minutes (Senior):**

> Reactive Panache entity:
>
> @Entity
> class Order extends PanacheEntity {
>   // Same @Entity annotations
>   // Access via Hibernate Reactive session
>   // Not blocking JPA
> }
>
> Reactive repository:
>   PanacheReactiveRepository<Order>
>   find(), list() return Uni<List<T>>
>   findById() returns Uni<Order>
>   persist() returns Uni<Order>
>
> Reactive session management:
>   Must run within a reactive transaction.
>   @ReactiveTransactional: annotation for methods.
>   Hibernate.getReactiveSession(): programmatic.
>
> Mutiny operators for DB operations:
>   .onItem().transformToUni(): flatMap
>   .chain(): sequential operations
>   .combine().unis(): parallel operations
>
> Configuration differences:
>   quarkus-reactive-pg-client: reactive PostgreSQL driver
>   quarkus-hibernate-reactive-panache: reactive ORM
>   No quarkus-jdbc-postgresql needed (reactive driver
>   instead of JDBC)
>
> When to use reactive vs blocking:
>   Reactive: high concurrency, gateway services,
>     WebSocket handlers, streaming.
>   Blocking + @Blocking: CRUD services with
>     moderate concurrency (< 500 req/s).
>   Decision: do you have blocking I/O bottleneck?
>     Profile first.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about reactive database
access in Quarkus - non-blocking JPA queries."

**(2) First principles:** "Non-blocking DB = Vert.x event
loop not blocked waiting for PostgreSQL. Reactive driver
handles the I/O asynchronously."

**(3) Bridge:** "Hibernate Reactive is Hibernate ORM
but returning Uni<T> instead of T. Same entity model,
reactive execution."

---

### 💻 Code Example

```java
// Reactive repository
@ApplicationScoped
public class OrderRepository
        implements PanacheReactiveRepository<Order> {

    public Uni<List<Order>> findByCustomerId(
            Long customerId) {
        return list("customerId", customerId);
    }

    public Uni<Order> findByIdAndCustomer(
            Long id, Long customerId) {
        return find(
            "id=?1 and customerId=?2",
            id, customerId)
            .firstResult()
            .onItem()
            .ifNull()
            .failWith(() ->
                new NotFoundException(id));
    }

    public Uni<Page<Order>> searchPaged(
            String status,
            int page, int size) {
        return find("status", status)
            .page(page, size)
            .list()
            .map(list -> /* wrap in Page */ null);
    }
}

// Reactive service
@ApplicationScoped
public class OrderService {

    @Inject
    OrderRepository orderRepo;

    @Inject
    InventoryReactiveClient inventoryClient;

    @ReactiveTransactional
    public Uni<Order> createOrder(
            CreateOrderRequest req) {
        return inventoryClient
            .checkAvailability(
                req.getProductId(), req.getQty())
            .chain(available -> {
                if (!available) {
                    return Uni.createFrom()
                        .failure(
                            new OutOfStockException());
                }
                Order order = Order.from(req);
                return orderRepo.persist(order);
            });
    }

    // Combine multiple reactive DB operations
    public Uni<OrderSummary> getOrderWithDetails(
            Long orderId) {
        Uni<Order> orderUni =
            orderRepo.findById(orderId)
                .onItem().ifNull()
                .failWith(() ->
                    new NotFoundException(orderId));

        Uni<List<OrderItem>> itemsUni =
            itemRepo.findByOrderId(orderId);

        // Run both queries in parallel
        return Uni.combine()
            .all()
            .unis(orderUni, itemsUni)
            .asTuple()
            .map(tuple -> OrderSummary.from(
                tuple.getItem1(),
                tuple.getItem2()));
    }
}

// Reactive controller
@Path("/orders")
public class OrderResource {

    @Inject
    OrderService orderService;

    @GET
    @Path("/{id}")
    public Uni<Response> findById(
            @PathParam("id") Long id,
            @QueryParam("customerId")
            Long customerId) {
        return orderService
            .findByIdAndCustomer(id, customerId)
            .map(order ->
                Response.ok(
                    OrderDto.from(order)).build())
            .onFailure(NotFoundException.class)
            .recoverWithItem(
                Response.status(404).build());
    }
}
```

> **Code walkthrough:** @ReactiveTransactional wraps the
> Mutiny chain in a reactive transaction - commits when
> the Uni completes. .chain() is Mutiny's flatMap - waits
> for the first Uni, then runs the next. Uni.combine().all()
> runs both orderUni and itemsUni in parallel - both DB
> queries execute concurrently, reducing total latency
> vs sequential. The controller chains the service call
> with .onFailure().recoverWithItem() for 404 handling.

---

### 🎓 Answers by Seniority

**Junior:** "Use PanacheReactiveRepository for reactive
queries returning Uni<T>. @ReactiveTransactional for
transaction management."

**Senior:** "Reactive Hibernate requires reactive PostgreSQL
driver (reactive-pg-client) - not a standard JDBC driver.
Uni.combine() for parallel queries: two DB calls in
parallel halves the latency compared to sequential.
@ReactiveTransactional commits when the Uni chain
completes - if you don't return the Uni, the transaction
may not be active when the DB operation runs."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Reactive repository, @ReactiveTransactional, parallel queries |
| Staff | 12 min | Reactive vs blocking decision, Mutiny operators |

---

**[SENIOR] Q1 - What is the most common bug when
using @ReactiveTransactional?**

*Why they ask:* Production reactive transaction bug.

Bug: returning void or not returning the Uni from the
@ReactiveTransactional method.

```java
// BAD: void return - transaction context lost
@ReactiveTransactional
public void createOrder(CreateOrderRequest req) {
    Order order = Order.from(req);
    orderRepo.persist(order);
    // persist() returns Uni<Order>
    // We're NOT subscribing to it
    // The persist may not execute!
}

// BAD: creating Uni but not returning it
@ReactiveTransactional
public Uni<Void> createOrder(CreateOrderRequest req) {
    Uni<Order> persistUni = orderRepo.persist(
        Order.from(req));
    // Never connected to the return chain
    return Uni.createFrom().voidItem();
    // Transaction commits with nothing persisted
}

// GOOD: return the Uni chain
@ReactiveTransactional
public Uni<Order> createOrder(
        CreateOrderRequest req) {
    return orderRepo.persist(Order.from(req));
    // Transaction commits when persist Uni completes
}
```

The transaction is bound to the Uni chain. If the
Uni is not connected to the method's return, the
persistence operation never executes in the transaction.

*What separates good from great:* Understanding that
the reactive chain is the execution trigger - not
just returning a Uni from the method.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | PanacheReactiveRepository, reactive types, @ReactiveTransactional. |
| Hiring Manager | Non-blocking database for scalable services. |
| Bar Raiser | @ReactiveTransactional void bug, Uni.combine parallel queries. |
| Peer Engineer | "Spent 3 hours debugging missing data. Found a void @ReactiveTransactional. Mutiny chain not connected." |

---

---

# Quarkus Flyway and Liquibase

**Interview Weight:** medium - Schema migration is
non-negotiable in production. Tested for integration
and best practices.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus supports both Flyway and Liquibase for database
> schema migrations. Add quarkus-flyway extension. Place
> SQL migrations in src/main/resources/db/migration/
> as V1__description.sql files. Quarkus runs Flyway at
> startup automatically. For production: use baseline
> for existing schemas. For Dev Mode: Dev Services starts
> a fresh database and Flyway runs from scratch.

**3 minutes (Senior):**

> Flyway integration:
>
> Configuration:
>   quarkus.flyway.migrate-at-start=true (default true)
>   quarkus.flyway.baseline-on-migrate=true (existing DB)
>   quarkus.flyway.locations=db/migration (default)
>   quarkus.flyway.out-of-order=false
>
> Migration file naming:
>   V1__create_orders_table.sql
>   V2__add_customer_index.sql
>   V1.1__hotfix_status_column.sql
>   R__repeatable_migration.sql (runs every time changed)
>
> Dev Mode behavior:
>   %dev.quarkus.flyway.clean-at-start=true
>     Drops schema and re-runs all migrations.
>     Useful for testing schema changes.
>     NEVER in production.
>
> Prod best practices:
>   Never modify applied migrations.
>   Use --repair for checksum mismatches.
>   Validate checksums in CI before deployment.
>
> Multi-datasource:
>   quarkus.flyway.myds.migrate-at-start=true
>   quarkus.flyway.myds.locations=db/migration-myds
>
> Liquibase alternative:
>   quarkus-liquibase extension.
>   src/main/resources/db/changeLog.xml
>   YAML/JSON/XML changeset format.
>   More powerful change types (addColumn, modifyColumn).
>   Better rollback support (Change.rollback).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about database schema
migrations in Quarkus - Flyway and Liquibase."

**(2) First principles:** "Schema must evolve with code.
Migrations track and apply schema changes in order."

**(3) Bridge:** "Quarkus Flyway is Spring Boot Flyway
with auto-run at startup. Same SQL migration files."

---

### 🎓 Answers by Seniority

**Junior:** "Add quarkus-flyway extension. Place SQL
files in db/migration/. Quarkus runs them at startup."

**Senior:** "Dev Mode: use %dev.quarkus.flyway.clean-at-start=true
to reset the schema during development. Never in production
(drops all data). For prod: baseline-on-migrate for
first deploy on existing schemas. Validate checksums
in CI to catch modified migrations before deployment."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | Flyway setup, migration file naming |
| Senior | 6 min | Dev Mode config, production practices |

---

**[SENIOR] Q1 - How do you run Flyway migrations
in Kubernetes without running them in every pod?**

*Why they ask:* Production deployment pattern.

Problem: 5 pods start simultaneously with migrate-at-start=true.
5 pods try to run the same migration.

Flyway handles this with a distributed lock (writes
to flyway_schema_history). Only one migration runs.
Others wait. This is safe but slow.

Better pattern: Kubernetes Job for migration:

```yaml
# k8s job - runs before deployment
apiVersion: batch/v1
kind: Job
spec:
  template:
    spec:
      containers:
        - name: flyway
          image: flyway/flyway:9
          command:
            - flyway
            - migrate
          env:
            - name: FLYWAY_URL
              value: ${DB_URL}
            - name: FLYWAY_LOCATIONS
              value: filesystem:/flyway/sql
      restartPolicy: OnFailure
```

Or: use Quarkus's flyway.migrate-at-start=false in
production pods, with a separate init container or
Kubernetes Job that runs migrations.

```properties
%prod.quarkus.flyway.migrate-at-start=false
%dev.quarkus.flyway.migrate-at-start=true
```

The migration Job runs and completes. Then the Deployment
starts all pods. No migration contention.

*What separates good from great:* Separating migration
execution from application startup is the correct
production pattern.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Flyway setup, migration files, configuration. |
| Hiring Manager | Safe schema evolution in production. |
| Bar Raiser | Kubernetes migration Job, distributed lock, prod migration strategy. |
| Peer Engineer | "Moved Flyway to a Kubernetes Job. Pod startup: 8s → 2s." |

---

---

# Quarkus Redis and Caching

**Interview Weight:** medium - Caching is a common
optimization. Tested for Quarkus cache annotations
and Redis integration.

---

### 🎯 Model Answer

**30 seconds:**

> Quarkus provides declarative caching via @CacheResult,
> @CacheInvalidate, @CacheInvalidateAll, @CacheName
> annotations (quarkus-cache extension). The default
> backend is in-process Caffeine. For distributed
> caching add quarkus-redis-client or quarkus-infinispan-client.
> Redis integration: inject RedisDataSource for reactive
> Redis operations. @CacheResult on a method: caches
> the result using method parameters as key.

**3 minutes (Senior):**

> Quarkus Cache annotations:
>
> @CacheResult(cacheName="orders"):
>   First call: execute method, cache result.
>   Subsequent calls: return cached value.
>   Key: method parameters (combined).
>
> @CacheInvalidate(cacheName="orders"):
>   Remove a specific key from cache.
>   Key: method parameters.
>   Use on update/delete methods.
>
> @CacheInvalidateAll(cacheName="orders"):
>   Clear the entire cache.
>   Use on bulk operations.
>
> @CacheKey on parameters:
>   Mark which parameters compose the cache key.
>   Exclude non-key parameters (e.g., audit context).
>
> Cache configuration:
>   quarkus.cache.caffeine."orders".maximum-size=1000
>   quarkus.cache.caffeine."orders".expire-after-write=10M
>
> Redis integration (quarkus-redis-client):
>   Inject RedisDataSource (reactive) or RedisClient.
>   Operations: get, set, del, expire, hset, hget.
>   Reactive: returns Uni<T>.
>
> Redis as Quarkus cache backend:
>   quarkus-redis-cache extension.
>   @CacheResult cached in Redis (not Caffeine).
>   Distributed: all pod instances share cache.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about caching in Quarkus -
how to cache results and use Redis."

**(2) First principles:** "Cache = store expensive results,
return fast on repeated access. Invalidate when data
changes."

**(3) Bridge:** "Quarkus @CacheResult is Spring @Cacheable.
@CacheInvalidate is @CacheEvict."

---

### 💻 Code Example

```java
// Declarative caching with Caffeine (local)
@ApplicationScoped
public class ProductService {

    @Inject
    ProductRepository productRepo;

    @CacheResult(cacheName = "products")
    public Product findById(Long productId) {
        // Called once per unique productId
        // Subsequent calls return cached value
        return productRepo.findById(productId)
            .orElseThrow(() ->
                new NotFoundException(productId));
    }

    @CacheInvalidate(cacheName = "products")
    public Product update(
            Long productId,
            UpdateProductRequest req) {
        // Removes productId from cache after update
        Product product = productRepo
            .findById(productId)
            .orElseThrow();
        product.update(req);
        return productRepo.save(product);
    }

    @CacheInvalidateAll(cacheName = "products")
    public void refreshAll() {
        // Clears entire products cache
    }
}

// Redis operations (reactive)
@ApplicationScoped
public class SessionService {

    @Inject
    ReactiveRedisDataSource redis;

    public Uni<Void> saveSession(
            String sessionId,
            UserSession session) {
        return redis.value(UserSession.class)
            .set("session:" + sessionId, session)
            .chain(() ->
                redis.key()
                    .expire("session:" + sessionId,
                        Duration.ofHours(24)));
    }

    public Uni<Optional<UserSession>> getSession(
            String sessionId) {
        return redis.value(UserSession.class)
            .get("session:" + sessionId)
            .map(Optional::ofNullable);
    }

    public Uni<Boolean> revokeSession(
            String sessionId) {
        return redis.key()
            .del("session:" + sessionId)
            .map(count -> count > 0);
    }
}

// application.properties
// # Local cache config
// quarkus.cache.caffeine."products".maximum-size=5000
// quarkus.cache.caffeine."products".expire-after-write=10M
//
// # Redis for distributed session cache
// quarkus.redis.hosts=redis://localhost:6379
// quarkus.redis.password=${REDIS_PASSWORD}
```

> **Code walkthrough:** @CacheResult on findById: first
> call with productId=1 executes the database query; second
> call with productId=1 returns the cached Product.
> @CacheInvalidate on update removes the cached value
> for the updated product - next call will fetch from DB.
> The Redis session service uses ReactiveRedisDataSource
> for non-blocking Redis operations. The expire call
> sets a TTL on the session key.

---

### 🎓 Answers by Seniority

**Junior:** "@CacheResult caches method results. @CacheInvalidate
removes stale entries. Configure size and TTL in
application.properties."

**Senior:** "In-process Caffeine cache is per-pod -
not shared. For multi-pod Kubernetes: use Redis as
cache backend (quarkus-redis-cache). Trade-off: Redis
adds network latency (~1ms) but serves all pods from
one cache. Caffeine is ~0ms latency but each pod has
its own cache (stale across pods)."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 5 min | Cache annotations, Redis integration |
| Staff | 8 min | Distributed vs local cache, cache stampede |

---

**[SENIOR] Q1 - What is a cache stampede and how
do you prevent it in Quarkus?**

*Why they ask:* Production cache failure pattern.

Cache stampede: a cache entry expires. Multiple requests
simultaneously query the DB to repopulate it. DB receives
N queries instead of 1.

Scenario:
- Cache TTL: 10 minutes.
- At minute 10: 100 concurrent requests for product-1.
- Cache miss: all 100 query the DB simultaneously.
- DB has 100 product-1 queries at once.

Prevention:

Option 1: Probabilistic early expiration:
Quarkus Caffeine doesn't have built-in, but:
Before expiry (e.g., at 80% TTL), randomly refresh
the cache for some requests.

Option 2: Locking (prevent concurrent population):
```java
// Manual locking with Quarkus Lock
@ApplicationScoped
public class ProductService {

    @Inject
    @CacheName("products")
    Cache productsCache;

    private final Map<Long, Object> locks =
        new ConcurrentHashMap<>();

    public Product findById(Long id) {
        return productsCache.get(id, k -> {
            // Only one thread populates per key
            // ConcurrentHashMap.computeIfAbsent semantics
            synchronized(locks
                .computeIfAbsent(id, i ->
                    new Object())) {
                return productRepo.findById(id)
                    .orElseThrow();
            }
        });
    }
}
```

Option 3: Stagger TTLs with jitter:
```properties
# Apply TTL jitter at application level
# Expires between 9-11 minutes (not exactly 10)
```

*What separates good from great:* Cache stampede is
a pattern with a specific name and specific fix. Knowing
the name shows production experience.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | @CacheResult, @CacheInvalidate, Redis setup. |
| Hiring Manager | Caching for performance. |
| Bar Raiser | Distributed vs local cache, cache stampede, Redis TTL. |
| Peer Engineer | "Cache stampede took down our product DB. Added jitter to TTL. Problem never recurred." |
