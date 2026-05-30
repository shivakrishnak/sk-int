---
layout: default
title: "Frontend Testing - L2 Vitest"
parent: "Frontend Testing"
nav_order: 6
permalink: /frontend-testing/l2-vitest/
render_with_liquid: false
---

# Vitest and Vite-native Testing

---

### 🎯 Model Answer

**30 seconds:**

> Vitest is a Vite-native test runner that reuses the same Vite config
> as the project, supports native ESM, and is significantly faster than
> Jest for Vite projects. API is Jest-compatible (describe, test, vi
> instead of jest). Key advantages: HMR-enabled watch mode (only re-runs
> tests affected by changed files), native TypeScript support without
> ts-jest, component testing with `@vitest/browser`. For projects not
> using Vite, Jest remains a strong default.

**3 minutes:**

The core difference between Jest and Vitest is how they handle
modules:

**Jest** transforms code using Babel or ts-jest before running tests.
This transformation adds overhead per test file and requires config
for ESM packages (Jest defaults to CommonJS).

**Vitest** uses Vite's module graph. When a test file imports modules,
Vitest resolves them through Vite's pipeline (same as the build).
Native ESM, TypeScript, path aliases, and environment variables work
identically in tests and production - no separate transformation config.

**HMR in watch mode**: Vitest tracks which files changed and which
test files import those files. Only affected tests re-run. A change
to `utils/date.ts` re-runs tests that import it, not all 2,000 tests.

**`vi` global**: Vitest uses `vi` instead of `jest` for mocking:
`vi.mock()`, `vi.fn()`, `vi.spyOn()`, `vi.useFakeTimers()`. API is
nearly identical to Jest's.

**Blank Mind Recovery:**

**(1) When to use Vitest:** "Vite project: always. Non-Vite: prefer
Jest unless speed is a pain point."

**(2) Key difference:** "Vitest uses Vite module pipeline. Native ESM,
TypeScript, aliases without extra config."

**(3) API:** "vi.fn(), vi.mock(), vi.spyOn(). Same as jest.fn(),
jest.mock(), jest.spyOn(). Drop-in replacement."

---

### 📘 Concept Explanation

**What it is:**

A Vite-native test framework with Jest-compatible API that runs tests
using Vite's module resolution and transformation pipeline.

**The problem it solves:**

Jest + Vite projects require duplicate configuration: Vite handles
the build with native ESM and TypeScript; Jest needs Babel/ts-jest
transformation. Vitest uses the same config for both, eliminating
this duplication.

**How it works:**

```
Module resolution comparison:

  Jest:
    import { format } from './utils'
    1. babel-jest transforms utils.ts -> CommonJS
    2. Jest module registry runs transformed code
    3. ESM packages need special handling
       (esModuleInterop, transformIgnorePatterns)

  Vitest:
    import { format } from './utils'
    1. Vite resolves via same pipeline as production build
    2. TypeScript, path aliases, env vars work identically
    3. Native ESM - no transformation needed

  vitest.config.ts (minimal for Vite project):
    import { defineConfig } from 'vitest/config';
    export default defineConfig({
      test: {
        environment: 'jsdom', // or 'happy-dom'
        globals: true,        // describe/test/expect without import
        setupFiles: ['./src/test-setup.ts'],
      },
    });

  Or extend existing vite.config.ts:
    import { defineConfig, mergeConfig } from 'vite';
    import viteConfig from './vite.config';

    export default mergeConfig(viteConfig, defineConfig({
      test: {
        environment: 'jsdom',
        globals: true,
      },
    }));

  Key vitest features:
    Workspaces: run tests for multiple packages in monorepo
    Browser mode: run tests in real browser (Chromium via Playwright)
    TypeScript: first-class without ts-vitest or separate config
    Coverage: v8 or istanbul providers (@vitest/coverage-v8)
    Snapshot testing: toMatchSnapshot(), toMatchInlineSnapshot()
    Concurrent tests: test.concurrent() for parallel execution
```

---

### 💻 Code Example

**Example (Wrong vs Right) - Vitest vs Jest config for Vite project:**

