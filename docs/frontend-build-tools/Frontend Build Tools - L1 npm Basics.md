---
layout: default
title: "Frontend Build Tools - L1 npm Basics"
parent: "Frontend Build Tools"
nav_order: 2
permalink: /frontend-build-tools/l1-npm-basics/
render_with_liquid: false
---

# npm Package Management

---

### 🎯 Model Answer

**30 seconds:**

> npm (Node Package Manager) is the default package manager for the
> JavaScript ecosystem. It installs packages from the npm registry,
> manages project dependencies, and runs scripts defined in
> package.json. `npm install` downloads all dependencies to
> node_modules and writes a package-lock.json for reproducible installs.
> Key commands: `npm install <pkg>`, `npm install --save-dev <pkg>` for
> dev-only tools, `npm run <script>` to run package.json scripts.

**Blank Mind Recovery:**

**(1) Restate:** "npm - the package manager for JavaScript. Installs
dependencies, manages versions, runs scripts."

---

### 📘 Concept Explanation

**What it is:**

npm is the package registry and CLI tool for JavaScript. It provides:
package installation from the registry, local package caching,
script runner for build tasks, and version resolution for dependencies.

**The problem it solves:**

Before npm, sharing JavaScript code meant copying files manually.
npm provides: centralized registry of 2M+ packages, versioned installs,
automatic transitive dependency resolution, and reproducible installs
via lockfiles.

**How it works:**

```
npm install (what happens):
  1. Read package.json dependencies list
  2. Resolve versions: find versions satisfying semver ranges
  3. Fetch packages from registry (or cache)
  4. Write node_modules/ tree
  5. Write/update package-lock.json (exact versions)

Dependency types in package.json:
  "dependencies": {            // shipped to production
    "react": "^18.2.0"
  },
  "devDependencies": {         // build tools, testing only
    "vite": "^5.0.0",
    "typescript": "^5.3.0",
    "jest": "^29.0.0"
  },
  "peerDependencies": {        // expected from consumer (libs)
    "react": ">=17.0.0"
  }

Key commands:
  npm install              # install all deps from package.json
  npm install react        # add to dependencies
  npm install -D vite      # add to devDependencies
  npm install -g nodemon   # global install
  npm uninstall react      # remove
  npm update               # update within semver ranges
  npm ci                   # clean install from lockfile (CI use)
  npm run build            # run "build" script from package.json
  npm audit                # check for vulnerabilities
  npm audit fix            # auto-fix vulnerabilities
```

**The key insight:**

`npm install` uses the semver range in package.json but writes exact
versions to package-lock.json. `npm ci` installs from the lockfile
exactly - always use `npm ci` in CI/CD for reproducible builds.

**When to use it:**

Every Node.js and frontend project uses npm (or its alternative: yarn,
pnpm, bun).

**Alternatives:**

- yarn: faster, workspaces, stricter lockfile
- pnpm: content-addressable store, disk-space efficient, strict symlinks
- bun: all-in-one runtime + package manager (fastest installs)

---

### 💻 Code Example

**Example 1: Package.json scripts (the npm script runner)**

```json
{
  "name": "my-app",
  "version": "1.0.0",
  "scripts": {
    "dev":     "vite",
    "build":   "tsc && vite build",
    "preview": "vite preview",
    "test":    "jest",
    "test:watch": "jest --watch",
    "lint":    "eslint src --ext ts,tsx --max-warnings 0",
    "typecheck": "tsc --noEmit",
    "ci":      "npm run typecheck && npm run lint && npm test"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.0",
    "@vitejs/plugin-react": "^4.0.0",
    "typescript": "^5.3.0",
    "vite": "^5.0.0",
    "eslint": "^8.0.0",
    "jest": "^29.0.0"
  }
}
```

> **Code walkthrough:** The `scripts` section defines tasks runnable
> with `npm run <name>`. The `ci` script chains other scripts: type
> check, then lint, then test - all must pass. `devDependencies` lists
> tools needed only at build/test time; they are not installed in
> production Docker builds (use `npm ci --omit=dev`). The `^` prefix
> in versions allows minor and patch updates (`^18.2.0` accepts
> `18.2.x` and `18.x.x`).

**Example 2: npm vs npm ci**

