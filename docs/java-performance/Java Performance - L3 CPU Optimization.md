---
layout: default
title: "Java Performance - L3 CPU Optimization"
parent: "Java Performance"
nav_order: 5
permalink: /java-performance/l3-cpu-optimization/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [JIT Optimization and Inlining](#jit-optimization-and-inlining) | high |
| 2 | [Loop Optimization](#loop-optimization) | medium |
| 3 | [Cache-Friendly Data Structures](#cache-friendly-data-structures) | high |
| 4 | [Thread Contention Reduction](#thread-contention-reduction) | high |
| 5 | [False Sharing](#false-sharing) | high |

---

# JIT Optimization and Inlining

**Interview Weight:** high - Expert-level. Writing JIT-friendly
code requires understanding inlining, devirtualization, and
escape analysis.

---

### 🎯 Model Answer

**30 seconds:**

> JIT inlining replaces a method call with the callee's body,
> enabling further optimization. Inline limit: ~35 bytes bytecode.
> Methods that exceed this are never inlined. Key patterns that
> defeat inlining: megamorphic call sites (>2 observed implementations
> of an interface), large methods, excessive call depth (>9).
> Write small, single-purpose methods in hot paths to maximize
> inlining.

**3 minutes (Senior):**

> **Inlining threshold:**
> `-XX:MaxInlineSize=35` (bytes): methods under this threshold
> are always inlined (at any call frequency).
> `-XX:FreqInlineSize=325`: methods called frequently but over
> MaxInlineSize may be inlined up to this size.
>
> **Devirtualization:**
> JIT checks virtual method call sites for monomorphism:
> - Monomorphic (1 implementation seen): direct call, fully inlinable.
> - Bimorphic (2 implementations): type check + two direct calls.
>   Still inlinable.
> - Megamorphic (3+ implementations): vtable dispatch. Not inlinable.
>   This is the biggest JIT performance killer for interface-heavy code.
>
> **Escape analysis:**
> If an object is allocated in a method and does not escape
> (not returned, not stored in fields), JIT may:
> - Stack-allocate: the object lives on the stack, freed automatically.
> - Scalar-replace: decompose object into primitive fields.
>   No heap allocation. No GC reference. Fastest path.
>
> **On-stack replacement (OSR):**
> JIT can replace running interpreted code with compiled code
> mid-execution (at loop back-edges). This is how JIT handles
> long-running loops that were being interpreted at start.
>
> **Monitoring JIT decisions:**
> `-XX:+PrintCompilation`: logs each compilation.
> `-XX:+PrintInlining`: shows inlining decisions.
> `-XX:+UnlockDiagnosticVMOptions -XX:+PrintAssembly`: see generated
> machine code (requires hsdis plugin).

---

### 💻 Code Example

**Example 1: Writing JIT-friendly code**

```java
// PATTERN 1: Keep hot methods small (inlineable)
// BAD: 200-line validation method → never inlined
boolean validateOrder(Order order) {
    // line 1: null checks ...
    // line 50: business rules ...
    // line 150: complex formatting for error message ...
    // 200 lines total → bytecode >> 35 bytes → not inlined
}

// GOOD: dispatcher + small specializers (each ≤35 bytes bytecode)
boolean validateOrder(Order order) {
    return order != null                  // 5 bytes
        && validateAmount(order)          // 15 bytes
        && validateInventory(order)       // 20 bytes
        && validateDeliveryAddress(order); // 15 bytes
}
// Each sub-method is ≤35 bytes → all candidates for inlining
// JIT can see through the full validation chain

// PATTERN 2: Avoid megamorphic call sites
interface Validator { boolean validate(Order o); }

// BAD: many implementations → megamorphic → not devirtualized
class Service {
    List<Validator> validators = List.of(
        new NullValidator(), new AmountValidator(),
        new InventoryValidator(), new AddressValidator()  // 4+ impls
    );
    boolean isValid(Order o) {
        // Loop calling validate() with 4 different implementations:
        // call site becomes megamorphic → JIT cannot inline any
        return validators.stream().allMatch(v -> v.validate(o));
    }
}
// GOOD: concrete composition or sealed hierarchy
sealed interface Validator permits NullValidator, AmountValidator { ... }
// JIT can see the full implementation set and devirtualize

// PATTERN 3: Escape analysis exploitation
// BAD: Point escapes method (stored in field) → heap allocated
class PathTracker {
    List<Point> history = new ArrayList<>();

    void move(int dx, int dy) {
        Point newPos = new Point(x + dx, y + dy);  // escapes → heap
        history.add(newPos);
    }
}

// GOOD: compute only the primitive result (no Point allocation)
void move(int dx, int dy) {
    int newX = x + dx;  // primitives: no allocation
    int newY = y + dy;
    x = newX; y = newY;
    // Point never created → escape analysis not needed
}

// CHECK inlining decisions:
// java -XX:+PrintCompilation -XX:+PrintInlining -jar app.jar 2>&1 | grep validateOrder
// Output:
//   @ 5   validateAmount (15 bytes)   inlined
//   @ 20  validateInventory (20 bytes)  inlined
//   ...
// If NOT inlined: "not inlineable" or "too large"
```

> **Code walkthrough:** The dispatcher pattern keeps each method
> under the inline threshold. JIT sees: `validateOrder` calls
> `validateAmount`. `validateAmount` is 15 bytes → inlined into
> `validateOrder`. Now JIT sees the combined logic and can apply
> further optimization (constant folding, branch prediction).
> The Point example shows why domain objects should be computed
> as primitives when possible - `int x, int y` never requires
> heap allocation.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JIT inlines small methods (≤35 bytes bytecode). Keep hot methods
> small. Interface call sites with >2 implementations become
> megamorphic and prevent inlining. Use `-XX:+PrintCompilation`
> to see what JIT compiles.

---

**Senior / Staff (5+ years):**

> The megamorphic call site trap is the most subtle JIT performance
> issue. I've seen 40% throughput drops from adding a third
> implementation of a hot interface. I check for megamorphic
> sites in async-profiler output - if a virtual call appears
> hot, I investigate the polymorphism. Sealing interfaces
> (Java 17+) helps the JIT by limiting the implementation set.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "Your service regressed 30% after adding a new Transformer
  implementation. How would you investigate?"

🗣️ "First hypothesis: megamorphic call site. The service previously
had 2 `Transformer` implementations (bimorphic) and JIT was
devirtualizing the call. Adding a third made it megamorphic -
JIT now uses vtable dispatch, cannot inline, and loses all
downstream optimizations. Investigation: (1) Confirm with
`-XX:+PrintCompilation`. Look for the `Transformer.transform()`
call site being recompiled after the third implementation is
loaded. (2) Confirm with async-profiler. The flame graph will
show the `transform()` dispatch itself consuming CPU (it shouldn't
if inlined). (3) Fix options: (a) refactor to a concrete class
hierarchy instead of interface; (b) use a sealed interface
(Java 17+) to tell JIT the implementation set is bounded;
(c) restructure the hot path to dispatch explicitly with a switch
or if-else on type, allowing the JIT to devirtualize each branch."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Inline threshold, devirtualization, escape analysis. |
| Hiring Manager   | JIT-friendly coding practices. |
| Bar Raiser       | OSR, C1 vs C2 decisions, PrintAssembly, tiered compilation events. |
| Peer Engineer    | "Third implementation of our hot parser interface killed JIT inlining..." |

---

---

# Loop Optimization

**Interview Weight:** medium - Tests awareness of JIT loop
optimizations and how to write loops the JIT can optimize well.

---

### 🎯 Model Answer

**30 seconds:**

> JIT applies several loop optimizations: loop unrolling (execute
> multiple iterations per cycle to reduce branch overhead),
> vectorization (use SIMD to process multiple elements at once),
> range check elimination (hoist array bounds checks out of the
> loop body). Write loops that iterate over arrays with a simple
> index pattern to maximize JIT vectorization. Avoid changing
> array contents during iteration.

**3 minutes (Senior):**

> **Loop vectorization:**
> Modern CPUs support SIMD (Single Instruction Multiple Data):
> process 4-16 elements in one instruction (AVX, SSE).
> JIT automatically vectorizes loops that:
> - Iterate over arrays with integer index counter.
> - Have no data dependencies between iterations.
> - Use simple operations: add, multiply, max, min.
> - Have no method calls inside (unless inlined).
>
> **Range check elimination:**
> JIT hoists `array[i]` bounds checks out of loops:
> `if (i >= 0 && i < array.length)`. After hoisting, only one
> check at loop entry. This is why `for (int i = 0; i < array.length; i++)`
> is faster than random access with variable indices.
>
> **Loop unrolling:**
> JIT replicates the loop body N times and adjusts the increment.
> `for (int i=0; i<n; i+=4) { body; body; body; body; }`
> Reduces branch overhead. Enabled automatically.
>
> **Iterator vs index loop:**
> For `ArrayList` and arrays: indexed loop (`for (int i=0; i<n; i++)`)
> is faster than enhanced for loop (`for (String s : list)`) for
> performance-critical paths because it avoids `Iterator` object
> creation and `hasNext()/next()` virtual calls.
>
> **What prevents vectorization:**
> - Loop body contains a method call that cannot be inlined.
> - Data dependency: `array[i] = array[i-1] + 1` (depends on previous).
> - Writing to indices other than `i`.

---

### 💻 Code Example

**Example 1: Vectorizable and non-vectorizable loops**

```java
// VECTORIZABLE: simple indexed, independent operations
// JIT will use SIMD (AVX) to process 4-8 elements per instruction
double[] prices;
double[] quantities;
double[] totals;

void calculateTotals() {
    for (int i = 0; i < prices.length; i++) {
        totals[i] = prices[i] * quantities[i];
        // Each iteration independent: JIT can vectorize
        // AVX-256: 4 doubles processed in one instruction
        // 4x throughput compared to scalar loop
    }
}

// NOT VECTORIZABLE: dependency between iterations
void computeRunningTotal(double[] values, double[] running) {
    running[0] = values[0];
    for (int i = 1; i < values.length; i++) {
        running[i] = running[i-1] + values[i];
        // running[i] depends on running[i-1]: serial dependency
        // Cannot vectorize: must compute in order
    }
}

// BETTER LOOP PERFORMANCE: avoid iterator overhead in hot path
// BAD: Iterator object allocation per loop
for (String name : names) {  // creates Iterator<String>
    process(name);
}

// GOOD for ArrayList: index loop (no Iterator allocation)
for (int i = 0, n = names.size(); i < n; i++) {
    process(names.get(i));
}
// Note: names.size() cached in n: avoids size() call per iteration

// BAD: range check NOT eliminated (JIT can't prove safety)
int[] lookup;
void processWithRandomAccess(int[] indices) {
    for (int i = 0; i < indices.length; i++) {
        int val = lookup[indices[i]];  // random access: bounds check per iteration
        process(val);
    }
}

// VERIFY vectorization:
// javap -p -c ClassName | grep "invokevirtual\|vectoriz"
// -XX:+PrintCompilation with Graal JIT: shows vectorization events
// async-profiler: see wide bar in SIMD instructions in perf output
```

> **Code walkthrough:** The `calculateTotals()` loop is the
> canonical vectorizable pattern: fixed stride, no dependencies,
> simple arithmetic. The `running total` loop demonstrates why
> prefix-sum computations cannot be vectorized - each element
> depends on the previous. Caching `names.size()` in `n` before
> the loop eliminates one virtual call per iteration; at 1M
> iterations, this matters.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JIT can vectorize loops that process arrays with independent
> operations. Use indexed loops for ArrayList in hot paths.
> Simple array operations (multiply, add) over fixed arrays are
> most JIT-friendly.

---

**Senior / Staff (5+ years):**

> Loop optimization matters most for numerical/data processing
> code. I verify vectorization using async-profiler with hardware
> counter events. For general business logic, JIT loop
> optimization is secondary - algorithm choice dominates.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "How does JIT eliminate range checks in array loops?"

🗣️ "Range check elimination is a JIT optimization that hoists
array bounds checks out of loops. Normally, `array[i]` compiles
to: check `i >= 0`, check `i < array.length`, then access. For
a loop `for (int i = 0; i < array.length; i++)`, JIT can prove:
(1) i starts at 0 (≥ 0 guaranteed), (2) the loop condition
guarantees `i < array.length` at each access. So JIT replaces
the per-iteration bounds check with a single loop-entry check.
This eliminates one conditional branch per array access - for
vectorized loops processing 4 elements at once, this is a
meaningful savings. The optimization does NOT apply when the
index is derived from an expression (e.g., `array[i + offset]`
where `offset` is unknown) - the JIT cannot prove the derived
index is in bounds without the runtime check."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Vectorization conditions, range check elimination. |
| Hiring Manager   | Loop best practices for performance-sensitive code. |
| Bar Raiser       | AVX instructions, JIT auto-vectorization flags, SIMD in streams. |
| Peer Engineer    | "Switching from for-each to index loop cut our sorting step by 15%..." |

---

---

# Cache-Friendly Data Structures

**Interview Weight:** high - CPU cache effects are the hidden
performance variable that benchmarks often miss.

---

### 🎯 Model Answer

**30 seconds:**

> CPU cache miss latency: L1 hit = 1ns, L2 = 5ns, L3 = 25ns,
> DRAM = 100ns. A data structure accessed with poor locality
> causes DRAM-speed access instead of cache-speed. Linked lists
> are cache-unfriendly (pointers to arbitrary heap locations).
> Arrays are cache-friendly (sequential memory). In Java, use
> arrays and array-backed collections for hot data paths.
> Object field layout matters: frequently co-accessed fields
> should be in the same class (same cache line).

**3 minutes (Senior):**

> **CPU cache lines:**
> CPU loads memory in 64-byte cache lines. When you access one
> field of an object, the entire 64-byte line is loaded. If that
> line contains 7 other useful fields, subsequent accesses are
> free. If the line contains unrelated data, the load "wastes"
> 56 bytes.
>
> **Array of Objects (AoO) vs Array of Struct (AoS) - Java's challenge:**
> Java stores objects on the heap with object headers. An array
> of objects is an array of *pointers*. Following each pointer
> can be a cache miss. There is no true struct-in-array layout
> in Java (yet - Project Valhalla's value types will fix this).
>
> **Cache-friendly patterns in Java:**
> - Use `int[]` instead of `Integer[]` (no pointers, sequential ints).
> - Group hot fields together in a class (JVM field layout is not
>   always field declaration order).
> - Use `ArrayList` instead of `LinkedList` (array-backed, sequential).
> - For hot object arrays: keep objects small and accessed in order.
>
> **Contended annotation (JDK 8+):**
> `@sun.misc.Contended` pads a field to its own cache line.
> Prevents false sharing (see False Sharing keyword).
> Use only for per-thread or per-lock counters.

---

### 💻 Code Example

**Example 1: Cache-friendly vs cache-unfriendly patterns**

```java
// CACHE-UNFRIENDLY: LinkedList (pointer chasing)
// Each node is a separate heap allocation, random memory location
LinkedList<Transaction> transactions = new LinkedList<>();
// Iterating: node1 → pointer → node2 (random location → cache miss)
//            node2 → pointer → node3 (another random location)
// Each iteration likely a cache miss: 100ns per element instead of 1ns

// CACHE-FRIENDLY: ArrayList (sequential array)
ArrayList<Transaction> transactions = new ArrayList<>(1000);
// Underlying array: [t0][t1][t2]...[t999] → sequential in memory
// CPU prefetcher loads ahead: most accesses hit L1 cache

// CACHE-FRIENDLY: primitive arrays (no object headers, pure data)
// BAD: array of objects (headers + pointer indirection)
double[] prices;   // 8 bytes per element, sequential (CACHE FRIENDLY)
Double[] boxed;    // 8 bytes pointer → 24 bytes on heap per Double (UNFRIENDLY)

// Processing 1,000,000 prices:
// double[]: ~8MB sequential → fits in L3 cache → fast
// Double[]: 8MB pointers + 24MB scattered objects → mostly DRAM access → slow

// CACHE-FRIENDLY: SoA (Structure of Arrays) pattern
// For hot computation over a subset of fields:

// BAD: Array of Objects (AoO) - full object accessed for each element
record Product(long id, String name, double price, int stock, String category) {}
Product[] products = new Product[1_000_000];
// Computing total value: access products[i].price AND products[i].stock
// Each Product is ~80 bytes. Loading price/stock loads 80 bytes of object.
// 60 bytes wasted per cache line (id, name, category not needed).

// GOOD: Structure of Arrays (SoA) - pure data fields
double[] prices   = new double[1_000_000];  // 8MB sequential
int[]    stocks   = new int[1_000_000];     // 4MB sequential
// Computing total value: prices[i] * stocks[i]
// Only 12 bytes accessed per element → 5x more elements per cache line
// Same computation: 5-10x faster due to cache locality

double computeTotalValue(double[] prices, int[] stocks, int n) {
    double total = 0;
    for (int i = 0; i < n; i++) {
        total += prices[i] * stocks[i];  // vectorizable + cache friendly
    }
    return total;
}
```

> **Code walkthrough:** The SoA (Structure of Arrays) pattern is
> the Java equivalent of CPU-cache-optimized data layout. By
> separating `prices` and `stocks` into their own arrays, each
> array is sequential memory - the CPU prefetcher loads ahead
> and subsequent accesses hit L1/L2 cache. The Product AoO layout
> loads 80 bytes per product but only uses 12 - wasting 85% of
> each cache line. The SoA approach uses every byte loaded.

---

### ⚖️ Comparison

| Structure | Memory Layout | Cache Behavior | Trade-off |
|---|---|---|---|
| `LinkedList` | Random (pointer per node) | L3/DRAM per element | Never use for traversal |
| `ArrayList` | Sequential (array of refs) | L2 for refs, L3+ for objects | Good for traversal |
| `int[]` / `double[]` | Sequential, no pointers | L1/L2 for all data | Best for numerical loops |
| AoO (object array) | Sequential pointers, random objects | L3/DRAM per object | Good for small objects |
| SoA (field arrays) | Multiple sequential arrays | L1/L2 per computation | Best for field-subset ops |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Arrays are cache-friendly, LinkedList is cache-unfriendly.
> Use ArrayList over LinkedList. Primitive arrays over boxed
> arrays. Cache line = 64 bytes - objects that fit in one line
> are efficient.

---

**Senior / Staff (5+ years):**

> Cache effects are the hardest performance factor to reason
> about from code. I use async-profiler with `perf_events` hardware
> counters to measure cache miss rates. SoA layout is appropriate
> for data processing code operating on subsets of fields.
> For business logic objects, AoO is fine - the object count
> is low enough that cache misses don't dominate.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "Why would a LinkedList perform worse than ArrayList for
  iteration even if both are O(n)?"

🗣️ "Both are O(n) algorithmic complexity but LinkedList has
much worse constant factors due to memory locality. LinkedList
stores each node as a separate heap object with a `prev`, `next`
pointer, and value. Node objects are allocated independently at
random heap locations. Iterating: follow pointer from node to
next node → each pointer dereference can cause a CPU cache miss
(100ns). For 100,000 elements, this is potentially 100,000 cache
misses × 100ns = 10ms just for pointer dereferencing.
ArrayList stores elements in a contiguous array. The CPU's
hardware prefetcher detects sequential access and loads ahead:
by the time you access element 100, elements 101-108 are already
in L1 cache (they fit in the same or adjacent cache lines).
The same 100,000 element traversal: ~100,000 ns × 1ns = 0.1ms.
100x faster, same O(n) complexity. The difference: memory layout,
not algorithmic complexity."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Cache line size, pointer chasing, SoA pattern. |
| Hiring Manager   | ArrayList vs LinkedList decision, practical impact. |
| Bar Raiser       | CPU prefetcher, false sharing, hardware performance counters. |
| Peer Engineer    | "We switched 200k-element LinkedList to ArrayList - 20x speed improvement..." |

---

---

# Thread Contention Reduction

**Interview Weight:** high - Core scalability skill. Tests
knowledge of lock-free, striped, and immutable designs.

---

### 🎯 Model Answer

**30 seconds:**

> Thread contention occurs when multiple threads compete for the
> same lock. Solutions: reduce lock scope (hold locks for the
> minimum time), use finer granularity (ConcurrentHashMap's
> striped buckets), use lock-free structures (AtomicLong, LongAdder),
> or eliminate sharing (thread-local state, immutable data).
> Profile contention with JFR `jdk.JavaMonitorEnter` events.
> `LongAdder` outperforms `AtomicLong` for high-contention counters.

**3 minutes (Senior):**

> **Contention reduction hierarchy:**
>
> 1. **Eliminate sharing**: the best lock is no lock. If each thread
>    has its own data copy (ThreadLocal, per-thread queue), no
>    contention is possible.
>
> 2. **Immutable data**: read-only objects need no locking.
>    Replace mutable shared state with immutable snapshots swapped
>    atomically (`AtomicReference<Config>`).
>
> 3. **Lock-free structures**: `AtomicLong`, `AtomicReference`,
>    `ConcurrentHashMap`. Use CAS (compare-and-swap) instead of
>    mutexes. CAS is hardware-supported: atomic at CPU level.
>    Cost: CAS retries under contention. `LongAdder` avoids
>    contention by striping across per-thread cells.
>
> 4. **Striping**: divide the lock space. `ConcurrentHashMap`
>    uses 16 buckets internally. Only operations on the same bucket
>    contend. 16x less contention than a single synchronized map.
>
> 5. **ReadWriteLock**: for read-heavy data, allows concurrent reads.
>    `StampedLock` adds optimistic reads (no lock acquisition for
>    reads if no writer active).
>
> **LongAdder vs AtomicLong:**
> `AtomicLong.incrementAndGet()` uses CAS which retries under
> contention. Under high contention (100+ threads), retry rate
> is high. `LongAdder` maintains per-cell (per-CPU) counters,
> aggregated on read. Near-linear scaling with thread count.
> Use `LongAdder` for high-contention counters; `AtomicLong`
> when the latest value must always be readable atomically.

---

### 💻 Code Example

**Example 1: Contention reduction patterns**

```java
// PATTERN 1: Replace AtomicLong with LongAdder for hot counters
// BAD: AtomicLong under high contention
AtomicLong requestCount = new AtomicLong();
// 1000 threads incrementing: heavy CAS contention
requestCount.incrementAndGet();  // may retry 100+ times under load

// GOOD: LongAdder (striped per CPU)
LongAdder requestCount = new LongAdder();
requestCount.increment();        // per-cell counter, no contention
long total = requestCount.sum(); // aggregate on read (slightly expensive)

// PATTERN 2: Reduce lock scope
// BAD: long critical section with I/O inside lock
synchronized void processRequest(Request req) {
    validate(req);              // 1ms (no shared state needed)
    User user = db.load(req);   // 20ms DB call (no lock needed)
    update(sharedState, user);  // 0.1ms (needs lock)
}
// Total lock hold: 21ms → throughput: 1/21ms = 47 RPS max

// GOOD: lock only what requires it
void processRequest(Request req) {
    validate(req);              // outside lock
    User user = db.load(req);   // outside lock (20ms DB call)
    synchronized (this) {
        update(sharedState, user); // only 0.1ms lock hold
    }
}
// Lock hold: 0.1ms → throughput: 1/0.1ms = 10,000 RPS

// PATTERN 3: Immutable snapshot swap
// BAD: readers acquire lock to read config
synchronized String getEndpoint() {
    return config.endpoint;  // read acquires write lock: contention
}

// GOOD: immutable snapshot, zero locking for reads
record Config(String endpoint, int timeout) {}
AtomicReference<Config> configRef = new AtomicReference<>(
    new Config("https://api.example.com", 5000)
);

// Readers: no lock
String endpoint = configRef.get().endpoint();

// Writers: single CAS (rare)
void updateEndpoint(String newEndpoint) {
    configRef.updateAndGet(c -> new Config(newEndpoint, c.timeout()));
}
```

> **Code walkthrough:** The lock scope reduction is the most
> impactful pattern. Moving the 20ms DB call outside the
> synchronized block increases maximum throughput from 47 to
> 10,000 RPS - without changing any algorithm. The immutable
> snapshot pattern takes this further: by making the shared
> state immutable, reads require no synchronization at all.
> The only lock cost is the rare write (config update), not
> the millions of reads.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Reduce lock scope, use ConcurrentHashMap, LongAdder for
> high-frequency counters. Never hold locks during I/O.

---

**Senior / Staff (5+ years):**

> I design for immutability first - no shared mutable state, no
> contention. Where mutation is needed, I use `AtomicReference`
> for config/state snapshots and `LongAdder` for metrics counters.
> I measure contention with JFR lock profiling before optimizing.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "When would you use a ReadWriteLock instead of synchronized?"

🗣️ "`ReadWriteLock` is appropriate when reads are frequent and
reads can proceed concurrently (no state change), while writes
are rare. The rule: if reads are >10x more frequent than writes,
ReadWriteLock can provide significant throughput improvement.
Example: a user permission cache reads millions of times per minute
but writes (permission changes) happen once per minute.
With synchronized: all reads and writes serialize. ReadWriteLock:
1,000 readers can execute concurrently, only writers block.
The cost: ReadWriteLock is heavier than synchronized (more objects,
more state). Under high write contention, it's slower than
synchronized. StampedLock goes further with optimistic reads:
readers don't acquire any lock, they get a stamp and validate
afterward. Fastest for read-dominated access but more complex
code. My default: start with synchronized for correctness,
switch to ReadWriteLock when profiling shows lock contention
on a read-dominated path."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | LongAdder mechanics, lock scope, immutable snapshot pattern. |
| Hiring Manager   | Contention diagnosis, practical design. |
| Bar Raiser       | StampedLock optimistic reads, CLH queue in ReentrantLock. |
| Peer Engineer    | "Moving DB call outside synchronized improved our p99 by 10x..." |

---

---

# False Sharing

**Interview Weight:** high - Advanced CPU-level performance.
Tests knowledge of cache line contention between unrelated data.

---

### 🎯 Model Answer

**30 seconds:**

> False sharing occurs when two threads write to different variables
> that happen to reside in the same CPU cache line (64 bytes).
> Even though the variables are logically independent, the cache
> coherence protocol invalidates the entire cache line on each
> write, forcing the other CPU to reload it. Result: a highly
> contended shared mutable state performance profile with no
> actual contention in the code. Fix: pad fields to separate
> cache lines using `@Contended`.

**3 minutes (Senior):**

> **CPU cache coherence (MESI protocol):**
> CPUs coordinate cache line ownership. If CPU 1 holds a cache
> line in Exclusive state, CPU 2 requesting the same line forces
> CPU 1 to flush and CPU 2 to reload: ~100ns. This happens even
> if CPU 1 and CPU 2 are writing to different bytes of the same
> 64-byte line.
>
> **False sharing symptoms:**
> - High throughput loss for operations that should scale linearly
>   with thread count.
> - Thread count increases do not improve throughput (or worsen it).
> - `perf stat -e cache-misses` shows high L1 cache miss rate.
> - async-profiler with `cache-misses` event shows the hot location.
>
> **Affected patterns:**
> - Per-thread counters in an array: `long[] counters` where
>   `counters[0]` is thread 0's counter and `counters[1]` is
>   thread 1's. If they're adjacent, they share a cache line.
> - Related fields in the same class that different threads write
>   independently: `head` and `tail` pointers of a concurrent queue.
>
> **Fixes:**
> - `@jdk.internal.vm.annotation.Contended` (Java 8+, JDK-internal):
>   pads the field with 64-byte buffers before and after.
>   Available to JDK classes; use `-XX:-RestrictContended` for
>   application classes.
> - Manual padding: add 7 dummy `long` fields after the contended
>   field (7 × 8 bytes = 56 bytes + 8 bytes field = 64 bytes = 1 line).
> - Redesign: avoid shared arrays of per-thread values.

---

### 💻 Code Example

**Example 1: False sharing detection and fix**

```java
// FALSE SHARING: two logically independent counters share a cache line
class MetricsCounters {
    volatile long requestCount;   // offset 16 (object header = 16 bytes)
    volatile long errorCount;     // offset 24 (same 64-byte line!)
    // requestCount and errorCount are in the same cache line:
    // [header 16 bytes][requestCount 8 bytes][errorCount 8 bytes]
    // Thread A writes requestCount → invalidates errorCount's line on Thread B
    // Thread B writes errorCount → invalidates requestCount's line on Thread A
    // Effect: two threads updating unrelated counters cause mutual invalidation
}

// SYMPTOM: counter update throughput doesn't scale with threads
// 1 thread: 500M ops/sec
// 2 threads: 200M ops/sec (EXPECTED: 1000M)  ← false sharing!
// 4 threads: 150M ops/sec ← getting worse

// FIX 1: @Contended (JDK internal, use in library code)
class MetricsCounters {
    @jdk.internal.vm.annotation.Contended
    volatile long requestCount;  // padded to its own cache line
    @jdk.internal.vm.annotation.Contended
    volatile long errorCount;    // padded to its own cache line
}
// Enable: -XX:-RestrictContended for application code

// FIX 2: Manual padding (portable, no JVM flag needed)
class PaddedCounter {
    // 8 bytes header part 1 (before field)
    long p1, p2, p3, p4, p5, p6, p7;  // 56 bytes padding before
    volatile long value;                // 8 bytes = 64 bytes total (own cache line)
    long q1, q2, q3, q4, q5, q6, q7;  // 56 bytes padding after
}

// FIX 3: LongAdder (JDK solution that avoids false sharing internally)
// LongAdder maintains Striped64 cells, one per CPU/thread
// Cells are padded internally to avoid false sharing
LongAdder requestCount = new LongAdder();
LongAdder errorCount   = new LongAdder();
// Both scale linearly with thread count

// DETECT false sharing:
// perf stat -e L1-dcache-load-misses,L1-dcache-loads ./app
// High L1-dcache-load-misses with low expected miss rate = false sharing

// async-profiler with cache-miss events:
// ./asprof -d 30 -e L1-dcache-load-misses -f /tmp/cm.html $PID
// Flame graph: hot → MetricsCounters field access
```

> **Code walkthrough:** The padded counter (FIX 2) adds 7 `long`
> fields before and after the contended field. This guarantees
> the `value` field is the only field in its 64-byte cache line.
> Thread A and Thread B each have exclusive ownership of different
> cache lines - no coherence traffic between them. `LongAdder`
> (FIX 3) is the practical solution: it handles the padding
> internally using Striped64's padded cells, and provides
> near-linear scaling for counter workloads.

---

### ⚖️ Comparison

| Solution | How it Works | Overhead | Code Complexity |
|---|---|---|---|
| @Contended | JVM-level padding (128 bytes) | Memory (~128B/field) | Low |
| Manual padding | 7 dummy fields | Memory (~112B/field) | Medium |
| LongAdder | Per-CPU cell with internal padding | Cell creation | Low |
| Redesign (per-thread) | No sharing at all | None | Medium-High |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> False sharing happens when two threads write to variables in
> the same cache line. Symptoms: counter updates don't scale.
> Fix: `@Contended` or `LongAdder`. Detect with perf cache miss
> counters.

---

**Senior / Staff (5+ years):**

> False sharing is insidious because nothing in the code shows
> it. I check for it when benchmarks show worse performance with
> more threads. The JDK's `LongAdder` and `ConcurrentHashMap`
> are designed to avoid it. I use `@Contended` for high-frequency
> per-thread mutable state (LMAX Disruptor uses this extensively).

---

### ❓ Questions You Will Be Asked

#### Debugging

- "Your thread-safe counter benchmark shows worse throughput
  with 8 threads than with 2. What could cause this?"

🗣️ "This is a classic false sharing symptom. Two mechanisms:
(1) If the counter is an array (`long[] counters`) with one
element per thread, adjacent elements likely share cache lines.
Thread 0 writes `counters[0]`, invalidating the cache line
containing `counters[1]`, `counters[2]`, etc. Threads 1-7 must
reload from DRAM on every write. With 8 threads, there are 7
invalidations per increment - throughput crashes. (2) If using
`AtomicLong`, high CAS contention causes retry loops. Under 8
threads, contention is 4x higher than 2 threads. `LongAdder`
fixes both: it uses per-CPU cells padded to their own cache
lines, and cells never contend with each other. I would verify
with async-profiler `-e L1-dcache-load-misses` to confirm cache
misses are the bottleneck, then switch from `long[] counters`
to `LongAdder[]` or a striped counter design."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | MESI protocol, cache line size, @Contended. |
| Hiring Manager   | Recognition and diagnosis of false sharing. |
| Bar Raiser       | Striped64 internals, LMAX Disruptor RingBuffer padding, hardware prefetcher. |
| Peer Engineer    | "Our metrics array was false sharing across 16 threads - LongAdder fixed it instantly..." |
