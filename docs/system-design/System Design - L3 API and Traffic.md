---
layout: default
title: "System Design - L3 API and Traffic"
parent: "System Design"
grand_parent: "SK Interview"
nav_order: 6
permalink: /system-design/l3-api-and-traffic/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [System Design - L3 API and Traffic](#system-design---l3-api-and-traffic) | medium |
| 2 | [API Gateway Pattern](#api-gateway-pattern) | medium |
| 3 | [Rate Limiting](#rate-limiting) | medium |

---

# API Gateway Pattern

---
id: SSD-013
title: API Gateway Pattern
category: System Design
difficulty: ★★☆
interview_weight: high
asked_at: Senior/Staff
seniority: senior
tags: #api-gateway, #bff, #rate-limiting, #auth, #routing, #microservices
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> An API Gateway is a single entry point for all client requests to a microservices
> backend. It handles: routing (forward /orders to orders-service), authentication
> (validate JWT before forwarding), rate limiting (10 req/sec per user), SSL
> termination, and request aggregation (combine multiple service calls into one
> client response). It removes the need for each microservice to implement these
> cross-cutting concerns independently.

**3 minutes:**
> Without an API Gateway, clients know about all services (direct coupling),
> each service handles its own auth/rate-limiting (duplication), and SSL certs
> are managed per service. The Gateway is the single point where cross-cutting
> concerns are centralized.
>
> The pattern: client sends one request -> Gateway authenticates, rate-limits,
> routes, transforms -> internal service receives clean request. Service doesn't
> need to know about the outside world.
>
> BFF (Backend for Frontend): a specialized Gateway per client type. The mobile
> BFF aggregates the exact data mobile needs (fewer API calls, smaller payloads).
> The web BFF delivers richer data for the web dashboard. One BFF per client
> type prevents the "one-size-fits-all API" that either bloats mobile responses
> or requires multiple web calls. Netflix, Spotify use BFF extensively.

**Blank Mind Recovery:**

**(1) Restate:** "API Gateway: the front door to your microservices. One URL,
handles auth, routing, everything."

**(2) Without it:** "Every service handles its own auth, rate limiting, SSL.
Every client knows about every service. Change one service: update all clients."

**(3) BFF insight:** "Different clients need different data. Mobile: compact.
Web: rich. One-size API forces a choice; BFF gives each client what it needs."

---

### 📘 Concept Explanation

**API Gateway responsibilities:**

```
Client request flow with API Gateway:

  Mobile App -> HTTPS -> [API Gateway]
  Web App    -> HTTPS -> [API Gateway]
  3rd Party  -> HTTPS -> [API Gateway]

  API Gateway:
    1. SSL Termination: decrypt HTTPS, forward HTTP internally
    2. Authentication: validate JWT/API key
    3. Authorization: check permissions (role: admin, user)
    4. Rate Limiting: 100 req/min per user (Redis-based)
    5. Routing: /api/orders -> orders-service:8080
                /api/users -> user-service:8080
    6. Load Balancing: distribute across service instances
    7. Request Transformation: translate API v1 to v2 internally
    8. Response Aggregation: call 3 services, merge response
    9. Circuit Breaking: fail fast if downstream is down
    10. Logging/Tracing: add request-id, log access

  Services only see:
    Clean authenticated request
    No TLS, no auth logic, no rate limiting logic

API Gateway vs Load Balancer vs Service Mesh:
  Load Balancer: distributes traffic across servers (L4/L7)
  API Gateway: cross-cutting concerns for external clients (L7)
  Service Mesh: service-to-service concerns internally (L7 sidecar)

  External traffic: Client -> API Gateway -> Service Mesh -> Service
  API Gateway: external facing
  Service Mesh: internal facing
```

> **Code walkthrough:** This API Gateway Pattern example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**BFF (Backend for Frontend) pattern:**

```
Problem with single API Gateway:
  Mobile App: needs compact product list (id, name, thumbnail)
  Web Dashboard: needs full product detail + analytics
  Admin Tool: needs product + audit log + pricing

  One API Gateway response:
    Returns full product object (designed for richest client)
    Mobile gets 10KB response, uses 1KB
    9KB wasted bandwidth on every mobile request

BFF Solution:
  Mobile BFF: optimized for mobile
    /products -> returns: id, name, thumbnail_url, price
    Aggregates: product-service + image-service (compressed)
    One call from mobile -> one optimized response

  Web BFF: optimized for web dashboard
    /products -> returns: full product + recommendations + analytics
    Aggregates: product + recommendation + analytics services

  Admin BFF: optimized for admin tool
    /products -> returns: product + audit + pricing history

  Each BFF:
    Maintained by the frontend team that uses it
    Evolves independently
    Aggregates/transforms as needed for that client
```

> **Code walkthrough:** This API Gateway Pattern example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

```java
// Spring Cloud Gateway configuration (Java DSL)
@Configuration
public class GatewayConfig {

    @Bean
    public RouteLocator routes(
            RouteLocatorBuilder builder) {
        return builder.routes()
            // Route: /api/orders/** -> order-service
            .route("order-service", r -> r
                .path("/api/orders/**")
                .filters(f -> f
                    .stripPrefix(1)  // /api/orders -> /orders
                    .addRequestHeader("X-Request-Id",
                        UUID.randomUUID().toString())
                    .circuitBreaker(c -> c
                        .setName("order-service")
                        .setFallbackUri("forward:/fallback/orders"))
                    .retry(config -> config
                        .setRetries(3)
                        .setStatuses(HttpStatus.BAD_GATEWAY)))
                .uri("lb://order-service"))  // load-balanced

            // Route: /api/users/** -> user-service
            .route("user-service", r -> r
                .path("/api/users/**")
                .filters(f -> f
                    .requestRateLimiter(c -> c
                        .setRateLimiter(redisRateLimiter())
                        .setKeyResolver(userKeyResolver())))
                .uri("lb://user-service"))

            // Aggregation route: /api/dashboard
            // (calls multiple services, merges response)
            .route("dashboard", r -> r
                .path("/api/dashboard")
                .filters(f -> f
                    .requestRateLimiter(c -> c
                        .setRateLimiter(redisRateLimiter())))
                .uri("lb://dashboard-aggregator"))
            .build();
    }

    @Bean
    public RedisRateLimiter redisRateLimiter() {
        // 10 requests/second per key, burst 20
        return new RedisRateLimiter(10, 20, 1);
    }

    @Bean
    public KeyResolver userKeyResolver() {
        // Rate limit per user (from JWT sub claim)
        return exchange -> exchange.getPrincipal()
            .map(Principal::getName)
            .defaultIfEmpty("anonymous");
    }
}

// JWT authentication filter (global):
@Component
public class JwtAuthFilter
        implements GlobalFilter, Ordered {

    private final JwtTokenProvider jwtProvider;

    @Override
    public Mono<Void> filter(
            ServerWebExchange exchange,
            GatewayFilterChain chain) {
        String token = extractToken(exchange.getRequest());
        if (token == null) {
            exchange.getResponse()
                .setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
        try {
            Claims claims = jwtProvider.validate(token);
            // Add user info to headers for downstream services
            ServerWebExchange mutated = exchange.mutate()
                .request(r -> r
                    .header("X-User-Id", claims.getSubject())
                    .header("X-User-Roles",
                        claims.get("roles", String.class)))
                .build();
            return chain.filter(mutated);
        } catch (JwtException e) {
            exchange.getResponse()
                .setStatusCode(HttpStatus.UNAUTHORIZED);
            return exchange.getResponse().setComplete();
        }
    }

    @Override
    public int getOrder() {
        return -100;  // run before routing filters
    }
}
```

> **Code walkthrough:** Spring Cloud Gateway's RouteLocator defines routing rulesice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> as a Java DSL. The order-service route strips the `/api` prefix before forwarding
> (service doesn't need to know about the gateway path). The circuit breaker filter
> wraps the call: if order-service fails, the gateway calls the fallback endpoint
> (returns a cached or degraded response). The rate limiter uses Redis to track
> request counts per user key (extracted from JWT). The JwtAuthFilter runs globally
> (all routes) before routing, validates JWT, and injects user claims as headers.
> Downstream services read `X-User-Id` and `X-User-Roles` headers - they don't
> do JWT validation themselves. Security concern: downstream services must only
> accept these headers from the gateway (internal network trust), not from external
> clients (to prevent header injection).

```java
// BFF aggregation pattern:
@RestController
public class MobileDashboardBff {

    private final ProductServiceClient productService;
    private final CartServiceClient cartService;

    // One endpoint, aggregates from 2 services
    @GetMapping("/mobile/dashboard")
    public Mono<MobileDashboard> getDashboard(
            @RequestHeader("X-User-Id") String userId) {
        // Parallel calls to both services
        Mono<List<ProductSummary>> products =
            productService.getTopProducts(10)
                .map(this::toMobileSummary);  // compact format

        Mono<CartSummary> cart =
            cartService.getCart(userId)
                .map(this::toMobileCart);  // count + total only

        return Mono.zip(products, cart)
            .map(tuple -> new MobileDashboard(
                tuple.getT1(),  // 10 products (compact)
                tuple.getT2()   // cart (count only)
            ));
    }

    // Compact mobile format: less data, smaller payload
    private ProductSummary toMobileSummary(Product p) {
        return ProductSummary.builder()
            .id(p.getId())
            .name(p.getName())
            .thumbnailUrl(p.getThumbnailUrl())  // small image
            .price(p.getCurrentPrice())
            .build();
        // NOT: description, full image list, reviews, inventory
    }
}
```

> **Code walkthrough:** The Mobile BFF aggregates two service calls in parallelice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> (Mono.zip = run both simultaneously, wait for both). It transforms the full
> Product model into a compact ProductSummary with only the fields mobile needs.
> This BFF is owned by the mobile team: they control the response shape.
> When the mobile app's requirements change (add a "on sale" flag), the mobile
> team updates the BFF - no coordination with product-service or cart-service
> required. The web BFF and admin BFF evolve independently. This is the
> organizational benefit of BFF beyond the technical benefits.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> An API Gateway is a reverse proxy that sits in front of your microservices.
> Clients make requests to the gateway; the gateway authenticates, then routes
> the request to the right service. The benefits: clients don't know about your
> internal service topology, and cross-cutting concerns like authentication and
> rate limiting are handled in one place.

**Senior / Staff:**
> The API Gateway has two failure modes to design against. First: the gateway
> becomes a bottleneck (all external traffic passes through one process). Solution:
> run multiple gateway instances behind a load balancer (stateless gateways scale
> horizontally). Second: the gateway becomes operationally complex (every new
> feature adds gateway config). Solution: limit the gateway to infrastructure
> concerns (auth, rate limiting, routing, SSL) and push business logic to services.
> The BFF pattern solves the aggregation problem without over-burdening the gateway:
> each client type has a thin BFF that aggregates what that client needs, while
> the core gateway handles infrastructure concerns only.

---

### ⚠️ Common Misconceptions

**Misconception: "API Gateway is the same as a load balancer."**
Load balancer: distributes traffic across identical instances (same service,
multiple pods). API Gateway: routes to different services based on URL/headers,
enforces auth, rate limiting, transformations. A load balancer is one feature
inside an API gateway. Most API gateways have built-in load balancing. The
semantic difference: load balancer = horizontal scaling; API gateway = service
routing + cross-cutting concerns.

---

### 🚨 Failure Modes and Diagnosis

**Failure: API Gateway becomes single point of failure**
Symptom: gateway goes down, all external traffic blocked.
Cause: single gateway instance, no redundancy.
Diagnosis: check gateway instance count, health check history.
Fix: run 2+ gateway instances behind a cloud load balancer (AWS ALB + multiple
gateway pods). Gateways are stateless (rate limit state in Redis): add instances
freely. Monitor gateway instance health, latency, error rates separately from
downstream services.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] How does an API Gateway handle authentication vs authorization?**

```
Authentication (who are you?):
  Gateway verifies identity: is this JWT valid?
  Methods:
    JWT Bearer token: validate signature + expiry
    API Key: check against valid key database
    OAuth2 introspect: call auth server to validate token
    mTLS: verify client certificate

  Gateway action:
    Valid: extract claims (user_id, roles) -> headers -> pass
    Invalid: 401 Unauthorized -> reject

Authorization (what can you do?):
  Two models:

  Model 1: Gateway-level authorization
    Gateway checks: does user have role X to access path Y?
    Simple RBAC: /admin/** requires role=ADMIN
    Implementation: route filter checks X-User-Roles header
    Pros: centralized, no duplication
    Cons: fine-grained business rules don't belong at gateway

  Model 2: Service-level authorization
    Gateway: only does authentication (passes user info)
    Service: checks: can user X access resource Y?
    Example: "Can user 42 access order 99?" (is it their order?)
    Pros: service has context to make the decision
    Cons: every service implements authorization logic

  Best practice:
    Gateway: authentication (who) + coarse-grained authorization (role)
    Service: fine-grained authorization (can you access THIS resource?)
    Reason: gateway can't know "is this user's order?"
            only the order service can check user_id == order.user_id
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The gateway should enforce minimum viable
authorization: reject unauthenticated requests (401) and enforce role-based
access to API segments (/admin requires ADMIN role). Fine-grained authorization
(can this user access this specific resource?) belongs in the service. The
anti-pattern: every fine-grained rule in the gateway config. This creates a
configuration that grows without bound and must be updated whenever business
rules change. Principle: the gateway knows "are you allowed to call this API
category?" The service knows "are you allowed to do this specific operation?"

---

**[JUNIOR] Q2 - [HANDS-ON] How do you implement API versioning at the gateway?**

API versioning: support multiple API versions simultaneously.

```
Versioning strategies:

URL path versioning:
  /api/v1/products -> product-service v1
  /api/v2/products -> product-service v2
  Clear, discoverable, cacheable
  Downside: URL changes between versions (bookmarks break)

  Gateway routing:
    path: /api/v1/** -> product-service-v1
    path: /api/v2/** -> product-service-v2
    OR: header injection: X-API-Version: 1 -> same service

Header versioning:
  GET /api/products
  Accept: application/vnd.myapp.v2+json
  Gateway: inspect Accept header -> route to v2 handler
  Clean URLs, but less discoverable, cache requires Vary header

Query param versioning:
  GET /api/products?version=2
  Simple to implement, explicit
  Not HTTP-standard, not ideal for REST

Sunset/deprecation:
  Gateway: adds header to v1 responses:
  Sunset: Sat, 01 Jan 2026 00:00:00 GMT
  Deprecation: true
  Monitors: track v1 vs v2 traffic
  Deprecation plan: notify users of v1, set sunset date, remove route

Version migration:
  Gateway transforms v1 requests to v2 internally:
    v1 /products/{id} -> transform -> v2 /products (new format)
    Reduces service complexity (only maintain one version)
    Gateway handles translation
    Downside: transformation logic in gateway (tight coupling)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The cleanest versioning strategy: maintain
one current API version in services; let the gateway handle version translation
for older clients. Old clients call v1; the gateway transforms to v2 format
before calling the service. This avoids running multiple service versions
simultaneously. The tradeoff: transformation logic in the gateway couples it
to the API schema. Evaluate: is the transformation simple (rename field A to B)?
Use gateway transformation. Is it complex (completely different data model)?
Run both service versions. Monitor adoption to know when to sunset old versions.

---

**[JUNIOR] Q3 - [CONCEPTUAL] How does the API Gateway handle service discovery?**

```
Static routing (hardcoded):
  Gateway config: /api/orders -> http://order-service:8080
  Problem: service IP changes -> update gateway config
  Use: development, single service instances

DNS-based discovery:
  Gateway: /api/orders -> http://order-service (DNS name)
  Kubernetes Service: order-service resolves to pod IPs
  Gateway: uses DNS, Kubernetes handles routing to pods
  Benefits: simple, Kubernetes-native
  Limitations: doesn't know about health, load distribution is at DNS level

Service registry (Eureka, Consul):
  Services: register on startup with Eureka
  Gateway: queries Eureka for service instances
  Gateway: load balances across registered instances
  Benefits: real-time instance list, health-aware (only healthy instances)
  Spring Cloud: @EnableEurekaServer, @EnableDiscoveryClient

  Spring Cloud Gateway + Eureka:
    uri: lb://order-service
    -> Ribbon/LoadBalancer queries Eureka for "order-service" instances
    -> Load balances across instances

Kubernetes native (service name):
  uri: http://order-service.default.svc.cluster.local:8080
  -> Kubernetes DNS resolves to ClusterIP
  -> kube-proxy routes to pod
  -> Gateway uses Kubernetes native discovery

  Spring Cloud Gateway on Kubernetes:
    @Bean
    RouteLocator routes(...) {
        return builder.routes()
            .route(r -> r.path("/orders/**")
                .uri("http://order-service:8080"))  // K8s DNS
            .build();
    }
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* In Kubernetes environments, Kubernetes-native
service discovery (ClusterIP Service + DNS) is sufficient for most cases. Adding
Eureka on top of Kubernetes adds operational overhead without much benefit.
Kubernetes already provides: service discovery (DNS), health-based routing
(readiness probe removes unhealthy pods from endpoints), load balancing
(kube-proxy). The gateway uses Kubernetes Services, which handle all the details.
Eureka is valuable when services run outside Kubernetes (VMs, legacy systems)
or in multi-cloud environments where Kubernetes services don't span clusters.

---

**[MID] Q4 - [ARCHITECTURE] How do you handle API Gateway performance at high scale?**

API Gateway performance tuning:

```
Key metrics to optimize:
  Latency added by gateway: should be < 5ms P99
  Throughput: gateway should not be the bottleneck

Performance patterns:

1. Stateless gateway (horizontal scale):
  No local state (rate limit state in Redis, not JVM memory)
  Scale: add more gateway instances freely
  Load balanced: multiple gateways behind cloud LB

2. Async (reactive) gateway:
  Spring Cloud Gateway: Project Reactor (non-blocking)
  Netty under the hood: handles 10K+ concurrent connections per instance
  NOT Spring MVC (blocking): Spring MVC = one thread per connection
  Reactive: one thread handles N connections (I/O-bound efficiency)

3. JWT validation optimization:
  JWT signature check: CPU-bound (~0.5ms per validation)
  At 50K QPS: 50K * 0.5ms = 25 CPU-seconds/sec = 25 cores just for JWT
  Optimization:
    Cache validated JWTs for their remaining validity period
    Key: JWT signature (hash), value: decoded claims
    TTL: min(JWT expiry, 5 minutes)
    Cache hit: skip validation (~0.01ms)
    Cache hit rate 99%: 25 cores -> 0.25 cores for JWT validation

4. Route matching optimization:
  Linear search through routes: O(N) per request
  With 1000 routes: 1000 comparisons per request
  Optimization: trie-based route matching (O(path length))
  Spring Cloud Gateway: optimized internally
  Custom routing: build prefix tree for /api/{service}/**

5. Connection pooling to backends:
  HTTP keepalive to backend services
  Without pool: TCP handshake per request (1-3ms each)
  With pool: reuse existing connections
  Netty: connection pooling by default
  Tune: max connections per backend
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The JWT caching optimization is significant
at scale and commonly overlooked. JWT validation is CPU-intensive but deterministic
(same token = same result until expiry). Caching validated tokens in Redis or
Caffeine (in-process) turns JWT validation from O(1) crypto operation to O(1)
hash lookup. The cache key: the JWT signature (last part of the token).
The cache value: the decoded claims. The TTL: remaining JWT validity.
Security concern: if a JWT is revoked (user logout, password change), it stays
in the cache until TTL expires. Solution: short JWT TTL (15 minutes) + maintain
a small revocation list in Redis (check cache + revocation list). Revocation
list only holds actively revoked tokens (typically very few at any moment).

---

**[MID] Q5 - [ARCHITECTURE] What is the circuit breaker pattern at the gateway level?**

Gateway circuit breaker: protect the gateway from cascading failures.

```
Without circuit breaker:
  Order service: takes 30 seconds to respond (DB overloaded)
  Gateway: forwards requests, waits 30 seconds each
  100 concurrent requests: 100 * 30s = all gateway threads blocked
  Gateway: becomes unavailable (thread exhaustion)

With circuit breaker (Resilience4j in gateway):
  Order service: slow responses
  Circuit breaker: counts failures/timeouts
  Threshold exceeded: circuit OPENS
  Open state: gateway returns fallback immediately (no wait)
  After timeout: circuit HALF-OPEN -> probe request
  If probe succeeds: circuit CLOSES (normal)

  Fallback options:
    Return cached last-known response
    Return error with retry-after hint
    Return degraded response (partial data)

Spring Cloud Gateway circuit breaker:
  .route("order-service", r -> r
      .path("/api/orders/**")
      .filters(f -> f
          .circuitBreaker(c -> c
              .setName("order-cb")
              .setFallbackUri("forward:/fallback/orders")))
      .uri("lb://order-service"))

  // Fallback controller:
  @GetMapping("/fallback/orders")
  public ResponseEntity<OrderFallback> ordersFallback() {
      return ResponseEntity.status(503)
          .body(new OrderFallback(
              "Orders temporarily unavailable",
              Instant.now().plus(30, ChronoUnit.SECONDS)));
  }
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The circuit breaker at the gateway level is
the last line of defense for external clients. Service-level circuit breakers
(Resilience4j in the service) protect services from their dependencies. Gateway
circuit breakers protect the gateway from downstream service failures propagating
to all clients. Both layers are needed. The operational question: "What should
a client see when the order service is down?" The answer must be designed (fallback
response) and tested (chaos engineering: kill order service, verify gateway returns
503 + fallback body, verify circuit breaker metrics). Untested fallbacks often
have bugs discovered at the worst moment (production incident).

---

**[MID] Q6 - [CONCEPTUAL] How do you handle API security at the gateway?**

Security layers at the API Gateway:

```
1. TLS Termination:
  All external traffic: HTTPS only
  HTTP: redirect to HTTPS (301)
  HSTS header: strict-transport-security: max-age=31536000
  Certificate: auto-renewed (AWS ACM, cert-manager)

2. Authentication:
  JWT Bearer: validate RS256/ES256 signature
              (asymmetric = only auth server has private key)
  API Key: hash-based lookup (don't store keys in plain text)
  OAuth2: introspect endpoint or validate JWT

3. Input Validation (basic):
  Max request size: reject payloads > 1MB
  Max URL length: reject URLs > 2KB
  Content-Type: validate for POST/PUT (expected JSON/XML)
  Gateway validates structure, not business logic

4. Rate Limiting:
  Per-user: 100 req/min per authenticated user
  Per-IP (unauthenticated): 10 req/min per IP
  Per-API key (external partners): customized limits
  Global: 100K req/sec total (protect all backends)

5. DDoS Protection:
  IP reputation: block known malicious IPs (Cloudflare)
  Geo-blocking: block traffic from regions (OFAC compliance)
  Anomaly detection: sudden 10x traffic spike -> alert

6. Injection prevention at gateway:
  Parameter sanitization: reject SQL metacharacters in path params?
  No: gateway shouldn't parse business data
  Service: validates and sanitizes business inputs
  Gateway: structural validation only

7. Logging (security-relevant):
  Log: client IP, user_id, API path, status code, latency
  NOT log: request body (may contain PII, credentials)
  Retention: 90 days (security incident investigation)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* JWT algorithm confusion attack: if your
gateway accepts both RS256 (asymmetric) and HS256 (symmetric), an attacker can
take a valid RS256 JWT, modify the header to say HS256, and sign it with the
RS256 public key (which is public knowledge). If your library validates HS256
signatures using the RS256 public key as the HMAC secret: attacker has forged
a valid JWT. Fix: in the gateway JWT validator, ONLY accept the expected algorithm
(RS256 or ES256). Reject any JWT that claims HS256. This is a real CVE-class
vulnerability in several JWT libraries. The secure pattern: specify the exact
expected algorithm in the validation configuration; never auto-detect.

---

**[SENIOR] Q7 - [HANDS-ON] How do you implement a GraphQL API Gateway?**

GraphQL gateway aggregates multiple services into one schema.

```
GraphQL API Gateway patterns:

Schema Stitching (older approach):
  Multiple GraphQL services -> gateway merges schemas
  Gateway: executes cross-service queries
  Query: { user { name orders { total } } }
    -> User service: { user { name } }
    -> Order service: { orders(userId: X) { total } }
    -> Gateway merges results

Federation (Apollo Federation - current standard):
  Each service owns its schema entities
  Product service: type Product @key(fields: "id")
  Review service: type Product @key(fields: "id") @extends
                  type Review { product: Product }
  Gateway (Apollo Router): routes subqueries, merges responses

  Benefits:
    Decentralized: each team owns their service + schema
    No central schema management
    Services extend entities from other services (federation)

  Apollo Router (Rust):
    ~10ms gateway overhead (Rust performance)
    Query planning: decomposes one GraphQL query into subqueries
    Parallel execution: independent subqueries run in parallel
    Caching: response caching per operation + variables

Tradeoffs vs REST gateway:
  GraphQL: flexible queries, over-fetching/under-fetching eliminated
           complex query planning, schema coordination required
  REST: simpler gateway (URL-based routing), HTTP caching native
        clients may need multiple calls for aggregated data

Performance:
  N+1 problem in GraphQL: query {products{reviews}}
    -> 1 query for products, N queries for reviews
  Solution: DataLoader (batch + cache)
    Instead of N separate review queries:
    Batch all review lookups: IN (1,2,3,...N)
    Return all reviews in one query
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Apollo Federation is the production-proven
solution for multi-team GraphQL at scale. The key architectural constraint: each
entity has one primary service that defines it. Other services can extend it with
additional fields but can't redefine its primary keys. This prevents schema
conflicts between teams. The operational challenge: the gateway's query plan
depends on the schema from all services. Schema changes in one service can
affect query plans for unrelated queries. Apollo Schema Registry + schema checks
in CI (breaking change detection) prevent accidental schema regressions that
break clients.

---

**[SENIOR] Q8 - [CONCEPTUAL] How does API Gateway observability work?**

Observability at the API Gateway layer:

```
Three pillars for API Gateway:

1. Metrics:
  Per-route metrics:
    request_count{route="order-service", status="2xx"}
    request_latency_p99{route="order-service"}
    circuit_breaker_state{circuit="order-service"}

  Global metrics:
    gateway_requests_total
    gateway_connections_active
    rate_limit_rejected_requests_total

  Alert on:
    P99 latency > 200ms for any route
    Error rate > 1% for any route
    Circuit breaker open for any circuit

2. Logs:
  Structured log per request:
  {
    "timestamp": "2024-01-15T10:30:00Z",
    "request_id": "550e8400-...",
    "user_id": "user123",
    "path": "/api/orders",
    "method": "GET",
    "status": 200,
    "latency_ms": 45,
    "route": "order-service",
    "client_ip": "1.2.3.4"
  }
  Note: no request body (PII), no auth tokens

3. Distributed Tracing:
  Gateway: generates trace ID (if not present)
  Propagates: traceparent header to all downstream calls
  Service: records spans with same trace ID
  Jaeger/Zipkin: correlates spans into full request trace

  Trace spans:
    Gateway: 0ms (receive) -> 50ms (respond)
      Order service: 5ms (receive) -> 45ms (respond)
        DB query: 10ms -> 40ms
    Total: 50ms, DB is 30ms (60% of total)
    Bottleneck identified: DB (not service or gateway)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The distributed trace from gateway to service
to database is the key tool for latency diagnosis. Without distributed tracing,
you see: "Gateway latency is 200ms." With tracing: "Gateway: 5ms, Order service:
10ms, DB query: 185ms (slow index scan)." The actionable difference. The challenge:
trace propagation requires all services to participate (read + write trace headers).
Spring Boot + Micrometer Tracing (Sleuth replacement) auto-instruments most HTTP
calls. The organizational discipline: treat missing trace propagation as a bug,
not optional. A service that doesn't propagate traces breaks the full chain view.

---

**[SENIOR] Q9 - [TRADE-OFF] What are the trade-offs between API Gateway and Service Mesh?**

```
API Gateway:
  Role: external-facing entry point
  Clients: end users (mobile, web), third-party API consumers
  Concerns: auth, rate limiting, URL routing, SSL, API versioning
  Protocol: HTTP/HTTPS (external)
  Layer: before traffic enters the cluster

Service Mesh (Istio, Linkerd):
  Role: internal service-to-service communication
  Clients: services within the cluster
  Concerns: mTLS, circuit breaking, retries, load balancing,
            traffic shifting (canary within cluster)
  Protocol: HTTP, gRPC, TCP
  Layer: inside the cluster, sidecar to each service

When to use each:
  API Gateway only (small system):
    - Simple routing + auth is sufficient
    - No internal service mesh needed
    - Small number of services (<20)

  API Gateway + Service Mesh (mature system):
    - External traffic: handled by API Gateway
    - Internal traffic: handled by Service Mesh
    - Service mesh provides mTLS (zero-trust internal network)
    - Gradual traffic shifting for internal canary deployments

  Costs of Service Mesh:
    - Sidecar proxy per pod: ~50-100MB additional memory per pod
    - Istio control plane: 1-2 additional pods
    - Added network hop: +1-2ms per call (Envoy sidecar)
    - Operational complexity: Istio has steep learning curve

Decision framework:
  <20 services: API Gateway only
  >20 services + security requirements (mTLS): add service mesh
  >50 services + canary/traffic management: service mesh essential
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using Kafka messaging. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The service mesh vs API gateway conflation
is common. Key distinction: API Gateway is for external consumers; service mesh
is for internal service-to-service security and reliability. Both can handle
retries and circuit breaking, but at different layers. If you implement retry
in the gateway AND in the service mesh AND in the application code: you have
3 layers of retry, which can multiply into 27 attempts (3^3) for one failed
request. Layer responsibility: gateway retries for transient client-gateway
errors; service mesh retries for transient internal errors; application retries
for business-level retries. Define which layer owns retry for each type and
disable the others.

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


# Rate Limiting

---
id: SSD-014
title: Rate Limiting
category: System Design
difficulty: ★★☆
interview_weight: high
asked_at: Senior/Staff
seniority: senior
tags: #rate-limiting, #throttling, #token-bucket, #leaky-bucket, #ddos
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Rate limiting controls how many requests a client can make in a time window.
> Algorithms: token bucket (allow burst, average rate enforced), leaky bucket
> (smooth output rate), fixed window counter (simple, window boundary burst risk),
> sliding window log (accurate, high memory), sliding window counter (approximate,
> memory-efficient). Redis atomic operations implement distributed rate limiting.
> Response: HTTP 429 Too Many Requests with Retry-After header.

**3 minutes:**
> Rate limiting serves multiple purposes: prevent abuse (DDoS, credential stuffing),
> ensure fairness (one tenant can't consume all capacity), protect downstream
> services (DB, external APIs have limits), and enforce monetization tiers
> (Free: 100/hour, Pro: 10K/hour).
>
> Algorithm choice: token bucket is the most common. Allows burst (up to bucket
> size) while enforcing average rate. A user can make 20 requests at once
> (burst = bucket size), but the long-term average is enforced (1 token added/second
> = 3600/hour). Leaky bucket produces a constant output rate - no bursting.
> Good for smoothing traffic before a rate-limited backend API.
>
> Distributed rate limiting: state must be shared across gateway instances.
> Redis INCR + EXPIRE for fixed window (atomic, simple). Sorted set with timestamp
> scores for sliding window (accurate, more memory). Lua scripts for token bucket
> (atomic check-and-update).

**Blank Mind Recovery:**

**(1) Restate:** "Rate limiting: limit how many requests a user or IP can make
per second/minute/hour."

**(2) Why needed:** "Prevent: (1) overload from one bad actor, (2) abuse
(brute-force, scraping), (3) expensive operations (AI inference) being abused."

**(3) Token bucket:** "Bucket fills at rate R. Max capacity B. Each request
consumes 1 token. If bucket empty: 429. Allows bursting up to B."

---

### 📘 Concept Explanation

**Rate limiting algorithms:**

```
Fixed Window Counter:
  Window: 1 minute (e.g., 10:00:00 - 10:01:00)
  Count: requests in this window
  Limit: 100 requests per window

  Problem: boundary burst
    00:59: 100 requests (window 1 fills up)
    01:00: new window starts -> 100 more requests allowed
    01:01: total 200 requests in 2 minutes, 100 in 1 minute at boundary

  Simple Redis impl:
    key = "rl:{userId}:{minute}"  (e.g., rl:user1:202401151000)
    INCR key -> count
    EXPIRE key 60 -> auto-clean
    count > limit: return 429

Token Bucket:
  Bucket: max B tokens (burst capacity)
  Fill rate: R tokens/second (average rate)
  Request: consume 1 token
  Empty bucket: 429 Too Many Requests

  Behavior: user can burst up to B requests,
            but average is limited to R/sec

  Example: R=10/sec, B=100 (10 second burst)
    Idle for 10 sec: bucket fills to 100
    User sends 100 requests at once: all allowed (burst)
    Next request: bucket empty -> 429
    Wait 1 second: 10 tokens -> 10 more requests

Leaky Bucket:
  Queue: fixed size Q
  Output: constant rate R requests/second (processed)
  Input: requests added to queue
  Full queue: 429

  Behavior: smooths traffic to constant output rate
  No burst: output is always <= R/sec
  Use: smoothing traffic to rate-limited external API
       (e.g., external API allows 10/sec, no burst)

Sliding Window Log:
  Maintain sorted set: {timestamp: user_id} per user
  New request: prune entries older than window
  Count remaining entries
  If count < limit: allow + add entry
  If count >= limit: 429

  Accurate: no boundary burst issue
  Memory: O(requests per window) per user (high for large windows)

Sliding Window Counter:
  Approximate sliding window using two counters
  Counter_prev = count in previous window
  Counter_curr = count in current window
  Position = fraction of current window elapsed (0.0 - 1.0)
  Approximate count = counter_prev * (1 - position) + counter_curr
  If approx < limit: allow

  Memory: O(1) per user (only 2 counters)
  Accuracy: within ~0.003% error rate (empirically measured)
```

> **Code walkthrough:** This Rate Limiting example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 💻 Code Example

```java
// Token Bucket rate limiter with Redis Lua script
@Component
public class TokenBucketRateLimiter {

    private final RedisTemplate<String, String> redis;

    // Lua script: atomic token bucket check + consume
    private static final String TOKEN_BUCKET_SCRIPT = """
        local key = KEYS[1]
        local capacity = tonumber(ARGV[1])
        local refill_rate = tonumber(ARGV[2])
        local requested = tonumber(ARGV[3])
        local now = tonumber(ARGV[4])

        local last_refill = tonumber(
            redis.call('hget', key, 'last_refill') or now)
        local tokens = tonumber(
            redis.call('hget', key, 'tokens') or capacity)

        -- Refill tokens since last request
        local elapsed = math.max(0, now - last_refill)
        local new_tokens = math.min(
            capacity,
            tokens + elapsed * refill_rate)

        if new_tokens >= requested then
            -- Allow: consume tokens
            redis.call('hset', key, 'tokens',
                new_tokens - requested)
            redis.call('hset', key, 'last_refill', now)
            redis.call('expire', key, 3600)
            return 1  -- allowed
        else
            -- Deny: not enough tokens
            return 0  -- denied
        end
        """;

    /**
     * Check if request is allowed for the given key.
     * capacity: max burst size
     * refillRate: tokens added per second (= avg req/sec)
     */
    public boolean isAllowed(String key,
                              int capacity,
                              double refillRate) {
        double now = System.currentTimeMillis() / 1000.0;

        Long result = redis.execute(
            new DefaultRedisScript<>(
                TOKEN_BUCKET_SCRIPT, Long.class),
            List.of("tb:" + key),
            String.valueOf(capacity),
            String.valueOf(refillRate),
            "1",  // consume 1 token per request
            String.valueOf(now));

        return Long.valueOf(1L).equals(result);
    }
}

// Gateway filter using rate limiter:
@Component
@RequiredArgsConstructor
public class RateLimitFilter
        implements GlobalFilter, Ordered {

    private final TokenBucketRateLimiter rateLimiter;

    @Override
    public Mono<Void> filter(
            ServerWebExchange exchange,
            GatewayFilterChain chain) {
        String userId = exchange.getRequest()
            .getHeaders()
            .getFirst("X-User-Id");

        String key = userId != null ?
            "user:" + userId :
            "ip:" + getClientIp(exchange.getRequest());

        // Tier-based limits:
        int capacity = isProUser(userId) ? 1000 : 100;
        double refillRate = isProUser(userId) ? 16.7 : 1.67;
        // Pro: 1000/min avg = 16.7/sec
        // Free: 100/min avg = 1.67/sec

        if (!rateLimiter.isAllowed(key, capacity, refillRate)) {
            ServerHttpResponse response = exchange.getResponse();
            response.setStatusCode(HttpStatus.TOO_MANY_REQUESTS);
            response.getHeaders().set(
                "Retry-After", "60");
            response.getHeaders().set(
                "X-RateLimit-Limit",
                String.valueOf(capacity));
            return response.setComplete();
        }

        return chain.filter(exchange);
    }

    @Override
    public int getOrder() { return -50; }
}
```

> **Code walkthrough:** The Lua script runs atomically in Redis. It reads theice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> current token state (tokens, last_refill_time) from a Redis hash. It calculates
> how many tokens have been added since the last request (elapsed * refill_rate).
> If sufficient tokens: consume 1, update state, return "allowed." If insufficient:
> return "denied" without modifying state. Atomicity is critical: without the
> Lua script, concurrent requests could both see "sufficient tokens" and both
> consume, exceeding the limit. The gateway filter applies tier-based limits:
> Pro users get 10x more capacity and refill rate. The 429 response includes
> `Retry-After: 60` (client should wait 60 seconds) and `X-RateLimit-Limit`
> (so client can adjust behavior). Good API design: tell clients what the limit
> is and when they can retry.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Rate limiting prevents users from sending too many requests and overwhelming
> the system. The simplest approach: count requests in a time window per user.
> If the count exceeds the limit: return 429 Too Many Requests. Redis is used
> for distributed rate limiting because the counter must be shared across all
> gateway instances (if each gateway kept its own counter, a user could send
> 10 requests to each of 10 gateways and get 100 total, bypassing a 10-request
> limit).

**Senior / Staff:**
> Rate limiting has an accuracy vs cost tradeoff. Fixed window is O(1) memory
> but has boundary burst vulnerability. Sliding window log is perfectly accurate
> but O(requests) memory. Token bucket is the practical choice: O(1) memory,
> allows burst, accurate average rate enforcement. At high scale: the rate
> limiter itself can become a bottleneck (every request hits Redis for a Lua script).
> Optimization: local (in-process) rate limiter as first filter (approximate,
> no network), then Redis as second filter (exact, shared). Local filter eliminates
> 90% of requests before they hit Redis. Only requests that pass the local limiter
> check Redis. This layering reduces Redis load 10x while maintaining accuracy.

---

### ⚠️ Common Misconceptions

**Misconception: "Rate limiting at the gateway prevents DDoS completely."**
Rate limiting is a throttling tool, not a DDoS shield. A volumetric DDoS
(10 Gbps UDP flood) overwhelms the gateway before it can rate-limit individual
requests. DDoS mitigation requires: Anycast routing (Cloudflare absorbs attack
at edge), BGP blackholing (upstream block attack traffic), scrubbing centers
(filter malicious traffic before it reaches your network). Rate limiting protects
against API abuse and application-layer attacks (HTTP floods from limited IPs)
but cannot absorb volumetric network attacks.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Rate limiter Redis outage causes false 429s or no limiting**
Symptom A: Redis down -> rate limiter throws -> gateway returns 429 to all users.
Symptom B: Redis down -> rate limiter silently ignores -> no limiting (all traffic passes).
Best practice: Redis unavailable -> fail open (allow traffic, log alert).
Reason: user-facing 429s from infrastructure failure = bad UX; brief no-limiting
window = acceptable (attackers also can't plan Redis outages).
Mitigation: local in-process fallback rate limiter (approximate) when Redis is down.

---

### 🎯 Interview Deep-Dive

**Timing:** Medium ★★☆ - 9 questions.

---

**[JUNIOR] Q1 - [CONCEPTUAL] How do you rate limit by user tier (free vs paid)?**

Tiered rate limiting: different limits per user/plan.

```
Tier definitions:
  Free: 100 req/min, burst 200
  Pro: 10,000 req/min, burst 20,000
  Enterprise: custom limits per tenant

Implementation approaches:

1. Hardcoded tiers (gateway config):
  if (user.plan == PRO) limit = 10000
  else limit = 100
  Simple, fast, no DB lookup
  Problem: plan changes need gateway redeploy

2. JWT claim-based:
  JWT: { "sub": "user123", "plan": "pro", "rate_limit": 10000 }
  Gateway: reads rate_limit from JWT claim
  Pro: no DB lookup, plan embedded in token
  Con: JWT refresh needed when plan changes (until old JWT expires)

3. External lookup (plan service):
  Gateway: calls plan-service to get user's limits
  Plan-service: returns rate limits from DB
  Cache: cache limits in gateway (TTL 5 minutes)
  Pro: real-time plan changes (effective within TTL)
  Con: adds latency (plan-service call, even with cache)

4. Redis-based tier storage:
  On user plan change:
    HSET user:123:rl capacity 10000 refill_rate 167
  Gateway: reads from Redis (same Redis as rate counter)
  Single Redis round-trip: get limit AND count
  Efficient: no separate service call

  Rate limiter Lua script:
    Reads limits AND current count in one atomic script
    No separate lookup
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* JWT-embedded rate limits are the cleanest
approach for most SaaS products. The plan is baked into the token at login time.
When a user upgrades: force token refresh (revoke old JWT, issue new one with
new plan). The 5-minute delay between upgrade and new rate limits is acceptable
for most products. Redis-based limits are better when: rate limits change frequently
(dynamic pricing, per-API-endpoint limits per plan). The Stripe approach: their
API rate limits are per API key, configurable per integration, stored in their
systems and checked on every request via Redis.

---

**[JUNIOR] Q2 - [CONCEPTUAL] How do you handle distributed rate limiting across multiple data centers?**

Multi-datacenter rate limiting: coordinating counters across regions.

```plaintext
Problem:
  User in US: makes 60 requests to US datacenter
  User in EU: same user makes 60 requests to EU datacenter
  Each datacenter allows 100/min
  Total: 120 requests (exceeds intended 100/min global limit)

Solutions:

Option 1: Single global Redis (simplest):
  All rate limit counters in one Redis cluster
  All datacenters: query same Redis
  Problems:
    - Cross-datacenter latency (+100ms per request for EU->US Redis)
    - Single Redis = SPOF for all rate limiting
    - GDPR: EU data in US Redis?

Option 2: Synchronous distributed counter:
  Each DC has local Redis
  On each request: increment local + sync to global
  Global sync: expensive (synchronous cross-DC)
  Not practical for high-throughput rate limiting

Option 3: Regional rate limits (practical):
  Global limit 100/min split across regions:
    US region: 60/min
    EU region: 40/min (based on traffic distribution)
  Each region has independent Redis
  No cross-region coordination
  Trade-off: user can get 60+40=100 by using both regions
             but normal users don't route to multiple DCs

Option 4: Approximate global (async sync):
  Each DC: local Redis for primary counting
  Every 5 seconds: sync local count to global Redis
  Rate limit check: local count + estimated global adjustment
  Approximate: +-5 second lag
  Good enough for most use cases (not financial APIs)
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* For most SaaS products: regional rate limits
(option 3) are sufficient. Users don't route through multiple datacenters unless
they're explicitly trying to bypass rate limits. If they are: add a per-user
global count synced to a global Redis every few seconds (option 4). For payment
APIs or security-sensitive rate limiting: stricter global synchronization is
needed even with added latency. The key question: "Can a user harm our system by
routing to multiple regions to bypass rate limits?" If yes: global coordination.
If no: regional limits are simpler and more resilient.

---

**[JUNIOR] Q3 - [CONCEPTUAL] What HTTP headers should a rate-limited API response include?**

Standard rate limit headers:

```
Successful response (within limit):
  X-RateLimit-Limit: 100           (requests allowed in window)
  X-RateLimit-Remaining: 47        (requests left this window)
  X-RateLimit-Reset: 1705312800    (Unix timestamp: when window resets)

  Or (newer draft standard):
  RateLimit-Limit: 100
  RateLimit-Remaining: 47
  RateLimit-Reset: 60              (seconds until reset)

429 Too Many Requests:
  HTTP/1.1 429 Too Many Requests
  Retry-After: 47                  (seconds until allowed again)
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 0
  X-RateLimit-Reset: 1705312800

  Body:
  {
    "error": "rate_limit_exceeded",
    "message": "Request limit exceeded. Retry after 47 seconds.",
    "retry_after": 47,
    "limit": 100,
    "window": "minute"
  }

Implementation in Spring:
  .headers(h -> {
      h.set("X-RateLimit-Limit", String.valueOf(limit));
      h.set("X-RateLimit-Remaining",
          String.valueOf(remaining));
      h.set("X-RateLimit-Reset",
          String.valueOf(windowResetEpochSeconds));
  })

Client behavior (expected):
  Check X-RateLimit-Remaining after every response
  When Remaining < 10: slow down proactively
  On 429: wait Retry-After seconds, then retry
  Exponential backoff: if 429 again, double wait time
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The Retry-After header is the most important
for good client behavior. Without it: clients either retry immediately (creating
a retry storm) or wait an arbitrary time. With it: clients know exactly when to
retry. The IETF rate limit headers draft (RFC-6585 for 429, draft-ietf-httpapi-
ratelimit-headers for the header spec) is becoming the standard. Implementing
the standard headers means clients using HTTP client libraries (Faraday in Ruby,
Axios in Node.js) can automatically respect rate limits if the library supports
the headers. Document your rate limits in the API reference, including the limit
per tier and the window duration.

---

**[MID] Q4 - [DEBUGGING] How does rate limiting interact with client retry logic?**

Retry + rate limiting interaction creates thundering herd risk:

```plaintext
Scenario without proper retry:
  All clients hit rate limit simultaneously (traffic spike)
  All get 429
  All retry after 1 second (fixed interval)
  All hit rate limit again simultaneously
  Pattern: synchronized retry wave (thundering herd)

Thundering herd amplification:
  1000 clients, rate limit 100/sec
  All 1000 hit limit -> 900 get 429
  900 retry at T+1s -> 900 simultaneous requests
  100 allowed, 800 get 429 again
  Never clears: wave of retries blocks recovery

Fix: jittered exponential backoff
  Base wait: 1 second
  Attempt 1: 1s + random(0, 1) = 1-2 seconds
  Attempt 2: 2s + random(0, 2) = 2-4 seconds
  Attempt 3: 4s + random(0, 4) = 4-8 seconds
  Max: 30 seconds

  Jitter distributes retries:
  1000 clients: retry between 1-2s (uniformly distributed)
  100-200 retry per second -> matches rate limit
  No wave effect

Server-side guidance:
  429 Retry-After: set to window reset time (not constant)
  Client respects Retry-After: waits specified time
  Server-side rate limit: don't give all clients same window reset
  Rolling windows: different users have staggered windows
    -> Retries after 429 naturally spread out
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using concurrency primitive. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The combination of server-side Retry-After
with client-side jitter is the standard solution. The server tells clients
the exact wait time; the client adds jitter to avoid synchronized retries.
AWS SDK, Google Cloud client libraries, and most modern HTTP clients implement
jittered exponential backoff with Retry-After handling. The engineering discipline:
test rate limiting behavior in load tests, not just happy-path tests. Send traffic
at 110% of rate limit for 60 seconds and verify: the system stabilizes at the
rate limit, doesn't create growing retry queues, and recovers cleanly when
traffic drops below the limit.

---

**[MID] Q5 - [CONCEPTUAL] How do you rate limit based on cost instead of request count?**

Cost-based rate limiting: different operations have different "weights."

```
Why cost-based:
  Simple endpoint: GET /products (10ms, low CPU)
  Expensive endpoint: POST /ai/generate (5 seconds, high GPU)

  Request-based: both cost 1 token (unfair to system)
  Cost-based: /products = 1 token, /ai/generate = 100 tokens

Implementation:
  Per-endpoint cost config:
    endpoints:
      GET /products: cost: 1
      GET /products/{id}/recommendations: cost: 5
      POST /ai/generate: cost: 100
      POST /bulk/import: cost: 10

  Rate limiter: consume cost tokens, not 1 token
    GET /products: tokens -= 1
    POST /ai/generate: tokens -= 100

  User sees: 1000 "credits" per minute
    Can make: 1000 product calls, OR 10 AI calls, OR mix

  Token bucket: capacity = 1000, refill = 1000/min
    AI call: costs 100 tokens (10% of bucket per call)
    Max AI: 10 per minute (1000/100)
    Max product: 1000 per minute (1000/1)

Stripe's approach:
  API calls weighted by complexity
  "Read" operations: 1 credit
  "Write" operations: 5 credits
  "List" operations (expensive pagination): variable
  API key has "read capacity" and "write capacity" limits
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Cost-based rate limiting is important for
AI/ML API monetization. OpenAI uses token-count-based rate limiting (tokens = words
in input + output). LLM inference cost scales with token count, so token-based
limits align the rate limit with actual cost. For traditional APIs: cost-based
limits align with actual server resource consumption (CPU, DB queries). The
implementation overhead is small (just multiply cost by the request's weight
in the token bucket), but the fairness improvement is significant. Teams
building expensive operations (search with many joins, complex aggregations)
should consider cost-based limits to prevent one expensive call type from
consuming the entire rate limit budget.

---

**[MID] Q6 - [HANDS-ON] How do you build rate limiting for a multi-tenant API?**

Multi-tenant rate limiting: fair resource allocation across tenants.

```plaintext
Requirements:
  Tenant isolation: Tenant A's heavy usage doesn't affect Tenant B
  Fair allocation: each tenant gets their contracted limit
  Priority: Enterprise tenants may get priority over Free

Key dimensions:
  Per-tenant limit: prevent one tenant from consuming all capacity
  Per-user-within-tenant: prevent one user from using all tenant quota
  Global system limit: hard cap on total system load

Hierarchical rate limiting:
  Level 1 (global): 1M req/min total (system protection)
  Level 2 (per-tenant): 10K req/min (enterprise), 1K (pro), 100 (free)
  Level 3 (per-user-within-tenant): 100 req/min max

  Check order: user -> tenant -> global
  First limit hit: 429

Redis key structure:
  Global: "rl:global:{window}"
  Tenant: "rl:tenant:{tenantId}:{window}"
  User: "rl:user:{tenantId}:{userId}:{window}"

  Atomic multi-check Lua script:
    Check all 3 levels in one round-trip
    If any fails: return which limit was hit

Rate limit response with tenant context:
  X-RateLimit-Scope: tenant  (which level was hit)
  X-RateLimit-Limit: 10000   (tenant's limit)
  X-RateLimit-Remaining: 0
  Tenant error: "Your organization's rate limit exceeded.
                 Upgrade plan for higher limits."
  vs User error: "Your personal rate limit exceeded.
                  Try again in 60 seconds."
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The error message must tell the user WHICH
limit was hit and WHAT they can do about it. "User's personal limit exceeded:
wait 60 seconds" is actionable. "Tenant's organization limit exceeded: contact
your admin or upgrade" is actionable but requires different action (can't wait
it out individually). The tenant admin dashboard should show: current usage vs
limit, historical usage trends, per-user breakdown within the tenant. This
self-service observability reduces support tickets about rate limits and helps
tenants right-size their plans.

---

**[SENIOR] Q7 - [DEBUGGING] How do you implement rate limiting for login/auth endpoints?**

Auth endpoint rate limiting: security-critical, different from API rate limiting.

```
Login rate limiting (brute force prevention):

1. Per-username rate limit:
  key: "rl:login:{username}"
  Limit: 5 failed attempts per 15 minutes
  After 5 failures: lockout
  Lockout: either "account locked" (notify user)
            or "slow response" (mitigate timing attacks)

  Problem: account enumeration
    "Account locked" reveals the username exists
    "Login failed" is ambiguous (could be wrong username OR locked)
    Best: always "Invalid username or password"

2. Per-IP rate limit:
  key: "rl:login_ip:{ip_address}"
  Limit: 20 login attempts per hour per IP
  Distributed attack: many IPs -> per-IP limit evaded
  Additional: per-IP honeypot (rate limit after suspicious pattern)

3. Global login rate limit:
  Protect the login endpoint itself from flooding
  Even if user/IP limits not hit: global cap
  Prevents login endpoint becoming a DDoS vector

4. CAPTCHA after N failures:
  After 3 failed attempts from same browser/IP: require CAPTCHA
  Cost for attacker: manual CAPTCHA solving (expensive at scale)
  Cost for legitimate user: minor friction after failures

5. Progressive delays:
  Attempt 1-3: immediate response
  Attempt 4: 1 second delay
  Attempt 5: 5 second delay
  Attempt 6+: 30 second delay
  Attacker: slowed to ~2 attempts/minute
  Legitimate user (forgot password): brief delay is acceptable
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Account lockout must include an unlock mechanism.
"5 failures = locked forever" creates a DOS attack vector: attacker locks all
user accounts by intentionally failing logins. Solutions: (1) time-based unlock
(locked for 15 minutes, auto-unlock), (2) email-based unlock (send unlock link),
(3) admin-assisted unlock. Time-based is most user-friendly for most cases.
For high-security (banking): email-based unlock with identity verification.
Monitor failed login rate: a spike means either a brute-force attack or a
legitimate bug (wrong client sending wrong credentials). Alert on: >100 failed
logins per minute from a new IP, or >10 failures for the same account in 5 minutes.

---

**[SENIOR] Q8 - [CONCEPTUAL] How does rate limiting work in Kubernetes with Envoy/Istio?**

Kubernetes-native rate limiting with service mesh:

```plaintext
Istio + Envoy rate limiting:

Option 1: Local rate limiting (per-pod):
  Each Envoy sidecar independently limits requests
  Simple, no external service needed
  Problem: 10 pods * 100 req/sec = 1000 req/sec total
  User can bypass by hitting different pods

  Istio EnvoyFilter (local):
    apiVersion: networking.istio.io/v1alpha3
    kind: EnvoyFilter
    spec:
      filters:
        - name: envoy.filters.http.local_ratelimit
          typedConfig:
            tokenBucket:
              maxTokens: 100
              tokensPerFill: 100
              fillInterval: 1s

Option 2: Global rate limiting (shared state):
  External rate limit service (Redis-backed)
  All Envoy sidecars call the rate limit service
  Shared counter across all pods

  Envoy: on each request:
    gRPC call -> rate-limit-service
    rate-limit-service: check Redis counter
    Response: OVER_LIMIT or OK
    Overhead: ~1-2ms for gRPC + Redis

  Rate limit service: envoy-ratelimit (Envoy open source project)
    Config: rate_limits per route/header/IP

Option 3: Gateway-level (most practical):
  Rate limiting at ingress-nginx / Istio gateway
  Not in every sidecar
  Gateway: aggregates all traffic, applies limits
  Services: don't need to know about rate limits

  NGINX Ingress rate limit:
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "5"
    nginx.ingress.kubernetes.io/limit-whitelist: "10.0.0.0/8"
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using container. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* Local rate limiting per pod is simple but
doesn't provide true per-user limiting across the cluster. If you run 10 pods
each with a 10 req/sec limit per user: a user can legitimately send 100 req/sec
by having their requests distributed across pods. For most applications: this
is acceptable (gateway-level rate limiting handles the global cap; per-pod
limits prevent any one pod from being overwhelmed). For strict per-user global
limits: global rate limiting with shared Redis is necessary. The architectural
decision: implement at the gateway (one place, global) and accept that pod-level
protection is secondary. Only add pod-level if you've proven the gateway isn't
sufficient.

---

**[SENIOR] Q9 - [HANDS-ON] How do you test rate limiting implementation?**

Rate limiting testing strategy:

```
Unit tests (algorithm correctness):
  Token bucket:
    Test: start full bucket (capacity=10), send 10 requests -> all allowed
    Test: send 11 requests -> 10 allowed, 1 denied
    Test: send 10 requests, wait 5 seconds (at rate 2/sec), send 10 more
          -> first 10 allowed, 10 allowed (5 sec * 2/sec = 10 tokens refilled)

  Fixed window boundary:
    Test: send 10 at 00:59:59, send 10 at 01:00:00 (new window)
          -> 20 total allowed (boundary burst)
          vs sliding window: 10 allowed at 01:00:00 (still within 1 min)

  Concurrent correctness:
    10 threads, each sends 10 requests to shared Redis counter
    Total: 100 requests, limit 50
    Exactly 50 allowed, 50 denied (not 100 allowed due to race condition)
    Assert: sum of allowed across all threads = 50 +-1 (atomic Lua)

Integration tests:
  Start gateway + Redis
  Send requests at 2x rate limit
  Assert: HTTP 429 after limit reached
  Assert: Retry-After header present
  Assert: after window reset, requests allowed again

Load tests:
  JMeter/k6 at 3x expected peak traffic
  Assert: system stable (no thread exhaustion, no OOM)
  Assert: rate limit kicks in, not service crash
  Assert: recovery after traffic drops

Chaos tests:
  Redis down: rate limiter fails open (allow traffic) or closed?
  Redis slow (50ms): does rate limit add 50ms to all requests?
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

*What separates good from great:* The concurrent correctness test is the most
important. Without it: a race condition in the rate limiter might allow 2x the
limit under concurrent load. The atomic Lua script prevents this, but only if
tested. The load test scenario "3x expected peak traffic" verifies the system
doesn't crash when rate-limited - it should reject requests cleanly, not exhaust
threads or OOM. And the Redis failure test: "what happens when rate limiting
infrastructure fails?" is a production scenario that must be tested. An alert
fires when Redis is down; in the meantime, the system should continue serving
traffic (fail open). The test verifies this fail-open behavior explicitly.

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



