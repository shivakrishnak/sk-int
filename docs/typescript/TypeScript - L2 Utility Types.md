---
layout: default
title: "TypeScript - L2 Utility Types"
parent: "TypeScript"
nav_order: 5
permalink: /typescript/l2-utility-types/
---

# Built-in Utility Types

🎯 **Interview Weight:** working (★★☆) - utility types are used in every
TypeScript codebase and their correct use is tested in TypeScript interviews

---

### 🎯 Model Answer

**30 seconds:**

> TypeScript's built-in utility types transform existing types without
> repeating their structure. Core utilities: `Partial<T>` (all optional),
> `Required<T>` (all required), `Readonly<T>` (all readonly), `Pick<T,K>`
> (keep specified keys), `Omit<T,K>` (remove specified keys), `Record<K,V>`
> (dictionary type), `Exclude<T,U>` (remove union members), `Extract<T,U>`
> (keep union members), `NonNullable<T>` (remove null/undefined), `ReturnType<T>`,
> `Parameters<T>`, `Awaited<T>`.

**3 minutes:**

> Grouped by purpose:
>
> Object transformation: `Partial`, `Required`, `Readonly`
> Key selection: `Pick<T,K>`, `Omit<T,K>`, `Record<K,V>`
> Union manipulation: `Exclude<T,U>`, `Extract<T,U>`, `NonNullable<T>`
> Function types: `ReturnType<T>`, `Parameters<T>`, `ConstructorParameters<T>`,
>   `InstanceType<T>`
> Promise types: `Awaited<T>`
> String manipulation: `Uppercase<S>`, `Lowercase<S>`, `Capitalize<S>`, `Uncapitalize<S>`

**Blank Mind Recovery:**

**(1) Restate:** "Utility types transform existing types. Object: Partial,
Required, Readonly, Pick, Omit, Record. Union: Exclude, Extract,
NonNullable. Function: ReturnType, Parameters, InstanceType. Promise:
Awaited. String: Uppercase, Capitalize."

---

### 📘 Concept Explanation

**What it is:**

TypeScript's standard library provides generic utility types that
implement common type transformations. They are built on mapped types
and conditional types and are available without any import.

**The problem it solves:**

Common type transformations (make all optional, remove nulls, extract
return type) would require writing custom mapped/conditional types
for each case without utility types. The built-ins cover 80% of
real-world type transformation needs.

**How it works:**

```
COMPLETE UTILITY TYPE REFERENCE:

  OBJECT TRANSFORMATIONS:
    Partial<T>         Make all properties optional
    Required<T>        Make all properties required
    Readonly<T>        Make all properties readonly
    Pick<T, K>         Keep only keys K from T
    Omit<T, K>         Remove keys K from T
    Record<K, V>       Object with keys K, values V

  UNION MANIPULATION:
    Exclude<T, U>      Remove T members that extend U
    Extract<T, U>      Keep T members that extend U
    NonNullable<T>     Remove null and undefined from T

  FUNCTION TYPES:
    ReturnType<T>            Return type of function T
    Parameters<T>            Tuple of parameter types
    ConstructorParameters<T> Constructor parameter tuple
    InstanceType<T>          Instance type of constructor

  PROMISE TYPES:
    Awaited<T>         Recursively unwraps Promise<T>

  STRING MANIPULATION (intrinsic):
    Uppercase<S>       'hello' -> 'HELLO'
    Lowercase<S>       'WORLD' -> 'world'
    Capitalize<S>      'hello' -> 'Hello'
    Uncapitalize<S>    'Hello' -> 'hello'

IMPLEMENTATION (selected):

  type Partial<T> = { [K in keyof T]?: T[K] };
  type Required<T> = { [K in keyof T]-?: T[K] };
  type Readonly<T> = { readonly [K in keyof T]: T[K] };
  type Pick<T, K extends keyof T> = { [P in K]: T[P] };
  type Omit<T, K extends keyof T> =
    Pick<T, Exclude<keyof T, K>>;
  type Record<K extends keyof any, V> = { [P in K]: V };

  type Exclude<T, U> = T extends U ? never : T;
  type Extract<T, U> = T extends U ? T : never;
  type NonNullable<T> = T extends null | undefined ? never : T;

  type ReturnType<T extends (...args: any) => any> =
    T extends (...args: any) => infer R ? R : any;
  type Parameters<T extends (...args: any) => any> =
    T extends (...args: infer P) => any ? P : never;

USAGE PATTERNS:

  // Update DTO (optional except id):
  type UpdateUser = { id: string } & Partial<
    Omit<User, 'id' | 'createdAt' | 'deletedAt'>
  >;

  // Type-safe function result extraction:
  async function loadUser(id: string): Promise<User> { ... }
  type LoadUserResult = Awaited<ReturnType<typeof loadUser>>;
  // User (auto-derived)

  // Exhaustive Record (all union members required):
  type Status = 'active' | 'inactive' | 'banned';
  const statusColors: Record<Status, string> = {
    active: 'green',
    inactive: 'gray',
    banned: 'red',
    // Missing 'banned' -> Error
  };
```

