# JPA Anti-Pattern Catalog

**Interview Weight:** medium - Anti-pattern recognition
is a senior marker. Interviewers expect candidates
to recognize and articulate what's wrong with common
JPA misuse patterns.

---

### 🎯 Model Answer

**30 seconds:**

> The most common JPA anti-patterns: N+1 selects (loading
> associations in loops), EAGER fetch on collections
> (loads data you may not need), anemic domain model
> (all logic in services, entities are data bags),
> entity as API response (exposes internals, prevents
> evolution), Open Session in View (DB connection held
> too long), missing transaction boundaries (lazy loading
> outside transaction), and large persistence context
> (batch without flush+clear).

**3 minutes (Senior):**

> The JPA Anti-Pattern Catalog:
>
> AP1: N+1 Selects
>   Problem: lazy collection loaded inside loop
>   Detection: query count equals entity count
>   Fix: JOIN FETCH, @EntityGraph, @BatchSize
>
> AP2: Premature EAGER
>   Problem: @OneToMany(fetch=EAGER) causes JOIN
>   on every entity load, even when not needed
>   Detection: slow single findById() queries
>   Fix: keep LAZY, add JOIN FETCH per use case
>
> AP3: Anemic Domain Model
>   Problem: entities are data holders, no behavior;
>   all logic in @Service classes
>   Detection: entities have only getters/setters,
>   services have all business rules
>   Fix: move invariant-enforcing logic to entities
>
> AP4: Entity as API Response
>   Problem: @RestController returns @Entity directly;
>   Jackson serializes all fields including lazy
>   associations (triggers N+1 during serialization)
>   Detection: Jackson triggering lazy loads (LazyInitializationEx or N+1)
>   Fix: map to DTO before returning from controller
>
> AP5: Open Session in View
>   Problem: DB connection held for entire HTTP request
>   Detection: spring.jpa.open-in-view=true
>   Fix: disable OSIV, load in @Transactional service
>
> AP6: Missing Tx Boundary
>   Problem: lazy association accessed outside @Transactional
>   Detection: LazyInitializationException
>   Fix: load within transaction, or use OSIV (don't)
>
> AP7: Unbounded Batch
>   Problem: loop persisting thousands with no flush+clear
>   Detection: OutOfMemoryError, slow batch jobs
>   Fix: flush+clear every 50-100 records

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the catalog of
common JPA misuse patterns and how to recognize them."

**(2) First principles:** "Anti-patterns in JPA fall
into three categories: performance (N+1, EAGER, batch),
security (entity exposure, SQL injection), and
design (anemic model, OSIV convenience)."

**(3) Bridge:** "The JPA anti-pattern catalog is the
difference between someone who read the JPA docs and
someone who debugged production JPA issues. Each
anti-pattern has a cost: N+1 costs 100x queries; OSIV
costs connection pool exhaustion; entity as DTO costs
schema coupling."

---

### ⚖️ Comparison Table

| Anti-Pattern | Symptom | Detection | Fix |
|---|---|---|---|
| N+1 Selects | Slow page load | Query count = entity count | JOIN FETCH / @BatchSize |
| Premature EAGER | Slow findById | Extra JOINs in every query | Keep LAZY |
| Anemic Model | Logic in services only | Entities have no behavior methods | Rich entity methods |
| Entity as API Response | LazyInitEx on serialization | @Entity returned from @Controller | DTO mapping |
| Open Session in View | Connection pool exhaustion | open-in-view=true | Disable OSIV |
| Missing Tx Boundary | LazyInitializationException | Lazy access outside @Transactional | Load in transaction |
| Unbounded Batch | OutOfMemoryError | No flush+clear in loop | Periodic flush+clear |

---

### 🎓 Answers by Seniority

**Junior:** "Common JPA mistakes: N+1 (fix with JOIN
FETCH), LazyInitializationException (fix by loading
within @Transactional), and returning entities directly
to the API (fix with DTOs)."

**Senior:** "The anti-pattern I see most in codebases:
OSIV enabled + entities as API responses. They mask
N+1 (OSIV lets lazy load work in serialization) until
production load exposes the connection pool exhaustion.
Fix order: disable OSIV, add DTOs, fix resulting
LazyInitializationExceptions with JOIN FETCH."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Junior | 3 min | N+1, EAGER, LazyInitEx |
| Senior | 7 min | Full catalog, detection methods, OSIV+entity-response coupling |

