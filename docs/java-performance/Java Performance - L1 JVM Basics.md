---
layout: default
title: "Java Performance - L1 JVM Basics"
parent: "Java Performance"
grand_parent: "SK Interview"
nav_order: 2
permalink: /java-performance/l1-jvm-basics/
---

# Java Performance - L1 JVM Basics

## JVM Memory Areas: Heap, Stack, Metaspace, Code Cache

### 🎯 Model Answer

**30 seconds:**
> JVM memory areas: Heap (objects, GC-managed), Stack (one per thread: method frames, local vars),
> Metaspace (class metadata, native, replaces PermGen in Java 8+), Code Cache (JIT-compiled native code),
> Native Memory (off-heap buffers, NIO). Performance concern: heap = GC pressure. Stack = thread
> count (each thread: 256KB-2MB stack). Metaspace: class loading leaks. Code Cache: JIT disabled
> if full.

**3 minutes (Senior):**
> JVM memory areas and their performance implications:
>
> 1. **Heap**: young generation (Eden + Survivor spaces) + old generation. New objects in Eden.
>    Objects surviving young GC promoted to old gen. GC pressure = allocation rate relative to
>    collection rate. `-Xmx` (max heap), `-Xms` (initial heap).
>
> 2. **Stack**: per-thread. Holds stack frames (local variables, operand stack, method reference).
>    Default: 512KB-1MB per thread. 1,000 platform threads = 512MB-1GB for stacks.
>    Virtual threads: stacks are heap-allocated continuations (~1KB each). `StackOverflowError`:
>    too-deep recursion exceeds the stack size.
>
> 3. **Metaspace**: class metadata (bytecode, field/method info, constant pool). Native memory
>    (not heap). Default: no limit (`-XX:MaxMetaspaceSize` should be set). ClassLoader leak:
>    classloaders not GC'd because some code holds a reference -> Metaspace grows unboundedly.
>    Common in web servers (each deployment creates new classloaders).
>
> 4. **Code Cache**: JIT-compiled native code. Default: 240-512MB depending on JVM version.
>    If full: JVM falls back to interpreted mode (severe performance degradation).
>    Flag: `-XX:ReservedCodeCacheSize=512m`.
>
> 5. **Direct/Off-heap memory**: `ByteBuffer.allocateDirect()`, NIO channels. Not subject to GC.
>    Managed manually or via Cleaner. Useful for large IO buffers.

**Blank Mind Recovery:**

**(1) Restate:** "Heap: objects, GC. Stack: per thread, frames. Metaspace: class metadata, native, no limit. Code Cache: JIT code. Native: off-heap buffers. Heap: -Xmx. Code Cache: -XX:ReservedCodeCacheSize."

**(2) First principles:** "Memory = objects + code + thread state + metadata. Each area has a lifecycle: heap is collected by GC, stacks die with threads, metaspace grows as classes load, code cache fills as JIT compiles. Each can become a bottleneck."

**(3) Bridge:** "JVM memory is like a city. The heap is the housing district (objects live and die here). Stacks are office buildings (each employee/thread has one). Metaspace is city hall (records about how the city works). Code Cache is the highway system (compiled roads for fast travel)."

---

### 📘 Concept Explanation

**JVM memory layout and sizing:**
```
JVM MEMORY AREAS (simplified):

  [ Heap (GC-managed) ]
    Eden    | Survivor0 | Survivor1  <- Young Generation
    ----------------------------------------
    Old Generation (Tenured)
  
  [ Metaspace (native, no GC) ]
    Class metadata: bytecode, field info, constant pool, method tables
    Grows as new classes are loaded
  
  [ Stack per thread (native, not GC) ]
    Thread-1 stack: [frame1][frame2][frame3]...
    Thread-2 stack: [frame1][frame2]...
    Size: -Xss (default 512KB-1MB)
  
  [ Code Cache (native) ]
    JIT-compiled native code: interpreted methods get compiled here
    -XX:ReservedCodeCacheSize=512m (default varies by JVM version)
  
  [ Direct Memory (native) ]
    ByteBuffer.allocateDirect() allocations
    -XX:MaxDirectMemorySize=256m
  
  TOTAL PROCESS MEMORY:
  = Heap + Metaspace + Stacks + CodeCache + DirectMemory + OS overhead
  Container memory limit (Docker/K8s) = ALL of the above
  Common mistake: set -Xmx to container limit, OOMKilled because
  Metaspace + Code Cache + native = 200-500MB additional.

KEY JVM FLAGS:
  -Xmx4g             : max heap 4GB
  -Xms4g             : initial heap = max (avoid heap resize overhead)
  -Xss512k           : thread stack size
  -XX:MetaspaceSize=256m     : initial metaspace (not a limit)
  -XX:MaxMetaspaceSize=512m  : max metaspace (set this!)
  -XX:ReservedCodeCacheSize=512m : code cache size
  -XX:MaxDirectMemorySize=256m   : off-heap limit

GENERATIONAL HEAP IN DETAIL (G1 GC):
  Eden: new objects allocated here (TLAB = thread-local allocation buffer)
  Survivor: objects that survived at least one young GC
  Old Gen: objects that survived N young GCs (N=15 default = -XX:MaxTenuringThreshold)
  
  Humongous objects (> 512KB for G1): skip young gen -> directly to old gen
  -> large object allocation = old gen pressure = major GC risk
  Fix: reuse large objects, use ByteBuffer.allocateDirect() for large IO buffers
```