**Why it matters:**

Utility types are the vocabulary of TypeScript type manipulation.
Writing TypeScript without them leads to repetitive, brittle type
definitions. Understanding them enables reading and contributing
to any TypeScript codebase.

**Mental model:**

> Utility types are like standard library functions for types. Just
> as you use `Array.filter()` instead of writing a custom loop,
> you use `Omit<T, 'password'>` instead of manually writing a type
> with all fields except `password`.

**Scale behavior:**

Utility types cascade: `Partial<Omit<User, 'id'>>` creates an update
type from User - remove the identity field, make all others optional.
Adding a field to `User` automatically includes it in all derived types.

---

### 💻 Code Example

**Utility types in a full CRUD API**

```typescript
// Domain model:
interface User {
  readonly id: string;
  name: string;
  email: string;
  passwordHash: string;  // never expose to client
  role: 'admin' | 'user';
  createdAt: Date;
  deletedAt?: Date;
}

// CREATE: exclude auto-generated fields
type CreateUserDto = Omit<User, 'id' | 'createdAt' | 'deletedAt'>;
// { name, email, passwordHash, role }

// UPDATE: optional all fields except id
type UpdateUserDto = { id: string } & Partial<
  Omit<User, 'id' | 'createdAt' | 'deletedAt'>
>;
// { id: string; name?: string; email?: string; ... }

// PUBLIC READ: no sensitive fields, all readonly
type PublicUser = Readonly<
  Omit<User, 'passwordHash' | 'deletedAt'>
>;
// Compile error if user.passwordHash returned to client

// BAD: manual parallel types go stale
type CreateUserDtoManual = {
  name: string;      // Must manually sync with User
  email: string;     // If User gains 'verified', must add here too
  role: 'admin' | 'user';
};

// Function return type extraction:
async function getUsers(): Promise<User[]> { ... }
type UsersResult = Awaited<ReturnType<typeof getUsers>>;
// User[] (derived automatically)

// Exhaustive role map:
type Permission = 'read' | 'write' | 'delete';
const ROLE_PERMS: Record<User['role'], Permission[]> = {
  admin: ['read', 'write', 'delete'],
  user: ['read'],
  // Adding 'viewer' to role union -> TypeScript flags missing key
};
```

> **Code walkthrough:** The `UpdateUserDto` composition chains utility
> types: first `Omit` removes auto-generated and immutable fields,
> then `Partial` makes all remaining fields optional, then intersection
> `&` adds back `id` as required. This derives the complete update
> shape from the domain model without any duplication. The `PublicUser`
> type with `Readonly<Omit<...>>` creates a compile-time contract that
> prevents accidentally returning `passwordHash` to clients - the type
> literally doesn't have that property. The `Record<User['role'], ...>`
> pattern enforces exhaustive role handling: when the `role` union
> gains a new value, every `Record<User['role'], ...>` in the codebase
> must be updated.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> TypeScript includes built-in utility types for common type transformations.
> `Partial<T>` makes all properties optional. `Pick<T, K>` keeps only
> specified keys. `Omit<T, K>` removes specified keys. `Record<K, V>`
> creates a dictionary type. `NonNullable<T>` removes null/undefined.
> `ReturnType<T>` extracts a function's return type.

**Senior / Staff:**

> Utility types are the composition layer for type derivation. The
> critical pattern: derive API DTOs from domain models using utility
> type composition, not parallel type hierarchies. `UpdateUserDto =
> Partial<Omit<User, 'id'>>` is semantically richer: it says "this is
> User without auto-generated fields, all optional." When `User` gains
> a new field, `UpdateUserDto` automatically includes it. `Exclude` and
> `Extract` are the union filtering primitives - understanding that
> `NonNullable<T>` is just `Exclude<T, null | undefined>` opens up
> custom null-filtering patterns for complex discriminated unions.

