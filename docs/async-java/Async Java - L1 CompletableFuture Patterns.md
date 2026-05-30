---
layout: default
title: "Async Java - L1 CompletableFuture Patterns"
parent: "Async Java"
nav_order: 3
permalink: /async-java/l1-completablefuture-patterns/
render_with_liquid: false
---

# Async Java - L1 CompletableFuture Patterns

---

# CompletableFuture Error Handling

---
id: AJA-007
title: CompletableFuture Error Handling
category: Async Java
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: mid
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> CompletableFuture has three error handling methods: exceptionally() recovers
> from exceptions and returns a fallback value, handle() processes both
> success and failure in one place, and whenComplete() adds a side-effect
> without changing the result. The critical rule: if no error handler is
> attached and nobody calls get(), exceptions are silently discarded. Every
> production CompletableFuture chain needs at least one terminal error handler.

**3 minutes:**
> Error handling in async code is fundamentally different from synchronous
> try/catch. In sync code, exceptions propagate up the call stack naturally.
> In async code, exceptions happen on a pool thread in a different context
> and cannot propagate to the caller's stack - they must be explicitly
> handled in the chain.
>
> `exceptionally(Function<Throwable, T>)`: invoked only when the previous
> stage failed. Receives the exception (wrapped in CompletionException if
> it propagated through thenApply stages) and returns a fallback T value.
> After exceptionally(), the chain continues as if the exception did not
> occur. Use for fallback values: return a default user, a cached result,
> an empty list.
>
> `handle(BiFunction<T, Throwable, U>)`: invoked for both success and
> failure. If success: first argument is the result, second is null. If
> failure: first is null, second is the exception. Can return a different
> type U. Use for unified response building: turn any result or exception
> into a Response object.
>
> `whenComplete(BiConsumer<T, Throwable>)`: side-effect only. Cannot
> change the result or recover from exceptions. The exception continues
> propagating after whenComplete. Use for logging and metrics, not recovery.
>
> The most dangerous pattern: a long chain with no error handler where
> nobody calls get(). An exception in stage 3 of a 10-stage chain makes
> stages 4-10 skip silently, the final future completes exceptionally,
> and if nothing reads it, the exception disappears entirely.

**Blank Mind Recovery:**

**(1) Restate:** "CompletableFuture error handling - let me think through
the three methods and when each applies."

**(2) First principles:** "Async exceptions cannot propagate to the caller.
We need to explicitly declare: what to do when this stage fails. Three
choices: recover with a value, handle both success and failure together,
or observe without changing."

**(3) Bridge:** "Like try/catch/finally but for async chains: exceptionally
is catch with a fallback, handle is catch-with-return, whenComplete is
finally."

---

### 📘 Concept Explanation

**What it is:**
Three CompletableFuture methods for handling failures in async chains:
`exceptionally` (recovery), `handle` (unified success/failure processing),
and `whenComplete` (side effects only). Each has distinct semantics for
whether it can recover from exceptions and whether it can transform the result.

**The problem it solves:**
Synchronous try/catch does not work across thread boundaries. When an async
operation on a pool thread throws, there is no stack frame on the calling
thread to catch it. CompletableFuture's error handling methods register
callbacks that execute when exceptions occur in the chain.

**How it works:**

```
Normal flow:
  CF<T> -> thenApply -> thenApply -> thenAccept
                                         ^success

Exception in stage 2:
  CF<T> -> thenApply[THROWS] -> thenApply[SKIPPED]
         -> exceptionally[FIRES] -> thenAccept[runs with fallback]
                                         ^recovery

whenComplete position:
  CF<T> -> thenApply -> whenComplete[fires for both]
                           |no recovery: exception continues
                        -> exceptionally[fires if still exceptional]
```

**The key insight:**
`exceptionally` and `handle` are recovery points: they absorb exceptions
and the chain continues normally after them. `whenComplete` is NOT a
recovery point: if the stage is exceptional, `whenComplete` receives
the exception but it continues propagating. Many developers use
`whenComplete` expecting it to handle exceptions - it does not.

**When to use each:**
- `exceptionally`: fallback values (return default on failure)
- `handle`: unified response building (convert any outcome to a DTO)
- `whenComplete`: logging, metrics, cleanup (never for recovery)

**When NOT to use:**
- Do not use `whenComplete` for exception recovery
- Do not nest try/catch inside callbacks without re-throwing as CompletionException
- Do not call `get()` inside callbacks (causes deadlock risk)

**Alternatives:**
- Project Reactor: `onErrorReturn()`, `onErrorResume()`, `doOnError()`
  provide the same three patterns with richer composition

**First-principles derivation:**
Exceptions in async pipelines must be carried as data (stored in the
future object) since they cannot propagate through the call stack. Recovery
requires converting "exception-carrying future" back to "value-carrying
future." Observation requires reading the exception without consuming it.
These two needs produce two different methods: recovery (handle/exceptionally)
and observation (whenComplete).

---

### 💻 Code Example

**The three error handling methods in context:**

```java
// 1. exceptionally: fallback value on failure
CompletableFuture<User> withFallback =
    CompletableFuture
        .supplyAsync(() -> userService.findUser(id), pool)
        .exceptionally(ex -> {
            log.warn("User lookup failed, using guest: {}",
                ex.getMessage());
            return User.GUEST; // fallback - chain continues
        });
// After exceptionally: chain continues with User.GUEST if failed

// 2. handle: unified success + failure processing
CompletableFuture<ApiResponse> response =
    CompletableFuture
        .supplyAsync(() -> userService.findUser(id), pool)
        .handle((user, ex) -> {
            if (ex != null) {
                // Failure path
                return ApiResponse.error(
                    ex.getMessage(), 500);
            }
            // Success path
            return ApiResponse.success(user);
        });
// handle fires for BOTH success and failure

// 3. whenComplete: side effect only (logging/metrics)
CompletableFuture<User> logged =
    CompletableFuture
        .supplyAsync(() -> userService.findUser(id), pool)
        .whenComplete((user, ex) -> {
            if (ex != null) {
                metrics.increment("user.lookup.error");
                log.error("Lookup failed", ex);
            } else {
                metrics.increment("user.lookup.success");
            }
            // Exception STILL propagates after this!
            // whenComplete does NOT recover.
        });
// If supplyAsync threw, logged is still exceptional
// even though whenComplete ran
```

> **Code walkthrough:** Example 1 uses `exceptionally` as a fallback -
> if the user service fails, return `User.GUEST`. The chain after
> `exceptionally` receives `User.GUEST` as if no exception occurred.
> Example 2 uses `handle` to convert any outcome (success or failure)
> into a unified `ApiResponse` type - this is the clean pattern for
> building HTTP response objects from async service calls. Example 3
> uses `whenComplete` for metrics and logging only. Critically, if
> `supplyAsync` threw, the `logged` future is still exceptional after
> `whenComplete` - the exception propagates through it unchanged. Using
> `whenComplete` thinking it recovers is the most common mistake in
> CompletableFuture error handling.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> CompletableFuture has three error handling options. exceptionally() runs
> when there's an error and lets me return a fallback value. handle() runs
> for both success and failure in the same callback. whenComplete() is for
> side effects like logging - it does not recover from exceptions. The key
> thing I learned is that whenComplete does NOT stop the exception from
> propagating - it just lets me observe it.

*Push deeper:* Explain what happens to a CompletableFuture chain after
`exceptionally()` - does the normal flow resume?

---

