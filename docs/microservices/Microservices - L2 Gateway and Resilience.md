---
layout: default
title: "Microservices - L2 Gateway and Resilience"
parent: "Microservices"
grand_parent: "SK Interview"
nav_order: 4
permalink: /microservices/l2-gateway-and-resilience/
render_with_liquid: false
---

# API Gateway Pattern

---

### 🎯 Model Answer

**30 seconds:**
> An API gateway is a single entry point for all external client requests to a microservices system. It handles cross-cutting concerns - authentication, rate limiting, routing, SSL termination, and request logging - in one centralized place. Without a gateway, every service would need to implement authentication independently, and clients would need to know the addresses of individual services. The gateway abstracts the internal topology and provides a unified, stable external interface.

**3 minutes:**
> The API gateway solves the N-client-to-M-service problem. Without it, a mobile app must call UserService, OrderService, and InventoryService directly. Any change to the internal service topology (splitting a service, renaming an endpoint) requires updates to the mobile app. With a gateway: the mobile app calls one address. The gateway routes to the appropriate backend services. Internal topology changes are transparent to clients. Core gateway responsibilities: routing (map incoming requests to backend services), authentication and authorization (validate tokens before requests reach services), rate limiting (prevent abuse, enforce quotas per client), SSL termination (handle HTTPS at the gateway, plain HTTP internally), and request transformation (adapt client-specific formats to backend formats). Common implementations: Kong (open-source, pluggable), AWS API Gateway (managed), Spring Cloud Gateway (code-first in Spring ecosystems), Nginx/Traefik (reverse proxy with routing). The Backend-for-Frontend (BFF) pattern is a gateway variant: a separate gateway implementation per client type (mobile BFF, web BFF) that aggregates and transforms data specifically for each client's needs, eliminating over-fetching.

**Blank Mind Recovery:**
**(1) Restate:** "API gateway - the front door for all external traffic to microservices."
**(2) Responsibilities:** "Routing, auth, rate limiting, SSL, logging - all in one place so services don't each implement these."
**(3) Benefit:** "Clients don't know internal service topology. Internal changes don't break clients."

---

### 📘 Concept Explanation

**What it is:**
An API gateway is a reverse proxy that sits between external clients and internal services. It is the single network entry point for external traffic. The gateway enforces policies, routes requests, and aggregates responses from multiple services when needed.

**Gateway responsibilities:**
```
CLIENT REQUEST FLOW:

  Mobile App -> HTTPS -> [API Gateway]
                              |
                    +----+----+----+----+
                    |    |         |    |
                 Auth  Rate    Log  Route
                 Check Limit       |
                                   +-> OrderService
                                   +-> UserService
                                   +-> InventoryService

GATEWAY HANDLES (cross-cutting):
  Authentication: validate JWT, OAuth token
  Authorization: verify role/scope claims
  Rate limiting: 1000 req/min per API key
  SSL termination: HTTPS at gateway, HTTP internal
  Request routing: /api/v1/orders -> OrderService
  Response aggregation: combine N service responses
  Request/response logging: all access in one place
  Request transformation: adapt mobile format to backend
```

**Backend-for-Frontend (BFF):**
```
WITHOUT BFF:
  Mobile App -> Gateway -> UserService (N fields)
  Mobile App -> Gateway -> OrderService (M fields)
  Mobile App does multiple calls, gets too much data,
  does client-side aggregation

WITH BFF:
  Mobile App -> MobileBFF -> UserService (needed fields)
                          -> OrderService (needed fields)
                          Aggregates, filters, returns
                          exactly what mobile needs

  Web App -> WebBFF -> (different aggregation for web)

Benefits:
  - Each client gets exactly what it needs
  - No over-fetching (unused fields)
  - Backend services unchanged
  - Client-specific optimization
```

**The key insight:**
The gateway is infrastructure, not business logic. The moment business rules appear in the gateway, they belong in a service instead. A gateway that validates whether a user is allowed to place an order based on account standing is doing work that should be in OrderService.

---

### 💻 Code Example

```java
// Spring Cloud Gateway route configuration
// (code-first approach, Java config)
@Configuration
public class GatewayConfig {

  @Bean
  public RouteLocator customRoutes(
      RouteLocatorBuilder builder) {
    return builder.routes()
        // Order service route
        .route("order-service", r -> r
            .path("/api/v1/orders/**")
            .filters(f -> f
                .addRequestHeader("X-Forwarded-By",
                    "api-gateway")
                .requestRateLimiter(c -> c
                    .setRateLimiter(redisRateLimiter())
                    .setKeyResolver(userKeyResolver())))
            .uri("lb://order-service"))
        // User service route
        .route("user-service", r -> r
            .path("/api/v1/users/**")
            .filters(f -> f
                .addRequestHeader("X-Forwarded-By",
                    "api-gateway"))
            .uri("lb://user-service"))
        .build();
  }

  @Bean
  public RedisRateLimiter redisRateLimiter() {
    // 10 requests per second, burst up to 20
    return new RedisRateLimiter(10, 20);
  }
  
  @Bean
  public KeyResolver userKeyResolver() {
    // Rate limit per authenticated user ID
    return exchange -> Mono.just(
        exchange.getRequest().getHeaders()
            .getFirst("X-User-Id"));
  }
}
```

