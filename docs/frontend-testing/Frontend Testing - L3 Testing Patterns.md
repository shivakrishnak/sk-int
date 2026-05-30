---
layout: default
title: "Frontend Testing - L3 Testing Patterns"
parent: "Frontend Testing"
nav_order: 7
permalink: /frontend-testing/l3-testing-patterns/
render_with_liquid: false
---

# Testing Patterns (AAA, Given-When-Then)

---

### 🎯 Model Answer

**30 seconds:**

> Two equivalent test structure patterns: AAA (Arrange, Act, Assert)
> and Given-When-Then (BDD-style). Both organize a test into three
> phases: set up the preconditions, perform the action under test,
> assert the expected outcome. AAA is the dominant pattern in Jest/
> Vitest unit tests. Given-When-Then is used in BDD frameworks (Cucumber,
> Jest-Cucumber) and Playwright tests. The critical rule: one assertion
> concept per test (may need multiple `expect` calls for one concept).

**3 minutes:**

AAA is the structural spine of every well-written unit test:

- **Arrange**: Set up test state - create objects, configure mocks,
  seed data. This is the `beforeEach` content or the first block
  of the test.
- **Act**: Execute the single thing being tested - call the function,
  click the button, submit the form.
- **Assert**: Verify the outcome - check return values, DOM state,
  mock calls.

The single-concept-per-test rule is the most important quality
constraint: a test that asserts 10 different things is testing 10
behaviors but naming and reporting them as one. When it fails, you
don't know which behavior broke. Tests should be granular enough that
a failing test name tells you exactly what broke.

Given-When-Then adds narrative structure:
- **Given**: the precondition state ("Given a logged-in admin user")
- **When**: the triggering action ("When they click Delete User")
- **Then**: the expected outcome ("Then the user is removed from the list")

This maps directly to AAA but reads as a specification of behavior.

**Blank Mind Recovery:**

**(1) AAA:** "Arrange (setup) -> Act (do the thing) -> Assert (verify
outcome). Three separate blocks with blank lines between."

**(2) Single concept:** "One test = one behavior. If test name has
'and', split into two tests."

**(3) GWT:** "BDD style. Same as AAA but reads as specification."

---

### 📘 Concept Explanation

**What it is:**

Structural patterns for organizing test code into clear phases that
are readable, maintainable, and granular.

**The problem it solves:**

Unstructured tests with mixed setup, action, and assertions are hard
to read and debug. When a test fails, you need to understand what was
being tested. The pattern provides visual structure and enforces
separation of concerns within a test.

**How it works:**

```
AAA structure:

  test('description of behavior', () => {
    // Arrange: setup
    const service = new UserService();
    const userData = { name: 'Alice', email: 'a@b.com' };

    // Act: the thing being tested
    const result = service.create(userData);

    // Assert: verify outcome
    expect(result.id).toBeDefined();
    expect(result.name).toBe('Alice');
  });

Single responsibility per test:

  BAD: one test, multiple behaviors
  test('user service works', () => {
    // Tests create, list, and delete in one test
    const user = service.create({ name: 'Alice' });
    expect(service.list()).toHaveLength(1);
    service.delete(user.id);
    expect(service.list()).toHaveLength(0);
    // Which step fails? The name gives no hint.
  });

  GOOD: one concept per test
  test('create returns user with generated id', () => {
    const user = service.create({ name: 'Alice' });
    expect(user.id).toBeDefined();
  });

  test('created user appears in list', () => {
    service.create({ name: 'Alice' });
    expect(service.list()).toHaveLength(1);
  });

  test('deleted user is removed from list', () => {
    const user = service.create({ name: 'Alice' });
    service.delete(user.id);
    expect(service.list()).toHaveLength(0);
  });
  // Now: failing test name tells you exactly what broke

GWT in Playwright (readable specifications):

  test('Admin can delete a user', async ({ page }) => {
    // Given: admin user logged in, viewing user list
    await page.goto('/admin/users');
    const userRow = page.getByRole('row', { name: /alice/i });

    // When: admin clicks delete button for Alice
    await userRow
      .getByRole('button', { name: /delete/i })
      .click();
    await page.getByRole('button', { name: /confirm/i }).click();

    // Then: Alice's row is removed from the list
    await expect(
      page.getByRole('row', { name: /alice/i })
    ).not.toBeVisible();
  });
```

---

### 💻 Code Example

**Example (Wrong vs Right) - Granular vs monolithic tests:**

