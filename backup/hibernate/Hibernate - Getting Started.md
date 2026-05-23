---
layout: default
title: "Hibernate - Getting Started"
parent: "Hibernate"
grand_parent: "Interview Mastery"
nav_order: 2
permalink: /interview/hibernate/getting-started/
topic: Hibernate
subtopic: Getting Started
keywords:
  - Configuration and Schema Generation
  - Spring Data JPA Repository Pattern
  - CRUD Operations with EntityManager
difficulty_range: easy
status: complete
version: 3
---

# Hibernate - Getting Started

L1 Foundational keywords for JPA and Hibernate ORM - practical setup,
framework integration, and first CRUD operations.

---

---

# Configuration and Schema Generation

**TL;DR** - JPA configuration controls how Hibernate connects
to databases, generates schemas, and behaves at runtime - getting
this wrong causes silent data loss or startup failures.

---

### ≡ƒöÑ The Problem This Solves

Without a standard configuration approach, every ORM required
its own configuration format. Hibernate used `hibernate.cfg.xml`.
JPA introduced `persistence.xml`. Spring Boot replaced both with
`application.properties`. Developers had to learn three different
systems for the same ORM.

The breaking point: teams accidentally ran `ddl-auto=create` in
production and wiped their databases.

This is exactly why understanding JPA configuration, especially
`ddl-auto` modes and environment-specific profiles, is critical.

**Evolution:** Hibernate properties -> `persistence.xml` (JPA
1.0) -> Spring Boot auto-configuration (2014).

---

### ≡ƒôÿ Textbook Definition

JPA configuration encompasses data source properties (URL,
credentials, pool sizing), Hibernate properties (dialect,
logging, batch sizing), and schema management properties
(`ddl-auto` modes controlling schema generation at startup).

---

### ΓÅ▒∩╕Å Understand It in 30 Seconds

**One line:** Configuration tells Hibernate how to connect, what
SQL dialect to speak, and whether to touch the schema.

> Think of `ddl-auto` modes as house renovation: `create` =
> demolish and rebuild. `validate` = inspect for violations.
> `update` = add rooms, never demolish. `none` = hands off.

**One insight:** The single most dangerous setting is
`ddl-auto=create` in production. The most valuable is
`ddl-auto=validate`.

---

### ≡ƒö⌐ First Principles Explanation

**Core Invariants:**

1. Hibernate needs: how to connect (DataSource), how to speak
   SQL (Dialect), how to handle schema (ddl-auto)
2. Spring Boot auto-configures all three from classpath and
   properties
3. Schema management must be environment-aware

**Trade-offs:**

- **Gain:** Auto-configuration reduces boilerplate to near zero
- **Cost:** Hidden behavior makes debugging harder

---

### ≡ƒºá Mental Model / Analogy

> `create` = demolish and rebuild (dev). `create-drop` = build
> temp, demolish on exit (tests). `update` = add rooms only
> (risky). `validate` = inspect and report (safe). `none` = let
> Flyway handle everything (production).

---

### ≡ƒô╢ Gradual Depth - Five Levels

**L1 - Anyone:** You tell your app where the database is and
how to set up tables. In development, Hibernate creates tables
automatically. In production, you use migration tools.

**L2 - Junior:** The five `ddl-auto` modes: `none`, `validate`,
`update`, `create`, `create-drop`. Use `create-drop` for tests,
`validate` for production.

**L3 - Mid:** Environment-specific config with Spring profiles.
Connection pool tuning: HikariCP `maximum-pool-size` (default
10), `connection-timeout` (30s), `leak-detection-threshold`.

**L4 - Senior/Staff:** Batch sizing (`jdbc.batch_size=50`,
`order_inserts=true`), Hibernate statistics, slow query logging.
Pool sizing formula: `cores * 2 + spindle_count`.

**L5 - Distinguished:** Configuration as contract. Externalize
with ConfigMaps/Vault. Build-time vs runtime configuration
separation. 12-factor app principles for database config.

**Senior-to-Staff Leap:**

- A Senior says: "I use `ddl-auto=validate` per environment."
- A Staff says: "I externalize all datasource config to K8s
  secrets. Pool sizing is from load test results. Hibernate
  statistics feed Prometheus."
- The difference: Staff engineers treat config as infrastructure.

---

### ΓÜÖ∩╕Å How It Works

```
application.yml
       |
  Spring Boot auto-config
       |
  +-- DataSource (HikariCP)
  +-- EntityManagerFactory
  |   (ddl-auto, dialect)
  +-- JPA properties
      (show-sql, batch-size)
```

---

### ≡ƒöä Complete Picture - End-to-End Flow

```
Spring Boot starts
  -> Load application-{profile}.yml
  -> Create HikariCP DataSource      <- POOL
  -> Create EntityManagerFactory
  -> Execute ddl-auto mode           <- HERE
  -> Run Flyway (if on classpath)
  -> Application ready
```

**Failure path:** Wrong URL -> connection refused. Wrong
`ddl-auto` -> data loss or startup failure.