**Senior / Staff:**
> The error handling contract in CompletableFuture is often misunderstood.
> My production rule: always end chains with `handle()` or `whenComplete()`
> for instrumentation, and ensure every chain has an explicit recovery
> path for expected failure modes.
>
> The subtle correctness issue: `whenComplete` passes the exception through
> - it does not transform the future from exceptional to normal. Teams
> often add `whenComplete` for logging and believe the exception is handled.
> It is not. You need `exceptionally` or `handle` for actual recovery.
>
> In high-reliability services I use handle() for all terminal processing -
> it forces me to explicitly decide what to do on both success and failure
> paths, preventing the silent-exception problem.

*Push deeper (Staff):* In reactive Reactor pipelines, the equivalent
distinction is `doOnError` (observe without recovering, like whenComplete)
vs `onErrorReturn`/`onErrorResume` (recover, like exceptionally/handle).
The semantics are identical; the method names are more explicit.

---

### ⚠️ Common Misconceptions

**Misconception: "whenComplete handles exceptions."**

`whenComplete` runs when the future completes (success OR failure) and
lets you observe the result or exception. But the future's exceptional
state is NOT changed by `whenComplete`. If the upstream was exceptional,
the future after `whenComplete` is still exceptional. Attaching
`whenComplete` for error "handling" (without `exceptionally` or `handle`
after it) means the exception propagates to whoever reads the future -
and if nobody reads it, it is silently lost. `whenComplete` is for
observation; `handle` or `exceptionally` is for recovery.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Exception swallowed because chain has no terminal consumer**

Symptom: service processes requests without error, but expected side
effects don't happen. No exceptions in logs.

Cause: a CompletableFuture chain ends with no handler and the terminal
future is never read (no `get()`, no `join()`, no consumer).

```java
// This chain runs, throws, and the exception disappears:
CompletableFuture.runAsync(() -> {
    sendEmail(user); // throws MailException
}, pool);
// Returned CompletableFuture never stored or read
// Exception silently lost
```

Diagnosis and fix:
```java
// Always store and handle the terminal future:
CompletableFuture<Void> emailTask =
    CompletableFuture.runAsync(() -> sendEmail(user), pool)
    .whenComplete((v, ex) -> {
        if (ex != null)
            log.error("Email failed for user {}", user.getId(), ex);
    });
// Or at minimum:
emailTask.exceptionally(ex -> {
    alertingSystem.report(ex);
    return null;
});
```

Establish a team standard: every fire-and-forget CompletableFuture must
have a `whenComplete` that logs exceptions. Enforce via code review
or a custom executor that logs unhandled exceptions:
```java
pool.execute(() -> {
    try { task.run(); }
    catch (Throwable t) { log.error("Pool task failed", t); }
});
```

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions minimum.

---

#### Q1 - What is the difference between exceptionally and handle?

`exceptionally(Function<Throwable, T>)`: invoked ONLY when the previous
stage failed. If the stage succeeded, exceptionally is bypassed and the
success value passes through unchanged. Returns the same type T.

`handle(BiFunction<T, Throwable, U>)`: invoked for BOTH success and
failure. One callback handles both outcomes. Can return a different type U.

Key distinction: exceptionally is for fallback values on error. handle
is for unified outcome processing where you want to inspect both paths.

```java
// exceptionally: only fires on failure, passes success through
cf.exceptionally(ex -> defaultValue); // T -> T (same type)

// handle: fires always, must handle both explicitly
cf.handle((value, ex) -> {
    if (ex != null) return "error";
    return "success: " + value;
}); // T -> U (can be different type)
```

*What separates good from great:* Knowing that `handle()` runs even on
success, so forgetting to check `ex != null` inside handle will try to
use a null result when successful. The pattern is always: `if (ex != null)
{ handle error } else { handle success }`.

---

#### Q2 - How does exceptionally chain with normal stages?

After `exceptionally(fn)`, the chain continues as normal. Stages after
exceptionally receive either: (a) the original success value if no
exception occurred (exceptionally was bypassed), or (b) the fallback
value returned by fn if there was an exception.

```java
CompletableFuture.supplyAsync(() -> fetchUser(id))
    .exceptionally(ex -> User.GUEST)    // fallback on error
    .thenApply(user -> user.getName())  // runs with either result
    .thenAccept(name -> respond(name)); // name is never null
```

If exceptionally itself throws, the returned CompletableFuture is
exceptional with that new exception (the original is replaced).

The chain continues AFTER exceptionally regardless of whether it
fired. This is useful for "keep going with a default if this fails"
patterns without branching the chain.

*What separates good from great:* Understanding that exceptionally can
be placed at any point in the chain, not just at the end. Placing it
early provides fine-grained fallback per stage. Placing it at the end
is a global catch for the entire chain.

---

#### Q3 - How do you convert checked exceptions in Callable lambdas?

CompletableFuture `supplyAsync` takes a `Supplier<T>`, which cannot
throw checked exceptions. Code that calls JDBC or IO methods needs
to wrap checked exceptions.

```java
// Checked exception inside supplyAsync - must wrap
CompletableFuture<User> cf =
    CompletableFuture.supplyAsync(() -> {
        try {
            return userRepo.findById(id); // throws SQLException
        } catch (SQLException e) {
            // Wrap as unchecked - CompletableFuture will store it
            throw new CompletionException(e);
        }
    }, pool);

// In the handler, unwrap:
cf.exceptionally(ex -> {
    Throwable cause = ex.getCause(); // the original SQLException
    if (cause instanceof SQLException sqle) {
        log.error("DB error: {}", sqle.getSQLState(), sqle);
    }
    return User.EMPTY;
});
```

Wrapping as `CompletionException` (not RuntimeException) is conventional:
CompletableFuture's exception propagation uses CompletionException as
the wrapper. `ex.getCause()` in handlers gives the original.

Alternatively, use a utility wrapper:
```java
@FunctionalInterface
interface ThrowingSupplier<T> {
    T get() throws Exception;
    static <T> Supplier<T> wrap(ThrowingSupplier<T> s) {
        return () -> {
            try { return s.get(); }
            catch (Exception e) { throw new CompletionException(e); }
        };
    }
}
// Usage:
CompletableFuture.supplyAsync(
    ThrowingSupplier.wrap(() -> repo.find(id)), pool);
```

*What separates good from great:* Knowing that CompletableFuture itself
wraps exceptions in CompletionException during propagation. When an
exception thrown in a `thenApply` callback reaches an `exceptionally`
handler, it is double-wrapped: `CompletionException(CompletionException(original))`.
The pattern `while (ex instanceof CompletionException) ex = ex.getCause()`
reliably unwraps to the root cause.

---

#### Q4 - What is the risk of long chains without error handlers?

A CompletableFuture chain where an exception occurs in stage N will
cause stages N+1 through end to be silently skipped. If no error
handler is attached and the terminal future is never read (no get(),
no join(), no whenComplete), the exception disappears entirely.

This creates two distinct failure patterns:

Pattern A: Exception in a chain whose result is used by the caller.
The caller will eventually call `get()` and receive the exception. It
will surface. Risk: if the exception arrives much later or the caller
ignores the future.

Pattern B: Fire-and-forget chain (background task, audit log, email).
Nobody reads the terminal future. Any exception in the chain is
permanently lost with zero log output.

Rule: attach `whenComplete` to every fire-and-forget chain:
```java
CompletableFuture.runAsync(() -> sendAuditLog(event), pool)
    .whenComplete((v, ex) -> {
        if (ex != null)
            log.error("Audit log failed", ex);
    });
```

