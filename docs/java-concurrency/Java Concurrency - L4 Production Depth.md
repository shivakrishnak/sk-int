---
layout: default
title: "Java Concurrency - L4 Production Depth"
parent: "Java Concurrency"
nav_order: 7
permalink: /java-concurrency/l4-production-depth/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Deadlock Detection and Prevention](#deadlock-detection-and-prevention) | high |
| 2 | [Thread Starvation and Priority Inversion](#thread-starvation-and-priority-inversion) | high |
| 3 | [Thread Pool Saturation Anti-patterns](#thread-pool-saturation-anti-patterns) | high |
| 4 | [Java Memory Model and Visibility](#java-memory-model-and-visibility) | high |
| 5 | [Concurrent Performance Tuning](#concurrent-performance-tuning) | high |

---

# Deadlock Detection and Prevention

**Interview Weight:** high - Core production safety topic. Tests
ability to recognize, diagnose, and prevent the four necessary
deadlock conditions.

---

### 🎯 Model Answer

**30 seconds:**

> Deadlock requires four conditions: mutual exclusion, hold-and-wait,
> no preemption, circular wait. Break any one to prevent deadlock.
> Most practical prevention: lock ordering (always acquire locks
> in the same order globally), or use `tryLock(timeout)` to avoid
> hold-and-wait. Detection: thread dump via `jstack` or
> `jcmd <pid> Thread.print` shows "Found one Java-level deadlock."

**3 minutes (Senior):**

> The four Coffman conditions and how to break each:
> 1. Mutual exclusion - cannot break for most resources; sometimes
>    use lock-free structures instead.
> 2. Hold-and-wait - acquire all locks atomically; if any lock
>    unavailable, release all and retry. `tryLock` with timeout
>    implements this.
> 3. No preemption - `tryLock(timeout)` provides preemption: if
>    the lock is not available within the timeout, release held
>    locks and back off.
> 4. Circular wait - the only consistently practical prevention.
>    Define a global lock ordering (e.g., by `System.identityHashCode()`
>    or by a canonical order). Always acquire locks in this order.
>
> The `tryLock` pattern breaks hold-and-wait. Define a
> `lockBoth(Lock a, Lock b)` helper: acquire lock A with `tryLock()`,
> if fails release nothing and retry. If A acquired, try lock B with
> `tryLock()`, if fails release A and retry with backoff.
>
> Thread dump analysis: `jstack <pid>` or `jcmd <pid> Thread.print`
> produces a deadlock report: "Found one Java-level deadlock: Thread A
> is waiting for lock held by Thread B; Thread B is waiting for lock
> held by Thread A." Monitor for `BLOCKED` thread state in thread
> dumps as a diagnostic signal.

---

### 💻 Code Example

**Example 1: Deadlock demonstration and prevention**

```java
// BAD: Classic deadlock - inconsistent lock ordering
class Account {
    private final Lock lock = new ReentrantLock();
    private int balance;

    // Thread 1: transfer(accountA, accountB, 100)  - acquires A then B
    // Thread 2: transfer(accountB, accountA, 50)   - acquires B then A
    // DEADLOCK
    static void transfer(Account from, Account to, int amount) {
        synchronized (from) {         // acquires from's lock
            synchronized (to) {       // tries to acquire to's lock
                from.balance -= amount;
                to.balance   += amount;
            }
        }
    }
}

// GOOD: Consistent lock ordering by identity hash code
static void transfer(Account from, Account to, int amount) {
    Account first  = from;
    Account second = to;
    // Canonical ordering: lower hash code first
    if (System.identityHashCode(from) > System.identityHashCode(to)) {
        first  = to;
        second = from;
    }
    // Both threads always acquire lower-hash lock first: no circular wait
    synchronized (first) {
        synchronized (second) {
            from.balance -= amount;
            to.balance   += amount;
        }
    }
}

// ALSO GOOD: tryLock with timeout (breaks hold-and-wait)
static boolean transfer(ReentrantLock fromLock, ReentrantLock toLock,
                        int amount) throws InterruptedException {
    while (true) {
        if (fromLock.tryLock(50, TimeUnit.MILLISECONDS)) {
            try {
                if (toLock.tryLock(50, TimeUnit.MILLISECONDS)) {
                    try {
                        // Both locks held
                        return true;
                    } finally {
                        toLock.unlock();
                    }
                }
            } finally {
                fromLock.unlock();
            }
        }
        // Neither or only one acquired: back off and retry
        Thread.sleep(ThreadLocalRandom.current().nextInt(5, 20));
    }
}
```

> **Code walkthrough:** Thread 1 acquires account A then needs B;
> Thread 2 acquires B then needs A - classic circular wait. The
> fix: global ordering by `identityHashCode` means BOTH threads
> always acquire the lower-hash account first. Circular wait is
> impossible. `tryLock` provides a timeout-based alternative: if
> either lock is unavailable within 50ms, release held locks and
> retry after random backoff.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Deadlock happens when two threads wait on each other's locks.
> Prevention: always acquire locks in the same order. Detection:
> `jstack` shows deadlocked threads. Use `tryLock(timeout)` as
> an alternative.

---

**Senior / Staff (5+ years):**

> In production, the most scalable deadlock prevention is lock
> ordering by object identity hash. For transactional systems I
> use `tryLock` with jitter to handle tie-breaking. I run
> `jcmd <pid> Thread.print` in CI for any test that uses multiple
> locks - thread dump analysis in automated tests catches potential
> deadlocks before production.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "How would you diagnose and resolve a deadlock in production?"

🗣️ "Step 1: Take a thread dump. `jcmd <pid> Thread.print` or
`kill -3 <pid>` or VisualVM. The JVM analyzes the dump and reports:
'Found one Java-level deadlock' with the chain of blocked threads.
Step 2: Identify the lock cycle - which threads hold which locks
and which they are waiting for. Step 3: Identify the lock acquisition
ordering in code. Step 4: Fix by (a) imposing a global lock
ordering (canonical order by `identityHashCode`), or (b) replacing
`synchronized` blocks with `tryLock(timeout)` to break hold-and-wait.
Step 5: Add a deadlock detector: `ThreadMXBean.findDeadlockedThreads()`
programmatically detects deadlocks at runtime."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Four Coffman conditions, lock ordering, tryLock. |
| Hiring Manager   | Production diagnosis - jstack, jcmd, VisualVM. |
| Bar Raiser       | ThreadMXBean detection, lock-free alternatives, timeout policies. |
| Peer Engineer    | "We had a production deadlock between two database connection pools..." |

---

---

# Thread Starvation and Priority Inversion

**Interview Weight:** high - Production pathology that is harder
to detect than deadlock. Tests depth on thread scheduling and
fairness.

---

### 🎯 Model Answer

**30 seconds:**

> Thread starvation: a thread is ready to run but never scheduled
> because other threads continuously preempt or starve it. Common
> causes: thread priority differences, unfair locks, a long-running
> thread monopolizing a resource. Priority inversion: a high-priority
> thread is blocked on a resource held by a low-priority thread,
> while medium-priority threads run freely - inverting the effective
> priorities. Java has no built-in priority inheritance to solve this.

**3 minutes (Senior):**

> Thread starvation in Java happens primarily with:
> 1. Unfair `synchronized` blocks: the JVM selects any waiting
>    thread, not the longest-waiting. A burst of short-running threads
>    can permanently starve a longer-waiting thread.
> 2. Thread priority abuse: setting high priority causes low-priority
>    threads to starve on CPU-bound workloads. Java priorities are
>    hints, not guarantees, and vary by OS.
> 3. Writer starvation in readers-writers: if readers are constant,
>    a writer waiting for a write lock never runs.
>
> `ReentrantLock(true)` enables fair mode: threads acquire the lock
> in FIFO order. This prevents starvation at the cost of lower
> throughput (higher context-switch overhead).
>
> Priority inversion: low-priority thread L holds lock. High-priority
> thread H blocks waiting. Medium-priority threads M run continuously
> (they don't need the lock). H effectively runs at L's priority.
> Real-world case: Mars Pathfinder's 1997 system reset was caused
> by priority inversion. Solution: avoid mixing priority levels
> with shared resources, or use a platform with priority inheritance
> (Java on Linux with specific JVM options can enable it).

---

### 💻 Code Example

**Example 1: Starvation demonstration and fair locks**

```java
// BAD: Unfair lock - high-contention threads may starve others
ReentrantLock unfairLock = new ReentrantLock();  // default: unfair
// Under high contention, threads that just released the lock
// often re-acquire it immediately - starvation of waiting threads

// GOOD: Fair lock - FIFO ordering prevents starvation
ReentrantLock fairLock = new ReentrantLock(true); // fair = true
// Longer wait = higher queue position = guaranteed eventual execution
// Cost: ~30-50% lower throughput than unfair mode

// Reader-Writer starvation - writers starved by constant readers
ReadWriteLock rwl = new ReentrantReadWriteLock();  // default: unfair
// Solution: fair ReadWriteLock
ReadWriteLock fairRwl = new ReentrantReadWriteLock(true);
// Writers are queued fairly: once a writer is waiting, new readers queue behind it

// Monitoring starvation: track lock wait time
class InstrumentedLock {
    private final ReentrantLock lock = new ReentrantLock(true);
    private final Histogram waitTimeHist = MetricRegistry.histogram("lock.wait");

    public void lock() {
        long start = System.nanoTime();
        lock.lock();
        waitTimeHist.update(System.nanoTime() - start);
    }
}

// Detecting CPU starvation via thread state monitoring
ThreadMXBean mxBean = ManagementFactory.getThreadMXBean();
for (ThreadInfo info : mxBean.dumpAllThreads(false, false)) {
    if (info.getThreadState() == Thread.State.RUNNABLE) {
        System.out.println("Runnable: " + info.getThreadName());
    } else if (info.getThreadState() == Thread.State.BLOCKED) {
        System.out.println("Blocked: " + info.getThreadName()
            + " waiting for: " + info.getLockName());
    }
}
```

> **Code walkthrough:** `ReentrantLock(true)` enables fair mode:
> waiting threads acquire the lock in the order they requested it.
> Fair mode prevents starvation but reduces throughput because the
> JVM cannot reuse the lock for the thread that just released it
> (which is already scheduled). The instrumented lock measures wait
> time: high percentile wait times in monitoring indicate starvation
> risk.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Starvation means a thread is ready but never runs. Fair locks
> prevent it. Priority inversion is when a high-priority thread
> waits on a resource held by a low-priority thread.

---

**Senior / Staff (5+ years):**

> I avoid thread priorities entirely in application code - they're
> JVM hints, not guarantees. For starvation prevention I default
> to fair `ReentrantLock` in high-contention scenarios and use
> queue depth and wait-time metrics to detect starvation in
> production dashboards.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "What is priority inversion and how do you handle it in Java?"

🗣️ "Priority inversion occurs when a high-priority thread H is
blocked waiting for a lock held by a low-priority thread L. If
medium-priority threads M run continuously, the OS never preempts
L (L is not running - it just holds the lock). H waits indefinitely
despite being highest priority. In Java, the standard fix is:
(1) avoid mixing thread priorities in the same lock domain; (2) use
lock-free data structures where possible; (3) limit critical section
duration. The Mars Pathfinder bug (1997) was priority inversion.
Java does not have built-in priority inheritance like POSIX - the
best defense is to avoid thread priority differences when shared
resources are involved."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Starvation causes, fair locks, reader-writer fairness. |
| Hiring Manager   | Production monitoring for starvation detection. |
| Bar Raiser       | Priority inversion, Mars Pathfinder, priority inheritance (POSIX). |
| Peer Engineer    | "Our report generation thread never ran despite being 'high priority'..." |

---

---

# Thread Pool Saturation Anti-patterns

**Interview Weight:** high - Production failure mode. Tests whether
you know how to properly size pools, detect saturation, and handle
back-pressure.

---

### 🎯 Model Answer

**30 seconds:**

> Thread pool saturation: the queue is full AND all threads are
> busy. New tasks are rejected. Three root causes: pool too small,
> tasks taking too long, producer faster than consumer. Four
> rejection policies: abort (throw exception), caller-runs
> (back-pressure), discard (silent loss), discard-oldest (drop
> queued tasks). Detection: queue depth > threshold in monitoring.
> Always alert on `RejectedExecutionException` in production.

**3 minutes (Senior):**

> Thread pool sizing is workload-dependent:
> - CPU-bound: `N = CPU count` or `CPU count + 1`
> - I/O-bound: `N = CPU count * (1 + wait_time / service_time)`.
>   For 90% wait time, N = 10x CPU count.
>   With virtual threads (Java 21), I/O-bound pools are obsolete.
>
> The deadlock-from-saturation anti-pattern: task A submits subtask
> B to the same pool and waits for B's result. If all pool threads
> are executing A-type tasks waiting for B, B never gets a thread.
> The pool is full with tasks that are waiting. This is not a "real"
> deadlock (no lock cycle) but has the same effect. Fix: use a
> separate pool for subtasks, or use `ForkJoinPool` (work stealing
> can still schedule subtasks).
>
> Queue type selection:
> - `SynchronousQueue`: zero buffering; a task is rejected unless
>   a thread is immediately available. Forces thread creation up to max.
> - `LinkedBlockingQueue(capacity)`: bounded buffer; tasks queue
>   up to capacity, then threads grow.
> - `ArrayBlockingQueue(capacity)`: bounded, FIFO, bounded array.
> - `PriorityBlockingQueue`: task priority ordering (risk: starvation
>   of low-priority tasks under load).

---

### 💻 Code Example

**Example 1: Saturation monitoring and anti-patterns**

```java
// BAD: Thread pool deadlock - submitting subtasks to same pool
ExecutorService pool = Executors.newFixedThreadPool(4);
pool.execute(() -> {
    Future<Integer> f = pool.submit(() -> computeSubtask());  // BAD
    int result = f.get();  // deadlock if pool full: all 4 threads waiting here
});

// GOOD: Separate pool for subtasks
ExecutorService mainPool = new ThreadPoolExecutor(4, 4, 0L, MILLISECONDS,
    new ArrayBlockingQueue<>(100));
ExecutorService subPool  = new ThreadPoolExecutor(8, 8, 0L, MILLISECONDS,
    new ArrayBlockingQueue<>(500));

mainPool.execute(() -> {
    Future<Integer> f = subPool.submit(() -> computeSubtask());  // safe
    int result = f.get();                                         // subPool separate
});

// Production monitoring: alert on queue depth and rejection
ThreadPoolExecutor pool = new ThreadPoolExecutor(
    4, 8, 60L, TimeUnit.SECONDS,
    new ArrayBlockingQueue<>(100),
    Executors.defaultThreadFactory(),
    (r, executor) -> {
        // CUSTOM rejection handler: metrics + fallback
        metrics.increment("pool.rejected");
        logger.error("Task rejected: queue={}, activeThreads={}",
            executor.getQueue().size(), executor.getActiveCount());
        // Caller runs as back-pressure mechanism
        if (!executor.isShutdown()) r.run();  // CallerRunsPolicy behavior
    }
);

// Schedule monitoring (run every 30s)
scheduler.scheduleAtFixedRate(() -> {
    int queueSize = pool.getQueue().size();
    int active    = pool.getActiveCount();
    metrics.gauge("pool.queue.size", queueSize);
    metrics.gauge("pool.active.threads", active);
    if (queueSize > 80) {  // 80% queue capacity = saturation alert
        alerting.warn("Thread pool near saturation: queue=" + queueSize);
    }
}, 0, 30, TimeUnit.SECONDS);
```

> **Code walkthrough:** The self-referential subtask pattern is a
> production deadlock trap. With 4 threads, if all 4 execute the outer
> task and each submits a subtask to the same pool, the 4 threads
> are all blocked on `f.get()` - the subtasks never get a thread.
> The fix is a separate pool for subtasks. The custom rejection handler
> emits a metric AND applies caller-runs as a fallback - giving
> observability without silent task loss.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Thread pool saturation happens when all threads are busy and the
> queue is full. Rejection policies control what happens: throw
> exception, run in caller thread, or drop the task. Monitor queue
> depth to detect approaching saturation.

---

**Senior / Staff (5+ years):**

> The most dangerous anti-pattern is the intra-pool task dependency:
> a task submitting subtasks to the same pool and blocking for
> results. I enforce a rule: tasks in a pool must never submit to
> the same pool and wait for results. Separate pools for tiers of
> work. In monitoring, I alert when queue depth > 70% of capacity
> - before rejection begins.

---

### ❓ Questions You Will Be Asked

#### Failure Mode

- "Describe a scenario where thread pool saturation causes a deadlock."

🗣️ "Task A runs in a fixed pool of 4 threads. Task A's logic
is: submit sub-task B to the same pool, then block calling
`futureB.get()`. If 4 instances of Task A run simultaneously, all
4 pool threads are now blocked on `futureB.get()`. Sub-task B needs
a thread to run, but all 4 threads are occupied. The pool queue
may have B tasks, but no thread will ever pick them up because all
threads are waiting for B. This is not a lock-based deadlock - it
is a resource deadlock: tasks waiting for tasks that cannot run.
The JVM thread dump will not show 'deadlock found' because no lock
cycle exists. Diagnosis: all threads in BLOCKED state waiting on
`FutureTask.get()`."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Four rejection policies, queue types, pool sizing formulas. |
| Hiring Manager   | Monitoring strategy - queue depth alerting. |
| Bar Raiser       | Intra-pool deadlock, SynchronousQueue behavior, load shedding. |
| Peer Engineer    | "Our pool saturated silently with DiscardPolicy and we lost events for hours..." |

---

---

# Java Memory Model and Visibility

**Interview Weight:** high - Advanced correctness topic. Tests
knowledge of happens-before, the visibility guarantee of volatile
and synchronized, and why double-checked locking works in Java 5+.

---

### 🎯 Model Answer

**30 seconds:**

> The Java Memory Model (JMM) defines when a write by one thread is
> visible to another. Without synchronization, writes may remain in
> CPU registers or L1 cache and never flush to main memory. Two
> visibility guarantees: `volatile` - all writes are immediately
> visible to all threads; `synchronized` - exit of a monitor flushes
> all writes; entering a monitor reads the latest values. The JMM
> is defined via happens-before: a write that happens-before a read
> is guaranteed to be visible.

**3 minutes (Senior):**

> Happens-before rules in the JMM:
> - Monitor unlock happens-before subsequent lock of the same monitor
> - Write to `volatile` happens-before subsequent read of same variable
> - Thread start happens-before any action in the started thread
> - All actions in a thread happen-before `join()` returns
> - Thread interruption happens-before the interrupted thread detects it
>
> `volatile` guarantees: (1) visibility - all threads see the latest
> write; (2) ordering - reads/writes to volatile are not reordered
> with adjacent reads/writes. `volatile` does NOT guarantee atomicity
> for compound operations (`count++` is still not thread-safe with
> just `volatile`).
>
> Double-checked locking (pre-Java 5) was broken: without `volatile`,
> the JVM could reorder the `instance = new Singleton()` instruction.
> A thread could see a non-null but partially-constructed object.
> Java 5+ with `volatile` fixes this: the `volatile` write to
> `instance` happens-before the read, so the partial construction
> is never visible.
>
> Final fields: a properly constructed object (constructor exits
> normally) has its `final` fields visible to any thread without
> synchronization. This is why immutable objects are inherently
> thread-safe.

---

### 💻 Code Example

**Example 1: Visibility bugs and fixes**

```java
// BAD: No visibility guarantee - stopped may never be seen as true
class Runner implements Runnable {
    private boolean stopped = false;   // no volatile - may be cached in CPU register
    public void stop() { stopped = true; }
    public void run() {
        while (!stopped) { doWork(); }  // may loop forever!
    }
}

// GOOD: volatile guarantees visibility across threads
class Runner implements Runnable {
    private volatile boolean stopped = false;  // flushes to main memory on write
    public void stop() { stopped = true; }     // all threads see the write
    public void run() {
        while (!stopped) { doWork(); }         // always sees latest value
    }
}

// Double-checked locking: broken before Java 5 (no volatile)
// BAD (Java 4-): partial construction visible
class Singleton {
    private static Singleton instance;
    public static Singleton getInstance() {
        if (instance == null) {             // check 1: no lock
            synchronized (Singleton.class) {
                if (instance == null) {     // check 2: with lock
                    instance = new Singleton(); // reordering possible!
                    // JVM may set instance = ref BEFORE constructor completes
                }
            }
        }
        return instance;  // may return partially-constructed object!
    }
}

// GOOD: volatile in Java 5+ prevents reordering
class Singleton {
    private static volatile Singleton instance;  // volatile key
    public static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton(); // safe: volatile write
                    // happens-before the volatile read in the outer check
                }
            }
        }
        return instance;  // always sees fully constructed object
    }
    // Even better: initialization-on-demand holder (no volatile needed)
    private static class Holder {
        static final Singleton INSTANCE = new Singleton();
    }
    public static Singleton getInstanceBetter() { return Holder.INSTANCE; }
}
```

> **Code walkthrough:** Without `volatile`, the JVM is free to
> cache `stopped` in the CPU register for the running thread. The
> main thread writes `stopped = true` to its register, but the
> runner thread's cached copy remains `false`. `volatile` forces
> every write to flush to main memory and every read to fetch from
> main memory. The initialization-on-demand holder pattern exploits
> class loading guarantees: the `Holder` class is initialized exactly
> once, by the class loader, which provides the required happens-before.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Threads can cache values in CPU registers. `volatile` forces reads
> and writes to go through main memory. Without synchronization,
> one thread's write may not be visible to another thread.

---

**Senior / Staff (5+ years):**

> The JMM's happens-before is the formal foundation. Volatile read
> of X after a volatile write to X is a happens-before edge. This
> is why double-checked locking needs `volatile`: the volatile write
> to `instance` creates a happens-before that prevents partial
> construction visibility. I use the initialization-on-demand holder
> for singletons - simpler and equally correct.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "Why was double-checked locking broken before Java 5?"

🗣️ "`instance = new Singleton()` is NOT an atomic operation. It
involves three steps: (1) allocate memory, (2) call constructor,
(3) assign reference to `instance`. Without `volatile`, the JVM
is allowed to reorder to: (1) allocate, (3) assign to `instance`,
(2) call constructor. Thread B now sees a non-null `instance` but
the constructor has not run - the object is partially initialized.
Any access to `instance`'s fields throws NPE or returns wrong values.
Java 5 made `volatile` a happens-before barrier that prevents this
reordering. With `private static volatile Singleton instance`, the
assignment to `instance` cannot be observed until the constructor
completes."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Happens-before rules, volatile vs synchronized visibility. |
| Hiring Manager   | Practical bugs: flags, counters, singleton. |
| Bar Raiser       | JMM specification, reordering rules, final field semantics. |
| Peer Engineer    | "We had a cache-not-invalidated bug that only appeared under load on 16-core servers..." |

---

---

# Concurrent Performance Tuning

**Interview Weight:** high - Production engineering depth. Tests
knowledge of false sharing, lock contention, contention profiling,
and lock-free alternatives.

---

### 🎯 Model Answer

**30 seconds:**

> Three main concurrency performance problems: lock contention
> (threads blocked waiting), false sharing (independent variables
> on the same cache line invalidate each other), and excessive
> context switching. Diagnosis: async-profiler for contention,
> JFR for lock wait times, `perf stat` for cache misses. Solutions:
> lock striping (reduce contention), `@Contended` annotation or
> padding (fix false sharing), lock-free structures.

**3 minutes (Senior):**

> **Lock contention**: a lock protects a shared resource. More
> threads competing = more time blocking. Solutions:
> 1. Reduce critical section size - move I/O and computation outside
>    the lock.
> 2. Lock striping - partition data across N locks. `ConcurrentHashMap`
>    uses 16 default segments.
> 3. Lock-free structures - `AtomicInteger`, `ConcurrentLinkedQueue`
>    use CAS (compare-and-swap) - no lock, no blocking.
> 4. Read-write locks - allow concurrent reads when writes are rare.
>
> **False sharing**: CPU caches work in 64-byte cache lines. If two
> threads on different CPUs write to different variables that share
> a cache line, each write invalidates the other thread's cache line.
> The threads "share" a cache line they do not logically share.
> Effect: worse than a real lock - contention appears in hardware
> without any explicit synchronization.
> Fix: `@sun.misc.Contended` (Java 8) pads fields to separate cache
> lines. Or manually pad fields: add 7 `long` padding fields adjacent
> to the hot field.
>
> **CAS vs lock**: CAS (compare-and-swap) tries to update atomically
> - if the value has changed since the read, retry. Under LOW
> contention, CAS is faster (no context switch). Under HIGH contention,
> CAS is slower (many retries). `LongAdder` solves this for counters:
> maintains separate per-CPU cells, only aggregates on read - reduces
> CAS contention dramatically.

---

### 💻 Code Example

**Example 1: False sharing, lock striping, LongAdder**

```java
// BAD: False sharing - two counters on same cache line
class Counters {
    long hits   = 0;  // bytes 0-7 on cache line 1
    long misses = 0;  // bytes 8-15 on cache line 1 (SAME CACHE LINE)
    // Thread A writes hits, Thread B writes misses
    // Each write invalidates the OTHER thread's cache line
    // Result: unnecessary cache invalidation across CPUs
}

// GOOD: Pad to separate cache lines
class Counters {
    @sun.misc.Contended   // JVM adds 128 bytes of padding
    volatile long hits   = 0;

    @sun.misc.Contended
    volatile long misses = 0;
    // Now on separate cache lines: no false sharing
}

// GOOD: LongAdder for high-contention counters (better than AtomicLong)
class Metrics {
    // BAD: AtomicLong under high contention - CAS retry loop
    private final AtomicLong counter = new AtomicLong();
    public void increment() { counter.incrementAndGet(); }
    public long get()       { return counter.get(); }

    // GOOD: LongAdder - per-thread cells, no CAS contention
    private final LongAdder adder = new LongAdder();
    public void increment() { adder.increment(); }
    public long get()       { return adder.sum(); }
    // Under 100 threads: LongAdder ~10x faster than AtomicLong
    // Tradeoff: sum() is not instantaneous (sums all cells)
}

// Lock striping: reduce contention with N locks for N segments
class StripedMap<K, V> {
    private static final int SEGMENTS = 16;
    private final Object[] locks = new Object[SEGMENTS];
    private final Map<K, V>[] maps = new Map[SEGMENTS];

    public V get(K key) {
        int seg = key.hashCode() & (SEGMENTS - 1);  // which segment
        synchronized (locks[seg]) {                  // lock only that segment
            return maps[seg].get(key);
        }
    }
}
```

> **Code walkthrough:** `@Contended` pads the annotated field so
> it occupies its own 128-byte region (no adjacent variables share
> the cache line). This is how `ForkJoinPool` avoids false sharing
> between its work queues. `LongAdder` maintains a cell per NUMA
> node/CPU - increments update the local cell without contending
> with other CPUs. The tradeoff: `sum()` iterates all cells, so
> it is not an O(1) atomic read.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Lock contention means threads block waiting. Reduce it by
> shortening critical sections, using `ConcurrentHashMap`, or
> lock-free structures like `AtomicInteger`. Use `LongAdder`
> for high-contention counters.

---

**Senior / Staff (5+ years):**

> False sharing is the most counterintuitive concurrency bottleneck.
> I've seen production systems where performance improved 5x by
> adding `@Contended` to a hot counter. Diagnosis: `perf stat -e
> cache-misses` shows cache invalidation rate. Async-profiler in
> "lock" mode shows lock contention hotspots without sampling bias.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is false sharing and how do you fix it?"

🗣️ "CPU caches work in 64-byte lines. When a CPU writes to a
memory location, it invalidates all copies of the containing cache
line on other CPUs, even if those CPUs are accessing different bytes
in the same line. False sharing occurs when two threads on different
CPUs write to different variables that happen to occupy the same
64-byte cache line. The threads do not logically share data, but
physically share a cache line. Each write causes the other CPU's
cache line to be invalidated and reloaded from main memory. The
fix: ensure hot variables written by different threads are on
separate cache lines. In Java: use `@sun.misc.Contended` (enable
with `-XX:-RestrictContended`), or manually add 7 `long` padding
fields adjacent to the hot field."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | LongAdder vs AtomicLong, false sharing, lock striping. |
| Hiring Manager   | Profiling approach to find contention in production. |
| Bar Raiser       | @Contended, NUMA topology, CAS under contention vs lock. |
| Peer Engineer    | "Our metrics counter was causing 30% overhead on 32-core servers..." |
