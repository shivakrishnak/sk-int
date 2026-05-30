---
layout: default
title: "React - META Patterns"
parent: "React"
nav_order: 16
permalink: /react/meta-patterns/
render_with_liquid: false
---

# Component Composition Mental Model

🎯 **Interview Weight:** meta (★☆☆) - transferable thinking pattern;
explains how to decompose any UI problem into React components

---

### 🎯 Model Answer

**30 seconds:**

> React's composition model: build complex UIs from simple, focused
> components. Key decisions: (1) What state does each component own?
> (2) Who needs to read/write this state (determines placement)?
> (3) How does data flow down, events up? Each component is a pure
> function from props + state to UI. Composition = combining these.
> When to split: single responsibility - if it does two unrelated things,
> split it.

**3 minutes:**

> Component decomposition follows three principles: (1) Single
> responsibility - one component, one concern. (2) Inversion of control
> via composition - instead of props for every variant, accept `children`
> and let the parent decide content. (3) Data locality - keep state as
> close to where it's used as possible; only lift when truly shared.
> Common mistake: lifting state to the root "just in case" causes
> unnecessary re-renders and tight coupling. The composition pattern
> (passing components as children or props) is more flexible than
> configuration props for UI variations.

**Blank Mind Recovery:**

**(1) Restate:** "Composition: small focused components + state near its users.
Split when doing two things. Data down (props), events up (callbacks).
Prefer composition over configuration props. Lift state only when truly shared."

---

### 📘 Concept Explanation

**What it is:**

Component composition is the fundamental pattern for structuring React
applications. Instead of building one large component, compose many
smaller, focused components into complex UIs.

**How it works:**

```jsx
// SINGLE RESPONSIBILITY: one job per component

// BAD: one component doing everything
function UserDashboard({ userId }) {
  const [user, setUser] = useState(null);
  const [posts, setPosts] = useState([]);
  const [editing, setEditing] = useState(false);
  // 200+ lines: hard to test, hard to reuse
}

// GOOD: each component has one job
function UserDashboard({ userId }) {
  return (
    <DashboardLayout>
      <UserProfile userId={userId} />
      <UserPosts userId={userId} />
      <UserActions userId={userId} />
    </DashboardLayout>
  );
}

// COMPOSITION OVER CONFIGURATION:
// BAD: giant prop list for every variant
function BadButton({
  variant, size, color, icon, iconPosition,
  loading, disabled, fullWidth, ...props
}) { /* combinatorial explosion */ }

// GOOD: compose from primitives
function Button({ children, ...props }) {
  return <button className="btn" {...props}>{children}</button>;
}

function LoadingButton({ loading, children, ...props }) {
  return (
    <Button disabled={loading} {...props}>
      {loading ? <Spinner /> : children}
    </Button>
  );
}
```

**Why it matters:**

The composition mental model applies to every React design decision.
When encountering an unfamiliar UI requirement, thinking in terms of
"what small components can I compose to build this" is the universal
problem-solving approach.

---

### 💻 Code Example

```jsx
// WHEN TO SPLIT A COMPONENT:
// Rule: if you need two different tests, it's two components

// BAD: one component, two concerns
function ProductCard({ product, currentUser }) {
  // Concern 1: display - expand/collapse description
  const [expanded, setExpanded] = useState(false);
  // Concern 2: user interaction - like/unlike
  const [liked, setLiked] = useState(
    currentUser.likedProducts.includes(product.id)
  );
  // These are independent - test them separately
}

// GOOD: separate components for separate concerns
function ProductDescription({ product }) {
  const [expanded, setExpanded] = useState(false);
  return (
    <div>
      <p>{expanded ? product.fullDesc : product.shortDesc}</p>
      <button onClick={() => setExpanded(e => !e)}>
        {expanded ? 'Less' : 'More'}
      </button>
    </div>
  );
}

function LikeButton({ productId, initialLiked, likeCount }) {
  const [liked, setLiked] = useState(initialLiked);
  return (
    <button onClick={() => setLiked(l => !l)}>
      {liked ? '❤️' : '♡'} {likeCount + (liked ? 1 : 0)}
    </button>
  );
}
```

