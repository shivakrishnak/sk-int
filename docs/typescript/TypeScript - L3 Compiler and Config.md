---
layout: default
title: "TypeScript - L3 Compiler and Config"
parent: "TypeScript"
nav_order: 7
permalink: /typescript/l3-compiler-and-config/
render_with_liquid: false
---

# TypeScript Compiler and tsconfig Options

---

### 🎯 Model Answer

**30 seconds:**

> `tsconfig.json` configures the TypeScript compiler. Key options:
> `strict: true` enables all strict checks (most important). `target`
> sets the output ES version. `module` sets the module format. `lib`
> adds type definitions. `paths` enables import aliases. `incremental:
> true` speeds up recompilation. Run `tsc --noEmit` for type-checking-
> only without generating output.

**Blank Mind Recovery:**

**(1) Restate:** "tsconfig.json controls TypeScript. strict: true is
most important. target = output ES version. noEmit = type check only."

---

### 📘 Concept Explanation

**What it is:**

`tsconfig.json` is the configuration file for the TypeScript compiler.
It controls type checking strictness, output format, compilation
targets, and file inclusion rules.

**The problem it solves:**

TypeScript has many optional behaviors (strict null checks, implicit
any, ES target). Without a tsconfig, defaults may not match your
project. A well-configured tsconfig enforces consistent type safety.

**How it works:**

```
tsconfig.json key options:
{
  "compilerOptions": {
    // Type checking (MOST IMPORTANT):
    "strict": true,           // enables ALL strict* flags
    "noUncheckedIndexedAccess": true, // array[i] is T | undefined
    "exactOptionalPropertyTypes": true,

    // Output target:
    "target": "ES2020",       // JS output syntax
    "lib": ["ES2020", "DOM"], // available type definitions
    "module": "ESNext",       // module format
    "moduleResolution": "Bundler", // how to resolve imports

    // Output control:
    "outDir": "./dist",
    "declaration": true,      // generate .d.ts files
    "noEmit": true,           // type check only (no output)
    "incremental": true,      // cache build info for speed

    // Safety:
    "isolatedModules": true,  // required for esbuild/SWC
    "paths": {
      "@/*": ["./src/*"]      // import aliases
    }
  }
}

What "strict: true" enables:
  strictNullChecks:            T != T | null | undefined
  noImplicitAny:               implicit 'any' is error
  strictPropertyInitialization: class props must be initialized
  useUnknownInCatchVariables:  catch 'e' is 'unknown' not 'any'
  + 4 more strict* flags

target vs lib:
  target: what syntax tsc EMITS (ES5 -> compiles async/await)
  lib: what type definitions are AVAILABLE
  ES2020 target + no DOM lib = fetch/document not recognized
```

---

### 💻 Code Example

**Example 1: Application vs library tsconfig**

```json
// Application (Vite + React) - type check only:
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noEmit": true,
    "isolatedModules": true,
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "paths": { "@/*": ["./src/*"] }
  },
  "include": ["src"]
}
```

```json
// Library (publishes .d.ts for consumers):
{
  "compilerOptions": {
    "target": "ES2018",
    "lib": ["ES2018"],
    "module": "ESNext",
    "moduleResolution": "Bundler",
    "strict": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist",
    "importHelpers": true
  },
  "include": ["src"],
  "exclude": ["src/**/*.test.ts"]
}
```

```bash
# Type check only (CI):
npx tsc --noEmit

# Show resolved config (debug):
npx tsc --showConfig

# Trace resolution (debug "cannot find module"):
npx tsc --noEmit --traceResolution 2>&1 | Select-String "=>"
```

> **Code walkthrough:** Application uses `noEmit: true` because Vite
> handles transpilation. `isolatedModules: true` ensures each file can
> be compiled independently by esbuild/SWC - required when the bundler
> processes files individually. Library config emits `.d.ts` files so
> TypeScript consumers get type information. `declarationMap: true`
> adds source maps for `.d.ts` files enabling IDE "go to definition"
> to jump to TypeScript source.

**Example 2: Incremental strict migration**

