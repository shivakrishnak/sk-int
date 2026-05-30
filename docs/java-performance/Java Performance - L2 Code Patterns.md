---
layout: default
title: "Java Performance - L2 Code Patterns"
parent: "Java Performance"
grand_parent: "SK Interview"
nav_order: 5
permalink: /java-performance/l2-code-patterns/
render_with_liquid: false
---

# Java Performance - L2 Code Patterns

## Object Allocation Reduction: Pool and Flyweight Patterns

### 🎯 Model Answer

**30 seconds:**
> Reducing object allocation: (1) Object pooling - reuse expensive objects (threads, connections,
> large buffers). (2) Flyweight pattern - share immutable state (string interning, enum). (3) Avoid
> temporary objects in hot paths (StringBuilder over String+, primitive arrays over boxed collections).
> (4) ThreadLocal pools for non-shareable objects. Allocation reduction = fewer GC cycles = better latency.

**3 minutes (Senior):**
> Object allocation reduction strategies, from most to least impactful:
>
> 1. **Avoid unnecessary temporaries**: the highest ROI change. String concatenation in loops,
>    `String.format()` in hot paths, autoboxing (`int` -> `Integer` in collection operations),
>    `Arrays.asList()` for single-use lists. Elimination: StringBuilder with pre-sized capacity,
>    parameterized logging (SLF4J `log.debug("val={}", val)` - lazy), primitive maps (Eclipse Collections).
>
> 2. **Object pooling**: for objects with high construction cost (DB connections, thread stacks,
>    large byte buffers). Use existing pools (HikariCP for connections, Apache Commons Pool for
>    generic pooling, Netty ByteBuf pooled allocator for IO buffers). Custom pools: `BlockingQueue<T>`
>    of pre-allocated instances.
>
> 3. **Flyweight pattern**: multiple logically different objects sharing the same immutable state.
>    `String.intern()`: all strings with the same content share one instance. `Integer.valueOf()`:
>    caches -128 to 127. Enum: one instance per constant. Apply when: same data is created many
>    times and is immutable.
>
> 4. **Value objects (Java 16+ records)**: records are not necessarily cheaper to allocate than
>    regular objects, but they're typically short-lived (immutable, no setters). Combined with
>    escape analysis: the JIT may eliminate them entirely.

**Blank Mind Recovery:**

**(1) Restate:** "Reduce allocation: (1) avoid temporaries in hot paths (String.format, autoboxing), (2) object pooling for expensive objects (connections, large buffers), (3) flyweight for shared immutable state. Measure first: alloc flame graph shows which call paths allocate most."

**(2) First principles:** "Allocation = creating a new object on the heap. GC must collect it. Reduction = less work for GC = fewer pauses = better latency. Most impactful: hot paths (called millions/sec). Zero impact: cold paths (called rarely)."

**(3) Bridge:** "Object pooling is like renting reusable containers instead of buying new ones each time. Flyweight is like using the same map for navigation instead of printing a new copy for each driver. Both reduce waste; neither is appropriate everywhere - pooling adds complexity, flyweight requires immutability."

---

### 📘 Concept Explanation

