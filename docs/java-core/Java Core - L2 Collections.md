---
layout: default
title: "Java Core - L2 Collections"
parent: "Java Core"
grand_parent: "SK Interview"
nav_order: 4
permalink: /java-core/l2-collections/
---

# Java Core - L2 Collections

## Collections Framework Design

### 🎯 Model Answer

**30 seconds:**
> The Java Collections Framework (JCF) is a unified hierarchy of
> interfaces and implementations for storing and manipulating groups
> of objects. Core interfaces: `Collection` (add/remove/iterate),
> `List` (ordered, indexed, allows duplicates), `Set` (no duplicates),
> `Map` (key-value pairs, not a Collection), `Queue`/`Deque`
> (ordered processing). Key implementations: `ArrayList` (fast random
> access), `LinkedList` (efficient insert/delete), `HashMap` (O(1) avg
> lookup), `TreeMap` (sorted), `HashSet`, `ArrayDeque`. The framework
> is backed by an interface-first design: always declare as `List` not
> `ArrayList` for flexibility.

**3 minutes (Senior):**
> The framework design (by Joshua Bloch) follows key principles:
> interface-first declarations, algorithm separation (Collections utility
> methods), fail-fast iterators (ConcurrentModificationException on
> structural changes), and consistent time complexity guarantees.
>
> `Iterable` and `Iterator` enable the enhanced for loop. `Comparable`
> and `Comparator` provide sorting. `Collections` utility class provides
> algorithms: `sort`, `binarySearch`, `shuffle`, `reverse`, `unmodifiable*`,
> `synchronized*`. Java 9 added factory methods: `List.of()`, `Set.of()`,
> `Map.of()` - immutable collections with null-rejection.
>
> Trade-offs: `ArrayList` vs `LinkedList` is the most common interview
> question - but in practice, `ArrayList` wins almost always due to
> cache locality. The only legitimate `LinkedList` use case is as a
> `Deque` (double-ended queue), not as a `List`.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Discuss the `Spliterator` interface (Java 8, parallel
streams), the `Sequenced Collections` interface hierarchy (Java 21:
`SequencedCollection`, `SequencedSet`, `SequencedMap`), and the
performance characteristics of `CopyOnWriteArrayList` for concurrent
read-heavy workloads.

*Adapting down:* "Collections are containers for groups of objects.
List is an ordered list (like a numbered grocery list). Set is a
no-duplicates bag. Map is a dictionary (word to definition). Queue is
a line at a cash register (first in, first out)."

**Blank Mind Recovery:**

**(1) Restate:** "Collections framework design - let me cover the
core interface hierarchy, key implementations with their time
complexities, and the principle of interface-first declarations."

**(2) First principles:** "From first principles: programs need
standard ways to group objects. Without a framework, every developer
would build their own list and map. The JCF provides standard,
tested, optimized implementations with a consistent interface."

**(3) Bridge:** "The collections framework is like a universal
toolkit with standardized tool types (interfaces): hammers (List),
bags (Set), and filing cabinets (Map). The specific brand (ArrayList,
HashSet) is an implementation detail - you work with the tool type."

---

### 📘 Concept Explanation

**Core interface hierarchy:**
```
Iterable
  |-- Collection
        |-- List (ordered, indexed, duplicates allowed)
        |     |-- ArrayList
        |     |-- LinkedList
        |     |-- Vector (legacy, synchronized)
        |     |-- CopyOnWriteArrayList (concurrent)
        |
        |-- Set (no duplicates)
        |     |-- HashSet (unordered, O(1) add/contains)
        |     |-- LinkedHashSet (insertion order)
        |     |-- TreeSet (natural or Comparator order)
        |
        |-- Queue (FIFO processing)
              |-- PriorityQueue (natural or Comparator order)
              |-- ArrayDeque (implements Deque: FIFO or LIFO)
              |-- LinkedList (also implements Deque)

Map (NOT a Collection)
  |-- HashMap (unordered, O(1) avg)
  |-- LinkedHashMap (insertion or access order)
  |-- TreeMap (sorted by key)
  |-- EnumMap (optimized for enum keys)
  |-- WeakHashMap (GC-friendly keys)
  |-- ConcurrentHashMap (concurrent, no locks on reads)
```

**Time complexity summary:**
| Operation | ArrayList | LinkedList | HashSet | TreeSet | HashMap | TreeMap |
|---|---|---|---|---|---|---|
| get(i) | O(1) | O(n) | N/A | N/A | O(1) avg | O(log n) |
| add(end) | O(1) amortized | O(1) | O(1) avg | O(log n) | O(1) avg | O(log n) |
| add(i) | O(n) | O(n) | N/A | N/A | N/A | N/A |
| remove(i) | O(n) | O(n) | O(1) avg | O(log n) | O(1) avg | O(log n) |
| contains | O(n) | O(n) | O(1) avg | O(log n) | O(1) avg | O(log n) |
| iterate | O(n) | O(n) | O(n) | O(n) | O(n) | O(n) |

---

### 💻 Code Example

> **Code walkthrough:** This example shows the interface-first declaration
> principle, immutable factory methods, and the `Collections` utility
> API. Declaring as `List` not `ArrayList` means you can swap
> implementations without changing all usages. `List.of()` creates
> an immutable list that throws on mutation - useful for return values,
> constants, and test data. `Collections.unmodifiableList()` wraps a
> mutable list but the wrapped list is still mutable through the original
> reference.

```java
// GOOD: interface-first declaration
List<String> names = new ArrayList<>();    // not ArrayList<> names
Set<Integer> ids = new HashSet<>();        // not HashSet<> ids
Map<String, User> users = new HashMap<>(); // not HashMap<>

// Java 9+ immutable factory methods:
List<String> tags = List.of("java", "spring", "sql"); // immutable
Set<String> roles = Set.of("ADMIN", "USER", "READ");  // immutable, unordered
Map<String, Integer> codes = Map.of(
    "OK", 200,
    "NOT_FOUND", 404,
    "ERROR", 500
); // immutable, max 10 entries; use Map.ofEntries() for more

// Differences from Collections.unmodifiableList():
List<String> mutable = new ArrayList<>(List.of("a","b"));
List<String> immutable = Collections.unmodifiableList(mutable);
mutable.add("c");          // ok
immutable.get(2);          // "c" - sees the change through wrapper!
immutable.add("d");        // UnsupportedOperationException

List<String> truly = List.of("a", "b"); // truly immutable copy
// List.of() vs unmodifiableList(): List.of() is truly immutable

// Collections utility algorithms:
List<Integer> nums = new ArrayList<>(List.of(3,1,4,1,5,9));
Collections.sort(nums);             // [1,1,3,4,5,9]
Collections.sort(nums, Comparator.reverseOrder()); // [9,5,4,3,1,1]
int idx = Collections.binarySearch(nums, 4); // works on sorted list
Collections.shuffle(nums);          // random order
Collections.reverse(nums);          // in-place reverse
int max = Collections.max(nums);    // 9
int min = Collections.min(nums);    // 1
Collections.frequency(nums, 1);     // 2 (count of 1s)
```

