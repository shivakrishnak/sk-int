---
layout: default
title: "React - L2 State Management"
parent: "React"
nav_order: 5
permalink: /react/l2-state-management/
render_with_liquid: false
---

# Context API and useContext

🎯 **Interview Weight:** working (★★☆) - Context misuse (performance) is
a common interview topic; knowing when to use vs avoid is critical

---

### 🎯 Model Answer

**30 seconds:**

> Context provides a way to pass data through the component tree without
> prop drilling. Create with `createContext`, provide with `<Context.Provider value={...}>`,
> consume with `useContext(Context)`. The critical performance issue: when
> context value changes, ALL consumers re-render. Mitigation: split contexts
> by update frequency, memoize the value object.

**3 minutes:**

> Context is for data that is "global" to a component subtree: auth state,
> theme, locale, feature flags. Not appropriate for data that changes
> frequently (every keystroke, every frame) because all consumers re-render.
>
> Performance mitigation: (1) Split into separate contexts (AuthContext,
> ThemeContext) so changes to one don't affect consumers of another.
> (2) Memoize the value: `useMemo(() => ({ user, login, logout }), [user])`.
> (3) For frequently changing data, use a state management library instead.

**Blank Mind Recovery:**

**(1) Restate:** "Context: pass data without prop drilling. createContext,
Provider value, useContext. Perf problem: all consumers re-render on value
change. Fix: split contexts, memoize value. Not for high-frequency state.
Use for: auth, theme, locale, feature flags."

---

### 📘 Concept Explanation

**What it is:**

Context is a React mechanism for sharing values between components without
explicit prop passing. A Provider component wraps the subtree that needs
access. Any component inside can read the value with `useContext`.

**How it works:**

```jsx
import { createContext, useContext, useState, useMemo } from 'react';

// 1. CREATE
const AuthContext = createContext(null);

// 2. PROVIDE (at app or subtree root)
function AuthProvider({ children }) {
  const [user, setUser] = useState(null);

  // MEMOIZE to prevent consumer re-renders on unrelated parent renders
  const value = useMemo(() => ({
    user,
    login: async (credentials) => {
      const u = await loginAPI(credentials);
      setUser(u);
    },
    logout: () => setUser(null),
  }), [user]); // re-create only when user changes

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

// 3. CONSUME
function UserAvatar() {
  const { user } = useContext(AuthContext);
  return user ? <img src={user.avatar} alt={user.name} /> : null;
}

// 4. CUSTOM HOOK WRAPPER (best practice)
function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
}
// Components use: const { user, login } = useAuth();

// PERFORMANCE ISSUE: SPLIT CONTEXTS
// BAD: one context with frequently changing + stable values
const AppContext = createContext(null);
// { user, theme, notifications } in one context
// Updating notifications (every 5s) causes ALL consumers to re-render!

// GOOD: separate contexts by update frequency
const AuthContext = createContext(null);    // changes on login/logout
const ThemeContext = createContext(null);   // changes on theme toggle
const NotifContext = createContext(null);   // changes frequently
// Components only subscribe to what they need

// SPLIT PROVIDER PATTERN:
function AppProviders({ children }) {
  return (
    <AuthProvider>
      <ThemeProvider>
        <NotifProvider>
          {children}
        </NotifProvider>
      </ThemeProvider>
    </AuthProvider>
  );
}
```

**Why it matters:**

Context is frequently misused: (1) Used for server data (use TanStack Query
instead), (2) Used for frequently changing state (causes widespread re-renders),
(3) Not memoized (causes re-renders even when value is the same).

---

### 💻 Code Example