```typescript
// Enabling strict flags one by one in existing codebase:
// Week 1: "noImplicitAny": true
// Week 2: "strictNullChecks": true
// Week 3: "strictPropertyInitialization": true
// Week 4: enable "strict": true (catches remaining)

// Most common strictNullChecks fix:
// BEFORE:
function getUser(id: string) {
  const user = users.find(u => u.id === id);
  return user.name; // ERROR: user possibly undefined
}

// AFTER:
function getUser(id: string): string | undefined {
  const user = users.find(u => u.id === id);
  return user?.name;
}

// noUncheckedIndexedAccess changes array access:
const arr = [1, 2, 3];
// BEFORE: arr[0] is number
// AFTER:  arr[0] is number | undefined
const first = arr[0] ?? 0; // handle undefined
```

> **Code walkthrough:** Incremental strict migration prevents a "big
> bang" of hundreds of errors. Each flag adds a specific category.
> `strictNullChecks` is the highest-value flag - it prevents null/
> undefined runtime errors. `noUncheckedIndexedAccess` is the most
> invasive but prevents out-of-bounds array bugs.

---

### ⚖️ Comparison Table

| Option | Effect | Default | Recommendation |
|---|---|---|---|
| `strict` | All strict checks | false | Enable always in new projects |
| `noEmit` | Type check only | false | Enable for apps (bundler emits) |
| `isolatedModules` | Per-file compatibility | false | Enable with esbuild/SWC |
| `incremental` | Cache builds | false | Enable for large projects |
| `noUncheckedIndexedAccess` | Array safety | false | Enable in new strict codebases |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> tsconfig.json configures TypeScript. Most important: `strict: true`
> enables all strict type checks. `noEmit: true` means tsc only type-
> checks, my bundler handles output. `target` controls JS output syntax.

**Senior / Staff:**

> tsconfig is a project safety contract. I use `strict: true` plus
> `noUncheckedIndexedAccess` and `exactOptionalPropertyTypes` for
> maximum safety. `isolatedModules: true` is required with Vite/esbuild.
> For monorepos I use project references for incremental builds. For
> migrations, I enable strict flags incrementally rather than all at once.

---

### ⚠️ Common Misconceptions

**Misconception 1: TypeScript compiler handles all transpilation.**

In modern projects, bundlers (Vite, webpack+SWC) handle transpilation.
`tsc` only type-checks (`--noEmit`). This is why `isolatedModules: true`
is common - esbuild/SWC compile files individually.

**Misconception 2: `target: "ES5"` handles polyfills for older browsers.**

Target controls output syntax only. Runtime APIs (`fetch`, `Promise`)
still need explicit polyfills via `core-js` or similar.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `tsc --noEmit` passes but runtime error occurs.**

Cause: Bundler has different config or handles differently than tsc.

Fix: Add `isolatedModules: true` to catch bundler-incompatible patterns.

**Failure: Incremental build misses errors after config change.**

Cause: .tsbuildinfo cache is stale.

Fix: Delete .tsbuildinfo and rebuild. Add to .gitignore.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What does `strict: true` enable? | Definition | ★★☆ | 2 min |
| target vs lib - what's the difference? | Comparison | ★★☆ | 2 min |
| Why use `noEmit: true`? | Mechanism | ★★☆ | 1 min |
| What is `isolatedModules` and why Vite needs it? | Mechanism | ★★★ | 3 min |
| Migrate a codebase to strict mode | Scenario | ★★★ | 4 min |
| TypeScript project references - when to use? | Design | ★★★ | 3 min |
| Debug: "cannot find module" TypeScript error | Debugging | ★★☆ | 2 min |
| `moduleResolution: "Bundler"` vs `"node16"` | Comparison | ★★★ | 3 min |
| What is `forceConsistentCasingInFileNames`? | Mechanism | ★★☆ | 1 min |

**Q: What is `isolatedModules: true` and why is it required with Vite?**

A: `isolatedModules: true` validates that each TypeScript file can
be independently transpiled without needing information from other
files.

The problem: esbuild and SWC (used by Vite) transpile files individually
- they don't do full TypeScript program analysis. Some TypeScript
features require program-level information:

