---
layout: default
title: "Node.js - L2 Async Patterns"
parent: "Node.js"
nav_order: 4
permalink: /nodejs/l2-async-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Promises and async/await in Node.js](#promises-and-asyncawait-in-nodejs) | medium |
| 2 | [Event Emitter Pattern](#event-emitter-pattern) | medium |

---

# Promises and async/await in Node.js

---

### 🎯 Model Answer

**30 seconds:**

> Promises represent an eventual value - resolved or rejected. async/await
> is syntactic sugar over Promises that makes async code look synchronous.
> `async` marks a function that returns a Promise. `await` pauses
> execution of that function until the Promise resolves (but does NOT
> block the thread - the event loop continues). Key: `await` only works
> inside `async` functions. For concurrent operations: `Promise.all()`
> for parallel, `Promise.allSettled()` when you need all results
> regardless of failures. Never use `await` in loops for sequential
> operations that should be parallel.

**3 minutes:**

Promises fix the fundamental problem with callbacks: composition. With
callbacks, three sequential async operations require three levels of
nesting. With Promises, they chain. With async/await, they look sequential.

**Critical Node.js-specific patterns:**

1. **Top-level await** (ESM only): `await` at module level without
   async wrapper. Node.js 14.8+ supports it in `.mjs` files.

2. **Promise.all vs Promise.allSettled**:
   - `Promise.all`: rejects immediately if ANY promise rejects
   - `Promise.allSettled`: waits for all, returns array of
     `{status: 'fulfilled'|'rejected', value|reason}`

3. **Async error propagation**: unhandled rejections terminate the
   process in Node.js 15+. Always catch.

4. **util.promisify**: converts error-first callbacks to Promises.

**Blank Mind Recovery:**

**(1) `async` function:** "Always returns a Promise. `return value` =
resolved. `throw` = rejected."

**(2) `await`:** "Pauses async function. Event loop continues. Resumes
when Promise settles."

**(3) Parallel:** "`Promise.all([p1, p2])` - run concurrently, wait
for all. Fail-fast."

---

### 📘 Concept Explanation

**What it is:**

A composable system for representing and handling asynchronous operations:
Promises as the data type, async/await as the syntax.

**How it works:**

```
Promise states and transitions:

  pending -> fulfilled (resolved value)
          -> rejected (error reason)

  Once settled (fulfilled or rejected), state never changes.

  Creating Promises:
    new Promise((resolve, reject) => {
      fs.readFile(path, (err, data) => {
        if (err) reject(err);
        else resolve(data);
      });
    });

  Chaining:
    fetchUser(id)
      .then(user => fetchOrders(user.id))
      .then(orders => processOrders(orders))
      .catch(err => handleError(err))
      .finally(() => cleanup());

  async/await equivalent:
    try {
      const user = await fetchUser(id);
      const orders = await fetchOrders(user.id);  // sequential!
      await processOrders(orders);
    } catch (err) {
      handleError(err);
    } finally {
      cleanup();
    }

  Parallel patterns:
    // Sequential (slow): each awaits before starting next
    const a = await fetchA();
    const b = await fetchB(); // starts only after A completes

    // Parallel (fast): all start at once
    const [a, b] = await Promise.all([fetchA(), fetchB()]);

    // Parallel with individual error handling:
    const results = await Promise.allSettled([
      fetchA(), fetchB(), fetchC()
    ]);
    // [{status:'fulfilled', value:...},
    //  {status:'rejected', reason:...}, ...]

  Async iteration:
    // Process stream pages lazily:
    for await (const page of paginatedAPI()) {
      await processPage(page);
    }
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Wrong vs Right) - Common async mistakes:**

```javascript
// BAD: sequential await in loop (each waits for previous):
async function fetchAllUsersBad(userIds) {
  const users = [];
  for (const id of userIds) {
    const user = await fetchUser(id); // sequential, slow
    users.push(user);
  }
  return users;
  // 100 users * 200ms each = 20 seconds total
}

// GOOD: parallel with Promise.all:
async function fetchAllUsersGood(userIds) {
  return Promise.all(userIds.map(id => fetchUser(id)));
  // All 100 requests fire simultaneously
  // 100 users * 200ms = ~200ms total
}

// BAD: missing await causes fire-and-forget:
async function saveUser(user) {
  db.update(user);  // missing await! Error is silently lost
  return 'saved';   // returns before DB operation completes
}

// GOOD: always await async operations:
async function saveUser(user) {
  await db.update(user);
  return 'saved';
}

// BAD: unhandled rejection (crashes Node.js 15+):
someAsyncOperation(); // rejected promise, no catch

// GOOD: always handle:
someAsyncOperation().catch(err => logger.error(err));

// Production pattern: async route handler in Express:
// BAD: async errors not forwarded to Express error handler:
app.get('/user/:id', async (req, res) => {
  const user = await db.getUser(req.params.id); // throws -> crashes!
  res.json(user);
});

// GOOD: wrap async handlers:
const asyncRoute = fn => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

app.get('/user/:id', asyncRoute(async (req, res) => {
  const user = await db.getUser(req.params.id);
  res.json(user);
}));
```

> **Code walkthrough:** The sequential vs parallel loop pattern is one
> of the most common Node.js performance bugs. `await` inside a `for...of`
> loop makes each request wait for the previous to complete. `Promise.all`
> launches all requests concurrently and waits for all to settle. For
> 100 requests each taking 200ms: sequential = 20 seconds, parallel =
> ~200ms. The Express async wrapper is non-negotiable: `async` route
> handlers that throw rejections don't automatically forward to Express's
> error handler (`next(err)`). Without the wrapper, unhandled rejections
> in route handlers will crash Node.js 15+.

---

### ⚖️ Comparison Table

| Pattern | Use case | Behavior on failure |
|---|---|---|
| `Promise.all` | All must succeed | Rejects immediately |
| `Promise.allSettled` | Need all results | Never rejects |
| `Promise.race` | First to settle wins | First result/error |
| `Promise.any` | First success | Rejects if all fail |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> async/await lets me write async code that looks synchronous. I put
> `async` before the function and `await` before async operations.
> Errors go in `try/catch`. For parallel operations, `Promise.all([])`
> runs them all at once and waits for all to complete.

**Senior / Staff:**

> Key mental models: `async` functions always return Promises, even
> if you return a primitive value. `await` suspends the async function
> but yields control to the event loop. The parallel vs sequential
> await in loops is the most frequent performance bug in Node.js code
> reviews. `Promise.allSettled` is underused - use it when partial
> failure is acceptable. In Express/Fastify, the async handler wrapper
> pattern is standard. For streaming data, `for await...of` with async
> generators provides a clean backpressure-aware consumption pattern.

---

### ⚠️ Common Misconceptions

**Misconception: `await` makes JavaScript single-threaded blocking.**

`await` pauses the current async function but does NOT block the
thread. The event loop continues processing other callbacks during
the wait. It's cooperative suspension - the function "yields" control
until the Promise resolves. True blocking is synchronous code like
`while(true){}` or `fs.readFileSync()`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `UnhandledPromiseRejection` terminates the process.**

Node.js 15+ terminates the process on unhandled promise rejections
by default (exit code 1). This is the correct behavior but surprises
developers migrating from Node.js 14.

Fix:
```javascript
// Global handler for unhandled rejections (last resort):
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection:', reason);
  // Log and exit gracefully:
  process.exit(1);
});
// Better: fix the root cause by adding .catch() or try/catch
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is a Promise? | Definition | ★☆☆ | 1 min |
| async/await vs Promise.then - difference? | Comparison | ★★☆ | 2 min |
| Sequential await in loop - what's wrong? | Failure | ★★☆ | 3 min |
| `Promise.all` vs `Promise.allSettled`? | Comparison | ★★☆ | 2 min |
| How do you handle async errors in Express? | Production | ★★★ | 3 min |
| What is top-level await? | Mechanism | ★★☆ | 2 min |
| Does `await` block the event loop? | Mechanism | ★★★ | 3 min |

