---
layout: default
title: "JavaScript - L3 Error Handling"
parent: "JavaScript"
nav_order: 11
permalink: /javascript/l3-error-handling/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [JavaScript Error Handling Strategies](#javascript-error-handling-strategies) | medium |
| 2 | [JavaScript Anti-patterns](#javascript-anti-patterns) | medium |

---

# JavaScript Error Handling Strategies

---

### 🎯 Model Answer

**30 seconds:**

> JavaScript error handling has three layers: synchronous `try/catch`
> for synchronous code, `.catch()` or `try/catch` in `async` functions
> for promises, and global handlers (`window.onerror`,
> `unhandledrejection`) as a last resort. The key mistake is catching
> errors without logging or re-throwing - silent swallowing hides bugs.
> In production, errors should be categorized: operational (expected,
> recoverable) vs programmer (bugs that should crash and be fixed).

**3 minutes (Senior):**

> I organize error handling around three categories: operational errors
> (network failures, validation errors - expected and recoverable),
> programmer errors (null dereference, type errors - should never happen
> in production), and external errors (third-party API failures).
> Operational errors should be caught and handled gracefully. Programmer
> errors should crash loudly in development and be reported via error
> monitoring in production.
>
> For synchronous code, `try/catch` is correct. For async/await code,
> `try/catch` wraps await calls. For promise chains, `.catch()` at the
> end handles rejections. The common mistake: `async` function throws
> become rejected promises - if the caller does not await or chain a
> `.catch()`, the rejection is swallowed.
>
> In production applications I use structured errors: custom Error
> subclasses with `code`, `statusCode`, and `context` fields. This
> enables error monitoring (Sentry, Datadog) to group related errors
> and enables middleware to respond with the right HTTP status.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "JavaScript error handling - let me think through
the three layers: sync, async, and global handlers."

**(2) First principles:** "Errors propagate up the call stack. For
synchronous code, `throw` + `catch` intercepts propagation. For
async code, rejections propagate through the promise chain..."

**(3) Bridge:** "Like a try/catch but for time-deferred code - the
promise chain is the async call stack."

---

### 📘 Concept Explanation

**What it is:**

JavaScript error handling combines synchronous `try/catch/finally`
with promise rejection handling (`.catch()`, `try/catch` in async
functions) and global last-resort handlers.

**The problem it solves:**

Unhandled exceptions crash Node.js processes. Unhandled promise
rejections cause silent failures in browsers and process termination
in Node.js (since v15). Structured error handling provides recovery,
logging, and user feedback.

**How it works:**

```
Synchronous:
  try {
    risky();
  } catch (err) {
    handle(err);    // err is Error or thrown value
  } finally {
    cleanup();      // always runs
  }

Async (Promise chain):
  fetch(url)
    .then(processResponse)
    .catch(err => handleNetworkError(err));
    // .catch at end handles ALL preceding rejections

Async/Await:
  async function load() {
    try {
      const data = await fetch(url).then(r => r.json());
      return data;
    } catch (err) {
      // Catches both fetch rejection AND JSON parse error
      handleError(err);
      throw err; // re-throw if caller needs to know
    }
  }

Global handlers (last resort):
  window.addEventListener('error', event => {
    reportToSentry(event.error);
  });
  window.addEventListener('unhandledrejection', event => {
    reportToSentry(event.reason);
    event.preventDefault(); // suppress browser console log
  });

Node.js:
  process.on('uncaughtException', (err) => {
    logger.fatal(err); process.exit(1);
  });
  process.on('unhandledRejection', (reason) => {
    logger.error(reason); process.exit(1);
  });
```

> **Code walkthrough:** This JavaScript Error Handling Strategies example demonstrates a key concept in practice using async/await. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

An unhandled promise rejection does not automatically bubble to
`window.onerror`. It fires `unhandledrejection` instead. Code that
only handles synchronous errors via `window.onerror` silently drops
all async errors.

**When to use it:**

- `try/catch` in async functions: catch both await rejections and
  synchronous errors in the same block
- Custom Error subclasses: structured errors with codes enable
  monitoring, retries, and appropriate HTTP responses
- Global handlers: always register; treat as monitoring, not recovery

**When NOT to use it:**

- Do not catch errors just to log and re-throw identically - that adds
  noise without value; let errors propagate and catch once at boundary
- Do not use empty `catch` blocks - they swallow bugs silently

**Alternatives:**

- Result type pattern (never throw) - explicit success/error return:
  `{ ok: true, value } | { ok: false, error }` - common in TypeScript
- Node.js EventEmitter `'error'` event - must be listened to or throws

**First-principles derivation:**

Errors must either be handled locally (recovery) or propagated upward
(boundary handling). The boundary that handles should log, report, and
decide whether to recover or terminate. Every throw should eventually
reach a catch; every catch should either recover or re-throw with context.

---

### 💻 Code Example

**Example 1: Async error handling patterns**


```javascript
// BAD: not awaiting async operations
function saveUser(user) {
    db.save(user); // async call not awaited
    return { success: true }; // returns before save completes
}
```


```javascript
// BAD: not awaiting async operations
function saveUser(user) {
    db.save(user); // async call not awaited
    return { success: true }; // returns before save completes
}
```

```javascript
// BAD: swallowed rejection
async function loadUser(id) {
  try {
    const user = await db.findUser(id);
    return user;
  } catch (err) {
    console.log('error'); // swallowed - caller sees undefined
  }
}

// BAD: missing catch on promise chain
function getProfile() {
  return fetchUser()
    .then(transformProfile);
    // No .catch - rejection silently swallowed
}

// GOOD: structured async error handling
async function loadUser(id) {
  try {
    const user = await db.findUser(id);
    if (!user) throw new NotFoundError(`User ${id} not found`);
    return user;
  } catch (err) {
    if (err instanceof NotFoundError) throw err; // re-throw known
    // Unexpected error: wrap with context
    throw new DatabaseError('Failed to load user', {
      cause: err, context: { id }
    });
  }
}

// GOOD: explicit error types
class AppError extends Error {
  constructor(message, options = {}) {
    super(message, { cause: options.cause });
    this.name = this.constructor.name;
    this.code = options.code ?? 'UNKNOWN';
    this.statusCode = options.statusCode ?? 500;
    this.context = options.context ?? {};
  }
}
class NotFoundError extends AppError {
  constructor(message, options = {}) {
    super(message, { ...options, code: 'NOT_FOUND',
      statusCode: 404 });
  }
}
class DatabaseError extends AppError {
  constructor(message, options = {}) {
    super(message, { ...options, code: 'DB_ERROR',
      statusCode: 500 });
  }
}
```

> **Code walkthrough:** The BAD pattern swallows the error by catchingice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> it without re-throwing - the caller receives `undefined` and never
> knows an error occurred. The GOOD pattern distinguishes error types:
> known errors (`NotFoundError`) are re-thrown unchanged; unexpected
> errors are wrapped with context and re-thrown. Custom Error classes
> with `code` and `statusCode` fields enable middleware to respond
> correctly and error monitoring to group related errors.

**Example 2: Global error boundary**

```javascript
// Production error boundary (Node.js Express)
function errorMiddleware(err, req, res, next) {
  // Log with full context
  logger.error({
    err,
    req: { method: req.method, url: req.url,
           userId: req.user?.id },
    stack: err.stack,
  });

  // Report to monitoring
  Sentry.captureException(err, {
    extra: { url: req.url, userId: req.user?.id }
  });

  // Respond with appropriate status
  const statusCode = err.statusCode ?? 500;
  const isOperational = err instanceof AppError;

  res.status(statusCode).json({
    error: {
      code: err.code ?? 'INTERNAL_ERROR',
      message: isOperational ? err.message
        : 'An unexpected error occurred',
    }
  });

  // Programmer errors (not AppError subclass) may warrant restart
  if (!isOperational) {
    process.nextTick(() => process.exit(1));
  }
}

// Global handlers as safety net
process.on('uncaughtException', err => {
  logger.fatal({ err }, 'Uncaught exception');
  Sentry.captureException(err);
  process.exit(1); // always exit - state is unknown
});
process.on('unhandledRejection', (reason, promise) => {
  logger.error({ reason, promise }, 'Unhandled rejection');
  Sentry.captureException(reason);
  process.exit(1);
});
```

> **Code walkthrough:** The Express error middleware is the boundaryice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> for all operational errors. It logs with full context, reports to
> monitoring, and responds with appropriate HTTP status. The distinction
> between operational errors (known AppError subclasses) and programmer
> errors (anything else) determines whether the process should continue
> or exit: programmer errors leave the system in an unknown state, so
> a controlled restart is safer than continuing. `process.nextTick`
> allows the response to be sent before exiting.

**Example 3: Error handling in async iteration**


```javascript
// BAD: unhandled Promise rejection
fetchData(url).then(data => {
    processData(data);
}); // no .catch() - rejection silently ignored
```

```javascript
// FAILURE EXAMPLE: parallel requests drop errors
async function loadAll(ids) {
  // BAD: if any fails, Promise.all rejects, others aborted
  const results = await Promise.all(ids.map(id => fetchItem(id)));
  return results;
}

// GOOD: use allSettled for independent parallel requests
async function loadAll(ids) {
  const results = await Promise.allSettled(
    ids.map(id => fetchItem(id))
  );
  const errors = results
    .filter(r => r.status === 'rejected')
    .map(r => r.reason);

  if (errors.length > 0) {
    logger.warn({ errors }, `${errors.length} items failed`);
  }

  return results
    .filter(r => r.status === 'fulfilled')
    .map(r => r.value);
}

// Error chaining with cause (ES2022)
async function processOrder(orderId) {
  try {
    const order = await db.getOrder(orderId);
    await paymentService.charge(order);
  } catch (err) {
    // Wrap with context, preserve original as cause
    throw new OrderProcessingError(
      `Failed to process order ${orderId}`,
      { cause: err, context: { orderId } }
    );
  }
}
// err.cause preserves the original error for stack trace
// err.message describes the high-level operation that failed
```

> **Code walkthrough:** `Promise.allSettled` is the correct choiceice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> for independent parallel operations where partial success is
> acceptable. `Promise.all` fails fast on first rejection, aborting
> all in-flight operations. The error chaining pattern using `cause`
> (ES2022) preserves the original error in the chain while adding
> domain context - monitoring tools and stack traces can follow the
> full chain from user action to root cause.

---

### ⚖️ Comparison Table

| Pattern | Use When | Risk |
|---|---|---|
| `try/catch` + re-throw | Sync or await code | Forgetting to re-throw |
| `.catch()` chain | Promise chains | Not chaining at end |
| `Promise.allSettled` | Independent parallel ops | Extra filtering code |
| `Promise.all` | Dependent parallel ops (fail-fast) | Partial completion state |
| Global `unhandledrejection` | Monitoring safety net | Cannot recover state |
| Result type `{ok, value, error}` | TS code, never-throw APIs | Verbose; callers must check |

**The deciding factor:**
Use `try/catch` in async functions for most code; `allSettled` for
independent parallel requests; structured custom errors at boundaries.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> For synchronous code I use `try/catch`. For async/await I wrap the
> await in `try/catch`. For promise chains I add `.catch()` at the
> end. In Node.js I register `process.on('unhandledRejection')` as
> a safety net. The most common mistake is catching errors without
> re-throwing, which hides bugs.

*Push deeper:* What happens to an unhandled promise rejection in
Node.js v15+? How does async/await error handling differ from promise
chain `.catch()`?

---

**Senior / Staff (5+ years):**

> I organize errors as operational vs programmer. Custom Error
> subclasses with `code`, `statusCode`, and `context` fields. At
> service boundaries (Express middleware) I catch, log, report to
> Sentry, and respond. Programmer errors that bypass the boundary
> hit global handlers and trigger process exit. For parallel requests
> I use `allSettled` to get partial results. Error `cause` chaining
> (ES2022) preserves the root cause through wrapping layers.

*Push deeper:* Staff discuss how to build observable error handling
(OpenTelemetry spans), error budgets vs SLOs, and circuit breaker
patterns for cascading failure prevention.

---

### ⚠️ Common Misconceptions

**Misconception 1: `window.onerror` catches unhandled promise rejections.**

It does not. Unhandled rejections fire `unhandledrejection`, not
`error`. Production apps must register both event types separately.

**Misconception 2: `try/catch` in an async function catches all errors.**

It catches errors thrown synchronously and rejections from awaited
promises in the try block. Errors from non-awaited promises or
callbacks inside setTimeout/setInterval are NOT caught.

**Misconception 3: Logging an error is the same as handling it.**

Logging provides observability; handling provides recovery. Catching,
logging, and returning `undefined` is typically a bug - the caller
receives a falsy value and may proceed incorrectly.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Silent promise rejection swallowing.**

Symptom: Feature stops working with no console errors; user gets
no feedback.

Diagnosis: Async function catches without re-throwing; callers check
for success but receive undefined.

Fix: All catch blocks must either recover fully (return valid value)
or re-throw (preserve rejection). Remove empty and log-only catches.

**Failure 2: Unhandled rejection in Node.js v15+ crashes process.**

Symptom: Node.js process exits with code 1 and "unhandledRejection"
message; no graceful shutdown.

Diagnosis: Promise chain missing `.catch()`; async function call
not awaited.

Fix: Add global `unhandledRejection` handler for monitoring; fix
the actual code to handle the rejection properly.

**Failure 3: Error information lost in re-wrapping.**

Symptom: Stack trace shows only the wrapping error; original cause
is unknown; hard to diagnose root failure.

Fix: Use `new Error('context', { cause: originalError })` (ES2022)
to preserve the original error in `err.cause`. Most error monitoring
tools display the full cause chain.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How do you handle errors in async/await code? | Definition | ★★☆ | 2 min |
| Promise.all vs allSettled - when to use each? | Comparison | ★★☆ | 2 min |
| Design error handling for an Express REST API | Scenario | ★★☆ | 5 min |
| Why is empty catch block dangerous? | Misconception | ★☆☆ | 1 min |
| Debugging: feature fails silently, no console errors | Debugging | ★★☆ | 3 min |
| Operational vs programmer errors - how do you handle each? | Deep Dive | ★★★ | 4 min |
| Does window.onerror catch promise rejections? | Misconception | ★★☆ | 2 min |
| Error cause chaining (ES2022) - why and how? | Mechanism | ★★☆ | 2 min |
| How do you implement global error observability? | Deep Dive | ★★★ | 4 min |

**Q: How do you design error handling for a production Express API?**

A: I organize around three layers. At the bottom: custom Error
subclasses (`AppError` base with `code`, `statusCode`, `context`;
`NotFoundError`, `ValidationError`, `ExternalServiceError` as
subclasses). Services throw these typed errors with domain context.

In the middle: async route handlers wrapped in a utility that catches
any thrown error and passes it to `next(err)`. This prevents
"unhandled async exception" issues and routes all errors to the
central middleware.

At the top: a single error middleware function that receives all
errors. It logs structured JSON with `err.stack`, request context,
and user ID. It calls `Sentry.captureException`. It responds with
`err.statusCode ?? 500` and a JSON body that exposes `err.message`
for operational errors (AppError subclasses) but returns a generic
message for programmer errors. For programmer errors (unexpected,
not AppError subclasses), it schedules `process.exit(1)` after
responding - the process is in an unknown state and should restart.

Outside Express: `process.on('uncaughtException')` and
`process.on('unhandledRejection')` as absolute last resort for
anything that escaped the middleware, both triggering monitoring
and process exit.

*What separates good from great:* The separation between operational
and programmer errors is the key design decision. Operational errors
are expected (bad request, not found, service unavailable) - handle
gracefully, respond with appropriate status, keep running.
Programmer errors (TypeError, RangeError) are bugs - report, exit,
restart. Treating all errors the same leads to either masking bugs
(catch everything, keep running) or crashing on expected failures.

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


# JavaScript Anti-patterns

---

### 🎯 Model Answer

**30 seconds:**

> JavaScript anti-patterns are code patterns that seem reasonable but
> cause subtle bugs, performance issues, or maintenance problems.
> The most impactful ones: callback hell (solved by async/await),
> floating promises (async call without await or .catch - swallows
> errors), mutating function arguments (causes side effects), using
> `var` across async callbacks (closure captures reference not value),
> and `==` with type coercion (implicit conversion surprises).

**3 minutes (Senior):**

> I organize JavaScript anti-patterns into four categories.
> Correctness anti-patterns: using `==` instead of `===` (type
> coercion surprises), mutating passed objects (caller's data changes
> unexpectedly), modifying built-in prototypes (breaks library code
> that iterates objects), and relying on `arguments` object instead
> of rest params.
>
> Async anti-patterns: floating promises (not awaiting or catching -
> the most common production bug), `for...of` with await inside a
> `.map()` callback (awaits run serially in map, not as intended),
> `async` function in `Promise.resolve()` (double-wrapping), and
> mixing promise and callback APIs.
>
> Performance anti-patterns: repeated DOM queries in loops (should
> cache), string concatenation in loops (use array + join or template
> literals), synchronous `JSON.parse` on large payloads in request
> handlers, and excessive prototype chain depth.
>
> Maintainability anti-patterns: callback nesting beyond 2 levels,
> boolean trap (function with two unnamed booleans), magic numbers,
> and giant modules with mixed concerns.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "JavaScript anti-patterns - code that looks correct
but causes subtle bugs. Let me think through the categories..."

**(2) First principles:** "Anti-patterns appear because JavaScript
has footguns: implicit coercion, reference semantics, async without
structured handling. Knowing the category predicts the fix..."

**(3) Bridge:** "Like code smells but with specific failure modes -
each anti-pattern has a diagnostic and a specific modern alternative."

---

### 📘 Concept Explanation

**What it is:**

JavaScript anti-patterns are recurring code patterns that appear
reasonable but cause bugs, performance issues, or maintainability
problems. Each has a specific failure mode and a preferred alternative.

**The problem it solves:**

JavaScript's flexibility and implicit behaviors (coercion, `this`
binding, async) create pitfalls that typed or stricter languages
prevent statically. Knowing the anti-patterns prevents production bugs.

**How it works:**

```
Category 1: Correctness
  == vs ===:    0 == false (true), "" == 0 (true)
  Mutation:     function modify(obj) { obj.x = 1; }
                caller's object changed - surprise!
  Prototype pollution: Object.prototype.isAdmin = true
                affects ALL objects in the runtime

Category 2: Async
  Floating promise:
    async function save() { await db.write(); }
    // caller: save(); // no await, no catch
    // rejection silently lost

  await in .map():
    const results = await ids.map(async id =>
      await fetchItem(id)); // WRONG
    // map returns array of Promises, not resolved values
    // Use: await Promise.all(ids.map(id => fetchItem(id)))

Category 3: Performance
  DOM queries in loop:
    for (let i = 0; i < 1000; i++) {
      document.getElementById('x').style.top = i + 'px';
      // Forces layout recalc each iteration
    }

  String concat in loop:
    let s = '';
    for (let i = 0; i < 10000; i++) s += items[i]; // O(n^2)
    // Use: items.join('')

Category 4: Maintainability
  Boolean trap:
    createUser('John', true, false, true);
    // What do true/false mean? No context
    // Better: createUser('John', { admin: true,
    //   active: false, verified: true })
```

> **Code walkthrough:** This JavaScript Anti-patterns example demonstrates a key concept in practice using async/await. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

The most dangerous anti-patterns are the silent ones: floating
promises (no error, just missing behavior), prototype pollution
(affects all objects globally), and `==` type coercion (truthy
check passes when it should fail). Lint rules (ESLint) catch most
of these statically.

**When to use it:**

Knowing anti-patterns is essential for code review, debugging
mysterious failures, and writing maintainable production code.

**When NOT to use it:**

Not all patterns labeled "anti-pattern" in blog posts are universally
bad - context matters. Mutation is fine in controlled local scope;
the issue is mutating shared or passed-in state.

**Alternatives:**

- ESLint with recommended rules: catches `==`, `var`, unused vars,
  floating promises (`@typescript-eslint/no-floating-promises`)
- TypeScript: eliminates type coercion surprises, requires explicit
  `void` for floating promises

**First-principles derivation:**

Anti-patterns emerge when language features interact in unexpected
ways. JavaScript's `==` performs implicit coercion by design; async
functions return promises by design. The anti-patterns arise when
developers treat these as synchronous strict operations.

---

### 💻 Code Example

**Example 1: Async anti-patterns**


```javascript
// BAD: unhandled Promise rejection
fetchData(url).then(data => {
    processData(data);
}); // no .catch() - rejection silently ignored
```


```javascript
// BAD: unhandled Promise rejection
fetchData(url).then(data => {
    processData(data);
}); // no .catch() - rejection silently ignored
```


```javascript
// BAD: unhandled Promise rejection
fetchData(url).then(data => {
    processData(data);
}); // no .catch() - rejection silently ignored
```

```javascript
// ANTI-PATTERN: floating promise (most common production bug)
// BAD: save() called but rejection silently dropped
button.addEventListener('click', async () => {
  saveData(); // no await, no catch - fire and forget
  showSuccess(); // shown even if save failed!
});

// GOOD: await and handle
button.addEventListener('click', async () => {
  try {
    await saveData();
    showSuccess();
  } catch (err) {
    showError(err.message);
  }
});

// ANTI-PATTERN: await in .map() (does not parallelize)
// BAD: sequential - each waits for previous to finish
async function loadItems(ids) {
  const results = await ids.map(async id =>
    await fetchItem(id)); // map doesn't await!
  // results = [Promise, Promise, ...] not resolved values
  return results; // returns array of Promises
}

// GOOD: Promise.all for parallel execution
async function loadItems(ids) {
  const results = await Promise.all(ids.map(id => fetchItem(id)));
  return results; // array of resolved values, all parallel
}

// ANTI-PATTERN: mixing async styles
// BAD: callback inside async function leaks control
async function readFile(path) {
  return new Promise((resolve, reject) => {
    fs.readFile(path, (err, data) => { // callback inside promise
      if (err) reject(err);
      else resolve(data);
    });
  }); // OK but prefer: fs.promises.readFile(path)
}
// GOOD: use promisified APIs directly
async function readFile(path) {
  return fs.promises.readFile(path); // no new Promise needed
}
```

> **Code walkthrough:** The floating promise anti-pattern is the mostice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> common production bug in JavaScript - an async function is called
> without await, and any rejection is silently dropped. The button
> handler shows success even on save failure. `await` in `.map()`
> is a subtler bug: `Array.map` is synchronous and returns an array
> of Promises, not resolved values. `Promise.all` is the correct
> parallel pattern. The third pattern shows that wrapping a
> promisified API in `new Promise` is unnecessary noise when the API
> already returns a promise.

**Example 2: Correctness anti-patterns**

```javascript
// ANTI-PATTERN: == type coercion surprises
// BAD: type coercion produces unexpected equality
console.log(0 == false);     // true (0 coerces to false)
console.log("" == 0);        // true (both coerce to 0)
console.log(null == undefined); // true
console.log([] == false);    // true (both become 0)

if (user.age == "18") { /* triggers for age === 18 too */ }

// GOOD: always use === for intentional equality
if (user.age === 18) { /* exact match only */ }

// ANTI-PATTERN: prototype pollution
// BAD: modifying Object.prototype affects ALL objects
Object.prototype.isAdmin = true;
const user = { name: 'Alice' };
if (user.isAdmin) { /* true for ALL objects - security hole */ }

// BAD: user-controlled input polluting prototype
function merge(target, source) {
  for (const key of Object.keys(source)) {
    target[key] = source[key]; // '__proto__' key pollutes!
  }
}
// Input: { "__proto__": { "isAdmin": true } }
// GOOD: sanitize keys, use Object.create(null) for dictionaries
function safeMerge(target, source) {
  for (const key of Object.keys(source)) {
    if (key === '__proto__' || key === 'constructor') continue;
    target[key] = source[key];
  }
}

// ANTI-PATTERN: mutating function arguments
// BAD: caller's object is modified - unexpected side effect
function addTimestamp(config) {
  config.timestamp = Date.now(); // mutates caller's object!
  return config;
}
// GOOD: return new object
function addTimestamp(config) {
  return { ...config, timestamp: Date.now() };
}
```

> **Code walkthrough:** The `==` anti-pattern is well-known but theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> failure mode is specific: `[] == false` being true is genuinely
> surprising because both convert through `Number()`. Prototype
> pollution is a security vulnerability (CVE-level in Node.js apps
> that merge user-controlled JSON) - `__proto__` as a key in a
> merge operation injects properties onto all objects in the runtime.
> The mutation anti-pattern causes hidden state sharing: callers
> expect their object to be unchanged after passing it to a function.

**Example 3: Performance anti-patterns**

```javascript
// ANTI-PATTERN: DOM queries in loop (layout thrashing)
// BAD: read and write style in same loop forces recalc
const items = document.querySelectorAll('.item');
for (const item of items) {
  const height = item.offsetHeight; // READ (forces layout)
  item.style.height = (height * 2) + 'px'; // WRITE (invalidates)
  // Next iteration: offsetHeight recalculates again
}

// GOOD: batch reads then batch writes
const heights = Array.from(items).map(el => el.offsetHeight); // reads
items.forEach((el, i) => {
  el.style.height = (heights[i] * 2) + 'px'; // then writes
});

// ANTI-PATTERN: string concatenation in hot loop (O(n^2))
// BAD: each += creates a new string object
function buildHtml(items) {
  let html = '';
  for (const item of items) {
    html += `<li>${item}</li>`; // O(n^2) total allocations
  }
  return html;
}
// GOOD: array join (O(n))
function buildHtml(items) {
  return items.map(item => `<li>${item}</li>`).join('');
}

// ANTI-PATTERN: creating functions inside loops
// BAD: new function object created per iteration
const handlers = items.map(item =>
  () => handleClick(item)); // closure per iteration is fine
  // but class methods in loop:
elements.forEach(el => {
  el.addEventListener('click', function() { // new fn each time
    this.classList.toggle('active');
  });
});
// GOOD: use event delegation - one listener on parent
parent.addEventListener('click', e => {
  if (e.target.matches('.item')) {
    e.target.classList.toggle('active');
  }
});
```

> **Code walkthrough:** Layout thrashing is one of the top performanceice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> anti-patterns in DOM-heavy code. Reading a layout property (`offsetHeight`,
> `getBoundingClientRect`) after a style write forces the browser to
> synchronously recalculate layout. Batching reads before writes
> eliminates this. String concatenation in loops is O(n^2) because
> each `+=` creates a new string of growing length; `join('')` does
> a single allocation of the final size. Event delegation replaces
> N listeners on N elements with 1 listener on the parent.

---

### ⚖️ Comparison Table

| Anti-pattern | Category | Risk | Fix |
|---|---|---|---|
| Floating promise | Async | Silent data loss | `await` or `.catch()` |
| `await` in `.map()` | Async | Returns Promises, not values | `Promise.all` |
| `==` coercion | Correctness | Unexpected equality | `===` |
| Prototype pollution | Security | Global object corruption | Key sanitization |
| Mutating arguments | Correctness | Hidden state sharing | Spread/Object.assign |
| DOM query in loop | Performance | Layout thrashing | Batch reads then writes |
| String concat in loop | Performance | O(n^2) allocations | `join('')` |

**The deciding factor:**
Enable ESLint `no-floating-promises`, `eqeqeq`, `no-prototype-builtins`
rules to catch the most dangerous anti-patterns at lint time.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Common JavaScript anti-patterns I watch for: forgetting to await
> async calls, using `==` instead of `===`, and mutating function
> arguments. I use ESLint to catch most of these automatically.

*Push deeper:* Explain why `await` in `.map()` does not work as
expected. What is prototype pollution and why is it dangerous?

---

**Senior / Staff (5+ years):**

> I categorize anti-patterns: async (floating promises, await in map),
> correctness (==, mutation, prototype pollution), performance (DOM
> thrashing, string concat in loop), and maintainability (boolean
> trap, magic numbers). I enforce ESLint `no-floating-promises` and
> `eqeqeq` at the repo level. Prototype pollution is my main concern
> in APIs that merge user-controlled input - I validate keys explicitly.

*Push deeper:* Staff discuss prototype pollution as CVE-level security
issue, how TypeScript's type system prevents most correctness
anti-patterns, and how bundler tree-shaking catches some of the
maintainability patterns.

---

### ⚠️ Common Misconceptions

**Misconception 1: `async` without `await` is equivalent to sync code.**

An `async` function always returns a Promise. Calling it without
`await` runs it but ignores the result and any rejection.
`// fire and forget` is rarely intentional in application code.

**Misconception 2: `===` is always slower than `==`.**

`===` skips type coercion and is typically faster. The "strict equals
is slower" myth is reversed.

**Misconception 3: `Object.freeze()` prevents prototype pollution.**

`Object.freeze()` prevents property addition to the frozen object.
Prototype pollution targets `Object.prototype`, not the frozen object
itself. You need to explicitly sanitize `__proto__` keys in merge
functions or use `Object.create(null)` for plain dictionaries.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Feature works in dev but fails silently in production.**

Symptom: Data loss with no error logs; async operation not completing.

Diagnosis: Floating promise - async function called without await/catch.

Fix: Grep for `async` function calls without `await`; add `no-floating-promises`
ESLint rule.

**Failure 2: `isAdmin` is true for all objects (prototype pollution).**

Symptom: Authorization bypass; all users have unexpected permissions.

Diagnosis: User-controlled JSON with `__proto__` key was merged into
an object.

Fix: Sanitize merge keys; use `Object.hasOwn()` instead of `in`
operator for security checks; validate JSON schema before merge.

**Failure 3: Parallel requests run sequentially (slow performance).**

Symptom: N API calls take N * latency instead of ~1 * latency.

Diagnosis: `await` inside `.map()` callback - each waits for previous.

Fix: `await Promise.all(ids.map(id => fetchItem(id)))`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is a floating promise and why is it dangerous? | Definition | ★★☆ | 2 min |
| Why doesn't await work inside .map()? | Mechanism | ★★☆ | 2 min |
| What is prototype pollution? How do you prevent it? | Security | ★★★ | 4 min |
| Fix: 100 API calls running sequentially instead of parallel | Debugging | ★★☆ | 3 min |
| What is layout thrashing and how do you prevent it? | Performance | ★★☆ | 3 min |
| == vs === - when would you ever use ==? | Comparison | ★★☆ | 2 min |
| What ESLint rules do you enforce to prevent anti-patterns? | Scenario | ★★☆ | 2 min |
| How does mutating a function argument cause production bugs? | Scenario | ★★☆ | 3 min |
| Design a safe object merge function (no prototype pollution) | Deep Dive | ★★★ | 5 min |

**Q: What is prototype pollution and how do you defend against it?**

A: Prototype pollution is a vulnerability where an attacker-controlled
object key (typically `__proto__` or `constructor.prototype`) causes
properties to be added to `Object.prototype`, affecting every object
in the runtime. The classic vector is a recursive object merge or
deep clone that does not sanitize keys:

```javascript
function merge(a, b) {
  for (const key in b) {
    if (typeof b[key] === 'object') merge(a[key], b[key]);
    else a[key] = b[key];
  }
}
// Attack: merge({}, JSON.parse('{"__proto__":{"isAdmin":true}}'))
// After: ({}).isAdmin === true for ALL objects
```

> **Code walkthrough:** This Unknown example demonstrates variable declaration. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **TAKEAWAY: use Object.freeze() to prevent mutation; const only guards the binding.**

This has caused critical CVEs in lodash, jquery, and dozens of
npm packages. Defenses: (1) sanitize merge keys explicitly -
skip `__proto__`, `constructor`, `prototype`; (2) use
`Object.create(null)` for dictionary objects - they have no
prototype and cannot be polluted; (3) use `Object.hasOwn(obj, key)`
instead of `key in obj` for authorization checks - `hasOwn` only
checks own properties, not inherited; (4) use `structuredClone()`
(native, does not clone prototype chain) for deep clones instead
of custom recursive clones.

*What separates good from great:* Understanding that `Object.freeze(Object.prototype)`
is a defense-in-depth mitigation - it prevents properties from being
added to the prototype but may break libraries that extend it. The
production-safe approach is key sanitization in all merge/assign
functions that accept user-controlled input.

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



