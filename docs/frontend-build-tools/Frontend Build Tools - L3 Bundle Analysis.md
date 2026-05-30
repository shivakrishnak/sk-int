---
layout: default
title: "Frontend Build Tools - L3 Bundle Analysis"
parent: "Frontend Build Tools"
nav_order: 8
permalink: /frontend-build-tools/l3-bundle-analysis/
---

# Bundle Analysis and Size Optimization

---

### 🎯 Model Answer

**30 seconds:**

> Bundle analysis identifies what's making your JavaScript bundle
> large. Tools: `webpack-bundle-analyzer` (webpack) and
> `vite-bundle-visualizer` (Vite) produce interactive treemaps showing
> module sizes. Common findings: lodash (full CJS) instead of lodash-es,
> moment.js with all locales, duplicate vendor chunks, and accidentally
> bundled test utilities. The fix: switch to ESM packages, remove unused
> features, and apply code splitting.

**Blank Mind Recovery:**

**(1) Restate:** "Bundle analysis: visualize what's in the bundle.
Tools: bundle-analyzer / bundle-visualizer. Find and remove large
unexpected modules."

---

### 📘 Concept Explanation

**What it is:**

Bundle analysis tools produce interactive visualizations of bundle
composition - which modules are in each chunk, how large they are,
and how they relate. This makes optimization actionable.

**The problem it solves:**

A 1MB bundle with no analysis is a black box. Bundle analysis reveals:
which library is responsible for 40% of the bundle, whether lodash
is fully included despite only using one function, and whether admin-
only code is accidentally in the main bundle.

**How it works:**

```
webpack-bundle-analyzer:
  npm install --save-dev webpack-bundle-analyzer

  // webpack.config.js:
  const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
  plugins: [
    ...(process.env.ANALYZE === 'true'
      ? [new BundleAnalyzerPlugin()]
      : []),
  ]

  # Run: ANALYZE=true npm run build
  # Opens browser with interactive treemap

Vite bundle visualizer:
  # One-time analysis (no config change needed):
  npx vite-bundle-visualizer
  # Or: npm install --save-dev rollup-plugin-visualizer

  // vite.config.ts:
  import { visualizer } from 'rollup-plugin-visualizer';
  plugins: [
    ...(process.env.ANALYZE === 'true'
      ? [visualizer({ open: true, gzipSize: true })]
      : []),
  ]

Reading the report:
  - Treemap: each box = one module, size proportional to size
  - Nested boxes: module inside chunk inside bundle
  - Colors: can indicate package source (node_modules vs src)

Common findings and fixes:
  1. lodash (full): switch to lodash-es + tree shaking
  2. moment.js (70KB+): switch to date-fns or dayjs
  3. Admin code in main bundle: add React.lazy split
  4. Duplicate React versions: npm dedupe
  5. test-utils in prod: check dependencies classification
  6. @sentry/browser: add Sentry to manual vendor chunk
```

**The key insight:**

Bundle analysis is a periodic diagnostic, not a continuous process.
Run it: after adding a new dependency, when bundle size grows
unexpectedly, and before production launches. A performance budget
(alert when main bundle > 200KB) automates the detection.

---

### 💻 Code Example

**Example 1: Setting up performance budgets**

```javascript
// webpack.config.js - performance budgets block builds
module.exports = {
  performance: {
    hints: 'error',           // error in prod (warn in dev)
    maxEntrypointSize: 250000,  // 250KB entry point limit
    maxAssetSize: 200000,       // 200KB per asset limit
    assetFilter(assetFilename) {
      // Only check JS, not images
      return assetFilename.endsWith('.js');
    },
  },
};
```

```javascript
// Vite with bundlesize check (via bundlesize2 or similar):
// package.json:
{
  "bundlesize": [
    { "path": "./dist/assets/index-*.js", "maxSize": "200kb" },
    { "path": "./dist/assets/vendor-*.js", "maxSize": "500kb" }
  ],
  "scripts": {
    "build:check": "vite build && bundlesize"
  }
}
```

