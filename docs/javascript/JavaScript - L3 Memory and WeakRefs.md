---
layout: default
title: "JavaScript - L3 Memory and WeakRefs"
parent: "JavaScript"
nav_order: 10
permalink: /javascript/l3-memory-and-weakrefs/
---

# JavaScript Memory Model and Garbage Collection

---

### 🎯 Model Answer

**30 seconds:**

> JavaScript uses automatic garbage collection - mark-and-sweep. The
> engine marks all objects reachable from the root (global scope,
> call stack), then frees everything unreachable. Memory leaks happen
> when code holds unnecessary references: listeners not removed,
> closures capturing large objects, detached DOM nodes. The
> diagnostic tool is Chrome DevTools heap snapshot comparison.

**3 minutes (Senior):**

> V8 uses generational GC: a young generation (new space, ~1-8MB)
> for short-lived objects and an old generation for survivors.
> Minor GC (Scavenger) collects only young generation - fast and
> frequent. Major GC (Mark-Compact) collects the full old generation
> and causes visible pauses. Orinoco makes major GC incremental and
> concurrent to reduce main-thread pauses.
>
> The four leak patterns I watch for: (1) window/document event
> listeners not removed when components destroy; (2) closures
> capturing large objects in long-lived callbacks; (3) global
> variables accumulating data; (4) detached DOM nodes held in JS.
>
> Diagnostic workflow: take heap snapshot at idle, exercise the
> leaking scenario ten times, trigger GC, take second snapshot,
> switch to Comparison view, sort by retained size delta. Objects
> growing there are the leak.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "JavaScript GC - let me think through what
reachable means and how the collector uses it."

**(2) First principles:** "GC needs a safe rule for what to free.
Only safe criterion: if nothing running can ever reach this object
again, free it. Mark-and-sweep from root implements this..."

**(3) Bridge:** "Like reference counting but handles cycles - GC
traces reachability from known roots rather than counting references."

---

### 📘 Concept Explanation

**What it is:**

JavaScript automatic GC. V8 uses a generational mark-and-compact
collector. Objects reachable from root (global, stack) are kept;
unreachable objects are freed.

**The problem it solves:**

Manual memory management causes use-after-free and double-free.
GC eliminates those at the cost of occasional pauses.

**How it works:**

```
V8 Heap:
  New Space (~1-8MB): short-lived objects
    Nursery -> Intermediate -> promoted to Old Space
  Old Space: long-lived promoted objects
  Large Object Space: objects > ~512KB

GC Algorithms:
  Minor GC (Scavenger): new space only, <1ms, frequent
  Major GC (Mark-Compact): full heap, expensive
  Orinoco: incremental + concurrent marking (reduces pauses)

Mark phase:
  Walk from root set (globals, stack, registers)
  Mark all reachable objects
Sweep/Compact:
  Free all unmarked objects
  Compact to eliminate fragmentation

Memory leak = object unnecessarily kept reachable:
  - forgotten window.addEventListener
  - closure capturing large object
  - JS variable holding removed DOM node
  - global accumulator (cache, log array)
```

**The key insight:**

A memory leak is not a GC failure - the GC is correct. The leaked
objects ARE reachable via unnecessary references. The fix is always
making objects unreachable when you are done with them.

**When to use it:**

Understanding GC matters for long-running SPAs, Node.js servers,
and 60fps animation code where GC pressure causes frame drops.

**When NOT to use it:**

Do not prematurely optimize short-lived computation. GC is invisible
for code that completes quickly.

**Alternatives:**

- SharedArrayBuffer: off-GC binary memory; no GC pressure
- WebAssembly linear memory: manual lifecycle; no GC involvement

**First-principles derivation:**

Manual free is error-prone. Automatic collection requires a sound
reclamation rule: "unreachable from root" is the only safe criterion.
Mark-and-sweep traverses from known roots to implement this exactly.

---

### 💻 Code Example

