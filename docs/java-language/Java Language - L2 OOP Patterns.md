---
layout: default
title: "Java Language - L2 OOP Patterns"
parent: "Java Language"
grand_parent: "SK Interview"
nav_order: 6
permalink: /java-language/l2-oop-patterns/
---

# Java Language - L2 OOP Patterns

## Inheritance and Polymorphism

### 🎯 Model Answer

**30 seconds:**
> Inheritance: a class extends another to reuse and extend behavior. Polymorphism: a
> reference of type Parent can hold a Child object; method calls dispatch to the
> actual runtime type. Runtime polymorphism via method overriding (`@Override`), compile-time
> polymorphism via method overloading. Liskov Substitution Principle: a subtype must be
> substitutable for its base type. `instanceof` / pattern matching (Java 16+) for type
> checking.

**3 minutes (Senior):**
> Key mechanics:
>
> 1. **Dynamic dispatch**: `animal.speak()` - the JVM calls the actual type's method at runtime
>    (virtual method table lookup). `Animal a = new Dog(); a.speak()` calls `Dog.speak()`.
>
> 2. **super keyword**: calls the superclass constructor (`super()`) or the overridden method
>    (`super.method()`). Must call `super()` as first statement in constructor if overriding.
>
> 3. **Covariant return types**: overriding method can return a more specific type than declared
>    in the superclass. `Animal clone()` overridden as `Dog clone()`.
>
> 4. **LSP violations**: the classic example - `Square extends Rectangle` breaks LSP.
>    Setting width on a Square also changes height (to maintain the square invariant),
>    but code expecting a Rectangle doesn't know this. Result: `setWidth(5)` followed by
>    `setHeight(3)` on a Square gives a 3x3 square (not 5x3 as Rectangle logic expects).
>
> 5. **Fragile base class problem**: adding a method to a base class that calls other
>    overridable methods - subclasses that override those methods change the base class
>    behavior unexpectedly.

**Blank Mind Recovery:**

**(1) Restate:** "Inheritance: `class Dog extends Animal`. Polymorphism: `Animal a = new Dog();
a.speak()` calls `Dog.speak()`. Override: `@Override`. Covariant return. super() calls parent.
LSP: subtype must behave correctly as supertype. Fragile base class: watch out when base class
methods call other overridable methods."

**(2) First principles:** "Inheritance = 'is-a' relationship + code reuse. Polymorphism =
treating different types uniformly through a common interface. The 'is-a' test: is every Dog
an Animal in ALL scenarios? If no: don't use inheritance. Design principle: prefer composition
over inheritance for code reuse when the 'is-a' relationship is uncertain."

**(3) Bridge:** "Inheritance is like a job title hierarchy. A 'SeniorEngineer extends Engineer':
has all Engineer behaviors plus more. Polymorphism: when the manager says 'all Engineers attend
the meeting', the SeniorEngineer goes too - the manager doesn't need to know the exact title.
LSP: if the manager says 'engineer, estimate this task in 2 hours', and the SeniorEngineer says
'I need 2 weeks' (different contract) - that's an LSP violation."

---

### 📘 Concept Explanation

**Inheritance mechanics and dispatch:**
```
INHERITANCE STRUCTURE:

  class Animal {
      String name;
      Animal(String name) { this.name = name; }
      
      // Overridable (virtual by default in Java):
      String speak() { return "..."; }
      
      // Final: cannot be overridden
      final String describe() { return name + " says " + speak(); }
  }
  
  class Dog extends Animal {
      Dog(String name) {
          super(name);  // must be first statement
      }
      
      @Override
      String speak() { return "Woof"; }  // dynamic dispatch target
  }

DYNAMIC DISPATCH (runtime method lookup):
  Animal a = new Dog("Rex");
  a.speak();          // -> Dog.speak() [runtime type = Dog]
  a.describe();       // -> Animal.describe() (final, no dispatch)
                      // inside describe(): speak() -> Dog.speak() (still dynamic!)
  
  // The runtime type is ALWAYS used for virtual method dispatch.
  // Even when called from a superclass method, virtual calls go to
  // the most-derived implementation.

STATIC BINDING (not dynamic dispatch):
  - static methods: bound at compile time to the declared type
  - private methods: bound at compile time (not virtual)
  - final methods: can be devirtualized by JIT (inlined)
  
  class Parent {
      static String staticMethod() { return "Parent"; }
  }
  class Child extends Parent {
      static String staticMethod() { return "Child"; }  // HIDES, not overrides
  }
  
  Parent p = new Child();
  p.staticMethod();   // -> "Parent" (compile-time type = Parent)
  Child c = new Child();
  c.staticMethod();   // -> "Child" (compile-time type = Child)

LSP VIOLATION EXAMPLE:
  class Rectangle {
      int width, height;
      void setWidth(int w)  { this.width = w; }
      void setHeight(int h) { this.height = h; }
      int area() { return width * height; }
  }
  
  class Square extends Rectangle {
      @Override void setWidth(int w)  { width = height = w; }  // LSP violation!
      @Override void setHeight(int h) { width = height = h; }  // same
  }
  
  void testRectangle(Rectangle r) {
      r.setWidth(5);
      r.setHeight(3);
      assert r.area() == 15;  // FAILS for Square: area = 9 (3x3)
  }
  // Square is not substitutable for Rectangle -> do NOT use inheritance here
  // Fix: common interface (Shape) with no setters, or make both immutable value types