> **Code walkthrough:** Spring Cloud Gateway routes are configured as filters on path-matched rules. The `lb://` prefix triggers Kubernetes service load balancing. Rate limiting is applied per user ID using Redis for distributed state. The X-Forwarded-By header identifies the gateway in downstream service logs. Route configuration centralizes cross-cutting concerns without modifying backend services.

```java
// JWT authentication filter at gateway layer
@Component
public class JwtAuthenticationFilter 
    implements GlobalFilter {
  
  private final JwtValidator jwtValidator;

  @Override
  public Mono<Void> filter(ServerWebExchange exchange,
      GatewayFilterChain chain) {
    String authHeader = exchange.getRequest()
        .getHeaders()
        .getFirst(HttpHeaders.AUTHORIZATION);
    
    if (authHeader == null || 
        !authHeader.startsWith("Bearer ")) {
      exchange.getResponse()
          .setStatusCode(HttpStatus.UNAUTHORIZED);
      return exchange.getResponse().setComplete();
    }
    
    String token = authHeader.substring(7);
    return jwtValidator.validate(token)
        .flatMap(claims -> {
          // Add verified claims to headers for
          // downstream services (they trust gateway)
          ServerWebExchange mutated = exchange
              .mutate()
              .request(r -> r
                  .header("X-User-Id",
                      claims.getUserId())
                  .header("X-User-Role",
                      claims.getRole()))
              .build();
          return chain.filter(mutated);
        })
        .onErrorResume(e -> {
          exchange.getResponse()
              .setStatusCode(HttpStatus.UNAUTHORIZED);
          return exchange.getResponse().setComplete();
        });
  }
}
```

> **Code walkthrough:** JWT validation happens once at the gateway. Validated user information is forwarded as trusted headers to downstream services. Backend services trust X-User-Id and X-User-Role without re-validating the JWT - they trust that only authenticated requests pass through the gateway. This eliminates N services each implementing JWT validation, but requires the gateway to be the only entry point (no direct service access bypassing the gateway).

---

### 🎓 Answers by Seniority

**Junior / Mid:** "An API gateway is the single entry point for all external requests to a microservices system. When a mobile app wants to get order data, it calls the API gateway, not the order service directly. The gateway handles authentication, rate limiting, and routing to the correct backend service. This means each service doesn't need to implement authentication itself, and clients don't need to know the addresses of each individual service."

**Senior / Staff:** "The API gateway is a double-edged sword. It solves the cross-cutting concerns problem elegantly but creates a potential bottleneck and single point of failure. The design discipline: keep the gateway thin - routing, auth, rate limiting, SSL. Any business logic in the gateway is a sign that a service is missing. The BFF variant is valuable for client-specific optimization: a mobile app and a web app have very different data needs. A dedicated mobile BFF aggregates exactly the right data for mobile in one call instead of requiring 3-4 calls from the mobile app. The operational risk: if the gateway goes down, all external access is lost. Architect for high availability: multiple gateway replicas, health checks on gateway pods, circuit breakers for gateway-to-service calls."

---

### ⚠️ Common Misconceptions

**Misconception:** "The API gateway should aggregate all backend responses for every client request."
Reality: Response aggregation in the gateway is appropriate for specific patterns (BFF) but not as a general principle. Aggregating all responses at the gateway creates tight coupling between the gateway and multiple backend services, making the gateway complex and brittle. Most request routing should be simple pass-through. Aggregation should be in dedicated BFF services, not in the core gateway routing layer.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Gateway becomes the bottleneck under high load**

Symptoms: Gateway CPU and memory are high. Gateway response times increase under load even though backend services have capacity. P99 gateway latency is 3x higher than sum of backend latencies.

Root cause: Gateway is doing too much CPU-intensive work per request: JWT verification, request/response transformation, logging serialization. Under high request volume, gateway CPU saturates.

Diagnosis: Profile gateway CPU usage by request type. Check if JWT verification is being done per-request rather than cached. Check response transformation logic for N^2 operations.

Fix: Cache JWT validation results for the token's remaining TTL (not re-validating the same token on every request). Offload response transformation to backend services or BFFs. Scale gateway horizontally - it should be stateless and horizontally scalable. Benchmark to establish gateway throughput limits and monitor saturation.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Comparison | 2 min | 1 |
| Scenario | 5 min | 2 |
| Debugging | 3 min | 1 |
| Trade-off | 2 min | 1 |
| Misconception | 2 min | 1 |
| Security | 3 min | 1 |
| Scale | 2 min | 1 |

