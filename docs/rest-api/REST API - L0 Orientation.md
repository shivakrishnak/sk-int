---
layout: default
title: "REST API - L0 Orientation"
parent: "REST API Design and HTTP"
grand_parent: "SK Interview"
nav_order: 1
permalink: /rest-api/l0-orientation/
---

# REST Architectural Style Overview

🎯 Interview Weight: medium - Foundation for all API design
questions. Asked to establish baseline understanding before
deeper API design discussions.

---

### 🎯 Model Answer

**30 seconds:**
> REST (Representational State Transfer) is an architectural style
> for distributed systems defined by Roy Fielding in 2000. It uses
> HTTP as the transport, models everything as a resource identified
> by a URL, and uses standard HTTP methods (GET, POST, PUT, DELETE)
> to represent operations. REST is not a standard or protocol - it
> is a set of constraints that, when applied, produce a scalable,
> stateless, uniform interface.

**3 minutes (Senior):**
> REST is fundamentally about resources and their representations.
> A resource is any concept that can be named: an order, a product,
> a user. A URL identifies the resource. The HTTP method indicates
> what to do with it. The response body is a representation of the
> resource's current state (in JSON, XML, etc.).
>
> The key constraints that define REST:
>
> Client-Server separation: the client and server evolve independently.
> The client only knows the URL and the response format - not how the
> server stores data.
>
> Stateless: each request contains all the information needed to
> process it. The server stores no client session state between
> requests. This enables horizontal scaling - any server instance
> can handle any request.
>
> Cacheable: responses can be marked cacheable with `Cache-Control`
> headers. Caching reduces load and improves performance.
>
> Uniform Interface: the most important REST constraint. It standardizes
> communication: resource identification via URL, manipulation via
> representations, self-descriptive messages, HATEOAS.
>
> These constraints give REST its scalability and simplicity. What
> REST gains: simplicity, tooling (every HTTP tool works), massive
> ecosystem support. What REST sacrifices: efficiency (JSON/XML overhead
> vs binary protocols), strict type safety, real-time updates (HTTP
> is request-response).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about REST - what it is and why
it is the dominant API style."

**(2) First principles:** "Resources on the web need addresses (URLs)
and operations. HTTP already provides both. REST says: map your
domain resources to URLs, use HTTP methods as the operations, use
HTTP status codes as the result."

**(3) Bridge:** "Like a library catalog: every book has a call number
(URL), there are standard operations (checkout, return, reserve),
and the state (available, checked out) is the resource's representation."

---

### 📘 Concept Explanation

**Six REST constraints (Fielding, 2000):**

```
1. Client-Server
   Separation of concerns: UI vs data storage
   Enables independent evolution of client and server

2. Stateless
   No session state on server between requests
   Each request is self-contained
   Enables horizontal scaling

3. Cacheable
   Responses marked as cacheable or not
   Reduces bandwidth and server load

4. Uniform Interface (MOST IMPORTANT)
   - Resource identification (URLs)
   - Manipulation via representations (CRUD via HTTP)
   - Self-descriptive messages (Content-Type headers)
   - HATEOAS (hypermedia links in responses)

5. Layered System
   Client cannot tell if it is talking to origin server
   or intermediary (proxy, CDN, API gateway)

6. Code on Demand (optional)
   Server can send executable code to client (JavaScript)
```

**REST vs HTTP:**
REST uses HTTP as its transport. An HTTP API is not automatically
RESTful. REST is a set of constraints; HTTP is a protocol. A
fully RESTful API follows all six constraints. Most "REST" APIs
are actually REST-ish (they use HTTP + JSON without following
all constraints, especially HATEOAS).

**The key insight:**
REST's stateless constraint is its most commercially important
property. Stateless servers can be scaled horizontally without
sticky sessions. Any load balancer can route any request to any
server instance. This is why REST scales to millions of concurrent
users.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> REST is an architectural style using HTTP for API design. It
> treats everything as a resource identified by a URL and uses
> HTTP methods (GET, POST, PUT, DELETE) as operations. REST is
> stateless - no session state on the server - and uses standard
> HTTP status codes to communicate results.

