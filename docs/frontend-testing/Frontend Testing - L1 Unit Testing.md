---
layout: default
title: "Frontend Testing - L1 Unit Testing"
parent: "Frontend Testing"
nav_order: 2
permalink: /frontend-testing/l1-unit-testing/
---

# Jest Test Structure and Lifecycle

---

### 🎯 Model Answer

**30 seconds:**

> Jest test structure uses `describe` (group), `it`/`test` (individual
> test), and four lifecycle hooks: `beforeAll` (run once before all
> tests in describe), `afterAll` (once after), `beforeEach` (before
> each test), `afterEach` (after each). Hooks nest: outer `beforeEach`
> runs before inner `beforeEach`. Tests are isolated by default -
> `beforeEach` resets state between tests. `describe.only` / `test.only`
> run a single test in watch mode.

**3 minutes:**

Jest organizes tests in a hierarchy: `describe` blocks group related
tests, and `it`/`test` blocks contain individual assertions. Lifecycle
hooks run at specific points in this hierarchy.

**Hook execution order** for nested describes:
1. Outer `beforeAll`
2. Outer `beforeEach`
3. Inner `beforeAll`
4. Inner `beforeEach`
5. Test
6. Inner `afterEach`
7. Outer `afterEach`
8. (repeat 2-7 for next test)
9. Inner `afterAll`
10. Outer `afterAll`

**`beforeAll` vs `beforeEach`**: Use `beforeAll` for expensive setup
that can be shared (database connections, compiled assets). Use
`beforeEach` for state that must be reset between tests (mutable
objects, mock reset, localStorage clear).

**Test isolation**: Jest runs each test file in its own Node.js process
(worker). `jest.resetAllMocks()` in `afterEach` ensures mocks don't
leak between tests within a file.

**Blank Mind Recovery:**

**(1) Structure:** "describe groups, it/test individual, 4 hooks."

**(2) Hook order:** "beforeAll -> beforeEach -> test -> afterEach ->
afterAll. Outer wraps inner."

**(3) beforeAll vs beforeEach:** "beforeAll = shared expensive setup.
beforeEach = reset mutable state."

---

### 📘 Concept Explanation

**What it is:**

Jest's organizing primitives for writing structured, maintainable
test suites with controlled setup and teardown.

**The problem it solves:**

Tests sharing state cause false positives (test A sets up state that
makes test B pass) and false negatives (test A leaves dirty state that
makes test B fail). Lifecycle hooks provide explicit control over when
state is created and destroyed.

**How it works:**

```
Execution order within a file:

  describe('outer', () => {
    beforeAll(() => { console.log('1: outer beforeAll') });
    afterAll(() => { console.log('8: outer afterAll') });
    beforeEach(() => { console.log('2/5: outer beforeEach') });
    afterEach(() => { console.log('4/7: outer afterEach') });

    describe('inner', () => {
      beforeAll(() => { console.log('3a: inner beforeAll') });
      afterAll(() => { console.log('9: inner afterAll') });
      beforeEach(() => { console.log('3b: inner beforeEach') });
      afterEach(() => { console.log('4a: inner afterEach') });

      it('test 1', () => { console.log('4: test') });
      it('test 2', () => { console.log('7: test') });
    });
  });

  Order: outer beforeAll -> (for each test:
    outer beforeEach -> inner beforeEach ->
    test -> inner afterEach -> outer afterEach
  ) -> outer afterAll

Jest file isolation:
  Each test file runs in a separate Node.js worker
  Globals (window, localStorage, module cache) are isolated
  No state leaks between test files (by default)
  --runInBand: runs files sequentially in same process (debugging)
```

**Key options:**

```javascript
// jest.config.js
module.exports = {
  clearMocks: true,      // clear mock.calls and mock.instances between tests
  resetMocks: false,     // reset mock implementation between tests
  restoreMocks: false,   // restore original implementation between tests
  // For most projects: clearMocks: true is sufficient
};
```

---

### 💻 Code Example

**Example (Wrong vs Right) - Test isolation:**

