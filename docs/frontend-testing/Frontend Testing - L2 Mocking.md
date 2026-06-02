---
layout: default
title: "Frontend Testing - L2 Mocking"
parent: "Frontend Testing"
nav_order: 4
permalink: /frontend-testing/l2-mocking/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Mocking with Jest (jest.mock, spies, stubs)](#mocking-with-jest-jestmock-spies-stubs) | medium |
| 2 | [Mocking HTTP Requests with MSW](#mocking-http-requests-with-msw) | medium |

---

# Mocking with Jest (jest.mock, spies, stubs)

---

### 🎯 Model Answer

**30 seconds:**

> Jest mocking replaces real dependencies with controlled doubles.
> `jest.mock('module')` auto-mocks all exports. `jest.fn()` creates a
> spy function that tracks calls. `jest.spyOn(obj, 'method')` wraps an
> existing method as a spy without replacing it (or with
> `.mockImplementation()`). `jest.mock` is hoisted to the top of the
> file automatically. Clear mocks between tests with `clearMocks: true`
> in config or `jest.clearAllMocks()` in afterEach.

**3 minutes:**

Mocking has three goals: isolation (test the unit without its
dependencies), control (make dependencies return predictable values),
and verification (assert the unit interacts with dependencies
correctly).

**Three types of mock doubles:**
- **Stub**: returns a fixed value, tracks calls (jest.fn())
- **Spy**: wraps a real function, records calls but calls through to
  real implementation (jest.spyOn)
- **Mock**: fully replaces a module (jest.mock)

**`jest.mock()` hoisting**: Jest transforms `jest.mock('module')` calls
to the top of the file at compile time. This means `jest.mock` runs
before imports - you don't need to mock before importing.

**`__mocks__` directory**: Manual mocks in `__mocks__/module-name.js`
alongside the real module. Jest uses them automatically (or when
`jest.mock()` is called without a factory function for node_modules).

**Blank Mind Recovery:**

**(1) Three tools:** "jest.fn() = stub function. jest.spyOn() = wrap
existing. jest.mock('module') = replace entire module."

**(2) Reset mocks:** "clearMocks = true in config, or jest.clearAllMocks()
in afterEach. Without reset, call counts accumulate across tests."

**(3) Hoisting:** "jest.mock() is always moved to top of file before
imports. Order in code doesn't matter."

---

### 📘 Concept Explanation

**What it is:**

Jest's built-in capability to replace functions, classes, and modules
with test doubles that control behavior and record interactions.

**The problem it solves:**

Unit tests should test one unit of behavior. If `UserService.create()`
calls `Database.save()`, a test for `UserService` should not depend on
a real database. Mocking replaces `Database.save()` with a function
that returns a predetermined value.

**How it works:**

```
Mock function API:

  const mockFn = jest.fn();           // creates mock function
  const mockFn = jest.fn(() => 42);   // with default implementation

  mockFn.mockReturnValue(value)       // returns value every call
  mockFn.mockReturnValueOnce(value)   // returns value once, then default
  mockFn.mockResolvedValue(value)     // returns Promise.resolve(value)
  mockFn.mockRejectedValue(error)     // returns Promise.reject(error)
  mockFn.mockImplementation(fn)       // custom function
  mockFn.mockImplementationOnce(fn)   // custom function for one call

  Assertions:
  expect(mockFn).toHaveBeenCalled()
  expect(mockFn).toHaveBeenCalledTimes(n)
  expect(mockFn).toHaveBeenCalledWith(...args)
  expect(mockFn).toHaveReturnedWith(value)

Module mocking:

  jest.mock('./utils') // auto-mock all exports as jest.fn()
  jest.mock('./utils', () => ({
    formatDate: jest.fn(() => '2024-01-01'),
    parseDate: jest.fn(s => new Date(s)),
  }));

  // In test:
  import { formatDate } from './utils';
  jest.mocked(formatDate).mockReturnValue('2024-06-15');

Spy on existing method:

  const spy = jest.spyOn(console, 'error');
  spy.mockImplementation(() => {}); // suppress output
  // ...test...
  expect(spy).toHaveBeenCalledWith('Expected error');
  spy.mockRestore(); // restore original implementation
```

> **Code walkthrough:** This Mocking with Jest (jest.mock, spies, stubs) example demonstrates a key concept in practice using Promise. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Wrong vs Right) - Mock cleanup:**


```typescript
// BAD: using any defeats type safety
```

```typescript
// BAD: mock state accumulates across tests
const mockFetchUser = jest.fn();
jest.mock('./api', () => ({ fetchUser: mockFetchUser }));

test('shows loading state', async () => {
  mockFetchUser.mockResolvedValue({ name: 'Alice' });
  // ...
});

test('shows error state', async () => {
  mockFetchUser.mockRejectedValue(new Error('Network error'));
  // mockFetchUser.mock.calls still contains call from previous test!
  // If test checks toHaveBeenCalledTimes(1), it may get 2
});

// GOOD: configure clearMocks globally + use jest.mocked() typing
// jest.config.js: { clearMocks: true }

import { fetchUser } from './api';
jest.mock('./api');

beforeEach(() => {
  // clearMocks: true in config handles this automatically,
  // but explicit reset is self-documenting:
  jest.mocked(fetchUser).mockResolvedValue({ id: '1', name: 'Alice' });
});

test('shows loading state initially', () => {
  jest.mocked(fetchUser).mockImplementation(
    () => new Promise(() => {}) // never resolves
  );
  render(<UserProfile id="1" />);
  expect(screen.getByText('Loading...')).toBeVisible();
});

test('shows user name after load', async () => {
  render(<UserProfile id="1" />);
  await screen.findByText('Alice');
});
```

> **Code walkthrough:** BAD pattern: This Mocking with Jest (jest.mock, spies, stubs) example demonstrates TypeScript pattern using async/await. **KEY MECHANISM:** TypeScript compiles to JavaScript; type information is erased at runtime. **WHY IT MATTERS:** type assertions bypass the type checker - a runtime error can still occur. **WHAT BREAKS: prefer type guards over type assertions for safe narrowing of union types.**

**Example (Production) - Module mock with factory:**

```typescript
// Mock an entire module with specific implementations:
jest.mock('./auth', () => ({
  getCurrentUser: jest.fn(),
  isAuthenticated: jest.fn(),
  logout: jest.fn(),
}));

import { getCurrentUser, isAuthenticated } from './auth';

describe('Dashboard', () => {
  beforeEach(() => {
    jest.mocked(isAuthenticated).mockReturnValue(true);
    jest.mocked(getCurrentUser).mockReturnValue({
      id: 'user-1',
      name: 'Alice',
      role: 'admin',
    });
  });

  test('shows admin menu for admin users', () => {
    render(<Dashboard />);
    expect(screen.getByRole('link', { name: /admin panel/i }))
      .toBeInTheDocument();
  });

  test('redirects to login when not authenticated', () => {
    jest.mocked(isAuthenticated).mockReturnValue(false);
    render(<Dashboard />);
    expect(screen.getByText(/please log in/i)).toBeVisible();
  });
});

// Spy pattern for assertions on existing methods:
test('logs error to console on API failure', async () => {
  const consoleSpy = jest.spyOn(console, 'error')
    .mockImplementation(() => {}); // suppress during test

  jest.mocked(fetchUser).mockRejectedValue(new Error('API Error'));
  render(<UserProfile id="1" />);

  await screen.findByText(/something went wrong/i);
  expect(consoleSpy).toHaveBeenCalledWith(
    expect.stringContaining('API Error')
  );
  consoleSpy.mockRestore(); // always restore spies
});
```

> **Code walkthrough:** The BAD example uses a `jest.fn()` declaredice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> in module scope - mock state (call count, recorded args) accumulates
> across tests because there is no reset. `clearMocks: true` in
> jest.config.js automatically clears mock state between tests.
> The production example uses `jest.mock('./auth', () => ({...}))` with
> a factory function that creates fresh `jest.fn()` instances - this
> prevents the factory from being affected by module-level state.
> `jest.spyOn(console, 'error')` wraps the existing console.error
> method; calling `mockRestore()` in cleanup removes the wrapper and
> restores original behavior.

---

### ⚖️ Comparison Table

| Tool | What it replaces | Tracks calls | Preserves implementation |
|---|---|---|---|
| `jest.fn()` | Nothing (new function) | Yes | N/A |
| `jest.spyOn()` | Wraps existing method | Yes | Optional |
| `jest.mock()` | Entire module | Yes (per fn) | No (auto-mock) |
| `__mocks__/` directory | Module (persistent) | Optional | Manual |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> I use `jest.fn()` to create mock functions that I can control and
> assert on. `jest.mock('./module')` replaces an entire module. I call
> `mockReturnValue` to control what the mock returns. I assert with
> `toHaveBeenCalledWith` to verify the function was called correctly.

**Senior / Staff:**

> The key to maintainable mocking is scope: mock at the boundary you're
> testing, not deeper. If testing a React component that calls an API
> client, mock the API client, not the fetch() function. Mock as shallow
> as possible to keep tests understandable. For module mocks, I use
> factory functions in `jest.mock()` to ensure the mock is always
> created fresh. I configure `clearMocks: true` globally - accumulating
> call state across tests is a common source of flaky tests.

---

### ⚠️ Common Misconceptions

**Misconception: `jest.mock()` must be called before the import.**

Jest hoists `jest.mock()` calls to the top of the file before imports
at compile time. The order in source code doesn't matter. This is
handled by Babel/Jest transform.

**Exception**: Dynamic imports and `require()` calls are not hoisted.
For dynamic mocking (changing mock behavior between test files loaded
dynamically), use `jest.resetModules()` + re-require.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Mock not working - real implementation is called.**

Causes:
1. Module path mismatch: `jest.mock('./api')` but component imports
   from `../api` - paths must resolve to the same file
2. `jest.mock()` not hoisted for dynamic imports: `require()` inside
   a function is not auto-mocked
3. Manual mock in `__mocks__/` without calling `jest.mock()`
   (required for non-node_modules)

Diagnose: Add `console.log('mock called')` to mock implementation.
If it doesn't log, the real module is being used.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| `jest.fn()` vs `jest.spyOn()` vs `jest.mock()` | Comparison | ★★☆ | 3 min |
| Why is `jest.mock()` hoisted? | Mechanism | ★★☆ | 2 min |
| Mock not working - how to diagnose? | Debugging | ★★☆ | 2 min |
| How to mock a module that exports a class? | Scenario | ★★★ | 3 min |
| `clearMocks` vs `resetMocks` vs `restoreMocks` | Comparison | ★★☆ | 2 min |
| What is the difference between a stub and a spy? | Definition | ★★☆ | 2 min |
| When should you NOT use mocks? | Trade-off | ★★☆ | 2 min |

**Q: When should you NOT use mocks?**

A: Mocks reduce test fidelity by replacing real behavior with
controlled doubles. Overuse causes tests that pass while real
behavior is broken.

Avoid mocks when:

1. **The real implementation is fast and deterministic**: A pure
   function (sorting, filtering, formatting) should be tested with
   real inputs. Mocking it removes the test value.

2. **You want to test integration between two things**: If testing
   that component A correctly calls component B, mock B. If testing
   that A and B work together end-to-end, use real implementations.

3. **The mock diverges from real behavior over time**: A mocked
   API client returns `{ id: '1', name: 'Alice' }` but the real API
   changes the schema to `{ userId: '1', fullName: 'Alice Smith' }`.
   The mock is now wrong but tests pass. Contract tests or MSW
   (which uses realistic HTTP interception) mitigate this.

4. **Your mocks are more complex than the real thing**: If the
   jest.mock factory needs extensive configuration to replicate real
   behavior, consider an in-memory implementation (real class with
   different backing storage) instead.

*What separates good from great:* Distinguishing the "London school"
(mock all collaborators, verify interactions) from the "Detroit school"
(use real collaborators, verify end state). Neither is universally
correct - most frontend testing benefits from mocking external I/O
(HTTP, localStorage) while using real component trees.

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


# Mocking HTTP Requests with MSW

---

### 🎯 Model Answer

**30 seconds:**

> MSW (Mock Service Worker) intercepts HTTP requests at the network
> level using a service worker (browser) or Node.js HTTP interceptor.
> Tests use real fetch/axios calls - MSW intercepts before the network
> is hit. Define handlers with `http.get('/api/users', resolver)`.
> Use `server.use()` to override handlers per-test. This gives tests
> realistic HTTP semantics (headers, status codes, streaming) without
> a real server.

**3 minutes:**

MSW's key advantage over `jest.mock('axios')` or `jest.mock('fetch')`:
it intercepts at the network layer, not at the library layer. This
means:

1. **Agnostic of HTTP library**: same handlers work whether the
   component uses fetch, axios, ky, or any future library
2. **Realistic behavior**: response headers, status codes, errors
   behave like real HTTP
3. **Shared between tests and Storybook**: same handlers can be used
   for dev mode, Storybook, and Cypress tests
4. **No implementation coupling**: tests don't know how the component
   fetches data - just that it displays what the API returns

MSW v2 uses `http` (for REST) and `graphql` handler factories. Each
handler takes a resolver function with `({request, params}) => Response`.
The `HttpResponse` class provides response helpers.

**Blank Mind Recovery:**

**(1) What it does:** "Intercepts HTTP at network level. Real fetch
calls hit MSW, not the network."

**(2) Setup:** "server = setupServer(...handlers). beforeAll: server.listen().
afterEach: server.resetHandlers(). afterAll: server.close()."

**(3) Per-test override:** "server.use(http.get('/api/...', override))
inside a test to change response for that test only."

---

### 📘 Concept Explanation

**What it is:**

A library that intercepts HTTP requests at the network layer for
testing and development, using a service worker in browsers and a
Node.js HTTP interceptor in Jest.

**The problem it solves:**

Mocking `fetch` or `axios` at the library level is brittle: it breaks
when the HTTP library changes, doesn't test real serialization/
deserialization, and doesn't support request/response headers. MSW
makes mocking HTTP realistic.

**How it works:**

```
MSW v2 architecture:

  Browser mode:
    Service Worker intercepts actual HTTP requests
    request -> service worker -> MSW handler -> response
    No real network request is made

  Node.js mode (Jest):
    Node HTTP interceptor at the http.ClientRequest level
    Works with fetch (Node 18+), axios, node-fetch

  Handler definition:

  import { http, HttpResponse } from 'msw';

  const handlers = [
    http.get('/api/users', () => {
      return HttpResponse.json([{ id: 1, name: 'Alice' }]);
    }),

    http.post('/api/users', async ({ request }) => {
      const body = await request.json();
      return HttpResponse.json(
        { id: 2, ...body },
        { status: 201 }
      );
    }),

    http.get('/api/users/:id', ({ params }) => {
      if (params.id === '999') {
        return new HttpResponse(null, { status: 404 });
      }
      return HttpResponse.json({ id: params.id, name: 'Bob' });
    }),
  ];

  Test setup:

  import { setupServer } from 'msw/node';

  const server = setupServer(...handlers);

  beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
  afterEach(() => server.resetHandlers()); // reset per-test overrides
  afterAll(() => server.close());
```

> **Code walkthrough:** This Mocking HTTP Requests with MSW example demonstrates a key concept in practice using async/await. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Wrong vs Right) - Library mock vs MSW:**


