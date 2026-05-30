---
layout: default
title: "TypeScript - L0 Orientation"
parent: "TypeScript"
nav_order: 1
permalink: /typescript/l0-orientation/
render_with_liquid: false
---

# Why TypeScript Exists

🎯 **Interview Weight:** foundational (★☆☆) - every TypeScript interview
starts here; being able to articulate the "why" distinguishes engineers
who use TypeScript deliberately from those who use it because the job
description required it

---

### 🎯 Model Answer

**30 seconds:**

> TypeScript exists because JavaScript has no static type system. In
> large codebases, JavaScript's dynamic typing causes bugs that only
> surface at runtime, makes refactoring dangerous (no compile-time
> catch of broken references), and hinders IDE tooling (no reliable
> autocompletion or go-to-definition). TypeScript adds a static type
> layer that is erased at compile time - you get type safety during
> development with zero runtime overhead.

**3 minutes:**

> The specific problems TypeScript solves:
>
> 1. **Runtime type errors become compile errors**: `Cannot read property
>    'name' of undefined` in production is caught as `Object is
>    possibly 'undefined'` at development time.
>
> 2. **Safe refactoring**: rename a function or change a parameter type -
>    TypeScript finds every broken caller at compile time. In JavaScript,
>    you find them in production.
>
> 3. **IDE intelligence**: TypeScript's language server powers VS Code's
>    autocompletion, go-to-definition, find references, and inline
>    documentation. JavaScript can approximate this with JSDoc, but
>    TypeScript is more precise.
>
> 4. **Self-documenting code**: function signatures with types are
>    a form of documentation that can't go out of date (unlike comments).
>
> TypeScript does NOT: make JavaScript faster, provide runtime type
> checking, or eliminate all bugs. It eliminates a specific category
> of type-related bugs that are common in large codebases.

**Blank Mind Recovery:**

**(1) Restate:** "TypeScript = JavaScript + static types. Types erased
at compile time (zero runtime overhead). Why: catch type errors before
runtime, safe refactoring, better IDE tooling. Created by Microsoft
(Anders Hejlsberg, 2012). First-class support in VS Code, Angular,
NestJS, Next.js. Compiles to plain JavaScript."

---

### 📘 Concept Explanation

**What it is:**