**Example 1: Four leak patterns and fixes**

```javascript
// LEAK 1: listener not removed on cleanup
// BAD
class Widget {
  constructor() {
    window.addEventListener('resize', this.update.bind(this));
    // 'this' held alive by listener forever
  }
}

// GOOD: AbortController for bulk cleanup
class Widget {
  #ctrl = new AbortController();
  constructor() {
    window.addEventListener('resize', e => this.update(e),
      { signal: this.#ctrl.signal });
  }
  destroy() { this.#ctrl.abort(); } // removes all listeners
}

// LEAK 2: closure capturing large data unnecessarily
// BAD: returned fn keeps entire 'data' array alive
function process(data) {
  const result = data.map(transform);
  return () => result.length; // closes over result -> data
}
// GOOD: break capture chain
function process(data) {
  const count = data.map(transform).length;
  return () => count; // only primitive captured
}

// LEAK 3: global accumulator
const log = [];
function track(event) {
  log.push(event); // BAD: grows forever
}
const MAX = 1000;
const boundedLog = [];
function track(event) {
  if (boundedLog.length >= MAX) boundedLog.shift();
  boundedLog.push(event); // GOOD: bounded
}

// LEAK 4: detached DOM node
// BAD
const removed = [];
function rm(el) {
  el.parentNode.removeChild(el);
  removed.push(el); // strong ref prevents GC
}
// GOOD: let go of removed elements
function rm(el) {
  el.parentNode.removeChild(el);
  // no push - GC reclaims when no refs remain
}
```

> **Code walkthrough:** AbortController is the modern cleanup pattern
> - one `abort()` removes all listeners registered with that signal.
> The closure leak shows how captured references extend lifetime:
> `result` references data items, so closing over `result` transitively
> keeps `data` alive. Breaking the chain by extracting only the
> primitive `count` allows both `result` and `data` to be collected.
> The detached DOM node leak is subtle - once removed from the tree,
> the node should be GC'd, but a JS array holding the reference
> prevents it.

**Example 2: Heap snapshot diagnosis**

```javascript
// DIAGNOSTIC STEPS (Chrome DevTools):
// 1. Memory panel -> Take Heap Snapshot (baseline)
// 2. Perform leaking action 10x (navigate route, etc.)
// 3. Click GC (trash icon) to force collection
// 4. Take second Heap Snapshot
// 5. Switch view to "Comparison"
// 6. Sort by "# Delta" or "Size Delta" descending
// 7. Filter for component names / "Detached HTMLElement"
// 8. Click item -> see "Retainers" panel -> find root cause

// Node.js: programmatic heap monitoring
setInterval(() => {
  const { heapUsed, heapTotal } = process.memoryUsage();
  const mb = n => (n / 1048576).toFixed(1) + 'MB';
  console.log(`heap: ${mb(heapUsed)} / ${mb(heapTotal)}`);
}, 60_000);

// Browser: observe GC events
const obs = new PerformanceObserver(list => {
  for (const entry of list.getEntries()) {
    if (entry.name === 'gc') {
      console.log(`GC: ${entry.duration.toFixed(1)}ms`);
    }
  }
});
obs.observe({ type: 'gc', buffered: true });
```

> **Code walkthrough:** The DevTools heap comparison is the
> authoritative memory leak diagnostic. The Retainers panel shows
> the reference chain keeping a leaked object alive - this identifies
> the exact code responsible. In Node.js, logging `heapUsed` every
> minute creates a trend that makes a growing leak unmistakable.
> `PerformanceObserver` type `'gc'` gives real-time GC pause duration
> in supported browsers, enabling GC-aware performance monitoring.

**Example 3: Reducing GC pressure in animation**

