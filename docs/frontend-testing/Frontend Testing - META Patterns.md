---
layout: default
title: "Frontend Testing - META Patterns"
parent: "Frontend Testing"
nav_order: 13
permalink: /frontend-testing/meta-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Test Selection Mental Model](#test-selection-mental-model) | medium |
| 2 | [Testing Decision Framework](#testing-decision-framework) | medium |
| 3 | [Test-Driven Development for Frontend](#test-driven-development-for-frontend) | medium |

---

# Test Selection Mental Model

---

### 🎯 Model Answer

**30 seconds:**

> When deciding what to test: ask "what behavior matters to users?"
> then choose the layer that tests it most cheaply. Pure logic ->
> unit tests. Component behavior -> RTL component tests. User flow ->
> E2E. Always test: business logic, auth/permissions, error handling,
> user-visible behavior changes. Don't test: framework code (React
> rendering), library internals, generated code, trivial getters.

**Blank Mind Recovery:**

**(1) Decision question:** "What breaks if this code is wrong? Who is
affected? Test that."

**(2) Layer selection:** "Logic = unit. Component behavior = RTL.
User journey = E2E. Visual = visual regression."

**(3) Don't test:** "React framework itself. Third-party libraries.
Generated code. CSS styling (use visual regression instead)."

---

### 📘 Concept Explanation

**What it is:**

A mental framework for deciding which tests to write, at which layer,
for any given piece of frontend code.

**How it works:**

```
Test selection decision tree:

  Is it pure business logic?
    Yes -> Unit test (no browser, no DOM, fast)
    Examples: calculations, formatters, validators, sorts

  Is it a React component's behavior?
    Yes -> RTL component test
    Test: renders correctly, user interactions, state changes,
          error states, loading states
    Don't test: internal state, CSS classes, prop types

  Is it a critical user journey (full stack)?
    Yes -> E2E test (Playwright/Cypress)
    Test: login, checkout, form submission, navigation
    Don't test: every edge case (those belong in unit/component)

  Is it a visual layout/styling issue?
    Yes -> Visual regression test (Chromatic)
    Test: design system components, stable page layouts
    Don't test: dynamic data pages

  Is it an accessibility requirement?
    Yes -> axe-core test (component or E2E)
    Test: WCAG violations, keyboard navigation

  Does the code interact with external systems?
    Browser APIs: mock them (localStorage, sessionStorage, fetch)
    HTTP APIs: use MSW
    Third-party libraries: use their real implementation
      (don't mock the router, don't mock React Query)

What NOT to test:
  React rendering (it works, not your job to test React)
  CSS styling details (visual regression, not unit tests)
  Third-party library behavior (use their tests)
  Trivial accessors: const getUser = (state) => state.user
  Type-only transformations (TypeScript handles this)
  Generated code (GraphQL types, API clients)
```

> **Code walkthrough:** This Test Selection Mental Model example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Decision) - Applying the mental model:**

```typescript
// Scenario: A checkout feature with 4 components

// 1. price calculation function
// -> Pure logic, unit test
function calculateTotal(items: CartItem[]): number {
  return items.reduce(
    (sum, item) => sum + item.price * item.quantity * (1 - item.discount),
    0
  );
}
// test: calculateTotal([{price:100,qty:2,discount:0.1}]) === 180

// 2. CartItem component (renders price + quantity controls)
// -> Component behavior, RTL test
// test: shows formatted price, +/- buttons change quantity,
//       disabled when out of stock, shows error for invalid qty

// 3. CheckoutPage (orchestrates CartItem, summary, submit)
// -> Component integration test with MSW
// test: shows cart items from API, submit calls POST /api/orders,
//       shows success message, handles 500 error

// 4. Full checkout user journey
// -> ONE E2E test
// test: add item -> go to cart -> enter shipping -> enter payment
//       -> submit -> see confirmation

// Distribution for this feature:
//   Unit tests: 8  (calculation edge cases)
//   Component tests: 12 (CartItem + CheckoutPage behaviors)
//   E2E tests: 1   (full happy path)
// Total: 21 tests covering the feature completely

// What NOT to add:
//   test('CartItem renders a div') // tests React, not your code
//   test('cart API call uses correct method') // tests MSW response
//   test('price is displayed in red when negative') // visual regression
//   test('Cart type has the correct TypeScript interface') // TS handles this
```

> **Code walkthrough:** The four test types map to four distinct concerns.
> The calculation function has no dependencies on React or the DOM -
> it's pure math, so it belongs in a unit test. The CartItem component's
> behavior (quantity controls working, out-of-stock disabling) belongs
> in an RTL component test - it tests what the user experiences. The
> full checkout journey needs E2E to verify the full stack works together.
> The mental model prevents both over-testing (unit testing React's
> rendering) and under-testing (only E2E for edge cases).

---

### ⚖️ Comparison Table

| Code type | Test layer | Reason |
|---|---|---|
| Pure functions | Unit | No dependencies, fast |
| React components | RTL component | User behavior, DOM |
| User journeys | E2E | Full stack integration |
| Visual layouts | Visual regression | Pixel-level detection |
| Accessibility | axe-core | WCAG rule engine |
| Third-party | Don't mock | Test your code, not theirs |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I ask: "What breaks if this is wrong?" For business logic, I write
> unit tests because they're fast and focused. For component behavior
> (what the user sees), I use RTL. For critical user journeys, I use
> Playwright E2E.

**Senior / Staff:**

> The mental model I apply: test at the layer closest to the user
> that doesn't have prohibitive cost. Unit tests for logic. RTL for
> component behavior (user-interaction-level). E2E for the integration.
> The mistake I see most often is testing at the wrong layer: unit
> tests for behavior that requires a real browser, or E2E tests for
> edge cases that are faster as unit tests.

---

### ⚠️ Common Misconceptions

**Misconception: More tests at every layer is always better.**

Tests are code with maintenance cost. A test for trivial behavior
(that React renders a div) adds maintenance burden without catching
bugs. Test selection - choosing what to test - is as important as
test quality.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Tests are slow to write and maintain, low bug detection.**

Cause: Testing at the wrong layer (E2E for logic, unit for integration).

Diagnose: Audit the last 5 production bugs. Which test layer would
have caught each one? If the answer is "none" or "only E2E" for logic
bugs, the test pyramid is inverted.

Fix: Add unit tests for the business logic that escaped. Restructure
E2E tests to cover only critical journeys, not edge cases.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| How do you decide what to unit test vs E2E? | Decision | ★★☆ | 3 min |
| Should you test React's rendering? | Definition | ★☆☆ | 1 min |
| What layer tests a form submission? | Scenario | ★★☆ | 2 min |
| How to choose the right test layer for a feature? | Framework | ★★☆ | 3 min |

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


# Testing Decision Framework

---

### 🎯 Model Answer

**30 seconds:**

> Testing decision framework: start with the Test Trophy (Kent C. Dodds'
> refinement of the pyramid: few unit, many integration, few E2E).
> For each decision: What is the cost? What is the coverage? What is
> the maintenance burden? The goal is highest confidence per unit of
> maintenance. Key principle: "If I delete this test, what bug could
> ship undetected?" If the answer is nothing important, delete the test.

**Blank Mind Recovery:**

**(1) Test Trophy:** "Unit (few) -> Integration/RTL component (many)
-> E2E (few). More integration than pure unit."

**(2) Delete test question:** "What ships undetected if I delete this
test? If nothing important: delete it."

**(3) ROI formula:** "Confidence gained / maintenance cost = test value."

---

### 📘 Concept Explanation

**What it is:**

A decision-making framework for test suite design: how to allocate
testing effort across layers and tools for maximum confidence at
minimum maintenance cost.

**How it works:**

```
Test Trophy (Kent C. Dodds):

         /  E2E  \        <- few, slow, but high confidence
        /----------\
       / Integration \    <- many, medium speed, RTL + MSW
      /--------------\
     /  Unit (logic)  \   <- some, fast, pure functions
    /------------------\
   /  Static (TypeScript)\<- free, type checking

  vs Traditional Pyramid:
       /    E2E    \      <- few
      /  Integration\     <- moderate
     /   Unit (many) \    <- most

  Kent's point: Integration tests with RTL + MSW give more
  confidence than pure unit tests because they test the whole
  component including all its integrations, without the
  overhead of a real browser.

Decision framework (per test):

  1. Confidence gain:
     Would this test catch a real user-facing bug?
     If yes: worth writing. If no: skip.

  2. Maintenance cost:
     How often will this test break on refactoring?
     Low: tests behavior (RTL by role). High: tests CSS or state.
     If high: consider rewriting to test behavior.

  3. Feedback speed:
     How fast does this test run?
     Unit: <1ms. RTL: <100ms. E2E: 10-30 seconds.
     Favor faster tests unless they can't test the behavior.

  4. Scope:
     Is this a boundary condition or a core flow?
     Core flow: test at every layer. Boundary: unit test only.

  Red flags for deleting a test:
    Test name: "component renders"
    Test assertion: toBeDefined(), toBeTruthy() with no context
    Test queries by className: .error-message
    Test accesses component internal state
    Test hasn't failed in 2 years despite many refactors
      (may not be testing meaningful behavior)
```

> **Code walkthrough:** This Testing Decision Framework example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Framework application):**

