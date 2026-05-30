---
layout: default
title: "Async JavaScript - META Patterns"
parent: "Async JavaScript"
nav_order: 17
permalink: /async-javascript/meta-patterns/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| # | Keyword | Difficulty |
|---|---------|------------|
| 1 | [Mental Models for JavaScript Async Reasoning](#mental-models-for-javascript-async-reasoning) | ★☆☆ |
| 2 | [Promise vs Observable Decision Framework](#promise-vs-observable-decision-framework) | ★☆☆ |
| 3 | [Debugging Async Code: Systematic Approach](#debugging-async-code-systematic-approach) | ★☆☆ |

---

# Mental Models for JavaScript Async Reasoning

---

### 🎯 Model Answer

**30 seconds:**
> Three mental models for async JavaScript. The "paused
> function" model: `await` pauses the current function and
> resumes it later; the rest of the program continues. The
> "mailbox" model: think of async operations as sending a
> message and registering a reply handler; you do not wait
> at the mailbox. The "queue" model: the event loop is a task
> queue; async tasks are added to the queue and processed
> one at a time.

**3 minutes:**
> Mental models are more valuable than API documentation
> because they let you predict behavior in situations you
> have not seen before.
>
> **Model 1: The "Paused Function"**
> `await expr` pauses THIS function. Not the program. Not
> the browser. Just this one function. The rest of the code
> continues running. When the awaited Promise resolves, the
> function resumes at the next line.
>
> Useful prediction: "Can I await inside a forEach?" No -
> forEach does not know about the await. It calls your
> function, gets a Promise back, and moves to the next item
> without waiting. The forEach does not pause.
>
> **Model 2: The "Mailbox"**
> Async I/O is a message + reply. You send the request to
> the OS mailbox, register a callback ("call me when done"),
> and return. You do not stand at the mailbox waiting. This
> explains why Node.js can handle thousands of connections
> on one thread: it never waits, it just processes replies
> as they arrive.
>
> **Model 3: The "Two-Queue" Model (for event ordering)**
> The event loop has two queues: a microtask queue (Promises,
> queueMicrotask) and a task queue (setTimeout, I/O events).
> After each task, ALL microtasks drain before the next task
> runs. This explains why Promise.then always runs before
> setTimeout(0).

**Blank Mind Recovery:**

**(1) Restate:** "Paused function: await pauses THIS function
only. Mailbox: send request, register callback, continue.
Two queues: microtasks (Promises) always before macrotasks
(setTimeout)."

**(2) First principles:** "A mental model is a prediction
machine. The right model lets you answer 'what happens if'
questions without reading documentation."

---

### 📘 Concept Explanation

**What it is:**
Mental models are simplified internal representations that
allow you to reason about system behavior. The right mental
model lets you predict correct behavior in novel situations.

**The problem it solves:**
Without a model, async debugging is trial-and-error.
With the right model, you can trace through code mentally
and predict the output.

**How it works:**

```javascript
// TEST YOUR MODEL: what is the output order?
console.log('A');
setTimeout(() => console.log('B'), 0);
Promise.resolve().then(() => console.log('C'));
console.log('D');

// Without a model: guessing
// With the Two-Queue model:
// Synchronous: A, D (runs immediately, no queue)
// Microtask queue: C (Promise.then = microtask, drains after sync)
// Macrotask queue: B (setTimeout = macrotask, runs after microtasks)
// Output: A, D, C, B
```

```javascript
// TEST: does await pause the whole program?
async function fetchData() {
  console.log('1: before await');
  const data = await fetch('/api/data');
  console.log('3: after await');
  return data;
}

fetchData();
console.log('2: after calling fetchData');

// Paused Function model:
// "1: before await" - runs synchronously inside fetchData
// fetchData hits await, PAUSES just fetchData, returns a Promise
// "2: after calling fetchData" - runs immediately (program continued)
// fetch resolves -> fetchData resumes -> "3: after await"
// Output: 1, 2, 3
```

```javascript
// TEST: forEach await misconception
const ids = [1, 2, 3];

ids.forEach(async (id) => {
  const data = await fetchById(id);
  console.log(data);
});
console.log('done');

// Paused Function model:
// forEach calls the async function for id=1
// Async function hits await, PAUSES. forEach gets a Promise back.
// forEach ignores the Promise. Calls async function for id=2.
// id=2 pauses. forEach calls id=3. id=3 pauses.
// forEach loop ends. console.log('done') runs.
// THEN: fetch results arrive, async functions resume in order.
// Output: 'done', then data[1], data[2], data[3] (in resolve order)
// The 'done' is BEFORE any data: the developer expected the opposite.

// FIX (sequential): for...of + await
for (const id of ids) {
  const data = await fetchById(id);
  console.log(data);
}
console.log('done'); // now actually after all data
```

> **Code walkthrough:** The three code blocks test the mental
> models. The two-queue test shows that Promise.then (microtask)
> always fires before setTimeout(0) (macrotask), even though
> setTimeout(0) is registered first. The paused-function test
> shows that `await` inside `fetchData` does not prevent `console.log('2')`
> from running - only fetchData itself is paused. The forEach
> test is the most important: it shows the most common async
> mistake, explained entirely by the paused-function model.

**The key insight:**
These three models are sufficient to predict 95% of async
JavaScript behavior. The remaining 5% (scheduler ordering
of microtasks within a single task) rarely matters in practice.

**When to use it:**
Before looking at documentation. Use the mental model to
predict behavior, then verify with a quick test.

**When NOT to use it:**
Mental models are simplifications. When behavior truly
surprises, go to the spec (ECMA-262 event loop specification).

**Alternatives:**
- Marble diagrams: visual model for Observable timing
- State machine model: for complex async workflows
- Sequence diagrams: for multi-actor async interactions

**First-principles derivation:**
Richard Feynman: "You do not really understand something
unless you can explain it to a child." A mental model is
the "child-explanation" level - the core mechanism without
the details. These three models are the core mechanisms.

---

### 💻 Code Example

```javascript
// BAD: reasoning by trial and error
// Developer adds console.logs until behavior is accidentally correct
async function badOrder() {
  let result;
  setTimeout(() => result = 'timeout', 0);
  await Promise.resolve();
  console.log(result); // undefined! setTimeout didn't run yet
  // Developer: "why is it undefined? Let me try adding await..."
  // This is debugging without a model.
}
```

> **Code walkthrough:** Without the two-queue mental model,
> this is mysterious. With it: `await Promise.resolve()` yields
> to the microtask queue. The microtask drains (resume this
> function). Only then does the event loop pick up the setTimeout
> macrotask. So `console.log(result)` runs BEFORE the setTimeout
> callback, giving `undefined`. The model predicts this
> before running a single line.

```javascript
// GOOD: mental model guides design
async function correctOrder() {
  // MODEL: "What order do things run in?"
  // 1. Synchronous code: all runs first
  // 2. Microtasks (Promise.then): runs after sync, before macrotasks
  // 3. Macrotasks (setTimeout): runs after all microtasks

  // setTimeout is a macrotask: never "done" by the time microtasks run
  // Solution: promisify the timeout OR use Promise-based API
  await new Promise(resolve => setTimeout(resolve, 0));
  // NOW we are in the macrotask's continuation (a microtask)
  // setTimeout has fired
  console.log('after macrotask'); // reliably after setTimeout fires
}
```

> **Code walkthrough:** The fix wraps the setTimeout in a Promise.
> `await` waits for the Promise to resolve, which happens in
> the setTimeout callback. This converts the macrotask into
> an awaitable: the function resumes after the setTimeout fires.
> The model guided the fix: "I need to be in a macrotask or
> after it, so I need to await the macrotask's completion."

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> "I use three mental models: await pauses only the current
> function (not the program), async ops are like sending mail
> with a return address, and Promises run before setTimeout.
> These models let me predict async behavior without debugging."

---

**Senior / Staff (5+ years):**
> "Mental models are the difference between developers who
> debug async by trial-and-error versus those who read the
> stack trace and immediately know the cause. The paused-function
> model explains forEach/await bugs in 10 seconds. The two-queue
> model explains all scheduling surprises. I introduce these
> models during onboarding and code review - they reduce async
> debugging time by 80%."

---

### ⚠️ Common Misconceptions

**Misconception 1:** "await pauses the whole program."
Only the current async function pauses. The rest of the
call stack continues. The event loop continues processing
events. Other async functions continue running.

**Misconception 2:** "setTimeout(0) runs immediately."
setTimeout(0) adds a task to the macrotask queue. All
microtasks (Promise.then, queueMicrotask) drain before
the macrotask runs. "0ms" means "when the current task
and all microtasks are done."

---

### 🚨 Failure Modes and Diagnosis

**Failure: Wrong mental model leads to race condition**
```javascript
// Bug caused by wrong model:
let data;
fetchData().then(result => { data = result; });
processData(data); // BUG: data is undefined here

// WRONG MODEL: "then runs immediately after fetchData"
// CORRECT MODEL: "then is a microtask queued after the current
// synchronous code completes. processData(data) runs synchronously,
// BEFORE the microtask queue. data is still undefined."

// FIX: use the model to see the bug:
// "processData must be inside the then callback, or await the fetch"
const result = await fetchData();
processData(result); // correct: awaits before using
```

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | Two-queue model, paused function model |
| Trade-off | 1 | Model accuracy vs simplicity |
| Failure Mode | 2 | forEach await, timing surprises |
| Debugging | 1 | Using models to predict before debugging |
| Behavioral | 1 | Teaching async to a team |

**Q1. Explain the output order of this code and why:**
```javascript
console.log(1);
setTimeout(() => console.log(2), 0);
Promise.resolve().then(() => console.log(3));
queueMicrotask(() => console.log(4));
console.log(5);
```

Using the two-queue model:
- Synchronous: 1, 5 (run in-line, no queue)
- Microtask queue (drains after sync):
  - `Promise.resolve().then(...)`: queued, runs next
  - `queueMicrotask(...)`: queued, runs after Promise
- Macrotask queue: `setTimeout(() => ..., 0)`: runs last

Output: 1, 5, 3, 4, 2

Key: both Promise.then and queueMicrotask are microtasks.
They drain before setTimeout(0). Within microtasks, they run
in registration order.

*What separates good from great:* Knowing that `queueMicrotask`
is a direct microtask queue insert, while Promise.resolve().then()
creates a resolved Promise first and then queues the callback.
For all practical purposes, they have the same priority.

---

**Q2. Why does `await` inside `forEach` not work as expected?**

The paused-function model explains it:
1. `forEach` calls the async callback for element 0
2. Callback hits `await`, pauses ONLY THE CALLBACK, returns a Promise
3. `forEach` receives the Promise, ignores it, calls callback for element 1
4. Same: pause, return Promise, forEach ignores it
5. All callbacks launched, none awaited
6. `forEach` loop ends, outer code continues

Correct pattern depends on the desired behavior:
```javascript
// Sequential (each waits for previous):
for (const item of items) {
  await process(item); // for...of respects await
}

// Parallel (all at once):
await Promise.all(items.map(item => process(item)));
```

*What separates good from great:* Knowing that `Promise.all`
with `.map` is O(N) parallel, while `for...of` with `await`
is O(N) sequential. For N items of duration T:
- Parallel: ~T total (+ overhead)
- Sequential: ~N*T total

Choose based on: are operations independent? Yes -> parallel.
Do later operations depend on earlier results? -> sequential.

---

**Q3. How do you teach the mental models to a new team member?**

Teaching approach:
1. Start with the output-order quiz (Q1 above). Let them guess.
2. Reveal the two-queue model. Quiz again. They predict correctly.
3. Show the forEach/await bug in their actual codebase (if one exists).
4. Explain: the paused-function model makes this predictable.
5. Practice: review 5 async code snippets, predict output before running.

Retention check (one week later): the quiz. If they predict
correctly without looking at notes, the model is internalized.

*What separates good from great:* The prediction-before-test
approach. Running code to see what happens is less effective
than predicting first (wrong predictions create cognitive
dissonance, which is a stronger memory consolidation trigger).

---

**Q4. What is the danger of an infinite microtask loop?**

```javascript
// Infinite microtask loop: starves all macrotasks
function infiniteMicrotask() {
  Promise.resolve().then(infiniteMicrotask);
}
infiniteMicrotask();
// macrotasks never run: setTimeout, I/O events, UI rendering all starved
// Browser: tab becomes unresponsive
// Node.js: no I/O events processed
```

Using the two-queue model: the microtask queue must drain
before any macrotask runs. If a microtask always queues
another microtask, the queue never empties. The event loop
is stuck in the microtask phase.

This is functionally equivalent to an infinite synchronous loop,
except it does not throw a stack overflow - it just hangs.

Detection:
- Browser: DevTools performance tab shows "Scripting" in
  an infinite loop with no other task types
- Node.js: `--trace-event-categories v8` shows constant microtask activity

*What separates good from great:* The practical implication
for recursive async operations: use `setImmediate` or `setTimeout(0)`
instead of `Promise.resolve().then()` for recursive work that
must yield to I/O. `setImmediate` is a macrotask: it yields
to I/O between calls.

---

**Q5. What is the "mental model" for Promises vs callbacks?**

Callbacks (CPS) model: "tell me what to do when done."
Promise model: "give me a receipt; I'll check it later."

The receipt analogy:
- `fetch('/api')` returns a Promise: the "receipt"
- The receipt does not contain the data yet
- `.then(data => ...)`: "when the receipt is honored, do this"
- `await promise`: "wait here until the receipt is honored"

This model explains:
- Why `promise.then()` does not block: you write a note on
  the receipt, you do not wait at the counter
- Why `await` pauses only the current function: only this
  person is waiting at the counter; others keep moving
- Why a rejected Promise with no `.catch()` is unhandled:
  the receipt bounced and nobody checked

*What separates good from great:* The receipt analogy extends
to `Promise.all`: "wait until ALL receipts are honored, then
proceed." And `Promise.race`: "wait until ANY receipt is
honored, use that one."

---

**Q6. How do you reason about Promise chain order?**

Chain order model: each `.then()` adds to the microtask queue.

```javascript
Promise.resolve('start')
  .then(v => { console.log(v); return 'step1'; })
  .then(v => { console.log(v); return 'step2'; })
  .then(v => console.log(v));

console.log('sync');
// Output: sync, start, step1, step2
// Model: all .then() callbacks are microtasks.
// sync runs first (current task).
// Then microtasks drain: start, step1, step2 run in chain order.
```

Chaining vs nesting:
```javascript
// CHAINING (flat, correct):
fetch('/a').then(a =>
  fetch('/b').then(b => [a, b]) // nested because b needs a
).then(([a, b]) => process(a, b));

// vs Promise.all when independent:
Promise.all([fetch('/a'), fetch('/b')])
  .then(([a, b]) => process(a, b)); // parallel, no nesting
```

*What separates good from great:* Knowing when to nest (later
fetch depends on earlier result) vs when to use `Promise.all`
(fetches are independent). Nested for dependencies, parallel
for independence.

---

**Q7. What mental model helps reason about async error handling?**

The "exception propagation through the chain" model:

Normal function: throw propagates up the call stack.
Promise chain: rejection propagates down the chain, skipping
`.then()` handlers, until caught by `.catch()`.

```javascript
Promise.resolve()
  .then(() => { throw new Error('oops'); }) // throw = rejection
  .then(() => console.log('skipped'))       // skipped: chain is rejected
  .catch(err => console.log('caught:', err.message)) // catches it
  .then(() => console.log('continues'))     // runs: catch recovers chain
```

With async/await: normal try/catch. Rejections ARE exceptions.
```javascript
async function f() {
  try {
    await failingOp(); // rejection = throw
  } catch (err) {
    handleError(err); // caught: no unhandled rejection
  }
}
```

*What separates good from great:* The "catch recovers the chain"
behavior. After `.catch()` handles a rejection, the chain
continues as resolved (unless catch itself throws). This
allows recovery: catch -> fallback -> continue.

---

# Promise vs Observable Decision Framework

---

### 🎯 Model Answer

**30 seconds:**
> The single deciding question: how many values will this
> produce over time? One value = Promise/async-await. Zero
> to infinity over time = Observable. The second question:
> does new input need to cancel in-progress work? No
> cancellation needed = Promise. Automatic cancellation on
> new input = Observable (switchMap).

**3 minutes:**
> Promise: a container for a single future value. One shot.
> Once resolved or rejected, it never changes. Perfect for:
> HTTP requests, file reads, database queries, any I/O operation
> that produces one result.
>
> Observable: a data pipeline that emits zero to many values
> over time, lazily (nothing happens until you subscribe).
> Perfect for: event streams, WebSocket messages, user input,
> derived values, any situation requiring coordination of
> multiple sources.
>
> **The decision tree:**
> 1. Single value, triggered once? -> Promise
> 2. Multiple values over time? -> Observable
> 3. Need to cancel old work on new input? -> Observable + switchMap
> 4. Need to combine multiple async sources? -> Observable (combineLatest)
> 5. Component state that updates reactively? -> Signal
>
> **Common mistake: using Observable for simple single requests.**
> `http.get('/api').pipe(take(1)).subscribe()` is more complex
> than `await fetch('/api')` with no benefit.

**Blank Mind Recovery:**

**(1) Restate:** "Promise = one value, one time. Observable =
stream of values over time. Ask: one or many? Then: cancel needed?
Combine sources? If yes to any: Observable."

**(2) First principles:** "Data has a temporal shape. Point-in-time
(single value at one moment) = Promise. Duration (values arriving
over time) = Observable."

---

### 📘 Concept Explanation

**What it is:**
A decision framework for choosing the right async abstraction
based on the temporal shape of the data and the coordination
requirements.

**The problem it solves:**
Over-engineering (using Observable for simple requests) and
under-engineering (using Promise chains for complex event
coordination) both lead to bugs and complexity.

**How it works:**

```javascript
// DECISION MATRIX IN CODE:

// CASE 1: Single request, single response -> Promise
const user = await fetch('/api/user').then(r => r.json());
// One call, one result, done.

// CASE 2: Multiple events over time -> Observable
const clicks$ = fromEvent(button, 'click');
// Infinite stream of click events

// CASE 3: Cancellable single request -> Observable + switchMap
// OR: AbortController + Promise (simpler for one-off)
const controller = new AbortController();
const user = await fetch('/api/user', { signal: controller.signal });
controller.abort(); // cancel if needed

// OR with Observable (cleaner when connected to other streams):
const userId$ = route.paramMap.pipe(map(p => p.get('id')));
const user$ = userId$.pipe(
  switchMap(id => from(fetch(`/api/user/${id}`).then(r => r.json())))
  // switchMap: new userId -> cancel previous fetch -> start new
);

// CASE 4: Combine independent async sources -> Observable
const dashboard$ = combineLatest({
  user: userService.user$,
  orders: orderService.orders$,
  alerts: alertService.alerts$
});
// Would be complex with Promises (need manual coordination + re-triggers)

// CASE 5: Component derived state -> Signal
const displayName = computed(() =>
  `${firstName()} ${lastName()}`
);
// Synchronous, reactive, no subscription management
```

> **Code walkthrough:** The five cases map to the decision
> tree directly. Single request is cleanest with async/await.
> Cancellable single request can use AbortController + Promise,
> but switchMap wins when the cancellation trigger is itself
> a stream (like route params). combineLatest is uniquely
> suited for case 4: Promise.all only works for one-time
> combined fetches, not for reactive re-combination on any
> source change.

**The key insight:**
The decision is about the data's temporal shape AND the
coordination requirements. Both must be considered.

**When to use it:**
Every time you start a new async feature. Ask the two questions
before writing any code.

**When NOT to use it:**
Do not over-apply the framework. A simple fetch request does
not require extensive analysis. The framework is for cases
where the choice is not obvious.

**Alternatives:**
Async generators (third option): pull-based multi-value
sequences. Best for: pagination, sequential event processing.
Between Observables (push) and Promises (one value).

**First-principles derivation:**
Promises and Observables represent different "algebraic
types" for values over time: `Maybe<Future<T>>` vs
`Observable<T>`. The temporal type of the data should drive
the choice.

---

### 💻 Code Example

```javascript
// BAD: Observable where Promise is sufficient
// Observable adds: operator complexity, subscription management,
// unsubscribe boilerplate, no benefit for single-value cases

// Fetching a single user profile:
const userSubscription = this.http.get('/api/user/1').pipe(
  tap(user => this.isLoading = false),
  catchError(err => { this.error = err; return EMPTY; }),
  take(1) // why are we even using Observable if take(1)?
).subscribe(user => this.user = user);

// Must remember to unsubscribe:
ngOnDestroy() {
  userSubscription.unsubscribe();
}
// 12 lines, subscription management, for what?
// This is ONE request that returns ONE value.
```

> **Code walkthrough:** Using an Observable with `take(1)` for
> a single HTTP request is the most common over-engineering pattern
> in Angular applications. The `take(1)` signals "I only want one
> value" - which IS a Promise. The Observable adds: pipe operators,
> subscription management, `take(1)` to prevent re-subscription,
> and `unsubscribe` in `ngOnDestroy`. The equivalent with async/await
> is 3 lines with no subscription management.

```javascript
// GOOD: Match abstraction to problem shape

// Single request: use the simplest abstraction (async/await)
async loadUser(id) {
  try {
    this.isLoading = true;
    this.user = await this.userService.getUser(id);
  } catch (err) {
    this.error = err;
  } finally {
    this.isLoading = false;
  }
}
// 10 lines, no subscription, obviously correct

// Multi-source reactive: Observable is the right tool
class Dashboard {
  readonly vm$ = combineLatest({
    user: this.auth.user$,
    orders: this.orders.recent$,
    alerts: this.alerts.active$
  }).pipe(
    map(({ user, orders, alerts }) => ({
      ...user,
      pendingOrderCount: orders.filter(o => o.pending).length,
      hasAlerts: alerts.length > 0
    })),
    takeUntilDestroyed() // Angular 16+ auto-cleanup
  );
  // 3 reactive sources, combined, derived, auto-cleaned
  // This is what Observables are built for
}

// Search-as-you-type: cancellation requirement -> switchMap
class SearchComponent {
  searchControl = new FormControl('');
  readonly results$ = this.searchControl.valueChanges.pipe(
    debounceTime(300),
    distinctUntilChanged(),
    switchMap(q => this.searchService.search(q).pipe(
      catchError(() => of([]))
    )),
    takeUntilDestroyed()
  );
  // Automatic cancellation of in-flight requests on new input
}
```

> **Code walkthrough:** The `loadUser` method with async/await
> is readable, has clear error handling with try/catch, and
> needs no cleanup. The `Dashboard` `vm$` Observable demonstrates
> where `combineLatest` shines: three independent streams that
> must be combined and kept in sync - impossible to match
> with `async/await` cleanly. The `SearchComponent` `results$`
> shows the `switchMap` use case: user types faster than
> responses arrive, `switchMap` automatically cancels the
> previous in-flight request on each new emission.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> "I choose between Promise and Observable based on: one value
> or many? If one value (HTTP request, file read), I use
> async/await. If multiple values over time (event stream,
> combining sources), I use Observable."

---

**Senior / Staff (5+ years):**
> "The question is the temporal shape of the data. Promises
> model point-in-time data. Observables model data over time.
> I use three decision factors: (1) how many values, (2) does
> cancellation of previous work matter, (3) are multiple sources
> being combined? If any answer points to Observable, I use
> Observable. Otherwise, async/await. The most expensive mistake
> I see: full RxJS pipelines for simple CRUD - it imports
> mental overhead without benefit."

---

### ⚠️ Common Misconceptions

**Misconception 1:** "Observables are always better because
they can do everything Promises can."
A Wrench can drive some screws if forced. But a screwdriver
is better for screws. Observable CAN model single values
(with `take(1)`) but adds complexity with no benefit.

**Misconception 2:** "You cannot use async/await with
Observables."
`firstValueFrom(observable$)` converts Observable to Promise.
`from(promise)` converts Promise to Observable. They are
interoperable at the boundary.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Wrong choice leads to missing error handling**
```javascript
// Observable error handling is explicit and easy to miss:
someObs$.subscribe(
  data => use(data),
  err => handle(err) // if this line is omitted: silent failure
);

// vs async/await: compiler/linter can remind you of try/catch
const data = await somePromise; // eslint warns if no try/catch in strict mode
```

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | When Promise, when Observable |
| Trade-off | 2 | Observable overhead for single values, Promise for streams |
| Failure Mode | 1 | Wrong choice, silent errors |
| Debugging | 1 | Converting between abstractions |
| Behavioral | 1 | Team decision making |

**Q1. When would you choose an async generator over
both Promise and Observable?**

Async generators are for:
- Multi-value sequences that are pull-based (consumer controls pace)
- Pagination (fetch next page only when consumer needs it)
- Sequential processing with natural backpressure
- Finite sequences (not infinite event streams)

Decision extended:
- One value, one time: Promise
- Finite sequence, pull-based (pagination): async generator
- Infinite events, push-based (WebSocket): Observable
- Multiple sources combined: Observable

```javascript
// Async generator: paginated API with backpressure
async function* pages(url) {
  let cursor = null;
  while (true) {
    const page = await fetch(`${url}?cursor=${cursor}`).then(r => r.json());
    for (const item of page.items) yield item;
    if (!page.nextCursor) return;
    cursor = page.nextCursor;
  }
}

for await (const item of pages('/api/orders')) {
  await db.insert(item); // backpressure: next page fetches only here
  // if db.insert is slow, network is not hammered
}
```

*What separates good from great:* The backpressure property.
For each iteration of `for await`, the generator advances
to the next `yield`. If the consumer is slow, the generator
pauses. Observables are push-based: no built-in pause.

---

**Q2. How do you convert between Promise and Observable
and why would you?**

```typescript
import { from, firstValueFrom, lastValueFrom } from 'rxjs';

// Promise -> Observable: use from()
const userObs$: Observable<User> = from(fetch('/api/user').then(r => r.json()));

// Observable -> Promise: firstValueFrom (throws if empty)
const user: User = await firstValueFrom(userObs$);
// OR: lastValueFrom (waits for complete, returns last value)
const last: User = await lastValueFrom(userObs$.pipe(take(3)));

// Why convert?
// Observable -> Promise: in async/await context, or in older APIs
//   that take Promise (some React hooks)
// Promise -> Observable: to use Observable operators (switchMap, retry)
//   on a Promise-based API
```

*What separates good from great:* Knowing `firstValueFrom`
throws `EmptyError` if the Observable completes without
emitting. Use `{ defaultValue: undefined }` option to provide
a fallback: `firstValueFrom(obs$, { defaultValue: null })`.

---

**Q3. What are the practical limits of Observables?**

1. **Error handling complexity**: errors terminate the stream.
   Inner operators must catchError or the outer stream dies.
   Promise: try/catch around the whole operation.

2. **Subscription leaks**: forgetting to unsubscribe causes
   memory leaks. Promise: no cleanup needed, GC handles it.

3. **Learning curve**: 100+ operators. Wrong operator choice
   (mergeMap vs switchMap vs concatMap vs exhaustMap) causes
   subtle bugs. Promise: two operations (then, catch).

4. **Not built into JavaScript**: RxJS is a library (~55KB
   bundled). Promise is native, available everywhere.

5. **Testing complexity**: marble testing syntax is powerful
   but adds learning overhead.

*What separates good from great:* Acknowledging observable
limitations while knowing when they provide genuine value.
The engineer who says "use Observables everywhere" does not
understand the trade-offs. The engineer who says "use async/await
everywhere" does not understand concurrent event coordination.

---

**Q4. How does Signals fit into the Promise/Observable decision?**

Signals are a third option for synchronous reactive state:

```typescript
// Signal: for derived component state (synchronous, reactive)
const firstName = signal('Alice');
const lastName  = signal('Smith');
const fullName  = computed(() => `${firstName()} ${lastName()}`);
// fullName updates instantly when firstName or lastName changes
// No async, no subscription, no unsubscribe

// Decision extended:
// One async value: Promise/async-await
// Reactive sync state: Signal/computed
// Event stream / multi-source async: Observable
// Pull-based sequence: async generator
```

Signals DO NOT replace Observables for async. Signals are
synchronous. For a Signal from an Observable (Angular):
```typescript
const user = toSignal(this.userService.user$, { initialValue: null });
// toSignal: subscribes internally, unsubscribes on destroy
// Bridges reactive (Observable) to component state (Signal)
```

*What separates good from great:* `toSignal` is the bridge
pattern for Angular. It converts an Observable into a Signal,
handling subscription and cleanup automatically. This is the
modern Angular pattern: HTTP returns Observable, converted
to Signal at the component boundary for use in templates.

---

**Q5. How would you explain the Promise vs Observable
decision to a non-technical stakeholder?**

Using the email vs newsletter analogy:

Promise: sending an email to one person and waiting for a
reply. One question, one answer, conversation ends.

Observable: subscribing to a newsletter. Once subscribed,
you receive ongoing updates. You can unsubscribe when done.
Multiple issues, arriving over time.

Technical framing: "our live dashboard subscribes to a
data feed (Observable) so it updates automatically as data
changes. Our login button sends a request and waits for
one response (Promise)."

Why this matters for product: "we built the order updates
screen as a live feed (Observable) - when an order status
changes on the server, the screen updates within 1 second
without the user needing to refresh."

*What separates good from great:* Translating technical
decisions into product outcomes. The choice of Observable
for the order updates screen enables the "no-refresh live
updates" product feature. This is why the technical decision
matters to the stakeholder.

---

**Q6. What is the `race` operator and when should you use it?**

`Promise.race` and RxJS `race()`: complete with the first
to emit, cancel/ignore others.

Use cases:
1. Timeout: race a request against a timeout Observable
2. Fastest-wins: send request to multiple endpoints, use
   the fastest response
3. Cache vs network: serve from cache OR from network, whichever
   responds first (with cache likely winning immediately)

```javascript
// Timeout pattern:
const result = await Promise.race([
  fetchData(),
  new Promise((_, reject) =>
    setTimeout(() => reject(new Error('Timeout')), 5000)
  )
]);

// RxJS race with timeout:
const result$ = race(
  this.http.get('/api/data'),
  timer(5000).pipe(
    mergeMap(() => throwError(() => new Error('Timeout')))
  )
);
```

*What separates good from great:* Knowing that `Promise.race`
does not cancel the losing Promises - they continue to run
in the background (but their results are ignored). For true
cancellation: wrap Promises in AbortController, or use
Observable `race()` with proper unsubscription.

---

**Q7. When should you wrap a third-party callback-based API
in Promises vs Observables?**

Decision: will this callback fire once or many times?

Once (Node.js callback, file read, HTTP response):
-> Wrap in Promise (`util.promisify` or manual)

Many times (event listener, WebSocket message, interval):
-> Wrap in Observable (`fromEvent`, `new Observable(...)`)

```javascript
// Once -> Promise:
const data = await util.promisify(fs.readFile)('file.txt');

// Many times -> Observable:
const messages$ = new Observable(subscriber => {
  const ws = new WebSocket('wss://...');
  ws.onmessage = e => subscriber.next(e.data);
  ws.onerror   = e => subscriber.error(e);
  ws.onclose   = () => subscriber.complete();
  return () => ws.close(); // unsubscribe = close
});
```

*What separates good from great:* The Observable constructor
cleanup function (`return () => ws.close()`). When all
subscribers unsubscribe, the cleanup runs. This is the
automatic resource management that makes Observable the
correct abstraction for continuous event sources.

---

# Debugging Async Code: Systematic Approach

---

### 🎯 Model Answer

**30 seconds:**
> Async bugs fall into four categories: race conditions (two
> paths racing to a shared value), timing violations (assuming
> something is ready before it is), resource leaks (async
> resources not cleaned up), and error silencing (rejection
> not caught). Systematic approach: identify the category
> first, then apply the category-specific fix.

**3 minutes:**
> Ad-hoc async debugging - adding console.logs until behavior
> accidentally changes - wastes hours. The systematic approach:
>
> **Step 1: Identify the symptom category**
> - Intermittent: likely race condition
> - Always wrong, consistent: likely timing violation or error silencing
> - Gradually degrading (memory/handles): likely resource leak
> - No output at all: likely unhandled rejection silencing the error
>
> **Step 2: Gather evidence**
> - DevTools: Network tab (request order, timing, cancellations)
> - Performance tab: long tasks, event loop blocking
> - Console: Unhandled Promise rejection warnings
> - Node.js: `--trace-warnings`, `--unhandled-rejections=throw`
>
> **Step 3: Apply category-specific fix**
> - Race condition: serialize with `await`, or use a mutex/lock
> - Timing violation: await the required operation before using result
> - Resource leak: add cleanup in `finally`, `takeUntil`, `AbortController`
> - Error silencing: add `.catch()` or `try/catch`

**Blank Mind Recovery:**

**(1) Restate:** "Four async bug categories: race condition,
timing violation, resource leak, error silencing. Identify
the category, apply the fix. Intermittent = race. Gradual
degradation = leak. Silent failure = swallowed error."

**(2) First principles:** "Async bugs are temporal. They
involve code executing in an unexpected order or at an
unexpected time. Systematic debugging asks: what order DID
the code execute? What order should it have?"

---

### 📘 Concept Explanation

**What it is:**
A systematic methodology for diagnosing and fixing async
JavaScript bugs, organized by bug category.

**The problem it solves:**
Async bugs are harder to reproduce and debug than synchronous
bugs because they depend on timing. A methodology converts
random debugging into structured diagnosis.

**How it works:**

```javascript
// BUG CATEGORY 1: Race Condition
// Two async operations racing to write a shared value
let currentUser = null;

async function loadUser(id) {
  currentUser = null; // reset
  const user = await fetchUser(id); // async gap here
  currentUser = user; // RACE: another loadUser may have run during gap
}

// Diagnosis: call loadUser(1) then quickly loadUser(2)
// currentUser may end up as user 1 (wrong) if user 1 fetches faster
// Fix: use a request token to detect staleness
async function loadUser(id) {
  const token = ++this.requestToken; // increment on each call
  const user = await fetchUser(id);
  if (this.requestToken === token) { // still the latest request?
    currentUser = user;
  }
  // If token doesn't match: a newer call has started, discard result
}
```

```javascript
// BUG CATEGORY 2: Error Silencing
// Promise rejection with no handler: silent failure

async function saveData(data) {
  const result = await db.save(data);
  await cache.invalidate(result.id); // if this throws: exception swallowed
  return result;
}

// Caller:
saveData(payload); // no await, no .catch() = unhandled rejection
// Process continues with no indication of failure

// Detection:
// Node.js: process.on('unhandledRejection', ...)
// Browser: window.addEventListener('unhandledrejection', ...)

// Fix:
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled rejection:', reason);
  // Log to monitoring, alert on-call
});
```

```javascript
// BUG CATEGORY 3: Resource Leak
// Subscription / timer / connection not cleaned up

// LEAK: interval runs after component is destroyed
componentDidMount() {
  this.interval = setInterval(() => {
    this.setState({ time: Date.now() }); // setState on unmounted: error
  }, 1000);
  // If componentWillUnmount doesn't clear: memory leak + error
}
// Missing: componentWillUnmount() { clearInterval(this.interval); }

// Detection: Chrome DevTools Memory tab, Heap snapshot
// Look for: growing heap after repeated mount/unmount
// Node.js: process.memoryUsage().heapUsed growing over time
```

```javascript
// BUG CATEGORY 4: Timing Violation
// Assuming async result is ready synchronously

const [data, setData] = useState(null);

useEffect(() => {
  fetch('/api/data').then(r => r.json()).then(setData);
}, []);

function render() {
  return data.items.map(i => <div key={i.id}>{i.name}</div>);
  // CRASH: data is null on first render, .items throws TypeError
}

// Fix: guard for the async gap:
return data?.items.map(i => <div key={i.id}>{i.name}</div>) ?? <Spinner />;
```

> **Code walkthrough:** The four categories cover the most
> common async bugs. The race condition fix uses a request
> token (incrementing counter) to detect when a newer request
> has superseded the current one - simpler and more reliable
> than AbortController for non-fetch async operations. Error
> silencing is detected via `unhandledRejection` global handlers,
> which should be set up in every Node.js application. Resource
> leaks require cleanup functions in component lifecycles.
> Timing violations require null-guards for async state.

**The key insight:**
Every async bug is a temporal reasoning error. The fix always
involves either: serializing operations that should not race,
handling the time gap between initiation and completion, or
cleaning up resources when the async lifetime ends.

**When to use it:**
Any time an async bug is encountered. Do not start with
`console.log` insertion - start with category identification.

**When NOT to use it:**
Simple synchronous bugs do not need this framework.

**Alternatives:**
- Formal verification (TLA+): for protocol-level correctness
- Property-based testing: for discovering edge cases
- Chaos engineering: for production resiliency

**First-principles derivation:**
All async bugs are violations of temporal assumptions.
The systematic approach makes the temporal assumption explicit,
then fixes the assumption or the code.

---

### 💻 Code Example

```javascript
// BAD: debugging by console.log insertion (non-systematic)
async function loadDashboard() {
  console.log('start');
  const user = await getUser(); // is this the problem?
  console.log('user', user);
  const posts = await getPosts(user.id);
  console.log('posts', posts);
  // Developer adds logs until behavior changes
  // No understanding of WHY it was wrong
}
```

> **Code walkthrough:** The non-systematic approach adds
> console.log statements until the developer accidentally
> discovers the problem. This works but is slow, does not
> build understanding, and the "fix" may not address the root
> cause. The bug may reappear in a different form later.

```typescript
// GOOD: systematic - identify category, apply targeted fix

// STEP 1: Identify category
// Symptom: Dashboard sometimes shows stale user data after login
// Intermittent = Race Condition

// STEP 2: Reproduce reliably
// Reproduce: login, immediately navigate to dashboard
// (fast navigation triggers both login completion and dashboard load)

// STEP 3: Trace the race
// loadDashboard runs before login completes:
// loadDashboard -> getUser returns cached (stale) user
// login completes -> updates user in store
// Dashboard already rendered with stale data

// STEP 4: Apply category fix (race condition = serialize or cancel)
// Option A: wait for login before loading dashboard
class DashboardComponent {
  private readonly user$ = this.auth.user$.pipe(
    filter(u => u !== null),      // wait until logged in
    take(1),                      // one-shot (not reactive)
    switchMap(user => this.loadDashboard(user)), // then load
    takeUntilDestroyed()
  );

  // Option B: invalidate cache after login
  // auth.onLogin$.subscribe(() => queryClient.invalidateQueries());

  // STEP 5: Verify fix
  // Run: login -> immediately navigate. Does dashboard show fresh data?
  // Run 10 times: all show fresh data -> race condition fixed
}
```

> **Code walkthrough:** The systematic approach identifies
> the bug as a race condition before writing any fix code.
> The `filter(u => u !== null)` + `take(1)` pattern waits until
> the user is authenticated before loading the dashboard,
> eliminating the race. The verification step is explicit:
> reproduce the exact scenario 10 times to confirm the fix holds.
> Systematic debugging produces durable fixes, not lucky patches.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> "I start by identifying the bug category: race condition,
> timing violation, resource leak, or error silencing. Each
> category has standard symptoms and fixes. For race conditions:
> check if two async operations are writing to the same value.
> For silent failures: add unhandledRejection handlers."

---

**Senior / Staff (5+ years):**
> "Async bugs are temporal reasoning failures. Before touching
> the code, I establish: (1) is it reproducible, (2) what is
> the execution order that causes the bug, (3) what order should
> it be? For production incidents, I add structured logging of
> async operation start/end with correlation IDs, then replay
> the timeline. For development: browser/node trace tools.
> The systematic approach takes 5 minutes longer upfront but
> saves 2 hours of random console.log debugging."

---

### ⚠️ Common Misconceptions

**Misconception 1:** "Adding await before every async call
fixes all timing issues."
Over-awaiting serializes parallel operations that could run
concurrently. `await fetch1(); await fetch2()` is sequential
(fetch2 waits for fetch1). `await Promise.all([fetch1(), fetch2()])`
is parallel. The wrong choice is a performance bug.

**Misconception 2:** "Using .catch() on every Promise is
sufficient error handling."
`.catch()` on individual Promises does not catch errors in
promise chains where catch is not at the right position,
or errors from async operations not attached to a Promise chain.
Always add a global unhandledRejection handler as a safety net.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Async error telemetry missing in production**
```javascript
// Missing: global async error handlers
// Production: silent failures, no alerting

// FIX: always add global handlers at application start
// Browser:
window.addEventListener('unhandledrejection', event => {
  monitoring.recordError(event.reason);
  event.preventDefault(); // prevent console noise (optional)
});

// Node.js:
process.on('unhandledRejection', (reason, promise) => {
  logger.error({ err: reason, promise }, 'Unhandled rejection');
  metrics.increment('errors.unhandled_rejection');
  // For critical: process.exit(1) with graceful shutdown
});
```

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Conceptual | 2 | Bug categories, systematic methodology |
| Trade-off | 1 | Serial vs parallel await |
| Failure Mode | 2 | Silent rejection, race condition |
| Debugging | 2 | DevTools technique, production async logging |
| Behavioral | 1 | Incident post-mortem with async root cause |

**Q1. How do you detect and diagnose an unhandled Promise
rejection in production?**

Setup (must be in place before bugs occur):
```javascript
// Node.js:
process.on('unhandledRejection', (reason, promise) => {
  logger.error({
    type: 'UNHANDLED_REJECTION',
    error: reason?.message,
    stack: reason?.stack,
    promise: promise.toString()
  });
  metrics.increment('error.unhandled_rejection');
  // Page on-call if error rate spikes
});

// Browser (with source maps):
window.addEventListener('unhandledrejection', (event) => {
  errorTracking.captureException(event.reason, {
    source: 'unhandledrejection',
    promise: event.promise
  });
});
```

Diagnosis from logs:
1. Check the error message and stack trace
2. Identify the Promise that was rejected (stack points to origin)
3. Search codebase for where that Promise is created and
   check if `.catch()` is missing on the chain

*What separates good from great:* Knowing that `--unhandled-rejections=throw`
(Node.js 15+ default) makes unhandled rejections crash the process
like uncaught exceptions. In production, graceful error handling
is preferable to crashes: log, alert, and continue if the error
is non-fatal.

---

**Q2. How do you reproduce and fix an intermittent async
race condition?**

Reproduction:
```javascript
// TECHNIQUE: artificial delay injection
// Add delays to make the race window reliable
async function getUser(id) {
  await delay(Math.random() * 100); // artificial: removes timing luck
  return cache.get(id) || fetch(`/api/user/${id}`).then(r => r.json());
}
// With this delay, the race condition triggers consistently
// Once reproducible: fix and verify without artificial delay
```

Fix pattern (request token):
```javascript
let latestRequestId = 0;

async function loadContent(id) {
  const requestId = ++latestRequestId;
  const content = await fetchContent(id);
  if (requestId !== latestRequestId) {
    return; // superseded by newer call, discard
  }
  render(content);
}
```

Verification:
1. Add a counter: how many times does `requestId !== latestRequestId`?
   This should equal (N-1) for N rapid calls.
2. Remove artificial delay, run stress test (100 rapid calls)
3. Verify: always renders the LAST requested content

*What separates good from great:* The artificial delay injection
technique. Most race conditions have a narrow timing window
that makes them hard to reproduce. Adding `Math.random() * 100ms`
to every async operation reliably opens the window, converting
a 1-in-100 bug into a 99-in-100 bug.

---

**Q3. How do you diagnose event loop blocking in production
Node.js?**

Detection:
```javascript
// Measure event loop lag:
const { monitorEventLoopDelay } = require('perf_hooks');
const histogram = monitorEventLoopDelay({ resolution: 10 });
histogram.enable();

setInterval(() => {
  const p99Ms = histogram.percentile(99) / 1e6; // ns to ms
  metrics.gauge('eventloop.lag.p99ms', p99Ms);
  if (p99Ms > 100) {
    logger.warn({ p99Ms }, 'Event loop lag above threshold');
  }
  histogram.reset();
}, 5000);
```

Diagnosis when lag detected:
```javascript
// V8 CPU profiler via Node.js:
const { session } = require('inspector');
const s = new session.Session();
s.connect();
s.post('Profiler.enable', () => {
  s.post('Profiler.start', () => {
    setTimeout(() => {
      s.post('Profiler.stop', (err, { profile }) => {
        fs.writeFileSync('cpu.cpuprofile', JSON.stringify(profile));
        // Open in Chrome DevTools: Profiles tab
      });
    }, 5000); // profile for 5 seconds during high-lag period
  });
});
```

Common causes found via profiler:
- Synchronous JSON.parse/stringify of large objects
- Synchronous file operations (`fs.readFileSync`)
- Inefficient synchronous algorithms (sorting large arrays)
- Synchronous compression (use streaming)

*What separates good from great:* `monitorEventLoopDelay` is
the Node.js official API for event loop lag measurement (Node.js
11.10+). P99 lag > 100ms typically indicates a blocking operation.
The CPU profiler pinpoints the exact function. Without profiling
data, you are guessing.

---

**Q4. How do you use DevTools to debug async code in the browser?**

Key DevTools techniques:

1. **Async stack traces**: in DevTools Settings, enable
   "Capture async stack traces." This makes Promise-based
   stack traces show the full chain, not just the current
   frame.

2. **Performance tab**: record a trace, look for "Long Tasks"
   (>50ms yellow bars). Click to see which JavaScript blocked.

3. **Network tab**: check request timing, order, cancellations.
   Look for: waterfall vs parallel requests (sequential = bug),
   cancelled requests (may indicate race condition with navigation).

4. **Console**: `Promise` objects are inspectable. Click a
   pending Promise to see its state and the rejection reason.

5. **Breakpoints in async code**: DevTools supports "Pause on
   caught exceptions" and "Pause on uncaught exceptions."
   For async: set a breakpoint inside the `.catch()` handler
   to inspect the rejection before it propagates.

```javascript
// Instrumentation pattern for async debugging:
const originalFetch = window.fetch;
window.fetch = async function(url, init) {
  const start = performance.now();
  try {
    const response = await originalFetch(url, init);
    console.log(`[fetch] ${url}: ${performance.now() - start}ms ${response.status}`);
    return response;
  } catch (err) {
    console.error(`[fetch] ${url}: FAILED`, err);
    throw err;
  }
};
```

*What separates good from great:* The fetch monkey-patching
pattern for temporary debugging. It adds timing and status
to every fetch call without modifying application code.
Remove it before merging.

---

**Q5. What is the correct pattern for cleaning up async
subscriptions in React vs Angular?**

React (useEffect cleanup):
```javascript
// Pattern: return cleanup function from useEffect
useEffect(() => {
  const ctrl = new AbortController();
  const sub = eventSource.subscribe(data => {
    if (!ctrl.signal.aborted) setState(data);
  });

  return () => {
    ctrl.abort();     // cancel in-flight requests
    sub.unsubscribe(); // cancel event source
  };
}, [dependency]); // cleanup runs when dependency changes or unmount
```

Angular (takeUntilDestroyed - Angular 16+):
```typescript
// Pattern: takeUntilDestroyed auto-unsubscribes
stream$.pipe(
  takeUntilDestroyed() // inside injection context: auto-cleanup
).subscribe(data => this.state = data);

// Outside injection context: pass DestroyRef
class MyComponent {
  private destroy = inject(DestroyRef);
  constructor() {
    stream$.pipe(
      takeUntilDestroyed(this.destroy)
    ).subscribe(data => this.state = data);
  }
}
```

*What separates good from great:* `takeUntilDestroyed` in
Angular 16+ vs the older `takeUntil(this.destroy$)` pattern.
The older pattern required a `Subject`, calling `.next()` and
`.complete()` in `ngOnDestroy`. `takeUntilDestroyed` is framework-
managed: injection context handles the lifecycle. Fewer lines,
no forgetting the `ngOnDestroy` call.

---

**Q6. How do you test async code for race conditions?**

Property-based testing approach:
```javascript
// Use fast-check for property testing:
import * as fc from 'fast-check';

test('loadUser always shows correct user for last call', async () => {
  await fc.assert(fc.asyncProperty(
    fc.integer({ min: 1, max: 100 }),  // userId 1
    fc.integer({ min: 1, max: 100 }),  // userId 2
    fc.nat(200),                        // delay between calls (ms)
    async (id1, id2, delayMs) => {
      // Load user 1, then after random delay load user 2
      const p1 = loadUser(id1);
      await delay(delayMs);
      await loadUser(id2);
      // After both resolve: displayed user should always be id2 (last call)
      expect(displayedUserId).toBe(id2);
      // If a race condition exists, some combination of delays will expose it
    }
  ), { numRuns: 100 });
});
```

The random delay generates hundreds of timing combinations,
systematically finding the race window.

*What separates good from great:* Property-based testing
for async is rare but powerful. `fast-check` with `asyncProperty`
runs the test with many random inputs, effectively performing
a timing stress test. A race condition that manifests in 1%
of manual runs will be found in 2-3 of 100 property test runs.

---

**Q7. What is the systematic approach to diagnosing a
production async incident?**

Incident response methodology:

**Phase 1: Stabilize (first 15 minutes)**
- Identify: is it affecting all users or some? Correlate with
  a recent deployment.
- Mitigation: roll back if deployment-correlated.
- Preserve evidence: capture logs, heap dumps, CPU profiles
  before the incident ends or is masked.

**Phase 2: Root cause (post-incident, structured)**
1. Reproduce locally with the exact inputs from production logs
2. Instrument with `console.time`/`console.timeEnd` or APM traces
3. Identify the async operation that failed or produced wrong result
4. Determine the bug category (race, timing, leak, error silencing)
5. Trace the execution path that led to the failure

**Phase 3: Fix and prevent**
1. Fix the root cause
2. Add the specific assertion that would have caught this
   (regression test)
3. Add monitoring that would have detected it earlier
   (unhandledRejection handler, event loop lag, memory metrics)

*What separates good from great:* Phase 1 evidence preservation.
Production bugs are often transient. Once the incident resolves,
the log data and runtime state that could explain the cause
may be gone. Capturing a heap dump or CPU profile DURING the
incident is worth 10x the post-mortem debugging time.
