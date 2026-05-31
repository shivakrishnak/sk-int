---
layout: default
title: "JavaScript - L2 Async Programming"
parent: "JavaScript"
nav_order: 5
permalink: /javascript/l2-async-programming/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Callbacks and Callback Hell](#callbacks-and-callback-hell) | working |
| 2 | [Promises and Promise Chaining](#promises-and-promise-chaining) | working |

---

# Callbacks and Callback Hell

🎯 **Interview Weight:** working (★★☆) - required for understanding
async JavaScript history; callback hell diagnosis is a code review skill

---

### 🎯 Model Answer

**30 seconds:**

> A callback is a function passed to another function to be called
> when an operation completes. Callback hell (pyramid of doom) occurs
> when callbacks nest deeply, creating heavily indented, hard-to-read
> code where error handling is duplicated. Modern JavaScript replaced
> nested callbacks with Promises and async/await, but callbacks are
> still used for event listeners and some Node.js APIs.

**3 minutes:**

> Callbacks work because JavaScript functions are first-class: you
> can pass them as arguments. The pattern: "do this operation, and
> when done, call THIS function." This enables non-blocking async
> code without threads.
>
> Callback hell emerges when sequential async operations nest:
> ```
> readFile → then parseJSON → then fetchUser → then saveToDB
> ```
> Each step nests inside the previous, creating indentation that
> spirals rightward with duplicated error handling at each level.
>
> Problems with deep callback nesting: error handling is inconsistent,
> inversion of control (you trust the API to call your callback
> correctly), no return values, cannot use try/catch.

**Blank Mind Recovery:**

**(1) Restate:** "Callback: function passed to be called later.
Callback hell: nested callbacks, pyramid shape, hard to read and error-handle."

---

### 📘 Concept Explanation

**What it is:**

A callback is a function passed as an argument to another function,
to be invoked when an asynchronous operation (or synchronous) completes.
Callback hell is the pattern of deeply nested callbacks that emerges
when multiple sequential async operations depend on each other's results.

**The problem it solves (and creates):**

Callbacks solved the fundamental problem of non-blocking I/O: start
an operation, provide a callback for when it finishes, and continue
executing other code in the meantime. The problem they created: chaining
multiple async operations requires nesting, leading to pyramidal code
with error handling duplicated at every level.

**How it works:**

```
CALLBACK MECHANICS:

  // Synchronous callback (called immediately):
  [1, 2, 3].forEach(item => console.log(item));

  // Asynchronous callback (called later):
  setTimeout(() => console.log('done'), 1000);
  fs.readFile('data.txt', 'utf8', (err, data) => {
    if (err) throw err;
    console.log(data);
  });
  // code after readFile runs BEFORE the callback fires

  // Node.js error-first callback convention:
  function doSomething(callback) {
    asyncOperation((error, result) => {
      if (error) {
        callback(error, null);  // first arg: error
        return;
      }
      callback(null, result);   // first arg: null = no error
    });
  }
  doSomething((error, result) => {
    if (error) { /* handle */ return; }
    // use result
  });

CALLBACK HELL (PYRAMID OF DOOM):

  // Reading a config, fetching a user, then saving
  fs.readFile('config.json', 'utf8', (err, configData) => {
    if (err) { console.error('Config error:', err); return; }

    const config = JSON.parse(configData);
    fetchUser(config.userId, (err, user) => {
      if (err) { console.error('Fetch error:', err); return; }

      processUser(user, config, (err, processed) => {
        if (err) {
          console.error('Process error:', err); return;
        }

        saveToDatabase(processed, (err, saved) => {
          if (err) {
            console.error('Save error:', err); return;
          }
          sendEmail(saved.email, (err) => {
            if (err) {
              console.error('Email error:', err); return;
            }
            console.log('All done!');
            // 5 levels deep, error handling repeated 5 times
          });
        });
      });
    });
  });

CALLBACK HELL PROBLEMS:
  1. Inversion of control: you trust the API to call your
     callback exactly once, with correct args, not throw
  2. Error handling duplication: if/return at every level
  3. No return values from async functions
  4. Cannot use try/catch for async errors
  5. Execution order is non-obvious
  6. Difficult to share intermediate results

MITIGATION WITHOUT PROMISES (named functions):
  function handleConfig(err, configData) {
    if (err) return handleError('config', err);
    const config = JSON.parse(configData);
    fetchUser(config.userId, handleUser.bind(null, config));
  }
  function handleUser(config, err, user) {
    if (err) return handleError('user', err);
    processUser(user, config, handleProcessed);
  }
  // ... separate named functions for each step
  // Flatter structure but harder to follow the flow
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Callback hell vs named callbacks vs Promise**

```javascript
// BAD: deep callback nesting
function loadUserProfile(userId) {
  db.findUser(userId, (err, user) => {
    if (err) { handleError(err); return; }

    db.findPosts(user.id, (err, posts) => {
      if (err) { handleError(err); return; }

      db.findComments(posts[0].id, (err, comments) => {
        if (err) { handleError(err); return; }

        // Finally have user, posts, comments
        renderProfile(user, posts, comments);
      });
    });
  });
}

// BETTER: named step functions (flatten the pyramid)
function loadUserProfile(userId) {
  db.findUser(userId, onUserFound);

  function onUserFound(err, user) {
    if (err) return handleError(err);
    db.findPosts(user.id, onPostsFound.bind(null, user));
  }

  function onPostsFound(user, err, posts) {
    if (err) return handleError(err);
    db.findComments(
      posts[0].id,
      onCommentsFound.bind(null, user, posts)
    );
  }

  function onCommentsFound(user, posts, err, comments) {
    if (err) return handleError(err);
    renderProfile(user, posts, comments);
  }
}

// BEST: Promises (or async/await)
async function loadUserProfile(userId) {
  const user     = await db.findUser(userId);
  const posts    = await db.findPosts(user.id);
  const comments = await db.findComments(posts[0].id);
  renderProfile(user, posts, comments);
  // Single try/catch wraps all errors
}
```

> **Code walkthrough:** The deeply nested version demonstrates callback
> hell: five levels of indentation, error handling repeated at each
> level, and the overall flow is hard to read because you must trace
> from the outermost function inward. The named function version flattens
> the structure but requires `bind(null, ...)` to pass intermediate
> results forward - awkward. The Promise/async version reads as
> sequential code: `await` pauses execution until each async operation
> resolves, sequential results are local variables, and a single
> try/catch (or `.catch()`) handles all errors. This clarity is the
> primary reason Promises and async/await were added to JavaScript.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Callbacks: functions passed to be called when async operations complete.
> Callback hell: deep nesting when sequential async operations are chained.
> Problems: duplicated error handling, inversion of control, hard to read.
> Solution: Promises and async/await flatten the structure.

---

**Senior / Staff:**

> Callback hell's deeper problem is inversion of control: you surrender
> control over when and how your callback is called. Promises solve this
> by returning values you control. The three callback hell escapes:
> named functions (structural), Promises (semantic), async/await (syntactic).
> Some APIs still require callbacks (event listeners, stream handlers)
> where the multi-call nature (`on('data')`) doesn't map to Promises.

---

### ⚠️ Common Misconceptions

**"Callbacks are always asynchronous"**

Callbacks can be synchronous. `Array.prototype.forEach`, `map`, `filter`,
`reduce` all take callbacks that are called synchronously and immediately.
`setTimeout` and `fs.readFile` take callbacks that are called asynchronously
(after the current call stack completes). The callback pattern itself
says nothing about timing - it depends on the function calling the callback.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: callback called multiple times or not at all**

```javascript
// INVERSION OF CONTROL PROBLEM:
// You pass a callback; the library calls it.
// If the library has a bug: callback may be called twice.

// DEFENSE: wrap with "once" pattern
function once(fn) {
  let called = false;
  return function(...args) {
    if (!called) {
      called = true;
      fn.apply(this, args);
    }
  };
}

// Or: convert callback API to Promise (promisify)
const readFileAsync = (path, encoding) =>
  new Promise((resolve, reject) => {
    fs.readFile(path, encoding, (err, data) => {
      if (err) reject(err);
      else resolve(data);
    });
  });
// Now: await readFileAsync('config.json', 'utf8')
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| What is a callback | 2 min | Clear definition |
| What is callback hell | 2-3 min | Pattern recognition |
| Problems with deep callbacks | 3 min | Inversion of control |
| How to flatten callback nesting | 3-4 min | Named functions approach |
| Convert callback to Promise | 3-4 min | Promisify pattern |
| When are callbacks still appropriate | 2 min | Event listeners |
| Error-first callback convention | 2 min | Node.js pattern |

---

**Q1: What is inversion of control in the context of callbacks?**
`[MID]` CONCEPT

> **Answer:**
>
> Inversion of control (IoC) means handing control to another system.
> In callbacks: you write a function and pass it to a third-party API.
> You no longer control when it's called, how many times, or with
> what arguments.
>
> ```javascript
> // Your callback:
> function handleData(err, data) {
>   processData(data);
> }
>
> // You trust someAPI to:
> someAPI.fetch(options, handleData);
> // 1. Call handleData exactly once
> // 2. Pass either (error, null) or (null, result)
> // 3. Not throw synchronously
> // 4. Not call with both error and data
> // 5. Not call multiple times
> // If someAPI has a bug in ANY of these: your code breaks
> ```
>
> With Promises, you get control back:
> ```javascript
> const promise = someAPI.fetch(options);
> // You control what happens next:
> promise
>   .then(data => processData(data))
>   .catch(err => handleError(err));
> // A promise can only resolve or reject once.
> // The .then/.catch are YOUR code, not someAPI's.
> ```
>
> Promises solve IoC by making the async result a VALUE you can
> manipulate, pass around, combine with other Promises, and chain.
>
> *What separates good from great:* Even with Promises, IoC can occur
> with Promise creators - if the Promise executor throws, the Promise
> rejects, but if the executor calls resolve multiple times, only
> the first call counts. The ES Promise spec guarantees:
> (1) only one settlement, (2) settled asynchronously (microtask),
> (3) no throwing from `.then`/`.catch` (errors are chained). This
> spec gives you guarantees that callbacks cannot.

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


# Promises and Promise Chaining

🎯 **Interview Weight:** working (★★☆) - Promises are the foundation
of modern async JavaScript; required for understanding async/await,
fetch API, and error propagation

---

### 🎯 Model Answer

**30 seconds:**

> A Promise represents an eventual result: pending (not yet), fulfilled
> (success with value), or rejected (failed with reason). `.then(onFulfilled)`
> handles success, `.catch(onRejected)` handles errors. Promises chain:
> each `.then()` returns a new Promise, enabling sequential async
> operations without nesting. `Promise.all` runs operations in parallel.

**3 minutes:**

> Promise states (three, non-reversible):
> - **Pending**: initial state, neither fulfilled nor rejected
> - **Fulfilled**: operation completed successfully with a value
> - **Rejected**: operation failed with a reason (error)
>
> Once settled (fulfilled or rejected), a Promise cannot change state.
>
> Chaining: `.then(fn)` returns a new Promise. If `fn` returns a value,
> the new Promise resolves with that value. If `fn` returns a Promise,
> the new Promise "waits" for that inner Promise. If `fn` throws, the
> new Promise rejects.
>
> `.catch(fn)` is equivalent to `.then(undefined, fn)`. Errors propagate
> through the chain until a `.catch` handles them. `finally(fn)` runs
> regardless of outcome (for cleanup).

**Blank Mind Recovery:**

**(1) Restate:** "Promise: pending -> fulfilled or rejected. .then chains.
.catch handles errors. Errors propagate until caught."

---

### 📘 Concept Explanation

**What it is:**

A Promise is an object representing the eventual result of an async
operation. It provides a structured API for handling success and error,
enabling chaining of sequential async steps without nesting.

**The problem it solves:**

Promises restore developer control (no inversion of control), provide
a chainable API for sequential async operations, propagate errors
through chains automatically, and enable parallel execution with
`Promise.all` / `Promise.allSettled` / `Promise.race` / `Promise.any`.

**How it works:**

```
PROMISE STATES:

  Pending ──────────────┬──> Fulfilled (with value)
                        └──> Rejected  (with reason)

  Once settled: cannot transition back to pending.
  Once fulfilled: cannot reject. Once rejected: cannot fulfill.

CREATING A PROMISE:
  const promise = new Promise((resolve, reject) => {
    // Executor function: runs synchronously
    // Call resolve(value) to fulfill
    // Call reject(reason) to reject

    setTimeout(() => {
      if (Math.random() > 0.5) {
        resolve('success value');
      } else {
        reject(new Error('failed'));
      }
    }, 1000);
  });

CONSUMING A PROMISE:
  promise
    .then(value => {           // runs on fulfillment
      console.log(value);      // 'success value'
      return transformed;      // passes to next .then
    })
    .catch(error => {          // runs on rejection
      console.error(error);    // handles any upstream error
      return fallback;         // recovery value
    })
    .finally(() => {           // runs always (ES2018)
      cleanup();               // close connections, hide spinner
    });

PROMISE CHAINING:
  // Each .then returns a NEW Promise
  // Errors skip .then until they hit .catch

  Promise.resolve('start')
    .then(val => {
      console.log(val);  // 'start'
      return 'step1';    // resolve next promise with 'step1'
    })
    .then(val => {
      console.log(val);  // 'step1'
      throw new Error('oops'); // rejects next promise
    })
    .then(val => {
      // SKIPPED because previous threw
    })
    .catch(err => {
      console.log(err.message);  // 'oops'
      return 'recovered';
    })
    .then(val => {
      console.log(val);  // 'recovered' (catch recovered)
    });

STATIC PROMISE METHODS:

  Promise.resolve(value)  // creates fulfilled promise
  Promise.reject(reason)  // creates rejected promise

  Promise.all([p1, p2, p3]):
    Waits for ALL to fulfill.
    Rejects if ANY rejects (fail-fast).
    Returns array of results in input order.
    Use: parallel independent operations

  Promise.allSettled([p1, p2, p3]):
    Waits for ALL to settle (fulfill OR reject).
    Never rejects.
    Returns array: [{status:'fulfilled',value},...] or
                   [{status:'rejected',reason},...]
    Use: parallel operations where you need ALL results

  Promise.race([p1, p2, p3]):
    Settles with the FIRST to settle (either way).
    Use: timeout patterns

  Promise.any([p1, p2, p3]):
    Fulfills with FIRST to fulfill.
    Rejects only if ALL reject.
    Use: take first successful result

MICROTASK QUEUE:
  Promise callbacks run in the microtask queue,
  which is flushed BEFORE the macrotask queue:
    console.log('1');
    Promise.resolve().then(() => console.log('2'));
    setTimeout(() => console.log('3'), 0);
    console.log('4');
    // Output: 1, 4, 2, 3
    // Sync -> microtasks -> macrotasks
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Sequential and parallel Promise patterns**

```javascript
// SEQUENTIAL with chaining (one after another):
function loadUserDashboard(userId) {
  return fetchUser(userId)
    .then(user => {
      return fetchPosts(user.id)
        .then(posts => ({ user, posts }));  // bundle results
    })
    .then(({ user, posts }) => {
      return fetchStats(user.id)
        .then(stats => ({ user, posts, stats }));
    })
    .then(({ user, posts, stats }) => {
      renderDashboard(user, posts, stats);
    })
    .catch(err => {
      console.error('Dashboard load failed:', err);
      renderError(err);
    });
}
// Runs: fetchUser -> fetchPosts -> fetchStats (sequential)

// PARALLEL with Promise.all (independent operations):
function loadUserDashboard(userId) {
  return fetchUser(userId)
    .then(user => Promise.all([
      fetchPosts(user.id),    // starts immediately
      fetchStats(user.id),    // starts immediately
      fetchFollowers(user.id) // starts immediately
    ])
    .then(([posts, stats, followers]) => {
      renderDashboard(user, posts, stats, followers);
    }))
    .catch(err => {
      console.error('Dashboard load failed:', err);
    });
}
// fetchPosts + fetchStats + fetchFollowers run IN PARALLEL
// Total time: max(posts, stats, followers) vs sum

// Promise.allSettled - get ALL results even if some fail:
async function loadWithFallback(userIds) {
  const results = await Promise.allSettled(
    userIds.map(id => fetchUser(id))
  );
  return results.map(result => {
    if (result.status === 'fulfilled') {
      return result.value;
    } else {
      console.warn('Failed:', result.reason.message);
      return null;  // graceful fallback
    }
  }).filter(Boolean);  // remove nulls
}

// TIMEOUT PATTERN with Promise.race:
function withTimeout(promise, ms) {
  const timeout = new Promise((_, reject) =>
    setTimeout(() => reject(new Error(`Timeout after ${ms}ms`)), ms)
  );
  return Promise.race([promise, timeout]);
}
withTimeout(fetchUser(userId), 5000)
  .then(user => console.log(user))
  .catch(err => console.error(err.message));
// If fetchUser takes > 5 seconds: "Timeout after 5000ms"
```

> **Code walkthrough:** The sequential approach chains `.then()` calls,
> passing intermediate results via bundle objects `{ user, posts }`.
> Each step waits for the previous before starting - total time equals
> the sum. The parallel approach uses `Promise.all` to start
> `fetchPosts`, `fetchStats`, and `fetchFollowers` simultaneously after
> getting the user - total time equals the slowest operation. For a
> typical dashboard load, this is a 3x speedup. `Promise.allSettled`
> is essential when you need ALL results even if some operations fail:
> unlike `Promise.all` which rejects on the first failure, `allSettled`
> waits for everything and gives you individual status for each.
> The timeout pattern uses `Promise.race`: whichever settles first wins -
> if the real request finishes before the timeout, success; if the
> timeout fires first, rejection with a descriptive error.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Promise: pending -> fulfilled or rejected. `.then` for success,
> `.catch` for errors, `.finally` always. Errors propagate through
> chains until caught. `Promise.all` runs in parallel, fails fast.
> `Promise.allSettled` waits for all, never fails fast.

---

**Senior / Staff:**

> Promise chaining is a monad-like structure: each `.then` transforms
> a Promise of T into a Promise of U. Errors "skip" `.then` until
> a `.catch` (like Option/Maybe chaining). `Promise.allSettled` is
> preferred over `Promise.all` in production when you need resilience:
> one failing API shouldn't prevent all others from succeeding.
> Unhandled promise rejections crash Node.js processes in modern versions
> (since v15). Always add `.catch()` or `try/catch` with async/await.

---

### ⚠️ Common Misconceptions

**"Promise.all is always better than sequential awaits"**

`Promise.all` is better when operations are INDEPENDENT. If `fetchPosts`
depends on the user returned by `fetchUser`, they must be sequential.
If `fetchPosts` and `fetchStats` are independent (both need only `user.id`),
`Promise.all` is faster. Running independent operations in parallel
is correct; running dependent operations in parallel would fail (the
later operation doesn't have the data it needs).

---

### 🚨 Failure Modes and Diagnosis

**Symptom: unhandled promise rejection**

```javascript
// Node.js will print warning (v14) or crash (v15+):
// "UnhandledPromiseRejectionWarning"

// CAUSES:
// 1. No .catch() on a rejected promise
fetchUser(id);  // returned promise rejected, no .catch

// 2. .then chain without .catch
fetchUser(id).then(process);  // if fetchUser rejects: uncaught

// 3. async function called without try/catch or .catch
async function loadData() {
  const data = await fetch('/api/data');  // may reject
}
loadData();  // no .catch, no try/catch

// FIX: always handle rejections
fetchUser(id)
  .then(process)
  .catch(err => logger.error('fetchUser failed:', err));

// In Node.js: global handler as safety net
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled rejection:', reason);
  // Do NOT use to suppress errors - use as monitoring only
});
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Promise states and transitions | 2-3 min | States knowledge |
| Error propagation in chains | 3-4 min | Skip .then, hit .catch |
| Promise.all vs Promise.allSettled | 3 min | Fail-fast vs complete |
| Promise.race timeout pattern | 3-4 min | Race use case |
| Microtask vs macrotask | 3-4 min | Event loop integration |
| Promise chaining vs nesting | 3 min | Flat vs pyramid |
| Unhandled rejection diagnosis | 2-3 min | Production issue |

