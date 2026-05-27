---
layout: default
title: "REST API - L3 Advanced Patterns"
parent: "REST API Design and HTTP"
grand_parent: "SK Interview"
nav_order: 5
permalink: /rest-api/l3-advanced-patterns/
---

# OpenAPI Specification and Code Generation

🎯 Interview Weight: medium-high - OpenAPI is the API contract
standard. Code generation from specs accelerates development.

---

### 🎯 Model Answer

**30 seconds:**
> OpenAPI Specification (formerly Swagger) is a machine-readable
> API description format. It defines endpoints, request/response
> schemas, authentication, and documentation in a single JSON/YAML
> file. Tools generate server stubs, client SDKs, mock servers,
> and interactive documentation from this file.

**3 minutes (Senior):**
> OpenAPI is the lingua franca of REST API design. Two workflows:
>
> Code-first: write the server code, annotate it, generate the
> OpenAPI spec at build time. Fast to start. Risk: the spec
> reflects the implementation, including its bugs and shortcuts.
> The spec is a description, not a contract.
>
> Design-first (API-first): write the OpenAPI YAML first.
> Generate server stubs and client SDKs from it. The spec is the
> contract. Frontend and backend can develop in parallel against
> the contract. Client teams can use Prism (mock server) to simulate
> the API before the backend is built. Non-breaking spec changes
> trigger only client regeneration; breaking changes require a
> version bump.
>
> OpenAPI 3.0 structure:
> - `info`: API metadata
> - `servers`: base URLs
> - `paths`: endpoint definitions (verb + path)
> - `components.schemas`: reusable data models
> - `components.securitySchemes`: auth definition
> - `security`: global auth requirement
>
> Code generation tools: OpenAPI Generator (generates server stubs
> in Java/Go/Python, client SDKs in 20+ languages),
> springdoc-openapi (code-first, generates spec from Spring annotations).
>
> Contract testing: use Pact or Schemathesis to test that the server
> implementation matches the OpenAPI spec. Prevents spec drift.

**Blank Mind Recovery:**

**(1) Restate:** "OpenAPI is the standard format for describing
a REST API. It enables tooling for documentation, mocking, and
code generation."

**(2) First principles:** "APIs need a contract. OpenAPI is that
contract written in a machine-readable format that tools can
consume."

---

### 💻 Code Example

**GOOD - Design-first: generate Spring stubs from OpenAPI spec:**

```yaml
# openapi.yaml - written FIRST, before any code
openapi: "3.0.3"
info:
  title: "Order API"
  version: "1.0.0"
paths:
  /orders:
    post:
      operationId: createOrder
      summary: Create a new order
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/CreateOrderRequest"
      responses:
        "201":
          description: Order created
          headers:
            Location:
              schema:
                type: string
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/OrderResponse"
        "422":
          description: Validation error
          content:
            application/problem+json:
              schema:
                $ref: "#/components/schemas/ProblemDetail"
      security:
        - bearerAuth: []
components:
  schemas:
    CreateOrderRequest:
      type: object
      required: [customerId, items]
      properties:
        customerId:
          type: string
          format: uuid
        items:
          type: array
          minItems: 1
          maxItems: 100
          items:
            $ref: "#/components/schemas/OrderItem"
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

```java
// Generated interface - implement this, don't modify
// (regenerated on spec change)
public interface OrdersApi {
    ResponseEntity<OrderResponse> createOrder(
        @Valid CreateOrderRequest request
    );
}

// Implementation: only business logic here
@RestController
public class OrderController implements OrdersApi {

    private final OrderService orderService;