```

---

### 💻 Code Example

> **Code walkthrough:** The template method pattern is the canonical use of inheritance
> done correctly. The base class defines the algorithm structure (invariant), subclasses
> provide the variable parts (variant). The contract is clear: override only the specified
> abstract methods; the template method is final.

```java
// CORRECT INHERITANCE: Template Method Pattern
abstract class DataExporter {
    // Template method: final so subclasses cannot change the algorithm structure
    final String export(List<Record> data) {
        String validated = validate(data);     // can override
        String formatted = format(validated);  // must override (abstract)
        return addHeader() + formatted + addFooter();
    }
    
    // Hook: overridable with a default (optional customization)
    protected String validate(List<Record> data) {
        return data.toString();  // default: no-op
    }
    protected String addHeader() { return ""; }
    protected String addFooter() { return ""; }
    
    // Abstract: must be overridden (the variable part)
    protected abstract String format(String data);
}

class CsvExporter extends DataExporter {
    @Override
    protected String format(String data) {
        return data.replace(";", ",");  // CSV format
    }
    @Override
    protected String addHeader() { return "col1,col2,col3\n"; }
}

class XmlExporter extends DataExporter {
    @Override
    protected String format(String data) {
        return "<data>" + data + "</data>";
    }
}

// WRONG: inheritance for code reuse (not 'is-a')
// BAD:
class JsonParser extends ArrayList<Token> {  // Parser IS NOT a List!
    void parse(String json) { /* uses add() */ }
}

// GOOD: composition
class JsonParser {
    private final List<Token> tokens = new ArrayList<>();  // HAS tokens
    void parse(String json) { /* uses tokens.add() */ }
    List<Token> getTokens() { return Collections.unmodifiableList(tokens); }
}

// PATTERN MATCHING (Java 16+): replaces instanceof cast chains
sealed interface Shape permits Circle, Rectangle, Triangle {}
record Circle(double radius) implements Shape {}
record Rectangle(double w, double h) implements Shape {}
record Triangle(double base, double height) implements Shape {}

double area(Shape shape) {
    return switch (shape) {
        case Circle c    -> Math.PI * c.radius() * c.radius();
        case Rectangle r -> r.w() * r.h();
        case Triangle t  -> 0.5 * t.base() * t.height();
        // No default needed: sealed type, exhaustive
    };
}
// 'sealed' + 'permits' ensures all cases are handled at compile time
```

> **Code walkthrough:** The `DataExporter` template method makes `export()` final, preventing
> subclasses from breaking the algorithm structure. The abstract `format()` forces subclasses
> to provide the specific implementation; the hook methods (`addHeader`, `addFooter`) provide
> optional customization with safe defaults. The sealed interface + pattern matching shows
> the modern alternative to class hierarchies for simple type-based dispatch: it's exhaustive
> at compile time, eliminating the need for a default branch or `instanceof` chains.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `extends` for inheritance. `@Override` for method overriding. Dynamic dispatch: calls the
> actual (runtime) type's method. `super()` calls parent constructor. LSP: subclass must work
> wherever the parent is used. Common mistake: inheriting for code reuse when there's no
> 'is-a' relationship.

---

**Senior / Staff (5+ years):**
> Prefer composition over inheritance for code reuse. Use inheritance for true 'is-a' relationships
> where substitutability is guaranteed. Template method: the correct inheritance pattern.
> Sealed classes (Java 17): replace open hierarchies with exhaustive, compile-time-checked
> alternatives. Fragile base class: avoid calling overridable methods in constructors (subclass
> override runs before subclass constructor body - partial initialization).

---

### ⚠️ Common Misconceptions

**Misconception 1: "Protected members are accessible only within the class hierarchy."**
Java `protected`: accessible in the same package (even without inheritance) AND accessible in
subclasses in any package. More visible than people expect. Sensitive data in a `protected`
field: accessible to any class in the same package (not just subclasses). Design: prefer
private fields with protected getters/setters over protected fields.

**Misconception 2: "You can override static methods."**
No. Static methods are class-level, not instance-level. A subclass can HIDE a static method
(declare a static method with the same signature), but it's not overriding. Virtual dispatch
does not apply. `Parent p = new Child(); p.staticMethod()` calls `Parent.staticMethod()` because
the compile-time type is `Parent`. This is one of the common interview gotcha questions.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Overridable method called in constructor causes NullPointerException.**
```
Symptom: NullPointerException inside the overridden method, even though
  the object was "just constructed."