**Allocation reduction patterns with trade-offs:**
```
ALLOCATION IN JAVA: WHERE IT HAPPENS:

  String operations:
    String s = a + b + c;       // creates: StringBuilder, 2 Strings
    String.format("v=%d", n);   // creates: String, Object[] (varargs autobox)
    s.substring(1, 3);          // creates: new String (up to Java 6)
                                 // Java 7+: shared char array, cheap
  
  Collections:
    List<Integer> l = Arrays.asList(1,2,3);  // Integer boxing: 3 objects
    Map<Integer,String> m = new HashMap<>();
    m.put(i, s);  // int i -> Integer (boxing allocation)
  
  Streams:
    list.stream().filter(...).map(...).collect(Collectors.toList())
    // Creates: Stream, filter lambda, map lambda, Collector, ArrayList
    // For a list of 1000 items: ~5-10 intermediate objects
  
  Logging:
    log.debug("value=" + obj.toString());  // String + toString() created
    // even if debug is disabled! The allocation happens BEFORE the
    // log.debug() call receives the argument.
    Fix: log.debug("value={}", obj);  // lazy: obj.toString() only if DEBUG

OBJECT POOLING PATTERNS:

  WHEN TO POOL:
    High construction cost: DB connections (TCP handshake + auth),
    Thread (OS thread creation), SSL context, large byte arrays (> 64KB)
    
  WHEN NOT TO POOL:
    Simple objects (new User()): allocation is very cheap (~10ns for TLAB bump)
    Pooling adds: synchronization overhead (ConcurrentLinkedDeque), 
    lifecycle complexity (borrow/return, expiration), 
    correctness risk (forgetting to return, state leakage between uses)
    Net: pooling simple objects SLOWER than just allocating new
  
  PATTERN 1: Connection pool (HikariCP - the model):
    Pool manages N pre-created connections.
    Borrower: getConnection() (blocks if none available)
    Returner: connection.close() (returns to pool, not actually closed)
    Pool size: CPU cores * 2-4 for optimal DB throughput (HikariCP docs)
  
  PATTERN 2: Buffer pool (Netty-style):
    Fixed pool of ByteBuf instances (pre-allocated, large enough)
    Acquire: pool.acquire() returns a ByteBuf
    Release: buf.release() returns to pool
    Key: reference counting (release() when done)
    Risk: forgetting release() -> pool depletion
  
  PATTERN 3: ThreadLocal pool (per-thread, no synchronization):
    Appropriate for objects used within a single thread's execution.
    ThreadLocal<byte[]> bufPool = ThreadLocal.withInitial(() -> new byte[8192]);
    No synchronization needed (each thread has its own copy).
    Risk: with virtual threads, one copy per virtual thread = many copies
    (virtual threads are cheap but plentiful)
  
  PATTERN 4: Flyweight (shared immutable state):
    Condition: the object's state is immutable AND shared across instances.
    String interning: String.intern() - all equal strings -> one instance
    Enum constants: one instance per constant (built-in flyweight)
    Integer cache: Integer.valueOf(n) for -128..127 returns cached instance
    (128+ always allocates new Integer - autoboxing in collections uses valueOf)
    Custom: a read-only configuration object shared by many request contexts

MEASURING ALLOCATION REDUCTION:

  Before change:
    async-profiler alloc mode: record 60 seconds under load
    Find: the target call path's allocation (MB/s or count/s)
  
  After change:
    Re-profile same conditions.
    Compare: allocation MB/s for that call path
  
  JMH with allocation measurement:
    Add GC counting between iterations (JMH's -prof gc output):
    gc.alloc.rate, gc.alloc.rate.norm (per operation allocation)
    Before: 256 B/op
    After: 0 B/op  (full elimination via escape analysis + pooling)
```

---

### 💻 Code Example

> **Code walkthrough:** The progression shows three allocation reduction techniques on the same
> use case: logging in a hot path. The first pattern (string concatenation) allocates on every
> call even when logging is disabled. The second (parameterized) defers allocation to after the
> level check. The third (full elimination via StringBuilder pre-check) shows the explicit form.

```java
// ALLOCATION REDUCTION IN A HOT PATH:

// Scenario: HTTP request handler called 10,000 times/second

// BAD PATTERN 1: String concatenation in log call (ALWAYS allocates):
public void processOrder(Order order) {
    log.debug("Processing order: " + order.getId() + 
        " for customer " + order.getCustomerId());
    // Creates: 2 String concatenation objects + the final String
    // Even when DEBUG is disabled (log level = INFO in production):
    // The string is ALWAYS built (allocation BEFORE the if-DEBUG check)
    doProcess(order);
}

// BAD PATTERN 2: String.format for logging:
public void processOrder(Order order) {
    log.debug(String.format("Processing order: %d for customer %s", 
        order.getId(), order.getCustomerId()));
    // String.format: creates Object[] for varargs, formats String
    // Again: always allocates, even when debug is disabled
}

// GOOD PATTERN 1: SLF4J parameterized logging (standard):
public void processOrder(Order order) {
    log.debug("Processing order: {} for customer {}", 
        order.getId(), order.getCustomerId());
    // SLF4J: checks if DEBUG is enabled FIRST (no-op in production)
    // Only creates the formatted string if debug IS enabled
    // Autoboxing: order.getId() (Long) still boxes if not already
    // For truly zero-allocation: use log.isDebugEnabled() guard
    doProcess(order);
}

// GOOD PATTERN 2: Explicit guard (zero allocation in production):
public void processOrder(Order order) {
    if (log.isDebugEnabled()) {
        log.debug("Processing order: {} for customer {}", 
            order.getId(), order.getCustomerId());
    }
    doProcess(order);
}

// OBJECT POOLING FOR BUFFERS:

// BAD: new byte[] allocation per request:
public byte[] readAndProcessStream(InputStream in) throws IOException {
    byte[] buffer = new byte[65536];  // 64KB allocation per request
    // At 1000 RPS: 64MB/s allocation rate just for this buffer
    int n;
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    while ((n = in.read(buffer)) != -1) {
        out.write(buffer, 0, n);
    }
    return out.toByteArray();
}

// GOOD: ThreadLocal buffer pool (zero allocation per request):
private static final ThreadLocal<byte[]> IO_BUFFER = 
    ThreadLocal.withInitial(() -> new byte[65536]);

public byte[] readAndProcessStream(InputStream in) throws IOException {
    byte[] buffer = IO_BUFFER.get();  // reuse, no allocation
    int n;
    // Use a fixed-size output if max response size is known:
    ByteArrayOutputStream out = new ByteArrayOutputStream(8192);
    while ((n = in.read(buffer)) != -1) {
        out.write(buffer, 0, n);
    }
    return out.toByteArray();
    // buffer stays in ThreadLocal, reused next request on same thread
}

// FLYWEIGHT FOR ENUMS:
// BAD: creating status objects:
class OrderStatus {
    private final String code;
    private final String description;
    // Created many times with the same code/description
    public OrderStatus(String code, String desc) {
        this.code = code;
        this.description = desc;
    }
}

// GOOD: Enum as flyweight (one instance per status, shared):
enum OrderStatus {
    PENDING("PENDING", "Order placed, awaiting payment"),
    CONFIRMED("CONFIRMED", "Payment confirmed"),
    SHIPPED("SHIPPED", "Order shipped"),
    DELIVERED("DELIVERED", "Order delivered");
    
    private final String code;
    private final String description;
    
    OrderStatus(String code, String description) {
        this.code = code;
        this.description = description;
    }
}
// OrderStatus.PENDING: same instance reused everywhere. Zero per-use allocation.
```

