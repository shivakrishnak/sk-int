---
layout: default
title: "Node.js - L3 Security"
parent: "Node.js"
nav_order: 8
permalink: /nodejs/l3-security/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Node.js Security Anti-patterns](#nodejs-security-anti-patterns) | medium |
| 2 | [Authentication and Session Security](#authentication-and-session-security) | medium |

---

# Node.js Security Anti-patterns

---

### 🎯 Model Answer

**30 seconds:**

> Node.js applications have specific security risks beyond generic web
> security. Top anti-patterns: (1) `eval()` and `new Function()` on
> user input - arbitrary code execution. (2) `exec()` with user input -
> shell injection. (3) path traversal: `fs.readFile(req.params.file)`
> without sanitizing - read any file. (4) prototype pollution: merging
> untrusted objects into plain objects - corrupts Object.prototype.
> (5) `__proto__` in JSON payloads. Use `npm audit`, helmet, input
> validation (zod/joi), and never trust `req.body` or `req.query` as-is.

**Blank Mind Recovery:**

**(1) Code injection:** "`eval(userInput)` = arbitrary code execution.
NEVER eval user input."

**(2) Shell injection:** "`exec(cmd + userInput)` = shell injection.
Use `spawn` with args array."

**(3) Path traversal:** "`readFile(req.params.path)` = can read `/etc/passwd`.
Validate and sanitize paths."

---

### 📘 Concept Explanation

**What it is:**

Common security vulnerabilities specific to Node.js: code injection,
command injection, path traversal, prototype pollution, and dependency
vulnerabilities.

**How it works:**

```
Node.js security vulnerabilities:

  1. Code Injection (CWE-94):
     // CRITICAL:
     eval(req.body.expression);
     new Function(req.body.code)();
     const Module = require('module');
     Module._resolveFilename(req.body.path);

     Any of these run attacker-supplied code as Node.js process.

  2. Command Injection (CWE-78):
     const { exec } = require('child_process');
     exec(`ls ${req.query.path}`); // CRITICAL
     // req.query.path = "; rm -rf /"

  3. Path Traversal (CWE-22):
     // Attacker sends req.params.file = "../../etc/passwd"
     const filePath = `./public/${req.params.file}`;
     fs.readFile(filePath, callback);

  4. Prototype Pollution (CWE-1321):
     // Merging JSON with __proto__ key:
     const user = JSON.parse('{"__proto__":{"isAdmin":true}}');
     Object.assign({}, user);
     // Now: ({}).isAdmin === true for ALL objects!

     // lodash merge before patch:
     const _ = require('lodash');
     _.merge({}, JSON.parse(
       '{"__proto__":{"polluted":true}}'
     ));

  5. Regular Expression DoS (ReDoS):
     // Catastrophic regex on untrusted input:
     const emailRegex = /^([a-zA-Z0-9])(([a-zA-Z0-9])*([._-])?)+@[...]+$/;
     emailRegex.test('a'.repeat(50) + '!'); // exponential time

  6. Dependency vulnerabilities:
     npm audit  // check for known CVEs
     # Must run in CI pipeline
```

> **Code walkthrough:** This Must run in CI pipeline example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Wrong vs Right) - Path traversal prevention:**


```javascript
// BAD: anti-pattern - see GOOD example below
```


```javascript
// BAD: anti-pattern - see GOOD example below
```

```javascript
import { readFile } from 'fs/promises';
import { resolve, join, normalize } from 'path';

const PUBLIC_DIR = resolve('./public');

// BAD: directly uses user input in path:
app.get('/files/:name', async (req, res) => {
  const filePath = join('./public', req.params.name);
  // req.params.name = "../../etc/passwd" -> reads system files!
  const content = await readFile(filePath);
  res.send(content);
});

// GOOD: resolve and validate path stays within allowed dir:
app.get('/files/:name', asyncRoute(async (req, res) => {
  // Resolve to absolute path:
  const requestedPath = resolve(PUBLIC_DIR, req.params.name);

  // Validate it's within the public directory:
  if (!requestedPath.startsWith(PUBLIC_DIR + '/')) {
    return res.status(403).json({ error: 'Access denied' });
  }

  const content = await readFile(requestedPath);
  res.send(content);
}));

// Prototype pollution prevention:
// BAD: using a plain object as hash map:
const userCache = {};
// Attacker sends key = "__proto__"
userCache['__proto__'] = { isAdmin: true };
// Now EVERY object in the process has isAdmin: true!

// GOOD: use Map or null-prototype objects:
const userCache = new Map(); // Map is not affected by __proto__
// OR:
const safeCache = Object.create(null); // no prototype

// Input validation with zod (prevents injection at boundary):
import { z } from 'zod';

const SearchSchema = z.object({
  q: z.string().min(1).max(100),
  page: z.number().int().min(1).max(1000).default(1),
  // Not: z.string() on 'page' (would accept JS injection)
});

app.get('/api/search', asyncRoute(async (req, res) => {
  const params = SearchSchema.safeParse(req.query);
  if (!params.success) {
    return res.status(400).json({ error: params.error.flatten() });
  }
  // params.data.q is validated, sanitized string
  const results = await search(params.data);
  res.json(results);
}));
```

> **Code walkthrough:** Path traversal prevention requires resolving toice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> an absolute path and checking that it starts with the allowed directory
> prefix. `normalize` alone is insufficient - `../../../etc/passwd`
> normalizes to an absolute path outside the public directory. `resolve`
> converts relative paths to absolute, then the prefix check ensures
> the path stays within bounds. Prototype pollution via `__proto__` is
> fixed by using `Map` (not affected by `__proto__` manipulation) or
> `Object.create(null)` (creates an object with no prototype at all).
> Zod schema validation at the API boundary rejects invalid input
> before it reaches any business logic.

---

### ⚖️ Comparison Table

| Vulnerability | Attack vector | Prevention |
|---|---|---|
| Code injection | `eval(userInput)` | Never eval user input |
| Command injection | `exec(cmd + input)` | `spawn` with args array |
| Path traversal | `readFile(userPath)` | resolve + prefix check |
| Prototype pollution | `merge(user, parsed)` | Use Map/null-proto |
| ReDoS | `regex.test(longInput)` | Limit input length |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Key security rules in Node.js: never use `eval()` on user input,
> never pass user input to `exec()`, always validate and sanitize file
> paths. Use `helmet` for security headers, `express-rate-limit` to
> prevent brute force. Run `npm audit` regularly.

**Senior / Staff:**

> Node.js security requires understanding the specific attack surface.
> The most dangerous is arbitrary code execution via `eval` or
> `new Function`. Path traversal is the most common real-world vulnerability
> in Node.js servers. Prototype pollution is a Node.js-specific risk
> that can subtly corrupt application logic. Security layers: input
> validation (zod), parameterized queries, path validation, security
> headers (helmet), dependency scanning (Snyk/audit). For supply chain
> security: pin dependencies with lock files, use `npm ci`, audit
> before deploy.

---

### ⚠️ Common Misconceptions

**Misconception: JSON.parse is safe from all injection attacks.**

`JSON.parse` is safe from code injection. But parsed JSON can contain
`__proto__` keys that cause prototype pollution when merged into objects.
Always use `Object.create(null)` or `Map` for hash maps. Use JSON Schema
validation or zod to reject unexpected keys before merging.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Server starts returning unexpected `true` for permission checks.**

Cause: Prototype pollution - an attacker has set `__proto__.isAdmin = true`
by sending a payload like `{"__proto__":{"isAdmin":true}}` to a
merge endpoint.

Diagnose:
```javascript
// Check for pollution:
console.log(({}).isAdmin); // true if polluted

// Find the source: look for Object.assign, _.merge,
// deepmerge, or other merge operations on user input
```

> **Code walkthrough:** This Must run in CI pipeline example demonstrates JavaScript pattern. **KEY MECHANISM:** V8 JIT-compiles hot functions to machine code; polymorphic call sites deoptimize the function. **WHY IT MATTERS:** closure captures the reference not the value - loop variables captured in closures retain last value. **TAKEAWAY: use block-scoped let/const in loops and closures to prevent stale reference bugs.**

Fix: Use `JSON.parse` with validation (reject `__proto__` keys).
Use `Object.create(null)` for dictionaries.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is path traversal and how to prevent it? | Security | ★★☆ | 3 min |
| What is prototype pollution? | Security | ★★★ | 4 min |
| Why is `exec(cmd + userInput)` dangerous? | Security | ★★☆ | 2 min |
| What is ReDoS? | Security | ★★★ | 3 min |
| Essential security middleware for Express? | Production | ★★☆ | 3 min |

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


# Authentication and Session Security

---

### 🎯 Model Answer

**30 seconds:**

> Authentication in Node.js HTTP APIs uses JWTs or sessions. JWTs:
> signed tokens containing claims, verified without a database hit.
> Sessions: server-side store with a signed cookie holding only the
> session ID. JWT pros: stateless, scalable. JWT cons: can't invalidate
> without a denylist. Session pros: easy logout. Session cons: requires
> store (Redis). Key rules: sign with strong secret (256-bit), use
> HTTPS only, set short expiry, validate in middleware, never store
> sensitive data in JWT payload (it's base64-encoded, not encrypted).

**Blank Mind Recovery:**

**(1) JWT:** "Signed token. Stateless. Can't invalidate without denylist.
Short expiry (15 min)."

**(2) Session:** "Server stores state. Client has only ID. Easy logout.
Needs Redis for multi-instance."

**(3) Never:** "Never store passwords in plaintext. Never trust JWT payload
without verifying signature. Never send token in URL."

---

### 📘 Concept Explanation

**What it is:**

Patterns for authenticating HTTP requests in Node.js APIs: JWT
(stateless) and session-based (stateful) authentication.

**How it works:**

```
JWT authentication flow:

  Login:
    POST /auth/login { email, password }
    1. Look up user in DB
    2. bcrypt.compare(password, hashedPassword)
    3. If valid: jwt.sign(
         { userId: user.id, role: user.role },
         process.env.JWT_SECRET,
         { expiresIn: '15m', algorithm: 'HS256' }
       )
    4. Return: { token, refreshToken }

  Request:
    Authorization: Bearer <jwt>
    1. Extract token from header
    2. jwt.verify(token, process.env.JWT_SECRET)
    3. Decoded payload: { userId, role, iat, exp }
    4. Attach to req.user

  Refresh flow:
    POST /auth/refresh { refreshToken }
    1. Verify refresh token (longer expiry: 7 days)
    2. Issue new access token (15m)

  Session authentication:

  Login:
    POST /auth/login
    1. Verify credentials
    2. req.session.userId = user.id  // express-session
    3. Set-Cookie: sessionId=<signed-id>; HttpOnly; Secure; SameSite=Strict

  Request:
    Cookie: sessionId=<signed-id>
    1. Verify cookie signature (secret)
    2. Look up session in Redis store
    3. Get userId, attach user data to req

  Security rules:
    - JWT_SECRET: minimum 256-bit random string
    - HTTPS only: Secure flag on cookies, always TLS
    - HttpOnly cookies: prevent XSS stealing tokens
    - SameSite=Strict: CSRF protection
    - Short expiry: access tokens 15 min
    - Rate limit: /auth/login (brute force prevention)
    - Log failed attempts: detect credential stuffing
```

> **Code walkthrough:** This Authentication and Session Security example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

**Example (Production) - JWT authentication middleware:**

```javascript
import jwt from 'jsonwebtoken';
import { z } from 'zod';

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET || JWT_SECRET.length < 32) {
  throw new Error('JWT_SECRET must be 32+ chars');
}

// Authentication middleware:
export function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token' });
  }

  const token = authHeader.slice(7);
  try {
    const payload = jwt.verify(token, JWT_SECRET, {
      algorithms: ['HS256'],     // explicit algorithm list
      // prevents algorithm confusion attacks (RS256 vs HS256)
    });
    req.user = { id: payload.userId, role: payload.role };
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token expired',
        code: 'TOKEN_EXPIRED' // client knows to refresh
      });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// Login route with brute force protection:
import rateLimit from 'express-rate-limit';
import bcrypt from 'bcrypt';

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 10,                    // 10 attempts
  skipSuccessfulRequests: true
});

const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1).max(128)
});

app.post('/auth/login', loginLimiter,
  asyncRoute(async (req, res) => {
    const body = LoginSchema.safeParse(req.body);
    if (!body.success) {
      return res.status(400).json({ error: 'Invalid input' });
    }

    const user = await userService.findByEmail(body.data.email);
    // IMPORTANT: constant-time comparison even if user not found:
    const passwordValid = user
      ? await bcrypt.compare(body.data.password, user.passwordHash)
      : await bcrypt.compare(body.data.password, '$2b$12$dummy');
    // Without the else branch: timing attack reveals valid emails

    if (!user || !passwordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      JWT_SECRET,
      { expiresIn: '15m', algorithm: 'HS256' }
    );

    res.json({ token });
  })
);
```

> **Code walkthrough:** Several security details are critical: explicitice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> `algorithms: ['HS256']` in `jwt.verify` prevents algorithm confusion
> attacks (where an attacker changes `alg` to `none` or `RS256` in
> the header). The constant-time bcrypt comparison in the login route
> prevents timing attacks: if we return immediately for unknown emails,
> an attacker can detect valid email addresses by measuring response
> time differences. By always calling `bcrypt.compare` (even with a
> dummy hash for unknown users), response time is consistent. Rate
> limiting on login prevents brute force. `skipSuccessfulRequests: true`
> only counts failed attempts against the rate limit.

---

### ⚖️ Comparison Table

| Approach | Stateless | Revocation | Scalability |
|---|---|---|---|
| JWT (access only) | Yes | Hard (denylist needed) | Excellent |
| JWT + refresh token | Mostly | Refresh can be revoked | Good |
| Session + Redis | No | Easy (delete session) | Good (Redis) |
| Session + DB | No | Easy | Poor (DB per request) |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> JWTs are signed tokens containing user claims. I verify them with
> `jwt.verify()` using a secret. For sessions, I use `express-session`
> with Redis. Key security rules: HTTPS only, HttpOnly cookies, short
> token expiry, rate limit on login.

**Senior / Staff:**

> JWT's main weakness is revocation: you can't invalidate a token
> without a denylist (which adds the database hit you were avoiding).
> The common pattern: short-lived access tokens (15min) + longer-lived
> refresh tokens (7 days) stored in HttpOnly Secure cookies (not
> localStorage). If the access token is stolen, it expires quickly.
> If the refresh token is stolen, you can revoke it in the database.
> Algorithm confusion attacks are a real CVE - always specify algorithms
> in verify.

---

### ⚠️ Common Misconceptions

**Misconception: JWT payload is encrypted.**

JWT payload is base64-encoded, not encrypted. Anyone who intercepts
the token can read the payload. Only the signature is cryptographic.
Never put sensitive data (passwords, SSNs, credit cards) in JWT
payloads. If you need encryption, use JWE (JSON Web Encryption) or
encrypt the payload separately.

---

### 🚨 Failure Modes and Diagnosis

**Failure: JWT `none` algorithm attack.**

Attacker modifies JWT header to `{"alg":"none"}` and removes the
signature. If the server doesn't specify allowed algorithms, it
may accept the unsigned token.

Fix: Always specify `algorithms: ['HS256']` (or your chosen algorithm)
in `jwt.verify` options. Never allow `none`.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| JWT vs session - when to use each? | Decision | ★★☆ | 3 min |
| How do you revoke a JWT? | Mechanism | ★★★ | 3 min |
| What is the algorithm confusion attack? | Security | ★★★ | 3 min |
| What is a timing attack in auth? | Security | ★★★ | 3 min |
| How do you store tokens securely in a browser? | Security | ★★☆ | 2 min |
| Refresh token rotation pattern? | Mechanism | ★★★ | 3 min |

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



