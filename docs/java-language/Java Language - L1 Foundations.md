---
layout: default
title: "Java Language - L1 Foundations"
parent: "Java Language"
nav_order: 2
permalink: /java-language/l1-foundations/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Primitive Types and Autoboxing](#primitive-types-and-autoboxing) | high |
| 2 | [Reference Types and Pass-by-Value](#reference-types-and-pass-by-value) | high |
| 3 | [Access Modifiers](#access-modifiers) | medium |
| 4 | [Static vs Instance Context](#static-vs-instance-context) | high |
| 5 | [Java Control Flow](#java-control-flow) | medium |

---

# Primitive Types and Autoboxing

**Interview Weight:** high - One of the most common Java gotcha
questions. Interviewers use this to filter candidates who know
Java syntax from those who understand the type system and the
performance implications of autoboxing.

---

### 🎯 Model Answer

**30 seconds:**

> Java has 8 primitive types (byte, short, int, long, float, double,
> char, boolean) that live on the stack and store raw values directly.
> Each has a corresponding wrapper class (Integer, Long, Double...)
> that is a full object on the heap. Autoboxing is the compiler
> automatically converting between the two. The danger: autoboxing
> in a hot loop creates millions of short-lived objects, generating
> GC pressure. The subtlety: Integer.valueOf(-128 to 127) returns
> cached instances - `==` comparison works there but fails outside
> that range.

**3 minutes (Senior):**

> Primitives are Java's performance escape hatch. They are stored
> on the stack (for local variables), not the heap, and avoid
> object header overhead (typically 16 bytes per object). An int
> is 4 bytes; an Integer object is 16+ bytes with header overhead
> and an int field inside it.
>
> Autoboxing is syntactic sugar that the compiler expands to
> `Integer.valueOf(x)` for boxing and `integer.intValue()` for
> unboxing. The JIT often eliminates boxing entirely through escape
> analysis - if an Integer never escapes the method, the JIT may
> keep it as a primitive on the stack. But this optimization is
> JIT-profile-dependent and not guaranteed.
>
> The Integer cache (pool) caches values -128 to 127. This is the
> source of one of Java's most common interview traps: `Integer a =
> 127; Integer b = 127; a == b` is `true` (same cached object);
> `Integer a = 128; Integer b = 128; a == b` is `false` (different
> objects). Always compare boxed types with `.equals()`.
>
> In hot code paths - sorting comparators, stream operations,
> collection lookups - the difference between using `int[]` vs
> `List<Integer>` can be 5-10x in throughput due to boxing
> overhead, cache locality, and GC pressure.

**Framework:** PRIMITIVES (raw values, stack) → WRAPPERS
(objects, heap) → AUTOBOXING (compiler sugar) → TRAPS
(== on Integer, GC pressure in loops)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the difference between
int and Integer, and what autoboxing is."

**(2) First principles:** "Java needs both raw numeric types for
performance and object types for generics. You cannot put an int
in a List<int>. Autoboxing is the bridge."

**(3) Bridge:** "This is similar to C# boxing/unboxing, except
Java's specific trap is the Integer cache for small values."

---

### 📘 Concept Explanation

**What it is:**

Eight primitive types (byte 1B, short 2B, int 4B, long 8B, float
4B, double 8B, char 2B, boolean 1B) hold raw values in-place.
Wrapper classes (Byte, Short, Integer, Long, Float, Double,
Character, Boolean) wrap them as objects for use in collections
and generics. Autoboxing/unboxing is the compiler-generated
conversion between them.

**The problem it solves:**

Java's generics are erased to Object at runtime - you cannot use
primitive types as generic type parameters. `List<int>` is illegal;
`List<Integer>` works because Integer is an Object. Autoboxing
lets you write `list.add(5)` instead of `list.add(Integer.valueOf(5))`.

**How it works:**

```java
// Autoboxing: compiler rewrites this
int x = 5;
Integer boxed = x;  // compiled to: Integer.valueOf(x)

// Unboxing: compiler rewrites this
int y = boxed;      // compiled to: boxed.intValue()

// Integer cache range: [-128, 127]
Integer a = 100;    // returns Integer.valueOf(100) - CACHED
Integer b = 100;
a == b;             // true - same cached object

Integer c = 200;    // returns new Integer(200) - NOT cached
Integer d = 200;
c == d;             // false - different objects!
```

**The key insight:**

Every unboxing operation on a null reference throws a
NullPointerException - this is the #1 source of production
NPEs from autoboxing. `Integer sum = null; int result = sum + 1;`
throws NPE at unboxing. Always initialize wrapper types, or
use primitives when nullability is not needed.

**When to use it:**

- Primitives: default for numeric computation, local variables,
  method parameters where null is not a valid value
- Wrappers: when you need to store in a collection, use as a
  generic type parameter, or explicitly represent absence (null)
- Wrappers in DTOs/entities where "field not set" means null
  (vs. 0 for unset int)

**When NOT to use it:**

- Avoid `List<Integer>` when `int[]` suffices for performance-
  critical code - boxing creates GC pressure
- Never use `==` to compare boxed numerics (use `.equals()`)
- Avoid boxing in tight loops (stream operations on large
  integer datasets)

**Alternatives:**

- `int[]` instead of `List<Integer>` for numerical data
- `OptionalInt`, `IntStream` for null-safe/functional int
  operations without boxing
- Valhalla (upcoming Java feature) - value types that avoid
  the boxing overhead for generics

**First-principles derivation:**

Java needs generics to work on the Object type hierarchy. Primitives
are not Objects. You need either: (1) allow generics to know about
primitives (complex, adds to VM spec), or (2) provide Object
wrappers and auto-convert. Java chose option 2. The Integer cache
exists as a micro-optimization (small integer literals are
common; sharing them saves allocation). The range -128 to 127
is configurable via `-XX:AutoBoxCacheMax`.

---

### 💻 Code Example

**Example 1: The Integer cache trap (Wrong vs Right)**

```java
// BAD: Using == to compare Integer objects
Integer a = 1000;
Integer b = 1000;
if (a == b) {
    // This branch is NEVER taken for values outside [-128, 127]
    // a and b are different heap objects
    System.out.println("equal");
}

// BAD: Unboxing null causes NPE (subtle - no null check visible)
Map<String, Integer> scores = new HashMap<>();
int total = scores.get("missing") + 10;  // NPE! get returns null, unboxing explodes

// GOOD: Use .equals() for wrapper comparison
Integer x = 1000;
Integer y = 1000;
if (x.equals(y)) {         // Always correct
    System.out.println("equal");
}
// Or unbox both and compare primitives:
if (x.intValue() == y.intValue()) { ... }

// GOOD: Null-safe unboxing
Integer raw = scores.get("missing");
int safeTotal = (raw != null ? raw : 0) + 10;
// Or with Java 8+:
int safeTotal2 = scores.getOrDefault("missing", 0) + 10;
```

> **Code walkthrough:** The `==` trap is the most common autoboxing
> bug in production. Integer cache makes `==` work for small values
> (-128 to 127), so unit tests with small values pass, but the bug
> appears in production with large IDs or counts. The NPE pattern
> is harder to spot because the addition `+` triggers unboxing of
> the null Integer before the NPE is thrown.

**Example 2: Autoboxing performance in hot paths**

```java
// BAD: Boxing in a tight loop - creates 1 million Integer objects
List<Integer> list = new ArrayList<>();
for (int i = 0; i < 1_000_000; i++) {
    list.add(i);  // autoboxes each int to Integer - 1M heap allocs
}
int sum = 0;
for (Integer n : list) {
    sum += n;     // unboxes each Integer back to int - 1M unboxes
}

// GOOD: Use primitive array or IntStream when boxing is unnecessary
int[] array = new int[1_000_000];
for (int i = 0; i < array.length; i++) {
    array[i] = i;  // no boxing, contiguous memory, cache-friendly
}
int sum2 = Arrays.stream(array).sum();  // IntStream - no boxing

// GOOD: IntStream avoids boxing entirely
int sum3 = IntStream.range(0, 1_000_000).sum();
```

> **Code walkthrough:** The BAD pattern generates 1 million Integer
> allocations causing GC pressure. The `int[]` approach avoids
> boxing entirely and benefits from cache-line locality (contiguous
> memory). `IntStream.range()` is the idiomatic Java 8+ approach
> for integer ranges - it uses primitive specializations internally,
> so no boxing occurs anywhere in the pipeline.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Java has 8 primitive types like int, long, double that hold raw
> values. Each has a wrapper class like Integer, Long, Double that
> is a full object. Autoboxing converts between them automatically.
> The main gotcha: always use `.equals()` not `==` to compare
> wrapper objects, and be careful with null wrappers that get
> unboxed - they throw NPE.

*Push deeper:* Integer cache range -128 to 127, and why autoboxing
in loops can cause GC pressure.

---

**Senior / Staff (5+ years):**

> In production I watch for autoboxing in three scenarios: (1)
> stream operations on large integer datasets - if the source is
> `List<Integer>`, every operation boxes/unboxes; switch to IntStream
> or primitive arrays for 5-10x speedup. (2) Map lookups where
> a missing key returns null that then gets auto-unboxed - this is
> a common NPE in counter patterns. (3) JVM escape analysis can
> eliminate boxing entirely for confined Integer objects, but you
> cannot rely on it - profile first.

*Push deeper:* Project Valhalla's value types will eventually
allow `List<int>` without boxing - the JVM spec changes needed
for this, and timeline considerations.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is autoboxing?"
- "What are Java's primitive types?"

🗣️ "Autoboxing is the automatic conversion from a primitive type
to its wrapper object and back. Java's 8 primitives are: byte,
short, int, long, float, double, char, boolean. The compiler
inserts `Integer.valueOf(x)` for boxing and `integer.intValue()`
for unboxing. The key practical issue: comparing boxed types with
`==` tests object identity, not value equality - always use
`.equals()` for boxed comparisons."

#### Mechanism

- "What is the Integer cache and what range does it cover?"

🗣️ "The Integer cache is a pool of pre-allocated Integer objects
for values -128 to 127. `Integer.valueOf()` returns cached instances
for values in this range, and new instances outside it. This
is why `Integer a = 100; Integer b = 100; a == b` is true (cached
instances are identical), but `Integer a = 200; Integer b = 200;
a == b` is false (different instances). The upper bound can be
extended with `-XX:AutoBoxCacheMax`, but -128 is fixed."

#### Comparison

- "int vs Integer - when do you use each?"

🗣️ "I use int by default for numeric computation - it is faster,
has no null, and avoids GC pressure. I use Integer when I need to
store it in a collection, use it as a generic type parameter, or
represent an absent value with null. For performance-critical
code with large integer datasets, I avoid `List<Integer>` in favour
of `int[]` or IntStream - the boxing overhead is measurable in
GC profiling."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Integer cache, == trap, autoboxing bytecode. |
| Hiring Manager   | Lead with common NPE scenario - production impact. |
| Bar Raiser       | GC pressure measurement, escape analysis, Valhalla timeline. |
| Peer Engineer    | "The cache trap catches everyone at least once in production..." |

---

---

# Reference Types and Pass-by-Value

**Interview Weight:** high - One of Java's most reliably asked
interview questions. Every interviewer knows this is a common
misconception. Getting it wrong signals a foundational gap.

---

### 🎯 Model Answer

**30 seconds:**

> Java is always pass-by-value. For primitives, the value itself
> is copied. For objects, the value of the reference (a memory
> address) is copied. This means you cannot make a method
> re-point the caller's variable to a different object. But you
> CAN mutate the object the reference points to - because the
> copy of the reference still points to the same heap object.

**3 minutes (Senior):**

> The confusion comes from conflating two things: the reference
> variable and the object it points to. When you call a method with
> an object, Java copies the reference value (a pointer). The
> method has its own copy of that pointer. If the method sets its
> parameter to a new object (`param = new Foo()`), the caller's
> variable is unchanged - the method only changed its local copy
> of the pointer.
>
> But if the method calls a mutating method on the object
> (`param.setName("x")`), the caller sees the change - because
> both the caller's variable and the method's parameter point to
> the same heap object. One mutation, two viewers.
>
> This distinction matters for three things in production: (1)
> defensive copying - if you do not copy mutable objects passed
> to your API, callers can mutate state through the reference.
> (2) builder patterns - you need a fresh copy if you want
> immutable results. (3) null checks - passing null is passing
> the null value as the reference; the callee receives null and
> must handle it.

**Framework:** PRIMITIVE (value copied) → OBJECT (reference
copied, object shared) → MUTATION (visible through copied
reference) → REASSIGNMENT (only local, invisible to caller)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking whether Java passes objects by
reference or by value."

**(2) First principles:** "Every method call needs its own scope.
Variables are either copied (pass-by-value) or shared (pass-by-
reference). Java always copies - the question is what it copies."

**(3) Bridge:** "In C, this is the difference between passing
a struct by value vs passing a pointer by value. Java always
passes the pointer by value."

---

### 📘 Concept Explanation

**What it is:**

In Java, all method arguments are passed by value. For primitive
types (int, long, etc.), the actual bit value is copied. For
reference types (all objects), the reference (a pointer-like
value containing the object's heap address) is copied. The
object itself is not copied.

**The problem it solves:**

Pass-by-reference semantics (where the method can re-seat the
caller's variable) cause subtle action-at-a-distance bugs. Java's
choice (pass-by-value, always) makes caller semantics predictable:
a method cannot replace the object you passed it - only mutate
the existing object if it is mutable.

**How it works:**

```java
// Primitive: value is copied
void increment(int x) {
    x++;           // only the local copy is incremented
}
int n = 5;
increment(n);
// n is still 5 - the copy was incremented, not the original

// Object: reference (pointer) is copied
void rename(StringBuilder sb) {
    sb.append(" Jr.");  // mutates the shared object - VISIBLE to caller
}
void reassign(StringBuilder sb) {
    sb = new StringBuilder("different");  // only local re-seat - INVISIBLE
}
StringBuilder name = new StringBuilder("Alice");
rename(name);
// name is now "Alice Jr." - mutation visible through copied reference
reassign(name);
// name is still "Alice Jr." - local reassignment not visible
```

**The key insight:**

"Pass-by-reference" would mean the method can change WHICH object
your variable points to. Java does not allow this. "Pass-by-value
of a reference" means the method can change WHAT IS IN the object
your variable points to (via mutation). This is a crucial
distinction that interviewers use to probe whether you understand
the JVM memory model.

**When to use it:**

Awareness of this rule directly drives API design decisions:
- Return a new modified copy from methods (functional style) to
  avoid caller surprises
- Accept defensive copies of mutable parameters in constructors
- Use `final` parameters to signal immutability intent (though
  final only prevents reassignment, not mutation)

**When NOT to use it:**

When you need output parameters (returning multiple values from
a method), use a dedicated return type (record, pair, list)
rather than hoping to use the reference mutation as a return
mechanism.

**First-principles derivation:**

Any runtime needs a calling convention. Three options: pass by
value (copies), pass by reference (aliased variable), or pass
by pointer (copy of the address). Java chose to pass everything
by value. For objects, the "value" is the heap address (what Java
calls a reference). This gives deterministic caller semantics
(method cannot reseat caller's variable) while still enabling
mutation through shared references.

---

### 💻 Code Example

**Example 1: The classic misconception - can a method swap two variables?**

```java
// BAD assumption: Java passes objects by reference, so swap works
void swap(StringBuilder a, StringBuilder b) {
    StringBuilder temp = a;
    a = b;           // reassigns LOCAL copy of reference
    b = temp;        // reassigns LOCAL copy of reference
    // Caller's references are unchanged
}

StringBuilder x = new StringBuilder("X");
StringBuilder y = new StringBuilder("Y");
swap(x, y);
System.out.println(x);  // prints "X" - not swapped!
System.out.println(y);  // prints "Y" - not swapped!

// GOOD: To swap, use an array or wrapper (passes the container
// by reference effectively, because you mutate the container)
void swap(StringBuilder[] arr, int i, int j) {
    StringBuilder temp = arr[i];
    arr[i] = arr[j];    // mutates the shared array - visible to caller
    arr[j] = temp;
}
StringBuilder[] arr = { new StringBuilder("X"), new StringBuilder("Y") };
swap(arr, 0, 1);
System.out.println(arr[0]);  // prints "Y" - swapped!
```

> **Code walkthrough:** The swap method receives copies of the
> references to X and Y. Reassigning the local parameter variables
> only affects the method's local copies - the caller's `x` and
> `y` still point to the original objects. The array version works
> because `arr` is a copy of the reference to the array object,
> and mutating the array's elements is visible to the caller.

**Example 2: Defensive copying for API safety**

```java
// BAD: Constructor stores mutable reference - caller can mutate state
class DateRange {
    private final Date start;  // Date is mutable!
    private final Date end;

    DateRange(Date start, Date end) {
        this.start = start;  // stores original reference
        this.end = end;
    }
}

Date d = new Date();
DateRange range = new DateRange(d, d);
d.setTime(0);  // caller mutates Date - range.start also changes!

// GOOD: Defensive copy in constructor
class DateRangeSafe {
    private final Date start;
    private final Date end;

    DateRangeSafe(Date start, Date end) {
        this.start = new Date(start.getTime());  // defensive copy
        this.end   = new Date(end.getTime());
    }

    Date getStart() {
        return new Date(start.getTime());  // defensive copy on read too
    }
}
```

> **Code walkthrough:** Without defensive copies, `DateRange` breaks
> its immutability guarantee because the caller retains a reference
> to the same mutable `Date` object. Defensive copies in the
> constructor and getter break this aliasing - any mutation by the
> caller only affects their own copy. This pattern is why Effective
> Java's Item 50 ("Make defensive copies when needed") is
> interview-standard knowledge.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Java is always pass-by-value. For primitives, the value is
> copied. For objects, a copy of the reference (memory address)
> is passed. This means the method can mutate the object the
> reference points to, but cannot make the caller's variable
> point to a different object.

*Push deeper:* Explain what defensive copying is and when it
is needed.

---

**Senior / Staff (5+ years):**

> The pass-by-value semantic drives how I design APIs. Mutable
> objects passed to constructors need defensive copies, or the
> caller can break invariants through the shared reference. This
> comes up constantly with Date, arrays, and custom mutable
> collections. The modern answer is to use immutable types
> (records, `List.of()`, `Instant` instead of `Date`) to make
> the aliasing question irrelevant - if the object cannot be
> mutated, sharing the reference is safe.

*Push deeper:* Discuss how value types (Project Valhalla) would
change this - value types would always be copied, eliminating
aliasing for value semantics without requiring defensive copies.

---

### ❓ Questions You Will Be Asked

#### Definition

- "Is Java pass-by-value or pass-by-reference?"
- "What happens when you pass an object to a method?"

🗣️ "Java is strictly pass-by-value. When you pass an object,
you pass a copy of the reference - the value of the pointer to
that object. The method can use the reference to mutate the object's
state, and those mutations are visible to the caller. But the method
cannot make the caller's variable point to a different object.
That is the key distinction: mutation is shared, reassignment is local."

#### Mechanism

- "Why can't a swap method work in Java?"

🗣️ "A swap method receives copies of the two references. When it
reassigns the local parameters, it only changes the local copies
of those pointers. The caller's variables still point to the
original objects. To actually swap from a method's perspective,
you would need to pass a mutable container - like an array or
a wrapper object - so the method can mutate the container's
contents, which are visible to the caller."

#### Comparison

- "How does Java's model differ from C++'s pass-by-reference?"

🗣️ "In C++, passing by reference `(Type& param)` creates a true
alias - the parameter IS the same variable as the caller's
argument. Any assignment to the parameter changes the caller's
variable. In Java, there is no equivalent; you always get a copy.
The closest Java equivalent to C++ pass-by-reference semantics
is to pass a single-element array or a mutable wrapper - the method
mutates the container, and the caller sees the change through
the shared container reference."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Reference vs object, reassignment vs mutation. |
| Hiring Manager   | Defensive copying - practical API safety. |
| Bar Raiser       | Valhalla value types, aliasing in concurrent code. |
| Peer Engineer    | "The swap question trips up seniors too - the subtle part is..." |

---

---

# Access Modifiers

**Interview Weight:** medium - Foundational knowledge tested
at junior level. At senior level, interviewers pivot to design
implications: when does package-private make sense, when should
you widen or narrow visibility?

---

### 🎯 Model Answer

**30 seconds:**

> Java has four access levels: public (anyone), protected (same
> package + subclasses), package-private/default (same package only,
> no keyword), and private (same class only). The principle is
> least-privilege: expose only what clients genuinely need. Private
> by default, widen only when necessary.

**3 minutes (Senior):**

> Access modifiers are the primary API surface control mechanism
> in Java. The rule I follow: start with private, widen only when
> you have a concrete reason. Package-private is the most
> under-appreciated level - it allows collaboration between classes
> in a package while hiding implementation from external code,
> without the coupling of inheritance (protected).
>
> Protected is often a design smell: it couples the superclass to
> subclasses in ways that are hard to change. If you make a field
> protected, every subclass can see it, and you cannot easily
> refactor it without checking all subclasses. Use protected for
> template method patterns where the extension point is deliberate.
>
> In practice, the module system (Java 9+) adds a layer above this:
> even public types in a module are not visible outside the module
> unless explicitly exported. This gives you public-within-module
> semantics, which maps to the package-private concept but at a
> coarser granularity.

**Framework:** PRIVATE (class) → PACKAGE-PRIVATE (package) →
PROTECTED (package + subclasses) → PUBLIC (everyone) →
DESIGN PRINCIPLE (minimal exposure)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Java access modifiers
- the four visibility levels."

**(2) First principles:** "Encapsulation requires restricting
who can see internal state. You need levels from most to least
restrictive to match different sharing needs."

**(3) Bridge:** "This is universal to OOP - C++ has private,
protected, public. Java adds the implicit package-private level
that has no keyword."

---

### 📘 Concept Explanation

**What it is:**

Access modifiers control visibility of classes, methods, fields,
and constructors. Four levels:

| Modifier | Class | Package | Subclass | World |
|----------|-------|---------|----------|-------|
| `private` | yes | no | no | no |
| (none) | yes | yes | no | no |
| `protected` | yes | yes | yes | no |
| `public` | yes | yes | yes | yes |

**The problem it solves:**

Without visibility control, any code can access any field,
breaking encapsulation and creating tight coupling. Access modifiers
enforce the API/implementation boundary: the public interface is
the contract; the private implementation can be changed freely.

**How it works:**

```java
public class BankAccount {
    private double balance;   // private: hidden from all outside code
    private List<Tx> history; // private: internal implementation detail

    // package-private: visible to test classes in same package
    // without making it part of the public API
    double getBalanceRaw() { return balance; }

    protected void onWithdraw(double amount) {
        // protected: subclass extension point (template method)
        // Called by withdraw() to allow subclass customization
    }

    public void deposit(double amount) {  // public: stable API
        if (amount <= 0) throw new IllegalArgumentException();
        balance += amount;
        onWithdraw(amount);  // can be overridden
    }
}
```

**The key insight:**

Package-private is a first-class design tool, not just a
"forgotten to add public." It enables "friendly" classes within
a package to collaborate on implementation details without those
details leaking into the public API. This is the Java equivalent
of C++'s `friend` - but at package granularity.

**When to use it:**

- `private`: all fields (always), helper methods
- package-private: inter-class collaboration within a package,
  or test access (white-box tests in the same package)
- `protected`: template method extension points (deliberate, not default)
- `public`: API surface only

**When NOT to use it:**

- Never make fields public (breaks encapsulation)
- Avoid protected fields (coupling to subclasses)
- Do not use public for implementation helpers (use package-private)

**First-principles derivation:**

Any module system needs to express: "visible to self," "visible
to allies," "visible to children," and "visible to all." Java's
four levels map exactly to these four scopes. The absence of a
keyword means package-private, not "forgot to add public" -
this is intentional API design guidance built into the language.

---

### 💻 Code Example

**Example 1: Access modifier design for a domain class**

```java
// BAD: Too much exposure - internal state is public
public class Order {
    public List<Item> items;  // Anyone can add/remove items directly
    public BigDecimal total;  // Anyone can set the total without validation

    public void recalculate() {
        total = items.stream()
                     .map(Item::getPrice)
                     .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
// External code can: order.items.clear(); order.total = BigDecimal.ZERO;
// This bypasses recalculate() and breaks invariants

// GOOD: Minimal exposure - invariants protected
public class OrderSafe {
    private final List<Item> items = new ArrayList<>();
    private BigDecimal total = BigDecimal.ZERO;

    public void addItem(Item item) {     // controlled mutation
        Objects.requireNonNull(item);
        items.add(item);
        total = total.add(item.getPrice());  // invariant maintained
    }

    public List<Item> getItems() {       // defensive copy
        return List.copyOf(items);
    }

    public BigDecimal getTotal() { return total; }
}
```

> **Code walkthrough:** The BAD pattern exposes mutable state
> directly, allowing callers to corrupt the `total` invariant.
> The GOOD pattern uses private state and controlled mutation points
> (`addItem`) that maintain the invariant atomically. `getItems()`
> returns an unmodifiable copy so callers cannot mutate the internal
> list. This is the standard encapsulation pattern.

**Example 2: Package-private for test access**

```java
// Production class in com.example.billing
package com.example.billing;

public class InvoiceCalculator {
    // Package-private: not part of public API, but accessible
    // to test classes in the same package
    BigDecimal applyDiscount(BigDecimal price, int quantity) {
        if (quantity >= 10) return price.multiply(new BigDecimal("0.9"));
        return price;
    }

    public Invoice calculate(Order order) {
        // ... uses applyDiscount internally
    }
}

// Test class in same package (src/test/java/com/example/billing/)
package com.example.billing;  // same package - can access package-private

class InvoiceCalculatorTest {
    @Test
    void discountApplied() {
        var calc = new InvoiceCalculator();
        // Can access applyDiscount() directly for white-box testing
        assertEquals(
            new BigDecimal("90.0"),
            calc.applyDiscount(new BigDecimal("100"), 10)
        );
    }
}
```

> **Code walkthrough:** Placing the test in the same package as
> production code (a common Maven/Gradle convention) gives it
> access to package-private members without making them part of
> the public API. This is the idiomatic Java approach to white-box
> testing - the alternative (making things protected or public just
> for tests) unnecessarily widens the API.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Java has four access levels. Private: only within the class.
> Default (no modifier): within the package. Protected: package
> plus subclasses. Public: everywhere. The rule is least privilege:
> make things as private as possible and only widen when there is
> a reason.

*Push deeper:* Explain the package-private use case for test
access.

---

**Senior / Staff (5+ years):**

> I use package-private deliberately as a design tool. It allows
> classes in a package to collaborate on internals without polluting
> the public API. For example, parser and lexer in a package can
> share internal AST structures package-privately. Protected is
> a code smell unless you are deliberately designing for inheritance
> (template method pattern). With Java 9+ modules, I can now also
> express public-within-module semantics using module exports,
> which is a coarser but more explicit alternative.

*Push deeper:* Discuss the module system's `exports to` directive
and how it creates "module-private" public APIs.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What are Java's access modifiers?"
- "What is the difference between protected and package-private?"

🗣️ "Java has four access levels. Private: only within the declaring
class. Package-private (no keyword): any class in the same package.
Protected: same package plus subclasses regardless of package.
Public: any class in any package. The critical difference between
protected and package-private: protected also includes subclasses
across packages; package-private is strictly package-scoped.
In practice, package-private is underused - it is the right
default for implementation helpers that need inter-class access
within a package."

#### Mechanism

- "Why should fields almost always be private?"

🗣️ "Private fields allow you to change the internal representation
without breaking callers. If `balance` is public, any code that
reads `account.balance` breaks when you rename it or change its
type. If it is private with a getter, you can change the
representation while keeping the getter's return type stable.
This is the core value of encapsulation: decouple the API from
the implementation."

#### Comparison

- "When would you use protected over package-private?"

🗣️ "Protected makes sense when you are designing for deliberate
inheritance - you want subclasses to be able to override or access
a method, and those subclasses might live in different packages.
The template method pattern is the canonical example: a base class
provides an algorithm skeleton and exposes protected hooks for
subclass customization. Outside of template method and similar
patterns, I prefer package-private because it avoids the coupling
to subclasses that protected introduces."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Exact visibility rules per modifier. |
| Hiring Manager   | Encapsulation value - maintainability impact. |
| Bar Raiser       | Module system's `exports to`, protected as design smell. |
| Peer Engineer    | "Package-private is the most underused visibility level..." |

---

---

# Static vs Instance Context

**Interview Weight:** high - A foundational Java question that
often reveals whether someone truly understands the object model.
Common at junior level; extends to complex questions about
classloading at senior level.

---

### 🎯 Model Answer

**30 seconds:**

> Static members (fields and methods) belong to the class itself -
> shared across all instances, accessible without creating an object.
> Instance members belong to a specific object - each instance has
> its own copy of instance fields, and instance methods operate on
> `this`. The fundamental rule: static methods cannot access instance
> members directly, because there is no `this` reference in a static
> context.

**3 minutes (Senior):**

> Static fields are initialized once when the class is loaded by
> the classloader. Instance fields are initialized per constructor
> call. This means static fields are shared state - a single
> mutation is visible to all instances and all threads. In concurrent
> systems, mutable static state is a class of bugs.
>
> Static methods are useful for utility operations (Math.sqrt),
> factory methods (Integer.valueOf, List.of), and operations that
> are logically associated with the class but not with any instance.
> Overusing static methods is a sign of procedural code in an OOP
> language - if you cannot inject or mock a static method in a test,
> that is a design smell.
>
> The interesting corner case: a static initializer block runs once
> when the class is loaded. If it throws an exception, the class
> is marked as failed and all subsequent attempts to use it throw
> ExceptionInInitializerError - a production failure mode that is
> hard to diagnose because the error is thrown at every use point,
> not just the first initialization.

**Framework:** STATIC (class-level, shared, no `this`) →
INSTANCE (object-level, per-instance, `this` available) →
DESIGN (factory, utility, singleton) →
TRAPS (mutable static state, concurrent access, init errors)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the difference between
static and instance methods and fields."

**(2) First principles:** "A class serves two roles: a blueprint
for instances, and a namespace for class-level operations. Static
members live in the namespace; instance members live in the
blueprint."

**(3) Bridge:** "In Python, this maps to class methods (decorated
with @classmethod) and instance methods. The `self` / `this`
parameter is the difference."

---

### 📘 Concept Explanation

**What it is:**

Static members (`static` keyword) are associated with the class
itself. They are allocated once when the class is loaded, shared
by all instances, and accessible via `ClassName.member`.
Instance members (no `static`) are associated with a specific
object instance - each new object gets its own copies of instance
fields.

**The problem it solves:**

Some state and behavior is logically class-level (the count of
all instances, a factory method, a mathematical constant).
Instance-level members for these would waste memory (every
instance storing the same constant) and make the semantics unclear.
Static provides the class-level namespace.

**How it works:**

```java
class Counter {
    private static int totalCreated = 0;   // class-level, shared
    private int id;                         // per-instance

    public Counter() {
        totalCreated++;         // OK: static field from anywhere
        this.id = totalCreated; // OK: instance field from constructor
    }

    public static int getTotal() {  // static method
        // can access totalCreated (static) directly
        // CANNOT access this.id - no 'this' in static context!
        return totalCreated;
    }

    public int getId() {   // instance method - has 'this'
        return this.id;    // OK: 'this' is available
        // getTotal() is also accessible here
    }
}
```

**The key insight:**

Calling an instance method on a null reference throws NullPointerException
because `this` would be null. Static methods have no `this` - you
cannot throw NPE by calling a static method via a null reference
(though Java style-checkers warn against `nullRef.staticMethod()`
because it is misleading).

**When to use it:**

- Static: utility methods (Math, Collections), factory methods
  (valueOf, of), constants (static final), singleton instance,
  counter across all instances
- Instance: any behavior that depends on object state, methods
  that belong to the lifecycle of a specific object

**When NOT to use it:**

- Avoid mutable static fields in production code - they are
  shared across threads and across test cases (thread-safety and
  test isolation problems)
- Avoid static methods when you need to mock the behavior in
  tests - static methods cannot be overridden and are hard to
  intercept without bytecode manipulation (PowerMock)
- Avoid static utility classes as a dumping ground (they become
  procedural code and cannot be injected)

**First-principles derivation:**

Every OOP language needs both class-level and instance-level
operations. Without static: you need an instance to call a factory
method (circular). Without instance: every object would share the
same state (no encapsulation). The distinction is a fundamental
requirement of the OOP memory model.

---

### 💻 Code Example

**Example 1: Static factory vs constructor (design pattern)**

```java
// BAD: Constructor exposes implementation type, cannot return cached
public class Connection {
    public Connection(String url) { ... }
}
// Caller: new Connection(url) - always creates a new object,
// cannot return cached, cannot return subclass transparently

// GOOD: Static factory method - flexible and cache-aware
public class Connection {
    private static final Map<String, Connection> POOL = new HashMap<>();

    private Connection(String url) { ... }  // private constructor

    // Static factory: can return cached instance
    public static Connection of(String url) {
        return POOL.computeIfAbsent(url, Connection::new);
    }

    // Can return a subclass without changing the return type
    public static Connection ofReadOnly(String url) {
        return new ReadOnlyConnection(url);  // ReadOnlyConnection extends Connection
    }
}
// Caller: Connection.of(url) - readable, can be cached
```

> **Code walkthrough:** Static factory methods (Item 1 in Effective
> Java) provide three advantages over constructors: they have names
> (expressive), they can return cached instances, and they can return
> subtypes. The private constructor forces callers to use the factory,
> giving the class full control over instance creation. This pattern
> underlies `Integer.valueOf`, `List.of`, `Optional.of`.

**Example 2: Mutable static state causing test pollution**

```java
// BAD: Mutable static field causes test isolation failure
public class RequestCounter {
    private static int count = 0;  // mutable static - shared across ALL tests

    public static void increment() { count++; }
    public static int getCount() { return count; }
}

@Test void testA() {
    RequestCounter.increment();
    assertEquals(1, RequestCounter.getCount());  // passes
}
@Test void testB() {
    // Runs after testA (or in parallel) - count is already 1
    RequestCounter.increment();
    assertEquals(1, RequestCounter.getCount());  // FAILS - count is 2!
}

// GOOD: Instance-level state, injected per test
public class RequestCounter {
    private int count = 0;  // instance field - isolated per instance
    public void increment() { count++; }
    public int getCount() { return count; }
}

@Test void testA() {
    var counter = new RequestCounter();  // fresh instance per test
    counter.increment();
    assertEquals(1, counter.getCount());  // always passes
}
```

> **Code walkthrough:** The BAD pattern uses mutable static state
> that bleeds between test runs. Test A mutates the counter; test B
> starts from a contaminated state. This is a production-quality
> diagnosis: if your tests pass individually but fail in suite, check
> for static mutable fields. The GOOD pattern uses instance state
> so each test gets a fresh, isolated counter.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Static members belong to the class, not to any instance.
> Instance members belong to a specific object. Static methods
> cannot use `this` because there is no instance context. Use
> static for constants, utility methods, and factory methods.
> Use instance for anything that depends on object state.

*Push deeper:* Static initializers, when they run, and the
ExceptionInInitializerError failure mode.

---

**Senior / Staff (5+ years):**

> I treat mutable static state as a design smell requiring
> justification. Static fields are globally shared - they break
> test isolation and require synchronization in concurrent code.
> The acceptable uses: static final constants (immutable), static
> loggers (thread-safe by design), and carefully controlled
> singletons. For everything else, I prefer instance state managed
> through dependency injection - this gives testability and
> lifecycle control that static state cannot provide.

*Push deeper:* Class loading and static initialization timing -
when a static field is initialized, what guarantees the JVM makes
about static initialization visibility across threads, and the
class initialization circularity problem.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between static and instance methods?"
- "Can a static method access instance variables?"

🗣️ "Static methods belong to the class and have no `this` reference.
Instance methods belong to a specific object and have `this`.
A static method cannot directly access instance variables because
there is no object - there is no `this.field` to reference. It can
access instance state only if passed an object reference as a
parameter. This is why utility classes like Collections and Arrays
work: they receive the target object as a method parameter."

#### Mechanism

- "When does a static initializer run?"

🗣️ "A static initializer block (or static field initializer)
runs when the class is first loaded by the classloader - which
happens on the first reference to the class: creating an instance,
calling a static method, or accessing a static field. It runs
exactly once per classloader. If the static initializer throws
an exception, the class is permanently failed: every subsequent
attempt to use the class throws ExceptionInInitializerError.
This is a non-recoverable failure without restarting the JVM."

#### Comparison

- "When would you use a static method vs an instance method?"

🗣️ "I use static methods for three cases: utility operations
that take all their input as parameters and have no state
dependency (Math.sqrt, Collections.sort), factory methods where
I want naming and caching control, and operations on a type that
make no sense for a specific instance (Integer.parseInt). I use
instance methods for anything that depends on the object's state.
The practical test: if the method uses `this` to access fields,
it should be an instance method. If it does not, it is a candidate
for static - but think about whether testability and mockability
matter before making that choice."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | No `this` in static, static initializer timing. |
| Hiring Manager   | Test isolation impact, design implications. |
| Bar Raiser       | Classloader lifecycle, thread safety of static init. |
| Peer Engineer    | "Mutable static state is the silent killer in test suites..." |

---

---

# Java Control Flow

**Interview Weight:** medium - Basic at junior level but extends
to nuanced questions about labeled breaks, exception control flow,
and performance of switch patterns at senior level.

---

### 🎯 Model Answer

**30 seconds:**

> Java control flow includes: if/else (conditionals), switch
> (multi-way branch), for/while/do-while loops, and break/continue
> for loop control. Since Java 14, switch expressions can return
> values with arrow syntax and `yield`. For/each (enhanced for
> loop) iterates any Iterable. Key control flow in exceptions:
> try/catch/finally and try-with-resources (Java 7+).

**3 minutes (Senior):**

> Beyond basics, the interview-level nuances: switch has traditionally
> had fall-through semantics (break required to exit each case)
> which is a source of bugs. Switch expressions (Java 14+) use
> arrow syntax that is always exhaustive and never falls through.
> For enums and sealed classes, switch expressions become type-safe
> exhaustiveness checks at compile time.
>
> For loop internals: the enhanced for loop calls `iterator()` on
> the Iterable, then `hasNext()/next()` for each element. You cannot
> remove elements from a collection in an enhanced for loop without
> getting ConcurrentModificationException - use `Iterator.remove()`
> explicitly or `removeIf()`.
>
> The `finally` block runs even when an exception is thrown, even
> when `return` is called in the try block. If `finally` itself
> has a `return`, that return overrides the return in try. This is
> a classic interview trap. In production, use try-with-resources
> rather than try/finally for resource cleanup.

**Framework:** SEQUENTIAL (top-down) → CONDITIONAL (if/switch)
→ ITERATION (for/while) → LOOP CONTROL (break/continue) →
EXCEPTION FLOW (try/catch/finally)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Java's control flow
constructs - the mechanisms for branching and looping."

**(2) First principles:** "Any Turing-complete language needs
sequential execution, conditional branching, and repetition.
Java has all three plus exception-based flow for error paths."

**(3) Bridge:** "This maps directly to structured programming -
sequence, selection (if/switch), and iteration (loops). Java
follows the same model as C, with additions like enhanced for
and switch expressions."

---

### 📘 Concept Explanation

**What it is:**

Control flow statements determine the order in which instructions
execute: branching (if/else, switch), looping (for, while,
do-while, enhanced-for), and exception handling (try/catch/finally,
try-with-resources). Java also supports labeled break and continue
for nested loop control.

**The problem it solves:**

Sequential execution alone cannot express algorithms. Branching
handles conditional logic; looping handles repetition; exception
handling handles the error path. These primitives together allow
the expression of any computation.

**How it works:**

```java
// Classic switch: fall-through requires break
switch (day) {
    case MONDAY:
    case TUESDAY:
        System.out.println("weekday");
        break;      // required - without this, falls to WEDNESDAY case
    case WEDNESDAY:
        System.out.println("hump day");
        break;
    default:
        System.out.println("other");
}

// Switch expression (Java 14+): exhaustive, no fall-through, returns value
String label = switch (day) {
    case MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY -> "weekday";
    case SATURDAY, SUNDAY -> "weekend";
    // No default needed - Day enum is exhaustive
};

// Enhanced for loop - uses Iterator internally
for (String item : list) {
    // list.remove(item) here throws ConcurrentModificationException!
}
// CORRECT: use removeIf for structural modification
list.removeIf(item -> item.startsWith("A"));
```

**The key insight:**

`finally` always runs, even after `return`. If you `return` from
inside a try block, the `finally` block executes before the method
actually returns. If `finally` has its own `return` statement, it
silently suppresses both the original return value and any
exception from the try/catch block. This is a subtle source of
lost exceptions in production code.

**When to use it:**

- Switch expression over classic switch for multi-way branches:
  it is exhaustive (compiler error if a case is missed) and
  eliminates fall-through bugs
- Enhanced for loop for iteration when you do not need the index
- try-with-resources for any AutoCloseable resource (streams,
  connections, files)
- Iterator.remove() or Collection.removeIf() when removing during
  iteration

**When NOT to use it:**

- Labeled breaks in deeply nested loops signal that the code
  should be extracted to a method with a regular return
- Classic switch with fall-through is a maintenance hazard in
  most cases
- Avoid `do-while` unless the loop must execute at least once
  and this condition is a core invariant

**First-principles derivation:**

The minimal computation model (Turing machine) needs conditional
branching and repetition. Java implements these through structured
control flow (no gotos) to make code analyzable and maintainable.
Switch expressions add compile-time exhaustiveness to avoid the
"forgot a case" class of bugs that classic switch with fall-through
enables.

---

### 💻 Code Example

**Example 1: Switch expression for pattern matching (Java 21)**

```java
// BAD: Classic switch - fall-through trap and no exhaustiveness
String format(Object obj) {
    switch (obj.getClass().getSimpleName()) {
        case "Integer": return "int: " + obj;
        case "String":  return "str: " + obj;
        // Forgot Double - silently falls through to default
        default: return "unknown";
    }
}

// GOOD: Switch expression with pattern matching (Java 21+)
// Compiler enforces exhaustiveness for sealed types
String format(Object obj) {
    return switch (obj) {
        case Integer i -> "int: " + i;
        case String s  -> "str: " + s;
        case Double d  -> "dbl: " + d;
        case null      -> "null";      // null handled explicitly
        default        -> "unknown: " + obj.getClass().getSimpleName();
    };
}
// Sealed type example - no default needed, compiler checks all cases:
sealed interface Shape permits Circle, Rectangle {}
double area(Shape s) {
    return switch (s) {
        case Circle c    -> Math.PI * c.r() * c.r();
        case Rectangle r -> r.w() * r.h();
        // No default: compiler verifies Circle and Rectangle are all cases
    };
}
```

> **Code walkthrough:** The BAD pattern uses string comparison of
> class names (fragile and error-prone) with classic switch. The
> GOOD pattern uses Java 21 pattern matching for switch: type
> patterns bind directly, null is handled explicitly (avoiding NPE),
> and sealed types get compile-time exhaustiveness checks. The
> `area` example shows zero-default switch for sealed classes -
> adding a new Shape subclass will cause a compile error, forcing
> the developer to handle the new case.

**Example 2: finally trap and try-with-resources**

```java
// BAD: finally return silently discards exception
int dangerous() {
    try {
        throw new RuntimeException("important error");
    } finally {
        return 42;  // SWALLOWS the exception! Returns 42, exception lost.
    }
}

// BAD: Manual try/finally for resource cleanup
InputStream in = new FileInputStream("file.txt");
try {
    process(in);
} finally {
    in.close();  // If process() throws AND close() throws,
                 // the process() exception is suppressed
}

// GOOD: try-with-resources - resources closed automatically
// Suppressed exceptions are attached, not lost
try (InputStream in = new FileInputStream("file.txt")) {
    process(in);
}
// in.close() is called here; if it throws, it is added as suppressed
// exception on the primary exception - nothing is lost
```

> **Code walkthrough:** `return` in `finally` is a trap that
> silently discards any exception or return value from the `try`
> block. The try-with-resources pattern (Java 7+) eliminates manual
> `finally` for closeable resources. If both `process()` and
> `in.close()` throw, the primary exception is the one from
> `process()`; the close exception is attached as a suppressed
> exception accessible via `e.getSuppressed()` - no data is lost.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Java control flow includes if/else, switch, and loops (for,
> while, do-while, enhanced for). Switch expressions (Java 14+)
> use arrow syntax, do not fall through, and can return values.
> try/catch/finally handles exceptions; try-with-resources
> automatically closes resources.

*Push deeper:* The ConcurrentModificationException when removing
from a collection in an enhanced for loop, and how to fix it.

---

**Senior / Staff (5+ years):**

> I care about three non-obvious control flow behaviors in
> production: (1) `finally` return silently discards exceptions -
> never return from finally. (2) ConcurrentModificationException
> from structural modification during enhanced-for - use removeIf
> or stream + filter to collect. (3) Switch expression exhaustiveness
> for sealed types is a powerful design tool: adding a new variant
> to a sealed hierarchy becomes a compile error until all switch
> expressions that pattern-match on it are updated - this is
> refactoring safety at compile time.

*Push deeper:* Enhanced switch with guards (when clauses in
Java 21), labeled break/continue behavior, and why `do-while`
is almost always the wrong choice.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between break and continue?"
- "What is fall-through in a switch statement?"

🗣️ "Break exits the current loop or switch. Continue skips the
rest of the current iteration and goes to the next one. Fall-through
in a classic switch means execution continues into the next case
if there is no break. This is intentional in some cases (multiple
cases sharing the same body) but is a source of bugs when
forgotten. Switch expressions (Java 14+) eliminate fall-through
entirely - each arrow case is independent."

#### Mechanism

- "What happens if you throw an exception inside a try block
  that has a finally clause?"

🗣️ "The finally block always executes, even when an exception is
thrown in the try block. After the finally block completes, the
exception propagates to the caller. If the finally block itself
throws an exception, the original exception is suppressed -
this is why manual try/finally for multiple resources is risky.
Try-with-resources handles this: if both the body and close()
throw, the body exception propagates and the close exception is
added as a suppressed exception."

#### Comparison

- "Classic switch vs switch expression - when to use each?"

🗣️ "Switch expressions are strictly superior for almost all cases:
they eliminate fall-through bugs, are exhaustive for enums and
sealed types (compile error if a case is missing), and can return
values cleanly with yield or arrow syntax. I use classic switch
only when maintaining pre-Java 14 code or when intentional
fall-through is needed for a specific reason. In new code, switch
expressions are the default."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Switch exhaustiveness, finally semantics, ConcurrentModException. |
| Hiring Manager   | Practical impact of try-with-resources on resource leaks. |
| Bar Raiser       | Pattern matching guards, labeled break/continue scope. |
| Peer Engineer    | "The finally return trap caught us once in a database layer..." |
