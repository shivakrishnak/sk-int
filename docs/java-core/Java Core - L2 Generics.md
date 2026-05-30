---
layout: default
title: "Java Core - L2 Generics"
parent: "Java Core"
grand_parent: "SK Interview"
nav_order: 6
permalink: /java-core/l2-generics/
render_with_liquid: false
---

# Java Core - L2 Generics

## Generics and Type Erasure

### 🎯 Model Answer

**30 seconds:**
> Generics enable type-safe containers and algorithms without casting.
> `List<String>` guarantees every element is a String - no `ClassCastException`
> at runtime. Java generics use TYPE ERASURE: the type parameter is
> removed by the compiler and not present in bytecode. At runtime,
> `List<String>` and `List<Integer>` are both just `List`. This means:
> no `new T()`, no `instanceof List<String>`, no `T.class`. The compiler
> inserts necessary casts and checks before erasure. The trade-off:
> backward compatibility (old and new code interoperate) at the cost of
> limited runtime type information.

**3 minutes (Senior):**
> Type erasure trade-offs: you CANNOT do `new T[]` (use cast of
> `Object[]`), `new T()` (use a factory or `Class<T>`), or
> `instanceof T` (use `Class<T>.isInstance()`). You CAN use `T` in
> method signatures and return types (useful at compile time). Reifiable
> types are those whose type info is preserved at runtime: raw types,
> non-parameterized types, unbounded wildcards (`?`). Parameterized types
> are not reifiable.
>
> Raw types (e.g., `List` without parameters): unsafe, discouraged,
> exist for backward compatibility with pre-generics code. Mixing raw
> and parameterized types produces "unchecked" warnings.
>
> The `@SuppressWarnings("unchecked")` annotation suppresses the warning
> when you know the cast is safe (e.g., in generic container internals).
> Should be used sparingly and documented.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Generics and type erasure - let me cover what generics
provide (compile-time type safety), how type erasure works, its
limitations, and common generic patterns."

**(2) First principles:** "From first principles: before generics,
`ArrayList` held `Object` and every read required a cast that could fail
at runtime. Generics move that failure to compile time, making programs
safer. Type erasure was chosen for backward compatibility - the JVM
doesn't need to know about generics."

**(3) Bridge:** "Generics are like clothing size labels that the factory
(compiler) uses to sort and verify, but the label is removed before
the product ships (runtime). The product (bytecode) itself has no label,
but everything was checked before the label was removed."

---

### 📘 Concept Explanation

**What generics provide:**
```java
// Without generics (pre-Java 5):
List names = new ArrayList();     // holds Object
names.add("Alice");
names.add(42);                    // no compile error!
String name = (String) names.get(1); // ClassCastException at runtime!

// With generics:
List<String> names = new ArrayList<>();
names.add("Alice");
names.add(42);                    // COMPILE ERROR: int not String!
String name = names.get(0);       // no cast needed, guaranteed String
```

**Type erasure - what the compiler does:**
```java
// Source (with generics):
List<String> list = new ArrayList<>();
list.add("hello");
String s = list.get(0);

// After erasure (conceptual bytecode equivalent):
List list = new ArrayList();       // type parameter removed
list.add("hello");
String s = (String) list.get(0);  // compiler inserts cast
```

**Type erasure limitations:**
```java
// CANNOT: create generic array
T[] array = new T[10];   // compile error
// Workaround:
T[] array = (T[]) new Object[10]; // unchecked cast

// CANNOT: check type at runtime
if (list instanceof List<String>) { } // compile error: erasure!
// Workaround:
if (list instanceof List) { }         // just check raw type

// CANNOT: create instance of T
T instance = new T();    // compile error
// Workaround:
T instance = clazz.getConstructor().newInstance(); // with Class<T>

// CANNOT: catch generic exception
try { } catch (T e) { }  // compile error

// CAN: use T in signatures (checked at compile time)
<T extends Comparable<T>> T max(List<T> list) { ... }
```

---

### 💻 Code Example

> **Code walkthrough:** The generic stack example shows the typical
> unchecked cast pattern that's safe in practice. The array `(T[]) new
> Object[capacity]` is flagged by the compiler but correct: elements
> are only added through the typed `push(T)` method, so all elements
> are actually of type T. The `@SuppressWarnings("unchecked")` documents
> this invariant. The generic utility method example shows bounded type
> parameters (`T extends Comparable<T>`).

```java
// Generic container with bounded type:
class TypeSafeRegistry<T> {
    private final Class<T> type;
    private final List<T> items = new ArrayList<>();

    TypeSafeRegistry(Class<T> type) { this.type = type; }

    void register(Object item) {
        if (!type.isInstance(item)) { // runtime type check via Class<T>
            throw new IllegalArgumentException(
                "Expected " + type.getName() + ", got " +
                item.getClass().getName());
        }
        items.add(type.cast(item)); // safe cast via Class<T>
    }

    List<T> getAll() { return Collections.unmodifiableList(items); }
}

// Generic bounded method:
public <T extends Comparable<T>> T max(List<T> items) {
    if (items.isEmpty()) throw new NoSuchElementException();
    T result = items.get(0);
    for (T item : items) {
        if (item.compareTo(result) > 0) result = item;
    }
    return result;
}
// Caller:
String longest = max(List.of("apple", "banana", "fig")); // "fig"? no - "banana"
int biggest = max(List.of(3, 1, 4, 1, 5, 9)); // 9

