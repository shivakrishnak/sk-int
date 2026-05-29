---
layout: default
title: "JPA - L3 Schema"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 9
permalink: /jpa/l3-schema/
---

# JPA - L3 Schema

## Schema Generation and Database Migration: Liquibase vs Flyway with JPA

### 🎯 Model Answer

**30 seconds:**
> JPA schema generation (`hbm2ddl.auto`): for development only (create-drop, update). Production:
> use Flyway or Liquibase. Flyway: SQL-based migration scripts, versioned filenames (V1, V2...).
> Liquibase: XML/YAML/JSON changesets, more flexible (rollback support). Both: migrate forward;
> track applied migrations in a history table.

**3 minutes (Senior):**
> Migration tool details:
>
> 1. **hbm2ddl.auto=validate**: on startup, Hibernate validates entity mappings against existing
>    schema. Does NOT modify the schema. Fails fast if mapping is wrong. Use in production alongside
>    Flyway/Liquibase.
>
> 2. **Flyway**: SQL scripts in `db/migration/`. Naming: `V{N}__{description}.sql` (V1, V2...).
>    Applied in order. Applied migrations tracked in `flyway_schema_history` table. Repeatable
>    migrations: `R__{description}.sql` (re-run when content changes). Checksum verification:
>    if an applied script is modified: Flyway detects and fails startup (prevents history tampering).
>
> 3. **Liquibase**: changelog files (XML, YAML, or SQL). Each change: `<changeSet id="..." author="...">`.
>    Changesets tracked in `databasechangelog` table. Supports rollback (`<rollback>` block in
>    changeset). Supports conditions (`runOnChange`, `runAlways`). More expressive than Flyway for
>    complex scenarios.
>
> 4. **JPA + Flyway together**: `spring.jpa.hibernate.ddl-auto=validate`. Flyway creates/updates
>    schema. Hibernate validates entity mappings match the schema. Startup fails if out of sync.

**Blank Mind Recovery:**

**(1) Restate:** "Dev: hbm2ddl.auto=create-drop. Prod: Flyway (V1, V2 SQL scripts) or Liquibase (changesets). JPA: ddl-auto=validate (validates, not modifies). Flyway: flyway_schema_history. Liquibase: databasechangelog."

**(2) First principles:** "Schema changes are irreversible (you can't undelete a column). Version control schema changes just like code. Apply changes incrementally. Track what's applied. Never apply the same change twice."

**(3) Bridge:** "Flyway/Liquibase for database schema is like Git for code. V1 = first commit. V2 = second commit. You can't go back (without explicit rollback). History table = git log. Checksum = git diff to detect tampering."

---

### 📘 Concept Explanation

