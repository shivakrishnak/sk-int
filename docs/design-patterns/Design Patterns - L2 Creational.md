---
layout: default
title: "Design Patterns - L2 Creational"
parent: "Design Patterns"
grand_parent: "SK Interview"
nav_order: 5
permalink: /design-patterns/l2-creational/
---

# Abstract Factory Pattern

---
id: DP-013
title: Abstract Factory Pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: high
asked_at: Senior+
seniority: mid-senior
tags: #design-patterns, #abstract-factory, #creational, #families
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Abstract Factory provides an interface for creating families of related
> or dependent objects without specifying their concrete classes. Where
> Factory Method creates one product, Abstract Factory creates a suite
> of products that belong together. The classic example: a UI toolkit
> factory that creates a Button and a Checkbox that both match
> (Light theme or Dark theme) - they are related objects that must
> be consistent.

**3 minutes (Senior):**
> Abstract Factory solves the object family consistency problem. When
> a system must work with multiple product families (Light theme, Dark
> theme, High Contrast theme), and within a family the objects must
> be compatible (LightButton must pair with LightCheckbox, not DarkCheckbox),
> Abstract Factory enforces this consistency at compile time. You inject
> one factory; every product it creates is guaranteed to be from the same
> family.
>
> Production context: JDBC drivers are Abstract Factory. `DriverManager.getConnection()`
> returns a `Connection` (factory) that creates `Statement`, `PreparedStatement`,
> `ResultSet` - all from the same database family (H2, MySQL, Oracle). Spring
> Data's `JpaRepositoryFactory` creates the right repository implementation
> for the configured JPA provider (Hibernate vs EclipseLink). You swap the
> factory, the whole family changes consistently.
>
> The distinction from Factory Method: Factory Method has ONE factory method
> creating ONE product type. Abstract Factory has a factory interface with
> MULTIPLE factory methods, each creating a different product type from the
> same family. The family coherence is the defining characteristic.

**Blank Mind Recovery:**

**(1) Restate:** "Abstract Factory - the pattern that creates consistent
families of objects."

**(2) First principles:** "Problem: I need to create several related objects
that must be compatible with each other. Solution: define a factory interface
with one creation method per product type; each concrete factory creates
all products for one family."

**(3) Bridge:** "Like a furniture factory: one factory makes Victorian chairs,
Victorian sofas, and Victorian tables. Another factory makes Modern chairs,
Modern sofas, and Modern tables. You pick one factory; all your furniture
matches."

---

### 📘 Concept Explanation

**What it is:**
Abstract Factory is a Creational pattern that provides an interface for
creating families of related objects. Concrete factories implement the
interface, each producing one family of products. Clients use the factory
interface without knowing which family is produced.

**The problem it solves:**
When a system must produce objects from one of several product families,
and the products within a family must be consistent with each other.
Without Abstract Factory, the client must know the concrete classes of
all products, creating coupling and risking inconsistency (mixing products
from different families).

**How it works:**

```
AbstractFactory interface:
  + createProductA(): AbstractProductA
  + createProductB(): AbstractProductB

ConcreteFactory1 implements AbstractFactory:
  + createProductA(): ConcreteProductA1
  + createProductB(): ConcreteProductB1
  // Both products are Family 1

ConcreteFactory2 implements AbstractFactory:
  + createProductA(): ConcreteProductA2
  + createProductB(): ConcreteProductB2
  // Both products are Family 2

Client:
  - factory: AbstractFactory  (injected)
  productA = factory.createProductA()
  productB = factory.createProductB()
  // Guaranteed: A and B are from the same family
```

**The key insight:**
The abstract factory interface is the contract for a family. By injecting
the factory, you inject the entire family. Swapping the factory swaps
the entire family consistently. The client code is identical for all
families.

**When to use it:**
- When a system should be independent of how its products are created,
  composed, and represented
- When a system should work with multiple families of products and must
  enforce product consistency within a family
- When you want to provide a library of products and only reveal their
  interfaces, not their implementations

