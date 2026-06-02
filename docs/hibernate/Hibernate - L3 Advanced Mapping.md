---
layout: default
title: "Hibernate - L3 Advanced Mapping"
parent: "Hibernate"
nav_order: 7
permalink: /hibernate/l3-advanced-mapping/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| # | Keyword | Weight |
| --- | --- | --- |
| 1 | [Inheritance Mapping Strategies](#inheritance-mapping-strategies) | high |
| 2 | [Optimistic and Pessimistic Locking](#optimistic-and-pessimistic-locking) | critical |

---

# Inheritance Mapping Strategies

**TL;DR** - Hibernate maps Java inheritance to relational tables using
three strategies: SINGLE_TABLE (one table, nullable columns), JOINED
(one table per class with JOINs), or TABLE_PER_CLASS (one table per
concrete class, no JOINs but no polymorphic queries).

---

### 🎯 Model Answer

**30 seconds:**
> Inheritance in OOP does not map directly to relational tables. Hibernate
> has three strategies. SINGLE_TABLE puts all subclass data in one table
> with a discriminator column - fastest but many nullable columns.
> JOINED gives each class its own table joined by PK - normalized but
> JOINs on every query. TABLE_PER_CLASS gives each concrete class its
> own complete table - fast reads per type but cannot query the hierarchy
> polymorphically without UNION.

**3 minutes (Senior):**
> The choice of inheritance strategy has deep performance and schema
> implications that make it one of the more consequential JPA decisions.
>
> SINGLE_TABLE is the JPA default and performs best because every query
> is against one table with no JOINs. The discriminator column identifies
> the subclass. All subclass-specific columns are nullable (no NOT NULL
> constraints). The downside: the table grows wide with many nullable
> columns as the hierarchy grows. Nullable columns reduce database
> ability to enforce constraints. This strategy works well when subclasses
> share most fields and the number of discriminator types is small (<5).
>
> JOINED normalizes the hierarchy: the base class table has base fields,
> each subclass table has only its additional fields, with the same PK
> linking them. Loading a subclass requires a JOIN between the base and
> subclass tables. Polymorphic queries (SELECT all Vehicles) require
> JOINs to all subclass tables - potentially expensive with many subclasses.
> This works well when subclasses have many unique fields and when DB
> constraints (NOT NULL) on subclass columns are important.
>
> TABLE_PER_CLASS gives each concrete class a fully denormalized table
> with ALL fields (inherited + own). No JOINs needed for per-type queries.
> But polymorphic queries require UNION ALL across all subclass tables.
> PKs must be globally unique (SEQUENCE strategy, not IDENTITY). This
> works well when subclasses are almost always queried individually by
> type, rarely polymorphically.
>
> My default: SINGLE_TABLE for 2-4 subclasses with few unique columns.
> JOINED for hierarchies where each subclass has significantly different
> fields. Avoid TABLE_PER_CLASS unless polymorphic queries are truly absent.

*Adapting up:* `@MappedSuperclass` is a fourth option: a Java superclass
that is NOT itself an entity but whose fields are inherited by subclass
entities. No inheritance at the database level - each subclass entity is
completely independent. No polymorphic queries, no shared table, but
reuses common field mappings.

*Adapting down:* "SINGLE_TABLE: one big table with a 'type' column.
JOINED: parent table + child tables linked by PK. TABLE_PER_CLASS:
separate full tables per concrete type."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about inheritance mapping - how Hibernate
maps Java class hierarchies to relational database tables."

**(2) First principles:** "From first principles, a class hierarchy in Java
is a tree of related types. A relational database has flat tables. The
mapping must choose: merge all types into one table, split by class with
JOINs, or give each concrete type its own independent table."

**(3) Bridge:** "SINGLE_TABLE is like a survey form with checkboxes for
every possible type - most fields are left blank for each respondent.
JOINED is like separate forms per department that share a common header
form. TABLE_PER_CLASS is like each department having its own completely
separate form with no shared fields."

---

### 📘 Concept Explanation

**What it is:**
JPA inheritance mapping strategies declare how a Java class hierarchy
(base class + subclasses) maps to database table(s). The three
strategies are SINGLE_TABLE, JOINED, and TABLE_PER_CLASS, configured
via `@Inheritance(strategy = ...)` on the root entity.

**The problem it solves:**
Object-oriented inheritance has no direct relational equivalent. The
mapping strategy controls the trade-off between query performance
(joins vs full table scan), schema normalization, and constraint
expressiveness.

**How it works:**

```
Java hierarchy:
  Vehicle (abstract)
    Car   (+ doors: int)
    Truck (+ payloadTons: float)
    Motorcycle (+ sidecar: boolean)

SINGLE_TABLE:
  vehicles(id, dtype, make, model,
           doors, payloadTons, sidecar)
  doors IS NULL for Truck/Motorcycle rows
  Discriminator: dtype = 'CAR'/'TRUCK'/'MOTORCYCLE'

JOINED:
  vehicles(id, make, model)    <- base
  cars(id, doors)              <- FK to vehicles.id
  trucks(id, payloadTons)      <- FK to vehicles.id
  motorcycles(id, sidecar)     <- FK to vehicles.id
  Loading Car: JOIN vehicles + cars

TABLE_PER_CLASS:
  cars(id, make, model, doors)    <- all fields
  trucks(id, make, model, payloadTons)
  motorcycles(id, make, model, sidecar)
  Polymorphic: UNION ALL cars, trucks, motorcycles
```

> **Code walkthrough:** This Inheritance Mapping Strategies example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The inheritance strategy is declared once at the root entity and
cannot be changed per subclass. All subclasses in a hierarchy use
the same strategy. Changing the strategy later requires a data
migration.

**When to use each:**
- SINGLE_TABLE: few subclasses (<5), mostly shared fields, simplicity
  priority
- JOINED: many unique fields per subclass, FK constraints needed,
  schema normalization important
- TABLE_PER_CLASS: rarely; only when polymorphic queries are absent
  and each type is always queried individually

**Alternatives:**
- `@MappedSuperclass`: no database hierarchy, just shared Java field
  mappings. Ideal for common audit fields (createdAt, updatedAt).
- Composition over inheritance: using `@Embedded` types instead of
  entity inheritance for value objects

---

### 💻 Code Example

```java
// SINGLE_TABLE strategy (default, recommended for simple hierarchies)
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "vehicle_type",
    discriminatorType = DiscriminatorType.STRING)
@Table(name = "vehicles")
public abstract class Vehicle {
    @Id @GeneratedValue Long id;
    String make;
    String model;
    int year;
}

@Entity
@DiscriminatorValue("CAR")
public class Car extends Vehicle {
    int doors; // stored as nullable in vehicles table
}

@Entity
@DiscriminatorValue("TRUCK")
public class Truck extends Vehicle {
    float payloadTons;
}
// SQL: SELECT * FROM vehicles WHERE vehicle_type = 'CAR'
// No JOINs needed - fast
```

> **Code walkthrough:** `@DiscriminatorColumn` defines the type column.
> `@DiscriminatorValue` sets the value for each subclass. All data lives
> in one `vehicles` table. The `doors` column has no NOT NULL constraint
> because Truck rows do not have doors. Querying all Cars:
> `SELECT * FROM vehicles WHERE vehicle_type = 'CAR'` - single table,
> no JOINs. Polymorphic: `SELECT * FROM vehicles` returns all types.

```java
// JOINED strategy (for normalized, constraint-rich hierarchies)
@Entity
@Inheritance(strategy = InheritanceType.JOINED)
@Table(name = "vehicles")
public abstract class Vehicle {
    @Id @GeneratedValue Long id;
    String make;
    String model;
}

@Entity
@Table(name = "cars")
@PrimaryKeyJoinColumn(name = "vehicle_id")
public class Car extends Vehicle {
    @Column(nullable = false) // allowed! cars always have doors
    int doors;
}
// Loading a Car:
// SELECT v.make, v.model, c.doors
// FROM vehicles v JOIN cars c ON v.id = c.vehicle_id
// WHERE c.vehicle_id = ?
```

> **Code walkthrough:** JOINED allows `nullable = false` on subclassice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> columns - `doors` is NOT NULL in the `cars` table. Every Car load
> requires a JOIN between `vehicles` and `cars`. Polymorphic query
> `FROM Vehicle` requires LEFT JOINs to all subclass tables - expensive
> if there are many subclasses. The schema is fully normalized: no
> NULL columns for different subtypes.

```java
// @MappedSuperclass (NOT an entity - no table, no polymorphic query)
@MappedSuperclass
public abstract class AuditEntity {
    @Column(updatable = false)
    Instant createdAt;
    Instant updatedAt;
    String createdBy;

    @PrePersist
    void prePersist() {
        createdAt = Instant.now();
        updatedAt = Instant.now();
    }
    @PreUpdate
    void preUpdate() { updatedAt = Instant.now(); }
}

@Entity
public class Order extends AuditEntity {
    @Id Long id;
    String status;
    // Has createdAt, updatedAt, createdBy columns
    // from AuditEntity - no separate table, no JOINs
}
// Cannot query: FROM AuditEntity (not an entity)
// Can query: FROM Order - returns Orders with audit fields
```

> **Code walkthrough:** `@MappedSuperclass` is NOT an entity. Itice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> has no table. Its fields are included in each subclass entity's
> own table. This is the correct pattern for common audit fields
> (createdAt, updatedAt) or soft-delete flags. Zero runtime overhead
> compared to inheritance strategies - just field inclusion.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Hibernate has three inheritance strategies. SINGLE_TABLE puts all
> subclass data in one table with a discriminator column like
> `vehicle_type = 'CAR'` - it is the fastest (no JOINs) but all
> subclass columns must be nullable. JOINED uses separate tables per
> class level, joined by PK - normalized but requires JOINs to load.
> TABLE_PER_CLASS gives each concrete class its own full table - fast
> per-type reads but polymorphic queries need UNION. For most cases,
> I use SINGLE_TABLE for simplicity. Also note `@MappedSuperclass`:
> not an entity, just shared field definitions with no table.

*Push deeper:* "A key limitation of TABLE_PER_CLASS: IDENTITY
generators do not work because IDs must be globally unique across
all subclass tables. You must use SEQUENCE strategy."

---

**Senior / Staff (5+ years):**
> My inheritance strategy selection follows a decision tree. First:
> does this hierarchy represent a true IS-A relationship with shared
> queries, or is it just shared fields? If just shared fields:
> use `@MappedSuperclass`. No database hierarchy needed.
>
> If true IS-A with polymorphic queries: how many subclasses and how
> different are their fields? Few subclasses (<5), mostly shared
> fields: SINGLE_TABLE. Many subclasses with very different fields,
> DB constraints matter: JOINED. Mostly queried individually by type,
> almost never polymorphically: TABLE_PER_CLASS.
>
> In practice I almost always choose SINGLE_TABLE or @MappedSuperclass.
> The JOINED strategy's JOIN overhead on polymorphic queries is often
> underestimated. A `SELECT all Vehicles` with JOINED generates a LEFT
> JOIN to every subclass table, which can be an N-table join plan
> with poor performance for wide hierarchies.
>
> When the hierarchy is in a domain event / CQRS context: I often skip
> JPA inheritance entirely and use a single event table with a JSON
> payload column. Each event type is deserialized in Java, not via
> Hibernate discriminators. This is more flexible for event-sourced
> designs.

*Push deeper:* "The SINGLE_TABLE discriminator filter optimization:
with a proper index on the discriminator column, `SELECT * FROM vehicles
WHERE vehicle_type = 'CAR'` performs as well as a dedicated table scan.
In PostgreSQL, a partial index `WHERE vehicle_type = 'CAR'` makes
per-type queries extremely fast regardless of total row count."

---

### ⚠️ Common Misconceptions

| Misconception | Reality | Danger Level |
|---|---|---|
| "JOINED is more normalized = always better" | JOINED has JOIN overhead on every query; SINGLE_TABLE is faster for most read patterns | Medium |
| "@MappedSuperclass entities can be queried polymorphically" | @MappedSuperclass has no entity table - JPQL FROM AuditEntity fails | High |
| "TABLE_PER_CLASS allows IDENTITY generator" | IDs must be globally unique across all subclass tables; SEQUENCE required | Critical |
| "SINGLE_TABLE cannot have NOT NULL columns for subclasses" | Correct - this is the main schema weakness of SINGLE_TABLE | Medium |
| "Inheritance strategy can be changed without data migration" | Strategy changes require table restructuring and data migration | High |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: SINGLE_TABLE with Too Many Nullable Columns**

*Symptom:* The `payments` table has 40 columns, 35 of which
are NULL for most rows. DBA reports storage waste.

*Root cause:* Payment hierarchy (CreditCard, BankTransfer,
PayPal, Crypto) with unique fields mapped as SINGLE_TABLE.
Each payment type uses 5 of 40 columns; 35 are always NULL.

*Fix:* Migrate to JOINED or use JSONB column for subclass-specific
data:
```java
@Column(columnDefinition = "jsonb")
String subclassData;
// Store type-specific data as JSON in one nullable column
// instead of 35 nullable columns
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

---

**Failure 2: TABLE_PER_CLASS with IDENTITY Generator**

*Symptom:* After adding a second subclass, Hibernate throws
`org.hibernate.MappingException: Generator does not produce
unique values for subclasses of entity`.

*Root cause:* IDENTITY generator is database-scoped per table.
Two tables can both generate ID=1. Polymorphic queries collide.

*Fix:*
```java
@Entity
@Inheritance(strategy = TABLE_PER_CLASS)
public abstract class Vehicle {
    @Id
    @GeneratedValue(strategy = SEQUENCE,
        generator = "vehicle_seq")
    @SequenceGenerator(name = "vehicle_seq",
        allocationSize = 50)
    Long id; // single sequence shared across all subclasses
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

---

**Failure 3: JOINED Polymorphic Query Performance**

*Symptom:* `FROM Vehicle` query takes 8 seconds on 500,000 rows.
EXPLAIN shows 12-way LEFT JOIN.

*Root cause:* JOINED hierarchy with 12 subclasses. Polymorphic
query JOINs all 12 tables.

*Fix:* Use type-specific queries where possible:
```java
// Instead of polymorphic (12-way JOIN):
FROM Vehicle

// Type-specific (2-way JOIN):
FROM Car
```
> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Or reconsider: migrate to SINGLE_TABLE if the hierarchy is stable.

---

### 🎯 Interview Deep-Dive

| Timing | Seniority | Focus |
|--------|-----------|-------|
| 2 min | Junior | Three strategies, basic trade-offs |
| 3 min | Mid | When to use each, @MappedSuperclass |
| 5 min | Senior | Schema implications, polymorphic query cost |
| 7 min | Staff | Domain design - when NOT to use JPA inheritance |
| 10 min | FAANG | SINGLE_TABLE vs JOINED migration |

---

**[JUNIOR] Q1 - [MECHANISM] What is `@MappedSuperclass` and how is it different from `@Inheritance`?**

*Why they ask:* @MappedSuperclass is frequently confused with inheritance.

*Likely follow-up:* "Can you query FROM AuditEntity if it is @MappedSuperclass?"

**Answer:**
`@MappedSuperclass` declares a Java class whose field mappings
are inherited by subclass entities, but which is NOT itself an
entity. It has no database table of its own and cannot be queried
directly.

`@Inheritance` declares a true entity hierarchy where the base
class IS an entity, has a table (or shares one), and can be queried
polymorphically.

Practical difference:
```java
// @MappedSuperclass: just field inheritance
@MappedSuperclass
abstract class AuditEntity {
    Instant createdAt;
    Instant updatedAt;
}
@Entity
class Order extends AuditEntity {
    // Has createdAt, updatedAt columns in orders table
}
// JPQL: FROM AuditEntity -> ERROR (not an entity)
// JPQL: FROM Order -> works

// @Inheritance: entity hierarchy, can query base type
@Entity
@Inheritance(strategy = SINGLE_TABLE)
abstract class Vehicle { ... }
@Entity
class Car extends Vehicle { ... }
// JPQL: FROM Vehicle -> returns all Vehicles (Cars, Trucks)
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using SQL. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Use `@MappedSuperclass` when: the superclass is just a container for
common fields (audit fields, soft-delete, version) and subclasses
are independent entities with no polymorphic query needed.

Use `@Inheritance` when: you need to query the base type
polymorphically or when the hierarchy represents a real IS-A
domain relationship.

*What separates good from great:* Demonstrating that `FROM
AuditEntity` fails while `FROM Vehicle` works - the key observable
difference between the two annotations.

---

**[MID] Q2 - [MECHANISM] When should you choose JOINED over SINGLE_TABLE?**

*Why they ask:* Understanding when JOINED is worth the JOIN cost.

*Likely follow-up:* "What is the schema difference for nullable columns?"

**Answer:**
Choose JOINED over SINGLE_TABLE when three conditions are true:

1. Subclasses have significantly different fields. If Car has 8
   unique fields, Truck has 7 unique fields, and Motorcycle has
   5 unique fields, SINGLE_TABLE has 20 nullable columns per row.
   JOINED has 3 small subclass tables, each with their specific
   NOT NULL columns.

2. NOT NULL constraints on subclass fields matter. In SINGLE_TABLE,
   `doors` on Car cannot be declared NOT NULL - Truck rows would
   violate it. In JOINED, the `cars.doors` column CAN be NOT NULL
   because only Car rows are in that table.

3. The hierarchy has limited polymorphic queries. JOINED's JOIN
   cost is per-query. If most queries are type-specific (`FROM Car
   WHERE make = 'Toyota'`), the JOIN is only 2 tables - manageable.
   If the primary query pattern is `FROM Vehicle` with many subclasses,
   the multi-table LEFT JOIN is expensive.

When SINGLE_TABLE wins: high query volume, performance critical,
discriminator column indexed, subclasses share most fields.

*What separates good from great:* The NOT NULL constraint argument -
the most concrete schema advantage of JOINED that is impossible
with SINGLE_TABLE.

---

**[SENIOR] Q3 - [TRADE-OFF] You are designing a notification system with 8 types (Email, SMS, Push, Webhook, Slack, Teams, Discord, InApp), each with 3-5 unique fields. Which inheritance strategy?**

*Why they ask:* 8 subtypes with unique fields is a real design decision.

*Likely follow-up:* "Would you use JPA inheritance at all for this?"

**Answer:**
For 8 notification types with 3-5 unique fields each, I would NOT
use JPA inheritance at all. Here is why:

Option 1 (if JPA inheritance required): SINGLE_TABLE.
- Total columns: ~10 shared + 40 unique = ~50 columns, mostly NULL
- Pro: one table, fast queries, simple
- Con: schema unreadable, no constraints on type-specific fields

Option 2 (better): JSONB column for type-specific payload.
```java
@Entity
@Table(name = "notifications")
public class Notification {
    @Id Long id;
    String type; // "EMAIL", "SMS", "PUSH"...
    String recipient;
    NotificationStatus status;
    @Column(columnDefinition = "jsonb")
    String payload; // type-specific fields as JSON
}
// Email payload: {"subject":"...", "from":"...", "body":"..."}
// SMS payload: {"phone":"...", "message":"..."}
```
> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

One table, no JPA inheritance, type-specific data in JSON.
In PostgreSQL, JSONB is queryable and indexable.

Option 3 (my preference for event-sourced systems):
No JPA inheritance. Each notification type has its own DTO/Command
object in Java. The polymorphism is in the application layer
(strategy pattern), not in the ORM layer.

*What separates good from great:* Proposing the JSONB payload pattern
as an alternative to ORM inheritance - a common production pattern
for notification/event hierarchies with many types.

---

**[SENIOR] Q4 - [DEBUGGING] A `SELECT * FROM vehicles` returns correct data but omits some vehicles. No error is thrown. What could cause this?**

*Why they ask:* Tests knowledge of discriminator mapping corner cases.

*Likely follow-up:* "How do you debug missing discriminator values?"

**Answer:**
If some rows are returned and some silently omitted from a
polymorphic query, the most likely cause is unmapped discriminator
values.

In SINGLE_TABLE: if the database has a row with
`vehicle_type = 'BICYCLE'` but there is no Java entity class
with `@DiscriminatorValue("BICYCLE")`, Hibernate drops that row
silently by default. It cannot construct an entity for an unknown
discriminator value.

Debugging:
```sql
-- Check for discriminator values not in entity mappings:
SELECT vehicle_type, COUNT(*) FROM vehicles
GROUP BY vehicle_type;
-- If you see types not in your entity classes,
-- those rows are silently dropped
```

> **Code walkthrough:** This Unknown example demonstrates query execution using SQL. **KEY MECHANISM:** the query planner builds an execution plan based on table statistics and indexes. **WHY IT MATTERS:** SELECT * reads all columns even if only 2 are needed - widens rows, increases I/O. **TAKEAWAY: always SELECT only the columns you need; index the columns in WHERE and JOIN clauses.**

Fixes:
1. Add the missing subclass entity with `@DiscriminatorValue`.
2. Add `@DiscriminatorValue("not null")` for abstract base class
   to return rows with non-matching discriminators.
3. Check for NULL discriminator values in legacy rows:
```sql
SELECT COUNT(*) FROM vehicles WHERE vehicle_type IS NULL;
-- NULLs are also silently dropped
```

> **Code walkthrough:** This Unknown example demonstrates query execution using SQL. **KEY MECHANISM:** the query planner builds an execution plan based on table statistics and indexes. **WHY IT MATTERS:** SELECT * reads all columns even if only 2 are needed - widens rows, increases I/O. **TAKEAWAY: always SELECT only the columns you need; index the columns in WHERE and JOIN clauses.**

Prevention: always explicitly annotate `@DiscriminatorValue` on every
subclass and never rely on the default (class simple name). Backfill
discriminator columns when adding the column to legacy tables.

*What separates good from great:* The SQL diagnostic query to find
discriminator values not in entity mappings - showing how to surface
the problem rather than guess at it.

---

**[MID] Q5 - [TRADE-OFF] What is the difference between `@Embedded`/`@Embeddable` and inheritance in Hibernate?**

*Why they ask:* Tests ability to distinguish IS-A from HAS-A patterns.

*Likely follow-up:* "When would you prefer composition over inheritance in Hibernate?"

**Answer:**
`@Embedded`/`@Embeddable` models HAS-A (composition): an entity
contains a value object whose fields are stored in the same table.
Inheritance models IS-A: a hierarchy of entity types sharing a
common base type.

```java
// Composition: Address is not an entity, it is a value object
@Embeddable
public class Address {
    String street;
    String city;
    String zipCode;
}
@Entity
public class User {
    @Embedded Address address; // columns in users table
    // users: id, name, street, city, zipCode
}
// Address is not queryable independently
// FROM Address -> ERROR

// Inheritance: Employee IS-A Person
@Entity
@Inheritance(strategy = SINGLE_TABLE)
class Person { ... }
@Entity
class Employee extends Person { ... }
// FROM Person -> returns all Persons (including Employees)
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Choose `@Embeddable` (composition) when:
- The component has no identity of its own (no PK, no lifecycle)
- It is always accessed through its owner
- Multiple entities can embed the same value type (User AND
  Company both have Address)

Choose inheritance when:
- The subclass IS an instance of the base class semantically
- Polymorphic queries are needed (give me all Persons)
- The subclass has its own lifecycle

*What separates good from great:* The DDD framing: `@Embeddable` for
value objects (no identity, equality by value), `@Entity` with
inheritance for entity hierarchies (identity, lifecycle, polymorphism).

---

**[MID] Q6 - [DEBUGGING] All `Car` queries return some Truck data mixed in. What is happening?**

*Why they ask:* Discriminator configuration bugs cause data integrity issues.

*Likely follow-up:* "How do you ensure the discriminator is set correctly?"

**Answer:**
Mixed data in SINGLE_TABLE queries is caused by a missing or incorrect
discriminator value assignment. Without `@DiscriminatorValue`, Hibernate
uses the class simple name as default. If the class was renamed or the
default differs from data in the database, discriminator matching breaks.

Investigation:
```sql
SELECT vehicle_type, COUNT(*) FROM vehicles
GROUP BY vehicle_type;
-- Expected: CAR, TRUCK, MOTORCYCLE
-- Actual: Car, Truck, com.example.Car, null
-- Mismatch between Java defaults and database values
```

> **Code walkthrough:** This Unknown example demonstrates query execution using SQL. **KEY MECHANISM:** the query planner builds an execution plan based on table statistics and indexes. **WHY IT MATTERS:** SELECT * reads all columns even if only 2 are needed - widens rows, increases I/O. **TAKEAWAY: always SELECT only the columns you need; index the columns in WHERE and JOIN clauses.**

Root cause scenario: Car was originally not annotated with
`@DiscriminatorValue`, so rows were inserted with `vehicle_type = 'Car'`
(class simple name default). Later, `@DiscriminatorValue("CAR")` was added.
Now Hibernate queries for `'CAR'` but legacy rows have `'Car'`.

Fix - migration:
```sql
UPDATE vehicles SET vehicle_type = 'CAR'
WHERE vehicle_type = 'Car';
```

> **Code walkthrough:** This Unknown example demonstrates SQL pattern using SQL. **KEY MECHANISM:** the database parses, plans, and executes the query; EXPLAIN ANALYZE shows the actual plan. **WHY IT MATTERS:** missing WHERE clause on UPDATE/DELETE affects all rows - no undo without a transaction rollback. **TAKEAWAY: always test destructive SQL in a transaction; use EXPLAIN ANALYZE before deploying.**

subclass. This makes the discriminator value visible in code and immune
to class renames.

*What separates good from great:* Diagnosing via the SQL query that
counts actual discriminator values in the database - not guessing.

---

**[STAFF] Q7 - [BEHAVIORAL] Tell me about a time you had to change an inheritance mapping strategy in a production system.**

*Why they ask:* Inheritance strategy migration is a real and difficult
operational task.

*Likely follow-up:* "How did you handle the dual-write period?"

**Answer:**

**S (Situation):** A payment processing system used SINGLE_TABLE for
a `Payment` hierarchy with 12 subtypes (CreditCard, BankWire, PayPal,
etc.). After 3 years, the `payments` table had 85 columns, 70 of which
were NULL for any given row. Query plans used row estimates based on
wide rows; performance was degrading.

**T (Task):** Migrate from SINGLE_TABLE to JOINED to normalize the
schema and allow NOT NULL constraints on required subtype fields.

**A (Action):** The migration followed an expand-contract pattern
across 4 deployment cycles:

Cycle 1 (Expand): Added JOINED subclass tables alongside the existing
SINGLE_TABLE schema. Hibernate read from SINGLE_TABLE, wrote to
BOTH tables using a Hibernate interceptor that populated both schemas.

Cycle 2 (Backfill): Migrated historical data into JOINED tables.
Verified row counts match for each subtype.

Cycle 3 (Switch): Changed Hibernate mapping to JOINED strategy.
Both schemas still exist. Hibernate now reads from JOINED. Kept
dual-write for 1 week for rollback safety.

Cycle 4 (Contract): Removed dual-write. Archived SINGLE_TABLE data.
Dropped excess nullable columns.

**R (Result):** Schema reduced from 85 to ~15 columns per subtype
table. Per-type query performance improved 3x (smaller row size).
NOT NULL constraints added on 47 previously nullable critical fields,
catching 3 data quality bugs in staging before they reached production.

*What separates good from great:* The 4-cycle expand-contract approach
rather than a flag-day migration - and using an interceptor for the
dual-write period.

---

### ⚖️ Comparison Table

| Strategy | Tables | JOINs on load | Polymorphic query | NULL columns | Best For |
|----------|--------|---------------|-------------------|--------------|----------|
| SINGLE_TABLE | 1 | 0 | Fast | Many | Few subtypes, shared fields |
| JOINED | N+1 | 1 per class | Moderate JOIN | None | Normalized, DB constraints |
| TABLE_PER_CLASS | N | 0 | UNION ALL | None | Independent types, no polymorphic |
| @MappedSuperclass | 0 (per entity) | 0 | N/A | None | Shared field definitions |

**The deciding factor:**
Default to SINGLE_TABLE for simplicity and performance. Use JOINED
when NOT NULL constraints on subclass columns are required. @MappedSuperclass
for shared audit fields.

*(Omit: System Design - ★★☆ keyword)*

*(Omit: Diagram - code and table are sufficiently illustrative)*

---

---

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


# Optimistic and Pessimistic Locking

**TL;DR** - Optimistic locking with `@Version` checks a version number
at UPDATE time to detect concurrent modifications without holding a
lock; pessimistic locking with `SELECT FOR UPDATE` holds a row lock
from read through commit to prevent concurrent access.

---

### 🎯 Model Answer

**30 seconds:**
> Optimistic locking assumes conflicts are rare - it does not hold a
> database lock. At UPDATE time, it checks: did anyone modify this row
> since I loaded it? If yes, throw `OptimisticLockException` and let
> the application retry. `@Version` implements this with a version column.
> Pessimistic locking holds a database row lock from the SELECT through
> commit, blocking other transactions from reading or writing that row.
> It is used when you cannot afford to retry (payment processing, seat booking).

**3 minutes (Senior):**
> The choice between optimistic and pessimistic locking is determined
> by: how often conflicts occur, whether the operation can be retried,
> and the acceptable latency.
>
> Optimistic locking with `@Version` works by appending `AND version = ?`
> to every UPDATE: `UPDATE products SET price = ?, version = 6 WHERE
> id = 42 AND version = 5`. If no row is updated (0 rows affected),
> Hibernate throws `OptimisticLockException`. The version is managed
> by Hibernate - incremented on every flush. For `@Version`, the field
> type can be `int`, `long`, `Instant`, or `Timestamp`. Using `Instant`
> has the advantage of providing a last-modified timestamp for free, but
> sub-millisecond concurrent updates can cause false collision detection.
> Use `Long` for reliability.
>
> Pessimistic locking uses `SELECT FOR UPDATE` which acquires a row-level
> exclusive lock on the database. Other transactions that attempt to
> write to the locked row block until the lock is released at commit or
> rollback. JPA: `LockModeType.PESSIMISTIC_READ` (shared lock) and
> `LockModeType.PESSIMISTIC_WRITE` (exclusive lock, most common).
>
> The hybrid pattern: start with optimistic locking. On conflict,
> retry the transaction up to N times. For booking-style operations
> where the resource is genuinely scarce, use pessimistic locking during
> the reservation phase only - minimize the lock duration.

*Adapting up:* Lock escalation risk: many row-level pessimistic locks
on the same table can escalate to a table lock in some databases (MySQL
with certain storage engines). Monitor via `pg_locks` and
`pg_stat_activity` in PostgreSQL.

*Adapting down:* "Optimistic: check if anything changed before saving.
No lock held. Pessimistic: hold a lock on the row so nobody else can
change it while you work."

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about locking strategies - optimistic
and pessimistic - for handling concurrent modifications to database rows."

**(2) First principles:** "From first principles, two transactions reading
and updating the same row can produce a lost update: the second update
overwrites the first's changes. Locking prevents this - either by detecting
the conflict at commit time (optimistic) or by preventing concurrent access
entirely (pessimistic)."

**(3) Bridge:** "Optimistic locking is like writing on a whiteboard in
pencil, checking before you erase: 'did anyone write here since I started?'
Pessimistic locking is like locking the room before you start writing:
nobody else can enter until you leave."

---

### 📘 Concept Explanation

**What it is:**
Locking strategies control how concurrent transactions access and modify
the same database rows. Optimistic locking detects conflicts at commit
time using a version check. Pessimistic locking prevents concurrent access
by holding a row-level lock from read through commit.

**The problem it solves:**
The lost update problem: Transaction A and Transaction B both read a product
with stock=10. A sells 3 and writes stock=7. B sells 5 and writes stock=5
(ignoring A's update). The correct stock should be 2. Without locking,
B's update silently loses A's change.

**How it works:**

```
Optimistic Locking (@Version):
T1: SELECT * FROM products WHERE id=1
    -> {id=1, stock=10, version=5}
T2: SELECT * FROM products WHERE id=1
    -> {id=1, stock=10, version=5}
T1: UPDATE products
    SET stock=7, version=6
    WHERE id=1 AND version=5  -> 1 row updated
T2: UPDATE products
    SET stock=5, version=6
    WHERE id=1 AND version=5  -> 0 rows (version=6 now)
    -> OptimisticLockException

Pessimistic Locking (SELECT FOR UPDATE):
T1: SELECT * FROM products WHERE id=1 FOR UPDATE
    -> row locked by T1
T2: SELECT * FROM products WHERE id=1 FOR UPDATE
    -> BLOCKS until T1 commits
T1 commits -> row released
T2 unblocks -> reads T1's committed value
T2 computes new stock based on T1's committed value
```

> **Code walkthrough:** This Optimistic and Pessimistic Locking example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
Optimistic locking detects conflicts; pessimistic locking prevents them.
Optimistic requires retry logic. Pessimistic requires careful lock duration
management to avoid deadlocks and connection pool exhaustion.

**When to use each:**
- Optimistic: web CRUD (high concurrency, conflicts rare, retry acceptable)
- Pessimistic: booking/allocation (conflict likely for scarce resource)
- Atomic UPDATE: counter increment/decrement (high-throughput, simple logic)

**Alternatives:**
- Serializable isolation: database handles serialization
- Event sourcing: append-only log removes the need for locking
- Redis atomic operations: for distributed counters

---

### 💻 Code Example

```java
// BAD: No locking - silent lost update
@Transactional
public void reserveSeat(Long seatId) {
    Seat seat = seatRepo.findById(seatId).orElseThrow();
    if (seat.isAvailable()) {
        seat.setAvailable(false);
        seatRepo.save(seat);
    }
    // Two concurrent calls can both see available=true
    // Both set available=false - both "succeed"
    // Silent data corruption: seat double-booked
}
```

> **Code walkthrough:** Both transactions read the same Seat, both seeice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `available = true`, both set it false, both commit. The seat is reserved
> twice. No exception is thrown. This is the lost update problem - silent,
> no error, discovered only by downstream inconsistencies.

```java
// GOOD: Optimistic locking with @Version (for most CRUD)
@Entity
public class Product {
    @Id Long id;
    String name;
    BigDecimal price;
    int stockCount;

    @Version
    long version; // Hibernate manages: increments on every flush
}

@Service
@Transactional
public class ProductService {
    public void decrementStock(Long productId, int quantity) {
        Product p = productRepo.findById(productId)
            .orElseThrow();
        if (p.getStockCount() < quantity) {
            throw new InsufficientStockException();
        }
        p.setStockCount(p.getStockCount() - quantity);
        // At flush: UPDATE products
        //   SET stock=?, version=N+1 WHERE id=? AND version=N
        // 0 rows updated -> OptimisticLockException
    }
}

// Caller with retry (Spring Retry):
@Retryable(value = OptimisticLockException.class,
    maxAttempts = 3,
    backoff = @Backoff(delay = 50, multiplier = 2))
@Transactional
public void decrementStockWithRetry(Long id, int qty) {
    productService.decrementStock(id, qty);
}
```

> **Code walkthrough:** `@Version` appends `AND version = N` to everyice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> UPDATE. If another transaction already committed a version increment,
> 0 rows are updated and `OptimisticLockException` is thrown. The retry
> annotation retries the entire transaction (reloading the entity with
> the new version) up to 3 times. Exponential backoff reduces retry
> collisions under high load. At low conflict rates (< 5%), this is
> efficient and requires no database locks.


```java
// BAD: calling @Transactional method from same class
// Spring proxy is bypassed - no transaction started
public void processOrder(Order order) {
    saveOrder(order); // self-call bypasses proxy
}
@Transactional
public void saveOrder(Order order) { /* ... */ }
```

```java
// GOOD: Pessimistic locking for booking (scarce resource)
@Service
@Transactional
public class SeatBookingService {

    public Booking reserveSeat(Long seatId, Long userId) {
        // PESSIMISTIC_WRITE = SELECT ... FOR UPDATE
        // Other transactions block on this row
        Seat seat = em.find(Seat.class, seatId,
            LockModeType.PESSIMISTIC_WRITE);

        if (!seat.isAvailable()) {
            throw new SeatNotAvailableException(seatId);
        }
        seat.setAvailable(false);
        Booking booking = new Booking(userId, seatId);
        bookingRepo.save(booking);
        return booking;
        // Commit: lock released here
    }
}

// Spring Data equivalent:
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("SELECT s FROM Seat s WHERE s.id = :id")
Optional<Seat> findByIdForUpdate(@Param("id") Long id);
```

> **Code walkthrough:** `LockModeType.PESSIMISTIC_WRITE` generatesice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `SELECT ... FOR UPDATE`. Concurrent transactions attempting to lock
> the same seat row BLOCK until this transaction commits. The second
> transaction then reads the updated row (`available = false`) and
> throws `SeatNotAvailableException`. No race condition, no double-booking.
> The lock is held only for the duration of this short transaction - typically
> < 100ms. Never hold a FOR UPDATE lock across an I/O operation.


```java
// BAD: calling @Transactional method from same class
// Spring proxy is bypassed - no transaction started
public void processOrder(Order order) {
    saveOrder(order); // self-call bypasses proxy
}
@Transactional
public void saveOrder(Order order) { /* ... */ }
```

```java
// GOOD: Atomic UPDATE - alternative for high-throughput counters
// Avoids both locking strategies for simple counter operations
@Modifying
@Transactional
@Query("UPDATE Product p " +
    "SET p.stock = p.stock - :qty " +
    "WHERE p.id = :id AND p.stock >= :qty")
int decrementStock(
    @Param("id") Long id,
    @Param("qty") int qty);
// Returns 1 = success, 0 = insufficient stock
// One atomic DB operation - no locks held in application
// Scales better than optimistic retries for hot items
```

> **Code walkthrough:** The atomic UPDATE is a single SQL statementice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> that reads and writes in one database operation. The `AND p.stock >= :qty`
> condition serves as both the business rule check (have enough stock?)
> and the concurrency control (only one update succeeds when stock hits
> zero). Return value 0 means either the product does not exist or stock
> was insufficient. This pattern is ideal for flash-sale-scale inventory
> where optimistic locking would produce many retries.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Optimistic locking uses `@Version` on the entity. Hibernate adds a
> version column and checks `AND version = ?` on every UPDATE. If
> another transaction updated the row first, the version does not
> match and Hibernate throws `OptimisticLockException`. The application
> retries. Pessimistic locking uses `SELECT FOR UPDATE` via
> `LockModeType.PESSIMISTIC_WRITE`, which holds a row lock from read
> to commit, blocking other writers. I use optimistic by default and
> pessimistic only for booking-style scenarios where two users competing
> for the same resource cannot both be allowed to proceed.

*Push deeper:* "`@Version` only works when ALL writes go through Hibernate.
If another system modifies the row via native SQL without updating the
version column, Hibernate will not detect the conflict and a lost update
can occur."

---

**Senior / Staff (5+ years):**
> My locking decision framework: default to optimistic locking for all
> CRUD operations. Measure conflict rate. If consistently below 5%:
> optimistic is optimal. If above 20%: pessimistic may be more efficient
> (fewer wasted retries at the cost of lock wait time).
>
> For pessimistic locking, I minimize lock duration aggressively: load
> with FOR UPDATE, make the decision immediately, commit. Never hold a
> pessimistic lock while doing I/O (HTTP calls, message queue reads).
> Lock contention creates queuing effects: 100ms average lock hold time
> at 50 req/s means an average queue of 5 waiting transactions.
>
> For inventory-style operations (concurrent counter decrements), I favor
> the atomic UPDATE pattern:
> `UPDATE products SET stock = stock - :qty WHERE id = :id AND stock >= :qty`.
> This eliminates application-level retry loops entirely and scales better
> than either locking strategy for hot items.

*Push deeper:* "Deadlock prevention with pessimistic locking: always acquire
locks in the same order. If transaction A locks seat 5 then seat 10, and
transaction B locks seat 10 then seat 5 - deadlock. Standardize lock
acquisition order (always ascending ID) to prevent circular waits."

---

### ⚠️ Common Misconceptions

| Misconception | Reality | Danger Level |
|---|---|---|
| "OptimisticLockException means data corruption occurred" | It means corruption was PREVENTED - the conflict was detected and the transaction rolled back | Medium |
| "@Version prevents all concurrent modification issues" | Only works when ALL writes go through Hibernate; native SQL bypasses the version check | Critical |
| "PESSIMISTIC_READ blocks all concurrent reads" | PESSIMISTIC_READ is a shared lock - multiple readers allowed simultaneously; only exclusive writes blocked | Medium |
| "Optimistic locking is always better (no blocking)" | For high-conflict scenarios, retry overhead from OptimisticLockExceptions can exceed pessimistic wait time | Medium |
| "Deadlocks only occur with pessimistic locking" | Optimistic locking retries can create effective live-locks if two transactions repeatedly collide | Low |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Lost Update Despite @Version**

*Symptom:* Stock goes negative despite `@Version` on the Product entity.

*Root cause:* A native SQL UPDATE (batch job, DBA script) modified
rows without updating the `version` column. Hibernate sees version=5
in memory and in DB (unchanged by native SQL) and commits a lost update.

*Fix:*
```sql
-- Native SQL MUST update version column:
UPDATE products
SET stock = stock - ?,
    version = version + 1 -- required!
WHERE id = ? AND version = ?
-- AND version check for optimistic semantics in native SQL
```

> **Code walkthrough:** This Unknown example demonstrates SQL pattern using SQL. **KEY MECHANISM:** the database parses, plans, and executes the query; EXPLAIN ANALYZE shows the actual plan. **WHY IT MATTERS:** missing WHERE clause on UPDATE/DELETE affects all rows - no undo without a transaction rollback. **TAKEAWAY: always test destructive SQL in a transaction; use EXPLAIN ANALYZE before deploying.**

---

**Failure 2: Deadlock with Pessimistic Locking**

*Symptom:* `LockAcquisitionException` or `DeadlockLoserDataAccessException`
intermittently under load.

*Root cause:* Transactions locking multiple rows in different orders.
T1: lock(seat5) then lock(seat10). T2: lock(seat10) then lock(seat5).
Circular wait = deadlock.

*Fix:*
```java
// Always acquire locks in ascending ID order:
List<Long> seatIds = new ArrayList<>(requestedIds);
Collections.sort(seatIds); // ascending order
for (Long id : seatIds) {
    em.find(Seat.class, id, PESSIMISTIC_WRITE);
}
// Both transactions now lock 5 then 10 - no circular wait
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

---

**Failure 3: Connection Pool Exhaustion from Long Pessimistic Locks**

*Symptom:* Pool exhaustion during high load. Transactions hold
connections for 5-10 seconds.

*Root cause:* Pessimistic lock acquired, then I/O performed (HTTP call
to external service) while holding the lock and connection.

*Fix:*

```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// BAD: lock held during I/O
Seat seat = em.find(Seat.class, id, PESSIMISTIC_WRITE);
paymentService.charge(...); // HTTP call while lock held!

// GOOD: charge first (no lock), then short lock window
PaymentResult result = paymentService.charge(...);
if (result.isSuccess()) {
    Seat seat = em.find(Seat.class, id, PESSIMISTIC_WRITE);
    if (seat.isAvailable()) {
        seat.setBooked(true);
        commit(); // lock released here - total hold < 10ms
    }
}
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **WHAT BREAKS: document thread-safety guarantees on every shared mutable class.**

---

### 🎯 Interview Deep-Dive

| Timing | Seniority | Focus |
|--------|-----------|-------|
| 2 min | Junior | @Version mechanism, when OLE is thrown |
| 3 min | Mid | Optimistic vs pessimistic decision |
| 5 min | Senior | Lost update failure modes, deadlock prevention |
| 7 min | Staff | Locking design for inventory system |
| 10 min | FAANG | High-throughput counter without locking |

---

**[JUNIOR] Q1 - [MECHANISM] What does `@Version` do in Hibernate and what happens when the version check fails?**

*Why they ask:* @Version is fundamental to Hibernate concurrency.

*Likely follow-up:* "What exception is thrown and how should the application handle it?"

**Answer:**
`@Version` adds a version column to the entity's table and enables
optimistic locking. Hibernate automatically manages the version:

On load: reads the version value and stores it in the entity.

On update (flush):
`UPDATE table SET ..., version = N+1 WHERE id = ? AND version = N`

If no row was updated (0 rows affected): another transaction
committed a change to the same row since our load, incrementing
the version. Hibernate throws `StaleObjectStateException` (Hibernate)
or `OptimisticLockException` (JPA).

Application handling:
```java
try {
    productService.updatePrice(id, newPrice);
} catch (OptimisticLockException e) {
    // Options:
    // 1. Retry the entire transaction (reload entity first)
    // 2. Show user "data was updated, please review"
    // 3. Automated jobs: exponential backoff + retry
    throw new ConcurrentUpdateException(
        "Product was updated concurrently, retry");
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using SQL. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

Critical: on retry, reload the entity from DB - do not reuse the
stale object. The entity's version is still the old value; retrying
with the same object will fail again.

*What separates good from great:* Emphasizing that the entity must
be reloaded on retry, not just the method retried with the stale object.

---

**[MID] Q2 - [MECHANISM] What is the difference between `PESSIMISTIC_READ` and `PESSIMISTIC_WRITE` lock modes?**

*Why they ask:* Tests knowledge of the different pessimistic lock types.

*Likely follow-up:* "When would you use PESSIMISTIC_READ?"

**Answer:**
`PESSIMISTIC_READ` acquires a shared lock (`SELECT ... FOR SHARE`).
Multiple transactions can hold a shared lock on the same row simultaneously.
A transaction attempting `PESSIMISTIC_WRITE` (exclusive lock) on a
shared-locked row blocks until all shared lock holders release.

`PESSIMISTIC_WRITE` acquires an exclusive lock (`SELECT ... FOR UPDATE`).
No other transaction can acquire any lock (read or write) on the locked
row until the exclusive lock is released.

`PESSIMISTIC_READ` use case: a price quotation scenario. I want to read
a product price for a quote and ensure the price does not change while
I prepare the quote. Other concurrent price reads are fine (shared lock
allows this). Only price updates are blocked.

`PESSIMISTIC_WRITE` use case: booking, reservation, stock decrement -
any operation where I must read and immediately write, and no concurrent
read or write should interfere.

In practice, `PESSIMISTIC_WRITE` is by far the most commonly used.
`PESSIMISTIC_READ` is appropriate when you want to prevent writes but
explicitly allow concurrent reads, and when you want to signal "this
operation is read-only and should not block other reads."

*What separates good from great:* The price quotation scenario for
PESSIMISTIC_READ - allow concurrent reads, prevent price change.

---

**[SENIOR] Q3 - [DEBUGGING] `OptimisticLockException` rate spikes to 30% during a flash sale. How do you diagnose and fix it?**

*Why they ask:* Tests handling of optimistic locking at high conflict rate.

*Likely follow-up:* "At what conflict rate does pessimistic locking become more efficient?"

**Answer:**
30% conflict rate means 30% of stock decrement operations fail and
retry. At 10,000 RPS, that is 3,000 wasted retries per second.

Diagnosis: high contention on specific product rows. Flash sales
concentrate traffic on a few product IDs.

Short-term fix: replace optimistic locking with an atomic UPDATE:
```java
@Modifying @Transactional
@Query("UPDATE Product p SET p.stock = p.stock - :qty " +
    "WHERE p.id = :id AND p.stock >= :qty")
int decrementStock(Long id, int qty);
// Return 0 = out of stock, 1 = success
// Single atomic operation, no retry loop
```

> **Code walkthrough:** This Unknown example demonstrates Spring declarative transaction using @Transactional. **KEY MECHANISM:** Spring wraps the method in a proxy that begins/commits a DB transaction. **WHY IT MATTERS:** calling @Transactional from the same class bypasses the proxy - no transaction. **TAKEAWAY: never self-invoke @Transactional methods; inject the bean instead.**

This is more efficient than either locking strategy for hot-item
flash sales because it has:
- No application-level retry loop
- No held lock between read and write
- The database's internal row lock is held only for the single
  statement duration (microseconds, not milliseconds)

Long-term fix: Redis `DECRBY` for hot counters:
```
DECRBY product:1001:stock 3
// If result < 0: INCRBY to rollback, return "out of stock"
```
> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

This moves the hot counter out of the relational database, removing
row contention entirely.

The threshold: if conflict rate > 10-15% consistently, atomic UPDATE
or queue-based inventory is more appropriate than optimistic retries.
For conflict rates < 5%: optimistic with retry is optimal.

*What separates good from great:* The Redis counter architecture for
flash-sale-scale inventory - removing the hot row from the relational
database entirely.

---

**[SENIOR] Q4 - [TRADE-OFF] When should you use an atomic `UPDATE ... WHERE stock >= qty` instead of either locking strategy?**

*Why they ask:* The atomic update is an underused alternative.

*Likely follow-up:* "What are the limitations of the atomic UPDATE approach?"

**Answer:**
Use the atomic UPDATE pattern when:

1. The operation is a simple counter operation expressible as a
   single SQL expression. Increment/decrement, conditional set
   (stock = stock - qty WHERE stock >= qty).

2. High contention is expected (flash sales, limited inventory).
   No application-level retries needed.

3. The return value (rows affected) is sufficient feedback to
   determine success or failure.

Limitations:

- No `@Version` increment: if other code uses optimistic locking
  on the same entity, it will not see a version change from this
  atomic UPDATE. You must include `version = version + 1` explicitly.

- No lifecycle callbacks: `@PreUpdate` is not called. Audit logic
  must be handled separately.

- L1C stale read: if you load the entity after this UPDATE in the
  same session, you will see the old value (L1C has the pre-update
  snapshot). Fix by evicting the entity from the L1C:
  ```java
  productRepo.decrementStock(id, qty);
  em.evict(productRef); // force fresh load on next access
  ```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

- Complex business logic cannot be expressed in one SQL expression:
  if the update requires reading multiple related entities, applying
  business rules, and updating several tables, the full entity-in-TX
  approach (optimistic or pessimistic) is required.

*What separates good from great:* The L1C stale read issue and the
`@Version` consistency requirement - two concrete limitations requiring
explicit handling.

---

**[MID] Q5 - [MECHANISM] What happens to `@Version` when you use `SELECT FOR UPDATE` pessimistic locking?**

*Why they ask:* Tests understanding of how the two mechanisms interact.

*Likely follow-up:* "Can you use both on the same entity?"

**Answer:**
When you load an entity with `PESSIMISTIC_WRITE` (FOR UPDATE) AND
the entity has `@Version`, both mechanisms are active simultaneously.

The sequence:
1. `SELECT * FROM products WHERE id=? FOR UPDATE`
   - Row is locked by T1
   - Version N is loaded with the entity

2. Business logic executes (price change, stock update, etc.)

3. `UPDATE products SET price=?, version=N+1 WHERE id=? AND version=N`
   - Version check appended as always
   - Since FOR UPDATE prevents any concurrent writes, version N is
     still the current value - the check always succeeds

In practice: when using PESSIMISTIC_WRITE, the @Version check is
redundant (FOR UPDATE already prevents the conflicting update).
But it does not cause errors - it simply always passes.

The combination is useful when: you use pessimistic for the initial
reservation (FOR UPDATE during the booking operation) and rely on
optimistic for subsequent updates to the same entity (status updates,
amount adjustments). The @Version provides protection for all
update paths, and FOR UPDATE is added only to the specific high-contention
operation.

Yes, both can be used on the same entity - and for booking systems,
this combination is a common production pattern.

*What separates good from great:* The practical combination pattern:
pessimistic for booking phase, optimistic for subsequent processing.

---

**[JUNIOR] Q6 - [DEBUGGING] You see duplicate invoice numbers despite `@Version` being configured. Why might this happen?**

*Why they ask:* Tests edge cases of optimistic locking.

*Likely follow-up:* "What is the database-level defense against duplicates?"

**Answer:**
`@Version` protects against lost updates to existing rows. Duplicate
invoice numbers are caused by concurrent INSERTS, not concurrent updates.

When two concurrent transactions both execute "get next invoice number"
without locking:
- Both read `counter = 1042`
- Both increment to 1043 and insert invoices with number 1042
- `@Version` on the invoice entity does not help - these are new rows,
  not updates to existing rows

`@Version` is on the SequenceCounter entity, but if the concurrent
access is between reading the counter and writing the invoice (two
separate entities), the version check on SequenceCounter fails for
the second transaction. If the application catches and swallows the
`OptimisticLockException` on the counter update, the duplicate occurs.

Fixes:

1. Pessimistic lock the counter:
```java
SequenceCounter c = em.find(SequenceCounter.class, tenantId,
    LockModeType.PESSIMISTIC_WRITE);
long invoiceNumber = c.getAndIncrement();
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

2. Unique constraint as the final defense:
```sql
ALTER TABLE invoices
ADD CONSTRAINT uq_tenant_invoice
UNIQUE (tenant_id, invoice_number);
```
> **Code walkthrough:** This Unknown example demonstrates SQL pattern. **KEY MECHANISM:** the database parses, plans, and executes the query; EXPLAIN ANALYZE shows the actual plan. **WHY IT MATTERS:** missing WHERE clause on UPDATE/DELETE affects all rows - no undo without a transaction rollback. **TAKEAWAY: always test destructive SQL in a transaction; use EXPLAIN ANALYZE before deploying.**

Even if locking fails, the constraint prevents silent duplicates.

*What separates good from great:* The two-layer fix (pessimistic lock
AND unique constraint as defense-in-depth) rather than fixing only
one layer.

---

**[STAFF] Q7 - [BEHAVIORAL] Describe a concurrency bug you encountered in production and how you debugged and fixed it.**

*Why they ask:* Tests real-world concurrency debugging experience.

*Likely follow-up:* "How did you add tests to prevent regression?"

**Answer:**

**S (Situation):** A multi-tenant SaaS platform tracked the next
invoice number per tenant in a `SequenceCounter` entity. Multiple
users in the same tenant could create invoices concurrently. We saw
duplicate invoice numbers - a critical billing integrity failure.

**T (Task):** Investigate the root cause and fix it without downtime.

**A (Action):**

Analysis:
1. Both invoice A and invoice B had number 1042.
2. `sequence_counters.version` was correctly incremented.
3. The code: load counter (no lock), read nextValue, increment, save.
4. Two threads both loaded counter with version=5, nextValue=1042.
5. First thread committed: version=6, nextValue=1043. Success.
6. Second thread: `OptimisticLockException` thrown.
7. A previous developer's "fix" caught the exception with a
   log statement - and then continued using the pre-exception
   value (1042) to create the invoice.
8. Root cause: swallowed `OptimisticLockException` + continuation
   with stale data.

Fix - two parts:

Part 1: Change counter read to pessimistic locking:
```java
SequenceCounter c = em.find(SequenceCounter.class,
    tenantId, LockModeType.PESSIMISTIC_WRITE);
long next = c.getAndIncrement(); // atomic, locked
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Part 2: Unique constraint as defense-in-depth:
```sql
ALTER TABLE invoices
ADD CONSTRAINT uq_tenant_invoice
UNIQUE (tenant_id, invoice_number);
```

> **Code walkthrough:** This Unknown example demonstrates SQL pattern. **KEY MECHANISM:** the database parses, plans, and executes the query; EXPLAIN ANALYZE shows the actual plan. **WHY IT MATTERS:** missing WHERE clause on UPDATE/DELETE affects all rows - no undo without a transaction rollback. **TAKEAWAY: always test destructive SQL in a transaction; use EXPLAIN ANALYZE before deploying.**

**R (Result):** Zero duplicate invoice numbers post-fix. Added a
concurrent integration test:
```java
// CountDownLatch to synchronize 20 concurrent invoice creations
CountDownLatch start = new CountDownLatch(1);
List<Future<Long>> futures = IntStream.range(0, 20)
    .mapToObj(i -> executor.submit(() -> {
        start.await();
        return invoiceService.create(tenantId);
    })).collect(toList());
start.countDown(); // release all threads simultaneously
Set<Long> numbers = futures.stream().map(f -> f.get())
    .collect(toSet());
assertThat(numbers).hasSize(20); // all unique
```
> **Code walkthrough:** This Unknown example demonstrates Java Stream pipeline using Stream. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **TAKEAWAY: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

This test runs in CI and catches any future regression.

*What separates good from great:* The concurrent integration test with
`CountDownLatch` to synchronize thread start - this is the exact kind
of test that catches race conditions.

---

### ⚖️ Comparison Table

| Aspect | Optimistic (@Version) | Pessimistic (FOR UPDATE) | Atomic UPDATE |
|--------|----------------------|--------------------------|----|
| Database lock held? | No | Yes (row lock) | Briefly (single statement) |
| Throughput | High (no blocking) | Lower (blocking) | Highest |
| Conflict rate sweet spot | < 10% | > 20% | Any |
| Application retry needed? | Yes | No (blocking) | No |
| Complex logic in TX | Yes | Yes | No (SQL only) |
| Best for | General CRUD | Booking, allocation | Counter operations |

**The deciding factor:**
Default to optimistic locking. Use pessimistic for booking/allocation.
Use atomic UPDATE for high-throughput counters. Add unique constraints
as defense-in-depth for all cases.

*(Omit: System Design - ★★☆ keyword)*

*(Omit: Diagram - code examples and table are sufficient)*

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



