---
layout: default
title: "Java Performance - L2 Profiling"
parent: "Java Performance"
grand_parent: "SK Interview"
nav_order: 6
permalink: /java-performance/l2-profiling/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Performance - L2 Profiling](#java-performance---l2-profiling) | medium |

---

# Java Performance - L2 Profiling

## JMH Basics: Benchmark Design and Pitfalls

---

### 🎯 Model Answer

**30 seconds:**
> JMH (Java Microbenchmark Harness): the correct tool for micro-benchmarking Java code.
> Handles JVM warmup, dead code elimination, constant folding, and benchmark bias.
> Core annotations: `@Benchmark`, `@State`, `@Warmup`, `@Measurement`, `@Fork`, `@BenchmarkMode`.
> Rule: never benchmark with `System.nanoTime()` in a loop - it gives wrong results.

**3 minutes (Senior):**
> JMH critical design elements:
>
> 1. **`@Fork(N)`**: runs the benchmark in N separate JVM processes. Essential for isolation:
>    without forks, JIT state from benchmark A affects benchmark B's results. Each fork:
>    fresh JVM, no shared JIT state.
>
> 2. **`@Warmup(iterations=N)`**: before measurement, runs N warmup iterations (not recorded).
>    Purpose: allow JIT to reach C2 steady state. Without warmup: measuring interpreted code.
>    Minimum: 3-5 iterations, often 10 for stable results.
>
> 3. **`@Measurement(iterations=N, time=Ts)`**: records N measurement iterations, each T seconds.
>    More iterations: lower variance in the reported result.
>
> 4. **`Blackhole`**: prevents dead code elimination. JIT can eliminate computations whose result
>    is never used. `Blackhole.consume(result)` fakes usage, preventing elimination.
>
> 5. **`@State(Scope.Benchmark)` vs `@State(Scope.Thread)`**: Benchmark scope = one state instance
>    shared by all benchmark threads. Thread scope = one per thread. For concurrent benchmarks:
>    Thread scope avoids false sharing on the state object. For contention tests: Benchmark scope.
>
> 6. **`@BenchmarkMode(Mode.AverageTime)`**: the mode. AverageTime (ns/op), Throughput (ops/s),
>    SampleTime (distribution), SingleShotTime (single iteration, warmup effect visible).

**Blank Mind Recovery:**

**(1) Restate:** "@Benchmark: measured method. @State: benchmark state. @Warmup: JIT warmup iterations. @Measurement: recorded iterations. @Fork: JVM isolation. Blackhole: prevent dead code elimination. Never use System.nanoTime() in a loop."

**(2) First principles:** "JVM benchmarking is hard because: JIT changes behavior over iterations, dead code elimination removes work, constant folding precomputes results. JMH systematically addresses each of these. A naive loop doesn't."

**(3) Bridge:** "JMH is to Java benchmarking what a controlled experiment is to science. System.nanoTime() in a loop is like measuring with a bent ruler in an uncontrolled environment - the measurements are unreliable. JMH: controls the environment (JVM warmup, JIT isolation) and provides statistical analysis."

---

### 📘 Concept Explanation

**JMH design principles and common pitfalls:**
```
JMH BENCHMARK PITFALLS:

  PITFALL 1: No JVM Warmup
    Naive benchmark:
      long start = System.nanoTime();
      for (int i = 0; i < 10000; i++) { method(); }
      long time = (System.nanoTime() - start) / 10000;
    
    Problem: first 1,000-2,000 invocations: interpreted (slow).
    Next 2,000-10,000: C1 compiled (medium).
    After 10,000: C2 compiled (fast, steady state).
    Average of all 10,000 includes slow interpreted iterations.
    Result: overestimates the real steady-state time by 2-10x.
    
    JMH solution: @Warmup(iterations=5) runs 5 warm-up iterations
    (not counted), ensuring C2 is active before measurement starts.
  
  PITFALL 2: Dead Code Elimination (DCE)
    JVM C2 is very smart. If a method's result is never used:
    C2 proves it has no side effects and eliminates the call entirely.
    
    Naive benchmark:
      for (int i = 0; i < N; i++) {
          String s = new StringBuilder().append("hello").toString();
          // s is created but never used after the loop
          // C2 eliminates the entire StringBuilder/String creation
          // The benchmark measures nothing (0 ns/op)
      }
    
    JMH solution: return the result from @Benchmark method
    (JMH consumes it via Blackhole), or explicitly pass to Blackhole:
      @Benchmark
      public String benchmark() {
          return new StringBuilder().append("hello").toString();
          // JMH framework consumes the return value
      }
  
  PITFALL 3: Constant Folding
    If benchmark inputs are constants:
      @Benchmark
      public int add() { return 1 + 2; }  // C2 folds to: return 3;
    C2 computes the result at JIT time, benchmark measures:
    "how fast is a single return-constant instruction" (0-1 ns/op).
    Not the cost of addition.
    
    JMH solution: use @State-held inputs:
      @State(Scope.Benchmark)
      public static class State {
          int x = 1, y = 2;  // not final, not constant
      }
      @Benchmark
      public int add(State s) { return s.x + s.y; }
    
  PITFALL 4: JIT Contamination Between Benchmarks
    Without @Fork: benchmarks run in the same JVM.
    benchmarkA() may cause JIT to inline method M.
    benchmarkB() (which also calls M) benefits from A's JIT work.
    benchmarkB appears faster due to contamination from benchmarkA.
    
    JMH solution: @Fork(2) runs each benchmark in a fresh JVM process.
    2 forks: reduces inter-benchmark contamination risk.
  
  PITFALL 5: Coordinated Omission
    In throughput benchmarks: if the benchmark thread blocks, it
    doesn't record the slow request; it just waits to start the next.
    The slow request is "omitted" from the distribution.
    
    JMH: @BenchmarkMode(Mode.SampleTime) with per-operation sampling
    catches latency outliers. For load testing: k6/Gatling handle
    this correctly (they time from request START, not from previous
    response end).

JMH SETUP AND STRUCTURE:

  Maven dependency:
    <dependency>
      <groupId>org.openjdk.jmh</groupId>
      <artifactId>jmh-core</artifactId>
      <version>1.37</version>
    </dependency>
    <dependency>
      <groupId>org.openjdk.jmh</groupId>
      <artifactId>jmh-generator-annprocess</artifactId>
      <version>1.37</version>
      <scope>provided</scope>
    </dependency>
  
  Maven shade plugin: build fat JAR, run with:
    java -jar target/benchmarks.jar
    java -jar target/benchmarks.jar "MyBenchmark.method" -f 2 -wi 5 -i 10

INTERPRETING JMH OUTPUT:

  Benchmark                          Mode  Cnt    Score    Error  Units
  MyBenchmark.serialize           avgt   20  1234.5 ± 12.3  ns/op
  MyBenchmark.serializeOptimized  avgt   20   456.7 ±  5.6  ns/op
  
  Score: the measured metric (average time here = 1234.5 ns per operation)
  Error: 99.9% confidence interval (±12.3 ns)
  Cnt: number of measurement samples
  
  "Optimized" is 1234/457 = 2.7x faster. The ± errors don't overlap:
  result is statistically significant (reliable difference).
```

> **Code walkthrough:** This L2 Profiling example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

---

### 💻 Code Example

> **Code walkthrough:** The complete JMH benchmark shows the full structure: State class holds
> non-constant inputs, Blackhole prevents DCE, Fork provides JVM isolation, Warmup lets JIT
> reach steady state. The bad vs good patterns in the benchmark show how each pitfall changes
> the result.


```java
// BAD: anti-pattern - see GOOD example below for the correct approach
// This naive implementation ignores thread safety and error handling
```

```java
// COMPLETE JMH BENCHMARK EXAMPLE:

@BenchmarkMode(Mode.AverageTime)
@OutputTimeUnit(TimeUnit.NANOSECONDS)
@State(Scope.Benchmark)
@Warmup(iterations = 5, time = 1, timeUnit = TimeUnit.SECONDS)
@Measurement(iterations = 10, time = 1, timeUnit = TimeUnit.SECONDS)
@Fork(value = 2, jvmArgsAppend = "-XX:+UseG1GC")
public class JsonSerializationBenchmark {
    
    // State: inputs must be non-constant to avoid constant folding
    private ObjectMapper mapper;
    private Order order;
    private byte[] preallocatedBuffer;
    
    @Setup(Level.Trial)
    public void setup() {
        mapper = new ObjectMapper();
        order = new Order(1L, "CUST-001", new BigDecimal("99.99"), "PENDING");
        preallocatedBuffer = new byte[4096];
    }
    
    // PITFALL EXAMPLE: missing Blackhole (result unused -> DCE):
    // @Benchmark
    // public void badBenchmark() {
    //     String json = mapper.writeValueAsString(order);
    //     // json assigned but never used -> C2 may eliminate the call!
    // }
    
    // CORRECT: return result (JMH auto-consumes via Blackhole):
    @Benchmark
    public byte[] serializeToBytes() throws Exception {
        return mapper.writeValueAsBytes(order);
    }
    
    // CORRECT: explicit Blackhole for void methods:
    @Benchmark
    public void serializeToStream(Blackhole bh) throws Exception {
        ByteArrayOutputStream baos = new ByteArrayOutputStream(256);
        mapper.writeValue(baos, order);
        bh.consume(baos.toByteArray());
    }
    
    // COMPARISON: alternative serialization
    @Benchmark
    public byte[] serializeRecord() throws Exception {
        OrderRecord rec = new OrderRecord(
            order.getId(), order.getCustomerId(),
            order.getTotal(), order.getStatus());
        return mapper.writeValueAsBytes(rec);
    }
}

// Run with comparison:
// java -jar benchmarks.jar JsonSerializationBenchmark -rf json -rff results.json
// Open results.json in https://jmh.morethan.io for visualization

// COMMON JMH ANTI-PATTERNS:

// BAD: @Benchmark method that always returns void and has no Blackhole:
@Benchmark
public void antiPattern_noBlackhole() {
    // These computations' results are unused -> C2 eliminates them:
    String result = computeExpensiveString();
    int hash = result.hashCode();
    // hash is computed but never returned or consumed
    // C2 may eliminate the entire body
}

// GOOD: consume results:
@Benchmark
public int goodPattern(Blackhole bh) {
    String result = computeExpensiveString();
    bh.consume(result);          // prevent DCE of result
    return result.hashCode();    // AND return something (double protection)
}
```

> **Code walkthrough:** The `@Setup(Level.Trial)` annotation runs `setup()` once per fork (JVM process),
> ensuring `ObjectMapper` is fully initialized before any warmup or measurement. `Level.Iteration`
> would run setup before each iteration (use for resetting state). `Level.Invocation` runs before
> each individual benchmark call (high overhead, use only when necessary). The `serializeToBytes`
> returning the result is the simplest correct form: JMH's harness stores the return value in a
> Blackhole, preventing DCE.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> JMH: use for accurate micro-benchmarks. Annotations: `@Benchmark`, `@State`, `@Warmup(5)`,
> `@Measurement(10)`, `@Fork(2)`. Blackhole: return results from `@Benchmark` or use `bh.consume()`.
> Never benchmark with System.nanoTime() - JIT warmup and DCE make it unreliable.

---

**Senior / Staff (5+ years):**
> JMH answers: "What is the steady-state throughput/latency of this specific code path under
> JIT?" It doesn't answer: "How does this code perform in my application?" Application-level
> benchmarks (load tests) are different. JMH: isolate a code path for comparison (serialization
> library A vs B, algorithm A vs B). Use JMH to inform a decision, then validate with application-level
> load test. The two questions: "Is this code fast in isolation?" (JMH) vs "Is my application fast?"
> (load test + profiling).

---

### ⚠️ Common Misconceptions

**Misconception: "JMH results directly predict production performance."**
JMH measures a specific code path in isolation at JVM steady state with controlled inputs. Production:
many code paths compete for CPU/cache, different data, different concurrency, GC pressure from other
code. A JMH benchmark showing 100 ns/op for a serialization method doesn't mean serialization takes
100 ns in production. It means: in isolation, with warmed-up JIT, this specific input, 100 ns.
In production with cache pressure, GC, and concurrent threads: could be 200-500 ns/op. JMH:
guides optimization decisions. Production profiling: measures actual performance.

---

### 🚨 Failure Modes and Diagnosis

**Failure: JMH shows 0 ns/op or unrealistically low numbers.**
```
Symptom: JMH benchmark reports 0.001 ns/op or 0 ns/op.
  Everything seems fine (no errors) but results are nonsensical.

Root cause: Dead code elimination. C2 proved the benchmark body has no
  externally visible effects and removed it entirely.
  The benchmark is measuring the overhead of the empty loop itself.

Diagnosis:
  Check: does the @Benchmark method return a value or use Blackhole?
  
  Example of problematic benchmark:
    @Benchmark
    public void problemBenchmark() {
        String s = input.toUpperCase();  // result 's' never used
        // C2 may eliminate the toUpperCase() call entirely
    }
  
  Verification:
    Add -XX:+PrintCompilation to JVM args.
    Look for: "made not entrant" or "uncommon trap" for the method.
    Or add -prof perfnorm (Linux) to see instruction counts.
    Near-zero instruction count = DCE.

Fix:
  Option 1: Return the result:
    @Benchmark
    public String fixedBenchmark() {
        return input.toUpperCase();  // returned, JMH consumes it
    }
  
  Option 2: Blackhole.consume():
    @Benchmark
    public void fixedBenchmark(Blackhole bh) {
        String s = input.toUpperCase();
        bh.consume(s);  // fake usage, prevents DCE
    }
  
  Option 3: Check both:
    @Benchmark
    public String extraSafe(Blackhole bh) {
        String s = input.toUpperCase();
        bh.consume(s.length());  // consume derived value too
        return s;
    }
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Why not System.nanoTime() | 2 minutes |
| JVM warmup in benchmarks | 1 minute |
| Dead code elimination | 2 minutes |
| @Fork purpose | 1 minute |
| @State scope | 1 minute |
| Constant folding prevention | 1 minute |
| JMH vs load test | 1 minute |
| Interpreting results + error | 1 minute |
| Coordinated omission | 1 minute |

---

**Q1 (dce): Explain dead code elimination and how JMH prevents it.**

A: Dead code elimination (DCE): C2 detects that a computation's result is never used (externally
observable side effect) and removes it entirely. Example: `String s = a.toUpperCase()` in a method
that doesn't return or store `s`: C2 proves no one will read `s`, eliminates the call. In a benchmark:
if the method is called in a tight loop and the result is never used: C2 eliminates the method body,
and the benchmark measures zero (the cost of the empty loop). JMH prevention: (1) return the result
from `@Benchmark` (JMH's harness stores it, simulating usage). (2) `Blackhole.consume()` takes a
reference and uses it in a way C2 can't prove is a no-op.

*What separates good from great:* The "Blackhole consumption" mechanism: JMH's `Blackhole` uses JVM
intrinsics that C2 cannot optimize away. The Blackhole.consume() call: takes the reference, stores
it in a volatile field (force write), which C2 can't eliminate (volatile writes have visible side
effects). The benchmark body can then produce a result, pass it to Blackhole, and C2 cannot eliminate
the production of that result (it's "needed" by Blackhole). The subtlety: you must consume EVERY
result, not just some. If a benchmark computes A and B but only Blackhole.consume(A): C2 may still
eliminate B if B's computation has no other side effects. Consume everything derived from the hot path.

---

**Q2 (scope): When should you use @State(Scope.Thread) vs @State(Scope.Benchmark)?**

A: Benchmark scope: one state instance shared by all benchmark threads. Use when: testing
contention (multiple threads accessing the same state = realistic contention scenario).
Thread scope: one state instance per benchmark thread. Use when: each thread should operate
on independent data (no contention). For single-threaded benchmarks: no difference.
For multi-threaded benchmarks: Thread scope = no contention from state, Benchmark scope = adds
contention from state object. Wrong choice: Thread scope for a benchmark testing lock performance
(the lock is on the state object - Thread scope means no contention, not what you're testing).

*What separates good from great:* The `@Scope.Group` option: for asymmetric concurrent benchmarks
where different thread groups do different operations. Example: benchmarking a concurrent queue with
producers and consumers. `@Scope.Group` allows one group to call `enqueue` and another to call `dequeue`
on the SAME shared queue instance. Without Group scope: you can't model producer-consumer concurrency.
Setup: `@GroupThreads(4) @Group("queue") @Benchmark public void producer(State s)` +
`@GroupThreads(4) @Group("queue") @Benchmark public void consumer(State s)`. This simulates 4 producer
threads and 4 consumer threads hitting the same queue simultaneously - a realistic concurrency scenario.

---

**Q3 (constant folding): How does constant folding affect JMH benchmarks?**

A: Constant folding: C2 evaluates expressions involving constants at JIT compile time. If benchmark
inputs are constants (final fields, literal values): C2 precomputes the result. Example: `@Benchmark
public int benchmark() { return 2 * 3; }` - C2 folds to `return 6`. The benchmark measures "cost of
returning an int" (~1ns). Not the cost of multiplication. Prevention: state-held inputs (`@State` fields
that are not final). C2 doesn't constant-fold non-final field reads.

*What separates good from great:* The more subtle constant folding scenario: if you have `@State` with
a `final int x = 5`: C2 may still fold because it knows the field is `final`. Use `@State` with
non-final fields. OR: if the `@Setup` method assigns a value to the state that C2 can infer is always
the same value (because setup always assigns the same constant): C2 may still fold. Defense: use input
data from configuration files or random seeds (that C2 can't predict). JMH's `@Param` annotation:
runs the benchmark for multiple parameter values; this prevents constant folding because the JVM
doesn't know which value will be used until runtime.

---

---

## Async-Profiler and CPU Sampling: Advanced Techniques

---

### 🎯 Model Answer

**30 seconds:**
> Async-profiler: sampling-based JVM profiler using `AsyncGetCallTrace` API (no safepoint bias).
> Three modes: CPU (where CPU time goes), allocation (where objects are created), wall-clock
> (where LATENCY time goes, includes IO/lock wait). Output: HTML flame graph, JFR, folded stacks.
> Use CPU for compute bottlenecks, wall for latency bottlenecks, alloc for GC optimization.

**3 minutes (Senior):**
> Async-profiler modes and when to use each:
>
> **CPU mode (`-e cpu`)**: samples thread stacks only when the thread is running on CPU.
> Shows: where compute time is spent. Misses: IO wait, lock blocking, sleep. Use when:
> CPU utilization is high and you need to find the computational bottleneck.
>
> **Wall-clock mode (`-e wall`)**: samples ALL threads at every interval, including sleeping and
> blocked threads. Shows: where latency time is spent, including IO, locks, GC (from the app
> thread's perspective). Use when: p99 latency is high but CPU profile looks sparse (the time
> is spent waiting, not computing).
>
> **Allocation mode (`-e alloc`)**: instruments TLAB (Thread-Local Allocation Buffer) allocation
> events. Shows: which call stacks allocate the most objects. Essential for GC optimization.
> Use before any "reduce allocation" work.
>
> **Lock mode (`-e lock`)**: monitors Java monitor (synchronized) contention. Shows: which locks
> are most contended and which threads wait. Use when: thread dumps show BLOCKED threads.
>
> **JFR output mode**: writes JFR format instead of SVG/HTML. Can be analyzed in JDK Mission
> Control for more detailed event analysis. Combines CPU profiling with JFR events.

**Blank Mind Recovery:**

**(1) Restate:** "async-profiler modes: cpu (compute), wall (latency including IO/lock), alloc (GC optimization), lock (contention). Output: HTML flame graph, JFR. Production use: low overhead, start profiling while running, no JVM restart needed."

**(2) First principles:** "A profiler needs to answer: 'where is time being spent?' CPU mode: time = CPU cycles. Wall mode: time = elapsed clock time. Alloc mode: time = bytes allocated. Each mode answers a different performance question."

**(3) Bridge:** "Choosing the async-profiler mode is like choosing a tracking sensor. CPU mode: a heartbeat monitor (only triggers when active). Wall-clock mode: a GPS tracker (records position continuously, whether moving or stopped). Allocation mode: a shopping counter (records every item purchased)."

---

### 📘 Concept Explanation

**Async-profiler deep dive:**
```plaintext
ASYNC-PROFILER ARCHITECTURE:

  AsyncGetCallTrace API:
    Standard profiling: JVM must reach a safepoint before the profiler
    can sample the stack. This creates "safepoint bias" - methods
    between safepoints are invisible.
    
    AsyncGetCallTrace: called via OS signal (SIGPROF on Linux).
    The signal interrupts the thread at ANY point (not just safepoints).
    The stack is captured at the EXACT moment of interruption.
    No safepoint bias: accurate representation of CPU time.
    
    Available since JDK 1.4.2 (but not widely used until async-profiler).
    Java 17+: better support via JEP 425 (GetCallTrace enhancement).

MODES COMPARISON:

  CPU mode:
    -e cpu (or just default)
    How: OS SIGPROF signal every N microseconds
    Samples: only threads on CPU
    Shows: computation bottlenecks, hot methods, call paths
    Misses: IO wait, lock wait, sleep
    Overhead: ~1-2%
  
  Wall-clock mode:
    -e wall
    How: thread-internal timer, all threads sampled
    Samples: ALL thread states (RUNNABLE, BLOCKED, WAITING)
    Shows: entire elapsed time, including: waiting for DB response,
           waiting for lock, sleeping, waiting for IO
    Overhead: ~2-5% (samples more threads)
    Key insight: if p99 is high but CPU profile is sparse,
                 wall-clock shows the blocking call path
  
  Allocation mode:
    -e alloc
    How: TLAB sampling (instruments the slow-path TLAB fill)
    Samples: every N-th allocation (configurable, default: ~500KB)
    Shows: which code paths create the most objects
    Overhead: ~1-5% depending on allocation rate
    Not all allocations sampled: only TLAB refill events
    (very short-lived objects within one TLAB may be missed)
  
  Lock mode:
    -e lock
    How: instruments Java monitor operations (synchronized, wait, notify)
    Samples: lock contention events with duration
    Shows: which monitors are hottest, thread contention
    For j.u.c.locks: use -e monitor (different event)

FLAME GRAPH READING TIPS:

  Colors in async-profiler output:
    Yellow/Green: Java code (JIT compiled)
    Red: native code (C library, OS)
    Teal: JVM internal frames (interpreter, runtime)
    Brown: C++ (JDK native methods)
  
  Wide frame at TOP = hot leaf method
  Wide frame at MIDDLE = call through a common path
  Narrow spike = rarely-called path
  
  SEARCH (Ctrl+F in browser): find a specific class or method
  ZOOM: click a frame to zoom in, click background to reset
  HOVER: shows exact percentage and full method name

PRODUCTION PROFILING:

  Lightweight continuous profiling (safe for production):
    Method 1: JFR continuous mode
      -XX:+FlightRecorder
      jcmd <pid> JFR.start settings=default maxage=5m
      # JFR overwrites old data after 5 minutes (ring buffer)
      jcmd <pid> JFR.dump filename=on-demand.jfr
      # Triggered by alert: capture last 5 minutes of data
    
    Method 2: async-profiler in background (low interval):
      ./profiler.sh -e cpu -i 10ms -d 60 -f profile.html <pid>
      # 10ms interval = lower overhead (default is 1ms)
      # Triggers: run when p99 spike detected by alerting system
    
    Safety checks before production profiling:
      1. Has the profiler been tested on staging? (same JVM flags)
      2. Is profiler overhead acceptable? (<5% CPU increase)
      3. Is disk space available for output? (flame graph HTML: ~1-5MB)
      4. Is the JVM running with -XX:+PreserveFramePointer? (async-profiler needs this on JDK < 17)

COMMON FLAME GRAPH PATTERNS:

  Pattern: Wide spike at java.net.SocketInputStream.read()
    Interpretation: threads are blocked waiting for network IO
    (DB response, HTTP response, message queue response)
    Fix: increase DB connection pool size, optimize the query,
         add caching, use async IO

  Pattern: Wide spike at sun.misc.Unsafe.park()
    Interpretation: threads waiting for a lock/condition
    Fix: identify which lock (use lock mode: -e lock),
         reduce lock scope, use lock-free alternatives

  Pattern: Wide spike at java.util.HashMap.get() or put()
    Interpretation: hot HashMap operations
    Fix: check for collision (poor hashCode), pre-size,
         consider ConcurrentHashMap if concurrent,
         or specialized map (EnumMap, IntObjectMap)

  Pattern: Wide spike at GC threads
    (appears in CPU mode if GC is using significant CPU)
    Interpretation: high GC overhead
    Fix: reduce allocation rate (use alloc mode to find source)
```

> **Code walkthrough:** This Triggers: run when p99 spike detected by alerting system example demonstrates a key concept in practice using Stream. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

> **Code walkthrough:** The async-profiler command examples show the practical workflow for each
> mode. The wall-clock analysis shows how to diagnose a latency problem where CPU profiling
> would show nothing because the thread is blocked waiting.

```java
// ASYNC-PROFILER COMMAND REFERENCE:

// 1. CPU PROFILING (find compute bottlenecks):
// ./profiler.sh -d 60 -f cpu-flamegraph.html <pid>
// Same, with JVM PID auto-detect (Java 17+ supports better attach):
// ./profiler.sh -d 60 -f cpu-flamegraph.html $(jcmd | grep MyApp | awk '{print $1}')

// 2. WALL-CLOCK PROFILING (find latency bottlenecks):
// ./profiler.sh -d 60 -e wall -t -f wall-flamegraph.html <pid>
// -t: separate threads (one row per thread in flame graph)
// Shows where threads are blocked (IO, locks, sleep)

// 3. ALLOCATION PROFILING (find GC pressure sources):
// ./profiler.sh -d 60 -e alloc -f alloc-flamegraph.html <pid>

// 4. JFR OUTPUT (for JMC analysis):
// ./profiler.sh -d 60 -o jfr -f recording.jfr <pid>
// Open recording.jfr in JDK Mission Control

// 5. AGENT MODE (start with JVM, no attach required):
// In JVM args:
// -agentpath:/opt/async-profiler/lib/libasyncProfiler.so=\
//   start,event=cpu,interval=1ms,file=/tmp/profile.html,duration=60

// DIAGNOSING A LATENCY SPIKE WITH WALL-CLOCK PROFILING:

// Scenario: p99 = 500ms. CPU profile shows no hot code.
// -> threads are spending time waiting, not computing.

// Run wall-clock profile during a load test:
// ./profiler.sh -d 60 -e wall -t -f wall.html <pid>

// EXPECTED FLAME GRAPH FINDING (illustrative):
// Thread: http-nio-8080-exec-1  [42% of wall time in this thread]
// main thread stack frames:
//   OrderController.getOrder()
//   OrderService.findOrder()
//   OrderRepository.findById()
//   HikariCP.getConnection()   <- 35% of this thread's wall time!
//   AbstractQueuedSynchronizer.park()  <- BLOCKED on connection pool
// 
// Interpretation: threads are waiting 35% of the time for a DB connection.
// Root cause: HikariCP connection pool too small for the concurrency level.
// Fix: increase pool size (hikari.maximumPoolSize = current * 1.5-2x)
// Validate: wall-clock profile should show the getConnection() block shrink

// ANNOTATION-BASED PROFILING TRIGGER (Spring AOP for selective profiling):
@Aspect
@Component
public class PerformanceProfilingAspect {
    
    private static final AtomicBoolean PROFILING_ACTIVE = new AtomicBoolean(false);
    
    @Around("@annotation(Profile)")
    public Object profileMethod(ProceedingJoinPoint pjp) throws Throwable {
        if (PROFILING_ACTIVE.compareAndSet(false, true)) {
            // Trigger async-profiler programmatically if needed
            // AsyncProfiler.getInstance().start(Events.CPU, Duration.ofSeconds(30));
        }
        long start = System.nanoTime();
        try {
            return pjp.proceed();
        } finally {
            long elapsed = System.nanoTime() - start;
            if (elapsed > 100_000_000L) {  // > 100ms: log for investigation
                log.warn("Slow operation: {} took {}ms",
                    pjp.getSignature(), elapsed / 1_000_000);
            }
        }
    }
}
```

> **Code walkthrough:** The wall-clock profiling workflow shows the critical path: CPU profiling
> finds nothing (threads are not burning CPU), wall-clock profiling reveals 35% of wall time in
> `AbstractQueuedSynchronizer.park()` via `HikariCP.getConnection()`. This is blocked waiting
> for a DB connection from an exhausted pool. Without wall-clock mode: this bottleneck would be
> invisible. The Spring AOP snippet shows how to add slow-operation detection instrumentally.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> async-profiler modes: cpu (compute), wall (latency), alloc (GC). Run during a load test to get
> representative data. Open the HTML flame graph in a browser. Find the widest frame near the top.
> That's the bottleneck.

---

**Senior / Staff (5+ years):**
> Production profiling strategy: always-on JFR (default + flight-recorder settings, < 1% overhead),
> triggered async-profiler for investigation (manually triggered when p99 spike is detected).
> Infrastructure: create a Grafana alert that fires when p99 > 2x baseline for 5 minutes. Alert
> runbook: "run async-profiler wall-clock on the affected pod for 60 seconds, upload flamegraph.html
> to shared drive, analyze." This gives engineers the tool to diagnose performance issues in < 5
> minutes instead of requiring a performance expert.

---

### ⚠️ Common Misconceptions

**Misconception: "async-profiler captures every allocation event."**
Async-profiler allocation mode samples allocations at the TLAB (Thread-Local Allocation Buffer)
slow path - when a TLAB is exhausted and a new one must be allocated from Eden. Short-lived small
objects that live entirely within one TLAB are NOT sampled (they never trigger the slow path). This
means: the allocation flame graph underrepresents small, frequent allocations. For those: JFR's
`jdk.ObjectAllocationInNewTLAB` event (which can be configured with a very low threshold) or
async-profiler with `-e alloc --alloc 1` (sample every allocation, very high overhead) gives a
complete picture.

---

### 🚨 Failure Modes and Diagnosis

**Failure: async-profiler fails to attach to JVM with "Could not attach to NNN".**
```
Symptom: Running profiler.sh against a running JVM fails with:
  "Could not attach to <pid>: java.io.IOException: Can not attach to the JVM"
  or: "Failed to load agent library"

Root causes and fixes:

  A: JVM running as a different user:
     Profiler must run as the same user as the JVM, or root.
     sudo ./profiler.sh -d 30 -f profile.html <pid>
     or: docker exec -it <container> bash -> run profiler inside container
  
  B: /proc/sys/kernel/yama/ptrace_scope = 1 (restricted):
     Linux ptrace restricted to parent processes only.
     Fix: echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
     (temporary, reverts on reboot)
     Or: run profiler as root.
  
  C: JDK 17+ module restrictions (JEP 403):
     --add-opens restrictions prevent attach.
     Fix: add to JVM startup flags:
     -Djdk.attach.allowAttachSelf=true
     -XX:+EnableDynamicAgentLoading (JDK 21+)
  
  D: Container without ptrace capability:
     Kubernetes pod: profiler fails because container lacks CAP_SYS_PTRACE.
     Fix: add to pod spec:
     securityContext:
       capabilities:
         add: ["SYS_PTRACE"]
     Or: use agent mode (start profiler with JVM, no attach needed):
     -agentpath:/path/to/libasyncProfiler.so=start,...
  
  E: JDK installed without debug symbols (rare):
     Frame symbolization fails for JVM internal frames.
     Install JDK debug symbols or use JFR output mode.
```

> **Code walkthrough:** This Triggers: run when p99 spike detected by alerting system example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| CPU vs wall-clock mode | 2 minutes |
| Safepoint bias in profiling | 2 minutes |
| When allocation profiling is needed | 1 minute |
| Production profiling safety | 2 minutes |
| Interpreting a flame graph | 2 minutes |
| Lock profiling | 1 minute |
| JFR vs async-profiler | 1 minute |
| Profiler attach failures | 1 minute |
| Finding IO bottleneck with profiler | 1 minute |

---

**Q1 (safepoint bias): What is the "safepoint bias" in profiling and why does async-profiler avoid it?**

A: Safepoint: a point in bytecode execution where all JVM threads can be safely paused (for GC,
deoptimization, etc.). JVM safepoints occur at method exits and loop back-edges. Standard profilers
(VisualVM, older JProfiler CPU sampling): can only sample thread stacks AT safepoints. Problem: if
a method contains a tight inner loop with no back-edge (e.g., a SIMD-like computation): it's invisible
to safepoint-biased profilers (the profiler samples at the last safepoint before the loop starts).
async-profiler: uses `AsyncGetCallTrace`, an OS-level signal (`SIGPROF`). The signal can interrupt
a thread at ANY point (not just safepoints). Captures the true call stack at the moment of interruption.
No safepoint bias: accurate representation of CPU time including tight inner loops.

*What separates good from great:* The practical consequence of safepoint bias: a safepoint-biased profiler
might show `someCallerMethod` as consuming 30% of CPU time, when the ACTUAL hot code is the tight inner
loop inside a native or JIT-inlined method that has no safepoint. The developer optimizes `someCallerMethod`
(perhaps refactoring it) and sees no improvement, because the real bottleneck was never shown. This
"false positive optimization" is expensive (developer time, code complexity, no performance gain). With
async-profiler: the tight inner loop shows up correctly. The developer targets the real bottleneck.
This is why async-profiler is the standard recommendation for production-ready Java profiling.

---

**Q2 (wall vs cpu): If a service has high p99 latency but CPU utilization is normal (30-40%), which profiler mode should you use?**

A: Wall-clock mode. High p99 with low CPU: threads are spending most of their time waiting, not
computing. CPU mode only captures threads that are RUNNING (using CPU). A thread blocked waiting
for a DB response: 0% CPU contribution to the CPU flame graph. Wall-clock mode: captures ALL
threads including BLOCKED/WAITING. The wall-clock flame graph will show the blocking call path
(e.g., `SocketInputStream.read()` in a thick block under the service call that's waiting for
the DB). The width of that block = proportion of total elapsed time spent waiting.

*What separates good from great:* The "which thread" disambiguation: wall-clock profiling with `-t` flag
creates separate rows per thread in the flame graph. In a service with a p99 problem: you can identify
which specific threads are the slowest (widest in the flame graph). If 10% of threads are blocking on
one specific DB query: that query is the root cause. The 90% of threads with normal profiles: not the
bottleneck. The `-t` flag is critical for multi-threaded server analysis: without it, all thread stacks
are merged into one flame graph (which can obscure which threads are contributing to the latency).

---

**Q3 (alloc mode): What is the output of allocation profiling and how do you act on it?**

A: Allocation flame graph: each frame's width = proportion of total bytes allocated by that call path.
The widest frame near the top = the code path allocating the most objects. Typical output: `serializeOrder()`
-> `ObjectMapper.writeValueAsBytes()` -> `BeanSerializer._serialize()` at 45% of all allocations.
Action: that serializer is creating temporary Java objects for every field. Fix: (1) switch to a
schema-based serializer (Protobuf, Avro) that generates code instead of reflection. (2) Or: cache
the serialized form if the order doesn't change frequently.

*What separates good from great:* The "allocation rate vs live set" distinction: the allocation flame graph
shows RATE (objects created per second), not LIVE SET (objects alive at any given time). High allocation
rate with short-lived objects: causes young GC overhead (frequent minor GC pauses). Long-lived objects
that survive to old gen: cause major GC overhead. A cache that accumulates 100MB of objects (live set growth)
may have a LOW allocation rate (objects are added slowly and never removed). The allocation flame graph
would show the cache as low-priority (low rate). But the memory leak symptom shows it as high-priority
(old gen filling). Use allocation profiling for rate bottlenecks; use heap dump analysis for live set
(leak) bottlenecks. Different tools for different problems.

---

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