**When NOT to use it:**
- When only one product type is needed: use Factory Method instead
- When the family rarely changes and there is only one family: regular
  factory or `new` is simpler
- When the factory interface must grow to add new product types: adding
  a new product type requires modifying the abstract factory and all
  concrete factories (the biggest weakness)

**Alternatives:**
- **Factory Method** - single product type; Abstract Factory for families
- **Builder** - constructs a single complex object step by step
- **Prototype** - copies existing objects; useful when
  `new` is expensive

**First-principles derivation:**
Given: products A and B must be from the same family (Family1.A must
pair with Family1.B, not Family2.B). Options: (A) client creates both
explicitly with `new` - no enforcement of family consistency.
(B) factory interface with `createA()` and `createB()` - one factory =
one family; guaranteed consistency.

---

### 💻 Code Example

```java
// BAD: direct instantiation - no family consistency
if (theme.equals("dark")) {
    Button button = new DarkButton();
    // Bug: forgot to use DarkCheckbox, used LightCheckbox
    Checkbox checkbox = new LightCheckbox();  // WRONG family!
    // DarkButton and LightCheckbox together = visual inconsistency
}
```

> **Code walkthrough:** Direct instantiation gives no compile-time or
> runtime guarantee that the products are from the same family. A
> developer creating `DarkButton` can accidentally use `LightCheckbox` -
> the compiler does not prevent it. This is the core problem Abstract
> Factory solves.

```java
// GOOD: Abstract Factory enforces family consistency
public interface UIFactory {
    Button createButton();
    Checkbox createCheckbox();
    TextField createTextField();
}

public class LightThemeFactory implements UIFactory {
    public Button createButton() {
        return new LightButton();
    }
    public Checkbox createCheckbox() {
        return new LightCheckbox();
    }
    public TextField createTextField() {
        return new LightTextField();
    }
}

public class DarkThemeFactory implements UIFactory {
    public Button createButton() {
        return new DarkButton();
    }
    public Checkbox createCheckbox() {
        return new DarkCheckbox();
    }
    public TextField createTextField() {
        return new DarkTextField();
    }
}

// Application uses the factory interface only
public class Application {
    private final UIFactory factory;  // injected

    public Application(UIFactory factory) {
        this.factory = factory;
    }

    public void buildLoginForm() {
        Button submit = factory.createButton();
        Checkbox rememberMe = factory.createCheckbox();
        TextField email = factory.createTextField();
        // Guaranteed: all three are from the same theme family
    }
}

// Configuration determines the theme
@Configuration
public class ThemeConfig {
    @Bean
    public UIFactory uiFactory(
            @Value("${app.theme}") String theme) {
        return switch (theme) {
            case "dark" -> new DarkThemeFactory();
            case "light" -> new LightThemeFactory();
            default -> throw new IllegalArgumentException(
                "Unknown theme: " + theme);
        };
    }
}
```

> **Code walkthrough:** `Application` depends only on `UIFactory` -
> it never knows whether it is creating dark or light components.
> Changing `app.theme=dark` in configuration swaps the entire UI family.
> Adding a `HighContrastThemeFactory` does not require changing
> `Application` at all. The family consistency is guaranteed by
> construction: one factory instance creates all products for one theme.

```java
// PRODUCTION: Abstract Factory in Spring Data
// DataSource acts as Abstract Factory concept:
// JDBC DriverManager returns a Connection (factory)
// that creates Statement, PreparedStatement, ResultSet
// all from the same database implementation.

@Configuration
public class DataSourceConfig {
    @Bean
    @Profile("test")
    public DataSource testDataSource() {
        // H2 factory: creates H2 Connections, H2 Statements
        return new EmbeddedDatabaseBuilder()
            .setType(EmbeddedDatabaseType.H2).build();
    }

    @Bean
    @Profile("prod")
    public DataSource prodDataSource() {
        // MySQL factory: creates MySQL Connections, Statements
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(env.getProperty("db.url"));
        return new HikariDataSource(config);
    }
    // All database code uses DataSource interface.
    // Swapping the factory swaps the entire DB family.
}
```