#### Q1 - "What is the difference between an API gateway and a load balancer?"
> "A load balancer distributes traffic across multiple instances of the same service - pure traffic distribution without content awareness. An API gateway is content-aware: it routes based on path, headers, or request body; applies authentication, authorization, and rate limiting; and can transform requests and responses. They serve different purposes. A load balancer scales a single service. An API gateway routes across multiple different services and enforces cross-cutting policies. In Kubernetes: Kubernetes Service with kube-proxy is a load balancer (distributes across pod instances). An Ingress controller with routing rules is closer to a gateway. A full API gateway (Kong, Spring Cloud Gateway) adds auth, rate limiting, and transformation on top."

*What separates good from great:* "In practice, a modern system uses both: a cloud load balancer at the edge for DDoS protection and anycast routing, then an API gateway for application-level routing and policy, then Kubernetes Services for internal load balancing. Each layer has a different scope and responsibility."

---

#### Q2 - "What is the Backend-for-Frontend pattern and when should you use it?"
> "BFF creates a dedicated gateway per client type (mobile, web, IoT). Each BFF aggregates and transforms backend data specifically for its client. Without BFF: the mobile app needs user name, latest order, and 2 notification counts. It makes 3 separate API calls, receives 500 fields total, and discards 490 of them. With a Mobile BFF: one API call returns the 10 fields the mobile app needs, aggregated from 3 backend services. Use BFF when: different clients have significantly different data needs (mobile needs less data, web needs more), when client-side aggregation is causing performance issues (too many API calls on slow mobile networks), or when client-specific transformations would complicate the core backend services."

*What separates good from great:* "Each BFF is typically owned by the frontend team that consumes it. This aligns ownership - the mobile team owns the Mobile BFF, enabling them to optimize their own integration without coordinating with backend teams for every UI change. BFF as an architectural pattern makes the 'who owns this?' question clear."

---

#### Q3 - "How do you rate limit at the API gateway and what are the common algorithms?"
> "Common rate limiting algorithms: token bucket (a bucket holds N tokens, each request consumes one, tokens refill at a rate; allows burst up to bucket size), leaky bucket (requests enter a queue, processed at a constant rate; excess dropped; smooths traffic), fixed window counter (count requests in a fixed time window, reset counter at window end; allows burst at window boundaries), sliding window log (log each request timestamp, count requests in last N seconds; precise but memory-heavy), sliding window counter (approximation using two fixed windows; accurate and memory-efficient). Implementation at gateway: rate limit state stored in Redis (distributed, shared across gateway instances). Rate limit key: by API key, user ID, or IP. Return 429 Too Many Requests with Retry-After header when exceeded. Spring Cloud Gateway integrates with Redis for distributed rate limiting."

*What separates good from great:* "Rate limiting should be per-client, not per-IP. IP rate limiting is easily circumvented (NAT, VPNs). API key or JWT-based rate limiting is more accurate and fairer. Also rate limit by endpoint (write endpoints get stricter limits than read endpoints) because write operations are typically more expensive."

---

#### Q4 - "Design an API gateway for a financial services company."
> "Requirements: security, compliance audit log, rate limiting, multi-protocol support. Design: gateway at the edge handles: mTLS for all service-to-service calls, JWT/OAuth validation for user requests, client certificate for partner API access. Routing: /api/v1/accounts -> AccountService, /api/v1/payments -> PaymentService, /api/v1/reports -> ReportingService. Rate limiting: tiered by customer type (retail: 100/min, premium: 1000/min, institutional: 10000/min). Audit logging: every request logged to immutable audit log (legal requirement). The gateway logs: timestamp, user ID, endpoint, IP, response code. No request/response body logging for PCI compliance (cardholder data must not be logged). Circuit breaker: payment service gets a 5-second circuit break period after 50% error rate. Reject requests during the break rather than queuing them for a slow service."

*What separates good from great:* "The audit log is a compliance requirement that the gateway uniquely satisfies: centralized logging of all API access. Backend services only see requests that pass the gateway. The gateway's audit log is authoritative for 'who called what, when.' Design the audit log to be write-only from the gateway (append-only S3, immutable storage), resistant to tampering."

---

#### Q5 - "What security responsibilities belong in the API gateway vs in the services?"
> "Gateway: authentication (validate JWT, OAuth token, API key), coarse-grained authorization (is this user's role allowed to call this endpoint at all?), SSL/TLS termination, IP allowlisting/blocklisting, DDoS protection and rate limiting, request header injection (add X-User-Id from validated token), request size limits. Services: fine-grained authorization (can this user access this specific order ID?), business rule validation (is this order in a state where it can be cancelled?), input validation and sanitization (prevent injection attacks), business data encryption. The principle: the gateway enforces access control. Services enforce business authorization. 'Is this user logged in?' = gateway. 'Is this user allowed to view this order?' = service."