*What separates good from great:* Naming a concrete production scenario:
"In a payment service, we had a fire-and-forget chain for sending
confirmation emails. The email service went down. No errors appeared in
logs for 6 hours because the CompletableFuture exception was swallowed.
We fixed it by adding whenComplete to all background tasks."

---

#### Q5 - How does exception propagation work in thenApply chains?

When an exception occurs in a `thenApply` callback, it is NOT thrown
immediately. Instead, it is caught by the CompletableFuture framework,
wrapped in `CompletionException`, and stored in the resulting future.
All downstream `thenApply` and `thenCompose` stages are skipped.

The exception propagates until an `exceptionally` or `handle` stage
intercepts it:

```java
CompletableFuture.supplyAsync(() -> "start")
    .thenApply(s -> {
        throw new IllegalStateException("oops");
        // wrapped in CompletionException automatically
    })
    .thenApply(s -> s + " [skipped]") // skipped
    .thenApply(s -> s + " [also skipped]") // skipped
    .exceptionally(ex -> {
        // ex is CompletionException
        // ex.getCause() is IllegalStateException("oops")
        return "recovered";
    })
    .thenAccept(s -> System.out.println(s)); // "recovered"
```

Note: the original `IllegalStateException` is accessible via
`ex.getCause()` inside the exceptionally handler.

*What separates good from great:* Understanding that the wrapping to
CompletionException happens at the framework level during propagation,
not at the throw point. An exception thrown in supplyAsync is wrapped
differently than one thrown in thenApply. The safest pattern: always
call `ex.getCause()` in exception handlers and handle both
`CompletionException` wrappers and raw exceptions.

---

#### Q6 - How do you handle errors in CompletableFuture.allOf() chains?

`allOf` completes normally only when ALL futures complete successfully.
If ANY future fails, allOf itself fails - but it waits for all others
to complete (it does not cancel them on failure).

```java
CompletableFuture<String> f1 = supplyAsync(() -> call1());
CompletableFuture<String> f2 =
    supplyAsync(() -> { throw new RuntimeException("f2 fail"); });
CompletableFuture<String> f3 = supplyAsync(() -> call3());

CompletableFuture.allOf(f1, f2, f3)
    .handle((v, ex) -> {
        if (ex != null) {
            // Find which specific future failed:
            for (CompletableFuture<?> f :
                    List.of(f1, f2, f3)) {
                if (f.isCompletedExceptionally()) {
                    f.exceptionally(e -> {
                        log.error("Sub-task failed", e);
                        return null;
                    });
                }
            }
            return Collections.emptyList();
        }
        // All succeeded
        return List.of(f1.join(), f2.join(), f3.join());
    });
```

Key: `allOf.handle()` receives only ONE exception (from the first failed
future, or an indeterminate choice if multiple fail). To find ALL failed
futures, iterate and check `isCompletedExceptionally()` on each.

*What separates good from great:* Knowing that all non-failed futures in
the allOf group complete normally even when allOf fails. f1 and f3 in the
example above have their results available - you can access them even
though allOf failed. This allows partial result collection with graceful
degradation.

---

#### Q7 - How do you test CompletableFuture error handling?

Testing async error handling requires ensuring exceptions are actually
handled, not just that no exception is thrown from the test method.

```java
@Test
void testFallbackOnServiceFailure() {
    // Arrange: service throws
    UserService mockService = mock(UserService.class);
    when(mockService.findUser(any()))
        .thenThrow(new ServiceException("down"));

    // Act: chain with fallback
    CompletableFuture<User> result =
        CompletableFuture
            .supplyAsync(() -> mockService.findUser("id"))
            .exceptionally(ex -> User.GUEST);

    // Assert: join() is safe in tests
    User user = result.join(); // throws if still exceptional
    assertThat(user).isEqualTo(User.GUEST);
}

@Test
void testExceptionPropagatedWhenNoHandler() {
    CompletableFuture<String> cf =
        CompletableFuture.supplyAsync(() -> {
            throw new RuntimeException("expected");
        });

    // join() throws CompletionException wrapping RuntimeException
    assertThatThrownBy(cf::join)
        .isInstanceOf(CompletionException.class)
        .hasCauseInstanceOf(RuntimeException.class)
        .hasMessageContaining("expected"); // from getCause()
}
```

In tests, `.join()` is appropriate (unlike production code) because
tests are synchronous. If the future is exceptional, `join()` throws
`CompletionException` - which surfaces in the test as a failure.

*What separates good from great:* Testing the "no exception in logs"
silent failure scenario: mock the logger and assert that the error
handler log statement was invoked when the service fails.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational entry. Comparison at L2+.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ entry. System design at L4/L5.)*

---

### 📊 Diagram

*(Omit: Exception flow expressed in the ASCII diagram in Concept Explanation.)*

---
---

# ExecutorService and Custom Thread Pools

---
id: AJA-008
title: ExecutorService and Custom Thread Pools
category: Async Java
difficulty: ★☆☆
interview_weight: high
asked_at: All
seniority: mid
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> ExecutorService is Java's abstraction for a pool of threads that execute
> submitted tasks. The key design decision is pool sizing: I/O-bound tasks
> need large pools (200+ threads) because threads spend most time blocked
> waiting; CPU-bound tasks need small pools sized to the number of CPU
> cores. Using the wrong pool size for the wrong work type is one of the
> most common async Java performance bugs.

**3 minutes:**
> `ExecutorService` decouples task submission from task execution. I submit
> a Callable or Runnable; the service allocates a thread from the pool,
> runs the task, and returns the thread when done.
>
> Three main factory methods from `Executors`:
> - `newFixedThreadPool(n)`: always n threads. Good for stable workloads.
>   Risk: if all n threads block on I/O, new tasks queue indefinitely.
> - `newCachedThreadPool()`: creates threads as needed, reuses idle ones,
>   removes after 60s idle. Good for bursty short tasks. Risk: under load,
>   creates unbounded threads - can OOM.
> - `newSingleThreadExecutor()`: exactly one thread. Tasks run sequentially.
>   Good for ordered processing. No concurrency within this pool.
>
> The most important concept: there is no universal "right" pool size.
> I/O-bound tasks: threads spend 95% time blocking - size the pool to the
> expected I/O concurrency (200-500). CPU-bound tasks: threads spend 95%
> time computing - size to CPU cores (Runtime.getRuntime().availableProcessors()).
> Mixing both types in one pool causes starvation.
>
> For Java 21+, `Executors.newVirtualThreadPerTaskExecutor()` removes
> the pool sizing problem entirely: one virtual thread per task, no pool
> limit needed, the JDK handles multiplexing.

**Blank Mind Recovery:**

**(1) Restate:** "ExecutorService and thread pools - let me think through
what they are and why pool sizing matters."

**(2) First principles:** "Threads are expensive to create. A pool
pre-creates threads and reuses them. The pool size is the key parameter:
too small and tasks queue; too large and threads waste memory."

**(3) Bridge:** "Like a restaurant kitchen. Fixed pool = fixed number of
chefs. Too few: orders queue. Too many: chefs stand idle (memory waste).
The right number depends on the kitchen's workload type."

---

### 📘 Concept Explanation

**What it is:**
`ExecutorService` is a managed thread pool that accepts Runnable/Callable
tasks, executes them on pool threads, and provides lifecycle management
(shutdown, awaitTermination). Created via `Executors` factory or custom
`ThreadPoolExecutor` constructor.

**The problem it solves:**
Creating and destroying threads for every task is expensive: thread
creation involves JVM and OS overhead, and premature destruction wastes
setup cost. Pools amortize creation cost across many tasks. They also
limit concurrency (preventing resource exhaustion) and queue overflow
tasks when all threads are busy.

