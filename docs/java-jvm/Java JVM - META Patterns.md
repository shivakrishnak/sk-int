---
layout: default
title: "Java JVM - META Patterns"
parent: "Java JVM"
grand_parent: "SK Interview"
nav_order: 18
permalink: /java-jvm/meta-patterns/
---

# Java JVM - META Patterns

## JVM Performance Debugging Mental Model

### 🎯 Model Answer

**30 seconds:**
> JVM performance debugging follows a hierarchy: measure first, never guess. Start with
> symptoms (latency, throughput, error rate). Correlate with JVM metrics (GC overhead,
> heap occupancy, thread state). Isolate to a specific layer (GC, JIT warmup, I/O, CPU).
> Use JFR for production-safe profiling. Reproduce in staging. Fix one variable at a time.
> Validate the fix with a measurement that matches the original symptom.

**3 minutes (Senior):**
> Mental model: JVM performance = CPU + Memory + I/O + GC + Concurrency
>
> 1. **CPU-bound**: `process.cpu.usage` near 100%, but NOT due to GC. JFR CPU sampling:
>    identifies hot methods. GC overhead < 5% but still slow = CPU bottleneck. Fix: algorithm,
>    data structure, JIT inlining issues (method too large), vectorization opportunities.
>
> 2. **GC-bound**: `jvm.gc.overhead` > 5%, or P99 spikes align with GC pauses.
>    GC log analysis: allocation rate, promotion rate, live data size. Fix: heap size,
>    GC algorithm, reduce allocation in hot paths.
>
> 3. **Memory-bound**: high heap usage with healthy GC = memory leak. Growing
>    `jvm.gc.live.data.size` after GC. Heap dump + MAT: find leak. Growing off-heap:
>    NMT differential.
>
> 4. **I/O-bound**: threads blocked on I/O (`WAITING`, `TIMED_WAITING` in thread dump).
>    Latency in external calls, not CPU or GC. Fix: connection pool sizing, async I/O,
>    caching.
>
> 5. **Concurrency-bound**: `BLOCKED` threads (lock contention). Thread dump: all threads
>    blocked on same lock. Fix: reduce lock granularity, use lock-free structures, virtual threads.
>
> Investigation order: check symptom -> check GC overhead -> check CPU profile ->
> check thread states -> check memory trend -> isolate one factor -> fix -> verify.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "JVM perf debugging: measure, don't guess. Layers: GC, CPU, memory,
I/O, concurrency. Tools: JFR for CPU/GC, NMT for memory, thread dump for concurrency.
Fix one thing at a time, validate the metric that triggered the investigation."

**(2) First principles:** "A computer can do nothing unless CPU is executing instructions.
Every performance problem reduces to: wrong instructions running, right instructions running
too few times per second, or waiting for something not on CPU. Classify which, then drill down."

**(3) Bridge:** "JVM performance debugging is like a hospital diagnosis. Symptoms come in
(latency spikes, OOM). You check vitals (CPU, GC metrics). You run tests (JFR profiles,
heap dumps). You form a hypothesis. You treat one thing (not everything at once). You
re-check vitals. Pattern: symptom -> measurement -> hypothesis -> treatment -> validation."

---

### 📘 Concept Explanation

**JVM performance debugging decision tree:**
```
JVM PERFORMANCE DEBUGGING DECISION TREE:

Symptom: high latency or low throughput

STEP 1: Is GC the cause?
  Check: jvm.gc.overhead > 5% (proportion of time in GC)
  Check: P99 latency spike aligned with jvm.gc.pause timing?
  YES -> Go to GC investigation (Step 2)
  NO  -> Go to CPU/Thread investigation (Step 3)

STEP 2: GC investigation
  Check: allocation rate vs. heap size
    GC log: Minor GC frequency > 1/minute at steady state?
    YES: too high allocation rate or Eden too small
    Fix: reduce allocation in hot paths, increase Xmx, or switch to ZGC

  Check: live data growth
    jvm.gc.live.data.size growing over time?
    YES: memory leak - heap dump needed
    Fix: find and eliminate the leak

  Check: Old Gen pressure
    Old Gen > 70% after GC? -> Xmx too small or promotion too fast
    Fix: increase Xmx, adjust survivor ratios, check for premature tenuring

STEP 3: CPU investigation
  Check: CPU usage
    process.cpu.usage > 80% AND NOT GC? -> CPU-bound
    JFR CPU profile: which methods consume the most samples?
    Fix: optimize hot methods, check JIT inlining, algorithm changes

  Check: thread states
    Thread dump (jcmd <pid> Thread.print):
    BLOCKED threads -> contention on a lock
    WAITING threads -> waiting for I/O or external resource
    RUNNABLE (many) -> CPU saturation or CPU throttling

STEP 4: Off-heap investigation
  pod RSS growing beyond Xmx + expected off-heap?
  NMT differential (jcmd VM.native_memory summary.diff)
  Which region grows? Metaspace? Thread? Other (direct buffers)?
  Fix: cap the growing region, find leak

STEP 5: I/O investigation
  High I/O wait (iostat) + WAITING threads in thread dump
  Check: connection pool exhaustion (hikari.connections.active = pool.size)
  Check: slow external calls (APM traces - P99 of each external call)
  Fix: increase pool size, add circuit breaker, add caching
```

---

### 💻 Code Example

> **Code walkthrough:** The performance debugging sequence below shows the canonical
> investigation flow using production-safe tools. JFR is enabled at application startup
> and provides all necessary profiling data without application changes.

```bash
# JVM PERFORMANCE DEBUGGING SEQUENCE

# 1. TRIAGE: check GC overhead (always first)
jcmd <pid> GC.heap_info
# Output: GC overhead 3.2% <- healthy
#         Heap: 1.8GB / 4GB (45%)  <- OK

# If GC overhead > 5%: run GC analysis
jfr print --events jdk.GarbageCollection,jdk.YoungGarbageCollection \
    recording.jfr | head -100
# Look for: high frequency, long pause, type of GC

# 2. TRIAGE: CPU profile (if GC overhead is healthy)
# Start JFR from running JVM:
jcmd <pid> JFR.start name=profile duration=60s settings=profile \
    filename=/tmp/profile.jfr
# Wait 60 seconds
jfr print --events jdk.ExecutionSample /tmp/profile.jfr | \
    sort -t'=' -k2 -rn | head -20
# Shows: which methods are hottest in CPU samples
# If JVM threads dominate: check GC threads, JIT compiler threads

# 3. TRIAGE: thread states
jcmd <pid> Thread.print > /tmp/threads.txt
# Count states:
grep -c "BLOCKED" /tmp/threads.txt    # lock contention
grep -c "WAITING" /tmp/threads.txt    # I/O or condition wait
grep -c "RUNNABLE" /tmp/threads.txt   # actively executing

# 4. TRIAGE: off-heap
jcmd <pid> VM.native_memory baseline  # set baseline
# (wait 5 minutes under load)
jcmd <pid> VM.native_memory summary.diff  # check growth
# Output shows: +50MB in "Other" -> direct buffer growth

# 5. TRIAGE: memory leak check
# Run Full GC to get accurate live data:
# (STAGING ONLY: triggers Full GC, causes pause)
jcmd <pid> GC.run
jcmd <pid> GC.heap_info  # check heap after Full GC
# If heap > 60% after Full GC: live data is too large (leak or undersized)
# Take heap dump:
jcmd <pid> GC.heap_dump /tmp/heap.hprof
# Analyze with MAT (Eclipse Memory Analyzer Tool):
# Find: largest retained objects, ClassLoader leaks, duplicate strings
```

