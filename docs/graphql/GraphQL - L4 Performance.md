---
layout: default
title: "GraphQL - L4 Performance"
parent: "GraphQL"
nav_order: 10
permalink: /graphql/l4-performance/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 21 | [Persisted Queries and APQ](#persisted-queries-and-apq) | ★★★ |

---

# Persisted Queries and APQ

---

### 🎯 Model Answer

**30 seconds:**
> Persisted Queries store pre-registered GraphQL query documents on the server by
> SHA-256 hash. Clients send only the hash (64 bytes) instead of the full query
> text (often 500B-5KB). This reduces network payload, enables GET requests
> (cacheable by CDN), and eliminates the arbitrary-query attack surface. APQ
> (Automatic Persisted Queries) is the self-registering variant: first request
> sends hash only; on cache miss, client retries with full query; server stores
> the mapping. Strictly used APQ (hash-only, no fallback) requires build-pipeline
> query registration but provides the strongest security guarantee.

**3 minutes (Senior):**
> APQ sits at the intersection of performance and security. Performance benefits:
> (1) Reduced payload - hashes are 64 bytes; queries are 500B-5KB; bandwidth savings
> are significant for mobile clients and global APIs. (2) GET requests - pre-registered
> queries can be served via HTTP GET instead of POST; CDN edge caches can cache GET
> responses by hash; cache hit rate approaches 100% for popular queries. (3) Parsing
> optimization - the server can cache the parsed query AST for registered hashes;
> parsing is avoided for every subsequent request with the same hash. Security benefits:
> (4) Attack surface reduction - strict APQ means only pre-registered queries execute;
> novel attacker-crafted queries are rejected at hash lookup; the server never executes
> unknown query documents. Operational trade-off: (5) Deployment coordination - all
> client queries must be registered before the client deploys; CI/CD must include a
> query extraction and registration step; a missing registration causes production errors.
> The Apollo Studio workflow: build pipeline runs `graphql-codegen`, extracts all
> operation documents, computes hashes, and publishes them to the schema registry;
> the schema registry serves as the APQ hash store for production servers.

**Blank Mind Recovery:**

**(1) Restate:** "APQ: hash-to-query map on server. Clients send SHA-256 hash instead of
query text. Miss -> server asks for full query -> stores -> executes. GET requests
possible -> CDN cacheable. Strict mode: no full-query fallback -> only pre-registered
queries. Build pipeline integration: extract + register hashes before frontend deploy.
Security: novel queries rejected. Performance: payload shrinks 10-100x."

---

### 📘 Concept Explanation

**APQ Protocol and Architecture:**

```text
AUTOMATIC PERSISTED QUERIES FLOW:

FIRST REQUEST (cache miss):
Client              Server
  |                   |
  |--extensions------>|
  |  {persistedQuery: |
  |   {sha256Hash:    |
  |    "abc123..."}}  |
  |  (NO query body)  |
  |                   |-> Hash lookup: MISS
  |<--error-----------| (PERSISTED_QUERY_NOT_FOUND)
  |                   |
  |--query + ext----->|
  |  {query: "...",   |
  |   extensions: {   |
  |    sha256Hash:    |
  |    "abc123..."}}  |
  |                   |-> Hash lookup: MISS
  |                   |-> Store: "abc123" -> "query..."
  |                   |-> Execute query
  |<--result----------| (data returned)

SUBSEQUENT REQUESTS (cache hit):
  |--extensions------>|
  |  {sha256Hash:     |
  |   "abc123..."}    |
  |  (64 byte payload)|
  |                   |-> Hash lookup: HIT
  |                   |-> Execute cached query
  |<--result----------| (data returned)

GET REQUEST (CDN-cacheable):
GET /graphql?extensions={"persistedQuery":
  {"version":1,"sha256Hash":"abc123..."}}
  |-> CDN: cache HIT? -> serve from edge
  |-> CDN: cache MISS -> forward to server
  |-> Server: execute + CDN caches response
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the three APQ flow variations - first request (two round-trips to warm the cache), subsequent requests (hash-only single round-trip), and CDN-cacheable GET requests (CDN-served after first request). (2) HOW TO READ IT: the Client-Server swim lanes show what each party sends and does; the `->` annotations show server-side operations; `MISS` and `HIT` show cache state. (3) KEY RELATIONSHIP: the first request always takes two round-trips (miss + full query); all subsequent requests with the same operation use one round-trip; the two-round-trip cost is amortized over many requests. (4) EDGE CASE: if the client computes the wrong hash (different from what the server stores), every request becomes a cache miss; hash computation must be consistent - `sha256` of the exact query string including whitespace. (5) INSIGHT: a senior engineer adds query normalization before hashing (remove comments, normalize whitespace) to ensure identical queries with different formatting produce the same hash; this maximizes cache hit rate.

---

### 💻 Code Example

```javascript
// BAD: GraphQL without APQ (full query every request)
// Every request carries the full query document

// 1. Request payload size:
// {"query":"query GetUserProfile($id:ID!) {
//   user(id:$id) { id name email bio
//     profilePhoto { url alt }
//     recentPosts(first:5) { id title createdAt }
//     followersCount followingCount
//     settings { notifications theme language }
//   }
// }","variables":{"id":"123"}}
// Size: ~500 bytes - sent on EVERY request

// 2. HTTP POST only: not CDN-cacheable
// POST /graphql -> Must reach origin server
// No CDN caching for POST requests

// 3. No AST caching: parsed on every request
// Even identical queries are re-parsed

// 4. Attack surface: any query can be submitted
// No restriction on what queries the server executes
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the four performance and security costs of not using APQ - repeated full query payloads, no CDN cacheability, repeated AST parsing, and open query execution surface. (2) KEY MECHANISM: each HTTP POST to `/graphql` carries the full query text; CDN cannot cache POST responses because POST is not idempotent in HTTP semantics; the GraphQL server parses the query document on every request even if it has parsed the same document millions of times. (3) WHY IT MATTERS: for a mobile app with 1 million daily active users making 5 queries each = 5 million requests × 500 bytes = 2.5GB query text bandwidth per day; APQ reduces this to 5M × 64 bytes = 320MB (87% reduction). (4) WHAT BREAKS: without CDN caching, all GraphQL queries reach the origin server; during traffic spikes (product launch, news event), the origin server handles 100% of traffic; with APQ GET + CDN, popular queries are served from edge. (5) TAKEAWAY: APQ is not just a security feature; it is a significant bandwidth and infrastructure cost optimization for high-traffic GraphQL APIs.

```javascript
// GOOD: Apollo Client with APQ enabled

import { ApolloClient, InMemoryCache, from } from '@apollo/client';
import { HttpLink } from '@apollo/client/link/http';
import {
  createPersistedQueryLink
} from '@apollo/client/link/persisted-queries';
import { sha256 } from 'crypto-hash';

// Create APQ link (hash computation)
const persistedQueriesLink = createPersistedQueryLink({
  sha256,
  // useGETForHashedQueries: serve registered queries
  // as HTTP GET requests (CDN-cacheable)
  useGETForHashedQueries: true
});

const httpLink = new HttpLink({
  uri: 'https://api.example.com/graphql'
});

const client = new ApolloClient({
  cache: new InMemoryCache(),
  link: from([
    persistedQueriesLink,
    httpLink
  ])
});

// What happens at runtime:
// useQuery(GET_USER_PROFILE, { variables: { id: '123' } })
// 1st call: hash sent first -> MISS -> full query sent
// 2nd call: hash only -> HIT -> result returned
// All calls via GET if useGETForHashedQueries: true
// CDN caches: GET /graphql?extensions=...sha256Hash...
// Result: 90%+ CDN hit rate for popular queries
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Apollo Client APQ configuration with `createPersistedQueryLink`, SHA-256 hash computation, and `useGETForHashedQueries: true` to enable CDN caching of registered queries. (2) KEY MECHANISM: `createPersistedQueryLink` wraps the HTTP link; it intercepts all outgoing requests; computes the SHA-256 hash of the query; sends hash-only first; handles the `PERSISTED_QUERY_NOT_FOUND` error by retrying with the full query; subsequent requests use hash-only GET. (3) WHY IT MATTERS: `useGETForHashedQueries: true` converts all cache-hit query requests to HTTP GET; CDNs (CloudFront, Fastly, Akamai) cache GET responses by URL; the CDN cache key is the URL including the hash parameter; popular queries achieve 90%+ CDN hit rates. (4) WHAT BREAKS: `useGETForHashedQueries` makes requests cacheable, but it also caches query results for ALL users; queries returning user-specific data must NOT use GET (or must include the user ID in the cache key via `Vary` header); use GET only for public/non-personalized queries. (5) TAKEAWAY: `createPersistedQueryLink` is one import; `useGETForHashedQueries: true` is one option; these two additions enable CDN caching and reduce bandwidth; the impact is immediate on high-traffic APIs.

```javascript
// ADVANCED: Server-side APQ with custom cache
// Pre-register queries from build pipeline

const {
  ApolloServer
} = require('@apollo/server');
const {
  KeyvAdapter
} = require('@apollo/utils.keyvadapter');
const Keyv = require('keyv');
const { sha256 } = require('crypto-hash');

// BAD: Default in-memory APQ cache
// const server = new ApolloServer({ typeDefs, resolvers });
// APQ hash store: in-memory LRU, 30MB limit
// Problem: cleared on EVERY server restart
// Rolling deployments: each new pod = cold APQ cache
// All clients experience two-round-trip miss period

// GOOD: Redis-backed APQ cache for production
// (persists across server restarts)
const keyv = new Keyv('redis://redis:6379', {
  ttl: 30 * 24 * 60 * 60 * 1000 // 30 days TTL
});
const cache = new KeyvAdapter(keyv);

const server = new ApolloServer({
  typeDefs,
  resolvers,
  cache,  // APQ hashes stored in Redis
  // Default cache: in-memory (lost on restart)
  // Redis: survives restarts, shared across instances
});

// PRE-REGISTRATION: Add to CI/CD pipeline
// (Run BEFORE deploying new frontend)
// extract-operations.js:
const {
  extractOperations
} = require('./extract-operations');

async function registerQueries() {
  const operations = await extractOperations(
    'src/**/*.graphql'
  );

  for (const op of operations) {
    const hash = await sha256(op.body);
    // Register in Redis APQ cache:
    await cache.set(`apq:sha256:${hash}`, op.body, {
      ttl: 30 * 24 * 60 * 60 * 1000
    });
    console.log(`Registered: ${op.name} (${hash})`);
  }
}
// Run: node extract-operations.js
// Output: "Registered: GetUserProfile (abc123...)"
// Now: client sends hash -> immediate HIT, no fallback
```

> **Code walkthrough:** (1) WHAT IT SHOWS: production APQ setup with Redis-backed cache for hash persistence across server restarts, plus a pre-registration script that populates the cache from the frontend build before deployment. (2) KEY MECHANISM: `KeyvAdapter(keyv)` adapts any key-value store to Apollo's cache interface; `cache` in `ApolloServer` options is used for both APQ hash storage and response caching; Redis ensures hashes survive server restarts and are shared across all server instances. (3) WHY IT MATTERS: in-memory APQ cache (default) is per-instance and lost on restart; if a server restarts while clients are running, all hashes are lost and every client request degrades to a two-round-trip miss; Redis APQ cache survives restarts with zero client impact. (4) WHAT BREAKS: the `apq:sha256:${hash}` key prefix must match Apollo Server's internal APQ key format; using the wrong prefix causes hash lookups to always miss; verify by checking the actual Redis keys Apollo Server writes. (5) TAKEAWAY: three APQ production requirements: (1) Redis-backed cache (not in-memory), (2) pre-registration in CI/CD, (3) `useGETForHashedQueries: true` in the client; missing any one reduces the effectiveness of APQ for performance.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-3 years):**
> Persisted Queries store GraphQL query documents on the server by hash. Clients send
> the hash instead of the full query text, reducing request payload by 10-100x. APQ is
> the automatic version: client sends hash; if server doesn't have it, client resends
> full query; server stores the mapping. Benefits: smaller payloads for mobile clients,
> CDN caching possible via GET requests, reduced server parsing overhead. Enable with
> `createPersistedQueryLink` on Apollo Client and Redis-backed cache on Apollo Server.

---

**Senior / Staff (5+ years):**
> APQ combines performance and security. Performance: (1) payload reduction (hash vs
> full query), (2) CDN caching via GET requests (near-infinite scaling for read-heavy
> queries), (3) AST parse caching on the server. Security: (4) strict APQ eliminates
> the arbitrary query attack surface. Production requirements: (1) Redis APQ cache
> (not in-memory); (2) pre-registration in CI/CD to avoid cache miss on first request
> after deployment; (3) `useGETForHashedQueries: true` for CDN caching; (4) separate
> cache TTL management (30-day TTL for registered queries, 1-day for auto-registered).
> Key operational decision: strict APQ (no full-query fallback) vs automatic APQ (with
> fallback). Strict = maximum security, requires deployment coordination. Automatic = self-
> healing, lower security (attackers can register queries by submitting them once).

---

### ⚠️ Common Misconceptions

**Misconception: "APQ caches query RESULTS; it is like response caching."**

APQ caches the query DOCUMENT mapping (hash -> query text). It does NOT cache the query
RESULTS. Two separate caching layers:

1. APQ hash cache: maps `sha256(query) -> query string`. Cached permanently (or with
   30-day TTL). Purpose: avoid sending the full query text on every request.

2. Response cache (Apollo full response caching): caches `{query + variables + user} ->
   result`. Cached with TTL per type/field. Purpose: avoid executing resolvers and DB
   queries for frequent identical requests.

APQ benefit: bandwidth reduction and CDN cacheability.
Response caching benefit: reduced server CPU and database load.

They are complementary, not alternatives. A production GraphQL API uses both: APQ for
all queries (bandwidth + CDN) and response caching for stable, infrequently-changing
queries (`PostList`, `ProductCatalog`). APQ hash misses (cache miss on the hash) must
still execute the full query against resolvers and databases; only response caching
avoids that execution.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: APQ causes PERSISTED_QUERY_NOT_FOUND after server restart.**

Symptom: after a server restart, all clients experience two round-trips for every query
request (cache miss + full query). The client metrics show doubled request latency for
approximately 1 minute after restart.

Root cause: in-memory APQ cache cleared on restart; all hash mappings are lost.

```bash
# Diagnosis:
# Monitor Apollo Server metrics for APQ cache hit rate
# In Apollo Studio: Operations -> Cache Metrics
# Or in Prometheus:
# apollo_server_cache_hits_total{operation="apq"} / total

# Verify APQ cache backend:
# Is cache configured in Apollo Server options?
const server = new ApolloServer({
  cache, // <- If this is absent or in-memory, PROBLEM
});

# Check: is the cache Redis-backed?
redis-cli keys "apq:*" | wc -l
# 0 = no APQ entries in Redis (using in-memory)
# > 0 = Redis-backed APQ (expected)

# Fix: switch to Redis-backed cache
const server = new ApolloServer({
  cache: new KeyvAdapter(
    new Keyv('redis://redis:6379')
  )
});
# After fix: server restart = zero APQ cache misses
# (Redis persists hashes; clients see no disruption)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: diagnosing APQ cache misses after restart using Redis CLI to verify whether APQ hashes are being persisted. (2) KEY MECHANISM: `redis-cli keys "apq:*" | wc -l` counts APQ entries in Redis; zero entries confirm the server is using in-memory cache (not Redis); entries confirm Redis-backed APQ. (3) WHY IT MATTERS: during deployment rollouts with rolling restarts, each new server instance starts with an empty APQ cache; without Redis-backed APQ, every deployment causes a brief period of double-round-trip requests for all clients; with Redis, new instances immediately serve hash lookups. (4) WHAT BREAKS: the `KeyvAdapter` import path differs between Apollo Server versions; verify the import is from `@apollo/utils.keyvadapter` (Apollo Server 4) not an older path. (5) TAKEAWAY: always use Redis-backed APQ cache; the `new Keyv('redis://redis:6379')` setup is a one-line change; the operational benefit (zero APQ cache misses on restart) is immediate.

---

### ⚖️ Comparison Table

| Strategy | Payload | CDN Cache | Security | Operational Cost |
|---|---|---|---|---|
| No APQ (full query POST) | Full (500B-5KB) | No (POST) | Low | None |
| Auto APQ (with fallback) | Hash (64B) after first | Yes (GET) | Medium | Low |
| Strict APQ (no fallback) | Hash (64B) always | Yes (GET) | Highest | High (CI/CD) |
| Manual Persisted Queries | Hash (64B) always | Yes (GET) | Highest | Highest |
| APQ + Response Cache | Hash + cached result | Full CDN | Highest | High |

---

### 🏛️ System Design

**APQ in a Production CDN Architecture:**

```text
APQ + CDN ARCHITECTURE:

Mobile Client
  |
  | Request 1 (cold start, first ever):
  | POST /graphql
  | Body: { query: "...", extensions: {sha256: "abc"} }
  |
[CDN Edge]
  | POST not cached -> forward to origin
  |
[Origin Server]
  | hash "abc" not found in Redis APQ cache
  | store: Redis SET apq:sha256:abc "query text"
  | execute query -> result
  | return result + Cache-Control: max-age=60
  |
[CDN]
  | POST not cached by CDN
  |
Mobile Client receives result

  | Request 2 (same operation, APQ warmed):
  | GET /graphql?extensions={"persistedQuery":{
  |   "version":1,"sha256Hash":"abc123..."}}
  |
[CDN Edge]
  | GET MISS (first GET request)
  | forward to origin
  |
[Origin Server]
  | hash "abc" FOUND in Redis APQ cache
  | execute query -> result
  | return result + Cache-Control: max-age=60
  |
[CDN]
  | Cache GET response by URL + hash
  |
  | Request 3 (same operation, CDN hit):
  | GET /graphql?...sha256Hash=abc123...
  |
[CDN Edge]
  | GET HIT -> serve from CDN cache
  | 0ms origin server load!
  | CDN handles 1,000,000 req/s with no origin cost
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the three-request lifecycle of APQ + CDN - first POST (APQ cache miss, origin execution), first GET (CDN miss, APQ cache hit), and subsequent GETs (CDN hit, zero origin load). (2) HOW TO READ IT: the vertical flow shows the request path; `->` annotations show forwarding decisions; each request lifecycle shows where processing stops (CDN edge vs origin). (3) KEY RELATIONSHIP: APQ GET requests are CDN-cacheable because GET + hash = stable URL; the CDN caches the response by URL; subsequent identical requests never reach the origin server. (4) EDGE CASE: CDN caching with `Cache-Control: max-age=60` means query results are 60 seconds stale; for user-specific data, caching is inappropriate; use `Cache-Control: private` for personalized responses to prevent CDN caching of user data. (5) INSIGHT: the CDN + APQ architecture creates near-infinite read scalability for public, non-personalized queries (product lists, content pages); the origin server handles only cache misses and writes; this is how news sites and e-commerce platforms serve millions of readers from a small GraphQL cluster.

---

### 📊 Diagram

```text
APQ PERFORMANCE IMPACT COMPARISON:

WITHOUT APQ:
  Request 1: POST 500B query -> Origin -> 50ms
  Request 2: POST 500B query -> Origin -> 50ms
  Request N: POST 500B query -> Origin -> 50ms
  All requests hit origin; no CDN benefit for queries

WITH APQ + CDN:
  Request 1: POST 550B (warm) -> Origin -> 50ms
             (hash miss, stores in cache)
  Request 2: GET 150B -> CDN MISS -> Origin -> 50ms
             (GET registered, CDN caches result)
  Request 3: GET 150B -> CDN HIT -> Edge -> 1ms!
  Request N: GET 150B -> CDN HIT -> Edge -> 1ms!

RESULT AT SCALE (1M req/day, 90% CDN hit):
  Without APQ: 1M x origin = $100/day compute
  With APQ: 100K origin + 900K CDN = $12/day
  Savings: 88% infrastructure cost reduction

PAYLOAD SIZE:
  Original query:  GetUserProfile = 587 bytes
  APQ hash:                        64 bytes
  Savings per request:             523 bytes (89%)
  At 1M req/day:                   499MB/day (saved)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the concrete performance impact comparison between no-APQ and APQ+CDN across multiple requests, plus cost and payload reduction statistics at scale. (2) HOW TO READ IT: the WITHOUT APQ section shows all N requests hitting the origin; the WITH APQ section shows the warm-up cost (requests 1-2) and then the CDN hit benefit (requests 3-N). (3) KEY RELATIONSHIP: the two-request warm-up cost is fixed regardless of total request count; at high traffic, the amortized cost approaches zero; APQ benefits increase with scale. (4) EDGE CASE: CDN hit rate depends on how many distinct queries are used; an API with 1000 unique query shapes (each used once) has near-zero CDN hit rate; an API with 10 popular query shapes (each used 100,000 times) has 99%+ CDN hit rate; APQ is most beneficial for APIs with few, frequently reused query shapes. (5) INSIGHT: a senior engineer combines APQ CDN caching with `stale-while-revalidate` CDN headers; CDN serves stale data immediately while revalidating in the background; this further reduces origin load without increasing perceived latency for clients.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | APQ mechanism, hash computation |
| Application | 2 | client setup, server setup |
| Performance | 2 | CDN caching, payload analysis |
| Architecture | 2 | strict APQ, CI/CD integration |
| Trade-off | 2 | strict vs auto, GET vs POST |
| Debugging | 2 | cache misses, deployment coordination |

---

**[JUNIOR] Q1 (Definition): What is a persisted query and how does it differ from a regular GraphQL query?**

A regular GraphQL query: the full query document text is sent in the HTTP request body
on EVERY request. If the query is 1KB, 1KB is sent every time.

A persisted query: the query document is stored on the server (in a Redis cache or
embedded in the schema registry). Clients send only the SHA-256 hash of the query
(64 bytes hex string). The server maps hash -> query and executes.

The hash is computed from the full query text:
```javascript
import { sha256 } from 'crypto-hash';

const query = `
  query GetUserProfile($id: ID!) {
    user(id: $id) { id name email bio }
  }
`;

const hash = await sha256(query);
// hash = "a3f4b9c2d1e8f7..." (64 hex chars)
// Same query always produces same hash
// Different whitespace -> different hash!
// -> Normalize queries before hashing
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the SHA-256 hashing of a GraphQL query document, producing a deterministic 64-character hex string that identifies the query. (2) KEY MECHANISM: SHA-256 produces a 256-bit (32 bytes) output represented as 64 hex characters; any change to the query text (even whitespace) produces a completely different hash; the server uses the hash as a lookup key in its APQ store. (3) WHY IT MATTERS: the hash is deterministic; the same query always produces the same hash; clients can compute hashes at build time (not at runtime) and pre-register them; the hash is a stable identifier for the query across deployments. (4) WHAT BREAKS: different whitespace normalization between the client (hashing) and the server (storing) causes hash mismatches; always normalize (remove comments, trim whitespace) before hashing; use the same normalization library on both client and server. (5) TAKEAWAY: query normalization before hashing is critical; `print(parse(query))` (parse and re-print the AST) produces a canonical form; use this normalized string for both hashing and storage.

---

**[JUNIOR] Q2 (Application): How do you enable APQ in Apollo Client?**

```javascript
// Step 1: Install
// npm install @apollo/client crypto-hash

// Step 2: Create the APQ link
import { ApolloClient, InMemoryCache,
         from, HttpLink } from '@apollo/client';
import {
  createPersistedQueryLink
} from '@apollo/client/link/persisted-queries';
import { sha256 } from 'crypto-hash';

const persistedQueriesLink = createPersistedQueryLink({
  sha256,
  useGETForHashedQueries: true
});

const httpLink = new HttpLink({
  uri: 'https://api.example.com/graphql'
});

// Step 3: Compose links (APQ before HTTP)
const client = new ApolloClient({
  cache: new InMemoryCache(),
  link: from([
    persistedQueriesLink,  // Intercepts, adds hash
    httpLink               // Sends the request
  ])
});

// APQ is now automatic for all operations:
// useQuery(MY_QUERY) -> APQ applied automatically
// No changes to queries, mutations, or subscriptions
// APQ link handles the hash/retry logic transparently
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the three-step APQ client setup - install, create the APQ link, compose with the HTTP link. (2) KEY MECHANISM: `createPersistedQueryLink` creates a middleware link; it intercepts outgoing operations; computes `sha256` of the query document; adds `extensions.persistedQuery.sha256Hash` to the request; handles `PERSISTED_QUERY_NOT_FOUND` by retrying with the full query; all of this is transparent to the application code. (3) WHY IT MATTERS: adding APQ requires no changes to any query, mutation, or component code; it is a one-time setup at the Apollo Client configuration level; all operations benefit automatically. (4) WHAT BREAKS: `from([persistedQueriesLink, httpLink])` - the APQ link MUST be before the HTTP link in the chain; if they are reversed, the HTTP link sends the request before APQ can add the hash extension. (5) TAKEAWAY: APQ requires two lines of configuration change in the Apollo Client setup; the benefit is immediate on the first deployment; no application code changes required.

*What separates good from great:* Hash collision resistance. SHA-256 has 2^256 possible
values; the probability of two different queries producing the same hash is
approximately 0 (less than 1 in 10^77). In practice, hash collisions are not a practical
concern for GraphQL APQ. However, if a different query produces the same hash (theoretical
collision), the server would execute the wrong query. Defense: store both the hash AND
the query text; on each execution, verify the request hash matches the stored query.
Apollo Server does this automatically; custom APQ implementations should too.

---

**[SENIOR] Q3 (Performance): How does APQ enable CDN caching for GraphQL?**

Standard GraphQL: HTTP POST. CDNs do not cache POST responses (POST is not idempotent
by HTTP spec). All queries must reach the origin server. CDN provides zero benefit for
GraphQL query traffic.

APQ GET: `useGETForHashedQueries: true` changes all hash-hit requests to HTTP GET:
```
GET /graphql?extensions={"persistedQuery":{"version":1,"sha256Hash":"abc123..."}}
       &variables={"id":"1"}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the APQ GET request URL format - the query hash and variables are URL-encoded query parameters; there is no request body. (2) KEY MECHANISM: HTTP GET requests have stable, inspectable URLs; the CDN uses the full URL (including hash and variables) as the cache key; identical operations produce identical URLs; CDNs can cache, purge, and share these responses globally. (3) WHY IT MATTERS: POST requests cannot be CDN-cached because POST is not idempotent; converting to GET is the critical step that enables CDN caching for GraphQL; without this conversion, APQ reduces bandwidth but not origin server load. (4) WHAT BREAKS: very long variable objects may exceed URL length limits (typically 8KB); `variables=` URL-encodes the JSON; for queries with large variable objects, consider compressing or shortening variable values. (5) TAKEAWAY: `useGETForHashedQueries: true` is the switch from bandwidth optimization to infrastructure cost optimization; enable it for all public non-personalized queries.

CDN behavior for GET:
- Cache key = URL (hash + variables).
- Same URL = same cache key = CDN serves from edge.
- `Cache-Control: max-age=60` = CDN caches for 60 seconds.
- After 60 seconds: CDN re-fetches from origin and re-caches.

The economics:
- Origin server cost (compute, DB): $X per request.
- CDN edge cost (serve cached): $X × 0.001 (100x cheaper).
- At 90% CDN hit rate: effective server cost = $X × (10% origin + 0.001 × 90%) ≈ $X × 0.1.
- APQ + CDN reduces server load by ~90%.

Configuration:
```javascript
// Server: per-type cache hints
const typeDefs = `
  type Product @cacheControl(maxAge: 300) {
    id: ID!
    name: String!
    price: Float!
    # cache for 5 minutes: stable product data
  }

  type User @cacheControl(maxAge: 0) {
    id: ID!
    email: String!
    # cache for 0: user-specific, never cache
  }
`;
```

> **Code walkthrough:** (1) WHAT IT SHOWS: `@cacheControl` directives setting per-type CDN cache TTLs - stable data (products) cached for 5 minutes; user-specific data not cached. (2) KEY MECHANISM: Apollo Server reads `@cacheControl(maxAge: N)` annotations and sets `Cache-Control: max-age=N` in the HTTP response; CDNs respect this header; queries that include User types get `max-age: 0` (no caching); queries that include only Product types get `max-age: 300`. (3) WHY IT MATTERS: without `@cacheControl`, all responses get the same TTL; user-specific data may be cached and served to other users (data privacy violation); type-level annotations ensure each type's TTL reflects its update frequency and sensitivity. (4) WHAT BREAKS: a query that fetches both Products AND Users receives `max-age: 0` (the minimum of all type TTLs); if `User @cacheControl(maxAge: 0)` is in the query, the entire response is not CDN-cacheable even if most fields are stable. (5) TAKEAWAY: design APQ GET + CDN for queries that return non-user-specific data (product catalogs, public content, lists); never cache user-specific queries; use `@cacheControl(maxAge: 0)` on all user-specific types as a safety net.

---

**[JUNIOR] Q4 (Application): How does the server store and retrieve APQ hashes?**

Apollo Server APQ hash storage:

```javascript
// Default (development): in-memory LRU cache
const server = new ApolloServer({
  typeDefs, resolvers
  // No cache option = in-memory default
  // Size: 30MB; LRU eviction
  // Problem: cleared on restart; single-instance
});

// Production: Redis-backed APQ cache
const { KeyvAdapter } = require('@apollo/utils.keyvadapter');
const Keyv = require('keyv');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  cache: new KeyvAdapter(
    new Keyv('redis://redis:6379', {
      ttl: 30 * 24 * 60 * 60 * 1000  // 30 days
    })
  )
});

