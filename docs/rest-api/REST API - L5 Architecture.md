---
layout: default
title: "REST API - L5 Architecture"
parent: "REST API Design and HTTP"
grand_parent: "SK Interview"
nav_order: 8
permalink: /rest-api/l5-architecture/
---

# API Platform Architecture

🎯 Interview Weight: high (staff/principal) - API platform
thinking separates staff engineers from seniors.

---

### 🎯 Model Answer

**30 seconds:**
> An API platform is the shared infrastructure layer for all APIs:
> gateway, auth service, rate limiting, monitoring, developer portal,
> and SDK generation. It provides common capabilities so individual
> teams implement only business logic. Platforms enable governance
> and consistency across hundreds of APIs.

**3 minutes (Senior):**
> API platform components:
>
> 1. API Gateway layer: SSL termination, routing, rate limiting,
>    auth token validation. Teams deploy their services behind
>    the gateway. Gateway enforces organization-wide policies.
>
> 2. Developer portal: documentation, API keys, usage dashboards,
>    OpenAPI exploration (Swagger UI). External developers self-service.
>    Built on: Backstage, ReadMe, Stoplight, or custom.
>
> 3. Identity platform: central OAuth 2.0 authorization server
>    (Keycloak, Auth0, Okta). Issues JWT tokens. Services validate
>    against the public key from the JWKS endpoint. All services
>    share the same auth infrastructure.
>
> 4. SDK generation pipeline: CI/CD generates client SDKs
>    (Java, Python, JavaScript, TypeScript) from OpenAPI specs
>    automatically. Published to package registries (npm, Maven).
>    Clients get typed, up-to-date SDKs without manual effort.
>
> 5. Contract registry: central storage for OpenAPI specs and Pact
>    contracts. Breaking change detection runs on every spec change.
>    Governance: specs must be approved before deployment.
>
> 6. API observability: centralized metrics, tracing, and logging
>    for all APIs. Platform team maintains the Grafana dashboards.
>    Teams get visibility without instrumentation effort.
>
> Platform team model: the API platform team builds and operates
> the shared infrastructure. Product teams use it. Platform team
> provides "golden path" templates (Spring Boot starter with
> tracing, metrics, and auth pre-configured).

**Blank Mind Recovery:**

**(1) Restate:** "An API platform is the shared infrastructure
layer that all APIs build on. It handles common concerns so
teams focus on business logic."

**(2) First principles:** "20 teams each implementing auth, rate
limiting, and monitoring = 20 different implementations. A platform
does it once, consistently, for all teams."

---

### 📘 Concept Explanation

**API Platform Architecture:**

```
INTERNET
    |
[CDN / WAF]  <- DDoS, TLS, static assets
    |
[Edge Gateway]  <- Rate limiting, auth, routing
    |
[BFF Layer]     <- Client-specific aggregation
    |
[Service Mesh]  <- mTLS, load balancing, tracing
    |
[Services]      <- Business logic only
    |
[Data Layer]    <- DB, cache, message queue

Platform provides:
  - Auth:       Keycloak / Auth0
  - Registry:   OpenAPI Specs + Pact contracts
  - SDK gen:    OpenAPI Generator + CI/CD
  - Portal:     Backstage / ReadMe
  - Observability: Prometheus + Jaeger + ELK
```

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> An API platform provides shared infrastructure: gateway, auth,
> monitoring, and developer portal. Teams build on the platform
> instead of reinventing these components.

---

**Senior / Staff (5+ years):**
> The API platform's golden path is the highest ROI investment.
> A Spring Boot starter that pre-configures metrics (Prometheus),
> tracing (OpenTelemetry), JWT auth, and standard error handling
> means teams start with operational excellence by default.
> Without it, each team makes different choices; observability
> is inconsistent; security posture varies. The platform is an
> enabler: it makes the right thing the easy thing.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Mid | 4 min | Platform components + developer portal |
| Senior | 7 min | Golden path + SDK generation + governance |
| Staff | 10 min | Build vs buy + team model + org-wide impact |

---

**[ARCHITECTURE] Your organization has 50 engineering teams
each building their own APIs. There is no consistency. Design
an API platform strategy.** `[STAFF]`

*Why they ask:* Tests ability to think at organizational scope.

