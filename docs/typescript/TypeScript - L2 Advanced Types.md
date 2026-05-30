---
layout: default
title: "TypeScript - L2 Advanced Types"
parent: "TypeScript"
nav_order: 4
permalink: /typescript/l2-advanced-types/
---

# Conditional Types and infer Keyword

🎯 **Interview Weight:** working (★★☆) - conditional types and `infer`
are the foundation of TypeScript's built-in utility types and are asked
in TypeScript-focused senior interviews

---

### 🎯 Model Answer

**30 seconds:**

> Conditional types allow a type to be one thing or another based on
> a condition: `T extends U ? TrueType : FalseType`. The `infer`
> keyword, used inside conditional types, captures a type that TypeScript
> infers - like pulling the return type out of a function type.
> `ReturnType<T>` is implemented as: `T extends (...args: any[]) => infer R ? R : never`.

**3 minutes:**

> Key concepts:
>
> - Conditional type: `T extends number ? 'number type' : 'other type'`
> - Distributes over union types: `type ToArray<T> = T extends any ? T[] : never`
>   with `ToArray<string | number>` gives `string[] | number[]` (not `(string | number)[]`)
> - `infer R`: declare a type variable R that TypeScript fills in from
>   the matched type. Used in: `ReturnType`, `Parameters`, `Awaited`,
>   `InstanceType`
> - To prevent distribution: wrap T in `[T]` - `[T] extends [any]`
>   evaluates T as-is, not distributed over union

**Blank Mind Recovery:**

**(1) Restate:** "Conditional type: T extends U ? A : B. Distributes
over unions by default. infer R: capture a type inside a conditional.
Used in built-in: ReturnType<T>, Parameters<T>, Awaited<T>.
To prevent distribution: [T] extends [U]."

---

### 📘 Concept Explanation

**What it is:**

Conditional types are type-level if-else expressions. They let you
create types that depend on a condition evaluated at the type level.
Combined with `infer`, they enable extracting parts of types, which
is the basis for TypeScript's utility types.

**The problem it solves:**

Some types need to change based on their input type. `ReturnType<T>`
should give you the return type of function T - which changes based
on what T is. Without conditional types, this is impossible to express
at the type level.

**How it works:**

```
CONDITIONAL TYPE SYNTAX:

  type IsString<T> = T extends string ? 'yes' : 'no';

  type A = IsString<string>;   // 'yes'
  type B = IsString<number>;   // 'no'
  type C = IsString<'hello'>;  // 'yes' (literal extends string)

DISTRIBUTION OVER UNION TYPES:

  type ToArray<T> = T extends any ? T[] : never;

  type StringArray = ToArray<string>;         // string[]
  type NumberArray = ToArray<number>;         // number[]
  type Distributed = ToArray<string | number>;
  // = string[] | number[]   NOT (string | number)[]

  // TypeScript applies the condition to each union member separately

PREVENT DISTRIBUTION: wrap T in tuple brackets

  type ToArrayNoDistribute<T> = [T] extends [any] ? T[] : never;
  type NoDistribute = ToArrayNoDistribute<string | number>;
  // = (string | number)[]   (treated as one unit)

infer KEYWORD:

  // infer R: TypeScript fills in R from the matched type
  type GetReturnType<T> = T extends (...args: any[]) => infer R
    ? R
    : never;

  type A = GetReturnType<() => string>;           // string
  type B = GetReturnType<(n: number) => boolean>; // boolean
  type C = GetReturnType<string>;                 // never

  // infer from array element type:
  type ElementType<T> = T extends (infer E)[] ? E : never;
  type StrElem = ElementType<string[]>;  // string
  type NumElem = ElementType<number[]>;  // number

  // infer from Promise:
  type Awaited<T> = T extends Promise<infer U>
    ? Awaited<U>  // recursive: unwrap nested promises
    : T;
  type A2 = Awaited<Promise<string>>;           // string
  type B2 = Awaited<Promise<Promise<number>>>;  // number

BUILT-IN UTILITY TYPES USING CONDITIONAL + infer:

  type ReturnType<T extends (...args: any) => any> =
    T extends (...args: any) => infer R ? R : any;

  type Parameters<T extends (...args: any) => any> =
    T extends (...args: infer P) => any ? P : never;

  type InstanceType<T extends abstract new (...args: any) => any> =
    T extends abstract new (...args: any) => infer R ? R : any;

PRACTICAL CONDITIONAL TYPES:

  // Flatten: unwrap nested arrays (one level)
  type Flatten<T> = T extends Array<infer Item> ? Item : T;
  type Flat = Flatten<string[]>;    // string
  type Same = Flatten<string>;      // string (unchanged)

  // UnpackPromise:
  type UnpackPromise<T> = T extends Promise<infer U> ? U : T;
  type Resolved = UnpackPromise<Promise<User>>;  // User
```

