---
layout: default
title: "Spring - Data Access"
parent: "Spring"
grand_parent: "Interview Mastery"
nav_order: 6
permalink: /interview/spring/data-access/
topic: Spring
subtopic: Data Access
keywords:
  - Spring Data JPA
  - Transaction Management
  - Connection Pooling
  - Spring JDBC vs JPA
  - Caching with Spring
difficulty_range: medium to hard
status: complete
version: 3
---

**Keywords covered in this file:**

- [Spring Data JPA](#spring-data-jpa)
- [Transaction Management](#transaction-management)
- [Connection Pooling](#connection-pooling)
- [Spring JDBC vs JPA](#spring-jdbc-vs-jpa)
- [Caching with Spring](#caching-with-spring)

# Spring Data JPA

**TL;DR** - Spring Data JPA eliminates boilerplate DAO code by generating repository implementations from interfaces at runtime - define a method like `findByEmailAndStatus()` and Spring creates the query automatically from the method name, reducing data access code by 80-90%.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every entity needs a DAO class with 5-10 methods: findById, findAll, save, update, delete, plus custom queries. Each method requires EntityManager injection, JPQL or Criteria API queries, transaction management, and error handling. 50 entities = 50 DAO classes = 250+ nearly identical methods.

**THE BREAKING POINT:**
A new developer copies a DAO, changes the entity type, misses updating one query, and introduces a subtle bug. Code reviews catch it, but the team spends more time reviewing boilerplate than business logic.

**THE INVENTION MOMENT:**
"This is exactly why Spring Data JPA was created."

**EVOLUTION:**
Raw JDBC -> JPA EntityManager -> DAO pattern with generics -> Spring Data JPA repository interfaces (2011) -> derived query methods -> `@Query` annotation -> Querydsl/Specifications for dynamic queries.

---

### 📘 Textbook Definition

Spring Data JPA is a module that implements the Repository pattern by generating JPA-based data access code from interface definitions at runtime. You declare a repository interface extending `JpaRepository<Entity, ID>`, and Spring creates the implementation automatically. Query derivation parses method names (`findByLastNameAndAgeGreaterThan`) into JPQL queries. For complex queries, `@Query` provides explicit JPQL or native SQL. `Specification` and `Querydsl` support dynamic, composable query criteria.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Define an interface, get a full repository implementation - including derived queries from method names.

**One analogy:**

> A library catalog. You describe what book you want ("find by author and published after 2020") and the librarian (Spring Data) knows exactly how to search the shelves (database). You never tell the librarian which shelf to look on or how to sort - just what you want.

**One insight:**
Spring Data does not replace JPA - it sits on top of it. The generated implementation still uses EntityManager, JPQL, and JPA under the hood. Understanding JPA is still essential for debugging and optimization.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. Repository interfaces are never implemented by you. Spring generates proxy implementations at startup.
2. Method name parsing follows strict conventions: `findBy{Property}{Operator}`. Typos cause startup failures (fail-fast).
3. `JpaRepository` extends `CrudRepository` extends `Repository`. Each level adds more methods.

**DERIVED DESIGN:**
From invariant 1: no boilerplate DAO code. From invariant 2: query correctness is validated at startup, not runtime. From invariant 3: choose the interface level based on what methods you need.

**THE TRADE-OFFS:**

**Gain:** 80-90% less data access code. Queries validated at startup.

**Cost:** Complex queries are hard to express as method names. Performance tuning requires understanding the generated SQL.

---

### 🧠 Mental Model / Analogy

> Spring Data JPA is like a voice assistant for your database. You say "find all users with email ending in @company.com ordered by name" (method name), and the assistant (Spring) translates it into the right query. For complex requests, you can write the query yourself (`@Query`). But for 80% of cases, just describing what you want is enough.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is:**
Define an interface, Spring generates database queries. No SQL needed for simple cases.

**Level 2 - How to use it (junior):**

```java
public interface UserRepository
        extends JpaRepository<User, Long> {

    List<User> findByEmail(String email);

    List<User> findByLastNameAndAge(
        String lastName, int age);

    Optional<User> findByUsername(
        String username);
}
// No implementation needed!
// Spring creates it at startup.
```

**Level 3 - How it works (mid-level):**

Query derivation parsing:

```
findByLastNameAndAgeGreaterThan
  |         |       |
  find      |       operator: >
  By        |
  LastName: property "lastName"
  And: conjunction
  Age: property "age"
  GreaterThan: WHERE age > ?
```

Generated JPQL:

```sql
SELECT u FROM User u
WHERE u.lastName = ?1
AND u.age > ?2
```

For complex queries:

```java
@Query("SELECT u FROM User u "
    + "WHERE u.department.name = :dept "
    + "AND u.salary > :min "
    + "ORDER BY u.salary DESC")
List<User> findTopEarners(
    @Param("dept") String dept,
    @Param("min") BigDecimal min);
```

**Level 4 - Mastery (senior/staff+):**

Pagination and sorting:

```java
Page<User> findByDepartment(
    String dept, Pageable pageable);

// Usage:
Pageable page = PageRequest.of(
    0, 20, Sort.by("name").ascending());
Page<User> result =
    repo.findByDepartment("eng", page);
```

Dynamic queries with Specifications:

```java
public interface UserRepository
        extends JpaRepository<User, Long>,
        JpaSpecificationExecutor<User> {}

Specification<User> hasName(String name) {
    return (root, query, cb) ->
        cb.equal(root.get("name"), name);
}

Specification<User> olderThan(int age) {
    return (root, query, cb) ->
        cb.greaterThan(
            root.get("age"), age);
}

// Composable:
repo.findAll(
    hasName("John").and(olderThan(25)));
```

Projections for performance:

```java
public interface UserSummary {
    String getName();
    String getEmail();
}

List<UserSummary> findByDepartment(
    String dept);
// Only fetches name and email columns
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use Spring Data JPA repositories to avoid writing DAOs."

**A Staff says:** "I choose the right query strategy per use case: derived queries for simple lookups, `@Query` for complex joins, Specifications for dynamic search, and native SQL for analytics. I use projections to avoid fetching unnecessary columns and `@EntityGraph` to control eager/lazy loading per query."

**Level 5 - Distinguished:**
Spring Data's repository abstraction works across data stores: JPA, MongoDB, Redis, Elasticsearch, Cassandra - same interface pattern, different implementations. This is the Repository pattern from DDD applied at the framework level. At scale, the N+1 query problem is the most common performance issue: fix with `@EntityGraph`, `JOIN FETCH` in `@Query`, or batch fetching.

---

### ⚙️ How It Works

```
  UserRepository interface defined
       |
  Spring Boot startup:
  RepositoryFactorySupport scans
       |
  For each interface:
    Create JDK Proxy
    Generate query for each method
    Validate queries against JPA model
       |
  Proxy registered as Spring bean
       |
  Runtime: method called on proxy
    -> route to SimpleJpaRepository
       or generated query
    -> EntityManager executes query
    -> Results mapped to entities
```

---

### 💻 Code Example

**BAD manual DAO vs GOOD Spring Data:**

```java
// BAD - manual DAO (50+ lines)
@Repository
public class UserDaoImpl {
    @PersistenceContext
    EntityManager em;

    public Optional<User> findById(
            Long id) {
        return Optional.ofNullable(
            em.find(User.class, id));
    }

    public List<User> findByEmail(
            String email) {
        return em.createQuery(
            "SELECT u FROM User u "
            + "WHERE u.email = :email",
            User.class)
            .setParameter("email", email)
            .getResultList();
    }
    // ... 8 more methods
}

// GOOD - Spring Data (5 lines)
public interface UserRepository
        extends JpaRepository<User, Long> {
    List<User> findByEmail(String email);
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Generated repository implementations from interface definitions.

**PROBLEM IT SOLVES:** Eliminates 80-90% of boilerplate data access code.

**KEY INSIGHT:** Method names are parsed into queries. Typos fail at startup (fail-fast).

**USE WHEN:** Any JPA-based data access layer.

**AVOID WHEN:** Complex analytics queries (use native SQL or JOOQ).

**ANTI-PATTERN:** Fetching entire entities when you need 2 columns (use projections).

**ONE-LINER:** "Interface + method name = generated query."

**TRIGGER PHRASE:** "Repository pattern with query derivation."

**If you remember only 3 things:**

1. Interface only - Spring generates the implementation
2. Method name -> query derivation (validated at startup)
3. @Query for complex, Specifications for dynamic queries

---

### ⚠️ Common Misconceptions

| #   | Misconception                           | Reality                                                                |
| --- | --------------------------------------- | ---------------------------------------------------------------------- |
| 1   | "Spring Data replaces JPA"              | It sits on top of JPA. EntityManager is still used underneath.         |
| 2   | "Method names can express any query"    | Complex joins, subqueries, and aggregations need @Query or native SQL. |
| 3   | "findAll() is fine for large tables"    | It loads every row into memory. Use pagination.                        |
| 4   | "Spring Data handles N+1 automatically" | No. You must use @EntityGraph or JOIN FETCH.                           |

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: What is Spring Data JPA and how does it work?**

**Answer:**
You define a repository interface extending `JpaRepository<User, Long>`. Spring generates the implementation at startup. Method names like `findByEmail()` are parsed into JPQL queries. `@Query` handles complex queries. No DAO boilerplate needed.

_What separates good from great:_ Mentioning startup validation and the method name parsing rules.

---

**Q2 [MID]: How do you solve the N+1 query problem with Spring Data JPA?**

**Answer:**
N+1 happens when loading entities with lazy associations - 1 query for the list, N queries for each association.

Solutions:

1. `@EntityGraph` on repository method:

```java
@EntityGraph(attributePaths =
    {"department", "roles"})
List<User> findByStatus(String status);
```

2. `JOIN FETCH` in `@Query`:

```java
@Query("SELECT u FROM User u "
    + "JOIN FETCH u.department "
    + "WHERE u.status = :s")
List<User> findActive(
    @Param("s") String status);
```

3. `@BatchSize(size = 50)` on the association for batch loading.

_What separates good from great:_ Multiple strategies with trade-offs (EntityGraph changes fetch semantics globally for that query).

---

**Q3 [SENIOR]: When would you NOT use Spring Data JPA?**

**Answer:**
Avoid Spring Data JPA for:

- **Analytics/reporting:** Complex aggregations, window functions, CTEs. Use native SQL, JOOQ, or a dedicated analytics store.
- **Bulk operations:** Updating 100K rows should use `@Modifying @Query` or JDBC batch, not entity loading.
- **High-performance reads:** When ORM overhead matters. Use Spring JDBC or JOOQ for raw performance.
- **Non-relational patterns:** Graph traversals, full-text search. Use specialized stores.

I use Spring Data JPA for CRUD and simple queries (80% of data access), and JOOQ/native SQL for the remaining 20%.

_What separates good from great:_ The 80/20 split and specific alternatives for each case.

---

### 🔗 Related Keywords

**Prerequisites:** IoC Container, Transaction Management

**Builds on:** Hibernate, JPA

**Alternatives:** JOOQ, MyBatis, Spring JDBC

---

---

# Transaction Management

**TL;DR** - Spring's `@Transactional` annotation provides declarative transaction management that wraps methods in begin/commit/rollback logic via AOP proxies - ensuring data consistency without manual transaction handling code.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every database operation requires manual `EntityManager.getTransaction().begin()`, try-catch with `commit()` in try and `rollback()` in catch. Nested transactions require manual savepoints. Transaction boundaries are scattered across business logic.

**THE BREAKING POINT:**
A service method calls three DAOs. The third fails. The first two already committed. Data is inconsistent. The developer forgot to wrap all three in a single transaction.

**THE INVENTION MOMENT:**
"This is exactly why @Transactional was created."

**EVOLUTION:**
Manual JDBC transactions -> JTA (distributed, complex) -> Spring `PlatformTransactionManager` (programmatic) -> `@Transactional` (declarative, Spring 1.0) -> reactive transaction management (Spring 5).

---

### 📘 Textbook Definition

Spring's declarative transaction management uses AOP proxies to intercept methods annotated with `@Transactional`. The proxy calls `PlatformTransactionManager.getTransaction()` before the method, `commit()` on success, and `rollback()` on RuntimeException. Transaction attributes (propagation, isolation, timeout, readOnly, rollbackFor) control behavior. The default propagation is `REQUIRED` (join existing or create new).

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Put `@Transactional` on a method and Spring handles begin, commit, and rollback automatically.

**One analogy:**

> A safety net under a trapeze act. The performer (business logic) focuses on the routine. If they fall (exception), the safety net (rollback) catches them. If they complete the routine (success), they walk off (commit). The net is always there without the performer thinking about it.

**One insight:**
`@Transactional` works through AOP proxies. This means self-invocation (calling a `@Transactional` method from within the same class) bypasses the proxy and the transaction is NOT applied. This is the #1 `@Transactional` bug.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. `@Transactional` is a proxy-based mechanism. The proxy wraps the method call with transaction logic.
2. Default rollback is on unchecked exceptions (RuntimeException) only. Checked exceptions commit.
3. Propagation defines how nested `@Transactional` methods interact: join, create new, or suspend.

**DERIVED DESIGN:**
From invariant 1: self-invocation bypasses the proxy (no transaction). From invariant 2: you must specify `rollbackFor = Exception.class` if you want checked exception rollback. From invariant 3: `REQUIRES_NEW` creates an independent transaction; `REQUIRED` joins the existing one.

**THE TRADE-OFFS:**

**Gain:** Clean business logic. No manual transaction code.

**Cost:** Proxy-based magic causes self-invocation bug. Transaction boundaries not visible in code.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is:**
An annotation that automatically wraps your method in a database transaction.

**Level 2 - How to use it (junior):**

```java
@Service
public class OrderService {
    @Transactional
    public Order placeOrder(OrderReq req) {
        Order order = orderRepo.save(
            new Order(req));
        inventoryService.reserve(
            req.getItems());
        paymentService.charge(
            req.getPayment());
        return order;
        // All three committed together
        // or all rolled back
    }
}
```

**Level 3 - How it works (mid-level):**

```
  Caller -> AOP Proxy
       |
  Proxy: begin transaction
       |
  Proxy: invoke actual method
       |
  Success? -> Proxy: commit
  RuntimeException? -> Proxy: rollback
  Checked exception? -> Proxy: COMMIT!
  (default behavior - surprising)
```

Key attributes:

| Attribute   | Default          | Purpose                   |
| ----------- | ---------------- | ------------------------- |
| propagation | REQUIRED         | Join or create            |
| isolation   | DEFAULT          | DB default                |
| readOnly    | false            | Optimize reads            |
| timeout     | -1 (none)        | Max seconds               |
| rollbackFor | RuntimeException | Which exceptions rollback |

**Level 4 - Mastery (senior/staff+):**

Self-invocation problem:

```java
@Service
public class UserService {
    public void process() {
        // THIS DOES NOT START
        // A TRANSACTION!
        // Self-invocation bypasses proxy
        this.updateUser();
    }

    @Transactional
    public void updateUser() { }
}

// Fix 1: Inject self
@Autowired
private UserService self;
public void process() {
    self.updateUser(); // goes through proxy
}

// Fix 2: Separate class
@Service
public class UserUpdater {
    @Transactional
    public void updateUser() { }
}
```

Propagation behaviors:

```
REQUIRED (default):
  Caller has TX? -> join it
  No TX? -> create new

REQUIRES_NEW:
  Always create new TX
  Suspend existing if any
  (independent commit/rollback)

NESTED:
  Create savepoint in existing TX
  Rollback to savepoint on failure
  Outer TX still controls final commit

SUPPORTS:
  Has TX? -> use it
  No TX? -> run without TX

NOT_SUPPORTED:
  Suspend TX if exists
  Run without TX
```

`readOnly = true` optimization:

```java
@Transactional(readOnly = true)
public List<User> findActive() {
    return repo.findByStatus("ACTIVE");
    // Hibernate skips dirty checking
    // DB may route to read replica
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Put `@Transactional` on service methods."

**A Staff says:** "I design transaction boundaries at the service layer, use `readOnly = true` for queries (enables read replica routing), specify `rollbackFor = Exception.class` for checked exceptions, and use `REQUIRES_NEW` only when I need independent commit (audit logs). I know the self-invocation trap and always call through the proxy."

**Level 5 - Distinguished:**
Spring's transaction abstraction (`PlatformTransactionManager`) supports JPA, JDBC, JTA, and reactive transactions through a single API. At distributed scale, `@Transactional` covers single-database transactions. Cross-service transactions require saga patterns or event-driven eventual consistency - `@Transactional` is the wrong tool for distributed systems.

---

### ⚙️ How It Works

```
  @Transactional method called
       |
  AOP proxy intercepts
       |
  TransactionInterceptor:
    Get PlatformTransactionManager
    Begin transaction (or join)
       |
  Invoke actual method
       |
  No exception: commit
  RuntimeException: rollback
  Checked exception: COMMIT (default!)
       |
  Return result to caller
```

---

### 💻 Code Example

**BAD manual transaction vs GOOD declarative:**

```java
// BAD - manual transaction management
public void transfer(Long from, Long to,
        BigDecimal amount) {
    EntityTransaction tx =
        em.getTransaction();
    try {
        tx.begin();
        debit(from, amount);
        credit(to, amount);
        tx.commit();
    } catch (Exception e) {
        tx.rollback();
        throw e;
    }
}

// GOOD - declarative
@Transactional(
    rollbackFor = Exception.class)
public void transfer(Long from, Long to,
        BigDecimal amount) {
    debit(from, amount);
    credit(to, amount);
    // Automatic commit/rollback
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** AOP proxy-based declarative transaction management.

**PROBLEM IT SOLVES:** Eliminates manual begin/commit/rollback code.

**KEY INSIGHT:** Self-invocation bypasses the proxy = no transaction. Always call through the proxy.

**ANTI-PATTERN:** Missing `rollbackFor` on checked exceptions. Self-invocation.

**ONE-LINER:** "@Transactional = proxy wraps with begin/commit/rollback."

**TRIGGER PHRASE:** "Proxy-based, self-invocation trap."

**If you remember only 3 things:**

1. Works through AOP proxy - self-invocation bypasses it
2. Default rollback on RuntimeException ONLY - add rollbackFor for checked
3. Propagation REQUIRED (join/create) is the default

---

### ⚠️ Common Misconceptions

| #   | Misconception                             | Reality                                                                  |
| --- | ----------------------------------------- | ------------------------------------------------------------------------ |
| 1   | "Self-invocation is transactional"        | No. Internal calls bypass the proxy. No transaction applied.             |
| 2   | "All exceptions cause rollback"           | Only RuntimeException by default. Checked exceptions COMMIT.             |
| 3   | "@Transactional on private methods works" | No. Proxies cannot intercept private methods.                            |
| 4   | "readOnly prevents writes"                | Not enforced by Spring. It is a hint to the persistence provider and DB. |

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: What does @Transactional do?**

**Answer:**
It wraps a method in a database transaction via AOP proxy. Before the method: begin transaction. After success: commit. On RuntimeException: rollback. Attributes control propagation (REQUIRED, REQUIRES_NEW), isolation level, timeout, and which exceptions trigger rollback.

---

**Q2 [MID]: Explain the self-invocation problem with @Transactional.**

**Answer:**

```java
@Service
class OrderService {
    public void process() {
        this.save(); // NO TRANSACTION!
    }
    @Transactional
    public void save() { }
}
```

`this.save()` calls the actual method, not the proxy. The proxy never intercepts, so no transaction starts.

Fixes: inject self (`@Autowired OrderService self; self.save()`), extract to separate class, or use `@EnableAspectJAutoProxy(exposeProxy = true)` + `AopContext.currentProxy()`.

---

**Q3 [SENIOR]: Design transaction boundaries for an order placement service.**

**Answer:**

```java
@Transactional
public Order placeOrder(OrderReq req) {
    // Single TX for core operations:
    Order order = orderRepo.save(
        new Order(req));
    inventory.reserve(req.getItems());
    payment.charge(req.getPayment());
    return order;
}

// Audit log: independent TX
// (must persist even if order fails)
@Transactional(
    propagation = REQUIRES_NEW)
public void auditLog(String event) {
    auditRepo.save(new AuditEntry(event));
}
```

`readOnly = true` for all query methods. Saga pattern for cross-service transactions (not `@Transactional`).

---

### 🔗 Related Keywords

**Prerequisites:** IoC Container, AOP Proxies

**Builds on:** Spring Data JPA

**Alternatives:** Programmatic TransactionTemplate, JTA for distributed

---

---

# Connection Pooling

**TL;DR** - HikariCP (Spring Boot's default connection pool) maintains a pool of pre-established database connections that are reused across requests, eliminating the 50-200ms overhead of creating a new connection per query and preventing connection exhaustion under load.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every database query opens a new TCP connection (DNS lookup, TCP handshake, TLS negotiation, authentication) - 50-200ms overhead. Under load, thousands of connections overwhelm the database. Connections are never closed properly, leaking resources.

**THE BREAKING POINT:**
100 concurrent requests each open a database connection. The database allows 150 max connections. Connection 151 is rejected. The application crashes.

**THE INVENTION MOMENT:**
"This is exactly why Connection Pooling was created."

---

### 📘 Textbook Definition

Connection pooling maintains a set of pre-established, reusable database connections in memory. When application code requests a connection, the pool lends an idle connection (or waits if all are busy). When code closes the connection, it returns to the pool (not actually closed). HikariCP is Spring Boot's default pool, chosen for its speed, correctness, and minimal overhead. Key settings: `maximumPoolSize` (max connections), `minimumIdle` (min idle connections), `connectionTimeout` (max wait time for a connection), and `maxLifetime` (max connection age).

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Pre-opened database connections are shared and reused instead of creating new ones per request.

**One analogy:**

> A shared car fleet. Instead of buying a car (opening a connection) for every trip and scrapping it after (closing), you rent from a fleet (pool). Cars are pre-fueled (pre-established). When you finish, the car returns to the fleet for the next person.

**One insight:**
The optimal pool size is NOT "as many as possible." It is typically `connections = (CPU cores * 2) + effective_spindle_count`. For most apps: 10-20 connections handle thousands of concurrent requests because each connection is held for milliseconds.

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is:**
A shared collection of database connections that your app reuses instead of creating new ones.

**Level 2 - How to use it (junior):**

```yaml
spring:
  datasource:
    url: jdbc:postgresql://localhost/mydb
    username: app
    password: secret
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 30000
```

HikariCP is the default in Spring Boot - no additional dependency needed.

**Level 3 - How it works (mid-level):**

```
  Request needs DB query
       |
  DataSource.getConnection()
       |
  HikariCP checks pool:
    Idle connection available?
      Yes -> lend it (< 1ms)
      No -> pool full?
        No -> create new connection
        Yes -> wait up to connectionTimeout
          Timeout -> throw exception
       |
  Code uses connection
       |
  connection.close() called
       |
  Connection returned to pool
  (NOT actually closed)
```

Key HikariCP settings:

| Setting           | Default     | Meaning                |
| ----------------- | ----------- | ---------------------- |
| maximumPoolSize   | 10          | Max connections        |
| minimumIdle       | same as max | Min idle connections   |
| connectionTimeout | 30000ms     | Wait for connection    |
| idleTimeout       | 600000ms    | Close idle connections |
| maxLifetime       | 1800000ms   | Max connection age     |

**Level 4 - Mastery (senior/staff+):**

Pool size formula:

```
pool size = (core_count * 2)
          + effective_spindle_count
```

For SSD: effective_spindle_count = 0-1.
For 4-core server: pool size = 8-10.

Why small pools work:

```
  100 concurrent HTTP requests
  Each holds DB connection for 5ms
  Avg query rate: 100 * (5/1000) = 0.5
  concurrent connections needed

  Pool of 10 handles this easily
  with ~5% utilization
```

Connection leak detection:

```yaml
spring:
  datasource:
    hikari:
      leak-detection-threshold: 60000
      # Logs warning if connection
      # not returned within 60s
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Set the pool size to 50 for safety."

**A Staff says:** "I calculate pool size based on CPU cores and query duration. I monitor pool utilization via Actuator metrics (`hikaricp.connections.active`). I set `maxLifetime` below the database's connection timeout to avoid stale connections. Small pools with fast queries outperform large pools."

---

### 💻 Code Example

**BAD oversized pool vs GOOD right-sized:**

```yaml
# BAD - 200 connections "just in case"
spring:
  datasource:
    hikari:
      maximum-pool-size: 200
# DB overwhelmed, context switching
# kills performance

# GOOD - right-sized for 4-core server
spring:
  datasource:
    hikari:
      maximum-pool-size: 10
      minimum-idle: 5
      connection-timeout: 5000
      max-lifetime: 1740000
      leak-detection-threshold: 60000
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Pre-established, reusable database connections managed by HikariCP.

**KEY INSIGHT:** Small pool + fast queries >> large pool. 10 connections handle thousands of requests.

**ANTI-PATTERN:** Setting `maximumPoolSize` to 200 "just in case."

**ONE-LINER:** "Pool size = (cores \* 2) + spindles. Monitor, do not guess."

**TRIGGER PHRASE:** "HikariCP, right-sized pool."

**If you remember only 3 things:**

1. HikariCP is Spring Boot's default - no extra dependency
2. Pool size = (CPU cores \* 2) + spindle count (usually 10-20)
3. Monitor `hikaricp.connections.active` via Actuator

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: How do you size a database connection pool?**

**Answer:**
Formula: `(CPU cores * 2) + effective spindle count`.

For a 4-core server with SSD: 8-10 connections. Why small pools work: each connection is held for milliseconds. 10 connections at 5ms per query handle 2000 queries/second.

Monitor with Actuator: `hikaricp.connections.active`, `hikaricp.connections.pending`. If pending is consistently > 0, increase pool size. If active is < 50% of max, decrease.

---

**Q2 [SENIOR]: Diagnose intermittent "connection pool exhausted" errors.**

**Answer:**

1. Check Actuator metrics: `hikaricp.connections.active` at max when errors occur
2. Enable leak detection: `leak-detection-threshold: 30000`
3. Common causes: long-running transactions holding connections, missing `@Transactional(readOnly = true)` causing unnecessary locks, or N+1 queries holding connections longer than needed
4. Fix: find and optimize slow queries, ensure connections are returned promptly, consider async for I/O-bound work

---

### 🔗 Related Keywords

**Prerequisites:** JDBC, DataSource

**Builds on:** Transaction Management (transactions hold connections)

**Alternatives:** Apache DBCP2, C3P0 (HikariCP is faster)

---

---

# Spring JDBC vs JPA

**TL;DR** - Spring JDBC (JdbcTemplate) gives you full SQL control with minimal abstraction overhead; JPA (via Spring Data JPA) gives you object-relational mapping with entity lifecycle management. Use JDBC for performance-critical queries and analytics; use JPA for CRUD-heavy domain models.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Teams debate endlessly: "Should we use JPA or raw SQL?" Without a clear decision framework, some services use JPA, others use JdbcTemplate, and some use both inconsistently. Developers do not understand when each is appropriate.

---

### 📘 Textbook Definition

Spring JDBC (`JdbcTemplate`) is a lightweight abstraction over raw JDBC that handles connection management, statement creation, result set mapping, and exception translation. JPA (Java Persistence API, typically via Hibernate) is an ORM that maps Java objects to database tables with entity lifecycle management, dirty checking, lazy loading, and JPQL. Spring Data JPA adds repository generation on top.

---

### ⚖️ Comparison Table

| Dimension            | Spring JDBC           | JPA / Spring Data JPA  |
| -------------------- | --------------------- | ---------------------- |
| Abstraction level    | SQL-centric           | Object-centric         |
| Query language       | Native SQL            | JPQL / method names    |
| Performance overhead | Minimal               | Moderate (dirty check) |
| Bulk operations      | Excellent (batch)     | Poor (entity loading)  |
| Complex joins        | Natural (SQL)         | Awkward (JPQL limits)  |
| CRUD boilerplate     | Moderate              | Near zero              |
| Caching              | Manual                | L1/L2 cache built-in   |
| Schema evolution     | Flyway/Liquibase      | + Hibernate DDL        |
| Learning curve       | Lower (SQL)           | Higher (ORM concepts)  |
| When to use          | Analytics, bulk, perf | CRUD, domain model     |

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
// Spring JDBC
@Repository
public class UserJdbcRepo {
    private final JdbcTemplate jdbc;

    public Optional<User> findById(
            Long id) {
        return jdbc.queryForObject(
            "SELECT * FROM users "
            + "WHERE id = ?",
            (rs, row) -> new User(
                rs.getLong("id"),
                rs.getString("name")),
            id);
    }
}

// Spring Data JPA
public interface UserRepository
        extends JpaRepository<User, Long> {
    // findById is inherited. Done.
}
```

**Level 4 - Mastery (senior/staff+):**

When to use each:

```
  CRUD operations
  with entity relationships?
    YES -> JPA (80% of data access)
       |
  Analytics / reporting
  with complex SQL?
    YES -> JDBC or JOOQ
       |
  Bulk insert/update
  (10K+ rows)?
    YES -> JDBC batch
       |
  Both in same service?
    YES -> JPA for entities,
           JDBC for analytics.
           Same DataSource, same TX.
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use JPA for everything."

**A Staff says:** "I use JPA for domain CRUD (80%) and JdbcTemplate for reporting queries and bulk operations (20%). Same DataSource and transaction manager. The key is knowing when ORM overhead matters and when it does not."

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: When would you choose JdbcTemplate over JPA?**

**Answer:**
Choose JdbcTemplate when:

1. **Performance-critical queries:** No ORM overhead (dirty checking, proxy creation)
2. **Complex SQL:** Window functions, CTEs, DB-specific features not available in JPQL
3. **Bulk operations:** Batch insert/update 100K rows without entity loading
4. **Read-only analytics:** No need for entity lifecycle management

Choose JPA when:

1. CRUD with entity relationships (80% of data access)
2. Entity lifecycle matters (dirty checking, cascading)
3. Developer productivity is priority

Best practice: use both. JPA for domain, JDBC for analytics.

---

### 🔗 Related Keywords

**Prerequisites:** JDBC, JPA, SQL

**Builds on:** Spring Data JPA, Connection Pooling

**Alternatives:** JOOQ (type-safe SQL), MyBatis (XML SQL mapping)

---

---

# Caching with Spring

**TL;DR** - Spring's caching abstraction (`@Cacheable`, `@CacheEvict`, `@CachePut`) adds method-level caching via AOP proxies, returning cached results for repeated calls with the same parameters - reducing database load and latency without polluting business logic with caching code.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every service method that calls the database is invoked for every request, even when the data rarely changes. A product catalog page queries the database 100 times per second for the same 50 products. Developers manually add `Map<Key, Value>` caches with inconsistent eviction logic.

**THE BREAKING POINT:**
The database is overwhelmed by repeated identical queries. Response time degrades from 50ms to 5 seconds. The team adds manual caching in 30 different places with 30 different expiry strategies.

**THE INVENTION MOMENT:**
"This is exactly why Spring's caching abstraction was created."

---

### 📘 Textbook Definition

Spring's caching abstraction provides annotation-based cache management through `@Cacheable` (cache the return value), `@CacheEvict` (remove from cache), and `@CachePut` (update cache without skipping method execution). It is backed by a `CacheManager` that supports multiple providers: ConcurrentHashMap (default), Caffeine, Redis, EhCache, Hazelcast. Like `@Transactional`, caching uses AOP proxies - subject to the same self-invocation limitation.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
`@Cacheable` makes a method return cached results for repeated calls with the same parameters.

**One analogy:**

> A memoized function. You calculate the answer once, write it on a sticky note (cache), and next time someone asks the same question, you read the sticky note instead of recalculating. `@CacheEvict` is throwing away the sticky note when the answer changes.

**One insight:**
Like `@Transactional`, `@Cacheable` works through AOP proxies. Self-invocation (calling a `@Cacheable` method from within the same class) bypasses the cache. Same trap, same fix.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
@Service
public class ProductService {
    @Cacheable("products")
    public Product findById(Long id) {
        // DB query - only called on
        // cache miss
        return repo.findById(id)
            .orElseThrow();
    }

    @CacheEvict(value = "products",
        key = "#product.id")
    public Product update(Product product) {
        return repo.save(product);
    }

    @CacheEvict(value = "products",
        allEntries = true)
    public void clearCache() {
        // Evicts all entries in
        // "products" cache
    }
}
```

```yaml
# Use Caffeine (high-performance)
spring:
  cache:
    type: caffeine
    caffeine:
      spec: maximumSize=1000,
        expireAfterWrite=10m
```

**Level 4 - Mastery (senior/staff+):**

Cache-aside pattern implementation:

```
  @Cacheable("products"):
  1. Check cache for key
  2. Cache hit -> return cached value
  3. Cache miss -> execute method
  4. Store result in cache
  5. Return result

  @CachePut("products"):
  1. Execute method (always)
  2. Store result in cache
  3. Return result

  @CacheEvict("products"):
  1. Remove entry from cache
  2. Execute method
```

Custom cache key:

```java
@Cacheable(
    value = "users",
    key = "#dept + '-' + #status")
public List<User> find(
        String dept, String status) {
    return repo.findByDeptAndStatus(
        dept, status);
}
```

Conditional caching:

```java
@Cacheable(
    value = "products",
    condition = "#id > 0",
    unless = "#result == null")
public Product findById(Long id) {
    return repo.findById(id)
        .orElse(null);
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Add `@Cacheable` to reduce database calls."

**A Staff says:** "I design the caching strategy: Caffeine for local high-throughput caching, Redis for distributed cache shared across instances. I set TTL based on data freshness requirements, use `@CacheEvict` on writes to prevent stale data, and monitor cache hit ratios via Micrometer. I never cache user-specific or security-sensitive data without careful TTL."

---

### 💻 Code Example

**BAD manual cache vs GOOD @Cacheable:**

```java
// BAD - manual cache management
private Map<Long, Product> cache =
    new ConcurrentHashMap<>();

public Product findById(Long id) {
    return cache.computeIfAbsent(id,
        k -> repo.findById(k)
            .orElseThrow());
    // No eviction! Memory leak!
    // No TTL! Stale data forever!
}

// GOOD - Spring Cache abstraction
@Cacheable("products")
public Product findById(Long id) {
    return repo.findById(id)
        .orElseThrow();
}
// Eviction, TTL, and monitoring
// handled by Caffeine/Redis config
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** AOP-based method result caching via `@Cacheable`, `@CacheEvict`, `@CachePut`.

**KEY INSIGHT:** Same self-invocation trap as `@Transactional`. Proxy-based.

**ANTI-PATTERN:** Caching without eviction strategy (stale data). Caching mutable objects.

**ONE-LINER:** "@Cacheable = memoization via AOP proxy."

**TRIGGER PHRASE:** "Cache-aside with eviction strategy."

**If you remember only 3 things:**

1. @Cacheable caches, @CacheEvict clears, @CachePut updates
2. AOP proxy - self-invocation bypasses cache (same as @Transactional)
3. Always set TTL and eviction strategy - no cache is better than stale cache

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: How does Spring's @Cacheable work?**

**Answer:**
AOP proxy intercepts method calls. On first call with key (derived from parameters), method executes and result is cached. On subsequent calls with the same key, cached result is returned without executing the method. Backed by CacheManager (Caffeine for local, Redis for distributed). Same self-invocation limitation as `@Transactional`.

---

**Q2 [SENIOR]: Design a caching strategy for a product catalog with 100K products.**

**Answer:**

- **Local cache (Caffeine):** 10K most-accessed products, 5-minute TTL
- **Distributed cache (Redis):** All 100K products, 1-hour TTL, shared across 20 instances
- **Multi-level:** Check Caffeine first, then Redis, then DB
- **Eviction:** `@CacheEvict` on product updates. Pub/Sub for cross-instance eviction.
- **Monitoring:** Hit ratio via Micrometer. Alert if ratio drops below 90%.
- **Cold start:** Warm cache on startup for top 1000 products.

---

### 🔗 Related Keywords

**Prerequisites:** IoC Container, AOP Proxies

**Builds on:** Spring Data JPA (caching query results)

**Alternatives:** Caffeine (standalone), Redis (standalone), Hazelcast
