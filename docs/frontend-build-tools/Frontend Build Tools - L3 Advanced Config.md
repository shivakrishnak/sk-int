---
layout: default
title: "Frontend Build Tools - L3 Advanced Config"
parent: "Frontend Build Tools"
nav_order: 7
permalink: /frontend-build-tools/l3-advanced-config/
---

# Advanced Webpack Configuration Patterns

---

### 🎯 Model Answer

**30 seconds:**

> Advanced webpack patterns: split config into dev/prod/base files
> with webpack-merge, use environment-based conditions in configs,
> configure module aliases for clean import paths, set up
> optimization.splitChunks for automatic vendor chunk splitting, and
> use cache (persistent build cache) for faster rebuilds. These
> patterns prevent config drift between environments and dramatically
> improve build times in CI.

**Blank Mind Recovery:**

**(1) Restate:** "Advanced webpack: split config by env, merge base,
aliases for imports, splitChunks for automatic splitting, persistent
cache for CI speed."

---

### 📘 Concept Explanation

**What it is:**

Advanced webpack configuration covers: multi-file config architecture
(base/dev/prod), automatic chunk splitting, resolve aliases, and build
caching - the patterns needed for production-grade webpack setups.

**The problem it solves:**

Single-file webpack configs become unmanageable. Dev and prod configs
diverge. Build times in CI are slow without caching. Import paths
become long and fragile (../../components/Button).

**How it works:**

```
Multi-file config with webpack-merge:
  webpack.base.js  <- shared config (entry, loaders, aliases)
  webpack.dev.js   <- devServer, fast source maps, HMR
  webpack.prod.js  <- MiniCssExtract, minification, contenthash

  // webpack.dev.js:
  const { merge } = require('webpack-merge');
  const base = require('./webpack.base.js');
  module.exports = merge(base, {
    mode: 'development',
    devtool: 'eval-source-map',
    devServer: { port: 3000, hot: true },
  });

Resolve aliases:
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
      '@components': path.resolve(__dirname, 'src/components'),
      '@utils': path.resolve(__dirname, 'src/utils'),
    },
  }
  // Usage: import { Button } from '@components/Button';

Automatic chunk splitting (optimization.splitChunks):
  optimization: {
    splitChunks: {
      chunks: 'all',
      cacheGroups: {
        vendor: {
          test: /[\\/]node_modules[\\/]/,
          name: 'vendors',
          priority: 20,
        },
        common: {
          name: 'common',
          minChunks: 2,        // used in 2+ places
          priority: 10,
          reuseExistingChunk: true,
        },
      },
    },
  },

Persistent cache (webpack 5+):
  cache: {
    type: 'filesystem',       // cache to disk
    cacheDirectory: path.resolve(__dirname, '.webpack-cache'),
    // Second build uses cache: 90%+ time savings
  }
```

**The key insight:**

`splitChunks.chunks: 'all'` applies splitting to both dynamic and
non-dynamic imports. Without explicit manualChunks, webpack uses
heuristics (minSize, maxSize, minChunks) to automatically split.
This is usually good enough for apps; manualChunks gives control
when the heuristics produce suboptimal results.

---

### 💻 Code Example

**Example 1: webpack-merge multi-environment config**

```javascript
// webpack.base.js - shared between dev and prod
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  entry: { app: './src/index.tsx' },
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
    alias: {
      '@': path.resolve(__dirname, 'src'),
      '@components': path.resolve(__dirname, 'src/components'),
    },
  },
  module: {
    rules: [
      {
        test: /\.[jt]sx?$/,
        use: 'babel-loader',
        exclude: /node_modules/,
      },
      {
        test: /\.(png|jpg|svg)$/,
        type: 'asset',
        parser: { dataUrlCondition: { maxSize: 4 * 1024 } },
        // < 4KB: inline; >= 4KB: asset/resource
      },
    ],
  },
  plugins: [
    new HtmlWebpackPlugin({ template: './public/index.html' }),
  ],
};

// webpack.prod.js
const { merge } = require('webpack-merge');
const base = require('./webpack.base.js');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');

module.exports = merge(base, {
  mode: 'production',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].[contenthash].js',
    clean: true,
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader'],
      },
    ],
  },
  optimization: {
    splitChunks: { chunks: 'all' },
    minimizer: [new TerserPlugin(), new CssMinimizerPlugin()],
  },
  plugins: [
    new MiniCssExtractPlugin({ filename: '[name].[contenthash].css'}),
  ],
  cache: { type: 'filesystem' },
});
```

