# Records: Value Semantics and Compact Constructors

**TL;DR** - Records (Java 16) are immutable data carriers. They
auto-generate equals, hashCode, toString, and accessor methods
from their components. Compact constructors enable validation
without re-assigning all fields.

**Interview Weight:** medium - Records are a Java 14-16+ feature
increasingly expected in modern Java interviews.

---

### 🎯 Model Answer

**30 seconds:**

> Records define immutable value types. You declare the components;
> Java generates the canonical constructor, accessor methods, and
> correct equals/hashCode/toString. Compact constructors add validation
> logic without re-assigning all fields. Records cannot extend other
> classes, all components are final.

**3 minutes (Senior):**

> Records solve the "data carrier boilerplate" problem: previously,
> a simple DTO required a constructor, equals, hashCode, toString, and
> getters - 40-60 lines for 3 fields. Records reduce this to one line
> per component.
>
> The canonical constructor (with all components as parameters) is
> auto-generated. A compact constructor lets you add validation or
> normalization without calling `this.field = parameter` for every
> field - the auto-generated assignments happen after the compact
> constructor body.
>
> Records are implicitly final (no subclassing) and all components
> are implicitly private final. This enforces value semantics: a
> record's identity is fully determined by its components. Two records
> with the same components are equal - period. This makes them ideal
> for DTOs, value objects, and projection types in JPA queries.

---

### 📘 Concept Explanation

**Record Syntax**

```java
record Point(int x, int y) { }
// Equivalent to a class with:
// - private final int x; private final int y;
// - public Point(int x, int y) { this.x = x; this.y = y; }
// - public int x() { return x; }  // accessor, NOT getX()
// - public int y() { return y; }
// - public boolean equals(Object o) { ... component-based ... }
// - public int hashCode() { ... component-based ... }
// - public String toString() { return "Point[x=..., y=...]"; }
```

**Compact Constructor**

```java
record Range(int low, int high) {
    // Compact constructor: body runs, THEN components are assigned
    // You can validate and normalize, but assignments happen after
    Range {
        if (low > high) throw new IllegalArgumentException(
            "low must be <= high but was: %d > %d".formatted(low, high)
        );
        // Normalize: assign to the compact params (not this.field)
        low = Math.max(low, 0);  // adjust param, assignment auto-done
    }
}
```

**Custom Canonical Constructor**

When you need full control:

```java
record Measurement(double value, String unit) {
    // Full canonical constructor
    public Measurement(double value, String unit) {
        if (value < 0) throw new IllegalArgumentException("value < 0");
        this.value = value;
        this.unit = Objects.requireNonNull(unit, "unit required");
    }
}
```

**Record Restrictions**

- Implicitly `final` - cannot be extended
- Cannot extend any class (implicitly extends `Record`)
- All components are `private final`
- Cannot declare instance fields beyond components
- Can implement interfaces
- Can have static fields and methods
- Can have additional instance methods

**Records vs Classes for Value Objects**

Records: best for pure value objects with no behavior beyond
data access. DTOs, result types, coordinate points.

Regular class: when you need inheritance, mutable state, JPA entity
mapping (JPA requires no-arg constructor and mutable fields), or
non-component instance fields.

---

### 💻 Code Example

```java
// BAD: verbose DTO class
class UserDto {
    private final long id;
    private final String name;
    private final String email;

    public UserDto(long id, String name, String email) {
        this.id = id;
        this.name = name;
        this.email = email;
    }

    public long getId() { return id; }
    public String getName() { return name; }
    public String getEmail() { return email; }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof UserDto u)) return false;
        return id == u.id &&
               Objects.equals(name, u.name) &&
               Objects.equals(email, u.email);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, name, email);
    }

    @Override
    public String toString() {
        return "UserDto{id=%d, name='%s', email='%s'}"
            .formatted(id, name, email);
    }
}
// 35 lines for 3 fields
```

> **Code walkthrough:** Every field in a DTO requires 4 lines: field
> declaration, constructor assignment, getter, and participation in
> equals/hashCode. For 3 fields: 35 lines. For 10 fields: ~110 lines.
> The cognitive cost of reviewing and maintaining this is high, and
> errors (missing field in hashCode) are invisible.

```java
// GOOD: record - all of the above in one line
record UserDto(long id, String name, String email) { }
// equals: component-based (correct)
// hashCode: component-based (correct, consistent with equals)
// toString: "UserDto[id=1, name=Alice, email=alice@example.com]"
// accessors: id(), name(), email() - not getters
```

> **Code walkthrough:** The record declaration provides everything
> the class above had - plus correct by construction. You cannot
> accidentally forget a field in equals because equals is auto-generated
> from all components. The accessor naming (`id()` not `getId()`) is
> a record convention; be aware that frameworks expecting `getX()` style
> (Thymeleaf, some serializers) may need configuration.

```java
// Compact constructor validation
record Email(String address) {
    Email {
        Objects.requireNonNull(address, "address required");
        address = address.strip().toLowerCase();  // normalize
        if (!address.contains("@"))
            throw new IllegalArgumentException(
                "invalid email: " + address
            );
        // 'this.address = address' happens automatically after this block
    }
}

Email e1 = new Email(" Alice@Example.com ");  // normalizes to alice@example.com
Email e2 = new Email("alice@example.com");
e1.equals(e2);  // true - same normalized address
```

> **Code walkthrough:** The compact constructor validates and normalizes
> the address parameter. After the block, the record auto-assigns
> `this.address = address` using the (now-normalized) parameter.
> No explicit field assignments are needed - compact constructors are
> for validation and normalization, not assignment. This guarantees
> that no `Email` instance can hold an invalid or un-normalized address.

**How to test:** Test compact constructor validation (valid input,
boundary cases, invalid input throws expected exception). Test that
equals/hashCode work correctly for equal and unequal records.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
"Records are immutable data classes where you declare fields in the
header and Java generates equals, hashCode, toString, and accessors.
Compact constructors let you add validation."

**Senior / Staff:**
"Records are the correct Java answer to the value object pattern -
immutable, structurally equal, no behavior beyond data access.
They replace 80% of the DTO boilerplate I've seen in every Java codebase.

The accessor naming (`id()` not `getId()`) is a deliberate choice -
records are not JavaBeans. Some frameworks (Lombok-generated classes,
older Spring serializers) expect JavaBeans convention. Check your
serialization library: Jackson supports records natively since 2.12,
but you may need to configure `jackson-module-kotlin` or record-specific
annotations in older setups.

For JPA: records cannot be entities (JPA requires no-arg constructor,
mutable fields, and often inheritance). But records work perfectly
as JPA projections:

````java
interface UserProjection {
    record Summary(String name, String email) implements UserProjection {}
}
// Spring Data query: native query or @Query returns record projections
```"

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---------------|---------|--------|
| 1 | "Record accessors are getX()" | Record accessor for component `x` is `x()`, not `getX()`. Some frameworks expecting JavaBeans convention may not find it. | Framework fails to serialize a record field |
| 2 | "Records can extend other classes" | Records implicitly extend java.lang.Record and are final. Cannot extend anything else. | Compile error when attempting inheritance |
| 3 | "Records are mutable via methods" | Records cannot have non-component instance fields. Components are final. All state is set at construction. | Assuming records can be updated in place |
| 4 | "Compact constructors assign fields" | Compact constructors run BEFORE the auto-generated assignments. They can modify the parameter values; assignments happen after the block. | Mistakenly adding explicit `this.field = param` causing compile errors |
| 5 | "Records work as JPA entities" | JPA requires: no-arg constructor (records have none), mutable fields (records have none), ability to extend entities. Records are incompatible with JPA entity mapping. | Runtime mapping failure |

---

### 🚨 Failure Modes and Diagnosis

**FM1 - Jackson serialization missing record fields**

*Symptom:* JSON output is `{}` (empty) for a record, or fields are
missing.

*Root Cause:* Old Jackson version that doesn't support records, or
configuration expecting JavaBeans getter names.

*Diagnostic:*
```bash
# Check Jackson version - must be 2.12+ for record support
mvn dependency:tree | grep jackson-databind
# Must be >= 2.12.0
````

_Fix:_ Upgrade Jackson to 2.12+. If using older version, add
`@JsonProperty` annotations to components or use `@JsonAutoDetect`
to detect `ANY` visibility.

**FM2 - Compact constructor mutates fields incorrectly**

