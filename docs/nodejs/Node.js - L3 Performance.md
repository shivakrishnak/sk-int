---
layout: default
title: "Node.js - L3 Performance"
parent: "Node.js"
nav_order: 7
permalink: /nodejs/l3-performance/
---

# Node.js Performance Profiling

---

### 🎯 Model Answer

**30 seconds:**

> Node.js profiling identifies what's slow: CPU hotspots, memory leaks,
> event loop blocking. Three tools: `--prof` (built-in V8 profiler,
> flamegraph), Node.js inspector (`--inspect`, Chrome DevTools),
> `clinic.js` (automated doctor/flame/bubbleprof). For production:
> `0x` generates interactive flamegraphs. Process: detect symptom
> (high CPU, slow requests, growing memory) -> choose tool -> analyze
> output -> find bottleneck -> fix and verify.

**3 minutes:**

Performance problems in Node.js fall into three categories:

1. **CPU-bound**: JavaScript executing too much synchronously
   - Symptom: event loop lag, all requests slow uniformly
   - Tool: flamegraph (0x, clinic flame)
   - Fix: optimize algorithm, offload to worker threads

2. **I/O-bound**: waiting for slow databases or external services
   - Symptom: high response times, low CPU
   - Tool: distributed tracing (OpenTelemetry)
   - Fix: add caching, connection pooling, parallel queries

3. **Memory**: leaks or excessive GC pauses
   - Symptom: memory grows, periodic latency spikes
   - Tool: heap snapshots (Chrome DevTools)
   - Fix: find and fix the leak

**Blank Mind Recovery:**

**(1) Three problem types:** "CPU (too much computation), I/O (waiting),
Memory (leaks or GC pressure)."

**(2) Key tools:** "`0x` for flamegraphs, `--inspect` for DevTools,
`clinic.js` for automated diagnosis."

**(3) Process:** "Measure first. No optimizing without data."

---

### 📘 Concept Explanation

**What it is:**

A systematic approach to identifying and fixing performance bottlenecks
in Node.js applications using built-in and third-party profiling tools.

**How it works:**

```
Profiling tools and what they reveal:

  1. Built-in V8 profiler (--prof):
     node --prof server.js
     # Run load test, then:
     node --prof-process isolate-*.log > profile.txt
     # Shows: ticks per function, percentage of CPU time
     # Reveals: hot functions in JavaScript + V8 internals

  2. Node.js Inspector (Chrome DevTools):
     node --inspect server.js
     # Open chrome://inspect in Chrome
     # Features: CPU profiler, heap snapshots, live debugging

  3. 0x (interactive flamegraphs):
     npm install -g 0x
     0x server.js &
     # Run load test, then Ctrl+C
     # Opens interactive SVG flamegraph in browser

  4. clinic.js (automated diagnosis):
     npm install -g clinic
     clinic doctor -- node server.js
     # Runs test, analyzes event loop, I/O, CPU
     # Produces HTML report with recommendations
     clinic flame -- node server.js  # flamegraph
     clinic bubbleprof -- node server.js  # async profiler

  5. Performance hooks (built-in):
     const { performance, PerformanceObserver } = require(
       'perf_hooks'
     );
     performance.mark('start-parse');
     parseData(input);
     performance.mark('end-parse');
     performance.measure('parse', 'start-parse', 'end-parse');
     const [entry] = performance.getEntriesByName('parse');
     console.log('Parse time:', entry.duration, 'ms');

  Event loop lag measurement:
     let lastTick = Date.now();
     setInterval(() => {
       const now = Date.now();
       const lag = now - lastTick - 100; // expected 100ms
       if (lag > 50) {
         console.warn('Event loop lag:', lag, 'ms');
       }
       lastTick = now;
     }, 100);
```

---

### 💻 Code Example

**Example (Debugging) - Finding and fixing a performance bottleneck:**

