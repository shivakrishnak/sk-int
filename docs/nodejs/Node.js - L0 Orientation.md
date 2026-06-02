---
layout: default
title: "Node.js - L0 Orientation"
parent: "Node.js"
nav_order: 1
permalink: /nodejs/l0-orientation/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Why Node.js Exists](#why-nodejs-exists) | medium |
| 2 | [Node.js vs Browser JavaScript](#nodejs-vs-browser-javascript) | medium |
| 3 | [npm Ecosystem Overview](#npm-ecosystem-overview) | medium |

---

# Why Node.js Exists

---

### 🎯 Model Answer

**30 seconds:**

> Node.js was created by Ryan Dahl in 2009 to solve one problem:
> web servers that block on I/O. Traditional server models (Apache,
> Java) use one thread per request - if a request waits for a database
> query, the thread is stuck doing nothing. Node.js uses a single
> thread with a non-blocking event loop: one thread handles thousands
> of concurrent I/O operations by yielding while waiting and resuming
> when results arrive. Same paradigm as the browser, but on the server.

**3 minutes:**

The problem Node.js solves is the C10K problem: how to handle 10,000
concurrent connections on a single server. The traditional model
(one thread per connection) fails here because:
- Each thread consumes ~1MB of stack memory
- Thread context switching is expensive
- Waiting for I/O (disk, network, database) wastes the thread

**The insight**: most web server work is I/O-bound, not CPU-bound.
A request arrives, the server waits for a database query (90% of
request time), then sends a response. The thread is idle 90% of the time.

**Node.js solution**: a single-threaded event loop that never blocks.
Instead of waiting for database results, Node.js registers a callback
and handles other work. When the database responds, the callback runs.
One thread handles thousands of concurrent operations.

**Why JavaScript**: browsers already had a non-blocking, event-driven
JavaScript runtime (V8 engine). Ryan Dahl took V8 out of the browser
and added I/O APIs (file system, network). Developers could use the
same language on client and server.

**Blank Mind Recovery:**

**(1) Problem:** "Traditional servers: 1 thread per request. 10k
connections = 10k threads = memory exhaustion."

**(2) Solution:** "Single thread + non-blocking I/O. Register callback,
do other work, callback fires when I/O completes."

**(3) Why JS:** "V8 already existed. Browser developers could write server code."

---

### 📘 Concept Explanation

**What it is:**

A server-side JavaScript runtime built on Chrome's V8 engine that
uses an event-driven, non-blocking I/O model for building scalable
network applications.

**The problem it solves:**

Thread-per-request models don't scale for I/O-heavy workloads. Node.js
uses cooperative concurrency (event loop) instead of preemptive
concurrency (threads), handling thousands of concurrent connections
with a single thread.

**How it works:**

```
Traditional thread model (Apache):
  Request 1 -> Thread 1 -> waits for DB (blocking) -> responds
  Request 2 -> Thread 2 -> waits for DB (blocking) -> responds
  10,000 requests = 10,000 threads = ~10GB memory

Node.js event loop model:
  Request 1 arrives -> register DB query callback -> continue
  Request 2 arrives -> register DB query callback -> continue
  DB response 1 -> run callback -> send response 1
  DB response 2 -> run callback -> send response 2
  10,000 requests = 1 thread = ~50MB memory

Non-blocking I/O means:
  fs.readFile('data.txt', callback)   // delegates to OS
  http.get('https://api.com', callback) // delegates to libuv
  db.query('SELECT ...', callback)    // delegates to DB driver
  No blocking: thread continues while OS handles I/O

Node.js strengths:
  High concurrency for I/O-heavy work
  Real-time applications (chat, live updates)
  API gateways and proxies
  Microservices with many external calls
  Streaming data processing

Node.js weaknesses:
  CPU-intensive work (image processing, encryption) blocks the loop
  Single-threaded: one CPU core by default (mitigated by clustering)
  Callback complexity (mitigated by async/await)
  Less mature ecosystem for heavy computation
```

> **Code walkthrough:** This Why Node.js Exists example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Recognition) - Non-blocking vs blocking pattern:**


```javascript
// BAD: not awaiting async operations
function saveUser(user) {
    db.save(user); // async call not awaited
    return { success: true }; // returns before save completes
}
```

```javascript
// BAD: synchronous/blocking - blocks event loop
const fs = require('fs');

// This blocks everything - no other requests can be handled:
const data = fs.readFileSync('large-file.txt', 'utf8');
console.log(data.length);

// GOOD: asynchronous/non-blocking - event loop continues
fs.readFile('large-file.txt', 'utf8', (err, data) => {
  if (err) throw err;
  console.log(data.length);
});
// Code after readFile continues IMMEDIATELY while OS reads the file:
console.log('This runs before file is read');
// Order: "This runs before..." -> then callback fires with data

// With async/await (modern Node.js):
const { readFile } = require('fs').promises;

async function processFile() {
  const data = await readFile('large-file.txt', 'utf8');
  // Non-blocking: event loop handles other work during await
  console.log(data.length);
}
```

> **Code walkthrough:** `readFileSync` blocks the Node.js processice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> until the file is fully read. During this time, no other requests
> can be processed. `readFile` with a callback delegates the I/O to
> the operating system, immediately returns, and the event loop continues
> processing other events. The callback fires when the OS delivers the
> file contents. `async/await` is syntactic sugar over this callback
> model: `await readFile(...)` suspends the current async function but
> does not block the thread - the event loop continues while the I/O
> completes.

---

### ⚖️ Comparison Table

| Model | Concurrency type | Memory per conn | CPU efficiency |
|---|---|---|---|
| Thread-per-request | Preemptive | ~1MB | Low (I/O-bound) |
| Node.js event loop | Cooperative | ~5-50KB | High (I/O-bound) |
| Node.js clustering | Multi-process | ~1 core per process | Good (multi-core) |
| Worker threads | Cooperative + threads | Medium | High (CPU-bound) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Node.js was created to handle many concurrent connections efficiently.
> Instead of one thread per request, Node.js uses a single thread with
> a non-blocking event loop. When a request needs I/O (database, file
> system), Node.js doesn't wait - it registers a callback and handles
> other requests. This lets one server handle thousands of concurrent
> connections.

**Senior / Staff:**

> Node.js solves the impedance mismatch between web server workloads
> (I/O-bound) and traditional concurrency models (CPU-per-thread). The
> event loop is optimal for I/O-heavy workloads: a single thread can
> handle 10,000 concurrent HTTP requests with significantly less memory
> than a thread-per-request model. The trade-off is that CPU-intensive
> work blocks the event loop - that's why Node.js added Worker Threads
> and why clustering is standard in production.

---

### ⚠️ Common Misconceptions

**Misconception: Node.js is single-threaded in all ways.**

Node.js JavaScript execution is single-threaded. But libuv (the
underlying I/O library) uses a thread pool (default: 4 threads) for
file system operations, DNS lookups, and crypto that can't be done
asynchronously by the OS. Network I/O (TCP/UDP) is handled by the
OS event mechanism (epoll/kqueue/IOCP), not the thread pool.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Node.js server becomes unresponsive under load.**

Cause: CPU-intensive operation blocking the event loop (image resize,
video processing, synchronous file operations, complex regex on
large strings).

Diagnose: `node --prof server.js` then `node --prof-process isolate-*.log`
to find hot functions. Or use Node.js built-in performance hooks:
`perf_hooks.performance.now()` around suspect code.

Fix: Move CPU-intensive work to Worker Threads or external services.
Never call `*Sync` APIs in request handlers.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| Why was Node.js created? | Definition | ★☆☆ | 2 min |
| What problem does the event loop solve? | Mechanism | ★★☆ | 3 min |
| Thread-per-request vs event loop trade-offs? | Comparison | ★★☆ | 3 min |
| What happens when CPU work blocks Node.js? | Failure | ★★☆ | 2 min |
| What is libuv? | Definition | ★★☆ | 2 min |

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


# Node.js vs Browser JavaScript

---

### 🎯 Model Answer

**30 seconds:**

> Both Node.js and browsers run JavaScript on V8, but the APIs differ
> fundamentally. Browsers have: DOM, window, document, localStorage,
> fetch (browser implementation), IndexedDB, service workers. Node.js
> has: fs, http, net, crypto, process, path, child_process, worker_threads.
> Neither has the other's APIs. Key: there's no `window` in Node.js,
> no `fs` in browsers. Shared: ES standard (let/const, classes, modules,
> async/await, Promises).

**Blank Mind Recovery:**

**(1) Shared:** "ES language features (syntax, promises, async/await).
Not the runtime APIs."

**(2) Browser only:** "DOM, window, document, localStorage, service workers."

**(3) Node.js only:** "fs, process, child_process, worker_threads, http server."

---

### 📘 Concept Explanation

**What it is:**

Two JavaScript environments that share the same language (ECMAScript)
but provide completely different runtime APIs.

**How they differ:**

```
JavaScript runtime environments comparison:

  Shared (ECMAScript standard):
    Variables: let, const, var
    Data structures: Array, Object, Map, Set, WeakMap
    Async: Promise, async/await
    Classes: class, extends
    Modules: ESM (import/export) - native in both
    Standard globals: Math, Date, JSON, console, setTimeout

  Browser-only:
    DOM: document.querySelector, addEventListener
    Window: window.location, window.history, window.alert
    Storage: localStorage, sessionStorage, IndexedDB, cookies
    APIs: fetch (browser), WebSockets, canvas, WebGL, WebRTC
    Workers: Web Workers, Service Workers
    No file system access (security sandbox)

  Node.js-only:
    File system: fs (read/write files, directories)
    Process: process.env, process.argv, process.exit()
    Networking: net (TCP), dgram (UDP), dns
    HTTP server: http.createServer(), https
    Child processes: child_process.exec(), fork(), spawn()
    Worker threads: worker_threads (CPU parallelism)
    Path: path.join(), path.resolve() (OS path handling)
    Streams: internal stream implementation
    Crypto: crypto (standard lib, not Web Crypto API)
    No DOM (no window, no document)

  fetch():
    Browser: built-in since Chrome 42
    Node.js: built-in since Node.js 18 (experimental), stable 21
    Before Node.js 18: required node-fetch package

  Buffer vs ArrayBuffer:
    Node.js: Buffer (extends Uint8Array) - primary binary type
    Browser: ArrayBuffer/TypedArray - primary binary type
    Modern Node.js: supports both

  Module systems:
    Node.js historically: CommonJS (require/module.exports)
    Modern: ESM (import/export, .mjs files or "type":"module")
    Browsers: ESM natively (no require())
```

> **Code walkthrough:** This Node.js vs Browser JavaScript example demonstrates a key concept in practice using async/await. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Recognition) - Environment-specific code:**

```javascript
// Environment detection (for isomorphic libraries):
const isNode = typeof process !== 'undefined'
  && process.versions != null
  && process.versions.node != null;

const isBrowser = typeof window !== 'undefined';

// File operations (Node.js only):
if (isNode) {
  const fs = require('fs');
  const data = fs.readFileSync('config.json', 'utf8');
}

// DOM access (browser only):
if (isBrowser) {
  document.getElementById('app').innerHTML = 'Hello';
}

// HTTP server (Node.js) vs HTTP client fetch (browser):
// Node.js server:
const http = require('http');
http.createServer((req, res) => {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello');
}).listen(3000);

// Browser client (or Node.js 18+):
const response = await fetch('/api/users');
const users = await response.json();

// CommonJS vs ESM:
// CommonJS (Node.js default before v12):
const express = require('express');
module.exports = { myFunction };

// ESM (modern - works in both):
import express from 'express';
export function myFunction() {}
```

> **Code walkthrough:** `typeof process !== 'undefined'` detects Node.jsice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> without throwing ReferenceError if process doesn't exist (browser).
> `typeof window !== 'undefined'` detects browser environment. These
> checks enable isomorphic code (runs in both) but should be used
> sparingly - better to separate node and browser code into different
> files. The HTTP examples illustrate the fundamental difference: Node.js
> creates servers, browsers create clients. Both can use `fetch` in
> modern versions, but historically this was browser-only.

---

### ⚖️ Comparison Table

| Feature | Node.js | Browser |
|---|---|---|
| File system | fs module | Not available |
| DOM | Not available | document, window |
| HTTP server | http.createServer | Not available |
| fetch | Since v18 | Yes (native) |
| Modules | CJS + ESM | ESM only |
| Environment vars | process.env | Not available |
| localStorage | Not available | Yes |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Node.js and browsers both run JavaScript but have different APIs.
> In Node.js I can use `fs`, `process`, and create HTTP servers. In
> the browser I have `document`, `localStorage`, and `fetch`. They
> share the JavaScript language (let/const, classes, async/await,
> Promises) but not the runtime APIs.

**Senior / Staff:**

> The key mental model: JavaScript is the language, V8 is the engine,
> Node.js and browsers are the runtimes. Runtimes provide different
> APIs. Writing isomorphic code (runs in both) requires careful
> abstraction or environment detection. Modern projects use bundlers
> (webpack, Vite) that replace Node.js-specific APIs with browser
> polyfills for shared code. The ESM module system is the convergence
> point - both environments support it natively, ending the CJS vs ESM
> split.

---

### ⚠️ Common Misconceptions

**Misconception: `require()` works everywhere in Node.js projects.**

CommonJS `require()` works in Node.js files using CJS modules. But
`.mjs` files or packages with `"type": "module"` in package.json use
ESM and require `import`. Mixing CJS and ESM in the same project
requires careful configuration. Modern projects use ESM throughout.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `ReferenceError: window is not defined`**

Cause: Code written for browser uses `window` directly in a Node.js
context (SSR, build tools, tests).

Fix: Replace `window.location` with environment-safe alternatives.
Use `globalThis` for the global object in both environments.
Guard browser code with `if (typeof window !== 'undefined')`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What APIs exist in Node.js but not browsers? | Definition | ★☆☆ | 2 min |
| What is isomorphic JavaScript? | Definition | ★★☆ | 2 min |
| CommonJS vs ESM - which to use? | Decision | ★★☆ | 2 min |
| `ReferenceError: window not defined` - cause and fix | Debugging | ★★☆ | 2 min |

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


# npm Ecosystem Overview

---

### 🎯 Model Answer

**30 seconds:**

> npm is Node.js's package manager: a registry of 2M+ packages, a
> CLI for installing/publishing them, and `package.json` as the manifest.
> `npm install` reads `package.json`, installs packages to `node_modules`,
> records exact versions in `package-lock.json`. Alternatives: yarn
> (faster, workspaces), pnpm (disk-efficient, strict peer deps). Key
> commands: `npm install`, `npm run <script>`, `npm publish`. `node_modules`
> is never committed to git.

**Blank Mind Recovery:**

**(1) Three components:** "Registry (packages). CLI (tool). package.json
(manifest)."

**(2) Two lock files:** "package.json = semver range. package-lock.json
= exact versions. ALWAYS commit lock file."

**(3) Alternatives:** "pnpm (fast, disk-efficient, strict). yarn (fast,
workspaces). Use one consistently per project."