_Symptom:_ Compile error: "cannot assign to final variable" in
compact constructor.

_Root Cause:_ Attempting to assign `this.field = value` in compact
constructor. Compact constructors assign to the parameter name,
not `this.field`.

_Fix:_

```java
record Name(String first, String last) {
    Name {
        // WRONG: this.first = first.trim();  // compile error
        first = first.trim();   // CORRECT: assign to parameter
        last = last.trim();     // auto-assigned to this.last after block
    }
}
```

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                                                        |
| ---------------- | ------------------------------------------------------------------------------------------- |
| 5 minutes        | Record syntax + what is auto-generated + restrictions                                       |
| 15 minutes       | Add compact constructor + accessor naming + JPA incompatibility                             |
| 30 minutes       | Add Jackson serialization + record projections in JPA                                       |
| Under pressure   | "Immutable data carrier: auto equals/hashCode/toString; compact constructor for validation" |

**[JUNIOR] Q1 - Conceptual**
_What does a record auto-generate?_

For `record Point(int x, int y) {}`, Java auto-generates:

1. **Canonical constructor**: `public Point(int x, int y)` assigning
   both components
2. **Accessor methods**: `public int x()` and `public int y()`
   (note: `x()`, not `getX()`)
3. **equals**: component-by-component comparison (same type + same values)
4. **hashCode**: hash of all components (consistent with equals)
5. **toString**: `"Point[x=3, y=4]"` format

What records do NOT generate: no-arg constructor, setters, `getX()`-style
getters.

_What separates good from great:_ Immediately noting the accessor
naming convention (`x()` not `getX()`) - a common gotcha with
frameworks.

---

**[MID] Q2 - Hands-on**
_Write a record with validation._

```java
// Positive amount value object
record Money(BigDecimal amount, String currency) {
    Money {
        Objects.requireNonNull(amount, "amount required");
        Objects.requireNonNull(currency, "currency required");
        if (amount.compareTo(BigDecimal.ZERO) < 0)
            throw new IllegalArgumentException(
                "amount cannot be negative: " + amount
            );
        currency = currency.toUpperCase().strip();
        if (currency.length() != 3)
            throw new IllegalArgumentException(
                "currency must be 3-letter ISO code: " + currency
            );
    }
}

Money usd = new Money(new BigDecimal("100.00"), "usd");
// currency is normalized to "USD" automatically
```

_What separates good from great:_ Using compact constructor correctly
(modifying parameters, not using `this.field =`), and normalizing
the currency.

---

**[SENIOR] Q3 - Trade-off**
_When would you choose a record vs Lombok @Value vs a plain class?_

| Scenario                                    | Choice                | Reason                                          |
| ------------------------------------------- | --------------------- | ----------------------------------------------- |
| Pure value object, no framework constraints | Record                | Built-in, no dependencies                       |
| JPA entity                                  | Plain class           | JPA incompatible with records                   |
| Legacy Java (<16)                           | Lombok @Value         | Records not available                           |
| Need to extend another class                | Plain class           | Records cannot extend                           |
| Needs `getX()` accessors for framework      | Lombok @Value         | Generates standard getters                      |
| Performance-critical, millions of instances | Record or plain class | Records have same footprint as equivalent class |

Records are the modern default for new code on Java 16+. Lombok
@Value is a valid alternative when records are unavailable or when
JavaBeans getter naming is required. Never use a plain class for
pure value objects when records are available.

_What separates good from great:_ The JPA incompatibility - the
most common reason to avoid records in enterprise code.

---

### ⚖️ Comparison Table

| Aspect              | Record       | Lombok @Value | Plain class              |
| ------------------- | ------------ | ------------- | ------------------------ |
| Boilerplate         | Zero         | Near-zero     | High                     |
| Mutability          | Immutable    | Immutable     | Configurable             |
| JPA Entity          | No           | No            | Yes                      |
| Inheritance         | No           | No            | Yes                      |
| Accessor style      | `x()`        | `getX()`      | `getX()` (by convention) |
| equals/hashCode     | Auto-correct | Auto-correct  | Manual or Lombok         |
| Java version        | 16+          | Any           | Any                      |
| External dependency | None         | Lombok        | None                     |

**Deciding factor:** Use records for new value objects in Java 16+.
Use Lombok @Value for pre-16 or when framework requires `getX()` style.
Use plain classes for entities, mutable objects, or types requiring
inheritance.

---

---

# Sealed Classes: Exhaustive Polymorphism and ADTs

**TL;DR** - Sealed classes restrict which classes can extend them.
Combined with switch expressions, they enable exhaustive pattern
matching (no default needed). They model Algebraic Data Types (ADTs)
in Java.

**Interview Weight:** medium - sealed classes are Java 17+ and appear
in senior interviews about modern Java and type system design.

---

### 🎯 Model Answer

**30 seconds:**

> Sealed classes restrict the set of permitted subtypes. The compiler
> knows every possible subtype at compile time. Combined with switch
> expressions, this enables exhaustive checking - the compiler
> verifies all cases are handled without a default clause. This is
> the ADT pattern for Java.

**3 minutes (Senior):**

> Before sealed classes, the type hierarchy was open - any code in
> any package could add a subtype. This made exhaustive dispatch
> impossible: you could never be sure your switch handled all cases.
>
> Sealed classes close the hierarchy. `permits` lists the allowed
> subtypes. The compiler verifies completeness of switch expressions
> over sealed types - if you miss a permitted subtype, it is a compile
> error, not a runtime missing-case.
>
> This enables Algebraic Data Types (ADTs) in Java. A `Shape` sealed
> class with `Circle`, `Rectangle`, and `Triangle` is a sum type:
> any Shape is exactly one of those three. This is how you model
> closed domains where all cases are known.
>
> Practical use: result types (`Success | Failure`), command/event
> hierarchies, expression trees in interpreters, state in state machines.

---

### 📘 Concept Explanation

**Sealed Class Syntax**

```java
// Sealed supertype
public sealed class Shape permits Circle, Rectangle, Triangle { }

// Each permitted subtype must be: final, sealed, or non-sealed
public final class Circle extends Shape {
    double radius;
    Circle(double radius) { this.radius = radius; }
}

public final class Rectangle extends Shape {
    double width, height;
    Rectangle(double w, double h) { this.width = w; this.height = h; }
}

public non-sealed class Triangle extends Shape {
    // non-sealed: allows arbitrary further extension of Triangle
    double base, height;
}
```

**Permitted Subtype Modifiers**

- `final`: no further subtyping
- `sealed`: further restricted to another permits list
- `non-sealed`: opens the hierarchy below this point (escapes sealing)

**Sealed Interfaces**

```java
sealed interface Result<T> permits Result.Success, Result.Failure {
    record Success<T>(T value) implements Result<T> { }
    record Failure<T>(String error, Throwable cause) implements Result<T> { }
}
```

**Exhaustive Switch with Sealed Types**

```java
double area(Shape shape) {
    return switch (shape) {
        case Circle c    -> Math.PI * c.radius() * c.radius();
        case Rectangle r -> r.width() * r.height();
        case Triangle t  -> 0.5 * t.base() * t.height();
        // No default needed - compiler verifies all cases covered
    };
}
// Adding a new Shape subtype NOT in permits = compile error
// Adding a permitted type NOT in switch = compile error
```

**Sealed Classes = Closed Polymorphism**

Open hierarchy (before Java 17): anyone can add subtypes; no exhaustive dispatch.
Sealed hierarchy: only listed subtypes exist; exhaustive dispatch is compile-verified.

---

### 💻 Code Example

```java
// BAD: open hierarchy with defensive default
sealed // pretend this is not sealed for the BAD example
class JsonValue {
    // Subclasses: JsonString, JsonNumber, JsonBoolean, JsonNull, JsonArray, JsonObject
}

String serialize(JsonValue value) {
    return switch (value) {
        case JsonString s -> "\"" + s.value() + "\"";
        case JsonNumber n -> String.valueOf(n.value());
        // forgot JsonBoolean, JsonNull, JsonArray, JsonObject
        default -> throw new IllegalStateException(
            "unhandled type: " + value.getClass()  // runtime error
        );
    };
}
// New JsonType added later -> default catches it silently
// Bug only appears when serialize() is actually called with JsonType
```

> **Code walkthrough:** The `default` clause silently masks missing
> cases. When a new JSON value type is added, the switch compiles
> without warning and throws at runtime. The bug is discovered in
> production, not at the keyboard.

