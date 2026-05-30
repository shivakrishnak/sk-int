---
layout: default
title: "JavaScript - L1 Types and Variables"
parent: "JavaScript"
nav_order: 2
permalink: /javascript/l1-types-and-variables/
---

# JavaScript Data Types

🎯 **Interview Weight:** foundational (★☆☆) - tested in every
JavaScript interview; cornerstone for understanding type coercion,
`typeof`, and runtime errors

---

### 🎯 Model Answer

**30 seconds:**

> JavaScript has 8 data types: 7 primitives (string, number, bigint,
> boolean, undefined, null, symbol) and 1 object type (which includes
> objects, arrays, functions, Date, Map, Set). Primitives are immutable
> and passed by value. Objects are mutable and passed by reference.
> `typeof` distinguishes most types but has the `typeof null === 'object'`
> quirk.

**3 minutes:**

> The key distinctions:
>
> **Primitives** (7 types): string, number, bigint, boolean, undefined,
> null, symbol. They are immutable: `"hello".toUpperCase()` returns
> a new string; the original is unchanged. Primitives are compared
> by value: `"a" === "a"` is true.
>
> **Object** (1 type): includes plain objects `{}`, arrays `[]`, functions,
> Date, RegExp, Map, Set, etc. They are mutable and compared by
> reference: `{} === {}` is false (different objects in memory).
>
> Number type: all numbers in JavaScript (except BigInt) are IEEE 754
> double-precision floats. This means `0.1 + 0.2 !== 0.3` and the
> max safe integer is `Number.MAX_SAFE_INTEGER` (2^53 - 1).
>
> `typeof` operator: returns a string identifying the type, but with
> quirks: `typeof null === 'object'` (historical bug), `typeof function(){}
> === 'function'` (functions are objects, but typeof gives 'function').

**Blank Mind Recovery:**

**(1) Restate:** "7 primitives: string, number, bigint, boolean,
undefined, null, symbol. 1 object type. Primitives by value; objects
by reference."

---

### 📘 Concept Explanation

**What it is:**

JavaScript's type system defines how values are classified, stored,
compared, and passed. Understanding types is prerequisite to understanding
coercion, equality, reference semantics, and runtime errors.

**The problem it solves:**

JavaScript's dynamic typing means any variable can hold any value
at any time. Understanding the type system helps predict behavior
when operations mix types, when values are compared, and when
functions receive unexpected input.

**How it works:**

```
JAVASCRIPT TYPE SYSTEM:

PRIMITIVES (7 types) - immutable, passed by value:

  string:
    "hello", 'world', `template ${literal}`
    typeof: "string"
    Immutable: methods return new strings
    UTF-16 encoding (emoji take 2 code units)

  number:
    42, 3.14, -0, Infinity, -Infinity, NaN
    typeof: "number"
    IEEE 754 double-precision float
    64-bit: 1 sign + 11 exponent + 52 fraction bits
    Integer precision: safe up to 2^53 - 1
    Float imprecision: 0.1 + 0.2 = 0.30000000000000004
    NaN is of type number and NaN !== NaN

  bigint:
    42n, BigInt(42), BigInt("9007199254740993")
    typeof: "bigint"
    Arbitrary precision integers
    Cannot mix with number: 1n + 1 throws TypeError
    Use for: very large integers, cryptography

  boolean:
    true, false
    typeof: "boolean"
    Falsy values: false, 0, -0, 0n, "", null,
                  undefined, NaN
    All else: truthy

  undefined:
    Variable declared but not assigned
    Missing function parameter
    Function with no return statement
    Object property that doesn't exist
    typeof: "undefined"

  null:
    Explicit absence of value (intentional "no value")
    typeof: "object"  <- HISTORICAL BUG (ES1, unfixable)
    Check null: value === null (not typeof)

  symbol:
    Symbol("description")
    typeof: "symbol"
    Globally unique identifier (no two symbols equal)
    Use: unique object keys, avoiding name collisions
    Symbol.iterator, Symbol.toPrimitive: well-known symbols

OBJECT (1 type) - mutable, passed by reference:

  Plain objects:   { key: value }
  Arrays:          [1, 2, 3]
  Functions:       function() {} / () => {}
  Date:            new Date()
  RegExp:          /pattern/flags
  Map:             new Map()
  Set:             new Set()
  WeakMap:         new WeakMap()
  WeakSet:         new WeakSet()
  Promise:         new Promise()
  typeof all:      "object" (except function -> "function")

REFERENCE vs VALUE:

  // Primitives - passed by value (copy)
  let a = 5;
  let b = a;
  b = 10;
  console.log(a); // 5 (unchanged)

  // Objects - passed by reference
  const obj1 = { x: 1 };
  const obj2 = obj1;  // obj2 points to same object
  obj2.x = 99;
  console.log(obj1.x); // 99 (changed!)

  // To copy an object:
  const copy = { ...obj1 };     // shallow copy (spread)
  const deep = JSON.parse(JSON.stringify(obj1)); // deep
  // or structuredClone(obj1) [ES2022]

TYPE CHECKING:
  typeof "string"    // "string"
  typeof 42          // "number"
  typeof true        // "boolean"
  typeof undefined   // "undefined"
  typeof null        // "object" (BUG! use === null)
  typeof {}          // "object"
  typeof []          // "object" (use Array.isArray())
  typeof function(){}// "function"
  typeof Symbol()    // "symbol"
  typeof 42n         // "bigint"

  // Reliable checks:
  Array.isArray([])       // true
  value === null          // null check
  Number.isNaN(NaN)       // true (not global isNaN)
  Number.isFinite(42)     // true
  obj instanceof Date     // true for Date instances
  Object.prototype.toString.call(value) // "[object ...]"
```

