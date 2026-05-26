---
layout: default
title: "Java Core - L5 Architecture"
parent: "Java Core"
nav_order: 9
permalink: /java-core/l5-architecture/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Core API Design Principles](#core-api-design-principles) | high |
| 2 | [Effective Collections Design](#effective-collections-design) | high |
| 3 | [Java Standard Library Evolution](#java-standard-library-evolution) | medium |

---

# Core API Design Principles

**Interview Weight:** high - Asked at senior and staff level. Tests
whether you can articulate design decisions behind the Java standard
library, and whether you apply these principles to your own APIs.

---

### 🎯 Model Answer

**30 seconds:**

> The Java standard library follows principles from Effective Java:
> minimize API surface, prefer static factories over constructors,
> favor immutability, use interfaces for type declarations, design
> for extension but restrict access. The non-obvious principle:
> a good API is one where the correct usage is obvious and the
> incorrect usage does not compile. Design APIs so callers can
> only express valid states.

**3 minutes (Senior):**

> The core design tension in the Java standard library is: backward
> compatibility vs. elegance. Once an API is public, it is frozen
> for decades. The old `java.util.Date` is a lesson in what happens
> when you get the abstraction wrong and cannot fix it. Java could
> not fix `Date` - it could only add a new API (`java.time`).
>
> Key principles I apply from studying the standard library:
> (1) Return interfaces, not implementations: `List.of()` returns
> `List<E>`, not `ArrayList<E>`, so the implementation can change.
> (2) Throw specific exceptions: `Files.delete()` throws
> `NoSuchFileException` not `IOException`, enabling callers to
> handle specific failure modes. (3) Make invalid states
> unrepresentable: `LocalDate.of(2024, 2, 30)` throws immediately -
> there is no object representing an invalid date.
>
> The most impactful principle for API design: minimize mutability.
> Immutable objects can be freely shared (no defensive copies),
> used as map keys, and used across threads without synchronization.
> Every mutable object in an API is a potential thread-safety bug
> and a defensive-copying burden.

**Framework:** IMMUTABILITY → MINIMAL SURFACE → SPECIFIC EXCEPTIONS
→ UNREPRESENTABLE INVALID STATES → BACKWARD COMPATIBILITY COST

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the design principles that
guided the Java standard library API design."

**(2) First principles:** "Good API design means callers can use
the API correctly without reading the documentation, and incorrect
usage fails at compile time rather than runtime."

**(3) Bridge:** "This is the same as API design for REST services:
make the happy path obvious, make errors explicit, and make invalid
requests impossible."

---

### 📘 Concept Explanation

**What it is:**

The principles governing how the Java standard library was designed
and how production-quality Java APIs should be built. Drawn from:
Effective Java (Joshua Bloch), the history of the standard library's
successes (java.time, Collections) and failures (Date, Calendar).

**The problem it solves:**

APIs that are hard to use correctly (or easy to misuse) cause
bugs in calling code that are blamed on the caller but are actually
API design failures. A well-designed API makes the wrong thing
hard or impossible, and the right thing obvious.

**Key principles:**

```
  1. STATIC FACTORIES over constructors
     └── Can return cached instances, subclasses, meaningful names
     └── List.of(), Optional.of(), Integer.valueOf()
  
  2. MINIMIZE MUTABILITY
     └── Immutable = thread-safe + no defensive copies + safe map keys
     └── String, Integer, LocalDate, List.of() are immutable
  
  3. RETURN INTERFACES, accept interfaces
     └── Return List<E> not ArrayList<E>
     └── Accept Collection<? extends E> not List<E>
  
  4. MAKE INVALID STATES UNREPRESENTABLE
     └── LocalDate.of(2024, 2, 30) throws immediately
     └── Duration cannot be in an inconsistent state
  
  5. THROW SPECIFIC EXCEPTIONS
     └── Files.delete(): NoSuchFileException, AccessDeniedException
     └── Caller can handle each case without string-parsing the message
  
  6. MINIMIZE SURFACE AREA
     └── More methods = more to learn, more to maintain, more to deprecate
     └── List.of() in Java 9 replaced the need for 6 Arrays.asList variants
```

**The key insight:**

Every public API method is a permanent commitment. Once a method
is in `java.util.List` and used by millions of applications,
you cannot remove or change its signature without breaking them.
The Java backward compatibility guarantee is what made Java
successful - and also what forces old API mistakes to live forever.
Design APIs as if they will last 20 years (they will).

**When to use it:**

Apply these principles when designing:
- Service interfaces (the contract between layers)
- Domain model classes (entities, value objects)
- Utility classes
- Library APIs exposed to other teams or systems

**When NOT to use it:**

Not every internal implementation class needs strict API design.
Private helper classes can be mutable, use concrete types, and
have larger surfaces - the constraints apply to public APIs.

**First-principles derivation:**

An API is a contract. Contracts must be stable (backward compat),
correct (no invalid states), and explicit (specific exceptions).
The Java standard library's evolution from `Date` to `java.time`
is a case study: the first attempt violated all three, requiring
a complete replacement that still had to coexist with the old API.

---

### 💻 Code Example

**Example 1: Applying static factory principles**

```java
// BAD: Constructor-heavy API - cannot cache, cannot name, cannot subtype
class Temperature {
    private final double value;
    private final String unit;
    public Temperature(double value, String unit) {
        this.value = value;
        this.unit = unit;
    }
}
// Calling code: new Temperature(100, "CELSIUS") - easy to pass wrong unit

// GOOD: Static factories with type-safe builder
public final class Temperature {
    private final double celsius;

    private Temperature(double celsius) {
        this.celsius = celsius;
    }

    // Named factories - intent is clear
    public static Temperature ofCelsius(double c) {
        return new Temperature(c);
    }
    public static Temperature ofFahrenheit(double f) {
        return new Temperature((f - 32) * 5.0 / 9.0);
    }
    public static Temperature ofKelvin(double k) {
        if (k < 0) throw new IllegalArgumentException(
            "Kelvin cannot be negative: " + k
        );
        return new Temperature(k - 273.15);
    }

    // Make invalid states unrepresentable: no public constructor
    // Kelvin < 0 is immediately rejected
    // Correct unit is ensured by the factory name
}
```

> **Code walkthrough:** Named static factories eliminate the
> "which argument is which unit" ambiguity. `ofCelsius`, `ofFahrenheit`,
> and `ofKelvin` make the unit explicit in the method name - callers
> cannot accidentally swap units. The private constructor means
> the only way to create a Temperature is through a factory, enabling
> validation (Kelvin < 0) at the construction point. Internally
> the representation is always Celsius - the implementation can
> change without affecting callers.

**Example 2: API surface minimization and immutability**

```java
// BAD: Mutable result with large surface - easy to misuse
class QueryResult {
    public List<Row> rows;        // mutable field - callers can corrupt it
    public int totalCount;
    public boolean hasMore;
    public String nextCursor;
    public long queryTimeMs;
    public void addRow(Row row) { rows.add(row); }  // leaks construction
    public void setError(String msg) { ... }  // valid even after build
}

// GOOD: Immutable record with minimal surface
record QueryResult(
    List<Row> rows,         // immutable view returned
    int totalCount,
    boolean hasMore,
    String nextCursor       // null if no more pages
) {
    // Compact constructor validates invariants immediately
    QueryResult {
        rows = List.copyOf(rows);  // defensive copy → immutable
        if (totalCount < 0)
            throw new IllegalArgumentException("totalCount < 0");
        if (hasMore && nextCursor == null)
            throw new IllegalArgumentException(
                "hasMore=true but nextCursor is null"
            );
    }
}
// Record automatically generates equals, hashCode, toString
// Immutable: thread-safe, can be cached, no defensive copies needed
```

> **Code walkthrough:** The record eliminates the mutable state
> and large surface area of the BAD class. The compact constructor
> validates invariants at construction time - a `QueryResult` with
> `hasMore=true` and `null` cursor cannot be constructed, making
> the invalid state unrepresentable. `List.copyOf()` in the
> constructor creates an immutable snapshot, so callers cannot
> mutate the original list through the returned `QueryResult`.

---

### ⚖️ Comparison

| Principle | Violation | Consequence | Fix |
|-----------|-----------|-------------|-----|
| Immutability | Mutable shared objects | Thread-safety bugs, aliasing surprises | Use records, final fields, defensive copies |
| Static factories | Only constructors | Cannot cache, subtype, rename | `of()`, `valueOf()`, `from()` naming |
| Specific exceptions | Throw raw IOException | Caller cannot distinguish failure modes | Exception hierarchy per error type |
| Minimal surface | 20 methods per class | High learning curve, hard to change | Keep public API small, use composition |
| Interface return type | Return ArrayList not List | Locks implementation, breaks callers on change | Return List<E>, not ArrayList<E> |

**The deciding factor:** APIs outlive their implementations.
Design for the caller's perspective (name, intent, errors) not
for the implementer's convenience (concrete types, mutable state).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Good API design means callers can only express valid states,
> the correct usage is obvious, and errors are specific. Use
> static factories instead of constructors when naming adds clarity.
> Return interfaces (List, Map) not concrete types (ArrayList).
> Immutable objects are safer because they cannot be accidentally
> shared and mutated.

*Push deeper:* Why returning `List` not `ArrayList` matters for
callers.

---

**Senior / Staff (5+ years):**

> At staff level, API design is about permanent decisions. I apply
> two tests before publishing any API: (1) Can a caller express
> an invalid state? If yes, add a constructor validation or use
> a type-safe builder. (2) Is the happy path obvious without
> reading the docs? If no, rename or restructure. The Java standard
> library's history shows the cost of API mistakes: `java.util.Date`
> still exists 30 years later despite being wrong, because removing
> it would break millions of codebases.

*Push deeper:* Discuss the open/closed principle in API design -
designing for extension without modification, and how sealed classes
and records enable this more safely than inheritance.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What makes a good Java API?"

🗣️ "A good Java API has several properties. First, the correct
usage is obvious and the incorrect usage does not compile if
possible. Second, invalid states are unrepresentable - you cannot
construct an object in an invalid state. Third, failures are
specific - exceptions carry enough information to handle the
specific case without parsing exception messages. Fourth, the
surface is minimal - only expose what callers genuinely need.
Fifth, mutability is minimized - immutable types are thread-safe
and can be freely shared."

#### Mechanism

- "Why return `List` instead of `ArrayList` from a method?"

🗣️ "Returning `List` decouples the API from the implementation.
If you return `ArrayList`, callers can write code that depends on
`ArrayList`-specific behavior (like `ArrayList.trimToSize()`).
When you later optimize and return a different `List` implementation,
those callers break. Returning `List` is a contract: the caller
gets a list; how it is stored is an implementation detail that
can change freely. The same principle: accept `Collection` as
a parameter, not `ArrayList` - do not require callers to use a
specific implementation."

#### Deep Dive

- "How do you handle backward compatibility in a public API?"

🗣️ "The Java platform's approach is instructive. First, deprecate
early - mark methods `@Deprecated` before removing them, giving
users time to migrate. Second, add new APIs alongside old ones
rather than changing existing ones (java.time alongside Date).
Third, use semantic versioning in the API version declaration.
Fourth, never change the signature or semantics of a published
method - add a new overload if needed. The cost of breaking API
changes is high: every application that uses your API must be
updated simultaneously."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Specific principles, standard library examples. |
| Hiring Manager   | Team API quality - how you enforce design standards. |
| Bar Raiser       | Backward compat strategy, the cost of API mistakes. |
| Peer Engineer    | "The Date lesson: get the abstraction right first time or live with it forever..." |

---

---

# Effective Collections Design

**Interview Weight:** high - Staff-level question. Tests whether
you can articulate collection choice as a design decision, not
just an implementation detail.

---

### 🎯 Model Answer

**30 seconds:**

> Effective collection design means: choose the right abstraction
> (interface), choose the right implementation (based on access
> patterns), minimize mutability, and size correctly. The three
> axes: access pattern (random vs sequential vs concurrent),
> ordering requirement (insertion order, sorted, hash), and
> mutability (immutable `List.of()` vs mutable `ArrayList`).
> The most common mistake: using `ArrayList` everywhere regardless
> of access pattern.

**3 minutes (Senior):**

> Collection choice is a performance and semantic decision. ArrayList
> gives O(1) random access but O(n) insert-at-beginning. LinkedList
> gives O(1) insert-anywhere but O(n) random access and poor cache
> locality. HashMap gives O(1) average lookup with unordered iteration.
> TreeMap gives O(log n) lookup with sorted iteration. The ordering
> decision drives the choice, and the access pattern determines
> the performance profile.
>
> Mutability is the bigger design decision. `List.of()` (Java 9+)
> returns an unmodifiable, compact list implementation that:
> (1) throws `UnsupportedOperationException` on mutation, making
> invariant violations visible immediately; (2) uses a more compact
> memory representation than ArrayList; (3) is thread-safe for
> reads. Return `List.of()` from APIs where the caller should not
> modify the result. Wrap in `List.copyOf()` when accepting external
> lists to prevent external mutation.
>
> At scale, the collection implementation matters for GC pressure.
> `ArrayList<Integer>` stores Integer objects (16 bytes each + header).
> A primitive `int[]` stores raw 4-byte values. For a list of a
> million integers, ArrayList uses ~16MB; `int[]` uses ~4MB. This
> difference in GC pressure is measurable under load.

**Framework:** INTERFACE FIRST (List/Map/Set/Queue) → SEMANTICS
(ordering, duplicates) → IMPLEMENTATION (access pattern) →
MUTABILITY (immutable vs mutable) → SCALE (GC pressure, sizing)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how to choose and design
with Java collections effectively."

**(2) First principles:** "Collections store data. The right
collection depends on: what data (type, duplicates), how you
access it (random, sequential, keyed), and whether it is shared
(thread safety, mutability)."

---

### 📘 Concept Explanation

**What it is:**

A decision framework for choosing, sizing, and exposing Java
collections in production code - covering interface selection,
implementation choice, mutability control, and memory efficiency.

**Key decision tree:**

```
  Need key-value pairs?
  ├── YES: Need sorted order?
  │   ├── YES: TreeMap (O(log n), natural/Comparator order)
  │   └── NO: Need insertion order?
  │       ├── YES: LinkedHashMap (O(1), insertion/access order)
  │       └── NO: HashMap (O(1) avg, no ordering guarantee)
  │           (concurrent?) → ConcurrentHashMap
  └── NO: Need unique elements?
      ├── YES: Need sorted?
      │   ├── YES: TreeSet
      │   └── NO: HashSet (O(1) contains) / LinkedHashSet (ordered)
      └── NO: Need random access?
          ├── YES: ArrayList (O(1) get, O(n) add-at-index)
          └── NO: Need FIFO/stack?
              ├── FIFO: ArrayDeque (LinkedList is slow)
              └── PRIORITY: PriorityQueue (O(log n) poll)
```

**The key insight:**

`ArrayList` should not be the default for everything. `ArrayDeque`
is faster than `LinkedList` as a queue because of cache locality.
`EnumMap` and `EnumSet` are O(1) for enum keys/elements with minimal
memory - always use them when keys are enums. For sorted lookup,
`TreeMap` gives O(log n) vs `HashMap`'s O(1) average - but TreeMap
has better worst-case guarantees (HashMap degrades to O(n) on hash
collisions without Java 8's treeification).

---

### 💻 Code Example

**Example 1: Collection choice based on access pattern**

```java
// BAD: ArrayList used for frequent contains() checks
List<String> allowedUsers = new ArrayList<>();
allowedUsers.add("alice");
allowedUsers.add("bob");
// ...thousands of users
for (Request req : requests) {
    if (allowedUsers.contains(req.getUser())) {  // O(n) per check!
        handle(req);
    }
}
// For 10,000 users and 1M requests: 10,000 * 1,000,000 = 10 billion comparisons

// GOOD: HashSet for O(1) contains()
Set<String> allowedUsers = new HashSet<>(Arrays.asList("alice", "bob"));
// Or from config: new HashSet<>(loadAllowedUsers())
for (Request req : requests) {
    if (allowedUsers.contains(req.getUser())) {  // O(1)
        handle(req);
    }
}

// BAD: LinkedList as queue (poor cache locality)
Queue<Task> queue = new LinkedList<>();
queue.offer(task);
queue.poll();  // GC pressure: node objects per element

// GOOD: ArrayDeque as queue (contiguous memory, no GC per element)
Deque<Task> queue = new ArrayDeque<>();
queue.offer(task);
queue.poll();  // No node allocation
```

> **Code walkthrough:** The BAD ArrayList-for-contains pattern is
> O(n) per check - for 10,000 users and 1M requests, that is 10
> billion string comparisons. HashSet gives O(1) contains. The
> queue comparison: `LinkedList` allocates a node object per element
> (GC pressure), stores elements non-contiguously (cache misses).
> `ArrayDeque` uses a circular array - contiguous memory, no per-
> element allocation, cache-friendly.

**Example 2: Immutability in collection APIs**

```java
// BAD: Returning mutable collection - caller can corrupt state
class UserRegistry {
    private final Map<String, User> users = new HashMap<>();

    public Map<String, User> getUsers() {
        return users;  // caller can: getUsers().clear() !
    }
}

// GOOD: Return immutable view - prevents external modification
class UserRegistry {
    private final Map<String, User> users = new HashMap<>();

    // Option 1: Unmodifiable view (live view - reflects changes)
    public Map<String, User> getUsers() {
        return Collections.unmodifiableMap(users);
    }

    // Option 2: Immutable copy (snapshot - never changes)
    public Map<String, User> getUserSnapshot() {
        return Map.copyOf(users);
    }
}

// Pre-sizing for known capacity to avoid rehashing
// HashMap rehashes at 75% load factor by default
// For 1,000 expected entries, size to 1333 (= 1000 / 0.75)
Map<String, Data> map = new HashMap<>(1333, 0.75f);
// Or use the util formula: (int) Math.ceil(expectedSize / 0.75) + 1
```

> **Code walkthrough:** The BAD pattern returns the internal map
> directly - any caller can corrupt it. Option 1 (unmodifiable view)
> reflects subsequent changes to the underlying map (live view).
> Option 2 (`Map.copyOf()`) creates an immutable snapshot that will
> not reflect future changes. Choose based on whether the caller
> needs a snapshot or a live view. The sizing formula avoids the
> first rehash for known-size maps, reducing initial GC pressure.

---

### ⚖️ Comparison

| Collection | Order | Duplicates | Access | Best Use |
|------------|-------|------------|--------|----------|
| ArrayList | insertion | yes | O(1) random | Default list |
| LinkedList | insertion | yes | O(n) random | Rarely (prefer ArrayDeque) |
| ArrayDeque | insertion | yes | O(1) head/tail | Queue, stack, deque |
| HashSet | none | no | O(1) contains | Membership test |
| LinkedHashSet | insertion | no | O(1) contains | Ordered unique |
| TreeSet | sorted | no | O(log n) | Sorted unique |
| HashMap | none | no (keys) | O(1) avg | Default map |
| LinkedHashMap | insertion/LRU | no (keys) | O(1) avg | LRU cache |
| TreeMap | sorted keys | no (keys) | O(log n) | Sorted map |
| EnumMap | enum order | no (keys) | O(1) | Enum key map |

**The deciding factor:** Ordering requirements drive the choice
(sorted: TreeMap/TreeSet; insertion: Linked*; unordered: Hash*).
Access pattern determines the implementation tier.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Choose collections based on access pattern. Use ArrayList for
> random access lists. Use HashSet for fast membership tests
> (contains). Use HashMap for key-value lookup. Return
> unmodifiable collections from APIs to prevent external mutation.

---

**Senior / Staff (5+ years):**

> Collection design has three dimensions I optimize: (1) access
> semantics (which operations need O(1) vs O(log n)); (2) mutability
> (immutable by default, mutable only when needed); (3) memory
> footprint (primitives > boxed types; arrays > collections for
> pure numeric data). At scale, ArrayList<Integer> vs int[] is a
> measurable GC difference. I also right-size HashMaps at construction
> to avoid rehashing on initial load, which helps with startup
> performance and reduces GC allocation spikes.

---

### ❓ Questions You Will Be Asked

#### Definition

- "When would you use LinkedHashMap over HashMap?"

🗣️ "`LinkedHashMap` maintains insertion order (or access order
if configured with `accessOrder=true`). I use it in two scenarios:
(1) when I need a cache with LRU eviction - `LinkedHashMap` with
`accessOrder=true` and overriding `removeEldestEntry()` gives a
simple LRU cache in a few lines. (2) when the output order of
a map must be predictable for debugging or serialization - using
`LinkedHashMap` guarantees the JSON output of a map has a consistent
field order."

#### Performance and Scalability

- "What happens to HashMap performance at scale?"

🗣️ "HashMap degrades in two scenarios. First, poor hash code
distribution causes many keys to land in the same bucket, creating
long chains. Pre-Java 8, this was O(n) per lookup. Java 8 introduced
treeification: when a bucket chain exceeds 8 entries, it converts
to a TreeMap-style red-black tree, recovering O(log n) worst case.
Second, rehashing: HashMap rehashes when its size exceeds
`capacity * loadFactor` (default 0.75). Each rehash doubles
capacity and re-inserts all elements - O(n). For known large maps,
pre-size to avoid rehashing: `new HashMap<>(expectedSize * 4 / 3 + 1)`."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Collection choice decision tree, complexity. |
| Hiring Manager   | Return immutable collections - correctness and safety. |
| Bar Raiser       | GC impact (boxed vs primitive), HashMap treeification. |
| Peer Engineer    | "The ArrayList.contains() in a loop is a classic O(n^2) bug..." |

---

---

# Java Standard Library Evolution

**Interview Weight:** medium - Signals that you track the language
and library evolution, understand the design constraints, and can
reason about API migration decisions.

---

### 🎯 Model Answer

**30 seconds:**

> The Java standard library evolves under strict backward
> compatibility: nothing that worked in Java 8 breaks in Java 21.
> This forces an additive model - new APIs alongside old ones.
> Key additions: Java 8 (streams, lambdas, Optional, java.time),
> Java 9 (module system, `List.of()/Map.of()`, HTTP Client incubator),
> Java 11 (HTTP Client standard), Java 16 (records, Stream.toList()),
> Java 21 (virtual threads, SequencedCollection). Key patterns:
> old APIs get deprecated but rarely removed; new APIs use
> immutability and functional style.

**3 minutes (Senior):**

> The library's evolution reveals the Java team's design philosophy.
> Each major addition addresses a pain point identified in the
> previous version. `java.time` was the response to `Date`/`Calendar`
> being fundamentally broken. `Stream` + `Optional` were the
> response to null-pointer-driven code. `List.of()` was the response
> to the verbose `Arrays.asList()` which returns a fixed-size,
> mutable list with confusing semantics. Records were the response
> to DTO boilerplate.
>
> The module system (Java 9) created the biggest migration challenge.
> Strong encapsulation of JDK internals broke frameworks (Spring,
> Hibernate) that used reflection on internal classes. The `--add-opens`
> workaround and the eventual framework updates took 2-3 years of
> ecosystem adjustment. Understanding why the module system was
> introduced (security, reliability, smaller JDK images) and what
> it cost (migration friction) shows architectural awareness.
>
> The most impactful upcoming change: virtual threads (Java 21 GA).
> This is the biggest change to the Java runtime model since Java 5's
> `java.util.concurrent`. It changes the economics of concurrency:
> blocking I/O no longer costs an OS thread, enabling simple
> synchronous code to scale to hundreds of thousands of concurrent
> operations.

**Framework:** CONSTRAINT (backward compat) → PATTERN (additive)
→ KEY ADDITIONS (8→21) → MIGRATION COST (module system) →
UPCOMING IMPACT (virtual threads)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about how the Java standard library
has evolved across versions and the design principles behind that
evolution."

**(2) First principles:** "A mature library serving millions of
applications must evolve without breaking them. The constraint
is additive-only evolution with long deprecation cycles."

---

### 📘 Concept Explanation

**What it is:**

The Java standard library evolution history and design constraints
- understanding how the JDK team adds new APIs while maintaining
backward compatibility across 30 years.

**Key evolution timeline:**

```
  Java 8  (2014) - Lambdas, Streams, Optional, java.time, CompletableFuture
  Java 9  (2017) - Module system, List.of(), jshell, ProcessHandle
  Java 11 (2018) - HTTP Client, String.lines/strip/repeat/isBlank
  Java 14 (2020) - Switch expressions (standard), helpful NPE messages
  Java 15 (2020) - Text blocks (standard)
  Java 16 (2021) - Records (standard), Stream.toList()
  Java 17 (2021) - Sealed classes, random API (nextInt range), 
                   RestrictedAccessChangesMakesModuleReady
  Java 19 (2022) - Virtual threads (preview), Pattern matching preview
  Java 21 (2023) - Virtual threads (GA), SequencedCollection,
                   Record patterns, String templates (preview)
  Java 23 (2024) - Primitive patterns, Module imports (preview)
```

**The key insight:**

The Java team never breaks existing code. `Arrays.asList()` still
returns a fixed-size mutable list even though it is confusing -
because changing it would break code that relies on the mutation
semantics. `List.of()` was added as a correctly-designed immutable
factory alongside the old API. Understanding this constraint
explains why Java's API surface grows but never shrinks.

**When to use it:**

Know the evolution to:
- Advise team on migration from older Java versions
- Understand why old APIs exist and when they are safe to use
- Anticipate performance improvements in newer JVM versions
- Plan library dependency updates for new Java LTS versions

---

### 💻 Code Example

**Example 1: Library evolution - same operation across versions**

```java
// Java 8: Streams and collectors introduced
List<String> names = List.of("Alice", "Bob", "Charlie");
List<String> filtered8 = names.stream()
    .filter(n -> n.startsWith("A"))
    .collect(Collectors.toList());    // Java 8: mutable result

// Java 9: Immutable factory methods
List<String> immutable = List.of("Alice", "Bob");
Map<String, Integer> scores = Map.of("Alice", 95, "Bob", 87);
Set<String> roles = Set.of("ADMIN", "USER");

// Java 10: Collectors.toUnmodifiableList()
List<String> filtered10 = names.stream()
    .filter(n -> n.startsWith("A"))
    .collect(Collectors.toUnmodifiableList());  // Java 10: unmodifiable

// Java 16: Stream.toList() - most concise, immutable
List<String> filtered16 = names.stream()
    .filter(n -> n.startsWith("A"))
    .toList();   // Java 16: direct, unmodifiable, most idiomatic

// Java 21: SequencedCollection - access first/last uniformly
SequencedCollection<String> sc = new ArrayList<>(names);
String first = sc.getFirst();   // getFirst/getLast on any list
String last  = sc.getLast();
SequencedCollection<String> rev = sc.reversed();
```

> **Code walkthrough:** The progression from `collect(Collectors.toList())`
> to `.toList()` shows how the library simplifies idioms over time.
> `Stream.toList()` (Java 16) is the most concise and returns an
> unmodifiable list. The `SequencedCollection` interface (Java 21)
> adds `getFirst()`/`getLast()` to all ordered collections - filling
> an API gap that previously required different calls for `List`
> vs `Deque`.

**Example 2: Module system migration pattern**

```java
// Before Java 9: internal API access via reflection (worked)
// After Java 9: throws InaccessibleObjectException by default
Field field = String.class.getDeclaredField("value");
field.setAccessible(true);   // fails if module system denies access

// --add-opens workaround (JVM arg - temporary, not a real fix):
// --add-opens java.base/java.lang=ALL-UNNAMED
// This opens the java.lang package to unnamed modules (app classpath)

// Real fix: use supported public APIs instead of internals
// If you needed String.value for performance, use:
String s = "hello";
byte[] bytes = s.getBytes(StandardCharsets.UTF_8);  // public API
// Or for char access: s.chars(), s.charAt(), s.toCharArray()

// The module system's purpose:
// 1. Strong encapsulation: internal JDK APIs hidden by default
// 2. Reliable configuration: explicit module dependencies
// 3. Smaller runtime images: jlink can exclude unused modules
module com.example.app {
    requires java.sql;        // explicit dependency
    requires spring.core;     // requires spring.core module
    exports com.example.api;  // expose this package
    opens com.example.dto to spring.core;  // allow reflection
}
```

> **Code walkthrough:** The migration from reflection-on-internals
> to public APIs is the core Java 9 migration task. `--add-opens`
> is a temporary workaround for legacy frameworks that have not
> yet migrated. The `module-info.java` shows the intended end state:
> explicit dependencies and controlled reflection access. `opens`
> grants reflection without `requires` granting compile-time access
> - this is how Spring's dependency injection works with modules.

---

### ⚖️ Comparison

| Java Version | Key Addition | Migration Cost | Impact |
|-------------|-------------|---------------|--------|
| Java 8 | Lambdas, Streams, java.time | Low | High - changed idiomatic Java |
| Java 9 | Module system, List.of() | High (JPMS) | High - broke many frameworks |
| Java 11 | HTTP Client, String methods | Low | Medium - incremental |
| Java 17 | Sealed classes, records finalized | Low | Medium - language modernization |
| Java 21 | Virtual threads (GA), SequencedCollection | Low | Very High - concurrency model |

**The deciding factor:** LTS versions (8, 11, 17, 21) are the
migration targets. Non-LTS releases are for early adopter testing.
Migrate when frameworks support the target LTS.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> The Java standard library grows with each version but never
> removes old APIs. Java 8 added lambdas, streams, and java.time.
> Java 9 added the module system and `List.of()`. Java 21 added
> virtual threads. LTS versions (8, 11, 17, 21) are the production-
> stable targets.

---

**Senior / Staff (5+ years):**

> I track library evolution at the LTS level and plan migrations
> based on framework compatibility. The Java 9 module system
> migration was the hardest: frameworks using internal JDK APIs
> via reflection needed `--add-opens` workarounds and then
> proper updates. I evaluate new Java versions on two axes:
> language features (records, sealed classes) which are safe to
> adopt incrementally, and runtime changes (GC algorithms, JIT
> improvements, virtual threads) which are transparent but require
> performance re-baselining.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What were the most impactful additions in Java 8?"

🗣️ "Java 8 introduced three things that fundamentally changed how
Java is written. First, lambda expressions and functional interfaces
- enabling functional-style code without verbose anonymous classes.
Second, the Streams API - declarative data processing pipelines
with lazy evaluation. Third, `java.time` - a correct, immutable
date/time API replacing the broken `Date`/`Calendar`. Together
these shifted Java from a pure OOP style to a hybrid functional-OOP
style."

#### Deep Dive

- "Why did the Java module system (Java 9) cause so many migration
  problems?"

🗣️ "The module system introduced strong encapsulation: internal
JDK packages (like `sun.misc.Unsafe`, `com.sun.*`) became inaccessible
by default. Many frameworks - Spring, Hibernate, CGLIB, Jackson -
used reflection on these internal classes for proxy generation,
bytecode manipulation, and serialization. These frameworks had to
be updated to use supported public APIs or module-aware patterns.
Until they were updated, applications had to add `--add-opens` flags
to the JVM startup to grant the required reflective access.
The migration took 2-3 years across the ecosystem."

#### Misconception / Trap

- "Is `Stream.toList()` (Java 16) the same as `collect(Collectors.toList())`?"

🗣️ "No - and this is an important distinction. `collect(Collectors.toList())`
returns a mutable `ArrayList`. `Stream.toList()` returns an
unmodifiable list. If your code assigns the result and then tries
to `add()` or `remove()` elements, the `toList()` version will throw
`UnsupportedOperationException` while the `collect()` version would
silently succeed. In new code, `toList()` is the right default -
you should be intentional about needing a mutable list and use
`collect(Collectors.toList())` explicitly in that case."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Version-by-version additions, module system internals. |
| Hiring Manager   | Migration planning, LTS strategy. |
| Bar Raiser       | Virtual threads impact, Valhalla roadmap, JPMS adoption. |
| Peer Engineer    | "The module migration took us a full sprint - here is what we hit..." |
