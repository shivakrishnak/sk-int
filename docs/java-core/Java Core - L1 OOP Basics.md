---
layout: default
title: "Java Core - L1 OOP Basics"
parent: "Java Core"
grand_parent: "SK Interview"
nav_order: 3
permalink: /java-core/l1-oop-basics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Core - L1 OOP Basics](#java-core---l1-oop-basics) | medium |

---

# Java Core - L1 OOP Basics

## Inheritance and Polymorphism

---

### 🎯 Model Answer

**30 seconds:**
> Inheritance lets a subclass extend a parent class, inheriting its
> fields and methods. Polymorphism lets the same method call behave
> differently based on the actual runtime type. Java supports single
> class inheritance (`extends`) but multiple interface implementation
> (`implements`). Method overriding (same signature, different class)
> enables runtime polymorphism. Method overloading (same name, different
> parameters) is compile-time polymorphism. The `final` keyword prevents
> inheritance (class) or overriding (method).

**3 minutes (Senior):**
> Polymorphism via virtual dispatch: the JVM uses a virtual method table
> (vtable) to resolve method calls at runtime. When you call `animal.speak()`,
> the JVM looks up the actual type of `animal` in the vtable and calls
> the appropriate implementation. This enables programming to interfaces
> (dependency inversion).
>
> Liskov Substitution Principle (LSP): subclasses must be substitutable
> for their parent class without breaking correctness. Violating LSP
> (a Square extending Rectangle breaks width/height invariant) is a
> classic design error. Prefer composition over inheritance to avoid
> tight coupling.
>
> The `Object` class is the root of all Java classes. It provides:
> `equals()`, `hashCode()`, `toString()`, `clone()`, `getClass()`,
> `finalize()` (deprecated), `wait()`, `notify()`, `notifyAll()`.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Inheritance and polymorphism - let me cover how Java
implements inheritance, virtual dispatch, the LSP, and when to prefer
composition over inheritance."

**(2) First principles:** "From first principles: inheritance reuses code
by letting a class build on another. Polymorphism makes programs extensible -
you can add new types without changing existing code that uses the base type."

**(3) Bridge:** "Inheritance is like building with LEGO: new pieces extend
base pieces. Polymorphism is like a remote control with a universal
'play' button - the same button works differently on a TV, DVD player,
or streaming box, depending on what device is actually connected."

---

### 📘 Concept Explanation

**Inheritance:**
```java
class Animal {
    String name;
    void speak() { System.out.println(name + " makes a sound"); }
}

class Dog extends Animal {    // single inheritance
    String breed;
    @Override                 // annotation: documents intent
    void speak() {            // override: replaces parent method
        System.out.println(name + " barks");
    }
}
```

> **Code walkthrough:** This L1 OOP Basics example demonstrates metadata declaration. **KEY MECHANISM:** annotations are processed at compile-time or runtime via reflection. **WHY IT MATTERS:** annotation processing adds compile time; runtime reflection disables JIT optimizations. **TAKEAWAY: prefer compile-time annotation processors (APT) over runtime reflection for performance.**

**Polymorphism (virtual dispatch):**
```java
Animal a = new Dog();  // parent type, child instance
a.speak();             // calls Dog.speak() - NOT Animal.speak()
// The JVM resolves the call to the actual runtime type (Dog)
```

> **Code walkthrough:** This L1 OOP Basics example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**Overriding rules:**
- Same method name, same parameter types, same (or covariant) return type
- Cannot be less accessible (Dog.speak() cannot be private if Animal.speak() is public)
- Cannot throw new checked exceptions not in parent's throws clause
- `@Override` annotation: compiler verifies you're actually overriding

**Method overloading (compile-time):**
```java
class Printer {
    void print(int i) { ... }
    void print(String s) { ... } // different parameter type
    void print(int i, int j) { ... } // different parameter count
    // NOT overloading: same erasure (generics)
}
```

> **Code walkthrough:** This L1 OOP Basics example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

---

### 💻 Code Example

> **Code walkthrough:** The animal hierarchy shows runtime polymorphismice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> via virtual dispatch. `list.get(i).speak()` calls the correct
> implementation based on the actual object type at runtime, not the
> declared type. The LSP violation example shows why Square extending
> Rectangle is incorrect - the Rectangle contract ("setting width
> doesn't change height") is violated by Square's implementation,
> breaking code that assumes the Rectangle contract.


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// Runtime polymorphism - same method, different behaviors:
List<Animal> animals = new ArrayList<>();
animals.add(new Dog());
animals.add(new Cat());
animals.add(new Bird());

for (Animal a : animals) {
    a.speak(); // Dog barks, Cat meows, Bird chirps
    // JVM looks up actual type's vtable entry for speak()
}

// LSP violation example (bad design):
class Rectangle {
    protected int width, height;
    void setWidth(int w) { this.width = w; }
    void setHeight(int h) { this.height = h; }
    int area() { return width * height; }
}

class Square extends Rectangle { // VIOLATES LSP!
    @Override void setWidth(int w) { width = height = w; }
    @Override void setHeight(int h) { width = height = h; }
}
// Client code that works with Rectangle:
void doubleWidth(Rectangle r) {
    int old = r.area();
    r.setWidth(r.width * 2);
    assert r.area() == old * 2; // fails for Square!
}

// GOOD: composition over inheritance
class Square {
    private final int side;
    Square(int side) { this.side = side; }
    int area() { return side * side; }
    // NOT a Rectangle - doesn't need to be
}
```

> **Code walkthrough:** The LSP violation is subtle: `Square` is aice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> valid mathematical subtype of rectangle (every square is a rectangle),
> but it's NOT a valid code subtype because it changes the behavioral
> contract. The `doubleWidth` method's assertion fails for Square -
> the code that worked correctly with Rectangle now breaks when given
> a Square. The fix: don't extend Rectangle; either make them
> independent classes or use an interface `Shape` with an `area()` method.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Inheritance lets subclasses reuse parent class code via `extends`.
> Polymorphism means the same method call behaves differently based on
> the actual runtime type. `@Override` verifies overriding is correct.
> Java supports single class inheritance but multiple interface implementation.
> `super` calls the parent's method. `final class` can't be extended;
> `final method` can't be overridden.

---

**Senior / Staff (5+ years):**
> Prefer composition over inheritance. Inheritance creates tight coupling
> - changes to the parent affect all subclasses. Composition (has-a) is
> more flexible than inheritance (is-a). The Liskov Substitution Principle
> defines when inheritance is valid: subclasses must honor the parent's
> behavioral contract. Virtual dispatch via vtable enables polymorphism
> at minimal runtime cost (one extra pointer dereference). JIT inlining
> can even eliminate this overhead for monomorphic call sites (one actual
> type). Design hierarchy shallowly: deep inheritance chains are hard to
> understand and test.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Java supports multiple inheritance."**
Java supports multiple INTERFACE inheritance but only single CLASS
inheritance. This avoids the diamond problem (ambiguous inherited
method). Default methods in interfaces (Java 8+) can cause a limited
form of diamond conflict, resolved by explicit override.

**Misconception 2: "Overloading is runtime polymorphism."**
Overloading is COMPILE-TIME polymorphism - the compiler chooses the
method at compile time based on declared types of arguments.
Overriding is RUNTIME polymorphism - the JVM chooses the method at
runtime based on actual object type.

---

### 🚨 Failure Modes and Diagnosis

**Failure: calling overridden method from constructor.**
```java
class Parent {
    Parent() { init(); }             // calls virtual method!
    void init() { System.out.println("Parent.init"); }
}
class Child extends Parent {
    int value = 42;
    @Override void init() {
        System.out.println("Child.init: " + value);
        // Prints "Child.init: 0" - field not initialized yet!
    }
}
new Child(); // value is 0 during init(), not 42
```
> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Diagnosis: avoid calling overridable methods in constructors.
The object's state is incomplete during construction.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Inheritance vs composition | 2 minutes |
| Virtual dispatch mechanism | 2 minutes |
| LSP explanation | 2 minutes |
| Overriding vs overloading | 90 seconds |
| covariant return type | 90 seconds |
| Constructor and inheritance | 2 minutes |
| final and abstract | 60 seconds |

---

**Q1 (Inheritance vs composition): When would you prefer composition
over inheritance?**

A: The rule: "prefer composition over inheritance" (Effective Java, Item 18).

**Use composition when:**
- The relationship is "has-a", not "is-a"
- You want to reuse behavior without inheriting the full interface
- The parent class may change (fragile base class problem)
- You need to use multiple implementations of the same behavior

**Use inheritance when:**
- The subclass genuinely IS the parent type (behavioral contract holds)
- You're extending abstract classes in frameworks (Template Method pattern)
- Override-and-extend is semantically correct

```java
// COMPOSITION: LoggingList wraps List, doesn't extend it:
class LoggingList<T> {
    private final List<T> delegate;
    LoggingList(List<T> list) { this.delegate = list; }
    boolean add(T item) {
        log("Adding: " + item);
        return delegate.add(item);
    }
    // forward other methods...
}
// If ArrayList adds a new method, LoggingList won't accidentally
// inherit it without logging.
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* The "fragile base class" problem is
the core reason to prefer composition. If you extend a class and the
parent adds a new method that you haven't overridden, callers get the
parent's implementation - possibly breaking your invariants. Example:
if you extend `HashSet` to count insertions and the parent adds a new
bulk-add method that internally calls `add()`, your count stays correct.
But if it calls a different internal method, your count breaks.
Composition: you control ALL method delegations.

---

**Q2 (Virtual dispatch): How does the JVM implement virtual method
dispatch?**

A: The JVM implements virtual dispatch via virtual method tables (vtables).

For each class, the JVM creates a vtable: a table of method pointers,
one per virtual method. Subclasses inherit the parent's vtable and
override entries for their overridden methods.

```plaintext
Animal vtable:
  [0] speak -> Animal.speak
  [1] toString -> Object.toString
  ...

Dog vtable (extends Animal):
  [0] speak -> Dog.speak  // OVERRIDDEN
  [1] toString -> Object.toString
  ...

Call a.speak() where a is declared Animal:
  1. Load actual object reference (points to Dog vtable)
  2. Look up vtable[0] = Dog.speak
  3. Call Dog.speak
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

JIT optimization: JVM profiles call sites. If a call site always sees
the same type (monomorphic), JIT inlines the method directly - no vtable
lookup overhead.

*What separates good from great:* JIT inline caching makes polymorphism
nearly free in hot code paths. But megamorphic call sites (3+ different
types seen at one call site) cannot be inlined and have higher overhead.
In performance-critical loops, monomorphic dispatch (always the same
concrete type) is fastest. Micro-benchmarks that compare interface
calls to direct calls often see no difference because JIT inlining
eliminates the dispatch overhead.

---

**Q3 (LSP): Explain the Liskov Substitution Principle with a Java example.**

A: LSP: if `S` is a subtype of `T`, then objects of type `T` may be
replaced by objects of type `S` without altering the correctness of
the program.

Behavioral definition: a subclass must honor all behavioral contracts
of the parent class: preconditions cannot be strengthened, postconditions
cannot be weakened, invariants must be preserved.

```java
// LSP violation: ReadOnlyList extends ArrayList
// Parent contract: add() adds an element and returns true
// Child behavior: add() throws UnsupportedOperationException
class ReadOnlyList<T> extends ArrayList<T> {
    @Override
    public boolean add(T e) {
        throw new UnsupportedOperationException(); // breaks parent contract
    }
}

// Code that uses ArrayList:
void addItem(ArrayList<String> list, String item) {
    list.add(item); // throws for ReadOnlyList!
}
// ReadOnlyList cannot substitute for ArrayList without breaking code

// FIX: ReadOnlyList should implement List, not extend ArrayList
// Better: use Collections.unmodifiableList() - designed for this
List<String> readOnly = Collections.unmodifiableList(mutableList);
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Java's `Collections.unmodifiableList()`
technically violates LSP for the same reason (throws on mutation), but
it's a documented design choice. The real lesson: throwing
`UnsupportedOperationException` from an interface method indicates a
poorly designed inheritance hierarchy. Modern Java uses `interface +
default methods` with explicit optional capabilities (e.g., `Spliterator`
with optional characteristics) instead of subclassing with unsupported
operations.

---

**Q4 (Overriding vs overloading): Contrast method overriding and
method overloading.**

A:

| Aspect | Overriding | Overloading |
|---|---|---|
| When resolved | Runtime (dynamic) | Compile time (static) |
| Relationship | Subclass changes parent's method | Same class, different params |
| Return type | Same or covariant | Can differ (if signature differs) |
| Exceptions | Can throw less (not more checked) | No restriction |
| `@Override` | Yes (validates) | Not applicable |
| Polymorphism type | Runtime polymorphism | Compile-time polymorphism |

```java
// Overriding: resolved at RUNTIME
Animal a = new Dog();
a.speak(); // Dog.speak() called - runtime type matters

// Overloading: resolved at COMPILE TIME
class Printer {
    void print(int n) { System.out.println("int: " + n); }
    void print(double d) { System.out.println("double: " + d); }
}
Printer p = new Printer();
p.print(5);    // print(int) - compiler sees int literal
p.print(5.0);  // print(double) - compiler sees double literal
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* A tricky overloading case: varargs
methods. `print(String... args)` is called when no specific overload
matches. Autoboxing and varargs interact in surprising ways:
`print(1, 2, 3)` matches `print(int...)` before `print(Integer...)`.
And overloading with inheritance: if you overload a method in a subclass,
the parent's overloads are ALSO visible. The compiler picks the most
specific applicable overload - can be surprising when the declared
type and actual type differ.

---

**Q5 (Covariant return): What is covariant return type overriding?**

A: In Java 5+, an overriding method can return a subtype of the parent
method's return type. This is covariant return type.

```java
class Animal {
    Animal getInstance() { return new Animal(); }
}

class Dog extends Animal {
    @Override
    Dog getInstance() { // covariant: Dog is a subtype of Animal
        return new Dog();
    }
}

// Usage:
Dog d = new Dog();
Dog result = d.getInstance(); // no cast needed (return type is Dog)

// Without covariant return (old style):
Animal result = d.getInstance(); // had to accept Animal, then cast
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Used extensively in builder patterns and fluent APIs:
```java
abstract class Builder<T extends Builder<T>> {
    abstract T self(); // returns concrete subtype
    T withName(String n) { this.name = n; return self(); }
}
class PersonBuilder extends Builder<PersonBuilder> {
    @Override PersonBuilder self() { return this; }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Covariant return enables cleaner
API design without casting. The `Comparable<T>` pattern and builder
hierarchies commonly use it. The JVM supports covariant return by
creating a bridge method (synthetic) in the bytecode that calls the
actual overriding method - transparent to the developer. In code
reviews: look for unnecessary casts after method calls - often a
sign that covariant return could simplify the code.

---

**Q6 (Constructor and inheritance): How does constructor chaining work
in Java inheritance?**

A: Constructor chaining rules:
1. Every constructor must call either `this(...)` (sibling constructor)
   or `super(...)` (parent constructor) as the FIRST statement.
2. If neither is specified, the compiler inserts `super()` - calling
   the no-arg parent constructor.
3. If the parent has no no-arg constructor, the compiler reports an error.

```java
class Vehicle {
    String type;
    int wheels;
    Vehicle(String type, int wheels) {
        this.type = type;
        this.wheels = wheels;
    }
    // No no-arg constructor!
}

class Car extends Vehicle {
    String model;
    Car(String model) {
        super("car", 4); // MUST call parent constructor explicitly
        this.model = model;
    }
    Car(String model, int extraWheels) {
        this(model); // chains to Car(String model)
    }
}

// Object lifecycle during new Car("Tesla"):
// 1. Object memory allocated
// 2. Car(String) calls super("car", 4)
// 3. Vehicle("car", 4) constructor runs
//    - Vehicle.type = "car", Vehicle.wheels = 4
// 4. Car constructor resumes
//    - Car.model = "Tesla"
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* The "call overridable method from
constructor" anti-pattern: if `Vehicle()` calls `this.validate()` and
Dog overrides `validate()`, Dog's validate runs before Dog's fields are
initialized. This causes NPE or incorrect values. Rule: constructors should
only call `private`, `final`, or `static` methods (which cannot be
overridden and therefore behave predictably during construction).

---

**Q7 (final and abstract): Contrast final, abstract, and sealed class
modifiers.**

A:

| Modifier | Class | Method | Field |
|---|---|---|---|
| `final` | Cannot be extended | Cannot be overridden | Cannot be reassigned |
| `abstract` | Cannot be instantiated | No implementation; must override | N/A |
| `sealed` (Java 17) | Limited set of permitted subclasses | N/A | N/A |

```java
// final class: String, Integer, System
final class ImmutablePoint {
    final int x, y; // final fields too - fully immutable
    ImmutablePoint(int x, int y) { this.x = x; this.y = y; }
}

// abstract class: template method pattern
abstract class ReportGenerator {
    // Template method:
    final void generate() { // final: can't override the skeleton
        fetchData();
        String content = formatContent(); // abstract step
        writeOutput(content);
    }
    abstract String formatContent(); // subclasses must implement
    private void fetchData() { ... }
    private void writeOutput(String c) { ... }
}

// sealed class: restricted hierarchy (Java 17)
sealed interface Shape permits Circle, Rectangle, Triangle {}
final class Circle implements Shape { double radius; }
final class Rectangle implements Shape { double w, h; }
final class Triangle implements Shape { double base, height; }
// No other class can implement Shape!
```

> **Code walkthrough:** This Unknown example demonstrates contract definition usice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Sealed classes enable exhaustive
pattern matching. The compiler verifies that a `switch` on a sealed
type covers all permitted subtypes - no `default` branch needed, and
adding a new subtype forces you to update all switches (compile error).
This is the Java equivalent of ML/Haskell algebraic data types. Use
sealed + records for domain modeling where the set of possible states
is closed and known at design time.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*

---

---

## Abstract Classes and Interfaces

---

### 🎯 Model Answer

**30 seconds:**
> Interfaces define a contract (what a class can do) without
> implementation. Abstract classes provide partial implementation
> and force subclasses to complete the rest. Key rule: a class
> can implement many interfaces but extend only one abstract class.
> Java 8 added default methods to interfaces (code in an interface),
> and Java 9 added private methods. Use interface when you want to
> define a capability (Comparable, Serializable, Runnable).
> Use abstract class when you want to share code while enforcing a
> contract (Template Method pattern).

**3 minutes (Senior):**
> Interface vs abstract class decision:
> - Interface: no state (except constants), pure contract, multiple
>   implementation, type token
> - Abstract class: state (fields), constructors, shared implementation,
>   template method pattern, one extends only
>
> Java 8 default methods reduced the gap: interfaces can now have code.
> But interfaces still cannot have instance fields or constructors.
> The diamond problem with default methods: if two interfaces both
> define `default void log()`, the implementing class must override
> to resolve ambiguity.
>
> Functional interfaces (exactly one abstract method): work with
> lambdas. Examples: `Runnable`, `Callable`, `Comparator`, `Function`.
> `@FunctionalInterface` annotation validates single abstract method.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Abstract classes vs interfaces - let me cover the
differences, when to use each, Java 8 default methods, and functional
interfaces."

**(2) First principles:** "From first principles: interfaces define
what something CAN DO (capability contract). Abstract classes define
what something IS (shared implementation). A class can be capable of
many things but is fundamentally one kind of thing."

**(3) Bridge:** "An interface is like a job description: it defines
the required skills. An abstract class is like an apprenticeship
program: it provides training and tools, plus requires you to
complete certain parts yourself."

---

### 📘 Concept Explanation

**When to use each:**

| Feature| Interface| Abstract Class|
|----------------------|-------------------------|-------------------|
| Multiple inheritance| Yes (multiple implements)| No (single extends)|
| Instance fields| No| Yes|
| Constructor| No| Yes|
| Default implementation| Yes (default methods)| Yes|
| Static methods| Yes (Java 8+)| Yes|
| Private methods| Yes (Java 9+)| Yes|
| Access modifiers| Public/private only| Any|
| State| No (constants only)| Yes|

**Functional interfaces:**
```java
@FunctionalInterface
interface Transformer<T, R> {
    R transform(T input); // single abstract method
    // May have default methods
    default Transformer<T, R> andLog() {
        return input -> {
            R result = transform(input);
            System.out.println(input + " -> " + result);
            return result;
        };
    }
}

// Lambda as functional interface:
Transformer<String, Integer> len = s -> s.length();
```

> **Code walkthrough:** This Unknown example demonstrates contract definition using interface. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **TAKEAWAY: interfaces define contracts; prefer them over abstract classes for unrelated types.**

---

### 💻 Code Example

> **Code walkthrough:** The Template Method pattern uses an abstract classice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> to define the algorithm skeleton in a final method, with abstract steps
> that subclasses must implement. The `final` on the template method prevents
> subclasses from changing the algorithm structure while still allowing
> customization of individual steps. The interface example shows a mixin
> pattern: multiple interfaces added to a class for capability.

```java
// Template Method Pattern (abstract class):
abstract class DataPipeline {
    // Template method - final: algorithm structure is fixed
    final void run() {
        List<String> raw = fetch();       // abstract: subclass provides
        List<String> clean = transform(raw); // abstract
        persist(clean);                   // concrete shared step
    }
    protected abstract List<String> fetch();
    protected abstract List<String> transform(List<String> data);
    private void persist(List<String> data) {
        // shared DB logic here
    }
}

class S3Pipeline extends DataPipeline {
    @Override protected List<String> fetch() { return readFromS3(); }
    @Override protected List<String> transform(List<String> d) {
        return d.stream().map(String::trim).collect(Collectors.toList());
    }
}

// Interface mixin: multiple capabilities:
interface Auditable { void audit(); }
interface Cacheable { void evict(); }
interface Validatable { boolean validate(); }

class Order implements Auditable, Cacheable, Validatable {
    @Override public void audit() { ... }
    @Override public void evict() { ... }
    @Override public boolean validate() { return true; }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java Stream pipeline using Stream. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **TAKEAWAY: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Abstract classes can have state (fields) and constructors; interfaces
> cannot. A class can extend one abstract class but implement many interfaces.
> Use abstract class for shared code + Template Method pattern. Use interface
> for contracts and capabilities (Comparable, Iterable, Runnable). Java 8
> added default methods to interfaces, reducing the difference.

---

**Senior / Staff (5+ years):**
> The "interface vs abstract class" decision is fundamentally about type
> semantics and inheritance structure. Interfaces define orthogonal
> capabilities (mixins). Abstract classes define is-a relationships with
> shared state. Default methods in interfaces enable defensive API evolution
> (add new methods without breaking existing implementations). But default
> methods add complexity when combined with inheritance - the resolution
> rules (class wins over default, specific interface wins over less specific)
> must be well-understood. Prefer interfaces for new API design; use abstract
> classes for framework extension points with shared infrastructure.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Default methods in interfaces make interfaces equal
to abstract classes."**
Interfaces still cannot have instance fields (no state) or constructors.
Default methods are purely behavioral - they can call other interface
methods but cannot access per-instance state. This fundamental difference
means interfaces cannot implement stateful patterns (decorators with
instance caches, etc.) that abstract classes can.

**Misconception 2: "Abstract classes are faster than interfaces."**
JVM virtual dispatch treats abstract class methods and interface methods
essentially the same. The JIT optimizer inlines both. No measurable
performance difference in hot code.

---

### 🚨 Failure Modes and Diagnosis

**Failure: diamond default method conflict.**
```java
interface A { default void hello() { System.out.println("A"); } }
interface B { default void hello() { System.out.println("B"); } }

class C implements A, B {
    // Compile error: C inherits unrelated defaults for hello() from A and B
    // Fix: must override to resolve ambiguity:
    @Override public void hello() {
        A.super.hello(); // explicitly call A's default
    }
}
```
> **Code walkthrough:** This Unknown example demonstrates contract definition using interface. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **TAKEAWAY: interfaces define contracts; prefer them over abstract classes for unrelated types.**

Diagnosis: compiler error will tell you which interfaces conflict.
Always override when two interfaces provide conflicting defaults.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Interface vs abstract class | 90 seconds |
| Default method conflicts | 2 minutes |
| Functional interfaces | 2 minutes |
| Template method pattern | 2 minutes |
| Interface segregation | 2 minutes |
| Abstract class constructor | 90 seconds |
| Marker interfaces | 90 seconds |

---

**Q1 (Interface vs abstract): When do you choose interface over
abstract class?**

A:

**Choose Interface when:**
- Defining a capability, not an identity (Runnable, Comparable, Printable)
- Multiple implementations needed from unrelated class hierarchies
- Type token / marker purpose (Serializable, Cloneable)
- Functional interface for lambda use
- API contract that must not restrict the implementor's class hierarchy

**Choose Abstract Class when:**
- Sharing state (instance fields) across subclasses
- Template Method pattern: algorithm skeleton with pluggable steps
- Providing non-trivial default implementations that need state
- Building framework extension points with infrastructure

```java
// Interface: capability (any class can be Comparable)
interface Comparable<T> { int compareTo(T other); }
// String, Integer, Date all implement Comparable - unrelated hierarchies

// Abstract class: is-a with shared state
abstract class AbstractHttpClient {
    private final String baseUrl; // shared state
    protected final HttpSession session = createSession();
    AbstractHttpClient(String baseUrl) { this.baseUrl = baseUrl; }
    abstract Response doRequest(Request req);
    final Response get(String path) {
        return doRequest(new Request("GET", baseUrl + path));
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates contract definition using interface. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **TAKEAWAY: interfaces define contracts; prefer them over abstract classes for unrelated types.**

*What separates good from great:* The Java SDK itself shows the pattern:
`AbstractList` (abstract class, shared state + template), `List`
(interface, contract). `AbstractList` reduces effort to implement a
custom List by implementing most methods via `get()` and `size()`.
This combination - define interface + provide abstract base - is called
the Interface + Skeletal Implementation pattern (Effective Java, Item 20).
Spring uses it extensively: `AbstractBeanFactory`, `AbstractController`, etc.

---

**Q2 (Default method conflicts): How does Java resolve conflicting
default methods?**

A: Three rules in priority order:

1. **Class or superclass wins:** if a class or any superclass provides
   an implementation, it takes priority over all interface defaults.
2. **More specific interface wins:** if one interface extends another
   and both provide defaults, the more specific (child) interface wins.
3. **Must override:** if neither rule resolves, the class must explicitly
   override.

```java
interface A { default void m() { System.out.println("A"); } }
interface B extends A {
    @Override default void m() { System.out.println("B"); }
}
class C implements A, B {
    // B wins (more specific than A)
}
new C().m(); // prints "B"

interface X { default void m() { System.out.println("X"); } }
interface Y { default void m() { System.out.println("Y"); } }
class D implements X, Y {
    // Compile error: neither X nor Y is more specific
    @Override public void m() {
        X.super.m(); // explicitly delegate to X
        // or:
        // Y.super.m(); // or to Y
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates contract definition using interface. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **TAKEAWAY: interfaces define contracts; prefer them over abstract classes for unrelated types.**

*What separates good from great:* Default methods were added for API
evolution: existing interfaces could add new methods without breaking
all existing implementations (e.g., `Collection.forEach()`,
`Map.computeIfAbsent()`). The diamond conflict problem is rare in
practice because most interfaces in the same type hierarchy share
ancestry. The conflict only arises with truly unrelated interfaces
providing the same default method - which is usually an API design
mistake.

---

**Q3 (Functional interfaces): Explain functional interfaces and
their role with lambdas.**

A: A functional interface is an interface with exactly one abstract
method (SAM - Single Abstract Method). Default methods and static
methods don't count. The `@FunctionalInterface` annotation is
optional but recommended (compiler validates SAM requirement).

```java
@FunctionalInterface
interface Validator<T> {
    boolean validate(T value);           // single abstract method
    default Validator<T> and(Validator<T> other) { // default - ok
        return v -> this.validate(v) && other.validate(v);
    }
    static <T> Validator<T> notNull() {  // static - ok
        return v -> v != null;
    }
}

// Lambda = anonymous implementation of functional interface:
Validator<String> notEmpty = s -> !s.isEmpty();
Validator<String> notTooLong = s -> s.length() <= 100;
Validator<String> combined = notEmpty.and(notTooLong);

combined.validate("");       // false
combined.validate("hello");  // true
```

> **Code walkthrough:** This Unknown example demonstrates contract definition using interface. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **TAKEAWAY: interfaces define contracts; prefer them over abstract classes for unrelated types.**

Standard functional interfaces in `java.util.function`:
- `Function<T,R>`: T -> R (transform)
- `Consumer<T>`: T -> void (side effect)
- `Supplier<T>`: () -> T (produce)
- `Predicate<T>`: T -> boolean (test)
- `BiFunction<T,U,R>`: (T,U) -> R (two inputs)
- `UnaryOperator<T>`: T -> T (same type in/out)

*What separates good from great:* Functional interface composition is
a powerful pattern. `Predicate.and()`, `Predicate.or()`, `Function.andThen()`,
`Function.compose()` build pipelines without creating named classes.
But over-composing function objects creates opaque call chains that are
hard to debug. Rule: use function composition for simple transformations;
use named methods for complex business logic (better stack traces,
easier testing).

---

**Q4 (Template method pattern): Where is the Template Method pattern
used in Java's standard library?**

A: Template Method: define the algorithm skeleton in a base class
(often `final`), let subclasses fill in specific steps.

**Java stdlib examples:**
- `AbstractList.sort()`: uses the list's own element comparison, calls
  `listIterator()` which subclasses provide
- `Thread.run()`: the `Thread` class's `run()` calls `target.run()` if
  set, or the subclass overrides `run()` directly
- `HttpServlet.service()`: dispatches to `doGet()`, `doPost()` etc.
  which subclasses override
- `AbstractQueuedSynchronizer (AQS)`: `acquire()` calls `tryAcquire()`
  which ReentrantLock, Semaphore, CountDownLatch override

```java
// Spring's Template Method: JdbcTemplate
public class JdbcTemplate {
    // Template method:
    public <T> T query(String sql, ResultSetExtractor<T> rse) {
        // acquire connection, create statement, execute, handle errors
        // ... boilerplate ...
        return rse.extractData(resultSet); // your code here
    }
}
// User provides only the extraction logic (lambda):
String name = jdbc.query(
    "SELECT name FROM user WHERE id = ?",
    rs -> rs.getString("name"),
    id
);
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using SQL. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* The Template Method pattern captures
the "Hollywood Principle" - don't call us, we'll call you. The framework
controls the flow; the application code provides customization points.
This is the foundation of Spring, Hibernate, and most Java frameworks.
Understanding Template Method helps you understand why framework classes
use `abstract` and why you override specific methods rather than writing
top-level code.

---

**Q5 (Interface segregation): What is Interface Segregation Principle
and how does Java support it?**

A: Interface Segregation Principle (ISP): clients should not be forced
to depend on interfaces they don't use. Large "fat" interfaces should
be split into smaller, focused interfaces.

```java
// FAT interface - violates ISP:
interface Employee {
    void work();
    void takeBreak();
    void attendMeeting();
    void writeTimesheet();
    void performReview(); // managers only!
    void approveBudget(); // finance only!
}

// SEGREGATED interfaces - obey ISP:
interface Worker { void work(); }
interface Reviewer { void performReview(); }
interface BudgetApprover { void approveBudget(); }

class Developer implements Worker, Reviewer { ... }
class FinanceManager implements Worker, Reviewer, BudgetApprover { ... }
// Each class implements only what it needs
```

> **Code walkthrough:** This Unknown example demonstrates contract definition using interface. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **TAKEAWAY: interfaces define contracts; prefer them over abstract classes for unrelated types.**

Java naturally supports ISP: multiple interface implementation means you
can compose small interfaces without forcing unrelated implementations.
Functional interfaces (single method) are the extreme case of ISP.

*What separates good from great:* Applying ISP requires identifying
"role interfaces" vs "header interfaces". A role interface captures
a specific behavior (Auditable, Printable); a header interface captures
all methods of a class (a 1:1 mapping). Role interfaces (ISP) enable
better decoupling. The `java.util.Collection` hierarchy is a good example:
`Iterable` (just iterate), `Collection` (add/remove), `List` (indexed),
`RandomAccess` (marker for efficient indexed access) - each additional
interface adds one capability.

---

**Q6 (Abstract class constructor): Can abstract classes have constructors
and what is their purpose?**

A: Yes. Abstract classes can and should have constructors. They cannot
be called directly (`new AbstractClass()` is a compile error) but are
called by subclass constructors via `super(...)`.

Purpose: initialize the shared state (fields) that the abstract class
defines and subclasses inherit.

```java
abstract class Shape {
    private final String color;
    private final boolean filled;

    // Constructor initializes shared state:
    protected Shape(String color, boolean filled) {
        this.color = Objects.requireNonNull(color);
        this.filled = filled;
    }

    public String getColor() { return color; }
    public boolean isFilled() { return filled; }
    public abstract double area();
}

class Circle extends Shape {
    private final double radius;
    Circle(String color, boolean filled, double radius) {
        super(color, filled); // must call abstract class constructor
        this.radius = radius;
    }
    @Override public double area() { return Math.PI * radius * radius; }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Abstract class constructors can
enforce invariants for ALL subclasses. `Objects.requireNonNull(color)`
in `Shape`'s constructor means NO subclass can create a shape with
null color - the check runs before any subclass code. This is a powerful
way to enforce domain invariants centrally. Contrast with interfaces:
no constructor, no shared state, no centralized invariant enforcement.

---

**Q7 (Marker interfaces): What is a marker interface and when should
you use one vs annotations?**

A: A marker interface has no methods - it exists only to tag a class
as having some property.

Classic Java marker interfaces:
- `Serializable`: marks a class as safe to serialize
- `Cloneable`: marks a class as supporting `clone()` (poorly designed)
- `RandomAccess`: marks a List as supporting fast random access

```java
// Marker interface approach:
interface Cacheable {}
class UserDTO implements Cacheable { ... }
class ProductDTO implements Cacheable { ... }

// Type-safe check:
if (obj instanceof Cacheable) {
    cacheService.cache(obj);
}
// Can be used as generic type bound:
<T extends Cacheable> void cache(T obj) { ... }
```

> **Code walkthrough:** This Unknown example demonstrates contract definition usice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Marker interface vs annotation:**
  |               | Marker Interface     | Annotation                     |  
|-------------|--------------------|------------------------------|
  | Type check    | `instanceof`         | reflection or framework        |  
  | Generic bound | `<T extends Marker>` | not possible                   |  
  | Applies to    | Classes              | Classes, methods, fields, etc. |  
  | Inherited     | Yes                  | `@Inherited` needed            |  
  | Retention     | Compile + runtime    | Configurable                   |  

Prefer annotations when: marking methods, fields, or constructors;
specifying metadata (configuration values); the mark is checked by
a framework at compile or annotation processor time.
Prefer marker interfaces when: compile-time type safety is needed;
the mark should be constrainable with generics.

*What separates good from great:* `Serializable` is a famous poor
example. It's a marker with no methods, but serialization behavior
depends on `serialVersionUID`, `readObject()`, `writeObject()` -
none of which are in the interface. Java can't verify that a class
actually serializes correctly just from the marker. Annotations with
retention `RUNTIME` are almost always clearer and more powerful
for framework metadata. Modern Java uses annotations extensively
(JPA `@Entity`, Spring `@Component`) and avoids marker interfaces
for new APIs.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*

---

---

## Exception Handling Basics

---

### 🎯 Model Answer

**30 seconds:**
> Java exceptions are objects that represent error conditions. Checked
> exceptions (extend Exception) must be declared in `throws` or caught -
> the compiler enforces this. Unchecked exceptions (extend RuntimeException)
> need not be declared. `try-catch-finally` handles exceptions; `finally`
> always runs. `try-with-resources` (Java 7) automatically closes
> `AutoCloseable` resources. Key rule: catch specific exception types,
> not bare `Exception`. Log the root cause, don't swallow exceptions.

**3 minutes (Senior):**
> Checked vs unchecked debate: checked exceptions force callers to handle
> errors, documenting failure modes in the API. But they pollute method
> signatures and are incompatible with lambdas (can't throw checked
> exceptions from `Function<T,R>`). Modern Java consensus: use unchecked
> (RuntimeException) for most application code; checked only for recoverable
> conditions where the caller MUST handle (e.g., `IOException` for files).
>
> Exception chaining: always wrap exceptions with context when re-throwing.
> `throw new ServiceException("Failed to load user " + id, e)` preserves
> the original cause. Lost cause = lost debugging context.
>
> Try-with-resources handles `Closeable`/`AutoCloseable` objects. Suppressed
> exceptions: if both the try body AND the close() throw, the close()
> exception is suppressed (added to the primary exception). Check
> `e.getSuppressed()` in debugging.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Exception handling - let me cover the hierarchy,
checked vs unchecked, try-catch-finally, try-with-resources, and
exception design best practices."

**(2) First principles:** "From first principles: errors need to be
communicated from where they occur to where they can be handled.
Java's exception system uses object propagation up the call stack,
with explicit declaration (checked) or implicit propagation (unchecked)."

**(3) Bridge:** "Checked exceptions are like registered mail - both
sender and receiver must acknowledge the exchange. Unchecked exceptions
are like unregistered mail - no acknowledgment required, but if something
goes wrong you find out when you check."

---

### 📘 Concept Explanation

**Exception hierarchy:**
```plaintext
Throwable
  |-- Error (JVM errors - do not catch)
  |     |-- OutOfMemoryError
  |     |-- StackOverflowError
  |     |-- AssertionError
  |
  |-- Exception (application-level errors)
        |-- RuntimeException (unchecked - no declaration required)
        |     |-- NullPointerException
        |     |-- IllegalArgumentException
        |     |-- IllegalStateException
        |     |-- IndexOutOfBoundsException
        |     |-- ClassCastException
        |
        |-- IOException (checked - must declare or catch)
        |-- SQLException (checked)
        |-- ParseException (checked)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Checked vs unchecked:**
- Checked: compiler verifies caller handles (try-catch) or declares (`throws`)
- Unchecked: no compiler enforcement; propagates automatically

---

### 💻 Code Example

> **Code walkthrough:** The BAD pattern catches the broad `Exception`ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> class, hiding all exceptions in one catch block and making debugging
> impossible. The GOOD pattern catches specific exceptions, handles
> each appropriately, and wraps with context when re-throwing. The
> try-with-resources pattern ensures the reader is closed in all cases
> without explicit finally, and handles suppressed exceptions from close().


```java
// BAD: null check without Optional
User user = findUser(id);
if (user != null) {
    return user.getName();
}
return null; // callers must null-check return value
```

```java
// BAD: broad catch, exception swallowed:
try {
    User user = userRepo.findById(id);
    emailService.send(user.getEmail());
} catch (Exception e) {
    // Swallowed! No logging, no rethrow - error disappears
}

// GOOD: specific catches, context preserved:
try {
    User user = userRepo.findById(id)
        .orElseThrow(() ->
            new UserNotFoundException("User not found: " + id));
    emailService.send(user.getEmail());
} catch (UserNotFoundException e) {
    throw e; // let caller handle missing user
} catch (EmailDeliveryException e) {
    // recoverable: retry or fallback
    log.warn("Email failed for user {}, retrying", id, e);
    notificationService.queueRetry(id, e);
} catch (DatabaseException e) {
    // wrap with context:
    throw new ServiceException(
        "Failed to load user " + id + " for email send", e);
}

// try-with-resources (Java 7+):
try (
    BufferedReader reader = new BufferedReader(
        new FileReader("data.csv")); // auto-closed
    Connection conn = dataSource.getConnection() // also auto-closed
) {
    String line;
    while ((line = reader.readLine()) != null) {
        processLine(conn, line);
    }
} // reader.close() and conn.close() called in reverse order
  // even if an exception occurs
```

> **Code walkthrough:** `try-with-resources` calls `close()` in theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> reverse order of resource declaration: `conn.close()` then `reader.close()`.
> If both the body AND `close()` throw exceptions, the exception from
> `close()` is suppressed (attached to the primary exception via
> `addSuppressed()`). You can retrieve suppressed exceptions:
> `e.getSuppressed()[0]`. This is important for diagnosis when database
> connection closing fails after a business logic error.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Checked exceptions extend `Exception`; unchecked extend `RuntimeException`.
> Checked exceptions must be caught or declared in `throws`. Unchecked
> don't. Use `try-catch` to handle exceptions, `finally` for cleanup,
> or `try-with-resources` for AutoCloseable resources. Don't catch bare
> `Exception`; catch specific types. Don't swallow exceptions without logging.

---

**Senior / Staff (5+ years):**
> The checked vs unchecked debate: James Gosling intended checked exceptions
> to force explicit error handling for recoverable conditions. In practice,
> checked exceptions became problematic because: they're incompatible with
> lambdas, pollute API signatures, and often lead to empty catch blocks.
> Modern consensus: use unchecked (RuntimeException) for most code, document
> failure conditions in Javadoc instead. Spring's approach: wrap all JDK
> checked exceptions in unchecked `NestedRuntimeException`. Exception
> hierarchy design: create domain-specific exception hierarchies (`OrderException
> -> PaymentException, ShippingException`) for fine-grained handling.

---

### ⚠️ Common Misconceptions

**Misconception 1: "catch (Exception e) {} is safe cleanup."**
Catching `Exception` and doing nothing (swallowing) hides bugs,
makes debugging impossible, and may mask `Error` subclasses. Always:
log the exception at minimum. Preferably: rethrow as a more specific
exception with context, or handle meaningfully.

**Misconception 2: "finally always runs AFTER the catch block."**
`finally` runs even when there is NO catch block, and even when the
catch block throws. It runs after `return` statements in try/catch.
Exception: `System.exit()` terminates JVM before `finally`. Thread kill
(`Thread.stop()`, deprecated) may prevent `finally`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: exception chain broken during re-throw.**

```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// BAD: original cause lost:
try {
    conn.query(sql);
} catch (SQLException e) {
    throw new RuntimeException("Query failed"); // e is LOST
}

// GOOD: chain preserved:
try {
    conn.query(sql);
} catch (SQLException e) {
    throw new RuntimeException("Query failed for: " + sql, e); // e in cause
}
// In stack trace: Caused by: java.sql.SQLException: ...
// Without chaining: you see RuntimeException only - no root cause
```
> **Code walkthrough:** BAD pattern: This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **WHAT BREAKS: log or rethrow every exception; empty catch blocks are defects.**

Diagnosis: search codebase for `throw new Exception(message)` without
passing `cause`. Replace with `throw new Exception(message, cause)`.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Checked vs unchecked | 2 minutes |
| try-with-resources | 2 minutes |
| Exception hierarchy design | 2-3 minutes |
| Suppressed exceptions | 90 seconds |
| Exception chaining | 90 seconds |
| finally guarantees | 2 minutes |
| Multi-catch syntax | 60 seconds |

---

**Q1 (Checked vs unchecked): When should you use checked vs unchecked
exceptions?**

A: The question of when to use checked vs unchecked is one of Java's
most debated design topics.

**Use CHECKED exceptions when:**
- The caller CAN and SHOULD handle the exception
- Recovery is possible and meaningful
- The failure is part of the normal contract (not a bug)
- Classic examples: `IOException` (file may not exist - check first),
  `InterruptedException` (thread interruption is expected)

**Use UNCHECKED exceptions when:**
- The error is a programming bug (NPE, illegal argument)
- The caller cannot meaningfully recover
- The code is used in lambda/stream contexts
- The failure is infrastructure/unexpected (DB connection dropped)

**Modern practice:**
```java
// Checked: file may not exist - callers should handle
public byte[] readConfig(Path path) throws IOException { ... }

// Unchecked: invalid argument is a programming error
public void setAge(int age) {
    if (age < 0) throw new IllegalArgumentException(
        "Age must be non-negative: " + age);
    // no throws declaration needed
}

// Spring/framework pattern: wrap checked as unchecked
try {
    return jdbcTemplate.queryForObject(sql, String.class, id);
} catch (DataAccessException e) { // Spring's unchecked wrapper
    throw new UserNotFoundException("User not found: " + id, e);
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

*What separates good from great:* The lambda incompatibility is the
strongest argument against checked exceptions for modern code. A
`Function<String, Integer>` cannot throw `ParseException` without
a wrapper. Many codebases use a utility:
`@FunctionalInterface interface ThrowingFunction<T,R> { R apply(T t) throws Exception; }`
with a static `wrap(ThrowingFunction)` adapter. This is boilerplate
that checked exceptions force upon functional programming. Kotlin and
C# made all exceptions unchecked for this reason.

---

**Q2 (try-with-resources): How does try-with-resources work and what
is the suppressed exception mechanism?**

A: `try-with-resources` (Java 7, JEP 334) automatically calls `close()`
on resources declared in the try header, in reverse declaration order.

```java
try (Resource1 r1 = ...; Resource2 r2 = ...) {
    // body
} // calls: r2.close(), then r1.close()
  // regardless of whether body threw or returned normally
```

> **Code walkthrough:** This Unknown example demonstrates exception handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

**Suppressed exception scenario:**
```java
try (var conn = openConnection()) {
    throw new BusinessException("Bad data"); // primary exception
    // conn.close() is called; if it also throws:
    // ConnectionCloseException is SUPPRESSED
}
// Result: catch gets BusinessException
// BusinessException.getSuppressed() = [ConnectionCloseException]
```

> **Code walkthrough:** This Unknown example demonstrates exception handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

Examining suppressed:
```java
try {
    ...
} catch (BusinessException e) {
    log.error("Primary: {}", e.getMessage(), e);
    for (Throwable suppressed : e.getSuppressed()) {
        log.error("Suppressed: {}", suppressed.getMessage(), suppressed);
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

Classes implementing `AutoCloseable` (not `Closeable`) can throw any
exception from `close()`. `Closeable` restricts to `IOException`.

*What separates good from great:* Suppressed exceptions are frequently
ignored in debugging. A `ConnectionCloseException` being silently
swallowed means the developer doesn't notice a connection leak.
Always log `getSuppressed()` in global exception handlers / logging
advice. Frameworks like Spring AOP can add cross-cutting logging of
suppressed exceptions. Also: `close()` should not throw for idempotency;
trying to close an already-closed resource should be a no-op, not an
exception.

---

**Q3 (Exception hierarchy design): How do you design a domain exception
hierarchy?**

A: A well-designed exception hierarchy provides:
- Catch at the right level of abstraction
- Specific handling for specific failures
- Generic handling for the entire domain

```java
// Domain exception hierarchy:
public class OrderException extends RuntimeException {
    // catch-all for order failures
    public OrderException(String message) { super(message); }
    public OrderException(String message, Throwable cause) {
        super(message, cause);
    }
}

public class PaymentException extends OrderException {
    private final String paymentId;
    public PaymentException(String paymentId, String message, Throwable cause) {
        super(message, cause);
        this.paymentId = paymentId;
    }
    public String getPaymentId() { return paymentId; }
}

public class InsufficientFundsException extends PaymentException {
    private final BigDecimal available;
    private final BigDecimal required;
    // carries diagnostic context
}

// Catching at different levels:
try {
    orderService.processOrder(order);
} catch (InsufficientFundsException e) {
    return ResponseEntity.status(402).body("Insufficient funds: " + e.getRequired());
} catch (PaymentException e) {
    return ResponseEntity.status(402).body("Payment failed: " + e.getPaymentId());
} catch (OrderException e) {
    return ResponseEntity.status(500).body("Order processing failed");
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

*What separates good from great:* Include diagnostic context in custom
exceptions: not just a message but the IDs, values, and state that
caused the failure. `InsufficientFundsException` carrying `available`
and `required` amounts means the error handler can generate precise
user messages and can be logged with full context without re-fetching
data. Exception classes are part of the API contract; changing them
is a breaking change. Design exception hierarchies as carefully as
regular class hierarchies.

---

**Q4 (Suppressed exceptions): When would you need to check getSuppressed()?**

A: Suppressed exceptions occur when: the try body throws, AND a
`close()` call in try-with-resources ALSO throws. The close exception
is attached to the primary exception as suppressed.

Scenarios where this matters in production:
1. **Database connection close fails:** if `close()` fails after a
   query exception, you miss the connection leak.
2. **File close fails:** OS file handle not released properly.
3. **Network socket close throws:** underlying network issue.

```java
// Utility to log all exceptions including suppressed:
static void logFullException(Logger log, Exception e) {
    log.error("Primary exception: ", e);
    Throwable[] suppressed = e.getSuppressed();
    for (int i = 0; i < suppressed.length; i++) {
        log.error("Suppressed[{}]: ", i, suppressed[i]);
    }
    if (e.getCause() != null) {
        log.error("Cause: ", e.getCause());
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Spring's `DataAccessUtils` and most framework exception translators
preserve suppressed exceptions in their wrapping.

*What separates good from great:* In production incident analysis,
missing the suppressed exception can lead to wrong root cause analysis.
If the DB query failed AND the connection close failed (indicating
connection pool exhaustion or network partition), both pieces of
information are needed. A good error reporting framework logs the
full exception chain including suppressed exceptions and causes.
OpenTelemetry's exception recording includes suppressed by default.

---

**Q5 (Exception chaining): Why is exception chaining important and how
do you use it?**

A: Exception chaining (introduced in Java 1.4) preserves the original
exception as the "cause" of a wrapping exception. The full chain appears
in the stack trace: `Caused by: ...`.

```java
// Layer 1: DAO throws specific exception
public User findUser(long id) {
    try {
        return jdbcTemplate.queryForObject(
            "SELECT * FROM users WHERE id=?", USER_MAPPER, id);
    } catch (EmptyResultDataAccessException e) {
        throw new UserNotFoundException(
            "User not found: " + id, e); // chain preserved
    }
}

// Layer 2: Service wraps with business context
public UserProfile getProfile(long userId) {
    try {
        User user = userDao.findUser(userId);
        return buildProfile(user);
    } catch (UserNotFoundException e) {
        throw new ProfileLoadException(
            "Cannot load profile for userId=" + userId, e);
    }
}

// Stack trace shows:
// ProfileLoadException: Cannot load profile for userId=42
//   at UserService.getProfile(UserService.java:45)
// Caused by: UserNotFoundException: User not found: 42
//   at UserDAO.findUser(UserDAO.java:23)
// Caused by: EmptyResultDataAccessException: ...
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using SQL. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

*What separates good from great:* Exception messages should include
the DATA that was being processed, not just the operation. "User not
found" is less useful than "User not found: id=42" when scanning logs
for a specific customer's issue. The message is your primary debugging
tool when you have a thread dump but no debugger. Treat exception
messages as your first line of log evidence.

---

**Q6 (finally guarantees): What are the guarantee and non-guarantee
of finally blocks?**

A:

**finally ALWAYS runs in:**
- Normal completion of try block
- Exception in try block (whether caught or not)
- `return` statement in try or catch block
- `break`/`continue` in try block

**finally does NOT run when:**
- `System.exit()` is called (JVM terminates)
- JVM is killed (kill -9, power off)
- Infinite loop in try block (finally waits but runs eventually if break)
- `Runtime.halt()` or `Runtime.getRuntime().halt(0)`

```java
// finally with return (tricky):
int getValue() {
    try {
        return 1;     // sets return value to 1
    } finally {
        return 2;     // OVERRIDES return 1! Returns 2
    }
}
// getValue() returns 2
// This is a code smell - never return from finally
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

**Prefer try-with-resources over finally for resources:**

```java
// BAD: null check without Optional
User user = findUser(id);
if (user != null) {
    return user.getName();
}
return null; // callers must null-check return value
```

```java
// BAD: manual finally, verbose, error-prone:
Connection conn = null;
try {
    conn = getConnection();
    // ...
} finally {
    if (conn != null) {
        try { conn.close(); } catch (SQLException e) { /* suppressed */ }
    }
}

// GOOD: try-with-resources handles this correctly:
try (Connection conn = getConnection()) {
    // ...
}
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **WHAT BREAKS: log or rethrow every exception; empty catch blocks are defects.**

*What separates good from great:* The `return` from `finally` override
is a famous Java gotcha. If `finally` returns a value, it silently
overrides the try/catch's return or exception. This can hide exceptions:
if the try body throws an exception and the finally block returns
normally, the exception is LOST. Code review checklist: flag any
`return` statement inside a `finally` block.

---

**Q7 (Multi-catch syntax): What is multi-catch syntax and when is
it useful?**

A: Multi-catch (Java 7+, JEP 334) allows catching multiple unrelated
exception types in a single catch block using `|`:

```java
// BEFORE Java 7: duplicate handling:
try {
    riskyOperation();
} catch (IOException e) {
    log.error("IO error", e);
    throw new ServiceException("Operation failed", e);
} catch (SQLException e) {
    log.error("IO error", e);    // same handling - duplicated!
    throw new ServiceException("Operation failed", e);
}

// Java 7+: multi-catch:
try {
    riskyOperation();
} catch (IOException | SQLException e) {
    // e is effectively final - cannot be reassigned
    log.error("Operation error", e);
    throw new ServiceException("Operation failed", e);
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

Multi-catch type: the inferred type is the common supertype. If
`IOException` and `SQLException` both extend `Exception`, `e` is
of type `Exception` in the multi-catch block.

**When to use:**
- Same handling for unrelated exceptions (different inheritance hierarchy)
- Reducing boilerplate without a common base exception class
- When you cannot or don't want to catch the common supertype (Exception)

*What separates good from great:* Multi-catch implicitly makes `e`
effectively final - you cannot reassign it. This is intentional: if
you could reassign `e` to a different exception type, the runtime type
would be ambiguous. This restriction also encourages cleaner code:
you should handle the exception as received, not transform it into
a different type inside the catch block. If transformation is needed,
catch separately and rethrow explicitly.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: hierarchy described adequately in code comments)*

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



