---
layout: default
title: "JavaScript - L3 Design Patterns"
parent: "JavaScript"
nav_order: 9
permalink: /javascript/l3-design-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [JavaScript Design Patterns](#javascript-design-patterns) | high |
| 2 | [Functional Programming Patterns in JavaScript](#functional-programming-patterns-in-javascript) | high |

---

# JavaScript Design Patterns

🎯 **Interview Weight:** high (★★☆) - Tested at mid/senior level;
demonstrates ability to write maintainable, reusable code beyond
framework-specific patterns

---

### 🎯 Model Answer

**30 seconds:**

> JavaScript design patterns are reusable solutions to common
> structural problems in code. The most interview-relevant are:
> Module (encapsulation), Observer/PubSub (event-driven decoupling),
> Factory (object creation without `new`), Singleton (single shared
> instance), and Strategy (swappable algorithms). The key insight is
> that JavaScript's first-class functions and closures enable many
> patterns more concisely than class-based implementations in other
> languages - a Strategy pattern is often just passing a function.

**3 minutes (Senior):**

> I think about JavaScript design patterns in terms of what problem
> they solve for the codebase, not as abstract templates to memorize.
>
> Observer/PubSub is the most commonly applied pattern in frontend
> code: every event listener is Observer pattern. The distinction is
> Observer (tight coupling, observer holds reference to subject) vs
> PubSub (loose coupling via event bus - publishers and subscribers
> do not know each other).
>
> The Module pattern is how JavaScript achieves encapsulation before
> ES6 modules: an IIFE creates a private scope, returns a public API.
> ES6 modules replaced this entirely - but understanding it helps
> explain legacy code.
>
> Factory functions are frequently better than classes in JavaScript:
> they compose naturally (return mixins of multiple behaviors), do
> not require `new`, and use closures for privacy rather than WeakMap-
> backed `#private` fields. The trade-off is no `instanceof` support.
>
> The pattern I use most in production is Command pattern in event
> sourcing systems - representing user actions as serializable objects
> enables undo/redo, replay, and audit logging. It is the backbone
> of Redux (actions are commands, reducer is the handler).

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Staff discuss the relationship between design patterns
and framework architecture (Redux as Command+Observer, React Context
as Observer, React hooks as Strategy).

*Adapting down:* Junior: Module, Observer, Singleton - the three
they will encounter in real codebases first.

**Blank Mind Recovery:**

**(1) Restate:** "Design patterns - let me think through what problems
arise in large JavaScript codebases that patterns solve."

**(2) First principles:** "As code grows, you need encapsulation,
decoupling, and reuse. Patterns are named solutions to these recurring
structural problems..."

**(3) Bridge:** "Redux is a design pattern combination - Command for
actions, Observer for subscriptions, Reducer as pure state handler.
Knowing the patterns explains why Redux works."

---

### 📘 Concept Explanation

**What it is:**

Design patterns are reusable solutions to recurring structural and
behavioral problems in software. JavaScript's function-first nature
makes many patterns more concise than class-based implementations.

**The problem it solves:**

Without patterns, solutions to recurring problems are reinvented in
ad-hoc ways. Patterns provide shared vocabulary, proven solutions,
and predictable structure for common problems.

**How it works:**

```
Key JavaScript Patterns:

MODULE PATTERN (encapsulation):
  const counter = (() => {
    let count = 0; // private
    return { increment: () => ++count }; // public
  })();

OBSERVER (event subscription):
  Subject has: subscribers[], subscribe(), notify()
  Observer has: update() method
  Tight coupling: observer references subject

PUBSUB (loose coupling variant):
  EventBus.publish('event', data)
  EventBus.subscribe('event', callback)
  Publisher and subscriber never reference each other

FACTORY (object creation):
  function createUser(role) {
    // Returns different shapes based on role
    return role === 'admin' ? AdminUser() : BasicUser();
  }

SINGLETON:
  const db = (() => {
    let instance;
    return { getInstance: () => instance ??= createDb() };
  })();

STRATEGY (swappable algorithms):
  // Just pass a function - Strategy is a first-class function
  sort(array, (a, b) => a - b); // comparator = strategy
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**

In JavaScript, a Strategy pattern is often just passing a function.
A Factory is often just a function returning an object. The patterns
exist as explicit named structures in class-based languages; in
JavaScript they frequently collapse to function composition and
closures - which is why understanding the underlying intent matters
more than the class structure.

**When to use it:**

- Observer/PubSub: cross-component communication without tight coupling
- Factory: when object creation logic is complex or varies
- Singleton: database connections, configuration, loggers
- Strategy: when algorithm/behavior needs to be swappable at runtime
- Command: when you need undo/redo, replay, or audit logging

**When NOT to use it:**

- Don't apply patterns for their own sake - premature pattern
  application adds indirection without benefit
- Singleton is a source of testing difficulty - singleton state
  persists between tests; prefer dependency injection instead
- Deep Observer chains make data flow hard to trace - consider
  unidirectional data flow instead

**Alternatives:**

- Dependency injection → More testable than Singleton
- Unidirectional data flow (Redux, Flux) → More predictable than
  bidirectional Observer
- Functional composition → Replaces many behavioral patterns in
  functional-style code

**First-principles derivation:**

As software grows, three forces create complexity: (1) tight coupling
makes components unable to change independently, (2) duplicated
creation logic makes refactoring error-prone, (3) distributed state
makes behavior unpredictable. Patterns each address one or more
of these forces: Observer decouples, Factory centralizes creation,
Command externalizes state changes.

---

### 💻 Code Example

**Example 1: Observer vs PubSub**

```javascript
// Observer Pattern - direct coupling
class EventEmitter {
  #listeners = new Map();

  on(event, fn) {
    if (!this.#listeners.has(event)) {
      this.#listeners.set(event, []);
    }
    this.#listeners.get(event).push(fn);
    // Return unsubscribe function (clean pattern)
    return () => this.off(event, fn);
  }

  off(event, fn) {
    const fns = this.#listeners.get(event) ?? [];
    this.#listeners.set(event, fns.filter(f => f !== fn));
  }

  emit(event, ...args) {
    (this.#listeners.get(event) ?? []).forEach(fn => fn(...args));
  }
}

// PubSub Pattern - no coupling (bus in between)
const eventBus = (() => {
  const subscribers = {};
  return {
    publish(event, data) {
      (subscribers[event] ?? []).forEach(fn => fn(data));
    },
    subscribe(event, fn) {
      subscribers[event] = [...(subscribers[event] ?? []), fn];
      return () => {
        subscribers[event] =
          subscribers[event].filter(f => f !== fn);
      };
    }
  };
})();

// Usage: components communicate without knowing each other
const unsub = eventBus.subscribe('user:logout', cleanup);
eventBus.publish('user:logout', { userId: 42 });
unsub(); // clean up subscription
```

> **Code walkthrough:** The EventEmitter (Observer) keeps listeners
> per-event in a Map using private fields. Each `on()` call returns
> an unsubscribe function - a clean pattern that avoids forgetting
> to clean up. The PubSub bus uses a closure for private state and
> returns only the publish/subscribe API. Neither publisher nor
> subscriber references the other - the bus is the only shared
> dependency.

**Example 2: Factory and Strategy patterns**

```javascript
// Factory: creation logic varies by type
function createValidator(type) {
  // BAD: switch in caller code repeated everywhere
  // GOOD: centralize creation in factory
  const validators = {
    email: {
      validate: (v) => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v),
      message: 'Invalid email format'
    },
    phone: {
      validate: (v) => /^\+?[\d\s-]{10,}$/.test(v),
      message: 'Invalid phone number'
    },
    required: {
      validate: (v) => v != null && v !== '',
      message: 'This field is required'
    }
  };
  if (!validators[type]) {
    throw new Error(`Unknown validator type: ${type}`);
  }
  return validators[type];
}

// Strategy: algorithm swapped at runtime (just a function)
// BAD: if/else for algorithm selection
function sort(arr, type) {
  if (type === 'asc') return [...arr].sort((a, b) => a - b);
  if (type === 'desc') return [...arr].sort((a, b) => b - a);
}

// GOOD: strategy IS the function - no pattern ceremony needed
function sort(arr, comparator = (a, b) => a - b) {
  return [...arr].sort(comparator);
}

// Strategies are just functions
const ascending = (a, b) => a - b;
const descending = (a, b) => b - a;
const byName = (a, b) => a.name.localeCompare(b.name);

sort([3,1,2], ascending);  // [1, 2, 3]
sort([3,1,2], descending); // [3, 2, 1]
```

> **Code walkthrough:** The Factory centralizes the `validators`
> map, ensuring type-specific creation logic lives in one place.
> New validator types are added by extending the map, not by editing
> callers. The Strategy example shows JavaScript's first-class
> function advantage: a comparator function IS the strategy - no
> Strategy interface, no concrete strategy classes, just pass the
> function. This is the correct idiomatic JavaScript approach.

**Example 3: Command pattern for undo/redo**

```javascript
// Command pattern: actions as serializable objects
class CommandHistory {
  #history = [];
  #position = -1;

  execute(command) {
    // Truncate redo history
    this.#history = this.#history.slice(0, this.#position + 1);
    this.#history.push(command);
    this.#position++;
    command.execute();
  }

  undo() {
    if (this.#position < 0) return;
    this.#history[this.#position].undo();
    this.#position--;
  }

  redo() {
    if (this.#position >= this.#history.length - 1) return;
    this.#position++;
    this.#history[this.#position].execute();
  }
}

// Commands are plain objects with execute/undo
function createAddItemCommand(list, item) {
  return {
    execute() { list.push(item); },
    undo() { list.splice(list.indexOf(item), 1); },
    // Serializable for persistence/audit:
    type: 'ADD_ITEM',
    payload: item
  };
}

const history = new CommandHistory();
const list = [];
history.execute(createAddItemCommand(list, 'item1')); // ['item1']
history.execute(createAddItemCommand(list, 'item2')); // ['item1','item2']
history.undo(); // ['item1']
history.redo(); // ['item1','item2']
```

> **Code walkthrough:** Each command encapsulates an action and its
> inverse. `CommandHistory` maintains a cursor (`#position`) into
> the history array, enabling undo by moving backward and redo by
> moving forward. Executing a new command after undo truncates the
> redo history - standard undo/redo behavior. The `type` and `payload`
> fields make commands serializable for persistence - this is
> exactly how Redux actions work, though Redux doesn't have built-in
> undo (redux-undo implements it with this pattern).

---

### ⚖️ Comparison Table

| Pattern | Coupling | Testability | Use When |
|---|---|---|---|
| **Observer** | Medium (direct ref) | Medium | Component needs direct feedback |
| PubSub | Low (via bus) | High | Cross-module communication |
| Singleton | High (global state) | Low | Configuration, shared resources |
| Factory | Low | High | Complex/varying object creation |
| Strategy | Low | High | Algorithm needs to be swappable |
| Command | Low | High | Undo/redo, audit log, queuing |

**The deciding factor:**
Use Observer for direct parent-child communication; PubSub for
cross-module events; avoid Singleton in favor of DI for testability.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Design patterns are reusable solutions to common problems. The
> ones I use most are: Observer for event handling (like `addEventListener`),
> Module for encapsulation (or just ES6 modules now), and Factory
> for creating objects when creation logic is complex. In JavaScript,
> many patterns reduce to passing functions - a Strategy is often
> just a comparator function parameter.

*Push deeper:* Describe how Redux uses the Command and Observer
patterns. Explain the difference between Observer and PubSub.

---

**Senior / Staff (5+ years):**

> I choose patterns based on the coupling and testability trade-offs.
> Observer/PubSub for decoupled communication - PubSub when
> publishers and subscribers should not know each other. Command
> when I need undo/redo or audit logging - Redux is essentially
> Command + Observer. I avoid Singleton for anything that holds
> mutable state in tests, because test isolation requires independent
> instances - I use dependency injection instead. In modern JS, the
> Strategy pattern is usually just a function parameter.

*Push deeper:* Staff discuss Proxy pattern for reactivity (Vue 3,
MobX), Decorator for aspect-oriented concerns (logging, memoization),
and the relationship between reactive frameworks and the Observer
pattern.

---

### ⚠️ Common Misconceptions

**Misconception 1: Patterns are class-based and require classes.**

In JavaScript, most patterns are expressed more naturally with
functions and closures than with classes. A Factory is a function
that returns objects. A Strategy is a function parameter. Forcing
class syntax onto JavaScript patterns adds unnecessary ceremony.

**Misconception 2: Singleton is a good pattern for shared state.**

Singletons make testing difficult - shared state persists between
tests unless explicitly reset. They hide dependencies. In production,
they cause concurrency issues in clustered Node.js environments
(each worker has its own singleton). Prefer dependency injection.

**Misconception 3: More patterns = better code.**

Patterns should be applied when they solve a real problem - not
to demonstrate pattern knowledge. Applying Observer when a direct
function call suffices adds indirection without benefit. The skill
is knowing which pattern fits, not applying all of them.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Memory leak in Observer - forgotten subscribers.**

Symptom: Memory grows over time; heap snapshot shows large subscriber
lists.

Diagnosis: `subscribe()` adds listeners that are never removed when
the subscriber is destroyed.

Fix: Return unsubscribe functions from `subscribe()`. Call them in
component cleanup. Use `WeakRef` for observer lists where the observer
lifetime is less than the subject.

**Failure 2: Singleton causing state pollution between tests.**

Symptom: Tests pass individually but fail when run together; test
order matters.

Diagnosis: Shared singleton state carries over between tests.

Fix: Reset singleton in beforeEach, or refactor to dependency
injection where each test gets a fresh instance.

**Failure 3: Deep Observer chains making data flow untraceable.**

Symptom: A change in one component causes unexpected updates in
unrelated parts of the UI; debugging requires following a chain
of events.

Fix: Switch to unidirectional data flow (Redux, Zustand) where all
state changes go through a central store. This makes data flow
predictable and debuggable via Redux DevTools.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| Name and describe 3 JavaScript design patterns you use | Definition | ★★☆ | 3 min |
| How does the Observer pattern work? | Mechanism | ★★☆ | 2 min |
| Observer vs PubSub - when does each win? | Comparison | ★★☆ | 2 min |
| Implement an EventEmitter with on, off, emit | Scenario | ★★☆ | 8 min |
| Tests fail when run together but pass individually - suspect Singleton | Debugging | ★★☆ | 3 min |
| How does Redux use design patterns? | Deep Dive | ★★★ | 4 min |
| "More patterns = better code architecture." | Misconception | ★★☆ | 2 min |
| How does Observer scale at 10,000 subscribers? | Performance | ★★☆ | 3 min |
| Why is Vue 3 reactivity an Observer pattern variant? | Deep Dive | ★★★ | 4 min |

**Q: How does Redux use design patterns?**

A: Redux combines three patterns. Command: Redux actions are command
objects - plain data describing what happened (`{ type: 'ADD_ITEM', payload: item }`).
They are serializable, loggable, and replayable. Observer: Redux's
`store.subscribe()` is Observer - components subscribe to store
changes and receive notifications on every dispatch. The `connect()`
function and `useSelector` hook are observer registrations.
Reducer as pure function: Redux reducers are the Command pattern's
handler - they receive the current state and a command (action),
return new state without mutation. This purity is what enables
time-travel debugging in Redux DevTools.

The insight: Redux makes these patterns explicit and enforced. The
constraint that actions are plain objects and reducers are pure is
what enables DevTools to replay the action history and restore any
past state.

*What separates good from great:* The awareness that Redux DevTools'
time-travel is Command pattern replay in action. The recorded action
history is a command log; replaying it from initial state reproduces
any past state deterministically.

**Q: Implement an EventEmitter with on, off, emit, and once.**

A: The implementation requires: a Map from event name to listener
array (private), `on` to add listeners, `off` to remove by reference,
`emit` to call all listeners, and `once` to add a self-removing wrapper.

```javascript
class EventEmitter {
  #listeners = new Map();

  on(event, fn) {
    if (!this.#listeners.has(event)) {
      this.#listeners.set(event, []);
    }
    this.#listeners.get(event).push(fn);
    return () => this.off(event, fn);
  }

  once(event, fn) {
    // Wrap fn to remove itself after first call
    const wrapper = (...args) => {
      fn(...args);
      this.off(event, wrapper); // remove wrapper, not fn
    };
    return this.on(event, wrapper);
  }

  off(event, fn) {
    const fns = this.#listeners.get(event);
    if (fns) {
      this.#listeners.set(event, fns.filter(f => f !== fn));
    }
  }

  emit(event, ...args) {
    // Slice to avoid mutation issues if listeners modify the array
    [...(this.#listeners.get(event) ?? [])].forEach(fn => fn(...args));
  }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Slicing the listener array before
calling `forEach` - if a listener calls `off` or `on` during emit,
it would modify the array being iterated. The slice prevents that
mutation. Also noting that `once` wraps the original function so
the self-removal works correctly even when the user calls `off(event, fn)`
before the once fires.

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


# Functional Programming Patterns in JavaScript

🎯 **Interview Weight:** high (★★☆) - FP patterns are core to modern
JS; pure functions, immutability, and function composition are
expected knowledge at senior level

---

### 🎯 Model Answer

**30 seconds:**

> Functional programming in JavaScript centers on pure functions
> (no side effects, same input always gives same output), immutability
> (create new data structures instead of mutating), and function
> composition (building complex behavior from small functions). The
> key FP tools in JavaScript are `map`, `filter`, `reduce`, closures,
> currying, and higher-order functions. The benefit is predictability -
> pure functions are trivially testable, parallelizable, and cacheable.

**3 minutes (Senior):**

> I apply FP principles selectively in JavaScript rather than as a
> religion. The three principles I apply consistently are: pure
> functions for business logic (easier to test, no hidden state),
> immutable state updates (spread operator or Immer for nested
> objects), and function composition for data transformation pipelines.
>
> Currying enables partial application - locking in some arguments
> to create reusable specialized functions. `map/filter/reduce`
> are the core transformation pipeline. The compose/pipe idiom
> creates left-to-right or right-to-left function chains.
>
> The practical trade-off: FP's immutability creates garbage. If you
> spread-copy a large array on every state update, you generate a
> lot of short-lived objects. This is usually fine with GC, but for
> performance-critical hot paths (60fps animation, real-time data
> processing), mutable in-place updates are faster. I choose FP style
> for correctness-critical business logic and allow mutation in
> performance-critical rendering code.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Staff discuss algebraic data types (Maybe/Result monads)
for error handling, transducers for efficient transformation pipelines,
and why React hooks are a functional pattern.

*Adapting down:* Junior: pure functions, `map/filter/reduce`, no
mutation - the three rules.

**Blank Mind Recovery:**

**(1) Restate:** "Functional programming in JavaScript - let me
think through what makes functions 'functional'."

**(2) First principles:** "A pure function: given the same input,
always returns the same output, no side effects. Everything else
in FP flows from that constraint..."

**(3) Bridge:** "React's hooks are FP applied to UI: `useState`
and `useReducer` are ways to handle state functionally - pure reducer
functions transform state, side effects are isolated in `useEffect`."

---

### 📘 Concept Explanation

**What it is:**

Functional programming (FP) in JavaScript is a style emphasizing pure
functions, immutability, and function composition over mutable state
and class hierarchies.

**The problem it solves:**

Mutable shared state is the primary source of bugs in concurrent and
complex systems. FP eliminates the shared state by making functions
predictable (pure) and data immutable.

**How it works:**

```
Pure function test:
  // PURE: same input → same output, no side effects
  const add = (a, b) => a + b;
  add(1, 2) === add(1, 2); // always true

  // IMPURE: reads external state, has side effects
  let total = 0;
  const addToTotal = (n) => { total += n; return total; };

Immutability:
  // Mutation (BAD for shared state)
  const arr = [1, 2, 3];
  arr.push(4); // mutates original

  // Immutable update (FP style)
  const newArr = [...arr, 4]; // new array
  const newObj = { ...obj, key: 'newValue' }; // new object

Function composition:
  const compose = (...fns) =>
    x => fns.reduceRight((v, f) => f(v), x);
  const pipe = (...fns) =>
    x => fns.reduce((v, f) => f(v), x);

  const process = pipe(
    x => x * 2,  // double
    x => x + 1,  // increment
    x => x ** 2  // square
  );
  process(3); // ((3*2)+1)^2 = 49
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**

Pure functions are trivially unit-testable - no mocking required,
no setup, no teardown. `add(1, 2)` tests with `expect(add(1, 2)).toBe(3)`.
This is why functional-style business logic dramatically reduces
testing friction compared to methods that read class state or call
external services.

**When to use it:**

- Business logic calculations: pure functions, easily tested
- Data transformation pipelines: `map/filter/reduce` chains
- State management reducers: pure function signature `(state, action) => newState`
- Event handlers that should not have side effects

**When NOT to use it:**

- I/O operations are inherently impure; accept this and isolate them
- In-place data structure updates for performance-critical paths
- When deep immutable cloning of large objects creates memory pressure

**Alternatives:**

- OOP with mutation → More intuitive for some domains; harder to test
- Reactive programming (RxJS) → FP for async streams; higher
  abstraction
- Imperative style → Sometimes more readable for simple algorithms

**First-principles derivation:**

Given that bugs arise from unexpected state changes, and state changes
are hardest to trace when they are spread across mutations throughout
a codebase, the functional constraint - no mutation, no side effects -
eliminates the entire class of bugs where "something changed this
value and I don't know where." Pure functions make the change visible
in the function signature: the output is a function only of the input.

---

### 💻 Code Example

**Example 1: Pure function and immutable updates**

```javascript
// IMPURE: mutates argument, reads external state
let taxRate = 0.2;
function calculateTotal(order) {
  order.total = order.subtotal * (1 + taxRate); // mutation!
  return order;
}

// PURE: no mutation, no external state
function calculateTotal(order, taxRate) {
  return {
    ...order, // spread to avoid mutation
    total: order.subtotal * (1 + taxRate)
  };
}

// Deep immutable update (nested objects)
function updateUserAddress(user, newAddress) {
  return {
    ...user,
    profile: {
      ...user.profile,
      address: {
        ...user.profile.address,
        ...newAddress // only override changed fields
      }
    }
  };
}
// Or with Immer for deeply nested structures:
// produce(user, draft => { draft.profile.address.city = 'NYC'; });
```

> **Code walkthrough:** The impure version has two problems: it
> mutates the `order` argument (the caller's object changes) and reads
> `taxRate` from outer scope (hidden dependency). The pure version
> takes all dependencies as arguments and returns a new object without
> mutating the input. Spread operator `{...obj}` creates a shallow
> copy; for deeply nested structures, each level must be spread or
> use Immer's `produce` which handles deep immutability via Proxy.

**Example 2: Currying and partial application**

```javascript
// Manual currying: transform f(a,b,c) → f(a)(b)(c)
const curry = (fn) => {
  const arity = fn.length;
  return function curried(...args) {
    if (args.length >= arity) {
      return fn(...args);
    }
    return (...moreArgs) => curried(...args, ...moreArgs);
  };
};

const add = curry((a, b) => a + b);
const add5 = add(5); // partial application - fixes first arg
add5(3); // 8
add5(10); // 15

// Real use case: create specialized functions from general ones
const multiply = curry((factor, n) => n * factor);
const double = multiply(2);
const triple = multiply(3);

[1, 2, 3, 4].map(double); // [2, 4, 6, 8]
[1, 2, 3, 4].map(triple); // [3, 6, 9, 12]

// Practical: curried event handler creation
const handleEvent = curry((handler, transform, event) => {
  handler(transform(event.target.value));
});
const handleInputChange = handleEvent(setState, v => v.trim());
input.addEventListener('change', handleInputChange);
```

> **Code walkthrough:** Currying transforms a multi-argument function
> into a chain of single-argument functions. `curry(fn)` checks if
> all arguments have been provided; if not, returns a new function
> waiting for the rest. Partial application (fixing some arguments)
> creates specialized functions from general ones - `double` and
> `triple` are `multiply` with the first argument fixed. The event
> handler example shows practical currying: `handleEvent` is curried
> so it can be specialized with handler and transform without
> immediately needing the event object.

**Example 3: Function composition pipeline**

```javascript
// pipe: left-to-right composition (most readable)
const pipe = (...fns) => x => fns.reduce((v, f) => f(v), x);

// Data transformation pipeline
const processUsers = pipe(
  users => users.filter(u => u.active),          // 1. filter active
  users => users.map(u => ({                     // 2. transform shape
    id: u.id,
    name: `${u.firstName} ${u.lastName}`,
    score: u.metrics.totalScore
  })),
  users => users.sort((a, b) => b.score - a.score), // 3. sort desc
  users => users.slice(0, 10)                    // 4. top 10
);

// Alternative: method chaining (similar readability)
const result = users
  .filter(u => u.active)
  .map(u => ({ id: u.id, name: `${u.firstName} ${u.lastName}`,
               score: u.metrics.totalScore }))
  .sort((a, b) => b.score - a.score)
  .slice(0, 10);

// pipe advantage: named, reusable, composable
const getActiveUsers = pipe(
  users => users.filter(u => u.active)
);
const formatUser = u => ({ id: u.id, name: `${u.firstName} ${u.lastName}` });
const getTopN = n => users => users.slice(0, n);

const getTop10ActiveUsers = pipe(
  getActiveUsers,
  users => users.map(formatUser),
  getTopN(10)
);
```

> **Code walkthrough:** `pipe` composes functions left-to-right using
> `reduce` - each function receives the output of the previous.
> This produces readable transformation pipelines where each step
> is a named, single-responsibility function. Compared to method
> chaining, `pipe` works with any functions (not just array methods)
> and each step is independently reusable. The `getTopN(n)` factory
> shows currying and composition together: `getTopN` is a curried
> function that returns a function suitable for use in `pipe`.

---

### ⚖️ Comparison Table

| Style | Predictability | Performance | Testability | Choose When |
|---|---|---|---|---|
| **Functional (pure)** | Very high | Lower (GC pressure) | Very high | Business logic, reducers |
| OOP with mutation | Medium | Higher (in-place) | Medium | Complex domain models |
| Imperative mutation | Low | Highest | Low | Performance hot paths |
| Reactive (RxJS) | High (explicit) | Medium | Medium | Async event streams |

**The deciding factor:**
Pure FP for business logic and state management; allow controlled
mutation in performance-critical paths.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Functional programming means using pure functions (same input, same
> output, no side effects), immutable data (create new objects/arrays
> instead of mutating), and methods like `map`, `filter`, `reduce`
> for transformations. Pure functions are easy to test - no mocks
> needed, just call the function and check the return value.

*Push deeper:* Explain what currying is. Describe function composition
with an example.

---

**Senior / Staff (5+ years):**

> I apply FP principles selectively. Pure functions for all business
> logic - they require no mocking, just call and assert. Immutable
> state updates for predictable change tracking - React's `useState`
> and Redux both require immutability for change detection. Function
> composition for data transformation pipelines - more readable and
> testable than nested function calls. The trade-off I accept: FP
> immutability creates more garbage collection pressure; for 60fps
> animation or real-time data, I allow controlled in-place mutation.

*Push deeper:* Staff discuss algebraic data types (Option/Either
monads), transducers for efficient pipeline composition, why React
hooks are a functional architecture, and how Immer bridges
immutability with mutation ergonomics.

---

### ⚠️ Common Misconceptions

**Misconception 1: FP means never using variables or mutation.**

FP avoids shared mutable state, not all mutation. Local mutation
within a function that is not observable from outside is fine: a
`for` loop with a local accumulator variable is still functionally
pure from the caller's perspective. `Array.prototype.sort` mutates
in place but if you operate on a copy, the original remains pure.

**Misconception 2: `reduce` is always the functional way.**

`reduce` is the most powerful but least readable array method.
For many transformations, `map` + `filter` is clearer and should
be preferred. `reduce` excels for accumulation, grouping, and
transforming to non-array types. Using `reduce` where `map` suffices
is unnecessary complexity.

**Misconception 3: FP is slower than imperative code.**

Functional patterns often create more garbage (new arrays/objects
per transform step), which increases GC pressure. For most business
logic this is negligible. For tight inner loops, in-place mutation
is faster. The correctness and testability benefits of FP usually
far outweigh the performance cost in typical web application code.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Accidental mutation of shared state.**

Symptom: Calling function with object A, then object A has changed
unexpectedly; tests pass in isolation but fail when run together.

Diagnosis: A "pure" function was mutating its argument. Check with
deep equality: `const before = JSON.stringify(arg); fn(arg); const after = JSON.stringify(arg); assert(before === after)`.

Fix: Replace mutation with spread: `return { ...arg, changed: value }`.
For arrays: `return [...arr, newItem]` not `arr.push(newItem); return arr`.

**Failure 2: Stack overflow from recursive FP patterns.**

Symptom: `Maximum call stack size exceeded` in deeply recursive
functional code.

Diagnosis: Recursive reduce/fold on deeply nested structures without
tail-call optimization.

Fix: JavaScript does not reliably implement tail-call optimization.
Use iterative approaches (trampoline pattern or explicit stack) for
deep recursion. Most practical data is shallow enough that recursion
is fine for trees of depth < 1000.

**Failure 3: Performance degradation from excessive object spreading.**

Symptom: Performance profiler shows high allocation rate; frequent
minor GC pauses.

Diagnosis: Immutable updates of large objects or arrays in tight
loops creating many short-lived objects.

Fix: Use Immer for complex nested updates - it uses Proxy to record
changes and produce the minimal updated structure. For performance-
critical paths, allow controlled local mutation with documented
boundaries.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is a pure function? | Definition | ★★☆ | 1 min |
| How does immutability enable change detection in React? | Mechanism | ★★☆ | 3 min |
| FP vs OOP - when does each approach win? | Comparison | ★★☆ | 3 min |
| Rewrite this imperative data pipeline as a functional pipe | Scenario | ★★☆ | 8 min |
| State updates are being lost in Redux - likely cause? | Debugging | ★★☆ | 3 min |
| How do React hooks implement functional state management? | Deep Dive | ★★★ | 4 min |
| "FP means never mutating anything, ever." | Misconception | ★★☆ | 2 min |
| How does immutable state affect GC at 60fps? | Performance | ★★★ | 3 min |
| What is a monad and why should JavaScript developers care? | Deep Dive | ★★★ | 5 min |

**Q: How does immutability enable change detection in React?**

A: React uses reference equality (`===`) to decide whether to
re-render. When state is a plain object, `state === newState` is
true if they are the same object in memory - even if properties
changed. If you mutate state in place, `setState(mutatedState)`,
React sees `state === mutatedState` (same reference) and skips
re-render even though data changed.

Immutable updates create new references: `setState({ ...state, count: state.count + 1 })`.
Now `state !== newState` (different objects), React sees a change
and schedules re-render. This is why Redux requires immutable updates
in reducers and why React warns against direct state mutation.

The optimization angle: `React.memo`, `useMemo`, and `useCallback`
all rely on referential equality. If you pass a new object on every
render - `<Child options={{ key: 'value' }} />` - `React.memo`
never bails out because `{}` creates a new reference each time.

*What separates good from great:* Understanding that `Object.is`
(used internally by React) is essentially `===` with two special
cases: `Object.is(NaN, NaN)` is true; `Object.is(-0, +0)` is false.
These edge cases matter for number state.

**Q: What is a monad and do JavaScript developers need to know them?**

A: A monad is a design pattern from category theory that wraps a
value in a context and provides two operations: `return` (wrap a
value) and `bind`/`chain` (apply a function to the wrapped value
and get back a monad). This enables chaining operations that might
fail without explicit null checks.

In JavaScript: Promises are monads. `then` is `bind`: it takes
a function, applies it to the resolved value, and returns a new
Promise (the monad). `Promise.resolve(value)` is `return`. The
monad laws ensure that chaining is associative: `p.then(f).then(g)`
equals `p.then(x => f(x).then(g))`.

Practical application: the Result/Either pattern for error handling.
Instead of `throw`, functions return `{ ok: true, value }` or
`{ ok: false, error }`. You can chain operations: `parseConfig().then(validateConfig).then(applyConfig)`, where each step returns Result and errors short-circuit without try/catch.

*What separates good from great:* Knowing that you use monads daily
(Promises, Array `flatMap`) without calling them monads. The academic
name matters less than understanding the pattern: wrap a value,
chain operations, handle the context (async, nullable, error) uniformly.

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



