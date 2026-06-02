---
layout: default
title: "Frontend Testing - L1 Component Testing"
parent: "Frontend Testing"
nav_order: 3
permalink: /frontend-testing/l1-component-testing/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [React Testing Library Philosophy](#react-testing-library-philosophy) | medium |
| 2 | [Querying and Asserting DOM Elements](#querying-and-asserting-dom-elements) | medium |
| 3 | [User Interaction and Event Testing](#user-interaction-and-event-testing) | medium |

---

# React Testing Library Philosophy

---

### 🎯 Model Answer

**30 seconds:**

> React Testing Library (RTL) philosophy: test components the way
> users interact with them, not the way they are implemented. Query
> the DOM by accessible role, label text, or visible text - not by
> CSS class, component name, or internal state. This makes tests
> resilient to refactoring (implementation can change; behavior must
> not). The guiding principle: "The more your tests resemble the way
> your software is used, the more confidence they can give you."

**3 minutes:**

RTL was created as a reaction to Enzyme's shallow rendering and
implementation-detail testing. The key differences:

**Enzyme (old approach)**: shallow render + access internal state and
props directly. Tests break when you refactor the implementation.
Tests don't break when you change user-visible behavior.

**RTL (current standard)**: full render + query by what users see and
interact with. Tests are resilient to implementation changes. Tests
break exactly when behavior changes.

The "priority" of RTL queries, from most to least preferred:
1. `getByRole` - accessible role (button, textbox, heading)
2. `getByLabelText` - form label text
3. `getByPlaceholderText` - input placeholder
4. `getByText` - visible text content
5. `getByDisplayValue` - form field current value
6. `getByAltText` - image alt text
7. `getByTitle` - title attribute
8. `getByTestId` - data-testid (last resort)

This priority reflects how users and assistive technologies interact
with the page. Tests that query by `getByRole('button', { name: /submit/i })`
describe what a screen reader user would experience.

**Blank Mind Recovery:**

**(1) Philosophy:** "Test behavior, not implementation. Query like a
user, not like a developer."

**(2) Query priority:** "Role > Label > Placeholder > Text > TestId
(last resort)."

**(3) Why:** "Tests that query by CSS class break on refactor.
Tests that query by role break when behavior changes. Only the second
is correct behavior."

---

### 📘 Concept Explanation

**What it is:**

A React testing library built on the principle that tests should
verify user behavior, not implementation details - making tests
resilient to refactoring.

**The problem it solves:**

Tests that access internal component state or query by CSS class
become a maintenance burden: they fail when code is refactored even
if behavior is unchanged, and they don't catch regressions that users
would notice.

**How it works:**

```
RTL rendering model:

  render(<Component />) renders the full component tree into JSDOM
  No shallow rendering - child components render too
  No access to component instance, state, or props directly
  Access only through the DOM (what users see)

  The DOM is the contract:
    - User sees "Submit" button -> getByRole('button', {name:/submit/i})
    - User sees "Email" label  -> getByLabelText(/email/i)
    - User sees error message  -> getByText(/invalid email/i)

Query semantics by role:
  Common ARIA roles:
    button, link, textbox, checkbox, radio, combobox, listbox,
    option, menuitem, heading, img, list, listitem, dialog,
    alert, status, progressbar

  getByRole('button', { name: /submit/i })
    -> finds a button accessible name matching 'submit'
    -> accessible name can be: text content, aria-label,
       aria-labelledby, title

  getByLabelText('Email')
    -> finds input associated with label "Email"
    -> works with: <label> for= attribute, aria-label,
       aria-labelledby, placeholder
```

> **Code walkthrough:** This React Testing Library Philosophy example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Wrong vs Right) - RTL vs implementation detail testing:**


```typescript
// BAD: using any defeats type safety
```

```typescript
// BAD: Enzyme-style - tests implementation details
import { shallow } from 'enzyme';

test('LoginForm renders email input', () => {
  const wrapper = shallow(<LoginForm />);
  // Accesses CSS class - breaks if class is renamed/removed:
  expect(wrapper.find('.email-input').exists()).toBe(true);
  // Accesses internal state - implementation detail:
  expect(wrapper.state('email')).toBe('');
  // Calls internal method directly:
  wrapper.instance().handleEmailChange('test@example.com');
  expect(wrapper.state('email')).toBe('test@example.com');
});

// GOOD: RTL - tests user-visible behavior
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('LoginForm shows email field', () => {
  render(<LoginForm />);
  // Finds by label - works regardless of CSS class or structure:
  const emailInput = screen.getByLabelText(/email/i);
  expect(emailInput).toBeInTheDocument();
});

test('LoginForm updates email field when user types', async () => {
  const user = userEvent.setup();
  render(<LoginForm />);

  const emailInput = screen.getByLabelText(/email/i);
  await user.type(emailInput, 'alice@example.com');

  // Assert what the user sees - the value in the input:
  expect(emailInput).toHaveValue('alice@example.com');
  // Not: expect(component.state.email).toBe(...)
});
```

> **Code walkthrough:** The Enzyme approach queries by CSS class andice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> accesses internal state - both are implementation details. If the
> class is renamed or the component is refactored to use hooks instead
> of class state, the tests break even though the user-visible behavior
> is identical. The RTL approach queries by the form label text (which
> is what a user or screen reader sees) and asserts the input's visible
> value. Refactoring the component from class to function, changing
> state management, or renaming CSS classes doesn't break the test.

---

### ⚖️ Comparison Table

| RTL query | Priority | Works with |
|---|---|---|
| `getByRole` | Highest | ARIA roles, accessible names |
| `getByLabelText` | High | Form labels, aria-label |
| `getByPlaceholderText` | Medium | Input placeholders |
| `getByText` | Medium | Visible text content |
| `getByTestId` | Lowest | `data-testid` attributes |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> RTL is about testing what the user sees and does, not what's inside
> the component. I query by role and label text instead of CSS classes
> or internal state. This makes tests more resilient to refactoring.

**Senior / Staff:**

> RTL's philosophy is that tests should serve as documentation of
> user behavior. `getByRole('button', { name: /submit/i })` reads as:
> "there should be a button that a user or screen reader would identify
> as 'submit'." This test fails when the button is removed, hidden, or
> relabeled - exactly when it should. It doesn't fail when the button's
> CSS changes, the onClick handler is refactored, or state management
> is switched from useState to Redux. That's the right failure mode.

---

### ⚠️ Common Misconceptions

**Misconception: RTL discourages all use of `data-testid`.**

RTL recommends `data-testid` as a last resort for elements with no
accessible role or text. Interactive elements (buttons, inputs, links)
should always be queried by role or label. For decorative elements
without accessible attributes, `data-testid` is appropriate.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Tests pass but component has broken accessibility.**

Symptom: Button queried with `getByTestId('submit-btn')` instead of
`getByRole('button', { name: /submit/i })`. The button loses its
accessible name and screen readers can't identify it.

Fix: Use `getByRole` queries - if the query fails to find the element,
the accessibility attribute is missing, prompting you to fix the
component.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is RTL's testing philosophy? | Definition | ★★☆ | 2 min |
| RTL query priority order | Definition | ★★☆ | 2 min |
| Why avoid `data-testid` as primary query? | Trade-off | ★★☆ | 2 min |
| Enzyme vs RTL - philosophy difference | Comparison | ★★☆ | 2 min |
| How does querying by role relate to a11y? | Mechanism | ★★★ | 3 min |

**Q: Why is testing by role better than testing by CSS class or
data-testid?**

A: Testing by role directly reflects how users and assistive
technologies navigate the application.

When you use `getByRole('button', { name: /submit/i })`:
- The test verifies the element is semantically a button (not a div
  with an onClick)
- The test verifies the element has an accessible name "submit"
- Screen readers announce: "submit, button" - exactly what is tested
- The test fails if the button's role or accessible name changes

When you use `getByTestId('submit-btn')`:
- The test verifies a `data-testid` attribute exists
- The element could be a div with no role, no accessible name
- The test passes even if the element is inaccessible
- Screen readers may not identify it at all

Testing by role functions as a free accessibility check: if
`getByRole` can find the element, it has the correct semantic role
and accessible name. Tests that pass are also accessible.

*What separates good from great:* Using RTL's `logRoles()` helper to
debug what roles are available in a rendered component:
```typescript
import { logRoles } from '@testing-library/dom';
const { container } = render(<MyComponent />);
logRoles(container); // prints all accessible elements and their roles
```

> **Code walkthrough:** This Unknown example demonstrates TypeScript pattern using container. **KEY MECHANISM:** TypeScript compiles to JavaScript; type information is erased at runtime. **WHY IT MATTERS:** type assertions bypass the type checker - a runtime error can still occur. **TAKEAWAY: prefer type guards over type assertions for safe narrowing of union types.**

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


# Querying and Asserting DOM Elements

---

### 🎯 Model Answer

**30 seconds:**

> RTL provides three query prefix variants: `getBy*` (throws if not
> found), `queryBy*` (returns null), `findBy*` (async, waits). Combined
> with selectors: ByRole, ByLabelText, ByText, ByPlaceholderText,
> ByAltText, ByTitle, ByTestId. Use `screen` object (not destructured
> from render) for queries. `@testing-library/jest-dom` adds matchers:
> `toBeInTheDocument`, `toBeVisible`, `toHaveValue`, `toBeDisabled`.

**Blank Mind Recovery:**

**(1) Three prefixes:** "get = throws. query = null. find = async."

**(2) Assertion package:** "@testing-library/jest-dom: toBeInTheDocument,
toBeVisible, toHaveValue, toBeDisabled."

---

### 📘 Concept Explanation

**What it is:**

RTL's query API for selecting DOM elements in tests, paired with
custom jest-dom matchers for asserting DOM state.

**How it works:**

```
Query matrix (prefix x selector):

  Prefix:
    getBy*     -> throws TestingLibraryElementError if not found
    queryBy*   -> returns null if not found
    findBy*    -> returns Promise, retries for timeout (default 1s)
    getAllBy*   -> throws if none found, returns array
    queryAllBy* -> returns empty array if none found
    findAllBy* -> returns Promise for array

  Selector:
    ByRole(role, options)
    ByLabelText(text)
    ByPlaceholderText(text)
    ByText(text)
    ByDisplayValue(value)  // current form field value
    ByAltText(text)        // image alt
    ByTitle(text)          // title attribute
    ByTestId(id)           // data-testid

Common combinations:
  screen.getByRole('button', { name: /submit/i })
  screen.getByLabelText('Email address')
  screen.getByText('Loading...')
  screen.queryByText('Error message')  // check absence
  await screen.findByText('Success!')  // wait for element

jest-dom matchers (from @testing-library/jest-dom):
  toBeInTheDocument()   // element is in DOM
  toBeVisible()         // element is visible to user
  toBeEnabled()         // form control is enabled
  toBeDisabled()        // form control is disabled
  toHaveValue(val)      // input/select has value
  toHaveTextContent(text) // element has text content
  toHaveClass(cls)      // element has CSS class
  toHaveFocus()         // element is focused
  toBeChecked()         // checkbox/radio is checked
  toBeRequired()        // form control is required
```

> **Code walkthrough:** This Querying and Asserting DOM Elements example demonstrates a key concept in practice using async/await. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Production) - Complete query and assertion patterns:**

```typescript
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';

test('form renders correctly and handles validation', async () => {
  render(<ContactForm />);

  // Assert presence (getBy - throws if absent):
  expect(screen.getByRole('heading', { name: /contact us/i }))
    .toBeInTheDocument();

  const emailInput = screen.getByLabelText(/email/i);
  expect(emailInput).toBeEnabled();
  expect(emailInput).not.toBeRequired(); // or toBeRequired()

  // Assert absence (queryBy - returns null, doesn't throw):
  expect(screen.queryByText(/invalid email/i))
    .not.toBeInTheDocument();

  // Submit button state:
  const submitBtn = screen.getByRole('button', { name: /submit/i });
  expect(submitBtn).toBeEnabled();

  // After submitting empty form (interaction test - next section):
  // await user.click(submitBtn);
  // const errorMsg = await screen.findByText(/email is required/i);
  // expect(errorMsg).toBeVisible();
});

// Checking visibility vs presence:
test('tooltip shows on hover', async () => {
  render(<HoverCard text="Help text" />);

  // Tooltip may be in DOM but hidden:
  const tooltip = screen.queryByRole('tooltip');
  if (tooltip) {
    expect(tooltip).not.toBeVisible(); // in DOM but hidden
  }

  // After hover:
  // await user.hover(screen.getByText('?'));
  // expect(screen.getByRole('tooltip')).toBeVisible();
});
```

> **Code walkthrough:** `getByRole` is the preferred query forice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> interactive elements because it verifies accessible semantics.
> `queryByText` returns null (instead of throwing) making it correct
> for asserting element absence. `toBeInTheDocument` vs `toBeVisible`:
> an element can be in the DOM but hidden via CSS (`display: none`,
> `visibility: hidden`). `toBeVisible` checks that the element is
> actually visible to the user, not just present in the HTML.

---

### ⚖️ Comparison Table

| Query prefix | Returns | Use for |
|---|---|---|
| `getBy*` | Element or throws | Element should exist |
| `queryBy*` | Element or null | Testing absence |
| `findBy*` | Promise | Element appears asynchronously |
| `getAllBy*` | Array or throws | Multiple elements |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `getBy*` throws if the element isn't found. `queryBy*` returns null
> - I use it for asserting something is NOT in the DOM. `findBy*` is
> async and waits for the element to appear. `@testing-library/jest-dom`
> adds matchers like `toBeInTheDocument` and `toHaveValue`.

**Senior / Staff:**

> The three query prefix variants map to three intent signals: `getBy`
> = "this element must exist" (throw if not), `queryBy` = "this element
> may or may not exist" (null if not), `findBy` = "this element will
> appear after an async operation" (wait for it). Choosing the wrong
> prefix hides bugs: `queryBy` for an element that should always exist
> returns null without failing the test if the element is missing.

---

### ⚠️ Common Misconceptions

**Misconception: `toBeInTheDocument` and `toBeVisible` are equivalent.**

`toBeInTheDocument` checks the element is in the DOM. An element can
be in the DOM but invisible (display: none, visibility: hidden,
opacity: 0, or a parent is hidden). `toBeVisible` checks the full
chain of visibility. Use `toBeVisible` when testing that users can
see an element, `toBeInTheDocument` when testing that it's rendered
at all.

---

### 🚨 Failure Modes and Diagnosis

**Failure: `getByRole` cannot find a button that clearly exists.**

Cause: Button has no accessible name (no text content, no aria-label).
A `<button><img src="..." /></button>` with no alt text has no name.

Diagnose:
```typescript
import { logRoles } from '@testing-library/dom';
const { container } = render(<MyComponent />);
logRoles(container); // shows all accessible elements
// or:
screen.debug(); // prints the current DOM state
```

> **Code walkthrough:** This Querying and Asserting DOM Elements example demonstrates TypeScript pattern using container. **KEY MECHANISM:** TypeScript compiles to JavaScript; type information is erased at runtime. **WHY IT MATTERS:** type assertions bypass the type checker - a runtime error can still occur. **TAKEAWAY: prefer type guards over type assertions for safe narrowing of union types.**

Fix: Add `aria-label` to icon buttons: `<button aria-label="Submit">`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| `getBy*` vs `queryBy*` vs `findBy*` | Comparison | ★★☆ | 2 min |
| How to assert an element is NOT present | Scenario | ★★☆ | 1 min |
| `toBeInTheDocument` vs `toBeVisible` | Comparison | ★★☆ | 2 min |
| Why can't `getByRole` find my button? | Debugging | ★★☆ | 2 min |
| What does `screen.debug()` output? | Mechanism | ★☆☆ | 1 min |

**Q: How would you test that an error message does NOT appear on
initial render but appears after form submission?**

A:
```typescript
test('error appears after submission, not on load', async () => {
  const user = userEvent.setup();
  render(<EmailForm />);

  // Assert absence on initial render (queryBy returns null):
  expect(screen.queryByText(/email is required/i))
    .not.toBeInTheDocument();

  // Submit the form without filling it:
  await user.click(screen.getByRole('button', { name: /submit/i }));

  // Assert presence after submission (findBy waits for async):
  const error = await screen.findByText(/email is required/i);
  expect(error).toBeVisible();
});
```

> **Code walkthrough:** This Unknown example demonstrates TypeScript pattern using async/await. **KEY MECHANISM:** TypeScript compiles to JavaScript; type information is erased at runtime. **WHY IT MATTERS:** type assertions bypass the type checker - a runtime error can still occur. **TAKEAWAY: prefer type guards over type assertions for safe narrowing of union types.**

Key: use `queryBy` for "should not be there" + use `findBy` for
"should appear after async operation."

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


# User Interaction and Event Testing

---

### 🎯 Model Answer

**30 seconds:**

> User interactions in RTL use `@testing-library/user-event` package,
> not `fireEvent`. `userEvent.setup()` creates a session that simulates
> real browser events: `user.click()` fires mousedown/mouseup/click.
> `user.type()` fires keydown/keypress/input/keyup for each character.
> `user.keyboard()` for keyboard shortcuts. `fireEvent` fires a single
> synthetic event - use only when `userEvent` is insufficient.

**3 minutes:**

The distinction between `userEvent` and `fireEvent` is important:

`fireEvent.click(element)` fires a single synthetic click event.
It doesn't simulate mousedown, doesn't move focus, doesn't trigger
hover effects. It's like calling `element.dispatchEvent(new MouseEvent('click'))`.

`userEvent.click(element)` (from `@testing-library/user-event`) fires
the full sequence: mouseover, mouseenter, mousemove, mousedown, focus,
mouseup, click. This matches what happens in a real browser.

For most tests, this distinction doesn't matter. For tests involving:
- Focus management (tab order, focus traps)
- Hover effects
- Form validation on blur
- Complex keyboard interactions (dropdowns, modals)

`userEvent` gives more realistic behavior and catches bugs that
`fireEvent` misses.

**`userEvent.setup()` vs `userEvent` directly**: The v14+ API requires
calling `userEvent.setup()` to get a `user` instance. This allows
configuration (delay, pointerEventsCheck) and correctly handles event
ordering across multiple interactions.

**Blank Mind Recovery:**

**(1) Two APIs:** "userEvent (realistic, full event sequence). fireEvent
(single synthetic event). Use userEvent always unless there's a reason."

**(2) Setup pattern:** "const user = userEvent.setup(); await user.click()."

**(3) Common interactions:** "type(), click(), keyboard(), selectOptions(),
clear(), tab(), hover()."

---

### 📘 Concept Explanation

**What it is:**

RTL's approach to simulating user interactions - clicking, typing,
tabbing, and keyboard input - in a way that reflects real browser
behavior.

**How it works:**

```
userEvent interaction sequence for click():
  mouseover -> mouseenter -> mousemove
  -> mousedown -> focus (if focusable)
  -> mouseup -> click

userEvent interaction sequence for type():
  For each character 'a':
    keydown(a) -> keypress(a) -> input(a) -> keyup(a)
  Also handles: paste, cut, special keys (Enter, Tab, Backspace)

Common userEvent methods:
  user.click(element)
  user.dblClick(element)
  user.type(element, 'text')     // type text character by character
  user.keyboard('{Enter}')       // keyboard shortcut/special key
  user.keyboard('[ShiftLeft]')   // low-level key simulation
  user.clear(element)            // clear input
  user.selectOptions(select, 'value')  // select option in <select>
  user.upload(input, file)       // file input
  user.tab()                     // Tab key (focus navigation)
  user.hover(element)            // mouse hover
  user.unhover(element)          // mouse leave

Pointer events check:
  userEvent by default checks pointer-events CSS property
  If an element has pointer-events: none, user.click() throws
  Useful: catches accidentally disabled click handlers
  Configure: userEvent.setup({ pointerEventsCheck: 0 }) to disable
```

> **Code walkthrough:** This User Interaction and Event Testing example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Wrong vs Right) - userEvent vs fireEvent:**


