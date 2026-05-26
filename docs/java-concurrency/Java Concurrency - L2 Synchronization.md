---
layout: default
title: "Java Concurrency - L2 Synchronization"
parent: "Java Concurrency"
nav_order: 3
permalink: /java-concurrency/l2-synchronization/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [ReentrantLock](#reentrantlock) | high |
| 2 | [ReadWriteLock](#readwritelock) | high |
| 3 | [Semaphore](#semaphore) | high |
| 4 | [CountDownLatch and CyclicBarrier](#countdownlatch-and-cyclicbarrier) | high |
| 5 | [AtomicInteger and Atomic Variables](#atomicinteger-and-atomic-variables) | high |

---

# ReentrantLock

**Interview Weight:** high - Tests awareness of explicit locking
advantages: timed acquisition, interruptible lock, fairness, and
multiple conditions. Interviewers probe when you'd choose it over
`synchronized`.

---

### 🎯 Model Answer

**30 seconds:**

> `ReentrantLock` is the explicit, flexible alternative to `synchronized`.
> Key advantages: timed `tryLock()` (give up after timeout),
> interruptible lock acquisition (`lockInterruptibly()`), optional
> fairness (FIFO ordering), and multiple condition variables per lock.
> The rule: always release in a `finally` block. Unlike `synchronized`,
> `ReentrantLock.unlock()` is not automatic - forgetting it leaks
> the lock forever.

**3 minutes (Senior):**

> `synchronized` is tied to a single condition variable (`wait/notify`).
> `ReentrantLock` gives you `newCondition()` to create multiple
> independent condition queues on the same lock. This is critical
> for the bounded buffer: with `synchronized`, producers and consumers
> share one wait-set and must use `notifyAll()`. With
> `ReentrantLock` + two conditions (`notFull`, `notEmpty`), producers
> wait on `notFull` and consumers wait on `notEmpty` - a producer
> wakeup signals `notEmpty` (consumers only), avoiding unnecessary
> wakeups.
>
> `tryLock(timeout, unit)` enables lock-ordering timeout: if a
> thread cannot acquire all required locks within a timeout, it
> releases what it has and retries with a random backoff -
> deadlock avoidance by design. `synchronized` cannot do this.
>
> Fair mode (`new ReentrantLock(true)`): threads acquire in FIFO
> order - the longest-waiting thread always gets the lock next.
> This prevents starvation but reduces throughput (every acquisition
> requires checking the queue). Default (unfair) mode allows
> "barging" - a thread just releasing the lock may immediately
> re-acquire it, skipping waiting threads, but providing higher
> throughput through better cache locality.

---

### 💻 Code Example

**Example 1: tryLock and multiple conditions**

```java
// GOOD: ReentrantLock with try/finally (mandatory pattern)
ReentrantLock lock = new ReentrantLock();
lock.lock();
try {
    // critical section
    updateSharedState();
} finally {
    lock.unlock();  // ALWAYS in finally - prevents lock leaks
}

// GOOD: Timed tryLock for deadlock avoidance
public boolean transferFunds(Account from, Account to, long amount)
        throws InterruptedException {
    while (true) {
        if (from.lock.tryLock(50, TimeUnit.MILLISECONDS)) {
            try {
                if (to.lock.tryLock(50, TimeUnit.MILLISECONDS)) {
                    try {
                        from.debit(amount);
                        to.credit(amount);
                        return true;
                    } finally {
                        to.lock.unlock();
                    }
                }
            } finally {
                from.lock.unlock();
            }
        }
        // Could not acquire both locks in time, retry with backoff
        Thread.sleep(ThreadLocalRandom.current().nextLong(1, 10));
    }
}

// GOOD: Multiple conditions on same lock (bounded buffer)
class BoundedBuffer<T> {
    private final ReentrantLock lock = new ReentrantLock();
    private final Condition notFull  = lock.newCondition();
    private final Condition notEmpty = lock.newCondition();
    private final Object[] items = new Object[100];
    private int head, tail, count;

    public void put(T item) throws InterruptedException {
        lock.lock();
        try {
            while (count == items.length)
                notFull.await();    // wait until not full
            items[tail] = item;
            if (++tail == items.length) tail = 0;
            count++;
            notEmpty.signal();      // signal only consumers (not other producers)
        } finally { lock.unlock(); }
    }

    @SuppressWarnings("unchecked")
    public T take() throws InterruptedException {
        lock.lock();
        try {
            while (count == 0)
                notEmpty.await();   // wait until not empty
            T item = (T) items[head];
            if (++head == items.length) head = 0;
            count--;
            notFull.signal();       // signal only producers (not other consumers)
            return item;
        } finally { lock.unlock(); }
    }
}
```

> **Code walkthrough:** The `try/finally` pattern is mandatory -
> if `updateSharedState()` throws, `finally` ensures `unlock()` is
> called. Without `finally`, the lock is held forever. The timed
> transfer avoids deadlock by releasing both locks if the second
> cannot be acquired within timeout, then retrying. The bounded
> buffer uses two conditions: `notFull.signal()` wakes exactly one
> producer (not consumers); `notEmpty.signal()` wakes exactly one
> consumer - no unnecessary wakeups, compared to `synchronized`'s
> `notifyAll()`.

---

### ⚖️ Comparison

| Feature | synchronized | ReentrantLock |
|---------|-------------|---------------|
| Auto-release | yes | no (requires finally) |
| Timed acquire | no | tryLock(timeout) |
| Interruptible | no | lockInterruptibly() |
| Fairness | no | new ReentrantLock(true) |
| Multiple conditions | no (one wait-set) | newCondition() |
| Diagnostic | BLOCKED in dump | WAITING (park) in dump |
| Performance | fast (optimized JVM) | slightly more overhead |

**The deciding factor:** `synchronized` for simple mutual exclusion.
`ReentrantLock` when you need timed lock, interruptible lock,
fairness, or multiple conditions.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `ReentrantLock` is an explicit lock that gives more control than
> `synchronized`. Key methods: `lock()`, `unlock()`, `tryLock()`.
> Always release in a `finally` block. It is reentrant: the same
> thread can lock it multiple times.

*Push deeper:* What is the timed tryLock useful for?

---

**Senior / Staff (5+ years):**

> I use `ReentrantLock` in three scenarios: (1) timed lock
> acquisition for deadlock-safe resource ordering; (2) multiple
> conditions on the same lock for efficient producer-consumer;
> (3) fair lock to prevent starvation in priority-sensitive systems.
> For everything else, `ConcurrentHashMap` and atomic types are
> preferred over any explicit locking.

---

### ❓ Questions You Will Be Asked

#### Definition

- "When would you use ReentrantLock over synchronized?"

🗣️ "I reach for `ReentrantLock` in three cases. First: deadlock
prevention with timed `tryLock()` - if I cannot acquire all needed
locks within a timeout, I release and retry, avoiding the fixed-
ordering requirement for deadlock prevention. Second: multiple
condition variables - if I have a bounded buffer where producers
and consumers share a lock but should not wake each other up,
two `Condition` objects (`notFull`, `notEmpty`) are more efficient
than `notifyAll()`. Third: interruptible lock acquisition with
`lockInterruptibly()` - if the thread is interrupted while waiting
for the lock, it should abort cleanly. `synchronized` cannot
do any of these."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | tryLock, Condition, fairness, try/finally pattern. |
| Hiring Manager   | When to reach for explicit locking vs higher-level tools. |
| Bar Raiser       | StampedLock optimistic reads, comparison to synchronized. |
| Peer Engineer    | "The deadlock in our transfer service was fixed by tryLock with timeout..." |

---

---

# ReadWriteLock

**Interview Weight:** high - Tests knowledge of read vs write
access patterns. Interviewers want to see that you understand
the performance improvement for read-heavy workloads and the
upgrade limitation.

---

### 🎯 Model Answer

**30 seconds:**

> `ReadWriteLock` allows multiple concurrent readers OR one exclusive
> writer, but not both simultaneously. This is the right choice for
> read-heavy workloads (caches, configuration, shared lookups) where
> writes are rare. `ReentrantReadWriteLock` is the standard
> implementation. Key limitation: Java's `ReadWriteLock` does not
> allow lock upgrade - you cannot upgrade a read lock to a write
> lock without releasing the read lock first.

**3 minutes (Senior):**

> The read lock can be held by many threads simultaneously, so
> read-heavy workloads see near-zero contention. The write lock
> is exclusive: it waits for all readers to release, and no new
> readers can acquire while a writer is waiting.
>
> The upgrade limitation is a real constraint. If a thread holds
> a read lock and needs to write, it must: (1) release the read
> lock, (2) acquire the write lock, (3) re-check the condition
> (it may have changed between release and acquire). This is why
> `ReadWriteLock` for caches needs careful design: the read-to-write
> transition requires a double-check after upgrading.
>
> Java 8 introduced `StampedLock` as an alternative with three modes:
> write (exclusive), read (non-exclusive), and optimistic read.
> Optimistic read acquires no lock - just reads a stamp, does the
> read, then validates the stamp. If invalid (a write happened
> concurrently), fall back to a pessimistic read. `StampedLock`
> has higher throughput than `ReentrantReadWriteLock` for read-heavy
> workloads but is more complex to use correctly and is NOT reentrant.

---

### 💻 Code Example

**Example 1: Read-write cache**

```java
public class ReadWriteCache<K, V> {
    private final Map<K, V> cache = new HashMap<>();
    private final ReentrantReadWriteLock rwl = new ReentrantReadWriteLock();
    private final ReadWriteLock.ReadLock  readLock  = rwl.readLock();
    private final ReadWriteLock.WriteLock writeLock = rwl.writeLock();

    public V get(K key) {
        readLock.lock();      // multiple readers allowed simultaneously
        try {
            return cache.get(key);
        } finally {
            readLock.unlock();
        }
    }

    public void put(K key, V value) {
        writeLock.lock();     // exclusive: waits for all readers to release
        try {
            cache.put(key, value);
        } finally {
            writeLock.unlock();
        }
    }

    // Upgrade: read-to-write requires release + re-acquire + re-check
    public V computeIfAbsent(K key, Function<K, V> loader) {
        readLock.lock();
        V value = null;
        try {
            value = cache.get(key);
        } finally {
            readLock.unlock();
        }
        if (value != null) return value;

        writeLock.lock();     // upgrade: acquire write lock separately
        try {
            value = cache.get(key);  // re-check: another thread may have loaded
            if (value == null) {
                value = loader.apply(key);
                cache.put(key, value);
            }
            return value;
        } finally {
            writeLock.unlock();
        }
    }
}
```

> **Code walkthrough:** `get()` acquires the read lock - any number
> of threads can read simultaneously with zero blocking between
> readers. `put()` acquires the exclusive write lock - waits for
> all readers to finish, then runs alone. `computeIfAbsent()` shows
> the upgrade pattern: release read lock, acquire write lock, then
> re-check the cache because another thread may have added the value
> between the two lock acquisitions (this is the double-check in
> write lock).

**Example 2: StampedLock optimistic read (Java 8+)**

```java
public class Point {
    private double x, y;
    private final StampedLock sl = new StampedLock();

    // Optimistic read: no lock, just validate after read
    public double distanceFromOrigin() {
        long stamp = sl.tryOptimisticRead();  // gets stamp without locking
        double cx = x, cy = y;               // read values optimistically
        if (!sl.validate(stamp)) {           // was there a concurrent write?
            stamp = sl.readLock();           // fall back to pessimistic read
            try {
                cx = x; cy = y;
            } finally {
                sl.unlockRead(stamp);
            }
        }
        return Math.sqrt(cx * cx + cy * cy);
    }

    public void move(double deltaX, double deltaY) {
        long stamp = sl.writeLock();
        try {
            x += deltaX;
            y += deltaY;
        } finally {
            sl.unlockWrite(stamp);
        }
    }
}
```

> **Code walkthrough:** `tryOptimisticRead()` returns a stamp without
> acquiring any lock - reads proceed without blocking other readers
> or even blocking on a writer. `sl.validate(stamp)` checks if a
> write happened since the stamp was acquired. If valid, the read
> is complete at near-zero cost. If invalid (concurrent write),
> fall back to a full read lock. For read-heavy, write-rare workloads,
> this gives near-zero read contention.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `ReadWriteLock` allows multiple concurrent readers but only one
> exclusive writer. Use it for read-heavy, write-rare shared state
> like caches and configuration. The read lock allows concurrency;
> the write lock is exclusive and waits for all readers.

---

**Senior / Staff (5+ years):**

> For Java 8+ I prefer `StampedLock` for high-read workloads -
> the optimistic read mode gives near-zero read overhead when
> writes are rare. I use `ReadWriteLock` when I need reentrancy
> (StampedLock is NOT reentrant). The key design point for both:
> minimize time spent in the write lock, and always double-check
> after acquiring the write lock when computing-if-absent.

---

### ❓ Questions You Will Be Asked

#### Definition

- "When would you use ReadWriteLock?"

🗣️ "When I have shared state that is read frequently and written
rarely - like an in-memory cache, configuration map, or shared
lookup table. Multiple threads can read concurrently without
blocking each other, while a writer gets exclusive access. This
is much more efficient than a plain `synchronized` map for read-
heavy workloads, where `synchronized` would serialize all reads
even though reads are safe to run concurrently."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Read/write semantics, upgrade limitation, double-check. |
| Hiring Manager   | Use case: cache, config map, read-heavy. |
| Bar Raiser       | StampedLock optimistic read, thread-local vs RWLock trade-off. |
| Peer Engineer    | "Switching from synchronized to ReadWriteLock cut our cache latency..." |

---

---

# Semaphore

**Interview Weight:** high - Tests whether you understand the
counting permit model and the classic use cases: connection
pooling and rate limiting.

---

### 🎯 Model Answer

**30 seconds:**

> A `Semaphore` maintains a count of permits. `acquire()` decrements
> the count and blocks if it reaches zero. `release()` increments
> it and wakes a blocked thread. A semaphore with 1 permit is a
> mutex (like a lock). A semaphore with N permits controls access
> to a pool of N resources. Classic uses: database connection pool,
> rate limiter, download throttle.

**3 minutes (Senior):**

> `Semaphore` is different from `ReentrantLock` in an important way:
> any thread can call `release()`. With a lock, only the thread that
> acquired the lock can release it. With a semaphore, one thread
> acquires and a different thread can release. This enables the
> "bouncer" pattern: a thread that enforces limits can release
> permits as resources become available, independent of who
> acquired them.
>
> `Semaphore(n, true)` is fair - waiters are served in FIFO order.
> Useful for rate limiting where you want predictable latency rather
> than some requests waiting much longer than others.
>
> In production, a `Semaphore(1)` is NOT a replacement for a lock
> when used in the same thread because it is not reentrant. If a
> thread holding a permit tries to acquire again, it blocks.
> `ReentrantLock` allows the same thread to acquire multiple times.
> For mutual exclusion within a single thread, use `ReentrantLock`.
> Use `Semaphore` for cross-thread resource pool control.

---

### 💻 Code Example

**Example 1: Connection pool with semaphore**

```java
// Semaphore-based connection pool (simplified)
public class ConnectionPool {
    private final Semaphore available;
    private final Queue<Connection> connections;

    public ConnectionPool(int poolSize) {
        available = new Semaphore(poolSize, true);  // fair: FIFO
        connections = new ConcurrentLinkedQueue<>();
        for (int i = 0; i < poolSize; i++) {
            connections.add(createConnection());
        }
    }

    public Connection acquire() throws InterruptedException {
        available.acquire();      // blocks if no connection available
        return connections.poll();
    }

    public Connection tryAcquire(long timeout, TimeUnit unit)
            throws InterruptedException {
        if (!available.tryAcquire(timeout, unit)) {
            return null;          // timeout - no connection available
        }
        return connections.poll();
    }

    public void release(Connection conn) {
        connections.offer(conn);
        available.release();      // any thread can release a permit
    }

    public int availableConnections() {
        return available.availablePermits();
    }
}

// Rate limiter using semaphore (token-bucket approximation)
public class RateLimiter {
    private final Semaphore permits;
    private final int maxPerSecond;

    public RateLimiter(int maxPerSecond) {
        this.maxPerSecond = maxPerSecond;
        this.permits = new Semaphore(maxPerSecond);
        // Refill permits every second
        Executors.newScheduledThreadPool(1).scheduleAtFixedRate(
            this::refill, 1, 1, TimeUnit.SECONDS
        );
    }

    public boolean allowRequest() {
        return permits.tryAcquire();  // non-blocking: false if exceeded
    }

    private void refill() {
        int needed = maxPerSecond - permits.availablePermits();
        if (needed > 0) permits.release(needed);
    }
}
```

> **Code walkthrough:** The connection pool uses `acquire()` to
> block callers until a connection is available - exactly the
> bounded-resource semantics needed. `tryAcquire(timeout)` adds
> a deadline for requests that cannot wait indefinitely. Any thread
> can call `release()` - the caller and the releaser are independent,
> matching the pool usage pattern where any thread can check in
> a connection. The rate limiter uses a scheduled refill to reset
> permits each second.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `Semaphore` controls access to a fixed number of resources.
> `acquire()` gets a permit (blocks if none available).
> `release()` returns a permit. Use it for connection pools,
> download limits, and concurrent access caps.

---

**Senior / Staff (5+ years):**

> In production, `Semaphore` is my tool for bounded concurrency:
> limit database connections, limit concurrent API calls to a
> third-party service, or implement back-pressure. The key insight
> is that any thread can release - unlike locks. I use fair mode
> for rate limiting (predictable queueing) and default mode for
> connection pools (higher throughput acceptable).

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between a Semaphore and a Lock?"

🗣️ "A lock is binary (acquired or not) and reentrant (same thread
can acquire multiple times). A semaphore maintains a count of permits
(N resources). The critical difference: a lock must be released
by the same thread that acquired it. A semaphore can be released
by any thread. This makes semaphores suitable for resource pool
management where the thread that returns the connection is not
the thread that borrowed it. Semaphore with 1 permit is a mutex
but NOT reentrant - the same thread acquiring again blocks."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Permit model, release by any thread, fair vs unfair. |
| Hiring Manager   | Connection pool design, rate limiting. |
| Bar Raiser       | Guava RateLimiter vs Semaphore, token bucket algorithm. |
| Peer Engineer    | "We used a semaphore to limit concurrent calls to our payment provider..." |

---

---

# CountDownLatch and CyclicBarrier

**Interview Weight:** high - Tests whether you can distinguish
one-shot countdown from reusable synchronization. Classic
use cases: startup gates, parallel test harness, parallel phases.

---

### 🎯 Model Answer

**30 seconds:**

> `CountDownLatch` is a one-shot synchronization gate: initialize
> with a count, decrement with `countDown()`, wait at `await()`.
> When the count reaches zero, all waiting threads proceed. It is
> not reusable. `CyclicBarrier` is reusable: N threads wait at
> `await()` until all N arrive, then all proceed to the next phase
> together. Use `CountDownLatch` for "wait for N things to complete".
> Use `CyclicBarrier` for "N threads rendezvous, then continue to
> the next phase."

**3 minutes (Senior):**

> Key distinction: `CountDownLatch.countDown()` can be called from
> any thread. The threads calling `countDown()` and the threads
> calling `await()` are typically different. The latch is a one-
> directional signal: tasks complete, and waiters are released.
>
> `CyclicBarrier` requires all participating threads to call
> `await()`. Each call `await()` blocks until the N-th thread
> arrives, then ALL threads are released simultaneously. It is
> "cyclic" because it automatically resets after all threads pass -
> it can be used in a loop for iterative parallel computation.
> A `Phaser` (Java 7+) is a more flexible generalization that
> allows dynamic registration/deregistration of participants.
>
> Use `CountDownLatch` for: server startup (wait for all services
> to initialize), test harness (trigger N worker threads simultaneously,
> then wait for all to finish). Use `CyclicBarrier` for: parallel
> iterative algorithms (matrix multiply phases), simulation steps
> where each phase must complete before the next begins.

---

### 💻 Code Example

**Example 1: CountDownLatch for startup and test timing**

```java
// CountDownLatch: wait for all services to start
int serviceCount = 3;
CountDownLatch startupLatch = new CountDownLatch(serviceCount);

// Services start asynchronously, each calls countDown() when ready
ExecutorService startup = Executors.newFixedThreadPool(serviceCount);
startup.submit(() -> { startDatabasePool(); startupLatch.countDown(); });
startup.submit(() -> { startCacheClient(); startupLatch.countDown(); });
startup.submit(() -> { startMessageBroker(); startupLatch.countDown(); });

// Main thread waits for all services
boolean allStarted = startupLatch.await(30, TimeUnit.SECONDS);
if (!allStarted) throw new RuntimeException("Startup timed out");
System.out.println("All services ready");

// Classic test harness: concurrent start, wait for all finish
int threadCount = 100;
CountDownLatch startGate  = new CountDownLatch(1);  // release all together
CountDownLatch endGate = new CountDownLatch(threadCount);

for (int i = 0; i < threadCount; i++) {
    pool.submit(() -> {
        try {
            startGate.await();     // ALL threads wait here
            doWork();
        } finally {
            endGate.countDown();   // signal completion
        }
    });
}
long start = System.nanoTime();
startGate.countDown();            // release all threads simultaneously
endGate.await();                  // wait for all to finish
long elapsed = System.nanoTime() - start;
```

> **Code walkthrough:** The startup latch uses `countDown()` from
> the service threads and `await()` from the main thread - different
> threads. The test harness pattern uses a start gate (count=1,
> all threads wait, then one countDown releases all simultaneously)
> and an end gate (count=threadCount, each thread counts down on
> completion). This gives accurate concurrent timing.

**Example 2: CyclicBarrier for parallel phases**

```java
// CyclicBarrier: parallel matrix computation in phases
int numThreads = Runtime.getRuntime().availableProcessors();
CyclicBarrier barrier = new CyclicBarrier(numThreads, () -> {
    // barrierAction: runs once when all threads reach barrier
    System.out.println("Phase complete, starting next phase");
    advanceToNextPhase();  // update shared state between phases
});

for (int t = 0; t < numThreads; t++) {
    final int threadId = t;
    pool.submit(() -> {
        for (int phase = 0; phase < NUM_PHASES; phase++) {
            computeMySlice(threadId, phase);  // parallel computation
            try {
                barrier.await();  // wait for ALL threads to complete phase
                // CYCLIC: barrier resets, all threads continue to next phase
            } catch (BrokenBarrierException e) {
                throw new RuntimeException("Barrier broken", e);
            }
        }
    });
}
```

> **Code walkthrough:** Each thread computes its slice of the work,
> then waits at `barrier.await()`. When all `numThreads` threads
> arrive, the optional `barrierAction` runs (single-threaded),
> then all threads are released simultaneously to start the next
> phase. The barrier resets automatically (cyclic). `BrokenBarrierException`
> is thrown if any thread is interrupted or times out while waiting
> - handle it to prevent the remaining threads from hanging.

---

### ⚖️ Comparison

| | CountDownLatch | CyclicBarrier | Phaser |
|--|----------------|---------------|--------|
| Reusable | no | yes | yes |
| Counter direction | count down to 0 | count up to N | flexible |
| Participants | fixed | fixed | dynamic |
| Barrier action | no | yes (optional) | no |
| Use case | one-shot wait | repeated phases | dynamic phases |

**The deciding factor:** One-shot wait for N events =
`CountDownLatch`. Repeated rendezvous of N threads = `CyclicBarrier`.
Dynamic participant registration = `Phaser`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `CountDownLatch` is one-shot: initialize with N, count down,
> await until 0. `CyclicBarrier` is reusable: N threads all call
> await(), when all arrive all proceed together. Use latch for
> startup/completion wait; barrier for parallel iterative phases.

---

**Senior / Staff (5+ years):**

> In production I use `CountDownLatch` for integration test harnesses
> (concurrent throughput measurement) and service initialization
> sequencing. `CyclicBarrier` for parallel batch processing with
> phases. For more complex scenarios - dynamic thread registration,
> multiple phase types - `Phaser` is more expressive.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between CountDownLatch and CyclicBarrier?"

🗣️ "`CountDownLatch` is a one-time gate: initialized with N,
`countDown()` decrements it, `await()` blocks until it reaches 0.
The counters and waiters can be different threads - multiple threads
can `countDown()` while one thread `await()`s. Once at 0, it cannot
be reset. `CyclicBarrier` is for N threads to rendezvous: all N
threads call `await()`, and when the N-th arrives, all N are released
simultaneously. It resets automatically, enabling iterative
parallel phases."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | One-shot vs cyclic, different-thread model for latch. |
| Hiring Manager   | Server startup sequencing use case. |
| Bar Raiser       | Phaser, BrokenBarrierException handling. |
| Peer Engineer    | "The start gate pattern gave us accurate concurrent throughput numbers..." |

---

---

# AtomicInteger and Atomic Variables

**Interview Weight:** high - Tests for CAS knowledge, the
difference from volatile, and when to use LongAdder instead.

---

### 🎯 Model Answer

**30 seconds:**

> `AtomicInteger` provides atomic read-modify-write operations on
> an integer using CAS (compare-and-swap) CPU instructions - no
> locks, no context switching. Key operations: `getAndIncrement()`,
> `incrementAndGet()`, `compareAndSet(expected, update)`. For high-
> contention counters (millions of increments per second from many
> threads), prefer `LongAdder` which distributes contention across
> cells and is faster than `AtomicLong` under high contention.

**3 minutes (Senior):**

> CAS (compare-and-swap) is a single atomic CPU instruction: "if
> the current value equals `expected`, set it to `update` and return
> true; otherwise return false." `AtomicInteger.incrementAndGet()`
> loops: read current value, compute current+1, CAS. If CAS fails
> (another thread changed the value), retry. Under low contention,
> this loop runs once. Under high contention, many threads retry,
> causing contention on the shared cache line.
>
> `LongAdder` solves high-contention increment: it maintains an
> array of cells, each on a separate cache line. Under contention,
> threads increment different cells. `sum()` sums all cells. This
> trades memory for throughput - `LongAdder.increment()` scales
> linearly with thread count, while `AtomicLong.incrementAndGet()`
> degrades as contention increases. The trade-off: `sum()` is not
> a snapshot (other threads may increment between cells being read).
> Use `LongAdder` for counters where you occasionally need the total,
> not for operations that require a single consistent snapshot.
>
> `AtomicReference<T>` enables lock-free reference swapping with
> CAS. `compareAndSet(expected, newRef)` atomically updates the
> reference if it still points to `expected`. Used for lock-free
> data structures and lazy initialization.
>
> The ABA problem: CAS fails to detect when a value changes from A
> to B and back to A. Thread 1 reads A, Thread 2 changes A→B→A,
> Thread 1's CAS succeeds even though the value was changed. For
> cases where this matters (linked lists, reference-based structures),
> use `AtomicStampedReference` which includes a version stamp in
> the CAS.

---

### 💻 Code Example

**Example 1: Atomic operations and LongAdder**

```java
// AtomicInteger for low-to-medium contention counters
AtomicInteger counter = new AtomicInteger(0);

// Atomic increment (safe from multiple threads)
counter.incrementAndGet();           // ++counter (returns new value)
counter.getAndIncrement();           // counter++ (returns old value)

// Conditional update with CAS
boolean updated = counter.compareAndSet(5, 10);  // if 5, set to 10
// Updated only if value was 5 at time of check

// Atomic update with function (Java 8+)
counter.updateAndGet(x -> x * 2);   // atomic double
counter.accumulateAndGet(10, Integer::sum);  // atomic add 10

// High-contention: LongAdder is faster (distributed cells)
LongAdder hitCount = new LongAdder();

// Multiple threads incrementing simultaneously - no CAS retries
hitCount.increment();      // fast: goes to thread-local cell
long total = hitCount.sum();  // sums all cells (not a snapshot)
hitCount.reset();          // set all cells to 0

// AtomicReference for lock-free lazy initialization
AtomicReference<ExpensiveService> service = new AtomicReference<>();

public ExpensiveService getService() {
    ExpensiveService s = service.get();
    if (s == null) {
        ExpensiveService created = new ExpensiveService();
        // Only one thread wins the CAS and sets the service
        if (service.compareAndSet(null, created)) {
            return created;
        }
        // Lost the CAS race: another thread set it, use theirs
        // (created is discarded - potential waste but no leak)
        return service.get();
    }
    return s;
}
```

> **Code walkthrough:** `incrementAndGet()` uses the CAS retry loop
> internally - thread-safe without a lock. `compareAndSet(5, 10)`
> is the CAS primitive exposed: only updates if the current value
> is exactly 5. `LongAdder.increment()` routes to a thread-local
> cell under contention, avoiding CAS retry loops entirely. The
> `AtomicReference` lazy init allows multiple threads to create
> `ExpensiveService` but only one CAS winner sets it - safe but
> may waste one creation.

**Example 2: Benchmark - AtomicLong vs LongAdder under contention**

```java
// Under HIGH CONTENTION (many threads, many increments):
// AtomicLong: CAS loop contention causes quadratic slowdown
AtomicLong atomic = new AtomicLong();
// Thread 1-100: atomic.incrementAndGet() - many CAS failures, retries

// LongAdder: distributes across cells, linear scaling
LongAdder adder = new LongAdder();
// Thread 1-100: adder.increment() - each goes to own cell
// adder.sum() at end - adds all cells

// Approximate benchmark guidance (not exact numbers):
// 1 thread:   AtomicLong ≈ LongAdder (no contention)
// 10 threads: AtomicLong slightly slower (some CAS retries)
// 100 threads: LongAdder ~2-5x faster (many CAS retries vs cells)
// Use AtomicLong when you need atomic get+increment in one op
// Use LongAdder when increment throughput is the priority
```

> **Code walkthrough:** The guidance is directional, not absolute -
> actual numbers depend on hardware, JVM version, and workload.
> The key insight: `AtomicLong` contention degrades because all
> threads write to the same cache line. `LongAdder` adds a cell
> array where each thread writes to a different cache line, eliminating
> CPU-level cache line bouncing.

---

### ⚖️ Comparison

| Class | Atomic Ops | Best For | Limitation |
|-------|-----------|----------|------------|
| `AtomicInteger` | increment, CAS | Low-medium contention counters | Slower under high contention |
| `AtomicLong` | increment, CAS | Low-medium contention long counters | Same |
| `LongAdder` | increment, decrement, sum | High-contention counters | sum() not a snapshot |
| `AtomicReference<T>` | CAS on reference | Lock-free ref updates | ABA problem |
| `AtomicStampedReference<T>` | CAS + version stamp | ABA-safe reference | More overhead |

**The deciding factor:** Counter with low-medium contention =
`AtomicInteger`. High-contention increment = `LongAdder`.
Reference update with condition = `AtomicReference`.
ABA-sensitive = `AtomicStampedReference`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `AtomicInteger` provides thread-safe operations without locks,
> using CAS hardware instructions. `incrementAndGet()` atomically
> increments and returns the new value. Use it instead of
> `synchronized int++`.

*Push deeper:* What is CAS? What does compareAndSet do?

---

**Senior / Staff (5+ years):**

> I default to `LongAdder` for counters in production metrics
> collection - it scales linearly with thread count under high
> contention. For single-variable atomic operations where I need
> CAS semantics (update if unchanged), `AtomicReference.compareAndSet()`
> is the right tool. I've seen `AtomicLong` be a bottleneck on
> 32+ core servers with high-throughput request counters - switching
> to `LongAdder` resolved the contention.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "What is compare-and-swap (CAS) and how does AtomicInteger use it?"

🗣️ "CAS is a hardware CPU instruction: atomically check if a
memory location has an expected value, and if so, replace it with
a new value. It returns whether the swap happened. `AtomicInteger.incrementAndGet()`
implements this as a CAS loop: read the current value, compute
current+1, CAS(current, current+1). If the CAS fails (another
thread changed the value between read and CAS), retry. Under low
contention, the loop runs once. Under high contention, many threads
fail the CAS and retry, creating a spin-retry overhead."

#### Performance and Scalability

- "When is LongAdder better than AtomicLong?"

🗣️ "Under high contention - many threads incrementing simultaneously.
`AtomicLong` stores the counter in a single memory location. Under
high contention, all threads fight over this location's cache line,
causing CAS failures and retries. `LongAdder` maintains an array
of cells, each on its own cache line. Under contention, threads
increment different cells. `sum()` adds all cells. The trade-off:
`sum()` is not instantaneous - concurrent increments during `sum()`
may be missed. Use `LongAdder` for statistics counters where a
slightly imprecise total is acceptable and increment throughput
matters."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | CAS, retry loop, AtomicLong vs LongAdder. |
| Hiring Manager   | Correctness: why synchronized int++ is wrong. |
| Bar Raiser       | ABA problem, AtomicStampedReference, VarHandle. |
| Peer Engineer    | "AtomicLong was the bottleneck on our 64-core server metric counter..." |
