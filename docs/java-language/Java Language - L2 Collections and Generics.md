---
layout: default
title: "Java Language - L2 Collections and Generics"
parent: "Java Language"
grand_parent: "SK Interview"
nav_order: 4
permalink: /java-language/l2-collections-and-generics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Language - L2 Collections and Generics](#java-language---l2-collections-and-generics) | medium |

---

# Java Language - L2 Collections and Generics

## Collections Framework: List, Set, Map

---

### 🎯 Model Answer

**30 seconds:**
> Java Collections: List (ordered, duplicates allowed), Set (unique elements, no duplicates),
> Map (key-value pairs, unique keys). Main implementations: ArrayList (list, dynamic array),
> LinkedList (list, doubly-linked), HashSet (set, hash-based O(1)), TreeSet (set, sorted O(log n)),
> HashMap (map, hash-based O(1)), TreeMap (map, sorted O(log n)), LinkedHashMap (map, insertion
> order). Thread-safe alternatives: ConcurrentHashMap, CopyOnWriteArrayList.

**3 minutes (Senior):**
> Choosing the right collection:
>
> | Need | Use |
> |---|---|
> | Ordered list, random access by index | ArrayList |
> | Fast insert/remove from middle | LinkedList (but rare - deque ops) |
> | Unique elements, order irrelevant | HashSet |
> | Unique elements, sorted | TreeSet |
> | Fast lookup by key | HashMap |
> | Key-value, sorted by key | TreeMap |
> | Key-value, insertion order | LinkedHashMap |
> | Thread-safe reads, rare writes | CopyOnWriteArrayList |
> | Thread-safe concurrent map | ConcurrentHashMap |
>
> HashMap internals: array of buckets. Each bucket: linked list (Java 7) or
> tree (Java 8+, when bucket > 8 entries). Load factor 0.75: resize when 75% full
> (doubles capacity, rehashes all entries). Initial capacity 16. O(1) average,
> O(n) worst case (hash collision attack - mitigated in Java 8+ with treeification).

**Blank Mind Recovery:**

**(1) Restate:** "List = ordered, duplicates OK (ArrayList). Set = unique (HashSet, TreeSet).
Map = key-value (HashMap, TreeMap, LinkedHashMap). Thread-safe: ConcurrentHashMap, CopyOnWriteArrayList. Choose by: access pattern, ordering need, thread safety."

**(2) First principles:** "A collection is a container for objects. The key question: how
is it organized? By position (List), by identity/uniqueness (Set), by key (Map). Secondary:
ordered or not, sorted or insertion-ordered, thread-safe or not. Each combination = a
different implementation."

**(3) Bridge:** "Collections are like filing systems. ArrayList: binder with page numbers.
HashSet: pile of unique sticky notes. HashMap: filing cabinet with labels. TreeMap:
alphabetically sorted cabinet. ConcurrentHashMap: secure file room where multiple people
can file simultaneously."

---

### 📘 Concept Explanation

**Collection interface hierarchy and implementation trade-offs:**
```
JAVA COLLECTIONS HIERARCHY:

  Iterable
    Collection
      List
        ArrayList    <- resizable array, O(1) random access, O(n) insert mid
        LinkedList   <- doubly-linked, O(1) insert/remove by iterator, O(n) access
        ArrayDeque   <- better than LinkedList for Deque; O(1) both ends
      Set
        HashSet      <- hash table, O(1) add/contains/remove, no order
        LinkedHashSet <- hash table + doubly-linked, insertion order, O(1) ops
        TreeSet      <- red-black tree, O(log n), sorted (Comparable/Comparator)
        EnumSet      <- bit vector, fastest Set for enum values
      Queue / Deque
        ArrayDeque   <- preferred Queue/Stack implementation
        PriorityQueue <- min-heap, O(log n) offer/poll, O(1) peek
    Map (NOT extends Collection)
      HashMap        <- hash table, O(1) avg, no order
      LinkedHashMap  <- hash table + linked list, insertion or access order
      TreeMap        <- red-black tree, O(log n), sorted by key
      EnumMap        <- array-backed, fastest Map for enum keys
      WeakHashMap    <- weak keys (GC'd when no other refs)
    ConcurrentMap
      ConcurrentHashMap <- segment locks (Java 8: node-level), high concurrency

PERFORMANCE COMPARISON:
  Operation       ArrayList  LinkedList  HashSet  TreeSet  HashMap  TreeMap
  add (end)       O(1) amort  O(1)       O(1)     O(log n) O(1)     O(log n)
  add (index i)   O(n)        O(1)*      -        -        -        -
  get(i)          O(1)        O(n)       -        -        O(1)     O(log n)
  contains        O(n)        O(n)       O(1)     O(log n) O(1)     O(log n)
  remove (mid)    O(n)        O(1)*      O(1)     O(log n) O(1)     O(log n)
  * O(1) remove requires iterator or reference to node

CAPACITY AND RESIZING (ArrayList):
  Initial: 10 elements
  Growth: 1.5x on each resize (newCapacity = oldCapacity + (oldCapacity >> 1))
  If you know the size: ArrayList(expectedSize) avoids resizing

HASHMAP LOAD FACTOR AND CAPACITY:
  Default initial capacity: 16 buckets
  Default load factor: 0.75 (resize when 75% full)
  When resized: capacity doubles, all entries rehashed
  To avoid resizing: new HashMap<>(expectedSize / 0.75 + 1)
  Java 8+: bucket > 8 entries -> converts to balanced tree (O(log n) worst case)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The map operation patterns show idiomatic Java 8+ API usage.
> The pre-Java 8 boilerplate for map operations is error-prone; the modern API
> eliminates the null-check dance while being thread-safe for ConcurrentHashMap.

```java
// COLLECTION PATTERNS: modern idiomatic Java

// Map operations (Java 8+):
Map<String, List<Order>> ordersByUser = new HashMap<>();

// BAD: pre-Java 8 (null check + put dance)
List<Order> orders = ordersByUser.get(userId);
if (orders == null) {
    orders = new ArrayList<>();
    ordersByUser.put(userId, orders);
}
orders.add(newOrder);

// GOOD: computeIfAbsent (atomic in ConcurrentHashMap)
ordersByUser.computeIfAbsent(userId, k -> new ArrayList<>()).add(newOrder);

// Count occurrences:
// BAD:
Integer count = wordCount.get(word);
wordCount.put(word, count == null ? 1 : count + 1);

// GOOD: merge
wordCount.merge(word, 1, Integer::sum);

// GOOD: getOrDefault
int count = wordCount.getOrDefault(word, 0) + 1;
wordCount.put(word, count);

// Map.computeIfPresent: update only if key exists
map.computeIfPresent(key, (k, v) -> transform(v));

// CHOOSING THE RIGHT COLLECTION:

// Need to preserve insertion order in a Map -> LinkedHashMap
Map<String, Config> config = new LinkedHashMap<>();  // iteration = insertion order

// Need sorted keys -> TreeMap
NavigableMap<Instant, Event> timeline = new TreeMap<>();
timeline.headMap(cutoff).clear();  // remove events before cutoff (sorted range)

// Need fastest Set for enums -> EnumSet
Set<DayOfWeek> weekdays = EnumSet.of(DayOfWeek.MONDAY, DayOfWeek.TUESDAY,
    DayOfWeek.WEDNESDAY, DayOfWeek.THURSDAY, DayOfWeek.FRIDAY);

// Need LRU cache -> LinkedHashMap with access order
Map<Key, Value> lruCache = new LinkedHashMap<>(16, 0.75f, true /* access order */) {
    @Override
    protected boolean removeEldestEntry(Map.Entry<Key, Value> eldest) {
        return size() > MAX_SIZE;  // remove oldest-accessed when full
    }
};

// Thread-safe map:
// BAD: Collections.synchronizedMap (locks entire map per operation)
Map<K, V> synced = Collections.synchronizedMap(new HashMap<>());

// GOOD: ConcurrentHashMap (segment/node locking, high concurrency)
Map<K, V> concurrent = new ConcurrentHashMap<>();
concurrent.computeIfAbsent(key, k -> expensiveCompute(k));
// computeIfAbsent in CHM: atomic - only computes once even under concurrency
```

> **Code walkthrough:** The `computeIfAbsent` pattern replaces three lines of null-check
> boilerplate with one expressive line, and it's atomic in `ConcurrentHashMap` (no race
> condition between the check and the put). The `merge` method handles the count-
> occurrences pattern without an initial null check. `LinkedHashMap` with access order
> is the standard LRU cache implementation in Java's standard library - used by many
> caching frameworks as the underlying data structure.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Choose ArrayList for ordered collections, HashSet for unique elements, HashMap for
> key-value. For sorted: TreeSet/TreeMap. Modern map API: `computeIfAbsent`, `merge`,
> `getOrDefault` instead of manual null checks. Thread-safe: ConcurrentHashMap.

---

**Senior / Staff (5+ years):**
> Collection selection is a performance and semantic decision. HashMap load factor and
> initial capacity: tune for large maps to avoid resizing. EnumMap and EnumSet for enum
> keys/values (fastest, no hashing overhead). ConcurrentHashMap vs synchronized wrappers:
> CHM always (fine-grained locking). LinkedHashMap for LRU caches. PriorityQueue for
> scheduled tasks, top-K problems. ArrayDeque for stack/queue (faster than Stack/LinkedList).

---

### ⚠️ Common Misconceptions

**Misconception 1: "LinkedList is faster for insertion than ArrayList."**
LinkedList insert at a known position (by iterator): O(1). But finding that position:
O(n) (traversal). For most use cases (add to end, random access): ArrayList is faster
due to cache locality (contiguous memory, CPU prefetching). LinkedList: only outperforms
ArrayList when inserting/removing from BOTH ends frequently (use ArrayDeque instead).
Benchmark rule: ArrayList is the default; use LinkedList only if a specific benchmark
shows it's faster for your access pattern.

**Misconception 2: "HashMap guarantees O(1) operations."**
HashMap is O(1) AVERAGE. Worst case: O(n) if all keys have the same hashCode (all in
one bucket, traversal). Java 8+: bucket > 8 elements -> converts to red-black tree
(O(log n) worst case). Pathological case: adversarial hash collisions. Fix: Java uses
randomized hash seeds (hashCode of strings is computed differently per JVM startup).
For custom hashCode: aim for good distribution, avoid returning constants.

---

### 🚨 Failure Modes and Diagnosis

**Failure: HashMap has unexpected behavior after key mutation.**
```
Symptom: map.containsKey(key) returns false for a key that was put in the map.
  key is a mutable object; its hashCode changed after insertion.

Root cause:
  public class MutableKey {
      private int value;
      MutableKey(int v) { this.value = v; }
      
      @Override
      public int hashCode() { return value; }
      @Override
      public boolean equals(Object o) {
          return o instanceof MutableKey mk && mk.value == value;
      }
      
      // BAD: setter allows mutation after use as map key
      public void setValue(int v) { this.value = v; }
  }
  
  MutableKey key = new MutableKey(1);
  map.put(key, "original");     // stored in bucket 1
  key.setValue(2);              // hashCode changes to 2
  map.containsKey(key);         // looks in bucket 2 -> not found!
  // The value is still in bucket 1, but unreachable via key

Prevention: NEVER use mutable objects as HashMap keys.
  Use: immutable keys (String, Integer, records, final classes)
  
  If you must use a mutable key:
    - Ensure the fields used in hashCode/equals are never changed
      after insertion (make them final)
    - Or: use IdentityHashMap (uses == for equality, System.identityHashCode)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| HashMap internals | 2 minutes |
| ArrayList vs LinkedList | 2 minutes |
| Choosing collection type | 2 minutes |
| ConcurrentHashMap vs synchronized | 2 minutes |
| computeIfAbsent pattern | 1 minute |
| TreeMap vs HashMap | 1 minute |
| Mutable keys in HashMap | 2 minutes |
| EnumMap/EnumSet | 1 minute |
| Fail-fast vs fail-safe iteration | 1 minute |

---

**Q1 (hashmap internals): How does HashMap work internally?**

A: HashMap: array of buckets (default 16). Key -> `hashCode()` -> bucket index (hash & (capacity-1)).
Within bucket: linked list (Java 7) or tree (Java 8+ when bucket > 8 entries). `get(key)`:
compute hash, find bucket, traverse bucket list/tree using `equals()`. `put(key, value)`:
find bucket, check for existing key, append or update. Load factor: resize (rehash all
entries) when entries / capacity > loadFactor (0.75 default). Resize: doubles capacity.

*What separates good from great:* The Java 8 treeification: when a single bucket exceeds
8 entries (high collision), the linked list converts to a red-black tree. This prevents
DoS via hash collision attacks (malicious input could force all keys to the same bucket -
O(n) per lookup). With treeification: O(log n) even in adversarial cases. The untreeify
threshold: 6 entries (hysteresis to prevent thrashing). The capacity is always a power
of 2: allows `hash & (capacity - 1)` as a fast modulo (bit mask). The HashMap contract:
non-null keys must have consistent hashCode (same key = same hashCode, always). Violating
this corrupts the map permanently.

---

**Q2 (list comparison): When do you use ArrayList vs ArrayDeque vs LinkedList?**

A: ArrayList: default list. O(1) random access, O(1) add to end, O(n) insert to middle.
ArrayDeque: when you need queue or stack behavior (add/remove from both ends). Faster than
LinkedList for queue/stack operations (array-based, better cache locality). LinkedList:
rarely needed; only outperforms when: you have an iterator position and need O(1) insert/
remove at that position (not by index). For most queue/deque operations: use ArrayDeque.
`Stack` (legacy): do not use, replaced by ArrayDeque.

*What separates good from great:* The common mistake: using `LinkedList` as a Queue
implementation because "Queue is a linked list". Modern Java: `ArrayDeque` is faster
than `LinkedList` for all Queue/Stack operations. Why: ArrayDeque is an array (contiguous
memory), LinkedList creates Node objects (heap allocation, pointer indirection, GC
pressure). A benchmark with millions of enqueue/dequeue operations: ArrayDeque is
2-5x faster than LinkedList. The Javadoc for ArrayDeque says: "This class is likely
to be faster than Stack when used as a stack, and faster than LinkedList when used
as a queue." Always use ArrayDeque.

---

**Q3 (thread safety): What are the options for thread-safe collections?**

A: (1) `ConcurrentHashMap` (best): node-level locking, high concurrency for all map operations.
(2) `CopyOnWriteArrayList` / `CopyOnWriteArraySet`: reads are lock-free, writes create a new copy.
Best for: very rare writes, frequent reads, when iterators must not see concurrent modifications.
(3) `Collections.synchronizedXxx()`: wraps any collection with a coarse lock. Problem:
compound operations (`get` then `put`) are NOT atomic - still need external synchronization.
(4) `Collections.synchronizedList` for iteration requires external sync block.

*What separates good from great:* The ConcurrentHashMap compound operation problem:
`if (!map.containsKey(k)) map.put(k, v)` - NOT atomic even with CHM. Between `containsKey`
(releases lock) and `put` (acquires lock): another thread may insert the same key. Solution:
`map.putIfAbsent(k, v)` (atomic). Or: `computeIfAbsent(k, creator)` (atomic, creates
value only if absent, value creator called at most once per key). This is the most common
CHM misuse: thinking individual method calls are thread-safe (they are), but compound
operations are not (they need the atomic compute methods).

---

**Q4 (sorting collections): How do you sort a List and what are Comparable vs Comparator?**

A: `Collections.sort(list)` or `list.sort(null)`: requires elements to implement `Comparable`
(natural ordering). `list.sort(comparator)`: uses provided `Comparator`. `Comparable.compareTo()`:
the natural ordering (e.g., String alphabetical, Integer numeric). `Comparator.comparing(keyExtractor)`:
modern, functional comparator. `Comparator.comparing(Employee::getSalary).reversed()`:
descending. Chaining: `.thenComparing(Employee::getName)` for secondary sort.

*What separates good from great:* `Comparator.comparingInt(e -> e.getAge())` vs `Comparator.comparing(Employee::getAge)`. The `comparingInt` variant avoids boxing (takes an `int` directly,
avoids `Integer` creation). For performance-critical sorting of many objects: use primitive
comparators (`comparingInt`, `comparingLong`, `comparingDouble`). The `compare()` contract:
must be consistent with `equals` for `TreeSet`/`TreeMap` keys (if `compareTo` returns 0,
`equals` should return true for the collection to work correctly). Violating this: elements
get "lost" in sorted collections even though they're present.

---

**Q5 (navigation): What does NavigableMap/NavigableSet provide over SortedMap?**

A: `NavigableMap` (TreeMap, ConcurrentSkipListMap) extends `SortedMap` with range navigation:
`headMap(k)` - keys less than k; `tailMap(k)` - keys >= k; `subMap(from, to)` - range.
`floorKey(k)` - largest key <= k; `ceilingKey(k)` - smallest key >= k; `lowerKey(k)` -
strictly less; `higherKey(k)` - strictly greater. `descendingMap()` - reverse order view.
Use case: time-series data (find events before/after a timestamp), price range queries
(find products in a price range).

*What separates good from great:* The `headMap(toKey, inclusive)` exclusive/inclusive
parameter (Java 6 NavigableMap): `treeMap.headMap(toKey, true)` includes the toKey;
`headMap(toKey)` (old SortedMap API) is exclusive. The INCLUSIVE variant is the new
correct API. The exclusive old API is a source of off-by-one bugs. Pattern: `treeMap.subMap(from, fromInclusive, to, toInclusive)`. This is the standard API for range queries.
In practice: the inclusive/exclusive parameters are easy to get wrong. Test explicitly
with boundary values.

---

**Q6 (iteration): What is the difference between fail-fast and fail-safe iteration?**

A: Fail-fast: throws `ConcurrentModificationException` if the collection is modified during
iteration (checks `modCount`). Standard Java collections: ArrayList, HashMap, HashSet are
fail-fast. Fail-safe: iterates over a snapshot or uses a concurrent structure that doesn't
throw on modification. Examples: `CopyOnWriteArrayList` (iterates the snapshot at the time
`iterator()` was called), `ConcurrentHashMap` (weakly consistent - may or may not see
concurrent modifications). Use case: when you need to modify a collection while iterating
(use concurrent collection or `removeIf`).

*What separates good from great:* "Weakly consistent" for ConcurrentHashMap iterator:
the iterator may or may not see insertions made after the iterator was created. It will
NOT see deletions that happened before the current position. It WILL see deletions that
happen after the current position. This makes CHM iteration best-effort for concurrent
scenarios. For an exact snapshot: `new HashMap<>(concurrentHashMap)` (creates a copy,
but blocks briefly during copy). For count-based consistency: read the map, then read
the size - both may differ by the time you use them. Design concurrent code to NOT require
exact consistency: use CHM for individual get/put/compute operations, not for "read the
whole map atomically."

---

**Q7 (copy vs view): What is the difference between a collection copy and a view?**

A: Copy: an independent collection that contains all elements at the time of copy.
Modifications to the copy don't affect the original and vice versa. Examples:
`new ArrayList<>(list)`, `List.copyOf(list)`. View: a collection that delegates operations
to the original. Modifications to the view affect the original. Examples:
`Collections.unmodifiableList(list)` (read-only view, original is still mutable),
`Arrays.asList(array)` (backed by array, `set()` affects array), `list.subList(0, 3)`.

*What separates good from great:* `subList` and structural modification: `List.subList(from, to)` returns a view. Structural modification to the ORIGINAL list (add/remove) after
creating a subList: makes the subList invalid (`ConcurrentModificationException` on any
operation). The subList keeps a reference to the original and tracks modCount. Safe pattern:
either don't structurally modify the original after creating a subList, or convert the
subList to a copy: `new ArrayList<>(list.subList(from, to))`. Use case for subList:
`list.subList(0, list.size() - 5).clear()` - removes the first (size-5) elements from
the list in place (efficient).

---

**Q8 (queue priority): How does PriorityQueue work and what are its use cases?**

A: PriorityQueue: min-heap (natural ordering or Comparator). `offer(e)`: O(log n) insert.
`poll()`: O(log n) remove min element. `peek()`: O(1) view min. NOT FIFO - always returns
the minimum element (by natural ordering or Comparator). Use cases: top-K elements
(maintain a size-K PriorityQueue, poll when larger than K), Dijkstra's shortest path
(priority = distance), scheduled task execution (priority = execution time).

*What separates good from great:* PriorityQueue for top-K: keep a size-K max-heap (using
`Comparator.reverseOrder()` for a max-heap). For each new element: if it's smaller than
the max, replace the max (pop max, insert new). After processing all elements: the
priority queue contains the K smallest. This is O(n log K) vs O(n log n) for sorting all
elements. For n=1M and K=100: sorting = 20M comparisons; top-K heap = 1M * log(100) = 7M
comparisons. 3x faster. The production use case: top-100 products by sales, most recent
100 events, K slowest API endpoints.

---

**Q9 (map operations): What are the atomic operations in ConcurrentHashMap?**

A: Atomic single operations: `get`, `put`, `remove`, `putIfAbsent`, `replace`, `remove(key, expectedValue)`.
Atomic compound operations: `computeIfAbsent` (compute only if key absent, atomic),
`computeIfPresent` (compute only if key present, atomic), `compute` (compute always, atomic),
`merge` (merge with existing value, atomic). These methods hold the lock for the duration
of the computation. Non-atomic: `get` followed by `put` (two separate lock acquisitions).

*What separates good from great:* The `computeIfAbsent` locking behavior: during the
computation (the lambda), the map entry is locked. If the lambda is slow (I/O, network):
other threads waiting for the same key are blocked. If the lambda throws: the key is NOT
added to the map (exception propagates). If the lambda returns null: the key is NOT added
(null values not supported in CHM). The anti-pattern: `computeIfAbsent` with a lambda that
does expensive I/O - blocks all concurrent operations on the same key. Fix: compute the
value outside the lambda, then use `putIfAbsent`. Or: use a cache library (Caffeine) which
handles this correctly with asynchronous loading.

---

### ⚖️ Comparison Table

| Feature | ArrayList | LinkedList | ArrayDeque | HashSet | TreeSet | HashMap | TreeMap | ConcurrentHashMap |
|---------|-----------|------------|------------|---------|---------|---------|---------|-------------------|
| Ordered | Yes (index)| Yes (index) | Yes (ends) | No | Sorted | No | Sorted | No |
| Duplicates | Yes | Yes | Yes | No | No | Keys: No | Keys: No | Keys: No |
| Random access | O(1) | O(n) | N/A | N/A | N/A | O(1) | O(log n) | O(1) |
| Insert end | O(1) amort | O(1) | O(1) | O(1) | O(log n) | O(1) | O(log n) | O(1) |
| Insert mid | O(n) | O(1)* | N/A | N/A | N/A | N/A | N/A | N/A |
| contains | O(n) | O(n) | O(n) | O(1) | O(log n) | O(1) | O(log n) | O(1) |
| Thread-safe | No | No | No | No | No | No | No | Yes |
| Null values | Yes | Yes | No | One null | No | Yes | Yes | No |
| Memory | Low | High (pointers) | Medium | Medium | High | Medium | High | High |

---

### 🏛️ System Design

*(Omit: L2 Working file - system design is reserved for ★★★ level files.)*

---

### 📊 Diagram

*(Omit: The collection hierarchy is expressed in the structured text and performance table
in the Concept Explanation section. The comparison table above provides the visual
comparison reference.)*

---

---

## Generics and Type Erasure

---

### 🎯 Model Answer

**30 seconds:**
> Generics (Java 5): type-safe collections and methods without casting. `List<String>`:
> only accepts Strings, returns Strings - no ClassCastException. Implemented via type
> erasure: generic type information removed at compile time; the JVM sees raw types.
> Key syntax: `<T>` type parameter, `<T extends Comparable<T>>` bounded, `<? extends T>`
> wildcard (producer/read), `<? super T>` wildcard (consumer/write). PECS: Producer Extends,
> Consumer Super.

**3 minutes (Senior):**
> Generic mechanics:
>
> 1. **Type erasure**: `List<String>` and `List<Integer>` are the same type at runtime
>    (`List`). The compiler inserts casts at call sites. A `List<String>` at runtime
>    is just a `List` - the string constraint exists only in the compiled bytecode.
>
> 2. **Wildcard PECS rule**: `? extends T` (upper-bounded): you can READ T from it
>    (it produces T), but cannot WRITE to it. `? super T` (lower-bounded): you can
>    WRITE T into it, but cannot READ T from it (you get `Object`).
>    `Collections.copy(destination, source)`:
>    `void copy(List<? super T> dest, List<? extends T> src)` - dest is consumer,
>    src is producer.
>
> 3. **Bounded type parameters**: `<T extends Comparable<T>>`: T must implement
>    Comparable. Multiple bounds: `<T extends Comparable<T> & Serializable>`. Class
>    bound must come before interface bounds.
>
> 4. **Raw types**: `List list = new ArrayList()` - no generic type. Pre-Java 5
>    code. Generates unchecked warnings. Should not appear in modern code.
>
> 5. **Generic methods vs generic classes**: a generic method can be called with any type
>    that satisfies the bound, independently of the enclosing class's generic parameters.

**Blank Mind Recovery:**

**(1) Restate:** "Generics: type-safe at compile time, type erased at runtime. T = type
parameter. `? extends T` = read-only (producer). `? super T` = write-only (consumer).
PECS: Producer Extends, Consumer Super. Type erasure: `List<String>` is `List` at runtime."

**(2) First principles:** "Before generics: collections held `Object`, you cast manually.
Generics: the compiler tracks the type for you, inserts casts automatically, and catches
errors at compile time. The JVM doesn't need to know - type erasure lets existing JVM
bytecode run generic code unchanged."

**(3) Bridge:** "Generics are like typed envelopes. A `List<String>` is an envelope marked
'only String letters'. The compiler enforces the marking at writing (compile time). By
delivery time (runtime): the marking is gone (erased), but the letters inside are still
strings (cast inserted by compiler). If you forge the envelope (raw type casting): you
might deliver non-String letters -> ClassCastException at read time."

---

### 📘 Concept Explanation

**Generic mechanics and wildcard rules:**
```
GENERIC TYPE PARAMETER SYNTAX:

  Generic class:
    class Box<T> {           // T is the type parameter
        private T value;
        Box(T value) { this.value = value; }
        T get() { return value; }
    }
  
  Generic method (independent of class type parameter):
    <T extends Comparable<T>> T max(T a, T b) {
        return a.compareTo(b) >= 0 ? a : b;
    }

WILDCARD RULES (PECS):
  
  Upper-bounded wildcard (? extends T): PRODUCER
    void printAll(List<? extends Number> list) {
        for (Number n : list) print(n);  // READ: OK (n is at least Number)
        list.add(42);    // WRITE: COMPILE ERROR (could be List<Integer>, List<Double>)
                         // Adding Integer to List<Double>: type violation
    }
    printAll(new ArrayList<Integer>());   // OK: Integer extends Number
    printAll(new ArrayList<Double>());    // OK: Double extends Number
    
  Lower-bounded wildcard (? super T): CONSUMER
    void addNumbers(List<? super Integer> list) {
        list.add(1);     // WRITE: OK (list accepts at least Integer)
        list.add(2);
        Integer i = list.get(0); // READ: COMPILE ERROR (could be Object)
        Object o = list.get(0);  // READ: OK (Object is the upper bound)
    }
    addNumbers(new ArrayList<Integer>());  // OK
    addNumbers(new ArrayList<Number>());   // OK (Number super Integer)
    addNumbers(new ArrayList<Object>());   // OK (Object super Integer)

TYPE ERASURE EFFECTS:
  // At runtime, List<String> and List<Integer> are the same:
  List<String> strings = new ArrayList<>();
  List<Integer> ints = new ArrayList<>();
  strings.getClass() == ints.getClass();  // true: both are ArrayList
  
  // Cannot create generic arrays:
  // T[] array = new T[10];  // compile error: cannot create generic array
  // Workaround: unchecked cast:
  @SuppressWarnings("unchecked")
  T[] array = (T[]) new Object[10];
  
  // Cannot use instanceof with generics:
  // if (list instanceof List<String>) // compile error
  if (list instanceof List<?>) ...     // OK (wildcard is type-safe)
  
  // Cannot overload with different generic types (same erasure):
  void process(List<String> list) {}
  void process(List<Integer> list) {}  // compile error: same erasure List
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The generic utility method demonstrates type inference and the
> practical difference between extends and super wildcards. The Stack example shows how
> to properly design a generic class with correct type constraints.

```java
// GENERICS IN PRACTICE

// WRONG vs RIGHT: wildcards
// BAD: wildcard prevents writing to producer list
void processBad(List<? extends Number> list) {
    list.add(1);  // compile error: cannot add to ? extends
}

// GOOD: extends for reading, super for writing
static <T> void copy(List<? super T> dst, List<? extends T> src) {
    for (T item : src) {  // reads T from src (producer extends)
        dst.add(item);    // writes T to dst (consumer super)
    }
}
// Call: copy(List<Object> dst, List<String> src) -> works!
// T=String, dst=List<Object> (Object super String), src=List<String>

// GENERIC METHOD: type inference
static <T extends Comparable<T>> Optional<T> findMin(List<T> list) {
    return list.stream()
        .min(Comparator.naturalOrder());
}

Optional<String> minWord = findMin(List.of("banana", "apple", "cherry"));
// minWord = Optional[apple]
// Type T inferred as String by compiler

// BOUNDED TYPE PARAMETER: constrain what T can be
class SortedList<T extends Comparable<T>> {
    private final List<T> items = new ArrayList<>();
    
    void add(T item) {
        items.add(item);
        Collections.sort(items);  // requires T to be Comparable
    }
    
    T get(int index) { return items.get(index); }
}
SortedList<Integer> sorted = new SortedList<>();
sorted.add(3); sorted.add(1); sorted.add(2);
// sorted.get(0) = 1 (smallest)

// TYPE TOKEN PATTERN: preserve generic type at runtime
// (workaround for type erasure)
class TypedCache<T> {
    private final Class<T> type;
    private final Map<String, Object> cache = new HashMap<>();
    
    TypedCache(Class<T> type) { this.type = type; }
    
    void put(String key, T value) { cache.put(key, value); }
    
    T get(String key) {
        return type.cast(cache.get(key));  // safe cast via type token
    }
}
TypedCache<String> stringCache = new TypedCache<>(String.class);
stringCache.put("key", "value");
String v = stringCache.get("key");  // no unchecked cast at call site
```

> **Code walkthrough:** The `copy(List<? super T> dst, List<? extends T> src)` pattern
> is the canonical PECS example. The type constraint says: "dst accepts at least T (super),
> src provides at least T (extends)." This allows copying from `List<String>` to
> `List<Object>` even though `List<String>` is not a `List<Object>`. The Type Token
> pattern (`Class<T>` parameter) preserves type information that would otherwise be erased,
> enabling type-safe casting at runtime without unchecked warnings at the call site.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Generics: type-safe collections. `<T>` = generic type. `List<String>`: only strings.
> Type erasure: generic type info removed at runtime. Wildcards: `? extends T` for reading,
> `? super T` for writing. PECS mnemonic: Producer Extends, Consumer Super.

---

**Senior / Staff (5+ years):**
> Generics design: avoid raw types in any new code (compile with `-Xlint:unchecked`).
> PECS rule reduces brittleness: APIs using `? extends T` and `? super T` are more flexible
> than fixed types. Type tokens (Class<T>) for runtime type checks. Generic bounds communicate
> constraints to callers explicitly. The type erasure limitation: if you need runtime generic
> type info (e.g., JSON deserialization into `List<User>`), use `TypeReference` patterns
> (Jackson, Gson) that capture generic type via anonymous subclass.

---

### ⚠️ Common Misconceptions

**Misconception 1: "`List<String>` is a subtype of `List<Object>`."**
FALSE. Generics are invariant (not covariant). `String` is a subtype of `Object`, but
`List<String>` is NOT a subtype of `List<Object>`. If it were: `List<Object> objs = new ArrayList<String>(); objs.add(42);` would corrupt the String list. Use `List<? extends Object>` (or `List<?>`) for "any list". This invariance is why PECS wildcards are needed.

**Misconception 2: "You can overload methods by generic type parameter."**
Type erasure makes `void process(List<String>)` and `void process(List<Integer>)` have the
same signature after erasure: `void process(List)`. The compiler rejects this as a duplicate
method declaration. Workaround: use different method names, or use a single method with
`instanceof` check inside (accepting `List<?>` or `List<Object>`).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Unchecked cast warning leading to ClassCastException at unexpected location.**
```
Symptom: ClassCastException at line N, but line N is just:
  String s = list.get(0);
  The get() return type is String - why ClassCastException?

Root cause:
  // Heap pollution: raw type assignment bypasses generics
  List<String> stringList = new ArrayList<>();
  List rawList = stringList;          // raw type: unchecked warning
  rawList.add(42);                    // no error: raw type, no check
  // Now stringList has an Integer in it - heap pollution
  
  String s = stringList.get(0);       // ClassCastException: Integer -> String
  // The cast is inserted by the compiler at the get() call site, not at add()

Diagnosis:
  Stack trace: ClassCastException at stringList.get(0)
  Look for: raw type assignments or unchecked casts in the code
  Warning: "unchecked" compiler warning in raw type usage
  
  Enable: -Xlint:unchecked in javac to see all warnings
  Enable: @SuppressWarnings("unchecked") searches to find suppressions

Fix:
  Never use raw types in new code.
  Never suppress "unchecked" without a documented comment explaining why it's safe.
  
  // If you must use raw types (legacy interop): validate at the boundary
  Object raw = legacyApi.get(key);    // raw API returns Object
  if (!(raw instanceof String s)) {
      throw new IllegalStateException("Expected String, got: " + raw.getClass());
  }
  // 's' is now a validated String

Prevention: compile with -Xlint:unchecked.
  CI: treat all unchecked warnings as build failures (requires code review for any suppression).
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Type erasure explanation | 2 minutes |
| PECS rule | 2 minutes |
| Wildcard vs type parameter | 2 minutes |
| Generic method vs generic class | 1 minute |
| Heap pollution | 2 minutes |
| Type token pattern | 2 minutes |
| Bounded type constraints | 1 minute |
| Raw types | 1 minute |
| Generic array creation | 1 minute |

---

**Q1 (type erasure): Why does Java use type erasure and what are its consequences?**

A: Type erasure: backward compatibility. Java 5 added generics; the JVM bytecode didn't change.
Generic type information exists only in the source code and class file metadata (for the
compiler). At runtime: `List<String>` is just `List`. Consequences: (1) cannot do
`instanceof List<String>` (only `instanceof List<?>` is valid), (2) cannot create `new T[]`
or `new T()`, (3) cannot overload by generic type parameter (same erasure), (4) generic
type info is lost at runtime (heap pollution from raw type abuse).

*What separates good from great:* The `getGenericSuperclass()` trick: generic type info
IS available at runtime for class definitions (not variable declarations). `new TypeReference<List<String>>() {}` (Jackson pattern): the anonymous subclass's supertype is
`TypeReference<List<String>>`, and `getGenericSuperclass()` returns the parameterized type.
The reflection API can read it. This is how Jackson deserializes `List<User>` correctly
even with type erasure - it uses the class definition's generic type, not the variable's.
This is a non-obvious but important pattern for any library that needs to work with
generic types at runtime.

---

**Q2 (pecs): Explain the PECS rule with a concrete example.**

A: PECS: Producer Extends, Consumer Super. Producer: you read FROM it -> use `? extends T`.
Consumer: you write TO it -> use `? super T`. Classic example: `Collections.copy`:
```java
public static <T> void copy(List<? super T> dest, List<? extends T> src) {
    for (int i = 0; i < src.size(); i++) {
        dest.set(i, src.get(i));
    }
}
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

`src` produces T (you read from it) -> `? extends T`. `dest` consumes T (you write to it) -> `? super T`. This allows: `copy(new ArrayList<Number>(), new ArrayList<Integer>())`. T=Integer, dest accepts Integer or supertypes (Number works), src provides Integer or subtypes.

*What separates good from great:* When to use unbounded `?` vs `<T>`: unbounded `List<?>`
when you don't care about the element type at all (just check size, clear, etc.). Type
parameter `<T>` when you need to refer to the type consistently (e.g., "return type is T",
or "this method takes a T and returns a T"). The rule: if you write `T` only once in the
signature, it can probably be `?`. If you write it twice (parameter + return, or two parameters
that must match): use `<T>`. Example: `<T> List<T> filter(List<T> list, Predicate<? super T> pred)` -
T appears twice (input and output must match), so `<T>` is correct.

---

**Q3 (wildcard capture): What is wildcard capture and when does it occur?**

A: Wildcard capture: when a generic method captures the wildcard type as a concrete type
parameter internally. Example: `void swap(List<?> list, int i, int j)` - to swap two
elements, you need to capture the type. Pattern: delegate to a private generic method:
```java
public void swap(List<?> list, int i, int j) {
    swapHelper(list, i, j);  // delegates
}
private <T> void swapHelper(List<T> list, int i, int j) {
    T temp = list.get(i);
    list.set(i, list.get(j));
    list.set(j, temp);  // T is the captured wildcard type
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* This pattern is used in the JDK's `Collections.swap()`
implementation. The public API uses a wildcard (flexible for callers), the implementation
uses a type parameter (needed for type-safe internal operations). The wildcard capture
through a private generic helper is the idiomatic solution for this mismatch. It's also
used in `Collections.sort()` which delegates to an internal method with a concrete type
parameter for the comparator. The pattern: public API surface is maximally flexible
(wildcards), implementation is maximally type-safe (type parameters).

---

**Q4 (recursive bounds): What is a recursive type bound and where is it used?**

A: Recursive type bound: a type parameter that is bounded by a generic type that uses
itself. `<T extends Comparable<T>>`: T must implement `Comparable<T>` - T can be compared
to other T instances. Used for: sorting algorithms (need T to be self-comparable),
binary search (need elements to be ordered), `TreeSet<T>` (T must be Comparable).

*What separates good from great:* The more general form: `<T extends Comparable<? super T>>`.
This allows T to be compared to supertypes of T. Example: `Integer implements Comparable<Integer>`. A `TreeSet<Integer>` works. A class `Foo extends Bar implements Comparable<Bar>`:
`<T extends Comparable<T>>` rejects Foo (Foo doesn't implement `Comparable<Foo>`), but
`<T extends Comparable<? super T>>` accepts Foo (Foo implements `Comparable<Bar>` and
Bar super Foo). The JDK uses `<T extends Comparable<? super T>>` in sort and min/max
methods for maximum flexibility.

---

**Q5 (type safety): How do you ensure type safety when calling legacy generic APIs?**

A: Strategy: (1) Create a typed wrapper that validates the raw type at the boundary.
(2) Use `Class.cast()` instead of raw cast - validates the type and throws CCE with a
clear message if wrong. (3) Use `Collections.checkedList(list, String.class)`: a
dynamically typed wrapper that throws ClassCastException if a wrong type is inserted
(instead of waiting until get). (4) Annotate any `@SuppressWarnings("unchecked")` with
a comment explaining why the cast is safe.

*What separates good from great:* `Collections.checkedList` is underused. It wraps a
`List<T>` with runtime type checking: any `add()` that inserts a wrong type throws
`ClassCastException` immediately. Without it: the corruption happens at `add()` time but
the ClassCastException only appears at `get()` time (possibly in completely different code).
Checked collections: make heap pollution detectable at the source. Use when: interfacing
with legacy raw-type code and you need to enforce type correctness. The cost: a
`instanceof` check on every add - small overhead.

---

**Q6 (generic inheritance): How do you properly subclass a generic class?**

A: Options: (1) concrete subtype - fix the type parameter: `class StringList extends ArrayList<String>`. (2) Pass-through - maintain the type parameter: `class MyList<T> extends ArrayList<T>`. (3) Bounded: `class NumberList<T extends Number> extends ArrayList<T>`. Raw
type subclass: `class BadList extends ArrayList` - loses all type safety. The override
rule: overriding a generic method with a covariant return type is allowed.

*What separates good from great:* The bridge method: when you override a generic method
with a concrete type, the compiler generates a bridge method to maintain runtime polymorphism.
Example: `Comparable<String>` with `compareTo(String s)`. The JVM needs `compareTo(Object o)` (the erased bridge) to support calling `compareTo` at the `Comparable` type. The bridge:
calls `(String)o` then your `compareTo(String s)`. This is why `compareTo(Object)` exists in
bytecode even though you only wrote `compareTo(String)`. The bridge method is a compiler artifact
for backward compatibility and polymorphism. Visible via `javap -verbose MyClass.class`.

---

**Q7 (generic with reflection): How do you get generic type information at runtime?**

A: Direct: generic type info of variables is erased. Available: generic type info in
class definitions, field declarations, and method signatures via reflection:
`field.getGenericType()`, `method.getGenericReturnType()`, `class.getGenericSuperclass()`.
For complex cases: Jackson's `TypeReference<T>`: create an anonymous subclass, then
use `getGenericSuperclass()` to get the parameterized type. Guava's `TypeToken<T>`:
similar, more complete.

*What separates good from great:* The Guava TypeToken is the production tool for runtime
generic type manipulation. `TypeToken.of(List.class).resolveType(List.class.getTypeParameters()[0])`.
Real use case: a generic serialization framework that needs to know at runtime "what type
are the elements in this List?" Answer: traverse the generic type hierarchy using TypeToken.
This is what Jackson, GSON, and similar frameworks do internally. For application code:
rarely needed. For library code: TypeToken is the standard solution.

---

**Q8 (generic method design): When should you use a generic return type vs a wildcard?**

A: Use a generic return type when the return type relates to the input type. `<T> T identity(T t)`:
T determines both input and output. Use `?` wildcard when the return type is "some unknown type" that
callers just need to store as Object or pass on: `List<?> getItems()`. Rule: if the caller
needs to do anything with the returned type (call methods on it, pass it to other typed
methods): use `<T>`. If the caller just stores it opaquely: use `?`.

*What separates good from great:* The "returning generics from methods" design: `<T> T createInstance(Class<T> type)` vs `Object createInstance(Class<?> type)`. The first
returns T (caller gets the exact type, no cast needed). The second returns Object (caller
must cast). The first is better API design but requires the Class<T> type token. In Spring:
`applicationContext.getBean(UserService.class)` returns `UserService` (no cast) because
of `<T> T getBean(Class<T> type)`. Without this: every `getBean()` call requires a cast.
This pattern (Class<T> type token -> T return) is ubiquitous in reflection-based frameworks.

---

**Q9 (generic pitfalls): What are the most common generic-related bugs in production code?**

A: (1) Raw type cast: `(List<String>) rawList` - heap pollution. (2) Returning `null` from
a generic method: caller does `T result = ...; result.method()` - NPE if T doesn't expect null.
(3) Generic array creation: `new T[]` doesn't work, `new Object[]` then unchecked cast - may
produce ClassCastException. (4) Overloading by erasure: duplicate erasure compile error.
(5) Using `instanceof` with parameterized type: compile error, must use `instanceof List<?>`.

*What separates good from great:* The null return from generic methods is the silent killer.
`<T> T processResult(Result result)` - if `result` is empty, returning null causes NPE at the
call site with no indication of WHERE the null came from. Fix: `Optional<T>` return type for
nullable generic methods, or throw a specific exception for empty results. The rule: never
return null from a generic method. The caller can't know whether null means "valid absent
value" or "bug in the implementation" without documentation. Use `Optional<T>` to make the
optional nature explicit, or throw an exception to make the empty case explicit.

---

### ⚖️ Comparison Table

| Feature | `<T>` Type Parameter | `? extends T` | `? super T` | `<?>` Unbounded |
|---------|---------------------|----------------|-------------|-----------------|
| Can READ as T | Yes | Yes | No (Object only) | No (Object only) |
| Can WRITE T | Yes | No | Yes | No |
| Use when | Need type consistency | Reading from collection | Writing to collection | Don't care about type |
| Example | `<T> T copy(T src)` | `List<? extends Number>` | `List<? super Integer>` | `void print(List<?>)` |
| Caller flexibility | Moderate | High (subtypes OK) | High (supertypes OK) | Maximum |
| PECS role | N/A | Producer | Consumer | Read-only |

---

### 🏛️ System Design

*(Omit: L2 Working file - system design reserved for ★★★ level.)*

---

### 📊 Diagram

*(Omit: Wildcard hierarchy is well-represented in the concept explanation code blocks
and comparison table.)*

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



