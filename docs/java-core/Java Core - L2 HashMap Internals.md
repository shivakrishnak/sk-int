---
layout: default
title: "Java Core - L2 HashMap Internals"
parent: "Java Core"
grand_parent: "SK Interview"
nav_order: 5
permalink: /java-core/l2-hashmap-internals/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Core - L2 HashMap Internals](#java-core---l2-hashmap-internals) | medium |

---

# Java Core - L2 HashMap Internals

## HashMap Internals and Hash Collision

---

### 🎯 Model Answer

**30 seconds:**
> `HashMap` stores entries in a hash table - an array of "buckets".
> `put(k,v)` computes `k.hashCode()`, spreads it with a secondary hash,
> and selects a bucket: `bucket = hash & (capacity - 1)`. If two keys
> land in the same bucket (collision), they form a linked list (Java 7)
> or a red-black tree when the list exceeds 8 nodes (Java 8). Average
> O(1) for `get/put`, worst case O(log n) with treeification (Java 8)
> vs O(n) without. The load factor (default 0.75) controls when the
> table resizes - at 75% fill, capacity doubles and all entries rehash.

**3 minutes (Senior):**
> Java 8's treeification (JEP 180) was motivated by hash DoS attacks:
> an adversary knowing the hash function could craft keys that all land
> in one bucket, degrading HashMap to O(n) per lookup. With treeification,
> the worst case becomes O(log n). Treeification requires keys to be
> `Comparable` - if not, the tree falls back to identity hash comparison.
>
> Performance factors: initial capacity choice matters. Default 16.
> With load factor 0.75, first resize at 12 entries. For 1000 entries:
> 7 resizes. Pre-size with `new HashMap<>(1000 / 0.75 + 1)` = 1334 to
> avoid any resize. Resizing is O(n) and rehashes every entry.
>
> HashMap is not thread-safe. Multiple threads modifying concurrently:
> lost updates, infinite loops in Java 6 (fixed in Java 8), data
> corruption. Use `ConcurrentHashMap` for concurrent access.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Discuss the HashMap secondary hash function (`(h = key.hashCode()) ^ (h >>> 16)` - XOR of high and low bits to spread entropy), the power-of-2 table size optimization (allows bitwise AND instead of modulo), and `ConcurrentHashMap`'s segment/stripe design evolution from Java 7 (16 segments) to Java 8 (CAS on individual nodes).

**Blank Mind Recovery:**

**(1) Restate:** "HashMap internals - let me cover the bucket array
structure, hash computation, collision handling, treeification in
Java 8, and load factor/resizing."

**(2) First principles:** "From first principles: we want O(1) key
lookup. An array gives O(1) by index, but we need to map arbitrary
keys to array indices. That's the hash function's job. Collisions
are inevitable (pigeonhole principle), so we need a strategy to
handle them."

**(3) Bridge:** "HashMap is like a parking garage with numbered slots.
The license plate (key) is hashed to a slot number. If the slot is
taken (collision), you chain cars behind it (linked list/tree). When
the garage is 75% full, you build a bigger garage and move everyone."

---

### 📘 Concept Explanation

**Internal structure (Java 8):**
```
HashMap state:
  Node<K,V>[] table     // the bucket array (size = power of 2)
  int size              // number of key-value pairs
  int threshold         // size * loadFactor = resize trigger
  float loadFactor      // default 0.75
  int modCount          // structural modification count (for CME)

Node<K,V>:
  int hash              // cached hashCode
  K key
  V value
  Node<K,V> next        // linked list chain (or TreeNode for trees)

TreeNode<K,V> extends Node<K,V>:
  // Red-Black tree node for buckets with > 8 entries
  TreeNode parent, left, right, prev
  boolean red
```

> **Code walkthrough:** This L2 HashMap Internals example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**put(k, v) algorithm:**
```
1. if table is null: initialize table to size 16

2. hash = hash(key.hashCode())
   // spread: h ^ (h >>> 16)
   // ensures upper bits affect lower bits (reduces collisions)

3. i = (table.length - 1) & hash
   // bucket index: bitwise AND (fast modulo for power-of-2)

4. if table[i] == null:
   table[i] = new Node(hash, key, value, null)   // empty bucket

5. else (bucket occupied):
   if (table[i].hash == hash && table[i].key.equals(key)):
       replace value   // exact same key

   else if table[i] is TreeNode:
       tree.putTreeVal(...)   // insert into tree

   else (linked list):
       walk list; if key found, replace; if end reached, append Node
       if list length >= TREEIFY_THRESHOLD (8):
           treeifyBin(table, i)   // convert to red-black tree

6. if ++size > threshold:
   resize()   // double capacity, rehash all entries
```

> **Code walkthrough:** This L2 HashMap Internals example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** The pre-sizing example shows the correct formulaice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> to avoid any resize operations. The hash DoS attack example explains
> why Java 8 added treeification. The thread-safety failure shows why
> concurrent HashMap access without synchronization corrupts state in
> Java 8+ (deadlock / lost updates; pre-Java 8 could cause infinite loops
> during concurrent resize).

```java
// PRE-SIZING: avoid resize with known entry count
int expectedEntries = 1000;
// Correct: initialCapacity = entries / loadFactor + 1
// (ensures capacity * loadFactor > entries, no resize needed)
Map<String, User> users = new HashMap<>(
    (int)(expectedEntries / 0.75) + 1  // = 1335
);

// HASH COLLISION: all keys in one bucket - bad performance
// (Before Java 8: O(n) per lookup; Java 8+: O(log n) after tree)
Map<String, String> map = new HashMap<>();
// All these hash to bucket 0 if hash function is broken:
for (int i = 0; i < 100; i++) {
    map.put("key" + i, "value" + i);  // normal case: ~1 per bucket
}

// THREAD-SAFETY FAILURE:
Map<String, Integer> counter = new HashMap<>(); // NOT thread-safe
// Multiple threads calling counter.put() concurrently:
// - Lost updates (two threads write same bucket simultaneously)
// - ConcurrentModificationException during concurrent resize

// FIX: use ConcurrentHashMap:
Map<String, Integer> safeCounter = new ConcurrentHashMap<>();
safeCounter.computeIfAbsent("key", k -> 0);
safeCounter.compute("key", (k, v) -> v == null ? 1 : v + 1); // atomic

// Or for counting: ConcurrentHashMap.merge():
safeCounter.merge("key", 1, Integer::sum); // atomic add
```

> **Code walkthrough:** `computeIfAbsent`, `compute`, and `merge` areice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> atomic operations in `ConcurrentHashMap` - they execute atomically
> on the affected bucket without external synchronization. `merge("key",
> 1, Integer::sum)` atomically sets the value to 1 if absent, or
> computes `existingValue + 1` if present. This is the idiomatic
> concurrent counter pattern. `ConcurrentHashMap` achieves this by
> using synchronized blocks only on the affected bucket, not the entire
> map.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> HashMap uses a hash table: hash codes map keys to bucket indices.
> Collisions are handled by linked lists (Java 7) or trees for long
> chains (Java 8). Default capacity 16, load factor 0.75. The table
> doubles when 75% full. Use `equals()` and `hashCode()` correctly or
> keys can't be found. Not thread-safe - use `ConcurrentHashMap` for
> concurrent access.

---

**Senior / Staff (5+ years):**
> Java 8 treeification (bucket list -> red-black tree at 8 nodes) was
> a security fix for hash DoS attacks, improving worst-case from O(n)
> to O(log n). The secondary hash (`h ^ h >>> 16`) spreads entropy from
> upper bits into lower bits - critical because bucket selection uses
> only the lower bits (`hash & (capacity-1)`). Poor hashCode() (e.g.,
> all low bits the same) concentrates keys in few buckets. For
> performance-critical maps: consider Guava's `ImmutableMap` (array-
> backed, no boxing), Eclipse Collections `UnifiedMap` (lower memory),
> or JDK's `EnumMap` for enum keys (array, O(1) everything).