---

**[SENIOR] Q1 - Why does OSIV + entity-as-response
mask N+1 problems until production?**

*Why they ask:* Two anti-patterns compound each other.

With OSIV (open-in-view=true) + entity as response body:

During development:
- Request comes in
- Service loads Order entities (lazy, no items loaded)
- Controller returns entities directly
- Jackson serializes: calls order.getItems() for each order
- OSIV: EntityManager still open → lazy load succeeds
- Response sent. No error. Works fine.

In development/staging with 5 orders:
- 1 query for orders + 5 queries for items = 6 queries
- Fast enough, nobody notices

In production with 500 orders:
- 1 + 500 queries per request
- Each query = 10ms
- 501 × 10ms = 5 seconds response time
- Connection pool held 5 seconds per request
- 20 connection pool × 5s = max 4 requests/second capacity
- Connection pool exhaustion

The anti-patterns reinforce each other:
- OSIV hides the LazyInitializationException that
  would reveal the problem early
- Entity-as-response causes Jackson to call all getters
  (triggering all lazy loads)
- Neither is obviously broken in development

Detection: enable Hibernate stats, check query count
per request in staging with realistic data volumes.

*What separates good from great:* The compounding
effect: two individually "working" patterns creating
a catastrophic production scenario.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Anti-pattern list, detection methods. |
| Hiring Manager | Anti-patterns compound in production. |
| Bar Raiser | OSIV + entity-as-response masking N+1, production vs dev divergence. |
| Peer Engineer | "We had OSIV + entity responses in prod for 2 years. It worked until we hit 1,000 concurrent users." |

---

---

# ORM Selection Decision Framework

**Interview Weight:** critical - Choosing between ORM
options (JPA/Hibernate, JOOQ, MyBatis, plain JDBC)
is an architectural decision. Staff interviews test
decision frameworks, not just feature knowledge.

---

### 🎯 Model Answer

**30 seconds:**

> ORM selection depends on four factors: (1) query
> complexity (complex reports → JOOQ/plain SQL;
> standard CRUD → JPA); (2) domain model richness
> (DDD with rich entities → JPA; query-centric reads →
> JOOQ); (3) team familiarity; (4) performance requirements
> (bulk operations → JDBC batch or native SQL; standard
> operations → JPA). JPA is optimal for domain-driven
> write models. JOOQ is optimal for complex query-driven
> read models. They can coexist.

**3 minutes (Senior):**

> Decision matrix:
>
> JPA/Hibernate use when:
> - Rich domain model with business behavior in entities
> - Standard CRUD operations dominate
> - Object-oriented design is the primary concern
> - Cache (L1/L2) can improve read performance
> - Schema evolution via Liquibase/Flyway + entities
>
> JPA/Hibernate avoid when:
> - Bulk operations (100K+ row updates)
> - Complex reporting queries with many aggregations
>   and multi-table joins not aligned with entity model
> - Full-text search, geospatial queries
> - High-performance read-heavy systems where
>   the ORM overhead matters
>
> JOOQ use when:
> - SQL fluency is valued over OOP
> - Complex dynamic queries are the norm
> - Type-safe SQL at compile time is required
> - Stored procedures are heavily used
>
> MyBatis use when:
> - SQL control is paramount
> - Team is SQL-first not Java-OOP-first
> - Legacy SQL must be preserved exactly
>
> Plain JDBC + Spring JdbcTemplate use when:
> - Bulk inserts/updates (no ORM overhead)
> - Stored procedure calls
> - Database-specific SQL required
>
> Combining: use JPA for write model,
>   JOOQ or projections for read model
>   (CQRS at the persistence layer)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking how to choose between
JPA and other persistence options for a given system."

**(2) First principles:** "No persistence tool is
universally best. The right tool depends on what
the code must do."

**(3) Bridge:** "ORM selection is a fit-for-purpose
decision. JPA is a rich model toolkit. JOOQ is a SQL
toolkit. A codebase can use both: JPA for the write
side, JOOQ for complex read queries."

---

### ⚖️ Comparison Table