> **Code walkthrough:** The sequence prioritizes GC overhead check first because GC is
> the most common source of JVM performance issues and is cheap to check. Only if GC is
> healthy do we spend time on CPU profiling (JFR 60s recording has < 2% overhead).
> Thread state analysis (jcmd Thread.print) is free and reveals contention and I/O issues.
> Off-heap NMT diff is used last because off-heap leaks are rarer and slower to develop.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> JVM performance debugging: start with GC metrics (is GC overhead > 5%?). If yes: heap
> size or allocation issue. If no: use JFR CPU profiling to find hot methods. Thread dump
> for concurrency issues. Never make multiple changes at once - change one thing, measure.

---

**Senior / Staff (5+ years):**
> Performance debugging mental model: categorize the bottleneck before investigating.
> CPU-bound vs GC-bound vs I/O-bound vs contention-bound: each has completely different
> root causes and fixes. Mixing up categories wastes weeks. Production-safe investigation:
> JFR CPU profiles, GC logs, thread dumps, NMT diffs. Never: heap dump on live production
> (pauses the JVM). Never: change multiple JVM flags simultaneously. Metrics: establish
> a baseline, measure impact, A/B test the fix.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Increasing Xmx always improves JVM performance."**
Larger heap: less frequent GC (good). But longer GC pauses (bad for G1). If the
bottleneck is NOT GC: increasing Xmx doesn't help. If the bottleneck is a memory leak:
increasing Xmx only delays the inevitable OOM. If the bottleneck is CPU: more heap = more
objects for GC to scan = slower full GCs. Correct approach: identify the bottleneck first,
then apply the appropriate fix.