---

**Senior / Staff (5+ years):**
> REST is a set of six architectural constraints. The two most
> important for production systems: Stateless (enables horizontal
> scaling - any server handles any request) and Uniform Interface
> (standardizes client-server communication so any HTTP client
> can use any REST API). The practical implication of Stateless:
> never store session state in the application tier. Use JWTs or
> stateless tokens for auth. Push state to the database or cache.

---

### ⚖️ Comparison Table

| API Style | Protocol | Format | Strengths | Weaknesses |
|-----------|---------|--------|-----------|------------|
| REST | HTTP | JSON/XML | Simple, universal tooling, cacheable | Verbose, no types, over/under-fetching |
| gRPC | HTTP/2 | Protobuf (binary) | Fast, type-safe, streaming | Less browser-friendly, steeper learning curve |
| GraphQL | HTTP | JSON | Precise data fetching, flexible | Complex caching, N+1 problem |
| SOAP | HTTP/TCP | XML | WS-* standards, enterprise features | Verbose, complex |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | REST constraints + HTTP methods + JSON |
| Mid | 4 min | Stateless constraint + uniform interface |
| Senior | 5 min | REST vs other styles + trade-offs |

---

**[ARCHITECTURE] What does "stateless" mean in REST and why
does it matter?** `[MID]`

*Why they ask:* Stateless is the REST constraint with the most
operational impact. Tests whether you understand REST deeply
or superficially.

*Likely follow-up:* "How do you handle authentication without
server-side sessions?"

Stateless means the server does not store any client session
state between requests. Every request contains all the information
the server needs to process it: authentication credentials (JWT
Bearer token), request context (in URL and headers), and request
body (for write operations). There is no `HttpSession` on the
server that holds "this user is logged in with these permissions."
Why it matters: with no server-side session state, any server
instance in a load-balanced cluster can handle any request from
any client. You can add or remove server instances freely. If a
server instance crashes, the client re-sends its request to another
instance - no session data is lost because there was none.
Authentication: use JWTs. The JWT contains the user's identity
and claims, signed with a server secret. The server validates
the JWT signature on every request without querying a session
store. The JWT is the complete authentication context, sent by
the client with every request.

*What separates good from great:* "No session state" without
explaining how authentication works stateless-ly and why this
enables horizontal scaling.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Six constraints + stateless + cacheable |
| Bar Raiser | REST vs SOAP evolution + Fielding's constraints |

---

---

# HTTP Protocol Fundamentals

🎯 Interview Weight: high - HTTP knowledge underlies all REST
API work. Asked early in interviews to establish baseline.

---

### 🎯 Model Answer

**30 seconds:**
> HTTP (HyperText Transfer Protocol) is a request-response protocol.
> Each request has: method (GET/POST/etc.), URL, headers (metadata),
> and optionally a body. Each response has: status code (200/404/etc.),
> headers, and optionally a body. HTTP/1.1 is the baseline; HTTP/2
> multiplexes multiple requests over one connection; HTTP/3 uses
> QUIC (UDP-based) for lower latency.

**3 minutes (Senior):**
> HTTP fundamentals every API developer must know:
>
> Request structure: method + URL + HTTP version (first line),
> headers (Host, Content-Type, Authorization, Accept), blank line,
> optional body.
>
> Response structure: HTTP version + status code + reason phrase
> (first line), headers (Content-Type, Cache-Control, ETag), blank
> line, optional body.
>
> HTTP versions and their significance:
>
> HTTP/1.1 (1997, still dominant): persistent connections (keep-alive),
> chunked transfer encoding. Limitation: head-of-line blocking - if one
> request is slow, subsequent requests on the same connection wait.
>
> HTTP/2 (2015): multiplexing - multiple request/response streams over
> one TCP connection. Binary framing. Header compression (HPACK).
> Server push. Eliminates head-of-line blocking at HTTP layer. 99%+
> of modern HTTPS traffic uses HTTP/2.
>
> HTTP/3 (2022): uses QUIC over UDP instead of TCP. Eliminates TCP
> head-of-line blocking (which persisted in HTTP/2 at the TCP level).
> Faster connection establishment (0-RTT). Critical for mobile users
> with high packet loss.
>
> HTTP headers worth knowing: `Content-Type` (MIME type of body),
> `Accept` (what the client accepts), `Authorization` (Bearer token,
> Basic auth), `Cache-Control` (caching directives), `ETag` (resource
> version for conditional requests), `If-None-Match` (conditional
> GET), `Location` (redirect target), `Retry-After` (rate limit
> recovery), `X-Request-ID` (distributed tracing).

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the HTTP protocol fundamentals
that underlie REST APIs."

