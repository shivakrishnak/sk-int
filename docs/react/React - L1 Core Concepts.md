---
layout: default
title: "React - L1 Core Concepts"
parent: "React"
nav_order: 2
permalink: /react/l1-core-concepts/
---

# JSX and React Elements

🎯 **Interview Weight:** foundational (★☆☆) - JSX is asked in every React
interview; misunderstanding it causes subtle bugs

---

### 🎯 Model Answer

**30 seconds:**

> JSX is syntactic sugar that compiles to `React.createElement()` calls.
> It is NOT HTML - it's JavaScript with XML-like syntax. `className` not
> `class`, `htmlFor` not `for`, `onClick` not `onclick`. JSX produces
> React elements (plain JS objects), not DOM nodes. React elements are
> the description of what to render; React DOM translates them to real DOM.

**3 minutes:**

> JSX transformation: `<div className="x">text</div>` compiles to
> `React.createElement('div', { className: 'x' }, 'text')`. With React 17+
> and the new JSX transform, you no longer need to import React to use JSX
> (the compiler auto-imports `react/jsx-runtime`).
>
> Key JSX rules: expressions use `{}` not `${}` (no template literals in
> JSX). Conditionals: use `&&` operator or ternary. Lists: must return
> a JSX element with a unique `key`. JSX can only return a single root
> element (use Fragment `<>` to avoid extra DOM nodes).

**Blank Mind Recovery:**

**(1) Restate:** "JSX = React.createElement() calls. Not HTML: className,
htmlFor, camelCase events. Produces React elements (JS objects). Expression
with {}. Return one root element (Fragment <>). React 17+: no import needed."

---

### 📘 Concept Explanation

**What it is:**

JSX (JavaScript XML) is a syntax extension that allows writing UI
structures in JavaScript files. Babel/TypeScript compiles JSX to
`React.createElement()` calls before execution. It's a developer
experience improvement, not a new language.

**The problem it solves:**

Before JSX, building component trees with `React.createElement` was
verbose and hard to read. JSX makes the component structure visually
match the resulting UI tree, reducing cognitive load.

**How it works:**

```jsx
// JSX TO JS COMPILATION:
// This JSX:
const element = (
  <div className="container" onClick={handleClick}>
    <h1>{title}</h1>
    <p>{description}</p>
  </div>
);

// Compiles to (classic transform):
const element = React.createElement(
  'div',
  { className: 'container', onClick: handleClick },
  React.createElement('h1', null, title),
  React.createElement('p', null, description)
);

// The resulting React element (plain JS object):
// {
//   $$typeof: Symbol(react.element),
//   type: 'div',
//   props: {
//     className: 'container',
//     onClick: handleClick,
//     children: [
//       { type: 'h1', props: { children: title } },
//       { type: 'p', props: { children: description } }
//     ]
//   }
// }

// KEY JSX RULES:
// 1. Expressions: use {} not ${}
const x = <p>{'Hello ' + name}</p>;      // CORRECT
// const x = <p>${'Hello ' + name}</p>;  // WRONG - renders literal ${}

// 2. One root element (or Fragment):
// BAD:
// return <h1>Title</h1> <p>Text</p>; // two roots - error
// GOOD: Fragment (no extra DOM node)
return (
  <>
    <h1>Title</h1>
    <p>Text</p>
  </>
);

// 3. HTML differences:
// class -> className
// for -> htmlFor
// onclick -> onClick
// tabindex -> tabIndex
// style: string in HTML, object in JSX
const style = { color: 'red', fontSize: '16px' };
const el = <div style={style}>Text</div>;

// 4. Self-closing tags (required in JSX):
<input />  // CORRECT (not <input>)
<br />     // CORRECT
<img src={url} alt={alt} />  // CORRECT

// 5. Components vs HTML elements:
// Lowercase: HTML element (<div>)
// Uppercase: React component (<MyComponent>)
const MyDiv = 'div';    // variable is lowercase
<MyDiv />               // BAD: treated as <mydiv> (HTML)
const Container = 'div';  // capitalize
<Container />           // GOOD: treated as component
```