```typescript
// BAD: Jest config for Vite project (extensive extra config needed)
// jest.config.cjs
module.exports = {
  transform: {
    '^.+\\.tsx?$': ['ts-jest', {
      tsconfig: { jsx: 'react-jsx' }
    }],
  },
  // Must explicitly list ESM packages for transformation:
  transformIgnorePatterns: [
    '/node_modules/(?!(some-esm-package|another-esm-lib)/).*/'
  ],
  moduleNameMapper: {
    // Duplicate Vite path aliases:
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  testEnvironment: 'jsdom',
  // Additional setup for CSS modules, SVG imports, etc.
};
// This config DIVERGES from vite.config.ts over time

// GOOD: Vitest config (extends existing Vite config)
// vitest.config.ts
import { defineConfig, mergeConfig } from 'vitest/config';
import viteConfig from './vite.config';

export default mergeConfig(viteConfig, defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test-setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      exclude: ['src/generated/**', '**/*.stories.*'],
    },
  },
}));
// Path aliases, env vars, TypeScript - all from vite.config.ts
// No duplication

// Usage - identical to Jest API:
// src/utils/format.test.ts
import { describe, test, expect, vi, beforeEach } from 'vitest';
// Or with globals: true, no imports needed

import { formatCurrency } from './format';

describe('formatCurrency', () => {
  test('formats USD by default', () => {
    expect(formatCurrency(1234.5)).toBe('$1,234.50');
  });

  test('mocking with vi.fn():', () => {
    const mockFormatFn = vi.fn(() => 'mocked');
    expect(mockFormatFn(100)).toBe('mocked');
    expect(mockFormatFn).toHaveBeenCalledWith(100);
  });
});
```

> **Code walkthrough:** The Jest configuration for a Vite project
> requires duplicating all the module resolution config: TypeScript
> transform settings, path alias mappings, ESM package exclusions.
> This config drifts from `vite.config.ts` over time - an alias added
> to Vite works in production but not tests until it's also added to
> Jest. Vitest's `mergeConfig` approach absorbs the existing Vite
> config, so path aliases, environment variables, TypeScript settings,
> and module resolution are automatically consistent between builds
> and tests.

---

### ⚖️ Comparison Table

| Factor | Vitest | Jest |
|---|---|---|
| Native ESM | Yes | Requires config |
| Vite integration | First-class | Extra config |
| Watch mode speed | HMR-based (fast) | Re-runs all |
| API compatibility | Jest-compatible | Standard |
| Ecosystem | Growing | Mature |
| Non-Vite projects | Works | Natural fit |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Vitest is like Jest but designed for Vite projects. It uses the same
> config as Vite so TypeScript and path aliases work without extra setup.
> The API is almost identical: `vi.fn()` instead of `jest.fn()`,
> `vi.mock()` instead of `jest.mock()`.

**Senior / Staff:**

> The key value of Vitest is eliminating the "two configs" problem in
> Vite projects: Vite resolves modules one way, Jest resolves them
> differently, and keeping these in sync is ongoing maintenance. With
> Vitest, `mergeConfig(viteConfig, defineConfig({test: {...}}))` means
> tests run with the exact same module resolution as production. This
> catches import issues that Jest/Babel would silently transform away.
> For non-Vite projects (webpack, Rollup), Jest remains the better
> default.

---

### ⚠️ Common Misconceptions

**Misconception: Vitest is always faster than Jest.**

Vitest's HMR-based watch mode is significantly faster for incremental
runs. But for single full test suite runs (cold start), the difference
is smaller and depends on test count. The biggest wins are in watch
mode during development and for projects with many ESM dependencies
that Jest struggles to transform.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Component tests see a different environment than the app.**

Symptom: Component works in browser but fails in Vitest tests.

Cause: `environment` is set to `jsdom` or `happy-dom` but the
component uses browser APIs unavailable in those environments.

Fix: Use `@vitest/browser` mode with `browser: { provider: 'playwright', enabled: true }` for tests that need a real browser environment.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| Why would you choose Vitest over Jest? | Decision | ★★☆ | 2 min |
| How does Vitest watch mode work? | Mechanism | ★★☆ | 2 min |
| How is Vitest config related to Vite config? | Mechanism | ★★☆ | 2 min |
| `vi.fn()` vs `jest.fn()` - differences? | Comparison | ★☆☆ | 1 min |
| When would you keep Jest instead of switching to Vitest? | Decision | ★★☆ | 2 min |

**Q: We have a large Jest test suite in a Vite project. Should we
migrate to Vitest?**

A: Evaluate by the size of the pain, not the tool's features.

Arguments for migrating:
- ESM packages in node_modules are causing `transformIgnorePatterns`
  headaches