---

### 📘 Concept Explanation

**What it is:**

The package manager for Node.js - both the registry hosting 2M+
open-source packages and the CLI tool for managing project dependencies.

**How it works:**

```
npm dependency management:

  package.json:
    "dependencies": {
      "express": "^4.18.0"   // ^ = compatible minor (4.x.x)
    },
    "devDependencies": {
      "jest": "~29.0.0"       // ~ = compatible patch (29.0.x)
    }

  Semver notation:
    4.18.0        exact version
    ^4.18.0       >=4.18.0 <5.0.0 (compatible minor)
    ~4.18.0       >=4.18.0 <4.19.0 (compatible patch)
    *             any version (DANGEROUS)

  npm install process:
    1. Read package.json for requirements
    2. If package-lock.json exists: install exact versions from lock
    3. If no lock: resolve semver ranges, install, create lock
    4. Write to node_modules/

  Key commands:
    npm install               # install all dependencies
    npm install express       # add dependency
    npm install -D jest       # add devDependency
    npm install --production  # install only dependencies (no dev)
    npm ci                    # clean install from lock file (CI)
    npm run test              # run test script from package.json
    npm run build             # run build script
    npm outdated              # show outdated packages
    npm audit                 # security vulnerability scan
    npm publish               # publish to registry

  npm vs yarn vs pnpm:
    npm: default, included with Node.js
    yarn: faster (parallel), workspaces, Plug'n'Play (no node_modules)
    pnpm: disk-efficient (symlinks), strict peer deps, fastest

  node_modules/ structure:
    npm v3+: flat (deduplicates shared deps)
    pnpm: symlinked (.pnpm store, strict)
    All: never commit to git (.gitignore node_modules/)
```