---

### ≡ƒÆ╗ Code Example

**BAD - Same config for all environments:**

```properties
# BAD: Dangerous in production!
spring.datasource.url=jdbc:h2:mem:test
spring.jpa.hibernate.ddl-auto=create
spring.jpa.show-sql=true
```

**GOOD - Profile-based config:**

```yaml
# application-prod.yml
spring:
  datasource:
    url: ${DB_URL}
    username: ${DB_USER}
    password: ${DB_PASS}
    hikari:
      maximum-pool-size: 10
      leak-detection-threshold: 60000
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        jdbc.batch_size: 50
        order_inserts: true
        generate_statistics: true
```

**How to test:** Use `@DataJpaTest` with `ddl-auto=create-drop`.
In CI, run with `ddl-auto=validate` against Flyway-migrated DB.

---

### ≡ƒôî Quick Reference Card

| Field              | Value                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------- |
| **WHAT IT IS**     | Settings for DB connection, schema, ORM behavior                                      |
| **PROBLEM**        | Same config in dev/prod causes data loss                                              |
| **KEY INSIGHT**    | ddl-auto must be environment-aware                                                    |
| **USE WHEN**       | Every Spring Boot JPA app                                                             |
| **AVOID WHEN**     | N/A                                                                                   |
| **ANTI-PATTERN**   | `ddl-auto=create` or `update` in production                                           |
| **TRADE-OFF**      | Auto-config convenience vs explicit control                                           |
| **ONE-LINER**      | create-drop for tests, validate for production                                        |
| **KEY NUMBERS**    | 5 ddl-auto modes, default pool size 10                                                |
| **TRIGGER PHRASE** | "How do you configure Hibernate?"                                                     |
| **OPENING SENT**   | "JPA configuration controls database connection, SQL dialect, and schema management." |

**If you remember only 3 things:**

1. Never use `ddl-auto=create` or `update` in production
2. Use Spring profiles for environment-specific config
3. Externalize credentials - never hardcode

**Interview one-liner:** "Use ddl-auto=create-drop for tests,
validate for production, and Flyway for schema migration."

---

### Γ£à Mastery Checklist

- [ ] **EXPLAIN** all five `ddl-auto` modes and their risks
- [ ] **DEBUG** a schema validation startup failure
- [ ] **DECIDE** HikariCP pool size using the sizing formula
- [ ] **BUILD** multi-profile Spring Boot JPA configuration
- [ ] **EXTEND** to multi-datasource read/write splitting

---

### ≡ƒÆí The Surprising Truth

Spring Boot auto-detects your database type from the JDBC URL
and selects the Hibernate dialect automatically. You rarely need
to set `hibernate.dialect` explicitly.

---

### ΓÜá∩╕Å Common Misconceptions

| #   | Misconception                                  | Reality                                                                   |
| --- | ---------------------------------------------- | ------------------------------------------------------------------------- |
| 1   | "ddl-auto=update is safe for production"       | It only adds, never drops or renames. Accumulates schema cruft.           |
| 2   | "show-sql=true is fine in production"          | Causes I/O overhead and log flooding. Use statistics instead.             |
| 3   | "Spring Boot handles all config automatically" | Defaults work but production needs explicit pool sizing and batch config. |
| 4   | "I need persistence.xml with Spring Boot"      | Spring Boot replaces it entirely via auto-configuration.                  |

---

### ≡ƒÜ¿ Failure Modes and Diagnosis

**Mode 1: Data Loss from Wrong ddl-auto**

- **Symptom:** Production tables empty after deployment
- **Root Cause:** `ddl-auto=create` dropped and recreated tables
- **Diagnostic:** Check logs for `drop table` at startup
- **Fix:** Set `ddl-auto=validate` + use Flyway
- **Prevention:** CI check that ddl-auto is validate in prod

**Mode 2: Connection Pool Exhaustion**

- **Symptom:** Requests hang, `ConnectionTimeoutException`
- **Root Cause:** Pool too small or connections leaking
- **Diagnostic:** `hikaricp_connections_pending` metric
- **Fix:** Size pool with formula, fix leaks,
  set `leak-detection-threshold`

**Mode 3: Schema Validation Failure**

- **Symptom:** `SchemaManagementException` at startup
- **Root Cause:** Annotations do not match database schema
- **Fix:** Write Flyway migration to sync schema

---

### ≡ƒÄ» Interview Deep-Dive

| Difficulty | Time  | Questions | Focus Areas                     |
| ---------- | ----- | --------- | ------------------------------- |
| Easy       | 30min | 7         | ddl-auto, profiles, pool config |

**Q1 [JUNIOR] - CONCEPTUAL: What are the different ddl-auto
modes and when do you use each?**

_Why they ask:_ Tests configuration knowledge and production
awareness.

Five modes: `none` (do nothing, let migration tools manage),
`validate` (compare metadata vs schema, throw if mismatch),
`update` (add missing columns/tables, never drop), `create`
(drop all + create), `create-drop` (create + drop on shutdown).

