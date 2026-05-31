---
layout: default
title: "Frontend Build Tools - L2 Optimization"
parent: "Frontend Build Tools"
nav_order: 5
permalink: /frontend-build-tools/l2-optimization/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Code Splitting and Lazy Loading](#code-splitting-and-lazy-loading) | medium |
| 2 | [Tree Shaking and Dead Code Elimination](#tree-shaking-and-dead-code-elimination) | medium |

---

# Code Splitting and Lazy Loading

---

### 🎯 Model Answer

**30 seconds:**

> Code splitting divides your JavaScript into multiple chunks that
> are loaded on demand. The most impactful technique: route-based
> splitting with `React.lazy(() => import('./pages/Dashboard'))`.
> The bundler outputs separate chunks per route; the browser downloads
> only what it needs. The result: a smaller initial bundle, faster
> first load, and cached route chunks for return visits.

**Blank Mind Recovery:**

**(1) Restate:** "Code splitting: one big bundle -> many small chunks.
Lazy loading: download on demand. Route splitting = most impact."

---

### 📘 Concept Explanation

**What it is:**

Code splitting is a build technique that divides the JavaScript bundle
into multiple smaller chunks. Lazy loading is the browser behavior
of downloading those chunks on demand, when they are needed.

**The problem it solves:**

A monolithic bundle requires downloading, parsing, and executing all
JavaScript before anything is interactive. A 1MB bundle on mobile
means 3-5 seconds before the user can interact. Code splitting delivers
only what is needed for the current page.

**How it works:**

```
Without code splitting:
  all code in main.js (500KB+)
  User visits homepage -> downloads ALL 500KB including
    admin panel, settings page, rarely-used features

With route-based code splitting:
  main.js (80KB) - React, Router, common components
  home.js (15KB) - loaded when user visits /
  dashboard.js (90KB) - loaded when user visits /dashboard
  admin.js (120KB) - loaded ONLY if user visits /admin

Code splitting mechanisms:

1. Dynamic import (standard, works everywhere):
  const module = await import('./heavyModule.js');

2. React.lazy (React-specific):
  const Dashboard = React.lazy(() => import('./pages/Dashboard'));
  // Wrap with Suspense to show fallback while loading:
  <Suspense fallback={<Spinner />}>
    <Dashboard />
  </Suspense>

3. Prefetching (load before needed):
  import(/* webpackPrefetch: true */ './pages/AdminPanel');
  // Added to <link rel="prefetch"> - loads during browser idle
  // For Vite: use vite-plugin-prefetch or manual prefetch

4. preloading (load in parallel with current):
  import(/* webpackPreload: true */ './criticalComponent');
  // Added to <link rel="preload"> - downloads immediately
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**

Dynamic imports are the mechanism; React.lazy is the React API wrapper.
The bundler (webpack/Rollup) splits at dynamic import boundaries.
`React.Suspense` provides the loading UI while the chunk downloads.

**When to use it:**

Always for routes (pages). Consider for: large rarely-used components
(chart libraries, PDF viewers, rich text editors), admin sections,
and feature-flagged components.

**When NOT to use it:**

Don't split tiny modules (< 5KB). The network round-trip cost exceeds
the savings. Don't split critical above-the-fold components.

---

### 💻 Code Example

**Example 1: Route-based code splitting with React Router**

```tsx
import React, { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';
import { PageSpinner } from './components/PageSpinner';

// Static: always in initial bundle (critical path)
import Layout from './components/Layout';
import ErrorBoundary from './components/ErrorBoundary';

// Lazy: each creates a separate chunk
// Bundler outputs: dashboard.[hash].js, admin.[hash].js, etc.
const Home = lazy(() => import('./pages/Home'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));
const AdminPanel = lazy(() => import('./pages/AdminPanel'));

export function AppRouter() {
  return (
    <Layout>
      <ErrorBoundary>
        {/* Suspense provides fallback while chunk downloads */}
        <Suspense fallback={<PageSpinner />}>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/dashboard" element={<Dashboard />} />
            <Route path="/settings" element={<Settings />} />
            <Route path="/admin/*" element={<AdminPanel />} />
          </Routes>
        </Suspense>
      </ErrorBoundary>
    </Layout>
  );
}
```

> **Code walkthrough:** Each `lazy()` call creates a split boundary.
> The bundler outputs a separate chunk for each page. When the user
> navigates to `/dashboard`, React downloads `dashboard.[hash].js`,
> shows the Suspense fallback (`<PageSpinner />`) during the download,
> then renders the component. The `ErrorBoundary` above `Suspense`
> catches chunk loading failures (network error, 404) and shows a
> useful error state instead of crashing.

**Example 2: Component-level splitting and prefetching**

```tsx
import React, { lazy, Suspense, useState } from 'react';

// Heavy component: only loaded when modal opens
const RichTextEditor = lazy(
  () => import('./components/RichTextEditor')
);

function BlogPost({ initialContent }: { initialContent: string }) {
  const [editing, setEditing] = useState(false);
  const [prefetchStarted, setPrefetchStarted] = useState(false);

  // Prefetch on hover (before user clicks Edit)
  const handleEditButtonHover = () => {
    if (!prefetchStarted) {
      // Start downloading the chunk while user is hovering
      import('./components/RichTextEditor');
      setPrefetchStarted(true);
    }
  };

  return (
    <article>
      <button
        onMouseEnter={handleEditButtonHover}  // prefetch
        onClick={() => setEditing(true)}
      >
        Edit Post
      </button>

      {editing && (
        <Suspense fallback={<div>Loading editor...</div>}>
          <RichTextEditor initialValue={initialContent} />
        </Suspense>
      )}
    </article>
  );
}
```

> **Code walkthrough:** RichTextEditor (likely 100KB+) is split into
> its own chunk and only downloaded when editing starts. The hover
> prefetch is a UX optimization: when the user hovers over the Edit
> button, the chunk starts downloading. By the time they click, the
> chunk may already be cached. Calling `import('./component')` without
> using the result is valid - it triggers the download and caches it
> for when React.lazy actually needs it.

---

### ⚖️ Comparison Table

| Splitting strategy | When to use | Impact |
|---|---|---|
| Route-based | Always | Highest: users load one route at a time |
| Component-level | Heavy, rarely-used components | Medium: reduces specific page bundles |
| Vendor splitting | Libraries vs app code | Improves caching, not initial load |
| Manual chunks | Fine-tune what goes where | Low-medium: optimization step |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Code splitting breaks the bundle into chunks. Route-based splitting
> is the most common: each route is a lazy component. The browser only
> downloads the chunk for the current page. React.lazy with Suspense
> handles the loading state.

**Senior / Staff:**

> I always apply route-based splitting as a baseline. For large apps
> I additionally split: heavy vendor libraries (recharts, D3, TipTap)
> into named chunks, admin sections loaded only for admin users, and
> feature-flagged components. I measure impact with Lighthouse and
> bundle analyzer. The rule: any chunk > 100KB that is not on the
> critical path should be split. Prefetching on hover is a high-ROI
> UX trick for common user flows.

---

### ⚠️ Common Misconceptions

**Misconception 1: More code splitting is always better.**

Splitting tiny modules (< 5KB) adds network round-trip overhead
without meaningful savings. Split at meaningful boundaries: routes,
heavy libraries, rarely-accessed features.

**Misconception 2: React.lazy works at the top level (not in conditionals).**

`React.lazy` calls should be at the module level, not inside
components. Defining lazy components inside render functions creates
new dynamic imports on every render.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Chunk failed to load (network error).**

Symptom: White screen or broken UI after navigation.

Fix: Add ErrorBoundary above Suspense to catch load failures;
show retry option.

**Failure: All components split into individual chunks (too many).**

Cause: Dynamic import inside a loop or too granular splitting.

Fix: Group related components; only split at route or feature boundaries.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is code splitting? | Definition | ★★☆ | 2 min |
| How does React.lazy work? | Mechanism | ★★☆ | 2 min |
| What is the purpose of Suspense? | Mechanism | ★★☆ | 2 min |
| Route splitting vs component splitting | Comparison | ★★☆ | 2 min |
| How to prefetch a chunk? | Mechanism | ★★☆ | 2 min |
| How does a chunk loading failure manifest? | Failure | ★★☆ | 2 min |
| Performance budget - when to split? | Decision | ★★★ | 3 min |

**Q: Describe when code splitting creates a bad experience.**

A: Code splitting introduces a loading gap: the user clicks navigation,
sees the Suspense fallback (spinner), waits, then sees the page. On
fast connections this is imperceptible. On slow connections it can be
500ms-3s.

Bad experience cases:

Spinner on main content: if the above-the-fold content is in a lazy
chunk, the user sees a spinner where they expect content. Fix: keep
layout and first-visible components in the main bundle.

No error handling: if the chunk fails to load (404, network error,
CDN down), React propagates an error. Without an ErrorBoundary, the
entire tree crashes to a white screen. Fix: wrap Suspense with ErrorBoundary.

Excessive granularity: too many tiny chunks (< 10KB) means many
waterfall requests. The browser HTTP/2 multiplexing helps but there
are limits. Fix: group related modules.

No prefetching for critical paths: if users almost always go to the
dashboard after login, the dashboard chunk should be prefetched during
the login page load. This eliminates the loading gap for the most
common flow.

*What separates good from great:* Understanding Largest Contentful Paint
(LCP) and code splitting interaction. The LCP element (hero image,
heading, main content) must not be behind a lazy boundary. Google's
Core Web Vitals measurement penalizes LCP > 2.5s. Route splitting
that puts the LCP element in a lazy chunk directly hurts the LCP score
and SEO ranking.

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


# Tree Shaking and Dead Code Elimination

---

### 🎯 Model Answer

**30 seconds:**

> Tree shaking removes unused exports from your bundle. Import `{ sortBy }` from
> lodash-es and only that function is included - the other 300 lodash
> functions are removed. This requires ES modules (static imports),
> not CommonJS (`require`). Bundlers analyze the module graph at build
> time and eliminate any exports that are never imported anywhere.

**Blank Mind Recovery:**

**(1) Restate:** "Tree shaking = dead export removal. Requires ESM
static imports. Enabled by default in production webpack/Vite builds."

---

### 📘 Concept Explanation

**What it is:**

Tree shaking is the build process of analyzing the module dependency
graph and removing code that is exported but never imported anywhere.
The term comes from the idea of shaking a tree to drop dead leaves.

**The problem it solves:**

JavaScript ecosystems have many large packages. Installing React Router,
lodash, or Material UI and using one function or component shouldn't
include the entire library in the bundle.

**How it works:**

```
Requirements for tree shaking:
  1. ES modules (static import/export)
  2. No side effects in unused modules
  3. Bundler with tree shaking support (webpack, Rollup/Vite)

How it works:
  1. Bundler builds module graph from entry point
  2. For each exported symbol, tracks all imports
  3. Any export with zero importers -> "dead code"
  4. Dead code removed from output

Example:
  // utils.js:
  export function add(a, b) { return a + b; }
  export function multiply(a, b) { return a * b; }
  export function divide(a, b) { return a / b; }

  // app.js:
  import { add } from './utils.js';  // only uses add
  console.log(add(1, 2));

  // After tree shaking: multiply and divide removed
  // Bundle contains only: add function

Side effects - the complication:
  // polyfill.js (has side effects):
  Array.prototype.at = function(i) { ... }; // modifies global

  // If polyfill.js is imported but its exports are unused,
  // tree shaking would remove it - WRONG! Side effect needed.

  // package.json (in polyfill package):
  { "sideEffects": ["./polyfills.js"] }
  // or: "sideEffects": false  (safe to fully tree-shake)

Real-world: lodash vs lodash-es
  import { sortBy } from 'lodash';    // CJS: whole lodash included
  import { sortBy } from 'lodash-es'; // ESM: only sortBy included
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**

`sideEffects: false` in package.json is the publisher's declaration
that the package is safe to tree-shake. Without it, bundlers must
conservatively keep all modules that were imported, even if their
exports are unused (to preserve potential side effects).

**When to use it:**

Tree shaking is automatic in production webpack and Vite builds. Your
responsibility: use ESM packages (lodash-es not lodash), avoid barrel
files (index.ts that re-exports everything), and configure `sideEffects`
in your own packages.

---

### 💻 Code Example

**Example 1: The barrel file anti-pattern**

```typescript
// BAD: barrel file imports (defeats tree shaking)
// src/components/index.ts (barrel):
export { Button } from './Button';
export { Input } from './Input';
export { Modal } from './Modal';
export { Table } from './Table';
export { Chart } from './Chart';  // imports recharts (500KB!)

// Consumer:
import { Button } from '../components'; // imports ALL components
// Even though only Button is used, the bundler may include
// Modal, Table, Chart (and recharts!) in the bundle
// because the barrel file re-exports everything together

// GOOD: direct imports
import { Button } from '../components/Button';
// Only Button is imported; recharts never loaded

// Even better: configure bundler barrel optimization
// vite.config.ts:
import { defineConfig } from 'vite';
import { optimizeBarrel } from 'vite-plugin-barrel'; // plugin

// webpack: use babel-plugin-import for MUI/antd
// transforms: import { Button } from '@mui/material'
// to: import Button from '@mui/material/Button/Button'
```

> **Code walkthrough:** Barrel files are index.ts files that re-export
> from many sub-modules. They improve developer experience (one import
> path) but disable tree shaking if the bundler cannot statically
> analyze which exports are used. The fix: direct imports. For large
> component libraries (MUI, antd), use babel-plugin-import or the
> library's official tree-shaking guide - these libraries publish ESM
> builds that most modern bundlers can tree-shake.

**Example 2: sideEffects configuration**

```json
// In your library's package.json:
{
  "name": "my-ui-lib",
  "sideEffects": false,
  // Declares: "no modules in this package have side effects"
  // Bundlers can safely tree-shake any unused export

  // If some files DO have side effects, list them:
  "sideEffects": [
    "./src/polyfills.js",  // modifies globals
    "./src/global.css",    // CSS imports (always side effects)
    "*.css"                // all CSS files
  ]
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

```javascript
// Check if tree shaking is working:
// 1. Build with bundle analyzer
ANALYZE=true npm run build

// 2. Check if expected-unused code appears
// Use webpack-bundle-analyzer or vite-bundle-visualizer
// Click on a chunk to see which modules it contains
// If you see 'lodash' instead of 'lodash-es', switch packages

// 3. Verify with actual bundle inspection:
grep -c 'multiply' dist/main.js
# 0 - tree shaking worked
# >0 - tree shaking didn't work for this export
```

> **Code walkthrough:** `sideEffects: false` is a package.json field
> that signals to bundlers: "you can remove any of my exports that
> are not imported." CSS files are always side effects (importing them
> adds CSS to the page even if no exports are used). The bundle analyzer
> is the essential diagnostic tool - it shows exactly which modules
> are in each chunk, making it possible to see if lodash (CJS, 70KB)
> accidentally made it in despite using lodash-es (ESM, tree-shakeable).

---

### ⚖️ Comparison Table

| Package | Format | Tree-shakeable | Bundle impact |
|---|---|---|---|
| lodash | CommonJS | No | All 70KB always included |
| lodash-es | ESM | Yes | Only used functions included |
| date-fns | ESM | Yes | Per-function imports |
| moment.js | CommonJS + locales | Poor | 70KB+ always, locales extra |
| dayjs | CommonJS + plugins | Partial | Small core, plugins separate |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Tree shaking removes unused code from the bundle. If I import only
> `sortBy` from lodash-es, only that function is in the bundle. It
> requires ES modules (not CommonJS `require`).

**Senior / Staff:**

> Tree shaking requires: ESM, no accidental side effects, and
> `sideEffects: false` declaration. The barrel file anti-pattern
> silently disables tree shaking. I audit bundles with bundle-analyzer
> after major dependency additions. For libraries I publish, I always
> set `sideEffects: false` and use `preserveModules` for per-file
> tree-shakeability. The lodash vs lodash-es choice alone can save
> 70KB for a typical app.

---

### ⚠️ Common Misconceptions

**Misconception 1: Tree shaking works with CommonJS.**

Tree shaking requires ESM static imports. CommonJS `require()` is
a runtime function call - bundlers cannot statically analyze it.

**Misconception 2: Importing from a barrel file is always fine.**

Barrel files can break tree shaking if the bundler cannot determine
which re-exports are used. Prefer direct imports for large libraries.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Entire lodash included despite using only one function.**

Cause: Importing from `lodash` (CJS) not `lodash-es` (ESM).

Fix: `npm install lodash-es`; change all imports to `from 'lodash-es'`.

**Failure: Library's unused components appear in bundle.**

Cause: Barrel file import; or library not published as ESM.

Fix: Direct imports; check if library has an ESM build (pkg.exports);
use babel-plugin-import for popular UI libs.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is tree shaking? | Definition | ★★☆ | 2 min |
| Why does tree shaking require ESM? | Mechanism | ★★☆ | 2 min |
| What is sideEffects:false? | Mechanism | ★★☆ | 2 min |
| lodash vs lodash-es - tree shaking impact? | Comparison | ★★☆ | 2 min |
| What are barrel files and why are they problematic? | Trade-off | ★★☆ | 3 min |
| How to debug tree shaking not working? | Debugging | ★★☆ | 3 min |
| How to publish a library that is tree-shakeable? | Scenario | ★★★ | 4 min |

**Q: How do you debug when tree shaking is not working?**

A: Three-step investigation:

Step 1: Bundle visualizer. Run `ANALYZE=true npm run build` (webpack)
or `npx vite-bundle-visualizer` (Vite). Open the report and look for
packages that should have been tree-shaken. If you see the entire
lodash in the bundle despite using only `sortBy`, tree shaking failed.

Step 2: Check the import source. `lodash` is CJS - not tree-shakeable.
`lodash-es` is ESM - tree-shakeable. Check if you're using the ESM
version of large packages. Look at the package's `package.json` for
`"type": "module"` or `"exports"` with ESM paths.

Step 3: Check for sideEffects. Your app's `package.json` may not have
`sideEffects: false`. Without it, bundlers conservatively keep all
imported modules. Check the library's `package.json` too.

Verify the fix: after changing, re-run the bundle visualizer and
compare sizes. Use `grep -r 'unusedFunctionName' dist/` to confirm
the function was removed.

*What separates good from great:* The "module" field in package.json
was the original ESM signal. Modern bundlers prefer the `exports` field
with explicit `"import"` paths. If a package has `"exports"` it takes
precedence. Check both when diagnosing.

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