**Misconception 2: "A heap dump is the right first step for any performance issue."**
Heap dumps are expensive: require a full GC (stop-the-world, seconds for large heaps),
generate a large file (1-4GB), and require significant analysis time. They are the RIGHT
tool for: confirmed memory leaks (growing live data). They are the WRONG tool for:
latency spikes (GC-bounded or CPU-bounded issues), high CPU (JFR CPU profiling is correct),
thread contention (thread dump is correct). Using heap dump for everything: wastes production
pause time and generates false leads.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Performance issue that changes after investigation (Heisenbug).**
```
Symptom: production JVM shows 500ms P99 latency spikes
  Staging: cannot reproduce (all latency < 50ms)
  Added logging: spikes disappeared in production

Diagnosis: Heisenbug - the observation changed the behavior
  Common cause: GC pause that was triggered by log message allocation
    Production: no logging for specific request type
    Debug (with logging): String allocation for log messages
      -> pushes Eden over GC threshold
      -> Minor GC triggered
      -> GC pause = the 500ms spike
    
    Wait: logging should create String allocations regardless?
    Detail: logging was added at INFO level, but the appender was
      writing to a slow remote log aggregator
    With logging: appender serializes log records (allocates byte[])
    -> additional allocation -> triggers GC -> GC pause -> spike

Root cause: log appender using synchronous remote write in hot path
  (not related to the original issue - logging revealed a different bug)

Fix:
  1. Use async log appender (Logback AsyncAppender, Log4j2 Async Logger):
     log writes: queued to a background thread (no blocking in application thread)
  2. Add log guards: if (log.isDebugEnabled()) log.debug(...)
     (prevents String allocation even if log level is filtered)
  3. Profile: use JFR with logging-specific events to measure log write latency
     jfr print --events jdk.FileWrite,jdk.SocketWrite recording.jfr

Lesson: in performance debugging, the investigation method itself can change
  the behavior. Use tools with the lowest possible overhead:
  - JFR (< 2% overhead): production-safe
  - Thread dumps: free (brief OS signal, < 1ms)
  - NMT summary: < 5% overhead
  
  NEVER in production without careful consideration:
  - Heap dumps (full GC + file I/O + JVM pause)
  - -XX:+PrintCompilation (high overhead output)
  - -verbose:gc (high overhead output)
  - Synchronous tracing (any tracing that writes synchronously to disk/network)
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| First step in JVM performance debug | 1 minute |
| Distinguishing GC vs CPU bottleneck | 2 minutes |
| JFR for production profiling | 2 minutes |
| Thread dump analysis | 2 minutes |
| Memory leak investigation | 2 minutes |
| Heisenbug avoidance | 1 minute |
| Metrics to track JVM health | 2 minutes |

---

**Q1 (first step): What is the FIRST thing you check when a JVM service has performance issues?**

A: GC overhead (`jvm.gc.overhead` or `jvm.gc.pause`). GC is the most common cause of JVM
performance problems, and it's the cheapest to check (one metric). If GC overhead > 5%:
GC is the likely culprit. If GC is healthy (< 2%): eliminate GC as the cause and move
to CPU profiling. Checking GC first avoids the common mistake of spending hours on CPU
profiling or algorithm optimization when the actual problem is heap sizing.

*What separates good from great:* The ordering: GC -> CPU -> threads -> off-heap. Each
step eliminates an entire category of root causes. Most performance issues fall into one
category. Checking multiple categories simultaneously: creates noise (which of the 3
things I changed fixed it?). The discipline: one category at a time, one change at a time,
one measurement at a time. This applies whether you're investigating a 10% throughput
regression or a 10x latency spike.

---

**Q2 (gc vs cpu): How do you distinguish a GC bottleneck from a CPU bottleneck?**

A: GC bottleneck: `jvm.gc.overhead` > 5%, latency spikes align with GC pause timing in GC
log, `jvm.gc.pause` P99 is significant. CPU bottleneck: `process.cpu.usage` high but GC
overhead < 2%, JFR CPU profile shows application methods as hot (not GC/JIT threads).
Key distinction: during a CPU bottleneck, throughput is limited but latency may be stable
(all threads working). During a GC bottleneck: latency spikes at GC events, throughput
drops during pause, then recovers.

*What separates good from great:* The trick case: CPU bottleneck caused by GC-adjacent work.
When heap is nearly full: the GC runs continuously (concurrent marking, evacuation) even if
individual pauses are short. `jvm.gc.overhead` may show 10-20% of CPU time in GC, but
individual pauses are < 10ms (so P99 looks fine). The symptom: reduced throughput without
obvious latency spikes. The fix: increase heap size OR reduce allocation rate. This is
the "throughput degradation without latency spike" pattern that's easy to miss if you only
look at P99 latency.

---

**Q3 (jfr): Why is JFR the preferred profiling tool for production JVM?**

A: JFR (Java Flight Recorder): built into OpenJDK, < 2% overhead, records: CPU samples
(method profiling), GC events (full details including allocation rate), I/O events,
lock events, JVM internal events (class loading, JIT compilation, thread activity).
All in one recording file. Alternative tools: `-agentlib:hprof` (10-30% overhead, not
production-safe), VisualVM agent (requires JMX, doesn't work in restricted environments),
Async-profiler (< 1% overhead, good alternative). JFR: the production standard because
it's always available in JDK, low overhead, comprehensive.

*What separates good from great:* JFR continuous recording: `-XX:StartFlightRecording=
settings=default,maxage=1h,maxsize=250m,filename=/var/jfr/continuous.jfr`. The JVM
keeps the last 1 hour of JFR data in a ring buffer on disk. On an incident: retrieve
the last 1 hour of JFR data (includes the problem period) without any pre-activation.
This is the production-ready JFR deployment pattern: always-on at < 2% overhead, always
available for post-incident analysis. Combined with `jcmd <pid> JFR.dump`: you can
retrieve the recording at any time without restarting the JVM. Many teams run without
this and then cannot diagnose incidents because "JFR wasn't running when it happened."

---

**Q4 (thread dump): How do you analyze a thread dump for performance issues?**

A: Thread dump analysis: (1) count states: BLOCKED (lock contention), WAITING (I/O, condition),
TIMED_WAITING (sleeping, waiting with timeout), RUNNABLE (executing). (2) For BLOCKED:
find the lock holder (`waiting for <lock>` references `locked by <thread>`). If all
threads blocked waiting for one lock: lock contention bottleneck. (3) For WAITING: check
what they're waiting on (`Object.wait`, `LockSupport.park`, `Thread.sleep`). Many threads
waiting on a database connection: connection pool exhaustion.

*What separates good from great:* Thread dump analysis at scale: 200+ threads produce
a hard-to-read dump. Tools: `fastthread.io` (online thread dump analyzer - do NOT upload
production thread dumps with internal data), `TDA` (Thread Dump Analyzer, open-source,
local analysis). The pattern: group threads by state and stack trace. All threads with
the same stack trace at the blocking point: a common bottleneck. 50 threads all blocked
at `HikariPool.getConnection()`: connection pool size is too small for the load. 50 threads
all blocked at `Logger.info()`: synchronous log appender. These patterns are invisible in
P99 metrics but obvious in thread dumps.

---

**Q5 (heap dump): When should you take a heap dump and what do you look for?**

A: Take a heap dump: (1) confirmed memory leak (live data grows after GC), (2) OOM
investigating what consumed the heap. NEVER routinely in production (causes full GC + large
file). Heap dump analysis with MAT (Memory Analyzer Tool): (1) "Leak Suspects" report
(automated). (2) Largest retained object (the root of the leak). (3) ClassLoader leak:
many ClassLoader instances still in memory. (4) Duplicate strings: `java.lang.String`
objects with identical content (memory waste from uninterned strings).

*What separates good from great:* The heap dump + MAT "dominated objects" view: for
every object, MAT shows what would be freed if that object were garbage-collected
(the "retained heap size"). A `HashMap` holding 100MB of retained data: the HashMap
entry is the root cause. Navigate: HashMap -> entries -> key/value types -> source code
that put them there. For ClassLoader leaks: the ClassLoader itself retains all loaded
classes (Metaspace entries) AND all static fields of those classes. A leaked ClassLoader
with 5,000 loaded classes: retains 50-100MB of Metaspace AND all static fields. In web
applications with hot redeployment: one undisposed ClassLoader per redeployment = Metaspace
leak over time. MAT's "ClassLoader Explorer": shows all ClassLoader instances, their class
counts, and retained memory.

---

**Q6 (production tools): What tools are safe to use in production vs staging only?**

A: Production-safe: JFR continuous recording (< 2% overhead), `jcmd Thread.print`
(brief freeze), `jcmd VM.native_memory summary` (< 5% overhead with NMT summary mode),
`jcmd Compiler.codecache` (free), Prometheus/Micrometer JVM metrics (minimal overhead).
Staging-only: heap dump (`jcmd GC.heap_dump` causes full GC pause), `-XX:NativeMemoryTracking=detail`
(10% overhead), `-XX:+PrintCompilation` (high verbose output overhead), `jmap` (legacy,
superseded by jcmd), Address Sanitizer for JNI debugging.

*What separates good from great:* JFR "on-demand recording" (trigger on specific events):
`jcmd <pid> JFR.start name=exception_debug duration=30s settings=default`
triggers=Exception threshold=10/s. This starts a 30-second JFR recording when exception
rate exceeds 10/second. Useful for: investigating intermittent exception storms without
continuously recording. Similar: JFR breakpoints - trigger recording on specific JFR event.
The operational discipline: every incident tool should have a documented overhead estimate.
Establish: "under 5% overhead = always-on acceptable; 5-15% = short-duration investigation;
> 15% = staging only." Share this policy with on-call engineers so they make informed
decisions about production tool use during incidents.

---

**Q7 (systematic): What systematic method ensures you don't guess when debugging JVM performance?**

A: The OODA loop adapted for JVM: Observe (collect metrics, logs, traces), Orient (classify
the bottleneck category: GC/CPU/memory/I/O/concurrency), Decide (formulate a single
hypothesis), Act (make one change, measure before/after). Never change two things at once.
Never make a change without a predicted metric improvement. Never declare "fixed" without
a metric showing the change in the symptom that triggered the investigation.

*What separates good from great:* The "what would you expect to see?" test before any
fix: state explicitly what metric should improve and by how much. "I believe the issue
is Eden too small (evidence: Minor GC every 5 seconds). If I double Xmn (Eden size),
I expect: Minor GC frequency drops to every 10-15 seconds, and P99 latency spikes reduce
by 50%." If the metric doesn't move as predicted: the hypothesis was wrong. Abandon the
change (rollback), re-observe, re-orient. Engineers who skip the explicit prediction:
make changes, see some improvement in one metric, claim victory, and leave the root cause
unresolved. The original symptom returns in 2 weeks.

---

---

## GC Selection Decision Framework

### 🎯 Model Answer

**30 seconds:**
> GC selection: start with the default (G1, JDK 9+). Only switch if: P99 latency target
> requires < 10ms (switch to ZGC), very large heap > 8GB with latency requirements
> (ZGC), extreme throughput batch (ParallelGC), or memory-constrained (G1 with smaller
> heap). Never change GC without measuring the impact on your specific workload.

**3 minutes (Senior):**
> GC decision framework:
>
> | If your primary constraint is... | Use |
> |---|---|
> | P99 pause < 10ms | ZGC (JDK 15+) or Shenandoah |
> | Maximum throughput, batch, no latency SLA | ParallelGC |
> | Balanced throughput + pause, medium heap | G1 (default) |
> | Very large heap (> 8GB) + low latency | ZGC |
> | Extremely limited memory (< 512MB heap) | SerialGC or G1 with small heap |
>
> Selection process: (1) Define the SLA (P99 latency, throughput requirement).
> (2) Measure CURRENT GC behavior (pause, overhead). (3) If current GC meets SLA: no change.
> (4) If not: identify the bottleneck (pause too long? throughput too low?). (5) Select
> the GC that addresses the specific bottleneck. (6) Load test. (7) Validate against SLA.

**Blank Mind Recovery:**

**(1) Restate:** "GC selection: G1 = default safe choice. ZGC = < 10ms pauses. ParallelGC
= max throughput. Always: measure current behavior first, only switch if SLA is breached."

**(2) First principles:** "GC exists on a spectrum: all effort into fast GC (pause app
threads, GC fast, resume) vs all effort into never pausing (concurrent GC, overhead throughout).
No GC can be best at both ends. Choose: how important is pause vs throughput for THIS service?"

**(3) Bridge:** "GC selection is like choosing a road for delivery. Parallel highway (ParallelGC):
fastest end-to-end, but you have to stop at every traffic light (full pause). Toll road
(G1): some stops but predictable. Roundabout city streets (ZGC): never a full stop, but
slower overall throughput. Choose based on: is your deadline for the package or for each
intermediate stop?"

---

### 📘 Concept Explanation

**GC selection criteria matrix:**
```
GC SELECTION CRITERIA MATRIX:

  G1 (default JDK 9+):
    Pause model: incremental STW (collects some regions per pause)
    Target: MaxGCPauseMillis (default 200ms, tune to 50-100ms)
    Best for:
      - Heap 2-8GB
      - P99 pause < 100ms acceptable
      - Mixed workloads (API + some batch)
      - "I don't want to think about GC tuning"
    Tune: -XX:MaxGCPauseMillis=100 -XX:G1HeapRegionSize=16m
    Red flags: Old Gen > 70% after GC -> increase Xmx
              RSet update time > 30% of GC time -> Old->Young refs too frequent

  ZGC (JDK 15+ production, JDK 21+ with generational ZGC):
    Pause model: sub-ms (only initial mark + final mark < 1ms)
    Best for:
      - P99 pause < 10ms SLA
      - Large heap > 8GB
      - Latency-sensitive services (APIs, streaming)
    Overhead: 10-15% CPU for concurrent GC work
    Tune: minimal tuning needed (ZGC is mostly self-tuning)
          -XX:SoftMaxHeapSize for adaptive heap sizing
    Red flags: Allocation stall (GC can't reclaim fast enough)
              -> reduce allocation rate OR increase Xmx

  Shenandoah (OpenJDK, not Zing):
    Pause model: sub-ms (concurrent relocation via Brooks barriers)
    Best for:
      - Similar to ZGC but on platforms where ZGC is less mature
      - Alternative when ZGC is not available (some JDK distributions)
    Tune: similar to ZGC

  ParallelGC (Throughput GC):
    Pause model: STW, all GC threads in parallel (maximize GC speed)
    Best for:
      - Batch jobs, ETL, data processing
      - Throughput > 99% (application pause < 1% of time)
      - No latency SLA (pauses can be 0.5-2 seconds for large heaps)
    Tune: -XX:ParallelGCThreads=N, -XX:+UseParallelGC

  SerialGC:
    Pause model: STW, single GC thread
    Best for:
      - Very small heaps (< 512MB)
      - Single-CPU or severely CPU-constrained
      - CLI tools, small utilities
    Not for: production microservices

DECISION FLOWCHART:
  1. Heap size > 8GB? -> ZGC
  2. P99 latency SLA < 10ms? -> ZGC or Shenandoah
  3. P99 latency SLA < 100ms? -> G1 with MaxGCPauseMillis=50
  4. Batch job, no latency SLA? -> ParallelGC
  5. None of the above? -> G1 default
```

---

### 💻 Code Example

> **Code walkthrough:** The GC selection validation script shows the before/after
> measurement process. Changing GC without measurement is guessing; measurement is how
> you know if the change helped.

```bash
# GC SELECTION VALIDATION PROCESS

# STEP 1: Baseline current GC behavior
# Enable detailed GC logging:
-Xlog:gc*,gc+heap=debug:file=/var/log/gc.log:time,level,tags:filecount=5,filesize=20m

# Parse key metrics from GC log:
# After 1 hour in production, extract:
grep "GC pause" /var/log/gc.log |
  awk '{print $NF}' |          # extract pause duration
  sort -n |
  awk 'BEGIN{c=0; s=0} {a[c++]=$1; s+=$1}
    END{print "median:", a[int(c/2)], "p99:", a[int(c*0.99)],
        "p999:", a[int(c*0.999)], "max:", a[c-1]}'
# P99 pause: 180ms -> exceeds 100ms SLA -> consider ZGC

# GC overhead calculation:
grep "Pause" /var/log/gc.log |
  awk -F'ms' '{sum += $1} END{print "total pause time (ms):", sum}'
# Divide by total elapsed time to get overhead %

# STEP 2: Switch to candidate GC (staging environment)
# Change: -XX:+UseG1GC -> -XX:+UseZGC
# Load test: same traffic profile as production (5-minute warmup + 30 minutes steady)

# STEP 3: Compare metrics
# G1 results:
#   P50: 12ms, P99: 180ms, P999: 450ms, overhead: 3.2%
# ZGC results:
#   P50: 2ms, P99: 8ms, P999: 15ms, overhead: 4.8%
# CPU increase: 1.6% (ZGC concurrent GC slightly more CPU than G1 at this heap size)
# Decision: ZGC meets SLA, CPU increase is acceptable

# STEP 4: Deploy to production canary (1% traffic)
# Monitor for 2 hours: compare p99 latency, error rate, CPU
# If stable: progressive rollout 10% -> 50% -> 100%

# ZGC-specific monitoring (post-switch):
# Alert: allocation stall (ZGC can't keep up with allocation rate)
# JFR event: jdk.ZAllocationStall
# If stalls occur: either increase Xmx or reduce allocation rate
jfr print --events jdk.ZAllocationStall /tmp/recording.jfr
# Each stall: one thread waited for GC to free space (latency spike)
# Stall duration = GC latency spike duration = SLA impact
```

> **Code walkthrough:** The validation process forces explicit before/after measurement.
> The GC log parsing produces P99 and P999 pause times - the metrics that determine if
> SLA is met. The comparison shows the actual trade-off: ZGC achieves better P99 (8ms
> vs 180ms) at a small CPU cost (1.6%). Without this measurement, engineers often make
> GC changes based on benchmarks from the internet rather than their specific workload.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> GC selection: G1 is the safe default. Switch to ZGC only if P99 latency > 10ms from
> GC. Measure first: enable GC logging, find actual P99 pause. If it's already under
> your SLA: don't change anything. "Don't fix what isn't broken" applies to GC selection.

---

**Senior / Staff (5+ years):**
> GC selection is a measurement-driven decision. Inputs: P99 pause SLA, heap size,
> CPU budget, allocation rate. Process: baseline -> identify if current GC meets SLA ->
> if not, identify the specific failure mode (long pause? throughput loss?) -> select
> GC that addresses the specific failure. Monitor: post-switch validation with production
> canary. The common mistake: switching to ZGC proactively "because it's newer" - without
> confirming G1 actually misses the SLA.

---

### ⚠️ Common Misconceptions

**Misconception 1: "ZGC is always better than G1."**
ZGC achieves sub-ms pauses at the cost of 5-15% CPU overhead for concurrent GC work.
For small-heap services (< 2GB) where G1 already achieves P99 pause < 20ms: ZGC adds
CPU cost with no SLA benefit. ZGC is the right choice when: P99 pause from G1 exceeds
your SLA. Default recommendation: use G1 until it fails the SLA, then switch to ZGC.

**Misconception 2: "Tuning MaxGCPauseMillis is a guarantee."**
MaxGCPauseMillis is a TARGET, not a hard limit. G1 makes a best effort to meet it.
Under extreme heap pressure (nearly full, rapid allocation): G1 may exceed the target.
If G1 consistently misses the target: either increase Xmx (more headroom for G1 to work)
or switch to ZGC (ZGC's sub-ms pauses don't depend on this flag). MaxGCPauseMillis
is a tuning lever, not a SLA commitment.

---

### 🚨 Failure Modes and Diagnosis

**Failure: ZGC experiencing allocation stalls under high load.**
```
Symptom: P99 latency spikes after switching to ZGC
  Previously: G1 with predictable 50-100ms pauses
  After ZGC: usually < 1ms, but occasional 200-500ms spikes

Diagnosis:
  jfr print --events jdk.ZAllocationStall recording.jfr
  Output:
    Event: jdk.ZAllocationStall
    Duration: 312ms   <- thread waited 312ms for ZGC to free space
    Thread: http-request-worker-23

  Allocation stall: ZGC cannot reclaim memory fast enough to keep up with
  the application's allocation rate. Thread must wait for GC to free space.

  ZGC allocation stall causes:
    1. Allocation rate too high: ZGC's concurrent relocation can't keep up
    2. Heap too small: ZGC needs more headroom than G1 for concurrent work
       (ZGC recommendation: set Xmx 1.5-2x live data, not 1.2x as with G1)
    3. Fragmentation in ZGC medium/large pages

  Check:
    jfr print --events jdk.ZStatisticsCounters recording.jfr
    -> allocation rate, relocation rate, compaction statistics

Fix:
  Option A: Increase Xmx by 25-50%
    ZGC needs more headroom than G1 (concurrent relocation requires free space)
    Rule: ZGC Xmx = live_data * 2.0 to 3.0 (vs G1: live_data * 1.5 to 2.5)

  Option B: Reduce allocation rate
    JFR TLAB analysis to find hot allocators
    Reduce string allocation in hot paths
    Use object pooling for large objects

  Option C: Enable Generational ZGC (JDK 21+, experimental)
    -XX:+UseZGC -XX:+ZGenerational
    Generational ZGC: collects short-lived objects more aggressively
    -> reduces allocation pressure on large-object GC
    -> fewer allocation stalls
    Note: still experimental in JDK 21, expected GA in JDK 25
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| When to use G1 vs ZGC | 2 minutes |
| MaxGCPauseMillis behavior | 1 minute |
| ZGC allocation stalls | 2 minutes |
| ParallelGC use cases | 1 minute |
| GC change validation process | 2 minutes |
| GC SLA definition | 1 minute |
| Generational ZGC | 2 minutes |

---

**Q1 (g1 vs zgc): When specifically should you switch from G1 to ZGC?**

A: Switch from G1 to ZGC when: (1) P99 GC pause from G1 exceeds the service's latency SLA,
(2) heap is larger than 8GB and G1 pause times are growing with heap size, (3) the service
has sub-10ms P99 latency requirements. Do NOT switch when: G1 already meets the SLA,
CPU budget is too tight for ZGC's concurrent overhead, the application is a batch job
where throughput matters more than pause latency.

*What separates good from great:* The "measure before switching" discipline prevents a
common mistake: teams switch to ZGC because a blog post says it's better, then find
that CPU usage increased 15%, throughput dropped 5%, and P99 latency improved only 5ms
(from 45ms G1 to 40ms ZGC). Not worth it if the P99 SLA was 100ms. The discipline:
always ask "what metric is my SLA?", measure against it, and only make a change if
the current GC violates the SLA.

---

**Q2 (gc validation): What does a proper GC change validation look like?**

A: (1) Baseline: collect GC pause P50/P99/P999, GC overhead %, and application P99 latency
for 1 hour under representative load. (2) Staging: apply the change, run same load profile,
collect same metrics. (3) Compare: did P99 GC pause improve? Did GC overhead change?
Did application P99 latency change? (4) Check side effects: CPU usage, memory usage,
error rate. (5) Canary: deploy to 1% of production, run for 2 hours, monitor all metrics.
(6) Progressive rollout: 10% -> 50% -> 100% if metrics are stable.

*What separates good from great:* The "A/A test" before the "A/B test": before changing
the GC, run two copies of the application with the SAME GC configuration side by side
under the same traffic. Confirm that both produce the same metrics. This validates that
your measurement methodology is sound and there's no confounding variable (e.g., traffic
was lighter during baseline, which would make ANY change look good). Without the A/A test:
you may attribute natural traffic variation to your GC change.