*Likely follow-up:* "How do you get 50 teams to adopt the platform?"

Phase 1 (0-3 months): assess the current state. Audit all
existing APIs (how many? what auth patterns? what monitoring?).
Identify the top pain points (most teams complain about duplicating
auth logic, inconsistent error formats, no documentation). Phase 2
(3-6 months): build the golden path. Create a Spring Boot starter
(or equivalent) that pre-wires: JWT validation against the central
auth server, Prometheus metrics with standard labels, OpenTelemetry
tracing, RFC 7807 error handler, and a Dockerfile template. This
handles 80% of teams' needs with zero configuration. Phase 3
(6-12 months): gateway + portal. Deploy Kong or AWS API Gateway
as the central entry point. Build (or buy) a developer portal with
OpenAPI spec browsing. Publish generated SDKs to internal Maven/npm
registry. Adoption strategy: do not mandate adoption. Instead, make
the platform demonstrably better than the alternative. Showcase
a before/after for one team: before = each team reinvents auth,
after = one annotation `@EnablePlatformAuth`. Adoption should be
pull, not push. Governance: require new APIs to register in the
contract registry (spec must exist before deployment). Do not
require platform usage - but require the API contract.

*What separates good from great:* The adoption strategy (pull
not push) and the two-phase governance (registry now, full
platform later at the team's pace).

---

---

# API Governance at Scale

🎯 Interview Weight: high (staff/principal) - Governance is how
organizations maintain quality across many teams and APIs.

---

### 🎯 Model Answer

**30 seconds:**
> API governance is the set of policies, processes, and tooling
> that ensures APIs are consistent, secure, and maintainable
> across an organization. Governance mechanisms: style guides,
> automated linting (Spectral), breaking change detection,
> API review boards, and contract registries.

**3 minutes (Senior):**
> API governance maturity levels:
>
> Level 0 (Ad-hoc): each team does whatever they want. Inconsistent
> URL styles, auth patterns, error formats. No central visibility.
>
> Level 1 (Style guide): documented conventions. Not enforced.
> Teams follow loosely when they read the docs.
>
> Level 2 (Automated linting): OpenAPI linting with Spectral
> enforces style rules in CI. PRs that violate naming conventions,
> missing descriptions, wrong error codes, fail the build.
>
> Level 3 (Contract registry): all API specs registered centrally.
> Breaking change detection on every spec update. "Can I deploy?"
> check blocks deployments that break registered consumers.
>
> Level 4 (Design review): major API changes (new resources, versioning)
> require API review board approval. Architectural alignment before
> coding.
>
> Level 5 (Platform enforcement): teams cannot deploy APIs that
> are not registered. The gateway only routes registered APIs.
> Governance is structural, not procedural.
>
> Common Spectral rules for API governance:
> - URLs must be lowercase with hyphens
> - All endpoints must have an `operationId`
> - All responses must have descriptions
> - Error responses must include `application/problem+json`
> - No operation can lack security schemes (unless explicitly exempt)

**Blank Mind Recovery:**

**(1) Restate:** "API governance ensures all APIs meet quality,
security, and consistency standards across many teams."

**(2) First principles:** "Without governance, each team optimizes
for themselves. Governance aligns teams toward organizational
goals: consistency, security, maintainability."

---

### 💻 Code Example

**Spectral API linting rules:**

```yaml
# .spectral.yml - enforced in CI on every OpenAPI spec change

rules:
  # URL naming: lowercase with hyphens
  path-casing:
    description: "Paths must use lowercase-with-hyphens"
    severity: error
    given: "$.paths"
    then:
      function: pattern
      functionOptions:
        match: "^(/[a-z0-9-]+)+$"

  # All operations need an operationId
  operation-operationId:
    description: "Every operation must have operationId"
    severity: error
    given: "$.paths[*][*]"
    then:
      field: operationId
      function: truthy

  # Error responses must use RFC 7807
  error-response-format:
    description: "Error responses must use problem+json"
    severity: warn
    given: "$.paths[*][*].responses[4*]"
    then:
      field: content
      function: schema
      functionOptions:
        schema:
          required:
            - "application/problem+json"

  # All operations must require authentication
  operation-security:
    description: "Operations must specify security"
    severity: warn
    given: "$.paths[*][*]"
    then:
      field: security
      function: truthy
    # Override with x-no-auth: true for public endpoints
```

```yaml
# CI: run Spectral on every PR that changes openapi.yaml

# .github/workflows/api-lint.yml
name: API Governance
on:
  pull_request:
    paths:
      - 'openapi.yaml'
      - 'openapi/**/*.yaml'
jobs:
  spectral-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Spectral
        uses: stoplightio/spectral-action@latest
        with:
          file_glob: 'openapi.yaml'
          spectral_ruleset: '.spectral.yml'
          # Fails PR on severity: error violations
```

> **Code walkthrough:** Spectral checks the OpenAPI spec against
> governance rules and fails the CI build on violations. `path-casing`
> enforces lowercase-with-hyphens URLs (not camelCase or underscores).
> `operation-operationId` ensures every endpoint has a stable ID
> (needed for SDK generation and documentation). `error-response-format`
> warns when 4xx responses do not use RFC 7807 format.
> `operation-security` warns when endpoints have no security scheme
> specified. These rules enforce the API style guide automatically
> before any human review, so reviewers focus on design quality,
> not formatting.

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> Governance must be automated to be effective. A style guide
> document that no one reads is not governance. Spectral linting
> in CI that fails PRs is governance. Breaking change detection
> that blocks deployments is governance. Human review boards
> should only be needed for high-impact changes (new domains,
> versioning decisions, external API launches).

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Governance levels + Spectral linting |
| Staff | 8 min | Organizational adoption + enforcement strategy |

---

---

# API Evolution and Deprecation Strategy

🎯 Interview Weight: high (senior/staff) - Long-lived APIs require
a mature evolution strategy.

---

### 🎯 Model Answer

**30 seconds:**
> API evolution strategy: evolve backward-compatibly as long as
> possible (additive changes only). When breaking change is required,
> version the API, run both versions in parallel, monitor traffic
> by version, and sunset the old version after a defined period
> when usage drops to zero.

**3 minutes (Senior):**
> The Tolerant Reader pattern: design consumers to accept more
> than they need and ignore what they do not understand. New fields
> in the response should be silently ignored by old clients.
> New optional request fields should be backward-compatible.
> This is why Jackson's `FAIL_ON_UNKNOWN_PROPERTIES = false` is
> important: old clients can receive new fields without breaking.
>
> The Expand/Contract pattern for zero-downtime migrations:
> Expand: add the new field alongside the old one. Both exist.
> Old clients use the old field. New clients can use either.
> Contract: deprecate the old field, monitor usage, eventually
> remove it. This avoids a hard v1/v2 split for simple changes.
>
> When to version vs when to expand/contract:
> - New optional field: expand/contract, no versioning needed
> - Field rename: expand (add new name), contract (remove old name)
> - Type change: must version (breaking: String -> Object)
> - Semantic change: must version (status values added = safe,
>   status values removed = breaking)
>
> Deprecation governance: deprecation must have a sunset date from
> day 1. Deprecations without sunset dates are promises that are
> never kept. Sunset date policy: public APIs = 12 months,
> internal APIs = 3-6 months.
>
> Sunset enforcement: after the sunset date, the endpoint
> returns 410 Gone. Monitor for clients that still call sunsetted
> endpoints and contact them (by API key → registered email).

**Blank Mind Recovery:**

**(1) Restate:** "How to evolve an API over years without breaking
clients."

**(2) First principles:** "Prefer additive changes. Version only
when a truly breaking change is unavoidable. Always set a sunset
date when deprecating."

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> The expand/contract pattern avoids version explosions. In a
> 5-year-old API with 100 endpoints, you can have 100 v1 endpoints,
> 20 v2 endpoints, and 5 v3 endpoints if every change requires a
> new version. With expand/contract, most changes are backward-
> compatible: the single endpoint evolves without versioning.
> We only version when the contract fundamentally changes (type
> change, semantic change, endpoint removal).

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Tolerant reader + expand/contract |
| Staff | 8 min | Version governance + sunset policy + 5-year API evolution |

---

---

# Multi-Protocol API Strategy

🎯 Interview Weight: medium-high (senior/staff) - Modern systems
often need REST, gRPC, GraphQL, and WebSockets simultaneously.

---

### 🎯 Model Answer

**30 seconds:**
> Different client needs require different protocols. A mature
> API strategy uses REST for public/external APIs (standards-based,
> cacheable), gRPC for internal service-to-service (performance,
> type safety), GraphQL for multi-client APIs (client-defined
> queries), and WebSocket/SSE for real-time (push, bidirectional).
> Protocol selection follows client needs, not technology preference.

**3 minutes (Senior):**
> Multi-protocol selection matrix:
>
> REST: external/public APIs, browser-facing, caching needed,
> well-known access patterns, third-party developer adoption.
>
> gRPC: internal service-to-service, latency-sensitive paths
> (payment processing, inventory checks), streaming needed,
> polyglot systems (Go services calling Java services).
>
> GraphQL: internal APIs with multiple client types (mobile, web,
> TV app) with different data needs, rapid product iteration
> (clients change data requirements without API changes).
>
> WebSocket: real-time bidirectional (chat, live trading, collaboration).
>
> SSE: real-time one-directional push (live dashboards, notifications,
> live updates). Browser-native, HTTP-based.
>
> Unified approach: REST-gRPC transcoding. Define the API in
> `.proto` with REST annotations (Google HTTP/JSON transcoding).
> The service is natively gRPC. The gateway auto-generates REST
> endpoints from the gRPC definition. Internal services use gRPC;
> external clients use REST. One implementation, two protocols.

**Blank Mind Recovery:**

**(1) Restate:** "Different protocols are optimal for different
use cases. The decision follows client needs and performance
requirements."

---

### 📘 Concept Explanation

**Protocol selection matrix:**

```
Client type       Protocol    Why
-------------------------------------------------
Browser           REST/HTTP   Native, caching, standards
Mobile app        REST/GraphQL Flexible, bandwidth-aware
Internal svc      gRPC        Performance, type safety
Realtime push     SSE         HTTP-based, browser-native
Realtime bidir    WebSocket   Full duplex
Partner B2B       REST        Standardized, documented
```

---

### 🎓 Answers by Seniority

**Senior / Staff (5+ years):**
> gRPC-REST transcoding is the most elegant multi-protocol solution.
> You define one `.proto` file with `google.api.http` annotations.
> The service is pure gRPC. The gateway (Envoy, GCP API Gateway,
> AWS App Mesh) auto-generates REST+JSON endpoints. Internal services
> use gRPC (fast, typed); external clients use REST (standard,
> cacheable). Maintenance is one codebase, one schema, two protocols.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Selection matrix + REST vs gRPC trade-offs |
| Staff | 8 min | Unified strategy + transcoding + org-level protocol standards |

---

**[ARCHITECTURE] Design the API strategy for a platform that
serves browser apps, mobile apps, 50 internal microservices,
and 200 external partners.** `[STAFF]`

*Why they ask:* Tests multi-protocol strategy at organizational scale.

*Likely follow-up:* "How do you ensure all teams follow the strategy?"

External partners (200): REST with full versioning and a developer
portal. Partners need stability, standard docs, and OpenAPI specs.
Version: URL-based (`/api/v2/`). Breaking change policy: 12-month
sunset. Browser app: REST for most APIs. GraphQL for the app's
BFF layer (high feature velocity; the React team changes data
needs weekly). SSE for real-time notifications (browser-native,
simpler than WebSocket for one-directional push). Mobile app:
GraphQL BFF (mobile needs different data shapes than web, bandwidth-
sensitive). REST for simple endpoints with stable access patterns.
Internal microservices (50): gRPC. Performance matters (milliseconds
add up across 5 service calls per request). Type safety (`.proto`
schemas prevent integration bugs). Streaming for event-driven
patterns. Governance: partner APIs require API review board approval.
Internal APIs use the gRPC platform golden path (`.proto` template
with auth + tracing). BFF APIs use GraphQL platform template
(Apollo Federation or schema stitching for multi-team ownership).

*What separates good from great:* Matching protocol to the
stakeholder's specific needs (stability for partners, flexibility
for browser, performance for services) rather than using one
protocol for everything.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Protocol selection + implementation |
| Staff/Principal | Org-level strategy + governance |
| System Design | Multi-client API architecture |
