---
layout: default
title: "JPA - L5 Migration"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 14
permalink: /jpa/l5-migration/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [JPA - L5 Migration](#jpa---l5-migration) | medium |

---

# JPA - L5 Migration

## JPA Migration Strategy: EclipseLink to Hibernate, Hibernate 5 to 6

---

### 🎯 Model Answer

**30 seconds:**
> JPA provider migrations (EclipseLink to Hibernate): test query behavior changes (JPQL semantics
> differences, N+1 changes, L2 cache configuration). Hibernate 5 to 6: major breaking changes -
> `javax.*` to `jakarta.*` package rename, JPQL standard changes, collection semantics, deprecated
> APIs removed. Incremental migration: test-first, one module at a time.

**3 minutes (Senior):**
> Migration approaches:
>
> 1. **EclipseLink to Hibernate**:
>    - Entity mappings: mostly compatible (both JPA spec). Differences: `@Cache` (EclipseLink-specific
>      annotation vs Hibernate `@Cache`), `@Index` annotations, `@Multitenant`.
>    - JPQL differences: EclipseLink interprets some expressions differently. Test all named queries.
>    - L2 cache: EclipseLink cache region strategy is different from Hibernate's JCache/EhCache.
>    - Native SQL: platform-specific SQL may differ (different parameter binding syntax).
>
> 2. **Hibernate 5 to 6 (jakarta migration)**:
>    - `javax.persistence.*` -> `jakarta.persistence.*` (package rename). All imports.
>    - `@Type(type = "...")` string-based: replaced by `@Type(value = Class.class)` typed.
>    - Implicit join in HQL: syntax changes. `SELECT o.customer.address` -> must use explicit JOIN.
>    - Collection semantics: `List` (bag semantics) vs ordered. `@OrderColumn` required for List.
>    - `SchemaExport` API changed. Custom `UserType` interface: changed.
>    - Spring Boot 3.x: requires Jakarta EE 9+ (jakarta namespace). Spring Boot 2.x: javax namespace.
>
> 3. **Migration strategy**: (a) Test suite coverage FIRST (before migrating). (b) Upgrade in a
>    separate branch. (c) Run full integration test suite. (d) Fix failures one by one. (e) Test
>    performance: query plans may change between Hibernate versions.

**Blank Mind Recovery:**

**(1) Restate:** "Hibernate 5 to 6: javax -> jakarta, @Type changed, JPQL stricter, Spring Boot 3.x needed. EclipseLink -> Hibernate: @Cache config, JPQL behavior, L2 cache setup different. Strategy: test-first, one module, integration tests."

**(2) First principles:** "JPA spec: portability layer. But implementations diverge. Migration = finding where you depended on implementation-specific behavior. Good test coverage exposes this. Poor test coverage: find it in production."

**(3) Bridge:** "JPA provider migration is like switching from iOS to Android. Core apps work (both run email, phone). But muscle memory (EclipseLink-specific features) and integration points (custom configurations) break. Audit what you used beyond the standard."

---

### 📘 Concept Explanation

**Hibernate 5 to 6 migration guide (jakarta namespace and breaking changes):**
```plaintext
JAKARTA NAMESPACE MIGRATION (Hibernate 5 -> 6 / Spring Boot 2 -> 3):

  // Hibernate 5 / Spring Boot 2:
  import javax.persistence.Entity;
  import javax.persistence.Id;
  import javax.persistence.GeneratedValue;
  import javax.persistence.OneToMany;
  import javax.persistence.CascadeType;
  import javax.transaction.Transactional;
  import javax.persistence.EntityManager;
  import javax.persistence.PersistenceContext;
  
  // Hibernate 6 / Spring Boot 3:
  import jakarta.persistence.Entity;
  import jakarta.persistence.Id;
  import jakarta.persistence.GeneratedValue;
  import jakarta.persistence.OneToMany;
  import jakarta.persistence.CascadeType;
  import jakarta.transaction.Transactional;
  import jakarta.persistence.EntityManager;
  import jakarta.persistence.PersistenceContext;
  
  // Automated migration:
  //   IntelliJ IDEA: Migration tool -> Javax to Jakarta
  //   OpenRewrite recipe: org.openrewrite.java.migrate.Jakarta
  //   sed script: for simple imports (verify regex doesn't touch javax.xml, javax.net, etc.)

HIBERNATE TYPE SYSTEM CHANGES (5 -> 6):

  // Hibernate 5:
  @Column
  @Type(type = "json")
  private Map<String, Object> metadata;
  
  // Hibernate 5 custom type:
  public class JsonType implements UserType {
      // ... returns int sqlTypes(), Class returnedClass(), etc.
  }
  
  // Hibernate 6 (fully typed):
  @Column
  @Type(JsonType.class)  // class reference, not string
  private Map<String, Object> metadata;
  
  // Hibernate 6 UserType interface change:
  public class JsonType implements UserType<Map<String, Object>> {
      @Override
      public int getSqlType() { ... }  // replaces sqlTypes()
      @Override
      public Class<Map<String, Object>> returnedClass() { ... }
      // ... serialize/deserialize methods changed
  }
  
  // Third-party library: hibernate-types (Vlad Mihalcea):
  // Hibernate 5: hibernate-types-55
  // Hibernate 6: hypersistence-utils-hibernate-62
  // Migration: update dependency + check changed class names.

HQL/JPQL STRICTER IN HIBERNATE 6:

  // Hibernate 5: implicit cross join allowed:
  @Query("SELECT o FROM Order o, Customer c WHERE o.customerId = c.id")
  // Works (though inefficient). Generates cross join + WHERE filter.
  
  // Hibernate 6: implicit cross join -> strict check.
  // Some implicit joins that worked in 5 fail in 6.
  // Must use explicit JOIN:
  @Query("SELECT o FROM Order o JOIN Customer c ON o.customerId = c.id")
  // Or: redesign to not JOIN across aggregate boundaries.
  
  // Hibernate 5: "SELECT o.customer.name" (implicit path navigation with join):
  @Query("SELECT o.customer.name FROM Order o")
  // Hibernate 6: may require explicit LEFT JOIN:
  @Query("SELECT c.name FROM Order o LEFT JOIN Customer c ON c.id = o.customerId")
  // Check all JPQL queries with path navigation after upgrading.

COLLECTION SEMANTICS (Hibernate 5 -> 6):

  // Hibernate 5: List<OrderItem> mapped as "bag" by default.
  //   Bag semantics: allows duplicate elements, no ordering guarantee.
  //   JOIN FETCH on two bags: MultipleBagFetchException (or enabled with fetch="select").
  
  // Hibernate 6: List maps to "list" semantics (ordered, requires @OrderColumn or @OrderBy).
  //   @OneToMany List<OrderItem>: without @OrderColumn, Hibernate may issue a warning.
  //   Fix: add @OrderColumn(name = "position") for ordered lists.
  //   Or: use Set<OrderItem> for unordered collections.
  //   Or: add @OrderBy("id ASC") for query-time ordering.

SPRING BOOT MIGRATION TABLE:

  Spring Boot 2.x:
    Hibernate: 5.6.x
    JPA: javax.persistence
    Jakarta: javax.* namespace
    Spring: 5.x
  
  Spring Boot 3.x:
    Hibernate: 6.x
    JPA: jakarta.persistence
    Jakarta: jakarta.* namespace
    Spring: 6.x
    Minimum Java: 17
  
  Migration path:
    1. Upgrade to Spring Boot 3.x
    2. Run IDE migration: javax -> jakarta
    3. Run tests: fix JPQL errors
    4. Update @Type usages: string to class
    5. Check List<> collections: add @OrderColumn or use Set<>
    6. Update hypersistence-utils to 62+ (if used)
    7. Run full integration test suite
    8. Load test: compare query plans between H5 and H6

ECLIPSELINK TO HIBERNATE SPECIFIC CHANGES:

  // EclipseLink cache:
  @Entity
  @Cache(type = CacheType.SOFT, size = 1000, expiry = 3600000)
  // EclipseLink-specific @Cache annotation.
  
  // Hibernate cache (replace with):
  @Entity
  @org.hibernate.annotations.Cache(
      usage = CacheConcurrencyStrategy.READ_WRITE,
      region = "product")
  // Different annotation, different configuration model.
  
  // EclipseLink JPQL: entity alias not required in ORDER BY.
  // Hibernate JPQL: alias required.
  
  // EclipseLink-specific: @Multitenant(SINGLE_TABLE), @TenantDiscriminatorColumn
  // Hibernate alternative: Hibernate filters or custom multi-tenancy support.
  // Full rewrite needed if using multi-tenancy features.
```

> **Code walkthrough:** This L5 Migration example demonstrates contract definition using SQL. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **TAKEAWAY: interfaces define contracts; prefer them over abstract classes for unrelated types.**

---

### 💻 Code Example

> **Code walkthrough:** The OpenRewrite recipe automates the mechanical javax->jakarta import rename.
> The manual steps are for semantic changes (JPQL, @Type) that require human review.

```java
// MIGRATION VALIDATION TEST (run before and after migration):

@SpringBootTest
public class JpaMigrationValidationTest {
    
    @Autowired OrderRepository orderRepository;
    @Autowired CustomerRepository customerRepository;
    
    @Test
    @Transactional
    void jpqlQueriesReturnCorrectResults() {
        // Create test data:
        Customer customer = customerRepository.save(
            new Customer("Alice", "alice@example.com"));
        Order order1 = orderRepository.save(
            new Order(customer.getId(), OrderStatus.COMPLETE));
        Order order2 = orderRepository.save(
            new Order(customer.getId(), OrderStatus.DRAFT));
        
        // Test all custom @Query methods:
        List<Order> complete = orderRepository
            .findByStatusAndCustomer(OrderStatus.COMPLETE, customer.getId());
        assertThat(complete).hasSize(1);
        assertThat(complete.get(0).getId()).isEqualTo(order1.getId());
        
        // Test that JOIN FETCH works (no MultipleBagFetchException):
        List<Order> withItems = orderRepository.findCompleteOrdersWithItems();
        assertThat(withItems).isNotEmpty();
    }
    
    @Test
    @Transactional
    void nativeQueries_returnCorrectResults() {
        // Native SQL: test DB-specific syntax still works:
        List<Object[]> result = orderRepository.findOrderSummariesNative();
        assertThat(result).isNotEmpty();
    }
    
    @Test
    void entityMappings_validateCorrectly() {
        // Spring Boot validation on startup: ddl-auto=validate.
        // If entity mappings don't match DB schema: startup fails.
        // This test: just starting the context is the validation.
        // If the context starts: mappings are valid.
    }
}
```

> **Code walkthrough:** The migration validation test suite should exist BEFORE the migration
> begins. Run it against Hibernate 5 to establish a passing baseline. Upgrade to Hibernate 6. Run
> the same test suite. Fix failures one by one. The `entityMappings_validateCorrectly` test is
> the simplest: if the Spring context starts without error (with `ddl-auto=validate`), all entity
> mappings are valid against the current DB schema. JPQL tests: catch query parsing regressions.
> Native query tests: catch DB dialect changes.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Hibernate 6 / Spring Boot 3: the main change is `javax.*` -> `jakarta.*`. Use IDE migration
> tools or OpenRewrite. Run all tests after migration. Common failures: `@Type` annotation syntax
> changed, List collection ordering behavior changed.

---

**Senior / Staff (5+ years):**
> Hibernate 5 to 6 is a significant migration for codebases that used Hibernate-specific features
> (`@Type`, custom `UserType`, `Criteria` API). The safest strategy: (1) add integration tests
> before starting. (2) Upgrade Spring Boot to 3.x on a branch. (3) Run IDE javax->jakarta migration.
> (4) Fix compile errors. (5) Fix test failures. (6) Load test: query plans change between versions.
> For EclipseLink to Hibernate migrations: the hardest part is L2 cache configuration (completely
> different provider model) and any use of `@Multitenant` (requires rewrite).

---

### ⚠️ Common Misconceptions

**Misconception: "JPA-standard code migrates between providers without changes."**
JPA is a specification. Both EclipseLink and Hibernate implement it. In theory: JPA-standard code
(annotations, EntityManager API, JPQL) should be portable. In practice: (1) JPQL: both support the
standard, but each has extensions and slightly different behaviors for edge cases (path navigation,
implicit joins, ORDER BY behavior). (2) Caching: the JPA standard defines the cache API but not the
provider configuration. `@Cache` annotation is Hibernate-specific. EclipseLink has its own `@Cache`.
(3) Native SQL and `@Type`: provider-specific, not portable. (4) Performance behavior: query plans
differ. A query fast in EclipseLink may be slow in Hibernate (different query generation, different
caching behavior). Always run a load test after migrating providers. Plan for 2-4 weeks of tuning.

---

### ⚖️ Comparison Table

| Migration Type | Main Risks | Test Coverage Needed | Estimated Effort |
|---|---|---|---|
| Hibernate 5 -> 6 (SB 2->3) | javax->jakarta, @Type API, JPQL | Integration tests for all queries | 2-6 weeks |
| EclipseLink -> Hibernate | L2 cache config, JPQL differences, @Cache | All queries + cache behavior | 4-12 weeks |
| Hibernate 4 -> 5 | Smaller changes, Criteria API | Core queries + criteria | 1-3 weeks |
| Spring Data version upgrade | Repository method signatures | Repository tests | 1-2 days |

---

### 🏛️ System Design

**Incremental migration strategy for large codebases:**
```
PHASE 1: BASELINE (Before migration)
  
  Goal: establish test coverage baseline.
  
  1. Run coverage report: which JPA queries have tests?
  2. Write integration tests for all untested @Query methods.
  3. Add query count assertions (Hibernate Statistics).
  4. Document all Hibernate-specific features in use:
     @Type, @BatchSize, @Cache, custom UserType, native SQL.
  5. Commit to main (not migration branch yet).

PHASE 2: DEPENDENCY UPGRADE (Migration branch)
  
  1. Create feature branch: git checkout -b hibernate6-migration
  2. Update pom.xml: spring-boot-starter 3.x
  3. Run IDE migration: Javax to Jakarta Namespace
  4. Fix compile errors (start with @Type changes).
  5. Run unit tests: fix failures.
  6. Run integration tests: fix failures.
  
  Common integration test failures:
  a. JPQL path navigation: add explicit JOINs.
  b. @Type(type="json"): change to @Type(JsonType.class)
  c. List collection: add @OrderColumn or change to Set.
  d. UserType: rewrite to new interface.

PHASE 3: LOAD TESTING
  
  1. Deploy to staging with production traffic replay.
  2. Compare: query execution times H5 vs H6.
  3. Identify regressions (queries > 20% slower).
  4. Fix: usually a missing index hint or query rewrite.
  5. Document: what changed in query plans.

PHASE 4: PRODUCTION DEPLOYMENT
  
  1. Blue-green deployment.
  2. Monitor: error rate, latency p99, DB query count.
  3. Rollback plan: keep H5 branch deployable for 2 weeks.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 📊 Diagram

**Hibernate 5 to 6 migration checklist:**

```
  MIGRATION CHECKLIST (H5 -> H6 / Spring Boot 3)

  ┌─────────────────────────────────────────────────────┐
  │ 1. Test Coverage                                    │
  │    [ ] All @Query methods have integration tests    │
  │    [ ] Query count assertions in place              │
  │    [ ] Native SQL tests                             │
  │                                                     │
  │ 2. javax -> jakarta                                 │
  │    [ ] IDE migration run                            │
  │    [ ] No javax.persistence imports remain          │
  │    [ ] No javax.transaction imports remain          │
  │                                                     │
  │ 3. @Type annotation                                 │
  │    [ ] String-based @Type("name") -> @Type(Class)   │
  │    [ ] Custom UserType rewritten                    │
  │    [ ] hypersistence-utils: 62+ version             │
  │                                                     │
  │ 4. JPQL/HQL                                         │
  │    [ ] All implicit joins -> explicit JOIN          │
  │    [ ] Path navigation queries reviewed             │
  │    [ ] Named queries validated                      │
  │                                                     │
  │ 5. Collections                                      │
  │    [ ] List -> @OrderColumn or Set                  │
  │    [ ] No MultipleBagFetchException                 │
  │                                                     │
  │ 6. Performance                                      │
  │    [ ] Load test passed (vs H5 baseline)            │
  │    [ ] Query plans reviewed (no new seq scans)      │
  └─────────────────────────────────────────────────────┘
```

```mermaid
flowchart TD
    A[Start: H5/SB2 codebase] --> B[Phase 1: Add integration tests\nEstablish qu
    B --> C{Coverage >= 80%?}
     C --> | No  | D[Write more tests]                            
    D --> C
     C --> | Yes | E[Phase 2: Upgrade SB3 + H6]                   
    E --> F[Run IDE javax->jakarta migration]
    F --> G[Fix compile errors\n @Type, UserType, etc.]
    G --> H[Run integration tests]
    H --> I{All passing?}
     I --> | No  | J[Fix: JPQL, collections, @Type]               
    J --> H
     I --> | Yes | K[Phase 3: Load test\nCompare H5 vs H6 perf]   
    K --> L{Perf regressions?}
     L --> | Yes | M[Fix slow queries\nAdd indexes, rewrite JPQL] 
    M --> K
     L --> | No  | N[Phase 4: Deploy to Staging]                  
    N --> O[Monitor: errors, latency, DB]
    O --> P{Issues?}
     P --> | Yes | Q[Fix or rollback to H5]                       
     P --> | No  | R[Production Deploy\nBlue-Green]               
```

> **Diagram walkthrough:** The flowchart shows the four-phase migration process with explicit
> go/no-go gates. Phase 1 (test coverage) is a prerequisite: migrating without tests is flying
> blind. Phase 2 (upgrade) iterates until all tests pass. Phase 3 (load test) is critical because
> Hibernate 6 may generate different query plans. Phase 4 (deploy) uses blue-green deployment so
> the old version is always available for rollback. The migration is complete only when production
> monitoring shows stable error rates and latency for at least 24-48 hours.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Post-migration performance regression: queries 5x slower in Hibernate 6.**
```
Symptom: after H5->H6 migration, findOrdersByCustomer() goes from 20ms to...
  Load test: p99 increased from 200ms to 1000ms for order queries.
  DB: no new load. Query plan changed.

Root cause: Hibernate 6 generates different SQL for the query.
  H5: SELECT o.* FROM orders o WHERE o.customer_id = ?
      (index scan on customer_id: fast)
  
  H6: SELECT o.* FROM orders o, customers c
      WHERE o.customer_id = c.id AND c.id = ?
      (explicit join: different query plan in PostgreSQL planner)
      (planner chooses seq scan: missing index on join condition)

Diagnosis:
  spring.jpa.properties.hibernate.generate_statistics=true
  Log: queryExecutionMaxTime. Compare H5 baseline vs H6.
  
  pg_stat_statements: find the slow query text.
  EXPLAIN ANALYZE: compare query plans H5 vs H6.
  H5 plan: Index Scan on orders (customer_id=?)
  H6 plan: Nested Loop -> Seq Scan on orders, Index Scan on customers

Fix:
  Option 1: Add missing index:
    CREATE INDEX idx_orders_customer_id ON orders(customer_id);
    (may already exist; check if query plan uses it)
  
  Option 2: Rewrite query to match H6 SQL generation:
    @Query("SELECT o FROM Order o WHERE o.customerId = :customerId")
    // No JOIN at all (ID-only reference). H6: simple WHERE. Fast.
  
  Prevention: run EXPLAIN ANALYZE on all critical queries after migration.
    Compare plans. Investigate any plan that changed from index scan to seq scan.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Hibernate 5 to 6 breaking changes | 3 minutes |
| javax -> jakarta migration | 2 minutes |
| @Type migration | 2 minutes |
| JPQL changes in H6 | 2 minutes |
| Migration strategy phases | 2 minutes |
| EclipseLink to Hibernate | 2 minutes |
| Performance regression post-migration | 2 minutes |
| Test coverage before migration | 1 minute |
| Spring Boot 2 to 3 implications | 1 minute |
| Rollback strategy | 1 minute |
| Collection semantics change | 1 minute |
| OpenRewrite tooling | 1 minute |

---

**Q1 (breaking change): What are the most impactful breaking changes when migrating from Hibernate 5 to Hibernate 6?**

A: Top breaking changes in Hibernate 6: (1) Jakarta namespace: all `javax.persistence.*` -> `jakarta.persistence.*`. Affects every entity, repository, service, and test. Automated migration available (IDE, OpenRewrite). (2) `@Type` annotation: string-based type name (`@Type(type="json")`) replaced with class reference (`@Type(JsonType.class)`). All custom type usages need updating. The `UserType` interface: changed method signatures (typed generics). Third-party libraries (Hibernate Types by Vlad Mihalcea): update to hypersistence-utils-hibernate-62+. (3) JPQL/HQL stricter: implicit cross joins (two entities in FROM without explicit join) deprecated or changed behavior. Path navigation: some forms require explicit JOIN. (4) List semantics: `List<>` collections in Hibernate 6 expect an `@OrderColumn` for positional ordering. Without it: ordering is not guaranteed. Existing code using `List<>` for bags may get unexpected ordering or warnings. Fix: add `@OrderBy("id ASC")` or change to `Set<>`. (5) `SchemaExport` and `Metadata` API changes: affects code that programmatically generates schema. (6) Minimum Java version: Java 11 for Hibernate 6.1, Java 11+ recommended.

*What separates good from great:* The hidden Hibernate 6 performance change: H6 generates more
correct SQL at the cost of sometimes different query plans. Example: H5 for a `@ManyToOne` fetch
in a JPQL query sometimes used a subquery. H6 may use a JOIN. The JOIN is more standard but the
PostgreSQL planner may not always choose the same index scan. Result: queries that were fast in H5
become slower in H6 not due to bugs but due to different (more correct) SQL generation. Testing
strategy: save the H5 SQL for all critical queries (`spring.jpa.show-sql=true` + log review). After
H6 migration: compare generated SQL side-by-side. For any query where SQL changed: run EXPLAIN ANALYZE
on both. If the plan changed: check if an index covers the new join condition. Add indexes if needed.
H6 migration: the DB schema may need index additions to match the new query patterns.

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*