**Why it matters:**

JSX quirks cause real bugs. `class` vs `className` is the classic mistake.
Understanding that JSX compiles to function calls explains why you can't
use `if` statements inside JSX (only expressions are allowed inside `{}`),
why you need keys on lists, and why React 17's new JSX transform removed
the need to import React in every file.

---

### 💻 Code Example

```jsx
// COMMON JSX MISTAKES:

// BAD: using class instead of className
<div class="container">Text</div>
// Console warning: "Invalid DOM property 'class'. Did you mean className?"

// GOOD:
<div className="container">Text</div>

// BAD: event handler called immediately (not passed as callback)
<button onClick={handleClick()}>Click</button>
// handleClick() executes during render, not on click!

// GOOD: pass function reference
<button onClick={handleClick}>Click</button>
// OR: arrow function for arguments
<button onClick={() => handleClick(id)}>Click</button>

// BAD: undefined condition renders "0" (falsy but truthy string)
const count = 0;
return <div>{count && <span>Items: {count}</span>}</div>;
// Renders: <div>0</div>  <- "0" appears in UI!

// GOOD: explicit boolean condition
return <div>{count > 0 && <span>Items: {count}</span>}</div>;
// OR: ternary
return <div>{count ? <span>Items: {count}</span> : null}</div>;
```

> **Code walkthrough:** The `onClick={handleClick()}` bug is extremely
> common for beginners - the parentheses cause the function to execute
> during render and the return value (likely undefined) is passed as the
> handler. React calls it on click and nothing happens (or throws because
> undefined is not a function). The `0 && <span>` bug occurs because `0`
> is falsy in JavaScript but when React renders a number, it outputs it
> as a text node. `0` is "falsy but renderable" - React renders it as
> "0". Using `count > 0` forces a true boolean comparison.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> JSX is syntactic sugar that compiles to React.createElement() calls.
> It looks like HTML but has differences: use `className` instead of
> `class`, `htmlFor` instead of `for`, camelCase for events (`onClick`).
> JSX expressions use `{}` for JavaScript values. You can only return
> one root element from a component; use `<>` (Fragment) to wrap multiple
> elements without adding an extra DOM node.

**Senior / Staff:**

> JSX is a syntax extension, not a feature of React the library. The
> compilation is handled by Babel or TypeScript. With React 17+ and the
> new JSX transform (`react/jsx-runtime`), components no longer need to
> import React just to use JSX - the compiler injects the import. The
> resulting React element is a plain JavaScript object with `$$typeof`
> (a Symbol to prevent XSS from JSON injection), `type`, and `props`.
> Understanding that React elements are immutable objects (not DOM nodes)
> explains why you can pass them as props, store them in state, and
> render them conditionally.

---

### ⚠️ Common Misconceptions

**Misconception 1: JSX is HTML inside JavaScript.**

JSX is JavaScript syntax extension that looks like HTML but compiles to `React.createElement()` calls. `<div className="box">` is NOT HTML - it becomes `React.createElement('div', { className: 'box' })`. This is why `class` becomes `className` (reserved JS keyword), `for` becomes `htmlFor`, event handlers are camelCase (`onClick` not `onclick`), and self-closing tags are required (`<br />` not `<br>`). Understanding JSX-as-JavaScript explains why you can embed any JS expression in `{}` but not statements.

**Misconception 2: JSX requires Babel and cannot be used without a build step.**

JSX can be used without a build step in two ways: 1) `React.createElement()` calls directly (tedious but valid), or 2) using the `@babel/standalone` browser build or import map with a JSX-capable runtime (like htm, a tagged template literal JSX alternative). Most production apps use a build step for performance optimization, but JSX is not architecturally required.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Rendering user content directly causes XSS vulnerabilities.**

Symptom: script tags or event handlers in user-provided content execute in the browser; stored XSS attack succeeds. Root cause: using `dangerouslySetInnerHTML={{ __html: userContent }}` without sanitization. Diagnosis: verify all uses of `dangerouslySetInnerHTML` in the codebase; check if the content is user-provided. Fix: sanitize HTML with DOMPurify before setting: `dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(content) }}`; prefer rendering user content via normal JSX rendering which auto-escapes strings.