```javascript
// BAD: new object every animation frame (60 alloc/sec)
function animate() {
  const pos = { x: calcX(), y: calcY() }; // allocates every frame
  updateEl(pos);
  requestAnimationFrame(animate);
}

// GOOD: reuse pre-allocated object (zero allocation in hot path)
const pos = { x: 0, y: 0 };
function animate() {
  pos.x = calcX(); // mutate existing object
  pos.y = calcY();
  updateEl(pos);
  requestAnimationFrame(animate);
}

// Object pool for more complex objects
class Pool {
  #free = [];
  #factory;
  constructor(factory, size = 20) {
    this.#factory = factory;
    for (let i = 0; i < size; i++) this.#free.push(factory());
  }
  acquire() { return this.#free.pop() ?? this.#factory(); }
  release(obj) { this.#free.push(obj); }
}

const particlePool = new Pool(() => ({
  x: 0, y: 0, vx: 0, vy: 0, life: 0
}), 100);

function spawnParticle(x, y) {
  const p = particlePool.acquire(); // no allocation if pool has stock
  p.x = x; p.y = y; p.vx = rand(); p.vy = rand(); p.life = 1;
  return p;
}
function destroyParticle(p) {
  particlePool.release(p); // return to pool
}
```

> **Code walkthrough:** Creating a new object every animation frame
> at 60fps produces 60 allocations per second, pressuring the minor
> GC and causing periodic pauses that drop frames. Reusing a single
> object eliminates allocation entirely from the hot path. The object
> pool pattern generalizes this: acquire on spawn, release on destroy,
> no allocation when the pool has stock. Critical for particle
> systems, physics simulations, and real-time data visualization.

---

### ⚖️ Comparison Table

| Approach | GC pressure | Control | Use When |
|---|---|---|---|
| Default allocation | Normal | None needed | Most code |
| Object pooling | Very low | Manual reset | 60fps hot paths |
| TypedArray | Low | Pre-allocated | Numeric/binary data |
| SharedArrayBuffer | Zero (off-GC) | Manual | Cross-worker binary buffers |
| WeakRef cache | Low | Non-deterministic | Best-effort optional caches |

**The deciding factor:**
Use object pooling for predictable high-frequency allocation;
TypedArrays for numeric data; WeakRef for optional caches where
miss is acceptable.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> JavaScript handles memory automatically. GC reclaims objects that
> are no longer reachable from the program. Memory leaks happen when
> I hold references to objects I no longer need - most commonly from
> forgetting to remove event listeners. I use Chrome DevTools heap
> snapshots to diagnose what is growing.

*Push deeper:* Describe the four memory leak patterns. Explain the
heap snapshot comparison workflow.

---

**Senior / Staff (5+ years):**

> I know the four leak patterns - listeners, closures, globals,
> detached nodes - and the heap snapshot comparison workflow. For
> high-frequency allocation code I use object pooling. For Node.js
> servers I monitor `process.memoryUsage()` over time and use
> `node --inspect` for heap snapshot analysis. AbortController
> makes bulk listener cleanup clean.

*Push deeper:* Staff discuss V8's Orinoco incremental/concurrent GC,
tri-color marking, memory budgeting for PWAs, SharedArrayBuffer for
off-GC data, and WASM linear memory.

---

### ⚠️ Common Misconceptions

**Misconception 1: `variable = null` immediately frees memory.**

It removes one reference. The object is collected only when all
references (closures, arrays, Maps, listeners) to it are gone.

**Misconception 2: Closures always cause memory leaks.**

Only when they capture variables holding large objects and the
closure outlives the need. Short-lived callbacks that fire once
and release are not leaks.

**Misconception 3: Modern JS engines eliminate all GC pauses.**

Orinoco reduces major GC pauses via incremental marking but does
not eliminate them. High allocation rates still trigger minor GC
events that can cause frame drops in animation-critical code.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: SPA memory grows unbounded on each navigation.**

Symptom: Memory increases per route change; browser tab slows over time.

Diagnosis: Heap snapshot comparison shows component objects surviving
after unmount; EventListener count grows.