**How it works:**

```
ThreadPoolExecutor internals:
  corePoolSize:     threads kept alive even when idle
  maximumPoolSize:  max threads ever created
  keepAliveTime:    time idle threads above core are kept
  workQueue:        where tasks wait when all threads busy

  Submit task:
    If active < corePoolSize: create new thread
    Else if queue not full:    add to queue
    Else if active < max:      create new thread
    Else:                      reject (RejectedExecutionHandler)
```

**The key insight:**
I/O-bound tasks need large pools because threads are blocked most of
the time. CPU-bound tasks need small pools because adding more threads
than cores causes context switching overhead with no throughput benefit.
The optimal pool size formula for I/O-bound work: threads = expected
concurrent I/O operations (not CPU count).

**When to use fixed thread pool:**
- Stable, predictable concurrency with known max parallel tasks
- I/O-bound work: database connections, HTTP calls, file operations
- When you want predictable memory usage

**When NOT to use cached thread pool:**
- Production I/O-bound services under load (unbounded thread creation)
- Any service that could receive bursts creating thousands of threads

**Alternatives:**
- `Executors.newVirtualThreadPerTaskExecutor()` (Java 21+): no pool
  sizing; one virtual thread per task with JDK multiplexing
- `ForkJoinPool`: work-stealing; best for CPU-bound divide-and-conquer
- Custom `ThreadPoolExecutor`: full control over queue type and rejection

**First-principles derivation:**
Threads have fixed creation and memory cost. If tasks arrive faster
than they complete, we must either: queue tasks (fixed pool), create
new threads (cached pool), or drop tasks (rejection). The queue provides
elasticity; the pool size provides the throughput ceiling. Sizing is a
trade-off between memory (large pool) and latency (small pool, long queue).

---

### 💻 Code Example

**Pool types and sizing for different workloads:**

```java
// BAD: Using default ForkJoinPool for I/O tasks
CompletableFuture.supplyAsync(() -> jdbc.query(sql));
// ForkJoinPool.commonPool() is CPU-sized (e.g., 7 threads on 8-core)
// Under concurrent load: all 7 threads block on JDBC; new tasks queue

// GOOD: Dedicated I/O pool sized for I/O concurrency
private static final ExecutorService IO_POOL =
    Executors.newFixedThreadPool(
        200,        // sized for expected concurrent DB calls
        r -> {
            Thread t = new Thread(r, "io-pool");
            t.setDaemon(true); // doesn't block JVM shutdown
            return t;
        });

CompletableFuture.supplyAsync(() -> jdbc.query(sql), IO_POOL);

// CPU pool for compute-bound work
private static final ExecutorService CPU_POOL =
    Executors.newFixedThreadPool(
        Runtime.getRuntime().availableProcessors(),
        r -> new Thread(r, "cpu-pool"));

// Custom ThreadPoolExecutor with bounded queue + rejection
ThreadPoolExecutor custom = new ThreadPoolExecutor(
    20,   // corePoolSize
    200,  // maximumPoolSize
    60L, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(1000), // max 1000 queued tasks
    new ThreadPoolExecutor.CallerRunsPolicy()); // reject = run inline
// CallerRunsPolicy: if pool full, caller thread runs the task
// provides natural backpressure

// Java 21+: Virtual Thread executor - no pool sizing needed
ExecutorService vtPool =
    Executors.newVirtualThreadPerTaskExecutor();
// Creates one virtual thread per task; JDK handles multiplexing
```

> **Code walkthrough:** The BAD example uses ForkJoinPool for JDBC -
> a CPU-sized pool for I/O work saturates immediately under load. The
> GOOD IO_POOL uses 200 threads with daemon-thread naming. The CPU_POOL
> is sized to available processors for compute work. The custom
> ThreadPoolExecutor shows production-grade configuration: bounded queue
> prevents OOM, `CallerRunsPolicy` provides backpressure (the caller runs
> the task when the pool is full, naturally slowing task submission). The
> Virtual Thread executor (Java 21+) eliminates sizing entirely - the JDK
> parks virtual threads during blocking I/O, so creating one per task
> is safe and efficient.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> ExecutorService is a thread pool that runs submitted tasks. The key
> decision is pool size. For I/O-bound tasks like database calls, I use
> a large fixed pool (200+ threads) because threads spend most time
> waiting - having lots of threads lets many I/O operations run in
> parallel. For CPU-bound tasks, I use a pool sized to CPU cores because
> adding more threads than cores just causes context switching overhead.

*Push deeper:* Explain what happens when the pool is full - how does the
rejection policy work?

---

**Senior / Staff:**
> The pool sizing decision is one of the most impactful configuration
> choices in a Java service. The formula for I/O-bound pools: expected
> concurrent I/O operations / (1 - I/O wait ratio). If a database call
> takes 10ms and processing takes 1ms, the I/O wait ratio is ~90%, so
> a service handling 1000 concurrent requests needs approximately
> 1000/(1-0.9) = 10,000 thread slots - or a reactive approach.
>
> In practice I use three pools: an I/O pool for database/HTTP (sized
> 100-500), a CPU pool for computation (sized to cores), and reject
> everything else to a bounded queue with CallerRunsPolicy for
> backpressure. Thread naming is non-negotiable in production - pool
> threads named "io-pool-23" are instantly identifiable in thread dumps.
>
> For Java 21+, Virtual Threads eliminate I/O pool sizing entirely.
> I configure Spring Boot with `spring.threads.virtual.enabled=true` for
> Tomcat, which creates a virtual thread per request. The JDBC pool
> (HikariCP) remains the throughput ceiling, not thread availability.

*Push deeper (Staff):* The interaction between thread pool and connection
pool (HikariCP) is a common production trap: a 200-thread I/O pool
with a 10-connection HikariCP pool means 190 threads block waiting for
connections - 190 threads wasted. The bottleneck is HikariCP, not the
I/O pool. Sizing both consistently is essential.

---

### ⚠️ Common Misconceptions

**Misconception: "A larger thread pool is always faster."**

Threads compete for CPU time. For CPU-bound work, more threads than
cores means more context switching with no additional computation:
a 16-core machine running a 100-thread CPU pool spends significant
time context-switching between 84 threads that cannot run simultaneously.
For I/O-bound work, large pools do help - but only up to the downstream
resource limit (database connections, upstream service capacity). A pool
of 1000 threads against a database that allows 50 connections means
950 threads block waiting for connections. The bottleneck shifts from
threads to resources.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Thread pool exhaustion causing request queuing**

Symptom: service response time gradually increases under sustained load.
Thread dump shows all pool threads in WAITING state. Request latency
grows without CPU saturation.

Cause: all pool threads blocked on I/O. New tasks queue in the work
queue. Queue length grows, adding latency for queued tasks.

Diagnosis:
```bash
# Thread dump - count pool threads in WAITING
jstack <pid> | grep -c "io-pool.*WAITING"

# JMX monitoring (Micrometer/Actuator exposes this):
# executor.pool.size      - current pool size
# executor.active         - active (running) threads
# executor.queued         - tasks in queue
# executor.completed      - completed task count
```

Micrometer integration:
```java
// Expose pool metrics automatically
new ExecutorServiceMetrics(
    IO_POOL, "io-pool",
    Tags.of("type", "io"))
    .bindTo(meterRegistry);
// Metrics: executor.pool.size, executor.active,
//          executor.queued, executor.completed
```

Fix: (1) Increase pool size for I/O-bound work. (2) Switch to
non-blocking I/O libraries + reactive. (3) Java 21+: Virtual Threads
eliminate this class of problem.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions minimum.