> **Code walkthrough:** `DataSource` is an Abstract Factory: it creates
> `Connection` objects (which in turn create `Statement` and `ResultSet`).
> Swapping the `DataSource` bean (H2 in test, MySQL in production) swaps
> the entire JDBC family. Application code that uses `jdbcTemplate.query()`
> works identically in both environments - the factory is the seam.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Abstract Factory creates families of related objects through a factory
> interface. Each concrete factory creates all products for one family.
> The client uses the factory interface without knowing which family it
> is using. The key difference from Factory Method: Factory Method creates
> one product; Abstract Factory creates a suite of related products that
> must be consistent with each other.

*Push deeper:* "JDBC is a real example: `DataSource` is the Abstract
Factory, `Connection` is one product it creates. You swap the
`DataSource` (H2, MySQL) and all the JDBC objects change consistently."

---

**Senior / Staff (5+ years):**
> Abstract Factory is how you enforce product-family consistency at
> the dependency injection level. The pattern appears everywhere in
> framework design: JDBC datasources, Spring Data repository factories,
> Spring Cloud circuit breaker factories (Resilience4j vs Hystrix).
>
> The key weakness to know: extensibility in the product dimension is
> expensive. If I need to add a `Tooltip` to the UI factory family, I
> must add `createTooltip()` to the abstract factory interface AND to
> every concrete factory. If I have five concrete factories, that is
> five file changes. The pattern is more extension-friendly in the
> family dimension (adding a new theme = one new concrete factory class)
> than in the product dimension.

*Push deeper:* "Abstract Factory vs Builder: Abstract Factory creates
multiple products that form a family (one call per product). Builder
constructs one complex object step by step using a fluent API. If
the 'family' is actually one complex object with many optional parts,
use Builder. If it is truly multiple independent product types that
must match, use Abstract Factory."

---

### ❓ Questions You Will Be Asked

#### Definition
- "What is Abstract Factory? How is it different from Factory Method?"

🗣️ "Abstract Factory provides an interface for creating families of
related objects. Each method in the abstract factory creates one type
of product; all products from one factory instance belong to the same
family. Factory Method: one factory method, one product type, parameterized
or specialized by subclass. Abstract Factory: multiple factory methods,
multiple product types, all products from the same family. The distinction:
Factory Method is about 'how to create one product.' Abstract Factory is
about 'how to create a consistent set of products.'"

#### Mechanism
- "Walk me through adding a new product family (third theme) vs adding
  a new product type to an existing family."

🗣️ "Adding a new family (HighContrast theme): create one new class
`HighContrastFactory implements UIFactory` with implementations for
all three factory methods. Zero changes to existing code. Open/Closed
Principle satisfied in the family dimension.
Adding a new product type (Tooltip): add `createTooltip()` to the
`UIFactory` interface. Every concrete factory (`LightThemeFactory`,
`DarkThemeFactory`, existing third) must implement `createTooltip()`.
This is a breaking change across all factories. Abstract Factory is
NOT open/closed in the product dimension. This is the main weakness -
if the product family grows frequently, each growth requires updating
all concrete factories."

#### Comparison
- "Compare Abstract Factory vs Factory Method vs Builder."

🗣️ "Three Creational patterns, three problems. Factory Method: virtual
constructor - a method that creates one product, overridden by subclasses
for different product types. One product hierarchy. Abstract Factory:
virtual constructor suite - multiple factory methods, each creating one
product type, all products consistent within a family. Multiple product
hierarchies, one factory interface per family. Builder: step-by-step
construction of a single complex object - set properties incrementally,
then build. Use Factory Method when you need one product type but do not
know which subtype. Use Abstract Factory when you need multiple products
that must be consistent. Use Builder when you need one complex object
with many optional configuration steps."

#### Scenario
- "Design an Abstract Factory for a cross-database reporting system
  that must work with Oracle and PostgreSQL."