---

### 💻 Code Example

**Type checking and reference semantics**

```javascript
// BAD: unreliable type checks
function processInput(value) {
  if (typeof value == "object") {
    // Catches: objects, arrays, null, Date
    // Misses: functions
    // BUG: null passes this check
    value.forEach(item => console.log(item));
    // TypeError if value is null or plain object
  }
}

// GOOD: precise type checks
function processInput(value) {
  if (value === null || value === undefined) {
    return null;
  }
  if (Array.isArray(value)) {
    return value.map(String);
  }
  if (typeof value === 'object') {
    return Object.values(value);
  }
  return String(value);  // primitives
}

// Reference semantics gotcha:
function updateConfig(config) {
  config.debug = true;  // MUTATES the original object!
  return config;
}
const myConfig = { host: 'localhost', port: 3000 };
const updated = updateConfig(myConfig);
console.log(myConfig.debug);  // true (original mutated!)

// FIXED: don't mutate, return a new object
function updateConfig(config) {
  return { ...config, debug: true }; // spread = new object
}
const myConfig = { host: 'localhost', port: 3000 };
const updated = updateConfig(myConfig);
console.log(myConfig.debug);  // undefined (original safe)

// Number precision:
console.log(0.1 + 0.2);  // 0.30000000000000004
console.log(0.1 + 0.2 === 0.3);  // false (!)
// Fix: compare with epsilon
const EPSILON = Number.EPSILON;
console.log(Math.abs(0.1 + 0.2 - 0.3) < EPSILON); // true
// For money: use integer arithmetic (cents) or BigInt
// never store $9.99 as a float
```

> **Code walkthrough:** The reference semantics bug is one of the
> most common production issues in JavaScript: a function receives an
> object, modifies it thinking it's a local copy, and silently corrupts
> the caller's data. The fix (spread operator `{...config}`) creates
> a shallow copy, so the function's modifications are isolated.
> The float precision issue explains why financial applications must
> never store monetary values as `number` - use integers (cents) or
> a dedicated decimal library. The GOOD type check demonstrates
> the correct order: check for `null` first (before `typeof 'object'`),
> then use `Array.isArray` before checking for plain objects.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> JavaScript has 7 primitives (string, number, bigint, boolean,
> undefined, null, symbol) and 1 object type. Primitives are passed
> by value; objects by reference. `typeof null === 'object'` is a
> historical bug - check null with `=== null`. Use `Array.isArray()`
> not `typeof` to check for arrays.

---

**Senior / Staff:**

> Type system knowledge matters in production: reference semantics
> means object parameters are mutable - functions should not mutate
> inputs (pure functions). Float precision means monetary values
> must use integer arithmetic or BigInt. The type system's implicit
> coercion (`==`) is why TypeScript's value is not just autocomplete -
> it prevents entire categories of type-coercion bugs at compile time.

