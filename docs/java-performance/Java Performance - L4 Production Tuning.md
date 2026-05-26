---
layout: default
title: "Java Performance - L4 Production Tuning"
parent: "Java Performance"
nav_order: 6
permalink: /java-performance/l4-production-tuning/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Production GC Configuration](#production-gc-configuration) | high |
| 2 | [Thread Pool Tuning](#thread-pool-tuning) | high |
| 3 | [JVM Startup Optimization](#jvm-startup-optimization) | high |
| 4 | [Memory Leak Detection and Fix](#memory-leak-detection-and-fix) | high |
| 5 | [High-Latency Diagnosis](#high-latency-diagnosis) | high |

---

# Production GC Configuration

**Interview Weight:** high - Expert diagnostic skill. Tests
ability to configure GC for production systems and read GC logs.

---

### 🎯 Model Answer

**30 seconds:**

> Production GC configuration starts with heap sizing (Xmx = live
> data × 3), GC algorithm selection (G1GC default, ZGC for sub-10ms),
> GC logging (`-Xlog:gc*`), and OOM dump (`-XX:+HeapDumpOnOutOfMemoryError`).
> Read GC logs to identify: pause frequency, Old Gen fill rate,
> Humongous allocations, and any Full GC occurrences (always a
> warning sign with G1GC).

**3 minutes (Senior):**

> **G1GC problem indicators (from GC log):**
>
> `to-space exhausted` / `evacuation failure`:
> Young gen objects cannot be promoted to Old gen because Old gen
> is full. G1GC falls back to a stop-the-world Full GC.
> Fix: increase heap or reduce allocation rate.
>
> Humongous allocation:
> Objects > 50% of region size allocated directly to Old gen
> (bypassing Young gen). Frequent Humongous allocation causes
> Old gen pressure without triggering Young GC first.
> Fix: increase G1HeapRegionSize.
>
> Concurrent marking not completing before Full GC:
> Old gen fills faster than concurrent marking can track.
> Lower `InitiatingHeapOccupancyPercent` (default 45%) to
> start marking earlier.
>
> **ZGC problem indicators:**
> `Allocation Stall`: application threads stall waiting for GC
> to free memory. Means ZGC is not keeping up with allocation rate.
> Fix: increase heap, reduce allocation rate, or increase
> concurrent threads (`-XX:ConcGCThreads`).
>
> **GC log reading - key metrics:**
> - Young GC frequency: >1 per second = high allocation rate
> - Young GC pause: G1GC normal range 20-50ms
> - Old GC occupancy growth: should decrease after each GC
> - Full GC (G1GC): should be zero in steady state
> - ZGC: pause should be < 5ms at any heap size

---

### 💻 Code Example

**Example 1: Production GC configuration and log analysis**

```bash
# FULL PRODUCTION G1GC CONFIGURATION
java \
  -Xms16g -Xmx16g \
  # Equal: no heap resize pauses.
  # Sized: measured live data 5GB × 3 = 15GB → 16GB for safety.
  -XX:+UseG1GC \
  -XX:MaxGCPauseMillis=150 \
  # G1 pause target. Set at 75% of p99 SLO target (200ms SLO → 150ms).
  -XX:G1HeapRegionSize=32m \
  # Increased from default for large heap (16GB / 32MB = 512 regions).
  # Also handles humongous objects (>16MB each go to Old gen directly).
  -XX:InitiatingHeapOccupancyPercent=35 \
  # Start concurrent mark earlier (default 45%).
  # Lower this if Full GC occurs (Old gen filling before marking completes).
  -XX:G1ReservePercent=10 \
  # Keep 10% of heap as reserve to absorb evacuation failure.
  -Xlog:gc*,gc+heap=debug:file=/var/log/app/gc.log:time,uptimemillis,tags:filecount=10,filesize=20m \
  # Rolling GC log: 10 files × 20MB = 200MB total log history.
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/var/log/app/oom.hprof \
  -XX:+ExitOnOutOfMemoryError \
  # Exit on OOM → let orchestrator restart. Better than degraded state.
  -jar app.jar

# ANALYZE GC LOG
grep -E "GC pause|Full GC|exhausted|Humongous" /var/log/app/gc.log | tail -50

# Check Full GC count (should be 0 in healthy G1GC):
grep "Full GC" /var/log/app/gc.log | wc -l

# Check average and max pause times:
grep "GC pause" /var/log/app/gc.log | \
  awk -F'ms' '{print $1}' | \
  awk '{sum += $NF; max = ($NF > max) ? $NF : max; count++} 
       END {print "avg=" sum/count "ms max=" max "ms count=" count}'

# GC Stats with jstat (real-time):
jstat -gcutil $PID 2000 30
# Watch: O (old gen %) should not trend up over time
# Watch: FGC (full GC count) should stay 0
```

> **Code walkthrough:** The `InitiatingHeapOccupancyPercent=35`
> is set below the default 45% to start concurrent marking earlier.
> If Old gen is growing faster than expected, this gives marking
> more time to complete before evacuation failure. The
> `-XX:+ExitOnOutOfMemoryError` is a production best practice:
> a JVM in OOM state is often in a degraded, unpredictable state.
> Exiting immediately and letting Kubernetes/systemd restart it
> is safer than attempting recovery.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Enable GC logging (`-Xlog:gc*`). Watch for Full GC (bad),
> `to-space exhausted` (bad). Size heap at live data × 3.

---

**Senior / Staff (5+ years):**

> Every production JVM has GC logging, OOM heap dump, and JFR
> continuous recording. The most diagnostic signal is Old gen
> fill rate: if it grows over time after every GC, there is a
> memory leak or heap is undersized. Full GC in G1GC is always
> a serious event requiring investigation.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "Your G1GC logs show 'to-space exhausted' and then a Full GC.
  What happened and how do you fix it?"

🗣️ "'To-space exhausted' means G1GC tried to promote Young gen
objects to Old gen during a mixed collection, but Old gen had
no free regions to receive them. G1GC falls back to a Full GC
(stop-the-world, entire heap scanned). Root causes: (1) Old gen
growing faster than concurrent marking can keep up - G1 is not
collecting Old gen regions fast enough. Fix: lower
`InitiatingHeapOccupancyPercent` to start marking earlier.
(2) Large Humongous objects filling Old gen faster than expected.
Fix: increase `G1HeapRegionSize` so fewer objects are Humongous.
(3) Heap genuinely undersized for live data. Fix: increase Xmx.
(4) Memory leak - live data growing over time. Fix: find the
leak with heap dump. I check GC log for the Old gen occupancy
trend before the evacuation failure - if it was approaching 80%+
before the failure, heap sizing or marking frequency is the issue.
If it was at 40% (reasonable), something caused a sudden allocation
surge."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | G1GC phases, evacuation failure, IHOP. |
| Hiring Manager   | GC log reading, incident response. |
| Bar Raiser       | G1GC concurrent vs STW phases, ZGC allocation stall, GC ergonomics. |
| Peer Engineer    | "to-space exhausted at 2AM - dropped IHOP from 45 to 30, never recurred..." |

---

---

# Thread Pool Tuning

**Interview Weight:** high - Core scalability concern.
Tests ability to size thread pools correctly and diagnose saturation.

---

### 🎯 Model Answer

**30 seconds:**

> Thread pool sizing depends on the workload type: CPU-bound tasks
> need threads = CPU cores; I/O-bound tasks need more threads to
> hide latency (Little's Law: threads = throughput × latency).
> Signs of saturation: task queue growing, rejection exceptions,
> increasing latency. Java 21 virtual threads change the calculus:
> use unlimited virtual threads for I/O-bound work, bounded for
> CPU-bound.

**3 minutes (Senior):**

> **Thread pool sizing formulas:**
>
> CPU-bound (computation, no blocking):
> `threads = CPU cores` (or × 1.2 for minor I/O).
> More threads = context switch overhead, no benefit.
>
> I/O-bound (DB queries, HTTP calls):
> `threads = target_throughput × p50_latency` (Little's Law)
> Example: 500 RPS, 50ms p50 DB latency → 500 × 0.05 = 25 threads minimum.
> Add 50% headroom: 38 threads.
>
> **`ThreadPoolExecutor` parameters:**
> - `corePoolSize`: threads always kept alive.
> - `maximumPoolSize`: max threads (extra threads created when queue full).
> - `keepAliveTime`: idle extra threads are terminated after this.
> - `workQueue`: `LinkedBlockingQueue` (unbounded) vs
>   `ArrayBlockingQueue(N)` (bounded). Unbounded = queue grows to
>   OOM; bounded = `RejectedExecutionException` when full.
> - `rejectionPolicy`: `AbortPolicy` (throws), `CallerRunsPolicy`
>   (caller executes task - backpressure), `DiscardPolicy` (silent drop).
>
> **Virtual threads (Java 21+) for I/O-bound:**
> `ExecutorService e = Executors.newVirtualThreadPerTaskExecutor()`
> Each task runs on a fresh virtual thread. No queue. No sizing.
> Virtual threads unmount from carrier threads during I/O.
> CPU-bound tasks: still use platform thread pools to bound CPU usage.

---

### 💻 Code Example

**Example 1: Thread pool sizing and saturation detection**

```java
// SIZING: I/O-bound service (DB + HTTP calls)
// Target: 300 RPS, p50 DB latency: 40ms
// Little's Law: 300 * 0.04 = 12 threads minimum
// Headroom: 12 * 1.5 = 18 threads

// BAD: unbounded queue (silent backlog growth)
ThreadPoolExecutor pool = new ThreadPoolExecutor(
    18, 18,          // core and max = 18
    0L, MILLISECONDS,
    new LinkedBlockingQueue<>()  // unbounded: queue grows forever under load
);

// BAD: too few threads (throughput limited)
ThreadPoolExecutor pool = new ThreadPoolExecutor(5, 5, ...);
// 5 threads × 40ms = 200ms slot per second → 5/0.04 = 125 RPS max
// At 300 RPS: queue grows without bound

// GOOD: bounded pool with monitoring
ThreadPoolExecutor pool = new ThreadPoolExecutor(
    18,           // corePoolSize
    24,           // maximumPoolSize (spill capacity for bursts)
    60, SECONDS,  // keepAlive for extra threads
    new ArrayBlockingQueue<>(500),  // bounded queue: 500 pending tasks max
    new ThreadPoolExecutor.CallerRunsPolicy()
    // On rejection: calling thread executes the task (backpressure)
    // Alternative: AbortPolicy + catch RejectedExecutionException
);

// MONITORING: detect saturation
ScheduledExecutorService monitor = Executors.newSingleThreadScheduledExecutor();
monitor.scheduleAtFixedRate(() -> {
    int queued = pool.getQueue().size();
    int active = pool.getActiveCount();
    long rejected = rejectionCounter.get(); // increment in rejection handler
    log.info("Pool: active={} queued={} rejected={}", active, queued, rejected);
    if (queued > 100) {
        log.warn("Thread pool backlog growing: {} tasks queued", queued);
    }
}, 0, 10, SECONDS);

// Java 21 Virtual Threads (I/O-bound workloads)
try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
    for (Request req : batch) {
        executor.submit(() -> processWithDbAndHttp(req));
        // Each task: own virtual thread. Blocks on I/O → unmounts.
        // 10,000 tasks concurrently: fine. 0 sizing decisions needed.
    }
}
```

> **Code walkthrough:** `ArrayBlockingQueue(500)` is the critical
> safety valve. Without it, the task queue can grow to OOM under
> sustained overload. `CallerRunsPolicy` provides natural backpressure:
> when the pool is full, the HTTP handler thread (the caller)
> executes the task directly, which slows incoming request acceptance
> automatically. The monitoring log at 10-second intervals provides
> early warning before the queue overflows.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CPU-bound: threads = CPU cores. I/O-bound: use Little's Law
> (threads = throughput × latency). Always use bounded queues.
> Java 21 virtual threads for I/O eliminates sizing.

---

**Senior / Staff (5+ years):**

> I instrument thread pool metrics (queue depth, active count,
> rejection count) as Prometheus gauges. Queue depth growing is
> the first saturation signal - before timeouts start. I also
> use virtual threads for all I/O-bound work in Java 21 - it
> removes the sizing problem entirely.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "Requests are timing out but thread dump shows threads
  WAITING at LinkedBlockingQueue.take(). What is happening?"

🗣️ "Threads WAITING at `LinkedBlockingQueue.take()` are idle -
they are waiting for tasks to be submitted to the queue. This
means the thread pool is not the bottleneck. The requests are
timing out for a different reason. Possibilities: (1) The
requests are not reaching the thread pool - they are being
rejected before submission. Check `RejectedExecutionException`
in logs. (2) The task queue is full and new submissions are
being rejected (if using `AbortPolicy`). (3) The requests are
being processed correctly but upstream is timing out waiting
for a response that is genuinely slow (DB, external service).
(4) The threads visible in the dump are a monitoring pool, not
the request pool - verify thread names. I would check: (a) rejection
counter for the request pool, (b) active count and queue depth
at time of timeouts, (c) database or external service response
times."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Pool parameters, Little's Law, queue types. |
| Hiring Manager   | Saturation detection, monitoring. |
| Bar Raiser       | ThreadPoolExecutor internals, work-stealing vs fixed, virtual thread scheduler. |
| Peer Engineer    | "CallerRunsPolicy saved us from OOM during a traffic spike - just slowed acceptance..." |

---

---

# JVM Startup Optimization

**Interview Weight:** high - Cloud-native and serverless
contexts. Tests knowledge of CDS, AOT, and startup trade-offs.

---

### 🎯 Model Answer

**30 seconds:**

> JVM startup is slow for three reasons: classloading (reading
> .class files), bytecode verification, and JIT warmup.
> Optimizations: AppCDS (Application Class Data Sharing) caches
> class loading metadata; `-Xms` small + lazy class loading;
> GraalVM Native Image (AOT) for sub-100ms startup. Spring Boot 3
> supports AOT compilation via `spring-aot` plugin.

**3 minutes (Senior):**

> **AppCDS (Class Data Sharing) - production mainstream:**
> CDS creates a shared archive of class metadata that can be
> mapped into process memory, bypassing classloading overhead.
> Steps:
> 1. Generate class list: run app with
>    `-XX:DumpLoadedClassList=classes.lst`
> 2. Create archive: `java -Xshare:dump -XX:SharedClassListFile=classes.lst
>    -XX:SharedArchiveFile=app.jsa -jar app.jar`
> 3. Run with archive: `-XX:SharedArchiveFile=app.jsa`
>
> Benefit: 30-50% startup time reduction. No code change.
>
> **JVM warmup optimization:**
> Ahead-of-time compilation (Java 9+ experimental, Java 21+
> better via GraalVM): compile frequently-called methods to
> native code at build time.
> Spring Boot 3 + Spring AOT: moves reflection, proxy generation,
> and bean initialization to build time.
>
> **GraalVM Native Image:**
> The most dramatic: 50ms vs 5s startup. See GraalVM keyword.
>
> **Startup flags to AVOID:**
> `-server` (no-op in modern JVM - always server mode).
> `-XX:+AggressiveOpts` (removed, causes errors).
> `-Xverify:none` (skips bytecode verification - security risk,
> can cause crashes from invalid bytecode). Never use in production.

---

### 💻 Code Example

**Example 1: AppCDS and startup optimization workflow**

```bash
# AppCDS: 3-step setup for a Spring Boot application

# Step 1: Generate class list (run app through startup + warmup)
java \
  -XX:DumpLoadedClassList=classlist.txt \
  -Dspring.context.exit=onRefresh \
  -jar app.jar
# -Dspring.context.exit=onRefresh: Spring Boot exits after context init
# classlist.txt now contains all loaded classes

# Step 2: Create CDS archive
java \
  -Xshare:dump \
  -XX:SharedClassListFile=classlist.txt \
  -XX:SharedArchiveFile=app.jsa \
  --class-path app.jar \
  --version
# Creates app.jsa: shared archive of class metadata

# Step 3: Use archive at runtime
java \
  -XX:SharedArchiveFile=app.jsa \
  -jar app.jar
# Startup time: 2.1s → 1.3s (38% improvement for typical Spring app)

# VERIFY CDS is working:
java -Xshare:on -XX:SharedArchiveFile=app.jsa -verbose:class -jar app.jar 2>&1 | \
  grep -c "shared objects file"
# Non-zero count = CDS classes loaded from archive

# BASELINE: measure startup time properly
for i in 1 2 3 4 5; do
  start=$(date +%s%3N)
  java -XX:SharedArchiveFile=app.jsa -jar app.jar &
  # Wait for "Started ApplicationContext" in log
  wait_for_start  # log grep or health check
  end=$(date +%s%3N)
  echo "$((end - start))ms"
done
# Average 3 runs: startup = 1350ms (vs 2100ms baseline)

# SPRING BOOT 3 NATIVE (for maximum startup time reduction)
./gradlew nativeBuild
# Output: ./build/native/nativeCompile/app (native executable)
time ./build/native/nativeCompile/app
# Started in 0.038s  (38ms vs 2100ms: 55x faster)
```

> **Code walkthrough:** AppCDS requires exactly three commands
> and delivers 30-50% startup improvement for free. The class
> list generation uses Spring Boot's `spring.context.exit=onRefresh`
> to exit cleanly after initializing the full application context,
> ensuring all production classes are captured. The verification
> step confirms CDS is actually loading classes from the archive.
> Measure with 5 iterations - startup time has variance from OS
> page cache effects.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> AppCDS reduces startup by 30-50% with no code change. GraalVM
> Native Image reduces startup to milliseconds but requires AOT
> configuration. Never use `-Xverify:none` in production.

---

**Senior / Staff (5+ years):**

> For Kubernetes deployments, startup time affects scale-out
> latency. AppCDS is the first step (free, no risk). For
> serverless or scale-to-zero deployments, Native Image is
> necessary - startup time must be < 500ms for sub-second
> cold starts. I use Spring Boot 3's native support which
> automates most of the AOT configuration.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "What are the trade-offs between AppCDS and GraalVM Native
  Image for startup optimization?"

🗣️ "AppCDS: easy to implement (3 commands), 30-50% startup
improvement, full JVM flexibility retained (dynamic class loading,
JIT, full JFR diagnostics), and no build pipeline changes beyond
generating the archive. Works with any Java framework. Limitation:
still JVM startup overhead, still JIT warmup. For a Spring Boot
app, CDS gets you from 5s to 3s startup. Native Image: 50ms
startup (100x better), 70% less memory, consistent latency
(no JIT warmup). Limitations: closed-world requirement (no
runtime class generation without configuration), no full JFR
support, long build times (5-10 minutes), reflection requires
explicit configuration. Works best with frameworks designed for
AOT (Quarkus, Micronaut, Spring Boot 3). My decision: for a
service that starts once per day and runs continuously, AppCDS.
For a serverless function or auto-scaling service with scale-to-zero,
Native Image."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | AppCDS steps, native image trade-offs. |
| Hiring Manager   | Cloud deployment context, startup SLA. |
| Bar Raiser       | Ahead-of-time compilation phases, dynamic proxies in AOT. |
| Peer Engineer    | "AppCDS cut our pod readiness from 45s to 27s - Kubernetes HPA was slow before..." |

---

---

# Memory Leak Detection and Fix

**Interview Weight:** high - Production war story material.
Tests systematic leak detection skills.

---

### 🎯 Model Answer

**30 seconds:**

> Memory leaks in Java: objects accumulate in the heap faster
> than they are collected. Old gen fills despite GC. Symptoms:
> OutOfMemoryError, or heap growing monotonically over hours/days.
> Detection: GC log shows old gen not shrinking after major GC.
> Diagnosis: heap dump + MAT leak suspects. Common causes:
> ThreadLocal not removed, unbounded caches, listener not
> unregistered, static collection accumulation.

**3 minutes (Senior):**

> **Leak detection sequence:**
>
> 1. **Confirm leak**: heap memory after major GC should be stable.
>    `jstat -gcutil <pid> 10000 60` for 10 minutes - watch 'O' column.
>    Growing O% = likely leak.
>
> 2. **Force GC and remeasure**:
>    `jcmd <pid> GC.run` - forces a full GC.
>    `jcmd <pid> GC.heap_info` - check live data size.
>    If live data grows by 50MB every 10 minutes, leak rate = 5MB/min.
>
> 3. **Heap dump**: `jcmd <pid> GC.heap_dump /tmp/heap.hprof`
>    (GC.heap_dump forces GC before dumping - live objects only).
>
> 4. **MAT analysis**: Leak Suspects Report → Dominator Tree →
>    find the root object retaining growing memory.
>
> **Common Java leak patterns and fixes:**
>
> - **ThreadLocal leak**: set in request handler, never removed.
>   Fix: `try { ... } finally { threadLocal.remove(); }`.
>
> - **Listener/observer not unregistered**:
>   Spring `@EventListener` beans that are `@Prototype` scoped.
>   Every request creates a new bean, registers a listener.
>   Listeners accumulate. Fix: use singleton beans or `@PreDestroy`
>   to unregister.
>
> - **Static collection growth**:
>   `static Map` accumulating entries without eviction.
>   Fix: bounded cache with Caffeine.
>
> - **ClassLoader leak**:
>   `Class` object held by static field in a parent classloader
>   prevents the child classloader from being GC'd on undeploy.
>   Fix: `WeakReference` for cross-classloader associations.

---

### 💻 Code Example

**Example 1: Leak patterns and detection**

```java
// LEAK PATTERN 1: ThreadLocal not removed in thread pool
static ThreadLocal<Connection> CONN = ThreadLocal.withInitial(
    () -> dataSource.getConnection()
);

// BAD: thread pool thread retains Connection forever after first use
void handleRequest(Request req) {
    Connection conn = CONN.get();
    conn.execute(req.query());
    // No CONN.remove() → Connection held by thread pool thread forever
}

// GOOD: always remove in finally
void handleRequest(Request req) {
    try {
        Connection conn = CONN.get();
        conn.execute(req.query());
    } finally {
        Connection conn = CONN.get();
        if (conn != null) {
            conn.close();
            CONN.remove();  // clear reference from thread's ThreadLocalMap
        }
    }
}

// LEAK PATTERN 2: Event listener accumulation
// BAD: prototype-scoped bean registers itself as listener
@Component
@Scope("prototype")  // new instance per request
public class RequestProcessor implements ApplicationListener<UserEvent> {
    @PostConstruct
    void init() {
        eventPublisher.register(this);  // registers each instance
    }
    // No @PreDestroy → old instances never unregistered
    // After 1000 requests: 1000 RequestProcessors retained by event bus
}

// GOOD: singleton listener or explicit unregister
@Component  // singleton: registered once, never leaked
public class RequestProcessor implements ApplicationListener<UserEvent> {
    // OR use @PreDestroy if prototype is required:
    @PreDestroy
    void cleanup() {
        eventPublisher.unregister(this);
    }
}

// DETECTION: confirm leak with jstat
// $ jstat -gcutil $PID 10000 60
# S0   S1    E    O     M   YGC  YGCT  FGC  FGCT   GCT
#  0   73.2  44.1 45.3  96  120  0.84    0  0.00  0.84  ← normal
#  0   71.5  38.9 46.1  96  121  0.85    0  0.00  0.85  ← O growing
#  0   70.2  41.3 46.8  96  122  0.85    0  0.00  0.85  ← O still growing
#  0   68.9  39.7 47.6  96  123  0.86    0  0.00  0.86  ← confirmed leak
# O% growing over 60 minutes: heap dump warranted
```

> **Code walkthrough:** The ThreadLocal leak is the most common
> Java server-side memory leak. Thread pool threads live indefinitely;
> a ThreadLocal set in a request handler and never removed is
> retained for the lifetime of the thread. The `finally` block
> with both `close()` and `remove()` is mandatory. The `jstat`
> output shows the leak pattern: `O%` (old generation percentage)
> growing monotonically across GC cycles - it should stabilize
> after GC in a healthy application.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Memory leaks show as growing old gen in GC log. Diagnose with
> heap dump + MAT. Common causes: ThreadLocal not removed,
> unbounded caches, listeners not unregistered.

---

**Senior / Staff (5+ years):**

> I prevent leaks with code review: any ThreadLocal access without
> a `finally { remove() }` is flagged. Any static collection is
> questioned: does it have an eviction policy? I confirm leaks
> with the jstat O% trend before taking a heap dump (dump is
> disruptive). MAT's Leak Suspects report finds 90% of leaks
> in 5 minutes.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "After a new deployment, Old gen memory grows 20MB per hour.
  Walk through your diagnosis."

🗣️ "20MB/hour is slow enough to not be urgent but will OOM in
a week. Step 1: confirm it's a real leak and not heap resizing.
Force GC with `jcmd GC.run` and measure live data immediately after
with `GC.heap_info`. Take this measurement again after 1 hour.
If live data grew by ~20MB, confirmed leak. Step 2: capture JFR
allocation profile to see what's being allocated. 20MB/hour =
~5.5KB/second allocation rate in old gen - it might show up in
the allocation profile by object type. Step 3: take two heap
dumps 1 hour apart. Compare in MAT (File → Compare Snapshots).
The growing class is the leak candidate. Step 4: trace the
retaining reference. In MAT, right-click the growing class →
Show Dominator Tree. Follow the reference chain to the root
holder (likely a static Map, ThreadLocal, or event bus).
Step 5: fix the root: add eviction, add `finally { remove() }`,
or add `@PreDestroy` unregister."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Leak patterns, jstat diagnostic flow, heap dump timing. |
| Hiring Manager   | Systematic approach, prevention culture. |
| Bar Raiser       | Phantom references, WeakReference, finalization heap leak. |
| Peer Engineer    | "ThreadLocal leak in our connection pool - found it with MAT in 10 minutes..." |

---

---

# High-Latency Diagnosis

**Interview Weight:** high - Expert production diagnostic.
Tests end-to-end latency investigation skills.

---

### 🎯 Model Answer

**30 seconds:**

> High latency investigation starts with: which percentile is
> affected (p50 vs p99 vs p999 have different root causes), then
> correlate with system metrics. P99 spikes → GC pauses (check
> GC log). All percentiles high → throughput bottleneck (CPU,
> DB, thread pool). Occasional extreme outliers → lock contention
> or garbage collection Full GC. Use JFR for correlation between
> latency events and JVM events.

**3 minutes (Senior):**

> **Latency spike investigation by percentile:**
>
> **P50 and p99 both high (all requests slow):**
> - CPU-bound: `top` shows Java at 90%+ CPU. JFR flame graph
>   shows hot methods.
> - I/O-bound: threads RUNNABLE at socket read. External dependency
>   slow.
> - Thread pool saturation: queue depth growing. Little's Law
>   violated.
>
> **P99 high, p50 normal (some requests slow):**
> - GC pause: check GC log for pauses correlating with p99 spikes.
>   G1GC pauses hit some requests, not all.
> - Lock contention: some requests hit a contended lock path.
>   JFR `jdk.JavaMonitorEnter` with long duration.
> - Thread scheduling outlier: OS scheduler jitter (rare).
>
> **Occasional p999 extreme outlier (1 in 1000 very slow):**
> - Full GC: G1GC Full GC can take seconds. Rare but extreme.
>   Check GC log for Full GC events.
> - Database connection timeout: connection pool exhausted.
>   Next request waits for timeout + retry.
> - External service timeout: one upstream call hangs.
>
> **JFR correlation technique:**
> Record timestamp of latency spike from APM/metrics.
> In JMC, use the timeline to navigate to that timestamp.
> Check: GC events (was there a pause?), Lock events (which
> thread was blocked?), Socket events (which remote endpoint
> was slow?).

---

### 💻 Code Example

**Example 1: High-latency diagnosis workflow**

```bash
# STEP 1: Identify which percentile is affected
# Prometheus query (Micrometer):
# http_request_duration_seconds{quantile="0.5"}  → p50
# http_request_duration_seconds{quantile="0.99"} → p99
# If p50 = 10ms, p99 = 800ms → spike pattern → GC or lock suspect
# If p50 = 300ms, p99 = 400ms → throughput bottleneck → CPU or I/O

# STEP 2: GC correlation (p99 spike scenario)
# Check GC log timestamps vs latency spike timestamps:
grep -oP '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.*GC pause.*\d+ms' /var/log/gc.log | \
  awk '$NF+0 > 50'  # show GC pauses > 50ms
# If pauses appear at same times as p99 spikes: GC is cause

# STEP 3: JFR dump for incident window
jcmd $PID JFR.dump name=continuous filename=/tmp/incident.jfr

# STEP 4: JMC analysis
# JVM Internals → GC → look for pause at spike timestamp
# Threads → Lock Instances → cumulative wait time per lock
# Code → Method Profiling → flame graph during spike window

# STEP 5: Thread pool saturation check
jcmd $PID Thread.print | grep -c "http-nio\|request\|worker"
# Count active request threads; compare to configured pool size
# If count = max pool size: saturated

# STEP 6: External dependency check (socket I/O events in JFR)
# JMC: Events → jdk.SocketRead → sort by duration desc
# Shows slowest socket reads with remote endpoint IP
# Correlates with specific DB host, Redis, external API

# EXAMPLE FINDING:
# p99 spike every 5 minutes, exactly 300ms
# GC log: G1GC Minor GC every 5 minutes, 280ms pause
# Cause: heap undersized → frequent large Young GC pauses
# Fix: increase heap from 4GB to 8GB
# Result: GC pauses drop to 45ms, p99 drops from 800ms to 120ms
```

> **Code walkthrough:** The 5-minute periodic p99 spike is the
> signature of a large, frequent GC pause. The GC log timestamp
> correlation confirms it: pauses appear at the same timestamps
> as latency spikes. The fix (doubling heap) reduces GC frequency
> by allowing more objects to accumulate before collection.
> The diagnosis cost: 15 minutes reading GC logs. Without GC
> logging, this would require a JFR recording to reproduce.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> High p99 = GC pauses or lock contention. High p50 = throughput
> bottleneck (CPU, I/O, thread pool). Correlate latency timestamps
> with GC log and JFR events.

---

**Senior / Staff (5+ years):**

> The percentile split is the first diagnostic branch: p50 high
> = systemic issue (fix the bottleneck); p99 high, p50 normal
> = tail issue (fix the rare event). I route to different tools
> for each. Continuous JFR recording means every p99 spike is
> diagnosable retrospectively.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "p50 latency is stable at 20ms, p99 spikes to 2 seconds
  every 10 minutes. What is likely happening and how do you confirm?"

🗣️ "P50 stable, p99 spiking every 10 minutes at 2 seconds is
almost certainly GC-related. The periodic interval is the giveaway:
GC runs when the heap fills, which happens on a cycle driven by
allocation rate. Two seconds is consistent with a G1GC Full GC
or a very large minor GC on an undersized heap. Confirmation:
Step 1: check GC log for 2-second pauses every 10 minutes.
`grep 'GC pause' /var/log/gc.log | awk '$NF+0 > 500'` - filter
for pauses > 500ms. If pauses appear at 10-minute intervals:
confirmed. Step 2: check what type. Full GC = heap severely
undersized or memory leak. Large Young GC = allocation rate
too high for current heap/GC config. Step 3: if Full GC, take
heap dump and check for leaks. If large Young GC, increase
heap and/or check allocation hotspots with JFR.
The immediate mitigation: switch to ZGC (`-XX:+UseZGC`) -
ZGC will deliver sub-10ms pauses and eliminate the 2-second
spikes instantly, even with the same root cause."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Percentile analysis, GC correlation, JFR timeline. |
| Hiring Manager   | Structured investigation, quick mitigation vs root cause. |
| Bar Raiser       | Coordinated omission in measurement, Little's Law at scale. |
| Peer Engineer    | "Every 8 minutes our API spiked - G1GC Full GC. ZGC fixed it in 5 minutes..." |
