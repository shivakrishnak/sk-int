---
layout: default
title: "REST API - L6 Theory and META Patterns"
parent: "REST API Design and HTTP"
grand_parent: "SK Interview"
nav_order: 9
permalink: /rest-api/l6-theory-meta/
---

# REST Architectural Constraints Theory

🎯 Interview Weight: medium (theory) - Fielding's dissertation
is the origin. Interviewers at senior/staff level may ask about
the constraints directly.

---

### 🎯 Model Answer

**30 seconds:**
> REST (Representational State Transfer) was defined by Roy Fielding
> in his 2000 PhD dissertation. It has six architectural constraints:
> Client-Server, Stateless, Cacheable, Uniform Interface, Layered
> System, and optional Code-on-Demand. Uniform Interface has four
> sub-constraints, of which HATEOAS is the most significant and
> the least implemented.

**3 minutes (Senior):**
> REST constraints and their implications:
>
> 1. Client-Server: separation of UI (client) from data storage
>    (server). Allows independent evolution of client and server.
>    A web browser and mobile app can both consume the same API.
>
> 2. Stateless: the server holds no client session state. Every
>    request contains all the information the server needs to
>    process it. Implication: JWT (all auth context in the token).
>    Benefit: any server can handle any request (horizontal scaling
>    without sticky sessions).
>
> 3. Cacheable: responses must define their cacheability. Benefit:
>    CDN caching, browser caching, reduced server load.
>    Violation: returning `Cache-Control: no-store` on cacheable
>    resources wastes infrastructure.
>
> 4. Uniform Interface: the defining REST constraint. Four parts:
>    (a) Resource identification in requests (URL identifies the resource),
>    (b) Resource manipulation through representations (GET returns
>    a representation; PUT replaces it),
>    (c) Self-descriptive messages (the response contains enough
>    information to process it: Content-Type header, response codes),
>    (d) HATEOAS: hypermedia drives application state.
>
> 5. Layered System: clients cannot tell if they are communicating
>    with the server or an intermediary (CDN, proxy, gateway).
>    Enables: CDN caching, load balancers, API gateways without
>    client changes.
>
> 6. Code-on-Demand (optional): servers can send executable code
>    to clients (JavaScript). The only optional constraint. Rarely
>    applied in the context of REST APIs.
>
> The gap between "REST" and reality: most APIs called "REST"
> are actually HTTP-based RPC (they use HTTP methods and URLs
> but do not implement HATEOAS). Fielding himself has written
> critically about APIs that claim to be REST but ignore Uniform
> Interface and HATEOAS.

**Blank Mind Recovery:**

**(1) Restate:** "REST has 6 architectural constraints from Fielding's
dissertation. Most are followed. HATEOAS is the most violated."

**(2) First principles:** "REST is an architectural style, not
a specification. The constraints define properties: scalability
(stateless + layered), performance (cacheable), evolvability
(uniform interface + HATEOAS)."

---

### 📘 Concept Explanation

**The Uniform Interface sub-constraints:**

```
1. Resource Identification in Requests
   /users/123  <- URI identifies the resource
   Not: session state or procedural calls

2. Manipulation Through Representations
   GET /users/123 -> JSON representation
   PUT /users/123 <- new representation to replace

3. Self-Descriptive Messages
   Content-Type: application/json
   200 OK (not 200 for everything)

4. HATEOAS
   Response includes links to next valid actions
   Client navigates the API by following links
   Not required in most practical APIs
```

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The statelessness constraint is the most impactful for operations.
> Stateless servers can scale horizontally without session affinity.
> Any pod handles any request. This is why JWT (not server-side
> sessions) is the correct auth mechanism for REST: the session
> state (user identity, roles) is in the token, not in a Redis
> session store. When teams use server-side sessions with REST APIs,
> they violate the stateless constraint and lose horizontal scalability.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 3 min | Six constraints + stateless implication |
| Senior | 5 min | Uniform Interface + HATEOAS gap in practice |
| Staff | 7 min | REST vs real-world + Fielding's critique |

---

---

# Richardson Maturity Model

🎯 Interview Weight: medium - RMM is the standard way to describe
"how RESTful" an API is. Tested in senior and architect interviews.

---

### 🎯 Model Answer

**30 seconds:**
> Richardson Maturity Model describes four levels of REST adoption.
> Level 0: HTTP as tunneling (RPC over HTTP). Level 1: resources
> (URLs identify things, but one method). Level 2: HTTP verbs
> (correct use of GET/POST/PUT/DELETE/status codes). Level 3:
> Hypermedia (HATEOAS, responses include next-action links).
> Most production APIs are at Level 2.