// Heap-based generic stack with unchecked array:
class Stack<T> {
    private final Object[] elements;  // can't do T[]
    private int size;
    @SuppressWarnings("unchecked")
    Stack(int capacity) {
        elements = new Object[capacity]; // Object array, typed on read
    }
    void push(T item) {
        elements[size++] = item; // safe: T goes in
    }
    @SuppressWarnings("unchecked")
    T pop() {
        if (size == 0) throw new EmptyStackException();
        T item = (T) elements[--size]; // safe: only T was put in
        elements[size] = null;          // prevent memory leak
        return item;
    }
}
```

> **Code walkthrough:** The `elements[size] = null` after pop is an
> important detail: if you hold a reference to the Stack but all logical
> items are popped, the backing array still holds references to the
> popped objects, preventing GC. Setting to null allows GC to reclaim
> the objects. This "null out obsolete references" pattern (Effective
> Java, Item 7) prevents subtle memory leaks in containers that own
> their elements.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Generics provide compile-time type safety - you know what type a
> collection holds without casting. Type erasure removes type parameters
> at runtime - both `List<String>` and `List<Integer>` become `List` in
> bytecode. Can't use generics for `instanceof`, `new T()`, or array
> creation. Use `Class<T>` token when you need runtime type information
> in generic code.

---

**Senior / Staff (5+ years):**
> Type erasure was chosen for Java 5 backward compatibility - old
> non-generic code interoperates with new generic code. The cost: no
> runtime type information for parameterized types. Project Valhalla
> (future Java) will introduce reified generics for primitive types
> (`List<int>`), solving the boxing problem. For framework code that
> needs runtime type info: `TypeToken` (Guava) or `ParameterizedTypeReference`
> (Spring) capture the generic type at creation time by subclassing
> (the actual type info is preserved in the class hierarchy metadata).
> This is the "super type token" pattern from Neal Gafter's article.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Generics provide runtime type safety."**
Type erasure means no runtime generic type checks. A cast from raw
`List` to `List<String>` generates only an unchecked warning, not
an error. The actual ClassCastException occurs only when you read an
element and try to use it as the wrong type. Use heap pollution carefully.

**Misconception 2: "`List<Object>` can hold a `List<String>` reference."**
`List<String>` is NOT a subtype of `List<Object>`. This invariance
prevents type-unsafe operations. You can add any `Object` to `List<Object>`,
so if `List<String>` were a subtype, you could add non-Strings to it.
Use `List<? extends Object>` (upper bounded wildcard) for read-only access.

---

### 🚨 Failure Modes and Diagnosis

**Failure: heap pollution - ClassCastException far from the cast.**
```java
@SuppressWarnings("unchecked")
static <T> List<T> asList(Object... items) {
    return (List<T>) Arrays.asList(items); // unchecked cast
}
List<Integer> ints = asList("not", "an", "int"); // no error here!
int x = ints.get(0); // ClassCastException here - far from cause!
```
Diagnosis: enable `-Xlint:unchecked` at compile time; all unchecked
operations generate warnings that reveal the root cause. Stack traces
from heap pollution may point to unrelated code.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Type erasure explained | 2 minutes |
| Why type erasure was chosen | 2 minutes |
| Generic array limitation | 2 minutes |
| Bounded type parameters | 2 minutes |
| Raw types dangers | 2 minutes |
| Super type token | 2-3 minutes |
| Generic method vs class | 90 seconds |
| @SuppressWarnings unchecked | 90 seconds |
| Heap pollution | 2 minutes |

---

**Q1 (Type erasure explained): Explain type erasure with a concrete example.**

A: Type erasure is the compiler process of removing type parameter information
from bytecode, replacing parameterized types with raw types and inserting
casts where needed.

```java
// Compiled source:
public <T extends Number> double sum(List<T> nums) {
    double total = 0;
    for (T n : nums) {
        total += n.doubleValue(); // T is known to extend Number
    }
    return total;
}

// After erasure (what bytecode represents):
public double sum(List nums) {  // T replaced by upper bound: Number
    double total = 0;
    for (Number n : nums) {     // cast inserted by compiler
        total += n.doubleValue();
    }
    return total;
}
// The method's erasure signature: double sum(List)
```

Consequences:
- Method overloading by generic type only is impossible:
  ```java
  void process(List<String> s) {} // erasure: process(List)
  void process(List<Integer> i) {} // COMPILE ERROR: same erasure!
  ```
- Generic type info NOT in bytecode (no `T.class`)
- `instanceof` cannot check parameterized type

*What separates good from great:* Type erasure was a deliberate compatibility
choice. Alternative: reified generics (C# style) where `List<int>` and
`List<String>` are truly different types at runtime. Java chose erasure
to allow old `List` (raw) code to interoperate with new `List<String>`
code via the raw type escape hatch. The cost: every interaction with
generic code from reflection requires extra work (TypeToken pattern).
C# .NET has reified generics and avoids boxing for value types in
`List<int>` - Project Valhalla aims to bring this to Java.

---

**Q2 (Why type erasure): Why did Java choose type erasure for generics?**

A: Java 5 (2004) needed to add generics while maintaining 100% backward
compatibility. The goal: existing pre-generics code (running on JDK 1.4)
must still run unmodified on JDK 5.

**Backward compatibility requirements:**
- Old code: `List list = new ArrayList();` (raw type)
- New code: `List<String> list = new ArrayList<>();`
- Both must compile and run on the same JVM

With type erasure: at runtime, `List<String>` is just `List`.
Old `List` methods work on new `List<String>` objects and vice versa.

```java
// Interoperability: old code using new generics code:
List<String> modern = new ArrayList<>();
modern.add("hello");

