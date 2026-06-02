---
layout: default
title: "TypeScript - L6 Theory"
parent: "TypeScript"
nav_order: 12
permalink: /typescript/l6-theory/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Structural vs Nominal Typing](#structural-vs-nominal-typing) | medium |
| 2 | [TypeScript Type System Soundness](#typescript-type-system-soundness) | medium |

---

# Structural vs Nominal Typing

---

### 🎯 Model Answer

**30 seconds:**

> TypeScript uses structural typing: two types are compatible if they
> have the same shape (same properties and methods), regardless of
> their names. Nominal typing (Java, C#) requires explicit declaration
> of compatibility. Structural typing enables "duck typing" with
> compile-time safety: any object with the right shape satisfies an
> interface. The trade-off: structural typing can accidentally accept
> wrong types if shapes coincidentally match.

**3 minutes:**

Structural typing is TypeScript's fundamental compatibility model.
Two types are compatible if one's shape is a superset of the other's
required shape.

**Structural (TypeScript):**
```typescript
interface Point { x: number; y: number; }
class Vector { x = 0; y = 0; z = 0; }

const p: Point = new Vector(); // OK - Vector has all Point properties
```

> **Code walkthrough:** This Structural vs Nominal Typing example demonstrates interface contract definition using interface. **KEY MECHANISM:** TypeScript erases interfaces at compile time; they exist only for type checking. **WHY IT MATTERS:** structural typing means any object with matching shape satisfies the interface. **TAKEAWAY: use interfaces for public API contracts; type aliases for unions and computed types.**

`Vector` is compatible with `Point` despite no explicit `implements
Point` declaration. TypeScript checks shape, not declaration.

**Nominal (Java):**
```java
// Java requires explicit declaration:
class Vector implements Point { ... }
// Without 'implements Point', not assignable to Point even if
// Vector has x, y properties
```

> **Code walkthrough:** This Structural vs Nominal Typing example demonstrates Java API usage. **KEY MECHANISM:** the JVM compiles to bytecode that runs on the JVM; JIT compiles hot paths to native. **WHY IT MATTERS:** unchecked assumptions about thread safety cause data races under concurrent load. **TAKEAWAY: document thread-safety guarantees on every shared mutable class.**

TypeScript's structural typing is by design for JavaScript
compatibility - existing JS libraries don't declare TypeScript
interfaces. Any object with the right properties satisfies an
interface without modification.

**Excess property checking** is a special case where TypeScript
appears nominal: object literals directly assigned to a typed variable
are checked for extra properties. This prevents typos in property
names. But the same object assigned via a variable bypasses the check.

**Fresh vs stale objects**: TypeScript only performs excess property
checking on "fresh" object literals. An object stored in a variable
is "stale" and only structurally checked.

**Blank Mind Recovery:**

**(1) Structural:** "Same shape = compatible. No 'implements' needed.
Duck typing at compile time."

**(2) Nominal:** "Java/C#. Must explicitly declare implements/extends.
Name matters, not just shape."

**(3) TypeScript exception:** "Excess property checking on fresh object
literals - appears nominal but is a special case to catch typos."

---

### 📘 Concept Explanation

**What it is:**

A type system's compatibility model - how it determines whether one
type can be used where another type is expected.

**The problem it solves:**

JavaScript is inherently duck-typed: any object with the right
properties works. TypeScript needed a type system that could
type-check JavaScript patterns without requiring Java-style explicit
interface declarations throughout legacy code.

**How it works:**

```
Structural typing algorithm (TypeScript):

  Is type A assignable to type B?

  For each required property P of B:
    Does A have property P?
    Is A.P assignable to B.P?
  If ALL required properties pass: A is assignable to B

  Example:
    B = { name: string; age: number }
    A = { name: string; age: number; email: string }
    A has all required B properties? YES
    A.name is string? YES; A.age is number? YES
    Result: A is assignable to B (superset is OK)

  Nominal typing algorithm (Java):
    Is A declared as implementing B?
    Is A in B's class hierarchy?
    If not explicitly: NOT assignable (even if shapes match)

Excess property checking (special case):
  ONLY for fresh object literals assigned directly:
  const x: { a: number } = { a: 1, b: 2 }; // ERROR
  const obj = { a: 1, b: 2 };
  const y: { a: number } = obj; // OK (stale, no check)

Why excess property check exists:
  Typo protection: { coloR: 'red' } vs { color: 'red' }
  Without it, typos in option objects silently do nothing
```

> **Code walkthrough:** This Structural vs Nominal Typing example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Implications:**

- Libraries don't need TS type definitions to be type-safe
- Any object with required properties satisfies an interface
- Functions accepting `{ name: string }` work with any superset

**Trade-offs:**

| Structural | Nominal |
|---|---|
| Flexible, JS-compatible | Explicit, predictable |
| Accidental compatibility possible | No accidental compatibility |
| No boilerplate for interfaces | Requires explicit declarations |
| Better for duck-typed patterns | Better for domain modeling |

---

### 💻 Code Example

**Example 1 (Recognition) - Structural compatibility:**

```typescript
interface Serializable {
  toJSON(): string;
}

// Any class with toJSON() satisfies Serializable:
class User {
  constructor(public name: string, public id: number) {}
  toJSON(): string { return JSON.stringify({ name: this.name }); }
}

class Order {
  constructor(public items: string[]) {}
  toJSON(): string { return JSON.stringify(this.items); }
}

// No explicit 'implements Serializable' required:
function serialize(obj: Serializable): string {
  return obj.toJSON();
}

serialize(new User('Alice', 1));  // OK - User has toJSON()
serialize(new Order(['item1']));  // OK - Order has toJSON()
serialize({ toJSON: () => '{}' }); // OK - anonymous object works too
```

> **Code walkthrough:** This Structural vs Nominal Typing example demonstrates interface contract definition using interface. **KEY MECHANISM:** TypeScript erases interfaces at compile time; they exist only for type checking. **WHY IT MATTERS:** structural typing means any object with matching shape satisfies the interface. **TAKEAWAY: use interfaces for public API contracts; type aliases for unions and computed types.**

**Example 2 (Wrong vs Right) - Accidental structural compatibility:**

```typescript
// Structural typing allows accidental compatibility:
type UserId = { id: string };
type OrderId = { id: string };

// These are structurally identical - TypeScript treats them
// as the same type:
function getUser(id: UserId): User { ... }

const orderId: OrderId = { id: 'ord_123' };
getUser(orderId);  // OK! TypeScript sees same shape.
                   // This is the accidental compatibility problem.

// FIX: Use branded types when nominal-like safety is needed:
declare const __brand: unique symbol;
type UserId = { id: string; readonly [__brand]: 'UserId' };
type OrderId = { id: string; readonly [__brand]: 'OrderId' };

// Now they are structurally incompatible:
const orderId: OrderId = { id: 'ord_123', [__brand]: 'OrderId' };
getUser(orderId); // ERROR: [__brand] types differ
```

> **Code walkthrough:** This Structural vs Nominal Typing example demonstrates type alias definition. **KEY MECHANISM:** type aliases are erased at compile time; they create no runtime overhead. **WHY IT MATTERS:** circular type aliases cause infinite recursion during type checking. **TAKEAWAY: prefer type aliases for union types and mapped types; interfaces for object shapes.**

**Example 3 (Wrong vs Right) - Excess property checking:**


```typescript
// BAD: using any defeats type safety
```

```typescript
interface Config {
  host: string;
  port: number;
}

// BAD: excess property on fresh literal - TypeScript catches typo
const config: Config = {
  host: 'localhost',
  port: 3000,
  timeoout: 5000,  // ERROR: 'timeoout' does not exist in Config
  // Typo! Without excess property check, this silently does nothing
};

// GOOD: TypeScript prevents typo at compile time

// BUT: stale object bypasses excess property check:
const opts = { host: 'localhost', port: 3000, timeoout: 5000 };
const config2: Config = opts;  // OK - no error on stale object
// The typo slips through when assigned via variable
// This is the excess property check limitation
```

> **Code walkthrough:** Structural typing makes TypeScript compatibleice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> with JavaScript patterns - any object with the right shape satisfies
> an interface without needing an explicit `implements` declaration.
> The excess property check on fresh object literals is a pragmatic
> safety guard that catches typos in option objects (a very common
> JavaScript pattern). The branded types workaround achieves nominal-
> like safety by adding a unique phantom property that differs between
> domain types even when their actual properties are identical.

---

### ⚖️ Comparison Table

| Feature | Structural (TS) | Nominal (Java/C#) |
|---|---|---|
| Compatibility basis | Shape (properties) | Name (class/interface) |
| Explicit declaration needed | No | Yes |
| Duck typing | Compile-time safe | Not possible |
| Accidental compatibility | Possible | Not possible |
| JS library interop | Natural | Requires wrappers |
| Domain type safety | Requires branded types | Built-in |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> TypeScript uses structural typing: two types are compatible if they
> have the same shape. A class doesn't need to explicitly implement
> an interface - if it has all the required properties, it satisfies
> it. This is different from Java which requires explicit `implements`.

**Senior / Staff:**

> Structural typing is TypeScript's deliberate design for JavaScript
> compatibility - you can't require existing JS libraries to add
> TypeScript declarations. The consequence is that two types with
> identical shapes are interchangeable, which can cause accidental
> compatibility bugs. When domain safety is needed (UserId vs OrderId),
> I use branded types to simulate nominal typing. Excess property
> checking is the one place TypeScript appears nominal - it prevents
> typos in fresh object literals, but the check is bypassed when the
> object is assigned via a variable (a known limitation).

---

### ⚠️ Common Misconceptions

**Misconception 1: TypeScript interfaces create nominal types.**

TypeScript interfaces are purely structural. Two interfaces with
identical properties are completely interchangeable regardless of
their names. `interface UserId { id: string }` and `interface OrderId
{ id: string }` are the same type to TypeScript.

**Misconception 2: Excess property checking always applies.**

Excess property checking only applies to fresh object literals
directly assigned to a typed variable. Assignments via intermediate
variables bypass the check. This is a deliberate design trade-off:
the intermediate-variable pattern is used for extension/partial
objects, not just typos.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Wrong object type accepted at runtime.**

Symptom: A function receives an `Order` object when a `User` was
expected - both have `id: string`.

Cause: Structural typing - both types have the same shape.

Fix: Add a discriminant property (`kind: 'user' | 'order'`) or use
branded types to force nominal-like incompatibility.

**Failure: Option object typo silently ignored.**

Symptom: `{ timeoout: 5000 }` passed to a function expecting `{ timeout: number }`.
The option is ignored, no TypeScript error.

Cause: Object assigned via variable (stale), bypasses excess property check.

Fix: Pass the object literal directly (fresh), or use a type assertion to
enable the check: `doSomething({ timeoout: 5000 } satisfies Options)`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| Structural vs nominal typing - explain | Definition | ★★★ | 3 min |
| Why did TS choose structural? | Design | ★★★ | 2 min |
| What is excess property checking? | Mechanism | ★★☆ | 2 min |
| Fresh vs stale objects | Mechanism | ★★★ | 2 min |
| How to get nominal-like safety in TS? | Scenario | ★★★ | 3 min |
| Duck typing vs structural typing | Comparison | ★★★ | 2 min |
| When does structural typing cause bugs? | Failure | ★★★ | 3 min |

**Q: Why did TypeScript choose structural typing over nominal typing?**

A: TypeScript was designed to type-check existing JavaScript code. JS
uses duck typing pervasively - if it walks like a duck and quacks like
a duck, it's a duck. Nominal typing would require adding `implements`
declarations throughout all existing JS code and all npm packages.

Structural typing means:
- Existing JS libraries work without any TypeScript modifications
- Anonymous objects satisfy interfaces without declaration overhead
- The `{ toJSON(): string }` interface is satisfied by ANY object
  with a `toJSON()` method, including plain objects and non-TS classes

The cost is accidental compatibility. Two types with the same shape
are interchangeable even when they represent different domain concepts.
The mitigation for domain-critical types is branded types, which add
a phantom property to force structural incompatibility.

*What separates good from great:* Recognizing that structural typing
is a spectrum choice. TypeScript made the pragmatic choice for JS
compatibility. TypeScript 5.x added `declare const __brand: unique
symbol` as the official branded type pattern. Some newer languages
(Gleam, ReScript) offer nominal typing with ergonomic JS compilation
as an alternative approach.

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


# TypeScript Type System Soundness

---

### 🎯 Model Answer

**30 seconds:**

> TypeScript's type system is intentionally unsound - it makes
> trade-offs that allow certain type errors to pass unchecked in
> exchange for practical usability. Known unsound behaviors: bivariant
> function parameters (pre-4.x methods), `any` type escape hatch,
> type assertions, class property initialization order, and structural
> typing with covariant return types. The TypeScript team explicitly
> chose "useful" over "sound."

**3 minutes:**

Type soundness means that a type system guarantees "well-typed programs
do not go wrong" - if the type checker says a program is correct, it
won't produce a type error at runtime. TypeScript is deliberately not
fully sound.

**Known unsoundness:**

1. **`any` type**: explicit escape hatch; bypasses all checking
2. **Type assertions (`as`)**: override the type checker's judgment
3. **Bivariant method parameters**: historically, methods allowed
   bivariant parameter types (both covariant and contravariant)
   because strict function checking was a breaking change. `strictFunctionTypes:
   true` (part of `strict`) fixes this for function properties but
   not method syntax
4. **Covariant type parameters**: generic types default to covariant
   which allows some unsafe assignments
5. **Readonly at runtime**: TypeScript's `readonly` is compile-time
   only; `Object.freeze()` is needed for runtime immutability

Why unsound? Because perfect soundness would require rejecting too
many valid JavaScript programs. TypeScript prioritizes productivity
and JS compatibility over mathematical proof of correctness. The goal
is to catch the vast majority of real bugs, not every theoretically
possible bug.

**Blank Mind Recovery:**

**(1) Unsound sources:** "any, type assertions, bivariant methods,
covariant generics, readonly compile-time only."

**(2) Design choice:** "Useful > Sound. TypeScript accepts real-world
JS patterns that a sound type system would reject. Any is the
primary escape hatch."

**(3) In practice:** "TypeScript catches ~95% of real bugs. The
unsound cases require intentional circumvention (any, as). In
practice, with strict: true, most code is effectively sound."

---

### 📘 Concept Explanation

**What it is:**

Type system soundness is the property that well-typed programs cannot
produce type errors at runtime. TypeScript deliberately departs from
full soundness in specific documented ways.

**The problem it solves:**

A fully sound type system for JavaScript would reject many valid and
useful JavaScript patterns. TypeScript chose pragmatic soundness:
catch most bugs, accept some unsoundness in exchange for usability.

**How it works:**

```
Sound type system guarantee:
  If type checker accepts the program -> no type errors at runtime
  This requires: no escape hatches, conservative typing

TypeScript's deliberate unsoundness:

  1. 'any' type:
     let x: any = "hello";
     x.toFixed(); // no compile error, crashes at runtime

  2. Type assertions:
     const x = "not a number" as unknown as number;
     x.toFixed(); // no compile error, crashes at runtime

  3. Method bivariance (pre-strict):
     interface Animal { makeSound(): void; }
     interface Dog extends Animal { fetch(): void; }
     let animals: Animal[] = [];
     let dogs: Dog[] = [];
     animals = dogs;  // OK (covariant arrays - unsound but common)

  4. readonly (compile-time only):
     interface Config { readonly host: string; }
     const c: Config = { host: 'localhost' };
     (c as any).host = 'hacked';  // runtime mutation allowed

  5. Bivariant method parameters (method syntax):
     interface Fn { method(x: string): void; }
     // Methods (not function properties) are bivariant:
     // An implementation can accept Animal where string expected
```

> **Code walkthrough:** This TypeScript Type System Soundness example demonstrates a key concept in practice using interface. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**Key insight:**

```
strictFunctionTypes: true (part of strict)

  Without: function parameters are bivariant
    type F = (x: Animal) => void;
    const f: F = (x: Dog) => x.fetch();  // unsound, no error

  With: function parameters are contravariant (correct)
    const f: F = (x: Dog) => x.fetch();  // error: correct!

  BUT: methods (not function properties) remain bivariant:
  interface I {
    method(x: Animal): void;    // bivariant (method syntax)
    prop: (x: Animal) => void;  // contravariant (property syntax)
  }
```

> **Code walkthrough:** This TypeScript Type System Soundness example demonstrates a key concept in practice using interface. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example 1 (Failure) - bivariant method parameters:**

```typescript
// strictFunctionTypes: true (part of strict) - STILL unsound
// for method syntax vs property syntax:

interface Printer {
  // Method syntax: bivariant (unsound)
  print(data: string): void;
}

interface DataPrinter {
  // Property syntax: contravariant (sound)
  print: (data: string) => void;
}

class CSVPrinter {
  print(data: number[]): void {  // expects number[], not string
    data.forEach(n => console.log(n.toFixed(2)));
  }
}

// Method syntax allows unsound assignment:
const p: Printer = new CSVPrinter(); // OK! (bivariant, unsound)
p.print("hello");  // Runtime: "hello".forEach is not a function

// Property syntax correctly rejects:
const q: DataPrinter = new CSVPrinter(); // ERROR (contravariant)
```

> **Code walkthrough:** This TypeScript Type System Soundness example demonstrates interface contract definition using interface. **KEY MECHANISM:** TypeScript erases interfaces at compile time; they exist only for type checking. **WHY IT MATTERS:** structural typing means any object with matching shape satisfies the interface. **TAKEAWAY: use interfaces for public API contracts; type aliases for unions and computed types.**

**Example 2 (Wrong vs Right) - readonly unsoundness:**

```typescript
// TypeScript readonly is compile-time only:
interface ServerConfig {
  readonly host: string;
  readonly port: number;
}

function configureServer(config: ServerConfig): void {
  // TypeScript prevents direct mutation:
  // config.host = 'evil.com'; // ERROR: readonly

  // But runtime bypass is possible:
  (config as any).host = 'evil.com'; // No TS error, mutates

  // Or via Object.assign:
  Object.assign(config, { host: 'evil.com' }); // No TS error
}

// BETTER: use Object.freeze for runtime immutability
function createConfig(host: string, port: number): Readonly<ServerConfig> {
  return Object.freeze({ host, port });
}

const config = createConfig('localhost', 3000);
(config as any).host = 'evil.com'; // throws in strict mode
// TypeError: Cannot assign to read only property 'host'
```

> **Code walkthrough:** TypeScript's `readonly` prevents directice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> property assignment at compile time but has no runtime enforcement.
> The `as any` cast bypasses the compile-time check. `Object.freeze()`
> is the JavaScript runtime mechanism that actually prevents mutation -
> it throws a `TypeError` in strict mode (which all modern browsers
> and Node.js use). This is a key soundness gap: compile-time immutable
> types can be mutated at runtime with `as any`.

---

### ⚖️ Comparison Table

| Language | Soundness | Practical? | JS compat |
|---|---|---|---|
| TypeScript | Intentionally unsound | High | Native |
| Flow | Mostly sound | Medium | Native |
| Elm | Sound | High | Compiles to JS |
| PureScript | Sound | Low | Compiles to JS |
| ReScript | Sound | Medium | Compiles to JS |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> TypeScript isn't fully sound - it allows some patterns that could
> cause runtime type errors. The main escape hatches are `any` and
> type assertions. In practice with `strict: true`, most code is
> effectively safe. TypeScript prioritizes being useful over being
> mathematically perfect.

**Senior / Staff:**

> TypeScript is deliberately unsound in documented ways: `any` is
> an explicit escape hatch, type assertions bypass checking, readonly
> is compile-time only, and method parameters are bivariant in method
> syntax (contravariant with function property syntax). The TypeScript
> team's stated goal is "useful" not "sound" - they accept certain
> unsoundness to type-check valid JS patterns that a sound system
> would reject. In practice, `strict: true` eliminates most unsound
> patterns in normal code. The unsound cases require deliberate
> circumvention (explicit `any`, `as` assertions) - accidental
> unsoundness is rare with strict mode.

---

### ⚠️ Common Misconceptions

**Misconception 1: `strict: true` makes TypeScript sound.**

`strict: true` enables `strictFunctionTypes` which fixes function
property variance but not method syntax variance. `readonly` remains
compile-time only. `any` and type assertions still allow unsound code.
Strict mode reduces unsoundness significantly but does not eliminate it.

**Misconception 2: TypeScript unsoundness is a bug to be fixed.**

TypeScript's unsoundness is intentional and documented. The TypeScript
team explicitly maintains the `any` escape hatch and other unsound
features because removing them would break valid JavaScript patterns
or make TypeScript too rigid for practical use. The design philosophy
is explicitly "sound enough for 95% of real bugs."

---

### 🚨 Failure Modes and Diagnosis

**Failure: Runtime type error in code that TypeScript approved.**

Symptom: `TypeError` on a method call that TypeScript said was safe.

Cause: Usually an `any` or `as` in the call chain, or bivariant
method assignment.

Diagnose: Search for `any`, `as`, and method-syntax interfaces in the
error's call stack. The unsound point is where the type was broadened
or asserted without runtime validation.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is type soundness? | Definition | ★★★ | 2 min |
| Is TypeScript sound? Why/why not? | Design | ★★★ | 3 min |
| Bivariant vs contravariant parameters | Mechanism | ★★★ | 3 min |
| TypeScript readonly vs Object.freeze | Comparison | ★★☆ | 2 min |
| Why does TypeScript allow unsoundness? | Design | ★★★ | 3 min |
| `strictFunctionTypes` - what it fixes | Mechanism | ★★★ | 3 min |
| Runtime type error in typed code - how? | Debugging | ★★★ | 3 min |

**Q: Is TypeScript's type system sound? What are the unsound cases?**

A: TypeScript is intentionally not fully sound. The TypeScript team
has explicitly stated this is a design choice, not a bug.

Known unsound cases:

1. `any` type - bypasses all checking (explicit escape hatch)

2. Type assertions (`as`) - overrides the type checker without
   runtime validation

3. Bivariant method parameters - method syntax (not function
   property syntax) allows unsound parameter variance even with
   `strictFunctionTypes: true`

4. Covariant arrays - `Dog[]` is assignable to `Animal[]` even
   though this enables unsound writes (adding a `Cat` to a `Dog[]
   via Animal[] variable)

5. `readonly` is compile-time only - runtime mutation is possible
   via `Object.assign`, `as any`, or direct property assignment

6. Unsound inference for `catch` - before TS 4.0, caught errors
   were implicitly `any`. `useUnknownInCatchVariables: true` (part
   of strict in 4.4+) fixes this.

Why the TypeScript team accepts unsoundness:

The goal is to "type-check JavaScript in a useful way." A fully sound
type system for JavaScript would need to handle `eval`, dynamic
property access, prototype mutation, and all other JS metaprogramming
patterns - either conservatively rejecting them or requiring explicit
annotations everywhere. TypeScript chose "catch the bugs people
actually encounter" over "prevent every theoretically possible bug."

*What separates good from great:* Knowing the direction of travel.
TypeScript has gotten more sound over time (strict function types in
2.6, unknown catch variables in 4.4, exactOptionalPropertyTypes in
4.4). The trend is increasing soundness where it doesn't break
existing patterns. Understanding this helps predict which TypeScript
version options to enable for maximum safety.

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