```typescript
// Decision framework applied to a SearchBar component

// SearchBar behavior to test:
// 1. Shows input field
// 2. Calls onSearch with query when Enter pressed
// 3. Shows loading spinner while searching
// 4. Shows "No results" when results array is empty
// 5. Shows results list when results are returned
// 6. Clears results when input is cleared

// Decision: What layer for each?

// Behavior 1 (shows input field):
// -> Trivial, probably not worth testing alone
// -> Include as part of behavior 2 test (Arrange uses the input)

// Behavior 2 (calls onSearch on Enter):
// -> RTL component test
// -> Mocks onSearch prop, verifies it's called with correct value
test('calls onSearch with query when Enter pressed', async () => {
  const user = userEvent.setup();
  const onSearch = jest.fn();
  render(<SearchBar onSearch={onSearch} />);

  await user.type(screen.getByRole('searchbox'), 'react hooks');
  await user.keyboard('{Enter}');

  expect(onSearch).toHaveBeenCalledWith('react hooks');
});

// Behavior 3 (loading spinner):
// -> RTL component test with mock that delays
test('shows spinner while search is in progress', async () => {
  let resolve: (v: any) => void;
  const onSearch = jest.fn(
    () => new Promise(r => { resolve = r; })
  );
  const user = userEvent.setup();
  render(<SearchBar onSearch={onSearch} />);

  await user.type(screen.getByRole('searchbox'), 'q');
  await user.keyboard('{Enter}');

  expect(screen.getByRole('progressbar')).toBeVisible();
  // resolve search...
});

// Behaviors 4-6: similar RTL tests

// NOT an E2E test: search behavior is fully testable at RTL level
// RTL tests are 100x faster than E2E for this component
// E2E test: full search user journey (search -> result -> detail page)
//           only ONE E2E test for the complete flow
```