**Why it matters:**

Conditional types are how TypeScript's built-in utility types are
implemented. Understanding them allows creating custom utility types
and understanding error messages when built-in utilities produce
unexpected results.

**Mental model:**

> Conditional types are like a type-level ternary operator. `T extends U ? A : B`
> reads as: "If T is assignable to U, the type is A; otherwise, the
> type is B." The `infer` keyword is like a capture group in a regex:
> it says "whatever TypeScript matches here, capture it as R."

**Scale behavior:**

Conditional types enable DRY type definitions. Instead of writing
separate types for every possible function signature, `ReturnType<T>`
extracts the return type from any function. This scales to complex
library types with hundreds of overloads.

---

### 💻 Code Example

**Conditional types in practice**

```typescript
// BAD: manually duplicating type transformations
type GetName = (name: string) => string;
type GetAge = (age: number) => number;
// Must manually derive return types:
type GetNameReturn = string;   // Manual - can go stale
type GetAgeReturn = number;    // Manual - can go stale

// GOOD: conditional type extracts return type automatically
type ReturnType<T> = T extends (...args: any[]) => infer R ? R : never;

type GetNameReturn = ReturnType<GetName>;  // string (auto-derived)
type GetAgeReturn = ReturnType<GetAge>;    // number (auto-derived)

// PRACTICAL: get first argument type of any function
type FirstArg<T> = T extends (first: infer F, ...rest: any[]) => any
  ? F
  : never;

type F1 = FirstArg<(x: string, y: number) => void>;  // string
type F2 = FirstArg<(event: MouseEvent) => void>;      // MouseEvent
type F3 = FirstArg<() => void>;                       // never

// ADVANCED: infer multiple positions
type FlipFunction<T> = T extends (a: infer A, b: infer B) => infer R
  ? (b: B, a: A) => R
  : never;

type Flipped = FlipFunction<(x: string, y: number) => boolean>;
// (b: number, a: string) => boolean

// RECURSIVE: DeepPartial
type DeepPartial<T> = T extends object ? {
  [P in keyof T]?: DeepPartial<T[P]>;
} : T;

type NestedConfig = {
  db: { host: string; port: number };
  cache: { ttl: number };
};
type PartialConfig = DeepPartial<NestedConfig>;
// { db?: { host?: string; port?: number }; cache?: { ttl?: number } }
```

> **Code walkthrough:** The `FlipFunction<T>` type infers three positions
> simultaneously: A (first param), B (second param), and R (return type).
> It creates a new function type with A and B swapped. This demonstrates
> that `infer` can appear multiple times in one conditional type, and
> each captures its respective structural position. The `DeepPartial<T>`
> recursive mapped conditional type shows how conditional and mapped
> types combine: the conditional branches on whether T is an object,
> and if so, applies the same transformation recursively to each value.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Conditional types are like if-else for types: `T extends U ? A : B`.
> The `infer` keyword captures a type that TypeScript matches inside
> a conditional. `ReturnType<T>` uses this: it extracts the return type
> from any function type. These are used in TypeScript's built-in
> utility types.

**Senior / Staff:**

> Conditional types with `infer` are the mechanism for type-level
> structural decomposition. The key insight: TypeScript's pattern
> matching in conditional types is structural type matching - not string
> matching. `T extends (a: infer A, b: infer B) => any` decomposes
> a function type into its parts. The distribution behavior is the
> most subtle aspect: a conditional type applied to a union distributes
> over each member. `NonNullable<string | null>` = `string` because
> distribution: `NonNullable<string> | NonNullable<null>` = `string | never`
> = `string`. Suppressing distribution with `[T]` is needed when you
> want to check the union as a whole type.

---

### ⚖️ Comparison Table

