---
layout: default
title: "JavaScript - L1 Objects and Arrays"
parent: "JavaScript"
nav_order: 4
permalink: /javascript/l1-objects-and-arrays/
render_with_liquid: false
---

# Objects and Prototypes

🎯 **Interview Weight:** foundational (★☆☆) - JavaScript's
prototype model is unique; required for understanding class
inheritance, `Object.create`, and property lookup

---

### 🎯 Model Answer

**30 seconds:**

> JavaScript objects are collections of key-value pairs. Every object
> has a prototype (accessed via `Object.getPrototypeOf(obj)`), and
> when a property is not found on the object itself, JavaScript walks
> up the prototype chain. ES6 `class` syntax is sugar over this
> prototype system. Use `Object.create()` for manual prototype control
> or ES6 classes for most use cases.

**3 minutes:**

> The prototype chain: if you access `obj.toString()` and `toString`
> is not on `obj`, JavaScript looks at `obj`'s prototype, then its
> prototype's prototype, continuing until `Object.prototype`
> (whose prototype is null). This is prototype chain traversal.
>
> ES6 classes use this system: `class B extends A` sets B's prototype
> chain so that B instances inherit from A. `class` is syntactic sugar -
> `Object.getPrototypeOf(B.prototype) === A.prototype`.
>
> Own properties vs inherited: `hasOwnProperty()` checks if a property
> is directly on the object (not inherited). `for...in` iterates
> inherited properties too.

**Blank Mind Recovery:**

**(1) Restate:** "Objects have prototypes. Property lookup traverses
the chain to Object.prototype. Classes are sugar over prototypes."

---

### 📘 Concept Explanation

**What it is:**

JavaScript's object system is prototype-based: objects inherit directly
from other objects rather than from classes. The prototype chain is
a linked list of objects. Property lookup traverses this chain.

**How it works:**

```
OBJECT CREATION:

  Object literal:
    const obj = { name: 'Alice', age: 30 };
    // prototype: Object.prototype

  Object.create(proto):
    const animal = {
      speak() { return `${this.name} speaks`; }
    };
    const dog = Object.create(animal);
    dog.name = 'Rex';
    dog.speak();  // "Rex speaks" (found on prototype)

  Constructor function:
    function Person(name) {
      this.name = name;
    }
    Person.prototype.greet = function() {
      return `Hi, I'm ${this.name}`;
    };
    const alice = new Person('Alice');
    alice.greet();  // found on Person.prototype

  ES6 class (sugar over prototypes):
    class Person {
      constructor(name) { this.name = name; }
      greet() { return `Hi, I'm ${this.name}`; }
    }
    // greet is on Person.prototype
    class Employee extends Person {
      constructor(name, role) {
        super(name);
        this.role = role;
      }
    }
    // Employee.prototype -> Person.prototype -> Object.prototype

PROTOTYPE CHAIN LOOKUP:
  const emp = new Employee('Alice', 'engineer');
  emp.greet();
  // 1. Check emp own properties: no greet
  // 2. Check Employee.prototype: no greet
  // 3. Check Person.prototype: FOUND greet()
  // Returns: "Hi, I'm Alice"

  emp.toString();
  // Not found until Object.prototype.toString()

  emp.unknownProp;
  // Not found anywhere -> undefined (chain ends at null)

OBJECT PROPERTY METHODS:

  Object.keys(obj)     // own enumerable string keys
  Object.values(obj)   // own enumerable values
  Object.entries(obj)  // [[key, value], ...] pairs
  Object.assign(target, ...sources) // shallow merge
  Object.freeze(obj)   // immutable object (shallow)
  Object.create(proto) // new obj with given prototype
  Object.getPrototypeOf(obj) // get prototype
  obj.hasOwnProperty(key)    // check own (not inherited)

  // for...in iterates ALL enumerable (including inherited)
  for (const key in emp) { ... }
  // Object.keys only own:
  Object.keys(emp);

