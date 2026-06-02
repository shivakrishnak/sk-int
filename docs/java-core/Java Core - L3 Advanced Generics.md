---
layout: default
title: "Java Core - L3 Advanced Generics"
parent: "Java Core"
nav_order: 8
permalink: /java-core/l3-advanced-generics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Core - L3 Advanced Generics](#java-core---l3-advanced-generics) | medium |

---

# Java Core - L3 Advanced Generics

## Generic Wildcards and PECS

---

### 🎯 Model Answer

**30 seconds:**
> PECS = "Producer Extends, Consumer Super" - the rule for generic
> wildcards. Use `? extends T` when reading FROM a collection (the
> collection PRODUCES T values for you). Use `? super T` when writing
> TO a collection (the collection CONSUMES T values from you).
> `List<? extends Number>` is read-only from Number perspective.
> `List<? super Integer>` accepts Integer and supertypes.
> Wildcards solve the covariance problem: `List<String>` is NOT a
> subtype of `List<Object>`, but `List<String>` IS a subtype of
> `List<? extends Object>`.

**3 minutes (Senior):**
> The invariance problem: why does Java make generics invariant?
> If `List<String>` were a subtype of `List<Object>`, you could add
> an Integer to a List<String> (via the List<Object> reference).
> Java arrays are covariant (`String[]` IS `Object[]`) - this is why
> `String[] arr = new String[1]; Object[] objs = arr; objs[0] = 42`
> compiles but throws `ArrayStoreException` at runtime.
>
> Bounded wildcards enable safe covariance for reading (`? extends`)
> and safe contravariance for writing (`? super`). The `Collections.copy()`
> signature: `copy(List<? super T> dest, List<? extends T> src)` -
> PECS in action. `src` produces T values (extends), `dest` consumes
> T values (super).
>
> Unbounded wildcard `<?>`: a list of unknown type. Can only read as
> Object, can only write null. Used when you don't care about the
> element type: `printList(List<?> list)`.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "PECS and wildcards - let me cover the invariance problem,
upper-bounded (extends, for reading), lower-bounded (super, for writing),
unbounded wildcard, and the Collections.copy example."

**(2) First principles:** "From first principles: covariance (read-only)
is safe - if List<Dog> is a List<Animal>, we can read Animals from it
safely. Contravariance (write-only) is also safe - if List<Animal>
is a List<Dog>, we can put Dogs in it safely. Doing both (read AND write)
is unsafe - that's why generic types are invariant by default."

**(3) Bridge:** "PECS is like a pantry rule. A pantry that PRODUCES
food (? extends Food) can give you any specific food - you consume what
it produces. A pantry that CONSUMES food (? super Fruit) will accept
any fruit or more general item - it's flexible about what you put in."

---

### 📘 Concept Explanation

**The invariance problem:**
```java
// Arrays are covariant (unsafe - runtime check):
String[] strings = new String[1];
Object[] objects = strings;      // compiles (covariant)
objects[0] = 42;                 // ArrayStoreException at runtime!

// Generics are invariant (safe - compile check):
List<String> strings = new ArrayList<>();
List<Object> objects = strings;  // COMPILE ERROR: not a subtype!
// This prevents the unsafe pattern above - caught at compile time

// But this is too restrictive:
void printAll(List<Object> list) { list.forEach(System.out::println); }
printAll(new ArrayList<String>()); // COMPILE ERROR!
// We're only reading - no writes - this should be safe
// Solution: upper-bounded wildcard
void printAll(List<? extends Object> list) { ... }
void printAll(List<?> list) { ... }  // same: unbounded = ? extends Object
```

> **Code walkthrough:** This L3 Advanced Generics example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**PECS applied:**
```java
// Producer (source): use ? extends T (upper bound)
// You READ from it; you get T-or-subtype values
void sumList(List<? extends Number> numbers) {
    double sum = 0;
    for (Number n : numbers) { sum += n.doubleValue(); } // read OK
    // numbers.add(3.14); // COMPILE ERROR: can't write (type unknown!)
}
sumList(List.of(1, 2, 3));           // OK: List<Integer>
sumList(List.of(1.0, 2.0, 3.0));    // OK: List<Double>

// Consumer (destination): use ? super T (lower bound)
// You WRITE to it; you put T values in
void addNumbers(List<? super Integer> list, int count) {
    for (int i = 0; i < count; i++) list.add(i); // write OK
    // Integer x = list.get(0); // COMPILE ERROR: might be Number or Object
    Object x = list.get(0); // only Object guaranteed
}
addNumbers(new ArrayList<Integer>(), 5); // OK: accepts Integer
addNumbers(new ArrayList<Number>(), 5);  // OK: Integer is a Number
addNumbers(new ArrayList<Object>(), 5);  // OK: Integer is an Object

// Collections.copy: PECS in stdlib
// <T> void copy(List<? super T> dest, List<? extends T> src)
List<Number> dest = new ArrayList<>(List.of(0.0, 0.0, 0.0));
List<Integer> src = List.of(1, 2, 3);
Collections.copy(dest, src); // T=Integer; dest consumes Integer (super)
                              //            src produces Integer (extends)
```

> **Code walkthrough:** This L3 Advanced Generics example demonstrates Java API usage using Kafka messaging. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

---

### 💻 Code Example

> **Code walkthrough:** The generic method for copying with PECS showsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> why the wildcards are required. Without wildcards, you'd need exact
> type match. With PECS, any compatible combination works. The generic
> stack with wildcard push shows a practical use: a utility method
> that pushes all elements from any compatible list - the "src" produces
> elements (extends T) for the stack to consume.

```java
// Generic copy method (implementing PECS):
public static <T> void copy(
        List<? super T> dest,    // consumer: super T
        List<? extends T> src) { // producer: extends T
    for (T item : src) dest.add(item); // reads T from src, writes T to dest
}

// Usage:
List<Object> objects = new ArrayList<>();
List<String> strings = List.of("a", "b", "c");
copy(objects, strings); // T=String; objects is List<? super String>

List<Number> numbers = new ArrayList<>();
List<Integer> ints = List.of(1, 2, 3);
copy(numbers, ints); // T=Integer; numbers is List<? super Integer>

// WRONG without PECS (too restrictive):
public static <T> void copyBad(List<T> dest, List<T> src) { ... }
// copyBad(objects, strings); // COMPILE ERROR: T must be exact same type
// copyBad(numbers, ints);    // COMPILE ERROR: T=Number vs T=Integer

// Wildcard in return type (generally avoid):
// AVOID: List<? extends Number> getNumbers() { ... }
// Callers get a List they can't add to - confusing API
// PREFER: return a concrete type or use bounded type parameter
public <T extends Number> List<T> getNumbers() { ... }

// Unbounded wildcard:
void printAll(List<?> list) {
    for (Object o : list) System.out.println(o); // read as Object
    // list.add("anything"); // COMPILE ERROR: can't write to List<?>
    list.add(null); // only null can be added to List<?>
}
```

> **Code walkthrough:** The `copy` method with PECS works becauseice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `List<? extends T>` guarantees we can read T from `src` (the actual
> type is T or a subtype - safe to use as T). `List<? super T>` guarantees
> we can write T to `dest` (dest accepts T or more general - T is always
> acceptable). Without these wildcards: the method only works when src
> and dest have the exact same type, severely limiting reuse.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> PECS: Producer Extends, Consumer Super. Use `? extends T` when reading
> from a collection (you produce T from it). Use `? super T` when writing
> to a collection (it consumes T). `List<String>` is not a subtype of
> `List<Object>` - use `List<? extends Object>` for read-only Object
> access. The mnemonic: "you GET from extends, PUT to super."

---

**Senior / Staff (5+ years):**
> Wildcards enable use-site variance in Java (C# and Kotlin have
> declaration-site variance). The constraint: you can't have a type
> parameter that's both covariant and contravariant. Wildcard capture
> (the compiler capturing `?` as a type variable T) enables algorithms
> like `Collections.swap`: the method can't accept `List<?>` directly
> because it needs to get and set the same type. The compiler captures
> the wildcard: `private <T> void swapHelper(List<T> list, int i, int j)`.
> Wildcard capture is an advanced feature used in JDK collection
> implementations.

---

### ⚠️ Common Misconceptions

**Misconception 1: "`List<? extends T>` allows adding elements."**
No - `? extends T` means "some specific but unknown subtype of T."
You can't add anything (except null) because the compiler doesn't
know the actual type. `List<? extends Number>` might be a `List<Integer>`;
adding a `Double` would be wrong. Only reading is safe.

**Misconception 2: "Wildcards and bounded type parameters are the same."**
`<T extends Number>` creates a named type parameter usable throughout
the method. `? extends Number` creates an anonymous wildcard. With
a named parameter: you can use T as a type in parameter AND return
types, and relate types. With `?`: you can't use the actual type anywhere.

---

### 🚨 Failure Modes and Diagnosis

**Failure: API too restrictive without wildcards.**
```java
// Too restrictive:
void process(List<Integer> data) { ... }
// Can't pass List<Long> or List<Double> even if method only reads

// Fix: PECS
void process(List<? extends Number> data) { ... }
// Now accepts any numeric list for read-only operations

// Compile error symptom:
List<Integer> ints = List.of(1, 2, 3);
process(ints); // Error: List<Integer> cannot be converted to List<Number>
// Even though Integer is a Number!
```
> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Diagnosis: "cannot be converted" or "incompatible types" error with
generic collections. Check if the method needs to write to the collection
(if not: add `? extends`).

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| PECS mnemonic explained | 2 minutes |
| Why generics are invariant | 2-3 minutes |
| Unbounded wildcard uses | 2 minutes |
| Wildcard vs bounded type param | 2 minutes |
| Collections.copy signature | 2 minutes |
| Wildcard capture | 2-3 minutes |
| Return type wildcards | 2 minutes |
| Lower-bounded wildcard | 2 minutes |
| Type inference with wildcards | 2 minutes |

---

**Q1 (PECS mnemonic explained): Explain PECS with an example.**

A: PECS = Producer Extends, Consumer Super.

A "Producer" collection is one you READ FROM (it produces T values for you):
```java
// Producer: reads integers, produces Number for calculation
double sum(List<? extends Number> nums) { // extends = producer
    return nums.stream().mapToDouble(Number::doubleValue).sum();
}
sum(List.of(1, 2, 3));     // List<Integer> - Integer extends Number
sum(List.of(1.0, 2.0));   // List<Double> - Double extends Number
```

> **Code walkthrough:** This Unknown example demonstrates Java Stream pipeline using Stream. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **TAKEAWAY: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

A "Consumer" collection is one you WRITE TO (it consumes T values from you):
```java
// Consumer: accepts Integer and supertypes
void fill(List<? super Integer> list, int n) { // super = consumer
    for (int i = 0; i < n; i++) list.add(i); // adds Integer to list
}
fill(new ArrayList<Integer>(), 5); // Integer can be added
fill(new ArrayList<Number>(), 5);  // Number list accepts Integer
fill(new ArrayList<Object>(), 5);  // Object list accepts Integer
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Kafka messaging. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

"Neither" - both read and write: use unbounded type parameter `<T>`.
"Both" contexts: use `<T>` so you have the type name to work with.

*What separates good from great:* The PECS rule comes from Effective Java
(Item 31). The formal terms are covariance (extends = read-only) and
contravariance (super = write-only). Java arrays chose covariance without
the read-only restriction (unsafe). Java generics chose invariance by
default (safe, but restrictive). Wildcards add controlled variance at
use-sites. Kotlin and Scala have declaration-site variance (annotate the
class definition to be always covariant or contravariant). Declaration-site
is simpler for API consumers; use-site is more flexible for API authors.

---

**Q2 (Why generics are invariant): Why is `List<String>` not a subtype
of `List<Object>` in Java?**

A: Because allowing this subtype relationship would create a type hole -
a way to put non-String objects into a List<String> through the List<Object>
reference.

```java
// If List<String> were a List<Object>:
List<String> strings = new ArrayList<>();
List<Object> objects = strings; // hypothetically allowed
objects.add(42); // 42 is an Object - would compile
String s = strings.get(0); // ClassCastException! Integer is not String

// Java prevents this at compile time by making generics INVARIANT.
// The compile error on line 2 above: "incompatible types"
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Arrays DO allow covariance (and regret it):
```java
String[] sa = new String[1];
Object[] oa = sa; // allowed (covariant arrays)
oa[0] = 42;  // COMPILES but throws ArrayStoreException at runtime!
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Java arrays were designed this way before generics, for compatibility
with pre-generics code (like `Arrays.sort(Object[])`). The runtime check
(ArrayStoreException) is the price.

*What separates good from great:* The array design decision is widely
considered a mistake. Generic collections correct it by using invariance
(compile-time safety instead of runtime checks). The Liskov Substitution
Principle is violated by covariant arrays: a `String[]` is NOT a
`Object[]` in the LSP sense because you can do things with `Object[]`
(add non-String) that you can't do with `String[]`. Generics enforce LSP
correctly. This is why Effective Java advises preferring generic collections
to arrays (Item 28).

---

**Q3 (Unbounded wildcard uses): When do you use `List<?>`?**

A: Use `List<?>` (unbounded wildcard) when:

1. **The method doesn't depend on the element type:**
```java
void printAll(List<?> list) {
    for (Object obj : list) System.out.println(obj); // elements as Object
}
printAll(List.of("a", "b"));   // OK
printAll(List.of(1, 2, 3));    // OK
printAll(List.of(new Object())); // OK - any list
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

2. **Checking size, clear, contains with Object:**
```java
boolean hasDuplicates(List<?> list) {
    return list.size() != new HashSet<>(list).size();
}
int indexOf(List<?> list, Object o) {
    return list.indexOf(o); // contains/indexOf take Object, not T
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

3. **instanceof check for raw type:**
```java
if (obj instanceof List) { // can't do instanceof List<String>
    List<?> list = (List<?>) obj; // safe wildcard cast
    // list.add(element); // COMPILE ERROR - correctly prevents unsafe adds
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

`List<?>` limits you to: read as Object, write null only, call methods
that don't care about element type (size, clear, isEmpty).

*What separates good from great:* `List<?>` and `List<Object>` look
similar but differ critically: `List<Object>` accepts ONLY `List<Object>`
references. `List<?>` accepts `List<Object>`, `List<String>`,
`List<Integer>` - any List. For method parameters that only OBSERVE
a list (don't modify): `List<?>` is the correct signature. It's more
permissive for callers while being safer (prevents accidental writes).
A method taking `List<Object>` forces callers to have exactly `List<Object>`,
which is rare - they usually have `List<SpecificType>`.

---

**Q4 (Wildcard vs bounded type parameter): When do you use `<T extends X>`
vs `<? extends X>`?**

A:

Use **bounded type parameter `<T extends X>`** when:
- You need to reference the type in multiple places (input AND output)
- The type must be consistent across parameters
- The type is used in the return type

```java
// T used in both parameter and return type:
<T extends Comparable<T>> T max(T a, T b) {
    return a.compareTo(b) >= 0 ? a : b;
}
// Caller: String s = max("apple", "banana"); // T=String inferred

// T relates two parameters:
<T> void copy(List<? super T> dest, List<? extends T> src) { ... }
// Both wildcards relate through T
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Use **wildcard `? extends X`** when:
- You only need to use the type once (single parameter position)
- The type doesn't need a name (not used in return type)
- You're writing a read-only parameter

```java
// Only used once, read-only, no return type dependency:
double sum(List<? extends Number> nums) { ... }
// Equivalent to:
<T extends Number> double sum(List<T> nums) { ... }
// But wildcard is preferred: simpler, communicates "read-only"
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Effective Java (Item 31) calls this
the "rule of thumb" for wildcards: "use bounded wildcards to increase
API flexibility." The general guideline: prefer wildcards in method
parameters if you don't need the type name elsewhere. Named type
parameters are for methods where the type must appear in multiple
positions or the return type. APIs with wildcards in parameters are
more flexible for callers; APIs with type parameters are more expressive
for method bodies that need to do typed operations.

---

**Q5 (Collections.copy signature): Analyze the signature
`<T> void copy(List<? super T> dest, List<? extends T> src)`.**

A: This is the canonical PECS example from the JDK.

```java
// Analysis:
// - T: the element type being copied
// - src: List<? extends T>
//   - src is a PRODUCER of T (we read T values from src)
//   - ? extends T: the actual type in src is T or a subtype of T
//   - We can read T from src safely (any subtype can be used as T)
//   - We CANNOT write to src (unknown actual subtype)
// - dest: List<? super T>
//   - dest is a CONSUMER of T (we write T values to dest)
//   - ? super T: dest holds T or a supertype of T
//   - We CAN write T to dest (T is a subtype of dest's element type)
//   - We cannot read from dest as T (might be supertype, needs cast)

// Example call:
List<Number> numbers = new ArrayList<>(List.of(1.0, 2.0, 3.0));
List<Integer> integers = List.of(10, 20, 30);

Collections.copy(numbers, integers);
// T = Integer
// dest: List<? super Integer> - numbers (List<Number>) qualifies
//   because Number is a supertype of Integer
// src: List<? extends Integer> - integers (List<Integer>) qualifies
//   because Integer extends itself

// After: numbers = [10, 20, 30]
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Kafka messaging. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Without PECS, the signature would be `<T> void copy(List<T> dest, List<T> src)`.
This would require `dest` and `src` to have EXACTLY the same type T.
You couldn't copy from `List<Integer>` to `List<Number>`.

*What separates good from great:* The PECS principle was not invented for
Java - it's the application of the Liskov Substitution Principle to
parameterized types. In type theory: covariant types can be used where
supertypes are expected (extends = covariant = producer). Contravariant
types can be used where subtypes are expected (super = contravariant =
consumer). Java's wildcards implement "use-site variance" - the variance
is declared at the usage of the type, not at the declaration of the
generic class.

---

**Q6 (Wildcard capture): What is wildcard capture?**

A: When the compiler "captures" a wildcard as a concrete type variable
for use in the method body.

```java
// Problem: can't swap elements via List<?> without capture
void swap(List<?> list, int i, int j) {
    Object temp = list.get(i);
    list.set(i, list.get(j)); // COMPILE ERROR: set expects '?'
    list.set(j, temp);        // COMPILE ERROR: same
}

// Solution: capture the wildcard via a private helper:
void swap(List<?> list, int i, int j) {
    swapHelper(list, i, j); // compiler captures '?' as type T
}

private <T> void swapHelper(List<T> list, int i, int j) {
    T temp = list.get(i);   // T captured - same type as list elements
    list.set(i, list.get(j)); // OK: set and get same type T
    list.set(j, temp);
}
// The compiler verifies: the '?' in swap is consistent with T in swapHelper
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

The compiler performs "wildcard capture" when `swap` calls `swapHelper`:
the actual type of `?` (unknown at compile time) is captured as T in
the helper. The type checker can verify consistency without knowing
the actual type.

*What separates good from great:* Wildcard capture is how the JDK
implements many collection utility methods. `Collections.swap`,
`Collections.reverse`, and similar methods use this pattern. The pattern:
public method with `List<?>` parameter (flexible API), private helper
with `<T>` (typed implementation). The compiler automatically performs
the capture. Understanding wildcard capture distinguishes candidates
who have read the collections source code from those who have only used it.

---

**Q7 (Return type wildcards): Why should you avoid wildcards in return types?**

A: Wildcards in return types force callers to deal with wildcards in their
own code, propagating complexity.

```java
// AVOID: wildcard in return type
List<? extends Number> getNumbers() { return List.of(1, 2, 3); }

// Caller forced to deal with wildcard:
List<? extends Number> nums = getNumbers(); // must use wildcard
// nums.add(4); // COMPILE ERROR
// List<Number> plainNums = getNumbers(); // COMPILE ERROR
// The caller is stuck with an un-addable list

// PREFER: concrete return type
List<Integer> getIntegers() { return List.of(1, 2, 3); }
List<Number> getNumbers() { return new ArrayList<>(List.of(1, 2, 3)); }

// If the actual type varies: use a bounded type parameter on the method:
<T extends Number> List<T> getValues(Class<T> type) {
    return new ArrayList<>(); // concrete type at call site
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Effective Java (Item 31): "Do not use wildcard types as return types."
Using wildcards in return types leaks the API's implementation complexity
to callers.

*What separates good from great:* The exception: `<T>` type parameters
in return types are fine (they give callers flexibility via type inference).
Wildcards in return types are different: they force callers to use
wildcard syntax. As an API design rule: if you find yourself putting
`? extends` or `? super` in a return type, reconsider. Either: make
the method generic with a bounded type parameter, or commit to a specific
concrete type. The goal: callers get the most specific usable type
from your API without needing to know about the implementation's variance.

---

**Q8 (Lower-bounded wildcard): When exactly do you use `? super T`?**

A: `? super T` (lower-bounded wildcard) means "T or any ancestor of T."
Used when the method writes T values to a container.

```java
// Consumer pattern: writing Integer values to any Integer-compatible list
void fillRange(List<? super Integer> list, int start, int count) {
    for (int i = start; i < start + count; i++) {
        list.add(i); // Integer can be added to List<Integer>,
                     // List<Number>, List<Object>
    }
}

// TreeSet with custom comparator:
TreeSet<? super Integer> set = new TreeSet<>(Comparator.naturalOrder());
// Can't create a TreeSet<? super Integer> directly - use concrete type
// Lower bound is usually for PARAMETERS, not variable declarations

// Comparator.naturalOrder() return type:
// static <T extends Comparable<? super T>> Comparator<T> naturalOrder()
// "? super T" for the Comparable bound: T itself or any supertype
// of T can be Comparable - allows T to inherit compareTo from a parent class

// Real use: Comparator.comparing with Function:
// static <T, U extends Comparable<? super U>> Comparator<T> comparing(
//     Function<? super T, ? extends U> keyExtractor)
// "? super T": key extractor accepts T or supertype (flexible input)
// "? extends U": result is U or subtype (safe use as U)
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using Kafka messaging. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* `Comparable<? super T>` appears in
many JDK signatures. It means: T is Comparable to something that T
extends. This allows a `Dog` class to inherit `compareTo` from `Animal`
(declared as `Animal implements Comparable<Animal>`) and still work in
`TreeSet<Dog>`. Without `? super`, you'd need `Dog` to explicitly implement
`Comparable<Dog>`, preventing inheritance of the comparison logic.
This subtlety is tested in senior interviews.

---

**Q9 (Type inference with wildcards): How does Java's type inference
interact with wildcards?**

A:
```java
// Type inference fills in T from context:
List<String> strings = new ArrayList<>();  // T=String inferred
List<Integer> ints = Collections.emptyList(); // T=Integer inferred

// Diamond operator (Java 7): infer type from left side
Map<String, List<Integer>> map = new HashMap<>(); // inferred

// Wildcard and inference:
List<? extends Number> nums = List.of(1, 2, 3); // ? captured as Integer

// Method inference with wildcards:
<T> T first(List<? extends T> list) { return list.get(0); }
Number n = first(List.of(1, 2, 3)); // T=Number, ? extends Number satisfied
Object o = first(List.of("a"));      // T=Object, ? extends Object satisfied
String s = first(List.of("a", "b")); // T=String

// Target typing (Java 8): infer from method parameter type
Collections.sort(strings);          // T=String inferred from strings
Collections.sort(strings, Comparator.reverseOrder()); // T=String inferred

// When inference fails: provide explicit type argument
List<Number> mixed = Collections.<Number>emptyList(); // explicit T=Number
// Without explicit: Collections.emptyList() may infer as List<Object>
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Java 8 improved type inference
significantly (target typing). Before Java 8: `Collections.emptyList()`
often required an explicit type argument. With Java 8: the compiler
infers from the assignment target. Inference failures are rare but
notable: when calling a method with a wildcard return type as an
argument to another generic method, the compiler may fail to infer
the type and require explicit annotation. Understanding this helps
debug "cannot infer type arguments" compile errors.

---

### ⚖️ Comparison Table

| Wildcard Type | Read Access | Write Access | Use Case |
|---|---|---|---|
| `List<T>` | As T | As T | Both read and write, type matters |
| `List<? extends T>` | As T | None (except null) | Read-only (producer) |
| `List<? super T>` | As Object only | As T | Write-only (consumer) |
| `List<?>` | As Object only | None (except null) | Type-agnostic operations |
| `List<Object>` | As Object | As Object | Explicitly heterogeneous |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*

---

---

## Effective Java Item Clusters

---

### 🎯 Model Answer

**30 seconds:**
> "Effective Java" by Joshua Bloch (3rd edition, 2018) is the definitive
> Java best-practices guide. Key clusters: (1) Static factory methods
> over constructors (readability, caching, subtyping). (2) Builder
> pattern for objects with many parameters. (3) Favor composition over
> inheritance. (4) Program to interfaces, not implementations.
> (5) Prefer immutable classes. (6) Use generics, not raw types.
> These items represent distilled experience from the Java platform
> team and remain the benchmark for professional Java code.

**3 minutes (Senior):**
> The clusters matter because they address recurring design problems:
> Static factories: `Optional.of()`, `Collections.emptyList()` are static
> factories. They can return cached instances (empty collections), have
> meaningful names, return subtypes without exposing them, and reduce
> verbosity. Builders: `HttpRequest.newBuilder()...build()` - construction
> with named parameters, validation at build time, optional parameters.
>
> Composition over inheritance: `extends` creates tight coupling and
> violates encapsulation (subclass depends on superclass internals).
> Composition wraps the underlying object; changes in the wrapped class
> don't automatically break the wrapper. Item 18: "Inheritance violates
> encapsulation." Real-world: `InstrumentedSet` wrapping `HashSet` vs
> extending it (the counting-add example in Effective Java).
>
> Immutability: thread-safe by default, simple, cacheable. Strings,
> Integer, LocalDate are immutable. Making a class immutable: all fields
> final, no setters, defensive copies of mutable fields in constructors
> and accessors.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Effective Java item clusters - let me cover the key
patterns: static factory methods, builders, composition over inheritance,
immutability, and programming to interfaces."

**(2) First principles:** "From first principles: these items address
the most common design mistakes in Java. Each one is a specific trade-off
with a recommended resolution based on decades of Java ecosystem experience."

**(3) Bridge:** "Effective Java items are like a professional
electrician's code book. You could wire a house your own way, but the
code represents accumulated safety wisdom. These patterns represent
accumulated Java safety and maintainability wisdom."

---

### 📘 Concept Explanation

**Cluster 1: Object Creation and Destruction (Items 1-9)**

Key items: 1 (static factory), 2 (builder), 3 (singleton), 5 (DI),
6 (avoid unnecessary objects), 7 (eliminate obsolete references).

**Cluster 2: Methods Common to All Objects (Items 10-14)**

Key items: 10 (equals contract), 11 (hashCode contract), 12 (toString),
13 (clone), 14 (Comparable).

**Cluster 3: Classes and Interfaces (Items 15-25)**

Key items: 15 (minimize accessibility), 16 (accessor methods), 17 (immutable),
18 (composition over inheritance), 19 (design for inheritance), 21 (interface defaults).

**Cluster 4: Generics (Items 26-33)**

Key items: 26 (no raw types), 27 (unchecked warnings), 28 (lists over arrays),
29 (generic types), 30 (generic methods), 31 (bounded wildcards), 33 (typesafe containers).

---

### 💻 Code Example

> **Code walkthrough:** The InstrumentedSet example (Item 18) is theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> canonical illustration of "favor composition over inheritance". The
> inheritance version has a subtle bug where `addAll()` counts elements
> twice because `HashSet.addAll()` internally calls `add()` (which is
> overridden). The composition version wraps the HashSet and counts
> at the wrapper level only, avoiding the double-counting bug.


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// BAD: inheritance for instrumentation (Item 18 - the famous bug):
class InstrumentedHashSet<E> extends HashSet<E> {
    private int addCount = 0;

    @Override public boolean add(E e) {
        addCount++;
        return super.add(e); // increments count +1 per element
    }
    @Override public boolean addAll(Collection<? extends E> c) {
        addCount += c.size(); // increments count by collection size
        return super.addAll(c); // calls add() for each element!
    }
    // When addAll(List.of("a","b","c")) is called:
    // addCount += 3 (in addAll), then add() called 3 more times = 6!
    // Expected: 3. Actual: 6!
}

// GOOD: composition with forwarding (Item 18):
class InstrumentedSet<E> implements Set<E> {
    private final Set<E> wrapped; // composition
    private int addCount = 0;

    InstrumentedSet(Set<E> set) { this.wrapped = set; }

    @Override public boolean add(E e) {
        addCount++;
        return wrapped.add(e); // delegates - no double-counting
    }
    @Override public boolean addAll(Collection<? extends E> c) {
        addCount += c.size(); // count once here
        return wrapped.addAll(c); // wrapped.addAll doesn't call our add()
    }
    // All other Set methods delegate to wrapped:
    @Override public int size() { return wrapped.size(); }
    @Override public boolean contains(Object o) { return wrapped.contains(o); }
    // ... other delegating methods
}

// Static factory vs constructor (Item 1):
// BAD: constructor doesn't communicate intent
new BigInteger(bytes); // what does this construct exactly?

// GOOD: static factory with name
BigInteger.valueOf(42);             // "valueOf" communicates conversion
Optional.of(value);                 // "of" is a factory idiom
Collections.emptyList();           // can return cached instance
List.of("a", "b", "c");           // factory that can return compact impl

// Builder for complex objects (Item 2):
// BAD: telescoping constructors or JavaBeans pattern
new User("Alice", "alice@ex.com", null, null, true, false, 30);
// What does null, null, true, false, 30 mean?

// GOOD: Builder
User user = User.builder()
    .name("Alice")
    .email("alice@example.com")
    .age(30)
    .active(true)
    .build(); // validates all required fields at build time
```

> **Code walkthrough:** The InstrumentedHashSet bug occurs becauseice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `HashSet.addAll()` is implemented by calling `add()` on each element.
> When you override `add()` and also call `super.addAll()`, the
> `super.addAll()` calls YOUR overridden `add()`. This is the "self-use"
> problem with inheritance - you depend on the superclass's internal
> implementation choices, which aren't documented and can change. The
> composition fix avoids this: `wrapped.addAll(c)` calls the wrapped
> HashSet's `add()`, not yours.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Key Effective Java items: prefer static factories for clearer API
> names and caching. Use Builder for many constructor parameters.
> Composition over inheritance avoids tight coupling to superclass
> internals. Prefer immutable classes: thread-safe, simple, cacheable.
> Program to interfaces (`List<String>` not `ArrayList<String>`).

---

**Senior / Staff (5+ years):**
> The composition-over-inheritance guidance (Item 18) is still violated
> frequently in enterprise code. The test: if you can't describe IS-A
> (a circle IS-A shape), use HAS-A (composition). Liskov Substitution:
> subclass must be substitutable for superclass in all contexts. Template
> Method pattern (Item 19) is the legitimate use of abstract classes with
> inheritance: the framework controls the algorithm skeleton; subclasses
> fill in steps. For modern Java: records (Java 16) enforce the immutability
> and standard method generation Items 17, 10-12 recommend.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Static factory methods are the same as the Factory Method pattern."**
Static factory methods (Item 1) are any static method that returns
instances. The Factory Method is a GoF design pattern where a method in
a superclass is overridden by subclasses to create objects. Naming: static
factories use idiomatic names: `of`, `from`, `valueOf`, `getInstance`,
`create`, `getType`.

**Misconception 2: "Composition always replaces inheritance."**
Inheritance is correct for IS-A relationships with Liskov substitution.
`ArrayList extends AbstractList` is correct: ArrayList IS-A List, and
AbstractList is designed for extension (Item 19). Use inheritance when
the superclass is designed for it and the IS-A relationship holds.
Use composition when the superclass is not designed for extension or
when you want to avoid the fragile base class problem.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Builder not validating invariants.**
```java
// BAD: build() creates invalid objects
class Range {
    final int min, max;
    Range(int min, int max) { this.min = min; this.max = max; }
    static class Builder {
        int min, max;
        Builder min(int v) { min = v; return this; }
        Builder max(int v) { max = v; return this; }
        Range build() {
            return new Range(min, max); // DOESN'T check min < max!
        }
    }
}
Range invalid = new Range.Builder().min(10).max(5).build(); // min > max!

// FIX: validate in build():
Range build() {
    if (min >= max) throw new IllegalStateException(
        "min must be less than max: " + min + " >= " + max);
    return new Range(min, max);
}
```
> **Code walkthrough:** BAD pattern: This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **WHAT BREAKS: document thread-safety guarantees on every shared mutable class.**

Diagnosis: invalid domain objects causing failures far from construction.
Centralizing validation in `build()` makes the error occur at the source.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Static factory benefits | 2 minutes |
| Builder pattern when needed | 2 minutes |
| Composition vs inheritance | 3 minutes |
| Immutability benefits | 2 minutes |
| Program to interfaces | 2 minutes |
| Equals/hashCode contract | 2 minutes |
| Item 7: obsolete references | 2 minutes |
| Item 17: immutable class rules | 2 minutes |
| Item 28: lists over arrays | 2 minutes |

---

**Q1 (Static factory benefits): What are the advantages of static factory
methods over constructors?**

A: Item 1 from Effective Java lists five advantages:

**1. They have names (communicate intent):**
```java
new BigInteger(int, int, Random) // which arg is which?
BigInteger.probablePrime(bitLength, random) // clear!
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**2. Not required to create new object each call (caching):**
```java
Integer.valueOf(127) // returns cached instance for -128..127
Boolean.valueOf(true) // always returns same Boolean.TRUE object
// constructors MUST create new objects
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**3. Can return any subtype (implementation hiding):**
```java
// Collections.emptyList() returns Collections.EMPTY_LIST - package-private class
// Caller sees List<T>, doesn't need to know the actual class
List<String> empty = Collections.emptyList(); // java.util.Collections.EmptyList
// This class is not public - hidden implementation
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**4. The returned class can vary based on parameters:**
```java
EnumSet.of(Day.MON, Day.TUE) // returns RegularEnumSet (long bit field)
EnumSet.noneOf(Day.class)    // may return JumboEnumSet for large enums
// Optimal implementation chosen for you
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**5. The returned class need not exist when writing the factory:**
Service Provider Framework pattern: `DriverManager.getConnection(url)`.

*What separates good from great:* The naming convention for static factories:
`of` (conversion with same type), `from` (type conversion), `valueOf`
(more verbose `of`), `instance` or `getInstance` (for singletons/shared
instances), `create` or `newInstance` (guaranteed new instance), `getType`
(factory in a different class, e.g., `Files.newBufferedReader`). Following
these conventions makes the API recognizable to Java programmers.

---

**Q2 (Builder pattern when needed): When should you use the Builder pattern?**

A: Use Builder when (Item 2):

**1. Constructor has 4+ parameters (especially optional ones):**

```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// BAD: telescoping constructors
NutritionFacts cola = new NutritionFacts(240, 8, 100, 0, 35, 27);
// Parameters: servingSize, servings, calories, fat, sodium, carbs
// Which number is sodium? 0 fat? 35 sodium?

// GOOD: Builder
NutritionFacts cola = new NutritionFacts.Builder(240, 8) // required
    .calories(100)
    .sodium(35)
    .carbohydrates(27)
    .build();
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **WHAT BREAKS: document thread-safety guarantees on every shared mutable class.**

**2. JavaBeans pattern would leave object in inconsistent state:**
```java
// JavaBeans: setters can leave partially constructed object
NutritionFacts cola = new NutritionFacts();
cola.setServingSize(240); // incomplete object accessible here!
cola.setServings(8);      // still incomplete
cola.setCalories(100);    // now valid? or not?
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**3. Class hierarchy with builders:**
```java
abstract class Pizza {
    abstract static class Builder<T extends Builder<T>> {
        abstract Pizza build();
    }
}
class NYPizza extends Pizza {
    enum Size { SMALL, MEDIUM, LARGE }
    static class Builder extends Pizza.Builder<Builder> {
        Builder size(Size size) { ... return this; }
    }
}
// Covariant return types and self-type pattern enable fluent subclass builders
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using enum. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Lombok's `@Builder` annotation generates
the Builder boilerplate at compile time. Spring Boot's configuration
objects use builders. Jackson uses builders for ObjectMapper configuration.
The test for when to use Builder: "Would a reasonable developer look at
this constructor call and know what each argument does?" If no: use Builder.
Builders are especially valuable when many optional parameters exist -
you only set what's relevant, defaults handle the rest.

---

**Q3 (Composition vs inheritance): When is inheritance appropriate
vs composition?**

A: The LSP test: is the relationship genuinely IS-A with full behavioral
compatibility?

**Inheritance is appropriate:**
```java
// Stack IS-A AbstractSequentialList? NO! (stack shouldn't expose get(i))
// A Vector IS-A Stack? NO! (Bloch's example of Java's design mistake)

// Car IS-A Vehicle? YES (if Vehicle defines all operations Car supports)
abstract class Vehicle {
    abstract void start();
    abstract void stop();
    // All operations that ALL vehicles support
}
class Car extends Vehicle {
    // Liskov: anywhere Vehicle is used, Car works identically
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**Composition is appropriate:**
```java
// Logger that wraps an existing logger:
class TimedLogger implements Logger {
    private final Logger delegate;      // composition
    private final Clock clock;

    TimedLogger(Logger delegate, Clock clock) {
        this.delegate = delegate;
        this.clock = clock;
    }

    @Override
    public void log(String msg) {
        delegate.log("[" + clock.now() + "] " + msg); // adds timing
    }
    // All other Logger methods delegate:
    // delegate.setLevel, delegate.isEnabled, etc.
}
// Change: if Logger adds a new method, TimedLogger delegates it
// without any change to TimedLogger (doesn't break)
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* The "fragile base class problem": when
a subclass's behavior breaks after a change to the base class that didn't
intend to affect subclasses. Composition avoids this: the wrapped object's
internals are irrelevant to the wrapper. Real-world: `Properties extends
Hashtable` in the JDK is a design mistake (admitted by Bloch). Properties
inherits `put(Object, Object)` from Hashtable, allowing non-String values
even though Properties should only hold String->String. Fixing this would
be a backward incompatible change. The lesson: wrong use of inheritance
creates permanent API debt.

---

**Q4 (Immutability benefits): What makes a class immutable and why
prefer immutability?**

A: **Five rules for immutable classes (Item 17):**
1. Don't provide methods that modify state (no setters)
2. Ensure the class can't be extended (final class or private constructors)
3. Make all fields final
4. Make all fields private
5. Ensure exclusive access to mutable components (defensive copies)

```java
// Immutable class:
public final class Point {
    private final double x;
    private final double y;

    public Point(double x, double y) {
        this.x = x;
        this.y = y;
    }

    // "Wither" methods return new instances instead of mutating:
    public Point translate(double dx, double dy) {
        return new Point(x + dx, y + dy);
    }

    public double getX() { return x; }
    public double getY() { return y; }
    // equals, hashCode, toString...
}

// Defensive copy for mutable fields:
public final class DateRange {
    private final Date start; // Date is mutable!
    private final Date end;

    public DateRange(Date start, Date end) {
        this.start = new Date(start.getTime()); // defensive copy IN
        this.end = new Date(end.getTime());
    }
    public Date getStart() {
        return new Date(start.getTime()); // defensive copy OUT
    }
    // Better: use LocalDate or Instant (immutable) instead of Date!
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**Benefits of immutability:**
- Thread-safe: no synchronization needed (read-only access is always safe)
- Cache-friendly: hash code computed once, shared instances safe
- Simple reasoning: state never changes - no "what changed my object?"
- Failure atomicity: operations either fully succeed or fully fail (no partial state)

*What separates good from great:* The biggest practical benefit in modern
Java: immutable objects work safely in concurrent environments without
any synchronization. `String`, `Integer`, `LocalDate`, `BigDecimal` are
immutable - safe to share across threads. Mutable objects (`Date`,
`ArrayList`) require external synchronization for concurrent access.
Java records (Java 16) enforce the immutability pattern for data carriers:
final fields, only accessor methods, generated equals/hashCode/toString.
For domain objects that are purely data: records are the modern idiomatic
choice over manual immutable classes.

---

**Q5 (Program to interfaces): What does "program to interfaces, not
implementations" mean in practice?**

A: Declare variables, parameters, and return types using interface types.
Reserve concrete types for instantiation (and local variables where the
type is clear from context).


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// BAD: concrete types in API
ArrayList<String> getNames() { return new ArrayList<>(); }
void process(HashMap<String, User> users) { ... }

// GOOD: interface types in API
List<String> getNames() { return new ArrayList<>(); }
void process(Map<String, User> users) { ... }

// BAD: concrete type in variable declaration
ArrayList<String> names = new ArrayList<>();

// GOOD: interface type (diamond infers the concrete type)
List<String> names = new ArrayList<>();

// Benefit: easy to change implementation:
// List<String> names = new LinkedList<>(); // change only one place
// If "names" was ArrayList everywhere: change in many places

// Interface in API: callers can pass any Map implementation:
process(new HashMap<>()); // works
process(new TreeMap<>());  // works
process(new ConcurrentHashMap<>()); // works
// If signature used HashMap: callers couldn't pass TreeMap!

// When to use concrete type:
// - When the concrete type's extra methods are needed:
ArrayDeque<String> deque = new ArrayDeque<>();
deque.push("first"); // ArrayDeque.push() not in Deque? (it is, via Deque)
// But: if you need ArrayDeque-specific methods not in Deque,
// use ArrayDeque in the variable type
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates contract definition using interface. **KEY MECHANISM:** the JVM uses dynamic dispatch for all interface method calls. **WHY IT MATTERS:** interfaces with default methods can conflict at compile time via diamond problem. **WHAT BREAKS: interfaces define contracts; prefer them over abstract classes for unrelated types.**

*What separates good from great:* This item applies to ALL types, not
just collections. `InputStream` not `FileInputStream` in method parameters
(caller decides the source). `Executor` not `ThreadPoolExecutor`. `Clock`
not `SystemClock` (enables test injection of a mock clock). The practical
test: "Does this API care HOW something is implemented, or just WHAT
it does?" If "what it does": use the interface. The secondary benefit:
testability - interfaces can be mocked (`Mockito.mock(List.class)`) while
final implementations can't.

---

**Q6 (Equals/hashCode contract): What are the rules for equals() and
hashCode()?**

A: **equals() contract (5 rules, Item 10):**
1. **Reflexive:** `x.equals(x)` = true
2. **Symmetric:** `x.equals(y)` = `y.equals(x)`
3. **Transitive:** if `x.equals(y)` and `y.equals(z)` then `x.equals(z)`
4. **Consistent:** same result for same unchanged objects
5. **Null:** `x.equals(null)` = false (never throws NPE)

**hashCode() contract (Item 11):**
1. Consistent with equals: if `x.equals(y)` then `x.hashCode() == y.hashCode()`
2. NOT required that unequal objects have different hash codes (collisions allowed)
3. Consistent across JVM runs UNLESS fields used in computation change

```java
// Common violation: symmetry broken by mixed-type equals
class Point {
    int x, y;
    @Override public boolean equals(Object o) {
        if (o instanceof Point p) return x == p.x && y == p.y;
        if (o instanceof ColorPoint cp) return x == cp.x && y == cp.y; // wrong!
        return false;
    }
}
class ColorPoint extends Point {
    Color color;
    @Override public boolean equals(Object o) {
        if (!(o instanceof ColorPoint cp)) return false;
        return super.equals(cp) && color.equals(cp.color);
    }
}
// point.equals(colorPoint) = true (ignores color)
// colorPoint.equals(point) = false (not a ColorPoint)
// ASYMMETRIC! Violates contract.

// Fix: don't mix types in equals. Use composition.
```

> **Code walkthrough:** This Unknown example demonstrates exception handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

*What separates good from great:* The impossibility result (Bloch, citing
Liskov): you CANNOT extend an instantiable class and add a value component
while preserving the equals contract. The solution: use composition
(ColorPoint HAS-A Point, not IS-A Point) and add a `asPoint()` view
method. Java records handle this correctly: equals compares all components
of the same record type, never mixing with supertypes.

---

**Q7 (Item 7 obsolete references): What are obsolete references and
how do you handle them?**

A: An "obsolete reference" is a reference your program holds but will
never access again. The GC can't collect the referenced object. This
is Java's version of a memory leak.

```java
// Classic example: a custom stack implementation
class Stack<E> {
    private Object[] elements;
    private int size;

    E pop() {
        if (size == 0) throw new EmptyStackException();
        return (E) elements[--size];
        // BUG: elements[size] still holds the reference!
        // Object won't be GC'd even after pop()!
    }

    // FIX: null out the obsolete reference:
    E popFixed() {
        if (size == 0) throw new EmptyStackException();
        @SuppressWarnings("unchecked")
        E result = (E) elements[--size];
        elements[size] = null; // eliminate obsolete reference
        return result;
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**Common sources of obsolete references:**
1. Caches: entries that are no longer needed but still in the cache.
   Fix: use `WeakHashMap` for cache keys; entries expire when key has no strong reference.
2. Listeners: registered but never deregistered.
   Fix: `removeEventListener` in `close()` or `AutoCloseable`.
3. Callbacks: stored but never cleaned up.
   Fix: WeakReference-based callback registry.

*What separates good from great:* Java's GC doesn't prevent memory leaks;
it prevents dangling pointer bugs. Memory leaks in Java come from holding
references to objects longer than needed. Tools for diagnosis: Eclipse MAT
(Memory Analyzer Tool), VisualVM heap dump analysis, `-XX:+HeapDumpOnOutOfMemoryError`.
The leak signature: heap usage grows monotonically even under steady load.
Profiler shows a specific class accumulating instances. Finding it in a
heap dump: sort by class instance count, look for what's holding references.

---

**Q8 (Item 17 immutable class rules): How do you make a Java class fully
immutable?**

A: The five rules plus practical implementation:

```java
public final class ImmutablePerson {
    // Rule 3: all fields final
    // Rule 4: all fields private
    private final String name;
    private final LocalDate birthDate;
    private final List<String> nicknames; // mutable - needs defense

    // Rule 5: defensive copies of mutable fields in constructor
    public ImmutablePerson(String name, LocalDate birthDate,
                           List<String> nicknames) {
        this.name = Objects.requireNonNull(name);
        this.birthDate = Objects.requireNonNull(birthDate);
        // Defensive copy of mutable list:
        this.nicknames = List.copyOf(nicknames); // Java 10: unmodifiable copy
        // or: Collections.unmodifiableList(new ArrayList<>(nicknames));
    }

    // Rule 1: no setters, no mutating methods
    // "Wither" method returns new instance:
    public ImmutablePerson withName(String newName) {
        return new ImmutablePerson(newName, birthDate, nicknames);
    }

    // Rule 5: defensive copies in accessors
    // (not needed here: nicknames is already unmodifiable)
    public List<String> getNicknames() { return nicknames; }

    // Rule 2: class is final (can't be extended to add mutable state)
}

// Alternatively: make constructor private + static factory
// to enable returning cached instances or subclasses
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* `List.copyOf()` (Java 10) creates an
unmodifiable copy in one call - the defensive copy IN the constructor.
Returning the unmodifiable list from the accessor means callers can't
mutate it. For deeper immutability: if the list contains mutable objects
(e.g., `List<Address>` where Address is mutable), you'd need to
deep-copy each element too. Truly immutable classes work deeply: all
reachable objects are also immutable. Java records achieve this automatically
for their components if the component types are immutable.

---

**Q9 (Item 28 lists over arrays): Why does Effective Java say to prefer
lists over arrays?**

A: Item 28: "Prefer lists to arrays."

**Three reasons:**

**1. Arrays are covariant, generics are invariant:**
```java
String[] sa = new String[1];
Object[] oa = sa;       // OK at compile time
oa[0] = 42;            // ArrayStoreException at runtime!

List<String> ls = new ArrayList<>();
List<Object> lo = ls;  // COMPILE ERROR: correctly rejected!
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**2. Arrays are reifiable (runtime type), generics are erased:**
```java
String[] sa = new String[1]; // new String[]: runtime type is String[]
// Generic array:
List<String>[] lsa = new List<String>[1]; // COMPILE ERROR: generic array!
// You'd get: List[]   (erased) - type safety lost
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**3. Lists provide type safety, arrays don't:**
```java
// With arrays: ClassCastException at runtime
// With generics: compile-time error
// Prefer compile-time errors
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// Practical conversion:
// BAD: generic array creation
@SuppressWarnings("unchecked")
T[] array = (T[]) new Object[n]; // need unchecked cast, type safety lost

// GOOD: generic list
List<T> list = new ArrayList<>(n); // no unchecked cast, fully type-safe
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates Java API usage using generic type. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **WHAT BREAKS: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* The legitimate uses for arrays in modern
Java: performance-critical code where boxing overhead of `List<Integer>`
vs `int[]` matters. JDK internals use arrays (ArrayList's backing store
is `Object[]`). For public APIs: `List<T>` is safer and more flexible.
For primitive numeric work: primitive arrays (`int[]`, `double[]`) are
always preferred over `List<Integer>` to avoid boxing. Java's `Arrays`
utility class (sort, fill, copyOf, binarySearch) provides collection-like
operations on primitive arrays.

---

### ⚖️ Comparison Table

| Pattern | Static Factory | Constructor | Builder |
|---|---|---|---|
| Can have name | Yes | No | Via method names |
| Can return cached | Yes | No | No |
| Can return subtype | Yes | No | Yes (factory method) |
| Enforces invariants | At factory time | At construction | At build time |
| Optional parameters | Methods | Overloading/null | Optional setters |
| Readability (many params) | Poor | Poor | Excellent |
| Suitable for | Small APIs | Few, clear params | 4+ params |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*

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