> **Code walkthrough:** The base config holds everything shared: entry,
> resolve aliases (making `@` an import shortcut), file type loaders,
> and HTML plugin. The prod config uses `merge()` to extend the base
> with production-specific additions: contenthash for caching, CSS
> extraction, minification, and splitChunks. The `asset` type with
> `dataUrlCondition` automatically inlines small assets and copies large
> ones - a cleaner API than the old url-loader/file-loader combination.

**Example 2: Build cache for CI**

```javascript
// webpack.prod.js - add filesystem caching for CI
module.exports = merge(base, {
  cache: {
    type: 'filesystem',
    cacheDirectory: path.resolve(__dirname, '.webpack-cache'),
    buildDependencies: {
      // Invalidate cache when config files change:
      config: [
        __filename,               // this config file
        path.resolve(__dirname, 'babel.config.js'),
        path.resolve(__dirname, 'tsconfig.json'),
      ],
    },
  },
});
```

```yaml
# .github/workflows/build.yml - cache webpack build cache in CI
- name: Cache webpack
  uses: actions/cache@v3
  with:
    path: .webpack-cache
    # Invalidate on lockfile change (deps changed):
    key: webpack-${{ runner.os }}-${{ hashFiles('package-lock.json') }}
    restore-keys: |
      webpack-${{ runner.os }}-

- name: Build
  run: npm run build
  # First run: full build (30s)
  # Subsequent runs with unchanged deps: 5-10s (from cache)
```

> **Code walkthrough:** Filesystem caching persists webpack's module
> graph and transformed module results between runs. The first CI build
> creates the cache; subsequent builds with no changes to dependencies
> or config files use the cache. `buildDependencies.config` lists files
> that should invalidate the cache when changed - crucial for correctness.
> The GitHub Actions cache action saves and restores the `.webpack-cache`
> directory between workflow runs.

---

### ⚖️ Comparison Table

| Config approach | Scale | Maintainability | Flexibility |
|---|---|---|---|
| Single webpack.config.js | Small | OK for simple | Low |
| webpack-merge base/dev/prod | Medium-Large | High | High |
| webpack function config | Medium | Good | High |
| Multiple configs (--config) | MPA / multiple apps | High | Very high |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I split webpack config into base, dev, and prod files using
> webpack-merge. The base has shared loaders and plugins; dev adds
> devServer; prod adds minification and CSS extraction.

**Senior / Staff:**

> webpack-merge with base/dev/prod plus filesystem caching for CI is
> the standard pattern. I also configure resolve.alias for clean
> import paths and splitChunks for automatic vendor extraction.
> For large monorepos, I add Module Federation to share runtime
> dependencies between micro-frontends. The biggest CI win: filesystem
> caching + GitHub Actions cache reduces rebuild time from 2 minutes
> to 15 seconds on code-only changes.

---

### ⚠️ Common Misconceptions

**Misconception 1: webpack-merge does a deep merge of all options.**

webpack-merge has smart merging: arrays (plugins, rules) are
concatenated; objects are merged. But nested config like
`output.filename` is overridden, not merged. Check the webpack-merge
docs for edge cases.

**Misconception 2: Filesystem cache is always safe to use.**

