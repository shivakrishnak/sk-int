---
layout: default
title: "TypeScript - META Patterns"
parent: "TypeScript"
nav_order: 13
permalink: /typescript/meta-patterns/
---

# TypeScript Decision Framework

---

### 🎯 Model Answer

**30 seconds:**

> TypeScript decisions: use `unknown` not `any` for external data,
> `interface` for extendable object shapes, `type` for unions/
> intersections/primitives, `class` when you need runtime behavior
> (instances, decorators), and `const` assertions with `satisfies`
> for typed configuration objects. Enable `strict: true` from day
> one. Add `noUncheckedIndexedAccess` for array safety.

**3 minutes:**

TypeScript has multiple ways to express most concepts. Choosing
the right tool requires understanding trade-offs:

**`type` vs `interface`**: Use `interface` for object shapes that
may be extended or merged (especially for public API contracts).
Use `type` for everything else: unions, intersections, mapped types,
conditional types, primitives, tuples. Practical rule: start with
`interface` for objects, `type` for everything else.

**`any` vs `unknown`**: Never use `any` for new code. `unknown` is
the correct type for "I don't know what this is yet" - it requires
narrowing before use, making the uncertainty explicit. `any` silently
spreads type unsafety through the codebase.

**`class` vs `interface` vs `type`**: Use `class` only when you
need runtime behavior: constructors, methods, `instanceof` checks,
decorators, or metadata. For pure data shapes, use `interface` or
`type`. Classes generate JavaScript code; interfaces and types are
erased.

**`enum` vs string union**: String unions (`type Status = 'active'
| 'inactive'`) are preferred over `enum` in most cases. String
unions are: simpler, tree-shakeable, have no runtime presence (enums
do), and work with `isolatedModules`. Use `const enum` never with
`isolatedModules`, regular `enum` only when you need iteration or
reverse mapping.

**`strict: true` always**: The strict bundle (`noImplicitAny`,
`strictNullChecks`, `strictFunctionTypes`, `strictPropertyInitialization`)
catches the most bugs. Add from day one; retrofitting is expensive.

**Blank Mind Recovery:**

**(1) Key choices:** "unknown not any. interface for extendable objects,
type for unions. class only for runtime. string union over enum.
strict: true always."

**(2) Memory:** "If you use any, you're writing JavaScript. If you
use unknown, you're writing TypeScript."

---

### 📘 Concept Explanation

**What it is:**

A structured framework for making TypeScript design decisions
consistently - which constructs to use, when, and why.

**The problem it solves:**

TypeScript has multiple ways to express similar concepts. Without
a framework, teams make inconsistent choices that accumulate as
confusion and maintenance overhead.

**Decision rules:**

```
type vs interface:
  interface -> extendable object shapes, declaration merging,
               public API contracts, OOP-style hierarchies
  type      -> unions (A | B), intersections (A & B),
               mapped types, conditional types, tuples,
               aliases for primitives and functions

any vs unknown:
  any     -> NEVER for new code; use only in migration
  unknown -> external data (API responses, JSON.parse, user input)

class vs interface vs type:
  class     -> need instances, instanceof, decorators, DI tokens
  interface -> extendable shape, declaration merging
  type      -> everything else

enum vs string union:
  string union ('a' | 'b') -> most cases (tree-shakeable, no runtime)
  enum                      -> need iteration, reverse mapping,
                               numeric ordering
  const enum               -> NEVER with isolatedModules

Nullability:
  T | null    -> can be null (explicit null as value)
  T | undefined -> can be missing (optional property or param)
  T?          -> shorthand for T | undefined (optional param)

Generic constraints:
  <T extends object>  -> T must be an object
  <T extends string>  -> T must be a string (string literal types)
  <T extends keyof U> -> T must be a key of U
```

---

### 💻 Code Example

**Example (Wrong vs Right) - Common decision mistakes:**

