---
layout: default
title: "Java Performance - L2 GC Basics"
parent: "Java Performance"
grand_parent: "SK Interview"
nav_order: 4
permalink: /java-performance/l2-gc-basics/
---

# Java Performance - L2 GC Basics

## GC Algorithms: G1, ZGC, Shenandoah Comparison

### 🎯 Model Answer

**30 seconds:**
> Java GC algorithms: G1 (default, generational, targets MaxGCPauseMillis), ZGC (concurrent,
> ultra-low latency < 1ms pause, JDK 15+ production-ready), Shenandoah (concurrent, similar to
> ZGC, JDK 17+ production-ready), Parallel GC (high throughput, long pauses). Choice: G1 for
> most apps, ZGC/Shenandoah for latency-sensitive, Parallel GC for batch processing.

**3 minutes (Senior):**
> GC algorithm comparison by mechanism:
>
> **G1 GC (Garbage-First)**:
> - Heap divided into equal-sized regions (1-32MB each).
> - Young gen: Eden regions + Survivor regions. Old gen: old regions.
> - Young GC: stop-the-world, evacuates Eden + Survivor regions. Target: MaxGCPauseMillis.
> - Mixed GC: evacuates young regions + some old regions with most garbage. Concurrent marking
>   runs concurrently to find garbage regions.
> - Full GC: last resort, stop-the-world, happens when concurrent marking can't keep up.
> - `-XX:MaxGCPauseMillis=200` (default): G1 targets 200ms pauses. Actual pauses depend on
>   live data volume and heap fragmentation.
>
> **ZGC**:
> - Mostly concurrent: GC threads run alongside application threads. Only 3 stop-the-world
>   pauses: initial mark, remap roots, final mark. All very short (< 1ms typical).
> - Colored pointers: uses bits in the object pointer to track GC state. No write barrier
>   needed for most operations.
> - Generational ZGC (JDK 21): adds generations for better throughput without sacrificing latency.
> - Trade-off: higher throughput overhead (GC threads use CPU that could serve requests).
>
> **Shenandoah**:
> - Concurrent compaction: unlike G1 (which evacuates stop-the-world), Shenandoah compacts
>   concurrently using load reference barriers.
> - Similar pause characteristics to ZGC (sub-millisecond).
> - Not in Oracle JDK (Red Hat OpenJDK only), but in JDK 17+.

**Blank Mind Recovery:**

**(1) Restate:** "G1: default, generational regions, 200ms pause target. ZGC: concurrent, < 1ms pauses, JDK 15+. Shenandoah: concurrent compaction, < 1ms, Red Hat JDK. Parallel: high throughput, long pauses. Use G1 default; ZGC for latency-critical."

**(2) First principles:** "Every GC algorithm solves the same problem (reclaim unreachable objects) but makes different trade-offs between: pause duration (latency), GC throughput overhead (CPU for GC vs app), and memory overhead. No algorithm is universally best."

**(3) Bridge:** "GC algorithms are like office cleaning strategies. Parallel GC: close the office, clean everything at once (long pause, thorough). G1: identify the messiest rooms, clean those first during a brief pause (targeted). ZGC: clean while everyone is still working (no real pause, but the cleaner is taking up desk space)."

---

### 📘 Concept Explanation

