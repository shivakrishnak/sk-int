---
layout: default
title: "Java Performance - L1 Foundations"
parent: "Java Performance"
nav_order: 2
permalink: /java-performance/l1-foundations/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Benchmarking with JMH](#benchmarking-with-jmh) | high |
| 2 | [CPU Profiling Basics](#cpu-profiling-basics) | high |
| 3 | [Memory Profiling Basics](#memory-profiling-basics) | high |
| 4 | [Latency vs Throughput](#latency-vs-throughput) | medium |
| 5 | [Performance Anti-patterns Overview](#performance-anti-patterns-overview) | medium |

---

# Benchmarking with JMH

**Interview Weight:** high - The standard Java benchmarking
tool. Tests whether the candidate can write valid microbenchmarks
and interpret results.

---

### 🎯 Model Answer

**30 seconds:**

> JMH (Java Microbenchmark Harness) is the standard for Java
> microbenchmarks. It handles: JIT warmup (runs the benchmark
> code until C2 compiles it), dead code elimination (via
> Blackhole), constant folding prevention (via @State), and
> statistical reporting (mean, confidence intervals per fork).
> Use `@BenchmarkMode`, `@OutputTimeUnit`, `@Warmup`, `@Measurement`,
> and `@Fork`. Maven archetype: `maven-archetype-jmh`.

**3 minutes (Senior):**

> **Key JMH annotations:**
>
> `@Benchmark`: marks a method as a benchmark entry point.
> JMH calls it in a loop during measurement.
>
> `@BenchmarkMode`: measurement type.
> - `Mode.AverageTime`: average time per operation (most common).
> - `Mode.Throughput`: operations per time unit.
> - `Mode.SampleTime`: statistical distribution (p50, p99).
> - `Mode.SingleShotTime`: single invocation (measures cold start).
>
> `@State(Scope.Thread)`: per-thread state. Each thread gets
> its own state object. Prevents sharing overhead from skewing
> results. `Scope.Benchmark`: shared state (for contention tests).
>
> `@Param`: drives parameterized benchmarks. The JIT treats
> `@Param` fields as non-constant, preventing constant folding.
>
> `@Fork(N)`: run N separate JVM processes. Each fork is a
> statistically independent measurement. 3+ forks recommended.
>
> `@Setup` / `@TearDown`: per-benchmark or per-iteration setup.
> Use `Level.Trial` (once per fork) or `Level.Iteration` (each measurement).
>
> **Reading results:**
> ```
> Benchmark    Mode  Cnt   Score   Error  Units
> myBenchmark  avgt    30  123.4 ±  5.2  ns/op
> ```
> Error ± 5.2 = 95% confidence interval. If two benchmarks'
> confidence intervals overlap, the difference is not statistically
> significant.

---

### 💻 Code Example

**Example 1: Complete JMH benchmark with common scenarios**

```java
// pom.xml dependency:
// <dependency>
//   <groupId>org.openjdk.jmh</groupId>
//   <artifactId>jmh-core</artifactId>
//   <version>1.37</version>
// </dependency>

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@State(Scope.Thread)
@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 10, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(value = 3, jvmArgs = {"-Xms2g", "-Xmx2g"})
public class CollectionBenchmark {

    // @Param: JIT cannot constant-fold size (it's not a compile-time const)
    @Param({"100", "10000", "1000000"})
    private int size;

    private List<Integer> arrayList;
    private List<Integer> linkedList;

    // Setup runs once per trial (fork), not per iteration
    @Setup(Level.Trial)
    public void setup() {
        arrayList = new ArrayList<>(size);
        linkedList = new LinkedList<>();
        for (int i = 0; i < size; i++) {
            arrayList.add(i);
            linkedList.add(i);
        }
    }

    // BAD: benchmarking without consuming result (JIT may eliminate)
    @Benchmark
    public void badBenchmark_resultUnused() {
        int sum = 0;
        for (int x : arrayList) { sum += x; }
        // sum is never used → JIT may eliminate the entire loop
    }

    // GOOD: return result (JMH consumes it)
    @Benchmark
    public int arrayListIteration() {
        int sum = 0;
        for (int x : arrayList) { sum += x; }
        return sum;  // JMH uses the return value to prevent elimination
    }

    // GOOD: use Blackhole for multiple results
    @Benchmark
    public void linkedListIteration(Blackhole bh) {
        int sum = 0;
        for (int x : linkedList) { sum += x; }
        bh.consume(sum);  // Blackhole prevents dead code elimination
    }
}

// Run from command line:
// java -jar target/benchmarks.jar CollectionBenchmark -rf json -rff results.json
// Java 21+ can also use @BenchmarkMode on class level for defaults
```

> **Code walkthrough:** `@Setup(Level.Trial)` populates the lists
> once per JVM fork, not once per measurement iteration - this
> ensures GC from setup does not interfere with measurements.
> The `badBenchmark_resultUnused()` method shows the dead code
> elimination pitfall: the loop result is never used, so JIT may
> remove it. Returning the result (or using `Blackhole.consume()`)
> forces JIT to preserve the computation.

---

### ⚖️ Comparison

| Approach | Valid? | Issue |
|---|---|---|
| `System.currentTimeMillis()` loop | No | No warmup, no stats, GC interference |
| JMH `Mode.AverageTime` | Yes | Best for latency comparison |
| JMH `Mode.SampleTime` | Yes | Best for percentile analysis |
| JMH `@Fork(1)` | Risky | Single JVM may have JIT outliers |
| JMH `@Fork(3+)` | Best | Statistical independence across JVMs |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JMH handles warmup, dead code elimination, and statistics.
> Use @Benchmark, @State, @Warmup, @Measurement, @Fork. Never
> benchmark with System.nanoTime() in a loop - JIT will make
> results meaningless.

---

**Senior / Staff (5+ years):**

> I use JMH as a regression guard: baseline benchmarks in CI
> and alert if p99 regresses by >10%. Key things I watch:
> high standard deviation (GC interference - add `@GcProfiler`
> to measure GC cost), overlapping confidence intervals (no
> statistical significance between the benchmarks - need more
> forks or longer measurement).

---

### ❓ Questions You Will Be Asked

#### Debugging

- "Your JMH benchmark shows 5ns per operation, but production
  code shows 50ns. What could explain the gap?"

🗣️ "Five likely explanations: (1) Constant folding - if the
benchmark inputs are constants (not @Param), JIT may precompute
the result. The benchmark measures a constant load, not actual
computation. (2) Benchmark isolation - the JMH benchmark runs
in a tight loop with no other concurrent allocations. Production
has GC pressure, CPU cache contention, and competing threads.
(3) Inlining - in the benchmark's tight loop, JIT aggressively
inlines and optimizes. Production may have a megamorphic call
site that prevents inlining. (4) Memory access patterns - the
benchmark's data fits in CPU L1/L2 cache. Production data is
much larger and causes L3 or main memory cache misses, which
cost 100-300ns each. (5) Input diversity - the benchmark uses
a few representative inputs. Production handles all real inputs
including worst-case paths the benchmark never exercises."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Annotations, dead code elimination, constant folding. |
| Hiring Manager   | Benchmark validity, CI regression detection. |
| Bar Raiser       | JMH profiler integration (@GcProfiler, @LinuxPerfNormProfiler). |
| Peer Engineer    | "We caught a 3x regression in PR review via JMH CI check..." |

---

---

# CPU Profiling Basics

**Interview Weight:** high - Core skill. Tests ability to
identify CPU hotspots and act on profiler output.

---

### 🎯 Model Answer

**30 seconds:**

> CPU profiling identifies which methods consume the most CPU time.
> Two approaches: sampling (periodically capture stack traces) and
> instrumentation (inject timing code into every method). Sampling
> is low-overhead (~1%), safe for production. Instrumentation is
> high-overhead but more accurate. Key output: flame graph (wider
> = more CPU). For JVM: JFR is the built-in sampling profiler.
> async-profiler avoids safepoint bias.

**3 minutes (Senior):**

> **Sampling profilers - the safepoint bias problem:**
> Traditional JVM profilers capture stack traces only at safepoints
> (safe points in code where the JVM can interrupt threads). Code
> between safepoints is never captured. This means methods that
> spend a lot of time between safepoints appear less hot than they
> are. Solutions: async-profiler uses OS signals (`SIGPROF`) to
> capture stacks at arbitrary points - no safepoint bias.
>
> **JFR CPU profiling:**
> `jdk.ExecutionSample` event samples stacks every ~10ms.
> Overhead: ~1%. View in JMC as flame graph. Best for: coarse
> identification of hot methods, production-safe profiling.
>
> **async-profiler:**
> Uses `perf_events` (Linux) or `dtrace` (macOS) to sample CPU.
> No safepoint bias. Overhead: ~2-3%. Outputs FLAMEGRAPH SVG
> directly. Best for: detailed CPU analysis, revealing code
> the JVM's safepoint-biased profiler misses.
>
> **Reading a flame graph:**
> - X-axis: alphabetical (NOT time). Width proportional to time in this frame.
> - Y-axis: call depth (bottom = bottom of stack, top = leaf method).
> - Wide bar at top = method consuming most CPU = optimization target.
> - Plateau: a method where CPU time accumulates (it's self-time).
>   Stacks don't go deeper from there = this method's code is the work.

---

### 💻 Code Example

**Example 1: Profiling workflow with async-profiler**

```bash
# Download async-profiler (Linux)
wget https://github.com/async-profiler/async-profiler/releases/latest/download/async-profiler-linux-x64.tar.gz
tar xzf async-profiler-linux-x64.tar.gz

# Attach to running JVM (30 second CPU profile)
./asprof -d 30 -f /tmp/profile.html <pid>
# → /tmp/profile.html opens as interactive flame graph in browser

# Or start with JVM:
java -agentpath:/path/to/libasyncProfiler.so=start,event=cpu,file=/tmp/p.html \
     -jar app.jar

# Built-in JFR profiling (lower resolution but zero overhead install)
jcmd <pid> JFR.start duration=60s settings=profile filename=/tmp/cpu.jfr
# Open in JMC → Code → Method Profiling → View Flame Graph

# Interpreting results: pseudo-example
# ┌─────────────────────────────────────────────────────┐
# │     UserService.processRequest() - 60% of CPU       │
# ├────────────────────────┬────────────────────────────┤
# │ UserDao.findUser()40%  │ OrderService.calc() 20%    │
# ├────────────────────────┤                            │
# │ HibernateSession 40%   │ BigDecimal.multiply() 20%  │
# └────────────────────────┴────────────────────────────┘
# Reading: processRequest() → findUser() uses 40% of CPU
# → findUser() calls HibernateSession: investigate DB query
# → calc() uses 20% via BigDecimal.multiply():
#   switch to double/float if precision allows (10x faster)
```

```java
// AFTER profiling: fixing the hotspot
// Profiler shows: BigDecimal.multiply() in inner loop = 20% CPU

// BAD: BigDecimal in tight loop (heavy allocation + slow ops)
BigDecimal total = BigDecimal.ZERO;
for (Order order : orders) {  // 100k orders
    total = total.add(
        order.price().multiply(BigDecimal.valueOf(order.quantity()))
    );
    // Each call: allocates 2-3 BigDecimal objects, heavy arithmetic
}

// GOOD: use long (pence/cents) internally, convert only for display
long totalCents = 0;
for (Order order : orders) {
    totalCents += order.priceInCents() * order.quantity();
    // Primitive arithmetic: zero allocation, CPU-native speed
}
BigDecimal result = new BigDecimal(totalCents).movePointLeft(2);
```

> **Code walkthrough:** The flame graph reading shows 60% of CPU
> in `processRequest()`, split 40% DB and 20% BigDecimal. The
> optimization targets the `BigDecimal` path: replacing it with
> `long` arithmetic eliminates all allocation in the hot path and
> replaces software-emulated precision with CPU-native integer
> arithmetic. Profiler directs the optimization - no guessing.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CPU profiling finds hot methods via stack sampling. Use JFR
> for production-safe profiling, async-profiler for accurate
> local profiling. Read flame graphs: wide = hot. Optimize the
> wide bars at the top of the flame.

---

**Senior / Staff (5+ years):**

> I prefer async-profiler to JFR for local profiling because it
> avoids safepoint bias - I've seen production issues where the
> real hot method didn't appear in JFR's safepoint-sampled output
> but was obvious in async-profiler's signal-based output.
> For production, continuous JFR is sufficient for coarse profiling.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "Your service is CPU-bound (90% CPU under moderate load).
  How would you profile and fix it?"

🗣️ "Step 1: Confirm the bottleneck is CPU, not GC.
`jstat -gcutil <pid>` - if GC threads consume <5% and the
application threads are busy, it's CPU-bound application code.
Step 2: Capture a CPU profile. In production I'd use JFR:
`jcmd <pid> JFR.start duration=60s settings=profile filename=/tmp/cpu.jfr`.
Locally I'd use async-profiler for a precise flame graph.
Step 3: Read the flame graph. Find the widest bar at the top
of the call stack - that is the most expensive self-work method.
Step 4: Diagnose the hot method. Common findings: O(n^2) loop,
BigDecimal math in a loop, JSON serialization on every call,
regex compilation on every invocation.
Step 5: Fix the root cause, not the symptom. Optimize the
algorithm, cache the expensive computation, or use a more
efficient library. Step 6: Measure again with the same JMH
benchmark or load test to confirm the improvement and quantify it."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Safepoint bias, async-profiler, flame graph reading. |
| Hiring Manager   | Profiling workflow, practical diagnosis. |
| Bar Raiser       | perf_events integration, JIT deoptimization in profile, wall-clock vs CPU profiling. |
| Peer Engineer    | "async-profiler revealed a hot regex compile the JFR profile completely missed..." |

---

---

# Memory Profiling Basics

**Interview Weight:** high - Core skill. Memory leaks and
excessive allocation are common Java production issues.

---

### 🎯 Model Answer

**30 seconds:**

> Memory profiling identifies: (1) allocation hotspots (what code
> creates the most objects), (2) memory leaks (what objects
> accumulate without being freed), and (3) heap structure
> (which objects use the most retained heap). Tools: JFR
> allocation profiling for hotspots, heap dump + Eclipse MAT
> for leaks and structure. Key MAT reports: Leak Suspects and
> Dominator Tree.

**3 minutes (Senior):**

> **Allocation profiling vs heap dump - when to use each:**
>
> Allocation profiling (JFR `jdk.ObjectAllocationInNewTLAB`):
> - Purpose: find what code creates the most objects per second.
> - When: high GC rate, high allocation rate. Want to reduce
>   the number of objects created.
> - Output: stack traces ranked by allocation volume.
>
> Heap dump (jmap, jcmd GC.heap_dump):
> - Purpose: snapshot of all live objects and references at one point.
> - When: heap growing over time (leak), or OOM.
> - Output: `.hprof` file. Analyze with Eclipse MAT.
>
> **Eclipse MAT analysis workflow:**
> 1. Open heap dump in MAT.
> 2. Run "Leak Suspects Report": MAT finds objects with large
>    retained heap that are likely leaks.
> 3. Dominator Tree: shows which objects "own" (retain) the most heap.
>    If `HashMap` at top dominates 80% of heap, something is
>    adding entries without removing them.
> 4. Histogram: count of objects by class. If `byte[]` count is
>    millions, look at what's holding the byte arrays.
> 5. OQL (Object Query Language): SQL-like queries over the heap.
>    Find all instances of a class with a specific field value.
>
> **Shallow heap vs retained heap:**
> - Shallow heap: memory of the object itself (fields only).
>   A `String` shallow heap = 24 bytes (length + hash + char[] ref).
> - Retained heap: memory freed IF this object were garbage collected
>   (includes all exclusively reachable objects).
>   A `String` retained heap = 24 + char[] size = 24 + 2*length bytes.

---

### 💻 Code Example

**Example 1: Allocation profiling workflow**

```java
// IDENTIFY: high GC rate → allocation profiling
// JFR allocation profiling command:
// jcmd <pid> JFR.start duration=60s settings=profile filename=/tmp/alloc.jfr
// Open in JMC → Memory → Allocation Profiling
// Sort by: Total Allocation (MB) → find top allocators

// COMMON FINDING: implicit String allocation
// BAD: allocates String on every call (even when log disabled)
log.debug("User " + userId + " accessed " + resourceId);
// String concat creates: "User " + userId → temp1,
//                        temp1 + " accessed " → temp2,
//                        temp2 + resourceId → final String
// 3 String allocations per call, all discarded if DEBUG disabled

// GOOD: SLF4J parameterized logging
log.debug("User {} accessed {}", userId, resourceId);
// Only evaluates if DEBUG is enabled → zero allocation 99% of the time

// IDENTIFY: heap growth → heap dump
// Take two dumps 10 minutes apart
jcmd <pid> GC.heap_dump /tmp/heap1.hprof
// (wait 10 minutes under production load)
jcmd <pid> GC.heap_dump /tmp/heap2.hprof
// Compare in MAT: "Compare Snapshots" → growing objects = leak

// COMMON FINDING: unbounded cache / map growth
// BAD: static cache with no eviction
private static final Map<String, Result> CACHE = new HashMap<>();

void process(String key) {
    CACHE.computeIfAbsent(key, k -> computeExpensive(k));
    // HashMap grows forever with every new key
    // After 1M unique keys: 80MB+ heap, never GC'd
}

// GOOD: bounded cache with eviction
private static final Map<String, Result> CACHE =
    Collections.synchronizedMap(
        new LinkedHashMap<>(1000, 0.75f, true) {  // LRU
            @Override
            protected boolean removeEldestEntry(Map.Entry<String, Result> e) {
                return size() > 1000;  // evict when > 1000 entries
            }
        }
    );
// Better: use Caffeine with size limit and TTL expiry
Cache<String, Result> cache = Caffeine.newBuilder()
    .maximumSize(1000)
    .expireAfterWrite(10, TimeUnit.MINUTES)
    .build();
```

> **Code walkthrough:** Allocation profiling reveals per-call
> waste (debug log string concat). Heap dump reveals accumulation
> (unbounded cache). The two-snapshot comparison is the standard
> leak diagnosis technique: objects that grow between snapshots
> under production load are likely leaks. The Caffeine cache fix
> bounds memory usage and adds TTL expiry to prevent stale data.

---

### ⚖️ Comparison

| Tool | Best For | Overhead | Works in Prod? |
|---|---|---|---|
| JFR allocation profiling | Allocation hotspots | ~1% | Yes |
| jmap / GC.heap_dump | Memory leak, heap structure | Brief STW pause | Carefully |
| Eclipse MAT | Heap dump analysis | Offline | N/A |
| VisualVM Sampler | Quick allocation overview | ~3% | Not recommended |
| async-profiler (alloc) | Precise allocation trace | ~2% | Short duration |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Allocation profiling (JFR) finds what creates the most objects.
> Heap dump (jmap + MAT) diagnoses memory leaks. Key MAT reports:
> Leak Suspects, Dominator Tree. Compare two heap dumps over time
> to find accumulating objects.

---

**Senior / Staff (5+ years):**

> I treat heap dumps as the last resort - taking a heap dump pauses
> GC and produces a large file. I use JFR allocation profiling first
> to find hotspots. For leak diagnosis, I take two timed dumps
> separated by 10+ minutes of load and use MAT's compare function.
> The dominator tree almost always points directly to the leak root.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "A service's heap grows steadily over 24 hours then OOMs.
  How do you diagnose the memory leak?"

🗣️ "Step 1: Enable GC logging to confirm the pattern.
`-Xlog:gc*:file=/var/log/gc.log` should show old generation
growing and never shrinking after major GC. That confirms a leak
(live objects that should be unreachable are being retained).
Step 2: If using JFR continuous recording, dump and look at the
allocation profile - it may point directly to the accumulating
type. Step 3: Take two heap dumps 20 minutes apart under production
load: `jcmd <pid> GC.heap_dump /tmp/heap1.hprof`, then later
`/tmp/heap2.hprof`. Step 4: Open both in Eclipse MAT.
'File → Compare Snapshots'. Sort by size difference. The classes
growing most rapidly are the leak candidates. Step 5: For each
candidate, use 'Show Dominator Tree' to find what is holding a
reference. Common culprits: static collections not bounded, thread
locals not cleared, event listeners not unregistered, session maps
holding large objects."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Heap dump workflow, MAT dominator tree. |
| Hiring Manager   | Leak diagnosis process, production safety of heap dump. |
| Bar Raiser       | Shallow vs retained heap, OQL, class histogram analysis. |
| Peer Engineer    | "MAT dominator tree showed our Hibernate session cache grew unboundedly..." |

---

---

# Latency vs Throughput

**Interview Weight:** medium - Foundational trade-off.
Understanding the inverse relationship is required for any
performance architecture discussion.

---

### 🎯 Model Answer

**30 seconds:**

> Latency and throughput are related but distinct: latency is how
> long one operation takes; throughput is how many operations
> complete per second. They are often in tension: batching
> increases throughput but increases individual latency. Concurrency
> increases throughput but contention increases latency. Little's
> Law: Throughput = Concurrency / Latency. To improve throughput
> at fixed latency, add concurrency. To reduce latency at fixed
> throughput, reduce per-request work.

**3 minutes (Senior):**

> **Little's Law (the most important performance formula):**
> L = λ * W
> - L = number of requests in the system (queue + processing)
> - λ = arrival rate (throughput, requests per second)
> - W = average time in system (latency, seconds)
>
> Consequence: at 1,000 RPS with 100ms average latency, there are
> always 100 concurrent requests in flight (L = 1000 * 0.1 = 100).
> Thread pool sizing: need at least 100 threads (or virtual threads).
>
> **The latency-throughput trade-off:**
> - Optimizing for throughput (batch, buffer, async): individual
>   operations wait longer (higher latency) but more total work done.
> - Optimizing for latency (process immediately, no batching):
>   less efficient use of resources (lower throughput).
>
> **p99 vs average latency:**
> Average latency hides tail behavior. A service with:
> - p50 = 5ms, p99 = 500ms, p999 = 5000ms
> - Average = ~10ms (looks fine)
> - 1% of users (100 per 10k requests) wait 500ms
> - 0.1% wait 5 seconds
>
> SLAs should be defined on percentiles, not averages.
> - "p99 < 100ms" = 99% of requests complete in under 100ms.
> - Use HDR Histogram for accurate percentile tracking.

---

### 💻 Code Example

**Example 1: Little's Law thread pool sizing**

```java
// LITTLE'S LAW APPLICATION: Thread pool sizing

// Given:
// Target throughput: 500 RPS
// Expected p50 latency per request: 200ms (mostly DB I/O)
// L = λ * W = 500 * 0.2 = 100 concurrent requests needed

// BAD: default thread pool (too small for this workload)
ExecutorService pool = Executors.newFixedThreadPool(10);
// 10 threads * 200ms per request = 50 RPS max throughput
// → at 500 RPS arrival, queue grows unboundedly → OOM or timeouts

// GOOD: size based on Little's Law
// With platform threads (1:1 OS threads): capped at ~500 (OS limit)
// Adding headroom: use 150 threads for 500 RPS at 200ms latency
ExecutorService pool = Executors.newFixedThreadPool(150);
// 150 threads * 200ms = 75 RPS capacity with no queueing
// Wait - we need 100 concurrent. 150 handles overhead and bursts.

// BEST (Java 21+): virtual threads
// Virtual threads don't block OS threads during I/O
// Little's Law still applies but virtual threads are cheap:
ExecutorService pool = Executors.newVirtualThreadPerTaskExecutor();
// 10,000 virtual threads at 200ms I/O each:
// throughput = 10,000 / 0.2 = 50,000 RPS (limited by DB, not threads)

// Measuring p99 latency with Micrometer + JVM monitoring
Timer timer = Timer.builder("request.latency")
    .publishPercentiles(0.5, 0.95, 0.99, 0.999)
    .publishPercentileHistogram()  // HDR histogram backend
    .register(registry);

timer.record(() -> {
    processRequest(req);
});
// Exposes: request.latency.p50, p99, p999 to Prometheus/Grafana
```

> **Code walkthrough:** Little's Law directly sizes the thread pool.
> 500 RPS at 200ms = 100 concurrent in-flight requests minimum.
> The GOOD example uses 150 threads for headroom. With virtual
> threads (Java 21), the thread count limit goes away - the
> bottleneck shifts to the database. The `Micrometer` timer with
> `publishPercentiles` provides production p99 visibility, which
> is what SLAs should be measured against.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Latency = how long one request takes. Throughput = requests
> per second. Little's Law: Throughput = Concurrency / Latency.
> Use p99, not average, for latency SLAs.

---

**Senior / Staff (5+ years):**

> I use Little's Law for every thread pool sizing decision.
> I also use it to detect overload: if throughput drops but
> latency and concurrency rise, the system is queuing (L is
> growing). I instrument p99 latency in Prometheus and set SLAs
> on percentiles, never averages.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "Your database can handle 1,000 queries/second with 50ms
  average latency. How many threads do you need to saturate it?"

🗣️ "Apply Little's Law: L = λ * W. Target throughput λ = 1,000
QPS. Average latency W = 50ms = 0.05 seconds. L = 1,000 * 0.05
= 50 concurrent requests in flight. So I need 50 threads (platform
threads) to fully saturate the database. With fewer than 50 threads,
threads are always waiting for a response and new DB queries cannot
start - the database would be idle some of the time. With 50 threads,
each is waiting for a DB response, but as soon as one completes,
a new query starts immediately. I would actually provision 60-70
threads for safety margin to handle burst traffic and variance in
response times. With Java 21 virtual threads, this changes: I can
use thousands of virtual threads at near-zero cost and let the
database's own connection limit become the bottleneck."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Little's Law calculation, thread pool sizing. |
| Hiring Manager   | SLO/SLA on percentiles, not averages. |
| Bar Raiser       | Queueing theory, USL (Universal Scalability Law), Amdahl's Law. |
| Peer Engineer    | "We used Little's Law to prove we needed 80 threads, not 20..." |

---

---

# Performance Anti-patterns Overview

**Interview Weight:** medium - Foundational awareness.
Tests whether the candidate recognizes common mistakes before
profiling.

---

### 🎯 Model Answer

**30 seconds:**

> The top Java performance anti-patterns: N+1 queries (one DB call
> per list item instead of one bulk call), premature optimization
> (fixing the wrong thing), excessive synchronization (locking
> more than necessary), object creation in hot paths (GC pressure),
> and String concatenation with `+` in loops. Most anti-patterns
> cause either excessive CPU use or excessive GC pressure.

**3 minutes (Senior):**

> **The seven deadly performance anti-patterns:**
>
> 1. **N+1 Query**: fetch a list of N items, then query for details
>    per item = N+1 total queries. Fix: JOIN or batch fetch.
>
> 2. **String `+` in loop**: each `+` creates a new String object.
>    1,000 iterations = 1,000 allocations. Fix: StringBuilder.
>
> 3. **Log string building when logging disabled**: `log.debug("x=" + x)`
>    builds the String even if DEBUG is off. Fix: parameterized
>    logging `log.debug("x={}", x)`.
>
> 4. **Unbounded cache**: `Map` or collection that grows forever.
>    Fix: bounded cache (Caffeine) with eviction policy.
>
> 5. **Synchronized everything**: coarse-grained `synchronized`
>    on a high-traffic method serializes all requests. Fix:
>    `ConcurrentHashMap`, `ReadWriteLock`, or immutable design.
>
> 6. **Premature optimization**: optimizing based on assumption
>    rather than profiler output. Fix: profile first, optimize
>    the measured hotspot.
>
> 7. **BigDecimal in hot paths**: 10-100x slower than primitive
>    arithmetic. Fix: use `long` for monetary values (in pence/cents),
>    convert to BigDecimal only for display.

---

### 💻 Code Example

**Example 1: Seven anti-patterns and fixes**

```java
// ANTI-PATTERN 1: N+1 Query
// BAD:
List<Order> orders = orderDao.findAll();   // 1 query
for (Order o : orders) {
    User user = userDao.findById(o.userId()); // N queries
    process(o, user);
}
// GOOD: JOIN in one query
List<OrderWithUser> results = orderDao.findAllWithUsers();

// ANTI-PATTERN 2: String + in loop
// BAD:
String result = "";
for (String item : items) { result = result + item + ","; }
// GOOD:
StringBuilder sb = new StringBuilder();
for (String item : items) { sb.append(item).append(','); }
String result = sb.toString();

// ANTI-PATTERN 3: Log building when disabled
// BAD (covered in CPU Profiling):
log.debug("Processing order: " + order.toJson());
// GOOD: lazy, no-op when DEBUG disabled
log.debug("Processing order: {}", order.id());
// Note: toJson() still called if using object directly;
//       use Supplier form if toJson() is expensive:
if (log.isDebugEnabled()) {
    log.debug("Processing order: {}", order.toJson());
}

// ANTI-PATTERN 4: Unbounded cache (see Memory Profiling section)
// Fix: Caffeine with maximumSize + expireAfterWrite

// ANTI-PATTERN 5: Coarse synchronized
// BAD:
public synchronized UserProfile getProfile(Long userId) { ... }
// Every thread serializes here even for different user IDs
// GOOD: striped locking or ConcurrentHashMap
ConcurrentHashMap<Long, UserProfile> cache = new ConcurrentHashMap<>();
cache.computeIfAbsent(userId, id -> loadProfile(id));
// Only blocks threads accessing the SAME user ID

// ANTI-PATTERN 6: Premature optimization (conceptual)
// BAD: spending 3 days optimizing a method that runs 10x/day
// GOOD: profile first - identify the method called 10M times/day

// ANTI-PATTERN 7: BigDecimal in hot path
// BAD:
BigDecimal total = BigDecimal.ZERO;
for (Order o : orders) {
    total = total.add(o.price());  // Object allocation + slow arithmetic
}
// GOOD: long arithmetic (pence internally)
long totalCents = 0;
for (Order o : orders) { totalCents += o.priceInCents(); }
BigDecimal total = new BigDecimal(totalCents).movePointLeft(2);
```

> **Code walkthrough:** Each anti-pattern has a predictable fix.
> N+1 → JOIN query. String loop → StringBuilder. Log building →
> parameterized. Cache → bounded. Coarse sync → striped or
> concurrent. Premature optimization → profile first.
> BigDecimal → long arithmetic. Recognizing these patterns by
> code review - before profiling - saves debugging time.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Top anti-patterns: N+1 queries, String + in loop, logging
> when disabled, unbounded cache, coarse synchronization.
> Fix by recognizing the pattern, not by profiling every line.

---

**Senior / Staff (5+ years):**

> I use code review to catch anti-patterns before they reach
> production. N+1 and unbounded cache are the most expensive
> in production: they scale with data size, so they seem fine
> in testing and catastrophic in production.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "During code review, what performance anti-patterns do you
  look for?"

🗣️ "I scan for six things in code review: First, loops that call
a DAO or service inside - potential N+1 queries. I check whether
the called method is batched at the call site or fetches individually.
Second, String concatenation with `+` inside loops - it creates
a new String on every iteration. Third, debug log statements
that build message Strings unconditionally - parameterized logging
fixes this. Fourth, `new` inside tight loops for objects that
could be reused - StringBuilder, DateFormatter, compiled Regexes.
Fifth, synchronized on methods or objects that could be avoided
with ConcurrentHashMap or ReadWriteLock. Sixth, static Maps
without size bounds - a signal for potential unbounded cache growth.
I don't block PRs on speculation - I flag these as performance
concerns and suggest profiling under load to confirm impact before
deciding to fix."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Specific anti-patterns with code examples. |
| Hiring Manager   | Code review practice, balancing optimization vs delivery. |
| Bar Raiser       | Amdahl's limitation on gains, cache invalidation overhead. |
| Peer Engineer    | "We had all 7 anti-patterns in one service - fixed 3 in a sprint, 10x throughput..." |