**Flyway vs Liquibase setup and integration with JPA:**
```
FLYWAY SETUP (Spring Boot auto-configuration):

  # application.properties:
  spring.jpa.hibernate.ddl-auto=validate  # Hibernate validates, Flyway manages schema
  spring.flyway.enabled=true
  spring.flyway.locations=classpath:db/migration
  spring.flyway.baseline-on-migrate=true  # for first-time migration on existing DB
  
  # pom.xml: spring-boot-starter-data-jpa includes flyway-core

  # Migration scripts: src/main/resources/db/migration/
  
  V1__create_users_table.sql:
  CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
  );
  
  V2__create_products_table.sql:
  CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price NUMERIC(19,2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    version INTEGER NOT NULL DEFAULT 0
  );
  
  V3__add_product_index.sql:
  CREATE INDEX idx_products_category ON products(category);
  
  V4__add_users_role_column.sql:
  ALTER TABLE users ADD COLUMN role VARCHAR(50) NOT NULL DEFAULT 'USER';
  UPDATE users SET role = 'USER' WHERE role IS NULL;
  
  # Flyway on startup:
  # 1. Read flyway_schema_history (what's applied).
  # 2. Scan db/migration/ for V*.sql scripts.
  # 3. Apply any not yet in the history table.
  # 4. Record each applied script in flyway_schema_history.

LIQUIBASE SETUP:

  # application.properties:
  spring.jpa.hibernate.ddl-auto=validate
  spring.liquibase.change-log=classpath:db/changelog/db.changelog-master.yaml
  
  # db/changelog/db.changelog-master.yaml:
  databaseChangeLog:
    - include:
        file: db/changelog/001-create-users.yaml
    - include:
        file: db/changelog/002-create-products.yaml
  
  # db/changelog/001-create-users.yaml:
  databaseChangeLog:
    - changeSet:
        id: 001-create-users
        author: team
        changes:
          - createTable:
              tableName: users
              columns:
                - column:
                    name: id
                    type: BIGINT
                    autoIncrement: true
                    constraints:
                      primaryKey: true
                - column:
                    name: email
                    type: VARCHAR(255)
                    constraints:
                      nullable: false
                      unique: true
        rollback:
          - dropTable:
              tableName: users
  
  # Rollback (not native in Flyway without Undo):
  liquibase rollbackCount 1  # or rollback by tag

ADDING COLUMN: SAFE MIGRATION PATTERN:

  # Safe: additive changes (add column with DEFAULT or nullable):
  V5__add_product_sku.sql:
  ALTER TABLE products ADD COLUMN sku VARCHAR(100);
  -- Nullable: no DEFAULT needed for existing rows.
  -- New Java entity field @Column nullable (or Optional).
  
  # Safe: add index CONCURRENTLY (PostgreSQL, no table lock):
  V6__add_products_name_index.sql:
  CREATE INDEX CONCURRENTLY idx_products_name ON products(name);
  -- CONCURRENTLY: no exclusive table lock. Safe for production with live traffic.
  -- Flyway: run in own transaction (or set spring.flyway.mixed=false).
  
  # UNSAFE: renaming a column (breaks existing queries):
  -- BAD:
  ALTER TABLE users RENAME COLUMN email TO email_address;
  -- Breaks: all JPA entities, all native SQL queries referencing 'email'.
  
  -- SAFE rename (backward-compatible, 3-phase migration):
  -- Phase 1: add new column, keep old:
  ALTER TABLE users ADD COLUMN email_address VARCHAR(255);
  UPDATE users SET email_address = email;
  -- Phase 2 (next deploy): update code to use email_address.
  -- Phase 3 (next deploy after all instances updated): drop old column.
```

---

### 💻 Code Example

> **Code walkthrough:** The three-phase rename pattern is the key production migration pattern.
> It avoids downtime by making only additive changes in each deploy.

```java
// WRONG: renaming in entity and DB simultaneously (breaking change):
@Entity
public class User {
    // BAD: renamed field AND DB column simultaneously.
    // If old instances (before deploy) are running: they reference old column 'email'.
    // If new schema (renamed to 'email_address') is deployed first:
    //   old instances fail with ColumnNotFoundException.
    @Column(name = "email_address")  // new name
    private String emailAddress;     // was: email
}
// + V5__rename_email_to_email_address.sql:
// ALTER TABLE users RENAME COLUMN email TO email_address;
// BREAKS: zero-downtime deployment impossible.

// RIGHT: additive migration with column alias during transition:
// Phase 1 migration (deploy 1):
// V5__add_email_address_column.sql:
// ALTER TABLE users ADD COLUMN email_address VARCHAR(255);
// UPDATE users SET email_address = email;

@Entity
public class User {
    @Column(name = "email")
    private String email;       // old: still works in Phase 1
    
    @Column(name = "email_address")
    private String emailAddress; // new: dual-write during transition
}

// Phase 2 (deploy 2): stop writing to 'email', read from 'email_address'.
// Phase 3 (deploy 3): drop 'email' column.
// V6__drop_email_column.sql: ALTER TABLE users DROP COLUMN email;
// @Entity: remove old field.
```

> **Code walkthrough:** The additive migration pattern enables zero-downtime deploys. In Phase 1:
> both columns exist. Old instances use `email`. New instances use `email_address` and dual-write
> to both. In Phase 2: all instances migrated to `email_address`. In Phase 3: the old column is
> dropped. At no point is an instance running against a missing column. The Flyway checksum ensures
> the migration scripts are not modified after being applied.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Never use `ddl-auto=update` in production. Use Flyway or Liquibase for schema migrations.
> Flyway: SQL scripts with versioned names (V1, V2). Spring Boot: auto-applies on startup.
> Set `ddl-auto=validate` with Flyway so Hibernate validates entity mappings match the DB.

---