---

### ⚖️ Comparison Table

| Utility | Input | Operation | Use case |
|---|---|---|---|
| `Pick<T, K>` | Object | Keep keys K | Safe projections |
| `Omit<T, K>` | Object | Remove keys K | Remove sensitive fields |
| `Exclude<T, U>` | Union | Remove matching members | Filter unions |
| `Extract<T, U>` | Union | Keep matching members | Extract subset |
| `NonNullable<T>` | Any | Remove null/undefined | Safe unwrap |
| `Partial<T>` | Object | All keys optional | Update DTOs |
| `Required<T>` | Object | All keys required | Strict validation |

---

### 📊 Diagram

*(Omit: utility types are code-level transformations)*

---

### ⚠️ Common Misconceptions

**"Omit and Exclude are the same for union types"**

`Omit<T, K>` works on OBJECT types (removes properties by key name).
`Exclude<T, U>` works on UNION types (removes union members). Applying
`Omit` to a union returns only properties in ALL union members
(intersection of keys). For filtering union members: use `Exclude`.
`Exclude<string | number | null, null>` = `string | number`.
`Omit<A | B, 'password'>` only removes `password` if it exists in
BOTH A and B.

---

### 🚨 Failure Modes and Diagnosis

**Utility types silently including sensitive fields:**

```typescript
// SYMPTOM: API response exposes passwordHash to client
// CAUSE: Readonly applied to full User keeps all fields

// BAD: Readonly doesn't remove sensitive fields
type SafeUser = Readonly<User>;
// passwordHash is now readonly BUT still present!

// FIX: explicitly Omit sensitive fields first
type SafeUser = Readonly<Omit<User, 'passwordHash'>>;

// BETTER: explicit projection (only fields you choose)
type PublicUser = Pick<User,
  'id' | 'name' | 'email' | 'role' | 'createdAt'
>;
// Adding new User fields doesn't accidentally expose them
```

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| Difference between Pick and Omit | 2-3 min | Include vs exclude |
| Difference between Exclude and Omit | 2-3 min | Union vs object |
| Compose Partial + Omit + & | 3-4 min | UpdateDto pattern |
| Record with literal union keys | 2-3 min | Exhaustive mapping |
| ReturnType + Awaited for async | 2-3 min | Combined extraction |
| NonNullable vs Exclude null | 2-3 min | Implementation |
| Readonly + Omit for API safety | 2-3 min | Security pattern |
| Parameters for event handlers | 2-3 min | React handlers |
| Required for strict validation | 2-3 min | Form submit types |

---

**Q1: How do you create an update DTO with all fields optional except ID?**
`[SENIOR]` MECHANISM

> **Answer:**
>
> ```typescript
> // Generic pattern: required id + optional everything else
> type UpdateDto<T extends { id: unknown }> =
>   { id: T['id'] } & Partial<Omit<T, 'id'>>;
>
> type UpdateUser = UpdateDto<User>;
> // { id: string } & { name?: string; email?: string; ... }
>
> // Usage:
> async function updateUser(dto: UpdateUser): Promise<User> {
>   return db.users.update({ where: { id: dto.id }, data: dto });
> }
>
> // TypeScript errors:
> updateUser({});  // Error: 'id' is required
> updateUser({ id: '1' });  // OK: minimum valid update
> updateUser({ id: '1', name: 'Alice' });  // OK
> updateUser({ id: '1', unknown: 'x' });  // Error: excess property
> ```
>
> *What separates good from great:* The generic `UpdateDto<T>` is
> reusable for any entity with `id`. `T['id']` uses indexed access to
> correctly type the id field - works whether id is `string`, `number`,
> or a branded type. This prevents writing separate update types for
> every entity.

**Q2: What is the difference between Exclude and Extract?** `[MID]`
MECHANISM