**GC algorithm trade-offs in detail:**
```
GC COMPARISON TABLE (key dimensions):

  Metric          G1 (default)   ZGC         Shenandoah  Parallel GC
  -----------     ------------   -------     ----------  -----------
  Max pause       50-200ms       < 1ms       < 1ms       100ms-10s+
  Throughput      High           Medium      Medium      Very High
  CPU overhead    Low            Medium      Medium      Low (pauses)
  Memory overhead Low            Medium      Medium      Low
  JDK version     JDK 9+ default JDK 15+     JDK 17+     JDK 1.4+
  Production?     Yes            Yes (15+)   Yes (17+)   Yes (batch)
  Best for        Most apps      Low latency Low latency Batch/offline

G1 GC INTERNALS:

  Heap layout:
    Regions: 1MB-32MB each (auto-sized based on -Xmx / 2048)
    Region types: Eden, Survivor, Old, Humongous, Free
    Humongous: region(s) for objects > 50% of region size
  
  GC cycles:
    Minor (Young GC): pause, collect Eden + Survivor regions
    Mixed GC: pause, collect Young regions + some Old regions
    Full GC: stop-the-world, last resort
  
  Concurrent marking (happens between GC cycles, no pause):
    Initial mark (stop-the-world, short): find roots
    Root region scan (concurrent): scan Survivor regions
    Concurrent mark (concurrent): trace heap from roots
    Remark (stop-the-world, short): complete marking
    Cleanup (pause + concurrent): identify garbage regions
  
  Key flags:
    -XX:+UseG1GC               (default JDK 9+)
    -XX:MaxGCPauseMillis=50    (target pause, not guaranteed)
    -XX:G1HeapRegionSize=4m    (region size, usually auto)
    -XX:G1NewSizePercent=5     (min young gen % of heap)
    -XX:G1MaxNewSizePercent=60 (max young gen % of heap)
    -XX:ConcGCThreads=4        (concurrent marking thread count)

ZGC INTERNALS:

  Key mechanism: load barriers
    Every time a thread reads an object reference: the JVM inserts a
    "load barrier" that checks the reference's GC state bits.
    This allows concurrent relocation: GC moves objects concurrently,
    and the load barrier forwards old references to new locations.
  
  Colored pointers:
    ZGC uses bits 42-45 of the 64-bit pointer for GC state:
    Marked0, Marked1, Remapped, Finalizable
    CPU processes these bits cheaply (bit masking is fast).
  
  Key flags:
    -XX:+UseZGC
    -XX:SoftMaxHeapSize=Ng  (soft limit, allows ZGC to compact proactively)
    Generational ZGC (JDK 21): -XX:+UseZGC -XX:+ZGenerational

CHOOSING A GC:

  Interactive latency-critical (APIs, UIs):
    p99 SLA < 100ms: ZGC or Shenandoah (JDK 17+)
    p99 SLA 100-500ms: G1 with -XX:MaxGCPauseMillis=100
    p99 SLA > 500ms: G1 with default settings
  
  Batch/throughput-first (ETL, data processing):
    Parallel GC: -XX:+UseParallelGC
    (or: G1 with larger heap, fewer GC cycles)
  
  Heap size factors:
    Large heap (> 32GB): G1 minor GC pauses grow with young gen size.
    With ZGC: pauses < 1ms regardless of heap size (major advantage).
    ZGC: designed for heaps from 8MB to 16TB.
  
  When NOT to use ZGC:
    Throughput-first workloads: ZGC's CPU overhead for concurrent marking
    reduces application throughput. G1 or Parallel GC better here.
    Very small heaps (< 1GB): G1 is fine, ZGC overhead not justified.
```

---

### 💻 Code Example

> **Code walkthrough:** The GC log analysis commands show how to diagnose GC behavior in production.
> The before/after comparison demonstrates switching from G1 to ZGC for a latency-sensitive service
> and measuring the actual pause time improvement.

```java
// GC LOGGING AND ANALYSIS (enable in all environments):

// JVM FLAGS for production GC logging:
// -Xlog:gc*:file=/var/log/app/gc.log:time,uptime:filecount=5,filesize=20m
// This creates rotating GC log files (5 x 20MB max)

// SAMPLE G1 GC LOG ENTRY:
// [2025-01-15T14:23:05.123+0000][2.345s][gc] GC(42) Pause Young (Normal)
//   (G1 Evacuation Pause) 512M->256M(4096M) 45.234ms

// SAMPLE ZGC LOG ENTRY:
// [2025-01-15T14:23:05.123+0000] GC(1) Pause Mark Start 0.234ms
// [2025-01-15T14:23:05.234+0000] GC(1) Pause Mark End 0.156ms
// [2025-01-15T14:23:05.345+0000] GC(1) Pause Relocate Start 0.123ms
// -> Total max pause: 0.234ms (sub-millisecond!)

// SWITCHING FROM G1 TO ZGC (Spring Boot app):

// Before: G1 (default for JDK 17+)
// java -Xmx4g -XX:MaxGCPauseMillis=100 -jar app.jar
// GC log shows: Pause Young 80-120ms. p99 latency spikes to 150ms.

// After: ZGC
// java -Xmx4g -XX:+UseZGC -XX:SoftMaxHeapSize=3500m -jar app.jar
// GC log shows: Pause Mark Start 0.2-0.5ms. p99 latency < 50ms.

// KUBERNETES JVM FLAGS (recommended for ZGC in containers):
// -XX:+UseZGC
// -XX:+ZGenerational       (JDK 21+ - improves throughput)
// -XX:MaxRAMPercentage=75  (heap = 75% of container RAM)
// -XX:SoftMaxHeapSize=     (set to ~90% of -Xmx to allow ZGC headroom)
// -XX:+UseContainerSupport (auto-detect container CPU/memory limits)
// -Xlog:gc*:file=/logs/gc.log:time:filecount=3,filesize=10m

// GC METRIC MONITORING (Micrometer auto-exports):
// jvm.gc.pause: timer recording each GC pause duration
// jvm.memory.used{area=heap}: current heap usage
// jvm.gc.memory.promoted: rate of promotion to old gen

// Prometheus alert for GC pause:
// ALERT LongGCPause
//   IF histogram_quantile(0.99, rate(jvm_gc_pause_seconds_bucket[5m])) > 0.200
//   FOR 5m
//   ANNOTATIONS { summary = "GC p99 pause > 200ms" }
```

