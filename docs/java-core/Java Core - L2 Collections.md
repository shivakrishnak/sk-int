---
layout: default
title: "Java Core - L2 Collections"
parent: "Java Core APIs"
nav_order: 3
permalink: /java-core/l2-collections/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [ArrayList vs LinkedList: Memory Layout and Access Cost](#arraylist-vs-linkedlist-memory-layout-and-access-cost) | medium |
| 2 | [HashMap: Buckets, Load Factor, Rehashing, and Java 8 Treeification](#hashmap-buckets-load-factor-rehashing-and-java-8-treeification) | high |
| 3 | [LinkedHashMap and TreeMap: Ordered Map Variants](#linkedhashmap-and-treemap-ordered-map-variants) | medium |
| 4 | [HashSet, LinkedHashSet, and TreeSet: Set Semantics](#hashset-linkedhashset-and-treeset-set-semantics) | medium |
| 5 | [PriorityQueue and ArrayDeque: Queue and Deque Implementations](#priorityqueue-and-arraydeque-queue-and-deque-implementations) | medium |

---

# ArrayList vs LinkedList: Memory Layout and Access Cost

**Interview Weight:** medium - Classic implementation comparison;
tests understanding of memory layout effects on performance.

---

### 🎯 Model Answer

**30 seconds:**

> `ArrayList` is a resizable array: contiguous memory, O(1) random
> access by index, O(n) insert/remove in the middle (array shift).
> `LinkedList` is a doubly-linked list: pointer chain, O(n) access
> by index, O(1) add/remove AT a known node. In practice, `ArrayList`
> beats `LinkedList` in nearly every scenario due to CPU cache
> effects - pointer chasing in `LinkedList` causes cache misses.
> Use `ArrayDeque`, not `LinkedList`, for queue/stack operations.

**3 minutes (Senior):**

> The memory model difference is fundamental. `ArrayList` stores
> references in a contiguous `Object[]`. Modern CPUs prefetch cache
> lines (64 bytes = ~8 references on a 64-bit JVM), so iterating
> `ArrayList` is a sequential memory scan - the next elements are
> already in L1 cache. `LinkedList` stores each element in a `Node`
> object with `prev` and `next` pointers; nodes are scattered on
> the heap. Each `node.next` dereference is a potential L3 cache
> miss (~100 ns vs 1 ns for L1). For a 1M-element list, this means
> `LinkedList` iteration can be 10-50x slower than `ArrayList`.
>
> `ArrayList` growth: when the backing array is full, `ArrayList`
> allocates a new array at 1.5x capacity and copies all elements
> (O(n) amortized, but the copy is a fast `System.arraycopy()`
> which maps to `memcpy`).
>
> `LinkedList` as a `Deque`: the only real advantage. `addFirst()`,
> `removeFirst()`, `addLast()`, `removeLast()` are all O(1) because
> head and tail pointers are maintained. But `ArrayDeque` provides
> the same O(1) amortized deque operations with better cache performance
> (circular array, not pointer chain).

**Framework:** MEMORY-MODEL (contiguous vs pointer chain) +
COMPLEXITY (get/insert/remove) + CACHE-EFFECTS + WHEN-TO-USE

_Adapting up:_ Discuss ArrayList's `ensureCapacity()` for avoiding
incremental growth, the exact 1.5x growth factor, and
`trimToSize()` to reclaim memory.

_Adapting down:_ ArrayList for most uses (fast random access);
LinkedList is almost never the right choice.

**Blank Mind Recovery:**

**(1) Restate:** "ArrayList vs LinkedList - the key difference is
memory layout: ArrayList is a contiguous array (cache-friendly),
LinkedList is a pointer chain (cache-unfriendly)."

**(2) First principles:** "CPU caches work on spatial locality:
fetching one byte brings in 64 bytes of neighbors. ArrayList
benefits from this (neighbors are next elements). LinkedList
breaks it (neighbors are unrelated heap objects)."

**(3) Bridge:** "ArrayList is a filing cabinet - all files in
order, find any instantly, inserting in middle requires shifting.
LinkedList is a scavenger hunt - each clue points to the next
location, getting to file #500 requires following 499 pointers."

---

### 📘 Concept Explanation

**Memory layout:**

```
ArrayList (Object[] backing array):
  index:   0        1        2        3
  data:  [ref A] [ref B] [ref C] [ref D]   <- contiguous

  CPU cache line (64 bytes = ~8 references):
  [A, B, C, D, E, F, G, H] <- all loaded in one cache fetch

LinkedList (doubly-linked Node objects):
  [Node A] --next--> [Node B] --next--> [Node C]
    prev: null          prev: A            prev: B
    data: "A"           data: "B"          data: "C"

  Each Node is a separate heap object:
  - Allocated at different times -> different heap locations
  - Each .next dereference may be a cache miss (L3: ~100ns)
```

**Complexity comparison:**

| Operation                    | ArrayList             | LinkedList                  |
| ---------------------------- | --------------------- | --------------------------- |
| `get(index)`                 | O(1)                  | O(n)                        |
| `add(element)` at end        | O(1) amortized        | O(1)                        |
| `add(index, element)` middle | O(n) shift            | O(n) traverse + O(1) insert |
| `remove(index)` middle       | O(n) shift            | O(n) traverse + O(1) remove |
| `contains(object)`           | O(n)                  | O(n)                        |
| `iterator.next()`            | O(1) + cache-friendly | O(1) + cache-hostile        |
| Memory per element           | 4-8 bytes (reference) | ~48 bytes (Node overhead)   |

**ArrayList growth:**

```java
// Default initial capacity: 10
ArrayList<String> list = new ArrayList<>();

// Pre-size when count is known: avoids incremental growth
ArrayList<String> list = new ArrayList<>(expectedSize);

// Growth factor: 1.5x (JDK source)
// newCapacity = oldCapacity + (oldCapacity >> 1)
// Triggers: System.arraycopy() - maps to OS memcpy()
```

**LinkedList memory overhead:**

Each `Node` in `LinkedList` has: `Object item` (8 bytes), `Node next`
(8 bytes), `Node prev` (8 bytes) plus object header (~16 bytes) =
~40-48 bytes per element. An `ArrayList` reference is 4-8 bytes.
For 1M elements: LinkedList uses ~48MB vs ArrayList's ~8MB.

---

### 💻 Code Example

#### When ArrayList clearly wins

```java
import java.util.*;

public class ListBenchmark {

    // BAD: using LinkedList for random access iteration
    static long sumLinkedList(LinkedList<Integer> list) {
        long sum = 0;
        for (int i = 0; i < list.size(); i++) {
            sum += list.get(i); // O(n) per call = O(n^2) total!
        }
        return sum;
    }

    // GOOD: ArrayList for indexed access
    static long sumArrayList(ArrayList<Integer> list) {
        long sum = 0;
        for (int i = 0; i < list.size(); i++) {
            sum += list.get(i); // O(1) per call = O(n) total
        }
        return sum;
    }

    // ALSO GOOD: Iterator on LinkedList (O(n) total, not O(n^2))
    static long sumLinkedListIterator(LinkedList<Integer> list) {
        long sum = 0;
        for (int val : list) { // uses Iterator, not get(i)
            sum += val;
        }
        return sum;
    }

    // BEST for queue: ArrayDeque, not LinkedList
    public static void main(String[] args) {
        // Queue use case:
        Deque<String> queue = new ArrayDeque<>(); // not LinkedList
        queue.addLast("task1");
        queue.addLast("task2");
        String next = queue.pollFirst(); // O(1) amortized

        // Stack use case:
        Deque<String> stack = new ArrayDeque<>();
        stack.push("item1");       // addFirst
        String top = stack.pop();  // removeFirst
    }
}
```

> **Code walkthrough:** `LinkedList.get(i)` traverses from the head
> each time - using it in an indexed loop is O(n^2). The iterator-based
> loop is O(n) because `Iterator.next()` maintains the cursor position.
> `ArrayDeque` replaces `LinkedList` for all queue/stack use cases:
> it is a circular array with O(1) amortized add/remove at both ends,
> and its memory layout is far more cache-friendly than `LinkedList`.

---

### 🎓 Answers by Seniority

**Junior:** `ArrayList` is faster for random access (get by index).
`LinkedList` is faster for add/remove at the front. In practice,
use `ArrayList` for almost everything.

**Mid-level:** `ArrayList`'s contiguous array makes iteration cache-
friendly. `LinkedList`'s nodes are scattered on the heap - pointer
chasing causes L3 cache misses. For deque/queue operations, `ArrayDeque`
beats `LinkedList` in both speed and memory. Never use indexed `get(i)`
on a `LinkedList`.

**Senior:** Memory overhead: `LinkedList` uses ~48 bytes per element
vs ~8 for `ArrayList`. For 1M elements that's 48MB vs 8MB. Pre-size
`ArrayList` with `new ArrayList<>(expectedSize)` to avoid repeated
growth copies in hot paths. `System.arraycopy()` in `ArrayList` growth
is a single native call, extremely fast.

**Staff:** Profile before optimizing. `ArrayList` wins 95% of the time.
For specialized cases: `CopyOnWriteArrayList` for read-heavy concurrent
lists (snapshot iteration), `ArrayDeque` for FIFO/LIFO, sorted
insertion-maintained list? Use `TreeSet` or binary search +
`Collections.binarySearch()` on `ArrayList`.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                       | Reality                                                                                                                                                                                          | Danger                                                                |
| --- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- |
| 1   | `LinkedList` is faster for insertions in the middle | `LinkedList` traversal to find index i is O(n). Then the O(1) link change. Net: O(n). `ArrayList` shifts are O(n) but use `System.arraycopy()` - faster in practice due to hardware optimization | Choosing LinkedList for "faster insert" and getting worse performance |
| 2   | `ArrayList` wastes memory due to growth copies      | Growth copies are amortized O(1) per add. The copied array is eligible for GC immediately. The unused capacity waste is at most 50% (1.5x growth)                                                | Over-engineering by pre-sizing all ArrayLists                         |
| 3   | `LinkedList` should be used as a Stack              | Java docs say "use Deque instead of Stack/LinkedList for stack". `ArrayDeque` is the correct stack - push/pop at O(1) amortized with better performance                                          | Using LinkedList or legacy Stack class for stack operations           |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - O(n^2) indexed loop on `LinkedList`**

Symptom: Inexplicably slow loop on what seems like a small list.

Root cause: `for (int i = 0; i < list.size(); i++) { list.get(i) }`
on a `LinkedList`. Each `get(i)` is O(n) traverse. Total: O(n^2).

Diagnostic: Profile shows most time in `LinkedList$Entry.next`.

Fix: Use iterator/for-each (O(n)), or switch to `ArrayList`.

---

**Failure 2 - `ArrayList` resize causing GC pressure**

Symptom: Periodic GC pauses correlating with `ArrayList` growth.

Root cause: Large `ArrayList` repeatedly growing from 10 elements,
creating large temporary arrays that are immediately discarded.

Fix: `new ArrayList<>(expectedSize)` when count is known. Use
`ensureCapacity(n)` before bulk adds.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                          |
| ---------------- | ------------------------------------------------------------- |
| 20 min           | Memory layout; O(1) vs O(n) access; ArrayDeque recommendation |
| 40 min           | Add cache effects; ArrayList growth; memory overhead numbers  |
| 1 hour           | Add profiling methodology; when LinkedList has any advantage  |

---

**[JUNIOR] Q1: When would you ever use `LinkedList` over `ArrayList`?**
[TRADE-OFF]

_Why they ask:_ Tests whether candidates know `LinkedList` is rarely
the right answer.

_Likely follow-up:_ "What about `ArrayDeque`?"

Honest answer: almost never in modern Java. The theoretical advantage
(O(1) head/tail add-remove) is better served by `ArrayDeque`.

`LinkedList` still wins in one scenario: when you have an `Iterator`
positioned at a specific node and need to insert/remove at that exact
position. `iterator.remove()` on `LinkedList` is O(1); on `ArrayList`
it involves shifting the array (O(n)). This pattern appears in
simulation code with frequently-modified ordered sequences where you
process elements and remove them from arbitrary positions while iterating.

For all queue/stack/deque use cases: `ArrayDeque` is always preferred.

_What separates good from great:_ Giving the iterator-positioned-remove
as the one legitimate use case, rather than just saying "never."

---

**[MID] Q2: How does `ArrayList` grow and what is the amortized
cost of `add()`?** [CONCEPTUAL]

_Why they ask:_ Tests understanding of amortized analysis.

_Likely follow-up:_ "What is the growth factor?"

When `add()` exceeds capacity, `ArrayList` allocates a new array
at 1.5x the current capacity: `newCapacity = oldCapacity + (oldCapacity >> 1)`.
Then `System.arraycopy()` copies all elements (maps to `memcpy()`).

Amortized O(1) analysis: starting from capacity C and adding n
elements, the total copy work is C + C/1.5 + C/1.5^2 + ... which
is a geometric series summing to approximately 3C. Across n=C adds,
each add costs amortized 3C/C = 3 extra copies on average - O(1).

Practical: `ArrayList` growth is fast (native `memcpy`) but:

- A single growth doubles GC pressure briefly (old array is
  discarded after copy)
- Use `new ArrayList<>(initialCapacity)` when you know expected size
- Use `ensureCapacity(n)` before bulk adds to trigger one resize

_What separates good from great:_ Knowing the exact growth factor
(1.5x, not 2x like Java pre-1.7) and the amortized analysis.

---

**[MID] Q3: DEBUGGING: Iterating a list with `get(i)` is extremely
slow. What is the most likely cause?** [DEBUGGING]

_Why they ask:_ Tests diagnostic pattern for O(n^2) loops.

_Likely follow-up:_ "How do you fix it without changing the loop?"

The most likely cause: the list is a `LinkedList` (or some other
`List` implementation with O(n) `get(index)`) and the code uses
an indexed loop.

```java
// O(n^2) if list is LinkedList:
for (int i = 0; i < list.size(); i++) {
    process(list.get(i));
}
```

Diagnosis: add logging of `list.getClass()` or check with a
profiler - `LinkedList.get()` shows as hot.

Fix option 1 (change to iterator):

```java
for (String item : list) { process(item); }
```

Fix option 2 (convert to ArrayList before loop):

```java
List<String> temp = new ArrayList<>(list);
for (int i = 0; i < temp.size(); i++) { process(temp.get(i)); }
```

Fix option 3 (change type at the source): replace `LinkedList`
with `ArrayList` in the field/variable declaration.

_What separates good from great:_ Noting that checking
`list instanceof RandomAccess` at runtime allows code to choose
the iteration strategy (`ArrayList` implements `RandomAccess`;
`LinkedList` does not).

---

**[SENIOR] Q4: What is the `RandomAccess` marker interface and
how should it influence iteration choice?** [CONCEPTUAL]

_Why they ask:_ Tests awareness of the marker interface pattern
in Collections.

_Likely follow-up:_ "Does `ArrayList` implement it? Does `LinkedList`?"

`java.util.RandomAccess` is a marker interface (no methods). It
signals that a `List` implementation provides O(1) random access.
`ArrayList`, `Vector`, `CopyOnWriteArrayList`, and `Arrays.asList()`
return implement it. `LinkedList` does NOT.

The correct iteration strategy based on `RandomAccess`:

```java
static <T> void process(List<T> list) {
    if (list instanceof RandomAccess) {
        // O(1) get - indexed loop is fine
        for (int i = 0; i < list.size(); i++) {
            handle(list.get(i));
        }
    } else {
        // O(n) get - use iterator
        for (T item : list) {
            handle(item);
        }
    }
}
```

`Collections.sort()` and other utilities use this check internally
to choose between indexed and iterator-based algorithms.

_What separates good from great:_ Knowing that `Collections.sort()`
and `Collections.binarySearch()` check `instanceof RandomAccess`
to optimize their algorithms.

---

**[SENIOR] Q5: TRADE-OFF: When should you prefer `ArrayList` over
`CopyOnWriteArrayList`?** [TRADE-OFF]

_Why they ask:_ Tests knowledge of concurrent list options.

_Likely follow-up:_ "What is the write cost of COWArrayList?"

`CopyOnWriteArrayList` (COW) provides thread-safe iteration: every
read sees a stable snapshot, no `ConcurrentModificationException`
possible. Trade-off: every write (add, remove, set) creates a
complete copy of the backing array - O(n) per write.

Use `CopyOnWriteArrayList` when:

- Reads vastly outnumber writes (event listener lists, config snapshots)
- You need concurrent-safe iteration without external synchronization
- List is small (copying 100 elements is cheap; copying 100k is not)

Use `ArrayList` when:

- Single-threaded code
- Writes are frequent (O(n) copy per write is expensive)
- List is large (COW copy overhead is prohibitive)

For write-heavy concurrent use cases: `Collections.synchronizedList(new ArrayList<>())` with external synchronization on iteration, or a `ConcurrentLinkedDeque` for unordered concurrent access.

_What separates good from great:_ Knowing the O(n) write cost and
the "read-heavy, small list" constraint for COW's use case.

---

**[STAFF] Q6: ARCHITECTURE: How would you implement a bounded
in-memory event buffer with efficient concurrent read/write?**
[ARCHITECTURE]

_Why they ask:_ Tests ability to compose collections for a real
concurrent design.

_Likely follow-up:_ "What happens when the buffer is full?"

Requirements: fixed capacity, concurrent producers add events, concurrent
consumers read (possibly batch).

Solution: `ArrayBlockingQueue` from `java.util.concurrent`:

```java
public class EventBuffer<T> {
    private final BlockingQueue<T> queue;

    public EventBuffer(int capacity) {
        // Bounded, thread-safe, FIFO
        this.queue = new ArrayBlockingQueue<>(capacity);
    }

    // Non-blocking add: drops if full (use case: metrics loss ok)
    public boolean tryAdd(T event) {
        return queue.offer(event);  // returns false if full
    }

    // Blocking add: waits for space (use case: critical events)
    public void addBlocking(T event) throws InterruptedException {
        queue.put(event); // blocks until space available
    }

    // Batch drain for efficient consumer
    public List<T> drain(int maxBatch) {
        List<T> batch = new ArrayList<>(maxBatch);
        queue.drainTo(batch, maxBatch); // atomic batch remove
        return batch;
    }
}
```

`ArrayBlockingQueue` is backed by a circular array (cache-friendly),
uses separate `ReentrantLock`s for put and take (concurrent
producers and consumers), and supports `drainTo()` for efficient
batch consumption.

Alternative for single-producer/single-consumer with extreme
throughput: `java.util.concurrent.ConcurrentLinkedQueue` (lock-free)
or a ring buffer (Disruptor pattern).

_What separates good from great:_ Knowing `drainTo()` as an atomic
batch-remove operation, and connecting to the Disruptor pattern for
extreme throughput cases.

---

**[STAFF] Q7: BEHAVIORAL: Describe a production incident involving
a collection choice.** [BEHAVIORAL - STAR]

_Why they ask:_ Tests production experience with collection performance.

_Likely follow-up:_ "What monitoring would prevent this in the future?"

**Situation:** A batch processing service processed order records.
The code used `LinkedList` as the accumulator for processed records
because "inserts don't require shifting." The service processed 50k
records per batch, typically completing in 2 seconds. After a
feature added a deduplication step, processing time spiked to 45 seconds.

**Task:** Investigate the performance regression introduced by the
deduplication step.

**Action:** Added timing logs around each phase. Profiler showed 98%
of time in the deduplication logic: `for (int i = 0; i < result.size(); i++) { if (result.get(i).equals(...))`
on a `LinkedList`. O(n^2) for 50k records = 2.5 billion operations.

Changed `LinkedList` to `ArrayList` for the accumulator. Deduplication
time dropped from 43 seconds to 0.1 seconds. Same O(n^2) algorithm,
but `ArrayList.get(i)` is O(1) + cache-friendly vs O(n) + pointer chase.

**Result:** Processing time returned to 2 seconds. Added linting
rule to flag `LinkedList` usage in code reviews.

_What separates good from great:_ Connecting the O(n^2) algorithmic
consequence to the specific collection API behavior (`get(i)` cost)
and adding a systematic prevention (linting rule).

---

**[SENIOR] Q8: What is `ArrayList`'s `trimToSize()` and when
would you use it?** [CONCEPTUAL]

_Why they ask:_ Tests depth of ArrayList API knowledge.

_Likely follow-up:_ "What is the capacity vs size difference?"

`ArrayList.size()` returns the number of stored elements.
`ArrayList.capacity()` (no public method - use reflection for
testing) is the length of the backing array, always >= size.

After growth events, `ArrayList`'s backing array can be up to
1.5x the needed size. For a list that is built and never modified
again, this unused space wastes memory.

`trimToSize()` sets the backing array length to exactly `size()`,
eliminating unused capacity.

Use case: building a large list that is then stored as a cache
value for the lifetime of the application. After construction,
call `trimToSize()` to reclaim the up-to-50% excess capacity.

```java
List<String> cache = new ArrayList<>();
// ... populate with N elements
((ArrayList<String>) cache).trimToSize(); // now size == capacity
// Store in application cache for long-term use
```

Not worth using for short-lived lists or when memory is not
a concern.

_What separates good from great:_ Knowing the distinction between
`size` (elements count) and backing array `capacity`, and
identifying the long-lived-cache use case.

---

**[STAFF] Q9: TRADE-OFF: How does the choice between `ArrayList`
and `LinkedList` illustrate the "know your hardware" principle
in software design?** [TRADE-OFF]

_Why they ask:_ Tests ability to connect data structure design to
hardware realities.

_Likely follow-up:_ "How has this principle changed over time?"

The performance difference between `ArrayList` and `LinkedList` is
not primarily about algorithmic complexity - they are both O(n) for
iteration. The difference is hardware utilization.

Modern CPUs fetch memory in cache lines (64 bytes). When `ArrayList`
iterates, sequential addresses are fetched together - the CPU
prefetcher correctly predicts the next cache line and loads it
before it is needed. Iteration cost approaches memory bandwidth
speed: ~10GB/s on modern hardware.

`LinkedList` iteration follows pointers to unpredictable heap
locations. Each pointer dereference may be an L3 cache miss (1-5%
probability if nodes are scattered). L3 miss latency: ~30-40 ns.
At 30ns per miss and 1M elements: 30 ms just in cache misses.
`ArrayList` of same size: ~1ms.

The lesson: algorithmic complexity (big-O) is a model that ignores
constant factors. Modern hardware constant factors (cache hit rate,
branch prediction accuracy, SIMD vectorization) often dominate
real performance. "Know your hardware" means understanding when
big-O analysis is misleading.

This principle has evolved: in 1990, the cost model was CPU cycles.
In 2026, the cost model is cache hierarchy (L1/L2/L3 cache miss
rates) and memory bandwidth. Data structures that maximize cache
line utilization (`ArrayList`, arrays) beat pointer-chain structures
(`LinkedList`, tree nodes) even when they have worse theoretical
complexity.

_What separates good from great:_ Quantifying the cache miss
penalty and connecting it to why cache-oblivious algorithms and
data-oriented design are active research areas in systems programming.

---

---

# HashMap: Buckets, Load Factor, Rehashing, and Java 8 Treeification

**Interview Weight:** high - One of the most common mid-senior Java
interview questions; tests understanding of the most-used data structure.

---

### 🎯 Model Answer

**30 seconds:**

> `HashMap` stores key-value pairs in a hash table: an array of
> buckets. The bucket index is `hash(key) % capacity`. Multiple keys
> can hash to the same bucket (collision) - handled by a linked list
> per bucket (Java 7) or a Red-Black tree per bucket when the chain
> exceeds 8 entries (Java 8). The load factor (default 0.75) triggers
> rehashing when filled fraction exceeds it: capacity doubles and
> all entries are redistributed. Not thread-safe.

**3 minutes (Senior):**

> Internal structure: `HashMap` is a `Node<K,V>[]` table (the
> bucket array) with initial capacity 16. The bucket index for a
> key is computed as `(n-1) & hash(key)` where `hash()` spreads the
> key's `hashCode()` using XOR with the high 16 bits to reduce
> clustering.
>
> Java 8 treeification: when a single bucket chain exceeds 8 nodes
> AND the table has at least 64 buckets, the linked list converts to
> a TreeNode (Red-Black tree). This makes worst-case lookup O(log n)
> per bucket instead of O(n). The tree untreeifies back to a list
> when the bucket shrinks below 6 nodes.
>
> Rehashing: when `size > capacity * loadFactor` (default: 16 \* 0.75
> = 12 entries), `HashMap` doubles the capacity and redistributes
> all entries. Old bucket index `i` entries move to either `i` or
> `i + oldCapacity` (determined by the new high bit of the hash) -
> elegant O(1) redistribution per entry.
>
> Thread safety: `HashMap` is NOT thread-safe. In Java 7, concurrent
> resize caused infinite loops via circular linked lists. In Java 8,
> this is fixed but concurrent modification still produces incorrect
> results. Use `ConcurrentHashMap` for thread safety.

**Framework:** STRUCTURE (array + chains/trees) + HASH-FUNCTION

- LOAD-FACTOR + REHASH + JAVA8-TREEIFICATION + THREAD-SAFETY

_Adapting up:_ Discuss `hashCode` / `equals` contract, HashMap's
hash spreading function, and how poor `hashCode` implementations
cause all keys to land in the same bucket.

_Adapting down:_ HashMap = array of chains. Bucket index = hash(key) %
capacity. Rehash when 75% full.

**Blank Mind Recovery:**

**(1) Restate:** "HashMap internals: bucket array indexed by hash.
Collision = chain in bucket. Rehash when load factor exceeded.
Java 8 adds tree per bucket for O(log n) worst case."

**(2) First principles:** "A hash map trades space for O(1) lookup:
dedicate an array slot to each possible hash value. With limited
array size, map hash values to bucket indices; handle collisions
with chaining."

**(3) Bridge:** "HashMap is like a mail sorting center: buckets are
labeled mailboxes (hash). Letters (keys) go to their box based on
their code. If one box is overflowing (collision), stack them in
a mini-pile. Java 8 turns the pile into a sorted filing system
(tree) when it gets too big."

---

### 📘 Concept Explanation

**Internal structure (Java 8+):**

```
HashMap internals:

  table: Node<K,V>[]  (bucket array, default capacity 16)
  size: int           (number of key-value pairs)
  loadFactor: float   (default 0.75)
  threshold: int      (= capacity * loadFactor = 12 initially)
  modCount: int       (for fail-fast iterators)

Each entry is a Node:
  int hash;
  K key;
  V value;
  Node<K,V> next;  // linked list (or TreeNode for tree buckets)

Bucket layout:
  table[0]: null
  table[1]: Node("Alice",30) -> Node("Eve",25) -> null
  table[2]: TreeNode("Bob",40)  [treeified - >8 entries]
  ...
  table[15]: Node("Charlie",35)
```

**Hash function:**

```java
// HashMap spreads hashCode to reduce clustering:
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 :
        (h = key.hashCode()) ^ (h >>> 16);
}
// XOR with upper 16 bits ensures high bits affect low bits
// This matters because bucket index = hash & (capacity-1)
// which only uses the low bits of the hash

// Bucket index:
int bucketIndex = (capacity - 1) & hash(key);
// Requires capacity to be a power of 2
// (capacity-1) acts as a bit mask
```

**Load factor and rehashing:**

```
Initial: capacity=16, loadFactor=0.75, threshold=12

After 12 entries:
  resize() called:
    newCapacity = 16 * 2 = 32
    newThreshold = 32 * 0.75 = 24
    For each entry at bucket i:
      if (hash & oldCapacity) == 0: stays at bucket i
      else: moves to bucket i + oldCapacity
    Old table is garbage collected

Rehashing cost: O(n) amortized once per doubling
Pre-size to avoid rehash: new HashMap<>(expectedSize / 0.75 + 1)
```

**Java 8 Treeification:**

```
Trigger: bucket chain length > TREEIFY_THRESHOLD (8)
         AND table capacity >= MIN_TREEIFY_CAPACITY (64)

If table < 64: resize instead (growing table distributes entries)
If table >= 64 AND chain > 8: convert chain to Red-Black tree

Tree bucket: O(log n) for get/put/remove in that bucket
Untreeify: when bucket shrinks below UNTREEIFY_THRESHOLD (6)

Why trees? Worst case with bad hashCode: all keys in same bucket.
Java 7: O(n) lookup for the bucket chain = DoS vulnerability!
Java 8: O(log n) worst case, also requires keys to implement
Comparable (or uses identity hash as fallback)
```

---

### 💻 Code Example

#### hashCode / equals and HashMap behavior

```java
// BAD: class used as Map key without hashCode/equals
class BadKey {
    int id;
    BadKey(int id) { this.id = id; }
    // No equals/hashCode - uses Object's identity-based versions
}

Map<BadKey, String> map = new HashMap<>();
BadKey k1 = new BadKey(1);
map.put(k1, "Alice");

BadKey k2 = new BadKey(1); // same id, different object
System.out.println(map.get(k2)); // null! k1 != k2 by identity
```

> **Code walkthrough:** Without `hashCode()`/`equals()` overrides,
> `BadKey` uses `Object`'s identity-based implementations. `k1` and
> `k2` hash to different buckets (different object identity) and
> are not equal. The map can never find a key by value equality.

```java
// GOOD: proper hashCode and equals
record GoodKey(int id) {
    // Records auto-generate hashCode and equals based on components
    // hashCode: based on id field
    // equals: id equality
}

Map<GoodKey, String> map = new HashMap<>();
map.put(new GoodKey(1), "Alice");
System.out.println(map.get(new GoodKey(1))); // "Alice" - correct

// Manual implementation for non-record class:
class ManualKey {
    final int id;
    ManualKey(int id) { this.id = id; }

    @Override public int hashCode() {
        return Integer.hashCode(id); // consistent with equals
    }
    @Override public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof ManualKey)) return false;
        return id == ((ManualKey) o).id;
    }
}
```

> **Code walkthrough:** `record` auto-generates `hashCode()` using
> all component fields and `equals()` comparing all components by value.
> Two `GoodKey(1)` instances have the same `hashCode` (same bucket)
> and `equals()` returns true - so the map finds the entry. The
> contract: if `a.equals(b)`, then `a.hashCode() == b.hashCode()`.
> The converse is not required (hash collisions are fine).

---

#### Pre-sizing for performance

```java
// BAD: default capacity causes multiple rehashes for large maps
Map<String, User> cache = new HashMap<>();
users.forEach(u -> cache.put(u.getId(), u)); // rehashes at 12, 24, 48...

// GOOD: pre-size to avoid rehash
int expectedSize = users.size();
// Formula: capacity = expectedSize / loadFactor + 1
Map<String, User> cache = new HashMap<>(
    (int)(expectedSize / 0.75) + 1);
users.forEach(u -> cache.put(u.getId(), u)); // no rehash
```

> **Code walkthrough:** For 1M entries, the default HashMap rehashes
> approximately 17 times (16 -> 32 -> ... -> 1M+). Each rehash is
> O(n). Total extra work: ~2M copy operations. Pre-sizing eliminates
> all rehashes. The formula `expectedSize / 0.75 + 1` sets capacity
> so the threshold (capacity \* 0.75) is above the expected size.
> Guava's `Maps.newHashMapWithExpectedSize(n)` does this calculation.

---

### 🎓 Answers by Seniority

**Junior:** `HashMap` uses `hashCode()` to find the bucket and
`equals()` to find the exact key in the bucket. Keys must implement
both. Default capacity 16, grows when 75% full.

**Mid-level:** Hash function: `hash = key.hashCode() XOR (key.hashCode() >>> 16)`.
Bucket index: `hash & (capacity - 1)`. Rehash at `capacity * 0.75`.
Java 8: bucket chain converts to Red-Black tree when length > 8 (treeification).
Pre-size with `new HashMap<>(expectedSize / 0.75 + 1)` for large maps.

**Senior:** Java 7 HashMap had a DoS vulnerability: crafted keys with
the same hash exhausted a bucket chain to O(n) lookup. Java 8 treeification
makes O(log n) worst case and was the fix. Rehashing: old bucket
index `i` entries go to `i` or `i + oldCapacity` based on the new
high bit of their hash - elegant O(1) per-entry determination.

**Staff:** At scale, HashMap capacity planning is a GC optimization.
A 10M-entry HashMap with default sizing creates ~24 backing arrays
over its lifetime (rehash doubling). Only the final one survives; the
rest are garbage. For long-lived caches, pre-size to avoid this GC
churn. Monitor via JMX: `HashMap$TreeNode` instances in heap dumps
indicate hash collisions (treeified buckets) from poor `hashCode`.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                   | Reality                                                                                                                               | Danger                                                                         |
| --- | ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| 1   | `HashMap` maintains insertion order             | `HashMap` has no ordering guarantee. Order can change on rehash. `LinkedHashMap` maintains insertion order                            | Code depending on HashMap order silently breaks on JVM upgrade or rehash       |
| 2   | `hashCode()` returning a constant is valid      | Technically valid (all keys hash to bucket 0) but turns HashMap into O(n) lookup. All entries in one bucket chain                     | Catastrophic performance - O(n) get/put                                        |
| 3   | Two keys with the same `hashCode` must be equal | Identical hash codes (collision) are normal. `hashCode` collision only means they share a bucket. `equals()` still distinguishes them | Confusing hash collision (expected) with equals semantics                      |
| 4   | `null` keys are not supported by `HashMap`      | `HashMap` explicitly supports one `null` key (stored at bucket 0). `ConcurrentHashMap` and `Hashtable` do NOT support null keys       | NullPointerException surprise when switching from HashMap to ConcurrentHashMap |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Using mutable keys in HashMap**

Symptom: Values become unretrievable after keys are modified.

Root cause: A mutable object is used as a `HashMap` key. After
`put(key, value)`, the key is modified, changing its `hashCode`.
The entry is stored in the OLD bucket but lookup uses the NEW bucket.

Fix: Only use immutable objects as Map keys (String, Integer, Long,
record). If mutable, ensure the fields used in `hashCode`/`equals`
are never modified after insertion.

---

**Failure 2 - Hash collision DoS (Java 7)**

Symptom: A REST endpoint accepting arbitrary string input becomes
very slow; profiler shows HashMap.get() consuming 99% of time.

Root cause: Attacker provides many strings with identical hashCode
(specially crafted). All end up in one bucket, causing O(n) per lookup.

Fix (Java 7): Enable randomized hash seeds (`-Djdk.map.althashing.threshold=0`).
Fix (Java 8+): Treeification limits to O(log n) worst case.
Fix (general): Rate limit inputs; validate key content.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                          |
| ---------------- | ------------------------------------------------------------- |
| 20 min           | Bucket array; hash to bucket index; collision chaining        |
| 40 min           | Add load factor/rehash; equals/hashCode contract              |
| 1 hour           | Add Java 8 treeification; null key; pre-sizing                |
| 1.5 hours        | Add thread-safety failure modes; ConcurrentHashMap comparison |

---

**[JUNIOR] Q1: What happens when two keys have the same `hashCode()`
in a `HashMap`?** [CONCEPTUAL]

_Why they ask:_ Tests understanding of hash collision handling.

_Likely follow-up:_ "What is the difference between hash collision
and key equality?"

Two keys with the same `hashCode` hash to the same bucket. The
HashMap stores them both in that bucket using a linked list (or
tree in Java 8). When you do `get(key)`, the HashMap:

1. Computes `hashCode()` to find the bucket
2. Iterates the bucket's chain, using `equals()` to find the exact entry

So `hashCode()` collision is handled correctly - both entries are
stored and retrieved. Performance degrades: a bucket with 10 entries
requires up to 10 `equals()` calls for a lookup (or O(log 10) with
Java 8 tree).

Contract: if `a.equals(b)` must imply `a.hashCode() == b.hashCode()`.
The reverse is NOT required: same hashCode does not mean equal.

_What separates good from great:_ Distinguishing between hashCode
collision (two different keys, same hash code - normal, handled)
and hashCode inconsistency with equals (same key, different hash
on repeated calls - breaks HashMap invariant).

---

**[MID] Q2: What is the `hashCode` / `equals` contract and what
breaks when it is violated?** [CONCEPTUAL]

_Why they ask:_ A fundamental contract that has surprising failure modes.

_Likely follow-up:_ "What happens if `equals` is correct but `hashCode`
always returns the same value?"

The contract (from `Object.hashCode()` Javadoc):

1. Consistency: `hashCode()` must return the same value for the
   same object on multiple invocations (unless fields change).
2. Equality implies same hash: if `a.equals(b)`, then
   `a.hashCode() == b.hashCode()`.
3. (Recommended): if `!a.equals(b)`, `a.hashCode() != b.hashCode()`
   for better distribution (not required).

What breaks when violated:

**`equals` inconsistent with `hashCode`**: `HashMap` puts key in
bucket based on `hashCode()`. If two `equals` objects have different
hashCodes, they go in different buckets. `get()` looks in the new
bucket, never finds the entry → returns null for a key that exists.

**`hashCode` always returns constant**: valid but catastrophic. All
keys in bucket 0. Lookup is O(n) for every get/put. HashMap becomes
a linked list.

**Mutable key after insertion**: if `hashCode` depends on a mutable
field and the field changes, the entry is "lost" in the old bucket.

_What separates good from great:_ The mutable key scenario (stored
in old bucket, lookup finds new bucket) is the most insidious
violation because it fails silently with no exception.

---

**[SENIOR] Q3: How does `ConcurrentHashMap` differ from
`Collections.synchronizedMap(HashMap)`?** [COMPARISON]

_Why they ask:_ Tests concurrent collections depth.

_Likely follow-up:_ "Is ConcurrentHashMap.get() ever stale?"

`synchronizedMap(map)` wraps the map with a single mutex: every
operation (get, put, remove, containsKey) acquires the same lock.
Benefits: simple, consistent. Problems: reads block reads;
iteration requires external synchronized block; under contention,
all operations queue behind a single lock.

`ConcurrentHashMap` uses a much more granular approach:

- **Reads**: lock-free. The table is a `volatile Node[]`. `get()`
  reads without acquiring any lock. This is safe because Node
  fields are `volatile` or final.
- **Writes**: fine-grained. Empty bucket: CAS operation (single
  CPU instruction). Non-empty bucket: `synchronized` on the bucket's
  head node only (not the entire map).
- **Sizing**: separate `LongAdder`-based counter to avoid lock on
  size updates.

Result: reads are always wait-free; writes contend only with
other writes to the same bucket (1/16th of the map on average
for a 16-bucket map).

Is `get()` stale? After a `put()` completes (happens-before is
established), subsequent `get()` sees the new value. However, a
`get()` concurrent with an in-progress `put()` may see the old
value - this is expected and documented behavior (not a bug).

_What separates good from great:_ Knowing reads are lock-free
(volatile read, no mutex) and that concurrent reads seeing slightly-stale
data is documented acceptable behavior.

---

**[SENIOR] Q4: What is treeification in Java 8 and why was it added?**
[CONCEPTUAL]

_Why they ask:_ Tests Java 8 HashMap internals knowledge.

_Likely follow-up:_ "What condition triggers treeification?"

Pre-Java 8: each HashMap bucket was a simple linked list. With a
pathological `hashCode()` implementation (or malicious input), all
keys could hash to the same bucket, creating a chain of length N.
`get()/put()` worst-case was O(N) per bucket - O(N) total for a
map with N entries in one bucket.

This was a known CVE (2011): attackers could craft HTTP request
parameters with identical hashCodes, causing the server-side request
parsing (which used HashMap) to consume O(N^2) CPU time. Several
frameworks (including some Tomcat/Jetty versions) were vulnerable.

Java 8 fix: treeification. When a bucket chain exceeds 8 nodes AND
the table has >= 64 total buckets:

1. Convert the linked list to a Red-Black tree (`TreeNode` subtypes)
2. Get/put/remove in the tree bucket: O(log n)
3. Worst case for the whole map: O(log n) per operation

Conditions for treeification:

- Chain length > `TREEIFY_THRESHOLD` = 8
- Table capacity >= `MIN_TREEIFY_CAPACITY` = 64
  (below 64, HashMap resizes the table instead - spreading entries
  across more buckets is cheaper than building a tree)

Untreeification: when a bucket shrinks below `UNTREEIFY_THRESHOLD` = 6

_What separates good from great:_ Connecting treeification to the
hash collision DoS attack as the security motivation, not just a
performance optimization.

---

**[STAFF] Q5: ARCHITECTURE: You are building an in-memory lookup
table that will have 50 million entries. How would you approach
the HashMap sizing?** [ARCHITECTURE]

_Why they ask:_ Tests production HashMap sizing knowledge.

_Likely follow-up:_ "What is the memory cost of 50M HashMap entries?"

50M entries with default HashMap:

**Memory estimation:**

- Each `Node<K,V>`: ~32 bytes (object header 16 + hash 4 + 3 refs 24 = ~40, aligned to 32)
- 50M nodes: 50M \* 40 = ~2GB just for nodes (before keys/values)
- Backing array at 75% load factor: ~66M buckets \* 4 bytes = ~256MB
- Total: ~2.5GB for the map structure, not counting key/value objects

**Sizing to avoid rehashing:**

```java
// Capacity = expectedSize / loadFactor + 1 (rounded to power of 2)
int capacity = Integer.highestOneBit(
    (int)(50_000_000 / 0.75) + 1) << 1; // ~67M -> 128M buckets

Map<K,V> map = new HashMap<>(capacity, 0.75f);
```

**Consider alternatives for 50M entries:**

- Lower load factor (e.g., 0.5): fewer collisions, larger array, faster lookups
- Off-heap: `ConcurrentHashMap` keeps data in Java heap (GC pressure).
  Chronicle Map, RocksDB embedded, or a Caffeine cache with off-heap mode
  for GC-free operation
- Sharding: 16 maps of 3M entries each, `key.hashCode() % 16` determines shard

**GC impact:** A 2GB HashMap causes long GC pauses during full GC
(mark all 50M nodes). Consider: CMS/ZGC/Shenandoah for pause sensitivity,
or off-heap storage (Chronicle Map) to keep the objects out of the
Java heap entirely.

_What separates good from great:_ Quantifying memory (~40 bytes/entry),
mentioning GC impact as a first-class concern at 50M entries, and
naming off-heap alternatives.

---

**[STAFF] Q6: BEHAVIORAL: When have you debugged a performance issue
traced to HashMap internals?** [BEHAVIORAL - STAR]

_Why they ask:_ Tests production HashMap debugging experience.

_Likely follow-up:_ "What signals in a heap dump tell you about HashMap health?"

**Situation:** A user profile service was experiencing 500ms+ latency
on lookups that should be O(1). The service cached user permissions
in a `HashMap<PermissionKey, Boolean>` with ~100k entries per user
session.

**Task:** Diagnose why HashMap lookups were slow for certain sessions.

**Action:**

1. Added timing around individual `map.get()` calls - confirmed
   some took 50ms while others took <1ms.
2. Took a heap dump with `jmap -dump:live,format=b,file=heap.hprof <pid>`.
3. In MAT (Memory Analyzer Tool), inspected the HashMap's backing
   table - found single buckets with 80-100 entries (highly unbalanced).
4. Dumped the `PermissionKey.hashCode()` for a slow session's entries -
   all returned the same value.

Root cause: `PermissionKey` had a buggy `hashCode()` that returned
`userId ^ roleId` where `userId` and `roleId` were integers from
a specific sequence. For one user, the XOR of all role IDs with the
user ID happened to always produce the same 4-bit low value.

Fix: Improved `hashCode()` using `Objects.hash(userId, roleId, permissionType)`.
Rewrote as a Java record for auto-generated, correct `hashCode`.

**Result:** Lookup times returned to sub-millisecond.

_What separates good from great:_ Using `jmap` + MAT to inspect
bucket distribution, and identifying the XOR hashCode weakness
pattern (XOR can cancel bits and reduce hash space).

---

**[MID] Q7: What is the default initial capacity and load factor
of `HashMap`? Why those values?** [CONCEPTUAL]

_Why they ask:_ Tests understanding of HashMap tuning parameters.

_Likely follow-up:_ "What happens if you set load factor to 1.0?"

Initial capacity: **16** (must be a power of 2 for bitwise bucket
index calculation). 16 buckets support 16 \* 0.75 = 12 entries before
first rehash - reasonable for small maps.

Load factor: **0.75** - an empirically chosen trade-off:

- High load factor (e.g., 1.0): fewer rehashes, more collisions,
  slower lookup (longer bucket chains)
- Low load factor (e.g., 0.25): faster lookup (shorter chains),
  more memory waste, more frequent rehashes during building

  0.75 balances time vs space. The Java docs describe it as providing
  "a good tradeoff between time and space costs."

Setting load factor to 1.0: map fills completely before rehashing.
More collisions, but for use cases where the map is built once and
only read (no more inserts), this can save memory (fewer empty buckets).

Setting load factor to 0.5: better performance for lookup-heavy maps
(shorter chains on average), at 2x the memory cost.

_What separates good from great:_ The actual trade-off analysis -
lower load factor = better lookup but more memory; and the "build
once, read many" justification for load factor 1.0.

---

---

# LinkedHashMap and TreeMap: Ordered Map Variants

**Interview Weight:** medium - Tests whether candidates know when and
why to use ordered maps.

---

### 🎯 Model Answer

**30 seconds:**

> `LinkedHashMap` extends `HashMap` with a doubly-linked list through
> all entries, maintaining insertion order (default) or access order
> (LRU mode). O(1) get/put like HashMap. `TreeMap` implements a
> Red-Black tree: O(log n) get/put, entries always sorted by key.
> Use `LinkedHashMap` when you need HashMap performance WITH predictable
> iteration order. Use `TreeMap` when you need sorted key order or
> range queries (headMap, tailMap, floorKey).

**3 minutes (Senior):**

> `LinkedHashMap` internal structure: every `Entry` has two extra
> pointers (`before` and `after`) forming a doubly-linked list that
> spans the entire map in insertion order. Iteration follows this list,
> not the bucket array - so iteration order is always consistent.
> With `accessOrder=true` (the LRU constructor), `get()` moves the
> accessed entry to the tail of the list. Combined with
> `removeEldestEntry()` override, this is a complete LRU cache in
> ~5 lines.
>
> `TreeMap` uses a Red-Black tree: each entry is a node with `left`,
> `right`, `parent`, and `color` fields. Tree invariants guarantee
> O(log n) height. Iteration in `entrySet()` is an in-order traversal:
> always sorted by key's natural order (or provided Comparator).
> Unique to TreeMap: `headMap(key)`, `tailMap(key)`, `subMap(from,to)`
> return live views of the key range; `floorKey(k)`, `ceilingKey(k)`,
> `lowerKey(k)`, `higherKey(k)` navigate by proximity.

**Framework:** LINKEDHASHMAP (insertion/access order + HashMap speed)

- TREEMAP (sorted + range queries + O(log n)) + WHEN-TO-USE

_Adapting up:_ Discuss thread-safe variants (`ConcurrentSkipListMap`
for sorted concurrent map), and how `LinkedHashMap`'s access order
supports eviction policy implementation.

_Adapting down:_ LinkedHashMap = HashMap with insertion order. TreeMap =
sorted map. Use TreeMap for range queries.

**Blank Mind Recovery:**

**(1) Restate:** "LinkedHashMap adds insertion/access order to HashMap.
TreeMap keeps entries sorted by key. LinkedHashMap for ordered
iteration; TreeMap for sorted keys + range queries."

**(2) First principles:** "HashMap is fast but unordered. Sometimes
order matters: insertion order for deterministic serialization, sorted
order for range scans. LinkedHashMap and TreeMap trade some overhead
for order guarantees."

**(3) Bridge:** "LinkedHashMap is HashMap with a thread of yarn through
all entries - follow the yarn to get them in insertion order. TreeMap
is a sorted filing cabinet - instantly find everything before or after
a given key."

---

### 📘 Concept Explanation

**`LinkedHashMap` internals:**

```
LinkedHashMap extends HashMap:

Each Entry has extra fields:
  Entry<K,V> before;  // previous in access/insertion order
  Entry<K,V> after;   // next in access/insertion order

Double-linked list threads through all entries:
  head <-> Entry(A) <-> Entry(B) <-> Entry(C) <-> tail
  (in insertion order by default)

Iteration: follows the before/after chain, not the bucket array
  -> Always consistent, predictable order

accessOrder mode (constructor arg):
  new LinkedHashMap<>(capacity, loadFactor, true)
  -> get() moves accessed entry to tail (most recently used = tail)
  -> head = least recently used
  -> Used for LRU cache
```

**`LinkedHashMap` as LRU cache:**

```java
int CAPACITY = 1000;
Map<String, User> lruCache = new LinkedHashMap<>(
        CAPACITY, 0.75f, true) { // accessOrder=true
    @Override
    protected boolean removeEldestEntry(
            Map.Entry<String, User> eldest) {
        return size() > CAPACITY; // evict LRU when over capacity
    }
};
```

**`TreeMap` internals:**

```
TreeMap uses a Red-Black Tree:
  - Each node: key, value, left, right, parent, color (RED/BLACK)
  - Red-Black invariants: O(log n) height guaranteed
  - In-order traversal = ascending key order

Operations: O(log n) for get, put, remove, containsKey

Additional NavigableMap operations (only TreeMap/ConcurrentSkipListMap):
  firstKey() / lastKey()     - min/max key
  floorKey(k)               - largest key <= k
  ceilingKey(k)             - smallest key >= k
  lowerKey(k)               - largest key < k
  higherKey(k)              - smallest key > k
  headMap(toKey)            - submap of keys < toKey (live view)
  tailMap(fromKey)          - submap of keys >= fromKey (live view)
  subMap(fromKey, toKey)    - submap [fromKey, toKey) (live view)
  descendingMap()           - reverse-order view
  pollFirstEntry()          - remove and return smallest entry
  pollLastEntry()           - remove and return largest entry
```

**Thread-safe sorted map: `ConcurrentSkipListMap`**

`TreeMap` is NOT thread-safe. For concurrent sorted maps, use
`ConcurrentSkipListMap` (java.util.concurrent): a lock-free skip list
with O(log n) amortized operations.

---

### 💻 Code Example

#### TreeMap range queries in practice

```java
import java.util.*;

// Use case: time-series events indexed by timestamp
public class TimeSeriesStore {
    private final TreeMap<Long, String> events = new TreeMap<>();

    public void add(long timestampMs, String event) {
        events.put(timestampMs, event);
    }

    // Get most recent event at or before a given time
    public String getLatestBefore(long timestampMs) {
        Map.Entry<Long, String> entry =
            events.floorEntry(timestampMs);
        return entry == null ? null : entry.getValue();
    }

    // Get all events in a time window [from, to)
    public SortedMap<Long, String> getWindow(
            long fromMs, long toMs) {
        return events.subMap(fromMs, toMs); // live view
    }

    // Remove all events older than a cutoff
    public void evictBefore(long cutoffMs) {
        events.headMap(cutoffMs).clear(); // clears the live view
    }
}
```

> **Code walkthrough:** `floorEntry(ts)` returns the entry with the
> largest key <= ts - the most recent event at or before the query
> time. `subMap(from, to)` returns a live view (modifications to the
> view modify the original map). `headMap(cutoff).clear()` removes all
> entries with key < cutoff atomically - no loop needed. All operations
> are O(log n). This pattern is common in caching layers, rate limiters,
> and time-series databases.

---

### 🎓 Answers by Seniority

**Junior:** `LinkedHashMap` is `HashMap` with insertion order preserved.
`TreeMap` keeps keys sorted. Use `TreeMap` when you need sorted output
or range queries.

**Mid-level:** `LinkedHashMap` maintains order by threading a doubly-linked
list through entries. With `accessOrder=true`, it becomes an LRU cache
backend. `TreeMap` wraps a Red-Black tree: O(log n) all ops, but supports
`floorKey`, `ceilingKey`, `headMap`, `tailMap` for range queries.

**Senior:** `TreeMap` live views (`subMap`, `headMap`, `tailMap`) are
the key feature: `headMap(cutoff).clear()` removes all entries below
the cutoff in one operation. `ConcurrentSkipListMap` is the thread-safe
sorted map for concurrent scenarios. `LinkedHashMap`'s `removeEldestEntry`
hook enables automatic LRU eviction without manual eviction logic.

**Staff:** For sorted concurrent maps, `ConcurrentSkipListMap` uses
lock-free CAS operations - reads never block. For large sorted datasets
not fitting in memory, use `TreeMap` as an index over an off-heap store.
`LinkedHashMap` for in-memory LRU is production-grade for caches up to
millions of entries; beyond that, use Caffeine with LRU policy.

---

### ⚠️ Common Misconceptions

| #   | Misconception                            | Reality                                                                                                                                                          | Danger                                                           |
| --- | ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| 1   | `LinkedHashMap` is sorted like `TreeMap` | `LinkedHashMap` maintains insertion OR access order, NOT sorted order. It preserves the order entries were added                                                 | Using LinkedHashMap thinking keys will be sorted                 |
| 2   | `TreeMap` subMap views are copies        | `headMap()`, `tailMap()`, `subMap()` return LIVE views - modifications to the view modify the original TreeMap. Reading from the view sees current TreeMap state | Accidentally modifying the source TreeMap via a subMap view      |
| 3   | `TreeMap` accepts null keys              | `TreeMap` does NOT accept null keys (compareTo would throw NPE). `HashMap` and `LinkedHashMap` accept one null key                                               | NullPointerException when migrating code from HashMap to TreeMap |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - TreeMap NPE on null key**

Symptom: `NullPointerException` from within `TreeMap.put()` when
code was working with `HashMap`.

Root cause: Code migrated from `HashMap` (null key allowed) to
`TreeMap` (null key causes NPE in compareTo).

Fix: Remove null keys before insertion, or use a custom `Comparator`
that handles nulls: `Comparator.nullsFirst(Comparator.naturalOrder())`.

---

**Failure 2 - Unintended TreeMap modification via subMap view**

Symptom: TreeMap entries disappear unexpectedly.

Root cause: `treeMap.headMap(key).clear()` was called somewhere,
clearing the live view which modifies the original.

Fix: Use `new TreeMap<>(sourceMap.subMap(from, to))` to get a
copy, not a live view.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                           |
| ---------------- | ---------------------------------------------- |
| 20 min           | LinkedHashMap ordering modes; TreeMap O(log n) |
| 40 min           | Add NavigableMap range ops; LRU implementation |
| 1 hour           | Add ConcurrentSkipListMap; live view semantics |

---

**[MID] Q1: How do you implement an LRU cache using `LinkedHashMap`?**
[HANDS-ON]

_Why they ask:_ Classic LRU implementation question.

_Likely follow-up:_ "Is it thread-safe?"

```java
public class LRUCache<K, V> extends LinkedHashMap<K, V> {
    private final int maxSize;

    public LRUCache(int maxSize) {
        super(maxSize, 0.75f, true); // accessOrder = true
        this.maxSize = maxSize;
    }

    @Override
    protected boolean removeEldestEntry(Map.Entry<K,V> eldest) {
        return size() > maxSize;
    }
}

LRUCache<String, User> cache = new LRUCache<>(1000);
cache.put("user1", user1);
cache.get("user1"); // moves user1 to tail (most recently used)
// When size > 1000, eldest (head = LRU) is evicted automatically
```

Key: `accessOrder=true` makes `get()` move the accessed entry to
the tail. Head = LRU. `removeEldestEntry()` returning true evicts
the head automatically after each `put()`.

Thread safety: NOT thread-safe. Wrap with `Collections.synchronizedMap()`
for thread safety. For high-concurrency production use, prefer Caffeine.

_What separates good from great:_ The `accessOrder=true` constructor
argument is the key differentiator (insertion order vs access order).

---

**[SENIOR] Q2: When would you choose `ConcurrentSkipListMap` over
`TreeMap`?** [TRADE-OFF]

_Why they ask:_ Tests concurrent sorted map knowledge.

_Likely follow-up:_ "What is a skip list?"

`TreeMap` is NOT thread-safe: concurrent reads while a write happens
can produce incorrect results or infinite loops in Java 7 (the same
circular list issue as HashMap).

`ConcurrentSkipListMap` is a concurrent sorted map using a lock-free
skip list data structure. Operations: O(log n) amortized, lock-free
reads.

Choose `ConcurrentSkipListMap` when:

- Multiple threads read/write a sorted map concurrently
- You need NavigableMap range operations (`floorKey`, `headMap`) in
  concurrent code
- You need `pollFirstEntry()` / `pollLastEntry()` for concurrent
  priority queue semantics

A skip list is a probabilistic data structure: a linked list with
multiple "express lanes" at increasing levels. The top level spans
the whole list; lower levels have more entries. `find(key)` starts
at the top, skips to the right level, then descends - O(log n) expected.

_What separates good from great:_ Knowing ConcurrentSkipListMap's
use for concurrent `pollFirstEntry()` (useful as a concurrent sorted
queue for scheduled tasks).

---

**[SENIOR] Q3: What does `TreeMap.subMap(from, to)` return, and
what are the pitfalls?** [CONCEPTUAL]

_Why they ask:_ Tests live view semantics of TreeMap.

_Likely follow-up:_ "What happens if you modify the returned map?"

`subMap(fromKey, toKey)` returns a **live view** of the portion of
the TreeMap with keys in [fromKey, toKey). It is NOT a copy.

Live view semantics:

- Reads from the view reflect current TreeMap state
- Writes to the view modify the original TreeMap
- `view.clear()` removes all entries with keys in range from TreeMap

Pitfalls:

1. `view.put(key, value)` where key is outside [from, to) throws
   `IllegalArgumentException`
2. Iterating the view while the source TreeMap is modified
   (outside the view range) is fine - but modifying within range
   concurrent with iteration causes `ConcurrentModificationException`
3. Callers of methods returning a subMap view don't know it's live -
   document it clearly

For a copy: `new TreeMap<>(treeMap.subMap(from, to))`.

_What separates good from great:_ The `IllegalArgumentException` on
out-of-range puts into the view, which surprises developers who
don't read the Javadoc.

---

---

# HashSet, LinkedHashSet, and TreeSet: Set Semantics

**Interview Weight:** medium - Companion to Map internals; tests
understanding of Set implementations.

---

### 🎯 Model Answer

**30 seconds:**

> `HashSet` is a HashMap with dummy values - keys are the set elements.
> O(1) add/contains/remove, no order. `LinkedHashSet` adds insertion
> order (backed by `LinkedHashMap`). `TreeSet` uses a TreeMap, giving
> sorted order and O(log n) operations. Choose by the ordering need:
> no order = `HashSet`, insertion order = `LinkedHashSet`, sorted =
> `TreeSet`.

**3 minutes (Senior):**

> `HashSet` implementation: literally `new HashMap<E, PRESENT>()` where
> `PRESENT` is a static `Object` singleton. `add(e)` calls `map.put(e, PRESENT)`.
> `contains(e)` calls `map.containsKey(e)`. All `hashCode`/`equals`
> rules from HashMap apply directly.
>
> `TreeSet` wraps a `TreeMap<E, PRESENT>` - the sorted map's keys are
> the set's elements. This gives TreeSet all the NavigableMap operations
> via `NavigableSet`: `first()`, `last()`, `floor(e)`, `ceiling(e)`,
> `headSet(e)`, `tailSet(e)`, `subSet(from, to)`.
>
> The key interview point on Set: deduplication is based entirely on
> `equals()` and `hashCode()` for HashSet/LinkedHashSet, but on
> `compareTo()`/`Comparator` for TreeSet. This means `HashSet` and
> `TreeSet` can disagree on what constitutes a "duplicate" if the
> `compareTo`/`equals` consistency contract is violated (e.g., BigDecimal
> "1.0" vs "1.00" is one entry in `TreeSet` but two entries in `HashSet`).

**Framework:** BACKING-STRUCTURE (HashMap / LinkedHashMap / TreeMap) +
ORDERING (none / insertion / sorted) + COMPLEXITY + DUPLICATE-DETECTION

_Adapting up:_ Discuss `EnumSet` (bit-vector backed, O(1) everything,
MUST use for enum element sets), and `CopyOnWriteArraySet` for
thread-safe set with iteration stability.

_Adapting down:_ HashSet for unique elements fast lookup. TreeSet for
sorted unique elements. Both prevent duplicates.

**Blank Mind Recovery:**

**(1) Restate:** "HashSet = HashMap keys. LinkedHashSet = LinkedHashMap
keys. TreeSet = TreeMap keys. Set = Map with no values - same internals,
same ordering behavior."

**(2) First principles:** "A Set needs: fast lookup, unique elements.
Reuse Map internals: keys are unique by definition. Sets are Maps
without values."

**(3) Bridge:** "Set implementations are Maps wearing a Halloween
costume. HashSet = HashMap, LinkedHashSet = LinkedHashMap, TreeSet =
TreeMap. Peel off the costume and all the performance characteristics
are the same."

---

### 📘 Concept Explanation

**Implementation relationship:**

```
HashSet         -> backed by HashMap<E, Object>
LinkedHashSet   -> backed by LinkedHashMap<E, Object>
TreeSet         -> backed by TreeMap<E, Object>

All share: static final Object PRESENT = new Object();
add(e):      map.put(e, PRESENT)  // returns true if new key
contains(e): map.containsKey(e)
remove(e):   map.remove(e)
```

**Complexity:**

| Operation         | HashSet   | LinkedHashSet   | TreeSet  |
| ----------------- | --------- | --------------- | -------- |
| `add(e)`          | O(1) avg  | O(1) avg        | O(log n) |
| `contains(e)`     | O(1) avg  | O(1) avg        | O(log n) |
| `remove(e)`       | O(1) avg  | O(1) avg        | O(log n) |
| `iterator.next()` | O(1)      | O(1) ordered    | O(log n) |
| Iteration order   | Undefined | Insertion order | Sorted   |
| Null element      | Yes (one) | Yes (one)       | No (NPE) |
| Thread-safe       | No        | No              | No       |

**TreeSet NavigableSet operations:**

```java
TreeSet<Integer> set = new TreeSet<>(Set.of(1,3,5,7,9));

set.first()        // 1
set.last()         // 9
set.floor(6)       // 5 (largest <= 6)
set.ceiling(6)     // 7 (smallest >= 6)
set.lower(5)       // 3 (largest < 5)
set.higher(5)      // 7 (smallest > 5)
set.headSet(5)     // [1, 3] (< 5, live view)
set.tailSet(5)     // [5, 7, 9] (>= 5, live view)
set.subSet(3, 8)   // [3, 5, 7] ([3, 8), live view)
set.pollFirst()    // removes and returns 1
set.pollLast()     // removes and returns 9
```

**EnumSet - specialized high-performance Set for enums:**

```java
enum Day { MON, TUE, WED, THU, FRI, SAT, SUN }

// EnumSet: backed by a single long (bit vector for <= 64 enum values)
Set<Day> weekdays = EnumSet.of(Day.MON, Day.TUE, Day.WED,
                               Day.THU, Day.FRI);
Set<Day> weekend  = EnumSet.complementOf(
                        (EnumSet<Day>) weekdays);

// All operations are O(1) bitwise: contains = single AND operation
// Iteration in enum declaration order
// Memory: 8 bytes for the entire set
```

---

### 💻 Code Example

#### HashSet deduplication requirements

```java
// BAD: Point without hashCode/equals - Set doesn't deduplicate
class BadPoint {
    int x, y;
    BadPoint(int x, int y) { this.x = x; this.y = y; }
}

Set<BadPoint> points = new HashSet<>();
points.add(new BadPoint(1, 2));
points.add(new BadPoint(1, 2)); // same logical point
System.out.println(points.size()); // 2! Not deduplicated

// GOOD: Record with automatic equals/hashCode
record GoodPoint(int x, int y) {}

Set<GoodPoint> points = new HashSet<>();
points.add(new GoodPoint(1, 2));
points.add(new GoodPoint(1, 2));
System.out.println(points.size()); // 1 - correctly deduplicated
```

> **Code walkthrough:** `BadPoint` uses `Object.hashCode()` (based on
> object identity) and `Object.equals()` (reference equality). Two
> `BadPoint(1,2)` objects have different identity, so they are stored
> in different buckets and considered unequal - both are added. `record`
> auto-generates `hashCode()` and `equals()` based on all components
> (`x` and `y`) - two `GoodPoint(1,2)` produce the same hash and compare
> equal, so HashSet correctly deduplicates them.

---

### 🎓 Answers by Seniority

**Junior:** HashSet for unique element storage with O(1) contains. TreeSet
for sorted unique elements. Both use equals/hashCode to define uniqueness.

**Mid-level:** HashSet is backed by HashMap (elements are keys, dummy
PRESENT is value). TreeSet is backed by TreeMap. TreeSet uniqueness is
determined by compareTo (or Comparator), not equals - can differ from
HashSet for inconsistently implemented classes.

**Senior:** `EnumSet` for enum elements is O(1) with a bit vector - always
prefer over `HashSet<MyEnum>`. `TreeSet`'s NavigableSet operations (`floor`,
`ceiling`, `headSet`) are the key differentiator from other Sets.
`LinkedHashSet` for ordered unique collection with O(1) lookup and
deterministic `toList()` output.

**Staff:** For Sets in concurrent code: `ConcurrentHashMap.newKeySet()`
creates a concurrent `Set<E>` backed by a `ConcurrentHashMap` - preferred
over `Collections.synchronizedSet()`. `CopyOnWriteArraySet` is the
thread-safe set for rare-write, frequent-read scenarios (observer lists).

---

### ⚠️ Common Misconceptions

| #   | Misconception                                                | Reality                                                                                                                                | Danger                                                                                    |
| --- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| 1   | `TreeSet` uses `equals()` for deduplication                  | `TreeSet` uses `compareTo()` (or Comparator). If `compareTo() == 0`, entries are considered duplicates regardless of `equals()` result | BigDecimal: TreeSet treats "1.0" and "1.00" as the same; HashSet treats them as different |
| 2   | `HashSet` guarantees any particular iteration order          | `HashSet` iteration order is undefined and can change on rehash or between JVM versions                                                | Code that passes tests locally breaks in production due to order dependency               |
| 3   | `Set.of()` and `new HashSet<>()` have the same null behavior | `Set.of()` throws NullPointerException for null elements. `new HashSet<>()` allows one null element                                    | NPE when migrating from HashSet to Set.of() or List.of()                                  |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Set not deduplicating custom objects**

Symptom: `Set.size()` grows when logically identical objects are added.

Root cause: Custom class missing `hashCode()`/`equals()` override
(using Object identity-based defaults).

Diagnostic: `new HashSet<>()` accepts any number of "equal" objects
without deduplication if `equals` is identity-based.

Fix: Override `hashCode()` and `equals()` consistently, or use Java
records for automatic generation.

---

**Failure 2 - `TreeSet`/`HashSet` inconsistency**

Symptom: An element "missing" in TreeSet but present in HashSet,
or vice versa.

Root cause: `compareTo()` is inconsistent with `equals()`. TreeSet
uses `compareTo` for deduplication; HashSet uses `equals`.

Fix: Ensure `compareTo() == 0` iff `equals() == true` for any class
used as a Set element.

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                                     |
| ---------------- | ------------------------------------------------------------------------ |
| 15 min           | HashSet as HashMap; TreeSet as TreeMap; ordering                         |
| 30 min           | Add NavigableSet operations; EnumSet                                     |
| 45 min           | Add compareTo vs equals for deduplication; ConcurrentHashMap.newKeySet() |

---

**[MID] Q1: How does `HashSet` prevent duplicates?** [CONCEPTUAL]

_Why they ask:_ Tests understanding of HashSet internals.

_Likely follow-up:_ "What happens when two objects have the same hashCode?"

`HashSet` is backed by `HashMap<E, Object>`. `add(element)` calls
`map.put(element, PRESENT)`. `HashMap.put()` uses `hashCode()` to
find the bucket and `equals()` to check if the key already exists.
If a key with `equals()` true already exists, the `put()` replaces
the value (PRESENT stays PRESENT - no visible change). The return
value of `put()` is the old value (PRESENT if existed); `HashSet.add()`
returns `false` if `put()` returned a non-null old value.

So deduplication contract: two objects are "the same" for HashSet
if and only if `a.hashCode() == b.hashCode()` AND `a.equals(b)`.

_What separates good from great:_ Knowing `HashSet.add()` returns
`false` if the element already exists (useful for checking
"was this a duplicate?").

---

**[SENIOR] Q2: When would you use `EnumSet` and what is its
performance advantage?** [TRADE-OFF]

_Why they ask:_ Tests knowledge of the most-overlooked high-performance
collection.

_Likely follow-up:_ "What is the constraint on EnumSet?"

`EnumSet` is the correct collection for sets of enum values:

- Implementation: a `long` bit vector (one bit per enum constant,
  up to 64 values). For enums with > 64 constants: `JumboEnumSet`
  uses a `long[]`.
- `contains(Day.MON)`: single bitwise AND operation - O(1) with
  essentially no overhead
- Iteration: visits constants in enum declaration order
- Memory: 8 bytes for the entire set

Compare to `HashSet<Day>`: each element is an Integer-like object,
each `contains()` computes hashCode, finds bucket, equals check.
Much higher overhead than a single AND.

Constraint: can only hold elements of a single enum type. Known at
compile time.

Use EnumSet for:

```java
// Permission sets
Set<Permission> granted = EnumSet.of(READ, WRITE);
// Feature flags
Set<Feature> enabled = EnumSet.allOf(Feature.class);
// Day-of-week processing
Set<DayOfWeek> workdays = EnumSet.range(
    DayOfWeek.MONDAY, DayOfWeek.FRIDAY);
```

_What separates good from great:_ Knowing `EnumSet` uses a `long`
bit vector (not a HashMap) and identifying the natural use cases.

---

**[SENIOR] Q3: How do you create a thread-safe Set in Java?**
[TRADE-OFF]

_Why they ask:_ Tests concurrent Set options.

_Likely follow-up:_ "When would you use each option?"

Three options:

1. `Collections.synchronizedSet(new HashSet<>())`: wraps with a
   mutex. Every operation synchronized. Iteration requires external
   `synchronized(set)` block. Simple but coarse-grained.

2. `ConcurrentHashMap.newKeySet()`: returns a `Set<K>` backed by
   ConcurrentHashMap. Lock-free reads, fine-grained writes. The
   preferred option for write-concurrent sets (metrics tracking,
   active session sets). Does NOT support null elements.

3. `CopyOnWriteArraySet`: backed by `CopyOnWriteArrayList`. Every
   write copies the array. Read iteration is always stable (snapshot).
   O(n) contains (linear scan, not hash). Best for small sets with
   rare writes and stable iteration (observer/listener sets).

Rule: `ConcurrentHashMap.newKeySet()` for most concurrent set needs.
`CopyOnWriteArraySet` for listener patterns. Avoid `synchronizedSet`
in new code.

_What separates good from great:_ Knowing `ConcurrentHashMap.newKeySet()`
(not commonly known) as the preferred concurrent Set, and the O(n)
linear scan limitation of `CopyOnWriteArraySet`.

---

---

# PriorityQueue and ArrayDeque: Queue and Deque Implementations

**Interview Weight:** medium - Tests knowledge of ordered and two-ended
queue implementations.

---

### 🎯 Model Answer

**30 seconds:**

> `PriorityQueue` is a min-heap: `poll()` always returns the smallest
> element (natural order or custom Comparator). Not FIFO. O(log n)
> add/poll, O(n) contains. `ArrayDeque` is a circular array supporting
> O(1) amortized add/remove at both ends - the preferred implementation
> for Queue, Stack, and Deque use cases. Neither is thread-safe.

**3 minutes (Senior):**

> `PriorityQueue` internal: a binary min-heap in an `Object[]`. The
> root (index 0) is always the minimum element. Children of node i
> are at 2i+1 and 2i+2. `add(e)` places e at the end and sifts up
> (swap with parent while smaller): O(log n). `poll()` removes the
> root, moves the last element to root, and sifts down: O(log n).
> `peek()` returns the root without removal: O(1). Critical: iteration
> of `PriorityQueue` is NOT in sorted order - only `poll()` guarantees
> removal in priority order.
>
> `ArrayDeque` internal: a circular array with `head` and `tail`
> indices. `addFirst()` moves `head` backwards (modulo capacity).
> `addLast()` moves `tail` forward. When full, doubles capacity with
> `System.arraycopy()`. All add/remove operations at either end are
> O(1) amortized. Preferred over `LinkedList` for queue/stack (cache-
> friendly array vs pointer chain), and over `Stack` (legacy, synchronized).

**Framework:** PRIORITYQUEUE (min-heap, priority order, log n) +
ARRAYDEQUE (circular array, O(1) both ends, preferred for queue/stack)

_Adapting up:_ Discuss `PriorityBlockingQueue` for concurrent priority
queues, and how to implement a max-heap with `Comparator.reverseOrder()`.

_Adapting down:_ PriorityQueue = sorted queue by value. ArrayDeque =
double-ended queue. Use ArrayDeque instead of LinkedList/Stack.

**Blank Mind Recovery:**

**(1) Restate:** "PriorityQueue = min-heap, poll() returns smallest.
ArrayDeque = circular array, fast add/remove at both ends, preferred
for queue and stack."

**(2) First principles:** "A priority queue needs: always give me the
most important item. A deque needs: add/remove from either end. Both
need O(1) or O(log n) operations. PriorityQueue = heap. ArrayDeque = circular array."

**(3) Bridge:** "PriorityQueue is a hospital emergency room: sickest
patient always gets seen first regardless of arrival. ArrayDeque is
a conveyor belt with access at both ends - add to one end, remove from
the other."

---

### 📘 Concept Explanation

**`PriorityQueue` - binary heap:**

```
Binary heap representation in Object[]:
  Array: [1, 3, 2, 7, 4, 5, 6]  (min-heap)
  Tree:        1
              / \
             3   2
            / \ / \
           7  4 5  6

  Parent of i: (i-1)/2
  Children of i: 2*i+1 (left), 2*i+2 (right)

Operations:
  add(e):   append to end, siftUp() - O(log n)
  poll():   remove root, move last to root, siftDown() - O(log n)
  peek():   return array[0] - O(1)
  contains(e): linear scan - O(n)

Iteration: NOT sorted order! The array stores heap order, not sorted.
Only poll() extracts in priority order.
```

**Max-heap with PriorityQueue:**

```java
// Min-heap (default): smallest element at top
PriorityQueue<Integer> minHeap = new PriorityQueue<>();

// Max-heap: largest element at top
PriorityQueue<Integer> maxHeap =
    new PriorityQueue<>(Comparator.reverseOrder());

// Custom priority: process tasks by priority then timestamp
PriorityQueue<Task> taskQueue = new PriorityQueue<>(
    Comparator.comparing(Task::getPriority).reversed()
              .thenComparing(Task::getCreatedAt));
```

**`ArrayDeque` - circular array:**

```
Circular array with head and tail indices:

Initial:  [_, _, _, _, _, _, _, _]  head=0, tail=0

addLast("A"):  [A, _, _, _, _, _, _, _]  head=0, tail=1
addLast("B"):  [A, B, _, _, _, _, _, _]  head=0, tail=2
addFirst("Z"): [A, B, _, _, _, _, _, Z]  head=7, tail=2
               (head wraps around - circular)

pollFirst():   returns Z, head=0
pollLast():    returns B, tail=1

When full: double capacity, copy elements in order
  O(1) amortized per operation (rare growth copies)
```

**ArrayDeque vs LinkedList vs Stack:**

| Use case       | Use                                           | Avoid                          |
| -------------- | --------------------------------------------- | ------------------------------ |
| Queue (FIFO)   | `ArrayDeque`                                  | `LinkedList`                   |
| Stack (LIFO)   | `ArrayDeque`                                  | `Stack` (legacy, synchronized) |
| Double-ended   | `ArrayDeque`                                  | `LinkedList`                   |
| Blocking queue | `ArrayBlockingQueue` or `LinkedBlockingQueue` | -                              |

---

### 💻 Code Example

#### PriorityQueue for task scheduling

```java
import java.util.*;

record Task(String name, int priority, long createdAt)
    implements Comparable<Task> {

    @Override
    public int compareTo(Task other) {
        // Higher priority number = more important
        int cmp = Integer.compare(
            other.priority, this.priority); // reverse for max
        if (cmp != 0) return cmp;
        // Tie-break by creation time (earlier = first)
        return Long.compare(this.createdAt, other.createdAt);
    }
}

public class TaskScheduler {
    private final PriorityQueue<Task> queue =
        new PriorityQueue<>(); // uses Task.compareTo

    public void submit(Task task) { queue.add(task); }

    public Task nextTask() {
        return queue.poll(); // O(log n) - highest priority first
    }

    public static void main(String[] args) {
        TaskScheduler scheduler = new TaskScheduler();
        scheduler.submit(
            new Task("Cleanup", 1, System.currentTimeMillis()));
        scheduler.submit(
            new Task("Deploy",  5, System.currentTimeMillis() + 1));
        scheduler.submit(
            new Task("Monitor", 3, System.currentTimeMillis() + 2));

        System.out.println(scheduler.nextTask().name()); // Deploy
        System.out.println(scheduler.nextTask().name()); // Monitor
        System.out.println(scheduler.nextTask().name()); // Cleanup
    }
}
```

> **Code walkthrough:** `Task` implements `Comparable` with higher
> priority value = more important (reverse order). `PriorityQueue`
> uses `compareTo` so the task with the highest priority number is
> always at the front. `poll()` extracts in priority order: Deploy
> (5), Monitor (3), Cleanup (1). Note: `queue.iterator()` would NOT
> give sorted order - only `poll()` guarantees priority order extraction.

---

#### ArrayDeque as both Stack and Queue

```java
public class DequeUsage {
    public static void main(String[] args) {

        // As a Queue (FIFO):
        Deque<String> queue = new ArrayDeque<>();
        queue.offerLast("task1");  // or: queue.add("task1")
        queue.offerLast("task2");
        queue.offerLast("task3");
        System.out.println(queue.pollFirst()); // task1 (FIFO)

        // As a Stack (LIFO):
        Deque<String> stack = new ArrayDeque<>();
        stack.push("frame1");  // = addFirst
        stack.push("frame2");
        stack.push("frame3");
        System.out.println(stack.pop()); // frame3 (LIFO)

        // Both-end usage:
        Deque<Integer> deque = new ArrayDeque<>();
        deque.addFirst(1);
        deque.addLast(2);
        deque.addFirst(0);
        // deque: [0, 1, 2]
        System.out.println(deque.peekFirst()); // 0
        System.out.println(deque.peekLast());  // 2
    }
}
```

> **Code walkthrough:** `ArrayDeque` serves both as a FIFO queue
> (`offerLast`/`pollFirst`) and LIFO stack (`push`=`addFirst`,
> `pop`=`removeFirst`). The `push`/`pop` methods are defined in `Deque`
> for stack semantics. All operations are O(1) amortized. `ArrayDeque`
> cannot contain `null` elements (null used internally as a sentinel
> for empty slots).

---

### 🎓 Answers by Seniority

**Junior:** `PriorityQueue` orders by natural order (smallest first by
default). `ArrayDeque` is a double-ended queue. Use `ArrayDeque` instead
of `Stack` or `LinkedList` for queue/stack operations.

**Mid-level:** `PriorityQueue` is a min-heap - `poll()` returns the
smallest element in O(log n). Use `Comparator.reverseOrder()` for a
max-heap. `ArrayDeque` is a circular array with O(1) amortized ops at
both ends - faster and more memory-efficient than `LinkedList`.
`PriorityQueue` iteration order is NOT sorted - only `poll()` gives
priority order.

**Senior:** `PriorityQueue.contains()` is O(n) (linear scan through
the heap array) - use with caution in hot paths. For concurrent priority
queues, use `PriorityBlockingQueue`. `ArrayDeque` is the Java docs'
recommended Stack and Queue implementation - it replaced both `Stack`
and `LinkedList` in the documentation.

**Staff:** For time-based priority (task scheduling at specific times),
use `DelayQueue`: elements implement `Delayed` interface; `poll()` returns
null until the element's delay expires. Appropriate for delayed task
execution without a thread-per-task scheduler.

---

### ⚠️ Common Misconceptions

| #   | Misconception                                     | Reality                                                                                                          | Danger                                                                 |
| --- | ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------- |
| 1   | `PriorityQueue` iteration is in sorted order      | Iteration traverses the heap array which is NOT sorted order. Only repeated `poll()` gives sorted order          | Incorrect output when iterating (not polling) a PriorityQueue          |
| 2   | `PriorityQueue` is a max-heap                     | Default is min-heap (smallest element at top). Use `Comparator.reverseOrder()` for max-heap                      | Accidentally getting smallest-first when largest-first is needed       |
| 3   | `ArrayDeque` can contain null                     | `ArrayDeque` uses null as an internal sentinel for empty slots. Adding null throws NullPointerException          | NPE when trying to add null to ArrayDeque                              |
| 4   | `Stack` class is recommended for stack operations | `Stack` extends `Vector` (synchronized, legacy). Java docs explicitly recommend `ArrayDeque` for stack use cases | Using synchronized Stack when single-threaded ArrayDeque is sufficient |

---

### 🚨 Failure Modes and Diagnosis

**Failure 1 - Iterating PriorityQueue expecting sorted order**

Symptom: Output from iterating PriorityQueue is not sorted.

Root cause: Iterator traverses internal heap array, not priority order.

Fix: Extract elements via `poll()` into a list, or drain with
`while (!queue.isEmpty()) result.add(queue.poll())`.

---

**Failure 2 - `PriorityQueue` with mutable priority field**

Symptom: `PriorityQueue` returns elements in wrong priority order.

Root cause: Element's priority field was modified after insertion.
The heap invariant is now violated. The queue does not rebalance on
field mutation.

Fix: PriorityQueue does not support priority changes after insertion.
Remove the element, update its priority, re-add it. Or use a
`TreeSet` with a custom comparator (supports removal by value).

---

### 🎯 Interview Deep-Dive

| Preparation time | Recommended approach                                          |
| ---------------- | ------------------------------------------------------------- |
| 20 min           | PriorityQueue heap structure; poll vs peek; ArrayDeque ops    |
| 40 min           | Add max-heap; PriorityQueue limitations (contains O(n))       |
| 1 hour           | Add DelayQueue; mutable priority bug; concurrent alternatives |

---

**[MID] Q1: What does `PriorityQueue.poll()` return when the queue
is empty?** [CONCEPTUAL]

_Why they ask:_ Tests Queue interface contract knowledge.

_Likely follow-up:_ "How does it differ from `remove()`?"

`poll()` returns `null` if the queue is empty (Queue interface
null-returning version).

`remove()` throws `NoSuchElementException` if the queue is empty
(Queue interface exception-throwing version).

For `PriorityQueue` specifically: `poll()` also invokes `siftDown()`
to restore the heap invariant after removing the root, returning the
minimum element.

Rule: prefer `poll()` when empty queue is a normal condition; use
`remove()` only when empty is an error.

_What separates good from great:_ Connecting to the Queue dual-method
pattern: `offer`/`add`, `poll`/`remove`, `peek`/`element` - each
pair is null-returning vs exception-throwing.

---

**[SENIOR] Q2: How would you find the k-th largest element in a
stream of numbers using `PriorityQueue`?** [HANDS-ON]

_Why they ask:_ Classic PriorityQueue algorithm.

_Likely follow-up:_ "What is the time and space complexity?"

Use a min-heap of size k:

```java
public static int findKthLargest(int[] nums, int k) {
    // Min-heap of size k
    PriorityQueue<Integer> minHeap = new PriorityQueue<>();

    for (int num : nums) {
        minHeap.add(num);
        if (minHeap.size() > k) {
            minHeap.poll(); // remove smallest - keep k largest
        }
    }
    // heap contains k largest; min of those = k-th largest
    return minHeap.peek();
}
```

Logic: the heap always holds the k largest elements seen so far.
When a new element is smaller than the heap's minimum (k-th largest
so far), it's discarded. When larger, it enters and the new minimum
is discarded. After all elements: the heap minimum is the k-th largest.

Complexity: O(n log k) time - each of n elements does at most O(log k)
heap operations. O(k) space.

_What separates good from great:_ The O(n log k) complexity analysis -
better than sorting all n elements O(n log n) when k << n.

---

**[SENIOR] Q3: DEBUGGING: A task queue is not processing tasks in
the expected order. The queue uses `PriorityQueue`. Diagnose.**
[DEBUGGING]

_Why they ask:_ Tests practical PriorityQueue debugging.

_Likely follow-up:_ "What if two tasks have equal priority?"

Three common causes:

1. **Tasks added to the queue after their priority fields were set,
   but priority later changed**: PriorityQueue does NOT rebalance
   after insertion. If `task.setPriority(newValue)` is called after
   `queue.add(task)`, the ordering is wrong.

2. **`compareTo`/`Comparator` implementation returning 0 for
   non-equal priorities**: ties are broken by heap order (not
   FIFO). If you need FIFO tie-breaking, include a sequence
   number: `Comparator.comparing(Task::getPriority).thenComparing(Task::getSeq)`.

3. **Using `queue.iterator()` instead of `queue.poll()`**: iterator
   returns heap array order, NOT priority order.

Diagnosis: print `queue.peek()` before each `poll()` to verify the
returned element is indeed the heap minimum. Add `compareTo` logging
to trace priority comparisons.

_What separates good from great:_ Identifying case 1 (mutable priority
after insertion) as the most insidious - it silently corrupts the
heap without any exception.

---

**[STAFF] Q4: ARCHITECTURE: Design a task scheduler that supports
task priority changes after submission.** [ARCHITECTURE]

_Why they ask:_ Tests that candidates know PriorityQueue limitations.

_Likely follow-up:_ "What is the trade-off of your approach?"

`PriorityQueue` does not support priority change after insertion -
no `heapify()` method. Options:

**Option 1: Remove + Re-add** (simple, O(n) remove):

```java
queue.remove(task);     // O(n) linear scan
task.setPriority(newP); // modify
queue.add(task);        // O(log n) re-add
```

Works for infrequent priority changes. `remove()` is O(n) -
acceptable if changes are rare.

**Option 2: Lazy deletion** (efficient for frequent changes):

```java
Set<Task> cancelled = new HashSet<>();

// To change priority:
cancelled.add(task);                 // mark old task invalid
Task newTask = task.withPriority(p); // create new task record
queue.add(newTask);

// When consuming:
while (!queue.isEmpty()) {
    Task t = queue.poll();
    if (!cancelled.contains(t)) { process(t); break; }
    // skip cancelled entries
}
```

The cancelled set grows; periodically call `queue.removeIf(cancelled::contains)` to trim.

**Option 3: `TreeSet` with unique keys** (O(log n) update):

```java
// TreeSet supports remove by value in O(log n)
TreeSet<Task> queue = new TreeSet<>(comparator);
queue.remove(task);     // O(log n) - no linear scan
task.setPriority(newP);
queue.add(task);        // O(log n)
// poll: queue.pollFirst()
```

Requires tasks to have consistent compareTo/equals.

_What separates good from great:_ Proposing lazy deletion as the
most performant option for frequent changes, and TreeSet as the
O(log n) remove alternative.
