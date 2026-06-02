---
layout: default
title: "Node.js - L2 HTTP and Express"
parent: "Node.js"
nav_order: 5
permalink: /nodejs/l2-http-express/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [HTTP Module and Express Basics](#http-module-and-express-basics) | medium |
| 2 | [Middleware Pattern](#middleware-pattern) | medium |

---

# HTTP Module and Express Basics

---

### 🎯 Model Answer

**30 seconds:**

> Node.js has a built-in `http` module for creating servers. Express
> is a minimal framework layered on top of it. `http.createServer()`
> receives every request as a `(req, res)` pair - raw, without routing.
> Express adds routing (`app.get('/path', handler)`), middleware, and
> convenience methods (`res.json()`, `req.body`). Express is not a
> framework with opinions - it's a thin routing and middleware layer.
> For production, use body-parser middleware and a router-per-feature
> structure.

**Blank Mind Recovery:**

**(1) Built-in:** "`http.createServer((req, res) => {})` - one function
handles ALL requests. No routing built in."

**(2) Express adds:** "Routing by method + path. Middleware pipeline.
`res.json()`, `req.params`, `req.body` (with parser)."

**(3) Why Express:** "Routing + middleware + ecosystem. Not for
performance - for developer experience."

---

### 📘 Concept Explanation

**What it is:**

Node.js's http module creates HTTP servers. Express wraps it with
routing, middleware, and convenience APIs.

**How it works:**

```
HTTP module vs Express:

  Raw http module:
    const http = require('http');

    const server = http.createServer((req, res) => {
      // req: IncomingMessage (extends Readable stream)
      // res: ServerResponse (extends Writable stream)

      if (req.url === '/users' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ users: [] }));
      } else {
        res.writeHead(404);
        res.end('Not found');
      }
    });

    server.listen(3000);
    // Manual routing, manual headers, manual body parsing

  Express equivalent:
    import express from 'express';
    const app = express();

    app.use(express.json());         // body parser
    app.use(express.urlencoded({ extended: true }));

    app.get('/users', (req, res) => {
      res.json({ users: [] });       // automatic headers + stringify
    });

    app.post('/users', (req, res) => {
      const user = req.body;         // parsed from JSON body
      res.status(201).json(user);
    });

    app.listen(3000);

  Key Express concepts:
    app.METHOD(path, ...handlers)  // routing
    app.use(middleware)            // apply to all routes
    app.use(path, router)          // mount sub-router
    req.params                     // /users/:id -> { id: '123' }
    req.query                      // /search?q=test -> { q: 'test' }
    req.body                       // parsed body (needs body-parser)
    res.json(data)                 // send JSON with correct headers
    res.status(code).json(data)    // status + JSON
    next()                         // pass to next middleware
    next(err)                      // pass to error handler
```

> **Code walkthrough:** This HTTP Module and Express Basics example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Production) - Organized Express app:**

```javascript
// app.js - application setup:
import express from 'express';
import { userRouter } from './routes/users.js';
import { errorHandler } from './middleware/errors.js';

const app = express();

// Middleware:
app.use(express.json({ limit: '1mb' })); // parse JSON bodies
app.use(express.urlencoded({ extended: false }));

// Routes:
app.use('/api/users', userRouter);

// 404 handler (after all routes):
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// Error handler (4 params = error handler):
app.use(errorHandler);

export { app };

// routes/users.js:
import { Router } from 'express';
const userRouter = Router();

const asyncRoute = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

userRouter.get('/', asyncRoute(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const users = await userService.list({ page, limit });
  res.json(users);
}));

userRouter.get('/:id', asyncRoute(async (req, res) => {
  const user = await userService.getById(req.params.id);
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  res.json(user);
}));

userRouter.post('/', asyncRoute(async (req, res) => {
  const user = await userService.create(req.body);
  res.status(201).json(user);
}));

export { userRouter };

// middleware/errors.js - centralized error handler:
export function errorHandler(err, req, res, next) {
  console.error(err);
  const status = err.status ?? err.statusCode ?? 500;
  res.status(status).json({
    error: err.message ?? 'Internal server error'
  });
}
```

> **Code walkthrough:** The `asyncRoute` wrapper is non-negotiable inice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> Express - without it, `async` route handlers that throw won't forward
> the error to Express's error handler. `express.json({ limit: '1mb' })`
> limits request body size (without this, a client can send an arbitrarily
> large body and exhaust memory). The error handler has 4 parameters -
> Express recognizes it as an error handler by the 4th `next` parameter.
> Mounting the router at `/api/users` means route paths inside the router
> are relative: `get('/')` handles `GET /api/users`. The 404 handler
> must come after all routes but before the error handler.

---

### ⚖️ Comparison Table

| Feature | Raw http | Express | Fastify |
|---|---|---|---|
| Routing | Manual | app.METHOD | app.METHOD |
| Body parsing | Manual | express.json | Built-in |
| Performance | Best | Good | Better than Express |
| TypeScript | Manual | @types/express | Full native TS |
| Validation | None | None (add zod) | Built-in JSON Schema |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Express adds routing and middleware to Node.js's built-in http module.
> I use `app.get()`, `app.post()` etc for routes, `app.use()` for
> middleware. `req.body` contains parsed JSON (with `express.json()`
> middleware). Errors go to a 4-parameter handler.

**Senior / Staff:**

> Express's main value is the middleware pipeline and routing ecosystem.
> For high-performance APIs, Fastify is 2-3x faster due to JSON schema
> compilation and efficient routing. For simple Node.js services, the
> raw `http` module is sufficient without the overhead. The async route
> wrapper pattern is a known Express limitation - Fastify handles async
> errors natively. Express 5 (in progress) will add native async support.

---

### ⚠️ Common Misconceptions

**Misconception: Express handles async route errors automatically.**

Express was designed before async/await. A thrown error in an async
route handler IS NOT caught by Express's error handler. The process
receives an `UnhandledPromiseRejection`. Always wrap async routes with
a `.catch(next)` pattern or use the `asyncRoute` wrapper.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Request bodies are empty (`req.body` is undefined).**

Cause: `express.json()` middleware not registered, or registered after
the route.

Fix: Register `app.use(express.json())` BEFORE all routes.

**Failure: Memory exhaustion from large request bodies.**

Fix: `app.use(express.json({ limit: '100kb' }))` - always set a limit.
Default is 100kb, but must be explicit.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What does Express add over raw http? | Comparison | ★☆☆ | 2 min |
| How does `req.body` work? | Mechanism | ★★☆ | 2 min |
| Why wrap async route handlers? | Failure | ★★☆ | 3 min |
| How do you structure a large Express app? | Design | ★★★ | 3 min |
| Express vs Fastify - when to use each? | Decision | ★★★ | 3 min |

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


# Middleware Pattern

---

### 🎯 Model Answer

**30 seconds:**

> Middleware is a function in Express (and other frameworks) that has
> access to `(req, res, next)`. It runs between the incoming request
> and the final route handler. Calling `next()` passes to the next
> middleware; `next(err)` jumps to the error handler. Middleware is
> used for: auth, logging, body parsing, rate limiting, CORS. Order
> matters: middleware runs in registration order. A middleware that
> doesn't call `next()` or send a response will hang the request.

**Blank Mind Recovery:**

**(1) Signature:** "`(req, res, next)` - three args. Call `next()` to continue
or `next(err)` for errors."

**(2) Order:** "Runs in registration order. Mount before routes that need it."

**(3) Pitfall:** "Forgot to call `next()` = request hangs forever."

---

### 📘 Concept Explanation

**What it is:**

A design pattern for composing request processing pipelines. Each
middleware function can inspect/modify the request and response, then
pass control to the next function.

**How it works:**

```
Middleware execution pipeline:

  Request -> [MW1] -> [MW2] -> [Route Handler] -> Response
                  |         |
              next()     next()

  Types of middleware:
    Application-level: app.use(fn)
    Router-level: router.use(fn)
    Error-handling: (err, req, res, next) - 4 params
    Built-in: express.json(), express.static()
    Third-party: cors(), helmet(), morgan(), express-rate-limit

  Authentication middleware example:
    function authenticate(req, res, next) {
      const token = req.headers.authorization?.split(' ')[1];
      if (!token) {
        return res.status(401).json({ error: 'No token' });
        // Does NOT call next() - short-circuits the chain
      }
      try {
        const user = jwt.verify(token, process.env.JWT_SECRET);
        req.user = user;  // attach to req for downstream use
        next();           // pass to next middleware/route
      } catch (err) {
        next(err);         // pass to error handler
      }
    }

  Conditional middleware:
    // Apply only to specific routes:
    app.get('/admin', authenticate, adminHandler);

    // Apply to all routes under /api:
    app.use('/api', authenticate);

  Middleware ordering (matters!):
    app.use(morgan('dev'));     // 1st: logging (all requests)
    app.use(cors());           // 2nd: CORS headers
    app.use(express.json());   // 3rd: parse bodies
    app.use('/api', router);   // 4th: routes
    app.use(errorHandler);     // LAST: error handler

  Building composable middleware:
    function rateLimit(maxRequests, windowMs) {
      const counts = new Map();
      return (req, res, next) => {
        const key = req.ip;
        const count = (counts.get(key) ?? 0) + 1;
        counts.set(key, count);
        setTimeout(() => counts.delete(key), windowMs);
        if (count > maxRequests) {
          return res.status(429).json({ error: 'Too many requests' });
        }
        next();
      };
    }
    app.use(rateLimit(100, 60000)); // 100 req/minute
```

> **Code walkthrough:** This Middleware Pattern example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Production) - Security middleware stack:**