Environment mapping: `create-drop` for tests, `create`/`update`
for local dev, `validate` for staging/prod, `none` for prod with
Flyway.

The key insight: `update` is dangerous because it never drops
columns, accumulating cruft. It cannot rename columns or migrate
data. `validate` + Flyway is the production-safe strategy.

_What separates good from great:_ Great answers explain why
`update` is dangerous and recommend `validate` + Flyway.

_Likely follow-up:_ "What happens if validate fails?"

---

**Q2 [JUNIOR] - DEBUGGING: App works locally but fails in
staging with schema validation error. What do you check?**

_Why they ask:_ Tests real debugging workflow.

Local dev uses `ddl-auto=create-drop` with H2 (rebuilds schema
each time). Staging uses `ddl-auto=validate` with PostgreSQL
(checks against actual schema).

Check: (1) Read exception for specific table/column mismatch.
(2) Compare entity annotations with staging schema. (3) Common
issues: column name case sensitivity (H2 vs PostgreSQL), missing
migration, type differences.

Fix: write a Flyway migration to sync the schema with annotations.

_What separates good from great:_ Great answers identify
database-specific differences as root cause.

_Likely follow-up:_ "How do you prevent this in CI?"

---

**Q3 [MID] - TRADE-OFF: Flyway vs Liquibase?**

_Why they ask:_ Tests strategic tooling decisions.

Flyway uses raw SQL files - full SQL power, simple mental model,
database-specific. Liquibase uses abstract changelogs
(XML/YAML) - database-agnostic, supports rollback generation.

Use Flyway for most Spring Boot apps (simpler, SQL-first). Use
Liquibase when supporting multiple database vendors or needing
automated rollback.

_What separates good from great:_ Great answers give specific
decision criteria, not just feature lists.

_Likely follow-up:_ "How do you handle Flyway in CI/CD?"

---

**Q4 [MID] - PRODUCTION: How do you size HikariCP pool?**

_Why they ask:_ Tests production operations knowledge.

Formula: `pool_size = (core_count * 2) + spindle_count`. For
SSD: `cores * 2 + 1`. Default of 10 is good for most workloads.

Key settings: `maximum-pool-size=10`, `minimum-idle=10` (keep
equal), `connection-timeout=30000`,
`leak-detection-threshold=60000`.

Monitor: `hikaricp_connections_active` (near max = saturated),
`hikaricp_connections_pending` (> 0 = waiting).

_What separates good from great:_ Great answers know the formula
and explain why larger pools hurt performance.

_Likely follow-up:_ "What happens when pool is exhausted?"

---

**Q5 [MID] - DEBUGGING: Startup takes 60s instead of 10s.
What could cause this?**

_Why they ask:_ Tests startup performance understanding.

Possible causes: (1) `ddl-auto=update` on large schema. (2)
Database connectivity issues (DNS, firewall). (3) Flyway
migration on large dataset. (4) Broad entity scanning scope.
(5) Hibernate metadata compilation for hundreds of entities.

Diagnosis: startup actuator, Hibernate statistics, JFR profiling.

_What separates good from great:_ Systematic check of each cause
rather than guessing.

_Likely follow-up:_ "How would you reduce startup time?"

---

**Q6 [JUNIOR] - HANDS-ON: Show complete Spring Boot JPA config
for dev and prod.**

_Why they ask:_ Tests practical configuration knowledge.

Dev: H2 in-memory, `ddl-auto: create-drop`, `show-sql: true`.
Prod: externalized credentials, `ddl-auto: validate`,
`show-sql: false`, batch config, Flyway enabled.

Key decisions: `open-in-view: false`, environment variables for
credentials, batch configuration for write performance.

_What separates good from great:_ Include `open-in-view: false`
as a best practice.

_Likely follow-up:_ "How do you manage multiple datasources?"

---

**Q7 [JUNIOR] - CONCEPTUAL: persistence.xml vs
application.properties?**

_Why they ask:_ Tests traditional vs modern configuration.

`persistence.xml` is JPA standard, mandatory before Spring Boot.
Spring Boot replaces it entirely via auto-configuration - entity
scanning, DataSource creation, and property mapping all happen
automatically from `application.properties`.

Use persistence.xml only for non-Spring JPA apps or multiple
persistence units.

_What separates good from great:_ Explain that Spring Boot
auto-config completely replaces persistence.xml.

_Likely follow-up:_ "How do you define multiple persistence
units in Spring Boot?"

---

### ≡ƒöù Related Keywords

**Prerequisites:**

- JPA Annotations - what gets configured
- Session and SessionFactory - what configuration creates

**Builds on this:**

- HikariCP Connection Pool - deep pool configuration
- Hibernate Statistics - production observability

**Alternatives:**

- persistence.xml - traditional JPA configuration
- Programmatic configuration - Java-based setup

---

---

# Spring Data JPA Repository Pattern