> **Code walkthrough:** The framework eliminates the trivial "componentice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> renders" test and focuses on meaningful behaviors. Each test uses the
> component's public interface (props, DOM output) - no internal state
> access. The loading behavior test uses a mock that returns an
> unresolved promise (simulating in-flight request). The decision not
> to write an E2E test for each behavior reflects the cost: RTL runs
> in <100ms, E2E in 10+ seconds. One E2E test covers the end-to-end
> flow.

---

### ⚖️ Comparison Table

| Decision | Signal | Action |
|---|---|---|
| What to test | User-facing behavior | Write test |
| What NOT to test | Framework internals, trivial | Skip |
| Which layer | Cost vs confidence | Lowest cost sufficient layer |
| When to delete | Test never fails, no behavior | Delete |
| Coverage threshold | Floor to prevent gaps | 80% global |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I ask: "Would a user notice if this broke?" If yes, I write a test.
> If it's complex logic, unit test. If it's component behavior, RTL.
> If it's a full user flow, Playwright.

**Senior / Staff:**

> The Test Trophy over the traditional pyramid reflects a key insight:
> RTL integration tests (component + real hooks + MSW handlers) catch
> more bugs than unit tests that mock everything, and are still fast
> enough to run on every PR. The decision framework: test the user-
> observable behavior, not the implementation. Delete tests that have
> never caught a real bug and have broken on multiple refactors.
> The test suite should shrink gracefully as code is refactored - if
> every refactor breaks 50 tests, they're testing the wrong thing.

---

### ⚠️ Common Misconceptions

**Misconception: More tests = better coverage = safer codebase.**

Tests have cost. A test suite with 500 meaningless tests is harder
to maintain than one with 100 meaningful tests. The right number of
tests is the minimum needed to provide sufficient confidence in
critical behaviors. Quality > quantity.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Team disagrees on what to test, inconsistent standards.**