---

#### Q1 - What is the difference between newFixedThreadPool and newCachedThreadPool?

`newFixedThreadPool(n)`: always n threads. Extra tasks wait in an
unbounded `LinkedBlockingQueue`. Predictable memory: n thread stacks.
Risk: if all n threads are blocked, the queue can grow unboundedly.

`newCachedThreadPool()`: creates new threads as needed. Idle threads
reused for 60 seconds, then removed. Unbounded thread creation. Good
for short-lived tasks with variable concurrency. Risk: under sudden
load spike, creates thousands of threads - OOM or OS limit hit.

In production:
- `newFixedThreadPool` for services with predictable load and bounded
  concurrency. The fixed count prevents OOM but may cause queuing.
- `newCachedThreadPool` is dangerous in production under load -
  avoid it. Use a custom ThreadPoolExecutor with bounded pool and queue.

*What separates good from great:* Knowing that `newCachedThreadPool()`
uses `SynchronousQueue` internally (zero capacity - each task must be
immediately picked up by a thread) combined with `Integer.MAX_VALUE`
max pool size. This is why it creates unlimited threads: no queue
buffer, so every task that cannot be immediately handled creates a new
thread.

---

#### Q2 - What is ThreadPoolExecutor rejection policy and when does rejection occur?

Rejection occurs when both conditions are met: (1) the pool is at
maximumPoolSize (all threads running), AND (2) the work queue is full.

Four built-in rejection policies:

1. `AbortPolicy` (default): throws `RejectedExecutionException`.
   Caller must handle it. Appropriate when the caller can retry.

2. `CallerRunsPolicy`: the calling thread runs the task directly.
   Provides backpressure: caller is slowed when pool is saturated.
   Appropriate for batch processing where slowing down is acceptable.

3. `DiscardPolicy`: silently drops the task. Only appropriate for
   truly optional work (metrics updates, cache pre-warming).

4. `DiscardOldestPolicy`: drops the oldest queued task and retries
   submission. Can cause unfair aging of tasks.

Custom policy (for alerting):
```java
ThreadPoolExecutor pool = new ThreadPoolExecutor(
    20, 200, 60L, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(500),
    (task, executor) -> {
        metrics.increment("pool.rejected");
        log.error("Task rejected - pool full");
        // Optionally: throw, queue to disk, etc.
    });
```

*What separates good from great:* Knowing that `CallerRunsPolicy` is
the most production-safe default for I/O-bound services because it
provides automatic backpressure: when the pool fills, the caller
(often the HTTP thread) runs the task directly, slowing request intake
naturally without dropping work or throwing exceptions.

---

#### Q3 - How do you properly shut down an ExecutorService?

Two-phase shutdown for graceful termination:

```java
// Phase 1: stop accepting new tasks
executor.shutdown();

// Phase 2: wait for running tasks to complete
try {
    if (!executor.awaitTermination(30, TimeUnit.SECONDS)) {
        // Still running after 30s - force stop
        executor.shutdownNow(); // sends interrupt to running tasks
        // Wait again after forced stop
        if (!executor.awaitTermination(10, TimeUnit.SECONDS)) {
            log.error("Pool did not terminate");
        }
    }
} catch (InterruptedException e) {
    executor.shutdownNow();
    Thread.currentThread().interrupt();
}
```

`shutdown()`: marks pool as shutting down. No new tasks accepted.
Running tasks and queued tasks complete normally.

`shutdownNow()`: attempts to stop running tasks by interrupting them.
Returns list of unstarted queued tasks. Tasks that do not check
`Thread.interrupted()` continue running.

In Spring Boot: declare pools as Spring Beans and implement
`DisposableBean` or `@PreDestroy` to trigger shutdown during application
context close.

*What separates good from great:* Using `awaitTermination` rather than
just calling `shutdown()` and returning. Services that restart without
draining the pool can produce partial results for in-flight requests -
particularly dangerous for financial transactions, audit logs, or email
sends. Always wait for completion during graceful shutdown.

---

#### Q4 - What is the difference between submit() and execute()?

`execute(Runnable)`: from `Executor` interface. Returns void. Exceptions
from the task go to the thread's `UncaughtExceptionHandler`. No way to
check task completion or result.

`submit(Callable<T>)`: returns `Future<T>`. Exceptions stored in the
future. Caller retrieves result or exception via `future.get()`.

`submit(Runnable)`: returns `Future<?>`. `future.get()` returns null
on success. Only useful for checking completion or exceptions.

`invokeAll(List<Callable<T>>)`: submits all tasks, blocks until all
complete, returns list of Future<T>. Simplifies parallel fan-out at
the cost of blocking the calling thread.

`invokeAny(List<Callable<T>>)`: submits all tasks, returns when first
succeeds, cancels the rest. Useful for redundant service calls or
competitive execution.

*What separates good from great:* Knowing the exception handling
difference: execute() exceptions go to UncaughtExceptionHandler (often
just logs to stderr if not configured). Unmonitored execute() tasks
that throw are silently lost in most configurations. This is why submit()
with future monitoring is generally safer.

---

#### Q5 - How do you size a thread pool for mixed I/O and CPU work?

Mixed workloads require separate pools, not a shared one:

```java
// PROBLEM: shared pool causes starvation
ExecutorService mixed = Executors.newFixedThreadPool(10);
// I/O tasks block all 10 threads -> CPU tasks queue forever
// CPU tasks use all 10 threads -> I/O tasks cannot get a thread

// SOLUTION: separate pools
int cpuCores = Runtime.getRuntime().availableProcessors();

ExecutorService cpuPool =
    Executors.newFixedThreadPool(cpuCores);

ExecutorService ioPool =
    Executors.newFixedThreadPool(100); // sized for I/O wait

// Route work explicitly:
CompletableFuture<byte[]> cpuResult =
    CompletableFuture.supplyAsync(() -> compress(data), cpuPool);

CompletableFuture<DbResult> ioResult =
    CompletableFuture.supplyAsync(() -> db.query(sql), ioPool);
```

