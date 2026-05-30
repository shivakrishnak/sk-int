---
layout: default
title: "Frontend Testing - L3 Advanced Testing"
parent: "Frontend Testing"
nav_order: 8
permalink: /frontend-testing/l3-advanced-testing/
render_with_liquid: false
---

# Visual Regression Testing (Chromatic, Percy)

---

### 🎯 Model Answer

**30 seconds:**

> Visual regression testing captures pixel-level screenshots of UI
> components and compares them to approved baselines. If pixels change,
> the test fails for human review. Chromatic (Storybook-native, captures
> component stories) and Percy (cross-framework, page/component
> screenshots) are the main SaaS providers. Applitools adds AI-based
> comparison. Use for design system stability and catching unintended
> CSS changes. Don't use for dynamic content, date-dependent UI,
> or animated components without stabilization.

**3 minutes:**

Visual regression testing addresses a class of bugs that functional
tests miss: a button still says "Submit" and is still clickable, but
it's now 20px to the left and using the wrong font. Functional tests
pass, users see a broken UI.

**How it works:**

1. CI captures screenshots of components/pages in a headless browser
2. Screenshots are compared pixel-by-pixel to a stored baseline
3. Differences above a threshold are flagged for human review
4. A reviewer approves or rejects the change

**Chromatic + Storybook integration**: Chromatic captures each
Storybook story as a visual test. When a PR changes CSS, Chromatic
shows exactly which stories changed and which pixels changed. A design
system with 200 stories gets 200 visual regression tests automatically.

**Threshold management**: Small differences (antialiasing, font
rendering differences between OS) are common. Providers offer:
- Pixel threshold (ignore differences < N pixels changed)
- Region masks (ignore dynamic content areas)
- Layout diffing (detect moved elements, not just pixel changes)

**Blank Mind Recovery:**

**(1) What it does:** "Screenshots current UI. Compares to baseline.
Flags pixel differences for human review."

**(2) When to use:** "Design systems. Component libraries. Stable
UI layouts. Release gates."

**(3) When to avoid:** "Dynamic content (dates, user data, animations).
High maintenance burden. Not a replacement for functional tests."

---

### 📘 Concept Explanation

**What it is:**

Automated pixel-level UI comparison that detects unintended visual
changes by comparing screenshots to approved baselines.

**The problem it solves:**

CSS regressions (layout shifts, color changes, font mismatches,
spacing errors) are invisible to functional tests. A refactored
flexbox layout may render all elements but in a different order.

**How it works:**

```
Visual regression testing workflow:

  Initial run (baseline creation):
    1. Component renders in headless browser
    2. Screenshot captured
    3. Stored as "approved baseline"

  Subsequent runs (comparison):
    1. Component renders with current code
    2. New screenshot captured
    3. Pixel-level diff computed
    4. If diff > threshold: flagged for review
    5. Reviewer: Approve (new baseline) or Reject (fix the code)

  Provider comparison:
    Chromatic:
      - Integrates with Storybook stories directly
      - Each story = automatic visual test
      - Cloud captures in real Chrome/Firefox
      - Snapshots captured in parallel (fast)
      - Turbosnap: only re-tests stories affected by changed files
      - Price: based on snapshot count per month

    Percy:
      - Framework-agnostic (works with Cypress, Playwright, Storybook)
      - @percy/playwright, @percy/cypress packages
      - Can capture full pages, not just component stories
      - Smart baselines per branch

    Applitools:
      - AI-based comparison (ignores intentional changes to fonts/colors)
      - More expensive, less false-positive noise
      - "Ultrafast Grid" for cross-browser

  CSS-in-JS and animation challenges:
    Animations must be disabled:
      prefers-reduced-motion: reduce in test environment
      Or: explicitly pause animations before screenshot

    Dynamic values must be masked:
      Dates, user IDs, random content -> mask before screenshot
      Percy: data-percy-hide attribute
      Chromatic: story parameters to disable dynamic content
```

---

### 💻 Code Example

**Example (Production) - Chromatic with Storybook:**

