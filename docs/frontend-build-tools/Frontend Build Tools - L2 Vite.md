---
layout: default
title: "Frontend Build Tools - L2 Vite"
parent: "Frontend Build Tools"
nav_order: 4
permalink: /frontend-build-tools/l2-vite/
render_with_liquid: false
---

# Vite Development Server and ESM-native Dev

---

### 🎯 Model Answer

**30 seconds:**

> Vite's development server does not bundle. Instead, it serves source
> files as native ES modules directly to the browser. When you import
> a file, Vite transforms it on-demand (TypeScript to JS, JSX to JS)
> and serves it. Startup is instant (no full bundle needed) and HMR
> is module-level (only the changed file is re-transformed). The
> browser's native ESM support handles the module graph.

**Blank Mind Recovery:**

**(1) Restate:** "Vite dev: no bundling. Serve ES modules directly.
Transform on request. Browser handles imports. Fast startup, fast HMR."

---

### 📘 Concept Explanation

**What it is:**

Vite (French for "fast") is a build tool that uses native browser ES
modules for development (no bundling, instant start) and Rollup for
production builds (optimized, tree-shaken bundles).

**The problem it solves:**

Webpack bundles everything before starting the dev server. For large
apps this means 30s+ cold starts and slow HMR. Vite eliminates both:
no bundle to create on start, no bundle to update on change.

**How it works:**

```
Vite Development Architecture:
  Traditional bundler:
    start -> compile ALL files -> bundle -> serve

  Vite:
    start -> serve (no compilation!) -> ready in < 1s
    browser requests /src/App.tsx
      -> Vite transforms App.tsx on-demand -> serves JS
      -> browser resolves each import as a new request
    change -> only /src/App.tsx invalidated
      -> browser re-requests that ONE module
      -> HMR: < 50ms regardless of app size

Pre-bundling (esbuild, first start only):
  Converts node_modules to ESM
  Merges packages with many small files
  Cached in .vite/ directory
  Prevents hundreds of network requests for package internals

Production uses Rollup:
  vite build -> Rollup bundles -> optimized output
  Same pipeline as webpack: tree shaking, code splitting,
  asset fingerprinting, minification
```

**The key insight:**

Vite dev server work is proportional to what the browser requests,
not total app size. A 500-component app loading the homepage processes
only the homepage's modules.

**When to use it:**

New React, Vue, Svelte, or vanilla JS/TS projects. Vite is the default
for new frontend projects (Create React App deprecated in favor of Vite).

**Alternatives:**

- webpack: more plugins, better for legacy projects
- Parcel: zero-config
- Turbopack: webpack's Rust successor (Next.js --turbo)

---

### 💻 Code Example

**Example 1: Vite config**

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [
    react(), // JSX transform + React Fast Refresh
  ],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
  build: {
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
        },
      },
    },
  },
  optimizeDeps: {
    // Pre-bundle these packages on first start (esbuild)
    include: ['react', 'react-dom', 'react-router-dom'],
  },
});
```

> **Code walkthrough:** `react()` plugin handles JSX and React Fast
> Refresh automatically. `optimizeDeps.include` pre-bundles packages
> at startup using esbuild - prevents hundreds of network requests
> for package internals. `manualChunks` in the build config splits
> vendor libraries for long-term caching in production.

**Example 2: Vite environment variables**

```javascript
// BAD: webpack-style process.env (undefined in Vite browser build)
const apiUrl = process.env.REACT_APP_API_URL;

// GOOD: Vite uses import.meta.env
const apiUrl = import.meta.env.VITE_API_URL;

// .env file (Vite reads these automatically):
// VITE_API_URL=https://api.example.com
// Variables MUST be prefixed with VITE_ to be exposed

// Build-time booleans:
const isProd = import.meta.env.PROD;  // true in prod build
const isDev = import.meta.env.DEV;    // true in dev server
const mode = import.meta.env.MODE;    // 'development' | 'production'