TypeScript is a strongly typed programming language that builds on
JavaScript by adding optional static types, interfaces, enums, and
other features. It compiles (transpiles) to plain JavaScript and can
run anywhere JavaScript runs. Created by Microsoft (lead architect:
Anders Hejlsberg, creator of C# and Delphi) in 2012.

**The problem it solves:**

JavaScript is dynamically typed. Types are checked at runtime, not
at compile time. In small scripts, this is fine - the codebase is
small enough to hold in your head. At scale (millions of lines, hundreds
of engineers), dynamic typing creates three severe problems:

1. **Type errors in production**: bugs where `undefined.method()` is
   called, a wrong data shape is passed, or a renamed property is still
   referenced with the old name.

2. **Refactoring fragility**: changing a function signature has no
   guaranteed way to update all callers. Engineers either write
   comprehensive tests (which don't cover all cases) or make "safe"
   changes by adding parameters instead of renaming.

3. **Cognitive load**: without types, engineers must read source code
   or documentation to understand what a function expects. Types make
   interfaces explicit.

**How it works:**

```
TYPESCRIPT TOOLCHAIN:

  TypeScript Source (.ts):
    function greet(name: string): string {
      return `Hello, ${name}`;
    }

  TypeScript Compiler (tsc):
    - Parses TypeScript source
    - Type checks (validates type correctness)
    - Erases type annotations
    - Emits JavaScript

  JavaScript Output (.js):
    function greet(name) {
      return `Hello, ${name}`;
    }
  // Types are GONE. Zero runtime overhead.
  // No type information exists at runtime.

  COMPILATION MODES:

    tsc --watch       (watches for changes, recompiles)
    tsc --noEmit      (type check only, no JS output)
    ts-node           (executes TypeScript directly in Node.js)
    Babel + @babel/preset-typescript  (strips types, no type check)
    esbuild / swc     (fast transpile, no type check)

  KEY: tsc does BOTH type checking AND transpilation.
       Babel/esbuild only transpile (no type checking).
       Production builds often use esbuild for speed + tsc for
       type checking in CI.

WHAT TYPESCRIPT CATCHES:

  // 1. Property access errors:
  const user = { name: 'Alice', age: 30 };
  console.log(user.emai);  // Error: Property 'emai' does not exist
  // (typo: email vs emai caught at compile time)

  // 2. Wrong argument types:
  function square(n: number): number { return n * n; }
  square('5');  // Error: Argument of type 'string' is not assignable
                //        to parameter of type 'number'

  // 3. Null/undefined access (with strictNullChecks):
  function getLength(s: string | null): number {
    return s.length;  // Error: Object is possibly 'null'
    // Must handle null first:
    return s?.length ?? 0;  // Correct
  }

  // 4. Structural shape mismatches:
  interface User { id: number; name: string; }
  function render(user: User) { ... }
  render({ id: '1', name: 'Alice' });
  // Error: Type 'string' is not assignable to type 'number' for 'id'

WHAT TYPESCRIPT DOES NOT CATCH:

  // Runtime values: TypeScript checks static types, not runtime data
  const userData = JSON.parse(apiResponse);
  // userData is 'any' - TypeScript has no idea what JSON.parse returns
  // You can cast it: userData as User
  // But that's a PROMISE to TypeScript, not runtime validation
  // Use: Zod, Yup, io-ts for runtime validation of external data
```

**Why it matters:**

TypeScript adoption in production codebases has accelerated sharply:
Google, Microsoft, Airbnb, Lyft, Stripe, Slack all use TypeScript.
The JavaScript ecosystem has largely moved to TypeScript for large
projects. Understanding WHY TypeScript exists (not just HOW to use it)
separates engineers who use it as a checkbox requirement from those
who use it as a genuine engineering tool.

**Mental model:**

> TypeScript is a spell-checker for your code's logic. Just as a
> spell-checker catches typos before you publish a document, TypeScript
> catches type errors before you deploy code. The document still
> exists without the spell-checker marks (TypeScript annotations are
> erased at compile time), but you caught the errors earlier.

**Scale behavior:**

At 1,000 lines of code: TypeScript overhead is real but manageable.
At 100,000+ lines with 50+ engineers: TypeScript pays for itself in
prevented bugs and safe refactoring. The "productivity loss" from
writing type annotations is recovered within weeks through bugs
prevented and refactoring confidence.

---

### 💻 Code Example

**JavaScript bug that TypeScript prevents**

```javascript
// JAVASCRIPT: runtime bug (production)
// BAD: no type safety
function getUserEmail(userId) {
  const users = getUsers();
  const user = users.find(u => u.id === userId);
  return user.email;  // TypeError if user is undefined!
  // Happens when userId doesn't match any user
  // Discovered in production, not during development
}

// Called with missing user:
getUserEmail(999);  // TypeError: Cannot read 'email' of undefined
// Happens in production, affects real users

// TYPESCRIPT: compile-time error
// GOOD: type-safe
interface User {
  id: number;
  name: string;
  email: string;
}

function getUserEmail(userId: number): string | undefined {
  const users = getUsers();
  const user = users.find(u => u.id === userId);
  return user?.email;  // undefined if user not found (safe)
}

// Caller must handle undefined:
const email = getUserEmail(999);
if (email) {
  sendEmail(email);  // Only runs if email exists
}

// REFACTORING SAFETY EXAMPLE:
// BAD (JavaScript): rename a function, miss a caller
function fetchUserData(id) { ... }  // Renamed to: fetchUser

// caller.js:
const data = fetchUserData(1);  // Only fails at RUNTIME

// GOOD (TypeScript): compiler catches missed callers
function fetchUser(id: number): Promise<User> { ... }
// Old name fetchUserData no longer exists:
const data = await fetchUserData(1);
// Error: Cannot find name 'fetchUserData'
// Caught at compile time, not runtime
```

> **Code walkthrough:** The JavaScript version's `user.email` access
> throws at runtime when `users.find()` returns `undefined` (no user
> with that ID). This is a production bug - it only happens with
> certain inputs. TypeScript forces the engineer to acknowledge that
> `find()` can return `undefined` by making the return type `User |
> undefined`. The `user?.email` (optional chaining) handles the
> undefined case safely. The refactoring example shows TypeScript's
> most valuable production feature: rename a function and TypeScript
> immediately shows every missed caller. In a 100K-line JavaScript
> codebase, finding all callers requires grep and hope.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> TypeScript adds static types to JavaScript. Types are checked at
> compile time - you find bugs earlier. The types are erased at
> compile time so there's no runtime overhead. Main benefits: catch
> type errors before production, better IDE autocompletion, safer
> refactoring.

**Senior / Staff:**

> TypeScript's core value proposition is narrowing the feedback loop
> for type errors from "production incident" to "compiler warning at
> save time." For large teams, the refactoring safety is the most
> valuable property: changing a shared interface triggers a compile
> error for every consumer, forcing explicit updates. This is the
> difference between confident refactoring and "grep-and-pray"
> refactoring. The structural type system (duck typing at compile time)
> makes it additive: you can adopt TypeScript incrementally with
> `allowJs: true` and `noImplicitAny: false`, then gradually tighten.
> The tooling dividend (VS Code's language server is TypeScript-powered)
> is immediate regardless of type strictness.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword - "why TypeScript exists" is a single concept, no comparison needed)*

---

### 📊 Diagram

*(Omit: TypeScript toolchain is fully described in ASCII in Concept Explanation)*

---

### ⚠️ Common Misconceptions

**"TypeScript provides runtime type safety"**

TypeScript types exist only at compile time. After `tsc` compiles
your code, all type annotations are GONE. The compiled JavaScript
has no type information. If external data (API responses, JSON.parse,
user input) doesn't match your TypeScript types, TypeScript does not
catch it at runtime - it trusts the types you declared. Runtime
validation of external data requires separate libraries: Zod, Yup,
Joi, or io-ts. TypeScript = compile-time safety. Zod = runtime safety.
Both are needed in production.

**"TypeScript makes JavaScript slower"**

TypeScript compiles to JavaScript. The runtime is still the JavaScript
engine (V8, SpiderMonkey). TypeScript adds ZERO overhead at runtime.
The only cost is the compilation step (which adds 1-10s to builds,
mitigated by incremental compilation). For the runtime behavior:
the compiled JS is identical to what you'd write manually - often
even simpler because TypeScript emits clean, modern JS.

---

### 🚨 Failure Modes and Diagnosis

**False sense of security from TypeScript with 'any':**

```typescript
// SYMPTOM: TypeScript-enabled codebase still has runtime type errors
// CAUSE: overuse of 'any' escapes type checking entirely

// BAD: any defeats the purpose
function processData(data: any) {
  return data.user.name.toLowerCase();
  // No type checking! Runtime error if data.user is undefined
  // TypeScript trusts you completely with 'any'
}

// DIAGNOSIS: run tsc with --strict and count 'any' usages
// Or: ESLint @typescript-eslint/no-explicit-any rule

// FIX: use unknown for truly unknown data, then narrow
function processData(data: unknown): string {
  if (typeof data === 'object' && data !== null &&
      'user' in data) {
    const user = (data as { user: { name: string } }).user;
    return user.name.toLowerCase();
  }
  throw new Error('Invalid data shape');
}

// BETTER FIX: Zod schema for runtime + compile time:
import { z } from 'zod';
const DataSchema = z.object({
  user: z.object({ name: z.string() })
});
function processData(rawData: unknown): string {
  const data = DataSchema.parse(rawData);  // Throws if invalid
  return data.user.name.toLowerCase();  // TypeScript knows the shape
}
```

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| Why TypeScript over JavaScript? | 2-3 min | Compile-time vs runtime |
| What TypeScript doesn't catch | 2-3 min | Runtime validation |
| TypeScript adoption strategy | 2-3 min | Incremental, allowJs |
| TypeScript vs JSDoc | 2-3 min | Trade-offs |
| any vs unknown | 2-3 min | Type safety levels |
| TypeScript compilation pipeline | 2-3 min | tsc vs Babel |
| TypeScript and bundle size | 1-2 min | Zero overhead |

---

**Q1: What are the main benefits of using TypeScript over JavaScript?**
`[JUNIOR]` DECISION

> **Answer:**
>
> TypeScript provides four concrete benefits:
>
> 1. **Earlier bug detection**: type errors are found at compile time
>    (when you save), not at runtime (when users hit a production bug).
>    TypeScript catches: property typos, wrong argument types, missing
>    required parameters, and null/undefined access.
>
> 2. **Safer refactoring**: changing a function signature or renaming
>    a property updates the TypeScript error count in real time. Every
>    call site that needs updating is immediately visible. Without
>    TypeScript, refactoring requires comprehensive grep searches and
>    reliance on test coverage.
>
> 3. **Better IDE tooling**: TypeScript's language server enables
>    accurate autocompletion, go-to-definition, find-all-references,
>    and inline type documentation. VS Code's TypeScript support is
>    industry-leading; these features work even in JavaScript files
>    via type inference.
>
> 4. **Living documentation**: type signatures are documentation that
>    can't go out of date. `function createUser(name: string, role: 'admin' | 'user'): Promise<User>`
>    tells every caller exactly what's needed without reading the implementation.
>
> *What separates good from great:* The most significant benefit at
> scale is refactoring safety. TypeScript enables what Martin Fowler
> calls "fearless refactoring" - you can rename, restructure, and
> reorganize code with confidence that the compiler will find every
> broken reference. In large JavaScript codebases, fear of breaking
> things creates "fossilized code" - unmaintainable code that no one
> touches because the cost of changing it is unpredictable.

**Q2: What does TypeScript NOT protect you from?** `[SENIOR]` MECHANISM

> **Answer:**
>
> TypeScript's guarantees are at compile time only. The compiled
> JavaScript has no type information. Gaps:
>
> 1. **External data**: `JSON.parse()` returns `any`. API responses,
>    user input, localStorage values, environment variables - TypeScript
>    trusts whatever type you declare, without verifying at runtime.
>
> 2. **Type assertions** (`as`): `const x = data as User` tells TypeScript
>    "I guarantee this is a User." If it's not, TypeScript trusts you
>    and you get runtime errors.
>
> 3. **`any` type**: the escape hatch. TypeScript performs NO checking
>    on `any` values. Libraries without type definitions and `JSON.parse`
>    return `any` by default.
>
> 4. **Third-party runtime behavior**: a library's TypeScript types
>    may be wrong or outdated. The types are documentation, not a
>    runtime contract.
>
> 5. **Logic errors**: TypeScript checks types, not logic correctness.
>    `const total = price + tax` is type-correct even if the business
>    logic should be `price * (1 + taxRate)`.
>
> ```typescript
> // WHAT TYPESCRIPT MISSES:
>
> // External data is 'any' unless validated:
> const config = JSON.parse(envVar) as DatabaseConfig;
> // TypeScript trusts 'as DatabaseConfig'
> // If envVar is malformed, you get runtime errors
>
> // Solution: runtime validation (Zod):
> const config = DatabaseConfigSchema.parse(JSON.parse(envVar));
> // Throws if shape doesn't match - catches misconfiguration early
> ```
>
> *What separates good from great:* Production TypeScript architectures
> have a clear boundary between "TypeScript-safe zone" (internal code,
> typed across the entire call chain) and "trust boundaries" (HTTP
> responses, environment variables, user input). At trust boundaries,
> you need runtime validation (Zod/Yup) that is ALSO reflected in
> TypeScript types. Zod's `.parse()` returns a typed result -
> TypeScript type safety + runtime validation in one call. This is
> the production pattern for safe external data handling.

**Q3: How do you incrementally adopt TypeScript in an existing
JavaScript codebase?** `[SENIOR]` SYSTEM-DESIGN

> **Answer:**
>
> Incremental adoption uses `allowJs: true` and `checkJs: false`
> to mix TypeScript and JavaScript files:
>
> ```json
> // tsconfig.json for incremental adoption:
> {
>   "compilerOptions": {
>     "allowJs": true,        // Allow .js files
>     "checkJs": false,       // Don't type-check .js files yet
>     "strict": false,        // Start lenient; tighten over time
>     "noImplicitAny": false, // Allow implicit any initially
>     "outDir": "./dist",
>     "target": "ES2020"
>   },
>   "include": ["src/**/*"]
> }
> ```
>
> **Migration phases:**
>
> 1. **Phase 1 (week 1-2)**: rename entry points `.js` -> `.ts`; fix
>    only errors that block compilation; use `any` freely; goal:
>    codebase compiles.
>
> 2. **Phase 2 (sprint by sprint)**: convert files by module boundary.
>    Start with shared utilities (used everywhere). Types on shared
>    code benefit all consumers.
>
> 3. **Phase 3 (over months)**: enable stricter settings:
>    `noImplicitAny: true`, then `strict: true`. Replace `any` with
>    real types. Add Zod validation at API boundaries.
>
> 4. **Phase 4 (ongoing)**: remove `allowJs`, require TypeScript for
>    all new files, lint rules to maintain strictness.
>
> *What separates good from great:* The most common incremental
> adoption mistake is converting all files at once and drowning in
> errors. The productive approach: convert leaf files (no imports
> from other local files) first, then work inward. This limits the
> blast radius of each conversion. Tooling: `ts-migrate` (Airbnb's
> open-source tool) automates the initial conversion by adding `any`
> annotations everywhere, creating a compilable baseline to improve
> incrementally.

**Q4: What is the difference between 'any' and 'unknown'?** `[MID]`
MECHANISM

> **Answer:**
>
> `any` disables type checking entirely for that value. `unknown` is
> type-safe: you can assign anything to it, but you MUST narrow it
> before use.
>
> ```typescript
> // ANY: no type checking (unsafe)
> let x: any = 'hello';
> x.toFixed(2);      // No error! Even though strings have no toFixed
> x.doesNotExist();  // No error! TypeScript trusts you completely
> const n: number = x;  // No error! Even though x is a string
>
> // UNKNOWN: must narrow before use (safe)
> let y: unknown = 'hello';
> y.toFixed(2);      // Error: Object is of type 'unknown'
> y.doesNotExist();  // Error: Object is of type 'unknown'
>
> // Must narrow first:
> if (typeof y === 'string') {
>   y.toUpperCase();  // OK: y is now narrowed to 'string'
> }
> if (typeof y === 'number') {
>   y.toFixed(2);     // OK: y is now narrowed to 'number'
> }
>
> // USE CASES:
> // any: migrating old code, third-party types are wrong
> // unknown: function parameters of uncertain type, JSON.parse results
>
> function processInput(input: unknown): string {
>   if (typeof input === 'string') return input;
>   if (typeof input === 'number') return input.toString();
>   throw new Error(`Unexpected input type: ${typeof input}`);
> }
> // TypeScript forces you to handle all cases
> ```
>
> *What separates good from great:* `unknown` is the type-safe
> replacement for `any` in all cases where you genuinely don't know
> the type. The rule: `any` means "I don't care about types here";
> `unknown` means "I know this exists but I'll check before using."
> For new code: use `unknown` for external data entry points and
> error handlers (`catch (e: unknown)`). The TypeScript 4.0 change
> made `catch` variables type `unknown` instead of `any` in strict mode
> - this forced correct error handling patterns across the ecosystem.

**Q5: How does TypeScript compile to JavaScript and what's the
performance impact?** `[MID]` MECHANISM

> **Answer:**
>
> TypeScript's compilation has two distinct phases:
>
> 1. **Type checking**: analyze the program's types, report errors
> 2. **Emit**: strip type annotations, generate JavaScript
>
> The emitted JavaScript is essentially your TypeScript code with
> type annotations removed. No runtime overhead is added.
>
> ```typescript
> // TypeScript input:
> interface Config {
>   host: string;
>   port: number;
>   ssl: boolean;
> }
>
> async function connect(config: Config): Promise<Connection> {
>   const url = `${config.ssl ? 'https' : 'http'}://${config.host}:${config.port}`;
>   return await createConnection(url);
> }
>
> // JavaScript output (after tsc):
> async function connect(config) {  // interface gone
>   const url = `${config.ssl ? 'https' : 'http'}://${config.host}:${config.port}`;
>   return await createConnection(url);
> }
> // Identical behavior, zero extra code
> ```
>
> Build performance considerations:
> - Full `tsc` (type check + emit): 5-30s for large codebases
> - `tsc --noEmit` (type check only): same cost
> - `babel` / `esbuild` (emit only, no type check): < 1s
> - Production pattern: esbuild/swc for dev builds (fast), tsc in CI
>
> *What separates good from great:* The separation of concerns between
> "type checking" and "transpilation" is a key architectural insight
> for build systems. Tools like esbuild and Babel can transpile
> TypeScript (strip types, compile to JS) much faster than tsc because
> they skip type checking. In a large monorepo, running tsc for every
> file change would be prohibitively slow. The pattern: use a fast
> transpiler for local development and running tests, use tsc for CI
> type-checking (can be parallelized across packages).

**Q6: What is TypeScript's relationship with JSDoc?** `[SENIOR]`
DECISION

> **Answer:**
>
> JSDoc is a comment-based type annotation system for JavaScript.
> TypeScript can read JSDoc annotations and provide type safety from
> them. This allows type safety without changing file extensions to .ts.
>
> ```javascript
> // JSDoc type annotations in JavaScript:
>
> /**
>  * @param {string} name
>  * @param {number} age
>  * @returns {{ name: string, greeting: string }}
>  */
> function greet(name, age) {
>   return { name, greeting: `Hello ${name}, you are ${age}` };
> }
>
> // TypeScript can type-check this with:
> // tsconfig.json: { "checkJs": true, "allowJs": true }
>
> // WHEN TO USE JSDoc INSTEAD OF TypeScript:
> // - Library authors who want to support JS consumers natively
> // - Gradual migration: add types without renaming files
> // - Node.js scripts where TypeScript compilation is overhead
> // - Quick prototypes
>
> // WHEN TYPESCRIPT IS BETTER:
> // - Complex type expressions (conditional types, mapped types)
> // - Generics (JSDoc supports them but syntax is awkward)
> // - Team consistency (one language, not JS+comment-types)
> // - New projects with no legacy JS to migrate
> ```
>
> *What separates good from great:* TypeScript `.d.ts` declaration
> files are the "type-only" artifact that library authors publish to
> npm. When you install `@types/lodash`, you're installing `.d.ts`
> files that describe lodash's types. Lodash itself is still JavaScript.
> This architecture allows: the library is JavaScript (runs everywhere
> without TypeScript), but TypeScript users get type safety. Many
> libraries (lodash, jQuery, older packages) use `@types/packagename`
> from DefinitelyTyped. Newer libraries are TypeScript-native and
> bundle their own `.d.ts` files.

**Q7: What is 'strict' mode in TypeScript and which checks does it
enable?** `[SENIOR]` MECHANISM

> **Answer:**
>
> `"strict": true` in tsconfig.json is a shorthand that enables a
> group of strict type-checking flags:
>
> | Flag | What it does |
> |---|---|
> | `strictNullChecks` | null/undefined are not assignable to other types |
> | `strictFunctionTypes` | contravariant function parameter types |
> | `strictBindCallApply` | strict types for .bind/.call/.apply |
> | `strictPropertyInitialization` | class properties must be initialized |
> | `noImplicitAny` | error when TypeScript infers 'any' |
> | `noImplicitThis` | error when 'this' has 'any' type |
> | `useUnknownInCatchVariables` | catch variables typed 'unknown' |
> | `alwaysStrict` | emits 'use strict' in all files |
>
> ```typescript
> // WITH STRICT: false
> function greet(name) { return `Hello ${name}`; }
> // name is 'any' (noImplicitAny disabled) - no error
>
> // WITH STRICT: true
> function greet(name) { return `Hello ${name}`; }
> // Error: Parameter 'name' implicitly has an 'any' type
> // Must explicitly type:
> function greet(name: string) { return `Hello ${name}`; }
>
> // strictNullChecks:
> function getUser(id: number): User | undefined {
>   return users.find(u => u.id === id);
> }
> const user = getUser(1);
> console.log(user.name);  // Error: Object is possibly 'undefined'
> // Must narrow:
> console.log(user?.name);
> ```
>
> *What separates good from great:* `strictNullChecks` is the most
> impactful flag. It changes the type system from "null is compatible
> with everything" (Java < 8 style) to "null/undefined are explicit
> types" (Kotlin/Swift style). Code written with `strictNullChecks: true`
> has dramatically fewer null pointer exceptions. The cost: you must
> handle null/undefined explicitly everywhere. The payoff: null pointer
> exceptions (one of the most common production errors) become compile
> errors. For new projects: always `strict: true`. For migrations:
> enable `strictNullChecks` first - it provides the most value, and
> `noImplicitAny` can come later.

---

---

# TypeScript vs JavaScript Trade-off

🎯 **Interview Weight:** foundational (★☆☆) - being asked to compare
TypeScript and JavaScript is universal in frontend/full-stack interviews

---

### 🎯 Model Answer

**30 seconds:**

> TypeScript adds compile-time type safety at the cost of additional
> compilation step, type annotation overhead, and stricter toolchain
> requirements. The trade-off is favorable for large codebases with
> teams (safety and tooling > overhead) and unfavorable for small
> scripts (overhead > benefit). Both produce identical JavaScript;
> the difference is in the development experience.

**3 minutes:**

> Key trade-offs:
>
> GAINS with TypeScript:
> - Type errors caught before runtime (compile-time safety)
> - Safe refactoring (compiler finds all broken callers)
> - Better IDE tooling (precise autocompletion, go-to-definition)
> - Living documentation (function signatures as docs)
>
> COSTS of TypeScript:
> - Compilation step required (adds build complexity)
> - Type annotation overhead (writing and maintaining types)
> - Learning curve for advanced features (generics, conditional types)
> - Third-party library types may be incomplete or wrong
> - `any` creep can undermine safety if not controlled

**Blank Mind Recovery:**

**(1) Restate:** "TypeScript gains: compile safety, refactoring, tooling.
TypeScript costs: compilation step, annotation overhead, learning curve.
Use TypeScript for: large projects, teams, long-lived code. JavaScript
might be fine for: small scripts, quick prototypes, single-use tools."

---

### 📘 Concept Explanation

**What it is:**

The TypeScript vs JavaScript trade-off is an engineering decision
about how much upfront investment in type safety is warranted for a
given project's size, team, and lifespan.

**The problem it solves:**

Teams need to make an informed decision about when TypeScript's benefits
outweigh its costs. Neither "always TypeScript" nor "always JavaScript"
is correct for all cases.

**How it works:**

```
WHEN TYPESCRIPT WINS (benefits outweigh costs):

  ✓ Team size > 3 engineers (coordination benefits)
  ✓ Codebase > 10K LOC (refactoring safety)
  ✓ Long-term project (> 6 months)
  ✓ Shared library / SDK (types as API contract)
  ✓ Complex domain logic (financial, medical, safety-critical)
  ✓ Framework that expects TypeScript (Angular, NestJS)

WHEN JAVASCRIPT MIGHT BE SUFFICIENT:

  ✓ Single-developer project
  ✓ Short-lived script (< 100 LOC)
  ✓ Prototype / proof-of-concept
  ✓ Team has no TypeScript experience (learning curve)
  ✓ Heavy reliance on dynamic patterns difficult to type

COST BREAKDOWN:

  Initial setup:    1-2 hours (tsconfig, build pipeline)
  Per-file cost:    Typing annotations adds ~10-20% more code
                    (recovered quickly via better tooling)
  Learning curve:   Basic TypeScript: 1-2 days
                    Advanced types: weeks of practice
  Build time:       tsc adds 5-30s; mitigated by esbuild for dev
  Third-party:      @types/* packages usually available
                    but may lag or be incorrect for edge cases

ECOSYSTEM ALIGNMENT:

  TypeScript-first frameworks (expect TypeScript):
    Angular, NestJS, Deno (built-in TS support)

  Strong TypeScript support (first-class):
    Next.js, Remix, Vite, tRPC, Prisma, Drizzle ORM,
    Zod, React (with @types/react)

  JavaScript with types via @types/:
    Lodash, Express, Node.js (all have @types/* packages)

  JavaScript-only (no official types):
    Rare in modern ecosystem (most have community @types/)
```

**Why it matters:**

Making the wrong choice has compounding costs. A TypeScript-heavy
codebase for a one-off script wastes time. A JavaScript codebase for
a 3-year product has escalating maintenance costs as the team grows.
Understanding the trade-off enables the right choice.

**Mental model:**

> TypeScript vs JavaScript is like the difference between building
> a temporary pop-up shop and a permanent store. The pop-up doesn't
> need a building permit (compilation), proper wiring (type system),
> or a lease (long-term maintenance). But if you want the business
> to run for 5 years with 10 employees, you invest in the proper
> infrastructure.

**Scale behavior:**

TypeScript's value scales with codebase size and team size. The
annotation overhead is roughly constant per-file; the refactoring
safety value grows with codebase size (more code to refactor) and
team size (more engineers who might break things accidentally).

---

### 💻 Code Example

**Trade-off demonstration in API client code**

```javascript
// JAVASCRIPT API CLIENT: flexible, less safe
// No types: fast to write, risky to maintain
class ApiClient {
  constructor(baseUrl) {
    this.baseUrl = baseUrl;
  }

  async get(path) {
    const response = await fetch(`${this.baseUrl}${path}`);
    return response.json();
    // Returns: any (unknown shape)
  }
}

const client = new ApiClient('https://api.example.com');
const user = await client.get('/users/1');
console.log(user.profle.email);
// Runtime error: 'profle' (typo) is undefined
// Discovered in production or testing

// TYPESCRIPT API CLIENT: safer, more verbose
interface GetResponse<T> {
  data: T;
  status: number;
}

interface User {
  id: number;
  profile: { email: string; name: string };
}

class ApiClient {
  constructor(private baseUrl: string) {}

  async get<T>(path: string): Promise<GetResponse<T>> {
    const response = await fetch(`${this.baseUrl}${path}`);
    const data = await response.json() as T;
    return { data, status: response.status };
  }
}

const client = new ApiClient('https://api.example.com');
const { data: user } = await client.get<User>('/users/1');
console.log(user.profle.email);
// Error: Property 'profle' does not exist on type 'User'
// Error: Did you mean 'profile'? (VS Code suggests fix)
// Caught at compile time, not in production
```

> **Code walkthrough:** The JavaScript version returns untyped data
> from the API. The `user.profle` typo only surfaces at runtime, when
> real users hit the code. The TypeScript version uses generics
> (`get<T>(path: string): Promise<GetResponse<T>>`) to make the API
> client typed for any shape the caller specifies. The `user.profle`
> typo is caught immediately at development time. The cost: ~15 extra
> lines for the types (interface declarations). The benefit: this typo
> (and all similar ones) are caught before the code is merged. For a
> codebase with 100 API calls, this pattern prevents a class of bugs
> entirely.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> TypeScript is better for large, long-lived projects. It costs more
> upfront (compilation, type annotations) but saves time by catching
> bugs early and enabling safer refactoring. JavaScript is fine for
> small scripts and prototypes where the overhead isn't worth it.

**Senior / Staff:**

> The TypeScript vs JavaScript decision is largely settled for new
> production projects: TypeScript is the right choice unless there are
> specific constraints (time-critical prototype, team has no TS
> experience). The key insight: TypeScript's costs are front-loaded
> (initial annotation, learning curve), while the benefits compound
> over time (every bug prevented, every safe refactor). The break-even
> point is typically 2-4 weeks for a medium-sized project. The true
> cost of JavaScript in large codebases is not visible until it
> manifests as: "we can't refactor that module because we don't know
> all the callers" or "we had a production outage because someone
> passed a string where a number was expected."

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword - trade-off is described as prose above)*

---

### 📊 Diagram

*(Omit: trade-off is a decision matrix, fully described in text)*

---

### ⚠️ Common Misconceptions

**"TypeScript is a different language"**

TypeScript is a superset of JavaScript. All valid JavaScript is valid
TypeScript. You can rename any `.js` file to `.ts` and it will
(mostly) compile with TypeScript's default settings. The types you
add are erased at compile time. The output is standard JavaScript.
TypeScript doesn't introduce new runtime constructs (except for a
few legacy features like `const enum` and decorators with
`emitDecoratorMetadata`).

---

### 🚨 Failure Modes and Diagnosis

**TypeScript provides false confidence (type assertions mask runtime errors):**

```typescript
// SYMPTOM: TypeScript codebase still crashes with type errors at runtime
// CAUSE: overuse of 'as' type assertions with external data

// BAD: 'as' is a promise to TypeScript, not a runtime guarantee
async function getUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return data as User;  // DANGEROUS: what if API returns error JSON?
  // { error: "User not found" } is cast to User without verification
  // user.name will be undefined at runtime
}

// DIAGNOSIS: look for 'as Type' with external data sources
// FIX: validate external data with Zod
import { z } from 'zod';
const UserSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
});
type User = z.infer<typeof UserSchema>;  // Type from schema

async function getUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return UserSchema.parse(data);  // Throws if data is wrong shape
}
// Now: wrong API response -> immediate error with clear message
// Not: undefined.name crash 10 lines later
```

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| TypeScript vs JavaScript for new project | 2-3 min | Scale decision |
| TypeScript for small script? | 1-2 min | Cost vs benefit |
| Runtime validation still needed? | 2-3 min | Zod/io-ts |
| any vs unknown in practice | 2-3 min | Safety levels |
| Breaking change handling | 2-3 min | Type guards |
| JSDoc as TypeScript alternative | 2-3 min | Use cases |
| TypeScript strict mode decision | 2-3 min | When to enable |

---

**Q1: Should every project use TypeScript?** `[SENIOR]` DECISION

> **Answer:**
>
> No. TypeScript's benefits are proportional to codebase complexity
> and team size. For small scripts, one-off tools, or solo projects
> under 500 lines, the overhead (compilation, annotation) is not
> justified by the benefits.
>
> **Use TypeScript:** new product teams, shared libraries, complex
> domain logic, Angular/NestJS (where it's expected), any project
> expected to live > 6 months with > 2 engineers.
>
> **JavaScript may be sufficient:** deployment scripts (< 50 lines),
> one-off data migrations, proof-of-concept demos, projects where
> the team has zero TypeScript experience and delivery timeline is short.
>
> *What separates good from great:* The decision is NOT "do I know
> TypeScript?" but "will TypeScript's safety properties pay for their
> overhead in this context?" For an experienced team, TypeScript adds
> minimal overhead (types flow naturally as you code). For a team
> learning TypeScript while shipping a deadline-driven project, the
> learning curve overhead can slow initial delivery. The nuanced answer:
> learn TypeScript separately from delivery pressure; once learned,
> use it by default for production projects.

**Q2: What are the hidden costs of NOT using TypeScript in a growing
codebase?** `[STAFF]` DECISION

> **Answer:**
>
> The costs compound as the codebase grows:
>
> **Refactoring risk**: renaming a function in JavaScript requires
> grep/regex + test coverage + careful code review. With a 10K-line
> codebase, this is manageable. With 100K lines, it's dangerous. Teams
> develop "if it works, don't touch it" culture - technical debt
> accumulates because safe refactoring is too expensive.
>
> **Onboarding friction**: new engineers must read source code to
> understand function signatures. In TypeScript, function types are
> immediately visible in the IDE. In JavaScript, you read the function
> body, look at call sites, or hope there's documentation. For a 10-person
> team, this is 10x the onboarding friction.
>
> **Runtime errors in production**: a category of errors (type mismatches,
> property access on undefined) that TypeScript eliminates as a class
> continue to appear in production JavaScript. Each requires: bug report,
> reproduction, debugging, fix, deploy. TypeScript prevention cost:
> 0. JavaScript fix cost: 2-4 hours per incident.
>
> **Test coverage gap**: teams compensate for missing type safety by
> writing more tests. Tests have overhead (maintenance, run time). TypeScript
> doesn't replace tests, but it eliminates the need for tests that
> only verify type correctness.
>
> *What separates good from great:* The JavaScript hidden costs are
> invisible until a threshold is crossed. Below ~20K lines with a
> stable team, JavaScript is fine. Above that threshold, the costs
> compound until they dominate engineering velocity. The signal:
> when your sprint review shows recurring "that bug shouldn't have
> happened" or "we needed 3 people to safely change one function" -
> that's the JavaScript scaling pain manifesting.

---

---

# TypeScript Tooling Ecosystem

🎯 **Interview Weight:** foundational (★☆☆) - understanding the TypeScript
toolchain is prerequisite to working effectively in TypeScript projects

---

### 🎯 Model Answer

**30 seconds:**

> The TypeScript tooling ecosystem consists of: `tsc` (the TypeScript
> compiler for type-checking), `ts-node` (execute TypeScript in Node.js
> directly), transpilers (esbuild, swc, Babel) for fast compilation
> without type-checking, bundlers (Webpack, Vite, esbuild) that
> integrate TypeScript, and language server (TypeScript Language
> Service) that powers IDE features in VS Code and other editors.

**3 minutes:**

> Key tools by role:
> - **tsc**: official compiler. Does type checking + emits JS. Slowest
>   but most accurate.
> - **esbuild**: ultra-fast transpiler (no type checking). Used for
>   dev builds and test runners. 10-100x faster than tsc.
> - **swc**: Rust-based TypeScript transpiler. Used by Next.js, Vite.
> - **ts-node / tsx**: run .ts files directly in Node.js (dev/scripts)
> - **@typescript-eslint**: ESLint plugin for TypeScript-specific linting
> - **Prettier**: code formatting (TypeScript aware)
> - **dtslint / @microsoft/api-extractor**: for library authors validating type definitions

**Blank Mind Recovery:**

**(1) Restate:** "TypeScript toolchain: tsc (compiler + type check),
esbuild/swc (fast transpile, no type check), ts-node (run .ts in Node),
TypeScript Language Server (IDE features), @typescript-eslint (lint rules).
Production pattern: esbuild for speed, tsc for CI type checking."

---

### 📘 Concept Explanation

**What it is:**

The TypeScript tooling ecosystem is the collection of compilers,
transpilers, linters, formatters, and IDE integrations that make
TypeScript productive in development and build pipelines.

**The problem it solves:**

TypeScript's official compiler (`tsc`) is powerful but slow for large
codebases. The ecosystem provides specialized tools for different
needs: fast compilation for hot reloading, type-only checking for CI,
IDE integration for real-time feedback.

**How it works:**

```
TYPESCRIPT TOOLCHAIN ROLES:

  Development:
  ┌─────────────────────────────────────────┐
  │  VS Code + TypeScript Language Server   │
  │  Real-time: type errors, autocomplete,  │
  │  go-to-def, find references             │
  └─────────────────────────────────────────┘
                    │
  ┌─────────────────────────────────────────┐
  │  tsx / ts-node                          │
  │  Run .ts files directly in Node.js      │
  │  No separate compile step               │
  └─────────────────────────────────────────┘

  Build (Fast Path):
  ┌─────────────────────────────────────────┐
  │  esbuild or swc                         │
  │  Transpile-only (strip types -> JS)     │
  │  10-100x faster than tsc               │
  │  Used by: Vite, Next.js, Vitest        │
  └─────────────────────────────────────────┘

  Build (Type Check Path - CI):
  ┌─────────────────────────────────────────┐
  │  tsc --noEmit                           │
  │  Type check only (no JS output)         │
  │  Authoritative: all type errors caught  │
  │  Run in CI, not local hot reload        │
  └─────────────────────────────────────────┘

  Linting:
  ┌─────────────────────────────────────────┐
  │  ESLint + @typescript-eslint/parser     │
  │  TypeScript-aware rules:                │
  │  no-explicit-any, no-unsafe-assignment  │
  │  await-thenable, prefer-nullish-coalescing│
  └─────────────────────────────────────────┘

TSCONFIG KEY OPTIONS:

  {
    "compilerOptions": {
      "target": "ES2020",     // What JS to emit
      "module": "ESNext",     // Module system in output
      "lib": ["ES2020","DOM"],// Type definitions to include
      "strict": true,         // All strict checks
      "noEmit": true,         // Type check only (for tsc in CI)
      "outDir": "./dist",     // Where to emit JS
      "rootDir": "./src",     // Source root
      "paths": {              // Module aliases
        "@/*": ["./src/*"]
      },
      "incremental": true,    // Cache for faster subsequent builds
      "composite": true,      // For project references (monorepo)
    }
  }

MONOREPO TYPESCRIPT:

  Project References (tsc --build):
    Each package has tsconfig.json with "references" to deps
    tsc builds only changed packages and their dependents
    Dramatically faster for monorepo builds

  Example:
    packages/
      api/tsconfig.json:
        { "references": [{ "path": "../shared" }] }
      shared/tsconfig.json:
        { "composite": true }  // required for referenced packages
```

**Why it matters:**

Understanding the toolchain is required to: configure build pipelines,
debug compilation errors, choose the right tool for each step, and
optimize build performance in CI/CD.

**Mental model:**

> The TypeScript toolchain is a pipeline where different tools specialize
> in different tasks. The "type checker" (tsc) is like a quality inspector
> who catches defects. The "transpiler" (esbuild) is like a fast
> production line worker who assembles products. The "language server"
> is like a real-time assistant giving you feedback as you work.
> Using the specialist for each task is faster and more reliable than
> using one generalist tool for everything.

**Scale behavior:**

As a TypeScript codebase grows, build times grow. Mitigation: `incremental`
compilation (caches .tsbuildinfo), project references (monorepo), and
parallel type checking (tsc-multi). The fastest CI setup: esbuild for
application build (1-5s), tsc --noEmit for type checking (run in parallel).

---

### 💻 Code Example

**Practical tsconfig for a Node.js + React monorepo**

```json
// Root tsconfig.base.json (shared settings):
{
  "compilerOptions": {
    "strict": true,
    "target": "ES2022",
    "moduleResolution": "bundler",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "declaration": true,
    "declarationMap": true,
    "incremental": true
  }
}

// React app: tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "noEmit": true,
    "jsx": "react-jsx"
  },
  "include": ["src"]
}

// Node.js service: tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "lib": ["ES2022"],
    "module": "CommonJS",
    "outDir": "./dist",
    "composite": true
  },
  "include": ["src"],
  "references": [
    { "path": "../shared" }
  ]
}
```

> **Code walkthrough:** `tsconfig.base.json` centralizes shared compiler
> options so all packages benefit from `strict: true` and consistent
> settings without duplication. The React app uses `noEmit: true` because
> Vite handles the transpilation (tsc is only for type checking). The
> Node.js service uses `composite: true` and `references` for project
> references - this tells `tsc --build` to track dependencies between
> packages, only rebuilding a package when its source or a referenced
> package changes. `skipLibCheck: true` speeds up compilation by skipping
> `.d.ts` file checking (rarely useful to type-check library types you
> don't control).

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> The TypeScript toolchain includes: `tsc` for type checking and
> compilation, `ts-node` for running TypeScript directly in Node.js,
> and the TypeScript Language Server that powers VS Code's IntelliSense.
> Modern build tools like Vite use esbuild for fast transpilation.
> ESLint with `@typescript-eslint` adds TypeScript-specific lint rules.

**Senior / Staff:**

> TypeScript tooling choices have major impact on developer experience
> and CI performance. The key architectural decision: separate "type
> checking" from "transpilation." esbuild/swc handle transpilation in
> < 1s; tsc handles type checking in 5-30s. Running these in parallel
> in CI gives you: fast application build + thorough type safety.
> For monorepos: project references with `tsc --build` provide incremental
> type checking - only changed packages are rechecked. The `incremental`
> flag caches type information between runs; `.tsbuildinfo` files must
> be cached in CI (same as node_modules caching). The most impactful
> CI optimization for TypeScript monorepos: parallel `tsc --noEmit`
> per package with task orchestration (Turborepo, Nx).

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword - tooling overview, no comparison needed)*

---

### 📊 Diagram

*(Omit: toolchain pipeline fully described with ASCII in Concept Explanation)*

---

### ⚠️ Common Misconceptions

**"tsc and esbuild/swc do the same thing"**

`tsc` performs type checking AND transpilation. esbuild and swc ONLY
transpile (strip types and compile to JavaScript) - they do NOT perform
type checking. Using esbuild alone for a TypeScript build means
NO type errors are caught. Production setup: use esbuild for fast
transpilation AND run `tsc --noEmit` separately for type checking.
This is why many CI pipelines have two separate steps: "build" (esbuild)
and "typecheck" (tsc).

---

### 🚨 Failure Modes and Diagnosis

**tsc and runtime behavior diverge (skipLibCheck hides real issues):**

```typescript
// SYMPTOM: tsc passes but runtime crashes with type-related error
// CAUSE: using skipLibCheck: true without understanding the trade-off

// skipLibCheck skips type-checking of .d.ts files (library types)
// This speeds up compilation but can miss type errors in library usage

// EXAMPLE: library has incorrect types
// some-library's types say: function getValue(): string
// But actual library returns: string | null
// With skipLibCheck: true -> this passes:
const val = getValue();
console.log(val.toUpperCase());  // Runtime crash if getValue() returns null
// Without skipLibCheck: would fail to compile if types were correct

// DIAGNOSIS:
// Run tsc without skipLibCheck on failing file:
// tsc --noSkipLibCheck src/problem-file.ts
// Look for underlying type errors that were masked

// BETTER PATTERN: use skipLibCheck only in specific package types
// Keep it enabled for most builds (performance), but understand
// it creates a gap between compile-time and runtime behavior
```

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| tsc vs esbuild difference | 2-3 min | Type check vs transpile |
| Configure TypeScript for Node.js | 2-3 min | module: CommonJS |
| Configure TypeScript for React | 2-3 min | jsx, DOM lib |
| Monorepo TypeScript setup | 3-4 min | Project references |
| incremental compilation | 2-3 min | .tsbuildinfo |
| @typescript-eslint rules | 2-3 min | Type-aware lint |
| Declaration files (.d.ts) | 2-3 min | Library types |

---

**Q1: What is the TypeScript Language Server and how does it work?**
`[MID]` MECHANISM

> **Answer:**
>
> The TypeScript Language Server (tsserver) is a long-running process
> that provides IDE features by maintaining an up-to-date type model
> of your entire codebase in memory.
>
> It implements the Language Server Protocol (LSP) - a standard
> interface between editors and language tooling. VS Code (and other
> editors) communicate with tsserver via JSON-RPC messages.
>
> What it provides:
> - **Autocomplete**: as you type `user.`, it returns all valid properties
> - **Hover information**: hovering a variable shows its inferred type
> - **Go-to-definition**: Cmd+Click jumps to where a symbol is defined
> - **Find all references**: shows every usage of a symbol
> - **Rename symbol**: renames across all files safely
> - **Real-time errors**: red squiggles as you type (before saving)
>
> ```
> COMMUNICATION FLOW:
>
>   VS Code (editor)
>     │
>     │ LSP: didChange (file updated)
>     ▼
>   tsserver (Language Server, in background)
>     │
>     │ Re-type-checks affected files
>     │ Generates new diagnostics
>     │
>     ▼
>   VS Code (editor)
>     │ LSP: publishDiagnostics (error list)
>     ▼
>   Shows red squiggles in editor
> ```
>
> *What separates good from great:* The Language Server is why TypeScript
> files in VS Code have dramatically better IDE experience than
> JavaScript. Because the Language Server has a complete type model,
> autocompletion is EXACT (not fuzzy/heuristic). "Go to definition"
> works cross-file and cross-package (using source maps for packages
> with `declarationMap: true`). For engineers: tsserver memory usage
> (1-2GB for large codebases) is normal. Restarting tsserver
> (`Cmd+Shift+P -> TypeScript: Restart TS Server`) fixes most stale
> state issues without reloading VS Code.

**Q2: What are TypeScript declaration files (.d.ts) and when do you
create them?** `[SENIOR]` MECHANISM

> **Answer:**
>
> `.d.ts` files are TypeScript type declaration files. They contain
> type information ONLY (no JavaScript code). They describe the shape
> of a JavaScript module to TypeScript consumers.
>
> Three scenarios:
>
> 1. **Third-party JavaScript libraries**: `@types/lodash` is a package
>    of `.d.ts` files that describe lodash's types. Lodash itself is
>    JavaScript. TypeScript users install `@types/lodash` to get type
>    safety when using lodash.
>
> 2. **Compiled TypeScript libraries**: when you publish a TypeScript
>    library with `declaration: true`, tsc generates `.d.ts` files
>    alongside the compiled `.js`. Consumers get types automatically
>    without `@types/`.
>
> 3. **Manual declaration files**: for JavaScript code you can't modify
>    (legacy files, vendor scripts), you write `module.d.ts` to tell
>    TypeScript what the module exports.
>
> ```typescript
> // GENERATED .d.ts (from tsc with declaration: true):
>
> // Source (mathUtils.ts):
> export function add(a: number, b: number): number {
>   return a + b;
> }
>
> // Generated (mathUtils.d.ts):
> export declare function add(a: number, b: number): number;
> // No implementation. Just type information.
>
> // MANUAL .d.ts for JavaScript library (legacyLib.js):
> // File: legacyLib.d.ts
> declare module 'legacyLib' {
>   export function doSomething(input: string): void;
>   export const VERSION: string;
> }
> // TypeScript now knows the shape of 'legacyLib'
> ```
>
> *What separates good from great:* The `DefinitelyTyped` repository
> (`@types/*` packages on npm) contains hand-maintained TypeScript
> definitions for thousands of JavaScript packages that don't bundle
> their own types. When a library you use doesn't have types, you can
> contribute to DefinitelyTyped. But the better long-term solution:
> library authors moving to TypeScript-native (bundling `.d.ts`) so
> types are always in sync with the implementation. Type drift (when
> `@types/foo` describes an older version of `foo`) causes subtle
> bugs that are hard to diagnose.

**Q3: How do you configure TypeScript for different environments
(browser vs Node.js vs Deno)?** `[SENIOR]` SYSTEM-DESIGN

> **Answer:**
>
> Each environment has different global APIs available. TypeScript's
> `lib` compiler option specifies which type definitions to include.
>
> ```json
> // Browser app (React, Vue):
> {
>   "compilerOptions": {
>     "target": "ES2020",
>     "module": "ESNext",
>     "lib": ["ES2020", "DOM", "DOM.Iterable"],
>     // DOM: window, document, fetch, etc.
>     // DOM.Iterable: NodeList.forEach, etc.
>     "moduleResolution": "bundler",
>     // bundler: for Vite/webpack (supports package.json exports)
>     "jsx": "react-jsx"
>   }
> }
>
> // Node.js service:
> {
>   "compilerOptions": {
>     "target": "ES2022",
>     "module": "Node16",
>     // Node16: supports both CJS and ESM Node.js modules
>     "lib": ["ES2022"],
>     // NO DOM: Node.js has no window, document
>     "moduleResolution": "node16",
>     "outDir": "./dist"
>   }
> }
> // Install @types/node for Node.js built-in types:
> // npm install -D @types/node
>
> // Deno:
> // Deno has built-in TypeScript support (no separate build step)
> // Uses Web standard APIs + Deno namespace
> // No tsconfig needed for basic usage; Deno infers from deno.json
> // @types/node NOT needed (Deno doesn't use Node.js APIs)
>
> // Universal library (browser + Node.js):
> {
>   "compilerOptions": {
>     "target": "ES2020",
>     "module": "ESNext",
>     "lib": ["ES2020"],
>     // Only ESNext lib: no DOM, no Node.js
>     // Consumers (browser or Node.js) add their own env types
>     "declaration": true,
>     "composite": true
>   }
> }
> ```
>
> *What separates good from great:* The `module` and `moduleResolution`
> options are the most confusing tsconfig settings. They must align:
> `module: "Node16"` requires `moduleResolution: "node16"`.
> `module: "ESNext"` for bundlers needs `moduleResolution: "bundler"`
> (TypeScript 5.0+). Using wrong combinations causes cryptic import
> errors. The `moduleResolution: "bundler"` option was added in
> TypeScript 5.0 specifically for bundler environments (Vite, webpack)
> where Node.js's resolution rules don't apply (bundlers support
> package.json `exports` field which `node10` resolution ignores).