```typescript
// BAD: Using 'any' for external data
async function fetchUser(id: string): Promise<any> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}

// GOOD: Using Zod + inferred type
import { z } from 'zod';
const UserSchema = z.object({ id: z.string(), name: z.string() });
type User = z.infer<typeof UserSchema>;

async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return UserSchema.parse(data); // validated + typed
}

// BAD: enum when string union is simpler
enum Direction { Up = 'UP', Down = 'DOWN' }

// GOOD: string union (no runtime code, tree-shakeable)
type Direction = 'UP' | 'DOWN';

// BAD: class when interface suffices
class UserConfig {
  constructor(
    public host: string,
    public port: number
  ) {}
}

// GOOD: interface (zero runtime overhead)
interface UserConfig {
  host: string;
  port: number;
}
```

> **Code walkthrough:** The three examples show the most common
> TypeScript decision mistakes. Using `any` for API responses
> silently removes all type safety for the function's callers. String
> unions compile to nothing (pure types, zero JS), while enums compile
> to a runtime object with a reverse mapping table - unnecessary
> overhead for most use cases. Classes generate constructor functions
> in the compiled JavaScript output; when you only need a type
> annotation for a data shape, an interface is the right choice.

---

### ⚖️ Comparison Table

| Decision | Prefer | When to use the other |
|---|---|---|
| any vs unknown | `unknown` always | `any`: only in migration |
| type vs interface (object) | `interface` | `type`: unions, mapped, conditional |
| class vs interface | `interface` | `class`: need instances/DI |
| enum vs string union | String union | `enum`: iteration/reverse map |
| readonly vs Object.freeze | Both | Security-critical: `Object.freeze` |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I use `interface` for extendable object shapes and `type` for
> unions and more complex type expressions. I never use `any` - I use
> `unknown` for data from external sources. String unions are simpler
> than enums for most cases.

**Senior / Staff:**

> TypeScript decisions are about making the type system's intent
> explicit. `unknown` forces the reader to see that the type is
> uncertain and will be narrowed. `interface` signals extensibility.
> `class` signals runtime presence. String unions over enums signals
> no runtime overhead. I enforce these via ESLint rules
> (`@typescript-eslint/no-explicit-any`, `@typescript-eslint/ban-types`)
> so the team's decisions are consistent without requiring review
> comments.

---

### ⚠️ Common Misconceptions

**Misconception: `interface` and `type` are always interchangeable.**

For object shapes, they are mostly equivalent. But only `interface`
supports declaration merging (critical for module augmentation and
`@types/` packages). Only `type` supports unions, intersections, and
complex type operations. Using `interface` for a union type is not
possible.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `any` silently spreading through codebase.**

Symptom: Type coverage metrics show increasing `any` count.

Fix: ESLint `@typescript-eslint/no-explicit-any: error` for all new
TypeScript files; enforce in CI from day one.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| `type` vs `interface` - when to use each? | Comparison | ★★☆ | 2 min |
| `any` vs `unknown` - difference? | Comparison | ★★☆ | 2 min |
| `enum` vs string union | Comparison | ★★☆ | 2 min |
| When to use `class` vs `interface`? | Decision | ★★☆ | 2 min |
| TypeScript tsconfig strict options | Definition | ★★☆ | 2 min |
| How to enforce decisions at team scale? | Design | ★★★ | 3 min |
| TypeScript vs JavaScript decision criteria | Decision | ★★☆ | 2 min |

**Q: When would you use `type` vs `interface` in TypeScript?**

A: The practical rule: `interface` for extendable object shapes,
`type` for everything else.

Use `interface`:
- Object shapes that might be extended or implemented by classes
- Public API contracts (libraries, module exports)
- Cases where declaration merging is needed (augmenting `Window`,
  `global`, React component props via module augmentation)

Use `type`:
- Unions: `type Result<T> = { ok: true; value: T } | { ok: false; error: Error }`
- Intersections: `type Admin = User & { role: 'admin' }`
- Mapped types: `type Partial<T> = { [K in keyof T]?: T[K] }`
- Conditional types: `type NonNull<T> = T extends null ? never : T`
- Primitive aliases: `type UserId = string & { __brand: 'UserId' }`
- Function signatures: `type Handler = (req: Request) => Response`
- Tuples: `type Pair<A, B> = [A, B]`