```typescript
// BAD: using any defeats type safety
```

```typescript
// BAD: mocking fetch directly (library-coupled, brittle)
global.fetch = jest.fn();

test('shows users list', async () => {
  (global.fetch as jest.Mock).mockResolvedValue({
    ok: true,
    json: async () => [{ id: 1, name: 'Alice' }],
  });
  // Doesn't test actual response parsing
  // Breaks if component switches from fetch to axios
  render(<UserList />);
  await screen.findByText('Alice');
});

// GOOD: MSW intercepts at network level
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';
import { render, screen } from '@testing-library/react';

const server = setupServer(
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'Alice' },
      { id: 2, name: 'Bob' },
    ]);
  })
);

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test('shows users list', async () => {
  render(<UserList />);
  await screen.findByText('Alice');
  await screen.findByText('Bob');
});

// Per-test override for error scenario:
test('shows error when API fails', async () => {
  server.use(
    http.get('/api/users', () => {
      return new HttpResponse(null, { status: 500 });
    })
  );
  render(<UserList />);
  await screen.findByText(/something went wrong/i);
});
```

> **Code walkthrough:** BAD pattern: This Mocking HTTP Requests with MSW example demonstrates type assertion using async/await. **KEY MECHANISM:** as tells TypeScript to treat the value as a specific type without runtime check. **WHY IT MATTERS:** asserting an incompatible type causes runtime errors that TypeScript cannot catch. **WHAT BREAKS: use type guards (typeof, instanceof, is) instead of as for safe narrowing.**