> **Code walkthrough:** The ZGC configuration shows the critical `-XX:SoftMaxHeapSize` flag: this
> tells ZGC to proactively compact when heap usage reaches the soft limit (leaving headroom before
> hitting the hard `-Xmx` limit). Without it: ZGC may defer compaction until the heap is nearly full,
> then need to do more work. The `-XX:+ZGenerational` flag (JDK 21) adds the generational optimization
> to ZGC, improving throughput significantly without sacrificing latency.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> G1: default, good for most apps. ZGC: ultra-low pause (< 1ms), use for latency-critical. Parallel GC:
> high throughput, use for batch. Key flags: `-XX:+UseZGC`, `-XX:MaxGCPauseMillis`. Enable GC logging
> in all environments: `-Xlog:gc*:file=gc.log:time`.

---

**Senior / Staff (5+ years):**
> GC choice is a trade-off between pause time and throughput overhead. ZGC concurrent marking uses
> CPU cycles that could serve requests. Under load: G1 may have higher throughput than ZGC even though
> G1 has longer pauses (the pauses are infrequent, so total throughput is higher). Benchmark your
> specific workload with both GCs. Generational ZGC (JDK 21) closes the throughput gap: concurrent
> marking of young gen only (most objects) reduces overhead significantly. For latency-sensitive
> services on JDK 21+: start with `-XX:+UseZGC -XX:+ZGenerational`.

---

### ⚠️ Common Misconceptions

**Misconception: "ZGC's sub-millisecond pauses mean the application never pauses."**
ZGC's concurrent phases run alongside the application, but the stop-the-world pauses still exist:
initial mark, remap roots, final mark. Each is typically 0.2-1ms. Additionally, ZGC's concurrent
GC threads consume CPU. Under heavy load, if ZGC threads compete with application threads for CPU:
application latency increases not from pauses, but from CPU contention. ZGC is not "free" - it
trades stop-the-world pauses for CPU overhead. Always measure CPU utilization when evaluating ZGC.

---

### 🚨 Failure Modes and Diagnosis