*What separates good from great:* "Never implement business authorization at the gateway. If the gateway checks whether user X can view order Y, the gateway must understand business rules about order ownership. This creates tight coupling. Services are the authority on their own data authorization. The gateway only verifies identity; services verify entitlement."

---

#### Q6 - "How do you handle API versioning at the gateway level?"
> "URL versioning at gateway: /api/v1/ routes to old service version. /api/v2/ routes to new service version. The gateway routes by URL prefix to different backend services or different deployments. During migration: run both versions simultaneously. Use traffic weighting (canary): /api/v2/ sends 5% of traffic to new service, 95% to old (weighted routing in Kong or Spring Cloud Gateway). Monitor v2 error rates. If acceptable, increase to 50%, then 100%. Once all traffic on v2, sunset v1 with a deprecation period. The gateway provides the routing flexibility for this migration without requiring clients to be updated immediately."

*What separates good from great:* "Gateway-level A/B testing and feature flagging: route specific user cohorts to v2 based on user ID headers. 'Users with IDs ending in 0-4 get v2, others get v1.' This allows controlled rollout and quick rollback by changing a gateway routing rule without deploying any service."

---

#### Q7 - "What is the difference between a service mesh and an API gateway?"
> "API gateway: east-west traffic (external to internal), north-south in the service topology diagram. Handles external clients to services. Service mesh: east-west traffic (service to service), within the cluster. Handles internal service-to-service communication. They complement each other: API gateway for external access with auth, rate limiting, and routing. Service mesh for internal service communication with mTLS, circuit breaking, and traffic management. Both are not redundant. A service mesh (Istio) does not replace the API gateway because it does not handle external JWT authentication or API-key-based rate limiting. An API gateway does not replace the service mesh because it does not provide mTLS between services or granular traffic management for internal calls."

*What separates good from great:* "Some service meshes include ingress gateway capabilities (Istio's Ingress Gateway). This can replace a separate API gateway for simpler use cases. But full-featured API gateways (Kong, Apigee) provide functionality that service mesh ingress does not: developer portal, API lifecycle management, analytics dashboards. Evaluate based on whether you need a developer platform or just ingress routing."

---

#### Q8 - "How do you handle gateway security to prevent bypass?"
> "If services can be called directly (bypassing the gateway), all gateway security controls are ineffective. Prevention: services should only be reachable within the cluster (ClusterIP, not NodePort or LoadBalancer). Network policies (Kubernetes NetworkPolicy) restrict which pods can call which services. Only the API gateway pods are allowed to call backend services on their port. Any other pod attempting to call backend services directly is blocked by NetworkPolicy. Additional: services should verify that requests came through the gateway by checking for the gateway's forwarded headers. Mutual TLS between gateway and services - the service only accepts connections with the gateway's certificate."

*What separates good from great:* "Defense in depth for gateway bypass: (1) Kubernetes NetworkPolicy (infrastructure level), (2) mTLS with gateway certificate (transport level), (3) gateway-signed request headers (application level). Three independent controls. An attacker must bypass all three to call services directly. Single controls can be misconfigured; defense in depth provides redundancy."

---

#### Q9 - "How does an API gateway scale to handle 100K requests per second?"
> "A stateless gateway scales horizontally. With 100K req/s at 100 gateway instances = 1,000 req/s per instance. Stateless design is critical: JWT validation results should be cached (in-process LRU cache, not Redis per-request call). Rate limit state is in Redis (shared across instances). Routing configuration is in-memory (loaded on startup). No per-request database calls. Performance profile: a Gateway request should add under 5ms overhead. At 100K req/s, each gateway instance at 1K req/s with 5ms overhead = 5 CPU-ms per request = 5000 CPU-ms/second per instance. With 8-core machines: headroom for 8000 CPU-ms/second, leaving 3000ms of buffer. Bottlenecks: Redis for rate limiting (use Redis Cluster or client-side token bucket with Redis as backup). JWT validation (cache decoded tokens by signature hash for the token TTL)."

*What separates good from great:* "The gateway is not just a performance concern at 100K req/s - it is a reliability concern. At this scale, a 10ms garbage collection pause on all instances simultaneously causes a traffic spike. Configure the gateway JVM for low-GC: use G1GC with maxGCPauseMillis=50, avoid large heap allocations per request, avoid object creation in the hot path."

---

---

# Circuit Breaker Pattern

---

### 🎯 Model Answer