The one practical difference: interfaces support declaration merging.
This is critical for `@types/` packages that augment existing
interfaces. For application code, the choice is mostly stylistic.

*What separates good from great:* Consistency. Pick a convention
(`interface` for objects, `type` for the rest) and enforce it via
ESLint's `@typescript-eslint/consistent-type-definitions` rule. The
wrong choice is inconsistency - using both interchangeably in the
same codebase creates cognitive overhead for no benefit.

---

# Type-Driven Development

---

### 🎯 Model Answer

**30 seconds:**

> Type-Driven Development (TDD with types) means writing the types
> first, then the implementation. Start with the domain types, define
> function signatures, then implement. The type signature is the
> specification. If the implementation compiles, it satisfies the
> contract. This eliminates entire categories of integration bugs
> because the type checker verifies the contracts before any code
> runs.

**Blank Mind Recovery:**

**(1) Restate:** "Types first, implementation second. Type signature
= specification. Compiler verifies contracts."

**(2) Example:** "Define User, Order, Cart types. Define
addToCart(cart: Cart, item: OrderItem): Cart signature. Implement.
The type checker proves the signature is satisfied."

---

### 📘 Concept Explanation

**What it is:**

Type-Driven Development is a design methodology where types are
written before implementation, using the type system as a design tool
to model the problem domain before writing a single line of logic.

**The problem it solves:**

Implementation-first code often discovers type mismatches at
integration time. Type-first code makes mismatches visible during
design, before any code is written.

**How it works:**

```
TDD with types - process:

  Step 1: Model the domain in types
    type User = { id: UserId; name: string; role: Role };
    type Role = 'admin' | 'viewer' | 'editor';
    type Permission = 'read' | 'write' | 'delete';

  Step 2: Define function signatures (not implementation)
    declare function canAccess(
      user: User,
      resource: Resource,
      action: Permission
    ): boolean;

  Step 3: Use the declared functions in calling code
    // TypeScript verifies the call sites type-check
    // even before the implementation exists

  Step 4: Implement (fill in the declare function bodies)
    function canAccess(...): boolean { ... }

  Compiler as contract verifier:
    If the implementation compiles:
      It returns the declared type
      It accepts the declared parameters
    Integration bugs caught at step 3, not at runtime
```

**Key practices:**

- Use `declare function` for design-time stubs
- Use `never` as return type for functions that should not be called
- Use discriminated unions to model all valid states
- Design error types explicitly (not just `throws Error`)

---

### 💻 Code Example

**Example (Production) - Type-first API design:**

```typescript
// Step 1: Domain types
type UserId = string & { __brand: 'UserId' };
type ResourceId = string & { __brand: 'ResourceId' };

type Permission = 'read' | 'write' | 'delete';
type Role = 'admin' | 'viewer' | 'editor';

interface User {
  id: UserId;
  name: string;
  role: Role;
}

interface Resource {
  id: ResourceId;
  ownerId: UserId;
  public: boolean;
}

// Step 2: Function signatures (the contract)
// Define before implementing - TypeScript checks all call sites
declare function canAccess(
  user: User,
  resource: Resource,
  action: Permission
): boolean;

declare function auditLog(
  userId: UserId,
  resourceId: ResourceId,
  action: Permission,
  granted: boolean
): Promise<void>;

// Step 3: Use the types in calling code
// TypeScript verifies call sites even before implementation:
async function handleRequest(
  user: User,
  resource: Resource,
  action: Permission
): Promise<{ granted: boolean }> {
  const granted = canAccess(user, resource, action);
  await auditLog(user.id, resource.id, action, granted);
  return { granted };
}

// Step 4: Implement
function canAccess(
  user: User,
  resource: Resource,
  action: Permission
): boolean {
  if (user.role === 'admin') return true;
  if (resource.public && action === 'read') return true;
  if (resource.ownerId === user.id) return true;
  return false;
}
```