> **Code walkthrough:** This npm Ecosystem Overview example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Production) - package.json structure:**

```json
{
  "name": "my-app",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node dist/server.js",
    "dev": "nodemon src/server.ts",
    "build": "tsc",
    "test": "jest",
    "test:watch": "jest --watch",
    "lint": "eslint src/",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "express": "^4.18.2",
    "zod": "^3.22.4"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.0.0",
    "typescript": "^5.3.0",
    "jest": "^29.7.0",
    "ts-jest": "^29.1.0",
    "eslint": "^8.55.0",
    "nodemon": "^3.0.0"
  },
  "engines": {
    "node": ">=20.0.0"
  }
}
```

> **Code walkthrough:** This npm Ecosystem Overview example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Example (Wrong vs Right) - Security practices:**


```bash
# BAD: unsafe shell scripting pattern
```


```bash
# BAD: unsafe shell scripting pattern
```

```bash
# BAD: committing node_modules
git add node_modules/  # 100MB+ of code, contains binaries

# GOOD: .gitignore
# .gitignore:
# node_modules/
# dist/
# .env

# BAD: using exact versions in package.json for all deps
"express": "4.18.2"  # Won't receive security patches automatically

# GOOD: use ranges for flexibility, lock for reproducibility
"express": "^4.18.2"  # range in package.json
# package-lock.json records exact version 4.18.2
# npm ci installs exactly 4.18.2 in CI
# npm update upgrades within the range when available

# Always run security scan:
npm audit
# Fix vulnerabilities:
npm audit fix
# For major version fixes (breaking changes):
npm audit fix --force  # review before using
```