> **Code walkthrough:** The GOOD version tests `ProductDescription` in
> isolation (expand/collapse, no user data) and `LikeButton` in isolation
> (like state, no product data). The BAD version requires both concerns
> in every test. This is the single responsibility principle applied to
> React: a component that can be tested independently for one behavior.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Component composition means building complex UIs from small, focused
> components. Each component should do one thing. Use children or
> composition instead of many configuration props for flexibility. Keep
> state in the component that uses it, only lift when siblings need it.

**Senior / Staff:**

> The composition mental model is the framework for every component design
> decision. Single responsibility test: can I write a focused unit test
> for this component in isolation? If the answer requires setting up two
> different contexts, it's two components. Inversion of control via
> `children` is the most underused pattern: instead of a `renderHeader`
> prop or an `icon` prop, accept `children` and let the parent compose
> whatever content it needs. This makes the component maximally flexible
> without anticipating every use case.

---

### ⚖️ Comparison Table

| Design | Flexibility | Reusability | Complexity |
|---|---|---|---|
| Monolithic | Low | Low | High |
| Props for every variant | Medium | Medium | Medium |
| Composition with children | High | High | Low |
| Compound components | Very high | Very high | Medium |

---

### ⚠️ Common Misconceptions

**Misconception 1: Component composition is just about code reuse.**

Component composition is a reasoning model for UI construction. It enables: independent reasoning about each component (what are its inputs? what does it render?), independent testing without rendering the entire application, progressive enhancement (add features by composing, not modifying), and team independence (different teams own different component boundaries). Code reuse is a benefit; compositional reasoning is the primary value.

**Misconception 2: The correct component hierarchy always mirrors the visual layout.**

Component boundaries should follow DATA OWNERSHIP and UPDATE FREQUENCY, not visual nesting. A `UserAvatar` that lives visually inside a `NavigationBar` that lives inside a `PageHeader` might be best implemented as a standalone component that reads directly from an auth context - its component boundary does not need to mirror the visual nesting if doing so creates prop drilling without benefit.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Component boundary placed at the wrong granularity causes a rewrite.**

Symptom: adding a new feature requires changing 5+ component interfaces; a seemingly simple change propagates through the entire component tree. Root cause: component boundaries drawn around visual elements rather than domain concepts; components are too thin and delegate too much via props. Diagnosis: count how many component files change for a single feature addition; more than 3-4 indicates wrong boundary placement. Fix: refactor to align component boundaries with domain concepts; a `<UserProfile>` component encapsulates its sub-parts internally rather than exposing every sub-element as a separate prop.

**Failure Mode 2: God component anti-pattern from insufficient composition.**

Symptom: single component file exceeds 500 lines; contains multiple unrelated responsibilities; hard to test in isolation. Root cause: features added to existing components rather than composed alongside them; composition principle not applied. Fix: apply the Single Responsibility Principle at component level - each component does one thing well; extract sub-features as composed child components or custom hooks.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| When to split a component | 2-3 min | Single responsibility |
| Composition vs configuration | 3-4 min | children vs props |
| State placement rule | 2-3 min | Lowest common ancestor |
| Component decomposition exercise | 5-7 min | Live breakdown of UI |
| Inversion of control | 3-4 min | Parent controls content |
| Reusability trade-offs | 2-3 min | Coupling vs flexibility |
| Testing as a split signal | 2-3 min | One test per component |

---

**Q1: Walk me through how you'd decompose a complex checkout form.**
`[MID]` LIVE DESIGN