---

### ⚠️ Common Misconceptions

**"Arrays are a different type from objects"**

`typeof []` returns `"object"`. Arrays ARE objects in JavaScript -
they are objects with numeric keys and a `length` property, plus
inherited Array methods. `Array.isArray([])` returns true; this is
the reliable way to check for arrays. Consequence: `[].constructor
=== Array` is true, `[] instanceof Array` is true, but `typeof []
=== "object"` (not "array").

---

### 🚨 Failure Modes and Diagnosis

**Symptom: unexpected mutation of function arguments**

```javascript
// DETECT: log object before and after function call
const obj = { count: 0 };
console.log('before:', JSON.stringify(obj));
suspiciousFunction(obj);
console.log('after:', JSON.stringify(obj));

// PREVENT: freeze objects that should be immutable
const config = Object.freeze({ debug: false, port: 3000 });
config.debug = true;   // silently fails in sloppy mode
                        // throws in strict mode

// DEEP FREEZE for nested objects:
function deepFreeze(obj) {
  Object.getOwnPropertyNames(obj).forEach(name => {
    const value = obj[name];
    if (value && typeof value === 'object') {
      deepFreeze(value);
    }
  });
  return Object.freeze(obj);
}
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Name all 8 JavaScript types | 1-2 min | Basic recall |
| Primitive vs object difference | 2 min | Value vs reference |
| Why typeof null is 'object' | 1-2 min | Historical knowledge |
| 0.1 + 0.2 != 0.3 explanation | 2-3 min | IEEE 754 knowledge |
| How to check if a value is an array | 1-2 min | Array.isArray |
| What are falsy values in JavaScript | 2 min | Boolean coercion |
| What is NaN and how to check for it | 2 min | NaN quirk |

---

**Q1: What is the difference between undefined and null?**
`[JUNIOR]` DEFINITION

> **Answer:**
>
> Both represent "no value" but with different semantics:
>
> **undefined**: a value was not assigned. JavaScript sets it
> automatically in several situations:
> - Variable declared but not assigned: `let x; // x is undefined`
> - Function parameter not provided: `function f(x) {} f(); // x is undefined`
> - Object property that doesn't exist: `obj.missing // undefined`
> - Function with no `return`: returns `undefined`
>
> **null**: explicitly assigned "no value". It must be explicitly set:
> - `const user = null;  // intentionally no user`
> - Signals intentional absence vs accidental absence
>
> Type check differences:
> ```javascript
> typeof undefined  // "undefined"
> typeof null       // "object" (historical bug)
> undefined == null // true  (loose equality - both "empty")
> undefined === null // false (strict - different types)
>
> // Null check pattern:
> if (value == null) { /* handles both null AND undefined */ }
> if (value === null) { /* only null, not undefined */ }
> if (value === undefined) { /* only undefined */ }
> ```
>
> *What separates good from great:* The `== null` check (loose
> equality) is a deliberate JavaScript idiom that checks for BOTH
> null and undefined simultaneously. It's one of the few cases where
> `==` is preferred over `===`. When you want to say "this value
> was not provided OR was explicitly cleared," `value == null` is
> correct and idiomatic. Many modern codebases use the nullish
> coalescing operator `??` and optional chaining `?.` which both
> treat null and undefined identically - acknowledging that in most
> cases the semantic distinction doesn't matter: `user?.name ?? 'Guest'`
> works whether user is null or undefined.

---

---

# Variables, Scope, and Hoisting

🎯 **Interview Weight:** foundational (★☆☆) - appears in every
JavaScript interview; `var` vs `let` vs `const` is a classic question

---

### 🎯 Model Answer

**30 seconds:**

> `var` is function-scoped and hoisted with an `undefined` value.
> `let` and `const` are block-scoped and in a Temporal Dead Zone
> (TDZ) before their declaration. `const` prevents reassignment
> but not mutation of objects. Prefer `const` by default, use `let`
> when reassignment is needed, avoid `var` in modern code.

**3 minutes:**