**Failure Mode 2: Stale JSX reference causes incorrect renders.**

Symptom: component renders old data after state/props update; re-render does not reflect the latest values. Root cause: JSX element or component reference captured in a closure that closed over stale values; or a component stored as JSX (`const element = <MyComponent />`), which is a static snapshot, not a reactive reference. Fix: use component functions (`<MyComponent />` in render output), not pre-rendered JSX element variables for dynamic content.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---|---|
| What is JSX? | 2-3 min | Compilation to createElement |
| class vs className | 1-2 min | HTML differences |
| Event handler syntax | 2-3 min | Reference vs call |
| Fragment usage | 2-3 min | No extra DOM nodes |
| 0 && component bug | 2-3 min | Falsy rendering |
| JSX transform (React 17+) | 2-3 min | No import needed |
| Security: $$typeof | 2-3 min | XSS prevention |

---

**Q1: What is the purpose of `$$typeof` on React elements?** `[STAFF]`
SECURITY

> **Answer:**
>
> > `$$typeof: Symbol(react.element)` is a security marker. React checks
> > this symbol before rendering any element. Since Symbols cannot be
> > represented in JSON, a JSON response from a server cannot fake a
> > React element.
> >
> > The attack scenario: if user input is passed to `dangerouslySetInnerHTML`
> > or a library renders untrusted JSON as a React element, an attacker
> > could craft JSON that appears to be a valid React element: `{ type: 'script', props: { src: 'evil.js' } }`. Without `$$typeof`, this could be rendered.
> >
> > With `$$typeof: Symbol(react.element)`, React rejects any "element"
> > that wasn't created via `React.createElement()` or JSX (because JSON
> > can't contain Symbols). This is a defense-in-depth measure, not a
> > replacement for proper XSS prevention (React already escapes strings
> > in JSX expressions).
>
> *What separates good from great:* Most candidates know "JSX is syntactic
> sugar for createElement" but few know about `$$typeof`. This detail
> shows understanding of React's security design and how the library
> protects against a class of JSON injection attacks.

---

---

# Props and Component Composition

🎯 **Interview Weight:** foundational (★☆☆) - props and composition are
the fundamental React programming model

---

### 🎯 Model Answer

**30 seconds:**

> Props are read-only inputs to React components (like function parameters).
> They flow one way: parent to child. Components must never modify their
> own props. Composition is building complex UIs from simple components,
> often by passing components as `children` prop or render props. This
> is React's alternative to inheritance: "compose, don't extend."

**3 minutes:**

> Props work like function arguments: pass data and callbacks from parent
> to child. Children prop is the most powerful composition mechanism -
> pass a component tree into another component to customize its content
> without modifying the container.
>
> Common patterns:
> - `children` prop: `<Modal title="x">{content}</Modal>`
> - render props: pass a function as prop: `<List renderItem={item => <Row data={item} />}`
> - compound components: `<Select.Root><Select.Option /></Select.Root>` - components
>   share implicit state via Context

**Blank Mind Recovery:**

**(1) Restate:** "Props: read-only inputs, parent-to-child one-way flow.
Composition: use children prop to customize container content. Compound
components share Context. Never inherit - always compose."

---

### 📘 Concept Explanation

**What it is:**

Props (properties) are the mechanism for passing data from parent
components to child components. They form the core of React's one-way
data flow. Component composition is the practice of building complex
UIs by combining simpler components through props.

**How it works:**