> **Answer:**
>
> Three steps: identify responsibilities, determine state placement,
> draw component boundaries.
>
> ```
> CheckoutForm (owns form submit, top-level validation)
> ├── ShippingSection (shipping field state + validation)
> ├── BillingSection (billing fields + SameAsShipping checkbox)
> │   └── reason: SameAsShipping reads ShippingSection values
> └── PaymentSection (payment details)
>     └── CardInput (Stripe-specific, isolated completely)
> ```
>
> Key decisions: React Hook Form centralizes data collection while
> keeping validation rules co-located with fields. CardInput is isolated
> because it owns Stripe integration - no other component needs to know
> about Stripe internals.
>
> *What separates good from great:* Explaining WHY each boundary is drawn,
> not just WHAT the structure is. The SameAsShipping checkbox explains why
> it lives in BillingSection: it needs to read shipping values without
> prop drilling through CheckoutForm.

---

---

# State Colocation Principle

🎯 **Interview Weight:** meta (★☆☆) - the most impactful architecture habit;
widely cited but poorly practiced in large codebases

---

### 🎯 Model Answer

**30 seconds:**

> State colocation: keep state as close to where it's used as possible.
> Only lift when multiple components share data. The anti-pattern:
> lifting all state to root "just in case" creates unnecessary re-renders
> and tight coupling. Test: can I remove this state from the parent
> without breaking anything? If yes, it's over-lifted.

**3 minutes:**

> Most React performance and coupling problems trace to over-lifted state.
> Root state re-renders all consumers on every change. Local state only
> re-renders that component. The colocation rule: a state update should
> only cause re-renders in components that care about it. Three levels:
> (1) local - single component, (2) lifted - siblings share via LCA,
> (3) global - app-wide via Zustand/Context. Never jump to global for
> local concerns. The signal for over-lifting: prop drilling through 3+
> intermediate components that don't use the prop.

**Blank Mind Recovery:**

**(1) Restate:** "Colocation: state near its users. Lift only when shared.
Anti-pattern: root state for local concerns. Signal: prop drilling 3+ levels.
Three levels: local (1 component), lifted (siblings), global (auth/theme/flags)."

---

### 📘 Concept Explanation

**What it is:**

State colocation is the principle that state should live in the component
closest to where it's used. This maximizes encapsulation, minimizes
re-renders, and reduces coupling.

**How it works:**

```jsx
// OVER-LIFTED STATE (common in growing codebases)
// BAD: All UI state lifted to App
function App() {
  const [user, setUser] = useState(null);
  const [cartOpen, setCartOpen] = useState(false);  // only Cart uses
  const [filterText, setFilterText] = useState(''); // only ProductList uses
  const [modalOpen, setModalOpen] = useState(false);// only Modal uses
  // Every state change re-renders App and ALL children

  return (
    <Layout>
      <Header user={user} cartOpen={cartOpen}
              onCartToggle={() => setCartOpen(o => !o)} />
      <ProductList filterText={filterText}
                   onFilterChange={setFilterText} />
    </Layout>
  );
}

// COLOCATED STATE (improved)
function App() {
  const { user } = useAuth(); // only auth is truly global
  return (
    <Layout>
      <Header user={user} /> {/* Cart state lives IN Header */}
      <ProductList />         {/* Filter state lives IN ProductList */}
    </Layout>
  );
}

// THREE LEVELS:

// 1. LOCAL: single component
function Toggle() {
  const [on, setOn] = useState(false);
  return <button onClick={() => setOn(o => !o)}>{on ? 'On' : 'Off'}</button>;
}

// 2. LIFTED: shared by siblings (lowest common ancestor)
function SearchPage() {
  const [query, setQuery] = useState('');
  return (
    <>
      <SearchInput value={query} onChange={setQuery} />
      <SearchResults query={query} />
    </>
  );
}

// 3. GLOBAL: app-wide (auth, theme, feature flags only)
const useAuthStore = create(set => ({ user: null, login: (u) => set({user: u}) }));
```

**Why it matters:**