**Failure: ZGC allocation stall ("Allocation Stall") causing latency spike.**
```
Symptom: ZGC in use, but periodic latency spikes still occur.
  GC log shows: "Allocation Stall" events.
  p99 latency: 50-200ms during stall events.

Root cause: ZGC allocation stall.
  ZGC tries to stay ahead of allocation by concurrently compacting.
  If application allocates faster than ZGC can compact:
  Application threads are STALLED waiting for ZGC to free memory.
  This is the ZGC equivalent of G1's stop-the-world evacuation.
  
  Triggers:
    A: Heap too small for the application's live set + allocation rate
    B: Allocation rate spike (e.g., burst of requests)
    C: SoftMaxHeapSize not set (ZGC waits too long to start compaction)

Diagnosis:
  GC log: search for "Allocation Stall" or "Stall" in ZGC log entries.
  Heap utilization: if heap is consistently > 80-85% before GC cycle: too small.
  Allocation rate: async-profiler alloc mode to find high-allocation code.

Fix:
  1. Increase heap: -Xmx (if container allows)
  2. Set -XX:SoftMaxHeapSize to ~85% of -Xmx to start GC earlier
  3. Reduce allocation rate (object pooling, reduce temporary objects)
  4. Add GC threads: -XX:ConcGCThreads=N (default: ~25% of CPU threads)
  5. For bursty workloads: G1 may be more resilient to allocation spikes
     than ZGC (G1 young GC can quickly reclaim Eden during burst)
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| G1 vs ZGC trade-off | 2 minutes |
| G1 region structure | 2 minutes |
| ZGC concurrent mechanism | 2 minutes |
| When to choose ZGC | 1 minute |
| Allocation stall in ZGC | 2 minutes |
| GC logging setup | 1 minute |
| Generational ZGC (JDK 21) | 1 minute |
| GC impact on CPU | 1 minute |
| G1 mixed GC trigger | 1 minute |

---

**Q1 (tradeoff): What is the fundamental trade-off between G1 and ZGC?**

A: G1: stop-the-world evacuation (brief pauses, 10-200ms). During pause: all threads stop. After pause:
compacted heap, application resumes at full speed. Between pauses: 100% CPU for application. ZGC:
concurrent collection (< 1ms pauses). During GC: GC threads share CPU with application threads. Always
"some" CPU overhead for GC. No long pauses, but application never has 100% CPU. Net result: G1 has better
peak throughput (when not in GC pause) but periodic latency spikes. ZGC has consistent (lower) throughput
but no latency spikes.

*What separates good from great:* The "throughput cliff" scenario with G1: at high allocation rates,
G1 young GC frequency increases. If young GC pauses overlap with each other (triggered before the
previous one completes): the JVM escalates to a full GC. Full GC: single-threaded, stop-the-world,
takes seconds. This "G1 Humongous Evacuation Failure" scenario is a hard latency cliff. ZGC: doesn't
have this cliff because collection is always concurrent. For services where p99.9 must be bounded
(financial services, real-time systems): ZGC's guarantee of sub-millisecond pauses even at high heap
utilization is critical. G1's guarantee of 200ms pauses "most of the time" is not sufficient.

---

**Q2 (regions): Explain G1's region structure and how it differs from classic generational GC.**

A: Classic generational (Parallel/CMS): fixed young gen + fixed old gen. Young gen size: -Xmn or
-XX:NewRatio. Rigid: if young gen is too small, high promotion rate. G1: heap divided into equal
regions (1-32MB). Each region can be: Eden, Survivor, Old, or Humongous. No fixed generational
boundary. G1 dynamically adjusts how many regions are young vs old based on the target pause time
and live data volume. More flexible: adapts to workload changes.

*What separates good from great:* The G1 humongous region: objects larger than 50% of the region size
are "humongous." They are allocated directly in one or more contiguous Humongous regions (bypassing
the young gen). Key implication: humongous objects are NOT collected in young GC. They are collected
only in the concurrent marking cycle or full GC. If the application frequently allocates large objects
(> 2MB for G1 with 4MB regions): humongous regions accumulate in old gen, trigger frequent mixed GC or
full GC. Detection: JFR event "G1 Humongous Allocation" shows which code paths allocate humongous
objects. Fix: resize the offending objects below the humongous threshold, or use `ByteBuffer.allocateDirect()`
for large IO buffers (off-heap, not subject to G1 humongous tracking).

---

**Q3 (zgc mechanism): How does ZGC achieve sub-millisecond pause times?**

A: ZGC does nearly all work concurrently: (1) Concurrent mark: trace all reachable objects while app
runs. (2) Concurrent relocate: physically move objects to compact heap while app runs. (3) Concurrent
remap: update all references to point to new locations while app runs. The trick for concurrent
relocation: "colored pointers" and "load barriers." Every reference read goes through a load barrier
that checks if the referenced object has been relocated. If relocated: the barrier forwards the old
pointer to the new location, transparently. Stop-the-world phases: only 3, each brief (< 1ms): initial
mark (find GC roots), remark, final remap.

*What separates good from great:* The "load barrier overhead" detail: every single object reference
dereference has a load barrier (a few extra instructions). For pointer-intensive code (lots of object
traversal), this overhead can be 5-15% compared to G1. This is where ZGC's throughput penalty comes
from - not from GC pauses but from the overhead of every pointer access. Generational ZGC (JDK 21)
reduces this overhead significantly: only pointers into the young generation need load barriers (most
objects), not the entire heap. Benchmark: use JMH to compare throughput of your specific data structures
under G1 vs ZGC to quantify the actual overhead for your workload.

---

---

## GC Tuning Fundamentals: Heap Sizing and Pause Goals

### 🎯 Model Answer

**30 seconds:**
> GC tuning: (1) Size the heap: old gen should be 2-3x the live set. (2) Set pause targets:
> `-XX:MaxGCPauseMillis` (G1). (3) Match young gen to allocation rate. (4) Monitor: GC logs,
> GC overhead %, allocation rate. The most impactful tuning is reducing allocation rate
> (code change), not JVM flags.

**3 minutes (Senior):**
> GC tuning hierarchy (most impactful first):
>
> 1. **Reduce allocation rate** (code change): highest impact. Less allocation -> less frequent GC -> better latency. async-profiler alloc mode: find hot allocation paths. Object pooling, avoiding temporaries.
>
> 2. **Right-size the heap**: old gen at steady state should be < 50-60% capacity. If old gen
>    is > 70% at steady state: either (a) heap too small (increase -Xmx), or (b) live set too
>    large (reduce caching, fix memory leak). Rule: `old gen size = 2-3x live data set size`.
>
> 3. **Tune pause targets** (G1): `-XX:MaxGCPauseMillis`. Lower value -> more frequent GC
>    (smaller work per cycle) -> less allocation done per cycle -> may increase GC overhead.
>    Start with 100-200ms, measure, adjust.
>
> 4. **Concurrent GC threads**: `-XX:ConcGCThreads`. More threads -> concurrent marking faster
>    -> less chance of promotion failure. But: fewer CPU cycles for application.
>
> 5. **Young gen sizing**: large young gen -> less frequent young GC but longer pause when it
>    does run. Small young gen -> frequent short young GC. Tune based on workload.

**Blank Mind Recovery:**

**(1) Restate:** "Tuning priority: (1) reduce allocation (code), (2) right-size heap, (3) tune pause goal (-XX:MaxGCPauseMillis), (4) ConcGCThreads. Most impact: allocation reduction. Heap sizing: old gen < 50-60% at steady state."

**(2) First principles:** "GC overhead is proportional to: (allocation rate) / (collection throughput). Reduce allocation or increase collection throughput. Collection throughput: heap sizing (larger heap = more time between GCs), GC threads."

**(3) Bridge:** "GC tuning is like managing a restaurant kitchen. The most impactful fix: reduce how many dishes are dirtied per service (allocation). Next: ensure the dishwasher (heap) is big enough. Then: set how fast to wash dishes (pause target). Throwing more dishwashers at the problem (threads) is a last resort."

---

### 📘 Concept Explanation

**Heap sizing and G1 tuning methodology:**
```
LIVE SET SIZING:

  Live set = all objects that must survive all GC cycles
  (caches, connection pools, framework objects, class metadata)
  
  Measure live set:
    jmap -histo:live <pid> | awk '{sum += $3} END {print sum/1024/1024 "MB"}'
    Or: JFR heap statistics event shows old gen size after full GC
  
  Sizing formula:
    -Xmx = max(live_set * 3, peak_workload_heap_requirement)
    Rule: old gen should never exceed 70% capacity at steady state.
    If it does: increase -Xmx or reduce the live set.
  
  Example:
    Live set = 1GB (caches, frameworks)
    Request working set = 500MB (objects alive during active requests)
    -Xmx should be >= (1GB live + 500MB working) * 2 = 3GB
    (the 2x provides headroom for GC to collect without a full GC)