```typescript
// BAD: using any defeats type safety
```

```typescript
// BAD: fireEvent misses validation-on-blur behavior
import { fireEvent } from '@testing-library/react';

test('shows error after email blur', () => {
  render(<EmailInput />);
  const input = screen.getByLabelText(/email/i);

  fireEvent.change(input, { target: { value: 'invalid' } });
  fireEvent.blur(input); // fire blur event

  // May not trigger validation depending on implementation:
  // If validation uses onBlur handler, this might work
  // If validation uses FocusEvent details, fireEvent may miss them
  expect(screen.getByText(/invalid email/i)).toBeInTheDocument();
});

// GOOD: userEvent.type() automatically triggers blur on Tab
import userEvent from '@testing-library/user-event';

test('shows error after email blur', async () => {
  const user = userEvent.setup();
  render(<EmailInput />);

  const input = screen.getByLabelText(/email/i);
  await user.type(input, 'invalid');
  await user.tab(); // moves focus away, triggers blur realistically

  await screen.findByText(/invalid email/i);
});

// Complete form interaction test:
test('submits form with valid data', async () => {
  const user = userEvent.setup();
  const handleSubmit = jest.fn();
  render(<ContactForm onSubmit={handleSubmit} />);

  // Fill in form fields:
  await user.type(
    screen.getByLabelText(/name/i),
    'Alice Smith'
  );
  await user.type(
    screen.getByLabelText(/email/i),
    'alice@example.com'
  );
  await user.selectOptions(
    screen.getByLabelText(/subject/i),
    'Support'
  );

  // Submit:
  await user.click(screen.getByRole('button', { name: /submit/i }));

  // Assert callback was called with correct data:
  expect(handleSubmit).toHaveBeenCalledWith({
    name: 'Alice Smith',
    email: 'alice@example.com',
    subject: 'Support',
  });
});
```