Cache must be invalidated when build configuration changes. Missing
a config file from `buildDependencies.config` means stale cached
output when the config changes. The safest option: include all config
files that affect the build.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Stale build output after config change.**

Cause: Filesystem cache not invalidated; config file not in
`buildDependencies.config`.

Fix: Add the changed config file to `buildDependencies.config`;
or delete `.webpack-cache` manually.

**Failure: merge() doesn't apply all options.**

Cause: webpack-merge only merges keys that are defined in the merged
config. Missing `output.path` in base means it must be in every env config.

Fix: Move all shared output options to base.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How do you structure webpack config for multiple environments? | Design | ★★☆ | 3 min |
| What is webpack-merge? | Definition | ★★☆ | 1 min |
| What is resolve.alias? | Definition | ★★☆ | 1 min |
| How does splitChunks work automatically? | Mechanism | ★★☆ | 3 min |
| How to speed up webpack in CI? | Scenario | ★★☆ | 3 min |
| What does cache.type:filesystem do? | Mechanism | ★★☆ | 2 min |
| How to invalidate the filesystem cache correctly? | Mechanism | ★★★ | 3 min |

**Q: How does webpack's splitChunks work automatically?**

A: `splitChunks.chunks: 'all'` enables webpack's automatic chunk
splitting algorithm. webpack analyzes the module graph and applies
heuristics:

`minSize` (default 20KB): don't create chunks smaller than this.
`maxSize`: try to split chunks larger than this.
`minChunks`: minimum number of chunks that must share a module before
it's extracted.
`cacheGroups`: named groups with custom criteria and priorities.

The default cacheGroups split vendors (node_modules) into a separate
chunk and create a common chunk for modules shared between entry points.

The algorithm: webpack walks the module graph and for each module
checks whether it matches any cacheGroup test. If it does, it's
grouped into that chunk. Modules used in 2+ chunks but not in
node_modules go into the `common` chunk.

Practical: the default configuration handles 80% of cases. For large
apps, explicit `manualChunks` gives more control: separate React,
charting libraries, admin sections.

*What separates good from great:* Understanding chunk overlap cost.
Putting too many modules in `common` increases the common chunk size,
which is downloaded even by users who never need those modules. The
optimal split: modules used by >50% of routes go in common; modules
used by <50% stay in their route chunks.

---

# Workspaces and Monorepo Package Management

---

### 🎯 Model Answer

**30 seconds:**

> Monorepo package management allows multiple packages in one git
> repository with shared dependencies. npm/yarn/pnpm workspaces hoist
> shared packages to the root node_modules. Turborepo and Nx add
> task orchestration: run builds in parallel, cache task outputs,
> and only rebuild packages affected by a change. The key benefit:
> a change in a shared component library only rebuilds the packages
> that depend on it.

**Blank Mind Recovery:**

**(1) Restate:** "Monorepo: multiple packages, one repo. Workspaces
hoist shared deps. Turborepo/Nx cache and parallelize tasks."

---

### 📘 Concept Explanation

**What it is:**

Monorepo tools allow multiple packages (applications, libraries,
utilities) in a single git repository, with shared configuration
and dependencies, task orchestration, and incremental builds.

**The problem it solves:**

Multi-repo setups require publishing and versioning every shared
package change before consuming it. Monorepos allow in-repo imports
(no publishing required), shared tooling, and atomic commits
(UI component + app changes in one PR).

**How it works:**