```typescript
// BAD: shared mutable state causes test interdependence
describe('UserService', () => {
  const service = new UserService(); // shared across all tests!

  it('creates a user', () => {
    service.create({ name: 'Alice' });
    expect(service.count()).toBe(1);
  });

  it('lists users', () => {
    // FAILS if 'creates a user' test ran first (count is 1, not 0)
    // PASSES if this test runs alone
    expect(service.count()).toBe(0);
  });
});

// GOOD: fresh instance per test via beforeEach
describe('UserService', () => {
  let service: UserService;

  beforeEach(() => {
    service = new UserService(); // fresh instance for each test
  });

  it('starts with zero users', () => {
    expect(service.count()).toBe(0);
  });

  it('increments count on create', () => {
    service.create({ name: 'Alice' });
    expect(service.count()).toBe(1);
  });

  it('lists created users', () => {
    service.create({ name: 'Bob' });
    expect(service.list()[0].name).toBe('Bob');
  });
});
```

**Example (Production) - beforeAll for expensive setup:**

```typescript
// Integration test with database connection:
describe('OrderRepository', () => {
  let db: Database;
  let repo: OrderRepository;

  // Expensive: open database connection ONCE per describe block
  beforeAll(async () => {
    db = await createTestDatabase(); // ~200ms
    repo = new OrderRepository(db);
  });

  // But reset DATA between each test:
  beforeEach(async () => {
    await db.exec('DELETE FROM orders'); // fast: <5ms
  });

  afterAll(async () => {
    await db.close(); // cleanup after all tests
  });

  it('saves an order', async () => {
    const order = await repo.save({ items: ['item1'], total: 99 });
    expect(order.id).toBeDefined();
  });

  it('retrieves an order by id', async () => {
    const created = await repo.save({ items: ['item1'], total: 99 });
    const retrieved = await repo.findById(created.id);
    expect(retrieved?.total).toBe(99);
  });
});
```

> **Code walkthrough:** The BAD example uses a single shared `service`
> instance - tests that create users affect subsequent tests that
> expect an empty service. `beforeEach` creates a fresh instance for
> each test, ensuring independence. The production database example
> uses `beforeAll` for the expensive connection (once per describe)
> and `beforeEach` for data reset (fast cleanup per test). This
> pattern provides test isolation without the overhead of reconnecting
> for every test.

---

### ⚖️ Comparison Table

| Hook | Runs | Use for |
|---|---|---|
| `beforeAll` | Once before describe block | Expensive setup (DB, server) |
| `afterAll` | Once after describe block | Expensive teardown |
| `beforeEach` | Before every test | Mutable state reset, mock setup |
| `afterEach` | After every test | Mock reset, cleanup assertions |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `beforeAll` runs once before all tests in the describe block.
> `beforeEach` runs before each test. I use `beforeEach` to reset
> mutable state between tests so they don't interfere with each other.
> `describe` groups related tests together.

**Senior / Staff:**

> The key insight with Jest lifecycle hooks is isolation: tests should
> be independent - running them in any order or in parallel should
> produce the same results. `beforeEach` for mutable state (always),
> `beforeAll` for expensive idempotent setup (connections, compiled
> assets). I configure `clearMocks: true` globally to reset mock call
> counts between tests automatically. Test files run in separate Node.js
> workers by default, providing file-level isolation without any hook
> configuration.

---

### ⚠️ Common Misconceptions

**Misconception: `beforeAll` is always better than `beforeEach` for performance.**

`beforeAll` is faster but creates shared state. If the setup creates
a mutable object (like a service with internal state), `beforeAll`
causes test interdependence. `beforeEach` is correct for mutable
state. Use `beforeAll` only for truly immutable or idempotent setup.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Tests pass in isolation but fail together.**

Symptom: `jest test-file.ts` passes, `jest` fails.

Cause: Shared mutable state between tests or globals not reset.

Diagnose:
```bash
# Run tests in random order:
jest --randomize
# If order-dependent tests exist, they will fail differently
```

Fix: Use `beforeEach` to reset all mutable state. Configure
`clearMocks: true` in jest.config.js.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is the lifecycle hook execution order? | Mechanism | ★★☆ | 2 min |
| `beforeAll` vs `beforeEach` - when to use each? | Decision | ★★☆ | 2 min |
| How does Jest isolate test files? | Mechanism | ★★☆ | 1 min |
| Tests pass alone but fail together - why? | Debugging | ★★☆ | 2 min |
| `clearMocks` vs `resetMocks` vs `restoreMocks` | Comparison | ★★☆ | 2 min |

**Q: Tests pass individually but fail when run together. What do
you investigate?**

A: This is a test isolation failure - tests are sharing state.