> **Code walkthrough:** `userEvent.type()` dispatches individualice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `keydown/keypress/input/keyup` events for each character, plus
> handles the input's `value` update and cursor position. `user.tab()`
> triggers the full focus change sequence including blur on the current
> element and focus on the next focusable element. This realistic event
> sequence is needed when testing components that rely on `onBlur`
> validation, focus management, or keyboard event handlers. The form
> submission test demonstrates the full user journey: fill fields,
> select dropdown, submit, assert callback was called with the correct
> data.

---

### ⚖️ Comparison Table

| API | Event fidelity | Speed | Use for |
|---|---|---|---|
| `userEvent` | High (browser-like) | Slower (await) | Most interactions |
| `fireEvent` | Low (single event) | Fast (sync) | Edge cases, performance |
| Direct DOM | Lowest | Fastest | Almost never |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I use `userEvent` from `@testing-library/user-event` for interactions
> because it fires realistic browser events. `const user = userEvent.setup()`
> then `await user.type(input, 'text')` and `await user.click(btn)`.
> `fireEvent` fires a single event - `userEvent` fires the full sequence.

**Senior / Staff:**

> The distinction between `userEvent` and `fireEvent` matters for
> components that react to specific event sequences - blur handlers,
> focus traps, pointer events. `userEvent` is the default because it
> fires the same event sequence as a real browser. For testing that a
> modal traps focus correctly (Tab doesn't escape the dialog), `user.tab()`
> is essential - `fireEvent.keyDown` with Tab would not trigger the
> focus management code in the same way.

---

### ⚠️ Common Misconceptions

**Misconception: `userEvent.type()` is slower than `fireEvent.change()`.**

`userEvent.type()` fires more events per character (keydown, keypress,
input, keyup). For a test typing 50 characters, this is hundreds of
events. For 99% of tests this is imperceptibly fast. Only in very
large test suites with many long typing sequences does this matter -
and the solution is shorter test inputs (`'ab'` not `'alice@example.com'`).

---

### 🚨 Failure Modes and Diagnosis

**Failure: `user.click()` throws "Unable to click" error.**

Symptom: `TestingLibraryElementError: unable to fire pointer event`

Cause: Element has `pointer-events: none` in CSS, or is covered by
another element.

Diagnose: `screen.debug()` to see element state. Check CSS for
`pointer-events: none`. Check if element is behind an overlay.

Fix: Fix the CSS or interaction logic. If testing a known pointer-events:none
element intentionally: `userEvent.setup({ pointerEventsCheck: 0 })`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| `userEvent` vs `fireEvent` - when to use each? | Comparison | ★★☆ | 2 min |
| How to test keyboard navigation? | Scenario | ★★☆ | 2 min |
| How to test file upload? | Scenario | ★★☆ | 2 min |
| How to test dropdown selection? | Scenario | ★★☆ | 2 min |
| `userEvent.setup()` - why is it needed? | Mechanism | ★★☆ | 1 min |

**Q: How would you test that a dropdown closes when Escape is pressed?**

A:
```typescript
test('dropdown closes on Escape', async () => {
  const user = userEvent.setup();
  render(<Dropdown options={['A', 'B', 'C']} />);

  // Open the dropdown:
  await user.click(screen.getByRole('button', { name: /select/i }));

  // Verify it's open:
  expect(screen.getByRole('listbox')).toBeVisible();

  // Press Escape:
  await user.keyboard('{Escape}');

  // Verify it's closed:
  expect(screen.queryByRole('listbox')).not.toBeInTheDocument();
  // Or if it stays in DOM but hidden:
  // expect(screen.queryByRole('listbox')).not.toBeVisible();
});
```

> **Code walkthrough:** This Unknown example demonstrates TypeScript pattern using async/await. **KEY MECHANISM:** TypeScript compiles to JavaScript; type information is erased at runtime. **WHY IT MATTERS:** type assertions bypass the type checker - a runtime error can still occur. **TAKEAWAY: prefer type guards over type assertions for safe narrowing of union types.**

Key details:
- `user.keyboard('{Escape}')` fires the full keyboard event sequence
  (keydown, keyup) with the Escape key
- Check listbox role (ARIA role for dropdown options)
- Use `queryByRole` for absence check (returns null, doesn't throw)
- After testing closure, verify focus returned to the trigger button:
  `expect(screen.getByRole('button')).toHaveFocus()` (if applicable)

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