> **Answer:**
>
> Both work on union types. `Exclude<T, U>` removes T members that
> extend U. `Extract<T, U>` keeps only T members that extend U.
>
> ```typescript
> type Mixed = string | number | null | undefined | Error;
>
> type NoNull = Exclude<Mixed, null | undefined>;
> // = string | number | Error
>
> type OnlyNull = Extract<Mixed, null | undefined>;
> // = null | undefined
>
> // With discriminated unions:
> type Event =
>   | { type: 'click'; x: number }
>   | { type: 'keydown'; key: string }
>   | { type: 'error'; message: string };
>
> type NonErrorEvent = Exclude<Event, { type: 'error' }>;
> // = { type: 'click', x: number } | { type: 'keydown', key: string }
>
> type OnlyErrors = Extract<Event, { type: 'error' }>;
> // = { type: 'error', message: string }
>
> // NonNullable is Exclude:
> type NonNullable<T> = Exclude<T, null | undefined>;
> ```
>
> *What separates good from great:* `Extract<T, U>` is the pattern
> for working with a subset of a discriminated union. In Redux, this
> filters action types handled by a specific reducer. The conditional
> type implementation: `T extends U ? T : never` distributes over
> union members - each member is independently tested against U.

**Q3: How does Record<K,V> enforce exhaustive key coverage?** `[SENIOR]`
MECHANISM

> **Answer:**
>
> `Record<K, V>` with a union K creates an object type requiring ALL
> keys in the union:
>
> ```typescript
> type Status = 'active' | 'inactive' | 'banned';
>
> // BAD: no type annotation (misses 'banned')
> const statusColors = { active: 'green', inactive: 'gray' };
> // No error - TypeScript doesn't know banned should be here
>
> // GOOD: Record enforces all members
> const statusColors: Record<Status, string> = {
>   active: 'green',
>   inactive: 'gray',
>   // Error: Property 'banned' is missing
> };
>
> // ADDING 'pending' to Status:
> // Immediately flags all Record<Status, ...> usages
> // Compile-time enforcement of exhaustive handling
>
> // With typed values:
> type Config = Record<Status, { label: string; color: string }>;
> const STATUS_CONFIG: Config = {
>   active:   { label: 'Active', color: '#22c55e' },
>   inactive: { label: 'Inactive', color: '#6b7280' },
>   banned:   { label: 'Banned', color: '#ef4444' },
> };
> ```
>
> *What separates good from great:* `Record<Status, V>` is the
> compile-time equivalent of exhaustive switch. Adding a new status
> forces every `Record<Status, ...>` to be updated - the TypeScript
> error cascade makes "forgot to update the UI mapping" impossible
> to ship unnoticed. Compare to switch statements where `default:`
> silently absorbs new cases.

---

---

# Template Literal Types

🎯 **Interview Weight:** working (★★☆) - template literal types appear
in TypeScript 4.1+ codebases and in senior TypeScript interviews

---

### 🎯 Model Answer

**30 seconds:**

> Template literal types are type-level string interpolation.
> `` `on${Capitalize<EventName>}` `` creates handler names from event
> names. Combined with mapped types, they generate entire families of
> types from string unions - used in tRPC routing, Prisma query types,
> and React event prop generation.

**3 minutes:**

> Template literal types support:
> - Literal concatenation: `` `${'GET' | 'POST'}_${string}` ``
> - Intrinsic utilities: `Uppercase<S>`, `Lowercase<S>`, `Capitalize<S>`,
>   `Uncapitalize<S>`
> - Pattern matching with infer:
>   `` T extends `${infer Prefix}:${infer Rest}` ? ... ``
> - Key generation in mapped types:
>   `` [K in keyof T as `on${Capitalize<string & K>}`] ``

**Blank Mind Recovery:**

**(1) Restate:** "Template literal types: string interpolation at type
level. `get${Capitalize<K>}` creates getter names. Combined with infer:
parse string types. Combined with mapped types: generate typed APIs.
Intrinsic: Uppercase, Lowercase, Capitalize, Uncapitalize."

---

### 📘 Concept Explanation

**What it is:**

Template literal types (TypeScript 4.1+) create new string types by
interpolating other string types. They mirror JavaScript template
literals but operate entirely at the type level.

**The problem it solves:**

Libraries with string-based APIs (event names, route paths, CSS
properties, database column names) need TypeScript types that mirror
string patterns. Without template literal types, you'd manually list
every possible string combination.

**How it works:**

