---
layout: default
title: "Frontend Testing - L2 E2E Testing"
parent: "Frontend Testing"
nav_order: 5
permalink: /frontend-testing/l2-e2e-testing/
---

# Playwright Fundamentals

---

### 🎯 Model Answer

**30 seconds:**

> Playwright is a browser automation and E2E testing framework by
> Microsoft. It drives Chromium, Firefox, and WebKit from Node.js.
> Key API: `page.goto(url)`, `page.getByRole()`, `page.getByLabel()`,
> `page.fill()`, `page.click()`, `expect(page).toHaveURL()`. Built-in
> auto-waiting: every action and assertion waits for the element to be
> actionable. Fixtures provide page, browser, context. `test.describe`
> organizes tests. `playwright.config.ts` controls parallelism.

**3 minutes:**

Playwright's design around **auto-waiting** is what makes it reliable.
Unlike Selenium/WebDriver, you don't call explicit `wait()` or
`sleep()` - Playwright waits automatically:
- `click()` waits for the element to be attached, visible, stable
  (not animating), and enabled
- `fill()` waits for the element to be editable
- `expect(locator).toBeVisible()` retries until timeout

**Locators** are the query mechanism: `page.getByRole('button', {name: /submit/i})`,
`page.getByLabel('Email')`, `page.getByTestId('submit-btn')`. Locators
use the same accessibility-first priority as RTL.

**Browser contexts** provide isolated browser sessions. Each test gets
a fresh context by default (no cookie/storage sharing between tests).
Multiple contexts enable multi-user interaction testing (user A sends
a message, user B receives it).

**Network interception**: `page.route('/api/users', route => route.fulfill({...}))` intercepts HTTP requests. Playwright can also record
and replay network traffic.

**Blank Mind Recovery:**

**(1) Core pattern:** "page.goto -> locate with getByRole/getByLabel ->
fill/click -> expect assertions with auto-wait."

**(2) Auto-wait:** "No sleep() needed. Playwright waits for actionable.
Actions retry on timeout."

**(3) Isolation:** "Each test gets fresh browser context. Cookies,
storage, state don't leak between tests."

---

### 📘 Concept Explanation

**What it is:**

A cross-browser E2E testing framework that controls real browsers
(Chromium, Firefox, WebKit) with built-in auto-waiting, network
interception, and parallel test execution.

**The problem it solves:**

E2E tests that test the real user journey through the full stack -
frontend + API + database - catch integration failures that unit and
component tests miss. Playwright makes these tests reliable (no
explicit waits) and fast (parallel, isolated contexts).

**How it works:**

```
Playwright architecture:

  Test runner  <-> Playwright Node.js API
  Playwright Node.js <-> Browser DevTools Protocol (CDP/WebKit/Firefox)
  Browser DevTools Protocol <-> Browser

  Auto-waiting state machine (for actionable check):
    attached -> visible -> stable -> enabled -> receives events

  Locator types:
    page.getByRole('button', { name: /text/i })
    page.getByLabel('Field label')
    page.getByPlaceholder('Placeholder')
    page.getByText('Visible text')
    page.getByTestId('data-testid-value')
    page.locator('css-selector')  // last resort

  Assertion examples:
    await expect(page).toHaveURL('/dashboard');
    await expect(page).toHaveTitle(/Dashboard/);
    await expect(locator).toBeVisible();
    await expect(locator).toHaveText('Expected text');
    await expect(locator).toHaveValue('form value');
    await expect(locator).toBeEnabled();
    await expect(locator).toBeChecked();
    await expect(locator).toHaveCount(3);

  Network interception:
    await page.route('/api/**', async route => {
      const response = await route.fetch(); // real request
      const json = await response.json();
      json.extra = 'added field';
      await route.fulfill({ json }); // modified response
    });
    // Or mock entirely:
    await page.route('/api/users', route =>
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ id: 1, name: 'Alice' }]),
      })
    );
```

---

### 💻 Code Example

**Example (Production) - Complete Playwright test:**