Investigation steps:

1. Run with `--randomize` flag (Jest 29+) to confirm order-dependency:
   `jest --randomize` - if failures change, it's ordering.

2. Identify shared state in the test file:
   - Variables declared outside `beforeEach` or `it`
   - Global state: `localStorage`, `window.X`, module-level singletons
   - Shared service instances not reset between tests
   - Mocks not reset (`jest.clearAllMocks()` in `afterEach`)

3. Common culprits:
   - Missing `clearMocks: true` in jest.config.js
   - `new Date()` or `Math.random()` not mocked (non-deterministic)
   - Module-level state in imported modules (singleton services)
   - `localStorage.setItem` in one test affecting next test

Fix: Add `beforeEach` to reset all mutable state. Add `clearMocks: true`
to jest.config.js. Use `jest.resetModules()` if module-level state
is shared.

*What separates good from great:* Configuring Jest with test randomization
in CI (`--randomize` flag or `testSequencer` config) to catch isolation
failures before they cause intermittent CI failures. A test that always
runs in the same order can have a hidden dependency that only surfaces
months later when the order changes.

---

# Jest Assertions and Matchers

---

### 🎯 Model Answer

**30 seconds:**

> Jest matchers check expected vs actual values. Core matchers:
> `toBe` (===, primitives), `toEqual` (deep equality, objects),
> `toBeNull`, `toBeTruthy`, `toContain` (array/string), `toMatchObject`
> (partial object match), `toThrow` (error thrown), `toHaveBeenCalled`
> (mock), `toHaveBeenCalledWith` (mock args). `expect.extend` adds
> custom matchers. `jest-extended` adds 100+ additional matchers.

**Blank Mind Recovery:**

**(1) Categories:** "Equality: toBe/toEqual. Truthiness: toBeTruthy/
toBeFalsy/toBeNull. Arrays: toContain/toHaveLength. Errors: toThrow.
Mocks: toHaveBeenCalled."

**(2) toBe vs toEqual:** "toBe uses ===. toEqual deep comparison.
Never use toBe for objects/arrays."

---

### 📘 Concept Explanation

**What it is:**

Jest's assertion API - the methods available on `expect(value)` for
verifying that values meet expectations.

**The problem it solves:**

Different value types need different equality semantics. `===` fails
for objects with the same content (`{a: 1} !== {a: 1}`). `toEqual`
handles deep equality. `toMatchObject` handles partial matching.

**How it works:**

```
Matcher categories:

Equality:
  toBe(value)          : === (primitives, same reference)
  toEqual(value)       : deep equality (objects, arrays)
  toStrictEqual(value) : deep equality + checks undefined properties
  toMatchObject(obj)   : partial match (subset of properties)

Truthiness:
  toBeTruthy()         : value is truthy (not 0, '', null, undefined)
  toBeFalsy()          : value is falsy
  toBeNull()           : value === null
  toBeUndefined()      : value === undefined
  toBeDefined()        : value !== undefined

Numbers:
  toBeGreaterThan(n)
  toBeLessThan(n)
  toBeCloseTo(n, digits)  // float comparison

Strings/Arrays:
  toContain(item)         // array item or string substring
  toHaveLength(n)
  toMatch(/regex/)        // string regex match

Errors:
  toThrow()               // function throws any error
  toThrow('message')      // throws with message
  toThrow(ErrorClass)     // throws specific error class

Mocks:
  toHaveBeenCalled()
  toHaveBeenCalledTimes(n)
  toHaveBeenCalledWith(arg1, arg2)
  toHaveBeenLastCalledWith(arg1, arg2)
  toHaveReturnedWith(value)

Asymmetric matchers (use inside other matchers):
  expect.any(String)    // any string value
  expect.arrayContaining([1, 2]) // array that contains these items
  expect.objectContaining({ a: 1 }) // object with at least these props
  expect.stringMatching(/pattern/) // string matching regex
```

---

### 💻 Code Example

**Example (Wrong vs Right) - Using correct matchers:**

