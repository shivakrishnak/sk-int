---
layout: default
title: "Node.js - L1 Core Concepts"
parent: "Node.js"
nav_order: 2
permalink: /nodejs/l1-core-concepts/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Event Loop Fundamentals](#event-loop-fundamentals) | medium |
| 2 | [Callbacks and Error-first Pattern](#callbacks-and-error-first-pattern) | medium |
| 3 | [Node.js Module System (require vs import)](#nodejs-module-system-require-vs-import) | medium |

---

# Event Loop Fundamentals

---

### 🎯 Model Answer

**30 seconds:**

> The event loop is Node.js's mechanism for handling asynchronous
> operations with a single thread. It continually checks whether the
> call stack is empty, then picks the next callback from the queue
> and executes it. Six phases in order: timers (setTimeout/setInterval),
> pending callbacks, idle/prepare, poll (I/O), check (setImmediate),
> close callbacks. `process.nextTick` runs between every phase.
> This is why Node.js can handle thousands of concurrent I/O operations
> without threads.

**3 minutes:**

The event loop is a loop that runs continuously as long as there's
work to do. "Work" means items in one of its queues. Each "tick" of
the loop processes callbacks that have become ready.

**How I/O works with the event loop:**

1. Your code calls `fs.readFile('data.txt', callback)`
2. Node.js delegates the read to libuv (OS I/O)
3. Your code continues executing (non-blocking)
4. When OS finishes reading, libuv marks the callback as ready
5. Event loop (poll phase) picks up the callback and executes it

**The critical insight:** "asynchronous" in Node.js means callbacks
run on the main thread but only when the call stack is empty. One
CPU core, one thread, but thousands of pending I/O callbacks.

**Blank Mind Recovery:**

**(1) What it is:** "A loop that runs forever, checking queues for
ready callbacks, executing them one at a time."

**(2) Six phases:** "Timers -> pending -> idle -> poll (I/O) ->
check -> close callbacks. nextTick runs between all phases."

**(3) Why it matters:** "Non-blocking I/O. Callbacks don't block
each other. But CPU work DOES block the loop."

---

### 📘 Concept Explanation

**What it is:**

The event loop is the core mechanism enabling Node.js's non-blocking,
single-threaded concurrency model.

**How it works:**

```
Event loop phases (simplified):

    ┌─────────────────────────────────────────────┐
    │                 timers phase                │
    │   setTimeout() / setInterval() callbacks    │
    └──────────────────────┬──────────────────────┘
                           │
    ┌──────────────────────▼──────────────────────┐
    │            pending callbacks phase           │
    │   I/O callbacks from previous loop tick     │
    └──────────────────────┬──────────────────────┘
                           │
    ┌──────────────────────▼──────────────────────┐
    │              poll phase (I/O)               │
    │   Retrieve new I/O events; execute I/O     │
    │   callbacks. If queue empty: block until   │
    │   next timer or setImmediate is ready.     │
    └──────────────────────┬──────────────────────┘
                           │
    ┌──────────────────────▼──────────────────────┐
    │              check phase                    │
    │         setImmediate() callbacks            │
    └──────────────────────┬──────────────────────┘
                           │
    ┌──────────────────────▼──────────────────────┐
    │          close callbacks phase              │
    │   socket.on('close') etc.                  │
    └──────────────────────┘
         └─ loops back to top

process.nextTick(cb): runs BEFORE the next phase (highest priority)
Promise.then(cb): runs in microtask queue, after nextTick

Priority order (high to low):
  1. process.nextTick callbacks
  2. Promise microtasks (resolved .then)
  3. setImmediate callbacks (check phase)
  4. setTimeout/setInterval callbacks (timers phase)
  5. I/O callbacks (poll phase)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Recognition) - Execution order:**

```javascript
// Understanding event loop execution order:
console.log('1: synchronous');

setTimeout(() => console.log('2: setTimeout 0ms'), 0);

Promise.resolve()
  .then(() => console.log('3: Promise microtask'));

process.nextTick(() => console.log('4: nextTick'));

setImmediate(() => console.log('5: setImmediate'));

console.log('6: synchronous end');

// Output:
// 1: synchronous
// 6: synchronous end
// 4: nextTick         <- runs BEFORE any other async
// 3: Promise microtask <- runs before setTimeout/setImmediate
// 2: setTimeout 0ms   <- timers phase
// 5: setImmediate     <- check phase

// Failure Example - blocking the event loop:
// BAD: synchronous CPU work blocks all callbacks:
function blockingWork() {
  const start = Date.now();
  while (Date.now() - start < 5000) {} // 5 second block
}

// During this 5 seconds, no I/O callbacks, no HTTP responses:
blockingWork(); // Server is completely frozen

// GOOD: yield to event loop for long work:
function nonBlockingWork(n, callback) {
  if (n <= 0) return callback();
  setImmediate(() => nonBlockingWork(n - 1, callback));
}
// setImmediate yields back to event loop each iteration
```

> **Code walkthrough:** The execution order reveals event loop priorities.
> Synchronous code always runs first (call stack). After the call stack
> clears, `process.nextTick` runs - this is the "between-phase" queue
> with highest async priority. Promise microtasks run next. Only then
> does the event loop advance to timers (setTimeout) and check
> (setImmediate) phases. The blocking work example shows the critical
> risk: a 5-second `while` loop freezes the entire event loop - no HTTP
> responses, no I/O callbacks, no timers fire. `setImmediate` in the
> non-blocking example yields control back to the event loop between
> iterations.

---

### ⚖️ Comparison Table

| Mechanism | When it runs | Priority |
|---|---|---|
| `process.nextTick` | Between every phase | Highest |
| `Promise.then` | Microtask queue | High |
| `setImmediate` | Check phase | Medium |
| `setTimeout(fn, 0)` | Timers phase | Low |
| I/O callbacks | Poll phase | Low |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> The event loop lets Node.js handle many tasks with one thread. It
> keeps looping through phases, picking up callbacks that are ready
> to run. `setTimeout` fires in the timers phase, file I/O callbacks
> in the poll phase. `process.nextTick` fires before any other async
> callback. If synchronous code runs for a long time, the loop is
> blocked and nothing else can execute.

**Senior / Staff:**

> The event loop is a cooperative multitasking scheduler. Key insight:
> all JavaScript is single-threaded, so callbacks don't preempt each
> other. This means you get atomic operations without locks, but it
> also means long-running synchronous work blocks everything. The
> microtask queue (nextTick, promises) is drained completely between
> each event loop phase - a recursively calling `nextTick` can starve
> the I/O phase entirely. In production, use `--inspect` with Chrome
> DevTools or `clinic.js` to detect event loop stalls.

---

### ⚠️ Common Misconceptions

**Misconception: `setTimeout(fn, 0)` runs immediately after current code.**

It runs after the current synchronous code AND after all microtasks
(nextTick and Promise chains). `setTimeout(fn, 0)` actually has a
minimum delay of ~1ms and runs in the timers phase - after `nextTick`
and resolved Promises have all executed.

---

### 🚨 Failure Modes and Diagnosis

**Failure: High event loop lag in production (slow requests, timeouts).**

Diagnose:
```bash
# measure event loop lag:
node -e "
  const start = Date.now();
  setImmediate(() => {
    const lag = Date.now() - start;
    console.log('Event loop lag:', lag, 'ms');
  });
"
# Acceptable: <10ms. Problem: >100ms. Critical: >500ms

# Use clinic.js for production profiling:
npm install -g clinic
clinic doctor -- node server.js
# clinic flame (flamegraph) for CPU hot spots
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Fix: Move CPU-intensive operations to Worker Threads.
Split large synchronous operations into chunks using `setImmediate`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What are the event loop phases? | Mechanism | ★★☆ | 3 min |
| `nextTick` vs `setImmediate` - difference? | Comparison | ★★☆ | 2 min |
| How do you detect event loop blocking? | Debugging | ★★☆ | 3 min |
| What happens when setImmediate is called from I/O? | Mechanism | ★★★ | 3 min |

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


# Callbacks and Error-first Pattern

---

### 🎯 Model Answer

**30 seconds:**

> Error-first callbacks (Node.js callbacks) are a convention: the first
> argument is always an error (null if success), the second is the result.
> `fs.readFile(path, (err, data) => { if (err) throw err; ... })`. This
> convention was established before Promises and allows consistent error
> handling across the Node.js ecosystem. All core Node.js async APIs
> follow this pattern. Modern code uses Promises and async/await, but
> understanding this pattern is essential for reading older code.

**Blank Mind Recovery:**

**(1) Signature:** "First arg: error (null if success). Second arg: data."

**(2) Why:** "Established before Promises. Consistent error handling."

**(3) Modern:** "Use async/await. Core fs.promises avoids callbacks."

---

### 📘 Concept Explanation

**What it is:**

A convention for asynchronous function signatures in Node.js:
`function callback(error, result)` where `error` is `null` on success
and an `Error` object on failure.

**How it works:**

```
Error-first callback convention:

  Pattern:
    asyncOperation(args, function(err, result) {
      if (err) {
        // handle error
        return;
      }
      // use result
    });

  Node.js core API example:
    const fs = require('fs');
    fs.readFile('data.txt', 'utf8', (err, data) => {
      if (err) {
        console.error('Read failed:', err.message);
        return;
      }
      console.log(data);
    });

  Callback hell (anti-pattern):
    fs.readFile('a.txt', (err, a) => {
      if (err) return handleError(err);
      fs.readFile('b.txt', (err, b) => {
        if (err) return handleError(err);
        fs.writeFile('c.txt', a + b, (err) => {
          if (err) return handleError(err);
          // 3 levels deep...
        });
      });
    });

  Modern equivalent (async/await):
    const { readFile, writeFile } = require('fs').promises;
    try {
      const a = await readFile('a.txt', 'utf8');
      const b = await readFile('b.txt', 'utf8');
      await writeFile('c.txt', a + b);
    } catch (err) {
      handleError(err);
    }
    // Same semantics, no nesting
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Wrong vs Right) - Error handling:**

```javascript
// BAD: not checking error argument:
fs.readFile('config.json', 'utf8', (err, data) => {
  // If file doesn't exist, err is set but we're parsing data
  // This throws an unrelated error hiding the real issue:
  const config = JSON.parse(data); // data is undefined!
});

// GOOD: always check err first:
fs.readFile('config.json', 'utf8', (err, data) => {
  if (err) {
    if (err.code === 'ENOENT') {
      console.log('Config file not found, using defaults');
      return;
    }
    throw err; // unexpected error
  }
  const config = JSON.parse(data);
});

// BAD: callback hell (pyramid of doom):
db.connect((err, client) => {
  client.query('SELECT * FROM users', (err, users) => {
    users.rows.forEach(user => {
      sendEmail(user.email, (err) => {
        // 3+ levels deep, error handling scattered
      });
    });
  });
});

// GOOD: promisify and flatten with async/await:
const { promisify } = require('util');
const connectAsync = promisify(db.connect.bind(db));

// Or use the native promises API:
const { readFile } = require('fs').promises;
const { Client } = require('pg'); // pg natively supports promises
```

> **Code walkthrough:** The first BAD example shows the most common
> mistake: ignoring the error argument. If the file doesn't exist, `err`
> is an `ENOENT` error and `data` is `undefined`. `JSON.parse(undefined)`
> throws "Unexpected token u in JSON" - a misleading error. Always check
> `err` first. The GOOD example handles the specific `ENOENT` code for
> missing files (a recoverable condition) and re-throws unexpected errors.
> `util.promisify` converts any error-first callback function to a
> Promise-returning function, enabling async/await usage with legacy APIs.

---

### ⚖️ Comparison Table

| Pattern | Readability | Error handling | Composability |
|---|---|---|---|
| Error-first callback | Poor (deep nesting) | Manual, scattered | Hard |
| Promises (.then) | Medium | Chain .catch | Medium |
| async/await | Excellent | try/catch | Excellent |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Error-first callbacks are a convention where the callback's first
> argument is an error. If null, the operation succeeded. I always
> check `if (err)` before using the result. Modern code uses
> async/await with `try/catch` instead.

**Senior / Staff:**

> Error-first callbacks were the original Node.js async pattern.
> They're still everywhere in older codebases and legacy npm packages.
> Key to remember: `util.promisify` converts them to Promises.
> For custom async libraries, use `util.callbackify` to go the other
> direction. The pattern's weakness isn't the convention itself but
> the nesting it causes when composing multiple async operations.
> Promises and async/await solve this at the syntax level.

---

### ⚠️ Common Misconceptions

**Misconception: Throwing inside a callback is safe.**

```javascript
// DANGEROUS - uncaught exception in async callback:
fs.readFile('file.txt', (err, data) => {
  throw new Error('something failed'); // crashes Node.js process!
});
// The try/catch wrapping readFile() does NOT catch this.
// Each callback runs in a new call stack context.

// SAFE: handle errors explicitly or use domains/
// async error boundaries:
process.on('uncaughtException', (err) => {
  console.error('Uncaught exception:', err);
  process.exit(1); // mandatory after uncaughtException
});
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `UnhandledPromiseRejectionWarning` in Node.js.**

Cause: Promise rejected but no `.catch()` or `try/catch` around `await`.

Fix:
```javascript
// Always handle promise rejections:
asyncOperation()
  .catch(err => console.error('Failed:', err));

// In Express: use async wrapper to forward errors:
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

app.get('/users', asyncHandler(async (req, res) => {
  const users = await db.getUsers(); // error forwarded to next(err)
  res.json(users);
}));
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is error-first callback convention? | Definition | ★☆☆ | 1 min |
| How do you convert callbacks to Promises? | Mechanism | ★★☆ | 2 min |
| What is callback hell and how to avoid it? | Pattern | ★★☆ | 3 min |
| Throw inside callback - why is it dangerous? | Failure | ★★☆ | 2 min |

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


# Node.js Module System (require vs import)

---

### 🎯 Model Answer

**30 seconds:**

> Node.js has two module systems: CommonJS (CJS) and ES Modules (ESM).
> CJS: `require()` and `module.exports` - the original, synchronous, 
> loads fully at require time. ESM: `import`/`export` - modern JavaScript
> standard, static analysis friendly, supports tree-shaking. To use ESM
> in Node.js: either use `.mjs` extension or set `"type": "module"` in
> `package.json`. CJS and ESM can coexist but mixing them requires care.
> New projects: use ESM. Legacy Node.js: CJS.

**Blank Mind Recovery:**

**(1) CJS:** "`require()` - sync, dynamic, original. `.cjs` or default."

**(2) ESM:** "`import` - static, tree-shakeable, modern. `.mjs` or `type:module`."

**(3) Interop rule:** "ESM can import CJS. CJS cannot `require()` ESM."

---

### 📘 Concept Explanation

**What it is:**

Two competing module systems in Node.js: the original CommonJS system
and the modern ECMAScript Modules standard.

**How they work:**

```
CommonJS (CJS):

  // math.js:
  function add(a, b) { return a + b; }
  module.exports = { add };       // single exports object
  // OR:
  module.exports.add = add;       // property on exports
  // OR:
  exports.add = add;              // shorthand (same ref as module.exports)

  // app.js:
  const { add } = require('./math');         // sync load
  const path = require('path');              // built-in
  const express = require('express');        // npm package
  const config = require('./config.json');   // JSON works!

  Key CJS behaviors:
    - require() is synchronous (blocks until module loads)
    - Cached after first load (same object on repeat require())
    - Dynamic: require() can be called anywhere, any time
    - module.exports evaluated when first required

ES Modules (ESM):

  // math.mjs (or .js with "type":"module"):
  export function add(a, b) { return a + b; }
  export const PI = 3.14159;
  export default class Calculator { ... }

  // app.mjs:
  import { add, PI } from './math.mjs';      // named imports
  import Calculator from './math.mjs';       // default import
  import * as math from './math.mjs';        // namespace import
  import data from './config.json'           // JSON with assert
    assert { type: 'json' };

  Key ESM behaviors:
    - Static analysis: imports resolved before execution
    - Async loading (Top-Level Await supported)
    - Tree-shakeable (bundlers eliminate unused exports)
    - .mjs extension OR "type":"module" in package.json
    - __dirname and __filename not available (use import.meta.url)
    - require() not available

  Interoperability:
    ESM can import CJS:   import cjsMod from './legacy.cjs'; ✓
    CJS cannot require ESM: require('./modern.mjs')          ✗ ERROR
    Workaround for CJS importing ESM:
      const { add } = await import('./modern.mjs'); // dynamic import

  File extensions (Node.js):
    .js:  inherits from package.json "type" (default: CJS)
    .cjs: always CommonJS
    .mjs: always ESM
    "type":"module" in package.json: .js files are ESM
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Wrong vs Right) - Module system choices:**

```javascript
// BAD: mixing CJS and ESM in the same project carelessly:
// package.json: "type": "module"
// But using require():
const express = require('express'); // SyntaxError! Not available in ESM

// GOOD: use import in ESM context:
import express from 'express';

// BAD: using __dirname in ESM (doesn't exist):
const config = require(path.join(__dirname, 'config.json')); // ReferenceError

// GOOD: use import.meta.url in ESM:
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const config = JSON.parse(
  await readFile(join(__dirname, 'config.json'), 'utf8')
);

// Practical decision guide:
// New project? -> ESM ("type":"module" in package.json)
// Library publishing? -> dual CJS+ESM build (using tsup or rollup)
// Existing CJS codebase? -> migrate gradually:
//   1. Rename key files to .mjs
//   2. Convert require() to import
//   3. Set "type":"module" when fully migrated
```

> **Code walkthrough:** `import.meta.url` is the ESM equivalent of
> `__filename` in CJS. It contains the URL of the current module
> (e.g., `file:///app/src/server.js`). `fileURLToPath` converts it
> to a regular file system path. `dirname()` extracts the directory.
> This pattern replaces the CJS `__dirname` pattern when using ESM.
> The "dual package" pattern (libraries that export both CJS and ESM)
> uses the `exports` field in `package.json` to route CJS `require()`
> calls to `./dist/index.cjs` and ESM `import` to `./dist/index.mjs`.

---

### ⚖️ Comparison Table

| Feature | CommonJS | ES Modules |
|---|---|---|
| Syntax | `require()` / `module.exports` | `import` / `export` |
| Loading | Synchronous | Static + async |
| Dynamic imports | Any expression | `import()` function |
| Tree-shaking | No | Yes |
| `__dirname` | Yes | Use `import.meta.url` |
| Top-Level Await | No | Yes |
| Use in browsers | No (needs bundler) | Yes (native) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> CJS uses `require()` and `module.exports`, ESM uses `import` and
> `export`. To enable ESM in Node.js I set `"type": "module"` in
> `package.json` or use `.mjs` extension. ESM is the modern standard;
> new projects should use it. Old projects use CJS.

**Senior / Staff:**

> The key architectural difference: CJS is evaluated lazily (synchronous
> require at runtime), ESM is statically analyzed (imports resolved
> before any code runs). This makes ESM tree-shakeable - bundlers can
> eliminate unused exports. The interop rule is critical: ESM can
> statically import CJS packages (they're wrapped as default exports),
> but CJS cannot `require()` ESM because ESM evaluation is asynchronous.
> Use dynamic `import()` in CJS to import ESM. Publishing libraries
> today means shipping dual CJS+ESM builds.

---

### ⚠️ Common Misconceptions

**Misconception: `export default` is the same as `module.exports`.**

When ESM with a default export is imported in CJS context, it
becomes `require('module').default`, not `require('module')`. This
breaks when CJS users do `const thing = require('your-package')`.
Libraries must either use named exports or provide a dual package
build that maps correctly.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `ERR_REQUIRE_ESM` - cannot require ESM module.**

```
Error [ERR_REQUIRE_ESM]: require() of ES Module not supported
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Cause: Package has `"type": "module"` or is an `.mjs` file, and
consumer is using `require()`.

Fix options:
1. Convert consumer to ESM: `import` instead of `require()`
2. Use dynamic import: `const mod = await import('esm-package')`
3. Find CJS-compatible version or alternative package
4. Use `create-require` (very legacy workaround)

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| CommonJS vs ESM - key differences? | Comparison | ★★☆ | 3 min |
| How do you enable ESM in Node.js? | Definition | ★☆☆ | 1 min |
| Why can't CJS `require()` an ESM module? | Mechanism | ★★★ | 3 min |
| What is `import.meta.url`? | Definition | ★★☆ | 2 min |
| What is tree-shaking and why does it need ESM? | Mechanism | ★★☆ | 2 min |

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