| Approach | Use case | Distribution | Complexity |
|---|---|---|---|
| Conditional type | Type-level decisions | Distributes over union | Medium |
| Mapped type | Transform all properties | No distribution | Medium |
| infer in conditional | Extract sub-types | Yes (in conditional) | High |
| Generic constraint | Restrict type parameter | No | Low |

---

### 📊 Diagram

*(Omit: conditional types are code-level concepts)*

---

### ⚠️ Common Misconceptions

**"Conditional types are only for utility types - not for application code"**

Conditional types are valuable in application code: for discriminated
union handling, API response typing, and function signature extraction.
Common application uses: extracting the resolved type of async functions
for testing, creating strict config types where some fields are required
only when another field is set, and typing event handler maps where
the event data type depends on the event name.

---

### 🚨 Failure Modes and Diagnosis

**Unexpected 'never' from conditional type distribution:**

```typescript
// SYMPTOM: conditional type returns 'never' unexpectedly
// CAUSE: distribution over union member that doesn't match

type IsString<T> = T extends string ? T : never;

type A = IsString<string | number>;
// = IsString<string> | IsString<number>
// = string | never
// = string  (never absorbed in union)
// This is CORRECT - 'number' was filtered out

// BUG: when you WANT to check the union as a unit:
// Wrap in [] to prevent distribution:
type IsAllString<T> = [T] extends [string] ? T : never;
type D = IsAllString<string | number>; // never (union != string)
// vs
type E = IsString<string | number>;    // string (filtered)

// DIAGNOSIS: unexpected never = distribution producing
//            never for one member, absorbed into union
// FIX: either intentional distribution or [T] extends [U]
```

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| What is a conditional type? | 2-3 min | Type-level if-else |
| Explain infer keyword | 3-4 min | Type capture |
| How is ReturnType<T> implemented? | 3-4 min | infer R in return |
| Distribution over union types | 3-4 min | T extends any ? T[] |
| Prevent distribution with [] | 2-3 min | [T] extends [U] |
| DeepPartial implementation | 3-4 min | Recursive conditional |
| Awaited<T> recursive unwrapping | 2-3 min | Nested Promise |
| infer for multiple positions | 2-3 min | FlipFunction |
| Conditional vs mapped types | 2-3 min | When to use each |

---

**Q1: What is the 'infer' keyword and what can it capture?** `[SENIOR]`
MECHANISM

> **Answer:**
>
> `infer` declares a type variable within the `extends` clause of a
> conditional type. TypeScript fills in the variable by matching the
> type structure.
>
> ```typescript
> // Capture return type:
> type ReturnType<T> =
>   T extends (...args: any[]) => infer R ? R : never;
>
> // Capture parameter types:
> type FirstParam<T> =
>   T extends (first: infer F, ...args: any[]) => any ? F : never;
>
> // Capture Promise value:
> type PromiseValue<T> = T extends Promise<infer U> ? U : T;
>
> // Capture array element:
> type ArrayElement<T> = T extends (infer E)[] ? E : never;
>
> // Tuple head and tail (TypeScript 4.0+ variadic tuples):
> type Head<T extends any[]> = T extends [infer H, ...any[]] ? H : never;
> type Tail<T extends any[]> = T extends [any, ...infer T] ? T : never;
>
> type H = Head<[string, number, boolean]>;  // string
> type TailType = Tail<[string, number, boolean]>;  // [number, boolean]
> ```
>
> *What separates good from great:* The variadic tuple `infer` patterns
> (`...infer T`) are used in tRPC and similar libraries for type-safe
> RPC, where argument and return types need to be statically tracked
> through a chain of operations. `infer` is the primitive operation
> that makes "type-level structural decomposition" possible.

**Q2: How does conditional type distribution work and when do you
disable it?** `[SENIOR]` MECHANISM

