---
layout: default
title: "Java Core - L1 Types and Strings"
parent: "Java Core"
grand_parent: "SK Interview"
nav_order: 2
permalink: /java-core/l1-types-and-strings/
render_with_liquid: false
---

# Java Core - L1 Types and Strings

## Primitive Types and Autoboxing

### 🎯 Model Answer

**30 seconds:**
> Java has 8 primitive types - value types stored on the stack with no
> object overhead: `byte` (1 byte), `short` (2), `int` (4), `long` (8),
> `float` (4), `double` (8), `char` (2), `boolean` (1 bit/1 byte JVM-
> dependent). Each has a wrapper class (Integer, Long, Double, etc.)
> that adds object behavior for use in collections. Autoboxing is the
> compiler's automatic conversion between primitive and wrapper:
> `Integer x = 5` (boxing), `int y = x` (unboxing). The trap: autoboxing
> `null` unboxes to NullPointerException; excessive boxing kills performance.

**3 minutes (Senior):**
> Primitives exist because Java's object model has significant overhead:
> every object has a 16-byte header, a reference indirection, and heap
> allocation. An array of 1 million ints is 4MB on the stack or heap
> directly; an Integer[] is 4MB of references + 16MB of objects = 20MB.
> That's 5x more memory and far worse cache performance.
>
> Autoboxing traps: (1) `Integer x = null; int y = x;` throws NPE.
> (2) `==` comparison: `Integer.valueOf(127) == Integer.valueOf(127)` is
> true (cache), but `Integer.valueOf(128) == Integer.valueOf(128)` is false
> (different objects). (3) Autoboxing in loops creates massive GC pressure.
>
> Performance: use `int[]` not `Integer[]` for numeric arrays. Use
> `int` not `Integer` for local variables and parameters. Use
> `IntStream` not `Stream<Integer>` for numeric streams.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Discuss Project Valhalla's value types, how they'll
eliminate boxing overhead for generics, and the implications for
`ArrayList<int>`. Also discuss `Integer.valueOf()` cache bounds,
`System.identityHashCode()`, and float/double IEEE 754 precision issues.

*Adapting down:* "Primitive types are like the basic building blocks
of math - just a number, directly in memory. Wrapper types are those
same numbers in a box (object). The box lets you put them in a list,
but it's bigger and slower. Java automatically puts numbers in boxes
and takes them out (autoboxing/unboxing) when needed."

**Blank Mind Recovery:**

**(1) Restate:** "Primitive types - let me cover the 8 types, their
sizes, their wrapper classes, autoboxing mechanics, and performance traps."

**(2) First principles:** "From first principles: Java needs basic numeric
types for performance. An int is just 4 bytes. An Integer is an object
with 16 bytes header + 4 bytes value. Collections need objects, not
primitives, so wrappers bridge the gap."

**(3) Bridge:** "Primitives are like a number written on a sticky note.
Wrappers are that sticky note in an envelope. The envelope (object) lets
you mail it (put in collection) but adds bulk. Autoboxing automatically
puts things in envelopes and takes them out."

---

### 📘 Concept Explanation

**8 primitive types:**
```
Type      Size    Range                       Default  Wrapper
boolean   1 bit   true/false                  false    Boolean
byte      8-bit   -128 to 127                 0        Byte
short     16-bit  -32,768 to 32,767           0        Short
char      16-bit  '\u0000' to '\uffff'         '\u0000' Character
int       32-bit  -2^31 to 2^31-1             0        Integer
long      64-bit  -2^63 to 2^63-1             0L       Long
float     32-bit  ~1.4E-45 to ~3.4E+38        0.0f     Float
double    64-bit  ~4.9E-324 to ~1.8E+308      0.0d     Double
```

**Autoboxing mechanics:**
```java
// Compiler transforms these:
Integer boxed = 42;        // Integer.valueOf(42)
int unboxed = boxed;       // boxed.intValue()

List<Integer> list = new ArrayList<>();
list.add(5);               // list.add(Integer.valueOf(5))
int val = list.get(0);     // list.get(0).intValue()
```

**Integer cache: -128 to 127:**
```java
Integer a = 127;
Integer b = 127;
System.out.println(a == b); // true (same cached object)

Integer c = 128;
Integer d = 128;
System.out.println(c == d); // false (different objects)
// ALWAYS use .equals() for Integer comparison:
System.out.println(c.equals(d)); // true
```

**Floating-point precision:**
```java
// NEVER use == for float/double:
double a = 0.1 + 0.2;         // 0.30000000000000004
System.out.println(a == 0.3);  // false (!)
System.out.println(Math.abs(a - 0.3) < 1e-9); // true

// Use BigDecimal for financial calculations:
BigDecimal price = new BigDecimal("0.10");
BigDecimal tax = new BigDecimal("0.02");
BigDecimal total = price.add(tax); // exact: 0.12
```

---

### 💻 Code Example

> **Code walkthrough:** This example demonstrates the boxing trap in a
> loop. The BAD version autoboxes every iteration, creating one `Integer`
> object per iteration and putting GC pressure on the JVM. The GOOD
> version works with primitives throughout, eliminating all heap allocation.
> The null unboxing trap and Integer comparison trap are separate
> common failures shown explicitly.

```java
// BAD: autoboxing in loop creates 10,000 Integer objects:
Long sum = 0L;          // boxed!
for (int i = 0; i < 10_000; i++) {
    sum += i;           // unbox, add, re-box each iteration
}
// Creates 10,000 Long objects -> GC pressure

// GOOD: use primitives:
long sum = 0L;          // primitive
for (int i = 0; i < 10_000; i++) {
    sum += i;           // pure arithmetic, no boxing
}

// FAILURE: null unboxing NPE:
Integer value = getValueFromMap(); // may return null
int result = value;    // NPE if value is null!
// FIX:
int result = (value != null) ? value : 0;
// or use Optional:
int result = Optional.ofNullable(value).orElse(0);

// FAILURE: == comparison for Integer (wrong):
Integer x = 200, y = 200;
if (x == y) { ... }       // compares references - WRONG
if (x.equals(y)) { ... }  // compares values - CORRECT
```

> **Code walkthrough:** The boxed `Long sum` creates 10,000 temporary
> Long objects because `Long += int` unboxes, adds, and re-boxes on
> every iteration. The JVM must allocate and then GC all these objects.
> The primitive `long sum` version stays entirely in CPU registers.
> In benchmarks, the primitive version runs 5-10x faster on tight
> numeric loops. The null trap is the most dangerous in production:
> a database query returning null for a nullable numeric column will
> throw NPE when assigned to a primitive.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Java has 8 primitive types: boolean, byte, short, int, long, float,
> double, char. They're value types - stored by value in memory. Each
> has a wrapper class (Integer, Long, Double, etc.) that wraps them
> as objects for use in collections. Autoboxing is automatic conversion
> between primitive and wrapper. Key traps: null unboxing = NPE;
> use `.equals()` not `==` for Integer comparison.