```bash
# Development: install, updating lockfile if needed
npm install
# - Reads package.json ranges
# - Resolves latest compatible versions
# - Updates package-lock.json
# - Use during development when adding/upgrading packages

# CI/CD: clean install from lockfile
npm ci
# - Reads package-lock.json ONLY
# - Installs exact versions from lockfile
# - Deletes node_modules first (clean install)
# - FAILS if lockfile is out of sync with package.json
# - Use in CI for reproducible, deterministic builds

# BAD: using npm install in CI
# npm install  <- can install different versions if lockfile
#                is missing or ranges allow updates

# GOOD: npm ci in CI
# npm ci       <- identical to every other CI run
```

> **Code walkthrough:** The distinction between `npm install` and
> `npm ci` is critical in CI/CD. `npm install` can silently install
> different patch/minor versions if the lockfile is absent or if
> someone pushed a change to package.json without updating the lockfile.
> `npm ci` fails loudly if the lockfile is inconsistent - this is the
> safety net. Always use `npm ci` in CI pipelines and Docker builds.

---

### ⚖️ Comparison Table

| Command | When to use | Reads | Writes |
|---|---|---|---|
| `npm install` | Development: adding/updating | package.json | package-lock.json |
| `npm ci` | CI/CD: reproducible builds | package-lock.json | (nothing, deletes node_modules first) |
| `npm install -D` | Adding dev tools | - | package.json + lockfile |
| `npm audit` | Security check | package-lock.json | (nothing) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> npm installs JavaScript packages. `npm install <pkg>` adds to
> dependencies; `-D` adds to devDependencies (build tools, testing).
> `npm run <script>` runs commands defined in package.json. The
> package-lock.json records exact versions for reproducibility.

**Senior / Staff:**

> npm's key operational distinction: `npm install` resolves ranges and
> updates the lockfile; `npm ci` installs exact lockfile versions and
> fails if out of sync. I enforce `npm ci` in CI/CD. For large teams
> I recommend pnpm for disk efficiency and strict module resolution
> (prevents undeclared dependency access). `npm audit` in CI with
> `--audit-level=high` catches security issues before deploy.

---

### ⚠️ Common Misconceptions

**Misconception 1: devDependencies are not important in production.**

devDependencies ARE excluded from production Docker builds (`npm ci
--omit=dev`). But the audit vulnerability check applies to all
dependencies, including dev. A dev dependency with a known vuln should
still be fixed.

**Misconception 2: package-lock.json should be gitignored.**

Lockfiles should be committed. They ensure every developer and every
CI run gets identical dependency trees. Gitignoring the lockfile causes
hard-to-diagnose "works on my machine" bugs when dependency resolution
varies between environments.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Inconsistent behavior between dev and CI.**

Cause: `npm install` was used in CI; lockfile was out of sync.

Fix: Always use `npm ci` in CI. Check `git log package-lock.json`.

**Failure: Module not found in production Docker build.**

Cause: Package was added to devDependencies but is required at runtime.

Fix: Move to dependencies. Check with `npm ci --omit=dev` locally.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| dependencies vs devDependencies | Definition | ★☆☆ | 1 min |
| npm install vs npm ci | Comparison | ★★☆ | 2 min |
| What is package-lock.json for? | Mechanism | ★☆☆ | 1 min |
| How do npm scripts work? | Definition | ★☆☆ | 1 min |
| What is npm audit? | Security | ★★☆ | 2 min |
| npm vs yarn vs pnpm - differences? | Comparison | ★★☆ | 3 min |
| How would you secure npm dependencies in CI? | Scenario | ★★☆ | 3 min |

**Q: npm vs yarn vs pnpm - key differences?**

A: npm is the default, ships with Node.js. Yarn (classic) introduced
parallel installs, a faster lockfile format, and workspaces before npm
had them. Yarn Berry (v2+) introduced Plug'n'Play (no node_modules),
zero-installs (lockfile in git), and strict package hoisting control.

pnpm is the most distinctive: it uses a content-addressable store
where each version of a package is stored once globally on disk
(linked into node_modules via symlinks). This means 10 projects
sharing React 18 use one copy instead of 10. pnpm also enforces
strict access: you can only import packages you declared in
package.json (not hoisted transitive deps), catching hidden dependency
bugs that npm and yarn allow.

For teams: pnpm is increasingly recommended for monorepos (disk
efficient, strict) and large teams (catches undeclared deps). yarn is
fine for single repos. npm is adequate for small projects.