**TL;DR** - Spring Data JPA eliminates boilerplate data access
code by generating repository implementations from interface
method names at runtime.

---

### ≡ƒöÑ The Problem This Solves

Before Spring Data, every entity required a hand-written DAO
with repetitive CRUD. For 50 entities, you wrote 50 DAOs with
nearly identical code. 80% of methods were trivial variations.

This is exactly why Spring Data JPA generates implementations
at runtime from interface method signatures.

**Evolution:** Spring Data 1.0 (2011) -> `@Query` (1.4) ->
`Optional` (2.0) -> Jakarta namespace (3.0).

---

### ≡ƒôÿ Textbook Definition

Spring Data JPA provides automatic implementation of repository
interfaces. Extending `JpaRepository<T, ID>` gives CRUD,
paging, sorting, and derived query methods without implementation
code.

---

### ΓÅ▒∩╕Å Understand It in 30 Seconds

**One line:** Declare a repository interface with method names
that describe the query - Spring writes the implementation.

> Like a personal assistant who understands "find users by email
> and active is true" and writes the SQL query for you.

**One insight:** Spring Data sits on top of JPA. Every generated
method calls `EntityManager`. Understanding what is underneath
is essential for debugging.

---

### ≡ƒö⌐ First Principles Explanation

**Core Invariants:**

1. Repository is an interface - Spring generates implementation
2. Method names are parsed into queries at startup
3. Generated code delegates to `EntityManager`

**Trade-offs:**

- **Gain:** Zero boilerplate for 80% of data access
- **Cost:** Hidden query generation, long method names

---

### ≡ƒºá Mental Model / Analogy

> Autocomplete for database queries. `findByEmailAndActiveTrue`
> autocompletes to `SELECT * FROM users WHERE email = ? AND
active = true`.

---

### ≡ƒô╢ Gradual Depth - Five Levels

**L1 - Anyone:** Create an interface with method names
describing what you want. Spring generates the query code.

**L2 - Junior:** Repository hierarchy: `CrudRepository` (basic
CRUD) -> `PagingAndSortingRepository` (pagination) ->
`JpaRepository` (JPA-specific methods).

**L3 - Mid:** `@Query` for complex queries. Projections for
partial loading. Custom implementations for business logic.

**L4 - Senior/Staff:** Performance: verify generated SQL,
use projections, `deleteAllInBatch()` for bulk ops,
`@EntityGraph` for fetch control.

**L5 - Distinguished:** Repository pattern from DDD. Repositories
as aggregate boundaries. Domain-driven persistence design.

**Senior-to-Staff Leap:**

- A Senior says: "I use repositories for all data access."
- A Staff says: "Repositories for CRUD, custom implementations
  for complex logic, projections for reads. Repositories expose
  aggregate roots."
- The difference: Right abstraction level per query.

---

### ΓÜÖ∩╕Å How It Works

```
interface UserRepository
  extends JpaRepository<User, Long>
       |
  Spring scans at startup
       |
  Parse method names -> JPQL
  Create JDK dynamic proxy
  Register as Spring bean
       |
  Runtime: proxy -> EntityManager
```

---

### ≡ƒöä Complete Picture - End-to-End Flow

```
Controller calls repo method
  -> JDK Proxy intercepts
  -> Parse method name to JPQL
  -> EntityManager.createQuery()
  -> Hibernate generates SQL
  -> JDBC -> Database
  -> Result mapping
  -> Return List<Entity>
```

---

### ≡ƒÆ╗ Code Example

**BAD - Hand-written DAO:**

```java
@Repository
public class UserDaoImpl {
    @PersistenceContext
    private EntityManager em;

    public List<User> findByActiveTrue() {
        return em.createQuery(
            "SELECT u FROM User u"
            + " WHERE u.active = true",
            User.class
        ).getResultList();
    }
    // + save(), findById(), delete()...
}
```

**GOOD - Spring Data repository:**

```java
public interface UserRepository
    extends JpaRepository<User, Long> {

    List<User> findByActiveTrue();

    @EntityGraph(attributePaths = "roles")
    Optional<User> findWithRolesById(
        Long id
    );

    @Query("SELECT u FROM User u "
        + "WHERE u.department.name = :d")
    List<User> findByDeptName(
        @Param("d") String dept
    );

    @Modifying
    @Query("UPDATE User u "
        + "SET u.active = false "
        + "WHERE u.lastLogin < :d")
    int deactivateOld(
        @Param("d") LocalDate date
    );
}
```

**How to test:** `@DataJpaTest` with embedded database.

---

### ≡ƒôî Quick Reference Card