    @Override
    public ResponseEntity<OrderResponse> createOrder(
        @Valid CreateOrderRequest request
    ) {
        Order order = orderService.create(request);
        return ResponseEntity
            .status(201)
            .location(URI.create(
                "/api/v1/orders/" + order.getId()
            ))
            .body(OrderResponse.from(order));
    }
}
```

> **Code walkthrough:** In the design-first workflow, the OpenAPI
> YAML defines the contract: required fields (`customerId`, `items`),
> response schema (`OrderResponse`), security (`bearerAuth`), and
> error responses (422 `ProblemDetail`). The OpenAPI Generator produces
> the `OrdersApi` Java interface from this spec. The controller
> implements the interface - if the controller does not implement
> a method in the spec, compilation fails. The controller is
> implementation-only (business logic); the routing, validation
> annotations, and method signatures are all spec-generated.
> When the spec changes, regenerate the interface and fix compile
> errors in the controller.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> OpenAPI is a YAML/JSON format that describes the API contract.
> Swagger UI generates interactive documentation from it.
> springdoc-openapi auto-generates the spec from Spring annotations
> for code-first development.

---

**Senior / Staff (5+ years):**
> Design-first is the approach I enforce in team APIs. The OpenAPI
> spec is checked in to the repository. API changes require a spec
> change PR reviewed by both API consumers and providers. This is
> an API governance mechanism: it prevents unilateral breaking
> changes, creates a reviewer checklist (does this break existing
> clients?), and keeps documentation in sync with the implementation.
> A CI check compares the live API against the spec (using Schemathesis)
> and fails the build on drift.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | What OpenAPI is + Swagger UI |
| Mid | 4 min | Code-first vs design-first |
| Senior | 6 min | API governance + contract testing |

---

---

# API Gateway Patterns

🎯 Interview Weight: very high - API Gateways are the entry point
for microservice architectures. Appears in system design interviews.

---

### 🎯 Model Answer

**30 seconds:**
> An API gateway is the single entry point for API clients. It
> handles cross-cutting concerns: authentication, rate limiting,
> SSL termination, routing, load balancing, request/response
> transformation, and observability. Backends implement only
> business logic.

**3 minutes (Senior):**
> API gateway patterns:
>
> Simple reverse proxy: route requests to backend services.
> No transformation. NGINX, Traefik. Minimal overhead.
>
> Full API gateway: Kong, AWS API Gateway, Azure API Management.
> Handles auth, rate limiting, caching, request transformation,
> API key management, usage metering. Backend services receive
> pre-validated, pre-authenticated requests.
>
> Gateway responsibilities:
> - SSL termination (HTTPS -> HTTP to backends in private network)
> - JWT validation (verify signature before forwarding)
> - Rate limiting (global enforcement, consistent across all backends)
> - Request routing (path-based, header-based, version-based)
> - Response caching (cache GET responses at gateway level)
> - Request/response transformation (adapt legacy backends)
> - Observability (access logs, metrics, distributed tracing injection)
>
> Gateway anti-patterns:
> - Business logic in the gateway (routing rules based on order
>   state require the gateway to call the database - wrong layer)
> - Gateway as a monolith (all transformations in one giant config)
> - Single gateway for all teams (deployment bottleneck)
>
> BFF (Backend for Frontend): a specialized gateway per client type
> (mobile BFF, web BFF, partner BFF). Each BFF aggregates and
> transforms data for its specific client. Reduces client-server
> round trips.

**Blank Mind Recovery:**

**(1) Restate:** "An API Gateway sits in front of all backend
services. It handles shared concerns so backends don't have to."

**(2) First principles:** "Every microservice would need auth, rate
limiting, and logging. The gateway does this once for all services."

---

### 💻 Code Example

**Spring Cloud Gateway configuration:**

```java
// Spring Cloud Gateway: route config with filters

@Configuration
public class GatewayConfig {