```javascript
// BAD: anti-pattern - see GOOD example below
```

```javascript
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';

const app = express();

// Security headers (sets X-Frame-Options, HSTS, etc.):
app.use(helmet());

// CORS:
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') ?? '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

// Rate limiting (per IP):
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,                  // 100 requests per window
  message: { error: 'Too many requests' }
});
app.use('/api/', limiter);

// Body parsing with size limit:
app.use(express.json({ limit: '10kb' }));

// Request logging middleware:
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    console.log(
      `${req.method} ${req.path} `
      + `${res.statusCode} ${Date.now() - start}ms`
    );
  });
  next();
});

// BAD: async middleware without error handling:
app.use(async (req, res, next) => {
  const user = await loadUser(req.headers.authorization);
  req.user = user;
  // If loadUser() throws: UnhandledPromiseRejection!
});

// GOOD: wrap with try/catch and forward to next:
app.use(async (req, res, next) => {
  try {
    const user = await loadUser(req.headers.authorization);
    req.user = user;
    next();
  } catch (err) {
    next(err); // forward to error handler
  }
});
```

> **Code walkthrough:** `helmet()` sets dozens of security-criticalice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> HTTP headers in one middleware call (Content-Security-Policy,
> X-Frame-Options, HSTS, etc). CORS middleware must come before routes
> so OPTIONS preflight requests are handled. The rate limiter on `/api/`
> applies to all API routes. The body size limit (`10kb`) prevents
> memory exhaustion attacks. The request logging uses `res.on('finish')`
> to capture the status code after the response is sent - logging in
> the request handler before the response would show the wrong status.
> The async middleware pattern is critical: wrap in try/catch and call
> `next(err)` to forward errors to Express's error handler.