| Field              | Value                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------- |
| **WHAT IT IS**     | Auto-implemented repository interfaces                                                |
| **PROBLEM**        | Repetitive DAO boilerplate                                                            |
| **KEY INSIGHT**    | Method names ARE the query specification                                              |
| **USE WHEN**       | CRUD and simple queries (80%)                                                         |
| **AVOID WHEN**     | Complex dynamic queries, bulk operations                                              |
| **ANTI-PATTERN**   | 200-char method names for complex queries                                             |
| **TRADE-OFF**      | Zero boilerplate vs hidden query generation                                           |
| **ONE-LINER**      | Declare interface, Spring writes implementation                                       |
| **KEY NUMBERS**    | 80% queries need no code                                                              |
| **TRIGGER PHRASE** | "How does Spring Data JPA work?"                                                      |
| **OPENING SENT**   | "Spring Data generates repository implementations by parsing method names into JPQL." |

**If you remember only 3 things:**

1. Extend `JpaRepository<Entity, IdType>`
2. Method names are parsed into queries
3. Use `@Query` for complex cases

**Interview one-liner:** "Spring Data generates implementations
by parsing method names into JPQL at startup, with @Query and
custom implementations as escape hatches."

---

### Γ£à Mastery Checklist

- [ ] **EXPLAIN** how Spring generates implementations (proxy +
      method name parsing)
- [ ] **DEBUG** a `PropertyReferenceException`
- [ ] **DECIDE** derived query vs `@Query` vs custom impl
- [ ] **BUILD** repository with projections and `@EntityGraph`
- [ ] **EXTEND** to DDD aggregate boundaries

---

### ≡ƒÆí The Surprising Truth

`deleteAll()` does NOT execute `DELETE FROM table`. It loads
every entity then calls `remove()` on each one. Use
`deleteAllInBatch()` for single-statement DELETE.

---

### ΓÜá∩╕Å Common Misconceptions

| #   | Misconception                        | Reality                                           |
| --- | ------------------------------------ | ------------------------------------------------- |
| 1   | "Spring Data is an ORM"              | It is an abstraction on top of JPA/Hibernate.     |
| 2   | "Derived queries are always optimal" | Method name parsing does not optimize SQL.        |
| 3   | "save() is always needed"            | Managed entities are dirty-checked automatically. |
| 4   | "findAll() is safe for any table"    | Loads everything into memory. Use Pageable.       |

---

### ≡ƒÜ¿ Failure Modes and Diagnosis

**Mode 1: PropertyReferenceException at Startup**

- **Symptom:** App fails to start, typo in method name
- **Fix:** Correct method name to match entity property

**Mode 2: N+1 from findAll() with Lazy Associations**

- **Symptom:** findAll() takes seconds
- **Fix:** Use `@EntityGraph` or DTO projections

**Mode 3: Unexpected Full-Table Scan**

- **Symptom:** `findByFieldContaining()` slow
- **Root Cause:** `LIKE '%value%'` cannot use indexes
- **Fix:** Use full-text search or `StartingWith`

---

### ≡ƒÄ» Interview Deep-Dive

| Difficulty | Time  | Questions | Focus Areas                      |
| ---------- | ----- | --------- | -------------------------------- |
| Easy       | 30min | 7         | Interfaces, queries, performance |

**Q1 [JUNIOR] - CONCEPTUAL: How does Spring Data generate
repository implementations?**

_Why they ask:_ Tests mechanism understanding.

At startup, Spring scans for interfaces extending `Repository`.
For each, it creates a JDK dynamic proxy. For inherited CRUD
methods, it uses pre-built implementations delegating to
`EntityManager`. For derived query methods, it parses method
names into JPQL at startup and stores compiled query templates.
At runtime, the proxy intercepts calls, binds parameters, and
executes via EntityManager.

Key advantage: all validation at startup (fail-fast). A
misspelled property name fails immediately, not at runtime.

_What separates good from great:_ Explain startup-time validation
and proxy mechanism.

_Likely follow-up:_ "What return types can methods have?"

---

**Q2 [JUNIOR] - HANDS-ON: Write a repository for Product with
various query methods.**

_Why they ask:_ Tests practical usage.

```java
public interface ProductRepository
    extends JpaRepository<Product, Long> {
    List<Product> findByCategory(String c);
    List<Product> findByPriceLessThan(
        BigDecimal max);
    Page<Product> findByActiveTrue(
        Pageable p);
    long countByCategory(String c);
    boolean existsByName(String name);
    @Query("SELECT p FROM Product p "
        + "WHERE p.price BETWEEN :min "
        + "AND :max")
    List<Product> findInRange(
        @Param("min") BigDecimal min,
        @Param("max") BigDecimal max);
}
```

_What separates good from great:_ Include pagination, count,
exists, and @Query examples.

_Likely follow-up:_ "How to add custom implementation?"

---

**Q3 [MID] - TRADE-OFF: Derived queries vs @Query vs custom
implementation?**

_Why they ask:_ Tests judgment about abstraction levels.

Derived: simple 1-3 condition queries that read naturally.
@Query: joins, subqueries, aggregations. Custom impl: dynamic
criteria, batch operations, non-JPA integration.

Heuristic: method name fits one line -> derived. Query fits 3-5
lines JPQL -> @Query. Programmatic logic needed -> custom.

_What separates good from great:_ The character-length heuristic
and code smell example.