PROPERTY DESCRIPTORS:
  Object.defineProperty(obj, 'name', {
    value: 'Alice',
    writable: false,    // can't change value
    enumerable: true,   // shows in for...in, Object.keys
    configurable: false // can't delete or redefine
  });
```

---

### 💻 Code Example

**Prototype chain and class inheritance**

```javascript
// BAD: duplicating methods on every instance (common mistake)
function Person(name) {
  this.name = name;
  this.greet = function() {   // NEW function per instance!
    return `Hi, I'm ${this.name}`;
  };
}
const a = new Person('Alice');
const b = new Person('Bob');
console.log(a.greet === b.greet);  // false (different fns)
// Each instance has its own copy of greet: wastes memory

// GOOD: method on prototype (shared across instances)
function Person(name) {
  this.name = name;             // own property
}
Person.prototype.greet = function() { // shared
  return `Hi, I'm ${this.name}`;
};
const a = new Person('Alice');
const b = new Person('Bob');
console.log(a.greet === b.greet);    // true (shared)

// GOOD (modern): ES6 class (same prototype mechanism)
class Person {
  constructor(name) { this.name = name; }
  greet() { return `Hi, I'm ${this.name}`; }
  // greet() is on Person.prototype
}
class Employee extends Person {
  constructor(name, role) {
    super(name);      // calls Person constructor
    this.role = role;
  }
  describe() {
    return `${this.greet()} and I'm a ${this.role}`;
  }
}

const emp = new Employee('Alice', 'engineer');
emp.describe();
// "Hi, I'm Alice and I'm a engineer"
emp.hasOwnProperty('name');   // true (own)
emp.hasOwnProperty('greet');  // false (on prototype)
Object.getPrototypeOf(emp) === Employee.prototype;  // true

// CHECKING INHERITANCE:
emp instanceof Employee;  // true
emp instanceof Person;    // true (chain includes Person.prototype)
emp instanceof Object;    // true (chain includes Object.prototype)
```

> **Code walkthrough:** The BAD pattern creates a new function object
> per instance because `this.greet = function() {}` runs inside the
> constructor for every `new Person()`. With thousands of instances,
> you have thousands of identical function objects in memory. The
> prototype pattern puts `greet` on `Person.prototype` - one function
> shared across all instances, accessed via prototype chain traversal.
> ES6 `class` method syntax does exactly the same thing: methods in
> the class body are placed on `ClassName.prototype`, not on each
> instance. The `instanceof` checks show that `emp` is simultaneously
> an instance of Employee, Person, and Object because its prototype
> chain passes through all three.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Objects have prototypes. Property lookup traverses the chain until
> `Object.prototype`. ES6 classes are sugar over this. `Object.keys()`
> returns own enumerable keys. `for...in` includes inherited properties.
> `hasOwnProperty()` checks own only.

---

**Senior / Staff:**

> Prototype chain is a linked list. Class `extends` wires the chain:
> `B.prototype.__proto__ === A.prototype`. Methods on prototype are
> shared across instances (efficient). Methods in constructor are per-instance
> (expensive). Property descriptors control writability, enumerability,
> configurability - `Object.freeze` sets `writable: false, configurable: false`
> on all own properties.

---

### ⚠️ Common Misconceptions

**"ES6 classes are a new inheritance model"**

ES6 `class` is syntactic sugar over the existing prototype system.
`class A extends B` is equivalent to setting up the prototype chain
manually. Under the hood: `Object.getPrototypeOf(A.prototype) === B.prototype`.
You can verify this: `Object.getPrototypeOf(Employee.prototype) === Person.prototype`
is `true`.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: method not found on instance**

```javascript
// SYMPTOM: TypeError: emp.greet is not a function
class Employee extends Person {}
// Did you call super() in constructor?
// Did you override constructor without calling super()?

// BAD: forgot super() - Person's constructor never ran
class Employee extends Person {
  constructor(name, role) {
    this.role = role;   // ReferenceError before super()
    super(name);        // must be FIRST in derived constructor
  }
}