G1 PAUSE TARGET TUNING:

  -XX:MaxGCPauseMillis=N (default: 200ms)
  
  Effect of lowering (e.g., 50ms):
    G1 collects fewer regions per GC cycle (to stay within time budget).
    More frequent GC cycles (each one shorter, more of them).
    Higher GC overhead if allocation rate is high.
    Better p99 latency (shorter individual pauses).
  
  Effect of raising (e.g., 500ms):
    G1 collects more regions per cycle (fewer, longer GC cycles).
    Lower GC overhead (fewer cycles).
    Worse p99 latency.
  
  Starting recommendations:
    Latency-sensitive: 50-100ms
    Balanced: 100-200ms (default)
    Throughput-first: 200-400ms (or switch to Parallel GC)
  
  WARNING: MaxGCPauseMillis is a TARGET, not a guarantee.
  If old gen fills faster than G1 can collect (allocation rate too high):
  G1 will exceed the target and may trigger a Full GC.

YOUNG GEN SIZING (G1):

  G1 auto-sizes young gen based on:
    1. Recent allocation rate
    2. MaxGCPauseMillis target
  
  Manual override:
    -XX:G1NewSizePercent=5    (min young gen = 5% of heap, default)
    -XX:G1MaxNewSizePercent=60 (max young gen = 60% of heap, default)
  
  When to override:
    If GC logs show very frequent young GC with tiny young gen:
    Increase G1NewSizePercent to allow more allocation before GC.
    If young GC pauses are too long:
    Decrease G1MaxNewSizePercent to limit young gen size.