---

**Q3 (parallelgc): What is the use case for ParallelGC in modern Java?**

A: ParallelGC: maximizes GC throughput (fastest garbage collection, all GC threads work
simultaneously). Use cases: (1) batch jobs that process large data sets and don't have
latency SLAs, (2) data pipeline stages that run to completion (not interactive), (3)
services where throughput SLA is "process 1 million records per minute" and individual
request latency is irrelevant, (4) test runners and CI tools where wall clock time for
the full suite matters more than individual test latency.

*What separates good from great:* ParallelGC is explicitly NOT suitable for interactive
services because it has no concurrent phases: the entire GC happens stop-the-world, using
all available GC threads. A 4GB heap with ParallelGC: a full GC can take 0.5-2 seconds.
In a user-facing API: that's a 2-second response time for any request that arrives during
a full GC. For batch jobs running locally (no users waiting): irrelevant. The confusion:
"ParallelGC sounds better because parallel = fast". Correct interpretation: "ParallelGC
is fast at collecting garbage, but stops EVERYTHING to do so." The name refers to
parallel GC threads, not concurrent execution with the application.

---

**Q4 (sla definition): How do you define the GC-related SLA for a service?**

A: GC-related SLA: derived from the application SLA. If the application SLA is "P99 < 50ms":
then GC pauses must be well under 50ms (leaving headroom for application processing time).
Target: GC P99 pause < 20ms for a 50ms application P99 SLA (leaving 30ms for actual work).
GC overhead SLA: typically < 5% (if GC consumes more than 5% of CPU time, it's impacting
throughput). Allocation stall rate: 0 (any allocation stall = unplanned GC-induced delay).