> **Code walkthrough:** The logging pattern shows the real cost of string concatenation: it allocates
> before the disabled-check runs, wasting CPU and GC cycles on every call in production. SLF4J
> parameterized logging defers the work but still autoboxes. The `isDebugEnabled()` guard is the
> zero-cost production option. The ThreadLocal buffer pool eliminates 64KB of allocation per request
> at 1000 RPS = 64MB/s less allocation = significantly fewer GC cycles.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Common allocation anti-patterns: String + in loops, autoboxing in hot paths, logging with string
> concatenation (use parameterized: `log.debug("v={}", val)`). Object pooling: for connections
> (HikariCP), not for simple data objects. Flyweight: enums, string interning for repeated strings.

---

**Senior / Staff (5+ years):**
> Allocation profiling is the prerequisite: don't pool or optimize without knowing which allocations
> dominate. Async-profiler alloc mode + flame graph: the top 3 call stacks typically account for
> 80% of allocation. Fix those 3 only. Custom pools: use existing implementations (Apache Commons Pool,
> Netty PooledByteBufAllocator). Hand-rolled pools: common bugs are deadlock (forget to return),
> state leak (previous use's state not cleared), and over-pooling (pool adds synchronization overhead
> that exceeds the allocation savings for cheap objects).

---

### ⚠️ Common Misconceptions