---

**Senior / Staff (5+ years):**
> Primitive types exist for performance - no object header, stack or
> array allocation, no GC pressure. The Integer cache (-128 to 127)
> is a JVM optimization that makes `==` comparison accidentally work
> for small values but fail silently for larger values - a common bug.
> For numeric-intensive code: use primitive arrays (`int[]`), not
> wrapper arrays (`Integer[]`); use `IntStream` not `Stream<Integer>`;
> use `LongAdder` not `AtomicLong` in high-contention counters. Project
> Valhalla will let generics work with primitives (`List<int>`) without
> boxing, eliminating this entire class of performance issues.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Autoboxing is transparent and has no cost."**
Autoboxing creates heap objects. In tight loops or high-throughput
code, excessive boxing creates GC pressure and reduces cache locality.
Use `int/long` primitives for local variables and parameters unless
you specifically need a wrapper (null, collection, reflection).

**Misconception 2: "Integer comparison with == works fine."**
Only true for values -128 to 127 (JVM cache). For any Integer value
outside this range, `==` compares object references and returns false
even for equal values. Always use `.equals()` for wrapper comparison.

---

### 🚨 Failure Modes and Diagnosis

**Failure: NPE from null unboxing in stream.**
```java
// Failure:
Map<String, Integer> scores = getScores();
int total = scores.values().stream()
    .reduce(0, (a, b) -> a + b); // NPE if any value is null

// Fix: filter nulls or use mapToInt:
int total = scores.values().stream()
    .filter(Objects::nonNull)
    .mapToInt(Integer::intValue) // returns IntStream (no boxing)
    .sum();
```
Diagnosis: check for null values in the map/list before streaming.
`Objects::nonNull` filter or `Optional` wrapper.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Primitive vs wrapper types | 60 seconds |
| Autoboxing mechanics | 2 minutes |
| Integer cache behavior | 2 minutes |
| Float/double precision | 2 minutes |
| Boxing performance impact | 2-3 minutes |
| Null unboxing trap | 90 seconds |
| When to use each type | 2 minutes |

---

**Q1 (Primitive vs wrapper): Why does Java have both primitive and
wrapper types?**

A: Primitives exist for performance. Java's object model requires every
object to have a header (16 bytes on 64-bit JVM) plus the data. An
`int` (4 bytes) vs `Integer` (20 bytes) is a 5x size difference.
For numeric arrays: `int[1000]` is 4KB; `Integer[1000]` is 4KB of
references + 20KB of Integer objects = 24KB total. The reference
indirection also destroys CPU cache locality.

Wrappers are needed for: collections (`List<Integer>` - generics can't
use primitives), nullability (`Integer` can be null; `int` cannot),
reflection (primitives have no `Class.forName()`), utility methods
(`Integer.parseInt()`, `Integer.toBinaryString()`).

Project Valhalla (future Java) will introduce generic specialization,
allowing `List<int>` - eliminating this trade-off entirely.

*What separates good from great:* Know the specific use cases that
require wrappers: nullable numeric columns from databases, map keys
(HashMap requires objects), generic type parameters, and concurrent
structures (AtomicInteger wraps int for CAS operations). When you
see `Integer` vs `int` in an API, the choice reveals the API's
contract: `Integer` means "may be null" or "used generically";
`int` means "always has a value, used for computation."

---

**Q2 (Autoboxing mechanics): Explain exactly what the compiler does
for autoboxing and unboxing.**

A: Autoboxing is a compile-time syntactic transformation. The compiler
inserts explicit boxing/unboxing calls:

```java
// Source code:
Integer x = 5;          // autoboxing
int y = x;              // autounboxing
List<Integer> l = ...; l.add(3); // autoboxing in method call
int v = l.get(0);       // autounboxing from method return

// Compiler generates (bytecode equivalent):
Integer x = Integer.valueOf(5);
int y = x.intValue();
l.add(Integer.valueOf(3));
int v = l.get(0).intValue();
```

`Integer.valueOf()` uses the cache for -128 to 127; outside that range
it calls `new Integer(n)` (deprecated in Java 9).

Unboxing on null: `x.intValue()` where `x == null` throws NPE. The
compiler generates the unboxing call without null check. This is why
null unboxing produces NPE with no obvious cause in the stack trace.

*What separates good from great:* The compiler warns about some boxing
inefficiencies but not all. Production issue: `Integer i = Integer.parseInt(...)` -
then `if (i != null && i > 0)` - the `i > 0` comparison unboxes `i`.
If `i` is null, the null check should prevent NPE, but... no: `&&`
evaluates left to right with short-circuit, so this is safe. But
`if (i > 0 && i != null)` reversed order is NOT safe - `i > 0`
unboxes first, NPE if null. Consistent null-check-first is the rule.

---

**Q3 (Integer cache): What is the Integer cache and why can it cause bugs?**

A: `Integer.valueOf()` caches Integer objects for values -128 to 127
(inclusive). These are static final cached instances. Any call to
`Integer.valueOf()` (including autoboxing) for values in this range
returns the SAME object instance.

```java
Integer a = 100;   // Integer.valueOf(100) - cached instance
Integer b = 100;   // Integer.valueOf(100) - same cached instance
a == b;            // true (same object reference)

Integer c = 200;   // Integer.valueOf(200) - new object
Integer d = 200;   // Integer.valueOf(200) - different new object
c == d;            // false (different object references)
c.equals(d);       // true (same value)
```

The cache exists for performance (small values are very common, caching
avoids allocating the same Integer repeatedly) and is specified in the
JLS (Java Language Specification, Section 5.1.7).

The cache range is configurable: `-XX:AutoBoxCacheMax=<N>` can extend
the upper bound. But it's a non-standard JVM property; don't rely on it.

*What separates good from great:* The cache bug is one of the most
common Java interview traps. The dangerous form: code that works in
development (small IDs, -128 to 127) but fails in production (real
IDs, larger numbers). `Integer id1 = order.getId(); Integer id2 = event.getOrderId(); if (id1 == id2) {...}` - works for IDs 1-127, fails
silently for ID 128+. Rule: always use `.equals()` for reference type
comparison, never `==`. Use `==` only for reference identity check.

---

**Q4 (Float/double precision): Why shouldn't you use float/double for
currency or financial calculations?**