```
Workspace structure:
  my-monorepo/
    package.json           <- workspace root
    turbo.json             <- Turborepo config
    packages/
      ui/                  <- shared component library
        package.json (name: "@myapp/ui")
        src/
      shared-utils/
        package.json (name: "@myapp/shared-utils")
        src/
    apps/
      web/                 <- React app
        package.json (depends on @myapp/ui)
      admin/               <- Admin app
        package.json (depends on @myapp/ui)

Root package.json (npm workspaces):
  {
    "name": "my-monorepo",
    "workspaces": ["packages/*", "apps/*"]
  }

pnpm workspace (pnpm-workspace.yaml):
  packages:
    - 'packages/*'
    - 'apps/*'

Workspace protocol (pnpm):
  # apps/web/package.json:
  { "dependencies": { "@myapp/ui": "workspace:*" } }
  # workspace:* = always use local version (no publish needed)

Turborepo task pipeline (turbo.json):
  {
    "pipeline": {
      "build": {
        "dependsOn": ["^build"],  // build deps first
        "outputs": ["dist/**"],   // cache these outputs
      },
      "test": {
        "dependsOn": ["build"],
        "outputs": ["coverage/**"],
      },
      "lint": { "outputs": [] },
    }
  }
  # turbo run build --filter=web
  # Only builds web and its changed transitive deps
```

**The key insight:**

Turborepo's content-hash caching means: if packages/ui source hasn't
changed since the last build, `turbo run build` skips rebuilding ui
and uses the cached output. Combined with remote caching (sharing
cache between CI runs and developers), most CI runs skip most work.

---

### 💻 Code Example

**Example 1: pnpm workspace setup**

```yaml
# pnpm-workspace.yaml (root)
packages:
  - 'packages/*'
  - 'apps/*'
```

```json
// packages/ui/package.json
{
  "name": "@myapp/ui",
  "version": "0.0.1",
  "main": "./src/index.ts",
  "exports": {
    ".": {
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts",
      "default": "./src/index.ts"
    }
  },
  "scripts": {
    "build": "vite build",
    "dev": "vite build --watch"
  }
}
```

```json
// apps/web/package.json
{
  "name": "web",
  "dependencies": {
    "@myapp/ui": "workspace:*",
    "react": "^18.2.0"
  }
}
```

```bash
# Install all packages from root:
pnpm install

# Run command in specific workspace:
pnpm --filter web dev
pnpm --filter @myapp/ui build

# Run command in all workspaces:
pnpm -r build

# Turborepo: build with caching and parallelism:
npx turbo run build
# - Builds ui (no cache - first run)
# - Builds web (depends on ui; waits for ui)
# Second run (no changes):
# - ui: cache hit - skipped
# - web: cache hit - skipped
# Total: ~100ms instead of ~30s
```

> **Code walkthrough:** pnpm workspaces with `workspace:*` creates
> an internal dependency that resolves to the local package version.
> No publishing required - changes in `@myapp/ui` are immediately
> available to `web`. The `exports` field in ui's package.json supports
> both ESM and CJS consumers, plus TypeScript types. The `"default":
> "./src/index.ts"` path means IDE imports resolve to source for
> development experience (Go to Definition shows source, not dist).

**Example 2: Turborepo with remote caching**

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "globalEnv": ["NODE_ENV"],
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"],
      "env": ["VITE_API_URL"],  // cache key includes this var
    },
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**"],
      "cache": true,
    },
    "lint": {
      "outputs": [],
      "cache": false,   // linting: always run
    },
    "dev": {
      "cache": false,   // dev server: never cache
      "persistent": true,
    }
  }
}
```

```bash
# Remote caching setup (Vercel Remote Cache):
npx turbo login
npx turbo link  # links to team's remote cache

# Now CI and local machines share cache:
# Developer builds on laptop -> cached
# CI runs same build -> cache hit from laptop's output!
# Team members share each other's build outputs