// DIAGNOSIS:
// Check prototype chain:
Object.getPrototypeOf(emp);             // Employee.prototype
Object.getPrototypeOf(Employee.prototype); // Person.prototype
// If chain is broken: problem in constructor
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Explain prototype chain | 2-3 min | Chain traversal |
| Own property vs inherited | 2 min | hasOwnProperty |
| Class vs prototype function | 3 min | Method placement |
| Object.create use case | 2-3 min | Prototype manipulation |
| instanceof mechanism | 2 min | Prototype check |
| Property descriptor | 2-3 min | Advanced object knowledge |
| for...in vs Object.keys | 2 min | Inherited properties |

---

**Q1: What is the prototype chain in JavaScript?** `[JUNIOR]` DEFINITION

> **Answer:**
>
> Every JavaScript object has an internal `[[Prototype]]` reference
> pointing to another object (or null). When you access a property
> that doesn't exist on an object, JavaScript follows this chain:
>
> ```javascript
> const emp = new Employee('Alice', 'engineer');
>
> // Property lookup for emp.greet():
> // 1. emp own properties? NO
> // 2. Employee.prototype? NO
> // 3. Person.prototype? YES -> call it
>
> // Chain:
> emp -> Employee.prototype -> Person.prototype
>     -> Object.prototype -> null (chain ends)
>
> Object.getPrototypeOf(emp) === Employee.prototype;  // true
> Object.getPrototypeOf(Employee.prototype)           // Person.prototype
> Object.getPrototypeOf(Person.prototype)             // Object.prototype
> Object.getPrototypeOf(Object.prototype)             // null (end)
> ```
>
> This is why all objects have `toString()`, `hasOwnProperty()`,
> `valueOf()` - they're inherited from `Object.prototype`.
>
> *What separates good from great:* The prototype chain is a performance
> consideration. Property lookup with a long chain is slower because
> each hop is a memory access. For deeply nested inheritance hierarchies,
> frequently accessed properties should be own properties (not inherited)
> for best performance. Also: modifying `Object.prototype` (a common
> beginner mistake) affects ALL objects in the program, because
> everything inherits from it. Never add properties to `Object.prototype`.

---

---

# Arrays and Iteration Methods

🎯 **Interview Weight:** foundational (★☆☆) - array methods are
used daily; map/filter/reduce are in every JavaScript interview

---

### 🎯 Model Answer

**30 seconds:**

> JavaScript arrays are objects with numeric keys and a `length` property.
> Key iteration methods: `map` (transform to new array), `filter`
> (subset), `reduce` (aggregate to single value), `forEach` (side effects),
> `find` (first match), `some`/`every` (boolean checks). These are
> all non-mutating except `forEach`. Use `Array.isArray()` to check
> for arrays.

**3 minutes:**

> Array methods in three categories:
>
> 1. **Transformation**: `map(fn)` -> new array, same length.
>    `flatMap(fn)` -> map then flatten one level.
> 2. **Filtering/Finding**: `filter(fn)` -> subset. `find(fn)` ->
>    first match or undefined. `findIndex(fn)` -> index or -1.
>    `some(fn)` -> true if any match. `every(fn)` -> true if all match.
> 3. **Aggregation**: `reduce(fn, init)` -> single value.
>    `reduceRight(fn, init)` -> right-to-left.
>
> Common mistakes: `sort()` without comparator (lexicographic),
> `reduce` without initial value, mutating array during `forEach`.
> Prefer `Array.from()` over `Array()` constructor to avoid sparse arrays.

**Blank Mind Recovery:**

**(1) Restate:** "map: transform. filter: subset. reduce: aggregate.
All return new arrays (except reduce which returns one value)."

---

### 📘 Concept Explanation

**What it is:**

JavaScript arrays are ordered collections with a rich set of iteration
methods for common functional programming patterns: transformation,
filtering, and aggregation.

**How it works:**