A: `float` and `double` use IEEE 754 binary floating-point
representation. Most decimal fractions (0.1, 0.2, 0.3) CANNOT be
represented exactly in binary floating point.

```
0.1 in binary is: 0.00011001100110011... (infinite repeating)
Stored as double: 0.1000000000000000055511151231257827021181583404541015625
0.2 in binary: 0.001100110011001100... (infinite repeating)
0.1 + 0.2 = 0.30000000000000004 (not 0.3)
```

**For currency use `BigDecimal`:**
```java
// BAD: float/double for money
double price = 0.10;
double tax = 0.02;
double total = price + tax; // 0.12000000000000001 - wrong!

// GOOD: BigDecimal with String constructor (not double constructor)
BigDecimal price = new BigDecimal("0.10"); // exact
BigDecimal tax = new BigDecimal("0.02");   // exact
BigDecimal total = price.add(tax);         // 0.12 - exact!
// DO NOT use: new BigDecimal(0.10) - inherits double imprecision!
```

Use `double` for: physics simulations, statistics, rendering, any
case where small rounding errors are acceptable.

*What separates good from great:* `BigDecimal` operations require
specifying `MathContext` for division and `RoundingMode` for any
operation that might produce infinite precision:
`price.divide(quantity, 2, RoundingMode.HALF_UP)`. The `scale`
(decimal places) must be managed explicitly. A common pattern:
store monetary values as `long` cents (`1050` = $10.50) to avoid
BigDecimal overhead in high-throughput systems, converting to
BigDecimal only for display.

---

**Q5 (Boxing performance): How does autoboxing affect performance in
a high-throughput system?**

A: Autoboxing impacts: heap allocation rate, GC frequency, and CPU
cache locality.

Allocation cost: each boxing operation allocates an object on the heap.
For a counter that receives 100K events/second, `Long count = 0L;
count += 1;` creates and discards 100K Long objects per second - GC
must collect them all.

Cache locality: `int[]` stores values contiguously - 100 ints = 400
bytes, fits in L1 cache. `Integer[]` stores 100 pointers (400 bytes)
pointing to 100 scattered Integer objects = ~2000 bytes, many cache
misses.

**Profiling boxing:**
```bash
# JVM allocation profiling:
java -XX:+PrintGCDetails -jar app.jar
# High "young gen" GC = boxing in hot path

# JFR allocation events:
jcmd <pid> JFR.start settings=profile duration=30s
# Look for: java.lang.Integer, java.lang.Long in top allocations
```

**Fixes:**
- `int/long` local variables and parameters
- `IntStream`/`LongStream` instead of `Stream<Integer>`
- `int[]`/`long[]` instead of `List<Integer>`
- `EnumMap`, `HashMap` with primitive value libraries (Eclipse Collections)

*What separates good from great:* JVM JIT can eliminate boxing for
short-lived objects via escape analysis (if the Integer never leaves
the method, the JVM may allocate on stack or eliminate entirely).
But this is not guaranteed and hard to verify. Eliminate boxing
in hot paths explicitly - don't rely on JIT to fix it. Use
async-profiler or JFR allocation profiling to identify boxing in
production hot paths.

---

**Q6 (Null unboxing trap): Describe a production bug caused by null
unboxing.**

A: Scenario: a REST endpoint receives a JSON body with optional numeric
field. Jackson deserializes it to a DTO. If the JSON field is absent,
Jackson sets the field to `null` (for wrapper types).

```java
// DTO:
public class OrderRequest {
    private Integer quantity; // nullable from JSON
}

// Service:
public void processOrder(OrderRequest req) {
    int qty = req.getQuantity(); // NullPointerException if absent
    if (qty > 0) {
        // ...
    }
}
```

This produces NPE with stack trace pointing to the assignment line,
not the null source. Confusing for developers who see `int qty = ...`
and don't immediately think "NPE here".

**Fix patterns:**
```java
// Option 1: null check
int qty = req.getQuantity() != null ? req.getQuantity() : 0;

// Option 2: Optional
int qty = Optional.ofNullable(req.getQuantity()).orElse(0);

// Option 3: change DTO to primitive + default value
// (Jackson uses 0 as default for int)
private int quantity = 0; // never null
```

*What separates good from great:* The best fix is domain-driven:
if `quantity` being absent is a validation error (required field),
add a `@NotNull` validation constraint and reject the request early.
If absent means "default to X", use a default value in the primitive
field or a `@JsonProperty` default. The NPE is a symptom; the root
cause is missing input validation at the system boundary.

---

**Q7 (When to use each type): Walk through the decision: int, Integer,
long, BigDecimal - when to use each?**

A:

| Use Case | Type | Reason |
|---|---|---|
| Loop counters, indices | `int` | Primitive, no boxing |
| Numeric computation | `int/long` | Primitive arithmetic |
| Large numbers (>2 billion) | `long` | int max = ~2.1 billion |
| Monetary amounts | `BigDecimal` | Exact decimal |
| DB nullable int column | `Integer` | Can be null |
| Collection element | `Integer` / `Long` | Generics require objects |
| Atomic counter (concurrency) | `AtomicLong` | Thread-safe primitives |
| High-freq numeric array | `int[]` / `long[]` | No boxing, cache-friendly |
| Bit flags | `int` with bit ops | Efficient flag representation |

```java
// Database nullable column pattern:
@Column(name = "discount_percent", nullable = true)
private Integer discountPercent; // null = no discount applied

// Compute with null safety:
int effectiveDiscount =
    discountPercent != null ? discountPercent : 0;
```

*What separates good from great:* The choice between `int` and `Integer`
communicates intent in APIs. A method signature `void process(int count)`
says "count is always present." `void process(Integer count)` says "count
might be null - handle it." APIs with `Integer` parameters that don't
handle null are bugs waiting to happen. Review method signatures in
code reviews: any `Integer`/`Long` parameter should have documented
nullability semantics.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: tabular representation of primitives already provided)*

---

---

## String Class and String Pool

### 🎯 Model Answer

**30 seconds:**
> `String` in Java is immutable: once created, its character data
> cannot change. The JVM maintains a String pool (intern pool) for
> string literals - identical literal strings share one object.
> Operations like `concat`, `substring`, and `replace` create new
> String objects, not modify the original. For repeated string
> construction, use `StringBuilder` (single-threaded) or
> `StringBuffer` (thread-safe, but slower). Immutability makes
> Strings safe to share across threads without synchronization.