Fix: Component cleanup uses AbortController, cancels async operations,
clears intervals and timeouts.

**Failure 2: Node.js server OOM after hours.**

Symptom: `heapUsed` grows steadily; eventual `ENOMEM` crash.

Diagnosis: `node --inspect` + heap snapshot at growth peak; common
causes: in-memory caches without eviction, EventEmitter listener
accumulation, request context objects not freed.

Fix: Bounded caches with eviction, cleanup in request finalizers,
`emitter.setMaxListeners()` and audits for listener leaks.

**Failure 3: GC pauses dropping animation frames.**

Symptom: Periodic FPS drops to ~30; Performance trace shows GC events
during frame rendering.

Diagnosis: DevTools Performance timeline shows Minor GC or Major GC
entries overlapping with frame callbacks.

Fix: Object pooling in animation loop; TypedArrays for numeric data;
avoid string concatenation and array spread in hot paths.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How does JavaScript GC work? | Definition | ★★☆ | 2 min |
| What is V8's generational hypothesis? | Mechanism | ★★☆ | 3 min |
| WeakMap vs Map for caching | Comparison | ★★☆ | 2 min |
| Debug SPA memory growing on each navigation | Scenario | ★★★ | 5 min |
| Node.js OOM after 24h - diagnose and fix | Debugging | ★★★ | 5 min |
| How does Orinoco reduce GC pauses? | Deep Dive | ★★★ | 4 min |
| "null assignment immediately frees memory." | Misconception | ★★☆ | 2 min |
| Reduce GC pressure in a 60fps animation loop | Performance | ★★★ | 4 min |
| What is tri-color marking in incremental GC? | Deep Dive | ★★★ | 4 min |

**Q: Walk through diagnosing a SPA memory leak.**

A: I start with measurement. Open DevTools Memory panel, take a
baseline heap snapshot after full load. Then perform the suspected
leaking action - navigate to a route and back - ten times. Click
the GC button (trash icon) to force a collection pass. Take a second
snapshot. Switch to Comparison view.

Sort by "Size Delta" descending. Objects with positive delta were
allocated during the test and not collected - these are the leaks.
I filter for my component class names and look for "Detached
HTMLElement" entries. Clicking a retained object shows the Retainers
panel: the chain of references keeping it alive, from the leaked
object up to the root. This chain directly identifies the code
holding the reference.

Typical root causes: `window.addEventListener` in component mount
without removal in cleanup; `setInterval` without `clearInterval`
on unmount; async callback closures holding component context after
unmount; a global store holding component-specific data that should
have been cleared.

Fix is always making objects unreachable: remove listeners, cancel
intervals, null out references in cleanup hooks. Verify by repeating
the snapshot comparison - the retention should be gone.

*What separates good from great:* Forcing GC before taking the
second snapshot (the trash icon) is critical - without it, minor
GC objects pollute the comparison. Also: the "Allocation Instrumentation
on Timeline" view is more powerful than snapshots for finding where
allocations originate, because it shows allocation call stacks.

---

# WeakMap, WeakSet, and WeakRef

---

### 🎯 Model Answer

**30 seconds:**

> WeakMap, WeakSet, and WeakRef hold references without preventing
> garbage collection. WeakMap maps object keys to values; when the
> key object becomes otherwise unreachable, the entry disappears
> automatically. WeakRef wraps an object; `.deref()` returns the
> object or `undefined` if it was collected. These exist for caches
> and associations that should not extend an object's lifetime.

**3 minutes (Senior):**