```typescript
// Component story (automatically becomes visual test in Chromatic):
// src/components/Button/Button.stories.tsx

import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta = {
  title: 'Components/Button',
  component: Button,
  parameters: {
    // Disable animations for stable visual snapshot:
    chromatic: { pauseAnimationAtEnd: true },
  },
} satisfies Meta<typeof Button>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: { label: 'Click me', variant: 'primary' },
};

export const Disabled: Story = {
  args: { label: 'Disabled', variant: 'primary', disabled: true },
};

export const Loading: Story = {
  args: { label: 'Loading', variant: 'primary', loading: true },
  parameters: {
    // Pause loading spinner at first frame:
    chromatic: { pauseAnimationAtEnd: true },
  },
};

// CI: npx chromatic --project-token=$CHROMATIC_PROJECT_TOKEN
// Chromatic captures each story, compares to approved baseline
// PR fails if visual changes are detected (for review)

// Percy with Playwright:
import { percySnapshot } from '@percy/playwright';

test('dashboard page visual snapshot', async ({ page }) => {
  await page.goto('/dashboard');
  await page.waitForLoadState('networkidle');

  // Mask dynamic content (timestamps, user-specific data):
  await page.evaluate(() => {
    document.querySelectorAll('[data-percy-hide]')
      .forEach(el => { (el as HTMLElement).style.visibility = 'hidden'; });
  });

  await percySnapshot(page, 'Dashboard - default state');
});
```

> **Code walkthrough:** Chromatic integrates with Storybook by
> capturing each exported story as a visual snapshot in the cloud.
> The `pauseAnimationAtEnd: true` parameter pauses CSS animations at
> their final state, preventing flaky snapshots from capturing
> mid-animation frames. Stories with loading states use this parameter
> to capture the spinner at a known position. Percy's
> `@percy/playwright` integration adds `percySnapshot()` calls to
> existing Playwright tests. The `data-percy-hide` pattern masks
> user-specific or time-based content that changes between runs.

---

### ⚖️ Comparison Table

| Tool | Integration | Best for | Cost model |
|---|---|---|---|
| Chromatic | Storybook-native | Component libraries | Per snapshot |
| Percy | Any framework | Full pages, mixed stack | Per snapshot |
| Applitools | Any framework | Low false positives | Per user/seat |
| reg-suit | Self-hosted | Avoiding SaaS cost | Free (infra cost) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Visual regression testing takes screenshots and compares them to a
> baseline. Chromatic integrates with Storybook - every component story
> becomes a visual test automatically. If a CSS change moves a button
> or changes a color, Chromatic flags it for review.

**Senior / Staff:**

> Visual regression testing is high-value for design systems and
> component libraries where unintended CSS changes are common and
> functional tests don't catch layout issues. The ROI question is
> maintenance vs value: a design system with 200 stories benefits from
> Chromatic significantly. An application with dynamic data-heavy
> pages has high screenshot noise (every run looks different) and low
> ROI. I gate visual testing on design system components and stable
> marketing/landing pages, not application dashboards with user data.

---

### ⚠️ Common Misconceptions

**Misconception: Visual regression testing replaces functional testing.**

Visual tests catch CSS regressions (broken layout, wrong color). They
don't test that forms submit, APIs are called, or error handling works.
Visual + functional tests are complementary. Visual testing is a
layer on top of functional testing, not a replacement.

---

### 🚨 Failure Modes and Diagnosis

**Failure: High volume of false-positive visual diffs in every build.**

Cause: Dynamic content in screenshots (dates, IDs, animations).

Fix:
1. Disable animations in test environment (prefers-reduced-motion)
2. Mask or hide dynamic content (data-percy-hide, Storybook decorators)
3. Use seed data that doesn't change (fixed timestamps, static fixtures)
4. Adjust pixel threshold to ignore antialiasing differences

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What does visual regression testing catch? | Definition | ★★☆ | 2 min |
| Chromatic vs Percy - when to use each? | Comparison | ★★☆ | 2 min |
| What causes false positive visual diffs? | Debugging | ★★☆ | 2 min |
| When is visual regression NOT worth it? | Trade-off | ★★☆ | 2 min |
| How to handle animations in visual tests? | Scenario | ★★☆ | 2 min |

**Q: Our design system team wants to add visual regression testing.
What would you recommend?**

A: Chromatic is the natural choice for a design system team using
Storybook. It requires no test code - every component story becomes
a visual test automatically.

Setup:
1. `npm install --save-dev chromatic`
2. `npx chromatic --project-token=TOKEN` in CI (GitHub Actions)
3. Review and approve baseline snapshots once
4. Future PRs that change component CSS: Chromatic shows exactly
   which stories changed and which pixels differ

Key configuration decisions:
- Enable Turbosnap to re-test only stories affected by changed files
  (reduces snapshot count and cost)
- Set `pauseAnimationAtEnd: true` globally for animation stability
- Create a branch review workflow: require Chromatic review to pass
  before merge (same as required status checks)

Cost management:
- Turbosnap limits snapshots to changed components
- Free tier covers ~5,000 snapshots/month
- Evaluate ROI: if design system is actively used by multiple teams,
  catching unintended CSS regressions is high value

---

# Accessibility Testing with axe-core

---

### 🎯 Model Answer

