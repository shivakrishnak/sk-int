---
layout: default
title: "Java Concurrency - L0 Orientation"
parent: "Java Concurrency"
nav_order: 1
permalink: /java-concurrency/l0-orientation/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Concurrency vs Parallelism](#concurrency-vs-parallelism) | high |
| 2 | [Java Concurrency Overview](#java-concurrency-overview) | high |
| 3 | [Thread Lifecycle](#thread-lifecycle) | high |
| 4 | [Race Conditions and Thread Safety](#race-conditions-and-thread-safety) | high |

---

# Concurrency vs Parallelism

**Interview Weight:** high - The foundational vocabulary question.
Interviewers use this to gauge whether you have a mental model
or just memorized definitions.

---

### 🎯 Model Answer

**30 seconds:**

> Concurrency is about dealing with multiple things at once -
> structure and coordination. Parallelism is about doing multiple
> things at once - execution and throughput. A single-core CPU
> can run concurrent code (interleaving threads) but cannot run
> parallel code (simultaneous execution). A multi-core CPU can
> do both. Java supports concurrency via threads; parallelism
> via parallel streams, ForkJoinPool, and virtual threads.

**3 minutes (Senior):**

> The distinction matters for design decisions. A web server that
> handles 10,000 requests is concurrent - requests interleave on
> a thread pool. Whether it is parallel depends on how many CPU
> cores are actively computing simultaneously. An application can
> be concurrent without being parallel (single-threaded event loop
> like Node.js), parallel without being concurrent (SIMD vector
> operations on a single data stream), or both.
>
> For Java specifically: the `Thread` and `ExecutorService` APIs
> provide concurrency. `ForkJoinPool` and parallel streams provide
> parallelism (dividing work across cores). Virtual threads (Java 21)
> enable millions of concurrent tasks but do not increase parallelism
> beyond the number of physical CPU cores.
>
> The practical implication: if your bottleneck is CPU computation,
> parallelism helps (parallel streams, ForkJoinPool). If your
> bottleneck is I/O wait (database, network), concurrency helps
> (more threads or virtual threads waiting simultaneously without
> consuming CPU). Applying parallelism to I/O-bound work wastes
> CPU; applying extra concurrency to CPU-bound work creates
> context-switching overhead without speedup.

**Framework:** STRUCTURE (concurrency) vs EXECUTION (parallelism)
→ CPU-BOUND (parallelism) vs IO-BOUND (concurrency) →
JAVA MECHANISM (threads, ForkJoin, virtual threads)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the difference between
concurrency and parallelism."

**(2) First principles:** "Concurrency: multiple tasks that can
progress in overlapping time periods. Parallelism: multiple tasks
executing at the exact same instant."

**(3) Analogy:** "Concurrency is a coffee shop with one barista
juggling orders. Parallelism is a coffee shop with 8 baristas
each making a different drink simultaneously."

---

### 📘 Concept Explanation

**What it is:**

- **Concurrency**: composing multiple sequential processes so they
  can make progress in overlapping time frames. About program
  structure and design.
- **Parallelism**: executing multiple computations simultaneously
  on multiple processors. About execution and performance.

**How it works:**

```
  CONCURRENCY (1 core, 2 threads - interleaving):
  Core 0: [Thread A]-[Thread B]-[Thread A]-[Thread B]-...
           ^ OS scheduler switches every ~1-100ms

  PARALLELISM (2 cores, 2 threads - simultaneous):
  Core 0: [Thread A runs continuously]
  Core 1: [Thread B runs continuously]

  BOTH (2 cores, 100 threads):
  Core 0: [T1]-[T2]-[T3]-...[T50]  ← concurrent on one core
  Core 1: [T51]-[T52]-...[T100]    ← concurrent on another core
          ← parallel across cores
```

**The key insight:**

Java threads are concurrent by definition (the OS scheduler
interleaves them). Whether they are parallel depends on whether
multiple cores are available AND the JVM/OS assigns them to
different cores. In practice, an `ExecutorService` with
`nThreads = Runtime.getRuntime().availableProcessors()` maximizes
parallelism for CPU-bound work.

**When to use it:**

- CPU-bound tasks: use parallelism (`parallelStream()`,
  `ForkJoinPool`, thread count = CPU cores)
- I/O-bound tasks: use concurrency (more threads or virtual threads
  waiting without consuming CPU)
- Mixed workloads: separate thread pools by task type

---

### 💻 Code Example

**Example 1: Parallelism for CPU-bound vs concurrency for I/O-bound**

```java
// CPU-BOUND: Use parallelism (thread count = CPU cores)
int cpuCores = Runtime.getRuntime().availableProcessors();
List<Result> results = dataList.parallelStream()   // uses ForkJoinPool
    .map(item -> expensiveComputation(item))       // CPU-saturating
    .collect(Collectors.toList());
// More threads than CPU cores would cause context-switching overhead

// I/O-BOUND: Use concurrency (many threads waiting)
ExecutorService ioPool = Executors.newFixedThreadPool(
    cpuCores * 10   // 10x multiplier for I/O blocking time ratio
);
// Or with Java 21 virtual threads - unlimited concurrency for I/O:
ExecutorService virtualPool = Executors.newVirtualThreadPerTaskExecutor();
List<Future<String>> futures = new ArrayList<>();
for (String url : urls) {
    futures.add(virtualPool.submit(() -> fetch(url)));  // blocks on I/O
}
// Even if fetch() blocks for 100ms, the thread (virtual) is
// parked, not consuming OS thread resources
```

> **Code walkthrough:** `parallelStream()` uses the ForkJoinPool
> with parallelism = CPU count, ideal for CPU-saturating work.
> Adding more threads than cores creates context-switching overhead
> with no speedup. For I/O-bound work, the thread is blocked waiting
> for network/disk - virtual threads park cheaply, allowing millions
> of concurrent I/O waits with minimal OS thread consumption.

---

### ⚖️ Comparison

| | Concurrency | Parallelism |
|--|-------------|-------------|
| Focus | Structure, coordination | Execution speed |
| Hardware needed | Any (even single-core) | Multi-core |
| Java API | Thread, ExecutorService | parallelStream, ForkJoinPool |
| Best for | I/O-bound, interactive | CPU-bound computation |
| Overhead | Context switching | Synchronization, data division |
| Measure of success | Responsiveness, throughput | CPU utilization, speedup |

**The deciding factor:** Identify the bottleneck first. I/O wait
→ concurrency. CPU computation → parallelism. Never apply parallelism
to I/O-bound code; never use unlimited threads for CPU-bound work.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Concurrency means multiple tasks can be in progress at the same
> time, even on a single core (via interleaving). Parallelism means
> multiple tasks run at the exact same time on multiple cores. Java
> supports both: threads for concurrency, parallel streams and
> ForkJoinPool for parallelism.

---

**Senior / Staff (5+ years):**

> Concurrency is a design property; parallelism is a hardware
> property. I decide which to use based on the workload. For the
> web tier handling 10,000 requests/second with database I/O,
> I use concurrency (thread pool or virtual threads - the bottleneck
> is DB latency). For batch data processing (transforming records),
> I use parallelism (parallel streams, ForkJoinPool). Mixing them
> up is a common mistake: running a parallel stream on I/O-bound
> code starves the common pool for other parallel operations without
> improving I/O throughput.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between concurrency and parallelism?"

🗣️ "Concurrency is about program structure - having multiple tasks
that can make progress in overlapping time periods, even on a single
CPU via interleaving. Parallelism is about simultaneous execution -
multiple tasks running at the exact same instant on multiple cores.
A single-core machine can run concurrent code but not parallel code.
In Java: threads give concurrency, parallel streams and ForkJoinPool
give parallelism."

#### Decision

- "When would you use parallel streams vs a regular thread pool?"

🗣️ "Parallel streams for CPU-bound, embarrassingly parallel data
processing where the data is already in memory. The ForkJoinPool
automatically scales to CPU count. I avoid parallel streams for
I/O-bound work (like calling a database per element) - it blocks
the common pool and starves other parallel operations. I use a
dedicated thread pool or virtual threads for I/O-bound concurrency."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Precise definitions, hardware relationship. |
| Hiring Manager   | When each is appropriate - practical judgment. |
| Bar Raiser       | Virtual threads and the future of Java concurrency. |
| Peer Engineer    | "We accidentally used parallelStream() for DB calls and degraded performance..." |

---

---

# Java Concurrency Overview

**Interview Weight:** high - Ecosystem map question. Tests
whether you know the full Java concurrency toolbox and can
choose the right tool.

---

### 🎯 Model Answer

**30 seconds:**

> Java's concurrency toolkit has three layers: (1) Low-level
> primitives - `Thread`, `synchronized`, `volatile`, `wait/notify`.
> (2) High-level utilities - `java.util.concurrent`: `ExecutorService`,
> `Lock`, `Semaphore`, `CountDownLatch`, `CompletableFuture`.
> (3) Concurrent data structures - `ConcurrentHashMap`,
> `BlockingQueue`, `CopyOnWriteArrayList`. Prefer the high-level
> utilities; use low-level primitives only when you understand
> exactly what you are doing.

**3 minutes (Senior):**

> The evolution of Java concurrency shows the progression from
> painful to practical. Java 1.0 had `Thread` and `synchronized` -
> powerful but easy to misuse. Java 5 added `java.util.concurrent`
> (JSR-166, Doug Lea) - `ExecutorService`, `ReentrantLock`,
> `AtomicInteger`, `ConcurrentHashMap`, `BlockingQueue`. Java 8
> added `CompletableFuture` for async composition. Java 21 added
> virtual threads (Project Loom) - the biggest change since Java 5.
>
> The guiding principle: avoid shared mutable state. Every approach
> to concurrency reduces to managing shared mutable state: (1) Don't
> share it - thread-local or message-passing models. (2) Don't make
> it mutable - immutable objects. (3) If you must share mutable
> state, synchronize access - locks, atomic operations, or concurrent
> collections.
>
> In production, 90% of concurrency is covered by three patterns:
> `ExecutorService` for managed thread pools, `CompletableFuture`
> for async pipelines, and `ConcurrentHashMap`/`BlockingQueue` for
> shared data structures. `synchronized` and `volatile` appear in
> legacy code and library internals; new code rarely needs them.

**Framework:** THREAD PRIMITIVES → JUC HIGH-LEVEL (Java 5) →
ASYNC COMPOSE (Java 8) → VIRTUAL THREADS (Java 21) →
PRINCIPLE: AVOID SHARED MUTABLE STATE

**Blank Mind Recovery:**

**(1) Restate:** "You are asking for an overview of Java's
concurrency tools and ecosystem."

**(2) Structure:** "Low-level (Thread, synchronized), mid-level
(ExecutorService, locks, semaphores), high-level (CompletableFuture),
data structures (concurrent collections)."

---

### 📘 Concept Explanation

**What it is:**

The `java.util.concurrent` package (JUC, Java 5) provides thread-
safe data structures, synchronization utilities, executor framework,
and atomic variables. Package `java.util.concurrent.locks` adds
`Lock` and `ReadWriteLock`. `java.util.concurrent.atomic` adds
non-blocking atomic operations.

**Key API map:**

```
  java.util.concurrent:
  ├── Executors       (ThreadPoolExecutor, ForkJoinPool)
  ├── Locks           (ReentrantLock, ReadWriteLock, StampedLock)
  ├── Synchronizers   (Semaphore, CountDownLatch, CyclicBarrier, Phaser)
  ├── Futures         (Future, CompletableFuture, FutureTask)
  ├── Queues          (ArrayBlockingQueue, LinkedBlockingQueue,
  │                    ConcurrentLinkedQueue, DelayQueue)
  └── Maps/Lists      (ConcurrentHashMap, CopyOnWriteArrayList,
                       ConcurrentLinkedDeque)
  
  java.util.concurrent.atomic:
  └── AtomicInteger, AtomicLong, AtomicReference, AtomicBoolean,
      LongAdder, LongAccumulator (high-contention counters)
```

**The key insight:**

Always prefer the highest-level abstraction that solves your problem.
Use `CompletableFuture` over `Future`. Use `ConcurrentHashMap` over
`HashMap + synchronized`. Use `AtomicInteger` over `synchronized int`.
Use `BlockingQueue` for producer-consumer instead of `wait/notify`.
Each higher-level abstraction eliminates a category of concurrency bugs.

---

### 💻 Code Example

**Example 1: Choosing the right tool**

```java
// BAD: Manual Thread management - error-prone, no reuse
Thread t = new Thread(() -> process(task));
t.start();
try { t.join(); } catch (InterruptedException e) { /* handle */ }

// BAD: synchronized + wait/notify for producer-consumer
// complex, error-prone, easy to forget notify or have spurious wakeup

// GOOD: ExecutorService for task submission
ExecutorService pool = Executors.newFixedThreadPool(4);
Future<Result> future = pool.submit(() -> compute(task));
Result result = future.get(5, TimeUnit.SECONDS);  // with timeout

// GOOD: CompletableFuture for async composition
CompletableFuture<String> cf = CompletableFuture
    .supplyAsync(() -> fetchUser(userId))      // async
    .thenApply(user -> enrichWithProfile(user)) // chain
    .thenApply(enriched -> serialize(enriched));// transform

// GOOD: BlockingQueue for producer-consumer
BlockingQueue<Task> queue = new LinkedBlockingQueue<>(100);
// Producer: queue.put(task)   - blocks when full
// Consumer: queue.take()      - blocks when empty

// GOOD: ConcurrentHashMap for thread-safe map operations
ConcurrentHashMap<String, Integer> counts = new ConcurrentHashMap<>();
counts.merge("key", 1, Integer::sum);  // atomic increment
counts.computeIfAbsent("key", k -> expensiveCompute(k)); // atomic
```

> **Code walkthrough:** Manual `Thread` management creates one-off
> threads without pooling - wasteful and unmanageable. The `ExecutorService`
> manages a reusable pool with shutdown lifecycle. `CompletableFuture`
> chains async operations without blocking. `BlockingQueue` replaces
> `wait/notify` for producer-consumer with built-in back-pressure.
> `ConcurrentHashMap.merge()` and `computeIfAbsent()` provide atomic
> compound operations that `HashMap + synchronized` cannot guarantee.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Java concurrency has three layers: `Thread`/`synchronized` (low-
> level), `java.util.concurrent` with `ExecutorService`, locks, and
> `CompletableFuture` (mid-level), and concurrent collections like
> `ConcurrentHashMap` and `BlockingQueue`. Use the highest-level API
> that fits the problem.

---

**Senior / Staff (5+ years):**

> My first preference is eliminating shared mutable state: immutable
> objects, message-passing, or actor models. When shared state is
> unavoidable, I reach for `ConcurrentHashMap` or `BlockingQueue`
> before any custom locking. For async coordination, `CompletableFuture`
> handles most cases. `synchronized` and `volatile` appear in my
> code only for performance-critical low-level structures where I
> need exact memory ordering control.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is in java.util.concurrent?"

🗣️ "`java.util.concurrent` (JUC, Java 5) provides the high-level
concurrency toolkit: Executor framework (`ExecutorService`,
`ThreadPoolExecutor`, `ForkJoinPool`) for managed thread pools;
synchronizers (`CountDownLatch`, `CyclicBarrier`, `Semaphore`,
`Phaser`) for thread coordination; `BlockingQueue` implementations
for producer-consumer; `ConcurrentHashMap`, `CopyOnWriteArrayList`
for thread-safe collections; `Future` and `CompletableFuture` for
async computation. The `atomic` sub-package provides lock-free
atomic operations. Together these cover 95% of production
concurrency needs."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | JUC package structure, major classes. |
| Hiring Manager   | When to use which tool. |
| Bar Raiser       | Virtual threads (Java 21), Loom impact on the toolkit. |
| Peer Engineer    | "Choosing between ReentrantLock and synchronized in production..." |

---

---

# Thread Lifecycle

**Interview Weight:** high - Foundational state machine question.
Interviewers check whether you know BLOCKED vs WAITING vs
TIMED_WAITING - a common misconception area.

---

### 🎯 Model Answer

**30 seconds:**

> A Java thread has 6 states: `NEW` (created, not started), `RUNNABLE`
> (running or ready to run), `BLOCKED` (waiting for a monitor lock
> - `synchronized` block), `WAITING` (indefinitely waiting for
> another thread - `Object.wait()`, `Thread.join()`), `TIMED_WAITING`
> (waiting for a duration - `Thread.sleep()`, `Object.wait(timeout)`),
> `TERMINATED` (finished). The BLOCKED/WAITING distinction is
> important: BLOCKED = waiting for a lock; WAITING = waiting for
> a signal from another thread.

**3 minutes (Senior):**

> The lifecycle states matter for debugging. When you take a thread
> dump, threads in `BLOCKED` state indicate lock contention - you
> need to find who holds the lock. Threads in `WAITING` state
> indicate coordination (expected behavior in thread pools) or
> deadlock (unexpected). Threads in `RUNNABLE` might actually be
> executing or might be waiting for CPU scheduling - the OS-level
> distinction is invisible to the JVM.
>
> `BLOCKED` can only occur with `synchronized` - when a thread
> tries to enter a synchronized block/method and the monitor is held
> by another thread. With `ReentrantLock`, the thread calls
> `lock.lock()` and blocks inside a `WAITING` state (the park
> operation), not `BLOCKED`. This is a critical distinction for
> thread dumps: a thread waiting on a `ReentrantLock` appears as
> `WAITING`, not `BLOCKED`.
>
> Thread creation is expensive (~1MB stack allocation per OS thread).
> Always use thread pools. When a task submitted to a pool waits
> in the queue before execution, it is not consuming a thread at
> all - the task is in the queue while pool threads are in
> `RUNNABLE` (busy) or `WAITING` (idle, waiting for the next task).

**Framework:** NEW → RUNNABLE → BLOCKED/WAITING/TIMED_WAITING
→ RUNNABLE → TERMINATED

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the states a Java thread
can be in and the transitions between them."

**(2) First principles:** "A thread can be: not started, running,
blocked on a lock, waiting for a signal, waiting for time to pass,
or finished."

---

### 📘 Concept Explanation

**What it is:**

`Thread.State` enum (6 states) representing the lifecycle of a
Java thread as visible to the JVM. Observable via
`Thread.getState()` and thread dumps (`jstack`, JFR, VisualVM).

**State machine:**

```
  ┌──────┐  start()   ┌──────────┐
  │ NEW  │──────────→ │ RUNNABLE │ ←─────────────────────┐
  └──────┘            └──────────┘                       │
                       │  │  │                           │
         synchronized  │  │  │  Object.wait()      lock acquired /
         block lock    │  │  │  Thread.join()      notify() received
         contention    │  │  │  LockSupport.park() /
                       │  │  │  CompletableFuture  │
                       ↓  │  ↓                     │
                 ┌─────────┐ ┌─────────────┐       │
                 │ BLOCKED │ │   WAITING   │───────┘
                 └─────────┘ └─────────────┘
                             ┌─────────────────┐
                   sleep()   │ TIMED_WAITING   │───────→ back to RUNNABLE
                   wait(ms)  └─────────────────┘        when time expires
                             
                         run() completes
                   RUNNABLE ──────────────→ ┌────────────┐
                                            │ TERMINATED │
                                            └────────────┘
```

**The key insight:**

BLOCKED = waiting for a `synchronized` monitor lock specifically.
WAITING = waiting for an explicit signal (notify, interrupt, unpark).
TIMED_WAITING = waiting for a duration. Confusing BLOCKED and
WAITING leads to wrong diagnosis in thread dumps.

---

### 💻 Code Example

**Example 1: Observing thread states**

```java
Object lock = new Object();
Thread t1 = new Thread(() -> {
    synchronized (lock) {
        System.out.println("T1 holds lock");
        try { Thread.sleep(5000); } // T1 goes TIMED_WAITING (sleep)
        catch (InterruptedException e) { Thread.currentThread().interrupt(); }
    }
});

Thread t2 = new Thread(() -> {
    synchronized (lock) { // T2 goes BLOCKED waiting for T1's lock
        System.out.println("T2 acquired lock");
    }
});

t1.start();
Thread.sleep(100);  // let T1 acquire the lock first
t2.start();
Thread.sleep(100);  // let T2 try to acquire

System.out.println("T1 state: " + t1.getState()); // TIMED_WAITING
System.out.println("T2 state: " + t2.getState()); // BLOCKED

// ReentrantLock: t2 would show WAITING, not BLOCKED
ReentrantLock rl = new ReentrantLock();
Thread t3 = new Thread(() -> rl.lock());
// t3 waiting on ReentrantLock → WAITING state (LockSupport.park)
```

> **Code walkthrough:** `t1` is in `TIMED_WAITING` because it called
> `Thread.sleep()`. `t2` is in `BLOCKED` because it is trying to
> enter a `synchronized(lock)` block that `t1` holds. This is the
> precise BLOCKED state. If the same scenario used `ReentrantLock`,
> `t2` would show `WAITING` instead of `BLOCKED` - because
> `ReentrantLock` uses `LockSupport.park()` internally.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Java threads have 6 states: NEW, RUNNABLE, BLOCKED, WAITING,
> TIMED_WAITING, TERMINATED. BLOCKED means waiting for a synchronized
> lock. WAITING means waiting for a signal from another thread
> (Object.wait, Thread.join). TIMED_WAITING is waiting for a time
> period (Thread.sleep, wait with timeout).

*Push deeper:* What tool would you use to see thread states in production.

---

**Senior / Staff (5+ years):**

> Thread state visibility is a debugging tool. In thread dumps
> (`jstack`), many BLOCKED threads pointing at the same lock
> indicates lock contention. Many WAITING threads is normal for
> idle thread pool threads. A thread permanently in WAITING
> (especially if paired with another thread permanently in WAITING)
> indicates deadlock. I use Java Flight Recorder thread state
> charts to see state transition patterns over time, which reveals
> lock starvation and pool saturation before they become incidents.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between BLOCKED and WAITING state?"

🗣️ "BLOCKED means the thread is waiting to acquire a `synchronized`
monitor lock - it tried to enter a `synchronized` block or method
and the monitor is held by another thread. WAITING means the thread
is waiting for another thread to explicitly notify it - it called
`Object.wait()`, `Thread.join()`, or `LockSupport.park()`. The
practical difference: BLOCKED in a thread dump always means lock
contention on a synchronized block. WAITING could mean expected
coordination (thread pool idle) or a deadlock."

#### Debugging

- "You see many threads in BLOCKED state in a thread dump.
  What do you do?"

🗣️ "First: find the thread that owns the lock that all these
threads are waiting for. Thread dumps show the lock address and
the thread holding it. Second: look at that thread's stack trace -
what is it doing? If it is also BLOCKED waiting for another lock,
that is a deadlock. If it is in a slow operation (database call,
network), that is lock contention under a critical section that
is too wide. The fix: narrow the synchronized block, use
`ConcurrentHashMap` instead of synchronizing the whole map, or
use `ReadWriteLock` to allow concurrent reads."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | All 6 states, BLOCKED vs WAITING distinction. |
| Hiring Manager   | Thread dump interpretation in production. |
| Bar Raiser       | LockSupport.park, ReentrantLock state distinction. |
| Peer Engineer    | "jstack showed 200 threads BLOCKED on our HashMap synchronization..." |

---

---

# Race Conditions and Thread Safety

**Interview Weight:** high - Core correctness concept. Interviewers
use this to test whether you think about shared state, memory
visibility, and atomic operations as a unit.

---

### 🎯 Model Answer

**30 seconds:**

> A race condition occurs when the correctness of a program depends
> on the relative timing or interleaving of operations from multiple
> threads. It happens when: multiple threads share mutable state AND
> at least one thread modifies it AND the operations are not atomic.
> Thread safety means a class behaves correctly when accessed from
> multiple threads without requiring additional synchronization from
> the caller.

**3 minutes (Senior):**

> Race conditions are hard to reproduce because they are timing-
> dependent. The classic example: `count++` is three operations
> (read, increment, write). If two threads execute them concurrently
> without synchronization, both may read the same value, both
> increment it, and write back the same result - the counter
> increments by 1 instead of 2.
>
> Thread safety has three dimensions: (1) Atomicity - compound
> operations must be indivisible (read-modify-write of a shared
> variable). (2) Visibility - when one thread writes to a variable,
> other threads must eventually see the updated value (the Java
> Memory Model allows caching values in CPU registers/caches).
> (3) Ordering - the compiler and CPU can reorder instructions for
> performance; `volatile` and `synchronized` establish
> happens-before relationships that prevent reordering of visible
> state.
>
> Approaches to thread safety in order of preference: (1) Don't
> share state (thread-local, immutable, or message-passing). (2)
> Use concurrent collections (`ConcurrentHashMap` vs synchronized
> map). (3) Use atomic operations (`AtomicInteger.incrementAndGet()`
> vs `synchronized int++`). (4) Use locks for compound operations
> that involve multiple fields.

**Framework:** DEFINITION (timing-dependent correctness) → CAUSES
(atomicity, visibility, ordering) → DETECTION (thread dumps,
stress tests, race detectors) → FIX (don't share / concurrent
types / atomic / locks)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about race conditions - when does
shared mutable state lead to incorrect behavior in concurrent code?"

**(2) First principles:** "Two threads modifying the same value
simultaneously without coordination = undefined result."

---

### 📘 Concept Explanation

**What it is:**

A race condition is a correctness defect where the output depends
on which thread runs which instruction in what order. Thread safety
is the property of code that behaves correctly regardless of thread
interleaving.

**Three root causes:**

```
  1. ATOMICITY FAILURE (check-then-act, read-modify-write)
     if (map.containsKey(k)) map.put(k, v);  ← two ops, not atomic
     count++;                                 ← three ops: R-M-W

  2. VISIBILITY FAILURE (CPU cache, JIT optimization)
     boolean running = true;  // Thread A reads cached 'true' forever
     // Thread B sets running = false but Thread A doesn't see it
     // Fix: volatile boolean running = true;

  3. ORDERING FAILURE (compiler/CPU reordering)
     instance = new Singleton();
     // CPU may: allocate memory, assign to 'instance', then construct
     // Another thread sees non-null instance before constructor completes
     // Fix: volatile instance (prevents the reorder)
```

**The key insight:**

`synchronized` solves all three: atomic (only one thread in block),
visible (exits flush to main memory), ordered (happens-before).
`volatile` solves visibility and ordering but NOT atomicity.
`AtomicInteger` solves all three for single-variable operations
using CAS (compare-and-swap) hardware instructions.

---

### 💻 Code Example

**Example 1: Race condition and fixes**

```java
// BAD: Classic race condition on counter
public class UnsafeCounter {
    private int count = 0;

    public void increment() {
        count++;  // NOT ATOMIC: read, add 1, write
    }              // Two threads may both read 5, both write 6

    public int get() { return count; }
}

// GOOD: Fix with AtomicInteger (lock-free, CAS-based)
public class SafeCounter {
    private final AtomicInteger count = new AtomicInteger(0);

    public void increment() { count.incrementAndGet(); }  // atomic CAS
    public int get() { return count.get(); }
}

// GOOD: Fix with synchronized (heavier but correct for compound ops)
public class SynchronizedCounter {
    private int count = 0;

    public synchronized void increment() { count++; }
    public synchronized int get() { return count; }
}

// BAD: Check-then-act race condition (common in lazy init)
if (instance == null) {                   // Thread A checks: null
    instance = new ExpensiveObject();     // Thread B also checks: null
}                                         // Both create the object!

// GOOD: Double-checked locking with volatile (Java 5+)
private volatile ExpensiveObject instance;  // volatile prevents reorder

public ExpensiveObject getInstance() {
    if (instance == null) {               // check without lock (fast path)
        synchronized (this) {
            if (instance == null) {       // re-check with lock
                instance = new ExpensiveObject();
            }
        }
    }
    return instance;
}
```

> **Code walkthrough:** `count++` compiles to three bytecode
> instructions (read, add, write). Two threads interleaving across
> these instructions produce a lost update. `AtomicInteger.incrementAndGet()`
> uses the CPU's CAS instruction - it retries atomically. In
> double-checked locking, `volatile` is essential: without it, the
> JVM can reorder the constructor call after the field assignment,
> making another thread see a non-null but partially constructed
> object.

---

### ⚖️ Comparison

| Technique | Atomicity | Visibility | Ordering | Overhead | Use When |
|-----------|-----------|------------|----------|----------|----------|
| `synchronized` | yes | yes | yes | medium | Compound ops, multiple fields |
| `volatile` | no | yes | yes (no cache) | low | Single field visibility only |
| `AtomicInteger` | yes (CAS) | yes | yes | low | Single numeric variable |
| `ConcurrentHashMap` | yes (per segment) | yes | yes | low | Map thread safety |
| Immutable object | n/a | yes | yes | none | Read-only shared state |

**The deciding factor:** Single variable read/write with visibility
= `volatile`. Single variable read-modify-write = `AtomicInteger`.
Compound operation or multiple fields = `synchronized` or `Lock`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> A race condition is when two threads access shared mutable state
> without synchronization and the result depends on timing. It
> causes corrupted data, lost updates, and non-reproducible bugs.
> Fix with `synchronized`, `volatile`, or atomic types, depending
> on the operation.

*Push deeper:* Explain why volatile alone does not fix count++.

---

**Senior / Staff (5+ years):**

> I treat race conditions as three separate problems: atomicity
> (CAS or synchronization for compound ops), visibility (volatile,
> synchronized exit, or Atomic types), and ordering (volatile or
> synchronized for happens-before). The most insidious production
> race conditions are not `count++` bugs - those are caught by
> review. The hard ones are check-then-act races in distributed
> systems: "is this order already processed?" where the check and
> the action are not atomic at the distributed level, requiring
> idempotency tokens or database-level compare-and-update.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is a race condition?"

🗣️ "A race condition is a program defect where the outcome depends
on the non-deterministic timing of operations across multiple
threads. It occurs when two or more threads access shared mutable
state without proper synchronization, and at least one thread
modifies it. The classic example: `count++` is three operations.
Two threads interleaving those operations can produce a lost update:
both read the same value, both increment, both write back the same
incremented value - one increment is lost."

#### Mechanism

- "Why doesn't volatile fix the race condition in count++?"

🗣️ "`volatile` guarantees visibility and ordering but NOT atomicity.
`count++` is three operations: read the current value, add 1,
write back. `volatile` ensures that each read sees the latest
written value and that writes are immediately visible to other
threads. But it does not prevent two threads from both reading
the same value before either writes. Both can read 5, both add 1,
both write 6 - a lost update. The fix is `AtomicInteger.incrementAndGet()`
which uses a CAS instruction that atomically reads, increments,
and writes only if the value has not changed since the read."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Why volatile doesn't fix count++, the three dimensions. |
| Hiring Manager   | Detection strategy, impact in production. |
| Bar Raiser       | Java Memory Model happens-before, CAS, ABA problem. |
| Peer Engineer    | "We found a race in our distributed lock implementation under load..." |
