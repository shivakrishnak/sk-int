---
layout: default
title: "TypeScript - L1 Basic Types"
parent: "TypeScript"
nav_order: 2
permalink: /typescript/l1-basic-types/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [TypeScript Primitive Types](#typescript-primitive-types) | foundational |
| 2 | [Interfaces and Type Aliases](#interfaces-and-type-aliases) | foundational |
| 3 | [Enums and Literal Types](#enums-and-literal-types) | foundational |

---

# TypeScript Primitive Types

🎯 **Interview Weight:** foundational (★☆☆) - basic types are asked
in every TypeScript screening interview

---

### 🎯 Model Answer

**30 seconds:**

> TypeScript's primitive types mirror JavaScript's: `string`, `number`,
> `boolean`, `bigint`, `symbol`, `null`, `undefined`. On top of that,
> TypeScript adds: `any` (disable type checking), `unknown` (safe
> unknown), `never` (unreachable code / exhaustive checks), `void`
> (no return value), and type literals like `"admin" | "user"`. These
> types are checked at compile time and erased at runtime.

**3 minutes:**

> Key distinctions:
> - `null` and `undefined` are distinct types with `strictNullChecks`
>   (without it, they're assignable to everything - dangerous)
> - `any` vs `unknown`: `any` disables all checks; `unknown` requires
>   narrowing before use
> - `never`: represents values that never occur (function that always
>   throws, exhaustive switch cases)
> - `void`: return type of functions that return nothing (vs `undefined`
>   which is the explicit absence of value)
> - Literal types: `type Direction = 'north' | 'south' | 'east' | 'west'`
>   constrains to exact string values

**Blank Mind Recovery:**

**(1) Restate:** "TypeScript primitives: string, number, boolean, bigint,
symbol, null, undefined. Special: any (unsafe escape), unknown (safe),
never (unreachable), void (no return). Literal types constrain to
exact values. strictNullChecks makes null/undefined distinct types."

---

### 📘 Concept Explanation

**What it is:**

TypeScript's type system is built on a set of primitive types that
correspond to JavaScript's runtime value types, plus special types
for type system reasoning.

**The problem it solves:**

Without explicit types, TypeScript infers types or falls back to `any`.
Understanding the full type vocabulary allows engineers to express
precise contracts for functions and data shapes.

**How it works:**

```
PRIMITIVE TYPE REFERENCE:

  JavaScript primitives (directly mapped):
    string     "hello", ""
    number     42, 3.14, NaN, Infinity
    boolean    true, false
    bigint     9007199254740991n
    symbol     Symbol('key')
    null       null (intentional absence)
    undefined  undefined (uninitialized/missing)

  TypeScript-only types:
    any        Disables type checking entirely
               Assignable to and from everything
               Use: migration, external libs without types

    unknown    Type-safe alternative to any
               Assignable from anything
               MUST narrow before use (typeof, instanceof)
               Use: external data, catch variables

    never      Represents impossible types / unreachable code
               Function that always throws -> return type is never
               Empty union (string & number = never)
               Use: exhaustive checks, error handling

    void       Return type of functions that don't return a value
               undefined is assignable to void
               Use: event handlers, side-effect functions

    object     Any non-primitive value
               Rarely used: prefer specific interface/type

  TYPE ANNOTATIONS (explicit):
    const name: string = 'Alice';
    let count: number = 0;
    let active: boolean = true;

  TYPE INFERENCE (TypeScript infers when possible):
    const name = 'Alice';   // inferred: string
    const count = 0;        // inferred: number (not literal 0!)
    const flag = true;      // inferred: boolean

    // For const literals, use 'as const' for literal type:
    const direction = 'north' as const;  // type: 'north' (not string)

SPECIAL TYPE BEHAVIORS:

  null and undefined (with strictNullChecks: true):
    let x: string = null;       // Error: not assignable
    let y: string | null = null;  // OK: explicitly nullable
    let z: string = undefined;  // Error: not assignable
    let w: string | undefined = undefined;  // OK

  Type assertions (promises to TypeScript, not runtime checks):
    const input = document.getElementById('name') as HTMLInputElement;
    // TypeScript trusts you that it's HTMLInputElement
    // If it's actually a <div>, you get runtime errors

  Non-null assertion operator (!):
    const input = document.getElementById('name')!;
    // The '!' tells TypeScript: I know this is not null/undefined
    // Runtime still crashes if it IS null - no runtime protection

NEVER IN EXHAUSTIVE CHECKS:

  type Shape = 'circle' | 'square' | 'triangle';

  function getArea(shape: Shape): number {
    switch (shape) {
      case 'circle': return Math.PI * 1;
      case 'square': return 1;
      case 'triangle': return 0.5;
      default:
        // TypeScript infers shape as 'never' here
        // because all cases are handled
        const _exhaustive: never = shape;
        throw new Error(`Unhandled shape: ${shape}`);
    }
  }

  // If you add 'hexagon' to Shape without updating the switch:
  // TypeScript error: Type 'hexagon' is not assignable to type 'never'
  // This catches missing cases at compile time!
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Why it matters:**

Understanding the full type vocabulary - especially `unknown`, `never`,
and literal types - enables writing precise, expressive TypeScript that
provides maximum compile-time safety.

**Mental model:**

> TypeScript types form a hierarchy. `unknown` is at the top (every
> value is `unknown`). `never` is at the bottom (no value is `never`).
> `any` is the escape hatch that opts out of the hierarchy entirely.
> All other types sit in between, with union types joining them and
> intersection types combining them.

**Scale behavior:**

Good type design prevents entire categories of bugs. `never`-based
exhaustive checks catch missing cases when new values are added to
a union. `unknown` at API boundaries forces explicit handling.

---

### 💻 Code Example

**Type annotations, inference, and special types in practice**

```typescript
// PRIMITIVE TYPES:
const name: string = 'Alice';         // explicit
const age = 30;                       // inferred: number
const active: boolean = true;         // explicit
const bigNum: bigint = 9007199254740991n;

// WRONG vs RIGHT for null/undefined (strictNullChecks):
// BAD: implicit null (without strictNullChecks - dangerous)
let user: User = null;  // Allowed without strictNullChecks
user.name;              // Runtime crash

// GOOD: explicit nullable type
let user: User | null = null;
user?.name;             // Safe: optional chaining
if (user !== null) {
  user.name;            // Type narrowed to User here
}

// NEVER FOR EXHAUSTIVE CHECKS:
type Status = 'active' | 'inactive' | 'banned';

function getStatusColor(status: Status): string {
  switch (status) {
    case 'active': return 'green';
    case 'inactive': return 'gray';
    case 'banned': return 'red';
    default:
      // If Status adds 'pending', TypeScript flags this:
      const check: never = status;
      throw new Error(`Unknown status: ${status}`);
  }
}

// UNKNOWN FOR SAFE EXTERNAL DATA:
function processApiResponse(data: unknown): string {
  // Must narrow before use
  if (typeof data === 'string') {
    return data.toUpperCase();  // OK: narrowed to string
  }
  if (typeof data === 'object' && data !== null &&
      'message' in data && typeof data.message === 'string') {
    return data.message;  // OK: narrowed
  }
  throw new Error('Unexpected data shape');
}

// AS CONST FOR LITERAL TYPES:
const ROLES = ['admin', 'user', 'viewer'] as const;
type Role = typeof ROLES[number];  // 'admin' | 'user' | 'viewer'
// Adding a role to ROLES automatically updates the type
```

> **Code walkthrough:** The `never` exhaustive check pattern is one
> of TypeScript's most powerful patterns. By assigning `shape` to a
> `never` variable in the `default` case, we get a compile error if
> any case is not handled. When `'pending'` is added to `Status`, the
> default case is reached with `'pending'`, but `'pending'` is not
> assignable to `never` - TypeScript immediately flags the missing case.
> The `unknown` example shows the required narrowing pattern: you cannot
> access any property on `unknown` without first checking its shape.
> This forces defensive code at external data entry points.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> TypeScript's primitive types are string, number, boolean, null,
> undefined, bigint, and symbol. Plus special types: any (no checking),
> unknown (safe any), never (impossible type), void (no return). Use
> `strictNullChecks` to make null/undefined distinct from other types.

**Senior / Staff:**

> The type system's completeness comes from `never` (bottom type) and
> `unknown` (top type). `never` in exhaustive checks is a compile-time
> safety net for union types. `unknown` at API boundaries enforces
> explicit narrowing. The `any` escape hatch should be minimized and
> tracked via `@typescript-eslint/no-explicit-any`. Literal types
> (`'north' | 'south'`) enable discriminated unions - the most important
> pattern for modeling sum types in TypeScript. `as const` satisfies
> the common need for compile-time enum-like objects without the
> overhead of actual `enum` declarations.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword - primitives overview, no comparison table needed)*

---

### 📊 Diagram

*(Omit: type hierarchy described in text)*

---

### ⚠️ Common Misconceptions

**"void and undefined mean the same thing"**

`void` is the return type of functions that explicitly return nothing
(or `return;`). `undefined` is a specific value. A function returning
`undefined` explicitly (`return undefined`) has return type `undefined`.
A function with no return statement has return type `void`. In practice
they overlap (a `void` function can return `undefined`), but semantically:
`void` = "caller should not use the return value" while `undefined` =
"this explicitly returns the undefined value." The distinction matters
for function callbacks.

---

### 🚨 Failure Modes and Diagnosis

**Non-null assertion causing runtime crashes:**

```typescript
// SYMPTOM: TypeScript passes but runtime crashes with null reference
// CAUSE: overuse of non-null assertion operator (!)

// BAD: ! suppresses type error but doesn't prevent null at runtime
const element = document.getElementById('submit-button')!;
element.addEventListener('click', handleSubmit);
// If 'submit-button' doesn't exist in DOM: element is null
// ! tells TypeScript "trust me it's not null"
// Runtime: TypeError: Cannot read 'addEventListener' of null

// DIAGNOSIS: search for ! in codebase, especially on DOM queries
// GOOD: defensive check
const element = document.getElementById('submit-button');
if (!element) {
  console.error('submit-button element not found');
  return;
}
element.addEventListener('click', handleSubmit);
// Only proceeds if element exists
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| Difference between any and unknown | 2-3 min | Type safety |
| When to use never | 2-3 min | Exhaustive checks |
| void vs undefined return types | 2-3 min | Semantic difference |
| strictNullChecks impact | 2-3 min | Null safety |
| Non-null assertion operator | 2-3 min | When NOT to use |
| Literal types and as const | 2-3 min | Narrowing |
| Type assertion vs type guard | 2-3 min | Runtime vs compile |

---

**Q1: What is the difference between 'any' and 'unknown'?** `[MID]`
MECHANISM

> **Answer:**
>
> `any` disables type checking entirely. You can do anything with an
> `any` value and TypeScript won't complain. `unknown` is the type-safe
> equivalent: you can assign anything TO `unknown`, but you must narrow
> the type BEFORE using it.
>
> ```typescript
> let a: any = 'hello';
> a.doesNotExist();    // No error - TypeScript trusts you
> const n: number = a; // No error - assignable everywhere
>
> let u: unknown = 'hello';
> u.doesNotExist();    // Error: Object is of type 'unknown'
> const m: number = u; // Error: unknown not assignable to number
> // Must narrow:
> if (typeof u === 'string') u.toUpperCase(); // OK
> ```
>
> *What separates good from great:* Use `unknown` for all external
> entry points (API responses, JSON.parse, catch blocks). Use `any`
> only during migration or for third-party types that are genuinely
> unusable. ESLint `@typescript-eslint/no-explicit-any` enforces this.

**Q2: What is the 'never' type and how do you use it for exhaustive
checks?** `[SENIOR]` MECHANISM

> **Answer:**
>
> `never` represents values that can never occur. Common uses:
> functions that always throw (return type `never`), empty union types,
> and exhaustive switch statements.
>
> ```typescript
> // Always-throw function:
> function fail(message: string): never {
>   throw new Error(message);
>   // Return type is 'never' because it NEVER returns normally
> }
>
> // Exhaustive check:
> type Direction = 'north' | 'south';
> function move(d: Direction) {
>   if (d === 'north') return;
>   if (d === 'south') return;
>   const _: never = d;  // TypeScript error if any case missed
> }
> ```
>
> *What separates good from great:* When `Direction` gets `'east'`
> added, the `never` assignment catches it immediately at compile time.
> This prevents the common "we added a new value to the enum but
> forgot to update the switch statement" production bug.

**Q3: What are literal types and how do they differ from their
primitive parent types?** `[MID]` MECHANISM

> **Answer:**
>
> Literal types are exact value types. `'north'` is a literal type
> assignable only to the string `'north'`. `42` is a literal type.
> They're subtypes of their primitive parent.
>
> ```typescript
> let generic: string = 'north';  // Can be any string
> let literal: 'north' = 'north'; // Can ONLY be 'north'
> // literal = 'south';  Error: Type '"south"' not assignable
>
> // Union of literals (discriminated union):
> type Direction = 'north' | 'south' | 'east' | 'west';
> function move(d: Direction) { ... }
> move('north');  // OK
> move('up');     // Error: not in Direction
>
> // as const for object/array literals:
> const DIRECTIONS = ['north', 'south'] as const;
> // DIRECTIONS: readonly ['north', 'south'] (literal tuple)
> // Without as const: string[] (generic)
> ```
>
> *What separates good from great:* Literal types + discriminated
> unions enable type-safe state machines. Instead of `state: string`,
> `type State = 'loading' | 'success' | 'error'` makes all state
> transitions type-checked. Add a new state without updating all
> handlers: TypeScript catches it via exhaustive checks.

---

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


# Interfaces and Type Aliases

🎯 **Interview Weight:** foundational (★☆☆) - interfaces vs type aliases
is a universal TypeScript interview question

---

### 🎯 Model Answer

**30 seconds:**

> Interfaces and type aliases are two ways to name and describe object
> shapes in TypeScript. They're mostly interchangeable for object types.
> Key differences: interfaces support declaration merging (can be
> extended by declaring them again); type aliases can express unions,
> intersections, and mapped types that interfaces cannot. For object
> shapes, prefer interface for public API types; type aliases for unions
> and complex type expressions.

**3 minutes:**

> Interface:
> - Can be extended with `extends`
> - Supports declaration merging (multiple declarations merge)
> - Can be implemented by classes
> - Used for OOP-style contracts
>
> Type alias:
> - Can represent any type (unions, intersections, primitives, tuples)
> - Cannot be re-opened (no declaration merging)
> - More powerful for complex type expressions
> - `type UserOrAdmin = User | Admin` is only possible with type

**Blank Mind Recovery:**

**(1) Restate:** "Interface = object shape, supports extends + merging.
Type alias = any type (union/intersection/primitive/tuple). Both describe
object shapes similarly. Interface preferred for public API types
(extendable). Type alias preferred for unions and complex expressions."

---

### 📘 Concept Explanation

**What it is:**

Interfaces and type aliases are TypeScript mechanisms for naming types.
Both can describe the shape of objects. Their use cases differ for
advanced patterns.

**The problem it solves:**

Without named types, you repeat object shapes everywhere. Named types
provide a single source of truth for the shape of data structures.

**How it works:**

```
INTERFACE vs TYPE ALIAS - SIDE BY SIDE:

  // Interface:
  interface User {
    id: number;
    name: string;
    email?: string;  // optional
    readonly createdAt: Date;  // read-only
  }

  // Type alias:
  type User = {
    id: number;
    name: string;
    email?: string;
    readonly createdAt: Date;
  };

  // For object shapes: nearly identical.
  // Difference 1: Declaration Merging (interface only):
  interface Window {
    myCustomProp: string;
  }
  interface Window {  // Second declaration MERGES with first
    anotherProp: number;
  }
  // Window now has: all standard Window props + myCustomProp + anotherProp
  // Used to: extend library types (global augmentation)

  // Type alias: cannot be re-declared
  type Point = { x: number };
  type Point = { y: number };  // Error: Duplicate identifier 'Point'

  // Difference 2: Type aliases can express unions
  type Result<T> = { success: true; data: T }
                 | { success: false; error: string };
  // Cannot express this as an interface

  // Difference 3: Interfaces can be implemented by classes
  interface Serializable {
    serialize(): string;
    deserialize(data: string): void;
  }
  class UserModel implements Serializable { ... }

  // Both support extends (differently):
  // Interface extends interface:
  interface Employee extends User {
    department: string;
  }

  // Type alias extends via intersection:
  type Employee = User & { department: string };

WHEN TO USE EACH:

  Interface:
    - Object shapes that may be extended (by library users)
    - React component props
    - Class contracts (implements)
    - When declaration merging is needed (augmenting library types)

  Type Alias:
    - Unions and discriminated unions
    - Mapped types and conditional types
    - Utility type compositions
    - Primitive aliases (type ID = string)
    - Tuple types

  Either is fine for:
    - Internal data structures
    - Simple object shapes with no need for declaration merging
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Why it matters:**

Choosing between interface and type alias thoughtfully affects library
design (declaration merging allows users to extend your types), class
design (interface contracts enable dependency injection patterns), and
union type modeling (type aliases only).

**Mental model:**

> Interface is like a class definition without the implementation - a
> "contract." Type alias is like a label you attach to any type
> expression - you're naming something that already exists. Interfaces
> can have new signatures added later (merging). Type aliases are final.

**Scale behavior:**

In large codebases: prefer interfaces for types that will be extended
(domain entities, API response shapes that consumers augment). Prefer
type aliases for internal, closed types. The distinction matters most
when publishing libraries.

---

### 💻 Code Example

**Interface and type alias patterns in React + API context**

```typescript
// INTERFACE for React component props (common, extendable):
interface ButtonProps {
  label: string;
  onClick: () => void;
  disabled?: boolean;
  variant?: 'primary' | 'secondary';
}

// TYPE ALIAS for discriminated union (only possible with type):
type ApiResult<T> =
  | { status: 'success'; data: T }
  | { status: 'loading' }
  | { status: 'error'; message: string };

function renderUser(result: ApiResult<User>) {
  switch (result.status) {
    case 'success': return <div>{result.data.name}</div>;
    case 'loading': return <Spinner />;
    case 'error': return <div>Error: {result.message}</div>;
    // TypeScript narrows result in each branch
  }
}

// DECLARATION MERGING to augment third-party types:
// Extending Express Request type to include user:
// express-augment.d.ts:
declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
    }
  }
}
// Now: req.user is typed in all Express route handlers
// (Declaration merging with the Express namespace)

// INTERFACE EXTENDING:
interface Animal {
  name: string;
  speak(): string;
}
interface Pet extends Animal {
  owner: string;
}
// Pet has: name, speak(), owner

// TYPE ALIAS INTERSECTION (equivalent):
type Pet = Animal & { owner: string };
// Same result, different syntax
```

> **Code walkthrough:** The discriminated union `ApiResult<T>` pattern
> shows where type aliases are essential: this 3-way union cannot be
> expressed as an interface. In each `switch` branch, TypeScript narrows
> the type - `result.data` is only accessible in the `'success'` branch
> (TypeScript knows `data` exists when `status === 'success'`). The
> declaration merging example shows the key use case for interface
> merging: extending third-party types (Express, Jest, React) without
> forking them. This is the official pattern for "global augmentation"
> in TypeScript - adding properties to library interfaces.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Interfaces and type aliases are similar for object shapes. Key
> difference: interfaces support declaration merging (can be extended
> by declaring the same interface again). Type aliases support unions
> and complex type expressions. For objects, use interfaces; for unions
> and complex types, use type aliases.

**Senior / Staff:**

> The practical rule: interface for shapes you want to be extensible
> (library public API, framework integration points), type alias for
> everything else. The declaration merging capability of interfaces is
> critical for framework integration - the pattern of extending
> `Express.Request` or `react.JSX.IntrinsicElements` uses interface
> merging. For complex type computations (mapped types, conditional
> types, template literal types), only type aliases work. The TypeScript
> team's guidance: if you're not sure, use type aliases for internal
> types; interfaces for public-facing library types.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword - comparison described in text)*

---

### 📊 Diagram

*(Omit: interface vs type is a code-level distinction, no visual needed)*

---

### ⚠️ Common Misconceptions

**"Interfaces are for objects and type aliases are for primitives"**

Both can describe object shapes. The distinction is about capabilities:
interfaces support declaration merging and class `implements`. Type
aliases support unions, intersections, mapped types, and any type
expression. For object shapes, they're nearly equivalent. The
misconception comes from tutorials that show `type ID = string` (type
alias for primitive) as the primary use case, making it seem like
type aliases are only for non-object types.

---

### 🚨 Failure Modes and Diagnosis

**Interface declaration merging causing unexpected property availability:**

```typescript
// SYMPTOM: Property 'foo' doesn't exist in the library source,
//          but no TypeScript error
// CAUSE: someone added a declaration merge for the interface

// EXAMPLE: someone added to global.d.ts or types.d.ts:
interface String {
  foo(): void;  // Added to String interface via merging
}
// Now ALL strings have .foo() in TypeScript (but not at runtime!)
'hello'.foo();  // TypeScript: OK! Runtime: TypeError: not a function

// DIAGNOSIS: search codebase for 'interface String' or
//            'interface Array' (built-in augmentations)
// They're legitimate for some use cases but dangerous if accidental
// RULE: global interface augmentation should be in a dedicated
//       *.d.ts file with a clear comment explaining the augmentation
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| Interface vs type alias main differences | 2-3 min | Merging + unions |
| When to use interface over type alias | 2-3 min | Extensibility |
| Declaration merging use case | 2-3 min | Third-party augmentation |
| Class implements interface | 2-3 min | OOP contracts |
| Intersection type vs interface extends | 2-3 min | Same result |
| Optional and readonly properties | 2-3 min | ? and readonly |
| Index signatures | 2-3 min | Dynamic keys |

---

**Q1: Can a type alias extend an interface and vice versa?** `[MID]`
MECHANISM

> **Answer:**
>
> Yes - they can extend each other using different syntax:
>
> ```typescript
> // Interface extends interface (interface syntax):
> interface Animal { name: string; }
> interface Dog extends Animal { breed: string; }
>
> // Interface extends type alias (interface syntax):
> type HasName = { name: string };
> interface Person extends HasName { age: number; }
>
> // Type alias extends interface (intersection):
> interface Vehicle { wheels: number; }
> type Car = Vehicle & { brand: string };
>
> // Type alias extends type alias (intersection):
> type A = { x: number };
> type B = A & { y: number };
>
> // Class implements type alias:
> type Printable = { print(): void };
> class Document implements Printable {
>   print() { console.log('Printing'); }
> }
> ```
>
> *What separates good from great:* The interoperability between interfaces
> and type aliases means you're not locked in. You can start with an
> interface and change to a type alias (or vice versa) without breaking
> consumers - assuming you don't use declaration merging, which is
> interface-only.

**Q2: What are index signatures and when do you use them?** `[SENIOR]`
MECHANISM

> **Answer:**
>
> Index signatures define types for dynamically-keyed objects:
>
> ```typescript
> // Index signature for string-keyed dictionary:
> interface StringDict {
>   [key: string]: string;  // any string key maps to string value
> }
> const dict: StringDict = { a: '1', b: '2' };
> dict['anything'] = 'value';  // OK
> dict.unknownKey;  // type: string (TypeScript allows any string key)
>
> // Number-indexed (array-like):
> interface NumberIndexed {
>   [index: number]: string;
>   length: number;  // Can add specific properties alongside
> }
>
> // BAD: index signature makes ALL properties unsafe
> interface Mixed {
>   [key: string]: string;
>   name: string;    // OK (string, compatible with [string]: string)
>   age: number;     // Error! number is not string (index signature conflict)
> }
>
> // BETTER: Record<K, V> utility type for typed dictionaries:
> type UserById = Record<string, User>;
> const users: UserById = { '1': user1, '2': user2 };
> ```
>
> *What separates good from great:* Index signatures weaken TypeScript's
> type safety because they allow any key. `Record<K, V>` is cleaner
> for known key shapes. For maps with computed keys from a union type:
> `Record<'north' | 'south', Coord>` ensures ALL keys in the union
> are present. For truly dynamic keys: `Map<string, V>` is often
> better than an index signature because TypeScript knows keys might
> be absent (`.get()` returns `V | undefined`).

**Q3: What does 'readonly' do and when should you use it?** `[JUNIOR]`
MECHANISM

> **Answer:**
>
> `readonly` makes a property or array element immutable after
> initialization (a compile-time restriction, not a runtime one).
>
> ```typescript
> interface Config {
>   readonly host: string;
>   readonly port: number;
>   name: string;         // mutable
> }
>
> const config: Config = { host: 'localhost', port: 3000, name: 'app' };
> config.host = 'prod';  // Error: Cannot assign to 'host' (readonly)
> config.name = 'prod';  // OK: name is mutable
>
> // Readonly array (cannot push/pop/modify):
> const items: readonly string[] = ['a', 'b', 'c'];
> items.push('d');   // Error: Property 'push' does not exist on readonly array
> items[0] = 'z';    // Error: cannot assign to readonly index
>
> // Readonly<T> utility makes all properties readonly:
> type ReadonlyConfig = Readonly<Config>;
>
> // RUNTIME: readonly is compile-time only!
> const obj = { x: 1 } as const;
> (obj as any).x = 2;  // TypeScript error, but runtime allows it
> // For true runtime immutability: Object.freeze()
> ```
>
> *What separates good from great:* `readonly` is best for domain
> models where mutation is a bug. Value objects (like Money, Coordinates)
> should always be readonly - they represent values, not mutable state.
> Function parameters typed as `readonly T[]` prevent accidental
> mutations of caller's arrays. The `as const` assertion makes all
> properties deeply readonly (including nested objects), which is
> useful for config objects that should never change.

---

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


# Enums and Literal Types

🎯 **Interview Weight:** foundational (★☆☆) - enums vs literal unions
is a common decision point and interview topic in TypeScript

---

### 🎯 Model Answer

**30 seconds:**

> TypeScript has `enum` for named constants (like Java enums), but
> the community increasingly prefers literal union types like
> `type Direction = 'north' | 'south'`. Literal unions are lighter
> (zero JavaScript output), easier to understand, and fully type-safe.
> Enums emit JavaScript code (unless `const enum`), can have unexpected
> reverse mappings, and are a TypeScript-specific concept that doesn't
> exist in JavaScript.

**3 minutes:**

> When to use `enum`:
> - Numeric enums where you need runtime values (rare)
> - `const enum` for compile-time-only constants with no JS output
> - When you need the reverse mapping (look up name from value)
>
> When to use literal union:
> - String constants (most use cases)
> - When the values should be plain strings visible in logs/APIs
> - When bundle size matters (enums add a few bytes of JS)
> - When using `as const` patterns

**Blank Mind Recovery:**

**(1) Restate:** "TypeScript enum = named constants, emits JS code.
Literal union = 'A' | 'B' | 'C', zero JS output, safer, preferred.
const enum = erased at compile time (like literals). Prefer literal
unions for strings; enums for rare cases needing runtime object."

---

### 📘 Concept Explanation

**What it is:**

TypeScript's `enum` keyword creates named constants that work at both
compile time (for type checking) and runtime (as JavaScript objects).
Literal union types (`'north' | 'south'`) achieve similar type safety
with zero runtime overhead.

**The problem it solves:**

JavaScript has no native enum type. TypeScript's enum provides named
constants with type safety. But the implementation has trade-offs that
make literal unions preferable in most cases.

**How it works:**

```
ENUM vs CONST ENUM vs LITERAL UNION:

  // String enum:
  enum Direction {
    North = 'NORTH',
    South = 'SOUTH',
    East = 'EAST',
    West = 'WEST',
  }

  // Emitted JavaScript:
  var Direction;
  (function(Direction) {
    Direction["North"] = "NORTH";
    Direction["South"] = "SOUTH";
    // ...
  })(Direction || (Direction = {}));
  // Creates an object at runtime

  // Numeric enum (with reverse mapping):
  enum Status {
    Active,    // 0
    Inactive,  // 1
  }
  Status.Active;    // 0
  Status[0];        // 'Active' (reverse mapping!)
  // Emits both forward AND reverse mappings

  // CONST enum (erased at compile time):
  const enum Direction {
    North = 'NORTH',
    South = 'SOUTH',
  }
  // Usage: Direction.North is inlined as 'NORTH'
  // Output JS: just the string 'NORTH' - no object at runtime
  // Limitation: cannot use const enum values at runtime (erased)

  // LITERAL UNION (preferred for most use cases):
  type Direction = 'NORTH' | 'SOUTH' | 'EAST' | 'WEST';
  // Zero JS output (type only)
  // Works with string literals directly in code
  // Can use in switch statements with exhaustive checks
  // Compatible with JSON serialization (plain strings)

  // AS CONST PATTERN (runtime object + type):
  const DIRECTION = {
    North: 'NORTH',
    South: 'SOUTH',
    East: 'EAST',
    West: 'WEST',
  } as const;
  type Direction = typeof DIRECTION[keyof typeof DIRECTION];
  // Direction = 'NORTH' | 'SOUTH' | 'EAST' | 'WEST'
  // DIRECTION is a real object (can iterate, use in runtime logic)
  // Type is derived from the values (single source of truth)

ENUM PITFALLS:

  // Numeric enum structural typing issue:
  enum Status { Active = 0, Inactive = 1 }
  function setStatus(s: Status) { ... }
  setStatus(42);  // NO TypeScript error! (number assignable to Status)
  // String enums don't have this problem

  // Enum bloat in bundles:
  // Each enum = a JS IIFE closure
  // For 20 enums, 20 IIFEs in the bundle
  // const enum or literal union = zero bytes

  // Enum in JSON: enum values serialize to their underlying value
  JSON.stringify({ direction: Direction.North })  // '{"direction":"NORTH"}'
  // Fine for string enums; numeric enums are less readable in JSON
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Why it matters:**

The `enum` vs literal union decision affects bundle size, type safety
(string enums are safer than numeric enums), and code readability.
Understanding the trade-offs enables the right choice.

**Mental model:**

> Enums are TypeScript trying to add "real enums" to JavaScript. Literal
> unions are TypeScript's type system naturally expressing the concept
> without adding runtime code. Most of the time, the simpler approach
> (literal union) is better. Enums are the "enum-shaped hammer" for
> a few specific nails (numeric constants, runtime iteration).

**Scale behavior:**

For bundle-size-conscious frontend code: 10 enums vs 10 literal union
types = ~500 bytes difference (the enum IIFEs). For CLI tools and
server-side code where bundle size doesn't matter: enums are fine.

---

### 💻 Code Example

**Enum vs literal union patterns**

```typescript
// BAD: numeric enum (unsafe, reverse mapping confusion)
enum Status {
  Active,    // 0
  Inactive,  // 1
  Banned,    // 2
}
function setUserStatus(status: Status) { ... }
setUserStatus(100);  // No TypeScript error! Number 100 assignable to Status
setUserStatus(Status.Active);  // OK

// BETTER: string enum (safer, readable in JSON)
enum Status {
  Active = 'ACTIVE',
  Inactive = 'INACTIVE',
  Banned = 'BANNED',
}
setUserStatus('ACTIVE');  // Error! Must use Status.Active

// BEST: literal union (zero runtime overhead):
type Status = 'ACTIVE' | 'INACTIVE' | 'BANNED';
function setUserStatus(status: Status) { ... }
setUserStatus('ACTIVE');   // OK (plain string)
setUserStatus('UNKNOWN');  // Error: not in Status union

// AS CONST pattern (runtime object + derived type):
const HTTP_STATUS = {
  OK: 200,
  NotFound: 404,
  InternalError: 500,
} as const;
type HttpStatusCode = typeof HTTP_STATUS[keyof typeof HTTP_STATUS];
// HttpStatusCode = 200 | 404 | 500

// Can iterate the object at runtime:
Object.values(HTTP_STATUS).forEach(code => console.log(code));
// AND get type safety from derived type

// CONST ENUM (inline at compile time, no runtime object):
const enum LogLevel {
  Debug = 0,
  Info = 1,
  Warning = 2,
  Error = 3,
}
if (level >= LogLevel.Warning) {
  // Compiled to: if (level >= 2) { (inlined, no object)
}
```

> **Code walkthrough:** The numeric enum pitfall is significant: TypeScript
> allows any `number` to be assigned to a numeric enum type. This is
> a design quirk for historical compatibility. String enums (`'ACTIVE'`)
> don't have this problem - TypeScript requires the exact string value.
> The literal union achieves the same type safety with zero runtime
> code. The `as const` pattern adds a runtime object (for iteration,
> display, or lookup) while deriving the type from the values - a
> "single source of truth" approach where adding a new constant to
> the object automatically expands the union type.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> TypeScript has `enum` for named constants, but literal union types
> like `'ACTIVE' | 'INACTIVE'` are preferred in most cases. Literal
> unions have zero runtime overhead (pure type annotations), are more
> readable, and work naturally with plain JavaScript strings. Use
> `as const` pattern when you need both a runtime object and a derived
> union type.

**Senior / Staff:**

> The enum vs literal union decision is well-settled in the TypeScript
> community: literal unions + `as const` for string constants, numeric
> enums only when you need auto-incremented numeric values. The `const enum`
> was promising (compile-time inlining = zero runtime) but has
> compatibility issues with Babel and esbuild (which don't support
> const enums because they process files individually, not as a program).
> For TypeScript-only projects with `tsc`: `const enum` is fine. For
> projects using Babel/esbuild (most modern frontend toolchains): use
> literal unions or regular string enums. The `isolatedModules: true`
> tsconfig flag will error on `const enum` usage, preventing the
> silent incompatibility.

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword - comparison fully covered in text above)*

---

### 📊 Diagram

*(Omit: enum vs literal union is a code-level concept, no visual needed)*

---

### ⚠️ Common Misconceptions

**"Enums are better because they're explicit and formal"**

TypeScript's `enum` emits JavaScript code (except `const enum`), can
have unexpected structural typing issues (numeric enums accept any
number), and are incompatible with some popular transpilers when
used as `const enum`. Literal union types are erased at compile time,
have precise type checking, work with all transpilers, and serialize
naturally to JSON. The TypeScript team itself has acknowledged that
enums have design issues. The community consensus: prefer literal
unions + `as const` for most use cases.

---

### 🚨 Failure Modes and Diagnosis

**const enum causing runtime errors with Babel/esbuild:**

```typescript
// SYMPTOM: const enum values are undefined at runtime
// Works with tsc but crashes when built with Babel or esbuild

// ROOT CAUSE: const enum requires cross-file type information
// Babel/esbuild process files individually (no type info)
// They can't inline const enum values from other files

// BAD:
// enums.ts:
export const enum Direction { North = 'N', South = 'S' }

// user.ts:
import { Direction } from './enums';
console.log(Direction.North);
// With tsc: outputs 'N' (inlined)
// With Babel/esbuild: outputs undefined (can't inline cross-file)

// FIX: add "isolatedModules": true to tsconfig.json
// This makes tsc error on const enum usage that would break Babel
// Then switch to: regular string enum OR literal union
type Direction = 'N' | 'S';
export const Direction = { North: 'N', South: 'S' } as const;
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| Enum vs literal union comparison | 2-3 min | Zero runtime cost |
| Numeric enum type safety issue | 2-3 min | Assignability |
| const enum limitation | 2-3 min | Babel/esbuild |
| as const pattern | 2-3 min | Single source of truth |
| Enum reverse mapping | 2-3 min | Bidirectional lookup |
| Discriminated unions with literal types | 2-3 min | Type narrowing |
| isolatedModules flag | 2-3 min | Transpiler compatibility |

---

**Q1: What is the problem with numeric enums in TypeScript?** `[SENIOR]`
MECHANISM

> **Answer:**
>
> Numeric enums accept any number due to structural typing:
>
> ```typescript
> enum Status { Active = 0, Inactive = 1 }
> function setStatus(s: Status): void { ... }
>
> // These ALL compile without error:
> setStatus(0);          // OK (Status.Active)
> setStatus(Status.Active); // OK
> setStatus(42);         // OK! (42 is a number, number is Status)
> setStatus(NaN);        // OK! (NaN is a number)
>
> // String enum doesn't have this problem:
> enum StringStatus { Active = 'ACTIVE', Inactive = 'INACTIVE' }
> setStringStatus('ACTIVE');   // Error: must use StringStatus.Active
> setStringStatus(StringStatus.Active); // OK
> setStringStatus('RANDOM');   // Error
> ```
>
> *What separates good from great:* This numeric enum behavior is a
> design quirk for compatibility with JavaScript patterns where functions
> accept both enum values and raw numbers. If you must use numeric enums
> (for interoperability with external systems using numeric codes), add
> a runtime validation. For pure TypeScript code: use string enums or
> literal unions.

**Q2: How do you create a type that represents all values of an object?**
`[SENIOR]` MECHANISM

> **Answer:**
>
> Use `typeof` to get the type of an object, then `keyof` and indexed
> access types to extract value types:
>
> ```typescript
> const COLORS = {
>   Red: '#FF0000',
>   Green: '#00FF00',
>   Blue: '#0000FF',
> } as const;
>
> // Type of keys:
> type ColorKey = keyof typeof COLORS;  // 'Red' | 'Green' | 'Blue'
>
> // Type of values:
> type ColorValue = typeof COLORS[keyof typeof COLORS];
> // '#FF0000' | '#00FF00' | '#0000FF'
>
> // Shorthand:
> type ColorValue = (typeof COLORS)[keyof typeof COLORS];
>
> function setColor(color: ColorValue) { ... }
> setColor('#FF0000');  // OK
> setColor('#FFFFFF');  // Error: not in ColorValue
>
> // Adding a new color automatically updates ColorValue
> const COLORS = { ..., Purple: '#800080' } as const;
> // ColorValue now includes '#800080' automatically
> ```
>
> *What separates good from great:* This `typeof obj[keyof typeof obj]`
> pattern is a "type-level enum" that derives from a runtime object.
> The runtime object serves as documentation, validation lookup table,
> and the source of truth for the TypeScript type - all at once. This
> eliminates the maintenance burden of keeping a separate enum in sync
> with a lookup object.

**Q3: When would you use a regular enum over a literal union?** `[SENIOR]`
DECISION

> **Answer:**
>
> Specific cases where enum is justified:
>
> 1. **Numeric auto-increment**: HTTP status codes, error codes where
>    you want consecutive values without manual assignment.
>
> 2. **Runtime iteration**: need to iterate all enum values
>    (`Object.values(Status)`). Literal unions don't have runtime objects
>    to iterate. The `as const` object pattern solves this.
>
> 3. **Bidirectional mapping**: numeric enum's reverse mapping:
>    `Status[0] === 'Active'`. Useful for serialization protocols that
>    use numeric codes but need human-readable names.
>
> 4. **Namespaced constants**: `HttpMethod.Get` vs `'GET'` is
>    documentation - the namespace makes the category explicit.
>
> ```typescript
> // JUSTIFIED enum: numeric auto-increment error codes
> enum ErrorCode {
>   ParseError = 1000,
>   NetworkError,  // 1001
>   AuthError,     // 1002
>   NotFound,      // 1003
> }
>
> // JUSTIFIED enum: bitwise flags
> enum Permission {
>   None = 0,
>   Read = 1 << 0,   // 1
>   Write = 1 << 1,  // 2
>   Execute = 1 << 2,// 4
> }
> const userPerms = Permission.Read | Permission.Write; // 3
>
> // NOT JUSTIFIED (use literal union):
> enum Direction { North = 'NORTH', South = 'SOUTH' }
> // type Direction = 'NORTH' | 'SOUTH'; is cleaner
> ```
>
> *What separates good from great:* Bitwise flags are the classic use
> case for numeric enums. File permissions (Unix chmod) and feature
> flags combine bit flags because they need compact storage and fast
> bitwise operations. TypeScript's numeric enum with power-of-2 values
> is the natural representation. The runtime object is required for
> the bitwise operations, and auto-increment from `1 << 0` is cleaner
> than writing `1, 2, 4, 8, 16` manually.

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