**3 minutes (Senior):**
> String immutability enforces the invariant that strings used as
> HashMap keys cannot be mutated after insertion (critical for
> hash-based correctness). The String pool allows literal comparison
> with `==` for pooled strings, but `new String("x")` bypasses the
> pool, creating a distinct object. `String.intern()` can add any
> string to the pool.
>
> Java 9+ changed String internal representation: `byte[]` (compact
> strings) instead of `char[]`. ASCII strings use 1 byte per character;
> non-ASCII uses 2 bytes. This halves memory for ASCII strings.
> Java 11 introduced `String.repeat()`, `strip()` (Unicode-aware), and
> `isBlank()`. Java 15 introduced text blocks (triple-quote strings).
> `StringBuilder` is not thread-safe. `StringBuffer` is synchronized.
> For concurrent string building: use local `StringBuilder` per thread
> (shared-nothing pattern).

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "String immutability - let me cover why Strings are
immutable, the String pool, StringBuilder vs String, and the Java 9
compact string optimization."

**(2) First principles:** "From first principles: mutable strings would
cause problems when used as Map keys (changing the key would break the
map's hash structure), in thread-safe code (two threads could mutate
the same string), and in security contexts (a filename you validated
could be changed before the system call)."

**(3) Bridge:** "A String is like a printed contract - you can read it,
copy it, or make a new contract with modifications, but you can't change
the original text."

---

### 📘 Concept Explanation

**Immutability benefits:**
1. Thread safety: shared across threads without synchronization
2. HashMap key safety: key hash can never change after insertion
3. Security: passwords, file paths cannot be mutated after validation
4. Caching: computed `hashCode()` cached in the String object (field)

**String pool mechanics:**
```java
String a = "hello";        // from string pool (literal)
String b = "hello";        // same object from pool
a == b;                    // true (same reference from pool)

String c = new String("hello"); // bypasses pool, new object
a == c;                    // false (different objects)
a.equals(c);               // true (same content)

// Force into pool:
String d = c.intern();     // returns pooled "hello"
a == d;                    // true (same pooled reference)
```

**StringBuilder vs String:**
```java
// SLOW: string concatenation in loop creates N strings:
String result = "";
for (String item : items) {
    result += item + ","; // creates new String each iteration
}

// FAST: StringBuilder, one mutable buffer:
StringBuilder sb = new StringBuilder();
for (String item : items) {
    sb.append(item).append(',');
}
String result = sb.toString(); // one allocation at the end
```

**Java 9 compact strings:**
- ASCII string: `byte[length]` (1 byte/char) - 50% less memory
- Latin-1/non-ASCII: `byte[length * 2]` (2 bytes/char)
- JVM flag: `-XX:-CompactStrings` to disable (rarely needed)

---

### 💻 Code Example

> **Code walkthrough:** The loop concatenation example is a classic
> Java performance trap. `result += item` compiles to `result =
> new StringBuilder(result).append(item).toString()` - creating two
> temporary objects per iteration. For 1000 items: 2000 object
> allocations. The StringBuilder version creates one buffer and
> reuses it throughout the loop, with a single `toString()` allocation
> at the end. The `==` trap is the most common String bug in Java code.

```java
// BAD: == for string comparison
String userInput = getUserInput();
if (userInput == "admin") { // WRONG: compares references
    grantAccess();
}
// GOOD: equals() for string comparison
if ("admin".equals(userInput)) { // null-safe if literal on left
    grantAccess();
}

// BAD: string concatenation in loop
String query = "SELECT * FROM users WHERE id IN (";
for (int id : ids) {
    query += id + ","; // O(N^2) time, N string allocations
}

// GOOD: StringBuilder
StringBuilder query = new StringBuilder(
    "SELECT * FROM users WHERE id IN (");
for (int id : ids) {
    query.append(id).append(',');
}
if (!ids.isEmpty()) {
    query.deleteCharAt(query.length() - 1); // remove trailing comma
}
query.append(')');
String result = query.toString();

// Java 15+: text blocks
String json = """
    {
        "name": "Alice",
        "age": 30
    }
    """; // indentation stripped by compiler
```

> **Code walkthrough:** The null-safe comparison pattern `"literal".equals(var)`
> is preferred over `var.equals("literal")` because it never throws NPE
> when `var` is null. The StringBuilder `deleteCharAt` pattern removes the
> trailing comma from ID list construction - a common query-building
> operation. Java 11+ offers `String.join(",", ids)` and
> `StringJoiner` as cleaner alternatives for delimiter-separated lists.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Strings are immutable - you can't change a String's content after
> creation. String literals share pool objects; `new String()` creates
> a new object. Always use `.equals()` to compare strings, not `==`.
> Use `StringBuilder` for repeated string construction (loops, building
> messages). String is thread-safe because it's immutable; StringBuilder
> is not thread-safe.

---

**Senior / Staff (5+ years):**
> String immutability is a cornerstone for HashMap correctness and thread
> safety. The pool reduces memory for literal strings. Java 9's compact
> strings (byte[] internally) halved String memory for ASCII-heavy
> workloads - important for applications storing millions of strings
> (caches, large JSON payloads). For high-throughput string building:
> pre-size StringBuilder (`new StringBuilder(estimatedCapacity)`) to
> avoid internal array resizing. For string interning: `intern()` can
> save memory for many repeated strings (e.g., field names in large
> datasets) but adds JNI overhead per intern call. Prefer explicit
> pooling (Map<String, String>) over intern() for performance-critical paths.

---

### ⚠️ Common Misconceptions

**Misconception 1: "`+` concatenation is always bad."**
The compiler optimizes `+` concatenation for non-loop contexts:
`String s = "Hello, " + name + "!"` compiles to a single `StringBuilder`
chain. The performance concern is ONLY in loops where a new StringBuilder
is created each iteration. Modern JIT also eliminates redundant
StringBuilder in simple cases.

**Misconception 2: "StringBuffer is better than StringBuilder because
it's thread-safe."**
StringBuffer's synchronization adds overhead even in single-threaded
code. Use `StringBuilder` unless you specifically need thread-safe
string building (rare - instead, use local StringBuilder per thread).

---

### 🚨 Failure Modes and Diagnosis

**Failure: `==` comparison returns false for equal strings.**
Symptom: `if (role == "ADMIN")` never matches even when role is "ADMIN".
Cause: `role` came from a database or user input, not a literal -
different object from pool.
Fix: always `"ADMIN".equals(role)` or `role.equals("ADMIN")`.
Diagnosis: add breakpoint, inspect object identity in debugger; check
if `==` vs `.equals()` is the discrepancy.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Why String is immutable | 60 seconds |
| String pool mechanics | 2 minutes |
| StringBuilder vs StringBuffer | 90 seconds |
| String comparison traps | 2 minutes |
| Java 9 compact strings | 2 minutes |
| String memory optimization | 2-3 minutes |
| Text blocks | 90 seconds |