List legacy = modern; // raw type - loses type info
String s = (String) legacy.get(0); // old-style cast - works!
legacy.add(42); // compiles! unchecked warning - heap pollution
```

**Alternative (reified generics) would have:**
- Required JVM bytecode changes
- Broken binary compatibility
- New JVM class file format

Type erasure kept the JVM unchanged - only the compiler changed.

*What separates good from great:* The backward compatibility decision
was correct for Java's ecosystem scale (millions of JARs). But it created
the erasure limitations we live with today. The lesson: early design
decisions about type systems have extremely long-lasting consequences.
Kotlin (on the JVM) uses the same erasure but adds `reified` for inline
functions (which are inlined by the compiler, so the type info is
available at the call site). This is a clever escape hatch within the
JVM's limitations.

---

**Q3 (Generic array limitation): Why can't you create a generic array?
What are the workarounds?**

A: `new T[n]` is not allowed because arrays are covariant and generics
are invariant - combining them creates a type-unsafe situation.

```java
// Why it's disallowed:
// Suppose T[] was allowed:
T[] array = new T[10];  // if T = String at runtime
// But due to erasure, actual runtime type is Object[]:
Object[] arr = (Object[]) array; // legal for array covariance
arr[0] = 42;                     // no ArrayStoreException!
T elem = array[0];               // ClassCastException when reading!
// The compiler can't prevent this -> disallowed entirely

// Workaround 1: Object array + unchecked cast (ArrayList approach)
@SuppressWarnings("unchecked")
T[] arr = (T[]) new Object[n]; // flagged but safe if managed carefully

// Workaround 2: use List<T> instead of T[]
List<T> list = new ArrayList<>(n);

// Workaround 3: Class<T> token to create typed array
T[] arr = (T[]) java.lang.reflect.Array.newInstance(clazz, n);

// Workaround 4: have caller supply the array (Collection pattern)
T[] toArray(T[] arr) { ... } // caller provides typed array
```

*What separates good from great:* `ArrayList`'s internal `elementData`
is `Object[]` (never `T[]`) for exactly this reason. The `toArray(T[])`
method on `Collection` takes a typed array from the caller, who knows
the actual type at the call site: `list.toArray(new String[0])`. Passing
`new String[0]` (zero-length) is idiomatic - the actual array returned
may be larger; the argument's type is used for runtime reflection.

---

**Q4 (Bounded type parameters): What are bounded type parameters and
when do you use them?**

A: Bounded type parameters restrict what types can be used as the type argument.

**Upper bound (`extends`):**
```java
// T must be Number or a subclass:
<T extends Number> double sum(List<T> nums) {
    return nums.stream().mapToDouble(Number::doubleValue).sum();
}
// Works with List<Integer>, List<Double>, List<BigDecimal>
// Won't compile with List<String>
```

**Multiple bounds:**
```java
// T must extend Number AND implement Comparable:
<T extends Number & Comparable<T>> T max(List<T> list) {
    return list.stream().max(Comparator.naturalOrder())
               .orElseThrow();
}
// Works with Integer (extends Number, implements Comparable<Integer>)
// Won't work with AtomicInteger (extends Number, NOT Comparable)
```

**Recursive type bound (Comparable pattern):**
```java
// T compared to itself:
<T extends Comparable<T>> T max(T a, T b) {
    return a.compareTo(b) >= 0 ? a : b;
}
```

*What separates good from great:* Multiple bounds have one important
rule: at most ONE class bound (the first), rest must be interfaces.
`<T extends ArrayList & Comparable<T>>` is legal (ArrayList is a class,
Comparable is interface). `<T extends ArrayList & LinkedList>` is not
(two class bounds). This mirrors Java's single inheritance rule.
Wildcard bounds (`? extends`, `? super`) are different from type
parameter bounds and apply the PECS principle (covered in L3).

---

**Q5 (Raw types dangers): What are the risks of using raw types?**

A: Raw types (e.g., `List` without type parameter) bypass all generic
type checking. They exist for backward compatibility with pre-Java 5 code.

```java
// Raw type hazards:
List rawList = new ArrayList();   // raw type
rawList.add("hello");
rawList.add(42);                  // compiles! no type check

// Mixing raw and generic:
List<String> typed = rawList;     // unchecked assignment warning
String s = typed.get(1);         // ClassCastException at runtime!
                                  // 42 is not a String

// Raw type loses method return type info:
List rawList2 = List.of("a", "b");
String s2 = (String) rawList2.get(0); // requires cast
```

Compile with `-Xlint:unchecked` to see all raw type usage warnings.
The compiler generates warnings but still compiles (backward compat).

*What separates good from great:* Raw types should NEVER appear in new
code. The only legitimate use: `instanceof` check against raw type
(can't check parameterized type due to erasure): `if (obj instanceof List)`.
A second legitimate use: `Class` literals: `List.class` (you can't write
`List<String>.class`). In code reviews: raw types in new code are a red
flag. Enable `-Xlint:unchecked` in build config and treat raw type warnings
as errors.

---

**Q6 (Super type token): What is the super type token pattern?**

A: Generic type info is erased at runtime. But a SUBCLASS that specializes
a generic superclass preserves the type info in its class file metadata.

```java
// Problem: generic type info lost at runtime
Type t = new ArrayList<String>() {}.getClass()
    .getGenericSuperclass(); // ParameterizedType!
// Anonymous class that extends ArrayList<String> preserves
// the String type parameter in its class file!

