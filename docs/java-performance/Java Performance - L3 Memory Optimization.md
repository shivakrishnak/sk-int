---
layout: default
title: "Java Performance - L3 Memory Optimization"
parent: "Java Performance"
nav_order: 4
permalink: /java-performance/l3-memory-optimization/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Object Allocation Optimization](#object-allocation-optimization) | high |
| 2 | [String Memory Optimization](#string-memory-optimization) | high |
| 3 | [Collection Sizing and Pre-allocation](#collection-sizing-and-pre-allocation) | medium |
| 4 | [Off-Heap Memory Management](#off-heap-memory-management) | high |
| 5 | [Garbage Collection Tuning](#garbage-collection-tuning) | high |

---

# Object Allocation Optimization

**Interview Weight:** high - High-impact optimization.
Reducing allocation lowers GC pressure, reduces pauses, and
improves throughput.

---

### 🎯 Model Answer

**30 seconds:**

> Every object allocation is eventually a GC event. Reducing
> allocation in hot paths is the most impactful JVM performance
> optimization. Techniques: object pooling (reuse expensive objects),
> escape analysis exploitation (JIT stack-allocates non-escaping
> objects), value types (Project Valhalla), and switching from
> heap to primitive types. Profile allocation with JFR
> `jdk.ObjectAllocationInNewTLAB` before optimizing.

**3 minutes (Senior):**

> **Allocation optimization strategies:**
>
> **1. Avoid allocation in hot paths:**
> Hot path = called >10k times per second. Every `new Object()` in
> a hot path contributes to GC. Most impactful: avoid String
> concatenation, avoid boxing primitives, avoid creating DTOs
> for intermediate transformations.
>
> **2. Object pooling:**
> For expensive-to-create objects: DB connections, threads,
> ByteBuffers. Pool reuses instances instead of allocating.
> Use `commons-pool2` or `HikariCP` patterns.
> Risk: forgetting to return objects to the pool, state leakage
> between uses. Always clear state before pooling.
>
> **3. ThreadLocal caches:**
> Thread-local objects avoid contention and allocation.
> Pattern: `ThreadLocal<StringBuilder>` for format buffers.
> Risk: must `remove()` in finally to prevent leaks in
> thread pool threads.
>
> **4. Escape analysis by the JIT:**
> Objects that do not escape a method (not returned, not stored
> in fields) are candidates for stack allocation or scalar
> replacement by C2. Keep hot objects method-local and small
> to maximize this optimization.
>
> **5. Primitives over wrappers:**
> `int` (0 bytes overhead) vs `Integer` (16 bytes header + 4 bytes value).
> Use `int[]` instead of `List<Integer>` for large numeric datasets.
> Libraries: Eclipse Collections, HPPC for primitive collections.

---

### 💻 Code Example

**Example 1: Allocation reduction patterns**

```java
// PATTERN 1: StringBuilder ThreadLocal (avoid String alloc in hot path)

// BAD: String concat in hot path (creates 2 new Strings per call)
String buildKey(String prefix, int id) {
    return prefix + ":" + id;  // Two new String objects per call
}
// At 50k RPS: 100k String objects/second → significant GC load

// GOOD: ThreadLocal StringBuilder (zero allocation per call)
private static final ThreadLocal<StringBuilder> KEY_BUILDER =
    ThreadLocal.withInitial(() -> new StringBuilder(64));

String buildKey(String prefix, int id) {
    StringBuilder sb = KEY_BUILDER.get();
    sb.setLength(0);                // reset (no allocation)
    sb.append(prefix).append(':').append(id);
    return sb.toString();           // one allocation (the result)
}

// PATTERN 2: Avoid boxing in hot path
// BAD: Map<Long, Integer> boxes every key/value
Map<Long, Integer> scores = new HashMap<>();
scores.put(userId, score);  // boxes Long + Integer each time
int s = scores.get(userId); // unboxes: auto-Integer → int

// GOOD: Eclipse Collections primitive map
import org.eclipse.collections.api.map.primitive.MutableLongIntMap;
MutableLongIntMap scores = new LongIntHashMap();
scores.put(userId, score);  // long and int, no boxing
int s = scores.get(userId); // no unboxing

// PATTERN 3: Object pooling (ByteBuffer for I/O)
// BAD: allocate ByteBuffer per request
void sendResponse(Response resp) {
    ByteBuffer buffer = ByteBuffer.allocate(4096);  // heap alloc
    resp.encode(buffer);
    channel.write(buffer);
}

// GOOD: pool and reuse ByteBuffers
ObjectPool<ByteBuffer> pool = new GenericObjectPool<>(
    new BasePooledObjectFactory<>() {
        @Override
        public ByteBuffer create() { return ByteBuffer.allocate(4096); }
        @Override
        public PooledObject<ByteBuffer> wrap(ByteBuffer buf) {
            return new DefaultPooledObject<>(buf);
        }
        @Override
        public void passivateObject(PooledObject<ByteBuffer> p) {
            p.getObject().clear();  // reset state before returning to pool
        }
    }
);

void sendResponse(Response resp) throws Exception {
    ByteBuffer buffer = pool.borrowObject();
    try {
        resp.encode(buffer);
        channel.write(buffer);
    } finally {
        pool.returnObject(buffer);  // ALWAYS return in finally
    }
}
```

> **Code walkthrough:** The ThreadLocal StringBuilder pattern
> trades one per-thread allocation (on first use) for zero
> allocations on subsequent calls. At 50k RPS, this saves 100k
> String allocations per second - measurable in JFR allocation
> profiling. The primitive map eliminates boxing overhead entirely.
> The ByteBuffer pool must `clear()` in `passivateObject` to
> reset position/limit state - forgetting this causes subtle bugs
> where pooled buffers carry state from previous use.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Reduce allocation in hot paths: avoid String + in loops, use
> primitives instead of wrappers, pool expensive objects. Profile
> allocation with JFR before optimizing.

---

**Senior / Staff (5+ years):**

> Object pooling is only worthwhile when construction cost exceeds
> pool management overhead, AND when objects are actually
> expensive to create (DB connections, direct ByteBuffers).
> For most domain objects, let GC handle them - pooling adds
> complexity. Focus on the JFR allocation hotspots.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "When is object pooling worth the added complexity?"

🗣️ "Object pooling is worth it when three conditions are met:
(1) The object is expensive to create - measuring >1 microsecond
for construction. Thread creation (~1ms), direct ByteBuffer
allocation, DB connection establishment (~10-100ms) all qualify.
(2) The object is created frequently in hot paths. A 1ms object
created 10 times per request at 1000 RPS = 10,000 constructions
per second = 10 seconds of CPU per second wasted.
(3) The object can be safely reset between uses with clear state.
If state cleanup is complex or error-prone, pooling introduces
subtle bugs. The risks: forgetting to return the object (resource
leak), not clearing state (data leakage between requests), thread
safety of the pool itself. For simple domain objects (DTOs, small
collections), pooling is never worth it - the JVM's young generation
GC handles these efficiently. Let GC do its job; pool only when
GC cannot solve the allocation rate."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | ThreadLocal pattern, escape analysis, primitive collections. |
| Hiring Manager   | When to pool, when not to. Pragmatic trade-offs. |
| Bar Raiser       | Project Valhalla value types, TLAB sizing, Eden region. |
| Peer Engineer    | "ByteBuffer pooling cut our p99 latency by 30% in our serialization layer..." |

---

---

# String Memory Optimization

**Interview Weight:** high - Strings are the #1 object type
in most Java applications. Optimizing String usage is high-impact.

---

### 🎯 Model Answer

**30 seconds:**

> Strings are often the largest memory consumer in Java heaps.
> Key optimizations: avoid String concatenation with `+` in loops
> (use StringBuilder), use parameterized logging (avoid building
> String when log level is off), intern frequently repeated strings
> (-XX:+UseStringDeduplication for G1GC), and use `char[]` or
> `byte[]` for protocol parsing instead of creating String objects.

**3 minutes (Senior):**

> **String memory model (Java 9+):**
> Java 9+ uses compact strings: if all characters are Latin-1
> (bytes 0-255), a String uses 1 byte per character. Otherwise
> UTF-16 (2 bytes per character). This halves the memory for most
> ASCII content.
>
> **String deduplication (G1GC + ZGC):**
> `-XX:+UseStringDeduplication` (G1GC): during GC, identical
> String content is detected and the char arrays are shared.
> One `String` object per unique value instead of N.
> Use case: parsing JSON where many requests carry the same
> field names. Overhead: GC does deduplication during the
> concurrent phase.
>
> **String interning:**
> `String.intern()` returns a canonical reference from the
> string pool. If the same string value appears many times
> (user agents, currency codes, status strings), interning
> ensures only one copy exists in memory.
> Risk: string pool uses Metaspace. Excessive interning can
> cause Metaspace OOM. Use a bounded Guava `Interner` instead
> of the JVM's unbounded pool.
>
> **Charset encoding:**
> `new String(bytes, "UTF-8")` vs `new String(bytes, StandardCharsets.UTF_8)`.
> Constant `StandardCharsets.UTF_8` avoids a charset lookup per
> call. Minor but measurable in high-throughput parsing.

---

### 💻 Code Example

**Example 1: String optimization patterns**

```java
// PATTERN 1: StringBuilder for concatenation in loops
// BAD: O(n^2) allocation
String csv = "";
for (String item : items) {
    csv = csv + item + ",";  // new String per iteration
    // n=10,000: creates 20,000 String objects, totaling 250MB
}

// GOOD: StringBuilder - O(n)
StringBuilder sb = new StringBuilder(items.size() * 20);  // pre-size hint
for (String item : items) {
    sb.append(item).append(',');
}
String csv = sb.toString();  // single allocation for the result

// PATTERN 2: String deduplication for repeated content
// Enable for G1GC:
// -XX:+UseStringDeduplication
// Benefit: if 100k HTTP requests each carry the header
//   "Content-Type: application/json",
//   only one copy of "Content-Type" and "application/json" lives in heap

// PATTERN 3: Bounded String interning (Guava)
// BAD: unbounded JVM intern pool → Metaspace OOM
String status = rawStatus.intern();  // grows Metaspace unboundedly

// GOOD: bounded Interner
private static final Interner<String> STATUS_INTERNER =
    Interners.newWeakInterner();  // entries GC'd when no external reference

String status = STATUS_INTERNER.intern(rawStatus);
// Only holds entries weakly - GC can reclaim; bounded automatically

// PATTERN 4: Avoid String for byte parsing
// BAD: create String just to check prefix
if (header.startsWith("Authorization")) { ... }
// header may be a large String built from byte[]

// GOOD: parse bytes directly (HTTP/2 parsing style)
boolean startsWithAuthorization(byte[] buf, int offset, int length) {
    final byte[] AUTH = "Authorization".getBytes(StandardCharsets.US_ASCII);
    if (length < AUTH.length) return false;
    for (int i = 0; i < AUTH.length; i++) {
        if (buf[offset + i] != AUTH[i]) return false;
    }
    return true;
    // Zero String allocation for the check
}
```

> **Code walkthrough:** The StringBuilder pre-sizing hint
> (`items.size() * 20`) avoids internal array resizes during
> append operations. Each resize doubles the array and copies -
> providing a size hint eliminates those allocations. String
> deduplication is free for applications already using G1GC.
> The byte-level parsing pattern eliminates String allocation
> for protocol header inspection - used in Netty, Undertow,
> and all high-performance HTTP servers.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Use StringBuilder for loops, parameterized logging to avoid
> unused String building, and `-XX:+UseStringDeduplication` with
> G1GC for applications with many repeated strings.

---

**Senior / Staff (5+ years):**

> String optimization order: (1) fix allocations in hot paths
> first (JFR shows you exactly which strings are created most).
> (2) Enable deduplication for G1GC - zero code change, free
> memory reduction for content-heavy apps. (3) Use bounded
> interning for frequently repeated domain values (status codes,
> user agents). Never use `String.intern()` directly - it's
> unbounded.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "Your service handles JSON APIs and heap is 60% Strings.
  How would you reduce String memory?"

🗣️ "Three approaches in order of effort: (1) Enable
`-XX:+UseStringDeduplication` (G1GC). JSON field names appear
in every response object - 'id', 'name', 'status', 'createdAt'.
With deduplication, each unique field name string shares its
character array. One JVM flag, zero code change. Typical 20-40%
String memory reduction for JSON APIs. (2) Check if the application
is retaining parsed objects. If a cache holds deserialized JSON
objects indefinitely, the String fields are retained too. Review
cache eviction policies. (3) Consider using byte[]-based formats
for internal services: Protobuf or MessagePack instead of JSON.
They avoid String allocation for field names entirely - binary
field IDs instead of String keys. This is a larger change but
gives 50-70% reduction in per-object memory for message-heavy
services."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | String deduplication, interning, compact strings. |
| Hiring Manager   | Practical reduction approaches for real services. |
| Bar Raiser       | Java 9 compact strings implementation, String pool in Metaspace. |
| Peer Engineer    | "UseStringDeduplication dropped our heap from 12GB to 8GB overnight..." |

---

---

# Collection Sizing and Pre-allocation

**Interview Weight:** medium - Common micro-optimization.
Tests awareness of collection growth behavior.

---

### 🎯 Model Answer

**30 seconds:**

> Collections that grow beyond their initial capacity must resize:
> allocate a larger array and copy. Each resize is O(n) and
> creates a temporary old array for GC. Pre-sizing collections
> eliminates resizes. Rule: `new ArrayList<>(expectedSize)`,
> `new HashMap<>(expectedSize * 4/3 + 1)` (load factor correction).
> Use `Collectors.toList()` over `new ArrayList<>()` when size
> is unknown - JDK streams optimize internally.

**3 minutes (Senior):**

> **Collection growth behavior:**
> - `ArrayList`: initial capacity 10. Grows by 50% per resize.
>   For 1,000 elements: ~10 resizes, copying ~2,000 elements total.
> - `HashMap`: initial capacity 16, load factor 0.75. Resizes when
>   size > capacity * 0.75. Each resize doubles and rehashes.
>   For 1,000 entries: needs capacity 1,334 (1,000/0.75) to avoid
>   resize. Use: `new HashMap<>(1334)`.
> - `ArrayDeque`: initial capacity 16, grows by 2x.
>
> **Pre-sizing formula for HashMap:**
> Capacity to hold N entries without resize:
> `(int) Math.ceil(N / 0.75) + 1`
> For N=100: `(int)(100/0.75)+1 = 134`.
> Guava helper: `Maps.newHashMapWithExpectedSize(N)` does this.
>
> **Unmodifiable vs pre-sized:**
> If the collection is populated once and then read, use:
> `List.of(...)` (Java 9+): immutable, compact, no extra capacity.
> `Map.of(...)`: immutable, ~33% less memory than HashMap.
> `Map.copyOf(map)`: compact immutable copy.
>
> **Avoiding List.toArray() overhead:**
> `list.toArray(new String[0])` is now faster than
> `list.toArray(new String[list.size()])` due to JVM optimizations.
> The pre-sized version requires the size before calling, which
> the JVM doesn't need.

---

### 💻 Code Example

**Example 1: Collection pre-sizing patterns**

```java
// ArrayList: pre-size when expected size is known
// BAD: default capacity 10, resizes multiple times for large input
List<Order> orders = new ArrayList<>();
while (cursor.hasNext()) {
    orders.add(cursor.next());
}

// GOOD: pre-size from expected count
int count = cursor.estimatedCount();
List<Order> orders = new ArrayList<>(count);
while (cursor.hasNext()) {
    orders.add(cursor.next());
}

// HashMap: correct pre-sizing (account for load factor)
// BAD: HashMap<>(100) → resizes at 75 entries
Map<String, User> users = new HashMap<>(100);
// Puts 100 users → HashMap resizes at put #76!

// GOOD: account for load factor
int expected = 100;
Map<String, User> users = new HashMap<>(
    (int) Math.ceil(expected / 0.75) + 1
);
// = new HashMap<>(134) → never resizes for 100 entries

// EVEN BETTER: Guava helper
Map<String, User> users = Maps.newHashMapWithExpectedSize(100);
// Internally computes 134

// Immutable collections for read-only data
// GOOD: compact, no resize possible
List<String> statusCodes = List.of("OK", "CREATED", "ACCEPTED");
Map<String, Integer> httpStatus = Map.of(
    "OK", 200, "CREATED", 201, "ACCEPTED", 202
);
// List.of() uses array internally (30% less memory than ArrayList)

// WRONG assumption: toArray with pre-size is faster
// BAD (historically "good"):
String[] arr = list.toArray(new String[list.size()]);
// GOOD (modern JVM optimizes):
String[] arr = list.toArray(new String[0]);
// Benchmark: the JVM can optimize the 0-size form better (JEP 468)
```

> **Code walkthrough:** The HashMap load factor trap is the most
> common sizing mistake. `new HashMap<>(100)` resizes at 75 entries
> - 25% of the expected capacity. The correct formula provides
> a capacity that won't resize until the 101st entry. Guava's
> `Maps.newHashMapWithExpectedSize(N)` encapsulates this correctly.
> `List.of()` for immutable data uses a compact array-based
> implementation without ArrayList's growth overhead.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Pre-size collections when you know the expected count: prevents
> resize copies. HashMap needs (N/0.75)+1 capacity. Use `List.of()`
> for immutable collections.

---

**Senior / Staff (5+ years):**

> Pre-sizing collections matters most for large collections (>1,000
> elements) or collections created frequently (>10k/s). For small
> collections in normal paths, the JVM's young GC handles resize
> allocation cheaply. I focus pre-sizing effort where JFR
> allocation profiling shows collections being resized.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "You notice 'ArrayList' near the top of your JFR allocation
  profile by count. What could cause this?"

🗣️ "High ArrayList count in allocation profiling means the
application is creating many ArrayList instances. Three patterns:
(1) ArrayList as return type for all queries - even queries
returning 0-3 results create a full ArrayList with default
capacity 10. For small-result queries, consider returning
`Collections.emptyList()` or `Collections.singletonList()` when
possible, or `List.of(...)` for the common small-result case.
(2) ArrayList as intermediate container in stream/loop operations
that accumulate results - check if the result is actually needed
as a list or if stream processing would suffice. (3) ArrayList
resizing - the JFR allocation event for ArrayList would show
allocation at `ArrayList.grow()` if resizing is the issue.
Pre-sizing with expected capacity eliminates this. I'd check
the stack trace in JFR to distinguish between these - the call
site tells me which pattern applies."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Load factor math, resize behavior, immutable alternatives. |
| Hiring Manager   | Practical pre-sizing awareness. |
| Bar Raiser       | Guava vs JDK collections, HPPC/Eclipse Collections for primitives. |
| Peer Engineer    | "Pre-sizing our HashMap cut allocation in our serialization path by 40%..." |

---

---

# Off-Heap Memory Management

**Interview Weight:** high - Advanced technique for GC
avoidance. Used in high-throughput systems.

---

### 🎯 Model Answer

**30 seconds:**

> Off-heap memory is allocated outside the Java heap - not managed
> by GC. Uses: caching large data sets without GC pressure,
> sharing memory between JVM processes, zero-copy I/O.
> APIs: `ByteBuffer.allocateDirect()` (limited), Unsafe
> (deprecated path), `MemorySegment` (Java 21 Foreign Memory API),
> and libraries: Netty, Chronicle Map, Ehcache with off-heap.
> Risk: manual memory management - leaks if not freed, segfaults
> if misused.

**3 minutes (Senior):**

> **Why off-heap:**
> On-heap objects are tracked by GC. GC pressure grows with
> heap size. A 100GB cache on-heap means GC scans 100GB of
> potential live objects, causing long GC pauses.
> Off-heap: GC does not scan off-heap memory. A 100GB off-heap
> cache has zero GC overhead.
>
> **`ByteBuffer.allocateDirect()`:**
> Allocates native memory backed by OS pages. Used for I/O
> channels: zero-copy between JVM and kernel.
> Limitation: size limited by `-XX:MaxDirectMemorySize`.
> Freed by GC when the `ByteBuffer` object is collected (via
> `sun.misc.Cleaner`). If `ByteBuffer` objects are promoted to
> old gen and rarely GC'd, the native memory lives indefinitely.
> Use `((DirectBuffer) buf).cleaner().clean()` explicitly.
>
> **Foreign Memory API (Java 21+, stable):**
> `MemorySegment.allocateNative(size, Arena.ofConfined())`
> Explicit deallocation via `Arena.close()`. Deterministic
> memory management. Bounds-checking built in (vs Unsafe which
> has none).
>
> **Chronicle Map / Ehcache off-heap:**
> Production off-heap caching libraries. Serialize Java objects
> to off-heap memory. Access via deserialization. Suitable for:
> L2 cache that would otherwise be too large for on-heap.

---

### 💻 Code Example

**Example 1: Off-heap memory patterns**

```java
// PATTERN 1: Direct ByteBuffer for I/O
// Direct memory: allocated from OS, not Java heap
// JVM transfers I/O to/from direct buffers without intermediate copy
ByteBuffer directBuf = ByteBuffer.allocateDirect(4 * 1024 * 1024);  // 4MB

void readFromChannel(FileChannel channel) throws IOException {
    directBuf.clear();
    int bytesRead = channel.read(directBuf);
    // Zero-copy: OS reads directly into directBuf's native memory
    directBuf.flip();
    processData(directBuf);
}

// Explicitly free direct memory (don't wait for GC)
void freeDirectBuffer(ByteBuffer buf) {
    if (buf.isDirect()) {
        ((sun.nio.ch.DirectBuffer) buf).cleaner().clean();
        // Frees native memory immediately instead of waiting for GC
    }
}

// PATTERN 2: Foreign Memory API (Java 21+)
import java.lang.foreign.*;

void processWithForeignMemory() {
    // Arena manages lifetime: memory freed when arena is closed
    try (Arena arena = Arena.ofConfined()) {
        MemorySegment segment = arena.allocate(1024 * 1024); // 1MB off-heap
        MemorySegment.copy(sourceData, 0, segment, 0, sourceData.length);

        // Bounds checking built in:
        long value = segment.get(ValueLayout.JAVA_LONG, 0);
        // Accessing out of bounds throws IndexOutOfBoundsException (not segfault)

    } // arena.close() → native memory freed immediately (deterministic)
}

// PATTERN 3: Chronicle Map (persistent off-heap cache)
```

```xml
<!-- pom.xml: Chronicle Map -->
<dependency>
    <groupId>net.openhft</groupId>
    <artifactId>chronicle-map</artifactId>
    <version>3.25.2</version>
</dependency>
```

```java
ChronicleMap<Long, UserProfile> cache = ChronicleMap
    .of(Long.class, UserProfile.class)
    .averageValueSize(200)    // helps size off-heap regions
    .entries(10_000_000)      // 10 million entries off-heap
    .createOrRecoverPersistedTo(new File("/mnt/cache/users.dat"));
    // Can persist to disk for crash recovery

// Zero GC overhead even for 10M entries → GC scans 0 of these objects
// Cost: serialization on put/get (~1-5 microseconds)
UserProfile profile = cache.get(userId);
```

> **Code walkthrough:** Direct ByteBuffer zero-copy I/O eliminates
> an intermediate heap buffer between the OS and application code.
> The explicit `cleaner().clean()` call is critical for long-lived
> direct buffers - if the `ByteBuffer` object is promoted to old
> gen and never GC'd, native memory is never freed. The Foreign
> Memory API (Java 21) is safer: `Arena.close()` provides deterministic
> deallocation with bounds checking (no segfaults). Chronicle Map
> with 10 million entries has zero GC overhead from the cached data.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Off-heap memory avoids GC. Direct ByteBuffer for I/O zero-copy.
> Foreign Memory API (Java 21) for explicit off-heap allocation.
> Off-heap caching (Chronicle Map, Ehcache) for large datasets.

---

**Senior / Staff (5+ years):**

> Off-heap is warranted when on-heap cache size would cause
> unacceptable GC pauses, typically >10% of heap. I use it for
> reference data caches (user profiles, product catalogs) in
> data-intensive services. The Foreign Memory API (Java 21) is
> now the preferred path - safer than Unsafe, deterministic
> deallocation via Arena, and bounds-checked.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "What are the risks of off-heap memory compared to on-heap?"

🗣️ "Three main risks. First: manual memory management. Off-heap
memory is not garbage collected. If you allocate and forget to
free (or free prematurely), you get native memory leaks (process
memory grows without bound) or use-after-free errors (segfaults).
The Foreign Memory API mitigates this with Arena scopes that
auto-free, but arena misuse is still possible. Second: serialization
overhead. Off-heap stores bytes, not Java objects. Every read
requires deserialization, every write requires serialization.
For small, frequent reads (microsecond access patterns), this
overhead may exceed the GC savings. Profile both paths. Third:
debugging is harder. A native memory leak does not produce an
OOM heap dump. You see process memory growing in `top` but no
Java-level evidence. Diagnosis requires native tools (Valgrind,
`proc/pid/maps`). The benefit - eliminated GC overhead for large
datasets - is real, but only justified when the on-heap GC cost
is measured and significant."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Direct ByteBuffer, Foreign Memory API, off-heap caching. |
| Hiring Manager   | When to use off-heap, trade-offs. |
| Bar Raiser       | Unsafe vs Foreign Memory API, memory mapped files (MappedByteBuffer). |
| Peer Engineer    | "Chronicle Map took our heap GC pause from 2s to 20ms for 20M cached objects..." |

---

---

# Garbage Collection Tuning

**Interview Weight:** high - Expert topic. Tests systematic
GC tuning approach and knowledge of G1GC and ZGC mechanics.

---

### 🎯 Model Answer

**30 seconds:**

> GC tuning follows a hierarchy: measure GC behavior first (logs,
> JFR), identify the problem (pause length, frequency, throughput
> overhead), then tune. Key levers: heap size (Xmx), GC algorithm
> (G1GC vs ZGC vs Shenandoah), pause target (MaxGCPauseMillis),
> and region sizing (G1HeapRegionSize). Rule: reduce allocation
> rate before tuning GC flags.

**3 minutes (Senior):**

> **GC selection guide:**
> - **G1GC** (default Java 9+): balanced throughput and latency.
>   Pause target: 200ms default, tunable. Best for: general
>   purpose servers with mixed workloads.
> - **ZGC** (Java 15+ production): sub-10ms pauses at any heap size.
>   Best for: latency-sensitive services where p99 GC pauses
>   must be < 10ms. Throughput: ~5% lower than G1GC.
> - **Shenandoah**: similar to ZGC. Available in OpenJDK, Red Hat
>   builds. Sub-10ms pauses.
> - **Parallel GC**: maximum throughput, long STW pauses. Use for
>   batch processing, offline jobs - not interactive services.
>
> **G1GC tuning sequence:**
> 1. Right-size heap: live data set * 3 = Xmx.
>    Measure live data with: heap size after Full GC = live data.
> 2. Set MaxGCPauseMillis to your SLO target (e.g., 100ms).
>    G1 will try to meet this (not a hard guarantee).
> 3. If humongous objects (>50% of region size) are common,
>    increase region size: `-XX:G1HeapRegionSize=16m`.
> 4. If young GC too frequent: increase young gen ratio
>    with `-XX:G1NewSizePercent=30`.
> 5. If GC time overhead > 10%: reduce allocation rate first.
>    Only then add more heap.
>
> **ZGC tuning:**
> ZGC is nearly self-tuning. Set Xmx generously (ZGC needs
> slack to collect concurrently). `-XX:SoftMaxHeapSize=<value>`
> to set a soft target below Xmx. Monitor `ZGC Allocation Stall`
> events (JFR) - these mean ZGC is not keeping up with
> allocation rate.

---

### 💻 Code Example

**Example 1: GC tuning flags with rationale**

```bash
# G1GC PRODUCTION SETUP (balanced workload)
java \
  -Xms8g -Xmx8g \
  # Equal: prevents heap resize pauses.
  # Size: measured live data (2.5GB) * 3 = 7.5GB → round to 8GB.
  -XX:+UseG1GC \
  # Default in Java 9+ but explicit for clarity
  -XX:MaxGCPauseMillis=100 \
  # Target: 100ms pause (G1 tries to stay under; not a hard cap).
  # For p99 SLO of 200ms: set 100ms to have headroom.
  -XX:G1HeapRegionSize=16m \
  # Increase if humongous allocation warnings in GC log.
  # Default: adaptive (typically 4-8MB for 8GB heap).
  -XX:InitiatingHeapOccupancyPercent=45 \
  # G1 starts concurrent marking when old gen > 45% of heap.
  # Default is 45%. Lower if Full GC occurs (old gen fills too fast).
  -Xlog:gc*,gc+heap=debug:file=/var/log/gc.log:time,tags:filecount=5,filesize=20m \
  -jar app.jar

# ZGC PRODUCTION SETUP (latency-sensitive)
java \
  -Xms4g -Xmx16g \
  # ZGC works better with heap slack: Xms < Xmx
  # ZGC expands heap to avoid stalls; generous Xmx is correct.
  -XX:+UseZGC \
  -XX:SoftMaxHeapSize=10g \
  # ZGC tries to stay under 10GB but can use up to 16GB in spikes.
  -XX:ZUncommitDelay=60 \
  # Return unused heap to OS after 60s idle (default 300s).
  -Xlog:gc*:file=/var/log/gc.log:time,tags:filecount=5,filesize=20m \
  -jar app.jar

# Verify GC behavior post-deploy:
grep -E "GC\(|pause" /var/log/gc.log | tail -20
# Look for: pause duration, heap before/after GC, any allocation stalls
```

> **Code walkthrough:** The G1GC setup demonstrates the rationale
> for each flag: Xmx sized from live data measurement, not
> from "seems big enough". The MaxGCPauseMillis is set at half
> the SLO target for margin. ZGC's asymmetric Xms/Xmx is intentional:
> ZGC needs heap slack to run concurrent collection; a fixed-size
> heap can cause allocation stalls if collection can't keep up.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> G1GC is the default, good for most workloads. ZGC for
> sub-10ms pauses. Always set Xmx based on measured live data,
> not guesses. Enable GC logging for post-hoc analysis.

---

**Senior / Staff (5+ years):**

> My GC tuning rule: fix allocation rate first, then tune flags.
> I measure live data size after a Full GC to set Xmx correctly.
> I use ZGC for any service with p99 SLO < 50ms. G1GC for
> everything else - the throughput advantage is real and measurable.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "How would you decide between G1GC and ZGC for a new service?"

🗣️ "The decision depends on the latency SLO. G1GC can deliver
100-200ms pause targets reliably, with throughput 3-5% higher
than ZGC. If the service's p99 SLO is 500ms or higher, G1GC is
the right choice - it has lower overhead and is more mature.
If the p99 SLO is 50ms or below (real-time trading, gaming,
interactive APIs where tail latency matters), ZGC is the right
choice - it delivers sub-10ms pauses even at 100GB+ heaps.
I'd also consider heap size: ZGC scales better for very large
heaps (32GB+) where G1GC's region scanning overhead grows.
For microservices with 4-8GB heaps and moderate latency requirements
(p99 < 200ms), G1GC is the pragmatic choice. I measure under
load and switch if GC pauses appear in the p99 tail."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | G1GC vs ZGC mechanics, tuning flags. |
| Hiring Manager   | GC selection decision framework. |
| Bar Raiser       | ZGC concurrent phases, SATB barriers, remembered sets. |
| Peer Engineer    | "ZGC cut our p99 from 400ms to 8ms - all from GC pauses..." |