🗣️ "I define `DatabaseFactory` interface with: `createQueryBuilder()`
(builds SQL in the dialect of the target DB), `createProcedureAdapter()`
(stored procedure calling convention differs), and `createPaginationStrategy()`
(Oracle uses ROWNUM, PostgreSQL uses LIMIT/OFFSET). `OracleFactory`
implements all three with Oracle-specific classes; `PostgresFactory`
does the same for PostgreSQL. The reporting engine injects `DatabaseFactory`
once; every query, procedure call, and pagination uses the correct
dialect family automatically. Adding a MySQL factory: create one class.
The reporting engine code: unchanged."

#### Debugging
- "The wrong factory was injected. How do you diagnose?"

🗣️ "Symptoms: wrong SQL dialect, wrong connection type, type cast
exceptions from incompatible product combinations. I trace by logging
`factory.getClass().getSimpleName()` at injection point. In Spring:
check profile activation (`spring.profiles.active`), check `@Bean`
`@Profile` or `@Conditional` annotations on factory beans, check for
multiple `@Bean` methods returning the same factory interface (ambiguous
injection). For ambiguous injection: Spring throws `NoUniqueBeanDefinitionException`
at startup - that is easy to catch. For wrong profile: add
`@ActiveProfiles` in tests and verify `Environment.getActiveProfiles()`
in the application."

#### Comparison Table

| Aspect | Factory Method | Abstract Factory | Builder |
|---|---|---|---|
| Products created | 1 | Multiple (family) | 1 (complex) |
| Pattern structure | Inheritance | Composition | Fluent API |
| Extension dimension | Product subtype | Product family | Object configuration |
| Adding new type | Add subclass | Add factory | Add builder step |
| Use case | One product, unknown subtype | Product families | One complex object |

---

### ⚖️ Comparison Table

| Factor | Abstract Factory | Factory Method | Prototype | Builder |
|---|---|---|---|---|
| Products per factory | Multiple (family) | One | N/A (copies) | One (complex) |
| Enforces consistency | Yes (family) | No | No | No |
| Extension cost (new family) | 1 new class | 1 new subclass | 1 new prototype | N/A |
| Extension cost (new product type) | N classes (breaking) | N/A | N/A | Add step |
| Runtime swap | Yes (inject new factory) | No (class hierarchy) | N/A | No |
| Best for | Multi-product families | Single-product variety | Clone-based creation | Complex single object |

---

### 🔥 Field Q&A

**Q: You have a Spring app that must work with three different notification
providers (SendGrid, Mailgun, AWS SES) where each provider has three
related components: sender, tracker, and bounce handler. How do you
apply Abstract Factory?**

A: Define `NotificationFactory` interface with `createSender()`,
`createTracker()`, and `createBounceHandler()`. Each method returns the
abstract type. Concrete implementations: `SendGridFactory`,
`MailgunFactory`, `SesFactory`, each returning the three provider-specific
classes. Spring `@Bean` method returns the concrete factory based on
`notification.provider` configuration. Application services inject
`NotificationFactory` and call the factory methods - they never know the
provider. Swapping from SendGrid to AWS SES in production: change one
config property, restart. The consistency guarantee: the sender, tracker,
and bounce handler are always from the same provider.

**Q: What happens when you need a new notification component (template
renderer) in the Abstract Factory?**

A: Add `createTemplateRenderer()` to the `NotificationFactory` interface.
This is a breaking change: all three existing concrete factories
(`SendGridFactory`, `MailgunFactory`, `SesFactory`) must implement the
new method. In a team where multiple people own the concrete factories,
this requires coordination. Mitigation: provide a default method in the
interface (`default TemplateRenderer createTemplateRenderer() { return new DefaultTemplateRenderer(); }`) - concrete factories can override it or
accept the default. Java 8 interface default methods partially alleviate
the extension cost in the product dimension.

**Q: When would you choose Abstract Factory vs injecting each product
separately?**

