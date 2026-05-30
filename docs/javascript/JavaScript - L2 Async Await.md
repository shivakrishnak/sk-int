---
layout: default
title: "JavaScript - L2 Async Await"
parent: "JavaScript"
nav_order: 6
permalink: /javascript/l2-async-await/
render_with_liquid: false
---

# Async/Await Syntax and Error Handling

🎯 **Interview Weight:** working (★★☆) - async/await is the primary
async syntax since ES2017; every JavaScript interview covers it

---

### 🎯 Model Answer

**30 seconds:**

> `async` functions always return a Promise. `await` pauses execution
> of the async function until the awaited Promise settles - without
> blocking the JavaScript thread. Error handling uses standard
> `try/catch`. Under the hood, async/await is syntax sugar over Promises;
> the same rules about Promise chaining and microtasks apply.

**3 minutes:**

> `async function f() {}` always returns a Promise. Even
> `return 42` inside an async function produces a Promise that
> resolves with `42`.
>
> `await expr` unwraps the Promise: if `expr` resolves, `await` returns
> the value; if `expr` rejects, `await` throws. Non-Promise values
> are passed through as-is.
>
> Error handling: `try/catch` around `await` catches both synchronous
> errors and Promise rejections. You can also use `.catch()` on the
> async function's return value.
>
> Common pitfalls: `await` inside `forEach` doesn't work as expected
> (forEach doesn't wait for async callbacks). Use `for...of` for
> sequential async iteration. For parallel: `Promise.all` with `await`.

**Blank Mind Recovery:**

**(1) Restate:** "async function returns Promise. await pauses until
Promise settles. try/catch catches rejections."

---

### 📘 Concept Explanation

**What it is:**

`async`/`await` is syntactic sugar over Promises, introduced in ES2017
(ES8). It makes asynchronous code read like synchronous code, improving
readability and error handling without sacrificing the non-blocking
nature of JavaScript.

**How it works:**

```
ASYNC FUNCTION:

  async function greet() {
    return 'hello';       // wraps in Promise.resolve('hello')
  }
  greet();                // Promise { 'hello' }
  greet().then(console.log); // 'hello'

  // Equivalent:
  function greet() {
    return Promise.resolve('hello');
  }

AWAIT:
  async function fetchData() {
    const response = await fetch('/api/data');
    // Pauses HERE until fetch Promise resolves
    // Thread is NOT blocked - other code can run
    const data = await response.json();
    return data;
  }

  // await only usable inside async function (or top-level modules)
  // Outside async context, call .then():
  fetchData().then(data => console.log(data));

ERROR HANDLING:
  // With try/catch (recommended):
  async function loadUser(id) {
    try {
      const response = await fetch(`/api/users/${id}`);
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      return await response.json();
    } catch (err) {
      // Catches: network errors, non-ok status, JSON parse errors
      console.error('loadUser failed:', err.message);
      throw err;  // re-throw to let caller decide
    }
  }

  // Alternative: .catch on call site
  const user = await loadUser(id).catch(err => {
    logger.error(err);
    return null;  // fallback
  });

AWAIT INSIDE LOOPS:

  // WRONG: forEach does NOT await
  const ids = [1, 2, 3];
  ids.forEach(async (id) => {
    const user = await fetchUser(id);  // runs concurrently
    console.log(user);                 // unordered output
  });
  // forEach fires all async functions at once but doesn't await them

  // SEQUENTIAL: for...of
  for (const id of ids) {
    const user = await fetchUser(id); // waits for each
    console.log(user);
  }
  // Total time: sum of each fetch

  // PARALLEL: Promise.all
  const users = await Promise.all(ids.map(id => fetchUser(id)));
  // Total time: max of each fetch

TOP-LEVEL AWAIT (ES2022, modules only):
  // In a module:
  const config = await fetchConfig();  // top-level await
  export const API_KEY = config.apiKey;
  // Blocks module evaluation until config is loaded
```

---

### 💻 Code Example

**Correct patterns for async/await**

```javascript
// BAD: sequential awaits for independent operations
async function loadDashboard(userId) {
  const user      = await fetchUser(userId);   // wait
  const posts     = await fetchPosts(userId);  // wait
  const followers = await fetchFollowers(userId); // wait
  // Total time: fetchUser + fetchPosts + fetchFollowers (sum)
}

// GOOD: parallel for independent operations
async function loadDashboard(userId) {
  const [user, posts, followers] = await Promise.all([
    fetchUser(userId),
    fetchPosts(userId),
    fetchFollowers(userId)
  ]);
  // Total time: max(fetchUser, fetchPosts, fetchFollowers)
}

// BAD: swallowing errors silently
async function getUser(id) {
  try {
    return await fetchUser(id);
  } catch (err) {
    // BAD: silently returns undefined
  }
}

// GOOD: explicit error handling
async function getUser(id) {
  try {
    const response = await fetch(`/api/users/${id}`);
    if (!response.ok) {
      throw new Error(
        `HTTP ${response.status}: ${response.statusText}`
      );
    }
    return await response.json();
  } catch (err) {
    logger.error('getUser failed:', { id, error: err.message });
    throw err;  // re-throw: let caller decide fallback
  }
}

// PATTERN: await with fallback
const user = await getUser(id).catch(() => null);
if (!user) return renderNotFound();

// PATTERN: sequential with early exit
async function processOrder(orderId) {
  const order = await getOrder(orderId);
  if (order.status === 'cancelled') {
    return { success: false, reason: 'cancelled' };
  }
  const payment = await processPayment(order.total);
  const confirmation = await sendConfirmation(order, payment);
  return { success: true, confirmation };
}

// PATTERN: retry with async/await
async function withRetry(fn, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      if (attempt === maxRetries) throw err;
      const delay = 2 ** attempt * 100; // exponential backoff
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
const data = await withRetry(() => fetchFromAPI('/data'));
```

> **Code walkthrough:** The sequential vs parallel pattern is the most
> important performance optimization in async code. If `fetchUser`,
> `fetchPosts`, and `fetchFollowers` each take 100ms, sequential takes
> 300ms while `Promise.all` takes ~100ms (the slowest). The silent
> error swallow is dangerous in production: the function returns
> `undefined` without logging, making debugging impossible. The explicit
> pattern logs the error with context (id, error message) and re-throws
> so the caller can decide whether to use a fallback, show an error
> UI, or propagate further. The retry pattern uses exponential backoff
> (100ms, 200ms, 400ms delays) - this is the standard approach for
> transient network errors in production systems.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `async` function returns Promise. `await` unwraps the value from a
> Promise. `try/catch` catches rejections from `await`. Don't use
> `forEach` with async callbacks - use `for...of` for sequential,
> `Promise.all` for parallel.

---

**Senior / Staff:**

> async/await is semantically equivalent to Promise chains: `await`
> desugars to `.then()`. For parallel operations: `Promise.all` with
> `await`. Error handling with `try/catch` is cleaner than chained
> `.catch` for complex flows. Production patterns: retry with backoff,
> circuit breakers, timeout wrapping (all implemented cleanly with
> async/await). Watch for unhandled rejections - always add `.catch()`
> or try/catch at the outermost async call.

---

### ⚠️ Common Misconceptions

**"await blocks the main thread"**

`await` suspends the CURRENT async function, but does NOT block the
JavaScript event loop. Other code (other promises, event handlers,
timers) can execute while an async function is awaiting. JavaScript
is still single-threaded - `await` simply yields execution until
the awaited Promise settles, then resumes. It is syntactic sugar
over `.then()`, not a blocking call.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: async function in forEach not awaiting correctly**

```javascript
// SYMPTOM: processing appears to complete before async work
async function processAll(items) {
  let count = 0;
  items.forEach(async (item) => {
    await processItem(item);  // awaits inside callback
    count++;                  // but forEach doesn't wait
  });
  console.log(`Processed ${count} items`);
  // Prints: "Processed 0 items" (all async, not waited)
}

// DIAGNOSIS: forEach fires all async callbacks immediately,
// returns without waiting for any of them to resolve

// FIX 1: sequential with for...of
async function processAll(items) {
  let count = 0;
  for (const item of items) {
    await processItem(item);
    count++;
  }
  console.log(`Processed ${count} items`);  // correct
}

// FIX 2: parallel with Promise.all
async function processAll(items) {
  await Promise.all(items.map(item => processItem(item)));
  console.log(`Processed ${items.length} items`);
}
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| async function return type | 2 min | Always Promise |
| await vs blocking | 2-3 min | Non-blocking |
| Error handling try/catch | 3 min | Catches rejections |
| forEach with async callbacks | 3-4 min | Classic bug |
| Sequential vs parallel await | 3-4 min | Performance |
| Top-level await | 2-3 min | ES2022 modules |
| Retry pattern implementation | 4-5 min | Production code |

---

**Q1: Why doesn't `await` work correctly inside `forEach`?**
`[MID]` DEBUGGING

> **Answer:**
>
> `forEach` calls the provided callback for each element, but it does
> NOT await the callback's return value. Even if the callback is `async`
> (returns a Promise), `forEach` ignores the returned Promise and
> immediately moves to the next element.
>
> ```javascript
> const results = [];
>
> // BROKEN: forEach doesn't await
> [1, 2, 3].forEach(async (num) => {
>   const result = await asyncDouble(num);
>   results.push(result);
> });
> console.log(results.length);  // 0 (not yet resolved!)
>
> // CORRECT: for...of (sequential)
> for (const num of [1, 2, 3]) {
>   const result = await asyncDouble(num);
>   results.push(result);
> }
> console.log(results.length);  // 3
>
> // CORRECT: Promise.all (parallel)
> const results = await Promise.all(
>   [1, 2, 3].map(num => asyncDouble(num))
> );
> console.log(results.length);  // 3
> ```
>
> The `forEach` source pseudocode shows why:
> ```javascript
> Array.prototype.forEach = function(callback) {
>   for (let i = 0; i < this.length; i++) {
>     callback(this[i], i, this); // returns Promise, IGNORED
>   }
>   // Returns undefined, doesn't await anything
> };
> ```
>
> *What separates good from great:* This behavior extends to other
> Array methods: `filter`, `reduce`, `map` all ignore returned Promises.
> They're designed for synchronous callbacks. The exception is `map`:
> `array.map(async fn)` returns an array of Promises (which can then
> be passed to `Promise.all`). This is why `Promise.all(array.map(async fn))`
> works correctly for parallel processing - `map` gives you the Promises
> and `Promise.all` waits for all of them.

---

---

# Concurrency Patterns

🎯 **Interview Weight:** working (★★☆) - Promise.all, race, and
allSettled patterns appear in senior interviews; required for
efficient async JavaScript

---

### 🎯 Model Answer

**30 seconds:**

> JavaScript is single-threaded but achieves concurrency through
> non-blocking I/O. `Promise.all` runs independent async operations
> in parallel and fails fast on first rejection. `Promise.allSettled`
> waits for ALL and never fails fast. `Promise.race` returns the first
> to settle. `Promise.any` returns the first to fulfill. Choose based
> on whether you need all results, any result, or tolerance for partial
> failure.

**3 minutes:**

> Key patterns and when to use them:
>
> - `Promise.all([p1, p2])`: Use when ALL must succeed. Fails fast if
>   any rejects. Best for: loading multiple resources that are all required.
>
> - `Promise.allSettled([p1, p2])`: Use when you want ALL results even
>   if some fail. Returns status + value/reason for each. Best for:
>   batch operations, resilient loading where partial success is acceptable.
>
> - `Promise.race([p1, p2])`: Settles with the FIRST to settle (either
>   fulfill OR reject). Best for: timeout patterns.
>
> - `Promise.any([p1, p2])`: Fulfills with FIRST to fulfill; rejects
>   only if ALL reject. Best for: redundant requests to multiple servers.
>
> Common pattern: wrap sequential bottlenecks with `Promise.all` to
> run independent operations concurrently.

**Blank Mind Recovery:**

**(1) Restate:** "all: wait for all, fail fast. allSettled: wait for all,
never fail fast. race: first to settle. any: first to fulfill."

---

### 📘 Concept Explanation

**What it is:**

Concurrency patterns in JavaScript are techniques for managing multiple
async operations simultaneously. Unlike true parallelism (multiple CPU
threads), JavaScript achieves concurrency through the event loop:
initiating multiple async operations before any has completed, allowing
the runtime to process all their responses as they arrive.

**How it works:**

```
CONCURRENCY MODELS:

  Sequential (one at a time):
    const a = await fetchA();  // starts, waits
    const b = await fetchB();  // starts AFTER a completes
    // Time: duration(A) + duration(B)

  Concurrent (start all, wait for all):
    const [a, b] = await Promise.all([fetchA(), fetchB()]);
    // fetchA and fetchB START at the same time
    // Time: max(duration(A), duration(B))

  NOTE: JavaScript is still single-threaded
  Both approaches run JS on ONE thread
  "Concurrency" = interleaved I/O, not parallel CPU execution

PROMISE.ALL:
  Promise.all(promises):
  - Accepts: array of Promises (or any iterable)
  - Returns: single Promise
    - Fulfills: when ALL fulfill, with array of results
    - Rejects: when FIRST rejects, with that rejection reason
  - Pending promises are NOT cancelled when one rejects
    (they continue but results are discarded)

  const [user, posts] = await Promise.all([
    fetchUser(id),   // runs immediately
    fetchPosts(id)   // runs immediately, in parallel
  ]);
  // Results in original order regardless of completion order

PROMISE.ALLSETTLED:
  Promise.allSettled(promises):
  - Returns: Promise<Array<{status, value|reason}>>
  - NEVER rejects
  - Waits for ALL promises to settle

  const results = await Promise.allSettled([
    fetchUser(1),
    fetchUser(2),
    fetchUser(3)
  ]);
  // [
  //   { status: 'fulfilled', value: user1 },
  //   { status: 'rejected',  reason: Error('not found') },
  //   { status: 'fulfilled', value: user3 }
  // ]

PROMISE.RACE:
  Promise.race(promises):
  - Settles with the FIRST promise to settle (either way)
  - Useful for timeout patterns

  const TIMEOUT = new Promise((_, reject) =>
    setTimeout(() => reject(new Error('timeout')), 5000)
  );
  const result = await Promise.race([fetchData(), TIMEOUT]);

PROMISE.ANY (ES2021):
  Promise.any(promises):
  - Fulfills with FIRST to fulfill
  - Only rejects if ALL reject (AggregateError with all reasons)
  - Use: try multiple endpoints, take first successful

  const data = await Promise.any([
    fetch('https://cdn1.example.com/data'),
    fetch('https://cdn2.example.com/data'),
    fetch('https://cdn3.example.com/data')
  ]);
  // First CDN to respond successfully wins

CONCURRENCY LIMIT PATTERN:
  // Problem: Promise.all with 1000 items hits rate limits
  async function batchProcess(items, concurrency = 5) {
    const results = [];
    for (let i = 0; i < items.length; i += concurrency) {
      const batch = items.slice(i, i + concurrency);
      const batchResults = await Promise.all(
        batch.map(item => processItem(item))
      );
      results.push(...batchResults);
    }
    return results;
  }
  // Process in batches of 5: limits concurrent requests
```

---

### 💻 Code Example

**Concurrency pattern selection in production**

```javascript
// SCENARIO: Load a user profile page
// - User data (required)
// - User posts (required)
// - Recommendations (nice to have, can degrade)
// - User stats (nice to have, can degrade)

// BAD: all sequential (slow)
async function loadProfile(userId) {
  const user  = await fetchUser(userId);    // 100ms
  const posts = await fetchPosts(userId);   // 150ms
  const recs  = await fetchRecs(userId);    // 200ms
  const stats = await fetchStats(userId);   // 80ms
  // Total: 530ms
  return { user, posts, recs, stats };
}

// BAD: Promise.all (fails if recs or stats fail)
async function loadProfile(userId) {
  const [user, posts, recs, stats] = await Promise.all([
    fetchUser(userId),
    fetchPosts(userId),
    fetchRecs(userId),    // if this fails: ENTIRE profile fails
    fetchStats(userId)
  ]);
  return { user, posts, recs, stats };
}

// GOOD: tiered approach
async function loadProfile(userId) {
  // Required data: fail fast if unavailable
  const [user, posts] = await Promise.all([
    fetchUser(userId),
    fetchPosts(userId)
  ]);

  // Nice-to-have data: degrade gracefully
  const [recs, stats] = await Promise.allSettled([
    fetchRecs(userId),
    fetchStats(userId)
  ]).then(results => results.map(r =>
    r.status === 'fulfilled' ? r.value : null
  ));

  return { user, posts, recs, stats };
  // If recs/stats fail: returns null for those fields
  // Profile still loads with core content
}

// CONCURRENCY LIMITER for batch jobs:
async function processUsers(userIds) {
  const CONCURRENCY = 10;
  const results = [];

  for (let i = 0; i < userIds.length; i += CONCURRENCY) {
    const chunk = userIds.slice(i, i + CONCURRENCY);
    const chunkResults = await Promise.all(
      chunk.map(id => processUser(id).catch(err => ({
        id,
        error: err.message,
        success: false
      })))
    );
    results.push(...chunkResults);
    // Optional: rate limit delay
    if (i + CONCURRENCY < userIds.length) {
      await new Promise(r => setTimeout(r, 100));
    }
  }
  return results;
}
```

> **Code walkthrough:** The tiered approach separates data into required
> (use `Promise.all`, fail fast) and optional (use `Promise.allSettled`,
> graceful degradation). Required data failing means the page cannot
> render meaningfully, so failing fast is correct. Optional data
> failing means the page can still show core content. The concurrency
> limiter processes items in chunks of 10 - without this, processing
> 1000 users with `Promise.all` would fire 1000 simultaneous requests,
> overwhelming the server or hitting rate limits. Batching to 10
> concurrent requests keeps throughput high while respecting limits.
> The per-item `.catch()` inside the chunk prevents one failing user
> from blocking the entire chunk.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `Promise.all`: parallel, fail fast. `Promise.allSettled`: parallel,
> never fail fast. `Promise.race`: first to settle. `Promise.any`:
> first to succeed. Use `Promise.all` for required parallel data,
> `Promise.allSettled` for optional data with graceful degradation.

---

**Senior / Staff:**

> Concurrency pattern selection is an architecture decision: fail-fast
> vs graceful degradation. Production systems often use tiered loading:
> critical path with `Promise.all`, optional features with `Promise.allSettled`.
> Concurrency limiting is essential for batch jobs against rate-limited
> APIs. Unhandled rejections from concurrent operations are a common
> production incident - always add per-item error handling inside
> `Promise.all` maps.

---

### ⚠️ Common Misconceptions

**"Promise.race cancels the slower promises"**

`Promise.race` returns the first to settle, but the other Promises
are NOT cancelled - they continue executing. JavaScript has no built-in
Promise cancellation. For true cancellation: use `AbortController`
with `fetch`, or implement a cancel token pattern. The non-cancelled
Promises in a race will continue running; their results are simply
ignored (and their side effects still occur).

---

### 🚨 Failure Modes and Diagnosis

**Symptom: one rejection silently kills entire Promise.all**

```javascript
// SYMPTOM: entire batch fails due to one error
const results = await Promise.all(
  userIds.map(id => fetchUser(id))  // if ANY rejects: ALL lost
);

// DIAGNOSIS: Promise.all rejects on first rejection,
// discarding results of fulfilled promises

// FIX: per-item error handling
const results = await Promise.all(
  userIds.map(id =>
    fetchUser(id).catch(err => ({
      id,
      error: err.message,
      success: false
    }))
  )
);
// results is always an array of successes or error objects
// Never throws

// OR: use Promise.allSettled
const settled = await Promise.allSettled(
  userIds.map(id => fetchUser(id))
);
const successes = settled
  .filter(r => r.status === 'fulfilled')
  .map(r => r.value);
const failures = settled
  .filter(r => r.status === 'rejected')
  .map(r => r.reason);
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Promise.all vs allSettled | 3 min | Fail-fast vs resilient |
| Promise.race timeout implementation | 3-4 min | Race use case |
| Concurrency limit pattern | 4-5 min | Batch processing |
| Sequential vs parallel trade-offs | 3 min | When each is right |
| Promise.any use case | 2-3 min | Redundancy pattern |
| Promise cancellation | 2-3 min | Not natively supported |
| Handling partial failures | 3-4 min | Production resilience |

---

**Q1: When would you use Promise.allSettled over Promise.all?**
`[MID]` TRADE-OFF

> **Answer:**
>
> Use `Promise.allSettled` when:
> 1. You need results from ALL operations, even if some fail
> 2. Partial success is acceptable and useful
> 3. You want to distinguish successes from failures after all complete
>
> Use `Promise.all` when:
> 1. ALL operations must succeed to proceed
> 2. Any failure should abort the entire operation
> 3. You only need results if everything succeeds
>
> ```javascript
> // Promise.all: appropriate for loading required data
> // If user or permissions fail: can't render anything
> const [user, permissions] = await Promise.all([
>   fetchUser(id),
>   fetchPermissions(id)
> ]);
>
> // Promise.allSettled: appropriate for batch reporting
> // Want to know which succeeded AND which failed
> const results = await Promise.allSettled(
>   emailList.map(email => sendEmail(email))
> );
>
> const sent   = results.filter(r => r.status === 'fulfilled');
> const failed = results.filter(r => r.status === 'rejected');
> logger.info(`Sent: ${sent.length}, Failed: ${failed.length}`);
>
> // Re-queue failed:
> const failedEmails = failed.map((r, i) => emailList[i]);
> await retryQueue.addAll(failedEmails);
> ```
>
> *What separates good from great:* The real production question is:
> "What is the user experience when partial failure occurs?" For a
> dashboard loading 5 widgets: `Promise.all` would blank the entire
> dashboard if one widget's API fails. `Promise.allSettled` lets you
> show 4 widgets with a "failed to load" state for the 5th. The latter
> is almost always better UX. The pattern is: use `Promise.all` for
> structural requirements (you literally cannot render without this
> data), use `Promise.allSettled` for optional or additive data.
> This distinction reflects the difference between hard dependencies
> and soft dependencies in your UI.
