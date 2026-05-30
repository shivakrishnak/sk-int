---
layout: default
title: "React - L1 Hooks Basics"
parent: "React"
nav_order: 3
permalink: /react/l1-hooks-basics/
---

# useEffect and Side Effect Management

🎯 **Interview Weight:** foundational (★☆☆) - useEffect misuse is the
#1 source of React bugs; interviewed in every role above junior

---

### 🎯 Model Answer

**30 seconds:**

> `useEffect` runs a function AFTER React renders and paints the DOM.
> It handles side effects: data fetching, subscriptions, manual DOM
> manipulation. Key rules: the dependency array controls when it runs
> (empty = once, [dep] = when dep changes, absent = every render).
> Return a cleanup function to prevent memory leaks. The most common
> mistake: missing dependencies causing stale values.

**3 minutes:**

> useEffect lifecycle:
> 1. React renders (creates virtual DOM, diffs)
> 2. React commits to real DOM
> 3. Browser paints
> 4. useEffect runs
> 5. On cleanup: runs previous effect's cleanup, then new effect
>
> Dependency array rules: include every reactive value used in the
> effect (values that change over time: state, props, context). Omitting
> a dependency = stale closure bug. Adding too many = effect runs too
> often. ESLint rule `exhaustive-deps` auto-detects missing deps.

**Blank Mind Recovery:**

**(1) Restate:** "useEffect: runs after render. Deps array: empty=once,
[dep]=on dep change, absent=every render. Cleanup function prevents
leaks. Missing dep = stale closure. ESLint exhaustive-deps catches issues."

---

### 📘 Concept Explanation

**What it is:**

`useEffect` is the mechanism for synchronizing a React component with
an external system (APIs, subscriptions, DOM, timers). It runs after
render is committed to the DOM, making it safe for side effects that
would be unsafe during render.

**The problem it solves:**

React renders are supposed to be pure (no side effects). Data fetching,
WebSocket connections, and DOM manipulations can't happen during render.
`useEffect` provides a designated side-effect zone that runs after render.

**How it works:**

```jsx
import { useEffect, useState } from 'react';

// BASIC: run after every render (no deps array)
useEffect(() => {
  document.title = `Count: ${count}`;
}); // runs after EVERY render

// ONCE: run only on mount (empty deps)
useEffect(() => {
  const subscription = subscribe(topic);
  return () => subscription.unsubscribe(); // cleanup on unmount
}, []); // empty array = run once on mount

// CONDITIONAL: run when deps change
useEffect(() => {
  fetchUser(userId).then(setUser);
}, [userId]); // re-runs when userId changes

// DATA FETCHING WITH CLEANUP:
function UserProfile({ userId }) {
  const [user, setUser] = useState(null);

  useEffect(() => {
    let cancelled = false; // cleanup flag

    async function loadUser() {
      const data = await fetchUser(userId);
      if (!cancelled) setUser(data); // don't update if unmounted
    }

    loadUser();

    return () => {
      cancelled = true; // cancel on cleanup
    };
  }, [userId]);

  return user ? <Profile user={user} /> : <Spinner />;
}

// THE WRONG WAY: no cleanup (memory leak + race condition)
function UserProfile({ userId }) {
  const [user, setUser] = useState(null);

  useEffect(() => {
    fetchUser(userId).then(setUser); // no cleanup!
    // If userId changes before fetch completes:
    // - Old fetch sets state to stale user
    // - New fetch sets state to correct user
    // - But order is non-deterministic! Race condition.
  }, [userId]);
}
```

**Why it matters:**

`useEffect` misuse is the most common source of React bugs:
(1) Memory leaks from missing cleanup (subscriptions, timers left running)
(2) Race conditions from missing cancellation (old requests completing after new ones)
(3) Infinite loops from wrong/missing dependencies
(4) Stale closures from missing dependency values

---

### 💻 Code Example

