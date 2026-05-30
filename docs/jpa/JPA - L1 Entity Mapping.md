---
layout: default
title: "JPA - L1 Entity Mapping"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 2
permalink: /jpa/l1-entity-mapping/
render_with_liquid: false
---

# JPA - L1 Entity Mapping

## Entity Basics: @Entity, @Id, @Column, and @Table

### 🎯 Model Answer

**30 seconds:**
> `@Entity`: marks a class as a JPA entity (mapped to a DB table). `@Id`: marks the primary key
> field. `@GeneratedValue`: auto-generate PK (IDENTITY: DB auto-increment, SEQUENCE: DB sequence,
> UUID: client-generated UUID). `@Column`: customize column mapping (name, nullable, length).
> `@Table`: customize table name. Without `@Column` or `@Table`: JPA uses field/class names as
> column/table names.

**3 minutes (Senior):**
> Entity mapping fundamentals:
>
> 1. **@Entity requirements**: class must be non-final (Hibernate creates subclass proxies), have
>    a no-arg constructor (public or protected), have an `@Id` field. Inner classes, enums, and
>    interfaces cannot be entities.
>
> 2. **@GeneratedValue strategies**: `IDENTITY` (MySQL AUTO_INCREMENT, PostgreSQL SERIAL):
>    Hibernate must INSERT before it knows the ID. Disables JDBC batch inserts (each insert is
>    executed separately to get the generated ID). `SEQUENCE` (PostgreSQL, Oracle): Hibernate
>    pre-allocates ID blocks from a DB sequence. Batch inserts work. Preferred for bulk insertion.
>    `UUID`: client generates UUID before INSERT. Works well with batching.
>
> 3. **@Column customization**: `nullable = false` -> `NOT NULL` constraint (with ddl-auto).
>    `unique = true` -> `UNIQUE` constraint. `length = 100` -> `VARCHAR(100)` for DDL.
>    `columnDefinition`: raw SQL type override (e.g., `TEXT`, `JSONB`).
>
> 4. **Embedded vs column mapping**: `@Embedded`/`@Embeddable`: value objects embedded in the
>    same table (no foreign key). `@Column`: primitive or String fields. `@Enumerated(EnumType.STRING)`:
>    enum stored as string in DB.

**Blank Mind Recovery:**

**(1) Restate:** "Entity: non-final class, no-arg constructor, @Id field. IDENTITY: auto-increment (no batching). SEQUENCE: pre-allocated IDs (batching works). @Column: customize name/nullable/length. @Enumerated(STRING): store enum as string."

**(2) First principles:** "A DB table has rows (records) and columns (fields). An entity maps a class to a table, fields to columns, and instances to rows. Annotations describe the mapping; Hibernate reads them to generate SQL."

**(3) Bridge:** "Entity mapping is like a passport translation guide. @Entity: 'this class is a traveler.' @Id: 'this field is the passport number.' @Column: 'this field's name in the foreign DB is...'. Hibernate reads the guide to translate between Java and SQL."

---

### 📘 Concept Explanation

