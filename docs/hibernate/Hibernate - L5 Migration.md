---
layout: default
title: "Hibernate - L5 Migration"
parent: "Hibernate"
grand_parent: "SK Interview"
nav_order: 10
permalink: /hibernate/l5-migration/
---

## Keywords in This File

{: .no_toc }

| # | Keyword | Weight |
| --- | --- | --- |
| 1 | [Migrating from Hibernate to Spring Data JPA](#migrating-from-hibernate-to-spring-data-jpa) | high |

---

# Migrating from Hibernate to Spring Data JPA

**TL;DR** - Spring Data JPA is not a replacement for Hibernate - it is
a repository abstraction layer built ON TOP of JPA (which Hibernate
implements). Migrating means replacing direct `SessionFactory`/`Session`
use with `JpaRepository` interfaces, shifting from HQL to derived query
methods or `@Query`, and delegating transaction management to Spring's
`@Transactional`.

---

### 🎯 Model Answer

**30 seconds:**
> Spring Data JPA does not replace Hibernate - Hibernate remains the JPA
> provider underneath. The migration is from using Hibernate's proprietary
> API (`SessionFactory`, `Session`, HQL) to using the JPA standard API
> (`EntityManagerFactory`, `EntityManager`, JPQL) exposed through
> Spring Data's `JpaRepository` interfaces. The benefit: less boilerplate
> code, standardized transaction management via `@Transactional`, and
> query derivation from method names instead of manual HQL strings.
> The risk: losing Hibernate-specific features like `StatelessSession`,
> multi-tenancy API, and advanced query options.

**3 minutes (Senior):**
> The migration is incremental by nature - you rarely migrate an entire
> application at once. The key layers to migrate are: (1) data access objects
> (DAOs using `Session`) to `JpaRepository` or `@Repository` classes using
> `EntityManager`; (2) transaction management from `session.beginTransaction()`
> to `@Transactional`; (3) HQL queries to JPQL or Spring Data query methods;
> (4) entity configuration from Hibernate XML mappings to JPA annotations (if
> still using XML).
>
> The migration preserves all entity annotations - JPA annotations (`@Entity`,
> `@Table`, `@Column`, `@OneToMany`, etc.) are identical between native
> Hibernate and Spring Data JPA. Only the data access layer changes.
>
> What you gain: `JpaRepository` provides `findById()`, `save()`, `delete()`,
> `findAll()` for free. Derived query methods (`findByStatusAndCreatedAtAfter`)
> eliminate HQL boilerplate for simple queries. Spring's `@Transactional`
> is more composable than manual transaction management.
>
> What you lose: `StatelessSession` (no equivalent in Spring Data JPA -
> must inject the `EntityManager` directly for batch processing),
> Hibernate-specific query options (transform, scroll results), and some
> multi-tenancy features. You can always fall back to `entityManager.unwrap(Session.class)`
> to access Hibernate-specific APIs when needed.
>
> Migration risk: implicit behavior changes. Spring Data's `@Transactional`
> on `@Repository` methods has slightly different propagation semantics
> than manual transaction management. Open Session In View (OSIV) is
> enabled by default in Spring Boot and may mask `LazyInitializationException`
> issues that were previously explicit.

*Adapting up:* "The OSIV default in Spring Boot is the most dangerous
implicit behavior change. In Hibernate-native code, you know exactly
when your session is open. With Spring Boot defaults, OSIV keeps the
session open through the view layer, hiding N+1 problems that only
appear under load. Always disable OSIV (`spring.jpa.open-in-view=false`)
and handle lazy loading explicitly."

*Adapting down:* "Spring Data JPA gives you free data access methods
without writing SQL. Hibernate still runs underneath - you are just
using a nicer API on top."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about migrating from Hibernate's native
API to Spring Data JPA - replacing SessionFactory/Session with Spring
repositories and JPA annotations."

**(2) First principles:** "From first principles, Spring Data JPA reduces
boilerplate by providing standard CRUD implementations and query derivation.
The underlying engine (Hibernate) does not change. What changes is the
API layer the developer interacts with."

**(3) Bridge:** "Think of Hibernate as a car engine and Spring Data JPA
as switching from a manual gearbox to an automatic transmission. The
engine is the same. The driving experience is different. You can still
switch to manual mode (access the EntityManager directly) when needed."

---

### 📘 Concept Explanation

**What it is:**
Migrating from native Hibernate to Spring Data JPA means replacing the
Hibernate-proprietary data access layer (`SessionFactory`, `Session`,
`Transaction`) with the JPA-standard layer (`EntityManagerFactory`,
`EntityManager`) exposed through Spring Data's `JpaRepository` abstraction.
The JPA provider (Hibernate) continues to run underneath unchanged.

**The problem it solves:**
Native Hibernate code has significant boilerplate: session management,
transaction begin/commit/rollback, query construction, and entity lifecycle
management. Spring Data JPA eliminates this boilerplate with generated
repository implementations and declarative transaction management.

**How it works:**

```
BEFORE (Native Hibernate):
  SessionFactory (wired manually)
    |
    Session (open/close manually)
      |
      Transaction (begin/commit/rollback manually)
        |
        Query (HQL strings, manual parameter binding)

AFTER (Spring Data JPA):
  EntityManagerFactory (Spring manages via LocalContainerEMF)
    |
    @Transactional (Spring manages tx lifecycle via AOP proxy)
      |
      JpaRepository (generated implementation via Spring Data)
        |
        EntityManager (injected, managed by Spring)
          |
          JPQL / derived query methods
```

**Entity annotations: unchanged.**
`@Entity`, `@Table`, `@Column`, `@OneToMany`, `@ManyToOne`, `@Version`,
`@Cache` - all these annotations are identical. The entity model does
not change during the migration. Only the data access layer changes.

**When to migrate:**
- Greenfield services: always use Spring Data JPA (less boilerplate)
- Existing services: migrate gradually when adding new features
- When standardization across teams is a goal
- When Hibernate's API version is blocking a Spring version upgrade

**When NOT to migrate (keep native Hibernate):**
- Heavy use of `StatelessSession` for batch processing (no Spring Data equivalent)
- Multi-tenancy patterns using Hibernate's proprietary API
- Stored procedures with `@NamedNativeQuery` and complex result transformers
- When the team is highly proficient in native Hibernate and migration risk is high

**Alternatives:**
- JOOQ: type-safe SQL DSL; not JPA-based but coexists with Spring Data
- MyBatis: SQL-centric ORM; explicit SQL mapping, no JPA
- Spring JDBC Template: raw JDBC with minimal abstraction

---

### 💻 Code Example

```java
// BEFORE: Native Hibernate DAO pattern
@Repository
public class ProductDaoHibernate {
    @Autowired
    SessionFactory sessionFactory;

    public Optional<Product> findById(Long id) {
        Session session = sessionFactory.getCurrentSession();
        return Optional.ofNullable(
            session.get(Product.class, id));
    }

    public List<Product> findByCategory(String category) {
        Session session = sessionFactory.getCurrentSession();
        return session.createQuery(
            "FROM Product p WHERE p.category = :cat",
            Product.class)
            .setParameter("cat", category)
            .list();
    }

    public void save(Product product) {
        Session session = sessionFactory.getCurrentSession();
        session.saveOrUpdate(product);
    }
}
// Manual session management
// Manual transaction boundary in @Service layer
```

> **Code walkthrough:** Native Hibernate DAO: every method explicitly
> accesses the Session. The caller must ensure a transaction is active.
> Query construction uses HQL strings. Entity lifecycle (`saveOrUpdate`)
> is managed explicitly. This is 3-5x more code than the Spring Data JPA
> equivalent for the same operations.

```java
// AFTER: Spring Data JPA Repository pattern
public interface ProductRepository
    extends JpaRepository<Product, Long> {

    // Derived query method - no implementation needed:
    List<Product> findByCategory(String category);

    // Custom JPQL for complex queries:
    @Query("SELECT p FROM Product p " +
        "JOIN FETCH p.attributes " +
        "WHERE p.category = :cat AND p.active = true")
    List<Product> findActiveByCategoryWithAttrs(
        @Param("cat") String category);

    // Projection - load only needed fields:
    @Query("SELECT p.id as id, p.name as name, " +
        "p.price as price FROM Product p " +
        "WHERE p.category = :cat")
    List<ProductSummary> findSummariesByCategory(
        @Param("cat") String cat);
}
// No implementation class needed
// Spring Data generates the implementation at startup
// findById(), save(), delete(), findAll() - all inherited from JpaRepository
```

> **Code walkthrough:** `JpaRepository<Product, Long>` provides
> `findById()`, `save()`, `delete()`, `findAll()`, `existsById()`,
> `count()` for free. `findByCategory()` is a derived query - Spring
> Data parses the method name and generates `WHERE category = ?`. The
> `@Query` annotation provides JPQL for complex queries. Projection
> interfaces (`ProductSummary`) load only the specified fields, avoiding
> the overhead of loading unused entity data.

```java
// MIGRATION: Running Hibernate-native and Spring Data JPA side by side
// This is the safe migration pattern - gradual, not flag-day

@Repository
public class ProductRepositoryHybrid {

    // Spring Data JPA for standard operations:
    @Autowired
    ProductRepository jpaRepository;

    // Direct EntityManager for Hibernate-specific features:
    @PersistenceContext
    EntityManager em;

    // Hibernate-specific: StatelessSession for batch
    @Autowired
    EntityManagerFactory emf;

    public void batchUpdatePrices(List<PriceUpdate> updates) {
        // No equivalent in Spring Data JPA:
        Session session = emf.unwrap(SessionFactory.class)
            .openStatelessSession();
        Transaction tx = session.beginTransaction();
        try {
            for (PriceUpdate u : updates) {
                session.createQuery(
                    "UPDATE Product p SET p.price = :price " +
                    "WHERE p.id = :id")
                    .setParameter("price", u.getNewPrice())
                    .setParameter("id", u.getProductId())
                    .executeUpdate();
            }
            tx.commit();
        } catch (Exception e) {
            tx.rollback();
            throw e;
        } finally {
            session.close();
        }
    }

    // Standard operations: use Spring Data JPA
    public Optional<Product> findById(Long id) {
        return jpaRepository.findById(id);
    }
}
```

> **Code walkthrough:** The hybrid pattern allows incremental migration.
> New code uses `ProductRepository` (Spring Data JPA). Existing batch
> processing code uses the `StatelessSession` directly via `emf.unwrap(SessionFactory.class)`.
> `@PersistenceContext` provides `EntityManager` for operations that
> require JPA but not the full Spring Data abstraction. This pattern is
> safe to deploy: both approaches use the same EntityManagerFactory and
> are within the same transactional context.

```java
// MIGRATION PITFALL: OSIV default behavior change
// application.yml - ALWAYS set this when migrating:
spring:
  jpa:
    open-in-view: false  # CRITICAL: disable Open Session In View

// Without this: Spring Boot keeps the session open through the
// web/controller layer. Lazy loading "works" in controllers.
// This hides N+1 problems during development - only visible at load.

// With open-in-view: false (correct):
// LazyInitializationException in controllers = tells you immediately
// where to add @EntityGraph or JOIN FETCH in the service layer.
```

> **Code walkthrough:** `open-in-view: false` is the most important
> migration configuration. The Spring Boot default (`open-in-view: true`)
> extends the JPA session through the entire HTTP request including the
> view/controller layer. This allows lazy loading in controllers -
> convenient but dangerous at scale. Setting it to `false` makes lazy
> loading boundary violations immediately visible as exceptions, forcing
> the developer to handle them explicitly in the service layer with JOIN
> FETCH or EntityGraph.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Spring Data JPA builds on top of JPA, which Hibernate implements.
> The migration replaces the native Hibernate API (SessionFactory, Session)
> with Spring Data's `JpaRepository` interface. Your entity classes do not
> change - all the annotations (`@Entity`, `@OneToMany`, etc.) stay the
> same. What changes is how you access data: instead of writing HQL queries
> manually with Session, you define a `JpaRepository` interface and Spring
> Data generates the implementation. You also get derived query methods like
> `findByNameAndStatus()` without writing any SQL or HQL.

*Push deeper:* "The biggest implicit change is OSIV (Open Session In View).
By default, Spring Boot keeps the Hibernate session open through the controller
layer. Always set `spring.jpa.open-in-view=false` to get the correct production
behavior - lazy loading must be handled explicitly in the service layer."

---

**Senior / Staff (5+ years):**
> I approach this migration as a two-phase process: API migration first,
> then behavior alignment.
>
> Phase 1 (API migration): Replace `SessionFactory` with `JpaRepository`
> interfaces incrementally - one DAO at a time. Use feature flags to route
> traffic through the new implementation and fall back if issues arise.
> Run both implementations in parallel for one sprint for critical paths.
>
> Phase 2 (behavior alignment): Spring Data JPA changes several implicit
> behaviors that must be explicitly addressed:
> - OSIV: disable it immediately (`open-in-view=false`)
> - `@Transactional` scope: Spring Data's repository methods are
>   `@Transactional` by default. Verify that your service-layer transaction
>   propagation is still correct (REQUIRED vs SUPPORTS vs REQUIRES_NEW)
> - Equality behavior: `CrudRepository.save()` vs `Session.saveOrUpdate()`
>   have different merge semantics for detached entities
>
> What I keep Hibernate-native for: `StatelessSession` batch processing,
> Hibernate-specific query hints, and multi-tenant configurations. Use
> `entityManager.unwrap(Session.class)` to access these features without
> abandoning Spring Data for the standard CRUD path.

*Push deeper:* "The `save()` method in Spring Data JPA: it calls
`persist()` for new entities (no ID or version=0) and `merge()` for
detached entities (has ID). `merge()` copies the detached entity's
state into a managed entity. This is different from `Session.update()`
which re-attaches the existing entity object. If your code passes detached
entities to `save()` and then modifies them after the call, the modifications
are lost - `save()` returned a different (managed) object."

---

### ⚠️ Common Misconceptions

| Misconception | Reality | Danger Level |
|---|---|---|
| "Spring Data JPA replaces Hibernate" | Spring Data JPA is an abstraction LAYER - Hibernate is still the provider, all Hibernate behaviors apply | High |
| "All entity annotations change during migration" | Entity annotations (@Entity, @OneToMany, etc.) are JPA standard - they do not change at all | Medium |
| "Spring Data JPA's save() works like Session.update()" | save() calls merge() for existing entities, returning a NEW managed object. Modifying the passed object after save() has no effect | Critical |
| "Derived query methods are always efficient" | findByStatusAndCreatedAtAfterOrderByCreatedAtDesc may generate a suboptimal query - always verify with EXPLAIN | Medium |
| "OSIV is a safe Spring Boot default for development" | OSIV hides N+1 problems that appear at production load. Always disable it and handle lazy loading explicitly | High |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Detached Entity save() Trap (Lost Update)**

*Symptom:* Modifications made to an entity after `save()` are silently
lost. Entity in database has the pre-save state.

*Root cause:* `JpaRepository.save()` calls `merge()` for existing entities.
`merge()` returns a NEW managed entity (copy). The passed entity remains
detached. Modifications to the passed entity after `merge()` are not tracked.

*Fix:*
```java
// BAD:
Product product = new Product(id, name);
productRepo.save(product); // merge() - product stays DETACHED
product.setDiscount(10);   // modifying DETACHED entity - lost!

// GOOD:
Product managed = productRepo.save(product);
// managed is the NEW managed entity returned by merge()
managed.setDiscount(10); // modifying MANAGED entity - tracked
// OR: load then modify within transaction:
@Transactional
public void addDiscount(Long id, int discount) {
    Product p = productRepo.findById(id).orElseThrow();
    p.setDiscount(discount); // dirty checking commits at flush
}
```

---

**Failure 2: OSIV Masking N+1 in Development**

*Symptom:* Application works fine in development. In production under
load, p99 latency spikes to 5+ seconds. Logs show hundreds of SQL
statements per request.

*Root cause:* `spring.jpa.open-in-view=true` (default). During development,
lazy loading "just works" in the controller layer. N+1 queries execute
but complete quickly due to low data volume. In production with millions
of records and concurrent load, N+1 queries become a throughput bottleneck.

*Fix:*
```yaml
spring:
  jpa:
    open-in-view: false  # expose LazyInitializationException immediately
```
Then fix each `LazyInitializationException` in the service layer with
JOIN FETCH or `@EntityGraph`.

---

**Failure 3: Transaction Propagation Change**

*Symptom:* After migrating from native Hibernate to Spring Data JPA,
operations that were atomic now partially commit. Some updates succeed
while related updates fail without rolling back the others.

*Root cause:* Native Hibernate: explicit `session.beginTransaction()` /
`tx.commit()` gives precise control over transaction boundaries.
Spring Data JPA repositories are `@Transactional` by default with
`REQUIRED` propagation. If the outer service method is NOT `@Transactional`,
each repository call runs in its own transaction, breaking atomicity.

*Fix:*
```java
// Ensure service-layer method is @Transactional when calling
// multiple repository methods atomically:
@Transactional // REQUIRED - all repo calls join this transaction
public void transferStock(Long fromId, Long toId, int qty) {
    Product from = productRepo.findById(fromId).orElseThrow();
    Product to = productRepo.findById(toId).orElseThrow();
    from.decrementStock(qty);
    to.incrementStock(qty);
    // Both saved in ONE transaction
}
// Without @Transactional: each findById and save runs in its own TX
```

---

### 🏛️ System Design

> *(Conditional: included because ★★★ keyword. Migration strategy is
> an architectural decision with organization-wide impact.)*

**Where Hibernate-to-Spring Data JPA migration appears in system design:**
- Technology standardization across microservices teams
- Reducing technical debt in services using legacy Hibernate XML config
- Enabling Spring Boot version upgrades blocked by old Hibernate dependencies
- Onboarding new engineers: Spring Data JPA has a shallower learning curve

**Example question:** "Your organization has 30 Spring-based microservices
using native Hibernate with various versions. Management wants to standardize
on Spring Data JPA. How do you approach this migration without disrupting
production?"

**6-step framework answer:**

Step 1 CLARIFY (~5 min):
- "What is the current Hibernate version per service?"
- "Are there services using Hibernate-specific features (StatelessSession, multi-tenancy)?"
- "Is this a deadline-driven migration or continuous improvement?"

Step 2 ESTIMATE (~5 min):
- 30 services * avg 5 DAO classes per service = 150 DAO classes to migrate
- Per service: 2-5 days for migration + 2-3 days for testing
- Total: 30 * 5 = 150 person-days
- Recommended: 6-month rolling migration (5 services/month per team)

Step 3 DESIGN (~10 min):
```
Migration Strategy: Strangler Fig Pattern

Phase 1: Standardize Hibernate/JPA version (no API change)
  |
  +-> Identify and document all Hibernate-specific features per service
  |
  +-> Fix: update entity annotations to JPA standard where possible

Phase 2: Migrate per service (one at a time, isolated)
  |
  +-> Add Spring Data JPA dependencies alongside existing
  |
  +-> Create JpaRepository interfaces for each entity (new file, no deletions yet)
  |
  +-> Route new code to JpaRepository, old code to existing DAOs
  |
  +-> Run both in parallel with integration tests comparing output
  |
  +-> Remove old DAOs when parallel tests pass for 2 weeks

Phase 3: Behavior alignment (post-migration)
  |
  +-> Disable OSIV in all services
  +-> Fix all LazyInitializationExceptions
  +-> Add query count assertions to CI for N+1 prevention
```

Step 4 DEEP DIVE (~10 min):
The highest-risk change is `save()` vs `saveOrUpdate()` semantics.
Add a migration lint rule: any `repo.save(entity); entity.modify();`
pattern is a bug. Add a custom ArchUnit test:
```java
// ArchUnit rule: detects save() followed by field modification
// (pattern-based static analysis)
```
Second highest risk: OSIV behavior. Disabling OSIV reveals all lazy
loading boundary violations at once. Plan a sprint to fix these before
the OSIV configuration change goes to production.

Step 5 ALTS (~5 min):
- Keep native Hibernate for services with heavy batch processing. These
  services benefit from `StatelessSession` which has no Spring Data equivalent.
- Use Spring Data JDBC instead of JPA for new services: simpler model,
  no lazy loading, no proxy issues.

Step 6 EVOLVE (~5 min):
At 10x service count (300 services): automated migration tooling becomes
necessary. OpenRewrite recipes can automate Hibernate-to-JPA API
replacements. The manual migration pattern does not scale beyond ~30 services.

**Scale inflection point:**
At ~10 services needing migration simultaneously, coordinating the
migration manually becomes a project management problem. At ~30+ services,
automated tooling (OpenRewrite, CodeShift) is necessary to maintain
velocity. The Strangler Fig pattern scales to any number of services but
requires explicit tooling at 30+.

**Common system design traps:**
- Flag-day migration: attempting to migrate all 30 services simultaneously.
  One critical service failure delays the entire program.
- Ignoring Hibernate-specific feature inventory: discovering StatelessSession
  usage mid-migration requires a detour that blocks the timeline.
- Not disabling OSIV before go-live: OSIV masks N+1 problems that only
  appear under production load, creating a time-bomb.

**Staff angle:** The cost of migration is not just development time.
It is cognitive load on teams, regression risk in production, and the
opportunity cost of features not built during the migration period.
I would challenge the "standardize on Spring Data JPA" mandate with:
what is the actual problem? If the problem is consistency of patterns
across teams: a coding guideline and training may be cheaper than migration.
If the problem is Spring Boot version lock: migrating only the blocking
dependency (Hibernate version, not the DAO pattern) may be sufficient.
Always scope the minimum change that solves the actual problem.

---

### 📊 Diagram

> *(Conditional: included because ★★★ keyword and the migration
> architecture is best understood by comparing the before and after
> layering.)*

```
BEFORE (Native Hibernate):                AFTER (Spring Data JPA):

  Service Layer                             Service Layer
    |                                         |
    @Autowired SessionFactory                 @Autowired ProductRepository
    Session s = sf.getCurrentSession()        (JpaRepository interface)
    |                                         |
    HQL: "FROM Product WHERE..."             Spring Data Generated Impl
    |                                         @Transactional methods
    Transaction.begin()                       |
    / commit() / rollback()                  EntityManager (managed by Spring)
    |                                         |
  SessionFactory                           EntityManagerFactory
  (Hibernate)                              (Spring LocalContainerEMF)
    |                                         |
  Hibernate Core (SAME)                    Hibernate Core (SAME)
    |                                         |
  JDBC (SAME)                              JDBC (SAME)
    |                                         |
  Database (SAME)                          Database (SAME)
```

```mermaid
flowchart TD
    subgraph before["BEFORE: Native Hibernate"]
        S1[Service] -->|Session API| SF[SessionFactory]
        SF -->|HQL| HQ[Query]
        HQ -->|TX manual| DB1[(Database)]
    end

    subgraph after["AFTER: Spring Data JPA"]
        S2[Service] -->|JpaRepository| REPO[Spring Data Impl]
        REPO -->|JPQL / derived| EM[EntityManager]
        EM -->|@Transactional AOP| DB2[(Database)]
    end

    subgraph shared["Unchanged"]
        HC[Hibernate Core]
        JDBC[JDBC Driver]
    end

    DB1 --- HC
    DB2 --- HC
    HC --- JDBC
```

> **Diagram walkthrough:** The database, JDBC layer, and Hibernate Core
> remain completely unchanged during migration. Only the application-level
> API changes: from `SessionFactory`/`Session` (Hibernate-native) to
> `EntityManager`/`JpaRepository` (JPA-standard via Spring Data). The
> entity model (annotations, mappings) is also unchanged. Migration effort
> is confined to the data access layer (DAOs / repositories) and transaction
> management configuration. This is why migration is incremental and
> low-risk: each DAO can be migrated independently.

---

### 🎯 Interview Deep-Dive

| Timing | Seniority | Focus |
|--------|-----------|-------|
| 3 min | Junior | What is Spring Data JPA, how does it relate to Hibernate |
| 5 min | Mid | Migration steps, what changes and what stays the same |
| 7 min | Senior | OSIV pitfall, save() semantics, transaction propagation |
| 10 min | Staff | Migration strategy for 30 services, risk management |
| 15 min | FAANG | Full migration roadmap, tooling, tradeoff analysis |

---

**Q1 [JUNIOR] - DEFINITION**
What is the relationship between Hibernate and Spring Data JPA?

*Why they ask:* Fundamental architecture question often misunderstood.

*Likely follow-up:* "Which one do you configure in Spring Boot?"

**Answer:**
JPA is a specification (Java Persistence API), not an implementation.
Hibernate is the most popular implementation of the JPA specification.
Spring Data JPA is a repository abstraction layer that sits on top of JPA.

The layering:
```
Your Code
    |
Spring Data JPA (JpaRepository abstraction)
    |
JPA API (EntityManager, EntityManagerFactory)
    |
Hibernate (JPA implementation)
    |
JDBC
    |
Database
```

Spring Data JPA depends on JPA, which Hibernate implements. When you use
Spring Data JPA, you are still using Hibernate underneath - Hibernate is
still the engine that generates SQL, manages sessions, and handles
transactions.

What Spring Data JPA adds:
- `JpaRepository` interface with free CRUD implementations
- Derived query methods from method names
- Pagination and sorting support
- `@Query` annotation for custom JPQL/native queries

In Spring Boot, you configure Hibernate via `spring.jpa.*` properties
(these configure the Hibernate provider through the JPA standard).
Spring Boot auto-configures both the `EntityManagerFactory` (Hibernate)
and the Spring Data JPA repository layer.

*What separates good from great:* Drawing the three-layer stack explicitly
(Spring Data JPA -> JPA -> Hibernate) and confirming that Hibernate is still
present and configurable even when using Spring Data JPA.

---

**Q2 [MID] - MECHANISM**
What changes and what stays the same when migrating from native
Hibernate to Spring Data JPA?

*Why they ask:* Tests understanding of migration scope.

*Likely follow-up:* "Can you use Hibernate-specific annotations after migrating?"

**Answer:**
What STAYS THE SAME:
- All entity annotations: `@Entity`, `@Table`, `@Column`, `@OneToMany`,
  `@ManyToOne`, `@Version`, `@Cache`, `@Filter` - unchanged
- Hibernate configuration: `spring.jpa.properties.hibernate.*` still works
- All Hibernate behavior: dirty checking, L1C, L2C, proxies - unchanged
- Database schema: no changes needed

What CHANGES:
- Data access layer: `SessionFactory.getCurrentSession()` → `JpaRepository`
- Transaction management: manual `tx.begin()/commit()` → `@Transactional`
- Query language: HQL remains valid as JPQL (very similar syntax) OR
  replace with derived methods for simple queries
- Entity lifecycle: `session.saveOrUpdate(entity)` → `repository.save(entity)`
  (important semantic difference: `save()` calls `merge()` for existing entities)

Hibernate-specific annotations still work after migration because Spring
Data JPA does not prohibit Hibernate annotations - Hibernate is still
the provider. You can keep `@NaturalId`, `@Cache`, `@BatchSize` etc.

You can also access the Hibernate session directly from within Spring Data JPA:
```java
@PersistenceContext
EntityManager em;

// Get Hibernate session from EntityManager:
Session session = em.unwrap(Session.class);
// Use Hibernate-specific features when needed
```

*What separates good from great:* Confirming that Hibernate-specific
annotations remain valid and showing how to access the underlying Hibernate
session when needed.

---

**Q3 [SENIOR] - TRADE-OFF**
What is the `save()` vs `saveOrUpdate()` semantic difference and
how does it affect migration?

*Why they ask:* This is the most common subtle bug introduced during migration.

*Likely follow-up:* "When would you use merge() directly instead of save()?"

**Answer:**
`Session.saveOrUpdate(entity)`: re-attaches the passed entity to the
session. If new, inserts. If detached (has ID), re-attaches and marks
dirty. The SAME object is now managed.

`JpaRepository.save(entity)`: calls `EntityManager.persist()` for new
entities (no ID) and `EntityManager.merge()` for existing entities (has ID).
`merge()` copies the state of the passed entity into a MANAGED ENTITY
and returns the managed entity. The ORIGINAL passed entity remains detached.

The critical difference:
```java
// Native Hibernate - safe:
Product p = new Product(existingId, newName);
session.saveOrUpdate(p); // p is NOW managed
p.setDescription("updated"); // tracked by dirty checking
// Commit: UPDATE includes name AND description

// Spring Data JPA - common bug:
Product p = new Product(existingId, newName);
Product managed = productRepo.save(p); // merge() - p stays DETACHED
p.setDescription("updated"); // p is DETACHED - NOT tracked
// Commit: UPDATE includes only name (from the merge)
// description change is LOST

// Correct:
managed.setDescription("updated"); // managed IS tracked
```

This bug is silent - no exception, just missing data in the database.

When to use `merge()` directly:
- When you need to control the merge cycle explicitly
- When working with DTOs: load entity, apply DTO fields, merge
- When you have an entity from a different context (cross-service, cache)

Rule: after calling `save()` on a Spring Data JPA repository, use the
RETURNED object for subsequent modifications, not the original.

*What separates good from great:* The concrete code showing that the
original entity is silently ignored after `save()` and the modification
is lost.

---

**Q4 [SENIOR] - DEBUGGING**
After migrating to Spring Data JPA, some complex queries that
worked as HQL now generate different (suboptimal) SQL or fail.
How do you diagnose and fix?

*Why they ask:* Tests ability to debug query translation issues.

*Likely follow-up:* "When should you fall back to native SQL?"

**Answer:**
HQL and JPQL are almost identical but have some differences that can
cause issues during migration:

Issue 1: HQL-specific features not in JPQL.
Hibernate HQL supports `str()`, `locate()`, `bit_length()`, and some
DB-specific functions. JPQL may not support all of these.
Fix: use `@Query(nativeQuery=true)` for queries that use DB-specific
functions.

Issue 2: Different JOIN generation.
HQL `FROM Order o JOIN o.items i` generates an INNER JOIN.
Spring Data JPA + JPQL may generate a different join plan for
complex queries with `@EntityGraph`.
Fix: compare EXPLAIN output for HQL and JPQL versions. Rewrite with
explicit JOIN FETCH or native SQL if needed.

Diagnosis approach:
```yaml
# Enable SQL logging:
logging.level.org.hibernate.SQL: DEBUG
logging.level.org.hibernate.type: TRACE
```
Then compare:
1. The HQL query in the legacy code
2. The JPQL or derived method in the migrated code
3. The generated SQL for both

If the generated SQL differs:
- Check EXPLAIN ANALYZE for both
- If JPQL generates a suboptimal plan: rewrite as `@Query` with explicit JOIN
- If no JPQL equivalent: use `@Query(nativeQuery=true)`:
```java
@Query(value = "SELECT * FROM orders o " +
    "WHERE o.metadata @> :filter::jsonb", // PostgreSQL JSONB
    nativeQuery = true)
List<Order> findByJsonbFilter(@Param("filter") String filter);
```

*What separates good from great:* The nativeQuery fallback and the
EXPLAIN ANALYZE comparison methodology.

---

**Q5 [SENIOR] - DEBUGGING**
After migrating and disabling OSIV, the application throws
`LazyInitializationException` in multiple controller methods.
How do you fix this systematically?

*Why they ask:* OSIV-related LIE is the most common post-migration issue.

*Likely follow-up:* "What is the difference between @EntityGraph and JOIN FETCH?"

**Answer:**
After disabling OSIV, every lazy association access outside a transaction
throws `LazyInitializationException`. This is correct behavior that was
previously hidden by OSIV.

Systematic fix approach:

Step 1: Catalog all `LazyInitializationException` stack traces.
Group by entity and association. This gives the list of N associations
that need eager loading in specific query paths.

Step 2: Fix each using the appropriate strategy:

For simple associations needed by one query:
```java
// @EntityGraph: declarative, no JPQL rewrite
@EntityGraph(attributePaths = {"customer", "items"})
Optional<Order> findById(Long id);
// Hibernate generates LEFT JOIN FETCH for each path
```

For associations needed by multiple queries:
```java
// Named EntityGraph on the entity:
@Entity
@NamedEntityGraph(name = "Order.withCustomer",
    attributeNodes = @NamedAttributeNode("customer"))
public class Order { ... }

// Repository:
@EntityGraph("Order.withCustomer")
List<Order> findByStatus(String status);
```

For complex join paths:
```java
// Explicit JOIN FETCH in @Query:
@Query("SELECT o FROM Order o " +
    "JOIN FETCH o.customer c " +
    "JOIN FETCH o.items i " +
    "JOIN FETCH i.product " +
    "WHERE o.id = :id")
Optional<Order> findDetailById(@Param("id") Long id);
```

Step 3: For associations needed in the service layer (not just queries):
```java
@Transactional
public OrderDTO getOrderDetails(Long id) {
    Order order = repo.findById(id).orElseThrow();
    // All association access here is within the transaction
    return OrderDTO.from(order, order.getCustomer(),
        order.getItems());
}
```

*What separates good from great:* The three-tier approach: EntityGraph
for simple cases, NamedEntityGraph for reusable graphs, explicit JPQL
JOIN FETCH for complex paths.

---

**Q6 [MID] - COMPARISON**
What is the difference between `JpaRepository.findById()` and
the native Hibernate `session.get()` vs `session.load()`?

*Why they ask:* Tests understanding of how Spring Data JPA maps to Hibernate primitives.

*Likely follow-up:* "Is there a Spring Data equivalent of session.load()?"

**Answer:**
`JpaRepository.findById(id)`:
- Calls `EntityManager.find(EntityClass, id)`
- Equivalent to `Session.get()` in native Hibernate
- Always hits the database (unless in L1C)
- Returns `Optional<Entity>` - empty if not found (no exception)

`Session.get()`:
- Always hits the database (unless in L1C)
- Returns `null` if not found
- Equivalent to `findById().orElse(null)`

`Session.load()` (native) / `EntityManager.getReference()` (JPA):
- Returns a proxy immediately without hitting the database
- Throws exception on access if entity does not exist
- Spring Data equivalent: `JpaRepository.getReferenceById(id)` (Spring Data 2.7+)

```java
// Spring Data JPA equivalents:
// session.get() equivalent:
Optional<Order> order = orderRepo.findById(42L);
// Returns Optional.empty() if not found (clean)

// session.load() equivalent (Spring Data 2.7+):
Order proxy = orderRepo.getReferenceById(42L);
// Returns proxy immediately, no SQL
// Use for FK reference setting (avoids unnecessary SELECT)

// Set FK reference without loading the entity:
Order order = new Order();
Customer proxy = customerRepo.getReferenceById(customerId);
order.setCustomer(proxy); // no SELECT, just sets FK
orderRepo.save(order);
```

The `getReferenceById()` use case: when you need to set a foreign key
on a new entity and have the ID but do not need the referenced entity's
data. Without it, `findById()` fires a SELECT just to get an object
reference for setting the FK.

*What separates good from great:* The `getReferenceById()` use case
for FK reference setting - the direct equivalent of `session.load()`.

---

**Q7 [STAFF] - ARCHITECTURE**
How do you handle Spring Data JPA migration for a service that
uses Hibernate multi-tenancy with a schema-per-tenant approach?

*Why they ask:* Multi-tenancy is a Hibernate-specific feature with no
direct Spring Data JPA equivalent.

*Likely follow-up:* "What is the difference between database, schema, and discriminator multi-tenancy in Hibernate?"

**Answer:**
Hibernate's multi-tenancy API (schema-per-tenant, database-per-tenant,
row-level discriminator) is Hibernate-proprietary - there is no JPA
standard equivalent. Spring Data JPA exposes the JPA API, not Hibernate's
multi-tenancy API. This means multi-tenant services cannot be migrated
to "pure" Spring Data JPA without custom integration.

