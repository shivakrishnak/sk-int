---
layout: default
title: "React - L3 Forms and Data"
parent: "React"
nav_order: 9
permalink: /react/l3-forms-and-data/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Controlled vs Uncontrolled Components](#controlled-vs-uncontrolled-components) | intermediate |
| 2 | [React Query and Server-State Management](#react-query-and-server-state-management) | intermediate |
| 3 | [React Performance Optimization Techniques](#react-performance-optimization-techniques) | intermediate |
| 4 | [React.memo and Re-render Prevention](#reactmemo-and-re-render-prevention) | intermediate |
| 5 | [React Router and Client-side Routing](#react-router-and-client-side-routing) | working |
| 6 | [Dynamic Routing and Code Splitting](#dynamic-routing-and-code-splitting) | working |
| 7 | [Higher-Order Components](#higher-order-components) | working |
| 8 | [Render Props and Compound Components](#render-props-and-compound-components) | working |

---

# Controlled vs Uncontrolled Components

🎯 **Interview Weight:** intermediate (★★☆) - foundational form concept;
controlled is the React way; knowing when to use uncontrolled is senior signal

---

### 🎯 Model Answer

**30 seconds:**

> Controlled component: React state is the source of truth for form input
> values. Every keystroke calls `onChange` -> `setState` -> re-render.
> Uncontrolled: the DOM manages input state; React reads it via a `ref`
> when needed. Controlled gives full control (validation, transforms,
> conditional logic). Uncontrolled is simpler for one-off file inputs and
> situations where you only need the value on submit, not on every change.

**3 minutes:**

> Controlled components enable: instant validation feedback, dependent
> field logic (city depends on country), format-as-you-type (phone numbers),
> disabled submit until form is valid. The cost: every keystroke triggers
> a re-render of the form component. For large, complex forms this can
> be slow - React Hook Form solves this by using uncontrolled inputs with
> refs internally, calling re-renders only on field register/errors.
> File inputs (`<input type="file">`) are always uncontrolled because you
> cannot set their value from JS (security restriction).

**Blank Mind Recovery:**

**(1) Restate:** "Controlled: state is source of truth, onChange -> setState.
Uncontrolled: DOM is source of truth, ref to read value. Controlled: validation,
transform, conditional. Uncontrolled: simpler, file inputs, React Hook Form
uses internally. File inputs always uncontrolled."

---

### 📘 Concept Explanation

**What it is:**

The controlled vs uncontrolled distinction determines which system -
React state or the browser DOM - is the authoritative source of truth
for form input values.

**How it works:**

```jsx
// CONTROLLED COMPONENT
function ControlledForm() {
  const [email, setEmail] = useState('');
  const [error, setError] = useState('');

  function handleChange(e) {
    const val = e.target.value;
    setEmail(val);
    // Validate on every keystroke
    setError(val.includes('@') ? '' : 'Invalid email');
  }

  function handleSubmit(e) {
    e.preventDefault();
    if (!error) submitForm({ email });
  }

  return (
    <form onSubmit={handleSubmit}>
      {/* value + onChange = controlled */}
      <input
        type="email"
        value={email}        // React state is source of truth
        onChange={handleChange}
        aria-invalid={!!error}
        aria-describedby="email-error"
      />
      {error && <span id="email-error">{error}</span>}
      <button type="submit" disabled={!!error || !email}>
        Submit
      </button>
    </form>
  );
}

// UNCONTROLLED COMPONENT
function UncontrolledForm() {
  const emailRef = useRef(null);

  function handleSubmit(e) {
    e.preventDefault();
    // Read DOM value only on submit
    const email = emailRef.current.value;
    if (email.includes('@')) submitForm({ email });
  }

  return (
    <form onSubmit={handleSubmit}>
      {/* ref = uncontrolled - no value or onChange */}
      <input type="email" ref={emailRef} defaultValue="" />
      <button type="submit">Submit</button>
    </form>
  );
}

// FILE INPUT: always uncontrolled (security restriction)
function FileUpload() {
  const fileRef = useRef(null);

  function handleUpload() {
    const file = fileRef.current.files[0];
    // Cannot do: setFile(someFileObject) and reflect in input
    uploadFile(file);
  }

  return (
    <div>
      <input type="file" ref={fileRef} accept="image/*" />
      <button onClick={handleUpload}>Upload</button>
    </div>
  );
}

// REACT HOOK FORM: uncontrolled under the hood, controlled API on top
import { useForm } from 'react-hook-form';

function OptimizedForm() {
  const { register, handleSubmit, formState: { errors } } = useForm();

  return (
    <form onSubmit={handleSubmit(data => console.log(data))}>
      {/* register() attaches ref + change handler internally */}
      <input {...register('email', {
        required: 'Email is required',
        pattern: { value: /\S+@\S+\.\S+/, message: 'Invalid email' }
      })} />
      {errors.email && <span>{errors.email.message}</span>}
      <button type="submit">Submit</button>
    </form>
  );
}
```

> **Code walkthrough:** This Controlled vs Uncontrolled Components example demonstrates variable declaration using React hook. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **TAKEAWAY: use Object.freeze() to prevent mutation; const only guards the binding.**

**Why it matters:**

Controlled vs uncontrolled is a React fundamentals question. But knowing
that React Hook Form uses uncontrolled inputs to avoid re-renders on
every keystroke - and that this matters for forms with 50+ fields - is
the senior-level insight.

---

### 💻 Code Example


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```jsx
// BAD: mixing controlled and uncontrolled
function BrokenForm() {
  const [name, setName] = useState(undefined); // undefined initial state!

  return (
    // ERROR: "A component is changing an uncontrolled input to be controlled"
    // React warns when input switches from uncontrolled (value=undefined)
    // to controlled (value="something")
    <input value={name} onChange={e => setName(e.target.value)} />
  );
}

// GOOD: initialize with empty string
function FixedForm() {
  const [name, setName] = useState(''); // empty string, not undefined/null
  return (
    <input value={name} onChange={e => setName(e.target.value)} />
  );
}

// DIAGNOSTIC: "uncontrolled to controlled" React warning
// Cause: initial value is undefined or null
// Fix: initialize state to '' (string inputs) or false (checkboxes)
// or use `value={name ?? ''}` as a fallback
```

> **Code walkthrough:** The `undefined` initial state bug is the mostice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> common controlled component mistake. When `value={undefined}`, React
> treats the input as uncontrolled (the DOM owns the value). When state
> updates to a string, React tries to switch to controlled mode and
> logs a warning. The fix is always initializing state to a defined
> value: `''` for text inputs, `false` for checkboxes, `[]` for
> multi-selects. The `?? ''` fallback handles cases where the initial
> value comes from an API (might be null for new records).

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Controlled components use React state for input values - `value` and
> `onChange` props keep React in sync. Uncontrolled components use a `ref`
> to read the DOM value only when needed, usually on form submit. Controlled
> is the React standard; use uncontrolled for file inputs and when using
> libraries like React Hook Form.

**Senior / Staff:**

> The controlled vs uncontrolled choice has a performance dimension for
> complex forms. Controlled inputs re-render the form component on every
> keystroke. For a form with 50 fields, that's 50 re-renders per character
> typed. React Hook Form solves this elegantly: it uses uncontrolled inputs
> (refs) internally, so typing doesn't trigger re-renders, but exposes a
> controlled-like API for validation and error display. The library only
> triggers re-renders when the validation state changes. For simple forms
> (< 20 fields), controlled is perfectly fine and easier to reason about.
> The signal that you need React Hook Form: noticeable typing lag in a
> large form.

---

### ⚖️ Comparison Table

| Aspect | Controlled | Uncontrolled |
|---|---|---|
| Source of truth | React state | DOM |
| Re-renders | On every keystroke | Only on explicit read |
| Validation | Real-time | On submit |
| File inputs | Not possible | Required |
| Default value | `value=` initial state | `defaultValue=` |
| When to use | Most forms | File upload, RHF |

---

### ⚠️ Common Misconceptions

**Misconception 1: Controlled components are always better than uncontrolled.**

Controlled components (React state drives input value) are appropriate when: form values need to be synchronized with other UI elements, values need validation on every keystroke, or values need to be pre-populated from API data. Uncontrolled components (DOM manages value, read via ref at submit time) are appropriate for: file inputs (always uncontrolled), large forms where keystroke-level validation is unnecessary, and performance-sensitive forms with many fields. React Hook Form uses uncontrolled components by default for better performance at scale.

**Misconception 2: `defaultValue` and `value` props are interchangeable.**

`value` makes a component controlled - React owns the value and the DOM cannot change it without state updates. `defaultValue` makes a component uncontrolled - React sets the INITIAL value but the DOM manages subsequent changes. Switching between controlled and uncontrolled (changing from `value={undefined}` to `value="text"`) after mount triggers a React warning and unpredictable behavior. Decide at design time which model to use.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Warning: A component is changing an uncontrolled input to be controlled.**

Symptom: `Warning: A component is changing an uncontrolled input to be controlled` in console; input behavior becomes erratic. Root cause: input starts with `value={undefined}` (uncontrolled) then receives `value={someString}` (controlled) after the initial render - typically because async data is loaded and `formData.field` starts as undefined. Fix: initialize state with an empty string: `useState({ name: '' })` instead of `useState({})` so the value is always a string, never undefined.

**Failure Mode 2: Form submit reads stale values from uncontrolled form without refs.**

Symptom: form submission sends initial values regardless of what the user typed. Root cause: form values read from state rather than from DOM refs for uncontrolled inputs. Diagnosis: log form values on submit; compare to what was typed. Fix: for uncontrolled forms, read values via `FormData(event.target)` on submit, or use input refs; for controlled forms, ensure onChange handlers update state.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| Define controlled vs uncontrolled | 2-3 min | State vs DOM |
| React "uncontrolled to controlled" warning | 2-3 min | undefined initial value |
| File inputs | 2-3 min | Always uncontrolled |
| React Hook Form approach | 3-4 min | Uncontrolled for perf |
| When controlled is better | 2-3 min | Real-time validation |
| Performance implications | 3-4 min | Re-renders per keystroke |
| defaultValue vs value | 2-3 min | Initial vs controlled |

---

**[SENIOR] Q1 - [DEBUGGING] Your large form has typing lag. What's wrong and how do you fix it?**

> **Answer:**
>
> Typing lag in a controlled form means each keystroke is causing too many
> re-renders or each re-render is too expensive.
>
> ```jsx
> // DIAGNOSIS:
> // 1. React DevTools Profiler: record while typing, look for long renders
> // 2. Check: is validation running expensive operations on every keystroke?
> // 3. Check: are many sibling components re-rendering?
>
> // CAUSE A: expensive validation on every change
> // BAD:
> function handleChange(e) {
>   setValue(e.target.value);
>   // Expensive regex or API call on every keystroke:
>   validateWithServer(e.target.value); // async call per char!
> }
>
> // GOOD: debounce expensive operations
> const debouncedValidate = useCallback(
>   debounce((val) => validateWithServer(val), 300),
>   []
> );
>
> // CAUSE B: many fields, many re-renders
> // Solution: React Hook Form
> import { useForm } from 'react-hook-form';
>
> function LargeForm() {
>   const { register, handleSubmit } = useForm();
>   // Internally uses refs - NO re-renders on keystroke
>   return (
>     <form onSubmit={handleSubmit(onSubmit)}>
>       {Array.from({ length: 50 }, (_, i) => (
>         <input key={i} {...register(`field_${i}`)} />
>       ))}
>     </form>
>   );
> }
> ```
>
> *What separates good from great:* Distinguishing between two different
> causes - expensive per-keystroke side effects vs re-render overhead from
> many controlled fields. The first is fixed with debouncing; the second
> with React Hook Form's uncontrolled approach. Jumping directly to RHF
> without diagnosing might be premature if the issue is a server call
> per keystroke.

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# React Query and Server-State Management

🎯 **Interview Weight:** intermediate (★★☆) - TanStack Query is industry
standard for server state; understanding the client/server state split is key

---

### 🎯 Model Answer

**30 seconds:**

> TanStack Query (React Query) manages server-state: data that lives on
> the server and is fetched asynchronously. It handles caching, background
> refetching, loading/error states, and stale-while-revalidate
> automatically. This removes the need for manual `useEffect` + `useState`
> for data fetching. The key insight: server state is fundamentally
> different from client state (local UI state like modal open/closed).
> Tools: TanStack Query for server state, Zustand/Redux for client state.

**3 minutes:**

> Without React Query, every data-fetching component has the same
> boilerplate: `useState` for data/loading/error, `useEffect` to fetch,
> manual cache invalidation, no background updates. React Query replaces
> all of this. A `useQuery` call fetches data, caches it by query key,
> and re-fetches when the window regains focus or the cache expires.
> `useMutation` handles writes (POST/PUT/DELETE) with optimistic updates.
> Automatic cache invalidation: after a mutation, call
> `queryClient.invalidateQueries()` to refetch related queries.
> Stale time and cache time control how long data is fresh vs kept in memory.

**Blank Mind Recovery:**

**(1) Restate:** "React Query: server-state management. useQuery for reads
(fetch + cache + loading/error), useMutation for writes, invalidateQueries
for cache reset. Replaces useEffect+useState for fetching. Separates server
state from client state. staleTime controls freshness. Background refetch
on focus."

---

### 📘 Concept Explanation

**What it is:**

TanStack Query is a server-state library: it manages data that originates
on a remote server, including fetching, caching, synchronization, and
background updates. It treats server data as a cache that is eventually
consistent with the server.

**How it works:**

```jsx
import {
  useQuery, useMutation, useQueryClient,
  QueryClient, QueryClientProvider
} from '@tanstack/react-query';

// Setup at app root:
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 min: data stays fresh
      retry: 2,                  // retry failed requests twice
    }
  }
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <MyApp />
    </QueryClientProvider>
  );
}

// READING: useQuery
function UserProfile({ userId }) {
  const { data: user, isLoading, isError, error } = useQuery({
    queryKey: ['user', userId],       // cache key; unique per user
    queryFn: () => fetchUser(userId), // the actual fetch function
    staleTime: 5 * 60 * 1000,         // fresh for 5 min
    // When userId changes, React Query refetches automatically
  });

  if (isLoading) return <Skeleton />;
  if (isError) return <ErrorBanner error={error} />;
  return <div>{user.name}</div>;
}

// WRITING: useMutation + cache invalidation
function UpdateUserButton({ userId }) {
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: (updates) => updateUser(userId, updates),
    // After success: invalidate the user query to refetch fresh data
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['user', userId] });
    },
    // Optimistic update: update cache immediately, rollback on error
    onMutate: async (updates) => {
      // Cancel any in-flight queries for this user
      await queryClient.cancelQueries({ queryKey: ['user', userId] });
      // Snapshot current state
      const previous = queryClient.getQueryData(['user', userId]);
      // Optimistically update
      queryClient.setQueryData(['user', userId], old => ({
        ...old, ...updates
      }));
      return { previous }; // pass to onError for rollback
    },
    onError: (err, _, context) => {
      // Rollback on error
      queryClient.setQueryData(['user', userId], context.previous);
    },
  });

  return (
    <button
      onClick={() => mutation.mutate({ name: 'Alice' })}
      disabled={mutation.isPending}
    >
      {mutation.isPending ? 'Saving...' : 'Save'}
    </button>
  );
}

// LIST: automatic cache per unique key
function UserList({ page }) {
  const { data } = useQuery({
    queryKey: ['users', { page }],    // different key per page
    queryFn: () => fetchUsers(page),
    placeholderData: keepPreviousData, // show old data while next page loads
  });

  return <Table rows={data?.users ?? []} />;
}
```

> **Code walkthrough:** This React Query and Server-State Management example demonstrates async/await Promise resolution using async/await. **KEY MECHANISM:** async functions return Promises; await suspends the microtask until the Promise settles. **WHY IT MATTERS:** unhandled Promise rejections crash the Node process in v15+ or fire unhandledRejection event. **TAKEAWAY: always await or .catch() every Promise - silent rejections are production defects.**

**Why it matters:**

React Query eliminates 80% of the boilerplate in data-fetching components
and solves subtle bugs (race conditions, stale closures, missing error
states) that home-grown `useEffect` solutions commonly have. It is
industry-standard for server-state management.

---

### 💻 Code Example


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```jsx
// BAD: manual fetching with useEffect (common bugs)
function UserProfile({ userId }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    setLoading(true);
    fetchUser(userId)
      .then(setUser)
      .catch(setError)
      .finally(() => setLoading(false));
    // BUG 1: race condition if userId changes quickly
    // BUG 2: no cache - refetches on every remount
    // BUG 3: no background sync after tab regains focus
    // BUG 4: no retry on network failure
  }, [userId]);

  if (loading) return <Spinner />;
  if (error) return <Error />;
  return <div>{user?.name}</div>;
}

// GOOD: React Query handles all of the above
function UserProfile({ userId }) {
  const { data: user, isLoading, isError } = useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
  });
  // Automatic: cache, dedup, retry, background refetch
  if (isLoading) return <Spinner />;
  if (isError) return <Error />;
  return <div>{user.name}</div>;
}
```

> **Code walkthrough:** The BAD pattern has four bugs that React Queryice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> automatically handles. Race condition: if `userId` changes while the first
> fetch is in-flight, both responses update state and the older response
> might "win". React Query cancels the in-flight query when the key changes.
> No cache: every component mount refetches even if data is fresh. React
> Query serves cached data instantly. No retry: network errors fail silently.
> React Query retries with exponential backoff. No background sync: data
> goes stale after the user switches tabs. React Query refetches on window
> focus.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> React Query handles data fetching with caching and automatic loading/error
> states. `useQuery` fetches and caches data by a key; `useMutation`
> handles writes. After a mutation, you call `invalidateQueries` to refresh
> the affected data. It replaces manual `useEffect` + `useState` for
> data fetching with much less code and better behavior.

**Senior / Staff:**

> The key architectural decision React Query encodes: server state and
> client state are fundamentally different. Server state is remote,
> asynchronously fetched, and potentially stale - it needs a caching
> layer with staleness policies. Client state (modal open, selected tab)
> is synchronous and owned by the client. Mixing them in a single state
> manager (Redux handling both) creates unnecessary complexity. The
> recommended split: TanStack Query for server state, Zustand or simple
> useState for client state. Query key design is where architecture decisions
> matter: flat keys `['users']` don't support partial invalidation; nested
> keys `['users', userId]` allow precise cache control.

---

### ⚖️ Comparison Table

| Approach | Caching | Background sync | Boilerplate | Error/retry |
|---|---|---|---|---|
| useEffect + useState | Manual | No | High | Manual |
| SWR | Yes | Yes | Low | Auto |
| TanStack Query | Yes | Yes | Low | Auto + configurable |
| RTK Query | Yes | Yes | Medium | Auto |

---

### ⚠️ Common Misconceptions

**Misconception 1: React Query replaces all global state management.**

React Query manages SERVER STATE (data fetched from APIs) - caching, deduplication, background refresh, and optimistic updates. It does NOT manage CLIENT STATE (UI state, form state, user preferences, shopping cart). A complete application needs both: React Query for server state and a client state solution (useState, Zustand, Context) for UI state. Trying to force client state through React Query adds unnecessary complexity.

**Misconception 2: React Query always requires a network request for fresh data.**

React Query's staleTime controls when data is considered stale and needs a background refresh. With `staleTime: Infinity`, data is never considered stale and no background requests occur. With `staleTime: 5000`, data fetched less than 5 seconds ago is served from cache without a network request. Default staleTime is 0, meaning data is considered immediately stale but served from cache while a background refresh happens (stale-while-revalidate pattern).

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: useQuery results not refreshing after mutation.**

Symptom: create/update/delete mutation succeeds but the list component shows stale data until page refresh. Root cause: React Query cache not invalidated after the mutation. Fix: add `queryClient.invalidateQueries({ queryKey: ['items'] })` in the mutation's `onSuccess` callback to mark the relevant queries as stale and trigger a background refetch.

**Failure Mode 2: Infinite re-fetching loop caused by object in queryKey.**

Symptom: network tab shows the same API request firing continuously; React Query keeps re-fetching in a tight loop. Root cause: queryKey contains an object (`queryKey: [{ filter }]`) - the object is compared by reference; each render creates a new object, which React Query sees as a new key. Fix: serialize the object or use stable values: `queryKey: ['items', filter.category, filter.status]` - primitive values in the key array are compared by value.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| What is server state | 3-4 min | Client vs server state split |
| useQuery basics | 2-3 min | queryKey, queryFn, return values |
| Cache invalidation | 3-4 min | invalidateQueries pattern |
| Optimistic updates | 4-5 min | onMutate/onError rollback |
| staleTime vs gcTime | 3-4 min | Freshness vs memory |
| Race condition prevention | 3-4 min | Key-based dedup |
| When NOT to use RQ | 2-3 min | Local-only client state |

---

**[SENIOR] Q1 - [TRADE-OFF] Explain optimistic updates in React Query and why they matter.**

> **Answer:**
>
> Optimistic updates update the UI immediately before the server confirms
> the change. If the server fails, roll back to the previous state.
>
> Why they matter: for user actions that are likely to succeed (liking a
> post, reordering a list), waiting 200-500ms for the server response before
> updating the UI feels sluggish. Optimistic updates make apps feel instant.
>
> ```jsx
> const mutation = useMutation({
>   mutationFn: (id) => likePost(id),
>
>   // Before the mutation fires:
>   onMutate: async (id) => {
>     // 1. Cancel in-flight queries (prevent overwriting optimistic update)
>     await queryClient.cancelQueries({ queryKey: ['posts'] });
>     // 2. Snapshot for rollback
>     const previous = queryClient.getQueryData(['posts']);
>     // 3. Optimistically update cache
>     queryClient.setQueryData(['posts'], (old) =>
>       old.map(post =>
>         post.id === id ? { ...post, liked: true, likes: post.likes + 1 }
>         : post
>       )
>     );
>     return { previous };
>   },
>
>   // On error: roll back
>   onError: (err, id, context) => {
>     queryClient.setQueryData(['posts'], context.previous);
>     toast.error('Failed to like post');
>   },
>
>   // On success or error: always sync with server truth
>   onSettled: () => {
>     queryClient.invalidateQueries({ queryKey: ['posts'] });
>   },
> });
> ```
>
> *What separates good from great:* The `cancelQueries` + `onSettled`
> combination is the complete pattern. Without `cancelQueries`, an
> in-flight background refetch could overwrite the optimistic update.
> Without `onSettled` invalidation, the UI might show an optimistic value
> forever if the error handler doesn't catch all cases. The pattern:
> cancel + snapshot + update, then rollback on error + always refetch
> on settle.

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*



# React Performance Optimization Techniques

🎯 **Interview Weight:** intermediate (★★☆) - performance is asked at senior
level; knowing WHEN not to optimize is as important as knowing HOW

---

### 🎯 Model Answer

**30 seconds:**

> React re-renders a component when its state or props change, and all
> descendants re-render by default. Performance tools: `React.memo` stops
> re-renders if props are shallowly equal; `useMemo` memoizes expensive
> calculations; `useCallback` memoizes functions (to prevent new references
> on each render). Profiler tools: React DevTools Profiler, `<Profiler>`
> component. First rule: measure before optimizing - premature optimization
> often adds complexity with zero user-perceived benefit.

**3 minutes:**

> React's default re-render behavior is usually fine. A component
> re-rendering means React calls the function again - typically takes
> <1ms. The problem is when expensive computations run in render, or when
> re-renders cascade to hundreds of child components. `React.memo` wraps
> a component; React skips re-rendering if props are referentially equal
> to the previous render. `useMemo` caches a value until dependencies
> change. `useCallback` caches a function reference. The trap: wrapping
> everything in memo/useMemo/useCallback can make performance WORSE because
> the memoization itself has a cost. Only apply when profiling shows a
> genuine problem.

**Blank Mind Recovery:**

**(1) Restate:** "React re-renders on state/prop change - default is fine.
Tools: React.memo (component skip), useMemo (value cache), useCallback
(function cache). Profiler first, then optimize. Pitfall: memo overhead can
exceed savings. Virtualization for long lists. Context splits to avoid
re-rendering all consumers."

---

### 📘 Concept Explanation

**What it is:**

React performance optimization reduces unnecessary re-renders and
expensive computations in the render path. The key insight: not all
re-renders are bad - only re-renders that are slow or cause visible lag.

**How it works:**


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```jsx
// 1. REACT.MEMO: memoize component renders
const UserCard = React.memo(function UserCard({ user, onSelect }) {
  // Only re-renders when `user` or `onSelect` props change (shallow compare)
  return (
    <div onClick={() => onSelect(user.id)}>
      {user.name}
    </div>
  );
});

// Problem: unstable onSelect prop reference breaks memo
function UserList({ users }) {
  // BAD: new function reference on every render -> memo is useless
  return users.map(u =>
    <UserCard key={u.id} user={u} onSelect={(id) => console.log(id)} />
  );
}

// GOOD: stable reference with useCallback
function UserList({ users }) {
  const handleSelect = useCallback((id) => {
    console.log(id);
  }, []); // stable: no deps

  return users.map(u =>
    <UserCard key={u.id} user={u} onSelect={handleSelect} />
  );
}

// 2. USEMEMO: cache expensive computations
function DataTable({ rows, filters }) {
  // BAD: filter runs on every render regardless of input changes
  const visible = rows.filter(r => filters.every(f => f(r)));

  // GOOD: only recompute when rows or filters change
  const visible = useMemo(
    () => rows.filter(r => filters.every(f => f(r))),
    [rows, filters]
  );

  return <Table rows={visible} />;
}

// 3. VIRTUALIZATION: render only visible list items
import { FixedSizeList } from 'react-window';

function VirtualList({ items }) {
  // BAD: render 10,000 DOM nodes
  return (
    <ul>
      {items.map(item => <li key={item.id}>{item.name}</li>)}
    </ul>
  );
  // GOOD: render only ~20 visible rows
  return (
    <FixedSizeList
      height={400}
      itemCount={items.length}
      itemSize={40}
      width="100%"
    >
      {({ index, style }) => (
        <div style={style}>{items[index].name}</div>
      )}
    </FixedSizeList>
  );
}
```

> **Code walkthrough:** BAD pattern: This React Performance Optimization Techniques example demonstrates variable declaration using React hook. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **WHAT BREAKS: use Object.freeze() to prevent mutation; const only guards the binding.**

**Why it matters:**

Premature optimization is the most common React performance mistake.
Engineers wrap everything in `useMemo` and `useCallback` "just in case",
adding cognitive overhead without benefit. The profiler-first approach
is the professional standard.

---

### 💻 Code Example

{% raw %}
```jsx
// DEBUGGING PERFORMANCE: React DevTools Profiler

// 1. Add Profiler to measure render time
import { Profiler } from 'react';

function onRenderCallback(id, phase, actualDuration) {
  console.log(`${id} [${phase}]: ${actualDuration.toFixed(2)}ms`);
}

<Profiler id="UserList" onRender={onRenderCallback}>
  <UserList users={users} />
</Profiler>

// 2. Find what's causing re-renders
// React DevTools: "Highlight updates when components render"
// Components flash when they re-render

// CONTEXT SPLIT: prevent all consumers re-rendering
// BAD: one context value with user + theme
const AppContext = createContext();
function AppProvider({ children }) {
  const [user, setUser] = useState(null);
  const [theme, setTheme] = useState('light');
  // Every consumer re-renders when EITHER user OR theme changes
  return (
    <AppContext.Provider value={{ user, setUser, theme, setTheme }}>
      {children}
    </AppContext.Provider>
  );
}

// GOOD: split contexts by change frequency
const UserContext = createContext();
const ThemeContext = createContext();
// UserCard only subscribes to UserContext
// ThemeToggle only subscribes to ThemeContext
```
{% endraw %}

> **Code walkthrough:** The `<Profiler>` component is the programmaticice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> way to measure render performance in development - it reports actual
> duration (time spent rendering) per component. The context split pattern
> is critical: a single context with multiple values causes ALL consumers
> to re-render when ANY value changes. Splitting by change frequency
> (user data changes rarely; theme may change often) means components
> only re-render when relevant data changes. The React DevTools "highlight
> updates" feature is the fastest way to identify what's re-rendering
> unexpectedly during development.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> React re-renders components when state or props change. To optimize
> performance: `React.memo` prevents re-renders when props haven't changed,
> `useMemo` caches expensive calculations, `useCallback` caches functions
> so wrapped components don't re-render unnecessarily. You should profile
> with React DevTools first to find actual bottlenecks before optimizing.

**Senior / Staff:**

> The correct React performance workflow: profile first with React DevTools
> Profiler, identify components with high actual duration or high render
> count, then apply targeted fixes. `React.memo` is only effective when
> combined with stable prop references - it's useless if parent renders
> create new objects or functions every time. `useMemo` breakeven is roughly
> a calculation taking >1ms; below that, the memoization overhead isn't
> worth it. For lists over ~100 items, virtualization (react-window) is the
> correct solution. For context performance, split by change frequency.
> Concurrent features (startTransition, useDeferredValue) help with
> responsiveness during expensive updates by yielding to user input.

---

### ⚖️ Comparison Table

| Tool | What it prevents | When to use |
|---|---|---|
| `React.memo` | Component re-render | Expensive component, stable props |
| `useMemo` | Expensive recalculation | Computation >1ms, deps rarely change |
| `useCallback` | Function reference change | Passed to memo'd child |
| Virtualization | DOM node count | Lists >100 items |
| Context split | All-consumer re-render | Context with mixed change frequencies |

---

### ⚠️ Common Misconceptions

**Misconception 1: React.memo, useMemo, and useCallback should be
applied to every component and value.**

Memoization has a cost: React.memo performs a shallow comparison on
every render, useMemo and useCallback run comparison logic, and all
three hold references in memory. Applying them everywhere often
degrades performance by adding overhead without benefit. The right
approach: profile first using React DevTools Profiler, identify
components that re-render unnecessarily and cause visible jank,
then apply memoization selectively. The golden rule: optimize when
you have measured a problem, not speculatively.

**Misconception 2: Virtualization solves slow list rendering for
any list size.**

Virtualization (react-window, react-virtual) is appropriate for
lists of hundreds or thousands of items where only ~10-50 are
visible at once. For lists under ~100 items, virtualization adds
complexity (scroll position management, accessibility challenges,
variable height items) without measurable benefit. The real
performance bottleneck for moderate-size lists is usually item
component complexity, not the number of DOM nodes. Profile before
reaching for virtualization.

**Misconception 3: Moving state down is always a performance
optimization.**

Moving state to the component that uses it reduces unnecessary
re-renders of unrelated siblings - but it can create other problems:
prop drilling if the state is needed by multiple components, complex
state synchronization if multiple components need to stay in sync,
and fragmentation of related state making debugging harder. Use
state co-location as a starting point but recognize that shared
state sometimes belongs higher in the tree. React Context or Zustand
are the alternatives when co-location creates more problems than
it solves.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Performance regression from context causing
full subtree re-renders.**

Symptom: profiler shows a large portion of the component tree
re-rendering even when only one small piece of data changes.
Root cause: a high-level context value changes on every parent
render (object literal in Provider value), causing all consumers
to re-render. Diagnosis: React DevTools Profiler shows components
highlighted as "Context changed" in the flamegraph. Fix: split
large contexts into smaller, focused ones (auth context, theme
context, user prefs context separately); wrap context value in
`useMemo`; or move the state down closer to the consumers.

**Failure Mode 2: useCallback dependency array causes new function
on every render, defeating memoization.**

Symptom: a child wrapped in `React.memo` re-renders on every
parent update despite receiving a "stable" callback. Root cause:
`useCallback(fn, [deps])` only returns a stable reference when deps
have not changed. If a dep like a state setter, or a variable that
changes on every render, is included in the array (or missing from
it and being captured via stale closure), the callback changes each
render. Diagnosis: use the `why-did-you-render` library or React
DevTools to trace which prop triggered the re-render. Fix: ensure
state setters (always stable from useState) are excluded from the
dependency array; use `useReducer` for complex state to avoid
unstable references.

**Failure Mode 3: Profiler shows expensive renders in dev but
production performance is fine - or vice versa.**

React dev mode performs additional checks that slow down rendering
by 2-3x compared to production. Always measure performance in a
production build (`npm run build && npx serve dist`). The reverse
problem also exists: some optimizations that help in dev (like
reduced prop drilling) can actually hurt in production due to
runtime overhead of memoization checks on very cheap renders.
Measure both environments before and after optimizations.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| React.memo effectiveness | 3-4 min | Requires stable props |
| useMemo vs useCallback | 2-3 min | Value vs function |
| Profiling approach | 3-4 min | Measure first |
| Virtualization | 3-4 min | react-window |
| Context performance | 3-4 min | Split by frequency |
| When NOT to memoize | 3-4 min | Premature optimization |
| startTransition use case | 3-4 min | Concurrent features |

---

**[SENIOR] Q1 - [DEBUGGING] You have a slow React list of 500 items. Walk through your diagnosis.**

> **Answer:**
>
> ```jsx
> // Step 1: Profile
> // React DevTools > Profiler > Record > interact with list > Stop
> // Look for: components with high "Actual duration"
>
> // Step 2: Identify cause
> // Is the LIST component itself slow? (expensive filter/sort)
> // Or are individual ITEMS slow?
>
> // Step 3: Fix based on cause
>
> // CAUSE A: expensive computation in render
> // BAD:
> function ItemList({ items, query }) {
>   const filtered = items
>     .filter(i => i.name.includes(query))
>     .sort((a, b) => a.score - b.score); // runs every render
> }
> // GOOD:
> const filtered = useMemo(
>   () => items.filter(i => i.name.includes(query)).sort(...),
>   [items, query]
> );
>
> // CAUSE B: individual items re-rendering unnecessarily
> const ListItem = React.memo(({ item, onAction }) => {
>   return <div onClick={() => onAction(item.id)}>{item.name}</div>;
> });
> // Ensure onAction is stable with useCallback
>
> // CAUSE C: 500 DOM nodes is too many
> import { FixedSizeList } from 'react-window';
> // Render only visible items (typically 10-20)
> ```
>
> *What separates good from great:* Starting with profiling rather than
> guessing is the key. Also recognizing the tipping point: 500 items is
> borderline - with simple row content, memo on list items may be
> sufficient. With complex row components (images, sub-lists), virtualization
> is the right answer. The question "is the list or the items slow?" is
> the diagnostic split.

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# React.memo and Re-render Prevention

🎯 **Interview Weight:** intermediate (★★☆) - memo is commonly misused;
explaining what breaks it (unstable props) is the senior differentiator

---

### 🎯 Model Answer

**30 seconds:**

> `React.memo` is a HOC that skips re-rendering a function component if
> its props are shallowly equal to the previous render's props. "Shallow
> equal" means primitives are compared by value, objects/arrays/functions
> by reference. The problem: object literals and inline functions create
> new references on every render, breaking memo's optimization. Fix:
> lift stable objects outside render scope or use `useMemo`/`useCallback`
> for unstable ones.

**3 minutes:**

> Shallow equality check: `Object.is(prev, next)` for each prop.
> Primitives (string, number, boolean) compare by value - safe.
> Objects, arrays, functions compare by reference. A new `{}` object
> has a different reference than an identical `{}` from the previous
> render. This is why `<Comp style={{ color: 'red' }} />` breaks memo:
> `style` gets a new object reference every render. Solutions: (1) define
> stable objects outside the component, (2) `useMemo` for derived objects,
> (3) `useCallback` for event handlers. Custom equality: `React.memo(Comp, areEqual)`
> accepts a custom comparison function for deep equality or partial checking.

**Blank Mind Recovery:**

**(1) Restate:** "React.memo: skip re-render if props shallowly equal.
Shallow = primitives by value, objects by reference. Breaks with inline
objects/functions. Fix: stable references - move outside component, or
useMemo/useCallback. Custom comparator for deep equality."

---

### 📘 Concept Explanation

**What it is:**

`React.memo` wraps a function component. Before re-rendering, React runs
a shallow comparison of old and new props. If all props are equal, the
previous render result is reused.

**How it works:**


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

{% raw %}
```jsx
// Basic React.memo:
const ExpensiveCard = React.memo(function ExpensiveCard({ user, onClick }) {
  // Expensive render (chart, complex UI)
  return (
    <div onClick={onClick}>
      <HeavyChart data={user.chartData} />
      <p>{user.name}</p>
    </div>
  );
});

// What React does internally:
function shallowEqual(objA, objB) {
  if (Object.is(objA, objB)) return true;
  const keysA = Object.keys(objA);
  const keysB = Object.keys(objB);
  if (keysA.length !== keysB.length) return false;
  return keysA.every(key => Object.is(objA[key], objB[key]));
}
// If shallowEqual(prevProps, nextProps) -> skip re-render

// BREAKING MEMO: reference instability

// 1. Inline object prop - new reference every render
function Parent({ userId }) {
  // BAD: { id: userId } creates new object reference each render
  return <ExpensiveCard style={{ padding: 16 }} user={{ id: userId }} />;
}

// GOOD: stable reference via useMemo
function Parent({ userId }) {
  const user = useMemo(() => ({ id: userId }), [userId]);
  const style = useMemo(() => ({ padding: 16 }), []); // or const outside
  return <ExpensiveCard style={style} user={user} />;
}

// 2. Inline function - new reference every render
function Parent({ userId }) {
  // BAD: new function reference each render
  return <ExpensiveCard onClick={() => console.log(userId)} />;
}
// GOOD: stable reference via useCallback
function Parent({ userId }) {
  const handleClick = useCallback(() => console.log(userId), [userId]);
  return <ExpensiveCard onClick={handleClick} />;
}

// CUSTOM COMPARATOR: deep equal for complex props
const UserList = React.memo(
  function UserList({ users }) {
    return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
  },
  // Custom: re-render only if user IDs change (not deep content)
  (prevProps, nextProps) => {
    if (prevProps.users.length !== nextProps.users.length) return false;
    return prevProps.users.every((u, i) => u.id === nextProps.users[i].id);
  }
);
```
{% endraw %}

> **Code walkthrough:** BAD pattern: This React.memo and Re-render Prevention example demonstrates variable declaration using React hook. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **WHAT BREAKS: use Object.freeze() to prevent mutation; const only guards the binding.**

**Why it matters:**

`React.memo` is frequently misused - applied without understanding the
reference stability requirement, giving zero benefit while adding
complexity. The correct mental model: `React.memo` is only effective
when combined with stable prop references.

---

### 💻 Code Example

{% raw %}
```jsx
// DIAGNOSIS: verify memo is working
// Add a console.log inside the memoized component:
const ExpensiveCard = React.memo(function ExpensiveCard({ user }) {
  console.log('ExpensiveCard rendered');
  return <div>{user.name}</div>;
});

// If you see the log on every parent render -> memo is broken
// Check: is any prop creating new references?

// WHY MEMO FAILED: object created in JSX
function UserList({ users }) {
  return users.map(u => (
    // `extra` is a new object every render - memo is useless
    <ExpensiveCard key={u.id} user={u} extra={{ show: true }} />
  ));
}

// FIXED: stable extra object
const EXTRA_PROPS = { show: true }; // defined once, outside component
function UserList({ users }) {
  return users.map(u => (
    <ExpensiveCard key={u.id} user={u} extra={EXTRA_PROPS} />
  ));
}

// WHEN NOT TO USE MEMO:
// - Component renders rarely anyway
// - Props are primitives (no reference issue)
// - Component render is fast (<1ms)
// Memo overhead: comparison cost + memory for cached result
// Not free - applies wisely, not defensively
```
{% endraw %}

> **Code walkthrough:** The console.log diagnostic is the fastest way toice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> verify whether `React.memo` is actually preventing re-renders. If the
> log fires on every parent render, a prop has unstable references. The
> "move constant objects outside the component" fix is the simplest
> solution - `const EXTRA_PROPS = { show: true }` defined at module scope
> creates exactly one object reference that never changes. This is more
> efficient than `useMemo` because it has zero runtime cost.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> `React.memo` wraps a component and compares props before re-rendering.
> If props haven't changed, the previous render is reused. It uses shallow
> comparison, so objects and functions need to have the same reference to
> be considered equal. That's why you need `useCallback` for function props
> and `useMemo` for object props when using `React.memo`.

**Senior / Staff:**

> `React.memo` is only effective when prop references are stable. In
> practice, this means auditing every prop passed to a memoized component:
> primitives are safe; anything else needs explicit stability management.
> The common mistake: applying `React.memo` without ensuring stable props,
> then wondering why performance is identical. My approach: profile first,
> identify the actual slow component, then apply `React.memo` + stable props
> as a targeted fix. For list items specifically, the pattern is
> `React.memo(Item)` + `useCallback(handler)` in the parent. For deeply
> nested objects, consider a custom comparator or restructure to pass
> primitive IDs instead of full objects.

---

### ⚖️ Comparison Table

| Prop type | Stable by default | Solution if unstable |
|---|---|---|
| string, number, boolean | Yes | N/A |
| Inline object `{}` | No | `useMemo` or module constant |
| Inline array `[]` | No | `useMemo` |
| Inline function `() => {}` | No | `useCallback` |
| Context value | No | Memoize context value |

---

### ⚠️ Common Misconceptions

**Misconception 1: React.memo prevents ALL re-renders of a
component.**

`React.memo` prevents re-renders caused by PARENT re-renders when
props have not changed (shallow comparison). It does NOT prevent
re-renders caused by: (1) the component's own `useState` or
`useReducer` dispatch, (2) `useContext` changes when the component
is a context consumer, (3) `useEffect` dependencies triggering state
updates inside the component. Understanding which re-render source
you are optimizing against is critical before applying React.memo.

**Misconception 2: React.memo uses deep equality for comparison.**

`React.memo` uses SHALLOW equality by default - it compares prop
references, not deep values. `{ a: 1 }` and `{ a: 1 }` are two
different object references, so passing a new object literal each
render causes React.memo to always re-render the component. The fix
is to stabilize the prop reference: use `useMemo` for derived
objects, `useCallback` for function props, or lift the value to
module scope if it is a constant. A custom comparator can be passed
as the second argument to React.memo for deep comparison, but this
has its own cost.

**Misconception 3: React.memo is only needed for expensive
components.**

React.memo is valuable for any component that: (1) renders
frequently due to parent updates, and (2) receives stable props
but is inside a fast-changing parent. The "expensive" threshold
is much lower than developers assume - even components that are
cheap individually can create performance problems when thousands
of instances re-render in a list. Profile first; apply memo where
the profiler shows unnecessary re-renders with stable inputs.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: React.memo has no effect because function props
are recreated on each render.**

Symptom: component wrapped in React.memo still re-renders every
time its parent re-renders. Diagnosis: React DevTools shows the
component re-rendering with "props changed"; check which prop is
changing - a function prop created inline (`onClick={() => doX()}`)
creates a new function reference each render. Fix: wrap function
props in `useCallback`. Verify that `useCallback`'s dependency
array is correct - a dep that changes on every render defeats the
purpose.

**Failure Mode 2: Custom comparator in React.memo causes stale
renders.**

Symptom: component shows outdated data even though the underlying
value has changed. Root cause: a custom comparator (`React.memo(Comp,
(prev, next) => shallowEqual(prev.data, next.data))`) incorrectly
returns `true` (equal) when the props have actually changed in a
way the comparator does not check. Fix: ensure the custom comparator
checks ALL props that affect render output. The default shallow
equality comparator is safer for most cases - only use a custom
comparator when you have a specific known optimization and a test
to verify it.

**Failure Mode 3: Memoized component still re-renders because
context changed.**

Symptom: profiler shows component re-rendering despite stable props
and React.memo applied. Diagnosis: DevTools shows "Context changed"
as the reason for re-render. Root cause: the component consumes a
context that updates frequently (e.g. a global store with frequent
small updates), and React.memo does not protect against context
changes. Fix: split the context into smaller focused contexts; use
a selector pattern with `useMemo` to derive only the specific value
needed; or use a state management library with built-in selector
support (Zustand, Redux Toolkit with `useSelector`).

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| What is React.memo | 2-3 min | Shallow comparison |
| What breaks memo | 3-4 min | Reference instability |
| memo + useCallback | 3-4 min | Stable function props |
| Custom comparator | 3-4 min | Deep equality |
| Debugging broken memo | 3-4 min | console.log in component |
| When not to use memo | 2-3 min | Cost vs benefit |
| memo vs PureComponent | 2-3 min | Class vs function equivalents |

---

**[JUNIOR] Q1 - [MECHANISM] A memoized child component still re-renders on every parent render.**
How do you diagnose and fix it?** `[SENIOR]` DEBUGGING

> **Answer:**
>
> ```jsx
> // Step 1: Confirm the problem
> const Child = React.memo(function Child(props) {
>   console.log('Child re-rendered', props);
>   return <div>{props.name}</div>;
> });
>
> // Step 2: Check each prop type
> function Parent() {
>   const [count, setCount] = useState(0);
>
>   // Prop audit:
>   // name: string - OK (primitive)
>   // config: object - PROBLEM (new ref every render)
>   // onAction: function - PROBLEM (new ref every render)
>
>   return (
>     <Child
>       name="Alice"                        // OK
>       config={{ debug: false }}           // BROKEN: new object
>       onAction={() => setCount(c => c+1)} // BROKEN: new function
>     />
>   );
> }
>
> // Step 3: Fix unstable props
> const CONFIG = { debug: false }; // module-level constant
>
> function Parent() {
>   const [count, setCount] = useState(0);
>
>   const handleAction = useCallback(
>     () => setCount(c => c + 1),
>     [] // stable: no deps change
>   );
>
>   return (
>     <Child
>       name="Alice"
>       config={CONFIG}
>       onAction={handleAction}
>     />
>   );
> }
>
> // Step 4: Verify fix
> // Child console.log should only fire when `name` changes
> ```
>
> *What separates good from great:* Systematically auditing each prop
> type rather than guessing is the professional approach. A quick mental
> model: "if this prop is JSX, an object literal, an array literal, or
> a function expression, it needs stabilization." The module-level constant
> (`CONFIG`) is better than `useMemo` here because it truly never changes
> across the entire app lifetime, not just between renders.

---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*



# React Router and Client-side Routing

🎯 **Interview Weight:** working (★★☆) - routing is required for every SPA;
React Router v6 API changes are a common catch for mid-level interviews

---

### 🎯 Model Answer

**30 seconds:**

> React Router is the standard routing library for React SPAs. It maps
> URLs to components using `<Route>` elements. v6 major changes: `<Switch>`
> replaced by `<Routes>`, `useHistory` replaced by `useNavigate()`,
> `component=` replaced by `element=`, and relative paths work without
> leading slash. The browser uses the History API to change URLs without
> full page reloads. Route matching is exact-by-default in v6.

**3 minutes:**

> React Router intercepts navigation events and renders the component
> matched by the current URL. The `<BrowserRouter>` wraps the app and
> provides routing context. Nested `<Routes>` enable layout nesting:
> the parent route renders an `<Outlet>` where child routes appear.
> Protected routes: wrap `<Outlet>` with auth check in a layout component.
> Navigation: `useNavigate()` hook for programmatic navigation,
> `<Link>` for declarative. `useParams()` extracts URL parameters.
> `useSearchParams()` handles query strings. Loaders (React Router v6.4+)
> enable data fetching before render.

**Blank Mind Recovery:**

**(1) Restate:** "React Router: URL to component mapping. v6: Routes not Switch,
useNavigate not useHistory, element not component prop. BrowserRouter wraps
app. Nested routes use Outlet. useParams for URL params. useNavigate for
programmatic navigation. v6.4+ loaders for data."

---

### 📘 Concept Explanation

**What it is:**

React Router is a client-side routing library. It listens to URL changes
(using the browser's History API) and renders the appropriate React
components without triggering a full page reload.

**How it works:**

{% raw %}
```jsx
// React Router v6 setup
import {
  BrowserRouter, Routes, Route,
  Outlet, Link, NavLink,
  useNavigate, useParams, useSearchParams,
  Navigate
} from 'react-router-dom';

// App entry point:
function App() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Layout route: renders Outlet for children */}
        <Route path="/" element={<RootLayout />}>
          <Route index element={<HomePage />} />
          <Route path="users" element={<UsersPage />} />
          <Route path="users/:id" element={<UserDetailPage />} />

          {/* Protected routes using layout pattern */}
          <Route element={<RequireAuth />}>
            <Route path="dashboard" element={<DashboardPage />} />
            <Route path="settings" element={<SettingsPage />} />
          </Route>

          <Route path="*" element={<NotFoundPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}

// RootLayout: renders persistent nav + Outlet for page content
function RootLayout() {
  return (
    <div>
      <nav>
        <NavLink to="/" end>Home</NavLink>
        <NavLink to="/users">Users</NavLink>
        <NavLink to="/dashboard">Dashboard</NavLink>
      </nav>
      <main>
        <Outlet /> {/* child route renders here */}
      </main>
    </div>
  );
}

// Protected route layout component:
function RequireAuth() {
  const { user } = useAuth();
  // Redirect to login, preserving intended destination
  if (!user) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }
  return <Outlet />;
}

// Reading URL parameters:
function UserDetailPage() {
  const { id } = useParams(); // matches :id in route
  const [searchParams, setSearchParams] = useSearchParams();
  const tab = searchParams.get('tab') || 'overview';

  return (
    <div>
      <h1>User {id}</h1>
      <button onClick={() => setSearchParams({ tab: 'details' })}>
        Details Tab
      </button>
    </div>
  );
}

// Programmatic navigation:
function LoginForm() {
  const navigate = useNavigate();
  const location = useLocation();
  const from = location.state?.from?.pathname || '/dashboard';

  async function handleSubmit(e) {
    e.preventDefault();
    await login(credentials);
    navigate(from, { replace: true }); // redirect to intended destination
  }
  return <form onSubmit={handleSubmit}>...</form>;
}
```
{% endraw %}

> **Code walkthrough:** This React Router and Client-side Routing example demonstrates async/await Promise resolution using async/await. **KEY MECHANISM:** async functions return Promises; await suspends the microtask until the Promise settles. **WHY IT MATTERS:** unhandled Promise rejections crash the Node process in v15+ or fire unhandledRejection event. **TAKEAWAY: always await or .catch() every Promise - silent rejections are production defects.**

**Why it matters:**

Every non-trivial React app needs routing. React Router v6 is nearly
universally used. The migration from v5 to v6 is a common interview
discussion point. Understanding the Outlet/nested routes pattern is
required for implementing layouts efficiently.

---

### 💻 Code Example


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```jsx
// Common v5 vs v6 gotchas:

// BAD: v5 patterns in v6 codebase
// <Switch> does not exist in v6
import { Switch, Route } from 'react-router-dom'; // v5
function Routes_v5() {
  return (
    <Switch>
      <Route exact path="/" component={Home} />
      <Route path="/users" component={Users} />
    </Switch>
  );
}

// GOOD: v6 equivalents
import { Routes, Route } from 'react-router-dom'; // v6
function MyRoutes() {
  return (
    // Routes replaces Switch, exact is default, element= not component=
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/users" element={<Users />} />
    </Routes>
  );
}

// BAD: useHistory (v5) in v6 codebase
const history = useHistory(); // v5 - does not exist in v6
history.push('/home');

// GOOD: useNavigate (v6)
const navigate = useNavigate();
navigate('/home');            // push
navigate('/home', { replace: true }); // replace
navigate(-1);                 // go back
```

> **Code walkthrough:** The most common React Router bug after upgradingice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> from v5 to v6 is using old imports. `Switch` is replaced by `Routes`,
> `component={MyComp}` is replaced by `element={<MyComp />}` (note JSX),
> and `useHistory()` is replaced by `useNavigate()`. The `exact` prop is
> gone because v6 routes are exact by default - `/users` no longer matches
> `/users/123`. If you need prefix matching in v6, add `/*` to the path.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> React Router maps URLs to React components. In v6, you wrap routes
> in `<Routes>`, use `element={<Component />}` instead of `component=`,
> and `useNavigate()` instead of `useHistory()`. `useParams()` gets URL
> parameters, `<Link>` creates navigation links. Nested routes let parent
> components render an `<Outlet>` where child routes appear.

**Senior / Staff:**

> React Router v6's biggest architectural improvement is nested routes
> with Outlets - layouts and shared UI are now just route hierarchy, not
> component state. Protected routes become layout components that render
> `<Outlet>` or `<Navigate>` based on auth state. The v6.4 data APIs
> (loaders, actions) bring routing closer to Remix's model: data fetching
> is co-located with routes, reducing waterfalls. For large apps, nested
> routes should mirror the data hierarchy (user detail route loads user
> data in its loader, sub-routes assume the user is loaded). This creates
> predictable loading states and avoids parent-to-child data prop drilling.

---

### ⚖️ Comparison Table

| Feature | React Router v5 | React Router v6 |
|---|---|---|
| Route container | `<Switch>` | `<Routes>` |
| Component prop | `component={Comp}` | `element={<Comp />}` |
| Navigation hook | `useHistory()` | `useNavigate()` |
| Exact matching | `exact` prop needed | Default |
| Nested routes | Manual nesting | `<Outlet>` |
| Redirect | `<Redirect>` | `<Navigate>` |

---

### ⚠️ Common Misconceptions

**Misconception 1: Client-side routing means the server never
needs to know about routes.**

The server must serve the React app's entry point (`index.html`)
for ALL routes on initial page load or direct URL access. Without
server configuration, navigating to `/dashboard/profile` returns
a 404 because no file exists at that path. The server must be
configured to fall back to `index.html` for all paths not matching
static files. Nginx: `try_files $uri /index.html;`. Apache:
`FallbackResource /index.html`. Hosts like Netlify/Vercel handle
this automatically. Missing this causes "works in dev but 404
in production" on deep links.

**Misconception 2: `useNavigate` and `<Link>` are interchangeable
based on preference.**

`<Link>` renders a real `<a>` element: it supports keyboard
navigation, screen reader route announcements, right-click
"open in new tab", and browser history integration automatically.
`useNavigate` is for PROGRAMMATIC navigation triggered by code
logic: redirect after form submission, redirect after auth state
change, redirect after API response. Using `useNavigate` for static
menu links loses accessibility. Using `<Link>` where you need to
navigate after an async operation complicates the code unnecessarily.

**Misconception 3: React Router v6 is v5 with minor API changes.**

v6 is a ground-up redesign. Key breaking changes: `<Switch>` is now
`<Routes>`, `<Route component={C}>` is now `<Route element={<C />}>`,
`useHistory()` is now `useNavigate()`, and route matching is now
always exact by default (no more `exact` prop). Most importantly,
nested routes in v6 use `<Outlet>` in the parent component to render
child routes - the entire nested routing model changed. Migration from
v5 to v6 requires systematic updates, not a find-replace.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Route params change does not trigger data
re-fetch when navigating between same-component routes.**

Symptom: navigating from `/user/1` to `/user/2` shows stale data;
component does not re-fetch for the new param. Root cause:
`useEffect` fetches data on mount but `params.userId` is not in
the dependency array, or the effect uses stale closure over the
initial params value. Diagnosis: add `console.log(params.userId)`
in the effect to verify it re-runs on param change. Fix: add
`params.userId` to the effect dependency array; or add
`key={params.userId}` to the component to force remount on change.

**Failure Mode 2: Nested route content is blank - Outlet missing
from parent component.**

Symptom: navigating to a child route renders the parent layout but
the child route content area is empty. Root cause: the parent route
component does not include `<Outlet />`. React Router renders matched
child routes where `<Outlet />` appears. Without it, child route
content has nowhere to render. Diagnosis: check if the parent route's
component renders `<Outlet />`. Fix: add `<Outlet />` at the position
in the parent layout where child route components should appear.

**Failure Mode 3: Browser navigation (back/forward) breaks
application state in single-page apps.**

Symptom: pressing browser back/forward navigates URL correctly but
the app state (filters, scroll position, form state) does not restore.
Root cause: React component state is ephemeral - navigating away
destroys state; navigating back creates a fresh component instance.
Fix: serialize critical state to URL params (React Router
`useSearchParams`) so that state survives navigation. For scroll
position, use React Router's `ScrollRestoration` component. For form
drafts, persist to `sessionStorage` with a route-specific key.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| v5 vs v6 differences | 3-4 min | Switch->Routes, useHistory->useNavigate |
| Nested routes and Outlet | 3-4 min | Layout pattern |
| Protected routes | 3-4 min | RequireAuth layout component |
| URL params and search params | 2-3 min | useParams, useSearchParams |
| Programmatic navigation | 2-3 min | useNavigate |
| Redirect after login | 3-4 min | location.state pattern |
| v6.4 loaders | 3-4 min | Data co-location |

---

**[SENIOR] Q1 - [TRADE-OFF] How do you implement a redirect-after-login flow with React Router?**

> **Answer:**
>
> The pattern: when an unauthenticated user tries to access a protected
> route, redirect them to `/login` with the intended destination in
> location state. After login, redirect to that stored destination.
>
> ```jsx
> // Step 1: Protected route saves intended destination
> function RequireAuth({ children }) {
>   const { user } = useAuth();
>   const location = useLocation();
>
>   if (!user) {
>     // Pass current location in state
>     return (
>       <Navigate
>         to="/login"
>         state={{ from: location }}
>         replace
>       />
>     );
>   }
>   return children;
> }
>
> // Step 2: Login reads destination from state
> function LoginPage() {
>   const navigate = useNavigate();
>   const location = useLocation();
>   // Default to /dashboard if no intended destination
>   const from = location.state?.from?.pathname ?? '/dashboard';
>
>   async function handleLogin(credentials) {
>     await login(credentials);
>     // replace: true removes /login from history stack
>     navigate(from, { replace: true });
>   }
>   return <LoginForm onSubmit={handleLogin} />;
> }
> ```
>
> *What separates good from great:* Using `replace: true` when redirecting
> after login is critical - without it, the browser Back button returns to
> `/login` (which redirects forward again in a loop). The `replace: true`
> removes the login page from history so Back goes to the page BEFORE the
> user tried to access the protected route. Also noting that
> `location.state?.from?.pathname ?? '/dashboard'` handles the case where
> the user navigated directly to `/login` with no intended destination.

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Dynamic Routing and Code Splitting

🎯 **Interview Weight:** working (★★☆) - lazy loading routes is a standard
performance optimization; every production React app should use it

---

### 🎯 Model Answer

**30 seconds:**

> Dynamic routing with `React.lazy` and `Suspense` splits the JS bundle
> so that route components are only loaded when the route is first visited.
> `const Dashboard = React.lazy(() => import('./Dashboard'))` creates a
> lazy component. Wrap lazy routes in `<Suspense fallback={<Loading />}>`.
> This reduces the initial bundle by 40-80% in large apps. Vite and
> webpack both support dynamic imports automatically.

**3 minutes:**

> Without code splitting, all route components ship in one JS bundle.
> A user visiting only the home page downloads the code for the dashboard,
> settings, and admin panels they may never see. Code splitting at the
> route level fixes this. `React.lazy` wraps a dynamic import; when the
> component is first needed, React downloads that chunk. `Suspense`
> shows a fallback during the download. React Router v6 integrates
> naturally: lazy components as `element` props work directly.
> Caution: over-splitting creates many small chunks with waterfall
> requests. Route-level splitting (one chunk per page) is the right
> granularity for most apps.

**Blank Mind Recovery:**

**(1) Restate:** "Code splitting: React.lazy + dynamic import + Suspense.
Route-level granularity is best. Reduces initial bundle. Vite/webpack handle
chunks automatically. Don't over-split below route level. Use Suspense
fallback for loading state."

---

### 📘 Concept Explanation

**What it is:**

Code splitting divides the JavaScript bundle into smaller chunks that load
on demand. Route-level code splitting is the most impactful form: each
route loads its code only when the user navigates to it.

**How it works:**

```jsx
import { Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';

// LAZY: component loaded on demand
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));
const AdminPanel = lazy(() => import('./pages/AdminPanel'));

// Suspense wraps lazy routes, shows fallback while loading
function App() {
  return (
    <BrowserRouter>
      <Suspense fallback={<PageSpinner />}>
        <Routes>
          {/* Eager: always included in main bundle */}
          <Route path="/" element={<HomePage />} />

          {/* Lazy: only loaded when route is visited */}
          <Route path="/dashboard" element={<Dashboard />} />
          <Route path="/settings" element={<Settings />} />
          <Route path="/admin" element={<AdminPanel />} />
        </Routes>
      </Suspense>
    </BrowserRouter>
  );
}

// Granular Suspense: different fallbacks per route section
function AdminSection() {
  return (
    <Suspense fallback={<AdminSkeleton />}>
      <Routes>
        <Route path="users" element={<AdminUsers />} />
        <Route path="reports" element={<AdminReports />} />
      </Routes>
    </Suspense>
  );
}

// Preloading: start download before user navigates
function NavBar() {
  return (
    <nav>
      <Link to="/dashboard"
        // onMouseEnter fires when user hovers - preloads chunk
        onMouseEnter={() => import('./pages/Dashboard')}
      >
        Dashboard
      </Link>
    </nav>
  );
}

// Vite: configure chunk naming (vite.config.ts)
// import { defineConfig } from 'vite';
// export default defineConfig({
//   build: {
//     rollupOptions: {
//       output: {
//         manualChunks: {
//           // Group vendor code separately from app code
//           vendor: ['react', 'react-dom', 'react-router-dom']
//         }
//       }
//     }
//   }
// });
```

> **Code walkthrough:** This Dynamic Routing and Code Splitting example demonstrates variable declaration. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **TAKEAWAY: use Object.freeze() to prevent mutation; const only guards the binding.**

**Why it matters:**

Bundle size directly impacts Time to Interactive (TTI). A 1MB bundle on
3G mobile takes ~10 seconds to parse and execute. Route-level code
splitting is the highest-ROI performance optimization for SPAs.

---

### 💻 Code Example


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```


```jsx
# BAD: anti-pattern shown for contrast
# This approach has the issues the GOOD example fixes
```

```jsx
// BAD: eager import, entire app in one bundle
import Dashboard from './pages/Dashboard';       // eager
import AdminPanel from './pages/AdminPanel';     // eager
// User visiting home page downloads ALL of these

// GOOD: lazy import, separate chunks
const Dashboard = lazy(() => import('./pages/Dashboard'));
const AdminPanel = lazy(() => import('./pages/AdminPanel'));

// BAD: no Suspense wrapper causes runtime error
// React throws if lazy component renders without Suspense boundary
function App() {
  return <Dashboard />; // Error: missing Suspense
}

// GOOD: Suspense at route level
function App() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
      </Routes>
    </Suspense>
  );
}

// DIAGNOSIS: check chunk sizes with Vite
// npx vite build --mode production
// open dist/stats.html (install rollup-plugin-visualizer)
```

> **Code walkthrough:** The BAD pattern loads all components eagerly.
> A user who only visits the home page pays the download cost for
> `AdminPanel` which they may never use. The GOOD pattern uses
> `React.lazy()` which tells the bundler to put each component in a
> separate chunk. The `Suspense` boundary is required - without it,
> React throws an error when the lazy component renders before its chunk
> is downloaded. The preload-on-hover pattern is an advanced optimization:
> by starting the download when the user hovers over a link (300-500ms
> before click), the chunk is often ready before navigation completes.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Code splitting with `React.lazy` and `Suspense` loads route components
> on demand instead of including everything in the initial bundle. This
> makes the app load faster because users only download code for routes
> they actually visit. You wrap lazy components in `<Suspense>` to show
> a loading spinner while the chunk downloads.

**Senior / Staff:**

> Route-level code splitting is typically the first performance
> optimization I apply to a new React app because the ROI is high and
> the implementation is trivial with React.lazy. The key decisions:
> (1) Suspense boundary placement - too high means one spinner for the
> whole app, too low means flickering on every micro-interaction.
> Route-level is usually right. (2) Preloading - hovering over nav links
> starts prefetching before click, eliminating perceived latency.
> (3) Chunk granularity - don't split below route level unless components
> are truly large (>50KB gzipped) and rarely used. Over-splitting creates
> request waterfalls. React Router v6.4 lazy route loaders take this
> further: data fetching starts in the loader before the component chunk
> even arrives.

---

### ⚖️ Comparison Table

| Approach | Initial bundle | Load on demand | Complexity |
|---|---|---|---|
| No splitting | Everything | No | None |
| Route-level lazy | Routes excluded | Yes, per route | Low |
| Component-level lazy | Large components out | Yes, per component | Medium |
| Library-level splits | Vendor separate | At bundle boundary | Config-only |

---

### ⚠️ Common Misconceptions

**Misconception 1: Code splitting is only useful for very large
applications.**

Even medium-sized SPAs benefit from code splitting. A 500KB initial
bundle (pre-gzip) can become 150KB for the initial route plus deferred
chunks for other routes. The user pays the parsing cost for all
JavaScript in the initial bundle even if they never visit those routes.
Code splitting at the route level gives every application a faster
Time to Interactive (TTI) at no functionality cost - it is a
structural optimization with no downside except slightly increased
server round-trips.

**Misconception 2: React.lazy and dynamic import are the same
thing.**

`import()` is a JavaScript dynamic import - it loads and evaluates
a module lazily, returning a Promise. `React.lazy` wraps that Promise
into a React component that can be rendered in the component tree.
`React.lazy` requires `Suspense` as a boundary to handle the loading
state. Dynamic `import()` can be used anywhere (non-React code, Webpack
magic comments, prefetching). Together they enable route-based code
splitting, but they serve different layers of the stack.

**Misconception 3: Suspense boundaries replace loading state
management entirely.**

`Suspense` handles the loading state for lazy-loaded code and (with
React 18) for async data sources. But Suspense does NOT handle error
states - an `ErrorBoundary` component is required alongside `Suspense`
to catch failed lazy imports (network error, chunk hash mismatch after
deploy). A production lazy-loading implementation always pairs
`<Suspense fallback={<Spinner />}>` with `<ErrorBoundary>` wrapping
the lazy component to handle the chunk-load-failure error gracefully.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: ChunkLoadError after deployment due to hash
mismatch.**

Symptom: users who have the app open during a deployment get
`ChunkLoadError: Loading chunk X failed` when navigating to a lazy
route. Root cause: Webpack/Vite generates content-hashed chunk names
(e.g. `about.a3f8b.js`). After deployment, old chunk URLs referenced
in the pre-deployment app no longer exist. Diagnosis: check the
browser console for `ChunkLoadError`; check network tab for 404 on
chunk files. Fix: add an error boundary around `React.lazy`
components that catches `ChunkLoadError` and either reloads the
page or shows a "New version available - please refresh" message.
Vite's `import.meta.env.MODE` and service workers can also help.

**Failure Mode 2: Lazy component re-imports on every render due
to lazy call inside component.**

Symptom: the lazy-loaded route component flashes/remounts on every
parent re-render. Root cause: `const LazyComp = React.lazy(() =>
import('./Comp'))` is called INSIDE a component function - creating
a new lazy reference on each render. React sees a new component
type and unmounts then remounts the tree. Fix: ALWAYS call
`React.lazy()` at module scope, never inside component functions
or render functions.

**Failure Mode 3: Code splitting gains eliminated by large
shared chunks.**

Symptom: despite lazy loading routes, the initial bundle size
barely decreases. Root cause: all routes share a common chunk
containing most of the application code (large utility libraries,
shared UI component library, etc.). Diagnosis: run `npm run build`
with Webpack Bundle Analyzer or Vite's `rollup-plugin-visualizer`
to visualize chunk composition. Fix: audit shared dependencies -
libraries used by only one or two routes should not be in the
shared chunk. Use Webpack's `splitChunks.cacheGroups` or Vite's
`build.rollupOptions.output.manualChunks` to control chunk
boundaries.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| What is code splitting | 2-3 min | Dynamic import + Suspense |
| React.lazy mechanics | 2-3 min | Separate chunk |
| Suspense fallback design | 2-3 min | Skeleton vs spinner |
| Preloading on hover | 3-4 min | UX optimization |
| Bundle analysis tools | 2-3 min | Vite visualizer, source-map-explorer |
| Over-splitting problems | 3-4 min | Request waterfalls |
| v6.4 loaders | 3-4 min | Data + code parallelism |

---

**[SENIOR] Q1 - [DEBUGGING] How do you investigate and fix bundle size issues in a React app?**

> **Answer:**
>
> ```bash
> # Step 1: analyze bundle with Vite
> npm i -D rollup-plugin-visualizer
> # vite.config.ts: add visualizer() to plugins
> npx vite build
> # Opens bundle visualization in browser
>
> # Step 2: find large modules
> # Look for: lodash (use lodash-es + tree-shaking)
> # moment.js (replace with date-fns or dayjs)
> # Old icons (import specific icons, not whole library)
>
> # Step 3: check for eager imports in routes
> # grep -r "import.*from.*pages" src/ | grep -v lazy
>
> # Step 4: add lazy loading
> # Before: import Dashboard from './pages/Dashboard'
> # After: const Dashboard = lazy(() => import('./pages/Dashboard'))
>
> # Step 5: check gzipped sizes matter, not raw
> npx source-map-explorer dist/assets/*.js
> ```
>
> Common culprits: moment.js (330KB raw), full icon libraries (importing
> `FaIcon` from `react-icons` without tree-shaking), lodash without
> per-method imports.
>
> *What separates good from great:* Emphasizing gzipped sizes over raw
> sizes is the key nuance. A 1MB raw bundle might be 250KB gzipped.
> Compression ratios vary by code type: JS compresses well, images do not.
> The visualizer is the correct starting point - fixing bundle size without
> measuring first is premature optimization.

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*



# Higher-Order Components

🎯 **Interview Weight:** working (★★☆) - HOCs are legacy pattern; knowing
when to use vs migrate to hooks shows pattern maturity

---

### 🎯 Model Answer

**30 seconds:**

> A Higher-Order Component (HOC) is a function that takes a component and
> returns a new component with additional behavior. Pattern:
> `const Enhanced = withAuth(MyComponent)`. HOCs add cross-cutting concerns:
> authentication gates, logging, feature flags, loading states. In modern
> React, custom hooks solve most HOC use cases with less boilerplate. HOCs
> remain relevant for class component patterns and some library integrations.

**3 minutes:**

> HOC problems: (1) Wrapper hell - multiple HOCs create deep nesting in
> DevTools. (2) Props collisions - HOC and wrapped component may use
> same prop names. (3) Ref forwarding - HOC must forward refs explicitly
> to wrapped component. (4) Hard to see which HOC provides which props.
>
> Modern equivalent: custom hooks replace most HOC logic. `withAuth(Comp)`
> HOC becomes `useAuth()` hook called inside the component. The exception:
> HOCs are still useful when you need to inject behavior into many
> components without touching them (third-party, legacy class components).

**Blank Mind Recovery:**

**(1) Restate:** "HOC: function(Component) => EnhancedComponent. Adds
cross-cutting behavior. Problems: wrapper hell, prop collision, ref issues.
Modern replacement: custom hooks. Still useful for: class components,
third-party library wrapping, error boundaries."

---

### 📘 Concept Explanation

**What it is:**

A Higher-Order Component is a function that accepts a React component
and returns a new component that wraps the original with added behavior.
Inspired by Higher-Order Functions in functional programming.

**How it works:**

```jsx
// HOC: adding authentication gate
function withAuth(WrappedComponent) {
  // Return a new component
  function AuthenticatedComponent(props) {
    const { user } = useAuth();

    if (!user) {
      return <Navigate to="/login" />;
    }

    // Pass all original props through
    return <WrappedComponent {...props} />;
  }

  // Preserve display name for DevTools
  AuthenticatedComponent.displayName =
    `withAuth(${WrappedComponent.displayName || WrappedComponent.name})`;

  return AuthenticatedComponent;
}

// Usage:
const ProtectedDashboard = withAuth(Dashboard);

// HOC: adding error boundary
function withErrorBoundary(WrappedComponent, fallback) {
  class ErrorBoundaryWrapper extends React.Component {
    state = { hasError: false };
    static getDerivedStateFromError() { return { hasError: true }; }
    render() {
      if (this.state.hasError) return fallback;
      return <WrappedComponent {...this.props} />;
    }
  }
  // Error boundaries MUST be class components
  // HOC is how to add them to function components
  return ErrorBoundaryWrapper;
}

// HOC: forwarding refs correctly
function withTheme(WrappedComponent) {
  // forwardRef to pass refs through the HOC
  const ThemedComponent = React.forwardRef((props, ref) => {
    const theme = useTheme();
    return <WrappedComponent {...props} ref={ref} theme={theme} />;
  });
  ThemedComponent.displayName =
    `withTheme(${WrappedComponent.name})`;
  return ThemedComponent;
}

// MODERN EQUIVALENT: custom hook (preferred for function components)
// Instead of: const Protected = withAuth(Dashboard)
// Use hook inside component:
function Dashboard() {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" />;
  return <DashboardContent />;
}
// OR: separate wrapper component:
function PrivateRoute({ children }) {
  const { user } = useAuth();
  return user ? children : <Navigate to="/login" />;
}
// <PrivateRoute><Dashboard /></PrivateRoute>
```

> **Code walkthrough:** This Higher-Order Components example demonstrates variable declaration using authentication. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **TAKEAWAY: use Object.freeze() to prevent mutation; const only guards the binding.**

**Why it matters:**

HOCs are part of React's component model history. Understanding them is
required for working with existing codebases (React Router v5 used HOCs:
`withRouter`). Knowing the pitfalls (wrapper hell, prop collisions) and
the modern hook-based alternatives shows pattern evolution awareness.

---

### 💻 Code Example

{% raw %}
```jsx
// WRAPPER HELL (classic HOC problem):
// Applying multiple HOCs creates DevTools nightmare
const ComponentWithEverything = withAuth(
  withTheme(
    withRouter(
      withErrorBoundary(
        withAnalytics(MyComponent)
      )
    )
  )
);
// DevTools shows: withAuth > withTheme > withRouter
//   > withErrorBoundary > withAnalytics > MyComponent

// MODERN: compose hook calls inline (flat)
function MyComponent() {
  const { user } = useAuth();       // was: withAuth
  const theme = useTheme();         // was: withTheme
  const navigate = useNavigate();   // was: withRouter (React Router v6)
  const analytics = useAnalytics(); // was: withAnalytics
  // Error boundaries still need HOC (class component requirement)
  return <div style={{ color: theme.primary }}>...</div>;
}

// WHEN HOC IS STILL VALUABLE:
// 1. Error boundaries (class component requirement)
// 2. Injecting behavior into legacy/class components
// 3. Library wrapping where you don't control the inner component
// 4. React.memo is technically a HOC:
const MemoizedList = React.memo(ExpensiveList);
```
{% endraw %}

> **Code walkthrough:** The "wrapper hell" example shows why HOCs fellice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> out of favor - 6 levels of nesting in DevTools makes debugging painful.
> The hook version is completely flat: all behavior is called at the top
> of one function component. React Router v6 replaced `withRouter` (HOC)
> with `useNavigate()` (hook) for this exact reason. The key insight:
> Error Boundaries are the only React pattern that still REQUIRES a class
> component (hooks can't catch render errors), so `withErrorBoundary` HOC
> is still the recommended pattern for adding error boundaries to function
> components.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> HOCs are functions that take a component and return an enhanced version.
> For example, `withAuth(MyComponent)` adds authentication checks before
> rendering. The modern approach is to use custom hooks inside the component
> instead. HOCs are still used for error boundaries (which need class
> components) and wrapping third-party components.

**Senior / Staff:**

> HOCs solved cross-cutting concerns before hooks existed. Their main
> limitations - wrapper hell in DevTools, implicit prop injection (unclear
> which HOC provides which prop), forwardRef complexity - led to the hooks
> API in React 16.8. For new code, custom hooks + wrapper components
> replace 95% of HOC use cases with clearer data flow. The 5%: error
> boundaries (class component requirement), third-party library adapters,
> and `React.memo` (which is itself an HOC). Understanding both patterns
> shows architectural maturity.

---

### ⚖️ Comparison Table

| Pattern | Composition | DevTools | Ref handling | Props clarity |
|---|---|---|---|---|
| HOC | Wrapping | Nested layers | forwardRef needed | Implicit injection |
| Custom hook | Call in component | Flat component | Direct | Explicit |
| Wrapper component | children prop | Visible layer | Direct | Explicit |
| Render prop | Function prop | Flat | Direct | Explicit |

---

### ⚠️ Common Misconceptions

**Misconception 1: HOCs are just like Python decorators and work the
same way.**

HOCs and Python decorators are similar in intent but different in
mechanism. A Python decorator replaces a function at definition time.
A React HOC wraps a component in a new component at runtime. The key
difference: HOCs create wrapper components in the React tree, adding
nesting visible in DevTools. Decorators do not create a wrapper
in any tree. This distinction matters because HOC nesting accumulates:
applying five HOCs creates five wrapper layers, inflating the component
tree and making DevTools debugging painful.

**Misconception 2: HOCs always add extra re-renders to wrapped
components.**

A well-written HOC does not add extra renders. The problem occurs
when HOC logic triggers state changes that cascade downward. If the
HOC passes stable references (via useMemo or useCallback) and its
own state does not change unnecessarily, the wrapped component
renders only when its own props change - same as without the HOC.
The actual performance risk is creating HOCs inside render functions:
`const Enhanced = withAuth(MyComponent)` inside a render call creates
a new component class on each render, which forces React to unmount
and remount the wrapped component every time.

**Misconception 3: Custom hooks have made HOCs obsolete in all
situations.**

Custom hooks replace most HOC use cases - specifically, HOCs that
inject behavior by calling hooks internally. But HOCs remain the
right tool for: (1) wrapping class components that cannot call hooks,
(2) library integrations that need to inject props into arbitrary
components without touching their source, and (3) error boundaries
(which cannot be implemented as hooks - only class components support
`componentDidCatch`). Knowing when each pattern applies is the signal
interviewers look for.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: HOC swallows the wrapped component's ref.**

Symptom: `React.createRef()` or `useRef()` attached to the HOC-wrapped
component returns `null` or points to the HOC wrapper instead of the
inner component. Root cause: HOC does not forward refs - refs are
blocked at the HOC boundary by default. Diagnosis: add a console.log
to the ref callback to check what it receives; check whether
`React.forwardRef` is used in the HOC definition. Fix: wrap the HOC
with `React.forwardRef`: `const HOC = React.forwardRef((props, ref) =>
<Wrapped {...props} ref={ref} />)`. Also set `HOC.displayName` for
readable DevTools output.

**Failure Mode 2: Props collision between HOC injected props and
wrapped component props.**

Symptom: a prop injected by the HOC (e.g. `isLoading`) is also
accepted by the wrapped component for a different purpose; one
silently overwrites the other, causing wrong behavior with no error
message. Diagnosis: list all props injected by the HOC and compare
to the wrapped component's prop types/TypeScript interface. Fix: HOCs
should document their injected props and use namespaced or prefixed
prop names to avoid collisions. Prefer TypeScript HOC signatures that
separate "injected" from "passthrough" props using `Omit<T, K>`.

**Failure Mode 3: HOC defined inside the render function causes
perpetual remounting.**

Symptom: wrapped component loses state on every parent render; inputs
reset, animations restart, network requests repeat. Root cause: HOC
is created inside the render/component body: `function Parent() {
const Wrapped = withAuth(Child); return <Wrapped />; }` - React sees
a new component type on every render and unmounts then remounts the
tree. Diagnosis: add a `console.log` in Child's `componentDidMount`
or `useEffect(()=>{...},[])` - if it fires on every parent update,
the HOC is being recreated. Fix: always define HOC-wrapped components
at module scope, never inside render functions.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| Define HOC | 2-3 min | Function returning component |
| HOC problems | 3-4 min | Wrapper hell, props collision |
| HOC to hooks migration | 3-4 min | Pattern evolution |
| forwardRef in HOC | 3-4 min | Ref forwarding |
| displayName importance | 2-3 min | DevTools debugging |
| Error boundary HOC | 3-4 min | Class requirement |
| React.memo as HOC | 2-3 min | Modern example |

---

**[JUNIOR] Q1 - [TRADE-OFF] How do you migrate a withAuth HOC to the hooks pattern?** `[SENIOR]`**

> **Answer:**
>
> > ```jsx
> > // BEFORE: HOC pattern
> > function withAuth(WrappedComponent) {
> >   function Protected(props) {
> >     const { user } = useAuthContext();
> >     if (!user) return <Navigate to="/login" />;
> >     return <WrappedComponent user={user} {...props} />;
> >   }
> >   return Protected;
> > }
> > const ProtectedDashboard = withAuth(Dashboard);
> >
> > // AFTER: route-level protection (preferred)
> > function RequireAuth({ children }) {
> >   const { user } = useAuth();
> >   return user ? children : <Navigate to="/login" />;
> > }
> > // In router:
> > <Route path="/dashboard" element={
> >   <RequireAuth><Dashboard /></RequireAuth>
> > } />
> >
> > // AFTER: hook inside component (for per-component protection)
> > function Dashboard() {
> >   useRequireAuth(); // throws redirect if not authenticated
> >   return <DashboardContent />;
> > }
> >
> > // useRequireAuth hook:
> > function useRequireAuth() {
> >   const { user } = useAuth();
> >   const navigate = useNavigate();
> >   useEffect(() => {
> >     if (!user) navigate('/login');
> >   }, [user, navigate]);
> >   return user;
> > }
> > ```
> >
> > The route-level pattern is cleanest for auth: protection is declared
> > in the routing configuration, not scattered across components. The hook
> > pattern is for cases where components need to self-protect regardless
> > of routing context.
>
> *What separates good from great:* The recommendation to protect at
> route level rather than component level is the architectural insight.
> Per-component auth HOCs or hooks create hidden coupling and are easy to
> forget. Route-level protection creates a single source of truth in the
> router config - every protected page is visible in one place.

---

---

---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


# Render Props and Compound Components

🎯 **Interview Weight:** working (★★☆) - compound components show advanced
React API design; asked at senior level for component library design

---

### 🎯 Model Answer

**30 seconds:**

> Render props: a component accepts a function prop that it calls to
> render content, sharing internal state with the caller.
> `<Mouse render={pos => <Cat position={pos} />} />`.
> Compound components: a set of related components that share implicit
> state through Context. `<Select.Root>`, `<Select.Option>`, etc.
> Both patterns create flexible, reusable component APIs. Custom hooks
> replaced render props; compound components remain the pattern for
> UI library design.

**3 minutes:**

> Render props share behavior (state + functions) with callers via
> function invocation. The `children` prop is a render prop when it's
> a function. Problems: nesting ("callback hell"), TypeScript verbosity.
> Custom hooks solve the same problem with less ceremony.
>
> Compound components use Context to share state between a parent
> and its children. The parent manages state; children read via Context.
> Excellent for UI libraries: `<Tabs>`, `<Accordion>`, `<Select>`.
> Benefits: consumers control composition without knowing internal state.

**Blank Mind Recovery:**

**(1) Restate:** "Render props: function as prop, called with internal state.
Compound components: parent manages state + Context, children read it.
Both: share behavior with flexible composition. Render props -> modern hooks.
Compound components: still best for UI library component APIs."

---

### 📘 Concept Explanation

**What it is:**

Render props expose component logic through a function prop. Compound
components expose a group of related components that share state
implicitly through React Context, providing a cohesive API.

**How it works:**

{% raw %}
```jsx
// RENDER PROP PATTERN:
function Toggle({ render }) {
  const [on, setOn] = useState(false);
  return render({ on, toggle: () => setOn(o => !o) });
}

// Usage:
<Toggle render={({ on, toggle }) => (
  <div>
    <button onClick={toggle}>{on ? 'Hide' : 'Show'}</button>
    {on && <div>Content</div>}
  </div>
)} />

// children as function (same pattern):
<Toggle>
  {({ on, toggle }) => (
    <button onClick={toggle}>{on ? 'Hide' : 'Show'}</button>
  )}
</Toggle>

// MODERN: custom hook replaces render props
function useToggle(initial = false) {
  const [on, setOn] = useState(initial);
  const toggle = useCallback(() => setOn(o => !o), []);
  return { on, toggle };
}
// Much cleaner:
function MyComponent() {
  const { on, toggle } = useToggle();
  return <button onClick={toggle}>{on ? 'Hide' : 'Show'}</button>;
}

// COMPOUND COMPONENTS PATTERN:
// The full pattern for an Accordion UI component

const AccordionContext = createContext(null);

function Accordion({ children }) {
  const [openId, setOpenId] = useState(null);
  const toggle = useCallback((id) => {
    setOpenId(current => current === id ? null : id);
  }, []);

  return (
    <AccordionContext.Provider value={{ openId, toggle }}>
      <div className="accordion">{children}</div>
    </AccordionContext.Provider>
  );
}

function AccordionItem({ id, children }) {
  const { openId, toggle } = useContext(AccordionContext);
  const isOpen = openId === id;

  return (
    <div className="accordion-item">
      <button
        onClick={() => toggle(id)}
        aria-expanded={isOpen}
      >
        {children[0]} {/* Header */}
      </button>
      {isOpen && <div className="accordion-panel">{children[1]}</div>}
    </div>
  );
}

// Attach as namespaced sub-components:
Accordion.Item = AccordionItem;

// Usage: flexible, consumer controls structure
<Accordion>
  <Accordion.Item id="1">
    <span>Section 1 Header</span>
    <p>Section 1 content</p>
  </Accordion.Item>
  <Accordion.Item id="2">
    <span>Section 2 Header</span>
    <p>Section 2 content</p>
  </Accordion.Item>
</Accordion>
```
{% endraw %}

> **Code walkthrough:** This Render Props and Compound Components example demonstrates variable declaration using React hook. **KEY MECHANISM:** const prevents reassignment but not mutation; the reference is locked, the value is not. **WHY IT MATTERS:** const obj = {}; obj.x = 1 works - const does not freeze the object. **TAKEAWAY: use Object.freeze() to prevent mutation; const only guards the binding.**

**Why it matters:**

Compound components are the dominant pattern for UI library design
(Radix UI, Headless UI, Shadcn all use compound components). Understanding
this pattern explains how `<Select>`, `<Dialog>`, `<Tabs>` components
in popular libraries work. It's frequently asked at senior level for
"design a reusable Tabs component" challenges.

---

### 💻 Code Example

```jsx
// DESIGN CHALLENGE: Implement a type-safe Tabs component
// (common senior interview ask)

const TabsContext = createContext(null);

function Tabs({ defaultValue, children }) {
  const [active, setActive] = useState(defaultValue);
  const value = useMemo(
    () => ({ active, setActive }),
    [active]
  );
  return (
    <TabsContext.Provider value={value}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

function TabsList({ children }) {
  return <div role="tablist" className="tabs-list">{children}</div>;
}

function TabsTrigger({ value, children }) {
  const { active, setActive } = useContext(TabsContext);
  return (
    <button
      role="tab"
      aria-selected={active === value}
      onClick={() => setActive(value)}
    >
      {children}
    </button>
  );
}

function TabsContent({ value, children }) {
  const { active } = useContext(TabsContext);
  if (active !== value) return null;
  return (
    <div role="tabpanel">{children}</div>
  );
}

Tabs.List = TabsList;
Tabs.Trigger = TabsTrigger;
Tabs.Content = TabsContent;

// Usage:
<Tabs defaultValue="overview">
  <Tabs.List>
    <Tabs.Trigger value="overview">Overview</Tabs.Trigger>
    <Tabs.Trigger value="details">Details</Tabs.Trigger>
  </Tabs.List>
  <Tabs.Content value="overview"><OverviewPanel /></Tabs.Content>
  <Tabs.Content value="details"><DetailsPanel /></Tabs.Content>
</Tabs>
```

> **Code walkthrough:** The Tabs compound component shares `active` stateice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> and `setActive` via Context. `TabsTrigger` reads `active` (for styling)
> and calls `setActive` (for navigation). `TabsContent` reads `active` to
> decide whether to render. No prop drilling: each sub-component accesses
> exactly what it needs from Context. The consumer sees a clean, semantic
> API: `<Tabs.Trigger>` is clearly the trigger for tab navigation. The
> `useMemo` on the context value ensures re-renders only happen when `active`
> changes, not when any parent re-renders.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Render props pass a function to a component, which calls it with its
> internal state to let the consumer render whatever it needs. Compound
> components are groups of related components (like `<Select>` and
> `<Select.Option>`) that share state through Context without explicit
> prop passing. Both patterns allow flexible composition.

**Senior / Staff:**

> Render props were the pre-hooks solution to behavior reuse. Custom hooks
> are now preferred because they avoid nesting and are easier to type.
> Compound components, however, remain the best API for stateful UI
> components because they give consumers control over composition without
> exposing internal state as props. The compound component pattern explains
> why Radix UI's `<Dialog.Root>`, `<Dialog.Trigger>`, `<Dialog.Content>`
> API works: the Root manages state via Context, Trigger and Content consume
> it. Headless UI libraries that use this pattern are infinitely more
> flexible than "all-in-one" components that accept props for every
> possible variant.

---

### ⚖️ Comparison Table

| Pattern | State sharing | Composition | Use today |
|---|---|---|---|
| Render props | Via function call | Nested | Migrate to hooks |
| Children as function | Via function call | Nested | Migrate to hooks |
| Custom hook | Via return value | Flat | Preferred |
| Compound components | Via Context | Semantic sub-components | UI library design |

---

### ⚠️ Common Misconceptions

**Misconception 1: Render props and compound components solve the
same problem.**

Render props pass behavior downward: a parent controls state and
passes a render function the child can use. Compound components
share implicit state across siblings: a parent `<Tabs>` holds active
tab state; `<Tabs.Tab>` and `<Tabs.Panel>` each read it without prop
drilling. The patterns are complementary, not alternatives. Render
props answer "how do I share logic?" while compound components answer
"how do I share state between related components with a natural API?"

**Misconception 2: Compound components must use React.cloneElement
to share state.**

`React.cloneElement` was the original implementation technique. The
modern approach uses `React.createContext` - the parent puts state
in a Provider, each child component reads it with `useContext`. The
Context approach is simpler (no child enumeration), works with
non-direct children (deep nesting), and avoids the `cloneElement`
limitation of only injecting props into direct children. Any new
compound component implementation should use Context.

**Misconception 3: Render prop callbacks execute like functions and
have no performance concern.**

The most common performance issue with render props: passing an
inline arrow function as the render prop creates a new function
reference on every parent render, which can cause the child to
re-render even when underlying data has not changed. The fix is
to memoize the render prop using `useCallback` when the child
implements `React.memo`. This is a subtle issue because the child
re-renders silently with no error or warning.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Compound component children used outside the
Provider cause cryptic undefined errors.**

Symptom: `Cannot read property 'activeTab' of undefined` or similar
when a `<Tabs.Tab>` is rendered outside its `<Tabs>` wrapper.
Root cause: the child calls `useContext(TabsContext)` but no Provider
is an ancestor, so context returns its default value (usually
`undefined` or an empty object). Diagnosis: check if the context
default value is defensive (`{}` or `null` with a guard). Fix:
add a guard in the context consumer: `const ctx = useContext(Ctx);
if (!ctx) throw new Error("Tab must be used inside Tabs");` This
surfaces the misconfiguration immediately with a clear error instead
of a cryptic downstream crash.

**Failure Mode 2: Render prop inline function prevents
React.memo optimization.**

Symptom: a child component wrapped in `React.memo` still re-renders
on every parent update. Diagnosis: check if the render prop is
passed as an inline arrow function: `<Mouse render={(pos) =>
<Cat pos={pos} />} />`. Every parent render creates a new function
reference, failing memo's shallow equality check. Fix: extract the
render prop to `useCallback` or to a stable component-level function.

**Failure Mode 3: Context value object recreated on every render
breaks compound component performance.**

Symptom: all compound component children re-render whenever any
ancestor re-renders, even when the compound component's own state
has not changed. Root cause: context value passed to Provider is
an object literal: `<Ctx.Provider value={{ activeTab, setActiveTab }}>`.
A new object reference is created on each render. Diagnosis: wrap
the context value in `useMemo`: `const value = useMemo(() =>
({ activeTab, setActiveTab }), [activeTab])`. This prevents
unnecessary renders of all context consumers.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| Define render props | 2-3 min | Function as prop |
| Render props vs hooks | 2-3 min | Evolution |
| Compound component mechanism | 3-4 min | Context sharing |
| Design a Tabs component | 7-10 min | Full implementation |
| Namespace pattern | 2-3 min | `Tabs.Trigger` |
| Headless component library | 3-4 min | Radix/Headless UI |
| When to use which pattern | 3-4 min | Decision framework |

---

**[SENIOR] Q1 - [SCENARIO] Design a Dropdown component using compound components pattern.**

> **Answer:**
>
> ```jsx
> const DropdownCtx = createContext(null);
>
> function Dropdown({ children }) {
>   const [open, setOpen] = useState(false);
>   const ref = useRef(null);
>
>   // Close on outside click
>   useEffect(() => {
>     function handleOutside(e) {
>       if (ref.current && !ref.current.contains(e.target)) {
>         setOpen(false);
>       }
>     }
>     document.addEventListener('mousedown', handleOutside);
>     return () => document.removeEventListener('mousedown', handleOutside);
>   }, []);
>
>   const value = useMemo(() => ({ open, setOpen }), [open]);
>   return (
>     <DropdownCtx.Provider value={value}>
>       <div ref={ref} className="dropdown">{children}</div>
>     </DropdownCtx.Provider>
>   );
> }
>
> Dropdown.Trigger = function DropdownTrigger({ children }) {
>   const { open, setOpen } = useContext(DropdownCtx);
>   return (
>     <button
>       aria-haspopup="true"
>       aria-expanded={open}
>       onClick={() => setOpen(o => !o)}
>     >
>       {children}
>     </button>
>   );
> };
>
> Dropdown.Menu = function DropdownMenu({ children }) {
>   const { open } = useContext(DropdownCtx);
>   if (!open) return null;
>   return <ul role="menu" className="dropdown-menu">{children}</ul>;
> };
>
> Dropdown.Item = function DropdownItem({ onClick, children }) {
>   const { setOpen } = useContext(DropdownCtx);
>   return (
>     <li role="menuitem">
>       <button onClick={() => { onClick?.(); setOpen(false); }}>
>         {children}
>       </button>
>     </li>
>   );
> };
>
> // Usage:
> <Dropdown>
>   <Dropdown.Trigger>Options</Dropdown.Trigger>
>   <Dropdown.Menu>
>     <Dropdown.Item onClick={handleEdit}>Edit</Dropdown.Item>
>     <Dropdown.Item onClick={handleDelete}>Delete</Dropdown.Item>
>   </Dropdown.Menu>
> </Dropdown>
> ```
>
> *What separates good from great:* Including accessibility attributes
> (`aria-haspopup`, `aria-expanded`, `role="menu"`, `role="menuitem"`)
> shows production awareness. The outside click handler via `useEffect` +
> `useRef` is the standard pattern for dismissing floating UI. The `setOpen(false)`
> in `Dropdown.Item.onClick` auto-closes the menu after selection - expected UX behavior.

---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*