    @Bean
    public RouteLocator routes(
        RouteLocatorBuilder builder
    ) {
        return builder.routes()
            // Route: Order Service
            .route("order-service", r -> r
                .path("/api/v1/orders/**")
                .filters(f -> f
                    // Strip /api/v1 prefix before forwarding
                    .rewritePath(
                        "/api/v1/(?<rest>.*)",
                        "/${rest}"
                    )
                    // Add correlation ID
                    .addRequestHeader(
                        "X-Request-ID",
                        "#{T(java.util.UUID)" +
                        ".randomUUID().toString()}"
                    )
                    // Retry on 503 (max 3 times)
                    .retry(config -> config
                        .setRetries(3)
                        .setStatuses(
                            HttpStatus.SERVICE_UNAVAILABLE
                        )
                    )
                    // Circuit breaker
                    .circuitBreaker(config -> config
                        .setName("orderServiceCB")
                        .setFallbackUri(
                            "forward:/fallback/orders"
                        )
                    )
                )
                .uri("lb://order-service")  // service discovery
            )

            // Route: Auth-protected Product Service
            .route("product-service", r -> r
                .path("/api/v1/products/**")
                .and().header(
                    "Authorization", "Bearer.*"
                )
                .filters(f -> f
                    .rewritePath(
                        "/api/v1/(?<rest>.*)",
                        "/${rest}"
                    )
                )
                .uri("lb://product-service")
            )
            .build();
    }
}
```

> **Code walkthrough:** Spring Cloud Gateway uses a reactive
> pipeline to route requests. The `order-service` route strips
> the `/api/v1` prefix (backends use clean paths like `/orders/123`
> without the API version prefix). A correlation ID is injected
> into every forwarded request - allowing log correlation across
> gateway and backend logs. The retry filter retries on 503 up
> to 3 times (idempotent routes only - DO NOT retry POST routes).
> The circuit breaker opens after repeated failures, routing to
> a fallback endpoint that returns a degraded response rather
> than an error.

---

### ⚖️ Comparison Table

| Solution | Complexity | Features | Cloud Lock-in | Best For |
|----------|-----------|----------|--------------|---------|
| NGINX | Low | Proxy, SSL, LB | No | Simple routing |
| Kong | Medium | Full gateway + plugins | No | On-prem enterprise |
| AWS API Gateway | Low-Medium | Managed, serverless-native | Yes | AWS workloads |
| Spring Cloud Gateway | Medium | Java-native, code config | No | Spring ecosystem |
| Traefik | Low | Container-native, auto-discover | No | Kubernetes |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> An API gateway routes requests from clients to backend services
> and handles auth, rate limiting, and logging centrally. All
> microservices are accessed through the gateway, not directly.

---

**Senior / Staff (5+ years):**
> Gateway granularity is a governance decision. One global gateway
> is a deployment bottleneck: every team's routing change requires
> a gateway deploy. BFF per team gives each team ownership.
> At scale, I use two tiers: an edge gateway (CDN/WAF, SSL termination,
> global rate limiting) and team-level BFFs (business routing,
> auth delegation, response aggregation). This separates security
> and performance concerns from business concerns.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 3 min | What a gateway does + common tools |
| Mid | 5 min | Cross-cutting concerns + BFF pattern |
| Senior | 7 min | Gateway vs BFF + performance + deployment governance |

---

---

# Long-Running Operations and Async APIs

🎯 Interview Weight: high - Async operation patterns are tested
in interviews involving file processing, report generation, and
batch jobs.

---

### 🎯 Model Answer

**30 seconds:**
> When an operation takes longer than the HTTP timeout (typically
> 30-60 seconds), use the async operation pattern: the API returns
> 202 Accepted with a job ID immediately, the client polls
> `GET /operations/{jobId}` for status, and fetches results when
> complete. Webhooks are the push alternative: the server calls
> the client when done.

**3 minutes (Senior):**
> HTTP timeout problem: a video encoding job takes 10 minutes.
> A REST client will timeout after 30-60 seconds. The server must
> return quickly and process asynchronously.
>
> Polling pattern (REST-friendly):
> 1. `POST /reports` returns 202 Accepted with `Location: /reports/jobs/abc123`
> 2. Client polls `GET /reports/jobs/abc123` with exponential backoff
> 3. Job reaches `COMPLETED` state, response includes `resultUri`
> 4. Client fetches `GET /reports/abc123/download` for results
>
> Webhook pattern (event-driven):
> 1. Client registers a callback URL: `POST /webhooks` with callbackUrl
> 2. Server POSTs the result to callbackUrl when complete
> 3. Client must verify the webhook signature (HMAC-SHA256) to
>    prevent spoofing
>
> Polling vs webhook trade-offs: polling is simpler (no inbound
> HTTP to client needed) but wastes requests checking status.
> Webhooks are push (no polling overhead) but require the client
> to expose an HTTP endpoint, handle retries if the endpoint
> is down, and verify signatures.
>
> OData Async pattern (RFC for async REST): `Prefer: respond-async`
> header in request; server returns 202 with `Location` and
> `Retry-After` headers.
>
> Job state machine: PENDING -> PROCESSING -> COMPLETED / FAILED.
> Include progress percentage for long jobs. Include error details
> for FAILED state.

**Blank Mind Recovery:**

**(1) Restate:** "How to handle API operations that take longer
than the HTTP timeout."

**(2) First principles:** "HTTP is synchronous: request waits for
response. Long jobs break this contract. The solution: accept the
job now (202), do the work async, let the client check back."

---

### 💻 Code Example

**GOOD - Async job pattern with polling:**

```java
// POST /reports - accepts job and returns 202 immediately
@PostMapping("/api/v1/reports")
public ResponseEntity<JobResponse> createReport(
    @RequestBody @Valid CreateReportRequest request,
    @RequestHeader("Authorization") String auth
) {
    String userId = jwtService.extractUserId(auth);
    String jobId = reportService.submitAsync(request, userId);

    URI statusUri = URI.create(
        "/api/v1/reports/jobs/" + jobId
    );

    return ResponseEntity
        .accepted()          // 202 Accepted
        .location(statusUri) // Location header for polling
        .header("Retry-After", "5")  // Poll after 5s
        .body(new JobResponse(
            jobId,
            "PENDING",
            statusUri.toString()
        ));
}