---

**Q1 (Why immutable): Why is String immutable in Java?**

A: Four reasons:

1. **Thread safety:** immutable objects can be shared across threads
   without synchronization. A String passed to multiple threads cannot
   be corrupted.

2. **HashMap key safety:** if a String used as a HashMap key could be
   mutated, its hash code would change, making it unfindable in the map.
   Immutability guarantees the key's hash never changes.

3. **Security:** passwords, file paths, network addresses validated as
   Strings cannot be changed between validation and use (no TOCTOU race).

4. **String pool:** caching String objects in a pool only works if they
   can never change. If `"hello"` could be mutated, sharing it would
   corrupt all holders.

*What separates good from great:* The security argument is the deepest.
Consider: `File f = new File(path)` where `path` is a String argument.
If String were mutable, an attacker could give you a path you validate,
then mutate it to a different path before `f` is used. Java's immutable
String makes this attack impossible. C strings (char[]) are mutable,
which is one reason C programs are more vulnerable to path traversal
attacks.

---

**Q2 (String pool): How does the String pool work and when does
intern() help?**

A: The String pool (intern pool) is a JVM-level cache of String objects.
All string literals in bytecode are automatically interned. `String.intern()`
allows runtime-created strings to be added to the pool.

The pool is stored in the JVM's heap (Java 7+ - previously PermGen,
which caused PermGen OOM with many interned strings).

**When intern() helps:** when you have millions of repeated strings with
high duplication rate (e.g., field names, status codes, category names
read from database).

```java
// Memory scenario: 1M records, each with "ACTIVE"/"INACTIVE" status
// WITHOUT intern: 1M String objects (~40 bytes each) = ~40MB
// WITH intern: 2 String objects + 1M references (~8 bytes each) = ~8MB

List<String> statuses = dbQuery.getStatuses();
for (int i = 0; i < statuses.size(); i++) {
    statuses.set(i, statuses.get(i).intern()); // deduplicate
}
```

**When NOT to use intern:** unique strings (user names, URLs) - interning
adds JNI overhead without reducing duplicates. Consider a `Map<String,
String>` deduplication cache instead.

*What separates good from great:* Java 8+ has the `-XX:StringTableSize`
JVM flag to resize the string table (default 60013 buckets). For
massive intern() use, increase it: `-XX:StringTableSize=1000003`.
`jcmd <pid> VM.stringtable` reports table statistics. Modern best
practice: prefer explicit object identity (enums, IDs) over string
interning for semantic deduplication.

---

**Q3 (StringBuilder vs StringBuffer): When do you use StringBuilder
vs StringBuffer?**

A: Nearly always `StringBuilder`. `StringBuffer` is thread-safe
(all methods synchronized) but adds synchronization overhead even
in single-threaded use. Java's designers have stated that `StringBuffer`
is effectively obsolete.

The correct pattern for concurrent string building is not `StringBuffer`
but rather: thread-local `StringBuilder` (each thread has its own),
or synchronize at a higher level, or use `String.join()` for simple cases.

```java
// WRONG: StringBuffer for thread safety
class LogFormatter {
    private final StringBuffer sb = new StringBuffer(); // over-engineered
    synchronized void append(String s) { sb.append(s); }
}

// RIGHT: local StringBuilder per operation
class LogFormatter {
    String format(List<String> entries) {
        StringBuilder sb = new StringBuilder(); // local, no sharing
        for (String e : entries) sb.append(e).append('\n');
        return sb.toString();
    }
}
```

`StringBuffer` exists for historical compatibility. It was the only
option before Java 5. `StringBuilder` was added in Java 5 as the
non-synchronized alternative.

*What separates good from great:* The performance difference is measurable
but rarely the bottleneck. More important: `StringBuffer` in code signals
the original author was worried about thread safety. If you inherit code
using `StringBuffer`, investigate the threading model - were they correct
to be concerned? Is there shared mutable state that needs fixing? The
`StringBuffer` is often a symptom of a larger concurrency design issue.

---

**Q4 (String comparison traps): What are the common String comparison
pitfalls?**

A:

**Trap 1: `==` instead of `.equals()`**
```java
// WRONG:
if (status == "ACTIVE") { ... }  // almost certainly wrong

// RIGHT:
if ("ACTIVE".equals(status)) { ... }  // null-safe and value-based
if (Objects.equals(status, "ACTIVE")) { ... } // null-safe both sides
```

**Trap 2: `.equals()` on potentially null reference**
```java
String s = null;
s.equals("test"); // NPE!
"test".equals(s); // safe - returns false
Objects.equals(s, "test"); // safe - handles null on both sides
```

**Trap 3: case sensitivity**
```java
// WRONG for case-insensitive comparison:
if (type.equals("json")) { ... }

// RIGHT:
if ("json".equalsIgnoreCase(type)) { ... }
```

**Trap 4: `compareTo()` for alphabetical sort (locale issues)**
```java
// WRONG for locale-sensitive text:
list.sort(String::compareTo);

// RIGHT for user-facing text:
list.sort(Collator.getInstance(Locale.US)::compare);
```

*What separates good from great:* In a code review, any `string1 ==
string2` comparison is a bug unless one of the operands is interned
or is a known literal and you are explicitly checking object identity.
The `Objects.equals(a, b)` pattern is the safest and most readable
for equality with nullable strings. Spring Security commonly compares
strings with `StringUtils.hasText()` (null + blank check) and
`passwordEncoder.matches()` (timing-safe comparison for passwords).

---

**Q5 (Compact strings): What changed in Java 9 String representation?**

A: Before Java 9: `String` stored characters as `char[]`, where each
`char` is 2 bytes (UTF-16). All strings, even pure ASCII, used 2 bytes
per character.

Java 9 (JEP 254 - Compact Strings): `String` stores characters as
`byte[]` with an encoding flag:
- If all characters fit in Latin-1 (codepoints 0-255): 1 byte/char
- Otherwise (any char > 255): 2 bytes/char (UTF-16 encoded)

Impact: ASCII and Latin-1 strings use half the memory. Significant
for typical English-language applications where most strings are ASCII.

Benchmark (from JEP 254): 10-15% reduction in heap for typical server
workloads (mostly ASCII strings).

No API change: the change is internal, transparent to application code.
Disabled with `-XX:-CompactStrings` (rarely needed, e.g., heavy
non-Latin string workloads where the encoding check has overhead).

*What separates good from great:* The encoding flag is stored as a byte
field in the String object. String operations check this flag and use
fast paths for Latin-1 strings (byte operations) vs UTF-16 strings
(char operations). For applications serving non-Latin content (Chinese,
Japanese, Arabic), compact strings provide less benefit and have a small
overhead for the flag check. Profile before assuming compact strings
help in your specific workload.