_Likely follow-up:_ "How do Specifications compare?"

---

**Q4 [MID] - DEBUGGING: findByDepartmentName() generates a
JOIN. Why?**

_Why they ask:_ Tests query derivation understanding.

`department` is a `@ManyToOne` relationship. Spring traverses
it: `findByDepartmentName` -> `JOIN department WHERE
department.name = ?`. This is correct, not a bug.

If you expected `WHERE department_name = ?`, you need a direct
field or explicit `@Query`.

_What separates good from great:_ Explain relationship traversal
is by design.

_Likely follow-up:_ "How to optimize too many JOINs?"

---

**Q5 [MID] - PRODUCTION: How to handle pagination correctly?**

_Why they ask:_ Tests commonly misused feature.

`Page<T>` = two queries (data + COUNT). `Slice<T>` = one query
(N+1 records). Use Page for "Page 3 of 47". Use Slice for
infinite scroll (faster, no COUNT).

Deep pagination pitfall: `OFFSET 100000 LIMIT 20` scans 100,020
rows. Use keyset pagination via `@Query` for deep offsets.

_What separates good from great:_ Distinguish Page vs Slice and
mention keyset pagination.

_Likely follow-up:_ "How to implement keyset pagination?"

---

**Q6 [JUNIOR] - COMPARISON: CrudRepository vs JpaRepository vs
PagingAndSortingRepository?**

_Why they ask:_ Tests hierarchy knowledge.

`CrudRepository`: basic CRUD. `PagingAndSortingRepository`: adds
pagination/sorting. `JpaRepository`: adds flush, batch delete,
Example queries.

Recommendation: always use `JpaRepository` in Spring Boot.
Exception: restricted read-only repositories.

_What separates good from great:_ Practical recommendation with
reasoning.

_Likely follow-up:_ "How to create read-only repository?"

---

**Q7 [JUNIOR] - CONCEPTUAL: What happens when Spring cannot
parse a method name?**

_Why they ask:_ Tests error handling knowledge.

Application fails to start with clear error. Common failures:
`PropertyReferenceException` (typo), ambiguous resolution
(direct field vs relationship traversal). Spring resolves
ambiguity: direct property first, then relationship traversal.

Advantage over raw JPQL: startup-time validation catches all
parsing errors.

_What separates good from great:_ Explain ambiguity resolution
rules.

_Likely follow-up:_ "How does Spring resolve ambiguous names?"

---

### ≡ƒöù Related Keywords

**Prerequisites:**

- JPA Annotations - entity structure repositories operate on
- EntityManager - underlying API repositories delegate to

**Builds on this:**

- DTO Projections - performance optimization
- Criteria API - programmatic dynamic queries

**Alternatives:**

- Manual DAO with EntityManager
- jOOQ - type-safe SQL
- MyBatis - SQL mapping framework

---

---

# CRUD Operations with EntityManager

**TL;DR** - EntityManager provides the four fundamental
persistence operations (persist, find, merge, remove) that
underpin all JPA data access, including Spring Data repositories.

---

### ≡ƒöÑ The Problem This Solves

Without a standard API, every ORM had its own method names.
Hibernate used `save()`, TopLink used `writeObject()`. JPA
standardized four operations with clearly specified semantics.

**Evolution:** JPA 1.0 (2006) defined core CRUD. JPA 2.0 added
Criteria API. JPA 2.2 added Stream results.

---

### ≡ƒôÿ Textbook Definition

`EntityManager` is the primary JPA interface for persistence
context interaction. It provides `persist` (INSERT), `find`
(SELECT by PK), `merge` (copy detached state), `remove`
(DELETE), and query creation methods.

---

### ΓÅ▒∩╕Å Understand It in 30 Seconds

**One line:** EntityManager is your single point of contact for
all JPA database operations.

> Like a bank teller: deposit (persist), check balance (find),
> update address (merge), close account (remove).

**One insight:** There is no `update()` method. JPA handles
updates through dirty checking on managed entities.

---

### ≡ƒö⌐ First Principles Explanation

**Core Invariants:**

1. `persist()` = transient -> managed (INSERT)
2. `find()` = returns managed entity or null
3. `merge()` = returns managed copy (argument stays detached)
4. `remove()` = requires managed entity (DELETE)

**Trade-offs:**

- **Gain:** Standard API, predictable semantics
- **Cost:** Requires understanding entity states

---

### ≡ƒºá Mental Model / Analogy

> Shopping cart: `persist()` = add item. `find()` = barcode
> lookup. `merge()` = replace item. `remove()` = take out.
> `flush()` = checkout.

---

### ≡ƒô╢ Gradual Depth - Five Levels

**L1 - Anyone:** EntityManager saves, finds, updates, and
deletes data in a database using Java.

**L2 - Junior:** Four operations: `persist()`, `find()`,
`merge()`, `remove()`. No explicit `update()` - modify managed
entities and dirty checking generates UPDATE.

