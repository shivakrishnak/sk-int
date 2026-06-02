---
layout: default
title: "Async Java - L1 CompletableFuture Basics"
parent: "Async Java"
nav_order: 2
permalink: /async-java/l1-completablefuture-basics/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Async Java - L1 CompletableFuture Basics](#async-java---l1-completablefuture-basics) | medium |
| 2 | [CompletableFuture Basics](#completablefuture-basics) | medium |
| 3 | [thenApply vs thenCompose vs thenCombine](#thenapply-vs-thencompose-vs-thencombine) | medium |
| 4 | [Future and Callable Interface](#future-and-callable-interface) | medium |

---

# CompletableFuture Basics

---
id: AJA-004
title: CompletableFuture Basics
category: Async Java
difficulty: ★☆☆
interview_weight: critical
asked_at: All
seniority: all
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> CompletableFuture is Java's primary API for composable async programming.
> It represents a value or computation that will be available in the future,
> and crucially it lets you register callbacks that fire when it completes -
> without blocking the caller. You can chain operations with thenApply,
> combine multiple futures with thenCombine, and handle errors with
> exceptionally. It replaced the blocking Future.get() pattern from Java 5.

**3 minutes:**
> CompletableFuture (Java 8) implements both `Future<T>` and
> `CompletionStage<T>`. The Future part lets it interoperate with existing
> code; the CompletionStage part is where all the power lives.
>
> Creating a CompletableFuture: `supplyAsync(() -> compute(), executor)`
> runs the lambda on the provided executor thread (or the common
> ForkJoinPool if no executor specified) and returns a CompletableFuture
> immediately. The calling thread is not blocked.
>
> Chaining: `cf.thenApply(result -> transform(result))` registers a
> callback that runs when cf completes. The callback runs on the thread
> that completed cf - or a new thread if cf was already completed. The
> return value is a new CompletableFuture representing the transformed result.
>
> Completing manually: `cf.complete(value)` and `cf.completeExceptionally(ex)`
> let you drive a CompletableFuture from external events - useful for
> bridging callback-based APIs.
>
> The non-obvious aspect: CompletableFuture does not prevent blocking. If
> you call `.get()` or `.join()` on it, the calling thread blocks. The
> async benefit comes from chaining callbacks instead of calling get().
> In production async code, `.get()` and `.join()` should only appear at
> the service boundary where you must return a synchronous result to the
> framework.

**Blank Mind Recovery:**

**(1) Restate:** "So you are asking about CompletableFuture - let me think
through what problem it solves over plain Future."

**(2) First principles:** "A Future gives you a promise of a future value.
CompletableFuture makes that promise composable - you can chain what to
do when it completes without blocking."

**(3) Bridge:** "This is like JavaScript Promise. A Promise represents a
future value and lets you .then() chain transformations. CompletableFuture
is Java's equivalent."

---

### 📘 Concept Explanation

**What it is:**
`CompletableFuture<T>` is a future that can be completed explicitly by
any code, supports callback-based non-blocking composition (thenApply,
thenCompose, thenCombine), and propagates exceptions through the chain.
It implements `Future<T>` for backward compatibility and
`CompletionStage<T>` for composition.

**The problem it solves:**
`Future<T>` (Java 5) required blocking `get()` to retrieve results.
There was no way to say "when this Future completes, run this function"
without blocking. CompletableFuture adds this callback registration,
enabling non-blocking async pipelines.

**How it works:**

```
supplyAsync(() -> A)        <- starts async, returns CF<A>
  .thenApply(a -> B(a))     <- transforms result, returns CF<B>
  .thenCompose(b -> CF<C>)  <- flat-maps to another CF, returns CF<C>
  .exceptionally(e -> D)    <- handles errors, returns CF<D or C>
  .thenAccept(c -> use(c))  <- terminal: consumes result
```

> **Code walkthrough:** This CompletableFuture Basics example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Each stage returns a new CompletableFuture. Callbacks execute on the
thread that completed the previous stage (or a specified executor with
`thenApplyAsync`). The chain is lazy: nothing runs until `supplyAsync`
starts the first computation.

**The key insight:**
CompletableFuture enables fork-join patterns without blocking: start
multiple async computations with `supplyAsync`, combine with `allOf` or
`thenCombine`, process results in callbacks. No thread is ever blocked
waiting for another thread - only the underlying I/O or computation
waits, while threads are free for other work.

**When to use it:**
- Parallel service calls: call 3 downstream services simultaneously
- Async result transformation pipelines
- Bridging callback-based APIs to composable futures
- Java 8-17 projects (Java 21+ consider Virtual Threads)

**When NOT to use it:**
- CPU-bound parallel work: parallel streams are more readable
- When backpressure is needed: use Reactor Flux instead
- Simple sequential code: sync code is clearer for non-concurrent logic

**Alternatives:**
- Java Virtual Threads (Java 21+): same concurrency goal, sync code style
- Project Reactor Mono<T>: reactive version with backpressure + operators
- Kotlin Coroutines: deferred values with cooperative cancellation

**First-principles derivation:**
A future represents a computation not yet complete. To use it without
blocking, we need a way to register "what to do next." This is callback
composition - register a function to execute when the value is ready.
CompletableFuture is this pattern made into a type-safe, composable API.

---

### 💻 Code Example

**Basic CompletableFuture patterns:**

```java
// 1. Create and chain
CompletableFuture<String> future =
    CompletableFuture.supplyAsync(
        () -> fetchUserName(userId), ioExecutor)
    .thenApply(name -> name.toUpperCase())  // transform
    .thenApply(name -> "Hello, " + name);   // chain

// 2. Complete manually (bridge from callback API)
CompletableFuture<String> cf = new CompletableFuture<>();
legacyAsyncApi.call(userId,
    result -> cf.complete(result),         // success callback
    error -> cf.completeExceptionally(error)); // error callback
// Now cf is a CompletableFuture you can chain

// 3. allOf: wait for multiple completions (no result)
CompletableFuture<Void> allDone =
    CompletableFuture.allOf(cf1, cf2, cf3);
allDone.thenRun(() -> {
    // All three completed. Safe to call .join() now:
    String r1 = cf1.join(); // won't block - already done
    String r2 = cf2.join();
    String r3 = cf3.join();
    buildResponse(r1, r2, r3);
});

// 4. anyOf: complete when first finishes (race pattern)
CompletableFuture<Object> first =
    CompletableFuture.anyOf(primary, fallback);
```

> **Code walkthrough:** Example 1 shows the standard chaining pattern:ice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `supplyAsync` starts computation on an executor thread; each `thenApply`
> registers a transform that runs when the previous stage completes. No
> thread is blocked. Example 2 shows the "bridge" pattern for legacy
> callback APIs - create a CompletableFuture manually and call `complete()`
> or `completeExceptionally()` from the callback. Example 3 is the most
> important production pattern: `allOf` for parallel fan-out. Critically,
> `.join()` inside `thenRun` is safe because we know all futures are done
> by the time `thenRun` fires - no blocking occurs. Example 4 shows
> `anyOf` for redundant calls or fallback patterns.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> CompletableFuture lets me run code asynchronously and chain what to do
> with the result - without blocking. I use supplyAsync to start async
> computation, thenApply to transform the result, and exceptionally to
> handle errors. The key difference from plain Future is that I never
> need to call get() to get the result - I register callbacks instead.
> allOf lets me wait for multiple async calls to complete simultaneously.

*Push deeper:* Explain the difference between `thenApply` and
`thenApplyAsync` - which executor the callback runs on.

---

**Senior / Staff:**
> CompletableFuture is the building block for async orchestration in Java
> 8-17. The critical production patterns are: (1) always provide an explicit
> executor to supplyAsync - the default ForkJoinPool.commonPool() is shared
> JVM-wide and CPU-sized, wrong for I/O work; (2) always attach error
> handlers (exceptionally or handle) - unhandled exceptions are silently
> stored in the future; (3) never call get() or join() on the hot path -
> only at the service boundary.
>
> The main limitation I hit in production is no backpressure: if I generate
> 10,000 CompletableFutures in a loop, they all execute immediately,
> potentially exhausting the pool. For that scenario, reactive streams
> (or explicit rate limiting) are needed.

*Push deeper (Staff):* CompletableFuture does not support cancellation
propagation - calling cf.cancel() does not interrupt the running task.
For proper cancellation semantics, Structured Concurrency (Java 21+)
or reactive streams with subscription.cancel() are required.

---

### ⚠️ Common Misconceptions

**Misconception: "CompletableFuture automatically uses a large thread pool."**

By default, `CompletableFuture.supplyAsync(() -> work)` uses
`ForkJoinPool.commonPool()`. This pool is CPU-sized (typically
CPU cores - 1 threads). For I/O-bound tasks, this is catastrophically
wrong: a single blocking I/O call occupies a precious CPU core slot,
and under any load the pool saturates immediately.

Always provide an explicit I/O-sized executor:
```java
// CORRECT for I/O-bound tasks:
ExecutorService ioPool = Executors.newFixedThreadPool(200);
CompletableFuture.supplyAsync(() -> dbCall(), ioPool);
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

---

### 🚨 Failure Modes and Diagnosis

**Failure: Silent swallowed exception in CompletableFuture chain**

Symptom: service call succeeds (returns 200) but expected side effect
did not happen. No exception in logs.

Cause: a CompletableFuture chain throws an exception but no handler is
attached. The exception is stored in the future object. If no code calls
`get()`, `join()`, or attaches `whenComplete()`/`handle()`, the exception
is never surfaced.

Diagnosis:
```java
// Add to every terminal CompletableFuture:
cf.whenComplete((result, ex) -> {
    if (ex != null) {
        log.error("Async chain failed: "
            + ex.getMessage(), ex);
        // alert, metric, etc.
    }
});
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

Fix: establish a policy: every CompletableFuture chain must end with
`whenComplete` or `exceptionally` that logs or re-throws errors. Use
a wrapper utility that enforces this:
```java
public static <T> CompletableFuture<T> tracked(
        CompletableFuture<T> cf, String context) {
    return cf.whenComplete((r, ex) -> {
        if (ex != null)
            log.error("[{}] async failed", context, ex);
    });
}
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions minimum.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What is CompletableFuture and how does it differ from Future?**

`Future<T>` (Java 5): represents a value that will be available in the
future. To retrieve it, you must call `future.get()` which blocks the
calling thread until the value is ready. There is no way to register
"run this when the future completes" without blocking.

`CompletableFuture<T>` (Java 8): extends Future with `CompletionStage<T>`.
Key differences:
- Callback registration: `thenApply`, `thenCompose`, `whenComplete`
  run when the future completes, without blocking the caller.
- Manual completion: any code can call `cf.complete(value)` or
  `cf.completeExceptionally(ex)` to complete the future.
- Composition: `allOf`, `anyOf`, `thenCombine` for combining multiple
  futures into one.

The practical difference: Future requires polling or blocking to get
results. CompletableFuture registers callbacks that execute automatically,
enabling fully non-blocking async code.

*What separates good from great:* Noting that CompletableFuture.get()
still exists and still blocks - the non-blocking API is the completion
stage methods. Candidates who say "CompletableFuture doesn't block" are
wrong; it blocks if you call get(). The point is you don't have to.

---

**[JUNIOR] Q2 - [CONCEPTUAL] What is the difference between thenApply and thenApplyAsync?**

`thenApply(fn)`: runs fn on the thread that completed the previous
stage. If the previous stage completed on pool-thread-5, fn runs on
pool-thread-5 immediately. If the future is already complete when
thenApply is called, fn runs on the calling thread.

`thenApplyAsync(fn)`: always runs fn on the executor (ForkJoinPool or
provided executor) regardless of which thread completed the previous stage.

When to use each:
- `thenApply`: for lightweight transformations (mapping, formatting).
  Avoids unnecessary thread hops.
- `thenApplyAsync`: for blocking or CPU-intensive transformations that
  should not run on the completing thread (especially the event loop
  thread in reactive contexts).

Production risk: using `thenApply` for a heavy transformation in a
Netty/reactive context where the completing thread is the event loop.
This blocks the event loop, degrading all concurrent requests.

*What separates good from great:* Understanding that thenApply creates
a dependency but not a new task: the function runs inline on the
completing thread. thenApplyAsync submits a new task to the executor,
adding a thread hop but guaranteeing isolation from the completing thread.

---

**[JUNIOR] Q3 - [CONCEPTUAL] How do you run two CompletableFutures in parallel and combine results?**

Two patterns:

**thenCombine** - when both futures are already in progress:
```java
CompletableFuture<User>  uf = supplyAsync(() -> getUser(id));
CompletableFuture<Order> of = supplyAsync(() -> getOrder(id));
CompletableFuture<Response> combined =
    uf.thenCombine(of, (user, order) ->
        buildResponse(user, order));
// uf and of run in parallel; combined fires when both done
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

**allOf** - for three or more futures:
```java
var f1 = supplyAsync(() -> callA());
var f2 = supplyAsync(() -> callB());
var f3 = supplyAsync(() -> callC());
CompletableFuture.allOf(f1, f2, f3)
    .thenRun(() -> {
        // All done - join() is non-blocking here
        Result r = combine(f1.join(), f2.join(), f3.join());
        respond(r);
    });
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

Key distinction: `thenCombine` gives you typed access to both results
in the BiFunction. `allOf` returns `CompletableFuture<Void>` - you
must call `join()` on each individual future inside the callback to get
results. Always safe inside the `thenRun`/`thenAccept` because allOf
only fires after all complete.

*What separates good from great:* Knowing `allOf` has no way to collect
individual results - you need the futures array in scope when handling
the callback. A cleaner production pattern uses streams:
```java
List<CompletableFuture<T>> futures = ids.stream()
    .map(id -> supplyAsync(() -> fetch(id), pool))
    .toList();
CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
    .thenApply(v -> futures.stream()
        .map(CompletableFuture::join).toList());
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

---

**[MID] Q4 - [CONCEPTUAL] How do you handle errors in a CompletableFuture chain?**

Three error handling methods, each with distinct semantics:

`exceptionally(fn)`: recovers from exceptions, returns a fallback value.
The chain continues with fn's return value. Non-exceptional path is
passed through unchanged.
```java
cf.exceptionally(ex -> {
    log.warn("Fallback for: " + ex.getMessage());
    return defaultValue; // chain continues with this
});
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

`handle(BiFunction<T, Throwable, U>)`: called for both success and
failure. Can inspect both the result and the exception. Can return a
different type.
```java
cf.handle((result, ex) -> {
    if (ex != null) return ErrorResponse.of(ex);
    return SuccessResponse.of(result);
});
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

`whenComplete(BiConsumer<T, Throwable>)`: side-effect only (logging,
metrics). Cannot transform the result or recover. The exception (if any)
continues propagating.
```java
cf.whenComplete((result, ex) -> {
    metrics.record(ex != null ? "error" : "success");
    // exception propagates to next stage regardless
});
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

*What separates good from great:* Knowing that `exceptionally` and
`handle` RECOVER from exceptions (chain continues normally after them).
`whenComplete` does NOT recover - if the upstream threw, the exception
propagates past whenComplete to the next stage. Misusing whenComplete
as a recovery handler is a common bug.

---

**[MID] Q5 - [CONCEPTUAL] What executor should you use with CompletableFuture for I/O tasks?**

Never use the default (ForkJoinPool.commonPool()) for I/O tasks. It is:
- Shared across the entire JVM (other frameworks use it too)
- CPU-sized (number of cores - 1 threads)
- Designed for non-blocking CPU work

For I/O-bound tasks, use a dedicated fixed thread pool:
```java
// Sized for expected I/O concurrency, not CPU cores
private static final ExecutorService IO_POOL =
    Executors.newFixedThreadPool(
        200, // tune based on I/O latency and concurrency
        r -> {
            Thread t = new Thread(r, "io-pool-thread");
            t.setDaemon(true); // don't block JVM shutdown
            return t;
        });

CompletableFuture.supplyAsync(() -> jdbc.query(...), IO_POOL);
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

For Java 21+, use a virtual thread executor:
```java
ExecutorService vtPool =
    Executors.newVirtualThreadPerTaskExecutor();
CompletableFuture.supplyAsync(() -> jdbc.query(...), vtPool);
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

This creates one virtual thread per task - no pool sizing needed. The
JDK handles carrier thread multiplexing automatically.

*What separates good from great:* Knowing that HikariCP (the standard
JDBC pool) limits concurrent DB connections independently. A 200-thread
I/O pool with a 10-connection HikariCP pool: 190 threads will wait for
DB connections, not for I/O. The right configuration aligns pool sizes
with actual resource limits.

---

**[MID] Q6 - [CONCEPTUAL] What is the difference between complete() and completeAsync()?**

`complete(T value)`: synchronously completes the future with the given
value, immediately triggering all registered callbacks on the calling thread
(or their registered executor threads). Blocking - the calling thread
waits for all synchronous callbacks to finish.

`completeAsync(Supplier<T>)`: submits the completion to an executor and
returns immediately. The future completes when the supplier finishes
executing on the executor. Non-blocking for the caller.

`obtrudeValue(T value)` / `obtrudeException(Throwable)`: forcibly
override a future's result even if it was already completed. Used rarely
(e.g., test scenarios, timeout overrides). Not safe for normal use.

The main use case for complete(): bridging event-driven or callback-
based systems to CompletableFuture:
```java
CompletableFuture<String> cf = new CompletableFuture<>();

// Register with callback-based API:
asyncLibrary.on("data", data -> cf.complete(data));
asyncLibrary.on("error", err -> cf.completeExceptionally(err));

// Now return cf to callers who can chain on it
return cf;
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

*What separates good from great:* Knowing that calling `complete()` from
within a callback can trigger synchronous callback chains before complete()
returns. For high-throughput event processing, this can cause unexpected
long execution on the event thread. `completeAsync()` or posting callbacks
to an executor avoids this.

---

**[SENIOR] Q7 - [CONCEPTUAL] How does CompletableFuture behave when exceptions occur mid-chain?**

When any stage in a CompletableFuture chain throws an exception, the
exception is stored in the resulting CompletableFuture. Downstream stages
that use `thenApply` or `thenCompose` are SKIPPED - they do not execute.
The exception propagates through the chain until an `exceptionally` or
`handle` stage catches it.

```java
CompletableFuture.supplyAsync(() -> "start")
    .thenApply(s -> { throw new RuntimeException("boom"); })
    .thenApply(s -> s + " never runs") // SKIPPED
    .thenApply(s -> s + " also skipped") // SKIPPED
    .exceptionally(ex -> "recovered: " + ex.getMessage())
    // ^ This runs with ex = CompletionException wrapping RuntimeException
    .thenAccept(s -> System.out.println(s)); // "recovered: boom"
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

Key: the exception is wrapped in `CompletionException` when propagating
through the chain. `exceptionally(fn)` receives the CompletionException.
`fn.getCause()` gives the original exception.

Exceptions in `thenApply`/`thenCompose` callbacks are automatically
wrapped and propagated. Exceptions in `exceptionally` itself also
propagate (no catch-all loop).

*What separates good from great:* Understanding that unhandled exceptions
in CompletableFuture chains are SILENT in production if nobody ever
calls `get()`. A chain that throws and has no `exceptionally` or
`handle` simply completes exceptionally and the error disappears unless
someone reads the future. This is why every production CompletableFuture
chain needs a terminal error handler.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational entry. Full tool comparison in L2+ files.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ entry. System design in L4/L5 files.)*

---

### 📊 Diagram

*(Omit: Chain flow expressed clearly through code examples above.)*

---
---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# thenApply vs thenCompose vs thenCombine

---
id: AJA-005
title: thenApply vs thenCompose vs thenCombine
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
> thenApply transforms the result of a future - like map on a stream.
> thenCompose flat-maps: it takes the result and returns a new
> CompletableFuture, unwrapping it - like flatMap on a stream. thenCombine
> waits for two independent futures to both complete, then merges the
> results. The rule: use thenApply for sync transformations, thenCompose
> when the transformation itself is async, thenCombine for parallel
> fan-out that needs both results.

**3 minutes:**
> The three methods map to functional programming concepts:
>
> `thenApply(T -> U)` is map. It takes the result T of the future,
> applies a synchronous function, and returns a new CompletableFuture<U>.
> The function must be synchronous - it returns U, not CompletableFuture<U>.
> Use this for pure transformations: string manipulation, object mapping,
> domain logic.
>
> `thenCompose(T -> CompletableFuture<U>)` is flatMap. It takes the result
> T, calls a function that returns a CompletableFuture<U>, and returns that
> CompletableFuture<U> directly (not CompletableFuture<CompletableFuture<U>>).
> Use this when the next step in the chain is itself async: "when user is
> fetched, then fetch their orders" - orders requires another async call.
>
> `thenCombine(CompletableFuture<U>, BiFunction<T,U,V>)` combines two
> independent futures. When both complete, applies the BiFunction to both
> results, returning CompletableFuture<V>. Use for parallel fan-out where
> both results are needed together.
>
> The classic mistake: nesting thenApply instead of thenCompose. If the
> function in thenApply returns a CompletableFuture, you get
> CompletableFuture<CompletableFuture<U>> - a nested future that never
> automatically unwraps. thenCompose is the unwrapping flatMap.

**Blank Mind Recovery:**

**(1) Restate:** "So you're asking about thenApply, thenCompose, and
thenCombine - let me think through what each does."

**(2) First principles:** "Map, flatMap, and zip from functional
programming. Apply transforms. Compose chains async operations. Combine
merges two parallel results."

**(3) Bridge:** "Same as Java Stream.map vs flatMap. flatMap is for when
the mapping function returns a stream (or future) - you don't want a
stream-of-streams, you want the contents merged."

---

### 📘 Concept Explanation

**What it is:**
Three core CompletableFuture combination methods that correspond to the
map/flatMap/zip operations from functional programming:
- `thenApply` = map (sync transform)
- `thenCompose` = flatMap (async transform, unwraps nested futures)
- `thenCombine` = zip (combines two independent async results)

**The problem it solves:**
Without thenCompose, chaining async operations produces nested futures
that must be manually unwrapped. Without thenCombine, running two async
operations in parallel and combining their results requires manual
coordination with CountDownLatch or join().

**How it works:**

```
thenApply (T -> U):
  CF<T> --[fn: T->U]--> CF<U>
  fn is synchronous; result is wrapped automatically.
  Use when: next step is a pure computation.

thenCompose (T -> CF<U>):
  CF<T> --[fn: T->CF<U>]--> CF<U>  (NOT CF<CF<U>>)
  fn returns a CompletableFuture; compose unwraps it.
  Use when: next step is another async operation.

thenCombine (CF<U>, BiFunction<T,U,V>):
  CF<T>  \
           +-[fn: T,U->V]--> CF<V>
  CF<U>  /
  Both futures run independently; fn fires when both done.
  Use when: two parallel results needed together.
```

> **Code walkthrough:** This thenApply vs thenCompose vs thenCombine example demonstrates a key concept in practice using CompletableFuture. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
The difference between `thenApply` and `thenCompose` is identical to
`Stream.map` vs `Stream.flatMap`. If your mapping function returns a
`CompletableFuture<U>`, always use `thenCompose`. Using `thenApply`
in that case gives `CompletableFuture<CompletableFuture<U>>` - a wrapped
future that does not automatically execute or resolve.

**When to use each:**
- `thenApply`: domain object mapping, string transforms, type conversion
- `thenCompose`: chaining async calls (fetch user, then fetch orders)
- `thenCombine`: parallel calls where both results are needed (user AND
  preferences must both be ready to build the response)

**When NOT to use:**
- Do not use thenApply when the transform is I/O or async - use thenCompose
- Do not use thenCombine for more than 2 futures - use allOf instead

**Alternatives:**
- `thenAcceptBoth`: like thenCombine but for void BiConsumer (no result)
- `runAfterBoth`: fire Runnable when both complete (neither result used)
- `applyToEither`/`acceptEither`: fire when FIRST of two completes

**First-principles derivation:**
Composing functions is the foundation of functional programming. Map
applies a function to a value. FlatMap applies a function that returns
a container and flattens the result. Zip combines two containers into
one. These three operations are sufficient to express any sequential
or parallel async pipeline.

---

### 💻 Code Example

**The three operations with a real service fan-out example:**

```java
// thenApply: sync transformation of async result
CompletableFuture<String> rawName =
    supplyAsync(() -> userService.getName(userId), pool);

CompletableFuture<String> upperName =
    rawName.thenApply(name -> name.toUpperCase()); // sync fn

// thenCompose: chained async calls (sequential dependency)
CompletableFuture<Orders> userOrders =
    supplyAsync(() -> userService.getUser(userId), pool)
    .thenCompose(user ->
        // Must use thenCompose: getOrders() is async
        supplyAsync(() -> orderService.getOrders(
            user.getId()), pool));
    // Returns CF<Orders>, NOT CF<CF<Orders>>

// WRONG (nested future - will not auto-resolve):
// .thenApply(user ->
//     supplyAsync(() -> orderService.getOrders(user.getId())))
// Returns CF<CF<Orders>> - a bug!

// thenCombine: parallel fan-out, combine when both ready
CompletableFuture<User>        uf =
    supplyAsync(() -> userService.getUser(id), pool);
CompletableFuture<Preferences> pf =
    supplyAsync(() -> prefService.getPrefs(id), pool);

CompletableFuture<Response> response =
    uf.thenCombine(pf,
        (user, prefs) -> buildResponse(user, prefs));
// uf and pf run simultaneously; response fires when both done
```

> **Code walkthrough:** The thenApply example transforms the nameice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> synchronously - no new async operation, just a mapping function. The
> thenCompose example shows the critical pattern: getOrders() is an async
> operation (returns a result from a service). Using thenApply would wrap
> the returned CompletableFuture in another CompletableFuture, leaving it
> unexecuted. thenCompose unwraps it, giving a single CF<Orders>. The
> thenCombine example runs both service calls in parallel since neither
> depends on the other. The BiFunction fires only after both complete,
> giving access to both results simultaneously.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> thenApply is for synchronous transforms - like map on a Stream.
> thenCompose is for when the next step returns a CompletableFuture
> itself - like flatMap on a Stream. If I use thenApply with a function
> that returns a CompletableFuture, I get a nested future that doesn't
> resolve automatically. thenCombine waits for two separate futures to
> both complete and combines their results.

*Push deeper:* Explain when getOrders() would require thenCompose vs
thenApply - specifically what "async" means for the next step.

---

**Senior / Staff:**
> The thenApply vs thenCompose distinction is the most common async Java
> bug I see in code reviews: someone uses thenApply when the function
> returns a CompletableFuture, getting CompletableFuture<CompletableFuture<T>>
> - a future that holds another future that nobody ever triggers.
>
> In production I use thenCompose for any sequential async dependency
> (get user, then get their permissions, then check policy) and thenCombine
> for truly parallel calls with both results needed. For more than 2
> parallel calls, allOf with a result-collecting stream is cleaner.
>
> The performance implication: thenCombine starts both computations
> immediately and combines when both complete. The total latency is
> max(latency_A, latency_B), not latency_A + latency_B. This is the
> primary motivation for parallel fan-out patterns.

*Push deeper (Staff):* Discuss operator fusion - when two thenApply
calls can be combined into one callback execution by the JVM's JIT,
and when thenApplyAsync breaks this optimization by forcing a thread hop.

---

### ⚠️ Common Misconceptions

**Misconception: "thenApply and thenCompose are interchangeable."**

Using thenApply when the function returns a CompletableFuture produces
`CompletableFuture<CompletableFuture<T>>`. The inner future is never
automatically triggered or awaited. Calling `.get()` or `.join()` on
the outer future gives you the inner unresolved CompletableFuture - not
the actual result. This is a silent bug: the code compiles, the outer
future completes, but the actual async work never runs. Always use
thenCompose when the mapping function is async.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Nested future from thenApply with async function**

Symptom: code that chains async service calls returns a result object
that appears to be the correct type, but when read it contains default
or null values. Downstream processing sees empty data.

Cause: `thenApply` was used where `thenCompose` was needed. The result
is a `CompletableFuture<CompletableFuture<User>>` cast to
`CompletableFuture<User>` - the inner future never runs.

Diagnosis:
```java
// Add explicit type to catch at compile time
CompletableFuture<CompletableFuture<User>> nested =  // won't compile cleanly
    cf.thenApply(id -> supplyAsync(() -> getUser(id)));

// vs correct:
CompletableFuture<User> flat =
    cf.thenCompose(id -> supplyAsync(() -> getUser(id)));
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

The type system helps: if the compiler infers
`CF<CF<User>>` for a thenApply call, that is always a bug.

Fix: always use `thenCompose` when the function returns a
`CompletableFuture`. Use `thenApply` only for synchronous (non-future-
returning) functions.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions minimum.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What is the difference between thenApply and thenCompose?**

`thenApply(T -> U)`: takes the result T of the current future and applies
a synchronous function to produce U. Returns `CompletableFuture<U>`.
The function runs synchronously on whatever thread completed the current
stage.

`thenCompose(T -> CompletableFuture<U>)`: takes the result T and calls
a function that returns a `CompletableFuture<U>`. thenCompose unwraps
the returned future, yielding `CompletableFuture<U>` (not the nested
`CompletableFuture<CompletableFuture<U>>` that thenApply would produce).

Analogy: `Stream.map` vs `Stream.flatMap`. If the mapping function returns
a Stream, flatMap flattens it. If the mapping function returns a
CompletableFuture, thenCompose flattens it.

Rule of thumb: does the next step in the chain involve an async call
(database, HTTP, queue)? Use thenCompose. Is it a pure in-memory
computation? Use thenApply.

*What separates good from great:* Demonstrating the nested future bug
from memory: `cf.thenApply(id -> supplyAsync(() -> getUser(id)))` returns
`CF<CF<User>>`. The inner future is never triggered until someone calls
`.get()` on it. This compiles and runs without throwing - silently broken.

---

**[JUNIOR] Q2 - [CONCEPTUAL] When would you use thenCombine vs allOf?**

`thenCombine(CF<U>, BiFunction<T,U,V>)`: combines exactly two futures.
Type-safe: the BiFunction receives T and U specifically. Returns CF<V>.
Best for two parallel calls where both typed results are needed.

`allOf(CF<?>...)`: waits for any number of futures (no type constraint).
Returns `CF<Void>` - no direct access to results. You must keep references
to the individual futures and call `.join()` on them inside the callback.
Best for three or more parallel calls.

```java
// 2 futures: thenCombine (typed, clean)
userFuture.thenCombine(orderFuture,
    (user, order) -> new Dashboard(user, order));

// 3+ futures: allOf with stream collection
CompletableFuture.allOf(f1, f2, f3)
    .thenApply(v -> Stream.of(f1, f2, f3)
        .map(CompletableFuture::join)
        .toList());
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

*What separates good from great:* Knowing that `allOf` with an empty
array completes immediately - `CompletableFuture.allOf()` is an edge
case that should be handled to avoid spurious empty results in production.

---

**[JUNIOR] Q3 - [CONCEPTUAL] What happens if a thenCombine dependency fails?**

If either of the two futures passed to `thenCombine` completes
exceptionally, the combined future also completes exceptionally with
that exception. The BiFunction is NOT called.

```java
CompletableFuture<User>  uf =
    supplyAsync(() -> { throw new RuntimeException("user svc down"); });
CompletableFuture<Order> of = supplyAsync(() -> getOrder(id));

uf.thenCombine(of, (u, o) -> build(u, o))
  .exceptionally(ex -> {
      // ex = CompletionException wrapping RuntimeException
      // BiFunction was never called
      return errorResponse(ex.getCause());
  });
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

If both fail simultaneously, whichever exception is stored in the
combined future is implementation-dependent. The first completed-
exceptionally future wins.

*What separates good from great:* Noting that `of` (the order future)
continues running even after `uf` fails - there is no automatic
cancellation of the other future. This is a resource waste if the
combined result is no longer needed. Structured Concurrency (Java 21+)
solves this: `ShutdownOnFailure` cancels all sibling tasks when one fails.

---

**[MID] Q4 - [TRADE-OFF] How does thenCompose compare to nested supplyAsync calls?**

Nested `supplyAsync` calls create independent futures that are not
sequenced. `thenCompose` creates a sequential chain where the second
async call only starts after the first completes.

```java
// WRONG: parallel, not sequential - orderId undefined
CompletableFuture<User>  uf = supplyAsync(() -> getUser(id));
CompletableFuture<Order> of =
    supplyAsync(() -> getOrder(???)); // user not available yet

// CORRECT: sequential dependency via thenCompose
CompletableFuture<Order> of =
    supplyAsync(() -> getUser(id))
    .thenCompose(user ->
        supplyAsync(() -> getOrder(user.getOrderId())));
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

Use thenCompose when the second async call DEPENDS on the result of the
first. Use `thenCombine` or parallel `supplyAsync` when both calls are
INDEPENDENT and can run simultaneously.

*What separates good from great:* Recognizing that thenCompose is
inherently sequential: it cannot start the second async operation until
the first completes. If independence is possible, thenCombine always
gives lower latency because both run simultaneously.

---

**[MID] Q5 - [CONCEPTUAL] What is runAfterBoth and when would you use it?**

`runAfterBoth(CF<?>, Runnable)`: fires a Runnable when both the current
future and the provided future complete, using neither result. Returns
`CompletableFuture<Void>`.

Use case: triggering a side effect that requires confirmation of two
independent operations, without needing either result.

```java
// After both cache invalidations complete, log audit event
cacheInvalidateFuture
    .runAfterBoth(dbUpdateFuture,
        () -> auditLog.record("cache+db updated"));
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using SQL. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Alternatives in the family:
- `thenAcceptBoth(CF<U>, BiConsumer<T,U>)`: receives both results but
  returns void (side effect)
- `thenCombine(CF<U>, BiFunction<T,U,V>)`: receives both results,
  returns a new value

The pattern: thenCombine returns a value, thenAcceptBoth consumes both
values, runAfterBoth ignores both values.

*What separates good from great:* Knowing `runAfterEither` and
`acceptEither`: fire when FIRST of two completes. Useful for fallback
patterns: send the same request to primary and replica, use whoever
responds first.

---

**[MID] Q6 - [CONCEPTUAL] How do you convert a blocking call into a CompletableFuture chain?**

Three approaches, from simplest to most correct:

1. Wrap in supplyAsync with I/O pool (simple, still blocks pool thread):
```java
CompletableFuture<User> cf =
    CompletableFuture.supplyAsync(
        () -> jdbc.findUser(id), ioPool);
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

2. Bridge from callback-based API (no thread blocking):
```java
CompletableFuture<String> cf = new CompletableFuture<>();
asyncHttpClient.execute(request,
    response -> cf.complete(response.body()),
    error    -> cf.completeExceptionally(error));
return cf;
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

3. Reactive to CompletableFuture (from Project Reactor):
```java
// Reactor Mono to CompletableFuture
CompletableFuture<User> cf =
    reactorMono.toFuture();
```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

The best approach depends on the underlying API. For JDBC (inherently
blocking), option 1 is the pragmatic choice with a properly sized pool.
For async HTTP clients (Netty-based), option 2 eliminates thread blocking.
For reactive libraries, option 3 provides interop.

*What separates good from great:* Understanding that option 1 is not
truly non-blocking - it moves blocking to the pool. The pool becomes
the throughput ceiling. Option 2 with an NIO-based HTTP client is
genuinely non-blocking. The choice depends on whether the downstream
API provides a callback or completion-notification mechanism.

---

**[SENIOR] Q7 - [CONCEPTUAL] What is the practical difference in latency between sequential thenCompose and parallel thenCombine?**

Sequential thenCompose: total latency = latency_A + latency_B.
The second operation starts only after the first completes.

Parallel thenCombine: total latency = max(latency_A, latency_B).
Both operations start immediately and the combination fires when both done.

Example with service call latencies:
```
thenCompose (sequential):
  getUser (30ms) -> getOrders (50ms) = 80ms total

thenCombine (parallel):
  getUser (30ms) \
                  -> combine at 50ms = 50ms total
  getPrefs (50ms)/
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

The latency saving is the latency of the shorter operation.

When sequential is necessary: when operation B needs the result of A.
When parallel is possible: when A and B are independent.

Production implication: microservice fan-out with thenCompose instead
of thenCombine adds 10-30ms per sequential-but-independent call. In a
service making 5 downstream calls, the difference between all-sequential
and all-parallel can be 100-150ms per request.

*What separates good from great:* Knowing that parallel fan-out has a
resource cost: all downstream services are called simultaneously, which
can spike their load. In systems with tight downstream capacity, staggered
calls (sequential) can be a deliberate backpressure technique.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational entry. Full comparison at L2+.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ entry. System design at L4/L5.)*

---

### 📊 Diagram

*(Omit: The ASCII operator diagrams in Concept Explanation illustrate
the three patterns clearly without additional diagrams.)*

---
---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


# Future and Callable Interface

---
id: AJA-006
title: Future and Callable Interface
category: Async Java
difficulty: ★☆☆
interview_weight: medium
asked_at: All
seniority: junior
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Callable is like Runnable but it can return a result and throw checked
> exceptions. Future represents the result of an async computation that
> hasn't completed yet - you can check if it's done with isDone(), cancel
> it with cancel(), or block for the result with get(). Together they are
> the Java 5 foundation for result-bearing tasks submitted to a thread pool.
> CompletableFuture superseded this pattern in Java 8.

**3 minutes:**
> Before Java 8, Callable and Future were the standard way to run
> result-bearing tasks asynchronously. You submit a Callable to an
> ExecutorService, which returns a Future<T>. The Callable runs on a pool
> thread; the Future lets the calling thread retrieve the result later.
>
> Future.get() is the critical design flaw: it blocks the calling thread
> until the result is ready, or until a timeout occurs if you use
> get(timeout, unit). There is no way to register a callback ("when this
> completes, run this function") without blocking.
>
> Callable is the upgrade over Runnable: Runnable.run() returns void and
> cannot throw checked exceptions. Callable.call() returns a typed result
> and can throw checked exceptions, which are wrapped in an
> ExecutionException when retrieved via Future.get().
>
> In modern Java code, Callable and Future are primarily encountered when:
> (1) working with legacy code, (2) using ScheduledExecutorService for
> scheduled tasks that return results, or (3) working with ForkJoinTask
> internals. New code should use CompletableFuture for async tasks or
> Virtual Threads for blocking tasks.

**Blank Mind Recovery:**

**(1) Restate:** "So you are asking about Callable and Future - let me
think through what they do and why they exist."

**(2) First principles:** "We need to submit work to a thread pool and
get a result back. Runnable has no return type. We need a typed,
exception-aware version - that is Callable. Future holds the not-yet-
available result."

**(3) Bridge:** "Future is Java 5's equivalent of a placeholder for a
value that will arrive later. CompletableFuture improved on it in Java 8
by adding non-blocking callbacks."

---

### 📘 Concept Explanation

**What it is:**
`Callable<V>` is a single-method interface (call() -> V) that can return
a typed result and throw checked exceptions. `Future<V>` represents the
pending result of an async computation submitted to an ExecutorService,
providing `get()`, `isDone()`, `cancel()`, and `isCancelled()`.

**The problem it solves:**
`Runnable` (Java 1) returned void and could not throw checked exceptions.
For any task that needed to produce a result or propagate errors back to
the submitter, raw thread coordination was needed. Callable and Future
provided a clean typed API for result-bearing async tasks.

**How it works:**

```plaintext
Callable<T>:
  V call() throws Exception;
  (Returns V; throws checked exceptions)

ExecutorService.submit(Callable<T>):
  Schedules Callable on pool thread.
  Returns Future<T> immediately.

Future<T>:
  T    get()                   // blocks until done
  T    get(timeout, unit)      // blocks with timeout
  bool isDone()                // true if completed/cancelled/failed
  bool cancel(interrupt)       // attempt cancellation
  bool isCancelled()
```

> **Code walkthrough:** This Future and Callable Interface example demonstrates a key concept in practice using thread pool. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

Exceptions from Callable.call() are caught by the executor and stored
in the Future. `future.get()` re-throws them wrapped in
`ExecutionException`. Access the original via `ex.getCause()`.

**The key insight:**
`Future.get()` is inherently blocking - there is no notification mechanism.
This is the fundamental limitation that CompletableFuture (Java 8) solved
by adding completion callbacks. In high-concurrency services, calling
`get()` blocks a thread for every pending result - negating the benefit
of the thread pool for the calling code.

**When to use it:**
- ScheduledExecutorService for scheduled result-bearing tasks
- Legacy codebases that predate CompletableFuture
- Simple fire-and-check patterns where polling isDone() is acceptable

**When NOT to use it:**
- High-concurrency services: use CompletableFuture or Virtual Threads
- Whenever you need non-blocking callbacks or composition

**Alternatives:**
- CompletableFuture - composable, non-blocking (Java 8+)
- ForkJoinTask/RecursiveTask - for divide-and-conquer parallelism
- Virtual Threads (Java 21+) - for sync-style blocking tasks

**First-principles derivation:**
Thread pools decouple "who submits work" from "who runs it." To return
a result from a pool thread to the submitter, a typed container is needed
that can be filled later. This is Future<T>. Callable provides the typed,
exception-aware task interface to fill it.

---

### 💻 Code Example

**Basic Callable + Future usage and its limitations:**

```java
ExecutorService pool = Executors.newFixedThreadPool(4);

// 1. Submit Callable, get Future
Callable<User> task = () -> {
    // Can return value and throw checked exceptions
    return userRepository.findById(userId);
};
Future<User> future = pool.submit(task);

// 2. Non-blocking check (polling)
while (!future.isDone()) {
    // Do other work...
    Thread.sleep(10); // bad pattern - busy waiting
}
User user = future.get(); // no longer blocks - already done

// 3. Blocking get with timeout (safer)
try {
    User user2 = future.get(5, TimeUnit.SECONDS);
} catch (TimeoutException e) {
    future.cancel(true); // attempt interrupt
    handleTimeout();
} catch (ExecutionException e) {
    // Unwrap: e.getCause() is the original exception
    Throwable cause = e.getCause();
    handleError(cause);
} catch (InterruptedException e) {
    Thread.currentThread().interrupt(); // restore flag
    handleInterrupt();
}

// 4. Limitation: no composition
// To run A and B in parallel and combine:
Future<String> fa = pool.submit(() -> callA());
Future<String> fb = pool.submit(() -> callB());
String a = fa.get(); // BLOCKS calling thread
String b = fb.get(); // BLOCKS again
combine(a, b);       // forced sequential blocking
// CompletableFuture.thenCombine() solves this elegantly
```

> **Code walkthrough:** Example 1 shows the basic pattern: Callable isice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> a lambda that returns a value (and can throw). `pool.submit(callable)`
> schedules it and returns a Future immediately. Example 2 shows naive
> polling - generally avoid this; it wastes CPU time. Example 3 is the
> production pattern: `get(timeout, unit)` with explicit handling for
> TimeoutException, ExecutionException (wraps task exceptions), and
> InterruptedException. Critically, interruption must restore the
> interrupted flag with `Thread.currentThread().interrupt()`. Example 4
> demonstrates the fundamental limitation: parallel fan-out with Future
> requires sequential blocking calls to get() - this is exactly what
> CompletableFuture.thenCombine() solved.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Callable is like Runnable but it returns a typed result and can throw
> checked exceptions. When I submit a Callable to an ExecutorService, I
> get back a Future that I can use to retrieve the result later with
> get(). The main limitation is that get() blocks my thread. That is why
> CompletableFuture was introduced in Java 8 - it lets me register
> callbacks instead of blocking.

*Push deeper:* Explain what ExecutionException is and how to access
the original exception.

---

**Senior / Staff:**
> Callable and Future are the Java 5 async primitives. The critical
> limitation is Future.get() blocking - there is no way to compose
> futures or register callbacks without blocking. This led to
> CompletableFuture in Java 8.
>
> In production today I encounter Future mainly in three contexts:
> ScheduledExecutorService for periodic tasks, ForkJoinTask internals for
> parallel divide-and-conquer, and legacy code that I'm refactoring. When
> I refactor, I convert Future<T> to CompletableFuture<T> using
> CompletableFuture.supplyAsync() or by bridging via complete().
>
> The one gotcha with Future.cancel(true): it passes the interrupt flag
> to the running thread, but the thread must check Thread.interrupted()
> to honour it. A task that does not check interruption cannot be
> cancelled via Future.cancel() - it will run to completion regardless.

*Push deeper (Staff):* ScheduledFuture (from ScheduledExecutorService)
extends Future with getDelay(). The scheduled tasks run with fixed-rate
or fixed-delay semantics. Fixed-rate: fire every N seconds regardless of
task duration (can overlap). Fixed-delay: wait N seconds after the
previous completion. Getting these wrong causes either missed tasks or
pile-up under slow execution.

---

### ⚠️ Common Misconceptions

**Misconception: "Future.cancel() stops the running task."**

`Future.cancel(true)` sets the interrupt flag on the thread running the
task. But it only REQUESTS interruption - it does not forcibly stop the
thread. The task must periodically check `Thread.interrupted()` or call
interruptible methods (Thread.sleep, BlockingQueue.take, etc.) to actually
stop. A task running a tight loop without I/O or sleep calls cannot be
interrupted via cancel(). This is a common production bug when trying to
implement timeouts using cancel().

---

### 🚨 Failure Modes and Diagnosis

**Failure: ExecutionException masks the real exception**

Symptom: `future.get()` throws ExecutionException with message "null"
or a generic wrapper. The actual root cause is buried.

Cause: the Callable threw a checked or unchecked exception. The executor
wrapped it in ExecutionException. Code logs or handles the ExecutionException
without unwrapping.

Diagnosis:
```java
try {
    result = future.get();
} catch (ExecutionException e) {
    // WRONG: logs the wrapper
    log.error("Task failed: " + e.getMessage());

    // CORRECT: unwrap to root cause
    Throwable cause = e.getCause();
    log.error("Task failed due to: " + cause.getMessage(), cause);
    // Now you can see the actual exception and stack trace
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

Fix: always unwrap ExecutionException with `getCause()` before logging
or handling. Consider a utility method:
```java
public static <T> T getResult(Future<T> f) {
    try {
        return f.get();
    } catch (ExecutionException e) {
        Throwable cause = e.getCause();
        if (cause instanceof RuntimeException re) throw re;
        throw new RuntimeException("Async task failed", cause);
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
        throw new RuntimeException("Interrupted", e);
    }
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions minimum.

---

**[JUNIOR] Q1 - [CONCEPTUAL] What is Callable and how does it differ from Runnable?**

`Runnable`: single method `void run()`. Returns nothing. Cannot throw
checked exceptions. Used for fire-and-forget tasks.

`Callable<V>`: single method `V call() throws Exception`. Returns a
typed value V. Can throw any checked Exception. Used for result-bearing
tasks where success/failure must be communicated back.

```java
// Runnable: no result, no checked exceptions
Runnable r = () -> updateCache(key, value); // void

// Callable: typed result + exceptions
Callable<User> c = () -> userRepo.findById(id); // returns User
```

> **Code walkthrough:** This Unknown example demonstrates Java API usage using SQL. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

Functional interface: both are functional interfaces, so lambdas work
for both. Callable is preferred when the task needs to return a result
or propagate checked exceptions (like IOException, SQLException).

*What separates good from great:* Knowing that Executor.execute(Runnable)
does not return a Future. Only ExecutorService.submit(Callable) and
ExecutorService.submit(Runnable) return Future. submit(Runnable) returns
`Future<?>` where `get()` returns null - only useful for waiting for
completion, not retrieving a result.

---

**[JUNIOR] Q2 - [CONCEPTUAL] How does ExecutorService.submit() differ from execute()?**

`execute(Runnable)`: from the Executor interface (parent of
ExecutorService). Schedules the task for execution, returns void. Any
exception from the task propagates to the UncaughtExceptionHandler of
the pool thread - not to the caller.

`submit(Callable<T>)` or `submit(Runnable)`: from ExecutorService.
Returns Future<T> (or Future<?> for Runnable). Exceptions are caught
by the framework and stored in the Future. The caller retrieves them
via `future.get()` which throws ExecutionException.

Use execute(): for fire-and-forget tasks where completion or errors are
monitored via other means (logging, metrics).
Use submit(): for tasks where the caller needs the result or must handle
task-specific errors.

*What separates good from great:* Understanding that exceptions from
tasks submitted via execute() go to the thread's UncaughtExceptionHandler.
Many teams have an unhandled exception handler that logs or alerts. If
execute() is used for tasks that throw, those exceptions reach the
handler. If submit() is used but Future.get() is never called, exceptions
are silently swallowed - the same silent-exception problem as
CompletableFuture without handlers.

---

**[JUNIOR] Q3 - [CONCEPTUAL] What happens when a Callable throws an exception?**

When `Callable.call()` throws an exception (checked or unchecked), the
executor catches it and stores it in the resulting Future.

`future.get()` then throws `ExecutionException` wrapping the original.
The original exception is accessible via `e.getCause()`.

If `future.get()` is never called, the exception is permanently lost.

```java
Future<Integer> f = pool.submit(() -> {
    throw new SQLException("connection failed");
});

// If f.get() is never called: exception silently discarded

// If f.get() is called:
try {
    f.get();
} catch (ExecutionException e) {
    Throwable cause = e.getCause(); // the actual SQLException
    System.out.println(cause.getClass()); // java.sql.SQLException
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

Special case: `InterruptedException` from `get()` means the waiting
thread was interrupted, not the task. Always restore the interrupt flag:
`Thread.currentThread().interrupt()`.

*What separates good from great:* Noting that `future.get()` can throw
three exception types: `ExecutionException` (task failed), `InterruptedException`
(waiting thread interrupted), `CancellationException` (future was
cancelled). Each requires different handling - mixing them up (catching
only Exception) masks distinct failure modes.

---

**[MID] Q4 - [HANDS-ON] How do you implement a timeout with Future?**

`future.get(long timeout, TimeUnit unit)`: waits at most the specified
duration. If the future does not complete in time, throws `TimeoutException`.

```java
Future<Response> f = pool.submit(() -> callSlowService());
try {
    Response r = f.get(3, TimeUnit.SECONDS);
    return r;
} catch (TimeoutException e) {
    // Timed out - cancel the task (best effort)
    f.cancel(true); // sends interrupt to pool thread
    log.warn("Service call timed out after 3s");
    return fallbackResponse();
} catch (ExecutionException e) {
    log.error("Task failed", e.getCause());
    return errorResponse();
} catch (InterruptedException e) {
    Thread.currentThread().interrupt();
    return errorResponse();
}
```

> **Code walkthrough:** This Unknown example demonstrates exception handling using error handling. **KEY MECHANISM:** the JVM checks catch clauses in order; finally always executes for cleanup. **WHY IT MATTERS:** swallowing exceptions silently hides failures that corrupt downstream state. **TAKEAWAY: log or rethrow every exception; empty catch blocks are defects.**

Key: `f.cancel(true)` after timeout is best-effort. The pool thread
running the task only stops if it checks `Thread.interrupted()`. For
network calls, the blocking socket read is interruptible - the thread
will be interrupted when cancel(true) is called.

Limitation: even with a 3-second timeout, the pool thread may continue
running until the socket read times out (configured separately at the
HTTP client level). cancel() sets the flag but does not forcibly kill
threads.

*What separates good from great:* Knowing that for reliable timeouts,
configure the timeout at the I/O library level (HttpURLConnection.setReadTimeout(),
OkHttp timeout, etc.) in addition to Future.get() timeout. Future
timeout controls how long the CALLER waits; I/O timeout controls how
long the task's socket waits.

---

**[MID] Q5 - [CONCEPTUAL] How do you collect results from multiple parallel Futures?**

Pattern: submit all tasks, collect futures, then iterate to get results.

```java
List<Callable<String>> tasks = List.of(
    () -> callService("a"),
    () -> callService("b"),
    () -> callService("c")
);

// Submit all - they run in parallel
List<Future<String>> futures =
    pool.invokeAll(tasks); // blocks until ALL complete (!)

// OR: submit individually for more control
List<Future<String>> futures2 = tasks.stream()
    .map(pool::submit)
    .toList();

// Collect results - get() called after submission
List<String> results = futures2.stream()
    .map(f -> {
        try { return f.get(); }
        catch (ExecutionException | InterruptedException e) {
            throw new RuntimeException(e);
        }
    })
    .toList();
```

> **Code walkthrough:** This Unknown example demonstrates Java Stream pipeline using Stream. **KEY MECHANISM:** the stream is lazy - intermediate ops build a pipeline, terminal op drives it. **WHY IT MATTERS:** calling terminal op twice throws IllegalStateException; parallel() on small data adds overhead. **TAKEAWAY: collect() or findFirst() triggers the pipeline; reuse by wrapping in Supplier.**

`invokeAll()`: blocks the calling thread until ALL submitted tasks
complete (or time out). Convenient but removes the ability to do other
work while tasks run.

Alternative `invokeAny()`: blocks until ONE task completes successfully,
cancels the rest. Useful for redundant calls.

Limitation: no way to process results as they arrive. CompletableFuture
with allOf allows callback-based collection without blocking.

*What separates good from great:* Knowing that `invokeAll` with a timeout
(`invokeAll(tasks, timeout, unit)`) cancels tasks that don't complete
in time but does NOT throw TimeoutException - it returns futures for all
tasks, some of which may be cancelled. Always check `future.isCancelled()`
when using timed invokeAll.

---

**[MID] Q6 - [CONCEPTUAL] When would you still use Future over CompletableFuture?**

Three scenarios where Future remains relevant:

1. ScheduledExecutorService: `ScheduledFuture<V>` is returned by
   `schedule(callable, delay, unit)`. It extends Future with `getDelay()`.
   No direct CompletableFuture equivalent for scheduled tasks.

2. ForkJoinTask: `RecursiveTask<V>.compute()` returns a result via the
   ForkJoinTask/Future interface. Internal to the fork-join framework.

3. Legacy API contracts: code that returns Future<T> and cannot be
   changed. You can bridge to CompletableFuture:
   ```java
   public static <T> CompletableFuture<T> toCompletable(
           Future<T> future, Executor executor) {
       return CompletableFuture.supplyAsync(() -> {
           try { return future.get(); }
           catch (ExecutionException e) {
               throw new CompletionException(e.getCause());
           } catch (InterruptedException e) {
               Thread.currentThread().interrupt();
               throw new CompletionException(e);
           }
       }, executor);
   }
   ```

> **Code walkthrough:** This Unknown example demonstrates async pipeline construction using CompletableFuture. **KEY MECHANISM:** the JVM schedules continuations via ForkJoinPool when each stage completes. **WHY IT MATTERS:** callback chains execute on wrong threads causing ClassCastException in Spring context. **TAKEAWAY: always specify executor on thenApplyAsync to control thread context.**

*What separates good from great:* The bridge pattern above - knowing
how to convert a blocking Future to a CompletableFuture without losing
exception semantics. The trick is using supplyAsync with an executor so
the blocking get() runs on a pool thread, not the calling thread.

---

**[SENIOR] Q7 - [CONCEPTUAL] What is the significance of interruption with Future and Callable?**

Interruption is a cooperative signaling mechanism in Java: one thread
sets the interrupt flag on another, which is expected to notice and
respond by stopping its current blocking operation.

In the context of Future/Callable:

1. `Future.cancel(true)`: sends an interrupt to the thread running the
   Callable. Effective only if the task checks `Thread.interrupted()` or
   is blocked in an interruptible method (Thread.sleep, BlockingQueue.take,
   socket I/O with interruptible channels).

2. Task implementation must restore the interrupt flag:
   ```java
   Callable<String> task = () -> {
       while (!Thread.interrupted()) { // check interrupt
           // do work
       }
       return partialResult; // respond to cancel
   };
   ```

> **Code walkthrough:** This Unknown example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

3. `future.get()` throws `InterruptedException` if the WAITING thread
   (not the task thread) is interrupted. This is often confused with task
   cancellation. When `get()` throws `InterruptedException`:
   - The task is still running
   - The waiting thread's interrupt flag has been cleared
   - Must be restored: `Thread.currentThread().interrupt()`

Rule: always restore the interrupt flag when catching InterruptedException.
Swallowing it silently prevents outer code from knowing the thread was
interrupted, breaking cooperative shutdown mechanisms.

*What separates good from great:* Distinguishing the three thread actors:
(1) the thread running the task (in the pool), (2) the thread waiting
on `get()` (the caller), (3) any thread calling `cancel()`. They are
three distinct threads. InterruptedException from `get()` is about thread
(2), not thread (1). This distinction is routinely confused in production
code and interviews.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational entry. Full comparison at L2+.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ entry. System design at L4/L5.)*

---

### 📊 Diagram

*(Omit: The linear executor/future flow is expressed in the code examples.)*

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*