GC TUNING PROCESS (systematic):

  Step 1: MEASURE CURRENT STATE
    Enable GC logs: -Xlog:gc*:file=gc.log:time
    Run load test (production-representative, 5-10 minutes)
    Collect: pause times, allocation rate, old gen growth rate
  
  Step 2: IDENTIFY THE PROBLEM
    Long pauses (> MaxGCPauseMillis): too much live data or high promotion
    High GC overhead (> 10%): high allocation rate or heap too small
    Full GC: old gen filling (heap too small or memory leak)
    Frequent young GC: high allocation rate or young gen too small
  
  Step 3: APPLY ONE CHANGE AT A TIME
    Change one flag. Re-run load test. Compare metrics.
    Multiple changes at once: you can't attribute the effect.
  
  Step 4: VERIFY AND DOCUMENT
    Record the final configuration with the measured improvement.
    Store in the deployment configuration (K8s Deployment, Dockerfile).

ALLOCATION RATE MEASUREMENT:

  From GC logs (G1):
  Parse: "Eden: NM->NM" values between young GC events
  Allocation rate = (Eden before GC) / (time between GC events)
  
  From JFR:
  jdk.GCHeapSummary event: heap used before/after each GC
  
  From Micrometer (auto-exposed in Spring Boot):
  jvm.gc.memory.allocated counter: cumulative bytes allocated
  Rate: rate(jvm_gc_memory_allocated_bytes_total[1m])
  
  Target allocation rate: < 500MB/s (for well-tuned apps)
  High allocation rate: > 1GB/s (investigate with alloc flame graph)
```

---

### 💻 Code Example

> **Code walkthrough:** The GC analysis script shows how to extract key metrics from GC logs
> programmatically. The configuration examples show the difference between a tuned and
> untuned production JVM configuration.

```java
// PRODUCTION JVM CONFIGURATION (Kubernetes/Docker):

// UNTUNED (common mistake - just -Xmx, nothing else):
// ENV JAVA_OPTS="-Xmx2g"
// Problems:
// - Heap may start at 512MB (JVM default -Xms) and resize dynamically (overhead)
// - No GC logging -> can't diagnose GC issues
// - No MaxMetaspaceSize -> Metaspace can grow without bound
// - No pause target specification
// - Code Cache default may be too small for large apps

// TUNED (production-ready G1 configuration):
// ENV JAVA_OPTS="\
//   -Xms2g -Xmx2g \
//   -XX:MaxMetaspaceSize=256m \
//   -XX:ReservedCodeCacheSize=512m \
//   -XX:+UseG1GC \
//   -XX:MaxGCPauseMillis=100 \
//   -XX:G1HeapRegionSize=4m \
//   -XX:ConcGCThreads=4 \
//   -Xlog:gc*:file=/var/log/app/gc.log:time:filecount=5,filesize=20m \
//   -XX:+HeapDumpOnOutOfMemoryError \
//   -XX:HeapDumpPath=/var/dumps/ \
//   -XX:+UseContainerSupport"

// TUNED (ZGC for latency-critical, JDK 21+):
// ENV JAVA_OPTS="\
//   -XX:MaxRAMPercentage=75.0 \
//   -XX:+UseZGC \
//   -XX:+ZGenerational \
//   -XX:SoftMaxHeapSize=3500m \
//   -XX:MaxMetaspaceSize=256m \
//   -XX:ReservedCodeCacheSize=512m \
//   -Xlog:gc*:file=/var/log/app/gc.log:time:filecount=3,filesize=10m \
//   -XX:+HeapDumpOnOutOfMemoryError \
//   -XX:HeapDumpPath=/var/dumps/"

// GC LOG PARSING (quick shell commands):

// Average pause time from G1 GC log:
// grep "Pause Young" gc.log | awk '{print $NF}' |
//   sed 's/ms//' | awk '{sum+=$1; n++} END {print "Avg:", sum/n "ms"}'

// Max pause time:
// grep "Pause" gc.log | awk '{print $NF}' |
//   sed 's/ms//' | sort -n | tail -5

