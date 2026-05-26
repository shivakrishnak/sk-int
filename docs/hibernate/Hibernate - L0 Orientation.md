---
layout: default
title: "Hibernate - L0 Orientation"
parent: "Hibernate"
nav_order: 1
permalink: /hibernate/l0-orientation/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Hibernate - L0 Orientation](#hibernate---l0-orientation) | medium |
| 2 | [ORM Concept and Why Hibernate](#orm-concept-and-why-hibernate) | foundational |
| 3 | [Hibernate vs JDBC Trade-offs](#hibernate-vs-jdbc-trade-offs) | foundational |
| 4 | [Hibernate vs JPA Relationship](#hibernate-vs-jpa-relationship) | foundational |
| 5 | [Hibernate Ecosystem and Versions](#hibernate-ecosystem-and-versions) | orientation |

---

# Hibernate - L0 Orientation

Why Hibernate exists, what problem it solves, how it
relates to JPA, and where it fits in the Java persistence
ecosystem. Foundation before learning Hibernate internals.

---

# ORM Concept and Why Hibernate

**Interview Weight:** foundational - Often asked as "why
use an ORM at all?" The goal is to assess whether you
understand the problem Hibernate solves and can articulate
the trade-offs.

---

### 🎯 Model Answer

**30 seconds:**

> ORM (Object-Relational Mapping) bridges the structural
> mismatch between Java objects (inheritance, references,
> collections) and relational tables (rows, foreign keys,
> join tables). Hibernate maps Java classes to database
> tables so you can work with objects while Hibernate
> generates the SQL. The benefit: productivity and database
> portability. The trade-off: hidden SQL, N+1 query risks,
> and an additional abstraction layer to understand.

**3 minutes:**

> Without ORM, persistence code is JDBC boilerplate:
> ```java
> PreparedStatement ps = conn.prepareStatement(
>     "SELECT * FROM orders WHERE id = ?");
> ps.setLong(1, id);
> ResultSet rs = ps.executeQuery();
> while (rs.next()) {
>     order = new Order();
>     order.setId(rs.getLong("id"));
>     order.setTotal(rs.getBigDecimal("total"));
>     // ... 20 more fields
> }
> ```
> Hibernate replaces all of this with:
> ```java
> Order order = session.get(Order.class, id);
> ```
>
> The ORM does: SQL generation, type conversion (Java BigDecimal
> -> SQL DECIMAL), relationship traversal (loading associated
> collections), dirty tracking (detecting changes and issuing
> UPDATE), and caching.
>
> The trade-off: ORM adds a layer. If you don't understand
> what SQL Hibernate generates, you will write code that
> appears fast in testing (10 rows) but is catastrophically
> slow in production (100,000 rows). N+1 queries, Cartesian
> product joins, and loading entire object graphs when you
> need two fields are common ORM pitfalls.

**Framework:** OBJECT-TABLE MISMATCH (the core problem) →
ORM MAPS (Java class to table) →
HIBERNATE GENERATES SQL (you work with objects) →
TRADE-OFF (productivity vs hidden SQL)

---

### 📘 Concept Explanation

**The mismatch ORM solves:**

```
  JAVA OBJECT MODEL         RELATIONAL MODEL
  Order                     orders table
    id: Long         <-->   id BIGINT PK
    total: BigDecimal<-->   total DECIMAL(10,2)
    items: List<Item><-->   items table (FK order_id)
    customer: Customer<-->  customer_id FK + customers table

  Inheritance:              orders_type column
    class Order             or separate tables per type
      |
      +-- StandardOrder
      +-- SubscriptionOrder

  Object identity:          Row identity:
    order1 == order1          WHERE id = 1 (always one row)
    (Java reference)
```

---

### 💻 Code Example

**Wrong vs Right: JDBC boilerplate vs Hibernate**

```java
// BAD: JDBC (verbose, error-prone, database-specific SQL)
public Order findOrder(Long id) throws SQLException {
    try (Connection conn = dataSource.getConnection();
         PreparedStatement ps = conn.prepareStatement(
             "SELECT o.*, c.name, c.email " +
             "FROM orders o " +
             "JOIN customers c ON c.id = o.customer_id " +
             "WHERE o.id = ?")) {
        ps.setLong(1, id);
        try (ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                Order o = new Order();
                o.setId(rs.getLong("id"));
                o.setTotal(rs.getBigDecimal("total"));
                Customer c = new Customer();
                c.setName(rs.getString("name"));
                c.setEmail(rs.getString("email"));
                o.setCustomer(c);
                return o;
            }
        }
    }
    return null;
}
```

```java
// GOOD: Hibernate (concise, database-portable,
//        relationship-aware)
@Entity
@Table(name = "orders")
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private BigDecimal total;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "customer_id")
    private Customer customer;
}

// Loading with Hibernate:
Order order = session.get(Order.class, id);
// SQL: SELECT * FROM orders WHERE id = ?
// customer is lazily loaded when accessed
String email = order.getCustomer().getEmail();
// SQL: SELECT * FROM customers WHERE id = ?
```

> **Code walkthrough:** The JDBC example is 25 lines for
> a simple single-entity query. It tightly couples to SQL
> syntax (database-specific), manually maps ResultSet columns
> to fields, and requires explicit transaction management.
> The Hibernate example is declarative: annotate the class,
> call `session.get()`. Hibernate generates the SQL,
> handles type conversion, and manages the relationship
> to `Customer` via `@ManyToOne`. The `FetchType.LAZY`
> annotation means the `Customer` is only loaded when
> accessed - avoiding unnecessary joins.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**

> ORM is a productivity tool that comes with cognitive
> overhead. My rule: use Hibernate for standard CRUD
> and relationship traversal. Use native SQL (Hibernate's
> `session.createNativeQuery()`) for complex reporting,
> bulk operations, and queries that require database-
> specific features. Never use ORM blindly - always
> check what SQL is being generated (`show_sql=true` in
> development).
>
> Hibernate's `@Entity` and relationship annotations are
> the vocabulary of persistence design. Understanding them
> is table stakes. Understanding what SQL they generate
> and when that SQL is executed is mastery.

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | ORM eliminates the need to understand SQL | ORM generates SQL. Understanding that SQL - and recognizing when it's wrong - is essential for any production application. Tools: `show_sql=true` in development, Hibernate Statistics in production. | Silent performance disasters from bad SQL hidden by ORM |
| 2 | Hibernate always generates optimal SQL | Hibernate generates correct SQL; it does not always generate optimal SQL. Complex queries (reports, aggregations, cross-table analytics) are often better written in native SQL. | Performance issues from ORM-generated SQL that a DBA would immediately optimize |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Hibernate generates too many SQL queries**

Symptom: application is slow. Enabling `show_sql=true`
reveals hundreds of SELECT statements for a single
endpoint.

Root cause: N+1 query problem. Loading a list of 100
orders, then accessing each order's customer, generates
1 (list query) + 100 (customer per order) = 101 queries.

Fix: use `JOIN FETCH` in HQL or `@EntityGraph` to load
the association in one query:
```java
// Fix with HQL JOIN FETCH
List<Order> orders = session.createQuery(
    "SELECT o FROM Order o JOIN FETCH o.customer",
    Order.class).getResultList();
// 1 SQL query instead of N+1
```

---

### 🎯 Interview Deep-Dive

**[JUNIOR] Q1: Why would you use Hibernate instead of
plain JDBC?** [FOUNDATION]

*Why they ask:* Tests understanding of the problem ORM solves.

Hibernate provides: (1) Object-relational mapping - write
Java, Hibernate writes SQL. (2) Relationship management -
`@OneToMany`, `@ManyToOne` annotations; no manual JOIN
SQL. (3) Database portability - switch from MySQL to
PostgreSQL by changing the dialect. (4) Caching - first
and second-level caches reduce database load. (5) Dirty
checking - modify an entity in a transaction; Hibernate
issues the UPDATE automatically.

When to use plain JDBC or jOOQ: complex reporting queries,
bulk operations (INSERT 100,000 rows), database-specific
features (PostgreSQL COPY, MySQL INSERT IGNORE).

*What separates good from great:* Knowing when NOT to
use Hibernate - "ORM for everything" is an anti-pattern;
native SQL for complex queries is professional judgment.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with N+1 and generated SQL awareness. |
| Hiring Manager | Lead with productivity and maintenance benefits. |
| Bar Raiser | Lead with ORM trade-offs and when native SQL is better. |

---

---

# Hibernate vs JDBC Trade-offs

**Interview Weight:** foundational - Asked to assess whether
the candidate understands the cost of the ORM abstraction,
not just its benefits.

---

### 🎯 Model Answer

**30 seconds:**

> Hibernate vs JDBC: Hibernate provides object mapping,
> relationship management, caching, and dirty checking
> at the cost of: control over SQL (you write HQL/JPQL,
> Hibernate decides the SQL), performance overhead (proxy
> creation, dirty checking, session management), and a
> learning curve (understanding what Hibernate does
> automatically). JDBC gives full SQL control and is
> faster for bulk operations. For most application CRUD:
> Hibernate. For complex reports and bulk operations:
> native SQL or jOOQ.

---

### 📘 Concept Explanation

**Trade-off comparison:**

```
  HIBERNATE strengths:
  - Object mapping (no ResultSet boilerplate)
  - Relationship traversal (lazy loading)
  - Caching (first-level, second-level)
  - Dirty checking (auto UPDATE on flush)
  - Database portability (dialect swap)
  - Schema generation (for dev/test environments)

  HIBERNATE weaknesses:
  - Complex SQL is hard to express in HQL/JPQL
  - Bulk operations (UPDATE 100k rows) are inefficient
    (loads all entities, checks dirty state, issues
    individual UPDATEs vs one bulk UPDATE)
  - Learning curve (Session lifecycle, cascades,
    flush modes, caching layers)
  - Hidden SQL can cause N+1 disasters

  JDBC strengths:
  - Full SQL control
  - Efficient bulk operations
  - No ORM learning curve
  - Lower memory overhead (no entity cache)

  JDBC weaknesses:
  - Boilerplate (prepareStatement, setParameter, etc.)
  - No relationship management
  - No caching
  - Database-coupled SQL
```

---

### 💻 Code Example

**Trade-off: bulk update - Hibernate vs JDBC/SQL**

```java
// BAD: Hibernate for bulk update (inefficient)
// Loads ALL matching entities (heap pressure),
// then issues one UPDATE per entity
@Transactional
public void deactivateOldAccounts() {
    List<Account> accounts = session.createQuery(
        "FROM Account WHERE lastLogin < :cutoff",
        Account.class)
        .setParameter("cutoff", LocalDate.now()
            .minusYears(2))
        .getResultList();
    // Loads 50,000 entities into memory!
    accounts.forEach(a -> a.setActive(false));
    // Hibernate issues 50,000 individual UPDATEs
    session.flush();
}
```

```java
// GOOD: bulk UPDATE with JPQL/HQL (single SQL statement)
@Transactional
public void deactivateOldAccounts() {
    int updated = session.createMutationQuery(
        "UPDATE Account SET active = false " +
        "WHERE lastLogin < :cutoff")
        .setParameter("cutoff", LocalDate.now()
            .minusYears(2))
        .executeUpdate();
    // Single SQL: UPDATE accounts SET active=false
    // WHERE last_login < ?
    log.info("Deactivated {} accounts", updated);
}
```

> **Code walkthrough:** The first version loads 50,000
> entity objects into memory (heap pressure, GC pressure),
> then calls `setActive(false)` on each. Hibernate's dirty
> checking issues one `UPDATE` per entity. This is
> 50,000 database round-trips. The second version uses
> Hibernate's bulk mutation query - one `UPDATE` statement,
> no entity loading, no dirty checking. Orders of magnitude
> faster for bulk operations. Use Hibernate's object model
> for single-entity operations; use bulk JPQL/HQL mutations
> for batch updates.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> My decision framework for Hibernate vs native SQL:
> - Standard CRUD (get, save, update one entity): Hibernate
> - List queries with filtering/sorting: JPQL or Criteria API
> - Aggregate queries (SUM, COUNT, GROUP BY): native SQL
> - Bulk updates/deletes: Hibernate bulk mutation query or
>   native SQL
> - Complex reports (multi-table joins, analytics): jOOQ
>   or native SQL (via Spring JDBC Template)
>
> The rule: if the generated SQL would be obvious and
> efficient, use Hibernate. If you would write it differently
> in raw SQL, write it in raw SQL.

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | JPQL/HQL bulk UPDATE bypasses Hibernate L2 cache | Correct: JPQL bulk updates bypass the first-level and second-level caches. Entities already in cache will be stale after a bulk update. Must evict the affected region: `sessionFactory.getCache().evictEntityData(Account.class)`. | Stale cache entries after bulk operations cause incorrect reads |

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: When would you choose jOOQ over Hibernate,
and why?** [TRADE-OFF]

*Why they ask:* Tests knowledge of persistence alternatives.

jOOQ over Hibernate when:

1. Complex queries are the majority of your workload:
   jOOQ generates type-safe SQL directly. Complex JOIN,
   window functions, CTEs - jOOQ can express them all
   in Java. Hibernate's Criteria API becomes unwieldy
   for complex queries.

2. Schema-first workflow: jOOQ generates Java DSL from
   your database schema. Changes to schema are reflected
   in compile-time type errors (rename a column = compile
   error). Hibernate is model-first.

3. You need readable, predictable SQL: jOOQ's Java DSL
   maps 1:1 to SQL. What you write is what runs. No
   surprise SQL from lazy loading or dirty checking.

Hibernate over jOOQ when:

1. Rich domain model with relationships: Hibernate's
   mapping and relationship management is natural for
   DDD-style domain models.

2. Caching: Hibernate's second-level cache has no
   equivalent in jOOQ.

3. Standard CRUD: Hibernate's JPA APIs are simpler
   for standard entity operations.

*What separates good from great:* Recommending using
both in the same project - Hibernate for the domain
model (entities with relationships), jOOQ for complex
queries and reports. They are not mutually exclusive.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with Hibernate vs JDBC performance comparison. |
| Hiring Manager | Lead with productivity trade-offs. |
| Bar Raiser | Lead with jOOQ alternative and mixed-approach strategy. |

---

---

# Hibernate vs JPA Relationship

**Interview Weight:** foundational - Distinguishing JPA
from Hibernate is a common interview question. Misunderstanding
here is a red flag at any level.

---

### 🎯 Model Answer

**30 seconds:**

> JPA (Jakarta Persistence API) is a specification - a set
> of interfaces and annotations (`@Entity`, `@Id`,
> `@OneToMany`). Hibernate is an implementation of JPA
> (plus many extensions beyond the spec). You program to
> JPA interfaces (`EntityManager`, `TypedQuery`); Hibernate
> is the runtime that executes them. Spring Data JPA is
> an abstraction on top of JPA, adding repository patterns.
> The stack: Spring Data JPA -> JPA spec -> Hibernate impl
> -> JDBC -> database.

**3 minutes:**

> The full persistence stack:
>
> ```
> Your Code
>   --> Spring Data JPA (findById, save, derived queries)
>     --> JPA API (EntityManager, JPQL)
>       --> Hibernate (JPA provider, implements the spec)
>         --> JDBC
>           --> Database
> ```
>
> JPA defines: `@Entity`, `@Id`, `@ManyToOne`,
> `EntityManager`, `JPQL`, transaction management SPI.
> Hibernate provides: the runtime implementation of all
> JPA interfaces plus Hibernate-specific extensions:
> - `@Filter`, `@Formula` (Hibernate-specific annotations)
> - `StatelessSession` (bypass first-level cache for bulk ops)
> - Native SQL result set mapping
> - Second-level caching configuration
>
> The JPA portability promise: theoretically, you can
> swap Hibernate for EclipseLink, OpenJPA, or another
> JPA provider by changing configuration. In practice:
> most projects use Hibernate-specific features and
> annotations, making portability theoretical.

---

### 📘 Concept Explanation

**The JPA stack:**

```
  ABSTRACTION LAYERS

  Spring Data JPA         (repository pattern)
  findById(), save()
  Derived query methods
          |
          v
  JPA Specification        (javax/jakarta.persistence)
  EntityManager
  JPQL queries
  @Entity, @Id annotations
          |
          v
  Hibernate ORM            (JPA provider / implementation)
  SessionFactory = EntityManagerFactory
  Session = EntityManager
  HQL (superset of JPQL)
  Hibernate-specific extensions
          |
          v
  JDBC / Connection Pool
          |
          v
  Database (MySQL, PostgreSQL, Oracle...)
```

---

### 💻 Code Example

**JPA API vs Hibernate-specific API**

```java
// JPA API (portable across providers):
EntityManager em = emf.createEntityManager();
Order order = em.find(Order.class, id);
TypedQuery<Order> query = em.createQuery(
    "SELECT o FROM Order o WHERE o.status = :status",
    Order.class);
query.setParameter("status", OrderStatus.PENDING);
List<Order> orders = query.getResultList();

// Hibernate-specific API (not portable):
Session session = (Session) em.unwrap(Session.class);
// StatelessSession: bypasses first-level cache
StatelessSession ss =
    sessionFactory.openStatelessSession();
// @Filter: Hibernate-specific annotation
// session.enableFilter("activeFilter")
//     .setParameter("active", true);
```

```java
// Spring Data JPA (highest abstraction):
// Implemented on top of JPA's EntityManager
public interface OrderRepository
    extends JpaRepository<Order, Long> {
    List<Order> findByStatus(OrderStatus status);
    // Spring Data generates:
    // SELECT * FROM orders WHERE status = ?

    @Query("SELECT o FROM Order o JOIN FETCH o.items " +
           "WHERE o.customerId = :customerId")
    List<Order> findWithItems(
        @Param("customerId") Long customerId);
}
```

> **Code walkthrough:** The three layers shown have different
> abstraction levels. JPA API (`EntityManager`) is portable
> but verbose. Hibernate-specific API (`Session.unwrap`) gives
> access to Hibernate extensions (`StatelessSession`,
> `@Filter`, `Interceptor`) not in the JPA spec. Spring Data
> JPA (`JpaRepository`) is the highest abstraction - derived
> query methods generate JPQL automatically from method
> names. Choose the abstraction level based on what you need:
> use Spring Data JPA by default, drop to JPA API for queries
> Spring Data cannot express, drop to Hibernate API for
> bulk operations or Hibernate-specific features.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> In practice: use Spring Data JPA for standard repository
> operations. Drop to `EntityManager` for complex JPQL
> queries. Drop to Hibernate `Session` only when you need
> Hibernate-specific features: `StatelessSession` for
> bulk processing, `@Filter` for soft-delete implementations,
> custom `UserType` for complex type mapping.
>
> The JPA portability promise is largely theoretical for
> production systems. Most Hibernate-specific extensions
> (`@BatchSize`, `@Fetch`, `@Filter`) are too valuable
> to give up for portability. Design for Hibernate but
> prefer JPA annotations where equivalent.

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | Spring Data JPA IS Hibernate | Spring Data JPA is a repository abstraction. It uses JPA's EntityManager under the hood. Hibernate is the JPA provider that implements EntityManager. They are different layers. | Conflating them makes architectural discussions confusing; understanding the stack enables better debugging |
| 2 | Switching from Hibernate to EclipseLink is easy if you use only JPA annotations | Even with pure JPA annotations, behavior differences (flush modes, caching, lazy loading proxy behavior) between providers mean switching requires significant testing. True portability requires avoiding provider-specific configuration. | Teams assume JPA portability is easy; behavior differences between providers cause subtle bugs |

---

### 🎯 Interview Deep-Dive

**[JUNIOR] Q1: What is the difference between JPA and Hibernate?**

*Why they ask:* Tests clarity on the specification vs implementation distinction.

JPA: Jakarta Persistence API. A specification (set of
interfaces and annotations). Part of the Jakarta EE
standard. `@Entity`, `@Id`, `@OneToMany`, `EntityManager`,
`JPQL` are all JPA.

Hibernate: An ORM framework that implements the JPA
specification. When you call `entityManager.find(Order.class, id)`,
it is Hibernate's code that executes the SELECT, maps
the ResultSet to an `Order` object, and manages the
first-level cache.

Spring Data JPA: builds on top of JPA. Provides `JpaRepository`,
derived query methods, and pagination. Still uses JPA's
`EntityManager` (backed by Hibernate) under the hood.

The analogy: JPA is like the JDBC spec (interfaces).
Hibernate is like a JDBC driver (implementation). You
code to the spec; the driver does the work.

*What separates good from great:* "The portability promise
of JPA is real in theory but requires deliberate avoidance
of Hibernate-specific features. Most production teams
accept the Hibernate lock-in for the functionality gains."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with the stack: Spring Data JPA -> JPA -> Hibernate -> JDBC. |
| Hiring Manager | Lead with practical usage (Spring Data JPA default, drop to Hibernate when needed). |
| Bar Raiser | Lead with when the JPA portability promise breaks and Hibernate-specific features worth the lock-in. |

---

---

# Hibernate Ecosystem and Versions

**Interview Weight:** orientation - Understanding the
Hibernate ecosystem (Hibernate ORM, Validator, Search,
Envers) and the breaking changes in Hibernate 6 (Spring
Boot 3's default) is expected at any level.

---

### 🎯 Model Answer

**30 seconds:**

> Hibernate ecosystem: Hibernate ORM (the JPA provider),
> Hibernate Validator (Bean Validation - `@NotNull`,
> `@Size`), Hibernate Search (full-text search via Lucene/
> Elasticsearch), and Hibernate Envers (entity auditing).
> Hibernate 6 (default in Spring Boot 3) brought:
> improved SQL generation, Jakarta EE namespace, type-safe
> queries (HQL), and removal of legacy APIs. The `hbm.xml`
> mapping format is deprecated in Hibernate 6.

**3 minutes:**

> Hibernate ORM project structure:
>
> - **Hibernate ORM** (core): `org.hibernate.orm:hibernate-core`.
>   The JPA provider. This is what most developers mean
>   when they say "Hibernate".
>
> - **Hibernate Validator**: `org.hibernate.validator:hibernate-validator`.
>   Implements Jakarta Bean Validation (JSR 380).
>   `@NotNull`, `@Size`, `@Email`, `@Min`, `@Max` on
>   entity fields. Triggered by Spring's `@Valid` and
>   `@Validated` annotations.
>
> - **Hibernate Search**: full-text search on JPA entities.
>   Annotations on entity fields (`@FullTextField`),
>   Hibernate Search indexes the data in Lucene (embedded)
>   or Elasticsearch/OpenSearch (remote).
>
> - **Hibernate Envers**: entity auditing. Annotate an entity
>   with `@Audited`; Hibernate Envers creates `_AUD` tables
>   and records all changes with revision numbers and
>   timestamps.
>
> Hibernate 6 key changes:
> - Jakarta EE namespace (`javax` -> `jakarta`)
> - Improved SQL generation (better DISTINCT, better
>   pagination handling)
> - `hbm.xml` format deprecated (use annotations)
> - New type system (simpler custom type mapping)
> - `Metamodel` API improvements for type-safe queries

---

### 📘 Concept Explanation

**Hibernate ecosystem components:**

```
  HIBERNATE ECOSYSTEM

  Hibernate ORM (core JPA provider)
    @Entity, @Id, @OneToMany
    SessionFactory, Session
    HQL, Criteria API
          |
          +-- Hibernate Validator
          |     @NotNull, @Size, @Email
          |     Bean Validation (JSR 380)
          |
          +-- Hibernate Search
          |     Full-text search
          |     Lucene or Elasticsearch backend
          |
          +-- Hibernate Envers
                Entity auditing
                @Audited -> creates orders_AUD table
                Revision tracking
```

---

### 💻 Code Example

**Hibernate Envers: entity auditing**

```java
// @Audited: Hibernate Envers tracks all changes
@Entity
@Audited
public class Order {
    @Id
    private Long id;
    private OrderStatus status;
    private BigDecimal total;
}

// Hibernate Envers creates:
// CREATE TABLE orders_aud (
//   id BIGINT, status VARCHAR, total DECIMAL,
//   REV INTEGER,        -- revision number
//   REVTYPE TINYINT     -- 0=INSERT,1=UPDATE,2=DELETE
// )

// Querying history:
AuditReader reader = AuditReaderFactory.get(entityManager);
List<Order> history = reader.createQuery()
    .forRevisionsOfEntity(Order.class, true, true)
    .add(AuditEntity.id().eq(orderId))
    .getResultList();
// Returns all historical snapshots of this order
```

> **Code walkthrough:** `@Audited` on an `Order` entity
> causes Hibernate Envers to intercept all INSERT, UPDATE,
> and DELETE operations. For each change, Envers writes a
> row to the `orders_aud` table with the full entity state,
> a revision number, and a revision type (0=insert, 1=update,
> 2=delete). Querying history uses `AuditReader` - the
> `forRevisionsOfEntity` query returns a list of historical
> snapshots of the entity. This gives a complete audit trail
> with no application-level code for tracking changes.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> In Spring Boot 3 projects, I default to Hibernate 6.
> The key behavioral change affecting migration from Boot 2:
> Hibernate 6 changed how it generates SQL for lazy collection
> loading (more optimal in most cases but different). If
> upgrading from Boot 2: always enable `show_sql=true` and
> compare queries before and after. Regression test all
> batch-loading and collection-fetching scenarios.
>
> Hibernate Envers is excellent for auditing requirements
> that would otherwise require application-level change
> tracking. The cost: additional tables (`_AUD`), additional
> INSERT/UPDATE on every entity change. For high-write
> entities, evaluate whether Envers overhead is acceptable
> or whether a message-based audit log (Kafka) is more
> appropriate.

---

### 🎯 Interview Deep-Dive

**[JUNIOR] Q1: What changed in Hibernate 6 that affects
Spring Boot 3 applications?** [FOUNDATION]

Key Hibernate 6 changes in Spring Boot 3 context:

1. **Jakarta EE namespace**: `javax.persistence.*` ->
   `jakarta.persistence.*`. All imports must be updated.
   Spring Boot Migrator handles this automatically.

2. **Improved SQL generation**: Hibernate 6 generates more
   optimal SQL in many cases. However: some query results
   ordering may change (Hibernate 6 is stricter about ORDER BY).
   Review queries after migration.

3. **hbm.xml deprecated**: the legacy XML mapping format
   is no longer supported. If your project uses `.hbm.xml`
   files (rare in modern projects), migrate to annotations.

4. **Type system**: Hibernate 6 replaced `UserType` API with
   `BasicType` and `@JavaType`/`@JdbcType`. Custom type
   implementations need updating.

5. **Criteria API improvements**: more type-safe, aligned
   with JPQL improvements.

*What separates good from great:* Mentioning that SQL
generation changes should be validated by running integration
tests against the same data before and after migration.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with Hibernate 6 breaking changes. |
| Hiring Manager | Lead with Envers for auditing and Validator for bean validation. |
| Bar Raiser | Lead with Hibernate ecosystem positioning (when to use each component). |