```
BASIC TEMPLATE LITERAL TYPES:

  type EventName = 'click' | 'change' | 'submit';
  type HandlerName = `on${Capitalize<EventName>}`;
  // = 'onClick' | 'onChange' | 'onSubmit'

  // Union distribution:
  type Method = 'GET' | 'POST';
  type Resource = 'User' | 'Product';
  type ApiPath = `/${Lowercase<Method>}${Resource}`;
  // = '/getUser' | '/getProduct' | '/postUser' | '/postProduct'

  type Prefix = 'user' | 'admin';
  type Action = 'Created' | 'Deleted';
  type EventType = `${Prefix}${Action}`;
  // = 'userCreated' | 'userDeleted' | 'adminCreated' | 'adminDeleted'

INTRINSIC STRING TYPES:

  type Upper = Uppercase<'hello'>;    // 'HELLO'
  type Lower = Lowercase<'WORLD'>;    // 'world'
  type Cap = Capitalize<'hello'>;     // 'Hello'
  type Uncap = Uncapitalize<'Hello'>; // 'hello'

  type UpperAll = Uppercase<'hello' | 'world'>;
  // = 'HELLO' | 'WORLD'  (distributes over union)

PATTERN MATCHING WITH infer:

  // Extract route params from path:
  type ExtractParams<Path extends string> =
    Path extends `${string}:${infer Param}/${infer Rest}`
      ? Param | ExtractParams<Rest>
      : Path extends `${string}:${infer Param}`
      ? Param
      : never;

  type Params = ExtractParams<'/users/:userId/posts/:postId'>;
  // = 'userId' | 'postId'

  // Remove prefix:
  type TrimPrefix<T extends string, P extends string> =
    T extends `${P}${infer Rest}` ? Rest : T;
  type WithoutGet = TrimPrefix<'getUser', 'get'>;  // 'User'

KEY GENERATION IN MAPPED TYPES:

  type Getters<T> = {
    [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
  };
  type User = { name: string; age: number };
  type UserGetters = Getters<User>;
  // { getName: () => string; getAge: () => number }
```

**Why it matters:**

Template literal types enable type-safe APIs that would previously
require `any` or manual string indexing. Route parameter extraction,
typed event systems, and typed sort keys all use this in production.

**Mental model:**

> Template literal types are like a macro system for string types.
> You write the pattern once, TypeScript expands it to all possible
> values. It's compile-time string generation - the output is a precise
> union of all strings matching the pattern.

**Scale behavior:**

Large cross-products can be expensive. 20 resources x 20 actions x
10 formats = 4000 union members. TypeScript has a limit around 100K
members. Measure type-checking time when using large string unions.

---

### 💻 Code Example

**Template literal types for a typed event system**

```typescript
// BAD: untyped event emitter
class EventEmitter {
  on(event: string, handler: (data: any) => void) { ... }
  emit(event: string, data: any) { ... }
}
// emit('user:created', { wrong: 'shape' }) - no error

// GOOD: typed event emitter
type EventRegistry = {
  'user:created': { userId: string; email: string };
  'user:deleted': { userId: string };
  'order:placed': { orderId: string; total: number };
};

class TypedEventEmitter<T extends Record<string, unknown>> {
  on<K extends string & keyof T>(
    event: K,
    handler: (data: T[K]) => void
  ): void { ... }

  emit<K extends string & keyof T>(
    event: K,
    data: T[K]
  ): void { ... }
}

const emitter = new TypedEventEmitter<EventRegistry>();

emitter.emit('user:created', {
  userId: '123', email: 'user@example.com'
}); // OK

emitter.emit('user:created', { wrong: 'shape' });
// Error: 'wrong' not in EventRegistry['user:created']

emitter.on('user:deleted', ({ userId }) => {
  // userId: string (auto-inferred from EventRegistry)
  console.log(`User ${userId} deleted`);
});

// SORT KEY PATTERN:
type UserColumn = keyof Pick<User, 'name' | 'email' | 'createdAt'>;
type SortKey = `${UserColumn}_${'asc' | 'desc'}`;
// = 'name_asc' | 'name_desc' | 'email_asc' | 'email_desc'
//   | 'createdAt_asc' | 'createdAt_desc'

function getUsers(sortBy: SortKey): Promise<User[]> { ... }
getUsers('name_asc');      // OK
getUsers('invalid_sort');  // Error: not in SortKey
```