Formula for I/O pool size (Little's Law):
`threads = concurrency * (1 / (1 - wait_ratio))`

Where `wait_ratio = I/O time / total task time`. If a DB call takes
9ms out of a 10ms task, wait_ratio = 0.9. For 100 concurrent requests:
`threads = 100 * (1 / 0.1) = 1000`. In practice, limit to available
DB connections and use Virtual Threads for Java 21+.

*What separates good from great:* Knowing that Reactor's `Schedulers.boundedElastic()`
is designed exactly for wrapping blocking I/O in reactive pipelines -
it's a bounded thread pool (capped at 10x CPU cores by default) with
queuing. It provides the right semantics without manual configuration.

---

#### Q6 - How do you monitor thread pool health in production?

Key metrics to expose via Micrometer (Spring Boot Actuator):

```java
// Register pool metrics
ExecutorServiceMetrics.monitor(
    registry, pool, "service.io-pool");

// Key metrics exposed:
// service.io-pool.executor.pool.size   - current thread count
// service.io-pool.executor.active      - busy threads
// service.io-pool.executor.queued      - pending tasks
// service.io-pool.executor.completed   - finished tasks
// service.io-pool.executor.pool.max    - max pool size
```

Alerting thresholds:
- `active / pool.max > 0.8` (80% utilization): approaching saturation
- `queued > 100`: significant backlog; pool may be too small
- `active = pool.max AND queued > 0`: pool saturated; requests delayed

Manual access (without Micrometer):
```java
ThreadPoolExecutor tpe = (ThreadPoolExecutor) pool;
int active    = tpe.getActiveCount();
int poolSize  = tpe.getPoolSize();
long queued   = tpe.getQueue().size();
long completed = tpe.getCompletedTaskCount();
```

*What separates good from great:* Setting up queue saturation alerting
before a pool-saturation incident happens. "Pool queued > 500" should
page on-call 30 minutes before "service response time > 10s" would
page. Proactive pool monitoring catches capacity issues before they
become user-visible outages.

---

#### Q7 - When would you use a single-thread executor?

`Executors.newSingleThreadExecutor()` creates a pool with exactly one
thread. All submitted tasks execute sequentially, in submission order.
If the thread dies from an uncaught exception, a new thread is created
automatically for subsequent tasks (unlike a single Thread).

Use cases:

1. Ordered processing: tasks that must run in sequence (event processing,
   log writing, state machine transitions). Multiple threads would
   require synchronization; one thread provides natural ordering.

2. Resource exclusion: accessing a non-thread-safe resource (legacy
   database driver, file system path with exclusive access). One thread
   prevents concurrent access without locks.

3. Serialized writes: writing to a shared log file or output stream
   without interleaving.

```java
// Single-thread executor for ordered audit logging
ExecutorService auditExecutor =
    Executors.newSingleThreadExecutor(
        r -> new Thread(r, "audit-writer"));

auditExecutor.submit(() -> auditLog.write(event1));
auditExecutor.submit(() -> auditLog.write(event2));
// event1 guaranteed to write before event2
```

Limitation: one thread means maximum throughput = one task at a time.
Not suitable for high-throughput concurrent workloads.

*What separates good from great:* Distinguishing `newSingleThreadExecutor()`
from `newFixedThreadPool(1)`. The single-thread variant wraps the pool
in a `FinalizableDelegatedExecutorService` that prevents callers from
downcasting to `ThreadPoolExecutor` and changing the pool size to > 1.
It is "guaranteed single-threaded" by API contract, not just configuration.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational entry. Comparison table in L2+.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ entry. System design in L4/L5.)*

---

### 📊 Diagram

*(Omit: ThreadPoolExecutor flow expressed through code and ASCII above.)*

---
---

# CompletableFuture Completion and Cancellation

---
id: AJA-009
title: CompletableFuture Completion and Cancellation
category: Async Java
difficulty: ★☆☆
interview_weight: medium
asked_at: All
seniority: mid
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> CompletableFuture can be completed externally via complete() or
> completeExceptionally(), not just by the computation submitted to
> supplyAsync. Cancellation via cancel(true) marks the future as
> cancelled but does NOT interrupt the underlying computation. This is
> the key gotcha: CompletableFuture.cancel() does not actually stop the
> running task - it only prevents callbacks from receiving the result.

**3 minutes:**
> CompletableFuture has two ways to complete: internally (from the
> computation given to supplyAsync) and externally (any code that holds
> a reference can call complete() or completeExceptionally()). This
> makes it useful as a promise-like primitive: create a CompletableFuture,
> pass it to a callback-based API, and complete it when the callback fires.
>
> Cancellation is designed for the waiting side, not the execution side.
> `cf.cancel(true)` marks the future as cancelled - isDone() returns true,
> get() throws CancellationException, and callbacks that were registered
> on cf do not execute. But the Supplier that was given to supplyAsync
> continues running on its thread until it finishes naturally.
>
> This is by design: CompletableFuture does not have a reference to the
> underlying thread running the task. If you need cancellation of the
> actual computation, you need a separate mechanism: a shared
> AtomicBoolean flag checked by the computation, or Structured Concurrency
> (Java 21+) which provides scope-based cancellation that propagates to
> forked tasks.
>
> Complete() semantics: only the first call to complete() or
> completeExceptionally() takes effect. Subsequent calls are no-ops.
> This is why it is safe to have multiple callbacks race to complete the
> same CompletableFuture - the first wins, others are silently ignored.

**Blank Mind Recovery:**

**(1) Restate:** "CompletableFuture completion and cancellation - let me
think through complete(), completeExceptionally(), and cancel()."

**(2) First principles:** "A Future represents a pending result. Completion
means filling in the result. Cancellation means signaling that the result
is no longer needed. But signaling is not the same as stopping."

**(3) Bridge:** "Like cancelling a restaurant order. You can cancel
your ticket (the future), but the chef may still be cooking the meal.
The cancellation marks the order as cancelled; the kitchen activity
is separate."

---

### 📘 Concept Explanation

**What it is:**
CompletableFuture completion methods allow external code to drive the
future's outcome rather than relying solely on the submitted computation.
Cancellation marks the future as done-with-cancellation but does not
interrupt the underlying computation thread.

**The problem it solves:**
Some async operations come from external events (network callbacks,
timer fires, WebSocket messages) rather than a direct computation. A
promise-style pattern (create a future, return it, complete it when
the external event arrives) requires explicit completion methods.

**How it works:**

```
completion methods:
  complete(T value)         - success; first call wins
  completeExceptionally(ex) - failure; first call wins
  cancel(mayInterrupt)      - cancelled; CancellationException
  completeAsync(supplier)   - async completion on executor
  obtrudeValue(T)           - force override (testing only)

cancellation semantics:
  cf.cancel(true):
    - Sets future state to CANCELLED
    - cf.get() throws CancellationException
    - Registered callbacks on cf do NOT fire
    - The Supplier in supplyAsync continues running
    - mayInterrupt flag is IGNORED for supplyAsync tasks
      (CF has no reference to the running thread)

Thread safety:
  All complete*() methods are thread-safe.
  First successful call wins; subsequent calls return false.
```

**The key insight:**
CompletableFuture's cancel() does NOT interrupt the running computation.
This is a frequent source of resource leaks: the cancelled future is
forgotten, but the thread pool thread running the original task
continues to completion, consuming resources. If cancellation of the
computation is required, use Structured Concurrency (Java 21+) or a
cooperative cancellation flag.

**When to use complete():**
- Bridging callback-based async APIs to CompletableFuture
- Timeout patterns: create CF, schedule complete(fallback) after N ms
- Testing: complete a CF with a test value without running real async code

**When NOT to use cancel():**
- When you need to actually stop the running computation
- When resource cleanup (open connections, files) depends on the task stopping

**Alternatives:**
- Structured Concurrency (Java 21+): scope-based cancellation that
  actually propagates to forked tasks
- Reactor Disposable: reactive cancel() that does propagate disposal

**First-principles derivation:**
A future's state is shared between the producer (runs the computation)
and consumers (waiting for the result). Complete() is the producer's
right to fill in the result. Cancel() is a consumer's signal that the
result is no longer needed. The system guarantees only one terminal
state wins. What it cannot guarantee: the producer stops working once
cancelled, because it may not know about the cancellation.

---

### 💻 Code Example

**Completion and cancellation patterns:**