```javascript
// Symptom: /api/search endpoint takes 2-5 seconds.
// Profiling with performance.mark reveals:

import { performance } from 'perf_hooks';

app.get('/api/search', asyncRoute(async (req, res) => {
  performance.mark('search-start');

  const { q } = req.query;

  performance.mark('db-start');
  const results = await db.search(q);
  performance.mark('db-end');

  performance.mark('filter-start');
  const filtered = results.filter(r => r.score > 0.5); // synchronous
  performance.mark('filter-end');

  performance.mark('format-start');
  const formatted = results.map(r => formatResult(r)); // synchronous
  performance.mark('format-end');

  performance.measure('db-query', 'db-start', 'db-end');
  performance.measure('filter', 'filter-start', 'filter-end');
  performance.measure('format', 'format-start', 'format-end');

  // Output reveals: db=50ms, filter=1800ms, format=200ms
  // filter() on 50,000 results is the bottleneck!
}));

// Fix 1: filter at DB level:
const results = await db.search(q, { minScore: 0.5 });

// Fix 2: if filter must be in-process, push to worker:
const filtered = await pool.run({ results, minScore: 0.5 });

// Fix 3: cache expensive computations:
import NodeCache from 'node-cache';
const cache = new NodeCache({ stdTTL: 300 }); // 5 min TTL

app.get('/api/search', asyncRoute(async (req, res) => {
  const cacheKey = `search:${req.query.q}`;
  const cached = cache.get(cacheKey);
  if (cached) {
    return res.json(cached);
  }
  const results = await expensiveSearch(req.query.q);
  cache.set(cacheKey, results);
  res.json(results);
}));
```

> **Code walkthrough:** `performance.mark` and `performance.measure`
> instrument code without external tools. This identifies the bottleneck
> is in the `filter()` call, not the database query. 50,000 synchronous
> filter operations blocking the event loop is the root cause. Three
> fixes in order of effectiveness: push the filter to the database
> (SQL `WHERE score > 0.5`), offload to worker threads (for complex
> in-process filtering), or cache results. The caching fix avoids
> redundant computation for repeated queries - the most impactful fix
> for search endpoints where the same queries repeat.

---

### ⚖️ Comparison Table

| Tool | Best for | Overhead | Setup |
|---|---|---|---|
| `--prof` + flamegraph | CPU hotspots | Medium | Low |
| Chrome DevTools | Interactive debugging | High | Low |
| `0x` | Production profiling | Medium | Low |
| `clinic.js` | Automated diagnosis | Medium | Low |
| `perf_hooks` | Specific measurement | Minimal | Code changes |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I use Chrome DevTools with `--inspect` for local profiling - it shows
> a CPU timeline and heap snapshots. `clinic.js` gives automated
> recommendations. For measuring specific code, `performance.mark/measure`
> from `perf_hooks` is built-in. The rule: measure first, optimize second.

**Senior / Staff:**

> Production profiling requires low-overhead tools. `0x` is good for
> short-lived profiles. For continuous monitoring, expose event loop lag
> metrics (how long between event loop ticks) as a Prometheus gauge.
> Flamegraphs reveal CPU hotspots but not I/O latency - for I/O profiling,
> `clinic bubbleprof` visualizes async timing. The most impactful
> optimization is usually moving CPU work to worker threads or pushing
> filtering/sorting to the database.

---

### ⚠️ Common Misconceptions

**Misconception: High CPU means Node.js is doing CPU-bound work.**

High CPU can also be caused by excessive serialization/deserialization
(JSON.parse/stringify on large objects), regular expression backtracking
(catastrophic regex on untrusted input), or V8 deoptimization of
hot functions (caused by inconsistent object shapes - hidden class
pollution).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Response times spike periodically (every few minutes).**

Cause: Likely GC pressure - V8's garbage collector pauses all JavaScript
execution during major GC cycles.

Diagnose:
```bash
node --expose-gc --trace-gc server.js
# Shows GC events and pause duration
# Example:
# [11] Heap::GarbageCollectionPrologue
# [11] 12 ms: Scavenge 45.1 (51.0) -> 43.4 (51.5) MB
# [11] 485 ms: Mark-sweep 120 MB -> 85 MB

# Prometheus metric for GC pauses:
import { monitorEventLoopDelay } from 'perf_hooks';
const h = monitorEventLoopDelay({ resolution: 20 });
h.enable();
setInterval(() => {
  console.log('p99 lag:', h.percentile(99) / 1e6, 'ms');
}, 5000);
```

Fix: Reduce object allocation rate, use Buffer pools, use
streaming instead of building large arrays.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How do you profile a Node.js app? | Mechanism | ★★☆ | 3 min |
| What causes event loop blocking? | Mechanism | ★★☆ | 2 min |
| How do you read a flamegraph? | Debugging | ★★★ | 3 min |
| Periodic latency spikes - what's causing it? | Debugging | ★★★ | 3 min |
| How do you measure performance without external tools? | Code | ★★☆ | 2 min |

