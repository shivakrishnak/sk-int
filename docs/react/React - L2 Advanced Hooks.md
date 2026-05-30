---
layout: default
title: "React - L2 Advanced Hooks"
parent: "React"
nav_order: 4
permalink: /react/l2-advanced-hooks/
render_with_liquid: false
---

# useMemo and useCallback Optimization

🎯 **Interview Weight:** working (★★☆) - premature optimization with these
hooks is a common mistake; knowing when to use and when NOT to use is tested

---

### 🎯 Model Answer

**30 seconds:**

> `useMemo` memoizes a computed value - recomputes only when deps change.
> `useCallback` memoizes a function reference - recreates only when deps
> change. Both exist for performance optimization ONLY: skip expensive
> recomputation (`useMemo`) and prevent child re-renders (`useCallback`
> + `React.memo`). The rule: don't use them by default - profile first,
> memoize only when you have a measurable performance issue.

**3 minutes:**

> When to use each:
> - `useMemo`: when computation is genuinely expensive (filter/sort of
>   large arrays, complex derived data) or when object identity matters
>   for a dependency array downstream.
> - `useCallback`: when passing a callback to a `React.memo` child (prevents
>   unnecessary re-renders) or when the callback is a dependency in
>   another `useMemo`/`useCallback`.
>
> Both are premature optimization anti-patterns when overused:
> memoization has a cost (memory + comparison on every render). For
> components that re-render with the same data, the cost of memoization
> can exceed the cost of just re-rendering.

**Blank Mind Recovery:**

**(1) Restate:** "useMemo: memoize expensive computed value. useCallback:
memoize function reference for stable deps/memo children. Both: performance
ONLY - profile first. Never memoize everything blindly. Cost: memory +
comparison. React.memo needed for useCallback to help."

---

### 📘 Concept Explanation

**What it is:**

`useMemo` and `useCallback` are performance hooks. `useMemo` caches the
result of a computation. `useCallback` caches a function reference.
Both return cached values until their dependency arrays change.

**The problem they solve:**