```jsx
// STALE DEPENDENCY BUG:
function SearchResults({ query }) {
  const [results, setResults] = useState([]);

  // BAD: stale query in effect
  useEffect(() => {
    // query is captured at effect creation time
    // if query changes rapidly, this may use old value
    search(query).then(setResults);
  }, []); // MISSING dependency: query!
  // eslint warning: "React Hook useEffect has a missing dependency: 'query'"

  // GOOD: add query to deps
  useEffect(() => {
    let cancelled = false;
    search(query).then(r => {
      if (!cancelled) setResults(r);
    });
    return () => { cancelled = true; };
  }, [query]); // re-runs when query changes
}

// INFINITE LOOP BUG:
function UserData({ userId }) {
  const [user, setUser] = useState(null);

  // BAD: object created on every render triggers infinite loop
  const options = { headers: { 'X-User': userId } };
  useEffect(() => {
    fetchUser(userId, options).then(setUser);
  }, [userId, options]); // options is new object every render!
  // React sees new options reference = effect runs = new render = new options...

  // GOOD: move object inside effect
  useEffect(() => {
    const opts = { headers: { 'X-User': userId } };
    fetchUser(userId, opts).then(setUser);
  }, [userId]); // only userId as dep
}
```

> **Code walkthrough:** The infinite loop from object-as-dependency is one
> of the trickiest useEffect bugs. On every render, `options` is a new
> object reference (even if the values are identical). React compares
> deps with `Object.is` - new reference = changed dependency = effect runs
> again - which triggers another render - which creates another `options`
> object. The fix: move the object creation INSIDE the effect (where it's
> not a dependency) or memoize it with `useMemo`. The stale closure example
> shows the opposite: missing `query` from deps means the effect runs with
> the initial value forever.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `useEffect` runs code after React renders. The dependency array controls
> when: no array = every render, empty array = once on mount, with values =
> when those values change. Always return a cleanup function when the effect
> creates subscriptions or timers. The most common mistake is forgetting
> to add dependencies, which causes the effect to use stale values.

**Senior / Staff:**

> `useEffect` is the escape hatch to synchronize React with external systems.
> Key subtleties: (1) Strict Mode double-invokes effects in development to
> expose cleanup bugs - this is intentional, not a bug. (2) `useEffect`
> fires after paint - for effects needing to run before paint (like DOM
> measurements), use `useLayoutEffect`. (3) In React 18 with concurrent
> features, effects can unmount and remount due to Offscreen API - cleanup
> must be idempotent. (4) The question "does this need useEffect?" is the
> most important question: most data derivation and event handling doesn't
> need effects (it belongs in render or event handlers).

---

### ⚠️ Common Misconceptions

**Misconception 1: useEffect runs after every render by default and that's fine for performance.**

Running useEffect without dependencies means it runs after every single render - including re-renders from parent state changes. For API calls, this creates a request waterfall: render → request → re-render → request → infinite loop if the response updates state. Every useEffect must have a dependency array that accurately reflects the values it uses. An empty `[]` means run once on mount; `[dependency]` means run when dependency changes.

**Misconception 2: You should always use useEffect for data fetching.**

React's own documentation now recommends against using useEffect for data fetching in new code. The reasons: no request deduplication, no caching, no automatic refetch on focus, and the potential for race conditions with stale responses. Use React Query, SWR, or RTK Query for data fetching. In Next.js, use server components or `getServerSideProps`. useEffect is appropriate for DOM side effects, subscriptions, and integrating with third-party libraries.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Race condition in useEffect causes stale state from an out-of-order response.**

Symptom: switching between tabs quickly shows data from a previous tab; search results show results for a different query than what's in the input. Root cause: two effects are in-flight; the earlier one resolves AFTER the later one and overwrites the correct state. Diagnosis: add request ID logging; observe order of API responses vs component state. Fix: use an effect cleanup function with an `isCancelled` flag: `let cancelled = false; fetch(url).then(d => !cancelled && setData(d)); return () => { cancelled = true; }`.

**Failure Mode 2: Missing cleanup causes memory leaks and update-on-unmounted-component errors.**

Symptom: "Can't perform a React state update on an unmounted component" warning; event listeners or subscriptions still active after component unmounts. Root cause: useEffect subscribes to events or starts async operations without returning a cleanup function. Fix: always return a cleanup function for subscriptions: `useEffect(() => { const sub = subscribe(); return () => sub.unsubscribe(); }, [])`.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| useEffect lifecycle | 3-4 min | After paint |
| Dependency array rules | 3-4 min | Exhaustive deps |
| Cleanup function | 3-4 min | Memory leak prevention |
| Race condition fix | 4-5 min | Cancellation pattern |
| Infinite loop causes | 3-4 min | Object reference |
| useEffect vs useLayoutEffect | 2-3 min | Before vs after paint |
| When NOT to use useEffect | 3-4 min | Over-use pattern |