Over-lifted state is the primary cause of React performance problems at
scale and the primary cause of unnecessary coupling between components.

---

### 💻 Code Example

```jsx
// DIAGNOSTIC: Is this state over-lifted?

// SIGNAL: prop drilling 3+ levels
// If a prop passes through 3 intermediate components that don't use it:
<App>
  <Page filterText={filterText}>          {/* doesn't use */}
    <Section filterText={filterText}>     {/* doesn't use */}
      <ProductGrid filterText={filterText} /> {/* only user */}
    </Section>
  </Page>
</App>
// filterText should live in Section or ProductGrid

// FIX 1: colocate to Section
function Section() {
  const [filterText, setFilterText] = useState('');
  return (
    <div>
      <input value={filterText}
        onChange={e => setFilterText(e.target.value)} />
      <ProductGrid filterText={filterText} />
    </div>
  );
}

// FIX 2: Context if multiple components in subtree need it
const FilterCtx = createContext('');
function Section() {
  const [filterText, setFilterText] = useState('');
  return (
    <FilterCtx.Provider value={{ filterText, setFilterText }}>
      <FilterInput />   {/* reads + writes */}
      <ProductGrid />   {/* reads */}
      <ProductCount />  {/* reads */}
    </FilterCtx.Provider>
  );
}
```

> **Code walkthrough:** The 3-level prop drilling is the practical signal
> that state is over-lifted. Intermediate components are coupled to state
> they don't care about - every type change requires updating all
> intermediaries. Colocation removes this coupling. The Context fix is
> appropriate when multiple components within a subtree need the value -
> removes drilling without lifting to global.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> State colocation means keeping state in the component that uses it.
> If only one component needs it, put it there. If siblings need it,
> lift to their common parent. Only use global state for data truly needed
> across unrelated parts of the app like auth. Test: can this state live
> one level lower without breaking anything?

**Senior / Staff:**

> State colocation is the single most impactful architecture habit in React.
> The default in poorly-scaled codebases: lift state early to "avoid
> refactoring later." This creates a self-fulfilling prophecy - global
> state becomes a dependency magnet, everything re-renders on any change.
> My rule: start with state in the component that uses it. Lift when a
> second component needs it. Consider Context/Zustand at 3+ levels deep
> only. This ensures state lives at the right level at each growth stage.
> The benefit: performance (changes re-render only the relevant subtree)
> and maintainability (change impact is localized).

---

### ⚖️ Comparison Table

| State level | Scope | Re-render impact | When to use |
|---|---|---|---|
| Component | One component | That component only | Default |
| Lifted | Component subtree | Subtree | Sibling communication |
| Context | Context subtree | All consumers | 3+ pass-through levels |
| Global store | Entire app | Selective subscribers | Auth, theme, config |

---

### ⚠️ Common Misconceptions

**Misconception 1: State should be lifted as high as possible for maximum flexibility.**

Lifting state too high creates unnecessary coupling and performance problems: every state change re-renders the entire subtree below the state owner, even if only one deeply nested component needs the update. The principle of Least Power applies to state placement: keep state as low in the component tree as possible while still satisfying the sharing requirement. Lift state ONLY as far as the nearest common ancestor of all components that need it.

**Misconception 2: Server state and client state should be managed together.**

Server state (data from APIs) has different characteristics than client state (UI toggle, form values): server state requires caching, deduplication, background refresh, optimistic updates, and synchronization with the server. Managing server state in the same store as client state (Redux for everything) means implementing these features yourself. React Query, SWR, and RTK Query are purpose-built for server state; combine them with a lightweight client state solution rather than forcing all state into one model.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: State lifted too high causes performance regression.**

Symptom: a text input field causes the entire page to re-render on every keystroke; typing feels sluggish on complex pages. Root cause: form state stored in a high-level component that renders the entire page; each keystroke triggers a full page re-render. Diagnosis: React DevTools Profiler - check how many components render on each keystroke. Fix: colocate form state in the form component itself; do not lift it to the page level unless other components on the page need the form values.