*What separates good from great:* pnpm's strict mode prevents a common
production bug: the "phantom dependency" - importing a package that is
not in your package.json but happens to be hoisted in node_modules from
a transitive dependency. It works in dev but breaks when the transitive
dep changes or is removed.

---

# package.json and Semantic Versioning

---

### 🎯 Model Answer

**30 seconds:**

> package.json is the manifest for a Node.js/JavaScript project:
> it declares the project name, version, dependencies with version
> ranges, and runnable scripts. Semantic versioning (semver) uses
> MAJOR.MINOR.PATCH: major = breaking changes, minor = new features
> (backward compatible), patch = bug fixes. In package.json, `^1.2.3`
> allows any compatible version (`1.x.x >= 1.2.3`); `~1.2.3` allows
> patch updates only (`1.2.x`).

**Blank Mind Recovery:**

**(1) Restate:** "Semver: MAJOR.MINOR.PATCH. Breaking change = major.
New feature = minor. Bug fix = patch. ^ means compatible; ~ means patches."

---

### 📘 Concept Explanation

**What it is:**

Semantic versioning is a convention for version numbers that
communicates the nature of changes. package.json uses semver ranges
to specify which versions of a dependency are acceptable.

**How it works:**

```
Semver: MAJOR.MINOR.PATCH-prerelease+build
  Example: 2.4.1-beta.1+20231201

MAJOR: Breaking change (API removed/changed)
  Users MUST update their code when upgrading
  1.x.x -> 2.x.x = potentially breaking

MINOR: New feature, backward compatible
  Existing code continues to work unchanged
  1.2.x -> 1.3.x = safe to update

PATCH: Bug fix, backward compatible
  No new features, no breaking changes
  1.2.3 -> 1.2.4 = safe to update

Version Ranges in package.json:
  "1.2.3"    exact version (rarely used - too rigid)
  "^1.2.3"   compatible: >=1.2.3 <2.0.0
             (most common for libraries)
  "~1.2.3"   approximate: >=1.2.3 <1.3.0
             (patch updates only - conservative)
  ">=1.0.0"  at least (open-ended)
  "*"        any version (dangerous)
  "latest"   whatever npm considers latest (dangerous)

Special cases:
  "^0.2.3"   -> >=0.2.3 <0.3.0 (0.x.x: minor is breaking!)
  "^0.0.3"   -> >=0.0.3 <0.0.4 (0.0.x: exact!)
  Pre-1.0 packages: minor versions may be breaking
```

**The key insight:**

The `^` operator in version 0.x.x behaves differently: for
`^0.2.3` it only allows patch updates (`0.2.x`), because pre-1.0
packages treat minor versions as potentially breaking. Many popular
packages were 0.x.x for years (webpack 0.x, many others).

**When to use it:**

Understand semver when: upgrading packages, deciding how to version
your own library, or debugging version conflicts.

---

### 💻 Code Example

**Example 1: Reading version ranges**

```json
{
  "dependencies": {
    "react": "^18.2.0",
    "lodash": "~4.17.21",
    "exact-pkg": "3.1.4",
    "open-range": ">=5.0.0",
    "react-router-dom": "^6.8.0"
  }
}
```

```bash
# What each range resolves to:
# react: ^18.2.0 -> any 18.x.x >= 18.2.0 (e.g., 18.3.1)
# lodash: ~4.17.21 -> any 4.17.x >= 4.17.21 (e.g., 4.17.22)
# exact-pkg: 3.1.4 -> exactly 3.1.4 (pinned)
# open-range: >=5.0.0 -> any 5.x.x, 6.x.x, ... (risky)
# react-router-dom: ^6.8.0 -> any 6.x.x >= 6.8.0

# Check what version would be resolved:
npm info react@"^18.2.0" version
# -> 18.3.1 (latest compatible at time of resolution)

# Check actual installed version:
npm list react
# my-app@1.0.0
# +-- react@18.3.1
```

> **Code walkthrough:** Version ranges determine what npm installs
> when there is no lockfile (or when using `npm install` with an
> outdated lockfile). The `^` range is widest - it allows all minor
> and patch updates within the major version. This is safe when
> library authors follow semver. The `~` range is conservative - only
> patches. Pinning exact versions (`3.1.4`) creates a rigid dependency
> that prevents even bug-fix updates - use the lockfile instead.

**Example 2: Semver in library publishing**

