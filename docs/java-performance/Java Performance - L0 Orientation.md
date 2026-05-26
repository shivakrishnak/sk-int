---
layout: default
title: "Java Performance - L0 Orientation"
parent: "Java Performance"
nav_order: 1
permalink: /java-performance/l0-orientation/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Performance Overview](#java-performance-overview) | medium |
| 2 | [Performance Measurement Fundamentals](#performance-measurement-fundamentals) | medium |
| 3 | [JVM Performance Model](#jvm-performance-model) | medium |

---

# Java Performance Overview

**Interview Weight:** medium - Foundational orientation.
Sets the context for all subsequent performance discussions.

---

### 🎯 Model Answer

**30 seconds:**

> Java performance engineering addresses three primary concerns:
> latency (how long a single operation takes), throughput (how
> many operations per second), and resource utilization (CPU,
> memory, I/O). The JVM adds unique dimensions: GC pauses, JIT
> warmup, and object allocation pressure. Java performance is
> substantially different from C/C++ performance because you
> cannot control memory management directly.

**3 minutes (Senior):**

> **The performance engineering lifecycle:**
>
> 1. **Baseline**: measure current behavior under realistic load.
>    Without a baseline, you cannot tell if changes help or hurt.
>
> 2. **Profile**: find the bottleneck. 90% of performance problems
>    are in 10% of the code (Amdahl's Law). Profile before optimizing.
>    Common mistake: optimize the wrong path and get negligible gains.
>
> 3. **Optimize**: make one change at a time. Multiple simultaneous
>    changes prevent attribution of improvement or regression.
>
> 4. **Validate**: measure again under the same load conditions.
>    Compare against baseline with statistical significance.
>
> 5. **Monitor**: performance degrades in production as data grows,
>    traffic patterns change, and dependencies change. Continuous
>    monitoring is not optional.
>
> **Java performance layers:**
> - **Application layer**: algorithm choices, data structures,
>   caching strategies, unnecessary computation.
> - **JVM layer**: GC behavior, JIT compilation, object allocation,
>   heap sizing.
> - **Platform layer**: OS scheduling, network I/O, disk I/O,
>   CPU cache effects.
>
> **Common misconceptions about Java performance:**
> - "Java is slow" - modern HotSpot JIT-compiled Java code is
>   within 10-30% of equivalent C++ for CPU-bound work. I/O-bound
>   performance is equivalent.
> - "More heap = better" - oversized heaps cause longer Full GC
>   pauses. Right-sizing is critical.
> - "Optimize early" - premature optimization wastes time. Profile
>   first.

---

### 💻 Code Example

**Example 1: Performance problem categories**

```java
// CATEGORY 1: Algorithm choice (most impactful)
// BAD: O(n^2) - fine for n=100, catastrophic for n=100,000
List<Order> findDuplicates(List<Order> orders) {
    List<Order> duplicates = new ArrayList<>();
    for (Order o1 : orders) {
        for (Order o2 : orders) {    // O(n^2)
            if (!o1.equals(o2) && o1.id().equals(o2.id())) {
                duplicates.add(o1);
            }
        }
    }
    return duplicates;
}
// GOOD: O(n) with HashSet
List<Order> findDuplicates(List<Order> orders) {
    Set<String> seen = new HashSet<>();
    return orders.stream()
        .filter(o -> !seen.add(o.id()))  // add returns false if already in set
        .collect(toList());
}

// CATEGORY 2: Unnecessary object creation (GC pressure)
// BAD: 1M String objects created per minute
void logRequest(Request req) {
    log.info("Request: " + req.method() + " " + req.path() + " from " + req.ip());
    // → 3 intermediate String objects per call even when log.INFO is disabled
}
// GOOD: lazy evaluation
void logRequest(Request req) {
    log.info("Request: {} {} from {}",
             req.method(), req.path(), req.ip());
    // → args only evaluated if log level is INFO (SLF4J parameterized logging)
}

// CATEGORY 3: Blocking I/O in critical path
// BAD: synchronous external call in request handler
Order processOrder(OrderRequest req) {
    User user = userService.getUser(req.userId());    // 20ms DB call
    Inventory inv = inventoryService.check(req);      // 30ms RPC call
    // Sequential: 50ms total I/O per request
    return createOrder(user, inv, req);
}
// GOOD: parallel I/O
Order processOrder(OrderRequest req) {
    CompletableFuture<User> userFuture =
        CompletableFuture.supplyAsync(() -> userService.getUser(req.userId()));
    CompletableFuture<Inventory> invFuture =
        CompletableFuture.supplyAsync(() -> inventoryService.check(req));
    User user = userFuture.join();
    Inventory inv = invFuture.join();
    // Parallel: 30ms total (max of the two I/O calls)
    return createOrder(user, inv, req);
}
```

> **Code walkthrough:** The three performance categories have very
> different payoffs. Algorithm choice (O(n) vs O(n^2)) provides
> 100x-10000x improvement for large inputs. Object creation reduction
> lowers GC pressure measurably. Parallel I/O reduces latency
> by removing sequential blocking. Profile first to know which
> category your bottleneck falls into.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Java performance covers latency, throughput, and resource use.
> The JVM adds GC and JIT dimensions. Profile before optimizing
> - don't guess the bottleneck.

---

**Senior / Staff (5+ years):**

> I treat performance as a lifecycle: baseline, profile, change
> one thing, validate. Most Java performance problems are algorithm
> choices, unnecessary allocations, or blocking I/O - in that
> order of frequency. GC tuning is rarely the first fix; fix the
> code before tuning the JVM.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "What are the most common performance anti-patterns in Java
  applications you have seen?"

🗣️ "The top three I encounter: (1) N+1 queries - one query to
fetch a list, then one query per item to fetch details. Produces
1,001 DB round trips instead of 2. Fix: eager load with JOIN.
(2) Synchronous calls in series when independence allows parallel
execution. A handler that calls 3 independent microservices
serially takes 150ms where parallel would take 50ms.
(3) Unnecessary object creation in hot paths - building log messages
when logging is disabled, creating substrings in parse loops,
using `+` concatenation inside loops instead of StringBuilder.
For a service doing 10k RPS, these create millions of short-lived
objects per minute, elevating GC CPU usage. The first fix is
almost always the algorithm. The second is almost always the I/O
pattern. GC tuning comes last."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Performance lifecycle, bottleneck categories. |
| Hiring Manager   | Practical experience with real performance issues. |
| Bar Raiser       | Amdahl's Law, Little's Law, measurement validity. |
| Peer Engineer    | "Our worst bottleneck was a nested loop we'd 'always had'..." |

---

---

# Performance Measurement Fundamentals

**Interview Weight:** medium - Critical foundation. Measuring
incorrectly produces false conclusions. Tests whether the candidate
knows why naive benchmarks are wrong.

---

### 🎯 Model Answer

**30 seconds:**

> Correct performance measurement requires: a warm JVM (JIT
> compiled), statistical significance (multiple runs, confidence
> intervals), realistic load (production-representative data and
> concurrency), and isolation (no competing processes). The primary
> measurement mistake: benchmarking cold code where JIT hasn't
> compiled it yet, getting 5x slower results than production.
> Use JMH for microbenchmarks - it handles warmup, JIT, and
> dead code elimination automatically.

**3 minutes (Senior):**

> **JVM-specific measurement pitfalls:**
>
> 1. **JIT warmup**: C2 compiles after ~10,000 invocations. A
>    benchmark that runs code 100 times measures the interpreter,
>    not the JIT. JMH default: 5 warmup iterations of 1 second each.
>
> 2. **Dead code elimination**: the JIT will eliminate code whose
>    result is never used. A benchmark that computes a value but
>    doesn't use it may be measuring nothing. JMH's `Blackhole.consume()`
>    prevents this.
>
> 3. **Constant folding**: if all inputs to a benchmark are constants,
>    the JIT may precompute the result. Use `@State` and `@Param`
>    to make inputs visible to the JIT.
>
> 4. **GC interference**: a GC pause during measurement skews the
>    result. JMH runs multiple iterations and reports mean/stddev.
>    Outliers from GC appear as high standard deviation.
>
> 5. **Coordinated omission**: in latency measurements, if the
>    system is backlogged and you only measure service time (not
>    wait time), you undercount latency. HDR Histogram records
>    true end-to-end latency including queue wait time.
>
> **Measurement metrics:**
> - **Throughput**: operations per second (OPS). Use when maximizing
>   work per unit time.
> - **Average latency**: misleading. One 1000ms outlier skews the average.
> - **Percentiles (p50, p95, p99, p999)**: p99 tells you what the
>   "slow" user experiences. p999 reveals catastrophic outliers.
> - **Standard deviation**: measures stability. High stddev = JIT
>   or GC interference.

---

### 💻 Code Example

**Example 1: JMH microbenchmark with common pitfalls fixed**

```java
// BAD: hand-rolled benchmark (all pitfalls present)
void measureStringConcatenation() {
    long start = System.currentTimeMillis();
    String result = "";
    for (int i = 0; i < 1000; i++) {
        result = result + "item" + i;   // never used → JIT may eliminate
    }
    // No warmup: running in interpreter
    // No statistical validity: single measurement
    // GC might run mid-measurement
    System.out.println("Time: " + (System.currentTimeMillis() - start) + "ms");
}

// GOOD: JMH benchmark (handles all pitfalls)
@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.MICROSECONDS)
@State(Scope.Thread)
@Warmup(iterations = 5, time = 1)  // 5 seconds warmup per fork
@Measurement(iterations = 10, time = 1)  // 10 measurement iterations
@Fork(3)  // 3 independent JVM forks for statistical independence
public class StringBenchmark {

    @Param({"10", "100", "1000"})  // parameterized inputs, not constants
    private int size;              // JIT cannot constant-fold this

    @Benchmark
    public String concatenationPlus(Blackhole bh) {
        String result = "";
        for (int i = 0; i < size; i++) {
            result = result + "item" + i;
        }
        return result;  // return value consumed by JMH → prevents elimination
    }

    @Benchmark
    public String concatenationBuilder(Blackhole bh) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < size; i++) {
            sb.append("item").append(i);
        }
        return sb.toString();
    }
}

// Run: java -jar benchmarks.jar StringBenchmark -rf json -rff results.json
// Output example:
// Benchmark                            (size)  Mode  Cnt   Score   Error  Units
// StringBenchmark.concatenationPlus      1000  avgt   30  4832.5 ± 23.4  us/op
// StringBenchmark.concatenationBuilder   1000  avgt   30    12.3 ±  0.2  us/op
// → StringBuilder is 400x faster at size=1000 (O(n^2) vs O(n) behavior)
```

> **Code walkthrough:** JMH's annotations handle the hard parts:
> `@Warmup` ensures JIT compilation before measurement. `@Fork(3)`
> creates 3 independent JVMs, giving statistically independent
> samples. `@Param` makes inputs non-constant (prevents JIT
> constant-folding). Returning the result (or using `Blackhole`)
> prevents dead code elimination. The example reveals a 400x
> difference that a hand-rolled benchmark would miss due to warmup.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JMH is the standard for Java microbenchmarks. It handles JIT
> warmup, dead code elimination, and GC interference. Never
> benchmark with System.currentTimeMillis() - single measurements
> are meaningless for JVM code.

---

**Senior / Staff (5+ years):**

> I use JMH for microbenchmarks and load tests with realistic
> traffic patterns for macro benchmarks. Key things I watch:
> standard deviation (high = GC interference), p99 vs average
> gap (large gap = outliers from pauses), and warmup stability
> (still improving after 5 iterations = insufficient warmup).

---

### ❓ Questions You Will Be Asked

#### Debugging

- "Why might a Java microbenchmark show 10x better performance
  than you observe in production?"

🗣️ "Several common causes: (1) JIT warmup - if the production
service receives low traffic, methods may never reach C2 compilation
thresholds. The benchmark runs millions of times, fully JIT-compiled.
Production code runs 100 times per minute, still in the interpreter
or C1. (2) Input data - microbenchmarks use simplified inputs
that fit in CPU cache. Production handles diverse, large inputs
that cause cache misses. (3) Isolation - in production, competing
threads share CPU caches and memory bandwidth. The benchmark has
dedicated CPU cache. (4) GC pressure - in production, allocation
from all request handlers competes for heap. The benchmark allocates
at a fraction of the production rate. (5) Coordinated omission -
benchmarking service time only, ignoring queue wait. Under real
load, requests wait before even being processed."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | JMH annotations, dead code elimination, constant folding. |
| Hiring Manager   | Benchmark validity, JIT warmup importance. |
| Bar Raiser       | Coordinated omission (Gil Tene), HDR histogram, p99 vs average. |
| Peer Engineer    | "Our JMH showed 2us - production showed 200us. Cache misses." |

---

---

# JVM Performance Model

**Interview Weight:** medium - Conceptual foundation.
Tests understanding of how JVM choices affect performance.

---

### 🎯 Model Answer

**30 seconds:**

> The JVM performance model has three layers: the application
> (code, algorithms, I/O patterns), the JVM runtime (JIT, GC,
> object allocation), and the OS/hardware (CPU, memory, disk).
> The unique JVM factor: GC pauses cause stop-the-world latency
> spikes that do not exist in non-GC languages. JIT provides
> adaptive optimization that can exceed static compilation for
> long-running workloads.

**3 minutes (Senior):**

> **JVM performance model components:**
>
> **Execution engine:**
> - Interpreted: ~100ns per bytecode. Startup code path.
> - C1-compiled: ~5x faster than interpreter.
> - C2-compiled: ~10x faster. Most hot code paths.
> - Deoptimization: brief regression when JIT assumptions break.
>
> **Memory model:**
> - Stack allocation: O(1), zero GC cost. Local primitives and
>   objects that don't escape (via escape analysis).
> - Heap allocation: ~10ns per object in TLAB (fast path).
>   Slower if TLAB exhausted (need new TLAB from heap).
> - GC overhead: 5-20% of CPU time in typical Java applications.
>   Can spike to 80%+ in an unhealthy JVM (GC thrashing).
>
> **Threading model:**
> - One OS thread per Java thread (platform threads). Thread
>   switch cost: ~1-5 microseconds.
> - Virtual threads (Java 21+): many virtual threads per OS
>   thread. Thread switch cost: nanoseconds. Enables
>   100k+ concurrent tasks with low memory.
>
> **I/O model:**
> - Platform threads: blocking I/O wastes an OS thread per wait.
> - Virtual threads: blocking I/O unmounts the virtual thread;
>   OS thread available for other virtual threads.
> - NIO: non-blocking I/O with explicit polling.
>
> **Performance bottleneck indicators:**
> - CPU-bound: `top` shows Java process at ~100% CPU. Profiler
>   shows application code methods (not GC threads) using CPU.
> - GC-bound: `top` shows high CPU, `jstat -gcutil` shows GC
>   threads consuming >20% CPU. GC log shows frequent pauses.
> - I/O-bound: CPU ~20-40%, threads RUNNABLE at socket/file read.
>   Requests per second limited by I/O throughput.
> - Memory-bound: slow due to cache misses. Hard to distinguish
>   from CPU-bound without hardware counters (perf, async-profiler).

---

### 💻 Code Example

**Example 1: Identifying JVM bottleneck type**

```bash
# STEP 1: Overall JVM health
jstat -gcutil <pid> 2000 10
# S0   S1    E     O     M   CCS  YGC  YGCT  FGC  FGCT   GCT
# 0.0  72.1  47.3  12.4  97  89   123  1.23    0  0.00  1.23
# O=12% (healthy), GCT=1.23s (low) → not GC-bound

# STEP 2: CPU profiling - what is consuming CPU?
jcmd <pid> JFR.start duration=30s filename=/tmp/profile.jfr settings=profile
# Open in JMC → Code → Method Profiling → CPU Flame Graph
# If GC threads show at top → GC-bound
# If application threads at top → CPU-bound (find the method)

# STEP 3: Identify I/O-bound threads
jcmd <pid> Thread.print | grep -E "RUNNABLE|BLOCKED|WAITING" | sort | uniq -c
# Expected healthy: many WAITING (idle threads), few RUNNABLE (working threads)
# I/O-bound: many RUNNABLE at socket read/file read → threads waiting for I/O
# Saturated: many BLOCKED → lock contention

# STEP 4: Memory allocation rate
# JFR ObjectAllocationInNewTLAB events → aggregate by stack trace
# High allocation rate (>500 MB/s) → reduce allocation for GC relief

# EXAMPLE: Diagnosing "GC-bound" JVM
# jstat shows: YGC happening 50 times/minute, YGCT=25s (50% CPU in GC!)
# JFR allocation profiling shows: String + in loop (top allocator)
# Fix: StringBuilder in loop, parameterized logging
# Result: YGC drops to 5 times/minute, GC CPU drops from 50% to 5%
```

> **Code walkthrough:** The three-tool sequence identifies the
> bottleneck type without guesswork. `jstat` gives the GC health
> overview in seconds. JFR flame graph reveals CPU consumers.
> Thread dump pattern matching identifies I/O wait vs lock
> contention. The fix for the GC-bound example (allocation
> reduction) is an application change, not a JVM flag change.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JVM performance has three layers: application, JVM runtime,
> OS/hardware. Key JVM factors: GC pauses and JIT compilation.
> Profile to find which layer is the bottleneck before changing
> anything.

---

**Senior / Staff (5+ years):**

> The most important JVM performance insight: GC pauses are a
> symptom of allocation rate, not a root cause. Fix allocation
> hotspots and GC behavior improves automatically. I use `jstat`
> for GC health, JFR for allocation source, and thread dump
> analysis for contention. These three cover 90% of JVM
> performance problems.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "How does Java's garbage collector affect application latency
  and what can you do about it?"

🗣️ "Garbage collection creates stop-the-world pauses where all
application threads freeze while GC runs. Young GC pauses are
typically 5-20ms. Full GC pauses can be 500ms-5 seconds for
large heaps with G1GC. This means even a healthy Java service
will have p99 latency elevated by GC pauses compared to a
non-GC language. What you can do: (1) Reduce allocation rate -
less garbage created means less frequent GC. Profile allocation
hotspots with JFR and fix top allocators. (2) Use low-pause GC -
ZGC and Shenandoah keep pauses under 10ms regardless of heap
size by doing most GC work concurrently. (3) Right-size the heap -
too small = frequent GC; too large = infrequent but longer GC.
The right size gives 2-3x the live data set. (4) Use GraalVM
Native Image for services where GC pauses are unacceptable -
no GC means no pauses, at the cost of lower peak throughput."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Three bottleneck types, GC impact on latency. |
| Hiring Manager   | Practical diagnosis workflow. |
| Bar Raiser       | Hardware performance counters, cache miss impact, NUMA effects. |
| Peer Engineer    | "Switched to ZGC and our p999 dropped from 2s to 50ms..." |