**Entity annotation reference:**
```
MINIMAL ENTITY:

  @Entity  // required
  public class Product {
      @Id
      @GeneratedValue(strategy = GenerationType.IDENTITY)
      private Long id;  // auto-increment
      
      private String name;    // column: name (default: field name)
      private BigDecimal price; // column: price
      
      protected Product() {}  // required: no-arg constructor (protected ok)
      
      public Product(String name, BigDecimal price) {
          this.name = name;
          this.price = price;
      }
  }
  // Table: product (lowercase class name, snake_case with Hibernate default naming)
  // Or: configure spring.jpa.hibernate.naming.physical-strategy for naming convention

CUSTOMIZED ENTITY:

  @Entity
  @Table(name = "products",
         uniqueConstraints = @UniqueConstraint(columnNames = {"sku"}))
  public class Product {
      
      @Id
      @GeneratedValue(strategy = GenerationType.SEQUENCE,
                      generator = "product_seq")
      @SequenceGenerator(name = "product_seq",
                         sequenceName = "product_id_seq",
                         allocationSize = 50)  // pre-allocate 50 IDs at once
      private Long id;
      
      @Column(name = "product_name", nullable = false, length = 255)
      private String name;
      
      @Column(name = "unit_price", precision = 10, scale = 2)
      private BigDecimal price;
      
      @Column(columnDefinition = "TEXT")
      private String description;
      
      @Enumerated(EnumType.STRING)  // stored as "ACTIVE", "INACTIVE" (not 0, 1)
      @Column(nullable = false, length = 20)
      private ProductStatus status;
      
      @Column(name = "created_at", updatable = false)
      private Instant createdAt;
      
      @Column(name = "updated_at")
      private Instant updatedAt;
      
      @PrePersist
      private void onPersist() {
          createdAt = Instant.now();
          updatedAt = createdAt;
      }
      
      @PreUpdate
      private void onUpdate() {
          updatedAt = Instant.now();
      }
  }

@GENERATEDVALUE STRATEGIES COMPARED:

  IDENTITY (auto-increment):
    DB generates ID after INSERT.
    Hibernate: cannot know ID until after INSERT.
    Batch insert impossible: each INSERT executed individually to get ID.
    Good for: low-volume inserts, simple setup.
    
  SEQUENCE:
    DB sequence pre-allocates IDs in blocks.
    allocationSize=50: one DB sequence call gets 50 IDs.
    Hibernate assigns IDs locally (1, 2, 3...) before INSERT.
    Batch insert works: IDs known before INSERT.
    Good for: high-volume bulk inserts, PostgreSQL/Oracle.
    
  UUID (client-generated):
    @Id @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(updatable = false, nullable = false, columnDefinition = "VARCHAR(36)")
    private String id;
    
    UUID assigned before INSERT: batching works.
    No DB sequence needed.
    Larger index size (36 bytes vs 8 bytes for Long).
    Random UUIDs (UUID v4): index fragmentation on insertion (B-tree re-balancing).
    Sequential UUIDs (UUID v7): better index performance.

ENUMTYPE.ORDINAL VS ENUMTYPE.STRING:

  // BAD: EnumType.ORDINAL stores enum index (0, 1, 2...)
  @Enumerated(EnumType.ORDINAL)  // stores 0 for ACTIVE, 1 for INACTIVE
  private OrderStatus status;
  // Problem: if enum is reordered or values added/removed:
  //   existing DB values become wrong.
  //   PENDING=0 may become ACTIVE=0 after a rename.
  //   Data silently corrupted.
  
  // GOOD: EnumType.STRING stores name
  @Enumerated(EnumType.STRING)  // stores "ACTIVE", "INACTIVE"
  @Column(length = 20)
  private OrderStatus status;
  // Enum can be reordered, new values added safely.
  // DB value is human-readable.
```

---

### 💻 Code Example

> **Code walkthrough:** The comparison between IDENTITY and SEQUENCE shows why bulk inserts need
> SEQUENCE. The ORDINAL vs STRING enum example shows a common data corruption risk.

```java
// SEQUENCE STRATEGY FOR BULK INSERT PERFORMANCE:

// BAD: IDENTITY strategy disables batch inserts:
@Entity
public class LogEntry {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)  // auto-increment
    private Long id;
    private String message;
}

// Even with batch_size=50 configured:
for (int i = 0; i < 10_000; i++) {
    em.persist(new LogEntry("msg " + i));
}
// Hibernate: 10,000 individual INSERT statements (cannot batch).
// Each INSERT: round-trip to DB for generated ID.
// Performance: slow at scale.

// GOOD: SEQUENCE strategy enables batch inserts:
@Entity
public class LogEntry {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE,
                    generator = "log_seq")
    @SequenceGenerator(name = "log_seq",
                       sequenceName = "log_entry_seq",
                       allocationSize = 100)  // fetch 100 IDs at once
    private Long id;
    private String message;
}

// application.properties:
// spring.jpa.properties.hibernate.jdbc.batch_size=100
// spring.jpa.properties.hibernate.order_inserts=true

for (int i = 0; i < 10_000; i++) {
    em.persist(new LogEntry("msg " + i));
}
// Hibernate: fetches IDs from sequence in batches of 100.
// Inserts: batched into groups of 100 (JDBC batch statements).
// Round-trips: 200 (100 seq fetches + 100 insert batches) vs 10,000.
// Performance: ~50x faster than IDENTITY for bulk inserts.
```

> **Code walkthrough:** With IDENTITY, every persist triggers an immediate INSERT to get the
> generated ID from the DB - batching is impossible because the ID is unknown before the INSERT.
> With SEQUENCE and `allocationSize=100`, Hibernate fetches 100 IDs per DB roundtrip, assigns them
> locally, and batches the actual INSERTs. For 10,000 inserts: 100 roundtrips instead of 10,000.
> The `order_inserts=true` setting groups inserts of the same entity type together for better
> batching.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `@Entity` + `@Id` minimum. Use `@GeneratedValue(IDENTITY)` for simple cases (MySQL/PostgreSQL
> serial). Use `@Column(nullable=false)` for required fields. Always use `@Enumerated(EnumType.STRING)`.
> Use `@Table(name=...)` when the class name doesn't match the DB convention.

---

**Senior / Staff (5+ years):**
> SEQUENCE with `allocationSize` matching your expected write throughput. UUID v7 for distributed
> systems where you need DB-portable globally unique IDs without sequence coordination. `@PrePersist`
> and `@PreUpdate` for audit fields (simpler than `@EntityListeners`). `columnDefinition = "JSONB"`
> for PostgreSQL JSON columns. `updatable = false` on `createdAt` prevents accidental updates.