---

### ⚠️ Common Misconceptions

**Misconception 1: "HashMap is O(1) always."**
Average O(1) with good hash distribution. Worst case:
O(n) Java 7 (all keys in one bucket), O(log n) Java 8+
(treeification). The load factor and quality of hashCode
both affect actual performance.

**Misconception 2: "Collections.synchronizedMap(map) is as good as
ConcurrentHashMap."**
`synchronizedMap` wraps the map in a monitor lock - only one thread
can access it at a time. `ConcurrentHashMap` uses bucket-level
synchronization (for writes) and lock-free reads - much higher
concurrency for read-heavy workloads.

---

### 🚨 Failure Modes and Diagnosis

**Failure: HashMap with all-zero hashCode causes O(n) or O(log n) degradation.**
```java
// Bad hashCode: always returns 0
class BadKey {
    int id;
    @Override public int hashCode() { return 0; } // terrible!
    @Override public boolean equals(Object o) { ... }
}
Map<BadKey, String> map = new HashMap<>();
// All entries land in bucket 0: one bucket with n entries
// get() walks the whole bucket: O(log n) with treeification
```
> **Code walkthrough:** BAD pattern: This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **WHAT BREAKS: document thread-safety guarantees on every shared mutable class.**

Diagnosis: `jstack` thread dump showing threads spending time in
`HashMap.getEntry()`; heap dump showing one bucket with thousands
of nodes.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| HashMap put algorithm | 2-3 minutes |
| Collision handling | 2 minutes |
| Java 8 treeification | 2 minutes |
| Load factor and resizing | 2 minutes |
| HashMap vs ConcurrentHashMap | 2-3 minutes |
| HashMap thread-safety failures | 2 minutes |
| LinkedHashMap use cases | 2 minutes |
| EnumMap advantages | 90 seconds |
| Pre-sizing formula | 90 seconds |
| HashMap vs Hashtable | 60 seconds |
| hashCode null key | 60 seconds |
| HashMap internal hash function | 2 minutes |

---

**Q1 (HashMap put algorithm): Walk through what happens when you call
`map.put("key", "value")` on a HashMap.**

A:
1. `key.hashCode()` is called. For String, this is a polynomial rolling
   hash of the characters.

2. A secondary hash is applied: `h ^ (h >>> 16)`. This XORs the high
   16 bits of the hash code into the low 16 bits. Purpose: the bucket
   index uses only `log2(capacity)` bits. For a 16-bucket table: only
   the lowest 4 bits matter. XOR spreads entropy from all 32 bits.

3. Bucket index: `i = (capacity - 1) & finalHash`. For capacity=16:
   `i = 15 & hash = hash % 16`.

4. Examine `table[i]`:
   - null: new `Node(hash, key, value, null)` placed here
   - `Node` with equal key (hash match + equals): update value
   - `Node` with different key (collision): walk the chain

5. At end of chain: add new `Node`. If chain length >= 8:
   convert to red-black tree (`treeifyBin`).

6. `size++`. If `size > threshold (= capacity * loadFactor)`:
   call `resize()` - double capacity, rehash all entries.

*What separates good from great:* The resize is the expensive operation
to avoid. Each resize: allocates new array, walks every entry, recomputes
bucket for each entry (but cheats: since new capacity is 2x old, the
new bucket is either same index or `old_index + old_capacity` - no full
hash recomputation needed). Amortized cost of n puts: O(n).

---

**Q2 (Collision handling): How does HashMap handle key collisions?**

A: Collision = two keys have the same bucket index (same `hash &
(capacity-1)`). Note: this doesn't require same hash code; different
hash codes can map to the same bucket.