---

### 💻 Code Example

> **Code walkthrough:** The memory diagnostic commands show how to inspect each memory area
> in a running JVM. The flag configuration example shows the correct JVM sizing for a
> container deployment - setting Metaspace and Code Cache limits to avoid unexpected
> container OOMKill.

```java
// DIAGNOSTIC COMMANDS FOR EACH MEMORY AREA:

// HEAP:
jmap -histo:live <pid>    // live object histogram (top classes by count/size)
// Output:
//  num     #instances         #bytes  class name
//    1:      1234567      98765432  [B  (byte arrays)
//    2:       234567      18765432  java.util.HashMap$Entry

// METASPACE:
jcmd <pid> VM.native_memory summary  // shows all memory areas
// Output:
//  - Java Heap:  committed = 2048MB
//  - Class:      committed = 48MB   (metaspace)
//  - Code:       committed = 240MB  (code cache)
//  - Thread:     committed = 512MB  (stack memory for all threads)

// CODE CACHE (if full - check for CodeCache warnings):
// JVM log: CodeCache is full. Compiler has been disabled.
// Flag to monitor: -XX:+PrintCodeCache or jcmd <pid> Compiler.codecache

// STACK OVERFLOW DIAGNOSIS:
// StackOverflowError: deep recursion, increase -Xss or fix infinite recursion
// Thread count * stack size = total stack memory consumption

// CONTAINER SIZING (Docker/K8s - critical):
// BAD: set -Xmx to container memory limit
// Container: 2GB limit
// -Xmx2g  <- WRONG: OOMKilled because:
//   Heap:         2048 MB (as configured)
//   Metaspace:     200 MB
//   Code Cache:    240 MB
//   Threads:       200 MB (100 threads * 2MB stack)
//   Native/OS:     100 MB
//   TOTAL:        ~2788 MB > 2048 MB container limit -> OOMKilled

// GOOD: heap = ~60-70% of container memory for JVM apps
// Container: 2GB limit
// -Xmx1200m -XX:MaxMetaspaceSize=256m -XX:ReservedCodeCacheSize=256m
// -XX:MaxDirectMemorySize=128m -Xss512k
// Estimated total: 1200 + 256 + 256 + 128 + threads + OS < 2GB
// Safe for most apps with < 100 threads.
```

> **Code walkthrough:** The container sizing calculation shows the most common production mistake:
> setting `-Xmx` to the container memory limit causes `OOMKill` because JVM uses additional
> native memory for Metaspace, Code Cache, and thread stacks. The rule: heap = 60-70% of container
> memory. The `jcmd VM.native_memory summary` command shows all memory areas, allowing accurate
> sizing. This should be run in staging before deploying to production with memory limits.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Heap: GC-managed, -Xmx for max size. Stack: per thread, StackOverflowError = too deep recursion.
> Metaspace: class metadata, set -XX:MaxMetaspaceSize. Code Cache: JIT code, -XX:ReservedCodeCacheSize.
> Container: heap is not the only memory area - allow headroom for Metaspace + Code Cache + stacks.

---

**Senior / Staff (5+ years):**
> Container sizing: use JVM ergonomics flags (-XX:MaxRAMPercentage=70.0) to auto-size heap as
> 70% of container memory. Remaining 30%: Metaspace + Code Cache + threads + native. Monitor:
> `jcmd VM.native_memory` for full memory accounting. ClassLoader leaks (Metaspace growth):
> common in Spring with hot-reload or dynamic class generation. Code Cache full: catastrophic
> performance drop, set `-XX:ReservedCodeCacheSize=512m` proactively.

---

### ⚠️ Common Misconceptions