> **Code walkthrough:** The `declare function` statement defines the
> contract without implementation. TypeScript immediately verifies all
> call sites against the declared types. This enables parallel work:
> one developer implements `canAccess` while another writes
> `handleRequest` - both compiling against the same contract. When
> the implementation is filled in, TypeScript verifies it satisfies
> the declared signature. Integration bugs that would appear at
> runtime in an untyped codebase are surfaced at compile time as soon
> as either the signature or the call site deviates.

---

### ⚖️ Comparison Table

| Approach | When bugs found | Test needed | Iteration speed |
|---|---|---|---|
| Runtime types | Runtime | Yes | Slow |
| Test-first TDD | Test run | Yes | Medium |
| Type-driven development | Compile time | Fewer | Fast |
| Formal verification | Proof | No | Slow |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I write the types first to design the function interface before
> implementing it. If the type checker is happy with my call sites,
> I know the integration will work. This is especially useful for
> functions that will be called from multiple places.

**Senior / Staff:**

> Type-Driven Development uses the compiler as a design tool. By
> writing domain types and function signatures first, you force
> yourself to think about the problem structure before writing logic.
> `declare function` stubs let you validate call sites before the
> implementation exists - enabling parallel development. Complex
> domain operations are modeled as types: the return type of
> `withdraw(account: Account, amount: Money)` should be
> `Result<Account, InsufficientFundsError | AccountFrozenError>`
> not `Account | null`. The error conditions are in the type, not
> the documentation.

---

### ⚠️ Common Misconceptions

**Misconception: Type-Driven Development replaces unit tests.**

Types prove structural contracts; tests prove behavioral correctness.
`canAccess(admin, resource, 'delete')` returning `boolean` is the
type contract. That it returns `true` for admin users is a behavioral
assertion that requires a test.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Types modeled too narrowly, blocking valid refactoring.**

Symptom: Adding a new valid state (new `Role` value) requires changes
in many files.

Cause: Discriminated unions are exhaustively switched everywhere.

Fix: This is a feature, not a bug. Exhaustiveness checking is why
you use discriminated unions. But if a type needs to be extensible,
use an interface hierarchy rather than a discriminated union.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is Type-Driven Development? | Definition | ★★☆ | 2 min |
| Types vs tests - what do each prove? | Comparison | ★★★ | 3 min |
| Design an API contract with types | Design | ★★★ | 5 min |
| When do types replace documentation? | Trade-off | ★★☆ | 2 min |
| `declare function` - what is it for? | Mechanism | ★★☆ | 1 min |
| Error types in function signatures | Design | ★★★ | 3 min |
| Making invalid states unrepresentable | Mechanism | ★★★ | 3 min |

**Q: What can types prove that tests cannot? What can tests prove
that types cannot?**

A: Types and tests are complementary verification tools.

Types prove:
- Structural contracts: function signatures, property existence
- Exhaustiveness: all union cases are handled
- Impossible states: discriminated unions prevent invalid combinations
- Composition safety: functions compose correctly type-wise
- These proofs apply to ALL inputs, not a subset of tested cases

Tests prove:
- Behavioral correctness: `canAccess(admin, res, 'delete') === true`
- Edge cases: empty lists, zero values, boundary conditions
- Integration: that two components work together at runtime
- Performance: response time under load
- These require execution with specific inputs

Practical boundary:
- Type check: `addToCart(cart: Cart, item: Item): Cart` - correct
  signature composition
- Test: `addToCart(emptyCart, item).items.length === 1` - correct
  behavior

*What separates good from great:* Modeling more invariants in types,
reducing tests needed. A `NonEmptyArray<T>` type eliminates tests
for "what happens with an empty array". A `PositiveMoney` branded
type eliminates tests for negative balances. Every invariant captured
in the type system is one fewer test class needed.

---

# TypeScript at Team Scale

---

### 🎯 Model Answer

**30 seconds:**

> TypeScript at team scale requires: a shared `tsconfig.base.json`
> with `strict: true` that all packages extend, ESLint with
> `@typescript-eslint` enforcing no-explicit-any and no-unsafe-*
> rules, a documented decision framework (type vs interface, when to
> use class), a migration ratchet for any existing JS, and code review
> criteria for type quality. The goal: type safety as a team invariant,
> not individual practice.