```
ARRAY CREATION:
  []                          // literal
  new Array(3)                // [undefined x3] SPARSE
  Array.from({ length: 3 })  // [undefined, undefined, undefined]
  Array.from('abc')           // ['a', 'b', 'c']
  Array.from(new Set([1,2])) // [1, 2]
  Array.of(1, 2, 3)          // [1, 2, 3]
  [1, ...otherArray, 2]      // spread

TRANSFORMATION:
  map(fn):
    [1, 2, 3].map(x => x * 2)  // [2, 4, 6]
    // Returns NEW array, same length
    // Does NOT modify original

  flatMap(fn):
    [1, 2].flatMap(x => [x, x * 2])
    // [1, 2, 2, 4] (map then flatten 1 level)

FILTERING/SEARCHING:
  filter(fn):
    [1, 2, 3, 4].filter(x => x % 2 === 0)  // [2, 4]

  find(fn):
    [1, 5, 3].find(x => x > 3)   // 5 (first match)
    [1, 2].find(x => x > 10)     // undefined

  findIndex(fn):
    [1, 5, 3].findIndex(x => x > 3)  // 1

  indexOf(value):
    ['a', 'b'].indexOf('b')       // 1
    ['a', 'b'].indexOf('c')       // -1

  includes(value):
    [1, 2].includes(2)            // true
    [1, NaN].includes(NaN)        // true (uses SameValueZero)

  some(fn):  true if ANY element matches
    [1, 2, 3].some(x => x > 2)   // true

  every(fn): true if ALL elements match
    [2, 4, 6].every(x => x % 2 === 0)  // true

AGGREGATION:
  reduce(fn, initialValue):
    [1, 2, 3].reduce((acc, cur) => acc + cur, 0)  // 6
    // fn receives: (accumulator, currentValue, index, array)
    // WITHOUT initial value: first element is initial acc
    // EMPTY array without initial value: TypeError!

  reduceRight: same but right-to-left

MUTATION (modifies original array):
  push(...items):    add to end, returns new length
  pop():             remove from end, returns element
  shift():           remove from start, returns element
  unshift(...items): add to start, returns new length
  splice(start, deleteCount, ...items): insert/remove
  sort(comparator):  sorts in place
  reverse():         reverses in place

NON-MUTATING ALTERNATIVES (ES2023):
  toSorted(), toReversed(), toSpliced(), with()
  These return new arrays without modifying original

ARRAY CREATION PATTERNS:
  // Range:
  Array.from({ length: 5 }, (_, i) => i)
  // [0, 1, 2, 3, 4]

  // Fill:
  new Array(5).fill(0)        // [0, 0, 0, 0, 0]

  // Chunk array:
  function chunk(arr, size) {
    return Array.from(
      { length: Math.ceil(arr.length / size) },
      (_, i) => arr.slice(i * size, i * size + size)
    );
  }
  chunk([1,2,3,4,5], 2)  // [[1,2],[3,4],[5]]
```

---

### 💻 Code Example

**map/filter/reduce chained**

```javascript
const orders = [
  { id: 1, amount: 50, status: 'completed', tax: 0.1 },
  { id: 2, amount: 120, status: 'pending',   tax: 0.1 },
  { id: 3, amount: 80,  status: 'completed', tax: 0.08 },
  { id: 4, amount: 200, status: 'cancelled', tax: 0.1 },
];

// GOAL: total revenue from completed orders including tax

// BAD: imperative loop
let total = 0;
for (let i = 0; i < orders.length; i++) {
  if (orders[i].status === 'completed') {
    total += orders[i].amount * (1 + orders[i].tax);
  }
}
// Hard to read, mutable state, no intermediate checks

// GOOD: declarative pipeline
const totalRevenue = orders
  .filter(order => order.status === 'completed')
  .map(order => order.amount * (1 + order.tax))
  .reduce((sum, amount) => sum + amount, 0);
// totalRevenue: 50*1.1 + 80*1.08 = 55 + 86.4 = 141.4

// COMMON reduce mistakes:

// BUG: no initial value with empty array
[].reduce((a, b) => a + b);  // TypeError!
[].reduce((a, b) => a + b, 0);  // 0 (safe)

// BUG: sort without comparator
const nums = [10, 9, 100, 2];
nums.sort();               // [10, 100, 2, 9] (string sort!)
nums.sort((a, b) => a - b); // [2, 9, 10, 100] (correct)

// IMMUTABLE sort (ES2023):
const sorted = nums.toSorted((a, b) => a - b);
// nums unchanged, sorted is a new array

// Array.from for ranges:
const range = Array.from({ length: 5 }, (_, i) => i + 1);
// [1, 2, 3, 4, 5]
```

