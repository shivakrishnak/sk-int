---
layout: default
title: "Node.js - L1 Module System"
parent: "Node.js"
nav_order: 5
permalink: /nodejs/l1-module-system/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [CommonJS Modules](#commonjs-modules) | foundational |
| 2 | [ES Modules in Node.js](#es-modules-in-nodejs) | foundational |
| 3 | [Node.js Module Resolution Algorithm](#nodejs-module-resolution-algorithm) | foundational |

---

# CommonJS Modules

🎯 **Interview Weight:** foundational (★☆☆) - CJS is the legacy default;
understanding it explains require caching, circular deps, and ESM differences

---

### 🎯 Model Answer

**30 seconds:**

> CommonJS (CJS) is Node.js's original module system. `require()` loads
> modules synchronously. `module.exports` defines what a module exports.
> Key behavior: modules are cached after first load - `require('./config')`
> always returns the same object. This enables singletons but causes issues
> with circular dependencies. CJS is still the default for `.js` files
> when `"type"` is not set in package.json.

**3 minutes:**

> CJS wraps every module in a function: `(function(exports, require,
> module, __filename, __dirname) { ... })`. This is why `__dirname` and
> `require` are available without imports. Module cache lives in
> `require.cache` - you can delete entries to force re-loading (useful in
> tests). Circular dependencies work partially: if A requires B and B
> requires A, whichever is partially loaded at the circular point returns
> an empty or partially-filled `module.exports`. This is the #1 source of
> `undefined` import bugs in CJS. `exports` is a shortcut to `module.exports`
> but reassigning `exports = {}` breaks the link - always use `module.exports`
> for whole object replacement.

**Blank Mind Recovery:**

**(1) Restate:** "CJS: require() loads synchronously. module.exports = what
you export. Modules cached after first load (singletons). Circular deps work
partially (partially loaded object returned). exports shortcut - never
reassign exports directly, use module.exports."

---

### 📘 Concept Explanation

**What it is:**

CommonJS is the module system built into Node.js from the beginning. Still
the default module format and used by the vast majority of npm packages.

**How it works - module wrapping and caching:**

```javascript
// HOW CJS WRAPS YOUR CODE:
// Node.js wraps every .js file in:
(function(exports, require, module, __filename, __dirname) {
  // Your module code runs here
  // exports = module.exports (alias - don't reassign!)
  // require() loads other modules
  // module = { id, exports, loaded, parent, children }
  // __filename = /srv/app/mymodule.js
  // __dirname = /srv/app
});

// EXPORTING: single value
module.exports = function createServer() { ... };
// Callers: const createServer = require('./server');

// EXPORTING: named (object properties)
module.exports = {
  add: (a, b) => a + b,
  subtract: (a, b) => a - b,
};
// Callers: const { add } = require('./math');

// EXPORTS SHORTCUT: only for adding properties
exports.add = (a, b) => a + b;      // OK
// BROKEN: exports = { add, subtract }
//   reassigns local var, breaks module.exports link!

// MODULE CACHE:
const config1 = require('./config'); // loads & caches
const config2 = require('./config'); // returns cached object
console.log(config1 === config2);   // true - same reference

// Force reload (useful in tests):
delete require.cache[require.resolve('./config')];
const freshConfig = require('./config'); // reloads from disk

// CIRCULAR DEPENDENCY (the bug explained):
// a.js:
const b = require('./b');
exports.a = 'from a'; // too late - b already got empty exports
module.exports.value = 'a value';

// b.js:
const a = require('./a'); // a mid-execution -> gets {} (empty)
console.log(a.value);    // undefined!
module.exports.value = 'b value';
```

> **Code walkthrough:** The module wrapper function explains why CJS has
> `__dirname` and `require` as apparent globals - they're function parameters.
> The cache creates singletons: every `require('./config')` returns the same
> object. The circular dependency example shows WHY `a.value` is `undefined`:
> when `b.js` requires `a.js` mid-execution, it gets the in-progress
> (empty) `module.exports`. Evaluation is linear and cache is checked first.

**Why it matters:**

CJS is still the most common Node.js module format. Every npm package that
doesn't specify `"type": "module"` uses CJS. Understanding cache and circular
dependency behavior is essential for debugging.

**Trade-offs:**

CJS: synchronous require (simpler), works everywhere. But blocks the event
loop during loading (acceptable at startup), and dynamic `require` calls
prevent tree-shaking.

**Failure modes:**

- Reassigning `exports` exports `{}` (breaks module.exports link)
- Circular deps produce `undefined` for partially-loaded modules
- Mutating cached module state causes hard-to-reproduce bugs

**Scale behavior:**

Module cache persists for the process lifetime. Hundreds of modules cached
in memory from startup. Hot reloading (nodemon) clears the entire require
cache and re-executes the entry module.

**Decision framework:**

Use CJS when: writing for maximum npm compatibility, using older tooling.
Use ESM when: writing modern code, consuming ESM-only packages.

**Memory model:**

`require.cache` is a plain object keyed by absolute file path. Each entry
holds `{ id, filename, loaded, exports }`. `exports` is the live object -
mutations affect all consumers.

---

### 💻 Code Example

```javascript
// BAD: breaking the exports shortcut
// config.js
exports = { host: 'localhost', port: 3000 };
// Nothing is exported! exports was a local variable pointing to
// module.exports. Reassigning it breaks the reference.
// Users get: const config = require('./config'); -> {}

// GOOD: use module.exports for full object assignment
module.exports = { host: 'localhost', port: 3000 };

// OR use exports shortcut only for adding properties:
exports.host = 'localhost';
exports.port = 3000;

// BAD: mutating cached module state
// db.js
let connection = null;
module.exports = {
  connect: async () => { connection = await createPool(); },
  query: async (sql) => connection.query(sql),
};
// Two test files calling connect() share the same connection object.
// Second connect() replaces the shared reference.

// GOOD: factory pattern for independent instances
module.exports = function createDB(config) {
  let connection = null;
  return {
    connect: async () => { connection = await createPool(config); },
    query: async (sql) => connection.query(sql),
  };
};
```

> **Code walkthrough:** `exports = {}` is one of the most common Node.js
> mistakes - produces no error, the module just exports `{}`. `module.exports =`
> is always safe. The factory pattern for mutable state is a key design
> principle: when you need independent instances (separate DB connections per
> test), export a factory function, not a shared singleton.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> CommonJS uses `require()` to import modules and `module.exports` to export.
> Modules are cached after first load so `require('./config')` always returns
> the same object. Don't reassign `exports` directly - use `module.exports`
> for whole object replacement. Circular dependencies can cause `undefined`
> values.

**Senior / Staff:**

> CJS module caching is both a feature and a footgun. The singleton behavior
> is intentional for shared resources but causes test isolation issues - tests
> must clear `require.cache` or use DI to get fresh state. Circular deps in
> CJS are silently handled: the importing module gets an incomplete object.
> The fix is to defer the require (lazy load inside a function) or restructure
> to break the cycle. For modern Node.js: prefer ESM for new code, but know
> that many packages are CJS-only and dynamic `require()` of CJS from ESM
> requires `createRequire`.

---

### ⚠️ Common Misconceptions

**"exports and module.exports are the same":**

They start pointing to the same object, but reassigning `exports = {}`
breaks the link. `module.exports` is what actually gets returned. Always
use `module.exports` for whole object replacement.

**"Circular dependencies cause errors":**

CJS silently handles them by returning the partially-constructed object.
No error - you get `undefined` properties instead. Much harder to debug.

**"require() always does a disk read":**

Only the first time. After that, the module cache returns the object
instantly. Disk I/O happens once per module per process lifetime.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: `module.exports` appears as empty `{}`**

```javascript
// DIAGNOSE: check if reassigning exports incorrectly
// In module file: exports = { key: 'value' }  <- BUG
// Fix: module.exports = { key: 'value' }

// Also check circular dependencies:
// If A requires B and B requires A,
// one will get {} due to circular resolution
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Symptom: Stale module state in tests**

```javascript
// Tests share cached modules - must reset between tests
beforeEach(() => {
  // Jest:
  jest.resetModules();
  // Manual:
  Object.keys(require.cache).forEach(key => {
    if (key.includes('/src/')) delete require.cache[key];
  });
});
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| exports vs module.exports | 2-3 min | Reassignment breaks link |
| Module caching behavior | 2-3 min | Singleton, require.cache |
| Circular dependencies | 2-3 min | Partial export, undefined values |
| Force reload in tests | 2-3 min | delete require.cache[...] |
| CJS vs ESM interop | 2-3 min | createRequire for ESM->CJS |
| Module wrapper function | 2-3 min | Why __dirname exists |
| Lazy require pattern | 2-3 min | Break circular deps |

---

**Q1: You have a circular dependency where module A imports B and B
imports A. One module gets `undefined`. How do you fix it?** `[MID]`
DEBUGGING

> **Answer:**
>
> ```javascript
> // PROBLEM: circular dependency
> // a.js
> const { b } = require('./b');
> exports.a = () => `a calls ${b()}`;
>
> // b.js
> const { a } = require('./a');
> // a not fully loaded -> a = undefined
> exports.b = () => `b calls ${a()}`;
> // TypeError: a is not a function
>
> // FIX 1: Lazy require (defer inside function):
> // b.js
> exports.b = () => {
>   const { a } = require('./a'); // loads lazily, after a finishes
>   return `b calls ${a()}`;
> };
>
> // FIX 2: Restructure - extract shared logic:
> // shared.js
> exports.shared = () => 'shared logic';
> // a.js and b.js both require('./shared') - no circular dep
>
> // FIX 3: Assign exports BEFORE requiring dependencies:
> // a.js
> exports.a = () => {}; // assign first
> const { b } = require('./b'); // b gets the real a now
> exports.a = () => `a calls ${b()}`; // overwrite with real impl
> ```
>
> *What separates good from great:* Understanding WHY it fails: CJS starts
> executing a.js, hits `require('./b')`, suspends a.js, starts b.js, hits
> `require('./a')` - a.js is already in cache but only partially executed,
> so it returns the incomplete `module.exports`. Restructuring to break
> the cycle is the clean solution; lazy require is quick but a code smell.

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


# ES Modules in Node.js

🎯 **Interview Weight:** foundational (★☆☆) - ESM is the modern standard;
interop with CJS and static analysis benefits are key interview topics

---

### 🎯 Model Answer

**30 seconds:**

> ES Modules (ESM) use `import`/`export` syntax. Enable with `"type": "module"`
> in package.json or use `.mjs` extension. Key differences from CJS: imports
> are static (resolved at parse time), top-level `await` is supported,
> `__dirname` is not available, and `require` doesn't exist. ESM can import
> CJS, but CJS cannot `require()` ESM - must use dynamic `import()`.

**3 minutes:**

> ESM static imports enable tree-shaking: bundlers can analyze what's used
> and eliminate dead code. CJS `require` is dynamic, making tree-shaking
> impossible. In Node.js: `.mjs` = always ESM; `.cjs` = always CJS; `.js`
> follows the nearest `package.json` `"type"` field. Top-level `await` in
> ESM enables async initialization without an IIFE. CJS interop: `import
> cjsModule from './legacy.cjs'` works (gets `module.exports`). ESM from
> CJS: use `import()` dynamic expression which returns a Promise.

**Blank Mind Recovery:**

**(1) Restate:** "ESM: import/export. Enable via type:module or .mjs.
Static imports (tree-shakeable). No __dirname, no require. Top-level await
works. ESM can import CJS. CJS cannot require() ESM - use dynamic import()."

---

### 📘 Concept Explanation

**What it is:**

ES Modules is the official JavaScript module standard, added to Node.js
in v12 (stable in v14). It aligns Node.js with browser JavaScript.

**How it works:**

```javascript
// package.json to enable ESM for .js files:
// { "type": "module" }

// EXPORTING (ESM):
export const PI = 3.14159;
export function add(a, b) { return a + b; }
export default function createServer() { ... }

// Re-export from another module:
export { add, subtract } from './math.js';
export * from './utils.js';

// IMPORTING (ESM):
import { add, subtract } from './math.js';
// NOTE: .js extension REQUIRED in Node.js (unlike bundlers)

import createServer from './server.js';       // default
import * as math from './math.js';             // namespace
const { module } = await import('./config.js'); // dynamic

// Import CJS from ESM:
import express from 'express'; // gets module.exports as default
import { Router } from 'express'; // named exports via analysis

// TOP-LEVEL AWAIT (ESM only):
const config = await fetch('/api/config').then(r => r.json());
export { config }; // available to importers after await completes

// __dirname equivalent in ESM:
import { fileURLToPath } from 'url';
import path from 'path';
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// CJS from ESM using dynamic import():
const cjsModule = await import('./legacy.cjs');
// cjsModule.default = the entire module.exports object
```

> **Code walkthrough:** The `.js` extension requirement in Node.js ESM is
> a common gotcha - bundlers allow omitting it, native Node.js requires it.
> Static `import` statements are hoisted and resolved before code executes
> (can't be inside `if` blocks - use dynamic `import()` for conditional
> loading). Top-level `await` blocks the entire module from being available
> to importers until the await completes - powerful but can delay startup.

**Why it matters:**

ESM is the future of JavaScript modules. Tree-shaking only works with ESM.
Browser compatibility requires ESM. More npm packages are becoming ESM-only.

**Trade-offs:**

ESM: static analysis, tree-shaking, top-level await, browser compatible.
But: slower startup than CJS (async parsing), stricter path resolution,
`__dirname` not available.

**Failure modes:**

- Missing `.js` extension: `ERR_MODULE_NOT_FOUND`
- `require()` in ESM file: `ReferenceError: require is not defined`
- `ERR_REQUIRE_ESM`: CJS code trying to require() an ESM-only package
- Top-level await in CJS: syntax error (CJS is synchronous)

**Scale behavior:**

ESM static analysis enables smaller bundles via tree-shaking. Critical for
Lambda/Cloud Run where bundle size affects cold start time.

**Decision framework:**

New project: ESM (modern, tree-shakeable). Library authoring: consider
dual CJS+ESM via package.json `"exports"` field. Legacy codebase: CJS is
fine, migrate incrementally.

**Memory model:**

ESM exports are live bindings - if module A exports `let count = 0` and
updates it, importers see the updated value. CJS exports are snapshots of
`module.exports` at the time of `require()`.

---

### 💻 Code Example

```javascript
// BAD: mixing CJS require() into ESM file
// In type:module .js or .mjs file:
const express = require('express');
// ReferenceError: require is not defined in ES module scope

// GOOD: use import in ESM
import express from 'express';

// BAD: missing .js extension in Node.js ESM
import { add } from './math'; // ERR_MODULE_NOT_FOUND in Node.js
// (Works in webpack/esbuild, NOT in native Node.js)

// GOOD: full extension required
import { add } from './math.js';

// ESM live bindings vs CJS snapshot:
// math.mjs
export let counter = 0;
export function increment() { counter++; }

// user.mjs
import { counter, increment } from './math.mjs';
console.log(counter); // 0
increment();
console.log(counter); // 1 - live binding, sees update

// CJS equivalent (snapshot):
// const { counter, increment } = require('./math');
// increment();
// console.log(counter); // still 0 - copied value at require time
```

> **Code walkthrough:** The live binding behavior of ESM is a fundamental
> difference from CJS. ESM named exports are live references to the variable
> in the exporting module. When `counter` is updated, all importers see
> the new value. CJS destructuring copies the value at require time. This
> matters for mutable module state (counters, singletons). For mutable
> values from CJS, keep a reference to the module object: `const math = require('./math')`,
> then `math.counter` reflects updates.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> ES Modules use `import`/`export` syntax. Enable with `"type": "module"`
> in package.json. Key differences from CJS: you need `.js` extensions,
> `__dirname` doesn't exist, and `require` is not available. ESM can import
> CJS modules but CJS can't `require()` ESM files.

**Senior / Staff:**

> ESM's static imports enable tree-shaking - bundlers can eliminate unused
> code because imports are resolved at parse time, not runtime. The CJS
> interop constraint is fundamental: CJS `require` is synchronous, but ESM
> supports top-level `await`, making it impossible to synchronously load an
> ESM module. For library authors, package.json `"exports"` enables dual
> publishing: `{ "import": "./esm/index.js", "require": "./cjs/index.js" }`.
> Top-level `await` is powerful for async initialization but blocks the
> entire module graph - use it carefully in startup-sensitive contexts.

---

### ⚠️ Common Misconceptions

**"ESM and CJS are completely interoperable":**

ESM can import CJS. CJS cannot `require()` ESM (must use async `import()`).
The restriction is fundamental: CJS is synchronous but ESM supports async
top-level await.

**"import and require work the same way":**

`import` is static and hoisted; `require` is dynamic and positional.
ESM named imports are live bindings; CJS destructured values are snapshots.
`import` cannot be inside conditionals (use dynamic `import()` for that).

**"Named imports from CJS always work":**

Node.js uses static analysis to infer CJS named exports, but it's imperfect.
Complex dynamic CJS patterns may not yield named exports. Use default import
and destructure manually as a fallback.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: `ERR_REQUIRE_ESM`**

```bash
# CJS code trying to require() an ESM-only package
# Fix: use dynamic import()
const pkg = await import('esm-only-package');
# Or: convert your file to ESM
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Symptom: `ERR_MODULE_NOT_FOUND` despite file existing**

```javascript
// Missing .js extension in ESM import
import { fn } from './utils'; // BROKEN in Node.js ESM
import { fn } from './utils.js'; // FIXED

// Also check: is file actually .cjs? Use explicit extension
import cjsMod from './module.cjs';
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Symptom: `SyntaxError: Cannot use import statement outside a module`**

```json
// Add to package.json:
{ "type": "module" }
// Or rename file to .mjs
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| ESM vs CJS differences | 2-3 min | Static vs dynamic, live bindings |
| Enable ESM in Node.js | 2-3 min | type:module or .mjs |
| CJS from ESM (and vice versa) | 2-3 min | ESM->CJS OK, CJS->ESM async only |
| Tree-shaking requirement | 2-3 min | Static imports only |
| Top-level await use case | 2-3 min | Async initialization |
| .js extension requirement | 2-3 min | Node.js vs bundler behavior |
| Live bindings vs value copy | 2-3 min | Mutable exports gotcha |

---

**Q1: An npm package is ESM-only and your code uses CJS `require`.
How do you handle it?** `[MID]` SYSTEM DESIGN

> **Answer:**
>
> ```javascript
> // ERROR: require() of ES Module not supported
> const pkg = require('pure-esm-package'); // ERR_REQUIRE_ESM
>
> // OPTION 1: Dynamic import() in CJS (returns Promise):
> async function getPackage() {
>   const { default: pkg } = await import('pure-esm-package');
>   return pkg;
> }
>
> // OPTION 2: Convert your file to ESM:
> // Rename to .mjs or add "type": "module" to package.json
> import pkg from 'pure-esm-package';
>
> // OPTION 3: ESM wrapper + dynamic import
> // esm-bridge.mjs
> export { default } from 'pure-esm-package';
>
> // Then in CJS:
> const { default: pkg } = await import('./esm-bridge.mjs');
> ```
>
> *What separates good from great:* Understanding WHY the restriction exists:
> CJS `require` is synchronous but ESM modules can use top-level `await`.
> Node.js can't synchronously load something that might be async. The
> dynamic `import()` works because it returns a Promise - it's async and
> can wait for the module's async initialization. Option 2 (convert to ESM)
> is often the cleanest long-term solution.

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


# Node.js Module Resolution Algorithm

🎯 **Interview Weight:** foundational (★☆☆) - resolution order explains
node_modules lookup, version conflicts, and why packages resolve wrong

---

### 🎯 Model Answer

**30 seconds:**

> When you `require('express')` or `import 'express'`, Node.js follows a
> defined algorithm: (1) check if it's a built-in module, (2) if relative
> path, resolve from current file, (3) for bare specifiers, walk up the
> directory tree checking `node_modules` at each level. First match wins.
> This walk-up algorithm enables version isolation: nested packages can have
> their own version of a dependency.

**3 minutes:**

> Relative requires (`./`, `../`) resolve from the current file. Bare
> specifiers (`express`, `fs`): (1) built-in Node modules always win,
> (2) `node_modules` in current directory, (3) `node_modules` in parent,
> continuing to filesystem root. `package.json` `"main"` field specifies
> the CJS entry point; the modern `"exports"` field specifies both CJS and
> ESM entry points with conditional support. `require.resolve` shows which
> file would load without actually loading it - essential for debugging.
> `"exports"` also controls encapsulation: with it, only declared paths
> are accessible.

**Blank Mind Recovery:**

**(1) Restate:** "Resolution: built-ins first, then node_modules walk up
from current file to root. Relative paths from current file. package.json
main = CJS entry. exports = modern conditional (import/require). Version
isolation from nested node_modules. require.resolve to debug."

---

### 📘 Concept Explanation

**What it is:**

Module resolution is the algorithm Node.js uses to find the actual file
for a `require` or `import` specifier.

**How it works - the full algorithm:**

```javascript
// BUILT-IN MODULES: always resolved first, no file lookup
require('fs');       // built-in
require('path');     // built-in
require('node:fs');  // explicit built-in prefix (recommended in ESM)

// RELATIVE PATH RESOLUTION (./  or  ../)
// require('./utils') from /srv/app/server.js tries:
// 1. /srv/app/utils.js     (exact + .js)
// 2. /srv/app/utils.json   (+ .json)
// 3. /srv/app/utils.node   (+ native addon)
// 4. /srv/app/utils/index.js   (as directory)
// 5. /srv/app/utils/package.json "main" field

// BARE SPECIFIER - walk up node_modules:
// require('express') from /srv/app/server.js checks:
// 1. /srv/app/node_modules/express
// 2. /srv/node_modules/express
// 3. /node_modules/express
// First match wins.

// NESTED node_modules (version isolation):
// /srv/app/node_modules/pkg-a/node_modules/lodash@4.x
// /srv/app/node_modules/pkg-b/node_modules/lodash@3.x
// Each gets its own version - resolved from the requiring file

// package.json ENTRY POINTS:
// Legacy: "main" field (CJS entry point)
// { "main": "./dist/index.js" }

// Modern: "exports" field (conditional exports)
// {
//   "exports": {
//     ".": {
//       "import": "./dist/esm/index.js",
//       "require": "./dist/cjs/index.js",
//       "default": "./dist/cjs/index.js"
//     },
//     "./utils": "./dist/utils.js"
//   }
// }

// "exports" LOCKS DOWN accessible paths:
// Without exports: require('pkg/lib/internal') works
// With exports (above): ERR_PACKAGE_PATH_NOT_EXPORTED

// DIAGNOSTIC TOOLS:
console.log(require.resolve('express'));
// /srv/app/node_modules/express/index.js

console.log(module.paths);
// [ '/srv/app/node_modules',
//   '/srv/node_modules',
//   '/node_modules' ]
```

> **Code walkthrough:** The `node_modules` walk-up algorithm is the core
> of npm's dependency management. `pkg-a` requiring `lodash` finds its own
> `lodash` in `pkg-a/node_modules/lodash`. This isolation lets packages
> depend on different versions without conflict. `require.resolve` is the
> essential debugging tool: it shows exactly which file loads without
> executing it. The `"exports"` field is increasingly important - it
> breaks code that directly accessed package internals.

**Why it matters:**

Version conflicts, `cannot find module` errors, and unexpected behavior
from wrong-version modules all stem from misunderstanding resolution.
The `"exports"` field is increasingly important for package authors.

**Trade-offs:**

`node_modules` isolation allows version flexibility but can lead to
multiple copies of the same package in memory. `npm dedupe` or pnpm's
linking reduces duplication.

**Failure modes:**

- `Cannot find module`: file doesn't exist at any search path
- Wrong version loaded: another `node_modules` in the tree wins
- `ERR_PACKAGE_PATH_NOT_EXPORTED`: `"exports"` blocks internal access
- Symlinked modules resolve from symlink source (pnpm, workspaces)

**Scale behavior:**

Deep `node_modules` trees slow resolution slightly. Bundlers resolve
at build time, eliminating runtime lookup overhead.

**Decision framework:**

Use `require.resolve` to debug which file loads. Use `module.paths`
to see search order. Add `"exports"` to published packages for
encapsulation and dual CJS/ESM support.

**Memory model:**

Node.js caches resolved paths after first lookup. `require.resolve`
is fast after first call. File system stats are cached per process.

---

### 💻 Code Example

```javascript
// DEBUGGING module resolution:

// 1. Find where a module actually loads from:
console.log(require.resolve('lodash'));
// /srv/app/node_modules/lodash/lodash.js

// 2. Check if two requires load the SAME version:
const l1 = require('lodash');
const l2 = require('lodash');
console.log(l1 === l2); // true - same cached module

// 3. Inspect search path:
console.log(module.paths);

// COMMON UPGRADE BUG: "exports" blocking subpath access
// Before: package allowed require('some-pkg/lib/internal')
// After adding "exports" field:
// Error: Package subpath './lib/internal' is not defined by "exports"
//
// Fix: use the package's public API
// Or: check if the package exports the utility differently now

// MONOREPO RESOLUTION:
// /monorepo/packages/service-a/index.js
// require('express') -> /monorepo/node_modules/express (hoisted)
// Only falls back to
// /monorepo/packages/service-a/node_modules/express
// if a different version was explicitly needed
```

> **Code walkthrough:** `require.resolve` is essential for debugging
> module resolution issues without executing the module. The `module.paths`
> array reveals the complete search order - helpful when a package seems
> to load the wrong version. The monorepo hoisting behavior is important:
> workspace managers hoist compatible versions to the root, so most
> packages find their dependencies at the monorepo root rather than
> in their local `node_modules`.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> When you `require('package')`, Node.js checks built-in modules first,
> then walks up from the current file through parent directories looking
> in `node_modules` folders. `require.resolve('pkg')` shows which file
> would load without loading it - useful for debugging.

**Senior / Staff:**

> The walk-up resolution enables version isolation: deep dependencies can
> have their own versions of shared packages. The modern `"exports"` field
> supersedes `"main"` and enables: conditional exports (CJS vs ESM),
> subpath exports, and package encapsulation (blocking internal paths).
> This is why upgrading a package can break code that directly `require`d
> its internals - the package added an `"exports"` field. In monorepos,
> package managers hoist shared dependencies to the root, so all packages
> resolve the same version unless explicitly pinned differently.

---

### ⚠️ Common Misconceptions

**"require('pkg') always loads from the nearest node_modules":**

It loads from the FIRST `node_modules` walking UP from the requiring file.
Packages higher in the tree (hoisted by workspaces) can be found first.

**"package.json 'exports' field is optional":**

Without it, all files are accessible. With it, you control your public API
and enable conditional CJS/ESM. Modern packages should use it for
encapsulation.

**"Cannot find module means the package isn't installed":**

Also happens with: wrong path extension in ESM, wrong working directory,
symlink resolution issues, or `"exports"` blocking the path.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: `ERR_PACKAGE_PATH_NOT_EXPORTED`**

```bash
# Package added "exports" field that blocks internal path
# Error: Package subpath './lib/internal' is not defined by "exports"
# Fix: use the package's public API, or check the new API
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Symptom: Wrong version of package loaded**

```javascript
// DIAGNOSE:
console.log(require.resolve('some-package'));
// If path shows unexpected node_modules location, that's the issue
// FIX: npm dedupe or add "overrides" to package.json
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Symptom: `Cannot find module './config'` but file exists**

```javascript
// ESM: missing .js extension
import config from './config.js'; // not './config'

// CJS: check working directory
console.log(process.cwd()); // where the process started
console.log(__dirname);     // where this file is
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| node_modules walk-up order | 2-3 min | Built-ins first, then up tree |
| Version isolation mechanism | 2-3 min | Per-directory node_modules |
| package.json exports field | 2-3 min | Conditional, subpaths, encapsulation |
| require.resolve for debugging | 2-3 min | Find actual loaded file |
| Monorepo hoisting | 2-3 min | Root node_modules wins |
| Exports blocking internals | 2-3 min | ERR_PACKAGE_PATH_NOT_EXPORTED |
| module.paths inspection | 2-3 min | See full search path |

---

**Q1: Your app uses two versions of the same npm package and gets strange
behavior. How do you diagnose and fix it?** `[MID]` DEBUGGING

> **Answer:**
>
> ```bash
> # DIAGNOSE: find all instances of the package
> find node_modules -name "package.json" -path "*/lodash/*" \
>   | xargs grep '"version"'
>
> # Or in Node.js:
> # node -e "console.log(require.resolve('lodash'))"
> ```
>
> ```javascript
> // Check which version your code loads:
> console.log(require.resolve('lodash'));
>
> // FIXES:
>
> // Fix 1: npm dedupe (hoists compatible versions)
> // npm dedupe
>
> // Fix 2: Force a single version
> // package.json (npm 8+):
> // "overrides": { "lodash": "^4.17.0" }
> // package.json (yarn/pnpm):
> // "resolutions": { "lodash": "^4.17.0" }
>
> // Fix 3: For peer dep conflicts, check if the package
> // accepts a range that includes both versions
> ```
>
> *What separates good from great:* Understanding WHEN two versions cause
> actual problems vs when they're harmless. Two identical functional packages
> just waste memory. Real problems occur when: (1) `instanceof` checks fail
> across versions (an object from v4 is not `instanceof` v3's class),
> (2) shared mutable state diverges between versions, (3) serialization/
> deserialization differs between versions. `npm dedupe` resolves it when
> versions are semver-compatible. `overrides` forces a version when they
> aren't - but test thoroughly as you may break a package that needed
> a specific version for a reason.

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