---

### ⚠️ Common Misconceptions

**Misconception: "Using `@GeneratedValue(IDENTITY)` is the simplest and best default."**
IDENTITY is the simplest setup, but it disables JDBC batch inserts. For applications that insert
large numbers of entities (event sourcing, audit logs, bulk data import): IDENTITY causes severe
performance degradation (one INSERT roundtrip per entity). SEQUENCE with `allocationSize` matching
your insert volume is the high-performance default for PostgreSQL (which has efficient native sequences).
For MySQL (which doesn't support sequences): `TABLE` generation strategy or UUID. The "simplest
setup" advice is correct only for low-volume inserts.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Bulk insert of 100,000 records takes 5 minutes.**
```
Symptom: importing 100,000 records via JPA persist: 5 minutes.
  Expected: < 30 seconds.

Diagnosis:
  Enable hibernate.show_sql=true.
  Log: 100,000 individual INSERT statements, one at a time.
  Root cause: IDENTITY strategy + batch_size not configured.

Fix:
  1. Switch to SEQUENCE strategy (allocationSize=500 for bulk import).
  2. Configure batch_size:
     spring.jpa.properties.hibernate.jdbc.batch_size=500
     spring.jpa.properties.hibernate.order_inserts=true
  3. Periodic flush+clear to prevent persistence context memory growth:
     for (int i = 0; i < records.size(); i++) {
         em.persist(records.get(i));
         if (i % 500 == 0) {
             em.flush();  // send batched inserts to DB
             em.clear();  // clear persistence context to free memory
         }
     }
  4. Use @Transactional on the import method (all 100K in one transaction).
  
  Result: 100K inserts in ~5 seconds (60x improvement).
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| @Entity requirements | 1 minute |
| IDENTITY vs SEQUENCE | 2 minutes |
| Batch insert with SEQUENCE | 2 minutes |
| @Column annotations | 1 minute |
| ORDINAL vs STRING enum | 1 minute |
| @PrePersist/@PreUpdate | 1 minute |
| UUID as primary key | 1 minute |

---

**Q1 (generation): Why does `GenerationType.IDENTITY` prevent batch inserts, and how do you fix it?**

A: IDENTITY relies on DB auto-increment (MySQL: AUTO_INCREMENT, PostgreSQL: SERIAL/IDENTITY column).
The DB generates the ID at INSERT time and returns it. Hibernate needs the ID immediately after
persist: it calls `em.persist(entity)`, entity has no ID, Hibernate must INSERT NOW and read the
generated ID. With batch inserts: Hibernate would accumulate 100 entities, send them in one JDBC
batch statement, but each entity needs an ID before the batch is sent. Impossible - circular dependency.
Fix: SEQUENCE strategy. A DB sequence pre-allocates IDs in blocks (`allocationSize`). Hibernate
fetches a block (e.g., 100 IDs) with one query, assigns IDs locally, then inserts all 100 entities
in a JDBC batch.

*What separates good from great:* The Hibernate-generated sequence gap behavior: with `allocationSize=50`,
if the application restarts after allocating sequence values 101-150 but only using 101-120: values
121-150 are wasted (IDs gap in the table). This is normal and expected with sequence-based generation.
The ID gaps are harmless for most applications (IDs are surrogates, not business keys). If gap-free
IDs are required for business reasons: don't use JPA sequence generation; generate IDs explicitly
from a business sequence. Understanding this gap behavior prevents unnecessary alarm when DBAs
question the "missing" IDs.

---

---

## Relationship Mappings: @OneToMany, @ManyToOne, @ManyToMany

### 🎯 Model Answer

**30 seconds:**
> `@OneToMany`: one entity owns a collection of related entities (e.g., Order -> OrderItems).
> `@ManyToOne`: the "many" side, owns the foreign key column. `@ManyToMany`: join table.
> `mappedBy`: tells JPA which side doesn't own the foreign key (no column on this side).
> The owning side (no `mappedBy`) controls the foreign key. The inverse side (`mappedBy`):
> for navigation only.

**3 minutes (Senior):**
> Bidirectional relationships and ownership:
>
> 1. **Owning side**: the entity that has the foreign key column (ManyToOne side, or the entity
>    with the join column). JPA looks at the owning side to generate INSERT/UPDATE for the relationship.
>    If you only set the `mappedBy` side: the foreign key is NOT saved.
>
> 2. **@OneToMany best practices**: always use `@OneToMany(mappedBy = "...")` with the FK on the
>    child (no join table). `@JoinColumn` on the `@OneToMany` side creates a join table-less
>    unidirectional mapping but uses a separate UPDATE statement. Use bidirectional (@ManyToOne +
>    @OneToMany mapped by) for efficiency.
>
> 3. **@ManyToMany**: creates a join table. Almost always better replaced with a join entity
>    (a class representing the join table) to add attributes to the relationship or to avoid
>    Hibernate's inefficient join table management.
>
> 4. **CascadeType**: `PERSIST`, `MERGE`, `REMOVE`, `REFRESH`, `DETACH`, `ALL`. Use carefully.
>    `CascadeType.REMOVE` on `@OneToMany`: deleting parent deletes all children. Often dangerous.
>    Use `orphanRemoval = true` for removing children when removed from the collection.

**Blank Mind Recovery:**

**(1) Restate:** "ManyToOne: owns the FK column. OneToMany(mappedBy): no column here, navigation only. Set BOTH sides for bidirectional. CascadeType.PERSIST: persisting parent also persists children. orphanRemoval: child removed from collection -> DELETE child."

**(2) First principles:** "A foreign key lives in one table. The entity mapped to that table is the 'owning side' of the relationship. The other side navigates but doesn't own data. JPA: always set the owning side to actually persist the relationship."

**(3) Bridge:** "A department has many employees. The employee table has the department_id FK (owning side). If you only set department.getEmployees().add(employee) without setting employee.setDepartment(dept): the FK column stays null. You must set the owning side."

---

### 📘 Concept Explanation

**Relationship mapping patterns:**
```
BIDIRECTIONAL @OneToMany / @ManyToOne (recommended):

  @Entity
  public class Order {
      @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
      private Long id;
      
      @OneToMany(mappedBy = "order",  // "order" = field name in OrderItem
                 cascade = CascadeType.PERSIST,
                 orphanRemoval = true)
      private List<OrderItem> items = new ArrayList<>();
      
      // Helper method: always set BOTH sides:
      public void addItem(OrderItem item) {
          items.add(item);
          item.setOrder(this);  // set owning side!
      }
      
      public void removeItem(OrderItem item) {
          items.remove(item);
          item.setOrder(null);  // unset owning side
          // orphanRemoval=true: item will be deleted from DB
      }
  }
  
  @Entity
  public class OrderItem {
      @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
      private Long id;
      
      @ManyToOne(fetch = FetchType.LAZY)  // important: always LAZY for ManyToOne
      @JoinColumn(name = "order_id")  // FK column in order_items table
      private Order order;
      
      private String productName;
      private int quantity;
  }

BIDIRECTIONAL MISTAKE (only setting inverse side):

  // BAD: only setting the mappedBy side:
  Order order = new Order();
  OrderItem item = new OrderItem("Product A", 1);
  order.getItems().add(item);  // adds to collection (inverse side)
  // item.setOrder(order) NOT CALLED
  
  em.persist(order);
  // Result: item.order_id = NULL in DB.
  // JPA: looks at owning side (OrderItem.order) for FK value.
  // OrderItem.order = null -> FK stored as NULL.
  
  // GOOD: use the helper method that sets both sides:
  order.addItem(item);  // sets both: items.add(item) + item.setOrder(this)
  em.persist(order);
  // Result: item.order_id = order.id (correct FK saved).

@MANYTOMANY: REPLACE WITH JOIN ENTITY:

  // BAD: @ManyToMany (Hibernate-managed join table):
  @Entity
  public class Student {
      @ManyToMany
      @JoinTable(name = "student_course",
                 joinColumns = @JoinColumn(name = "student_id"),
                 inverseJoinColumns = @JoinColumn(name = "course_id"))
      private List<Course> courses;
  }
  // Problems:
  //   Cannot add attributes to the relationship (enrollment date, grade).
  //   Hibernate join table operations: often inefficient.
  //   Removing one course: Hibernate deletes ALL rows for this student, re-inserts the rest.
  
  // GOOD: explicit join entity:
  @Entity
  @Table(name = "student_course")
  public class Enrollment {
      @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
      private Long id;
      
      @ManyToOne(fetch = FetchType.LAZY)
      @JoinColumn(name = "student_id")
      private Student student;
      
      @ManyToOne(fetch = FetchType.LAZY)
      @JoinColumn(name = "course_id")
      private Course course;
      
      private LocalDate enrolledAt;  // relationship attribute
      private BigDecimal grade;
  }
  // Benefits: relationship has its own attributes, operations are explicit,
  //           no Hibernate join table management quirks.

CASCADETYPES REFERENCE:

  CascadeType.PERSIST:
    em.persist(parent) -> also persists all children in the collection.
    Use: when children should always be persisted with the parent.
    
  CascadeType.MERGE:
    em.merge(parent) -> also merges all children.
    Use: when updating a detached entity graph.
    
  CascadeType.REMOVE:
    em.remove(parent) -> also removes all children (DELETE per child).
    Use: carefully. Can cause massive unintended deletes.
    Alternative: ON DELETE CASCADE at DB level (more efficient).
    
  orphanRemoval = true:
    Child removed from parent's collection -> DELETE the child.
    Different from REMOVE: REMOVE triggers when parent is deleted.
    orphanRemoval: triggers when child is removed from the collection.
    
  CascadeType.ALL:
    Includes all cascade types.
    Often too broad: enables REMOVE cascade which is dangerous.
    Prefer explicit cascade types: {PERSIST, MERGE} for most cases.
```

---

### 💻 Code Example

> **Code walkthrough:** The `addItem` / `removeItem` helper method pattern is the correct way to
> maintain bidirectional relationships. The join entity pattern shows why `@ManyToMany` should be
> replaced in production code.

```java
// BIDIRECTIONAL RELATIONSHIP WITH HELPER METHODS:

@Entity
public class BlogPost {
    @Id @GeneratedValue(strategy = GenerationType.SEQUENCE)
    private Long id;
    private String title;
    
    @OneToMany(mappedBy = "post",
               cascade = {CascadeType.PERSIST, CascadeType.MERGE},
               orphanRemoval = true,
               fetch = FetchType.LAZY)
    private List<Comment> comments = new ArrayList<>();
    
    // Helper: always set both sides:
    public void addComment(Comment comment) {
        comments.add(comment);
        comment.setPost(this);
    }
    
    public void removeComment(Comment comment) {
        comments.remove(comment);
        comment.setPost(null);
        // orphanRemoval=true: on flush, DELETE FROM comments WHERE id=?
    }
}

@Entity
public class Comment {
    @Id @GeneratedValue(strategy = GenerationType.SEQUENCE)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)  // always LAZY for ManyToOne
    @JoinColumn(name = "post_id", nullable = false)
    private BlogPost post;
    
    private String content;
    
    // equals/hashCode based on business key (not id):
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Comment)) return false;
        // Use a business key that exists before persist (id may be null):
        Comment c = (Comment) o;
        return content != null && content.equals(c.content);
    }
    
    @Override
    public int hashCode() {
        return getClass().hashCode();  // stable hashCode (entity lifecycle)
    }
}
```

> **Code walkthrough:** The `addComment` and `removeComment` helper methods maintain both sides
> of the bidirectional relationship. The `@ManyToOne(fetch = FetchType.LAZY)` is critical: eager
> loading on the "many" side means every Comment load also loads its BlogPost (N+1 risk). The
> `equals/hashCode` implementation uses a business key rather than ID because the ID may be null
> before `persist()` - using null ID in a HashMap (which `List.remove()` needs) causes subtle bugs.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Bidirectional: `@OneToMany(mappedBy=...)` + `@ManyToOne`. Always set both sides with a helper
> method. FK is on the `@ManyToOne` side. Use `orphanRemoval = true` to delete children removed
> from the collection. Avoid `@ManyToMany`: use a join entity instead.

---

**Senior / Staff (5+ years):**
> `equals/hashCode` on entities is tricky: ID-based equals breaks in `Set` or `List.remove()` when
> ID is still null (before persist). The "entity type as hashCode" pattern from the Hibernate docs
> is the safest default. Performance: `FetchType.LAZY` on all associations by default. EAGER is
> the source of most JPA performance problems. `CascadeType.REMOVE` vs `orphanRemoval`: the former
> triggers on `em.remove(parent)`, the latter on removing from the collection - choose based on
> the business requirement.

---

### ⚠️ Common Misconceptions

**Misconception: "Setting the `mappedBy` side of the relationship persists the relationship."**
The `mappedBy` side is the inverse side: it has no FK column and JPA ignores it for persistence.
Example: `order.getItems().add(item)` where `items` is `mappedBy = "order"`. This modifies the
Java collection but does NOT set the `item.order` field (which is the owning side with the FK column).
At flush: `item.order_id = NULL` in the DB. The fix: always use a helper method that sets both
`items.add(item)` AND `item.setOrder(this)`. This is the most common relationship mapping bug for
developers new to JPA.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Foreign key column is NULL after persist.**
```
Symptom: persist Order with Items. Items saved in DB but order_id = NULL.
  