```java
// GOOD: sealed hierarchy with exhaustive switch
public sealed interface JsonValue
    permits JsonString, JsonNumber, JsonBoolean, JsonNull,
            JsonArray, JsonObject { }

public record JsonString(String value) implements JsonValue { }
public record JsonNumber(double value) implements JsonValue { }
public record JsonBoolean(boolean value) implements JsonValue { }
public record JsonNull() implements JsonValue { }
// JsonArray and JsonObject omitted for brevity

String serialize(JsonValue value) {
    return switch (value) {
        case JsonString s   -> "\"" + s.value() + "\"";
        case JsonNumber n   -> String.valueOf(n.value());
        case JsonBoolean b  -> String.valueOf(b.value());
        case JsonNull n     -> "null";
        case JsonArray a    -> serializeArray(a);
        case JsonObject o   -> serializeObject(o);
        // No default - compiler verifies all 6 cases are handled
    };
}
// Adding a new JsonValue type not in permits = COMPILE ERROR
// Removing a case from switch = COMPILE ERROR (missing coverage)
```

> **Code walkthrough:** The sealed interface makes the complete set
> of JsonValue types explicit. The switch expression is exhaustive by
> compile-time guarantee. Adding a new permitted subtype to the
> interface makes every switch on JsonValue a compile error until
> the new case is handled. This propagates the change requirement
> to all callers automatically - the compiler tells you every place
> you need to update.

**How to test:** Test each subtype's serialization. Add a test that
verifies all permitted types are handled (can be done via reflection
on the sealed class).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
"Sealed classes limit which classes can extend them. The `permits`
clause lists allowed subtypes. With switch expressions, you get
compile-time verification that all subtypes are handled."

**Senior / Staff:**
"Sealed classes are how Java got algebraic data types. An ADT is a
type where you know all possible variants at definition time. The
classic example from functional languages: `type Result = Ok of value | Err of string`.
In Java: `sealed interface Result<T> permits Success, Failure`.

The exhaustive switch is the payoff: every switch on a sealed type
is compile-verified. This eliminates an entire class of runtime errors
where 'unhandled case' is caught by a defensive default.

The practical trade-off: sealed classes are closed extension points.
This is intentional for closed domains (JSON value types, AST nodes,
state machine states). For open extension points (plugins, user-defined
types), keep the hierarchy open. The question to ask: 'Should a library
user be able to add subtypes?' If yes: interface. If no: sealed."

---

### ⚠️ Common Misconceptions

| #   | Misconception                                     | Reality                                                                                                                               | Danger                                                                   |
| --- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| 1   | "Sealed classes prevent all extension"            | Permitted subtypes marked non-sealed can be extended further. Sealed closes the immediate level, not all levels.                      | Unexpected extension through non-sealed subtype                          |
| 2   | "Permits list can be in any package"              | Permitted subtypes must be in the same package (or same module if using JPMS) as the sealed class.                                    | Compile error when trying to define permitted subtype in another package |
| 3   | "switch default is still needed for sealed types" | For sealed types, if all permitted types are covered, no default is needed. Adding one suppresses the exhaustiveness check.           | Masking missing cases with a default                                     |
| 4   | "Sealed requires record subtypes"                 | Sealed works with regular classes, final classes, and records. Records are common because they complement sealed interfaces for ADTs. | Confusion about which kinds of subtypes are valid                        |
| 5   | "Sealed is just for pattern matching"             | Sealed classes also formalize API contracts - they document which subtypes are part of the library's design.                          | Missing the documentation/design intent aspect                           |

---

### 🚨 Failure Modes and Diagnosis

**FM1 - Compile error when extending sealed class from another package**

_Symptom:_ "class is not allowed to extend sealed class" compiler error.

_Root Cause:_ Permitted subtype is in a different package from the
sealed class. Unless using JPMS with exports, this fails.

_Fix:_ Move the permitted subtype to the same package, or use `non-sealed`
on a subtype that is then extended from outside.

**FM2 - Switch exhaustiveness broken by non-sealed subtype**

_Symptom:_ Compiler requires a default even for what appears to be
an exhaustive switch over a sealed hierarchy.

_Root Cause:_ One of the permitted subtypes is `non-sealed`. The
compiler cannot enumerate subtypes of a `non-sealed` class.

_Diagnostic:_

```java
// If any permitted subtype is non-sealed:
non-sealed class SpecialShape extends Shape { }

// Then switch over Shape cannot be exhaustive:
switch (shape) {
    case Circle c -> ...;
    case Rectangle r -> ...;
    case SpecialShape s -> ...;  // could be any subtype of SpecialShape
    // default required - compiler doesn't know all SpecialShape subtypes
}
```

_Fix:_ Use `final` or `sealed` for permitted subtypes to maintain
exhaustiveness.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                                           |
| ---------------- | ------------------------------------------------------------------------------ |
| 5 minutes        | Sealed syntax + permits + what each modifier means                             |
| 15 minutes       | Add exhaustive switch + ADT framing                                            |
| 30 minutes       | Add same-package restriction + non-sealed tradeoff + practical domain examples |
| Under pressure   | "Closed hierarchy; compiler verifies exhaustive dispatch; no default needed"   |

**[MID] Q1 - Conceptual**
_What is a sealed class and what problem does it solve?_

A sealed class restricts which classes can extend it. The compiler
knows the complete set of permitted subtypes at compile time.

Problem solved: before sealed classes, switch statements on a type
hierarchy needed a `default` clause because anyone could add a new
subtype. The `default` clause silently masks new subtypes added later.

With sealed classes:

- The permitted subtypes are exhaustively listed
- Switch expressions over sealed types can omit `default`
- The compiler verifies all cases are handled
- Adding a new permitted subtype makes all incomplete switches compile errors

_What separates good from great:_ Explaining the "default clause
masking" problem - this is the concrete bug sealed classes prevent.

---

**[SENIOR] Q2 - Architecture**
_How would you use sealed classes to model a domain result type?_

```java
// Result type: operation either succeeds with T, or fails with error
sealed interface Result<T> permits Result.Success, Result.Failure {
    record Success<T>(T value) implements Result<T> { }
    record Failure<T>(String message, Throwable cause)
        implements Result<T> { }

    // Factory methods (optional convenience)
    static <T> Result<T> ok(T value) { return new Success<>(value); }
    static <T> Result<T> fail(String msg, Throwable cause) {
        return new Failure<>(msg, cause);
    }
}

// Service returning Result
Result<User> fetchUser(long id) {
    try {
        return Result.ok(repository.findById(id)
            .orElseThrow(() -> new NotFoundException(id)));
    } catch (NotFoundException e) {
        return Result.fail("User not found: " + id, e);
    } catch (Exception e) {
        return Result.fail("Database error", e);
    }
}

// Caller with exhaustive dispatch
Result<User> result = fetchUser(userId);
String response = switch (result) {
    case Result.Success<User> s -> "Found: " + s.value().name();
    case Result.Failure<User> f -> "Error: " + f.message();
    // exhaustive - no default
};
```

This pattern replaces exceptions for expected failure cases (not
exceptional cases). The caller is forced to handle both Success
and Failure at compile time.

_What separates good from great:_ Explaining that Result types
are for EXPECTED failures (not found, validation fail) while
exceptions remain appropriate for unexpected/exceptional failures.

---

**[STAFF] Q3 - Trade-off**
_When is an open interface better than a sealed class?_

Sealed = correct when you own the complete set of variants:

- AST nodes in a compiler you write
- HTTP response states (200, 4xx, 5xx) in your framework
- Payment states (Pending, Authorized, Settled, Refunded)

Open = correct when third parties extend your type:

- Plugin system where users define new handlers
- Testing framework where users write custom matchers
- ORM where users define new column type mappings

The question: "Who needs to add new variants?" If only the library
author: seal it. If library users: open interface.

The middle ground: sealed class with a `non-sealed` permitted subtype.
This lets the library define the core variants (sealed) while allowing
user extension via the non-sealed slot.

_What separates good from great:_ The middle ground pattern - sealed
with one non-sealed "extension slot" is a legitimate design choice.

---

### ⚖️ Comparison Table

| Aspect            | Open class            | Sealed class               | Final class         |
| ----------------- | --------------------- | -------------------------- | ------------------- |
| Who can extend    | Anyone                | Permitted list only        | Nobody              |
| Exhaustive switch | No (requires default) | Yes (compile-time)         | Yes (only one type) |
| Use case          | Extension point       | Closed domain              | No subtyping needed |
| Adding subtypes   | Anywhere              | Requires modifying permits | N/A                 |
| API contract      | Open                  | Documented closed set      | Closed              |