// Apollo Server APQ storage logic:
// On PERSISTED_QUERY_NOT_FOUND:
//   1. Check Redis for key "apq:sha256:HASH"
//   2. Not found -> send error to client
//   3. Client retries with full query
//   4. Server receives hash + query:
//      Redis SET "apq:sha256:HASH" "query text" EX 2592000
//   5. Execute query

// On subsequent request with hash only:
//   1. Check Redis for key "apq:sha256:HASH"
//   2. Found -> execute cached query
//   3. Cache hit: ~0.5ms Redis GET latency
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Apollo Server's APQ storage with in-memory (development) vs Redis-backed (production) cache, including the key format (`apq:sha256:HASH`) and TTL configuration. (2) KEY MECHANISM: `KeyvAdapter` adapts any Keyv-compatible store to Apollo's `KeyValueCache` interface; `Keyv` supports Redis, Memcached, SQLite, and others; the 30-day TTL prevents the Redis cache from growing without bound. (3) WHY IT MATTERS: the TTL strategy: 30 days covers all active clients; after 30 days, unused queries expire from the cache naturally; this prevents unbounded cache growth from historical queries. (4) WHAT BREAKS: if `KeyvAdapter` is imported from the wrong package (there were multiple paths in different Apollo Server versions), the cache silently falls back to in-memory; verify the import path for your Apollo Server version. (5) TAKEAWAY: `new KeyvAdapter(new Keyv('redis://redis:6379'))` is the production standard; add this to every new Apollo Server deployment; Redis APQ cache is operational infrastructure, not an optimization.