*What separates good from great:* The GC SLA must be defined BEFORE selecting a GC,
not after. The common failure: team selects G1, gets 150ms P99 pause, sets the SLA to
"P99 < 200ms" (making the current behavior acceptable). Correct process: product defines
user-facing SLA (P99 < 50ms). Engineering derives: GC pause budget = SLA - worst-case
application time. This gives the GC selection criterion. If the GC budget is < 10ms:
ZGC is required. If < 100ms: G1 likely works. This flow ensures GC selection is driven
by product requirements, not engineering preferences.

---

**Q5 (workload profiling): How does workload type affect GC selection?**

A: API/interactive service: latency-sensitive, user-facing. GC must meet P99 pause budget
(< 20ms for typical P99 < 100ms API SLAs). G1 (MaxGCPauseMillis=50) or ZGC. Batch/ETL:
throughput-sensitive, processes large data sets to completion. GC pauses acceptable (no
users waiting). ParallelGC for maximum throughput. Streaming (Kafka consumer): continuous
processing, moderate latency. G1 or ZGC depending on throughput/latency balance. Event-driven
(Lambda): short-lived functions. GraalVM native (no JIT warmup, no GC pauses, but no JIT
optimization).

*What separates good from great:* The "spiky" workload is the hardest to size: an API
service that normally handles 100 RPS, but spikes to 1,000 RPS for 5 minutes per day
(e.g., nightly report download). At normal load: heap usage is 2GB, GC is healthy.
During spike: allocation rate 10x, heap fills rapidly, G1 switches to full GC.
Mitigation: (1) pre-provision for peak load (expensive), (2) horizontal autoscaling
(adds pods before memory pressure builds - requires predictive scaling, not reactive),
(3) ZGC with a larger heap (handles spiky allocation better than G1 at the cost of
more memory reserved). The correct answer depends on cost constraints and the magnitude
of the spike.

---

**Q6 (generational zgc): What is Generational ZGC and when should you use it?**

A: Generational ZGC (JDK 21 experimental, -XX:+UseZGC -XX:+ZGenerational): adds a "young"
generation to ZGC. Standard ZGC: non-generational (all objects treated equally). Short-lived
objects collected at the same rate as long-lived objects = inefficient for typical Java
workloads where 80%+ of objects die young. Generational ZGC: frequently collects the
young generation (similar to G1's Young GC), collects old generation concurrently (like
standard ZGC). Result: lower CPU overhead than standard ZGC (young gen collection is
efficient), same sub-ms pauses, better allocation stall resistance.

*What separates good from great:* Generational ZGC is the likely default GC in JDK 25+
(pending finalization). Early benchmarks (JDK 21-23): Generational ZGC outperforms both
non-generational ZGC and G1 on typical server workloads (Spring Boot apps, Kafka consumers).
The combination of G1's generational efficiency + ZGC's sub-ms pauses. The catch: still
experimental (use in staging, not production, until GA in JDK 25). The recommendation
for new services: design for JDK 21 LTS + G1 now, plan to switch to Generational ZGC
when it reaches GA. This means: measure GC overhead and pause times now, have a data
point for the A/B comparison when Generational ZGC is ready.

---

**Q7 (gc tuning): What is the minimum effective GC tuning for each algorithm?**

