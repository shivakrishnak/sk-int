---
layout: default
title: "Java JVM - L3 Safepoints and Sync"
parent: "Java JVM"
grand_parent: "SK Interview"
nav_order: 9
permalink: /java-jvm/l3-safepoints-and-sync/
render_with_liquid: false
---

# Java JVM - L3 Safepoints and Sync

## JVM Safepoints and Stop-the-World

### 🎯 Model Answer

**30 seconds:**
> A safepoint is a point in a thread's execution where its state is fully known
> to the JVM - the thread can be paused safely for GC, deoptimization, or
> class redefinition. Stop-the-world (STW) means the JVM requests all threads
> to reach a safepoint before proceeding. The pause time = time for the slowest
> thread to reach a safepoint + the STW operation itself. Long "time to safepoint"
> is a common hidden source of pause inflation that doesn't show up in GC work phases.

**3 minutes (Senior):**
> Safepoint mechanism in HotSpot:
> - Each thread has a safepoint "polling" point: a memory read from a special
>   polling page. When the JVM wants a safepoint: it mprotects the polling page
>   (makes it non-readable). The next poll read causes a SIGSEGV -> signal handler
>   -> thread stops at safepoint.
> - Safepoint polls are inserted by the JIT at: method returns, back-edges
>   (loop iterations), and explicit safe points in runtime code.
> - Counted loops (for-loop with int counter): the JIT may hoist the safepoint
>   poll out of the loop (or omit it entirely in old JVMs). A tight counted loop
>   running for 500ms without a safepoint poll = 500ms safepoint delay.
>
> Thread types at safepoint:
> - Running Java thread: must reach a poll point
> - Blocked (monitor, I/O): already at safepoint (blocked threads are always safe)
> - JNI: native code can run, but must not return to Java until safepoint cleared
>   (when the JNI function returns to Java, it's considered at safepoint)
>
> Diagnosis: `-Xlog:safepoint` logs every safepoint with "sync time" (time to bring
> all threads to safepoint) + total STW time. "sync time" >> "total time" = threads
> slow to safepoint.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Safepoint: thread execution point where JVM knows full state.
STW: all threads must reach safepoint. Pause = reach time + GC time.
Counted loop = missing safepoint poll = delay. Fix: UseCountedLoopSafepoints."

**(2) First principles:** "GC needs to read object references in thread stacks.
For this to be correct, the thread must be in a consistent state (not mid-operation).
Safepoints are those consistent states. All threads must be there simultaneously."

**(3) Bridge:** "Safepoints are like fire drill muster points. The fire marshal
(GC) calls a drill. Everyone must go to their muster point. The drill can't start
until the last person arrives. One person in a deep basement (counted loop) delays
everyone else."

---

### 📘 Concept Explanation

**Safepoint mechanics and thread states:**
```
SAFEPOINT STATES:

  Thread Running Java Code:
    Must reach a safepoint poll (inserted by JIT)
    Polls at: method returns, loop back-edges
    When poll: checks if safepoint requested
      Yes: block at poll location -> JVM records stack state
      No: continue

  Thread Blocked (wait, sleep, I/O, monitor):
    Already at safepoint (state is quiescent)
    Does NOT need to "reach" a safepoint
    Can resume immediately after safepoint cleared

  Thread in JNI:
    Native code doesn't need to stop
    CANNOT return to Java code until safepoint cleared
    On native->Java transition: checks safepoint flag

SAFEPOINT TIMING:
  STW request issued
  |
  | <- "time to safepoint" (sync time)
  |    (wait for all running Java threads to poll)
  |
  All threads stopped (JVM proceeds with STW operation)
  |
  | <- STW operation (GC, deoptimization, etc.)
  |
  Threads released

TOTAL PAUSE = time_to_safepoint + stw_operation_time

GC LOGS SHOW:
  [safepoint] Safepoint sync time: 0.0820000 seconds  <- reach time
  [safepoint] Total time for which threads were stopped: 0.0850000 s
  (GC work = 0.0850 - 0.0820 = 0.003 = 3ms, reach time = 82ms!)
```

---

### 💻 Code Example

> **Code walkthrough:** The counted loop issue is the most common cause of
> unexpected safepoint delays. The BAD pattern: a JIT-compiled counted loop
> without safepoint checks can hold the entire JVM for hundreds of milliseconds.
> The diagnostic pattern using safepoint logging reveals this clearly.

```java
// BAD: tight counted loop without safepoint poll
// JIT may compile this without safepoint polls inside the loop
public class ReportProcessor {
    public void processAllRecords(int[] records) {
        // This loop may compile without internal safepoint polls
        // JIT optimization: safepoint poll hoisted out of loop
        // Result: while this runs, GC cannot start -> pause inflation
        int sum = 0;
        for (int i = 0; i < records.length; i++) {  // counted loop!
            sum += records[i];
        }
        // safepoint poll here (after loop)
        // If records.length = 10M and loop body is fast:
        // Thread runs for 50-200ms without safepoint -> STW delay
    }
}

// GOOD: options to add safepoint opportunities
public class ReportProcessor_GOOD {
    // Option 1: use long counter (long loops not subject to same optimization)
    public void processAllRecordsLong(int[] records) {
        int sum = 0;
        for (long i = 0; i < records.length; i++) {  // long loop -> different treatment
            sum += records[(int)i];
        }
    }

    // Option 2: break into chunks (add JVM overhead but add safepoint opportunities)
    public void processInChunks(int[] records) {
        int chunkSize = 10_000;
        int sum = 0;
        for (int i = 0; i < records.length; i += chunkSize) {
            int end = Math.min(i + chunkSize, records.length);
            for (int j = i; j < end; j++) {
                sum += records[j];  // inner loop: short enough for reliable polls
            }
            // outer loop has poll opportunity between chunks
        }
    }

    // Option 3: JVM flag (Java 10+)
    // -XX:+UseCountedLoopSafepoints
    // Adds safepoint polls at counted loop back-edges
    // Overhead: ~1-2% for CPU-bound loops
}

// DIAGNOSIS: identifying safepoint delay source
// 1. Enable safepoint + safepoint-stats logging:
//    -Xlog:safepoint,safepoint+stats:file=safepoint.log:time,uptime,level

// 2. Sample output with safepoint delay:
// [safepoint] Application time: 0.2000000 seconds
// [safepoint] Entering safepoint region: G1CollectForAllocation
// [safepoint] Safepoint sync time: 0.1850000 seconds  <- 185ms! most of pause
// [safepoint] Total time stopped: 0.1870000 seconds

// 3. Find which thread is slow:
//    -Xlog:safepoint+thread=debug
// Output:
// [safepoint+thread] Thread "main" is at unsafe: 0x7f... (loop in ReportProcessor)
// Shows the EXACT thread AND its current instruction

// 4. async-profiler can also profile safepoint-immune code:
//    ./profiler.sh -d 30 -e cpu -f profile.html <pid>
//    Look for: methods with long CPU time that correlate with safepoint delays
```

> **Code walkthrough:** The JVM safepoint logs reveal two numbers: sync time (reach
> time) and total time. When sync time is close to total time: the GC work itself
> was trivial (a few ms) but thread synchronization took 185ms. This is the
> "invisible GC pause" - the application was paused for 185ms but GC metrics only
> show 2ms of actual GC work. Without safepoint logging, this delay is invisible in
> GC analysis.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Safepoint = consistent point in thread execution where GC can inspect thread state.
> STW = all threads must reach a safepoint. Total pause includes time to reach
> safepoint + GC work. Enable `-Xlog:safepoint` to see both times.

---

**Senior / Staff (5+ years):**
> Safepoint latency is a production reality for latency-sensitive services. The trifecta
> of safepoint delay causes: (1) counted loops without polls (fix: UseCountedLoopSafepoints),
> (2) JNI calls taking hundreds of ms (fix: limit JNI scope), (3) sleeping threads
> blocking safepoint (wait, sleep). Profiling: async-profiler in safepoint-immune mode
> (`-e wall` instead of `-e cpu`) captures time spent in code that's blocking safepoints.
> For microservices with GC pause SLAs < 100ms: measure safepoint sync time explicitly.

---

### ⚠️ Common Misconceptions

**Misconception 1: "GC pause time shown in logs = total application pause time."**
GC log shows GC WORK time. Total application pause = safepoint reach time + GC work time.
Safepoint reach time can be 10-100x the GC work time for applications with counted loops
or slow JNI. A GC log showing "5ms GC pause" might mean the application was actually
paused for 100ms (95ms reaching safepoint + 5ms GC work). The complete picture requires
BOTH GC logs (`-Xlog:gc*`) AND safepoint logs (`-Xlog:safepoint`).

**Misconception 2: "Using Thread.sleep() or Object.wait() makes threads safe for safepoints."**
Threads blocked in `wait()`, `sleep()`, or I/O ARE at safepoints - the JVM knows their
state (they're quiescent). This is actually GOOD for safepoint performance: blocked
threads don't slow down safepoint synchronization. The misconception is reversed:
blocked threads help (they're already "stopped"), running threads in tight loops hurt
(they delay safepoints).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Application has 500ms+ pauses but GC logs show < 10ms GC work.**
```
Symptom: P99 latency = 500ms+, GC work phases = 5-10ms, heap healthy
  Users complain about intermittent "lag spikes"
  Monitoring shows regular 500ms hiccups every 30-60 seconds

Investigation:
  Enable: -Xlog:safepoint:file=safepoint.log:time,uptime
  Result:
    [safepoint] Entering safepoint region: RevokeBias
    [safepoint] Safepoint sync time: 0.4950000 seconds  <- 495ms reach time!
    [safepoint] Total time stopped: 0.5000000 seconds

  Not a GC issue! Safepoint sync time = 495ms.

Root cause: JIT-compiled counted loop in business logic
  Find with: -Xlog:safepoint+thread=debug
  Shows: Thread "worker-7" blocked at safepoint in BatchCalculator.sumAll()
  BatchCalculator.sumAll() has a 10M-iteration for-int loop
  JIT compiled without safepoint polls (JDK 8 default behavior)

Fix:
  Option A: -XX:+UseCountedLoopSafepoints (JDK 10+, 1-2% overhead)
  Option B: Change loop counter to long
  Option C: Break loop into chunks with explicit yield points
  Option D: Move to JDK 21 (default loop safepoints improved)

Verification:
  After fix:
  [safepoint] Safepoint sync time: 0.0020000 seconds  <- 2ms reach time
  [safepoint] Total time stopped: 0.0070000 seconds   <- 7ms total (GC work)
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Safepoint definition | 2 minutes |
| How safepoint polling works | 2 minutes |
| Thread states at safepoints | 2 minutes |
| Counted loop problem | 2 minutes |
| Time to safepoint diagnosis | 2 minutes |
| JNI and safepoints | 2 minutes |
| UseCountedLoopSafepoints | 90 seconds |
| async-profiler and safepoint blind spots | 2 minutes |
| Safepoint operations beyond GC | 2 minutes |

---

**Q1 (definition): What is a safepoint in the JVM?**

A: A safepoint is a point in a thread's execution where: (1) the JVM knows the exact
location of all object references (in registers, on the stack), (2) the thread is not
mid-operation on JVM internals, (3) the thread's state can be safely inspected or
modified. At a safepoint: the JVM can walk the thread's stack, update object references
(for GC moving), and change the thread's execution (for deoptimization). Not all points
in code are safepoints - only specifically marked ones.

*What separates good from great:* The JVM needs safepoints for GC but also for: class
redefinition (javaagent bytecode transformation), biased lock revocation, deoptimization
(when JIT assumptions are violated), method profiling samples (some GC profilers require
all threads at safepoints to get accurate stack samples). The term "safepoint" is JVM
internal - application code sees only the "pause." JFR events include safepoint events
that show the reason for the safepoint (GC, deopt, lock revocation, etc.) and duration.

---

**Q2 (polling): How does HotSpot implement safepoint polling?**

A: HotSpot uses a "polling page" mechanism: a specially mapped memory page. When no
safepoint is needed: the page is readable. When a safepoint is requested: the JVM
marks the page as unreadable (mprotect). JIT-compiled code periodically reads from this
page (a load instruction). If the page is unreadable: SIGSEGV is raised. A signal handler
catches it and brings the thread to a safepoint.

*What separates good from great:* The polling page mechanism evolved in JDK 14+ with
"thread-local handshakes" (JEP 312). Previously: a safepoint required ALL threads to
stop simultaneously. With thread-local handshakes: the JVM can suspend one thread
(for deoptimization, stack sampling) without stopping all others. This significantly
reduces the scope of pauses for non-GC safepoint operations. GC still requires all
threads, but deoptimization and lock revocation now use thread-local handshakes
(much cheaper). JDK 15+ also uses per-thread polling pages (each thread reads from
its own page), enabling more targeted thread suspension.

---

**Q3 (operations): What JVM operations require safepoints?**

A: GC (all types: Minor, Mixed, Full, concurrent marking initial+remark phases).
Deoptimization (when JIT's speculative assumptions are violated). Biased lock revocation
(pre-JDK 15). Class redefinition (javaagent transformations, JVM TI). Thread dumps
(`jstack`). Heap dumps (`jcmd GC.heap_dump`). Code cache flush (when JIT code is
invalidated). Profile data collection (some implementations).

*What separates good from great:* Biased locking (pre-JDK 15) caused many unexpected
safepoints. When a biased lock is revoked (another thread tries to acquire it): global
safepoint required to revoke the bias. Applications with many threads contending on
"biased" locks (HashMap, ArrayList, synchronized blocks that are sometimes accessed
by different threads) saw frequent short safepoints for bias revocation. JDK 15
deprecated biased locking (disabled by default in JDK 17). If running on JDK 8-14
with safepoint logs showing "RevokeBias" frequently: upgrade to JDK 17+ to eliminate
those safepoints entirely.

---

**Q4 (counted loops): Why do counted loops cause safepoint delays?**

A: JIT compilers optimize counted loops aggressively (integer overflow detection,
vectorization, loop unrolling). Safepoint poll is inserted at the loop back-edge.
But: for some counted loop forms (int-indexed, simple body), the JIT may hoist the
safepoint poll OUT of the loop body (to just before the loop), or in some JIT versions,
omit it entirely in short loops. Result: the loop runs to completion before the
first safepoint poll. A 100M-iteration loop: 50-500ms runtime without any safepoint
= the GC must wait the full loop duration.

*What separates good from great:* The optimization is not a bug - it's intentional.
Inserting a safepoint poll at every counted loop back-edge adds a conditional branch
per iteration, reducing vectorization opportunities and adding overhead. The JIT trades:
"safepoint responsiveness vs loop throughput." `-XX:+UseCountedLoopSafepoints` (JDK 10+)
forces safepoint polls at counted loop back-edges, guaranteeing responsiveness at a
small cost (~1-2% for CPU-bound loops). The cost is worth it for any service with GC
pause SLAs. JDK 21's JIT improvements reduce the overhead further. As a rule: enable
`UseCountedLoopSafepoints` in any production service with latency requirements.

---

**Q5 (diagnosis): How do you find which code is causing safepoint delays?**

A: (1) Enable `-Xlog:safepoint+thread=debug` -> shows thread name and current bytecode
position at safepoint. (2) async-profiler wall-clock profiling (`-e wall`): captures
samples even in safepoint-immune code. (3) JFR "JavaMonitorEnter" and "SafepointWait"
events. (4) If `-Xlog:safepoint+thread=debug` shows a specific method: inspect it for
counted loops. (5) GC pause histogram: if P99 >> P50 and the spike correlates with
batch processing: counted loop is likely.

*What separates good from great:* async-profiler's `-e wall` (wall clock mode) is
critical for finding safepoint-immune code. Standard CPU profilers using JVMTI work
by: pausing each thread at a safepoint to take a sample. But code in a counted loop
without safepoint polls is "safepoint-immune" - the profiler can't sample it! This
means: the exact code causing the problem is INVISIBLE to standard profilers. async-profiler
uses OS signals (SIGPROF) to interrupt threads regardless of safepoint state, enabling
profiling of safepoint-immune code. Without `-e wall`: the profiler silently misses
the bottleneck.

---

**Q6 (JNI): How does JNI code interact with safepoints?**

A: Native code doesn't have JVM safepoint polls - it can't be stopped at arbitrary
points. JNI code runs concurrently with a STW operation (surprising!). When the JVM
wants a safepoint: JNI threads are "acknowledged" as safe because: the JNI code isn't
manipulating JVM heap. But: the JNI thread CANNOT re-enter Java code during the
safepoint. When JNI native code calls back into Java (upcall): the thread checks the
safepoint flag and blocks until the safepoint is cleared.

*What separates good from great:* Long JNI calls appear as safepoint delay in TOTAL
pause time but NOT in safepoint sync time. The JVM considers the JNI thread "at
safepoint" even while running native code. BUT: if the JNI thread returns to Java
during the safepoint: it blocks (returns immediately, then blocks at the Java
re-entry check). The real problem: JNI frames on the thread stack. At safepoint,
the JVM must "freeze" the JNI frame (record its state). If the JNI call is blocking
(waiting for I/O, mutex): the thread is technically at safepoint but holding
a native frame. This can prevent heap compaction (the GC can't move objects
referenced by JNI local references).

---

**Q7 (long pause): What if safepoints cause latency but GC is fine?**

A: Non-GC safepoint operations: deoptimization (JIT assumption violated),
code cache flush, thread dumps, heap dumps. Each requires all threads at safepoint.
A `jstack` or `jcmd Thread.print` on a production JVM: triggers a safepoint, pausing
all application threads for the duration. If automated monitoring takes a thread dump
every 30 seconds: it causes a STW pause every 30 seconds!

*What separates good from great:* Diagnosing "phantom pauses": use JFR to record
`jdk.SafepointBegin` and `jdk.SafepointEnd` events. Each event includes the "reason"
field: GC, Deoptimize, PrintThreads (thread dump), RevokeBias, etc. If frequent
non-GC safepoints: (1) "PrintThreads" -> your monitoring is taking thread dumps too
frequently; (2) "Deoptimize" -> JIT is frequently invalidating compiled code (check for
polymorphic call sites); (3) "RevokeBias" -> upgrade to JDK 17+ (biased locking removed).

---

**Q8 (virtual threads): How do virtual threads change safepoint behavior?**

A: Virtual threads (JDK 21+) run on carrier threads (platform threads). When a virtual
thread performs a blocking operation (I/O, sleep): it unmounts from the carrier thread.
The carrier thread is a platform thread and participates in safepoints normally.
Virtual thread suspension is managed by JVM, not OS - the JVM knows exactly where the
virtual thread is suspended. For safepoints: carrier threads reach safepoints normally;
suspended virtual threads are considered safe (their state is captured in the JVM's
continuation stack).

*What separates good from great:* Virtual threads dramatically improve safepoint behavior
for I/O-heavy workloads. Traditional thread-per-request (50ms I/O per request, 100 threads):
100 threads participate in safepoints, and 90 of them are blocked in I/O (at safepoints
immediately). With virtual threads: potentially 10000 requests in-flight, but only
N platform threads (carrier threads) participate in safepoints. Fewer platform threads
= fewer threads that need to reach safepoints = lower safepoint sync time. The trade-off:
virtual thread continuations that ARE actively computing (CPU-bound work) are still
subject to the counted loop safepoint problem.

---

**Q9 (overhead): What is the overhead of safepoint polling in Java code?**

A: Safepoint polling is a conditional branch per poll point. The cost: ~1-2 CPU
instructions per method return/loop back-edge. For typical Java code: negligible
(< 0.1% overhead). For tight loops: the poll prevents some JIT optimizations (loop
unrolling, vectorization). `UseCountedLoopSafepoints` adds polls in counted loops:
~1-2% overhead for CPU-bound loop-heavy code. For I/O-heavy code: zero difference
(I/O wait is safepoint by definition).

*What separates good from great:* The polling page mechanism (JDK 9+) is extremely
efficient. The safepoint check is a read from a cached memory page. When no safepoint
is pending: the page is in L1/L2 cache, the read takes 0-4 cycles. The branch predictor
predicts "no safepoint" (it's almost always true). Overhead is < 0.1%. When a safepoint
IS requested: the page protection is changed, the read faults, the handler stops the
thread. This is the "stop on exception" model: zero overhead for the 99.99% case
(no safepoint pending), at the cost of a trap (SIGSEGV) for the 0.01% case (safepoint
requested). JDK 14+ per-thread polling pages improve this further.

---

### ⚖️ Comparison Table

| Safepoint Cause | Frequency | STW Duration | Prevention |
|---|---|---|---|
| GC (Minor) | High | 5-50ms | Tune MaxGCPauseMillis, heap |
| GC (Full) | Rare (ALARM) | Seconds | Fix IHOP, heap sizing |
| Deoptimization | Medium (after warmup) | 1-5ms | Stable class hierarchy |
| Biased lock revocation | High (JDK 8-16) | 1-10ms | Upgrade to JDK 17+ |
| Thread dump (jstack) | Per-use | 5-50ms | Limit monitoring frequency |
| Counted loop delay | Application-specific | 10-500ms+ | UseCountedLoopSafepoints |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: safepoint timing described adequately in Concept Explanation)*

---

---

## JVM Synchronization Internals

### 🎯 Model Answer

**30 seconds:**
> JVM synchronization uses an object's mark word (in the object header) to track
> lock state. Three optimization tiers: biased locking (JDK 8-16: lock owned by
> a thread with no CAS overhead), lightweight locking (CAS on the mark word for
> uncontended access), and heavyweight/inflated locking (OS mutex for contended
> access). Modern JDK 17+: biased locking removed, JEP 374. Understanding
> lock inflation is critical for diagnosing contention.

**3 minutes (Senior):**
> Mark word layout (64-bit JVM, default compressed oops):
> ```
> Unlocked:      [hash: 25 | age: 4 | 0 | 01]
> Biased:        [thread_id: 54 | epoch: 2 | 1 | 01]  (JDK < 17)
> Lightweight:   [stack_ptr: 62 | 00]  (lock record ptr on stack)
> Heavyweight:   [monitor_ptr: 62 | 10]  (ObjectMonitor ptr)
> GC Marked:     [...] 11
> ```
>
> Lock acquisition path (JDK 17+ without biased locking):
> 1. Check: mark word state == unlocked (01)?
> 2. Yes: try CAS(expected=mark_word, new=lock_record_on_stack) -> success = lightweight lock
> 3. CAS fails (another thread took it): spin briefly, then inflate
> 4. Inflate: allocate ObjectMonitor, set mark word to heavyweight (10), block on mutex
>
> ObjectMonitor: contains entry set (threads waiting to acquire), wait set
> (threads in Object.wait()), owner, recursion count.
>
> Contention diagnosis: JFR `JavaMonitorEnter` events (wait time for each lock
> acquisition), async-profiler lock contention profiling.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Mark word = 64 bits in object header. States: unlocked, lightweight
(CAS on stack frame), heavyweight (OS mutex, ObjectMonitor). Lock inflates when CAS
fails (contention). Diagnose with JFR JavaMonitorEnter events."

**(2) First principles:** "synchronized needs mutual exclusion. JVM implements it in
the object header to avoid allocating a separate mutex object for every synchronized
use. Most locks are uncontended - use fast CAS. Contended: use OS mutex (slower but
correct)."

**(3) Bridge:** "JVM locking is like a parking spot. Unoccupied: you just park (mark
word = your stack frame pointer). Someone else arrives while you're there: they wait
in the parking lot queue (heavyweight, OS mutex). When you leave: you release the spot,
notify the next person in queue."

---

### 📘 Concept Explanation

**JVM lock states and mark word:**
```
OBJECT HEADER (64-bit JVM, JDK 17+):
  [  8 bytes mark word  |  4 bytes klass pointer  ]

MARK WORD STATES (JDK 17+, no biased locking):

  UNLOCKED (01 tag):
  +---------+------+-----+--+
  | hashCode| age  | ... |01|  <- identity hash, GC age
  +---------+------+-----+--+

  LIGHTWEIGHT LOCKED (00 tag):
  +-----------------------------------+--+
  | pointer to lock record on stack   |00|
  +-----------------------------------+--+
  Lock record on stack:
    displaced mark word (original mark word backup)
    obj reference

  HEAVYWEIGHT LOCKED (10 tag):
  +-----------------------------------+--+
  | pointer to ObjectMonitor          |10|
  +-----------------------------------+--+
  ObjectMonitor:
    owner: thread currently holding lock
    entry_count: recursion depth
    entry_list: waiting threads (trying to enter)
    wait_set: threads in Object.wait()

LOCK INFLATION SEQUENCE:
  1. Thread A enters synchronized block (object unlocked)
     CAS mark_word: unlocked -> lightweight (A's lock record)
     -> Thread A holds lightweight lock

  2. Thread B tries synchronized block (object lightweight-locked by A)
     B's CAS fails (expected unlocked, got A's lock record)
     -> B spins for a short time (adaptive spinning)
     -> If A releases during spin: B CAS succeeds (fast path)
     -> If A does NOT release: B inflates the lock

  3. Inflation:
     Allocate ObjectMonitor
     Install heavy mark word (pointer to ObjectMonitor)
     ObjectMonitor.owner = Thread A
     Thread B blocks on ObjectMonitor.enter_list (OS park)

  4. Thread A exits synchronized block
     Finds heavyweight mark word
     ObjectMonitor.owner = null
     Notify one waiter (Thread B)
     Thread B wakes, acquires ObjectMonitor
```

---

### 💻 Code Example

> **Code walkthrough:** Lock contention is often hidden behind seemingly simple
> synchronized blocks. The BAD pattern: synchronizing on a shared singleton for
> every operation creates a serialization point. The GOOD pattern: use
> purpose-built concurrency primitives (ConcurrentHashMap, AtomicLong) that avoid
> synchronized blocks entirely or reduce their scope.

```java
// BAD: coarse-grained synchronization - contention bottleneck
class MetricsCollector {
    private final Map<String, Long> counters = new HashMap<>();
    // Single lock for all operations on all counters
    // Every thread blocks on the same lock
    public synchronized void increment(String key) {
        counters.merge(key, 1L, Long::sum);
    }
    public synchronized long get(String key) {
        return counters.getOrDefault(key, 0L);
    }
    // With 100 threads: all block on single monitor
    // ObjectMonitor inflated permanently
    // Throughput: 1 operation at a time
}

// GOOD: non-blocking concurrent alternatives
class MetricsCollector_GOOD {
    // No synchronized -> no lock inflation -> no ObjectMonitor
    // ConcurrentHashMap: per-bucket locking (128 segments)
    // LongAdder: striped counters, no single contention point
    private final ConcurrentHashMap<String, LongAdder> counters
        = new ConcurrentHashMap<>();

    public void increment(String key) {
        counters.computeIfAbsent(key, k -> new LongAdder()).increment();
        // computeIfAbsent: single CAS per existing key
        // LongAdder.increment(): per-thread cell, no global lock
    }

    public long get(String key) {
        LongAdder adder = counters.get(key);
        return adder == null ? 0L : adder.sum();
    }
    // With 100 threads: each writes to its own LongAdder cell
    // Throughput: ~100x better than synchronized version
}

// Diagnosing lock contention with JFR:
// Enable: -XX:+FlightRecorder -XX:StartFlightRecording=duration=60s,
//         filename=recording.jfr,settings=profile

// JFR event "jdk.JavaMonitorEnter":
//   startTime: when thread started waiting for lock
//   duration: how long thread waited
//   monitorClass: class of the object being locked on
//   previousOwner: thread that held the lock before

// Analyzing with JMC (Java Mission Control):
// Open recording -> Event Browser -> JavaMonitorEnter
// Sort by duration -> highest = worst contention bottlenecks
// monitorClass column -> tells you WHICH class is being contended

// async-profiler lock profiling:
// ./profiler.sh -d 60 -e lock -f lock-profile.html <pid>
// Shows: which synchronized methods hold locks longest
// Stack traces: where the lock is being held AND where it's being waited on
```

> **Code walkthrough:** `ConcurrentHashMap` with `LongAdder` is the canonical
> high-throughput counter pattern in Java. `LongAdder` uses "striping" - it maintains
> an array of counters, one per CPU (approximately), and each thread increments its
> own counter. No synchronization needed. On read (sum()): it adds all counters.
> Under contention: 10-50x throughput improvement over `AtomicLong` (which uses
> a single CAS loop). Under no contention: nearly identical to AtomicLong.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> `synchronized` uses the object's header (mark word) to track lock state. Three states:
> unlocked (CAS possible), lightweight (CAS succeeded, stack frame pointer), heavyweight
> (OS mutex, created under contention). JDK 17+ removes biased locking. Contention
> inflates the lock permanently. Use JFR to find contended locks.

---

**Senior / Staff (5+ years):**
> Lock inflation is irreversible (in current JVM): once inflated to heavyweight, stays
> heavyweight for the object's lifetime (unless GC + re-allocation). In contended systems:
> heavyweight locks mean OS context switches (expensive). For lock-intensive hot paths:
> avoid synchronized entirely - use LockFreeStack, ConcurrentHashMap, LongAdder,
> or StampedLock (ReadWriteLock with optimistic reads). For Java 21+ with virtual
> threads: `synchronized` blocks a carrier thread if the virtual thread is pinned
> (holding a monitor). Migrating to `ReentrantLock` instead of `synchronized` unblocks
> the carrier thread (virtual thread remounts on a different carrier).

---

### ⚠️ Common Misconceptions

**Misconception 1: "synchronized is always slower than ReentrantLock."**
Uncontended synchronized: comparable speed to ReentrantLock (both use CAS on mark word
or internal state). Contended synchronized: both use OS mutex (both slow). ReentrantLock
advantage: (1) tryLock(timeout) to avoid deadlocks, (2) fairness option, (3) multiple
Condition variables, (4) virtual thread carrier unpinning (JDK 21+). For uncontended
hot paths: `synchronized` may be FASTER due to JIT-level lock elision optimizations
that don't apply to ReentrantLock. The rule: use synchronized for simplicity,
ReentrantLock for advanced features or virtual thread compatibility.

**Misconception 2: "volatile is a lighter version of synchronized."**
`volatile` and `synchronized` provide different guarantees. `volatile`: visibility (write
immediately visible to all threads) + prevents reordering around the volatile access.
Does NOT provide atomicity for compound operations (read-modify-write). `synchronized`:
visibility + atomicity for the synchronized block. For `i++` on a shared counter:
`volatile int i` is WRONG (non-atomic increment). `synchronized` or `AtomicInteger`
is correct. `volatile` is NOT a "light synchronized" - it's a different mechanism
for a different guarantee (visibility only).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Application throughput collapses under load due to lock contention.**
```
Symptom: TPS drops from 5000 to 50 at high concurrency
  GC is healthy, CPU low (threads are mostly blocked)
  Thread dump: many "BLOCKED" threads on same lock

Diagnosis:
  1. Thread dump (jstack) - fast:
     jcmd <pid> Thread.print | grep -A3 "BLOCKED"
     Look for: many threads "waiting to lock" same monitor
     Output: "locked <0x00000007b40e1150> (a com.example.SomeService)"
     All waiting on same object -> contention confirmed

  2. JFR lock profiling:
     jcmd <pid> JFR.start duration=60s filename=lock.jfr
     jcmd <pid> JFR.stop
     Open in JMC: JavaMonitorEnter events, sort by duration
     Shows: which methods hold the contended lock longest

  3. Find scope of the lock:
     grep -n "synchronized" SomeService.java
     Is it method-level (synchronized on 'this')?
     -> The entire method is critical section: too wide scope

Root cause patterns:
  - synchronized method with I/O inside
    (holds lock while doing I/O -> all other threads blocked for I/O duration)
  - shared mutable state (HashMap, ArrayList) with synchronized method
  - singleton service with synchronized methods

Fix options:
  A. Reduce lock scope: synchronized(lock) { only the critical code }
  B. Replace HashMap with ConcurrentHashMap (removes lock)
  C. Replace synchronized counter with AtomicLong or LongAdder
  D. Use read/write lock: ReadWriteLock or StampedLock (if reads dominate)
  E. Remove shared state: thread-local data, partition by thread
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Mark word states | 2 minutes |
| Lock inflation sequence | 2 minutes |
| Biased locking removal | 2 minutes |
| Lock elision by JIT | 2 minutes |
| ReentrantLock vs synchronized | 2 minutes |
| Diagnosing contention | 2 minutes |
| Virtual threads and monitors | 2 minutes |
| StampedLock | 2 minutes |
| ABA problem | 2 minutes |

---

**Q1 (mark word): What information does the mark word store?**

A: The mark word is 64 bits (8 bytes) in a 64-bit JVM object header. It stores:
lock state (2 bits), identity hash code (25 bits, computed lazily on first hashCode() call),
GC age (4 bits, for generational GC promotion), and depending on lock state: displaced
mark word pointer (lightweight lock), ObjectMonitor pointer (heavyweight), or biased
thread ID + epoch (JDK < 17).

*What separates good from great:* The mark word's "identity hash code" interaction with
locking is subtle. `Object.hashCode()` default: stores the hash in the mark word (lazily).
When an object is locked (lightweight): the mark word is used for the lock record pointer
-> where does the hash go? Answer: it's saved in the displaced mark word (on the stack).
When the lock is released: the displaced mark word (with hash) is restored. This is why:
calling `hashCode()` on an object that has never been hashed, then synchronizing on it,
is safe - the hash is preserved. But: once an object has been synchronized on AND the mark
word is in heavyweight state (ObjectMonitor): the hash is lost from the mark word, stored
in the ObjectMonitor. Objects used as HashMap keys and synchronized on simultaneously:
this complex interaction is managed correctly by HotSpot.

---

**Q2 (elision): Can the JIT eliminate synchronization?**

A: Yes. Lock elision: if the JIT proves an object cannot escape the current thread
(only one thread can ever acquire this lock), it eliminates the lock operations entirely.
Lock coarsening: if two consecutive synchronized blocks on the same object are adjacent:
JIT merges them into one (eliminates lock release + re-acquire in between).

```java
// Lock elision example:
public String buildReport() {
    StringBuffer sb = new StringBuffer(); // StringBuilder is recommended,
    // but let's say legacy code uses StringBuffer
    sb.append("ID: ").append(id).append(", Name: ").append(name);
    return sb.toString();
    // StringBuffer is synchronized. But: 'sb' is local variable.
    // JIT escape analysis: 'sb' doesn't escape this method
    // -> no other thread can synchronize on it
    // -> JIT ELIMINATES all synchronized operations on sb
    // -> StringBuffer as fast as StringBuilder here
}
```

*What separates good from great:* Lock elision requires escape analysis to confirm the
object is thread-local. If the object is passed to a method that the JIT can't inline:
escape analysis fails (JIT can't be sure the method doesn't leak the reference). JIT
inlining and escape analysis work together: more inlining = more opportunity for
elision. In JMH benchmarks of synchronized vs unsynchronized: synchronized methods on
thread-local objects are often identical in performance (elision kicks in under JIT
optimization). In production: JIT inlining is limited by method size and call depth.
Lock elision is more reliable for small, simple methods.

---

**Q3 (virtual threads): How do virtual threads interact with synchronized?**

A: A virtual thread can be "pinned" to its carrier thread by: (1) a `synchronized`
block or method, (2) a native frame (JNI call). While pinned: the carrier thread
cannot unmount and serve other virtual threads. If all carrier threads are pinned:
virtual thread throughput collapses (blocking behavior reverts to platform thread model).

```
Virtual Thread Pinning:
  virtual thread A: enters synchronized block (pin to carrier)
  virtual thread A: performs blocking I/O INSIDE synchronized block
  virtual thread A: tries to unmount (blocked on I/O)
  -> CAN'T unmount (pinned by monitor)
  -> carrier thread BLOCKS on I/O
  -> carrier thread unavailable for other virtual threads
  -> effectively same as platform thread for this operation

Fix: Replace synchronized with ReentrantLock
  virtual thread A: acquires ReentrantLock
  virtual thread A: performs blocking I/O inside lock
  virtual thread A: unmounts (not pinned by ReentrantLock!)
  -> carrier thread picks up other virtual threads
  -> virtual thread A remounts when I/O completes
  -> ReentrantLock re-acquired correctly
```

*What separates good from great:* JDK 21 released virtual threads as GA. JDK 24 is
fixing the pinning issue by making `synchronized` virtual-thread-friendly (Project Loom
follow-up work). For JDK 21/22 production: the guidance is to audit any `synchronized`
block that might perform I/O and replace with `ReentrantLock`. JFR event
`jdk.VirtualThreadPinned` shows when pinning occurs: high frequency or long duration
of this event = significant carrier thread blocking. Spring Framework 6.x, Tomcat 11:
audited their synchronized usage for virtual thread compatibility.

---

**Q4 (biased locking): Why was biased locking removed in JDK 17?**

A: Biased locking (JDK 1.4-16): if a synchronized object is always accessed by the
same thread: bias the lock to that thread, eliminating CAS overhead for the common case.
Problems: (1) safepoint required to revoke bias when another thread tries to acquire
(expensive); (2) revocation is a global safepoint (all threads stop); (3) modern hardware
CAS is fast (original motivation no longer compelling); (4) implementation complexity
is high; (5) bugs and edge cases. JEP 374: deprecated in JDK 15, disabled by default
in JDK 17, fully removed in JDK 21.

*What separates good from great:* For JDK 8 applications with frequent lock contention
changes (one thread owns lock, then another): biased lock revocation storms. Each
revocation: global safepoint. A HashMap being accessed by thread-1 for writes and
thread-2 for reads: frequent revocations. Fix in JDK 8: disable biased locking
(`-XX:-UseBiasedLocking`). This actually IMPROVES performance for mixed-access patterns.
Benchmark: Spring web services on JDK 8, high concurrency - disabling biased locking
often shows 5-15% throughput improvement because it eliminates revocation safepoints.
JDK 17+ upgrade: this is free (biased locking gone, no revocations).

---

**Q5 (deadlock): How do you diagnose deadlock in Java?**

A: Deadlock: Thread A holds lock 1, waits for lock 2. Thread B holds lock 2, waits for
lock 1. Both wait forever. Diagnosis: (1) `jstack <pid>` - Java automatically detects
deadlocks and prints "Found one Java-level deadlock." with the cycle. (2) JFR
`jdk.JavaMonitorDeadlockDetection` event. (3) JMX: `ThreadMXBean.findDeadlockedThreads()`.

*What separates good from great:* JVM's deadlock detection only handles Java monitor
deadlocks (synchronized blocks). JUC lock deadlocks (ReentrantLock): `jstack` detects
these too (thread state shows "waiting on condition" with lock info). But: mixed deadlocks
(one thread holds synchronized, waits on ReentrantLock; another holds ReentrantLock, waits
on synchronized): detection may be incomplete. Prevention is better than detection:
(1) always acquire locks in the same order (consistent lock ordering), (2) use
`tryLock(timeout)` with ReentrantLock to avoid indefinite waiting, (3) use
java.util.concurrent structures that avoid external locking.

---

**Q6 (fair vs unfair): When should you use fair ReentrantLock?**

A: Unfair lock (default): threads compete to acquire the lock when it's released.
The next thread to run (CPU scheduler choice) gets it. May cause thread starvation
for low-priority threads. Throughput: higher (reduced context switching overhead).
Fair lock (`new ReentrantLock(true)`): threads acquire in FIFO order. No starvation.
Throughput: lower (extra overhead to maintain queue order).

*What separates good from great:* Fair locks are rarely the right choice. The overhead
of maintaining strict FIFO ordering: 10-100x more context switches (every acquire:
check the queue, wake the next waiter, which then needs a CPU). For most services:
unfair locking has acceptable fairness properties because thread scheduling is
round-robin at the OS level anyway. Use fair lock when: (1) starvation is a proven
business problem (e.g., high-priority requests starving behind low-priority ones), AND
(2) the lock is contended significantly. Note: Java's PriorityBlockingQueue +
thread pool priorities is usually a better solution than fair locking for priority-based
fairness.

---

**Q7 (StampedLock): When is StampedLock better than ReadWriteLock?**

A: `StampedLock` (Java 8+) provides: read lock, write lock, AND optimistic read
(no lock acquisition, just a version stamp). Optimistic read: read the data, check
if the stamp is still valid (no writer intervened). If valid: no lock overhead.
If invalid: fall back to read lock. Use StampedLock when: reads heavily dominate
(95%+ reads), writes are rare and short, and the read operation is short (validate
quickly after reading).

```java
StampedLock lock = new StampedLock();
double x, y;

// Optimistic read - no lock!
double read() {
    long stamp = lock.tryOptimisticRead();
    double currentX = x;
    double currentY = y;
    if (!lock.validate(stamp)) {
        // Writer intervened - fall back to real read lock
        stamp = lock.readLock();
        try {
            currentX = x;
            currentY = y;
        } finally {
            lock.unlockRead(stamp);
        }
    }
    return Math.sqrt(currentX*currentX + currentY*currentY);
}
```

*What separates good from great:* StampedLock is NOT reentrant. A thread that already
holds a write lock cannot acquire a read lock (unlike ReentrantReadWriteLock).
This causes deadlock if not careful. Also: StampedLock doesn't implement Lock/ReadWriteLock
interfaces - cannot be used as a drop-in replacement. The performance advantage:
in a read-dominated scenario (99% reads), StampedLock optimistic reads have zero
contention overhead (just 2 instructions: get stamp, validate). ReadWriteLock:
still requires memory barriers for the read lock (even though multiple reads can proceed).
For point reads on a shared structure with rare updates: StampedLock is 2-5x faster
than ReadWriteLock.

---

**Q8 (volatile vs sync): What is the difference between volatile and synchronized?**

A: `volatile`: guarantees (1) visibility - writes immediately visible to all threads,
(2) happens-before ordering - operations before a volatile write are visible to
code after a volatile read of the same variable. Does NOT guarantee atomicity of
compound operations. `synchronized`: guarantees (1) visibility (memory barrier at
enter/exit), (2) atomicity (only one thread in the block), (3) mutual exclusion.
Use `volatile` for: flags, status variables, single-value reads/writes. Use `synchronized`
or `java.util.concurrent` for: compound check-then-act, multi-variable consistency.

*What separates good from great:* The subtle `volatile` atomicity guarantee: for 32-bit
types (int, float): reads and writes are atomic even without volatile (JMM guarantees
atomicity for 32-bit primitives). For 64-bit types (long, double): reads and writes
are NOT atomic without volatile (32-bit JVM may split the write into two 32-bit operations).
`volatile long` and `volatile double` guarantee atomic reads/writes for 64-bit types.
`AtomicLong` vs `volatile long`: AtomicLong provides CAS (`compareAndSet`) for compound
operations; `volatile long` provides only visibility. For counters: use AtomicLong or
LongAdder. For flags: use `volatile boolean`.

---

**Q9 (avoid sync): What are the main strategies to reduce synchronization in Java?**

A: (1) Immutability: immutable objects need no synchronization (safe publication
guarantees). (2) Thread confinement: each thread owns its data, no sharing needed.
(3) CAS-based operations: `AtomicLong`, `AtomicReference`, `ConcurrentHashMap` use
hardware CAS instead of OS locks. (4) Partitioning: shard data by thread/request ID
to eliminate cross-thread contention. (5) Copy-on-write: `CopyOnWriteArrayList` for
read-heavy collections. (6) Off-heap data (Disruptor, Chronicle Map): structured
buffers with controlled access patterns.

*What separates good from great:* The LMAX Disruptor pattern: a ring buffer with
per-producer/consumer head/tail pointers (no locks, just CAS on the pointers + memory
barriers). Under extreme throughput (millions of events/second): synchronized queues
(LinkedBlockingQueue) are 10-100x slower than a Disruptor. The Disruptor eliminates:
lock contention (CAS only), thread wake-up overhead (producers/consumers busy-wait
or yield instead of park/unpark), memory allocation (pre-allocated ring buffer entries).
For most applications: `LinkedBlockingQueue` is perfectly fine. For ultra-low-latency
trading, gaming, or high-throughput pipelines: the Disruptor pattern is proven and
battle-tested.

---

### ⚖️ Comparison Table

| Lock Type | Contention Handling | Reentrancy | Fairness | Best Use Case |
|---|---|---|---|---|
| synchronized | OS mutex (inflated) | Yes | No (unfair) | Simple mutual exclusion |
| ReentrantLock | OS mutex (park/unpark) | Yes | Optional | Advanced features, virtual threads |
| ReadWriteLock | Shared read, exclusive write | Yes | Optional | Read-heavy shared state |
| StampedLock | Optimistic read (no lock) | NO | No | Read-dominated, short reads |
| AtomicLong/Ref | CAS (no OS mutex) | N/A | N/A | Single-variable compound ops |
| LongAdder | Striped CAS | N/A | N/A | High-contention counters |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: lock state transitions described adequately in Concept Explanation)*
