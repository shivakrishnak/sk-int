---
layout: default
title: "JPA - L5 Architecture"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 8
permalink: /jpa/l5-architecture/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [JPA in Domain-Driven Design](#jpa-in-domain-driven-design) | critical |
| 2 | [CQRS with JPA Read Models](#cqrs-with-jpa-read-models) | critical |
| 3 | [JPA Multi-tenancy Architecture](#jpa-multi-tenancy-architecture) | critical |

---

# JPA in Domain-Driven Design

**Interview Weight:** critical - DDD with JPA is a
Staff/Principal level topic. Interviewers test whether
candidates understand the tension between rich domain
models and JPA's persistence requirements.

---

### 🎯 Model Answer

**30 seconds:**

> DDD aggregates map to JPA entities, but with a
> critical constraint: JPA entities must have a no-arg
> constructor, getters, and setters - which violates
> OOP encapsulation. Solutions: use package-private
> constructor + protected no-arg for JPA; expose
> behavior methods, not setters; return unmodifiable
> collections. The aggregate root controls consistency:
> only the root has a public repository. Child entities
> are loaded through the root, not independently.

**3 minutes (Senior):**

> DDD + JPA design decisions:
>
> Aggregate Root → @Entity + Repository
>   Only aggregate roots have repositories.
>   Children accessed via root.getChildren()
>   not ChildRepository.findAll()
>
> Value Objects → @Embeddable
>   DDD value objects have no identity.
>   @Embeddable stores them in the same table.
>   Immutable: no setters, final fields,
>   constructor-only creation.
>
> Encapsulation challenge:
>   JPA needs: no-arg constructor + setters
>   (for proxy creation and field injection)
>   DDD wants: constructor enforcement, no setters
>   Solution: protected/package-private no-arg for JPA
>   Public methods for business operations (not setters)
>   Collections: return unmodifiable view
>
> Repository pattern:
>   DDD: Repository is a collection of aggregates
>   JPA: Spring Data JPA Repository interface
>   Mapping: interface matches, but:
>   - Repository should be an interface in domain layer
>   - Implementation is in infrastructure layer
>   - Domain layer has no JPA imports
>
> Domain events:
>   Domain events published on state changes.
>   Spring's @DomainEvents + @AfterDomainEventPublication
>   or ApplicationEventPublisher.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about using JPA with
Domain-Driven Design - making JPA serve a rich domain
model."

**(2) First principles:** "DDD puts behavior in entities,
not services. JPA requires persistence mechanisms.
The challenge: satisfy JPA's technical requirements
without compromising domain model integrity."

**(3) Bridge:** "DDD + JPA is a design negotiation:
domain model wins on behavior, JPA wins on persistence
mechanics. Protected no-arg constructor is the
compromise: JPA can create instances, but callers can't."

---

### 💻 Code Example

```java
// BAD: Anemic domain model with JPA
@Entity
public class Order {
    @Id @GeneratedValue
    private Long id;
    private String status;

    // Public no-arg + setters = no encapsulation
    public Order() {}
    public void setStatus(String status) {
        this.status = status;  // Any caller can set!
    }
}

// Service does all logic (anemic model)
orderService.updateStatus(orderId, "SHIPPED");
// Domain logic lives in service, not Order

// GOOD: Rich domain model with JPA-friendly design
@Entity
@Table(name = "orders")
public class Order {

    @Id @GeneratedValue
    private Long id;

    private String status;
    private BigDecimal total;

    @OneToMany(
        mappedBy = "order",
        cascade = CascadeType.ALL,
        orphanRemoval = true)
    private List<OrderItem> items =
        new ArrayList<>();

    // JPA needs this - protected, not public
    protected Order() {}

    // Domain constructor - callers use this
    public Order(
            Customer customer,
            List<OrderItem> items) {

        Objects.requireNonNull(customer);
        this.status = "PENDING";
        this.total = items.stream()
            .map(OrderItem::getSubtotal)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        this.items.addAll(items);
    }

    // Behavior method, not setter
    public void ship() {
        if (!"PAID".equals(status)) {
            throw new InvalidStateException(
                "Only PAID orders can be shipped");
        }
        this.status = "SHIPPED";
        registerEvent(new OrderShippedEvent(id));
    }

    // Unmodifiable collection view
    public List<OrderItem> getItems() {
        return Collections.unmodifiableList(items);
    }

    // Domain events (Spring Data)
    @Transient
    private List<Object> domainEvents =
        new ArrayList<>();

    @DomainEvents
    public List<Object> getDomainEvents() {
        return domainEvents;
    }

    @AfterDomainEventPublication
    public void clearDomainEvents() {
        domainEvents.clear();
    }

    private void registerEvent(Object event) {
        domainEvents.add(event);
    }
}

// Value Object as @Embeddable
@Embeddable
public class Money {
    private BigDecimal amount;
    private String currency;

    protected Money() {}  // JPA

    public Money(BigDecimal amount, String currency) {
        this.amount = Objects.requireNonNull(amount);
        this.currency = Objects.requireNonNull(currency);
    }

    // No setters - immutable
    public BigDecimal getAmount() { return amount; }
    public String getCurrency() { return currency; }

    public Money add(Money other) {
        if (!this.currency.equals(other.currency))
            throw new IllegalArgumentException();
        return new Money(
            this.amount.add(other.amount), currency);
    }
}
```

> **Code walkthrough:** The GOOD Order has protected
> no-arg constructor (JPA can create it, callers cannot).
> State changes via ship() not setStatus() - the method
> enforces the business rule (only PAID → SHIPPED). The
> domain events pattern integrates with Spring: @DomainEvents
> returns events to publish; @AfterDomainEventPublication
> clears them after Spring publishes. Money as @Embeddable
> is immutable (no setters, final behavior via add()).

---

### 🎓 Answers by Seniority

**Senior:** "The key JPA+DDD pattern: protected no-arg
constructor for JPA, public business methods instead
of setters. Value Objects as @Embeddable. Aggregate
root controls child entity access. Repository interface
in domain layer, Spring Data JPA implementation in
infrastructure."

**Staff:** "I separate domain model from JPA model
for large systems: domain layer (no framework imports),
JPA persistence layer (infrastructure). The domain
model is pure Java objects; JPA entities map to them.
More code but true hexagonal architecture. For smaller
systems: @Entity directly with JPA-friendly DDD patterns."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Aggregate root, @Embeddable, protected constructor |
| Staff | 12 min | Hexagonal architecture, domain events, separation |

---

**[STAFF] Q1 - How do you handle JPA's requirement
for public setters when following DDD with rich domain
models?**

*Why they ask:* DDD-JPA tension is a real design challenge.

Options, in order of trade-off:

1. **Protected no-arg + business methods only:**
   JPA uses protected no-arg for proxy creation.
   Use business-named methods (pay(), ship()) instead
   of setters. No setter for status.
   Best for most cases.

2. **@Access(AccessType.FIELD):**
   JPA accesses fields directly (not via getters).
   You can have getter methods without setters.
   No public setter needed.
   Caveat: field access works for all JPA fields.

3. **Domain model + persistence model separation:**
   Domain model: pure Java, no JPA.
   Persistence model: @Entity with all JPA requirements.
   Mapper: between domain and persistence models.
   Full encapsulation, more code.
   Best for large systems where domain integrity > cost.

4. **Kotlin data classes:**
   val fields = immutable. JPA plugin generates
   no-arg constructor automatically.
   Copy semantics for value changes.

*What separates good from great:* Knowing @Access(FIELD)
as the minimal-change solution for eliminating setters.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Aggregate root, @Embeddable, protected constructor. |
| Hiring Manager | DDD + JPA = business logic in domain, not service. |
| Bar Raiser | Hexagonal architecture separation, domain events, @Access(FIELD). |
| Peer Engineer | "I use @Access(FIELD) on every entity. No setters, JPA still works, domain model is clean." |

---

---

# CQRS with JPA Read Models

**Interview Weight:** critical - CQRS (Command Query
Responsibility Segregation) with JPA is an architectural
pattern that separates write and read models. Tested
at Staff level for architectural thinking.

---

### 🎯 Model Answer

**30 seconds:**

> CQRS separates writes (commands) from reads (queries).
> In JPA: write side uses full @Entity aggregates with
> business methods; read side uses DTO projections or
> separate read entities mapped to views/denormalized
> tables. This allows independent optimization: write
> side optimizes for consistency, read side for query
> performance. Spring Data projections implement the
> read model without separate tables.

**3 minutes (Senior):**

> CQRS with JPA patterns:
>
> Pattern 1: Projections as read model
>   Write: OrderRepository extends JpaRepository<Order,Long>
>   Read: interface OrderListView with specific getters
>   Same table, different SQL (read uses optimized SELECT)
>   Simple to implement, limited optimization potential
>
> Pattern 2: Read entity to database view
>   Create a DB view: view_order_summary
>   Map a separate @Entity (OrderSummary) to the view
>   @Table(name = "view_order_summary")
>   @Immutable (Hibernate: this entity never changes)
>   Read queries hit the view; writes hit the base tables
>   Good for complex read queries with JOINs
>
> Pattern 3: Separate read store
>   Commands write to relational DB (JPA)
>   Events trigger write to read store (Elasticsearch,
>   Redis, MongoDB)
>   Read queries hit the read store
>   Eventual consistency required
>   Full CQRS at infrastructure level
>
> @Immutable (Hibernate):
>   Entity that should never be updated or deleted.
>   Hibernate skips dirty checking for @Immutable.
>   All updates/deletes throw ImmutableEntityException.
>   Use for read-only projections mapped to views.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about separating read
and write models in JPA using the CQRS pattern."

**(2) First principles:** "Read and write operations
have different optimization requirements. Writes need
ACID, normalization, consistency. Reads need performance,
joins across multiple tables, shaped for the UI."

**(3) Bridge:** "CQRS with JPA is like a restaurant
kitchen: the chef (write model) controls cooking.
The waiter's presentation (read model) is optimized
for the diner, not the chef."

---

### 💻 Code Example

```java
// Write side: full aggregate entity
@Entity
@Table(name = "orders")
public class Order {
    @Id @GeneratedValue
    private Long id;
    private String status;
    private BigDecimal total;
    private Long customerId;

    @OneToMany(cascade = ALL, orphanRemoval = true)
    private List<OrderItem> items;

    // Business methods
    public void pay(PaymentDetails payment) {
        this.status = "PAID";
        registerEvent(new OrderPaidEvent(this));
    }
}

// Read side: projections (Pattern 1)
public interface OrderListView {
    Long getId();
    String getStatus();
    BigDecimal getTotal();
    String getCustomerName();  // nested: JOIN
}

public interface OrderRepository
        extends JpaRepository<Order, Long> {

    // Write: full entity
    Optional<Order> findById(Long id);

    // Read: projection
    List<OrderListView> findAllProjectedBy();
}

// Read side: database view entity (Pattern 2)
// SQL VIEW: CREATE VIEW order_summary AS
// SELECT o.id, o.status, o.total,
//        c.name AS customer_name,
//        COUNT(i.id) AS item_count
// FROM orders o JOIN customers c
//   ON o.customer_id = c.id
// LEFT JOIN order_items i ON i.order_id = o.id
// GROUP BY o.id, o.status, o.total, c.name

@Entity
@Table(name = "order_summary")
@Immutable   // Hibernate: read-only, skip dirty check
@Subselect("SELECT o.id, o.status, o.total, "
    + "c.name AS customer_name "
    + "FROM orders o JOIN customers c "
    + "ON o.customer_id = c.id")
public class OrderSummary {
    @Id private Long id;
    private String status;
    private BigDecimal total;
    private String customerName;

    // No setters, no modifying operations
    public Long getId() { return id; }
    public String getStatus() { return status; }
    public BigDecimal getTotal() { return total; }
    public String getCustomerName() {
        return customerName;
    }
}

@Repository
public interface OrderSummaryRepository
        extends Repository<OrderSummary, Long> {
    List<OrderSummary> findAll();
    Page<OrderSummary> findByStatus(
        String status, Pageable pageable);
    // Read operations only
}
```

> **Code walkthrough:** Write side uses full Order
> entity with business methods. Read side has two
> implementations: (1) projection interface for simple
> column selection, (2) @Immutable entity mapped to
> a database view for complex denormalized reads. The
> @Subselect alternative to DB view: Hibernate uses
> the subquery as the "table" - no DB view required.
> @Immutable tells Hibernate to never dirty-check
> OrderSummary or generate UPDATE/DELETE for it.

---

### 🎓 Answers by Seniority

**Senior:** "Three CQRS levels: (1) projections (same
table, different SELECT), (2) @Immutable entity to DB
view (same DB, read-optimized SELECT), (3) separate
read store (different DB, eventual consistency).
Choose based on query complexity and scale requirements."

**Staff:** "CQRS separates the optimization concerns.
Write model optimizes for ACID and business invariants.
Read model optimizes for the UI's data shape. The
simplest effective level: DTO projections for most
reads. @Subselect for read models needing JOINs.
Separate read store only when projections can't meet
SLA."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Projections, @Immutable, @Subselect |
| Staff | 12 min | Three CQRS levels, trade-off selection, eventual consistency |

---

**[STAFF] Q1 - How do you keep the read model
consistent with the write model in CQRS with JPA?**

*Why they ask:* Consistency is the hard part of CQRS.

Consistency options by pattern:

**Pattern 1 (projections):** Always consistent.
Same database, same transaction. Read projects the
same data the write model stored. Zero consistency lag.

**Pattern 2 (DB view/subselect):** Always consistent.
Same database, same underlying tables. View refreshes
on read.

**Pattern 3 (separate read store):** Eventually consistent.
Write event → event bus → consumer updates read store.
Lag: milliseconds to seconds depending on pipeline.

For Pattern 3, keeping the read model fresh:
1. Domain events (OrderPaidEvent) trigger read model update
2. Event consumer updates Elasticsearch/Redis
3. Idempotent consumer: processing same event twice is safe
4. Replay: rebuild read model from all events (event sourcing)

Spring @TransactionalEventListener:
```java
@TransactionalEventListener
public void onOrderPaid(OrderPaidEvent event) {
    // Called AFTER commit of write transaction
    // Safe to update read model
    readModelService.updateOrder(event.getOrderId());
}
```

*What separates good from great:* @TransactionalEventListener
timing: after commit (not after call) prevents read model
update if the write transaction rolls back.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Projections, @Immutable, @Subselect syntax. |
| Hiring Manager | CQRS = separate optimization for reads and writes. |
| Bar Raiser | Three CQRS levels, consistency models, @TransactionalEventListener. |
| Peer Engineer | "Pattern 2 (@Subselect) is underused. No new infrastructure, consistent read model, complex JOINs in one query." |

---

---

# JPA Multi-tenancy Architecture

**Interview Weight:** critical - Multi-tenancy is an
architectural topic for Staff engineers. Interviewers
test awareness of the three strategies and their
trade-offs.

---

### 🎯 Model Answer

**30 seconds:**

> JPA multi-tenancy: three strategies. (1) Schema-per-tenant:
> each tenant has their own schema, same DB. High
> isolation, complex connection management. (2) Database-per-tenant:
> each tenant has their own database. Maximum isolation,
> most operational overhead. (3) Shared table with
> discriminator column (tenant_id): all tenants in
> same table, filtered by tenant_id in every query.
> Most efficient (hardware sharing), most risk (tenant
> data leak if filter missed). Hibernate native multi-tenancy
> support manages connections per tenant.

**3 minutes (Senior):**

> Multi-tenancy strategies:
>
> Discriminator column (tenant_id in table):
> Pros: simplest, no schema duplication, efficient
> Cons: tenants share storage, one missed filter = data leak
>   Requires tenant_id filter in every query
>   Row Level Security (DB-native) can enforce this
>
> Schema-per-tenant:
> Pros: data isolation, different schemas can have
>   different structure per tenant
> Cons: schema migration must run N times
>   connection must switch schema per request
>
> Database-per-tenant:
> Pros: maximum isolation (different DB instances)
>   independent backups/compliance per tenant
> Cons: most resources (N database instances)
>   most operational complexity
>
> Hibernate multi-tenancy:
>   CurrentTenantIdentifierResolver: returns current tenant ID
>     (from thread local, security context, etc.)
>   MultiTenantConnectionProvider: returns correct connection
>     (schema-based: SET search_path = tenant_schema)
>     (database-based: different connection string per tenant)
>   Hibernate uses these to route each query

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about JPA/Hibernate
multi-tenancy - running multiple tenants from one
application."

**(2) First principles:** "Multiple tenants share
infrastructure. Their data must be isolated. The choice:
how to enforce that isolation."

**(3) Bridge:** "Multi-tenancy strategies are rooms
in a building: shared office (discriminator column:
same room, each person's desk has their name),
separate offices (schema per tenant: different rooms
in the same building), separate buildings (database per tenant)."

---

### 💻 Code Example

```java
// Strategy 1: Discriminator column
// Add @TenantId to every entity (Hibernate 6)
@Entity
@Table(name = "orders")
public class Order {
    @Id @GeneratedValue
    private Long id;

    @TenantId           // Hibernate 6 annotation
    private String tenantId;
    // Hibernate auto-filters WHERE tenant_id=?
    // Hibernate auto-sets on persist

    private String status;
}

// Strategy 2/3: Hibernate multi-tenancy components
// CurrentTenantIdentifierResolver
@Component
public class TenantResolver
        implements CurrentTenantIdentifierResolver {

    @Override
    public String resolveCurrentTenantIdentifier() {
        // Extract from security context or request header
        return TenantContext.getCurrentTenant();
        // Thread-local set by filter per request
    }

    @Override
    public boolean validateExistingCurrentSessions() {
        return true;
    }
}

// MultiTenantConnectionProvider (schema-based)
@Component
public class SchemaBasedConnectionProvider
        extends AbstractMultiTenantConnectionProvider {

    @Override
    protected DataSource selectAnyDataSource() {
        return defaultDataSource;
    }

    @Override
    protected DataSource selectDataSource(
            String tenantId) {
        return dataSourceMap.get(tenantId);
        // Returns different DataSource per tenant
    }
}

// Request filter: set tenant from JWT or header
@Component
public class TenantFilter
        implements Filter {

    @Override
    public void doFilter(
            ServletRequest req,
            ServletResponse res,
            FilterChain chain)
            throws IOException, ServletException {

        String tenantId = extractTenant(
            (HttpServletRequest) req);
        TenantContext.setCurrentTenant(tenantId);
        try {
            chain.doFilter(req, res);
        } finally {
            TenantContext.clear();
            // CRITICAL: clear to prevent thread reuse leak
        }
    }

    private String extractTenant(
            HttpServletRequest req) {
        // From JWT claim, subdomain, or header
        String host = req.getServerName();
        return host.split("\\.")[0];
        // tenant1.example.com → tenant1
    }
}
```

> **Code walkthrough:** Hibernate 6 @TenantId annotation
> auto-filters all queries for the discriminator column
> strategy. TenantContext (thread-local) stores the
> current tenant per request. TenantFilter sets it at
> request start and clears it in the finally block
> (critical: thread pool reuse means previous tenant
> bleeds into next request if not cleared). The
> MultiTenantConnectionProvider routes to different
> DataSources per tenant for schema/database isolation.

---

### 🎓 Answers by Seniority

**Senior:** "Three strategies: discriminator (shared
table), schema-per-tenant, database-per-tenant. For
most SaaS: schema-per-tenant balances isolation and
resource sharing. Hibernate's CurrentTenantIdentifierResolver
routes queries to the right schema."

**Staff:** "Multi-tenancy choice: compliance requirements
drive it. HIPAA/SOC2 for large enterprises may require
database-per-tenant. SaaS with hundreds of small tenants:
discriminator with Row Level Security at the database
level (enforced by DB, not application). Hibernate's
@TenantId is the least error-prone discriminator column
implementation."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 7 min | Three strategies, trade-offs, Hibernate components |
| Staff | 12 min | Compliance drivers, RLS, @TenantId, thread-local leak |

---

**[STAFF] Q1 - Why is the TenantContext finally block
critical in a multi-tenancy application?**

*Why they ask:* Security bug from thread pool reuse.

Web application servers use thread pools. When a
request completes, the thread returns to the pool for
the next request. If the TenantContext (thread-local)
is not cleared:

Request 1 (tenant A) → sets TenantContext = "tenantA"
Request 1 completes → thread returns to pool
Request 2 (tenant B) → thread reused → TenantContext still "tenantA"
Request 2 queries run with tenant A's filter!
Tenant B sees tenant A's data.

This is a critical data isolation breach.

Fix: always clear in finally block (guarantees clear
even on exception). Or use ThreadLocal.remove() in
an interceptor's afterCompletion (Spring's
HandlerInterceptor.afterCompletion is always called).

```java
@Override
public void afterCompletion(
        HttpServletRequest req,
        HttpServletResponse res,
        Object handler, Exception ex) {
    TenantContext.clear();
    // Called even on exception
    // Servlet filter finally block also works
}
```

*What separates good from great:* Thread pool reuse
as the root cause of the security leak.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Three strategies, Hibernate components. |
| Hiring Manager | Multi-tenancy = SaaS isolation architecture. |
| Bar Raiser | Thread-local leak (security bug), RLS, Hibernate 6 @TenantId, compliance drivers. |
| Peer Engineer | "We learned about the thread-local leak in production. Tenant A's data was briefly visible to tenant B. Fixed with finally block." |