**Senior / Staff (5+ years):**
> Migration strategy for zero-downtime: only additive changes in each migration (add column, add
> table, add index). Never remove or rename in the same migration as the code change. Three-phase
> rename/remove. For large tables: `ALTER TABLE ADD COLUMN` with `DEFAULT` locks the table in
> PostgreSQL < 11. PostgreSQL 11+: instant ADD COLUMN with constant DEFAULT. Avoid backfill in the
> migration script for 100M+ row tables; use a background job. Index creation: always use
> `CONCURRENTLY` in PostgreSQL (no table lock). Flyway Pro: undo migrations. Liquibase free:
> rollback blocks in changesets.

---

### ⚠️ Common Misconceptions

**Misconception: "`spring.jpa.hibernate.ddl-auto=update` is safe for staging/QA environments."**
`ddl-auto=update` adds missing columns and tables, but NEVER removes columns or tables (safety
mechanism). If an entity field is removed: the DB column remains. If a field is renamed: a new
column is added with the new name AND the old column remains (data not migrated). Over time: the
DB accumulates ghost columns not in any entity. For QA: this causes divergence from production
schema (QA has extra columns, different constraints). Tests pass on QA but fail in production
because the schema is different. Rule: use Flyway/Liquibase everywhere (dev, QA, staging, prod)
so all environments apply the same migration scripts in the same order. Consistent schema across
all environments is the goal.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Flyway startup failure - "Migration checksum mismatch".**
```
Symptom: application fails to start with:
  "FlywayException: Validate failed: Detected failed migration to version 3"
  or: "Migration checksum mismatch for migration version 5"

Root cause: an already-applied migration script (V5__...) was modified after being applied.
  Developer edited the SQL file after it was deployed. Flyway detects the change.
  Flyway refuses to start: prevent applying tampered migrations.

Fix:
  Option 1: Never modify applied migrations. Append new scripts (V6, V7...).
    This is the correct process. Treat applied migrations as immutable.
    
  Option 2: If the modification was intentional and the DB was manually corrected:
    DELETE FROM flyway_schema_history WHERE version = '5';
    Then let Flyway re-apply V5 on next startup.
    WARNING: only if you KNOW the DB state is correct and V5 is safe to re-apply.
    
  Option 3 (repair):
    flyway repair  # resets checksums for failed migrations
    # Use only when the modification was intentional AND DB state is correct.
  
  Prevention:
    Code review gate: migration files must never be modified after merge to main.
    Git pre-commit hook: detect changes to db/migration/ for already-committed files.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Flyway vs Liquibase tradeoffs | 2 minutes |
| ddl-auto=validate purpose | 1 minute |
| Zero-downtime migration strategy | 3 minutes |
| Column rename three-phase | 2 minutes |
| Flyway checksum failure | 1 minute |
| Large table migration | 2 minutes |
| Rollback strategy | 1 minute |

---

**Q1 (design): How do you perform a zero-downtime database migration when renaming a column in production?**

A: Zero-downtime column rename requires three deploys (phases): Phase 1 - Add new column: migration
script adds the new column (nullable or with default). Application updated to write to BOTH the old
and new columns (dual-write). Reads from old column. Deploy. All instances now dual-writing. Phase 2
- Switch reads: once all instances are on Phase 2, update reads to use the new column. Still
dual-writing to both columns. Deploy. Phase 3 - Drop old column: all instances reading from new
column. Migration script drops old column. Application code removes references to old column. Deploy.
Each phase is a separate PR + deploy. The key insight: at no point does an instance reference a
column that doesn't exist. Old and new code can run simultaneously against the same DB schema.

*What separates good from great:* The "schema migration + code change in one PR" anti-pattern.
A single PR: adds a `NOT NULL` column to the products table AND the entity field `@Column(nullable=false)`.
Deployment: DB migration runs first (ALTER TABLE ADD COLUMN NOT NULL). Old application instances
still running (rolling deploy): they try to INSERT products without the new column -> constraint
violation -> crash. Or: code deploys first, accesses new column that doesn't exist -> SQL error.
Either way: partial downtime or errors during the deploy window. Fix: expand-contract pattern.
Expand: add the column nullable, no constraint. Migrate data in background. Contract: once all
instances updated, add the NOT NULL constraint. Always separate schema changes from code changes.

---

---

## Advanced Mapping: @Embeddable, @ElementCollection, and Converter

### 🎯 Model Answer

**30 seconds:**
> `@Embeddable`: value object mapped to columns in the owner entity's table. No own table, no own
> ID. `@ElementCollection`: collection of value objects or primitives - own table with FK back to
> owner. `@Converter`: maps a Java type to a DB column type (e.g., enum to string, JSON to string).
> All three: enrich the JPA object model without extra entity tables.

**3 minutes (Senior):**
> Advanced mapping details:
>
> 1. **@Embeddable**: the address is part of the User row. `@Embedded` in the owner class.
>    `@AttributeOverride`: rename columns when embedding multiple instances of the same type.
>    Updates to the embedded object: tracked by dirty checking (no extra SELECT).
>
> 2. **@ElementCollection**: own join table. Example: `List<String> tags` -> `product_tags` table
>    with `product_id` and `tag` columns. No entity class for the elements. Fetch type: LAZY
>    by default. On entity load: no extra SQL for the collection. On collection access: SELECT
>    from the collection table.
>
> 3. **@Converter**: implement `AttributeConverter<JavaType, DBType>`. Auto-applies with
>    `autoApply=true`. Or: `@Convert(converter=...)` on the field. Common use cases:
>    JSON blob to Map, enum to code (not ordinal), encrypted string, custom date format.
>
> 4. **When to use each**: `@Embeddable` - when the value object logically belongs to the entity
>    (address, money amount). `@ElementCollection` - for simple collections that don't need their
>    own entity (tags, phone numbers). `@Converter` - when the Java type and DB type don't match
>    naturally.

**Blank Mind Recovery:**

**(1) Restate:** "@Embeddable: no table, no ID, columns in owner table. @ElementCollection: own join table, no entity. @Converter: JavaType <-> DBType. @AttributeOverride: rename embeddable columns."

**(2) First principles:** "Not every field needs to be a separate table. Some data belongs together logically. Embeddable: same row, same transaction. ElementCollection: separate table but managed by owner. Converter: Java type system meets DB type system."

**(3) Bridge:** "Embeddable is like a name tag badge that's part of the person. @ElementCollection is a list of sticky notes attached to a document. Converter is the translation layer between your Java type and DB storage format."

---

### 📘 Concept Explanation

**@Embeddable, @ElementCollection, and @Converter patterns:**
```
@EMBEDDABLE (value object mapping):

  // Define the value object:
  @Embeddable
  public class Address {
      @Column(name = "street")
      private String street;
      
      @Column(name = "city")
      private String city;
      
      @Column(name = "country_code")
      private String countryCode;
      
      // No @Id, no @Entity. Part of the owner's table.
  }
  
  // Owner entity:
  @Entity
  public class Customer {
      @Id @GeneratedValue Long id;
      String name;
      
      @Embedded
      private Address shippingAddress;  // columns: street, city, country_code
      
      @Embedded
      @AttributeOverrides({
          @AttributeOverride(name = "street",
              column = @Column(name = "billing_street")),
          @AttributeOverride(name = "city",
              column = @Column(name = "billing_city")),
          @AttributeOverride(name = "countryCode",
              column = @Column(name = "billing_country_code"))
      })
      private Address billingAddress;  // different column names
  }
  
  // DB table: customers
  // Columns: id, name, street, city, country_code,
  //          billing_street, billing_city, billing_country_code
  // One row. No JOIN needed.