> Scope defines where a variable is accessible:
>
> - **Global scope**: top-level variables, accessible everywhere
> - **Function scope**: `var` - visible throughout the entire function
> - **Block scope**: `let` and `const` - visible only within `{}`
>
> **Hoisting**: variable declarations are processed before code executes.
> `var` declarations are hoisted and initialized to `undefined`. `let`/`const`
> are hoisted but NOT initialized - accessing them before declaration
> throws a ReferenceError (Temporal Dead Zone).
>
> **TDZ (Temporal Dead Zone)**: the period between the start of a
> block and the `let`/`const` declaration. Accessing the variable
> here throws a ReferenceError, which is better behavior than `var`'s
> silent `undefined` (easier to catch bugs).
>
> **`const` with objects**: `const` prevents reassignment of the variable
> binding, NOT mutation of the value. `const obj = {}; obj.x = 1`
> works. `const obj = {}; obj = {}` throws.

**Blank Mind Recovery:**

**(1) Restate:** "var = function-scoped + hoisted to undefined.
let/const = block-scoped + TDZ. const = no reassignment."

---

### 📘 Concept Explanation

**What it is:**

Scoping rules determine which variables are accessible where. Hoisting
is JavaScript's behavior of processing declarations before executing
code. Together they explain many classic JavaScript bugs and why
modern code uses `let`/`const` over `var`.

**The problem it solves:**

`var`'s function-scoping causes bugs: `var` in a loop body is
visible outside the loop, `var` in an `if` block is visible outside
the block. Hoisting makes `var` silently `undefined` before declaration.
`let`/`const` (ES6) provide predictable block scoping and TDZ errors.

**How it works:**

```
VAR vs LET vs CONST:

  Feature          var         let         const
  Scope            function    block       block
  Hoisting         yes+init    yes+TDZ     yes+TDZ
  Re-declaration   yes         no          no
  Reassignment     yes         yes         no
  Global property  yes         no          no

FUNCTION SCOPE (var):
  function example() {
    if (true) {
      var x = 10;  // function-scoped, not block-scoped
    }
    console.log(x);  // 10 (accessible outside if block)
  }
  console.log(x);    // ReferenceError (out of function)

  for (var i = 0; i < 3; i++) {
    setTimeout(() => console.log(i), 0); // 3, 3, 3 (!)
  }
  // var i is shared across all iterations
  // By the time timeouts run, loop is done: i === 3

BLOCK SCOPE (let/const):
  function example() {
    if (true) {
      let x = 10;  // block-scoped
    }
    console.log(x);  // ReferenceError (out of block)
  }

  for (let i = 0; i < 3; i++) {
    setTimeout(() => console.log(i), 0); // 0, 1, 2
  }
  // let creates a new i for each iteration
  // Each closure captures a different i

HOISTING:

  VAR hoisting - initialized to undefined:
    console.log(x);  // undefined (no error)
    var x = 5;
    // Interpreted as:
    var x;           // declaration hoisted to top
    console.log(x);  // undefined
    x = 5;

  LET/CONST hoisting - Temporal Dead Zone:
    console.log(y);  // ReferenceError
    let y = 5;       // TDZ from block start to here
    // Declaration is hoisted but not initialized
    // Accessing before declaration = ReferenceError

  FUNCTION hoisting:
    greet();          // "Hello!" (works)
    function greet() { console.log("Hello!"); }
    // Function declarations are fully hoisted (body too)

    hello();           // TypeError: hello is not a function
    var hello = function() { console.log("Hello!"); };
    // var is hoisted to undefined; calling undefined() throws

CONST IMMUTABILITY NUANCE:
  const PI = 3.14;
  PI = 3.15;           // TypeError: Assignment to constant

  const config = { debug: false };
  config.debug = true;  // OK: mutating the object (allowed)
  config = {};          // TypeError: reassigning the variable

  // To make an object truly immutable:
  const config = Object.freeze({ debug: false });
  config.debug = true;  // silently fails (throws in strict mode)

CLOSURE AND SCOPE CHAIN:
  function outer() {
    const x = 10;   // in outer's scope
    function inner() {
      const y = 20; // in inner's scope
      console.log(x + y); // 30 - inner can see outer's x
    }
    inner();
    // outer cannot see y (inner's scope)
  }
  // Scope chain: inner -> outer -> global
  // Variable lookup travels UP the chain
```

---

### 💻 Code Example

**Classic var scope bug and the fix**