Options:

Option 1: Keep the Hibernate multi-tenancy configuration, use Spring Data
JPA for query methods, access Hibernate API for tenant context:
```java
// Spring Data repository still works:
public interface OrderRepository
    extends JpaRepository<Order, Long> {
    List<Order> findByStatus(String status);
    // Works with current tenant schema
}

// Hibernate multi-tenancy context set manually before each request:
@Component
public class TenantFilter implements WebMvcConfigurer {
    @Autowired
    CurrentTenantIdentifierResolver resolver;
    // (Hibernate interface - still configured even with Spring Data JPA)
}
```
The `CurrentTenantIdentifierResolver` and `MultiTenantConnectionProvider`
are Hibernate interfaces that Spring Boot supports via
`spring.jpa.properties.hibernate.multiTenancy` and
`spring.jpa.properties.hibernate.tenant_identifier_resolver`.

Option 2: Replace Hibernate multi-tenancy with Row-Level Security (RLS)
in the database. RLS enforces tenant isolation at the database level,
making Hibernate/JPA unaware of multi-tenancy:
```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON orders
    USING (tenant_id = current_setting('app.tenant_id')::int);
```
Set the RLS parameter per request in the DataSource connection.
This approach works cleanly with Spring Data JPA and removes the
Hibernate-specific multi-tenancy code.

