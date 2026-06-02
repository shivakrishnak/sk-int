---
layout: default
title: "Java Language - L1 Core Types"
parent: "Java Language"
grand_parent: "SK Interview"
nav_order: 2
permalink: /java-language/l1-core-types/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Language - L1 Core Types](#java-language---l1-core-types) | medium |

---

# Java Language - L1 Core Types

## Primitive Types and Wrapper Classes

---

### 🎯 Model Answer

**30 seconds:**
> Java has 8 primitive types: byte (8-bit), short (16-bit), int (32-bit), long (64-bit),
> float (32-bit IEEE 754), double (64-bit IEEE 754), char (16-bit Unicode), boolean.
> Each has a wrapper class (Integer, Long, Double, etc.) for use in collections and
> generics. Autoboxing (Java 5) automatically converts between primitive and wrapper.
> Key trade-off: primitives are faster and smaller; wrappers are needed for generic
> collections and can be null.

**3 minutes (Senior):**
> Primitives vs wrappers in practice:
>
> - **Memory**: `int` = 4 bytes. `Integer` = 16 bytes (8-byte object header + 4-byte
>   int field + 4-byte alignment padding). `int[]` of 1 million elements = 4MB.
>   `ArrayList<Integer>` of 1 million elements = 16MB (Integer objects) + 4MB (reference
>   array) = 20MB. 5x memory cost for the generic collection.
>
> - **Autoboxing gotchas**: `Integer.valueOf(n)` caches -128 to 127. `new Integer(128) == new Integer(128)` is `false` (identity comparison, two different objects).
>   `Integer.valueOf(128) == Integer.valueOf(128)` is also `false` (outside cache range).
>   Always use `.equals()` for wrapper comparisons.
>
> - **Null handling**: primitives cannot be null (compile error). Wrapper in a field: can
>   be null. Unboxing a null wrapper: NullPointerException. Common bug:
>   `int value = myObject.getIntegerField();` throws NPE if field is null.
>
> - **Numeric types in JVM**: `boolean`, `byte`, `short`, `char` are represented as
>   `int` in the JVM (padded to 32 bits). No byte arithmetic on the JVM - all promotes
>   to `int`. Only `long`, `float`, `double` have dedicated JVM types.

**Blank Mind Recovery:**

**(1) Restate:** "8 primitives: byte/short/int/long (integers), float/double (floating
point), char (Unicode), boolean. Wrappers: Integer, Long, Double, etc. Autoboxing:
automatic int <-> Integer. Key difference: primitives = faster, no null; wrappers =
needed for generics, can be null."

**(2) First principles:** "The JVM is most efficient with native types that map directly
to CPU registers (int, long, double). Objects have overhead: header, GC tracking, pointer
indirection. Primitives: no overhead. The dualism (primitives + wrappers) is the price
of JVM efficiency with OOP generality."

**(3) Bridge:** "Primitives are cash - fast, directly spendable. Wrapper classes are
bank accounts - each needs an address (reference), has overhead (header), but can be
used anywhere that accepts accounts (generics). Autoboxing is the ATM - converts cash
to account balance automatically, but charges a small fee (performance)."

---

### 📘 Concept Explanation

**Primitive types and their wrapper equivalents:**
```
JAVA PRIMITIVE TYPES:

Type    Size     Default  Min Value         Max Value
byte    8-bit    0        -128              127
short   16-bit   0        -32,768           32,767
int     32-bit   0        -2^31             2^31 - 1
long    64-bit   0L       -2^63             2^63 - 1
float   32-bit   0.0f     ~1.4e-45          ~3.4e38
double  64-bit   0.0d     ~4.9e-324         ~1.8e308
char    16-bit   '\u0000' 0                 65,535 (Unicode BMP)
boolean JVM-int  false    -                 -

WRAPPER CLASSES (java.lang):
  Primitive  -> Wrapper     Key constants/methods
  int        -> Integer     Integer.MAX_VALUE, .parseInt(), .toBinaryString()
  long       -> Long        Long.MAX_VALUE, .parseLong()
  double     -> Double      Double.isNaN(), .isInfinite(), .parseDouble()
  float      -> Float       Float.isNaN(), Float.compare(a, b)
  char       -> Character   Character.isLetter(), .isDigit(), .toUpperCase()
  boolean    -> Boolean     Boolean.parseBoolean()
  byte       -> Byte        Byte.parseByte()
  short      -> Short       Short.parseShort()

INTEGER CACHE (-128 to 127):
  Integer.valueOf(127) == Integer.valueOf(127)  // true (cached)
  Integer.valueOf(128) == Integer.valueOf(128)  // false (not cached)
  // Always use .equals() for wrapper comparison

AUTOBOXING / UNBOXING (Java 5):
  int a = 5;
  Integer obj = a;           // autoboxing: int -> Integer
  int b = obj;               // unboxing: Integer -> int
  // Compiler generates: Integer.valueOf(a) and obj.intValue()
  
  // Hidden NullPointerException:
  Integer nullable = null;
  int c = nullable;          // NPE: unboxing null Integer
```

> **Code walkthrough:** This L1 Core Types example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** This example shows the most common primitive/wrapper pitfalls:
> the integer cache comparison trap, unboxing NPE, and performance difference between
> primitive arrays and boxed collections.


```java
// BAD: using for-loop where Stream API is cleaner
List<String> results = new ArrayList<>();
for (Item item : items) {
    if (item.isActive()) {
        results.add(item.getName().toUpperCase());
    }
}
```


```java
// BAD: using for-loop where Stream API is cleaner
List<String> results = new ArrayList<>();
for (Item item : items) {
    if (item.isActive()) {
        results.add(item.getName().toUpperCase());
    }
}
```


```java
// BAD: using for-loop where Stream API is cleaner
List<String> results = new ArrayList<>();
for (Item item : items) {
    if (item.isActive()) {
        results.add(item.getName().toUpperCase());
    }
}
```


```java
// BAD: using for-loop where Stream API is cleaner
List<String> results = new ArrayList<>();
for (Item item : items) {
    if (item.isActive()) {
        results.add(item.getName().toUpperCase());
    }
}
```


```java
// BAD: using for-loop where Stream API is cleaner
List<String> results = new ArrayList<>();
for (Item item : items) {
    if (item.isActive()) {
        results.add(item.getName().toUpperCase());
    }
}
```

```java
// PRIMITIVE vs WRAPPER PITFALLS

// BAD: == comparison with wrappers (works for -128..127, fails elsewhere)
Integer a = 200;
Integer b = 200;
System.out.println(a == b);       // false (different objects)
System.out.println(a.equals(b));  // true (correct way)

// BAD: == comparison that happens to work (dangerous)
Integer x = 100;
Integer y = 100;
System.out.println(x == y);  // true (cached, but WRONG approach)
// If 100 changes to 200 later: silently breaks

// GOOD: always use .equals() for wrapper comparison
boolean same = Objects.equals(a, b);  // null-safe: returns false if either null

// BAD: unboxing NPE - very common bug
Integer value = getValueFromMap(key);  // may return null
int result = value * 2;               // NPE if value is null

// GOOD: null check before unboxing
Integer value = getValueFromMap(key);
int result = (value != null) ? value * 2 : 0;

// GOOD: or use Optional
Optional<Integer> maybeValue = Optional.ofNullable(getValueFromMap(key));
int result = maybeValue.map(v -> v * 2).orElse(0);

// PERFORMANCE: primitive array vs boxed list
// BAD: boxing overhead for number-heavy work
List<Integer> boxedList = new ArrayList<>();
for (int i = 0; i < 1_000_000; i++) {
    boxedList.add(i);              // 1M Integer objects, 16MB
}
int sum = boxedList.stream()
    .mapToInt(Integer::intValue)  // unboxing in the stream
    .sum();

// GOOD: primitive array for performance-critical paths
int[] primitiveArray = new int[1_000_000];
for (int i = 0; i < primitiveArray.length; i++) {
    primitiveArray[i] = i;        // 4MB, no object overhead
}
int sum = 0;
for (int n : primitiveArray) {
    sum += n;                     // no boxing/unboxing
}

// GOOD: IntStream (primitive stream, no boxing)
int sum = IntStream.range(0, 1_000_000).sum();  // no boxing
```