```javascript
// BAD: var in a loop (classic interview trap)
for (var i = 0; i < 5; i++) {
  setTimeout(function() {
    console.log(i); // prints 5, 5, 5, 5, 5
  }, i * 100);
}
// Reason: var i is function-scoped (or global).
// There is ONE i, shared by all closures.
// When timeouts run: loop is done, i === 5.

// GOOD: let creates a new binding per iteration
for (let i = 0; i < 5; i++) {
  setTimeout(function() {
    console.log(i); // prints 0, 1, 2, 3, 4
  }, i * 100);
}
// Reason: let creates a new i for EACH iteration.
// Each closure captures its own i.

// ALSO GOOD: IIFE solution (pre-ES6)
for (var i = 0; i < 5; i++) {
  (function(capturedI) {
    setTimeout(function() {
      console.log(capturedI); // prints 0, 1, 2, 3, 4
    }, capturedI * 100);
  })(i);  // immediately invoke, passing current i
}

// const in practice:
const user = { name: 'Alice', role: 'admin' };
user.role = 'user';  // OK - mutating object properties
// user = { name: 'Bob' };  // TypeError - reassigning

// const for arrays:
const items = [1, 2, 3];
items.push(4);     // OK - mutating the array
items[0] = 0;      // OK - mutating elements
// items = [];     // TypeError - reassigning
```

> **Code walkthrough:** The classic `var` loop bug trips up many
> JavaScript engineers. `var` has function scope, not block scope,
> so the loop creates ONE `i` variable shared across all iterations
> and all closures. By the time the setTimeout callbacks fire, the
> loop has completed and `i === 5`. `let` solves this because it
> creates a fresh binding per iteration - each iteration gets its
> own `i` value, and each closure captures a different one.
> The IIFE approach is the pre-ES6 workaround: immediately invoking
> a function with the current `i` creates a new function scope
> with a captured `capturedI` per iteration. Prefer `let` in all
> modern code.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `var` = function-scoped, hoisted to `undefined`. `let`/`const` =
> block-scoped, TDZ before declaration. `const` prevents reassignment
> but not object mutation. Prefer `const` by default; use `let`
> when you need to reassign. Avoid `var`.

---

**Senior / Staff:**

> The `var` loop bug (`i` is 5 for all callbacks) is explained by
> function scope + closures over the shared binding. `let` fixes it
> by creating a new binding per iteration. TDZ is a deliberate
> improvement over `var`'s silent `undefined` - ReferenceErrors are
> easier to debug. `const` communicates intent: "this variable won't
> be reassigned." Object.freeze adds a second layer of protection
> for truly immutable values.

---

### ⚠️ Common Misconceptions

**"const means the value is immutable"**