```typescript
// BAD: wrong matcher for the value type
const user = { name: 'Alice', age: 30 };

expect(user).toBe({ name: 'Alice', age: 30 });
// FAILS: {} !== {} (different object references)

expect(user.name).toEqual('Alice');
// Works but toBe is more semantically correct for primitives

// GOOD: match the matcher to the value type
expect(user).toEqual({ name: 'Alice', age: 30 }); // deep equality
expect(user.name).toBe('Alice');                    // === for string

// Partial matching with toMatchObject:
const response = { data: { id: 1, name: 'Alice' }, status: 200 };
expect(response).toMatchObject({ status: 200 });    // OK - subset
expect(response.data).toMatchObject({ name: 'Alice' }); // OK

// Error assertions (must wrap in function):
// BAD: toThrow on a thrown value (not a function):
// expect(dangerousFunction()).toThrow(); // WRONG - already called

// GOOD: wrap in arrow function:
expect(() => dangerousFunction()).toThrow('Invalid input');
expect(() => dangerousFunction()).toThrow(ValidationError);

// Async error:
await expect(async () => {
  await asyncDangerousFunction();
}).rejects.toThrow(NetworkError);

// Mock assertions:
const mockFn = jest.fn(() => 42);
mockFn('hello', 'world');

expect(mockFn).toHaveBeenCalledTimes(1);
expect(mockFn).toHaveBeenCalledWith('hello', 'world');
expect(mockFn).toHaveReturnedWith(42);

// Asymmetric matchers for partial mock assertions:
expect(mockFn).toHaveBeenCalledWith(
  expect.stringContaining('hell'), // any string containing 'hell'
  expect.any(String)               // any string value
);
```

> **Code walkthrough:** `toBe` uses strict equality (`===`) - it fails
> for objects because two object literals are never the same reference
> even if their contents match. `toEqual` performs deep recursive
> equality, comparing each property. `toMatchObject` is the flexible
> option for partial matches - useful for asserting a response has a
> specific status without asserting all other properties. Error
> assertions require wrapping the throwing code in a function - `toThrow`
> calls the function internally and catches the error. Asymmetric
> matchers like `expect.any(String)` combine with other matchers for
> flexible partial assertions.

---

### ⚖️ Comparison Table

| Matcher | What it checks | Use for |
|---|---|---|
| `toBe` | `===` (reference) | Primitives, same object |
| `toEqual` | Deep equality | Objects, arrays |
| `toMatchObject` | Partial match | Response shapes, subsets |
| `toStrictEqual` | Deep + undefined | Exact object shape |
| `toContain` | Member/substring | Arrays, strings |
| `expect.any(T)` | Any value of type | Mock argument flexibility |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `toBe` uses `===` so it's for primitives. `toEqual` does deep
> comparison so it's for objects and arrays. `toMatchObject` checks
> that an object contains at least these properties. For errors, I
> wrap the function in an arrow function: `expect(() => fn()).toThrow()`.

**Senior / Staff:**

> Matcher choice affects test fragility. `toEqual` on a large object
> asserts every property - adding a new field to the response breaks
> the test even if the field being tested is correct. `toMatchObject`
> or `expect.objectContaining` for partial assertions makes tests
> resilient to schema additions. For mock assertions, `toHaveBeenCalledWith`
> with `expect.any(String)` asymmetric matchers avoids asserting on
> arguments that aren't relevant to the test case.

---

### ⚠️ Common Misconceptions

**Misconception: `toStrictEqual` is always better than `toEqual`.**

`toStrictEqual` checks for undefined properties and object class
(instances of different classes with same properties are not equal).
This is stricter but also more brittle. Use `toEqual` for plain data
objects; `toStrictEqual` only when class identity or undefined
properties matter.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `toEqual` comparison fails unexpectedly.**

Symptom: `expect(a).toEqual(b)` fails even though objects look identical.

Cause: Date objects, regex, class instances - `toEqual` uses the
same algorithm but handles these specially. A `Date` is equal to
another `Date` only if `.getTime()` values match.

Fix: Use `expect(a).toEqual(expect.objectContaining(b))` for partial
matching. For Date: `expect(date.getTime()).toBe(expected.getTime())`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| `toBe` vs `toEqual` - difference? | Comparison | ★☆☆ | 1 min |
| How to assert an error is thrown? | Scenario | ★★☆ | 2 min |
| How to partially match an object? | Scenario | ★★☆ | 2 min |
| Asymmetric matchers - what are they? | Definition | ★★☆ | 2 min |
| How to assert async rejection? | Scenario | ★★☆ | 2 min |

**Q: When would you use `toMatchObject` instead of `toEqual`?**

A: Use `toMatchObject` when you care about a subset of properties and
want the test to be resilient to future additions.