Recommendation: if the service is migrating to Spring Data JPA AND
the multi-tenancy approach is schema-per-tenant: consider migrating
to RLS simultaneously. The two migrations align well and RLS is more
database-portable.

*What separates good from great:* The RLS alternative as a way to
remove Hibernate-specific multi-tenancy code while migrating - a concrete
architectural path rather than just explaining the limitation.

---

**Q8 [MID] - MECHANISM**
What is Open Session In View (OSIV) and why should you disable it
when using Spring Data JPA?

*Why they ask:* OSIV is enabled by default and is a significant production risk.

*Likely follow-up:* "What is the correct way to handle lazy loading without OSIV?"

**Answer:**
Open Session In View (OSIV) is a Spring pattern where the JPA session
(Hibernate session) is opened at the beginning of the HTTP request and
kept open through the entire request lifecycle - including the controller
layer, view rendering, and response serialization. It is enabled by default
in Spring Boot (`spring.jpa.open-in-view=true`).

Why OSIV exists: to allow lazy loading in the view/controller layer without
`LazyInitializationException`. Before OSIV, accessing a lazy association
in a Thymeleaf template or a Jackson serializer would fail because the
service-layer transaction had already closed the session.

Why you should disable it in production:

1. Hidden N+1 queries: with OSIV, lazy loading "works" everywhere. Each
   template access `order.getCustomer().getName()` fires a SQL query.
   In a list of 100 orders: 100 extra queries, each invisible until load testing.

