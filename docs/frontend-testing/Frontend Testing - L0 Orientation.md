---
layout: default
title: "Frontend Testing - L0 Orientation"
parent: "Frontend Testing"
nav_order: 1
permalink: /frontend-testing/l0-orientation/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Frontend Testing Landscape](#frontend-testing-landscape) | medium |
| 2 | [Testing Trophy vs Testing Pyramid](#testing-trophy-vs-testing-pyramid) | medium |
| 3 | [Why Frontend Testing is Hard](#why-frontend-testing-is-hard) | medium |

---

# Frontend Testing Landscape

---

### 🎯 Model Answer

**30 seconds:**

> The frontend testing landscape covers four layers: unit tests
> (logic, utilities), component tests (React components in isolation),
> integration tests (multiple components together), and E2E tests
> (full browser automation). Key tools: Jest/Vitest (unit + component),
> React Testing Library (component), Playwright/Cypress (E2E), Chromatic
> (visual regression), axe-core (accessibility). The Testing Trophy
> (Kent C. Dodds) recommends emphasizing integration tests over unit
> tests for frontend.

**3 minutes:**

Frontend testing differs from backend testing because the primary
artifact is a user interface - a visual, interactive system that
renders differently across browsers, screen sizes, and user states.

The four test layers form a value pyramid:

**Unit tests** verify isolated logic: utility functions, reducers,
custom hooks, validators. Fast (milliseconds), cheap to write. Limited
value for UI because they don't verify rendering or user interaction.

**Component tests** render a single React (or Vue/Angular) component
in a test environment using JSDOM and verify its output. React Testing
Library (RTL) is the standard: query the DOM as a user would (by
role, label text, placeholder), interact (click, type), assert output.

**Integration tests** verify multiple components working together -
a form with validation, a list with pagination. The highest-value
test type in Kent C. Dodds's Testing Trophy because they test
realistic scenarios without full browser overhead.

**E2E tests** drive a real browser (Playwright, Cypress) through
complete user workflows: login → navigate → submit → verify. Highest
confidence, highest cost, most flaky.

**Visual regression tests** (Chromatic, Percy) capture screenshots of
components and flag pixel-level changes. Catch CSS regressions that
functional tests miss.

**Blank Mind Recovery:**

**(1) Four layers:** "Unit (logic), Component (single render), Integration
(multi-component), E2E (browser)."

**(2) Tools:** "Jest/Vitest + RTL (component). Playwright/Cypress (E2E).
Chromatic (visual). axe-core (a11y)."

**(3) Trophy:** "Integration tests highest value for frontend. Unit tests
less valuable than backend because rendering = the product."

---

### 📘 Concept Explanation

**What it is:**

The set of testing strategies, tools, and practices used to verify
that a frontend application behaves correctly from a user's perspective.

**The problem it solves:**

Frontend bugs manifest differently than backend bugs: visual breakage,
interaction failures, rendering regressions, accessibility violations.
A pure unit test suite can pass while the UI is broken.

**How it works:**

```
Test environment stack:

  Playwright E2E:
    Real browser (Chromium/Firefox/WebKit)
    Full DOM, CSS, network
    Actual user journey verification
    Slowest (seconds per test)

  React Testing Library + JSDOM:
    Simulated browser environment (JSDOM)
    Component renders in Node.js
    No real CSS (JSDOM ignores styles)
    No real network (mock with MSW)
    Fast (milliseconds per test)

  Jest/Vitest unit:
    Pure JavaScript execution
    No DOM required
    Fastest (sub-millisecond per test)

Test types by value:

  E2E tests:
    + Highest confidence (real browser, real flows)
    - Slowest, most flaky, hardest to maintain
    Best for: critical user flows (checkout, login)

  Integration/component tests:
    + High confidence, fast, reliable
    - No real CSS/browser
    Best for: feature behavior, form flows

  Unit tests:
    + Fastest, most precise
    - Low coverage of UI rendering
    Best for: utilities, business logic, reducers
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Ecosystem tools:**

| Layer | Primary tools | Alternative |
|---|---|---|
| Unit + component | Jest + RTL | Vitest + RTL |
| E2E | Playwright | Cypress |
| Visual regression | Chromatic | Percy, Playwright |
| Accessibility | axe-core | pa11y |
| API mocking | MSW | jest.mock |

---

### 💻 Code Example

**Example (Recognition) - A complete test stack:**

```typescript
// Unit test (logic only):
// src/utils/formatPrice.test.ts
import { formatPrice } from './formatPrice';

test('formats cents as dollars', () => {
  expect(formatPrice(1999)).toBe('$19.99');
  expect(formatPrice(0)).toBe('$0.00');
});

// Component test (React Testing Library):
// src/components/PriceDisplay.test.tsx
import { render, screen } from '@testing-library/react';
import { PriceDisplay } from './PriceDisplay';

test('displays formatted price', () => {
  render(<PriceDisplay cents={1999} />);
  expect(screen.getByText('$19.99')).toBeInTheDocument();
});

// Integration test (form + validation + component):
// src/features/checkout/CheckoutForm.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { CheckoutForm } from './CheckoutForm';

test('shows error when submitting empty form', async () => {
  const user = userEvent.setup();
  render(<CheckoutForm onSubmit={jest.fn()} />);

  await user.click(screen.getByRole('button', { name: /submit/i }));

  expect(screen.getByText(/email is required/i)).toBeInTheDocument();
});

// E2E test (Playwright - real browser):
// e2e/checkout.spec.ts
import { test, expect } from '@playwright/test';

test('user can complete checkout', async ({ page }) => {
  await page.goto('/checkout');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="card"]', '4242424242424242');
  await page.click('button[type="submit"]');
  await expect(page.locator('.success-message')).toBeVisible();
});
```

> **Code walkthrough:** The four test types in the same codebase show
> the spectrum from fast/precise (unit) to slow/realistic (E2E). The
> unit test verifies pure logic in milliseconds with no DOM. The
> component test renders a single component in JSDOM and asserts
> text is visible. The integration test simulates real user interaction
> (typing, clicking) using `userEvent` and verifies validation behavior.
> The E2E test controls a real browser, testing the entire stack from
> browser through application to API.

---

### ⚖️ Comparison Table

| Test type | Speed | Confidence | Flakiness | Maintenance |
|---|---|---|---|---|
| Unit | Very fast | Low (for UI) | None | Low |
| Component | Fast | Medium | Very low | Medium |
| Integration | Fast | High | Low | Medium |
| E2E | Slow | Very high | High | High |
| Visual regression | Medium | Medium | Medium | Medium |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> The four test types are unit (logic), component (single component
> render), integration (multi-component), and E2E (real browser).
> I use Jest or Vitest with React Testing Library for component and
> integration tests, and Playwright for E2E. The Testing Trophy says
> integration tests give the best value for frontend.

**Senior / Staff:**

> Frontend test strategy differs from backend because the product IS
> the rendering. Pure unit tests have limited value for UI - they verify
> logic but not the thing users see and interact with. The Testing
> Trophy pattern inverts the traditional pyramid: fewer unit tests,
> more integration tests (component level with RTL), and targeted E2E
> for critical flows. I match test type to what I'm verifying:
> logic -> unit, rendering + interaction -> RTL integration,
> critical flows + visual regressions + A11y -> E2E + specialized tools.

---

### ⚠️ Common Misconceptions

**Misconception 1: High unit test coverage means the UI is tested.**

Unit tests verify JavaScript logic. A component can have 100% unit
test coverage on its helper functions while the rendered UI has
broken layout, inaccessible elements, or interaction failures. Unit
tests cannot catch rendering, styling, or accessibility issues.

**Misconception 2: E2E tests should replace integration tests.**

E2E tests are 10-100x slower and 10x more flaky than integration
tests. Running 500 E2E tests takes hours. Running 500 RTL integration
tests takes seconds. E2E tests are valuable for critical paths; they
should not be the primary verification strategy.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Test suite is slow (> 5 minutes for component tests).**

Cause: Mounting too many full application trees in tests; no isolation.

Fix: Use React Testing Library with minimal context providers. Mock
API calls (MSW). Run tests in parallel (Jest workers or Vitest threads).

**Failure: Tests pass but UI is broken.**

Cause: Tests query by implementation detail (CSS class, data-testid)
not by user-visible text or role. Changes to implementation that
don't change behavior break tests; changes to behavior that users see
are not caught.

Fix: Query by accessible role, label text, or visible text. Write
tests that fail when what the user sees changes.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What are the four frontend test layers? | Definition | ★☆☆ | 1 min |
| Testing Trophy vs Testing Pyramid | Comparison | ★★☆ | 2 min |
| Why does RTL query by role not class? | Mechanism | ★★☆ | 2 min |
| When to write E2E vs integration test? | Decision | ★★☆ | 2 min |
| What tools make up a full frontend test stack? | Definition | ★☆☆ | 2 min |
| Why are frontend tests harder than backend? | Design | ★★☆ | 2 min |
| Test coverage metrics - are they useful? | Trade-off | ★★☆ | 2 min |

**Q: What is the difference between the Testing Pyramid and the
Testing Trophy?**

A: Both are frameworks for deciding how many tests of each type to
write.

Testing Pyramid (classic, Mike Cohn):
```
    /\
   /E2E\
  /-----\
 / Integr\
/----------\
/   Unit     \
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Write many unit tests, fewer integration tests, very few E2E tests.
Designed for backend systems where unit = a function or class with
clear inputs and outputs.

Testing Trophy (Kent C. Dodds, frontend-focused):
```
  /E2E\
 /------\
/ Integr \
/---------\
/ Unit     \
/- Static  -\
(TypeScript, ESLint)
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Integration tests are the largest group. Unit tests are fewer because
isolating individual components often tests implementation details
rather than user behavior.

Why the difference? For backend: unit test = verify a function.
High value. For frontend: unit test = verify a utility function.
Rendering is the product; testing functions without rendering
verifies the wrong thing.

*What separates good from great:* Knowing that these are guidelines,
not rules. A state management library deserves many unit tests. A
CRUD form deserves integration tests. A checkout flow deserves E2E
coverage. Match the test type to what you're verifying, not to a
diagram.

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


# Testing Trophy vs Testing Pyramid

---

### 🎯 Model Answer

**30 seconds:**

> The Testing Pyramid (classic): many unit, fewer integration, few E2E.
> The Testing Trophy (frontend): static analysis (TypeScript, ESLint)
> at the base, integration tests as the largest group, fewer unit
> tests, few E2E tests. The Trophy is better for frontend because
> integration tests verify rendered components with real user
> interactions - closer to what users experience than isolated unit
> tests of helper functions.

**Blank Mind Recovery:**

**(1) Pyramid:** "Unit heavy. Good for backend pure functions."

**(2) Trophy:** "Integration heavy. Good for frontend - rendering is
the product. TypeScript at base catches bugs for free."

**(3) Decision:** "Unit: business logic, utils, reducers. Integration
(RTL): components, forms, flows. E2E: critical paths only."

---

### 📘 Concept Explanation

**What it is:**

Two competing frameworks for deciding the distribution of test types
in a frontend codebase. The Trophy is the modern frontend-specific
recommendation.

**How it works:**

```
Testing Pyramid (Mike Cohn, 2009):
  Top    : E2E tests (few, slow, expensive)
  Middle : Integration tests (some)
  Bottom : Unit tests (many, fast, cheap)
  Based on: traditional enterprise Java/C# backend code
  Unit test = a function/class with clear contract
  Value: catch regression in isolated logic quickly

Testing Trophy (Kent C. Dodds, 2018):
  Top    : E2E tests (few, for critical flows)
  Upper  : Integration tests (most tests live here)
  Lower  : Unit tests (for utilities, logic)
  Base   : Static analysis (TypeScript + ESLint = free tests)
  Based on: React/JS frontend code
  Integration = component rendered with RTL, user interactions
  Value: test the thing users actually see and interact with

Why Trophy for frontend:
  Frontend "unit" = utility function (low value to test)
  Frontend "integration" = component with interactions (high value)
  Rendering IS the product - verify it renders correctly
  TypeScript catches: null references, type errors (free, at write time)
  ESLint catches: common mistakes (free, at write time)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Wrong vs Right) - Pyramid vs Trophy approach:**

```typescript
// PYRAMID approach: many unit tests, test implementation

// Unit test for formatting utility:
test('formatDate returns expected string', () => {
  expect(formatDate(new Date('2024-01-15'))).toBe('Jan 15, 2024');
});

// PROBLEM: This component test uses shallow render (Enzyme-style)
// and tests props, not what the user sees:
test('DateDisplay renders with formatted prop', () => {
  const wrapper = shallow(<DateDisplay date="2024-01-15" />);
  expect(wrapper.find('.date-text').prop('children')).toBe('Jan 15, 2024');
});
// Testing CSS class and internal prop - brittle to implementation change

// TROPHY approach: fewer units, more integration (user perspective)

// Keep the utility test (pure logic, worth testing):
test('formatDate returns expected string', () => {
  expect(formatDate(new Date('2024-01-15'))).toBe('Jan 15, 2024');
});

// But the component test queries by visible text, not internal impl:
test('DateDisplay shows formatted date', () => {
  render(<DateDisplay date="2024-01-15" />);
  expect(screen.getByText('Jan 15, 2024')).toBeInTheDocument();
});
// Refactoring the CSS class or internal structure doesn't break test
// Adding a new format DOES break test (correct - behavior changed)

// TypeScript as "free unit tests":
// Instead of: test('throws on null date', () => {...})
// TypeScript prevents calling with null at compile time:
interface DateDisplayProps {
  date: string; // null not allowed - TypeScript prevents it
}
```

> **Code walkthrough:** The Trophy approach values tests that verify
> what users see over tests that verify implementation details. The
> `getByText('Jan 15, 2024')` assertion fails only when the visible
> text changes - which is exactly when a user would notice the
> regression. The `.prop('children')` assertion fails whenever the
> internal structure changes, even if the rendered output is identical.
> TypeScript's type annotations replace a category of unit tests
> (null safety, type safety) with compile-time checks that are faster
> and always up to date.

---

### ⚖️ Comparison Table

| Aspect | Testing Pyramid | Testing Trophy |
|---|---|---|
| Dominant test type | Unit | Integration (component) |
| Test environment | Pure JS | JSDOM (RTL) |
| Based on | Backend patterns | Frontend (React) patterns |
| Static analysis | Not counted | Base layer |
| Good for | Business logic | UI components, flows |
| Risk of heavy unit tests | Over-testing internals | Under-testing logic |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> The Testing Pyramid says write many unit tests. The Testing Trophy
> says write more integration tests for frontend because they test
> what users see. TypeScript and ESLint sit at the base and catch bugs
> for free without writing test code.

**Senior / Staff:**

> The Pyramid was designed for backend systems where unit = isolated
> function with clear contracts. For frontend, the "unit" is often a
> UI component, and testing it in isolation tests implementation details
> that users don't care about. The Trophy inverts this: integration
> tests with RTL are the primary layer because they render the actual
> component, simulate real user interactions, and verify user-visible
> outcomes. TypeScript at the base catches type errors at write time -
> before any test runs - making them the most cost-effective "tests."

---

### ⚠️ Common Misconceptions

**Misconception: The Trophy says don't write unit tests.**

The Trophy includes unit tests - it just says they should be for
logic that benefits from isolation (utilities, business rules, state
machines, custom hooks) rather than for every function in a component.
The distribution shifts toward integration, not away from unit to zero.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Excessive Enzyme-style "shallow render" unit tests that
test props and state directly.**

Symptom: Test suite breaks on every refactoring even when behavior
is unchanged.

Fix: Replace shallow renders with RTL `render()`. Query by accessible
attributes. Tests should break when user-visible behavior changes,
not when internal structure changes.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| Testing Pyramid vs Trophy - explain | Comparison | ★★☆ | 2 min |
| Why is TypeScript at the base of the Trophy? | Mechanism | ★★☆ | 2 min |
| What percentage of tests should be E2E? | Decision | ★★☆ | 2 min |
| When does the Pyramid apply to frontend? | Trade-off | ★★★ | 2 min |

**Q: In the Testing Trophy, why are integration tests more valuable
than unit tests for frontend?**

A: For frontend, the product is the rendered user interface. A unit
test that verifies `formatPrice(1999) === '$19.99'` provides some
value. A unit test that verifies an internal class or prop value of
a React component provides low value - it tests implementation
details that users never see.

An integration test with RTL renders the actual component, finds
elements by accessible role or visible text, simulates clicks and
keyboard input, and asserts on user-visible output. It tests
the same code path a user exercises.

Benefits of integration over unit for UI:
1. Tests don't break when internals are refactored (if behavior is same)
2. Tests DO break when user-visible behavior changes (correct)
3. One integration test covers multiple "units" (component + hook + util)
4. Catches interaction between parts that unit tests miss

The integration layer is "most tests per dollar of confidence" for
frontend. E2E gives higher confidence but at 10-100x the cost.

*What separates good from great:* The Trophy doesn't say to minimize
unit tests. Custom hooks, state reducers, validation logic, and utility
functions all deserve unit tests. The skill is identifying where each
test type provides the most value per test written.

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


# Why Frontend Testing is Hard

---

### 🎯 Model Answer

**30 seconds:**

> Frontend testing is hard because: (1) the DOM is a stateful, event-
> driven environment hard to simulate, (2) async operations (data
> fetching, animations, timers) create timing issues, (3) visual
> rendering (CSS, layout) cannot be verified by JS tests, (4) browser
> environment differences (JSDOM vs real browsers), and (5) external
> dependencies (APIs, auth, third-party scripts) require mocking
> infrastructure. Backend tests are deterministic; frontend tests deal
> with time, events, and visual state.

**Blank Mind Recovery:**

**(1) Five challenges:** "DOM statefulness, async timing, visual CSS,
browser differences, external deps."

**(2) Solutions:** "RTL wraps in act(). MSW mocks API. Playwright uses
real browser. Chromatic catches CSS. Test IDs for brittle selectors."

---

### 📘 Concept Explanation

**What it is:**

The specific technical challenges that make frontend tests harder to
write and maintain than backend tests.

**The problem it solves:**

Understanding WHY frontend tests fail or are flaky enables better
test design and tooling choices.

**How it works:**

```
Challenge 1: Async rendering
  React renders asynchronously. Component renders, state updates,
  re-renders. Test must wait for the final rendered state.
  WRONG:
    render(<AsyncComponent />);
    expect(screen.getByText('Loaded')).toBeInTheDocument();
    // Error: 'Loaded' not yet in DOM
  RIGHT:
    render(<AsyncComponent />);
    await waitFor(() =>
      expect(screen.getByText('Loaded')).toBeInTheDocument()
    );

Challenge 2: DOM simulation vs real browser
  JSDOM (jest/vitest environment):
    - No CSS support (computed styles not applied)
    - No real layout engine (element dimensions are zero)
    - No real network (must mock with MSW or jest.fn())
    - No real browser APIs (canvas, WebGL, some APIs missing)
  Real browser (Playwright):
    - Full CSS and layout
    - Real network
    - More realistic but much slower

Challenge 3: Flaky async tests
  Animation timers, debounced inputs, polling intervals:
  test waits too short -> intermittent failures
  test waits too long -> slow suite
  Fix: use findBy* (waits up to 1000ms by default) instead of
  getBy* (synchronous, throws immediately if not found)

Challenge 4: External dependencies
  API calls, authentication, third-party scripts must be:
  mocked (unit/integration) or real (E2E with test environment)
  MSW: intercepts HTTP requests at network level in both test
  and browser environments using Service Workers

Challenge 5: Test brittle to implementation
  Tests that query by CSS class or data-testid break on refactor
  Tests that query by visible text or role are more resilient
  RTL philosophy: query like a user, not like a developer
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

**Example (Wrong vs Right) - Async rendering:**

```typescript
// BAD: synchronous assertion on async render
test('shows user name after load', () => {
  render(<UserProfile userId="123" />);
  // UserProfile fetches user data, then renders name
  // At this point, the fetch hasn't completed:
  expect(screen.getByText('Alice')).toBeInTheDocument();
  // Intermittent: sometimes passes (fast machine), often fails
});

// GOOD: wait for the element to appear
test('shows user name after load', async () => {
  render(<UserProfile userId="123" />);
  // findByText waits up to 1000ms (configurable):
  const name = await screen.findByText('Alice');
  expect(name).toBeInTheDocument();
  // Stable: waits for React to finish rendering
});

// MSW: mock the API call at the network level
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ id: params.id, name: 'Alice' });
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test('shows user name after load', async () => {
  render(<UserProfile userId="123" />);
  await screen.findByText('Alice');
  // Now the test is stable, realistic, and independent
});
```

> **Code walkthrough:** The synchronous `getByText` assertion fails
> intermittently because React's data fetching is async - the component
> renders a loading state first, then updates when data arrives.
> `findByText` is an async query that polls the DOM until the element
> appears or times out. MSW (Mock Service Worker) intercepts the
> actual HTTP fetch call at the network level - the component code
> is unchanged, but the API returns test data. This is more realistic
> than mocking the fetch function because it tests the actual
> network call path.

---

### ⚖️ Comparison Table

| Challenge | Symptom | Solution |
|---|---|---|
| Async rendering | Intermittent failures | `findBy*`, `waitFor` |
| JSDOM vs browser | CSS tests fail | Playwright for visual |
| External APIs | Slow/flaky tests | MSW for HTTP mocking |
| Timer-based code | Unpredictable timing | `jest.useFakeTimers()` |
| Brittle selectors | Tests break on refactor | Query by role/text |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Frontend tests are harder because of async rendering - you need to
> wait for data fetching to complete before asserting. JSDOM doesn't
> support CSS so you can't test visual styles. I use `findByText`
> for async assertions and MSW to mock API calls.

**Senior / Staff:**

> The root of frontend testing difficulty is the browser environment:
> stateful, event-driven, visually rendered, and dependent on timing.
> JSDOM provides 80% of the test surface but misses CSS, layout, and
> some browser APIs - Playwright fills the gap for visual and
> browser-specific behavior. The async challenge is universal: use
> `findBy*` queries (which wait) over `getBy*` (which throw
> immediately). MSW is the right abstraction for API mocking: it works
> identically in JSDOM tests and real browsers, so the same handlers
> work in Storybook, development, and testing.

---

### ⚠️ Common Misconceptions

**Misconception 1: `act()` warnings mean the test is wrong.**

React Testing Library wraps most operations in `act()` automatically.
You see `act()` warnings when state updates happen outside of an
act-wrapped operation - usually async updates triggered by timers or
API responses. The fix is usually `await findBy*` or `await act(async
() => { ... })`, not disabling the warning.

**Misconception 2: `data-testid` is the recommended way to query.**

RTL recommends querying by accessible attributes first: role, label
text, placeholder, visible text. `data-testid` is the last resort
for elements with no accessible attribute. Over-relying on
`data-testid` makes tests test implementation details rather than
user experience.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Tests pass locally, fail in CI.**

Cause: Machine speed differences - local machine faster, CI slower.
Async operations that barely complete in time locally time out in CI.

Fix: Increase `waitFor` timeout in RTL config. Use `findBy*` instead
of manual `waitFor + getBy*`. Ensure consistent fake timer setup.

**Failure: Test fails with `act()` warning about state updates.**

Symptom: `Warning: An update to Component inside a test was not wrapped in act(...).`

Cause: Async state update triggered after test assertion completes.

Fix:
```typescript
// If using findBy*: it already wraps in act
await screen.findByText('Success');