Example: An API response contains many fields but the test only cares
about specific ones:
```typescript
// BAD: toEqual asserts ALL properties - fails when new fields added
expect(apiResponse).toEqual({
  status: 'success',
  userId: '123',
  // Adding 'timestamp' field later breaks this test
});

// GOOD: toMatchObject asserts only specified fields
expect(apiResponse).toMatchObject({
  status: 'success',
  userId: '123',
  // timestamp, requestId, etc. can be added without breaking test
});
```

Use `toEqual` when exact shape matters (no extra properties allowed),
such as testing a transformation function's output format.

---

# Code Coverage Strategy

---

### 🎯 Model Answer

**30 seconds:**

> Code coverage measures what percentage of your code is executed by
> tests: statement, branch, function, line coverage. A coverage
> percentage is not a quality metric - 100% coverage can coexist with
> zero assertions. Use coverage to find untested code paths, not as
> a target. Focus on: branch coverage (are all conditionals tested?)
> and business logic coverage. Test configuration files and generated
> code are noise.

**Blank Mind Recovery:**

**(1) Four types:** "Statement, branch, function, line coverage."

**(2) Anti-pattern:** "100% coverage ≠ good tests. Tests without
assertions give coverage. Coverage is a floor, not a target."

**(3) Use for:** "Find uncovered branches in business logic. Not for
config files, generated code, or pure UI."

---

### 📘 Concept Explanation

**What it is:**

A measurement of which lines, branches, functions, and statements in
the codebase are executed during the test run.

**The problem it solves:**

Without coverage, you don't know which code paths have zero tests.
Coverage finds the gaps - it doesn't measure test quality.

**How it works:**

```
Coverage types:

Statement coverage:
  Is each statement executed? (most lenient)
  Line: if (a && b) c();
  Covered if the if-statement executes, even if condition is false

Branch coverage:
  Is each branch taken?
  For if (a && b): true/true, true/false, false must all be tested
  Most valuable: catches uncovered error paths

Function coverage:
  Is each function called at least once?
  Less useful: doesn't verify all code within the function

Line coverage:
  Is each line executed?
  Similar to statement coverage

Jest coverage configuration:
  jest --coverage
  generates: lcov report, HTML report, terminal table

  Coverage thresholds (enforce minimums):
  jest.config.js:
    coverageThreshold: {
      global: { branches: 80, functions: 80, lines: 80 }
    }
    coveragePathIgnorePatterns: ['node_modules', 'dist', '.test.']
    collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.d.ts']

Excluded from coverage (configure explicitly):
  - Generated code (GraphQL types, Swagger clients)
  - Configuration files
  - Test files themselves
  - Barrel exports (index.ts re-exports)
  - Type declarations (.d.ts files)
```

---

### 💻 Code Example

**Example (Wrong vs Right) - Coverage without assertions:**

```typescript
// BAD: achieves 100% coverage with zero useful assertions
function processPayment(amount: number, userId: string): boolean {
  if (amount <= 0) return false;
  if (!userId) return false;
  return chargeUser(userId, amount);
}

// This test "covers" all branches but asserts nothing useful:
test('processPayment coverage', () => {
  processPayment(100, 'user1');  // covers true branch of both checks
  processPayment(-1, 'user1');   // covers amount <= 0 branch
  processPayment(100, '');       // covers !userId branch
  // No expect() calls! 100% branch coverage, 0% quality
});

// GOOD: coverage follows from meaningful assertions
test('returns false for non-positive amount', () => {
  expect(processPayment(0, 'user1')).toBe(false);
  expect(processPayment(-100, 'user1')).toBe(false);
});

test('returns false for missing userId', () => {
  expect(processPayment(100, '')).toBe(false);
  expect(processPayment(100, null as any)).toBe(false);
});

test('returns chargeUser result for valid inputs', () => {
  jest.mocked(chargeUser).mockReturnValue(true);
  expect(processPayment(100, 'user1')).toBe(true);
});
// Coverage is 100% AND every assertion is meaningful
```

**Example (Production) - jest.config.js with coverage:**