Without memoization, every render:
- Recomputes derived values (even if inputs didn't change)
- Creates new function references (causing children with `React.memo`
  to re-render because their props changed - even though the function
  logic didn't)

**How they work:**

```jsx
import { useMemo, useCallback, memo } from 'react';

// useMemo: expensive computation
function ProductList({ products, searchQuery }) {
  // WRONG: no memoization (refilters on every render)
  const filtered = products.filter(p =>
    p.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  // RIGHT: only refilter when products or searchQuery change
  const filteredProducts = useMemo(
    () => products.filter(p =>
      p.name.toLowerCase().includes(searchQuery.toLowerCase())
    ),
    [products, searchQuery] // deps: only recompute when these change
  );

  return <ul>{filteredProducts.map(p => <li key={p.id}>{p.name}</li>)}</ul>;
}

// useCallback: stable function reference for memo children
const ProductItem = memo(function ProductItem({ product, onDelete }) {
  console.log('ProductItem render:', product.id);
  return (
    <li>
      {product.name}
      <button onClick={() => onDelete(product.id)}>Delete</button>
    </li>
  );
});

function ProductList({ products }) {
  const [deleted, setDeleted] = useState(new Set());

  // WRONG: new function reference every render -> all ProductItems re-render
  const handleDelete = (id) => setDeleted(d => new Set([...d, id]));

  // RIGHT: stable reference -> ProductItems only re-render if handleDelete changes
  const handleDelete = useCallback(
    (id) => setDeleted(d => new Set([...d, id])),
    [] // no deps: setDeleted is stable (from useState)
  );

  return (
    <ul>
      {products
        .filter(p => !deleted.has(p.id))
        .map(p => (
          <ProductItem
            key={p.id}
            product={p}
            onDelete={handleDelete}
          />
        ))
      }
    </ul>
  );
}

// WHEN NOT TO MEMOIZE:
// Simple components that re-render cheaply
function Label({ text }) {
  // useMemo here is waste: returning JSX is already cheap
  return useMemo(() => <span>{text}</span>, [text]); // BAD
  // Just return it directly:
  return <span>{text}</span>; // GOOD
}
```

**Why it matters:**

The most common React performance anti-pattern is adding `useMemo` and
`useCallback` everywhere "to be safe." This is counterproductive: every
memo adds memory usage and comparison cost. The correct approach: measure
first (React DevTools Profiler), then memoize specific bottlenecks.

**Mental model:**

> `useMemo` and `useCallback` are like caching layers. A cache only helps
> if the cache lookup is cheaper than recomputation AND if the data is
> frequently reused. A cache that's invalidated on every request adds
> overhead without benefit. Same principle: only cache what's expensive
> to compute or what has a measurable downstream effect.

---

### 💻 Code Example

```jsx
// PROFILE BEFORE MEMOIZING:
// React DevTools Profiler shows which components are slow

// EXAMPLE: genuinely expensive computation (worth memoizing)
function DataGrid({ data, sortConfig }) {
  // This sort runs on every keystroke if in a parent with input state
  const sortedData = useMemo(() => {
    console.time('sort');
    const result = [...data].sort((a, b) => {
      if (sortConfig.direction === 'asc')
        return a[sortConfig.key] > b[sortConfig.key] ? 1 : -1;
      return a[sortConfig.key] < b[sortConfig.key] ? 1 : -1;
    });
    console.timeEnd('sort');
    return result;
  }, [data, sortConfig.key, sortConfig.direction]);
  // Only re-sort when data or sort config changes
  // Not when parent re-renders due to unrelated state (e.g., search input)

  return <table>{sortedData.map(row => <Row key={row.id} data={row} />)}</table>;
}

// useCallback TRAP: memoizing but memo child doesn't use it
function Parent() {
  const handleClick = useCallback(() => {
    doSomething();
  }, []); // stable reference

  // Problem: ChildComponent is NOT wrapped in React.memo
  // useCallback has zero benefit here - child re-renders anyway
  return <ChildComponent onClick={handleClick} />;
}
// Rule: useCallback is only useful if the consumer is wrapped in React.memo
// or if the callback is a dep in another memoized hook
```

> **Code walkthrough:** The DataGrid example shows genuine `useMemo` value:
> sorting a large array is O(n log n) - expensive for 1000+ rows. Without
> memoization, typing in an unrelated search input (which causes the parent
> to re-render) would re-sort the entire table on each keystroke. The
> `useMemo` ensures the sort only runs when data or sort config changes.
> The `useCallback` trap shows the most common mistake: adding `useCallback`
> without `React.memo` on the child provides zero benefit. The function
> reference is stable, but the child re-renders for other reasons (like
> parent state changes), making the optimization pointless.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `useMemo` caches a computed value and only recalculates when dependencies
> change. `useCallback` caches a function reference. Both are for performance
> optimization. The common use case: `useCallback` with a child wrapped
> in `React.memo` - without useCallback, the child re-renders every time
> the parent renders because it gets a new function reference each time.

**Senior / Staff:**

> The critical insight: `useMemo` and `useCallback` have costs (memory,
> comparison on every render) that only pay off under specific conditions.
> `useCallback` only helps when (a) the consumer is `React.memo` wrapped,
> OR (b) the function is a dependency in another hook. `useMemo` only
> helps when (a) the computation is genuinely expensive (>1ms), OR (b)
> the result is used as a dependency elsewhere and object identity matters.
> The "memoize everything" pattern is a common senior React mistake - it
> adds overhead without measurement. React Compiler (React 19 experimental)
> automatically memoizes at the compiler level, which will make manual
> `useMemo`/`useCallback` largely obsolete.

---

### ⚖️ Comparison Table

| Hook | What it memoizes | When to use | Cost |
|---|---|---|---|
| `useMemo` | Computed value | Expensive computation | Memory + comparison |
| `useCallback` | Function reference | Memo child / hook dep | Memory + comparison |
| `React.memo` | Component render | Child with stable props | Comparison per render |
| No memoization | Nothing | 99% of components | None |

---

### ⚠️ Common Misconceptions

**Misconception 1: useMemo and useCallback should be used on every computed value and function.**

useMemo and useCallback have a cost: memory (storing the memoized value), computation (comparing dependencies), and cognitive overhead. They are beneficial only when: the memoized value is computationally expensive AND the dependencies change less frequently than the component renders, OR the value is passed as a prop to a `React.memo()`-wrapped child component. Wrapping simple string concatenations or trivial operations in useMemo adds overhead without benefit.

**Misconception 2: useMemo prevents a child component from re-rendering.**

useMemo prevents re-computation of the memoized VALUE. Whether the child re-renders depends on whether the child is wrapped in `React.memo()` AND whether the memoized value is passed as a prop. useMemo in the parent + no React.memo on child = child still re-renders on parent re-render. React.memo on child + new function reference on every render = child still re-renders. Both are needed together: useMemo/useCallback + React.memo.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Object created in useMemo is mutated, bypassing memoization.**

Symptom: memoized object behaves inconsistently; state that should be stable changes unexpectedly. Root cause: consumer of the memoized object mutates it directly; next render returns the same reference (correctly memoized), but the content was mutated. Diagnosis: check all usages of the memoized value for mutations. Fix: return new objects from useMemo rather than mutating; freeze returned objects with Object.freeze() in development to catch mutations early.

**Failure Mode 2: useCallback dependency array is missing a dependency causing stale closure.**

Symptom: callback reads a stale value from when it was created; editing a form field whose value the callback reads results in the callback using the original value. Root cause: `useCallback` with missing dependencies - the function is not recreated when values it depends on change. Diagnosis: add exhaustive-deps ESLint rule (from eslint-plugin-react-hooks); it catches missing dependencies. Fix: add all values used inside the callback to the dependency array.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| useMemo vs useCallback | 2-3 min | Value vs function |
| When NOT to memoize | 3-4 min | Premature optimization |
| useCallback + React.memo pair | 3-4 min | Full pattern |
| Dependency arrays | 2-3 min | Exhaustive deps |
| React DevTools profiling | 3-4 min | Measure first |
| React Compiler (future) | 2-3 min | Auto-memoization |
| Object identity in deps | 3-4 min | useMemo for deps |

---

**Q1: Explain the relationship between useCallback, React.memo, and
re-renders.** `[SENIOR]` MECHANISM

> **Answer:**
>
> > ```jsx
> > // THE CHAIN: all three required for optimization to work
> > //
> > // 1. React.memo: skip re-render if props are shallowly equal
> > const Child = React.memo(function Child({ onClick, data }) {
> >   console.log('Child rendered');
> >   return <button onClick={onClick}>{data}</button>;
> > });
> >
> > // 2. Without useCallback: Child re-renders every parent render
> > function Parent() {
> >   const [count, setCount] = useState(0);
> >   const handleClick = () => console.log('clicked'); // new fn each render
> >   return (
> >     <>
> >       <button onClick={() => setCount(c => c + 1)}>+</button>
> >       <Child onClick={handleClick} data="static" />
> >       // Child re-renders on every click (onClick is a new function)
> >     </>
> >   );
> > }
> >
> > // 3. With useCallback: Child skips re-render
> > function Parent() {
> >   const [count, setCount] = useState(0);
> >   const handleClick = useCallback(() => console.log('clicked'), []);
> >   return (
> >     <>
> >       <button onClick={() => setCount(c => c + 1)}>+</button>
> >       <Child onClick={handleClick} data="static" />
> >       // Child does NOT re-render when count changes
> >     </>
> >   );
> > }
> > ```
> >
> > The optimization requires BOTH: `React.memo` on the child
> > (opt in to prop comparison) AND `useCallback` on the parent
> > (provide stable reference). Either alone is insufficient.
>
> *What separates good from great:* This is a common interview question.
> The "both required" insight is the signal. Many developers add only
> `React.memo` or only `useCallback` and wonder why the optimization
> doesn't work. `React.memo` does the comparison but needs stable props.
> `useCallback` provides stable props but child must check for changes.
> Together, they form the full memoization optimization chain.

---

---

# Custom Hooks

🎯 **Interview Weight:** working (★★☆) - custom hooks show React abstraction
maturity; designing a good custom hook API is tested at mid/senior level

---

### 🎯 Model Answer

**30 seconds:**

> Custom hooks are functions that start with `use` and call other hooks.
> They extract stateful logic from components into reusable functions
> WITHOUT creating component hierarchy. Custom hooks enable sharing logic
> (like data fetching, form management, subscriptions) across multiple
> components. Key rule: if you need to share behavior (not UI), extract
> to a custom hook.

**3 minutes:**

> Custom hooks return whatever is needed by the consumer - state, functions,
> refs, or any combination. The naming convention `use*` is not just style:
> it tells React's linter that this function follows hooks rules and
> should be checked for hooks-in-conditions violations.
>
> Design principles for good hooks: (1) single responsibility - do one
> thing, (2) return what callers need (not more), (3) stable API (callers
> shouldn't break when hook internals change), (4) testable in isolation
> with `renderHook`.

**Blank Mind Recovery:**

**(1) Restate:** "Custom hooks: function starting with 'use' that calls
other hooks. Extracts reusable stateful logic (not UI). Returns state +
actions. Single responsibility. testable with renderHook."

---

### 📘 Concept Explanation

**What it is:**

Custom hooks are regular JavaScript functions that call React hooks.
They enable extracting component logic into reusable units. The `use`
prefix is the convention that signals React's rules-of-hooks apply.

**How it works:**

```jsx
// PATTERN: extract data fetching logic
// Before: data fetching logic in component
function UserProfile({ userId }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    fetchUser(userId)
      .then(data => { if (!cancelled) { setUser(data); setLoading(false); } })
      .catch(err => { if (!cancelled) { setError(err); setLoading(false); } });
    return () => { cancelled = true; };
  }, [userId]);

  if (loading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;
  return <Profile user={user} />;
}

// After: extracted to custom hook (reusable)
function useUser(userId) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    fetchUser(userId)
      .then(data => {
        if (!cancelled) { setUser(data); setLoading(false); }
      })
      .catch(err => {
        if (!cancelled) { setError(err); setLoading(false); }
      });
    return () => { cancelled = true; };
  }, [userId]);

  return { user, loading, error };
}

// Clean component:
function UserProfile({ userId }) {
  const { user, loading, error } = useUser(userId);
  if (loading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;
  return <Profile user={user} />;
}

// Multiple components reuse the same logic:
function UserAvatar({ userId }) {
  const { user, loading } = useUser(userId);
  if (loading) return <AvatarSkeleton />;
  return <img src={user.avatarUrl} alt={user.name} />;
}

// REAL-WORLD CUSTOM HOOKS:

// useLocalStorage: persist state in localStorage
function useLocalStorage(key, initialValue) {
  const [value, setValue] = useState(() => {
    try {
      const item = localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setStoredValue = useCallback((newValue) => {
    setValue(newValue);
    localStorage.setItem(key, JSON.stringify(newValue));
  }, [key]);

  return [value, setStoredValue];
}

// useDebounce: delay state updates
function useDebounce(value, delay) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);
  return debounced;
}

// Usage:
function SearchInput() {
  const [query, setQuery] = useState('');
  const debouncedQuery = useDebounce(query, 300);
  // Only search when user stops typing for 300ms
  const { data } = useQuery(['search', debouncedQuery], () =>
    searchAPI(debouncedQuery)
  );
}
```

**Why it matters:**

Custom hooks are the primary code reuse mechanism in React. Understanding
how to design them well (what to extract, what to return, how to handle
cleanup) is the mark of a senior React developer. Poorly designed hooks
create tight coupling and hard-to-test code.

---

### 💻 Code Example

```jsx
// TESTING CUSTOM HOOKS: renderHook
import { renderHook, act } from '@testing-library/react';

// Hook to test:
function useCounter(initialValue = 0) {
  const [count, setCount] = useState(initialValue);
  const increment = useCallback(() => setCount(c => c + 1), []);
  const decrement = useCallback(() => setCount(c => c - 1), []);
  const reset = useCallback(() => setCount(initialValue), [initialValue]);
  return { count, increment, decrement, reset };
}

// Test:
test('useCounter increments and resets', () => {
  const { result } = renderHook(() => useCounter(5));

  expect(result.current.count).toBe(5);

  act(() => result.current.increment());
  expect(result.current.count).toBe(6);

  act(() => result.current.reset());
  expect(result.current.count).toBe(5);
});
// Hooks can be tested in isolation without a real component
```

> **Code walkthrough:** `renderHook` from React Testing Library creates a
> minimal component wrapper that renders the hook. `result.current`
> contains the hook's return value. `act()` wraps state updates to ensure
> React processes them before assertions. This pattern tests the hook's
> behavior in isolation - no UI rendering required. `useCallback` on the
> action functions ensures they're stable references (important for
> components using React.memo with these callbacks as props).

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Custom hooks are functions that start with `use` and can call other
> hooks. They extract reusable logic from components. For example, instead
> of writing the same data fetching code in multiple components, you extract
> it into `useFetch(url)` and call it from any component that needs it.
> Custom hooks can hold state, call useEffect, and return whatever the
> component needs.

**Senior / Staff:**

> Custom hooks are the primary mechanism for composing behavior in React.
> Good hook design: single responsibility, stable API that doesn't expose
> internals, returns exactly what callers need (no more). The hook
> interface is a contract - callers bind to the return shape. Hook
> composition (hooks calling hooks) enables building complex behaviors
> from simple primitives. Test with `renderHook` to verify behavior in
> isolation. Common mistakes: making hooks too generic (a hook for everything)
> or too specific (a hook for one component), and not handling cleanup
> (memory leaks from subscriptions).

---

### ⚖️ Comparison Table

| Approach | Reuse | UI | State | Hooks |
|---|---|---|---|---|
| Custom hook | Logic | No | Yes | Yes |
| Component | UI + logic | Yes | Yes | Yes |
| Utility function | Logic | No | No | No |
| Context | Shared state | Optional | Yes | Yes |
| Render prop | Logic | Optional | Yes | Yes |

---

### ⚠️ Common Misconceptions

**Misconception 1: Custom hooks must return JSX.**

Custom hooks are functions that use React hooks internally and share stateful logic between components - they do NOT return JSX. A hook returns data, state, and handlers: `useFormInput` returns `{ value, onChange }`; `useFetch` returns `{ data, loading, error }`. Components consume hooks to get the state and event handlers they need, then render JSX using those values. Hooks compose logic; components compose UI.

**Misconception 2: Custom hooks are only useful for reusing logic across multiple components.**

Custom hooks also improve single-use component code by extracting complex logic from the component body. A component with 150 lines of useEffect, useState, and event handler logic is hard to read. Extracting to a custom hook even if only used in one place makes the component body declarative: `const { items, addItem, removeItem } = useShoppingCart(userId)` vs 50 lines of state and effect logic inline.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Custom hook violates the Rules of Hooks causing runtime error.**

Symptom: "React Hook cannot be called inside a callback" or "React Hook is called conditionally" error. Root cause: hook called inside an `if` statement, a loop, or a nested function rather than at the top level of a component or hook. Diagnosis: check the call site; verify the hook is not inside any conditional or iteration. Fix: extract the conditional logic OUT of the hook call; call hooks unconditionally at the top level and use condition-based logic inside the hook body.

**Failure Mode 2: Hook state isolation breaks when the same hook is used in sibling components.**

Symptom: two instances of the same component that use the same custom hook do not share state; changes in one instance are not visible in the other. Root cause: this is the EXPECTED behavior - each component instance has its own state. If you want shared state across components, the state must be lifted to a common ancestor or managed in a shared store (Context, Zustand, etc.). Fix: if state should be shared, lift to a parent component or use a shared store; if state should be isolated per instance, the current behavior is correct.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| What is a custom hook | 2-3 min | Logic reuse (not UI) |
| Design a useFetch hook | 5-7 min | Cleanup, race conditions |
| Test a custom hook | 3-4 min | renderHook |
| Custom hook vs utility function | 2-3 min | Hooks rules |
| Hook API design | 3-4 min | Return shape |
| Composition of hooks | 3-4 min | Hooks calling hooks |
| When NOT to extract to hook | 2-3 min | Single-use logic |
| useLocalStorage implementation | 4-5 min | SSR safety |
| useDebounce implementation | 4-5 min | Cleanup timer |

---

**Q1: Design a useAsync hook for handling async operations.** `[SENIOR]`
LIVE CODING

> **Answer:**
>
> ```jsx
> function useAsync(asyncFn, deps) {
>   const [state, setState] = useState({
>     status: 'idle', // idle | pending | success | error
>     data: null,
>     error: null
>   });
>
>   useEffect(() => {
>     let cancelled = false;
>     setState({ status: 'pending', data: null, error: null });
>
>     asyncFn()
>       .then(data => {
>         if (!cancelled) {
>           setState({ status: 'success', data, error: null });
>         }
>       })
>       .catch(error => {
>         if (!cancelled) {
>           setState({ status: 'error', data: null, error });
>         }
>       });
>
>     return () => { cancelled = true; };
>   }, deps); // eslint-disable-line react-hooks/exhaustive-deps
>
>   return {
>     isIdle:    state.status === 'idle',
>     isPending: state.status === 'pending',
>     isSuccess: state.status === 'success',
>     isError:   state.status === 'error',
>     data:      state.data,
>     error:     state.error
>   };
> }
>
> // Usage:
> function UserProfile({ userId }) {
>   const { isPending, isError, data: user } = useAsync(
>     () => fetchUser(userId),
>     [userId]
>   );
>   if (isPending) return <Spinner />;
>   if (isError) return <Error />;
>   return <Profile user={user} />;
> }
> ```
>
> *What separates good from great:* Using a discriminated union for
> status (`idle | pending | success | error`) prevents impossible states
> (`status: 'success', error: new Error(...)` can't happen). The `cancelled`
> flag handles the race condition when deps change before the promise
> resolves. The hook derives boolean flags from the status string for
> cleaner consumer API. For production: use TanStack Query instead of
> building this, but demonstrating this implementation shows deep hooks
> understanding.