**(2) First principles:** "HTTP is request-response. Request says
what you want (method + URL) and how you want it (Accept header).
Response says whether it worked (status code) and here it is (body)."

**(3) Bridge:** "Like ordering at a restaurant: request = order
(method: 'give me', URL: 'the burger'); response = delivery (status:
'here is the burger' = 200, or 'we are out of burgers' = 404)."

---

### 📘 Concept Explanation

**HTTP request structure:**

```
POST /api/v1/orders HTTP/1.1
Host: api.example.com
Content-Type: application/json
Authorization: Bearer eyJhbGci...
Accept: application/json
X-Request-ID: 4bf92f35-77b3-4da6-a123

{
  "productId": "PROD-001",
  "quantity": 2,
  "customerId": "CUST-123"
}
```

**HTTP response structure:**

```
HTTP/1.1 201 Created
Content-Type: application/json
Location: /api/v1/orders/ORD-789
ETag: "version-1"
Cache-Control: no-cache

{
  "orderId": "ORD-789",
  "status": "PENDING",
  "createdAt": "2024-01-15T10:23:45Z"
}
```

**HTTP/1.1 vs HTTP/2 vs HTTP/3:**

```
HTTP/1.1:
  - Text-based protocol
  - One request per TCP connection (without keep-alive)
  - Keep-alive: one request at a time per connection
  - Head-of-line blocking: slow request blocks others

HTTP/2:
  - Binary framing
  - Multiplexing: multiple streams over one connection
  - Header compression (HPACK)
  - Server push (server sends resources before requested)
  - TCP head-of-line blocking remains

HTTP/3:
  - Built on QUIC (UDP-based)
  - No TCP head-of-line blocking
  - 0-RTT connection establishment
  - Resilient to packet loss (important for mobile)
```

**The key insight:**
HTTP/2 multiplexing is why modern REST APIs perform well without
extensive connection pooling tuning. A single HTTP/2 connection
can carry hundreds of concurrent request streams. A single HTTP/1.1
connection carries only one request at a time.

---

### 💻 Code Example

**HTTP request/response inspection - Spring Boot:**

```java
// Spring Boot: accessing raw HTTP request details

@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {

    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(
        @RequestBody @Valid CreateOrderRequest request,
        @RequestHeader("X-Request-ID")
            String requestId,
        @RequestHeader(
            value = "Accept-Language",
            defaultValue = "en"
        ) String language,
        HttpServletRequest httpRequest
    ) {
        // HTTP method available programmatically
        String method = httpRequest.getMethod(); // POST

        // Setting response headers explicitly
        OrderResponse order = orderService.create(request);

        return ResponseEntity
            .status(HttpStatus.CREATED)  // 201
            .location(URI.create(
                "/api/v1/orders/" + order.getOrderId()
            ))
            .header("X-Request-ID", requestId)
            .eTag("\"" + order.getVersion() + "\"")
            .body(order);
    }

    // Conditional GET using ETag
    @GetMapping("/{orderId}")
    public ResponseEntity<OrderResponse> getOrder(
        @PathVariable String orderId,
        @RequestHeader(
            value = "If-None-Match",
            required = false
        ) String ifNoneMatch
    ) {
        Order order = orderService.findById(orderId);
        String currentETag =
            "\"" + order.getVersion() + "\"";

        // If ETag matches: return 304 (not modified)
        if (currentETag.equals(ifNoneMatch)) {
            return ResponseEntity
                .status(HttpStatus.NOT_MODIFIED)
                .eTag(currentETag)
                .build();
        }

        return ResponseEntity.ok()
            .eTag(currentETag)
            .body(toResponse(order));
    }
}
```