---

**Q1: What happens when an error is thrown inside a .then callback?**
`[MID]` MECHANISM

> **Answer:**
>
> If a `.then` callback throws an error, the Promise returned by
> that `.then` is rejected with the thrown error. The error propagates
> down the chain, skipping subsequent `.then` callbacks until it
> reaches a `.catch`:
>
> ```javascript
> Promise.resolve('start')
>   .then(val => {
>     console.log(val);         // 'start'
>     throw new Error('step 1 failed');
>     // ^ Promise returned by this .then is REJECTED
>   })
>   .then(val => {
>     // SKIPPED: upstream promise is rejected
>     console.log('never runs');
>   })
>   .then(val => {
>     // SKIPPED: still rejected, no .catch yet
>     console.log('never runs');
>   })
>   .catch(err => {
>     console.log(err.message); // 'step 1 failed'
>     // CAUGHT: .catch returns fulfilled promise
>     return 'recovered';       // recovery value
>   })
>   .then(val => {
>     console.log(val);  // 'recovered'
>     // Runs because .catch recovered the chain
>   });
> ```
>
> The same behavior applies when a `.then` returns a rejected Promise:
> ```javascript
> .then(val => Promise.reject(new Error('inner rejection')))
> // behaves the same as throwing
> ```
>
> *What separates good from great:* `.catch` is not just error handling -
> it's error RECOVERY. If `.catch` returns a value (or resolves a
> Promise), the chain CONTINUES in fulfilled state. This means you
> can have intermediate `.catch` blocks that handle specific errors
> and fall back to alternatives, while letting other errors propagate:
> ```javascript
> fetchPrimary(id)
>   .catch(err => {
>     if (err.code === 'NOT_FOUND') return fetchFallback(id);
>     throw err;  // re-throw other errors to outer .catch
>   })
>   .then(data => render(data))
>   .catch(err => renderError(err));
> ```
> This pattern is called "selective catch and re-throw."

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