---

# Memory Management in Node.js

---

### 🎯 Model Answer

**30 seconds:**

> Node.js uses V8's garbage collector. Memory is divided into young
> generation (new objects, frequent minor GC) and old generation (long-lived
> objects, infrequent major GC). Memory leaks happen when references
> to objects are accidentally retained - common causes: closures holding
> large data, global variables, EventEmitter listeners not removed,
> unbounded caches, timers not cleared. To diagnose: heap snapshot
> before/after suspected operation - compare what grew. Use Chrome DevTools
> or `v8.writeHeapSnapshot()`.

**Blank Mind Recovery:**

**(1) Causes of leaks:** "Uncleared closures, global vars, EventEmitter
listeners not removed, caches without limits, timers not cleared."

**(2) Diagnose:** "Heap snapshots: take two, compare. What grew?"

**(3) Tool:** "`v8.writeHeapSnapshot()` or Chrome DevTools Heap tab."

---

### 📘 Concept Explanation

**What it is:**

V8's memory model for Node.js: automatic garbage collection of
unreachable objects, with two generations optimized for different
object lifetimes.

**How it works:**

```
V8 memory structure:

  Young generation (nursery):
    - New objects allocated here
    - Small (~32-64MB by default)
    - Scavenge GC: frequent, fast (~1-2ms)
    - Objects that survive 2 collections: promoted to old gen

  Old generation (tenured):
    - Long-lived objects
    - Larger (configurable with --max-old-space-size)
    - Mark-sweep GC: infrequent, can cause pauses (10-500ms)
    - What most "heap memory" metrics measure

  Heap limits:
    Default old generation: ~1.5GB (64-bit systems)
    Change: node --max-old-space-size=4096 server.js  # 4GB

  Common memory leaks:

    1. Closures holding large data:
       function processRequest(data) {
         const largeBuffer = Buffer.alloc(100 * 1024 * 1024);
         // largeBuffer captured in closure:
         return function cleanup() {
           console.log(largeBuffer.length); // prevents GC
         };
       }

    2. Global variable accumulation:
       global.cache = {};
       app.use((req) => {
         global.cache[req.url] = req.body; // grows forever!
       });

    3. EventEmitter leak:
       setInterval(() => {
         emitter.on('data', processData); // never removed!
         // After each interval: +1 permanent listener
       }, 1000);

    4. Circular references (usually handled by GC):
       const a = {}; const b = { ref: a }; a.ref = b;
       // Modern V8 handles this; old code may assume it doesn't

    5. Timer not cleared:
       function setupConnection() {
         const healthCheck = setInterval(
           () => checkHealth(), 1000
         );
         // connection.close() never calls clearInterval(healthCheck)
         // interval keeps running, keeps closure alive
       }
```

---

### 💻 Code Example

**Example (Debugging) - Finding a memory leak:**

```javascript
import v8 from 'v8';
import path from 'path';

// Take heap snapshot programmatically:
function takeHeapSnapshot(label) {
  const filename = `heap-${label}-${Date.now()}.heapsnapshot`;
  v8.writeHeapSnapshot(filename);
  console.log('Heap snapshot:', filename);
  return filename;
}

// Diagnose a leak:
takeHeapSnapshot('before');
// ... run the operation suspected of leaking 100 times ...
for (let i = 0; i < 100; i++) {
  await suspectedOperation();
}
takeHeapSnapshot('after');
// Load both files in Chrome DevTools Memory tab
// Use "Comparison" view to see what grew

// LRU cache instead of unbounded Map (prevents leak):
import { LRUCache } from 'lru-cache';

const cache = new LRUCache({
  max: 1000,        // max 1000 entries
  ttl: 1000 * 300,  // 5 minute TTL
  maxSize: 50 * 1024 * 1024, // 50MB max
  sizeCalculation: (value) => JSON.stringify(value).length
});

// Memory usage monitoring:
function logMemory() {
  const { rss, heapUsed, heapTotal, external } =
    process.memoryUsage();
  console.log({
    rss: `${(rss / 1024 / 1024).toFixed(1)} MB`,
    heap: `${(heapUsed / 1024 / 1024).toFixed(1)} MB`,
    heapTotal: `${(heapTotal / 1024 / 1024).toFixed(1)} MB`
  });
}
setInterval(logMemory, 30000); // log every 30s

// rss: Resident Set Size - total memory allocated to process
// heapUsed: JS objects currently in heap
// heapTotal: heap committed to V8 (may be larger than heapUsed)
// external: C++ objects bound to JS (Buffers)
```