2. Long-lived session: the session holds all loaded entities in the L1C
   for the entire request lifecycle. For requests that load many entities,
   this increases memory usage.

3. Implicit database connection hold: the session holds a database connection
   through the view layer. This reduces connection availability during
   template rendering/response serialization.

Correct approach without OSIV:
```java
// Service: explicitly load what the controller needs
@Transactional(readOnly = true)
public OrderDetailDTO getOrderDetail(Long id) {
    Order order = repo.findById(id).orElseThrow();
    // Access ALL needed associations within the transaction:
    return OrderDetailDTO.builder()
        .orderId(order.getId())
        .customerName(order.getCustomer().getName())
        .items(order.getItems().stream()
            .map(ItemDTO::from)
            .collect(toList()))
        .build();
}
// Controller receives a DTO: no session needed, no lazy loading
```

Configuration: `spring.jpa.open-in-view=false`

*What separates good from great:* Quantifying the N+1 risk (100 orders
= 100 extra queries) and the DTO pattern as the correct solution.

---

**Q9 [SENIOR] - DEBUGGING**
After migrating to Spring Data JPA, `@Modifying @Transactional`
queries are not reflecting updated data when the same entity is
loaded again in the same transaction. Why?

*Why they ask:* Tests knowledge of L1C invalidation with @Modifying queries.