**30 seconds:**

> axe-core is an accessibility engine that checks rendered HTML against
> WCAG 2.1/2.2 rules. Integration: `@axe-core/react` (dev-time overlay),
> `jest-axe` (component tests), `@axe-core/playwright` (E2E). Run
> `await expect(page).toPassAxe()` or `const results = await axe(container)`
> and assert zero violations. Axe catches ~57% of accessibility issues
> automatically. It doesn't replace manual testing (keyboard navigation,
> screen reader testing).

**Blank Mind Recovery:**

**(1) Integration:** "jest-axe for component tests. @axe-core/playwright
for E2E. @axe-core/react for dev-mode overlay."

**(2) Usage:** "render component -> run axe() -> assert no violations."

**(3) Limitation:** "57% of a11y issues caught automatically. Still need
keyboard and screen reader testing."

---

### 📘 Concept Explanation

**What it is:**

An accessibility rules engine that analyzes rendered HTML and reports
WCAG guideline violations, used in automated testing pipelines.

**The problem it solves:**

Accessibility violations (missing ARIA labels, color contrast failures,
form labels disconnected from inputs) are invisible to functional tests
and easy to miss in code review. Automated axe checks catch a
significant portion of violations before they reach production.

**How it works:**

```
axe-core analysis:

  1. Takes rendered DOM
  2. Runs 100+ rules based on WCAG 2.1/2.2, Section 508, and best practices
  3. Reports: violations (failures), passes, incomplete (needs human)

  Rule categories:
    critical:    Prevents access entirely (missing form labels)
    serious:     Significant barrier (low contrast)
    moderate:    Partial barrier (missing landmark regions)
    minor:       Best practice (redundant alt text)

  WCAG levels:
    A:   Must fix (most impactful)
    AA:  Required for legal compliance (WCAG 2.1 AA)
    AAA: Optional (enhanced)

  What axe catches automatically:
    - Images missing alt text
    - Form inputs without labels
    - Buttons without accessible names
    - Color contrast failures (4.5:1 for text, 3:1 for large text)
    - Missing page language (lang attribute)
    - Empty heading elements
    - ARIA roles used incorrectly

  What axe CANNOT catch:
    - Logical reading order
    - Meaningful link text ("click here" problem)
    - Focus management in dynamic interactions
    - Screen reader announcement quality
    - Keyboard trap diagnosis (can detect some)

  Integration points:
    jest-axe:
      import { axe, toHaveNoViolations } from 'jest-axe';
      expect.extend(toHaveNoViolations);

    @axe-core/playwright:
      import { checkA11y } from 'axe-playwright';
      await checkA11y(page, undefined, { detailedReport: true });

    @axe-core/react (dev tool):
      import ReactDOM from 'react-dom';
      import axe from '@axe-core/react';
      if (process.env.NODE_ENV !== 'production') {
        axe(React, ReactDOM, 1000); // overlay in browser dev mode
      }
```

---

### 💻 Code Example

**Example (Wrong vs Right) - Common accessibility violations:**

```typescript
// BAD: common accessibility violations
function LoginForm() {
  return (
    <form>
      {/* Missing label: input has no accessible name */}
      <input type="email" placeholder="Email" />
      {/* Button with no text: accessible name is empty */}
      <button>
        <img src="arrow.png" /> {/* No alt text */}
      </button>
      {/* Color contrast < 4.5:1 ratio */}
      <div style={{ color: '#999', backgroundColor: '#fff' }}>
        Error message
      </div>
    </form>
  );
}

// GOOD: accessibility-first markup
function LoginForm() {
  return (
    <form aria-label="Login">
      {/* Input associated with label via id/htmlFor */}
      <label htmlFor="email">Email address</label>
      <input type="email" id="email" />
      {/* Button with accessible name via aria-label */}
      <button aria-label="Submit login form">
        <img src="arrow.png" alt="" aria-hidden="true" />
      </button>
      {/* WCAG AA contrast: 4.5:1 minimum */}
      <div style={{ color: '#666', backgroundColor: '#fff' }}
           role="alert">
        Error message
      </div>
    </form>
  );
}

// Automated test with jest-axe:
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';
expect.extend(toHaveNoViolations);

test('LoginForm has no accessibility violations', async () => {
  const { container } = render(<LoginForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
  // If violations exist, output includes:
  // - Rule ID (e.g., 'label', 'color-contrast')
  // - Impact (critical, serious, moderate, minor)
  // - Help URL with explanation
  // - HTML element that violated the rule
});

// With Playwright (E2E level):
import { checkA11y, injectAxe } from 'axe-playwright';

test('login page passes axe', async ({ page }) => {
  await page.goto('/login');
  await injectAxe(page);
  await checkA11y(page, undefined, {
    detailedReport: true,
    detailedReportOptions: { html: true },
    // Only check critical and serious violations:
    runOnly: {
      type: 'tag',
      values: ['wcag2a', 'wcag2aa'],
    },
  });
});
```