**Example (Production) - Shared handlers and msw.config.ts:**

```typescript
// src/mocks/handlers.ts (shared between tests, Storybook, dev mode)
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json({ users: userFixtures, total: 3 });
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json() as Partial<User>;
    const newUser = { id: crypto.randomUUID(), ...body };
    return HttpResponse.json(newUser, { status: 201 });
  }),

  http.delete('/api/users/:id', ({ params }) => {
    return new HttpResponse(null, { status: 204 });
  }),
];

// src/mocks/server.ts (Jest/Node.js environment)
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// jest.setup.ts (or setupFilesAfterFramework):
import { server } from './src/mocks/server';
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
// Now all tests in the suite use the shared handlers by default
```

> **Code walkthrough:** The BAD example mocks `global.fetch` directly.
> This works but creates several problems: the mock must simulate the
> entire Response interface (ok, status, json(), text()), it only
> works with fetch (not axios), and it breaks if the component changes
> HTTP libraries. MSW intercepts before the network layer - `UserList`
> calls `fetch('/api/users')` normally, MSW returns the handler
> response instead of hitting a real server. `server.use()` inside a
> test adds a temporary handler that overrides the default for that
> test only. `server.resetHandlers()` in `afterEach` removes it.

---

### ⚖️ Comparison Table