**Failure Mode 2: Overly colocated state causes duplication and inconsistency.**

Symptom: two components on the same page show different values for the same piece of data; updating one does not update the other. Root cause: state colocated in two different subtrees that both need to display the same value - violates the single-source-of-truth principle. Fix: identify the lowest common ancestor of all components needing the state; lift state to that level; pass as props to consumers.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| Explain state colocation | 2-3 min | Closest to users |
| Over-lifting anti-pattern | 2-3 min | Root state for local concerns |
| When to lift vs keep local | 2-3 min | Sharing signal |
| Prop drilling signal | 2-3 min | 3 levels = lift or Context |
| Performance implications | 2-3 min | Render scope |
| Global state criteria | 2-3 min | Auth/theme only |
| Auditing over-lifted state | 3-4 min | Profiler + prop trace |

---

**Q1: How do you audit a React codebase for over-lifted state?** `[SENIOR]`
DEBUGGING

> **Answer:**
>
> Systematic audit:
>
> 1. **List all state** in components above leaf level. For each:
>    "How many direct children actually use this prop?"
>
> 2. **Trace prop chains**: any prop passing through 2+ components
>    without being used is a colocation signal.
>
> 3. **Check global stores**: anything in Redux/Zustand not shared by
>    3+ unrelated components is probably over-lifted.
>
> 4. **Profile**: React DevTools Profiler - components re-rendering on
>    unrelated state changes are consuming over-lifted state.
>
> Fix priority: colocate first (easy), then Context for subtrees,
> global stores last.
>
> *What separates good from great:* Using the Profiler to observe
> what's re-rendering rather than guessing from code. A component that
> re-renders when a button in a completely different area is clicked is
> the observable signal that state is lifted too high.

---

---

# React Decision Framework

🎯 **Interview Weight:** meta (★☆☆) - the "when to use what" map; shows
pattern maturity and principled architecture choices

---

### 🎯 Model Answer

**30 seconds:**

> React decisions reduce to: (1) State type - server state? TanStack Query.
> Local UI? useState. Shared app? Zustand. (2) Component split - multiple
> responsibilities? Split. (3) Rendering - public data? SSG. Dynamic per
> user? SSR/RSC. Pure client? CSR. (4) Performance - profile first,
> then code-split, memo, virtualize as needed. The answer is rarely
> the most complex option.

**3 minutes:**

> Start simple, add complexity only when needed. State escalation:
> useState (1 component) → lifted (siblings) → Context (subtree) →
> Zustand (app-wide). Data fetching: useEffect (learning) → TanStack
> Query (production) → RSC (Next.js, initial loads). Performance:
> nothing → code splitting → React.memo + useCallback → virtualization.
> Each step adds complexity. Only move to the next when the current
> step genuinely causes problems. Never jump to global state for local
> concerns. Never profile manually what you haven't measured.

**Blank Mind Recovery:**

**(1) Restate:** "Decision framework: start simple, escalate when needed.
State: useState→lift→Context→Zustand. Data: useEffect→TanStack Query→RSC.
Performance: nothing→split→memo→virtualize. Rendering: CSR→SSR→SSG→RSC.
Never complex if simple works."

---

### 📘 Concept Explanation

**What it is:**

The React decision framework is a set of escalating choices - start with
the simplest tool that solves the problem, escalate only when it's
genuinely insufficient.

**How it works:**