**Q: How do you limit concurrency in a Promise.all pattern?**

A: Without limits, `Promise.all(items.map(processItem))` fires all
promises simultaneously. For 10,000 items, this means 10,000 concurrent
DB connections or HTTP requests.

Limiting concurrency:
```javascript
import pLimit from 'p-limit';

const limit = pLimit(10); // max 10 concurrent
const results = await Promise.all(
  items.map(item => limit(() => processItem(item)))
);
// Only 10 items process simultaneously
// When one completes, the next queued item starts
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Understanding that `pLimit` uses
a queue internally. When a slot frees up, the next queued function
starts immediately. This is more efficient than batching
(processing 10 at a time, waiting for all 10, then the next 10) because
it never leaves slots idle.

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


# Event Emitter Pattern

---

### 🎯 Model Answer

**30 seconds:**

> EventEmitter is Node.js's built-in publish/subscribe pattern.
> An emitter emits named events; listeners are functions registered
> for those events. Key class: `EventEmitter` from 'events' module.
> Usage: `emitter.on('event', handler)` to subscribe,
> `emitter.emit('event', data)` to publish. Most Node.js core APIs
> (streams, HTTP server, child processes) extend EventEmitter. Key
> pitfall: more than 10 listeners on one event triggers a memory
> leak warning. Use `emitter.once()` for one-time handlers.

**Blank Mind Recovery:**

**(1) Pattern:** "Pub/sub. Emitter publishes named events. Listeners subscribe."

**(2) Key methods:** "`on(event, fn)` = subscribe. `emit(event, data)` = publish.
`once(event, fn)` = one-time. `off(event, fn)` = unsubscribe."

**(3) Pitfall:** "More than 10 listeners = memory leak warning. Use `off()`
to clean up. Always call `once` for request-scoped listeners."

---

### 📘 Concept Explanation

**What it is:**

An implementation of the observer pattern built into Node.js. Objects
that emit events extend `EventEmitter` and fire named events that
registered handlers respond to.

**How it works:**

```
EventEmitter mechanics:

  Basic usage:
    import { EventEmitter } from 'events';

    class OrderService extends EventEmitter {
      async placeOrder(order) {
        const result = await db.save(order);
        this.emit('order:placed', result);   // fire event
        return result;
      }

      async cancelOrder(orderId) {
        await db.cancel(orderId);
        this.emit('order:cancelled', { orderId }); // fire event
      }
    }

    const orders = new OrderService();

    // Subscribe:
    orders.on('order:placed', (order) => {
      sendEmail(order.userId, 'Order confirmed');
    });

    orders.on('order:placed', (order) => {
      analytics.track('order_placed', order);
    });

    orders.once('order:placed', (order) => {
      // fires only for first order, then unsubscribes
    });

    // Unsubscribe:
    const handler = (order) => doSomething(order);
    orders.on('order:placed', handler);
    orders.off('order:placed', handler); // remove specific handler

  Error events (special handling):
    emitter.emit('error', new Error('something failed'));
    // If no 'error' listener: throws and crashes Node.js!
    // Always register error listener:
    emitter.on('error', (err) => console.error(err));

  Event list (inspection):
    emitter.eventNames()      // ['order:placed', 'order:cancelled']
    emitter.listenerCount('order:placed')  // 2

  Memory leak prevention:
    // Default max listeners: 10
    // Changing the limit:
    emitter.setMaxListeners(20);
    // Or globally: EventEmitter.defaultMaxListeners = 20
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Production) - Request tracking with EventEmitter:**