> **Code walkthrough:** The critical distinction: `Collections.unmodifiableList()`
> wraps the original list but does NOT copy it. Mutations through the
> original reference are visible through the wrapper. `List.of()` creates
> a truly immutable copy. For defensive copies in APIs: use
> `List.copyOf(existing)` (Java 10) which creates an immutable copy.
> Return `List.copyOf()` from methods that should not give callers
> a mutable view into internal state.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> The key collection interfaces: `List` (ordered, duplicates), `Set`
> (no duplicates), `Map` (key-value). Always declare as the interface
> type, not the implementation. Key implementations: `ArrayList` for
> most lists, `HashMap` for most maps, `HashSet` for sets. Use
> `List.of()`, `Set.of()`, `Map.of()` for immutable collections.
> `Collections.sort()` and `Collections.unmodifiableList()` are common
> utilities.

---

**Senior / Staff (5+ years):**
> Collection choice is a performance and semantics decision. `ArrayList`
> vs `LinkedList`: `ArrayList` wins on almost all benchmarks for modern
> hardware due to cache locality. `LinkedList` as a `List` is almost
> always wrong; as an `ArrayDeque` competitor for `Deque` operations,
> `ArrayDeque` still wins. `TreeMap`/`TreeSet` are for when you need
> sorted order (e.g., time-series range queries, ordered processing).
> `LinkedHashMap` gives insertion or access order (LRU cache skeleton).
> For concurrent code: `ConcurrentHashMap` (not `Collections.synchronized
> Map()`), `CopyOnWriteArrayList` for read-heavy lists.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Map is a type of Collection."**
`Map<K,V>` does NOT implement `Collection`. It's a separate hierarchy.
You cannot pass a `Map` where a `Collection` is expected. To iterate
a Map as a Collection: use `map.entrySet()` (Set of entries),
`map.keySet()` (Set of keys), or `map.values()` (Collection of values).

**Misconception 2: "`List.of()` and `Arrays.asList()` are the same."**
`Arrays.asList()` returns a fixed-size list backed by the array: you
can set elements but not add/remove. It allows null elements. `List.of()`
is truly immutable: no set/add/remove, and it rejects null elements.

---

### 🚨 Failure Modes and Diagnosis

**Failure: ConcurrentModificationException from structural modification.**
```java
List<String> names = new ArrayList<>(List.of("a","b","c"));
for (String name : names) {
    if (name.equals("b")) {
        names.remove(name); // ConcurrentModificationException!
    }
}
// Fix 1: Iterator.remove():
Iterator<String> it = names.iterator();
while (it.hasNext()) {
    if (it.next().equals("b")) it.remove(); // safe
}
// Fix 2: removeIf (Java 8+):
names.removeIf(name -> name.equals("b"));
```
Diagnosis: stack trace points to `checkForComodification()`.
Root cause: structural modification (add/remove/clear) during iteration.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Collection hierarchy | 90 seconds |
| Interface-first principle | 60 seconds |
| List.of() vs unmodifiable | 2 minutes |
| Collection selection | 2 minutes |
| ConcurrentModificationException | 2 minutes |
| Sorting and ordering | 2 minutes |
| Java 21 Sequenced Collections | 90 seconds |
| Fail-fast iterators | 2 minutes |
| Collections utility methods | 90 seconds |

---

**Q1 (Collection hierarchy): Walk through the Java Collections
Framework hierarchy.**

A: The JCF has two root hierarchies:

**`Iterable` / `Collection` tree:**
- `Iterable`: supports for-each loops (`iterator()`)
- `Collection`: adds `add()`, `remove()`, `contains()`, `size()`, `isEmpty()`
- `List`: adds `get(i)`, `set(i)`, `add(i)`, `indexOf()`
- `Set`: no duplicates; same methods as `Collection`
- `SortedSet` / `NavigableSet`: adds `first()`, `last()`, `headSet()`,
  `tailSet()`, `subSet()`
- `Queue`: adds `offer()`, `poll()`, `peek()` (FIFO semantics)
- `Deque`: extends `Queue` with `addFirst()`, `addLast()`,
  `pollFirst()`, `pollLast()` (both ends)

**`Map` tree (separate from `Collection`):**
- `Map`: `put()`, `get()`, `remove()`, `containsKey()`, `keySet()`,
  `values()`, `entrySet()`
- `SortedMap` / `NavigableMap`: sorted by key, range operations

**Java 21 additions (`SequencedCollection`):**
- `SequencedCollection` extends `Collection`: adds `getFirst()`,
  `getLast()`, `addFirst()`, `addLast()`, `reversed()`
- `SequencedSet` extends `SequencedCollection` and `Set`
- `SequencedMap` extends `Map`: adds `firstEntry()`, `lastEntry()`, `reversed()`

*What separates good from great:* The JCF design separated algorithms
from data structures (unlike C++ STL templates). `Collections.sort()`
works on any `List`; `Collections.binarySearch()` on any sorted `List`.
This was ahead of its time in 1998. The interface-first design means
you can substitute implementations (e.g., replace `ArrayList` with
`LinkedList` or `CopyOnWriteArrayList`) by changing one line. Modern
Java streams operate on any `Collection` via the `Spliterator` interface.

---

**Q2 (Interface-first principle): Why should you declare `List<String>
names` instead of `ArrayList<String> names`?**

A: Declaring the interface type:
1. **Flexibility:** you can change the implementation in one place
2. **Encapsulation:** code only uses the interface contract, not
   ArrayList-specific methods (`trimToSize()`, `ensureCapacity()`)