> **Code walkthrough:** The `createOrder` endpoint extracts custom
> headers (`X-Request-ID` for distributed tracing, `Accept-Language`
> for localization). The response sets: 201 status, `Location` header
> pointing to the created resource, `X-Request-ID` echoed back for
> client correlation, and `ETag` for subsequent conditional requests.
> The `getOrder` endpoint implements conditional GET with `If-None-Match`:
> if the client sends the ETag it received in a previous response
> and the resource has not changed, the server returns 304 with no
> body. This saves bandwidth and is the correct implementation of
> HTTP caching for mutable resources.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> HTTP is a request-response protocol. Request has method, URL,
> headers, and body. Response has status code, headers, and body.
> Common status codes: 200 (success), 201 (created), 400 (bad input),
> 401 (not authenticated), 403 (not authorized), 404 (not found),
> 500 (server error). HTTP/2 improves performance via multiplexing
> (multiple requests over one connection).

---

**Senior / Staff (5+ years):**
> The HTTP features I use consistently in production: ETags for
> conditional requests (saves bandwidth, enables optimistic locking),
> Cache-Control for caching strategy, `Location` header for POST
> responses (points to the created resource), `Retry-After` for
> rate limit responses. HTTP/2 is the default in modern deployments;
> HTTP/3 matters for mobile-heavy APIs where packet loss is common.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | Request/response structure + status codes |
| Mid | 4 min | Headers + HTTP/2 multiplexing |
| Senior | 5 min | Conditional requests + caching headers |

---

**[DEBUGGING] How do you debug an intermittent HTTP 503 error
in production?** `[SENIOR]`

*Why they ask:* HTTP debugging is an operational skill.

*Likely follow-up:* "How do you distinguish a 503 from the origin
vs from a load balancer?"

503 Service Unavailable can come from: (1) the origin server is
returning 503 (health check failing, connection pool exhausted,
too many threads), (2) the load balancer or API gateway returns
503 because no upstream is healthy. Distinguish via: check the
response headers. Load balancer 503s often include a `Via` or
`X-Forwarded-For` header with the gateway's identity and missing
application-specific headers. Origin 503s include your application
headers. Check access logs at each layer: load balancer logs show
if the upstream returned the error or the LB generated it.
For origin 503s: check the actuator health endpoint
(`/actuator/health`), check thread pool active threads and queue
depth, check HikariCP connection pool pending. For intermittent
503s: correlate with traffic spikes (connection pool exhaustion
under load) or scheduled tasks (GC pressure, batch jobs).

*What separates good from great:* "Check the server logs" without
the systematic layer-by-layer isolation approach.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | HTTP/2 multiplexing + conditional requests |
| Bar Raiser | HTTP/3 QUIC + TCP head-of-line blocking |

---

---

# API-First Design Philosophy

🎯 Interview Weight: medium - API-First is an organizational
approach that improves API quality. Asked in architect-level
interviews.

---

### 🎯 Model Answer

**30 seconds:**
> API-First means designing the API contract (OpenAPI spec) before
> writing any implementation code. The API contract is the source
> of truth. Clients and servers generate code from it. Teams align
> on the contract before development begins. This prevents the common
> failure: the API is designed by looking at the implementation rather
> than by designing for consumers.