// Super type token pattern (Guava's TypeToken / Spring's ParameterizedTypeReference):
public abstract class TypeRef<T> {
    final Type type;
    protected TypeRef() {
        ParameterizedType superType =
            (ParameterizedType) getClass().getGenericSuperclass();
        type = superType.getActualTypeArguments()[0];
    }
}
// Usage:
TypeRef<List<String>> ref = new TypeRef<List<String>>() {};
// ref.type = ParameterizedType: List<String>
// The anonymous subclass preserves List<String> in its metadata!

// Spring RestTemplate uses ParameterizedTypeReference:
ResponseEntity<List<User>> resp = restTemplate.exchange(
    "/api/users",
    HttpMethod.GET,
    null,
    new ParameterizedTypeReference<List<User>>() {}
);
List<User> users = resp.getBody(); // typed! no cast needed
```

*What separates good from great:* The super type token is a clever workaround
for type erasure. The anonymous subclass `new TypeRef<List<String>>() {}`
has its parent type `TypeRef<List<String>>` encoded in its class file
metadata. This survives erasure because it's class HIERARCHY info, not
local variable type info. Jackson's `TypeReference<T>` uses the same
trick for deserialization: `mapper.readValue(json, new TypeReference<List<User>>() {})`.

---

**Q7 (Generic method vs class): When do you use a generic method
instead of a generic class?**

A:
```java
// Generic class: type parameter applies to the entire class
class Repository<T> {
    T findById(Long id) { ... }
    void save(T entity) { ... }
    List<T> findAll() { ... }
    // T is the same for all methods - it's a class-level concept
}

// Generic method: type parameter applies only to one method
class CollectionUtils {
    // This method works with any type - no need for a generic class:
    public static <T> List<T> repeat(T item, int times) {
        return Collections.nCopies(times, item);
    }

    // Multiple unrelated type parameters:
    public static <K, V> Map<V, K> invertMap(Map<K, V> original) {
        Map<V, K> inverted = new HashMap<>();
        original.forEach((k, v) -> inverted.put(v, k));
        return inverted;
    }
}
// Usage: type inference from arguments
List<String> strings = CollectionUtils.repeat("hello", 3);
Map<Integer, String> inverted = CollectionUtils.invertMap(codeToName);
```

**Rule:** use generic class when the type parameter represents an
"owned" concept (Repository<User>). Use generic method when the type
is only relevant to that specific operation.

*What separates good from great:* Generic methods allow type INFERENCE -
the compiler deduces the type argument from the method arguments. For
static utility methods (algorithms, transformations), generic methods
are almost always preferable to wrapping in a generic class. Generic
methods can also have multiple independent type parameters (`<K, V>`)
which generic classes could handle but would require both parameters
to be specified at the class level, reducing reusability.

---

**Q8 (Suppress warnings unchecked): When is `@SuppressWarnings("unchecked")`
appropriate?**

A: `@SuppressWarnings("unchecked")` is appropriate ONLY when you can
verify the cast is safe through the program's invariants.

```java
// GOOD: documented safe cast in generic container:
class TypedCache<T> {
    private final Object[] storage;
    @SuppressWarnings("unchecked")
    T get(int index) {
        // Safe: only T is put in via put(T)
        return (T) storage[index];
    }
}

// GOOD: known framework interaction:
@SuppressWarnings("unchecked")
List<String> fromFramework = (List<String>) session.getAttribute("list");
// Documented: "list" attribute is always List<String>

// BAD: suppressing without understanding:
@SuppressWarnings("unchecked")
List<String> risky = (List<String>) getRandomObject(); // could fail!

// Rule: apply at the narrowest scope possible
// Don't suppress at class or method level - suppress just the line:
@SuppressWarnings("unchecked") // only this line
T item = (T) storage[index];  // not the whole method
```

*What separates good from great:* Every `@SuppressWarnings("unchecked")
` should have a comment explaining WHY the cast is safe. Code review
question: "Why is this cast safe?" If the author can't explain it, the
annotation should be removed and the code redesigned. In security audits,
unchecked cast suppressions are red flags - each one needs justification.
A `@SuppressWarnings` without a comment is a code smell.

---

**Q9 (Heap pollution): What is heap pollution and how does it occur?**

A: Heap pollution: a variable of a parameterized type refers to an object
that is not of that parameterized type. The compiler cannot detect this
at runtime because of type erasure.

```java
// Heap pollution via varargs:
@SafeVarargs
static <T> void addToList(List<T> list, T... items) {
    for (T item : items) list.add(item);
}

// Heap pollution via raw type:
List<String> strings = new ArrayList<>();
List rawList = strings;       // raw type alias
rawList.add(42);               // compiles! puts Integer in List<String>
strings.get(0);                // returns "?" from original items
strings.get(strings.size()-1); // ClassCastException when reading!
// The heap now contains an Integer where String is expected - POLLUTED