> **Code walkthrough:** The declarative pipeline reads as a sentence:
> filter to completed orders, map to revenue with tax, reduce to sum.
> Each step is independently testable: you can console.log between
> each chained method. The reduce without initial value bug is subtle:
> if `orders` is empty (API returns empty array), `.reduce()` without
> an initial value throws `TypeError: Reduce of empty array with no
> initial value`. Always provide an initial value for `reduce`. The
> sort comparator bug surprises experienced developers: `sort()` without
> a comparator converts elements to strings - `100` sorts before `9`
> because `"1"` < `"9"`. Always provide a comparator for numeric sort.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `map`: transform to new array. `filter`: subset. `reduce`: aggregate
> to single value. `find`: first match. `some`/`every`: boolean checks.
> Always provide initial value for `reduce`. Always use comparator
> for numeric `sort`. Use `Array.isArray()` to check for arrays.

---

**Senior / Staff:**

> Array methods are the basis of data pipeline patterns. Chaining
> creates readable transformation stages. Performance: `map+filter`
> creates two intermediate arrays; `reduce` can do both in one pass.
> For large datasets, prefer `reduce` or a single `for` loop.
> ES2023 introduced non-mutating counterparts: `toSorted`,
> `toReversed`, `toSpliced`, `with` - prefer these in React/functional
> code where immutability is expected.

---

### ⚠️ Common Misconceptions

**"forEach is like map but doesn't return anything"**

`forEach` is for SIDE EFFECTS (logging, modifying external state).
`map` is for TRANSFORMATION (creating a new array). Don't use
`map` when you don't use the returned array (ESLint will warn).
Don't use `forEach` when you want a transformed array (use `map`).
`forEach` cannot be stopped early (no `break`); use `for...of`
or `some`/`every` if you need early exit.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: TypeError from reduce on empty array**