// GC overhead % (pause time / total elapsed time):
// awk '/Pause/{pause+=$NF; gsub("ms","",$NF)}
//      END{print "Total pause:", pause "ms"}' gc.log

// Allocation rate per second (from Eden occupancy in G1 logs):
// grep "Eden" gc.log | head -20
// Pattern: "Eden: 512.0M(512.0M)->0.0B(512.0M) Survivors: 0.0B->64.0M"
// 512MB allocated between two Young GC events
// If interval between events = 500ms: allocation rate = 1024 MB/s (HIGH)
```

> **Code walkthrough:** The tuned JVM configuration shows the critical additions beyond `-Xmx`:
> `-Xms` equals `-Xmx` to avoid heap resizing overhead (no adaptive sizing between min and max),
> MaxMetaspaceSize to bound class loading memory, HeapDumpOnOutOfMemoryError for post-mortem
> diagnosis, and GC log rotation with size limits (5 x 20MB = keeps last 100MB of GC history).
> These are the production baseline flags that every JVM deployment should have.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Heap tuning: old gen should be < 50-60% at steady state. `-XX:MaxGCPauseMillis` sets G1's target.
> Always enable GC logging in production. Set `-Xms = -Xmx` to avoid heap resize. HeapDumpOnOutOfMemoryError
> for post-mortem.

---

**Senior / Staff (5+ years):**
> The most valuable GC tuning is reducing allocation rate (code change), not flag tuning. Flag tuning
> can shift the pause distribution but not improve GC overhead caused by high allocation rates. Before
> tuning flags: run async-profiler alloc mode, find the 3 highest-allocation code paths, reduce them.
> Then: size the heap based on the measured live set. Then: tune pause target for the SLA. In that order.
> Flag tuning without allocation reduction: diminishing returns.

---

### ⚠️ Common Misconceptions

**Misconception: "Setting -Xmx as large as possible always improves performance."**
A very large heap means: (1) if using G1, young GC pauses may become longer (more regions to evacuate).
(2) Full GC (if triggered) takes proportionally longer to complete. (3) The JVM startup time is longer
(JVM reserves virtual memory). (4) Startup heap is tiny (defaults to 1/64 of max), so the heap grows
dynamically from startup (-Xms = -Xmx prevents this). Optimal heap: 2-3x the live data set. Larger
than that: waste. ZGC exception: ZGC pause time is independent of heap size (sub-millisecond regardless
of 4GB or 400GB heap). For ZGC: a larger heap actually helps (more headroom for concurrent GC).

---

### 🚨 Failure Modes and Diagnosis

**Failure: G1 GC Ergonomics Log shows continuously declining pause prediction accuracy.**
```
Symptom: GC log shows MaxGCPauseMillis=100 but actual pauses are 300-500ms.
  Log entry: "GC(42) Pause Young (G1 Evacuation Pause) 423ms"
  G1 ergonomics log: "Attempting ergonomics" changes every GC cycle.

Root cause: G1 can't meet the pause target because:
  A: Live data per region is too high (too much survives each young GC)
     -> G1 can't reduce the work below 100ms
  B: Promotion rate too high (many objects being promoted to old gen)
     -> G1 needs to do more work per cycle
  C: Humongous objects: regions not being collected in young GC
     -> old gen fills, triggering mixed GC with larger work

Diagnosis:
  Enable G1 ergonomics log:
    -Xlog:gc+ergo*:file=gc.log
  
  Look for:
    "GC (young-only) phase is triggered" (young gen being sized down)
    "Attempting ergonomic young generation size adjustment"
    If G1 is constantly trying to shrink young gen: it's trying to
    reduce per-cycle work to meet the pause goal. If it can't: pauses remain high.
  
  Check live data per young GC:
    Pattern: "Eden: NM->0(NM) Survivors: AM->BM"
    Survivor size growing each cycle -> high promotion rate