**Misconception: "Object pooling always improves performance."**
Pooling adds overhead: acquiring from a pool requires thread-safe access (lock or CAS). For small
objects (< 100 bytes), the allocation cost (TLAB bump pointer, ~5ns) is LESS than the pool acquisition
overhead (CAS retry, thread-safe queue, ~10-50ns). Pooling is beneficial only when the object's
construction cost (resource acquisition, large initialization) exceeds the pool overhead AND allocation
rate is high enough to cause measurable GC pressure. Measure both before and after with JMH.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Object pool depletes under load, causing thread stalls.**
```
Symptom: Under high load, request latency spikes. Threads appear blocked.
  Pool metric: "waiting threads" > 0 for extended periods.

Root cause: Pool size too small for the concurrency level.
  Formula: pool_size >= max_concurrent_users_of_the_resource
  If 200 concurrent requests each hold a pooled connection for 100ms:
  Pool needs >= 200 connections simultaneously.
  
  Alternatively: objects not being returned (bug in borrow/return code).

Diagnosis:
  Monitor pool metrics (HikariCP exposes via Micrometer):
    hikaricp.connections.pending: waiting threads
    hikaricp.connections.active: in-use connections
    hikaricp.connections.idle: available in pool
  
  If pending > 0 continuously: pool exhausted.
  If idle > active constantly: pool too large (wasted resources).

Fix:
  1. Correct pool size: measure actual concurrency * hold time
     HikariCP formula: pool_size = (CPU cores * 2) + effective_spindle_count
     For Postgres on SSD: ~2*CPU cores is optimal.
  2. Reduce hold time: don't hold a connection for non-DB work
     BAD: connection = pool.get(); doLogging(conn); doDb(conn); doFile(conn)
     GOOD: doLogging(); connection = pool.get(); doDb(conn); conn.close(); doFile()
  3. Add connection acquire timeout: prevent indefinite stall
     HikariCP: connectionTimeout=5000 (5s max wait, then exception)
     Caller handles: retry or fail-fast (better than blocking forever)
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| When to pool vs not pool | 2 minutes |
| SLF4J lazy logging | 1 minute |
| Autoboxing in hot paths | 2 minutes |
| ThreadLocal pool trade-offs | 2 minutes |
| Flyweight pattern | 1 minute |
| Pool sizing formula | 1 minute |
| Measuring allocation reduction | 1 minute |
| Pool depletion diagnosis | 1 minute |
| Escape analysis vs pooling | 1 minute |

---

**Q1 (when pool): When does object pooling improve performance and when does it hurt it?**

A: Pool improves when: (1) object construction is expensive (TCP connection, OS thread, SSL handshake),
(2) object is large (64KB+ buffers - GC benefits from reuse), (3) allocation rate is measured as high
on the profiler. Pool hurts when: (1) object is cheap to allocate (< 100 bytes, no IO), (2) pool
synchronization cost exceeds allocation cost, (3) pool adds code complexity that leads to bugs (state
leak, depletion). The TLAB bump pointer allocation is ~5ns. A thread-safe pool acquisition: ~20-100ns.
Pool only makes sense when construction cost > 100ns (roughly).

*What separates good from great:* The "escape analysis beats pooling" principle: for objects that don't
escape their creation scope, C2 applies scalar replacement and the object is never heap-allocated at
all. This is BETTER than pooling (pool: allocate once, reuse many times; scalar replacement: allocate
zero times). Check if escape analysis already eliminates the object before adding a pool. JMH with
`-prof gc` prints `gc.alloc.rate.norm` (bytes allocated per operation). If it's 0: escape analysis
worked. If it's > 0 and the object is local: investigate why escape analysis didn't trigger (too-large
method, virtual call in the path, object passed to another method that may escape it).

---

**Q2 (autoboxing): How does autoboxing cause GC pressure and how do you eliminate it?**

A: Autoboxing: automatic conversion of primitive (int, long, double) to wrapper object (Integer, Long,
Double). Triggered: when a primitive is added to a collection (`Map<String, Integer>`), passed to a
generic method, or stored in a generic field. Cost: one Object allocation per boxing. In a hot path
calling `map.put(int, int)` 1 million times: 1 million Integer allocations. At ~24 bytes each:
24MB/s allocation rate from boxing alone. Fix: use primitive-specialized collections. Eclipse Collections:
`IntIntHashMap`, `IntObjectHashMap`. Trove: similar. Or: use `int[]` arrays if the access pattern
allows.

*What separates good from great:* The JDK 23+ Project Valhalla "value types" preview: primitive
classes that are value-typed and stored inline (no heap allocation). `int` in a `List<int>` will not
box - the list stores the int values directly. This is the language-level fix to autoboxing. Until
Valhalla GA: Eclipse Collections or Koloboke for primitive maps/lists. The performance difference:
for a `HashMap<Integer, Long>` with 1 million entries vs `IntLongHashMap`: 50-70% memory reduction
(no Integer/Long wrappers), 30-50% faster iteration (no pointer chasing). For hot code paths that
do many map operations: this is a measurable improvement.

---

**Q3 (threadlocal pools): What are the risks of using ThreadLocal for object pooling?**

A: Risks: (1) Memory leak: if the `ThreadLocal` is set in a request and `remove()` is not called:
the thread pool thread retains the object for its lifetime. With 200 threads: 200 retained objects.
(2) Virtual thread problem: with virtual threads, each virtual thread has its own ThreadLocal copy.
1 million concurrent virtual threads: 1 million copies. ThreadLocal pooling defeats the purpose of
virtual threads. (3) State leakage: if the pooled object is not reset between uses: the next user
sees stale state. Always reset the object state when returning to the pool.

*What separates good from great:* The virtual thread migration pattern: code with ThreadLocal pools
that worked well with platform threads breaks with virtual threads (millions of copies instead of
200). The fix for virtual threads: use `ScopedValue` (JDK 21 preview, JDK 23 final) instead of
ThreadLocal for request-scoped context. ScopedValue: immutable, scoped to a structured concurrency
scope, garbage-collected when the scope exits. No `remove()` needed, no leak possible. For mutable
state that needs a per-request buffer: pass the buffer explicitly (parameter injection) instead of
ThreadLocal. This is cleaner, compatible with virtual threads, and avoids the lifecycle complexity.

---

---

## Collection Performance: ArrayList vs LinkedList vs HashMap Trade-offs

### 🎯 Model Answer

**30 seconds:**
> ArrayList: contiguous memory, O(1) random access, O(n) insert/delete middle, fast iteration.
> LinkedList: O(n) random access, O(1) insert/delete at known position, poor cache performance.
> HashMap: O(1) average get/put, O(n) worst case (collision). Choose based on access pattern:
> random access -> ArrayList, frequent middle insert -> LinkedList (rarely correct),
> key lookup -> HashMap. Default: prefer ArrayList over LinkedList.

**3 minutes (Senior):**
> Collection choice by operation profile:
>
> **ArrayList**: backed by an `Object[]`. Random access by index: O(1). Append: O(1) amortized
> (resize doubles capacity). Insert/delete at arbitrary position: O(n) (element shift). Iteration:
> very fast (sequential memory access, CPU cache-friendly). Best for: list where you mostly
> append and iterate.
>
> **LinkedList**: doubly-linked node chain. Get(i): O(n) (traverse from head or tail).
> Add/remove at iterator position: O(1). Memory: 3x overhead (node object + 2 pointers per element).
> Cache unfriendly: nodes scattered in memory. Profiler: looks like many small GC objects.
> Use case: almost never in modern Java (ArrayDeque is better for queue/stack, ArrayList for list).
>
> **HashMap**: array of buckets + linked list/tree per bucket. Average O(1) get/put. Worst
> case O(n) (all keys hash to same bucket, Java 8: O(log n) tree). Load factor: 0.75 default.
> Initial capacity: set to expected size / load_factor to avoid resizing.
>
> **ArrayDeque**: circular array. O(1) add/remove at both ends. Better than LinkedList for queue/stack.
> CPU cache-friendly (array-backed). Prefer over LinkedList for deque operations.

**Blank Mind Recovery:**

**(1) Restate:** "ArrayList: O(1) get, O(n) insert middle, fast iteration, cache-friendly. LinkedList: O(n) get, O(1) insert at known position, cache-unfriendly. HashMap: O(1) average, O(n) worst. ArrayDeque: better LinkedList for queues. Default: ArrayList."

**(2) First principles:** "Collections have different asymptotic and constant-factor performance. Asymptotic (O-notation): algorithmic complexity. Constant factor: CPU cache behavior. Linked lists: O(1) insert but terrible cache behavior (pointer chasing = cache miss per node). ArrayList O(n) insert but sequential memory (cache-friendly scan) = often faster in practice for small n."

**(3) Bridge:** "ArrayList is like a filing cabinet drawer: you can instantly grab file #47, but inserting in the middle requires pushing 46 files aside. LinkedList is like a chain of sticky notes: adding to the chain is instant, but finding note #47 means counting from the beginning."

---

### 📘 Concept Explanation

**Collection performance dimensions: time, memory, and CPU cache:**
```
PERFORMANCE COMPARISON TABLE:

  Operation         ArrayList   LinkedList   HashMap      ArrayDeque
  ---------         ---------   ----------   -------      ----------
  get(i)            O(1)        O(n)         O(1) avg     O(1)
  add(e) end        O(1) amort  O(1)         -            O(1)
  add(i, e) middle  O(n)        O(1)*        -            -
  remove(i)         O(n)        O(1)*        -            -
  contains(e)       O(n)        O(n)         O(1) avg     O(n)
  iteration         O(n) FAST   O(n) SLOW    O(n+m)       O(n) FAST
  memory/element    ~4 bytes    ~20-24 bytes ~32 bytes    ~4 bytes
  
  *LinkedList add/remove at iterator position is O(1),
   but finding the position is O(n).