> **Code walkthrough:** The `==` vs `.equals()` trap is the most common wrapper bug:
> Java's integer cache means `==` works for -128 to 127 but fails silently for larger
> values. Always use `.equals()` or `Objects.equals()` (null-safe). The unboxing NPE
> is the second most common issue: a map returning null for a missing key, immediately
> unboxed to a primitive, throws NPE. The performance section shows that for
> number-intensive work, primitive arrays outperform boxed collections by 3-5x in both
> memory and CPU.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> 8 primitive types. Wrappers needed for collections and generics. Autoboxing converts
> automatically. Two key gotchas: (1) use `.equals()` not `==` for wrappers, (2) unboxing
> null throws NPE. For collections: `ArrayList<Integer>` works, but primitive arrays are
> faster and smaller for number-heavy work.

---

**Senior / Staff (5+ years):**
> Primitives vs wrappers: a performance and API design decision. Method signature `int` vs
> `Integer`: prefer `int` (no null, no boxing). Method that may return no value: `Integer`
> or `Optional<Integer>` (both valid; Optional is more explicit). API design: use primitives
> as far down the call stack as possible; box only at API boundaries. For hot loops (millions
> of iterations): primitive arrays or primitive streams (IntStream, LongStream, DoubleStream)
> avoid boxing. Project Valhalla (JDK 23 preview): value types will eventually allow `List<int>`
> without boxing.

---

### ⚠️ Common Misconceptions

**Misconception 1: "float and double are exact."**
IEEE 754 floating-point: NOT exact for most decimal values. `0.1 + 0.2` = `0.30000000000000004`
in double precision. For financial calculations: NEVER use float or double. Use `BigDecimal`
with an explicit scale and rounding mode. `new BigDecimal("0.1").add(new BigDecimal("0.2"))`
= `0.3` exactly. BigDecimal trade-off: slower than double (no hardware floating-point),
more verbose. For money: BigDecimal is non-negotiable.

**Misconception 2: "char can hold any Unicode character."**
Java `char` is a 16-bit unsigned value (UTF-16 code unit), covering the Basic Multilingual
Plane (U+0000 to U+FFFF). Unicode code points above U+FFFF (supplementary characters like
emoji) require TWO char values (a surrogate pair). `String.length()` counts UTF-16 code
units, not Unicode code points. `"hello".length()` = 5 (correct). `"😊".length()` = 2
(incorrect if you mean "number of characters"). For correct Unicode handling:
`str.codePointCount(0, str.length())` or `str.chars()` (returns int stream of code points).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Silent data loss from integer overflow in financial calculation.**

```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```
Symptom: Large payment amounts compute incorrectly
  Input:  totalItems=50_000, pricePerItem=100_000 (in cents)
  Expected: 5,000,000,000 cents ($50,000,000)
  Actual:   705,032,704 (wrong!)

Root cause:
  int total = totalItems * pricePerItem;
  // 50_000 * 100_000 = 5,000,000,000
  // Integer.MAX_VALUE = 2,147,483,647
  // 5,000,000,000 > Integer.MAX_VALUE -> overflow -> wraps to 705,032,704

Diagnosis:
  Check: are intermediate results exceeding Integer.MAX_VALUE?
  50_000 (int) * 100_000 (int) = arithmetic in int space (overflows)
  Even if you assign to long: multiplication already overflowed

Fix:
  // BAD: overflow before assignment
  long total = totalItems * pricePerItem;  // still overflows in int space

  // GOOD: ensure at least one operand is long
  long total = (long) totalItems * pricePerItem;
  
  // GOOD: use Math.multiplyExact for fail-fast on overflow
  try {
      long total = Math.multiplyExact(
          (long) totalItems, (long) pricePerItem);
  } catch (ArithmeticException e) {
      throw new PaymentCalculationException("Overflow: " + e.getMessage());
  }

  // BEST for financial: BigDecimal
  BigDecimal total = BigDecimal.valueOf(totalItems)
      .multiply(BigDecimal.valueOf(pricePerItem));
  // No overflow, exact arithmetic

Prevention: Financial calculations must use long or BigDecimal.
  Never int for money-related values.
  Code review: flag any int multiplication where the result may exceed 2 billion.
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates a key concept in practice using error handling. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **WHAT BREAKS: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Primitive vs wrapper choice | 1 minute |
| Integer cache behavior | 2 minutes |
| Autoboxing performance | 2 minutes |
| float/double precision | 2 minutes |
| NPE from unboxing | 1 minute |
| long vs int for IDs | 1 minute |
| char and Unicode | 1 minute |

---

**Q1 (int vs Integer): When do you use int vs Integer?**

A: Use `int`: method parameters, local variables, return types when null is not a valid
value - always faster, smaller, no NPE risk. Use `Integer`: when null must be representable
(optional numeric field in a DTO), collection type parameter (`List<Integer>`), generic
type parameter (`Optional<Integer>`), method return type when "no value" is possible.
Prefer `int` as far as possible; convert to `Integer` only at API boundaries that require
it.

*What separates good from great:* The DTO/database mapping case: a nullable database
column (e.g., `optional_age INT NULL`). Map to `Integer` (nullable) not `int` (required).
If mapped to `int`: ORM may throw when the column is null (or silently default to 0,
which is wrong). The `@Column(nullable = false)` + `int` field is a correct combination
(non-null DB column + non-null Java primitive). The mismatch (`nullable=true` column + `int`
field) is a bug waiting to happen. Code review: always check that nullable DB columns map
to `Integer` (wrapper) not `int` (primitive) in entity classes.

---

**Q2 (integer cache): Explain the Integer cache and why it matters.**

A: `Integer.valueOf(n)` caches Integer objects for values -128 to 127 (JLS-mandated minimum,
JVM can extend the upper bound via `-XX:AutoBoxCacheMax`). Within the cache range: two calls
to `Integer.valueOf(42)` return the SAME object (same reference). Outside: two different
objects. This means `==` comparison works "by accident" for small integers and fails for
large ones. Rule: NEVER use `==` to compare Integer values; always use `.equals()`.

*What separates good from great:* The cache upper bound is configurable:
`-XX:AutoBoxCacheMax=1000` extends the cache to -128..1000. This is sometimes tuned in
applications that create many Integer objects in a small range. The JVM only caches the
UPPER bound, not lower (-128 is always the lower). You may see this as a production JVM
flag: verify that `AutoBoxCacheMax` is set for the right reason (real benchmark showing
improvement), not cargo-culted. Overextending the cache: more memory for the cache, less
memory for application heap.

---

**Q3 (float double): When do you use float vs double, and when neither?**