A: G1 minimum tuning: `-XX:MaxGCPauseMillis=100` (or your pause budget). Heap: `-Xmx`
set to live_data * 2.0. Region size: auto or `-XX:G1HeapRegionSize=16m` for large heaps.
ZGC minimum tuning: just set `-Xmx` to live_data * 2.5 (ZGC needs more headroom). ZGC
is self-tuning otherwise. ParallelGC minimum tuning: `-XX:ParallelGCThreads=N` (match
CPU count). Almost no other tuning needed. Shenandoah: similar to ZGC, minimal tuning.

*What separates good from great:* Over-tuning is a real failure mode. Teams add 20+
GC flags from a tuning guide and get worse performance than the defaults. Why: the JVM's
adaptive sizing algorithms (G1 region selection, ZGC concurrent pacing) are based on
runtime profiling of YOUR workload. Overriding them with static flags: degrades the
adaptive behavior. Minimum viable tuning: set Xmx (required), set MaxGCPauseMillis
(for G1), pick the right algorithm. Monitor metrics. Only add more flags if a specific
metric is out of target. Every added GC flag: document WHY it was added and what metric
it addresses. Flags added "because someone on Stack Overflow said so": remove them.

---

---

## JVM Observability and Monitoring Strategy

### 🎯 Model Answer

**30 seconds:**
> JVM observability: instrument three categories. (1) JVM metrics via Micrometer
> (heap, GC, threads, CPU): the always-on health dashboard. (2) Distributed traces via
> OpenTelemetry: request-level latency breakdown across services. (3) Continuous JFR
> recording: deep JVM internals for incident post-mortems. Together: you can answer
> "is the JVM healthy?" (metrics), "why is THIS request slow?" (traces), and "what was
> the JVM doing during the incident?" (JFR).

**3 minutes (Senior):**
> JVM observability layers:
>
> 1. **Health metrics** (always-on, < 1% overhead): heap used/max, GC pause P99, GC
>    overhead %, threads active, CPU usage, Metaspace used. Collected by Micrometer
>    -> Prometheus -> Grafana. Alerts: GC overhead > 5%, heap > 80% after GC, thread
>    count spike.
>
> 2. **Distributed tracing** (sampled, typically 1-10%): each request gets a trace ID.
>    Spans: across microservices, database queries, HTTP calls. Tools: OpenTelemetry
>    agent (auto-instrument Spring, Hibernate, JDBC, HTTP clients). Identifies: WHICH
>    requests are slow and WHERE (which service, which operation).
>
> 3. **Continuous profiling** (JFR, 1-2% overhead): always-on JFR ring buffer.
>    On incident: dump last 1-2 hours of JFR. Analyze: CPU hotspots, GC detail,
>    allocation rate, lock contention. The "black box recorder" for JVM incidents.
>
> 4. **On-demand investigation** (staging or brief production): heap dump (memory leak),
>    NMT detail (off-heap growth), thread dump analysis (deadlock/contention).

**Blank Mind Recovery:**

**(1) Restate:** "JVM observability: metrics (health dashboard), traces (request-level),
JFR (deep JVM internals). All three required. Metrics: daily monitoring. Traces: slow
request investigation. JFR: incident post-mortem."

**(2) First principles:** "You can't debug what you can't see. JVM is a complex runtime:
many failure modes invisible from the outside. Observability: making internal state
visible without stopping the process. Three views: current health (metrics), request
journey (traces), historical internals (JFR)."

**(3) Bridge:** "JVM observability is like a car's instrumentation. Metrics = dashboard
(speed, fuel, temperature: health at a glance). Traces = GPS track log (route taken,
stops made: what happened during this trip). JFR = black box recorder (everything that
happened: for accident reconstruction)."

---

### 📘 Concept Explanation

**Observability framework for production JVM services:**
```
JVM OBSERVABILITY ARCHITECTURE:

LAYER 1: Metrics (always-on, real-time)
  Tool: Micrometer + Prometheus + Grafana
  Setup: io.micrometer:micrometer-registry-prometheus in pom.xml
         management.endpoints.web.exposure.include=prometheus
         management.metrics.export.prometheus.enabled=true
  
  KEY JVM METRICS:
    jvm.memory.used{area=heap}      <- current heap usage
    jvm.memory.max{area=heap}       <- Xmx (heap limit)
    jvm.gc.pause{action=...}        <- GC pause histogram
    jvm.gc.overhead                 <- % time in GC
    jvm.gc.live.data.size           <- live data post-GC (leak indicator)
    jvm.threads.live                <- active thread count
    jvm.threads.states{state=blocked} <- lock contention indicator
    process.cpu.usage               <- JVM process CPU
    jvm.memory.used{area=nonheap}   <- Metaspace + code cache
    jvm.buffer.memory.used{id=direct} <- direct buffer usage

  ALERT RULES:
    GC overhead: > 5% for 5 min -> warn; > 10% -> critical
    Heap after GC: > 70% -> warn; > 85% -> critical (OOM risk)
    GC pause P99: > 200ms -> warn; > 500ms -> critical
    Thread count: > 200 (or 2x baseline) -> warn (possible thread leak)
    Direct buffer: > 80% MaxDirectMemorySize -> critical

LAYER 2: Distributed Tracing (sampled, request-level)
  Tool: OpenTelemetry Java Agent (zero-code-change instrumentation)
  Start: java -javaagent:opentelemetry-javaagent.jar \
              -Dotel.exporter.otlp.endpoint=http://collector:4317 \
              -jar app.jar
  
  Auto-instrumented: Spring MVC, Spring Boot, JDBC, HTTP clients,
    Kafka producer/consumer, Redis, MongoDB, gRPC, Hibernate
  
  Trace data:
    span.duration: per-operation latency
    db.statement: SQL query (careful: mask sensitive data)
    http.status_code: upstream call result
    exception.type: exception details in span attributes

LAYER 3: Continuous JFR (always-on, incident post-mortem)
  Setup (in JVM flags):
    -XX:StartFlightRecording=name=continuous,\
      settings=default,\
      maxage=2h,\
      maxsize=500m,\
      filename=/var/jfr/continuous.jfr,\
      disk=true
  
  On-demand dump (during or after incident):
    jcmd <pid> JFR.dump name=continuous filename=/tmp/incident.jfr
  
  Analysis:
    jfr print --events jdk.ExecutionSample incident.jfr  <- CPU profile
    jfr print --events jdk.GarbageCollection incident.jfr  <- GC timeline
    jfr print --events jdk.JavaMonitorEnter incident.jfr  <- lock contention
    jfr print --events jdk.ObjectAllocationInNewTLAB incident.jfr  <- allocators
```

---

### 💻 Code Example

> **Code walkthrough:** Custom JFR events allow application-level business metrics to
> be included in the JFR recording alongside JVM-level events. This correlation is
> powerful for post-incident analysis: you can see both "the JVM was in a GC cycle" AND
> "this was during a product import batch" in the same timeline.