# Affected-only builds:
npx turbo run build --filter=...[HEAD^1]
# Only build packages changed since last commit
# and their dependents
```

> **Code walkthrough:** The `dependsOn: ["^build"]` pattern means
> "build all dependencies first" (`^` = dependencies). Turborepo
> analyzes the dependency graph and runs builds in parallel where
> possible. Remote caching via Vercel (or self-hosted with Turborepo
> API) means CI can reuse build outputs from developer machines and
> previous CI runs. The `env` field in pipeline tasks includes env
> var values in the cache key - same code with different API URLs
> produces different cached outputs.

---

### ⚖️ Comparison Table

| Tool | Focus | Language | Remote cache |
|---|---|---|---|
| npm workspaces | Package management | Any | No |
| pnpm workspaces | Package management + strict | Any | No |
| Turborepo | Task orchestration + caching | Any | Yes (Vercel) |
| Nx | Full toolkit (generators, CI) | JS/TS focus | Yes (Nx Cloud) |
| Lerna | Package versioning + publishing | Any | Via Nx |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Workspaces let multiple packages in one repo share dependencies.
> I can import from a local package with `workspace:*`. Turborepo
> adds caching: if the package source hasn't changed, the build is
> skipped and cached output is used.

**Senior / Staff:**

> For monorepos I use pnpm workspaces (strict resolution, disk efficient)
> + Turborepo (caching, affected-only builds). Remote caching dramatically
> reduces CI time: most PRs only touch 1-2 packages; Turborepo detects
> what's affected and skips everything else. The `dependsOn: ["^build"]`
> pattern ensures correct build order. For large teams, Nx is worth
> considering for its scaffolding and project graph visualization.

---

### ⚠️ Common Misconceptions

**Misconception 1: Monorepos require complex tooling.**

A basic monorepo with npm workspaces has minimal setup: add `workspaces`
to root package.json. Turborepo is optional but highly recommended for
caching. You don't need Nx unless you want the full DX platform.

**Misconception 2: Remote cache stores source code.**

Turborepo remote cache stores build outputs (dist/, coverage/).
Never source code. The cache key is a hash of inputs (source content,
env vars, dependencies). Source stays in git.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Workspace package change not reflected in consumer.**

Cause: Consumer bundles dist/ (not src/), and dist/ is stale.

Fix: Run `turbo run build --filter=@myapp/ui` first; or set up
`dev` task with `--watch` for live rebuild.

**Failure: TypeScript can't find types for workspace package.**

Fix: Add `"types": "./src/index.ts"` in the package's package.json
exports; ensure paths in tsconfig.json point to the source package.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What are npm/pnpm workspaces? | Definition | ★★☆ | 2 min |
| How does Turborepo caching work? | Mechanism | ★★☆ | 3 min |
| workspace:* protocol - what is it? | Mechanism | ★★☆ | 1 min |
| Turborepo vs Nx - when to choose each? | Comparison | ★★★ | 3 min |
| How does affected-only building work? | Mechanism | ★★★ | 3 min |
| Why use monorepo over multi-repo? | Trade-off | ★★★ | 3 min |
| How to set up remote caching? | Scenario | ★★★ | 3 min |

**Q: Monorepo vs multi-repo - when does each work?**

A: Monorepo advantages: atomic changes (UI + app in one commit),
shared tooling, in-repo dependencies without publishing, easier
cross-package refactoring, unified CI pipeline.

Multi-repo advantages: team isolation (different deploy cadences,
access controls), smaller repo sizes, independent versioning, simpler
CI per repo.

Choose monorepo when: tight coupling between packages (shared design
system + apps using it), teams collaborate heavily, you want unified
tooling, and you're willing to invest in monorepo tooling (Turborepo).

Choose multi-repo when: teams are largely independent, packages have
separate ownership, versioning independence matters, or the monorepo
tooling overhead isn't justified.

The practical reality: most mid-size to large tech companies use
monorepos (Google, Meta, Shopify). The tooling (Turborepo, Nx) has
matured significantly. The main ongoing cost is managing a larger
git history and coordinating across teams on breaking changes.

*What separates good from great:* Understanding constraint propagation
in monorepos. A breaking change in a shared utility breaks all consumers
simultaneously - this forces better API design and communication.
In multi-repo, breaking changes can be silently "shipped" to a separate
version that consumers don't upgrade. Monorepos make technical debt
visible and immediate.
