---
layout: default
title: "Java Concurrency - L3 Thread Pools"
parent: "Java Concurrency"
nav_order: 5
permalink: /java-concurrency/l3-thread-pools/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [ExecutorService and Executor](#executorservice-and-executor) | high |
| 2 | [ThreadPoolExecutor Internals](#threadpoolexecutor-internals) | high |
| 3 | [ForkJoinPool and Work Stealing](#forkjoinpool-and-work-stealing) | high |
| 4 | [ScheduledExecutorService](#scheduledexecutorservice) | high |
| 5 | [Callable and Future](#callable-and-future) | high |

---

# ExecutorService and Executor

**Interview Weight:** high - The foundation of managed concurrency.
Tests pool lifecycle, graceful shutdown, and the difference between
`execute()` and `submit()`.

---

### 🎯 Model Answer

**30 seconds:**

> `ExecutorService` manages a pool of reusable threads. You submit
> tasks; the pool executes them on available threads. Key methods:
> `submit()` (returns `Future`), `execute()` (fire-and-forget, no
> future), `shutdown()` (stop accepting, finish queued tasks),
> `shutdownNow()` (stop accepting, interrupt running tasks, return
> unstarted tasks). Never create raw threads in production - always
> use an `ExecutorService`.

**3 minutes (Senior):**

> `Executors` factory methods provide common pool configurations:
> - `newFixedThreadPool(n)`: fixed N threads, `LinkedBlockingQueue`
>   (UNBOUNDED - can OOM under load)
> - `newCachedThreadPool()`: grows on demand, 60s idle timeout,
>   `SynchronousQueue` - can create unlimited threads
> - `newSingleThreadExecutor()`: one thread, ordered queue, replaces
>   itself on failure
> - `newWorkStealingPool()`: ForkJoinPool with parallelism = CPU count
>
> Shutdown is a lifecycle concern. `shutdown()` allows submitted
> tasks to complete; `shutdownNow()` interrupts them. After
> `shutdown()`, submitting a task throws `RejectedExecutionException`.
> Always await termination after shutdown: `awaitTermination(30, SECONDS)`.
>
> `execute()` vs `submit()`: `execute()` swallows exceptions -
> if the task throws, the exception is caught by the
> `UncaughtExceptionHandler` but not propagated to the caller.
> `submit()` wraps the task in a `FutureTask`. If the task throws,
> the exception is stored in the `Future` and re-thrown when
> `future.get()` is called. This is a critical debugging point:
> tasks that throw and are submitted via `execute()` silently
> disappear unless a `UncaughtExceptionHandler` is set.

---

### 💻 Code Example

**Example 1: Pool creation and lifecycle**

```java
// BAD: Executors.newFixedThreadPool - UNBOUNDED queue - OOM risk
ExecutorService pool = Executors.newFixedThreadPool(10);
// Default LinkedBlockingQueue capacity = Integer.MAX_VALUE
// Under sustained overload: queue grows to millions of tasks, OOM

// GOOD: Custom ThreadPoolExecutor with bounded queue
ExecutorService pool = new ThreadPoolExecutor(
    4,                              // corePoolSize
    8,                              // maximumPoolSize
    60L, TimeUnit.SECONDS,          // keepAlive for idle threads above core
    new ArrayBlockingQueue<>(1000), // BOUNDED queue: back-pressure
    new ThreadFactory() {           // named threads for debugging
        AtomicInteger count = new AtomicInteger();
        public Thread newThread(Runnable r) {
            Thread t = new Thread(r, "worker-" + count.incrementAndGet());
            t.setDaemon(false);
            return t;
        }
    },
    new ThreadPoolExecutor.CallerRunsPolicy()  // back-pressure: caller executes
);

// Graceful shutdown pattern
pool.shutdown();                                  // stop accepting new tasks
try {
    if (!pool.awaitTermination(30, TimeUnit.SECONDS)) {
        pool.shutdownNow();                       // force-interrupt running tasks
        if (!pool.awaitTermination(10, TimeUnit.SECONDS)) {
            System.err.println("Pool did not terminate");
        }
    }
} catch (InterruptedException e) {
    pool.shutdownNow();
    Thread.currentThread().interrupt();
}

// submit() captures exceptions; execute() swallows them
Future<String> f = pool.submit(() -> {
    throw new RuntimeException("Task failed");  // stored in Future
});
try {
    String result = f.get();          // throws ExecutionException
} catch (ExecutionException e) {
    Throwable cause = e.getCause();   // the actual RuntimeException
}

// execute() - exception goes to UncaughtExceptionHandler (or is lost)
pool.execute(() -> {
    throw new RuntimeException("Silently disappears if no handler");
});
```

> **Code walkthrough:** The bounded `ArrayBlockingQueue(1000)` provides
> back-pressure: when 1,000 tasks are queued and all 8 threads are
> busy, `CallerRunsPolicy` makes the submitting thread execute the
> task itself - slowing the producer naturally. The unbounded
> `LinkedBlockingQueue` in `Executors.newFixedThreadPool()` can
> OOM under sustained overload. The `submit()` exception wrapping
> means exceptions are surfaced when you call `future.get()`, not
> silently.

---

### ⚖️ Comparison

| Factory Method | Threads | Queue | Risk |
|---------------|---------|-------|------|
| newFixedThreadPool(n) | fixed n | unbounded LBQ | OOM under overload |
| newCachedThreadPool() | unlimited | SynchronousQueue | unlimited thread creation |
| newSingleThreadExecutor() | 1 | unbounded LBQ | OOM under overload |
| Custom TPE (recommended) | bounded | bounded ABQ | Rejection (controllable) |
| newVirtualThreadPerTaskExecutor() | unlimited virtual | none | N/A (Java 21+) |

**The deciding factor:** Use custom `ThreadPoolExecutor` with bounded
queues in production. Never use default factory methods for
production workloads.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `ExecutorService` manages thread pools. `submit()` returns a
> `Future`. `shutdown()` gracefully stops the pool. Always use
> `ExecutorService` instead of raw threads.

*Push deeper:* What is the risk of newFixedThreadPool's default queue?

---

**Senior / Staff (5+ years):**

> I always create custom `ThreadPoolExecutor` with named threads,
> bounded queue, and an explicit rejection policy. Thread names
> make thread dumps readable ("worker-1" instead of "Thread-47").
> Bounded queues prevent OOM. Rejection policies define the
> back-pressure behavior explicitly.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "What is the difference between submit() and execute()?"

🗣️ "`execute()` runs the task asynchronously and has no return
value. If the task throws an exception, it is caught by the thread's
`UncaughtExceptionHandler`. If no handler is set, the exception
is lost silently. `submit()` wraps the task in a `FutureTask` and
returns a `Future`. If the task throws, the exception is stored
in the `Future` and re-thrown as `ExecutionException` when you
call `future.get()`. For tasks where you care about completion
or errors, always use `submit()` and check the `Future`."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | execute vs submit, shutdown lifecycle, rejection policies. |
| Hiring Manager   | OOM risk from unbounded queues - production safety. |
| Bar Raiser       | ThreadFactory, CallerRunsPolicy, virtual thread executor. |
| Peer Engineer    | "Our Executors.newFixedThreadPool had an unbounded queue and OOMed at 2 AM..." |

---

---

# ThreadPoolExecutor Internals

**Interview Weight:** high - Expert-level question testing knowledge
of core/max threads, queue, and the decision logic for when new
threads are created.

---

### 🎯 Model Answer

**30 seconds:**

> `ThreadPoolExecutor` has 5 parameters that control behavior:
> `corePoolSize` (always-alive threads), `maximumPoolSize`
> (max threads ever), `keepAliveTime` (idle thread timeout above
> core), `workQueue` (task buffer), and `RejectedExecutionHandler`
> (behavior when queue full and at max threads). The creation logic:
> if below core → create new thread. If at core → queue task.
> If queue full + below max → create new thread. If at max + queue
> full → reject.

**3 minutes (Senior):**

> The thread creation decision is counter-intuitive: new threads
> are created above core size only when the queue is full. This
> means with a large unbounded queue, `maximumPoolSize` is never
> reached. A `LinkedBlockingQueue(Integer.MAX_VALUE)` means the
> queue never fills, so you always have exactly `corePoolSize`
> threads regardless of `maximumPoolSize`.
>
> This is the key insight behind the Tomcat thread pool: Tomcat
> uses a custom `TaskQueue` that reports `offer()` returning false
> when threads are below max, causing `ThreadPoolExecutor` to
> create threads up to max BEFORE queuing. This reverses the
> standard behavior: threads up to max first, then queue.
>
> Four rejection policies:
> - `AbortPolicy` (default): throw `RejectedExecutionException`
> - `CallerRunsPolicy`: caller thread executes the task (back-pressure)
> - `DiscardPolicy`: silently drop the task (dangerous - silent loss)
> - `DiscardOldestPolicy`: discard the oldest queued task, retry submit
>   (dangerous for ordered tasks)
>
> `prestartAllCoreThreads()` starts all core threads immediately
> at construction, useful for initialization-sensitive workloads
> that need threads ready before the first task arrives.

---

### 💻 Code Example

**Example 1: ThreadPoolExecutor creation logic**

```java
ThreadPoolExecutor pool = new ThreadPoolExecutor(
    2,    // corePoolSize: always 2 threads active
    8,    // maximumPoolSize: up to 8 threads if queue full
    30,   // keepAliveTime: threads above 2 exit after 30s idle
    TimeUnit.SECONDS,
    new ArrayBlockingQueue<>(100),   // queue: holds up to 100 tasks
    Executors.defaultThreadFactory(),
    new ThreadPoolExecutor.CallerRunsPolicy()
);

// Decision logic for submit():
// Task 1-2: below core (2) → create threads T1, T2
// Task 3-102: core threads busy → queue (up to 100)
// Task 103-109: queue full (100) + below max (8) → create T3-T8
// Task 110+: queue full + at max (8) → CallerRunsPolicy (caller executes)

// Monitoring thread pool health
System.out.println("Active: " + pool.getActiveCount());
System.out.println("Pool size: " + pool.getPoolSize());
System.out.println("Queue size: " + pool.getQueue().size());
System.out.println("Completed: " + pool.getCompletedTaskCount());

// Dynamically resize pool (change core/max at runtime)
pool.setCorePoolSize(4);     // increase core (starts threads immediately)
pool.setMaximumPoolSize(16); // increase max
```

> **Code walkthrough:** Threads are created up to `corePoolSize`
> eagerly (one per task). Then tasks queue up to 100. Only when
> the queue is full do threads grow toward `maximumPoolSize`.
> `CallerRunsPolicy` is back-pressure: when at max capacity,
> the submitting thread runs the task, naturally throttling the
> producer without dropping tasks. The monitoring methods give
> real-time visibility into pool saturation.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `ThreadPoolExecutor` has core size, max size, queue, and keepAlive.
> Tasks run on core threads first, then queue, then threads grow
> to max if queue full. Exceeding max triggers the rejection policy.

---

**Senior / Staff (5+ years):**

> The thread creation logic is counterintuitive and catches many
> engineers. New threads are created above core only when the queue
> is full. With unbounded queues, max threads is irrelevant. I size
> the queue based on acceptable latency and memory: small queue for
> tight back-pressure, larger queue for burst absorption.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "When does ThreadPoolExecutor create a new thread?"

🗣️ "Three scenarios. First: when the current pool size is below
`corePoolSize` - each new task gets a new thread. Second: when
all core threads are busy AND the task queue is full AND pool size
is below `maximumPoolSize` - a burst thread is created. Third:
when `prestartCoreThread()` or `prestartAllCoreThreads()` is called
explicitly. The key insight: with an unbounded queue, the pool
never reaches `maximumPoolSize` because the queue never fills.
This is why `Executors.newFixedThreadPool(n)` always has exactly
n threads regardless of the `maximumPoolSize` parameter."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Five constructor params, creation logic, rejection policies. |
| Hiring Manager   | Sizing strategy for different workload types. |
| Bar Raiser       | Tomcat custom TaskQueue pattern, prestartAllCoreThreads. |
| Peer Engineer    | "Set maximumPoolSize=100 with unbounded queue - always only had 4 threads..." |

---

---

# ForkJoinPool and Work Stealing

**Interview Weight:** high - Tests knowledge of divide-and-conquer
parallelism, work stealing, and why `parallelStream()` uses
ForkJoinPool.

---

### 🎯 Model Answer

**30 seconds:**

> `ForkJoinPool` is a thread pool optimized for recursive divide-
> and-conquer tasks. Threads have their own deque (double-ended
> queue) of tasks. When a thread finishes its work, it "steals"
> tasks from the end of other threads' deques - reducing idle
> time. `parallelStream()` uses the common `ForkJoinPool`. For
> CPU-bound work, pool size defaults to `availableProcessors() - 1`.

**3 minutes (Senior):**

> `RecursiveTask<T>` and `RecursiveAction` are the core abstractions.
> A task's `compute()` method checks if the problem is small enough
> to solve directly; if not, it forks two sub-tasks (`left.fork()`,
> `right.fork()`) and joins their results (`left.join() + right.join()`).
> The pool manages the deques; work stealing balances load when
> sub-problems are unequal size.
>
> Work stealing: each thread has a deque. New sub-tasks are pushed
> to the head of the owning thread's deque. When a thread is idle,
> it steals from the TAIL of another thread's deque. Pushing to
> head and stealing from tail minimizes contention because the owner
> accesses the head and thieves access the tail.
>
> The `parallelStream()` common pool problem: `parallelStream()` uses
> the static common `ForkJoinPool` shared across the entire JVM.
> Long-running tasks in a parallel stream block the common pool's
> threads, degrading ALL parallel streams in the JVM. The fix:
> submit the parallel stream to a dedicated custom `ForkJoinPool`:
> `pool.submit(() -> list.parallelStream().map(...).collect(...)).get()`.
>
> Avoid using `ForkJoinPool` for I/O-bound tasks: a blocking I/O
> call in a `RecursiveTask` occupies a pool thread and prevents
> work stealing for the duration of the I/O wait.

---

### 💻 Code Example

**Example 1: RecursiveTask for parallel sum**

```java
public class SumTask extends RecursiveTask<Long> {
    private static final int THRESHOLD = 1000;
    private final long[] array;
    private final int start, end;

    public SumTask(long[] array, int start, int end) {
        this.array = array;
        this.start = start;
        this.end = end;
    }

    @Override
    protected Long compute() {
        int length = end - start;
        if (length <= THRESHOLD) {
            // Base case: compute directly
            long sum = 0;
            for (int i = start; i < end; i++) sum += array[i];
            return sum;
        }
        // Divide: fork sub-tasks
        int mid = start + length / 2;
        SumTask left  = new SumTask(array, start, mid);
        SumTask right = new SumTask(array, mid, end);
        left.fork();                   // submit left to pool
        long rightResult = right.compute();  // compute right on this thread
        long leftResult  = left.join();      // wait for left result
        return leftResult + rightResult;
    }
}

// Run in a ForkJoinPool
long[] data = new long[10_000_000];
ForkJoinPool pool = new ForkJoinPool(
    Runtime.getRuntime().availableProcessors()
);
long sum = pool.invoke(new SumTask(data, 0, data.length));

// Use dedicated pool to avoid polluting common pool
ForkJoinPool customPool = new ForkJoinPool(4);
long result = customPool.submit(
    () -> hugeList.parallelStream().mapToLong(Long::longValue).sum()
).get();
```

> **Code walkthrough:** The pattern: check if small enough (threshold),
> if so compute directly, otherwise fork left, compute right on the
> current thread, join left. Computing right on the current thread
> avoids the fork/join overhead for the rightmost subtask. The
> threshold of 1,000 elements avoids fork overhead for tiny tasks.
> The custom pool for parallel streams prevents blocking the global
> common pool.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `ForkJoinPool` is for recursive divide-and-conquer tasks.
> `parallelStream()` uses it. `RecursiveTask` defines a task that
> forks sub-tasks and joins results. Work stealing rebalances load
> across threads automatically.

---

**Senior / Staff (5+ years):**

> I use `ForkJoinPool` for CPU-bound batch processing. The work-
> stealing design makes it efficient for unequal subtask sizes.
> I always use a dedicated pool rather than the common pool for
> production parallel streams, to prevent one slow operation from
> degrading all parallel stream throughput JVM-wide.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "What is work stealing in ForkJoinPool?"

🗣️ "Each thread in a `ForkJoinPool` has its own double-ended deque
(deque). When a thread creates sub-tasks (via `fork()`), it pushes
them onto the HEAD of its own deque. When a thread finishes all
its tasks, it steals from the TAIL of another thread's deque.
Pushing and stealing from opposite ends minimizes contention between
the owner (accessing head) and potential thieves (accessing tail).
This self-balancing mechanism ensures that when subtasks are
unevenly sized, idle threads automatically pick up work from
overloaded threads."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | RecursiveTask pattern, fork/join sequence, common pool. |
| Hiring Manager   | When to use ForkJoinPool vs ExecutorService. |
| Bar Raiser       | Work stealing details, common pool contamination, ManagedBlocker. |
| Peer Engineer    | "Our long-running parallel stream froze all other parallel operations JVM-wide..." |

---

---

# ScheduledExecutorService

**Interview Weight:** high - Tests knowledge of scheduled and
recurring task execution as a replacement for the error-prone
`Timer` class.

---

### 🎯 Model Answer

**30 seconds:**

> `ScheduledExecutorService` schedules tasks to run after a delay
> or at a fixed rate/interval. It replaces `java.util.Timer` which
> had two critical bugs: one uncaught exception in a `TimerTask`
> kills ALL scheduled tasks on that timer forever; `Timer` uses
> a single thread, so slow tasks delay subsequent ones.
> `ScheduledExecutorService` isolates task failures and can have
> multiple threads.

**3 minutes (Senior):**

> `scheduleAtFixedRate(task, initialDelay, period, unit)` executes
> every `period` regardless of how long the task takes. If the task
> takes longer than `period`, the next execution starts immediately
> after the current one finishes (no concurrent executions).
> This means the effective rate can be slower than `period` if
> tasks are slow.
>
> `scheduleWithFixedDelay(task, initialDelay, delay, unit)` waits
> `delay` after the previous task FINISHES before starting the next.
> The gap between executions is always at least `delay`.
>
> The distinction matters: a health-check ping should use
> `scheduleWithFixedDelay` to ensure the previous check completes
> before starting the next. A metrics emitter should use
> `scheduleAtFixedRate` to emit at consistent intervals.
>
> Exception handling: unlike `Timer`, an exception in a
> `ScheduledExecutorService` task does not kill other tasks.
> However, it silently stops the recurring task - it is
> not rescheduled. Wrap task code in try/catch or the
> recurring schedule terminates silently after the first exception.

---

### 💻 Code Example

**Example 1: Fixed rate vs fixed delay, exception handling**

```java
ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);

// Fixed rate: execute every 1 second regardless of task duration
ScheduledFuture<?> metricsJob = scheduler.scheduleAtFixedRate(
    () -> emitMetrics(),
    0,               // initial delay
    1,               // period
    TimeUnit.SECONDS
);

// Fixed delay: wait 5 seconds AFTER each completion before next run
scheduler.scheduleWithFixedDelay(
    () -> cleanupExpiredCache(),
    0,               // initial delay
    5,               // delay after completion
    TimeUnit.SECONDS
);

// CRITICAL: Exception stops recurring schedule silently
// BAD:
scheduler.scheduleAtFixedRate(
    () -> doWork(),  // if throws, schedule terminates silently!
    0, 1, TimeUnit.SECONDS
);

// GOOD: Wrap in try/catch to prevent silent schedule termination
scheduler.scheduleAtFixedRate(() -> {
    try {
        doWork();
    } catch (Exception e) {
        logger.error("Scheduled task failed - will retry next period", e);
        // Schedule continues running next period
    }
}, 0, 1, TimeUnit.SECONDS);

// One-time delay
ScheduledFuture<String> delayed = scheduler.schedule(
    () -> fetchData(),
    500,             // run after 500ms
    TimeUnit.MILLISECONDS
);

// Shutdown
metricsJob.cancel(false);     // cancel, don't interrupt if running
scheduler.shutdown();
```

> **Code walkthrough:** `scheduleAtFixedRate` triggers every 1s on
> the wall clock. `scheduleWithFixedDelay` waits 5s after each
> task completes. The exception wrapping is mandatory for recurring
> tasks: an unhandled exception causes the `ScheduledExecutorService`
> to stop rescheduling that task without any log or error message
> unless you explicitly catch and log it.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `ScheduledExecutorService` runs tasks after a delay or on a
> recurring schedule. `scheduleAtFixedRate` runs every N seconds.
> `scheduleWithFixedDelay` waits N seconds after each completion.
> It replaces the buggy `Timer` class.

---

**Senior / Staff (5+ years):**

> The silent exception behavior is the most important production
> concern. I always wrap recurring scheduled tasks in try/catch.
> I also use `ScheduledFuture.get()` in tests to detect exceptions.
> For distributed scheduling (tasks across multiple nodes),
> `ScheduledExecutorService` is insufficient - use Quartz or
> Spring Scheduler with distributed locking.

---

### ❓ Questions You Will Be Asked

#### Debugging

- "Your scheduled metrics job stopped running. What would you check?"

🗣️ "First: the task threw an uncaught exception. An unhandled
exception in a recurring `ScheduledExecutorService` task silently
terminates the schedule - no log, no alert. Check logs for exception
stack traces around the last reported metric. Fix: wrap the task
body in try/catch. Second: the `ScheduledFuture` was cancelled.
Check if any code called `future.cancel()`. Third: the scheduler
itself was shut down - `scheduler.isShutdown()` returns true.
This happens if the JVM shutdown hook ran or if `shutdown()` was
called explicitly."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | fixedRate vs fixedDelay, Timer's bugs, exception behavior. |
| Hiring Manager   | Production reliability of scheduled jobs. |
| Bar Raiser       | Distributed scheduling, ScheduledFuture vs CompletableFuture. |
| Peer Engineer    | "Our nightly job silently stopped after an exception - we found out from users..." |

---

---

# Callable and Future

**Interview Weight:** high - The bridge between async execution
and result retrieval. Tests knowledge of `Future.get()` behavior,
exceptions, timeouts, and `CompletableFuture` as the modern
replacement.

---

### 🎯 Model Answer

**30 seconds:**

> `Callable<T>` is like `Runnable` but returns a value and can
> throw checked exceptions. Submit to `ExecutorService`, get a
> `Future<T>`. `future.get()` blocks until the result is available
> and throws `ExecutionException` if the task threw an exception.
> Always call `get(timeout, unit)` with a timeout in production -
> never plain `get()` which blocks indefinitely. `CompletableFuture`
> is the modern non-blocking alternative.

**3 minutes (Senior):**

> `Future` is a limitations-laden API. Once submitted, you cannot
> cancel cleanly (cancel may not interrupt a running task, only
> signals it). There is no way to chain futures or register a
> callback - you must block on `get()`. Combining multiple futures
> requires looping and calling `get()` on each, which is clunky.
>
> `ExecutorCompletionService` solves one problem: instead of polling
> each future, it provides a blocking queue of completed futures.
> Submit N tasks; `poll()` or `take()` returns each future as it
> completes in completion order rather than submission order.
>
> The `FutureTask` class implements both `Callable` (wraps the task)
> and `Future` (provides `get()`, `cancel()`). It is useful for
> one-time expensive operations: submit to executor, share the
> `FutureTask` reference, all callers call `get()` - the task runs
> once, all callers get the result.
>
> `CompletableFuture` (Java 8) supersedes raw `Future` for async
> composition: chain transformations with `thenApply`, combine
> with `thenCombine`, handle errors with `exceptionally`, all
> without blocking.

---

### 💻 Code Example

**Example 1: Future patterns and timeouts**

```java
ExecutorService pool = Executors.newFixedThreadPool(4);

// Basic submit and get
Callable<String> task = () -> {
    Thread.sleep(1000);
    return "result";
};
Future<String> future = pool.submit(task);

// BAD: Blocks indefinitely
String result = future.get();

// GOOD: Always use timeout in production
try {
    String r = future.get(5, TimeUnit.SECONDS);  // timeout = circuit breaker
} catch (TimeoutException e) {
    future.cancel(true);  // interrupt the task if still running
    throw new ServiceException("Task timed out");
} catch (ExecutionException e) {
    throw new ServiceException("Task failed: " + e.getCause().getMessage(), e.getCause());
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();
    future.cancel(true);
    throw new ServiceException("Interrupted while waiting");
}

// ExecutorCompletionService: process in completion order
ExecutorCompletionService<String> ecs = new ExecutorCompletionService<>(pool);
List<Future<String>> futures = new ArrayList<>();
for (String url : urls) {
    futures.add(ecs.submit(() -> fetch(url)));
}
// Process each as it completes (fastest first)
for (int i = 0; i < urls.size(); i++) {
    Future<String> completed = ecs.take();  // blocks until next completion
    try {
        processResult(completed.get());     // result is ready immediately
    } catch (ExecutionException e) {
        logError(e.getCause());
    }
}
```

> **Code walkthrough:** `get()` without timeout blocks the calling
> thread indefinitely if the task hangs - a thread leak in production.
> `get(5, SECONDS)` acts as a circuit breaker: after 5s, cancel
> the task and fail fast. `ExecutorCompletionService` queues
> completed futures; `take()` returns them in completion order,
> not submission order - useful for displaying results as they
> arrive or parallelizing dependent steps.

---

### ⚖️ Comparison

| | Future | CompletableFuture |
|--|--------|-------------------|
| Return value | yes | yes |
| Blocking on result | get() - must block | thenApply() - non-blocking |
| Exception handling | ExecutionException on get() | exceptionally() |
| Combining | manual looping | thenCombine, allOf, anyOf |
| Callback | no | thenAccept, thenRun |
| Cancel | cancel() - best effort | cancel() - same |
| Use in Java | Java 5+ | Java 8+ (preferred) |

**The deciding factor:** Use `CompletableFuture` for all new async
code. Use `Future` when you need the result immediately and the
blocking `get()` is acceptable (e.g., test code, sequential
batch steps).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `Callable` returns a value; `Runnable` does not. Submit `Callable`
> to `ExecutorService`, get `Future`. `future.get()` blocks for
> the result. Always use `get(timeout)` in production.

*Push deeper:* What exception does `get()` throw if the task failed?

---

**Senior / Staff (5+ years):**

> In new code I use `CompletableFuture` exclusively - it provides
> non-blocking composition that `Future` cannot. When I see `Future.get()`
> in code review without a timeout, I flag it. `ExecutorCompletionService`
> is underused and valuable for fan-out patterns.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "What exceptions can Future.get() throw?"

🗣️ "`future.get()` can throw three exceptions. `ExecutionException`:
the submitted task threw an exception - the cause is the original
exception, wrapped. `InterruptedException`: the thread calling
`get()` was interrupted while waiting. `CancellationException`:
`cancel()` was called before the task completed. For `get(timeout)`,
`TimeoutException` is also possible. The critical pattern: always
handle all three, and for `InterruptedException` always re-interrupt
the current thread before rethrowing or handling."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | ExecutionException wrapping, TimeoutException, all exception types. |
| Hiring Manager   | Production safety - always use get(timeout). |
| Bar Raiser       | CompletableFuture composition, ExecutorCompletionService. |
| Peer Engineer    | "get() without timeout blocked our request handler thread for 10 minutes..." |
