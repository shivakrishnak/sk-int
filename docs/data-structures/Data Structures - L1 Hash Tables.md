---
layout: default
title: "Data Structures - L1 Hash Tables"
parent: "Data Structures"
nav_order: 3
permalink: /data-structures/l1-hash-tables/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Hash Tables and Hash Functions](#hash-tables-and-hash-functions) | critical |
| 2 | [Collision Resolution Strategies](#collision-resolution-strategies) | high |
| 3 | [HashMap vs HashSet Trade-offs](#hashmap-vs-hashset-trade-offs) | medium |

---

# Hash Tables and Hash Functions

---
id: DS-007
title: Hash Tables and Hash Functions
difficulty: ★☆☆
status: draft
---

### 🎯 Model Answer

**30 seconds:**
> A hash table is a data structure that maps keys to values in O(1) average time. It works by computing a hash function on the key to determine a bucket index, then storing the value in that bucket. A good hash function distributes keys uniformly across buckets to minimize collisions. Java's HashMap and HashSet are hash table implementations.

**3 minutes:**
> The hash table achieves O(1) average lookup by reducing the search space from "all elements" to "one bucket." If we have n elements in b buckets and the hash function distributes uniformly, each bucket has about n/b elements. If we maintain b ≈ n (via resizing), each bucket has about 1 element. That's the key insight: uniform distribution + appropriate sizing = constant time lookup.

> A good hash function has three properties: determinism (same key always produces the same hash), uniformity (keys spread evenly across the hash space), and efficiency (fast to compute). Java's String.hashCode() is `s[0]*31^(n-1) + s[1]*31^(n-2) + ... + s[n-1]`. The prime multiplier 31 reduces clustering - primes cause fewer regularities in the hash values.

> The critical invariant for hash tables: if two objects are `equal()`, they must have the same `hashCode()`. If you override `equals()` without overriding `hashCode()`, the hash table will never find entries you insert because lookup uses `hashCode()` to find the bucket and `equals()` to verify the match. Breaking this contract is one of the most common and subtle Java bugs.

**Blank Mind Recovery:**
**(1) Restate:** "Hash table - maps keys to values in constant time using a hash function."

**(2) First principles:** "Arrays give O(1) access by index. What if we could turn any key into an array index? A hash function does exactly that - turns a key into an index."

**(3) Bridge:** "It's like a library organized by first letter. Instead of searching all books, you immediately go to the right shelf. The shelf letter is the hash."

---

### 📘 Concept Explanation

**What it is:**
A hash table is an array-based data structure where the position of each element is determined by applying a hash function to the element's key. The hash function maps the key space to a smaller index space (the array indices).

**The problem it solves:**
Searching a sorted array requires O(log n) binary search. Searching an unsorted array requires O(n) linear scan. Hash tables provide O(1) average search by converting the key directly into an array index - turning search into direct array access.

**How it works:**
1. Compute `hashCode(key)` → an integer (possibly large or negative)
2. Compute bucket index: `index = hashCode & (capacity - 1)` (when capacity is power-of-2)
3. Store the entry at `array[index]`
4. On lookup: compute same index, scan the bucket for the key using `equals()`

**Critical equation:** bucket_index = hash(key) % capacity

Java uses bitwise AND (`hash & (capacity - 1)`) which is equivalent to modulo when capacity is a power of 2 but much faster (bit operation vs division).

**Load factor and resizing:**
Load factor = n/capacity. Java's HashMap default load factor is 0.75. When exceeded, the table doubles in capacity and rehashes all entries (O(n)). This resize maintains the O(1) average by keeping buckets sparse.

**The key insight:**
Hash tables trade space (extra buckets) for time (O(1) lookup). The load factor controls this trade-off: lower load factor = fewer collisions = faster lookups = more wasted space.

**When to use it:**
- Fast lookup by arbitrary key: "does this key exist? what's the value for this key?"
- Deduplication and counting: "have I seen this key before? how many times?"
- Caching: key = cache key, value = cached result
- Frequency maps: `Map<String, Integer>` for word counting

**When NOT to use it:**
- Sorted iteration required (use TreeMap)
- Range queries required (use TreeMap.subMap())
- Memory is severely constrained (hash tables have overhead per entry)
- Keys need to be stored in insertion order (use LinkedHashMap)

**Alternatives:**
- TreeMap: O(log n) but sorted; use when sort order matters
- Array: when keys are small integers, directly use as indices
- Trie: when keys are strings and prefix queries matter
- Bloom filter: when membership testing with a small false positive rate is acceptable and memory is critical

**First-principles derivation:**
We want O(1) access. Arrays give O(1) access by index. The problem is that real-world keys (strings, objects) aren't array indices. A hash function converts arbitrary keys to integers, and modulo reduces those integers to valid array indices. The result: any key can be turned into an array index in constant time. This is the hash table's fundamental insight.

---

### 💻 Code Example

```java
// Custom class used as HashMap key
// MUST override both hashCode() and equals()
public class Point {
    final int x, y;

    public Point(int x, int y) { this.x = x; this.y = y; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Point)) return false;
        Point p = (Point) o;
        return x == p.x && y == p.y;
    }

    @Override
    public int hashCode() {
        // Combine fields using prime multiplier (31)
        // This is the same pattern as Java's Objects.hash()
        return 31 * x + y;
    }
}

// Usage
Map<Point, String> locations = new HashMap<>();
locations.put(new Point(1, 2), "Library");
// Works because hashCode() and equals() both implemented
System.out.println(locations.get(new Point(1, 2))); // "Library"
```

> **Code walkthrough:** This is the correct pattern for using custom objects as HashMap keys. KEY MECHANISM: when `put(new Point(1,2), "Library")` is called, HashMap computes `new Point(1,2).hashCode()` to find the bucket, then stores the entry; when `get(new Point(1,2))` is called, it computes the same hashCode, finds the same bucket, and uses `equals()` to verify the match. WHY IT MATTERS: if `hashCode()` is missing or wrong, `get()` returns null for keys you know were inserted - this is a silent bug that's extremely hard to diagnose. WHAT BREAKS: using a mutable field in `hashCode()` means that after mutation, the entry is in the wrong bucket and is effectively lost. TAKEAWAY: for HashMap keys, always implement both `hashCode()` and `equals()`, use only immutable fields in the computation, and prefer `Objects.hash(field1, field2)` to avoid manual prime arithmetic.

```java
// BAD: forgot hashCode() override
public class BadPoint {
    int x, y;
    // equals() correctly compares x and y
    @Override
    public boolean equals(Object o) {
        if (!(o instanceof BadPoint)) return false;
        BadPoint p = (BadPoint) o;
        return x == p.x && y == p.y;
    }
    // Missing hashCode()! Uses Object.hashCode()
    // which is based on identity (memory address)
}

// GOOD: always override both together
public class GoodPoint {
    final int x, y; // immutable = safe as key
    public GoodPoint(int x, int y) { this.x=x; this.y=y; }

    @Override
    public boolean equals(Object o) {
        if (!(o instanceof GoodPoint)) return false;
        GoodPoint p = (GoodPoint) o;
        return x == p.x && y == p.y;
    }

    @Override
    public int hashCode() {
        return Objects.hash(x, y); // safe, correct
    }
}

// Demonstration of BadPoint failure
Map<BadPoint, String> map = new HashMap<>();
map.put(new BadPoint(1, 2), "Library");
// Returns null! Two BadPoint(1,2) have different hashCode
// because Object.hashCode() returns different values
// for different instances
System.out.println(map.get(new BadPoint(1, 2))); // null!
```

> **Code walkthrough:** This BAD/GOOD pair demonstrates the most common HashMap bug in Java - overriding `equals()` without `hashCode()`. KEY MECHANISM: `Object.hashCode()` returns a value based on the object's identity (memory address or a derived value), so two `BadPoint(1,2)` instances have different default hashCodes even though they're `equal()` by content; this causes the HashMap to look in a different bucket on retrieval, finding nothing. WHY IT MATTERS: this bug appears in production when developers create a custom class, properly implement equals(), and forget hashCode() - tests pass if only one instance is used as a key, but fail when new instances are created for lookup. WHAT BREAKS: this is silent - no exception is thrown, just unexpected null returns or duplicate entries in HashSets. TAKEAWAY: use `@Override` on both methods so the compiler catches typos; use `Objects.hash(fields...)` for the implementation; and in IntelliJ/Eclipse, generate both together via the IDE's "generate" feature.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A hash table maps keys to values using a hash function to compute an array index. This gives O(1) average lookup, insert, and delete. In Java, HashMap is the standard implementation. The main rule I follow is: if I use a custom class as a key, I must override both equals() and hashCode() - forgetting one breaks the map silently.

---

**Senior / Staff (5+ years):**
> I think of hash tables as the Swiss Army knife of data structures - O(1) for everything except ordered operations. At production scale I pay attention to hash quality. Java String's hashCode has a polynomial construction that distributes well. But user-provided keys in public APIs are potentially adversarial - an attacker can craft strings that all hash to the same bucket, forcing O(n) behavior per operation (hash-flooding DoS attack). Java's HashMap mitigates this by switching to tree nodes (Red-Black tree) per bucket when a bucket exceeds 8 entries, converting worst-case from O(n) to O(log n) per bucket.

> For very high-throughput scenarios I use specialized maps. For primitive int→Object mappings, Eclipse Collections' IntObjectHashMap eliminates boxing overhead. For concurrent access, ConcurrentHashMap is far better than Collections.synchronizedMap() because it uses segment-level locks instead of whole-map locks.

---

### ⚠️ Common Misconceptions

**Misconception 1: "HashMap preserves insertion order."**
No. HashMap makes no ordering guarantees. Two runs of the same code may produce different iteration orders. Use LinkedHashMap (insertion order) or TreeMap (key sorted order) when order matters.

**Misconception 2: "null keys and values are supported universally."**
HashMap supports one null key and multiple null values. Hashtable (legacy) and ConcurrentHashMap do NOT support null keys or values. Using null keys in ConcurrentHashMap throws NullPointerException. Always check the docs when using less common Map implementations.

**Misconception 3: "A better hash function is always better."**
Hash functions are a trade-off between distribution quality and computation time. A cryptographic hash (SHA-256) has excellent distribution but is expensive to compute. Java's String.hashCode() is a fast polynomial hash that's good enough for hash tables. For hash tables, "good enough distribution, fast computation" beats "perfect distribution, slow computation."

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: equals/hashCode contract violation causes data loss**
Symptom: HashMap.get() returns null for keys you know were inserted; HashSet.contains() returns false for elements you know were added.
Diagnosis: decompile or inspect the key class. Check if hashCode() is absent (using Object's identity-based default) or if it doesn't use the same fields as equals().
Fix: implement both equals() and hashCode() using the same set of fields. Use Objects.hash() and Objects.equals() to simplify.

**Failure 2: Hash-collision DoS**
Symptom: API endpoint response time grows to seconds when receiving specific inputs. CPU usage spikes on HashMap operations.
Diagnosis: profile with async-profiler; if HashMap bucket traversal appears in hot path, suspect hash flooding. Log key distribution to verify.
Fix: use ConcurrentHashMap (tree bins for overflowing buckets), add input validation to reject obviously adversarial keys, or use a randomized hash seed.

**Failure 3: HashMap in concurrent code causes infinite loop**
Symptom: thread hangs indefinitely in HashMap.get() or put(); CPU at 100%.
Diagnosis: HashMap's internal linked list can form a cycle during concurrent resize in Java < 8. Even in Java 8+, concurrent modification can corrupt the structure.
Fix: use ConcurrentHashMap for any shared mutable map. Never share a HashMap across threads without external synchronization.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | hash function, equals/hashCode, load factor |
| Debugging | 2 | contract violation, hash flooding |
| Trade-off | 1 | hash quality vs speed |
| Behavioral | 1 | production HashMap use |

---

**[JUNIOR] Q1 - [SCENARIO] Explain the equals() and hashCode() contract and why it matters.**

The contract has two rules:
1. If `a.equals(b)` is true, then `a.hashCode() == b.hashCode()` must be true.
2. `hashCode()` must return the same value every time it's called on the same object (within a single JVM run).

Rule 1 is critical for HashMap correctness. HashMap uses `hashCode()` to find the bucket and `equals()` to verify the match within the bucket. If two equal objects have different hashCodes, the lookup looks in the wrong bucket and returns null - the entry is effectively lost.

The reverse is not required: `a.hashCode() == b.hashCode()` does NOT mean `a.equals(b)`. Hash collisions (different objects with same hash) are legal and handled by storing multiple entries per bucket.

A common violation: override `equals()` based on logical equality (field values) but forget `hashCode()`, which defaults to Object's identity-based implementation. Now `new Point(1,2).equals(new Point(1,2))` is true but their hashCodes differ, breaking HashMap.

Why the contract exists: it's an optimization contract. If equal objects always have equal hash codes, then the hash code serves as a pre-filter: if hash codes differ, we know the objects are unequal without calling the more expensive `equals()`. This makes bucket scanning faster.

*What separates good from great:* Great engineers also know the rule for consistent hashCode: even if an object's fields change between calls to hashCode(), the same value must be returned within a single JVM invocation (though it may differ across JVM runs, as documented in Java). This is why mutable objects make bad HashMap keys - if you change the key's fields after insertion, you've changed its hashCode, and the entry is now in the wrong bucket. The key is "there" but unreachable.

---

**[JUNIOR] Q2 - [MECHANISM] What is the load factor and how does it affect HashMap performance?**

Load factor is `n / capacity` where n = number of entries and capacity = number of buckets.

Java's HashMap default load factor: 0.75. When the map exceeds 75% of capacity (i.e., 75% of buckets have at least one entry), it rehashes: doubles the bucket count and redistributes all entries.

**Effect on performance:**
- Low load factor (e.g., 0.25): fewer collisions (most buckets have 0 or 1 entry), O(1) lookups are consistently fast. But more memory wasted on empty buckets.
- High load factor (e.g., 0.95): more collisions (more buckets have multiple entries), bucket scanning increases, approaching O(k) per lookup where k = average bucket size.

**The 0.75 compromise:** mathematical analysis shows that at 0.75 load factor, the probability of a bucket having 0 entries ≈ e^-0.75 ≈ 47%, probability of 1 entry ≈ 35%, probability of 2+ entries ≈ 18%. Most lookups hit an empty or single-entry bucket - still effectively O(1).

**Pre-sizing for performance:**
```java
// Common mistake: creates map with capacity 1000
// but will rehash at 750 entries
Map<K, V> m = new HashMap<>(1000);

// Correct: size to avoid rehashing at n entries
// capacity = n / 0.75 + 1
Map<K, V> m = new HashMap<>(1334); // holds 1000 without rehash
```

> **Code walkthrough:** This snippet shows correct HashMap pre-sizing to prevent rehashing. The KEY MECHANISM: `new HashMap<>(1334)` sets initial capacity so 1000 entries fit below the 0.75 load factor threshold - at 750 entries Java rehashes; at capacity 1334, it rehashes only when 1001 entries are added. WHY IT MATTERS: each rehash allocates a new backing array 2x larger and copies all entries - at 100,000 entries, the final rehash copies 100,000 entries in one O(n) pause. WHAT BREAKS: `new HashMap<>(1000)` is still insufficient - Java rehashes when `size > capacity * loadFactor` = 750, not 1000. TAKEAWAY: pre-size formula is `initialCapacity = expectedSize / 0.75 + 1`; use it whenever you know the approximate number of entries upfront.

*What separates good from great:* The pre-sizing formula is a practical micro-optimization that matters at scale. Creating a HashMap that will hold 1 million entries without pre-sizing causes approximately log₂(1,000,000) ≈ 20 rehashing operations (each doubling capacity and copying all entries). Pre-sizing to `(int)(n / 0.75 + 1)` eliminates all rehashing. Guava's `Maps.newHashMapWithExpectedSize(n)` does this calculation for you.

---

**[JUNIOR] Q3 - [MECHANISM] How does Java handle HashMap collisions and what changed in Java 8?**

Pre-Java 8: collisions are handled with separate chaining. Each bucket is a linked list of entries that hash to that bucket. Lookup: compute bucket index, traverse the linked list, find matching key using equals(). Worst case: all keys hash to same bucket = O(n) traversal.

Java 8+ change: when a bucket's linked list exceeds 8 entries AND the table has at least 64 buckets, the linked list is converted to a Red-Black tree. This changes worst-case from O(n) to O(log n) per bucket.

The threshold logic: if bucket size > 8, convert to tree (treeify). If bucket size falls below 6 (due to removals), convert back to linked list (untreeify). The 8/6 thresholds prevent thrashing between tree and list when bucket size is near the boundary.

Why this matters: before Java 8, hash flooding DoS attacks could be mounted by crafting keys with identical hashCodes, forcing all entries into one bucket and turning every HashMap operation into O(n). Java 8's tree bins bound this to O(log n) even under adversarial inputs. This was a significant security fix for web applications that used HashMap with user-provided keys.

Performance impact: treeified buckets have higher constant factor overhead than linked list buckets (tree operations are more complex). They're a defense mechanism, not a performance feature. A well-designed application with a good hash function rarely triggers treeification.

*What separates good from great:* Great engineers know that tree bins in Java 8 require keys to be Comparable (or a Comparator to be provided via the map's constructor). For String keys this is automatic. For custom classes used as keys, if your class doesn't implement Comparable, Java falls back to identity-based comparison for tree ordering - which still avoids the O(n) worst case but makes tree operations non-deterministic.

---

**[MID] Q4 - [MECHANISM] What makes a good hash function for a hash table?**

A good hash function has five properties:

1. **Deterministic:** same input always produces same output. This is a requirement - if the hash were random, you could never find what you stored.

2. **Uniform distribution:** outputs spread evenly across the hash space. If 90% of keys hash to bucket 0, you've effectively reduced your hash table to a linked list of n * 0.9 elements.

3. **Avalanche effect:** small changes in input cause large changes in output. If `hash("abc") = 5` and `hash("abd") = 6`, bucket distribution of similar keys is predictable and potentially clustered. Good hashes cause `hash("abd")` to be unrelated to `hash("abc")`.

4. **Fast to compute:** hash is computed on every insert, lookup, and delete. A hash that takes 1 millisecond per call makes the hash table 1000x slower than an O(1) lookup should be.

5. **Collision-resistant enough:** perfect collision-resistance is a cryptographic property; hash tables don't need it. They need distribution that's uniform enough that bucket sizes stay small.

Java String hashCode: `s[0]*31 + s[1]*31^0 + ... + s[n-1]` (Horner's method). The prime 31 was chosen because it's a prime (reduces regularities), and it can be computed as `(value << 5) - value` (bit shift + subtract is faster than multiplication on some architectures).

Bad hash example: `return key.length()` - all strings of the same length hash to the same bucket. Terrible distribution; violates property 2.

*What separates good from great:* Great engineers know that hash table performance is only as good as the hash function's distribution quality for your specific key distribution. A hash function that works well for random strings may cluster for URLs (many start with "https://"), IDs (sequential integers), or timestamps (many differ only in last digit). When choosing or writing a hash function, always test it against your actual key distribution.

---

**[MID] Q5 - [SCENARIO] Implement a simple hash table from scratch with open addressing (linear probing).**

```java
public class SimpleHashTable<K, V> {
    private static final int CAPACITY = 16;
    private final Object[] keys = new Object[CAPACITY];
    private final Object[] values = new Object[CAPACITY];

    private int index(Object key) {
        // & 0x7FFFFFFF clears sign bit for non-negative index
        return (key.hashCode() & 0x7FFFFFFF) % CAPACITY;
    }

    public void put(K key, V value) {
        int i = index(key);
        // Linear probing: find empty slot or existing key
        while (keys[i] != null && !keys[i].equals(key)) {
            i = (i + 1) % CAPACITY; // wrap around
        }
        keys[i] = key;
        values[i] = value;
    }

    @SuppressWarnings("unchecked")
    public V get(K key) {
        int i = index(key);
        while (keys[i] != null) {
            if (keys[i].equals(key)) {
                return (V) values[i];
            }
            i = (i + 1) % CAPACITY;
        }
        return null; // key not found
    }
}
```

> **Code walkthrough:** This snippet implements a basic open-addressing hash map with linear probing. The KEY MECHANISM: on collision, the while loop increments the bucket index with `(i + 1) % CAPACITY` to find the next empty slot, wrapping around as needed. WHY IT MATTERS: open addressing stores all entries in one flat array - cache-friendly because probe sequences access adjacent memory locations. WHAT BREAKS: linear probing creates primary clustering - long runs of occupied slots form, making future probes traverse the entire cluster; double hashing or Robin Hood probing mitigates this. TAKEAWAY: linear probing is simple and cache-efficient but degrades under high load; keep load factor below 0.7 for acceptable probe lengths.

This implements linear probing (open addressing): on collision, probe the next slot linearly until empty. Simple, cache-friendly (probing is sequential access), but suffers from clustering when load factor is high.

Limitation: delete is complex with open addressing - you can't just set a slot to null (it breaks lookup chains). You need a tombstone marker to indicate "deleted but was occupied."

Production note: Java's HashMap uses separate chaining (linked list per bucket), not open addressing. Modern languages (Python dict, C++ unordered_map) often use open addressing with sophisticated probing strategies (quadratic probing, double hashing) for better cache behavior.

*What separates good from great:* The tombstone problem in open addressing is subtle and important. If you delete a key by setting its slot to null, subsequent gets for keys that probed past this slot will incorrectly return null (the probe stops at the empty slot before finding the target). The tombstone solution marks deleted slots so probing continues through them. This adds complexity that separate chaining avoids entirely, which is one reason Java chose chaining for HashMap.

---

**[SENIOR] Q6 - [DESIGN] How would you design a hash function for a Point(x, y) class? What are the pitfalls?**

Good implementation:
```java
@Override
public int hashCode() {
    return Objects.hash(x, y); // Uses 31-multiplier pattern
    // Equivalent to: 31 * x + y (but safer)
}
```

> **Code walkthrough:** This snippet shows the correct `hashCode()` implementation for a Point(x, y) class using `Objects.hash()`. The KEY MECHANISM: `Objects.hash(x, y)` applies `31 * hashCode(x) + hashCode(y)` using a prime multiplier, distributing (x,y) pairs across buckets with low collision rate. WHY IT MATTERS: a well-distributed hash function keeps average bucket length near 1, maintaining O(1) HashMap operations. WHAT BREAKS: if `equals()` is overridden but `hashCode()` is not, two equal Points will hash to different buckets and HashMap will never find one after storing the other - a silent correctness bug. TAKEAWAY: always implement `hashCode()` and `equals()` together; use `Objects.hash()` for multi-field classes to avoid manual prime-multiplier arithmetic.

Why `Objects.hash(x, y)` is correct:
- Uses prime multiplier (31) to mix x and y
- Accounts for both fields in the hash (not just one)
- Results in good distribution for typical coordinate values

**Pitfalls:**

**Pitfall 1: Return constant**
```java
// BAD - all Points hash to same bucket
@Override
public int hashCode() { return 1; }
```

> **Code walkthrough:** This snippet shows a degenerate hashCode that returns a constant. The KEY MECHANISM: every key hashes to bucket 0, so the HashMap degrades to a single linked list. WHY IT MATTERS: all operations become O(n) instead of O(1) - a 10,000-entry map becomes slower than a linear scan. WHAT BREAKS: this is technically contract-compliant (equal objects have the same hash) but catastrophically wrong for performance; it's the most common mistake in early-stage TDD when developers add the minimum to compile. TAKEAWAY: a constant hashCode is the canary for "I forgot to implement this" and must be replaced before any performance testing.

Technically satisfies the contract (all equal objects have hash 1), but destroys performance - every operation is O(n).

**Pitfall 2: Use only one field**
```java
// BAD - Point(1,1), Point(1,2), Point(1,3) all same hash
@Override
public int hashCode() { return x; }
```

> **Code walkthrough:** This snippet shows hashing only on one field. The KEY MECHANISM: all points sharing the same x coordinate hash identically regardless of y, creating hot buckets with long chains for typical grid data. WHY IT MATTERS: a grid with x in range 0-100 produces only 101 distinct hashes for potentially millions of points - average chain length grows proportionally. WHAT BREAKS: this failure is data-dependent; it passes unit tests with small test data but degrades in production with realistic distributions. TAKEAWAY: hash functions must incorporate ALL significant fields; omitting any creates predictable collision patterns.

All points with the same x-coordinate collide. For typical data with many same-x points, this creates hot buckets.

**Pitfall 3: XOR (symmetric)**
```java
// BAD - hash(1, 2) == hash(2, 1)
@Override
public int hashCode() { return x ^ y; }
```

> **Code walkthrough:** This snippet shows XOR as a broken hash function for 2D coordinates. The KEY MECHANISM: XOR is commutative (`a ^ b == b ^ a`), so Point(1,2) and Point(2,1) produce identical hash codes, doubling collisions for symmetric coordinate pairs. WHY IT MATTERS: in graph traversal and matrix algorithms, transposed coordinates are common - systematically colliding them creates hot buckets proportional to the symmetry in the data. WHAT BREAKS: any grid where (row,col) and (col,row) both appear as valid keys will see 2x the collisions. TAKEAWAY: XOR is good only when fields are independent; for ordered tuples like coordinates, use a polynomial hash like `31 * x + y`.

XOR is commutative, so (1, 2) and (2, 1) have the same hash. For grids or matrices where transposed coordinates are both valid and common, this doubles collisions.

**Pitfall 4: Mutable fields**
If x or y could change after insertion, the entry would be stored at the wrong bucket after mutation.

Correct design: make Point immutable (final fields) and use `Objects.hash(x, y)`.

*What separates good from great:* The XOR pitfall is subtle and worth highlighting: XOR is symmetric so `hash(a, b) == hash(b, a)`. For many real-world datasets (graph edges where (u,v) and (v,u) are both present), this doubles collisions for a specific 50% subset of your keys. The asymmetric multiplication-based polynomial `31*x + y` doesn't have this problem.

---

**[SENIOR] Q7 - [MECHANISM] What is the time complexity of HashMap.get() and when does it degrade?**

HashMap.get() time complexity:
- **O(1) average case**: uniform hash distribution, low load factor
- **O(log n) worst case** (Java 8+): all keys hash to one bucket (treeified)
- **O(n) worst case** (pre-Java 8 or < 8 entries in bucket): all keys hash to one bucket (linked list)

Degradation conditions:

**1. Bad hash function with clustering:**
If many keys hash to the same bucket, bucket scanning increases. The operation is still O(bucket_size), but bucket_size is no longer O(1).

**2. Adversarial input (hash flooding):**
An attacker sends keys that all hash to the same bucket. Pre-Java 8 this caused O(n) operations. Java 8's tree bins cap this at O(log n) per bucket.

**3. High load factor:**
As load factor approaches 1.0, expected bucket size grows and collisions increase. At 100% load factor (fully packed), average bucket size > 1 even with uniform distribution.

**4. Integer overflow in hashCode:**
If custom hashCode computation overflows int, it wraps to a negative value. `& 0x7FFFFFFF` is commonly used to clear the sign bit before modulo. Without this, negative modulo results cause ArrayIndexOutOfBoundsException in naive implementations (though Java's HashMap handles this correctly).

In practice, with a good hash function and load factor 0.75, get() is effectively O(1) for all reasonable inputs. The theoretical worst cases require either a deliberately bad hash function or adversarial input.

*What separates good from great:* Great engineers know that the distinction between "O(1) average" and "O(1) worst case" matters for security-sensitive code. A public API that uses HashMap with user-provided keys and doesn't validate those keys is potentially vulnerable to hash-flooding DoS. The fix is using Java 8+ HashMap (O(log n) worst case per bucket), adding key validation, or using a hash function with a randomized seed (like SipHash, which Rust's HashMap uses by default for security).
---

### 🏛️ System Design

*(Omit: system design not applicable for ★☆☆ foundational concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

---

# Collision Resolution Strategies

---
id: DS-008
title: Collision Resolution Strategies
difficulty: ★☆☆
status: draft
---

### 🎯 Model Answer

**30 seconds:**
> Hash table collisions occur when two keys hash to the same bucket. The two main resolution strategies are separate chaining - each bucket holds a linked list of entries - and open addressing - when a collision occurs, probe for another empty slot. Java's HashMap uses separate chaining. Python's dict uses open addressing. Both achieve O(1) average, but open addressing has better cache behavior while separate chaining handles high load factors better.

**3 minutes:**
> Separate chaining puts a linked list (or in Java 8+, a Red-Black tree) at each bucket. Every insert just appends to the bucket's list. Every lookup scans the bucket's list with equals(). It tolerates load factors above 1.0 (more entries than buckets) - the lists just get longer. The downside: each node in the list is a separate heap allocation, which is cache-unfriendly and GC-pressuring.

> Open addressing stores everything in the main array. On collision, probe for an empty slot using a probing sequence. Linear probing tries i+1, i+2, i+3... Quadratic probing tries i+1², i+2², i+3²... Double hashing uses a second hash function. Open addressing is cache-friendly (probing is sequential memory access) but degrades sharply at high load factors due to clustering.

> The key insight is that the best strategy depends on your workload: if you need cache efficiency and can maintain load factor < 0.75, use open addressing. If you need simplicity and can tolerate higher memory usage, use separate chaining. Java chose chaining for HashMap because it handles worst-case load better and simplifies the delete operation.

**Blank Mind Recovery:**
**(1) Restate:** "Two keys, same bucket - what do we do? Two main strategies: chaining and open addressing."

**(2) First principles:** "Chaining: make the bucket hold multiple entries. Open addressing: find a different bucket for the second entry."

**(3) Bridge:** "Chaining is like a parking garage where multiple cars can park in the same 'spot' by stacking vertically. Open addressing is like driving around the parking lot until you find an empty spot."

---

### 📘 Concept Explanation

**What it is:**
Collision resolution is the strategy used when two keys produce the same bucket index (hash collision). The strategy determines how entries are stored and retrieved when they share a hash.

**The problem it solves:**
Even with a perfect hash function, the pigeonhole principle guarantees collisions when the number of possible keys exceeds the number of buckets. With a 16-bucket table and 12 entries, collisions are expected by the birthday paradox even with uniform distribution. Collision resolution makes the hash table correct and predictable despite collisions.

**How it works:**

**Separate Chaining:**
Each bucket holds a linked list (or tree) of all entries that hash to that bucket.
- Insert: compute bucket, append to bucket's list. O(1) for appending.
- Lookup: compute bucket, scan bucket's list with equals(). O(1) average (list is short), O(n) worst (all in one bucket).
- Delete: find in bucket's list, unlink. O(1) average.
- Load factor can exceed 1.0 - lists just grow longer.

```
Bucket 0: [Entry("A")] -> [Entry("K")] -> null
Bucket 1: [Entry("B")] -> null
Bucket 2: null
Bucket 3: [Entry("C")] -> [Entry("M")] -> null
```

> **Diagram walkthrough:** This diagram depicts separate chaining collision resolution. Each row is a hash bucket (array slot); entries within a bucket form a singly linked list. Bucket 0 holds a chain of A and K (both hash to 0); bucket 1 holds only B; bucket 2 is empty; bucket 3 chains C and M. The key relationship: each bucket is an independent linked list, so collision handling is delegated to list append and traversal. Edge case: if all keys hash to bucket 0, the map degrades to a single O(n) list - Java 8+ mitigates this by converting chains longer than 8 entries to a red-black tree (O(log n) worst case). Insight: Java's HashMap uses separate chaining internally, which is why `hashCode()` quality directly determines HashMap performance.

**Open Addressing:**
All entries stored in the main array. On collision, probe for an empty slot.

Linear probing: probe index = (h + i) % capacity for i = 0, 1, 2, ...
Quadratic probing: probe index = (h + i²) % capacity
Double hashing: probe index = (h + i * hash2(k)) % capacity

```
Before collision:  [ _ | A | _ | _ | _ ]
After adding B (collision at 1):
Linear: probe 2   [ _ | A | B | _ | _ ]
```

> **Diagram walkthrough:** This diagram depicts open addressing with linear probing. Reading left-to-right: A is stored at index 1 (no collision). When B also hashes to index 1, linear probing checks index 2, finds it empty, and places B there. The key relationship: all entries live in one flat array with no separate lists - collision handling is in-array probing, not pointer chasing. Edge case: when the array is heavily loaded (>70% full), probe sequences grow long; keeping load factor below 0.7 is critical to maintaining near-O(1) operations. Insight: the contiguous storage makes open addressing cache-friendly - probing moves to adjacent memory addresses, pre-loaded into the same cache line.

**The key insight:**
Open addressing is cache-friendly because probing moves sequentially through an array. Separate chaining creates pointer chains that may be anywhere in the heap - each pointer dereference is a potential cache miss. At equal theoretical complexity, open addressing has a lower constant factor for lookup.

**When to use each:**

Separate chaining:
- Load factor needs to exceed 1.0
- Delete operations are frequent (no tombstone complexity)
- Implementation simplicity matters
- Key memory overhead (node objects) is acceptable

Open addressing:
- Cache performance is critical
- Load factor can be kept below 0.7
- Simple deletion can be handled with tombstones
- Memory compactness matters (no node overhead per entry)

**When NOT to use open addressing:**
When load factor approaches 1.0 - clustering becomes severe and performance degrades sharply. Open addressing requires more aggressive resizing thresholds (typically 0.6-0.7) than separate chaining (0.75+).

**Alternatives:**
- Robin Hood hashing (open addressing variant): on collision, steal the slot from an entry that is closer to its ideal bucket than the new entry. Reduces variance in probe sequence length.
- Cuckoo hashing: two hash tables, two hash functions. Each key can be in one of two positions. On collision, evict and rehash existing entry. Guarantees O(1) worst-case lookup (not just average).

**First-principles derivation:**
When two keys land in the same array slot, you have two choices: store them at the same slot (by making the slot hold multiple entries = chaining) or store one of them at a different slot (by finding a new slot = open addressing). These are the only two options; all collision strategies are variations on one of these two approaches.

---

### 💻 Code Example

```java
// Separate chaining illustration - conceptually what
// HashMap does internally (simplified)
class SeparateChainingMap<K, V> {
    private static class Entry<K, V> {
        K key; V value; Entry<K, V> next;
        Entry(K k, V v, Entry<K, V> n) {
            key=k; value=v; next=n;
        }
    }

    private static final int BUCKETS = 16;
    @SuppressWarnings("unchecked")
    private Entry<K,V>[] table =
        (Entry<K,V>[]) new Entry[BUCKETS];

    private int bucket(K key) {
        return (key.hashCode() & 0x7FFFFFFF) % BUCKETS;
    }

    public void put(K key, V value) {
        int b = bucket(key);
        for (Entry<K,V> e = table[b]; e != null; e=e.next) {
            if (e.key.equals(key)) { // update existing
                e.value = value; return;
            }
        }
        // Prepend new entry to bucket's list
        table[b] = new Entry<>(key, value, table[b]);
    }

    public V get(K key) {
        int b = bucket(key);
        for (Entry<K,V> e = table[b]; e != null; e=e.next) {
            if (e.key.equals(key)) return e.value;
        }
        return null;
    }
}
```

> **Code walkthrough:** This is a stripped-down version of Java's HashMap internals. KEY MECHANISM: each bucket is the head of a linked list; on collision, the new entry is prepended to the list (O(1) prepend, which is why chain order is reverse insertion order); on get, we traverse the list comparing with equals(). WHY IT MATTERS: understanding the internal structure explains why HashMap's iteration order is undefined (depends on bucket distribution and prepend order) and why a bad hash function turns every operation into O(n) list traversal. WHAT BREAKS: a key class with `hashCode()` that returns 0 for all instances places all entries in bucket 0 - the entire map becomes a single linked list. TAKEAWAY: the separate chaining approach's correctness proof is simple: every entry is in exactly one bucket's list; finding it requires computing its bucket (O(1)) and traversing that list (O(average list length)).

```java
// Linear probing illustration (open addressing)
class LinearProbingMap<K, V> {
    private static final int CAP = 16;
    private static final Object TOMBSTONE = new Object();
    private Object[] keys = new Object[CAP];
    private Object[] vals = new Object[CAP];
    private int size = 0;

    private int probe(Object key) {
        int h = (key.hashCode() & 0x7FFFFFFF) % CAP;
        while (keys[h] != null && !keys[h].equals(key)) {
            h = (h + 1) % CAP; // linear probe
        }
        return h;
    }

    public void put(K key, V value) {
        int h = probe(key);
        if (keys[h] == null || keys[h] == TOMBSTONE) size++;
        keys[h] = key; vals[h] = value;
    }

    @SuppressWarnings("unchecked")
    public V get(K key) {
        int h = (key.hashCode() & 0x7FFFFFFF) % CAP;
        while (keys[h] != null) {
            if (keys[h].equals(key)) return (V) vals[h];
            h = (h + 1) % CAP;
        }
        return null; // stops at null, not tombstone
    }
}
```

> **Code walkthrough:** Open addressing stores entries directly in the main array - no per-entry object allocation. KEY MECHANISM: linear probing scans sequentially until it finds the target key or an empty slot; this sequential scan is cache-friendly because consecutive array slots are on the same or adjacent cache lines. WHY IT MATTERS: for high-frequency lookups where cache misses dominate performance (e.g., routing tables, caches, de-duplication), open addressing can be 2-3x faster than chaining despite equal theoretical complexity. WHAT BREAKS: the tombstone `TOMBSTONE` marker is essential for delete - if we set a deleted slot to null, subsequent gets that probed past this slot would stop at the null and miss valid entries further in the probe sequence. TAKEAWAY: open addressing is faster in practice for read-heavy, low-load-factor scenarios; separate chaining is simpler to implement correctly, especially for delete.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Separate chaining handles collisions by storing a linked list at each bucket. When two keys hash to the same bucket, they're both in the list. Open addressing handles collisions by finding another empty slot in the main array using a probing sequence. Java uses chaining; Python uses open addressing. Both achieve O(1) average lookup.

---

**Senior / Staff (5+ years):**
> The real-world performance difference between chaining and open addressing comes down to cache behavior. Open addressing with linear probing is L1/L2 cache-friendly - probe sequences are sequential memory accesses. Chaining with linked list nodes is cache-hostile - each node is a separate allocation at an arbitrary heap address.

> I've seen this matter in production: a routing table hot-path in a high-throughput proxy went from 40 microseconds to 12 microseconds per lookup by switching from Java's HashMap (chaining) to a custom open-addressing implementation. The theoretical complexity was identical; the cache behavior was the difference. At scale, constant factors matter as much as Big-O.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Collisions are errors that should never happen."**
Collisions are expected and normal. The birthday paradox says that with a 365-bucket table (days of year), only 23 keys are needed for a 50% chance of collision. Well-designed hash tables handle collisions gracefully; they're a design consideration, not a failure.

**Misconception 2: "Open addressing is always faster."**
Open addressing is faster at low load factors with good hash functions. At high load factors (> 0.7), clustering degrades performance significantly. Separate chaining is more tolerant of high load factors and adversarial input. Java's decision to use separate chaining was deliberate.

**Misconception 3: "Linear probing is terrible due to clustering."**
Primary clustering (long probe sequences) is a real issue with linear probing but only manifests at high load factors. Modern CPUs with large L1 caches make linear probing's cache-friendly sequential access a significant advantage that offsets clustering effects at typical load factors (0.5-0.6).

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Infinite loop in open addressing with full table**
Symptom: put() or get() hangs indefinitely.
Diagnosis: the probe sequence has visited all slots (table is full or all slots are tombstones) but hasn't found an empty slot or the key. The termination condition `keys[h] != null` loops forever when the table is full.
Fix: always resize before the table reaches 100% capacity. Track load factor and resize at 0.7 for open addressing.

**Failure 2: Incorrect get() after delete in open addressing**
Symptom: get() returns null for keys that were inserted, after some keys were deleted.
Diagnosis: delete was implemented by setting the slot to null instead of using a tombstone. This breaks probe chains for keys that were inserted after the deleted key.
Fix: implement delete with a tombstone marker. The get() probe must continue through tombstones but stop at null.

**Failure 3: Clustering causes O(n) probes**
Symptom: hash table operations are O(n) in practice, not O(1). Profile shows long probe sequences.
Diagnosis: load factor > 0.8 with linear probing. Or hash function with poor distribution causing many keys to cluster near the same initial bucket.
Fix: reduce load factor threshold. Switch to quadratic probing or double hashing to reduce primary clustering. Consider separate chaining.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 3 | chaining, open addressing, clustering |
| Debugging | 1 | tombstone/delete issues |
| Trade-off | 2 | cache vs tolerance, probing strategies |
| Behavioral | 1 | production strategy choice |

---

**[JUNIOR] Q1 - [MECHANISM] Compare separate chaining and open addressing on five dimensions.**

| Dimension | Separate Chaining | Open Addressing |
|---|---|---|
| Collision handling | Multiple entries per bucket (list) | Find alternate slot via probing |
| Cache behavior | Poor (pointer chasing) | Good (sequential probing) |
| Load factor tolerance | Can exceed 1.0 | Degrades sharply near 1.0 |
| Delete operation | Simple (unlink from list) | Complex (tombstones) |
| Memory overhead | Node objects per entry | None beyond main array |

Java's HashMap uses chaining. Python dict, Rust HashMap (before 2017), and many systems programming scenarios use open addressing.

When to prefer chaining: delete-heavy workloads, high load factors, simplicity required.
When to prefer open addressing: read-heavy workloads, memory efficiency matters, cache-sensitive performance paths.

*What separates good from great:* The delete complexity in open addressing is often underestimated. Setting a deleted slot to null breaks probe chains and causes false negatives on get(). Tombstone markers fix correctness but add space overhead and slow down get() (probing must skip tombstones). Periodic rehashing (remove all tombstones by rehashing remaining entries) is needed to prevent performance degradation in delete-heavy workloads.

---

**[JUNIOR] Q2 - [MECHANISM] What is primary clustering and how does quadratic probing reduce it?**

Primary clustering is the tendency of linear probing to create long runs of occupied slots. Once a run forms, all keys that hash to any position in the run extend it further. The more keys hash into the cluster, the longer the cluster grows - self-reinforcing.

Example with linear probing (bucket size 10, half full):
Keys hash to positions: 3, 3, 4, 3 (consecutive collisions)
Slots occupied after 4 inserts: 3, 4, 5, 6 - a cluster of 4
The 5th key hashing to 3 must probe 4 more times to find slot 7.

Quadratic probing: probe at h, h+1, h+4, h+9, h+16... (h + i²)
Keys that hash to the same initial position follow the same probe sequence (secondary clustering). But keys that hash to adjacent positions follow different sequences - they don't extend each other's clusters. Primary clustering is eliminated.

However, quadratic probing introduces secondary clustering: all keys with the same initial hash follow the exact same probe sequence. If multiple keys hash to the same bucket and all need to probe, they all probe the same slots in order.

Double hashing eliminates even secondary clustering: probe at h + i * h2(k) where h2(k) is a second hash function of the key. Different keys with the same initial hash follow different probe sequences (because h2 differs). This gives the best distribution but requires computing two hash functions.

Trade-offs: linear probing < quadratic probing < double hashing in terms of clustering. Reverse in terms of cache behavior: linear probing is most cache-friendly (sequential), double hashing is least (random jumps).

*What separates good from great:* Modern CPU hardware has changed the calculus. L1 cache miss penalty (~4 cycles) vs L2 miss (~12 cycles) vs L3 miss (~40 cycles) vs RAM miss (~200 cycles). Linear probing keeps probe sequences in the same cache line or adjacent lines. Double hashing jumps to random locations, likely causing cache misses on each probe. At small load factors (< 0.6), linear probing often wins over double hashing in benchmarks despite worse theoretical clustering, because the clustering effect rarely activates at low load.

---

**[JUNIOR] Q3 - [MECHANISM] Explain cuckoo hashing and its O(1) worst-case lookup guarantee.**

Cuckoo hashing achieves O(1) worst-case lookup (not just average) using two hash functions and two tables.

**Structure:** Two arrays T1 and T2 of size n/2 each. Two hash functions h1 and h2. Each key k can be stored at position h1(k) in T1 or h2(k) in T2.

**Lookup (O(1) worst case):** check T1[h1(k)] and T2[h2(k)]. Two memory lookups, always. If neither matches, key is absent. This is why lookup is O(1) worst case.

**Insert:** place k at T1[h1(k)]. If T1[h1(k)] is occupied by key m, evict m and place it at T2[h2(m)]. If T2[h2(m)] is occupied by key p, evict p to T1[h1(p)]. Continue this "cuckoo" eviction chain until an empty slot is found. If a cycle forms (infinite loop), rehash with new hash functions.

**Insert complexity:** O(1) expected amortized. Eviction chains are usually short. Pathological cases (cycles) require full rehash, but occur with low probability.

**Why it's called cuckoo:** like the cuckoo bird that pushes eggs out of other birds' nests, cuckoo hashing evicts existing keys to make room for new ones.

**Real-world use:** high-performance network routers (guaranteed O(1) packet forwarding table lookup), hardware lookup tables, memory-constrained systems where worst-case bounds matter.

*What separates good from great:* Cuckoo hashing's O(1) worst-case lookup makes it attractive for time-sensitive systems where tail latency matters more than average latency. In financial trading or network routing, a single O(n) lookup spike can be catastrophic. Cuckoo hashing eliminates this risk at the cost of more complex inserts and occasional rehash events. Great engineers recognize that "average O(1)" and "worst-case O(1)" are different properties with different use-case implications.

---

**[MID] Q4 - [MECHANISM] How does Java 8's HashMap change from linked list to tree per bucket?**

Java 8 introduced the treeification optimization: when a bucket's linked list grows beyond 8 entries AND the overall table has at least 64 buckets, the linked list is converted to a Red-Black tree.

**Why this matters:** With a linked list, a bucket with k entries requires O(k) scan on lookup. With a tree, it's O(log k). For adversarial input (keys engineered to collide), this changes worst-case HashMap behavior from O(n) to O(n log n) for n operations, or O(log n) per operation.

**Thresholds (from HashMap source code):**
- `TREEIFY_THRESHOLD = 8`: convert list to tree when bucket size exceeds 8
- `UNTREEIFY_THRESHOLD = 6`: convert tree back to list when size drops below 6
- `MIN_TREEIFY_CAPACITY = 64`: don't treeify if table has fewer than 64 buckets (resize instead)

**Why 8?** Statistical analysis: with a good hash function and load factor 0.75, the probability of a single bucket having 8 entries is approximately `0.00000006` - essentially impossible under normal conditions. So treeification should never trigger in well-behaved code; it's purely a defense mechanism.

**The security implication:** before Java 8, hash flooding DoS attacks could cause all HashMap operations to become O(n) by sending keys that all hash to the same bucket. Java 8's treeification made this O(n log n) - a significant but not complete mitigation. A properly randomized hash (like Rust's default SipHash) provides stronger protection.

*What separates good from great:* The `MIN_TREEIFY_CAPACITY = 64` threshold is subtle and often overlooked. If the table has fewer than 64 buckets, Java prefers to resize the table rather than treeify - resizing spreads keys across more buckets, reducing collision density. This makes sense because at small table sizes, treeification is expensive (creating tree nodes) but resizing would likely fix the collision anyway. Only at large table sizes (64+) is it more efficient to treeify than to resize.

---

**[MID] Q5 - [SCENARIO] When would you use open addressing in production Java code?**

Java's standard HashMap uses separate chaining, so using open addressing in Java requires a third-party library or custom implementation. Situations where this is worth the effort:

**1. Cache-critical lookup paths:**
In a system processing 10 million lookups per second, the cache behavior difference between chaining and open addressing is measurable. Trading systems, network packet processors, and real-time analytics systems have used custom open-addressing maps.

**2. Primitive keys to avoid boxing:**
`HashMap<Integer, V>` boxes every Integer key (16 bytes + object overhead). Eclipse Collections' `IntObjectHashMap` uses open addressing with a primitive int[] for keys - no boxing, 4x better memory, better cache behavior.

**3. Memory-constrained environments:**
Each chaining node in HashMap is a separate object: 16 bytes header + 8 bytes key ref + 8 bytes value ref + 8 bytes next pointer = 40 bytes of overhead per entry. Open addressing stores keys and values in flat arrays with no per-entry overhead.

**4. Embedded or GC-free systems:**
Java game engines, latency-sensitive financial systems, and JVM-based systems programming sometimes require GC-free data structures. Open-addressing maps with pre-allocated arrays create zero GC objects per operation.

Production libraries using open addressing: Eclipse Collections (IntObjectHashMap), HPPC (High Performance Primitive Collections), Koloboke.

*What separates good from great:* Choosing open addressing for a production system requires careful consideration of load factor management. You must trigger rehashing at a lower load factor (0.6-0.7 vs 0.75 for chaining) and handle tombstone accumulation from deletes. The performance gain is real but comes with implementation complexity that must be tested thoroughly. The "just use HashMap" default is correct for most cases; switching to open addressing is a measured optimization, not a premature one.

---

**[SENIOR] Q6 - [MECHANISM] Explain Robin Hood hashing and how it improves open addressing.**

Robin Hood hashing is an open addressing variant that reduces probe sequence variance by applying the principle: "steal from the rich (keys close to ideal), give to the poor (keys far from ideal)."

**Key concept: displacement distance.** For each stored key k, track `d(k) = current_slot - ideal_slot(k)` (modulo table size). This is how many probes were needed to place k.

**Robin Hood insert rule:** when inserting key k at probe position h, if the existing key m at h has displacement d(m) < d(k) (m is "richer" - closer to ideal), evict m and continue placing m. Insert k here.

This ensures no key's displacement can be much larger than another key's displacement. The maximum displacement is bounded (logarithmically), and average probe length is more uniform.

**Lookup improvement:** because maximum displacement is bounded, lookups can use early termination: if the current probe's displacement d(current) < d(target), the target key is absent. No need to probe to an empty slot.

**Backward shift deletion:** Robin Hood hashing enables clean deletion without tombstones. When deleting a key, shift subsequent keys backward (toward their ideal position) as long as they have displacement > 0. This restores the Robin Hood property without tombstones.

Real-world use: Rust's BTreeMap and several high-performance hash table libraries use Robin Hood hashing. Swiss Table (Google's abseil/flat_hash_map) uses a different probe strategy (SIMD-accelerated bucket comparison) that achieves similar benefits.

*What separates good from great:* Robin Hood hashing's backward shift deletion is a significant advantage over standard open addressing with tombstones. Tombstones accumulate over time (especially in delete-heavy workloads), increasing average probe length. Backward shift deletion maintains the compact, tombstone-free invariant at O(1) amortized delete cost. This makes Robin Hood hashing more practical for mixed insert/delete workloads than standard linear or quadratic probing.

---

**[SENIOR] Q7 - [SCENARIO] You're implementing a cache with 10 million entries and 1 million lookups/second. What collision resolution strategy and why?**

At 10 million entries with 1 million lookups/second, cache behavior dominates performance. Each cache miss is ~200 cycles vs ~4 cycles for an L1 hit. At 1 million lookups/second, 1 extra cache miss per lookup = 200 million extra cycles/second = ~100ms per second of lookup latency added.

**My choice: open addressing (linear probing or Robin Hood), with load factor capped at 0.6.**

Reasoning:
1. At 10 million entries in a HashMap with separate chaining, the linked list nodes are scattered across the heap. Each lookup: compute bucket (O(1)) + dereference node pointer (likely L3 miss or RAM miss) + equals() (another dereference). For 1M lookups/second, these cache misses compound.

2. Open addressing stores key-value pairs in a flat array. The probe sequence accesses consecutive array slots, which are on the same or adjacent cache lines. At 10M entries with int keys (4 bytes each), 64 consecutive keys fit in 4 cache lines. Probing 2-3 positions for a collision is still likely a cache hit for positions 2-3 after loading position 1.

3. Robin Hood hashing with linear probing caps maximum displacement at O(log n), so even occasional probing goes only 2-3 positions on average.

4. Load factor 0.6: at 60% full, expected probe length for linear probing is 1.9 (nearly O(1) in practice). At 80%, expected probe length is 5+, degrading noticeably.

Concrete implementation: Eclipse Collections IntObjectHashMap (if keys are ints) or a custom open-addressing map backed by long[] for key/value pairs. Pre-allocate for 10M / 0.6 ≈ 17M slots.

Tradeoff accepted: open addressing requires more careful load factor management and deletion with tombstones. The cache performance justifies the complexity.

*What separates good from great:* The candidate who immediately says "HashMap" is answering for the average case. The candidate who says "open addressing with load factor 0.6" is thinking about the specific access pattern: 1M lookups/second makes cache behavior the dominant factor, not code simplicity. The candidate who specifies pre-allocation, load factor cap, and tombstone strategy is reasoning from implementation constraints, not just theory.
---

### 🏛️ System Design

*(Omit: system design not applicable for ★☆☆ foundational concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

---

# HashMap vs HashSet Trade-offs

---
id: DS-009
title: HashMap vs HashSet Trade-offs
difficulty: ★☆☆
status: draft
---

### 🎯 Model Answer

**30 seconds:**
> HashMap stores key-value pairs. HashSet stores only keys - it's backed by a HashMap where every value is a dummy sentinel object. HashMap is for lookups by key returning an associated value. HashSet is for membership testing and deduplication - just "is this element present?" Both provide O(1) average for add, contains, and remove. The choice comes down to: do I need associated values, or just unique membership?

**3 minutes:**
> I think of HashSet as HashMap with the value thrown away. Internally, Java's HashSet literally wraps a HashMap<E, Object> where every put uses the same PRESENT sentinel object as the value. This means HashSet has the same performance characteristics as HashMap - O(1) add/contains/remove, same hash function requirements, same collision handling.

> The key trade-off: HashMap is for the association problem ("given a user ID, what is the user's email?") and HashSet is for the membership problem ("have I seen this transaction ID before?"). When I see code using a HashMap where the value is always Boolean.TRUE or a constant sentinel, that's a code smell - it should be a HashSet.

> The practical performance considerations: HashSet.contains() is O(1) while List.contains() is O(n). Any time I need to check "is this element in this collection?" frequently, I should use a Set, not a List. And when I need that set in sorted order (for iteration or range queries), I use TreeSet - accepting O(log n) operations for sorted semantics.

**Blank Mind Recovery:**
**(1) Restate:** "HashMap is key-to-value. HashSet is key-only, just membership."

**(2) First principles:** "Both use the same hash table mechanism. HashSet is just HashMap where you don't care about the value."

**(3) Bridge:** "HashMap is a dictionary. HashSet is a student roster - you just need to know 'is Alice enrolled?' not 'what grade does Alice have?'"

---

### 📘 Concept Explanation

**What it is:**
HashMap: a hash table storing key-value pairs. Operations: `put(k, v)`, `get(k)`, `remove(k)`, `containsKey(k)`.
HashSet: a hash table storing only unique keys (no associated values). Operations: `add(e)`, `contains(e)`, `remove(e)`.

**The problem they solve:**
HashMap solves the association problem: given a key, retrieve its associated value in O(1) time. HashSet solves the membership problem: determine whether an element is a member of a collection in O(1) time.

**How they work:**
In Java, `HashSet<E>` is implemented as `HashMap<E, Object>` with a shared dummy value (`Object PRESENT = new Object()`). Every `add(e)` is `map.put(e, PRESENT)`. Every `contains(e)` is `map.containsKey(e)`.

This implementation choice means:
- HashSet has identical performance to HashMap
- HashSet requires the same hashCode()/equals() contract
- HashSet provides no value storage (attempting to retrieve an element's "value" is meaningless)

**Comparison table:**

| Property | HashMap | HashSet |
|---|---|---|
| Stores | Key-value pairs | Keys only |
| Primary operation | `get(key)` | `contains(element)` |
| Backed by | hash table | HashMap internally |
| Null support | One null key | One null element |
| Iteration | Entry, key, or value iteration | Element iteration |
| Memory | Key ref + value ref per entry | Key ref + PRESENT ref per entry |

**The key insight:**
When you find yourself using `Map<K, Boolean>` or `Map<K, Object>` where the value is always the same, convert to `Set<K>`. The Set API makes the intent clearer and is the idiomatic Java choice.

**When to use HashMap:**
- Key-to-value association: user ID → user object, word → frequency count, cache key → cached value
- When you need both the key and an associated value

**When to use HashSet:**
- Membership testing: "have I seen this?"
- Deduplication: remove duplicates from a collection
- Set operations: union, intersection, difference
- When you only need the key, not an associated value

**Variants:**

| Structure | Order | Null key | Thread-safe |
|---|---|---|---|
| HashMap | None | 1 null key | No |
| LinkedHashMap | Insertion or access | 1 null key | No |
| TreeMap | Sorted | No null key | No |
| ConcurrentHashMap | None | No null key/value | Yes |
| EnumMap | Enum ordinal | No | No |
| HashSet | None | 1 null element | No |
| LinkedHashSet | Insertion order | 1 null | No |
| TreeSet | Sorted | No null | No |
| EnumSet | Enum ordinal | No null | No |

**First-principles derivation:**
A Set is a Map where you don't use the value. This is confirmed by Java's implementation: HashSet literally delegates to HashMap. This design choice makes sense: instead of reimplementing a hash table for Sets, reuse the Map implementation and discard the value. The cost: each Set entry allocates a key reference + a dummy PRESENT reference (vs Map's key ref + value ref). The memory overhead is identical.

---

### 💻 Code Example

```java
// Pattern: wrong structure, then correct structure

// BAD: Map<K, Boolean> when only membership needed
public class VisitedTracker_BAD {
    // Using Map with always-true value wastes space
    // and signals wrong intent to readers
    private Map<String, Boolean> visited =
        new HashMap<>();

    public void markVisited(String url) {
        visited.put(url, true); // value always true - why?
    }

    public boolean hasVisited(String url) {
        return Boolean.TRUE.equals(visited.get(url));
    }
}

// GOOD: HashSet when only membership needed
public class VisitedTracker_GOOD {
    // Clear intent: we track membership, not associations
    private Set<String> visited = new HashSet<>();

    public void markVisited(String url) {
        visited.add(url);
    }

    public boolean hasVisited(String url) {
        return visited.contains(url); // O(1)
    }
}
```

> **Code walkthrough:** The BAD version is a code smell seen in production Java code - it reveals the developer didn't know about Set or chose Map out of habit. KEY MECHANISM: both have identical O(1) performance because HashSet wraps HashMap; the difference is clarity of intent, reduced memory (no explicit Boolean value per entry - though internally HashSet also uses a PRESENT sentinel), and idiomatic API usage. WHY IT MATTERS: code reviews catch this pattern as a clarity issue; use the structure that best communicates intent, not just the one that works. WHAT BREAKS: the BAD version's `Boolean.TRUE.equals(visited.get(url))` is also redundant - `visited.getOrDefault(url, false)` would suffice, but neither pattern is idiomatic. TAKEAWAY: when the value in your Map is always a constant or Boolean.TRUE, replace it with a Set.

```java
// Set operations: union, intersection, difference
public class SetOperations {
    // Set union: all elements from both sets
    public <T> Set<T> union(Set<T> a, Set<T> b) {
        Set<T> result = new HashSet<>(a); // copy a
        result.addAll(b);                 // add all of b
        return result; // O(|a| + |b|)
    }

    // Set intersection: elements in both sets
    public <T> Set<T> intersection(Set<T> a, Set<T> b) {
        Set<T> result = new HashSet<>(a);
        result.retainAll(b); // keep only elements in b
        return result; // O(min(|a|, |b|))
    }

    // Set difference: elements in a but not in b
    public <T> Set<T> difference(Set<T> a, Set<T> b) {
        Set<T> result = new HashSet<>(a);
        result.removeAll(b); // remove elements that are in b
        return result; // O(|a| + |b|)
    }

    // Check if a is a subset of b
    public <T> boolean isSubset(Set<T> a, Set<T> b) {
        return b.containsAll(a); // O(|a|) with HashSet b
    }
}
```

> **Code walkthrough:** These set operations are building blocks for many practical algorithms. KEY MECHANISM: `retainAll(b)` on a HashSet iterates `a` and removes each element not in `b`; because `b` is a HashSet, each `contains(element)` in the inner check is O(1), making the overall `retainAll` O(|a|) rather than O(|a|*|b|) as it would be with a List. WHY IT MATTERS: finding common elements between two collections (intersection) is a frequent operation in data processing; using sets makes it O(n) instead of O(n²). WHAT BREAKS: `retainAll` modifies `a` in-place - if you need the original `a`, always copy first (`new HashSet<>(a)`). TAKEAWAY: Java's Set API provides union (addAll), intersection (retainAll), and difference (removeAll) as built-in operations; these are O(n) with HashSet backends and O(n²) with List backends.

```java
// Frequency counting: canonical HashMap use case
public Map<String, Long> countWords(List<String> words) {
    Map<String, Long> freq = new HashMap<>();
    for (String word : words) {
        freq.merge(word, 1L, Long::sum);
        // merge(): if key absent, set to 1L
        //          if key present, apply Long::sum to old+new
    }
    return freq; // O(n), word count in O(1) per word
}

// Deduplication while preserving order: LinkedHashSet
public List<String> deduplicateOrdered(List<String> items) {
    // LinkedHashSet: O(1) membership + insertion order
    Set<String> seen = new LinkedHashSet<>(items);
    return new ArrayList<>(seen);
    // Preserves first-occurrence order, removes duplicates
}

// Top-K frequent elements: HashMap + PriorityQueue
public List<String> topK(List<String> words, int k) {
    Map<String, Integer> freq = new HashMap<>();
    for (String w : words) {
        freq.merge(w, 1, Integer::sum);
    }
    // Min-heap of size k: keeps top-k highest frequencies
    PriorityQueue<Map.Entry<String, Integer>> heap =
        new PriorityQueue<>(
            Comparator.comparingInt(Map.Entry::getValue)
        );
    for (Map.Entry<String, Integer> e : freq.entrySet()) {
        heap.offer(e);
        if (heap.size() > k) heap.poll(); // evict minimum
    }
    List<String> result = new ArrayList<>();
    while (!heap.isEmpty()) result.add(0,
        heap.poll().getKey()); // reverse order
    return result; // O(n log k)
}
```

> **Code walkthrough:** These three patterns cover the most common HashMap/HashSet use cases in practice. KEY MECHANISM: `Map.merge()` is the idiomatic Java 8+ way to increment a counter - it handles the "key absent = initialize" case and "key present = update" case in one atomic call, replacing the verbose `getOrDefault` + `put` pattern. WHY IT MATTERS: frequency counting, deduplication with order preservation, and top-K selection are the most common analytical operations in backend systems; knowing the idiomatic patterns for each saves time and reduces bugs. WHAT BREAKS: `deduplicateOrdered` creates a new Set from the List constructor - O(n) operation, O(n) space - this is the correct approach but mutates nothing in the original list. TAKEAWAY: `Map.merge(key, 1, Integer::sum)` is the canonical one-liner for frequency counting and should be memorized; it replaces 3-4 lines of conditional code.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> HashMap stores key-value pairs. HashSet stores only unique keys. HashSet.contains() is O(1) while List.contains() is O(n) - that's the main practical difference I use it for. When I need to check if I've seen something before, I use a HashSet. When I need to look up a value by key, I use a HashMap.

---

**Senior / Staff (5+ years):**
> The Map/Set family decision tree I follow: if I need key-value association → Map. If I need sorted key iteration or range queries → TreeMap. If I need insertion order → LinkedHashMap. If I need thread safety with high throughput → ConcurrentHashMap. If I only need membership → Set. If I need membership in sorted order → TreeSet. If I need membership in insertion order → LinkedHashSet.

> At production scale I'm also careful about EnumMap and EnumSet. If keys are enum values, EnumMap uses an array indexed by enum ordinal - O(1) with a much smaller constant than HashMap (no hashing, no collision). EnumSet uses a bitmask. For small, fixed key domains (like feature flags, roles, permission bits), these are 10x more memory-efficient than their general-purpose equivalents.

---

### ⚠️ Common Misconceptions

**Misconception 1: "HashSet has better performance than HashMap."**
No. HashSet is implemented as HashMap<E, Object>. They have identical performance. The difference is API semantics - Set doesn't expose value retrieval because there's no meaningful value. The memory overhead is identical (key ref + PRESENT ref per entry = key ref + value ref per entry).

**Misconception 2: "LinkedHashMap is significantly slower than HashMap."**
LinkedHashMap maintains a doubly-linked list through all entries in insertion order. Each put/remove updates the list (O(1) pointer updates). The overhead is constant per operation - not asymptotically worse. In practice, LinkedHashMap is ~10-20% slower than HashMap due to the additional pointer updates, not a fundamental scalability difference.

**Misconception 3: "TreeMap and TreeSet are rarely useful."**
Very common in production. Any time you need sorted keys, range queries, closest-neighbor lookups, or ordered iteration, TreeMap/TreeSet is the right choice. Use cases: leaderboards, range-based rate limiters, time-series buckets, ordered event queues, sliding window statistics.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Using List.contains() inside a loop instead of Set**
Symptom: endpoint latency grows quadratically with input size.
Diagnosis: profile shows `AbstractList.indexOf` in the flame graph on a hot path.
Fix: convert the list to a HashSet before the loop. `Set<T> set = new HashSet<>(list)` is O(n) once; every `set.contains()` is O(1) after that.

**Failure 2: HashMap iteration while modifying**
Symptom: `ConcurrentModificationException` during iteration.
Diagnosis: code modifies the map (put/remove) inside a `for(Map.Entry e : map.entrySet())` loop.
Fix: collect modifications in a separate list and apply after the loop, or use `map.entrySet().removeIf(...)`, or use `forEach` with `Map.compute/merge` for updates.

**Failure 3: ConcurrentHashMap.computeIfAbsent for side-effectful computation**
Symptom: unexpected behavior or deadlock when `computeIfAbsent` lambda itself calls `computeIfAbsent` on the same map.
Diagnosis: ConcurrentHashMap.computeIfAbsent acquires a segment lock during computation. If the lambda tries to acquire the same or another lock, deadlock is possible.
Fix: avoid recursive computeIfAbsent on the same map. Compute the value before calling computeIfAbsent.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | Map vs Set, variant selection |
| Trade-off | 2 | linked/tree variants, concurrent variants |
| Debugging | 1 | concurrent modification |
| Behavioral | 2 | production variant choices |

---

**[JUNIOR] Q1 - [SCENARIO] When would you choose LinkedHashMap over HashMap?**

LinkedHashMap adds one capability over HashMap: it maintains iteration order. There are two modes: insertion order (default) and access order (set with `accessOrder=true` in the constructor).

**Insertion order use cases:**
- Returning map contents in the order keys were added (e.g., configuration keys in the order they were parsed)
- Building a JSON object where key order matters (JSON spec doesn't require order, but some consumers depend on it)
- Predictable test output (HashMap iteration order varies across JVM runs)

**Access order use cases (LRU cache):**
With `accessOrder=true`, every `get()` and `put()` moves the accessed entry to the end of the iteration order. Override `removeEldestEntry()` to evict the head (oldest accessed) when size exceeds capacity. This is Java's built-in LRU cache implementation.

```java
Map<Integer, User> lruCache = new LinkedHashMap<>(
    16, 0.75f, true) { // accessOrder=true
  @Override
  protected boolean removeEldestEntry(
      Map.Entry<Integer, User> e) {
    return size() > 1000; // keep last 1000 accessed
  }
};
```

> **Code walkthrough:** This snippet creates a fixed-capacity access-ordered LinkedHashMap that functions as an LRU cache. The KEY MECHANISM: `accessOrder=true` reorders entries on every `get()` or `put()` call (most recent at tail); `removeEldestEntry()` returns true when size exceeds 1000, triggering automatic eviction of the head entry (least recently accessed). WHY IT MATTERS: 5 lines of Java vs 30+ for a manual HashMap+DoublyLinkedList LRU implementation; both are O(1) amortized. WHAT BREAKS: using default `accessOrder=false` gives FIFO eviction (insertion order), not LRU; forgetting this flag is the most common LinkedHashMap misuse. TAKEAWAY: `new LinkedHashMap<>(cap, 0.75f, true)` + `removeEldestEntry()` is the canonical Java LRU cache - know this cold for interviews.

Performance overhead: ~10-20% slower than HashMap due to additional doubly-linked list pointer updates on each modification. Acceptable for most use cases.

*What separates good from great:* The LRU cache pattern is the most important use case for LinkedHashMap. Great engineers know this built-in before reaching for Guava's Cache or manually implementing linked list + HashMap. However, LinkedHashMap is not thread-safe - for a concurrent LRU cache, you'd need external synchronization or a purpose-built solution like Caffeine.

---

**[JUNIOR] Q2 - [SCENARIO] When would you choose ConcurrentHashMap over HashMap?**

ConcurrentHashMap is the right choice whenever multiple threads read from or write to the same map.

**Why not `Collections.synchronizedMap(new HashMap())`?** synchronizedMap wraps the entire map with a single lock. Every operation (including reads) acquires the same lock. Under high read concurrency, all readers queue up for the single lock - throughput is limited to what one thread can do at a time.

**ConcurrentHashMap's approach:**
Pre-Java 8: divided the map into segments (default 16), each with its own lock. Up to 16 concurrent writers.
Java 8+: lock-free reads using volatile + CAS for updates. Writers lock only the specific bucket being modified. Read operations never block.

**Result:** ConcurrentHashMap allows many concurrent readers at full speed and multiple concurrent writers. Throughput scales with the number of CPU cores.

**Key ConcurrentHashMap-specific methods:**
- `putIfAbsent(k, v)`: atomic "insert if not present" - avoids race between containsKey and put
- `computeIfAbsent(k, fn)`: atomic "compute and store if not present" - used for lazy initialization
- `merge(k, v, fn)`: atomic "update or insert" - used for atomic counters

**When NOT to use ConcurrentHashMap:** single-threaded code. Its atomicity mechanisms add overhead. If a map is only ever accessed from one thread, HashMap is faster.

*What separates good from great:* ConcurrentHashMap's `computeIfAbsent` is powerful but has a subtle danger: the mapping function is called while holding a segment lock. If the function is slow or tries to access the same map, it can cause contention or deadlock. For expensive computations, compute the value BEFORE calling computeIfAbsent and pass it as a pre-computed value.

---

**[JUNIOR] Q3 - [TRADE-OFF] What is the difference between HashMap, Hashtable, and Properties?**

This question tests Java history and backward compatibility knowledge.

**Hashtable (Java 1.0):** Synchronized on every method. Methods include `get`, `put`, `remove`, `contains`, `keys`, `elements`. Doesn't allow null keys or values (throws NullPointerException). Extends Dictionary (abstract class), not AbstractMap. Legacy API - rarely used in new code.

**HashMap (Java 1.2):** Not synchronized. Allows one null key, multiple null values. Implements Map interface. Extends AbstractMap. The modern, preferred general-purpose map.

**Properties (Java 1.0):** Extends Hashtable. Key-value pairs where both keys and values are Strings. Supports loading from and saving to `.properties` files. Has `getProperty()`, `setProperty()`, `load()`, `store()` methods. Used for application configuration.

**Why Hashtable is obsolete:**
The synchronized methods use a coarse object-level lock - effectively single-threaded for concurrent access. ConcurrentHashMap achieves actual concurrent access with much higher throughput. Hashtable's API also leaks implementation details (the `elements()` and `keys()` methods return Enumeration, the pre-Iterator legacy interface).

Migration path: `Hashtable` → `HashMap` (single-threaded) or `ConcurrentHashMap` (multi-threaded). `Properties` remains in use because it has no direct modern equivalent for file-based property loading.

*What separates good from great:* Great engineers know when to use Properties vs externalized configuration systems (Spring's @Value, Quarkus config, Kubernetes ConfigMaps). For simple standalone applications, Properties files remain a legitimate choice. For distributed systems or cloud deployments, externalized configuration (12-factor app principle) is the pattern: configuration lives in environment variables or config services, not bundled .properties files.

---

**[MID] Q4 - [MECHANISM] How does Java's EnumMap outperform HashMap for enum keys?**

EnumMap uses an array indexed by enum ordinal (the position of the enum constant in its declaration). No hashing, no collision resolution - just direct array access.

```java
enum Status { PENDING, PROCESSING, COMPLETE, FAILED }

// EnumMap: backed by Status[4] - one array slot per value
EnumMap<Status, List<Order>> ordersByStatus =
    new EnumMap<>(Status.class);

// vs HashMap: backed by hash table with Object[] entries
Map<Status, List<Order>> hashMap = new HashMap<>();
```

> **Code walkthrough:** This snippet compares `EnumMap<Status, List<Order>>` with `HashMap<Status, List<Order>>`. The KEY MECHANISM: `EnumMap` internally uses a plain array indexed by `enum.ordinal()` - a `get()` is a single `array[key.ordinal()]` access with zero hash computation, no bucket resolution, no boxing. WHY IT MATTERS: for enum-keyed maps (which are extremely common in domain objects like Status, Category, Priority), EnumMap is measurably faster and more memory-efficient. WHAT BREAKS: `EnumMap` only works with enum keys; attempting to use it with non-enum types is a compile error. TAKEAWAY: when your map key is an enum, always prefer `EnumMap` - it is the single most commonly overlooked performance optimization for business logic maps.

**Performance advantages:**
- get(): `array[key.ordinal()]` - one array access, zero hash computation
- put(): same array access
- Iteration: linear array scan in enum declaration order - cache-friendly

**Memory advantages:**
- EnumMap<Status, V>: 4 references (one per Status value)
- HashMap<Status, V>: hash table overhead (~32+ bytes per entry, plus internal array)

For 4 enum values: EnumMap ≈ 32 bytes total. HashMap ≈ 200+ bytes.

**Null key:** EnumMap doesn't allow null keys (ordinal() would NPE). HashMap allows one null key.

**EnumSet:** similar principle for a Set of enum values. Uses a `long` bitmask (up to 64 enum values fit in one long). `contains()` is a bitwise AND - one CPU instruction. `add()` is a bitwise OR. Memory: 8 bytes for the entire set regardless of how many elements are in it.

**Real-world use:** permission systems (`Set<Permission>` where Permission is an enum), state machines (`Map<State, List<Transition>>`), routing tables with fixed category counts.

*What separates good from great:* EnumSet with permission checks is a beautiful pattern: `if (user.getPermissions().contains(Permission.ADMIN))` is a single bitwise AND when permissions is an EnumSet. Compared to a `HashSet<Permission>` (multiple hash lookups, object comparisons), this is orders of magnitude faster - not that the difference matters for one check, but in a hot authorization path called millions of times per second, the constant factor is the entire performance story.

---

**[MID] Q5 - [DESIGN] Design a cache that evicts the least-frequently-used (LFU) entry. What structures would you use?**

LFU cache: on capacity exceeded, evict the entry that has been accessed the fewest times total (ties broken by least recently used).

**Required operations in O(1):**
- `get(key)`: return value, increment key's access count
- `put(key, value)`: insert (evict LFU entry if full)

**Data structures needed:**
1. `HashMap<K, V>` keyToValue: key → value lookup
2. `HashMap<K, Integer>` keyToFreq: key → access count
3. `HashMap<Integer, LinkedHashSet<K>>` freqToKeys: frequency → ordered set of keys with that frequency
4. `int minFreq`: track current minimum frequency

**Algorithm:**
- `get(k)`: look up value, increment keyToFreq[k], update freqToKeys, update minFreq if freqToKeys[minFreq] becomes empty
- `put(k, v)`: if full, evict the head of freqToKeys[minFreq] (oldest entry with lowest frequency). Insert with frequency 1. Set minFreq = 1.

All operations are O(1) because: HashMap lookups are O(1); LinkedHashSet insertion/deletion/head-access are O(1); the data structures are kept consistent in O(1) per operation.

The LinkedHashSet at each frequency level maintains insertion order, so among keys with the same frequency, we can always evict the least recently added (LRU among same frequency).

*What separates good from great:* LFU cache design requires correctly maintaining the minimum frequency across all operations. The key insight: after a put(), the new entry has frequency 1, so minFreq becomes 1. After a get(), if the entry's old frequency was minFreq and freqToKeys[minFreq] is now empty, minFreq increments by 1. Getting this update logic right in all cases separates candidates who understand the invariant from those who know the structure but get the transitions wrong.

---

**[SENIOR] Q6 - [TRADE-OFF] What is the memory layout difference between HashMap<String, Integer> and a primitive int[] array?**

This question probes deep understanding of JVM memory representation.

**HashMap<String, Integer> with n entries:**
- HashMap object: ~48 bytes header + metadata
- Internal Object[] table: 8 bytes per bucket reference × table_capacity
- Per entry: HashMap.Node object (~32 bytes) = 16 header + 8 key ref + 8 value ref
- Per String key: ~40-56 bytes = 16 header + 4 length + 4 hash + 16 char[] or compacted bytes
- Per Integer value: 16 bytes = 16 header (value stored in header with int compression)

Total for 1000 entries: approximately 1000 × (32 + 48 + 24) = ~100KB + table overhead

**int[] with n entries:**
- int[] object: 16 bytes header + 4 bytes length + 4 bytes × n
- 1000 entries: 16 + 4 + 4000 = ~4KB

The ratio: ~25x more memory for HashMap vs int[].

Practical implications:
1. CPU cache: int[1000] = 4KB fits entirely in L2 cache. HashMap with 1000 entries = ~100KB, spans many cache lines, with pointer chasing to String and Integer objects scattered in heap.
2. GC pressure: int[1000] = 1 GC-tracked object. HashMap with 1000 entries = 1 map + 1 table array + 1000 nodes + 1000 strings + ~1000 Integer objects = ~3001+ GC objects.

This is why performance-critical Java code (game engines, trading systems, numerical computation) uses primitive arrays directly or specializes collections (Eclipse Collections, HPPC) that use primitive backing arrays.

*What separates good from great:* Great engineers know that JVM Integer caches values from -128 to 127. `Integer.valueOf(5)` returns a cached object; `Integer.valueOf(1000)` allocates a new object. For HashMap<String, Integer> used for counting (where values could be large), most values will NOT benefit from Integer cache, meaning each unique value count allocates a new Integer. `Map.merge(key, 1, Integer::sum)` will allocate a new Integer every time the count exceeds 127. For high-throughput counters, use `int[]` or specialized primitive maps.

---

**[SENIOR] Q7 - [MECHANISM] You need to deduplicate 10 million strings while preserving first-occurrence order. What is the most efficient approach?**

Requirements: deduplicate 10M strings, preserve insertion order, time and space efficient.

**Option 1 - LinkedHashSet (O(n) time, O(n) space):**
```java
List<String> dedup(List<String> input) {
    return new ArrayList<>(new LinkedHashSet<>(input));
}
```

> **Code walkthrough:** This snippet deduplicates a list while preserving insertion order using `LinkedHashSet`. The KEY MECHANISM: constructing `LinkedHashSet` from a `List` eliminates duplicates (Set contract) while maintaining the order of first occurrence (LinkedHashSet's insertion-order property); wrapping in `ArrayList` returns the result as a list. WHY IT MATTERS: O(n) time and O(n) space - single pass through the data with O(1) average `add()`. WHAT BREAKS: using `HashSet` instead of `LinkedHashSet` loses the original insertion order. TAKEAWAY: `new ArrayList<>(new LinkedHashSet<>(list))` is the idiomatic one-liner for order-preserving deduplication.

LinkedHashSet maintains insertion order (first occurrence) and O(1) contains/add. At 10M strings, each string in the set is an Object reference (~8 bytes) + String object (~40 bytes). Total: ~500MB for 10M strings (assuming ~50 chars average length).

**Option 2 - Streaming (same complexity, cleaner code):**
```java
List<String> dedup(List<String> input) {
    return input.stream().distinct().collect(
        Collectors.toList()
    );
}
// Stream.distinct() uses LinkedHashSet internally
```

> **Code walkthrough:** This snippet uses Java Streams to deduplicate preserving encounter order. The KEY MECHANISM: `stream().distinct()` internally uses a `LinkedHashSet` to track seen elements and filters out subsequent occurrences - semantically identical to the explicit LinkedHashSet approach. WHY IT MATTERS: the stream version is more composable - you can chain `filter()`, `map()`, `limit()` in the same pipeline. WHAT BREAKS: `distinct()` maintains state and is not safely parallelizable with `parallelStream()` when order preservation matters. TAKEAWAY: prefer `stream().distinct()` when chaining operations; use the explicit `LinkedHashSet` constructor when deduplication is the only operation - it's clearer in intent.

**Option 3 - External sort + merge (if memory is constrained):**
For 10M long strings that don't fit in memory: sort into a temp file, then merge-deduplicate in one pass. O(n log n) time, O(1) working memory beyond the sort file. Only relevant if strings are very long (multi-KB) and memory is constrained.

**Optimal choice:** LinkedHashSet (Option 1 or 2). It's O(n) time, one pass, preserves first-occurrence order, and 500MB is manageable on modern servers with 16-64GB RAM.

**Micro-optimization:** pre-size the LinkedHashSet to avoid rehashing: `new LinkedHashSet<>(10_000_000, 0.75f)`. This pre-allocates capacity for 10M entries and avoids the ~23 resize operations that would occur with default initial capacity 16.

*What separates good from great:* The pre-sizing optimization matters at 10M entries. With default capacity 16, LinkedHashSet resizes ~23 times (each time doubling and copying all entries). Pre-sizing to the expected count eliminates all resizing. For 10M entries, that's avoiding ~10M copy operations from the final resize alone. The formula: `new LinkedHashSet<>(n / loadFactor + 1)` = `new LinkedHashSet<>(13_333_334)`.
---

### 🏛️ System Design

*(Omit: system design not applicable for ★☆☆ foundational concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*