*Likely follow-up:* "What does clearAutomatically=true do?"

**Answer:**
`@Modifying @Query("UPDATE Product p SET p.price = :price WHERE p.id = :id")`
executes a bulk UPDATE directly on the database, bypassing Hibernate's
L1C (first-level cache). After this update:

1. The database row has the new price.
2. Hibernate's L1C (within the same session/transaction) still holds
   the old `Product` entity snapshot.
3. `productRepo.findById(id)` returns the L1C entity (old price).
4. The returned entity appears stale: the price has not updated.

Fix 1 (preferred): add `clearAutomatically = true` to evict the
entity from L1C after the update:
```java
@Modifying(clearAutomatically = true)
@Query("UPDATE Product p SET p.price = :price WHERE p.id = :id")
int updatePrice(@Param("price") BigDecimal price, @Param("id") Long id);
// L1C cleared after UPDATE - next findById fires fresh SELECT
```

Fix 2: add `flushAutomatically = true` to flush pending changes before
the bulk update (ensures pending dirty writes are committed before the bulk):
```java
@Modifying(clearAutomatically = true, flushAutomatically = true)
@Query("UPDATE Product p SET p.price = :price WHERE p.id = :id")
int updatePrice(BigDecimal price, Long id);
```

Fix 3: evict the entity manually:
```java
productRepo.updatePrice(newPrice, id);
em.evict(productRef); // or: em.clear() for all entities
Product updated = productRepo.findById(id).orElseThrow();
// Now fires fresh SELECT
```