> **Code walkthrough:** `package.json` serves two purposes: definingice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> the project metadata and scripting. `private: true` prevents accidental
> publish. `"type": "module"` enables ESM throughout the package.
> `scripts` defines runnable commands: `npm run dev`, `npm run build`.
> Dependencies in `dependencies` are required at runtime; `devDependencies`
> are only needed during development and CI. `engines.node` documents
> the required Node.js version and can be enforced by package managers.
> The `package-lock.json` is crucial for reproducible installs: `npm ci`
> (used in CI) installs exactly the versions in the lock file, not the
> latest matching semver range.

---

### ⚖️ Comparison Table

| Tool | Speed | Disk usage | Strict deps | Workspaces |
|---|---|---|---|---|
| npm | Good | High | Loose | Yes |
| yarn | Fast | High | Moderate | Yes (v1+) |
| pnpm | Fastest | Low | Strict | Yes |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> npm is how I install packages for Node.js. `npm install express` adds
> it to `package.json` and `node_modules`. I never commit `node_modules`.
> `package-lock.json` records exact versions for reproducible installs.
> `npm ci` is faster and cleaner for CI environments.

**Senior / Staff:**

> The lock file is the critical artifact: `package.json` defines semver
> ranges, `package-lock.json` records exact resolved versions. Always
> commit the lock file. `npm ci` (used in CI) is stricter: it deletes
> `node_modules` and installs exactly from the lock file, failing if
> package.json and lock file are out of sync. `npm install` updates the
> lock file; `npm ci` only reads it. For large monorepos, pnpm's
> symlink-based approach saves significant disk space and is faster
> than npm or yarn.