```bash
# Analyze bundle composition:
ANALYZE=true npm run build

# Alternatively: analyze without rebuilding (use stats.json):
webpack --profile --json > stats.json
npx webpack-bundle-analyzer stats.json

# Check for unexpected large modules:
# In the visualizer, click a large vendor chunk:
# If you see: lodash@4.17.21 (68.3KB) - switch to lodash-es
# If you see: moment@2.29.4 (72.1KB) - switch to dayjs (2KB)
# If you see: @sentry/browser (96KB) - add lazy loading

# Quick size check without visualizer:
ls -la dist/assets/*.js | sort -k5 -n -r | head -10
# Or with sizes in KB:
du -sh dist/assets/*.js | sort -rh | head -10
```

> **Code walkthrough:** Performance budgets in webpack cause the build
> to fail when assets exceed limits. This prevents bundle size regressions
> from slipping through code review unnoticed. The budget should match
> your mobile performance targets: 200KB initial JS means ~1.5s parse
> time on a mid-range Android. Run `stats.json` analysis offline (no
> build time overhead) when investigating specific issues.

**Example 2: Systematic size reduction workflow**

```bash
# Step 1: Baseline measurement
npm run build
# Note current sizes: main.js: 487KB

# Step 2: Identify largest chunks
ANALYZE=true npm run build
# Finding: lodash fully included (68KB), moment (72KB)

# Step 3: Fix lodash - switch to lodash-es
npm uninstall lodash
npm install lodash-es

# Update imports:
# BAD: import { sortBy } from 'lodash';
# GOOD: import { sortBy } from 'lodash-es';

# Step 4: Fix moment - replace with dayjs
npm uninstall moment
npm install dayjs
# dayjs core: 2KB vs moment's 72KB

# Step 5: Add code splitting for admin section
# BEFORE: AdminPanel loaded on every page visit
# AFTER: lazy(() => import('./pages/AdminPanel'))

# Step 6: Re-measure
npm run build
# main.js: 487KB -> 310KB (37% reduction)
# admin.js: 0 -> 45KB (only for admin users)

# Step 7: Add performance budget to prevent regression
# webpack performance.maxEntrypointSize: 320000
```

> **Code walkthrough:** The systematic workflow prevents chasing the
> wrong optimizations. Always measure first (step 1-2), then fix by
> category (step 3-5), then re-measure to verify impact (step 6). The
> performance budget (step 7) is the prevention layer - it fails the
> build if size regresses, making the optimization permanent.

---

### ⚖️ Comparison Table

| Tool | For | Shows gzip? | Interactive? | CI support |
|---|---|---|---|---|
| webpack-bundle-analyzer | webpack | Optional | Yes | Via stats.json |
| rollup-plugin-visualizer | Vite/Rollup | Yes | Yes | Via plugin |
| bundlesize | Any | Yes | No (CLI) | Yes (fail build) |
| Lighthouse CI | Any | N/A | No (metrics) | Yes |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I run `ANALYZE=true npm run build` to open the bundle visualizer.
> I look for unexpectedly large packages and switch to lighter
> alternatives or add code splitting.

**Senior / Staff:**

> Bundle analysis is part of my performance workflow: baseline measure,
> visualize, identify 80/20 wins (usually 2-3 large packages), fix,
> re-measure. I add performance budgets in webpack/bundlesize to CI
> so regressions fail the build automatically. The biggest wins I've
> seen: removing lodash CJS (68KB save), replacing moment with dayjs
> (70KB save), and adding route splitting to move admin code out of
> the initial bundle.

---

### ⚠️ Common Misconceptions

**Misconception 1: Gzip size is what matters for performance.**

Both matter: gzip size affects transfer time (network), but the
browser must parse and execute the uncompressed JavaScript. Parse
time is proportional to file size, not gzip size.

