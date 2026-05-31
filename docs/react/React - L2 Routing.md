---
layout: default
title: "React - L2 Routing"
parent: "React"
nav_order: 7
permalink: /react/l2-routing/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [React Router and Client-side Routing](#react-router-and-client-side-routing) | working |
| 2 | [Dynamic Routing and Code Splitting](#dynamic-routing-and-code-splitting) | working |
| 3 | [Higher-Order Components](#higher-order-components) | working |
| 4 | [Render Props and Compound Components](#render-props-and-compound-components) | working |

---

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Why it matters:**

Every non-trivial React app needs routing. React Router v6 is nearly
universally used. The migration from v5 to v6 is a common interview
discussion point. Understanding the Outlet/nested routes pattern is
required for implementing layouts efficiently.

---

### 💻 Code Example

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

> **Code walkthrough:** The most common React Router bug after upgrading
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

**Misconception 1: Client-side routing means the server is not involved in navigation.**

The server is involved for the initial page load AND for deep links. When a user navigates directly to `/dashboard/settings`, the server must serve the React app entry point (index.html) for ALL routes - not a 404 for routes it doesn't know about. This requires server configuration: Nginx `try_files $uri /index.html;`, Apache `FallbackResource /index.html`, or the hosting platform's SPA redirect configuration. Without this, direct URL access to any non-root route returns 404.

**Misconception 2: useNavigate and Link are interchangeable.**

`Link` renders an `<a>` element and is appropriate for navigation triggered by user interaction (menu items, breadcrumbs, call-to-action buttons). `useNavigate` returns a navigate function appropriate for programmatic navigation: after form submission, after async operation completion, after authentication state change. Using `useNavigate` where `Link` is appropriate loses accessibility benefits (keyboard navigation, screen reader announcements, right-click open-in-new-tab) that native `<a>` elements provide.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Route params not updating component when URL changes for same component.**

Symptom: navigating from `/user/1` to `/user/2` shows stale data from user 1; component does not re-fetch for the new user ID. Root cause: component mounted once and uses the initial route params; if useEffect has `params.userId` in dependencies but the component is not remounted, re-runs are expected - but a missing dependency or wrong equality check prevents re-fetching. Diagnosis: add `console.log` in useEffect to verify it re-runs on params change. Fix: ensure `params.userId` is in the useEffect dependency array; or add a `key={params.userId}` prop to force remount when user ID changes.

**Failure Mode 2: Nested routes not rendering because Outlet is missing.**

Symptom: navigating to a child route shows the parent layout but the child route content is blank. Root cause: parent route component does not include `<Outlet />` - the placeholder where React Router renders matched child routes. Fix: add `<Outlet />` in the parent route component at the location where child routes should appear.

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

**Q1: How do you implement a redirect-after-login flow with React Router?**
`[SENIOR]` DECISION

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Why it matters:**

Bundle size directly impacts Time to Interactive (TTI). A 1MB bundle on
3G mobile takes ~10 seconds to parse and execute. Route-level code
splitting is the highest-ROI performance optimization for SPAs.

---

### 💻 Code Example

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

**Misconception 1: Code splitting should be applied to every component for maximum performance.**

Code splitting has overhead: each split creates an async chunk that requires a network request on first access. Splitting tiny utility components adds network round-trips that cost more than the bandwidth saved. Code split at meaningful boundaries: route-level (each page loads its own bundle), feature-level (admin features only load for admin users), and heavy library-level (chart library only loaded on the analytics page). Splitting at the component level for small components is premature optimization.

**Misconception 2: React.lazy loads the component before the route is navigated to.**

React.lazy is LAZY - it loads the component bundle WHEN the component needs to render, not proactively. This means the first navigation to a lazy route shows a loading state while the bundle downloads. For critical routes that should feel instant, use prefetching: use the browser's `<link rel="prefetch">` or the dynamic `import()` function triggered on hover/focus to load the bundle before the user navigates.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Missing Suspense boundary causes React to throw on lazy component load.**

Symptom: blank screen or unhandled error on first navigation to a lazy-loaded route. Root cause: `React.lazy()` must be wrapped in a `<Suspense fallback={...}>` component; without it, React throws when the component is in the loading state. Fix: wrap all lazily loaded components in a Suspense boundary: `<Suspense fallback={<Spinner />}><LazyComponent /></Suspense>`.

**Failure Mode 2: Dynamic import paths prevent build-time chunk optimization.**

Symptom: Webpack/Vite cannot create named chunks; all dynamic imports result in generic numbered chunk files; code splitting configuration is ignored. Root cause: dynamic import with a fully dynamic expression `import(variable)` - bundlers cannot statically analyze which modules to include. Fix: use partial dynamic paths with a static prefix: `import(\`./features/\${featureName}/index\`)` - Webpack includes all possible matches in a chunk; or use fully static paths for each split boundary.

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

**Q1: How do you investigate and fix bundle size issues in a React app?**
`[SENIOR]` DEBUGGING

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Why it matters:**

HOCs are part of React's component model history. Understanding them is
required for working with existing codebases (React Router v5 used HOCs:
`withRouter`). Knowing the pitfalls (wrapper hell, prop collisions) and
the modern hook-based alternatives shows pattern evolution awareness.

---

### 💻 Code Example

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

> **Code walkthrough:** The "wrapper hell" example shows why HOCs fell
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

**Q1: How do you migrate a withAuth HOC to the hooks pattern?** `[SENIOR]`
DECISION

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

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

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

> **Code walkthrough:** The Tabs compound component shares `active` state
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

**Q1: Design a Dropdown component using compound components pattern.**
`[SENIOR]` LIVE CODING

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