// Safe varargs: @SafeVarargs guarantees method doesn't store to the
// varargs array in an unsafe way
@SafeVarargs
static <T> List<T> listOf(T... items) {
    return Arrays.asList(items); // only reads, doesn't store differently
}
```

*What separates good from great:* `@SafeVarargs` is needed on generic
varargs methods because `T...` (varargs) creates a `T[]` internally -
which is actually `Object[]` after erasure. The compiler warns you that
it can't verify the method doesn't pollute the heap. `@SafeVarargs`
suppresses this warning when you guarantee: the method only reads from
the varargs array (doesn't store non-T values into it). `Collections.addAll()`,
`Arrays.asList()` are examples of `@SafeVarargs` methods in the JDK.

---

### ⚖️ Comparison Table

| Aspect | Generics | Pre-Generics (raw types) |
|---|---|---|
| Type checking | Compile-time | Runtime (cast required) |
| ClassCastException | Rare (caught at compile time) | Common |
| Readability | `List<String>` is self-documenting | `List` requires Javadoc |
| Collection API usage | No cast on get() | Explicit cast on get() |
| Runtime type info | Erased | N/A |
| Backward compat | Via raw types | Yes |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*

---

---

## Optional API

### 🎯 Model Answer

**30 seconds:**
> `Optional<T>` is a container that may or may not hold a value - a
> better alternative to returning `null` for "value may be absent."
> Created with `Optional.of(value)`, `Optional.ofNullable(value)`, or
> `Optional.empty()`. Key methods: `isPresent()`, `get()` (throws if
> empty), `orElse(default)`, `orElseGet(supplier)`, `orElseThrow()`,
> `map(fn)`, `flatMap(fn)`, `filter(predicate)`. Use Optional as a
> RETURN TYPE from methods to communicate "this may be absent." Do NOT
> use as a field, method parameter, or collection element.

**3 minutes (Senior):**
> The primary purpose: force callers to explicitly handle the "absent"
> case instead of ignoring a potential null. `Optional.of(null)` throws
> NPE (use `ofNullable` for possibly-null sources). `orElse()` evaluates
> its argument eagerly - even if the Optional is present. Use `orElseGet()`
> with a supplier for expensive defaults.
>
> Optional chains: `optional.map(String::toUpperCase).orElse("N/A")`
> is cleaner than `value != null ? value.toUpperCase() : "N/A"`.
> `flatMap`: when the mapping function itself returns an Optional:
> `user.flatMap(User::getAddress).map(Address::getCity).orElse("Unknown")`.
>
> Anti-patterns: `optional.isPresent() && optional.get()...` (defeats
> the purpose - just use `ifPresent()` or `map()`). Optional fields
> in classes (Optional is not Serializable). Optional collection
> elements (use `filter` on the stream instead).

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Optional API - let me cover its purpose, key methods,
proper use cases, and the anti-patterns to avoid."

**(2) First principles:** "From first principles: `null` is a single
pointer value that conflates 'not initialized', 'not found', 'not
applicable', and 'error'. Optional makes the 'not found' case explicit
in the type system, forcing callers to handle it."

**(3) Bridge:** "Optional is like a gift box that may or may not contain
a gift. You can peek (isPresent), open it safely (orElse - you get the
gift or a default), or chain operations on the contents (map). You don't
need to check if the box is empty before every operation - the box
handles it."

---

### 📘 Concept Explanation

**Creating Optionals:**
```java
Optional<String> full = Optional.of("value");    // never null
Optional<String> maybe = Optional.ofNullable(maybeNull); // null ok
Optional<String> empty = Optional.empty();       // definitely empty
Optional.of(null);  // throws NullPointerException!
```

**Reading from Optionals:**
```java
Optional<String> opt = Optional.of("hello");
opt.get();           // "hello" - throws NoSuchElementException if empty
opt.orElse("N/A");   // "hello" - evaluated EAGERLY
opt.orElseGet(() -> expensiveDefault()); // lazy - supplier only called if empty
opt.orElseThrow();   // "hello" - throws NoSuchElementException if empty
opt.orElseThrow(() -> new EntityNotFoundException("Not found"));

// Chain operations:
opt.filter(s -> s.length() > 3)    // Optional<String> or empty
   .map(String::toUpperCase)       // Optional<String>
   .ifPresent(System.out::println); // "HELLO"
```

---

### 💻 Code Example

> **Code walkthrough:** The BAD pattern uses `get()` without checking
> `isPresent()` - this defeats Optional's purpose and throws the same
> kind of exception as NPE. The GOOD pattern uses `orElseThrow()` which
> is explicit about the exceptional case, or `orElse()` for a default.
> The `orElse` vs `orElseGet` distinction is subtle but important for
> performance when the default is expensive to compute.

```java
// BAD: using Optional like null check (defeats purpose):
Optional<User> userOpt = userRepo.findById(id);
if (userOpt.isPresent()) {
    User user = userOpt.get(); // same pattern as null check!
    sendEmail(user);
}

// GOOD: use ifPresent or map:
userOpt.ifPresent(this::sendEmail); // clean
userOpt.ifPresentOrElse(            // Java 9
    this::sendEmail,
    () -> log.warn("User {} not found", id)
);

// BAD: orElse with expensive default:
String name = findUser(id)
    .map(User::getName)
    .orElse(expensiveDbLookup(id)); // called even if Optional is present!

// GOOD: orElseGet with supplier:
String name = findUser(id)
    .map(User::getName)
    .orElseGet(() -> expensiveDbLookup(id)); // only called if absent

// flatMap for chained Optionals:
// User has Optional<Address>, Address has Optional<String> city
Optional<User> user = findUser(id);
Optional<String> city = user
    .flatMap(User::getAddress)   // Optional<Address>
    .flatMap(Address::getCity);  // Optional<String>