**L3 - Mid:** Additional: `getReference()` (lazy proxy),
`createQuery()`, `flush()`, `clear()`, `detach()`, `contains()`.

**L4 - Senior/Staff:** Batch operations need flush/clear cycles.
`em.unwrap(Session.class)` for Hibernate-specific features.
StatelessSession for bulk imports.

**L5 - Distinguished:** EntityManager implements Unit of Work
pattern. Same pattern in Hibernate Session, EF DbContext,
Django ORM.

**Senior-to-Staff Leap:**

- A Senior says: "I use persist() and find() for CRUD."
- A Staff says: "Repositories for CRUD, EntityManager for batch
  ops and Criteria API, unwrap to Session for StatelessSession."
- The difference: Right abstraction level per use case.

---

### ΓÜÖ∩╕Å How It Works

```
em.persist(entity)
  -> Add to identity map
  -> Queue INSERT
       |
em.find(Class, id)
  -> Check identity map first
  -> If not cached: SELECT from DB
       |
em.merge(detached)
  -> SELECT current state
  -> Copy fields to managed copy
  -> Queue UPDATE if changed
       |
em.remove(managed)
  -> Queue DELETE
       |
flush() or commit
  -> Execute all queued SQL
```

---

### ≡ƒöä Complete Picture - End-to-End Flow

```
@Transactional method starts
  -> EM created
  -> persist(new) -> INSERT queued
  -> find(id) -> SELECT + cache
  -> modify managed entity -> dirty
  -> remove(entity) -> DELETE queued
  -> Method returns
  -> flush: INSERT, UPDATE, DELETE
  -> commit
  -> EM closed, all detached
```

---

### ≡ƒÆ╗ Code Example

**BAD - Incorrect usage:**

```java
// BAD: null check missing, detached remove
User user = em.find(User.class, id);
user.setName("New"); // NPE if null!

Order old = getDetachedOrder();
em.remove(old); // IllegalArgumentException!
```

**GOOD - Correct usage:**

```java
@Transactional
public void process(OrderDto dto) {
    User user = em.find(
        User.class, dto.getUserId()
    );
    if (user == null) {
        throw new NotFoundException(
            "User " + dto.getUserId()
        );
    }

    Order order = new Order();
    order.setCustomer(user);
    em.persist(order);

    user.setLastOrderDate(Instant.now());
    // No save needed - dirty checking

    if (dto.getOldOrderId() != null) {
        Order old = em.find(
            Order.class, dto.getOldOrderId()
        );
        if (old != null) em.remove(old);
    }
}
```

**How to test:** Enable `show-sql`, verify correct SQL. Use
`em.contains()` to verify entity states in tests.

---

### ≡ƒôî Quick Reference Card

| Field              | Value                                                                        |
| ------------------ | ---------------------------------------------------------------------------- |
| **WHAT IT IS**     | JPA's standard CRUD + context management API                                 |
| **PROBLEM**        | Vendor-specific ORM APIs                                                     |
| **KEY INSIGHT**    | No update() - dirty checking handles it                                      |
| **USE WHEN**       | Batch ops, complex queries, beyond repos                                     |
| **AVOID WHEN**     | Simple CRUD (use Spring Data)                                                |
| **ANTI-PATTERN**   | remove() on detached entity                                                  |
| **TRADE-OFF**      | Full control vs more boilerplate                                             |
| **ONE-LINER**      | persist=INSERT, find=SELECT, merge=copy, remove=DELETE                       |
| **KEY NUMBERS**    | 4 CRUD ops, 6 context methods                                                |
| **TRIGGER PHRASE** | "How do you use EntityManager?"                                              |
| **OPENING SENT**   | "EntityManager provides four operations that every repository delegates to." |

**If you remember only 3 things:**

1. No update() - dirty checking handles it
2. find() returns null, not exception
3. merge() returns managed copy - use the return value

**Interview one-liner:** "persist, find, merge, remove -
no update() because dirty checking on managed entities
generates UPDATEs automatically."

---

### Γ£à Mastery Checklist

- [ ] **EXPLAIN** why no update() method exists
- [ ] **DEBUG** IllegalArgumentException from remove() on
      detached entity
- [ ] **DECIDE** when EntityManager vs repositories
- [ ] **BUILD** batch import with flush/clear cycles
- [ ] **EXTEND** to getReference() for lazy proxy loading

---

### ≡ƒÆí The Surprising Truth

`em.getReference()` returns a proxy without any SQL. Perfect for
setting FKs: `order.setUser(em.getReference(User.class, userId))`
avoids loading the full User just to set a FK column.

---

### ΓÜá∩╕Å Common Misconceptions

| #   | Misconception                         | Reality                                                       |
| --- | ------------------------------------- | ------------------------------------------------------------- |
| 1   | "JPA has an update() method"          | No. Modify managed entities; dirty checking generates UPDATE. |
| 2   | "find() throws for missing entities"  | find() returns null. getReference() throws on access.         |
| 3   | "persist() writes immediately"        | persist() queues INSERT. SQL executes at flush.               |
| 4   | "I need EntityManager for everything" | Repositories handle 80%. EntityManager for complex cases.     |