> **Code walkthrough:** `v8.writeHeapSnapshot` dumps the current heap
> state to a `.heapsnapshot` file. Loading two snapshots in Chrome
> DevTools "Memory" tab and using the "Comparison" view shows which
> object types grew between snapshots - the ones with the most retained
> size are leak candidates. `LRUCache` solves the unbounded cache problem:
> it evicts the Least Recently Used entries when the max size is reached,
> bounding memory usage. `process.memoryUsage()` is the lightweight
> monitoring tool: `heapUsed` growing linearly over time is the classic
> leak signature; `rss` growing is more severe (OS-level memory not freed).

---

### ⚖️ Comparison Table

| Memory metric | What it measures | Leak indicator |
|---|---|---|
| `heapUsed` | Live JS objects | Growing over time |
| `heapTotal` | V8 heap committed | Growing, doesn't shrink |
| `rss` | Total process memory | Growing = severe |
| `external` | Buffer, C++ objects | Growing = Buffer leak |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Memory leaks in Node.js happen when objects are referenced somewhere
> and can't be garbage collected. Common causes: EventEmitter listeners
> not removed, caches without limits, timers not cleared. I diagnose
> with heap snapshots and look for what grew. I monitor `process.memoryUsage().heapUsed`
> as a metric.

**Senior / Staff:**

> V8's GC is generational: minor GCs happen frequently on the young
> generation and are fast. Major GC (mark-sweep on old generation) is
> infrequent but can pause for 10-500ms - this is what causes the
> periodic latency spikes. Tuning: `--max-old-space-size` sets the heap
> limit; V8 starts major GC when the heap approaches this limit.
> For bounded caches, `lru-cache` is standard. WeakMaps and WeakRefs
> are the correct tool for caches where you want GC to reclaim entries
> when nothing else holds a reference.

---

### ⚠️ Common Misconceptions

**Misconception: `delete obj.property` frees memory.**

`delete` removes the property from the object but doesn't guarantee
GC of the value. Memory is freed when the GC determines the value
has no more references. Setting the property to `null` (`obj.property = null`)
explicitly removes the reference, making the old value eligible for GC.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `FATAL ERROR: Reached heap limit Allocation failed`**

Cause: Heap exceeded `--max-old-space-size` limit (default ~1.5GB).

Diagnose: Take heap snapshot just before OOM. Look at top retained
objects. Common culprits: `Map`/`Set` accumulating entries, large
arrays not freed, connection pools not released.

Fix (short-term): `node --max-old-space-size=4096 server.js`
Fix (permanent): Find and fix the leak.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is a memory leak in Node.js? | Definition | ★☆☆ | 2 min |
| How do you diagnose a memory leak? | Debugging | ★★★ | 4 min |
| What are common causes of memory leaks? | Pattern | ★★☆ | 3 min |
| What is `process.memoryUsage()`? | Mechanism | ★★☆ | 2 min |
| `heapUsed` vs `rss` - difference? | Comparison | ★★★ | 2 min |
| How does V8 garbage collection work? | Mechanism | ★★★ | 4 min |

**Q: How would you diagnose a memory leak in a production Node.js service?**

A:

Step 1 - Confirm the leak: monitor `process.memoryUsage().heapUsed`
over time. If it grows linearly and doesn't decrease during low traffic,
that's a leak.

Step 2 - Trigger GC manually (for baseline):
```javascript
if (global.gc) global.gc(); // requires --expose-gc flag
```
If memory drops significantly after GC, objects were reachable.
If memory doesn't drop, objects are still referenced somewhere.

Step 3 - Take heap snapshots: use `v8.writeHeapSnapshot()` or
Chrome DevTools. Take before and after suspected operations.
Compare in Chrome DevTools "Memory" tab, Comparison view.

Step 4 - Analyze growth: look for Closure, Array, Map, Object
types that grew. "Retained Size" shows total memory kept alive
by this object.

Step 5 - Find the retainer: Chrome DevTools shows the reference
chain keeping the object alive. Follow the retainer path from
leaked object to the GC root.

*What separates good from great:* Understanding that `heapsnapshot`
captures object references and closure contexts, not just object
counts. A single closure retaining a 1GB Buffer shows as one object
but massive retained size. The "Retainer" path in DevTools traces
exactly why the object can't be GC'd.