**Misconception 2: Minification replaces bundle size optimization.**

Minification reduces 20-30%. Removing unnecessary packages or splitting
can reduce 50-80%. They are complementary, not alternatives.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Bundle size grew significantly after adding a package.**

Diagnose: Run bundle analyzer; identify new module. Check if it has
an ESM build; check if it bundles its own dependencies.

Fix: Use tree-shakeable alternative; add to manualChunks to split.

**Failure: Build doesn't fail despite exceeding size budget.**

Cause: performance.hints is 'warning' not 'error'; or budget too high.

Fix: Set `hints: 'error'` and realistic limits.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How do you analyze bundle size? | Scenario | ★★☆ | 2 min |
| What are the most common bundle size culprits? | Definition | ★★☆ | 3 min |
| How do you prevent size regressions? | Design | ★★☆ | 2 min |
| lodash vs lodash-es - what's the size difference? | Comparison | ★★☆ | 2 min |
| Parse time vs transfer time - which matters more? | Comparison | ★★☆ | 2 min |
| Walk through a size optimization workflow | Scenario | ★★★ | 5 min |
| What is a performance budget? | Definition | ★★☆ | 2 min |

**Q: Walk through your bundle size optimization process.**

A: I follow a measure-analyze-fix-prevent workflow:

Measure: Run a production build and record baseline sizes. Use
`ls -la dist/assets/*.js | sort -k5 -n -r` for a quick view or
Lighthouse for user-facing metrics.

Analyze: Run the bundle visualizer (`ANALYZE=true npm run build`).
Look for: large vendor packages that should be tree-shaken (lodash,
moment), packages that appear multiple times (version conflict),
modules in the wrong chunk (admin code in main bundle), and test
utilities in production (classification error).

Fix by priority (80/20 approach):
1. Switch CJS packages to ESM equivalents (lodash->lodash-es, moment->dayjs)
2. Add code splitting at route boundaries
3. Extract large optional features (charts, editors) into lazy chunks
4. Fix version conflicts (`npm dedupe`)
5. Verify `sideEffects: false` declarations

Prevent regression: add performance budgets via webpack
`performance.maxEntrypointSize` or bundlesize in CI. Configure as
`error` (not `warning`) to fail builds that exceed limits.

*What separates good from great:* Tracking long-term trends in a
metrics dashboard. Bundle size creep is slow - no individual change
is alarming. But 10 PRs each adding 5KB results in a 50KB regression
over a sprint. Lighthouse CI with historical tracking makes this
visible before it becomes a user problem.

---

# Build Caching Strategies

---

### 🎯 Model Answer

**30 seconds:**

> Build caching stores transformation results so unchanged files are
> not re-processed. webpack 5 has filesystem caching. Vite pre-bundles
> dependencies to `.vite/`. Turborepo adds monorepo-level task output
> caching with remote sharing. In CI, save and restore the cache
> directory between runs. A well-configured cache reduces CI build
> time from minutes to seconds for typical code-only changes.

**Blank Mind Recovery:**

**(1) Restate:** "Build caching: skip re-processing unchanged files.
webpack: filesystem cache. Vite: .vite/ pre-bundle. Turborepo: task
output cache + remote."

---

### 📘 Concept Explanation

**What it is:**

Build caching is storing the results of transformations (compiled TS,
transformed modules, bundled output) keyed by input content hashes.
If inputs haven't changed, cached output is used instead of reprocessing.

**The problem it solves:**

Without caching, every CI run compiles all 500 TypeScript files from
scratch. With caching, only the 3 changed files are recompiled.
Build time drops from 3 minutes to 15 seconds.

**How it works:**

