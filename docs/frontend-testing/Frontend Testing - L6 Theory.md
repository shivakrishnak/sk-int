---
layout: default
title: "Frontend Testing - L6 Theory"
parent: "Frontend Testing"
nav_order: 12
permalink: /frontend-testing/l6-theory/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Test Confidence vs Coverage Trade-off](#test-confidence-vs-coverage-trade-off) | medium |
| 2 | [Property-Based Testing for Frontend](#property-based-testing-for-frontend) | medium |

---

# Test Confidence vs Coverage Trade-off

---

### 🎯 Model Answer

**30 seconds:**

> Coverage measures what code is executed. Confidence measures how
> certain you are that the code behaves correctly. High coverage does
> not imply high confidence (tests without assertions, trivial
> assertions). High confidence is achievable without 100% coverage
> (focus on critical paths, user-facing behavior). The goal is
> maximizing confidence per unit of test maintenance cost, not maximizing
> coverage percentage.

**3 minutes:**

The confidence vs coverage trade-off is the core intellectual tension
in testing strategy. Coverage is easy to measure; confidence is not.

**Why they diverge:**

A test `test('function runs', () => { myFunction(); })` covers the
function (every statement executes) but provides zero confidence
(no assertions verify correctness). 100% coverage, 0% confidence.

A test with meaningful assertions on critical user paths can provide
high confidence while covering only 60% of the codebase (config files,
generated code, infrastructure code excluded).

**Coverage is a floor, not a ceiling:**

A minimum coverage threshold (e.g., 80%) prevents obviously untested
code from shipping. But the target isn't to reach 100% - it's to
have meaningful tests for meaningful behavior. The last 20% of
coverage often covers:
- Error paths in unreachable code branches
- Infrastructure/config code not worth unit testing
- Generated code (GraphQL types, OpenAPI clients)

**Where to invest in confidence:**

1. Business logic: payment calculations, discount rules, validation
2. Auth/authorization: who can see what, what actions are allowed
3. Data transformations: API response -> UI state mappings
4. Critical user journeys: login, checkout, core workflow

**Blank Mind Recovery:**

**(1) Key insight:** "Coverage = execution. Confidence = correctness
verification. They are different."

**(2) Coverage as floor:** "80% prevents untested code. Not a goal
by itself."

**(3) Invest in:** "Business logic. Auth. Data transforms. Critical
user journeys."

---

### 📘 Concept Explanation

**What it is:**

The tension between two test suite quality dimensions: percentage of
code executed (coverage) vs probability that the suite catches real
bugs (confidence).

**How it works:**

```
Coverage vs Confidence spectrum:

  High Coverage + Low Confidence:
    - Tests exist for every function
    - Tests call functions without assertions
    - Tests assert trivial properties (type, existence)
    - 100% coverage, broken code ships undetected

  Low Coverage + High Confidence:
    - Tests for critical paths only
    - Each test has strong behavioral assertions
    - Edge cases and error paths covered for business logic
    - 60% coverage, critical bugs caught reliably

  High Coverage + High Confidence (target):
    - Coverage > 80% global threshold
    - Tests assert meaningful behavioral outcomes
    - Business logic has > 95% coverage with assertions
    - Confidence is high for user-facing behavior

Confidence metrics (harder to measure):
  Mutation testing score (Stryker):
    Modifies source code (flip >, change return values)
    Checks whether tests catch the mutation
    Score = killed mutations / total mutations
    High mutation score = tests actually verify correctness
    (not just execute code)

  Defect escape rate:
    Bugs found in production vs bugs found in tests
    High escape rate = tests have low confidence for that module

  Test specificity:
    Are assertions specific? "expect(result).toBe(42)" vs
    "expect(result).toBeDefined()" - former is high confidence

Coverage exclusion strategy:
  Exclude from coverage (noise):
    - Generated code (GraphQL types, API clients)
    - Configuration files (jest.config.ts, vite.config.ts)
    - Type declaration files (.d.ts)
    - Barrel exports (index.ts with re-exports only)
    - Storybook stories
    - Main entry files (main.tsx just renders <App />)

  Include at 95%+ threshold:
    - Business logic modules (payments, auth, validation)
    - Data transformation utilities
    - API client adapters
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Trade-off) - High coverage vs high confidence:**

```typescript
// Test A: High coverage, low confidence
test('UserService.createUser', () => {
  const service = new UserService();
  service.createUser({ name: 'Alice', email: 'a@b.com' });
  // No assertion! Coverage: 100% of createUser. Confidence: 0%.
});

// Test B: High coverage, medium confidence
test('UserService.createUser returns something', () => {
  const service = new UserService();
  const result = service.createUser({ name: 'Alice', email: 'a@b.com' });
  expect(result).toBeDefined();
  // Coverage: 100%. Confidence: low (undefined check isn't behavioral)
});

// Test C: Selective coverage, high confidence
test('createUser generates unique id for each user', () => {
  const service = new UserService();
  const user1 = service.createUser({ name: 'Alice', email: 'a@b.com' });
  const user2 = service.createUser({ name: 'Bob', email: 'b@c.com' });
  expect(user1.id).not.toBe(user2.id);
  expect(user1.id).toMatch(UUID_PATTERN);
  // Coverage: partial (only ID generation path). Confidence: high
  // for the specific behavior being tested.
});

test('createUser rejects invalid email format', () => {
  const service = new UserService();
  expect(() => service.createUser({
    name: 'Alice',
    email: 'not-valid',
  })).toThrow(ValidationError);
  // Coverage: error path only. Confidence: high for validation.
});

// Mutation testing (Stryker) detects confidence gaps:
// If createUser has: if (email.includes('@')) { ... }
// Mutation: if (!email.includes('@')) { ... }
// Test B (just toBeDefined) does NOT kill this mutation - passes anyway
// Test C (expects ValidationError on invalid) DOES kill this mutation
```

> **Code walkthrough:** Test A executes 100% of the code with zero
> assertions - illustrating that coverage tells you nothing about
> confidence. Test B is better but `toBeDefined()` doesn't verify any
> behavioral contract. Test C and D are specific: they assert exact
> outcomes that would fail if the implementation is wrong. Mutation
> testing (Stryker) formalized this: it modifies the implementation
> and checks whether tests catch it. Tests B fail to detect mutations;
> Tests C/D succeed. Coverage % tells you where code is executed;
> mutation score tells you whether tests actually verify correctness.

---

### ⚖️ Comparison Table

| Metric | What it measures | What it misses |
|---|---|---|
| Line coverage | Code execution | Assertion quality |
| Branch coverage | Conditional paths | Assertion quality |
| Mutation score | Assertion effectiveness | Human judgment |
| Defect escape rate | Post-production bugs | Future bugs |
| Test count | Test quantity | Test quality |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Coverage shows which lines are executed. You can have 100% coverage
> with tests that make no assertions. Confidence is whether the tests
> would actually catch a bug. I focus on writing tests that assert
> specific behaviors, not just that code runs.

**Senior / Staff:**

> The coverage vs confidence trade-off is why I advocate mutation
> testing for critical modules. Coverage tells you a test exists;
> mutation testing tells you the test is meaningful. A 90% mutation
> score means 90% of realistic code changes would be caught by
> existing tests. For payment and auth modules, I aim for 90%+
> mutation score, not just high coverage. For UI components with
> stable, trivial behavior, 80% branch coverage with meaningful
> assertions is sufficient.

---

### ⚠️ Common Misconceptions

**Misconception: You need to measure mutation score for all code.**

Mutation testing is expensive (it runs the test suite once per
mutation, which can be thousands of runs). It's valuable for critical
business logic modules, not for every file. Focus mutation testing
on the 20% of code where bugs have the most impact.

---

### 🚨 Failure Modes and Diagnosis

**Failure: High coverage, bugs in production.**

Cause: Tests have low assertion specificity (toBeDefined, toBeTruthy
on everything) - coverage without confidence.

Diagnose: Run Stryker mutation testing on the affected module. Check
mutation score. If < 60%, tests are not verifying behavior.

Fix: Add targeted tests with specific assertions for the business
rules that were violated. Don't just increase coverage - increase
assertion specificity.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| Coverage vs confidence - explain the difference | Definition | ★★★ | 3 min |
| What is mutation testing? | Definition | ★★★ | 3 min |
| Why can 100% coverage coexist with bugs? | Mechanism | ★★★ | 2 min |
| How to maximize confidence per maintenance cost? | Strategy | ★★★ | 4 min |
| When to use mutation testing? | Decision | ★★★ | 3 min |

**Q: A critical payment bug escaped to production despite high test
coverage. How do you prevent recurrence?**

A: Coverage didn't protect against this bug, so the answer isn't
"add more tests" - it's "add better tests."

Investigation:
1. Which specific line/branch in the payment module was the bug in?
2. Was there an existing test for that code path?
3. If yes: what assertion did it have? Was it specific enough to
   catch the wrong behavior?
4. Run Stryker on the payment module: what is the mutation score?

Remediation:
1. Write a test that would have caught this specific bug (regression test)
2. Run mutation testing on payment module to find other low-confidence areas
3. Add tests with specific assertions for all business rules
   (correct amounts, rounding behavior, edge cases)
4. Set higher coverage threshold for payment module (95%+)
5. Add contract test between frontend and payment API to catch
   schema changes

Process change:
- Payment module changes require two-engineer review
- Include "does this test have specific assertions for this rule?"
  in PR review template

*What separates good from great:* Recognizing that bugs escape
when tests cover execution paths without asserting behavioral
correctness. The regression test for this specific bug is just
the start - mutation testing systematically finds all the other
paths that have coverage-without-confidence.

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


# Property-Based Testing for Frontend

---

### 🎯 Model Answer

**30 seconds:**

> Property-based testing generates many random inputs and verifies
> that properties (invariants) hold for all of them. Instead of
> `test('sorts [3,1,2]', () => ...)`, write `property('sorted output
> is always ascending')` and the framework generates 100 random arrays.
> `fast-check` is the main JS/TS library. Best for: pure functions with
> clear invariants (formatters, validators, parsers, sorting,
> transformations). Not for UI rendering or async operations.

**Blank Mind Recovery:**

**(1) What it does:** "Generates hundreds of random inputs. Verifies
a property holds for all of them."

**(2) Library:** "fast-check for JS/TS. fc.property(), fc.check()."

**(3) Best for:** "Pure functions with invariants: formatters, validators,
sort algorithms, parsers."

---

### 📘 Concept Explanation

**What it is:**

A testing technique that generates hundreds of random inputs and
verifies that stated invariant properties hold for all of them -
catching edge cases that example-based tests miss.

**The problem it solves:**

Example-based tests are limited by the developer's imagination.
`formatCurrency(1234.56)` is tested, but `formatCurrency(0.001)`,
`formatCurrency(999999999999)`, `formatCurrency(-0)`, and
`formatCurrency(NaN)` may not be. Property-based testing generates
these automatically.

**How it works:**

```
Property-based testing model:

  1. Define a property (invariant) that must always hold
  2. Define the input type/constraints (arbitrary values)
  3. Framework generates 100-1000 random inputs
  4. Verifies property holds for each
  5. On failure: shrinks input to minimal failing case

  Example properties:
    Idempotency: encode(decode(x)) === x
    Commutativity: sort(sort(array)) === sort(array)
    Ordering: sorted[i] <= sorted[i+1] for all i
    Boundary: formatDate always returns 10-char string
    Roundtrip: serialize(deserialize(json)) === json

  fast-check API:
    fc.assert(
      fc.property(
        fc.array(fc.integer()),    // arbitrary: array of ints
        (arr) => {
          const sorted = mySort(arr);
          // Property: sorted array is non-decreasing
          for (let i = 0; i < sorted.length - 1; i++) {
            if (sorted[i] > sorted[i + 1]) return false;
          }
          return true;
        }
      )
    );

  Arbitrary types:
    fc.integer()         : any integer
    fc.float()           : any float
    fc.string()          : any string (including unicode, empty)
    fc.array(arb)        : array of any length with element type arb
    fc.record({k: arb})  : object with specified field types
    fc.boolean()         : true or false
    fc.constant('fixed') : always this value
    fc.oneof(a, b, c)    : one of these arbitraries

  Shrinking: on failure, fast-check finds the minimal
  input that still fails (reduces noise in bug report)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Production) - Property tests for a validator:**

```typescript
import fc from 'fast-check';
import { parsePrice, formatCurrency } from './currency';

// Property: roundtrip - format then parse recovers original value
test('format/parse roundtrip holds for valid prices', () => {
  fc.assert(
    fc.property(
      fc.float({ min: 0, max: 1_000_000, noNaN: true }),
      (price) => {
        const formatted = formatCurrency(price);
        const reparsed = parsePrice(formatted);
        // Allow floating point tolerance:
        expect(Math.abs(reparsed - price)).toBeLessThan(0.01);
      }
    ),
    { numRuns: 500 } // run 500 random cases
  );
});

// Property: sorted output is non-decreasing
test('sort output is always non-decreasing', () => {
  fc.assert(
    fc.property(
      fc.array(fc.integer({ min: -1000, max: 1000 })),
      (arr) => {
        const sorted = mySort([...arr]);
        for (let i = 0; i < sorted.length - 1; i++) {
          expect(sorted[i]).toBeLessThanOrEqual(sorted[i + 1]);
        }
      }
    )
  );
});

// Property: email validator accepts all valid patterns
// Example-based would test 3-4 valid emails
// Property-based generates 100+ realistic email patterns
test('valid emails are always accepted', () => {
  // Define the arbitrary for valid email (simplified):
  const validEmail = fc.emailAddress();

  fc.assert(
    fc.property(validEmail, (email) => {
      const result = validateEmail(email);
      expect(result.isValid).toBe(true);
    })
  );
});

// Failure example - fc shows minimal failing case:
// If validateEmail fails for unicode domains:
// fast-check shrinks to: "a@b.xn--p1ai" (minimal unicode domain)
// Not: "john.doe+tag@subdomain.example.co.uk" (generated input)
```

> **Code walkthrough:** The roundtrip property `parse(format(x)) ≈ x`
> is a classic invariant for serialization code. `fc.float({ noNaN: true })`
> generates valid floating point numbers (excluding NaN which might be
> a separate error case). The sort property `sorted[i] <= sorted[i+1]`
> is the algorithmic definition of sorted order - and it tests ALL
> orderings and array lengths automatically. When a property test fails,
> fast-check's shrinking algorithm finds the minimal input that still
> fails: if the email validator fails on a 50-character email, shrinking
> finds the shortest email that still triggers the bug.

---

### ⚖️ Comparison Table

| Approach | What it tests | Input scope | Best for |
|---|---|---|---|
| Example-based | Specific inputs | What developer imagined | Most cases |
| Property-based | Invariants | Generated (vast) | Pure functions, parsers |
| Fuzzing | Error handling | Edge cases | Security, robustness |
| Mutation testing | Assertion strength | All mutations | Critical logic |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Property-based testing uses `fast-check` to generate hundreds of
> random inputs and check that an invariant holds for all of them.
> Instead of writing specific examples, I write a property like "sorted
> output is always non-decreasing" and fast-check generates the test
> cases. It's great for pure functions.

**Senior / Staff:**

> Property-based testing is most valuable for pure transformation
> functions with clear invariants: formatters that have parse/format
> roundtrip, sort functions where the output must be non-decreasing,
> validators that should accept all inputs matching a spec. The investment
> pays off when the function is called with a wide variety of real-world
> inputs that example tests can't anticipate. For UI rendering and
> async operations, example-based tests are more practical.

---

### ⚠️ Common Misconceptions

**Misconception: Property-based testing replaces example-based testing.**

Property-based testing is additive. Example-based tests document
specific known cases and their expected outputs. Property-based tests
verify invariants across a space of inputs. You need both: examples
for documentation and regression, properties for edge case discovery.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Property test runs take too long.**

`numRuns: 1000` can be slow for complex properties. Default is 100 runs.

Fix: Reduce `numRuns` for expensive properties. Use seed-based
deterministic runs in CI: `fc.assert(prop, { seed: 12345 })`.
Record and replay failing seeds: when fast-check finds a failure, it
logs the seed so the exact same run can be reproduced.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is property-based testing? | Definition | ★★★ | 2 min |
| Example-based vs property-based | Comparison | ★★★ | 3 min |
| What is shrinking? | Definition | ★★★ | 2 min |
| When should you use property-based testing? | Decision | ★★★ | 3 min |
| What properties would you test for a shopping cart? | Design | ★★★ | 5 min |

**Q: What properties would you test for a shopping cart total
calculation function?**

A:
```typescript
import fc from 'fast-check';
import { calculateTotal } from './cart';

const cartItem = fc.record({
  price: fc.float({ min: 0.01, max: 10000, noNaN: true }),
  quantity: fc.integer({ min: 1, max: 100 }),
  discount: fc.float({ min: 0, max: 1, noNaN: true }),
});

// Property 1: total is always non-negative
fc.assert(fc.property(
  fc.array(cartItem, { minLength: 0, maxLength: 20 }),
  (items) => {
    const total = calculateTotal(items);
    expect(total).toBeGreaterThanOrEqual(0);
  }
));

// Property 2: empty cart = zero total
fc.assert(fc.property(
  fc.constant([]),
  (items) => {
    expect(calculateTotal(items)).toBe(0);
  }
));

// Property 3: adding item increases total (unless discounted 100%)
fc.assert(fc.property(
  fc.array(cartItem),
  cartItem,
  (items, newItem) => {
    if (newItem.discount < 1) {
      const before = calculateTotal(items);
      const after = calculateTotal([...items, newItem]);
      expect(after).toBeGreaterThan(before);
    }
  }
));

// Property 4: 100% discount item contributes nothing
fc.assert(fc.property(
  fc.array(cartItem),
  (items) => {
    const freeItem = { price: 100, quantity: 1, discount: 1.0 };
    const without = calculateTotal(items);
    const with_ = calculateTotal([...items, freeItem]);
    expect(with_).toBe(without);
  }
));
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Combining property tests for
invariants with specific example tests for exact values:
`calculateTotal([{price: 10, qty: 3, discount: 0.2}]) === 24.00`
(example: specific known answer) + property tests for all orderings.

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