`const enum` requires inlining: the transpiler needs the enum's values
from another file to inline them at usage sites. Without full program
analysis, esbuild produces wrong output.

```typescript
const enum Direction { Up = 1, Down }
const d = Direction.Up; // should inline to: const d = 1;
// esbuild can't do this without full program analysis -> runtime bug
```

With `isolatedModules: true`, TypeScript reports an error when you use
`const enum` across files - preventing the silent runtime bug.

The rule: any codebase using Vite, Next.js, esbuild, or SWC as the
transpiler should have `isolatedModules: true`. The flag makes the
TypeScript checker enforce the constraint that the transpiler needs.

*What separates good from great:* Understanding the separation: `tsc`
type-checks, bundler transforms. This split enables fast parallel
builds (esbuild runs on all cores; tsc checks types separately) but
requires `isolatedModules` to ensure compatibility. The flag is the
contract between the type system and the transformation pipeline.

---

# Module Resolution Strategies

---

### 🎯 Model Answer

**30 seconds:**

> TypeScript module resolution determines how `import './foo'` finds
> a file. `"node"` follows old Node.js rules. `"bundler"` (TS 5+) is
> for webpack/Vite - supports package.json `exports`, no extension
> required. `"node16"` requires explicit `.js` extensions for Node.js
> ESM. Wrong `moduleResolution` causes "cannot find module" errors.
> Path aliases need config in tsconfig AND bundler AND jest.

**Blank Mind Recovery:**

**(1) Restate:** "moduleResolution: how TypeScript finds imports.
'bundler' for Vite/webpack. 'node16' for Node.js ESM. Path aliases
go in tsconfig + bundler + jest."

---

### 📘 Concept Explanation

**What it is:**

Module resolution is the algorithm TypeScript uses to map an import
path to a file. Different environments (Node.js, bundlers, browsers)
use different resolution strategies.

**The problem it solves:**

TypeScript must find the same files as the actual runtime. Wrong
`moduleResolution` causes false "cannot find module" errors, or
accepts imports that fail at runtime.

**How it works:**

```
Available strategies:

"node" (legacy):
  Old Node.js CJS algorithm
  './foo' -> foo.ts, foo.tsx, foo.d.ts, foo/index.ts
  Does NOT support: package.json "exports" field
  Use: old projects only

"bundler" (TypeScript 5.0+, RECOMMENDED for apps):
  Matches bundler (Vite, webpack) behavior
  Supports package.json "exports" field
  No extension required: import './utils' (finds utils.ts)
  Use: all Vite/webpack frontend projects

"node16" / "nodenext":
  Node.js 12+ ESM algorithm
  Supports "exports" field
  Requires .js extensions: import './utils.js'
  Use: Node.js packages publishing ESM

Path aliases:
  tsconfig.json:
    "paths": { "@/*": ["./src/*"] }

  MUST ALSO configure in bundler:
  vite.config.ts: resolve.alias { '@': '/src' }

  MUST ALSO configure in jest:
  jest.config: moduleNameMapper: { '^@/(.*)$': '<rootDir>/src/$1' }
```

---

### 💻 Code Example

**Example 1: Path aliases - all three configurations**

```typescript
// tsconfig.json - TypeScript resolution:
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": { "@/*": ["src/*"] }
  }
}

// vite.config.ts - bundler resolution:
import path from 'path';
export default defineConfig({
  resolve: {
    alias: { '@': path.resolve(__dirname, 'src') }
  }
});

// jest.config.ts - test resolution:
export default {
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  }
};

// Usage (works everywhere after all 3 are configured):
import { Button } from '@/components/Button';
```

> **Code walkthrough:** Path aliases are a common source of confusion
> because they must be configured in three independent places. TypeScript
> `paths` only affects type checking. The bundler and jest each have
> their own module resolution that must be separately configured.
> `vite-tsconfig-paths` plugin automatically syncs tsconfig paths to
> Vite, eliminating the duplication.

**Example 2: Debug "cannot find module" errors**