> The practical use case for WeakMap is associating metadata with
> objects without controlling their lifetime. A regular Map with
> object keys holds a strong reference, keeping objects alive
> forever - even after they are logically "destroyed." WeakMap
> keys are weak: when the key object has no other strong references,
> the entry is collected automatically.
>
> Vue 3's reactivity system uses a WeakMap (`targetMap`) from reactive
> targets to their effect dependency maps. When a component unmounts
> and its reactive data loses all strong references, the WeakMap
> entry - including all effect subscriptions - is collected without
> any explicit cleanup call anywhere. A regular Map would require
> explicit teardown and would leak on every unmount otherwise.
>
> WeakRef is more nuanced: the object may be collected at any GC
> cycle. `.deref()` may return `undefined` at any time. This makes
> WeakRef appropriate only for best-effort optional caches where
> a cache miss means recomputing, not an error. Never use WeakRef
> where correctness requires the object to exist.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "WeakMap vs Map - let me think through what weak
means in the context of garbage collection..."

**(2) First principles:** "Map holds strong references to keys. An
object used as a Map key is prevented from GC. Weak means: hold
the reference but do not count it for GC reachability..."

**(3) Bridge:** "Like a cache that evicts automatically when entries
are no longer used elsewhere - no explicit eviction logic needed."

---

### 📘 Concept Explanation

**What it is:**

WeakMap/WeakSet/WeakRef hold references that do not prevent GC.
WeakMap object keys are held weakly: when the key is otherwise
unreachable, the entry (key + value) is automatically collected.

**The problem it solves:**

Regular Map with object keys creates strong references that prevent
GC indefinitely. Weak collections allow object-keyed associations
without extending the object's lifetime.

**How it works:**

```
Regular Map (strong key):
  const m = new Map();
  let obj = { data: 'big' };
  m.set(obj, 'metadata');
  obj = null;
  // Map still holds strong ref to obj - NOT GC'd

WeakMap (weak key):
  const wm = new WeakMap();
  let obj = { data: 'big' };
  wm.set(obj, 'metadata');
  obj = null;
  // No more strong refs - entry collected on next GC

WeakRef:
  const ref = new WeakRef(expensiveObject);
  expensiveObject = null;
  const val = ref.deref();
  // val === expensiveObject if still alive
  // val === undefined if GC'd

FinalizationRegistry:
  const registry = new FinalizationRegistry(heldValue => {
    // Called after target is GC'd (non-deterministic timing)
    cleanup(heldValue);
  });
  registry.register(target, 'some-cleanup-key');

WeakMap constraints (intentional by spec):
  - Keys must be objects (not primitives)
  - Not iterable (no forEach, keys(), values())
  - No .size property
  Reason: observing which keys disappeared would expose GC timing
```

**The key insight:**

WeakMap is not iterable by design. Iteration would let you observe
which entries disappeared between two calls - exposing GC timing.
The ES spec requires GC timing to be non-observable. Non-iterability
is a correctness requirement, not a missing feature.

**When to use it:**

- WeakMap: DOM element metadata, reactive target dependencies, per-
  instance private state in polyfills
- WeakSet: visited tracking in graph traversal (cycle detection)
- WeakRef + FinalizationRegistry: optional caches; resource cleanup
  as last-resort safety net

**When NOT to use it:**

- Never for required data (GC timing is non-deterministic)
- Never when you need iteration or size
- FinalizationRegistry: not for primary resource cleanup

**Alternatives:**

- Map with explicit cleanup: fully controllable, iterable; correct
  when lifecycle is deterministic
- LRU cache: bounded Map with eviction; explicit size limit

**First-principles derivation:**

Map with object keys creates strong references, preventing GC.
For caches and metadata stores where association should not control
lifetime, a weak-key variant is required. Non-iterability follows
from GC observability requirements - iteration would expose
non-deterministic key disappearance.

---

### 💻 Code Example

**Example 1: WeakMap for DOM metadata without leaks**