`clearAutomatically=true` is the standard solution for bulk update
methods. Include it as a default practice for all `@Modifying` queries.

*What separates good from great:* `flushAutomatically = true` and its
purpose: ensures dirty checking flushes pending writes before the bulk
update executes, preventing the bulk from operating on stale data.

---

**Q10 [STAFF] - DEBUGGING**
You migrate a service to Spring Data JPA and notice that insert
performance degrades significantly for bulk inserts compared to
the native Hibernate implementation. What are the causes?

*Why they ask:* Tests understanding of bulk insert performance in Spring Data JPA.

*Likely follow-up:* "What is the difference between saveAll() and a native batch insert?"

**Answer:**
`JpaRepository.saveAll(List<Entity>)` calls `save()` for each entity
individually - it is a loop over `save()`, not a true batch insert.
By default, this generates N individual INSERT statements regardless
of list size.

Causes of degraded bulk insert performance:

Cause 1: IDENTITY generation strategy. If entities use
`@GeneratedValue(strategy=IDENTITY)`, Hibernate cannot batch inserts.
IDENTITY requires the database to generate the ID on each INSERT and
return it - this requires a round-trip per row. Batch inserts group
multiple rows in one network packet, but IDENTITY forces one-at-a-time.

Cause 2: JDBC batching not enabled. Hibernate has JDBC batch size
configuration that groups INSERT statements into JDBC batches (one
network packet, many rows). Without this, each INSERT is a separate
network round-trip.