```jsx
// BASIC PROPS:
function Avatar({ src, alt, size = 48 }) {
  return (
    <img
      src={src}
      alt={alt}
      width={size}
      height={size}
      className="avatar"
    />
  );
}
// Usage: <Avatar src={user.photo} alt={user.name} size={64} />

// CHILDREN PROP: slot-based composition
function Card({ title, children }) {
  return (
    <div className="card">
      <div className="card-header"><h2>{title}</h2></div>
      <div className="card-body">{children}</div>
    </div>
  );
}
// Usage: Card with any content
<Card title="Profile">
  <Avatar src={user.photo} alt={user.name} />
  <p>{user.bio}</p>
  <Button>Follow</Button>
</Card>

// COMPOSITION OVER INHERITANCE:
// BAD: class inheritance (anti-pattern in React)
class RedButton extends Button {
  render() {
    return <button style={{ color: 'red' }}>{this.props.label}</button>;
  }
}

// GOOD: composition via props
function Button({ color = 'blue', children, ...rest }) {
  return (
    <button style={{ color }} {...rest}>
      {children}
    </button>
  );
}
// Usage:
<Button color="red">Delete</Button>
<Button>Save</Button>

// PROP SPREADING (use carefully):
function Input({ label, ...inputProps }) {
  return (
    <label>
      {label}
      <input {...inputProps} />
      {/* inputProps: type, value, onChange, etc. */}
    </label>
  );
}
```

**Why it matters:**

Props define the component's API contract. Well-designed prop APIs make
components reusable (generic enough for different contexts) and self-documenting.
Poorly designed props create tight coupling (too many specific props) or
opacity (too few, over-relying on globals). The `children` prop is React's
most powerful composition primitive - master it.

---

### 💻 Code Example

```jsx
// COMMON MISTAKE: prop drilling anti-pattern
// BAD: passing props through many intermediate levels
function App({ user }) {
  return <Layout user={user} />;
}
function Layout({ user }) {
  return <Header user={user} />;
}
function Header({ user }) {
  return <Avatar user={user} />;
}
function Avatar({ user }) {
  return <img src={user.photo} alt={user.name} />;
}
// user prop passes through Layout and Header even though
// they don't use it - "prop drilling"

// GOOD: composition with children (avoids drilling)
function App({ user }) {
  return (
    <Layout>
      <Header>
        <Avatar src={user.photo} alt={user.name} />
      </Header>
    </Layout>
  );
}
function Layout({ children }) {
  return <main className="layout">{children}</main>;
}
function Header({ children }) {
  return <header className="header">{children}</header>;
}
// Layout and Header don't know about user - clean separation
```

> **Code walkthrough:** The prop drilling version forces `Layout` and
> `Header` to accept and pass through `user` even though they never
> use it. Any change to the `user` shape requires updating all intermediate
> components. The composition version inverts this: `App` (which knows
> about `user`) builds the complete `<Avatar>` and passes it to the
> layout containers. The containers are now generic - they don't know
> about users. This is the same principle as "slots" in web components
> or named outlets in Angular.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Props are how you pass data from parent to child components, like
> function arguments. They're read-only - a component never changes
> its own props. The `children` prop lets you nest content inside a
> component. Composition means building complex components from simpler
> ones by combining them through props and children, rather than
> inheriting from base components.

**Senior / Staff:**

> React's component model is fundamentally compositional. The children
> prop is a first-class mechanism for "inversion of control" - the parent
> provides the specific content (which knows about the data), the container
> provides the structure (which is generic). This is why proper React
> avoids prop drilling: instead of passing data down many levels, push the
> concerned component UP to where the data is and pass it as `children`.
> The compound component pattern extends this: `<Tabs>` + `<Tabs.Panel>`
> share implicit state via Context, creating a cohesive API without exposing
> internal state as props.

---

### ⚠️ Common Misconceptions

**Misconception 1: Props should be avoided for deep component hierarchies - use global state instead.**

Prop drilling (passing props through many component layers) is a real concern, but the solution is not always global state. Context API is React's built-in solution for prop drilling elimination. Moving data to global state (Redux, Zustand) for data that only belongs to one component subtree creates accidental coupling between unrelated components. Prefer Context for subtree-scoped data; use global state only for truly global concerns (auth, theme, user preferences).

**Misconception 2: Components should be as small as possible (one concern = one component).**