**Chaining strategy (HashMap's approach):**
Multiple entries in the same bucket form a chain. Java 7: singly-linked
list. Java 8: singly-linked list until 8 nodes, then red-black tree.

```
Bucket 3: [entry(k1,v1)] -> [entry(k2,v2)] -> null  (linked list)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**get() on a collision bucket:**
1. Compute bucket index
2. Walk the chain: check `hash == e.hash && (key == e.key || key.equals(e.key))`
3. Return value if found, null otherwise

**Why check hash first?**
`hash == e.hash` is a cheap int comparison. `equals()` may be expensive
(String compares characters). Short-circuit: most entries in a bucket
won't have matching hash codes even if their bucket indices match.

*What separates good from great:* The quality of hash distribution is
the most important performance factor. A perfect hash puts exactly one
entry per bucket: zero collisions, pure O(1). A pathological hash
puts all entries in one bucket: O(log n) in Java 8. Real-world: with
default load factor 0.75 and good hashCode, average bucket occupancy
is 0.75 entries (most buckets empty, few have 1 entry, very rare to
have 2+). Poisson distribution predicts ~2% of buckets will have 2+
entries in this scenario.

---

**Q3 (Java 8 treeification): Why did Java 8 add tree buckets to HashMap?**

A: Java 8 (JEP 180: "Handle Frequent HashMap Collisions with Balanced
Trees") added treeification for two reasons:

**1. Algorithmic complexity improvement:**
Before: O(n) worst-case per lookup (one bucket with n entries)
After: O(log n) worst-case per lookup (treeified bucket)

**2. Hash DoS attack mitigation:**
An adversary who knows the HashMap hash function (it's in the JDK source)
can craft keys that all hash to the same bucket. Sending 10,000 crafted
keys through a REST API can degrade `HashMap.get()` to O(n):
10,000 operations of O(10,000) = 100,000,000 operations.
Java 8 treeification reduces this to O(10,000 * log(10,000)) ≈ 130,000 ops.

**Treeification details:**
- Threshold: 8 entries in a bucket triggers treeification
- Untreeify threshold: 6 entries (after removals, tree -> list)
- Minimum table size for treeification: 64 (small tables may resize first)
- Requires keys to be `Comparable` for tree ordering; falls back to
  identity-based ordering if keys don't implement `Comparable`

*What separates good from great:* For String keys, Java 8 also introduced
a "hash randomization" concept (randomized hash seed) in some JVM
implementations to prevent reproducible hash DoS. However, `HashMap`
itself uses a deterministic hash in the standard JDK. The randomization
is in web frameworks that handle untrusted input (e.g., Tomcat uses
`useBodyEncodingForURI` and request parameter limiting). Defense in depth:
the treeification handles the performance degradation; input size limits
handle the attack surface.

---

**Q4 (Load factor and resizing): What is the load factor and how does
it affect HashMap performance?**

A: Load factor = `size / capacity`. Default: 0.75. Resize threshold:
when `size > capacity * loadFactor`.

**Effects of load factor:**
- Lower load factor (e.g., 0.5): fewer collisions (more empty buckets),
  faster lookups, but wastes memory (half the buckets empty on average)
- Higher load factor (e.g., 0.9): more collisions, slower lookups,
  but less memory waste

**Resize mechanics:**
```java
void resize() {
    int newCapacity = oldCapacity * 2;
    Node<K,V>[] newTable = new Node[newCapacity];
    // Rehash all entries:
    for (each entry in table) {
        int newBucket = (newCapacity - 1) & entry.hash;
        // Move to newTable
    }
    table = newTable;
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

**Java 8 resize optimization:**
New bucket index = old index OR (old index + oldCapacity).
Since capacity doubles (power of 2), only 1 new bit is added to the
bucket calculation. No need to recompute hash:
```plaintext
old capacity = 16 (0001 0000)
new capacity = 32 (0010 0000)
new bit = hash & oldCapacity (the bit that changed)
if new bit == 0: new index = old index
if new bit == 1: new index = old index + oldCapacity
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The default 0.75 load factor is a
good empirical compromise. For read-heavy, memory-available caches:
use 0.5 for fewer collisions. For memory-constrained environments with
predictable data: use 0.9. The initial capacity choice is more impactful
than load factor tuning. Formula: `initialCapacity = n / loadFactor + 1`
where n = expected entries. For 10K entries with 0.75 load factor:
`10000 / 0.75 + 1 = 13335` initial capacity.

---

**Q5 (HashMap vs ConcurrentHashMap): Compare HashMap and
ConcurrentHashMap for concurrent use.**

A:

| Aspect | HashMap | ConcurrentHashMap |
|---|---|---|
| Thread safety | No | Yes |
| Null keys | One allowed | Not allowed |
| Null values | Allowed | Not allowed |
| Read performance | Fastest | Near-HashMap (no lock for reads) |
| Write performance | Fastest | Good (bucket-level lock) |
| Atomic operations | No | computeIfAbsent, merge, compute |
| Size accuracy | Exact | Approximate (size()) |
| Iteration | Fail-fast | Weakly consistent |

**ConcurrentHashMap Java 8 internals:**
- Reads: lock-free (volatile access)
- Writes: `synchronized (bucket)` - only locks the specific bucket node
- Atomic CAS (Compare-And-Swap) for bucket insertion
- No global lock: 16+ threads can write to different buckets simultaneously

**Why not `Collections.synchronizedMap()`?**
```java
// synchronizedMap: global lock, one thread at a time:
Map<K,V> syncMap = Collections.synchronizedMap(new HashMap<>());
syncMap.put(k1, v1); // locks entire map
syncMap.get(k2);     // also locks entire map - no read concurrency

// ConcurrentHashMap: fine-grained, parallel reads:
ConcurrentHashMap<K,V> chm = new ConcurrentHashMap<>();
chm.put(k1, v1); // locks bucket[i]
chm.get(k2);     // no lock (volatile read) - parallel with puts!
```

> **Code walkthrough:** This Unknown example demonstrates mutex locking using concurrency primitive. **KEY MECHANISM:** the JVM acquires the intrinsic lock on the object monitor before entering the block. **WHY IT MATTERS:** a thread holding the lock blocks all other threads - a bottleneck at scale. **TAKEAWAY: prefer ReentrantLock or ConcurrentHashMap over synchronized for hot paths.**

*What separates good from great:* ConcurrentHashMap's `size()` method
returns an approximate count (uses the internal `CounterCell` accumulator,
similar to `LongAdder`). For exact counting in concurrent systems: maintain
a separate `AtomicLong` counter. Also: ConcurrentHashMap doesn't support
null keys or values - this is intentional. Null in a regular HashMap
means "key absent" (return null from get). In ConcurrentHashMap, null
could mean "key absent" OR "value is null" - ambiguous under concurrency.
Eliminating null forces explicit absence representation.

---

**Q6 (HashMap thread-safety failures): What failures can occur when
multiple threads use HashMap concurrently?**

A:

**1. Lost updates:**
```
Thread A: get("counter") -> 5
Thread B: get("counter") -> 5
Thread A: put("counter", 6)   // +1
Thread B: put("counter", 6)   // +1, overwrites A's write
// Expected: 7. Actual: 6. Lost update.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**2. ConcurrentModificationException:**
Thread A iterates; Thread B puts (changes modCount).
Thread A's iterator detects modCount change -> CME.

**3. Infinite loop (Java 6 and earlier - fixed in Java 8):**
Pre-Java 8 HashMap resize used head insertion for the new chain.
Two concurrent threads doing resize could create a circular linked list.
Any subsequent get() on an entry in that bucket enters an infinite loop.
(Java 8 uses tail insertion and preserves order, fixing this.)

**4. Partial initialization:**
Partially constructed entries visible due to memory ordering.
Without volatile or synchronization: another thread may see a node
with null key or hash = 0 during construction.

*What separates good from great:* The infinite loop bug (pre-Java 8) was
a production catastrophe for teams that discovered HashMap "isn't thread
safe in theory" was actually "HashMap can hang your server" in practice.
The symptoms: CPU at 100%, thread dump shows all threads stuck in
`HashMap.get()`. The fix (Java 8 tail insertion) was a silent correctness
improvement alongside the tree buckets. Even with Java 8, HashMap is not
safe for concurrent access - the lost update and CME issues remain.

---

**Q7 (LinkedHashMap use cases): When would you use LinkedHashMap?**

A: `LinkedHashMap` extends `HashMap` by maintaining a doubly-linked list
through all entries in INSERTION order (or access order if specified).

**Use case 1: Preserve insertion order**
```java
Map<String, Integer> config = new LinkedHashMap<>();
config.put("host", 0);
config.put("port", 1);
config.put("timeout", 2);
// Iteration order matches insertion: host, port, timeout
// HashMap would give random order
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using SQL. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**Use case 2: LRU Cache skeleton**
```java
// access-order LinkedHashMap: most-recently-accessed last
Map<String, Object> lruCache = new LinkedHashMap<>(16, 0.75f, true) {
    private static final int MAX_SIZE = 100;
    @Override
    protected boolean removeEldestEntry(Map.Entry<String,Object> eldest) {
        return size() > MAX_SIZE; // evict when full
    }
};
// get() moves entry to end (most recent); removeEldestEntry evicts head
```

> **Code walkthrough:** This Unknown example demonstrates exception handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

**Use case 3: JSON serialization order**
JSON object properties have no required order, but tools
(logs, diffs) are easier to read with consistent field order.
`LinkedHashMap` for DTO-to-JSON conversion preserves field order.

*What separates good from great:* The LRU cache use case is common in
interviews. `LinkedHashMap(capacity, loadFactor, true)` (access-order
mode) reorders entries on every `get()` - the accessed entry moves to
the tail. Override `removeEldestEntry()` to evict when size exceeds
the limit. The complexity: `get/put/remove` are still O(1) but with
pointer maintenance for the linked list. Caffeine cache (modern Java
caching library) is a production-grade LRU/LFU/W-TinyLFU implementation
with better concurrency than `LinkedHashMap`.

---

**Q8 (EnumMap advantages): What are the advantages of EnumMap over HashMap
for enum keys?**

A: `EnumMap` uses a plain array indexed by the enum ordinal. No hashing,
no collision, no boxing.


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
enum Day { MON, TUE, WED, THU, FRI, SAT, SUN }

// GOOD: EnumMap for enum keys
Map<Day, String> schedule = new EnumMap<>(Day.class);
schedule.put(Day.MON, "Sprint planning");
schedule.put(Day.FRI, "Retrospective");

// Performance comparison:
// HashMap<Day, V>: hash Day -> box if needed -> find bucket
// EnumMap<Day, V>: array[Day.ordinal()] -> O(1), no boxing, no hashing

// Size: 7 (Days.values().length) array slots vs HashMap's 16+ buckets
// Memory: compact, no Node objects, no pointer chains
// Iteration: always in enum declaration order (predictable)
```

> **Code walkthrough:** GOOD pattern: This Unknown example demonstrates Java API usage using enum. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**When to use EnumMap:**
- Map keys are always from a known enum
- Performance-critical code with enum keys
- Need predictable iteration order (enum declaration order)
- Particularly useful for: state machines (state -> handler), case
  dispatch (status -> action), configuration by environment

*What separates good from great:* `EnumMap` is the correct choice
whenever your keys are an enum - it's not a micro-optimization; it's
semantically more correct. The map size is bounded by the enum constants
(no growth). The ordinal-based storage is cache-line friendly.
`EnumSet` is the corresponding `Set` implementation for enum values
(uses a bitfield internally for extremely compact storage and O(1) ops).

---

**Q9 (Pre-sizing formula): What's the formula to pre-size a HashMap
to avoid resizing?**

A:
```java
// Formula: initialCapacity = (expectedEntries / loadFactor) + 1
// This ensures capacity * loadFactor >= expectedEntries

int expected = 1000;
float loadFactor = 0.75f;
int initialCapacity = (int)(expected / loadFactor) + 1; // 1335

Map<String, User> map = new HashMap<>(initialCapacity);
// HashMap rounds up to next power of 2: 2048
// With 1000 entries: 1000 < 2048 * 0.75 = 1536 -> no resize!

// Alternative: let Guava compute it
Map<String, User> guavaMap = Maps.newHashMapWithExpectedSize(1000);
// Guava uses (expected * 4 / 3) + 1 = same formula
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**Why round up to power of 2?**
HashMap requires capacity to be a power of 2 for the `(n-1) & hash`
bitwise bucket calculation. It automatically rounds up to the next
power of 2.

*What separates good from great:* Pre-sizing matters for batch operations:
loading 100K records from a database into a HashMap. Without pre-sizing:
8+ resize/rehash operations during loading, temporary 2x memory usage
during each resize. With pre-sizing: single allocation, zero resizes.
The temporary 2x memory during resize can cause OOM in memory-constrained
environments. Profile-driven pre-sizing (from initial `COUNT(*)` query)
is a standard pattern in high-throughput data processing.

---

**Q10 (HashMap vs Hashtable): When would you use Hashtable instead of HashMap?**

A: Almost never. `Hashtable` is legacy (Java 1.0) and obsolete.

| Aspect | HashMap | Hashtable |
|---|---|---|
| Thread safety | No | Yes (synchronized) |
| Null keys | One allowed | Not allowed |
| Null values | Allowed | Not allowed |
| Iteration | Iterator (fail-fast) | Enumeration (not fail-fast) |
| Performance | Faster (no sync) | Slower (global sync) |
| Inheritance | AbstractMap | Dictionary (legacy) |
| Modern use | Yes | No - use ConcurrentHashMap |

`Hashtable`'s synchronization is coarse-grained (entire table locked).
`ConcurrentHashMap` is the modern thread-safe replacement with much
better concurrency.

*What separates good from great:* `Hashtable` exists only for backward
compatibility. You might encounter it in legacy code (pre-Java 5).
When modernizing: replace `Hashtable` with `ConcurrentHashMap` (for
concurrent access) or `HashMap` (for single-threaded). The same applies
to `Vector` -> `ArrayList` (or `CopyOnWriteArrayList`) and `Stack` ->
`ArrayDeque`.

---

**Q11 (hashCode null key): How does HashMap handle null keys?**

A: HashMap allows exactly one null key, stored at bucket index 0.

```java
map.put(null, "value");  // stored at index 0
map.get(null);           // returns "value"
map.containsKey(null);   // true
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Implementation:
```java
// HashMap special-cases null key:
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
// null -> hash = 0 -> bucket[0]
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**ConcurrentHashMap does NOT allow null keys or null values.**
Reason: in concurrent access, `map.get(key) == null` is ambiguous:
did get return null because the key is absent, or because the value
is null? With non-concurrent HashMap, you can `containsKey()` to
distinguish. Under concurrent access, the state may change between
`get()` and `containsKey()`.

*What separates good from great:* Using null as a map key is a code
smell. It typically means "absent" key - but the map already has the
concept of absent keys. If null key means "unknown", use an `Optional`
or a sentinel value instead: `Map.getOrDefault(key, DEFAULT)`. Null
values similarly: if null value means "deleted" or "absent", use
`Optional<V>` as the value type or remove the entry instead.

---

**Q12 (HashMap internal hash function): Why does HashMap use
`h ^ (h >>> 16)` as a secondary hash?**

A: The secondary hash (also called hash "spreading"):

```java
static final int hash(Object key) {
    int h;
    return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
}
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

**Why needed:** Bucket index uses only the lower bits of the hash:
`(capacity - 1) & hash`. For a 16-bucket table: only 4 bits matter.
For a 256-bucket table: only 8 bits matter. If the hash code has poor
entropy in its low bits (common for integer keys, class-generated hash
codes), many entries cluster in few buckets.

**XOR with upper bits:**
`h ^ (h >>> 16)` mixes the high 16 bits of `h` into the low 16 bits.
Now the low bits contain entropy from the entire 32-bit hash code.
This reduces clustering without additional computation.

**Example:**
```
key.hashCode() = 0xFFFF_0001
h >>> 16 = 0x0000_FFFF
h ^ (h >>> 16) = 0xFFFF_FFFE
// Low 4 bits: 0001 -> 1110 (changed by upper bits)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* This secondary hash is a practical
engineering compromise. A full cryptographic hash would give near-perfect
distribution but be much slower. The XOR spreading is O(1), requires
two CPU instructions, and significantly reduces clustering for common
hashCode implementations (integer keys, String hash codes). This is
the kind of detail that shows you've read the HashMap source code -
a strong signal in senior-level interviews.

---

### ⚖️ Comparison Table

| Map Type| Order| Null key| Thread-safe| Get O| Add O| Use When|
|---|---------|--------|------------|--------|--------|------------------------|
| HashMap| None| One| No| O(1) avg| O(1) avg| General use|
| LinkedHashMap| Insert/access| One| No| O(1) avg| O(1) avg| LRU, ordered output
| TreeMap| Sorted| No| No| O(log n)| O(log n)| Sorted key range queries|
| EnumMap| Enum order| No| No| O(1)| O(1)| Enum key maps|
| ConcurrentHashMap| None| No| Yes| O(1) avg| O(1) avg| Concurrent access|
| Hashtable| None| No| Yes (global)| O(1) avg| O(1) avg| Legacy only|

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: HashMap bucket structure described adequately in Concept Explanation)*

---

---

## Comparable and Comparator

---

### 🎯 Model Answer

**30 seconds:**
> `Comparable<T>` provides the NATURAL ordering of a class: implemented
> inside the class (`compareTo()`) to say "objects of this type are
> naturally ordered this way." `Comparator<T>` is an EXTERNAL ordering:
> a separate object defining a specific comparison strategy. Use
> `Comparable` for the primary, natural order (String alphabetical,
> Integer numeric). Use `Comparator` when you need multiple orderings,
> ad-hoc ordering, or you can't modify the class. `Comparator.comparing()`,
> `.thenComparing()`, `.reversed()` build readable comparison chains.

**3 minutes (Senior):**
> `compareTo()` contract: returns negative (this < other), zero (equal),
> positive (this > other). Must be consistent with equals: if
> `a.compareTo(b) == 0` then `a.equals(b)` should be true (TreeMap,
> TreeSet correctness depends on this). Violating this creates invisible
> bugs in sorted collections.
>
> Java 8 `Comparator` factory methods:
> `Comparator.comparing(Person::getName)` - by name
> `.thenComparing(Person::getAge)` - then by age
> `.reversed()` - reverse the order
> `Comparator.nullsFirst(Comparator.naturalOrder())` - nulls first
>
> `Arrays.sort()` and `Collections.sort()` use `TimSort` which requires
> consistent total order (anti-symmetry, transitivity, totality).
> Inconsistent comparators cause undefined behavior in sort.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Comparable vs Comparator - let me cover the difference,
the compareTo contract, Comparator.comparing() factory methods, and
when to use each."

**(2) First principles:** "From first principles: to sort objects, we
need to answer 'is A < B, A == B, or A > B?' This can be inherent to
the type (String alphabetical) or external (sort users by age for one
use case, by name for another)."

**(3) Bridge:** "Comparable is like a person who has a birth certificate
(natural age ordering). Comparator is like a judge at a talent show
who applies specific scoring criteria. You need both: the natural order
exists, but sometimes you need custom ordering criteria."

---

### 📘 Concept Explanation

**Comparable - natural ordering:**
```java
class Temperature implements Comparable<Temperature> {
    private final double celsius;
    Temperature(double celsius) { this.celsius = celsius; }

    @Override
    public int compareTo(Temperature other) {
        return Double.compare(this.celsius, other.celsius);
        // NEVER: return (int)(this.celsius - other.celsius)
        //   This causes integer overflow and wrong order!
    }
}
// Now: Collections.sort(temps), TreeSet, PriorityQueue all work
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Comparator - external/multiple orderings:**
```java
// Multiple orderings without modifying Person:
Comparator<Person> byAge = Comparator.comparingInt(Person::getAge);
Comparator<Person> byName = Comparator.comparing(Person::getName);
Comparator<Person> byAgeThenName = byAge.thenComparing(byName);
Comparator<Person> byAgeDesc = byAge.reversed();
Comparator<Person> nullsLast = Comparator.nullsLast(byAge);
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

---

### 💻 Code Example

> **Code walkthrough:** The BAD comparison using subtraction is a famousice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> Java bug - integer overflow causes wrong ordering. The correct approach
> uses `Integer.compare()` or `Double.compare()` for numeric types. The
> multi-criteria sort example shows how `Comparator.comparing().thenComparing()`
> chains build readable, composed comparators without custom classes.


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// BAD: subtraction comparator (overflow bug):
Comparator<Integer> bad = (a, b) -> a - b;
// a = Integer.MIN_VALUE = -2147483648
// b = 1
// a - b = -2147483648 - 1 = 2147483647 (overflow!) -> wrong: says a > b!

// GOOD: use Integer.compare or Comparator.comparingInt:
Comparator<Integer> good = Integer::compare;
Comparator<Integer> alsoGood = Comparator.comparingInt(i -> i);

// Multi-criteria sort:
record Employee(String name, String dept, int salary) {}
List<Employee> employees = loadEmployees();

employees.sort(
    Comparator.comparing(Employee::dept)       // by dept ascending
        .thenComparingInt(Employee::salary)    // then by salary ascending
        .reversed()                            // both reversed (desc)
);
// Note: reversed() reverses the ENTIRE chain above

// Or explicitly control order per criterion:
employees.sort(
    Comparator.comparing(Employee::dept)
        .thenComparingInt(e -> -e.salary())  // salary descending
);

// Null-safe comparator:
List<String> withNulls = Arrays.asList("c", null, "a", null, "b");
withNulls.sort(Comparator.nullsFirst(Comparator.naturalOrder()));
// [null, null, a, b, c]
withNulls.sort(Comparator.nullsLast(Comparator.naturalOrder()));
// [a, b, c, null, null]
```

> **Code walkthrough:** The `reversed()` call reverses the entireice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> composed comparator chain. If you want `dept` ascending and `salary`
> descending independently, use `thenComparingInt(e -> -e.salary())`
> (negate to reverse) rather than `.reversed()`. The null-safe comparators
> are essential when sorting data from databases where nullable columns
> produce null values in Java - without `nullsFirst`/`nullsLast`, a
> `null.compareTo()` call throws NPE during sort.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `Comparable` is implemented by the class itself (natural order).
> `Comparator` is an external comparison strategy. Use `Comparable`
> for the main "default" ordering. Use `Comparator` for secondary
> orderings or when you can't modify the class. Never use `a - b` for
> integer comparison (overflow). Use `Integer.compare(a, b)` or
> `Comparator.comparingInt()`.

---

**Senior / Staff (5+ years):**
> The `compareTo` contract consistency with `equals` is critical for
> sorted collections. `TreeSet` uses `compareTo` for equality, not
> `equals`: if two objects have `compareTo == 0`, `TreeSet` treats them
> as the same element. If `compareTo == 0` but `equals` is false (e.g.,
> case-insensitive String comparison): `TreeSet` rejects the second element.
> For Java 8+ sorting: prefer `Comparator.comparing()` chains for
> readability and null safety. `Stream.sorted()` doesn't modify the
> source - it returns a new sorted stream, making it composable.

---

### ⚠️ Common Misconceptions

**Misconception 1: "a - b is a valid integer comparator."**
Causes integer overflow: if `a = MIN_VALUE` and `b = 1`,
`a - b = MAX_VALUE` (positive), saying a > b, which is wrong.
Always use `Integer.compare(a, b)`, `Comparator.comparingInt()`,
or `Double.compare(a, b)` for numeric comparisons.

**Misconception 2: "Comparable and Comparator define equals."**
`compareTo()` returning 0 means "equal for ordering purposes", not
`equals()`. They should be consistent, but are separate contracts.
`TreeMap` and `TreeSet` use `compareTo()` for element equality
(not `equals()`). Inconsistency causes lost elements in `TreeSet`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: TreeSet losing elements due to compareTo/equals inconsistency.**
```java
// compareTo returns 0 for case-insensitive match,
// equals returns false for different case:
class CIString implements Comparable<CIString> {
    final String value;
    @Override public int compareTo(CIString o) {
        return value.compareToIgnoreCase(o.value); // case-insensitive
    }
    @Override public boolean equals(Object o) {
        return value.equals(((CIString)o).value); // case-SENSITIVE
    }
}
TreeSet<CIString> set = new TreeSet<>();
set.add(new CIString("Hello"));
set.add(new CIString("hello")); // compareTo returns 0 -> "already exists"!
set.size(); // 1, not 2 - "hello" was rejected
```
> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Diagnosis: TreeSet/TreeMap not containing expected elements; check
if compareTo and equals are consistent.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Comparable vs Comparator | 90 seconds |
| compareTo contract | 2 minutes |
| Subtraction comparator bug | 90 seconds |
| Comparator.comparing() chains | 2 minutes |
| Consistent with equals | 2 minutes |
| Natural order primitives | 60 seconds |
| Reverse ordering | 90 seconds |
| Null-safe comparison | 90 seconds |
| Custom multi-field sort | 2 minutes |

---

**Q1 (Comparable vs Comparator): When do you use Comparable vs Comparator?**

A: **Comparable:** implement on a class to define its natural order.
One ordering per class. The class "knows" how to compare itself.
Examples: `String` (alphabetical), `Integer` (numeric), `LocalDate` (chronological).

**Comparator:** an external object defining a specific ordering.
Multiple comparators possible per class. The class doesn't need to implement anything.
Use when: multiple orderings needed, can't modify the class, ad-hoc ordering.

```java
// Natural order: Person comparable by ID (the primary order)
class Person implements Comparable<Person> {
    final int id;
    @Override public int compareTo(Person other) {
        return Integer.compare(this.id, other.id);
    }
}

// External orderings: sort by different fields
Comparator<Person> byName = Comparator.comparing(p -> p.name);
Comparator<Person> byAge = Comparator.comparingInt(p -> p.age);
Comparator<Person> byIdDesc = Comparator.comparingInt(
    (Person p) -> p.id).reversed();

// Using in sort:
people.sort(byName);              // sort by name
people.sort(byAge.thenComparing(byName)); // by age, then name
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* The Comparable/Comparator split is
a design choice about where ordering logic belongs. If ordering is
inherent to the domain concept (higher ID = newer, lower price = better
deal), `Comparable` makes sense. If ordering is context-dependent
(sort users by name for the UI, by signup date for analytics, by
spending for loyalty), `Comparator` is the right choice. Records
do NOT auto-generate `Comparable` - you must implement it explicitly
if needed. This is intentional: what's the "natural" order of a record
with multiple fields is a domain decision.

---

**Q2 (compareTo contract): What are the requirements of compareTo()?**

A: `compareTo()` must satisfy four properties:

1. **Anti-symmetry:** `sgn(a.compareTo(b)) == -sgn(b.compareTo(a))`
   If a < b, then b > a.

2. **Transitivity:** if `a.compareTo(b) > 0` and `b.compareTo(c) > 0`,
   then `a.compareTo(c) > 0`.

3. **Consistency:** if `a.compareTo(b) == 0`, then `sgn(a.compareTo(c))
   == sgn(b.compareTo(c))` for all c.

4. **Consistency with equals (strongly recommended):**
   `(a.compareTo(b) == 0) == a.equals(b)`. Required for `TreeMap`/`TreeSet`
   to work correctly.

```java
// Transitivity violation example:
// a=1.0, b=NaN, c=2.0
// 1.0.compareTo(NaN) -> -1  (1.0 < NaN)
// NaN.compareTo(2.0) -> -1  (NaN < 2.0)
// 1.0.compareTo(2.0) -> -1  (1.0 < 2.0)
// This is consistent! But:
// NaN.compareTo(NaN) -> 0 (NaN == NaN for ordering)
// Double.compareTo handles NaN correctly; < operator does not
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Violating transitivity causes
undefined behavior in sorting algorithms. Java's `TimSort` may
throw `IllegalArgumentException` if it detects a violated comparator
contract (Java 7+: "Comparison method violates its general contract!").
This is a correctness check, not a performance optimization. If you
see this exception in production: find the inconsistent comparator
in your sorted collection or stream sort.

---

**Q3 (Subtraction comparator bug): Why is `(a, b) -> a - b` wrong as
a comparator?**

A: Integer overflow makes the subtraction comparator incorrect for
extreme values:

```java
// The bug:
Comparator<Integer> subtraction = (a, b) -> a - b;

int a = Integer.MIN_VALUE;  // -2147483648
int b = 1;
a - b;  // = -2147483648 - 1
        // = 2147483647 (integer overflow)
        // Comparator says a > b (positive result)
        // But a is actually LESS than b!

// Concrete sorting failure:
List<Integer> list = Arrays.asList(Integer.MIN_VALUE, 0, 1, 2);
list.sort((a, b) -> a - b);
// Expected: [MIN_VALUE, 0, 1, 2]
// Actual: unpredictable due to overflow!

// FIXES:
Comparator<Integer> correct1 = Integer::compare;
Comparator<Integer> correct2 = Comparator.comparingInt(i -> i);
Comparator<Integer> correct3 = (a, b) -> Integer.compare(a, b);
// Integer.compare uses subtraction internally with long cast:
// (x < y) ? -1 : ((x == y) ? 0 : 1) - no overflow
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* The subtraction comparator works
for small bounded values (ages 0-150, scores 0-100) because overflow
never occurs in practice. This makes it a silent bug - tests pass,
production works for years, then an edge case hits. Code review flag:
any comparator implemented as `(a, b) -> a - b` or `(a, b) -> b - a`
should be rewritten. The correct forms are all one-liners:
`Comparator.comparingInt()`, `Integer.compare()`, `Comparator.naturalOrder()`.

---

**Q4 (Comparator.comparing() chains): Build a comparator that sorts
employees by department ascending, then by salary descending, with
null departments last.**

A:
```java
record Employee(String dept, String name, int salary) {}

Comparator<Employee> comp =
    Comparator.comparing(
        Employee::dept,
        Comparator.nullsLast(Comparator.naturalOrder()) // nulls last
    )
    .thenComparingInt(e -> -e.salary()); // negate = descending

// Test:
List<Employee> emps = List.of(
    new Employee("Eng", "Alice", 90000),
    new Employee("Eng", "Bob", 80000),
    new Employee(null, "Carol", 70000),
    new Employee("HR", "Dave", 60000)
);
emps.stream()
    .sorted(comp)
    .forEach(System.out::println);
// Eng Alice 90000
// Eng Bob 80000
// HR Dave 60000
// null Carol 70000
```

> **Code walkthrough:** This Unknown example demonstrates Java Stream pipeline using Stream. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **TAKEAWAY: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

Alternatively using explicit reversed:
```java
Comparator<Employee> comp2 =
    Comparator.comparing(
        Employee::dept,
        Comparator.nullsLast(Comparator.naturalOrder()))
    .thenComparing(
        Comparator.comparingInt(Employee::salary).reversed());
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* The `.reversed()` method reverses
the ENTIRE comparator up to that point. If you chain `.comparing().thenComparing().reversed()`, all criteria are reversed. To reverse
only the second criterion: use a new `Comparator.comparingX(...).reversed()`
as the argument to `thenComparing()`. Understanding this scoping rule
is essential for complex multi-field sorts. In production code: extract
named comparators for readability when the chain gets complex.

---

**Q5 (Consistent with equals): What happens when compareTo is not
consistent with equals in a TreeSet?**

A:
```java
// Case-insensitive comparator, case-sensitive equals:
TreeSet<String> set = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
set.add("hello");
set.add("Hello");  // compareTo returns 0 (case-insensitive match)
                   // TreeSet says "already in set"!
set.size();        // 1, not 2!
set.contains("HELLO"); // true
set.contains("hello"); // true
// But set only has one element!

// TreeSet uses compareTo for all operations (not equals)
// When compareTo returns 0, it's treated as "same element"
// regardless of what equals() says
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

The Javadoc for `Comparable` says: "It is strongly recommended, but
not strictly required, that `(x.compareTo(y) == 0) == x.equals(y)`."
The "strictly required" part is what causes the TreeSet behavior.

*What separates good from great:* This inconsistency is intentional
for `String.CASE_INSENSITIVE_ORDER` - you want a case-insensitive set
where "hello" and "Hello" are the same element. When the inconsistency
is unintentional, it's a subtle bug. `TreeMap` has the same issue:
inserting `"hello"` and `"Hello"` with a case-insensitive map only
stores one entry. To diagnose: check `set.size()` vs expected count
after population; if too small, check compareTo/equals consistency.

---

**Q6 (Natural order primitives): What is the natural order of Java's
primitive wrapper types?**

A: All primitive wrapper types implement `Comparable<T>` with numeric ordering:
- `Byte`, `Short`, `Integer`, `Long`, `Float`, `Double`: numeric ascending
- `Character`: Unicode code point order (same as `char` cast to `int`)
- `Boolean`: `false` < `true` (false=0, true=1)

```java
// Natural order examples:
List<Integer> nums = Arrays.asList(3, 1, 4, 1, 5);
Collections.sort(nums); // [1, 1, 3, 4, 5]

List<Character> chars = Arrays.asList('z', 'A', 'a', 'Z');
Collections.sort(chars); // [A, Z, a, z] (uppercase before lowercase in ASCII)

List<String> strs = Arrays.asList("banana", "Apple", "cherry");
Collections.sort(strs); // [Apple, banana, cherry] (uppercase before lowercase)
// For case-insensitive sort:
strs.sort(String.CASE_INSENSITIVE_ORDER); // [Apple, banana, cherry]
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* String's natural order is lexicographic
based on Unicode code points. This means uppercase letters come before
lowercase in ASCII (A=65, a=97). For locale-aware text sorting:
`Collator.getInstance(Locale)` provides locale-appropriate ordering
(e.g., Swedish has 'å' after 'z', not after 'a'). For user-facing
sort: always use `Collator` unless the data is purely technical
(IDs, codes) where lexicographic order is sufficient.

---

**Q7 (Reverse ordering): How do you reverse a natural or custom order?**

A:
```java
// Reverse natural order:
List<Integer> nums = new ArrayList<>(List.of(3,1,4,1,5));

// Option 1: Comparator.reverseOrder()
nums.sort(Comparator.reverseOrder()); // [5,4,3,1,1]

// Option 2: Collections.sort + Collections.reverse
Collections.sort(nums);
Collections.reverse(nums);

// Option 3: .reversed() on an existing comparator
Comparator<Integer> asc = Comparator.naturalOrder();
Comparator<Integer> desc = asc.reversed();
nums.sort(desc);

// TreeSet with reverse natural order:
TreeSet<Integer> descSet = new TreeSet<>(Comparator.reverseOrder());
descSet.addAll(List.of(3,1,4,1,5));
// Iterates: 5, 4, 3, 1 (descending, no duplicate 1)

// PriorityQueue max-heap (reverse natural order):
PriorityQueue<Integer> maxHeap =
    new PriorityQueue<>(Comparator.reverseOrder());
maxHeap.offer(3); maxHeap.offer(1); maxHeap.offer(5);
maxHeap.poll(); // 5 (max element)
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* `PriorityQueue` is min-heap by default
(natural order). For max-heap: `new PriorityQueue<>(Comparator.reverseOrder())`.
This is a common interview question: "implement a k-largest elements
algorithm". Solution: min-heap of size k; if a new element is larger
than the heap's min, replace the min with the new element. Result:
heap contains the k largest elements. `PriorityQueue` is O(log k)
per insert with the bounded heap trick.

---

**Q8 (Null-safe comparison): How do you sort a collection that contains
null elements?**

A:
```java
// Collections.sort(list) throws NPE if list contains null
List<String> list = Arrays.asList("c", null, "a", null, "b");
// Collections.sort(list); // NullPointerException!

// Fix: Comparator.nullsFirst or nullsLast
list.sort(Comparator.nullsFirst(Comparator.naturalOrder()));
// [null, null, a, b, c]

list.sort(Comparator.nullsLast(Comparator.naturalOrder()));
// [a, b, c, null, null]

// Null-safe custom comparator:
Comparator<Person> byName = Comparator.nullsLast(
    Comparator.comparing(Person::getName,
        Comparator.nullsLast(Comparator.naturalOrder()))
);
// Handles null Person AND null Person.getName()!

// For null-safe sorting of primitives from nullable sources:
people.stream()
    .sorted(Comparator.comparingInt(p ->
        p.getAge() != null ? p.getAge() : Integer.MAX_VALUE))
    .collect(Collectors.toList());
```

> **Code walkthrough:** This Unknown example demonstrates Java Stream pipeline using Stream. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **TAKEAWAY: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

*What separates good from great:* Database query results frequently
contain null values for optional fields. Any stream sort on such data
without null handling will NPE in production when a null row appears.
Standard defensive practice: always use `nullsFirst()/nullsLast()` when
sorting data from external sources. Define the null policy explicitly
in the comparator (not silently letting NPE propagate). For domain
objects: prefer `Optional<T>` return types from accessors to make null
handling explicit at the type level.

---

**Q9 (Custom multi-field sort): Implement a comparator to sort
employees by: manager first, then by years of service descending,
then by name ascending.**

A:
```java
record Employee(String name, boolean isManager,
                int yearsOfService) {}

Comparator<Employee> comp =
    // Managers first: false < true, so reversed (true first):
    Comparator.comparing(Employee::isManager).reversed()
    // Then years of service descending:
    .thenComparingInt(e -> -e.yearsOfService())
    // Then name ascending (natural order):
    .thenComparing(Employee::name);

// Equivalent, more explicit:
Comparator<Employee> comp2 =
    Comparator.<Employee, Boolean>comparing(Employee::isManager,
        Comparator.reverseOrder())           // true > false
    .thenComparing(
        Comparator.comparingInt(Employee::yearsOfService).reversed())
    .thenComparing(Employee::name);

// Test:
List<Employee> staff = List.of(
    new Employee("Alice", false, 3),
    new Employee("Bob",   true,  5),
    new Employee("Carol", true,  8),
    new Employee("Dave",  false, 7)
);
staff.stream().sorted(comp2).forEach(System.out::println);
// Carol (manager, 8 years)
// Bob   (manager, 5 years)
// Dave  (non-manager, 7 years)
// Alice (non-manager, 3 years)
```

> **Code walkthrough:** This Unknown example demonstrates Java Stream pipeline using Stream. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **TAKEAWAY: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

*What separates good from great:* When negating for descending order
(`e -> -e.yearsOfService()`), be aware of integer overflow for
`Integer.MIN_VALUE` - the same subtraction bug in comparator form.
For safety: use `Comparator.comparingInt(...).reversed()` instead of
negation. Also: the `comparing(Employee::isManager, Comparator.reverseOrder())`
pattern is clearer than negating or chaining `.reversed()` after
because it explicitly documents "isManager, sorted descending".

---

### ⚖️ Comparison Table

| Aspect | Comparable | Comparator |
|---|---|---|
| Location | Inside the class | External class or lambda |
| Number of orderings | One per class | Unlimited |
| Modifying class needed | Yes | No |
| Java 8 factory methods | No | Comparator.comparing(), etc. |
| Used by | Collections.sort, TreeSet/Map | Sort overloads, sorted() |
| Null handling | Not supported | nullsFirst()/nullsLast() |
| Thread safe | N/A (stateless) | N/A if stateless |

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