```typescript
// BAD: monolithic test - when it fails, which behavior broke?
test('checkout flow works', async () => {
  const user = userEvent.setup();
  render(<CheckoutFlow />);

  // 5 different behaviors tested as one:
  expect(screen.getByText('Step 1: Cart')).toBeVisible();
  await user.click(screen.getByRole('button', { name: /proceed/i }));
  expect(screen.getByText('Step 2: Shipping')).toBeVisible();
  await user.type(screen.getByLabelText(/address/i), '123 Main St');
  await user.click(screen.getByRole('button', { name: /next/i }));
  expect(screen.getByText('Step 3: Payment')).toBeVisible();
  // Test name "checkout flow works" = useless failure info
});

// GOOD: one concept per test, descriptive names
describe('Checkout Flow', () => {
  test('shows cart step on initial render', () => {
    render(<CheckoutFlow />);
    expect(screen.getByText('Step 1: Cart')).toBeVisible();
  });

  test('advances to shipping step after proceed', async () => {
    const user = userEvent.setup();
    render(<CheckoutFlow />);

    await user.click(screen.getByRole('button', { name: /proceed/i }));

    await expect(screen.findByText('Step 2: Shipping')).resolves
      .toBeVisible();
  });

  test('shows payment step after entering shipping address', async () => {
    const user = userEvent.setup();
    render(<CheckoutFlow initialStep="shipping" />);

    await user.type(
      screen.getByLabelText(/address/i),
      '123 Main St'
    );
    await user.click(screen.getByRole('button', { name: /next/i }));

    await expect(screen.findByText('Step 3: Payment')).resolves
      .toBeVisible();
  });
});
// Failing test name: "advances to shipping step after proceed"
// -> immediately clear what broke
```

> **Code walkthrough:** The BAD example's test name "checkout flow works"
> tells you nothing when it fails. Is the cart step missing? Does proceed
> not work? Is the payment step broken? Each test covers one behavior,
> so the failing test name is the diagnosis. The GOOD tests use
> `initialStep` prop to start at a specific step, avoiding the need
> for each test to execute all prior steps. This is the "test setup
> via props" pattern - position the component in the required state
> directly rather than navigating there through user interactions.

---

### ⚖️ Comparison Table

| Pattern | Style | Best for | Framework |
|---|---|---|---|
| AAA | Imperative | Unit/component tests | Jest, Vitest |
| Given-When-Then | Narrative | E2E, BDD specs | Playwright, Cucumber |
| Single-concept | Quality rule | All tests | Universal |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I structure every test with Arrange-Act-Assert: setup at top, the
> action being tested in the middle, assertions at the end. I separate
> the three sections with a blank line. Each test should test one
> behavior so the failing test name tells you what broke.

**Senior / Staff:**

> The single-concept rule is the most valuable structural discipline.
> A test with "and" in its name is testing multiple behaviors - split
> it. A test with unclear Arrange/Act boundary is usually testing
> multiple actions. I also apply the rule to test setup: if `beforeEach`
> contains 20 lines of setup used by only 2 of 10 tests, the setup is
> hiding test preconditions. Inline the setup for clarity.

---

### ⚠️ Common Misconceptions

**Misconception: One `expect()` per test.**

The single-concept rule means one *behavioral concept* per test, not
one assertion. `expect(user.id).toBeDefined()` followed by
`expect(user.name).toBe('Alice')` are both verifying properties of
the created user - one concept. Two separate `expect` calls for one
concept is correct. The violation is when expect calls verify
*different concepts* (create AND list AND delete).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Tests are hard to maintain - changing one thing breaks 10 tests.**

Cause: Test interdependence (shared mutable state), or tests that
are testing implementation details (brittle to refactoring).

Diagnose: Count how many tests a single behavioral change breaks. If
> 3, the tests are likely too coupled to implementation.

Fix: Use `beforeEach` for state reset. Use RTL queries (not CSS classes)
for element selection. Test behaviors, not implementations.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is the AAA pattern? | Definition | ★☆☆ | 1 min |
| Why "one concept per test"? | Trade-off | ★★☆ | 2 min |
| Given-When-Then vs AAA - difference? | Comparison | ★★☆ | 2 min |
| How granular should tests be? | Decision | ★★☆ | 2 min |
| Multiple expects in one test - OK or not? | Clarification | ★★☆ | 2 min |

**Q: How do you decide how granular tests should be?**

A: The granularity rule is: failing test name should tell you exactly
what broke.

Test "submit button disabled when form is invalid" - when this fails,
you know exactly what to investigate.

Test "form works" - when this fails, you know nothing.

Practical rules:
1. If the test name contains "and", split it
2. If debugging a failing test requires reading all assertions to
   understand which one failed, the test is too broad
3. If each test in a describe block has identical setup, the setup
   belongs in `beforeEach` - but each test still tests one behavior
4. For integration tests (more steps): one complete user action
   per test (submit form, complete checkout step, delete item)