@ELEMENTCOLLECTION (collection without entity):

  @Entity
  public class Product {
      @Id @GeneratedValue Long id;
      String name;
      
      // Collection of strings:
      @ElementCollection
      @CollectionTable(
          name = "product_tags",
          joinColumns = @JoinColumn(name = "product_id"))
      @Column(name = "tag")
      private Set<String> tags = new HashSet<>();
      
      // Collection of embeddables:
      @ElementCollection
      @CollectionTable(name = "product_prices",
          joinColumns = @JoinColumn(name = "product_id"))
      private List<PricePoint> historicalPrices = new ArrayList<>();
  }
  
  @Embeddable
  public class PricePoint {
      private BigDecimal price;
      private Instant effectiveFrom;
  }
  
  // DB tables:
  //   product_tags: product_id, tag
  //   product_prices: product_id, price, effective_from
  
  // Behavior: lazy by default.
  //   product.getTags(): SELECT tag FROM product_tags WHERE product_id=?
  //   product.getHistoricalPrices(): SELECT ... FROM product_prices WHERE product_id=?
  
  // Orphan removal: deleting an element from the collection
  //   and saving: DELETE FROM product_tags WHERE product_id=? AND tag=?
  
  // WARNING: @ElementCollection is replaced entirely on update:
  //   Hibernate: DELETE all existing entries, INSERT all current entries.
  //   For large collections: huge DELETE + INSERT load on every save.
  //   Alternative: use @Entity for large or frequently-modified collections.