```bash
# Trace TypeScript resolution:
npx tsc --noEmit --traceResolution 2>&1 | Select-String "myModule"

# Common causes:
# 1. Missing @types:
# "Could not find declaration file for 'lodash'"
npm install --save-dev @types/lodash

# 2. moduleResolution: "node" misses "exports" field
# Fix: switch to "moduleResolution": "bundler"

# 3. Path aliases missing from jest config
# Fix: add moduleNameMapper to jest.config

# 4. Case sensitivity (macOS vs Linux):
# Fix: "forceConsistentCasingInFileNames": true
```

> **Code walkthrough:** `--traceResolution` is verbose but shows
> exactly what TypeScript tried. It reveals whether the issue is a
> missing file, a wrong strategy, or a paths misconfiguration.

---

### ⚖️ Comparison Table

| Strategy | Extensions required | exports field | Use for |
|---|---|---|---|
| `node` (legacy) | No | No | Old CJS projects |
| `bundler` (TS 5+) | No | Yes | All Vite/webpack apps |
| `node16`/`nodenext` | Yes (.js) | Yes | Node.js ESM packages |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `moduleResolution: "bundler"` for Vite/webpack projects. Path aliases
> need config in both tsconfig and the bundler. Wrong setting causes
> "cannot find module" errors even when the file exists.

**Senior / Staff:**

> Module resolution must match the runtime. I use `"bundler"` for
> frontend apps (supports exports field, no extension needed), and
> `"node16"` for Node.js ESM packages. Path aliases require three
> configurations: tsconfig, bundler, and jest. I use `vite-tsconfig-paths`
> to sync tsconfig paths to Vite automatically.

---

### ⚠️ Common Misconceptions

**Misconception 1: TypeScript `paths` applies to the bundler.**

TypeScript `paths` only affects TypeScript type resolution. The bundler
uses its own alias configuration. Both must be set independently.

**Misconception 2: `"node16"` is for all modern projects.**

`"node16"` requires `.js` extensions in imports - correct for Node.js
ESM, awkward for frontend. Frontend with bundlers should use `"bundler"`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: TypeScript accepts import, bundler fails at build.**

Cause: tsconfig moduleResolution != bundler resolution. TypeScript
found the type but bundler can't find the file.

Fix: Use `"bundler"` resolution; verify bundler alias config matches
tsconfig paths.

**Failure: `@/` alias works in src but fails in tests.**

Cause: jest.config moduleNameMapper not configured.

Fix: Add `moduleNameMapper: { '^@/(.*)$': '<rootDir>/src/$1' }`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is TypeScript module resolution? | Definition | ★★☆ | 2 min |
| "bundler" vs "node16" - when each? | Comparison | ★★☆ | 2 min |
| How to configure path aliases? | Scenario | ★★☆ | 3 min |
| Why do aliases need 3 separate configs? | Mechanism | ★★★ | 2 min |
| Debug: "cannot find module" for local file | Debugging | ★★☆ | 3 min |
| What is the package.json "exports" field? | Definition | ★★★ | 3 min |
| `forceConsistentCasingInFileNames` - why? | Mechanism | ★★☆ | 2 min |
| `baseUrl` - when to use vs not? | Definition | ★★☆ | 2 min |
| How TypeScript resolves `@types` packages | Mechanism | ★★★ | 2 min |

**Q: How does TypeScript resolve `import { Button } from '@/components/Button'`?**

A: With `moduleResolution: "bundler"` and `paths: { "@/*": ["src/*"] }`:

1. Match against `paths`: `@/*` matches `@/components/Button`
   -> maps to `src/components/Button`

2. Apply `baseUrl` to make absolute: `<root>/src/components/Button`

3. Try extensions:
   - `src/components/Button.ts` - found -> done

TypeScript then type-checks using the found file. The bundler (Vite)
independently resolves the same import using its own alias configuration.

The two resolution steps are independent: TypeScript confirms types,
Vite finds the runtime file. Both must succeed for the import to work.

*What separates good from great:* `vite-tsconfig-paths` plugin
automatically reads tsconfig `paths` and configures Vite aliases.
This centralizes alias configuration in tsconfig.json and eliminates
the "forgot to update one of three places" bug.