---

**Q6 (String memory optimization): How do you reduce String memory
usage in a JVM with millions of strings?**

A:

**1. Avoid unnecessary string creation:**
```java
// BAD: new String per log message
logger.info(new StringBuilder("User ").append(id).toString());
// GOOD: use format strings (lazy evaluation):
logger.info("User {}", id); // SLF4J - only formats if level enabled
```

**2. Deduplication via G1GC:**
JVM flag: `-XX:+UseStringDeduplication` (Java 8u20+, requires G1GC)
GC identifies identical String objects and replaces their backing
`byte[]` with a shared copy. Reduces live heap for duplicate strings
without changing references.
```bash
java -XX:+UseG1GC -XX:+UseStringDeduplication \
     -XX:+PrintStringDeduplicationStatistics -jar app.jar
```

**3. Manual deduplication via intern():**
For high-duplication fields (status codes, categories), intern strings
at the point of creation.

**4. Use byte[] or char[] for very large text:**
For in-memory document processing, work with `byte[]` buffers instead
of String; convert to String only at boundaries.

*What separates good from great:* `-XX:+UseStringDeduplication` is the
easiest win for applications with many duplicate strings (e.g., a cache
storing JSON with repeated field names). It runs during GC, no code
change needed. Check with `-XX:+PrintStringDeduplicationStatistics`
to see deduplication rate. If 40%+ of strings are deduplicated, it's
worth enabling. It does add a small GC overhead (comparing string contents
during GC), so measure the trade-off.

---

**Q7 (Text blocks): What are text blocks and when should you use them?**

A: Text blocks (final in Java 15, JEP 355) are multiline string literals
using triple-quote `"""` syntax. The compiler strips common leading
whitespace and normalizes line endings.

```java
// BEFORE (Java 14 and earlier):
String json = "{\n"
    + "  \"name\": \"Alice\",\n"
    + "  \"age\": 30\n"
    + "}";

// AFTER Java 15+:
String json = """
    {
      "name": "Alice",
      "age": 30
    }
    """;
// ^ trailing """ on its own line adds a trailing newline
// No trailing newline:
String json = """
    {
      "name": "Alice"
    }"""; // """ on same line as last content

// Indentation: the compiler removes leading whitespace common to all
// lines, aligned to the closing """. Incidental whitespace stripped.
```

Use cases: SQL queries, JSON/XML templates, HTML templates, multiline
test assertions.

**String templates (Java 21 preview):**
```java
// Interpolation syntax (preview in Java 21):
String name = "Alice";
int age = 30;
String msg = STR."Hello \{name}, you are \{age} years old.";
```

*What separates good from great:* Text blocks eliminate escape hell
for SQL and JSON in tests. Important: the closing `"""` position
controls indentation stripping. `"""` on a new line with 4 spaces of
indentation = 4 spaces stripped from all lines. If a line has less
indentation than the closing `"""`, a compile error occurs. Use your
IDE's formatter to handle this automatically - IntelliJ auto-formats
text block indentation correctly.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept adequately described in prose)*

---

---

## equals() and hashCode() Contract

### 🎯 Model Answer

**30 seconds:**
> `equals()` and `hashCode()` must be consistent: if two objects are
> equal (`a.equals(b)` is true), they MUST have the same `hashCode()`.
> Breaking this contract causes objects to "disappear" from HashMaps
> and HashSets - you put an object in and can never find it again.
> Both methods are inherited from `Object` (identity equality/identity
> hash). Always override both together - never one without the other.
> Use `Objects.equals()` and `Objects.hash()` (utility methods) to
> implement them correctly.

**3 minutes (Senior):**
> The contract is: (1) equals is reflexive, symmetric, transitive,
> consistent, and x.equals(null) == false. (2) If a.equals(b) then
> a.hashCode() == b.hashCode(). The converse is not required: hash
> collision (same hash, different objects) is allowed and handled by
> the hash bucket's linked list/tree.
>
> hashCode design: good hash functions minimize collisions. Java
> recommends `Objects.hash(field1, field2, ...)` which uses prime
> multiplication (31 * result + field.hashCode()). All-zero hashCode()
> is legal but terrible for HashMap performance (all objects end
> up in bucket 0).
>
> Mutable fields in equals/hashCode: never use mutable fields as
> HashMap keys. If you change a field used in hashCode after insertion,
> the object is in the wrong bucket - it's lost. Make key classes
> immutable or don't include mutable fields.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "equals() and hashCode() contract - let me cover
the required properties, how HashMap uses them, why they must be
consistent, and how to implement them correctly."

**(2) First principles:** "From first principles: HashMap stores objects
in buckets by hash code, then uses equals() to find the exact object
within a bucket. If hashCode() returns different values for equal objects,
they end up in different buckets - equals() is never called to find them."

**(3) Bridge:** "HashMap is like a library. hashCode() is the floor
and shelf number (the bucket). equals() is the book title check.
If 'Java Programming' is filed on floor 2, shelf 3, but hashCode()
says look on floor 5, shelf 7 - you'll never find the book even
though it exists."

---

### 📘 Concept Explanation

**The contract requirements:**

```
equals() contract (from Object.equals() Javadoc):
  Reflexive:   a.equals(a) == true
  Symmetric:   a.equals(b) == b.equals(a)
  Transitive:  if a.equals(b) && b.equals(c) then a.equals(c)
  Consistent:  repeated calls return same result (if object unchanged)
  Null:        a.equals(null) == false (never throws NPE)

hashCode() contract (from Object.hashCode() Javadoc):
  Consistent:  repeated calls return same int (if object unchanged)
  Required:    if a.equals(b) then a.hashCode() == b.hashCode()
  Recommended: if !a.equals(b) then a.hashCode() != b.hashCode()
               (minimize collisions)
```

**How HashMap uses equals/hashCode:**
```
put(key, value):
  1. bucket = key.hashCode() % capacity
  2. store entry in bucket[bucket]

get(key):
  1. bucket = key.hashCode() % capacity
  2. search bucket for entry where entry.key.equals(key)
  3. return found entry.value, or null

If hashCode is different for equal keys:
  put goes to bucket A; get goes to bucket B -> not found
```

---

### 💻 Code Example

> **Code walkthrough:** The BAD class overrides only `equals`, breaking
> the contract. Two `BadKey` objects with the same ID would be "equal"
> via `equals()` but have different hash codes (from Object's identity-
> based hashCode). HashMap would place them in different buckets and
> never find one using the other as a lookup key. The GOOD class uses
> `Objects.equals()` (null-safe) and `Objects.hash()` (prime-based
> combination) to implement both consistently.