---

**[SENIOR] Q5 (Architecture): How do you integrate APQ hash pre-registration into a CI/CD pipeline?**

Pre-registration ensures zero APQ cache misses after deployment:

```bash
# CI/CD Pipeline Steps (order matters):

# Step 1: Build frontend
npm run build
# Output: dist/ with bundled JS

# Step 2: Extract all GraphQL operations
# graphql-codegen generates a manifest:
# operations: [{name: "GetUserProfile",
#               body: "query GetUserProfile...",
#               hash: "abc123..."}]
npx graphql-codegen --config codegen.yml
# Or: rover persisted-queries publish ...

# Step 3: Register operations with APQ cache
# (BEFORE deploying frontend!)
node scripts/register-apq.js
# register-apq.js:
# For each operation in manifest:
#   Redis SET apq:sha256:HASH QUERY_BODY EX 2592000
# Output: Registered 47 operations

# Step 4: Deploy frontend
# New frontend uses pre-registered hashes
# APQ cache: immediate HIT for all new operations
# Zero PERSISTED_QUERY_NOT_FOUND errors!

# Step 5: (Optional) Deploy backend changes
# Backend can deploy independently of frontend

# Deployment order: register -> frontend -> backend
# (backend last because it never depends on hashes)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a CI/CD pipeline ordering that pre-registers APQ hashes before the frontend is deployed, ensuring zero cache miss errors for new operations after deployment. (2) KEY MECHANISM: the registration step runs `graphql-codegen` to extract operation documents, computes their hashes, and writes them to Redis with the same key format Apollo Server expects; when the frontend deploys, the hashes are already in Redis; the first request sees a cache hit. (3) WHY IT MATTERS: without pre-registration, the first request from any client using a new operation experiences two round-trips (APQ miss + full query); with pre-registration, all requests use hash-only GET from the first moment; particularly important for mobile clients where retries add significant latency. (4) WHAT BREAKS: if the hash is computed from the un-normalized query text but Apollo Server normalizes before storing, the hashes don't match; use the same normalization step (AST parse + print) in both the registration script and the Apollo Client link. (5) TAKEAWAY: APQ pre-registration is a CI/CD concern, not a runtime concern; treat it as a deployment prerequisite like database migration; create a standard Makefile target or GitHub Action that runs pre-registration automatically on every frontend build.

---

**[SENIOR] Q6 (Trade-off): What are the trade-offs between strict APQ and automatic APQ?**

**Automatic APQ (with fallback):**
- Behavior: hash-only first; on miss, retry with full query; server stores hash.
- Self-healing: new queries automatically register on first use; no CI/CD coordination.
- Security posture: moderate; attackers can register malicious queries by submitting
  them once (full query fallback allows registration).
- Best for: development environments, internal APIs, APIs with multiple clients
  (not all clients can be pre-registered centrally).

**Strict APQ (no fallback):**
- Behavior: hash-only; on miss, return error (no full-query fallback allowed).
- Security: highest; only hashes registered during the build pipeline can execute;
  novel queries are permanently rejected.
- Operational cost: high; all client queries must be pre-registered; new query in a
  feature branch requires pre-registration before the PR can be tested.
- Best for: production public APIs with a single controlled client.

```javascript
// Strict APQ mode on the server:
// Reject full-query fallback entirely
const server = new ApolloServer({
  typeDefs,
  resolvers,
  cache,
  // Custom plugin to reject full-query fallback:
  plugins: [{
    requestDidStart: () => ({
      didResolveOperation: async ({ request }) => {
        const ext = request.extensions;
        // If hash provided but no APQ match
        // AND full query also provided -> reject
        if (ext?.persistedQuery
            && request.query) {
          const hash = await sha256(request.query);
          if (hash === ext.persistedQuery.sha256Hash) {
            // Client is trying to self-register
            // In strict mode: reject this!
            throw new GraphQLError(
              'Query registration not allowed',
              { extensions: { code: 'FORBIDDEN' } }
            );
          }
        }
      }
    })
  }]
});
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a custom Apollo Server plugin implementing strict APQ mode - when a client sends both a hash AND the full query (the registration step), the server rejects it; only pre-registered hashes are accepted. (2) KEY MECHANISM: the plugin intercepts `didResolveOperation`; if both `request.extensions.persistedQuery.sha256Hash` and `request.query` are present, the client is attempting to register a new query; in strict mode, this is rejected with a `FORBIDDEN` error. (3) WHY IT MATTERS: without this plugin, any client can send `{query: "mutation deleteAllData {...}", extensions: {persistedQuery: {sha256Hash: "..."}}}` to self-register and then execute a malicious query; strict mode blocks this. (4) WHAT BREAKS: strict mode breaks any workflow that submits ad-hoc queries: GraphiQL, Apollo Sandbox, `graphql-request` in tests, any script that sends direct queries; add a bypass for internal IP ranges or admin API keys. (5) TAKEAWAY: strict APQ is appropriate for the production public API; never for development or staging; use separate Apollo Server configurations or a middleware flag to control strict mode by environment.

