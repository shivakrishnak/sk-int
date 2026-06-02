---
layout: default
title: "React - L2 Component Patterns"
parent: "React"
nav_order: 6
permalink: /react/l2-component-patterns/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Higher-Order Components](#higher-order-components) | working |
| 2 | [Render Props and Compound Components](#render-props-and-compound-components) | working |

---

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

**Misconception 1: HOCs are deprecated in modern React.**

HOCs are not deprecated - they are less commonly needed because React hooks achieve the same logic-reuse goal with less ceremony. HOCs are still the right tool for: wrapping third-party class components that cannot use hooks, code-mod patterns that must wrap an entire component export, and cross-cutting concerns applied at route or module level (authentication guards via HOC at the router level). React Router's `withRouter` and Redux's `connect()` are HOCs that remain relevant.

**Misconception 2: HOC props automatically pass through to the wrapped component.**

HOC props do NOT automatically pass through. The HOC must explicitly forward props: `return <WrappedComponent {...props} extraProp={...} />`. Additionally, refs do not pass through by default - a ref attached to the HOC-returned component points to the HOC's wrapper, not the inner component. Use `React.forwardRef()` in the HOC to forward refs correctly.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: HOC display name disappears in React DevTools making debugging difficult.**

Symptom: React DevTools shows components as `Component` or `HOC(Component)` without meaningful names; hard to identify which component has a problem. Root cause: HOC does not set `displayName` on the returned wrapper component. Fix: set display name explicitly: `WrappedComponent.displayName = \`withAuth(${getDisplayName(WrappedComponent)})\``; React DevTools will then show `withAuth(UserProfile)` in the component tree.

**Failure Mode 2: HOC wrapping mutates the original component.**

Symptom: original component behaves differently when used without the HOC; adding or removing a HOC has unexpected side effects. Root cause: HOC modifies `WrappedComponent.prototype` or `WrappedComponent.propTypes` directly instead of creating a new wrapper component. Fix: never mutate the input component - always create and return a new component that wraps and delegates to the original.

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

**Misconception 1: Render props are obsolete and should always be replaced with hooks.**

Hooks replaced render props for simple logic sharing, but render props remain uniquely appropriate when the parent component needs to control rendering of its consumer's output. A `DataTable` that exposes render props for cell content (`renderCell={(row, col) => <strong>{row[col]}</strong>}`) is more flexible than a hook because the parent controls when and how to render - it can batch cells, add wrappers, apply animations. Render props give consumers control of the rendered output; hooks give consumers control of the logic.

**Misconception 2: Compound Components pattern is only for complex UI libraries.**

Compound Components (a `<Select>` that contains `<Option>` children) is applicable to any feature with multiple coordinated sub-components. A `<Form>` with `<Form.Field>`, `<Form.Error>`, and `<Form.Submit>` sub-components that share form state via Context is a compound component pattern. It is appropriate whenever you have a set of tightly related UI elements where the parent needs to share state with children without prop drilling.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Render prop causes unnecessary re-renders of children on every parent render.**

Symptom: child component rendered via render prop re-renders on every parent re-render even when data hasn't changed; performance profile shows wasted renders. Root cause: render prop function is defined inline in JSX (`renderItem={() => <Item />}`), creating a new function reference on every parent render; if the render prop is used in a PureComponent or memo child, it defeats memoization. Fix: define render prop functions outside the render method or memoize with useCallback.

**Failure Mode 2: Compound Component children used outside the parent provider context.**

Symptom: `<Tabs.Panel>` used without a parent `<Tabs>` wrapper throws a null reference error; consuming the sub-component directly without the parent fails. Root cause: compound component sub-components rely on Context provided by the parent; without the parent, context is undefined. Fix: add a guard in sub-components: `const context = useContext(TabsContext); if (!context) throw new Error('<Tabs.Panel> must be used within <Tabs>');`

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