**3 minutes (Senior):**
> API-First design inverts the traditional workflow. Traditional:
> (1) build the backend, (2) expose whatever the backend does as
> an API, (3) document it (often inconsistently). This produces
> APIs that are implementation-driven rather than consumer-driven.
>
> API-First: (1) design the API contract (OpenAPI YAML), (2) review
> with consumers (frontend team, mobile team, external partners),
> (3) generate server stubs and client SDKs from the spec, (4) build
> the implementation behind the spec. The spec is the contract -
> the implementation must match it.
>
> The benefits:
>
> Parallel development: once the contract is agreed, frontend and
> backend teams develop in parallel. Frontend uses a mock server
> (Prism, WireMock) that serves responses matching the spec. Backend
> implements the contract. Integration at the end is smooth.
>
> Better API design: forcing the design review before implementation
> catches consumer-unfriendly decisions (inconsistent naming, missing
> fields, wrong status codes) before they are baked into code.
>
> Contract enforcement: automated tests verify the implementation
> matches the spec on every build. Dredd, or Spring REST Docs, or
> Pact verify this.
>
> The discipline: the spec comes first, always. Implementation that
> diverges from the spec is a bug to fix in the implementation,
> not a spec change.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about API-First - designing
the API contract before implementation."

**(2) First principles:** "An API is a product for consumers.
Product design starts with requirements, not with the implementation.
API-First forces the requirements (contract) conversation before
building."

**(3) Bridge:** "Like an architect designing a building before
construction: the blueprints (API spec) are reviewed and approved
before any concrete is poured. Changes to the blueprints are easy;
changes after construction are expensive."

---

### 📘 Concept Explanation

**API-First workflow:**

```
Traditional (Code-First):
  1. Implement service logic
  2. Expose via REST endpoints
  3. Document (sometimes)
  4. Consumers adapt to whatever exists
  -> Result: implementation-driven, consumer-unfriendly

API-First (Contract-First):
  1. Write OpenAPI spec (YAML)
  2. Review with all consumers
  3. Generate: server stubs + client SDKs + mock server
  4. Parallel development: backend implements, frontend
     uses mock server
  5. Integration: implementation matches the contract
  -> Result: consumer-driven, consistent, parallel delivery
```

**The key insight:**
The contract is the shared understanding. Without a contract,
"we agreed" means different things to different teams. With an
OpenAPI spec: "we agreed" means the spec version X is the truth.
Any deviation from the spec is a bug, not a feature.

**Tools for API-First:**
- OpenAPI Specification (OAS 3.x): contract format
- Swagger Editor / Stoplight: visual OpenAPI design
- OpenAPI Generator: generates stubs in 50+ languages
- Prism: mock server from OpenAPI spec
- Dredd: contract testing (spec vs implementation)

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | API-First definition + benefits |
| Mid | 3 min | Contract workflow + parallel development |
| Senior | 5 min | Contract enforcement + governance |

---

**[TRADE-OFF] What are the disadvantages of API-First and
when would you NOT use it?** `[SENIOR]`

*Why they ask:* Tests whether you can assess trade-offs, not just
advocate for a pattern.

*Likely follow-up:* "When is code-first more appropriate?"

API-First disadvantages: (1) Upfront investment: writing a
complete OpenAPI spec before any code is slower to start than
writing a quick prototype. For exploratory work (new features,
uncertain requirements), the spec is a premature commitment.
(2) Spec drift: in fast-moving teams, the implementation diverges
from the spec faster than the spec can be updated. This requires
discipline and automated contract testing to catch. (3) Design
overhead: good API design requires domain knowledge and consumer
perspective. A poorly designed spec is worse than a well-designed
ad-hoc API. (4) Rigidity: if the spec is approved by 5 teams, any
spec change requires re-approval. This adds process overhead that
can slow iteration. When to NOT use API-First: (1) Internal
prototypes and spikes where the API shape is exploratory. Build
first, formalize the spec after the shape stabilizes. (2) Teams
with excellent existing API patterns and discipline (may not need
formal spec process). When to use API-First: (1) Public APIs
(external developers depend on stability). (2) Multiple teams
consuming the same API in parallel. (3) Mobile APIs (mobile app
releases are slow to update; API changes must not break old clients).

*What separates good from great:* "API-First is always better"
without the trade-offs and specific conditions where code-first
is more appropriate.

---

---

# REST vs RPC vs GraphQL Landscape

