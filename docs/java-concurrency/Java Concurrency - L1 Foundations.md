---
layout: default
title: "Java Concurrency - L1 Foundations"
parent: "Java Concurrency"
nav_order: 2
permalink: /java-concurrency/l1-foundations/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Thread Creation and Runnable](#thread-creation-and-runnable) | high |
| 2 | [synchronized Keyword](#synchronized-keyword) | high |
| 3 | [volatile Keyword](#volatile-keyword) | high |
| 4 | [Thread Interruption and Daemon Threads](#thread-interruption-and-daemon-threads) | high |
| 5 | [wait notify and notifyAll](#wait-notify-and-notifyall) | high |

---

# Thread Creation and Runnable

**Interview Weight:** high - Baseline knowledge. Interviewers
check for awareness of Thread vs Runnable, the deprecation of
`stop()`/`suspend()`, and why thread pools replace manual threads.

---

### 🎯 Model Answer

**30 seconds:**

> Threads are created by extending `Thread` or implementing
> `Runnable`. Prefer `Runnable` - it separates the task (what to
> do) from the thread (how to execute it). In production, never
> create threads directly; always use `ExecutorService`. Direct
> thread creation is unmanaged - no lifecycle, no reuse, no
> back-pressure, no monitoring.

**3 minutes (Senior):**

> The `Thread` class is both a runnable unit and the thread itself -
> a design mistake acknowledged by Java's own documentation. The
> `Runnable` interface separates the task from the execution
> mechanism, which is the correct design. Java 8 added `Callable<T>`
> (returns a value, throws checked exceptions) and lambda support
> makes both trivial.
>
> Creating an OS thread costs ~1MB of stack space and kernel
> resources. Creating 1,000 threads for 1,000 concurrent tasks
> costs ~1GB RAM before any work is done. Thread pools amortize
> this cost by reusing threads. With Java 21 virtual threads,
> the cost drops to ~few KB per virtual thread, enabling millions
> of concurrent tasks - but they still run on a fixed number of
> OS carrier threads.
>
> Never call `Thread.stop()`, `Thread.suspend()`, or `Thread.resume()`.
> They are deprecated because they are unsafe: `stop()` releases
> all locks held by the thread, leaving shared state in an
> inconsistent state. The safe way to stop a thread: use an
> interrupt flag and check `Thread.interrupted()` periodically,
> or use `Thread.interrupt()` which sets the interrupt status that
> blocking methods (`sleep`, `wait`, `join`) respond to with
> `InterruptedException`.

---

### 📘 Concept Explanation

**How it works:**

```java
// Three ways to define a task:
// 1. Extend Thread (not recommended - couples task and thread)
class MyThread extends Thread {
    public void run() { /* task code */ }
}
new MyThread().start();

// 2. Implement Runnable (preferred for tasks without return value)
Runnable task = () -> System.out.println("Task on: "
    + Thread.currentThread().getName());
new Thread(task).start();  // still creates a raw thread

// 3. Implement Callable (returns value, throws checked exceptions)
Callable<String> callable = () -> { return "result"; };

// In production: ALWAYS use ExecutorService
ExecutorService pool = Executors.newFixedThreadPool(4);
Future<String> future = pool.submit(callable);
String result = future.get();
```

**Thread creation cost:**

```
  OS Thread:       ~1 MB stack (configurable -Xss)
                   kernel thread object
                   scheduler entry
  
  Virtual Thread:  ~few KB (grows dynamically)
                   runs on carrier thread pool
                   parked when blocking (no OS thread consumed)
```

**The key insight:**

`thread.start()` calls the OS to create a kernel thread.
`run()` called directly executes on the current thread - a common
mistake in testing. Always use `start()`, never `run()`.

---

### 💻 Code Example

**Example 1: Thread creation anti-patterns and best practice**

```java
// BAD: Raw thread for each task (no pooling, no lifecycle)
for (int i = 0; i < 1000; i++) {
    new Thread(() -> processRequest()).start();  // 1000 OS threads!
}

// BAD: Calling run() instead of start() (runs on current thread)
Thread t = new Thread(() -> background());
t.run();   // NOT a new thread - runs synchronously!
t.start(); // this is what you want

// BAD: Extending Thread (couples task and execution)
class DataFetcher extends Thread {
    @Override public void run() { fetchData(); }
}
// Cannot submit a DataFetcher to an ExecutorService directly

// GOOD: Runnable with ExecutorService
ExecutorService pool = Executors.newFixedThreadPool(
    Runtime.getRuntime().availableProcessors()
);
Runnable task = () -> processRequest();
pool.submit(task);              // task queued, executed by pool thread

// Shutdown gracefully
pool.shutdown();                // stop accepting new tasks
if (!pool.awaitTermination(30, TimeUnit.SECONDS)) {
    pool.shutdownNow();         // force-interrupt running tasks
}

// Java 21: Virtual thread per task (no manual pool management)
try (ExecutorService vPool = Executors.newVirtualThreadPerTaskExecutor()) {
    IntStream.range(0, 100_000)
        .forEach(i -> vPool.submit(() -> processRequest()));
}  // auto-shutdown via AutoCloseable (Java 19+)
```

> **Code walkthrough:** Creating 1,000 OS threads consumes ~1GB
> stack space before any work begins. The pool reuses 4 OS threads
> for all 1,000 tasks via a queue. `run()` vs `start()` is a common
> beginner mistake - `run()` is a method call, `start()` creates
> a new thread. Virtual threads (Java 21) eliminate the
> `newFixedThreadPool` sizing problem: create as many as needed,
> the JVM manages OS thread usage automatically.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Implement `Runnable` for the task and submit it to an
> `ExecutorService`. Never create raw threads for production work.
> `Callable` is like `Runnable` but returns a value. Call
> `start()`, not `run()`, to actually create a new thread.

*Push deeper:* Why not extend Thread?

---

**Senior / Staff (5+ years):**

> Direct thread creation is legacy code. In production I use
> `ExecutorService` for managed pools and, in Java 21+, virtual
> threads for I/O-heavy workloads. The pool sizing question
> (CPU vs I/O threads) is critical: CPU-bound = `availableProcessors()`
> threads; I/O-bound = higher multiplier or virtual threads.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between Runnable and Callable?"

🗣️ "`Runnable` has a `run()` method that returns `void` and
cannot throw checked exceptions. `Callable<T>` has a `call()`
method that returns a value of type `T` and can throw a checked
exception. You submit both to an `ExecutorService`. With
`Runnable`, `submit()` returns `Future<?>` with `null` result.
With `Callable`, `submit()` returns `Future<T>` where you can
get the result with `future.get()`."

#### Debugging

- "Why does calling thread.run() not start a new thread?"

🗣️ "`run()` is just a method. Calling it invokes the method on
the current thread synchronously. `start()` is what creates a new
OS thread and then calls `run()` on that new thread. This is a
very common beginner mistake - the test passes because the code
runs correctly, but it does not actually test concurrent behavior."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | run() vs start(), Runnable vs Callable, thread cost. |
| Hiring Manager   | Why pool over raw threads in production. |
| Bar Raiser       | Virtual threads, carrier thread model, ThreadFactory. |
| Peer Engineer    | "Someone called thread.run() in a unit test and it 'worked'..." |

---

---

# synchronized Keyword

**Interview Weight:** high - Foundational synchronization primitive.
Tests whether you understand monitors, reentrancy, and the
performance implications.

---

### 🎯 Model Answer

**30 seconds:**

> `synchronized` in Java provides two guarantees: mutual exclusion
> (only one thread at a time in the synchronized block) and memory
> visibility (when a thread exits a synchronized block, all writes
> are flushed to main memory; when it enters, it reads fresh values).
> It can be applied to methods (locks on `this` or the Class) or
> to specific blocks with an explicit lock object. Java's built-in
> locks are reentrant: a thread that holds the lock can reacquire
> it without deadlocking itself.

**3 minutes (Senior):**

> Every Java object has an intrinsic lock (monitor). `synchronized(obj)`
> acquires `obj`'s monitor. Only one thread can hold a monitor at
> a time. Synchronized methods on an instance lock `this`; on static
> methods they lock the `Class` object.
>
> Reentrancy means if thread A holds lock L and calls a method
> synchronized on L, it succeeds without blocking - the lock count
> increments. This prevents common deadlocks in inheritance scenarios:
> a synchronized method in a subclass calling `super.method()` that
> is also synchronized on the same object.
>
> Performance: `synchronized` in HotSpot goes through three phases.
> First, biased locking: the JVM biases the object toward the first
> thread, making acquisition almost free. Then, thin lock (CAS-based):
> low overhead for uncontended access. Then, inflated lock: actual
> OS mutex when contended. Post-Java 15, biased locking is deprecated
> (not worth the deoptimization cost). In modern JVMs, uncontended
> `synchronized` is cheap (a few nanoseconds).
>
> When NOT to use `synchronized`: avoid synchronizing on publicly
> accessible objects (`this`, class literals, string literals),
> because external code can acquire the same lock and cause livelock
> or performance issues. Always use a private `final Object lock = new Object()`
> for internal synchronization.

---

### 💻 Code Example

**Example 1: Correct and incorrect synchronized patterns**

```java
// BAD: Synchronizing on 'this' - callers can interfere
public class PublicLockBug {
    public synchronized void doWork() { /* ... */ }
    // External code: synchronized (myObj) { ... } acquires same lock!
}

// BAD: Synchronizing on a string literal (interned - shared JVM-wide!)
public void badSync() {
    synchronized ("LOCK") {  // ALL code synchronizing on "LOCK" shares it!
        update();
    }
}

// GOOD: Private lock object - safe from external interference
public class SafeCache {
    private final Object lock = new Object();  // private, not accessible
    private final Map<String, String> cache = new HashMap<>();

    public String get(String key) {
        synchronized (lock) {
            return cache.get(key);
        }
    }

    public void put(String key, String value) {
        synchronized (lock) {
            cache.put(key, value);
        }
    }
}

// GOOD: Reentrant - same thread can acquire multiple times
public class ReentrantExample {
    public synchronized void outer() {
        inner();  // same thread, same lock: succeeds, count = 2
    }
    public synchronized void inner() { /* count was 1, now 2 */ }
}
// Without reentrancy, outer() calling inner() on the same instance
// would deadlock with itself
```

> **Code walkthrough:** Synchronizing on `"LOCK"` (a string literal)
> acquires a lock on the interned string, which is shared across
> the entire JVM. Any other code synchronizing on the same literal
> would block. The private lock pattern is the correct idiom:
> only the owning class can acquire this lock. Reentrancy prevents
> the inner method deadlock - the JVM tracks the lock acquisition
> count per thread.

---

### ⚖️ Comparison

| Feature | synchronized | ReentrantLock |
|---------|--------------|---------------|
| Syntax | keyword | explicit lock/unlock |
| Reentrant | yes | yes |
| Fairness | no | optional (true) |
| Timed tryLock | no | yes |
| Condition variables | one (wait/notify) | multiple (newCondition()) |
| Interruptible acquire | no | yes (lockInterruptibly()) |
| Thread dump visibility | shows BLOCKED | shows WAITING (park) |

**The deciding factor:** `synchronized` for simple mutual exclusion.
`ReentrantLock` when you need timed/interruptible acquisition,
fairness, or multiple condition variables.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `synchronized` provides mutual exclusion and memory visibility.
> A synchronized method or block is entered by at most one thread
> at a time. Java locks are reentrant: the same thread can re-
> acquire its own lock without blocking.

*Push deeper:* What object is the lock on a static synchronized method?

---

**Senior / Staff (5+ years):**

> In production I prefer `ConcurrentHashMap` and atomic types over
> `synchronized` for most cases - they have finer-grained locking
> and better throughput. When I do use `synchronized`, I keep
> critical sections as short as possible (lock acquisition +
> minimal work + lock release), never call external code inside
> a synchronized block (risk of deadlock), and always synchronize
> on a private lock object.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "What is an intrinsic lock in Java?"

🗣️ "Every Java object has a built-in lock called the intrinsic
lock or monitor. When a thread executes `synchronized(obj)`, it
acquires `obj`'s intrinsic lock. If another thread tries to
acquire the same lock, it blocks (enters BLOCKED state). When the
first thread exits the synchronized block, it releases the lock
and a blocked thread can acquire it. For synchronized instance
methods, the implicit lock object is `this`. For synchronized
static methods, the lock is the `Class` object."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Monitor, reentrancy, static vs instance lock. |
| Hiring Manager   | Critical section discipline in code review. |
| Bar Raiser       | synchronized vs ReentrantLock, StampedLock. |
| Peer Engineer    | "Synchronizing on a String literal caused a cross-component deadlock..." |

---

---

# volatile Keyword

**Interview Weight:** high - One of the most misunderstood keywords.
Tests whether you correctly understand the atomicity vs visibility
distinction.

---

### 🎯 Model Answer

**30 seconds:**

> `volatile` in Java guarantees two things: (1) visibility - writes
> to a volatile variable are immediately visible to all other threads
> (no CPU cache, always reads from main memory); (2) ordering -
> prevents the compiler and CPU from reordering instructions around
> the volatile read/write (establishes a happens-before relationship).
> It does NOT provide atomicity for compound operations like `count++`.

**3 minutes (Senior):**

> Without `volatile`, the Java Memory Model allows threads to cache
> variables in CPU registers or L1/L2 cache. Thread A may write
> `running = false` but thread B reads a stale cached `true` forever.
> `volatile` forces writes to main memory and reads to bypass the
> cache.
>
> The happens-before guarantee: a write to a `volatile` variable
> happens-before every subsequent read of that same variable. This
> is stronger than just visibility - it means all actions prior to
> the volatile write are visible to the thread that reads the volatile.
> This is why double-checked locking requires `volatile`: the write
> to `instance` (and the constructor work before it) must happen-
> before any thread reads `instance` as non-null.
>
> `volatile long` and `volatile double`: without volatile, 64-bit
> reads/writes may be split into two 32-bit operations on some
> platforms, creating a race condition even on a single read/write.
> `volatile` guarantees 64-bit atomicity.
>
> When NOT to use volatile: when you need atomicity for compound
> operations (count++, check-then-act). `volatile` is not a
> replacement for `synchronized`; it is a lighter-weight complement
> for cases where you only need visibility and ordering, not atomicity.

---

### 💻 Code Example

**Example 1: Volatile for control flag**

```java
// BAD: Without volatile - thread may loop forever (stale cache)
public class InfiniteLoopBug {
    private boolean running = true;     // NOT volatile

    public void runTask() {
        while (running) {               // JIT may cache 'running' = true
            processNext();              // and never re-read from memory
        }
    }

    public void stop() {
        running = false;                // Thread B writes, Thread A never sees
    }
}

// GOOD: volatile guarantees visibility across threads
public class CorrectLoop {
    private volatile boolean running = true;

    public void runTask() {
        while (running) {  // re-reads from main memory each iteration
            processNext();
        }
    }

    public void stop() {
        running = false;  // immediately visible to all threads
    }
}

// WRONG: volatile does NOT fix compound operations
public class StillBroken {
    private volatile int count = 0;

    public void increment() {
        count++;  // STILL BROKEN: read, increment, write - not atomic
    }             // volatile only ensures each read/write is visible,
                  // not that the three operations are indivisible
}

// CORRECT: Use AtomicInteger for atomic increment
private final AtomicInteger count = new AtomicInteger(0);
public void increment() { count.incrementAndGet(); }  // truly atomic
```

> **Code walkthrough:** The `running = false` write without volatile
> may stay in Thread B's CPU cache and never reach main memory.
> The JIT compiler may even optimize the `while (running)` loop
> into an infinite loop by hoisting the read. `volatile` prevents
> both. The broken `volatile count++` shows the common misconception:
> `volatile` makes each read/write visible, but `count++` is three
> operations - another thread can see the count between the read
> and the write.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `volatile` makes a variable's writes immediately visible to all
> threads, bypassing CPU caches. It guarantees visibility and
> ordering but NOT atomicity. Use it for control flags and simple
> published references. Use AtomicInteger for counters.

---

**Senior / Staff (5+ years):**

> I use `volatile` in two specific patterns: (1) a stop/running
> flag read by a loop thread and written by the control thread.
> (2) double-checked locking - the `instance` field must be
> volatile to prevent the construction reorder. For everything else,
> I use higher-level tools. I explicitly explain the happens-before
> semantics of volatile when reviewing code: the pre-condition is
> not just "visible," it is "all actions before the write are
> visible after the read."

---

### ❓ Questions You Will Be Asked

#### Definition

- "What does volatile guarantee and what does it NOT guarantee?"

🗣️ "`volatile` guarantees two things. First, visibility: writes
to the variable are immediately visible to all other threads -
no CPU cache, always reads from main memory. Second, ordering: it
establishes a happens-before relationship - all actions before
the write are visible to anyone who subsequently reads the volatile
variable. What `volatile` does NOT guarantee: atomicity for compound
operations. `count++` with a volatile count is still a race
condition because read-increment-write is three non-atomic
operations."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Atomicity vs visibility, happens-before, 64-bit atomicity. |
| Hiring Manager   | Real-world patterns where volatile is appropriate. |
| Bar Raiser       | Memory model formal semantics, VarHandle (Java 9+). |
| Peer Engineer    | "Our stop flag bug was a visibility issue - volatile fixed it instantly..." |

---

---

# Thread Interruption and Daemon Threads

**Interview Weight:** high - Tests for correct understanding of
cooperative thread cancellation. The most common mistake: catching
`InterruptedException` and doing nothing.

---

### 🎯 Model Answer

**30 seconds:**

> Thread interruption is a cooperative cancellation mechanism.
> `thread.interrupt()` sets the interrupt flag. Blocking methods
> (`sleep`, `wait`, `join`, `BlockingQueue.take()`) check this
> flag and throw `InterruptedException` when interrupted. The
> critical rule: when you catch `InterruptedException`, either
> re-interrupt the thread (`Thread.currentThread().interrupt()`)
> or propagate the exception up. Never silently swallow it.
> Daemon threads are background threads that do not prevent JVM
> shutdown - the JVM exits when all non-daemon threads complete.

**3 minutes (Senior):**

> The interruption mechanism is cooperative: it does not forcibly
> stop a thread. `thread.interrupt()` sets a flag. The thread being
> interrupted must check this flag periodically. Blocking methods
> in the JDK honor this contract: `Thread.sleep()`, `Object.wait()`,
> `BlockingQueue.take()` all throw `InterruptedException` when the
> interrupt flag is set. Code that calls them must handle or
> propagate the exception.
>
> The most common mistake: catching `InterruptedException` and
> continuing execution as if nothing happened:
> `catch (InterruptedException e) { /* ignore */ }`.
> This permanently clears the interrupt flag, preventing any
> upstream code from detecting that the thread was interrupted.
> The correct handling: either (1) re-set the flag:
> `Thread.currentThread().interrupt()`, or (2) propagate:
> `throws InterruptedException`, or (3) wrap in an unchecked:
> `throw new RuntimeException(e)` (with re-interrupt before throw
> in frameworks).
>
> Daemon threads: all threads started by `main()` are non-daemon
> by default. Set a thread as daemon BEFORE starting it:
> `thread.setDaemon(true)`. When the last non-daemon thread exits,
> the JVM shuts down immediately - daemon threads are killed without
> completing. Use daemon threads for monitoring/logging threads
> that should not prevent shutdown. Never use them for threads
> that must complete work (file writing, database transactions).

---

### 💻 Code Example

**Example 1: Correct interruption handling**

```java
// BAD: Swallowing InterruptedException - permanently clears flag
public void processLoop() {
    while (true) {
        try {
            Task task = queue.take();  // blocks until task available
            process(task);
        } catch (InterruptedException e) {
            // WRONG: flag cleared, loop continues, no cancellation
        }
    }
}

// BAD: Checking flag wrong way
while (!Thread.interrupted()) {  // clears the flag on true!
    // ... if you check interrupted() here again, it returns false
}

// GOOD: Propagate InterruptedException (preferred in libraries)
public void processLoop() throws InterruptedException {
    while (!Thread.currentThread().isInterrupted()) {
        Task task = queue.take();   // throws InterruptedException if interrupted
        process(task);
    }
}

// GOOD: Re-interrupt when cannot propagate (in Runnable.run())
public void run() {
    while (!Thread.currentThread().isInterrupted()) {
        try {
            Task task = queue.take();
            process(task);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();  // restore flag
            break;                               // exit loop
        }
    }
    cleanup();  // guaranteed to run
}
```

> **Code walkthrough:** `queue.take()` throws `InterruptedException`
> when the thread's interrupt flag is set, AND clears the flag in
> the process. If you catch and ignore it, the flag stays cleared -
> the next `queue.take()` will block normally. Re-interrupting
> with `Thread.currentThread().interrupt()` restores the flag so
> upstream code can detect the interruption. Breaking the loop after
> re-interrupt ensures the thread terminates correctly.

**Example 2: Daemon thread**

```java
// GOOD: Daemon thread for background monitoring
Thread metricsThread = new Thread(() -> {
    while (true) {
        reportMetrics();
        try { Thread.sleep(60_000); }
        catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            break;
        }
    }
});
metricsThread.setDaemon(true);  // MUST be before start()
metricsThread.start();
// When main() completes, JVM shuts down immediately
// metricsThread is killed mid-sleep if in progress - that is fine for metrics

// BAD: Daemon thread for critical work
Thread dbWriteThread = new Thread(this::flushPendingRecords);
dbWriteThread.setDaemon(true);  // WRONG: may be killed mid-flush on shutdown
dbWriteThread.start();
// JVM exits, data not flushed, database corruption possible
```

> **Code walkthrough:** The metrics thread is a good daemon thread
> candidate: if the JVM exits, losing one metrics batch is acceptable.
> The database flush thread must NOT be a daemon - if the JVM exits
> while it is mid-flush, data loss or corruption follows. Daemon
> threads are for fire-and-forget background monitoring, not for
> work that must complete.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Thread interruption is cooperative. `interrupt()` sets a flag.
> Blocking methods throw `InterruptedException` when interrupted.
> Never swallow `InterruptedException` silently - re-interrupt or
> propagate. Daemon threads exit when all non-daemon threads finish.

---

**Senior / Staff (5+ years):**

> Interruption is the standard cancellation protocol for blocking
> Java code. In library code, I declare `throws InterruptedException`.
> In `Runnable.run()` (which cannot throw checked exceptions), I
> re-interrupt before breaking out. I enforce this in code reviews -
> `catch (InterruptedException e) {}` is a bug I flag every time.
> For ExecutorService tasks, the framework sets the interrupt flag
> when `shutdownNow()` is called - tasks that honor interruption
> stop quickly; tasks that swallow it block the shutdown.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "Your ExecutorService.shutdownNow() hangs and never returns.
  What is the cause?"

🗣️ "The tasks submitted to the pool are swallowing
`InterruptedException`. `shutdownNow()` calls `interrupt()` on all
running threads, but tasks that catch `InterruptedException` and
continue working will never terminate. The fix: ensure all tasks
check the interrupt flag or propagate `InterruptedException`. Also
check for tight CPU loops that never call a blocking method -
these tasks would also not respond to interruption. The fix there:
add `if (Thread.currentThread().isInterrupted()) break;` checks
in the loop."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Cooperative mechanism, re-interrupt protocol. |
| Hiring Manager   | shutdownNow() behavior, graceful shutdown. |
| Bar Raiser       | Thread.interrupted() vs isInterrupted() clearing behavior. |
| Peer Engineer    | "shutdownNow() took 60 seconds - all tasks were swallowing the exception..." |

---

---

# wait notify and notifyAll

**Interview Weight:** high - Tests whether you understand the
wait-set, spurious wakeups, and why higher-level APIs exist to
replace this pattern.

---

### 🎯 Model Answer

**30 seconds:**

> `wait()`, `notify()`, and `notifyAll()` are the low-level thread
> coordination primitives on Java's `Object` class. `wait()` causes
> the current thread to release the lock and enter a waiting state.
> `notify()` wakes one waiting thread. `notifyAll()` wakes all
> waiting threads. They must be called within a `synchronized`
> block on the same object. The cardinal rule: always check the
> wait condition in a `while` loop, not an `if`, because of
> spurious wakeups.

**3 minutes (Senior):**

> The `wait/notify` pattern implements a monitor condition variable.
> The canonical usage: a thread checks a condition, if not met it
> `wait()`s (releases lock, parks), another thread changes the
> condition and calls `notifyAll()`, the waiting thread wakes up
> and re-checks.
>
> Why `while`, not `if`: spurious wakeups. The JVM is allowed to
> wake a thread from `wait()` without any `notify()` being called,
> without the condition being true. Using `if (condition) wait()`
> can proceed on a spurious wakeup when the condition is still
> false. Using `while (!condition) wait()` re-checks after every
> wakeup.
>
> Why `notifyAll()` over `notify()`: `notify()` wakes exactly one
> waiting thread chosen by the JVM. If the chosen thread cannot
> proceed (the condition is not met for it), and no other notify
> comes, the other waiting threads wait forever (missed wakeup or
> effective deadlock). `notifyAll()` wakes all and lets each check
> the condition and proceed or re-wait. For most cases, prefer
> `notifyAll()`.
>
> In modern code, replace `wait/notify` with `BlockingQueue` for
> producer-consumer, or `ReentrantLock.newCondition()` for explicit
> condition variables with multiple conditions on the same lock.
> `wait/notify` is legacy API for new code.

---

### 💻 Code Example

**Example 1: Correct wait/notify with while loop**

```java
// BAD: Using if instead of while - spurious wakeup bug
public void consume() throws InterruptedException {
    synchronized (lock) {
        if (queue.isEmpty()) {       // WRONG: if, not while
            lock.wait();             // could wake spuriously
        }
        process(queue.remove());     // may throw NoSuchElementException!
    }
}

// GOOD: Always while loop around wait()
public class BoundedBuffer<T> {
    private final Queue<T> buffer = new LinkedList<>();
    private final int capacity;
    private final Object lock = new Object();

    public void put(T item) throws InterruptedException {
        synchronized (lock) {
            while (buffer.size() == capacity) {  // while, not if
                lock.wait();  // releases lock, parks thread
            }
            buffer.add(item);
            lock.notifyAll();  // wake consumers (and other producers)
        }
    }

    public T take() throws InterruptedException {
        synchronized (lock) {
            while (buffer.isEmpty()) {          // while, not if
                lock.wait();
            }
            T item = buffer.remove();
            lock.notifyAll();  // wake producers (and other consumers)
            return item;
        }
    }
}
```

> **Code walkthrough:** `wait()` releases the lock and parks the
> thread atomically - no race condition between checking the
> condition and releasing the lock. The `while` loop re-checks
> after every wakeup because: (1) spurious wakeups may occur;
> (2) another thread may have acquired the lock and consumed the
> item before this thread runs. `notifyAll()` is preferred over
> `notify()` here because both producers and consumers wait on
> the same lock - a consumer should not wake a producer waiting
> for space (which `notify()` might do).

**Example 2: Modern replacement with BlockingQueue**

```java
// GOOD: BlockingQueue replaces wait/notify for producer-consumer
BlockingQueue<Task> queue = new LinkedBlockingQueue<>(100);

// Producer thread:
void produce() throws InterruptedException {
    queue.put(createTask());  // blocks when full
}

// Consumer thread:
void consume() throws InterruptedException {
    Task task = queue.take();  // blocks when empty
    process(task);
}
// No explicit synchronization needed, no while loops, no notify
```

> **Code walkthrough:** `LinkedBlockingQueue` implements the bounded
> buffer pattern internally with `ReentrantLock` and two `Condition`
> objects (notFull, notEmpty). `put()` internally does the while-
> loop wait on `notFull`, and `take()` waits on `notEmpty`. This
> replaces the entire `BoundedBuffer` class above with two lines.
> Always prefer `BlockingQueue` for producer-consumer.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `wait()`, `notify()`, `notifyAll()` are called within a
> synchronized block. `wait()` releases the lock and parks the
> thread. `notify()` wakes one thread, `notifyAll()` wakes all.
> Always wrap `wait()` in a `while` loop, not `if`, to handle
> spurious wakeups. In new code, use `BlockingQueue` or
> `ReentrantLock.Condition` instead.

---

**Senior / Staff (5+ years):**

> In new code I never use `wait/notify` - I use `BlockingQueue`
> for producer-consumer and `Condition` variables on `ReentrantLock`
> when I need multiple conditions on the same lock. Understanding
> `wait/notify` is important for reading legacy code and for
> understanding what `BlockingQueue` does internally. The invariant
> is the same: always while loop, always synchronize on the object
> you wait on, always re-check the condition after wakeup.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "Why must wait() be called in a while loop and not an if?"

🗣️ "Two reasons. First: spurious wakeups. The Java Language
Specification explicitly permits `wait()` to return without any
thread calling `notify()`, for implementation reasons. If you
use `if`, the code continues executing despite the condition not
being met. Second: missed signals and multiple waiters. If two
threads are both waiting and one `notify()` is called, one thread
wakes up, re-acquires the lock, and processes. The other thread
eventually wakes (from notifyAll or another notify) but the
condition may no longer be true because the first thread consumed
it. The `while` loop re-checks and re-waits if needed."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Spurious wakeups, notify vs notifyAll, synchronized requirement. |
| Hiring Manager   | Why BlockingQueue replaces this pattern. |
| Bar Raiser       | Condition variables (ReentrantLock.newCondition()), park/unpark. |
| Peer Engineer    | "Missed notify caused our background thread to wait 30 minutes..." |
