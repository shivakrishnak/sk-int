---
layout: default
title: "Java Core - L2 Collections Advanced"
parent: "Java Core APIs"
nav_order: 4
permalink: /java-core/l2-collections-advanced/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Collections Utility Class: Sort, Binary Search, Shuffle, Min/Max](#collections-utility-class-sort-binary-search-shuffle-minmax) | low-medium |
| 2 | [Unmodifiable vs Immutable: List.of() vs Collections.unmodifiableList()](#unmodifiable-vs-immutable-listof-vs-collectionsunmodifiablelist) | medium |
| 3 | [Collectors: groupingBy, partitioningBy, joining, toUnmodifiableMap](#collectors-groupingby-partitioningby-joining-tounmodifiablemap) | medium |
| 4 | [Stream-to-Collection Patterns: collect(), toList(), and Materialization](#stream-to-collection-patterns-collect-tolist-and-materialization) | medium |
| 5 | [Array-to-Collection Bridges: Arrays.asList(), List.of(), Mutation Trap](#array-to-collection-bridges-arraysaslist-listof-mutation-trap) | medium |

---

# Collections Utility Class: Sort, Binary Search, Shuffle, Min/Max

**Interview Weight:** low-medium - Tests knowledge of standard
utility methods that avoid reinventing the wheel.

---

### 🎯 Model Answer

**30 seconds:**

> `java.util.Collections` is a utility class of static methods for
> List operations. Key methods: `sort(list)` - natural order sort
> (requires `Comparable`); `sort(list, comparator)` - custom sort;
> `binarySearch(list, key)` - O(log n) search on sorted List
> (requires Comparable or Comparator); `shuffle(list)` - random order;
> `min(collection)` / `max(collection)` - extremes. Most operations
> require the list to already be sorted for binary search to be correct.

**3 minutes (Senior):**

> `Collections.sort()` delegates to `list.sort(null)` since Java 8,
> which calls `Arrays.sort()` on the backing array - a TimSort
> implementation. TimSort is O(n log n) worst case but O(n) for nearly-
> sorted input (common in practice). It is stable: equal elements
> maintain their relative order.
>
> `Collections.binarySearch(list, key)`: returns the index if found,
> or `-(insertionPoint) - 1` if not found. The list MUST be sorted by
> the same ordering as the search (natural order or the Comparator
> argument). Violating this produces undefined results (not an exception).
>
> `Collections` also provides: `reverse(list)`, `rotate(list, distance)`,
> `swap(list, i, j)`, `fill(list, obj)`, `copy(dest, src)`,
> `frequency(collection, obj)`, `disjoint(c1, c2)`, and wrappers:
> `unmodifiableList()`, `synchronizedList()`, `singletonList()`,
> `emptyList()`, `nCopies(n, obj)`.

**Framework:** SORT (TimSort, stable, log n) + BINARY-SEARCH
(sorted required, returns insertion point) + WRAPPERS + JAVA-8 (List.sort)

_Adapting up:_ Discuss `Arrays.sort()` vs `Collections.sort()` -
former uses dual-pivot quicksort for primitives (not stable), latter
uses TimSort (stable) for objects.

_Adapting down:_ `Collections.sort(list)` sorts. `Collections.binarySearch(list, key)`
searches if sorted. Need Comparable elements.

**Blank Mind Recovery:**

**(1) Restate:** "Collections is a static utility class. Key methods:
sort, binarySearch, min/max, shuffle, reverse, unmodifiableList."

**(2) First principles:** "Instead of duplicating sorting/searching
logic everywhere, a utility class provides tested implementations.
Binary search requires sorted input - this is a contract the caller
must ensure."

**(3) Bridge:** "Collections is the 'standard library toolbox' for
List operations - like having a Swiss Army knife. But binarySearch
is like a GPS: it only works if you're already on a mapped road (sorted list)."

---

### 📘 Concept Explanation

**Key methods:**

```java
List<String> names = new ArrayList<>(
    List.of("Charlie", "Alice", "Bob", "Dave"));

// Sort - natural order (requires Comparable)
Collections.sort(names);
// ["Alice", "Bob", "Charlie", "Dave"]

// Sort - custom order (Comparator)
Collections.sort(names, Comparator.reverseOrder());
// ["Dave", "Charlie", "Bob", "Alice"]

// Binary search - list MUST be sorted by same order
Collections.sort(names); // sort ascending first
int idx = Collections.binarySearch(names, "Charlie");
// Returns: 2 (index of "Charlie")
// If not found: returns -(insertionPoint) - 1
//   e.g., searching "Eve" -> -(4) - 1 = -5
//   meaning: Eve would be inserted at index 4

// Shuffle
Collections.shuffle(names); // random order
Collections.shuffle(names, new Random(42)); // seeded

// Min / Max
String min = Collections.min(names); // uses Comparable
String max = Collections.max(names, Comparator.reverseOrder());

// Reverse
Collections.reverse(names);

// Frequency
int count = Collections.frequency(names, "Alice");

// Rotate: moves last N elements to front
Collections.rotate(names, 2);
// [A,B,C,D] -> [C,D,A,B] (rotate by 2)
```

**Unmodifiable and singleton wrappers:**

```java
// Unmodifiable views (throws UnsupportedOperationException on write)
List<String> immutable = Collections.unmodifiableList(names);
Map<K,V> immutableMap = Collections.unmodifiableMap(map);
Set<T> immutableSet = Collections.unmodifiableSet(set);

// Singletons (immutable, 1-element)
List<String> singleton = Collections.singletonList("only");
Set<String>  singletonSet = Collections.singleton("only");
Map<K,V>     singletonMap = Collections.singletonMap(k, v);

// Empty (immutable, 0 elements, shared instances)
List<String> empty = Collections.emptyList();
Set<String>  emptySet = Collections.emptySet();
Map<K,V>     emptyMap = Collections.emptyMap();

// Repeated values
List<String> tenNulls = Collections.nCopies(10, null);
```

**TimSort behavior:**

```java
// TimSort is STABLE: equal elements keep relative order
record Person(String name, int age) {}
List<Person> people = new ArrayList<>(List.of(
    new Person("Bob",   30),
    new Person("Alice", 25),
    new Person("Carol", 25)  // same age as Alice
));

// Sort by age: Alice (25) and Carol (25) keep their order
Collections.sort(people, Comparator.comparingInt(Person::age));
// [Alice(25), Carol(25), Bob(30)]  <- relative order of 25s preserved
```

---

### 💻 Code Example

#### Binary search return value decoding

```java
// BAD: checking only >= 0
List<Integer> sorted = new ArrayList<>(List.of(1, 3, 5, 7, 9));
int result = Collections.binarySearch(sorted, 6);
if (result >= 0) {
    System.out.println("Found at: " + result);
} else {
    System.out.println("Not found"); // OK but ignores insertion point
}

// GOOD: use insertion point for sorted insert
int pos = Collections.binarySearch(sorted, 6);
if (pos >= 0) {
    System.out.println("Found at index: " + pos);
} else {
    int insertAt = -(pos) - 1;
    sorted.add(insertAt, 6); // insert to maintain sort order
    // sorted: [1, 3, 5, 6, 7, 9]
}
```

> **Code walkthrough:** `binarySearch` returning a negative value
> `r` encodes the insertion point: `insertionPoint = -(r) - 1`.
> This is the index where the element would be inserted to keep the
> list sorted. Using the insertion point allows maintaining a sorted
> list with `add(insertAt, element)` without re-sorting. This pattern
> implements an "insert in sorted order" operation efficiently.

---

### 🎓 Answers by Seniority

**Junior:** `Collections.sort(list)` sorts in natural order. `binarySearch`
searches a sorted list. Returns negative if not found.

**Mid-level:** `Collections.sort()` uses TimSort (stable, O(n log n),
O(n) for nearly sorted). `binarySearch` returns `-(insertionPoint)-1`
for not-found. The list must be sorted by the same comparison used in
search or results are undefined. `Collections.unmodifiableList()` wraps
for read-only access.

**Senior:** In Java 8+, `Collections.sort(list)` delegates to
`list.sort(null)` which calls `Arrays.sort()` on the backing array.
`Arrays.sort(primitives)` uses dual-pivot quicksort (not stable).
`Arrays.sort(objects)` uses TimSort (stable). Knowing this distinction
matters when stability is required.

**Staff:** `Collections.emptyList()`/`emptyMap()` return shared static
instances - no allocation. Prefer these as null-replacement for empty
return values. `Collections.unmodifiableList()` is a view - the underlying
list can still be modified; use `List.copyOf()` for a true immutable copy.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                              | Reality                                                                                                                                        | Danger                                                               |
| --- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| 1   | `Collections.binarySearch()` works on any list             | List must be sorted by the SAME ordering used for the search. Unsorted input produces undefined results (not an exception)                     | Silent wrong results from binary search on unsorted data             |
| 2   | `Collections.unmodifiableList()` creates an immutable copy | It is a read-only VIEW. The underlying list can still be modified by the original reference. Callers see modifications                         | Expecting immutability but getting mutable-through-original behavior |
| 3   | `Arrays.sort(primitives)` is stable                        | `Arrays.sort(int[])` uses dual-pivot quicksort which is NOT stable. Only `Arrays.sort(Object[])` and `Collections.sort()` (TimSort) are stable | Unexpected ordering of equal primitive values                        |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Modifying underlying list "breaks" unmodifiableList**

Symptom: A "read-only" list passed to a method unexpectedly changes.

Root cause: `Collections.unmodifiableList(source)` was passed,
but code still holds a reference to `source` and modifies it.
The unmodifiable view reflects changes.

Fix: Use `List.copyOf(source)` (Java 10) or
`Collections.unmodifiableList(new ArrayList<>(source))` to
create a truly independent copy.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                         |
| ---------------- | ------------------------------------------------------------ |
| 15 min           | Key methods: sort, binarySearch, min/max, unmodifiableList   |
| 30 min           | Add binarySearch return value semantics; TimSort stability   |
| 45 min           | Add Arrays.sort vs Collections.sort; emptyList/singletonList |

---

**[JUNIOR] Q1: What is the return value of `Collections.binarySearch()`
when the element is not found?** [CONCEPTUAL]

_Why they ask:_ Tests whether candidate understands the encoded return value.

_Likely follow-up:_ "How would you insert the element in sorted order
using this value?"

When the element is not found, `binarySearch` returns a negative integer
`r` where `r = -(insertionPoint) - 1`. The insertion point is the
index where the element would need to be inserted to keep the list sorted.

Recovering the insertion point: `insertionPoint = -(r) - 1` or equivalently
`insertionPoint = -r - 1`.

If `binarySearch` returns -3: `insertionPoint = -(-3) - 1 = 2`. Insert
at index 2 to maintain sort order.

The -1 adjustment ensures the return value is always negative (even when
the insertion point is 0, which would otherwise return 0 and appear found).

_What separates good from great:_ Explaining WHY `-1` is subtracted
(to distinguish "not found at position 0" from "found at position 0").

---

**[MID] Q2: Is `Collections.sort()` stable? Why does it matter?**
[CONCEPTUAL]

_Why they ask:_ Tests understanding of sort stability and TimSort.

_Likely follow-up:_ "Is `Arrays.sort()` stable?"

`Collections.sort()` is stable - equal elements maintain their
relative order after sorting. It uses TimSort (Timsort), a hybrid
of merge sort and insertion sort designed to exploit natural runs
in the data. TimSort is:

- O(n log n) worst case
- O(n) for nearly-sorted data (very common in practice)
- Stable
- Available in `Collections.sort()`, `List.sort()`, `Arrays.sort(Object[])`

Stability matters for multi-key sorting:

```java
// Sort by first name first, then by last name
// WRONG without stability: second sort destroys first sort's ordering
Collections.sort(people, Comparator.comparing(Person::getFirstName));
Collections.sort(people, Comparator.comparing(Person::getLastName));
// CORRECT: people are now sorted by last name, with first-name tie-break
// (only works because sort is stable)
```

`Arrays.sort(int[])` (primitives) uses dual-pivot quicksort - NOT
stable. Stability is irrelevant for primitives (no "equivalent" primitives).

_What separates good from great:_ The multi-key stable sort example
showing why stability enables independent single-key sorts to compose
into multi-key sorts.

---

**[SENIOR] Q3: When should you use `Collections.emptyList()` over
`new ArrayList<>()`?** [TRADE-OFF]

_Why they ask:_ Tests awareness of null-avoiding patterns and allocation.

_Likely follow-up:_ "Can you add elements to it later?"

`Collections.emptyList()` returns a shared static immutable list
instance (`EMPTY_LIST`). No allocation - always the same object.
Adding elements throws `UnsupportedOperationException`.

`new ArrayList<>()` allocates a new empty ArrayList with a backing
array of 10. Mutable.

Use `Collections.emptyList()` when:

- Method returns "no results" - signals the caller nothing was found
- Replacing null returns (null-safe: callers can iterate, check size,
  without null check)
- The result is guaranteed to stay empty

Use `new ArrayList<>()` when the list will be populated.

The null-replacement pattern is the key use case:

```java
// BAD: null return - callers must null-check before iterating
public List<User> findActive() {
    if (noActiveUsers) return null;
    // ...
}

// GOOD: never return null for collections
public List<User> findActive() {
    if (noActiveUsers) return Collections.emptyList();
    // caller can safely do: for (User u : findActive()) {}
}
```

_What separates good from great:_ Connecting `emptyList()` to the
Null Object pattern - returning an empty collection instead of null.

---

---

# Unmodifiable vs Immutable: List.of() vs Collections.unmodifiableList()

**Interview Weight:** medium - Critical distinction for defensive
programming; commonly misunderstood.

---

### 🎯 Model Answer

**30 seconds:**

> `Collections.unmodifiableList(source)` is a read-only VIEW - write
> operations throw `UnsupportedOperationException`, but the original
> source list can still be modified and the view reflects those changes.
> `List.of()` (Java 9) and `List.copyOf()` (Java 10) are truly immutable:
> the content never changes, independent of any source. The difference:
> view vs copy, and whether mutation through another reference is possible.

**3 minutes (Senior):**

> `Collections.unmodifiableList(list)` wraps `list` in a
> `UnmodifiableList` - a read-only facade. The internal `list` field
> holds the original reference. All mutating methods (`add`, `set`,
> `remove`) throw `UnsupportedOperationException`. BUT: if you hold
> the original `list` reference and call `list.add("x")`, the
> unmodifiable view immediately shows the new element. This is the
> "back door": immutability is only from the wrapper's API, not
> guaranteed.
>
> `List.of(e1, e2, ...)` creates a truly immutable list with no
> backing mutable collection. Implementation varies: small lists
> (0-2 elements) use specialized classes; larger lists use an
> array-backed immutable implementation. Cannot contain null elements.
> Identity and order are not specified - two `List.of("a","b")` calls
> may return the same object or different objects.
>
> `List.copyOf(collection)` creates an immutable copy of any collection.
> Takes a snapshot at copy time; subsequent changes to the source are
> NOT reflected. Cannot contain null elements.

**Framework:** VIEW (unmodifiable, back-door exists) vs COPY (immutable,
no back-door) + NULL-POLICY + USE-CASES

_Adapting up:_ Discuss Guava's `ImmutableList` (also a copy, but
guarantees the class is always immutable without Java version dependency),
and defensive copying patterns in API design.

_Adapting down:_ `unmodifiableList` prevents writes through the wrapper
but source can still change. `List.of()` is truly immutable - nothing
can change it.

**Blank Mind Recovery:**

**(1) Restate:** "unmodifiableList = read-only wrapper, underlying
list can still change. List.of() = truly immutable, fixed content.
The difference is whether a 'back door' to the original exists."

**(2) First principles:** "Immutability needs a guarantee that the
object's state CANNOT change. A read-only view cannot provide that
guarantee if the source is accessible elsewhere. A copy can."

**(3) Bridge:** "unmodifiableList is a locked room with a key the
janitor still has. List.of() is a room sealed in concrete - no key
exists."

---

### 📘 Concept Explanation

**Comparison:**

| Feature                  | `unmodifiableList(src)` | `List.of(elements)` | `List.copyOf(src)` |
| ------------------------ | ----------------------- | ------------------- | ------------------ |
| Null elements            | Allowed (if src allows) | Throws NPE          | Throws NPE         |
| Mutate via wrapper       | No (`UOE`)              | No (`UOE`)          | No (`UOE`)         |
| Mutate via source        | YES - back door         | No source exists    | No source exists   |
| Source changes reflected | YES                     | N/A                 | No (snapshot)      |
| Java version             | 1.2+                    | Java 9+             | Java 10+           |
| Implementation           | Wrapper/View            | Purpose-built       | Purpose-built      |

**The back-door problem:**

```java
List<String> source = new ArrayList<>(List.of("A", "B"));
List<String> view = Collections.unmodifiableList(source);

System.out.println(view.size()); // 2

source.add("C"); // mutates through the back door
System.out.println(view.size()); // 3! View changed!
```

**List.of() - truly immutable:**

```java
// No source to mutate through
List<String> immutable = List.of("A", "B");
immutable.add("C"); // UnsupportedOperationException

// Cannot contain null:
List<String> withNull = List.of("A", null); // NullPointerException!

// Structural equality: two separate List.of calls
List<String> l1 = List.of("A", "B");
List<String> l2 = List.of("A", "B");
System.out.println(l1.equals(l2)); // true (value equality)
```

**List.copyOf() - snapshot:**

```java
List<String> source = new ArrayList<>(List.of("A", "B"));
List<String> copy = List.copyOf(source); // snapshot

source.add("C");  // source changes
System.out.println(copy.size()); // still 2 - copy not affected

// List.copyOf on an already-immutable List.of may return the same object:
List<String> original = List.of("A", "B");
List<String> copyOf = List.copyOf(original);
System.out.println(original == copyOf); // true (optimization!)
```

**Set.of() / Map.of() - unspecified iteration order:**

```java
// WARNING: Set.of() and Map.of() have unspecified iteration order
// (may vary between JVM runs)
Set<String> set = Set.of("A", "B", "C");
// Iterating set gives A,B,C in unknown order - may change on restart

// Map.of() - max 10 entries; use Map.ofEntries() for more
Map<String, Integer> map = Map.of("a", 1, "b", 2);
// Map.ofEntries: varargs of Map.entry() pairs
Map<String, Integer> big = Map.ofEntries(
    Map.entry("a", 1), Map.entry("b", 2), Map.entry("c", 3));
```

---

### 💻 Code Example

#### Defensive copying in API design

```java
public class Config {
    private final List<String> servers;

    // BAD: Stores reference - caller can modify Config via their list
    public Config(List<String> servers) {
        this.servers = servers; // caller holds the same reference!
    }

    // BAD: Returns internal reference - caller can modify internals
    public List<String> getServers() {
        return servers; // exposes mutable state!
    }
}

// GOOD: Defensive copy on construction + read-only on return
public class Config {
    private final List<String> servers;

    public Config(List<String> servers) {
        // Defensive copy on input: own the data
        this.servers = List.copyOf(servers); // immutable snapshot
    }

    public List<String> getServers() {
        return servers; // List.copyOf result is already immutable
        // Alternatively: return Collections.unmodifiableList(servers)
        // but List.copyOf already is immutable - nothing to wrap
    }
}

// Usage:
List<String> input = new ArrayList<>(List.of("server1", "server2"));
Config cfg = new Config(input);
input.add("server3"); // doesn't affect cfg
System.out.println(cfg.getServers()); // [server1, server2]
```

> **Code walkthrough:** The BAD constructor stores the caller's reference
> directly - `input.add("server3")` after construction corrupts `cfg`.
> The GOOD version uses `List.copyOf(servers)` which takes an immutable
> snapshot at construction time, independent of the source. The `getServers()`
> return is already immutable (List.copyOf returns an unmodifiable list),
> so callers cannot corrupt internals through the returned reference.

---

### 🎓 Answers by Seniority

**Junior:** `unmodifiableList()` prevents adding/removing through the wrapper
but the original list can still be changed. `List.of()` creates a
truly immutable list where nothing can change it.

**Mid-level:** `Collections.unmodifiableList()` is a VIEW - holds a reference
to the original. The source list can be mutated through its reference.
`List.of()` is backed by no mutable source. `List.copyOf()` takes a
defensive snapshot. Null elements throw NPE in `List.of()` / `List.copyOf()`.

**Senior:** Defensive copying pattern: constructor takes `List.copyOf(input)`
to own the data; getter returns the immutable copy. This prevents both
construction-time modification (caller mutates source after passing) and
access-time modification (caller mutates returned list). `List.copyOf(aList.of())`
returns the same object (optimization - already immutable).

**Staff:** Immutability by convention vs. immutability by guarantee is
a critical API contract decision. `Collections.unmodifiableList()` provides
convention (don't modify through this reference), not guarantee. `List.of()` /
Guava `ImmutableList` provide guarantees. API contracts for collections
should specify: mutable, unmodifiable view, or truly immutable.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                   | Reality                                                                                                                                                                   | Danger                                                                                                |
| --- | --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| 1   | `Collections.unmodifiableList()` makes the list truly immutable | It is a read-only VIEW. The original reference holder can still mutate through the source                                                                                 | Passing unmodifiableList to a method thinking it's safe, while another thread/method holds the source |
| 2   | `List.of()` is equivalent to `Arrays.asList()`                  | `Arrays.asList()` returns a fixed-size but MUTABLE list (set/get work, add/remove don't). `List.of()` is fully immutable (set also throws). `Arrays.asList()` allows null | Using Arrays.asList thinking it's as immutable as List.of()                                           |
| 3   | `Map.of()` maintains insertion order                            | `Map.of()` and `Set.of()` do NOT guarantee iteration order. Order may differ between JVM runs                                                                             | Tests that assert Map.of() iteration order may fail intermittently                                    |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Aliasing through unmodifiableList**

Symptom: A config object's internal list appears to change after
construction.

Root cause: Constructor called `Collections.unmodifiableList(source)`,
stored the wrapper, and returned it. The caller holds `source` and
calls `source.add(x)`. The config object's wrapper reflects the change.

Fix: Use `List.copyOf(source)` in the constructor to take a
defensive snapshot.

---

**Failure 2 - NullPointerException with `List.of()`**

Symptom: Code that works with `new ArrayList<>()` throws NPE
after migrating to `List.of()`.

Root cause: The list contained null elements, which `List.of()` rejects.

Fix: Filter nulls before creating the immutable list, or use
`new ArrayList<>()` if null elements are intentional.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                            |
| ---------------- | --------------------------------------------------------------- |
| 20 min           | View vs copy distinction; back-door problem                     |
| 40 min           | Add List.copyOf; defensive copy pattern; null policy            |
| 1 hour           | Add Arrays.asList comparison; Map.of order; Guava ImmutableList |

---

**[MID] Q1: What is the difference between `Arrays.asList()` and
`List.of()`?** [COMPARISON]

_Why they ask:_ Tests knowledge of two common list-creation methods.

_Likely follow-up:_ "Which one allows null elements?"

| Feature         | `Arrays.asList(arr)`          | `List.of(elements)` |
| --------------- | ----------------------------- | ------------------- |
| null elements   | Allowed                       | Throws NPE          |
| add/remove      | Throws UOE                    | Throws UOE          |
| set(index, val) | Allowed (fixed size, mutable) | Throws UOE          |
| Backed by array | Yes - same array shared       | No                  |
| Java version    | 1.2+                          | 9+                  |

`Arrays.asList()` creates a List backed by the original array - changes
to the array are reflected in the List and vice versa (for array-based
overload). It supports `set()` but not `add()`/`remove()` (fixed size).

`List.of()` is fully immutable - `set()` also throws. Null elements
cause immediate NPE (fail-fast).

_What separates good from great:_ Knowing `Arrays.asList()` allows `set()`
but not `add()`/`remove()`, and that it's backed by the original array.

---

**[SENIOR] Q2: How do you implement defensive copying for a class
with a List field?** [PRODUCTION]

_Why they ask:_ Tests ability to reason about object state encapsulation.

_Likely follow-up:_ "What if the list elements are mutable?"

Two copies needed: on input (construction) and on output (getter).

```java
public final class ServiceConfig {
    private final List<String> endpoints;

    // Defensive copy on construction: decouple from caller's list
    public ServiceConfig(List<String> endpoints) {
        Objects.requireNonNull(endpoints, "endpoints must not be null");
        this.endpoints = List.copyOf(endpoints); // immutable snapshot
    }

    // Return immutable - callers cannot corrupt internal state
    public List<String> getEndpoints() {
        return endpoints; // already immutable from List.copyOf
    }
}
```

What if elements are mutable? `List.copyOf` copies references, not
objects. If `endpoints` is `List<ServerConfig>` and `ServerConfig` is
mutable, callers can mutate the `ServerConfig` objects they got from
the original list.

For true deep immutability: either use immutable value types (`record`)
for elements, or provide `getEndpoints()` that returns a deep-copied
list of cloned elements.

_What separates good from great:_ The shallow copy limitation -
`List.copyOf` copies references, not the objects they point to.
Deep immutability requires immutable element types.

---

**[STAFF] Q3: ARCHITECTURE: When would you choose Guava's
`ImmutableList` over `List.of()`?** [TRADE-OFF]

_Why they ask:_ Tests awareness of third-party alternatives.

_Likely follow-up:_ "What does Guava's ImmutableList guarantee that List.of() doesn't?"

Guava's `ImmutableList` vs `List.of()`:

| Feature            | `List.of()`                                                        | Guava `ImmutableList`                                                     |
| ------------------ | ------------------------------------------------------------------ | ------------------------------------------------------------------------- |
| Java version       | Java 9+                                                            | Java 6+                                                                   |
| Null elements      | NPE                                                                | NPE                                                                       |
| Builder API        | No                                                                 | `ImmutableList.builder()`                                                 |
| Subtype guarantees | `List.of()` is immutable, but any `List` variable could be mutable | `ImmutableList` is a concrete class - type itself guarantees immutability |
| Stream collector   | None                                                               | `ImmutableList.toImmutableList()`                                         |
| Copy of            | `List.copyOf()`                                                    | `ImmutableList.copyOf()`                                                  |

The key advantage of Guava: method signatures can use `ImmutableList<T>`
as the type, GUARANTEEING callers they will receive an immutable list
(not just a `List` that happens to be immutable). `List.of()` returns
`List<T>` - callers need to read the docs or trust conventions.

Use `List.of()` when: Java 9+, no Guava dependency, simple cases.
Use Guava when: need explicit type-level immutability guarantees,
need a builder for conditional construction, or project already uses Guava.

_What separates good from great:_ The type-level guarantee distinction -
`ImmutableList` as a type communicates immutability in the signature;
`List` does not.

---

---

# Collectors: groupingBy, partitioningBy, joining, toUnmodifiableMap

**Interview Weight:** medium - Tests fluency with Stream terminal
operations for aggregation.

---

### 🎯 Model Answer

**30 seconds:**

> `Collectors` provides factory methods for stream terminal aggregation.
> Key methods: `groupingBy(classifier)` - groups elements into a
> `Map<K, List<V>>`; `partitioningBy(predicate)` - splits into true/false
> `Map<Boolean, List<T>>`; `joining(delimiter)` - concatenates strings;
> `toUnmodifiableMap(keyMapper, valueMapper)` - immutable Map.
> The second argument to `groupingBy` is a downstream Collector for
> further aggregation within each group.

**3 minutes (Senior):**

> `Collectors.groupingBy(classifier)` collects stream elements into a
> `Map<K, List<V>>` where the key is the classifier's return value.
> The downstream Collector defaults to `Collectors.toList()` but can
> be any Collector: `counting()`, `summingInt()`, `mapping()`,
> `joining()`, or another `groupingBy()` for nested grouping.
>
> `partitioningBy(predicate)` is a specialized `groupingBy` with two
> groups: `true` (predicate matches) and `false` (doesn't match). The
> Map always has BOTH keys even if one group is empty - unlike
> `groupingBy` which omits groups with no elements.
>
> `toUnmodifiableMap(keyFn, valueFn)` (Java 10) is equivalent to
> `Collectors.toMap()` but returns an immutable map. `toMap` throws
> `IllegalStateException` on duplicate keys; provide a merge function
> (`(a,b) -> b`) to handle duplicates.
>
> `Collectors.teeing(downstream1, downstream2, merger)` (Java 12)
> collects to two downstream collectors and merges the results.

**Framework:** GROUPINGBY (key -> List) + DOWNSTREAM (further aggregation)

- PARTITIONINGBY (true/false split) + JOINING + UNMODIFIABLE

_Adapting up:_ Discuss `Collectors.collectingAndThen()` for transforming
the Collector result, and `Collectors.toMap()` duplicate key handling.

_Adapting down:_ groupingBy groups by a field. joining concatenates strings.
partitioningBy splits by predicate.

**Blank Mind Recovery:**

**(1) Restate:** "Collectors aggregates stream elements. groupingBy
groups into a Map. partitioningBy splits true/false. joining concatenates.
toUnmodifiableMap makes an immutable map."

**(2) First principles:** "Stream reduces elements to a single result.
Collectors specify what kind of result: a list, a map, a string.
groupingBy is 'SQL GROUP BY' for Java."

**(3) Bridge:** "Collectors are the chefs of the stream kitchen.
groupingBy = plate food by type. partitioningBy = vegetarian vs
non-vegetarian. joining = blend everything into one. toMap = store
in labeled containers."

---

### 📘 Concept Explanation

**`groupingBy` with downstream collectors:**

```java
List<Employee> employees = List.of(
    new Employee("Alice", "Eng",  90_000),
    new Employee("Bob",   "Eng",  85_000),
    new Employee("Carol", "HR",   70_000),
    new Employee("Dave",  "HR",   75_000)
);

// Simple grouping: dept -> List<Employee>
Map<String, List<Employee>> byDept =
    employees.stream()
        .collect(Collectors.groupingBy(Employee::dept));

// Downstream: count per group
Map<String, Long> countByDept =
    employees.stream()
        .collect(Collectors.groupingBy(
            Employee::dept, Collectors.counting()));

// Downstream: sum salaries per group
Map<String, Integer> totalSalaryByDept =
    employees.stream()
        .collect(Collectors.groupingBy(
            Employee::dept,
            Collectors.summingInt(Employee::salary)));

// Downstream: map values to names (not full objects)
Map<String, List<String>> namesByDept =
    employees.stream()
        .collect(Collectors.groupingBy(
            Employee::dept,
            Collectors.mapping(Employee::name,
                               Collectors.toList())));

// Nested grouping: dept -> salary range -> count
Map<String, Map<String, Long>> nested =
    employees.stream()
        .collect(Collectors.groupingBy(
            Employee::dept,
            Collectors.groupingBy(
                e -> e.salary() > 80_000 ? "high" : "low",
                Collectors.counting())));
```

**`partitioningBy` always returns both keys:**

```java
// partitioningBy: always produces both true and false keys
Map<Boolean, List<Employee>> partition =
    employees.stream()
        .collect(Collectors.partitioningBy(
            e -> e.salary() > 80_000));
// {true=[Alice, Bob], false=[Carol, Dave]}
// Even if no employees have salary <= 80k, false key is present (empty list)

// Compare to groupingBy:
Map<String, List<Employee>> grouped =
    employees.stream()
        .filter(e -> e.dept().equals("Eng"))
        .collect(Collectors.groupingBy(Employee::dept));
// {Eng=[Alice, Bob]}  <- "HR" key is ABSENT (not in filtered stream)
```

**`joining` and `toUnmodifiableMap`:**

```java
// joining: concatenate strings with delimiter
String names = employees.stream()
    .map(Employee::name)
    .collect(Collectors.joining(", "));
// "Alice, Bob, Carol, Dave"

String wrapped = employees.stream()
    .map(Employee::name)
    .collect(Collectors.joining(", ", "[", "]"));
// "[Alice, Bob, Carol, Dave]"

// toUnmodifiableMap: immutable result (Java 10)
Map<String, Integer> salaryById = employees.stream()
    .collect(Collectors.toUnmodifiableMap(
        Employee::name,   // key mapper
        Employee::salary  // value mapper
    ));
// Throws IllegalStateException if duplicate keys!

// With merge function for duplicates:
Map<String, Integer> withMerge = employees.stream()
    .collect(Collectors.toMap(
        Employee::dept,     // key: dept (may have duplicates)
        Employee::salary,   // value
        Integer::max        // merge: keep highest salary per dept
    ));
```

**`collectingAndThen` - transform the result:**

```java
// Collect to list, then wrap in unmodifiable (pre-Java 16)
List<String> unmodNames = employees.stream()
    .map(Employee::name)
    .collect(Collectors.collectingAndThen(
        Collectors.toList(),
        Collections::unmodifiableList));

// Modern alternative:
List<String> names2 = employees.stream()
    .map(Employee::name)
    .collect(Collectors.toUnmodifiableList()); // Java 10
```

---

### 💻 Code Example

#### Invoice grouping by status and currency

```java
import java.util.*;
import java.util.stream.*;

record Invoice(String id, String status,
               String currency, double amount) {}

public class InvoiceReporter {

    public static Map<String, DoubleSummaryStatistics>
            summaryByStatus(List<Invoice> invoices) {

        // Group by status, summarize amounts per group
        return invoices.stream()
            .collect(Collectors.groupingBy(
                Invoice::status,
                Collectors.summarizingDouble(Invoice::amount)));
        // Result: {"PAID" -> {count=3, sum=1000.0, avg=333.3, ...},
        //          "PENDING" -> {...}}
    }

    public static Map<String, Map<String, Double>>
            totalByStatusAndCurrency(List<Invoice> invoices) {

        // Nested grouping: status -> currency -> total
        return invoices.stream()
            .collect(Collectors.groupingBy(
                Invoice::status,
                Collectors.groupingBy(
                    Invoice::currency,
                    Collectors.summingDouble(Invoice::amount))));
    }

    public static String toCsvLine(List<Invoice> invoices) {
        return invoices.stream()
            .map(inv -> String.join(",",
                inv.id(), inv.status(),
                inv.currency(),
                String.format("%.2f", inv.amount())))
            .collect(Collectors.joining("\n"));
    }
}
```

> **Code walkthrough:** `summarizingDouble` returns a `DoubleSummaryStatistics`
> per group: count, sum, min, max, average in one pass. The nested
> `groupingBy` produces a two-level map: status -> currency -> total.
> This is equivalent to a SQL `GROUP BY status, currency SUM(amount)`.
> `joining("\n")` produces a CSV string without explicit StringBuilder.
> All three use one stream pass (no intermediate materializations).

---

### 🎓 Answers by Seniority

**Junior:** `Collectors.groupingBy(field)` groups stream elements into
a Map. `joining(delimiter)` concatenates Strings.
`partitioningBy(predicate)` splits into true/false.

**Mid-level:** `groupingBy` takes an optional downstream collector:
`counting()`, `summingInt()`, `mapping()` for per-group aggregation.
`toMap()` throws on duplicate keys - provide merge function to handle
them. `partitioningBy` always returns both true and false keys.

**Senior:** `collectingAndThen(collector, finisher)` transforms the
collected result. `Collectors.teeing(c1, c2, merger)` (Java 12) collects
to two collectors in one pass and merges. `Collectors.toUnmodifiableList/Map/Set`
(Java 10) replaces `collectingAndThen(toList(), Collections::unmodifiableList)`.

**Staff:** `groupingByConcurrent()` uses `ConcurrentHashMap` as the
output map and processes in parallel (requires parallel streams; output
map insertion is thread-safe). `groupingBy()` on a parallel stream uses
a thread-local accumulator per thread and merges - result is `HashMap`.
Use `groupingByConcurrent()` when you want concurrent accumulation
without the merge step.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                                       | Reality                                                                                                                                                                | Danger                                                              |
| --- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| 1   | `Collectors.toMap()` handles duplicate keys gracefully                              | `toMap()` throws `IllegalStateException` on duplicate keys. Must provide a merge function: `toMap(key, value, (a,b) -> b)`                                             | Runtime exception in production when data has unexpected duplicates |
| 2   | `groupingBy` result map is immutable                                                | `groupingBy` returns a `HashMap` (mutable). The inner Lists are also `ArrayList` (mutable). Only `toUnmodifiableMap` and `toUnmodifiableList` return immutable results | Accidentally mutating the result of groupingBy                      |
| 3   | `partitioningBy` and `groupingBy(e -> predicate ? "true" : "false")` are equivalent | `partitioningBy` always includes both keys (true and false). `groupingBy` on a string "true"/"false" omits keys with no elements                                       | Missing expected null-check on groupingBy result for empty groups   |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - `IllegalStateException` from duplicate keys in `toMap()`**

Symptom: `java.lang.IllegalStateException: Duplicate key <value>`
from a `Collectors.toMap()` operation.

Root cause: Stream has two elements with the same key mapper result.
`toMap()` does not allow duplicates without a merge function.

Fix: `Collectors.toMap(keyMapper, valueMapper, (a, b) -> b)` keeps
the last value. Or use `groupingBy` if multiple values per key
is the expected model.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                |
| ---------------- | --------------------------------------------------- |
| 20 min           | groupingBy, partitioningBy, joining, toMap          |
| 40 min           | Add downstream collectors; duplicate key handling   |
| 1 hour           | Add collectingAndThen; teeing; groupingByConcurrent |

---

**[MID] Q1: How do you count elements per group using `groupingBy`?**
[HANDS-ON]

_Why they ask:_ Tests downstream collector knowledge.

_Likely follow-up:_ "How do you get the sum per group?"

```java
Map<String, Long> countByDept = employees.stream()
    .collect(Collectors.groupingBy(
        Employee::dept,
        Collectors.counting())); // downstream collector

// Count: counting() -> Map<K, Long>
// Sum:   summingInt(fn) -> Map<K, Integer>
// Stats: summarizingInt(fn) -> Map<K, IntSummaryStatistics>
// Avg:   averagingInt(fn) -> Map<K, Double>
// Max:   maxBy(comparator) -> Map<K, Optional<T>>
```

The second argument to `groupingBy` is the "downstream Collector"
applied to each group. Defaults to `Collectors.toList()`.

_What separates good from great:_ Knowing `summarizingInt()` returns
a `IntSummaryStatistics` with count, sum, min, max, average in one
pass - more efficient than calling separate collectors.

---

**[SENIOR] Q2: How do you handle duplicate keys in `Collectors.toMap()`?**
[PRODUCTION]

_Why they ask:_ Tests awareness of a common production failure.

_Likely follow-up:_ "How do you accumulate values for duplicate keys?"

`Collectors.toMap()` signature:

```java
toMap(keyMapper, valueMapper)
// Throws IllegalStateException on duplicate keys

toMap(keyMapper, valueMapper, mergeFunction)
// merge(existingValue, newValue) resolves duplicate keys

toMap(keyMapper, valueMapper, mergeFunction, mapSupplier)
// mapSupplier: () -> new LinkedHashMap<>() for ordered result
```

Common patterns:

```java
// Keep last value for duplicates:
toMap(keyFn, valueFn, (a, b) -> b)

// Keep first value:
toMap(keyFn, valueFn, (a, b) -> a)

// Concatenate on duplicate:
toMap(Employee::dept, Employee::name,
      (a, b) -> a + ", " + b)
// Result: {"Eng" -> "Alice, Bob", "HR" -> "Carol, Dave"}

// Sum on duplicate:
toMap(Employee::dept, Employee::salary, Integer::sum)
```

If each key should have multiple values: use `groupingBy` instead:

```java
// groupingBy(keyFn) -> Map<K, List<V>> (handles duplicates as list)
```

_What separates good from great:_ Knowing `groupingBy` is the right
choice when multiple values per key is the domain model (not a degenerate case).

---

**[SENIOR] Q3: What is `Collectors.teeing()` and when would you
use it?** [CONCEPTUAL]

_Why they ask:_ Tests Java 12 additions.

_Likely follow-up:_ "Can you achieve the same thing without teeing?"

`Collectors.teeing(downstream1, downstream2, merger)` (Java 12):
processes each element through BOTH downstream collectors, then
combines their results using the merger function. Two collectors,
one stream pass.

Use case: when you need two different aggregations of the same stream
without iterating twice.

```java
record Stats(long count, double average) {}

// Without teeing: two stream passes
long count = employees.stream().count();
double avg = employees.stream()
    .mapToInt(Employee::salary).average().orElse(0);

// With teeing: one stream pass
Stats stats = employees.stream().collect(
    Collectors.teeing(
        Collectors.counting(),
        Collectors.averagingInt(Employee::salary),
        (count2, avg2) -> new Stats(count2, avg2)
    ));
```

Can be achieved without `teeing` using `summarizingInt()`:
`IntSummaryStatistics stats = employees.stream().collect(
Collectors.summarizingInt(Employee::salary))`.

`teeing` is more useful when the two collectors need different
classification logic, not just different aggregation of the same value.

_What separates good from great:_ Noting that `summarizingInt()` covers
the count+average case, and `teeing` is most valuable for qualitatively
different aggregations.

---

---

# Stream-to-Collection Patterns: collect(), toList(), and Materialization

**Interview Weight:** medium - Tests ability to choose the right
terminal collection strategy.

---

### 🎯 Model Answer

**30 seconds:**

> Streams are lazy; `collect()` materializes them. `stream.collect(Collectors.toList())`
> produces a mutable `ArrayList`. `stream.toList()` (Java 16) produces
> an unmodifiable list. `Collectors.toUnmodifiableList()` (Java 10)
> is the older equivalent. Key principle: minimize materialization -
> only collect when you actually need a concrete collection; chain
> further operations on the stream instead.

**3 minutes (Senior):**

> `collect()` is a mutable reduction: it uses a Collector's supplier
> (creates an accumulator, e.g., `new ArrayList<>()`), accumulator
> (adds each element), and combiner (for parallel streams, merges
> partial results).
>
> Collection options in modern Java:
>
> - `stream.collect(Collectors.toList())`: returns `ArrayList`
>   (mutable, allows null, no size guarantee until all elements consumed)
> - `stream.toList()` (Java 16): returns an unmodifiable list
>   (implementation-defined, allows null, O(n) space)
> - `stream.collect(Collectors.toUnmodifiableList())` (Java 10):
>   equivalent to `toList()` for unmodifiable, but via Collectors
> - `stream.collect(Collectors.toCollection(LinkedList::new))`:
>   specific collection type
>
> Premature materialization anti-pattern: materializing to a list
> just to then stream again:
>
> ```java
> // BAD: materializes, then re-streams
> list.stream().filter(x).collect(toList()).stream().map(y)...
> // GOOD: single stream chain
> list.stream().filter(x).map(y)...collect(toList())
> ```

**Framework:** COLLECT (mutable reduction) + OPTIONS (toList, toList(),
toUnmodifiable) + PREMATURE-MATERIALIZATION anti-pattern

_Adapting up:_ Discuss parallel stream collect, Collector's combiner
function, and how Collectors can be custom (implementing `Collector<T,A,R>`).

_Adapting down:_ `collect(toList())` = mutable ArrayList. `.toList()` =
immutable list (Java 16+).

**Blank Mind Recovery:**

**(1) Restate:** "Streams are lazy. collect() materializes the result.
toList() is the Java 16 shorthand for an immutable list. Avoid collecting
and re-streaming - keep the chain."

**(2) First principles:** "A stream is a pipeline of operations not yet
executed. collect() says 'execute now and give me a collection.' Lazy
evaluation means nothing runs until a terminal operation."

**(3) Bridge:** "Stream is an assembly line plan. collect() is 'run the
line and package the output.' Why stop the line halfway, re-box, and
start a new line? Keep going to the end."

---

### 📘 Concept Explanation

**Stream collection options:**

```java
Stream<String> stream = list.stream().filter(s -> !s.isEmpty());

// Mutable ArrayList (most flexible, pre-Java 16 default)
List<String> mutable = stream.collect(Collectors.toList());

// Unmodifiable list - immutable snapshot (Java 10)
List<String> unmod = stream.collect(
    Collectors.toUnmodifiableList());

// Unmodifiable list - Java 16 shorthand
List<String> simple = stream.toList(); // most concise

// Specific collection type
List<String> linked = stream.collect(
    Collectors.toCollection(LinkedList::new));

// Always unmodifiable:
Set<String> set = stream.collect(Collectors.toUnmodifiableSet());

// For sorted: TreeSet
Set<String> sorted = stream.collect(
    Collectors.toCollection(TreeSet::new));
```

**`Collector<T, A, R>` three components:**

```
T = input element type
A = mutable accumulation type (e.g., ArrayList)
R = result type (e.g., List)

Collector phases:
  1. supplier(): () -> new ArrayList<T>()  // create accumulator
  2. accumulator(): (list, elem) -> list.add(elem)  // fold element
  3. combiner(): (list1, list2) -> { list1.addAll(list2); return list1; }
     // for parallel stream merge
  4. finisher(): list -> Collections.unmodifiableList(list)
     // optional transform after accumulation
```

**Premature materialization patterns:**

```java
// BAD: materializes to List, then re-streams
users.stream()
    .filter(User::isActive)
    .collect(Collectors.toList())  // <- unnecessary materialization
    .stream()
    .map(User::getName)
    .collect(Collectors.toList());

// GOOD: single stream chain
List<String> names = users.stream()
    .filter(User::isActive)
    .map(User::getName)
    .collect(Collectors.toList()); // one materialization at end

// BAD: materializing just to call forEach
users.stream()
    .filter(User::isActive)
    .collect(Collectors.toList())
    .forEach(this::notify); // unnecessary list

// GOOD: forEach is a terminal operation
users.stream()
    .filter(User::isActive)
    .forEach(this::notify);
```

**`stream.toList()` vs `Collectors.toList()` (Java 16):**

| Feature       | `stream.toList()`        | `Collectors.toList()` |
| ------------- | ------------------------ | --------------------- |
| Java version  | 16+                      | 8+                    |
| Mutability    | Immutable (UOE on write) | Mutable (ArrayList)   |
| Null elements | Allowed                  | Allowed               |
| Verbosity     | Less                     | More                  |

---

### 💻 Code Example

#### Choosing collection strategy

```java
import java.util.*;
import java.util.stream.*;

public class OrderProcessor {

    // BAD: collects to mutable list, caller may mutate
    public List<String> getActiveOrderIds(List<Order> orders) {
        return orders.stream()
            .filter(Order::isActive)
            .map(Order::getId)
            .collect(Collectors.toList()); // mutable!
    }

    // GOOD: unmodifiable result - clear API contract
    public List<String> getActiveOrderIds(List<Order> orders) {
        return orders.stream()
            .filter(Order::isActive)
            .map(Order::getId)
            .toList(); // immutable (Java 16+)
    }

    // When mutable is needed: explicit
    public List<Order> buildWorkQueue(List<Order> orders) {
        // Caller WILL add/remove from this list
        List<Order> queue = orders.stream()
            .filter(o -> o.status() == PENDING)
            .sorted(Comparator.comparing(Order::priority).reversed())
            .collect(Collectors.toCollection(
                ArrayList::new)); // explicit mutable ArrayList
        return queue; // document it's mutable in Javadoc
    }
}
```

> **Code walkthrough:** Returning `.toList()` (Java 16) communicates
> to callers that the result is read-only and they should not cache
> a mutable reference. When callers need to add/remove elements,
> explicitly use `Collectors.toCollection(ArrayList::new)` to signal
> intent. The naming distinction (`getActiveOrderIds` returning
> immutable vs `buildWorkQueue` returning mutable) makes the contract
> clear from the method name.

---

### 🎓 Answers by Seniority

**Junior:** `stream.collect(Collectors.toList())` gathers stream elements
into a list. `stream.toList()` is the shorter Java 16 version that
returns an unmodifiable list.

**Mid-level:** `toList()` (Java 16) returns unmodifiable; `toList()`
allows null elements. Avoid premature materialization: chaining stream
operations is more efficient than collect-then-stream. Use
`toCollection(LinkedList::new)` when a specific collection type is needed.

**Senior:** `Collector<T,A,R>` has three functions: supplier (create
accumulator), accumulator (fold element), combiner (parallel merge).
Custom collectors implement this interface. The combiner is only called
in parallel streams; sequential streams ignore it. `toList()` eliminates
the collector boilerplate for the most common terminal operation.

**Staff:** Parallel stream `collect()` uses the combiner to merge partial
results from different threads. `Collectors.groupingByConcurrent()` avoids
the combiner overhead by using a concurrent accumulator directly. For
high-throughput data transformation, avoiding intermediate materializations
(keeping as stream as long as possible) reduces GC pressure.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                | Reality                                                                                                                                                                                          | Danger                                          |
| --- | ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------------------------------- |
| 1   | `stream.toList()` is available in Java 8                     | `stream.toList()` requires Java 16. Before Java 16: use `Collectors.toList()` or `Collectors.toUnmodifiableList()`                                                                               | Compile error on pre-16 JDK                     |
| 2   | `Collectors.toList()` returns an immutable list              | Returns a mutable `ArrayList`. Only `toUnmodifiableList()` and `stream.toList()` return unmodifiable                                                                                             | Callers mutate the returned list unexpectedly   |
| 3   | Collecting then re-streaming is equivalent to not collecting | Materializing to a list consumes all elements (applies all lazy operations up to that point), allocates a List object, then the second stream re-applies. This doubles memory and loses laziness | Unnecessary O(n) memory allocation in hot paths |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Premature materialization in hot path**

Symptom: GC pressure from large temporary List allocations.

Root cause: `stream.filter().collect(toList()).stream().map().collect(toList())`
creates two large intermediate lists.

Fix: Chain operations in a single stream pipeline with one
terminal `collect()` at the end.

---

**Failure 2 - Mutating `stream.toList()` result**

Symptom: `UnsupportedOperationException` when adding to a collected list.

Root cause: Code uses `.toList()` (Java 16 - immutable) and tries
to `add()` to the result.

Fix: Use `Collectors.toList()` or `new ArrayList<>(stream.toList())`
when the result needs to be mutable.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                  |
| ---------------- | ----------------------------------------------------- |
| 15 min           | collect() terminal op; toList() mutable vs immutable  |
| 30 min           | Add premature materialization; Collector internals    |
| 45 min           | Add custom Collector; parallel combiner; toCollection |

---

**[MID] Q1: What is the difference between `stream.toList()` and
`stream.collect(Collectors.toList())`?** [COMPARISON]

_Why they ask:_ Tests Java 16 API awareness.

_Likely follow-up:_ "What Java version introduced stream.toList()?"

`stream.toList()` (Java 16): returns an UNMODIFIABLE list.
Shorthand for the common pattern. Allows null elements.

`stream.collect(Collectors.toList())` (Java 8+): returns a MUTABLE
`ArrayList`. The specification does not guarantee the exact type
(could be any List implementation), but the JDK returns ArrayList.

In practice: prefer `stream.toList()` for Java 16+ code when the
result is read-only. Use `Collectors.toList()` when you need to add
to the result, or when targeting Java < 16.

Migration: `stream.collect(Collectors.toList())` to `stream.toList()`
is NOT always safe if callers mutate the returned list. Audit before
migrating.

_What separates good from great:_ The migration risk - changing from
`Collectors.toList()` to `toList()` can break callers that mutate
the result.

---

**[SENIOR] Q2: How does a custom `Collector` work and when would
you write one?** [CONCEPTUAL]

_Why they ask:_ Tests depth of Stream API understanding.

_Likely follow-up:_ "What is the `combiner()` used for?"

```java
// Custom Collector example: collect to String with header/footer
public static Collector<String, StringBuilder, String>
        toWrappedString(String header, String footer) {
    return Collector.of(
        StringBuilder::new,  // supplier: create accumulator
        (sb, s) -> {         // accumulator: add element
            if (sb.length() > 0) sb.append(", ");
            sb.append(s);
        },
        StringBuilder::append, // combiner: merge parallel results
        sb -> header + sb + footer  // finisher: transform result
    );
}

// Usage:
String result = Stream.of("A", "B", "C")
    .collect(toWrappedString("[", "]"));
// "[A, B, C]"
```

When to write a custom Collector:

- `Collectors` factory methods don't provide the needed aggregation
- Collecting into a non-standard type (stats object, summary record)
- Combining multiple aggregations that share the same accumulator
  (more efficient than using `teeing` for 3+ aggregations)

The `combiner()` function is used ONLY in parallel streams to merge
partial results from different threads. In sequential streams, the
combiner is never called.

_What separates good from great:_ The combiner is only called in
parallel - this is why `groupingBy()` (not `groupingByConcurrent()`)
is safe as a sequential collector even without thread-safe accumulator.

---

**[STAFF] Q3: BEHAVIORAL: Describe a time you optimized a data
processing pipeline involving stream collection.** [BEHAVIORAL - STAR]

_Why they ask:_ Tests production stream optimization experience.

_Likely follow-up:_ "How did you measure the improvement?"

**Situation:** A reporting service generated a monthly summary for
each customer, processing 100k transaction records. Processing time
was 8 seconds for a full report.

**Task:** Reduce report generation time.

**Action:** Profiled with JFR (Java Flight Recorder). Found 60% of
time in GC, driven by 15 intermediate list allocations. The pipeline:

```java
// BAD: 15 intermediate materializations
List<Tx> all = txService.getAll();
List<Tx> valid = all.stream()
    .filter(Tx::isValid).collect(toList());    // list #1
List<Tx> recent = valid.stream()
    .filter(Tx::isRecent).collect(toList());   // list #2
Map<String, List<Tx>> byCustomer = recent.stream()
    .collect(groupingBy(Tx::customerId));      // list #3+
// ... 12 more similar patterns
```

Refactored to single-pass:

```java
// GOOD: single pass, one materialization
Map<String, DoubleSummaryStatistics> report =
    txService.stream()  // source as stream (no initial list)
        .filter(Tx::isValid)
        .filter(Tx::isRecent)
        .collect(groupingBy(
            Tx::customerId,
            summarizingDouble(Tx::amount)));  // one materialization
```

Also switched the source from `getAll().stream()` to a lazy database
stream (Spring Data Scroll API) to avoid loading all 100k records
into memory.

**Result:** Processing time dropped from 8 seconds to 1.2 seconds.
GC overhead dropped from 60% to 8%.

_What separates good from great:_ Using JFR for profiling (not guessing),
AND addressing the data source (switching to lazy stream) in addition
to the pipeline.

---

---

# Array-to-Collection Bridges: Arrays.asList(), List.of(), Mutation Trap

**Interview Weight:** medium - A common source of bugs; tests
practical knowledge of array-collection interop.

---

### 🎯 Model Answer

**30 seconds:**

> Three ways to create a List from an array: `Arrays.asList(arr)` -
> fixed-size mutable list backed by the array (add/remove throw, set
> works); `List.of(elements)` - fully immutable, no nulls;
> `new ArrayList<>(Arrays.asList(arr))` - true mutable copy, disconnected
> from the array. The mutation trap: `Arrays.asList` is backed by the
> original array - mutating via `set()` changes the original array and
> vice versa.

**3 minutes (Senior):**

> `Arrays.asList(T... a)` returns a `java.util.Arrays$ArrayList` (an
> inner class, NOT `java.util.ArrayList`). This inner class is backed by
> the original array `a`. `get(i)` reads `a[i]`; `set(i,v)` writes to
> `a[i]`. The array and the list share the same memory. But `add()` and
> `remove()` throw `UnsupportedOperationException` because the backing
> array has fixed size.
>
> The mutation trap: if you pass an array to `Arrays.asList()`, changes
> to the array are visible through the list, and vice versa. This is
> often surprising and leads to bugs where "the list changed" because
> the original array was modified.
>
> For primitive arrays: `Arrays.asList(intArray)` does NOT work as
> expected. `int[]` is not a `T[]`; the compiler infers `T = int[]`
> and returns `List<int[]>` containing one element (the array itself).
> Use `IntStream.of(arr).boxed().toList()` for primitive array to
> `List<Integer>`.

**Framework:** ARRAYSASLIST (backed by array, fixed-size, mutable via set)

- LIST.OF (immutable, no nulls) + NEW-ARRAYLIST (true copy) +
  PRIMITIVE-TRAP

_Adapting up:_ Discuss the generic type inference difference for
`Arrays.asList(new int[]{1,2,3})` and why it returns `List<int[]>`.

_Adapting down:_ Arrays.asList is fixed size. Use `new ArrayList<>(Arrays.asList(arr))`
for a fully mutable copy.

**Blank Mind Recovery:**

**(1) Restate:** "Arrays.asList wraps the array (fixed size, shared
memory). List.of is immutable. new ArrayList<>(Arrays.asList(arr))
is a true mutable copy. The mutation trap: Arrays.asList and original
array are the same memory."

**(2) First principles:** "An array has fixed size. Arrays.asList
creates a List view over the same fixed-size memory. For a resizable
list, copy to ArrayList."

**(3) Bridge:** "Arrays.asList is like a plastic folder for loose papers

- protects them and lets you reorder (set), but you can't add new
  pages to the folder (fixed size). ArrayList copy is a new folder with
  a photocopied set - completely independent."

---

### 📘 Concept Explanation

**Comparison:**

| Method               | Mutable (add/remove) | Mutable (set) | Null ok  | Backed by array | Java version |
| -------------------- | -------------------- | ------------- | -------- | --------------- | ------------ |
| `Arrays.asList(arr)` | No (UOE)             | Yes           | Yes      | Yes - shared    | 1.2+         |
| `List.of(elems)`     | No (UOE)             | No (UOE)      | No (NPE) | No              | 9+           |
| `new ArrayList<>(c)` | Yes                  | Yes           | Yes      | No - copy       | 1.2+         |
| `List.copyOf(c)`     | No (UOE)             | No (UOE)      | No (NPE) | No              | 10+          |

**The mutation trap in detail:**

```java
String[] arr = {"A", "B", "C"};
List<String> list = Arrays.asList(arr);

// Mutation through list affects array:
list.set(0, "Z");
System.out.println(arr[0]); // "Z" - array changed!

// Mutation through array affects list:
arr[1] = "Y";
System.out.println(list.get(1)); // "Y" - list changed!

// This is the same memory:
list.add("D"); // throws UnsupportedOperationException
```

**Primitive array trap:**

```java
int[] primitiveArr = {1, 2, 3};

// WRONG: Arrays.asList on int[] - returns List<int[]> with ONE element
List<int[]> wrong = Arrays.asList(primitiveArr);
// wrong.size() == 1!  (one element: the int[] array itself)
System.out.println(wrong.get(0)); // [I@<address> (array object)

// Integer[] works correctly:
Integer[] boxedArr = {1, 2, 3};
List<Integer> correct = Arrays.asList(boxedArr); // size == 3

// Primitive array to List<Integer> properly:
List<Integer> fromPrimitive = Arrays.stream(primitiveArr)
    .boxed()
    .collect(Collectors.toList());
// OR (Java 16+):
List<Integer> fromPrimitive2 = Arrays.stream(primitiveArr)
    .boxed().toList();
```

**Collection to array:**

```java
List<String> list = List.of("A", "B", "C");

// Correct: toArray with type-inferring constructor reference
String[] arr = list.toArray(String[]::new); // Java 11

// Pre-Java 11:
String[] arr = list.toArray(new String[0]);
// Note: new String[0] is preferred over new String[list.size()]
// The JVM optimizes allocation when size is 0
```

---

### 💻 Code Example

#### Common conversion scenarios

```java
import java.util.*;
import java.util.stream.*;

public class ArrayCollectionBridge {

    // BAD: Arrays.asList exposes array backing - mutation trap
    public static List<String> fromConfig(String[] config) {
        return Arrays.asList(config);
        // Caller's mutation of the list affects original config array!
    }

    // GOOD: true copy, disconnected from original
    public static List<String> fromConfig(String[] config) {
        return new ArrayList<>(Arrays.asList(config));
        // or: return List.of(config) if immutable is acceptable
    }

    // GOOD: Java 9+ immutable
    public static List<String> fromConfigImmutable(String[] config) {
        return List.of(config); // fully immutable, no array sharing
    }

    // Primitive array to List:
    public static List<Integer> fromInts(int[] ints) {
        return Arrays.stream(ints).boxed().toList(); // Java 16
    }

    // List to array:
    public static String[] toArray(List<String> list) {
        return list.toArray(String[]::new); // Java 11 clean syntax
    }

    // WRONG: raw Object[] return
    public static String[] toArrayWrong(List<String> list) {
        return (String[]) list.toArray(); // ClassCastException risk!
        // list.toArray() returns Object[], cast to String[] may fail
    }
}
```

> **Code walkthrough:** `fromConfig` with `Arrays.asList()` shares
> memory with the input array - any modification to the returned list
> propagates back to the original array. The GOOD version with
> `new ArrayList<>(Arrays.asList(config))` creates an independent copy:
> the ArrayList has its own backing array, disconnected from `config`.
> `List.of(config)` is immutable and independent - no back-door mutation.
> `list.toArray()` returns `Object[]` - the cast to `String[]` succeeds
> only if the JVM can verify at runtime the array contains only Strings
> (typically fails with ClassCastException).

---

### 🎓 Answers by Seniority

**Junior:** `Arrays.asList(arr)` creates a list from an array.
`new ArrayList<>(Arrays.asList(arr))` is needed if you want to add
elements.

**Mid-level:** `Arrays.asList` is backed by the original array:
`set()` changes the array; array changes affect the list. For a
true copy, use `new ArrayList<>(Arrays.asList(arr))` or `List.of(arr)`.
For primitive `int[]`, use `Arrays.stream(arr).boxed().toList()`.

**Senior:** The backing memory sharing is the key design detail:
`Arrays$ArrayList` (the inner class returned by `Arrays.asList`) holds
a reference to the `Object[]` parameter. `get`/`set` read/write
directly to that array. This is why `list.toArray()` on this list
returns the SAME array object (not a copy) in some JDK versions.

**Staff:** API design: never return `Arrays.asList()` from a public
method. The caller cannot add elements (surprising UOE) and any
modification leaks back to your internal array. Always return a copy
(`new ArrayList<>()` or `List.of()`) from public APIs. Document the
mutability contract explicitly.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                      | Reality                                                                                                                                                   | Danger                                                            |
| --- | -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| 1   | `Arrays.asList(int[])` returns `List<Integer>`     | Returns `List<int[]>` with ONE element: the array itself. Must use `Integer[]` or `Arrays.stream(arr).boxed()`                                            | `list.size() == 1` when expecting the array length                |
| 2   | `Arrays.asList(arr)` returns `java.util.ArrayList` | Returns `java.util.Arrays$ArrayList` (private inner class). Same interface, different implementation. Missing `add()`/`remove()` support                  | Code that checks `instanceof ArrayList` fails; `add()` throws UOE |
| 3   | `list.toArray()` is safe to cast to `String[]`     | `list.toArray()` returns `Object[]`. Casting to `String[]` compiles but throws `ClassCastException` at runtime. Use `list.toArray(String[]::new)` instead | Runtime ClassCastException far from the cast site                 |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Mutation trap: array changes through list**

Symptom: An array unexpectedly changes values after code that
"only reads" the list.

Root cause: The list was created with `Arrays.asList(arr)` and
`list.set(i, newValue)` was called, directly writing to the
original array.

Diagnostic: Check all call sites that receive the list for `set()`
calls.

Fix: Use `List.copyOf(Arrays.asList(arr))` or `new ArrayList<>(Arrays.asList(arr))`
to break the array-list memory sharing.

---

**Failure 2 - `UnsupportedOperationException` from `Arrays.asList()`**

Symptom: `UnsupportedOperationException` when calling `list.add()` on
a list received from a utility method.

Root cause: The method returns `Arrays.asList()` result directly.

Fix: Either document the list is fixed-size (interface contract), or
return a mutable copy: `return new ArrayList<>(Arrays.asList(arr))`.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                     |
| ---------------- | -------------------------------------------------------- |
| 20 min           | Arrays.asList vs List.of; mutation trap; primitive array |
| 40 min           | Add Arrays$ArrayList distinction; toArray semantics      |
| 1 hour           | Add toArray type-safe version; API design contract       |

---

**[MID] Q1: What is the "mutation trap" of `Arrays.asList()`?**
[DEBUGGING]

_Why they ask:_ Tests awareness of this specific gotcha.

_Likely follow-up:_ "How do you avoid it?"

`Arrays.asList(arr)` returns a List view backed by the original array.
The `set(i, v)` method writes to `arr[i]` directly. The array reference
and the list reference point to the same memory.

```java
String[] arr = {"A", "B"};
List<String> list = Arrays.asList(arr);
list.set(0, "Z");
System.out.println(arr[0]); // "Z" - array mutated!
```

This is the "mutation trap" - it surprises developers who think
`Arrays.asList` makes a copy.

Avoidance: `List.of(arr)` creates an independent immutable list.
`new ArrayList<>(Arrays.asList(arr))` creates an independent mutable list.

_What separates good from great:_ Knowing the mutation goes both
ways (modifying the array also changes the list).

---

**[SENIOR] Q2: How do you correctly convert a `List<String>` to
`String[]`?** [HANDS-ON]

_Why they ask:_ Tests knowledge of the `toArray()` API evolution.

_Likely follow-up:_ "Why is `list.toArray()` risky?"

Three approaches, in order of preference:

```java
List<String> list = List.of("A", "B", "C");

// Best (Java 11+): constructor reference - type-safe, clean
String[] arr1 = list.toArray(String[]::new);

// Pre-Java 11 safe: zero-length hint
String[] arr2 = list.toArray(new String[0]);
// JVM optimizes: allocates String[] of correct size
// "new String[0]" is a type hint, not the result array

// Pre-Java 11 (old pattern, same performance):
String[] arr3 = list.toArray(new String[list.size()]);

// WRONG: returns Object[], cast compiles but may throw at runtime
String[] wrong = (String[]) list.toArray(); // ClassCastException!
```

Why `list.toArray()` is risky: returns `Object[]`, not `String[]`.
The cast compiles (unchecked) but throws `ClassCastException` when
the JVM verifies the array type at assignment.

_What separates good from great:_ Knowing `new String[0]` vs
`new String[list.size()]` - both work, `new String[0]` is slightly
preferred because the JVM can optimize allocation without the pre-allocated
array overhead.

---

**[SENIOR] Q3: DEBUGGING: A `List<Integer>` has only one element
when created from `int[]`. What went wrong?** [DEBUGGING]

_Why they ask:_ Tests the primitive array auto-boxing trap.

_Likely follow-up:_ "How do you fix it?"

```java
int[] arr = {1, 2, 3, 4, 5};
List<Integer> list = Arrays.asList(arr); // BUG: List<int[]> size=1!
```

Root cause: `Arrays.asList(T... a)` is generic on `T`. An `int[]` is
not an `Integer[]`. The compiler infers `T = int[]` and creates a
`List<int[]>` containing ONE element: the entire `int[]` array.

The list has `size() == 1`, and `list.get(0)` returns the `int[]` object.

Fix options:

```java
// Option 1: use Integer[] instead
Integer[] boxedArr = {1, 2, 3, 4, 5};
List<Integer> list = Arrays.asList(boxedArr); // correct: size=5

// Option 2: stream with boxing
List<Integer> list = Arrays.stream(arr)
    .boxed()
    .collect(Collectors.toList());

// Option 3: Java 16+
List<Integer> list = Arrays.stream(arr).boxed().toList();
```

_What separates good from great:_ Explaining the `T = int[]` type
inference as the root cause, not just "it doesn't work with primitives."