---

**[JUNIOR] Q7 (Application): How do you debug an APQ cache miss in production?**

```bash
# Step 1: Verify the error message
# Client should report: PERSISTED_QUERY_NOT_FOUND
# Or: operation fails with no data

# Step 2: Check if hash exists in APQ cache
redis-cli GET "apq:sha256:YOUR_HASH_HERE"
# (nil) = hash not in cache -> cache miss
# "{query text}" = hash in cache -> NOT an APQ issue

# Step 3: Check Apollo Server logs
# Enable APQ logging:
# APOLLO_KEY=your-key APOLLO_GRAPH_REF=graph@prod node server.js
# Apollo Studio: Operations -> Persisted Queries
# Or add custom logging:
plugins: [{
  requestDidStart: () => ({
    parsingDidStart: ({ request }) => {
      const hash = request.extensions
        ?.persistedQuery?.sha256Hash;
      if (hash && !request.query) {
        logger.debug('APQ hash-only request', { hash });
      }
    }
  })
}]

# Step 4: Verify hash computation
# Client-side hash must match server expectations
# Test: compute hash of a known query and check Redis
node -e "
const { sha256 } = require('crypto-hash');
const query = require('fs')
  .readFileSync('query.graphql', 'utf-8');
sha256(query).then(hash => console.log(hash));
"
# Compare with: redis-cli GET "apq:sha256:COMPUTED_HASH"
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a systematic four-step APQ debug process - checking the error, verifying Redis cache contents, enabling APQ logging, and verifying hash computation consistency. (2) KEY MECHANISM: `redis-cli GET "apq:sha256:HASH"` directly queries the APQ store to determine if the hash is registered; if the hash is absent, the root cause is either a cache miss (new query, no pre-registration) or a hash mismatch (client and server computing different hashes). (3) WHY IT MATTERS: PERSISTED_QUERY_NOT_FOUND errors affect all clients using APQ; the debug process must quickly determine if the issue is a missing registration, wrong hash computation, or a Redis connectivity problem. (4) WHAT BREAKS: the `apq:sha256:HASH` key prefix must match Apollo Server's internal format; if a custom APQ cache uses a different key format, `redis-cli GET "apq:sha256:..."` returns nil even when the hash is registered (under a different key). (5) TAKEAWAY: add APQ cache hit/miss logging as a standard Apollo Server plugin from the start; diagnosing APQ issues requires knowing the hit rate baseline; without logging, you cannot distinguish "cache is working but hash missing" from "cache is broken."

---

**[SENIOR] Q8 (Architecture): How does APQ interact with GraphQL schema changes?**

APQ hashes are computed from the query document text only - NOT the schema. A schema
change does not invalidate APQ hashes.

Scenario: schema adds a new field `User.bio`. Existing queries (not using `bio`) have
unchanged hash values and continue to work without re-registration.

Problem: schema REMOVES a field that existing queries use.

```javascript
// Before schema change:
// type User { id, name, email, bio }
// Registered APQ query:
// sha256("query { user { id name bio } }") = "abc123"