```jsx
// THE CONTEXT PERFORMANCE PROBLEM:
const SlowContext = createContext(null);

function Parent() {
  const [count, setCount] = useState(0);
  // NEW OBJECT on every render -> all consumers re-render
  return (
    <SlowContext.Provider value={{ count, setCount }}>
      {/* Every consumer re-renders when Parent re-renders, even for
          unrelated state changes that don't touch count */}
      <ExpensiveChild />
    </SlowContext.Provider>
  );
}

// FIX 1: memoize the value
function Parent() {
  const [count, setCount] = useState(0);
  const value = useMemo(
    () => ({ count, setCount }),
    [count] // only new object when count changes
  );
  return (
    <SlowContext.Provider value={value}>
      <ExpensiveChild />
    </SlowContext.Provider>
  );
}

// FIX 2: split read/write contexts
const CountContext = createContext(0);         // read
const SetCountContext = createContext(null);   // write (stable setter)

function CountProvider({ children }) {
  const [count, setCount] = useState(0);
  return (
    <SetCountContext.Provider value={setCount}>
      <CountContext.Provider value={count}>
        {children}
      </CountContext.Provider>
    </SetCountContext.Provider>
  );
}
// Components reading count re-render only when count changes
// Components calling setCount never re-render from count changes
```

> **Code walkthrough:** The performance problem is subtle: the Provider
> creates a new object reference `{ count, setCount }` on every render of
> `Parent`. React's Context comparison uses `Object.is` - a new object
> always fails equality, triggering re-renders in ALL consumers even if
> `count` didn't change. `useMemo` with `[count]` creates a new object
> only when `count` changes. The read/write split pattern is more elegant:
> `setCount` from `useState` is already stable (React guarantees it never
> changes), so the write context never causes re-renders.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Context lets you share data across components without passing props
> through every level. Create a context with `createContext`, wrap your
> tree in a Provider with a value, and consume with `useContext`. Common
> uses: user auth state, theme, language settings. The main limitation
> is performance: when the context value changes, all components using
> `useContext` re-render.

**Senior / Staff:**