Diagnosis:
  Check: is item.setOrder(order) called?
  Hibernate: looks at @ManyToOne (owning side) for FK value.
  If not set: FK = NULL.
  
Fix:
  Use helper method (addItem) that sets both sides.
  Enable spring.jpa.show-sql=true to see the INSERT statement:
    INSERT INTO order_items (order_id, product_name, quantity, id)
    VALUES (NULL, 'Product A', 1, 1)  // NULL confirms missing owning side set
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Owning vs inverse side | 2 minutes |
| mappedBy meaning | 2 minutes |
| Why FK is NULL | 1 minute |
| CascadeType.REMOVE risk | 1 minute |
| orphanRemoval | 1 minute |
| @ManyToMany problems | 1 minute |
| equals/hashCode on entities | 1 minute |

---

**Q1 (mapping): What is the owning side of a JPA relationship and why does it matter?**

A: The owning side is the entity that has the foreign key column in the DB table. For `@ManyToOne`:
always the owning side (FK is in the "many" table). For `@OneToOne`: whichever side has `@JoinColumn`.
It matters because JPA only reads the owning side to generate INSERT/UPDATE for the relationship.
The `mappedBy` side is navigation-only; changes to it are ignored by JPA's dirty checking. If you
only add an entity to the `@OneToMany` (inverse/mappedBy) collection without setting the `@ManyToOne`
(owning side) field: the FK is stored as NULL. Correct approach: always set the owning side, ideally
via a helper method that sets both sides simultaneously for bidirectional consistency.