3. **Testability:** tests can pass mock implementations
4. **Communication:** the declaration says "I need a list"; not "I need
   an ArrayList"

```java
// GOOD: interface type in field, local variable, parameter, return
List<String> process(List<String> items) {
    List<String> result = new ArrayList<>();
    // switch to CopyOnWriteArrayList? Change ONE line above
    ...
    return result;
}

// BAD: concrete type everywhere
ArrayList<String> process(ArrayList<String> items) {
    ArrayList<String> result = new ArrayList<>();
    // now everything depends on ArrayList specifically
}
```

**Exceptions: concrete type is appropriate when:**
- You specifically need concrete-type methods not in the interface
  (`ArrayDeque.peekFirst()` vs `Deque.peekFirst()` - actually same here)
- You're explicitly documenting implementation choice for performance
  (`private final ConcurrentHashMap<>` to document thread-safety choice)

*What separates good from great:* API boundary declarations (method
parameters, return types) are the most important. Using `List` in a
public method signature means callers can pass any List. Using `ArrayList`
unnecessarily restricts callers and leaks implementation detail. However:
in a `private` method used only within the class, the concrete type
in a `local variable` is mostly a style choice - the JVM doesn't care.
Focus the interface-first discipline on public API boundaries.

---

**Q3 (List.of() vs unmodifiable): What's the difference between
List.of() and Collections.unmodifiableList()?**

A:

| Aspect | `List.of()` | `Collections.unmodifiableList()` |
|---|---|---|
| Truly immutable | YES | NO (original can mutate) |
| Null elements | Rejects (NPE) | Allows |
| Backed by original | NO (own storage) | YES (wrapper) |
| Iteration order | JVM-dependent (small) | Same as wrapped |
| Memory | Compact (JVM optimized) | Extra wrapper object |
| Thread-safe | YES | Reads yes; writes blocked |

```java
List<String> src = new ArrayList<>(Arrays.asList("a","b","c"));
List<String> unmod = Collections.unmodifiableList(src);
List<String> immut = List.of("a", "b", "c");

src.add("d");
unmod.get(3); // "d" - unmod sees the mutation!
// immut never changes

unmod.add("e"); // UnsupportedOperationException
immut.add("e"); // UnsupportedOperationException

unmod.contains(null); // false - null not in list
immut.contains(null); // NullPointerException - List.of() rejects null
```

**Practical choice:**
- `List.of()`: return values, constants, test data - truly immutable
- `Collections.unmodifiableList()`: when you need a read-only VIEW of
  a mutable list (rare; usually defensive copy is better)
- `List.copyOf(other)` (Java 10): immutable copy of another collection

*What separates good from great:* Returning a mutable collection from
a method is a common encapsulation violation. Callers can modify the
returned list and affect the object's internal state:
`order.getItems().clear()` could empty an order's items if `getItems()`
returns the internal list. Fix: return `List.copyOf(items)` or
`Collections.unmodifiableList(items)`. `List.copyOf` is safer
(truly immutable). The tradeoff: defensive copy has O(n) allocation;
unmodifiable wrapper has O(1) but the underlying list is still mutable.

---

**Q4 (Collection selection): How do you choose the right collection
implementation?**

A:

Decision tree:

**Need key-value pairs?** -> `Map` family
- Unordered, fast: `HashMap`
- Insertion order: `LinkedHashMap`
- Sorted by key: `TreeMap`
- Enum keys: `EnumMap`
- Concurrent: `ConcurrentHashMap`

**Need no duplicates?** -> `Set` family
- Unordered, fast: `HashSet`
- Insertion order: `LinkedHashSet`
- Sorted: `TreeSet`

**Need ordered sequence?** -> `List` or `Queue` family
- Random access: `ArrayList` (almost always)
- Queue/stack operations: `ArrayDeque` (never LinkedList)
- Concurrent reads: `CopyOnWriteArrayList`
- Priority-based: `PriorityQueue`

**The `LinkedList` myth:**
```java
// WRONG: using LinkedList as a List (almost always worse than ArrayList)
List<String> list = new LinkedList<>(); // worse cache locality

// RIGHT: use ArrayDeque for queue/stack:
Deque<String> queue = new ArrayDeque<>();
queue.addLast("a");   // enqueue
queue.pollFirst();    // dequeue

// RIGHT: use ArrayList for list:
List<String> list = new ArrayList<>();
```

*What separates good from great:* The performance case against LinkedList
is compelling. Modern CPUs have 64-byte cache lines. `ArrayList` stores
elements contiguously; iterating it is a sequential memory scan with
perfect prefetching. `LinkedList` nodes are scattered in heap memory;
iterating it follows pointers, causing cache misses. For a list of 1000
elements, iteration is 2-10x faster with `ArrayList` even though
`LinkedList` has O(1) insertions. The only competitive use case for
`LinkedList` is as a `Deque` - but `ArrayDeque` is still faster.

---

**Q5 (ConcurrentModificationException): Explain fail-fast iterators
and how to avoid CME.**

A: Fail-fast iterators track a `modCount` (modification count) on the
collection. When the iterator is created, it captures `modCount`.
On each `next()` call, it checks if `modCount` changed. If yes:
`ConcurrentModificationException`.

This detects structural modifications (add, remove, clear - anything
that changes the list size) made while iterating.

**Safe modification patterns:**
```java
List<String> items = new ArrayList<>(List.of("a","b","c","d"));

// Option 1: Iterator.remove() - safe
Iterator<String> it = items.iterator();
while (it.hasNext()) {
    if (it.next().startsWith("a")) it.remove(); // safe
}

// Option 2: removeIf (Java 8+) - cleanest
items.removeIf(s -> s.startsWith("a"));

// Option 3: stream filter + collect - creates new list
List<String> kept = items.stream()
    .filter(s -> !s.startsWith("a"))
    .collect(Collectors.toList());

// Option 4: indexed loop with decreasing index
for (int i = items.size() - 1; i >= 0; i--) {
    if (items.get(i).startsWith("a")) items.remove(i);
}
```

*What separates good from great:* CME is a best-effort detection
mechanism, not a hard guarantee. The Javadoc says: "It is not generally
permissible for one thread to modify a Collection while another thread
is iterating over it." Concurrent access requires thread-safe collections
(`CopyOnWriteArrayList` for read-heavy, `Collections.synchronizedList()`
with external synchronization, or `ConcurrentHashMap` for maps). CME
also occurs in single-threaded code if you modify while iterating -
the most common case.