`const` prevents reassignment of the variable binding, NOT mutation
of the value. `const obj = {}; obj.x = 1` works because you're
mutating the object, not reassigning `obj`. The only truly immutable
primitive values are... all primitives (they can't be mutated in place).
For truly immutable objects: use `Object.freeze()` (shallow) or a
deep freeze utility.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: ReferenceError for let/const before declaration**

```javascript
// SYMPTOM:
console.log(name);  // ReferenceError: Cannot access 'name'
                    // before initialization
let name = 'Alice';

// ROOT CAUSE: Temporal Dead Zone
// let/const are hoisted but NOT initialized.
// Accessing in TDZ = ReferenceError.

// COMMON TDZ TRAP - circular dependencies:
// fileA.js: import { B } from './fileB.js'; const A = B + 1;
// fileB.js: import { A } from './fileA.js'; const B = A + 1;
// One of A or B is in TDZ when the other initializes.

// DIAGNOSIS:
// Stack trace will include "Cannot access '...' before initialization"
// Look for the variable name, check if it's used before declared.
// In bundlers: may indicate a circular import.
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| var vs let vs const differences | 2-3 min | Scope and hoisting |
| Classic var loop bug | 3-4 min | Scope + closures |
| What is hoisting | 2 min | Declaration processing |
| What is TDZ | 2-3 min | let/const TDZ |
| const with objects | 2 min | Binding vs value |
| Function hoisting vs var hoisting | 2 min | Declaration types |
| Why avoid var | 2 min | Best practices |

---

**Q1: What is the Temporal Dead Zone?** `[JUNIOR]` DEFINITION

> **Answer:**
>
> The Temporal Dead Zone (TDZ) is the period between the start of a
> block and the `let`/`const` declaration where the variable exists
> but cannot be accessed.
>
> ```javascript
> {
>   // TDZ for 'name' starts here
>   console.log(name);  // ReferenceError: Cannot access
>                       // 'name' before initialization
>   let name = 'Alice'; // TDZ ends here
>   console.log(name);  // 'Alice'
> }
> ```
>
> Why `let`/`const` have TDZ but `var` does not:
> - `var` is hoisted AND initialized to `undefined`
> - `let`/`const` are hoisted but NOT initialized
> - Accessing before initialization throws ReferenceError
>
> TDZ is a FEATURE, not a bug. It prevents a class of bugs where
> `var` silently returned `undefined` when used before its declaration:
>
> ```javascript
> // var: silently wrong
> console.log(x);  // undefined (should be an error)
> var x = 5;
>
> // let: clearly wrong
> console.log(x);  // ReferenceError (immediately obvious)
> let x = 5;
> ```
>
> *What separates good from great:* TDZ can occur in unexpected
> places, particularly with default parameter values:
> ```javascript
> function f(a = b, b = 1) {  // a's default uses b before b is init
>   return [a, b];
> }
> f();  // ReferenceError: b is not defined
>       // b is in TDZ when a's default is evaluated
> ```
> This is because parameters are evaluated left-to-right, and `b`
> is in TDZ when `a = b` is evaluated. The rule: don't reference
> a later parameter in an earlier parameter's default value.

---

---

# Type Coercion and Equality

🎯 **Interview Weight:** foundational (★☆☆) - one of JavaScript's
most tested topics; coercion bugs cause real production issues

---

### 🎯 Model Answer

**30 seconds:**

> Type coercion is JavaScript's automatic conversion of values from
> one type to another. `==` (loose equality) triggers coercion;
> `===` (strict equality) does not. Use `===` always. Falsy values
> are: `false`, `0`, `-0`, `0n`, `""`, `null`, `undefined`, `NaN`.
> Everything else is truthy.

**3 minutes:**

> Coercion happens in three contexts:
>
> 1. **Arithmetic operators**: `+` with a string converts the other
>    operand to string. `-`, `*`, `/` convert operands to numbers.
> 2. **Comparison `==`**: follows complex Abstract Equality Comparison
>    rules: `null == undefined` is true, `null == 0` is false,
>    `"3" == 3` is true (string converted to number).
> 3. **Boolean context** (if/while/ternary): values are coerced to
>    boolean via "falsy/truthy" rules.
>
> Rules of thumb:
> - Always use `===` and `!==`
> - Use `Boolean(value)` or `!!value` for explicit boolean conversion
> - Use `Number(value)` or `parseInt(value, 10)` for explicit number conversion
> - Be aware that `+` is overloaded: `1 + "2" === "12"` (string concat)
>   but `1 - "2" === -1` (numeric subtraction)

**Blank Mind Recovery:**

**(1) Restate:** "== does coercion; === does not. Use === always.
Falsy: false, 0, '', null, undefined, NaN."

---

### 📘 Concept Explanation

**What it is:**

Type coercion is JavaScript's implicit conversion of values between
types when operators or functions expect a different type than provided.
It makes some operations convenient but introduces unexpected behavior
in others.

**The problem it solves (and creates):**

Coercion allows `"The answer is " + 42` to produce `"The answer is 42"`
without explicit conversion - convenient. It also allows `[] + {}` to
produce `"[object Object]"` and `0 == "0"` to be true - confusing.
The solution: use `===` for all equality comparisons.

**How it works:**

```
COERCION MECHANISMS:

TO NUMBER (Number() conversion rules):
  Number("")        // 0   (empty string)
  Number("3")       // 3   (numeric string)
  Number("3.5")     // 3.5
  Number("3abc")    // NaN (non-numeric string)
  Number(true)      // 1
  Number(false)     // 0
  Number(null)      // 0
  Number(undefined) // NaN
  Number([])        // 0   ([] -> "" -> 0)
  Number([3])       // 3   ([3] -> "3" -> 3)
  Number([1,2])     // NaN ([1,2] -> "1,2" -> NaN)
  Number({})        // NaN ({} -> "[object Object]" -> NaN)

TO STRING (String() conversion rules):
  String(42)        // "42"
  String(true)      // "true"
  String(false)     // "false"
  String(null)      // "null"
  String(undefined) // "undefined"
  String([1,2,3])   // "1,2,3"
  String({})        // "[object Object]"

TO BOOLEAN (truthy/falsy):
  FALSY (8 values):
    false, 0, -0, 0n (BigInt zero),
    "", '', `` (empty string),
    null, undefined, NaN
  TRUTHY: everything else, including:
    "0"     (non-empty string, truthy!)
    "false" (non-empty string, truthy!)
    []      (empty array, truthy!)
    {}      (empty object, truthy!)
    -1      (non-zero number, truthy)

ABSTRACT EQUALITY (==) ALGORITHM SUMMARY:
  Same type: same as ===
  null == undefined  -> true (only combination of null/undefined)
  null == anything_else -> false (0, "", false all false)
  If one is string, other is number: convert string to number
  If one is boolean: convert boolean to number first
  If one is object, other is primitive: call valueOf/toString

  Notable:
    null == undefined  // true
    null == 0          // false (!)
    null == ""         // false (!)
    null == false      // false (!)
    "" == false        // true
    0 == false         // true
    0 == ""            // true
    [] == ""           // true
    [] == 0            // true
    [] == ![]          // true (this is wild)

  Explanation of [] == ![]:
    ![] -> false ([] is truthy, !truthy = false)
    [] == false
    -> Number(false) = 0; Number([]) = 0; 0 == 0 -> true

STRICT EQUALITY (===) ALGORITHM:
  Same type AND same value -> true
  Different types -> always false (no coercion)
  Special cases:
    NaN === NaN  // false (use Number.isNaN())
    +0 === -0    // true  (use Object.is(+0, -0) for strict)

TYPEOF + COERCION:

  ARITHMETIC:
    1 + 2        // 3   (number + number)
    1 + "2"      // "12" (number coerced to string)
    "1" + 2      // "12" (number coerced to string)
    1 - "2"      // -1  (string coerced to number)
    "3" * "4"    // 12  (both coerced to number)
    true + true  // 2   (both coerced to number)
    null + 1     // 1   (null -> 0)
    undefined + 1 // NaN (undefined -> NaN)
```

---

### 💻 Code Example

**Coercion bugs and safe equality patterns**

```javascript
// BAD: loose equality with coercion surprises
function isAdult(age) {
  if (age == '18') {  // true for '18', 18, [18]
    return true;
  }
  return false;
}
isAdult(18);    // true
isAdult('18');  // true
isAdult([18]);  // true (!) [18] -> "18" -> 18

// BAD: truthy/falsy as null check
function getUser(id) {
  return id ? fetchUser(id) : null;
}
getUser(0);  // returns null - but 0 might be a valid ID!

// GOOD: explicit type checks
function isAdult(age) {
  const numAge = Number(age);
  return Number.isFinite(numAge) && numAge >= 18;
}

function getUser(id) {
  return (id !== null && id !== undefined)
    ? fetchUser(id)
    : null;
  // or: return id != null ? fetchUser(id) : null;
}

// COERCION IN SORT (common bug):
const nums = [10, 9, 2, 1, 20];
nums.sort();  // [1, 10, 2, 20, 9] - sorted as strings!
nums.sort((a, b) => a - b);  // [1, 2, 9, 10, 20] - correct

// TYPE-SAFE EQUALITY PATTERNS:
// Check for NaN:
isNaN('hello');       // true (!) coerces first
Number.isNaN('hello'); // false (does NOT coerce)
Number.isNaN(NaN);    // true (correct)

// Object equality (objects are compared by reference):
const a = { x: 1 };
const b = { x: 1 };
console.log(a === b);  // false (different objects)
console.log(JSON.stringify(a) === JSON.stringify(b)); // true
// For deep equality: use Lodash isEqual, or fast-deep-equal
```

> **Code walkthrough:** The `isAdult` bug shows why loose equality
> is dangerous: `[18] == '18'` is true because the array is first
> converted to the string `"18"`, then compared. The id check bug
> (`id ?`) fails for `0` because 0 is falsy - valid IDs of 0 would
> be rejected. The sort bug catches many engineers: `Array.sort()`
> without a comparator converts elements to strings before comparing,
> so `10` < `2` because `"1"` < `"2"`. The `Number.isNaN` vs
> `isNaN` distinction matters: global `isNaN` coerces its argument
> first (`isNaN("hello")` returns `true` because `Number("hello")`
> is `NaN`), while `Number.isNaN` returns `true` ONLY for the
> actual `NaN` value without coercion.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `==` triggers type coercion; `===` does not. Always use `===`.
> Falsy values: `false, 0, "", null, undefined, NaN`. Use
> `Number.isNaN()` not `isNaN()`. Sort arrays with a comparator
> function - default sort converts to strings.

---

**Senior / Staff:**

> Coercion bugs are production issues: `sort()` without comparator,
> loose equality in conditions, `0` being falsy when 0 is a valid value.
> TypeScript catches most coercion bugs at compile time by preventing
> comparison of incompatible types. In code reviews: flag any `==`
> usage, flag `if (id)` where id might be 0 or empty string,
> flag `array.sort()` without comparator.

---

### ⚠️ Common Misconceptions

**"An empty array is falsy"**

`[]` is truthy. Only these 8 values are falsy: `false`, `0`, `-0`,
`0n`, `""`, `null`, `undefined`, `NaN`. An empty array `[]`, empty
object `{}`, and empty string with a space `" "` are all truthy.
`Boolean([])` returns `true`. This surprises engineers who expect
"empty = falsy". The rule: truthiness is NOT about the content of
the value, it's about a fixed list of falsy values.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: data sorted incorrectly**

```javascript
// SYMPTOM: numbers appear sorted as strings
[100, 20, 3].sort()  // [100, 20, 3] - "1" < "2" < "3"
// vs expected [3, 20, 100]

// DIAGNOSE:
// Check: is there a comparator function passed to sort()?
// No comparator -> lexicographic string sort (almost always wrong)

// FIX: always pass comparator for numbers
[100, 20, 3].sort((a, b) => a - b)  // [3, 20, 100]

// For strings with locale awareness:
['banana', 'apple', 'Cherry']
  .sort((a, b) => a.localeCompare(b))
  // ['apple', 'banana', 'Cherry']
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| == vs === with example | 2-3 min | Coercion mechanism |
| What are all falsy values | 1-2 min | Exhaustive list |
| Why 0 == false is true | 2 min | Coercion algorithm |
| Why [] == ![] is true | 3 min | Advanced coercion |
| Number.isNaN vs isNaN | 2 min | Coercion in isNaN |
| Sort bug without comparator | 2-3 min | Practical bug |
| How to safely compare objects | 2 min | Reference equality |

---

**Q1: Explain the difference between == and === with an example.**
`[JUNIOR]` COMPARISON

> **Answer:**
>
> `===` (strict equality): compares value AND type. No type coercion.
> `==` (loose equality): coerces types before comparing.
>
> ```javascript
> // === (strict): no coercion
> 1 === 1          // true  (same type, same value)
> 1 === "1"        // false (different types)
> null === undefined // false (different types)
> NaN === NaN      // false (special case - NaN never equals NaN)
>
> // == (loose): coercion applied
> 1 == "1"         // true  ("1" -> 1)
> 0 == false       // true  (false -> 0)
> 0 == ""          // true  ("" -> 0)
> null == undefined // true  (special rule)
> null == 0        // false (null only == undefined)
> [] == ""         // true  ([] -> "")
> [] == 0          // true  ([] -> "" -> 0)
> ```
>
> When to use `==`: almost never. The one idiomatic use is
> `value == null` which checks for both `null` AND `undefined`
> simultaneously (covers the case where a value was either
> not provided or was explicitly set to null).
>
> ```javascript
> // This is idiomatic (only case where == is preferred):
> if (user == null) {
>   // handles both user === null AND user === undefined
>   return 'Guest';
> }
> ```
>
> Everything else: use `===` and explicit type conversion.
>
> *What separates good from great:* The Abstract Equality Comparison
> algorithm is asymmetric and non-intuitive. `null == false` is
> `false`, but `0 == false` is `true`. The algorithm doesn't follow
> transitive rules: `A == B` and `B == C` doesn't mean `A == C`.
> (`"" == 0` is true, `"" == false` is true, but `false == 0` is
> also true - this isn't transitive in a useful way). TypeScript
> removes this entire problem: it flags `==` comparisons between
> incompatible types as errors.