A: `double`: default for floating-point (more precision: 15-17 significant digits vs 6-7
for float). Use double for: scientific calculations, statistics, non-financial approximate
quantities. `float`: only when memory is the critical constraint (half the size of double)
and 6-7 digit precision is sufficient (rare in business applications). Neither (BigDecimal):
financial calculations, any situation where exact decimal representation is required.
`BigDecimal("0.1")` is exact; `double 0.1` is not.

*What separates good from great:* The "exact" vs "approximate" distinction has an interview
corollary: `0.1 + 0.2 == 0.3` is `false` in Java (and every language that uses IEEE 754
double). This is a famous interview question and also a real production bug. The correct
comparison: `Math.abs((0.1 + 0.2) - 0.3) < 1e-10` (epsilon comparison). For financial:
`BigDecimal.valueOf(0.1).add(BigDecimal.valueOf(0.2))` = `0.3` exactly. Key API: always
use `BigDecimal.valueOf(double)` (converts from canonical string form), NEVER `new BigDecimal(double)` (converts from the inexact double representation: `new BigDecimal(0.1)` =
`0.1000000000000000055511151231257827021181583404541015625`).

---

**Q4 (numeric range): How do you handle values that might exceed int range?**

A: Use `long` for IDs, timestamps (milliseconds), large counts, byte offsets. Long range:
-9.2e18 to +9.2e18 (64 bits). `System.currentTimeMillis()` returns `long` (millis since epoch -
exceeds int range in 2038). Database sequence IDs should be `BIGINT`/`long`, not `INT`/`int`
(int maxes out at ~2 billion rows). For values beyond long: `BigInteger` (arbitrary
precision, no overflow).

*What separates good from great:* The "2038 problem" for Java: Unix timestamps as `int`
overflow in January 2038 (2^31 seconds since 1970). Java's `System.currentTimeMillis()`
returns `long` (no overflow until year 292 million). But: if you store timestamps in a
database `INT` column (not `BIGINT`): the database will have the problem. Java code using
`java.time.Instant` (JDK 8+): represents instants as seconds + nanoseconds as `long` values.
No Y2K38 problem for properly written Java code using `java.time` and `BIGINT` DB columns.
Legacy code using `java.util.Date` and `INT` columns: a real concern for systems expected
to run past 2038.

---

**Q5 (overflow detection): How do you detect and prevent integer overflow?**

A: `Math.addExact(a, b)`, `Math.multiplyExact(a, b)`, `Math.subtractExact(a, b)`: throw
`ArithmeticException` on overflow. Use for: financial calculations, security-sensitive
arithmetic, any case where overflow is wrong (not a feature). For non-critical paths:
cast to `long` before multiplication to prevent overflow in intermediate results.
`Integer.MAX_VALUE` and `Long.MAX_VALUE`: know the limits.

