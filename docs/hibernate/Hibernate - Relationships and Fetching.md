---
layout: default
title: "Hibernate - Relationships and Fetching"
parent: "Hibernate"
grand_parent: "Interview Mastery"
nav_order: 4
permalink: /interview/hibernate/relationships-and-fetching/
topic: Hibernate
subtopic: Relationships and Fetching
keywords:
  - Entity Relationships
  - LAZY vs EAGER Fetching
  - N+1 Select Problem
  - CascadeType and Orphan Removal
  - EntityGraph and Fetch Profiles
difficulty_range: medium to hard
status: complete
version: 3
---

**Keywords covered in this file:**

- [Entity Relationships](#entity-relationships)
- [LAZY vs EAGER Fetching](#lazy-vs-eager-fetching)
- [N+1 Select Problem](#n1-select-problem)
- [CascadeType and Orphan Removal](#cascadetype-and-orphan-removal)
- [EntityGraph and Fetch Profiles](#entitygraph-and-fetch-profiles)

# Entity Relationships

**TL;DR** - JPA relationship annotations (`@OneToMany`, `@ManyToOne`, `@ManyToMany`, `@OneToOne`) map Java object references to database foreign keys, with the "owning side" (the side with the FK column) controlling database writes and the "inverse side" using `mappedBy` for bidirectional navigation.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Navigating relationships requires manual JOIN queries for every access. Loading a User's Orders means writing SQL, mapping results, and maintaining the association manually. Object graphs and relational tables have fundamentally different structures (object-relational impedance mismatch).

**THE BREAKING POINT:**
A User has Orders, each Order has Items, each Item references a Product. Building this object graph from SQL requires 4 queries with manual mapping. Changes to any relationship require updating multiple queries.

**THE INVENTION MOMENT:**
"What if the ORM could map Java references to foreign keys and navigate relationships automatically?"

---

### 📘 Textbook Definition

JPA relationship annotations define how entities reference each other and how those references map to database foreign key columns. `@ManyToOne` maps the FK side (many orders -> one user). `@OneToMany` maps the inverse side (one user -> many orders). `@ManyToMany` uses a join table. `@OneToOne` shares a PK or uses a FK. In bidirectional relationships, the owning side (without `mappedBy`) controls the FK. The inverse side (with `mappedBy`) is read-only for relationship updates.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
`@ManyToOne` is the foreign key side; `@OneToMany(mappedBy = ...)` is the read-only navigation side.

**One analogy:**

> A parent-child relationship in a family registry. The child's birth certificate (owning side, `@ManyToOne`) records the parent's ID (FK). The parent's family record (`@OneToMany mappedBy`) lists all children but does not control the relationship - updating the parent's list without updating the child's certificate does nothing in the registry (database).

**One insight:**
The single most common Hibernate relationship bug: adding to the `@OneToMany` collection without setting the `@ManyToOne` back-reference. Only the owning side (`@ManyToOne`) writes to the database. The inverse side (`@OneToMany`) is for navigation only.

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**

1. **Owning side controls the FK:** Only changes to the owning side (`@ManyToOne`, or `@ManyToMany` without `mappedBy`) are persisted to the database.
2. **mappedBy = read-only:** The inverse side declares `mappedBy` and does not write FK values. Adding to the inverse collection without setting the owning side does nothing in the DB.
3. **Bidirectional = two separate mappings:** In Java, both sides must be synchronized manually. Hibernate does not auto-sync.

**THE TRADE-OFFS:**

**Gain:** Navigate object graphs (`user.getOrders()`) without writing JOINs.

**Cost:** Understanding owning vs inverse side. Synchronization bugs. Performance traps (lazy loading, N+1).

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is:**
Annotations that let you navigate between related entities (User -> Orders) without writing SQL JOINs.

**Level 2 - How to use it (junior):**

```java
// Bidirectional @ManyToOne/@OneToMany
@Entity
public class Order {
    @ManyToOne(fetch = LAZY)
    @JoinColumn(name = "user_id")
    private User user; // OWNING SIDE (FK)
}

@Entity
public class User {
    @OneToMany(mappedBy = "user")
    private List<Order> orders;
    // INVERSE SIDE (read-only)
}
```

```java
// @ManyToMany with join table
@Entity
public class Student {
    @ManyToMany
    @JoinTable(
        name = "student_course",
        joinColumns = @JoinColumn(
            name = "student_id"),
        inverseJoinColumns = @JoinColumn(
            name = "course_id"))
    private Set<Course> courses;
}

@Entity
public class Course {
    @ManyToMany(mappedBy = "courses")
    private Set<Student> students;
}
```

**Level 3 - How it works (mid-level):**

Owning side determines what SQL is generated:

```java
// WRONG - only updates inverse side
user.getOrders().add(newOrder);
// Nothing written to DB!
// user.orders is mappedBy (read-only)

// RIGHT - update owning side
newOrder.setUser(user);
em.persist(newOrder);
// INSERT order (user_id = ?) -> DB
```

Convenience method for bidirectional sync:

```java
@Entity
public class User {
    @OneToMany(mappedBy = "user")
    private List<Order> orders =
        new ArrayList<>();

    public void addOrder(Order order) {
        orders.add(order);    // Java side
        order.setUser(this);  // DB side
    }

    public void removeOrder(Order order) {
        orders.remove(order);
        order.setUser(null);
    }
}
```

**Level 4 - Mastery (senior/staff+):**

@OneToOne strategies:

| Strategy  | Mechanism              | Lazy?             |
| --------- | ---------------------- | ----------------- |
| Shared PK | Child PK = Parent PK   | Yes (bytecode)    |
| FK column | Child has FK to Parent | Yes (owning side) |
| @MapsId   | Child PK = Parent FK   | Yes               |

```java
// @MapsId - best practice
@Entity
public class UserProfile {
    @Id
    private Long id; // Same as user.id

    @OneToOne
    @MapsId
    @JoinColumn(name = "id")
    private User user;
}
```

@ManyToMany - prefer join entity:

```java
// BAD - @ManyToMany (no extra columns)
@ManyToMany
Set<Course> courses;

// GOOD - explicit join entity
// (allows extra columns like grade)
@Entity
public class Enrollment {
    @ManyToOne
    private Student student;
    @ManyToOne
    private Course course;
    private String grade;
    private LocalDate enrollDate;
}
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `@OneToMany` and `@ManyToOne` for relationships."

**A Staff says:** "I always make `@ManyToOne` the owning side. I use convenience methods (`addOrder/removeOrder`) for bidirectional sync. I replace `@ManyToMany` with an explicit join entity when extra columns are needed. I default to LAZY fetch and use JOIN FETCH or `@EntityGraph` for specific queries. I use `@MapsId` for `@OneToOne` to share the primary key."

---

### 💻 Code Example

**BAD missing owning side vs GOOD bidirectional sync:**

```java
// BAD - only updating inverse side
@Transactional
public void addOrder(Long userId,
        Order order) {
    User user = userRepo.findById(userId)
        .orElseThrow();
    user.getOrders().add(order);
    // order.user is still null!
    // FK column NOT set in DB!
}

// GOOD - sync both sides
@Transactional
public void addOrder(Long userId,
        Order order) {
    User user = userRepo.findById(userId)
        .orElseThrow();
    user.addOrder(order); // Sets both sides
    orderRepo.save(order);
}
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Annotations mapping Java object references to database foreign keys.

**KEY INSIGHT:** Owning side (no mappedBy) controls DB writes. Inverse side is read-only navigation.

**ANTI-PATTERN:** Adding to @OneToMany without setting @ManyToOne. @ManyToMany without join entity.

**ONE-LINER:** "ManyToOne owns the FK. OneToMany(mappedBy) is read-only navigation."

**If you remember only 3 things:**

1. @ManyToOne is the owning side (writes FK to DB)
2. Always sync both sides in bidirectional relationships
3. Replace @ManyToMany with join entity for extra columns

---

### ⚠️ Common Misconceptions

| #   | Misconception                                       | Reality                                                                              |
| --- | --------------------------------------------------- | ------------------------------------------------------------------------------------ |
| 1   | "Adding to @OneToMany list persists the FK"         | No. Only the owning side (@ManyToOne) writes the FK.                                 |
| 2   | "@ManyToMany is the best way to model many-to-many" | Use explicit join entity when you need extra columns.                                |
| 3   | "Bidirectional relationships sync automatically"    | No. You must set BOTH sides in Java code.                                            |
| 4   | "@OneToOne is always lazy-loadable"                 | Inverse @OneToOne is EAGER by default (Hibernate cannot know if null without query). |

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: What is the difference between @ManyToOne and @OneToMany?**

_Why they ask:_ Foundation relationship knowledge.
_Likely follow-up:_ "Which side owns the relationship?"

**Answer:**
`@ManyToOne` maps the foreign key side. Many orders belong to one user. The FK column (`user_id`) is in the orders table. This is the owning side - changes here write to the database.

`@OneToMany(mappedBy = "user")` is the inverse side. One user has many orders. This is read-only navigation - adding to this collection does NOT set the FK in the database.

Always set the `@ManyToOne` side when creating relationships:

```java
order.setUser(user); // Sets FK in DB
```

_What separates good from great:_ Explaining owning vs inverse and that only owning side writes to DB.

---

**Q2 [MID - DEBUGGING]: Orders are saved but user_id is NULL. Why?**

_Why they ask:_ Most common relationship bug.
_Likely follow-up:_ "How do you prevent this?"

**Answer:**
The developer added the order to the `@OneToMany` list but did not set the `@ManyToOne` back-reference:

```java
// Bug: only inverse side updated
user.getOrders().add(order);
// order.user is still null -> FK is NULL

// Fix: set owning side
order.setUser(user);
user.getOrders().add(order);
```

Prevention: always use convenience methods that synchronize both sides:

```java
user.addOrder(order); // Sets both
```

_What separates good from great:_ The convenience method pattern for prevention.

---

### 🔗 Related Keywords

**Prerequisites:** Entity Mapping, Foreign Keys

**Builds on:** LAZY vs EAGER, N+1 Problem, CascadeType

**Alternatives:** JOOQ (manual JOINs, no entity relationships)

---

---

# LAZY vs EAGER Fetching

**TL;DR** - LAZY fetching loads associations only when first accessed (on-demand), while EAGER fetching loads them immediately with the parent entity - LAZY is the correct default because EAGER loads data you may never use and causes the "EAGER everywhere" performance death spiral.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Every entity load fetches ALL related entities recursively. Loading a User loads their Orders, each Order loads its Items, each Item loads its Product. A simple `findById(1)` generates 50 JOINs and returns 10MB of data.

**THE INVENTION MOMENT:**
"Load data only when it is actually needed."

---

### 📘 Textbook Definition

Fetch type controls when associated entities are loaded from the database. `FetchType.LAZY` creates a proxy/wrapper that loads the association only when a non-ID getter is called. `FetchType.EAGER` loads the association immediately with the owning entity via JOIN or subsequent SELECT. JPA defaults: `@ManyToOne`/`@OneToOne` default to EAGER. `@OneToMany`/`@ManyToMany` default to LAZY. Best practice: override ALL to LAZY and use JOIN FETCH or `@EntityGraph` for specific queries.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
LAZY = load when accessed (good default). EAGER = load immediately (almost always wrong).

**One analogy:**

> Streaming vs downloading. LAZY is like streaming a movie - you load each scene when you watch it. EAGER is like downloading the entire movie catalog before watching one movie. LAZY saves bandwidth (queries); EAGER wastes it.

**One insight:**
JPA's default fetch types are wrong for production: `@ManyToOne` and `@OneToOne` default to EAGER. Override them to LAZY. Then use JOIN FETCH or `@EntityGraph` when you actually need the association.

---

### 📶 Gradual Depth - Five Levels

**Level 2 - How to use (junior):**

```java
// Override defaults to LAZY
@Entity
public class Order {
    @ManyToOne(fetch = LAZY) // Override!
    private User user;

    @OneToMany(mappedBy = "order",
        fetch = LAZY)
    private List<OrderItem> items;
}

// Load association when needed:
// Option 1: JOIN FETCH in query
@Query("SELECT o FROM Order o "
    + "JOIN FETCH o.user "
    + "WHERE o.id = :id")
Order findWithUser(@Param("id") Long id);

// Option 2: @EntityGraph
@EntityGraph(attributePaths = {"user"})
Optional<Order> findById(Long id);
```

**Level 3 - How it works (mid-level):**

LAZY proxy mechanism:

```
  em.find(Order.class, 1)
       |
  SELECT from orders WHERE id=1
  order.user = HibernateProxy (not loaded)
       |
  order.getUser().getName() <- access!
       |
  Proxy detects first access
  -> SELECT from users WHERE id=?
  -> Replaces proxy with real User
       |
  But if session is closed:
  -> LazyInitializationException!
```

JPA fetch type defaults:

| Annotation  | Default FetchType |
| ----------- | ----------------- |
| @ManyToOne  | EAGER (override!) |
| @OneToOne   | EAGER (override!) |
| @OneToMany  | LAZY (correct)    |
| @ManyToMany | LAZY (correct)    |

**Level 4 - Mastery (senior/staff+):**

Why EAGER is almost always wrong:

```
  @ManyToOne(fetch = EAGER)
  private User user;

  Every query that returns Order
  ALWAYS loads User too.
  Even: SELECT o FROM Order o

  With EAGER, you cannot opt-out.
  With LAZY, you can opt-in per query.

  EAGER + EAGER + EAGER
  = loading the entire database
    for a single entity
```

LAZY for @OneToOne (tricky):

```java
// LAZY @OneToOne on inverse side
// does not work by default!
// Hibernate cannot know if the
// related entity exists without
// querying - so it eagerly loads.

// Fix: use @MapsId (shared PK)
@Entity
public class UserProfile {
    @Id
    private Long id;

    @OneToOne(fetch = LAZY)
    @MapsId
    private User user;
}
// Now Hibernate knows profile exists
// if user.id exists -> can proxy
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use LAZY to avoid loading unnecessary data."

**A Staff says:** "I set ALL relationships to LAZY and use query-level fetch strategies (JOIN FETCH, @EntityGraph) for each use case. I never use EAGER because it cannot be overridden per query. For @OneToOne inverse, I use @MapsId to enable LAZY. I design my queries around fetch plans, not my entity annotations."

---

### 💻 Code Example

**BAD EAGER everywhere vs GOOD LAZY + targeted fetch:**

```java
// BAD - EAGER on everything
@Entity
public class Order {
    @ManyToOne(fetch = EAGER)
    private User user;
    @OneToMany(fetch = EAGER)
    private List<OrderItem> items;
    @ManyToOne(fetch = EAGER)
    private Address shipAddress;
}
// findById(1) loads User + Items
// + Address even if not needed
// Every query that returns Order
// loads ALL associations

// GOOD - LAZY + query-level fetch
@Entity
public class Order {
    @ManyToOne(fetch = LAZY)
    private User user;
    @OneToMany(fetch = LAZY)
    private List<OrderItem> items;
    @ManyToOne(fetch = LAZY)
    private Address shipAddress;
}
// Load what you need per query:
@EntityGraph(attributePaths =
    {"user", "items"})
Optional<Order> findById(Long id);
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Control over when associated entities are loaded from the database.

**KEY INSIGHT:** LAZY = opt-in per query. EAGER = cannot opt-out. LAZY always wins.

**ANTI-PATTERN:** Keeping default EAGER on @ManyToOne/@OneToOne. EAGER "just in case."

**ONE-LINER:** "Default everything to LAZY. JOIN FETCH or @EntityGraph per query."

**If you remember only 3 things:**

1. Set ALL relationships to LAZY (override @ManyToOne/@OneToOne defaults)
2. Use JOIN FETCH or @EntityGraph when you need the association
3. EAGER cannot be overridden per query - LAZY can always be upgraded

---

### 🎯 Interview Deep-Dive

**Q1 [JUNIOR]: What is the difference between LAZY and EAGER fetching?**

_Why they ask:_ Core ORM knowledge.
_Likely follow-up:_ "What are the defaults?"

**Answer:**
LAZY: association is not loaded until you access it. A proxy is created. On first non-ID field access, a SELECT is fired.

EAGER: association is loaded immediately with the parent entity (via JOIN or subselect).

Default: @ManyToOne and @OneToOne are EAGER (should override to LAZY). @OneToMany and @ManyToMany are LAZY.

Best practice: set everything to LAZY. Use JOIN FETCH or @EntityGraph when you need data.

_What separates good from great:_ Knowing the defaults are wrong and should be overridden.

---

**Q2 [MID]: LazyInitializationException - causes and solutions?**

_Why they ask:_ Most common Hibernate error.
_Likely follow-up:_ "Is open-in-view a good solution?"

**Answer:**
Cause: accessing a LAZY association after the persistence context is closed (transaction ended).

Solutions (good to bad):

1. **JOIN FETCH** in query (best - one query, data loaded)
2. **@EntityGraph** on repository method (same effect, declarative)
3. **@Transactional on service** (keeps context open for service method)
4. **spring.jpa.open-in-view=true** (default, BAD - keeps session open for entire request, hides N+1)

Always use option 1 or 2. Never rely on open-in-view in production.

_What separates good from great:_ Ranking solutions and explaining why open-in-view is an anti-pattern.

---

### 🔗 Related Keywords

**Prerequisites:** Entity Relationships, Persistence Context

**Builds on:** N+1 Problem, EntityGraph

**Related:** Proxy pattern, Bytecode enhancement

---

---

# N+1 Select Problem

**TL;DR** - The N+1 problem occurs when loading N entities triggers N additional queries for each entity's lazy association - turning a single-query operation into N+1 queries, detectable via Hibernate statistics and fixable with JOIN FETCH, @EntityGraph, or @BatchSize.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
A page showing 100 orders with user names executes 101 queries: 1 for orders + 100 for each order's user. Response time: 2 seconds. Database CPU: 80%. Nobody knows why.

**THE BREAKING POINT:**
The application loads 1000 orders with items and users. 1 + 1000 + 1000 = 2001 queries. Response time: 15 seconds. Database connection pool exhausted.

---

### 📘 Textbook Definition

The N+1 select problem is a data access anti-pattern where 1 query loads N parent entities, and then N additional queries are executed to load a lazy association for each parent. This occurs when code iterates over a collection of entities and accesses a lazy-loaded relationship on each one. The fix is to load the association in the original query using JOIN FETCH, `@EntityGraph`, or `@BatchSize`.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
1 query loads 100 orders; accessing `order.getUser()` on each triggers 100 more queries = 101 total.

**One analogy:**

> Ordering food for a table of 10 people by making 10 separate trips to the kitchen (N+1) vs one trip with all 10 orders (JOIN FETCH). Same food, 10x fewer trips.

**One insight:**
N+1 is invisible in unit tests (1-2 entities) and only manifests in production with real data volumes. Always enable Hibernate statistics in dev/staging and assert query counts in tests.

---

### 📶 Gradual Depth - Five Levels

**Level 2 - How to identify (junior):**

Enable Hibernate statistics:

```yaml
spring:
  jpa:
    properties:
      hibernate:
        generate_statistics: true
logging:
  level:
    org.hibernate.stat: DEBUG
    org.hibernate.SQL: DEBUG
```

Output:

```
  SQL: SELECT * FROM orders
  SQL: SELECT * FROM users WHERE id=1
  SQL: SELECT * FROM users WHERE id=2
  ... (98 more)
  Session Metrics:
    queries executed: 101  <- N+1!
```

**Level 3 - How to fix (mid-level):**

Fix 1 - JOIN FETCH:

```java
@Query("SELECT o FROM Order o "
    + "JOIN FETCH o.user")
List<Order> findAllWithUser();
// 1 query with JOIN instead of 101
```

Fix 2 - @EntityGraph:

```java
@EntityGraph(attributePaths = {"user"})
List<Order> findAll();
// Same effect, declarative
```

Fix 3 - @BatchSize (Hibernate):

```java
@Entity
public class Order {
    @ManyToOne(fetch = LAZY)
    @BatchSize(size = 50)
    private User user;
}
// Instead of 100 individual queries:
// SELECT * FROM users
//   WHERE id IN (1,2,3,...,50)
// SELECT * FROM users
//   WHERE id IN (51,52,...,100)
// 2 queries instead of 100
```

Fix 4 - Subselect fetch (Hibernate):

```java
@OneToMany(mappedBy = "order")
@Fetch(FetchMode.SUBSELECT)
private List<OrderItem> items;
// SELECT * FROM items WHERE order_id
//   IN (SELECT id FROM orders
//        WHERE ...)
// 1 subselect query for ALL items
```

**Level 4 - Mastery (senior/staff+):**

Detecting N+1 in tests:

```java
@DataJpaTest
class OrderRepositoryTest {
    @Autowired EntityManager em;

    @Test
    void noNPlusOne() {
        Statistics stats = em.unwrap(
            Session.class)
            .getSessionFactory()
            .getStatistics();
        stats.setStatisticsEnabled(true);
        stats.clear();

        List<Order> orders =
            repo.findAllWithUser();
        orders.forEach(o ->
            o.getUser().getName());

        assertThat(
            stats.getPrepareStatementCount())
            .isLessThanOrEqualTo(1);
    }
}
```

MultipleBagFetchException:

```java
// ERROR: cannot JOIN FETCH two Lists
@Query("SELECT o FROM Order o "
    + "JOIN FETCH o.items "      // List
    + "JOIN FETCH o.payments")   // List
// MultipleBagFetchException!

// Fix 1: Use Set instead of List
@OneToMany
private Set<OrderItem> items;
@OneToMany
private Set<Payment> payments;

// Fix 2: Two separate queries
@EntityGraph(attributePaths = {"items"})
List<Order> findAllWithItems();
// Then batch-fetch payments separately
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use JOIN FETCH to fix N+1."

**A Staff says:** "I detect N+1 using Hibernate statistics and query count assertions in tests. I choose between JOIN FETCH (best for @ManyToOne), @BatchSize (best for collections with known size), and SUBSELECT (best for 'load all' scenarios). I handle MultipleBagFetchException by using Sets or splitting into multiple queries. I monitor query counts in production via Micrometer."

---

### 💻 Code Example

**BAD N+1 vs GOOD JOIN FETCH:**

```java
// BAD - N+1 queries
List<Order> orders = repo.findAll();
for (Order o : orders) {
    log.info("User: {}",
        o.getUser().getName());
    // Each call triggers a SELECT!
}
// 1 + N queries

// GOOD - single query
List<Order> orders =
    repo.findAllWithUser();
for (Order o : orders) {
    log.info("User: {}",
        o.getUser().getName());
    // Already loaded via JOIN FETCH
}
// 1 query total
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** 1 query for N parents + N queries for each parent's association = N+1 total.

**KEY INSIGHT:** Invisible in unit tests, catastrophic in production. Test with query count assertions.

**ANTI-PATTERN:** Accessing lazy associations in a loop. EAGER fetch as "fix" (worse).

**ONE-LINER:** "1 + N queries. Fix: JOIN FETCH, @EntityGraph, or @BatchSize."

**If you remember only 3 things:**

1. N+1 = 1 parent query + N association queries (each loop iteration)
2. Fix: JOIN FETCH (single JOIN), @BatchSize (batched IN clause), or @EntityGraph
3. Detect: Hibernate statistics + query count assertions in tests

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Slow endpoint with excessive queries**

**Symptom:** 200ms endpoint becomes 5000ms under load.

**Root Cause:** N+1 queries for lazy associations accessed in a loop.

**Diagnostic:**

```yaml
hibernate.generate_statistics: true
```

```
Session Metrics:
  queries executed: 1001
  -> N+1 detected
```

**Fix:** Add `JOIN FETCH` to the repository query.

**Failure Mode 2: MultipleBagFetchException**

**Symptom:** `MultipleBagFetchException: cannot simultaneously fetch multiple bags`

**Root Cause:** Two `@OneToMany List<>` associations in the same JOIN FETCH.

**Fix:** Change `List` to `Set`, or split into separate queries.

**Failure Mode 3: Cartesian product explosion**

**Symptom:** Query returns 10K rows for 100 orders x 100 items.

**Root Cause:** JOIN FETCH on `@OneToMany` creates a Cartesian product (N x M rows).

**Fix:** Use `DISTINCT` in JPQL: `SELECT DISTINCT o FROM Order o JOIN FETCH o.items`. Or use `@BatchSize` instead.

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: What is the N+1 problem and how do you fix it?**

_Why they ask:_ #1 JPA performance issue.
_Likely follow-up:_ "How do you detect it?"

**Answer:**
Loading N entities with a lazy association, then accessing that association on each, triggers N additional queries.

Example: `findAll()` returns 100 orders (1 query). Calling `order.getUser()` on each triggers 100 user queries = 101 total.

Fixes:

1. **JOIN FETCH:** `SELECT o FROM Order o JOIN FETCH o.user` - 1 query with JOIN
2. **@EntityGraph:** Declarative on repository method
3. **@BatchSize(size=50):** Batches lazy loads into IN clauses (2 queries for 100 entities)

Detection: enable `hibernate.generate_statistics=true`, check query count, assert in tests.

_What separates good from great:_ Three fix strategies with trade-offs and detection via statistics.

---

### 🔗 Related Keywords

**Prerequisites:** LAZY vs EAGER, Entity Relationships

**Builds on:** EntityGraph, Caching

**Related:** @BatchSize, @Fetch(SUBSELECT)

---

---

# CascadeType and Orphan Removal

**TL;DR** - `CascadeType` propagates EntityManager operations (persist, merge, remove) from parent to child entities automatically, while `orphanRemoval = true` deletes child entities when they are removed from the parent's collection - modeling parent-child aggregate ownership.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Saving an Order with 10 Items requires 11 persist calls: 1 for the order + 10 for items. Deleting the order requires 11 remove calls. Forgetting one item leaves orphaned rows in the database.

---

### 📘 Textbook Definition

`CascadeType` is a JPA attribute that propagates lifecycle operations from the parent entity to associated child entities. `CascadeType.PERSIST` cascades `persist()`, `MERGE` cascades `merge()`, `REMOVE` cascades `remove()`, `ALL` cascades everything. `orphanRemoval = true` (on `@OneToMany`/`@OneToOne`) automatically removes child entities from the database when they are removed from the parent's collection, even without calling `remove()`.

---

### ⏱️ Understand It in 30 Seconds

**One line:**
Cascade means "when I persist/remove the parent, also persist/remove the children." Orphan removal means "when I remove a child from the collection, delete it from the database."

**One insight:**
`CascadeType.REMOVE` and `orphanRemoval` are different. REMOVE only triggers when the parent is deleted. OrphanRemoval triggers when a child is removed from the collection (even if the parent is not deleted). OrphanRemoval implies REMOVE but is more aggressive.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
@Entity
public class Order {
    @OneToMany(mappedBy = "order",
        cascade = CascadeType.ALL,
        orphanRemoval = true)
    private List<OrderItem> items =
        new ArrayList<>();
}

// Persist cascades: save order + items
Order order = new Order();
order.addItem(new OrderItem("Widget"));
order.addItem(new OrderItem("Gadget"));
em.persist(order);
// 1 persist call -> 3 INSERTs

// Orphan removal: remove item from list
order.getItems().remove(0);
// DELETE from order_items WHERE id=?
// Automatic! No em.remove() needed.

// Remove cascades: delete order + items
em.remove(order);
// DELETE items, DELETE order
```

**Level 3 - When to use each (mid-level):**

| CascadeType | Propagates       | Use When                |
| ----------- | ---------------- | ----------------------- |
| PERSIST     | em.persist()     | Parent creates children |
| MERGE       | em.merge()       | Parent updates children |
| REMOVE      | em.remove()      | Parent deletes children |
| REFRESH     | em.refresh()     | Rarely needed           |
| DETACH      | em.detach()      | Rarely needed           |
| ALL         | All of the above | Strong ownership        |

**Level 4 - Mastery (senior/staff+):**

Cascade REMOVE danger:

```java
// DANGEROUS on @ManyToMany
@ManyToMany(cascade = CascadeType.ALL)
private Set<Tag> tags;
// Deleting a Post deletes its Tags
// But other Posts reference those Tags!
// -> ConstraintViolationException

// SAFE: cascade only for @OneToMany
// where parent truly owns children
@OneToMany(cascade = ALL,
    orphanRemoval = true)
private List<OrderItem> items;
// Items belong ONLY to this Order
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use `CascadeType.ALL` for convenience."

**A Staff says:** "I use `CascadeType.ALL` + `orphanRemoval = true` only for true parent-child aggregates (Order -> OrderItem). Never cascade REMOVE on `@ManyToOne` or `@ManyToMany` (shared references). For non-owned associations, I use PERSIST + MERGE only (no REMOVE)."

---

### 💻 Code Example

**BAD cascade on shared entity vs GOOD cascade on owned:**

```java
// BAD - cascade ALL on shared reference
@ManyToMany(cascade = CascadeType.ALL)
private Set<Category> categories;
// Deleting Product deletes Categories
// that other Products reference!

// GOOD - no cascade on shared reference
@ManyToMany
private Set<Category> categories;
// Categories managed independently

// GOOD - cascade ALL on owned children
@OneToMany(mappedBy = "order",
    cascade = CascadeType.ALL,
    orphanRemoval = true)
private List<OrderItem> items;
// Items BELONG to this Order only
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Automatic propagation of EntityManager operations from parent to child.

**KEY INSIGHT:** CascadeType.ALL + orphanRemoval only for true parent-child ownership.

**ANTI-PATTERN:** CASCADE REMOVE on @ManyToMany or @ManyToOne (deletes shared entities).

**ONE-LINER:** "Cascade = parent operation propagates. OrphanRemoval = collection removal deletes."

**If you remember only 3 things:**

1. CASCADE ALL + orphanRemoval for owned children (Order -> Items)
2. NEVER cascade REMOVE on shared associations (@ManyToMany, @ManyToOne)
3. OrphanRemoval deletes when removed from collection; REMOVE only when parent deleted

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: CascadeType.REMOVE vs orphanRemoval - what is the difference?**

_Why they ask:_ Subtle but important distinction.
_Likely follow-up:_ "When is orphanRemoval dangerous?"

**Answer:**
`CascadeType.REMOVE`: When the parent entity is deleted (`em.remove(parent)`), children are also deleted. Only triggered by parent deletion.

`orphanRemoval = true`: When a child is removed from the parent's collection (`parent.getChildren().remove(child)`), the child is deleted from the database. Triggered by collection modification, not just parent deletion. OrphanRemoval implies CascadeType.REMOVE.

Example: `order.getItems().clear()` with orphanRemoval deletes ALL items from DB. Without orphanRemoval, items become orphaned rows.

Use orphanRemoval for true aggregates where children cannot exist without the parent.

_What separates good from great:_ The collection.remove() vs em.remove() distinction.

---

### 🔗 Related Keywords

**Prerequisites:** Entity Relationships, Entity Lifecycle

**Builds on:** Aggregate pattern (DDD)

**Related:** @OnDelete (database-level cascade)

---

---

# EntityGraph and Fetch Profiles

**TL;DR** - `@EntityGraph` defines which associations to eagerly fetch for a specific query, overriding the entity's default fetch type - giving you per-query control over what is loaded, solving N+1 without hardcoding fetch strategy in entity annotations.

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
EAGER fetching loads associations for every query (wasteful). LAZY fetching requires JOIN FETCH in JPQL (verbose, not reusable). You need different fetch plans for different use cases: list view (user only), detail view (user + orders + items).

**THE INVENTION MOMENT:**
"What if you could define fetch plans per query, not per entity?"

---

### 📘 Textbook Definition

`@EntityGraph` (JPA 2.1) is a declarative way to specify which associations should be eagerly fetched for a specific repository method or query. It creates a fetch plan that overrides the entity's default fetch types. `attributePaths` lists the associations to fetch. `@NamedEntityGraph` defines reusable graphs on the entity class. Spring Data JPA supports `@EntityGraph` directly on repository methods.

---

### 📶 Gradual Depth

**Level 2 - How to use (junior):**

```java
// Ad-hoc EntityGraph on repository
public interface OrderRepository
        extends JpaRepository<Order, Long> {

    // List view: load user only
    @EntityGraph(attributePaths = {"user"})
    List<Order> findByStatus(String status);

    // Detail view: load user + items
    @EntityGraph(attributePaths =
        {"user", "items"})
    Optional<Order> findById(Long id);

    // No graph: lazy (default)
    List<Order> findByDateBetween(
        LocalDate from, LocalDate to);
}
```

**Level 3 - Named entity graphs (mid-level):**

```java
@Entity
@NamedEntityGraph(
    name = "Order.detail",
    attributeNodes = {
        @NamedAttributeNode("user"),
        @NamedAttributeNode(
            value = "items",
            subgraph = "items.product")
    },
    subgraphs = {
        @NamedSubgraph(
            name = "items.product",
            attributeNodes =
                @NamedAttributeNode(
                    "product"))
    })
public class Order { }

// Usage:
@EntityGraph("Order.detail")
Optional<Order> findById(Long id);
// Loads: Order -> User
//        Order -> Items -> Product
```

**Level 4 - Mastery (senior/staff+):**

EntityGraph vs JOIN FETCH:

| Feature             | @EntityGraph       | JOIN FETCH         |
| ------------------- | ------------------ | ------------------ |
| Defined on          | Repository method  | JPQL query         |
| Reusable            | Yes (named graphs) | Copy JPQL          |
| Subgraphs           | Yes (nested)       | Yes (nested FETCH) |
| Collection + paging | Works correctly    | Paging in memory!  |
| SQL generated       | LEFT JOIN          | INNER/LEFT JOIN    |

Pagination pitfall with JOIN FETCH:

```java
// BAD - pagination in memory!
@Query("SELECT o FROM Order o "
    + "JOIN FETCH o.items")
Page<Order> findAll(Pageable pageable);
// Hibernate: HHH90003004:
// firstResult/maxResults specified
// with collection fetch; applying
// in memory!
// Loads ALL rows, pages in Java!

// GOOD - use @EntityGraph for paging
@EntityGraph(attributePaths = {"items"})
Page<Order> findByStatus(
    String status, Pageable pageable);
// Correct SQL-level pagination
```

**The Senior-to-Staff Leap:**

**A Senior says:** "Use JOIN FETCH for associations."

**A Staff says:** "I use `@EntityGraph` for Spring Data repository methods (cleaner, paging-safe) and JOIN FETCH only for custom JPQL queries. I define `@NamedEntityGraph` for reusable fetch plans across multiple queries. I never use JOIN FETCH with Spring Data pagination (it pages in memory)."

---

### 💻 Code Example

**BAD JOIN FETCH with paging vs GOOD @EntityGraph:**

```java
// BAD - pages in memory
@Query("SELECT o FROM Order o "
    + "JOIN FETCH o.items")
Page<Order> findAll(Pageable p);
// WARNING: all rows fetched,
// paging applied in Java!

// GOOD - SQL-level paging
@EntityGraph(attributePaths = {"items"})
Page<Order> findByStatus(
    String status, Pageable p);
// Correct LIMIT/OFFSET in SQL
```

---

### 📌 Quick Reference Card

**WHAT IT IS:** Per-query fetch plan overriding entity default fetch types.

**KEY INSIGHT:** @EntityGraph works with pagination. JOIN FETCH + Page = pages in memory.

**ANTI-PATTERN:** JOIN FETCH with Spring Data Page (loads all rows).

**ONE-LINER:** "@EntityGraph = declarative, per-query, pagination-safe fetch plan."

**If you remember only 3 things:**

1. @EntityGraph overrides LAZY with EAGER per query (not globally)
2. Use @EntityGraph (not JOIN FETCH) with Spring Data pagination
3. @NamedEntityGraph for reusable fetch plans

---

### 🎯 Interview Deep-Dive

**Q1 [MID]: @EntityGraph vs JOIN FETCH - when to use each?**

_Why they ask:_ Practical query optimization.
_Likely follow-up:_ "What about pagination?"

**Answer:**
Use `@EntityGraph` for Spring Data repository methods - it is declarative, reusable, and works correctly with pagination.

Use JOIN FETCH for custom JPQL queries in `@Query` where you need full SQL control.

Critical difference with pagination: JOIN FETCH + `Page` loads ALL rows and pages in Java memory (Hibernate logs a warning). `@EntityGraph` generates proper SQL LIMIT/OFFSET.

For complex graphs (Order -> Items -> Product), use `@NamedEntityGraph` with subgraphs.

_What separates good from great:_ The pagination in-memory warning with JOIN FETCH.

---

### 🔗 Related Keywords

**Prerequisites:** LAZY vs EAGER, N+1 Problem

**Builds on:** Spring Data JPA, Query Optimization

**Related:** Hibernate @FetchProfile, @Fetch(FetchMode)