🎯 Interview Weight: high - Protocol selection is an architect-level
decision. Asked in senior interviews to test whether you can
justify protocol choice rather than defaulting to REST for everything.

---

### 🎯 Model Answer

**30 seconds:**
> REST is the default for public APIs and service-to-browser
> communication. gRPC is preferred for internal service-to-service
> communication where performance and type safety matter. GraphQL
> solves the specific problem of multiple clients with different
> data requirements from the same API. Each has a clear use case;
> the mistake is applying one style universally.

**3 minutes (Senior):**
> REST: the universal default. Every tool supports it. Every developer
> knows it. Cacheable. Browser-native. Use REST for: public APIs,
> external developer integrations, browser-facing APIs, any API where
> simplicity and ecosystem support outweigh efficiency.
>
> gRPC (Google Remote Procedure Call): uses HTTP/2 + Protocol Buffers.
> Binary wire format - 3-10x smaller than JSON. Strongly typed schema
> (`.proto` files). Bidirectional streaming. Use gRPC for:
> internal microservice-to-service communication, high-throughput APIs
> (millions of calls/second), APIs requiring streaming, polyglot systems
> where generated type-safe clients in multiple languages matter.
> Limitation: not browser-native without gRPC-web proxy.
>
> GraphQL: a query language for APIs. Clients specify exactly what
> data they need. Single endpoint. The server resolves the query
> against a typed schema. Eliminates over-fetching (getting fields
> you do not need) and under-fetching (needing multiple requests).
> Use GraphQL for: consumer-driven APIs where multiple clients
> (mobile, web, partner) need different subsets of data; APIs for
> complex, interconnected data models. Limitations: no HTTP caching
> (all queries are POST or dynamic GET), complex query execution
> can cause N+1 database problems, learning curve for server and client.
>
> The decision framework: public API = REST. Internal microservices
> = gRPC. Multiple different consumers of the same data = GraphQL.
> Mixed: BFF (Backend for Frontend) - one GraphQL layer composing
> multiple REST/gRPC backends, each client uses GraphQL with its
> own query.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about when to choose REST vs gRPC
vs GraphQL."

**(2) First principles:** "Choose the API style based on who the
consumer is and what they need. Browser consumers: REST (native).
Internal services with high throughput: gRPC (fast, typed). Multiple
consumers with different data needs: GraphQL (flexible)."

**(3) Bridge:** "Like shipping methods: standard mail (REST) is
universal and everyone understands it. Express courier (gRPC) is
fast and direct. Custom delivery (GraphQL) gets exactly what each
recipient needs at their door."

---

### 📘 Concept Explanation

**Decision matrix:**

```
Consumer Type -> Recommended Protocol:

  Browser (direct)
    -> REST (JSON over HTTP/1.1 or HTTP/2)
    -> GraphQL (single endpoint, no REST design needed)

  Internal microservices (Java to Java)
    -> gRPC (HTTP/2, Protobuf, 3-10x smaller payloads)
    -> REST (if simplicity preferred over performance)

  Mobile (iOS/Android)
    -> GraphQL (multiple screens need different data subsets)
    -> REST (with field filtering)

  External partners/public API
    -> REST (universal tooling, well-understood)

  Real-time data (streaming)
    -> gRPC (bidirectional streaming)
    -> WebSocket (if browser-native required)
    -> Server-Sent Events (server-to-client only)
```

**The key insight:**
The biggest REST vs GraphQL decision factor: if you have one
backend and many different types of clients, GraphQL solves the
data-fetching problem cleanly. If you have one type of client
consuming one backend, REST is simpler.