Fix: Document the testing decision framework as a team standard.
Include it in the repository README and onboarding documentation.
Use PR review as enforcement: "This test queries by className - change
to getByRole."

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is the Test Trophy? | Definition | ★★☆ | 2 min |
| How do you decide to delete a test? | Decision | ★★☆ | 2 min |
| Unit tests vs RTL integration - which is better? | Trade-off | ★★★ | 3 min |
| How do you build team-wide testing standards? | Design | ★★★ | 4 min |

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


# Test-Driven Development for Frontend

---

### 🎯 Model Answer

**30 seconds:**

> TDD cycle: Red (write a failing test), Green (write minimal code
> to pass), Refactor (improve without breaking tests). Frontend TDD
> works best for logic (pure functions, custom hooks) and is more
> awkward for UI components (design emerges from visual feedback, not
> specs). Practical frontend TDD: write tests for business logic first,
> use TDD selectively for pure functions and hooks, write tests
> alongside or after for UI components.

**Blank Mind Recovery:**

**(1) Cycle:** "Red -> Green -> Refactor. Write test first, then code."

**(2) Frontend fit:** "Great for logic and hooks. Awkward for visual
components. Use selectively."

**(3) Value:** "Forces testable design. Prevents over-engineering.
Documents expected behavior before code."

---

### 📘 Concept Explanation

**What it is:**

A development practice where tests are written before code, driving
the implementation through the test feedback loop.

**How it works:**

```
TDD cycle:

  1. RED: Write a test for behavior that doesn't exist yet
     -> Test fails (expected)
     -> Test describes the intended behavior precisely

  2. GREEN: Write the minimal code to make the test pass
     -> Don't over-engineer
     -> Code can be ugly - just pass the test
     -> Resist writing more than needed

  3. REFACTOR: Improve the implementation while tests pass
     -> Extract functions, rename variables, improve structure
     -> Tests remain green throughout
     -> Refactoring is safe because tests verify behavior

  TDD advantages for frontend:
    Forces testable design (no hidden dependencies)
    Prevents implementation before interface is clear
    Creates test documentation before code documentation
    Natural stopping point (tests pass = done)

  TDD challenges for frontend UI:
    Visual design is exploratory (hard to specify upfront)
    Component structure emerges from visual feedback
    Storybook-first development is an alternative
      (build component visually, test behavior after)

  Where TDD works well in frontend:
    Custom hooks with clear input/output contract
    Utility functions (validators, formatters, calculators)
    State machines (finite states with clear transitions)
    API adapters (transform API shape to app shape)

  TDD flow for a custom hook:
    test('useCounter starts at 0') -> write state
    test('increment increases count by 1') -> write increment
    test('decrement decreases count by 1') -> write decrement
    test('cannot go below 0') -> add guard
    Refactor: extract helpers, add TypeScript types
```

> **Code walkthrough:** This Test-Driven Development for Frontend example demonstrates a key concept in practice using interface. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (TDD walkthrough) - Custom hook:**

```typescript
// TDD step 1: RED - write test for hook that doesn't exist
import { renderHook, act } from '@testing-library/react';
import { usePagination } from './usePagination';

test('starts at page 1', () => {
  const { result } = renderHook(() => usePagination({ total: 50 }));
  expect(result.current.page).toBe(1);
});
// usePagination doesn't exist yet - test fails (RED)

// TDD step 2: GREEN - minimal implementation
// usePagination.ts:
export function usePagination({ total }: { total: number }) {
  const [page, setPage] = useState(1);
  return { page };
}
// Test passes (GREEN)

// TDD step 3: add next test (RED)
test('nextPage increments page', () => {
  const { result } = renderHook(() => usePagination({ total: 50 }));
  act(() => result.current.nextPage());
  expect(result.current.page).toBe(2);
});
// nextPage doesn't exist - test fails (RED)

// GREEN: add nextPage
export function usePagination({ total }: { total: number }) {
  const [page, setPage] = useState(1);
  const nextPage = () => setPage(p => p + 1);
  return { page, nextPage };
}

// Continue TDD cycle:
test('cannot go beyond last page', () => {
  const { result } = renderHook(() =>
    usePagination({ total: 10, pageSize: 5 })
  );
  // On page 2 of 2:
  act(() => result.current.nextPage()); // page 2
  act(() => result.current.nextPage()); // should stay at 2
  expect(result.current.page).toBe(2);
});
// RED -> implement max page guard -> GREEN

// Refactor after all tests pass:
// Extract totalPages calculation, add TypeScript types,
// add prevPage, add hasPreviousPage/hasNextPage booleans
// All tests still pass after refactor - safe refactoring

// Final hook has:
// - 6 tests written first
// - Implementation driven by tests
// - Types and helpers added in refactor phase
// - No over-engineering (only what tests required)
```