*What separates good from great:* The performance implication of bidirectional vs unidirectional
OneToMany: a unidirectional `@OneToMany` with `@JoinColumn` (no mappedBy) is surprisingly inefficient.
Hibernate manages the FK by: (1) INSERTing the child with FK=NULL, then (2) UPDATEing the child
to set the FK. Two SQL operations per child. The bidirectional version (with mappedBy) has the FK
set during INSERT (one SQL per child). This is a significant difference for bulk operations: 10,000
children = 10,000 extra UPDATEs with unidirectional OneToMany. Always use bidirectional OneToMany
with mappedBy for entities you insert frequently.

---

---

## Inheritance Mapping Strategies: SINGLE_TABLE, JOINED, TABLE_PER_CLASS

### 🎯 Model Answer

**30 seconds:**
> JPA supports three inheritance strategies: `SINGLE_TABLE` (all subclasses in one table with a
> discriminator column), `JOINED` (each class has its own table, joined on query), `TABLE_PER_CLASS`
> (each concrete class has its own table with all columns). SINGLE_TABLE: fastest queries, wastes
> space (null columns). JOINED: normalized, slower queries (JOINs). TABLE_PER_CLASS: no polymorphic
> queries.

**3 minutes (Senior):**
> Inheritance strategy comparison:
>
> 1. **SINGLE_TABLE**: one table for all subclasses. Discriminator column (e.g., `dtype`) identifies
>    the type. Subclass-specific columns are nullable for other subclasses. Fast: no JOINs. Bad:
>    table has many null columns; impossible to add NOT NULL constraints to subclass columns.
>
> 2. **JOINED**: parent class in one table, each subclass in its own table with only the
>    subclass-specific columns (and a FK to the parent table). Queries for a specific subclass: one
>    JOIN. Polymorphic queries (fetch all `Payment`): OUTER JOIN across all subclass tables. Normalized.
>    Slower for polymorphic queries.
>
> 3. **TABLE_PER_CLASS**: each concrete class has its own table with ALL columns (inherited + own).
>    No inheritance relationship at the DB level. Polymorphic queries: UNION ALL across all tables.
>    Very slow. `@GeneratedValue` doesn't work with IDENTITY (no shared sequence). Almost always avoid.
>
> 4. **Recommendation**: SINGLE_TABLE for wide but sparse hierarchies (few subclasses, moderate
>    columns). JOINED for deep hierarchies where normalization matters or where subclass tables need
>    constraints. TABLE_PER_CLASS: avoid in most cases.