**Deciding factor:** Sealed = closed set of known variants. Open =
extension point for third parties. Final = no inheritance needed.

---

---

# Pattern Matching: instanceof, Switch Expressions, Deconstruction

**TL;DR** - Pattern matching eliminates manual casts after instanceof
checks. `instanceof Type t` binds the variable inline. Switch expressions
with patterns enable exhaustive type dispatch. Deconstruction patterns
(Java 21+) destructure records inline in case labels.

**Interview Weight:** medium - heavily tested in Java 16-21 upgrade
discussions and modern API design interviews.

---

### 🎯 Model Answer

**30 seconds:**

> Pattern matching removes the cast after instanceof. `if (obj instanceof String s)` binds `s` directly - no explicit cast needed. Switch expressions extend this to type dispatch across multiple types with exhaustiveness checking.

**3 minutes (Senior):**

> Before pattern matching, the idiom was:
> `if (obj instanceof String) { String s = (String) obj; }` - check then
> cast. Pattern matching merges these: `if (obj instanceof String s)`.
> The binding `s` is in scope only where the check is true.
>
> Switch expressions with patterns extend this to multiple types:
> `case Circle c -> area(c)` handles type check, cast, and binding
> in one step. Combined with sealed classes, this creates exhaustive
> type dispatch verified at compile time.
>
> Deconstruction patterns (Java 21) let you destructure records:
> `case Point(int x, int y)` matches a Point and extracts its
> components in the case label. Guard patterns add conditions:
> `case User u when u.isAdmin()`. These features compose - you can
> nest patterns within patterns for complex structural matching.

---

### 📘 Concept Explanation

**Pattern Matching for instanceof (Java 16)**

```java
// BEFORE: check then cast
if (obj instanceof String) {
    String s = (String) obj;  // redundant cast
    System.out.println(s.length());
}

// AFTER: pattern variable binding
if (obj instanceof String s) {
    System.out.println(s.length());  // s bound directly
}

// Negative check works too
if (!(obj instanceof String s)) {
    return;  // s NOT in scope here
}
System.out.println(s.length());  // s IS in scope (definite assignment)
```

**Switch Expressions with Patterns (Java 21 - stable)**

```java
// Type pattern in switch
String describe(Object obj) {
    return switch (obj) {
        case Integer i -> "int: " + i;
        case Long l    -> "long: " + l;
        case String s  -> "str: " + s;
        case null      -> "null";  // null must be explicit case
        default        -> "other: " + obj.getClass().getSimpleName();
    };
}
```

**Guard Patterns (when clause)**

```java
String classify(Number n) {
    return switch (n) {
        case Integer i when i < 0  -> "negative int";
        case Integer i when i == 0 -> "zero";
        case Integer i             -> "positive int";
        case Long l when l > 1_000_000L -> "large long";
        case Long l                -> "small long";
        default                    -> "other number";
    };
}
```

**Deconstruction Patterns (Java 21)**

```java
record Point(int x, int y) { }
record Circle(Point center, double radius) { }

// Deconstruct in instanceof
if (shape instanceof Circle(Point(int x, int y), double r)) {
    System.out.println("center at " + x + "," + y + " radius " + r);
}

// Deconstruct in switch
double area(Shape shape) {
    return switch (shape) {
        case Circle(Point center, double r) ->
            Math.PI * r * r;
        case Rectangle(Point tl, Point br) ->
            Math.abs(br.x() - tl.x()) * Math.abs(br.y() - tl.y());
    };
}
```

**Scope Rules for Pattern Variables**

Pattern variables have flow-sensitive scope:

```java
// s is in scope only on the true branch
if (obj instanceof String s) {
    // s usable here
}
// s NOT usable here

// In && - s in scope on right side (true path)
if (obj instanceof String s && s.length() > 5) {
    // s is the long string
}

// In || - s NOT in scope on right (either path can be false)
// if (obj instanceof String s || s.length() > 5) // COMPILE ERROR
```

---

### 💻 Code Example

```java
// BAD: manual cast chain - verbose and error-prone
double totalArea(List<Shape> shapes) {
    double total = 0;
    for (Shape shape : shapes) {
        if (shape instanceof Circle) {
            Circle c = (Circle) shape;  // redundant cast
            total += Math.PI * c.radius() * c.radius();
        } else if (shape instanceof Rectangle) {
            Rectangle r = (Rectangle) shape;  // redundant cast
            total += r.width() * r.height();
        } else {
            throw new IllegalStateException("Unknown: " + shape);
        }
    }
    return total;
}
```

> **Code walkthrough:** Every branch does an instanceof check then
> an explicit cast. The cast is guaranteed to succeed (we just checked)
> but the compiler cannot eliminate it without pattern matching. The
> throw-on-unknown has no exhaustiveness guarantee - new shape types
> are silent at compile time.

```java
// GOOD: pattern matching switch with sealed types
sealed interface Shape permits Circle, Rectangle, Triangle { }
record Circle(double radius) implements Shape { }
record Rectangle(double width, double height) implements Shape { }
record Triangle(double base, double height) implements Shape { }

double totalArea(List<Shape> shapes) {
    double total = 0;
    for (Shape shape : shapes) {
        total += switch (shape) {
            case Circle c ->
                Math.PI * c.radius() * c.radius();
            case Rectangle(double w, double h) ->
                w * h;  // deconstruction pattern
            case Triangle(double base, double height) ->
                0.5 * base * height;
            // No default - sealed ensures exhaustiveness
        };
    }
    return total;
}
```

> **Code walkthrough:** Pattern matching eliminates all explicit casts.
> The Rectangle and Triangle cases use deconstruction to extract
> components directly in the case label. The switch is exhaustive by
> compiler guarantee (sealed + all cases covered). Adding a new Shape
> type to the sealed interface makes this switch a compile error until
> the new case is added.

**How to test:** Test each pattern branch. Test the guard (`when`)
boundaries - values just above and below the threshold. Test null
handling explicitly in switch expressions.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
"Pattern matching instanceof removes the explicit cast after a type
check. `if (obj instanceof String s)` binds s directly. In switch
expressions, `case Circle c` handles the type check, cast, and
binding together."

**Senior / Staff:**
"Pattern matching is the Java realization of structural matching from
functional languages (Scala's match, Haskell's case). The key insight:
checking a type and then using that type's API is one logical operation,
but Java split it into two steps (check + cast). Pattern matching
unifies them.

The practical win is at the intersection with sealed classes. When you
have a sealed hierarchy and a switch with patterns, the compiler tracks
coverage. This is the closest Java gets to ML-style exhaustiveness
checking. The deconstruction patterns extend this further - you can
match on record structure, not just type.

The subtle edge: guard patterns (`when`) are evaluated sequentially.
Order matters - a `case Integer i` without a guard before
`case Integer i when i > 0` is unreachable. The compiler warns."

---

### ⚠️ Common Misconceptions

| #   | Misconception                                      | Reality                                                                                          | Danger                                                     |
| --- | -------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------- |
| 1   | "Pattern variable scope is the whole method"       | Scope is flow-sensitive - only where the check is definitely true.                               | Compile error or incorrect scope assumption                |
| 2   | "switch with patterns always needs default"        | With sealed types and all cases covered, no default. With non-sealed types, default is required. | Unnecessary default masking coverage gaps                  |
| 3   | "Guard (when) clauses short-circuit the switch"    | Guards are part of the case - if the guard fails, matching continues to the next case.           | Unexpected fall-through when guard fails                   |
| 4   | "instanceof pattern matching is Java 14 (preview)" | Stable (non-preview) since Java 16. Switch patterns stable since Java 21.                        | Avoiding useful features due to incorrect version tracking |
| 5   | "Deconstruction works on all classes"              | Deconstruction patterns work on records only (in Java 21). Not on regular classes.               | Compile error on non-record types                          |

---

### 🚨 Failure Modes and Diagnosis

**FM1 - Unreachable case in switch (guard ordering)**

_Symptom:_ Compiler warning "this case label is dominated by a
preceding case label."

_Root Cause:_ A general case appears before a specific guard case.