CACHE BEHAVIOR (the hidden constant factor):

  ArrayList: [elem0][elem1][elem2][elem3]...  <- contiguous memory
    CPU cache line = 64 bytes = 16 int values = 8 object pointers
    Iterating: CPU loads one cache line, processes 8 elements, loads next
    Cache miss rate: very low (sequential access pattern)
  
  LinkedList: [node0] -> [node1] -> [node2]...
    Each node: ~24 bytes (header) + value + prev + next pointers
    Nodes: scattered throughout heap at random addresses
    Iterating: each node = potential cache miss (new heap address)
    Cache miss rate: very high
    Impact: ArrayList 5-10x faster than LinkedList for iteration
    even though both are O(n) - constant factors dominate.

HASHMAP SIZING:

  Initial capacity: default 16. Load factor: 0.75.
  Resize triggers: when size > capacity * loadFactor.
  Resize cost: O(n) - rehash all entries.
  
  BAD: new HashMap<>() when you know the expected size:
    Adding 1000 entries: resizes at 12, 24, 48, 96, 192, 384, 768 entries
    = 7 resize operations, each rehashing all existing entries.
  
  GOOD: new HashMap<>(expectedSize / loadFactor + 1):
    Expected 1000 entries: new HashMap<>(1334)  // or 2048 (next power of 2)
    Zero resizes during insertion.
    
  Or: Guava Maps.newHashMapWithExpectedSize(1000) -> computes correct capacity
  
  HASHCODE QUALITY MATTERS:
    All keys hashing to the same bucket: O(n) lookup (linked list in bucket)
    Even in Java 8+ (bucket becomes tree above 8 entries, O(log n)):
    O(log n) vs O(1) average is a 1000x difference at 1000-entry bucket.
    
    BAD hashCode (constant): all entries in one bucket.
    class BadKey { public int hashCode() { return 1; } }
    
    GOOD hashCode: well-distributed across all buckets.