Over-componentization creates files with single-line components, prop drilling just to render a label, and complex component trees that are harder to understand than a single medium-sized component. Component boundaries should reflect logical UI units (a card, a form, a list) not implementation units (a paragraph, a button). Split when: a piece of UI is reused in multiple places, a piece of UI has independent state and lifecycle, or a component exceeds ~200 lines.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Mutating props causes unpredictable bugs.**

Symptom: parent component's state changes unexpectedly when child component modifies its data; changes in child component persist beyond expected scope. Root cause: props are shallow copies of parent state objects; mutating the prop object mutates the parent's state object reference. Diagnosis: use React DevTools to track state changes; check for object mutations in child components. Fix: treat props as read-only; create copies before modifying: `const localCopy = { ...props.data }`.

**Failure Mode 2: Boolean prop trap creates confusing API.**

Symptom: component accepts many boolean props (`isLarge`, `isDisabled`, `isPrimary`, `isLoading`); callers must understand all boolean combinations to use the component correctly. Root cause: component has too many behavioral variants controlled by individual flags. Fix: use a `variant` string enum prop (`variant="primary"` | `"secondary"`) for mutually exclusive variants; reserve booleans for truly independent toggles (`disabled`, `loading`).

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| Props one-way flow | 2-3 min | Immutability |
| children prop | 2-3 min | Composition |
| Prop drilling vs children | 3-4 min | Inversion of control |
| Compound components | 3-4 min | Context sharing |
| Props vs state | 2-3 min | External vs internal |
| Render props pattern | 2-3 min | Function as child |
| Component API design | 3-4 min | Reusability |

---

**Q1: How do you solve prop drilling without Context?** `[SENIOR]`
DECISION