---

**Q1: How do you prevent race conditions in useEffect data fetching?**
`[SENIOR]` DEBUGGING

> **Answer:**
>
> > Race conditions occur when a second request completes before the first.
> > For example: user types 'A' (request 1), then types 'AB' (request 2).
> > Request 2 is faster. Request 1 resolves after request 2, overwriting
> > the correct results with stale 'A' results.
> >
> > Fix patterns:
> >
> > ```jsx
> > // Pattern 1: cancelled flag (simple, most common)
> > useEffect(() => {
> >   let cancelled = false;
> >   searchAPI(query).then(results => {
> >     if (!cancelled) setResults(results);
> >   });
> >   return () => { cancelled = true; };
> > }, [query]);
> >
> > // Pattern 2: AbortController (native, cancels in-flight requests)
> > useEffect(() => {
> >   const controller = new AbortController();
> >   fetch(`/api/search?q=${query}`, {
> >     signal: controller.signal
> >   }).then(r => r.json()).then(setResults)
> >     .catch(e => {
> >       if (e.name !== 'AbortError') setError(e);
> >     });
> >   return () => controller.abort();
> > }, [query]);
> >
> > // Pattern 3: TanStack Query (handles all of this automatically)
> > const { data } = useQuery({
> >   queryKey: ['search', query],
> >   queryFn: ({ signal }) =>
> >     fetch(`/api/search?q=${query}`, { signal })
> >       .then(r => r.json()),
> > });
> > ```
> >
> > For production code, TanStack Query is the recommended approach -
> > it handles cancellation, caching, stale-while-revalidate, and error
> > states automatically.
>
> *What separates good from great:* Knowing all three patterns and being
> able to articulate when each is appropriate. `AbortController` actually
> cancels the HTTP request (good for bandwidth), while the `cancelled` flag
> only prevents state updates (request still completes). For complex apps,
> TanStack Query eliminates the entire class of data-fetching useEffect bugs.

---

---

# useRef and DOM Access

🎯 **Interview Weight:** foundational (★☆☆) - useRef is used for DOM
access, mutable values without re-render, and forwarding refs to children

---

### 🎯 Model Answer

**30 seconds:**

> `useRef` returns a mutable object `{ current: initialValue }` that
> persists across renders WITHOUT causing re-renders when changed.
> Two use cases: (1) DOM access: `ref={myRef}` attaches ref to DOM element,
> `myRef.current` is the DOM node. (2) Mutable instance variable: store
> values that change but shouldn't trigger re-renders (timers, previous
> values, stale-closure workarounds).

**3 minutes:**

> DOM access: use `useRef` to call imperative DOM APIs: focus(), scrollIntoView(),
> getBoundingClientRect(). Never store refs in state (causes re-renders);
> useRef is specifically for "not trigger re-render" mutations.
>
> The "mutable ref" pattern solves stale closures in callbacks: instead
> of a value in deps, store the latest value in a ref. The callback reads
> from `ref.current` (always latest), not from a closed-over variable.
>
> `forwardRef` lets parent components pass a ref through to a child's DOM
> element: `const Input = forwardRef((props, ref) => <input ref={ref} />)`.

**Blank Mind Recovery:**

**(1) Restate:** "useRef: mutable object persisting across renders, no
re-render on change. Use for: DOM access (ref={myRef}, then myRef.current
is DOM node), mutable values (timer ids, prev values). forwardRef: expose
DOM to parent."

---

### 📘 Concept Explanation

**What it is:**

`useRef` creates a box that holds a mutable value. Unlike state, mutating
a ref's `.current` property does not trigger a re-render. The same ref
object persists across all re-renders of a component (unlike a new variable
declaration each render).

**How it works:**