```
Three levels of caching:

1. File transformation cache (per file):
  webpack filesystem cache:
    Each module is cached by its content hash
    On rebuild: only changed modules are retransformed
    Cache stored in: .webpack-cache/ (configurable)

  esbuild cache (built-in):
    esbuild maintains its own transformation cache
    No configuration needed

2. Dependency pre-bundling cache (Vite):
  vite dev: pre-bundles node_modules to .vite/
  Invalidated when: package.json/lockfile changes
  Subsequent starts: skip pre-bundling step

3. Task output cache (Turborepo):
  Caches entire task outputs (dist/, coverage/)
  Key: hash of inputs (source files + env vars + config)
  Same inputs = same output = use cache
  Remote cache: share across machines (CI + local)

CI caching (GitHub Actions):
  - name: Cache webpack/Vite
    uses: actions/cache@v3
    with:
      path: |
        .webpack-cache
        node_modules/.vite
        .turbo
      key: build-cache-${{hashFiles('package-lock.json')}}
      restore-keys: build-cache-
```

**The key insight:**

Cache invalidation is the hard part. A cache key that's too broad
(just the lockfile hash) means config changes don't invalidate it,
producing stale builds. Too narrow (every file's hash) means no reuse.
The right granularity: hash of all files that could affect the output.

---

### 💻 Code Example

**Example 1: webpack filesystem cache configuration**

```javascript
// webpack.prod.js
module.exports = merge(base, {
  cache: {
    type: 'filesystem',
    cacheDirectory: path.resolve(__dirname, '.webpack-cache'),
    buildDependencies: {
      // Invalidate cache when these files change:
      config: [
        __filename,                          // webpack config
        path.resolve(__dirname, 'babel.config.js'),
        path.resolve(__dirname, 'tsconfig.json'),
        path.resolve(__dirname, 'postcss.config.js'),
      ],
    },
    // Cache name: different caches per environment
    name: `${process.env.NODE_ENV}-build`,
  },
});

// Measure cache effectiveness:
// First build:  Build time: 45.234s, cache: 0 hits
// Second build: Build time: 3.891s,  cache: 847 hits
// Touch one file:
// Third build:  Build time: 4.102s,  cache: 844 hits, 3 misses
```

```yaml
# GitHub Actions with layered caching
- name: Cache build artifacts
  uses: actions/cache@v3
  with:
    path: .webpack-cache
    # Invalidate when lock file changes (deps changed):
    key: webpack-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}-${{ hashFiles('webpack*.js') }}
    restore-keys: |
      # Fallback: use old cache (partial reuse, some misses)
      webpack-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}-
      webpack-${{ runner.os }}-

- name: Build
  run: npm run build
```

> **Code walkthrough:** The `buildDependencies.config` list is critical:
> it tells webpack which files could affect build output beyond the
> source files themselves. Missing the babel config means babel changes
> don't invalidate the cache - modules get compiled with the old babel
> config. The layered `restore-keys` in GitHub Actions means even
> when the exact key misses (lockfile changed), an older partial cache
> is restored, providing partial benefit.

**Example 2: Vite pre-bundling cache management**

```bash
# Vite caches pre-bundled dependencies in node_modules/.vite/
# (configurable via cacheDir in vite.config.ts)

# The cache is invalidated automatically when:
# - package.json or lockfile changes
# - vite.config.ts changes
# - Node.js version changes (esbuild binary changes)

# Manual cache clear when facing stale behavior:
npx vite --force  # skip cache, re-prebundle everything
# Or delete the cache directory:
rm -rf node_modules/.vite

# Configure cache location (for easier CI caching):
# vite.config.ts:
export default defineConfig({
  cacheDir: '.vite-cache',  // instead of node_modules/.vite
});

# CI: cache .vite-cache directory
- uses: actions/cache@v3
  with:
    path: .vite-cache
    key: vite-${{ hashFiles('**/package-lock.json') }}
```

> **Code walkthrough:** Vite's pre-bundling cache (`node_modules/.vite`)
> contains esbuild-compiled versions of all npm packages. This is why
> Vite dev startup is fast after the first run - packages are already
> compiled to ESM. Moving the cache to `.vite-cache` (not inside
> node_modules) makes it easier to cache in CI separately from
> node_modules.

---

### ⚖️ Comparison Table

| Cache level | Tool | What's cached | Scope |
|---|---|---|---|
| Module transforms | webpack filesystem | Individual file transforms | Local |
| Dep pre-bundling | Vite .vite/ | node_modules ESM conversion | Local |
| Task outputs | Turborepo | dist/, coverage/ (entire task output) | Local + Remote |
| node_modules | npm/GitHub Actions | Installed packages | CI (between runs) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> webpack filesystem cache saves transformed modules to disk. Next
> build: only changed files are re-transformed. In CI I cache the
> .webpack-cache directory with GitHub Actions cache. This reduces
> build time significantly.

**Senior / Staff:**

> Three caching layers: module-level (webpack filesystem or esbuild),
> task-level (Turborepo caches entire dist/ with remote sharing), and
> CI-level (GitHub Actions cache for node_modules and build artifacts).
> The key insight: cache keys must include all inputs that affect output
> - source files, config files, env vars. Missing any invalidation
> trigger produces stale builds that are harder to debug than no cache.

---

### ⚠️ Common Misconceptions

**Misconception 1: node_modules caching in CI is the same as build caching.**

node_modules caching speeds up `npm ci` (avoiding package download).
Build caching speeds up webpack/Vite compilation. Both are valuable;
they cache different things at different levels.

**Misconception 2: Filesystem cache always speeds up the first build.**

Filesystem cache only helps on the second and subsequent builds. The
first build is always a cache miss. Turborepo remote cache can give
a "warm" cache on first CI run if another developer has already built.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Stale build output after config change.**

Cause: Config file not in `buildDependencies.config` list.

Fix: Add all config files that affect build; delete `.webpack-cache`.

**Failure: CI cache always misses (no speedup).**

Cause: Cache key too specific (includes content that changes each run).

Fix: Use lockfile hash only; add `restore-keys` fallback for partial reuse.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is filesystem caching in webpack 5? | Definition | ★★☆ | 2 min |
| What invalidates the build cache? | Mechanism | ★★☆ | 2 min |
| How to cache builds in GitHub Actions? | Scenario | ★★☆ | 3 min |
| webpack filesystem cache vs Turborepo cache | Comparison | ★★☆ | 3 min |
| What are the risks of build caching? | Trade-off | ★★★ | 3 min |
| How to debug a stale cache issue? | Debugging | ★★☆ | 3 min |
| Remote caching - how does it work? | Mechanism | ★★★ | 3 min |

**Q: What are the risks of build caching and how do you mitigate them?**

A: The primary risk is stale cached output: the cache returns old results
when the inputs should have produced new output. This causes subtle bugs:
a config change not taking effect, a dependency update not visible.

Mitigation strategies:

Comprehensive cache keys: include all files that can affect output -
not just source files but also config files (webpack.config.js,
babel.config.js, tsconfig.json), env vars, and the node version
(esbuild binary is version-specific).

Cache name per environment: `name: ${NODE_ENV}-build` in webpack
means dev and prod caches are separate. A dev build doesn't pollute
the prod cache.

Versioned cache keys in CI: `webpack-${{ runner.os }}-v2-...` - bump
v2 to v3 to force full cache invalidation when you know the cache
is wrong.

Monitoring: compare build output checksums between cached and non-
cached runs periodically. Run `--no-cache` builds in CI weekly as
a correctness check.

Delete and rebuild policy: when investigating a bug that "appeared
from nowhere," delete the local cache first (`rm -rf .webpack-cache`)
and rebuild from scratch. Many mystery bugs are stale caches.

*What separates good from great:* Understanding that caching is a
trade-off between build speed and correctness. The safest approach
is no caching (always correct); the fastest is maximum caching (risk
of staleness). Production builds should err toward correctness (more
conservative cache invalidation); developer builds can be more
aggressive for speed.