```javascript
import { EventEmitter } from 'events';
import http from 'http';

class RequestTracker extends EventEmitter {
  #activeRequests = new Map();

  trackRequest(req, res) {
    const id = crypto.randomUUID();
    const startTime = Date.now();

    this.#activeRequests.set(id, { req, startTime });
    this.emit('request:start', { id, url: req.url });

    res.on('finish', () => {
      const duration = Date.now() - startTime;
      this.#activeRequests.delete(id);
      this.emit('request:complete', {
        id, url: req.url,
        status: res.statusCode, duration
      });
    });
  }

  getActiveCount() {
    return this.#activeRequests.size;
  }
}

const tracker = new RequestTracker();

// Log slow requests:
tracker.on('request:complete', ({ url, duration, status }) => {
  if (duration > 1000) {
    console.warn(`Slow request: ${url} ${duration}ms`);
  }
});

// BAD: memory leak - listener added per request, never removed:
http.createServer((req, res) => {
  tracker.on('request:complete', (data) => {
    // this listener is added for EVERY request and never removed!
    // After 10 requests: MaxListenersExceeded warning
    if (data.id === currentId) { /* ... */ }
  });
});

// GOOD: use once() or move listener outside request scope:
http.createServer((req, res) => {
  const id = crypto.randomUUID();
  tracker.once(`request:${id}:complete`, handleComplete);
  // OR: use named function and off() in cleanup
});
```