```java
// BAD: unreachable case
switch (n) {
    case Integer i             -> "any int";    // matches all Integer
    case Integer i when i < 0  -> "negative";  // unreachable
}

// GOOD: specific guards first
switch (n) {
    case Integer i when i < 0  -> "negative";
    case Integer i when i == 0 -> "zero";
    case Integer i             -> "positive";   // catch-all last
}
```

_Fix:_ Place more specific patterns (with guards) before general ones.

**FM2 - NullPointerException in switch without null case**

_Symptom:_ NPE when passing null to a switch expression with patterns.

_Root Cause:_ Traditional switch throws NPE on null selector. Pattern
switch does too, unless `case null` is explicitly handled.

_Fix:_

```java
switch (obj) {
    case null  -> "null";     // explicit null handling
    case String s -> "string: " + s;
    default -> "other";
}
```

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                          |
| ---------------- | ------------------------------------------------------------- |
| 5 minutes        | instanceof pattern + case type pattern + scope rules          |
| 15 minutes       | Add guard patterns + ordering rules                           |
| 30 minutes       | Add deconstruction patterns + null handling + sealed synergy  |
| Under pressure   | "Type check + bind in one; switch dispatch; guards with when" |

**[MID] Q1 - Hands-On**
_Show how pattern matching improves a type-checking method._

```java
// Old style
String format(Object value) {
    if (value instanceof Integer) {
        return "int:" + (Integer) value;
    } else if (value instanceof String) {
        return "str:" + ((String) value).trim();
    }
    return "?:" + value;
}

// With pattern matching
String format(Object value) {
    return switch (value) {
        case Integer i -> "int:" + i;
        case String s  -> "str:" + s.trim();
        case null      -> "null";
        default        -> "?:" + value;
    };
}
```

Improvements: no explicit casts, exhaustive structure, null handled
explicitly, return type enforced by switch expression (all paths must
return or throw).

_What separates good from great:_ Mentioning the null case - the
interviewer often asks "what about null?" immediately after.

---

**[SENIOR] Q2 - Trade-off**
_When would you use a visitor pattern instead of pattern matching?_

Pattern matching wins when:

- You control the type hierarchy (can seal it)
- Operations are simple and few
- The dispatch logic belongs in one place (e.g., a serializer)

Visitor wins when:

- Third parties need to add new operations without changing the
  hierarchy (open extension point for operations)
- You have many operations on the same hierarchy and want each
  operation encapsulated in its own class
- The hierarchy is not sealed (external extensibility)

The Expression Problem: sealed + pattern matching solves "add new
types easily, operations hard"; Visitor solves "add new operations
easily, types hard."

_What separates good from great:_ Framing as the Expression Problem -
this is the theoretical foundation that explains when each approach wins.

---

**[STAFF] Q3 - Architecture**
_How would you combine sealed classes and pattern matching to build
a type-safe command dispatcher?_

```java
// Sealed command hierarchy
sealed interface Command permits
    CreateUser, DeleteUser, UpdateEmail, BanUser { }

record CreateUser(String name, String email) implements Command { }
record DeleteUser(long userId) implements Command { }
record UpdateEmail(long userId, String newEmail) implements Command { }
record BanUser(long userId, String reason) implements Command { }

// Dispatcher using pattern matching with deconstruction
CommandResult dispatch(Command cmd) {
    return switch (cmd) {
        case CreateUser(var name, var email) ->
            userService.create(name, email);
        case DeleteUser(var id) ->
            userService.delete(id);
        case UpdateEmail(var id, var email) ->
            userService.updateEmail(id, email);
        case BanUser(var id, var reason) ->
            userService.ban(id, reason);
        // No default - adding new Command = compile error here
    };
}
```

Benefits:

- Adding a new Command type makes every dispatcher a compile error
- Deconstruction avoids repeated `cmd.userId()` calls
- The switch is exhaustive - no missed commands
- Each branch is a single expression - easy to read and test

_What separates good from great:_ Noting that `var` in deconstruction
patterns lets the compiler infer component types - reduces verbosity
without losing type safety.

---

### ⚖️ Comparison Table

| Feature                 | Java version | Benefit               | Limitation                       |
| ----------------------- | ------------ | --------------------- | -------------------------------- |
| instanceof pattern      | 16 (stable)  | Removes cast          | Single type only                 |
| switch type patterns    | 21 (stable)  | Multi-type dispatch   | null needs explicit case         |
| Guard patterns (when)   | 21 (stable)  | Conditional matching  | Order matters (no reorder check) |
| Deconstruction patterns | 21 (stable)  | Structural matching   | Records only                     |
| Nested patterns         | 21 (stable)  | Compose pattern logic | Readability decreases with depth |

**Deciding factor:** Pattern matching is the idiomatic modern Java for
type dispatch. Use it over instanceof+cast chains wherever you target
Java 16+. For full exhaustiveness, combine with sealed classes.


---

---

# Annotations: Retention, Target, and Custom Processors

**TL;DR** - Annotations are metadata tags on code elements. Three
retention policies control when the annotation is available: SOURCE
(compile-time tools), CLASS (bytecode, default), RUNTIME (reflection).
Target restricts which code elements can be annotated. Custom annotations
power frameworks (Spring, JPA, Jackson) and compile-time code generation.

**Interview Weight:** medium - tested in framework internals questions
and APT/code generation discussions.

---

### 🎯 Model Answer

**30 seconds:**
> Annotations are metadata. `@Retention` controls lifecycle: SOURCE
> annotations are discarded after compilation, CLASS annotations
> survive to bytecode, RUNTIME annotations are visible via reflection.
> `@Target` restricts where the annotation can be placed (method,
> field, type, etc.).

**3 minutes (Senior):**
> Every annotation a developer uses - `@Override`, `@Autowired`,
> `@Entity`, `@JsonProperty` - is backed by a `@interface` definition
> with retention and target metadata.
>
> SOURCE annotations are for compile-time tooling: `@Override` just
> tells the compiler "verify this actually overrides something." It
> is discarded after compilation. No runtime cost.
>
> CLASS annotations (the default) are written to bytecode but not
> loaded by the JVM into the runtime class model. Bytecode manipulation
> tools (like AspectJ or certain bytecode weavers) can read them.
> Most developers do not use this policy directly.
>
> RUNTIME annotations survive to runtime and can be read via reflection:
> `method.getAnnotation(MyAnnotation.class)`. This is how Spring reads
> `@Autowired`, how JPA reads `@Entity`, how Jackson reads `@JsonProperty`.
>
> Annotation processors (APT) run at compile time. They can generate
> new source files (Lombok, Dagger, MapStruct). They receive the
> SOURCE/CLASS annotations of the types being compiled and emit
> new `.java` files or resources.

---

### 📘 Concept Explanation

**Defining a Custom Annotation**

```java
import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME)    // visible via reflection
@Target({ElementType.METHOD,           // applicable to methods
         ElementType.TYPE})            // and classes
@Documented                           // appears in Javadoc
@Inherited                            // subclasses inherit (class-level only)
public @interface Audited {
    String action() default "UNKNOWN";  // element with default
    boolean logArgs() default false;    // boolean element
}
```

**Retention Policies**

| Policy | Survives To | Readable By |
|--------|-------------|-------------|
| `SOURCE` | Compilation only | APT processors, IDEs |
| `CLASS` | Bytecode | Bytecode tools (ASM, Javassist) |
| `RUNTIME` | JVM runtime | Reflection API |

**Target Element Types**

```java
ElementType.TYPE           // class, interface, enum, record
ElementType.FIELD          // fields (including enum constants)
ElementType.METHOD
ElementType.PARAMETER
ElementType.CONSTRUCTOR
ElementType.LOCAL_VARIABLE
ElementType.ANNOTATION_TYPE
ElementType.PACKAGE
ElementType.TYPE_PARAMETER  // T in <T>
ElementType.TYPE_USE        // anywhere a type is used (Java 8+)
ElementType.RECORD_COMPONENT // Java 14+
```

**Reading Annotations at Runtime**

```java
// Read annotation from a method
Method method = MyClass.class.getMethod("doWork");
if (method.isAnnotationPresent(Audited.class)) {
    Audited a = method.getAnnotation(Audited.class);
    System.out.println(a.action());  // "UNKNOWN" if not set
    System.out.println(a.logArgs()); // false
}

// Read all annotations
Annotation[] all = method.getDeclaredAnnotations();
```

**Repeatable Annotations (Java 8+)**