```json
{
  "name": "my-ui-lib",
  "version": "2.3.1",
  "peerDependencies": {
    "react": ">=16.8.0 <20.0.0"
  },
  "exports": {
    ".": {
      "import": "./dist/index.esm.js",
      "require": "./dist/index.cjs.js",
      "types": "./dist/index.d.ts"
    }
  }
}
```

```bash
# When to bump which version:
# patch: 2.3.1 -> 2.3.2
#   Bug fix, no API change, no behavior change for existing code

# minor: 2.3.1 -> 2.4.0
#   New optional prop, new exported function
#   Existing consumers unaffected

# major: 2.3.1 -> 3.0.0
#   Required prop added, existing prop removed
#   Renamed export, changed callback signature
#   Any change that breaks existing consumer code
```

> **Code walkthrough:** Library versioning requires discipline: every
> breaking change to the public API is a major bump. A common mistake
> is treating minor versions as breaking-change-allowed. This breaks
> consumers whose lockfile allows `^` ranges. The `peerDependencies`
> range shows another pattern: support a wide range of React versions
> without requiring consumers to upgrade. The `exports` field enables
> tree-shakeable ESM and CommonJS interop.

---

### ⚖️ Comparison Table

| Range | Allows | Conservative? | Use When |
|---|---|---|---|
| `^1.2.3` | `>=1.2.3 <2.0.0` | No | Most dependencies |
| `~1.2.3` | `>=1.2.3 <1.3.0` | Yes | Risky deps (historical bugs) |
| `1.2.3` | Exactly `1.2.3` | Most | Never (use lockfile instead) |
| `>=1.0.0` | Anything >= 1.0.0 | Never | Peer dep minimum |
| `*` | Any version | Never | Development only |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Semver: MAJOR.MINOR.PATCH. Breaking change = bump major. New feature
> = bump minor. Bug fix = bump patch. In package.json, `^1.2.3` allows
> any compatible version (1.x.x). `~1.2.3` allows only patch updates.

**Senior / Staff:**

> I enforce semver in library releases and use conventional commits +
> semantic-release to automate version bumping from commit messages.
> Key trap: `^0.x.x` treats minor as breaking (correct behavior for
> pre-1.0 packages). For apps I pin all transitive deps via lockfile
> (`npm ci`); for libraries I use `^` ranges and rely on consumers'
> lockfiles for reproducibility.

---

### ⚠️ Common Misconceptions

**Misconception 1: Pinning exact versions in package.json ensures reproducibility.**

Pinning only pins the direct dependency. Transitive dependencies still
resolve to latest compatible versions. The lockfile is what ensures full
reproducibility.

**Misconception 2: `^` is dangerous because it allows arbitrary upgrades.**

`^` only allows compatible versions (same major). The lockfile pins
the exact resolved version. `npm install` updates within the range and
refreshes the lockfile; `npm ci` uses the exact lockfile. Use `npm ci`
in production to get pinned behavior.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Package.json `^` range causes breaking upgrade.**

Cause: Library published a breaking change without bumping major version.

Fix: Pin to last known good version; create an issue in the library;
update when migration guide is published.

**Failure: `npm install` installs different version in CI.**

Cause: Lockfile not committed; or using `npm install` instead of `npm ci`.

Fix: Commit lockfile; replace `npm install` with `npm ci` in CI.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| Explain MAJOR.MINOR.PATCH | Definition | ★☆☆ | 1 min |
| `^` vs `~` in version ranges | Comparison | ★★☆ | 2 min |
| Why commit package-lock.json? | Reasoning | ★☆☆ | 1 min |
| dependencies vs devDependencies vs peerDependencies | Comparison | ★★☆ | 2 min |
| What is a semver breaking change? | Definition | ★☆☆ | 1 min |
| Pinning exact version vs using ranges | Comparison | ★★☆ | 2 min |
| How to automate version bumping? | Scenario | ★★☆ | 2 min |

**Q: When is a change a breaking change (major version bump)?**

A: A breaking change is any change that requires existing consumers
to update their code or configuration to avoid errors or behavior
changes. Examples:

API removals: deleting an exported function, removing a prop, removing
a configuration option.

API renames: changing a function name, renaming an export without an
alias.

Behavioral changes: a function that used to return `null` now throws,
or an async function is now synchronous.

Signature changes: adding a required parameter, changing parameter
order, changing return type.

Dependency requirement changes: requiring a minimum Node.js version
bump that breaks some users.

Non-obvious breaking changes: changing CSS class names (consumer's
CSS may rely on them), removing a performance optimization that
consumers depended on for timing guarantees.