```javascript
// BAD: regular Map keeps elements alive indefinitely
const tooltipData = new Map();
function attachTooltip(el, text) {
  tooltipData.set(el, text); // strong ref: el never GC'd
  el.addEventListener('mouseenter', showTooltip);
}

// GOOD: WeakMap - entry collected when element is GC'd
const tooltipData = new WeakMap();
function attachTooltip(el, text) {
  tooltipData.set(el, text); // weak key: collected with el
  el.addEventListener('mouseenter', showTooltip);
}

// Private state per-instance (used in polyfills before # fields)
const _state = new WeakMap();
class Controller {
  constructor() {
    _state.set(this, { count: 0, active: false });
  }
  increment() { _state.get(this).count++; }
  get count() { return _state.get(this).count; }
}
// When instance is GC'd, WeakMap entry is too
// _state is module-private - no external access
```

> **Code walkthrough:** WeakMap keyed by DOM elements means when an
> element is removed from the document and all strong references are
> gone, the WeakMap entry disappears automatically. Regular Map would
> keep every element that ever received a tooltip in memory indefinitely.
> The private state pattern via WeakMap was the standard approach
> before `#private` class fields - it provides real encapsulation
> since the WeakMap is module-scoped and inaccessible from outside.

**Example 2: WeakRef optional cache with FinalizationRegistry**

```javascript
class WeakCache {
  #cache = new Map(); // string -> WeakRef<T>
  #registry = new FinalizationRegistry(key => {
    // Safety cleanup: remove stale Map entry after GC
    // This fires asynchronously and non-deterministically
    const ref = this.#cache.get(key);
    if (ref?.deref() === undefined) this.#cache.delete(key);
  });

  set(key, value) {
    this.#cache.set(key, new WeakRef(value));
    this.#registry.register(value, key);
  }

  get(key) {
    const ref = this.#cache.get(key);
    if (!ref) return undefined;
    const value = ref.deref();
    if (value === undefined) {
      this.#cache.delete(key); // eager cleanup on miss
      return undefined; // caller must recompute
    }
    return value;
  }
}

// WeakSet: cycle detection in graph traversal
function processGraph(root) {
  const visited = new WeakSet();
  function visit(node) {
    if (visited.has(node)) return; // cycle - skip
    visited.add(node);
    processNode(node);
    node.children?.forEach(visit);
  }
  visit(root);
  // After return: visited WeakSet holds no strong refs
  // Nodes GC'd normally when no longer reachable
}
```

> **Code walkthrough:** The WeakRef cache returns `undefined` on cache
> miss - the caller must handle recomputation. FinalizationRegistry
> cleans the stale Map key after GC but fires asynchronously; the
> eager cleanup in `get()` handles the common case immediately. The
> WeakSet graph traversal tracks visited nodes without extending their
> lifetime - with a regular Set, all visited nodes would remain in
> memory as long as the Set. WeakSet lets them be collected naturally.

**Example 3: Vue 3 reactivity WeakMap pattern**

```javascript
// Simplified Vue 3 @vue/reactivity - targetMap structure
// WeakMap<target, Map<key, Set<ReactiveEffect>>>
const targetMap = new WeakMap();

function track(target, key) {
  if (!currentEffect) return;
  let depsMap = targetMap.get(target);
  if (!depsMap) {
    targetMap.set(target, (depsMap = new Map()));
  }
  let dep = depsMap.get(key);
  if (!dep) depsMap.set(key, (dep = new Set()));
  dep.add(currentEffect); // effect subscribes to this key
}

function trigger(target, key) {
  const depsMap = targetMap.get(target);
  if (!depsMap) return;
  depsMap.get(key)?.forEach(effect => effect.run());
}

// WHY WeakMap: when a component unmounts, its reactive data
// (the 'target') loses all strong refs from component scope.
// targetMap entry is GC'd automatically - all subscriptions
// for all reactive properties cleaned up with zero explicit code.
// With a regular Map: every component's reactive data lives forever.

// Also: proxyMap ensures same proxy for same target
const proxyMap = new WeakMap(); // target -> proxy
function reactive(target) {
  if (proxyMap.has(target)) return proxyMap.get(target);
  const proxy = new Proxy(target, handlers);
  proxyMap.set(target, proxy);
  return proxy;
}
// Guarantees reactive(obj) === reactive(obj) - same proxy identity
```