> **Answer:**
>
> When T is a bare type parameter in `T extends U ? A : B`, TypeScript
> distributes the conditional over union members:
>
> ```typescript
> type Filter<T, U> = T extends U ? T : never;
>
> type C = Filter<string | number | boolean, string | number>;
> // Distributes:
> // Filter<string, string | number>   = string
> // Filter<number, string | number>   = number
> // Filter<boolean, string | number>  = never
> // Result: string | number  (boolean filtered out)
>
> // DISABLE with []:
> type NoDistribute<T, U> = [T] extends [U] ? T : never;
> type D = NoDistribute<string | number, string | number>;
> // Checks the UNION AS A UNIT -> true -> string | number
>
> type E = NoDistribute<string | number, string>;
> // [string | number] extends [string] ? -> false -> never
> // (number is not string)
> ```
>
> *What separates good from great:* Distribution is why `NonNullable<string | null>` = `string`:
> `NonNullable<string> | NonNullable<null>` = `string | never` = `string`.
> Suppressing distribution is needed when you want to check if an
> ENTIRE union satisfies a constraint, not just filter matching members.

**Q3: Implement DeepReadonly using recursive conditional types.** `[STAFF]`
MECHANISM

> **Answer:**
>
> ```typescript
> type DeepReadonly<T> = T extends (infer E)[]
>   ? ReadonlyArray<DeepReadonly<E>>
>   : T extends object
>   ? { readonly [K in keyof T]: DeepReadonly<T[K]> }
>   : T;
>
> type Config = {
>   server: { host: string; port: number };
>   features: string[];
> };
>
> type ReadonlyConfig = DeepReadonly<Config>;
> // {
> //   readonly server: { readonly host: string; readonly port: number };
> //   readonly features: ReadonlyArray<string>;
> // }
>
> const cfg: ReadonlyConfig = loadConfig();
> cfg.server.host = 'new';     // Error: readonly
> cfg.features.push('x');     // Error: ReadonlyArray
> cfg.server.port = 8080;     // Error: readonly (deep)
> ```
>
> *What separates good from great:* The array check MUST come before
> the object check because arrays are objects. The `infer E` captures
> the element type for the `ReadonlyArray<DeepReadonly<E>>` recursion.
> TypeScript has a recursion depth limit for conditional types -
> production `DeepReadonly` implementations use additional guards to
> handle circular references and very deep nesting.

**Q4: How is Awaited<T> implemented and what problem does it solve?**
`[SENIOR]` MECHANISM

> **Answer:**
>
> `Awaited<T>` (built-in since TypeScript 4.5) extracts the resolved
> type from a `Promise`, recursively unwrapping nested promises:
>
> ```typescript
> // Simplified implementation:
> type Awaited<T> =
>   T extends null | undefined ? T :
>   T extends object & { then(onfulfilled: infer F, ...args: any[]): any } ?
>     F extends ((value: infer V, ...args: any[]) => any) ?
>       Awaited<V>
>     : never
>   : T;
>
> // Practical usage:
> type A = Awaited<Promise<string>>;          // string
> type B = Awaited<Promise<Promise<number>>>; // number (recursive unwrap)
> type C = Awaited<string>;                   // string (not a promise)
>
> // Where you need it:
> async function fetchUser(): Promise<User> { ... }
> type UserType = Awaited<ReturnType<typeof fetchUser>>; // User
>
> // Testing pattern: infer what an async function resolves to
> type ResolvedType<T extends (...args: any) => Promise<any>> =
>   Awaited<ReturnType<T>>;
>
> type FetchResult = ResolvedType<typeof fetchUser>;  // User
> ```
>
> *What separates good from great:* The official implementation checks
> for `.then` method (thenable) rather than `extends Promise<infer U>`,
> because any thenable is awaitable in JavaScript, not just native Promises.
> This correctly handles custom promise implementations and third-party
> thenable libraries. `ReturnType<typeof fn>` combined with `Awaited<T>`
> is the standard pattern for extracting the resolved type of async
> functions without running them.

**Q5: Implement a type that makes certain keys required and leaves
others optional.** `[SENIOR]` MECHANISM

