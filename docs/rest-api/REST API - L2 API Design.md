---
layout: default
title: "REST API - L2 API Design"
parent: "REST API"
grand_parent: "SK Interview"
nav_order: 4
permalink: /rest-api/l2-api-design/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [API Versioning Strategies](#api-versioning-strategies) | medium |
| 2 | [Pagination, Filtering, and Sorting](#pagination-filtering-and-sorting) | medium |

---

# API Versioning Strategies

---

### 🎯 Model Answer

**30 seconds:**
> API versioning is the practice of maintaining multiple API versions simultaneously to allow clients to evolve at their own pace without being forced to upgrade immediately. The three main strategies are URI versioning (/v1/users), header versioning (Accept: application/vnd.myapp.v2+json), and query parameter versioning (/users?version=2). URI versioning is the most practical choice for public APIs.

**3 minutes:**
> Versioning is necessary because APIs are contracts - once published, breaking changes are breaking clients that may not be under your control. A mobile app on a user's phone that calls your v1 API cannot be updated by you - you must keep v1 running while the user updates the app. API versioning gives you the freedom to evolve the API (add fields, change structures, remove deprecated features) while maintaining backward compatibility for existing clients. URI versioning (/v1/, /v2/) is the most commonly used approach: simple to implement, visible in logs and proxies, easy to test with a browser or curl, and cache-friendly (CDN caches v1 and v2 responses separately). Header versioning (Accept: application/vnd.myapp.v2+json) keeps URLs clean but is hard to test without special tools and doesn't work well with CDN caching. Query parameter versioning (/users?version=2) is simple but pollutes query parameters and makes version routing less explicit. The strategic principle: version rarely. Additive changes (new fields, new endpoints) don't require a version bump. Only breaking changes (remove fields, rename fields, change semantics) require a new version. Use the Sunset header (RFC 8594) to communicate when a version will be retired. Keep v1 running for at least 6-12 months after v2 is available.

**Blank Mind Recovery:**
**(1) Restate:** "API versioning - keeping multiple API versions running simultaneously."
**(2) First principles:** "Why? APIs are contracts. Clients you don't control must work. Breaking changes need a new version."
**(3) Bridge:** "Like a building's floors. v1 clients live on floor 1, v2 clients on floor 2. Both floors accessible, each floor may be different."

---

### 📘 Concept Explanation

**What it is:**
API versioning is a strategy for managing changes to a published API in a way that doesn't break existing clients while allowing new clients to use improved functionality.

**The problem it solves:**
APIs are contracts. Published APIs are consumed by clients you don't control (mobile apps, third-party integrations, partners). When you need to change the API (restructure response, remove a field, change semantics), breaking those clients. Versioning allows additive evolution while keeping existing contracts intact.

**How it works:**
```
URI Versioning (most common):
  GET /v1/users/123  -> { id: 123, name: "Alice",
                          address: "123 Main..." }
  GET /v2/users/123  -> { id: 123, firstName: "Alice",
                          lastName: "Smith",
                          address: { street:..., city:... } }

Both endpoints live simultaneously.
V1 clients continue working unchanged.
New clients use /v2/ for the improved structure.

Header Versioning:
  GET /users/123
  Accept: application/vnd.myapp.v1+json

  GET /users/123
  Accept: application/vnd.myapp.v2+json

Same URL, different response format based on Accept.

Query Parameter:
  GET /users/123?version=1
  GET /users/123?version=2
```

> **Code walkthrough:** This API Versioning Strategies example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
Versioning at the API level (breaking change = new version) is simpler than versioning at the field level (every field has a version). The contract is the version. Within a version, add new fields freely (additive changes are non-breaking for clients that use Jackson's `@JsonIgnoreProperties(ignoreUnknown = true)`). Between versions, change structure as needed.

**When to use it:**
Any public API that will be consumed by clients you don't control. Any API that will need breaking changes. Any API where you cannot guarantee all clients will update simultaneously.

**When NOT to use it:**
Internal microservices with a single team owning both client and server - rolling update is simpler. APIs consumed only by your own controlled clients that can be updated immediately.

**Alternatives:**
- Semantic versioning via OpenAPI spec (documents changes, doesn't address backward compatibility)
- Field deprecation without version bump (mark fields @deprecated, keep them, add new fields - for minor changes only)
- API evolution without versioning (GraphQL approach: additive only, deprecate but keep)

**First-principles derivation:**
Every distributed system with independently deployable components needs a versioning strategy. When client code and server code can be deployed independently, they may run different versions simultaneously. The versioning strategy defines the rules for what constitutes a compatible vs. incompatible change, and how long old versions remain supported.

---

### 💻 Code Example

```java
// Spring Boot URI versioning implementation

// V1 controller
@RestController
@RequestMapping("/v1/users")
public class UserControllerV1 {

  @GetMapping("/{id}")
  public UserV1 getUser(@PathVariable Long id) {
    User user = userService.findById(id);
    // V1 response: flat address string
    return new UserV1(user.getId(),
        user.getName(),
        user.getAddress().toString());
  }
}

// V2 controller - breaking change: address is now object
@RestController
@RequestMapping("/v2/users")
public class UserControllerV2 {

  @GetMapping("/{id}")
  public UserV2 getUser(@PathVariable Long id) {
    User user = userService.findById(id);
    // V2 response: structured address object
    return new UserV2(user.getId(),
        user.getFirstName(),  // renamed from name
        user.getLastName(),   // new field
        new AddressV2(        // address is now object
            user.getAddress().getStreet(),
            user.getAddress().getCity(),
            user.getAddress().getPostalCode()));
  }
}

// Sunset header on V1 responses (RFC 8594)
@RestControllerAdvice
public class DeprecationAdvice
    implements ResponseBodyAdvice<Object> {

  @Override
  public Object beforeBodyWrite(...) {
    if (request.getRequestURI().startsWith("/v1/")) {
      headers.add("Deprecation", "true");
      headers.add("Sunset",
          "Thu, 01 Jan 2027 00:00:00 GMT");
      headers.add("Link",
          "</v2/users>; rel=\"successor-version\"");
    }
    return body;
  }
}
```

> **Code walkthrough:** Two separate controllers for v1 and v2 with different response shapes. UserV1 has a flat string address. UserV2 has firstName/lastName instead of name, and a structured address object. Both controllers share the same `userService` layer - the versioning is only in the API representation. The DeprecationAdvice adds RFC 8594 Sunset header to all v1 responses, telling clients that v1 will be retired on January 1, 2027, and pointing them to the successor version.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "API versioning lets us change an API without breaking clients that are already using it. We keep v1 running while introducing v2 with improvements. URI versioning is the simplest: /v1/users for the old version, /v2/users for the new. Clients using /v1/ keep working unchanged. New clients use /v2/. We eventually retire v1 after giving clients time to migrate."

**Senior / Staff:** "API versioning strategy depends on client control. For public APIs (mobile apps, third-party integrations): use URI versioning with a clear sunset policy - at least 6 months from v2 GA to v1 sunset. For internal microservices: use consumer-driven contracts (Pact) to verify compatibility - this allows breaking changes without versioning when all consumers are verified. For breaking changes: version. For additive changes (new fields, new endpoints): don't version - clients that use `@JsonIgnoreProperties(ignoreUnknown=true)` (Jackson default) won't break. The operational concern: maintaining multiple API versions means maintaining multiple code paths. I try to keep the versioned layer thin: same service layer, different response DTOs. Alternatively, use a data transformation layer (versioned serializers) that maps from the internal domain model to the versioned API response. This way the service layer doesn't know about API versions. At staff level: version the external contract (the API), not the internal model. The domain model evolves independently. The versioned controller layer is a translation layer between the current domain model and each published API version."

---

### ⚠️ Common Misconceptions

**Misconception:** "Every change requires a new API version."
Reality: Only BREAKING changes require a new version. Additive changes are non-breaking for well-written clients. Adding new fields to a JSON response: non-breaking (clients that use `JsonIgnoreProperties(ignoreUnknown=true)` or access fields by name will work unchanged). Adding new optional request parameters: non-breaking (clients not sending them use defaults). Adding new endpoints: non-breaking (clients that don't call them are unaffected). Breaking changes that DO require versioning: removing fields from responses (clients that use those fields break). Renaming fields (clients using the old name break). Changing field types (string to integer breaks parsers). Changing URL structure (clients that hardcoded the URL break). Changing semantics (GET that previously returned all users now returns only active users - behavior changes without signature changes). The practical rule: when in doubt, add don't remove. Use `@Deprecated` to signal future removal. Remove in the next major version.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Legacy clients break after API "non-breaking" change**

Symptoms: After adding new required fields to a POST request, old mobile app versions start returning errors. Marketing team reports complaints from users with older app versions.

Root cause: New required fields were added to the request body. Old clients don't send them. Server validates them as required and returns 400 Bad Request.

Diagnosis: Check mobile app version distribution in app analytics. Check API access logs for 400 errors from old User-Agent strings (old app versions).

Fix: New request fields should be optional with sensible defaults for at least one full version (6-12 months). Never add required request fields to an existing endpoint without a version bump. If urgently needed: add as optional with default; make required in v2. Backfill strategy: use the Client-Version header (sent by the app) to determine which validation rules to apply. This is complex but allows version-specific validation without a full URL versioning.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Comparison | 3 min | 2 |
| Scenario | 3 min | 2 |
| Trade-off | 3 min | 2 |
| Debugging | 2 min | 1 |
| Design | 3 min | 1 |
| Behavioral | 3 min | 1 |

**[JUNIOR] Q1 - [TRADE-OFF] "Compare URI versioning, header versioning, and query parameter versioning."**
> "Three strategies, each with clear trade-offs: URI versioning (/v1/users, /v2/users): visible in every URL, easy to test with browser/curl, cache-friendly (CDN caches by URL, v1 and v2 are separate cache entries), easy to route at proxy level (`if /v2/` -> new backend), client explicitly chooses version on every call. Cost: URL pollution, version visible in every log line. Best for: public APIs with external clients. Header versioning (Accept: application/vnd.myapp.v2+json): clean URLs, version negotiated per response. Same URL serves both v1 and v2. Cost: cannot test with browser without tools, CDN caches by URL only (must add Vary: Accept header), version invisible in URL logs, harder to understand when debugging. Best for: internal APIs where URL cleanliness matters more than observability. Query parameter (/users?version=2): simple, URL-based but version in query string. Cost: leaks version into query parameters (interferes with caching if not handled), easy to omit accidentally. Rarely used in practice. The deciding factor: can all clients be controlled and updated? No -> URI versioning (simple, observable, independent client choice). Yes -> header versioning or contract testing without versioning."

*What separates good from great:* "The CDN caching consideration (URI versioning caches separately per URL, header versioning needs Vary: Accept which reduces cache efficiency) is the production operations insight that candidates who've operated CDN-fronted APIs know."

---

**[JUNIOR] Q2 - [CONCEPTUAL] "How do you sunset a deprecated API version?"**
> "Sunset lifecycle: (1) Announce v2: release v2 while keeping v1 running. Add `Sunset` header (RFC 8594) to all v1 responses: `Sunset: Sat, 01 Jan 2027 00:00:00 GMT`. Add `Deprecation: true` header. Add `Link: </v2/users>; rel=successor-version` pointing to the replacement. (2) Track v1 usage: monitor v1 request volume and the User-Agent / API key making those requests. Contact specific clients that are still heavily using v1. Some won't know about v2 unless you tell them directly. (3) Set a sunset date: 6 months minimum for public APIs, 12+ months for enterprise integrations. Announce via email to registered API key owners, developer portal, changelog. (4) Grace period behavior: in the last month before sunset, increase Sunset header urgency (add warning log entries on the server, consider rate limiting v1 to nudge clients). (5) Sunset day: return 410 Gone from v1 endpoints with a body pointing to v2. Don't return 404 (resource doesn't exist) - return 410 (resource existed, now gone). This tells clients the endpoint was removed intentionally, not a typo. Keep 410 response for 6+ months to help clients who check only occasionally."

*What separates good from great:* "The 410 Gone recommendation (vs 404) on sunset day is the precise HTTP semantics: 410 communicates 'this was here and was intentionally removed.' Clients that check for 404 to detect URL typos won't confuse a 410 with a bug. The tracking v1 usage and proactively contacting heavy users shows operational experience."

---

**[JUNIOR] Q3 - [DEBUGGING] "You're on call and v1 clients are suddenly failing. How do you debug?"**
> "Triage steps: (1) Check if v2 is also affected. If yes: the issue is shared infrastructure (database, authentication service). Not a versioning issue. (2) Check deployment logs: was anything deployed in the last hour? If v2 was deployed and v1 is in the same codebase: the deployment may have broken v1. (3) Check the v1 error types: 500 vs 400 vs 404. 500: server error, check application logs. 400: schema/validation changed, check if shared request validation logic changed. 404: routing changed, check if /v1/ routes are still configured. (4) If using a shared database schema: check if a database migration altered a column type, added a NOT NULL constraint, or deleted a column that v1 queries use. Database migrations that serve both v1 and v2 must be backward-compatible. (5) Check load balancer routing: v1 requests might be routing to the v2 backend. `curl -v /v1/users -H 'User-Agent: v1test'` and inspect the Server header to see which backend responded. Mitigation: if v2 deployment broke v1: rollback v2 immediately. Root cause: v1 and v2 shared a code path that changed. Fix: version the code path, not just the URL."

*What separates good from great:* "The database migration backward compatibility point is the production edge case. A v2 migration that adds a NOT NULL column with no default breaks v1 code that doesn't set that column. Running both API versions means database migrations must be compatible with all running versions."

---

**[MID] Q4 - [HANDS-ON] "How do you handle versioning for API clients that hardcoded the wrong version?"**
> "This happens with mobile apps. The scenario: v1 was released. The app hardcoded `/v1/users`. Later, v2 was released. You eventually sunset v1 (return 410). But users haven't updated the app (older iOS/Android version, disabled auto-update, enterprise-managed device). Solution options: (1) Never sunset: accept that v1 lives forever. Practical for small client populations but accumulates technical debt. (2) Redirect: 301 Permanent Redirect from `/v1/users` to `/v2/users`. Works only if v2 is backward compatible enough for v1 clients. v2 must handle missing v1-specific params gracefully. (3) Version adapter: serve v1 responses from the v2 backend using a transformation layer. The v1 endpoint translates v2 internal data to v1 response format. This 'v1 compatibility layer' is a translation adapter, not the original v1 code. Allows v1 URLs to work indefinitely with the current backend. (4) Force upgrade: return `410 Gone` with body `{message: 'Please update your app', updateUrl: '...'}`. Mobile apps must display the update prompt. For regulated industries (banking): often have minimum version policies that force updates. The pragmatic choice: for mobile, the compatibility layer (option 3) is safest. You can update the translation layer incrementally. For partner integrations: negotiate the upgrade timeline directly and commit to a formal sunset date."

*What separates good from great:* "The v1 compatibility layer (translation adapter over v2 backend) is the production solution for long-lived mobile clients. This approach lets you deprecate v1 implementation without removing v1 URL support."

---

**[MID] Q5 - [CONCEPTUAL] "What is consumer-driven contract testing and how does it replace API versioning?"**
> "Consumer-driven contract testing (CDCT) is a testing approach where the API consumer (client) defines the contract it expects from the producer (server). The producer must satisfy all consumer contracts. When the producer wants to change the API: run the CDCT suite. If all consumer contracts still pass: the change is backward compatible, no versioning needed. If a consumer contract breaks: contact that consumer team, update the contract, and only then deploy. Tools: Pact is the industry standard. Consumer team writes a Pact test: 'I expect a GET /users/123 to return {id: 123, name: string, email: string}.' Pact generates a contract file. The provider runs the contract against their API: all contracts must pass before deployment. CDCT enables: confident breaking changes (you know exactly which consumers are affected), independent deployment (consumer and provider can deploy in any order as long as contracts pass), and contract documentation (the Pact files are the living API contract). Why CDCT replaces versioning for internal APIs: versioning is for external clients you can't contact. For internal services, CDCT gives you the same safety (no surprises) without maintaining multiple API versions."

*What separates good from great:* "Knowing Pact by name and how it generates contract files shows practical tooling knowledge. The insight about CDCT replacing versioning for internal services (because you can coordinate with all consumers directly) shows architectural thinking."

---

**[MID] Q6 - [BEHAVIORAL] "Tell me about a time you made a breaking API change and how you managed it."**
> "Use STAR format. Framework: Situation: a production API served by mobile clients (iOS and Android) with varying update adoption rates. A business requirement changed the order response: the 'price' field needed to become 'subtotal' (price before tax) with a new 'total' field. 'price' was used by mobile clients for displaying checkout. Renaming 'price' to 'subtotal' was a breaking change. Task: make the change without breaking active clients. Action: created v2 endpoint with the correct field names. Added 'subtotal' and 'total' to the v1 response as additive fields (non-breaking) while keeping 'price' as the old field (now a copy of subtotal for backward compat). Added Sunset header to v1 responses with 6-month sunset date. Notified mobile teams. Monitored v1 usage by app version using User-Agent parsing. Result: v2 adoption reached 85% within 3 months. The remaining 15% were on very old app versions (3+ years old). Sunset was extended by 3 months for those users. Total migration: 9 months. No client-visible outages. Lesson: adding fields to v1 while adding the v2 endpoint in parallel is the lowest-risk path. Clients not using v2 don't notice, clients migrating to v2 get the clean design."

*What separates good from great:* "The specific tactic of adding the new fields to v1 additively (while keeping the old field) and launching v2 simultaneously is the non-disruptive migration strategy. Tracking adoption by User-Agent to make the sunset decision data-driven shows production operational discipline."

---

**[SENIOR] Q7 - [CONCEPTUAL] "How does API versioning affect your OpenAPI/Swagger documentation?"**
> "Each API version should have its own OpenAPI specification. `/v1/openapi.yaml` documents v1. `/v2/openapi.yaml` documents v2. Don't try to document both in one spec - it adds complexity without clarity. Tooling: Swagger UI can be configured to load multiple specs with a version selector dropdown. API portals (Backstage, Stoplight, Kong Developer Portal) support multiple spec versions natively. The documentation strategy mirrors the versioning strategy: (1) Publish v2 spec when v2 launches. (2) Add deprecation note to v1 spec: `deprecated: true` at the API level or on specific operations. (3) When sunset approaches: add sunset date prominently in the v1 spec description and in the Swagger UI. (4) After sunset: remove v1 spec (or redirect to archived version). Automatically generating OpenAPI from code (Springdoc, Springfox): each controller version produces its own spec with `@OpenAPIDefinition` or path prefix filtering. Keep both specs accurate - a stale v1 spec that shows endpoints that no longer exist misleads migrating clients."

*What separates good from great:* "Recommending separate OpenAPI files per version (not one merged spec) and the specific UI tooling (Swagger UI version selector, API portals) shows you've managed multi-version documentation in practice."

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


# Pagination, Filtering, and Sorting

---

### 🎯 Model Answer

**30 seconds:**
> REST APIs use query parameters for pagination, filtering, and sorting on collection endpoints. Offset pagination (?page=2&size=20) is simple but unstable for large datasets. Cursor pagination (?cursor=abc&size=20) is stable but doesn't allow random page access. Filtering uses query parameters (?status=active&category=books). Sorting uses sort parameter (?sort=createdAt,desc). These three capabilities together make collection endpoints production-ready.

**3 minutes:**
> Pagination is non-negotiable for collection endpoints. GET /users without pagination attempts to return all users - which works for 100 users, fails at 1 million. Offset pagination (?page=2&size=20) is the simple approach: `LIMIT 20 OFFSET 40` in SQL. Easy to implement, allows random page access (jump to page 5). The problem: concurrent writes make it unstable. If 5 new users are inserted between page 1 and page 2 requests, the first 5 users on page 2 are the same as the last 5 on page 1 (the inserts pushed the window). Cursor pagination solves this by using the last-seen record ID as the anchor: `WHERE id > 100 LIMIT 20`. Stable regardless of concurrent inserts. No random access (can't jump to page 5 without cursoring through pages 1-4). Cursor encoding: base64 the cursor object to make it opaque (`eyJpZCI6MTAwfQ==`). Clients shouldn't construct cursors - they should only use cursors from the server's response. Filtering reduces the result set by field values. Query parameters are the standard: ?status=active&category=books&createdAfter=2026-01-01. Range filters: ?price[gte]=50&price[lte]=200. Full-text search: ?q=blue+shoes. Sorting: ?sort=price,asc&sort=createdAt,desc (multiple sorts supported). The response should include pagination metadata: total count (for offset pagination), next page cursor or link (for cursor pagination), and whether there are more pages.

**Blank Mind Recovery:**
**(1) Restate:** "Pagination, filtering, sorting - how to work with collections in REST."
**(2) First principles:** "Why is pagination needed? Can't return 1M users in one response. Why cursor vs offset? Stability under concurrent writes."
**(3) Bridge:** "Offset is like page numbers in a book. Cursor is like a bookmark - start exactly where you left off."

---

### 📘 Concept Explanation

**What it is:**
Pagination, filtering, and sorting are three capabilities that make REST collection endpoints practical for production use. Pagination limits response size. Filtering reduces the dataset. Sorting orders results.

**The problem it solves:**
Collections grow. GET /users for 10 million users is infeasible (bandwidth, memory, latency). Filtering avoids returning users the client doesn't need. Sorting avoids client-side sort computation. Pagination breaks large datasets into manageable chunks.

**How it works:**
```
Pagination patterns:

Offset: GET /users?page=2&size=20
  SELECT * FROM users
  ORDER BY id
  LIMIT 20 OFFSET 40
  
  Response:
  {
    "data": [...],
    "meta": { "total": 500, "page": 2,
              "size": 20, "pages": 25 }
  }

Cursor: GET /users?cursor=eyJpZCI6MTAwfQ==&size=20
  cursor decoded: {id: 100}
  SELECT * FROM users
  WHERE id > 100
  ORDER BY id
  LIMIT 21  (fetch 21 to detect hasNext)
  
  Response:
  {
    "data": [...20 items...],
    "meta": { "nextCursor": "eyJpZCI6MTIwfQ==",
              "hasNext": true }
  }

Filtering: GET /users?status=active&role=admin
  SELECT * FROM users
  WHERE status='active' AND role='admin'

Sorting: GET /users?sort=createdAt,desc
  SELECT * FROM users ORDER BY created_at DESC
```

> **Code walkthrough:** This Pagination, Filtering, and Sorting example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**
Cursor pagination and offset pagination have different index requirements. Offset pagination with `LIMIT OFFSET` causes a table scan to the offset position - slow for large offsets. `WHERE id > 100 LIMIT 20` uses an index seek - fast regardless of position. For large datasets (millions of rows), cursor pagination is an order of magnitude faster than offset for later pages.

**When to use it:**
Offset pagination: admin panels, reports where users need to jump to specific pages. Datasets where insertions/deletions during pagination are infrequent or where stability doesn't matter. Cursor pagination: user-facing feeds, infinite scroll, export jobs, large datasets, any scenario with concurrent writes.

**When NOT to use it:**
Don't allow clients to specify unlimited page sizes (`size=999999`). Cap page size at a reasonable maximum (100-1000 depending on record size). Don't expose raw OFFSET to clients - it leaks database implementation details and is exploitable for slow queries.

**Alternatives:**
- GraphQL connections (relay cursor-based pagination standard)
- Elasticsearch scroll/search_after (for search-based pagination)
- Database cursors for server-side streaming (JDBC scrollable ResultSet)

**First-principles derivation:**
A collection endpoint without pagination is implicitly a batch operation returning all data. As data grows, batch operations fail by size, timeout, and memory. Pagination converts a batch operation into an iterative operation: process manageable chunks. The choice between offset and cursor depends on whether you need positional access (offset) or stable sequential access (cursor).

---

### 💻 Code Example

```java
// Spring Data - offset pagination
@GetMapping("/users")
public ResponseEntity<PagedResponse<UserDto>> getUsers(
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "20") int size,
    @RequestParam(required = false) String status,
    @RequestParam(required = false) String sort) {

  // Validate and cap page size
  int cappedSize = Math.min(size, 100);
  
  // Build sort from query param
  Sort sorting = sort != null
      ? Sort.by(
          sort.endsWith(",desc")
              ? Sort.Direction.DESC
              : Sort.Direction.ASC,
          sort.split(",")[0])
      : Sort.by("createdAt").descending();

  Pageable pageable = PageRequest.of(
      page, cappedSize, sorting);

  // Dynamic filtering using Specification
  Specification<User> spec =
      status != null
          ? UserSpecification.hasStatus(status)
          : Specification.where(null);

  Page<User> result = userRepo.findAll(
      spec, pageable);

  return ResponseEntity.ok(
      PagedResponse.of(
          result.map(userMapper::toDto),
          result.getTotalElements(),
          result.getTotalPages()));
}

// Cursor-based pagination
@GetMapping("/feed")
public ResponseEntity<CursorPagedResponse<Post>> getFeed(
    @RequestParam(required = false) String cursor,
    @RequestParam(defaultValue = "20") int size) {

  Long afterId = cursor != null
      ? CursorCodec.decode(cursor)   // base64 decode
      : null;

  // Fetch size+1 to detect hasNext
  List<Post> posts = postRepo.findFeed(
      afterId, size + 1);

  boolean hasNext = posts.size() > size;
  List<Post> page = hasNext
      ? posts.subList(0, size)
      : posts;

  String nextCursor = hasNext
      ? CursorCodec.encode(
          page.get(page.size() - 1).getId())
      : null;

  return ResponseEntity.ok(
      CursorPagedResponse.of(
          page, nextCursor, hasNext));
}
```

> **Code walkthrough:** The offset pagination example caps page size at 100 (prevents `size=999999` DoS), builds dynamic filtering via JPA Specifications (avoids SQL injection), and uses Spring Data's built-in Pageable for `LIMIT/OFFSET` queries. The cursor pagination example fetches `size+1` records to cheaply detect whether there are more pages (if we got 21 when requesting 20, there are more). The cursor is base64-encoded to make it opaque (clients shouldn't construct cursors manually).

---

### 🎓 Answers by Seniority

**Junior / Mid:** "Pagination prevents returning all data at once. I use query parameters: page and size for offset pagination, cursor for cursor-based. Filtering uses query parameters too: /users?status=active. Sorting: /users?sort=name. For offset pagination, the response includes total count and page info. For cursor pagination, the response includes a nextCursor token to fetch the next page."

**Senior / Staff:** "The pagination strategy choice has significant database performance implications. Offset pagination with LIMIT OFFSET causes a full index scan to find the offset position - page 1000 requires scanning 20,000 rows to discard the first 19,980. This is O(N) per page for large offsets. Cursor pagination with WHERE id > ? uses an index seek - O(log N) regardless of position. For user-facing APIs with large datasets: always cursor. For admin reporting where users jump to specific pages: offset with indexed sorting columns. The design decision I always make explicit: what are the sort cursor fields? If you allow sorting by any field, cursor pagination requires that field to be in the cursor. Multi-field cursors (sort by createdAt DESC, id ASC) need both fields encoded. The id field is always the tiebreaker for stable pagination. Missing the tiebreaker causes duplicate records or skipped records when the primary sort field has duplicate values."

---

### ⚠️ Common Misconceptions

**Misconception:** "Cursor pagination is strictly better than offset pagination for all use cases."
Reality: Cursor and offset pagination each have genuine use cases. Cursor pagination prevents skipping/duplicating records on concurrent writes and is more database-efficient at high offsets. But it loses two capabilities that offset pagination provides: random access (jump to page 5 directly) and total count (you don't know how many total records exist without a separate COUNT query). Use cases where offset pagination is better: export features where the user selects a range ("show records 1000-2000"), admin panels with explicit page navigation, and UIs with "Go to page N" functionality. The pragmatic approach: provide cursor pagination for user-facing feeds and infinite scroll (where stability matters). Provide offset pagination for admin and reporting use cases (where random access matters). Many APIs provide both through different query parameter patterns.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Large page size request causes API timeout**

Symptoms: Some users report API timeouts. Investigation shows `size=10000` in the request logs. A client is requesting 10,000 records per page, causing a slow database query and response serialization that exceeds the 30-second timeout.

Root cause: No server-side cap on the requested page size. One legitimate client (a data export script) is requesting very large pages. The script works fine for 100 records, fails for 10,000.

Diagnosis: `curl /users?size=10000` - measure response time. Check database slow query log for `LIMIT 10000` queries.

Fix: Cap page size server-side: `int cappedSize = Math.min(requestedSize, 100)`. Return the actual page size used in the response metadata so clients know what cap was applied. For legitimate bulk export needs: provide a separate export endpoint with streaming (StreamingResponseBody writing to OutputStream) that can handle large datasets asynchronously.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Comparison | 3 min | 2 |
| Mechanism | 3 min | 1 |
| Scenario | 3 min | 2 |
| Debugging | 2 min | 1 |
| Design | 3 min | 1 |
| Trade-off | 3 min | 1 |
| Behavioral | 2 min | 1 |

**[JUNIOR] Q1 - [CONCEPTUAL] "What is the difference between cursor and offset pagination? When do you use each?"**
> "Offset pagination: `LIMIT 20 OFFSET 40` in SQL. Page 3 of size 20 means skip the first 40 records. Simple to implement. Allows random page access (jump to any page). Returns total count. The database problem: OFFSET causes a full index scan to the offset position. Page 1,000 of size 20 means scanning 19,980 rows. O(N) per request for large N. Also unstable: concurrent inserts/deletes shift the window. Cursor pagination: `WHERE id > 100 LIMIT 20`. Anchors on the last-seen record. No count of skipped rows. O(log N) database performance regardless of position. Stable under concurrent writes. The tradeoffs: offset has total count and random access. Cursor doesn't. Cursor is more database-efficient and stable. Use cursor for: infinite scroll, user feeds, export jobs, any scenario with concurrent writes. Use offset for: admin panels with page navigation, reports with 'go to page N', scenarios where the user needs total count to understand their position. My default: cursor for user-facing APIs, offset for internal/admin."

*What separates good from great:* "The O(N) vs O(log N) database complexity analysis is what shows you understand why cursor is more scalable, not just that it's more 'correct.'"

---

**[JUNIOR] Q2 - [ARCHITECTURE] "How do you design a sort cursor that supports multiple sort fields?"**
> "When clients can sort by any field, the cursor must encode enough information to resume from the exact position regardless of sort order. Problem: sort by createdAt DESC. The cursor encodes the last-seen createdAt value. But if two records have the same createdAt: which one comes first? The sort is ambiguous. The solution: always include the primary key (id) as a tiebreaker in the sort and the cursor. Sort: `createdAt DESC, id ASC`. Cursor: `{createdAt: '2026-01-01T10:00:00Z', id: 100}`. Query: `WHERE createdAt < '2026-01-01T10:00:00Z' OR (createdAt = '2026-01-01T10:00:00Z' AND id > 100) ORDER BY createdAt DESC, id ASC LIMIT 20`. This keyset pagination query handles ties correctly. The SQL is more complex than simple cursor but still uses indexes efficiently. Cursor encoding: serialize to JSON, base64-encode to make opaque. The client receives `eyJjcmVhdGVkQXQiOiIuLi4iLCJpZCI6MTAwfQ==` and sends it back on the next request. The server decodes and uses. Never trust client-constructed cursors - validate and use only server-generated cursor values."

*What separates good from great:* "The keyset pagination SQL (`WHERE createdAt < X OR (createdAt = X AND id > Y)`) and the tiebreaker id requirement are implementation details that candidates who have built cursor pagination in production know. The security note about not trusting client-constructed cursors shows security thinking."

---

**[JUNIOR] Q3 - [CONCEPTUAL] "A user reports they're missing records in a paginated export. What do you investigate?"**
> "Missing records in pagination is usually one of three causes: (1) Offset pagination with concurrent writes: the most common cause. While the client was paginating (page 1, page 2, page 3...), new records were inserted. The inserts shifted the OFFSET window. Records on the boundary between page N and N+1 were either skipped or duplicated. Diagnosis: check if the export was using offset pagination. Check if there was concurrent write activity during the export. Fix: use cursor pagination for exports. (2) Deleted records: records were deleted between page requests. Cursor pagination handles this correctly (the cursor anchors on id, deleted records don't shift the window). Offset pagination may skip records or return duplicates. (3) Sorting instability: sorting by a non-unique field (e.g., updatedAt) with offset pagination. If two records have the same updatedAt, the database may return them in different order on different requests. Diagnosis: check if the sort field has many duplicate values. Fix: add id as tiebreaker to the sort. Always. For the immediate fix: re-run the export with cursor pagination and include a unique sort key. For permanent fix: switch all export endpoints to cursor pagination."

*What separates good from great:* "Identifying three distinct root causes (concurrent inserts, deletes, sort instability) and having a fix for each shows production debugging experience. The sort instability cause (non-unique sort field without tiebreaker) is the subtle one most candidates miss."

---

**[MID] Q4 - [HANDS-ON] "How do you implement full-text search in a REST API collection endpoint?"**
> "Full-text search via REST collection endpoint: `GET /products?q=blue+leather+shoes`. The q parameter is the search query. Implementation layers: (1) Database full-text search: PostgreSQL tsvector + tsquery. `WHERE to_tsvector('english', name || ' ' || description) @@ plainto_tsquery('english', ?)`. Reasonable for small to medium datasets (< 10M records), no extra infrastructure. (2) Elasticsearch/Opensearch: dedicated search engine. Query DSL sent from the API to Elasticsearch. Better relevance scoring, faceting, autocomplete, synonym support. More infrastructure. (3) Algolia/Typesense: hosted search service. Fast, relevant, zero infrastructure maintenance. Requires data sync. API design: `GET /products?q=shoes&category=footwear&sort=relevance`. `q` is the free-text query. `category` is a filter applied in addition to the full-text search. `sort=relevance` uses the search engine's relevance score. Include `highlight` in the response: `{name: 'Blue <em>Leather</em> <em>Shoes</em>', score: 0.95}`. Don't expose search engine query syntax directly in the URL. If you switch from Elasticsearch to Algolia, the URL should stay the same."

*What separates good from great:* "The abstraction layer recommendation (don't expose search engine query syntax in the URL) is the API design principle that prevents lock-in. Mentioning PostgreSQL tsvector as a viable small-scale option (not just Elasticsearch) shows pragmatism."

---

**[MID] Q5 - [CONCEPTUAL] "How does pagination interact with API rate limiting?"**
> "Pagination reduces per-request payload size but increases the number of requests needed to fetch all data. A client that needs all 10,000 users makes 500 requests (at size=20). Rate limiting must account for this. The design tension: set rate limit at 100 req/min. The export use case needs 500 requests. The export will hit the rate limit and fail. Solutions: (1) Higher rate limit for authenticated bulk export use case: a specific 'export' API key with a higher rate limit tier. (2) Dedicated export endpoint: `POST /exports/users` creates an async export job. The client polls `GET /exports/{jobId}` for completion. `GET /exports/{jobId}/download` returns the file. Rate limit the export creation (1 per hour), not the download. (3) Streaming response: `GET /users?export=true` streams the entire dataset as newline-delimited JSON or CSV. One request, streaming response. Rate limit: 1 concurrent export per API key. The underlying principle: pagination is not the right tool for bulk data export. It's designed for interactive browsing (user sees 20 users at a time). For bulk data: use async export jobs or streaming. The API should make this explicit with a separate export endpoint."

*What separates good from great:* "The observation that pagination is for interactive browsing, not bulk export, and that a dedicated async export endpoint is the correct solution is the system design insight. Rate limiting for export is a different concern than rate limiting for browsing."

---

**[MID] Q6 - [CONCEPTUAL] "How do you handle sparse fieldsets in collection responses?"**
> "Sparse fieldsets: the client requests only specific fields to reduce response size. Useful for mobile clients (bandwidth), list views (only need id + name for a list, not all 50 fields), and clients building aggregations. API design: `GET /users?fields=id,name,email` returns only those fields. Also called 'projections.' Implementation in Spring Data JPA: `@ProjectedPayload` interface or `Projections.fields()` with dynamic projections. The trade-off: sparse fieldsets increase API complexity. The server must dynamically serialize only the requested fields. JSON serialization libraries (Jackson) require dynamic views or custom serializers for this. Performance: reduces response payload (network cost). Potentially reduces database queries if using `SELECT id, name, email FROM users` instead of `SELECT *`. GraphQL is the natural evolution: sparse fieldsets are built into GraphQL's core (clients always specify fields). REST sparse fieldsets are partial adoption of GraphQL's query model. My recommendation: implement sparse fieldsets if you have mobile clients where bandwidth is a documented concern. For server-to-server APIs with reliable connections: the complexity cost exceeds the bandwidth benefit."

*What separates good from great:* "Framing sparse fieldsets as REST's partial adoption of GraphQL's model shows architectural perspective. The pragmatic recommendation (implement for mobile bandwidth concerns, skip for server-to-server) shows judgment."

---

**[SENIOR] Q7 - [ARCHITECTURE] "Design the pagination response format for a collection endpoint."**
> "Recommended pagination response envelope: `{data: [...items...], meta: {pagination: {...}}}`. For offset pagination: `{data: [...], meta: {page: 2, size: 20, total: 500, pages: 25, hasNext: true, hasPrev: true}}`. For cursor pagination: `{data: [...], meta: {nextCursor: 'eyJpZCI6MTIwfQ==', prevCursor: 'eyJpZCI6MTAwfQ==', hasNext: true}}`. Also support Link header (RFC 5988) for programmatic navigation: `Link: </users?cursor=abc>; rel='next', </users?cursor=xyz>; rel='prev'`. Link header is what GitHub uses for pagination. The data + meta envelope pattern is widely adopted (JSON:API, GitHub, Stripe). Advantages: consistent structure for all collection endpoints, easy to extend meta without changing data structure, libraries can parse generic pagination from the meta field. Avoid: embedding pagination in the root object alongside data items (collision risk), returning just an array (no pagination metadata), pagination fields named differently per endpoint (page vs offset vs skip vs page_number). Consistency matters: all collection endpoints in the API should use the same pagination envelope."

*What separates good from great:* "Mentioning the RFC 5988 Link header as an alternative (and that GitHub uses it) shows knowledge of the header-based pagination approach. Recommending consistent structure across all collection endpoints shows API design discipline."

---

### ⚖️ Comparison Table

| Strategy | Random Access | Stable Under Writes | Database Performance | Total Count |
|---|---|---|---|---|
| Offset (?page=N) | Yes | No | O(N) for large offsets | Yes |
| Cursor (?cursor=X) | No | Yes | O(log N) always | No |
| Keyset (WHERE id > N) | No | Yes | O(log N) always | No |
| Seek (composite cursor) | No | Yes | O(log N), index-optimal | No |

**The deciding factor:** Use cursor/keyset for user-facing feeds and exports (stability + performance). Use offset for admin interfaces and reports (random access + total count).

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