A: Inject separately when the products are independent - they do not need
to be from the same family. Use Abstract Factory when the products have
a family constraint: they must be compatible with each other. If you inject
`Button` and `Checkbox` separately, nothing prevents a misconfiguration
that injects a `DarkButton` with a `LightCheckbox`. The Abstract Factory
prevents this by construction: one factory, one family.

---

# Prototype Pattern

---
id: DP-014
title: Prototype Pattern
category: Design Patterns
difficulty: ★★☆
interview_weight: medium
asked_at: Mid+
seniority: mid-senior
tags: #design-patterns, #prototype, #creational, #clone, #deep-copy
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Prototype creates new objects by cloning an existing object (the
> prototype) rather than using `new`. When creating an object from
> scratch is expensive (database query, network call, complex
> initialization) and many similar objects are needed, Prototype
> clones a cached prototype. Java's `Cloneable` and `clone()` method
> is the language-level Prototype implementation.

**3 minutes (Senior):**
> Prototype addresses two problems: expensive construction and subclass
> proliferation. For expensive construction: instead of querying the
> database for a configuration object on every request, cache one
> prototype and clone it. For subclass proliferation: when you need
> to create instances of classes determined at runtime, Prototype lets
> you register prototype instances and clone the right one by name,
> avoiding a factory class hierarchy.
>
> The critical technical challenge: clone must produce a deep copy.
> Java's `Object.clone()` performs a shallow copy - only the object's
> direct fields are copied, not the objects those fields reference.
> If the prototype has a `List<Item>` field and shallow copy is used,
> the clone shares the list with the original. Mutating the clone's
> list mutates the original. Production code must perform deep copy for
> mutable referenced objects.
>
> Spring's `ApplicationContext.getBean()` with `@Scope("prototype")`
> is named after this pattern: each call returns a new instance.
> Spring serialization-based deep copy is one technique for Prototype
> in Java.

**Blank Mind Recovery:**

**(1) Restate:** "Prototype - the pattern that creates new objects by
copying existing ones."

**(2) First principles:** "Problem: creating a new object is expensive
or complex. I have an existing object that is already set up correctly.
Solution: copy the existing object instead of creating a new one from
scratch."

**(3) Bridge:** "Like a copy machine: you have a master document (prototype),
you make copies. Each copy is independent. Much faster than typing
the document from scratch each time."

---

### 📘 Concept Explanation

**What it is:**
Prototype specifies the kinds of objects to create using a prototypical
instance, and creates new objects by copying this prototype.

**The problem it solves:**
Object creation is expensive (database load, complex calculation,
external API call) or the exact class to instantiate is determined at
runtime. Prototype avoids re-running the expensive construction and
avoids hard-coding class names.

**How it works:**

```
Prototype interface:
  + clone(): Prototype

ConcretePrototype implements Prototype:
  - expensiveData: ComplexObject
  + clone():
      // Deep copy all mutable fields
      copy = new ConcretePrototype()
      copy.expensiveData = this.expensiveData.deepCopy()
      return copy

PrototypeRegistry:
  - prototypes: Map<String, Prototype>
  + register(name, prototype)
  + create(name): Prototype
      return prototypes.get(name).clone()

// Usage:
registry.register("fullConfig",
    loadFullConfigFromDB())  // expensive, done once

// Later, cheap:
Config cfg = (Config) registry.create("fullConfig");
cfg.customize(userSettings);  // mutate the clone, not original
```

**The key insight:**
The prototype registry separates "knowing which kind to create"
(the registry keys) from "creating the kind" (the clone implementation).
New variants are registered at startup; cloning is always cheap (relative
to original construction).

**When to use it:**
- When constructing an object is more expensive than copying it
- When you need many similar objects that differ in a few details
- When the exact class to instantiate is determined at runtime (registry
  key lookup)

**When NOT to use it:**
- When objects have circular references: deep copy of circular
  structures requires special handling
- When `clone()` semantics are unclear for your objects (Java's
  `Cloneable` is poorly designed - prefer copy constructors or
  factory methods that copy)
- When construction cost is negligible: overengineering

**Alternatives:**
- **Copy constructor** - `new MyObject(existingObject)` - explicit and
  clear; preferred over `Cloneable` in Java