**Blank Mind Recovery:**

**(1) Four pillars:** "Shared tsconfig. ESLint enforcement. Decision
framework documentation. Code review criteria for types."

**(2) Key metric:** "Track: @ts-expect-error count, explicit any count,
type coverage %. These must decrease over time."

---

### 📘 Concept Explanation

**What it is:**

The practices, tooling, and governance needed to maintain TypeScript
quality consistently across a team of 5+ developers over months.

**The problem it solves:**

Individual TypeScript practices are inconsistent. Without governance,
`any` spreads, different patterns are used for the same problems,
and type quality degrades over time.

**How it works:**

```
Team TypeScript governance:

1. Shared base tsconfig:
   tsconfig.base.json: strict: true, target, module
   All packages: "extends": "../../tsconfig.base.json"
   Override only what the package needs (e.g., jsx for React)

2. ESLint enforcement (automated):
   @typescript-eslint/no-explicit-any: error
   @typescript-eslint/no-unsafe-assignment: error
   @typescript-eslint/no-unsafe-return: error
   @typescript-eslint/consistent-type-definitions: ["error", "interface"]
   @typescript-eslint/prefer-string-starts-ends-with: error

3. Decision documentation:
   When to use type vs interface
   When to use class vs interface
   How to type API responses (always Zod)
   How to handle errors (Result<T, E> pattern)

4. Code review criteria:
   No any without comment + issue link
   No @ts-ignore (must be @ts-expect-error with reason)
   API boundary functions: input validated with Zod
   No non-null assertions without explicit null check pattern

5. Migration ratchet (if migrating):
   CI: @ts-expect-error count must not increase
   CI: js file count must not increase
   Weekly: type coverage % tracked
```

---

### 💻 Code Example

**Example (Production) - Team tsconfig structure:**

```json
// tsconfig.base.json (root, shared by all packages)
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "skipLibCheck": true,
    "incremental": true,
    "declaration": true,
    "declarationMap": true
  }
}

// packages/api/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "composite": true,
    "outDir": "dist",
    "rootDir": "src",
    "tsBuildInfoFile": "../../.cache/api.tsbuildinfo"
  },
  "include": ["src"],
  "references": [{ "path": "../shared" }]
}

// packages/web/tsconfig.json
{
  "extends": "../../tsconfig.base.json",
  "compilerOptions": {
    "jsx": "react-jsx",
    "composite": true,
    "outDir": "dist"
  },
  "include": ["src"]
}
```

```jsonc
// .eslintrc.json (TypeScript-specific rules)
{
  "extends": ["plugin:@typescript-eslint/recommended-type-checked"],
  "parserOptions": {
    "project": "./tsconfig.json"
  },
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unsafe-assignment": "error",
    "@typescript-eslint/no-unsafe-return": "error",
    "@typescript-eslint/no-unsafe-call": "error",
    "@typescript-eslint/consistent-type-definitions": ["error", "interface"],
    "@typescript-eslint/consistent-type-imports": "error",
    "@typescript-eslint/switch-exhaustiveness-check": "error",
    "@typescript-eslint/no-non-null-assertion": "warn"
  }
}
```

> **Code walkthrough:** The base tsconfig pattern ensures all packages
> inherit the same strict settings without duplication. Packages can
> override only what they need (JSX for React, different module
> formats). The ESLint configuration uses `recommended-type-checked`
> which enables rules that require type information (not just parsing)
> for maximum accuracy. `switch-exhaustiveness-check` enforces the
> `assertNever` pattern without needing to remember to add it manually.
> `consistent-type-definitions` enforces the `interface` for objects
> convention across the codebase.

---

### ⚖️ Comparison Table

| Governance tool | What it enforces | Cost |
|---|---|---|
| Shared tsconfig.base | Same compiler settings | Low setup |
| ESLint @typescript-eslint | Anti-patterns prevented | Medium setup |
| Zod at boundaries | Runtime type safety | Per-boundary work |
| Code review checklist | Quality bar | Review time |
| CI metrics tracking | No regression | Pipeline setup |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> The team uses a shared `tsconfig.base.json` with `strict: true`
> that all packages extend. ESLint with `@typescript-eslint` rules
> prevents `any` and unsafe operations. All API responses are
> validated with Zod. Code reviews check for `as` assertions and
> non-null assertions.