```typescript
// playwright.config.ts
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  use: {
    baseURL: 'http://localhost:3000',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});

// e2e/auth.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Authentication', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
  });

  test('successful login redirects to dashboard', async ({ page }) => {
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('password123');
    await page.getByRole('button', { name: /log in/i }).click();

    // Auto-waits for navigation and URL change:
    await expect(page).toHaveURL('/dashboard');
    await expect(
      page.getByRole('heading', { name: /welcome/i })
    ).toBeVisible();
  });

  test('shows error for invalid credentials', async ({ page }) => {
    await page.getByLabel('Email').fill('wrong@example.com');
    await page.getByLabel('Password').fill('wrong');
    await page.getByRole('button', { name: /log in/i }).click();

    // Auto-waits for error to appear:
    await expect(
      page.getByRole('alert')
    ).toHaveText(/invalid credentials/i);
    // Still on login page:
    await expect(page).toHaveURL('/login');
  });
});

// Testing with network interception:
test('shows loading state while API responds', async ({ page }) => {
  // Delay API response to observe loading state:
  await page.route('/api/users', async route => {
    await new Promise(r => setTimeout(r, 500));
    await route.fulfill({
      json: [{ id: 1, name: 'Alice' }],
    });
  });

  await page.goto('/users');
  await expect(page.getByRole('progressbar')).toBeVisible();
  await expect(page.getByText('Alice')).toBeVisible();
});
```