Root cause:
  class Base {
      Base() {
          init();  // calls overridable method during construction!
      }
      protected void init() {}
  }
  
  class Derived extends Base {
      private final String name;  // not initialized yet when init() is called
      
      Derived(String name) {
          super();          // <- Base() runs first, calls init()
          this.name = name; // <- this runs AFTER super()
      }
      
      @Override
      protected void init() {
          System.out.println(name.length()); // NPE: name is null here!
      }
  }
  
  Execution order:
    1. Derived() begins
    2. super() (Base()) executes
    3. Base.init() -> Derived.init() (dynamic dispatch, not Base.init()!)
    4. Derived.init() accesses name -> null (step 4 hasn't run yet)
    5. NPE
    6. this.name = name (never reached)

Diagnosis:
  Stack trace: NPE in Derived.init() called from Base()
  Pattern: calling virtual methods in constructors

Fix:
  Option A: Make init() final in Base (no override -> no issue)
  Option B: Remove virtual call from constructor; call init() explicitly after construction
  Option C: Use a factory method pattern (private constructor + static factory):
    static Derived create(String name) {
        Derived d = new Derived(name);
        d.init();  // called AFTER constructor completes
        return d;
    }

Prevention: NEVER call overridable methods in constructors.
  Rule: constructors should only assign fields. Overridable method calls in constructors
  are a code smell that IDEs and static analysis (SpotBugs, Checkstyle) flag.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Dynamic dispatch mechanism | 2 minutes |
| Static vs instance method overriding | 1 minute |
| LSP violation example | 2 minutes |
| Template method pattern | 2 minutes |
| Fragile base class | 2 minutes |
| Sealed classes use case | 2 minutes |
| Constructor + virtual method | 2 minutes |
| Covariant return types | 1 minute |
| Composition vs inheritance | 2 minutes |

---

**Q1 (dynamic dispatch): How does Java's virtual method dispatch work?**

A: Every non-final, non-static, non-private method is virtual. Each object has a vtable pointer
(virtual method table) set to the actual runtime class's method table. `animal.speak()`:
(1) dereference the object reference, (2) follow the vtable pointer, (3) look up `speak()` in
the vtable of the actual class (Dog), (4) call it. This happens at every virtual call site
unless the JIT inlines or devirtualizes. Devirtualization: JIT can inline the call when it
knows (via escape analysis or monomorphic call sites) that there's only one possible runtime type.

*What separates good from great:* JIT devirtualization: in production code, virtual calls
often have only one or two concrete implementations at a given call site (megamorphic call
sites with 3+ types are rare). JIT: detects this, inlines the method body, eliminates the
vtable lookup overhead. This makes Java virtual calls nearly as fast as static calls in
hot paths. The difference: cold code (first execution), rarely-executed paths. There, virtual
calls do have overhead. Microbenchmarking virtual vs non-virtual: JMH required because JIT
state matters enormously. Don't avoid interfaces/inheritance for performance without a
profiler-confirmed bottleneck.

---

**Q2 (lsp practical): How do you identify LSP violations in code reviews?**

A: Look for: (1) override that throws an exception the base class method doesn't declare,
(2) override that ignores some parameters and does nothing (weakened behavior), (3) override
that strengthens preconditions (requires more from the caller), (4) override that weakens
postconditions (guarantees less), (5) tests that need to know the concrete type to work
correctly. The substitutability test: can you replace all usages of the base type with
the subtype and have all existing tests pass unchanged?

*What separates good from great:* The Heuristic for LSP violations in production: check if you
have `instanceof` checks in the codebase for the base type. `if (animal instanceof Dog) { ((Dog) animal).fetchBall(); }` - code that needs to know the specific type is a sign that the hierarchy is not
properly substitutable for that operation. Fix: add `fetchBall()` to the base interface (even
if as a no-op default), or use separate interfaces (one for animals that can fetch). The
`instanceof` cascade is the canonical sign of an LSP violation or a missing interface.

---

**Q3 (sealed classes): What problem do sealed classes solve?**

A: Sealed classes/interfaces (Java 17): restrict which classes can extend/implement them.
`sealed interface Shape permits Circle, Rectangle, Triangle`. Benefits: (1) exhaustive
pattern matching - compiler can verify all cases are handled (no `default` needed in `switch`),
(2) domain modeling - the type system enforces that only known types exist (important for
algebraic data types), (3) prevents unauthorized subclassing (useful for library design).

*What separates good from great:* The use case in DDD (Domain-Driven Design): modeling a
finite state machine as a sealed interface. `sealed interface OrderState permits Pending, Processing, Shipped, Delivered, Cancelled`. Each state implements `OrderState`. A `switch` on the order state: exhaustive at compile time. Adding a new state: compiler immediately flags all
unhandled `switch` expressions. Without sealed: you must handle `default` everywhere, and a
new state added in one place silently breaks all switch statements that didn't handle it.
Sealed interfaces: the compile-time alternative to the "switch on type" anti-pattern.

---

**Q4 (override rules): What are the rules for method overriding in Java?**

A: (1) Same method signature (name + parameter types). (2) Return type: same or covariant
(more specific subtype). (3) Access modifier: same or wider (can widen protected to public,
cannot narrow public to protected). (4) Checked exceptions: can throw fewer or narrower
checked exceptions, never MORE. (5) Cannot override: static methods (hide instead), private
methods (invisible to subclass), final methods (compile error).

*What separates good from great:* The exception rule is the most interview-tricky. Override
can throw fewer checked exceptions (fine) or none. Override CANNOT add new checked exceptions
the base class didn't declare. Why: code using the base type only catches the base type's
declared exceptions. If the override throws a new checked exception: callers using the base
type reference wouldn't catch it (compile error at the call site if they tried to call the
subtype's method through the base reference, but the compiler prevents this by not allowing
the override in the first place). The rule: overriding is a contract, and exceptions are part
of the contract (Eiffel's Design by Contract principle).

---

**Q5 (polymorphism design): When should you use polymorphism vs conditional logic?**

A: Polymorphism: when you have multiple types with different behaviors for the same operation,
and new types may be added later. Replaces `if (type == X) { ... } else if (type == Y) { ... }`.
Conditional logic: when the condition is a simple data distinction (status flag, boolean), not
a type distinction. When the branching is unlikely to grow. Rule: if you need to add a new
"branch" frequently (new types), polymorphism scales better (add a class, don't modify existing
switch). If the branching is fixed and few: conditional is simpler.

*What separates good from great:* The Open/Closed principle: software should be open for
extension (add new types) and closed for modification (don't change existing switch). Polymorphism
enables this: add a new class, existing code handles it via the base interface. A switch on a
type enum: adding a new type requires modifying all switches. In practice: the choice depends
on the code's evolution. A payment processor with 5 payment types growing to 20: polymorphism.
A request with status NEW/PROCESSING/DONE (never adding more states): switch on enum.

---

**Q6 (covariant returns): What is a covariant return type and when is it useful?**

A: Covariant return: an overriding method can return a more specific type than the base class.
`Animal clone()` overridden as `Dog clone()`. Callers using the Dog type get Dog directly,
without casting. Callers using the Animal type get the Animal return (backward compatible).
Most useful in: factory methods, builder patterns, clone methods. `AbstractBuilder<T> build()`
overridden as `ConcreteBuilder build()` - fluent builder chains return the concrete type.

*What separates good from great:* The self-referential generic pattern for fluent builders:
`class Builder<B extends Builder<B>>`. The `self()` method: `protected B self() { return (B) this; }`.
All mutator methods return `B` (the actual builder type): `B withName(String n) { ... return self(); }`.
When a concrete builder extends this: all methods return the concrete builder type without
casting. This is the standard pattern for fluent builders with inheritance: no `(ConcreteBuilder)` casts needed at call sites.

---

**Q7 (fragile base): What is the fragile base class problem?**

A: A base class change breaks subclasses even without the subclasses changing. Two forms:
(1) Base class adds a method that subclasses have already defined (unintentional override).
(2) Base class changes the behavior of method A, which calls method B. Subclasses override B.
Now B's new semantics don't match what A expects. The subclass is "fragile" because it depends
on undocumented base class behavior.

*What separates good from great:* The `HashSet` example in "Effective Java": `InstrumentedHashSet`
extends `HashSet`, overrides `add()` and `addAll()` to count insertions. But `HashSet.addAll()`
calls `add()` internally. So `InstrumentedHashSet.addAll()` double-counts (once for addAll,
once for each add via the overridden add). The fix from Effective Java: use composition (wrapper
pattern) instead. `InstrumentedSet` wraps a `Set`, delegates all calls, counts in the wrapper.
No dependency on internal base class behavior. This is the canonical example of why composition
is preferred over inheritance for extension.

---

**Q8 (instanceof pattern): How does pattern matching instanceof differ from traditional instanceof?**

A: Traditional: `if (shape instanceof Circle) { Circle c = (Circle) shape; ... }`. Two operations:
type check + cast. Pattern matching (Java 16+): `if (shape instanceof Circle c) { ... c.radius() ... }`.
Single operation: type check + binding in one expression. `c` is scoped to the if block.
In a `switch` expression: `case Circle c -> ...`. Sealed types: exhaustive (no default needed).

*What separates good from great:* The scope rules for pattern variables: `if (shape instanceof Circle c && c.radius() > 10)` - the `&&` short-circuits. `c` is in scope AFTER the instanceof
check (because `&&` only proceeds if the instanceof is true). `if (!(shape instanceof Circle c) || c.radius() < 5)` - `c` is NOT in scope after `!()` because the `!` flips the guarantee. Compiler
enforces this. The guarded pattern in switch (Java 21 preview): `case Circle c when c.radius() > 10 -> "large circle"`. Combines type binding with condition. Cleaner than if chains.

---

**Q9 (design choice): When do you choose inheritance over composition?**

A: Inheritance: true 'is-a' relationship where substitutability is guaranteed. Template method
pattern: base class defines algorithm structure, subclasses fill in the steps. When the subclass
IS naturally a more specific version of the base class. Composition: extending behavior of a type
you don't control (can't inherit from final class). Mixing behaviors from multiple sources.
When substitutability is uncertain. When you need to change the implementation strategy at runtime.

*What separates good from great:* The GoF design patterns are almost all composition-based:
Strategy (inject behavior), Decorator (wrap and add behavior), Observer (notify independently).
The Template Method is the primary inheritance-based pattern (it works because the base class
CONTROLS the hierarchy and defines the contract). The practical rule: in application code,
composition (injecting dependencies) is more flexible than inheritance. In framework code (where
you ARE designing the hierarchy): inheritance + template method is the correct tool. When in
doubt: ask "can I achieve this with composition?" If yes: use composition. Inheritance is harder
to change later and creates tight coupling between base and derived classes.

---

### ⚖️ Comparison Table

| Feature | Inheritance | Composition |
|---------|-------------|-------------|
| Relationship | Is-a | Has-a |
| Coupling | Tight (base + derived) | Loose (interface) |
| Flexibility | Low (fixed at compile time) | High (swap at runtime) |
| Code reuse | Direct (base methods) | Via delegation |
| Multiple bases | No (single inheritance) | Yes (multiple composed objects) |
| LSP | Must satisfy | N/A |
| Change impact | Base changes can break derived | Isolated by interface |
| Testing | Harder (full hierarchy) | Easier (mock composed parts) |
| Use when | True is-a, template method | Most code reuse scenarios |

---

### 🏛️ System Design

*(Omit: L2 Working file.)*

---

### 📊 Diagram

*(Omit: Inheritance hierarchy is demonstrated via the code examples.)*

---

---

## Interfaces vs Abstract Classes

### 🎯 Model Answer

**30 seconds:**
> Interface: pure contract, no instance state (only static/default methods, constants).
> A class can implement multiple interfaces. Abstract class: partial implementation,
> can have instance state and constructor. A class can only extend one abstract class.
> Rule: prefer interfaces for type definitions; use abstract classes only when you need
> to share state or implementation across closely related classes.

**3 minutes (Senior):**
> Decision framework:
>
> 1. **Interface when**: defining a type that multiple unrelated classes will implement.
>    When multiple inheritance of type is needed. When you want maximum flexibility.
>    Java 8+ default methods allow providing optional implementations in interfaces.
>
> 2. **Abstract class when**: sharing code between closely related classes. When protected
>    state (fields) must be shared. When you need to run initialization logic (constructors).
>    Template method pattern (protected abstract methods that subclasses must implement).
>
> 3. **Marker interfaces vs annotations**: `Serializable`, `Cloneable` - marker interfaces
>    (no methods, signal a capability). Modern Java: annotations are preferred for markers
>    (no single-use interface pollution). `@Entity`, `@NotNull` are examples.
>
> 4. **Default methods pitfalls**: default methods provide backward compatibility (add new
>    methods to existing interfaces without breaking implementations). Conflict: if two
>    interfaces have a default method with the same signature, the implementing class MUST
>    override to resolve the ambiguity.

**Blank Mind Recovery:**

**(1) Restate:** "Interface: contract, multiple implementations, default methods. Abstract class:
partial implementation, single inheritance, can have state. Choose interface for type contracts.
Use abstract class for shared state/init. Combine: interface + abstract implementation class
(e.g., `List` + `AbstractList`)."

**(2) First principles:** "Interfaces define WHAT something does. Abstract classes define
WHAT something is (partial). A List is a contract (interface). A 'collection that supports
index-based access' is an abstract implementation (AbstractList). Concrete classes implement
both: ArrayList."

**(3) Bridge:** "Interface = a job description (requirements, no implementation). Abstract class =
a starter template (some work done, some blanks to fill). You can carry multiple job descriptions
(implement many interfaces), but you can only extend one template (single inheritance)."

---

### 📘 Concept Explanation

**Interface vs abstract class capabilities:**
```
INTERFACE (Java 8+):
  interface Displayable {
      // Abstract method (no body): MUST be implemented
      void display();
      
      // Default method (has body): optional to override
      default String format() { return toString(); }
      
      // Static method: belongs to interface, not instance
      static Displayable of(String text) {
          return () -> System.out.println(text);
      }
      
      // Private method (Java 9+): internal helper for defaults
      private void validate() { ... }
      
      // Constants: implicitly public static final
      int MAX_LENGTH = 100;
  }
  
  // Can implement multiple:
  class Report implements Displayable, Printable, Exportable { ... }

ABSTRACT CLASS:
  abstract class BaseProcessor {
      // Instance state: allowed
      protected final Logger log = Logger.getLogger(getClass());
      private int processedCount = 0;  // shared state
      
      // Constructor: allowed
      protected BaseProcessor(Config config) {
          this.config = config;
      }
      
      // Template method (final: subclasses cannot change algorithm):
      final void process(List<Item> items) {
          validate(items);
          items.forEach(this::processOne);  // calls abstract method
          log.info("Processed: {}", processedCount);
      }
      
      // Abstract: subclass must implement
      protected abstract void processOne(Item item);
      
      // Concrete helper: shared across all subclasses
      protected void validate(List<Item> items) {
          if (items == null || items.isEmpty()) {
              throw new IllegalArgumentException("items must not be empty");
          }
      }
  }

COMBINATION PATTERN (JDK standard):
  // Interface: defines the contract (all capabilities)
  interface List<E> extends Collection<E> {
      E get(int index);
      int size();
      // 24 more abstract methods...
      // + many default methods (Java 8+)
  }
  
  // Abstract class: skeletal implementation (optional convenience)
  abstract class AbstractList<E> implements List<E> {
      // Implements most methods in terms of get() and size()
      // Subclasses only need to implement get(), size()
      // Optional: override for better performance
  }
  
  // Concrete class: real implementation
  class ArrayList<E> extends AbstractList<E> {
      @Override
      public E get(int index) { return elementData[index]; }
      @Override
      public int size() { return size; }
      // Override others for better performance
  }
  // Result: ArrayList is a List, is an AbstractList, is a Collection
```

---

### 💻 Code Example

> **Code walkthrough:** The combination pattern (interface + abstract skeletal implementation)
> is used throughout the JDK. The abstract class reduces boilerplate for concrete implementations
> by providing default implementations of the non-core methods in terms of the core primitives.
> This gives concrete classes the choice: extend the abstract class for less work, or implement
> the interface directly for full control.

```java
// INTERFACE WITH DEFAULT METHODS (backward compatibility):
interface EventListener {
    void onEvent(Event event);
    
    // Default added in Java 8 without breaking existing implementations:
    default void onError(Exception e) {
        System.err.println("Error: " + e.getMessage());
    }
}

// Old implementation: still works (no need to implement onError):
class MyListener implements EventListener {
    @Override
    public void onEvent(Event event) { ... }
}

// DEFAULT METHOD CONFLICT:
interface A { default String greet() { return "Hello from A"; } }
interface B { default String greet() { return "Hello from B"; } }

// BAD: ambiguous - compiler error
class C implements A, B {
    // Error: C inherits default greet() from both A and B
}

// GOOD: resolve by overriding
class C implements A, B {
    @Override
    public String greet() {
        return A.super.greet() + " and " + B.super.greet();
    }
}

// WHEN TO USE ABSTRACT CLASS:
// Need constructor + shared mutable state + template method
abstract class JdbcRepository<T, ID> {
    protected final DataSource dataSource;  // shared state
    
    protected JdbcRepository(DataSource ds) {
        this.dataSource = ds;  // initialized once, shared by all subclasses
    }
    
    // Template method: transaction + query
    final List<T> findAll(String query, Object... params) {
        try (Connection conn = dataSource.getConnection()) {
            PreparedStatement stmt = conn.prepareStatement(query);
            // ... set params ...
            return mapResultSet(stmt.executeQuery());  // abstract
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
    
    // Abstract: subclass provides the mapping
    protected abstract List<T> mapResultSet(ResultSet rs) throws SQLException;
    protected abstract String getFindAllQuery();
}

class UserRepository extends JdbcRepository<User, Long> {
    UserRepository(DataSource ds) { super(ds); }
    
    @Override
    protected List<User> mapResultSet(ResultSet rs) throws SQLException {
        List<User> users = new ArrayList<>();
        while (rs.next()) {
            users.add(new User(rs.getLong("id"), rs.getString("name")));
        }
        return users;
    }
    
    @Override
    protected String getFindAllQuery() { return "SELECT id, name FROM users"; }
}
```

> **Code walkthrough:** The `JdbcRepository` abstract class correctly uses the abstract class
> for a shared resource (`DataSource`), initialization logic (constructor), and a template method
> for the query execution pattern. The abstract `mapResultSet()` forces subclasses to provide the
> type-specific mapping. If this were an interface: there would be no place to store `dataSource`
> (interfaces have no instance state), requiring every subclass to reinitialize the connection
> pattern. The combination of shared state + template method = abstract class.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Interface: contract, multiple implementations, no state. Abstract class: partial implementation,
> single inheritance, can have state. Modern rule: prefer interfaces. Use abstract class when you
> need shared state or a constructor.

---

**Senior / Staff (5+ years):**
> The JDK's interface + AbstractXxx pattern: interfaces for the contract, abstract skeletal
> implementations for convenience. Default methods: backward compatibility for library evolution.
> Avoid abstract classes with too much state - they become a god class over time. For extensible
> frameworks: interfaces first, skeletal abstract class as optional convenience (users who need
> less boilerplate extend it; users who need full control implement the interface directly).

---

### ⚠️ Common Misconceptions

**Misconception 1: "Interfaces are for behavior only, abstract classes are for state."**
Post-Java 8: interfaces can have static fields, static methods, default methods (behavior with
body), and private methods (Java 9). The line has blurred. The remaining difference: interfaces
cannot have instance state (no instance fields), no constructors (no initialization logic), and
cannot contain `synchronized` instance blocks. For anything requiring per-instance state initialization: abstract class.

**Misconception 2: "Default methods in interfaces make abstract classes obsolete."**
No. Default methods solve backward compatibility (adding new methods without breaking existing
implementations). They do NOT provide instance state, constructors, or synchronized methods.
Abstract classes remain correct when: shared state is needed, constructor logic is needed,
or the template method pattern is the design choice.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Diamond problem from default methods causes unexpected behavior.**
```
Symptom: Method call on an object returns unexpected result.
  The method is "from interface A" but the value is wrong.

Root cause:
  interface A {
      default int priority() { return 1; }
  }
  interface B extends A {
      @Override
      default int priority() { return 10; }  // overrides A's default
  }
  interface C extends A {
      @Override
      default int priority() { return 20; }
  }
  class D implements B, C {
      // D must resolve: B.priority=10 or C.priority=20?
      // COMPILE ERROR: conflicting defaults
  }
  
  Resolution: D must override priority() explicitly
  class D implements B, C {
      @Override
      public int priority() {
          return B.super.priority();  // explicitly choose B's version
          // or: return C.super.priority();
          // or: return custom logic
      }
  }
  
  But what if D forgets to override?
    -> COMPILE ERROR: "inherits unrelated defaults" - Java forces explicit resolution

Diagnosis:
  Compile error: "D inherits unrelated defaults for priority() from types B and C"
  Resolution: always explicit when two interfaces conflict on a default method

Prevention: when designing interfaces with default methods:
  Be conservative - add default methods only for backward compatibility.
  Minimize the chance of conflict: use descriptive names, avoid overriding
  default methods from super-interfaces unless intentional.
  The most common source of diamond problems: multiple inheritance of frameworks'
  listener/callback interfaces that each add lifecycle default methods.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Interface vs abstract class | 2 minutes |
| Default method purpose | 1 minute |
| Diamond problem with defaults | 2 minutes |
| Functional interface | 1 minute |
| Skeletal implementation pattern | 2 minutes |
| Marker interfaces vs annotations | 1 minute |
| Interface evolution | 2 minutes |
| Abstract class constructor | 1 minute |
| When to choose which | 2 minutes |

---

**Q1 (decision): When do you choose an interface over an abstract class?**

A: Interface when: (1) multiple inheritance of type is needed (class implements multiple
interfaces), (2) the type should be implementable by unrelated classes, (3) no shared
state is needed, (4) you want maximum flexibility for implementors. Abstract class when:
(1) shared state (instance fields) must be carried, (2) constructor logic is needed,
(3) template method pattern with protected methods, (4) all subclasses are closely related.

*What separates good from great:* The Effective Java principle: "Interfaces are generally
superior to abstract classes for defining types that permit multiple implementations." The
reason: interfaces don't impose a hierarchy. A `Flyable` interface can be implemented by Bird,
Plane, Superman. These have nothing else in common. A `FlyingThing` abstract class would
force an artificial hierarchy. The exception: `AbstractList` in the JDK - it's an abstract
class for skeletal implementation, not the type contract (that's the `List` interface). The
pattern: interface for the contract, abstract class for convenience (optional). Never skip the
interface and go straight to abstract class unless the abstract class IS the contract
(Template Method pattern family only).

---

**Q2 (default methods): What was the original motivation for default methods in Java 8?**

A: Backward compatibility for the Collections Framework. Adding `forEach`, `removeIf`,
`stream()`, `sort()` to the `Collection`/`List`/`Iterator` interfaces in Java 8. Without default
methods: all existing implementations of these interfaces would break at compile time (they don't
have the new methods). With default methods: the methods are provided in the interface itself.
Existing implementations don't need to change.

*What separates good from great:* The alternative the JDK team considered before default methods:
adding new methods to Collection via a separate utility class (like `Collections.sort(list)` vs
`list.sort(comparator)`). This was the pre-Java 8 pattern. The problem: it's less discoverable
(two places for behavior: the class + the utility), less composable (can't chain utility calls
the same way), less idiomatic. Default methods: the better solution, at the cost of adding
language complexity (potential diamond problem). The trade-off: the JDK team decided the
discoverability and composability of `stream()` directly on `Collection` was worth the language
complexity. Every Java 8 developer benefits from this decision every day.

---

**Q3 (interface evolution): How do you add new methods to an existing interface without breaking clients?**

A: Option A: default methods (Java 8+). Add the method with a default implementation. Existing
implementations are not broken. New implementations can optionally override. Option B: extend
the interface (new interface that extends the old one). Old code uses the old interface, new code
uses the new one. Option C: versioning (major version: NewInterface, deprecated OldInterface).
Option D: visitor pattern (add accept(Visitor) to the interface; add new operations via new
visitors).

*What separates good from great:* The abstract class advantage here: adding a new non-abstract
method to an abstract class doesn't break subclasses (they inherit the implementation). This
was the pre-Java 8 reason to prefer abstract classes for extensible APIs. Java 8 default methods
leveled this: interfaces can now evolve too. But default methods have a constraint: the
implementation can only call other interface methods (no instance state). If the new method
needs instance state: it can't be a default method, and you're forced to break the interface
or use another approach (extend the interface with the new method and provide a skeletal
implementation in an AbstractBase class).

---

**Q4 (abstract class constructor): What is the purpose of a protected constructor in an abstract class?**

A: Protected constructor: prevents direct instantiation of the abstract class (can't `new BaseClass()` outside the package or class hierarchy), while allowing subclass constructors to call `super()`. If public: no functional difference since abstract classes can't be instantiated directly anyway. If package-private: limits subclassing to the same package. Protected: subclasses anywhere can call it. Design: abstract classes typically have protected (or package-private) constructors to make the design intent clear: "this is not meant for direct use."

*What separates good from great:* The "constructor stealing" concern: if an abstract class has a
public constructor, anyone can subclass it in any package. If the intent is to seal the hierarchy
to a specific package (or a permitted set of classes): use package-private constructors (or Java 17 sealed classes). The `java.lang.Number` abstract class: protected constructor. All of `Integer`,
`Long`, `Double` live in the same package (`java.lang`) and extend it. The protected constructor
signals: "only intended for closely related implementations in known packages." Modern Java: sealed abstract classes (Java 17) combine the abstract class and the sealed hierarchy control.

---

**Q5 (functional interface): Can an abstract class be used as a lambda target?**

A: No. Lambda expressions target functional interfaces only (SAM interfaces). An abstract class
with one abstract method cannot be used as a lambda target. The reason: a lambda creates an
instance of a functional interface, not a class. A class instantiation via lambda would require
invoking the constructor (possibly with state initialization), which is not the lambda model.
Anonymous classes (not lambdas) can instantiate abstract classes.

*What separates good from great:* The practical consequence: if you want your callback API to
support lambdas, use a `@FunctionalInterface` interface, not an abstract class. Pre-Java 8 code
using abstract classes for callbacks (like Swing's `AbstractAction`): lambda-unfriendly. Modern
Java: callback APIs use functional interfaces exclusively. If you have legacy abstract class
callbacks: provide a factory method that takes a lambda and wraps it: `static AbstractAction of(Runnable action) { return new AbstractAction() { public void actionPerformed(ActionEvent e) { action.run(); } }; }`. This bridges the lambda world to the legacy abstract class world.

---

**Q6 (interface static methods): What are static methods in interfaces and when are they useful?**

A: Interface static methods (Java 8+): utility methods related to the interface's type.
`Collection.unmodifiableList(list)` was in `Collections` utility class before Java 8. With
static interface methods: `List.of(...)`, `Set.of(...)`, `Map.of(...)` can live directly in
the interface. More discoverable. Cannot be inherited by implementing classes (not override-able).
Must be called via the interface: `List.of()` (not via an instance).

*What separates good from great:* The naming convention: `List.of()`, `List.copyOf()` (Java 9+
static factory methods on interfaces) vs the old `Collections.unmodifiableList()`. The interface
static method is more discoverable: when you type `List.`, you see the factory methods right there.
The `Collections` utility class: a workaround for pre-Java 8 when interfaces couldn't have static
methods. It's still used for methods that aren't conceptually "creating a List" (like
`Collections.sort()`, `Collections.shuffle()`). The clean design: if a static method is conceptually
part of the interface's type (factory, validation), put it on the interface. If it's a general
utility that combines multiple types: keep it in a utility class.

---

**Q7 (multiple inheritance): How does Java avoid the diamond problem?**

A: Java does not allow multiple inheritance of class state (only single class inheritance).
Multiple interface implementation: allowed, but only introduces method signatures (and default
methods, which have concrete bodies). Diamond problem with default methods: Java requires
explicit resolution. Rule: class > interface (a class's implementation always takes priority
over a default method). More specific interface > less specific (if B extends A and both provide
a default, B's wins if D implements B but not C). If two unrelated interfaces conflict on a
default: compile error (must override explicitly).

*What separates good from great:* The three rules of interface resolution (in priority order):
(1) Class or superclass method always wins over any interface default. (2) Among interfaces:
the most specific interface wins (the one that overrides the other in the hierarchy). (3)
If still ambiguous: explicit override required. These three rules eliminate most accidental
diamonds. The only case requiring explicit resolution: two interfaces at the SAME level in the
hierarchy providing conflicting defaults. This is the intended design: the compiler forces the
programmer to make a conscious decision rather than silently choosing one over the other.

---

**Q8 (abstract vs interface state): What kind of state can an interface hold?**

A: Interface fields: implicitly `public static final` (constants). There are NO instance fields
in interfaces. Any field declared in an interface is a named constant, shared by all instances
of all implementing classes. Default methods can only work with the state that's accessible via
the interface's own methods (no direct field access to instance state). If a default method needs
state: it must access it via an abstract method that returns the state.

*What separates good from great:* The pattern for "interface with state via abstract getter":
```java
interface Identifiable {
    String getId();  // abstract: implementor provides the id
    
    default boolean sameAs(Identifiable other) {
        return this.getId().equals(other.getId());  // uses abstract getter
    }
}
```
The default `sameAs()` method works correctly for all implementations because it accesses
state via the `getId()` abstract method (which the implementing class provides). This is the
correct pattern for default methods that need "instance state": access it through abstract
methods, not through direct fields.

---

**Q9 (sealed + abstract): How do sealed classes interact with abstract classes?**

A: Sealed abstract class: an abstract class that limits which classes can extend it. `sealed abstract class Shape permits Circle, Rectangle`. Subclasses must be: `final`, `sealed`, or `non-sealed`. `final`: no further extension. `sealed`: extends the sealed hierarchy. `non-sealed`: reopens the hierarchy (allows any extension of that subclass). Sealed abstract class + pattern matching: exhaustive switch without default.

*What separates good from great:* The `non-sealed` keyword: the escape hatch. If you have `sealed abstract class Shape permits Circle, Polygon, CustomShape`, and `CustomShape` is `non-sealed`: users can create `class MyWeirdShape extends CustomShape` without the library knowing. The `switch` on Shape: still needs a `default` case (because CustomShape subclasses are unknown). Use `non-sealed` only when you intentionally want to allow extension of a specific subtype while keeping the rest of the hierarchy sealed. The pattern: `sealed` for the core domain types (Circle, Rectangle), `non-sealed` for the "escape hatch" subtype that third parties can extend.

---

### ⚖️ Comparison Table

| Feature | Interface | Abstract Class |
|---------|-----------|----------------|
| Multiple inheritance | Yes (implement many) | No (extend one) |
| Instance fields | No (only static final) | Yes |
| Constructor | No | Yes |
| Default methods | Yes (Java 8+) | Yes (concrete methods) |
| Static methods | Yes (Java 8+) | Yes |
| Private methods | Yes (Java 9+) | Yes |
| Access modifiers for methods | public or private | Any |
| Lambda target | Yes (if SAM) | No |
| Design purpose | Type contract | Shared implementation |
| When to use | Multiple types, no state | Shared state, template method |

---

### 🏛️ System Design

*(Omit: L2 Working file.)*

---

### 📊 Diagram

*(Omit: The interface/abstract class comparison is best expressed through the code
examples and comparison table above.)*