**Senior / Staff:**

> TypeScript quality at team scale requires automated enforcement,
> not just documentation. The three-layer approach: shared base
> tsconfig (same compiler settings everywhere), ESLint rules
> (automated anti-pattern prevention in CI), and Zod at data
> boundaries (runtime + compile-time safety for external data).
> Documentation of decisions (when to use type vs interface, how to
> handle errors) reduces cognitive load in code reviews. The key
> metric: track `@ts-expect-error` count and explicit `any` count in
> CI - they must not increase. This makes type quality a team
> invariant, not an individual practice.

---

### ⚠️ Common Misconceptions

**Misconception: `strict: true` is too restrictive for fast-moving teams.**

`strict: true` catches null pointer dereferences, implicit any types,
and unsafe function types - the bugs that cause production incidents.
The cost is writing slightly more explicit code. In practice, teams
that start with strict have faster development because they catch bugs
at the keyboard, not in staging. Retroactively enabling strict is far
more expensive than starting with it.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Different packages have different tsconfig settings.**

Symptom: Code that compiles in package A fails type checking in
package B.

Cause: Each package's tsconfig is manually maintained without a
shared base.

Fix: Create `tsconfig.base.json` at the monorepo root; have all
packages extend it with `"extends": "../../tsconfig.base.json"`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How to enforce TypeScript quality in a team? | Design | ★★★ | 4 min |
| Shared tsconfig structure for monorepo | Design | ★★★ | 3 min |
| Which ESLint rules to enforce for TS? | Definition | ★★★ | 3 min |
| How to track type quality over time? | Design | ★★☆ | 2 min |
| Code review criteria for TypeScript | Design | ★★★ | 3 min |
| Onboarding new devs to TypeScript standards | Behavioral | ★★★ | 3 min |
| TypeScript tech debt - how to reduce? | Design | ★★★ | 3 min |

**Q: Your team has inconsistent TypeScript quality - some files use
`any` everywhere, others are strictly typed. How do you fix this?**

A: This is a governance problem, not a TypeScript problem. The fix
requires making the right behavior the default, not the documented
standard.

Step 1: Measure current state. Track the metrics:
```pwsh
# Count any occurrences:
(Select-String -Path "src/**/*.ts" -Pattern ": any" | Measure-Object).Count
# Count @ts-expect-error:
(Select-String -Path "src/**/*.ts" -Pattern "@ts-expect-error" | Measure-Object).Count
# Type coverage (using type-coverage package):
npx type-coverage --strict
```

Step 2: Add ESLint enforcement for new code only:
```json
{ "overrides": [{ "files": ["src/**/*.ts"],
  "rules": { "@typescript-eslint/no-explicit-any": "error" } }] }
```
This prevents new `any` without breaking existing code.

Step 3: Set up the CI ratchet. Store current counts as the baseline.
CI fails if counts increase. This prevents regression while allowing
gradual improvement.

Step 4: Create a team decision framework (1-page doc):
- When to use `type` vs `interface`
- External data: always Zod
- Error handling: Result<T, E> pattern or exceptions
- No `any`, use `unknown` for uncertainty

Step 5: Code review criteria (add to PR template):
- [ ] No new `any` without `@ts-expect-error + issue link`
- [ ] API responses validated with Zod
- [ ] No non-null assertions without null check pattern

Step 6: Pay down existing debt incrementally. Budget 20% of each
sprint for type quality work - prioritize high-churn files (most
likely to cause bugs).

*What separates good from great:* The ESLint enforcement is the
difference between "documented standards" and "automated standards."
Documentation is ignored under pressure; ESLint errors block PRs.
Make the right path the easy path: provide shared ESLint config
and base tsconfig that teams can adopt in one PR, with zero
configuration decisions to make.