// After schema change (bio removed):
// type User { id, name, email }
// APQ hash "abc123" still maps to the old query
// Server executes: "query { user { id name bio } }"
// -> GraphQL validation fails: "bio" not in schema
// -> ERROR returned to client

// The APQ hash is not invalidated by schema change!
// Old queries fail until clients re-deploy with
// updated queries (without "bio")

// Fix: monitor for query validation errors
// that reference removed fields;
// these indicate stale APQ registrations
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a schema field removal that causes APQ-registered queries to fail with validation errors - the APQ hash points to an old query that references a removed field. (2) KEY MECHANISM: APQ stores `hash -> query text`; the query text references `bio`; after `bio` is removed from the schema, the stored query is syntactically valid but schema-invalid; Apollo Server's validation phase rejects it; the client receives a validation error. (3) WHY IT MATTERS: this is the APQ-specific consequence of breaking schema changes; in non-APQ GraphQL, the client deploys a new query without `bio`; with APQ, the old hash is still registered and used until the client deploys an updated query that hashes differently. (4) WHAT BREAKS: both the old hash (for the query with `bio`) and the new hash (for the query without `bio`) may exist in the APQ cache simultaneously; old clients use the old hash (fails); new clients use the new hash (succeeds); the mixed state continues until all clients update. (5) TAKEAWAY: when removing fields from a GraphQL schema, follow the deprecation workflow: deprecate first, monitor usage to zero, then remove; use Apollo Studio's field usage data to verify no client queries reference a field before removing it from the schema.