---

**Q6 (Sorting and ordering): How do you sort a collection in Java?**

A:

```java
List<String> names = new ArrayList<>(List.of("Charlie","Alice","Bob"));

// Method 1: Collections.sort() - mutates list
Collections.sort(names);                         // [Alice, Bob, Charlie]
Collections.sort(names, Comparator.reverseOrder()); // [Charlie, Bob, Alice]

// Method 2: List.sort() - mutates list (Java 8+)
names.sort(Comparator.naturalOrder());
names.sort(Comparator.comparingInt(String::length)); // by length
names.sort(Comparator.comparingInt(String::length)
    .thenComparing(Comparator.naturalOrder())); // length, then alpha

// Method 3: Stream.sorted() - creates new sorted stream (no mutation)
List<String> sorted = names.stream()
    .sorted(Comparator.comparingInt(String::length))
    .collect(Collectors.toList());

// Sorting objects:
record Person(String name, int age) {}
List<Person> people = List.of(
    new Person("Alice", 30), new Person("Bob", 25)
);
List<Person> byAge = people.stream()
    .sorted(Comparator.comparingInt(Person::age))
    .toList(); // Java 16+

// Reverse a sorted:
List<Person> byAgeDesc = people.stream()
    .sorted(Comparator.comparingInt(Person::age).reversed())
    .toList();
```

*What separates good from great:* Java's sort algorithm is `TimSort`
(a hybrid merge sort / insertion sort), O(n log n) worst case with O(n)
for nearly-sorted data. It's stable: equal elements maintain their
original relative order. This matters when sorting by one field and
wanting secondary sort to be preserved from a previous sort. For parallel
sorting of large arrays: `Arrays.parallelSort()` uses fork/join for
O(n log n) with multiple cores.

---

**Q7 (Java 21 Sequenced Collections): What are Sequenced Collections
in Java 21?**

A: Java 21 (JEP 431) added three new interfaces to unify "has a defined
encounter order" semantics:

```java
// Before Java 21: inconsistent APIs
list.get(0);              // List - get first
deque.peekFirst();        // Deque - peek first
sortedSet.first();        // SortedSet - get first
// No common way to get "first" of any ordered collection!

// Java 21: SequencedCollection interface
interface SequencedCollection<E> extends Collection<E> {
    E getFirst();     // get first element
    E getLast();      // get last element
    void addFirst(E e);
    void addLast(E e);
    E removeFirst();
    E removeLast();
    SequencedCollection<E> reversed(); // reversed view
}
// ArrayList, LinkedList, ArrayDeque all implement this now
```

**Practical use:**
```java
List<String> list = new ArrayList<>(List.of("a","b","c"));
list.getFirst();  // "a" - new Java 21 method
list.getLast();   // "c" - new Java 21 method
list.reversed();  // reversed view ["c","b","a"]
list.addFirst("z"); // adds at front: ["z","a","b","c"]
```

*What separates good from great:* `SequencedCollection.reversed()`
returns a VIEW, not a copy. Mutating the original is reflected in the
reversed view and vice versa. For an immutable reversed copy:
`List.copyOf(list.reversed())`. The sequenced collection interfaces
unify what previously required different APIs for each collection type,
reducing the need to check documentation for "how do I get the last
element of this particular type?"

---

**Q8 (Fail-fast iterators): What is the difference between fail-fast
and fail-safe iterators?**

A:

| Property | Fail-Fast (ArrayList, HashMap) | Fail-Safe (CopyOnWrite, Concurrent) |
|---|---|---|
| How works | Throw CME if modified during iteration | Operate on snapshot or don't throw |
| Memory | No copy | Copy (CopyOnWrite) or segment lock |
| Sees updates | Yes (same underlying data) | No (snapshot) or eventually |
| Thread safety | No | Yes |
| Performance | Lower overhead | Higher overhead |

**Fail-safe examples:**
```java
// CopyOnWriteArrayList: iterates on snapshot taken at iterator creation
List<String> cowList = new CopyOnWriteArrayList<>(List.of("a","b"));
for (String s : cowList) {
    cowList.add("x"); // no CME! iterator sees original ["a","b"]
}
// After loop: cowList = ["a","b","x","x"]

// ConcurrentHashMap: iterates without copying, no CME, may see partial updates
Map<String, Integer> map = new ConcurrentHashMap<>();
for (Map.Entry<String, Integer> e : map.entrySet()) {
    map.put("new", 1); // no CME, but may or may not be seen in iteration
}
```

*What separates good from great:* `CopyOnWriteArrayList` is only
appropriate when writes are rare and reads are very frequent. Each write
creates a complete copy of the underlying array: O(n) write cost. For
an application with 100 readers and 1 writer: great. For 50% writes:
terrible performance. Real-world uses: event listener lists (many reads,
rare adds/removes), role/permission lists (loaded at startup, rarely changed).

---

**Q9 (Collections utility methods): What are the most useful methods
in the Collections utility class?**

A:
```java
List<Integer> nums = new ArrayList<>(List.of(3,1,4,1,5,9,2,6));

// Sorting:
Collections.sort(nums);              // natural order
Collections.sort(nums, Comparator.reverseOrder());

// Searching (requires sorted list):
Collections.sort(nums);
int pos = Collections.binarySearch(nums, 4); // >= 0 if found

// Reordering:
Collections.shuffle(nums);           // randomize
Collections.reverse(nums);           // reverse in place

// Stats:
Collections.max(nums);               // max element
Collections.min(nums);               // min element
Collections.frequency(nums, 1);      // count occurrences

// Defensive wrappers:
List<String> immutable = Collections.unmodifiableList(mutableList);
Map<String, String> syncMap = Collections.synchronizedMap(new HashMap<>());
Set<String> emptySet = Collections.emptySet(); // empty immutable
List<String> singletonList = Collections.singletonList("only"); // 1 element

// Fill and copy:
Collections.fill(nums, 0);           // set all to 0
List<Integer> dest = new ArrayList<>(Collections.nCopies(8, 0));
Collections.copy(dest, nums);        // copy nums into dest

// Disjoint check:
boolean noCommon = Collections.disjoint(list1, list2);
```