*What separates good from great:* conventional commits + semantic-release
automation. Commit messages like `feat!: remove deprecated API` or
`BREAKING CHANGE:` in the commit body automatically trigger a major
version bump in CI. This makes semver compliance automatic rather than
manual.

---

# node_modules and Dependency Resolution

---

### 🎯 Model Answer

**30 seconds:**

> node_modules is the local directory where npm installs all project
> dependencies. Node.js resolves `require('react')` by searching up
> the directory tree for `node_modules/react`. With npm/yarn, packages
> are "hoisted" to the root node_modules (flat structure) to deduplicate
> shared dependencies. pnpm uses symlinks to a global store instead.
> The key problem: `node_modules` can be 500MB+ (never commit to git),
> and hoisting causes "phantom dependency" access to undeclared packages.

**Blank Mind Recovery:**

**(1) Restate:** "node_modules - where dependencies live. Resolution
walks up the directory tree. Hoisting deduplicates. Size is a concern."

---

### 📘 Concept Explanation

**What it is:**

node_modules is the directory tree where npm/yarn/pnpm installs all
project dependencies and their transitive dependencies. The Node.js
module resolver uses a specific algorithm to find packages from there.

**How it works:**

```
Resolution Algorithm (Node.js):
  require('react')
  1. Check if 'react' is a core module - no
  2. Look for ./node_modules/react
  3. If not found, look in ../node_modules/react
  4. Continue up to filesystem root
  5. If not found: MODULE_NOT_FOUND error

Flat (hoisted) node_modules (npm/yarn):
  project/
    node_modules/
      react/          <- hoisted to root
      react-dom/
      lodash/
      some-lib/       <- depends on react (not duplicated)

  Problem: some-lib can require('react') even if not declared
  in some-lib's package.json (phantom dependency)

Nested (strict) node_modules (pnpm):
  project/
    node_modules/
      .pnpm/             <- actual packages (content store)
        react@18.2.0/
          node_modules/
            react/ -> link to store
        some-lib@1.0.0/
          node_modules/
            some-lib/ -> link to store
            react/ -> symlink (only packages declared)
      react -> symlink to .pnpm/react@18.2.0/

  pnpm only creates symlinks for declared deps
  Phantom dependency access is blocked
```

**The key insight:**