String cityName = city.orElse("Unknown");
```

> **Code walkthrough:** `flatMap` is essential when the mapping function
> itself returns Optional. Without `flatMap`, you'd have `Optional<Optional<String>>`
> (double-wrapped). `flatMap` unwraps one level: it applies the function
> and flattens the result. This mirrors `Stream.flatMap` which unwraps
> streams from a stream-of-streams. The rule: if the mapping function
> returns Optional, use `flatMap`; if it returns a plain value, use `map`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Optional wraps a value that may be absent, forcing the caller to
> handle the absent case. Use `orElse()` for a default, `orElseThrow()`
> for required values, `map()` to transform the value. Anti-pattern:
> `optional.get()` without checking - use `orElseThrow()` instead.
> Use as return type only, not as field or parameter type.

---

**Senior / Staff (5+ years):**
> Optional's real value is in API design: a method returning `Optional<T>`
> communicates "this may be absent, handle it" at the type level. A
> method returning `T` (nullable) puts the burden on documentation and
> caller discipline. Spring Data repositories return `Optional<T>` from
> `findById()`. Design rule: use `Optional` for return types where
> absence is a normal, expected state (findById, getFirst). Don't use
> for "error" cases (throw exceptions for invalid states). `Optional`
> is not `Either<T, Error>` - it doesn't carry the reason for absence.
> For domain-rich error modeling: use sealed interfaces with pattern matching.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Optional eliminates all NPEs."**
Optional prevents NPE only if used correctly. `Optional.of(null)` throws
NPE. `optional.get()` on an empty Optional throws NoSuchElementException.
Mixing Optional and null (storing null in Optional.of()) bypasses all
the protection. Optional reduces NPE risk by making absence explicit
in the type, but only if you avoid the anti-patterns.

**Misconception 2: "Use Optional for all fields and parameters."**
Optional is not Serializable, adds boxing overhead (~24 bytes per Optional),
and makes null-safe handling optional's own responsibility. Use as return
type only. Fields: use `@Nullable` annotation + null checks. Parameters:
method overloading (one without the optional param) or builder pattern.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `orElse()` with expensive side effects.**
```java
// BUG: database query called even when user is found:
Optional<UserPreferences> prefs = userPrefsRepo.findById(userId)
    .orElse(userPrefsRepo.getDefaults()); // ALWAYS called!

// FIX: orElseGet:
Optional<UserPreferences> prefs = userPrefsRepo.findById(userId)
    .orElseGet(() -> userPrefsRepo.getDefaults()); // lazy
```
Diagnosis: unexpected DB queries in logs even when data exists.
Profile method calls to see `getDefaults()` being called for cache hits.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Optional purpose | 60 seconds |
| orElse vs orElseGet | 2 minutes |
| map vs flatMap | 2 minutes |
| Optional anti-patterns | 2 minutes |
| Optional in APIs | 2 minutes |
| Stream and Optional | 2 minutes |
| Optional performance | 90 seconds |
| Optional vs null | 2 minutes |
| Java 9+ Optional additions | 90 seconds |

---

**Q1 (Optional purpose): What problem does Optional solve?**

A: `null` is ambiguous. When a method returns `null`, it can mean:
(a) "not found", (b) "not applicable", (c) "error occurred",
(d) "not yet initialized". Callers must guess which and handle
(or forget to handle) the case.

Tony Hoare called null "my billion-dollar mistake." In Java, forgetting
to check for null causes `NullPointerException` - one of the most common
Java runtime errors.

`Optional<T>` makes "not found" (or "absent") explicit in the type.
A method returning `Optional<User>` tells callers: "this might not
be there - handle both cases." The caller's code must explicitly deal
with the Optional to get the value; you can't accidentally pass an
Optional where a User is expected without unwrapping.

*What separates good from great:* Optional was introduced in Java 8
inspired by Haskell's `Maybe` and Scala's `Option`. But Java's Optional
is intentionally limited compared to those: not Serializable, no special
null handling in the JVM. The intent: use Optional ONLY for return types
from API methods where absence is a normal result. Not for all nullable
values (which would be unworkable). Not for fields (use @Nullable annotation
with static analysis tools like NullAway or FindBugs for field nullability).

---

**Q2 (orElse vs orElseGet): When is `orElseGet()` preferred over `orElse()`?**

A: `orElse(T other)`: the `other` argument is ALWAYS evaluated, even
if the Optional is present. It's like: `optional.isPresent() ? optional.get() : other`.

`orElseGet(Supplier<T> supplier)`: the supplier is called ONLY if the
Optional is empty. It's like: `optional.isPresent() ? optional.get() : supplier.get()`.

```java
// orElse is fine for cheap constants/literals:
String name = findName().orElse("Unknown"); // "Unknown" is a literal
String name = findName().orElse(DEFAULT_NAME); // field, no computation

// orElseGet is required for expensive operations:
User user = findUser(id)
    .orElseGet(() -> createDefaultUser(id)); // expensive if called

// Performance trap:
Optional<String> present = Optional.of("value");
present.orElse(generateReport()); // generateReport() ALWAYS runs!
present.orElseGet(this::generateReport); // only runs if empty
```

*What separates good from great:* The `orElse` vs `orElseGet` mistake
is common in production code and can cause significant performance
degradation. A real-world example: `findCachedUser().orElse(loadFromDatabase())`
- `loadFromDatabase()` runs even when the cache hits! This negates the
entire purpose of the cache. The fix is one word: `orElseGet`.
In code review: any `orElse(methodCall())` where the method does I/O,
computation, or has side effects should be flagged for `orElseGet`.

---

**Q3 (map vs flatMap): When do you use `map` vs `flatMap` on Optional?**

A: `map(Function<T,R>)`: transform the value if present; the mapping
function returns a plain value R. Result: `Optional<R>`.

`flatMap(Function<T,Optional<R>>)`: the mapping function returns an
Optional itself. Without flatMap, you'd get `Optional<Optional<R>>`.
flatMap flattens to `Optional<R>`.

```java
// map: mapping function returns a plain value
Optional<String> name = findUser(id)
    .map(User::getName);  // User::getName returns String (not Optional)

// flatMap: mapping function returns Optional
Optional<Address> address = findUser(id)
    .flatMap(User::getAddress); // User::getAddress returns Optional<Address>