SPECIALIZED COLLECTIONS:

  EnumMap: faster than HashMap for Enum keys (array-backed, no hashing)
  EnumSet: BitSet-backed Set for Enum values. Ultra-fast add/contains.
  
  Example: Set<OrderStatus> activeStatuses = EnumSet.of(PENDING, CONFIRMED);
  activeStatuses.contains(status);  // bit check: O(1), no hashing
  
  Primitive collections (Eclipse Collections / Trove):
    IntArrayList, IntHashMap: no autoboxing, 3-4x less memory than ArrayList<Integer>
  
  CopyOnWriteArrayList:
    Thread-safe read without locks.
    Write: copies entire array. Expensive: O(n) per write.
    Use when: reads >> writes (e.g., list of event listeners rarely changed)
    DO NOT use as a general-purpose thread-safe list (O(n) writes too expensive)

ITERATION PERFORMANCE:

  Fastest to slowest for iteration:
  1. Primitive array (int[]): cache-line sequential, no object overhead
  2. ArrayList: near-array speed (Object[] internally)
  3. ArrayDeque: similar to ArrayList (circular array)
  4. HashMap.entrySet(): access buckets + node traversal (some cache misses)
  5. LinkedList: worst (pointer chasing, high cache miss rate)
  
  Measurement: JMH benchmark for specific collection sizes shows:
    ArrayList 1000 elements: 300 ns/iteration
    LinkedList 1000 elements: 5,000 ns/iteration (17x slower!)
    (both O(n), but constant factors diverge dramatically)
```

---

### 💻 Code Example

> **Code walkthrough:** The benchmark results show the cache-behavior difference between ArrayList
> and LinkedList concretely. The HashMap sizing example shows how pre-sizing avoids the hidden
> resize cost. The EnumMap and primitive collection examples show how specialized collections
> eliminate overhead for specific access patterns.

```java
// COLLECTION CHOICE PATTERNS:

// BAD: LinkedList for general list usage:
List<Order> orders = new LinkedList<>();
// Poor choice for: random access, iteration, append
// orders.get(500) on a 1000-element list = 500 pointer traversals
// Iteration: cache-unfriendly (pointer chasing)

// GOOD: ArrayList for general list usage:
List<Order> orders = new ArrayList<>(estimatedSize);  // pre-sized!
// Random access: O(1). Append: O(1) amortized. Iteration: fast.

// GOOD: ArrayDeque for queue/stack operations:
Deque<Task> taskQueue = new ArrayDeque<>();
taskQueue.addLast(task);   // O(1), cache-friendly (circular array)
Task t = taskQueue.pollFirst();  // O(1), no lock needed (single-thread)
// NOT: LinkedList as Deque (also O(1) but 5x slower due to cache misses)

// BAD: HashMap default constructor when size is known:
Map<Long, User> userCache = new HashMap<>();
for (User u : users) userCache.put(u.getId(), u);
// Resizes multiple times during population if users.size() > 12

// GOOD: Pre-sized HashMap:
int expectedSize = users.size();
// Correct formula: expectedSize / loadFactor + 1
int initialCapacity = (int)(expectedSize / 0.75) + 1;
Map<Long, User> userCache = new HashMap<>(initialCapacity);
// Or using Guava:
// Map<Long, User> userCache = Maps.newHashMapWithExpectedSize(expectedSize);
for (User u : users) userCache.put(u.getId(), u);
// Zero resizes = no rehash cost

// GOOD: EnumMap for Enum keys (array-backed, no hashing):
Map<OrderStatus, List<Order>> ordersByStatus = new EnumMap<>(OrderStatus.class);
// Backed by an array indexed by enum ordinal. No hash computation.
// Faster than HashMap for enum keys. Memory: proportional to enum count.

// GOOD: EnumSet for status flag checking:
// BAD (HashSet with Enum values):
Set<OrderStatus> activeStatuses = new HashSet<>(
    Arrays.asList(OrderStatus.PENDING, OrderStatus.CONFIRMED));