```javascript
// SYMPTOM: "TypeError: Reduce of empty array with no initial value"
const items = [];
items.reduce((a, b) => a + b);  // TypeError!

// DIAGNOSIS: reduce was called without initial value on empty array

// FIX: always provide initial value
items.reduce((a, b) => a + b, 0);  // 0 (safe)
items.reduce((acc, item) => {
  acc[item.id] = item;
  return acc;
}, {});  // {} (safe initial object)

// For non-numeric initial values, the type of the initial
// value must match what the reducer accumulates into:
const grouped = orders.reduce((groups, order) => {
  const key = order.status;
  if (!groups[key]) groups[key] = [];
  groups[key].push(order);
  return groups;
}, {});  // initial value: empty object
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Implement map using reduce | 3-4 min | reduce mastery |
| filter + map + reduce pipeline | 3 min | Chaining fluency |
| sort bug without comparator | 2-3 min | Classic bug |
| reduce without initial value | 2 min | Edge case |
| forEach vs map difference | 2 min | Side effects vs transform |
| Flatten nested arrays | 2-3 min | flat / flatMap |
| Array.from use cases | 2-3 min | Array creation |

---

**Q1: Implement map using reduce.** `[JUNIOR]` IMPLEMENTATION

> **Answer:**
>
> ```javascript
> function myMap(array, fn) {
>   return array.reduce((acc, item, index) => {
>     acc.push(fn(item, index));
>     return acc;
>   }, []);
> }
>
> // Usage:
> myMap([1, 2, 3], x => x * 2);  // [2, 4, 6]
> ```
>
> How it works: `reduce` starts with an empty array `[]` as the
> accumulator. For each element, we call the transformation function
> `fn(item, index)` and push the result into `acc`.
>
> The implementation shows that `map` is a specialization of `reduce`:
> any aggregation operation can be expressed as `reduce`.
>
> *What separates good from great:* While `myMap` using `reduce` is
> a valid implementation, it has a performance characteristic to note:
> `.push()` inside `reduce` is mutation of the accumulator. A fully
> immutable version would use spread: `[...acc, fn(item)]`, but this
> creates a new array on EVERY iteration - O(n^2) vs O(n) for push.
> Production JavaScript typically uses the push approach. The conceptual
> insight is that `reduce` is the "universal" array operation - you
> can implement `map`, `filter`, `find`, `some`, `every`, `flat`,
> and `forEach` all using `reduce`. Understanding this reveals that
> `reduce` is the most powerful of the array methods, though rarely
> the most readable for simple transformations.

---

---

# Destructuring and Spread Operator

🎯 **Interview Weight:** foundational (★☆☆) - ES6 features used
in virtually every modern JavaScript codebase; React props,
function parameters, array manipulation

---

### 🎯 Model Answer

**30 seconds:**

> Destructuring extracts values from arrays or properties from objects
> into distinct variables. Spread (`...`) expands an iterable into
> individual elements. Rest (`...`) collects remaining elements into
> an array. These ES6 features enable concise assignment, function
> parameter handling, and immutable object/array operations.

**3 minutes:**

> Three related features:
>
> 1. **Array destructuring**: `const [a, b] = [1, 2]` - extracts
>    by position. Skip with commas: `const [, second] = [1, 2]`.
>    Rest: `const [first, ...rest] = [1, 2, 3]`.
>
> 2. **Object destructuring**: `const { name, age } = person` - extracts
>    by key. Rename: `const { name: fullName } = person`. Default:
>    `const { role = 'user' } = person`. Nested: `const { address: { city } } = person`.
>
> 3. **Spread**: `[...arr1, ...arr2]` (concat arrays), `{...obj1, ...obj2}`
>    (merge objects). Creates shallow copies. REST is the parameter
>    counterpart: `function f(...args)` collects all arguments.
>
> Common uses: React component props (`const { title, onClick } = props`),
> function parameters with defaults, swapping variables, cloning objects.

**Blank Mind Recovery:**

**(1) Restate:** "Destructuring: extract values. Spread (...): expand.
Rest (...): collect into array."

---

### 📘 Concept Explanation

**What it is:**

Destructuring is syntactic sugar for extracting values from arrays
or objects. Spread/rest are operators that expand or collect iterables.
Together they enable expressive, concise code for common data manipulation patterns.

**How it works:**

```
ARRAY DESTRUCTURING:

  const [a, b, c] = [1, 2, 3];
  // a=1, b=2, c=3

  // Skip elements:
  const [, second, , fourth] = [1, 2, 3, 4];
  // second=2, fourth=4

  // Default values:
  const [x = 10, y = 20] = [5];
  // x=5, y=20

  // Rest:
  const [head, ...tail] = [1, 2, 3, 4];
  // head=1, tail=[2, 3, 4]

  // Swap variables:
  let a = 1, b = 2;
  [a, b] = [b, a];
  // a=2, b=1

  // Works with any iterable:
  const [first, second] = 'hello';
  // first='h', second='e'
  const [x, y] = new Set([1, 2, 3]);
  // x=1, y=2

OBJECT DESTRUCTURING:

  const { name, age } = { name: 'Alice', age: 30 };
  // name='Alice', age=30

  // Rename:
  const { name: fullName, age: years } = person;
  // fullName='Alice', years=30

  // Default values:
  const { role = 'user', name = 'Guest' } = userObj;
  // role and name fall back if undefined

  // Nested:
  const {
    address: { city, country }
  } = { address: { city: 'NYC', country: 'US' } };
  // city='NYC', country='US'
  // NOTE: address is NOT assigned as a variable here

  // Rest:
  const { name, ...rest } = { name: 'Alice', age: 30, role: 'admin' };
  // name='Alice', rest={ age: 30, role: 'admin' }

  // Function parameter destructuring:
  function greet({ name = 'Guest', role = 'user' } = {}) {
    return `Hello ${name}, you are ${role}`;
  }
  greet({ name: 'Alice' }); // "Hello Alice, you are user"
  greet();                   // "Hello Guest, you are user"