// Chain of flatMaps:
Optional<String> city = findUser(id)
    .flatMap(User::getAddress)      // Optional<Address>
    .flatMap(Address::getCity)      // Optional<String>
    .map(String::toUpperCase);      // String -> String (use map, not flatMap)

// Wrong: using map when flatMap is needed:
Optional<Optional<Address>> wrong = findUser(id)
    .map(User::getAddress);  // User::getAddress returns Optional<Address>
                             // so map returns Optional<Optional<Address>>!
```

*What separates good from great:* The map/flatMap distinction directly
mirrors the same distinction in streams and functional programming monads.
If you understand that Optional is a monad (a container with `map` and
`flatMap`), the rules are consistent: `map` for pure transformation,
`flatMap` for operations that produce the same container type. This
pattern appears in `CompletableFuture.thenApply(map)` vs
`thenCompose(flatMap)`, and in reactive streams.

---

**Q4 (Optional anti-patterns): What are the main Optional anti-patterns?**

A:

**1. Using `get()` without `isPresent()` - same as NPE:**
```java
// BAD:
String name = findUser(id).get(); // NoSuchElementException if empty!
// GOOD:
String name = findUser(id).orElseThrow();
String name = findUser(id).orElseThrow(
    () -> new UserNotFoundException(id));
```

**2. Optional as method parameter:**
```java
// BAD: callers can pass Optional.empty() or null
void save(Optional<Attachment> attachment) { ... }
// GOOD: two methods or @Nullable annotation
void save() { ... }
void save(Attachment attachment) { ... }
```

**3. Optional as field:**
```java
// BAD: not Serializable, extra overhead
class User { private Optional<String> middleName; }
// GOOD: nullable field with documentation
class User { @Nullable private String middleName; }
```

**4. isPresent + get instead of ifPresent/map:**
```java
// BAD: defeats Optional purpose, verbose
if (opt.isPresent()) { process(opt.get()); }
// GOOD: functional style
opt.ifPresent(this::process);
opt.map(this::transform).ifPresent(this::process);
```

**5. Optional in collections:**
```java
// BAD: Optional as list element - just use filter instead
List<Optional<User>> users = ...;
// GOOD:
List<User> users = optionals.stream()
    .filter(Optional::isPresent)
    .map(Optional::get)
    .collect(Collectors.toList());
// Or Java 9+:
optionals.stream().flatMap(Optional::stream).collect(Collectors.toList());
```

*What separates good from great:* The Optional anti-patterns reveal
whether someone uses Optional idiomatically (as a functional container)
or defensively (as a verbose null check). The clearest signal: code
using `if (opt.isPresent()) { opt.get()... }` was written by someone
who learned `if (x != null) { x... }` and mechanically translated it.
Refactoring to `opt.ifPresent()` or `opt.map().orElse()` is not just
style - it's intent-driven code that communicates "this operation only
happens if the value is present."

---

**Q5 (Optional in APIs): When should a method return `Optional<T>`
vs `T` vs throwing an exception?**

A: Three cases:

**Return `Optional<T>` when:**
- Absence is a NORMAL, expected result (not an error)
- Examples: `findById(id)` (entity may not exist), `findFirst()` (list may be empty)
- Caller should handle both present and absent without exceptional code path

**Return `T` (possibly null) when:**
- Null is an accepted representation in the domain (though discouraged)
- Internal/private methods where callers are known to handle null
- Performance-critical paths where Optional boxing is unacceptable

**Throw exception when:**
- Absence is an ERROR condition (caller guaranteed existence)
- Examples: `getById(id)` (asserts entity exists; throws `EntityNotFoundException`)
- Required configuration is missing (startup-time failure)

```java
// Spring Data pattern:
Optional<User> findById(Long id);   // may not exist - Optional
User getById(Long id);              // must exist - throws if not

// Our code:
Optional<User> findUser(Long id) {
    return userRepo.findById(id);   // normal: user may not exist
}
User loadUser(Long id) {
    return findUser(id)
        .orElseThrow(() -> new UserNotFoundException(id)); // contract: must exist
}
```

*What separates good from great:* The naming convention `find*` (returns
Optional or null) vs `get*` (returns value or throws) is useful for
communicating the contract at the method signature level. Spring Data,
Hibernate, and most frameworks follow this convention. In API reviews:
a `findById` that throws instead of returning Optional, or a `getById`
that returns null instead of throwing, is a contract mismatch that causes
bugs.

---

**Q6 (Stream and Optional): How do streams and Optional interact in Java 9+?**

A:
```java
// Java 9: Optional.stream() - convert Optional to a 0-or-1 element Stream
Optional<User> user = findUser(id);
Stream<User> userStream = user.stream(); // empty stream or 1-element stream

// The key use case: flatMap with Optional in a stream:
List<Optional<User>> optUsers = List.of(
    Optional.of(new User("Alice")),
    Optional.empty(),
    Optional.of(new User("Bob"))
);

// Java 8 (verbose):
List<User> presentUsers = optUsers.stream()
    .filter(Optional::isPresent)
    .map(Optional::get)
    .collect(Collectors.toList());

// Java 9+ (clean):
List<User> presentUsers = optUsers.stream()
    .flatMap(Optional::stream) // empty Optionals disappear
    .collect(Collectors.toList()); // [Alice, Bob]

// Java 9: Optional.ifPresentOrElse:
findUser(id).ifPresentOrElse(
    user -> log.info("Found user: {}", user.getName()),
    () -> log.warn("User {} not found", id)
);