```
// STATE MANAGEMENT DECISION TREE

Where does this data come from?
├── Server (DB, API) → TanStack Query
│   Provides: caching, loading/error, background sync
├── URL (filters, pagination) → useSearchParams
│   Provides: shareable, back-button, bookmarkable
├── Form input → React Hook Form
│   Provides: validation, submission, minimal re-renders
└── UI-only (modal, toggle) → local useState
    └── Siblings need it?
        ├── Yes → lift to lowest common ancestor
        │   └── 3+ pass-through levels?
        │       ├── Yes → Context (domain-scoped)
        │       └── High update frequency? → Zustand
        └── No → keep local

// RENDERING STRATEGY DECISION TREE

What type of content?
├── Public, rarely changes (blog, docs) → SSG + CDN
├── Public, frequently changes (news) → SSR or ISR
├── Private per user → RSC (Next.js App Router)
│   └── Highly interactive → CSR + TanStack Query
└── Mixed public/private → RSC shell + Client components

// PERFORMANCE DECISION TREE

Do users actually perceive slowness?
├── No → Nothing. Measure first.
├── Initial load slow → Code splitting (React.lazy)
│   └── Bundle audit: visualizer tool
├── Typing lag in large form → React Hook Form
├── Long list (>100 items) → react-window
└── Specific re-renders too often → React.memo
    └── Requires: profile confirms + stable props
```

**Why it matters:**

The framework prevents both under-engineering (useEffect where TanStack
Query is needed) and over-engineering (Redux for state that should be
local). It's the meta-skill that accelerates all React architectural
decisions.

---

### 💻 Code Example

```jsx
// APPLYING THE FRAMEWORK: product reviews page

// Data type → server data → TanStack Query
const { data: reviews } = useQuery({
  queryKey: ['reviews', productId],
  queryFn: () => fetchReviews(productId),
});

// Filter state → URL state (shareable link behavior)
const [searchParams, setSearchParams] = useSearchParams();
const rating = searchParams.get('rating') || 'all';

// Modal state → local UI state only
const [selectedReview, setSelectedReview] = useState(null);

// Form → React Hook Form
const { register, handleSubmit } = useForm();

// RESULT: no global state, each concern at right level
function ReviewsPage({ productId }) {
  return (
    <div>
      <ReviewFilters />          {/* reads/writes searchParams */}
      <ReviewList
        reviews={reviews}
        onSelect={setSelectedReview}
      />
      {selectedReview && (
        <ReviewModal
          review={selectedReview}
          onClose={() => setSelectedReview(null)}
        />
      )}
      <AddReviewForm productId={productId} />
    </div>
  );
}
// Zero prop drilling. Zero global state. Every tool at right level.
```

> **Code walkthrough:** The example applies the framework mechanically:
> server data to TanStack Query, filter state to URL params (filters in
> URL = shareable link, back-button navigates filter history), modal state
> is local (only ReviewsPage cares, nowhere else), form state to React
> Hook Form. No Redux, no Context, no Zustand. Each piece of state is at
> its natural level. The component is easy to test: mock the query, set
> URL params in test, check rendered output.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> For React decisions, I follow a simple escalation: useState for local
> state, lift when siblings need it, Context for subtrees, global stores
> for app-wide needs. TanStack Query for server data instead of manual
> useEffect. For performance: profile first, then code splitting and
> React.memo where profiling shows it's needed.

**Senior / Staff:**

> The React decision framework is about understanding which problem each
> tool solves, then matching tool to problem. TanStack Query solves server
> state specifically: staleness, deduplication, background sync - not
> solvable by React state. URL state solves shareability: filters in
> useState are lost on page refresh; filters in URL survive. The framework
> prevents reaching for complexity before the simple solution is proven
> insufficient. My rule: I can always add complexity later; removing it
> from a production codebase is much harder. Every over-engineered React
> codebase started with premature global state.

---

### ⚖️ Comparison Table

| Problem | Simple | Complex (when needed) |
|---|---|---|
| Component UI state | useState | useReducer (many related) |
| Sibling state | Lift to parent | Context (many siblings) |
| App state | Context | Zustand (high update rate) |
| Server data | useEffect+fetch | TanStack Query (caching) |
| Performance | Nothing | memo + splitting (measured) |
| Long lists | Simple map | react-window (>100, slow) |