```java
// 1. External completion - bridge from callback API
public CompletableFuture<String> fetchAsync(String url) {
    CompletableFuture<String> cf = new CompletableFuture<>();

    asyncHttpClient.get(url,
        result -> cf.complete(result),          // success
        error  -> cf.completeExceptionally(error)); // failure

    return cf; // caller chains on this
}
// HTTP library fires the callback; we complete the future

// 2. Timeout via completeOnTimeout (Java 9+)
CompletableFuture<String> withTimeout =
    CompletableFuture
        .supplyAsync(() -> slowService.call(), pool)
        .completeOnTimeout("default", 3, TimeUnit.SECONDS);
// If slowService doesn't finish in 3s:
// future completes with "default", NOT with exception

// 3. orTimeout (Java 9+) - timeout as exception
CompletableFuture<String> withException =
    CompletableFuture
        .supplyAsync(() -> slowService.call(), pool)
        .orTimeout(3, TimeUnit.SECONDS);
// If timeout: completes with TimeoutException
// caller receives: CompletionException wrapping TimeoutException

// 4. Cancellation - marks future, does NOT stop task
CompletableFuture<String> cf =
    CompletableFuture.supplyAsync(() -> {
        // This continues running even after cf.cancel()!
        Thread.sleep(10_000);
        return "result";
    }, pool);

cf.cancel(true); // future is cancelled
// cf.isCancelled() == true
// cf.get() throws CancellationException
// BUT: pool thread continues sleeping for 10 seconds

// 5. Cooperative cancellation via AtomicBoolean
AtomicBoolean shouldStop = new AtomicBoolean(false);
CompletableFuture<String> cancellable =
    CompletableFuture.supplyAsync(() -> {
        while (!shouldStop.get()) { // check flag
            // do work in chunks
        }
        return "stopped";
    }, pool);
shouldStop.set(true); // signals the computation to stop
```

> **Code walkthrough:** Example 1 is the key pattern for bridging legacy
> callback APIs - create a CompletableFuture, pass completion lambdas to
> the callback API, return the future to callers. Example 2 shows
> `completeOnTimeout()` (Java 9+) which provides a default value on
> timeout - the task continues running but the future gives a default.
> Example 3 shows `orTimeout()` which throws TimeoutException instead.
> Example 4 is the critical demonstration: cancel(true) marks the future
> but the pool thread continues running for 10 full seconds. Example 5
> is the correct pattern for cooperative cancellation: share an
> AtomicBoolean between the cancel caller and the computation.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> complete() fills in the result of a CompletableFuture from outside the
> running computation - useful for bridging callback-based APIs. cancel()
> marks the future as cancelled so callbacks don't run and get() throws
> CancellationException. The important thing I learned: cancel() does NOT
> actually stop the computation that's running - the task keeps going on
> its thread. You need a separate mechanism to stop the actual work.

*Push deeper:* How would you actually stop a running computation if
cancel() doesn't work?

---

**Senior / Staff:**
> The cancel() limitation in CompletableFuture is a frequent production
> gotcha. When I implement timeout patterns with cancel(), the pool thread
> continues running the original computation until completion, consuming
> a thread slot I thought I had freed. For short timeouts with short
> tasks, this is fine. For long-running tasks with frequent timeouts,
> threads accumulate and the pool saturates.
>
> My production pattern for true cancellation: use completeOnTimeout()
> or orTimeout() for the future, AND a cooperative AtomicBoolean flag in
> the computation that the task checks periodically. The flag lets the
> task exit early; the CF methods handle the caller's perspective.
>
> Java 21+ Structured Concurrency solves this correctly: cancelling the
> scope cancels all forked tasks with propagated interruption. This is
> the right model for production fan-out with timeout-based cancellation.

*Push deeper (Staff):* The interaction between cancel() and thenApply
chains: if cf is cancelled, thenApply callbacks registered on cf do not
run - they are also in cancelled state. This means a cancelled future
propagates through the entire downstream chain, skipping all thenApply
stages. The downstream chain completes with CancellationException unless
an `exceptionally` handler catches it (cancellation throws
CancellationException, which exceptionally does receive).

---

### ⚠️ Common Misconceptions

**Misconception: "cancel(true) interrupts and stops the running task."**

The `mayInterruptIfRunning` parameter in `cancel(true)` is inherited
from the `Future` interface and was intended for that behavior. For
CompletableFuture, it is IGNORED: CompletableFuture does not hold a
reference to the thread running the computation (by design, to support
multiple execution models). The running Supplier/Callable continues
executing to completion regardless of cancel(). The `true`/`false`
parameter has no effect on CompletableFuture. Only the future's state
is changed.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Thread pool saturation from cancelled but still-running tasks**

Symptom: service cancels slow requests via future.cancel(), but thread
pool remains saturated. New requests queue even though most "active"
futures are cancelled.

Cause: cancel() marks futures as done but threads running the original
computations are still active. Each cancelled future's pool thread
continues until the underlying I/O completes (potentially seconds or
minutes later). The pool has no free threads for new work.

Diagnosis:
```java
ThreadPoolExecutor tpe = (ThreadPoolExecutor) pool;
int active    = tpe.getActiveCount();
int queued    = (int) tpe.getQueue().size();
int cancelled = (int) cancelledCounter.get(); // app-level counter

// If active ≈ pool.max AND many futures are cancelled:
// threads are held by cancelled-but-still-running tasks
log.info("Pool: active={}, queued={}, cancelled={}",
    active, queued, cancelled);
```

Fix: add cooperative cancellation:
```java
Map<String, AtomicBoolean> cancelFlags = new ConcurrentHashMap<>();

public CompletableFuture<String> call(String reqId) {
    AtomicBoolean cancel = new AtomicBoolean(false);
    cancelFlags.put(reqId, cancel);

    return CompletableFuture.supplyAsync(() -> {
        // Check cancel flag periodically
        if (cancel.get()) return null;
        String result = doSlowWork();
        if (cancel.get()) return null;
        return result;
    }, pool);
}

public void cancel(String reqId) {
    AtomicBoolean flag = cancelFlags.remove(reqId);
    if (flag != null) flag.set(true);
}
```

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions minimum.

---

#### Q1 - What is the difference between complete() and completeExceptionally()?

`complete(T value)`: sets the future's result to the given value.
Subsequent calls to `get()` or `join()` return this value. Registered
completion callbacks receive the value. Returns `true` if this call
completed the future; `false` if it was already completed.

`completeExceptionally(Throwable ex)`: sets the future's state to
failed with the given exception. `get()` throws `ExecutionException`
wrapping ex. `join()` throws `CompletionException` wrapping ex.
Downstream `thenApply` stages are skipped; `exceptionally` stages fire.

Both are idempotent (first call wins):
```java
CompletableFuture<String> cf = new CompletableFuture<>();
boolean won = cf.complete("value"); // true - first caller wins
boolean lost = cf.complete("other"); // false - already completed
cf.get(); // returns "value"
```

Use case: multiple threads racing to complete the same future (e.g.,
redundant service calls - take whichever responds first).

*What separates good from great:* Knowing that `obtrudeValue(T)` and
`obtrudeException(Throwable)` forcibly override an already-completed
future. These are intended for test scenarios and unusual recovery
patterns. In normal production code, they should never be used - they
break the "first call wins" contract.

---

#### Q2 - How does completeOnTimeout differ from orTimeout?

Both are Java 9+ methods for handling slow computations:

`completeOnTimeout(T value, long timeout, TimeUnit unit)`: if the future
does not complete before the timeout, it completes with the given value
(as a normal, non-exceptional completion). The underlying computation
continues running.

`orTimeout(long timeout, TimeUnit unit)`: if the future does not complete
before the timeout, it completes with `TimeoutException` (exceptional
completion). Downstream stages that check for exceptions receive
TimeoutException.

Choosing between them:
- `completeOnTimeout`: use when a fallback/default value is acceptable
  and callers should not know about the timeout.
- `orTimeout`: use when callers must distinguish timeout from other
  failures and handle it differently (e.g., log "service timed out"
  vs "service threw error").