**30 seconds:**
> The circuit breaker pattern prevents a service from repeatedly calling a downstream service that is failing or slow. Like an electrical circuit breaker, it detects fault conditions (high error rate or latency) and "trips" to an open state, failing requests immediately without calling the downstream service. After a timeout, it allows a probe request through to test recovery. If the probe succeeds, the circuit closes and normal traffic resumes. This prevents cascading failures and gives failing services time to recover.

**3 minutes:**
> Without circuit breakers, a slow or failing downstream service can take down its callers. The mechanism: Service A calls Service B. Service B starts timing out (5-second responses instead of 100ms). Service A's thread pool fills with threads waiting for B. Service A's queue fills. Service A itself becomes slow and starts timing out for its own callers. The cascade continues up the call chain. Circuit breakers stop this at each hop. Three states: Closed (normal operation, all calls pass through), Open (failed, all calls fail immediately without calling downstream), and Half-Open (testing state, one probe call through to check recovery). Transitions: Closed -> Open when failure rate exceeds threshold (e.g., 50% errors in 30 seconds or 10 consecutive failures). Open -> Half-Open after a wait duration (e.g., 30 seconds). Half-Open -> Closed if probe succeeds; -> Open if probe fails. The practical benefit: during downstream failure, fast failures (immediate circuit open response) allow callers to return a degraded but useful response (cached data, fallback value) rather than waiting for a timeout. Users see degraded functionality rather than a 30-second wait for a timeout.

**Blank Mind Recovery:**
**(1) Restate:** "Circuit breaker - stop calling a broken service to prevent cascade failures."
**(2) States:** "Closed (normal), Open (fail fast), Half-Open (testing recovery)."
**(3) Benefit:** "Fast failure allows fallback response. Protects caller from cascade failure."

---

### 📘 Concept Explanation