| Factor | JPA/Hibernate | JOOQ | MyBatis | Spring JDBC |
|---|---|---|---|---|
| Domain model support | Excellent | Poor | None | None |
| SQL control | Limited (native) | Full (type-safe) | Full (XML/Annot) | Full |
| Compile-time SQL check | No | Yes | No | No |
| Bulk operation perf | Poor | Good | Good | Excellent |
| Learning curve | High | Medium | Medium | Low |
| Cache support | L1+L2 built-in | None | None | None |
| Schema migration | Entity + tool | Code + tool | SQL + tool | SQL + tool |

---

### 🎓 Answers by Seniority

**Senior:** "JPA for domain-driven write model with rich
entities. JOOQ or DTO projections for complex read queries.
These aren't mutually exclusive. Spring JdbcTemplate
for bulk operations where JPA overhead matters."

**Staff:** "I make this decision based on three questions:
(1) Is the primary concern object model or SQL model?
OOP → JPA; SQL → JOOQ. (2) Are bulk operations (>10K
rows) common? Yes → JdbcTemplate or Spring Batch.
(3) Can I afford the JPA learning curve cost? Most
teams need 6 months to stop making common JPA mistakes.
JOOQ is more intuitive for SQL-fluent teams."

---

### 🎯 Interview Deep-Dive

| Experience | Time | Depth |
|---|---|---|
| Senior | 6 min | JPA vs JOOQ, bulk operations, combining tools |
| Staff | 12 min | Full decision matrix, mixed-persistence architecture, team fit |

---

**[STAFF] Q1 - How would you design the persistence
layer of a system that needs both complex domain logic
and complex reporting?**

*Why they ask:* Mixed persistence architecture is a real
production need.

Architecture: separate persistence strategies per use case.

Write model (JPA):
- Rich @Entity aggregates (Order, Customer, Product)
- Business methods enforce invariants
- Spring Data JPA repositories for CRUD
- Transaction management with @Transactional
- JPA handles the unit-of-work pattern

Read model (JOOQ or DTO projections):
- Complex reporting queries:
  Revenue per region per month, customer cohort
  analysis, order funnel metrics
- These queries JOIN 5-10 tables, use window functions,
  GROUP BY, HAVING - poorly expressed in JPQL
- JOOQ provides type-safe SQL for these
- Or: Spring Data JPA native @Query for simpler reports

Bulk operations (Spring JdbcTemplate):
- Monthly data archival (1M rows)
- Price update for all products in category
- Statistical recalculation
- No entity loading, direct SQL

Implementation layers:
```
domain/
  Order.java          @Entity
  OrderRepository.java JpaRepository

infrastructure/
  reporting/
    RevenueReport.java JOOQ queries
  batch/
    ArchiveService.java JdbcTemplate
```

The domain layer uses JPA. Reports use JOOQ. Batch
uses JDBC. Each tool does what it's best at. One
database, multiple access strategies.

*What separates good from great:* "One database, multiple
access strategies" as the architectural principle.

**[STAFF] Q2 - When is the JPA overhead
actually a problem?**

*Why they ask:* Tests practical judgment about when JPA
is the wrong choice, not just theoretical knowledge.

JPA overhead sources:
1. Query parsing and JPQL translation on every query
   (partially mitigated by query plan cache)
2. Entity state comparison (dirty checking) per flush
3. Reflection for field access and proxy creation
4. Connection and session management overhead

When this matters:
- Batch inserts: 100K rows/second possible with
  plain JDBC; JPA batch (batch_size=50) achieves
  ~30K-50K. For 99% of use cases, this is fine.
- Extreme latency: latency-sensitive systems
  (trading, real-time gaming) where sub-millisecond
  persistence matters. Rare in enterprise software.
- Report queries returning millions of rows:
  JPA entity creation overhead per row. Use DTO
  projections or JOOQ for large result sets.

When JPA overhead does NOT matter:
- Standard web APIs (sub-second response time OK)
- Standard CRUD operations
- Read operations with L1/L2 cache hits
- Any scenario where network/I/O dominates
  (database query cost >> JPA overhead)

Practical rule: measure first. JPA overhead is rarely
the bottleneck in typical enterprise software.

*What separates good from great:* "Measure first.
JPA overhead is rarely the bottleneck in enterprise
software. Database I/O is almost always the bottleneck."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Decision factors, JPA vs JOOQ features. |
| Hiring Manager | Right tool for the job = architectural judgment. |
| Bar Raiser | Mixed-persistence architecture, JPA overhead measurement, team capability fit. |
| Peer Engineer | "We use JPA for writes and JOOQ for all reporting queries. Best of both. No regrets." |
