---
layout: default
title: "Microservices - L3 Versioning and Security"
parent: "Microservices"
grand_parent: "SK Interview"
nav_order: 8
permalink: /microservices/l3-versioning-and-security/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Service Versioning and API Evolution](#service-versioning-and-api-evolution) | medium |
| 2 | [Microservices Security - Authentication and Authorization](#microservices-security---authentication-and-authorization) | medium |

---

# Service Versioning and API Evolution

---

### 🎯 Model Answer

**30 seconds:**
> Service versioning allows microservices to evolve their APIs without breaking existing clients. The core strategies: URL versioning (/v1/, /v2/), HTTP header versioning (Accept: application/vnd.api.v2+json), and query parameter versioning (?version=2). More importantly: the design philosophy of backward compatibility - adding optional fields and new endpoints is always safe; removing or renaming fields breaks clients and requires versioning.

**3 minutes:**
> In a microservices architecture, services are independently deployed by different teams at different times. A client may be running version 1 of the contract while the service deploys version 2. Versioning strategies must accommodate this reality. Breaking change categories: removing a field from a response (clients expecting that field break), renaming a field (same), changing a field's type (string to integer), changing an endpoint URL, requiring a new mandatory request field, changing error response shapes. Non-breaking changes: adding optional fields to responses (clients ignore fields they don't know), adding optional fields to requests (services use defaults), adding new endpoints, adding new enum values (clients that don't handle all enums may break - debated). The practical approach: treat your API as a public contract. Use semantic versioning for breaking changes. Maintain the previous version for a deprecation period (typically 6-12 months for internal APIs, longer for public APIs). Notify consumers of upcoming breaking changes. The hardest part: discovering all consumers of an API before deprecating. Service catalog and API gateway analytics help identify which clients are calling which endpoints.

**Blank Mind Recovery:**
**(1) Restate:** "API versioning lets services evolve without breaking existing clients."
**(2) Key types:** "Breaking change = must version. Non-breaking = additive, safe."
**(3) Real challenge:** "Deprecating old versions requires knowing all consumers. Gradual migration."

---

### 📘 Concept Explanation

**What it is:**
API versioning is the practice of managing changes to a service's API contract in a way that allows existing clients to continue working while new clients can use improved interfaces. The goal is independent deployability: service and client can be deployed on their own schedule.

**Versioning strategies:**
```
URL VERSIONING (most common):
  /api/v1/orders          <- v1 clients (still deployed)
  /api/v2/orders          <- v2 clients (new behavior)

  Pros: explicit, easy to route, cacheable
  Cons: URL should identify resource, not version

HEADER VERSIONING:
  Accept: application/vnd.company.v2+json

  Pros: URL stays clean, REST-pure
  Cons: not visible in browser/curl, harder to test

QUERY PARAMETER:
  GET /api/orders?version=2

  Pros: easy to test, explicit
  Cons: pollutes query string

SEMANTIC VERSIONING FOR APIs:
  MAJOR.MINOR.PATCH
  MAJOR: breaking change (new URL version)
  MINOR: backward-compatible addition
  PATCH: bug fix (no API change)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Backward compatibility rules:**
```
SAFE (non-breaking changes):
  + Add optional field to response
  + Add optional field to request with default
  + Add new endpoint
  + Add new optional query parameter
  + Add new enum value (with caveat)
  + Relax validation (accept more inputs)

BREAKING (requires new version):
  - Remove field from response
  - Rename field (same as remove + add)
  - Change field type (string -> number)
  - Make optional field required
  - Change URL structure
  - Remove endpoint
  - Change error response format
  - Tighten validation (reject previously valid input)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Consumer-driven contract testing:**
```
PACT CONTRACT TESTING:
  Consumer (OrderService) defines expectations:
    - GET /products/{id} returns {id, name, price}
    - POST /reservations accepts {productId, qty}
    - Returns 200 with {reservationId}

  Provider (InventoryService) verifies:
    - Run Pact against the contract in CI
    - If contract violated: build fails before deploy

  Result:
    - Consumer declares what it needs
    - Provider verified to satisfy all consumers
    - Breaking changes caught before deployment
    - No need for a separate API integration test
      environment to catch contract violations
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**The key insight:**
The version number in a URL is not about the service version - it is about the API contract version. A service can be at version 15.2.3 internally but still support /v1/ and /v2/ API contracts. Keep old API versions running until all consumers have migrated, not until the service is upgraded.

---

### 💻 Code Example

```java
// BAD: No versioning strategy - breaking change
@RestController
@RequestMapping("/api/orders")
public class OrderController {
  @GetMapping("/{id}")
  public OrderResponse getOrder(@PathVariable String id) {
    Order order = orderService.getOrder(id);
    return new OrderResponse(
        order.getId(),
        order.getStatus(),
        // BREAKING: renamed from 'totalAmount'
        // to 'total' - all clients break
        order.getTotal()
    );
  }
}
```

> **Code walkthrough:** Renaming totalAmount to total in the response is a breaking change. All clients that read response.totalAmount now receive null. No versioning protection was in place. This is the silent failure mode: the field just disappears from the response with no error.

```java
// GOOD: Versioned endpoints with deprecation
@RestController
public class OrderController {
  
  // v1: original contract - maintained for 6 months
  @GetMapping("/api/v1/orders/{id}")
  @Deprecated
  public OrderResponseV1 getOrderV1(
      @PathVariable String id) {
    Order order = orderService.getOrder(id);
    // V1 response: backward compatible
    return OrderResponseV1.builder()
        .id(order.getId())
        .status(order.getStatus())
        .totalAmount(order.getTotal()) // old name
        .build();
  }
  
  // v2: new contract with improved fields
  @GetMapping("/api/v2/orders/{id}")
  public OrderResponseV2 getOrderV2(
      @PathVariable String id) {
    Order order = orderService.getOrder(id);
    // V2: renamed field + new fields
    return OrderResponseV2.builder()
        .id(order.getId())
        .status(order.getStatus())
        .total(order.getTotal())          // new name
        .currency(order.getCurrency())    // new field
        .lineItems(order.getLineItems())  // new field
        .build();
  }
}
```

> **Code walkthrough:** Both v1 and v2 endpoints coexist. v1 uses the old field name (totalAmount) for backward compatibility. v2 uses the new name (total) with additional fields. The @Deprecated annotation signals to Java clients that v1 is scheduled for removal. The Deprecation: header and Sunset: header can be added to HTTP responses to inform API clients programmatically of the deprecation timeline.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "API versioning is about letting the service change its API without breaking existing clients. You keep the old version working at /v1/ while the new version is at /v2/. The key rule is: adding new fields is safe, but removing or renaming fields breaks clients. When you make a breaking change, you create a new version and give clients time to migrate to it before removing the old one."

**Senior / Staff:** "The real challenge in API versioning is not the technical mechanism but the operational discipline: tracking all consumers, communicating deprecations, and actually removing old versions. Services that 'support v1 until nobody uses it' find that v1 is never removed because there's always some undiscovered consumer. The solution: API gateway analytics showing request counts by version endpoint. Mandatory sunset dates in contracts. Consumer-driven contract testing (Pact) to know exactly which consumers exist and what they need. Evolve-first thinking: design APIs that can grow without breaking (use envelopes, avoid polymorphism in responses, use nullable for optional fields). The best API versioning strategy is one where you rarely need to create a new version."

---

### ⚠️ Common Misconceptions

**Misconception:** "Adding a new required field to a request is a non-breaking change."
Reality: Adding a required field to a request body is always a breaking change. Existing clients that don't send the new field will get validation errors (400 Bad Request). The correct approach: add new fields as optional with sensible defaults. If the field will eventually be required: (1) add as optional first, (2) inform all clients, (3) after migration period, move to required in the next major version. Only mark a field required in a new version after all known clients have been updated.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Silent contract break - clients receive null for renamed fields**

Symptoms: A downstream service starts returning null or default values for fields that were previously populated. No error is thrown. Business logic using those fields produces incorrect results silently.

Root cause: The provider service renamed a field in the response (e.g., totalAmount -> total). Existing clients deserialize the response using the old field name and receive null. No 4xx/5xx error - the response is technically valid JSON.

Diagnosis: Compare the current API response structure against the client's deserialization model. Use Pact contract tests in CI to catch this before deployment. In production: add response validation in clients (fail fast on unexpected null for critical fields) rather than silently processing null values.

Fix: Restore the old field name in the response (add it back alongside the new name) for the v1 endpoint. Deploy the fix. Add Pact consumer contract tests to prevent future silent breaks.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Trade-off | 2 min | 1 |
| Scenario | 5 min | 1 |
| Comparison | 2 min | 1 |
| Debugging | 2 min | 1 |
| Design | 3 min | 2 |
| Anti-pattern | 2 min | 1 |
| Scale | 2 min | 1 |

#### Q1 - "What is consumer-driven contract testing and how does it prevent API breaks?"
> "Pact-based contract testing: the consumer (OrderService) defines its contract - what it calls, what request format, what response it expects. This contract (Pact file) is shared with the provider (InventoryService). In InventoryService's CI pipeline: run Pact verification. InventoryService starts a mock of itself based on the Pact, verifies its actual response matches the contract. If InventoryService removes a field the consumer expects: Pact verification fails and the deployment is blocked. Benefits: catches contract violations before they reach production, no dedicated integration test environment needed, consumers are self-documenting (their Pact files show exactly what they depend on), providers can see all consumers and their expectations before making any API change."

*What separates good from great:* "Pact Broker is the infrastructure: a centralized service where consumers publish their Pact files and providers verify against them. Can-I-Deploy command: before any deployment, query 'can this service version deploy to production?' based on whether all consumer contracts pass. This makes contract testing a deployment gate, not just a CI check."

---

#### Q2 - "How do you deprecate and remove an old API version?"
> "Deprecation lifecycle: (1) Publish new version (/v2/). (2) Announce deprecation of v1 with sunset date. (3) Add Deprecation and Sunset HTTP response headers to v1 responses. (4) Use API gateway analytics to monitor v1 usage. (5) Contact teams still using v1. (6) After sunset date, remove v1. Sunset header format: Sunset: Sat, 01 Jun 2025 00:00:00 GMT. Clients that handle this header can alert their developers. In practice: sunset dates are rarely enforced because unknown consumers appear. Enforcement: require consumers to register in a service catalog. Gate sunset removal on the registry showing zero registered consumers. For public APIs: longer deprecation periods (1-2 years). For internal APIs: 3-6 months."

*What separates good from great:* "Hard enforcement: return HTTP 410 Gone instead of 200 after the sunset date. 410 is different from 404 (resource not found): 410 means 'permanently gone, stop calling.' Clients receive a clear error rather than silent degradation. This forces consumers to update because they get hard errors, not just deprecation warnings that can be ignored."

---

#### Q3 - "How do you version event schemas (not just REST APIs)?"
> "Events in Kafka have the same versioning challenge as REST APIs: consumers may be running an old version when a new event format is deployed. Strategies: (1) Avro with Schema Registry (Confluent): schemas registered with compatibility mode. BACKWARD compatibility allows new consumers to read old events. FORWARD allows old consumers to read new events. FULL is both. The schema registry enforces this at publish time. (2) Version in event type: order.created.v1 vs order.created.v2. Different Kafka topics or same topic with type field routing. Consumers subscribe to specific versions. (3) Envelope pattern: events always have an envelope with version, eventType, timestamp, and data. Consumers route based on version in the envelope. (4) CloudEvents specification: standardized event envelope (type, source, time, data). Build version into the type field: com.company.order.created.v2."

*What separates good from great:* "Event schema evolution is harder than REST API evolution because events are persisted. A REST API version is only active while the service is deployed. A Kafka event version lives in the log for the retention period (potentially forever). If you have 6 months of events in Kafka, a new consumer must be able to deserialize both v1 and v2 events. Schema Registry backward compatibility mode enforces that new schemas can always deserialize old events."

---

#### Q4 - "A new team wants to integrate with your service but needs a slightly different API shape. What is your process?"
> "Evaluation: (1) Is the needed change backward compatible (add optional field)? Add it without versioning. (2) Is it a non-breaking addition that benefits other consumers too? Discuss and add to the current version. (3) Is it specific to this consumer only? Consider a BFF (Backend-for-Frontend) that adapts the response specifically for that consumer. (4) Is it a breaking change that other consumers would benefit from? Plan a v2 with a migration path. (5) Is it a fundamental architectural mismatch (they need a different data model entirely)? They may need to maintain their own read model (subscribing to your events and building their own projection). The key: the service API is for all consumers, not one consumer. Special-casing for one consumer creates N special cases over time."

*What separates good from great:* "The BFF pattern (Backend-for-Frontend) is underused. A BFF owned by the consuming team means the consuming team can shape the API exactly as they need it, without coupling to the provider's API evolution cycle. The BFF calls the provider's stable API and transforms for its consumer. This creates clean separation: provider API evolves slowly for stability, BFF evolves as needed for the consumer."

---

#### Q5 - "How do you handle API versioning when multiple microservices need to change their contracts simultaneously?"
> "Synchronized multi-service versioning: an order flow that requires OrderService, InventoryService, and PaymentService all changing their contracts simultaneously. Strategy: (1) Identify the dependency direction. Which service does the other depend on? (2) Deploy in reverse dependency order. Deploy provider before consumer. (3) Use feature flags: new code is deployed but not active. Enable the flag to activate the new behavior. (4) Use contract versioning: each service version is compatible with both the old and new contract. Service A v2 can work with Service B v1 and v2. Remove backward compatibility only after all services are on the new version. (5) Event versioning: if event-driven, publish both old and new event formats during the migration window."

*What separates good from great:* "The hardest case: bidirectional dependency (A calls B, B calls A). This is a design smell (cyclic dependency between services), but if it exists: deploy with both old and new API support active simultaneously. The transition window where both services support both versions is the migration window. Keep it short."

---

#### Q6 - "How does API versioning interact with database migrations?"
> "Database migrations must be backward compatible with the previous API version still running. Expand-contract pattern: Phase 1 (expand): add new column, keep old column. API v1 still reads old column. API v2 reads new column. Phase 2 (migrate): fill new column with migrated data from old column. Phase 3 (contract): after v1 is deprecated and removed, drop old column. The database migration lifecycle is longer than the API versioning lifecycle: the old column cannot be dropped until v1 is fully decommissioned. This means database schemas may have deprecated columns for the entire duration of the API deprecation period. Track deprecated columns with comments or naming conventions (e.g., _deprecated_total_amount) to indicate they are kept only for old API version compatibility."

*What separates good from great:* "Blue-green deployments + database migration compatibility: a blue-green deployment runs old and new code simultaneously. The database must be compatible with both during the transition. Flyway's migration scripts run once, not per deployment. Migrations must be idempotent and forward-only. Never write migrations that depend on the application version - the migration runs on the database, the application runs on the API."

---

#### Q7 - "What is hypermedia (HATEOAS) and does it solve the versioning problem?"
> "HATEOAS (Hypermedia as the Engine of Application State): API responses include links to related actions and resources. Clients follow links rather than hardcoding URLs. A response includes: { id: 123, status: 'pending', _links: { confirm: /api/orders/123/confirm, cancel: /api/orders/123/cancel } }. The client discovers available actions from the response rather than knowing URLs in advance. This theoretically allows server URL structure to change without breaking clients - they follow links, not hardcoded paths. In practice: HATEOAS rarely solves versioning because clients still depend on the structure of the response data (field names, types), not just URLs. HATEOAS prevents URL versioning from being needed but doesn't prevent field-level versioning. Most production microservices use URL versioning, not HATEOAS, due to the complexity of implementing a fully HATEOAS-compliant client."

*What separates good from great:* "HATEOAS is theoretically elegant but rarely implemented correctly. The practical problems: clients still embed field name knowledge (reading order.status regardless of URL), link following adds latency (multiple round trips to discover actions), and no standard client libraries implement HATEOAS navigation. URL versioning + semantic versioning + contract testing is the pragmatic combination used in production."

---

#### Q8 - "How do you communicate API changes to downstream teams?"
> "Change management strategy: (1) API changelog: maintain a CHANGELOG.md per service documenting all breaking and non-breaking changes per version. (2) Deprecation announcements: send to a #api-changes Slack channel with sunset date, affected endpoints, migration guide. (3) Deprecation headers: HTTP Deprecation and Sunset headers on deprecated endpoints - tools and monitoring pick these up. (4) Service catalog: list all deprecated endpoints and their sunset dates. (5) Consumer notification: if a consumer is registered in the service catalog, notify them directly before the sunset date. (6) Breaking change PR policy: all breaking API changes require an architecture review. The PR cannot be merged until a migration plan and consumer notification are in place."

*What separates good from great:* "Automated deprecation notification: API gateway logs which client (API key, service name) is calling deprecated endpoints. Weekly automated email to the owning team: 'Your service X called deprecated endpoint Y 15,000 times this week. Sunset date: June 1, 2025.' This makes deprecation visible and actionable for the consuming team, rather than hoping they read Slack announcements."

---

#### Q9 - "Design an API versioning strategy for a public-facing API with 10,000 external developers."
> "Public API versioning must be extremely conservative. Strategy: (1) URL versioning (/v1/, /v2/) for major versions. (2) Minimum 1-year deprecation period after a new version is released before removing v1. (3) Open beta for new versions: release v2 as /v2-beta/ for 3-6 months while collecting feedback. Promote to /v2/ when stable. (4) Change log on developer portal: detailed migration guide for every breaking change. (5) OpenAPI/Swagger spec: machine-readable contract that SDK generators and documentation tools consume. (6) SDKs: publish versioned SDKs in major languages. SDK deprecation follows API deprecation. (7) Webhooks versioning: event payload versioning (same breaking change rules as REST responses). (8) API keys: track per-developer which version they're using. Contact developers directly before their used version is sunset."

*What separates good from great:* "For external developers, breaking changes have higher costs than internal API changes: external developers have no obligation to migrate on your timeline, their code may not be actively maintained, and breaking changes can cause developer churn. The discipline: additive-only changes as the default. Breaking changes are exceptional events requiring substantial justification and very long migration windows."

---

### ⚖️ Comparison Table

| Strategy | Visibility | REST Purity | Client Effort | Cacheable |
|---|---|---|---|---|
| URL Versioning (/v1/) | High | Low | Low | Yes |
| Header Versioning | Low | High | Medium | No (without Vary) |
| Query Parameter | High | Medium | Low | Yes |
| Content Negotiation | Medium | Highest | High | With Vary header |
| No Versioning (Additive only) | N/A | N/A | Zero | Yes |

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


# Microservices Security - Authentication and Authorization

---

### 🎯 Model Answer

**30 seconds:**
> In microservices security, authentication (who are you?) typically happens once at the gateway using JWT or OAuth2. Authorization (what are you allowed to do?) happens at two levels: coarse-grained at the gateway (is this role allowed to call this endpoint?) and fine-grained within each service (can this user access this specific resource?). Service-to-service communication uses mTLS for identity verification and propagates the user's identity via trusted headers or token forwarding.

**3 minutes:**
> Microservices introduce a new security concern: trust between services. In a monolith, internal function calls implicitly trust the caller. In microservices, a request from ServiceA to ServiceB crosses a network boundary. An attacker could call ServiceB directly, bypassing ServiceA's authorization checks. The defense-in-depth approach: (1) Perimeter security: API gateway validates external tokens, prevents unauthenticated access. (2) Service identity: mTLS verifies that ServiceA is actually ServiceA (not an attacker pretending). (3) Authorization at the service: each service verifies that the authenticated user/service is authorized for the specific operation. Token propagation strategies: (1) JWT forwarding: the user's JWT is passed from service to service in the Authorization header. Each service validates the JWT signature. (2) Gateway-injected headers: the gateway validates the JWT, extracts claims, and injects them as trusted headers (X-User-Id, X-User-Role). Services trust these headers because only authenticated requests from the gateway reach them. The common security mistake: services trusting internal network location for authorization ("this request came from our internal network so it must be legitimate"). Zero-trust networking requires identity verification at every hop.

**Blank Mind Recovery:**
**(1) Authentication:** "Who are you? JWT at the gateway, validated once."
**(2) Authorization:** "What can you do? Coarse at gateway, fine-grained in each service."
**(3) Service-to-service:** "mTLS for identity, token forwarding or trusted headers for user context."

---

### 📘 Concept Explanation

**What it is:**
Microservices security is the set of practices for authenticating users and services, authorizing access to resources, and protecting data in a distributed system where requests cross multiple trust boundaries.

**Authentication and authorization layers:**
```
EXTERNAL REQUEST FLOW:

  User -> [HTTPS] -> API Gateway
              |
          JWT validation
          Rate limiting
          IP filtering
          OWASP protection
              |
          [Trusted internal network]
              |
    +----+----+----+
    |         |    |
  OrderSvc  InvSvc  UserSvc
    |         |    |
  Fine-    Fine-  Authoritative
  grained  grained user store
  authz    authz

AUTHENTICATION OPTIONS:
  External users: JWT (OAuth2/OIDC)
  Service-to-service: mTLS (preferred)
                      or JWT (simpler)
  Internal jobs: service account tokens

AUTHORIZATION OPTIONS:
  Gateway: RBAC (role -> endpoint allowed)
  Service: ABAC (user attribs -> resource access)
  Service mesh: service-to-service allow/deny rules
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Zero-trust model:**
```
WRONG (perimeter trust):
  "If request arrived at OrderService, it passed
   the gateway, so the user is authenticated"
  -> An attacker bypassing the gateway can
     call OrderService directly

CORRECT (zero-trust):
  OrderService validates the user's identity on
  every request, regardless of how it arrived.
  Either:
    a) Validate the JWT directly (signature check)
    b) Verify gateway-injected headers only if
       the request provably came from the gateway
       (mTLS + NetworkPolicy)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Scopes and claims in JWT:**
```json
{
  "sub": "user-123",
  "email": "user@example.com",
  "roles": ["customer"],
  "scope": "order:read order:write",
  "tenant": "tenant-456",
  "exp": 1735689600,
  "iss": "https://auth.company.com"
}
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

The service uses these claims for authorization: the user can read and write orders, is in tenant-456, and has the customer role.

**The key insight:**
Authentication is global (done once per request at the gateway or token validation point). Authorization is local (each service decides for itself what an authenticated user can do with that service's resources). Never centralize authorization logic outside the owning service - only the OrderService knows whether user 123 can access order 456 (based on ownership, tenant, etc.).

---

### 💻 Code Example

```java
// BAD: IP-based trust - not zero-trust
@RestController
@RequestMapping("/api/orders")
public class OrderController {
  
  @GetMapping("/{orderId}")
  public OrderResponse getOrder(
      @PathVariable String orderId,
      HttpServletRequest request) {
    // WRONG: trusting based on IP range
    // An attacker in the network bypasses all security
    String clientIp = request.getRemoteAddr();
    if (!clientIp.startsWith("10.0.")) {
      throw new UnauthorizedException();
    }
    // No user identity verification
    // No ownership check
    return orderService.getOrder(orderId);
  }
}
```

> **Code walkthrough:** Trusting requests based on IP address is the most dangerous pattern in microservices. Any pod in the Kubernetes cluster shares the 10.0.x.x network. A compromised pod or a developer misconfiguration can call this endpoint without any user authentication. The IP check provides false security confidence.

```java
// GOOD: JWT validation + fine-grained authorization
@RestController
@RequestMapping("/api/orders")
public class OrderController {
  private final OrderService orderService;

  @GetMapping("/{orderId}")
  @PreAuthorize("hasScope('order:read')")
  public OrderResponse getOrder(
      @PathVariable String orderId,
      @AuthenticationPrincipal JwtToken token) {
    // Fine-grained authorization:
    // is this user allowed to see this specific order?
    String userId = token.getClaim("sub");
    String tenantId = token.getClaim("tenant");
    
    Order order = orderService
        .findById(orderId)
        .orElseThrow(() -> new NotFoundException(
            orderId));
    
    // Ownership check - fine-grained authz
    // Only the order's owner can view it
    // (or an admin - checked by Spring Security)
    if (!order.getCustomerId().equals(userId) ||
        !order.getTenantId().equals(tenantId)) {
      throw new ForbiddenException(
          "Order does not belong to user");
    }
    
    return OrderResponse.from(order);
  }
}
```

> **Code walkthrough:** @PreAuthorize verifies the JWT scope (coarse-grained: user has order:read permission). The fine-grained check: does this user own this specific order? This prevents user A from viewing user B's order even if both have order:read scope. The tenantId check enforces multi-tenant isolation. Both the scope check and the ownership check are needed: scope grants access to the endpoint, ownership grants access to the specific resource.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "In microservices, security happens in layers. The API gateway handles authentication - it validates the JWT token and rejects unauthenticated requests. Inside the network, services receive the user's identity through the token or through headers set by the gateway. Each service then checks if the authenticated user is allowed to do what they're asking - like checking if this user owns the order they're requesting. Services communicate with each other using mTLS for secure encrypted connections."

**Senior / Staff:** "The microservices security design principle is defense in depth. Don't rely on a single chokepoint (the gateway) for all security. The gateway provides perimeter security - but services must independently validate user identity and authorization for every request. This is zero-trust: never trust the network, always verify identity. The service-to-service identity problem is separate: when OrderService calls InventoryService, InventoryService must know that the caller is actually OrderService (not an attacker). mTLS with SPIFFE identity (service mesh) provides this. Without mTLS: any pod in the cluster can call any service. With mTLS + AuthorizationPolicy: only OrderService can call InventoryService's reservation endpoint. Least-privilege service-to-service authorization is as important as user authorization."

---

### ⚠️ Common Misconceptions

**Misconception:** "If the API gateway validates the JWT, internal services don't need to check authentication."
Reality: Services that skip authentication validation on the assumption that only the gateway can reach them have a critical vulnerability: any new service added to the cluster, any misconfigured ingress, or any Kubernetes escape can call internal services directly. Zero-trust requires each service to validate identity independently. The gateway reduces the attack surface but is not a sufficient single control. Each service should either: (a) validate the JWT signature itself (stateless), (b) trust gateway-injected headers only when requests provably came from the gateway via mTLS + NetworkPolicy (defense in depth), or (c) use service mesh mTLS + AuthorizationPolicy (infrastructure-level enforcement).

---

### 🚨 Failure Modes and Diagnosis

**Failure: JWT secret rotation breaks all services simultaneously**

Symptoms: After a security rotation of the JWT signing key, all authenticated requests return 401 Unauthorized across all services. Users are logged out. Services report JWT signature validation failures.

Root cause: Services have the old JWT signing key cached (JwksClient cache). The token validation library is comparing tokens signed with the new key against the old cached key.

Diagnosis: Check service logs for JWT validation errors (invalid signature). Check if the JWT signing key rotation was completed at the identity provider. Check the JwksClient cache TTL in each service - if 24-hour cache, services won't pick up the new key for 24 hours.

Fix: Set JWKS cache TTL to 5-10 minutes (balance between security and performance). When rotating keys: support both old and new keys at the JWKS endpoint for the old key's TTL duration (dual-key rotation). This allows tokens signed with the old key to remain valid during the transition while new tokens are signed with the new key.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Security | 3 min | 3 |
| Scenario | 5 min | 1 |
| Debugging | 2 min | 1 |
| Comparison | 2 min | 1 |
| Trade-off | 2 min | 1 |
| Design | 3 min | 1 |
| Anti-pattern | 2 min | 1 |

#### Q1 - "How do you implement OAuth2 / OIDC in a microservices architecture?"
> "OAuth2/OIDC flow: client (mobile app, web app) redirects user to the Identity Provider (Keycloak, Auth0, Okta). User authenticates. IDP issues: ID token (identity claims, for the client), Access token (JWT, for calling APIs), Refresh token (for obtaining new access tokens). Client sends access token in Authorization: Bearer header to API gateway. Gateway validates the JWT: verify signature against IDP's JWKS endpoint, verify expiration, verify issuer (iss) and audience (aud). JWT is self-contained: services don't need to call the IDP on every request (stateless validation). Claims in the JWT (roles, scopes, tenant, user ID) are used for authorization downstream. Microservices receive the JWT from the gateway (forwarded or transformed into trusted headers) and use the claims for authorization."

*What separates good from great:* "Access token lifespan is a security-performance tradeoff. Short access tokens (5-15 minutes) reduce the window of token misuse after revocation but require frequent refresh. Long tokens (1 hour+) reduce refresh overhead but extend the validity window for stolen tokens. Most production systems: 15-minute access tokens with 7-day refresh tokens. The refresh token is the long-lived credential; access tokens are short-lived capabilities."

---

#### Q2 - "How do services verify they are talking to the correct upstream service (not an impersonator)?"
> "mTLS (mutual TLS): both services present and verify X.509 certificates. The certificate is issued by the cluster CA (Istio, cert-manager). ServiceB verifies that the connecting client's certificate is issued by the trusted CA and has the expected SPIFFE identity (spiffe://cluster.local/ns/default/sa/order-service). An attacker cannot present a valid certificate for order-service without the CA's private key. Kubernetes NetworkPolicy: restricts which pods can connect to which services at the network level. Even without mTLS, NetworkPolicy prevents random pods from reaching protected services. Combined: NetworkPolicy limits which pods can try to connect; mTLS verifies the identity of those that do connect."

*What separates good from great:* "SPIFFE (Secure Production Identity Framework for Everyone) provides a standardized identity format for services. SPIFFE ID: spiffe://trust-domain/path. Each workload has a unique SPIFFE identity based on its Kubernetes service account. This identity is cryptographically bound to the workload (not just an API key that can be copied). When a pod is killed and replaced, the new pod automatically gets the same SPIFFE identity - certificate rotation is automatic."

---

#### Q3 - "How do you implement multi-tenancy security in microservices?"
> "Multi-tenancy means multiple customers (tenants) share the same service infrastructure. Security requirement: tenantA cannot access tenantB's data under any circumstances. Implementation: (1) Tenant ID in JWT: IDP includes tenantId claim in the access token. Services extract tenantId from JWT. All database queries include WHERE tenant_id = ? from the JWT claim. (2) Row-level security (PostgreSQL RLS): the database enforces tenant isolation at the query level. Application sets SET app.tenant_id = ? before queries. RLS policy: USING (tenant_id = current_setting('app.tenant_id')). Any query forgetting to set tenant_id returns zero rows. (3) Schema per tenant: each tenant has a separate database schema. More isolation, more operational overhead. (4) Tenant validator middleware: a middleware in each service that extracts tenantId from JWT and injects it into all queries via a thread-local context."

*What separates good from great:* "Row-level security at the database is defense in depth for multi-tenancy. If the application has a bug (forgot to filter by tenantId), the database RLS policy prevents data leakage. Application-level filtering + database RLS = two independent controls for the most critical multi-tenancy requirement. Regularly test this: attempt cross-tenant access in security test suites."

---

#### Q4 - "Design the security architecture for a healthcare microservices platform."
> "Healthcare: HIPAA compliance, PHI data, role-based access with audit log. Architecture: (1) Identity: identity provider with HIPAA-compliant MFA. JWT tokens with role (physician, nurse, patient, admin), organization (hospital ID), and user ID claims. Token TTL: 15 minutes (short for compliance). (2) Gateway: validates JWT, enforces rate limiting, logs all access attempts. Returns 401 for invalid tokens, 403 for insufficient scope. (3) Service-to-service: mTLS with SPIFFE identity. AuthorizationPolicy: only specific services can call PHI-bearing endpoints. (4) Data access: PHI queries filtered by organization (multi-tenant). Additional check: RBAC (physicians can read all patient data in their organization; patients can only read their own data). (5) Audit log: every PHI access logged with user ID, timestamp, patient ID, data type, purpose. Tamper-evident log to S3 Object Lock. (6) Encryption: PHI encrypted at rest (AES-256), in transit (TLS 1.3), and in Kafka events (field-level encryption for PHI fields)."

*What separates good from great:* "HIPAA requires minimum necessary access principle: users should access only the minimum PHI necessary for their role. Implement this via scope: a nurse preparing medications needs medication data but not billing data. Scopes in JWT are fine-grained by data category. This is ABAC (Attribute-Based Access Control) where data category is an attribute."

---

#### Q5 - "How do you prevent token hijacking and replay attacks?"
> "Token hijacking: stealing a valid JWT and using it from a different location. Mitigations: (1) Short token TTL (15 minutes): stolen token has limited utility. (2) Token binding: bind the access token to the TLS connection (TLS 1.3 token binding). Not widely supported. (3) Audience claim: JWT aud must match the service receiving it. A token issued for the order service cannot be used for the user service. (4) HTTPS everywhere: token can only be stolen if TLS is compromised (rare). Replay attacks: using a captured valid request again. Mitigations: (1) JWT jti (JWT ID) claim: unique ID per token. Service tracks used JTI values and rejects replays. Effective for critical operations (payment, delete). (2) Nonce: include a one-time nonce in the request. Server validates nonce has not been used. (3) Timestamp: include request timestamp. Reject requests older than N seconds."

*What separates good from great:* "Replay protection adds statefulness to token validation (tracking used JTI values in Redis). This is expensive and only warranted for high-risk operations. Most services rely on short TTL + HTTPS + audience binding as sufficient protection. Reserve replay protection for: financial transactions, one-time operations (password reset), and high-privilege administrative actions."

---

#### Q6 - "What is the difference between RBAC and ABAC in microservices authorization?"
> "RBAC (Role-Based Access Control): permissions assigned to roles, roles assigned to users. User has role 'admin', admin role has permission to DELETE /users/{id}. Simple to implement and reason about. Limited expressiveness: cannot encode 'user can only edit their own profile' without a custom ownership check. ABAC (Attribute-Based Access Control): permissions based on attributes of the user, the resource, and the environment. Policy: user.department == resource.department AND action == 'read'. More expressive - can encode fine-grained access rules without code changes. More complex to implement (policy engine like Open Policy Agent). In microservices: gateway RBAC for coarse-grained endpoint access. Service-level ABAC (code-level or OPA policy) for fine-grained resource access."

*What separates good from great:* "Open Policy Agent (OPA) externalizes authorization logic from service code. Service calls OPA with: {user: claims, resource: order_data, action: 'read'}. OPA evaluates the Rego policy and returns allow/deny. Benefits: authorization logic is testable independently, policy changes don't require service redeployment, policies are auditable. The OPA sidecar pattern: OPA runs as a sidecar next to each service (or shared per node). Low latency authorization decisions without external network calls."

---

#### Q7 - "How do you handle secret management for microservices at scale?"
> "Secrets: database passwords, API keys, TLS certificates, JWT signing keys. Never store secrets in code, configuration files checked into Git, or environment variables in deployment YAMLs (leaked in Git history). Vault (HashiCorp Vault): centralized secrets management. Services authenticate to Vault using Kubernetes service accounts. Vault issues short-lived secrets (dynamic secrets: Vault generates a PostgreSQL user+password that expires in 1 hour, rotated automatically). AWS Secrets Manager / Azure Key Vault: cloud-native alternatives. Kubernetes Secrets: base64-encoded, not encrypted at rest by default. Acceptable if etcd encryption is enabled. External Secrets Operator: syncs secrets from Vault/AWS Secrets Manager into Kubernetes Secrets automatically. Services mount Kubernetes Secrets as environment variables or files."

*What separates good from great:* "Dynamic secrets are the gold standard. Instead of a long-lived database password, Vault generates a unique database user with a 1-hour TTL for each service instance. When the TTL expires, the credential is revoked. Even if a credential is leaked, it's valid for at most 1 hour. The surface area for credential compromise is dramatically reduced compared to a shared long-lived password."

---

#### Q8 - "How do you secure Kafka messages in a microservices architecture?"
> "Kafka security layers: (1) Transport: TLS between producers, consumers, and brokers. Encrypts data in transit. (2) Authentication: SASL/SCRAM (username/password), SASL/GSSAPI (Kerberos), mTLS (client certificates). mTLS preferred for service-to-service (same SPIFFE identity used for HTTP). (3) Authorization: Kafka ACLs. Allow/deny specific service accounts to read/write specific topics. InventoryService can only read order-events topic and write inventory-events topic. PaymentService cannot read inventory-events (no need). (4) Encryption at rest: Kafka stores messages on disk. Disk encryption (LUKS, EBS encryption) or application-level field encryption for sensitive fields. (5) Schema Registry: Avro/Protobuf schemas with compatibility enforcement prevent malformed messages."

*What separates good from great:* "Field-level encryption for PII in Kafka events: encrypt specific fields (customer name, email) with a per-tenant key before publishing. Consumers that need the PII data must have access to the decryption key. Consumers that process the event for non-PII purposes (inventory, shipping) never see the PII fields. This implements minimum-necessary access at the event level."

---

#### Q9 - "How do you audit all cross-service calls for compliance purposes?"
> "Cross-service audit requirements: who called what service, when, with what parameters, with what result. Implementation: (1) Service mesh audit log: Istio Envoy sidecar logs all service-to-service calls automatically. Logs include: source service (SPIFFE identity), destination service, timestamp, request method/path, response code. Published to a centralized logging system. (2) Application-level audit: services log business-meaningful audit events (user 123 viewed order 456) to a dedicated audit Kafka topic. Audit service subscribes and stores in an immutable log. (3) API gateway access logs: all external API calls logged at the gateway. (4) Database audit: PostgreSQL audit extension or Debezium CDC captures all data changes with timestamp. Combined: infrastructure-level audit (who called what) + application-level audit (what business action was taken). Both are needed for compliance: infrastructure for security review, application-level for business audit."

*What separates good from great:* "Audit log integrity: audit logs must be tamper-evident for legal compliance. WORM storage (S3 Object Lock with Governance or Compliance mode) prevents deletion or modification. Signed audit entries (HMAC with a per-service key) detect whether an entry was modified after creation. Compliance auditors can verify the audit log hasn't been altered."

---

### ⚖️ Comparison Table

| Mechanism | Who is Verified | Complexity | Token Lifecycle | Use Case |
|---|---|---|---|---|
| JWT (user) | User identity + claims | Low | Short-lived (15min) | External user requests |
| mTLS (service) | Service identity | Medium | Auto-rotated (24h) | Service-to-service |
| API Key | Client application | Low | Long-lived (manual rotation) | Third-party integrations |
| RBAC | Role membership | Low | Per role assignment | Coarse-grained endpoint access |
| ABAC + OPA | User + resource attributes | High | Policy-based | Fine-grained resource access |

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