@CONVERTER (type conversion):

  // Enum to meaningful string (not ordinal):
  @Converter(autoApply = true)
  public class OrderStatusConverter
          implements AttributeConverter<OrderStatus, String> {
      
      @Override
      public String convertToDatabaseColumn(OrderStatus status) {
          return status == null ? null : status.getCode();
          // OrderStatus.PENDING -> "P", OrderStatus.SHIPPED -> "S"
      }
      
      @Override
      public OrderStatus convertToEntityAttribute(String code) {
          if (code == null) return null;
          return OrderStatus.fromCode(code);  // parse from DB code
      }
  }
  // With autoApply=true: applied to ALL OrderStatus fields in ALL entities.
  
  // JSON field (store a Map as JSONB in PostgreSQL):
  @Converter
  public class MapToJsonConverter
          implements AttributeConverter<Map<String, Object>, String> {
      
      private static final ObjectMapper MAPPER = new ObjectMapper();
      
      @Override
      public String convertToDatabaseColumn(Map<String, Object> map) {
          try {
              return map == null ? null : MAPPER.writeValueAsString(map);
          } catch (JsonProcessingException e) {
              throw new IllegalArgumentException("Cannot serialize to JSON", e);
          }
      }
      
      @Override
      public Map<String, Object> convertToEntityAttribute(String json) {
          try {
              return json == null ? null
                  : MAPPER.readValue(json, new TypeReference<>(){});
          } catch (JsonProcessingException e) {
              throw new IllegalArgumentException("Cannot parse JSON", e);
          }
      }
  }
  
  @Entity
  public class Event {
      @Id Long id;
      String type;
      
      @Convert(converter = MapToJsonConverter.class)
      @Column(columnDefinition = "jsonb")
      private Map<String, Object> metadata;
      // Stored as JSON in the DB column.
      // Loaded as Map<String, Object> in Java.
  }
```

---

### 💻 Code Example

> **Code walkthrough:** The ElementCollection replace-all behavior is the key performance trap.
> For small, stable collections it's fine. For large or frequently-modified collections, switch
> to a proper @Entity.

```java
// WRONG: @ElementCollection for a large, frequently-modified collection:
@Entity
public class UserProfile {
    @Id Long id;
    
    @ElementCollection
    @CollectionTable(name = "user_activities")
    private List<UserActivity> activities = new ArrayList<>();
    // PROBLEM: adding ONE activity:
    //   Hibernate: DELETE FROM user_activities WHERE user_id=?  (delete ALL)
    //   INSERT INTO user_activities (user_id, ...) VALUES (?, ?)  (re-insert ALL)
    // For 1000 activities: 1 DELETE + 1000 INSERTs on every add. O(N) writes.
}

// RIGHT: @Entity for frequently-modified or large collections:
@Entity
public class UserActivity {
    @Id @GeneratedValue Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private UserProfile user;
    
    private String action;
    private Instant performedAt;
}

// RIGHT: @ElementCollection for small, stable collections:
@Entity
public class User {
    @Id Long id;
    