> **Code walkthrough:** Vue 3 uses two WeakMaps: `targetMap` for
> reactive dependency tracking and `proxyMap` for proxy identity
> guarantees. The WeakMap in `targetMap` means when a reactive target
> (component data) loses all strong references on unmount, the entire
> entry including all effect subscriptions is collected with no
> explicit cleanup. `proxyMap` ensures the same target always returns
> the same proxy - enabling identity checks in templates to work.

---

### ⚖️ Comparison Table

| Collection | Key type | Iterable | GC-safe | Use When |
|---|---|---|---|---|
| `Map` | Any | Yes | No (strong) | Need iteration, size, or primitive keys |
| **WeakMap** | Objects | No | Yes | Object metadata without lifetime extension |
| `Set` | Any | Yes | No (strong) | Unique values, need iteration |
| **WeakSet** | Objects | No | Yes | Visited/processed tracking in traversal |
| **WeakRef** | N/A | N/A | Yes | Best-effort optional cache; handle undefined |

**The deciding factor:**
Use WeakMap/WeakSet when the collection should not control object
lifetime; use Map/Set when you need iteration or explicit lifecycle.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> WeakMap is like Map but holds object keys weakly. If the key object
> is no longer referenced anywhere else, the WeakMap entry is GC'd
> automatically. Useful for associating metadata with objects without
> leaking. WeakRef wraps an object and may return `undefined` after
> GC. WeakMap is not iterable because entries can disappear at any
> GC cycle.

*Push deeper:* Give a real use case for WeakMap. Why must WeakMap
keys be objects and not primitives?

---

**Senior / Staff (5+ years):**

> WeakMap is my tool for object-keyed caches where I do not want to
> control object lifetime. Vue 3's reactivity uses WeakMap from
> reactive targets to their effect dependencies - when the target is
> GC'd, subscriptions disappear automatically. WeakRef with
> FinalizationRegistry enables optional caches. The critical rule:
> never rely on GC timing for correctness - WeakRef can return
> `undefined` at any cycle. Use WeakRef only when undefined is an
> acceptable result.

*Push deeper:* Staff discuss FinalizationRegistry non-determinism,
WeakMap in Proxy identity guarantees, WeakMap in private field polyfills,
and spec-level GC observability requirements.

---

### ⚠️ Common Misconceptions

**Misconception 1: WeakMap holds values weakly.**

WeakMap holds KEYS weakly. Values are held strongly as long as
the entry exists. When the key is GC'd, the entire entry (key + value)
is collected. If you want weak values, use a Map of WeakRefs.

**Misconception 2: WeakRef provides a reliable optional reference.**

GC can clear a WeakRef at any point after the strong reference is
gone. Correctness cannot depend on GC timing. WeakRef is only for
best-effort caches where `undefined` is handled by recomputation.

**Misconception 3: WeakMap is always better than Map for object keys.**

WeakMap trades iterability and size for automatic cleanup. If you
need to enumerate entries, get count, or use primitive keys, use
Map with explicit lifecycle management.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: FinalizationRegistry used for critical resource cleanup.**

Symptom: File handles, DB connections not closed reliably under load.

Diagnosis: FinalizationRegistry callbacks are non-deterministic;
may be significantly delayed after GC.

Fix: Explicit `dispose()` / `close()` pattern for critical resources.
`using` keyword (TypeScript 5+, ES2024) for deterministic cleanup.
FinalizationRegistry is a last-resort safety net only.

**Failure 2: WeakRef dereferenced without undefined check.**

Symptom: Random `TypeError: Cannot read properties of undefined`
under memory pressure.

Fix: Always check `const val = ref.deref(); if (val !== undefined)`.
If the object must exist, use a strong reference instead.

**Failure 3: WeakMap entry not collected despite null assignment.**