| Approach | Library-agnostic | Realistic headers | Shareable | Setup cost |
|---|---|---|---|---|
| `jest.mock('fetch')` | No | No | No | Low |
| `jest.mock('axios')` | No | No | No | Low |
| MSW | Yes | Yes | Yes | Medium |
| Real test server | Yes | Yes | Yes (if running) | High |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> MSW defines HTTP request handlers that intercept requests during
> tests. I set up handlers with `http.get('/api/path', resolver)`,
> create a server with `setupServer(...handlers)`, and call
> `server.listen()` in `beforeAll`. Per-test overrides use
> `server.use(http.get(...))`.

**Senior / Staff:**

> MSW's main value is decoupling tests from the HTTP library. When I
> mock `axios` directly, my tests break if the component switches to
> fetch. With MSW, the same handlers work regardless of transport
> layer. I configure `onUnhandledRequest: 'error'` to catch unexpected
> requests - if a component makes an API call that has no handler,
> the test fails with a clear error instead of silently receiving
> undefined. I share handlers between Jest, Storybook, and Cypress
> by keeping them in `src/mocks/handlers.ts`.

---

### ⚠️ Common Misconceptions

**Misconception: MSW requires a running server in tests.**

MSW works entirely in-process in Node.js mode - no server process is
needed. The service worker is only used in browser (Storybook/dev
mode). In Jest, MSW uses Node.js HTTP interceptors that intercept
requests before they leave the process.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Tests make real HTTP requests when MSW is configured.**