**3 minutes (Senior):**
> RMM levels with examples:
>
> Level 0 (The Swamp of POX): one endpoint, one HTTP method,
> everything is a POST. SOAP, XML-RPC. The URL is a service
> endpoint, not a resource.
> `POST /api - { "action": "getUser", "userId": "123" }`
>
> Level 1 (Resources): multiple resource URLs, but no differentiation
> of HTTP methods. All operations use POST.
> `POST /users/123 - { "action": "get" }`
> `POST /orders - { "action": "create", "data": {...} }`
>
> Level 2 (HTTP Verbs): correct use of HTTP methods and status
> codes. Resources have URLs. Operations are HTTP methods.
> `GET /users/123` returns 200 with the user.
> `POST /orders` returns 201 with Location header.
> `DELETE /orders/456` returns 204.
> This is what most "REST APIs" achieve.
>
> Level 3 (Hypermedia): responses include `_links` to valid next
> actions (HATEOAS). The API is self-describing. Clients follow
> links rather than constructing URLs. Rarely implemented in practice.
>
> Practical value of RMM: it is a diagnostic tool. Assessing
> an API's level quickly identifies its design maturity.
> Level 0-1 APIs are RPC in disguise. Level 2 is the target.
> Level 3 is aspirational.

**Blank Mind Recovery:**

**(1) Restate:** "Richardson Maturity Model is a scale of how
RESTful an API is. Most good APIs target Level 2."

**(2) First principles:** "Like a quality scale: Level 0 uses
HTTP as a dumb pipe. Level 2 uses HTTP correctly. Level 3 uses
HTTP's hypermedia capability."

---

### ⚖️ Comparison Table

| Level | Name | URL Style | Methods | Status Codes | Links |
|-------|------|-----------|---------|-------------|-------|
| 0 | POX | /api | POST only | 200 always | No |
| 1 | Resources | /users, /orders | POST only | 200 always | No |
| 2 | HTTP Verbs | /users/123 | GET, POST, PUT, DELETE | Correct | No |
| 3 | Hypermedia | /users/123 | GET, POST, PUT, DELETE | Correct | Yes (_links) |

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> I use RMM as a quick audit tool for legacy APIs. A Level 0 API
> (everything is POST, 200 for errors) is telling: it was designed
> by developers who thought of HTTP as a dumb pipe. The migration
> path is: Level 2 first (correct methods + status codes), then
> evaluate whether Level 3 (HATEOAS) adds value for the specific
> use case. For most APIs, Level 2 is the right target.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 3 min | Four levels with examples |
| Senior | 5 min | Level 2 vs Level 3 practical trade-offs |

---

---

# API Design Decision Framework

🎯 Interview Weight: very high (META) - Decision frameworks
demonstrate structured thinking. Staff interviews often start
with "walk me through how you design an API."

---

### 🎯 Model Answer

**30 seconds:**
> API design starts with four questions: Who are the consumers?
> What operations do they need? What are the non-functional requirements
> (latency, throughput, security)? What are the evolution constraints
> (how often will this change)? Answers drive protocol, versioning,
> auth, and caching choices.

**3 minutes (Senior):**
> The API design decision framework:
>
> Step 1 - Identify consumers and their needs:
> - External/public? (stability, documentation, standard protocols)
> - Internal services? (performance, type safety)
> - Browser? (REST, cacheable)
> - Mobile? (bandwidth efficiency, flexible data shapes)
> - Partners? (stability, versioning, SDK support)
>
> Step 2 - Map operations to HTTP semantics:
> - Which are reads? (GET + caching)
> - Which are writes? (POST/PUT/PATCH + idempotency)
> - Which are long-running? (202 Accepted + polling/webhook)
> - Which are real-time? (WebSocket/SSE)
>
> Step 3 - Non-functional requirements:
> - Latency target? (affects sync vs async, caching)
> - Scale? (rate limiting, pagination, bulk APIs)
> - Security classification? (auth scheme, PII in URLs)
>
> Step 4 - Evolution constraints:
> - Stable contract or iterating fast? (REST + versioning vs GraphQL)
> - Multiple clients with different needs? (BFF or GraphQL)
> - Breaking change tolerance? (internal = fast, external = slow)
>
> Step 5 - Design choices:
> - Protocol: REST, gRPC, GraphQL, WebSocket?
> - Versioning: URL, header, or none (expand/contract)?
> - Auth: API key, JWT, OAuth 2.0?
> - Error format: RFC 7807 Problem Details
> - Pagination: offset or cursor?

**Blank Mind Recovery:**

**(1) Restate:** "How do you approach designing a new API from scratch?"

**(2) First principles:** "An API is a contract. Understand the
consumer's needs before designing. Design for the consumer,
not for the implementation."

---

### 💻 Code Example

**Applying the framework to a new API requirement:**