```java
// Custom JFR event for application-level observability
// Correlate application events with JVM events in JFR recording

import jdk.jfr.*;

// Define a custom JFR event:
@Label("Database Query Execution")
@Category("Application", "Database")
@Description("Records slow database query executions for JFR analysis")
@StackTrace(true)          // include call stack in event
@Threshold("10 ms")        // only record events longer than 10ms
public class DatabaseQueryEvent extends jdk.jfr.Event {
    @Label("SQL Statement")
    @Sensitive(Relation.NONE) // don't obfuscate in JFR analysis
    public String sql;

    @Label("Row Count")
    public long rowCount;

    @Label("Query Duration Ms")
    public long durationMs;

    @Label("Database Name")
    public String database;
}

// Usage in database layer:
public List<Product> findProducts(String query) {
    DatabaseQueryEvent event = new DatabaseQueryEvent();
    event.begin();  // start timing

    try {
        // Execute the database query:
        List<Product> results = jdbcTemplate.query(
            query, rowMapper);

        event.sql = sanitizeSql(query);     // mask parameters
        event.rowCount = results.size();
        return results;
    } finally {
        event.end();    // stop timing
        event.durationMs = event.getDuration().toMillis();
        event.commit(); // write to JFR ring buffer (only if > threshold)
    }
}

// In post-incident JFR analysis:
// jfr print --events DatabaseQueryEvent /tmp/incident.jfr
// Output shows: which SQL queries ran during the incident
//   correlated with GC pauses and CPU spikes in the same timeline
// This answers: "was the latency spike from slow SQL or from GC pause?"
// Answer: GC pause at 12:34:56.789 (500ms)
//         Slow SQL at 12:34:57.123 (300ms, different root cause)

// Custom metrics with Micrometer:
import io.micrometer.core.instrument.MeterRegistry;
import io.micrometer.core.instrument.Timer;

@Service
public class OrderService {
    private final Timer orderProcessingTimer;
    private final Counter failedOrders;

    public OrderService(MeterRegistry registry) {
        orderProcessingTimer = Timer.builder("order.processing.duration")
            .description("Order processing time")
            .percentiles(0.5, 0.95, 0.99) // P50, P95, P99 in Prometheus
            .register(registry);

        failedOrders = Counter.builder("order.failures")
            .description("Failed order count")
            .register(registry);
    }

    public Order processOrder(OrderRequest req) {
        return orderProcessingTimer.recordCallable(() -> {
            // ... order processing logic ...
        });
    }
}
// Grafana: overlay order.processing.duration P99 with jvm.gc.pause P99
// -> correlation: are order latency spikes caused by GC pauses?
```

> **Code walkthrough:** The correlation pattern (custom JFR events + Micrometer metrics)
> is the key insight. JFR events give microsecond-precision JVM-level detail. Micrometer
> metrics give business-level aggregates. When a P99 latency spike appears in Grafana,
> you can: (1) correlate with GC pause timing (metrics), (2) pull the JFR recording for
> that time window (JFR), (3) look for your custom events to see exactly which operations
> ran during the incident (custom JFR events).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> JVM monitoring: Micrometer (heap, GC, threads) + Prometheus + Grafana. Always enable
> JFR continuous recording (< 2% overhead, invaluable post-incident). Set GC log file
> rotation for persistent GC history. Alert on heap > 80% and GC overhead > 5%.

---

**Senior / Staff (5+ years):**
> JVM observability as a platform concern: standardize across all services. Base image
> includes: Micrometer Prometheus endpoint, OpenTelemetry agent, JFR continuous recording,
> crash capture (hs_err PVC). All services get these automatically. Per-service customization:
> add business-level custom JFR events and Micrometer metrics. The platform handles
> collection infrastructure; services focus on what to instrument, not how to collect.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Prometheus scraping JVM metrics provides enough observability."**
Prometheus metrics: 15-60 second resolution. A 200ms GC pause: invisible in a 15-second
scrape interval (it's averaged). Prometheus is sufficient for: trending (heap growth over
days), coarse alerts (heap > 80%). Insufficient for: diagnosing specific latency spikes
(need JFR millisecond precision), understanding allocation rates (need JFR per-second),
finding hot methods (need JFR CPU samples). Prometheus + JFR: complementary, not
alternatives. Use Prometheus for health dashboards; use JFR for incident analysis.