> **Code walkthrough:** The TDD cycle forces a clear interface beforeice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> implementation. Writing `usePagination({ total: 50 })` in the test
> defines the API contract before a single line of implementation
> exists. Each Red-Green cycle adds exactly one feature with the minimal
> code needed. The refactor phase (after all tests pass) is safe because
> the test suite verifies behavior throughout. This prevents the
> common over-engineering pattern where developers implement features
> "just in case" - TDD naturally stops when all tests pass.

---

### ⚖️ Comparison Table

| Approach | Best for | Challenges |
|---|---|---|
| TDD (test first) | Logic, hooks, utilities | Visual UI components |
| Test alongside | UI components | Less design feedback |
| Test after | Exploratory work | Coverage gaps, retrofitting |
| Storybook-first | UI components | Behavior tests added later |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> TDD means writing the test before the code. Red = failing test,
> Green = minimal code to pass, Refactor = improve. I use it for custom
> hooks and utility functions where the interface is clear before
> implementation. For UI components, I usually write tests alongside
> or after because the design evolves visually.

**Senior / Staff:**

> TDD's real value is forcing interface design before implementation
> design. Writing `const { page, nextPage, hasNext } = usePagination(total)`
> in a test first forces you to design the consumer API. The implementation
> follows the contract instead of the contract following the implementation.
> For frontend, I apply TDD selectively: always for custom hooks and
> business logic, rarely for pure UI components where visual feedback
> drives design. The refactor phase is underutilized - the safe
> refactoring that TDD enables (all behaviors specified, change freely)
> is its most powerful benefit.

---

### ⚠️ Common Misconceptions

**Misconception: TDD means you write all tests before all code.**

TDD is a per-function/per-behavior cycle. You write one test, write
code to pass it, refactor, then write the next test. You're always
writing a few lines of test, then a few lines of code. Not 200 tests
first, then 200 functions. The cycle is tight and iterative.

---

### 🚨 Failure Modes and Diagnosis

**Failure: TDD feels slow and mechanical, team stops doing it.**

Cause: Applying TDD to the wrong things (visual components, config,
infrastructure code) creates friction without value.

Fix: Apply TDD where it provides the most value (logic, hooks,
utilities). Use test-alongside or test-after for visual components.
Let TDD be a technique, not a religion.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is the TDD cycle? | Definition | ★☆☆ | 1 min |
| Where does TDD work best in frontend? | Decision | ★★☆ | 2 min |
| TDD for UI components - challenges? | Trade-off | ★★☆ | 2 min |
| How does TDD improve design? | Mechanism | ★★★ | 3 min |
| How to introduce TDD to a team that doesn't practice it? | Behavioral | ★★★ | 3 min |

**Q: How would you introduce TDD practices to a team that writes
tests only after the code?**

A: Don't introduce TDD as a mandate - introduce it as a technique
for specific problem classes.

Approach:
1. Identify where the team has the most test coverage gaps (usually
   logic and utils). Propose: "For this module, let's try writing
   the test contract first."

2. Demonstrate value in a pairing session:
   - Write the test for a utility function
   - Show that the test forces the API design to be clear
   - Implement the minimal code to pass
   - Show how refactoring is safe with tests
   - Measure: "that took 20 minutes and we have 5 tests"

3. Apply selectively - never to visual components, always to:
   - Custom hooks
   - Business logic utilities
   - State management reducers
   - API adapter functions

4. Measure adoption through test timing:
   If new tests are added with code (not after the PR is merged),
   TDD or test-alongside is working.

*What separates good from great:* Recognizing that TDD is a
design technique, not just a testing technique. The question
"what would make this testable?" forces decoupling, clear interfaces,
and single responsibility. Even engineers who write tests after often
benefit from asking "how would I test this?" before writing the
implementation.

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