> **Code walkthrough:** The `TypedEventEmitter<T>` connects event names
> to their data types via the generic parameter. `K extends string & keyof T`
> narrows K to string keys of T (keyof returns `string | number | symbol`,
> the `string &` selects only string keys). When you listen to
> `'user:deleted'`, the handler parameter is automatically typed as
> `{ userId: string }`. The sort key pattern shows the most common
> production use: generating a precise union of valid sort values from
> component parts. Adding a new sortable column to `UserColumn` automatically
> adds 2 entries to `SortKey` without manual maintenance.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Template literal types create new string types by combining other
> string types, like `` `on${Capitalize<'click'>}` `` = `'onClick'`.
> They work with union types (each member gets the template applied).
> Used for: generating event handler names, creating API path types,
> and type-safe string patterns.

**Senior / Staff:**

> Template literal types are the mechanism for type-level DSLs.
> tRPC uses them for procedure names, Prisma for query builder methods,
> i18next for translation key types. The `infer` combination enables
> type-level string parsing. The combination with mapped types (generating
> keys + deriving value types from those keys) enables fully type-safe
> APIs with zero runtime overhead. Main production risk: accidentally
> creating huge union types from large cross-products. Measure type-checking
> time when using template literal types with large unions.

---

### ⚖️ Comparison Table

| Approach | Type safety | Runtime overhead | Use case |
|---|---|---|---|
| Template literal types | Compile-time | Zero | String pattern types |
| String enum | Compile-time | ~50 bytes | Named string constants |
| Literal union | Compile-time | Zero | Set of valid strings |
| `string` type | None | Zero | Any string (unsafe) |
| zod.string() | Runtime + compile | Small | Validated strings |

---

### 📊 Diagram

*(Omit: template literal types are code-level concepts)*

---

### ⚠️ Common Misconceptions

**"Template literal types validate strings at runtime"**

Like all TypeScript types, template literal types are erased at compile
time. `` `${string}:${string}` `` only validates the string format at
the TYPE level. At runtime, your code receives plain JavaScript strings.
A string that passes TypeScript's template literal type check can still
be invalid at runtime if the values violate business rules. Template
literal types catch category errors (passing `'noColon'` where
`':separated'` is needed), not semantic errors.

---

### 🚨 Failure Modes and Diagnosis

**Excessive type instantiation from template literal cross-products:**

```typescript
// SYMPTOM: "Type instantiation is excessively deep"
//          or very slow TypeScript compilation
// CAUSE: large cross-product of template literal unions

// FINE: 3 x 4 = 12 variants
type CssShorthand = `${'margin' | 'padding' | 'border'}-${
  'top' | 'right' | 'bottom' | 'left'
}`;

// DANGEROUS: ~500 CSS props x 4 sides = 2000 variants
type AllCss = `${keyof CSSStyleDeclaration}-${
  'top' | 'right' | 'bottom' | 'left'
}`;
// TypeScript may time out or throw depth error

// FIX: restrict to the specific properties you actually use
type ValidCssShorthand = `${'margin' | 'padding'}-${
  'top' | 'right' | 'bottom' | 'left'
}`;
```

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| What are template literal types? | 2-3 min | Type-level strings |
| Generating handler names | 3-4 min | on${Capitalize<K>} |
| Pattern matching with infer | 3-4 min | Route params |
| Template + mapped type combo | 3-4 min | Event system |
| Intrinsic types (Uppercase etc.) | 2-3 min | Built-in utils |
| Large union explosion risk | 2-3 min | Performance |
| Template literals vs string type | 2-3 min | Safety level |
| TypeScript version compatibility | 2-3 min | 4.1+ required |
| Branded strings with template | 2-3 min | Opaque types |

---

**Q1: How would you type a URL route string to extract its parameters?**
`[SENIOR]` MECHANISM

> **Answer:**
>
> ```typescript
> type ExtractRouteParams<T extends string> =
>   T extends `${string}:${infer Param}/${infer Rest}`
>     ? Param | ExtractRouteParams<Rest>
>     : T extends `${string}:${infer Param}`
>     ? Param
>     : never;
>
> type UserPostParams =
>   ExtractRouteParams<'/users/:userId/posts/:postId'>;
> // = 'userId' | 'postId'
>
> // Typed route handler:
> type RouteParams<T extends string> = {
>   [K in ExtractRouteParams<T>]: string;
> };
>
> function createHandler<T extends string>(
>   path: T,
>   handler: (params: RouteParams<T>) => void
> ) {
>   return { path, handler };
> }
>
> createHandler('/users/:userId/posts/:postId', (params) => {
>   params.userId;   // string (inferred)
>   params.postId;   // string (inferred)
>   params.missing;  // Error: not in params
> });
> ```
>
> *What separates good from great:* This pattern is used by Hono, Remix,
> and tRPC's routing types. The recursive conditional handles multiple
> parameters by extracting one and recursing over the rest. TypeScript's
> template literal `infer` can capture dynamic path segments - enabling
> "type-safe parsing" of URL patterns at compile time.

