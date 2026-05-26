---
layout: default
title: "Java Performance - L2 Profiling Tools"
parent: "Java Performance"
nav_order: 3
permalink: /java-performance/l2-profiling-tools/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Flight Recorder](#java-flight-recorder) | high |
| 2 | [Java Mission Control](#java-mission-control) | high |
| 3 | [VisualVM and JConsole](#visualvm-and-jconsole) | medium |
| 4 | [Async-Profiler](#async-profiler) | high |
| 5 | [Heap Dump Analysis](#heap-dump-analysis) | high |

---

# Java Flight Recorder

**Interview Weight:** high - The standard production-safe
JVM profiler. Tests knowledge of JFR capabilities, event types,
and operational usage.

---

### 🎯 Model Answer

**30 seconds:**

> Java Flight Recorder (JFR) is a built-in, always-on, low-overhead
> (~1%) profiling framework in HotSpot. It records JVM events:
> GC, JIT compilation, thread activity, lock contention, memory
> allocation, and I/O. Available in OpenJDK 11+ without commercial
> license. Enabled at startup with `-XX:StartFlightRecording` or
> dynamically with `jcmd JFR.start`. Analyzed with Java Mission
> Control. Key advantage: production-safe and always available.

**3 minutes (Senior):**

> **JFR architecture:**
> JFR uses a ring buffer in direct memory. Event data is written
> lock-free using pre-allocated memory. No heap allocation per
> event. No safepoint needed for most events. The ring buffer is
> periodically flushed to disk (or on demand).
>
> **JFR event categories (essential knowledge):**
> - `jdk.GarbageCollection`: duration, cause, heap before/after.
> - `jdk.ExecutionSample`: CPU sampling at ~10ms intervals
>   (enabled with `settings=profile`).
> - `jdk.ObjectAllocationInNewTLAB`: allocation hotspots with
>   stack trace. Samples per new TLAB allocation (not every object).
> - `jdk.JavaMonitorEnter`: lock acquisition events. Captures
>   thread waiting for a monitor lock with stack trace and
>   wait duration.
> - `jdk.SocketRead` / `jdk.SocketWrite`: I/O duration with
>   remote address. Identifies slow external dependencies.
> - `jdk.Compilation`: JIT compilation events per method.
> - `jdk.Deoptimization`: when JIT assumptions are invalidated.
>
> **JFR configuration profiles:**
> - `default`: low overhead (~1%). GC + thread events. No CPU
>   profiling (no `jdk.ExecutionSample`).
> - `profile`: ~2% overhead. Adds CPU sampling and allocation
>   profiling. Use for performance investigations.
>
> **Continuous recording (production best practice):**
> Start at JVM launch with `maxsize` and `maxage` constraints.
> The ring buffer retains the last N minutes. Dump on demand
> during incidents. No pre-planning required.

---

### 💻 Code Example

**Example 1: JFR command reference**

```bash
# START AT LAUNCH - recommended production setup
java \
  -XX:StartFlightRecording=name=continuous,\
maxsize=200m,maxage=15m,disk=true,\
filename=/var/log/app/jfr/recording.jfr \
  -jar app.jar
# maxsize=200m: ring buffer cap
# maxage=15m: retain last 15 minutes of events
# disk=true: flush to disk (for longer-running recordings)

# DYNAMIC ATTACH - attach to running JVM
PID=$(pgrep -f "java.*app.jar")

# Start 60-second profile recording
jcmd $PID JFR.start \
  name=perf-investigation \
  duration=60s \
  settings=profile \
  filename=/tmp/perf.jfr

# Check status
jcmd $PID JFR.check

# Stop and dump early (if enough data collected)
jcmd $PID JFR.stop name=perf-investigation filename=/tmp/perf.jfr

# Dump continuous recording during incident
jcmd $PID JFR.dump name=continuous filename=/tmp/incident-$(date +%s).jfr

# PROGRAMMATIC RECORDING (Java API)
```

```java
// Programmatic JFR recording (useful for test environments)
import jdk.jfr.Recording;
import jdk.jfr.consumer.*;

try (Recording recording = new Recording()) {
    recording.enable("jdk.GarbageCollection");
    recording.enable("jdk.ExecutionSample")
             .withPeriod(Duration.ofMillis(10));
    recording.enable("jdk.ObjectAllocationInNewTLAB");
    recording.start();

    // ... run workload ...

    recording.stop();
    recording.dump(Path.of("/tmp/test.jfr"));
}

// Read JFR events programmatically (for automated analysis)
try (var es = EventStream.openFile(Path.of("/tmp/test.jfr"))) {
    es.onEvent("jdk.GarbageCollection", event -> {
        System.out.printf("GC: %s duration=%sms%n",
            event.getString("cause"),
            event.getDuration("duration").toMillis());
    });
    es.start();
}
```

> **Code walkthrough:** The continuous recording with `maxage=15m`
> is the most valuable production setup - it always has the last
> 15 minutes of JVM behavior without any pre-planning. When a
> midnight alert fires, `JFR.dump` captures the full 15-minute
> window before the alert. The programmatic `EventStream` API
> enables automated analysis: parse GC events in CI load tests
> and fail if pauses exceed a threshold.

---

### ⚖️ Comparison

| Feature | JFR default | JFR profile | async-profiler |
|---|---|---|---|
| CPU profiling | No | Yes (~10ms) | Yes (SIGPROF) |
| Allocation profiling | No | Yes (TLAB-based) | Yes (all) |
| Lock contention | Yes | Yes | No |
| GC events | Yes | Yes | No |
| Safepoint bias | Yes | Yes | No |
| Production safe | Yes | Yes | Short duration |
| Analysis tool | JMC | JMC | Flamegraph SVG |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JFR records JVM events with ~1% overhead, safe for production.
> Start with `-XX:StartFlightRecording`, analyze with JMC.
> Key events: GC, lock contention, CPU samples, allocations.

---

**Senior / Staff (5+ years):**

> Every service I deploy has continuous JFR with a 15-minute
> ring buffer. It's the single best investment in observability
> with zero application code changes. I've used it to diagnose
> GC regressions, lock contention, and slow external calls
> without any additional instrumentation.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "You have a JFR recording from a production incident. What
  is your analysis process?"

🗣️ "I open the recording in JMC. First, I check the timeline at
the top to identify when the incident started based on latency
spikes or error rate. Then I investigate three areas depending
on the symptom: (1) If high latency: 'JVM Internals → GC' shows
GC pause timeline. If pauses correlate with latency spikes, GC
is the cause. 'Code → Method Profiling' shows CPU flame graph -
if a method is hot during the incident, that's the bottleneck.
(2) If thread pool saturation: 'Threads → Lock Instances' shows
which locks are contended and which threads are blocked. Correlate
with application-level timeouts. (3) If memory growth: 'Memory →
Allocation Profiling' shows per-stack allocation rates. Then I
cross-reference with socket/file I/O events to check if slow
external dependencies explain the latency."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Event types, continuous recording, ring buffer. |
| Hiring Manager   | Production operational usage, incident response. |
| Bar Raiser       | JFR API (EventStream), custom events, safepoint bias. |
| Peer Engineer    | "We caught a Hibernate N+1 via SocketRead event timing..." |

---

---

# Java Mission Control

**Interview Weight:** high - The JFR analysis tool. Tests
ability to navigate JMC and interpret its reports.

---

### 🎯 Model Answer

**30 seconds:**

> Java Mission Control (JMC) is the GUI analysis tool for JFR
> recordings. Key views: Automated Analysis Report (highlights
> problems automatically), GC timeline (heap + pause visualization),
> Method Profiling (CPU flame graph), Allocation Profiling,
> Lock Instances (contention), and Thread activity. JMC 8+ is
> Apache 2.0 licensed. Download at jdk.java.net/jmc.

**3 minutes (Senior):**

> **JMC navigation for common diagnoses:**
>
> **Automated Analysis (first stop):**
> JMC applies ~100 rule checks to the recording and flags issues.
> Categories: GC (High Allocation Rate, Long GC Pauses), JIT
> (Method Too Large to Inline, Deoptimizations), Threading
> (Lock Contention, Thread Starvation), Memory (TLAB Allocation
> Hot Spots), Code (Potential Regression).
>
> **GC Analysis:**
> - 'JVM Internals → Garbage Collections': timeline with heap
>   before/after, pause type (minor/major), and cause.
> - Heap graph: if old gen grows between pauses, classic leak pattern.
> - 'GC Configuration': what GC and settings were active.
>
> **CPU Profiling (Method Profiling):**
> - 'Code → Method Profiling': flame graph of CPU samples.
> - Filter by thread if only some threads are hot.
> - 'Reverse Stack Trace': see all methods that eventually called
>   a hot method.
>
> **Lock Contention:**
> - 'Threads → Lock Instances': table of locks sorted by cumulative
>   wait time. Click a lock to see blocking/blocked thread pairs.
> - 'Threads → Thread Dumps': if thread dumps were captured in
>   the recording.
>
> **Allocation Profiling:**
> - 'Memory → Allocation by Class': top-allocated classes by volume.
> - 'Memory → Allocation by Thread': which threads allocate most.
> - Stack trace for each allocation type.

---

### 💻 Code Example

**Example 1: JMC-guided optimization workflow**

```bash
# Step 1: Capture recording under realistic load
jcmd $PID JFR.start duration=120s settings=profile filename=/tmp/prod.jfr

# Step 2: Open in JMC
# File → Open Recording → /tmp/prod.jfr

# Step 3: Automated Analysis (top of window)
# Example findings JMC might show:
# [WARNING] High Allocation Rate: 450 MB/s
#   → Recommendation: Review allocation hotspots in Method Profiling
# [WARNING] Lock Contention: UserService.processRequest() 23% blocked
#   → Recommendation: Review lock in Thread analysis
# [OK]      GC Pauses: Max 45ms (within G1GC default target)

# Step 4: Follow automated analysis → Method Profiling
# Flame graph shows: UserService.toJson() consuming 35% of CPU
# Stack: toJson() → Jackson.serialize() → Class.getMethods()
# Root cause: Jackson using reflection on every call, not caching

# Fix: configure Jackson ObjectMapper as @Bean (singleton)
# vs instantiating per-request
```

```java
// BAD: ObjectMapper instantiated per request (reflection on every call)
void handleRequest(Request req) {
    ObjectMapper mapper = new ObjectMapper();  // expensive construction
    String json = mapper.writeValueAsString(req.data());
}

// GOOD: singleton ObjectMapper (JMC-guided optimization)
@Bean  // Spring singleton - one instance for all requests
public ObjectMapper objectMapper() {
    return new ObjectMapper()
        .registerModule(new JavaTimeModule())
        .configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);
}
// Inject and reuse:
@Autowired private ObjectMapper mapper;
void handleRequest(Request req) {
    String json = mapper.writeValueAsString(req.data());
    // ObjectMapper is thread-safe once configured
}
```

> **Code walkthrough:** The JMC automated analysis points directly
> to the hot method, and the stack trace reveals the root cause:
> `Class.getMethods()` in the stack means Jackson is using
> reflection to discover serializable fields on every invocation.
> The fix - singleton `ObjectMapper` - caches the reflection
> results after first use. This is the JMC-guided optimization
> workflow: let the tool find the hotspot, understand the root
> cause, fix the root cause.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JMC analyzes JFR recordings. Start with Automated Analysis for
> auto-detected issues. Use Method Profiling for CPU, GC view
> for memory, Lock Instances for contention.

---

**Senior / Staff (5+ years):**

> JMC's Automated Analysis is surprisingly good - it applies
> rule-based heuristics that catch common issues. I start there,
> then drill into the specific view for the flagged problem.
> I also use JMC's regression detection: compare two recordings
> (before/after deployment) to find what changed.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "Walk me through how you would use JMC to investigate a
  latency regression after a deployment."

🗣️ "First, I capture JFR recordings before and after the deployment
using identical load conditions and duration. Open both in JMC.
First view: Automated Analysis on the post-deploy recording.
Look for new warnings that weren't in the pre-deploy recording -
these are the regression candidates. Second: compare GC behavior.
If GC pause frequency or duration increased post-deploy, check
'Memory → Allocation Profiling' to see if new code allocates more.
Third: compare CPU profiles. Load both flame graphs and look for
methods that are wider (hotter) in the post-deploy recording.
New code in the hot path, or previously-cached code now running
on every request, usually shows up here. Fourth: check lock
contention. If a new synchronized path was introduced, it will
appear in 'Threads → Lock Instances' with high cumulative wait
time. This four-step process usually identifies the regression
source within 20 minutes."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | JMC view navigation, Automated Analysis rules. |
| Hiring Manager   | Regression investigation workflow. |
| Bar Raiser       | JMC plugin API, custom rules, JMC Agent. |
| Peer Engineer    | "JMC flagged High Allocation Rate after our deploy - new Jackson instances..." |

---

---

# VisualVM and JConsole

**Interview Weight:** medium - Lightweight monitoring tools.
Tests knowledge of quick diagnostic capabilities.

---

### 🎯 Model Answer

**30 seconds:**

> VisualVM and JConsole are lightweight JVM monitoring tools bundled
> with older JDKs or available as standalone downloads. JConsole:
> JMX-based, shows heap, threads, classes, MBeans. Minimal.
> VisualVM: more capable - heap/thread monitoring, CPU/memory
> sampling profiler, heap dump trigger, thread dump. Neither is
> production-safe for continuous profiling (higher overhead than
> JFR). Use for development diagnostics and quick checks.

**3 minutes (Senior):**

> **JConsole use cases:**
> - Connect to local or remote JMX port.
> - Monitor: heap usage, thread count, class count, GC rate.
> - Access MBeans: query/set application-specific JMX attributes.
>   Spring Boot Actuator exposes JMX beans for cache management,
>   health, and thread pool status.
>
> **VisualVM use cases:**
> - CPU sampler: sampling profiler with ~3% overhead.
>   Less accurate than async-profiler but zero install cost.
> - Memory sampler: heap usage timeline.
> - Heap dump: right-click process → "Heap Dump" → basic analysis
>   in VisualVM or export to MAT.
> - Thread dump: right-click → "Thread Dump" → formatted view.
> - Remote monitoring: connect via JMX
>   (`-Dcom.sun.management.jmxremote.port=9999`).
>
> **Limitations:**
> - Sampler uses safepoint-biased sampling (same as old JFR).
> - Not suitable for production continuous profiling.
> - JFR + JMC is superior for all profiling use cases.
> - Use VisualVM when JFR is unavailable (pre-Java 11 production
>   without commercial license).

---

### 💻 Code Example

**Example 1: JConsole remote monitoring setup**

```bash
# JVM flags to enable JMX (for JConsole / VisualVM remote)
java \
  -Dcom.sun.management.jmxremote=true \
  -Dcom.sun.management.jmxremote.port=9999 \
  -Dcom.sun.management.jmxremote.authenticate=false \
  -Dcom.sun.management.jmxremote.ssl=false \
  # WARNING: no auth/ssl only for internal/dev use!
  # For production: enable authentication + SSL
  -Dcom.sun.management.jmxremote.password.file=/etc/jmxremote.password \
  -Dcom.sun.management.jmxremote.access.file=/etc/jmxremote.access \
  -jar app.jar

# Connect from JConsole:
# jconsole <hostname>:9999
# or for local process: jconsole (auto-discovers local JVMs)

# Expose custom metrics via JMX (Spring Boot Actuator auto-does this)
```

```java
// Custom JMX MBean for application metrics
public interface CacheMonitorMBean {
    int getCacheSize();
    int getCacheHits();
    void clearCache();  // JMX-writable operation
}

@Component
public class CacheMonitor implements CacheMonitorMBean {
    @Autowired private UserCache cache;

    @PostConstruct
    void registerMBean() throws Exception {
        MBeanServer server = ManagementFactory.getPlatformMBeanServer();
        ObjectName name = new ObjectName("com.example:type=CacheMonitor");
        server.registerMBean(this, name);
    }

    @Override public int getCacheSize() { return cache.size(); }
    @Override public int getCacheHits() { return cache.hitCount(); }
    @Override public void clearCache() { cache.clear(); }
}
// Visible in JConsole under MBeans → com.example → CacheMonitor
```

> **Code walkthrough:** The JMX setup without authentication is
> dangerous - any process on the network can connect and invoke
> operations including `clearCache()`. Always use JMX password
> files in production environments. The custom MBean shows how
> to expose application-specific metrics (cache hit rate, size)
> via JConsole - useful when Prometheus/Grafana is not available.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JConsole is JMX-based: heap, threads, MBeans. VisualVM adds
> CPU/memory sampling and heap dumps. Both are good for development
> diagnostics. For production, JFR + JMC is safer and more capable.

---

**Senior / Staff (5+ years):**

> I use JConsole mainly to access JMX MBeans in dev/staging -
> check cache hit rates, invoke health checks, or tune thread
> pool sizes via Spring Boot Actuator's JMX exposure. For
> production profiling, I've moved entirely to JFR + JMC.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "When would you use JConsole over JFR for monitoring?"

🗣️ "JConsole has one advantage over JFR: real-time MBean access.
JFR records historical events for post-hoc analysis. JConsole
lets me query and modify JMX attributes live. Use cases where
I'd choose JConsole: (1) Checking application-specific metrics
exposed as JMX MBeans in real time - cache size, connection pool
state, custom counters. (2) Invoking JMX operations - clearing
a cache, forcing a configuration reload, or calling Spring Boot
Actuator operations. (3) Quick one-time check on a development
or staging server where I need to see current heap and thread
count without starting a recording. For any historical analysis
or production profiling, JFR is superior."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | JMX setup, MBean exposure, VisualVM vs JConsole. |
| Hiring Manager   | Practical tool selection. |
| Bar Raiser       | JMX security, remote JMX via SSH tunnel, RMI registry. |
| Peer Engineer    | "VisualVM heap dump saved us when the JFR wasn't configured..." |

---

---

# Async-Profiler

**Interview Weight:** high - The definitive Java CPU and
allocation profiler for local/staging use. Fixes JFR's safepoint
bias.

---

### 🎯 Model Answer

**30 seconds:**

> async-profiler is a low-overhead Java profiler that eliminates
> safepoint bias by using OS-level signals (`SIGPROF` on Linux,
> `perf_events`) to sample CPU at arbitrary points. It reveals
> code between safepoints that JFR sampling misses. Outputs: SVG
> flame graph, JFR format (analyzable in JMC), collapsed stacks.
> Overhead: ~2-3% CPU. Used for: accurate CPU profiling, allocation
> profiling, wall-clock profiling (find slow I/O).

**3 minutes (Senior):**

> **Why safepoint bias matters:**
> HotSpot inserts safepoints in code: at method entries, back-edges
> of loops, and before certain operations. JFR's CPU sampling
> only captures stack traces when threads are at safepoints.
> Code between safepoints is invisible. If your hotspot is in a
> tight native method or a JIT-compiled loop between safepoints,
> JFR sampling will not show it.
>
> async-profiler uses `SIGPROF` (a POSIX signal) to interrupt
> threads at any point - not just safepoints. This gives true
> representation of where CPU time is spent.
>
> **async-profiler modes:**
> - `event=cpu`: CPU profiling (default). Shows where CPU time goes.
> - `event=alloc`: allocation profiling. Captures every allocation
>   (more precise than JFR's TLAB-level sampling).
> - `event=wall`: wall-clock profiling. Samples all threads,
>   including those blocked on I/O. Finds slow external calls.
>   Very useful for I/O-bound or async apps.
> - `event=lock`: lock contention. Similar to JFR JavaMonitorEnter.
>
> **Output formats:**
> - `-f profile.html`: interactive flame graph HTML (open in browser).
> - `-o jfr -f profile.jfr`: output in JFR format (open in JMC).
> - `-o collapsed`: collapsed stacks for flamegraph.pl or speedscope.

---

### 💻 Code Example

**Example 1: async-profiler usage and interpretation**

```bash
# INSTALL (Linux x86_64)
curl -L https://github.com/async-profiler/async-profiler/releases/\
latest/download/async-profiler-linux-x64.tar.gz | tar xzf -
cd async-profiler-*

PID=$(pgrep -f "java.*app.jar")

# CPU flame graph (30 seconds)
./asprof -d 30 -e cpu -f /tmp/cpu-flame.html $PID
# Open /tmp/cpu-flame.html in browser

# Allocation profiling (captures every allocation, not just TLABs)
./asprof -d 30 -e alloc -f /tmp/alloc-flame.html $PID

# WALL-CLOCK profiling (samples ALL threads including blocked ones)
# Identifies I/O-bound code, not just CPU-bound code
./asprof -d 30 -e wall -f /tmp/wall-flame.html $PID
# Key insight: in wall-clock mode, threads waiting on DB/network
# show up as hot → reveals I/O bottlenecks invisible to CPU profiling

# Output as JFR (open in JMC with full timeline)
./asprof -d 60 -e cpu -o jfr -f /tmp/profile.jfr $PID

# Start with JVM agent (zero-download attach)
java -agentpath:/path/to/libasyncProfiler.so=\
start,event=cpu,file=/tmp/cpu.html \
     -jar app.jar

# COMPARING CPU vs WALL-CLOCK findings:
# CPU profile shows:  JsonSerializer.serialize() 30% of CPU time
# Wall profile shows: HibernateSession.getEntity() 45% of wall time
# Interpretation:
#   - serialize() is CPU-intensive code (shows in CPU profile)
#   - HibernateSession is blocking on I/O (shows in wall profile only)
#   - DB queries are the bigger latency bottleneck despite lower CPU
```

> **Code walkthrough:** Wall-clock mode is the key differentiator.
> CPU profiling only shows work that consumes CPU. I/O-bound
> threads are blocked and use no CPU - CPU profiling misses them
> entirely. Wall-clock mode samples all threads regardless of
> state, revealing slow database queries, HTTP client calls, or
> any blocking operation. The comparison shows why CPU profiling
> alone is insufficient for I/O-bound Java services.

---

### ⚖️ Comparison

| | async-profiler | JFR ExecutionSample |
|---|---|---|
| Safepoint bias | No (SIGPROF) | Yes |
| Wall-clock mode | Yes | No (only CPU states) |
| Allocation mode | Yes (all allocs) | Yes (TLAB only) |
| Lock contention | Yes | Yes (more detail) |
| GC events | No | Yes |
| I/O events | No | Yes (SocketRead etc.) |
| Output | HTML flame graph | JFR file for JMC |
| Best for | Precise CPU/alloc/wall | Production + all JVM events |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> async-profiler gives accurate CPU profiling without safepoint
> bias. Wall-clock mode finds I/O bottlenecks. Use for local
> and staging profiling. JFR is better for production (lower
> overhead, GC and lock events).

---

**Senior / Staff (5+ years):**

> I use async-profiler wall-clock mode whenever I need to
> understand why a service is slow end-to-end, not just which
> code uses CPU. For CPU-bound issues, async-profiler's SIGPROF
> sampling finds hotspots in tight JIT-compiled code that JFR's
> safepoint sampling completely misses.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "What is safepoint bias and how does async-profiler fix it?"

🗣️ "Safepoint bias is a systematic measurement error in profilers
that only sample threads at JVM safepoints. HotSpot inserts
safepoints at method entries, loop back-edges, and before certain
operations. JFR and old-style JVMTI profilers can only capture
stack traces at these points. The bias: code between safepoints
- such as tight JIT-compiled loops or native method bodies - is
never captured in the sample, making it appear to consume zero
CPU. The actual hot code is invisible. async-profiler fixes this
by using OS-level `SIGPROF` signals to interrupt threads at
arbitrary points - the signal handler captures the native stack
trace regardless of whether the JVM is at a safepoint. On Linux,
it also uses `perf_events` for hardware performance counters.
This gives a true sample distribution. The practical impact:
I've seen JFR flame graphs show a method as 5% of CPU while
async-profiler shows it at 30%, because JFR's safepoint sampling
happened to miss the tight inner loop of that method."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Safepoint mechanics, SIGPROF, wall-clock mode. |
| Hiring Manager   | When to use async-profiler vs JFR. |
| Bar Raiser       | perf_events integration, DWARF stack unwinding, kernel stacks. |
| Peer Engineer    | "async-profiler revealed a JIT-compiled hot loop JFR was completely missing..." |

---

---

# Heap Dump Analysis

**Interview Weight:** high - Essential skill for diagnosing
memory leaks and OOM errors in production.

---

### 🎯 Model Answer

**30 seconds:**

> Heap dump analysis diagnoses memory leaks and OOM errors. Tools:
> Eclipse MAT (industry standard), VisualVM (basic), YourKit.
> Key MAT analyses: Leak Suspects Report (automated), Dominator
> Tree (which objects retain most heap), Histogram (objects by
> class count), and OQL (custom queries). Always take the dump
> shortly after GC to see only live objects. Compare two dumps
> to find accumulating objects.

**3 minutes (Senior):**

> **Taking heap dumps:**
> - JVM flag: `-XX:+HeapDumpOnOutOfMemoryError
>   -XX:HeapDumpPath=/var/log/app/` - dumps automatically on OOM.
> - `jcmd <pid> GC.heap_dump /tmp/heap.hprof` - on demand,
>   triggers GC first (live objects only).
> - `jmap -dump:format=b,file=/tmp/heap.hprof <pid>` - older
>   approach, does not force GC first.
>
> **Eclipse MAT key analyses:**
>
> 1. **Leak Suspects Report**: MAT groups objects by accumulation
>    pattern and reports: "Problem Suspect 1: One instance of
>    com.example.SessionStore retains 2.4 GB (80% of heap).
>    The object was loaded by AppClassLoader and has 50,000
>    references." This is automated root cause identification.
>
> 2. **Dominator Tree**: every object has a dominator (the closest
>    ancestor that, if removed, would make the object unreachable).
>    The dominator tree shows which objects "own" the most retained
>    heap. The top entry is usually the leak root.
>
> 3. **Histogram**: number and total size of instances by class.
>    If `byte[]` has 5 million instances totaling 2GB, something
>    is holding byte arrays. If `char[]` or `String` dominates,
>    look for string accumulation.
>
> 4. **OQL (Object Query Language)**:
>    ```sql
>    SELECT * FROM java.util.HashMap s WHERE s.size > 10000
>    ```
>    Finds all HashMaps with more than 10,000 entries.
>    Useful for finding oversized caches.

---

### 💻 Code Example

**Example 1: Heap dump workflow and MAT analysis**

```bash
# Step 1: Configure heap dump on OOM (production setup)
java \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/var/log/app/heap/ \
  # Creates heap-<pid>-<timestamp>.hprof on OOM
  -jar app.jar

# Step 2: Manual dump (during investigation, not OOM)
jcmd $PID GC.heap_dump /tmp/heap-$(date +%s).hprof
# GC.heap_dump forces a GC first → only live objects in dump

# Step 3: Analyze in Eclipse MAT
# File → Open Heap Dump → /tmp/heap.hprof
# 1. File → Run Leak Suspects Report
# 2. Window → Heap Dump Details → Dominator Tree
# 3. Window → Heap Dump Details → Histogram

# OQL examples (MAT query browser):
# Find all ThreadLocal values:
SELECT * FROM java.lang.ThreadLocal$ThreadLocalMap$Entry e
  WHERE e.value != null

# Find oversized maps:
SELECT * FROM java.util.HashMap h WHERE h.size > 5000

# Find String objects longer than 10,000 chars (outliers):
SELECT s FROM java.lang.String s WHERE s.count > 10000
```

```java
// COMMON HEAP DUMP FINDINGS AND FIXES:

// FINDING 1: ThreadLocal leak
// MAT shows: large ThreadLocal values retained by thread pool threads
// Cause: ThreadLocal set in request handler, never cleared
static ThreadLocal<ByteBuffer> BUFFER =
    ThreadLocal.withInitial(() -> ByteBuffer.allocate(1024 * 1024));

// BAD: ThreadLocal set but never removed in thread pool
void handleRequest() {
    BUFFER.get().put(requestData);
    // Thread returns to pool with 1MB ByteBuffer retained forever
}

// GOOD: always remove in finally
void handleRequest() {
    try {
        BUFFER.get().put(requestData);
        processBuffer(BUFFER.get());
    } finally {
        BUFFER.remove();  // thread can be reused safely
    }
}

// FINDING 2: Listener not unregistered
// MAT shows: EventBus/Observable retaining objects expected to be GC'd
class DashboardWidget {
    DashboardWidget(EventBus bus) {
        bus.register(this);  // registers as listener
    }
    // BAD: no corresponding bus.unregister(this) on close
    // → EventBus holds reference → widget (and all its fields) never GC'd
}
// GOOD: unregister in close/destroy
@PreDestroy void close() { bus.unregister(this); }
```

> **Code walkthrough:** The ThreadLocal leak is the most common
> heap dump finding in Java server applications. Thread pool threads
> run indefinitely; a ThreadLocal set in a request handler but
> never removed accumulates memory on those threads forever. MAT's
> OQL query for `ThreadLocalMap.Entry` quickly surfaces all
> retained ThreadLocal values. The `finally` block with
> `BUFFER.remove()` is the mandatory pattern.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Heap dump + MAT diagnoses memory leaks. Key reports: Leak
> Suspects (automated), Dominator Tree (leak root), Histogram
> (object counts). Enable `-XX:+HeapDumpOnOutOfMemoryError` in
> production always.

---

**Senior / Staff (5+ years):**

> My heap analysis workflow: Leak Suspects Report first (MAT
> automated analysis is fast and usually points directly at the
> problem). Dominator Tree second (confirms the leak root object).
> OQL third (for targeted queries: find all caches over 1,000
> entries, all ThreadLocal values). I've found thread pool
> ThreadLocal leaks, unbounded caches, and Hibernate session
> leaks this way.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "MAT shows one instance of SessionStore retaining 80% of heap.
  How do you find what's inside it and fix the leak?"

🗣️ "In MAT: right-click the SessionStore instance → 'Show
Retained Set'. This lists every object kept alive because of this
reference. Sort by retained heap to find the largest objects.
Right-click → 'Show Object as Dominator Tree' to see the object
graph. Expand the tree to find what SessionStore is holding: likely
a Map or List with entries that should have been evicted.
Next: right-click the Map → 'List Objects → With Outgoing References'
to see a sample of keys and values. This usually reveals whether
it's holding HTTP session objects, user data, or cached query
results. Then trace the code: what adds to this Map and what
removes from it? If entries are only added (in login, cache-aside)
but never removed (no session expiry, no TTL), the fix is to add
eviction. Use Caffeine with `maximumSize` and `expireAfterAccess`,
or add explicit session cleanup on logout/timeout."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Heap dump workflow, MAT analyses, OQL. |
| Hiring Manager   | OOM diagnosis process, -XX:+HeapDumpOnOutOfMemoryError. |
| Bar Raiser       | Shallow vs retained heap, dominator tree theory, class histogram interpretation. |
| Peer Engineer    | "MAT Leak Suspects flagged our unbounded Hibernate query cache immediately..." |