```jsx
import { useRef, useEffect } from 'react';

// USE CASE 1: DOM ACCESS
function SearchInput() {
  const inputRef = useRef(null);

  // Focus input on mount:
  useEffect(() => {
    inputRef.current.focus();
  }, []);

  function handleClear() {
    inputRef.current.value = ''; // direct DOM manipulation
    inputRef.current.focus();
  }

  return (
    <div>
      <input ref={inputRef} type="search" />
      <button onClick={handleClear}>Clear</button>
    </div>
  );
}

// USE CASE 2: MUTABLE INSTANCE VARIABLE (no re-render)
function Stopwatch() {
  const [elapsed, setElapsed] = useState(0);
  const intervalRef = useRef(null); // store timer id

  function start() {
    intervalRef.current = setInterval(() => {
      setElapsed(e => e + 1);
    }, 1000);
  }

  function stop() {
    clearInterval(intervalRef.current); // access stored timer id
    intervalRef.current = null;
  }

  return (
    <div>
      <p>{elapsed}s</p>
      <button onClick={start}>Start</button>
      <button onClick={stop}>Stop</button>
    </div>
  );
}

// USE CASE 3: LATEST VALUE REF (stale closure workaround)
function useLatest(value) {
  const ref = useRef(value);
  ref.current = value; // update on every render
  return ref;
}

function LiveSearch({ onSearch }) {
  const onSearchRef = useLatest(onSearch);

  useEffect(() => {
    const subscription = socket.on('update', () => {
      onSearchRef.current(); // always latest onSearch callback
    });
    return () => subscription.off();
  }, []); // no deps needed - always reads latest via ref
}

// FORWARDING REFS: expose DOM node to parent
import { forwardRef } from 'react';
const TextInput = forwardRef(function TextInput(props, ref) {
  return <input ref={ref} {...props} />;
});
// Parent:
function Form() {
  const inputRef = useRef(null);
  return <TextInput ref={inputRef} onFocus={() => inputRef.current.select()} />;
}
```

**Why it matters:**

`useRef` is the escape hatch for imperative DOM access and mutable values.
Without it, focusing inputs, measuring elements, and integrating non-React
libraries (D3, maps) is impossible. The "latest ref" pattern solves stale
closures in long-lived effects without adding values to dependency arrays.

---

### 💻 Code Example

```jsx
// USING useRef WITH PREVIOUS VALUE COMPARISON:
function useWhyDidYouUpdate(name, props) {
  const prevProps = useRef({});
  useEffect(() => {
    const changedProps = {};
    Object.entries(props).forEach(([key, value]) => {
      if (prevProps.current[key] !== value) {
        changedProps[key] = {
          from: prevProps.current[key],
          to: value
        };
      }
    });
    if (Object.keys(changedProps).length > 0) {
      console.log('[why-did-you-update]', name, changedProps);
    }
    prevProps.current = props;
  });
}

// Usage (debugging re-renders):
function MyComponent(props) {
  useWhyDidYouUpdate('MyComponent', props);
  return <div>{props.value}</div>;
}
// Logs which props changed between renders
// Critical for debugging unnecessary re-renders
```

