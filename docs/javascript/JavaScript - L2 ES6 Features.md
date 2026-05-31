---
layout: default
title: "JavaScript - L2 ES6 Features"
parent: "JavaScript"
nav_order: 8
permalink: /javascript/l2-es6-features/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [ES6 Classes and Inheritance](#es6-classes-and-inheritance) | high |
| 2 | [JavaScript Modules (ESM and CommonJS)](#javascript-modules-esm-and-commonjs) | critical |

---

# ES6 Classes and Inheritance

🎯 **Interview Weight:** high (★★☆) - Asked to test OOP understanding
in JavaScript; the trap is assuming ES6 classes are "real" classes -
they are syntactic sugar over prototype chains

---

### 🎯 Model Answer

**30 seconds:**

> ES6 classes are syntactic sugar over JavaScript's prototype-based
> inheritance - not a new object model. `class Foo extends Bar` sets
> up the prototype chain so `Foo.prototype` inherits from `Bar.prototype`.
> The `constructor` runs when `new` is called; `super()` calls the
> parent constructor. The key insight is that `typeof MyClass === 'function'`
> - classes are constructor functions with prototype-chain sugar.
> Methods defined in class bodies are non-enumerable, unlike manually
> assigning to `prototype`.

**3 minutes (Senior):**

> ES6 classes make inheritance readable and reduce boilerplate, but
> understanding what they compile to is critical for debugging and
> for interview questions about JavaScript's object model.
>
> When you write `class Animal { speak() {} }`, the result is a
> constructor function `Animal` with `Animal.prototype.speak` as
> a non-enumerable method. `class Dog extends Animal` sets
> `Dog.prototype = Object.create(Animal.prototype)` and
> `Dog.__proto__ = Animal` (for static inheritance). `super.speak()`
> resolves via `Animal.prototype.speak.call(this)`.
>
> Private fields with `#` are a genuine runtime feature - they use
> WeakMap-based storage and are truly private, not closures or naming
> conventions. Static fields and methods live on the class itself,
> not on instances.
>
> The trade-offs: classes encourage deep inheritance hierarchies which
> create tight coupling. Composition (mixins, plain functions) is often
> better than inheritance for reuse. In React and modern JS, class
> components have been largely replaced by function components with
> hooks - composition won the debate.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Staff discuss prototype chain manipulation, mixin
patterns as alternatives to deep hierarchies, and why TC39 added
`#private` fields vs closure-based privacy.

*Adapting down:* Junior: `class`, `extends`, `super`, `constructor` -
the four keywords; one example of each.

**Blank Mind Recovery:**

**(1) Restate:** "ES6 classes - let me think through what they
actually are under the hood."

**(2) First principles:** "JavaScript always used prototype chains.
Classes add syntax to make inheritance readable without changing
the underlying mechanism..."

**(3) Bridge:** "This is similar to how TypeScript types compile away
- ES6 classes compile to ES5 prototype code that does the same thing."

---

### 📘 Concept Explanation

**What it is:**

ES6 class syntax is a cleaner way to write constructor functions and
prototype chain setup. It does not introduce a new object model -
it desugars to prototype-based inheritance.

**The problem it solves:**

Pre-ES6 prototype inheritance required verbose, error-prone boilerplate:
`Child.prototype = Object.create(Parent.prototype); Child.prototype.constructor = Child;`
Classes make inheritance readable and predictable.

**How it works:**

```
class Animal {
  constructor(name) { this.name = name; }
  speak() { return `${this.name} speaks`; }
}
class Dog extends Animal {
  speak() { return super.speak() + ' woof'; }
}

Compiles to (conceptually):
  Animal.prototype.speak = function() {...}
  Dog.prototype = Object.create(Animal.prototype)
  Dog.__proto__ = Animal  // static chain
  Dog.prototype.speak = function() {
    Animal.prototype.speak.call(this) + ' woof'
  }

instanceof check:
  new Dog() instanceof Dog    → true
  new Dog() instanceof Animal → true (prototype chain)
  typeof Dog                  → 'function' (it's still a function)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**

`typeof Dog === 'function'` - ES6 classes are constructor functions.
The `class` keyword enforces: must use `new`, methods are non-enumerable,
`super()` must be called before `this` in derived constructors, and
in strict mode only. These enforcements prevent the common mistakes
of prototype-based inheritance.

**When to use it:**

- Building APIs where instances share behavior (data models, services)
- When extending browser built-ins (`class MyError extends Error`)
- When working with frameworks that require class syntax (some decorators)

**When NOT to use it:**

- Don't use deep inheritance hierarchies (3+ levels) - use composition
- Don't use classes as namespaces (static-only) - use plain objects
- In modern React - prefer function components; class components are
  legacy

**Alternatives:**

- Factory functions → Closure-based privacy; composable; no `new`
  required; more flexible but no `instanceof` support
- Object.create / mixins → Explicit prototype manipulation; good for
  multiple inheritance patterns
- Module pattern → Private state without classes; preferred in
  functional-style code

**First-principles derivation:**

JavaScript chose prototype-based inheritance (simpler than classical)
but prototype chain syntax was too verbose for readable code. ES6
classes apply the principle of least surprise: class syntax looks
like other languages, compiles to the same prototype chains, and
enforces the correct usage pattern via syntax.

---

### 💻 Code Example

**Example 1: Class basics and inheritance**

```javascript
class Animal {
  #name; // private field - truly inaccessible outside class

  constructor(name) {
    this.#name = name;
  }

  speak() {
    return `${this.#name} makes a sound`;
  }

  get name() { return this.#name; } // public accessor
}

class Dog extends Animal {
  #breed;

  constructor(name, breed) {
    super(name); // MUST call super before using this
    this.#breed = breed;
  }

  speak() {
    // super.speak() resolves to Animal.prototype.speak.call(this)
    return super.speak() + ': Woof!';
  }

  static create(name, breed) {
    // Static method - lives on Dog, not Dog.prototype
    return new Dog(name, breed);
  }
}

const d = Dog.create('Rex', 'Labrador');
console.log(d.speak()); // Rex makes a sound: Woof!
console.log(d instanceof Dog);    // true
console.log(d instanceof Animal); // true (prototype chain)
// d.#name → SyntaxError: private fields are truly private
```

> **Code walkthrough:** Private fields (`#name`) are WeakMap-backed
> and inaccessible outside the class body - not just a naming
> convention. `super()` must be called before any `this` access in
> derived constructors; the JS engine enforces this. Static methods
> live on the constructor function itself, not on instances - accessed
> via `Dog.create()`, not `d.create()`.

**Example 2: Composition vs inheritance**

```javascript
// BAD: deep inheritance - tight coupling, fragile base class problem
class Vehicle { move() {} }
class Car extends Vehicle { drive() {} }
class ElectricCar extends Car {
  charge() {}
  // Now inherits EVERYTHING from Car and Vehicle
  // What if we want an ElectricBike? Inherit from both?
}

// GOOD: composition with mixins - mix in only what you need
const Serializable = (Base) => class extends Base {
  serialize() { return JSON.stringify(this); }
};

const Validatable = (Base) => class extends Base {
  validate() { return Object.keys(this).length > 0; }
};

class User {
  constructor(name, email) {
    this.name = name;
    this.email = email;
  }
}

// Compose only needed behaviors
class SerializableUser extends Serializable(User) {}
class ValidatableUser extends Validatable(User) {}
class FullUser extends Serializable(Validatable(User)) {}
```

> **Code walkthrough:** The mixin pattern (a function that takes a
> base class and returns an extended class) enables multiple behavior
> composition without deep hierarchies. `Serializable` and `Validatable`
> are independent behaviors that can be mixed into any class.
> This avoids the fragile base class problem where a change to
> a deep ancestor breaks all descendants.

**Example 3: Custom error with proper stack traces**

```javascript
// BAD: plain object errors lose instanceof checks and stack traces
function fetchUser(id) {
  throw { code: 'NOT_FOUND', message: 'User not found' };
}

// GOOD: extend Error for proper stack traces and instanceof
class AppError extends Error {
  constructor(message, code, statusCode = 500) {
    super(message); // sets this.message and captures stack
    this.name = this.constructor.name; // 'AppError'
    this.code = code;
    this.statusCode = statusCode;
  }
}

class NotFoundError extends AppError {
  constructor(resource, id) {
    super(`${resource} ${id} not found`, 'NOT_FOUND', 404);
    this.resource = resource;
    this.id = id;
  }
}

try {
  throw new NotFoundError('User', '42');
} catch (err) {
  console.log(err instanceof NotFoundError); // true
  console.log(err instanceof AppError);      // true
  console.log(err instanceof Error);         // true
  console.log(err.stack); // full stack trace from super(message)
}
```

> **Code walkthrough:** Extending `Error` properly requires calling
> `super(message)` to set `this.message` and capture the stack trace.
> Setting `this.name = this.constructor.name` gives the correct class
> name in error output rather than "Error". This pattern enables
> `instanceof` checks in catch blocks to handle different error types
> differently - a pattern impossible with plain error objects.

---

### ⚖️ Comparison Table

| Pattern | Privacy | Multiple inheritance | `instanceof` | Choose When |
|---|---|---|---|---|
| **ES6 class** | `#private` fields | No (single extends) | Yes | OOP APIs, extending builtins |
| Factory function | Closure-based | Yes (compose) | No | Functional style, flexible composition |
| Object.create | None built-in | Yes (manual) | Yes (if set up) | Explicit prototype control |
| Mixin pattern | None | Yes | Partial | Adding behaviors to existing hierarchy |

**The deciding factor:**
Use classes when `instanceof` checks and extending builtins matter;
use factory functions or mixins when behavior composition across
multiple sources is needed.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> ES6 classes use `class`, `extends`, `constructor`, and `super`.
> `extends` sets up inheritance so the child has all parent methods.
> `super()` calls the parent constructor; must be called before using
> `this` in a child constructor. Methods in a class body are on the
> prototype, not on each instance - so they are shared, not copied.
> Private fields with `#` are truly private.

*Push deeper:* Explain what `typeof MyClass` returns. Describe
the difference between instance methods and static methods.

---

**Senior / Staff (5+ years):**

> I understand ES6 classes as prototype chain setup with enforcement.
> The class syntax prevents the common prototype mistakes: `new` is
> enforced, `super()` before `this` is enforced, methods are
> non-enumerable. For deep inheritance I prefer composition - mixin
> functions that extend a base class - because deep hierarchies create
> fragile base class problems. Private fields (`#`) are a genuine
> runtime feature using WeakMap storage, not just a naming convention
> like `_private`.

*Push deeper:* Staff discuss the fragile base class problem in depth,
why React moved from class components to function components,
decorator patterns that require classes, and prototype chain
manipulation for polyfills.

---

### ⚠️ Common Misconceptions

**Misconception 1: ES6 classes introduce a new object model.**

Classes are syntax sugar. `typeof MyClass === 'function'`. The
prototype chain works exactly the same as pre-ES6. Understanding
this matters for debugging: `console.log(Dog.prototype)` shows the
same methods whether you write a class or manually set up the chain.

**Misconception 2: `_privateProp` is a private field.**

Underscore prefix is a naming convention with no enforcement - any
code can access `obj._privateProp`. True private fields require `#`:
`this.#secret` is inaccessible outside the class body, enforced by
the JavaScript engine, not by convention.

**Misconception 3: Class methods are on the instance.**

Methods defined in a class body (without `static`) are on
`ClassName.prototype`, shared across all instances. Only properties
assigned in `constructor` via `this.x = val` are per-instance.
Arrow functions assigned as class fields (`onClick = () => {}`) ARE
per-instance - they are created in the constructor for each instance.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: `this` is undefined in a class method used as callback.**

Symptom: `TypeError: Cannot read property of undefined` when a class
method is passed as an event callback.

Diagnosis: Class methods are regular functions. When passed as a
callback, `this` is not bound to the instance - it is undefined in
strict mode.

Fix: Arrow function class field `handleClick = () => { this.name }` -
bound to instance. Or `el.addEventListener('click', this.handleClick.bind(this))`.

**Failure 2: `super()` not called before `this` in derived class.**

Symptom: `ReferenceError: Must call super constructor in derived class
before accessing 'this'`.

Diagnosis: Derived class constructor uses `this` before calling
`super()`.

Fix: Always call `super(/* args */)` as the first statement in a
derived constructor.

**Failure 3: Static property accessed on instance.**

Symptom: `instance.staticMethod()` is `undefined`.

Diagnosis: Static methods/properties live on the class, not
instances. `instance.staticMethod` is undefined.

Fix: Access via the class name: `ClassName.staticMethod()`. Or use
`this.constructor.staticMethod()` within instance methods.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is `class` sugar for in JavaScript? | Definition | ★★☆ | 2 min |
| How does `extends` set up the prototype chain? | Mechanism | ★★☆ | 3 min |
| Factory functions vs ES6 classes - trade-offs? | Comparison | ★★☆ | 3 min |
| Design an error hierarchy for a REST API service | Scenario | ★★☆ | 5 min |
| Class method loses `this` when used as callback - diagnose and fix | Debugging | ★★☆ | 3 min |
| Why did React move from class to function components? | Deep Dive | ★★★ | 4 min |
| "Private fields with `_underscore` are as safe as `#private`." | Misconception | ★★☆ | 2 min |
| How does deep inheritance perform vs composition at scale? | Performance | ★★☆ | 2 min |
| Explain the fragile base class problem with a concrete example | Deep Dive | ★★★ | 4 min |

**Q: What does `class Foo extends Bar` actually do to the prototype chain?**

A: Two things happen: `Foo.prototype` is set to `Object.create(Bar.prototype)`,
which makes instances of `Foo` inherit `Bar`'s instance methods via
the prototype chain. And `Foo.__proto__` is set to `Bar` itself
(not `Bar.prototype`), which makes static methods on `Bar` accessible
via `Foo.staticMethod()`.

When `super.methodName()` is called in a Foo instance, JavaScript
looks up `Bar.prototype.methodName` and calls it with `this` bound
to the current instance. `super()` in the constructor calls
`Bar.call(this, ...args)`, which is why it must run before any
`this` usage - the instance is not fully initialized until the parent
constructor runs.

*What separates good from great:* Knowing both the instance prototype
chain and the constructor function chain. Most candidates know
`Foo.prototype → Bar.prototype`, but fewer know `Foo.__proto__ === Bar`
which is what enables static method inheritance.

**Q: Why did React move from class to function components?**

A: Class components had several problems. `this` binding in callbacks
was a persistent source of bugs requiring `bind` or arrow function
class fields. The lifecycle methods (`componentDidMount`,
`componentDidUpdate`) duplicated logic - related code was split across
methods, unrelated code was forced into the same method. No mechanism
for reusing stateful logic across components without HOC or render
prop gymnastics.

Hooks solved all three: no `this`, related logic co-located in one
`useEffect`, and custom hooks enable stateful logic reuse without
wrapper components. The composition model of function components
proved superior for sharing behavior - composition over inheritance
in practice, at scale.

*What separates good from great:* Mentioning that class components
still work in React and are not deprecated - the move was a
recommendation, not a removal. Staff engineers can articulate when
a class component might still be preferred (error boundaries still
require classes as of React 18).

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


# JavaScript Modules (ESM and CommonJS)

🎯 **Interview Weight:** critical (★★☆) - Module systems are asked
in every Node.js and bundler context; the CJS vs ESM distinction
is the source of "Cannot use import statement in a module" errors

---

### 🎯 Model Answer

**30 seconds:**

> JavaScript has two module systems: CommonJS (CJS) used in Node.js
> with `require()` and `module.exports`, and ES Modules (ESM) used
> in browsers and modern Node.js with `import`/`export`. The critical
> difference: CJS is synchronous and dynamic - `require()` can be
> called anywhere, at runtime, with dynamic paths. ESM is static and
> asynchronous - `import` declarations are analyzed at parse time,
> enabling tree shaking. They are not directly interoperable without
> a compatibility layer.

**3 minutes (Senior):**

> The module system difference matters most in two contexts: bundlers
> and Node.js interoperability. Bundlers like webpack and Rollup need
> ESM for tree shaking - they analyze `import` graphs statically at
> build time to identify and eliminate unused exports. CJS `require()`
> calls with dynamic paths cannot be statically analyzed, so dead
> code cannot be eliminated. This is why library authors are pushed
> to publish ESM alongside CJS.
>
> In Node.js, CJS is the historical default: files are CJS unless
> the package.json has `"type": "module"` or the file extension is
> `.mjs`. ESM files use `import`/`export` and top-level `await`.
> The interop rules are strict: ESM can import CJS (the `module.exports`
> object becomes the default export), but CJS cannot `require()` ESM
> (because ESM loading is asynchronous, and `require()` is synchronous).
>
> Named exports in ESM are live bindings - if a module updates an
> exported variable, the importing module sees the update. CJS
> `module.exports` properties are copied at require time - not live
> bindings. This difference matters for modules that export counters
> or state.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Staff discuss dual-package publishing (CJS+ESM), the
`exports` map in package.json for conditional exports, and the
Node.js module resolution algorithm differences between CJS and ESM.

*Adapting down:* Junior: `import`/`export` for browser/modern code;
`require`/`module.exports` for Node.js; they are different and not
directly mixable.

**Blank Mind Recovery:**

**(1) Restate:** "Module systems - let me think through why JavaScript
needed a module system in the first place."

**(2) First principles:** "Before modules, all JavaScript was in the
global scope. Modules add encapsulation - each file has its own scope.
The question is how imports work: static analysis or runtime lookup..."

**(3) Bridge:** "This is like the difference between compiled imports
(static, analyzed at build time) and dynamic loading (runtime, flexible)."

---

### 📘 Concept Explanation

**What it is:**

JavaScript module systems enable encapsulation and code sharing
between files. CommonJS (CJS) uses `require()`/`module.exports`;
ES Modules (ESM) uses `import`/`export`. Both solve the same problem
with different semantics and performance trade-offs.

**The problem it solves:**

Without modules, all scripts share the global scope, leading to naming
collisions and uncontrolled dependencies. Modules give each file its
own scope and explicit dependency declarations.

**How it works:**

```
CommonJS (CJS):
  // math.js
  module.exports = { add: (a,b) => a+b };

  // app.js
  const { add } = require('./math'); // synchronous
  // require() runs the file, caches the module.exports object

  Dynamic: require(condition ? 'a' : 'b') is valid
  Timing: module.exports is a value at require-time (copy)

ES Modules (ESM):
  // math.js
  export const add = (a,b) => a+b;
  export default 42;

  // app.js
  import { add } from './math.js'; // static, hoisted
  import defaultValue from './math.js';

  Static: import paths must be string literals (mostly)
  Timing: named exports are LIVE BINDINGS (not copies)
  Top-level await: allowed in ESM, not in CJS

Resolution differences:
  CJS: require('./math') → looks for math.js, math/index.js
  ESM: import './math.js' → must include extension (browser)
       import './math' → Node.js resolves (with some rules)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**

ESM named exports are live bindings - they point to the binding in
the exporting module. If the exporting module updates a counter, all
importing modules see the updated value. CJS `module.exports` is a
value copied at require-time. This means CJS cannot reliably export
mutable state that consumers observe.

**When to use it:**

- ESM: browser code, libraries, modern Node.js, anything bundled;
  enables tree shaking, top-level await, static analysis
- CJS: legacy Node.js code, packages that must work in older Node
  versions without transpilation, when synchronous module loading
  is required

**When NOT to use it:**

- Don't mix CJS `require()` and ESM `import` in the same file without
  a bundler handling the transpilation
- Don't use dynamic `require()` in code that must be tree-shakable
- Don't use CJS for new libraries that target modern environments

**Alternatives:**

- AMD (RequireJS) → Legacy browser module system; async loader;
  effectively obsolete with bundlers
- UMD → Universal format supporting CJS, AMD, and globals; used for
  library dual publishing before ESM; largely replaced by dual
  CJS+ESM packages
- IIFE bundles → Self-contained scripts with no import/export;
  still used for simple embeddable scripts

**First-principles derivation:**

Modules need: (1) encapsulated scope, (2) explicit dependency
declarations, (3) a loading mechanism. Browser constraints require
asynchronous loading (network latency). Server constraints allowed
synchronous loading (local filesystem). This is why CJS is
synchronous (Node.js design) and ESM is async-compatible (browser
design). TC39 standardized ESM to work in both environments.

---

### 💻 Code Example

**Example 1: CJS vs ESM syntax comparison**

```javascript
// CommonJS (CJS) - Node.js default
// math.cjs
const PI = 3.14159;
function add(a, b) { return a + b; }
module.exports = { PI, add }; // export object

// app.cjs
const { PI, add } = require('./math.cjs');
const dynModule = require(process.env.MODULE_NAME); // dynamic OK
console.log(add(1, PI)); // 4.14159

// ES Modules (ESM) - browser/modern Node
// math.mjs
export const PI = 3.14159;
export function add(a, b) { return a + b; }
export default 'math module'; // default export

// app.mjs
import defaultExport, { PI, add } from './math.mjs';
// import paths must include extension in browser ESM
// top-level await: allowed in ESM
const data = await fetch('/api/data').then(r => r.json());
```

> **Code walkthrough:** CJS uses `module.exports` as an export
> object and `require()` for synchronous imports. ESM uses named
> `export` declarations and `import` statements. The key behavioral
> difference: CJS runs the module and assigns the result to a variable
> (copy semantics for primitives); ESM exports are live bindings.
> Top-level await is only available in ESM - it allows module
> initialization to be async without wrapping in an async function.

**Example 2: Live binding difference**

```javascript
// ESM LIVE BINDINGS
// counter.mjs
export let count = 0;
export function increment() { count++; }

// app.mjs
import { count, increment } from './counter.mjs';
console.log(count); // 0
increment();
console.log(count); // 1 - live binding, sees update!

// CJS COPY SEMANTICS
// counter.cjs
let count = 0;
function increment() { count++; }
module.exports = { count, increment };

// app.cjs
const { count, increment } = require('./counter.cjs');
console.log(count); // 0
increment();
console.log(count); // STILL 0 - count was copied at require time
// To observe: const mod = require('./counter.cjs'); mod.count
```

> **Code walkthrough:** ESM named exports are live bindings - the
> importing module has a live reference to the binding in the exporting
> module. When `increment()` updates `count`, all importers see the
> new value immediately. CJS destructuring copies the value at require
> time; to see updates, you must reference `module.count` rather than
> destructuring. This distinction is critical for modules exporting
> mutable state, configuration singletons, or feature flags.

**Example 3: Node.js interop and package.json configuration**

```javascript
// package.json for dual-package publishing
{
  "name": "my-lib",
  "version": "1.0.0",
  "main": "./dist/cjs/index.js",    // CJS entry (legacy)
  "module": "./dist/esm/index.js",  // ESM entry (bundlers)
  "exports": {
    ".": {
      "import": "./dist/esm/index.js",  // ESM: import
      "require": "./dist/cjs/index.js", // CJS: require()
      "types": "./dist/types/index.d.ts"
    }
  }
}

// ESM can import CJS (default export = module.exports)
// esm-consumer.mjs
import cjsModule from './legacy-lib.cjs'; // module.exports = default
// named exports from CJS need manual destructuring:
const { namedExport } = cjsModule;

// CJS CANNOT require() ESM (ESM is async, require is sync)
// This will throw: ERR_REQUIRE_ESM
const esmModule = require('./esm-lib.mjs'); // ERROR

// CJS async workaround (Node.js 22+ experimental):
// async function loadESM() {
//   const mod = await import('./esm-lib.mjs');
// }
```

> **Code walkthrough:** The `exports` map in package.json enables
> conditional exports - bundlers use the `import` condition, Node.js
> CJS uses `require`. Dual-package publishing solves the CJS/ESM
> interop problem for library authors by shipping both formats.
> The one-way interop restriction (ESM can import CJS; CJS cannot
> require ESM) exists because `require()` is synchronous but ESM
> loading is fundamentally async - there is no synchronous wrapper
> possible.

---

### ⚖️ Comparison Table

| Feature | CommonJS (CJS) | ES Modules (ESM) | Choose When |
|---|---|---|---|
| Load timing | Synchronous | Asynchronous | CJS: server init; ESM: browser/bundler |
| Dynamic import | `require(variable)` | `import()` function | Both support dynamic; ESM preferred |
| Exports | Value copy (mostly) | Live bindings | ESM for shared mutable state |
| Tree shaking | Not possible | Yes (static) | ESM for libraries |
| Top-level await | No | Yes | ESM for async module init |
| Node.js default | Yes | With `"type":"module"` | CJS: legacy; ESM: new projects |

**The deciding factor:**
Use ESM for new code. Use CJS when maintaining legacy Node.js
codebases or when consumers require synchronous module loading.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CommonJS uses `require()` and `module.exports`; ES Modules use
> `import` and `export`. In Node.js, CJS is the default; to use
> ESM you add `"type": "module"` to package.json or use `.mjs`
> extension. In browsers, ESM is native with `<script type="module">`.
> The two systems cannot be directly mixed: CJS can import from ESM
> only asynchronously, ESM cannot synchronously require CJS.

*Push deeper:* Explain live bindings vs value copies. Describe when
you would use dynamic `import()` vs static `import`.

---

**Senior / Staff (5+ years):**

> The module system difference matters most for tree shaking and
> Node.js interop. Bundlers need ESM's static `import` graph to
> eliminate dead code. CJS dynamic `require()` is opaque at build
> time. For library publishing, I ship dual CJS+ESM using the
> `exports` map in package.json with `import` and `require` conditions.
> The live binding behavior of ESM named exports is important for
> singleton patterns - a CJS-required configuration object is a
> snapshot, but an ESM-imported config is a live reference.

*Push deeper:* Staff discuss the Node.js module resolution algorithm,
`__dirname` unavailability in ESM (use `import.meta.url` instead),
circular dependency behavior differences, and the role of Rollup's
ESM assumption in its bundle optimization.

---

### ⚠️ Common Misconceptions

**Misconception 1: You can mix `require()` and `import` in the same file.**

You cannot. A file is either CJS (uses `require`) or ESM (uses
`import`). Bundlers like webpack can handle both in a project (they
transpile everything), but a single file cannot use both syntaxes
in a native Node.js environment.

**Misconception 2: `import()` (dynamic) is the same as `import` (static).**

Static `import` is hoisted to the top of the module and processed
at parse time. Dynamic `import()` is a function that returns a
Promise - resolved at runtime. Dynamic import enables lazy loading
and conditional module loading. Both are valid ESM; they are not the
same mechanism.

**Misconception 3: Adding `"type": "module"` to package.json breaks all CJS files.**

Only `.js` files in that package are treated as ESM. Files with `.cjs`
extension remain CJS. Files with `.mjs` extension are always ESM.
The `"type": "module"` setting can coexist with CJS files using the
`.cjs` extension - this is the dual-package strategy.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: `ERR_REQUIRE_ESM` when requiring a library.**

Symptom: `Error [ERR_REQUIRE_ESM]: require() of ES Module not supported`.

Diagnosis: A dependency published ESM-only (no CJS fallback). Your
CJS code cannot `require()` it synchronously.

Fix: Either use dynamic `import()` in an async function, or switch
the consuming file to ESM, or find a CJS-compatible version of the
library, or use a bundler that handles the transpilation.

**Failure 2: Tree shaking not eliminating dead code.**

Symptom: Bundle size unexpectedly large; unused exports included.

Diagnosis: The imported module is CJS - bundler cannot statically
analyze the export graph. Or the module has side effects that prevent
removal.

Fix: Ensure you import from an ESM build. Add `"sideEffects": false`
to library package.json if true. Use named imports rather than
namespace imports (`import { fn } from 'lib'` not `import * as lib`).

**Failure 3: `__dirname` undefined in ESM.**

Symptom: `ReferenceError: __dirname is not defined in ES module scope`.

Diagnosis: `__dirname` and `__filename` are CJS-only globals injected
by Node.js's module wrapper. ESM modules do not have them.

Fix: Use `import.meta.url` and the `URL` API:
`const __dirname = new URL('.', import.meta.url).pathname;`

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is the difference between CJS and ESM? | Definition | ★★☆ | 2 min |
| How do ESM live bindings differ from CJS require? | Mechanism | ★★☆ | 3 min |
| When would you use dynamic `import()` vs static `import`? | Comparison | ★★☆ | 2 min |
| You need to publish a library that works in CJS and ESM - design it | Scenario | ★★★ | 5 min |
| `ERR_REQUIRE_ESM` error appears after upgrading a dependency. Fix it. | Debugging | ★★☆ | 3 min |
| Why does ESM enable tree shaking but CJS does not? | Deep Dive | ★★★ | 4 min |
| "You can use `import` and `require` in the same file." | Misconception | ★★☆ | 2 min |
| How does module loading affect startup performance in large Node.js apps? | Performance | ★★★ | 4 min |
| What is circular dependency behavior in ESM vs CJS? | Deep Dive | ★★★ | 4 min |

**Q: Why does ESM enable tree shaking but CJS does not?**

A: Tree shaking requires static analysis of the dependency graph at
build time. Bundlers must know which exports of each module are used
before executing any code, so they can mark unused exports for removal.

ESM `import` declarations are static: the module specifier must be
a string literal (mostly), and the imported names are declared at
parse time. A bundler can build the full import graph and identify
which exported names are actually used across the entire codebase
without running the code.

CJS `require()` is dynamic: it is a function call that can appear
anywhere, take any variable as path, and be called conditionally.
`require(condition ? 'a' : 'b')` and `require(dynamicPath)` are
valid. The bundler cannot know which modules will be loaded or which
exports will be used without executing the code - which defeats the
purpose of build-time analysis.

*What separates good from great:* Understanding that tree shaking is
not just about `import`/`export` syntax - it also requires that the
module has no side effects (or declares `"sideEffects": false`). A
module that modifies globals on import cannot be tree-shaken even
if it uses ESM syntax, because the side effect must be preserved.

**Q: How does module circular dependency behave differently in CJS vs ESM?**

A: In CJS, circular requires get the partially initialized export
object. If A requires B and B requires A, when B's require of A
runs during A's initialization, B gets whatever `module.exports`
A has set up so far - which may be an empty object or partially
populated. This is a common source of `undefined` function errors:
a function A exports is not yet defined when B's module body runs.

In ESM, circular imports work because `import` bindings are live.
When the import graph is resolved at parse time, circular bindings
are established as live references that point to the binding (which
may be in TDZ initially). By the time module bodies run (after the
full graph is resolved), all exports are typically defined. ESM
handles cycles more gracefully but can still produce TDZ errors if
a binding is read before its module's body executes.

*What separates good from great:* The practical insight - in both
systems, circular dependencies are a design smell indicating the
modules are too tightly coupled. The diagnostic is usually "why do
these two modules depend on each other?" and the fix is extracting
the shared dependency into a third module.

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