Fix:
  1. If live data per GC is too high: increase MaxGCPauseMillis (accept longer pauses)
     or switch to ZGC (concurrent, no pause size-data correlation)
  2. If high promotion: objects living too long in young gen. Reduce cache size,
     shorten request processing time, increase young gen size
     (-XX:G1MaxNewSizePercent=40, up from default of 60 to limit, or:
     analyze what objects survive, fix their lifecycle)
  3. If humongous objects: find them (JFR G1HumongousAllocation event), fix the code
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| How to right-size the heap | 2 minutes |
| G1 MaxGCPauseMillis mechanics | 2 minutes |
| GC overhead formula | 1 minute |
| Step-by-step tuning process | 2 minutes |
| -Xms vs -Xmx | 1 minute |
| ZGC SoftMaxHeapSize | 1 minute |
| When does allocation rate matter | 1 minute |
| Full GC triggers | 1 minute |
| Production GC flags checklist | 1 minute |

---

**Q1 (sizing): How do you determine the correct heap size for a Java application?**

A: Process: (1) Measure the live set: `jmap -histo:live <pid>` + sum of live object sizes after
a stable Full GC. (2) Estimate peak working set: heap used during high-load (above live set, due to
active requests and their data). (3) Formula: `-Xmx = 2-3 * (live set + peak working set)`. The
2-3x factor: G1 needs headroom to avoid promotion failure (old gen must not fill during concurrent
marking). (4) In containers: use `-XX:MaxRAMPercentage=70` for the heap; allocate 30% for Metaspace
+ Code Cache + stacks.

*What separates good from great:* The "GC efficiency" calculation: GC overhead = pause time / total time.
If old gen is 90% full at steady state: G1 triggers concurrent marking frequently, mixed GC frequently,
each cycle reclaims small amounts (little garbage in nearly-full old gen). Efficiency is low. If old gen
is 50% full: GC cycles less frequently, each cycle reclaims more, efficiency is high. The "footprint vs
throughput" trade-off: a larger heap reduces GC frequency (improves throughput) but uses more memory
(increases cost). The sweet spot: old gen 30-50% utilization at steady state, with room to absorb
traffic spikes without triggering emergency Full GC.

---

**Q2 (pausegoal): What happens when you set -XX:MaxGCPauseMillis too low?**

A: G1 adapts by: (1) reducing young gen size (fewer regions per young GC, smaller work per cycle).
(2) Increasing young GC frequency (more collections, each shorter). Net effect: more GC events but
each one shorter. If the target is unrealistically low (e.g., 5ms with a 4GB heap): G1 can't
physically evacuate even one region in 5ms. It tries anyway, reports to ergonomics, but can't
meet the goal. GC overhead increases (more CPU for more frequent, smaller GCs). Latency may
worsen due to high GC overhead (CPU contention between GC and app threads).

*What separates good from great:* The G1 adaptive sizing feedback loop: G1 tracks the time to evacuate
one region. If evacuation of even 1 region takes 30ms: MaxGCPauseMillis of 10ms is impossible.
G1 will try to evacuate 0 regions per young GC (impossible - Eden must be collected). The result:
G1 switches to a full stop-the-world collection as a "safety valve" when it can't meet the target.
This is the "pause target feedback loop" breaking down. Symptom: log shows
"GC ergonomics adjusted young generation size to 0" + full GC follows. Fix: set a realistic pause
target based on actual evacuation time per region (visible in GC logs as evacuation rate).

---

**Q3 (allocation): Why is reducing allocation rate more effective than tuning JVM flags?**

A: Allocation rate determines GC frequency (for a fixed heap size). Formula: `GC frequency =
allocation rate / eden size`. If Eden = 1GB and allocation rate = 500MB/s: young GC every 2 seconds.
If allocation rate = 2GB/s: young GC every 500ms. Doubling the heap allows 1-second intervals
(50% improvement). Halving the allocation rate gives 1-second intervals (same improvement, free).
Further allocation reduction to 100MB/s: young GC every 10 seconds (10x improvement over flag tuning).
Code changes can reduce allocation by 50-90% for high-allocation paths.

*What separates good from great:* The "allocation is not free" mental model: each object allocation
has cost: (1) TLAB bump-pointer (very cheap), but (2) TLAB refill (when TLAB is exhausted, a new
TLAB must be allocated from Eden, which requires a lock on Eden). (3) Young GC pause: every N allocations
trigger a young GC. High-frequency allocations: frequent young GC. The real cost is the GC overhead,
not the allocation itself. The "zero allocation" ideal: code that allocates nothing in the hot path
has zero GC overhead. Achievable for specific hot paths via: escape analysis (scalar replacement),
object pooling, primitive-specialized data structures (no autoboxing). The goal is not zero allocation
everywhere - just in the paths that dominate the allocation rate (top 3 from the alloc flame graph).

---