- Test configuration has diverged from `vite.config.ts`
- Watch mode is slow (full re-run instead of HMR-based)
- TypeScript errors appear differently in tests vs IDE

Arguments against:
- Migration cost: `jest.` -> `vi.`, config rewrite, timer mock API
  differences, possible snapshot regeneration
- Large test suite with extensive Jest-specific features
- Team not in active pain with current setup

Migration path (if proceeding):
1. Install Vitest, create `vitest.config.ts` with `mergeConfig`
2. Run both in parallel: `jest` for existing, `vitest` for new tests
3. Gradually migrate test files (mostly search-and-replace)
4. Remove Jest after full migration

*What separates good from great:* Recognizing that this is a
cost-benefit decision, not a technical superiority question. Vitest
is objectively better for Vite projects but migration has real cost.
The correct answer is "assess the pain first."

---

# Test Performance Optimization with Vitest

---

### 🎯 Model Answer

**30 seconds:**

> Vitest performance: watch mode uses HMR (runs only tests affected
> by changed files). Full suite: parallelism is built-in (workers per
> test file). Key knobs: `pool` (threads vs forks vs vmThreads),
> `singleThread` for debugging, `testTimeout` reduction,
> `isolate: false` for shared module state (faster but less isolation).
> `@vitest/coverage-v8` is faster than istanbul for coverage collection.

**Blank Mind Recovery:**

**(1) Watch mode:** "Only re-runs tests touching changed files. HMR."

**(2) Parallelism:** "Each file gets a worker thread by default. Pool
config: threads (default), forks, vmThreads."

**(3) Trade-off:** "isolate: false - faster but tests can share state.
Only safe if tests don't mutate module-level state."

---

### 📘 Concept Explanation

**What it is:**

Techniques for making Vitest test suites run faster by leveraging
parallelism, reducing unnecessary module reloading, and tuning worker
pool settings.

**How it works:**

```
Vitest execution model:

  By default: each test file gets a worker thread
  Worker threads have separate module registry (isolation)
  Module registry is re-created per test file by default

  Pool options:
    pool: 'threads'       // Worker threads (default, fastest)
    pool: 'forks'         // Child processes (slower, better isolation)
    pool: 'vmThreads'     // VM context threads (ESM compatible)

  Isolation control:
    isolate: true  (default)
      Fresh module registry per test file
      Slower: modules re-imported per file
      Safe: no state leaks between test files

    isolate: false
      Shared module registry across test files
      Faster: modules cached and reused
      Unsafe: module-level singletons persist between files
      Only use for pure utility tests without side effects

  Watch mode HMR:
    Vitest tracks import graph (which test imports which module)
    On change to src/utils/date.ts:
      Only re-runs tests that import date.ts (directly or transitively)
      Large test suites: 2000 tests -> ~20 tests re-run on change

  Coverage optimization:
    @vitest/coverage-v8  : V8 native coverage, fastest
    @vitest/coverage-istanbul: Slower, more accurate for edge cases
    Exclude generated code via coverage.exclude patterns
```

---

### 💻 Code Example

**Example (Production) - Optimized vitest.config.ts:**

```typescript
// vitest.config.ts - performance-optimized
import { defineConfig, mergeConfig } from 'vitest/config';
import viteConfig from './vite.config';

export default mergeConfig(viteConfig, defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test-setup.ts'],

    // Parallelism:
    pool: 'threads',        // default, use Worker threads
    poolOptions: {
      threads: {
        singleThread: false, // set true for debugging only
        // maxThreads: 4,    // limit if memory is a concern
        // minThreads: 1,
      },
    },

    // Isolation:
    isolate: true,          // default: fresh module registry per file
    // isolate: false,      // faster but only safe for pure utils

    // Timeouts:
    testTimeout: 5_000,     // default: 5s per test
    hookTimeout: 10_000,    // default: 10s per hook

    // Coverage:
    coverage: {
      provider: 'v8',       // faster than istanbul
      reportsDirectory: 'coverage',
      reporter: ['text', 'html'],
      include: ['src/**/*.{ts,tsx}'],
      exclude: [
        'src/generated/**',
        'src/**/*.stories.*',
        'src/**/*.d.ts',
        'src/**/index.ts',  // barrel exports
      ],
    },

    // Benchmarking:
    benchmark: {
      outputFile: 'bench-results.json',
    },
  },
}));

// package.json scripts:
// "test": "vitest run",           // single full run (CI)
// "test:watch": "vitest",         // HMR watch mode
// "test:coverage": "vitest run --coverage",
// "test:ui": "vitest --ui",       // browser-based test UI
```