// Performance comparison (real-world ~300 components):
// webpack start: 28 seconds
// Vite start:    0.6 seconds
// webpack HMR:   4 seconds
// Vite HMR:      12 milliseconds
```

> **Code walkthrough:** The most common Vite migration gotcha is the
> environment variable system. `process.env` is Node.js - browsers
> don't have it. Vite replaces `import.meta.env.VITE_*` at build time
> (like webpack's DefinePlugin). Variables without `VITE_` prefix are
> excluded for security (prevents accidentally exposing secrets).

---

### ⚖️ Comparison Table

| Feature | webpack dev | Vite dev | Vite prod |
|---|---|---|---|
| Cold start | 10-60s | < 1s | N/A |
| HMR speed | 1-5s | < 50ms | N/A |
| Bundling in dev | Yes | No | Yes (Rollup) |
| Config complexity | High | Low | Low |
| Env variables | `process.env` | `import.meta.env` | Same |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Vite is faster than webpack because it doesn't bundle in development.
> It serves ES modules directly and transforms files when requested.
> Startup is nearly instant and HMR is very fast.

**Senior / Staff:**

> Vite dev: native ESM + esbuild transforms on demand. Production:
> Rollup with the same optimizations as webpack. The key insight: work
> proportional to browser requests, not app size. Migration from webpack:
> replace `process.env` with `import.meta.env`, replace webpack plugins
> with Vite equivalents, pre-bundle problematic CommonJS packages in
> `optimizeDeps`.

---

### ⚠️ Common Misconceptions

**Misconception 1: Vite production build uses native ESM.**

Vite production uses Rollup for bundling. Native ESM is dev-only.

**Misconception 2: `process.env.VITE_*` works in Vite.**

Vite uses `import.meta.env.VITE_*`. `process.env` is Node.js only.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Environment variable undefined in Vite.**

Cause: Using `process.env.X` (webpack) or missing `VITE_` prefix.

Fix: Use `import.meta.env.VITE_X`; prefix with `VITE_` in `.env`.

**Failure: CJS package fails ("require is not defined").**

Fix: Add to `optimizeDeps.include` in vite.config.ts.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How does Vite dev server differ from webpack? | Comparison | ★★☆ | 3 min |
| Why is Vite's HMR faster? | Mechanism | ★★☆ | 2 min |
| What is Vite's production build based on? | Definition | ★★☆ | 1 min |
| What is pre-bundling? | Mechanism | ★★☆ | 2 min |
| Vite env variables vs webpack | Comparison | ★★☆ | 2 min |
| When would you choose webpack over Vite? | Decision | ★★☆ | 3 min |
| How to migrate from webpack to Vite? | Scenario | ★★★ | 4 min |

**Q: When would you choose webpack over Vite?**

A: Vite is the right choice for most new projects. Choose webpack when:

Complex legacy config: deep webpack plugin customization (custom
loaders, Module Federation config, coverage integrations) that would
require significant rewrite to migrate.

Specific plugins without Vite equivalents: Module Federation is a
notable one - the Vite version is less mature.

Constrained Node.js versions: Vite requires Node.js 18+.

CommonJS-heavy ecosystem: many CJS-only packages can cause issues.
`optimizeDeps` handles most cases, but edge cases exist.

The honest answer: if starting fresh, Vite is almost always right.
The DX difference is substantial. webpack choice is usually about
migration cost.

*What separates good from great:* Turbopack context. webpack's Rust
successor (in Next.js `--turbo`) targets the same problem. Unlike Vite
(Rollup for prod), Turbopack uses the same engine for dev and prod,
potentially eliminating dev/prod parity issues.

---

# Vite Build Configuration and Rollup Integration

---

### 🎯 Model Answer

**30 seconds:**

> Vite's production build uses Rollup under the hood. Configure it
> via `build.rollupOptions` in vite.config.ts. Key options: output
> (chunk filenames, manualChunks for splitting), and external (don't
> bundle these - for library builds). In library mode, use `build.lib`
> with external peer deps (React) to prevent duplicate instances.

**Blank Mind Recovery:**

**(1) Restate:** "Vite production = Rollup. build.rollupOptions.
Library mode: build.lib + external peer deps."

---

### 📘 Concept Explanation

**What it is:**

Vite's production build wraps Rollup's API. `build.rollupOptions`
passes directly to Rollup. Vite adds esbuild transforms, asset
processing, and CSS extraction.

**How it works:**

```
Vite Build Pipeline (production):
  esbuild: TypeScript + JSX -> JS (fast)
  Rollup: module bundling + tree shaking + code splitting
  Asset processing: CSS extract, fingerprint images/fonts
  Output: dist/ with hashed filenames

Key build.rollupOptions:
  output.manualChunks:  control chunk membership
  output.chunkFileNames: pattern for chunk filenames
  external:            don't bundle (library mode)
  input:               multiple entry points (MPA)

Library mode:
  build.lib:
    entry:   './src/index.ts'
    name:    'MyLib'      (UMD global)
    formats: ['es', 'cjs']

  rollupOptions:
    external: ['react', 'react-dom']
    output.preserveModules: true  (one file per source module)
```

**The key insight:**

Library builds must externalize peer dependencies. Bundling React
inside a library causes consumers to get two React instances,
breaking hooks with "invalid hook call" errors.

---

### 💻 Code Example

**Example 1: Library build config**

```typescript
// vite.config.ts for a component library
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';
import dts from 'vite-plugin-dts';