*What separates good from great:* `Collections.emptyList()`,
`Collections.emptySet()`, `Collections.emptyMap()` return singleton
empty collections (not new objects each time). For method return values
when there are no results, prefer these over `new ArrayList<>()`.
Similarly, `Collections.singletonList()` is more efficient than
`new ArrayList<>` with one element for read-only single-element lists.
These are micro-optimizations, but they signal idiomatic Java coding.

---

### ⚖️ Comparison Table

| Collection | Order | Duplicates | Null | Thread-Safe | Get O | Add O |
|---|---|---|---|---|---|---|
| ArrayList | Insertion | Yes | Yes | No | O(1) | O(1) amort |
| LinkedList | Insertion | Yes | Yes | No | O(n) | O(1) |
| ArrayDeque | Insertion | Yes | No | No | O(1) ends | O(1) amort |
| HashSet | None | No | One null | No | - | O(1) avg |
| LinkedHashSet | Insertion | No | One null | No | - | O(1) avg |
| TreeSet | Sorted | No | No | No | - | O(log n) |
| HashMap | None | Keys no | One null key | No | O(1) avg | O(1) avg |
| LinkedHashMap | Insert/access | Keys no | One null key | No | O(1) avg | O(1) avg |
| TreeMap | Key sorted | Keys no | No null key | No | O(log n) | O(log n) |
| ConcurrentHashMap | None | Keys no | No | Yes | O(1) avg | O(1) avg |
| CopyOnWriteArrayList | Insertion | Yes | Yes | Yes | O(1) | O(n) |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: collection hierarchy described adequately in code comments)*

---

---

## ArrayList vs LinkedList

### 🎯 Model Answer

**30 seconds:**
> `ArrayList` is backed by a dynamic array: O(1) random access, O(1)
> amortized append, O(n) insert/delete in the middle. `LinkedList` is
> a doubly-linked list: O(n) random access (traverses from head),
> O(1) insert/delete IF you have the node reference (which `ListIterator`
> gives you). In practice, `ArrayList` wins on nearly all benchmarks
> because modern CPUs prefetch sequential memory extremely efficiently,
> while LinkedList's pointer-chasing causes cache misses. Use `ArrayList`
> for lists; use `ArrayDeque` for queue/stack operations, not `LinkedList`.

**3 minutes (Senior):**
> The memory layout is the key. `ArrayList` stores references
> contiguously in memory. When iterating, the CPU prefetcher sees
> sequential memory access and loads cache lines proactively. For
> 1000 elements, iteration accesses 1000 sequential memory locations.
> `LinkedList` nodes are allocated on the heap at random locations.
> Iterating follows pointers to random locations, causing cache misses
> at each step. Cache miss penalty: ~100 cycles. CPU prefetch hit: ~4 cycles.
> For a 1000-element list, LinkedList iteration has potentially 1000 cache
> misses vs near-zero for ArrayList.
>
> When `ArrayList.add(i, element)` in the middle is O(n): it shifts
> all elements after index i. But this is a `System.arraycopy()` call -
> a native operation that copies memory in bulk at hardware speed.
> `LinkedList.add(i, element)` first traverses to index i (O(n)), then
> inserts (O(1)). The traversal has cache misses; the arraycopy is fast.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "ArrayList vs LinkedList - let me cover their internal
structures, time complexities, and why ArrayList wins in practice
due to cache locality."

**(2) First principles:** "From first principles: arrays are contiguous
memory - the CPU can prefetch. Linked lists are scattered - pointer
chasing means cache misses. Modern CPU caches reward sequential access
enormously."

**(3) Bridge:** "ArrayList is like books on a straight shelf - easy to
grab any book by position, and fast to scan sequentially. LinkedList is
like books connected by strings scattered around a library - you follow
strings from one to the next, never knowing where the next book is until
you find the string."

---

### 📘 Concept Explanation

**ArrayList internal structure:**
```
int[] elementData = [ref0, ref1, ref2, ref3, null, null, null, null]
                     ^^^^^^^^^^^^^^^^^^^^        ^^^^^^^^^^^^^^^
                     size = 4 (used)             capacity = 8 (allocated)

add(): if size < capacity, elementData[size++] = element  -> O(1)
       if size == capacity, grow: copy to new array of capacity*1.5 -> O(n) once
       amortized over n appends: O(1) total

get(i): return elementData[i]  -> O(1) - single array access

add(i, e): System.arraycopy(elementData, i, elementData, i+1, size-i)
           elementData[i] = element  -> O(n) shifts
```

**LinkedList internal structure:**
```
Node {
    E item;
    Node<E> prev;
    Node<E> next;
}
head -> [a] <-> [b] <-> [c] <-> [d] <- tail

get(i): if i < size/2, start from head; else from tail -> O(n)
add(last): tail.next = new Node -> O(1)
addFirst(): head.prev = new Node -> O(1)
add(i, e): traverse to node i -> O(n), then insert -> O(1)
           traversal cost (cache misses) usually dominates
```

---

### 💻 Code Example

> **Code walkthrough:** The benchmark shows the memory-access pattern
> difference. ArrayList iteration accesses a contiguous memory block;
> LinkedList iteration follows pointers. The `System.arraycopy` for
> ArrayList mid-insertion is a native bulk memory operation, typically
> faster than LinkedList's node traversal despite theoretically being
> the same O(n). The pre-sizing tip avoids the O(n) growth copies.

```java
// ArrayList: pre-size to avoid reallocations:
List<String> results = new ArrayList<>(expectedSize);
// Without pre-sizing: default capacity 10, grows by 1.5x each time
// With pre-sizing: no growth copies at all

// LinkedList: its one legitimate use - Deque operations:
Deque<String> stack = new ArrayDeque<>(); // prefer this
stack.push("first");
stack.push("second");
String top = stack.pop(); // "second" (LIFO)

Deque<String> queue = new ArrayDeque<>(); // prefer this
queue.offer("first");     // enqueue
queue.offer("second");
String head = queue.poll(); // "first" (FIFO)

// When to actually use LinkedList:
// Almost never. These operations LOOK faster for LinkedList but aren't:

// "Middle insert" benchmark reality:
// 1000 elements, insert at position 500:
// ArrayList: System.arraycopy(500 elements) - contiguous, fast
// LinkedList: traverse 500 nodes (cache misses) + insert
// Result: ArrayList is often FASTER even for middle inserts!

// The only case where LinkedList wins:
// Repeated insert at the SAME iterator position using ListIterator:
ListIterator<String> it = linkedList.listIterator(position);
for (int i = 0; i < 1000; i++) {
    it.add(newElement); // O(1) insert at current position
    // ArrayList equivalent: O(n) shift each time -> O(n^2) total
}
```