> **Code walkthrough:** `pool: 'threads'` (the default) is the fastest
> option for most test suites - Worker threads share the V8 heap with
> the parent process and have lower startup overhead than forks. The
> `poolOptions.threads.singleThread: false` is the default that enables
> parallelism. Setting `singleThread: true` forces serial execution
> (useful for debugging intermittent failures). The `coverage.exclude`
> patterns prevent noise from generated files and barrel exports, which
> have no behavior to test. `provider: 'v8'` uses the Node.js built-in
> V8 coverage instrumentation, which adds minimal overhead compared to
> Istanbul's source code transformation approach.

---

### ⚖️ Comparison Table

| Strategy | Speed gain | Risk |
|---|---|---|
| `pool: 'threads'` (default) | High baseline | None |
| `isolate: false` | 2-5x faster | Module state leaks |
| Watch mode (HMR) | 10-100x vs full run | None |
| `@vitest/coverage-v8` | 30% vs istanbul | Slightly less accurate |
| Excluding generated code | 5-10% | None |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Vitest runs test files in parallel using worker threads by default.
> Watch mode is fast because it only re-runs tests affected by changed
> files. For coverage, I use `@vitest/coverage-v8` which is faster
> than the Istanbul alternative.

**Senior / Staff:**

> The biggest speed wins in Vitest come from the HMR-based watch mode
> in development - for a 2,000-test suite, a change to a utility
> function re-runs 20-30 tests instead of all 2,000. For CI full runs,
> the main levers are thread pool size (default is good), excluding
> unnecessary files from coverage collection, and using v8 coverage.
> `isolate: false` is a tempting optimization but should only be used
> for test files you're certain have no module-level side effects.

---

### ⚠️ Common Misconceptions

**Misconception: More parallel workers is always faster.**

Worker threads have startup cost and memory overhead. Beyond 4-8
workers, adding more can slow tests down due to memory pressure and
context switching. Vitest's default uses a heuristic based on CPU
count. Override only if profiling shows bottleneck.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Tests fail with `isolate: false` but pass with `isolate: true`.**

Cause: Module-level singleton state (e.g., a module-level Map or
Array) is shared between test files. One test file mutates the
singleton and another test file sees the mutated state.

Fix: Add `isolate: true` (default) OR refactor the module to not
use module-level mutable state (factory functions, reset methods).

Diagnose: Run with `--sequence.concurrent false` to serialize tests
and identify which file is contaminating state.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How does Vitest watch mode avoid full re-runs? | Mechanism | ★★☆ | 2 min |
| What does `isolate: false` do and when is it safe? | Trade-off | ★★☆ | 2 min |
| V8 vs Istanbul coverage - difference? | Comparison | ★★☆ | 2 min |
| `pool: threads` vs `pool: forks` | Comparison | ★★☆ | 2 min |

**Q: Our CI test run takes 8 minutes for 3,000 tests. What would
you investigate to reduce it?**

A: Profile first, then optimize by biggest lever.

1. **Check parallelism**: Is `pool: 'threads'` in use? (default)
   Are workers limited by the CI container CPU count?

2. **Identify slow test files**: `vitest run --reporter=verbose` or
   the Vitest UI shows per-file timing. A single test file taking
   90 seconds is a bigger win than micro-optimizations.

3. **Coverage collection overhead**: Is `--coverage` running in CI?
   V8 coverage is faster than Istanbul - switch if on Istanbul.
   Is all of `node_modules` being scanned? Add proper excludes.

4. **E2E vs unit**: Are E2E tests mixed with unit tests in the same
   run? Separate them into different CI jobs that run in parallel.

5. **Isolation cost**: If many test files use `isolate: true` (default)
   and import large shared modules, the module re-import overhead
   adds up. Consider `isolate: false` for pure utility test files.

6. **Test infrastructure**: Is the CI container undersized?
   2 vCPUs for 3,000 parallel tests is a bottleneck.

*What separates good from great:* Splitting the test suite into
parallel CI jobs (fast unit tests + slow E2E tests running
simultaneously) is often a 10x win over any Vitest configuration
change.