**Misconception: "OutOfMemoryError always means the heap is full."**
JVM throws `OutOfMemoryError` for multiple reasons: (1) heap full (most common), (2) Metaspace full
(`java.lang.OutOfMemoryError: Metaspace`), (3) Direct buffer memory full, (4) Unable to create
native thread (OS-level thread limit, not heap). Read the OOM message: it specifies which area.
"Java heap space" = heap. "Metaspace" = class loading issue. "unable to create new native thread" =
too many threads (check thread count + stack size).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Service gets OOMKilled in Kubernetes without clear cause.**
```
Symptom: Pod OOMKilled. Heap dumps show heap usage at 1.2GB.
  Container limit: 2GB. Heap max: 1.5GB. Math should work. OOMKilled.

Root cause: non-heap memory growing beyond container limit.
  Heap: 1.2GB (current) / 1.5GB (max) - NOT the issue
  Metaspace: 400MB (leaked classloaders, large Spring context)
  Code Cache: 240MB
  Thread stacks: 300MB (150 threads * 2MB stack)
  Native/OS: 100MB
  Total: ~2.24GB > 2GB container limit

Diagnosis:
  jcmd <pid> VM.native_memory summary scale=MB
  Look for "Class" section (Metaspace) growing continuously.
  
  If Metaspace grows without bound: ClassLoader leak.
  Find: jmap -histo <pid> | grep ClassLoader
        heaptrack or async-profiler alloc mode on class loading path.

Fix:
  1. Set -XX:MaxMetaspaceSize=256m (limit metaspace, OOM instead of leak)
  2. Fix ClassLoader leak (find and GC the leaked ClassLoader reference)
  3. Reduce stack size (-Xss512k instead of default 1-2MB)
  4. Reduce thread count (virtual threads: 10x fewer OS threads)
  5. Use -XX:MaxRAMPercentage=70 to keep heap below 70% of container RAM
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Name JVM memory areas | 1 minute |
| Heap young vs old generation | 2 minutes |
| Metaspace vs PermGen | 1 minute |
| Container sizing formula | 2 minutes |
| OOM types and causes | 2 minutes |
| Code Cache full consequence | 1 minute |
| Stack overflow vs heap overflow | 1 minute |

---

**Q1 (areas): What are the JVM memory areas and what does each store?**

A: Heap: all objects (instances, arrays). Young gen: newly created objects. Old gen: long-lived objects.
GC manages heap. Stack (per thread): method frames (local variables, return address, operand stack).
Not GC-managed. Metaspace: class metadata (class structure, method bytecodes, constant pools). Native
memory, not heap. Code Cache: JIT-compiled native code. Native memory. Direct memory: `ByteBuffer.allocateDirect()`
allocations. Native, not heap.

*What separates good from great:* The "total process memory" calculation: container monitoring shows
the total process resident set size (RSS), not just heap. RSS = heap (used) + Metaspace + Code Cache
+ Thread stacks + Direct memory + JVM internal overhead. A JVM process with `-Xmx4g` but large thread
count (1000 threads * 1MB = 1GB stack) uses 5GB+ RSS. Container limits must account for all of these.
The JVM `-XX:MaxRAMPercentage=70` flag: sets heap to 70% of available container RAM. The remaining
30% is available for Metaspace, Code Cache, threads, and OS overhead. This is the recommended
approach for containers.

---

**Q2 (permgen): What is the difference between PermGen and Metaspace?**

A: PermGen (pre-Java 8): a fixed-size heap region for class metadata. Default: 64MB-128MB.
`OutOfMemoryError: PermGen space`: class metadata filled PermGen (common in web servers with
many deployed applications). Java 8: PermGen removed. Metaspace: replaces PermGen but uses
NATIVE memory (not heap). No fixed limit by default (grows with class loading). No more
"PermGen space" OOM, but Metaspace can grow without bound (set `-XX:MaxMetaspaceSize`).

*What separates good from great:* The ClassLoader leak in Metaspace: when a web application
is undeployed (hot-reload), its ClassLoader should be GC'd (and Metaspace freed). But if any
class or thread holds a reference to the ClassLoader (or a class loaded by it): the ClassLoader
is not GC'd, Metaspace is not freed. After 10 redeploys: 10x the Metaspace. This is invisible
in heap dump tools (Metaspace is native, not on the heap). Detection: `jcmd VM.native_memory`
shows "Class" committed growing over time. Fix: find the ClassLoader reference (often in thread
locals, static fields, or JDK internals like JDBC driver registration).

---

**Q3 (stack): What is the relationship between thread count and stack memory?**

A: Each platform thread has a stack. Default stack size: OS-dependent (512KB on Linux, 1MB on
Windows, often 2MB on some JDKs with `-Xss` default). 1000 threads: 512MB-2GB of stack memory.
This is native memory (not heap). Virtual threads: stacks are heap-allocated continuations
(~1KB each). 1 million virtual threads: ~1GB heap for stacks (much more efficient). Stack size
tunable: `-Xss256k` reduces each thread's stack (allows more threads but risks StackOverflowError
for deep call stacks).

*What separates good from great:* The thread pool sizing heuristic: for blocking IO (JDBC, HTTP),
the rule was "50-200 threads per CPU for high concurrency." This meant: 200 threads * 1MB = 200MB
of native stack. With virtual threads: 10,000 virtual requests on 16 carrier threads = 16 * 1MB
= 16MB of stack (the virtual threads' continuations are in the heap, amortized). The thread stack
memory was a real limiting factor for high-concurrency servers before virtual threads. A system
with 1 million concurrent connections required a very large machine just for thread stacks. Virtual
threads eliminate this constraint.

---

---

## Garbage Collection Fundamentals

### 🎯 Model Answer

**30 seconds:**
> GC: automatic memory management. The JVM identifies unreachable objects and reclaims their memory.
> Generational hypothesis: most objects die young. Young GC (minor): collects Eden and Survivor
> spaces (fast, ~10ms). Old GC (major/full): collects entire heap (slow, 100ms-seconds). GC choice:
> G1 (default), ZGC (low latency), Shenandoah (low latency), Parallel (throughput).

**3 minutes (Senior):**
> GC fundamentals:
>
> 1. **Reachability**: an object is live if reachable from a GC root (static fields, stack frames,
>    JNI references). Unreachable = eligible for collection. No reference cycle detection needed:
>    unreachable cycles are collected too.
>
> 2. **Generational hypothesis**: most objects live very briefly (died with the request that created
>    them). Few objects live a long time (caches, connection pools). Design consequence: short-lived
>    objects = cheap (young GC, fast). Long-lived objects = expensive (eventually old gen, major GC).
>
> 3. **Young GC (minor)**: collects Eden + Survivors. Surviving objects promoted. Stop-the-world
>    but brief (~1-10ms for G1). Triggered: Eden full.
>
> 4. **Old GC (major)**: collects old gen. Stop-the-world (for stop-the-world collectors) or
>    concurrent (G1, ZGC). Triggered: old gen fills. Can be seconds for Parallel GC.
>
> 5. **GC roots**: the starting points for reachability: (1) JVM stack frame local variables,
>    (2) static fields, (3) JNI references, (4) active threads, (5) class loaders.

**Blank Mind Recovery:**

**(1) Restate:** "Objects: live if reachable from GC roots. Dead if unreachable. Generational: young gen = cheap. Old gen = expensive. Young GC: short, frequent. Old GC: long, infrequent. GC roots: stack frames, static fields, JNI, threads."

**(2) First principles:** "Memory must be reclaimed automatically to prevent leaks. GC traces the reachability graph from GC roots to find live objects. Everything not reachable = garbage = can be freed."

**(3) Bridge:** "GC is like a janitor cleaning an office. Young gen = desk (cleared daily). Old gen = file cabinets (cleaned monthly). GC roots = the active people in the office - their stuff stays. Everything no one is using gets cleaned up."

---

### 📘 Concept Explanation

**GC mechanics and generational design:**
```
REACHABILITY GRAPH:

  GC Root (static field) -> Object A -> Object B
                         -> Object C -> Object D -> Object E
  
  Object F (no path from any GC root) -> GARBAGE, will be collected
  
  Note: reference cycles (A -> B -> A) are collected if no path FROM GC root
  This is why reference counting (Python's GC) fails for cycles;
  Java's tracing GC handles cycles correctly.

GENERATIONAL DESIGN:

  Eden:     new objects (cheapest to allocate - bump pointer, no scan)
  Survivor: objects surviving 1+ young GCs
  Old Gen:  objects surviving MaxTenuringThreshold young GCs (default 15)
  
  Young GC (G1):
  1. All application threads stopped (stop-the-world)
  2. Mark live objects in Eden + Survivors from roots (fast, small area)
  3. Copy live objects to a new Survivor space (compact)
  4. Old Eden + old Survivor -> free for new allocations
  5. Objects with age >= threshold -> promoted to old gen
  Duration: 1-10ms typically
  
  Major GC / Full GC (G1):
  1. (Concurrent) Marking: mark live objects in old gen while app runs
  2. (Stop-the-world) Remark: finalize marking
  3. (Concurrent) Cleanup: identify garbage regions
  4. (Stop-the-world) Evacuation: compact old gen
  Duration: 10-100ms (G1 targets MaxGCPauseMillis)

WRITE BARRIER (how GC tracks cross-generational references):
  A reference from old gen to young gen: old objects can reference new ones.
  Write barrier: intercepts every reference assignment.
  If old gen object O gets a reference to young gen object Y:
    The write barrier records this in a "remembered set."
  During young GC: check remembered sets to find references from old gen.
  Without write barriers: young GC would have to scan all of old gen (slow).

GC OVERHEAD METRIC:
  GC overhead % = (GC pause time / total elapsed time) * 100
  
  < 5%: healthy
  5-10%: monitor
  10-20%: GC bottleneck, investigate allocation patterns
  > 20%: severe GC problem, likely high allocation rate or large live set
  
  Monitoring: -Xlog:gc:file=gc.log   or   JFR GC events
  Parse: GCEasy.io for GC log analysis
```

---

### 💻 Code Example

> **Code walkthrough:** The allocation patterns show which code generates efficient short-lived
> objects (collected cheaply) vs long-lived objects (promoted to old gen, causing major GC pressure).
> The large object allocation and the static collection anti-pattern are the most common sources
> of old gen pressure in real applications.

```java
// GOOD: short-lived objects (die in young gen):
@GetMapping("/users/{id}")
UserResponse getUser(@PathVariable Long id) {
    User user = userService.findById(id);     // lives for one request
    return new UserResponse(user.getName());  // lives for one response
    // Both objects: created at request start, unreachable after response sent
    // -> collected in next young GC. Very cheap.
}

// BAD: long-lived object accumulation in old gen:
static final List<User> ALL_USERS = new ArrayList<>();  // static = GC root!

void processUser(User user) {
    ALL_USERS.add(user);  // user becomes long-lived, promoted to old gen
    // Never removed -> old gen grows without bound -> major GC or OOM
}

// BAD: large object allocation (bypasses young gen):
byte[] largeBuffer = new byte[5 * 1024 * 1024];  // 5MB - humongous object
// G1 humongous threshold: > half of heap region size (default 1MB region)
// 5MB object -> goes directly to old gen -> old gen pressure
// Fix: reuse large buffers (pool them) or use off-heap DirectByteBuffer

// GOOD: buffer reuse pattern:
// Per-request buffer from a pool (or ThreadLocal):
private static final ThreadLocal<byte[]> BUFFER_POOL = 
    ThreadLocal.withInitial(() -> new byte[65536]);  // 64KB

void processData(InputStream in) throws IOException {
    byte[] buf = BUFFER_POOL.get();  // reuse, no allocation
    int n;
    while ((n = in.read(buf)) != -1) {
        process(buf, n);
    }
    // buf is ThreadLocal, stays alive but is reused - not allocated each time
}
// Caution: ThreadLocal keeps the buffer alive for the thread's lifetime.
// With virtual threads: one ThreadLocal per virtual thread = many copies.
// Use ScopedValue or explicit pass-through for virtual thread contexts.
```

> **Code walkthrough:** The three patterns show the generational lifecycle in practice. Short-lived
> request/response objects die cleanly in young GC. Static collections make objects immortal (never
> GC'd because the static field is a GC root). Large object allocations bypass young gen entirely.
> The ThreadLocal buffer pool is a valid optimization for high-allocation paths but has a caveat
> with virtual threads (one copy per virtual thread can be many copies with 10,000 virtual threads).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> GC collects unreachable objects. Generational: young gen (cheap, fast GC) + old gen (expensive,
> slow GC). Young GC: triggered when Eden fills. Old GC: triggered when old gen fills. GC roots:
> stack frames, static fields. Short-lived objects: free. Long-lived objects that promote: expensive.

---

**Senior / Staff (5+ years):**
> GC tuning is about REDUCING what gets promoted to old gen, not just tuning GC settings.
> Allocation profiling (async-profiler alloc mode): find code creating too many objects.
> Object pooling (carefully): reduces allocation rate. Avoid static collections holding live objects.
> Large object awareness: objects > 512KB (G1) skip young gen. Off-heap for large IO buffers
> (DirectByteBuffer). GC metrics: allocation rate (MB/s), promotion rate (MB/s), old gen growth rate.

---

### ⚠️ Common Misconceptions

**Misconception: "GC is non-deterministic and unpredictable."**
GC behavior is deterministic given the same heap usage patterns and GC configuration. It appears
non-deterministic in production because load varies (allocation rate varies with traffic). G1 GC
with `-XX:MaxGCPauseMillis=50`: the JVM targets 50ms pauses. It adapts region sizes and collection
frequency. If you feed it the same allocation pattern, it produces the same GC schedule. Predictability:
improved by sizing the heap generously (reduces GC frequency), tuning pause targets, and controlling
allocation rate.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Full GC pauses causing p99 latency spikes every few minutes.**
```
Symptom: Every 3-5 minutes, p99 latency spikes to 2-5 seconds.
  Coincides with GC log entry: Full GC 1800ms.

Root cause diagnosis:
  Check GC log for the trigger:
  "Full GC (Allocation Failure)": young objects can't be promoted
    to old gen (old gen too full). Cause: old gen nearly full.
  "Full GC (Metadata GC Threshold)": Metaspace growing.
  "Full GC (System.gc())": explicit GC call in code (anti-pattern).

  Case: "Allocation Failure" -> old gen filling:
  Causes:
    A: High promotion rate (many objects surviving to old gen)
       jstat -gcold <pid>: old gen occupancy growing over time
       Fix: reduce object lifetime (scope variables, avoid caching too much)
    B: Memory leak: objects accumulate in old gen, never released
       Heap dump: jmap -dump:live,format=b,file=heap.hprof <pid>
       MAT: dominator tree shows which objects retain most heap
    C: Heap too small for the live set
       Increase -Xmx. Monitor old gen occupancy at steady state.
       Old gen should be < 50% at steady state.

Fix for System.gc() anti-pattern:
  grep code for System.gc() -> remove or replace with documented justification.
  -XX:+DisableExplicitGC: ignore all System.gc() calls.
  (Warning: some libraries rely on System.gc() for cleanup - audit first.)
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| GC reachability | 2 minutes |
| Generational hypothesis | 1 minute |
| Young GC vs Full GC | 2 minutes |
| What triggers a Full GC | 1 minute |
| Write barriers | 1 minute |
| GC overhead metric | 1 minute |
| How to reduce GC pressure | 2 minutes |

---

**Q1 (reachability): How does GC determine if an object is live or garbage?**

A: Tracing: start from GC roots, follow all references transitively, mark every reachable object.
Anything not marked = unreachable = garbage = eligible for collection. GC roots: local variables in
active stack frames, static fields, JNI references, class objects. Reference types: strong (default),
soft (GC'd when memory low), weak (GC'd any time), phantom (for post-collection cleanup). An object
with only weak references: eligible for collection even if reachable.

*What separates good from great:* The "reference cycles" insight: `A -> B -> A` with no path from a
GC root - both A and B are unreachable (not in the root set). Java's tracing GC collects this correctly.
Python's reference counting: A.ref_count = 1 (from B), B.ref_count = 1 (from A). Neither reaches
zero. Python needs a separate cycle collector. Java's tracing GC handles cycles natively. This is a
fundamental advantage of tracing GC over reference counting. The practical implication: in Java, you
cannot create circular memory leaks through object cycles UNLESS one of the objects is reachable from
a GC root. The GC root leakage is the real risk.

---

**Q2 (generations): Why does the generational hypothesis enable more efficient GC?**

A: If most objects die young: collect young gen frequently and cheaply (small area, most is garbage,
fast to process). Old gen: large but mostly live, rarely collect. Without generations: every collection
must scan the entire heap. With generations: young GC scans only Eden + Survivors (1-5% of heap).
This gives most of the collection benefit at a fraction of the cost.

*What separates good from great:* The "generational hypothesis breaks down" scenarios: (1) large
object caches (objects survive many GC cycles, promote to old gen, fill it). (2) Long transaction
processing (request creates many objects that must survive the entire transaction duration, potentially
multiple young GC cycles -> promoted). (3) High promotion rate: Eden fills quickly with long-lived
objects, young GC must copy many objects to old gen -> expensive. Tuning: `MaxTenuringThreshold`:
increase to allow more young GC cycles before promotion (gives short-lived objects more chances to die
in young gen). `-XX:NewRatio=2`: young gen = 1/3 of heap (adjust based on workload's young/old ratio).

---

**Q3 (triggers): What triggers a major/full GC?**

A: (1) Old gen fills to capacity: `Full GC (Allocation Failure)`. Most common. (2) Metaspace fills:
`Full GC (Metadata GC Threshold)`. Old in Java 7 (PermGen), still happens in Java 8+ if MetaspaceSize
is not set. (3) `System.gc()` call: `Full GC (System.gc())`. Explicit GC invocation. (4) Heap
compaction needed: some GCs trigger full collection when fragmentation is too high. (5) JVM ergonomics:
GC triggered preventively if old gen reaches a threshold.

*What separates good from great:* The `System.gc()` in production: a common hidden performance bomb.
Some libraries call `System.gc()` for "cleanup" (old RMI code, some finalization-based cleanup).
In a high-throughput service: `System.gc()` causes a Full GC pause at the worst possible time.
Detection: GC logs showing "Full GC (System.gc())" repeatedly. Fix: `-XX:+DisableExplicitGC`. BUT:
some libraries use `System.gc()` to trigger direct buffer cleanup (DirectByteBuffer: allocated
off-heap, freed when the Cleaner runs, Cleaner runs on GC). If you disable explicit GC and the
app uses many DirectByteBuffers: the Cleaner may never run -> off-heap memory leak. Alternative:
`-XX:+ExplicitGCInvokesConcurrent`: System.gc() triggers a concurrent G1 GC instead of a
stop-the-world full GC.

---

---

## Bytecode and JIT Compilation Basics

### 🎯 Model Answer

**30 seconds:**
> Java: source code compiled to bytecode (.class files), executed by the JVM's interpreter OR
> JIT-compiled to native machine code. JIT tiers: interpreted, C1 (fast compile, lower optimization),
> C2 (slow compile, maximum optimization). Hot methods (called ~10,000 times) are C2-compiled.
> C2 code: inlining, escape analysis, loop unrolling. 3-10x faster than C1.

**3 minutes (Senior):**
> JIT compilation pipeline:
>
> 1. **Tier 0**: interpreted. JVM reads and executes bytecode directly. Slow (~10x C2). Starts
>    immediately for all methods.
>
> 2. **Tier 1-2 (C1)**: "client compiler." Compiles to native code after ~2,000 invocations.
>    Basic optimizations: inlining small methods. Fast compile time. Runs while the app warms up.
>
> 3. **Tier 4 (C2)**: "server compiler." Compiles after ~10,000 invocations. Full optimizations:
>    aggressive inlining, escape analysis, loop unrolling, vectorization, constant folding.
>    Compilation is slow (background thread) but the produced code is highly optimized.
>
> 4. **Profile-guided**: C1 instruments the code with counters. C2 uses the counters to make
>    optimization decisions. C2 inlines based on actual call frequency, not just static analysis.
>
> 5. **Deoptimization**: if a JIT assumption is violated (e.g., C2 assumed a virtual call always
>    dispatches to the same implementation, but a new class is loaded): C2 deoptimizes (reverts
>    to interpreted) and recompiles with the new information.

**Blank Mind Recovery:**

**(1) Restate:** "Source -> bytecode (javac). Bytecode -> interpreter (slow) -> C1 (fast compile, medium speed) -> C2 (slow compile, maximum speed). C2: inlining, escape analysis. Tiered compilation: gradual. Deoptimization: C2 reverts if assumptions violated."

**(2) First principles:** "Bytecode is portable (one .class runs on any JVM). Native machine code is fast but platform-specific. JIT gives you portability (bytecode) AND speed (native) by compiling on demand."

**(3) Bridge:** "JIT is like a sports coach who first plays by the book (interpret all moves), then as the season progresses, creates a custom playbook for each player based on their stats (C1 data), then at the championship, runs fully optimized plays based on extensive video analysis (C2 aggressive optimization)."

---

### 📘 Concept Explanation

**JIT tiers and key optimizations:**
```
TIERED COMPILATION LEVELS:

  Level 0: Interpreted (always starts here)
  Level 1: C1 - full opt, no profiling
  Level 2: C1 - full opt, invocation/backedge counters
  Level 3: C1 - full opt, all profiling (call type, branch)
  Level 4: C2 - full opt using Level 3 profile data

  Transition thresholds (approx):
    0 -> 3: method invoked first time (profiling C1)
    3 -> 4: method invoked ~10,000 times (compile with C2)
    4: steady-state, maximum performance

KEY C2 OPTIMIZATIONS:

  INLINING:
    Method call: overhead (frame creation, argument passing, return)
    Inlined: callee code inserted directly into caller
    Small methods (< 35 bytecodes by default): likely inlined
    Effect: enables further optimizations (constant folding, dead code)
    
    Threshold: -XX:MaxInlineSize=35 (bytecodes, default)
              -XX:MaxInlineLevel=9  (max inlining depth)
  
  ESCAPE ANALYSIS:
    If an object does NOT escape the current method (not stored in fields,
    not passed to other methods that save it, not returned):
    -> Scalar replacement: allocate fields directly on the stack
    -> Zero allocation: no heap allocation, no GC pressure
    
    Example: new Point(x, y) used only locally -> may be eliminated
    
    Check if escape analysis is working:
    -XX:+DoEscapeAnalysis (default on)
    Verify: JMH benchmark with JVM printing allocation
    
  LOOP OPTIMIZATIONS:
    Loop unrolling: expand loop body to reduce loop overhead
    Loop vectorization: use SIMD instructions (process 4 ints at once)
    Loop invariant hoisting: move constant calculations out of loop
  
  CONSTANT FOLDING:
    int x = 2 * 3;  -> replaced with int x = 6 at compile time
    
  NULL CHECK ELIMINATION:
    If JIT knows a reference is non-null: removes the null check instruction

DEOPTIMIZATION:
  C2 makes speculative assumptions. If violated: deoptimize + recompile.
  Common trigger: bimorphic inline cache invalidated.
  C2 inlines virtual call to a single implementation (monomorphic).
  New subclass loaded and used for that call -> deoptimize -> recompile
  as polymorphic dispatch.
  
  Detection: JFR event jdk.Deoptimization or:
  -XX:+PrintDeoptimizationDetails

WARMUP IMPLICATIONS:
  Code runs slowly for first ~10,000 invocations (before C2).
  Performance tests: always run warmup before measuring.
  Production: startup = cold (interpreted/C1). Stabilizes after
  traffic warms up the hot methods. Canary: p99 higher during
  warmup period (first 30-60s after deployment).
```

---

### 💻 Code Example

> **Code walkthrough:** The inlining example shows how small methods that call each other benefit
> from aggressive C2 inlining - the entire call chain may be compiled into a single optimized
> native function with no virtual dispatch. The escape analysis example shows how a locally-used
> object may never hit the heap.

```java
// INLINING: small methods likely inlined by C2

// These 4 methods will likely be fully inlined by C2:
double computeArea(Shape shape) {
    return shape.area();  // virtual call -> inlined if monomorphic
}

// After inlining (conceptually, what C2 generates in native code):
// if shape is always Circle -> computeArea inlined + Circle.area() inlined:
// double area = Math.PI * shape.radius * shape.radius;
// No virtual dispatch, no method call overhead.

// ESCAPE ANALYSIS: avoiding heap allocation:
double computeDistance(int x1, int y1, int x2, int y2) {
    Point p1 = new Point(x1, y1);   // p1 does NOT escape this method
    Point p2 = new Point(x2, y2);   // p2 does NOT escape this method
    return Math.sqrt(
        Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2)
    );
    // C2 escape analysis: p1 and p2 are local, no escape
    // Scalar replacement: p1.x and p1.y become local int variables
    // Result: zero heap allocation for p1 and p2!
}

// VERIFICATION WITH JMH (allocation test):
@Benchmark
@Fork(value = 1, jvmArgsAppend = {
    "-XX:+UnlockDiagnosticVMOptions", "-XX:+PrintInlining"
})
public double benchmarkDistance() {
    return computeDistance(0, 0, 3, 4);
}
// -XX:+PrintInlining output:
//   @ 5  computeDistance: Point.<init> (inlined, 12 bytes)
//   @ 15 computeDistance: Point.<init> (inlined, 12 bytes)
// The Point constructors are inlined -> escape analysis can see full picture
// -> scalar replacement eliminates the Point objects from heap.

// BAD: defeating escape analysis:
List<Point> allPoints = new ArrayList<>();  // class-level field

double computeDistanceLeaking(int x1, int y1, int x2, int y2) {
    Point p1 = new Point(x1, y1);
    allPoints.add(p1);  // p1 ESCAPES to the field -> no scalar replacement
    Point p2 = new Point(x2, y2);
    return Math.sqrt(
        Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2)
    );
    // Now both points are heap-allocated (p1 escapes; p2 might too
    // because C2 may conservatively treat them the same scope)
}
```

> **Code walkthrough:** The distance computation with local `Point` objects shows escape analysis
> in practice. `p1` and `p2` are created and used entirely within `computeDistance` - they don't
> escape to the heap. C2 detects this and applies scalar replacement: the Point's x and y values
> become local registers, never allocated on the heap. The leaking version adds `p1` to a class
> field: now `p1` escapes, C2 cannot apply scalar replacement, and both points are heap-allocated.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Java compiles to bytecode (platform-independent). JVM JIT-compiles hot methods to native code
> at runtime. Tiers: interpreted (slow) -> C1 (fast compile) -> C2 (optimized native). Key
> optimizations: method inlining, escape analysis. JMH warmup: let C2 compile before measuring.

---

**Senior / Staff (5+ years):**
> Inlining is the foundation of other optimizations: once a call is inlined, the entire merged
> code block can be optimized as one unit (constant folding, dead code elimination, escape analysis).
> Failure modes: megamorphic virtual calls (> 2 implementations, C2 can't inline) degrade to
> vtable dispatch. Thread pool patterns: if a runnable's type varies (new lambda each request),
> the call to `run()` is megamorphic -> C2 falls back to inline cache. Fix: reuse runnable
> instances or use a fixed number of lambda types.

---

### ⚠️ Common Misconceptions

**Misconception: "Java is always slower than C++ because it's bytecode."**
Bytecode is the distribution format. At runtime: JIT-compiled to native code. For long-running
applications (servers): JIT-compiled Java code runs at near-C++ speed for CPU-bound computations.
Differences: (1) Java startup: slower (JIT warmup). (2) C++ can use RAII and custom allocators
(no GC pauses). (3) C++ can vectorize more aggressively (no bounds checks in release builds). But:
for steady-state server workloads, Java JIT-compiled code is 10-20% slower than C++ at worst for
CPU-heavy operations - and often equivalent.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Service is slow immediately after deployment, normalizes after 2-5 minutes.**
```
Symptom: Canary deployment shows elevated p99 latency for first 2-5 minutes.
  Then stabilizes at baseline. Not a memory or GC issue.

Root cause: JVM warmup (JIT not yet compiled hot methods to C2).
  First 10,000 invocations of each method: interpreted or C1.
  After warmup: C2-compiled code, 3-10x faster.
  Visible as: high p99 during "cold" period, then latency drops.

Mitigation options:
  1. WARMUP IN CANARY: send low-percentage traffic to canary for 2-5 minutes
     before routing full traffic. Let it warm up under light load.
  
  2. AOTC (Ahead-of-Time Compilation - experimental):
     GraalVM native image: all code compiled at build time.
     No warmup needed. BUT: AOT requires reflection config, no dynamic
     class loading, longer build time.
  
  3. SPRING AOT (Spring Boot 3.x):
     Pre-generates Spring configuration at build time.
     Reduces warmup for Spring's reflection-heavy startup.
     Not full AOT but reduces warmup time significantly.
  
  4. CDS (Class Data Sharing):
     Share pre-loaded class metadata across JVM starts.
     -Xshare:on  (use CDS archive)
     Reduces class loading overhead, not JIT warmup directly.
  
  5. Manual warmup endpoint: /internal/warmup that calls representative
     operations before the pod is added to the load balancer.
     Kubernetes readinessProbe: /internal/warmup must return 200 first.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Bytecode vs native code | 1 minute |
| Tiered compilation | 2 minutes |
| C2 inlining | 2 minutes |
| Escape analysis | 2 minutes |
| JIT warmup | 1 minute |
| Deoptimization | 1 minute |
| How to check if escape analysis is working | 1 minute |

---

**Q1 (tiers): Walk through the tiered compilation levels.**

A: Level 0: interpreted, every bytecode instruction executed one at a time. No compilation.
Level 3 (C1 with full profiling): after ~2,000 invocations. Compiles to native with profiling
counters inserted (counts invocations, branch frequencies, call targets). Level 4 (C2): after
~10,000 invocations. Uses the C1 profile data to make aggressive optimization decisions. Produces
highly optimized native code. The transition is automatic and transparent to application code.

*What separates good from great:* The C1 profiling data is critical for C2 quality: C2 uses the
branch frequency data to optimize branch prediction (make the common branch fast), uses the call
type data for inlining (inline the 90% common implementation, keep a fallback for the 10%). Without
profiling: C2 would have to be conservative. This is called "profile-guided optimization" (PGO).
PGO in C++ requires a separate compilation step (compile, run with representative workload, recompile
using profile). In Java: happens transparently at runtime. The implication: Java's JIT can optimize
based on the ACTUAL production workload, not a synthetic benchmark used at build time.

---

**Q2 (inlining): What is method inlining and why is it valuable?**

A: Inlining: the JIT replaces a method call with the called method's body, inline in the caller.
Eliminates: stack frame creation, argument passing, return value passing, virtual dispatch.
Enables further optimizations: once the callee is inline, the combined code block can be optimized
as a whole (constants visible, dead branches eliminated). Rule of thumb: methods < 35 bytecodes
are inlined; methods > 325 bytecodes are never inlined (-XX:InlineSmallCode).

*What separates good from great:* The inlining depth limit: `-XX:MaxInlineLevel=9` (default). A call
chain `A -> B -> C -> D -> E` (5 levels): may be fully inlined. A chain `A -> B -> ... -> K` (10+ levels):
the deep calls are not inlined, reverting to regular dispatch. This matters for deeply-nested lambda
chains (Stream pipelines with 10+ operations). Practical implication: Stream pipelines with many
chained operations (`filter.map.filter.flatMap.map.collect`) may hit inlining depth limits and not
get the full optimization benefit. JMH with `-XX:+PrintInlining` can show which calls are inlined
and which are not.

---

**Q3 (escape): Explain escape analysis and when it eliminates heap allocation.**

A: Escape analysis: C2 determines if a newly created object can "escape" its current scope.
Escape: stored in a field accessible to other code, passed to a method that stores it, returned.
No escape: used only within the current method's scope. If no escape: scalar replacement (decompose
the object into local variables). Scalar variables can live on the CPU stack or in registers. Zero
heap allocation, zero GC pressure for that object.

*What separates good from great:* The failure modes for escape analysis: (1) method too large
for inlining (escape analysis works best when the full call graph is inline). (2) Dynamic dispatch
(virtual call): C2 can't always prove which method is called, so can't prove the callee doesn't
store the argument. (3) Lambda captures: `() -> list.add(x)` - the lambda captures a reference
to `x`. C2 may not be able to prove `x` doesn't escape via the lambda. (4) Code paths: if
an object escapes only on the exception path (rare), C2 can still apply scalar replacement on
the happy path. The JMH test: use `-XX:+PrintEscapeAnalysis` to see what C2 identified as non-escaping.

---