> **Code walkthrough:** The ListIterator insert scenario is the ONLY
> realistic case where LinkedList wins. If you have an iterator positioned
> at the middle of the list and perform 1000 consecutive inserts at that
> position, LinkedList does 1000 O(1) insertions (total O(n)), while
> ArrayList does 1000 O(n) shifts (total O(n^2)). In every other
> scenario - iteration, random access, appending, searching - ArrayList
> wins decisively on modern hardware.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> ArrayList uses a dynamic array (O(1) get), LinkedList uses a doubly-
> linked list (O(n) get). ArrayList is faster for most operations because
> of memory locality. Use ArrayList for almost everything. Use ArrayDeque
> for queue/stack operations (not LinkedList). LinkedList has high memory
> overhead: each node has two extra references (prev/next) plus object header.

---

**Senior / Staff (5+ years):**
> The ArrayList vs LinkedList question is settled: use ArrayList. The
> only exception is the `ListIterator` insert scenario (bulk inserts at
> a maintained iterator position). LinkedList's memory overhead (3x per
> element: data + prev + next references) and cache miss penalty make
> it consistently slower than ArrayList in practice. For large-scale
> data processing: always profile before choosing LinkedList based on
> theoretical complexity. `System.arraycopy` is hardware-optimized and
> faster than theoretical O(n) suggests for typical list sizes.

---

### ⚠️ Common Misconceptions

**Misconception 1: "LinkedList is better for frequent insertions."**
Only true if you're inserting at a maintained iterator position.
For `list.add(i, element)`: LinkedList must traverse to index i (O(n)
with cache misses) before the O(1) insert. ArrayList shifts elements
with `System.arraycopy` - a single native memory copy. For typical
list sizes (< 10,000 elements), ArrayList add-at-index is faster
than LinkedList due to hardware-accelerated memory copy.

**Misconception 2: "LinkedList uses less memory because it doesn't
pre-allocate."**
The opposite is true. `ArrayList` with 100 elements and capacity 128
uses: 128 references (1024 bytes) + 100 object headers. `LinkedList`
with 100 elements uses: 100 nodes * (object header + item ref + prev
ref + next ref) = 100 * (16 + 8 + 8 + 8) = 4000 bytes of node overhead,
not counting the actual objects.

---

### 🚨 Failure Modes and Diagnosis

**Failure: ArrayList with wrong initial capacity causes GC pressure.**
```java
// BAD: default capacity 10, needs 100,000 elements
List<String> results = new ArrayList<>();
for (String item : hugeResultSet) { results.add(item); }
// Resizes 15+ times, each resize allocates new array + copies

// GOOD: pre-size if count is known:
List<String> results = new ArrayList<>(hugeResultSet.size());
// or use streams/collect which optimize internally
```
Diagnosis: heap profiler shows many ArrayList.grow() calls, or
`ArrayList$` objects in heap dump.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| ArrayList vs LinkedList | 2-3 minutes |
| Cache locality impact | 2 minutes |
| ArrayList resizing | 2 minutes |
| ListIterator advantage | 2 minutes |
| When to use LinkedList | 90 seconds |
| Memory comparison | 2 minutes |
| ArrayDeque as Deque | 90 seconds |
| Performance benchmark | 2-3 minutes |
| Pre-sizing benefit | 90 seconds |

---

**Q1 (ArrayList vs LinkedList): Compare ArrayList and LinkedList in
terms of time complexity and practical performance.**

A:

| Operation | ArrayList | LinkedList | Practical Winner |
|---|---|---|---|
| `get(i)` | O(1) | O(n) | ArrayList |
| `add(last)` | O(1) amort | O(1) | ArrayList (cache) |
| `add(i)` | O(n) | O(n) | ArrayList (arraycopy) |
| `remove(i)` | O(n) | O(n) | ArrayList (arraycopy) |
| `addFirst()` | O(n) | O(1) | LinkedList |
| Iteration | O(n) | O(n) | ArrayList (cache) |
| Memory | Low | High (3x per element) | ArrayList |

The asymptotic complexity alone misleads. `System.arraycopy` achieves
memory bandwidth of ~20 GB/s (modern hardware). A 1000-element array
copy is ~8KB - fits in L1 cache (typically 32KB). LinkedList traversal
of 1000 nodes causes ~1000 cache misses at ~100ns each = ~100 microseconds.
`System.arraycopy` of 1000 elements = ~100 nanoseconds. **ArrayList wins
on the operation the theory says LinkedList should win.**

*What separates good from great:* The only valid LinkedList win is
`addFirst()`/`removeFirst()` when you truly need a FIFO queue or LIFO stack.
But even then, `ArrayDeque` (amortized O(1) for both ends, better cache)
beats `LinkedList`. The Java team has effectively deprecated `LinkedList`
for all practical purposes - it exists for historical compatibility,
not because it's better for any common use case.

---

**Q2 (Cache locality impact): Explain why cache locality matters for
collection performance.**

A: Modern CPU cache hierarchy:
```
L1 cache: ~32KB, ~4 cycles access
L2 cache: ~256KB, ~12 cycles access
L3 cache: ~8-32MB, ~40 cycles access
DRAM: unlimited, ~200-300 cycles access
```

A CPU cache line is 64 bytes. When you access an element, the CPU
loads the surrounding 64 bytes. For `ArrayList` with 8-byte references:
one cache miss loads 8 adjacent references. The next 7 accesses are
free (L1 cache hit).

For `LinkedList` nodes (~40 bytes each, scattered in heap):
each node access likely triggers a cache miss (node is at an arbitrary
heap address, not adjacent to the previous node).

**Measured impact:**
```java
// Typical microbenchmark result (JMH, 100K elements):
// ArrayList iterate: ~1.2 ms
// LinkedList iterate: ~6.8 ms  (5.6x slower!)
// Despite both being O(n)!
```

Pre-fetching: the hardware prefetcher sees sequential memory addresses
and proactively loads the next cache lines. `ArrayList` triggers
aggressive prefetching. `LinkedList` access patterns are random;
prefetcher cannot predict them.