---

**[JUNIOR] Q9 (Application): What is the correct link chain order for Apollo Client with APQ?**

```javascript
// The Apollo Client link chain processes requests
// in order (left to right) and responses in reverse:

// BAD: Wrong order - HTTP before APQ
const client = new ApolloClient({
  link: from([
    httpLink,              // Sends request FIRST
    persistedQueriesLink   // Never runs! After HTTP
  ])
});
// httpLink sends the request WITHOUT the APQ extension
// persistedQueriesLink never intercepts

// GOOD: Correct order - APQ before HTTP
// BAD: (see above - wrong order breaks APQ)
const client = new ApolloClient({
  link: from([
    persistedQueriesLink,  // Adds hash extension
    httpLink               // Sends modified request
  ])
});
// persistedQueriesLink: adds extensions.persistedQuery
// httpLink: sends request with hash extension
// On PERSISTED_QUERY_NOT_FOUND:
//   persistedQueriesLink intercepts the response
//   Retries with full query (not httpLink's concern)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the BAD (wrong) and GOOD (correct) link chain order, explaining why `persistedQueriesLink` must be BEFORE `httpLink` in the `from()` array. (2) KEY MECHANISM: `from([a, b, c])` creates a chain; `a` runs first, passes to `b`, passes to `c`; for requests: a -> b -> c -> network; for responses: c -> b -> a; `persistedQueriesLink` must intercept the outgoing request (to add hash) AND the incoming response (to handle `PERSISTED_QUERY_NOT_FOUND`); it must be FIRST in the chain. (3) WHY IT MATTERS: the wrong order is a silent bug; APQ appears to be configured but never activates; requests send full query text every time; bandwidth is not reduced and CDN GET caching does not work. (4) WHAT BREAKS: with `[httpLink, persistedQueriesLink]`, the response interceptor in `persistedQueriesLink` is correct (it runs before `httpLink` on responses), but the request interceptor (adding hash) never runs because `httpLink` terminates the chain by sending the request. (5) TAKEAWAY: always put middleware links (authentication, APQ, error handling) BEFORE terminal links (httpLink, batchHttpLink) in the `from()` array; terminal links end the chain.

---

**[SENIOR] Q10 (Trade-off): How does APQ compare to response caching for reducing GraphQL server load?**

Both reduce server load, but at different points:

APQ (hash cache):
- What it caches: `hash -> query document text`.
- What it avoids: sending full query over the wire; query document parsing; AST traversal.
- What it does NOT avoid: resolver execution, database queries.
- Load reduction: bandwidth, CPU for parsing.
- Best for: high-traffic APIs where bandwidth is a cost; mobile clients.

Response caching (result cache):
- What it caches: `{query + variables + user} -> result JSON`.
- What it avoids: resolver execution, database queries, ALL computation after parsing.
- What it does NOT avoid: Redis lookup for cache key.
- Load reduction: database queries, resolver CPU, everything.
- Best for: queries returning data that changes infrequently (product catalog, content).

Combined: use both. APQ for all queries (always beneficial). Response caching for stable,
non-user-specific queries (product list, public content pages).

```javascript
// Response caching with Apollo Server
const {
  ApolloServerPluginCacheControl
} = require('@apollo/server/plugin/cacheControl');
const {
  InMemoryLRUCache
} = require('@apollo/utils.keyvaluecache');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  cache: new InMemoryLRUCache({
    maxSize: Math.pow(2, 20) * 30  // 30MB
  }),
  plugins: [
    ApolloServerPluginCacheControl({
      defaultMaxAge: 60,  // 60 seconds default
      calculateHttpHeaders: true
    })
  ]
});
// Products (maxAge: 300): cached 5 minutes
// Users (maxAge: 0): never cached
// Mixed queries: use minimum maxAge
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Apollo Server's response caching setup alongside APQ, creating a two-tier caching architecture. (2) KEY MECHANISM: `ApolloServerPluginCacheControl` adds HTTP `Cache-Control` headers based on `@cacheControl` directives on types; the server's `InMemoryLRUCache` caches the full response JSON; a cache hit returns the stored JSON without executing any resolvers. (3) WHY IT MATTERS: response caching is orthogonal to APQ; APQ reduces parsing overhead and bandwidth; response caching reduces resolver and DB overhead; together they eliminate most of the server work for frequently accessed, stable data. (4) WHAT BREAKS: response cache key must include the user identity for user-specific queries; without user-keyed caching, user A's data is cached and served to user B; set `@cacheControl(maxAge: 0)` on all user-specific types. (5) TAKEAWAY: APQ + response caching is the GraphQL production optimization stack; APQ everywhere; response caching for non-user-specific queries; the combination can reduce origin server load by 90%+ for read-heavy APIs.