> **Answer:**
>
> ```typescript
> // RequireFields<T, K>: required K, optional rest
> type RequireFields<T, K extends keyof T> =
>   Omit<T, K> & Required<Pick<T, K>>;
>
> type User = {
>   id?: string;
>   name?: string;
>   email?: string;
>   role?: 'admin' | 'user';
> };
>
> // Make 'id' and 'name' required, keep others optional:
> type CreatedUser = RequireFields<User, 'id' | 'name'>;
> // {
> //   email?: string;
> //   role?: 'admin' | 'user';
> //   id: string;   <- required
> //   name: string; <- required
> // }
>
> const user1: CreatedUser = { id: '1', name: 'Alice' };  // OK
> const user2: CreatedUser = { id: '1' };  // Error: name required
>
> // Alternative: conditional mapped type
> type RequireFields2<T, K extends keyof T> = {
>   [P in keyof T]-?: P extends K ? T[P] : T[P] | undefined;
>   // This removes ? from all keys, but adds | undefined for non-K
>   // Not quite right - better use the Omit & Required pattern
> };
> ```
>
> *What separates good from great:* The `Omit<T, K> & Required<Pick<T, K>>`
> pattern is the standard composition for "make some keys required."
> Breaking it down: `Omit<T, K>` gets everything except the keys to
> require; `Required<Pick<T, K>>` gets just the required keys as
> non-optional; the intersection `&` combines both. This pattern appears
> in ORM types (some fields optional on creation, required after save),
> React component props (some required when another prop is set), and
> form validation types.

**Q6: What happens when infer is used with string template literal
types?** `[STAFF]` MECHANISM

> **Answer:**
>
> `infer` can capture parts of template literal types, enabling
> type-level string parsing:
>
> ```typescript
> // Extract route parameters from a path string:
> type ExtractParams<T extends string> =
>   T extends `${string}:${infer Param}/${infer Rest}`
>     ? Param | ExtractParams<`/${Rest}`>
>     : T extends `${string}:${infer Param}`
>     ? Param
>     : never;
>
> type Params = ExtractParams<'/users/:userId/posts/:postId'>;
> // 'userId' | 'postId'
>
> // Remove prefix from string type:
> type RemovePrefix<T extends string, P extends string> =
>   T extends `${P}${infer Rest}` ? Rest : T;
>
> type WithoutGet = RemovePrefix<'getUser', 'get'>;  // 'User'
> type WithoutGet2 = RemovePrefix<'setUser', 'get'>; // 'setUser' (no prefix)
>
> // Capitalize first letter (built-in since TS 4.1):
> type Capitalize<T extends string> =
>   T extends `${infer First}${infer Rest}`
>     ? `${Uppercase<First>}${Rest}`
>     : T;
> ```
>
> *What separates good from great:* Template literal type inference
> enables type-safe URL routing (Express-style `:param` extraction),
> generating typed getter/setter names from property names, and
> type-safe string parsing. Libraries like tRPC and Hono use these
> patterns extensively for their routing types. The recursion depth
> limit applies here too - for deeply nested paths, TypeScript may
> stop resolving and return `string` as a fallback.

---

---

# Mapped Types

🎯 **Interview Weight:** working (★★☆) - mapped types are the foundation
of TypeScript's utility types (Partial, Required, Pick, Omit, Record)
and appear in senior TypeScript interviews

---

### 🎯 Model Answer

**30 seconds:**

> Mapped types iterate over the keys of a type and create a new type
> by transforming each key-value pair. `[K in keyof T]: T[K]` creates
> a copy of T; `[K in keyof T]?: T[K]` creates a Partial; `[K in keyof T]-?: T[K]`
> creates a Required. They're the mechanism behind Partial, Required,
> Readonly, Pick, Omit, and Record.

**3 minutes:**

> Key mapped type syntax:
> - `[K in keyof T]`: iterate over T's keys
> - `T[K]`: indexed access type (property type for key K)
> - `?:`: add optional modifier
> - `-?:`: remove optional modifier
> - `readonly`: add readonly modifier
> - `-readonly`: remove readonly modifier
> - Key remapping: `[K in keyof T as NewKey]: T[K]`
>
> Mapped types distribute over union keys - iterating each key in
> `keyof T`.

**Blank Mind Recovery:**

**(1) Restate:** "Mapped type: [K in keyof T]: T[K]. Transform all properties.
? = optional, -? = required, readonly = immutable, -readonly = mutable.
as SomeType = remap key names. Partial, Required, Readonly, Pick,
Omit, Record are all mapped types."

---

### 📘 Concept Explanation

**What it is:**

Mapped types create new types by transforming the properties of an
existing type. The `[K in keyof T]` syntax iterates over every key
of T, applying a transformation to each property.

**The problem it solves:**

Without mapped types, you'd manually write `Partial<User>` by repeating
every User property with `?` added. For a 20-property type, this is
20 lines of maintenance overhead. Mapped types derive new types
programmatically.