// Java 9: Optional.or() - supply alternative Optional:
Optional<User> userFromCache = cacheRepo.findUser(id);
Optional<User> user = userFromCache
    .or(() -> dbRepo.findUser(id)); // try DB if not in cache
```

*What separates good from great:* `flatMap(Optional::stream)` is the
idiomatic Java 9+ pattern for filtering out empty Optionals from a stream.
Before Java 9, the `filter + map + get` pattern was required and was
error-prone (the `get()` could throw if filter was wrong). The Java 9
`or()` method is particularly useful for cache-then-database fallback
patterns: try cache first, then DB, without nested if statements.

---

**Q7 (Optional performance): Does Optional have a performance overhead?**

A: Yes, a small but measurable overhead in hot paths:

1. **Object allocation:** each `Optional.of(value)` creates an `Optional`
   object (~24 bytes on 64-bit JVM with header + reference). For methods
   called millions of times per second, this adds GC pressure.

2. **JIT optimization:** HotSpot JIT can optimize Optional away via
   escape analysis if the Optional doesn't escape the method:
   ```java
   Optional<String> opt = findName(); // may be optimized away by JIT
   return opt.orElse("default"); // JIT may inline and avoid allocation
   ```
   This optimization is not guaranteed.

**When Optional overhead matters:**
- Tight inner loops: don't use Optional inside a loop called 100M times
- Primitive values: use `OptionalInt`, `OptionalLong`, `OptionalDouble`
  (avoid boxing + Optional wrapping):
  ```java
  OptionalInt maxAge = people.stream()
      .mapToInt(Person::getAge)  // IntStream
      .max();                    // OptionalInt (no boxing)
  ```

*What separates good from great:* The Optional overhead is negligible
for typical business logic (HTTP request handling, database queries).
The cost of one Optional allocation is ~100ns; a database query is ~1ms.
The performance concern is only relevant for numeric computations and
very hot paths. Use `OptionalInt`/`OptionalLong`/`OptionalDouble` for
primitive streams to avoid boxing overhead - they're the correct API
for stream operations on primitives anyway.

---

**Q8 (Optional vs null): Should you always use Optional instead of null?**

A: No - Optional has specific use cases. The full recommendation:

**Use Optional for:**
- Public API return types where absence is expected
- Domain objects expressing "may or may not have a value"
- Chaining transformations on possibly-absent values

**Use null (with @Nullable annotation) for:**
- Fields: Optional is not Serializable; `@Nullable String` is cleaner
- Method parameters: overloading or builder pattern is cleaner
- High-performance code: avoid allocation overhead in hot paths
- Private/internal code where nulls are well-controlled

**Use exceptions for:**
- "Not found" that's an error (not an expected state)
- Required configuration or contract violations

**Reality of Java codebases (2024):**
Most existing Java code uses null extensively (especially older code).
Modern code should use Optional for public API return types. Static
analysis tools (NullAway, SpotBugs, IntelliJ's nullable annotations)
handle field/parameter nullability without Optional overhead.

*What separates good from great:* The "use Optional everywhere" approach
fails because Optional was not designed for fields (performance, Serializable),
parameters (verbose, unhelpful), or collection elements (use filter).
Kotlin took a different approach: nullable types (`String?` vs `String`)
at the language level, making null safety a first-class concern throughout.
Many Java teams adopt @Nullable/@NonNull annotations with NullAway for
field/parameter nullability and reserve Optional for return types.
This hybrid gives the best of both worlds.

---

**Q9 (Java 9+ Optional additions): What new Optional methods were added
in Java 9-11?**

A:

| Method | Version | Description |
|---|---|---|
| `or(Supplier<Optional<T>>)` | Java 9 | Fallback to another Optional if empty |
| `ifPresentOrElse(Consumer, Runnable)` | Java 9 | Handle both present and empty |
| `stream()` | Java 9 | Convert to 0 or 1 element Stream |
| `isEmpty()` | Java 11 | Returns true if no value present (not `!isPresent()`) |

```java
// or(): chain fallback Optionals
Optional<Config> config = fromEnvVar("DB_URL")
    .or(() -> fromSystemProperty("db.url"))
    .or(() -> Optional.of(Config.DEFAULT));

// ifPresentOrElse(): handle both cases in one call
userOptional.ifPresentOrElse(
    user -> metrics.userFound(user.getId()),
    () -> metrics.userNotFound()
);

// isEmpty(): cleaner than !isPresent()
if (optional.isEmpty()) {
    throw new IllegalStateException("Required value missing");
}

// stream(): unwrap in stream pipelines
List<User> users = ids.stream()
    .map(this::findUser)        // Stream<Optional<User>>
    .flatMap(Optional::stream)  // Stream<User> (empties removed)
    .collect(Collectors.toList());
```

*What separates good from great:* The `or()` method enables the "fallback chain"
pattern cleanly - try source A, then B, then C. Before Java 9, this required
nested `isPresent` checks or `.map(...).orElseGet(...)` chains. The `isEmpty()`
method was added purely for readability - `optional.isEmpty()` reads more
naturally than `!optional.isPresent()` in conditions like `if (optional.isEmpty()) throw ...`.

---

### ⚖️ Comparison Table

| Approach | Null | Optional | Exception |
|---|---|---|---|
| Absence semantics | Implicit | Explicit in type | N/A (error, not absence) |
| Compile-time enforcement | No | Yes (unwrap required) | No |
| Serializable | Yes | No | Yes |
| Performance | Fastest | Small overhead | High (exception creation) |
| Chaining | Verbose null checks | Clean (map/flatMap) | Try-catch blocks |
| Use case | Fields, internal | Public return types | Error conditions |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*