---

**[JUNIOR] Q11 (Definition): What is the format of an APQ request over the wire?**

APQ modifies the GraphQL HTTP request format:

```
Standard GraphQL request (no APQ):
POST /graphql HTTP/1.1
Content-Type: application/json

{"query":"query GetUser($id:ID!){ user(id:$id){ name } }",
 "variables":{"id":"123"}}

APQ - First request (hash only):
POST /graphql HTTP/1.1
Content-Type: application/json

{"variables":{"id":"123"},
 "extensions":{"persistedQuery":{
   "version":1,
   "sha256Hash":"abc123def456..."}}}

APQ - Second request (miss, full query + hash):
POST /graphql HTTP/1.1
Content-Type: application/json

{"query":"query GetUser($id:ID!){ user(id:$id){ name } }",
 "variables":{"id":"123"},
 "extensions":{"persistedQuery":{
   "version":1,
   "sha256Hash":"abc123def456..."}}}

APQ - Subsequent requests (GET, CDN-cacheable):
GET /graphql?variables={"id":"123"}
  &extensions={"persistedQuery":{
    "version":1,"sha256Hash":"abc123..."}}
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the four request formats in the APQ lifecycle - standard (no APQ), first APQ request (hash only), second APQ request (miss, full query), and subsequent GET requests (CDN-cacheable). (2) KEY MECHANISM: the `extensions.persistedQuery.version` is always `1` (current APQ spec version); the `sha256Hash` is the 64-char hex SHA-256 of the query document; `variables` are always included for the correct execution; the `query` field is omitted in hash-only requests. (3) WHY IT MATTERS: understanding the wire format is essential for debugging APQ; inspecting network requests in browser DevTools shows which request format is being used; a request with only `extensions.persistedQuery` and no `query` is a hash-only APQ request. (4) WHAT BREAKS: the `version: 1` in `extensions.persistedQuery` is required; servers reject APQ requests with missing version; the version is always 1 (the spec has not changed). (5) TAKEAWAY: use browser DevTools Network tab to verify APQ is working: first request should show hash-only, subsequent requests should be GET with hash; if all requests show full `query` text, APQ is not functioning correctly.

---

**[SENIOR] Q12 (Architecture): How do you handle APQ in a multi-tenant or multi-environment setup?**

Multi-tenant GraphQL APIs often share a Redis APQ cache across tenants. Issues and
solutions:

1. Hash namespace collision: two tenants may have queries with the same hash (unlikely
   with SHA-256 but defensively important). Solution: prefix APQ keys with tenant ID:
   `apq:tenant:{tenantId}:sha256:{hash}`.

2. Different schema versions: a SaaS platform with per-tenant schema extensions may have
   different type definitions per tenant. The same query hash could be valid in one
   tenant's schema and invalid in another. Solution: include schema version in the APQ
   key: `apq:schema:{schemaVersion}:sha256:{hash}`.

3. Multi-environment caching: staging and production share a Redis instance. A staging
   APQ registration (possibly a test query) persists in the cache. Solution: namespace
   by environment: `apq:{env}:sha256:{hash}`.

4. Apollo Federation with multiple subgraphs: each subgraph has its own schema; the
   gateway handles APQ; the gateway's APQ cache stores supergraph-level queries; subgraph
   schemas changing the supergraph invalidates supergraph queries; use the supergraph
   version (from schema registry) as the cache namespace.

```javascript
// Custom APQ key generator:
const customCache = {
  get: (key) =>
    redis.get(`apq:${env}:${schemaVersion}:${key}`),
  set: (key, value, options) =>
    redis.set(
      `apq:${env}:${schemaVersion}:${key}`,
      value,
      'EX',
      options?.ttl || 2592000
    ),
  delete: (key) =>
    redis.del(`apq:${env}:${schemaVersion}:${key}`)
};
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a custom APQ cache implementation that prefixes all keys with environment and schema version, preventing cross-environment and stale-schema cache pollution. (2) KEY MECHANISM: `apq:${env}:${schemaVersion}:${key}` creates a namespace hierarchy; `env` (production vs staging) prevents cross-environment sharing; `schemaVersion` (from schema registry version tag) ensures that schema changes automatically invalidate old queries. (3) WHY IT MATTERS: schema-versioned APQ keys ensure that when a breaking schema change is deployed (field removed, type changed), the old APQ entries are ignored because the schema version in the key changes; old entries expire via TTL. (4) WHAT BREAKS: if `schemaVersion` changes on every deploy (even non-schema changes), every deploy invalidates the APQ cache and causes a cold-start two-round-trip period; use schema hash (based on SDL content) rather than deploy tag as the version identifier. (5) TAKEAWAY: APQ cache namespacing is an advanced topic that becomes necessary in multi-tenant and multi-environment setups; start with simple `apq:sha256:HASH` keys; add namespacing when you encounter environment bleed-through or schema-version issues.