```java
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@Repeatable(Roles.class)       // container annotation
@interface Role {
    String value();
}

@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.TYPE)
@interface Roles {
    Role[] value();            // container holds array
}

@Role("ADMIN")
@Role("USER")
class AdminUser { }           // two @Role annotations
```

---

### 💻 Code Example

```java
// BAD: runtime check without annotation contract
class AuditInterceptor {
    void before(Method method) {
        // Check method name convention - fragile, no compile-time check
        if (method.getName().startsWith("audit_")) {
            log("auditing: " + method.getName());
        }
    }
}
```

> **Code walkthrough:** Method name conventions are fragile. A typo
> in the name bypasses the check silently. There is no compile-time
> signal that a method should be audited. Rename the method and
> auditing silently stops.

```java
// GOOD: annotation contract
@Retention(RetentionPolicy.RUNTIME)
@Target(ElementType.METHOD)
public @interface Audited {
    String action() default "";
    AuditLevel level() default AuditLevel.INFO;
}

// Applied to methods that need auditing
@Audited(action = "CREATE_ORDER", level = AuditLevel.WARN)
public Order createOrder(CreateOrderRequest req) {
    // ...
}

// Interceptor reads annotation
class AuditInterceptor {
    void before(Method method, Object[] args) {
        Audited annotation = method.getAnnotation(Audited.class);
        if (annotation == null) return;
        log.info("audit: action={} level={} args={}",
            annotation.action(),
            annotation.level(),
            annotation.logArgs() ? Arrays.toString(args) : "hidden"
        );
    }
}
```

> **Code walkthrough:** The `@Audited` annotation is the explicit
> contract. The `action` and `level` elements carry metadata directly
> to the interceptor. No naming convention required. The annotation
> is visible in IDE autocompletion. If the method is renamed, the
> annotation moves with it. The interceptor reads only annotated methods
> - unannotated methods are transparently bypassed.

```java
// Compile-time annotation processor (simplified APT)
@SupportedAnnotationTypes("com.example.Audited")
@SupportedSourceVersion(SourceVersion.RELEASE_17)
public class AuditProcessor extends AbstractProcessor {

    @Override
    public boolean process(
            Set<? extends TypeElement> annotations,
            RoundEnvironment roundEnv) {
        for (Element elem :
                roundEnv.getElementsAnnotatedWith(Audited.class)) {
            if (elem.getKind() != ElementKind.METHOD) {
                processingEnv.getMessager().printMessage(
                    Diagnostic.Kind.ERROR,
                    "@Audited must be on a method",
                    elem
                );
            }
        }
        return true;
    }
}
// This processor generates a compile ERROR (not runtime) if @Audited
// is placed on a field or class, despite @Target allowing TYPE.
```

> **Code walkthrough:** The annotation processor validates annotation
> usage at compile time. Even though `@Audited`'s `@Target` allows
> types, this processor adds an extra rule: only methods are valid.
> The error appears in the IDE and compiler output, not at runtime.
> This shifts validation from "fails at 2 AM in production" to
> "fails before commit."

**How to test:** Test annotation presence via reflection. Test
annotation element values. For processors, test with compilation
frameworks (JavaC API or compile-testing library).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
"Annotations add metadata to code. @Retention says when the annotation
is available (SOURCE, CLASS, RUNTIME). @Target says where it can be
placed (method, field, class). RUNTIME annotations are read by frameworks
via reflection."

**Senior / Staff:**
"Most Java developers work with annotations as consumers - applying
framework annotations. The interesting questions are producer-side:
when should I create a custom annotation vs. a different mechanism?

The answer: annotations work well when the metadata is stable and
declarative. `@Cacheable`, `@Transactional`, `@Validated` - these are
stable behaviors applied declaratively to methods. The annotation is
documentation of intent that tools enforce.

Annotation processors are the compilation side. Lombok uses SOURCE-
retention processing to generate constructors, getters, builders without
runtime overhead. MapStruct generates mapper implementations at compile
time. Dagger generates dependency injection without reflection. These
source-generation processors eliminate runtime reflection costs.

The trade-off: SOURCE processors require code generation. Generated
code appears in the target directory and can surprise developers who
do not know it is there. RUNTIME reflection is simpler but has reflection
overhead."

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---------------|---------|--------|
| 1 | "Default retention is RUNTIME" | Default is CLASS - bytecode-visible but not loadable via reflection. Most frameworks need RUNTIME explicitly. | Framework annotation not working at runtime |
| 2 | "@Inherited makes annotation available on all subclasses" | @Inherited only works for class-level annotations. Interface annotations are never inherited. | Assuming subclass inherits method-level annotations |
| 3 | "Annotation elements can be any type" | Elements must be primitive, String, Class, enum, annotation type, or array of the above. No List, no Map. | Compile error on invalid element type |
| 4 | "Changing annotation values is free" | Annotation values are constant at compile time. Dynamic values require runtime logic (e.g., Spring SpEL in @Value). | Trying to use expressions directly in annotation elements |
| 5 | "APT and runtime processing are the same" | APT runs at compile time and generates code. Runtime processors use reflection. Very different costs and use cases. | Confusing Lombok (APT) with Spring AOP (runtime) |

---

### 🚨 Failure Modes and Diagnosis

**FM1 - Framework annotation not visible via reflection**

*Symptom:* `method.getAnnotation(MyAnnotation.class)` returns null even
though the annotation is present in source.

*Root Cause:* Missing `@Retention(RetentionPolicy.RUNTIME)`. Default
is CLASS - annotation not loaded by reflection API.

*Diagnostic:*
```java
// Check declared retention
MyAnnotation.class.getAnnotation(Retention.class)
// If null or RetentionPolicy.CLASS -> not visible via reflection
```

*Fix:* Add `@Retention(RetentionPolicy.RUNTIME)` to the annotation definition.

**FM2 - @Inherited not working on interface annotations**

*Symptom:* Subclass or implementing class does not have expected annotation.

*Root Cause:* `@Inherited` only applies to class hierarchy (extends),
not interface hierarchy (implements). If the annotation is on an
interface, implementing classes do NOT inherit it.

*Fix:* Explicitly annotate each implementation, or use a different
mechanism (AOP pointcut on interface) to avoid the inheritance limitation.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach |
|---|---|
| 5 minutes | Three retention policies + read via reflection |
| 15 minutes | Custom annotation definition + @Target + @Inherited limits |
| 30 minutes | APT introduction + Lombok/MapStruct examples + compile vs runtime |
| Under pressure | "SOURCE=compile tools, CLASS=bytecode, RUNTIME=reflection" |

**[MID] Q1 - Conceptual**
*What do @Retention and @Target control on an annotation?*

`@Retention` controls the annotation's lifecycle:
- `RetentionPolicy.SOURCE`: discarded after compilation (compile-time
  tools only)
- `RetentionPolicy.CLASS`: written to .class bytecode (default; not
  accessible via reflection)
- `RetentionPolicy.RUNTIME`: loaded into JVM; accessible via
  `method.getAnnotation()`

`@Target` controls where the annotation can be applied:
- `ElementType.METHOD`, `TYPE`, `FIELD`, `PARAMETER`, etc.
- The compiler enforces target at the use site

```java
@Retention(RetentionPolicy.RUNTIME)  // visible via reflection
@Target(ElementType.METHOD)          // methods only
@interface Cacheable {
    int ttlSeconds() default 60;
}
```

*What separates good from great:* Knowing the default retention is
CLASS, not RUNTIME - a common source of "my framework annotation does
not work" bugs.

---

**[SENIOR] Q2 - Architecture**
*How does Spring's @Transactional use annotations internally?*

`@Transactional` has `@Retention(RetentionPolicy.RUNTIME)`.

At startup, Spring AOP creates proxies for beans with `@Transactional`
methods. The proxy intercepts method calls, reads the annotation via
reflection, and applies transaction management:

```java
// Spring AOP proxy checks annotation at invocation time
@Around("@annotation(transactional)")
public Object aroundTransactional(
        ProceedingJoinPoint pjp,
        Transactional transactional) throws Throwable {
    TransactionDefinition def = new DefaultTransactionDefinition();
    def.setPropagationBehavior(
        transactional.propagation().value());
    def.setIsolationLevel(
        transactional.isolation().value());
    // begin transaction, call pjp.proceed(), commit or rollback
}
```