- **Serialization/deserialization** - serialize to byte stream and
  deserialize; always deep copy but slow
- **Builder from existing** - `MyObject.builder().from(existing).build()`
- **Factory Method** - when the class to create is known; Prototype
  when it is determined at runtime by key lookup

---

### 💻 Code Example

```java
// BAD: Shallow copy - shared mutable state
public class GameCharacter implements Cloneable {
    private String name;
    private int level;
    // BAD: List is mutable - shallow copy shares reference
    private List<String> inventory;

    @Override
    public Object clone() throws CloneNotSupportedException {
        return super.clone(); // SHALLOW COPY - inventory shared!
    }
}

GameCharacter original = createCharacter();
GameCharacter clone =
    (GameCharacter) original.clone();
clone.getInventory().add("Sword"); // Also adds to original!
// Bug: original.getInventory() now contains "Sword"
```

> **Code walkthrough:** `super.clone()` copies the object but not
> the objects its fields reference. `inventory` in `original` and
> `clone` point to the same `List` object. Any mutation of the clone's
> inventory mutates the original. This is the canonical Prototype bug.

```java
// GOOD: Deep copy with copy constructor
public class GameCharacter {
    private final String name;
    private int level;
    private List<String> inventory;  // mutable
    private Stats stats;             // mutable

    // Copy constructor - explicit and readable
    public GameCharacter(GameCharacter source) {
        this.name = source.name;           // String: immutable, ok
        this.level = source.level;         // int: primitive, ok
        // Deep copy mutable collections:
        this.inventory = new ArrayList<>(source.inventory);
        // Deep copy mutable objects:
        this.stats = new Stats(source.stats); // Stats copy constructor
    }

    // Alternatively: static factory method
    public static GameCharacter copyOf(GameCharacter source) {
        return new GameCharacter(source);
    }
}

// Usage:
GameCharacter template = loadTemplateFromDB("warrior");
// Cheap - copy constructor not database query:
GameCharacter player1 = new GameCharacter(template);
GameCharacter player2 = new GameCharacter(template);
player1.getInventory().add("Sword");
// player2.getInventory() is independent - still empty
```

> **Code walkthrough:** Copy constructor makes the deep copy explicit
> and readable. Every mutable field is explicitly copied. Immutable
> fields (`String`, primitives) can be shared safely. The `Stats` deep
> copy uses its own copy constructor. No magic `super.clone()` with
> hidden shallow copy semantics.

```java
// PRODUCTION: Prototype Registry for template objects
@Component
public class EmailTemplateRegistry {
    private final Map<String, EmailTemplate> templates =
        new HashMap<>();

    @PostConstruct
    public void loadTemplates() {
        // Expensive: loads from DB including all HTML content
        templates.put("welcome",
            emailRepo.findByType("WELCOME"));
        templates.put("shipping",
            emailRepo.findByType("SHIPPING"));
        templates.put("invoice",
            emailRepo.findByType("INVOICE"));
    }

    // Returns a deep copy - caller can customize safely
    public EmailTemplate get(String type) {
        EmailTemplate proto = templates.get(type);
        if (proto == null) throw new TemplateNotFoundException(type);
        return proto.deepCopy(); // clones the template
    }
}

@Service
public class EmailService {
    private final EmailTemplateRegistry templateRegistry;

    public void sendWelcome(User user) {
        // Cheap: copy, not DB query
        EmailTemplate email = templateRegistry.get("welcome");
        // Customize the copy
        email.setRecipient(user.getEmail());
        email.setVariable("name", user.getName());
        send(email); // send customized copy
    }
}
```

> **Code walkthrough:** Templates are loaded once at startup (expensive:
> DB queries). Each request calls `get()` which returns a deep copy
> (cheap: in-memory copy). The copy is then customized with the specific
> user's data and sent. The prototype in the registry is never mutated.
> Without Prototype: every email would require a DB query to get
> the fresh template.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Prototype creates new objects by copying existing ones. It is useful
> when creating an object from scratch is expensive (like loading from
> a database), so you load it once and clone it for each use. The critical
> detail: Java's `Object.clone()` does a shallow copy. For objects with
> mutable fields (Lists, Maps, custom objects), you must implement a
> deep copy to avoid shared mutable state between the original and the clone.