```java
// BAD: only equals overridden (breaks HashMap contract):
class BadKey {
    int id;
    // hashCode inherited from Object (identity-based)
    @Override public boolean equals(Object o) {
        if (!(o instanceof BadKey)) return false;
        return ((BadKey) o).id == this.id;
    }
}
// Result:
BadKey k1 = new BadKey(1), k2 = new BadKey(1);
k1.equals(k2); // true
k1.hashCode() != k2.hashCode(); // different (broken contract)
Map<BadKey, String> map = new HashMap<>();
map.put(k1, "value");
map.get(k2); // null - can't find it! (different hash bucket)

// GOOD: both equals and hashCode:
class GoodKey {
    final int id;
    final String name;
    GoodKey(int id, String name) {
        this.id = id; this.name = name;
    }
    @Override public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof GoodKey)) return false;
        GoodKey other = (GoodKey) o;
        return id == other.id
            && Objects.equals(name, other.name);
    }
    @Override public int hashCode() {
        return Objects.hash(id, name);
    }
}
```

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Override both equals() and hashCode() together - always. If a.equals(b)
> then a.hashCode() must equal b.hashCode(). Breaking this makes HashMap
> and HashSet lose objects. Use `Objects.equals()` and `Objects.hash()`
> to implement them correctly and avoid NPEs. Never override just one
> without the other.

---

**Senior / Staff (5+ years):**
> The equals/hashCode contract is the foundation of all hash-based
> collections. Mutable objects as map keys violate the contract if fields
> used in hashCode change after insertion - the object ends up in the
> wrong bucket. Immutable value objects (records in Java 14+) automatically
> get correct equals/hashCode. Records generate field-based implementations
> by default - perfect for use as map keys. For custom equals, consider
> what "equality" means in the domain: identity equality (same object),
> structural equality (same fields), or domain equality (same ID). Choose
> deliberately.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Overriding equals() is sufficient."**
Without consistent hashCode(), the object "disappears" from HashMaps
and HashSets. The equals() contract says nothing about hash codes.
Always check: if two objects would be equals, do they compute the
same hashCode? If not, you have a bug.

**Misconception 2: "hashCode() must be unique."**
Hash collision (different objects same hash code) is allowed and
expected. HashMap handles it via chaining (bucket linked list/tree
in Java 8+). The requirement is only: equal objects must have equal
hash codes. Collisions degrade performance (O(n) bucket search) but
are not incorrect.

---

### 🚨 Failure Modes and Diagnosis

**Failure: object "disappears" from HashMap after field mutation.**
```java
// Bug scenario:
class MutableKey { int id; String status; ... }
Map<MutableKey, String> map = new HashMap<>();
MutableKey key = new MutableKey(1, "ACTIVE");
map.put(key, "data");
key.status = "INACTIVE"; // mutates field used in hashCode
map.get(key); // null - wrong bucket now!
// Fix: use immutable keys, or don't include mutable fields
// in hashCode/equals
```
Diagnosis: check if hashCode implementation includes mutable fields.
Test by putting, mutating, and getting - should find null.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| equals/hashCode contract | 60 seconds |
| HashMap mechanics | 2-3 minutes |
| Mutable key bug | 2-3 minutes |
| hashCode quality | 2 minutes |
| Records and equals | 90 seconds |
| Symmetric equals pitfall | 2 minutes |
| equals with inheritance | 2-3 minutes |

---

**Q1 (Contract): State the equals/hashCode contract.**

A: Two rules from the Java specification:

**equals() contract:**
- Reflexive: `x.equals(x)` is always true
- Symmetric: `x.equals(y)` iff `y.equals(x)`
- Transitive: if `x.equals(y)` and `y.equals(z)`, then `x.equals(z)`
- Consistent: same result on repeated calls (no side effects)
- Null safety: `x.equals(null)` always returns false (never NPE)

**hashCode() contract:**
- Consistent: repeated calls return same int (unless object state changes)
- If `x.equals(y)` then `x.hashCode() == y.hashCode()`
  (the ONLY hard requirement linking the two)
- Optional but strongly recommended: if `!x.equals(y)` then different hash
  (minimize collisions for performance)

*What separates good from great:* The subtle point is: the contract
does NOT require that unequal objects have different hash codes. That's
just a recommendation for performance. What IS required: if you override
equals to make two objects "equal", you MUST also ensure their hash codes
are the same. HashMap's algorithm first computes hash to find the bucket,
then calls equals within the bucket. A broken contract means the get
never reaches the equals call.

---

**Q2 (HashMap mechanics): How does HashMap use equals() and hashCode()
internally?**

A: HashMap uses a two-phase lookup:

```
Phase 1 (hashCode): which bucket?
  bucket = (n - 1) & hash(key.hashCode())
  n = table length (power of 2)
  hash() = additional spreading to reduce collisions

Phase 2 (equals): which entry in the bucket?
  for each entry in bucket:
      if entry.hash == hash && (entry.key == key
                                || key.equals(entry.key))
          return entry.value
```

Java 8 improvement: when a bucket's linked list exceeds 8 entries,
it's converted to a tree (TreeNode, Red-Black tree) for O(log n) vs
O(n) lookup on heavily collided buckets. This requires keys to be
`Comparable` for treeification.

**If hashCode is broken:**
- All keys may hash to the same bucket -> O(n) lookup (or O(log n))
- The worst case: `hashCode()` returns 0 for everything -> one giant
  bucket -> HashMap degrades to O(n) linked list

*What separates good from great:* The Java 8 treeification of buckets
was motivated by hash DoS attacks. An adversary who knows your hash
function can craft keys that all collide into one bucket, making HashMap
O(n) per get. Java 8 treeifies to O(log n), limiting the damage.
For security-sensitive code: use `String.hashCode()` which is not secret
(predictable). Spring Security's `Hmac` is used to hash sensitive
request parameters before putting in maps.

---

**Q3 (Mutable key bug): Describe the mutable HashMap key bug with example.**

A:
```java
// The trap:
class User {
    int id;
    String name;

    @Override public boolean equals(Object o) {
        if (!(o instanceof User)) return false;
        return id == ((User) o).id && name.equals(((User) o).name);
    }
    @Override public int hashCode() {
        return Objects.hash(id, name); // name is MUTABLE!
    }
}

Map<User, String> roles = new HashMap<>();
User alice = new User(1, "Alice");
roles.put(alice, "ADMIN");   // stored in bucket = hash("Alice")

alice.name = "ALICE";        // mutate the name!
roles.get(alice);            // looks in bucket = hash("ALICE")
                             // different bucket -> returns null!
roles.containsKey(alice);    // false - "lost" the entry
```