Symptom: `onUnhandledRequest: 'error'` throws for expected endpoints.

Causes:
1. Handler URL doesn't match request URL (path vs absolute URL)
2. `server.listen()` not called (check jest.setup.ts or setupFiles)
3. Request uses a different base URL than the handler

Diagnose: Set `onUnhandledRequest: 'warn'` temporarily to see which
URLs are not matching. Print `request.url` in a catch-all handler:
`http.get('*', ({ request }) => { console.log(request.url); })`

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| MSW vs jest.mock('fetch') - why MSW? | Trade-off | ★★☆ | 2 min |
| How to override a handler for one test? | Scenario | ★★☆ | 2 min |
| What is `onUnhandledRequest: 'error'`? | Mechanism | ★★☆ | 1 min |
| How does MSW work in Node.js? | Mechanism | ★★☆ | 2 min |
| How to share MSW handlers with Storybook? | Design | ★★☆ | 2 min |
| How to test loading and error states? | Scenario | ★★★ | 3 min |
| Can MSW be used for Cypress E2E tests? | Scenario | ★★★ | 2 min |

**Q: How would you test loading and error states with MSW?**

A:
```typescript
// Loading state: use a delayed response
test('shows loading spinner during fetch', async () => {
  server.use(
    http.get('/api/users', async () => {
      // Delay response: spinner should be visible during this delay
      await new Promise(resolve => setTimeout(resolve, 100));
      return HttpResponse.json([{ id: 1, name: 'Alice' }]);
    })
  );

  render(<UserList />);

  // Should show spinner immediately:
  expect(screen.getByRole('progressbar')).toBeVisible();

  // Should show data after response:
  await screen.findByText('Alice');
  expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
});

// Error state: return error status code
test('shows error message on 500', async () => {
  server.use(
    http.get('/api/users', () => {
      return new HttpResponse(null, {
        status: 500,
        statusText: 'Internal Server Error',
      });
    })
  );

  render(<UserList />);
  const error = await screen.findByRole('alert');
  expect(error).toHaveTextContent(/failed to load/i);
});

// Network error (connection refused):
test('shows error on network failure', async () => {
  server.use(
    http.get('/api/users', () => {
      return HttpResponse.error(); // simulates network error
    })
  );

  render(<UserList />);
  await screen.findByText(/network error/i);
});
```

> **Code walkthrough:** This Unknown example demonstrates TypeScript pattern using async/await. **KEY MECHANISM:** TypeScript compiles to JavaScript; type information is erased at runtime. **WHY IT MATTERS:** type assertions bypass the type checker - a runtime error can still occur. **TAKEAWAY: prefer type guards over type assertions for safe narrowing of union types.**

*What separates good from great:* Using `HttpResponse.error()` to
simulate actual network failures (connection refused, DNS failure)
which is different from HTTP error status codes. Real applications
handle both cases and they require different error handling code.

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