Hoisting solves deduplication (only one copy of React even if 20
packages depend on it) but creates phantom dependencies (you can
accidentally use packages you didn't declare). pnpm's symlink approach
solves phantom deps but has some compatibility issues with packages
that don't handle symlinks well.

**When to use it:**

Understanding node_modules is necessary for: debugging module not
found errors, monorepo configuration, Docker build optimization
(`.dockerignore` must exclude `node_modules`), and CI caching.

---

### 💻 Code Example

**Example 1: Debugging module resolution**

```bash
# Find where a package resolves from:
node -e "console.log(require.resolve('react'))"
# /project/node_modules/react/index.js

# Check if there are multiple versions (version conflict):
npm list react
# project@1.0.0
# +-- react@18.3.1
# +-- some-legacy-lib@1.0.0
#   +-- react@16.14.0 (nested - version conflict!)

# Deduplicate packages where possible:
npm dedupe

# With pnpm: check why a package is installed:
pnpm why react
# Legend: production deps / dev deps / optional deps
# project@1.0.0
# +-- react@18.3.1
# +-- react-dom@18.3.1  <- also requires react

# BAD: importing a phantom dependency
import { debounce } from 'lodash'; // lodash in node_modules
                                   // (from another package)
// Breaks when that other package stops depending on lodash

# GOOD: declare the dependency yourself
# Add lodash to package.json first:
# npm install lodash
import { debounce } from 'lodash';
```

> **Code walkthrough:** `npm list react` is the first diagnostic for
> version conflicts. Multiple React versions in the tree cause hard-to-
> debug errors (hooks may fail because they're called from a different
> React instance). `npm dedupe` resolves these when the version ranges
> overlap. The phantom dependency example shows the hoisting trap: lodash
> may be available in node_modules (hoisted from a transitive dep) even
> if not declared - but it will break silently when the transitive dep
> changes or is removed.

**Example 2: Docker optimization**

```dockerfile
# BAD: Copying node_modules into Docker image
COPY . .
RUN npm install  # installs on top of copied node_modules
# Results in huge image, non-reproducible

# GOOD: Install fresh in Docker
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev  # install only production deps

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY dist ./dist  # pre-built output (not source)
CMD ["node", "dist/server.js"]
```

```text
.dockerignore:
  node_modules        <- never copy host node_modules
  .git
  dist                <- rebuilt in Docker
  coverage
```

> **Code walkthrough:** Never copy host `node_modules` into Docker.
> The host may be macOS; the container is Linux. Binary npm packages
> (compiled C++) are platform-specific and will fail. `npm ci --omit=dev`
> installs only production dependencies, keeping the image small. The
> multi-stage build separates dependency installation from the runtime
> image, preventing dev tools from being in the production image.

---

### ⚖️ Comparison Table

| Package manager | node_modules structure | Phantom deps | Disk use | Speed |
|---|---|---|---|---|
| npm | Flat (hoisted) | Possible | High (duplicates per project) | Medium |
| yarn classic | Flat (hoisted) | Possible | High | Fast |
| yarn Berry (PnP) | No node_modules | None (strict) | Low | Very fast |
| pnpm | Symlinks to store | None (strict) | Low (shared store) | Fast |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> node_modules is where npm stores all installed packages. Node.js
> finds packages by looking in the nearest node_modules up the
> directory tree. Always add node_modules to .gitignore and
> .dockerignore - run `npm install` to recreate it.

**Senior / Staff:**

> npm hoists packages to a flat root node_modules for deduplication
> but enables phantom dependency access. pnpm solves this with symlinks
> to a content-addressable store - packages can only access what they
> declared. In monorepos, pnpm's strict resolution catches undeclared
> deps early. For Docker, always use `npm ci --omit=dev` and multi-
> stage builds to avoid platform-specific binary issues.

---

### ⚠️ Common Misconceptions

**Misconception 1: You should commit node_modules.**

Never commit node_modules. It can be 500MB+ and is platform-specific
for native addons. Regenerate with `npm ci` from the committed lockfile.

**Misconception 2: All packages in node_modules are declared in package.json.**

Hoisting means undeclared transitive dependencies are accessible.
This is the phantom dependency problem. Use pnpm to enforce that only
declared packages are importable.

---

### 🚨 Failure Modes and Diagnosis

**Failure: "Error: Cannot find module" in production/Docker.**

Cause: Package is devDependency only; or copying host node_modules.

Fix: Move to dependencies; run `npm ci --omit=dev` and test locally.

**Failure: Multiple React instances error (hooks violation).**

Cause: Two versions of React in node_modules tree.

Diagnose: `npm list react`. Fix: `npm dedupe`; align versions.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How does Node.js resolve a require('react') call? | Mechanism | ★★☆ | 2 min |
| What is a phantom dependency? | Definition | ★★☆ | 2 min |
| Why is node_modules in .gitignore? | Reasoning | ★☆☆ | 1 min |
| How to debug multiple React instances? | Debugging | ★★☆ | 3 min |
| npm vs pnpm for monorepos - why prefer pnpm? | Comparison | ★★★ | 3 min |
| How do you optimize Docker images with node_modules? | Scenario | ★★☆ | 3 min |
| What is package hoisting and what problem does it create? | Mechanism | ★★☆ | 3 min |

**Q: How do you optimize Docker images that include node_modules?**

A: Three-step strategy: multi-stage builds, `--omit=dev`, and
cache layers.

Multi-stage build: stage 1 installs dependencies; stage 2 copies
only the node_modules and built output. Dev tools (TypeScript, ESLint,
webpack) are in devDependencies and excluded from stage 2.

`--omit=dev` (`npm ci --omit=dev` or `npm install --omit=dev`):
excludes devDependencies from the install. For a typical React app,
this reduces node_modules from 800MB to ~150MB.

Docker layer caching: `COPY package.json package-lock.json ./` before
`RUN npm ci`. If package.json doesn't change between builds, Docker
uses the cached node_modules layer. Only source code changes require
re-running the COPY step for source files.

Platform consistency: never copy your local node_modules (macOS
native addons fail on Linux Alpine). Always run `npm ci` inside the
container.

*What separates good from great:* Understanding that `npm ci` in Docker
does a clean install from the lockfile, deleting node_modules first.
Combine with `.dockerignore` that excludes `node_modules` to prevent
accidental copy, and use a `.npmrc` with `audit=false` in Docker to
skip security audit during build (run audit separately in CI).