**Fix options:**
1. Make key class immutable: `final class User { final String name; }`
2. Don't use mutable fields in hashCode: only use `id`
3. Don't use this class as a map key (use the ID directly)

*What separates good from great:* This bug is insidious because the
map doesn't throw an exception - it silently returns null. If you
subsequently `put` with the mutated key, you create a SECOND entry
in the map with the new hash, while the original entry still exists
in the old bucket. Iterating the map would reveal two entries for
"the same object". Production diagnosis: `HashMap.size()` keeps
growing, or lookups always miss despite puts succeeding.

---

**Q4 (hashCode quality): What makes a good hashCode implementation?**

A: A good hash function minimizes collisions and distributes entries
evenly across buckets.

**Properties of a good hashCode:**
1. Fast to compute
2. Even distribution across the int range
3. Different for "obviously different" objects
4. Consistent with equals

**Effective Java recipe (still the best):**
```java
@Override public int hashCode() {
    int result = 17;              // non-zero prime seed
    result = 31 * result + field1.hashCode();
    result = 31 * result + (field2 != null ? field2.hashCode() : 0);
    result = 31 * result + field3;  // primitive
    return result;
}

// Modern equivalent:
@Override public int hashCode() {
    return Objects.hash(field1, field2, field3);
    // Uses 31*result + ... internally
}
```

**Why 31?** It's an odd prime, close to a power of 2, and JVMs optimize
`31 * i` as `(i << 5) - i` (shift + subtract, no multiply needed).

**Bad hashCodes:**
```java
return 0; // all objects in one bucket -> O(n) everywhere
return id; // only uses one field - misses other distinguishing data
return field1.hashCode() ^ field2.hashCode(); // XOR is symmetric;
          // Point(1,2).hashCode() == Point(2,1).hashCode() -> collision
```

*What separates good from great:* For immutable classes: cache the
hash code. `String` computes hash on first call and caches it in a field.
For mutable classes: never cache (may change). Java's `record` generates
field-based hashCode automatically - the standard implementation using
`Objects.hash()`. Use records for value objects instead of manual
hashCode.

---

**Q5 (Records and equals): How do records handle equals() and hashCode()?**

A: Records (Java 14+, final in Java 16) automatically generate `equals()`,
`hashCode()`, and `toString()` based on all record components.

```java
record Point(int x, int y) {}

// Auto-generated (equivalent to):
@Override public boolean equals(Object o) {
    if (!(o instanceof Point p)) return false;
    return x == p.x && y == p.y;
}
@Override public int hashCode() {
    return Objects.hash(x, y);
}
@Override public String toString() {
    return "Point[x=" + x + ", y=" + y + "]";
}
```

Records are ideal as HashMap keys: immutable (fields are final),
correct equals/hashCode, and minimal boilerplate.

You can override the generated methods:
```java
record CaseInsensitiveName(String value) {
    @Override public boolean equals(Object o) {
        if (!(o instanceof CaseInsensitiveName n)) return false;
        return value.equalsIgnoreCase(n.value);
    }
    @Override public int hashCode() {
        return value.toLowerCase().hashCode();
    }
}
```

*What separates good from great:* When customizing equals for a record,
you MUST also customize hashCode to maintain the contract. The compiler
does not check this - it's your responsibility. Also: record equality
compares ALL components. If you want partial equality (two records equal
if their IDs match, ignoring other fields), records are not ideal -
use a regular class with explicit equals/hashCode.

---

**Q6 (Symmetric equals pitfall): What's the symmetric equals pitfall
with inheritance?**

A: The Liskov Substitution Principle conflicts with equals in inheritance
hierarchies. A common mistake: making a subclass's equals compare with
the parent class.

```java
class Animal { String species; }
class Dog extends Animal { String breed; }

// BROKEN: asymmetric equals
@Override // in Dog:
public boolean equals(Object o) {
    if (o instanceof Animal a) { // accepts Animal!
        return species.equals(a.species);
    }
    return false;
}

Animal a = new Animal("Canis");
Dog d = new Dog("Canis", "Labrador");
a.equals(d); // false (Animal.equals uses Object identity)
d.equals(a); // true (Dog.equals accepts Animal!)
// Violates symmetry!
```

**Fix: use getClass() instead of instanceof for inheritance:**
```java
// In Dog:
@Override public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    Dog dog = (Dog) o;
    return Objects.equals(species, dog.species)
        && Objects.equals(breed, dog.breed);
}
```

Effective Java recommends: "There is no way to extend an instantiable
class and add a value component while preserving the equals contract."
Use composition over inheritance for value objects.

*What separates good from great:* `instanceof` vs `getClass()` is a
classic Effective Java debate. `instanceof` allows subclass instances
to be "equal" to parent instances (useful for polymorphism), but
violates symmetry when the subclass adds value fields. `getClass()`
is strict: only same-class objects can be equal (correct contract,
less polymorphic). For sealed hierarchies with pattern matching,
record-based approaches eliminate this entirely: each case is a
distinct record type with its own equals.

---

**Q7 (equals with inheritance): What is the canonical equals
implementation pattern for a non-final class?**

A:
```java
public class Person {
    private final String name;    // immutable field
    private final int age;        // immutable field

    public Person(String name, int age) {
        this.name = Objects.requireNonNull(name);
        this.age = age;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;          // 1. identity check (fast path)
        if (!(o instanceof Person)) return false; // 2. type check
        Person other = (Person) o;           // 3. safe cast
        return age == other.age              // 4. compare primitives first
            && Objects.equals(name, other.name); // 5. null-safe reference
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, age);      // consistent with equals
    }

    @Override
    public String toString() {
        return "Person[name=" + name + ", age=" + age + "]";
    }
}
```

Step explanation:
1. `this == o`: fast path, same reference always equal
2. `instanceof`: handles null (false if o is null) and type check
3. Cast: safe after instanceof check
4. Primitive first: cheap comparison, fail fast
5. `Objects.equals`: null-safe reference comparison

*What separates good from great:* Always implement `toString()` alongside
equals/hashCode. It has no contract requirements but is invaluable for
debugging. `System.out.println(person)` that shows `Person@7f3e5c` vs
`Person[name=Alice, age=30]` is the difference between hours of debugging.
IDEs generate all three together; records generate all three automatically.
In a code review, a class that overrides equals but not toString is
a missed opportunity.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ level - comparison table not required)*

---

### 🏛️ System Design

*(Omit: ★☆☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept adequately described in prose)*