> **Code walkthrough:** `playwright.config.ts` configures `webServer`
> to auto-start the dev server before tests and reuse it locally
> (not on CI, where it's always fresh). The `webServer.url` field
> makes Playwright wait until the server is ready before running tests.
> `page.getByLabel('Email')` finds the input associated with the
> "Email" label - the same accessibility-first query as RTL. No
> `await page.waitForSelector()` calls are needed because all actions
> auto-wait for the element to be actionable. `page.route()` intercepts
> the `/api/users` request and adds a 500ms delay to test loading state.

---

### ⚖️ Comparison Table

| Playwright feature | Alternative | Playwright advantage |
|---|---|---|
| Auto-waiting | Manual `waitFor*` | Zero flaky sleep() calls |
| Browser contexts | Cookie reset | Isolated per test, fast |
| Multi-browser | Choose one | Built-in Chromium/Firefox/WebKit |
| Network interception | Proxy server | In-process, no extra setup |
| Component testing | Cypress CT | Official React/Vue/Svelte support |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Playwright drives real browsers. I use `page.getByRole()` and
> `page.getByLabel()` to find elements, `fill()` and `click()` to
> interact, and `expect(locator).toBeVisible()` for assertions.
> Auto-waiting means I don't need sleep() calls - Playwright waits
> automatically.

**Senior / Staff:**

> Playwright's reliability comes from its auto-waiting model: every
> action has a built-in actionability check that retries until the
> element is visible, stable, enabled, and can receive events.
> This eliminates the largest category of E2E test flakiness: timing
> issues. I configure `screenshot: 'only-on-failure'` and
> `video: 'retain-on-failure'` for CI debugging. For tests that
> need authentication state, I use Playwright's `storageState` fixture
> to save and restore auth cookies rather than logging in before
> every test.

---

### ⚠️ Common Misconceptions

**Misconception: E2E tests should test every user scenario.**

E2E tests are slow (seconds per test) and brittle (depend on full
stack). They should cover critical user journeys (login, checkout,
key workflows), not every edge case. Edge cases belong in unit and
component tests. A typical ratio: 70% unit/component, 20% integration,
10% E2E (Testing Trophy).

---

### 🚨 Failure Modes and Diagnosis

**Failure: Playwright tests are flaky in CI but pass locally.**

Causes:
1. CI environment is slower - timeouts too short
2. Animation / transition timing differences
3. Network latency in full-stack tests

Fix:
- Increase global timeout: `use: { actionTimeout: 10_000 }`
- Disable animations: `use: { reducedMotion: 'reduce' }`
- Use `page.waitForLoadState('networkidle')` for network-heavy pages
- Run Playwright trace viewer on failed CI runs:
  `npx playwright show-trace trace.zip`

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is auto-waiting in Playwright? | Mechanism | ★★☆ | 2 min |
| What is a browser context and why does it matter? | Definition | ★★☆ | 2 min |
| How to intercept and mock API requests? | Scenario | ★★☆ | 2 min |
| Playwright test flaky in CI - how to debug? | Debugging | ★★★ | 3 min |
| How to reuse authentication state across tests? | Design | ★★★ | 3 min |
| Page Object Model pattern - how and why? | Design | ★★★ | 3 min |

**Q: What is the Page Object Model pattern in Playwright?**

A: Page Object Model (POM) encapsulates page interactions in classes,
making tests more readable and maintainable.

```typescript
// pages/LoginPage.ts
export class LoginPage {
  constructor(private page: Page) {}

  async goto() {
    await this.page.goto('/login');
  }

  async login(email: string, password: string) {
    await this.page.getByLabel('Email').fill(email);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', {name:/log in/i}).click();
  }

  async getErrorMessage() {
    return this.page.getByRole('alert').textContent();
  }
}

// e2e/auth.spec.ts
test('login', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login('user@example.com', 'password123');
  await expect(page).toHaveURL('/dashboard');
});
```

Benefits: If the login form HTML changes (label text, button text),
only `LoginPage.ts` needs to update - not every test that logs in.

---

# Cypress vs Playwright Decision

---

### 🎯 Model Answer

**30 seconds:**

> Playwright and Cypress are both E2E testing frameworks. Key
> differences: Playwright supports all browsers natively (Chromium,
> Firefox, WebKit) while Cypress added Firefox/Edge later and has no
> Safari. Playwright is faster (parallel by default, multiple browsers
> simultaneously). Cypress has a better developer experience - in-browser
> runner with time-travel debugging. Playwright is better for CI and
> cross-browser. Cypress is better for teams new to E2E testing.

**Blank Mind Recovery:**

**(1) Choose Playwright when:** "Multiple browsers required (Safari),
parallel execution needed, CI-first workflow, large test suites."

**(2) Choose Cypress when:** "Team new to E2E testing, great DX
matters, component testing in Cypress already in use."

**(3) Both are good:** "Wrong answer is no E2E tests. Prefer Playwright
for new projects in 2024+."

---

### 📘 Concept Explanation

**What it is:**

Two leading end-to-end testing frameworks for web applications, each
with different architectural decisions and tradeoffs.

**How they differ architecturally:**

```
Playwright architecture:
  Node.js -> Browser DevTools Protocol -> Browser process
  Tests run in Node.js, communicate with browser via CDP
  Multiple browsers, multiple tabs, multiple contexts in parallel
  Out-of-process: can test Chrome extensions, multiple domains

Cypress architecture:
  Tests run INSIDE the browser JavaScript environment
  Same origin as the app under test
  One browser at a time (by default)
  Iframe-based runner with time-travel (snapshots per command)
  cy.intercept() for network mocking (XHR and fetch)

Feature comparison:

  Feature              Playwright   Cypress
  -------              ----------   -------
  Safari/WebKit        Yes          No (Mac Chrome/Firefox only)
  Firefox              Yes          Yes
  Chromium/Chrome      Yes          Yes
  Parallel execution   Built-in     Needs Cloud (paid)
  Component testing    Experimental Mature (CT product)
  Time-travel debug    Trace Viewer In-browser time-travel
  API testing          Native       Plugin needed
  iframes              Supported    Limited
  Multiple tabs        Supported    No (single tab)
  Cross-origin frames  Supported    Limited (web security flag)
  Speed (CI)           Fast         Slower (single thread default)
  Learning curve       Medium       Low (great docs, DX)

When to choose Playwright:
  - Safari/WebKit testing required
  - Multiple browsers in same test needed
  - Speed matters (large test suite)
  - API testing alongside UI testing
  - Multi-tab or multi-window scenarios
  - New projects (2024+ community momentum)

When to choose Cypress:
  - Team already using Cypress (migration cost not worth it)
  - Component Testing with Cypress CT is desired
  - Great time-travel debugging experience is valued
  - Limited to Chromium/Firefox acceptable
```

---

### 💻 Code Example

**Example (Comparison) - Same test in both frameworks:**

```typescript
// Playwright version:
import { test, expect } from '@playwright/test';

test('user can add item to cart', async ({ page }) => {
  await page.goto('/products');
  await page.getByRole('button', {
    name: /add widget to cart/i
  }).click();

  await expect(
    page.getByRole('status', { name: /cart count/i })
  ).toHaveText('1');
});

// Cypress version:
describe('user can add item to cart', () => {
  it('adds item to cart', () => {
    cy.visit('/products');
    cy.findByRole('button', {name: /add widget to cart/i}).click();
    // Cypress is synchronous-looking (command queue)
    cy.findByRole('status', {name: /cart count/i})
      .should('have.text', '1');
  });
});

// Key syntax difference:
// Playwright: async/await, Promises, standard JS
// Cypress: synchronous-looking API (command queue), own assertion style

// Network mocking comparison:
// Playwright:
await page.route('/api/cart', route =>
  route.fulfill({ json: { count: 5 } })
);

// Cypress:
cy.intercept('/api/cart', { body: { count: 5 } });
```

> **Code walkthrough:** Both frameworks use accessibility-first queries
> (Playwright's `getByRole`, Cypress's `findByRole` via
> `@testing-library/cypress`). The syntax diverges: Playwright uses
> native async/await, reflecting its Node.js-first architecture.
> Cypress uses a command queue that looks synchronous but is internally
> chained. Cypress's `should` chains assertions onto the element query;
> Playwright uses separate `expect` calls. Network mocking uses
> `page.route()` vs `cy.intercept()` - similar capability, different API.

---

### ⚖️ Comparison Table

| Factor | Playwright | Cypress |
|---|---|---|
| Safari/WebKit | Yes | No |
| Parallelism | Built-in free | Paid Cloud |
| Architecture | Out-of-process | In-browser |
| API testing | Native | Plugin |
| Component testing | Experimental | Mature |
| DX / debugging | Trace Viewer | Time-travel |
| 2024 momentum | Growing | Established |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Playwright supports all browsers including Safari, runs tests in
> parallel, and is faster in CI. Cypress has better developer experience
> with its in-browser time-travel debugging. Both are good - I'd
> choose Playwright for new projects because of Safari support and
> built-in parallelism.

**Senior / Staff:**

> The architectural difference drives the capability difference:
> Playwright's out-of-process model lets it control multiple tabs,
> iframes, and cross-origin frames without the same-origin restrictions
> that affect Cypress. For teams testing Safari-critical applications
> or needing cross-browser coverage, Playwright is the only option
> with genuine WebKit support. For teams where E2E debugging UX
> matters most - junior engineers, complex user flows - Cypress's
> in-browser time-travel makes failures easier to diagnose. Migration
> cost must be weighed carefully; a mature Cypress suite is often
> worth maintaining rather than rewriting.

---

### ⚠️ Common Misconceptions

**Misconception: Cypress is "easier" so it's better for small teams.**

Cypress has better interactive debugging, but Playwright has better
documentation and the same accessibility-first query approach through
its built-in locators. Both have similar learning curves. The "easier"
advantage of Cypress applies primarily to teams already familiar with
it, not new adopters in 2024.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Cross-browser tests fail in Safari/WebKit but pass in Chrome.**

This is common with CSS features not supported in WebKit or with
APIs unavailable in older Safari versions.

Diagnose with Playwright:
```bash
npx playwright test --project=webkit --headed
# Run in headed mode to see the browser
npx playwright show-trace trace.zip
# View trace recording for failed test
```

Common WebKit issues: CSS grid, certain input types, service workers,
specific keyboard events differ from Chrome behavior.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| Playwright vs Cypress - key differences? | Comparison | ★★☆ | 3 min |
| When would you choose Cypress over Playwright? | Decision | ★★☆ | 2 min |
| Why does Playwright support more features than Cypress? | Mechanism | ★★★ | 3 min |
| How to decide which E2E framework to use? | Framework | ★★★ | 3 min |
| What is the Testing Trophy and how does it guide E2E test scope? | Design | ★★★ | 3 min |
| How do you handle auth in E2E tests for both frameworks? | Scenario | ★★★ | 3 min |

**Q: How do you handle authentication state in E2E tests efficiently?**

A: Re-logging in before every test is slow. Both frameworks provide
mechanisms to save and restore auth state.

**Playwright approach** - storageState:
```typescript
// playwright/global-setup.ts
async function globalSetup() {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('/login');
  await page.getByLabel('Email').fill(process.env.TEST_USER!);
  await page.getByLabel('Password').fill(process.env.TEST_PASS!);
  await page.getByRole('button', {name:/log in/i}).click();
  await page.waitForURL('/dashboard');
  // Save auth cookies/localStorage to file:
  await page.context().storageState({ path: 'auth.json' });
  await browser.close();
}

// playwright.config.ts:
// use: { storageState: 'auth.json' }
// Each test starts with saved auth state (no login needed)
```

**Cypress approach** - cy.session():
```typescript
Cypress.Commands.add('login', () => {
  cy.session('user', () => {
    cy.visit('/login');
    cy.get('[name=email]').type(Cypress.env('TEST_USER'));
    cy.get('[name=password]').type(Cypress.env('TEST_PASS'));
    cy.contains('button', 'Log in').click();
    cy.url().should('include', '/dashboard');
  });
});
// In tests: cy.login() - restores cached session on second run
```

*What separates good from great:* Using Playwright's `storageState`
with multiple user roles (admin.json, editor.json, viewer.json) so
each test can declaratively specify its auth context:
`test.use({ storageState: 'admin.json' })`. This eliminates per-test
login and makes role-based testing explicit.