---

### ≡ƒÜ¿ Failure Modes and Diagnosis

**Mode 1: IllegalArgumentException on remove()**

- **Symptom:** Removing detached entity
- **Fix:** `em.remove(em.find(Entity.class, id))`

**Mode 2: TransactionRequiredException**

- **Symptom:** Write operation outside @Transactional
- **Fix:** Add @Transactional, ensure proxy call

**Mode 3: OptimisticLockException on merge()**

- **Symptom:** Concurrent modification detected
- **Fix:** Reload entity, apply conflict resolution

---

### ≡ƒÄ» Interview Deep-Dive

| Difficulty | Time  | Questions | Focus Areas                |
| ---------- | ----- | --------- | -------------------------- |
| Easy       | 30min | 7         | CRUD ops, states, patterns |

**Q1 [JUNIOR] - CONCEPTUAL: What are the four core CRUD
operations in EntityManager?**

_Why they ask:_ Tests fundamental API knowledge.

persist() = transient -> managed, queues INSERT. find() = load by
PK, returns managed entity or null. merge() = copies detached
state to managed copy, returns copy. remove() = managed ->
removed, queues DELETE. No update() - dirty checking handles it.

_What separates good from great:_ Explain no update() and dirty
checking.

_Likely follow-up:_ "Difference between find() and
getReference()?"

---

**Q2 [JUNIOR] - DEBUGGING: persist() on entity with manually
set ID throws EntityExistsException. Why?**

_Why they ask:_ Tests persist() semantics.

persist() is for NEW entities. If ID exists in DB, it is a
duplicate PK. Use merge() for existing entities, or let
@GeneratedValue handle ID assignment.

Spring Data save() avoids this by checking isNew() internally.

_What separates good from great:_ Cover all scenarios and
mention how save() handles it.

_Likely follow-up:_ "How does save() decide persist vs merge?"

---

**Q3 [MID] - TRADE-OFF: find() vs getReference()?**

_Why they ask:_ Tests proxy understanding.

find() = immediate SELECT, returns entity or null. getReference()
= returns proxy, no SQL until non-ID field accessed. Use
getReference() for FK assignment only.

Risk: getReference() defers EntityNotFoundException until access.

_What separates good from great:_ Show FK assignment use case.

_Likely follow-up:_ "What if you serialize a proxy?"

---

**Q4 [MID] - PRODUCTION: How to implement efficient batch
inserts?**

_Why they ask:_ Tests memory management knowledge.

Periodic flush/clear: `em.flush(); em.clear();` every 50 records.
Configure `jdbc.batch_size=50`, `order_inserts=true`.

For highest throughput: StatelessSession with no identity map.

_What separates good from great:_ Show both patterns with config.

_Likely follow-up:_ "What happens to cascades on em.clear()?"

---

**Q5 [JUNIOR] - HANDS-ON: Write a service using EntityManager
for CRUD.**

_Why they ask:_ Tests practical usage.

Show: `em.persist()` for create, `em.find()` with null check,
field modification for update (no save), `em.find()` then
`em.remove()` for delete. Use `getReference()` for FK
assignment.

_What separates good from great:_ Use getReference() and
explain why no save needed for updates.

_Likely follow-up:_ "Convert to Spring Data repositories?"

---

**Q6 [MID] - DEBUGGING: persist() does not execute SQL
immediately. Is this a bug?**

_Why they ask:_ Tests write-behind understanding.

Not a bug. JPA uses write-behind: persist() queues INSERT, SQL
executes at flush (before queries, at commit, or explicit
flush()). Enables batching, ordering, deduplication.

Exception: IDENTITY strategy forces immediate INSERT for ID
generation. SEQUENCE is preferred.

_What separates good from great:_ Explain IDENTITY exception.

_Likely follow-up:_ "Why prefer SEQUENCE over IDENTITY?"

---

**Q7 [JUNIOR] - CONCEPTUAL: Relationship between EntityManager
and CrudRepository.save()?**

_Why they ask:_ Tests abstraction layer understanding.

save() = if isNew() then persist() else merge(). isNew() checks
if @Id is null. For managed entities, save() is redundant
(dirty checking handles updates). For assigned IDs, implement
Persistable to customize isNew().

_What separates good from great:_ Show SimpleJpaRepository
source and mention Persistable.

_Likely follow-up:_ "When is save() on managed entity wasteful?"

---

### ≡ƒöù Related Keywords

**Prerequisites:**

- Entity States and Lifecycle - essential for correct usage
- Session and SessionFactory - EntityManager wraps Session

**Builds on this:**

- Spring Data JPA Repository Pattern - abstraction on top
- Dirty Checking and Flush Modes - change detection mechanics

**Alternatives:**

- JpaRepository - higher-level abstraction
- JdbcTemplate - direct SQL
- StatelessSession - no identity map