// GET /reports/jobs/{jobId} - returns job status
@GetMapping("/api/v1/reports/jobs/{jobId}")
public ResponseEntity<JobStatusResponse> getJobStatus(
    @PathVariable String jobId,
    @RequestHeader("Authorization") String auth
) {
    String userId = jwtService.extractUserId(auth);
    Job job = jobService.findById(jobId);

    // Authorization: user can only see their own jobs
    if (!job.getOwnerId().equals(userId)) {
        return ResponseEntity.status(404).build();
        // 404 not 403: do not leak job existence
    }

    JobStatusResponse response =
        new JobStatusResponse(
            job.getId(),
            job.getStatus().name(),  // PENDING/PROCESSING/DONE
            job.getProgressPct(),    // 0-100
            job.getResultUri(),      // null until COMPLETED
            job.getErrorMessage()    // null unless FAILED
        );

    // Set Retry-After on non-terminal states
    if (!job.isTerminal()) {
        return ResponseEntity.ok()
            .header("Retry-After", "10")
            .body(response);
    }

    return ResponseEntity.ok(response);
}

// Async worker (Spring @Async or Quartz)
@Async
public CompletableFuture<Void> processReport(
    String jobId,
    CreateReportRequest request
) {
    try {
        jobService.updateStatus(jobId, "PROCESSING", 0);

        // ... processing steps with progress updates
        for (int step = 0; step < 10; step++) {
            // do work...
            jobService.updateProgress(
                jobId, (step + 1) * 10
            );
        }

        String resultUri = storageService.store(jobId);
        jobService.complete(jobId, resultUri);
    } catch (Exception e) {
        jobService.fail(
            jobId, e.getMessage()
        );
    }
    return CompletableFuture.completedFuture(null);
}
```

> **Code walkthrough:** The `createReport` endpoint returns 202
> Accepted within milliseconds - it only queues the job and returns
> a job ID. The `Location` header tells the client where to poll.
> `Retry-After: 5` hints the client to wait 5 seconds before
> the first poll. The `getJobStatus` endpoint checks ownership:
> returning 404 (not 403) for jobs owned by other users prevents
> leaking whether a job with that ID exists. The `Retry-After`
> header on non-terminal states guides clients to implement
> exponential backoff rather than tight polling loops.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> For operations longer than the HTTP timeout, return 202 Accepted
> with a job ID. The client polls `GET /jobs/{id}` for status.
> When complete, the response includes a download URL.

---

**Senior / Staff (5+ years):**
> Webhook reliability is the hardest part. The webhook delivery
> system must handle: (1) client endpoint is down (retry with
> exponential backoff for up to 24 hours), (2) client endpoint
> is slow (timeout webhook delivery at 10 seconds, retry later),
> (3) duplicate delivery (webhook consumer must be idempotent -
> same event ID delivered twice should be processed once), (4)
> verification (HMAC-SHA256 signature in `X-Webhook-Signature`
> header). Stripe's webhook delivery system is the reference
> implementation for all of these.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | 202 Accepted + polling pattern |
| Mid | 4 min | Job state machine + Retry-After |
| Senior | 7 min | Webhooks vs polling + reliability + idempotency |

---

---

# API Composition and BFF Pattern

🎯 Interview Weight: high - BFF pattern is standard in
microservices architectures. Appears in system design interviews.

---

### 🎯 Model Answer

**30 seconds:**
> API composition aggregates data from multiple backend services
> into a single response. BFF (Backend for Frontend) is a specialized
> API layer per client type (mobile, web, partner). Each BFF
> aggregates, shapes, and caches data specifically for its client,
> reducing round trips and payload size.

**3 minutes (Senior):**
> The problem BFF solves: a mobile app needs a summary screen
> showing order status, customer info, and product images.
> Without BFF: 3 API calls (order service, customer service,
> product service). With BFF: 1 API call to the mobile BFF which
> fetches from all three services in parallel and returns a
> mobile-optimized response.
>
> BFF responsibilities:
> - Data aggregation: call multiple services in parallel, merge results
> - Data shaping: return only what the client needs (not the full
>   order object with 50 fields when mobile only needs 8)
> - Protocol translation: REST backend, GraphQL or REST to client
> - Authentication forwarding: validate JWT, forward user context
> - Response caching: cache aggregated responses at BFF level
> - Failure handling: graceful degradation (return partial data
>   if one backend fails)
>
> BFF governance: one BFF per client type, owned by the
> client team. Web BFF owned by web team, mobile BFF by mobile
> team. Each team can evolve their BFF independently without
> coordination. Backend services remain generic.
>
> BFF vs API gateway: the gateway handles infrastructure concerns
> (SSL, rate limiting, auth). The BFF handles business aggregation.
> They work together: gateway -> BFF -> backend services.
>
> Failure modes: if the BFF aggregates from 5 services and one
> is slow, the BFF response is slow. Mitigation: parallel calls,
> timeouts per backend call, return partial data with a degraded
> flag.

**Blank Mind Recovery:**

**(1) Restate:** "BFF creates a purpose-built API layer for each
client type, optimizing data for that client."

**(2) First principles:** "Mobile needs small, fast payloads.
Web needs rich data. Partner APIs need stability. One generic API
serves none well. BFF serves each client optimally."

---

### 💻 Code Example

**GOOD - BFF with parallel service calls and graceful degradation:**

```java
// Mobile BFF: aggregates order summary for mobile app