The annotation carries all configuration: propagation, isolation,
readOnly, rollbackFor. The framework reads these at runtime for each
invocation. This is why `@Transactional` on a private method does
not work - the AOP proxy cannot intercept it.

*What separates good from great:* The private method limitation -
it is a direct consequence of how proxy-based AOP reads annotations.

---

**[STAFF] Q3 - Trade-off**
*When should you use compile-time annotation processing vs runtime
reflection?*

**Use compile-time APT when:**
- Code generation is needed (Lombok, MapStruct, Dagger, AutoFactory)
- The metadata is fully known at compile time
- Eliminating reflection overhead matters (Android, embedded)
- You want compile errors, not runtime failures

**Use runtime reflection when:**
- Dynamic behavior based on deployment configuration
- Frameworks need to adapt to user-defined classes at startup
- The full type set is not known at compile time (plugin systems)

**Examples:**
- Lombok `@Data`: APT - generates getters/setters in source
- Spring `@Autowired`: runtime reflection - wires beans at startup
- MapStruct `@Mapper`: APT - generates mapper implementation class
- Jackson `@JsonProperty`: runtime reflection - reads field names

**Trade-off:** APT eliminates reflection overhead but requires
generated code to be checked in or regenerated on build. Runtime
reflection is flexible but has startup cost and is harder to debug.

*What separates good from great:* Noting that MapStruct vs ModelMapper
is exactly this trade-off: compile-time APT (MapStruct, fast) vs
runtime reflection (ModelMapper, slower, more magic).

---

### ⚖️ Comparison Table

| Aspect | SOURCE Annotation | CLASS Annotation | RUNTIME Annotation |
|--------|------------------|-----------------|-------------------|
| Available to | APT processors | Bytecode tools | Reflection API |
| JVM overhead | None | None | Class loading + reflection |
| Use cases | Override checks, Lombok | ASM, AspectJ weaving | Spring, JPA, Jackson |
| Discarded at | Compilation | Class loading | Never |
| Default | No | Yes | No |

**Deciding factor:** RUNTIME for framework annotations read at
startup/invocation. SOURCE for compile-time tools and code generation.
CLASS rarely needed directly - it is the default for bytecode tools.


---

---

# Covariance, Contravariance, and Wildcard Capture

**TL;DR** - Covariance (`? extends T`) preserves the "is-a" direction
for reading: a `List<? extends Animal>` is a list you can read Animals
from. Contravariance (`? super T`) reverses direction for writing:
a `List<? super Dog>` is a list you can write Dogs into. PECS: Producer
Extends, Consumer Super.

**Interview Weight:** medium - one of the hardest generics topics.
Appears in senior-level generics deep-dives and API design discussions.

---

### 🎯 Model Answer

**30 seconds:**
> Covariance allows a more specific type where a general type is expected
> for reading. `List<? extends Animal>` accepts any `List<Cat>` or
> `List<Dog>`. You can read Animals from it but cannot add to it.
> Contravariance is the reverse: `List<? super Dog>` accepts any list
> that can hold Dogs - you can write but not type-safely read.

**3 minutes (Senior):**
> The problem: in Java, `List<Cat>` is NOT a `List<Animal>` even though
> `Cat` is an Animal. This is because `List<Animal>` allows adding any
> Animal (including dogs), but `List<Cat>` cannot hold dogs.
>
> Wildcards solve this at the API boundary with read/write trade-offs.
>
> `List<? extends Animal>` (covariant): you can read Animals from it
> (the actual list contains some subtype of Animal, so every element
> IS an Animal). You cannot add to it (you don't know the exact type -
> maybe it's a `List<Cat>` and you're trying to add a Dog).
>
> `List<? super Dog>` (contravariant): you can add Dogs to it (the list
> can hold Dog or any supertype, so Dog fits). You cannot type-safely
> read (you get back Object, not Dog).
>
> PECS is the mnemonic: Producer Extends, Consumer Super. A collection
> you read from (it produces values) uses `extends`. A collection you
> write into (it consumes values) uses `super`.

---

### 📘 Concept Explanation

**Why `List<Cat>` is not a `List<Animal>`**

```
List<Animal> animals = new ArrayList<Cat>(); // COMPILE ERROR

// If this worked:
animals.add(new Dog());    // would be legal for List<Animal>
                           // but List<Cat> cannot hold Dog
// -> type safety broken -> Java prevents this at compile time
```

Java generics are invariant by default: `List<Cat>` and `List<Animal>`
have no subtype relationship, even though `Cat extends Animal`.

**Covariance: ? extends T (read-only)**

```
List<? extends Animal> animals = new ArrayList<Cat>(); // OK

Animal a = animals.get(0);  // OK: element IS-AN Animal (guaranteed)
animals.add(new Cat());     // COMPILE ERROR: unknown actual type
                            // might be List<Dog>, Cat won't fit
```

Covariant wildcard = reading is safe, writing is forbidden.

**Contravariance: ? super T (write-only)**

```
List<? super Dog> dogs = new ArrayList<Animal>(); // OK

dogs.add(new Dog());         // OK: Dog IS-A Dog (any supertype list can hold)
dogs.add(new PoliceDog());   // OK: PoliceDog IS-A Dog
Object o = dogs.get(0);      // Only Object - actual type unknown (Animal? Object?)
Dog d = (Dog) dogs.get(0);   // Unsafe cast required
```

Contravariant wildcard = writing is safe, reading gives Object.

**PECS Mnemonic**

| Role | Wildcard | Can | Cannot |
|------|----------|-----|--------|
| Producer (source) | `extends` | read T | write T |
| Consumer (sink) | `super` | write T | read T (only Object) |

**Collections.copy() - PECS in action**

```java
// JDK source: both wildcards to maximize flexibility
public static <T> void copy(
    List<? super T> dest,     // destination: consumer
    List<? extends T> src) {  // source: producer
    // Can read from src (extends), write to dest (super)
    for (T t : src) dest.add(t);
}

// This allows:
List<Animal> dest = new ArrayList<>();
List<Cat> src = List.of(new Cat(), new Cat());
Collections.copy(dest, src);  // Cat -> Animal list (works!)
```

**Wildcard Capture**

The compiler internally names `?` as a capture variable:

```java
void reverse(List<?> list) {
    // list has type List<capture#1>
    // Cannot call list.add(list.get(0)) directly - type mismatch
    // Use helper method to capture the type:
    reverseHelper(list);
}

private <T> void reverseHelper(List<T> list) {
    // T is captured - can now read and write the same T
    for (int i = 0; i < list.size() / 2; i++) {
        T tmp = list.get(i);
        list.set(i, list.get(list.size() - i - 1));
        list.set(list.size() - i - 1, tmp);
    }
}
```

---

### 💻 Code Example

```java
// BAD: invariant parameter - too restrictive
// Only accepts exactly List<Number>, not List<Integer> or List<Double>
double sum(List<Number> numbers) {
    return numbers.stream()
        .mapToDouble(Number::doubleValue)
        .sum();
}

// Problem: cannot call sum(new ArrayList<Integer>())
// List<Integer> is NOT a List<Number> due to invariance
```

> **Code walkthrough:** The invariant parameter `List<Number>` is
> maximally restrictive. The method only reads from the list (produces
> values), so invariance is unnecessary. Every call site that has a
> `List<Integer>` or `List<Double>` must cast or copy - a design
> friction that should not exist.

```java
// GOOD: covariant (extends) for a read-only method
double sum(List<? extends Number> numbers) {
    return numbers.stream()
        .mapToDouble(Number::doubleValue)
        .sum();
}

// Now ALL of these work:
sum(new ArrayList<Integer>());    // List<Integer> ok
sum(new ArrayList<Double>());     // List<Double> ok
sum(new ArrayList<Number>());     // List<Number> ok
sum(new ArrayList<BigDecimal>()); // List<BigDecimal> ok
```

> **Code walkthrough:** `? extends Number` expresses the contract: "I
> only need to read Numbers from this list." Any list whose elements
> are Numbers (Integer, Double, BigDecimal) satisfies this. The method
> gains flexibility without losing type safety. Adding to the list
> inside the method would be a compile error - the covariant wildcard
> correctly prevents mutation.