> Context has a critical performance characteristic: a single Provider
> value change causes all consumers to synchronously re-render, regardless
> of which part of the value they actually use. Mitigation requires
> architectural decisions: split contexts by update frequency (auth changes
> rarely, notifications change often), memoize values (prevent re-renders
> from parent re-renders that don't change the value), and consider
> splitting read/write contexts (setters are stable, state values change).
> For complex shared state, external libraries (Zustand, Jotai) use
> subscription-based access (components re-render only when the specific
> slice they subscribe to changes), which is fundamentally more efficient
> than Context for frequently-changing data.

---

### ⚖️ Comparison Table

| Approach | Re-render scope | Performance | Use case |
|---|---|---|---|
| Context (no memo) | All consumers always | Poor for frequent updates | Auth, theme, locale |
| Context + useMemo | All consumers on change | Good for infrequent | Auth, config |
| Split contexts | Per-context consumers | Good | Separate concerns |
| Zustand | Only subscribed components | Excellent | Global UI state |
| TanStack Query | Query-specific components | Excellent | Server data |

---

### ⚠️ Common Misconceptions

**Misconception 1: Context API is a state management solution like Redux.**

Context is a dependency injection mechanism - it provides a way to pass values down the component tree without prop drilling. It does not provide: optimized re-render behavior (all consumers re-render when context value changes, regardless of whether they use the changed part), devtools for time-travel debugging, middleware for side effects, or a defined action/reducer pattern. Context is appropriate for low-frequency updates (theme, locale, auth state). For high-frequency updates (search query, form state, realtime data), use a dedicated state management library that provides selective subscription.

**Misconception 2: Splitting context into many smaller contexts always improves performance.**

Splitting context reduces unnecessary re-renders only if the contexts update at different frequencies and consumers subscribe to different contexts. If all the data in the context updates together (e.g., user profile object), splitting into `UserNameContext`, `UserEmailContext`, `UserRoleContext` adds complexity with no performance benefit. Split context along UPDATE FREQUENCY lines, not data type lines.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Context value changes on every parent render causing all consumers to re-render.**

Symptom: performance profile shows all context consumers re-rendering on every parent render even when context data hasn't changed. Root cause: context value is an object literal created in the Provider component render: `<MyContext.Provider value={{ user, setUser }}>` creates a new object on every render. Fix: memoize the context value: `const value = useMemo(() => ({ user, setUser }), [user]);` to stabilize the reference.

**Failure Mode 2: Context consumed in component before the Provider is mounted throws.**

Symptom: `useContext` returns undefined; component throws `Cannot read properties of undefined`; occurs in deeply nested components or portals. Root cause: component rendered outside the Provider's subtree, or Provider not yet mounted when the component first renders. Fix: add a default value to `createContext(defaultValue)` that is safe to use; add a guard: `const ctx = useContext(MyContext); if (!ctx) throw new Error('MyProvider is required');`.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| Context mechanism | 2-3 min | Provider, consumer |
| Performance problem | 3-4 min | All consumers re-render |
| Memoize context value | 3-4 min | useMemo pattern |
| Split contexts | 3-4 min | Update frequency |
| Context vs Zustand | 3-4 min | When to use each |
| Custom useAuth hook | 2-3 min | Error boundary |
| Context for server data | 2-3 min | Anti-pattern |

---

**Q1: When would you NOT use Context for shared state?** `[SENIOR]`
DECISION

> **Answer:**
>
> > Avoid Context for:
> >
> > 1. **Server data** (users, products, orders from APIs): Context provides
> >    no caching, no background refetch, no invalidation, no loading states.
> >    Use TanStack Query. Context would require reimplementing all of that.
> >
> > 2. **Frequently changing state** (mouse position, scroll, animations,
> >    real-time data that updates every second): Context re-renders ALL
> >    consumers synchronously. For 100 consumers and 60fps animations,
> >    that's 6000 component renders per second from Context alone.
> >    Use Zustand's subscribe or refs + event listeners.
> >
> > 3. **Large complex state** (form state with 50 fields, shopping cart
> >    with complex discount logic): Context offers no selectors. Any field
> >    change re-renders all consumers. Use Zustand or Redux Toolkit for
> >    selector-based subscriptions.
> >
> > Use Context for: auth state (changes rarely), theme (changes on user
> > action), locale (changes on language switch), feature flags (set once).
> > The pattern: Context for stable "ambient" data, external store for
> > dynamic data.
>
> *What separates good from great:* Articulating that Context vs external
> store is about subscription granularity. Zustand components subscribe
> to a selector: `const theme = useStore(s => s.theme)` - only re-renders
> when `theme` changes, regardless of other store changes. Context provides
> no selector mechanism - you get the whole value or nothing. This
> fundamental difference explains why Zustand is almost always better
> for non-ambient state.

---

---

# External State Management (Redux, Zustand, Jotai)

🎯 **Interview Weight:** working (★★☆) - state management library choice
is a common architecture question at mid/senior level

---

### 🎯 Model Answer

**30 seconds:**

> External state management: Zustand (simple, minimal boilerplate, selector-based),
> Redux Toolkit (complex, Flux pattern, excellent DevTools, time-travel debugging),
> Jotai (atomic state, derived atoms, minimal). Rule: Zustand for most apps,
> Redux Toolkit for apps needing strict data flow governance and time-travel
> debugging, Jotai for granular atomic state. Never use Redux for simple CRUD.

**3 minutes:**

> Zustand: `create(set => ({ state, action: () => set(...) }))` - minimal API,
> components subscribe to slices via selectors. Re-renders only when subscribed
> slice changes.
>
> Redux Toolkit: `createSlice` + `configureStore`. Actions, reducers, selectors
> separated. `createAsyncThunk` for async. Best for: apps where state mutations
> must be auditable, teams needing strict patterns.
>
> Jotai: atoms are reactive signals. `atom(initialValue)`, `useAtom(myAtom)`.
> Derived atoms recompute automatically. Best for: form state, dependent UI state.

**Blank Mind Recovery:**

**(1) Restate:** "External state: Zustand=simple (create + selector), Redux
Toolkit=structured (slice+store+action), Jotai=atomic (atom + useAtom).
TanStack Query for server data (not these). Choose: Zustand default, Redux
for governance, Jotai for atomic."

---

### 📘 Concept Explanation

**What it is:**

External state management libraries maintain application state outside
the React component tree, using subscription-based updates (components
re-render only when their specific state slice changes).

**How it works:**

```javascript
// ZUSTAND: minimal and flexible
import { create } from 'zustand';

const useCartStore = create((set, get) => ({
  items: [],
  total: 0,

  addItem: (product) => set(state => {
    const items = [...state.items, product];
    return { items, total: items.reduce((s, i) => s + i.price, 0) };
  }),

  removeItem: (id) => set(state => {
    const items = state.items.filter(i => i.id !== id);
    return { items, total: items.reduce((s, i) => s + i.price, 0) };
  }),

  clearCart: () => set({ items: [], total: 0 }),
}));

// Component: subscribe to slice only
function CartCount() {
  const itemCount = useCartStore(state => state.items.length);
  // Only re-renders when items array length changes
  return <span>{itemCount} items</span>;
}

function CartTotal() {
  const total = useCartStore(state => state.total);
  // Only re-renders when total changes
  return <span>${total.toFixed(2)}</span>;
}

// REDUX TOOLKIT: structured and auditable
import { createSlice, configureStore } from '@reduxjs/toolkit';
import { useSelector, useDispatch } from 'react-redux';

const cartSlice = createSlice({
  name: 'cart',
  initialState: { items: [], total: 0 },
  reducers: {
    addItem: (state, action) => {
      // Immer: write mutating code, gets immutable result
      state.items.push(action.payload);
      state.total += action.payload.price;
    },
    removeItem: (state, action) => {
      state.items = state.items.filter(i => i.id !== action.payload);
      state.total = state.items.reduce((s, i) => s + i.price, 0);
    },
  },
});

const store = configureStore({ reducer: { cart: cartSlice.reducer } });

// Component:
function CartCount() {
  const count = useSelector(state => state.cart.items.length);
  return <span>{count} items</span>;
}

// JOTAI: atomic state
import { atom, useAtom } from 'jotai';

const cartItemsAtom = atom([]);
// Derived atom: automatically recomputes when cartItemsAtom changes
const cartTotalAtom = atom(get => {
  const items = get(cartItemsAtom);
  return items.reduce((sum, item) => sum + item.price, 0);
});

function CartTotal() {
  const [total] = useAtom(cartTotalAtom); // read-only derived atom
  return <span>${total.toFixed(2)}</span>;
}
```

**Why it matters:**

Choosing the wrong state management library is an architectural debt.
Redux in a simple app adds boilerplate without benefit. Zustand in an
app with complex audit requirements misses Redux's tracing capabilities.

---

### 💻 Code Example

```javascript
// MIGRATION: Redux -> Zustand (same behavior, less code)

// BEFORE: Redux (40 lines)
// action types, action creators, reducer, store setup, connect...

// AFTER: Zustand (15 lines)
const useAuthStore = create((set) => ({
  user: null,
  loading: false,
  error: null,

  login: async (credentials) => {
    set({ loading: true, error: null });
    try {
      const user = await loginAPI(credentials);
      set({ user, loading: false });
    } catch (error) {
      set({ error: error.message, loading: false });
    }
  },

  logout: () => set({ user: null }),
}));

// Component:
function LoginButton() {
  const { user, login, logout } = useAuthStore();
  return user
    ? <button onClick={logout}>Logout {user.name}</button>
    : <button onClick={() => login(credentials)}>Login</button>;
}
```

> **Code walkthrough:** Zustand collapses Redux's action types, action
> creators, and reducer into a single `create()` call. The actions (`login`,
> `logout`) are co-located with the state they manage. Async actions use
> regular async/await - no thunk middleware needed. The component receives
> state and actions from the same `useAuthStore` hook. Selector usage:
> `const user = useAuthStore(s => s.user)` subscribes only to `user` changes.
> Using `const { user, login } = useAuthStore()` subscribes to the entire
> store object (fine for simple cases, inefficient for large stores).

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> For global state that many components need, we have options: Context
> (built-in but no selectors), Zustand (simple, minimal boilerplate),
> Redux Toolkit (more structured, great DevTools). Zustand is the best
> starting point for most apps. Use Redux when you need time-travel
> debugging or strict data flow patterns.

**Senior / Staff:**

> State management library choice is an architectural decision with team
> implications. Zustand's minimal API has low cognitive overhead and fast
> onboarding. Redux Toolkit's strict Flux pattern creates predictable data
> flow that's valuable for large teams - every state change is an action
> with a name, making debugging easier. The key question: does the team
> need governance (Redux) or freedom (Zustand)? For server data (anything
> from an API), neither - use TanStack Query. Conflating server state with
> client state (storing API responses in Redux/Zustand) is the most common
> React state management mistake.

---

### ⚖️ Comparison Table

| Library | API complexity | Re-render model | DevTools | Best for |
|---|---|---|---|---|
| useState/Context | Low | All consumers | Basic | Local/small shared state |
| Zustand | Very low | Selector-based | Good | Most apps |
| Jotai | Low | Atom-based | Good | Atomic/derived state |
| Redux Toolkit | Medium | Selector-based | Excellent | Large teams, audit trails |
| TanStack Query | Medium | Query-based | Excellent | Server state (API data) |

---

### ⚠️ Common Misconceptions

**Misconception 1: Redux is the standard for React state management in 2024.**

Redux had ~90% market share among React state management solutions in 2018-2019. By 2023-2024, Zustand, Jotai, Valtio, and React Query have captured significant market share for specific use cases. Redux Toolkit reduced Redux boilerplate dramatically, but the framework choice depends on the use case: Zustand for simple global state, Jotai for atomic state co-located with components, React Query for server state, and Redux for complex client-side state with middleware requirements.

**Misconception 2: Global state should be used for all application data.**

Global state creates tight coupling between distant components. Prefer local state wherever possible: form state, UI toggle state, transient animations, and component-specific data should live in the component. Lift state up to the nearest common ancestor when siblings need to share it. Use global state only for truly application-wide concerns: authentication, user preferences, shopping cart, real-time connection status. Over-globalized state makes it impossible to reuse components and turns every component change into a global state refactor.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Zustand store causes stale closure in actions.**

Symptom: Zustand action reads outdated state; incrementing counter from outside React gives wrong result when called rapidly. Root cause: action is defined outside the store's `set()` call and captures state from its closure rather than the current store state. Fix: use `get()` inside actions to read current state: `increment: () => set(state => ({ count: state.count + 1 }))` instead of capturing the count variable in the action closure.

**Failure Mode 2: Redux selector returning new object on every render defeats memoization.**

Symptom: components re-render on every store update even when the component's data hasn't changed; `useSelector` does not prevent unnecessary re-renders. Root cause: selector returns a new derived object: `useSelector(state => ({ a: state.a, b: state.b }))` creates a new object reference on every call. Fix: use `createSelector` from Reselect to memoize derived values; or use separate `useSelector` calls per field.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| Redux vs Zustand | 3-4 min | When each is appropriate |
| Server vs client state | 3-4 min | Critical distinction |
| Zustand selector usage | 2-3 min | Re-render optimization |
| Redux Toolkit migration | 3-4 min | createSlice |
| Jotai atoms | 2-3 min | Atomic model |
| Zustand persistence | 2-3 min | Middleware |
| State normalization | 3-4 min | Flat vs nested |

---

**Q1: When would you choose Redux Toolkit over Zustand?** `[SENIOR]`
DECISION

> **Answer:**
>
> > Choose Redux Toolkit when:
> >
> > 1. **Large team (15+ developers)**: Redux's strict patterns prevent
> >    anti-patterns. Action names document every state change. No accidental
> >    direct mutations possible (Immer enforces immutability).
> >
> > 2. **Audit/compliance requirements**: Redux DevTools' time-travel
> >    debugging shows exactly what happened before a bug. For fintech,
> >    healthcare, or complex business logic, this is invaluable.
> >
> > 3. **Complex async flows**: Redux's middleware ecosystem (RTK Query,
> >    Saga) handles complex orchestration scenarios (polling, optimistic
> >    updates, request deduplication) with patterns the whole team knows.
> >
> > 4. **Existing Redux codebase**: migration cost exceeds benefit unless
> >    there's a specific pain point.
> >
> > Choose Zustand when:
> >
> > 1. **Small-medium team**: lower cognitive overhead, faster to write
> > 2. **Simple client state**: theme, modal states, wizard steps
> > 3. **New project**: Zustand's minimal API is a better starting point
> >    than Redux's indirection
> >
> > In either case: use TanStack Query for server/API state.
> > Both libraries are for CLIENT state only.
>
> *What separates good from great:* The "team size" and "governance needs"
> framing. Redux's boilerplate is not overhead - it's governance. For a
> team of 30 developers, having every state mutation as a named action
> with a type string means any developer can grep for all places that
> modify a specific piece of state. Zustand's freedom becomes complexity
> at scale. The staff engineer answer identifies team context as the
> primary decision factor, not technical preference.