**Blank Mind Recovery:**

**(1) Restate:** "SINGLE_TABLE: one table, discriminator column, fast, nullable columns. JOINED: parent + child tables, JOIN on query, normalized, slower polymorphic. TABLE_PER_CLASS: separate tables, UNION for polymorphic, slowest. Default: SINGLE_TABLE."

**(2) First principles:** "Inheritance in Java: parent/child relationship. SQL: no native inheritance. Three solutions: pack all into one table (SINGLE_TABLE), normalize into separate tables (JOINED), or duplicate columns (TABLE_PER_CLASS). Each trades space, query complexity, and constraint flexibility."

**(3) Bridge:** "Inheritance strategies are like storing family member information. SINGLE_TABLE: one spreadsheet with all possible columns for everyone (many blank cells). JOINED: one sheet per role, all linked by ID. TABLE_PER_CLASS: one completely separate spreadsheet per family role, all columns duplicated."

---

### 📘 Concept Explanation

**Inheritance strategy comparison:**
```
SINGLE_TABLE (default when no strategy specified):

  @Entity
  @Inheritance(strategy = InheritanceType.SINGLE_TABLE)
  @DiscriminatorColumn(name = "payment_type",
                       discriminatorType = DiscriminatorType.STRING)
  public abstract class Payment {
      @Id @GeneratedValue private Long id;
      private BigDecimal amount;
      private Instant createdAt;
  }
  
  @Entity
  @DiscriminatorValue("CREDIT_CARD")
  public class CreditCardPayment extends Payment {
      private String cardNumber;
      private String cvv;
      // Both columns: nullable for non-CC payments
  }
  
  @Entity
  @DiscriminatorValue("BANK_TRANSFER")
  public class BankTransferPayment extends Payment {
      private String accountNumber;
      private String routingNumber;
  }
  
  DB table: payments
  | id | amount | payment_type  | card_number | cvv  | account_number | routing_number |
  |----|--------|---------------|-------------|------|----------------|----------------|
  | 1  | 100.00 | CREDIT_CARD   | 4111...     | 123  | NULL           | NULL           |
  | 2  | 50.00  | BANK_TRANSFER | NULL        | NULL | 123456789      | 021000021      |
  
  Query all payments: SELECT * FROM payments (no JOIN, fast)
  Query credit card only: SELECT * FROM payments WHERE payment_type = 'CREDIT_CARD'
  Problem: cannot add NOT NULL to card_number (would fail for BANK_TRANSFER rows).

JOINED STRATEGY:

  @Entity
  @Inheritance(strategy = InheritanceType.JOINED)
  public abstract class Payment {
      @Id @GeneratedValue private Long id;
      private BigDecimal amount;
  }
  
  @Entity
  @Table(name = "credit_card_payments")
  public class CreditCardPayment extends Payment {
      private String cardNumber;  // can be NOT NULL (only CC rows in this table)
      private String cvv;
  }
  
  DB tables:
    payments: id, amount
    credit_card_payments: id (FK -> payments.id), card_number, cvv
    bank_transfer_payments: id (FK -> payments.id), account_number, routing_number
  
  Query CreditCardPayment by id:
    SELECT p.id, p.amount, c.card_number, c.cvv
    FROM payments p
    JOIN credit_card_payments c ON c.id = p.id
    WHERE p.id = 1
  
  Polymorphic query (all payments):
    SELECT p.id, p.amount, c.card_number, c.cvv, b.account_number, b.routing_number
    FROM payments p
    LEFT OUTER JOIN credit_card_payments c ON c.id = p.id
    LEFT OUTER JOIN bank_transfer_payments b ON b.id = p.id
  
  With many subclasses: polymorphic query = many LEFT JOINs = slow.

TABLE_PER_CLASS (avoid):

  @Entity
  @Inheritance(strategy = InheritanceType.TABLE_PER_CLASS)
  public abstract class Payment { ... }
  
  DB tables:
    credit_card_payments: id, amount, card_number, cvv  // ALL columns
    bank_transfer_payments: id, amount, account_number, routing_number
  
  Polymorphic query (all payments):
    SELECT id, amount, 'CC' AS type FROM credit_card_payments
    UNION ALL
    SELECT id, amount, 'BT' AS type FROM bank_transfer_payments
  
  UNION ALL: slow, no index optimization across tables.
  ID uniqueness: IDENTITY strategy doesn't work (each table has its own sequence).
  Almost always replaced by SINGLE_TABLE or JOINED.

STRATEGY SELECTION:

  Use SINGLE_TABLE when:
    - Few subclasses (2-5)
    - Subclass-specific columns are sparse (few, nullable)
    - Polymorphic queries are frequent (performance matters)
    
  Use JOINED when:
    - Many subclasses with many own columns
    - Subclass tables need NOT NULL constraints
    - Normalized schema is required (DBA requirement)
    - Polymorphic queries are infrequent
    
  Avoid TABLE_PER_CLASS:
    - Almost all cases (UNION ALL is slow, ID management complex)
```