*What separates good from great:* Recognizing that granularity is
a spectrum. Too granular: `test('add function returns sum')` might
have 10 tests for 10 different input values. Too broad: one test for
the entire payment flow. The right level is: one meaningful user-facing
behavior per test, which typically maps to one user action with one
observable outcome.

---

# Frontend Testing Anti-patterns

---

### 🎯 Model Answer

**30 seconds:**

> Common frontend testing anti-patterns: testing implementation
> details (query by CSS class, test internal state), too many mocks
> (mock entire modules when only one function needs mocking), test
> coupling (shared mutable state between tests), testing the wrong
> layer (testing React component internals instead of behavior),
> assertions without actions (setup tests with coverage but no
> behavior verification), and snapshot tests that are updated without
> review.

**Blank Mind Recovery:**

**(1) Top 3:** "Implementation detail testing. Excessive mocking.
Test coupling (shared state)."

**(2) RTL anti-patterns:** "queryByTestId when role works. Testing
CSS class instead of visibility. Accessing component internal state."

**(3) Snapshot anti-patterns:** "Updating snapshots blindly
(--updateSnapshot on CI). Large snapshots with no review. Using
snapshots for everything instead of specific assertions."

---

### 📘 Concept Explanation

**What it is:**

A catalog of common testing mistakes in frontend codebases that
create test suites which are expensive to maintain and provide low
confidence.

**The problem it solves:**

Anti-pattern tests pass when behavior is broken and fail when behavior
is correct (refactoring). This inverts the value of tests.

**Key anti-patterns:**

```
Anti-pattern 1: Implementation detail testing
  BAD:
    test('state updates on click', () => {
      const { result } = renderHook(() => useCounter());
      act(() => result.current.increment());
      expect(result.current.count).toBe(1); // internal state
    });

  GOOD: Test observable behavior (what user sees)
    test('shows incremented count after click', async () => {
      const user = userEvent.setup();
      render(<Counter />);
      await user.click(screen.getByRole('button', {name:/increment/i}));
      expect(screen.getByText('1')).toBeVisible();
    });

Anti-pattern 2: Snapshot everything
  BAD: Large component snapshots updated blindly
    expect(container).toMatchSnapshot();
    // Snapshot = 500 lines of HTML
    // Review: "looks the same? ok --updateSnapshot"
    // Actually: invisible a11y regression slipped in

  GOOD: Specific assertions for specific behaviors
    expect(button).toBeEnabled();
    expect(heading).toHaveTextContent('Welcome');
    // Reserve snapshots for stable, small, intentional outputs
    // (SVG icons, config objects, not full component trees)

Anti-pattern 3: Over-mocking
  BAD: Mock entire module when only one function is needed
    jest.mock('./utils'); // mocks ALL utils
    // Test now has no idea what formatCurrency does

  GOOD: Mock at the boundary - only what crosses a system boundary
    jest.mock('./api');     // external API: mock
    // utils/formatters: use real implementation
    // Only mock things that are:
    //   - slow (databases, HTTP)
    //   - non-deterministic (Date.now, Math.random)
    //   - side-effectful (console.error, localStorage)
    //   - not the subject of the test

Anti-pattern 4: Test coupling
  BAD: Tests share mutable state
    let userList = [];
    test('adds user', () => { userList.push('Alice'); });
    test('shows user', () => { expect(userList).toContain('Alice'); });
    // Test 2 passes only if Test 1 ran first

  GOOD: Each test is independent
    beforeEach(() => { userList = []; });
    // Now tests can run in any order

Anti-pattern 5: Testing the testing library
  BAD:
    test('button renders', () => {
      render(<Button />);
      expect(screen.getByRole('button')).toBeInTheDocument();
    });
    // This tests that React renders buttons - not your code

  GOOD: Test your component's behavior
    test('button is disabled when form is invalid', () => {
      render(<Form />); // no required fields filled
      expect(screen.getByRole('button', {name:/submit/i}))
        .toBeDisabled();
    });
```

---

### 💻 Code Example

**Example (Failure + Fix) - The "ice cream cone" anti-pattern:**