if (activeStatuses.contains(order.getStatus())) { ... }

// GOOD (EnumSet - bit operations):
EnumSet<OrderStatus> activeStatuses = 
    EnumSet.of(OrderStatus.PENDING, OrderStatus.CONFIRMED);
if (activeStatuses.contains(order.getStatus())) { ... }
// contains(): single bitwise AND operation (~1ns vs ~50ns for HashSet)

// JMH RESULT SNAPSHOT (illustrative, order of magnitude accurate):
// Benchmark                              Mode  Cnt    Score   Units
// iterate_ArrayList_1000                avgt   10   300.4   ns/op
// iterate_LinkedList_1000               avgt   10  5123.7   ns/op (17x slower!)
// hashmap_get_defaultSize               avgt   10    45.2   ns/op
// hashmap_get_presized                  avgt   10    38.1   ns/op (no resize)
// enumset_contains                      avgt   10     1.2   ns/op
// hashset_enum_contains                 avgt   10    48.3   ns/op (40x slower!)
```

> **Code walkthrough:** The LinkedList vs ArrayList benchmark result shows the 17x difference
> despite both being O(n) - this is the cache behavior gap at work. The EnumSet benchmark shows
> a 40x speedup over HashSet for enum key membership tests: the bitwise AND replaces hashing,
> map lookup, and equality checks. The HashMap pre-sizing shows 15% improvement from eliminating
> resize operations - modest for small maps but significant when building large maps in tight loops.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> ArrayList: use by default for lists. LinkedList: almost never (ArrayDeque for queue operations).
> HashMap: use for key-value lookups. Pre-size HashMap when you know the expected size. EnumSet/EnumMap
> for enum keys: faster. Cache behavior: ArrayList >> LinkedList for iteration even though both O(n).

---

**Senior / Staff (5+ years):**
> The "LinkedList is rarely the right answer" rule applies in practice: the scenarios where LinkedList's
> O(1) middle-insert genuinely wins are very narrow (you have an Iterator positioned at the insertion
> point AND insertion is the dominant operation AND n > 1000). For most real cases: ArrayList's O(n)
> shift is faster in practice (cache-friendly memmove on modern CPUs). Profile before choosing.
> For large-scale data processing: consider primitive arrays (int[], long[]) or off-heap structures
> to avoid GC entirely for hot data structures.

---

### ⚠️ Common Misconceptions

**Misconception: "LinkedList is better than ArrayList for frequent middle insertions."**
True in theory (O(1) vs O(n)). False in practice for n < ~10,000 because ArrayList's O(n) insert
is a `System.arraycopy()` call - a highly-optimized JVM intrinsic using SIMD instructions, operating
on sequential cache-friendly memory. LinkedList's O(1) insert requires traversing to the insert
position (O(n)), and each traversal step is a cache miss. For n < 1,000: ArrayList insert is
typically FASTER than LinkedList despite the worse asymptotic. Measure with JMH at your actual
n values before concluding.

---

### 🚨 Failure Modes and Diagnosis

**Failure: HashMap.get() performance degrades under certain key distributions.**
```
Symptom: Service using HashMap<UserId, Profile> shows increasing p99 latency
  for a subset of user IDs. Not reproducible with all IDs.

Root cause: hashCode collision causing bucket overflow.
  Some UserId implementations have poor hashCode() (e.g., all IDs
  in a test range hash to the same bucket).
  Java 8: bucket converts to tree at 8 entries (O(log n) instead of O(n)).
  Still: O(log n) per lookup vs O(1) average -> measurable degradation.

Diagnosis:
  Check the UserId.hashCode() implementation:
    Are IDs in the range 0-1000? Integer.hashCode() = the value.
    HashMap with capacity 1024: all IDs 0-1023 distribute well.
    HashMap with capacity 16: IDs 0, 16, 32, 48... all go to bucket 0.
  
  Verify: hashCode distribution
    Map<Integer, Integer> bucketCount = new HashMap<>();
    for (UserId uid : allIds) {
        int bucket = (uid.hashCode() ^ (uid.hashCode() >>> 16)) & (capacity - 1);
        bucketCount.merge(bucket, 1, Integer::sum);
    }
    // Ideal: all buckets have ~1 entry. Spike: collision problem.

Fix:
  1. Improve hashCode():
     For sequential IDs: use Fibonacci hashing or bitwise mixing
     Long hash: Long.hashCode(value) = (int)(value ^ (value >>> 32))
     This distributes sequential longs much better.
  
  2. Use initial capacity that avoids the collision:
     Power of 2 with good hashCode: good distribution.
  
  3. Consider LinkedHashMap (insertion-ordered) if iteration order matters,
     or TreeMap (sorted) if sorted access is needed - both avoid this.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| ArrayList vs LinkedList real-world | 2 minutes |