*What separates good from great:* Cache locality is the defining
performance difference between data structures in modern systems.
B-trees vs binary search trees: both O(log n) but B-trees store
multiple keys per node, minimizing cache misses per tree level.
`HashMap`'s open-addressing competitors (e.g., `HashMap` with linear
probing) vs chaining: open-addressing has better cache locality for
the probe sequence. Understanding cache effects allows you to explain
why theoretically equivalent algorithms have large real-world performance
differences.

---

**Q3 (ArrayList resizing): How does ArrayList grow and what is the
amortized cost of appending?**

A: ArrayList starts with a default capacity of 10 (if no initial capacity
given). When capacity is exceeded, it grows to `(capacity * 3 / 2 + 1)`
(approximately 1.5x growth since Java 8).

```
n=1:   capacity 10
n=11:  grow to 15, copy 10 elements
n=16:  grow to 22, copy 15 elements
n=23:  grow to 33, copy 22 elements
...
```

**Amortized O(1) analysis:**
For n appends, the total copy work is: 10 + 15 + 22 + 33 + ... < 3n.
Total work O(n), amortized per operation O(1).

```java
// Check current capacity (hack - no public API):
// ArrayList stores size; capacity requires reflection:
ArrayList<String> list = new ArrayList<>(4);
list.add("a"); list.add("b"); list.add("c"); list.add("d");
// capacity = 4, size = 4
list.add("e"); // triggers growth: capacity becomes 6
// 4 elements copied to new array

// Pre-size to avoid growth copies:
int expectedSize = dbQuery.getResultSize();
List<String> results = new ArrayList<>(expectedSize);
// capacity = expectedSize, no copies needed
```

*What separates good from great:* The 1.5x growth factor is a balance
between memory waste (too large a factor wastes memory) and copy
frequency (too small causes more copies). Compare: Java uses 1.5x,
C++ `vector` uses 2x, Python list uses ~1.125x (more memory-efficient).
The trade-off: 2x factor means each element is copied at most once on
average (amortized O(1) is tighter). 1.5x means slightly more copies
but less wasted capacity. For `ArrayList<byte[]>` holding large arrays,
preallocating capacity is more important than the growth factor.

---

**Q4 (ListIterator advantage): When does LinkedList actually
outperform ArrayList?**

A: LinkedList's ONLY practical win: bulk insertions at a maintained
`ListIterator` position.

```java
// Scenario: insert 1000 elements at position 500 of a 1000-element list:

// GOOD for LinkedList: use ListIterator
LinkedList<String> linked = new LinkedList<>(existingList);
ListIterator<String> it = linked.listIterator(500);
for (String item : newItems) {
    it.add(item); // O(1) each - total O(n)
}

// BAD for ArrayList: each insert shifts elements
ArrayList<String> array = new ArrayList<>(existingList);
int pos = 500;
for (String item : newItems) {
    array.add(pos++, item); // O(n) each - total O(n^2)!
}
```

This scenario requires: (1) you need to insert at a fixed position in
the middle, (2) you need to insert many elements, (3) you maintain
the iterator across inserts. Very specific requirements rarely met
in practice.

**Alternative for the ArrayList O(n^2) problem:**
```java
// Merge two sorted regions without O(n^2):
List<String> combined = new ArrayList<>(list1.size() + newItems.size());
combined.addAll(list1.subList(0, 500));
combined.addAll(newItems);           // one arraycopy - O(m)
combined.addAll(list1.subList(500, list1.size()));
// Total: O(n+m) instead of O(n*m)
```

*What separates good from great:* The `ListIterator` LinkedList advantage
is real but rare enough that most production code should still default
to `ArrayList`. The key insight: if you find yourself writing code that
inserts many elements at the same position in a list, the correct solution
is usually not LinkedList but a different data structure or algorithm:
batch the inserts and rebuild, use a `Deque`, or rethink the data model.

---

**Q5 (When to use LinkedList): Give a real-world scenario where
LinkedList is the right choice.**

A: The only defensible real-world scenario:

**Implementing an LRU cache with O(1) eviction:**
```java
// LRU cache: remove the least-recently-used element when full
// LinkedHashMap already does this, but conceptually:

class LRUCache<K, V> {
    private final int capacity;
    private final Map<K, LinkedList.Node<K>> nodeMap = new HashMap<>();
    private final LinkedList<K> accessOrder = new LinkedList<>();

    // When accessing key:
    //   1. Find node via nodeMap.get(key) -> O(1)
    //   2. Move node to front of LinkedList -> O(1) with node reference
    //   3. Return value

    // When evicting:
    //   1. Remove last node of LinkedList -> O(1)
    //   2. Remove from nodeMap -> O(1)
}
```

But Java's `LinkedHashMap(capacity, loadFactor, true)` (access-order mode)
already implements this without exposing `LinkedList`.

**More honest answer:** in modern Java, `LinkedList` has no use case
that's better served by it over `ArrayDeque` (for Deque) or `ArrayList`
(for List). The standard library provides better alternatives for all
its theoretical strengths.

*What separates good from great:* When an interviewer asks "when would
you use LinkedList?" - the most impressive answer is: "Rarely in modern
Java. ArrayDeque beats it for Deque operations, ArrayList for List
operations. The only valid case is maintaining a ListIterator for bulk
mid-list inserts, which is uncommon. LinkedHashMap handles the LRU cache
use case. I'd choose LinkedList only after profiling shows it's faster
for my specific access pattern."

---

**Q6 (Memory comparison): Compare the memory usage of ArrayList and
LinkedList for 100 objects.**

A:

**ArrayList (100 String references, capacity 128):**
```
ArrayList object: 16 bytes (header) + 8 (elementData ref) + 4 (size) + 4 (modCount)
elementData array: 16 (header) + 128 * 8 (refs) = 1040 bytes
Total ArrayList overhead: ~1060 bytes
Plus: 100 String objects (actual data)
```

**LinkedList (100 String references):**
```
LinkedList object: 16 (header) + 4 (size) + 8 (first ref) + 8 (last ref) = 36 bytes
Per Node: 16 (header) + 8 (item ref) + 8 (prev ref) + 8 (next ref) = 40 bytes
100 nodes: 4000 bytes
Total LinkedList overhead: ~4036 bytes
Plus: 100 String objects (actual data)
```