*Push deeper:* "I prefer copy constructors over Java's `Cloneable` interface.
`Cloneable` has a confusing design (the marker interface does not define
`clone()`), and `super.clone()` returns a shallow copy that you must
manually deepen. A copy constructor is explicit about what gets copied."

---

**Senior / Staff (5+ years):**
> Prototype in production appears as a template registry: load expensive
> objects once, clone for each use. The design decision: copy constructor
> vs serialization for deep copy. Copy constructor: fast, explicit, but
> must be maintained as the object evolves. Serialization deep copy:
> always complete, but slow (30x slower than copy constructor for typical
> objects). For high-throughput systems, copy constructor is mandatory.
>
> Spring's `@Scope("prototype")` is named after this pattern but is
> actually a factory scope: each `getBean()` call creates a new instance
> via normal construction, not cloning. The naming is unfortunate. True
> Prototype (cloning) is used in template registries, object pools, and
> when initialization cost is the dominant concern.

*Push deeper:* "The Java Record (Java 16+) `with()` pattern is the modern
Prototype for immutable objects: `record Point(int x, int y)` and then
`point.with(y -> y + 1)` creates a new record with the modified field.
For fully immutable objects, shallow copy IS deep copy (immutable objects
cannot be mutated). The Prototype complexity exists only for mutable objects."

---

### ❓ Questions You Will Be Asked

#### Definition
- "What is the Prototype pattern?"
- "What is the difference between shallow copy and deep copy?"

🗣️ "Prototype creates new objects by cloning existing instances rather
than using `new` with a constructor. The prototype is a pre-built object
stored in a registry. Creating a new instance means cloning the prototype.
Shallow vs deep copy: shallow copy duplicates the object but not the
objects its fields reference - the copy and the original share the same
referenced objects. Mutations to shared referenced objects affect both.
Deep copy duplicates the object AND all objects it references, recursively.
Mutations to the copy's internal objects do not affect the original. For
Prototype to be safe, the clone must be a deep copy of any mutable state."

#### Mechanism
- "Implement a deep copy for an object with a nested list."

🗣️ "Copy constructor approach - preferred:
`public Config(Config source) { this.name = source.name; this.values = new ArrayList<>(source.values); this.settings = new HashMap<>(source.settings); }`
Each mutable collection is explicitly constructed from the source's
collection. Immutable fields (String, primitives) are copied by
assignment. For nested objects: each nested object needs its own copy
constructor, and you call `new NestedObject(source.nestedObject)`.
Serialization approach (simpler for deeply nested, complex objects):
serialize to bytes and deserialize. Always produces a complete deep copy
but has significant performance overhead for frequent cloning."

#### Comparison
- "Compare Prototype vs Factory Method vs Copy Constructor."

🗣️ "Factory Method creates new instances by calling a factory method
that uses constructors - it does not clone. It is closed to extensions
without subclassing. Prototype creates instances by cloning - it avoids
re-running construction. The prototype is a registry of pre-built
instances. Copy Constructor is not a pattern but an idiom: a constructor
that accepts an existing instance and copies it. In Java, copy constructor
is the preferred implementation of Prototype over `Cloneable`. It is
explicit about what is copied and does not have the design problems
of Java's `clone()` method. Prototype (the pattern) describes the intent:
clone-based creation. Copy constructor (the idiom) is the implementation."

#### Scenario
- "You have 10,000 requests per second, each needing a copy of a configuration
  object loaded from a database. How do you apply Prototype?"