| HashMap resizing | 1 minute |
| Cache behavior impact | 2 minutes |
| EnumMap vs HashMap | 1 minute |
| HashMap worst case | 1 minute |
| When to use LinkedList | 1 minute |
| Primitive collection libraries | 1 minute |
| CopyOnWriteArrayList trade-off | 1 minute |
| HashMap initial capacity formula | 1 minute |

---

**Q1 (cache): Explain why ArrayList is faster than LinkedList for iteration even though both are O(n).**

A: ArrayList: backed by `Object[]` - contiguous heap memory. CPU cache line = 64 bytes = holds ~8 object
references. When iterating: CPU prefetcher loads the next cache line before it's needed (sequential
access pattern). Result: most array accesses are cache hits (~4ns). LinkedList: each node is a separate
heap object (24 bytes: header + value + prev + next). Nodes are allocated at different times, scattered
in heap memory. Accessing node N: follows a pointer to a random heap address = cache miss (~100ns per
miss). 1000 iterations: ArrayList ~4000ns (mostly cache hits), LinkedList ~100,000ns (mostly cache misses).
Both O(n), but cache behavior makes ArrayList 25x faster in practice.

*What separates good from great:* The "false O(n)" trap: asymptotic complexity hides constant factors.
For n < ~10,000 (typical list sizes in business applications), constant factors dominate over asymptotic
complexity. O(1) with a large constant can be slower than O(n) with a small constant. The CPU memory
hierarchy: registers (1 cycle), L1 cache (4 cycles), L2 cache (12 cycles), L3 cache (40 cycles), main
memory (200+ cycles). A cache-friendly O(n) algorithm with L1 hits: 4n cycles. A cache-unfriendly O(n)
algorithm with main memory misses: 200n cycles. 50x difference. This is why "mechanical sympathy"
(understanding how CPU caches work) is a critical skill for high-performance Java.

---

**Q2 (hashmap resizing): What happens when HashMap is not pre-sized and why does it matter?**

A: HashMap default capacity: 16. Load factor: 0.75. Resize triggers when `size > capacity * 0.75`.
Resize: allocates a new `Object[]` of double the capacity, rehashes every existing entry into the new
array. Cost: O(n). For a HashMap that grows to 1024 entries: resizes at 12, 24, 48, 96, 192, 384, 768
entries = 7 resizes. Each resize: rehash all existing entries. Total extra work: proportional to
12 + 24 + 48 + ... = 2 * n (approximately). With pre-sizing: zero resizes.

*What separates good from great:* The "capacity must be power of 2" detail: HashMap always rounds up
to the next power of 2. `new HashMap<>(1000)` -> actual capacity = 1024. To avoid even one resize
with 1000 entries: `capacity = (int)(expectedSize / loadFactor) + 1 = 1334` -> rounds up to 2048.
Using the Guava `Maps.newHashMapWithExpectedSize(1000)` handles this calculation correctly. The performance
difference is usually small for one HashMap, but when building many HashMaps in a loop (e.g., building
a response object for each request): the cumulative resize cost is measurable. In a tight loop building
10,000 HashMaps each with 100 entries: pre-sizing saves 7 * 10,000 = 70,000 rehash operations.

---

**Q3 (enummap): When should you prefer EnumMap over HashMap?**

A: Whenever the keys are an Enum type. EnumMap is backed by an array indexed by the enum's ordinal.
Get/put: array index lookup (single array access, O(1) with zero hash computation). No hash function,
no bucket computation, no equals() call. Memory: one entry per enum constant (compact, no wasted
buckets). Iteration: array iteration (cache-friendly, sequential). HashMap comparison: HashMap requires
hash computation + bitwise AND + possible bucket chain traversal + equals() check. For frequent
get/put on enum-keyed maps: EnumMap is 5-10x faster than HashMap.

*What separates good from great:* The composite pattern for EnumMap in a hot path: if you have
`Map<Status, Map<Type, Count>>` where Status and Type are both Enum: use `EnumMap<Status, EnumMap<Type, Count>>`.
Both levels are array-backed, no hashing at either level. For a 4-Status x 8-Type grid: the inner map
is just an 8-element array. A status+type lookup: two array dereferences. Compare to HashMap<Status, HashMap<Type, Count>>: two hash computations, two bucket lookups, two equals() checks. For metrics tracking (hot path for every request): the EnumMap<EnumMap<>> version is measurably faster and uses less memory.

---