---

### 💻 Code Example

> **Code walkthrough:** The SINGLE_TABLE example shows the discriminator column mechanism.
> The strategy selection shows concrete DB structure differences.

```java
// SINGLE_TABLE INHERITANCE (most common, recommended default):

@Entity
@Table(name = "notifications")
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "notification_type",
                     discriminatorType = DiscriminatorType.STRING,
                     length = 20)
public abstract class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    private Long id;
    
    @Column(nullable = false)
    private Long userId;
    
    @Column(nullable = false)
    private String message;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private NotificationStatus status;
    
    private Instant createdAt;
}

@Entity
@DiscriminatorValue("EMAIL")
public class EmailNotification extends Notification {
    @Column(name = "to_address")  // nullable for non-email notifications
    private String toAddress;
    
    @Column(name = "subject")
    private String subject;
}

@Entity
@DiscriminatorValue("SMS")
public class SmsNotification extends Notification {
    @Column(name = "phone_number")  // nullable for non-SMS notifications
    private String phoneNumber;
}

// Usage: polymorphic repository queries work without JOIN:
@Repository
public interface NotificationRepository
    extends JpaRepository<Notification, Long> {
    
    // Returns all notifications (any type):
    List<Notification> findByUserId(Long userId);
    
    // Returns only EmailNotification subtypes:
    List<EmailNotification> findByUserIdAndToAddressNotNull(Long userId);
    
    // Spring Data detects the subtype and adds WHERE notification_type = 'EMAIL':
}
```

