---
layout: default
title: "GraphQL - L4 Production"
parent: "GraphQL"
nav_order: 9
permalink: /graphql/l4-production/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 20 | [GraphQL Security: Introspection, Rate Limiting, and Query Whitelisting](#graphql-security) | ★★★ |

---

# GraphQL Security

---

### 🎯 Model Answer

**30 seconds:**
> GraphQL has a unique attack surface compared to REST. Three critical production
> security controls: (1) Disable introspection in production - prevents schema
> reconnaissance; (2) Rate limiting per client - prevents query volume attacks;
> (3) Query whitelisting (Persisted Queries/APQ) - only pre-registered queries execute,
> eliminating arbitrary novel query attacks. Add depth limiting and complexity scoring
> as defense-in-depth. Never expose raw GraphQL errors to clients.

**3 minutes (Senior):**
> The GraphQL attack surface is different from REST: every endpoint is `POST /graphql`;
> the attack vector is the query payload, not the URL. Four primary attack categories:
> (1) DoS via expensive queries (depth/width/alias attacks) - mitigated by depth limiting,
> complexity scoring, and query timeout. (2) Schema reconnaissance via introspection -
> mitigated by disabling `__schema` in production. (3) Injection via query variables -
> mitigated by parameterized queries and input validation; GraphQL variables are
> parameterized by design (safe from injection when using `$variable` syntax). (4)
> Excessive data exposure via unbounded queries - mitigated by pagination enforcement,
> field-level authorization, and complexity limits. The strictest protection: Persisted
> Queries (APQ) - clients register query documents during the build process; at runtime,
> only query hashes are sent; the server maps hash to the pre-registered document; no
> novel query is ever executed. APQ eliminates the arbitrary query attack surface
> entirely. The defense-in-depth stack: introspection disabled + complexity limits +
> depth limits + query timeout + rate limiting + APQ + field-level auth + error
> sanitization.

**Blank Mind Recovery:**

**(1) Restate:** "GraphQL security differs from REST: one endpoint, variable query payloads.
Attacks: expensive queries (depth/alias), schema discovery (introspection), injection
(variables), excessive exposure (unbounded lists). Defense stack: introspection off +
complexity + depth + timeout + rate limit + APQ (strictest). APQ = only pre-registered
queries; novel queries rejected. Error sanitization via `formatError`."

---

### 📘 Concept Explanation

**GraphQL Threat Model:**

```text
GRAPHQL ATTACK SURFACE:

REST API:
  GET /users/123 -> Fixed cost, known shape
  POST /orders   -> Fixed endpoint, validated body
  Surface: URL paths + HTTP methods

GraphQL API:
  POST /graphql  -> Variable cost, variable shape
  Body: { query: "..." }  <- Any valid GraphQL!
  Surface: the query language itself

  Specific attack classes:
  A1. Expensive query (DoS):
    { user { friends { friends { friends { ... }}}}}
    1 request -> millions of DB queries

  A2. Schema discovery (reconnaissance):
    { __schema { types { name fields { name } } } }
    Full API map in one request

  A3. Alias amplification:
    { a1:posts a2:posts a3:posts ... a1000:posts }
    1000 executions in 1 request, low apparent depth

  A4. Query variable injection:
    Variable: { id: "1; DROP TABLE users; --" }
    Mitigated: GraphQL variables are typed/parameterized

  A5. Unbounded list exposure:
    { users { creditCard { number } } }
    Returns ALL users' credit cards

  DEFENSE LAYERS (in order of effectiveness):
  D1. APQ (query whitelisting) - eliminates A1,A2,A3
  D2. Complexity + depth limits - mitigates A1,A3
  D3. Introspection disabled - eliminates A2
  D4. Field-level auth - mitigates A5
  D5. Query timeout - backstop for A1
  D6. Rate limiting - limits all attacks by volume
  D7. Error sanitization - prevents info disclosure
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: GraphQL's unique attack surface (one endpoint, variable query payloads) contrasted with REST (fixed endpoints), followed by five attack classes and seven defense layers with their coverage mapping. (2) HOW TO READ IT: the attack classes A1-A5 show what attackers can do; the defense layers D1-D7 show what server-side controls block which attacks; D1 (APQ) covers the most attacks. (3) KEY RELATIONSHIP: attacks A1-A3 exploit GraphQL's flexible query language; defenses D1-D3 are specific to GraphQL; D4-D7 are general API security controls. (4) EDGE CASE: A4 (injection) is largely mitigated by GraphQL's typed variable system; variables declared as `ID!` type are validated as ID format; BUT parameterized queries only work if the resolver uses `$variable` syntax; a resolver that string-concatenates variables into SQL bypasses the protection. (5) INSIGHT: a senior engineer recognizes that APQ (D1) is a paradigm shift: instead of input validation (checking that bad queries are rejected), APQ uses allowlisting (only pre-approved queries execute); allowlisting is always stronger than blacklisting for security.

---

### 💻 Code Example

```javascript
// BAD: GraphQL server with no security controls
// Vulnerable to all five attack classes

const server = new ApolloServer({
  typeDefs,
  resolvers,
  // No validationRules
  // No query timeout
  // No introspection disabled
  // No formatError sanitization
  // No rate limiting
  // -> All queries accepted and executed
  // -> Schema visible via __schema
  // -> No protection from DoS or data scraping
  introspection: true,  // Always on!
});

app.use('/graphql', server.middleware());
// No rate limiting middleware
// Raw GraphQL errors exposed to clients:
// "ERROR: relation 'users' does not exist"
//  -> Reveals database table structure!
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a bare Apollo Server with zero security controls - introspection always enabled, no validation rules, no error sanitization, no rate limiting. (2) KEY MECHANISM: `introspection: true` means `{ __schema { ... } }` returns the full schema; database error messages reach the client (revealing table names, column names); any query depth or complexity is accepted. (3) WHY IT MATTERS: this is the default state for many new GraphQL APIs; shipping to production without security controls is a common mistake that leaves the API open to OWASP API Security Top 10 vulnerabilities. (4) WHAT BREAKS: raw database error messages to clients are an information disclosure vulnerability; "relation 'users' does not exist" reveals the database schema; "duplicate key value violates unique constraint 'users_email_key'" reveals column names. (5) TAKEAWAY: before going to production, apply the security checklist: introspection off, complexity limit, depth limit, query timeout, rate limiting, formatError, field-level auth on sensitive data.

```javascript
// GOOD: Production GraphQL security stack
// Defense in depth - all seven controls applied

const {
  ApolloServerPluginLandingPageDisabled
} = require('@apollo/server/plugin/disabled');
const {
  createComplexityLimitRule,
  simpleEstimator
} = require('graphql-query-complexity');
const depthLimit = require('graphql-depth-limit');
const rateLimit = require('express-rate-limit');
const { createHash } = require('crypto');

// D2: Complexity limit
const complexityRule = createComplexityLimitRule(1000, {
  estimators: [simpleEstimator({ defaultComplexity: 1 })]
});

// D2: Depth limit
const depthLimitRule = depthLimit(7);

// D5: Query timeout plugin
const timeoutPlugin = {
  requestDidStart: () => ({
    executionDidStart: () => ({
      willResolveField: () => {
        const timer = setTimeout(() => {
          throw new GraphQLError('Query timeout', {
            extensions: { code: 'TIMEOUT' }
          });
        }, 10000);  // 10 second timeout
        return () => clearTimeout(timer);
      }
    })
  })
};

// D7: Error sanitization
const sanitizeError = (formattedError, err) => {
  // Log full error server-side
  logger.error(formattedError.extensions?.code, {
    message: err.message,
    stack: err.stack,
    query: formattedError.path
  });

  // Never expose internal errors to clients
  if (formattedError.extensions?.code ===
      'INTERNAL_SERVER_ERROR') {
    return {
      message: 'Internal server error',
      locations: formattedError.locations,
      path: formattedError.path,
      extensions: { code: 'INTERNAL_SERVER_ERROR' }
    };
  }
  // Client errors (VALIDATION, AUTH, etc.) pass through
  return formattedError;
};

const server = new ApolloServer({
  typeDefs,
  resolvers,

  // D3: Disable introspection in production
  introspection: process.env.NODE_ENV !== 'production',

  // D2: Complexity + depth limits
  validationRules: [complexityRule, depthLimitRule],

  // D5 + D1 (APQ) plugins
  plugins: [
    timeoutPlugin,
    // Disable GraphQL Playground in production
    process.env.NODE_ENV === 'production'
      ? ApolloServerPluginLandingPageDisabled()
      : ApolloServerPluginLandingPageLocalDefault()
  ],

  // D7: Sanitize errors
  formatError: sanitizeError
});

// D6: Rate limiting (per IP, per API key)
const graphqlRateLimit = rateLimit({
  windowMs: 60 * 1000,  // 1 minute window
  max: 100,             // 100 requests per minute
  keyGenerator: (req) => {
    // Rate limit by API key if present, else by IP
    return req.headers['x-api-key']
      || req.ip;
  },
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    errors: [{
      message: 'Rate limit exceeded',
      extensions: { code: 'RATE_LIMITED' }
    }]
  }
});

app.use('/graphql', graphqlRateLimit, server.middleware());
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a complete defense-in-depth GraphQL security configuration implementing all seven defense layers: introspection disabled, complexity + depth limits, query timeout plugin, error sanitization with server-side logging, and rate limiting per API key or IP. (2) KEY MECHANISM: `validationRules` run synchronously before execution (zero DB cost for rejected queries); `plugins` (timeout) run during execution; `formatError` post-processes all errors before the response is sent; `rateLimit` middleware runs at the HTTP level before GraphQL parsing. (3) WHY IT MATTERS: each defense layer covers different attacks; removing any layer leaves a gap; complexity limits don't help against high-volume low-complexity attacks (rate limiting covers this); rate limiting doesn't help against one well-crafted expensive query (complexity limits cover this). (4) WHAT BREAKS: the timeout plugin using `setTimeout` in `willResolveField` fires on each field; if the total execution time exceeds 10 seconds, the FIRST field to trigger after 10 seconds throws; the error may be confusing if field resolution is nearly complete; use a global timeout rather than per-field timer in production. (5) TAKEAWAY: implement security controls in layers; no single control is sufficient; the combination of APQ + complexity limits + rate limiting + introspection disabled covers all five GraphQL attack classes.

```javascript
// D1: Automatic Persisted Queries (APQ)
// Strictest protection: only registered queries execute

// Client: Apollo Client with APQ
import { ApolloClient, from } from '@apollo/client';
import { createPersistedQueryLink } from
  '@apollo/client/link/persisted-queries';
import { sha256 } from 'crypto-hash';

const persistedQueriesLink =
  createPersistedQueryLink({ sha256 });

const client = new ApolloClient({
  link: from([
    persistedQueriesLink,
    httpLink
  ]),
  cache: new InMemoryCache()
});

// Flow:
// 1. First request: client sends hash only
//    { extensions: { persistedQuery: { sha256Hash } } }
// 2. Server: hash not found -> returns error
//    { errors: [{extensions: {code: 'PERSISTED_QUERY_NOT_FOUND'}}] }
// 3. Client: resends with full query + hash
// 4. Server: stores hash -> query mapping, executes
// 5. Subsequent requests: hash only (smaller payload)

// Server: register APQ handling in Apollo Server
// Apollo Server supports APQ built-in:
const server = new ApolloServer({
  typeDefs, resolvers,
  plugins: [
    ApolloServerPluginCacheControl(),
    // APQ is automatic with Apollo Server;
    // configure cache for hash storage:
    // KeyValueCache compatible (Redis, Memcached)
  ],
  // Block all non-persisted queries:
  // (strict APQ mode - only hash-registered queries)
  allowBatchedHttpRequests: false
});
// With a Redis cache: hashes persist across restarts
// Arbitrary non-registered queries return error
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Apollo Client's Automatic Persisted Queries setup and the server-side APQ flow - first request sends only the hash, server returns `PERSISTED_QUERY_NOT_FOUND`, client retries with full query, server stores and executes, subsequent requests use hash only. (2) KEY MECHANISM: APQ creates a server-side hash-to-query map; production clients only send hashes; attackers cannot construct valid queries because the server only executes pre-registered hashes; novel attacker-crafted queries return `PERSISTED_QUERY_NOT_FOUND`. (3) WHY IT MATTERS: APQ eliminates the arbitrary query attack surface - the most powerful GraphQL security control; it also reduces request payload size for frequently used queries (hash is 64 bytes vs query document which may be 1KB+). (4) WHAT BREAKS: APQ requires all valid client queries to be pre-registered; queries added in new frontend code must be deployed to the APQ cache before the frontend deploys; deployment coordination is required; a mismatch causes `PERSISTED_QUERY_NOT_FOUND` for all new queries. (5) TAKEAWAY: APQ requires build-pipeline integration; extract all GraphQL operations during the frontend build and register them with the schema registry; Apollo Studio automates this; use APQ for public production APIs; accept the operational overhead of query registration.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> GraphQL security differs from REST because one endpoint accepts variable queries.
> Key protections: (1) Disable introspection in production (`introspection: false`) to
> prevent schema discovery. (2) Add depth and complexity limits as validation rules to
> reject expensive queries before execution. (3) Rate limiting with `express-rate-limit`
> to prevent query volume attacks. (4) Use `formatError` to sanitize error messages
> and prevent internal details from reaching clients. These are the minimum baseline
> for any production GraphQL API.

---

**Senior / Staff (5+ years):**
> GraphQL's threat model requires defense in depth because the query language itself
> is the attack surface. Production baseline: introspection disabled, complexity limits,
> depth limits, query timeout, rate limiting (per API key, not just per IP to prevent
> shared-IP issues), field-level authorization on all sensitive data, `formatError` to
> sanitize errors. Strictest mode: Persisted Queries (APQ) - only pre-registered queries
> execute; novel queries are rejected at hash lookup; this eliminates all arbitrary query
> attacks at the cost of deployment coordination. APQ also provides performance benefits:
> smaller request payloads, query-level CDN caching. For public APIs, APQ is the
> production standard. For internal developer-facing APIs, complexity limits + introspection
> (in dev/staging) + rate limiting is the practical balance.

---

### ⚠️ Common Misconceptions

**Misconception: "Rate limiting GraphQL is the same as rate limiting REST APIs."**

REST rate limiting typically counts requests per endpoint (`/users` = 1 request unit).
GraphQL rate limiting by request count is insufficient because one GraphQL request can
be thousands of "REST request units" in cost. Rate limiting by request count: `{ users
{ creditCards { number } } }` (very expensive) counts the same as `{ me { name } }`
(cheap). More accurate approaches: (1) Rate limit by complexity score - each request's
computed complexity contributes to the rate limit bucket; expensive queries deplete the
bucket faster. (2) Rate limit by query cost - compute actual execution cost (number of
DB queries) and add to the rate limit bucket after execution. (3) Rate limit by field
count - count the total fields requested. The common production pattern: request-count
rate limiting (simple, prevents volume attacks) PLUS complexity limit (prevents expensive
individual queries). The two together cover both high-frequency cheap attacks and low-
frequency expensive attacks.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: APQ causes "PERSISTED_QUERY_NOT_FOUND" for new frontend deployments.**

Symptom: after deploying a new version of the frontend with new GraphQL queries,
clients receive `PERSISTED_QUERY_NOT_FOUND` errors; the application is broken.

Root cause: the new frontend sends APQ hashes for newly written queries; those hashes
are not in the server's APQ cache; the server rejects them.

```bash
# Diagnosis: check APQ cache hit rate
# Apollo Studio: Operations -> Query Cache
# Or: monitor server logs for PERSISTED_QUERY_NOT_FOUND

# Check if specific hash is in APQ cache:
redis-cli GET "apq:sha256:abc123def456..."
# (nil) = not in cache -> new query, will be populated
#         on first full-query request

# BAD: Frontend and APQ cache deployed out of order
# Frontend deployed at 14:00 (new queries, new hashes)
# APQ cache not pre-populated
# Users receive PERSISTED_QUERY_NOT_FOUND 14:00-14:05
# (until clients retry with full query, populating cache)

# GOOD: Pre-populate APQ cache before frontend deploy
# Step 1: extract all queries from new frontend build
# Step 2: register hashes with server-side APQ cache
# Step 3: deploy frontend (queries already in cache)

# Apollo Studio Rover CLI:
# rover persisted-queries publish --graph GRAPH_REF \
#   --manifest persisted-queries-manifest.json
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the APQ deployment race condition where a new frontend with new query hashes is deployed before those hashes are registered in the server's APQ cache, causing errors. (2) KEY MECHANISM: APQ clients send hashes first; if the hash is not in the cache, the server responds with `PERSISTED_QUERY_NOT_FOUND`; standard clients retry with the full query and the cache self-heals; but if strict APQ mode only allows registered hashes, the retry with full query is also rejected. (3) WHY IT MATTERS: if strict APQ mode is enabled (no full query fallback), the deployment order is critical; new frontend queries must be registered before the frontend deploys; wrong order = production outage for all new features. (4) WHAT BREAKS: automatic APQ (allowing full-query fallback) is self-healing but allows arbitrary queries; strict APQ (hash-only) requires pre-registration but is more secure; choose based on security requirements. (5) TAKEAWAY: integrate APQ hash extraction and registration into the frontend build pipeline (CI/CD); run `rover persisted-queries publish` as part of the deployment job before the frontend container is deployed; treat APQ cache registration as a deployment prerequisite.

Recovery: `apollo client:push --config apollo.config.js` to register all queries from
the frontend; or temporarily disable strict APQ to allow full-query fallback; client
will self-populate the cache within one request cycle.

---

### ⚖️ Comparison Table

| Control | Attack Prevented | Overhead | Strictness |
|---|---|---|---|
| Introspection disabled | Schema reconnaissance | None | Medium |
| Depth limiting | Deep recursive queries | Minimal | Low |
| Complexity scoring | Wide/alias/expensive queries | Low | Medium |
| Query timeout | Unbounded execution time | None | Low |
| Rate limiting (count) | Volume attacks | Low | Low |
| Rate limiting (complexity) | Cost-weighted volume attacks | Low | Medium |
| APQ (automatic) | Novel queries (with fallback) | Hash lookup | High |
| APQ (strict) | All novel queries | Hash lookup | Highest |
| Field-level auth | Data over-exposure | Per field | High |
| Error sanitization | Information disclosure | Minimal | Medium |

---

### 🏛️ System Design

**Production GraphQL API Security Architecture:**

```text
DEFENSE-IN-DEPTH SECURITY ARCHITECTURE:

Internet
  |
[CDN / WAF Layer]
  - HTTPS termination (TLS 1.2+)
  - IP-based rate limiting (WAF rules)
  - Geographic blocking (if applicable)
  - DDoS protection
  |
[Load Balancer]
  - SSL passthrough or re-encryption
  - Health checks
  |
[API Gateway or Ingress]
  - API key validation
  - Per-key rate limiting (request count)
  - JWT validation (optional at gateway)
  |
[GraphQL Server]
  BEFORE PARSING:
  - Body size limit (< 100KB per request)
  - Request rate limiter (express-rate-limit)
  
  PARSING:
  - JSON parse: malformed request = 400
  - GraphQL parse: syntax error = 400
  
  VALIDATION (before execution):
  - depthLimit(7): depth > 7 = reject
  - complexityLimit(1000): cost > 1000 = reject
  - APQ hash check: unknown hash = reject (strict)
  - Schema validation: unknown fields = reject
  
  EXECUTION:
  - Query timeout (10s)
  - Field-level authorization
  - DataLoader batching (not security, but DoS protection)
  
  POST-EXECUTION:
  - formatError: sanitize errors
  - Response size limit
  - Metrics / tracing

[Data Layer]
  - Parameterized queries (SQL injection prevention)
  - Row-level security (PostgreSQL RLS)
  - Audit logging
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the complete security architecture from internet request to data layer, showing all security controls in order of execution with each layer's specific responsibilities. (2) HOW TO READ IT: requests flow top-to-bottom; each layer is a security checkpoint; a request that passes all layers reaches data; a request stopped at any layer gets an appropriate error response. (3) KEY RELATIONSHIP: the layers are additive - CDN/WAF stops DDoS before it reaches the API server; APQ stops novel queries before validation runs; validation stops expensive queries before DB calls; field auth stops data exposure at the resolver level. (4) EDGE CASE: body size limit (100KB) before GraphQL parsing prevents parse-bomb attacks (deeply nested JSON that causes parser stack overflow); this is often forgotten because GraphQL schema validation protects against the query, but the JSON parser runs before schema validation. (5) INSIGHT: a senior engineer notes that the query timeout and DataLoader are last-resort backstops; APQ + complexity limits should catch all expensive queries before execution; if timeouts are frequently triggered in production, the complexity limit is set too high.

---

### 📊 Diagram

```text
GRAPHQL SECURITY DECISION FLOW:

  Request arrives
      |
  [WAF] -> DDoS? -> DROP
      |
  [Body size] -> > 100KB? -> 400
      |
  [Rate limiter] -> > limit? -> 429
      |
  [Parse JSON] -> malformed? -> 400
      |
  [Parse GraphQL] -> syntax error? -> 400
      |
  [APQ check] -> hash unknown? -> 404 (strict)
               or hash miss? -> fetch full query
      |
  [Depth limit] -> > 7? -> 400
      |
  [Complexity] -> > 1000? -> 400
      |
  [Execute with timeout]
      |
  [Field auth] -> unauthorized? -> null / FORBIDDEN
      |
  [Format errors] -> sanitize
      |
  Response

  COST: Each arrow = potentially 0ms overhead
  Validation rules run pre-execution (no DB)
  Total security overhead < 1ms for most paths
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the complete request flow through all GraphQL security checkpoints, showing that each check is performed before the next; a rejected request exits early. (2) HOW TO READ IT: each `->` is a check; the condition after `->` is the failure case; the number on the right is the HTTP response code returned on failure; a request reaching "Execute" has passed all pre-execution checks. (3) KEY RELATIONSHIP: checks are ordered from cheapest to most expensive - WAF (hardware), body size (byte count), rate limit (counter), parsing (CPU), validation (schema traversal), execution (DB + logic); early cheap checks protect expensive late checks. (4) EDGE CASE: APQ check can go two ways - strict mode (unknown hash = error) or auto mode (unknown hash = request full query, then execute); the diagram shows strict mode; auto mode has an additional loop. (5) INSIGHT: "Total security overhead < 1ms for most paths" is the key production reality; adding these security controls does not meaningfully impact performance because they all run before the expensive DB execution phase.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | GraphQL attack surface, introspection risk |
| Application | 3 | APQ setup, rate limiting, error sanitization |
| Security | 3 | threat model, defense-in-depth, APQ deployment |
| Debugging | 2 | security audit, APQ failures |
| Trade-off | 2 | APQ vs complexity limits, strict vs auto APQ |

---

**[JUNIOR] Q1 (Definition): Why is GraphQL introspection a security risk in production?**

Introspection allows any client to query the full schema: all types, fields, arguments,
directives, and their descriptions. An attacker with introspection access can:

1. Map the entire API surface: identify all mutations, all sensitive queries (`adminStats`,
   `deleteUser`, `updatePaymentMethod`), all input types, and all arguments.

2. Find deprecated fields: `@deprecated` fields often have looser validation (added
   before the security review improved); attackers look for deprecated fields as soft
   targets.

3. Discover private or internal-facing fields: a schema may have fields added for
   development that were never intended to be public (`debugInfo`, `internalAuditLog`);
   introspection reveals them.

4. Enable automated exploitation: security scanners and fuzzers can use introspection
   to automatically generate valid queries for every field; these run against the
   API to find unprotected fields or unexpected behavior.

Fix: `introspection: process.env.NODE_ENV !== 'production'`.

*What separates good from great:* The introspection disable is binary in Apollo Server.
For APIs that expose introspection to partners (external developers building clients),
introspection should be available for authenticated partners only. Implement a custom
validation rule that checks `context.user.hasRole('DEVELOPER_PARTNER')` before allowing
`__schema` queries. This enables partner developer tools while blocking public
reconnaissance.

---

**[JUNIOR] Q2 (Application): How does Automatic Persisted Queries (APQ) work and why is it secure?**

APQ reduces query payload size AND improves security:

Mechanism:
1. Client computes SHA-256 hash of the query document.
2. First request: client sends ONLY the hash.
3. Server: hash not found -> `PERSISTED_QUERY_NOT_FOUND` error.
4. Client: resends with full query body AND hash.
5. Server: caches `hash -> query`; executes query.
6. All subsequent requests: send hash only.

Security benefit: in strict APQ mode, the server ONLY executes pre-registered hashes.
An attacker cannot send a custom malicious query - the server does not have its hash.

```javascript
// Step 5: server registers hash automatically
// Next time attacker sends custom malicious query:
// hash = sha256("{ maliciousQuery { ... } }")
// Server: hash not found -> PERSISTED_QUERY_NOT_FOUND
// Attacker tries to register full query:
// Server (strict mode): rejects full query fallback
// -> Attacker cannot execute any non-registered query
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the APQ flow where an attacker's novel malicious query has a hash that is not in the server's registry; the server rejects it; the attacker cannot register new queries in strict mode. (2) KEY MECHANISM: strict APQ blocks the full-query fallback; an attacker cannot self-register queries by sending `{ query: "...", extensions: { persistedQuery: { sha256Hash: ... } } }` in one request; the server must have seen the hash via the official registration path. (3) WHY IT MATTERS: APQ converts GraphQL from a "submit any query" API to an "execute pre-approved queries" API; the query execution surface becomes finite and auditable. (4) WHAT BREAKS: strict APQ requires all client queries to be registered before deployment; a new query in the frontend code must be registered in the APQ cache before the client can use it; deployment coordination is mandatory. (5) TAKEAWAY: APQ is the gold standard for GraphQL security; use automatic APQ (with full-query fallback) for development and staging; use strict APQ for production public APIs; integrate hash registration into CI/CD.

---

**[SENIOR] Q3 (Security): How do you implement complexity-based rate limiting for GraphQL?**

Standard request-count rate limiting treats all GraphQL requests equally. More accurate:

```javascript
// Complexity-aware rate limiting:
// Each request costs its complexity score

const rateLimiter = new Map(); // userId -> {cost, reset}

const complexityRateLimitPlugin = {
  requestDidStart: () => ({
    executionDidStart: async ({
      request, document
    }) => {
      // Calculate complexity before execution
      const complexity = getComplexity({
        schema, query: document,
        estimators: [
          simpleEstimator({ defaultComplexity: 1 })
        ]
      });

      const userId = request.context.user?.id
        || request.context.clientIp;
      const now = Date.now();

      const bucket = rateLimiter.get(userId)
        || { cost: 0, reset: now + 60000 };

      // Reset if window expired
      if (now > bucket.reset) {
        bucket.cost = 0;
        bucket.reset = now + 60000;
      }

      // Check complexity budget (10,000 per minute)
      if (bucket.cost + complexity > 10000) {
        throw new GraphQLError('Complexity budget exceeded', {
          extensions: {
            code: 'COMPLEXITY_RATE_LIMITED',
            remainingBudget: 10000 - bucket.cost
          }
        });
      }

      bucket.cost += complexity;
      rateLimiter.set(userId, bucket);
    }
  })
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: complexity-based rate limiting where each request's complexity score depletes a per-user "complexity budget" instead of a simple request counter - a query with complexity 500 uses 500 budget units; 20 such queries exhaust the 10,000/minute budget. (2) KEY MECHANISM: `getComplexity()` calculates the score before execution; a Map stores per-user buckets with `{ cost, reset }`; the bucket resets after the time window; if `current_cost + new_complexity > budget`, the request is rejected. (3) WHY IT MATTERS: request-count limiting allows 100 requests × 1000 complexity = 100,000 effective complexity; complexity-based limiting caps total complexity at 10,000/minute regardless of how it is split across requests. (4) WHAT BREAKS: using an in-memory Map is single-instance only; use Redis for distributed rate limiting; `rateLimiter.set(userId, bucket)` must be atomic (Redis INCR with TTL) to prevent race conditions under concurrent requests. (5) TAKEAWAY: complexity-based rate limiting is more accurate than request-count for GraphQL; it prevents the "many cheap queries" and "one expensive query" attacks simultaneously; the budget number requires calibration from production complexity distribution data.

---

**[JUNIOR] Q4 (Application): What should the `formatError` function do for a production GraphQL API?**

`formatError` runs after every error before sending the response:

```javascript
// BAD: No formatError - raw errors reach clients
const server = new ApolloServer({
  typeDefs, resolvers
  // No formatError:
  // DB errors: "relation 'users' does not exist"
  // Stack traces: at Object.<anonymous> graphql.js:123
  // JWT hints: "invalid algorithm 'none'"
  // All exposed to ANY client in the response!
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: omitting `formatError` allows raw database, JWT, and framework error messages to reach clients. (2) KEY MECHANISM: Apollo Server's default error formatter includes `message` from the original error plus `extensions.exception.stacktrace` in development mode; in production mode, stack traces are omitted but `message` is still the raw error message. (3) WHY IT MATTERS: database error messages reveal schema structure; JWT errors reveal algorithm details; any raw error is an OWASP A05 Security Misconfiguration. (4) WHAT BREAKS: not overriding `formatError` is the mistake; Apollo Server does NOT automatically sanitize errors in production. (5) TAKEAWAY: always implement `formatError`; it is the last line of defense before errors reach clients.

```javascript
// GOOD: Production formatError
const formatError = (formattedError, err) => {
  // 1. Log full error server-side (with stack trace)
  logger.error({
    code: formattedError.extensions?.code,
    message: err.message,
    stack: err.stack,
    path: formattedError.path,
    operationName: err.locations
  });

  // 2. Pass through client-safe error codes
  const clientSafeCodes = [
    'UNAUTHENTICATED',    // 401 equivalent
    'FORBIDDEN',          // 403 equivalent
    'BAD_USER_INPUT',     // Validation errors
    'NOT_FOUND',          // Resource not found
    'COMPLEXITY_LIMIT',   // Client's query too complex
    'RATE_LIMITED'        // Rate limit exceeded
  ];

  const code = formattedError.extensions?.code;
  if (clientSafeCodes.includes(code)) {
    return formattedError; // Safe: pass through
  }

  // 3. Sanitize INTERNAL_SERVER_ERROR
  return {
    message: 'Internal server error',
    locations: formattedError.locations,
    path: formattedError.path,
    extensions: {
      code: 'INTERNAL_SERVER_ERROR'
      // Remove: originalError, stacktrace, extensions.exception
    }
  };
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a `formatError` function that logs full errors server-side (for debugging) while returning sanitized errors to clients - client-safe error codes pass through; internal server errors are replaced with a generic message. (2) KEY MECHANISM: `formattedError.extensions?.code` distinguishes client-safe errors (authentication, validation) from internal errors (database failures, bugs); client-safe errors have user-actionable messages; internal errors have no useful message for clients. (3) WHY IT MATTERS: database error messages like "relation 'payment_methods' does not exist" reach clients if not sanitized; this is an OWASP Top 10 A05 Security Misconfiguration. (4) WHAT BREAKS: Apollo Server's default `formattedError` includes `extensions.exception.stacktrace` in development; this is safe in development; `formatError` must explicitly remove it in production. (5) TAKEAWAY: implement `formatError` in every production GraphQL API; the function is the last line of defense against information disclosure; the `clientSafeCodes` allowlist prevents over-sanitizing errors that clients need.

---

**[SENIOR] Q5 (Security): How do you detect if a GraphQL API is vulnerable to abuse in the wild?**

Security audit checklist - execute these against the production API:

```graphql
# Test 1: Introspection enabled?
{ __schema { queryType { name } } }
# Expected: error (disabled in production)
# Vulnerable if: full schema returned

# Test 2: Depth limit working?
# (manually send deeply nested query)
# Expected: 400 "Exceeds maximum depth"

# Test 3: Alias amplification blocked?
# Expected: 400 "Exceeds complexity limit"
# (100 aliases of posts(first:100))

# Test 4: Error messages sanitized?
# Send invalid ID: { user(id: "INVALID_SQL') }
# Expected: generic error, no SQL details

# Test 5: APQ required?
# Send full query (not hash)
# Expected: PERSISTED_QUERY_NOT_FOUND (strict APQ)
# or: success (no APQ) -> vulnerability
```

> **Code walkthrough:** (1) WHAT IT SHOWS: five security probe queries that test specific GraphQL vulnerabilities - an automated security audit checklist. (2) KEY MECHANISM: each probe tests one specific control; passing = control is in place; failing = vulnerability confirmed; the probes are simple and fast (no authentication needed for most). (3) WHY IT MATTERS: security controls are often added but never verified; a complexity limit added to the schema may be broken by a library update; probes run as part of CI/CD verify controls remain effective after every deployment. (4) WHAT BREAKS: automated security probes require a staging environment that mirrors production; running them against production risks rate limiting or alerting security systems. (5) TAKEAWAY: add these probes as automated integration tests that run in the CI/CD pipeline against staging; failing probes block deployment; treat security controls like functional tests - they must be verified continuously.

---

**[SENIOR] Q6 (Trade-off): What are the trade-offs between strict APQ and complexity limiting?**

Strict APQ:
- Protection: highest (only pre-registered queries execute; no novel queries possible).
- Operational cost: high (build pipeline must extract and register queries; deployment
  coordination required between frontend and backend; any new query requires registration).
- Flexibility: low (ad-hoc queries from API explorers, internal tools, or GraphiQL blocked).
- Best for: public production APIs with a controlled client (single SPA or mobile app).

Complexity limiting:
- Protection: medium (blocks expensive queries; does not block reconnaissance or schema
  enumeration; crafty attacker can stay under threshold).
- Operational cost: low (one-time configuration; no deployment coordination).
- Flexibility: high (any valid query under the threshold executes; internal tools work).
- Best for: internal APIs, developer-facing APIs, APIs with multiple unknown clients.

The combination: use both. APQ for public production API (client queries are known and
finite). Complexity limits as the fallback safety net for when APQ cache is warming up
(first deployment), for authenticated internal tools, or for partner APIs where APQ
registration is impractical.

*What separates good from great:* The multi-tiered client model. Public API (unauthenticated
clients): strict APQ + complexity limits + introspection disabled + rate limiting. Partner
API (authenticated partners with API keys): automatic APQ (no full-query fallback block)
+ complexity limits + introspection enabled. Internal admin API (authenticated staff):
no APQ + complexity limits + introspection enabled + audit logging. Different security
postures for different trust levels, implemented as separate GraphQL endpoints or middleware
rules keyed on `context.clientType`.

---

**[JUNIOR] Q7 (Application): How do you implement request body size limiting for GraphQL?**

GraphQL query documents can be arbitrarily large. A malicious client can send megabytes
of query text to cause parser memory exhaustion.

```javascript
// BAD: No body size limit (parse-bomb vulnerability)
const app = express();
app.use(express.json()); // Accepts unlimited size!
// Attacker sends 100MB JSON query:
// { "query": "{ " + "a { ".repeat(1000000) + "} " }
// Node.js allocates 100MB buffer to parse it
// Parser runs; OOM kill possible on small instances
app.use('/graphql', server.middleware());
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `express.json()` with no limit accepts arbitrarily large request bodies, enabling memory-exhaustion attacks via large JSON payloads. (2) KEY MECHANISM: Node.js `http` module buffers the entire request body before `express.json()` parses it; a 100MB body allocates 100MB of heap; under concurrent large requests, the heap is exhausted. (3) WHY IT MATTERS: GraphQL parsers are recursive; deeply nested valid JSON causes parser stack overflow independent of the body size limit; body size is the first line of defense. (4) WHAT BREAKS: setting the limit too low (1KB) breaks legitimate GraphQL queries with large variable payloads (e.g., bulk input arrays); 100KB is sufficient for almost all legitimate queries. (5) TAKEAWAY: set `express.json({ limit: '100kb' })` and never use the default unlimited `express.json()`.

```javascript
// GOOD: Body size limit before GraphQL parsing
const express = require('express');
const app = express();

// Limit JSON body size to 100KB
// (default is 100KB in express; make explicit)
app.use(express.json({
  limit: '100kb',   // Bytes, KB, or MB
  strict: true,     // Only accept arrays and objects
  type: 'application/json'
}));
// Any request body > 100KB returns 413 immediately
// GraphQL parser NEVER runs on oversized requests

app.use('/graphql', server.middleware());

// For file uploads (multipart):
const upload = multer({
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max
    files: 1                    // Max 1 file
  }
});
// Without limits: a client uploads a 1GB file
// -> Node.js buffers it in memory
// -> OOM kill on small instances
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `express.json({ limit: '100kb' })` limiting request body size before GraphQL parsing, with additional `multer` limits for file uploads. (2) KEY MECHANISM: `express.json` parses the request body; the `limit` option checks the `Content-Length` header and rejects requests exceeding the limit with HTTP 413 (Payload Too Large) before allocating a buffer; the GraphQL parser never runs. (3) WHY IT MATTERS: without a body size limit, a 100MB query document is parsed by the GraphQL parser; deeply nested invalid queries can cause parser stack overflow; 100KB is generous for legitimate GraphQL queries. (4) WHAT BREAKS: the `100kb` limit applies to the BODY before JSON parsing; a 100KB JSON query document is valid; most production GraphQL queries are 1-5KB; set 100KB as the ceiling with headroom. (5) TAKEAWAY: add `express.json({ limit: '100kb' })` before the GraphQL handler; this is a single-line, zero-cost security control that prevents body-size-based attacks; it is often forgotten in the GraphQL security checklist.

---

**[SENIOR] Q8 (Security): How do you prevent GraphQL injection vulnerabilities?**

GraphQL variables are the primary injection prevention mechanism. When variables are
used correctly, user input is typed and parameterized:

```javascript
// BAD: String interpolation -> SQL injection possible
const resolvers = {
  Query: {
    userByName: async (_, { name }, { db }) => {
      // BAD: name directly in SQL string
      return db.query(
        `SELECT * FROM users WHERE name = '${name}'`
      );
      // Input: name = "'; DROP TABLE users; --"
      // Query: WHERE name = ''; DROP TABLE users; --'
      // SQL injection!
    }
  }
};

// GOOD: Parameterized query
// BAD: (see above - string interpolation)
const resolvers = {
  Query: {
    userByName: async (_, { name }, { db }) => {
      // GOOD: name as parameterized placeholder
      return db.query(
        'SELECT * FROM users WHERE name = $1',
        [name]
        // PostgreSQL driver: $1 is parameterized
        // Driver escapes the value properly
        // SQL injection impossible
      );
    }
  }
};

// GraphQL types also enforce basic validation:
const typeDefs = `
  type Query {
    user(id: ID!): User  # ID type: must match ID format
    users(
      first: Int         # Int type: must be integer
    ): [User!]!
  }
`;
// Input: { id: "'; DROP TABLE users; --" }
// GraphQL validates: ID type is a string; accepts it
// BUT parameterized query prevents injection anyway
// -> Use parameterized queries even with typed inputs
// GraphQL types reduce but don't eliminate injection
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the contrast between string-interpolated SQL (vulnerable to injection) and parameterized queries (injection-safe), demonstrating that GraphQL's type system helps but does not replace parameterized queries. (2) KEY MECHANISM: GraphQL `ID!` type accepts any string; a malicious string `"'; DROP TABLE--"` passes type validation; only the database driver's parameterized query (`$1`) escaping prevents injection. (3) WHY IT MATTERS: SQL injection is OWASP #1; many GraphQL tutorials show `db.query(\`SELECT WHERE id = '${id}'\`)` which is vulnerable; parameterized queries (`db.query('SELECT WHERE id = $1', [id])`) are the correct pattern. (4) WHAT BREAKS: ORMs like Prisma, Sequelize, and TypeORM use parameterized queries internally; direct SQL via `pg` or `mysql2` requires explicit parameterization; check all raw query sites. (5) TAKEAWAY: ALWAYS use parameterized queries in GraphQL resolvers; never use string template literals with user-supplied values in SQL; GraphQL type validation is insufficient for SQL injection prevention.

---

**[JUNIOR] Q9 (Application): How do you configure a query timeout for GraphQL?**

Query timeouts prevent long-running queries from holding server resources:

```javascript
// Query timeout via AbortController (Node.js 18+)
const server = new ApolloServer({
  typeDefs,
  resolvers,
  plugins: [{
    requestDidStart: () => ({
      executionDidStart: async ({ request }) => {
        const controller = new AbortController();

        // Abort execution after 10 seconds
        const timeout = setTimeout(() => {
          controller.abort(
            new GraphQLError('Query timeout exceeded', {
              extensions: { code: 'TIMEOUT' }
            })
          );
        }, 10000);

        // Add signal to context for resolvers
        request.context.abortSignal =
          controller.signal;

        return {
          executionDidEnd: () => {
            clearTimeout(timeout);
          }
        };
      }
    })
  }]
});

// Resolver checks abort signal:
const resolvers = {
  Query: {
    heavyReport: async (_, args, { abortSignal }) => {
      return db.query(
        'SELECT ... FROM large_table ...',
        { signal: abortSignal }
        // Pass signal to database driver
        // Driver cancels query on abort
      );
    }
  }
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: query timeout using `AbortController` in an Apollo Server plugin, with the abort signal passed to database drivers to cancel running queries when the timeout fires. (2) KEY MECHANISM: `setTimeout(10000)` creates a timer; if execution has not completed, `controller.abort()` fires; the `abortSignal` passed to the database driver causes the running database query to be cancelled (PostgreSQL: `pg_cancel_backend`); the resolver receives an abort error. (3) WHY IT MATTERS: without canceling the database query on timeout, the server stops waiting for the result but the database continues the expensive query; server resources are released but database resources are not; cancel at both layers. (4) WHAT BREAKS: `AbortController` signals are supported by Node.js `fetch` and many database drivers natively; `pg` (node-postgres) supports `signal` option; `mysql2` uses a different cancellation mechanism; verify your driver's abort/cancel mechanism. (5) TAKEAWAY: query timeout requires two parts: (1) server-side timeout that stops waiting, and (2) database-side cancellation that stops the query; only implementing (1) wastes database resources; always pass the abort signal to the database driver.

---

**[SENIOR] Q10 (Security): How do you audit a GraphQL API for the OWASP API Security Top 10?**

OWASP API Security Top 10 mapped to GraphQL:

**API1 (Broken Object-Level Authorization):** GraphQL field resolvers that do not check
if the requesting user owns the parent object. Check: `Post.author` resolver - does it
return the author for any post, or only posts the user has access to?

**API2 (Broken Authentication):** JWT not validated in context function; tokens not
expire-checked; subscriptions missing auth context.

**API3 (Excessive Data Exposure):** Field resolvers that return full database rows
including sensitive fields (`password_hash`, `ssn`) that are not needed by the client.
Check: do User type fields include fields that should be excluded?

**API4 (Lack of Resource & Rate Limiting):** No complexity limits, no rate limiting,
no body size limit.

**API5 (Broken Function-Level Authorization):** Admin mutations accessible without
admin role check. Check: `deleteUser`, `adminStats`, `updateConfig` resolvers.

**API7 (Security Misconfiguration):** Introspection enabled in production; stack traces
in error responses; `playground` endpoint in production.

**API8 (Injection):** String-interpolated SQL in resolvers. Check all `db.query()`
calls for template literals with user input.

```bash
# Automated security scan:
npm install -g @escape.tech/graphql-armor-cli
graphql-armor scan https://api.example.com/graphql
# Reports: introspection status, depth limits,
# complexity, CSRF protection, schema audit
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using `@escape.tech/graphql-armor-cli` to automate GraphQL security scanning - the tool tests introspection, depth limits, complexity, and other controls. (2) KEY MECHANISM: the scanner sends probe requests to the GraphQL endpoint (including introspection queries, deeply nested queries, alias bombs) and reports which controls are in place; it does not require source code access. (3) WHY IT MATTERS: security controls can break silently (library update changes behavior, configuration changed during deployment); automated scanning in CI/CD detects regressions before attackers do. (4) WHAT BREAKS: security scanners may trigger rate limits or alerting rules; configure the scanner to use a test API key or a separate security-test subnet; coordinate with the security team before running. (5) TAKEAWAY: add `graphql-armor scan` to the CI/CD pipeline against a staging environment; block deployment if high-severity findings appear; run quarterly against production to detect configuration drift.

---

**[SENIOR] Q11 (Trade-off): What is the performance cost of GraphQL security controls?**

Each control has a specific overhead profile:

| Control | When It Runs | Overhead |
|---|---|---|
| Body size limit | Before JSON parse | ~0ms (header check) |
| JSON parse | Before GraphQL | Unavoidable (~1ms) |
| Depth limit | After GraphQL parse | ~0.1ms (tree traversal) |
| Complexity calc | After GraphQL parse | ~1ms (schema traversal) |
| APQ hash lookup | After parse | ~0.5ms (Redis HGET) |
| Rate limiter | HTTP level | ~0.5ms (Redis INCR) |
| formatError | After execution | ~0.1ms (object copy) |

Total security overhead for a typical request: 2-3ms. For a GraphQL request that takes
100ms (including DB queries), security overhead is 2-3%. For a request that takes 5ms
(simple query), security overhead is 40-60%. For high-frequency, simple queries: the
security overhead dominates.

Optimization: for known-safe queries (internal service calls, trusted API keys), use
a bypass middleware that skips complexity calculation and APQ lookup. Route internal
traffic through a separate GraphQL endpoint with reduced security controls.

*What separates good from great:* Per-endpoint security tiering. Three endpoint tiers:
(1) `/graphql/public` - all controls, strict APQ. (2) `/graphql/partner` - API key auth,
complexity limits, no APQ. (3) `/graphql/internal` - mTLS auth, no complexity limits,
no APQ. This gives each client class the appropriate security posture without imposing
the overhead of the strictest tier on all clients.

---

**[JUNIOR] Q12 (Application): How do you enable CSRF protection for GraphQL?**

GraphQL over HTTP POST is vulnerable to CSRF if cookies are used for authentication.
A malicious site can POST to `https://api.example.com/graphql` using the victim's
session cookie.

Mitigations:

1. Use Authorization header (not cookies): JWTs in `Authorization: Bearer ...` header
   cannot be sent by malicious CSRF forms; CSRF does not apply to custom headers.

2. CORS: configure `origin` to only allow your domain:
```javascript
app.use(cors({
  origin: 'https://app.example.com',
  credentials: true,
  // Blocks requests from other origins
}));
```

> **Code walkthrough:** (1) WHAT IT SHOWS: CORS configuration as the primary CSRF defense for GraphQL APIs - allowing requests only from the known frontend origin prevents cross-site form POSTs. (2) KEY MECHANISM: CORS preflight checks the `Origin` header; requests from unauthorized origins receive a CORS error before reaching the GraphQL handler; cookies are irrelevant if the request never reaches the server. (3) WHY IT MATTERS: GraphQL CSRF is a real vulnerability if cookie-based authentication is used; a malicious form `<form action="https://api.example.com/graphql" method="POST">` POSTs to the API; the browser includes the user's session cookie; CORS prevents this cross-origin form submission. (4) WHAT BREAKS: CORS allows the browser to decide; server-side code should not rely solely on CORS; add a CSRF token check as a defense-in-depth measure for cookie-authenticated GraphQL. (5) TAKEAWAY: prefer JWT Bearer tokens over cookies for GraphQL APIs; Authorization header tokens are immune to CSRF; if cookies are required, implement both CORS and CSRF token validation.