> **Code walkthrough:** The BAD example has three violations: an input
> with no associated label (critical - screen readers can't announce
> the field's purpose), a button with no accessible name (critical),
> and an image with no alt text (serious). The GOOD example uses
> `htmlFor`/`id` to associate the label with the input, adds `aria-label`
> to the submit button, and marks the decorative arrow icon with
> `alt=""` + `aria-hidden="true"` (decorative images should be hidden
> from screen readers). The jest-axe test catches all three violations
> automatically and outputs the rule ID, impact level, and a link to
> the WCAG documentation for the violation.

---

### ⚖️ Comparison Table

| Integration | Layer | Runs when | Coverage |
|---|---|---|---|
| `@axe-core/react` | Dev tool | Browser dev mode | Full app in browser |
| `jest-axe` | Component test | CI unit tests | Component output |
| `@axe-core/playwright` | E2E test | CI E2E tests | Full rendered page |
| `@axe-core/puppeteer` | E2E test | CI E2E tests | Full rendered page |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I add `jest-axe` to component tests: `const results = await axe(container); expect(results).toHaveNoViolations()`. This catches missing
> labels, contrast violations, and ARIA errors automatically. It
> doesn't catch everything - I still test keyboard navigation manually.

**Senior / Staff:**

> Automated axe testing is the floor, not the ceiling. axe catches
> ~57% of WCAG violations that can be determined programmatically.
> It doesn't catch focus management issues, logical reading order,
> keyboard traps in complex interactions, or screen reader announcement
> quality. My accessibility testing layers: axe in component tests
> (catches markup violations), axe in E2E (catches full-page context
> violations), manual keyboard testing (tab order, focus visibility,
> modals trapping focus), and periodic screen reader testing with
> NVDA/VoiceOver for critical flows.

---

### ⚠️ Common Misconceptions

**Misconception: Passing axe means the app is accessible.**

axe catches structural violations (missing labels, contrast, ARIA).
It cannot detect: incorrect reading order, confusing language, focus
management bugs, keyboard traps in complex widgets, or screen reader
announcement issues. Passing axe is necessary but not sufficient.

---

### 🚨 Failure Modes and Diagnosis

**Failure: axe violations in CI but component looks correct.**

Common: `color-contrast` violation - CSS computed contrast fails
axe's WCAG AA threshold.

Diagnose: axe output includes the element HTML and the contrast
values it computed. Check: is the color inherited from a parent
element with a background that axe doesn't see?

Fix: Ensure text color meets 4.5:1 contrast against its actual
background in all states (hover, focus, disabled).

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What does axe-core check? | Definition | ★★☆ | 2 min |
| What can't automated tools check for a11y? | Limitation | ★★☆ | 2 min |
| How to add axe to a component test suite? | Scenario | ★★☆ | 2 min |
| What is WCAG AA? | Definition | ★★☆ | 2 min |
| Passing axe = accessible? | Critical thinking | ★★★ | 3 min |

**Q: How would you build a comprehensive accessibility testing
strategy for a React application?**

A: Layered approach - automated catches the majority, manual covers
the rest.

**Layer 1 - Dev-time (zero-cost, instant feedback):**
```typescript
// Add @axe-core/react in development mode only:
// Overlays violations directly in the browser
if (process.env.NODE_ENV !== 'production') {
  import('@axe-core/react').then(({ default: axe }) => {
    axe(React, ReactDOM, 1000);
  });
}
```

**Layer 2 - Component tests (CI, per PR):**
```typescript
// Every component test file adds:
test('has no a11y violations', async () => {
  const { container } = render(<MyComponent />);
  expect(await axe(container)).toHaveNoViolations();
});
```

**Layer 3 - E2E tests (CI, key pages):**
```typescript
// Run axe on login, signup, dashboard, checkout pages
```

**Layer 4 - Manual testing (sprint cadence):**
- Keyboard navigation (Tab, Shift+Tab, Enter, Escape, Arrow keys)
- Focus visible on all interactive elements
- Modal trapping focus
- Screen reader testing: VoiceOver (Mac/iOS), NVDA (Windows)
  on critical flows (login, checkout, form completion)

*What separates good from great:* Including accessibility acceptance
criteria in definition-of-done: "New components must pass axe with
zero violations and be keyboard-navigable." This makes accessibility
a shipping requirement, not an afterthought audit.