---

### ⚖️ Comparison Table

| Middleware | Purpose | Essential |
|---|---|---|
| `helmet` | Security headers | Yes (production) |
| `cors` | Cross-origin headers | Yes (APIs) |
| `express.json` | Parse JSON bodies | Yes (APIs) |
| `morgan` | HTTP access logging | Development |
| `express-rate-limit` | Rate limiting | Yes (public APIs) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Middleware functions run before route handlers. They receive `req`,
> `res`, and `next`. Calling `next()` continues to the next middleware.
> I use middleware for logging, body parsing, auth. Order matters -
> middleware runs in the order I register it.

**Senior / Staff:**

> Middleware is a pipeline pattern. Key design insight: middleware
> transforms or validates the request, routes handle the business logic.
> Security middleware order matters: CORS must handle preflight OPTIONS
> before auth middleware sees it. Body parser before routes that need
> the body. Rate limiter before body parser (don't process the body
> if rate limited). Error handler last with 4 parameters. For complex
> apps, per-router middleware scoping avoids applying auth middleware
> to public routes.

---

### ⚠️ Common Misconceptions

**Misconception: `app.use(errorHandler)` handles all errors.**

Error handlers only receive errors passed via `next(err)`. Errors
thrown in synchronous code inside route handlers ARE caught by Express.
But errors thrown in async callbacks (not `await`ed) are NOT. The
`asyncRoute` wrapper catches them and calls `next(err)`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Request hangs with no response.**

Cause: Middleware forgot to call `next()` or `res.end()`.

Diagnose:
```javascript
// Add timeout middleware to detect hangs:
app.use((req, res, next) => {
  res.setTimeout(5000, () => {
    res.status(408).json({ error: 'Request timeout' });
  });
  next();
});
// If a middleware never calls next(), the timeout fires
```

> **Code walkthrough:** This Unknown example demonstrates arrow function. **KEY MECHANISM:** arrow functions capture `this` lexically from the enclosing scope at definition time. **WHY IT MATTERS:** using arrow function as an object method loses `this` - it becomes the outer context. **TAKEAWAY: use arrow functions for callbacks; use regular functions for object methods.**

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is middleware and how does it work? | Definition | ★☆☆ | 2 min |
| Why does middleware order matter? | Mechanism | ★★☆ | 2 min |
| How do you write error-handling middleware? | Code | ★★☆ | 2 min |
| Request hangs - what's wrong? | Debugging | ★★☆ | 2 min |
| What security middleware should every Express app have? | Production | ★★★ | 3 min |
| Async middleware - how to handle errors? | Failure | ★★☆ | 2 min |

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