```java
// Producer-consumer pipeline using PECS
class Pipeline<T> {
    // Add all items from source into this pipeline
    void addAll(Collection<? extends T> source) { // source PRODUCES T
        for (T item : source) items.add(item);
    }

    // Drain all items from this pipeline into destination
    void drainTo(Collection<? super T> dest) {    // dest CONSUMES T
        dest.addAll(items);
        items.clear();
    }

    private List<T> items = new ArrayList<>();
}

// Usage: Cat -> Animal -> Object (up the hierarchy)
Pipeline<Cat> catPipeline = new Pipeline<>();
catPipeline.addAll(List.of(new Cat(), new Siamese())); // List<Siamese> ok
List<Animal> animalSink = new ArrayList<>();
catPipeline.drainTo(animalSink);   // List<Animal> as super of Cat - ok
```

> **Code walkthrough:** `addAll` uses `? extends T` because the
> collection argument produces T values (we read from it). `drainTo`
> uses `? super T` because the collection argument consumes T values
> (we write into it). A Siamese (Cat subtype) can be added via
> `addAll(Collection<? extends Cat>)`. The result lands in
> `List<Animal>` via `drainTo(Collection<? super Cat>)`. PECS
> allows this natural widening flow.

**How to test:** Test with concrete subtypes and supertypes at
each API boundary. Verify the compile-time restrictions (cannot
add to extends, cannot typed-read from super).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
"Covariance is `? extends T` - you can read T values but not add.
Contravariance is `? super T` - you can add T values but get only
Object back. PECS: Producer Extends, Consumer Super."

**Senior / Staff:**
"Covariance and contravariance reflect the direction of type substitution
safety. The Liskov Substitution Principle says a subtype can be used
where a supertype is expected. But for mutable containers, naive
covariance breaks type safety - you could add a Dog to a List<Cat>.

Java's solution is use-site variance with wildcards. The `extends`
wildcard restricts the list to read-only use - no writes possible, so
the subtype relationship is safe to expose. The `super` wildcard
restricts to write-only use of the specific type - safe to write T,
but the actual type of stored elements is unknown.

Declaration-site variance (Kotlin's `out`/`in`, Scala's `+T`/`-T`)
is cleaner but requires the API to be designed with variance in mind.
Java's use-site approach is more flexible but more verbose.

Wildcard capture is the mechanism that lets you write methods operating
on `List<?>` by delegating to a generic helper that names the type.
It is necessary because `?` has no name, so you cannot write operations
that read and write the same element type without capturing."

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality | Danger |
|---|---------------|---------|--------|
| 1 | "`List<Cat>` is a `List<Animal>` (covariant by default)" | Java generics are invariant by default. `List<Cat>` and `List<Animal>` have no subtype relationship. Wildcards are required for covariant use. | Compile errors from passing List<Cat> where List<Animal> is expected |
| 2 | "You can add null to `List<? extends T>`" | You can add null to any List. The restriction is on typed elements - you cannot add `new Cat()` to `List<? extends Animal>`. | Unexpected null addition to a covariant list |
| 3 | "PECS means extends is for writing" | It is the opposite. Extends = reading (producer provides T to you). Super = writing (consumer accepts T from you). | Wrong wildcard choice in method signatures |
| 4 | "Wildcard `?` and Object are the same" | `List<?>` and `List<Object>` are different. `List<?>` can be any parameterized list. `List<Object>` is specifically a list of Objects - `List<String>` is NOT a `List<Object>`. | Wrong assumption about List<Object> accepting List<String> |
| 5 | "Contravariant lists give you back the right type" | `List<? super Dog>` gives back Object, not Dog. If you need both read and write, use an invariant parameter `List<T>`. | Unchecked casts when reading from super wildcard |

---

### 🚨 Failure Modes and Diagnosis

**FM1 - Wildcard capture error**

*Symptom:* "capture#1 of ? cannot be applied to capture#1 of ?"
compiler error when trying to set an element to a value read from
the same list.

*Root Cause:* The compiler treats each `?` occurrence as a potentially
different type.

```java
// FAILS: two separate capture variables
void swap(List<?> list, int i, int j) {
    list.set(i, list.get(j));  // set expects capture#1, get returns capture#1
                                // compiler cannot prove same
}

// FIX: wildcard capture helper
void swap(List<?> list, int i, int j) {
    swapHelper(list, i, j);
}
private <T> void swapHelper(List<T> list, int i, int j) {
    T tmp = list.get(i);
    list.set(i, list.get(j));
    list.set(j, tmp);
}
```

**FM2 - Over-restrictive API with invariant collections**

*Symptom:* Library users cannot pass `List<Integer>` where `List<Number>`
is expected, forcing unnecessary copies.

*Root Cause:* Method parameter declared `List<Number>` instead of
`List<? extends Number>` for a read-only operation.

*Diagnostic:* If the method only reads from the list, change to
`? extends T`. If it only writes, change to `? super T`. Both is invariant `T`.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach |
|---|---|
| 5 minutes | Invariance + extends = read + super = write |
| 15 minutes | PECS + why Cat not subtype of Animal list |
| 30 minutes | Wildcard capture + Collections.copy internals + declaration vs use-site variance |
| Under pressure | "Invariant by default; extends=read; super=write; PECS" |

**[MID] Q1 - Conceptual**
*Why is `List<Cat>` not a `List<Animal>` in Java?*

Because `List<Animal>` allows adding any Animal:
```java
List<Animal> animals = ...; // if this were List<Cat>...
animals.add(new Dog());     // legal for List<Animal>, breaks List<Cat>
```

If `List<Cat>` were a `List<Animal>`, you could add a Dog to a Cat
list - breaking type safety. Java prevents this by making generics
invariant: `List<Cat>` and `List<Animal>` have no subtype relationship.

To allow read-only access up the hierarchy, use `List<? extends Animal>`.
This is safe because you cannot add to it.

*What separates good from great:* The concrete example of "if it were
allowed, this illegal operation would compile" - connecting the rule
to its motivation.

---

**[SENIOR] Q2 - Hands-On**
*Implement a method that copies elements from a source into a destination
using PECS wildcards.*

```java
<T> void copy(
        List<? extends T> source,  // produces T (we read from it)
        List<? super T> dest) {    // consumes T (we write into it)
    for (T item : source) {
        dest.add(item);
    }
}

// Enables: copy from List<Integer> into List<Number>
List<Integer> ints = List.of(1, 2, 3);
List<Number> nums = new ArrayList<>();
copy(ints, nums);  // works: Integer extends Number, Number super Integer
```

PECS: source PRODUCES T values -> `extends`. dest CONSUMES T values
-> `super`. This signature is the most flexible possible while remaining
type-safe.

*What separates good from great:* Noting that this is exactly the
signature of `Collections.copy(dest, src)` in the JDK.

---

**[STAFF] Q3 - Trade-off**
*Compare Java use-site variance (wildcards) with Kotlin declaration-site
variance (in/out). When does each approach win?*

**Java wildcards (use-site):**
- Variance declared at each use site (`List<? extends T>`)
- The API designer writes invariant types; callers apply wildcards
- More verbose at call sites
- Flexible: same type can be used covariantly or contravariantly
  at different sites
- Works for any existing type, including JDK collections

**Kotlin declaration-site variance:**
- `out T` on the class declaration means always covariant
- `in T` means always contravariant
- Single declaration applies everywhere
- Cleaner call sites: `List<Cat>` IS a `List<Animal>` for `out`-typed List
- Requires foresight at API design time
- Cannot change variance on a type you do not control

**When each wins:**
- Use-site: when using existing types you do not own, when the same
  type needs both co- and contra-variance in different contexts
- Declaration-site: when designing a new API from scratch where the
  variance is fixed and universal (e.g., a read-only List interface
  should always be covariant)

Java 8+ added `Stream<T>` which is implicitly covariant in practice
(you only get T out, never add T in), but the type itself is not
declared with variance.

*What separates good from great:* The point that declaration-site
variance requires design foresight and is best applied to new APIs -
not a retrofit for existing types.

---

### ⚖️ Comparison Table

| Variance | Wildcard | Direction | Read | Write | Example |
|----------|----------|-----------|------|-------|---------|
| Invariant | `T` | Neither | T | T | `List<T>` parameter |
| Covariant | `? extends T` | Subtype UP | T (safe) | No | source/producer |
| Contravariant | `? super T` | Supertype UP | Object only | T (safe) | dest/consumer |
| Unbounded | `?` | Both | Object only | null only | wildcard passthrough |

**Deciding factor:** Read-only collection parameter -> `? extends T`.
Write-only collection parameter -> `? super T`. Both read and write ->
`T` (invariant). Only passing through -> `?` unbounded.