```
REQUIREMENT: Design the Orders API for an e-commerce platform.
Consumers: web app, mobile app, 50 internal services,
           200 partner integrations.

STEP 1 - Consumers:
  Web app      -> REST (browser-native, cacheable)
  Mobile app   -> REST (standard, well-documented)
  Internal svcs-> gRPC (performance, type safety)
  Partners     -> REST (standard, documented, stable)

STEP 2 - Operations:
  GET /orders (list)     -> cacheable (private/short TTL)
  POST /orders           -> idempotent (Idempotency-Key)
  POST /orders/{id}/cancellations -> idempotent
  GET /orders/{id}/export -> long-running (202 + polling)

STEP 3 - Non-functional:
  Latency: < 200ms p99 for GET
  Scale: 10k requests/minute peak
  Security: PII in orders, OAuth2 + BOLA check required

STEP 4 - Evolution:
  External partner API: stable, versioned (URL versioning)
  Internal gRPC: fast-moving, proto evolution rules
  Web/mobile: GraphQL BFF (feature velocity)

STEP 5 - Design decisions:
  External REST: /api/v1/orders, JWT OAuth2, RFC7807 errors,
                 cursor pagination, rate limit 1000/min/key
  Internal gRPC: order_service.proto, RS256 JWT,
                 DataLoader for N+1 prevention
  Partner SDK: OpenAPI Generator (Java, Python, JS)
  BFF: GraphQL (Apollo) aggregating order+customer+product
```

> **Code walkthrough:** The framework produces different API designs
> for different consumers from the same underlying domain. External
> partners get stable REST with versioning and official SDKs.
> Internal services get gRPC for performance. The web/mobile
> BFF gets GraphQL for flexibility. This is not overengineering -
> it is matching the tool to the job. The key discipline: make
> the decision explicit and record the rationale in an ADR
> (Architecture Decision Record).

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The framework prevents "REST by default" where teams use REST
> even when gRPC or GraphQL is clearly better for the use case.
> It also prevents "GraphQL for everything" when most consumers
> are external partners who need stable, standard, cacheable
> endpoints. The decision is driven by consumer analysis, not
> technology preference.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Five-step framework walkthrough |
| Staff | 10 min | Applying framework to a multi-consumer system design |

---

---

# REST Maturity Mental Model

🎯 Interview Weight: medium (META) - Mental models help candidates
explain trade-offs clearly in interviews.

---

### 🎯 Model Answer

**30 seconds:**
> REST is a spectrum, not a binary. The mental model: REST is a
> highway system, not a private road. Private roads (RPC) are fast
> and direct but serve only one destination. Highways (REST)
> are shared infrastructure: standard lanes, signs, and rules
> that anyone can use. You sacrifice some customization for
> universal compatibility.

**3 minutes (Senior):**
> REST maturity as a spectrum of constraints:
>
> Constraint 1 (stateless): you pay a cost per request (token
> re-validation on every call). You gain: horizontal scaling
> without sticky sessions.
>
> Constraint 2 (uniform interface): you commit to standard
> methods and semantics. You lose: custom verbs and shortcuts.
> You gain: any HTTP client, CDN, proxy, and tool works with
> your API without customization.
>
> Constraint 3 (cacheable): you must mark responses with
> cacheability metadata. You gain: CDN hit rates of 70-90%
> for public resources.
>
> Constraint 4 (HATEOAS): you embed links in responses. You
> gain: discoverable, evolvable API. You pay: complexity,
> response size, client code to follow links.
>
> Trade-off principle: each REST constraint adds complexity
> (implementation effort) and gains a specific architectural
> property (scalability, compatibility, cacheability). Apply
> constraints proportionally to the problem size.
>
> Practical corollary: a CRUD API for an internal tool does
> not need HATEOAS. A public API consumed by thousands of
> developers benefits from Level 2 discipline. The constraints
> are not rules to follow blindly - they are tools to apply
> with judgment.

**Blank Mind Recovery:**

**(1) Restate:** "REST constraints are trade-offs. Each constraint
costs something and buys something. Apply them proportionally."

**(2) First principles:** "Architecture is about trade-offs.
REST's constraints buy specific properties. Know what you are
buying before you accept the cost."

---

### 🎓 Answers by Seniority

**Staff (8+ years):**
> The REST maturity mental model helps in API design reviews.
> When a team proposes HATEOAS, I ask: what architectural property
> are you buying? Discoverability? Client decoupling from URL
> structure? Is that property worth the complexity? For most
> internal APIs: no. For a public platform API consumed by
> generic clients: maybe. The constraint is a tool; use it
> when the problem calls for it.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 4 min | Constraint cost-benefit analysis |
| Staff | 7 min | Applying constraints proportionally to problem size |

---

---

# Protocol Selection Thinking Pattern

🎯 Interview Weight: high (META) - Protocol selection thinking
demonstrates senior engineering judgment.

---

### 🎯 Model Answer

