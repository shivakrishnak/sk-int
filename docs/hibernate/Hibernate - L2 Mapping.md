---
layout: default
title: "Hibernate - L2 Mapping"
parent: "Hibernate"
nav_order: 3
permalink: /hibernate/l2-mapping/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Hibernate - L2 Mapping](#hibernate---l2-mapping) | medium |
| 2 | [One-to-One and One-to-Many Mappings](#one-to-one-and-one-to-many-mappings) | working |
| 3 | [Many-to-Many with Join Tables](#many-to-many-with-join-tables) | working |
| 4 | [Inheritance Mapping Strategies](#inheritance-mapping-strategies) | working |
| 5 | [Embedded Objects and Components](#embedded-objects-and-components) | working |
| 6 | [Collection Mappings](#collection-mappings) | working |

---

# Hibernate - L2 Mapping

Entity relationship mapping: one-to-many, many-to-many,
inheritance, embedded objects, and collection mappings.
The vocabulary of domain model persistence.

---

# One-to-One and One-to-Many Mappings

**Interview Weight:** working - Relationship mapping is
core Hibernate knowledge. Questions target: bidirectional
vs unidirectional, owning side, `mappedBy`, lazy vs eager
defaults, and the `@JoinColumn` placement.

---

### 🎯 Model Answer

**30 seconds:**

> One-to-One: `@OneToOne` with `@JoinColumn` on the owning
> side (the table that holds the FK). One-to-Many: the "many"
> side owns the FK; the "one" side uses `mappedBy` to reference
> the field on the "many" side. Default fetch: `@OneToMany`
> is LAZY (correct), `@OneToOne` is EAGER (watch out).
> Always specify `fetch = FetchType.LAZY` explicitly on
> `@OneToOne` to avoid inadvertent eager loading.

**3 minutes:**

> The `mappedBy` attribute is the key to bidirectional
> mapping: it tells Hibernate "the JOIN column is managed
> by the other side." Only one side should manage the FK.
>
> Common mistake: bidirectional one-to-many without the
> inverse reference set. If you add an `Item` to
> `order.getItems()` but forget to set `item.setOrder(order)`,
> Hibernate only sets the FK if the `Item` entity owns
> the relationship (has `@JoinColumn`). If you forget
> to set the `item.order` field (and the Order side has
> `mappedBy`), the FK column stays null.
>
> Best practice for bidirectional one-to-many: add a
> helper method to keep both sides in sync:
> ```java
> public void addItem(Item item) {
>     items.add(item);
>     item.setOrder(this);  // keep inverse in sync
> }
> ```

---

### 📘 Concept Explanation

**Bidirectional One-to-Many:**

```
  ORDER                    ITEM
  (one side)               (many side)

  @OneToMany               @ManyToOne
  (mappedBy = "order")     @JoinColumn(name="order_id")
  List<Item> items         Order order

  ^^ "order" refers to     ^^ Owns the FK column
  the field name in Item   in the items table

  DB Schema:
  items table: order_id FK references orders(id)
  orders table: no FK column (FK is in items table)
```

---

### 💻 Code Example

**Production: bidirectional One-to-Many with helper methods**

```java
@Entity
public class Order {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    private Long id;

    // Lazy is the default for @OneToMany - always keep lazy
    @OneToMany(mappedBy = "order",
               cascade = CascadeType.ALL,
               orphanRemoval = true,
               fetch = FetchType.LAZY)
    private List<OrderItem> items = new ArrayList<>();

    // Bidirectional helper: keeps both sides in sync
    public void addItem(OrderItem item) {
        items.add(item);
        item.setOrder(this);  // CRITICAL: set the FK owner
    }

    public void removeItem(OrderItem item) {
        items.remove(item);
        item.setOrder(null);
    }
}

@Entity
public class OrderItem {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE)
    private Long id;

    // Owning side: holds the FK column in items table
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    private String productCode;
    private int quantity;
}
```

```java
// @OneToOne: explicitly lazy (default is EAGER!)
@Entity
public class Order {
    @Id
    private Long id;

    @OneToOne(fetch = FetchType.LAZY,    // MUST be explicit
              cascade = CascadeType.ALL,
              orphanRemoval = true)
    @JoinColumn(name = "shipping_address_id")
    private ShippingAddress shippingAddress;
}
```

> **Code walkthrough:** The `addItem` helper method is
> essential for bidirectional correctness. Without it:
> adding an item to `order.items` (the `mappedBy` side)
> does NOT set the `order_id` FK in the `OrderItem` row
> because the `mappedBy` side is not the owning side.
> Only setting `item.setOrder(order)` (the `@JoinColumn`
> side) updates the FK. The helper method keeps both
> sides in sync. `@OneToOne` default is `EAGER` - this
> is a common gotcha. If `Order` has 10 `@OneToOne`
> associations, every `Order` load triggers 10 additional
> SELECT statements for the associated entities. Always
> specify `FetchType.LAZY` explicitly for `@OneToOne`.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> The `mappedBy` placement rule: `mappedBy` goes on the
> side that does NOT own the FK column. The `@JoinColumn`
> goes on the side that DOES own the FK column. For
> `Order` -> `OrderItem` (one-to-many): the `items` table
> has an `order_id` FK column. So `@JoinColumn` is on
> `OrderItem.order` and `mappedBy = "order"` is on
> `Order.items`.
>
> For `orphanRemoval = true`: if an `OrderItem` is removed
> from `order.items`, Hibernate issues a DELETE for the
> orphaned item. Without `orphanRemoval`: the item's FK
> is set to null (or deletion fails if the FK is NOT NULL).

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---|---|---|
| 1 | Adding to the @OneToMany collection saves the relationship | @OneToMany with mappedBy is the INVERSE side. Setting only this side has no effect on the FK column. You must set the @ManyToOne field on the owning side. | FK column stays null; item appears in the collection in-memory but is not persisted correctly |
| 2 | @OneToOne defaults to lazy loading | @OneToOne default fetch is EAGER. This means loading an Order will also load all @OneToOne associations. Explicitly set FetchType.LAZY. | Performance: every Order load triggers N extra SELECT queries for @OneToOne associations |

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: What is the "owning side" in a bidirectional
Hibernate relationship, and why does it matter?**
[FOUNDATION + INTERNALS]

The owning side is the side that controls the FK column
in the database. It is the side that does NOT have
`mappedBy`.

Why it matters:
- Hibernate ONLY looks at the owning side to determine
  what FK value to persist
- Changing only the inverse side (the `mappedBy` side)
  has no effect on the database
- The `mappedBy` side is just a convenience for navigation;
  it is not persisted

Identifying the owning side:
- `@ManyToOne`: always the owning side (holds the FK column)
- `@OneToMany(mappedBy=...)`: inverse side (no FK column)
- `@OneToOne`: the side with `@JoinColumn` is owning
- `@ManyToMany`: the side without `mappedBy` is owning (holds the join table)

*What separates good from great:* Explaining that `mappedBy`
is a Hibernate instruction, not a database concept - it
tells Hibernate "don't manage the FK from this side;
the other side manages it."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with mappedBy, owning side, and FK management. |
| Hiring Manager | Lead with bidirectional helper methods and correct relationship management. |
| Bar Raiser | Lead with OneToOne EAGER default gotcha and orphanRemoval semantics. |

---

---

# Many-to-Many with Join Tables

**Interview Weight:** working - Many-to-Many is common
in domain models. Questions target: join table mapping,
when to use an intermediate entity vs `@ManyToMany`,
and Hibernate's extra UPDATE issue.

---

### 🎯 Model Answer

**30 seconds:**

> `@ManyToMany` maps to a join table (intersection table).
> Both entities have a `List` or `Set` of the other.
> The join table contains just two FK columns. For
> many-to-many with extra attributes (e.g., a role with
> an assigned date), create an intermediate entity class
> instead of `@ManyToMany`. The `Set` vs `List` choice
> matters: using `List` causes Hibernate to delete all
> join table rows and re-insert them on any change
> (the Hibernate bag issue). Use `Set` for many-to-many
> collections.

---

### 📘 Concept Explanation

**Many-to-Many mapping:**

```
  Order (*)  <--->  (*) Tag

  orders table    order_tags (join table)    tags table
  id              order_id  FK               id
  total           tag_id    FK               name

  @ManyToMany on Order:
  @JoinTable(
    name = "order_tags",
    joinColumns = @JoinColumn(name = "order_id"),
    inverseJoinColumns = @JoinColumn(name = "tag_id")
  )
  Set<Tag> tags;

  @ManyToMany(mappedBy = "tags") on Tag:
  Set<Order> orders;
```

---

### 💻 Code Example

**Wrong vs Right: List vs Set for many-to-many**

```java
// BAD: List<Tag> in @ManyToMany (Hibernate bag issue)
@Entity
public class Order {
    @ManyToMany
    @JoinTable(name = "order_tags",
        joinColumns = @JoinColumn(name = "order_id"),
        inverseJoinColumns = @JoinColumn(name = "tag_id"))
    private List<Tag> tags = new ArrayList<>();
    // When adding one tag:
    // DELETE FROM order_tags WHERE order_id = ?
    // INSERT INTO order_tags VALUES (?, ?) [for every tag!]
    // Replaces the entire list on every change!
}
```

```java
// GOOD: Set<Tag> (only inserts new, deletes removed)
@Entity
public class Order {

    @ManyToMany
    @JoinTable(name = "order_tags",
        joinColumns = @JoinColumn(name = "order_id"),
        inverseJoinColumns = @JoinColumn(name = "tag_id"))
    private Set<Tag> tags = new HashSet<>();
    // When adding one tag:
    // INSERT INTO order_tags VALUES (?, ?) [one row only]
    // No full delete/re-insert

    public void addTag(Tag tag) {
        tags.add(tag);
        tag.getOrders().add(this);  // sync inverse
    }
}

@Entity
public class Tag {
    @Id
    @GeneratedValue
    private Long id;
    private String name;

    @ManyToMany(mappedBy = "tags")
    private Set<Order> orders = new HashSet<>();
}
```

```java
// BEST for many-to-many with extra attributes:
// Intermediate entity (avoids @ManyToMany entirely)
@Entity
@Table(name = "order_tags")
public class OrderTag {

    @Id
    @GeneratedValue
    private Long id;

    @ManyToOne
    @JoinColumn(name = "order_id")
    private Order order;

    @ManyToOne
    @JoinColumn(name = "tag_id")
    private Tag tag;

    // Extra attributes impossible with @ManyToMany:
    private LocalDateTime assignedAt;
    private String assignedBy;
}
```

> **Code walkthrough:** The List bag issue is a real
> Hibernate gotcha. When using `List` for `@ManyToMany`,
> Hibernate does not track individual element changes.
> Adding one tag causes: DELETE all rows from `order_tags`
> for this order, then INSERT all tags (old + new).
> For an order with 50 tags, adding one tag = 51 database
> operations. Using `Set` tells Hibernate to track set
> membership: adding a tag = 1 INSERT, removing a tag
> = 1 DELETE. The intermediate entity approach is the most
> flexible: it allows extra attributes on the relationship
> and gives explicit control over the join table.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> My rule for many-to-many: start with the intermediate
> entity approach. `@ManyToMany` looks simpler but the
> List/Set gotcha, lack of extra attributes, and limited
> query flexibility make it less useful for production
> domain models. The intermediate entity gives you: extra
> attributes (assigned date, assigned by), explicit join
> table control, and direct querying without joining through
> both sides.
>
> The only time I use bare `@ManyToMany`: read-only
> tag/label assignments with no extra attributes and
> `Set` collections. Even then: I document the `Set`
> requirement explicitly to prevent future developers
> from changing it to `List`.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: Why does using List instead of Set in
@ManyToMany cause performance issues?** [INTERNALS]

Hibernate uses a `PersistentBag` for `List` collections.
`PersistentBag` does not deduplicate and does not track
individual element additions/removals. When any change
occurs to a `PersistentBag` collection, Hibernate cannot
determine which specific rows changed - it resorts to
deleting all join table rows for the parent entity and
re-inserting all current elements.

For `Set` (`PersistentSet`): Hibernate tracks additions
and removals individually. Adding one element = one INSERT.
Removing one element = one DELETE.

The practical impact: an order with 100 tags, adding one
more tag: with `List` = 101 database operations; with
`Set` = 1 database operation.

*What separates good from great:* Knowing that this is
a `PersistentBag` vs `PersistentSet` internal difference
and that the fix is switching to `Set<>` - not adding
`@IndexColumn` or other workarounds.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with List bag issue and Set fix. |
| Hiring Manager | Lead with intermediate entity as the recommended pattern. |
| Bar Raiser | Lead with PersistentBag internals and the production performance impact. |

---

---

# Inheritance Mapping Strategies

**Interview Weight:** working - Three strategies (SINGLE_TABLE,
TABLE_PER_CLASS, JOINED) are tested for trade-offs.
Questions target: when to use each, discriminator columns,
and the polymorphic query implications.

---

### 🎯 Model Answer

**30 seconds:**

> Three JPA inheritance strategies: SINGLE_TABLE (all
> subclass columns in one table, nullable for irrelevant
> columns, fastest queries, wastes space), JOINED (separate
> table per subclass joined to parent, normalized,
> requires JOIN for every query), TABLE_PER_CLASS
> (complete separate table per subclass, no joins,
> but UNION for polymorphic queries). Default:
> SINGLE_TABLE (Hibernate's default if unspecified).
> Recommended: SINGLE_TABLE for most cases; JOINED when
> there are many columns per subtype.

---

### 📘 Concept Explanation

**Three inheritance strategies:**

```
  SINGLE_TABLE (one table, discriminator column)
  orders table:
  id | type | total | subscription_period | discount_pct
  1  | STD  | 100   | NULL                | NULL
  2  | SUB  | 50    | 30days              | NULL
  3  | DISC | 80    | NULL                | 10.0
  Pros: fastest (no JOIN), simple queries
  Cons: nullable columns, sparse for many subtypes

  JOINED (separate table per subclass)
  orders:      | subscription_orders: | discount_orders:
  id | total   | order_id | period    | order_id | pct
  1  | 100     | 2        | 30days    | 3        | 10.0
  2  | 50      | ...      | ...       | ...      | ...
  Pros: normalized, no null columns
  Cons: JOIN required for every subclass query

  TABLE_PER_CLASS (complete table per subclass)
  standard_orders:  | subscription_orders: | discount_orders:
  id | total        | id | total | period   | id | total | pct
  1  | 100          | 2  | 50    | 30days   | 3  | 80    | 10.0
  Pros: simple per-type queries, no nullable columns
  Cons: polymorphic query = UNION ALL (slow at scale)
        cannot use identity generation strategy
```

---

### 💻 Code Example

**SINGLE_TABLE strategy (most common)**

```java
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "order_type",
    discriminatorType = DiscriminatorType.STRING)
@DiscriminatorValue("STD")
public class Order {
    @Id @GeneratedValue private Long id;
    private BigDecimal total;
    private OrderStatus status;
}

@Entity
@DiscriminatorValue("SUB")
public class SubscriptionOrder extends Order {
    @Column(name = "subscription_period")
    private String subscriptionPeriod;
}

@Entity
@DiscriminatorValue("DISC")
public class DiscountOrder extends Order {
    @Column(name = "discount_pct")
    private Double discountPercent;
}
```

```java
// JOINED strategy: separate tables, JOINed at query time
@Entity
@Inheritance(strategy = InheritanceType.JOINED)
public class Order {
    @Id @GeneratedValue private Long id;
    private BigDecimal total;
}

@Entity
@Table(name = "subscription_orders")
public class SubscriptionOrder extends Order {
    // Separate table: subscription_orders
    // FK: id references orders(id)
    private String subscriptionPeriod;
}
// Query: SELECT o.*, s.* FROM orders o
//        JOIN subscription_orders s ON s.id = o.id
//        WHERE o.id = ?
```

> **Code walkthrough:** SINGLE_TABLE uses a `@DiscriminatorColumn`
> to identify the subclass. All subclass columns exist in
> the same table - they are nullable for rows of other
> types. The `@DiscriminatorValue` on each subclass specifies
> what value the discriminator column holds for that type.
> Polymorphic queries (`SELECT FROM Order`) query one table
> and return a mix of `Order`, `SubscriptionOrder`, and
> `DiscountOrder` instances based on the discriminator value.
> JOINED generates a JOIN to the subclass table on every
> subclass query - normalized schema but query cost for
> each access.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> My default is SINGLE_TABLE. It is the simplest, fastest
> strategy for polymorphic queries. The nullable columns
> trade-off is acceptable unless: many subclasses each
> with many columns (table becomes very wide and sparse).
> In that case: JOINED.
>
> TABLE_PER_CLASS I actively avoid. The UNION ALL for
> polymorphic queries is a scalability trap. At 1 million
> rows per subtype with 5 subtypes: the polymorphic query
> scans 5 million rows. Also: identity ID generation
> cannot be used (no single table for the ID sequence).

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: When would you choose JOINED over
SINGLE_TABLE inheritance, and what is the performance trade-off?** [TRADE-OFF]

Choose JOINED when:
- Each subtype has many unique columns (wide sparse table
  is the cost of SINGLE_TABLE)
- Database schema normalization is a strict requirement
  (DBA may require no nullable columns)
- Sub-type queries are more common than polymorphic
  queries (most queries target `SubscriptionOrder` directly,
  not the abstract `Order` type)

JOINED performance trade-off:
- Subclass instance load: requires a JOIN. `SELECT
  subscription_orders.*, orders.* FROM orders o JOIN
  subscription_orders s ON s.id = o.id`
- Polymorphic query (`SELECT FROM Order`): requires
  LEFT OUTER JOINs to all subclass tables to determine
  the type. With 10 subtypes: 10-way LEFT OUTER JOIN.
  This is slow.

SINGLE_TABLE performance advantage:
- One table. All queries are single-table SELECTs with
  a discriminator `WHERE` clause. No JOINs.
- Polymorphic query: one SELECT, returns rows filtered
  by discriminator.

*What separates good from great:* Knowing that JOINED
polymorphic queries use LEFT OUTER JOINs (not INNER JOINs)
because the discriminator is not in the subclass tables -
Hibernate must check all subclass tables to determine
the type.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with three strategies and when to use each. |
| Hiring Manager | Lead with SINGLE_TABLE as the default recommendation. |
| Bar Raiser | Lead with TABLE_PER_CLASS UNION ALL limitation and JOINED LEFT OUTER JOIN polymorphic query cost. |

---

---

# Embedded Objects and Components

**Interview Weight:** working - `@Embeddable` and `@Embedded`
are common in DDD-style domain models. Questions target:
when to use embedded vs entity, column name overrides,
and `@ElementCollection` for collections of value objects.

---

### 🎯 Model Answer

**30 seconds:**

> `@Embeddable` marks a class whose fields are stored in
> the parent entity's table (no separate table, no PK).
> `@Embedded` references an embeddable. Use for value objects
> in DDD: `Address`, `Money`, `DateRange` - types that
> have no identity of their own and only exist as part
> of an entity. For collections of value objects: use
> `@ElementCollection` (separate table, FK to parent, no
> PK of its own).

---

### 📘 Concept Explanation

**Embedded objects:**

```
  @Embeddable           Not a separate table
  class Address         Stored in orders table:
    street: String  --> street VARCHAR
    city: String    --> city VARCHAR
    zip: String     --> zip VARCHAR

  @Entity
  class Order
    @Embedded
    Address shippingAddress  --> street, city, zip columns
    @Embedded
    Address billingAddress   --> must override column names!
```

---

### 💻 Code Example

**Value objects with @Embeddable**

```java
@Embeddable
public class Address {
    @Column(nullable = false, length = 200)
    private String street;

    @Column(nullable = false, length = 100)
    private String city;

    @Column(nullable = false, length = 10)
    private String zipCode;

    @Column(nullable = false, length = 2)
    private String countryCode;
}

@Entity
@Table(name = "orders")
public class Order {

    @Embedded
    @AttributeOverrides({
        @AttributeOverride(name = "street",
            column = @Column(name = "ship_street")),
        @AttributeOverride(name = "city",
            column = @Column(name = "ship_city")),
        @AttributeOverride(name = "zipCode",
            column = @Column(name = "ship_zip")),
        @AttributeOverride(name = "countryCode",
            column = @Column(name = "ship_country"))
    })
    private Address shippingAddress;

    @Embedded
    @AttributeOverrides({
        @AttributeOverride(name = "street",
            column = @Column(name = "bill_street")),
        @AttributeOverride(name = "city",
            column = @Column(name = "bill_city")),
        @AttributeOverride(name = "zipCode",
            column = @Column(name = "bill_zip")),
        @AttributeOverride(name = "countryCode",
            column = @Column(name = "bill_country"))
    })
    private Address billingAddress;
}

// @ElementCollection: collection of value objects
@Entity
public class Customer {
    @Id @GeneratedValue private Long id;

    // Stored in customer_emails table: customer_id, email
    @ElementCollection
    @CollectionTable(
        name = "customer_emails",
        joinColumns = @JoinColumn(name = "customer_id"))
    @Column(name = "email")
    private Set<String> emails = new HashSet<>();
}
```

> **Code walkthrough:** `@AttributeOverrides` is required
> when the same `@Embeddable` is embedded twice in the
> same entity. Without it: two `Address` objects would
> map to the same column names (`street`, `city`, etc.)
> - column name collision. `@AttributeOverride` renames
> each column per embedding context. `@ElementCollection`
> creates a separate `customer_emails` table with a FK
> to `customers`. Unlike `@OneToMany`, there is no entity
> class for the email - it is a pure value stored as a
> string. Loading is eager by default for `@ElementCollection`;
> add `@LazyCollection(LazyCollectionOption.TRUE)` for
> lazy loading with large collections.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> `@Embeddable` is the JPA mechanism for DDD value objects.
> The rule: use `@Embeddable` when the type has no identity
> (no meaningful PK) and only exists as part of an entity.
> `Money(amount, currency)`, `DateRange(start, end)`,
> `Address` - all are value objects.
>
> Common pitfall: `null` embedded object. If `shippingAddress`
> is null, all columns in the addresses embedding are null.
> This can cause issues with `NOT NULL` constraints on
> embeddable columns. Solution: define the embedded object
> as `@Embedded @NotNull` and ensure it is always populated.

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: When would you use @Embeddable vs @Entity
for a component like Address?** [DECISION]

Use `@Embeddable` when:
- Address has no identity of its own (no need to look
  up an address by ID)
- Address is always accessed through its owner (Order,
  Customer)
- Address does not need to be shared between multiple
  owners (each owner has its own address copy)

Use `@Entity` when:
- Address needs to be shared (multiple orders reference
  the same delivery address)
- Address has its own lifecycle (created, updated,
  deleted independently of the owner)
- Address needs its own audit trail or versioning

Rule of thumb: `@Embeddable` for value objects (DDD concept:
equality by value, not identity). `@Entity` for entities
(DDD concept: equality by identity).

*What separates good from great:* Connecting to DDD vocabulary
(value object vs entity) and the identity criterion.

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with @AttributeOverrides for multiple embeddings. |
| Hiring Manager | Lead with DDD value object pattern. |
| Bar Raiser | Lead with @ElementCollection for collections of value types and lazy loading. |

---

---

# Collection Mappings

**Interview Weight:** working - Collection type choice
(`List`, `Set`, `Map`, `SortedSet`) affects behavior and
performance. Questions target: `@OrderBy`, `@OrderColumn`,
`@MapKey`, and the `List` vs `Set` performance difference.

---

### 🎯 Model Answer

**30 seconds:**

> Hibernate maps `List` (ordered, duplicates allowed,
> bag semantics unless `@OrderColumn` is added), `Set`
> (unordered by default, deduplicated by `equals`/`hashCode`),
> `Map` (key-value, `@MapKey` or `@MapKeyColumn`), and
> `SortedSet` (sorted by `Comparator`). For ordered collections:
> use `@OrderBy` (order in the SELECT query) or
> `@OrderColumn` (persisted index column). Always define
> `equals` and `hashCode` on entity classes that participate
> in `Set` collections.

---

### 💻 Code Example

**Collection mapping patterns**

```java
@Entity
public class Order {

    // Ordered by query (no extra column)
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL)
    @OrderBy("productCode ASC, quantity DESC")
    // Hibernate adds ORDER BY to the SELECT
    private List<OrderItem> items = new ArrayList<>();

    // Persisted order (extra position column in table)
    @OneToMany(mappedBy = "order")
    @OrderColumn(name = "item_position")
    // items table: item_position INTEGER
    // Position maintained on every add/remove
    private List<OrderItem> orderedItems = new ArrayList<>();
}

@Entity
public class Customer {

    // Map: phone type -> phone number
    @ElementCollection
    @CollectionTable(name = "customer_phones",
        joinColumns = @JoinColumn(name = "customer_id"))
    @MapKeyColumn(name = "phone_type")  // map key
    @Column(name = "phone_number")       // map value
    private Map<String, String> phones = new HashMap<>();

    // SortedSet: natural ordering by Tag.name
    @ManyToMany
    @SortNatural  // sorted by Tag.compareTo()
    private SortedSet<Tag> tags = new TreeSet<>();
}

// CRITICAL: entities in Set must implement equals/hashCode
@Entity
public class OrderItem {
    @Id @GeneratedValue private Long id;

    @Override
    public boolean equals(Object obj) {
        if (!(obj instanceof OrderItem)) return false;
        OrderItem other = (OrderItem) obj;
        // Use business key, NOT id (id is null before persist)
        return Objects.equals(productCode,
            other.productCode);
    }

    @Override
    public int hashCode() {
        return Objects.hash(productCode);
        // NEVER use id in hashCode for JPA entities
        // id is null before persist (would change hash)
    }
}
```

> **Code walkthrough:** `@OrderBy` adds an `ORDER BY`
> clause to the Hibernate-generated SELECT for the collection.
> It is expressed in JPQL (entity property names, not
> column names). `@OrderColumn` persists the position in
> a dedicated column. Maintaining position requires updating
> the column on every insertion/removal - more expensive
> but gives a stable, persisted order. The `equals`/`hashCode`
> implementation is critical for entities in `Set` collections.
> Using `id` in `hashCode` is dangerous: before `persist()`,
> the ID is null. After persist, the ID is set - the hash
> changes, and the entity is "lost" in the `HashSet`
> (stored in the wrong bucket). Use a business key
> (like `productCode`) that is stable before and after persist.

---

### 🎓 Answers by Seniority

**Senior (4+ years):**

> The `equals`/`hashCode` rule for JPA entities: never
> use the `@Id` field in `hashCode`. The ID is null before
> `persist()`. If you add an entity to a `HashSet` before
> persisting, the hash is based on `null`. After persist,
> the hash changes and the entity is effectively "lost"
> in the set (cannot be found by `contains()`).
>
> Use a business key: a field that is stable before and
> after persistence (`productCode`, `username`, `uuid`).
> If no business key exists: override `equals`/`hashCode`
> using only `getClass()` and `id` WITH null safety
> (treat two entities with null IDs as equal only if they
> are the same object reference).

---

### 🎯 Interview Deep-Dive

**[SENIOR] Q1: Why should you never use the @Id field
in equals/hashCode for JPA entities?** [INTERNALS]

The JPA entity lifecycle: TRANSIENT -> PERSISTENT.
Before `persist()`, the `@Id` field is null (for generated
IDs). `hashCode()` based on null = 0 (typically). The
entity is stored in `HashSet` with hash 0.

After `persist()` (and flush), the ID is populated.
If `hashCode()` uses the ID, the hash changes from 0
to `hash(42)`. But the entity is stored in the `HashSet`
at bucket 0. The `HashSet` cannot find it at the new
bucket. `set.contains(entity)` returns false even though
the entity IS in the set.

Safe patterns for `equals`/`hashCode`:
1. Business key (stable before and after persist)
2. UUID generated in the constructor (stable from creation)
3. Identity-based: `return getClass().hashCode()` (all
   instances of same class have the same hash - more
   collisions but always consistent)

*What separates good from great:* Walking through the
HashMap/HashSet bucket mechanism to explain WHY the entity
is lost - not just saying "don't use ID in hashCode."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Lead with @OrderBy vs @OrderColumn trade-off. |
| Hiring Manager | Lead with collection type selection guide. |
| Bar Raiser | Lead with equals/hashCode contract and the ID-in-hashCode failure mode. |