Symptom: Memory does not decrease despite using WeakMap; leak persists.

Diagnosis: Another strong reference to the key exists - in an array,
closure, another Map, or global scope.

Fix: Trace all references to the key object. WeakMap only helps when
its entry is the last remaining reference to the key.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is WeakMap and how does it differ from Map? | Definition | ★★☆ | 2 min |
| How does WeakMap prevent memory leaks? | Mechanism | ★★☆ | 3 min |
| WeakMap vs WeakRef - when does each apply? | Comparison | ★★☆ | 2 min |
| Build a DOM metadata store without leaking | Scenario | ★★☆ | 5 min |
| Map-based cache keeps growing - redesign it | Debugging | ★★☆ | 3 min |
| How does Vue 3 use WeakMap in its reactivity? | Deep Dive | ★★★ | 4 min |
| "WeakRef gives reliable optional caching." | Misconception | ★★☆ | 2 min |
| WeakMap vs Map lookup performance overhead | Performance | ★★☆ | 2 min |
| Explain FinalizationRegistry and why it cannot replace explicit cleanup | Deep Dive | ★★★ | 4 min |

**Q: How does Vue 3 use WeakMap in its reactivity system?**

A: Vue 3's `@vue/reactivity` maintains two WeakMaps. The first is
`targetMap`: a `WeakMap<target, Map<key, Set<ReactiveEffect>>>`.
This is the dependency graph. When a reactive property is read
during effect execution, `track(target, key)` subscribes the current
effect to that property. When the property changes, `trigger(target, key)`
re-runs all subscribed effects.

The WeakMap is essential for memory management. When a component
unmounts, its reactive data object - the `target` - loses all strong
references from the component's scope. Because `targetMap` holds
the target weakly, the entire entry including all effect subscriptions
for all properties of that target is collected automatically. No
explicit cleanup is ever needed in Vue's lifecycle hooks for this.
A regular Map would require Vue to explicitly remove every reactive
target on every unmount, and any miss would be a permanent memory leak.

The second WeakMap is `proxyMap`: a `WeakMap<target, Proxy>`. This
ensures that `reactive(obj)` always returns the same proxy for the
same target object. This proxy identity guarantee is required for
template rendering - the virtual DOM diff algorithm relies on object
identity to detect changes, and inconsistent proxies would break it.

*What separates good from great:* The proxy identity insight. Without
`proxyMap`, `reactive(obj) !== reactive(obj)` would be true, and
every re-render would see a "new" reactive object and trigger full
subtree reconciliation. The WeakMap caches proxy instances to prevent
this. When the target is GC'd, the proxy entry disappears automatically
- again, no explicit cleanup.

**Q: Why is WeakMap not iterable, and is this a design flaw?**

A: It is an intentional design decision required by the GC
non-observability requirement in the ECMAScript specification. GC
timing in JavaScript must not be observable by user code - programs
must behave identically regardless of when GC runs.

If WeakMap were iterable, you could detect when entries disappeared:
iterate at time T, iterate again at T+delta, and find fewer entries.
This would mean program behavior changes based on GC timing, which
violates the spec's requirement. The TC39 committee explicitly
considered and rejected weak iteration for this reason.

The consequence: WeakMap has no `forEach`, no `keys()`, `values()`,
`entries()`, no `size`, no `Symbol.iterator`. The only operations
are `get`, `set`, `has`, `delete` - all O(1), all non-temporal.

The practical test for choosing between WeakMap and Map: if you ever
ask "how many entries are there?" or "what are all the keys?", use
Map with explicit cleanup. If you only ever do `get(key)` and `set(key, val)`
and want entries to be GC'd with their keys, use WeakMap.

*What separates good from great:* Knowing this is a spec-level
constraint that cascades to WeakSet (no iteration, no size) and
WeakRef (no enumeration of all active refs), all for the same reason.
The entire Weak* family is constrained by the GC observability rule.