SPREAD OPERATOR:

  ARRAYS:
    const a = [1, 2, 3];
    const b = [4, 5, 6];
    const merged = [...a, ...b];    // [1,2,3,4,5,6]
    const copy   = [...a];          // [1,2,3] (shallow copy)
    const withExtra = [0, ...a, 4]; // [0,1,2,3,4]

    Math.max(...[1, 2, 3]);  // 3 (spread as args)

  OBJECTS:
    const obj1 = { a: 1, b: 2 };
    const obj2 = { b: 3, c: 4 };
    const merged = { ...obj1, ...obj2 };
    // { a: 1, b: 3, c: 4 }  (obj2.b overwrites obj1.b)

    const clone = { ...obj1 };  // shallow copy
    const updated = { ...user, role: 'admin' }; // update field

SHALLOW vs DEEP COPY:
  const original = { a: { b: 1 } };
  const shallow  = { ...original };
  shallow.a.b = 99;
  console.log(original.a.b);  // 99 (shared nested object!)

  // Deep copy options:
  const deep1 = JSON.parse(JSON.stringify(original));
  const deep2 = structuredClone(original); // ES2022, preferred
```

---

### 💻 Code Example

**React-style props and state patterns**

```javascript
// BAD: accessing properties without destructuring
function UserCard(props) {
  return `${props.user.name}, ${props.user.role},
          ${props.isAdmin ? 'admin' : 'user'}`;
}

// GOOD: destructuring in parameters
function UserCard({
  user: { name, role },  // nested destructuring
  isAdmin = false,       // default value
  onUpdate,              // function prop
}) {
  return `${name}, ${role}, ${isAdmin ? 'admin' : 'user'}`;
}

// IMMUTABLE UPDATE PATTERNS:
const state = {
  user: { name: 'Alice', role: 'user' },
  theme: 'dark',
  count: 0
};

// Update a field (immutably):
const newState = { ...state, count: state.count + 1 };
// { user: ..., theme: 'dark', count: 1 }

// Update nested field:
const updatedUser = {
  ...state,
  user: { ...state.user, role: 'admin' }
};
// { user: { name: 'Alice', role: 'admin' }, theme: 'dark', count: 0 }
// original state.user UNTOUCHED

// Merge arrays:
const existing = [1, 2, 3];
const added = [4, 5];
const all = [...existing, ...added];  // [1,2,3,4,5]
const deduplicated = [...new Set(all)];  // unique values

// Collect remaining args with rest:
function logger(level, message, ...details) {
  console[level](message, ...details);
}
logger('error', 'Connection failed', { host: 'db.example.com' });
// console.error('Connection failed', { host: ... })