---

### ⚠️ Common Misconceptions

**Misconception: `package.json` is enough for reproducible installs.**

Without `package-lock.json`, `npm install` resolves the latest matching
semver version at install time. Running it a week later can install
a different (buggy) version. The lock file records exact resolved
versions. Always commit `package-lock.json` (or `yarn.lock` / `pnpm-lock.yaml`).

---

### 🚨 Failure Modes and Diagnosis

**Failure: "works on my machine, fails in CI" package issues.**

Cause: `package-lock.json` not committed, or `npm install` used instead
of `npm ci` in CI.

Fix:
1. Commit `package-lock.json`
2. Use `npm ci` in CI (not `npm install`)
3. Run `npm ci` locally to verify lock file is clean

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is `package-lock.json` and why commit it? | Mechanism | ★☆☆ | 2 min |
| `npm install` vs `npm ci` - difference? | Comparison | ★★☆ | 2 min |
| `dependencies` vs `devDependencies` | Definition | ★☆☆ | 1 min |
| Semver `^` vs `~` | Definition | ★★☆ | 2 min |
| npm vs pnpm vs yarn - when to use each? | Decision | ★★☆ | 3 min |

**Q: How do you handle security vulnerabilities in npm dependencies?**

A:
1. `npm audit` - reports known vulnerabilities from npm advisory database
2. `npm audit fix` - auto-fix by upgrading to patched versions
3. `npm audit fix --force` - for major version upgrades (review
   breaking changes before using)

For automation:
- GitHub Dependabot: creates PRs automatically for vulnerable packages
- Snyk: deeper analysis, can identify transitive vulnerabilities

Policy:
- Run `npm audit` in CI, fail on high/critical severity
- Weekly dependency updates via Dependabot or Renovate Bot
- Pin major versions: `"express": "4.x"` not `"*"`

*What separates good from great:* Understanding that `npm audit`
only checks `node_modules` against the npm advisory database. Transitive
dependencies (dependencies of dependencies) can also have vulnerabilities
that `npm audit` catches. Use `npm ls <package>` to trace which
dependency requires a vulnerable package.

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