**How it works:**

```
MAPPED TYPE ANATOMY:

  type MyPartial<T> = {
    [K in keyof T]?: T[K]
    //  ^^^^^^^^^  ^^  ^^^^
    //  key        ?   value type
    //
    // [K in keyof T] = for each key K in keys of T
    // ? = make each property optional
    // T[K] = the original property type at key K
  };

HOW BUILT-IN UTILITY TYPES ARE IMPLEMENTED:

  type Partial<T> = { [K in keyof T]?: T[K] };

  type Required<T> = { [K in keyof T]-?: T[K] };
  // -? removes the optional modifier

  type Readonly<T> = { readonly [K in keyof T]: T[K] };

  type Mutable<T> = { -readonly [K in keyof T]: T[K] };
  // -readonly removes the readonly modifier

  type Pick<T, K extends keyof T> = { [P in K]: T[P] };
  // Iterate over K (subset of T's keys)

  type Omit<T, K extends keyof T> = Pick<T, Exclude<keyof T, K>>;
  // Exclude = conditional type: keyof T - K

  type Record<K extends keyof any, V> = { [P in K]: V };
  // All keys K map to type V

KEY REMAPPING (TypeScript 4.1+):

  // Add getter prefix to all keys:
  type Getters<T> = {
    [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
  };

  type User = { name: string; age: number };
  type UserGetters = Getters<User>;
  // { getName: () => string; getAge: () => number }

  // Filter keys with 'as never':
  type OnlyStrings<T> = {
    [K in keyof T as T[K] extends string ? K : never]: T[K];
  };
  // Keys whose value type is not string are mapped to 'never'
  // TypeScript removes 'never' keys from the result

COMBINING MAPPED + CONDITIONAL:

  type RequireFields<T, K extends keyof T> =
    Omit<T, K> & Required<Pick<T, K>>;

  type FormOptional = {
    id?: string;
    name?: string;
    email?: string;
  };
  type RequiredId = RequireFields<FormOptional, 'id'>;
  // { name?: string; email?: string; id: string }
```

**Why it matters:**

Mapped types are the mechanism for DRY type derivation. Every time
you transform an existing type (add optional, remove properties, rename
keys), a mapped type is the right tool. Understanding them unlocks
reading TypeScript library type definitions.

**Mental model:**

> Mapped types are like `Array.map()` but for types. Just as
> `[1,2,3].map(x => x * 2)` creates `[2,4,6]` by transforming each
> element, a mapped type creates a new type by transforming each
> property. Adding a property to the source type automatically updates
> all derived mapped types.

**Scale behavior:**

Mapped types scale with the number of properties in a type. Adding
a property to `User` automatically updates `Partial<User>`,
`Required<User>`, `Readonly<User>`, and all custom derived types.

---

### 💻 Code Example

**Custom mapped types for real-world scenarios**

```typescript
// BAD: manually maintained synchronized versions of a type
type User = { id: string; name: string; email: string };
// Must manually write and keep in sync:
type UserUpdate = {
  id?: string;
  name?: string;
  email?: string;
};  // Every User change requires updating UserUpdate

// GOOD: derived type - always in sync
type UserUpdate = Partial<User>;

// CUSTOM MAPPED TYPE: form field state
type FormFields<T> = {
  [K in keyof T]: {
    value: T[K];
    error: string | null;
    touched: boolean;
  };
};

type UserForm = FormFields<{ name: string; email: string }>;
// {
//   name: { value: string; error: string | null; touched: boolean };
//   email: { value: string; error: string | null; touched: boolean };
// }

// KEY REMAPPING: add 'on' prefix to event handlers
type EventHandlers<T> = {
  [K in keyof T as `on${Capitalize<string & K>}`]: (
    event: T[K]
  ) => void;
};
type AppEventHandlers = EventHandlers<{
  click: { x: number; y: number };
  keydown: { key: string };
}>;
// {
//   onClick: (event: { x: number; y: number }) => void;
//   onKeydown: (event: { key: string }) => void;
// }

// FILTER KEYS: keep only function properties
type FunctionProperties<T> = {
  [K in keyof T as T[K] extends Function ? K : never]: T[K];
};
type Service = {
  name: string;
  getUser(id: string): User;
  saveUser(user: User): void;
  count: number;
};
type ServiceMethods = FunctionProperties<Service>;
// { getUser: ...; saveUser: ... } (name, count filtered out)
```