🗣️ "Load the configuration object once at startup and store it in a
`PrototypeRegistry`. Each request calls `registry.get('config')` which
returns a deep copy. The deep copy uses a copy constructor (fast: microseconds).
Benchmark: object construction from DB = 50ms per request. Copy constructor
= 0.1ms. At 10,000 RPS: construction from DB = 500 seconds of DB time
per second (infeasible). Copy constructor = 1 second of CPU time per second
(feasible). The cache invalidation strategy: listen for configuration change
events (Observer); when a change occurs, reload the master prototype in the
registry. Ongoing requests use the old copy; new requests get a copy of
the new master."

#### Debugging
- "A cloned object is mutating the original. How do you diagnose?"

🗣️ "This is a shallow copy bug. I add a test: create original, clone it,
mutate the clone's mutable field (add an item to a list), assert that
the original's field was not changed. This test will fail for a shallow
copy. Then I trace through the `clone()` or copy constructor to find
which mutable field is not being deep-copied. Tools: JVM heap analysis
(check that the original and clone have different object references for
the shared field). Fix: add explicit copy construction for every mutable
referenced type. The rule: every mutable field (List, Map, Date, custom
object) must be explicitly copied. Every immutable field (String, Integer,
enum, primitives) can be shared."

#### Comparison Table

| Aspect | Object.clone() | Copy Constructor | Serialization |
|---|---|---|---|
| Depth | Shallow (must override) | Explicit (you control) | Always deep |
| Performance | Fast (native) | Fast (explicit) | Slow (30x slower) |
| Type safety | Unchecked cast required | Typed | Unchecked cast |
| Interface required | Cloneable (marker) | None | Serializable |
| Best for | Simple objects (all fields immutable/primitive) | Objects with known mutable state | Complex nested objects, legacy code |

---

### ⚖️ Comparison Table

| Factor | Prototype | Factory Method | Abstract Factory | Builder |
|---|---|---|---|---|
| Creation mechanism | Clone existing | New via factory | New via family factory | Construct step by step |
| When construction is expensive | Yes (key use case) | No benefit | No benefit | No benefit |
| Runtime type selection | Registry key lookup | Not applicable | Factory swap | Not applicable |
| Mutable state risk | High (shallow copy bug) | None | None | Low (immutable result) |
| Java implementation | Cloneable or copy constructor | Interface + implementations | Interface per family | Builder inner class |
| Best for | Template objects, expensive init | Single product variety | Product families | Complex single object |

---

### 🔥 Field Q&A

**Q: In Spring, what is the difference between `@Scope("singleton")`,
`@Scope("prototype")`, and the Prototype design pattern?**

A: Spring's scope naming is confusing. `@Scope("singleton")`: Spring
creates one instance of the bean and returns the same instance every
time. `@Scope("prototype")`: Spring creates a new instance via the
constructor every time `getBean()` is called. This is NOT the GoF
Prototype pattern - it uses normal construction, not cloning. GoF
Prototype: create new instances by cloning a cached prototype object,
specifically to avoid the cost of construction. Spring's prototype scope
is "new instance per injection" not "clone from prototype." For GoF
Prototype in Spring: you would implement it as a `PrototypeRegistry`
`@Component` with explicit clone methods, as shown in the code examples.

**Q: How do you handle Prototype for objects with circular references?**

A: Circular references in deep copy: Object A references B, B references
A. A naive recursive deep copy loops infinitely. Solution: track visited
objects during the copy operation using an `IdentityHashMap`. When you
encounter an already-visited object, return the copy you already made
for it (not a new copy). This is the same approach used by serialization
frameworks. In production: avoid circular references in prototyped objects.
If unavoidable: use a copy library (Apache Commons `BeanUtils`, MapStruct,
or a custom `DeepCopyContext`) that handles cycles. Never implement
deep copy for circular structures by hand.

**Q: When would you use Prototype over caching the object directly?**

A: Use the original cached object when: it is immutable (no mutation
needed), or when all reads are stateless. Use Prototype (clone) when:
the caller needs to customize the object for their use case without
affecting other callers. The template registry use case is the canonical
example: the email template is shared, but each email needs recipient-
specific variable substitution. Cloning allows the customization without
requiring a new DB load and without corrupting the shared template.