**What it is:**
The circuit breaker pattern wraps a service call in a state machine. When the downstream service fails frequently or slowly, the circuit "trips open" and subsequent calls fail immediately without actually calling the downstream service. This provides: fast failure (no waiting for timeouts), isolation (caller not affected by callee's degradation), and automatic recovery testing (half-open state probes for recovery).

**State machine:**
```
CLOSED (normal):
  All calls pass through to downstream
  Track: error rate, latency
  Transition to OPEN when:
    - Error rate > threshold (50% in 30s window)
    - OR slow call rate > threshold (> 100% calls
      slower than 1s in 30s window)
  
OPEN (fault):
  All calls fail immediately
    (CallNotPermittedException, no network call)
  Wait for: waitDurationInOpenState (e.g., 30s)
  Transition to HALF-OPEN
  
HALF-OPEN (testing):
  Allow: permittedCallsInHalfOpenState (e.g., 3 calls)
  If all succeed -> CLOSED
  If any fail -> OPEN (restart wait timer)

CALLER EXPERIENCE:
  CLOSED: call latency = actual downstream latency
  OPEN: call latency = ~1ms (immediate exception)
  HALF-OPEN: first N calls may succeed or fail
```

**Resilience4j configuration:**
```java
// resilience4j.yml
resilience4j:
  circuitbreaker:
    instances:
      inventory-service:
        registerHealthIndicator: true
        slidingWindowSize: 10          # last 10 calls
        minimumNumberOfCalls: 5        # min before trip
        permittedCallsInHalfOpenState: 3
        automaticTransitionFromOpenToHalfOpenEnabled: true
        waitDurationInOpenState: 30s   # 30s before retry
        failureRateThreshold: 50       # 50% errors
        slowCallRateThreshold: 80      # 80% slow calls
        slowCallDurationThreshold: 2s  # "slow" = >2s
```

**The key insight:**
The circuit breaker does not fix the downstream failure - it isolates the caller from it. The value is: fast failure enables graceful degradation. With a circuit breaker, when inventory service is down, order service returns a useful response (fallback: assume available, check at fulfillment) rather than waiting 30 seconds for a timeout before returning an error.

---

### 💻 Code Example

```java
// BAD: No circuit breaker - cascading failure risk
@Service
public class OrderService {
  private final InventoryClient inventoryClient;

  public OrderResponse createOrder(OrderRequest req) {
    // If InventoryService hangs for 30s:
    // - This thread blocks for 30s
    // - Thread pool fills with blocked threads
    // - OrderService accepts no new requests
    // - OrderService appears hung to its callers
    boolean available = inventoryClient
        .checkAvailability(req.getProductId(), 1);
    // ... rest of order creation
  }
}
```

> **Code walkthrough:** No timeout, no circuit breaker. A slow InventoryService causes thread exhaustion in OrderService, making OrderService appear hung to its own callers. The failure cascades upward.

```java
// GOOD: Circuit breaker with fallback
@Service
public class OrderService {
  private final InventoryClient inventoryClient;

  @CircuitBreaker(
      name = "inventory-service",
      fallbackMethod = "fallbackCheckAvailability")
  @TimeLimiter(name = "inventory-service")
  @Retry(name = "inventory-service")
  public CompletableFuture<Boolean>
      checkAvailability(String productId, int qty) {
    return CompletableFuture.supplyAsync(
        () -> inventoryClient.checkAvailability(
            productId, qty));
  }
  
  // Fallback: called when circuit is open or timeout
  public CompletableFuture<Boolean>
      fallbackCheckAvailability(
          String productId, int qty,
          Throwable throwable) {
    log.warn("Inventory circuit open for {}: {}",
        productId, throwable.getMessage());
    // Optimistic fallback: assume available
    // Inventory will be verified at fulfillment
    // Better UX than rejecting the order
    return CompletableFuture.completedFuture(true);
  }
}
```

> **Code walkthrough:** The @CircuitBreaker annotation wraps the call. When the circuit is open, the fallback method is called instead of the actual service call. The fallback returns an optimistic assumption (available=true) rather than failing the order. This is a business decision: the product team decided that falsely allowing an order is better than rejecting it - inventory will be reconciled at fulfillment. The @Retry handles transient failures before the circuit breaker counts them.

---

### 🎓 Answers by Seniority

**Junior / Mid:** "A circuit breaker is like a power breaker that trips when there's too much current. When a downstream service starts failing or is slow, the circuit breaker 'trips open' and all calls fail immediately instead of waiting for timeouts. After a waiting period, it tests if the service has recovered. This prevents a slow service from making everything slow by filling up threads waiting for it."

**Senior / Staff:** "The circuit breaker is most valuable as an enabler of graceful degradation. Without it, you have two outcomes for a dependency failure: wait for timeouts (bad user experience) or catch exceptions (need to handle every failure manually). With a circuit breaker, the pattern is clean: define a fallback once, and it is used automatically when the circuit trips. The fallback should be a meaningful degraded response, not just an error. This requires thinking about what the system should do when each dependency is unavailable - a valuable design exercise that improves system resilience overall. Configuration challenge: threshold tuning. Set too sensitive and the circuit trips on normal traffic spikes. Set too lenient and it doesn't protect against real failures. Start with conservative settings (50% error rate, 10-call minimum window) and tune based on production data."

---

### ⚠️ Common Misconceptions

**Misconception:** "Circuit breakers prevent downstream services from being overwhelmed."
Reality: Circuit breakers protect the caller from cascade failures. They do not prevent the downstream service from being called at high rates under normal operation. To limit call rate, use rate limiting or bulkhead patterns. A circuit breaker that is Open does reduce load on the downstream (since calls are no longer made), which helps recovery - but this is a side effect, not the primary purpose.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Circuit breaker stuck open - service has recovered but circuit stays open**

Symptoms: Users report errors from a specific feature. The feature's dependency (InventoryService) shows as healthy in monitoring. But the circuit breaker is still OPEN.

Root cause: The circuit's half-open probe calls failed due to a brief transient error that is now resolved. The circuit restarted its wait timer. The circuit is waiting again before trying another probe.

Diagnosis: Check circuit breaker state via /actuator/health (Resilience4j exposes this). Check the circuit breaker event log for the last state transitions and which errors caused the probe to fail.

Fix: Manually trigger a circuit state reset via actuator (for emergency). Long-term: reduce waitDurationInOpenState to re-probe more quickly (30s instead of 60s). Review whether the half-open probe failure was from the same root cause as the original failure or a false positive.

---

### 🎯 Interview Deep-Dive

| Category | Time | Minimum |
|---|---|---|
| Definition | 2 min | 1 |
| Mechanism | 3 min | 2 |
| Scenario | 5 min | 2 |
| Debugging | 3 min | 2 |
| Comparison | 2 min | 1 |
| Trade-off | 2 min | 1 |
| Misconception | 2 min | 1 |
| Scale | 2 min | 1 |
| Design | 3 min | 1 |

#### Q1 - "What are the three states of a circuit breaker and what triggers each transition?"
> "Closed: normal state, all calls pass through. Transitions to Open when: error rate exceeds threshold (e.g., 50% of last 10 calls failed) OR slow call rate exceeds threshold (e.g., 80% of calls took longer than 2 seconds). Open: fault isolation state, all calls return immediately with CallNotPermittedException. Transitions to Half-Open after: waitDurationInOpenState expires (e.g., 30 seconds). Half-Open: recovery testing state, allows N probe calls. Transitions to Closed if: all permitted calls succeed. Transitions back to Open if: any call fails during half-open."

*What separates good from great:* "The sliding window type matters: COUNT_BASED uses the last N calls; TIME_BASED uses the last N seconds. COUNT_BASED is more common but can be misleading: at low traffic (1 call/minute), 1 failure = 100% error rate and the circuit trips immediately. TIME_BASED is more appropriate for low-traffic services since it requires a minimum number of calls in the window."

---

#### Q2 - "How do you design a fallback for a circuit breaker on a payment validation service?"
> "Payment validation failure requires careful fallback design. Options: (1) Fail the payment (reject the transaction). Safest but worst UX. (2) Accept the payment with manual review flag. Mark the order as 'pending-validation' and process later. Risky for fraud. (3) Use cached validation result. If the last validation for this user/card passed within N minutes, use cached pass. Risky for fraud scenarios where validation would now fail. For most payment services: Option 1 is correct. Accepting payments when validation is unavailable creates fraud risk that outweighs UX cost. The fallback should return a clear 503 Service Unavailable, not a silent pass-through. The circuit breaker enables fast failure (no 30-second wait for a timeout) but the fallback should still communicate clearly that the service is unavailable."

*What separates good from great:* "The fallback decision is a business decision, not a technical one. Technical engineers should not decide what happens when a payment service is unavailable without consulting the business and risk teams. Present the options with their trade-offs; let the business decide. Then implement the decision as the circuit breaker fallback."

---

#### Q3 - "Compare circuit breaker, retry, and timeout patterns - when do you use each?"
> "Timeout: set a maximum wait time for any call. Prevent threads from waiting forever. Use on every outgoing call. Typically 1-3 seconds for synchronous service calls. Retry: automatically retry transient failures (network glitch, brief 503). Use for idempotent operations only. Do NOT retry non-idempotent operations (payment authorization - retry could double-charge). Exponential backoff prevents thundering herd on recovery. Circuit breaker: stop retrying when a service is consistently failing. After N failures, open the circuit and fail fast. Use when: a service is expected to have extended outages (not just transient errors). Combined pattern: timeout -> retry (for transient) -> circuit breaker (for sustained). The retry should feed circuit breaker failure counts: a final retry failure counts as a circuit breaker failure."

*What separates good from great:* "The order matters: timeout wraps the individual call attempt. Retry wraps the timeout (retrying on TimeoutException). Circuit breaker wraps the retry (opens after enough retry failures). Resilience4j applies decorators in the order: Circuit Breaker > Retry > Time Limiter > Bulkhead > Rate Limiter. Understanding the wrapping order prevents unexpected interactions."

---

#### Q4 - "A circuit breaker is tripping every 5 minutes despite the downstream service appearing healthy. What do you investigate?"
> "Tripping every 5 minutes suggests: the waitDurationInOpenState is set to 5 minutes, and the service is not actually recovering in that time - or the service appears healthy in a shallow health check but the actual calls are failing. Investigation: (1) Check what errors are triggering the circuit (CircuitBreaker events log). Are they 4xx errors (client errors, not transient) or 5xx/timeouts? (2) Check if the downstream service's health endpoint is checked differently from the actual call path. (3) Check the circuit's slowCallDurationThreshold - maybe the service responds but slowly (degraded, not failed). (4) Check for request body/payload issues - maybe certain request patterns fail while others succeed. (5) Check if the circuit is being tested against a non-production instance that looks healthy but the production instance is failing."

*What separates good from great:* "Circuit breaker event recording is your first diagnostic tool. Resilience4j maintains a ring buffer of events (CALL, FAILURE, STATE_TRANSITION). Inspect the failure events for: what was the exception type, what was the call duration, what was the request. This narrows the failure to specific conditions."

---

#### Q5 - "How do you monitor circuit breakers in production?"
> "Key metrics to expose: circuit state (open/closed/half-open), failure rate (percentage), slow call rate (percentage), successful calls count, failed calls count, total calls count. In Spring Boot: Resilience4j automatically exposes Prometheus metrics via Actuator. Metrics prefix: resilience4j.circuitbreaker.{name}.state (0=closed, 1=open, 2=half-open), resilience4j.circuitbreaker.{name}.failure.rate. Alert when: circuit state is OPEN (immediate notification), circuit has been open for more than N minutes (dependency may need intervention), failure rate exceeds 25% in CLOSED state (early warning before tripping). Dashboard: show all circuit states in a service dependency map. A red (open) circuit is a dependency failure in progress."

*What separates good from great:* "Correlate circuit breaker state changes with deployment events. A circuit that opens 5 minutes after a deploy of the downstream service points to a regression in the downstream service. This correlation is automatic if you tag Grafana annotations with deployment events."

---

#### Q6 - "What is the relationship between circuit breaker and bulkhead patterns?"
> "Complementary patterns that address different failure modes. Circuit breaker: stops calling a failing downstream service. Bulkhead: limits the number of concurrent calls to a downstream service (thread pool or semaphore-based). Without bulkhead: a slow downstream service fills all available threads, starving other calls that go to different services. Bulkhead gives each downstream service its own thread pool or concurrency limit. If InventoryService is slow: the InventoryService bulkhead's 10 threads fill up. But the 10 threads for PaymentService are unaffected. PaymentService calls continue normally. Combined: use both. Circuit breaker prevents wasted calls when a service is consistently failing. Bulkhead limits blast radius when a service is occasionally slow."

*What separates good from great:* "Semaphore-based vs thread-pool bulkhead: Semaphore is lighter (no thread context switching) but blocks the caller thread during the wait. Thread pool runs calls asynchronously on a dedicated pool. Thread pool bulkhead is better for I/O-bound calls where waiting is the bottleneck. Semaphore is better for CPU-bound calls where you want to limit concurrency."

---

#### Q7 - "How does circuit breaker behavior change at 1000 requests per second vs 10 per second?"
> "At 10 req/s with COUNT_BASED window of 10 calls: the window represents 1 second of production. A brief 2-second spike of errors can fill the window and trip the circuit. Recovery: half-open state allows 3 probes, which take 0.3 seconds at 10 req/s. Fast feedback loop. At 1000 req/s with COUNT_BASED window of 10 calls: the window represents 10ms of production. 10ms of errors trips the circuit. This is probably too sensitive - a tiny transient hiccup trips the circuit. Solution: increase the window to 100 calls (representing 100ms at 1000 req/s) or switch to TIME_BASED window (last 10 seconds). Recovery: half-open allows 3 probes at 1000 req/s - this takes 3ms. Very fast feedback. Overall: at high throughput, use TIME_BASED windows for stability. COUNT_BASED windows become noise-sensitive at high call rates."

*What separates good from great:* "Also consider the minimum number of calls threshold. At 1000 req/s, set minimumNumberOfCalls to 100+ to ensure the error rate calculation has statistical significance. At 10 calls, the error rate calculation is too coarse."

---

#### Q8 - "What is the half-open state and why is it necessary?"
> "Half-open prevents the circuit from staying open forever after the downstream service recovers. Without half-open: the circuit must be manually reset when the downstream service recovers. This requires human intervention for every service outage - not scalable. Half-open mechanism: after waitDurationInOpenState expires, the circuit moves to half-open and allows a configurable number of probe calls. If the probes succeed (downstream recovered), the circuit closes automatically. If the probes fail (downstream still failing), the circuit opens again and restarts the wait timer. This enables automatic recovery without human intervention. Design consideration: during half-open, some calls succeed (probes) and some fail (if the circuit re-opens during the probe period). Users may see intermittent errors during recovery. This is expected and acceptable."

*What separates good from great:* "The probe calls in half-open should be representative of real traffic. If the probe is a trivial health check that always passes even when the service is partially degraded, the circuit will close prematurely. Use actual service calls (the same calls that tripped the circuit) as the probe."

---

#### Q9 - "Design circuit breaker configuration for a payment service with a 99.9% uptime requirement."
> "Requirements: 99.9% uptime = max 8.7 hours downtime/year. Circuit breaker configuration for payment-sensitive scenario: failureRateThreshold: 30 (trip at 30% error rate - more sensitive than default 50%). slowCallRateThreshold: 50 (trip if 50% of calls take > 1 second). slowCallDurationThreshold: 1s (payments should complete in under 1 second). slidingWindowSize: 20 (last 20 calls, statistical significance). minimumNumberOfCalls: 10 (need at least 10 calls before evaluating). waitDurationInOpenState: 10s (short wait - re-probe quickly for payments). permittedCallsInHalfOpenState: 5 (5 probes to verify stability). Fallback: on circuit open, return 503 Service Unavailable immediately. Do not accept payments when the payment service is unavailable. Alert immediately when the circuit opens."

*What separates good from great:* "Add a Slack/PagerDuty alert that fires immediately when the payment circuit breaker opens. Payment failures are business-critical. Automatic recovery (circuit reopens after 10s) is insufficient - a human should be notified. The alert includes: circuit state, error rate, last error message, service health dashboard link."

---

### ⚖️ Comparison Table

| Pattern | Protects Against | Mechanism | Complexity |
|---|---|---|---|
| Circuit Breaker | Cascade failure from sustained downstream failure | Fast-fail when failure rate high | Medium |
| Retry | Transient failures (brief network issue) | Retry with backoff | Low |
| Timeout | Thread exhaustion from slow downstream | Max wait time | Low |
| Bulkhead | Thread exhaustion affecting all downstream calls | Thread pool isolation | Medium |
| Rate Limiter | Overwhelm downstream | Limit call rate | Low |

**Combined pattern:** Timeout + Retry + Circuit Breaker + Bulkhead provides comprehensive resilience.