> **Code walkthrough:** The `FormFields<T>` mapped type wraps each
> property in a form field state object. Adding a new field to the
> form data type automatically creates a corresponding entry in
> `UserForm`. The `EventHandlers<T>` type remaps keys using
> `` `on${Capitalize<string & K>}` `` - `click` becomes `onClick`.
> The `string & K` intersection ensures `K` is treated as a string
> type (required for `Capitalize`). The `FunctionProperties<T>` type
> filters by mapping non-function keys to `never`: TypeScript removes
> `never` keys from mapped types, leaving only the function properties.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Mapped types transform all properties of an existing type. `[K in keyof T]`
> iterates each key. You can make them optional (`?`), required (`-?`),
> or readonly. The built-in utility types (Partial, Required, Readonly,
> Pick, Omit, Record) are all implemented as mapped types.

**Senior / Staff:**

> Mapped types are the primary mechanism for type derivation. The
> combination of mapped types with conditional types enables expressing
> virtually any type transformation. Key remapping with `as` (TypeScript 4.1)
> unlocked generating getter/setter pairs, filtering by value type,
> and prefix/suffix naming. The key insight: `never` in the key position
> removes the property from the result - this is how filter mapped
> types work. For library authors: understanding mapped types is essential
> for writing generic utilities that work correctly with any shape of input.

---

### ⚖️ Comparison Table

| Approach | Transforms | Key Remap | Conditional | Use case |
|---|---|---|---|---|
| Mapped type | All properties | Yes (as) | With conditional | Property transforms |
| Conditional type | Single type | No | Yes | Type-level branching |
| Utility types (Partial etc.) | All (predefined) | No (some) | Some | Common transforms |
| Template literal | String keys | With mapped | No | Key name generation |

---

### 📊 Diagram

*(Omit: mapped types are code-level concepts)*

---

### ⚠️ Common Misconceptions

**"Omit<T,K> directly removes a key from the mapped type"**

`Omit<T, K>` is NOT a direct mapped type with a removal operation.
It's implemented as `Pick<T, Exclude<keyof T, K>>`: first use `Exclude`
(a conditional type) to get all keys EXCEPT K, then `Pick` them.
This matters for union types: `Omit<A | B, 'x'>` is NOT
`Omit<A, 'x'> | Omit<B, 'x'>` - it only keeps keys in BOTH A and B.
For truly distributive Omit over unions, use:
`type DistributiveOmit<T, K extends keyof any> = T extends any ? Omit<T, K> : never`.

---

### 🚨 Failure Modes and Diagnosis

**Mapped type key remapping breaking IDE navigation:**

```typescript
// SYMPTOM: go-to-definition doesn't work for remapped keys
// CAUSE: key remapping breaks the structural connection to source

// Remapped keys create NEW types - IDE navigation doesn't know
// that 'onClick' came from 'click' in the source type

type EventHandlers<T> = {
  [K in keyof T as `on${Capitalize<string & K>}`]: T[K];
};
// 'onClick' in EventHandlers has no IDE link to 'click' in T
// This is a known limitation of TypeScript's mapped type key remapping

// WORKAROUND: for better DX, consider explicit interface instead of
// computed keys when the type is small and stable:
// interface MyHandlers { onClick: ...; onKeydown: ...; }
// (More verbose but better IDE experience)
```

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| How is Partial<T> implemented? | 2-3 min | [K in keyof T]? |
| How is Omit<T,K> implemented? | 3-4 min | Pick + Exclude |
| Key remapping with 'as' | 3-4 min | Getters pattern |
| Filter properties by value type | 3-4 min | as T[K] extends |
| Combine mapped + conditional | 3-4 min | DeepPartial |
| Record<K,V> implementation | 2-3 min | [P in K]: V |
| -? and -readonly modifiers | 2-3 min | Required, Mutable |
| Homomorphic vs non-homomorphic | 3-4 min | keyof T vs union |
| Distributive Omit for union types | 3-4 min | T extends any? |

---

**Q1: What is a homomorphic mapped type and why does it matter?**
`[STAFF]` MECHANISM