**Misconception 2: "Adding observability is a separate task after the feature is built."**
Observability added post-hoc: typically incomplete (missing the specific data needed for
production incidents). Observability as a design practice: before implementing a feature,
define what metrics and traces will indicate it's working correctly. Implement alongside
the feature. The specific metrics depend on the business operation: "order processing rate",
"cache hit rate", "payment authorization latency". Generic JVM metrics alone don't tell
you if the business logic is working.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Production incident: service degraded, no useful observability to diagnose.**
```
Scenario: service P99 latency spikes from 50ms to 2000ms
  No JFR running ("we didn't set it up")
  No custom business metrics ("just the default spring actuator")
  GC logs: not configured to write to file
  Thread dumps: not taken during the incident

Investigation options (post-incident):
  All you have: P99 latency timeline in Prometheus (15s resolution)
    -> shows spike started at 14:30:00, resolved at 15:00:00
    -> no other useful data

  What you NEED but don't have:
    - GC pause timing and duration during spike
    - CPU profile during spike (which methods were hot?)
    - Thread states at peak latency (blocked? waiting? running?)
    - Heap state at peak latency
    - Any external call latencies (database, upstream services)

Prevention (to be set up before next incident):
  JVM startup flags:
    -XX:StartFlightRecording=name=continuous,settings=default,\
      maxage=2h,disk=true,filename=/var/jfr/continuous.jfr
    -Xlog:gc*:file=/var/log/gc-%t.log:time:filecount=5,filesize=20m

  Application:
    Add OpenTelemetry agent (distributed traces for every request)
    Add Micrometer custom timers for key business operations
    
  Alerting:
    On GC overhead > 5%: immediate page
    On heap > 80%: warning alert (gives 30-60 min to investigate before OOM)
    On P99 latency > 200ms: warning alert (triggers investigation before SLA breach)

  Incident runbook:
    Step 1: jcmd <pid> JFR.dump name=continuous filename=/tmp/incident_<timestamp>.jfr
    Step 2: kubectl cp <pod>:/tmp/incident_*.jfr ./  (retrieve from pod)
    Step 3: jfr print --events jdk.ExecutionSample,jdk.GarbageCollection incident.jfr
    Step 4: analyze

  Cost: < 2% CPU overhead (JFR continuous) + < 1% (GC logs) = trivial
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| JVM metrics to always monitor | 2 minutes |
| JFR vs APM for profiling | 2 minutes |
| Custom JFR events | 2 minutes |
| Distributed tracing for JVM | 1 minute |
| GC log configuration | 2 minutes |
| Alerting thresholds | 2 minutes |
| Observability in Kubernetes | 2 minutes |

---

**Q1 (essential metrics): What are the minimum JVM metrics every production service must expose?**

A: Minimum: (1) `jvm.memory.used{area=heap}` / `jvm.memory.max{area=heap}` - heap utilization.
(2) `jvm.gc.pause` histogram (P50/P99/max) - GC latency. (3) `jvm.gc.overhead` or
`jvm.gc.memory.allocated` rate - GC activity. (4) `jvm.threads.live` and `jvm.threads.states`
- concurrency health. (5) `process.cpu.usage` - CPU utilization. (6) `jvm.memory.used
{area=nonheap}` - Metaspace health. Standard: use Micrometer with Spring Boot Actuator
(auto-configured with `spring-boot-actuator` + `micrometer-registry-prometheus`).

*What separates good from great:* The "canary metric" for upcoming OOM: `jvm.gc.live.data.size`
(stable = healthy, growing = leak). Alert: if live data grows > 10% over 6 hours = suspect
memory leak. This gives hours of warning before OOM, compared to alerting on heap > 85%
(which gives only minutes). Proactive alerting on live data growth: the hallmark of a
mature observability setup. Reactive alerting on heap > 85%: the minimum viable setup.
The difference: with proactive alerting, you investigate during business hours; with
reactive alerting, you wake up at 3AM to an OOM.

---

**Q2 (jfr setup): How do you set up JFR for production JVM monitoring?**

A: Add to JVM startup flags: `-XX:StartFlightRecording=name=continuous,settings=default,
maxage=2h,maxsize=500m,filename=/var/jfr/continuous.jfr,disk=true`. This creates a
2-hour ring buffer on disk, always-on, < 2% overhead. On incident: `jcmd <pid> JFR.dump
name=continuous filename=/tmp/incident.jfr`. For Kubernetes: mount a PVC at `/var/jfr/`
so JFR survives pod restarts.

*What separates good from great:* JFR event configurations: `settings=default` covers
90% of use cases (CPU samples every 20ms, GC events, class loading, file I/O). The
`profile` configuration: more events, higher overhead (5-10%), use only for short
investigations. Custom event configuration: create a `.jfc` file to enable specific
event categories (e.g., enable `jdk.JavaMonitorEnter` for lock contention analysis,
disabled in default settings). The configuration file: committed to the repository,
documented, available for on-call engineers. This prevents the "I had to figure out
the JFR flags at 3AM during an incident" problem.

---

**Q3 (opentelemetry): What does OpenTelemetry auto-instrumentation provide for JVM services?**

A: OpenTelemetry Java agent: attaches to the JVM via `-javaagent:opentelemetry-javaagent.jar`.
Auto-instruments: all HTTP client calls (headers injection, span creation), Spring MVC
(incoming request spans), JDBC (database query spans with SQL text), Kafka producer/consumer
(message spans with topic/partition), gRPC (bidirectional stream spans), Hibernate (ORM
query spans). Result: complete request traces from entry to external dependencies without
any code changes. Collector: OTLP exporter -> Jaeger or Tempo -> Grafana.

*What separates good from great:* OpenTelemetry baggage propagation: custom key-value
pairs attached to traces and propagated across service boundaries. Use case: propagate
`customer_id` or `tenant_id` in baggage. Every span in the trace: tagged with `customer_id`.
Useful for: diagnosing customer-specific latency issues ("customer 12345 always has high
P99, others don't"). Without baggage: you have traces but can't filter by business entity.
With baggage: `trace.customer_id = 12345` in every span. Grafana Tempo: `{customer_id="12345"}`
query returns all traces for that customer. This is the observability pattern that enables
"debug one customer's experience" in a multi-tenant system.

---

**Q4 (gc logs): How do you configure GC logging for production?**

A: `-Xlog:gc*:file=/var/log/gc.log:time,level,tags:filecount=5,filesize=20m`. This:
enables all GC-related logging (gc*), writes to a rotating file (5 files of 20MB = 100MB
max), with timestamps and log levels. JDK 9+ unified logging: replaces `-verbose:gc`
and `-XX:+PrintGCDetails`. The `filecount=5,filesize=20m` rotation: prevents unbounded
log growth. Key GC log analysis: GC pause duration, pause cause, heap before/after.

*What separates good from great:* GC log rotation timing: each `gc.log` file covers a
time window. For incident analysis: find the file that covers the incident time. `ls -lt
/var/log/gc.log.*` sorts by modification time. The log contains: exact timestamps for
every GC event, pause duration to millisecond precision, heap state before and after.
In Kubernetes: mount a PVC for `/var/log/` (GC logs are ephemeral otherwise). Or: use
a sidecar container that ships GC logs to a central log aggregator (ELK, Loki). Post
shipment: `grep "GC pause" logs | sort -k5 -rn | head -20` finds the 20 longest pauses
in the last week.

---

**Q5 (alerting): What alerting thresholds do you set for JVM health monitoring?**

A: Critical (page immediately): heap > 90% after GC (OOM imminent), GC overhead > 15%
(service severely degraded), JVM process down. Warning (business-hours investigation):
heap > 75% after GC (investigate before growth continues), GC overhead > 5% (GC starting
to impact throughput), thread count > 2x baseline (thread leak suspected), direct buffer
> 80% of MaxDirectMemorySize. Trend alert (no immediate action, schedule investigation):
live data size growing > 10% per hour for > 6 hours (memory leak developing).

*What separates good from great:* Alert fatigue is a real operational risk. Too many
low-urgency alerts: on-call engineers start ignoring alerts. Alert design principles:
(1) every alert must have a runbook entry (what to do when fired); (2) every alert must
be actionable (if you can't do anything about it: it's not an alert, it's a metric to
display on a dashboard); (3) alert on symptoms, not causes (alert on "P99 latency > 200ms",
not on "GC overhead > 3%"; the latter may not cause user-visible impact). The hierarchy:
critical = page now (user impact), warning = investigate soon (risk of user impact),
info = know about it (operational intelligence, not actionable alone).

---

**Q6 (correlation): How do you correlate JVM metrics with application behavior?**

A: Correlation patterns: (1) Grafana: plot `jvm.gc.pause P99` and `http.server.requests P99`
on the same timeline. GC spikes that align with request latency spikes: GC is the cause.
(2) OpenTelemetry trace + JFR: within a trace span that shows high latency, look at the
JFR recording for that same time window (CPU profile, GC events). (3) JFR custom events
+ application events: emit a custom JFR event at the start/end of key business operations.
In the JFR recording: GC events and your business events appear on the same microsecond timeline.

*What separates good from great:* The "correlation gap" between metrics (15-60 second resolution)
and JFR (microsecond resolution): metrics show you WHEN the problem occurred; JFR shows
you WHAT happened. But bridging them requires: accurate timestamps (same NTP source), both
metric and JFR are from the same JVM instance (important in autoscaling environments where
metrics are aggregated across pods). The practice: when a metric alert fires, immediately
dump the JFR recording (`jcmd <pid> JFR.dump`) while the problem may still be ongoing.
The JFR dump includes all data from the last `maxage` period (up to 2 hours). This
preserves the evidence before the 2-hour ring buffer overwrites it.

---

**Q7 (kubernetes observability): What are the unique observability challenges for JVM services in Kubernetes?**

A: (1) Pod ephemeral: JFR files, GC logs, hs_err files lost on pod restart. Solution:
PVC mounts for all crash/log files. (2) Pod IP changes: traces lose pod context. Solution:
OTel resource attributes include pod name, namespace, deployment (env vars injected by
Kubernetes). (3) Horizontal scaling: metrics aggregated across pods can hide individual
pod issues (one pod leaking memory: heap average looks OK). Solution: per-pod metrics
(Prometheus `instance` label), per-pod dashboards. (4) Metrics cardinality: don't label
metrics with request-specific data (path parameters): explosion in time series.

*What separates good from great:* The "pod name" in metrics: each Prometheus scrape
includes `instance` label (pod IP:port). In Grafana: filter to a specific pod to isolate
a single JVM's behavior. Without per-pod filtering: a memory leak in one pod is masked
by healthy pods in the aggregate. Useful Kubernetes-specific JVM metrics: `jvm.memory.used`
with `pod_name` label -> can identify the specific pod with the leak. Kubernetes also
provides: `container_memory_rss` (actual RSS from cgroup, includes all JVM memory
regions). Correlate `container_memory_rss` with `jvm.memory.used{heap}` to measure
off-heap overhead: `rss - heap_used = off_heap_overhead`. This is the fastest way to
estimate total off-heap consumption without running NMT.

---

### ⚖️ Comparison Table

*(Omit: META Patterns files (★☆☆) - explicit omit as per spec rules. The comparison
between observability tools (JFR, APM, metrics) is covered within the Q&A section
rather than a summary table format.)*

---

### 🏛️ System Design

*(Omit: META Patterns files focus on transferable thinking patterns and mental models.
System-level observability architecture is covered in the Q&A deep-dive and code examples,
providing practical patterns without requiring a separate system design section.)*

---

### 📊 Diagram

*(Omit: The mental model and decision frameworks in this META file are better expressed
through the structured text content (decision trees, priority lists, checklists)
and the code examples than through visual diagrams. The code examples contain embedded
ASCII decision trees that serve the same purpose.)*