Fix: enable JDBC batch size:
```yaml
spring:
  jpa:
    properties:
      hibernate:
        jdbc.batch_size: 50       # group 50 inserts per batch
        order_inserts: true       # group by entity type
        order_updates: true       # group updates too
```

Fix: switch from IDENTITY to SEQUENCE generator:
```java
@Id
@GeneratedValue(strategy=SEQUENCE, generator="product_seq")
@SequenceGenerator(name="product_seq", allocationSize=50)
// allocationSize=50: pre-allocate 50 IDs per sequence call
// No round-trip per row - Hibernate uses cached IDs
```

For true bulk insert performance (1M+ rows): use `StatelessSession`
or native SQL (`INSERT INTO ... VALUES (...), (...), ...`). Spring Data
JPA is not optimized for bulk import workloads.

*What separates good from great:* The IDENTITY generator as the root
cause of why batch size configuration does not help - switching to
SEQUENCE is required for JDBC batching to take effect.

---

**Q11 [SENIOR] - COMPARISON**
When would you choose Spring Data JDBC over Spring Data JPA for
a new service?

*Why they ask:* Tests ability to evaluate alternatives to JPA.

*Likely follow-up:* "What features does Spring Data JDBC not support?"

**Answer:**
Spring Data JDBC is a simpler, SQL-centric repository abstraction that
does not use JPA at all. It has no proxy generation, no dirty checking,
no lazy loading, and no L1C. Every operation is explicit: you read when
you call `findById()`, you write when you call `save()`.

