---
layout: default
title: "Java Concurrency - L3 Async Programming"
parent: "Java Concurrency"
nav_order: 6
permalink: /java-concurrency/l3-async-programming/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [CompletableFuture Basics](#completablefuture-basics) | high |
| 2 | [CompletableFuture Chaining and Composition](#completablefuture-chaining-and-composition) | high |
| 3 | [CompletableFuture Exception Handling](#completablefuture-exception-handling) | high |
| 4 | [Virtual Threads Project Loom](#virtual-threads-project-loom) | high |
| 5 | [Reactive Programming vs Threads](#reactive-programming-vs-threads) | high |

---

# CompletableFuture Basics

**Interview Weight:** high - The modern async programming foundation.
Tests whether you understand async vs blocking, the default executor,
and how `CompletableFuture` differs from `Future`.

---

### 🎯 Model Answer

**30 seconds:**

> `CompletableFuture<T>` (Java 8) extends `Future<T>` with composable
> async operations. Key advantage: non-blocking pipelines with
> `thenApply()`, `thenAccept()`, `thenCompose()`. Create one with
> `CompletableFuture.supplyAsync(supplier)` to run on the common
> `ForkJoinPool`, or pass a custom executor. Unlike raw `Future`,
> you can register callbacks, chain transformations, and combine
> multiple futures without blocking.

**3 minutes (Senior):**

> `CompletableFuture.supplyAsync(supplier)` uses the common
> `ForkJoinPool.commonPool()` by default. This shares thread pool
> capacity with parallel streams. For I/O-bound async operations,
> always provide a custom executor: `supplyAsync(supplier, ioPool)`.
> I/O on the common pool blocks ForkJoin worker threads, degrading
> all other parallel computations in the JVM.
>
> The `complete()` and `completeExceptionally()` methods allow
> external completion - creating a `CompletableFuture` that you
> fulfill from another thread or callback. This is how you wrap
> callback-based APIs (old async HTTP clients) into
> `CompletableFuture` form.
>
> `CompletableFuture.completedFuture(value)` creates an already-
> completed future - useful for returning synchronously-available
> values from methods that return `CompletableFuture` (no async
> dispatch needed).
>
> `allOf(cf1, cf2, ...)` waits for all futures to complete (returns
> `CompletableFuture<Void>`). `anyOf(cf1, cf2, ...)` completes
> with the first result. Neither carries the results - you need
> to call `cf.get()` or `cf.join()` on the originals after `allOf`
> completes.

---

### 💻 Code Example

**Example 1: Basic creation and non-blocking patterns**

```java
// Create async computation on ForkJoinPool (CPU-bound work only)
CompletableFuture<String> cf = CompletableFuture.supplyAsync(() -> {
    return fetchFromDatabase();   // BAD: I/O on ForkJoinPool!
});

// GOOD: Provide dedicated I/O executor for I/O-bound tasks
ExecutorService ioPool = Executors.newFixedThreadPool(20);
CompletableFuture<String> cf2 = CompletableFuture.supplyAsync(
    () -> fetchFromDatabase(),     // runs on ioPool thread
    ioPool
);

// Already-completed future (no async dispatch)
CompletableFuture<String> cached = CompletableFuture.completedFuture("cached");

// External completion: wrap callback-based API
CompletableFuture<Response> cf3 = new CompletableFuture<>();
oldHttpClient.send(request, new Callback() {
    public void onSuccess(Response r) { cf3.complete(r); }
    public void onError(Throwable t)  { cf3.completeExceptionally(t); }
});
// cf3 is now a CompletableFuture backed by the callback-based client

// Wait for multiple futures (non-blocking until the join point)
CompletableFuture<String> a = CompletableFuture.supplyAsync(() -> serviceA());
CompletableFuture<String> b = CompletableFuture.supplyAsync(() -> serviceB());
CompletableFuture<String> c = CompletableFuture.supplyAsync(() -> serviceC());

// allOf: wait for all three; results retrieved from originals
CompletableFuture.allOf(a, b, c).thenRun(() -> {
    try {
        String ra = a.get();   // already done, no blocking
        String rb = b.get();
        String rc = c.get();
        assemble(ra, rb, rc);
    } catch (Exception e) { throw new RuntimeException(e); }
});

// anyOf: first to complete wins
CompletableFuture.anyOf(a, b, c)
    .thenAccept(result -> System.out.println("First: " + result));
```

> **Code walkthrough:** Running I/O on the common `ForkJoinPool`
> is the most common `CompletableFuture` mistake. The common pool
> has parallelism = CPU count. One blocked I/O thread occupies a
> CPU slot, causing CPU-bound parallel streams to queue. The `ioPool`
> with more threads handles I/O blocking without starving CPU work.
> The callback-wrapping pattern bridges legacy async APIs to
> `CompletableFuture`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `CompletableFuture` runs tasks asynchronously and lets you chain
> operations with `thenApply`, combine with `allOf`, and get results
> with `get()` or `join()`. Use `supplyAsync()` with a custom
> executor for I/O operations.

---

**Senior / Staff (5+ years):**

> I always specify a custom executor for I/O-bound futures.
> `CompletableFuture.completedFuture()` is the pattern for
> conditional async: if the value is in cache, return completed;
> if not, return `supplyAsync()`. This gives callers a consistent
> `CompletableFuture` API regardless of whether the call was
> synchronous or async.

---

### ❓ Questions You Will Be Asked

#### Definition

- "How does CompletableFuture differ from Future?"

🗣️ "`Future` is a handle for a result that is not yet available.
To get the result you must call `get()`, which blocks. `CompletableFuture`
adds: (1) callback registration - `thenApply()`, `thenAccept()`,
`thenRun()` run when the result is ready, without blocking; (2)
chaining - the result of one stage is the input to the next;
(3) combining - `thenCombine()`, `allOf()`, `anyOf()` coordinate
multiple async operations; (4) external completion - `complete()`,
`completeExceptionally()` let any thread complete the future;
(5) exception handling - `exceptionally()`, `handle()` manage errors
in the pipeline without interrupting the chain."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | allOf/anyOf, supplyAsync vs runAsync, completedFuture. |
| Hiring Manager   | I/O-bound futures and the executor choice. |
| Bar Raiser       | join() vs get(), common pool contamination, orTimeout() (Java 9). |
| Peer Engineer    | "Our all I/O was on the common ForkJoinPool - parallel streams degraded..." |

---

---

# CompletableFuture Chaining and Composition

**Interview Weight:** high - Tests whether you know the difference
between thenApply/thenCompose, sync vs async variants, and how
to fan-out/fan-in.

---

### 🎯 Model Answer

**30 seconds:**

> Chaining transforms results through stages. Key operators:
> `thenApply(fn)` - transform the result (sync); `thenCompose(fn)` -
> chain another async stage (the fn returns a `CompletableFuture`);
> `thenCombine(other, fn)` - combine two independent futures into
> one. The `Async` suffix variants (`thenApplyAsync`, `thenComposeAsync`)
> run on the thread pool instead of the completing thread. Use
> `thenCompose` instead of `thenApply` when the transformation is
> itself async.

**3 minutes (Senior):**

> `thenApply` vs `thenCompose`: `thenApply` wraps a synchronous
> function that returns `T`, producing `CompletableFuture<T>`.
> `thenCompose` accepts a function that returns `CompletableFuture<T>`,
> avoiding `CompletableFuture<CompletableFuture<T>>` nesting. This
> is equivalent to `flatMap` on a stream.
>
> The `Async` suffix controls which thread executes the stage
> function. Without `Async`: the completing thread runs the
> continuation (fast, but uses the completing thread's pool or the
> calling thread). With `Async`: the function runs on the
> `ForkJoinPool.commonPool()` or the specified executor.
> For CPU-heavy transformations, use `Async` to avoid blocking
> the I/O thread that completed the future.
>
> Fan-out pattern: start N independent async operations, wait for
> all, combine results. `CompletableFuture.allOf()` + `join()` on
> each after `allOf` completes is the standard pattern. For collecting
> results:
> ```java
> List<CompletableFuture<T>> futs = items.stream().map(...)...;
> CompletableFuture.allOf(futs.toArray(new CompletableFuture[0]))
>     .thenApply(v -> futs.stream().map(CompletableFuture::join).collect(...))
> ```
> `join()` after `allOf` is non-blocking (all are already complete).

---

### 💻 Code Example

**Example 1: Chain, compose, and fan-out**

```java
// WRONG: thenApply with an async function - wraps in CompletableFuture
CompletableFuture<CompletableFuture<User>> nested =
    CompletableFuture.supplyAsync(() -> userId)
        .thenApply(id -> fetchUserAsync(id));  // double-wrapped!

// GOOD: thenCompose = flatMap for CompletableFuture
CompletableFuture<User> user =
    CompletableFuture.supplyAsync(() -> userId)
        .thenCompose(id -> fetchUserAsync(id))  // flattens the nesting
        .thenCompose(u  -> enrichWithProfile(u)); // chain another async step

// Combine two independent async results
CompletableFuture<UserDetails> details = 
    fetchUserAsync(userId).thenCombine(
        fetchPermissionsAsync(userId),
        (user, perms) -> new UserDetails(user, perms)  // combine when both done
    );

// Fan-out: parallel requests, wait for all
List<String> serviceUrls = List.of("url1", "url2", "url3");
List<CompletableFuture<String>> futures = serviceUrls.stream()
    .map(url -> CompletableFuture.supplyAsync(
        () -> httpClient.get(url), ioPool
    ))
    .collect(Collectors.toList());

CompletableFuture<List<String>> allResults =
    CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
        .thenApply(v -> futures.stream()
            .map(CompletableFuture::join)  // non-blocking: all done
            .collect(Collectors.toList()));

// Timeout on the combined result (Java 9+)
allResults.orTimeout(5, TimeUnit.SECONDS);
```

> **Code walkthrough:** `thenApply(fetchUserAsync)` wraps the result
> in a nested `CompletableFuture<CompletableFuture<User>>`. `thenCompose`
> unwraps it like `flatMap`. The fan-out pattern uses `allOf` to
> wait for all futures, then `join()` on each (safe because `allOf`
> already completed them). `orTimeout()` (Java 9) cancels the
> chain if not complete within the timeout.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Use `thenApply` to transform a result (sync function). Use
> `thenCompose` when the transformation is itself async (returns
> CompletableFuture). Use `thenCombine` to merge two independent
> futures. Fan-out with allOf + join.

---

**Senior / Staff (5+ years):**

> The `thenApply` vs `thenCompose` distinction is the most common
> source of subtle bugs. I review any `thenApply` with a function
> that returns `CompletableFuture` - it should be `thenCompose`.
> For the `Async` suffix: use it for CPU-heavy or I/O stages to
> prevent blocking the completing thread.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "When would you use thenCompose over thenApply?"

🗣️ "Use `thenCompose` when the transformation function itself returns
a `CompletableFuture`. `thenApply` with a `f: T → CompletableFuture<U>`
produces `CompletableFuture<CompletableFuture<U>>` - nested futures
that you cannot easily chain further. `thenCompose` with the same
function produces `CompletableFuture<U>` - it is `flatMap` for
`CompletableFuture`. The pattern: any time you have an async step
that depends on the result of a previous async step, use
`thenCompose`."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | thenApply vs thenCompose, Async variants, allOf fan-out. |
| Hiring Manager   | Parallel service fan-out pattern - real-world use. |
| Bar Raiser       | orTimeout, completeOnTimeout, Async variants executor control. |
| Peer Engineer    | "The nested CompletableFuture bug cost us a day to debug..." |

---

---

# CompletableFuture Exception Handling

**Interview Weight:** high - Tested because exception handling in
async pipelines is non-obvious and commonly done wrong.

---

### 🎯 Model Answer

**30 seconds:**

> Three exception-handling methods: `exceptionally(fn)` - recover
> from a failed stage with a fallback value; `handle(fn)` - handle
> both success and failure in one stage; `whenComplete(fn)` - run
> a callback on completion (success or failure) without transforming
> the result. The key rule: if you don't handle exceptions in the
> pipeline, they propagate to `get()`/`join()` as `CompletionException`
> and are silently dropped if the future is never observed.

**3 minutes (Senior):**

> `exceptionally(fn)` is recovery: if the previous stage threw,
> the function receives the `Throwable` and returns a fallback value.
> If the previous stage succeeded, `exceptionally` is skipped. This
> is the "catch and recover" pattern.
>
> `handle(fn)` receives both the value (or null on failure) and
> the exception (or null on success). It always runs. This is
> the "always run this stage, check which happened" pattern.
> Unlike `exceptionally`, `handle` can choose to return a fallback
> or re-throw.
>
> `whenComplete(fn)` is a side-effect: runs after the stage
> completes (success or failure) but does not change the value
> or exception that continues down the chain. Use it for logging
> and metrics.
>
> The silent exception problem: if you create a `CompletableFuture`
> with `runAsync()` or `supplyAsync()` and never call `get()` or
> add an error handler, exceptions are silently swallowed. Always
> add a final `.exceptionally(e -> { log(e); return null; })` to
> fire-and-forget pipelines.

---

### 💻 Code Example

**Example 1: Three exception handling strategies**

```java
CompletableFuture<String> pipeline =
    CompletableFuture.supplyAsync(() -> fetchFromApi(url))

    // RECOVERY: catch failure, return fallback
    .exceptionally(ex -> {
        logger.warn("API fetch failed, using fallback: {}", ex.getMessage());
        return "fallback-value";     // pipeline continues with fallback
    })

    .thenApply(result -> transform(result));

// HANDLE: always runs, access both result and exception
CompletableFuture<String> withHandle =
    CompletableFuture.supplyAsync(() -> fetchFromApi(url))
    .handle((result, ex) -> {
        if (ex != null) {
            logger.error("Failed", ex);
            return "fallback";        // return fallback on failure
        }
        return result;               // return result on success
    });

// WHEN_COMPLETE: side effects without changing the pipeline
CompletableFuture<String> withLogging =
    CompletableFuture.supplyAsync(() -> fetchFromApi(url))
    .whenComplete((result, ex) -> {
        if (ex != null) metricsService.increment("api.error");
        else            metricsService.increment("api.success");
        // result/exception unchanged - pipeline continues as before
    });

// BAD: Fire-and-forget with no exception handler (silent failure)
CompletableFuture.runAsync(() -> sendEmail(user));  // exceptions lost!

// GOOD: Always handle exceptions on fire-and-forget
CompletableFuture.runAsync(() -> sendEmail(user))
    .exceptionally(ex -> {
        logger.error("Failed to send email to {}: {}", user, ex.getMessage());
        return null;  // Void pipeline
    });
```

> **Code walkthrough:** `exceptionally` transforms the exception
> into a fallback value and resumes the pipeline. `handle` always
> executes and can return different things for success/failure.
> `whenComplete` does not change the pipeline - it is a tap for
> side effects. The fire-and-forget pattern without an exception
> handler is the most common production mistake: email sending
> failures are silently swallowed.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `exceptionally` handles failures with a fallback. `handle` handles
> both success and failure. `whenComplete` is a side-effect observer.
> Always add exception handling to async pipelines.

---

**Senior / Staff (5+ years):**

> In production async code I apply a standard pattern: `exceptionally`
> for recovery, `whenComplete` for metrics/logging, `orTimeout`
> for deadlines. The silent failure problem is the worst: a
> `CompletableFuture` exception with no handler is gone. I enforce
> "all fire-and-forget futures must have an `exceptionally` handler"
> in code review.

---

### ❓ Questions You Will Be Asked

#### Mechanism

- "What is the difference between exceptionally() and handle()?"

🗣️ "`exceptionally(fn)` only runs when the stage failed. It receives
the `Throwable` and must return a recovery value of the same type.
The pipeline continues with the fallback value if it throws, or the
original pipeline terminates if it throws. `handle(fn)` always runs,
receiving both the value (null on failure) and the exception (null
on success). It can return any value or rethrow. Use `exceptionally`
for simple recovery scenarios. Use `handle` when you need to always
run a stage and conditionally choose between success and failure
handling."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Three methods, when each runs, silent failure. |
| Hiring Manager   | Production reliability - error propagation in async. |
| Bar Raiser       | CompletionException vs ExecutionException, multi-stage failure propagation. |
| Peer Engineer    | "Silent failures in our async notification pipeline took weeks to detect..." |

---

---

# Virtual Threads Project Loom

**Interview Weight:** high - The biggest change in Java concurrency
since Java 5. Tests awareness of the model, the impact on blocking
I/O, and the limitations.

---

### 🎯 Model Answer

**30 seconds:**

> Virtual threads (Java 21 GA) are JVM-managed threads that are
> cheap to create (few KB each) and park cheaply when blocking.
> They run on a small pool of OS carrier threads. When a virtual
> thread blocks on I/O, the JVM parks it and reuses the carrier
> thread for another virtual thread. This enables simple blocking
> code to scale to millions of concurrent operations - without
> async/reactive programming.

**3 minutes (Senior):**

> The traditional problem: one OS thread per request consumes ~1MB
> of stack. For 10,000 concurrent requests = 10GB RAM in stacks.
> With virtual threads, 10,000 concurrent operations use a handful
> of OS carrier threads (default: CPU count). Each virtual thread
> parks when blocking and resumes when the I/O completes - the OS
> thread is freed to run other virtual threads.
>
> The critical implication: you can write synchronous-looking code
> that scales as well as reactive/async code. `blockingDb.query(sql)`
> blocks the virtual thread (not the OS thread), so throughput is
> not lost. This directly competes with Project Reactor/RxJava
> reactive programming for I/O-bound services.
>
> Key limitations:
> 1. **Pinning**: synchronized blocks/methods pin the virtual thread
>    to the carrier thread - a pinned virtual thread blocks the
>    carrier while waiting. Fix: replace `synchronized` with
>    `ReentrantLock` in pinning hot paths (or use `-Djdk.tracePinnedThreads`
>    to detect).
> 2. **CPU-bound work**: virtual threads don't help CPU-bound code.
>    Parallelism still requires `ForkJoinPool` or parallel streams.
> 3. **ThreadLocal**: millions of virtual threads with large
>    `ThreadLocal` values = memory pressure. Java 21 introduces
>    `ScopedValues` as the alternative.

---

### 💻 Code Example

**Example 1: Virtual threads for concurrent I/O**

```java
// Old way: fixed thread pool (limited concurrency for I/O)
ExecutorService fixed = Executors.newFixedThreadPool(200);
// 200 requests in flight at a time; 201st queues

// Java 21: Virtual thread per task - unlimited I/O concurrency
ExecutorService virtual = Executors.newVirtualThreadPerTaskExecutor();
// Millions of concurrent tasks - each parks when blocked on I/O

// One-liner for creating a named virtual thread
Thread.ofVirtual().name("request-handler").start(() -> {
    String data = database.fetchUser(userId);  // blocks virtual thread
    // OS carrier thread is reused by other virtual threads during the block
    return processUser(data);
});

// Concurrent fan-out with virtual threads (replaces CompletableFuture)
try (ExecutorService pool = Executors.newVirtualThreadPerTaskExecutor()) {
    List<Future<String>> futures = IntStream.range(0, 1000)
        .mapToObj(i -> pool.submit(() -> callService(i)))
        .collect(Collectors.toList());

    for (Future<String> f : futures) {
        processResult(f.get());  // 1000 concurrent I/O calls, simple blocking code
    }
}  // pool.close() waits for all tasks to complete (Java 19+ AutoCloseable)

// Detect pinning (synchronized block pins carrier thread)
// BAD: synchronized block inside virtual thread
synchronized (lock) {  // pins carrier thread while waiting
    callSlowDatabase();  // blocks carrier thread, not just virtual thread
}

// GOOD: ReentrantLock does NOT pin
ReentrantLock lock = new ReentrantLock();
lock.lock();
try {
    callSlowDatabase();  // parks virtual thread, releases carrier thread
} finally {
    lock.unlock();
}
```

> **Code walkthrough:** `newVirtualThreadPerTaskExecutor()` creates
> a virtual thread per task with zero OS thread overhead. 1,000
> concurrent database calls use a handful of OS carrier threads.
> The blocking `f.get()` in the loop blocks the CALLING virtual
> thread (or OS thread if called from main) while each service call
> blocks its own virtual thread. The `synchronized` block pins the
> carrier - the virtual thread cannot yield, defeating the purpose.
> `ReentrantLock` uses `LockSupport.park()` which the scheduler
> handles correctly.

---

### ⚖️ Comparison

| | OS Threads | Virtual Threads | Async (CompletableFuture) |
|--|------------|-----------------|--------------------------|
| Code style | blocking | blocking | async/callback |
| Memory per thread | ~1MB | ~few KB | minimal (no stack) |
| I/O blocking | blocks OS thread | parks virtual thread | non-blocking |
| CPU-bound | efficient | same as OS threads | efficient |
| Debugging | simple stack | simple stack | complex async traces |
| Pinning risk | n/a | synchronized blocks | n/a |
| Java version | all | Java 21 GA | Java 8+ |

**The deciding factor:** Java 21+, I/O-bound = virtual threads
(simplest code). CPU-bound = ForkJoinPool/parallel streams.
Pre-Java 21 I/O-bound = CompletableFuture or reactive.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Virtual threads are lightweight threads managed by the JVM.
> They park cheaply when blocked, freeing the OS thread. This
> allows millions of concurrent tasks with simple blocking code.
> Available as GA in Java 21.

*Push deeper:* What is pinning and why does synchronized cause it?

---

**Senior / Staff (5+ years):**

> Virtual threads change the economics of concurrency in Java.
> For I/O-bound services, I can write simple blocking code and
> scale to high concurrency without reactive complexity. The two
> things I monitor when adopting virtual threads: (1) pinning from
> `synchronized` blocks in hot paths (detected with
> `-Djdk.tracePinnedThreads=full`); (2) `ThreadLocal` memory with
> many concurrent tasks (migrate to `ScopedValues` where possible).

---

### ❓ Questions You Will Be Asked

#### Definition

- "What are virtual threads and how do they differ from OS threads?"

🗣️ "Virtual threads are JVM-managed, lightweight threads. An OS
thread has a ~1MB stack allocated in kernel memory. A virtual thread
has a small initial stack (~few KB) that grows dynamically, and
is managed entirely by the JVM. When a virtual thread blocks on
I/O or locks, the JVM parks it and reuses the carrier OS thread
for another virtual thread. This allows millions of virtual threads
to run on dozens of OS threads. The programming model is identical
to OS threads - write blocking code - but the scalability is close
to async/reactive without the code complexity."

#### Debugging

- "A virtual thread application is slower than expected. What
  would you check?"

🗣️ "First: check for pinning. If `synchronized` blocks appear
in the blocking hot paths, the virtual thread cannot yield -
it pins the carrier OS thread. Use `-Djdk.tracePinnedThreads=full`
to log all pinning events. Replace `synchronized` with `ReentrantLock`
in the hot paths. Second: check if the work is CPU-bound rather
than I/O-bound. Virtual threads give no benefit for CPU-bound
code. Third: check `ThreadLocal` usage - millions of virtual threads
with large `ThreadLocal` objects cause GC pressure."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Carrier thread model, pinning, synchronized limitation. |
| Hiring Manager   | Migration from reactive to virtual threads. |
| Bar Raiser       | ScopedValues, structured concurrency (Java 21+), continuations. |
| Peer Engineer    | "Switching to virtual threads cut our async boilerplate by 80%..." |

---

---

# Reactive Programming vs Threads

**Interview Weight:** high - Architect-level comparison. Tests
ability to articulate the trade-offs between thread-per-request
and reactive/event-loop models.

---

### 🎯 Model Answer

**30 seconds:**

> Reactive programming (Project Reactor, RxJava) uses non-blocking
> pipelines of events/data on a small thread pool (typically CPU
> count). Blocking is forbidden - it would stall the event loop.
> Advantages: extreme throughput with minimal threads. Disadvantages:
> complex error handling, difficult debugging (async stack traces),
> steep learning curve. Virtual threads (Java 21) provide similar
> throughput with familiar blocking code, reducing the need for
> reactive frameworks for most I/O-bound use cases.

**3 minutes (Senior):**

> The reactive model uses a publish-subscribe pipeline: data flows
> through operators (`map`, `flatMap`, `filter`) without blocking.
> The thread executing the operator must never block. This means
> any blocking operation (database call, HTTP call) must be wrapped
> in a non-blocking async driver (R2DBC for databases, reactive
> HTTP clients). This forced reactive migration is the biggest
> operational cost of reactive adoption.
>
> Reactive excels in scenarios where data throughput is the
> primary concern: streaming large datasets (back-pressure built
> in), event-driven architectures, WebSocket/SSE servers, high-
> throughput message processing. The back-pressure mechanism
> (subscriber signals demand to the publisher) naturally handles
> fast producers and slow consumers without dropping data or OOM.
>
> Virtual threads (Java 21) address the same problem as reactive
> for I/O-bound services: many concurrent I/O operations with few
> OS threads. The key practical difference: virtual threads work
> with ALL existing blocking Java libraries (JDBC, synchronous HTTP
> clients). Reactive requires new non-blocking libraries for every
> data source. For most web applications, virtual threads will
> replace reactive programming. Reactive remains superior for
> streaming/event-driven architectures where back-pressure and
> pipeline operators are the primary model.

---

### 💻 Code Example

**Example 1: Same operation - reactive vs virtual threads**

```java
// REACTIVE (Project Reactor): non-blocking pipeline
Mono<User> reactiveUser = Mono.fromCallable(() -> userId)
    .flatMap(id -> userRepository.findById(id))  // non-blocking (R2DBC)
    .flatMap(user -> profileService.enrich(user)) // non-blocking
    .doOnError(ex -> log.error("Failed", ex))
    .timeout(Duration.ofSeconds(5))
    .onErrorReturn(User.ANONYMOUS);
// Returns: reactive type - caller must subscribe to trigger

// VIRTUAL THREADS (Java 21): blocking code, same throughput
User virtualUser;
try {
    User u = userRepository.findById(userId);      // JDBC - blocks virtual thread
    virtualUser = profileService.enrich(u);        // HTTP - blocks virtual thread
} catch (Exception ex) {
    log.error("Failed", ex);
    virtualUser = User.ANONYMOUS;
}
// Returns: value directly (readable, debuggable, stacktraceable)

// Reactive back-pressure (streaming) - no virtual thread equivalent
Flux<Order> ordersStream = orderRepository.findAllByUserId(userId)
    .filter(order -> order.isActive())
    .map(this::enrichOrder)
    .limitRate(100);   // process 100 at a time (back-pressure)

// Virtual threads: no built-in back-pressure for streaming
// Would require: Semaphore or BlockingQueue for flow control
```

> **Code walkthrough:** The reactive chain is powerful but complex.
> `flatMap` is required for any async sub-call (not `map`). Error
> handling requires `onErrorReturn`, `onErrorResume`, etc. The
> virtual threads version is simpler blocking code that scales
> identically for I/O-bound work. Reactive retains an advantage
> for streaming with built-in back-pressure: `limitRate(100)` tells
> the database to produce 100 rows at a time.

---

### ⚖️ Comparison

| | Thread-per-request | Reactive | Virtual Threads |
|--|-------------------|----------|-----------------|
| Code style | blocking | async pipelines | blocking |
| OS threads | 1 per request | CPU count | CPU count (carrier) |
| I/O scaling | poor (1MB/thread) | excellent | excellent |
| Blocking allowed | yes | NO | yes |
| Back-pressure | manual (BQ) | built-in | manual |
| Debugging | simple | complex (async traces) | simple |
| Library compat | any blocking lib | reactive libs only | any blocking lib |
| Java version | all | requires Reactor/RxJava | Java 21+ |

**The deciding factor:** Java 21+ I/O-bound service = virtual
threads (simpler, same performance). Streaming with back-pressure
or event-driven = reactive. Pre-Java 21 high-concurrency = reactive
or CompletableFuture.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Reactive programming uses non-blocking pipelines. It's great
> for high throughput but complex to write. Virtual threads (Java 21)
> give similar throughput with simple blocking code. Reactive is
> still useful for streaming and back-pressure scenarios.

---

**Senior / Staff (5+ years):**

> I evaluate reactive vs virtual threads on three axes: back-
> pressure needs (reactive wins), existing library ecosystem (virtual
> threads win - no reactive driver needed), and team familiarity
> (blocking code is easier to learn). For a new Java 21+ service
> I would use virtual threads by default and reach for reactive
> only if streaming back-pressure is a core requirement.

---

### ❓ Questions You Will Be Asked

#### Trade-off

- "When would you choose reactive programming over virtual threads?"

🗣️ "Three scenarios. First: streaming data with back-pressure.
Project Reactor's `Flux` with `limitRate()` naturally signals demand
to the producer, preventing OOM from fast producers. Virtual threads
would need manual `Semaphore` or `BlockingQueue` flow control.
Second: teams and codebases already on reactive stacks with reactive
drivers - migration cost outweighs benefit. Third: integration with
reactive frameworks (Spring WebFlux) where the reactive model is
the natural fit. For a new service in Java 21+ that does primarily
request/response I/O without streaming, virtual threads eliminate
reactive complexity."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Back-pressure, library compatibility, debugging. |
| Hiring Manager   | Migration strategy for existing reactive codebases. |
| Bar Raiser       | Structured concurrency, back-pressure alternatives with virtual threads. |
| Peer Engineer    | "Migrating from WebFlux to virtual threads cut our code complexity by half..." |