> **Code walkthrough:** `RequestTracker` extends `EventEmitter` and
> uses private class fields (`#activeRequests`) to track state. Events
> decouple the tracking logic from the response logic - the HTTP layer
> doesn't know about logging or analytics. The memory leak example shows
> the classic pattern: adding a listener inside a request handler means
> a new listener is registered for every incoming request. After 10
> requests, Node.js emits a `MaxListenersExceeded` warning. After
> thousands, the listeners array consumes significant memory. The fix
> is to use `once()` for request-scoped handlers, or - better - define
> long-lived listeners outside the request handler.

---

### ⚖️ Comparison Table

| Pattern | Coupling | Use case |
|---|---|---|
| EventEmitter | Loose (pub/sub) | Within same process, many listeners |
| Callbacks | Direct | Single consumer, one-time |
| Promises | Direct | One-time async result |
| Message queue | Decoupled | Cross-process, distributed |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> EventEmitter is Node.js's pub/sub system. I can emit named events with
> data and other parts of my code subscribe with `on()`. It decouples
> the publisher from subscribers. Core Node.js APIs like streams and
> the HTTP server use it. I use `once()` for one-time handlers and
> `off()` to avoid memory leaks.

**Senior / Staff:**

> EventEmitter is excellent for within-process event broadcasting
> where multiple listeners react to the same event. Key design rule:
> always register an 'error' event listener on EventEmitters - an
> emitted 'error' with no listener throws and crashes the process.
> Memory leaks from EventEmitter are a production reality: every `on()`
> inside a request handler creates a permanent listener. The `MaxListeners`
> warning is the symptom. For cross-service events, EventEmitter is
> inappropriate - use a message queue (Kafka, RabbitMQ).

---

### ⚠️ Common Misconceptions

**Misconception: EventEmitter events are asynchronous.**

`emit()` is synchronous: all listeners for the event run synchronously
before `emit()` returns. If you need async listeners, you must handle
that yourself (call async functions inside the listener but don't
`await` them, or use a dedicated async event system).

---

### 🚨 Failure Modes and Diagnosis

**Failure: `MaxListenersExceededWarning` in production logs.**

Cause: Listeners are being added repeatedly without being removed.
Common pattern: `emitter.on()` called inside a loop or request handler.

Diagnose:
```javascript
// Find which events have too many listeners:
emitter.eventNames().forEach(event => {
  const count = emitter.listenerCount(event);
  if (count > 5) {
    console.warn(`Event ${event} has ${count} listeners`);
  }
});
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Fix: Use `once()` for one-time handlers. Use `off()` in cleanup.
Move persistent listeners outside the hot path.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is EventEmitter? | Definition | ★☆☆ | 1 min |
| `on()` vs `once()` - difference? | Comparison | ★☆☆ | 1 min |
| What is the 'error' event special behavior? | Mechanism | ★★☆ | 2 min |
| Memory leak from EventEmitter - how? | Failure | ★★☆ | 3 min |
| Is `emit()` synchronous or asynchronous? | Mechanism | ★★★ | 2 min |
| EventEmitter vs message queue - when to use? | Decision | ★★★ | 3 min |

**Q: How would you implement a typed EventEmitter in TypeScript?**

A:
```typescript
import { EventEmitter } from 'events';

interface OrderEvents {
  'order:placed': [order: Order];
  'order:cancelled': [orderId: string, reason: string];
}

class TypedEmitter<T extends Record<string, unknown[]>>
  extends EventEmitter {
  emit<K extends keyof T>(event: K, ...args: T[K]): boolean {
    return super.emit(event as string, ...args);
  }
  on<K extends keyof T>(
    event: K, listener: (...args: T[K]) => void
  ): this {
    return super.on(event as string, listener);
  }
}

class OrderService
  extends TypedEmitter<OrderEvents> { ... }
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* TypeScript inference on event
names and payloads catches typos and mismatched handler signatures
at compile time. The `eventemitter3` npm package provides a
TypeScript-first typed emitter with better performance than the
built-in one.

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