---

### ⚠️ Common Misconceptions

**Misconception 1: The best React architecture is the one used by large tech companies.**

Facebook's React architecture (Relay, GraphQL, React Server Components) is optimized for Facebook's scale: thousands of engineers, hundreds of product teams, billions of users. Most applications need simpler solutions: a well-structured SPA with React Query and Zustand may be the best architecture for a 5-person team building a B2B tool. Architecture decisions should match team size, deployment frequency, and product complexity - not the most impressive technology.

**Misconception 2: The correct technology choice is always the newest one.**

New React features (Server Components, Concurrent Mode, Actions) are additions to an already-functional library, not replacements for proven patterns. A codebase with well-structured class components or pre-hooks React is not necessarily in need of upgrading - if the code works, is well-tested, and the team understands it, the upgrade cost may exceed the benefit. Evaluate new features against specific problems you have; do not chase the latest release for its own sake.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Technology chosen based on hype rather than requirements causes costly rewrites.**

Symptom: team migrates to the latest React meta-framework or state management library; 6 months later discovers it does not solve the actual problem; begins another migration. Root cause: adoption based on conference talks or community buzz rather than a documented problem statement. Fix: before adopting any new library or pattern, write down the specific problem it solves and measure the current pain; evaluate alternatives; decide based on evidence.

**Failure Mode 2: No architecture decision records (ADRs) cause inconsistent implementation across the codebase.**

Symptom: different parts of the codebase use different state management approaches, data fetching patterns, or component structure conventions; code reviews are contentious because there is no agreed standard. Root cause: architectural decisions made verbally or in Slack without documentation; new team members apply different defaults. Fix: write ADRs for significant architectural choices (state management approach, data fetching strategy, component structure); store them in the repo and reference them in onboarding documentation.

---

### 🎯 Interview Deep-Dive

| Scenario | Time | Key Signal |
|---|---------|-----------|
| State management choice | 3-4 min | Escalation principle |
| useState vs useReducer | 2-3 min | Multiple related fields |
| When TanStack Query | 2-3 min | Server state properties |
| URL state use case | 2-3 min | Shareable/bookmarkable |
| Performance decision | 2-3 min | Profile before optimizing |
| CSR vs SSR vs SSG | 3-4 min | Data change frequency |
| "Should we use Redux?" | 3-4 min | Criteria checklist |

---

**Q1: A new project is starting. How do you pick the React stack?**
`[SENIOR]` DECISION

> **Answer:**
>
> Derive from requirements, not from previous project templates:
>
> **Framework choice:**
> - SPA, no SEO → Vite + React
> - Public pages + private app → Next.js App Router
> - Pure static site (docs, marketing) → Next.js with SSG
>
> **State:**
> - Simple CRUD → TanStack Query + useState only
> - Complex auth + shared UI state → add Zustand (minimal)
> - Forms everywhere → React Hook Form + Zod validation
>
> **Team size signals:**
> - 1-3 devs → co-locate everything, minimal tooling
> - 5+ devs → monorepo, shared component library, strict linting
>
> **Typical React SPA stack:**
> ```
> Vite + React + TypeScript
> TanStack Router + TanStack Query
> Zustand (auth only)
> React Hook Form + Zod
> Vitest + React Testing Library
> Tailwind CSS or CSS Modules
> ```
>
> **Typical Next.js full-stack:**
> ```
> Next.js App Router (RSC + Server Actions)
> TanStack Query (client mutations)
> Zustand (minimal client state)
> React Hook Form + Zod
> Vitest/Jest + RTL
> Tailwind CSS
> ```
>
> *What separates good from great:* Starting from REQUIREMENTS (app type,
> team size, rendering needs) rather than TOOLS. Technology choices should
> be derived from constraints, not cargo-culted from previous projects.
> A team of 2 building a dashboard does not need the same stack as a
> team of 20 building a marketing + app hybrid.