```javascript
// jest.config.js
module.exports = {
  collectCoverage: false, // only collect when running with --coverage
  collectCoverageFrom: [
    'src/**/*.{ts,tsx}',
    '!src/**/*.d.ts',
    '!src/**/*.stories.tsx',    // Storybook files
    '!src/generated/**',        // Generated GraphQL/OpenAPI types
    '!src/**/index.ts',         // Barrel exports (re-exports only)
    '!src/**/*.config.ts',      // Config files
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
    // Per-file thresholds for critical business logic:
    './src/payments/': {
      branches: 95,
      functions: 95,
    },
  },
  coverageReporters: ['text', 'lcov', 'html'],
};
```

> **Code walkthrough:** The BAD example shows the fundamental limitation
> of coverage as a quality metric: calls without assertions execute
> code paths (giving coverage) without verifying correctness. Jest
> does not require `expect()` calls in a test - a test with zero
> assertions passes. The GOOD example makes every test assert a specific
> behavior. The `jest.config.js` excludes generated code (which
> shouldn't be tested manually) and sets higher thresholds for
> critical payment code. `collectCoverage: false` means coverage only
> runs when explicitly requested with `--coverage`, keeping normal
> test runs fast.

---

### ⚖️ Comparison Table

| Coverage type | What it catches | What it misses |
|---|---|---|
| Statement | Unreachable code | Branch conditions |
| Branch | Untested conditionals | Boundary values |
| Function | Uncalled functions | Internal path coverage |
| Line | Similar to statement | Branch conditions |
| Mutation testing | Missing assertions | Nothing (most powerful) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Coverage shows which lines and branches are executed by tests.
> Branch coverage is the most useful because it shows which conditionals
> are untested. I configure Jest to exclude generated code, config
> files, and test files from coverage reports. A coverage percentage
> doesn't measure test quality - tests need assertions to be valuable.

**Senior / Staff:**

> Coverage is a floor, not a target. An 80% coverage threshold prevents
> untested code from shipping, but 80% coverage can coexist with zero
> assertions if tests are written badly. I focus on branch coverage
> for business logic (payments, auth, validation) and use mutation
> testing (Stryker) for critical modules - it verifies that removing
> a single line of code breaks at least one test. For UI components,
> I don't chase high coverage; I chase high confidence in user-facing
> behavior through RTL integration tests.

---

### ⚠️ Common Misconceptions

**Misconception: 100% code coverage means the code is correct.**

Coverage measures execution, not correctness. A function can be
called in tests with zero `expect()` assertions and achieve 100%
coverage. Coverage confirms that code runs; tests with assertions
confirm that code runs correctly.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Coverage drops unexpectedly in CI.**

Symptom: Coverage goes from 82% to 73% after a PR.

Cause: New code added without corresponding tests, or exclusion
patterns changed.

Diagnose: `jest --coverage --changedSince=main` to see coverage for
only changed files. Review `lcov.info` for specific uncovered lines.

Fix: Add tests for the new code paths. Review the PR for business
logic branches that need assertions.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What are the four coverage types? | Definition | ★☆☆ | 2 min |
| Why is 100% coverage not a good goal? | Trade-off | ★★☆ | 2 min |
| Branch vs line coverage - difference? | Comparison | ★★☆ | 2 min |
| How to configure coverage thresholds? | Scenario | ★★☆ | 2 min |
| What files should be excluded from coverage? | Design | ★★☆ | 2 min |
| What is mutation testing? | Definition | ★★★ | 2 min |

**Q: A new engineer wants to set a 100% code coverage requirement.
What do you say?**

A: 100% coverage is usually the wrong goal, for two reasons:

First, coverage measures execution, not correctness. A test that
calls `processPayment(100, 'user1')` with no `expect()` gives full
coverage of that function with zero verification.

Second, 100% branch coverage for all code is often counterproductive.
Configuration files, generated code, barrel exports, and simple
getters/setters provide no value when tested but add maintenance burden.

Better approach:
- Set 80-90% global threshold to prevent untested code from shipping
- Set 95%+ threshold for critical business logic directories
  (payments, auth, validation) - configure in jest.config.js
- Exclude generated code, config, stories from coverage
- Require meaningful assertions (code review, mutation testing for
  critical paths)
- Use branch coverage as the primary metric (catches untested
  conditionals, not just uncalled lines)

*What separates good from great:* Mutation testing (Stryker) as the
complement to coverage. Mutation testing modifies the source code
(flips `>` to `>=`, changes return values, removes conditions) and
checks whether existing tests catch the mutation. A test suite that
kills 90% of mutations is much higher quality than one achieving
100% line coverage with no assertions.