```typescript
// ICE CREAM CONE: too many E2E, too few unit tests
// Result: test suite takes 30 minutes, breaks on any environment
// issue, doesn't pinpoint failures

// Anti-pattern: E2E test for every edge case
it('shows error for empty email', async ({ page }) => { ... });
it('shows error for invalid email', async ({ page }) => { ... });
it('shows error for email already taken', async ({ page }) => { ... });
// 20 more E2E tests for validation rules...

// CORRECT PYRAMID: most tests at unit level
// Unit tests (fast, isolated):
describe('validateEmail', () => {
  test('returns error for empty email', () => {
    expect(validateEmail('')).toBe('Email is required');
  });
  test('returns error for invalid format', () => {
    expect(validateEmail('not-an-email')).toBe('Invalid email');
  });
  test('returns null for valid email', () => {
    expect(validateEmail('a@b.com')).toBeNull();
  });
});

// Component test (medium, RTL):
test('form displays validation error message', async () => {
  const user = userEvent.setup();
  render(<EmailForm />);
  await user.click(screen.getByRole('button', {name:/submit/i}));
  expect(screen.getByRole('alert'))
    .toHaveTextContent('Email is required');
});

// One E2E test (slow, full-stack):
test('registration flow: validates email', async ({ page }) => {
  await page.goto('/register');
  await page.getByRole('button', {name:/register/i}).click();
  // Verify the error appears in real browser, real server
  await expect(page.getByRole('alert'))
    .toHaveText('Email is required');
});
// 3 tests covering all validation - not 22 E2E tests
```

> **Code walkthrough:** The ice cream cone is the inversion of the
> testing pyramid - heavy on slow E2E tests, light on fast unit tests.
> Email validation logic belongs in a pure function unit test (zero
> browser, <1ms). The component test verifies the form displays the
> error message (browser-like, <100ms). The E2E test verifies the
> full flow works in a real browser (<10 seconds). Writing 20 E2E tests
> for validation variations runs each at 10 seconds = 200 seconds vs
> 20 unit tests at <1ms = <20ms.

---

### ⚖️ Comparison Table

| Anti-pattern | Problem | Correct approach |
|---|---|---|
| Implementation detail testing | Tests break on refactor | Query by role/behavior |
| Snapshot everything | False confidence | Specific assertions |
| Over-mocking | Hides real behavior | Mock only boundaries |
| Test coupling | Order-dependent failures | beforeEach state reset |
| Ice cream cone | Slow, brittle suite | Testing pyramid |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Common anti-patterns: querying by CSS class instead of role (breaks
> on refactor), testing internal state instead of visible output,
> sharing mutable state between tests (order-dependent failures), and
> updating snapshots without reviewing them.

**Senior / Staff:**

> The most damaging anti-pattern I see in production codebases is the
> inverted testing pyramid: 200 E2E tests and 50 unit tests. It's
> intuitive to reach for E2E because they "test the real thing," but
> they create a test suite that takes 40 minutes in CI, fails for
> infrastructure reasons unrelated to the code, and doesn't pinpoint
> which function broke. The pyramid discipline (many unit, fewer
> component, few E2E) is the most impactful quality investment.

---

### ⚠️ Common Misconceptions

**Misconception: More tests always means better coverage.**

Test count is not a quality metric. 1,000 tests with no assertions
pass and cover nothing. 20 precise tests with meaningful assertions
can provide more confidence than 200 tests that test incidental
behavior. Quality of assertions matters more than quantity of tests.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Snapshot tests keep breaking with PR reviews.**

Symptom: Every refactor breaks 50 snapshot tests. Engineers run
`--updateSnapshot` without reviewing changes.

Cause: Using snapshots for large component HTML output instead of
specific assertions. Snapshots become maintenance burden, not safety net.

Fix: Replace snapshot tests with specific assertions for the behaviors
that matter. Reserve snapshots for small, stable, intentional outputs
(config objects, serialized data formats).

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is the testing pyramid? | Definition | ★☆☆ | 2 min |
| What is implementation detail testing? | Definition | ★★☆ | 2 min |
| When are snapshot tests appropriate? | Decision | ★★☆ | 2 min |
| How do you deal with snapshot tests that break constantly? | Scenario | ★★☆ | 2 min |
| What is over-mocking and why is it harmful? | Definition | ★★☆ | 3 min |

**Q: How do you convince a team that has 200 E2E tests and 20 unit
tests to change their approach?**

A: Frame it as a business problem, not a technical preference.

Evidence to collect:
1. Current CI time - if 200 E2E tests take 40 minutes, every PR
   costs developers 40 minutes of wait time
2. Flaky test frequency - if 10% of builds fail due to E2E flakiness,
   engineers spend time re-running CI instead of reviewing code
3. Defect location - when a bug is found, can the test that catches
   it pinpoint the function, or does it say "checkout broke"?

Proposed change:
- Pick a specific validation module with 10 E2E tests
- Write 30 unit tests + 2 E2E tests instead
- Compare: test run time, flakiness rate, ability to identify bug location
- Show the result to the team as a concrete before/after

Don't advocate theory - show data. A 90% CI time reduction on one
module is more persuasive than any principle.

*What separates good from great:* Recognizing that the team wrote
200 E2E tests for a reason - probably because unit tests seemed
abstract or insufficient. Understanding and addressing that motivation
(add more integration-level tests, show that unit tests do catch bugs)
is more effective than just advocating the pyramid.
