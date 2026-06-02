---
layout: default
title: "Frontend Build Tools - L6 Theory"
parent: "Frontend Build Tools"
nav_order: 13
permalink: /frontend-build-tools/l6-theory/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Bundler Internals (AST, Module Graph, Tree Walking)](#bundler-internals-ast-module-graph-tree-walking) | medium |
| 2 | [ESM Specification and Browser-Native Modules](#esm-specification-and-browser-native-modules) | medium |

---

# Bundler Internals (AST, Module Graph, Tree Walking)

---

### 🎯 Model Answer

**30 seconds:**

> A bundler works in three phases: parse (source -> AST), analyze
> (build module graph by traversing imports), bundle (walk graph,
> concatenate modules, write output). Tree shaking happens during
> analysis: exports unused by any import path are marked dead and
> excluded from output. This requires ESM (static imports) because
> CommonJS imports are dynamic - the tree cannot be statically analyzed.

**Blank Mind Recovery:**

**(1) Restate:** "Bundler: parse source -> build module graph -> write
output. Tree shaking: mark unused exports dead during graph analysis.
Requires ESM for static analysis."

---

### 📘 Concept Explanation

**What it is:**

A bundler transforms multiple JavaScript module files into one or more
optimized output files. The core algorithm: parse source to AST, analyze
imports to build a dependency graph, walk the graph to determine which
code is reachable, and emit optimized output.

**The problem it solves:**

Browsers historically couldn't efficiently load hundreds of separate
JS files (HTTP/1.1 connection limits). Bundlers solve the module system
problem (CommonJS, AMD, ESM) and produce browser-optimized output.

**How it works:**

```
Phase 1: PARSE (entry point inward)

  Start: src/index.js
  Read file content -> Tokenize -> Parse to AST

  AST (Abstract Syntax Tree):
    Source: import { add } from './math';
    AST node:
      ImportDeclaration {
        specifiers: [ImportSpecifier { local: 'add', imported: 'add' }]
        source: Literal { value: './math' }
      }

  Parser: Acorn (webpack), esprima, or custom (esbuild Go parser)
  Cost: O(n) per file where n = file size

Phase 2: ANALYZE (build module graph)

  Module graph:
    Node = module (file)
    Edge = import statement

  Algorithm (BFS or DFS from entry):
    queue = [entry]
    while queue not empty:
      module = queue.dequeue()
      for each import in module.AST:
        dependency = resolve(import.path, module.dir)
        graph.addEdge(module, dependency)
        if dependency not visited:
          queue.enqueue(dependency)

  Resolution:
    './math' -> /src/math.js         (relative)
    'lodash' -> /node_modules/lodash/ (bare specifier)
    Follow: package.json "exports" field -> entry point

Phase 3: TREE SHAKING (ESM only)

  Mark all exports in graph as "unused"
  Walk import statements:
    for each `import { add } from './math'`:
      mark math.js#add as "used"
  Transitive: if add() calls multiply(), mark multiply as "used"

  Only works with ESM (static analysis):
    ESM: import { add } from './math'    <- statically analyzable
    CJS: const { add } = require('./math') <- dynamic, can't analyze
    CJS with variable: require(name) <- definitely can't analyze

  Rollup coined "tree shaking" from this dead code elimination

Phase 4: SCOPE HOISTING (optimization)

  Without: each module wrapped in a function closure
  With: modules concatenated into a single scope
  Benefit: smaller output, faster execution (fewer closures)
  Requirement: no circular dependencies, ESM

Phase 5: EMIT

  Minify AST (rename vars, remove whitespace)
  Generate code from AST (AST -> string)
  Write to output file with source map
```

> **Code walkthrough:** This Bundler Internals (AST, Module Graph, Tree Walking) example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

The shift from CommonJS to ESM (ES Modules) was required for tree
shaking to work. CommonJS `require()` can be called with a variable,
inside an if statement, or after async operations - there is no way
to statically determine what will be imported before running the code.
ESM `import` statements must be at the top level and the path must be
a string literal - making static analysis possible.

---

### 💻 Code Example

**Example 1: Observable tree shaking behavior**

```javascript
// src/math.js
export function add(a, b) { return a + b; }      // used
export function subtract(a, b) { return a - b; } // not imported
export function multiply(a, b) { return a * b; } // not imported

// src/index.js
import { add } from './math';
console.log(add(1, 2));

// Bundle output (webpack production, scope hoisted):
// function add(a, b) { return a + b; }
// console.log(add(1, 2));
// subtract and multiply: REMOVED (tree shaken)

// Verify tree shaking worked:
npm run build
grep -l 'subtract\|multiply' dist/assets/*.js
# If grep returns nothing: tree shaking worked
```

> **Code walkthrough:** This If grep returns nothing: tree shaking worked example demonstrates JavaScript pattern. **KEY MECHANISM:** V8 JIT-compiles hot functions to machine code; polymorphic call sites deoptimize the function. **WHY IT MATTERS:** closure captures the reference not the value - loop variables captured in closures retain last value. **TAKEAWAY: use block-scoped let/const in loops and closures to prevent stale reference bugs.**

```javascript
// Why CJS defeats tree shaking:
// lodash (CJS) - BAD for tree shaking:
import _ from 'lodash';
const sorted = _.sortBy(arr, 'name');
// webpack cannot determine what of lodash is needed
// ENTIRE lodash included: 68KB

// lodash-es (ESM) - GOOD for tree shaking:
import { sortBy } from 'lodash-es';
const sorted = sortBy(arr, 'name');
// Only sortBy and its dependencies included: ~3KB

// Verify the difference:
// ANALYZE=true npm run build
// lodash bundle: shows 68KB "lodash.js" module
// lodash-es bundle: shows ~3KB "sortBy.js" + small deps
```

> **Code walkthrough:** The observable test of tree shaking is a grepice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> for the removed function name in the output bundle. If `subtract`
> and `multiply` appear in dist/, tree shaking failed. Common failure
> reasons: the module has `sideEffects: true` (or missing) in its
> package.json; the imports are inside a function or conditional; or
> the bundler config has `optimization.usedExports: false`.

**Example 2: Source map internals**

```javascript
// Source map links minified output to original source
// Output: dist/main.js
// a(1,2);
//
// Source map: dist/main.js.map
// {
//   "version": 3,
//   "file": "main.js",
//   "sources": ["src/math.js", "src/index.js"],
//   "mappings": "AAAA,SAAS,GAAG,CAAC,CAAC,CAAC,..."
//   // VLQ (Variable Length Quantity) encoded column/line refs
// }

// Webpack generates source maps via source-map library
// Cost: source maps are ~3-5x the size of the bundle
// Always: hide source maps from public CDN in production
// (use hidden-source-map and serve only to Sentry)
```

> **Code walkthrough:** VLQ encoding is the compression scheme thatice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> makes source map files manageable. Instead of storing absolute line/
> column pairs, each position is stored as a delta from the previous
> position - small numbers that VLQ encodes compactly. Generating
> source maps adds ~10-20% to build time; this is acceptable in production
> but using `eval-source-map` in development eliminates this overhead
> by embedding the source directly.

---

### ⚖️ Comparison Table

| Module format | Static analysis | Tree shaking | Scope hoisting |
|---|---|---|---|
| ESM (`import`/`export`) | Yes | Yes | Yes (Rollup/webpack) |
| CJS (`require`/`exports`) | No | No | No |
| AMD (define/require) | Partial | No | No |
| UMD | No | No | No |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> A bundler parses JavaScript into ASTs, traces imports to build a
> dependency graph, and writes the combined output. Tree shaking uses
> the graph to remove unused exports. It requires ESM because CommonJS
> imports can't be statically analyzed.

**Senior / Staff:**

> The bundler's core algorithm is graph construction + dead code
> elimination. Tree shaking marks all exports as unused, then walks
> import statements to find what's actually referenced. ESM is required
> because CJS `require()` is a runtime function call - the bundler cannot
> determine the imported module at build time. This is why the ecosystem
> shift to ESM packages was necessary for effective tree shaking. The
> practical implication: always check if your dependencies ship ESM
> builds (`"module"` field in package.json or `"exports"` with ESM entry).

---

### ⚠️ Common Misconceptions

**Misconception 1: Adding `sideEffects: false` always enables tree shaking.**

`sideEffects: false` tells the bundler that no module in the package
has side effects on import (so unused modules can be safely eliminated).
But tree shaking also requires ESM exports. `sideEffects: false` with
CJS entry points does not enable tree shaking.

**Misconception 2: Tree shaking works on every import.**

Dynamic imports (`import(variable)`) cannot be tree-shaken. Imports
inside functions or conditionals may not be tree-shaken depending on
the bundler. Re-exports (`export * from './all'`) can defeat tree shaking
if the bundler doesn't track through the re-export chain.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Library included fully despite only importing one function.**

Cause: Library uses CJS exports; or library has `sideEffects: true`.

Diagnose: Bundle analyzer; check library's package.json for `module`
or `exports.import` field (ESM entry point).

Fix: Switch to lodash-es / ESM alternative; or add
`sideEffects: ['*.css']` to your own package.json.

**Failure: Tree-shaken code included in bundle despite not being imported.**

Cause: Module has a side effect on import (e.g., modifies prototype
or registers global). Bundle must include it.

Fix: This is correct behavior. Document the side effect; or refactor
to remove side effects on import.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How does a bundler work? (phases) | Mechanism | ★★☆ | 4 min |
| What is an AST and how is it used? | Definition | ★★☆ | 2 min |
| How does tree shaking work? | Mechanism | ★★☆ | 3 min |
| Why does tree shaking require ESM? | Mechanism | ★★★ | 3 min |
| What is scope hoisting? | Mechanism | ★★☆ | 2 min |
| Why is lodash-es better for bundles than lodash? | Comparison | ★★☆ | 2 min |
| What is `sideEffects: false` in package.json? | Definition | ★★☆ | 2 min |
| Source map internals - VLQ encoding | Mechanism | ★★★ | 3 min |
| Diagnose: tree shaking not working | Debugging | ★★★ | 4 min |

**Q: Explain tree shaking - from first principles to diagnosis.**

A: Tree shaking is dead code elimination based on static analysis
of module imports and exports.

The algorithm:

1. Build module graph: during bundle analysis, webpack/Rollup maps
   every `import` statement to its source module. This creates a directed
   graph: module A imports from module B, B imports from C, etc.

2. Mark all exports unused: every `export` in every module is initially
   marked as "not used."

3. Walk import statements: for every `import { add } from './math'`,
   mark `math.js#add` as "used." Recursively: if `add()` calls
   `multiply()`, mark `multiply` as used transitively.

4. Eliminate dead exports: any export still marked "unused" after the
   walk is excluded from the bundle.

Why ESM is required: ESM `import` statements are statically analyzable
at parse time - the imported module path is always a string literal,
and the import always appears at the module's top level. CommonJS
`require()` is a function call that can contain variables, can be
inside conditionals, and can be called at any point during execution.
The bundler cannot know what will be required without running the code.

Diagnosing tree shaking failure:

Step 1: Verify the library ships ESM. Check `package.json`:
- `"module": "dist/index.esm.js"` - old convention
- `"exports": { ".": { "import": "dist/index.esm.js" } }` - modern

Step 2: Check `sideEffects` in library's package.json:
- Missing or `sideEffects: true` - modules can't be tree-shaken
- `sideEffects: false` - safe to eliminate unused modules
- `sideEffects: ["*.css"]` - CSS files have side effects, others don't

Step 3: Check your import style:
- `import { sortBy } from 'lodash-es'` - tree-shakeable
- `import _ from 'lodash-es'; _.sortBy(...)` - may not tree-shake

Step 4: Verify with bundle analyzer - did the unused export disappear?

*What separates good from great:* Understanding that tree shaking is
a best-effort optimization, not a guarantee. The bundler must be
conservative: if it cannot prove code is unused, it keeps it. This
means complex re-export patterns, dynamic property access, and circular
imports can defeat tree shaking even with ESM. For critical libraries,
always verify with the bundle analyzer after optimizing.

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


# ESM Specification and Browser-Native Modules

---

### 🎯 Model Answer

**30 seconds:**

> ESM (ES Modules) is the native JavaScript module system: `import`/
> `export` syntax, static resolution, live bindings, and browser-native
> `<script type="module">`. Browsers have supported ESM since 2018.
> The build tool landscape is shifting: Vite uses ESM in development
> (no bundling needed - browser imports directly). For production,
> bundling is still needed for HTTP/2 multiplexing trade-offs and
> older browser support.

**Blank Mind Recovery:**

**(1) Restate:** "ESM: native JS modules. `import`/`export`. Static.
Live bindings. Browser-native since 2018. Vite uses ESM in dev (no
bundling). Production still benefits from bundling."

---

### 📘 Concept Explanation

**What it is:**

ESM (ECMAScript Modules, ES6 modules) is the standard module system
defined in the ECMAScript specification. It defines `import`/`export`
syntax, module resolution rules, and the semantics of module
evaluation (live bindings, deferred evaluation).

**The problem it solves:**

Before ESM, JavaScript had no standardized module system. CommonJS
(Node.js, 2009) and AMD (browser async loading, 2011) were community
standards. ESM is the language specification itself.

**How it works:**

```
ESM specification properties:

1. STATIC: imports/exports are at the top level, paths are strings
   ESM: import { a } from './module'  <- static, compile-time
   CJS: const a = require('./module') <- runtime function call

2. LIVE BINDINGS (not values):
   // module.js:
   export let count = 0;
   export function increment() { count++; }

   // consumer.js:
   import { count, increment } from './module.js';
   console.log(count);  // 0
   increment();
   console.log(count);  // 1  <- live binding, updated!
   // CJS would give 0 twice (copied value, not reference)

3. DEFERRED EVALUATION:
   Modules are evaluated once, lazily (on first import)
   Subsequent imports: same instance (no re-evaluation)
   Circular imports: work but may see undefined for not-yet-
   evaluated bindings

4. ASYNC MODULE LOADING (browser native):
   <script type="module" src="./app.js"></script>
   Browser fetches app.js, parses imports, fetches dependencies
   Network waterfall: one fetch per import depth level
   This is why production bundling still matters (HTTP round trips)

5. TOP-LEVEL AWAIT (ES2022):
   // module.js:
   export const data = await fetch('/api/config').then(r => r.json());
   // The module doesn't export until the fetch completes
   // Importers of this module wait for the fetch

6. IMPORT MAPS (browser native, all modern browsers):
   <script type="importmap">
   { "imports": { "react": "/vendor/react.js" } }
   </script>
   <script type="module">
   import React from 'react';  // resolved via import map
   </script>

CJS vs ESM key differences:
  Property          CJS              ESM
  Syntax            require()        import/export
  Binding           Copy value       Live binding
  Evaluation        Synchronous      Async (browser)
  Analysis          Runtime          Static
  Circular deps     Works mostly     Works (live bindings)
  Top-level await   No               Yes (ES2022)
  Default in Node   Yes              With "type":"module"
```

> **Code walkthrough:** This ESM Specification and Browser-Native Modules example demonstrates a key concept in practice using async/await. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

Vite's dev server works without bundling because browsers natively
support ESM imports. Instead of bundling `src/` into one file, Vite
serves each file as a separate ESM module. The browser's module loader
handles dependency resolution. This is why Vite starts instantly
regardless of project size: no bundle step.

The production trade-off: 500 unbundled ESM files means 500 separate
HTTP requests (even over HTTP/2). HTTP/2 multiplexing handles this
but the request overhead adds up. A bundled build with 2-3 chunks
is still faster for production.

---

### 💻 Code Example

**Example 1: Live bindings - CJS vs ESM behavior**

```javascript
// ESM live bindings:
// counter.mjs:
export let count = 0;
export function increment() { count++; }

// main.mjs:
import { count, increment } from './counter.mjs';
console.log(count);   // 0
increment();
increment();
console.log(count);   // 2  <- reflects current value (live binding)

// CJS equivalent (different semantics):
// counter.js:
let count = 0;
module.exports = {
  count,                    // copies VALUE at require time
  increment() { count++; }, // modifies the local count
};

// main.js:
const { count, increment } = require('./counter.js');
console.log(count);   // 0
increment();
increment();
console.log(count);   // 0  <- still 0! (got a copy, not the live binding)
// To get updated value with CJS:
const counter = require('./counter');
console.log(counter.count); // 2 (the property on the object is live)
```

> **Code walkthrough:** Live bindings are one of the most subtle butice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> important differences between ESM and CJS. With ESM, the `count`
> name in the importing module is a live view into the exporting module's
> `count` variable - it always reflects the current value. With CJS,
> destructuring `{ count }` takes a snapshot of the value at require
> time. This affects state management patterns: if a module exports
> mutable state, ESM consumers see updates automatically; CJS consumers
> see the initial value.

**Example 2: Native browser ESM with import maps**

```html
<!-- index.html: modern browser app without a bundler -->
<!DOCTYPE html>
<html>
<head>
  <!-- Import map: resolve bare specifiers in the browser -->
  <script type="importmap">
  {
    "imports": {
      "react": "https://esm.sh/react@18.2.0",
      "react-dom/client": "https://esm.sh/react-dom@18.2.0/client",
      "zustand": "https://esm.sh/zustand@4"
    }
  }
  </script>
</head>
<body>
  <div id="root"></div>
  <!-- type="module" enables native ESM loading: -->
  <script type="module" src="/src/main.jsx"></script>
</body>
</html>
```

> **Code walkthrough:** This ESM Specification and Browser-Native Modules example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

```javascript
// src/main.jsx (served as-is, no bundling)
import React from 'react';
import { createRoot } from 'react-dom/client';
import { create } from 'zustand';

const useStore = create((set) => ({
  count: 0,
  increment: () => set((s) => ({ count: s.count + 1 })),
}));

function App() {
  const { count, increment } = useStore();
  return (
    <button onClick={increment}>Count: {count}</button>
  );
}

createRoot(document.getElementById('root')).render(<App />);

// The browser fetches each import as a separate HTTP request
// No compilation step needed
// Works in Chrome/Firefox/Safari/Edge without any build tools
// Limitation: JSX is not native - needs either:
//   a) A transform step (Vite, esbuild transform, SWC)
//   b) No JSX (use React.createElement directly)
//   c) htm library (JSX-like tagged template literals)
```

> **Code walkthrough:** Import maps are the final piece that makesice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> browser-native ESM practical. Without them, bare specifiers like
> `import React from 'react'` fail in browsers (browsers don't know
> how to resolve a name without a path). Import maps map these names
> to URLs (CDN or local). This architecture - import map + native ESM -
> is how Vite's dev mode works: it transforms only what the browser
> can't handle (JSX, TypeScript) and lets the browser handle module
> loading. The key insight: "no bundler" doesn't mean "no build tool" -
> JSX transformation and TypeScript stripping are still needed.

---

### ⚖️ Comparison Table

| Module system | Static analysis | Live bindings | Async | Browser native |
|---|---|---|---|---|
| ESM | Yes | Yes | Yes | Yes (2018+) |
| CommonJS | No | No (copies) | No | No |
| AMD | Partial | No | Yes (callback) | Requires loader |
| UMD | No | No | Partial | Yes (IIFE) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> ESM is the native JavaScript module system with `import`/`export`.
> Unlike CommonJS, ESM imports are static (analyzed at build time) and
> give live bindings (not value copies). Browsers support ESM natively
> with `<script type="module">`. Vite uses this in dev mode to skip
> bundling entirely.

**Senior / Staff:**

> ESM's three defining properties matter for build tools: static
> imports enable tree shaking (analyze without running), live bindings
> enable correct circular dependency handling, and browser-native
> loading enables Vite's unbundled dev mode. The production trade-off
> is real: unbundled ESM in production means one HTTP request per module
> (500+ requests), which HTTP/2 handles but adds overhead versus 2-3
> bundled chunks. Import maps solve the bare specifier problem for
> browser-native ESM, enabling CDN-served dependencies without bundling.

---

### ⚠️ Common Misconceptions

**Misconception 1: Vite doesn't need a bundler at all.**

Vite uses esbuild as a bundler for production builds. The "no bundler"
aspect is only in development mode. Production always bundles.

**Misconception 2: `type: "module"` in package.json only affects Node.js.**

`"type": "module"` in package.json tells Node.js to treat `.js` files
as ESM. It has no effect on browsers or bundlers. Bundlers use the
`"module"` or `"exports"` fields to find ESM entry points.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `SyntaxError: Cannot use import statement in a module` in Node.js.**

Cause: Running ESM file with CommonJS Node runtime.

Fix: Either rename file to `.mjs`; add `"type": "module"` to
package.json; or add `--experimental-vm-modules` for jest compatibility.

**Failure: Browser module loading waterfall degrades performance.**

Cause: Deep import chains in unbundled mode: A imports B imports C
imports D - each level requires a new browser network request.

Fix: Use Vite (or similar) for production: it bundles ESM into
optimized chunks, eliminating the waterfall.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| ESM vs CJS - key differences | Comparison | ★★☆ | 3 min |
| What are live bindings? | Mechanism | ★★☆ | 2 min |
| Why does Vite not bundle in development? | Mechanism | ★★☆ | 2 min |
| What is an import map? | Definition | ★★☆ | 2 min |
| Why does production still need bundling with ESM? | Trade-off | ★★★ | 3 min |
| What is top-level await in ESM? | Mechanism | ★★☆ | 2 min |
| CJS live binding trap - debug the bug | Debugging | ★★★ | 3 min |
| ESM circular dependency behavior | Mechanism | ★★★ | 3 min |
| `type: "module"` in package.json vs `"module"` field | Comparison | ★★★ | 2 min |

**Q: Explain why Vite uses ESM in development but still bundles for production.**

A: Development and production have different constraints.

In development, speed of startup and hot reload matters most. If Vite
bundled during development, every project startup would take 5-30
seconds. Instead, Vite starts instantly: no bundling. When a file
changes, only that file is re-served. The browser handles dependency
resolution via native ESM imports.

This works in development because:
- Chrome DevTools source maps work perfectly with unbundled modules
- Developers are on fast local networks (no latency for module loading)
- The number of concurrent HTTP requests (hundreds in dev mode) is
  fine over localhost
- Vite pre-bundles only node_modules to ESM (using esbuild, once),
  since browsers can't handle CJS

In production, performance for end users matters most. An unbundled
app with 500 modules means:

- 500+ HTTP requests (even over HTTP/2, this adds latency)
- HTTP request overhead accumulates, especially on mobile networks
- Older browsers don't support ESM (Safari < 10.1, IE11)
- Dynamic import splitting can't be as granular without the bundler's
  code-splitting analysis

Vite's production build uses Rollup (or esbuild for libraries) to:
- Combine modules into optimized chunks (2-5 files typically)
- Apply tree shaking (remove unused exports)
- Minify the output
- Generate content-hashed filenames for cache busting

The result: development has instant startup (ESM native); production
has optimal performance (bundled, tree-shaken, minified).

*What separates good from great:* Understanding that the future may
converge: as HTTP/3 reduces request overhead, as browser module
loading optimizes, and as import maps become universally supported,
the production case for bundling weakens. Projects like Deno Deploy
and some edge runtimes already serve unbundled ESM in production for
simple apps. The decision is always a performance measurement on your
specific app and user network distribution, not a universal rule.

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