*What separates good from great:* Overflow in division: `Integer.MIN_VALUE / -1` overflows
in Java (result would be `Integer.MAX_VALUE + 1`, which doesn't fit). This is one of the
few cases where Java integer arithmetic has unexpected behavior (not undefined behavior,
but an overflow). `Math.divideExact` doesn't exist; manual check: `if (a == Integer.MIN_VALUE && b == -1) throw new ArithmeticException()`. Also: `Math.abs(Integer.MIN_VALUE)` =
`Integer.MIN_VALUE` (still negative - overflow). The correct `abs` for arbitrary integers:
`Math.absExact(n)` (Java 15+, throws on MIN_VALUE).

---

**Q6 (boxing in maps): What is the performance impact of using Integer as map keys?**

A: `HashMap<Integer, V>`: each key is a boxed Integer (16 bytes per key + overhead for
the Map.Entry objects). For a map with 1 million entries: ~50-80MB for keys + entries alone.
Alternatives: (1) primitive-keyed maps from libraries: `IntObjectMap<V>` from Eclipse
Collections or Koloboke (no boxing), (2) arrays as maps (if keys are densely distributed:
`V[] indexed = new V[maxKey + 1]`), (3) compact encoding for small maps (EnumMap for
small key spaces). Standard `HashMap<Integer, V>`: fine for small-to-medium maps (< 100K
entries). For millions of entries: evaluate memory impact of boxing.

*What separates good from great:* The `EnumMap` optimization: `EnumMap<MyEnum, V>` uses
an array internally (ordinal as index), no boxing, O(1) lookup like HashMap, 5-10x less
memory than `HashMap<MyEnum, V>`. Rule: always use `EnumMap` when keys are enums.
The missed optimization: `Map<UserType, Config>` where `UserType` is an enum. Using
`HashMap<UserType, Config>`: boxes enum references unnecessarily. Using `EnumMap<UserType, Config>`: array-backed, smaller, faster. This is a standard code review finding.

---

**Q7 (char vs string): When do you use char vs String, and what are char limitations?**

A: `char`: single Unicode code unit (not necessarily a single character). Use for: (1)
single ASCII character constants (`final char DELIMITER = ','`), (2) char-level
String operations (`String.charAt(i)`, `String.toCharArray()`), (3) historical APIs
that accept char (IO readers/writers). `String`: the standard for all text. Char limitations:
only covers Basic Multilingual Plane (U+0000-U+FFFF). Emoji and supplementary characters
require two char values (surrogate pairs). For Unicode-safe code: use `String.codePoints()`
or `Character.codePointAt()` instead of `charAt()`.

*What separates good from great:* The `String.length()` vs character count trap in
internationalized applications. A string containing 3 emoji: `str.length()` may return 6
(each emoji = 2 chars, surrogate pair). `str.codePointCount(0, str.length())` = 3
(correct Unicode count). For user-facing validation (e.g., "username must be 3-20 characters"):
use codePointCount for Unicode-correct validation. A username containing emoji: `length()`
returns twice the value; `codePointCount` returns the visual count. Most validation code
in the wild uses `length()` (fast but wrong for supplementary characters). The fix: one
line change per validation. The risk: input fuzzing with supplementary characters can
bypass length limits if `length()` is used.

---

### ⚖️ Comparison Table

*(Omit: L1 Foundational file (★☆☆) - comparison tables reserved for ★★☆ and above.)*

---

### 🏛️ System Design

*(Omit: L1 Foundational - primitive types are language building blocks, not system design
elements.)*

---

### 📊 Diagram

*(Omit: Primitive type characteristics are clearly expressed in the structured table format
in the Concept Explanation section. A diagram would not add meaningful value.)*

---

---

## Control Flow and Iteration Constructs

---

### 🎯 Model Answer

**30 seconds:**
> Java control flow: `if/else`, `switch` (statement and expression), `while`, `do-while`,
> `for` (counting), enhanced `for-each` (Iterable), `try-catch-finally`. Modern additions:
> switch expressions (Java 14+, `switch (x) { case A -> result; }`) and enhanced switch
> with pattern matching (Java 21+). Key: prefer for-each over indexed for when you don't
> need the index; prefer switch expressions over statement switches (exhaustive, no fall-through).

**3 minutes (Senior):**
> Control flow evolution:
>
> 1. **Classic switch (pre-Java 14)**: fall-through by default (requires `break`). Supports
>    only: int, char, String, enum. Statement only (no value), can assign to a variable
>    from a switch case with verbose code. Common bug: missing `break` causes fall-through.
>
> 2. **Switch expression (Java 14+ GA)**: value-producing, arrow syntax (`case A -> value`),
>    NO fall-through, exhaustive (compiler error if case is missing without default), can
>    have multiple labels per case (`case A, B -> value`), `yield` for multi-line cases.
>
> 3. **Pattern matching switch (Java 21+ GA)**: `case String s -> s.toUpperCase()`,
>    `case Integer i when i > 0 -> "positive"`, `case null -> "null"`. Combines type
>    testing and switch into a single expression.
>
> 4. **Iteration choices**: counted loop (`for (int i = 0; ...)`) when index needed.
>    For-each when iterating all elements. `while` for condition-controlled loops.
>    Stream pipelines for functional-style operations with filter/map/reduce.
>    `Iterator` explicitly when you need to remove during iteration.

**Blank Mind Recovery:**

**(1) Restate:** "if/else (condition), switch (multiple cases), for/while/do-while
(iteration), for-each (Iterable), try-catch-finally (exceptions). Modern: switch
expressions (Java 14, value-producing, no fall-through), pattern matching switch
(Java 21, type-testing in cases)."

**(2) First principles:** "Control flow is about: making decisions (if/switch) and
repeating work (loops). Java borrowed C's syntax but added: for-each (requires Iterable),
switch expressions (value-producing), pattern matching (type testing in decisions).
Each addition: reduces boilerplate while maintaining safety."

**(3) Bridge:** "Control flow is a flowchart in code. if/else = diamond (decision).
for = rectangle with a counter. switch = multi-way junction. try-catch = a detour
sign. Modern switch expressions = a smarter junction that also tells you where
everyone ended up (value-producing)."

---

### 📘 Concept Explanation

**Control flow constructs and modern equivalents:**
```
JAVA CONTROL FLOW REFERENCE:

SWITCH STATEMENT (legacy):
  switch (day) {
    case MONDAY:
    case TUESDAY:                         // fall-through
      System.out.println("Workday"); break;
    case SATURDAY:
    case SUNDAY:
      System.out.println("Weekend"); break;
    default:
      System.out.println("Weekday");
  }
  Issue: easy to forget break -> silent fall-through bug

SWITCH EXPRESSION (Java 14+ GA):
  String type = switch (day) {
    case MONDAY, TUESDAY,                 // multiple labels
         WEDNESDAY, THURSDAY, FRIDAY ->   // no fall-through
        "Workday";
    case SATURDAY, SUNDAY -> "Weekend";
    // Exhaustive: compiler error if case missing without default
  };
  
  // With multi-statement body:
  String result = switch (code) {
    case 200 -> "OK";
    case 404 -> "Not Found";
    default -> {
        log.warn("Unknown code: {}", code);
        yield "Unknown";  // yield = value in multi-line case
    }
  };

PATTERN MATCHING SWITCH (Java 21+ GA):
  String describe(Object obj) {
    return switch (obj) {
      case null -> "null value";
      case Integer i when i < 0 -> "negative int: " + i;
      case Integer i -> "int: " + i;
      case String s when s.isEmpty() -> "empty string";
      case String s -> "string: " + s;
      default -> "other: " + obj.getClass().getSimpleName();
    };
  }

ITERATION PATTERNS:
  // Indexed (use when index matters):
  for (int i = 0; i < array.length; i++) {
      process(array[i], i);
  }
  
  // For-each (use when iterating all, no index):
  for (String item : collection) {
      process(item);
  }
  
  // Iterator (use when removing during iteration):
  Iterator<String> iter = list.iterator();
  while (iter.hasNext()) {
      if (shouldRemove(iter.next())) {
          iter.remove();  // safe removal during iteration
      }
  }
  // Alternative: list.removeIf(this::shouldRemove);
  
  // Stream (functional - filter/map/collect):
  collection.stream()
      .filter(this::isValid)
      .map(this::transform)
      .collect(Collectors.toList());
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using Stream. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** The switch evolution example shows why switch expressionsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> are strictly better than switch statements for most use cases: exhaustiveness
> checking prevents missing cases, no fall-through removes a common bug source,
> and the value-producing nature reduces boilerplate.


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
// SWITCH EVOLUTION: from error-prone to robust

// BAD: switch statement with fall-through trap
int value = getDayValue(day);
String type;
switch (day) {
    case MONDAY:
        type = "Start of week";
        // FORGOT break -> falls through to TUESDAY case
    case TUESDAY:
    case WEDNESDAY:
    case THURSDAY:
    case FRIDAY:
        type = "Weekday";
        break;
    case SATURDAY:
    case SUNDAY:
        type = "Weekend";
        break;
    // Missing FRIDAY? No compiler error - compiles with default behavior
}
// PROBLEM: type may be uninitialized if day doesn't match (no default)
// Compiler: "variable type may not have been initialized"

// GOOD: switch expression (Java 14+)
String type = switch (day) {
    case MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY -> "Weekday";
    case SATURDAY, SUNDAY -> "Weekend";
    // Compiler error if any enum constant is missing without default
    // No fall-through possible
    // type is always assigned (value-producing)
};

// GOOD: pattern matching switch (Java 21+)
// Sealed class hierarchy:
sealed interface Shape permits Circle, Rectangle, Triangle {}
record Circle(double radius) implements Shape {}
record Rectangle(double w, double h) implements Shape {}
record Triangle(double base, double height) implements Shape {}

double area(Shape shape) {
    return switch (shape) {
        case Circle c -> Math.PI * c.radius() * c.radius();
        case Rectangle r -> r.w() * r.h();
        case Triangle t -> 0.5 * t.base() * t.height();
        // No default needed: sealed hierarchy is exhaustive
        // Adding a new Shape: compiler error here until case is added
    };
}

// BAD: ConcurrentModificationException during iteration
for (String s : list) {
    if (s.isEmpty()) {
        list.remove(s);  // throws ConcurrentModificationException
    }
}

// GOOD: removeIf (internal iteration, safe removal)
list.removeIf(String::isEmpty);
```

> **Code walkthrough:** The switch statement's fall-through bug is a classic interview
> topic and a real production issue. Missing a `break` in a case: execution falls through
> to the next case's code silently. Switch expressions make this impossible: each case
> arm is a separate expression, never falls through. The sealed + switch combination is
> the modern Java exhaustive matching pattern: adding a new `Shape` subclass requires
> updating the switch (compiler enforces it). The `removeIf` pattern shows the safe
> alternative to removing elements during iteration.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Control flow basics: if/else for decisions, for/while for loops, for-each for
> collections. Switch expressions (Java 14+) are better than switch statements: no
> fall-through, exhaustive. For removing while iterating: use `removeIf` or `Iterator`.
> Never modify a collection while iterating it with for-each.

---

**Senior / Staff (5+ years):**
> Control flow selection: for-each is readable and safe; prefer it over indexed for.
> Switch expressions over switch statements always. Pattern matching switch (Java 21)
> replaces long instanceof-chains with clean, exhaustive, type-safe dispatch. Streams
> for functional pipelines. Loop labels (`break outer;`) for nested loop control:
> acceptable but prefer extracted methods for clarity. Labeled breaks: common in
> leetcode, rare in production code.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Enhanced for-each supports indexing."**
The for-each loop (`for (String s : list)`) gives no index. If you need both the element
and its index: (1) use the indexed `for (int i = 0; i < list.size(); i++)`, (2) use
`IntStream.range(0, list.size()).forEach(i -> process(list.get(i), i))`, or (3) use
`Streams.mapWithIndex()` from Guava. Trying to track index with an `int` counter in
a for-each: works but verbose; the indexed for loop is clearer.

**Misconception 2: "do-while is the same as while with the condition at the end."**
`do-while` guarantees at least ONE execution of the body (condition checked after).
`while` may execute zero times (condition checked before). Use case for `do-while`: code
that MUST run at least once (e.g., display a menu and read input until valid). In practice:
`do-while` is rare in Java codebases (most loop patterns don't require guaranteed first
execution). Overusing `do-while`: signals unclear loop semantics.

---

### 🚨 Failure Modes and Diagnosis

**Failure: ConcurrentModificationException in a for-each loop.**
```
Symptom:
  java.util.ConcurrentModificationException
    at java.util.ArrayList$Itr.checkForComodification
    at java.util.ArrayList$Itr.next

Root cause:
  // BAD: modifying list during for-each iteration
  List<String> names = new ArrayList<>(List.of("Alice", "", "Bob"));
  for (String name : names) {
      if (name.isEmpty()) {
          names.remove(name);  // throws on next iteration
      }
  }
  
  The for-each uses an Iterator internally.
  ArrayList tracks a modCount (structural modification count).
  Removing during iteration: modCount changes.
  Iterator.next(): checks modCount == expectedModCount -> throws CME.

Fix options:
  Option A: removeIf (Java 8+, single line, safest)
    names.removeIf(String::isEmpty);

  Option B: Collect-then-remove
    List<String> toRemove = names.stream()
        .filter(String::isEmpty)
        .collect(Collectors.toList());
    names.removeAll(toRemove);

  Option C: Explicit Iterator.remove()
    Iterator<String> iter = names.iterator();
    while (iter.hasNext()) {
        if (iter.next().isEmpty()) {
            iter.remove();  // safe: marks iterator as having modified
        }
    }

  Option D: Stream to new list (no mutation)
    names = names.stream()
        .filter(s -> !s.isEmpty())
        .collect(Collectors.toList());
    // Creates a new list (functional style)

Note: CopyOnWriteArrayList does NOT throw CME during iteration
  (iteration works on a snapshot), but it's expensive for writes.
  Use for: very rare writes, frequent reads, iteration under modification.
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates a key concept in practice using Stream. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **WHAT BREAKS: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| switch vs switch expression | 2 minutes |
| for-each vs indexed for | 1 minute |
| ConcurrentModificationException | 2 minutes |
| removeIf and safe iteration | 1 minute |
| Pattern matching switch | 2 minutes |
| Loop labels | 1 minute |
| Break vs continue | 1 minute |

---

**Q1 (switch expression): What advantages does switch expression have over switch statement?**

A: Three key advantages: (1) No fall-through: each case arm is independent (arrow syntax),
preventing the "missing break" bug. (2) Exhaustiveness: if switching on an enum or sealed
type, the compiler requires all cases to be covered. No case = compile error. (3) Value-producing:
the entire switch can be assigned to a variable, eliminating the "variable may not have
been initialized" issue. Bonus: multiple labels per case (`case A, B, C ->`).

*What separates good from great:* The `yield` keyword in multi-line case blocks is a common
interview question. `yield value;` is required when a case arm has multiple statements and
produces a value. `->` syntax: single-expression arm (value is the expression result).
Multi-statement arm: requires `{ ... yield value; }`. The semantic model: switch expression
IS an expression (has a type, produces a value), not a statement. This enables using switch
in lambda, in method argument, in assignment - anywhere an expression is valid.

---

**Q2 (iteration patterns): How do you choose between for, for-each, and streams?**

A: Indexed `for`: when you need the index (array position, parallel processing with index
offsets), or when you need to iterate backwards. For-each: default choice for all forward
iteration over Iterable - cleaner syntax, safe. Stream: when the operation is naturally
functional (filter + map + collect, reduction, parallel), when you want lazy evaluation.
Iterator explicitly: only when removing during iteration (and `removeIf` isn't applicable).

*What separates good from great:* Stream laziness: `stream().filter().map().collect()` -
the filter and map are not executed until the terminal operation (collect). This enables:
short-circuit evaluation with `findFirst()` (stops at first match), infinite streams
(`Stream.iterate(0, n -> n + 1).limit(10)`), lazy I/O pipelines. The pitfall: calling a
stream terminal operation twice throws `IllegalStateException: stream has already been
operated upon`. Rule: create a new stream for each pipeline. Reusable streams: store the
stream-producing code (method reference or supplier), not the stream itself.

---

**Q3 (labeled break): When and when not to use labeled break/continue?**

A: Labeled break: exits a specific (named) outer loop. `break outer;` in a nested loop:
exits the loop labeled `outer`. Use case: nested loop search where you want to stop ALL
loops on first match. More readable alternative: extract the inner loop logic into a
method and use `return` to exit. Labeled continue: skips to the next iteration of the
labeled outer loop. Both features: valid Java, but overuse = hard-to-follow control flow.

*What separates good from great:* The refactoring: replace any labeled break/continue with
an extracted method. Labeled loop example in search:

```java
// Labeled break:
outer: for (int i = 0; i < rows; i++) {
    for (int j = 0; j < cols; j++) {
        if (matrix[i][j] == target) {
            result = new int[]{i, j};
            break outer;
        }
    }
}

// Refactored (cleaner):
int[] findTarget(int[][] matrix, int target) {
    for (int i = 0; i < matrix.length; i++) {
        for (int j = 0; j < matrix[i].length; j++) {
            if (matrix[i][j] == target) return new int[]{i, j};
        }
    }
    return null;
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

The extracted method version: clearer intent, testable, no label syntax. Labeled breaks:
acceptable in leetcode, discouraged in production.

---

**Q4 (try-catch-finally): What is the execution order of try-catch-finally?**

A: Order: try body -> if exception: matching catch -> finally. If no exception: try body ->
finally. Finally ALWAYS runs (even with return in try/catch, even with uncaught exception).
Exception to "always": `System.exit()` or JVM crash. Practical implication: finally is
for cleanup (close resources). With try-with-resources (Java 7+): resources closed
automatically in reverse order of declaration, before finally block.

*What separates good from great:* The `return` in `try` vs `finally` interaction:
```java
int test() {
    try {
        return 1;
    } finally {
        return 2;  // overrides the try's return value
    }
}
// Returns 2, not 1
// This is NEVER acceptable in production code
```
> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

The finally return overrides any return in try or catch - a confusing behavior that
suppresses exceptions too (an exception thrown in try is swallowed if finally returns
normally). Code review: a `return` in a `finally` block is a red flag that should be
removed. Use try-with-resources for resource cleanup instead of finally to avoid this trap.

---

**Q5 (for comprehension): How do you iterate a Map in Java?**

A: Three patterns: (1) `map.forEach((k, v) -> process(k, v))` - simplest for side effects.
(2) `map.entrySet().stream()...` - for functional transformation. (3)
`for (Map.Entry<K, V> entry : map.entrySet())` - when you need both key and value in a
non-lambda context. Iterating only keys: `for (K key : map.keySet())`. Iterating only
values: `for (V val : map.values())`. Performance: `entrySet()` iteration is fastest
(single Entry object per pair); `keySet()` + `map.get(key)` is slower (extra lookup).

*What separates good from great:* Iterating while computing: `Map.computeIfAbsent`,
`Map.merge`, `Map.replaceAll` are safer and more efficient than iterating + modifying.
`map.replaceAll((k, v) -> transform(v))` replaces all values in-place. `map.merge(key, 1, Integer::sum)` - count occurrences without if/get/put boilerplate. These methods
avoid ConcurrentModificationException and reduce code to one line. The pattern:
when you see `for (entry : map.entrySet()) { map.put(...); }`, replace with the
appropriate `Map` functional method.

---

**Q6 (break vs return): What is the difference between break and return in a switch?**

A: `break` (switch statement): exits the switch, continues executing after the switch block.
`return` (in switch inside a method): exits the method, returning a value. In switch
expressions: neither `break` nor `return` is used at the case level; arrow syntax (`->`)
makes each case a separate expression. `yield`: produces a value from a multi-statement
case arm of a switch expression (like `return` but only exits the switch, not the method).

*What separates good from great:* The confusion between `return` and `yield` in switch
expressions. Scenario: a switch expression inside a method. Arrow case: no keyword needed
(expression is the value). Multi-statement case: use `yield value;` (not `return value;`).
`return` in a multi-statement case: exits the METHOD with that value (exits the entire
method, not just the switch). This is often unintentional. Rule: in a switch expression
case block `{ ... }`: always use `yield` to produce the case value. Use `return` only
when you intentionally want to exit the enclosing method.

---

**Q7 (iteration removal): What are all the safe ways to remove elements during iteration?**

A: (1) `collection.removeIf(predicate)` - the simplest, uses internal iteration. (2)
`Iterator.remove()` - explicit iterator, works for any Iterable. (3) Collect to remove:
find elements to remove into a separate list, then `collection.removeAll(toRemove)`.
(4) Stream to new collection: `list = list.stream().filter(condition).collect(toList())`.
(5) `CopyOnWriteArrayList`: iterates over a snapshot, allows modifications. ALL others
(removing via the collection directly during for-each, for loop, or stream) throw
`ConcurrentModificationException`.

*What separates good from great:* The `removeIf` source code is worth knowing: it
uses a single-pass algorithm with a bit set to track elements to remove, then shifts
remaining elements in one pass. O(n) time, O(n/64) additional space (for the bit set).
More efficient than collect-then-removeAll (two passes, creates an intermediate list).
For concurrent collections (ConcurrentHashMap): `map.keySet().removeIf(predicate)` is
thread-safe (uses the built-in concurrent iterator). The rule: know which collection
you're using before choosing the iteration-removal strategy.

---

### ⚖️ Comparison Table

*(Omit: L1 Foundational file (★☆☆).)*

---

### 🏛️ System Design

*(Omit: L1 Foundational.)*

---

### 📊 Diagram

*(Omit: Control flow constructs are best expressed through code examples and decision
trees already embedded in the Concept Explanation section.)*

---

---

## Arrays and String Fundamentals

---

### 🎯 Model Answer

**30 seconds:**
> Arrays: fixed-size, homogeneous, contiguous memory (for primitives). `new int[n]`
> creates an array; `array.length` (not a method - a field). `Arrays` utility class:
> sort, search, copy, fill. `String`: immutable, interned pool for literals. Key string
> methods: `charAt`, `substring`, `indexOf`, `split`, `trim`, `startsWith`. For string
> building in loops: always `StringBuilder`, never `+` concatenation in a loop.

**3 minutes (Senior):**
> String internals and performance:
>
> - **Immutability**: `String` objects never change after creation. `str.toUpperCase()`
>   returns a NEW String, doesn't modify `str`. Safe for sharing across threads without
>   synchronization. Safe as HashMap keys (hash is cached).
>
> - **String pool**: string literals are interned (stored in a pool; `"hello" == "hello"`
>   is true). `new String("hello")`: creates a new heap object (not interned). `str.intern()`:
>   returns the pooled version.
>
> - **`String.format` vs concatenation**: `"a" + "b"` = one String object (compiler
>   optimizes literal concatenation). In loops: `str += item` creates a new String per
>   iteration (O(n^2) total allocations). `StringBuilder.append()` is O(n) total.
>
> - **Java 17+**: Compact Strings optimization (`-XX:+CompactStrings`, default on):
>   strings containing only Latin-1 characters (common English text) are stored as
>   byte[] (1 byte per char) instead of char[] (2 bytes per char). Halves memory for
>   most application strings.
>
> - **Arrays vs ArrayList**: arrays = fixed size, primitives supported, no boxing.
>   ArrayList = dynamic, boxed types, List API. Use arrays for: fixed-size data,
>   performance-critical iteration, primitive data. Use ArrayList for: dynamic sizing,
>   collection operations.

**Blank Mind Recovery:**

**(1) Restate:** "Arrays: fixed size, `array.length` field, `Arrays` utility class.
Strings: immutable, pool for literals, `StringBuilder` for building. Key: never use
`+=` in loops for strings (O(n^2)), use StringBuilder."

**(2) First principles:** "String immutability: once created, a String object's bytes
never change. This makes Strings safe to share (no synchronization needed), usable as
HashMap keys (stable hash), and safe to pass across threads. The cost: every modification
creates a new object."

**(3) Bridge:** "String immutability is like a stone tablet - once carved, it can't be
changed; you copy the text to a new tablet with modifications. StringBuilder is like
a whiteboard - you can erase and rewrite efficiently, then photograph (toString()) the
final result."

---

### 📘 Concept Explanation

**Arrays and String internals:**
```
ARRAYS IN JAVA:

  int[] arr = new int[5];        // default: all zeros
  int[] arr = {1, 2, 3, 4, 5};  // initializer
  int[][] matrix = new int[3][4]; // 2D: 3 rows, 4 cols

  arr.length  // field (NOT arr.length())
  
  Arrays utility (java.util.Arrays):
    Arrays.sort(arr)              // in-place sort, O(n log n)
    Arrays.binarySearch(arr, key) // O(log n), arr must be sorted
    Arrays.copyOf(arr, newLength) // new array, truncates or pads
    Arrays.copyOfRange(arr, from, to)
    Arrays.fill(arr, value)       // fill all with value
    Arrays.equals(arr1, arr2)     // element-wise comparison
    Arrays.toString(arr)          // "[1, 2, 3, 4, 5]"
    Arrays.asList(arr)            // List view (fixed-size!)

STRINGS IN JAVA:

  String s = "hello";   // literal: interned in string pool
  String s = new String("hello");  // heap object, NOT interned
  
  Key methods:
    s.length()          // char count (UTF-16 units)
    s.charAt(i)         // char at index i
    s.substring(from, to)  // [from, to) - to is exclusive
    s.indexOf(str)      // first occurrence, -1 if not found
    s.lastIndexOf(str)  // last occurrence
    s.startsWith(str)   // prefix check
    s.endsWith(str)     // suffix check
    s.contains(str)     // membership
    s.equals(other)     // content comparison
    s.equalsIgnoreCase(other)
    s.trim()            // remove leading/trailing whitespace
    s.strip()           // Java 11+, Unicode-aware whitespace
    s.split(regex)      // split by pattern
    s.replace(old, new) // replaces all occurrences
    s.replaceAll(regex, replacement)
    s.toUpperCase()     // new String
    s.toLowerCase()     // new String
    s.isBlank()         // Java 11+, all whitespace?
    s.isEmpty()         // length == 0?
    String.join(delimiter, elements)  // static join

STRINGBUILDER vs STRING:
  // String concatenation in loop (BAD):
  String result = "";
  for (String item : items) {
      result += item + ", ";  // creates new String each iteration
  }
  // O(n^2) total char copies for n items of length m

  // StringBuilder (GOOD):
  StringBuilder sb = new StringBuilder();
  for (String item : items) {
      sb.append(item).append(", ");  // in-place append
  }
  String result = sb.toString();    // single String creation
  // O(n) total char copies
  
  // Java String.join (better for simple cases):
  String result = String.join(", ", items);
  
  // Collectors.joining (in streams):
  String result = items.stream()
      .collect(Collectors.joining(", "));
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using Stream. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** The string-building performance example demonstrates theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> fundamental O(n^2) vs O(n) difference. The array sorting and searching examples
> show the standard `Arrays` utility class patterns used in production.


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// STRING BUILDING PERFORMANCE

// BAD: O(n^2) string concatenation in loop
String buildReport(List<Order> orders) {
    String report = "Orders:\n";
    for (Order order : orders) {
        report += order.getId() + ": " + order.getAmount() + "\n";
        // Each += creates: order.getId() + ": " (new String)
        //                  above + order.getAmount() (new String)
        //                  above + "\n" (new String)
        //                  report + above (new String, full copy!)
        // For 1000 orders: ~4000 String allocations, O(n^2) total chars
    }
    return report;
}

// GOOD: StringBuilder O(n)
String buildReport(List<Order> orders) {
    StringBuilder sb = new StringBuilder("Orders:\n");
    sb.ensureCapacity(orders.size() * 30);  // pre-allocate estimated size
    for (Order order : orders) {
        sb.append(order.getId())
          .append(": ")
          .append(order.getAmount())
          .append('\n');   // '\n' char (not "\n" String) - slight optimization
    }
    return sb.toString();
}

// BEST for joining: use String.join or Collectors.joining
String report = "Orders:\n" + orders.stream()
    .map(o -> o.getId() + ": " + o.getAmount())
    .collect(Collectors.joining("\n"));

// ARRAY OPERATIONS
int[] scores = {85, 92, 78, 96, 88, 73};

// Sort in place:
Arrays.sort(scores);  // [73, 78, 85, 88, 92, 96]

// Binary search (ONLY after sorting):
int idx = Arrays.binarySearch(scores, 88);  // returns 3

// Copy with new length:
int[] top3 = Arrays.copyOfRange(scores, scores.length - 3, scores.length);
// [88, 92, 96]

// Arrays.asList: fixed-size List (throws on add/remove)
List<String> fixed = Arrays.asList("a", "b", "c");
// fixed.add("d");  // throws UnsupportedOperationException
List<String> mutable = new ArrayList<>(Arrays.asList("a", "b", "c"));
// Mutable copy

// STRING EQUALITY TRAP:
String a = new String("hello");
String b = new String("hello");
System.out.println(a == b);      // false (different objects)
System.out.println(a.equals(b)); // true (same content)
// Always use .equals() for String comparison
```

> **Code walkthrough:** The StringBuilder pre-sizing with `ensureCapacity()` is aice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> production optimization: prevents multiple internal array reallocations as the builder
> grows. The `Arrays.asList()` trap (fixed-size list that throws on structural modification)
> is a common source of bugs. The string equality `==` trap: always use `.equals()` for
> String content comparison. String interning (`==`) works only for literals and explicitly
> interned strings, never for `new String(...)`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Arrays: `array.length` (field), `Arrays.sort()` and `Arrays.copyOf()`. Strings: immutable,
> `.equals()` for comparison (never `==`). StringBuilder for building strings in loops
> (never `+` in loops). Key string methods: `substring`, `indexOf`, `split`, `trim`.

---

**Senior / Staff (5+ years):**
> String performance: Compact Strings optimization halves memory for Latin-1 strings (Java 9+,
> on by default). String deduplication via G1 (`-XX:+UseStringDeduplication`): deduplicates
> equal strings in the heap during GC (reduces memory for applications with many duplicate
> strings). StringBuilder vs StringBuffer: StringBuffer is synchronized (thread-safe but
> slower); use StringBuilder in single-threaded contexts. For concurrent string building:
> use a StringBuilder per thread (ThreadLocal or method-local), combine results at the end.

---

### ⚠️ Common Misconceptions

**Misconception 1: "`String.substring()` always creates a new String."**
Before Java 8: `substring()` returned a view of the original char[] (sharing the underlying
array - memory-efficient). Post Java 8: `substring()` creates a new char[] (new String object).
The change: prevents memory leaks where holding a 1-char substring kept a multi-megabyte
original string alive. In practice: `substring()` on hot paths: consider StringBuilder or
manual index manipulation to avoid allocation. For most code: non-issue.

**Misconception 2: "Arrays.asList() returns a mutable list."**
`Arrays.asList("a", "b", "c")` returns a fixed-size `java.util.Arrays.ArrayList` (not
`java.util.ArrayList`). You CAN set elements: `list.set(0, "x")` works. You CANNOT add
or remove elements: `list.add("d")` throws `UnsupportedOperationException`. This is a
common source of bugs. If you need a mutable list: `new ArrayList<>(Arrays.asList(...))`.
Similarly: `List.of(...)` (Java 9+) is FULLY immutable (throws even on `set`).

---

### 🚨 Failure Modes and Diagnosis

**Failure: String concatenation performance degradation under load.**
```
Symptom: Method that builds large reports runs in 5ms with 100 items,
         but 8 seconds with 10,000 items. CPU profiling shows 95%
         time in String allocation and char[] copying.

Root cause:
  String report = "";
  for (Order o : orders) {
      report += formatOrder(o);  // creates new String each iteration
  }
  
  Analysis of char copies:
    Iteration 1: copy 0 chars (empty) + len(order1)
    Iteration 2: copy len(order1) + len(order2)
    Iteration 3: copy len(order1+2) + len(order3)
    ...
    Total chars copied: n * avg_len * (1 + 2 + ... + n) / 2
                      = O(n^2 * avg_len)
    At 10,000 items: 10,000 * 20 * 10,000/2 = 1 billion char copies!
    At 100 items: 100 * 20 * 50 = 100,000 char copies (fast)

Diagnosis:
  JFR CPU profile: String.append or StringBuilder.<init> dominating
  Allocation profiler: massive String[] allocation in the loop

Fix:
  StringBuilder sb = new StringBuilder();
  sb.ensureCapacity(orders.size() * estimatedOrderLength);
  for (Order o : orders) {
      sb.append(formatOrder(o));
  }
  return sb.toString();
  
  Total chars copied: 0 (append is always to end, no copy)
  Total: O(n * avg_len) - linear

Validation: before/after benchmark with JMH (Java Microbenchmark Harness)
  or System.nanoTime() wrappers if JMH setup time is not justified.
  Expected: 8 seconds -> < 10ms for 10,000 items.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| String immutability rationale | 2 minutes |
| StringBuilder vs String | 2 minutes |
| String == vs equals | 1 minute |
| String intern and pool | 2 minutes |
| Arrays.asList limitation | 1 minute |
| String memory optimization | 2 minutes |
| substring complexity | 1 minute |

---

**Q1 (immutability): Why is String immutable in Java and what are the benefits?**

A: String immutability: once created, the string's content never changes. Benefits:
(1) thread-safe: multiple threads can share a String without synchronization, (2)
HashMap key safety: String's hashCode is cached after first computation - safe because
the content that generates the hash never changes. A mutable key in a HashMap = potential
key loss when the key mutates after insertion. (3) Security: passwords as Strings (though
better practice is char[] for sensitive data), class names passed to ClassLoader, file
paths - all safe because they can't be mutated by callee code. (4) String pool: interning
requires immutability (pooled strings must never change).

*What separates good from great:* The char[] vs String for passwords advice: String stays
in memory until GC'd (and may be in the String pool longer). char[] can be explicitly
zeroed: `Arrays.fill(passwordArray, '\0')`. Security best practice: use char[] for
passwords in Java (this is why JPasswordField.getPassword() returns char[], not String).
However: in Java 9+, String internally uses byte[] (Compact Strings). More importantly:
strings may appear in GC logs, heap dumps, and thread dumps. For production secrets:
use a secrets manager (Vault, AWS Secrets Manager) rather than holding plain-text secrets
in memory as Strings.

---

**Q2 (string pool): What is the String pool and how does interning work?**

A: String pool (String intern pool): a JVM-managed set of unique String objects. String
literals (`"hello"`) are automatically interned: `"hello" == "hello"` is `true` (same
pooled object). `new String("hello")`: NOT in the pool (separate heap object). `str.intern()`:
returns the pooled version of `str` (adds to pool if not present). Use case: reduce memory
when many equal strings are created (e.g., parsing CSV with repeated values in a column).

*What separates good from great:* The string pool lives in the heap (since Java 7; before
Java 7 it was in PermGen). Pool size: unlimited by default (bounded only by heap). Excessive
interning: fills heap with String objects (defeats the purpose). Use `.intern()` judiciously:
only when you know many duplicates exist AND you need fast equality via `==`. The modern
approach: don't call `.intern()` explicitly. Use `Objects.equals()` for content comparison,
let GC handle duplicates. If memory is truly an issue from duplicate strings: `G1 -XX:+UseStringDeduplication` (JVM background deduplication during GC) works without changing
application code.

---

**Q3 (substring memory): How did Java's substring change in Java 8 and what problem did it fix?**

A: Pre-Java 7u6: `String.substring(begin, end)` returned a new String OBJECT but shared the
SAME underlying char[] as the original. `new String(original, begin, end - begin)` - new
object, same array. Benefit: fast and memory-efficient. Problem: holding a 5-char substring
of a 10MB string kept the 10MB char[] alive. Java 7u6+: substring creates a new char[] copy
(new String with new underlying array). Benefit: the original string can be GC'd after
substring. Cost: O(n) allocation per substring call.

*What separates good from great:* The fix for the pre-7u6 memory leak was controversial:
applications that relied on the fast-substring behavior (sharing the array) suddenly saw
more allocation and GC pressure. The practical impact for 2024: always assume substring
copies the content (Java 7u6+). For performance-critical string parsing: avoid repeated
substring; instead, pass begin/end offsets to methods, or use `CharSequence`/`StringBuilder.subSequence()` which may optimize in some implementations. For Apache Commons or Guava
string utilities: they generally use the correct modern approach.

---

**Q4 (string comparison): Why is == wrong for String comparison and what about literal strings?**

A: `==` tests object identity (same reference). `.equals()` tests content equality.
`new String("hello") == new String("hello")` = `false` (two different objects). String literals
are interned: `"hello" == "hello"` = `true` (same interned object). But: there is no
guarantee that ALL equal strings are interned. Method return values, `StringBuilder.toString()`,
String concatenation results: NOT interned. The rule: ALWAYS use `.equals()` (or
`Objects.equals()` for null safety). Using `==` for String comparison is a bug that
may pass unit tests (because tests often use literals) but fail in production.

*What separates good from great:* Static analysis tools (SonarQube, PMD, IntelliJ inspections)
flag `==` on String types. The CI pipeline should run static analysis. But the lesson
goes deeper: Java's `==` means "same object" for ALL reference types. This is correct for:
enums (each enum constant is a singleton, `==` is valid), interned strings (by contract).
It's wrong for: String (unless you interned manually), Integer with value > 127, new
Object() instances. The mental model: in Java, `==` means "same place in memory." For
value equality, always use `.equals()`.

---

**Q5 (array covariance): Explain array covariance and why it can cause runtime errors.**

A: Java arrays are covariant: `String[]` is a subtype of `Object[]`. You can assign
`Object[] arr = new String[3]`. But: trying to store a non-String into this array throws
`ArrayStoreException` at runtime. `arr[0] = Integer.valueOf(42)` - compiles (arr is
`Object[]`), throws `ArrayStoreException` at runtime (actual array is `String[]`).
This is a known type system weakness in Java. Generics (`List<String>` is NOT a subtype
of `List<Object>`) are invariant - they fix this at compile time.

*What separates good from great:* The covariance vs invariance distinction in Java is a
frequent interview topic. Arrays: covariant (compile-time safety breaks). Generics: invariant
(type-safe but inflexible). Wildcards add flexibility: `List<? extends Animal>` accepts
`List<Dog>` or `List<Cat>` (read-only: you can't add to a `? extends` list). The practical
implication: prefer `List<String>` over `String[]` when possible - List gives compile-time
type safety without covariance issues. Arrays are still useful for: primitive storage
(no generics for primitives), known-size fixed data, performance-critical iteration.

---

**Q6 (arrays to list): What is the difference between Arrays.asList, List.of, and new ArrayList()?**

A: `Arrays.asList(arr)`: fixed-size view (set/get work, add/remove throw UOE), backed
by the array (changes to array reflected in list). `List.of(a, b, c)` (Java 9+): fully
immutable (any structural modification throws UOE, even set). Null elements: `Arrays.asList`
allows null; `List.of` does not (throws NullPointerException). `new ArrayList<>(List.of(a,b))`
or `new ArrayList<>(Arrays.asList(a,b))`: fully mutable copy. Rule: for read-only data:
`List.of()` (clear intent, null-safe). For mutable needs: `new ArrayList<>(...)`.

*What separates good from great:* `List.copyOf(collection)` (Java 10+): creates an
immutable copy of any collection. If the source is already an immutable `List.of` list:
returns it as-is (no copy). If mutable: creates a copy. Use in method signatures that
accept a list but want to ensure the returned/stored copy is immutable. The API design
principle: return immutable collections from methods when the contract is "read this,
don't modify it." Defensive copy vs `List.copyOf`: `new ArrayList<>(input)` is a mutable
copy (allows modification without affecting the source). `List.copyOf(input)` is immutable.
Choose based on your intent.

---

**Q7 (text blocks): What are Java text blocks and when should you use them?**

A: Text blocks (Java 15+ GA): multi-line string literal without manual newlines or escaping.
```java
String json = """
    {
        "name": "Alice",
        "age": 30
    }
    """;
```
> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Leading whitespace is stripped based on the column of the closing `"""`. No need for
`\n`, `\"`. Use cases: SQL queries, JSON, HTML templates, XML in tests. Produces a regular
`String` object. Can use `\n`, `\\` explicitly if needed.

*What separates good from great:* Text blocks and the incidental whitespace algorithm:
the closing `"""` position determines how much leading whitespace is stripped. Moving
`"""` left = more whitespace stripped. Common confusion: `"""` immediately after content
(same line) vs on its own line. Best practice: always put closing `"""` on its own line,
indented at the leftmost content column. The `\s` escape (space) and `\<newline>` (line
continuation) in text blocks are new escape sequences: `\s` = one space (prevents trimming
of trailing spaces), `\<newline>` joins two lines (multi-line text block as single logical
line). Useful for long SQL queries where you want logical line continuation without the
actual newline.

---

### ⚖️ Comparison Table

*(Omit: L1 Foundational file (★☆☆).)*

---

### 🏛️ System Design

*(Omit: L1 Foundational.)*

---

### 📊 Diagram

*(Omit: String pool and array structures are well-described in the concept explanation
text and code examples.)*

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