export default defineConfig({
  plugins: [
    react(),
    dts({
      insertTypesEntry: true,
      rollupTypes: true, // bundle all .d.ts into one file
    }),
  ],
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      name: 'MyComponentLib',
      formats: ['es', 'cjs'],
      fileName: (fmt) => `index.${fmt === 'es' ? 'mjs' : 'cjs'}`,
    },
    rollupOptions: {
      // Externalize peer deps (consumers provide their own)
      external: ['react', 'react-dom', 'react/jsx-runtime'],
      output: {
        // One output file per source file = tree-shakeable
        preserveModules: true,
        preserveModulesRoot: 'src',
        globals: {
          react: 'React',
          'react-dom': 'ReactDOM',
        },
      },
    },
  },
});
```

> **Code walkthrough:** `external` excludes React from the bundle.
> `preserveModules: true` keeps directory structure in output instead
> of merging everything into one file - this enables consumers to
> tree-shake individual components. `vite-plugin-dts` generates
> TypeScript declaration files. The `globals` mapping is needed for
> UMD format output where externals become global variable names.

**Example 2: Advanced chunk splitting for apps**

```typescript
// Adaptive manualChunks function
build: {
  rollupOptions: {
    output: {
      manualChunks(id) {
        // React core: most stable, longest cache
        if (id.includes('node_modules/react')) {
          return 'react-vendor';
        }
        // Heavy chart lib: separate (loaded on demand)
        if (id.includes('node_modules/recharts') ||
            id.includes('node_modules/d3')) {
          return 'charts-vendor';
        }
        // All other node_modules
        if (id.includes('node_modules/')) {
          return 'vendor';
        }
        // Admin pages (route-level splitting)
        if (id.includes('/pages/admin/')) {
          return 'admin';
        }
        return undefined; // Rollup decides
      },
    },
  },
},
```

> **Code walkthrough:** React in its own chunk means consumers who
> haven't changed React dependencies keep a long-lived cached version.
> Heavy third-party libs (charts, PDF, editors) in separate chunks
> means users who never visit chart pages never download chart code.
> The function approach is more flexible than the object shorthand:
> it can use dynamic logic to assign modules to chunks.

---

### ⚖️ Comparison Table

| Build mode | Bundle React? | Output format | For |
|---|---|---|---|
| App mode | Yes | HTML + JS + CSS | Consumer-facing apps |
| Library mode | No (external) | ESM + CJS + types | npm packages |
| Library + UMD | No | ESM + CJS + UMD | CDN-loadable library |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Vite's production build uses Rollup. I configure chunk splitting via
> `build.rollupOptions.output.manualChunks`. For library builds, I use
> `build.lib` and mark React as external.

**Senior / Staff:**

> Vite wraps Rollup's API fully. For apps: `manualChunks` for vendor
> splitting, `cssCodeSplit` for per-route CSS. For libraries:
> `build.lib` + external peer deps + `preserveModules: true` for
> tree-shakeable per-file output. `vite-plugin-dts` generates type
> declarations. For MPA: `rollupOptions.input` with HTML entries.

---

### ⚠️ Common Misconceptions

**Misconception 1: Vite and Rollup configs are completely separate.**

Vite wraps Rollup. `build.rollupOptions` IS Rollup config. Most Rollup
plugins work in Vite directly.

**Misconception 2: Libraries should bundle all dependencies.**

Peer dependencies must be external. Bundling React causes duplicate
instance errors for consumers.

---

### 🚨 Failure Modes and Diagnosis

**Failure: "Invalid hook call" from consumer of component library.**

Cause: Library bundled its own React; two instances conflict.

Fix: Add `external: ['react', 'react-dom']` to library rollupOptions.

**Failure: Library consumers cannot tree-shake individual components.**

Fix: Add `preserveModules: true` + `preserveModulesRoot: 'src'`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What does Vite's production build use? | Definition | ★★☆ | 1 min |
| Library mode vs app mode | Comparison | ★★☆ | 2 min |
| Why externalize React in library builds? | Mechanism | ★★☆ | 2 min |
| How to split chunks in Vite? | Mechanism | ★★☆ | 3 min |
| How to generate TypeScript types in library builds? | Scenario | ★★☆ | 2 min |
| What is preserveModules? | Mechanism | ★★★ | 3 min |
| How to debug bundle size issues? | Debugging | ★★☆ | 2 min |

**Q: Explain preserveModules and when to use it.**

A: By default Rollup merges all modules into one output file.
`preserveModules: true` maintains the module structure: each source
file becomes a separate output file with the same directory layout.

When to use: component library publishing. `src/Button/index.tsx`
becomes `dist/Button/index.mjs`. Consumers import:
```javascript
import { Button } from 'my-lib/Button'; // only Button loaded
```
Tree shaking works at the file level. Without it, importing Button
loads all components in the merged bundle.

When NOT to use: applications (network efficiency favors fewer files).

The `package.json` `exports` field should match:
```json
{
  "exports": {
    ".": { "import": "./dist/index.mjs" },
    "./Button": { "import": "./dist/Button/index.mjs" }
  }
}
```

*What separates good from great:* `preserveModules` generates many
small files. Some bundlers (older webpack versions) struggle with
package `exports` pointing to many files. Test with your consumers'
bundlers. The `sideEffects: false` flag in `package.json` is also
required for consumers' bundlers to tree-shake aggressively.