// If using waitFor:
await waitFor(() => {
  expect(screen.getByText('Success')).toBeInTheDocument();
});
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| Why is frontend testing harder than backend? | Definition | ★★☆ | 2 min |
| What is JSDOM's main limitation? | Mechanism | ★★☆ | 2 min |
| `getBy*` vs `findBy*` vs `queryBy*` | Comparison | ★★☆ | 2 min |
| How MSW works differently from jest.mock | Mechanism | ★★☆ | 2 min |
| Why do tests that pass locally fail in CI? | Debugging | ★★☆ | 2 min |
| How to test async component behavior? | Scenario | ★★☆ | 3 min |

**Q: What is the difference between `getBy*`, `findBy*`, and `queryBy*`
in React Testing Library?**

A: The three query families differ in their behavior when the element
is not found:

`getBy*` (synchronous, throws if not found):
- Use when the element should already be in the DOM
- Throws immediately if element is absent
- Best for: elements present on initial render

`findBy*` (async, returns Promise, throws if not found in timeout):
- Polls the DOM until the element appears or timeout (~1000ms)
- Use when the element appears after an async operation
- Best for: data fetching, state updates, transitions

`queryBy*` (synchronous, returns null if not found):
- Returns null instead of throwing when absent
- Use when asserting an element is NOT present
- Best for: `expect(screen.queryByText('Error')).not.toBeInTheDocument()`

Practical rule:
- Element present on initial render -> `getBy*`
- Element appears after async -> `findBy*`  
- Asserting absence -> `queryBy*`

*What separates good from great:* Using the right query for the
wrong reason causes flaky tests. `getBy*` for an async element causes
intermittent failures. `findBy*` for a synchronous element wastes
time (waits up to 1s unnecessarily). `queryBy*` for an element that
should exist hides bugs (doesn't throw when element is missing).

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