**N+1 problem in GraphQL:**
GraphQL resolvers execute per-field. A query for 100 users with
their orders can trigger 100 + 1 database queries (1 for users,
100 for each user's orders). Solved by DataLoader (batching)
which coalesces multiple individual queries into one bulk query.

---

### 💻 Code Example

**BAD - N+1 GraphQL resolver:**

```java
// BAD: N+1 query problem
// For 100 users, executes 101 database queries

@Component
public class UserResolver
    implements GraphQLResolver<User> {

    private final OrderRepository orderRepo;

    // Called once PER USER - N queries for N users
    public List<Order> getOrders(User user) {
        return orderRepo
            .findByCustomerId(user.getId()); // N queries
    }
}
```

**GOOD - DataLoader batching:**

```java
// GOOD: DataLoader batches N queries into 1

@Component
public class UserOrderDataLoader
    implements BatchLoaderWithContext<
        String, List<Order>
    > {

    private final OrderRepository orderRepo;

    @Override
    public CompletionStage<List<List<Order>>> load(
        List<String> userIds,
        BatchLoaderEnvironment env
    ) {
        // ONE query for ALL user IDs
        Map<String, List<Order>> ordersByUser =
            orderRepo.findByCustomerIds(userIds)
                .stream()
                .collect(groupingBy(Order::getCustomerId));

        // Return in the same order as input userIds
        return completedFuture(
            userIds.stream()
                .map(id -> ordersByUser.getOrDefault(
                    id, emptyList()
                ))
                .collect(toList())
        );
    }
}
```

> **Code walkthrough:** The BAD resolver calls the database once
> per user - for 100 users, this is 101 database queries. The GOOD
> DataLoader receives all user IDs in a single batch, executes ONE
> query with `WHERE customer_id IN (...)`, then maps results back
> to the original order. The DataLoader is registered per GraphQL
> request (request-scoped). GraphQL's execution engine automatically
> batches all `getOrders` calls within a request before executing them.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The protocol selection decision I apply: who are the consumers?
> REST for public/external (universal), gRPC for internal
> service-to-service (performance), GraphQL for APIs consumed by
> multiple client types with different data needs. I have seen teams
> force GraphQL onto internal microservices and REST onto mobile apps
> with many screen types - both are mismatched to the use case.

---

### ⚖️ Comparison Table

| Protocol | Wire Format | Streaming | Browser | Caching | Use Case |
|----------|-----------|---------|---------|---------|---------|
| REST | JSON (text) | No (SSE for server-push) | Native | HTTP cache | Public APIs, external |
| gRPC | Protobuf (binary) | Yes (bidirectional) | Needs proxy | No | Internal, high-throughput |
| GraphQL | JSON (text) | Yes (subscriptions) | Native | Limited | Multi-client, flexible data |
| SOAP | XML (text) | No | Native | No | Enterprise/legacy |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | REST vs gRPC basic comparison |
| Mid | 4 min | GraphQL use case + N+1 problem |
| Senior | 6 min | Protocol selection decision framework |

---

**[TRADE-OFF] When would you use GraphQL in a microservices
system?** `[SENIOR]`

*Why they ask:* GraphQL in microservices has specific use cases.

*Likely follow-up:* "How does the BFF pattern use GraphQL?"

Use GraphQL in microservices via the BFF (Backend for Frontend)
pattern. Each client type (mobile iOS, mobile Android, web,
partner portal) has its own BFF service. Each BFF is a GraphQL
API that: (1) composes data from multiple downstream REST/gRPC
microservices, (2) shapes the response to exactly what the client
needs, (3) handles client-specific logic (e.g., mobile pagination
different from web). The downstream microservices remain REST or
gRPC (their API is service-to-service, not client-to-service).
The BFF aggregates and transforms for the specific client. Benefits:
each client team owns their BFF. The mobile team can add mobile-
specific fields without changing the order service API. The web
team's BFF has different response shapes. The microservices stay
clean and consumer-independent. When NOT to use GraphQL in
microservices: do not add a GraphQL layer to every service. This
adds schema maintenance overhead and GraphQL execution complexity
without the multi-client benefit. GraphQL belongs at the BFF/API
composition layer, not at every microservice.

*What separates good from great:* "GraphQL is good for flexible
queries" without the BFF pattern and the specific placement of
GraphQL in the microservices stack.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | DataLoader + N+1 + GraphQL subscriptions |
| Bar Raiser | Protocol selection at organization scale |