Choose Spring Data JDBC when:
1. The data model is simple: few associations, no complex hierarchy.
   For CRUD services with flat entities, JPA's complexity adds overhead
   without benefit.

2. Predictable SQL is critical: Spring Data JDBC generates simple,
   predictable SQL. No surprise N+1, no proxy, no dirty checking.
   What you write in the repository is what executes.

3. Team prefers explicit over implicit: JPA has many implicit behaviors
   (dirty checking, proxy initialization, cascade). Spring Data JDBC is
   explicit: load data when you ask, save data when you ask.

4. Immutable entities with value objects: Spring Data JDBC works well
   with immutable `record` types and value objects. JPA requires mutable
   entities (no-args constructor, setter methods).

Features NOT in Spring Data JDBC:
- Lazy loading (no proxies)
- L1C / L2C (every read hits the database)
- Dirty checking (must explicitly call save() after modifications)
- Cascading saves through complex hierarchies
- JPQL (uses SQL or derived methods only)
- @Version optimistic locking (limited support)

Choose JPA when: complex associations, lazy loading needed, existing
Hibernate knowledge on the team, complex query requirements.
Choose Spring Data JDBC when: simple CRUD, explicit behavior preferred,
team new to JPA, performance-sensitive with predictable SQL needs.

*What separates good from great:* The immutable entity use case for
Spring Data JDBC - it works with `record` types natively, while JPA
requires mutable entities with no-args constructors.

---

**Q12 [STAFF] - BEHAVIORAL**
Tell me about a Hibernate-to-Spring Data JPA migration you led
or participated in. What were the biggest challenges?

*Why they ask:* Tests leadership and real-world experience with migrations.

*Likely follow-up:* "What would you do differently next time?"

**Answer:**
**S (Situation):** A fintech backend service had been using native Hibernate
since 2014 with a custom DAO framework (BaseDao generic class, manual
SessionFactory injection). The service was blocking a Spring Boot 3.0
upgrade because the custom DAO framework was incompatible with the new
Spring lifecycle.

**T (Task):** Migrate all 47 DAO classes to Spring Data JPA in 6 weeks
without disrupting a production system processing ~$10M/day in transactions.

**A (Action):**

Week 1-2: Inventory and risk analysis.
Catalogued all 47 DAOs. Identified 4 DAOs using `StatelessSession` for
batch imports (no Spring Data equivalent), 3 using Hibernate multi-tenancy
API, and 12 using HQL features not in JPQL (`str()` function, named
parameters in different syntax).

Risk-tiered the migration:
- Low risk: 28 simple DAOs - replace with `JpaRepository`, no behavior change
- Medium risk: 12 with HQL differences - rewrite queries, test output
- High risk: 4 batch DAOs, 3 multi-tenant DAOs - keep native Hibernate, wrap in adapters

Week 3-4: Migrate low-risk DAOs.
Used expand-contract: created new `JpaRepository` interfaces alongside
existing DAOs. Ran both in parallel with request-level comparison (Assert
both return identical data for the same input). Merged after 48-hour parallel test.

Week 5: Migrate medium-risk DAOs.
Rewrote HQL to JPQL. Used EXPLAIN ANALYZE to verify query plan equivalence.
Found 2 queries with worse plans: rewrote as `@Query(nativeQuery=true)`.

Week 6: Address high-risk DAOs.
Kept `StatelessSession` for batch DAOs - wrapped in a `BatchImportService`
that injects `EntityManagerFactory` directly. Migrated multi-tenant DAOs
to use Spring's AbstractRoutingDataSource instead of Hibernate's multi-tenancy API.

**R (Result):** Migrated 40 of 47 DAOs to Spring Data JPA. 7 kept
Hibernate-native (4 batch + 3 multi-tenant). Spring Boot 3.0 upgrade
succeeded. Zero production incidents during migration.

Biggest challenge: the `save()` vs `saveOrUpdate()` semantic difference.
Found 3 places where code modified entities after calling `save()` and
expected the changes to be tracked. Added an ArchUnit test that fails if
an entity is modified after `save()` in the same method.

What I would do differently: add the query count assertion CI tests BEFORE
starting the migration, not after. Discovered 5 new N+1 issues introduced
during migration that would have been caught earlier.

*What separates good from great:* The hybrid outcome (7 DAOs kept native),
the ArchUnit rule for the save() semantic, and the lesson learned about
query count tests.