    @ElementCollection
    @CollectionTable(name = "user_roles")
    @Column(name = "role")
    private Set<String> roles = new HashSet<>();
    // Typical user has 1-3 roles. Rarely changes.
    // Small set: replace-all is cheap (1 DELETE + 3 INSERTs).
}
```

> **Code walkthrough:** The wrong example uses `@ElementCollection` for `activities`, which grows
> unboundedly. Every time an activity is added: Hibernate deletes all activities and re-inserts
> them all. O(N) writes for an O(1) operation. The correct approach is a proper `@Entity` for
> `UserActivity` with a `@ManyToOne` relationship: adding one activity is a single INSERT. The
> `roles` example shows the right use for `@ElementCollection`: small, stable sets where the
> replace-all behavior is acceptable.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `@Embeddable`: value object, no separate table. `@ElementCollection`: collection (strings or
> embeddables), own join table. `@Converter`: custom Java-to-DB type mapping. Use `@ElementCollection`
> only for small, stable collections. Large/frequently-modified: use a proper `@Entity`.

---

**Senior / Staff (5+ years):**
> `@Embeddable` for money types: `Amount` with `value` (BigDecimal) and `currency` (Currency enum).
> Instead of duplicating `price`, `priceCurrency`, `discount`, `discountCurrency` as separate fields:
> `Amount price` and `Amount discount` (two embedded instances, two `@AttributeOverrides`). For
> `@Converter` with JSON: use a library type for the JSON column (e.g., `JSONB` in PostgreSQL)
> with a `@Converter` to `Map<String, Object>`. Better than `@Entity` for unstructured metadata.
> Watch out: JPQL predicates on converted fields require the `@Converter` to run in Java (the
> WHERE clause cannot reach inside the JSON blob without native SQL or DB-specific functions).

---

### ⚠️ Common Misconceptions

**Misconception: "@ElementCollection elements can have their own ID."**
`@ElementCollection` elements are VALUE OBJECTS (in the DDD sense). They have no identity, no
`@Id`. They cannot be referenced by other entities (no foreign key FROM another table TO the
collection element). They cannot be updated individually: Hibernate replaces the entire collection
on any change. If elements need independent identity (their own `@Id`), independent relationships,
or selective updates: they must be `@Entity` with a proper `@OneToMany` or `@ManyToMany` mapping.
Using `@ElementCollection` for entity-like objects creates the replace-all performance problem and
prevents referential integrity enforcement.

---

### 🚨 Failure Modes and Diagnosis

**Failure: @ElementCollection collection replace-all causes DB bottleneck.**
```
Symptom: adding a tag to a product (previously had 500 tags) causes:
  501 SQL statements logged (1 DELETE + 500 INSERTs).
  Performance: O(N) SQL on every tag add. Slows under load.

Root cause: @ElementCollection replace-all behavior.
  Hibernate: on any modification to the collection:
    DELETE FROM product_tags WHERE product_id = ?
    INSERT INTO product_tags (product_id, tag) VALUES (?, ?) x500

Diagnosis:
  spring.jpa.show-sql=true.
  Count DELETE + INSERT statements on a single collection mutation.
  If N+1 INSERTs for N existing elements: replace-all behavior confirmed.

Fix option 1: Switch to @Entity:
  @Entity class ProductTag {
    @Id Long id;
    @ManyToOne Product product;
    String tag;
  }
  // Adding a tag: one INSERT.
  // Removing a tag: one DELETE.

Fix option 2: If collection size is bounded and small (< 10):
  Keep @ElementCollection. Add size validation: never allow > 10 tags.
  At that size: replace-all is acceptable.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| @Embeddable vs @Entity | 2 minutes |
| @ElementCollection replace-all | 2 minutes |
| @AttributeOverride use case | 1 minute |
| @Converter implementation | 2 minutes |
| JSON field mapping | 1 minute |
| When to use each type | 2 minutes |
| @ElementCollection with @Embeddable | 1 minute |

---

**Q1 (design): When would you choose `@Embeddable` over a separate `@Entity` with a `@OneToOne` relationship?**

A: `@Embeddable` for value objects: logically part of the owner, no identity of its own. Examples:
Address (you don't manage addresses independently - an address means nothing without its owner),
Money amount (value + currency), GPS coordinates. Benefits of `@Embeddable`: no join needed, all
data in one row, no extra SELECT for the value object, dirty checking covers the embedded fields.
`@Entity` + `@OneToOne` when: the related object needs its own identity (other entities reference
it), the related object is shared (multiple parents point to the same address - like a global
address book), or the related object needs its own lifecycle (created before the parent, deleted
independently). Rule: use `@Embeddable` when the value object is always created with its parent and
makes no sense without it. Use `@Entity` when the related object has independent existence.

*What separates good from great:* The `@Embeddable` null handling gotcha. If all columns of an
embedded object are null in the DB row: Hibernate constructs the object but sets all fields to null
- OR: returns null for the entire embedded object (behavior varies by Hibernate version and
`@NotFound` configuration). Safe pattern: (1) design embedded objects to always be non-null (use
default values), (2) or wrap in `Optional` at the application layer, (3) or use `@Column(nullable=false)`
constraints on all embedded columns. For Address that may not be set: use a separate `@OneToOne
(optional=true)` nullable entity reference instead of an embedded object. Null embedded objects
produce NullPointerException in service code unless every embedded field access is null-checked.