> **Code walkthrough:** The `useWhyDidYouUpdate` hook illustrates both
> `useRef` patterns simultaneously: (1) persisting a value across renders
> (`prevProps.current` stores the previous render's props), and (2) no
> re-render triggered when `prevProps.current` is mutated (we don't want
> the debugging hook to cause more renders). The `useEffect` (no deps array)
> runs after every render, compares current props to `prevProps.current`,
> logs any differences, then updates `prevProps.current` for the next render.
> This is a real production debugging pattern used to find performance issues.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `useRef` gives you a mutable box that persists across renders. Use it
> to access DOM elements (attach with `ref={myRef}`, then `myRef.current`
> is the DOM node) and to store values that should persist without causing
> re-renders (like timer IDs). Unlike state, changing `ref.current` doesn't
> trigger a re-render.

**Senior / Staff:**

> useRef serves two distinct purposes often confused: (1) DOM access -
> the "escape hatch" to the imperative DOM API for focusing, measuring,
> and integrating third-party libraries. (2) Instance variable - values
> that must persist across renders but must NOT trigger re-renders when
> changed. The critical insight: a ref is conceptually like an instance
> variable on a class component - it's part of the component's lifecycle
> but outside the rendering pipeline. The "latest ref" pattern
> (`ref.current = latestValue` on every render) is the proper solution
> for stale closures in long-lived effects, avoiding the need to include
> rapidly changing values in dependency arrays.

---

### ⚠️ Common Misconceptions

**Misconception 1: useRef is only for accessing DOM elements.**

useRef creates a mutable container (`{ current: value }`) whose changes do NOT trigger re-renders. This makes it useful for: storing a previous render's value, holding a timer ID that should not cause re-renders, keeping a mutable reference to a callback (to avoid stale closures), tracking whether the component has mounted, and storing any value that needs to persist across renders without triggering an update. DOM access is one use case, not the only one.

**Misconception 2: Modifying ref.current inside render is safe.**

Modifying `ref.current` inside the render function violates React's rendering model - renders should be pure. `ref.current` modifications during render can cause inconsistencies in Concurrent Mode where React may render the same component multiple times before committing. Read refs in event handlers and useEffect (after commit); do not write to them during render.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: ref.current is null on first render when the element hasn't mounted.**

Symptom: `ref.current` is null when accessed in useEffect or event handler immediately after component mounts; null reference error. Root cause: refs are populated AFTER the component commits to the DOM. Accessing `ref.current` during initial render (in the function body, not in effects/handlers) always returns null. Diagnosis: add `console.log(ref.current)` in render vs in useEffect. Fix: access `ref.current` inside useEffect (after mount) or event handlers (after user interaction), never in the render function body.

**Failure Mode 2: Using state instead of ref for values that should not trigger re-renders.**

Symptom: interval timer fires cause unnecessary re-renders updating the UI; logging of render counts shows excessive renders for internal tracking values. Root cause: using useState for a timer ID, abort controller, or animation frame ID that only needs to persist across renders without affecting the UI. Fix: use useRef for values that need to persist but should not trigger re-renders: `const timerRef = useRef(null); timerRef.current = setInterval(fn, 1000);`.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| useRef vs useState | 2-3 min | Re-render behavior |
| DOM access pattern | 2-3 min | Focus, measure |
| Mutable instance variable | 2-3 min | Timer ID storage |
| Latest ref pattern | 3-4 min | Stale closure fix |
| forwardRef usage | 3-4 min | Expose DOM to parent |
| useRef vs useCallback | 2-3 min | Difference |
| Previous value comparison | 2-3 min | useEffect without re-render |

---

**Q1: When should you use useRef instead of useState?** `[SENIOR]`
DECISION

> **Answer:**
>
> > Use `useRef` when you need a value to persist across renders but
> > changing it should NOT cause a re-render.
> >
> > Decision rule:
> > - Does changing this value need to update the UI? -> `useState`
> > - Is this value used only in event handlers/effects (not in render)? -> `useRef`
> >
> > Common ref use cases:
> > - Timer/interval IDs (stored for cleanup)
> > - Previous prop/state comparison (doesn't affect render)
> > - Scroll position tracking (read only)
> > - Third-party library instances (D3, map instances)
> > - The "latest" value of a callback (stale closure workaround)
> >
> > ```javascript
> > // STATE: value drives the UI
> > const [inputValue, setInputValue] = useState('');
> > return <input value={inputValue} onChange={e => setInputValue(e.target.value)} />;
> >
> > // REF: value doesn't drive the UI (just used in cleanup)
> > const timerRef = useRef(null);
> > const startTimer = () => {
> >   timerRef.current = setTimeout(action, 1000);
> > };
> > const cancelTimer = () => clearTimeout(timerRef.current);
> > ```
>
> *What separates good from great:* The distinction "does this trigger
> a re-render?" is the decision axis. Using state for values that don't
> affect render causes unnecessary re-renders. Using ref for values that
> DO affect render causes stale UI (UI doesn't update when ref changes).
> The correct mental model: `useState` = render reactive value, `useRef` =
> render-invisible mutable slot.

---

---

# Event Handling in React

🎯 **Interview Weight:** foundational (★☆☆) - event handling is asked in
every React junior/mid interview; synthetic events and bubbling matter

---

### 🎯 Model Answer

**30 seconds:**

> React uses synthetic events: cross-browser wrappers around native DOM events.
> Events use camelCase (`onClick`, `onChange`, `onSubmit`). Event handlers
> receive a synthetic event object with the same API as native events.
> React 17+ uses event delegation to the root element (not document).
> Stop propagation: `e.stopPropagation()`. Prevent default: `e.preventDefault()`.

**3 minutes:**

> React's event system normalizes browser differences. Key behaviors:
> - `onChange` in React fires on every keystroke (unlike HTML's change,
>   which fires on blur)
> - `onInput` is equivalent to HTML's input event (React maps onChange
>   to the native input event for inputs)
> - Synthetic events are pooled in React 16 and earlier (accessing them
>   async required `e.persist()`). React 17+ removed pooling - no `persist()` needed.
> - Form submission: `<form onSubmit={handleSubmit}>` + `e.preventDefault()` to
>   prevent page reload.

**Blank Mind Recovery:**

**(1) Restate:** "React: synthetic events (camelCase: onClick, onChange).
onChange fires on every keystroke. e.preventDefault() stops default.
e.stopPropagation() stops bubbling. React 17+: no event pooling, no persist().
Delegation to root element."

---

### 📘 Concept Explanation

**What it is:**

React's event system wraps native DOM events in SyntheticEvent objects
for cross-browser normalization. Events attach using JSX camelCase
attributes and receive the SyntheticEvent as the first argument.

**How it works:**

```jsx
// BASIC EVENT HANDLING:
function Button() {
  function handleClick(event) {
    event.preventDefault(); // prevent anchor navigation, form submit
    event.stopPropagation(); // stop event from bubbling to parent
    console.log(event.target);     // the element that was clicked
    console.log(event.currentTarget); // the element with the handler
  }
  return <button onClick={handleClick}>Click me</button>;
}

// FORM HANDLING:
function LoginForm() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  function handleSubmit(e) {
    e.preventDefault(); // prevent page reload!
    login({ email, password });
  }

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={e => setEmail(e.target.value)}
      />
      <input
        type="password"
        value={password}
        onChange={e => setPassword(e.target.value)}
      />
      <button type="submit">Login</button>
    </form>
  );
}

// PASSING ARGUMENTS TO EVENT HANDLERS:
function TodoList({ todos, onDelete }) {
  return (
    <ul>
      {todos.map(todo => (
        <li key={todo.id}>
          {todo.text}
          {/* Arrow function creates new function each render (acceptable here) */}
          <button onClick={() => onDelete(todo.id)}>Delete</button>
          {/* OR: using data attributes (no new function per render) */}
          <button
            data-id={todo.id}
            onClick={e => onDelete(e.currentTarget.dataset.id)}
          >
            Delete
          </button>
        </li>
      ))}
    </ul>
  );
}

// EVENT DELEGATION (React 17+):
// React attaches ONE event listener to the root element
// All React events bubble up to this single listener
// This is why e.stopPropagation() may not work as expected
// with non-React event listeners outside the React tree

// KEYBOARD EVENTS:
function SearchInput({ onSearch }) {
  function handleKeyDown(e) {
    if (e.key === 'Enter') {
      onSearch(e.target.value);
    }
    if (e.key === 'Escape') {
      e.target.value = '';
    }
  }
  return <input type="text" onKeyDown={handleKeyDown} />;
}
```

**Why it matters:**

Understanding React's event delegation model is critical for debugging
integration with non-React code (jQuery plugins, vanilla JS event listeners).
Since React 17, events attach to the root React container, not `document` -
this changes how `stopPropagation()` interacts with handlers outside React.

---

### 💻 Code Example

```jsx
// COMMON MISTAKE: event handler with async and stale event
// BAD: accessing event after async operation (React 16)
function handleClick(e) {
  fetchData().then(() => {
    console.log(e.target.value); // null! Event was nullified (pooling)
  });
}

// GOOD for React 16: persist the event
function handleClick(e) {
  e.persist();
  fetchData().then(() => {
    console.log(e.target.value); // works
  });
}

// React 17+: pooling removed, no persist() needed
function handleClick(e) {
  fetchData().then(() => {
    console.log(e.target.value); // works in React 17+
  });
}

// BEST: capture value immediately (works all versions)
function handleChange(e) {
  const value = e.target.value; // capture before async
  fetchSuggestions(value).then(setSuggestions);
}
```

> **Code walkthrough:** In React 16, SyntheticEvent objects were reused
> (pooled) for performance. After an event handler returned, the event
> was "nullified" (all properties set to null). Accessing event properties
> in async callbacks caused "null" errors. `e.persist()` opted out of
> pooling for that event. React 17 removed pooling entirely (modern browsers
> make it unnecessary), so `persist()` is now a no-op. The safest pattern
> across all React versions: capture needed values into local variables
> immediately in the handler before any async operations.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> React event handlers use camelCase names and receive a SyntheticEvent
> object. Call `e.preventDefault()` to prevent default browser behavior
> (like form submission reloading the page). Call `e.stopPropagation()`
> to prevent the event from bubbling to parent elements. For forms, always
> use `e.preventDefault()` in the submit handler and control input values
> with state and `onChange`.

**Senior / Staff:**

> React's event system uses delegation - one listener at the root container.
> This changed in React 17 from attaching to `document` to attaching to
> the root element, enabling multiple React versions on one page (the
> micro-frontend scenario). The `e.stopPropagation()` behavior is subtly
> different: it stops propagation to parent React handlers AND native
> handlers on the root element, but won't stop native handlers registered
> below the root. Understanding this is critical for integrating React
> with jQuery or legacy code: if a jQuery handler is registered on a parent
> element, React's `stopPropagation()` may or may not stop it depending
> on where in the event flow it's attached.

---

### ⚠️ Common Misconceptions

**Misconception 1: React event handlers directly attach to DOM elements like addEventListener.**

React uses event delegation: a single event listener is attached at the root container, not to each individual element. When a click event fires, React's root listener catches it and dispatches to the appropriate component handler. This is why `stopPropagation()` in a React handler stops React's synthetic event propagation but NOT the original native DOM event from propagating. React 17+ changed the root from `document` to the React root container to enable multiple React roots on the same page.

**Misconception 2: Creating a new function in JSX for event handlers always causes performance problems.**

Creating inline arrow functions in JSX (`onClick={() => doSomething()}`) creates a new function reference on every render. This only causes measurable performance issues when: the function is passed to a child component wrapped in `React.memo()` (breaking memoization), or the function is a dependency of `useEffect` or `useMemo` (causing unnecessary re-executions). For most event handlers, inline arrow functions are perfectly fine.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Calling a function directly instead of passing it as a callback causes immediate execution.**

Symptom: function executes immediately on render, not on user click; every render triggers the side effect instead of user interaction. Root cause: `onClick={handleClick()}` - the `()` calls the function immediately and passes its return value as the handler. Diagnosis: verify the event fires on render, not on click. Fix: pass a reference without calling: `onClick={handleClick}`, or wrap in an arrow function if arguments are needed: `onClick={() => handleClick(id)}`.

**Failure Mode 2: Event handler captures stale state from closure.**

Symptom: event handler reads an outdated value that was current when the component last rendered; incrementing counter shows wrong value when clicks are rapid. Root cause: event handler is a closure over state/props at the time of render; if the component re-renders between event registrations and the event firing, the handler has a stale value. Fix: use the functional updater form (`setState(prev => prev + 1)`) or useRef to track the latest state value.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| Synthetic events | 2-3 min | Browser normalization |
| preventDefault usage | 2-3 min | Form submission |
| stopPropagation | 2-3 min | Bubbling control |
| onChange vs onInput | 2-3 min | React normalization |
| Event delegation model | 3-4 min | Root attachment |
| Passing arguments | 2-3 min | Arrow function in JSX |
| React 17 pooling change | 2-3 min | No persist needed |

---

**Q1: How does React's event system differ from native DOM events?**
`[SENIOR]` MECHANISM

> **Answer:**
>
> > React uses synthetic events (SyntheticEvent) as wrappers around native
> > DOM events, with these key differences:
> >
> > 1. **Delegation**: Native events attach per element. React attaches
> >    ONE handler at the root React container element. All React events
> >    bubble up to this one handler (React 17+; previously to document).
> >
> > 2. **Normalization**: React normalizes browser differences. The same
> >    `onChange` handler works for input, select, textarea across all
> >    browsers. `onChange` fires on every keystroke for input (mapped
> >    to native `input` event), not just on blur.
> >
> > 3. **Pooling (pre-React 17)**: SyntheticEvent objects were reused.
> >    React 17+ removed this - synthetic events are plain objects now.
> >
> > 4. **Async access**: Because React 17+ doesn't pool events, you can
> >    safely access event properties in async callbacks without `persist()`.
> >
> > Practical implication: to attach native events (e.g., to `window`),
> > use `addEventListener` in `useEffect`. For React tree events, use
> > JSX handlers. Don't mix them for the same behavior.
>
> *What separates good from great:* The React 17 event delegation change
> (from document to root container) is the key architectural change that
> enables micro-frontends and multiple React versions on one page.
> Before React 17, two React instances would conflict because both
> attached to `document`. After React 17, each attaches to its own root.