ArrayList overhead: ~1060 bytes (10.6 bytes/element)
LinkedList overhead: ~4036 bytes (40.4 bytes/element)
**LinkedList uses ~4x more memory for the collection overhead.**

*What separates good from great:* Memory usage matters at scale. A cache
holding 1M string entries: ArrayList overhead ~10MB; LinkedList overhead
~40MB. For JVM with limited heap (containers): 30MB difference matters.
The GC pressure also differs: LinkedList creates 1M separate node objects
(1M GC-tracked references), while ArrayList is 1 array object. GC scanning
1M node objects is more work than scanning 1 array.

---

**Q7 (ArrayDeque as Deque): Why is ArrayDeque preferred over LinkedList
for queue/stack operations?**

A: `ArrayDeque` implements `Deque` (double-ended queue) using a circular
resizable array. Both `addFirst()`/`addLast()` are O(1) amortized.

```java
// Stack (LIFO):
Deque<String> stack = new ArrayDeque<>();
stack.push("a");    // addFirst
stack.push("b");
stack.pop();        // removeFirst -> "b"

// Queue (FIFO):
Deque<String> queue = new ArrayDeque<>();
queue.offer("a");   // addLast
queue.offer("b");
queue.poll();       // removeFirst -> "a"

// ArrayDeque advantages over LinkedList:
// 1. No node object overhead (~4x less memory)
// 2. Better cache locality (circular array vs pointer chain)
// 3. No null elements allowed (faster null checks elided)
// 4. Slightly faster in all microbenchmarks
```

`ArrayDeque` resizes by doubling (similar to ArrayList). The circular
array wraps around: head and tail pointers move independently.

*What separates good from great:* The `Stack` class in Java is legacy
(extends `Vector`, which is synchronized). Never use `Stack`. Use
`ArrayDeque` for stack operations. For single-threaded FIFO queues:
`ArrayDeque`. For producer-consumer: `LinkedBlockingQueue` (bounded)
or `ArrayBlockingQueue` (array-backed, bounded). For priority: `PriorityQueue`.
The `Deque` interface (not `Queue`) on `ArrayDeque` is the most versatile
choice - it can serve as either a queue or a stack.

---

**Q8 (Performance benchmark): Walk through a microbenchmark comparing
ArrayList and LinkedList.**

A:
```java
// Hypothetical JMH benchmark results (1000-element list, 1M iterations):

// Sequential iteration:
// ArrayList: 85 µs/op
// LinkedList: 520 µs/op (6x slower: cache miss per node)

// Random access (get(random)):
// ArrayList: 1 µs/op
// LinkedList: 250 µs/op (250x slower: O(n) traversal)

// Append (add to end):
// ArrayList: 30 µs/op
// LinkedList: 45 µs/op (allocation per node + GC pressure)

// Insert at middle (add(500, element)):
// ArrayList: 15 µs/op (arraycopy 500 elements, hardware-accelerated)
// LinkedList: 260 µs/op (traverse 500 nodes, cache misses)
// Yes: ArrayList wins even for middle insert!

// ListIterator bulk insert (1000 inserts at position 500):
// ArrayList: 15,000 µs/op  (O(n^2): 1000 * 1000 element shifts)
// LinkedList: 1,000 µs/op  (O(n): 1000 * O(1) inserts)
// LinkedList wins only here!
```

*What separates good from great:* Running your own microbenchmark with
JMH (Java Microbenchmark Harness) is the correct approach for data-driven
decisions. JMH handles JVM warmup (JIT compilation), prevents dead code
elimination, and controls for GC effects. Microbenchmarks without JMH
are unreliable for JVM code. When presenting performance data in interviews
or design reviews: always mention the benchmarking methodology and
expected variance.

---

**Q9 (Pre-sizing benefit): How much does pre-sizing ArrayList improve
performance?**

A:
```java
// Without pre-sizing: 100K elements
List<String> noPresizing = new ArrayList<>();
for (int i = 0; i < 100_000; i++) {
    noPresizing.add("item" + i);
}
// Growth events: 10 -> 15 -> 22 -> 33 -> ... -> ~100K
// Approximately 15-20 growth events
// Total elements copied across all growths: ~3 * 100K = ~300K copies

// With pre-sizing:
List<String> presized = new ArrayList<>(100_000);
for (int i = 0; i < 100_000; i++) {
    presized.add("item" + i);
}
// Zero growth events, zero copies during population

// Performance difference: typically 20-30% faster population for large lists
// Memory: no excess capacity (exact fit vs 1.5x overshoot)

// When you don't know the size:
// Overestimate and then trim:
List<String> result = new ArrayList<>(estimatedSize);
// ... populate ...
result.trimToSize(); // shrink to fit (rarely needed)
```

*What separates good from great:* Pre-sizing is most important when:
(1) the final size is known or estimable, (2) the list is large (>10,000
elements), (3) the list is populated in a tight loop. For small lists or
asynchronous population, pre-sizing has negligible impact. A common
pattern in Spring/Hibernate: result set sizes are known from
`COUNT(*)` queries before fetching. Use the count for pre-sizing.
`stream().collect(Collectors.toList())` does not pre-size internally
(uses a default ArrayList), so for large results from streams,
`Collectors.toCollection(() -> new ArrayList<>(estimatedSize))` is
preferable.

---

### ⚖️ Comparison Table

| Aspect | ArrayList | LinkedList | ArrayDeque |
|---|---|---|---|
| Backed by | Dynamic array | Doubly-linked list | Circular array |
| get(i) | O(1) | O(n) | O(1) ends only |
| add(end) | O(1) amort | O(1) | O(1) amort |
| add(front) | O(n) | O(1) | O(1) amort |
| add(middle) | O(n) | O(n)* | N/A |
| remove(i) | O(n) | O(n)* | N/A |
| Iteration | Fast (cache) | Slow (misses) | Fast (cache) |
| Memory | Low (1 array) | High (3x/node) | Low (1 array) |
| Null elements | Yes | Yes | No |
| Interface | List, Deque | List, Deque | Deque |
| Recommended use | Lists | Rare (ListIterator) | Queue/Stack |

*Traversal to position is O(n) with cache misses; insert/remove itself O(1)

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: array vs linked structure described adequately in prose)*
