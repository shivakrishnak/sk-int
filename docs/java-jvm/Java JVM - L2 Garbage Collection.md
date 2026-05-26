---
layout: default
title: "Java JVM - L2 Garbage Collection"
parent: "Java JVM"
nav_order: 3
permalink: /java-jvm/l2-garbage-collection/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [GC Roots and Reachability](#gc-roots-and-reachability) | high |
| 2 | [Minor GC and Major GC](#minor-gc-and-major-gc) | high |
| 3 | [Serial and Parallel GC](#serial-and-parallel-gc) | high |
| 4 | [G1 Garbage Collector](#g1-garbage-collector) | high |
| 5 | [ZGC and Shenandoah](#zgc-and-shenandoah) | high |

---

# GC Roots and Reachability

**Interview Weight:** high - The foundation of all GC algorithms.
Tests whether you understand WHY objects get collected and what
keeps them alive.

---

### 🎯 Model Answer

**30 seconds:**

> GC starts from "GC roots" - the set of references that are
> inherently live. Starting from roots, the GC traces all reachable
> objects. Any object not reachable from a root is garbage and
> eligible for collection. GC roots include: local variables on
> active thread stacks, static fields, JNI references, thread
> objects themselves, class objects (Class instances), and system
> classloader references.

**3 minutes (Senior):**

> Complete list of GC roots:
> - Local variables and parameters in active stack frames
> - Static variables (class-level fields)
> - JNI global and local references (C/C++ code holding Java references)
> - Active Java threads (the Thread objects themselves)
> - Synchronization monitors (objects used as lock)
> - JVM system classes (bootstrap classloader loaded classes)
> - JVM infrastructure references (e.g., class literals in constant pools)
>
> Reachability types (weak/soft/phantom affect when collection occurs):
> - **Strongly reachable**: reachable from a root without traversing
>   any Reference object. Never collected while reachable.
> - **Softly reachable**: only reachable through one or more
>   SoftReferences. Collected before OOM.
> - **Weakly reachable**: only reachable through WeakReferences.
>   Collected on the next GC.
> - **Phantom reachable**: finalized but not yet reclaimed.
>
> Common memory leak root causes:
> 1. Static fields holding object references (class-level = GC root)
> 2. Cache not bounded (keeps growing, objects never released)
> 3. Listener/callback not removed (event source holds reference)
> 4. Thread-local variables not cleaned (thread pool reuse retains objects)
> 5. ClassLoader not released (holds all its classes as roots)

---

### 💻 Code Example

**Example 1: GC root scenarios and common leaks**

```java
// GC ROOT: Static field - object alive as long as the class is loaded
class AppConfig {
    private static final Map<String, Config> REGISTRY = new HashMap<>();
    // REGISTRY is a GC root; all Config objects are strongly reachable
    // If Config objects are large and never removed: memory leak
    static void put(String name, Config c) { REGISTRY.put(name, c); }
    // No remove() method = REGISTRY grows forever!
}

// MEMORY LEAK: listener not removed
class EventBus {
    private List<Listener> listeners = new ArrayList<>();
    public void subscribe(Listener l) { listeners.add(l); }
    // No unsubscribe = listeners held forever (GC root via static EventBus)
}
class MyComponent {
    void start(EventBus bus) {
        bus.subscribe(new Listener() { ... });  // anonymous inner class
        // holds reference to MyComponent (outer this reference)
        // MyComponent never collected as long as EventBus lives
    }
}

// MEMORY LEAK: ThreadLocal not removed
private static final ThreadLocal<RequestContext> CTX = new ThreadLocal<>();

void handle(Request req) {
    CTX.set(new RequestContext(req));   // set in thread pool thread
    try {
        processRequest();
    } finally {
        CTX.remove();   // MUST remove! Thread pool reuses thread;
        // without remove(), RequestContext lives for the thread's lifetime
    }
}

// CHECK with jmap (heap dump inspection)
// Eclipse MAT: "Retained Heap" report shows which objects hold most memory
// OQL: SELECT * FROM java.util.HashMap
//      LIMIT 100  ORDER BY retainedHeap DESC
```

> **Code walkthrough:** Static field `REGISTRY` is a GC root -
> everything reachable from it is live. A map that only adds entries
> and never removes them is a memory leak. The anonymous listener
> holds an implicit reference to the enclosing `MyComponent` class
> through the synthetic outer-this field - the component stays
> alive as long as the EventBus holds the listener. `ThreadLocal.remove()`
> is mandatory in thread pools: the thread survives indefinitely,
> and its thread-local map holds references to all un-removed values.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> GC roots are the starting points for reachability analysis.
> Objects reachable from roots are live; unreachable objects are
> garbage. Common roots: local variables, static fields, JNI refs.

---

**Senior / Staff (5+ years):**

> The four most common production memory leaks I debug: static
> Map/Set that only adds entries, event listeners never unsubscribed,
> ThreadLocal values in thread pools never removed, and classloader
> leaks from hot deployment. Each one is a GC root chain that holds
> memory alive indefinitely.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "How would you identify a memory leak in Java?"

🗣️ "Step 1: Confirm it is a leak. Monitor heap usage with `jstat -gcutil <pid> 5s` or a Prometheus JVM gauge. If heap used keeps growing after GC (Old generation never shrinks), it is a leak. Step 2: Take heap dumps at different times. `jcmd <pid> GC.heap_dump /tmp/before.hprof`, wait, then `jcmd <pid> GC.heap_dump /tmp/after.hprof`. Step 3: Compare dumps in Eclipse MAT with 'Compare Snapshots' feature - identifies classes that grew between dumps. Step 4: Find the root path. In MAT, select the growing objects, 'Path to GC Roots' - this shows the chain from a GC root to the leaked object. That chain is the bug: a static field, an unclosed listener, an un-removed ThreadLocal."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Complete GC root list, reachability types, reference semantics. |
| Hiring Manager   | Common leak patterns, production diagnosis. |
| Bar Raiser       | MAT heap comparison, retained vs shallow heap, dominator tree. |
| Peer Engineer    | "Our heap grew 50MB/hour - tracked to un-removed ThreadLocals in pool threads..." |

---

---

# Minor GC and Major GC

**Interview Weight:** high - Tests understanding of generational
GC and the production impact of each GC type.

---

### 🎯 Model Answer

**30 seconds:**

> Minor GC: collects the Young generation (Eden + Survivor spaces).
> Fast: typically 1-50ms. Triggered when Eden fills. Live objects
> copied to Survivor; objects exceeding the age threshold promoted
> to Old. Major/Full GC: collects the Old generation (and often
> Young too). Slow: 100ms-seconds. Triggered when Old fills or
> is fragmented. Every Full GC is a stop-the-world event for
> most collectors.

**3 minutes (Senior):**

> Young generation anatomy:
> - Eden: where all new objects are allocated
> - Survivor 0 (S0) and Survivor 1 (S1): alternating; one is always empty
>
> Minor GC process: all live objects in Eden are copied to the current
> Survivor space (S0 or S1). Objects in the previous Survivor space
> are also copied if still alive. Age is incremented. Objects exceeding
> `MaxTenuringThreshold` (default 15) are promoted to Old.
> After copying, Eden and the old Survivor are cleared in one step
> (no individual reclamation needed). This is why Minor GC is fast:
> copy live objects (typically small set), clear Eden (no marking needed).
>
> Promotion failure: if Old generation is too full to accept promoted
> objects, a Full GC is triggered immediately. Symptom: Minor GC
> followed immediately by Full GC in logs.
>
> Concurrent Mark Sweep (CMS - deprecated in Java 14): ran GC
> concurrently with the application to reduce Old-gen pause time.
> Replaced by G1 (default since Java 9) and ZGC.
>
> Key GC log metrics to watch:
> - Heap before/after Minor GC (healthy: heap after = heap before Old)
> - Young GC pause time (healthy: <50ms for most apps)
> - Old GC frequency (healthy: very infrequent)
> - Full GC frequency (healthy: never or extremely rare)

---

### 💻 Code Example

**Example 1: Reading GC logs and identifying problems**

```bash
# GC log configuration (Java 9+ unified logging)
# -Xlog:gc*:file=gc.log:time,uptime,level,tags:filecount=5,filesize=20m

# HEALTHY Young GC (G1):
# [2.345s][info][gc] GC(15) Pause Young (G1 Evacuation Pause) 256M->112M(512M) 8.234ms

# UNHEALTHY: Promotion failure → triggers Full GC
# [45.012s][info][gc] GC(89) Pause Young (G1 Evacuation Pause) 480M->478M(512M) 3ms
# [45.015s][info][gc] GC(90) Pause Full (G1 Compaction Pause) 478M->201M(512M) 1823ms
# Pattern: Young GC barely frees space (480→478) → immediate Full GC → 1.8s pause

# UNHEALTHY: Old growing continuously (Heap leak)
# GC(10)  Heap: Eden=128M Old=200M
# GC(50)  Heap: Eden=128M Old=250M
# GC(100) Heap: Eden=128M Old=320M  ← Old growing after each GC
# → memory leak in long-lived objects

# jstat -gcutil output (1s interval)
#  S0     S1     E      O      M     YGC  YGCT   FGC  FGCT    GCT
#   0.00  45.12  22.67  55.23  95.1  234  1.456    2  0.312  1.768
# Columns: S0%  S1%  Eden%  Old%  Metaspace%  YoungGC#  YoungGCTime  FullGC#  FullGCTime
# Healthy: Old% stable (not growing), FGC=0 or very low
```

```java
// Trigger Minor GC pressure (allocation-heavy code)
void processRequests(List<Request> requests) {
    for (Request req : requests) {
        byte[] buffer = new byte[8192];  // 8KB per request
        // Short-lived: dies after processRequest returns
        // → allocated in Eden, collected in next Minor GC
        processRequest(req, buffer);
    }
}
// This is fine: Eden handles short-lived allocations efficiently

// Trigger Old generation pressure (long-lived objects)
static List<ProcessedResult> resultCache = new ArrayList<>();
void processRequest(Request req) {
    ProcessedResult result = new ProcessedResult(req);
    resultCache.add(result);  // LEAK: never removed from static list
    // After many requests: Old generation fills → Full GC
}
```

> **Code walkthrough:** The GC log shows a promotion failure pattern:
> Young GC at 45.012s barely frees any heap (480→478MB), then
> immediately triggers a Full GC with 1.8s pause. The root cause:
> Old generation is full and cannot accept promoted objects. `jstat
> -gcutil` columns show Old% growing over time = leak or insufficient
> heap for working set.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Minor GC collects Young generation - fast. Major/Full GC collects
> Old generation - slow. Objects move from Eden to Survivor to Old
> as they age. Full GC pauses the whole application.

---

**Senior / Staff (5+ years):**

> The promotion failure pattern is the most important GC anti-pattern
> to recognize: Minor GC barely frees heap → immediate Full GC.
> Root cause: either too many objects are surviving Minor GC (Eden
> too small, or objects are legitimately long-lived), or Old is
> too small. Fix: increase heap (`-Xmx`), adjust Young:Old ratio,
> or fix the leak.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "Why is Minor GC faster than Full GC?"

🗣️ "Two reasons. First: minor GC only processes the Young generation,
which is a small fraction of the total heap (typically 1/3). Full
GC processes the entire heap. Second: Minor GC uses copying
collection. It copies all live objects from Eden and the old
Survivor to the current Survivor (or promotes to Old). After
copying, Eden and the old Survivor are cleared instantly - no
need to scan individual dead objects. This is O(live objects),
not O(total heap). Full GC on the Old generation typically uses
mark-compact which requires scanning all live objects, then
moving them to defragment - O(live objects in heap) plus
reference updates."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Eden/Survivor mechanics, promotion, promotion failure. |
| Hiring Manager   | Reading GC logs, jstat output, alerting on Full GC. |
| Bar Raiser       | Survivor ratios, MaxTenuringThreshold, adaptive size policy. |
| Peer Engineer    | "Every night at 2 AM we had a 2-second GC pause - Old generation compaction..." |

---

---

# G1 Garbage Collector

**Interview Weight:** high - The default GC since Java 9. Tests
understanding of region-based collection and how G1 differs from
older generational GCs.

---

### 🎯 Model Answer

**30 seconds:**

> G1 (Garbage First) is the default GC since Java 9. It divides
> the heap into equal-sized regions (~1-32MB each). Regions are
> dynamically assigned as Eden, Survivor, Old, or Humongous (for
> large objects). G1 collects the regions with the most garbage
> first ("garbage-first" = highest return per pause time). Key
> feature: predictable pause time target (`-XX:MaxGCPauseMillis=200`
> default). Concurrent marking identifies which regions have most
> garbage.

**3 minutes (Senior):**

> G1 GC cycle phases:
> 1. **Young collection (Evacuation Pause)**: evacuates Eden and
>    Survivor regions to new Survivor/Old regions. Stop-the-world,
>    short (1-50ms typical).
> 2. **Concurrent Marking**: traces live objects from GC roots,
>    runs CONCURRENTLY with application. Identifies Old regions
>    with high garbage ratio. Three phases: initial mark (STW, piggybacked
>    on Young GC), concurrent mark (concurrent), remark (STW, short).
> 3. **Mixed Collection**: evacuates selected Old regions (the
>    "most garbage" regions) along with Young regions. STW like
>    Young collection but collects more.
> 4. **Full GC (fallback)**: if G1 cannot keep up with allocation
>    rate, falls back to serial Full GC with long pause. Must avoid this.
>
> Tuning G1:
> - `-XX:MaxGCPauseMillis=200` (default): G1 tries to stay under
>   200ms pause. This is a goal, not a guarantee.
> - `-XX:G1HeapRegionSize=N`: region size (1MB-32MB, power of 2).
>   Larger regions = fewer regions = less overhead.
> - `-XX:G1NewSizePercent=5` and `G1MaxNewSizePercent=60`: Young
>   generation size as % of heap (G1 adapts dynamically).
>
> Humongous objects: objects >50% of region size are "humongous",
> allocated in contiguous humongous regions. They are treated
> specially: allocated outside Eden, collected during concurrent
> marking, not during Young GC. Short-lived humongous objects
> cause excessive GC pressure.

---

### 💻 Code Example

**Example 1: G1 configuration and log interpretation**

```bash
# Enable G1 (default Java 9+, explicit pre-Java 9)
# -XX:+UseG1GC

# Recommended G1 production flags
# -XX:MaxGCPauseMillis=200        target max pause (G1 tunes itself)
# -Xms4g -Xmx8g                   initial and max heap
# -XX:G1HeapRegionSize=4m         region size (tune for heap size)
# -XX:G1NewSizePercent=10         min young generation %
# -XX:G1MaxNewSizePercent=40      max young generation %
# -XX:InitiatingHeapOccupancyPercent=45  start concurrent marking at 45% Old
# -Xlog:gc*:file=gc.log:time:filecount=5,filesize=50m

# G1 GC log (healthy):
# [1.234s][info][gc] GC(23) Pause Young (G1 Evacuation Pause) 1024M->512M(4G) 12ms
#    Before→After(HeapMax) PauseTime

# G1 Mixed GC (healthy - reclaiming Old regions):
# [12.456s][info][gc] GC(45) Pause Young (G1 Mixed Evacuation Pause) 2048M->1024M(4G) 45ms

# G1 Full GC (BAD - fallback):
# [89.012s][info][gc] GC(101) Pause Full (Evacuation Failure) 3.8G->2.1G(4G) 3456ms
# Caused by: G1 running out of free regions during evacuation

# Humongous allocation in log:
# [1.001s][info][gc,alloc] (humongous) Humongous object 8M allocated at: 0x...
# Large objects (>region_size/2) bypass Eden - immediate Old allocation
```

```java
// AVOID: Short-lived humongous objects
void processLargeData(byte[] input) {
    byte[] buffer = new byte[4 * 1024 * 1024];  // 4MB = humongous!
    // Bypasses Eden, allocated in humongous region (Old area)
    // Collected during Mixed GC (not Young GC) - inefficient
}

// BETTER: Reuse large buffers via pool
private static final ThreadLocal<byte[]> BUFFER =
    ThreadLocal.withInitial(() -> new byte[4 * 1024 * 1024]);

void processLargeData(byte[] input) {
    byte[] buffer = BUFFER.get();  // reuse: no new allocation per call
    // zero GC pressure for the buffer
}
```

> **Code walkthrough:** G1's region model means "humongous" objects
> (>50% of region size) skip Eden and go directly into Old-area
> humongous regions. They are not collected by Young GC - only by
> Mixed or Full GC. Short-lived 4MB buffers allocated on every
> request will cause Old generation pressure that triggers Mixed
> and eventually Full GC. Buffer pooling via `ThreadLocal` eliminates
> this allocation entirely.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> G1 divides the heap into regions dynamically assigned to Young/Old.
> It collects the most garbage-filled regions first for efficient
> pause time. Default since Java 9. Target pause: 200ms default.

---

**Senior / Staff (5+ years):**

> G1's concurrent marking is its key advantage over Parallel GC.
> I tune `InitiatingHeapOccupancyPercent` (IHOP) to start marking
> early enough to avoid Full GC. Humongous objects are a G1-specific
> concern: I monitor `jstat -gcutil` for a continuously growing Old%
> in apps with large transient buffers.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "How does G1 achieve its pause time target?"

🗣️ "G1 uses a predictive pause time model. It tracks the pause
time required to evacuate each heap region based on historical data
(how long previous evacuations of similar regions took). Before
each collection, G1 selects a set of regions (Eden + any Old regions
for Mixed GC) whose predicted evacuation time fits within the
`MaxGCPauseMillis` budget. If time runs out mid-collection, G1
stops adding regions to the collection set. This is why G1 says
the target is a 'soft goal' - it uses prediction to stay within
budget, but unpredictable live-set sizes can cause overrun. G1
does NOT guarantee the pause time; it optimizes toward it."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Region model, Mixed GC, concurrent marking phases. |
| Hiring Manager   | MaxGCPauseMillis tuning, IHOP configuration. |
| Bar Raiser       | Humongous objects, G1 evacuation failure, Remark STW. |
| Peer Engineer    | "G1 Mixed GC was pausing us 400ms even with MaxGCPauseMillis=200..." |

---

---

# ZGC and Shenandoah

**Interview Weight:** high - Next-generation low-latency collectors.
Tests awareness of the sub-millisecond pause goal and the
mechanisms that achieve it.

---

### 🎯 Model Answer

**30 seconds:**

> ZGC (Java 15 GA) and Shenandoah (Java 12 OpenJDK) are concurrent
> low-latency GCs with sub-millisecond pause times regardless of
> heap size. They achieve this by doing compaction concurrently
> with the application using colored pointers (ZGC) or load barriers
> (both) to handle objects moving while the application runs.
> Trade-off: more CPU overhead than G1. Use when p99 latency < 10ms
> is required.

**3 minutes (Senior):**

> Both ZGC and Shenandoah solve the same fundamental problem:
> traditional GCs stop the application to compact (move) objects
> because moving objects updates references. If a thread reads
> a reference while GC is moving the object, it gets a stale pointer.
>
> **ZGC approach - colored pointers**: stores GC metadata in unused
> bits of the 64-bit object pointer (load barrier reads the color
> bits and forwards to new address if the object was moved).
> All heap accesses go through a load barrier that checks if the
> pointer is up to date. ZGC pauses: only initial mark root scan
> + remark root scan (both <1ms). Rest is concurrent.
>
> **Shenandoah approach - load barriers + Brooks pointer**: adds
> a forwarding pointer to every object. When GC moves an object,
> the forwarding pointer is updated. Any read through a stale
> pointer is redirected via the Brooks pointer. Pause: initial mark
> + final mark + update references (all <1ms).
>
> **Trade-offs vs G1**:
> - ZGC: ~5-10% CPU overhead from load barriers; excellent for
>   large heaps (100GB+); sub-ms pauses.
> - G1: lower CPU overhead; longer pauses (10-200ms); better
>   throughput for non-latency-critical workloads.
>
> **Use ZGC/Shenandoah when**: tail latency (p99/p999) requirements
> are tight (<10ms), heap is large (16GB+), pausing users is
> unacceptable (real-time bidding, financial transactions,
> interactive APIs).

---

### 💻 Code Example

**Example 1: ZGC and Shenandoah configuration**

```bash
# ZGC (Java 15+ GA)
java -XX:+UseZGC \
     -Xmx16g \
     -Xms16g \   # Set initial=max to avoid heap resize pauses
     -XX:ConcGCThreads=4 \   # concurrent GC threads (default: auto)
     -Xlog:gc*:file=gc.log:time \
     -jar myapp.jar

# ZGC GC log (healthy):
# [1.023s][info][gc] GC(1) Garbage Collection (Proactive) 3276M(39%)->1024M(12%)
# Pause: 0.432ms  ← sub-millisecond!

# Shenandoah (Java 12+, OpenJDK)
java -XX:+UseShenandoahGC \
     -Xmx16g -Xms16g \
     -XX:ShenandoahGCMode=iu \   # incremental update (default)
     -Xlog:gc*:file=gc.log:time \
     -jar myapp.jar

# Shenandoah log (healthy):
# [1.456s][info][gc] GC(3) Concurrent reset 0.345ms
# [1.457s][info][gc] GC(3) Pause Init Mark (unload classes) 0.234ms
# [1.578s][info][gc] GC(3) Concurrent marking 121.456ms
# [1.578s][info][gc] GC(3) Pause Final Mark (unload classes) 0.456ms

# Benchmarking GC choice for your workload
# -XX:+PrintGCDetails: compare pause times between G1, ZGC, Shenandoah
# Use: wrk or hey HTTP load tool + latency histogram
# Compare p99 and p999 latency across GC configurations
```

```java
// Application impact of ZGC: nearly invisible
// Before ZGC (G1): p99 latency = 150ms (GC pause)
// After ZGC: p99 latency = 12ms (application code), GC pauses < 1ms

// Load barrier overhead: measure with JMH (micro-benchmark)
@Benchmark
public int readField(State s) {
    return s.obj.value;  // ZGC load barrier checks on every read
}
// Overhead: ~3-5% on reads - typically acceptable
```

> **Code walkthrough:** ZGC log shows a full GC cycle completing
> in 0.432ms on a 16GB heap. This would be a 5-10 second Full GC
> with Serial GC. The load barrier overhead is visible in
> micro-benchmarks (~3-5% on reads) but amortizes well in I/O-bound
> applications where the bottleneck is I/O, not object access.

---

### ⚖️ Comparison

| | G1 | ZGC | Shenandoah |
|--|----|----|------------|
| Default | Java 9-20, default | Java 21 default | OpenJDK only |
| Pause type | STW evacuate | Concurrent compact | Concurrent compact |
| Pause length | 10-200ms | <1ms | <5ms |
| Throughput | high | ~5-10% lower | ~5-10% lower |
| Heap size | 4-100GB sweet spot | 1MB-16TB | 1MB-16TB |
| CPU overhead | low | 10-20% | 10-20% |

**The deciding factor:** p99 < 10ms AND heap > 16GB = ZGC.
Default Java workloads = G1. Interactive APIs where GC pauses
cause SLA breaches = ZGC.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> ZGC and Shenandoah are low-latency GCs with sub-millisecond
> pauses on any heap size. They run concurrently with the application.
> Trade-off: slightly lower throughput. Use for latency-sensitive
> services.

---

**Senior / Staff (5+ years):**

> ZGC is the default in Java 21 and is the right choice for
> latency-sensitive services at any scale. The load barrier overhead
> is negligible for I/O-bound services. For CPU-bound batch jobs,
> G1 or Parallel GC maximize throughput. I recommend ZGC as the
> default for new services and switching to G1 only if CPU profiling
> shows measurable overhead.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "When would you choose ZGC over G1?"

🗣️ "I choose ZGC when p99 or p999 latency requirements are tight.
G1's pause time target is a soft goal - in practice, G1 pauses
can be 100-500ms under sustained allocation. For a trading system
or an interactive API with a 50ms SLA, a 200ms GC pause is a
violation. ZGC's concurrent compaction keeps pauses under 1ms
regardless of heap size - on a 100GB heap, G1 would have
increasingly long pauses. The trade-off: ZGC adds ~5-10% CPU
overhead from load barriers. For CPU-bound batch processing,
G1 or Parallel GC give better total throughput. For I/O-bound
web services, the CPU overhead of ZGC is absorbed by I/O wait
time and the latency benefit is clear."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Load barriers, colored pointers, concurrent compaction. |
| Hiring Manager   | When to use each GC - latency vs throughput decision. |
| Bar Raiser       | ZGC Java 21 default, Generational ZGC (Java 21+), Brooks pointer. |
| Peer Engineer    | "Switching to ZGC cut our p99 from 400ms to 5ms with 20GB heap..." |