**30 seconds:**
> Protocol selection is a trade-off analysis: REST (standards,
> caching, broad adoption) vs gRPC (performance, type safety)
> vs GraphQL (flexibility, client-defined queries) vs WebSocket
> (real-time bidirectional). The decision framework: who is the
> consumer? what is the access pattern? what are the performance
> requirements? what is the change frequency?

**3 minutes (Senior):**
> The decision tree:
>
> Is the consumer a browser or external developer?
> -> Yes: REST. External consumers need standards, documentation,
>         and HTTP caching.
>
> Is this service-to-service inside the same organization?
> -> gRPC. Performance, type safety, streaming.
>    Exception: if one team uses Python and the other Java and
>    gRPC tooling is poor in one, REST may be simpler.
>
> Do multiple clients need different data shapes from the same data?
> -> GraphQL. Client-defined queries avoid N+1 round trips and
>    over-fetching.
>    Exception: if change velocity is low (data shapes rarely change),
>    REST BFFs are simpler.
>
> Is this real-time bidirectional?
> -> WebSocket. Full duplex.
>    Exception: if one-directional push, use SSE (simpler).
>
> Is this real-time one-directional push?
> -> SSE. HTTP-based, browser-native, simpler than WebSocket.
>
> The meta-principle: match the protocol to the consumer's needs
> and constraints, not to your preferred technology. A protocol
> that is optimal for the server but awkward for the consumer
> is a poor choice.

**Blank Mind Recovery:**

**(1) Restate:** "Protocol selection is a consumer-driven decision.
Who consumes this API and what do they need?"

**(2) First principles:** "Protocols exist to serve communication
between parties. Choose the protocol that serves the communication
need, not the implementation preference."

---

### 📘 Concept Explanation

**Protocol selection matrix:**

```
Consumer      Access Pattern    Protocol     Reason
-----------------------------------------------------
Browser       Request-response  REST         Standard, cache
Browser       Live updates      SSE          HTTP-based, simple
Browser       Real-time bidir   WebSocket    Full duplex
Mobile        Request-response  REST/GraphQL Flexible, offline
Internal svc  Request-response  gRPC         Performance
Internal svc  Streaming         gRPC         Native streaming
External dev  Request-response  REST         Documentation
Partner       Batch operations  REST         Standard tooling

Anti-patterns:
  - gRPC for external/public APIs (not browser-native)
  - GraphQL for stable, well-known patterns (overkill)
  - REST for high-frequency internal calls (HTTP overhead)
  - WebSocket for non-real-time (connection overhead)
```

---

### 🎓 Answers by Seniority

**Staff (8+ years):**
> The biggest protocol mistake I see: teams use REST internally
> because it is familiar, even for high-frequency service calls
> where gRPC's 10x performance advantage is measurable. Conversely,
> teams adopt gRPC for all APIs and struggle with external partners
> who cannot use binary protocols. The discipline: separate the
> internal (performance) from the external (standards) protocol
> strategy. Both can coexist with a REST-gRPC transcoding layer
> at the gateway.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Decision tree + anti-patterns |
| Staff | 8 min | Multi-protocol org strategy + REST-gRPC transcoding |

---

**[TRADE-OFF] A team wants to use GraphQL for everything - external
APIs, internal services, and partner integrations. What is your advice?**
`[STAFF]`

*Why they ask:* Tests ability to apply the protocol selection
framework against a strong existing preference.

*Likely follow-up:* "How do you convince the team to use REST
for some cases?"

GraphQL for everything has specific failure modes: (1) External/partner
APIs: partners expect OpenAPI documentation and REST conventions.
GraphQL queries require significant client tooling (Apollo Client
or similar). Caching is complex (all POST, no native HTTP caching).
Partners integrating with dozens of APIs prefer REST. (2) Internal
service-to-service: GraphQL adds overhead (HTTP, JSON parsing,
GraphQL parsing) vs gRPC (binary protobuf). For a call that happens
10,000 times per second, this matters. (3) Simple CRUD operations:
a simple `GET /users/123` with a fixed response does not benefit
from GraphQL's flexibility. Adding GraphQL resolver complexity
for no gain. Advice: use GraphQL where it excels - multi-client
APIs with varying data needs (mobile BFF, web BFF). Use REST for
external APIs (standards, caching, partner tools). Use gRPC for
high-frequency internal calls (performance). The argument to the
team: "GraphQL is a great tool. Let us use it where it provides
the most value and REST/gRPC where they are more appropriate.
The goal is to build the best system, not to be consistent on
the wrong dimension."

*What separates good from great:* Concrete failure modes for
"GraphQL everywhere" with specific alternatives for each, and
a diplomatic path to changing the team's approach without
dismissing GraphQL.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Decision tree + implementation |
| System Design | Multi-protocol architecture |
| Bar Raiser | Engineering judgment + org-level thinking |