*What separates good from great:* Both methods set up a ScheduledExecutor
timeout under the hood. Neither cancels the underlying computation.
The pool thread running the computation continues until it finishes
naturally. Callers receive the timeout result/exception, but resources
are still held until the computation completes.

---

#### Q3 - When would you create a CompletableFuture manually instead of supplyAsync?

Three scenarios for manually creating and completing a CompletableFuture:

1. Bridging callback-based APIs:
   ```java
   CompletableFuture<String> cf = new CompletableFuture<>();
   legacyApi.call(result -> cf.complete(result),
                  error  -> cf.completeExceptionally(error));
   return cf;
   ```

2. Already-known results (testing, caching):
   ```java
   // Return a pre-completed future for cached values
   if (cache.has(key)) {
       return CompletableFuture.completedFuture(cache.get(key));
   }
   // CompletableFuture.completedFuture(value) is the factory
   ```

3. Fan-in from multiple sources (race pattern):
   ```java
   CompletableFuture<String> winner = new CompletableFuture<>();
   // First to respond completes the winner
   supplyAsync(() -> callPrimary(), pool)
       .thenAccept(r -> winner.complete(r));
   supplyAsync(() -> callReplica(), pool)
       .thenAccept(r -> winner.complete(r)); // ignored if primary won
   ```

*What separates good from great:* `CompletableFuture.completedFuture(value)`
(also `failedFuture(ex)` in Java 9+) for testing: instead of mocking
the entire async infrastructure, return pre-completed futures from mocked
services. Downstream code handles them identically to real async futures.

---

#### Q4 - What is the cancellation propagation behavior in a chain?

When `cf.cancel(true)` is called:
- `cf.isCancelled()` returns true
- `cf.get()` throws `CancellationException`
- Any stage registered directly on `cf` (via `thenApply(cf)`) also
  completes with CancellationException
- This propagates downstream through the chain until an `exceptionally`
  or `handle` stage catches it

CancellationException IS an exception - `exceptionally` can catch it:
```java
cf.cancel(true);

cf.thenApply(v -> "skipped")        // cancelled
  .exceptionally(ex -> {
      if (ex.getCause() instanceof CancellationException) {
          return "was cancelled"; // handle specifically
      }
      throw (RuntimeException) ex;  // re-throw others
  })
  .thenAccept(s -> respond(s)); // "was cancelled"
```

Key: cancellation does NOT propagate UPSTREAM. Cancelling a downstream
future (a future returned by thenApply) does not cancel the upstream
future that it depends on.

*What separates good from great:* Knowing that `CompletableFuture`
cancelled state is checked via `isCancelled()` not just `isCompletedExceptionally()`.
Both return true for a cancelled future, but `isCancelled()` distinguishes
cancellation from other exceptional completions. Important for building
diagnostics that distinguish "timed out" vs "failed" vs "cancelled."

---

#### Q5 - How do you implement a timeout pattern with CompletableFuture?

Three approaches, from simple to robust:

1. `orTimeout()` (Java 9+) - built-in, simplest:
   ```java
   return supplyAsync(() -> slowCall(), pool)
       .orTimeout(3, TimeUnit.SECONDS);
   // Throws CompletionException(TimeoutException) after 3s
   ```

2. `completeOnTimeout()` (Java 9+) - with fallback:
   ```java
   return supplyAsync(() -> slowCall(), pool)
       .completeOnTimeout(defaultValue, 3, TimeUnit.SECONDS);
   // Returns defaultValue after 3s; no exception
   ```

3. Manual timeout with ScheduledExecutorService (Java 8):
   ```java
   CompletableFuture<String> cf = supplyAsync(() -> slowCall());
   scheduler.schedule(
       () -> cf.completeExceptionally(new TimeoutException()),
       3, TimeUnit.SECONDS);
   return cf;
   ```

All three patterns: the underlying computation continues running.
Combine with cooperative cancellation flag for true resource release:
```java
AtomicBoolean cancel = new AtomicBoolean(false);
CompletableFuture<String> cf = supplyAsync(
    () -> slowCallWithCheck(cancel), pool)
    .orTimeout(3, TimeUnit.SECONDS)
    .exceptionally(ex -> {
        if (ex.getCause() instanceof TimeoutException) {
            cancel.set(true); // signal computation to stop
        }
        return "timed out";
    });
```

*What separates good from great:* Understanding that `orTimeout` and
`completeOnTimeout` use `ForkJoinPool.commonPool()` for the internal
timeout scheduler if no delayer is specified. For precise timeout behavior
in high-throughput services, provide a custom scheduled executor.

---

#### Q6 - What is the difference between isDone(), isCancelled(), and isCompletedExceptionally()?

```java
CompletableFuture<String> cf = new CompletableFuture<>();

// Completed normally:
cf.complete("value");
cf.isDone()                    // true
cf.isCancelled()               // false
cf.isCompletedExceptionally()  // false

// Completed exceptionally:
CompletableFuture<String> failed = new CompletableFuture<>();
failed.completeExceptionally(new RuntimeException());
failed.isDone()                    // true
failed.isCancelled()               // false
failed.isCompletedExceptionally()  // true

// Cancelled:
CompletableFuture<String> cancelled = new CompletableFuture<>();
cancelled.cancel(true);
cancelled.isDone()                    // true
cancelled.isCancelled()               // true
cancelled.isCompletedExceptionally()  // true (!)
// Note: isCancelled() => isCompletedExceptionally() is always true
```

Key: `isCancelled()` implies `isCompletedExceptionally()`. All three
states (normal, exceptional, cancelled) make `isDone()` true.

*What separates good from great:* Using these in health checks and
diagnostics: a monitoring dashboard that shows "5% of futures in
isCompletedExceptionally state but isCancelled is false" identifies
unexpected service failures. A high isCancelled rate identifies timeout
pressure.

---

#### Q7 - How does CompletableFuture compare to Promise in JavaScript?

Conceptual mapping:

| JavaScript Promise | Java CompletableFuture |
|---|---|
| `new Promise((resolve, reject) => {})` | `new CompletableFuture<>()` |
| `resolve(value)` | `cf.complete(value)` |
| `reject(error)` | `cf.completeExceptionally(error)` |
| `.then(fn)` | `.thenApply(fn)` |
| `.then(a -> promise)` | `.thenCompose(fn)` |
| `Promise.all([p1, p2])` | `CompletableFuture.allOf(cf1, cf2)` |
| `Promise.race([p1, p2])` | `CompletableFuture.anyOf(cf1, cf2)` |
| `.catch(fn)` | `.exceptionally(fn)` |
| `.finally(fn)` | `.whenComplete(fn)` |
| `async/await` | Virtual Threads (Java 21+) |

Key differences:
- JavaScript Promises are single-threaded; CompletableFuture callbacks
  run on thread pool threads (multi-threaded).
- CompletableFuture has no built-in microtask queue; ordering of
  callbacks is based on thread scheduling.
- `async/await` in JS provides synchronous-looking async code; Virtual
  Threads in Java 21+ provide the equivalent for blocking calls.
- JavaScript Promise.cancel() does not exist natively;
  CompletableFuture.cancel() exists but does not stop computation.

*What separates good from great:* The thread-safety implication: in
JavaScript, the single-thread guarantees that `.then` callbacks never
run concurrently. In Java, multiple `thenApply` callbacks on different
futures can run concurrently on different threads. Shared mutable state
in Java CF callbacks requires synchronization; in JS it does not.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational entry. Comparison at L2+.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ entry. System design at L4/L5.)*

---

### 📊 Diagram

*(Omit: State transitions expressed in the ASCII completion method table
in Concept Explanation.)*