@RestController
@RequestMapping("/mobile/v1")
public class MobileOrderBff {

    private final OrderServiceClient orderClient;
    private final CustomerServiceClient customerClient;
    private final ProductServiceClient productClient;

    // Single endpoint aggregating 3 service calls
    @GetMapping("/order-summary/{orderId}")
    public MobileOrderSummary getOrderSummary(
        @PathVariable String orderId,
        @RequestHeader("Authorization") String auth
    ) {
        String userId = jwtService.extractUserId(auth);

        // Fetch all three in PARALLEL
        CompletableFuture<OrderDto> orderFuture =
            CompletableFuture.supplyAsync(
                () -> orderClient.getOrder(orderId, auth)
            );
        CompletableFuture<CustomerDto> customerFuture =
            CompletableFuture.supplyAsync(
                () -> customerClient.getCustomer(userId, auth)
            );

        // Wait for order before fetching products
        OrderDto order = orderFuture.join();

        List<String> productIds = order.getItems()
            .stream()
            .map(i -> i.getProductId())
            .toList();

        CompletableFuture<List<ProductDto>> productsFuture =
            CompletableFuture.supplyAsync(
                () -> productClient.getProducts(productIds)
            );

        // Wait for remaining futures with timeout
        CustomerDto customer = customerFuture
            .orTimeout(2, TimeUnit.SECONDS)
            .exceptionally(e -> {
                // Graceful degradation: return minimal customer
                log.warn("Customer service degraded: {}",
                    e.getMessage());
                return CustomerDto.minimal(userId);
            })
            .join();

        List<ProductDto> products = productsFuture
            .orTimeout(2, TimeUnit.SECONDS)
            .exceptionally(e -> {
                log.warn("Product service degraded: {}",
                    e.getMessage());
                return List.of();  // Empty: no images
            })
            .join();

        // Shape response for mobile: only needed fields
        return MobileOrderSummary.builder()
            .orderId(order.getId())
            .status(order.getStatus())
            .customerName(customer.getFullName())
            .totalAmount(order.getTotal())
            .itemCount(order.getItems().size())
            .productImages(
                products.stream()
                    .map(p -> p.getThumbnailUrl())
                    .toList()
            )
            .degraded(
                customer.isMinimal() || products.isEmpty()
            )
            .build();
    }
}
```

> **Code walkthrough:** The BFF fires two service calls in parallel
> (`orderFuture` and `customerFuture`) using `CompletableFuture`.
> Product IDs are only known after the order response, so product
> fetching is sequential after the order but concurrent with the
> customer. Each future has a 2-second timeout with graceful
> degradation: if the customer service is slow, the response uses
> a minimal customer object; if the product service is slow, the
> response has no images. The `degraded: true` flag tells the
> mobile client to show a "limited display" indicator. The response
> is mobile-shaped: only the 8 fields mobile needs, not the full
> 50-field order model. This is the BFF pattern's core value:
> optimal data shape for each client type.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> BFF is a dedicated API layer per client type (mobile, web) that
> aggregates and shapes data from backend services. It reduces
> mobile's N API calls to 1 by doing the aggregation server-side.

---

**Senior / Staff (5+ years):**
> BFF ownership is the critical governance decision. The BFF
> must be owned by the client team (mobile team owns mobile BFF,
> web team owns web BFF). If a central API team owns all BFFs,
> it becomes a bottleneck. The client team evolves their BFF at
> their deployment cadence. Backend services remain stable and
> generic. This is the Conway's Law alignment: BFFs map to
> client teams, not to backend domains.

---

### ⚠️ Common Misconceptions

**"BFF is an API Gateway":** An API gateway handles infrastructure
(SSL, rate limiting, auth). A BFF handles business aggregation
(shaping, merging, caching for a specific client). They work at
different layers and are usually both present.

---

### 🚨 Failure Modes and Diagnosis

**Failure: BFF as a bottleneck** - A single BFF serves all
client types. The mobile team's optimization breaks the web
app. Diagnosis: feature requests for the BFF come from multiple
teams with conflicting requirements. Fix: split into separate
BFFs per client type, each owned by the respective team.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | What BFF is + N+1 call problem |
| Mid | 5 min | Parallel aggregation + graceful degradation |
| Senior | 7 min | BFF governance + team topology + failure handling |

---

**[BEHAVIORAL] Tell me about a time you designed or improved an
API composition layer.** `[SENIOR]`

*Why they ask:* Tests real-world experience with BFF/composition.

*Likely follow-up:* "How did you handle failures in dependent services?"

A strong answer structure: (1) Context: what the client needed
(mobile app needing 3-service aggregation), what the old approach
cost (3 sequential API calls from mobile = 450ms). (2) Solution:
designed a mobile BFF that called all three services in parallel.
The parallel calls reduced latency from 450ms to 150ms (the
slowest of the three). (3) Failure handling: added 2-second
timeouts per service, graceful degradation (return partial data
with a `degraded` flag), and circuit breakers to prevent
cascading failures. (4) Outcome: mobile app response time
improved by 67%, app store review score improved due to faster
load times. (5) Trade-off: added a deployment layer to maintain.
Mitigated by: dedicated ownership (mobile team owns the BFF),
automated testing against backend service contracts.

*What separates good from great:* The parallel call optimization
(not sequential), the graceful degradation strategy, and the
team ownership model.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | Implementation + parallel calls |
| System Design | BFF placement + failure handling |
| Bar Raiser | Team topology + governance |