> **Code walkthrough:** The `notifications` table has a `notification_type` discriminator column.
> JPA uses this to instantiate the correct subclass when loading. Spring Data JPA handles
> polymorphic queries: `findByUserId()` returns a mix of `EmailNotification` and `SmsNotification`
> instances from the single table. The `toAddress` and `phoneNumber` columns are nullable for rows
> of other subtypes - this is the SINGLE_TABLE trade-off: cannot enforce NOT NULL on subclass columns.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Three strategies: SINGLE_TABLE (one table, discriminator), JOINED (one table per class level),
> TABLE_PER_CLASS (one table per concrete class). Default is SINGLE_TABLE. Use SINGLE_TABLE unless
> you need NOT NULL on subclass columns (then use JOINED). Avoid TABLE_PER_CLASS.

---

**Senior / Staff (5+ years):**
> Avoid deep inheritance hierarchies with JPA entirely when possible. Composition over inheritance
> is easier to query and maintain. When inheritance is unavoidable: SINGLE_TABLE for small, shallow
> hierarchies; JOINED for large hierarchies needing normalization. TABLE_PER_CLASS is almost always
> wrong. If the hierarchy grows: consider refactoring to a `type` discriminator column without
> inheritance (just a `type` field with subtype-specific JSON/JSONB columns for the extra attributes).

---

### ⚠️ Common Misconceptions

**Misconception: "JOINED is always better because it's normalized."**
Normalization is correct in theory but JOINED has severe performance consequences for polymorphic
queries. A polymorphic query against a JOINED hierarchy with 10 subclasses generates a SQL query
with 10 LEFT OUTER JOINs. On a large dataset: the query optimizer struggles; plans become
unpredictable. SINGLE_TABLE eliminates all JOINs for both specific and polymorphic queries. The
nullable-column tradeoff of SINGLE_TABLE is often acceptable in practice: the nullable columns are
rarely large (mainly IDs and short strings). The NOT NULL constraint requirement is the real
signal to use JOINED; not normalization purity.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Polymorphic query with JOINED strategy generates N+1 queries.**
```
Symptom: loading 100 Notifications via JOINED strategy:
  SQL log shows 201 queries (1 SELECT + 1 per EmailNotification + 1 per SmsNotification).

Root cause: Hibernate executes a SELECT for the parent table, then a SELECT per
  subtype row to fetch the subtype-specific columns.
  
Diagnosis:
  Enable spring.jpa.show-sql=true.
  Count queries: should be 1 for SINGLE_TABLE, N+1 for JOINED with lazy subtype loading.

Fix option 1: switch to SINGLE_TABLE (eliminates the JOINs entirely).
  
Fix option 2: JOINED but with batch loading:
  @Entity
  @Inheritance(strategy = InheritanceType.JOINED)
  @org.hibernate.annotations.BatchSize(size = 50)
  public abstract class Notification { ... }
  // Hibernate fetches subtypes in batches of 50 instead of 1-at-a-time.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Three strategies overview | 2 minutes |
| SINGLE_TABLE vs JOINED tradeoffs | 2 minutes |
| TABLE_PER_CLASS limitations | 1 minute |
| Polymorphic query SQL | 1 minute |
| When to use which | 1 minute |
| NOT NULL constraints in SINGLE_TABLE | 1 minute |
| Discriminator column | 1 minute |

---

**Q1 (inheritance): Compare SINGLE_TABLE and JOINED inheritance strategies.**

A: SINGLE_TABLE: one DB table for the entire hierarchy. A discriminator column (e.g., `dtype` or
`notification_type`) identifies the subclass. Subclass-specific columns are present in the table
for all rows but are NULL for rows of other subtypes. Polymorphic queries: no JOIN, single SELECT.
Specific subtype queries: add `WHERE discriminator = 'TYPE'`. Cannot add NOT NULL constraints to
subclass columns. JOINED: parent class in one table, each subclass in its own table with only the
subclass columns. Subtype-specific columns can be NOT NULL. Normalized schema. Polymorphic queries:
requires LEFT OUTER JOINs across all subtype tables. With many subtypes: complex query plan, slower.
Choose SINGLE_TABLE for performance (default), JOINED for schema integrity requirements.

*What separates good from great:* The "implicit JOIN" cost in JOINED: every `em.find(Payment.class, id)`
with JOINED strategy joins the parent table with the relevant subtype table. Even loading one entity:
a JOIN. In a high-traffic read path: this is measurable overhead vs SINGLE_TABLE's single table read.
JOINED is often chosen for schema purity without considering that the application will do millions of
reads per day. The SINGLE_TABLE nullable-column disk space concern is usually negligible: a few nullable
VARCHAR columns per row adds bytes, not megabytes. The JOIN overhead in JOINED is the real cost for
read-heavy applications.