> **Answer:**
>
> > Prop drilling is solved by composition before reaching for Context.
> > The pattern: instead of drilling `user` through 4 levels, lift the
> > component that NEEDS `user` to the level that HAS `user`, and pass
> > it as `children` to the intermediate levels.
> >
> > ```jsx
> > // Before (drilling): App -> Layout -> Header -> Avatar
> > // After (composition): App builds Avatar, passes as children
> > function App({ user }) {
> >   const avatar = <Avatar src={user.photo} alt={user.name} />;
> >   return <Layout header={<Header>{avatar}</Header>} />;
> > }
> > ```
> >
> > When to use Context instead: when the data is needed in many unrelated
> > places in the tree (not just one leaf), or when composition would
> > make the component tree awkward (deeply nested content that needs
> > to float up). Context is appropriate for: auth state, theme,
> > locale/i18n, feature flags. Context is NOT appropriate for:
> > server data (use TanStack Query), complex client state (use Zustand).
>
> *What separates good from great:* The insight that composition solves
> most prop drilling is the mark of a senior React engineer. Many
> developers jump to Context too early, which creates hidden dependencies
> (components implicitly depend on a Context value without the dependency
> being visible in the component's API). Composition keeps dependencies
> explicit. Context should be the last resort for shared state, not the
> first response to drilling.

---

---

# State with useState

🎯 **Interview Weight:** foundational (★☆☆) - useState is the most
commonly asked hook; understanding re-renders and batching is critical

---

### 🎯 Model Answer

**30 seconds:**

> `useState` declares a state variable that, when updated, causes React
> to re-render the component with the new value. Key rules: state updates
> are asynchronous (not immediately reflected after calling setState).
> Multiple state updates in a single event handler are batched (React 18
> batches all updates, not just event handler updates). Use the functional
> updater form `setCount(c => c + 1)` when new state depends on old state.

**3 minutes:**

> `const [state, setState] = useState(initialValue)`. The initial value
> is only used on the first render; on re-renders, React uses the stored
> value. State triggers a re-render of the component and all descendants
> (unless they use memo).
>
> Critical: `setState` does NOT merge objects like class component's
> `this.setState`. In function components, you must spread the previous
> state manually: `setState(prev => ({ ...prev, name: 'new' }))`.
>
> Lazy initialization: `useState(() => expensiveCompute())` - the function
> runs only on the first render.

**Blank Mind Recovery:**

**(1) Restate:** "useState: declare state + trigger re-render. Updates async
(not immediate). Batch in React 18 (all contexts). Functional updater for
prev-state-dependent updates. Object state: spread manually. Lazy init:
pass function to avoid re-running on every render."

---

### 📘 Concept Explanation

**What it is:**

`useState` is a React hook that adds local state to function components.
It returns a tuple: the current state value and a dispatch function.
Calling the dispatch function schedules a re-render with the new value.

**How it works:**

```jsx
import { useState } from 'react';

// BASIC USAGE:
function Counter() {
  const [count, setCount] = useState(0);
  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>+</button>
    </div>
  );
}

// WRONG: reading state immediately after update
function Counter() {
  const [count, setCount] = useState(0);
  function handleClick() {
    setCount(count + 1);
    console.log(count); // Logs OLD value (update is async)
    // count is still 0 after setCount(1) is called
  }
  // ...
}

// RIGHT: functional updater for dependent updates
function Counter() {
  const [count, setCount] = useState(0);
  function handleTripleClick() {
    // WRONG: all three use the same stale count
    setCount(count + 1); // count = 0 -> setCount(1)
    setCount(count + 1); // count = 0 -> setCount(1) again!
    setCount(count + 1); // count = 0 -> setCount(1) again!
    // Result: count = 1 (not 3!)

    // RIGHT: functional updater uses latest state
    setCount(c => c + 1); // c=0 -> 1
    setCount(c => c + 1); // c=1 -> 2
    setCount(c => c + 1); // c=2 -> 3
    // Result: count = 3
  }
}

// OBJECT STATE: must spread to merge
function UserForm() {
  const [user, setUser] = useState({
    name: '',
    email: '',
    age: 0
  });

  // WRONG: replaces the entire object
  function handleNameChange(name) {
    setUser({ name }); // { name: 'Alice' } - email/age LOST!
  }

  // RIGHT: spread previous state
  function handleNameChange(name) {
    setUser(prev => ({ ...prev, name }));
    // { name: 'Alice', email: '', age: 0 }
  }
}

// LAZY INITIALIZATION: for expensive initial state
function SearchResults() {
  // WRONG: readFromStorage runs on every render
  const [query, setQuery] = useState(readFromStorage('query'));

  // RIGHT: function runs only on first render
  const [query, setQuery] = useState(
    () => readFromStorage('query')
  );
}
```

**Why it matters:**

`useState` batching behavior changed in React 18 (now batches ALL updates,
including those in setTimeout and Promises). The stale closure bug (using
`count` directly in async callbacks) is one of the most common React bugs.
Functional updaters are the solution.

---

### 💻 Code Example

```jsx
// STALE CLOSURE BUG (very common):
function Timer() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      // BAD: count is captured at interval creation time (stale)
      setCount(count + 1);
      // count is always 0 here! interval never sees updated count
      // Result: count oscillates between 0 and 1
    }, 1000);
    return () => clearInterval(interval);
  }, []); // empty deps - interval only created once

  return <p>Count: {count}</p>;
}

// FIX: functional updater doesn't close over count
function Timer() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setCount(c => c + 1); // c is the current value, not closure
    }, 1000);
    return () => clearInterval(interval);
  }, []); // safe: doesn't depend on count

  return <p>Count: {count}</p>;
}
```

> **Code walkthrough:** The stale closure is one of the most common React
> bugs. When `useEffect` runs with `[]` deps, it captures the initial
> value of `count` (0) in the closure for `setInterval`. Every tick calls
> `setCount(0 + 1)` = `setCount(1)`, and React sets it to 1 - but then
> the component re-renders, count becomes 1, but the interval closure
> still has `count = 0`. The functional updater `c => c + 1` receives
> the actual current state as `c` (not the closed-over value), so it
> always increments correctly regardless of when it executes.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `useState` adds local state to a component. You get the current value
> and a setter function. When you call the setter, React re-renders the
> component with the new value. State updates are asynchronous - you can't
> read the new value immediately after setting it. For object state, you
> must spread the previous state to avoid overwriting unrelated fields.

**Senior / Staff:**

> Key `useState` subtleties for senior interviews: (1) React 18 batches
> ALL state updates, including inside Promises and setTimeout - previously
> only event handlers were batched. (2) Functional updaters are critical
> for correctness when updates depend on previous state (stale closures,
> multiple updates in one event handler). (3) State identity: React uses
> `Object.is` to compare previous and new state - avoid creating new
> object references unnecessarily, or use `useReducer` for complex
> state objects. (4) State colocation: keep state as close to where it's
> needed as possible; don't "lift" state prematurely.

---

### ⚠️ Common Misconceptions

**Misconception 1: useState updates are synchronous - the new value is available immediately after calling setState.**

State updates are asynchronous and batched. After `setCount(count + 1)`, reading `count` in the same synchronous code block returns the OLD value. React batches multiple `setState` calls in event handlers into a single re-render. In React 18, ALL state updates are batched, including those in `setTimeout` and async callbacks. To compute new state based on the current state, use the functional updater: `setCount(prev => prev + 1)`.

**Misconception 2: Complex objects should be stored in separate useState calls.**

The choice between single useState with an object vs multiple useState calls is about logical grouping, not performance. Fields that change together should be grouped in a single useState call to avoid partial state updates. Fields that change independently are cleaner as separate calls. For complex state with many fields and conditional logic, `useReducer` is often clearer than multiple `useState` calls.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Stale closure in event handler reads old state.**

Symptom: counter increments by 1 even when clicked rapidly; async operations set outdated values; event handler uses the value from when it was created, not the current value. Root cause: `setCount(count + 1)` captures `count` from the closure at render time; if called three times in a row, all three calls use the same initial count. Diagnosis: add console.log of `count` in the handler; verify it changes between fast clicks. Fix: use functional updater: `setCount(prev => prev + 1)` which always receives the latest state.

**Failure Mode 2: Initialization of expensive state runs on every render.**

Symptom: slow render performance traced to a complex computation happening on every re-render even when the input hasn't changed. Root cause: `useState(computeExpensiveValue())` - the argument to useState is a function CALL; it runs on every render even though useState ignores it after the first render. Fix: use lazy initialization: `useState(() => computeExpensiveValue())` - the function is only called once on initial mount.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| useState mechanism | 2-3 min | Re-render trigger |
| Async state updates | 2-3 min | Not immediate |
| Functional updater | 3-4 min | Stale closure fix |
| Object state spreading | 2-3 min | Merge vs replace |
| Stale closure bug | 3-4 min | Closure capture |
| Lazy initialization | 2-3 min | Run once only |
| React 18 batching | 2-3 min | All contexts |

---

**Q1: Why does calling setState multiple times in the same event handler
only cause one re-render?** `[SENIOR]` MECHANISM

> **Answer:**
>
> > React batches state updates within a single event handler. Instead of
> > re-rendering after each `setState` call, React schedules all updates
> > and processes them together in a single render pass.
> >
> > In React 18+, this batching extends to ALL update contexts - not just
> > event handlers. Updates inside `setTimeout`, Promises, and `async`
> > functions are also batched.
> >
> > ```javascript
> > function handleClick() {
> >   setCount(c => c + 1); // queued, not rendered yet
> >   setName('Alice');      // queued, not rendered yet
> >   setLoading(false);     // queued, not rendered yet
> >   // React renders ONCE after handleClick returns
> >   // with all three updates applied
> > }
> > ```
> >
> > This is critical for performance: 3 state updates in an event handler
> > cause 1 re-render, not 3.
> >
> > If you need to opt out of batching (rare), use
> > `ReactDOM.flushSync()` to force immediate rendering.
>
> *What separates good from great:* Knowing that React 18 EXTENDED batching
> to asynchronous contexts (fixing a long-standing React pain point) shows
> current knowledge. The follow-up question is often "what was the behavior
> before React 18?" - in React 17, only event handlers were batched;
> Promise callbacks triggered a re-render after each setState.