**Q2: How do template literal types combine with branded types?**
`[STAFF]` MECHANISM

> **Answer:**
>
> Branded types use template literals to create distinct string types:
>
> ```typescript
> // Generic branded ID:
> type EntityId<Entity extends string> = string & {
>   readonly __brand: `${Entity}Id`;
> };
>
> type UserId = EntityId<'User'>;
> type OrderId = EntityId<'Order'>;
>
> function getUser(id: UserId): Promise<User> { ... }
>
> const uid = '123' as UserId;
> const oid = '456' as OrderId;
>
> getUser(uid);    // OK
> getUser(oid);    // Error: OrderId is not UserId
> getUser('123');  // Error: string is not UserId
> ```
>
> *What separates good from great:* Branded types prevent passing a
> UserId where an OrderId is expected. At runtime they're plain strings
> (the brand is erased). Template literal branding (`${Entity}Id`) makes
> the brand self-documenting: hover over `UserId` and see
> `string & { __brand: 'UserId' }`. Used in financial applications
> (prevent mixing up currency amounts) and DDD (aggregate root IDs).

**Q3: What are practical use cases for template literal types in
production code?** `[SENIOR]` DECISION

> **Answer:**
>
> Five high-value production use cases:
>
> 1. **Typed event names**: `` `${Resource}:${Action}` `` for type-safe
>    event buses. Prevents typos in event name strings.
>
> 2. **Database sort keys**: `` `${Column}_${'asc' | 'desc'}` `` for
>    type-safe ORDER BY clauses. Adding a column auto-expands the union.
>
> 3. **i18n translation keys**: `` `${Namespace}.${Key}` `` for type-safe
>    translation function calls (i18next TypeScript plugin).
>
> 4. **CSS property types**: `` `${CssProperty}-${Side}` `` for shorthand
>    property validation in CSS-in-JS libraries.
>
> 5. **Route parameter extraction**: type-safe route handlers where
>    parameter names are extracted from the path pattern.
>
> ```typescript
> // DATABASE SORT KEY:
> type UserColumn = 'name' | 'email' | 'createdAt';
> type SortKey = `${UserColumn}_${'asc' | 'desc'}`;
> // 3 columns x 2 directions = 6 valid values
> // Adding a new column auto-expands SortKey
>
> function getUsers(sortBy: SortKey): Promise<User[]> { ... }
> getUsers('name_asc');       // OK
> getUsers('invalid_sort');   // Error: not in SortKey
> ```
>
> *What separates good from great:* Template literal types pay off when
> the alternative is `string` (losing all safety) or a large manually
> maintained literal union. The automated expansion from component unions
> prevents the "added a new column but forgot to add both sort directions"
> class of bugs - the union is always correct by construction.

**Q4: What is the 'string & K' pattern and why is it needed in mapped
types?** `[SENIOR]` MECHANISM

> **Answer:**
>
> `keyof T` returns `string | number | symbol`. Template literal types
> only accept `string` types. `string & K` narrows K to only the string
> members of the key union.
>
> ```typescript
> type WithPrefixes<T> = {
>   [K in keyof T as `prefixed_${K}`]: T[K];
>   //                          ^ Error: K could be number or symbol
> };
>
> // FIX: string & K
> type WithPrefixes<T> = {
>   [K in keyof T as `prefixed_${string & K}`]: T[K];
>   //                           ^^^^^^^^^ narrows to string keys only
> };
>
> // For most objects, keys are strings, so the & doesn't change anything
> // But TypeScript requires this for type correctness
>
> // Capitalize<string & K> is the canonical pattern:
> type Getters<T> = {
>   [K in keyof T as `get${Capitalize<string & K>}`]: () => T[K];
> };
> // Capitalize requires string argument; string & K provides that
> ```
>
> *What separates good from great:* The `string & K` pattern is required
> whenever you use `K` (from `keyof T`) in a template literal type.
> TypeScript's type system is conservative: since `K extends string |
> number | symbol`, TypeScript insists on the narrowing. In practice,
> most object keys are strings, so `string & K` simply removes the
> `number | symbol` possibilities that don't apply to your actual data.