// Object rest for "omit" pattern:
function omit(obj, ...keys) {
  const keysToOmit = new Set(keys);
  return Object.fromEntries(
    Object.entries(obj).filter(([k]) => !keysToOmit.has(k))
  );
}
const { password, ...safeUser } = user;
// safeUser has all fields except password (for API response)
```

> **Code walkthrough:** The `UserCard` destructuring in parameters is
> the most common React/component pattern. Nested destructuring
> `user: { name, role }` extracts `name` and `role` directly from the
> `user` property - `user` itself is NOT a local variable. Default
> values (`isAdmin = false`) handle missing props gracefully.
> The immutable update pattern (`{ ...state, count: state.count + 1 }`)
> is fundamental to React state management: spread creates a new object
> with all properties from `state`, then overrides `count`. The original
> state object is never mutated. Nested immutable updates require spreading
> at each level - `{ ...state, user: { ...state.user, role: 'admin' } }`.
> The `password` omit pattern (`const { password, ...safeUser } = user`)
> is a clean way to exclude sensitive fields from an object before logging
> or sending to a client.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Destructuring extracts values: `const { name } = obj` or
> `const [a, b] = arr`. Spread expands: `[...arr]` clones an array,
> `{...obj}` clones an object. Rest collects: `function f(...args)`.
> Spread creates shallow copies - nested objects are still shared.

---

**Senior / Staff:**

> Destructuring and spread are ergonomic layers over property access.
> Performance implication: spread creates a NEW object/array - avoid
> in hot loops. For immutable updates: shallow spread is O(n) where n
> is the number of properties. For deeply nested objects: spread every
> level from root to the changed property. `structuredClone` is the
> modern deep clone API (replaces `JSON.parse(JSON.stringify(...))`)
> and handles circular references.

---

### ⚠️ Common Misconceptions

**"Spread creates a deep copy"**

Spread creates a SHALLOW copy. `{ ...obj }` creates a new object with
the same top-level properties, but nested objects are still shared
references. `const copy = { ...original }; copy.nested.x = 1` ALSO
changes `original.nested.x`. Use `structuredClone(obj)` for deep copies.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: mutating state unexpectedly in React**

```javascript
// SYMPTOM: state mutations cause React render bugs
const [state, setState] = useState({ user: { name: 'Alice' } });

// BAD: mutates the nested object directly
state.user.name = 'Bob';    // mutates original state object!
setState(state);             // React sees same reference, may not re-render

// GOOD: create new objects at every level
setState(prev => ({
  ...prev,
  user: { ...prev.user, name: 'Bob' }
}));
// prev.user is NOT mutated
// setState receives a completely new reference -> re-render triggered
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Array vs object destructuring syntax | 2-3 min | Syntax mastery |
| Spread vs rest operator | 2 min | Expansion vs collection |
| Shallow vs deep copy | 2-3 min | Reference semantics |
| Immutable object update | 3 min | Spread for updates |
| Rename in destructuring | 1-2 min | Renaming syntax |
| Default values in destructuring | 2 min | undefined triggering default |
| Rest in function parameters | 2 min | Variadic functions |

---

**Q1: What is the difference between spread and rest operator?**
`[JUNIOR]` COMPARISON

> **Answer:**
>
> Same syntax (`...`) but opposite roles:
>
> **Spread**: EXPANDS an iterable into individual elements:
> ```javascript
> const arr = [1, 2, 3];
> console.log(...arr);          // 1  2  3 (separate args)
> Math.max(...arr);             // 3
> const copy = [...arr];        // [1, 2, 3] (new array)
> const merged = [...arr, 4];   // [1, 2, 3, 4]
>
> const obj = { a: 1 };
> const extended = { ...obj, b: 2 };  // { a: 1, b: 2 }
> ```
>
> **Rest**: COLLECTS remaining elements into an array:
> ```javascript
> // Function parameters:
> function sum(...numbers) {
>   return numbers.reduce((a, b) => a + b, 0);
> }
> sum(1, 2, 3, 4);  // numbers = [1, 2, 3, 4] -> 10
>
> // Destructuring:
> const [first, ...rest] = [1, 2, 3, 4];
> // first = 1, rest = [2, 3, 4]
>
> const { a, ...others } = { a: 1, b: 2, c: 3 };
> // a = 1, others = { b: 2, c: 3 }
> ```
>
> Memory aid: spread OPENS the package (spreads contents out);
> rest PACKS into a package (collects into array).
>
> *What separates good from great:* REST must always be the LAST
> parameter: `function f(a, ...b, c)` is a SyntaxError. And rest
> is not the same as the `arguments` object: `arguments` is an
> array-like (not a real Array) that captures ALL arguments including
> those with names. Rest captures only the REMAINING unnamed arguments
> and is a real Array with all Array methods (`.map`, `.filter`, etc.).
> This is why rest is preferred over `arguments` in modern code.