> **Answer:**
>
> A homomorphic mapped type iterates over `keyof T` (keys of a specific
> type) and preserves type modifiers from the original. A non-homomorphic
> mapped type iterates over an arbitrary key set and does not preserve
> modifiers.
>
> ```typescript
> // HOMOMORPHIC: iterates over keyof T (preserves ?, readonly)
> type Partial<T> = { [K in keyof T]?: T[K] };
>
> type User = { name: string; readonly id: string };
> type PartialUser = Partial<User>;
> // { name?: string; readonly id?: string }
> // 'readonly' from 'id' is PRESERVED
>
> // NON-HOMOMORPHIC: iterates over arbitrary keys (no preservation)
> type Record<K extends keyof any, V> = { [P in K]: V };
> type StringRecord = Record<'a' | 'b', string>;
> // { a: string; b: string } (no modifiers, fresh type)
> ```
>
> *What separates good from great:* Homomorphic mapped types are the
> basis of "safe" utility types that don't accidentally strip modifiers.
> `Partial<T>` adding `?` while preserving `readonly` is correct behavior -
> you want the partial version to still be immutable where the original
> was. Non-homomorphic types like `Record` create fresh types with no
> structural debt to any source type.

**Q2: How do you implement RequireAtLeastOne (at least one of the keys
must be present)?** `[STAFF]` MECHANISM

> **Answer:**
>
> ```typescript
> // RequireAtLeastOne: exactly what it says
> type RequireAtLeastOne<T, Keys extends keyof T = keyof T> = {
>   [K in Keys]-?: Required<Pick<T, K>> & Partial<Omit<T, K>>;
> }[Keys];
> // Creates one type per key (required key + optional rest)
> // then unions them all together with [Keys]
>
> type Config = {
>   email?: string;
>   phone?: string;
>   address?: string;
> };
>
> type ContactInfo = RequireAtLeastOne<Config>;
> // At least one contact method must be present:
> const c1: ContactInfo = { email: 'a@b.com' };          // OK
> const c2: ContactInfo = { phone: '555-0100' };         // OK
> const c3: ContactInfo = { email: 'a@b.com', phone: '...' }; // OK
> const c4: ContactInfo = {};  // Error: at least one required
>
> // HOW IT WORKS:
> // For 'email': { email: string } & { phone?: string; address?: string }
> // For 'phone': { phone: string } & { email?: string; address?: string }
> // For 'address': { address: string } & { email?: string; phone?: string }
> // [Keys] = union of all three options
> ```
>
> *What separates good from great:* This pattern uses the "indexed
> access on a mapped type" trick: `{ [K in Keys]: SomeType<K> }[Keys]`
> creates a union of all the mapped values. Each value is the type for
> "K is required, others are optional." The union of all these options
> means "at least one is required." This is a common pattern in form
> validation types and API option objects.

**Q3: How do you make a type where exactly one key is required (XOR)?**
`[STAFF]` MECHANISM

> **Answer:**
>
> ```typescript
> // XOR: exactly one key must be present (mutually exclusive)
> type XOR<T, U> =
>   (T & { [K in Exclude<keyof U, keyof T>]?: never }) |
>   (U & { [K in Exclude<keyof T, keyof U>]?: never });
>
> // Example: payment method (card OR bank, not both)
> type CardPayment = { type: 'card'; cardNumber: string };
> type BankPayment = { type: 'bank'; accountNumber: string };
>
> type Payment = XOR<CardPayment, BankPayment>;
>
> const p1: Payment = { type: 'card', cardNumber: '1234' };  // OK
> const p2: Payment = { type: 'bank', accountNumber: '5678' }; // OK
> const p3: Payment = {
>   type: 'card',
>   cardNumber: '1234',
>   accountNumber: '5678'  // Error: accountNumber is 'never' for card
> };
>
> // THE TRICK: adding `never` properties to each side:
> // CardPayment with XOR gets: accountNumber?: never
> // So you CAN'T specify accountNumber when type is 'card'
> ```
>
> *What separates good from great:* The `?: never` pattern is the
> TypeScript idiom for "this property must not be present." When you
> assign `never` to a key, TypeScript won't let you provide a value
> for that key (because nothing is assignable to `never`). Combined
> with XOR, this creates truly exclusive types - the TypeScript encoding
> of "exclusive OR" from set theory.
