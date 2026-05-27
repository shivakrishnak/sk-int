---
layout: default
title: "REST API - L4 Production Depth"
parent: "REST API Design and HTTP"
grand_parent: "SK Interview"
nav_order: 7
permalink: /rest-api/l4-production-depth/
---

# API Performance Optimization

🎯 Interview Weight: very high - Performance questions appear in
every senior backend and system design interview.

---

### 🎯 Model Answer

**30 seconds:**
> API performance optimization has four layers: (1) transport
> (HTTP/2, compression, keep-alive), (2) server (connection pool,
> non-blocking I/O, JVM tuning), (3) data access (query optimization,
> connection pool sizing, N+1 prevention), (4) architecture
> (caching, CDN, async offloading). Profile before optimizing.

**3 minutes (Senior):**
> API performance bottlenecks in order of frequency:
>
> Database N+1: the most common. `GET /orders` triggers 1 order
> query + N product queries + N customer queries. Detection:
> enable SQL logging, look for repeated similar queries.
> Fix: JOIN fetch, `@EntityGraph`, DataLoader (GraphQL).
>
> Missing index: a query runs slowly because there is no index
> on the WHERE clause column. Detection: `EXPLAIN ANALYZE` (Postgres),
> `EXPLAIN` (MySQL), slow query log. Fix: add index on the
> filter column.
>
> Serialization overhead: Jackson serializes a 500-field object
> on every request. Fix: use `@JsonView` to return only the fields
> the endpoint needs. Or use projections (DTO queries) at the JPA
> layer to only fetch the needed columns.
>
> Synchronous blocking: a REST endpoint calls an external service
> synchronously. If the external service is slow, threads block.
> Fix: async non-blocking (Spring WebFlux, CompletableFuture), or
> move to async messaging.
>
> Missing HTTP cache: a product catalog API runs the same DB query
> on every request. Fix: `Cache-Control: max-age=300, public`.
> CDN serves 85% of requests from cache.
>
> No connection pooling: new DB connection per request (100ms setup
> overhead). Fix: configure HikariCP (default in Spring Boot)
> with appropriate pool size.
>
> Profiling tools: async-profiler (CPU profiling, flame graphs),
> p6spy or datasource-proxy (SQL query logging with timing),
> Spring Actuator `/actuator/metrics`, distributed tracing (Jaeger,
> Zipkin) to find slow service calls.

**Blank Mind Recovery:**

**(1) Restate:** "How to find and fix API performance bottlenecks."

**(2) First principles:** "Measure before optimizing. Profile to
find the bottleneck (database, network, CPU, I/O). Fix the
bottleneck, not the symptoms."

---

### 💻 Code Example

**GOOD - Diagnosing and fixing N+1 in Spring Data:**

```java
// BAD: N+1 query problem
// GET /orders returns 20 orders
// Then fetches customer for EACH order = 21 queries

@GetMapping("/api/v1/orders")
public List<OrderSummary> listOrders() {
    List<Order> orders = orderRepository.findAll();
    return orders.stream()
        .map(order -> {
            // LAZY loaded: N separate queries
            Customer c = order.getCustomer();
            return new OrderSummary(
                order.getId(),
                c.getName(), // triggers SELECT
                order.getTotal()
            );
        })
        .collect(toList());
}

// GOOD: single JOIN FETCH query
@Query("""
    SELECT o FROM Order o
    JOIN FETCH o.customer c
    WHERE o.status = :status
    """)
List<Order> findAllWithCustomer(OrderStatus status);

// BETTER: DTO projection (only SELECT needed columns)
@Query("""
    SELECT new com.example.OrderSummaryDto(
        o.id, c.name, o.total, o.status, o.createdAt
    )
    FROM Order o
    JOIN o.customer c
    WHERE o.status = :status
    """)
List<OrderSummaryDto> findSummariesByStatus(
    OrderStatus status
);

// TOOL: Detect N+1 in dev/test with datasource-proxy
@Bean
@Profile({"dev", "test"})
DataSource dataSource(
    @Qualifier("originalDataSource") DataSource ds
) {
    QueryLoggingListener listener = new QueryLoggingListener();
    listener.setLogLevel(QueryLogEntryCreator.LogLevel.INFO);
    return ProxyDataSourceBuilder
        .create(ds)
        .name("DS-Proxy")
        .listener(listener)
        .countQuery()       // logs query count per request
        .build();
}
```

> **Code walkthrough:** The BAD example triggers 1 + N database
> queries (1 for orders, N for lazy-loaded customers). With 100
> orders: 101 queries. The `JOIN FETCH` solution fetches all data
> in one query. The DTO projection is the most efficient: it selects
> only the columns needed (`o.id, c.name, o.total`) and maps
> directly to a DTO, avoiding the `Order` entity hydration overhead.
> The `datasource-proxy` bean in dev/test logs the total query
> count per request - a count above 3-5 for a single request is
> a signal to investigate. In production, distributed tracing
> (Jaeger) shows database span counts per request.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Profile first to find the bottleneck. Common issues: N+1 queries
> (fix with JOIN FETCH), missing HTTP cache (fix with
> Cache-Control headers), missing indexes (fix with EXPLAIN ANALYZE).
> Use Spring Actuator and SQL logging to identify slow requests.

---

**Senior / Staff (5+ years):**
> The performance work I do on a new codebase: (1) enable slow query
> logging (>100ms threshold), (2) add datasource-proxy in dev to
> count queries per request, (3) enable distributed tracing and
> look for spans >500ms. Within a day, the top-3 bottlenecks are
> visible. The fixes are usually simple: a missing JOIN FETCH,
> a missing index on a status column, or a Cache-Control header
> on the product catalog. The hard part is convincing the team
> to prioritize it before it becomes a production incident.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 3 min | N+1 + indexes + basic profiling |
| Mid | 5 min | JOIN FETCH + DTO projections + HTTP caching |
| Senior | 7 min | Full profiling workflow + caching strategy + load testing |

---

---

# API Anti-Patterns and Design Smells

🎯 Interview Weight: high - Anti-pattern knowledge demonstrates
practical experience. Senior interviewers ask "what have you
seen go wrong?"

---

### 🎯 Model Answer

**30 seconds:**
> Common API anti-patterns: 200 for all responses (breaks monitoring),
> verbs in URLs (not RESTful), business logic in the gateway,
> breaking changes without versioning, returning mega-objects with
> 100+ fields (over-fetching), and chatty APIs requiring N calls
> for one operation. Each has a specific fix.

**3 minutes (Senior):**
> Most impactful API anti-patterns:
>
> 1. 200 for all responses: all errors return 200 with an error
>    in the body. Monitoring sees 0% error rate. APM tools cannot
>    alert on failures. Fix: use correct HTTP status codes.
>
> 2. RPC-style URLs: `POST /cancelOrder`, `GET /getUsers`. The
>    HTTP method is ignored - all operations use POST. Loses
>    caching, safety, and idempotency semantics. Fix: noun-based
>    URLs with proper HTTP methods.
>
> 3. God endpoint: `GET /everything?include=users,orders,addresses,products&filter=...`
>    One endpoint returns everything. Changes require coordination
>    of all consumers. Fix: GraphQL (client-defined queries) or
>    specific endpoints with BFF aggregation.
>
> 4. Breaking change without versioning: remove a field, rename it,
>    or change a type in production. Clients break silently.
>    Fix: versioning + consumer-driven contract tests.
>
> 5. Ignoring idempotency: a POST endpoint creates a duplicate
>    on client retry. Payments, orders, and emails are processed
>    twice. Fix: Idempotency-Key header pattern.
>
> 6. Missing rate limiting: an API with no rate limits is vulnerable
>    to abuse and DoS. Fix: rate limiting at gateway level.
>
> 7. Sensitive data in URLs: `GET /users?ssn=123-45-6789`.
>    SSNs and tokens in URLs appear in server access logs, browser
>    history, and CDN logs. Fix: sensitive data in request body
>    or headers.
>
> 8. Synchronous chain (distributed monolith): `ServiceA ->
>    ServiceB -> ServiceC -> ServiceD`. One slow service in
>    the chain stalls all callers. Fix: async where possible,
>    circuit breakers, bulkhead isolation.

**Blank Mind Recovery:**

**(1) Restate:** "What common mistakes make APIs hard to use,
monitor, and maintain?"

**(2) First principles:** "Good API design follows HTTP semantics,
is predictable, and fails loudly. Anti-patterns hide errors,
violate contracts, or create fragile dependencies."

---

### 💻 Code Example

**BAD - Multiple anti-patterns in one controller:**

```java
// BAD: Multiple anti-patterns

@PostMapping("/api/doStuff")  // Verb in URL + vague name
public ResponseEntity<Map> doStuff(
    @RequestParam String userId,
    @RequestParam String action,    // Uses action param instead
    @RequestParam String token      // Token in URL = in logs!
) {
    // Handles everything in one endpoint (God endpoint)
    if ("getOrders".equals(action)) {
        // Always 200 even for errors
        try {
            return ResponseEntity.ok(
                Map.of("orders",
                    orderService.getOrders(userId))
            );
        } catch (Exception e) {
            return ResponseEntity.ok(  // WRONG: 200 for error
                Map.of("error", e.getMessage())
            );
        }
    }
    // ... 200 more lines of action-based routing
    return ResponseEntity.ok(Map.of("error", "unknown action"));
}
```

**GOOD - RESTful with correct semantics:**

```java
// GOOD: Separate endpoints, correct status codes,
// token in header not URL

@RestController
@RequestMapping("/api/v1/users/{userId}/orders")
public class UserOrderController {

    @GetMapping
    public ResponseEntity<Page<OrderSummary>> getUserOrders(
        @PathVariable @Valid @Pattern(regexp="[0-9a-f-]{36}")
            String userId,
        @RequestParam(required = false) OrderStatus status,
        @PageableDefault(size = 20) Pageable pageable,
        @RequestHeader("Authorization") String authToken
        // Token in header, not URL (not in access logs)
    ) {
        // Authorization: user can only see their own orders
        String requestingUser = jwtService.extractUserId(
            authToken.substring(7)
        );
        if (!requestingUser.equals(userId)) {
            return ResponseEntity.status(403).build();
        }

        return ResponseEntity.ok(
            orderService.findByUser(userId, status, pageable)
        );
        // Correct status codes: 200 OK or 403 Forbidden
        // Exception handler returns 404/500 as appropriate
    }
}
```

> **Code walkthrough:** The BAD example has five anti-patterns:
> verb in URL, action-based routing (RPC style), token in query
> parameter (visible in access logs), returns 200 for errors,
> and a god endpoint handling all operations. The GOOD example
> uses a noun-based URL (`/users/{userId}/orders`), `Authorization`
> header for the token (not in logs), correct status codes via
> exception handlers, and separate focused endpoints. The
> authorization check verifies the requesting user matches the
> `userId` path parameter - preventing IDOR (Insecure Direct Object
> Reference) where user A accesses user B's orders.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Common REST anti-patterns: 200 for errors, verbs in URLs,
> tokens in URLs. Use correct HTTP status codes, noun-based URLs,
> and Authorization headers.

---

**Senior / Staff (5+ years):**
> The most expensive anti-pattern in production systems is the
> synchronous service chain. `ServiceA -> B -> C -> D` means
> D's latency directly impacts A's response time. If D's p99
> is 500ms, A's p99 is 500ms + overhead. The fix: make B, C, D
> calls parallel where possible; use circuit breakers to prevent
> cascade failures; consider making parts async with message queues.
> At scale, this is the difference between a 50ms p99 and a
> 500ms p99 API.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | Most common anti-patterns + fixes |
| Mid | 4 min | God endpoint + 200-for-errors impact |
| Senior | 6 min | Distributed monolith + security anti-patterns |

---

---

# API Monitoring and Debugging

🎯 Interview Weight: high - Operational readiness is tested in
senior interviews. "How do you know your API is healthy?"

---

### 🎯 Model Answer

**30 seconds:**
> API monitoring tracks: availability (uptime), performance
> (latency percentiles), error rate (4xx/5xx), and throughput
> (requests/second). Tools: Prometheus+Grafana (metrics),
> distributed tracing (Jaeger), structured logging (ELK stack),
> and synthetic monitoring (Pingdom). Alert on SLI/SLO thresholds.

**3 minutes (Senior):**
> The four golden signals for API monitoring (Google SRE):
>
> 1. Latency: track p50, p95, p99 - not average (averages hide
>    outliers). Alert at p99 > 2x the baseline. Histogram metric.
>
> 2. Traffic: requests per second per endpoint. Sudden spike:
>    possible DoS. Sudden drop: possible deployment failure.
>
> 3. Error rate: percentage of 5xx responses. SLO: e.g., error
>    rate < 0.1%. Alert when error budget is burning fast.
>
> 4. Saturation: how full is the system? CPU%, memory%, DB
>    connection pool utilization, thread pool queue depth.
>
> Distributed tracing: every request gets a `traceId`. Each service
> call adds a span. Traces show the complete request path across
> services with timing. Tools: Jaeger, Zipkin, AWS X-Ray.
> Invaluable for: "which service in the chain is slow?"
>
> Structured logging: log as JSON with consistent fields (`traceId`,
> `userId`, `endpoint`, `statusCode`, `durationMs`). ELK stack
> (Elasticsearch + Logstash + Kibana) or Loki+Grafana. Structured
> logs support complex queries: "all orders for user X in the
> last hour with status 500".
>
> Health checks: `/actuator/health` (Spring Boot). Liveness probe
> (is the process alive?), readiness probe (can it serve traffic?).
> Kubernetes uses both for pod lifecycle management.
>
> SLI/SLO: SLI (measurement), SLO (target). Example SLO:
> "99.9% of POST /orders complete < 500ms over 30 days."
> Error budget: 0.1% of requests can fail. Track budget burn rate.

**Blank Mind Recovery:**

**(1) Restate:** "How do you know if an API is healthy and how
do you debug issues?"

**(2) First principles:** "You cannot fix what you cannot measure.
Instrument the API with metrics, traces, and logs. Alert on
threshold violations."

---

### 💻 Code Example

**GOOD - Prometheus metrics + structured logging + tracing:**

```java
// Spring Boot: metrics, tracing, and structured logging

@RestController
@RequestMapping("/api/v1/orders")
@Slf4j
public class OrderController {

    // Custom Prometheus metrics
    private final Counter orderCreatedCounter;
    private final Counter orderErrorCounter;
    private final Timer orderCreateTimer;

    public OrderController(MeterRegistry registry) {
        this.orderCreatedCounter = Counter.builder(
            "api.orders.created.total"
        ).register(registry);

        this.orderErrorCounter = Counter.builder(
            "api.orders.errors.total"
        ).tag("type", "creation").register(registry);

        this.orderCreateTimer = Timer.builder(
            "api.orders.create.duration"
        ).publishPercentiles(0.5, 0.95, 0.99)
         .register(registry);
    }

    @PostMapping
    public ResponseEntity<OrderResponse> createOrder(
        @RequestBody @Valid CreateOrderRequest request,
        @RequestHeader(
            value = "X-Request-ID",
            required = false
        ) String requestId,
        HttpServletRequest httpReq
    ) {
        String traceId = MDC.get("traceId"); // from filter

        return orderCreateTimer.record(() -> {
            try {
                Order order = orderService.create(request);

                orderCreatedCounter.increment();

                // Structured log with correlation fields
                log.info("Order created",
                    // Logback structured arguments (key=value)
                    kv("orderId", order.getId()),
                    kv("customerId", request.getCustomerId()),
                    kv("traceId", traceId),
                    kv("requestId", requestId),
                    kv("amount", order.getTotal())
                );

                return ResponseEntity.status(201)
                    .body(OrderResponse.from(order));

            } catch (BusinessException e) {
                orderErrorCounter.increment();
                log.warn("Order creation failed",
                    kv("reason", e.getCode()),
                    kv("traceId", traceId)
                );
                throw e; // let exception handler return 422
            }
        });
    }
}

// Distributed trace context propagation
@Component
public class TraceContextFilter
    extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(
        HttpServletRequest req,
        HttpServletResponse res,
        FilterChain chain
    ) throws ServletException, IOException {
        String traceId = Optional.ofNullable(
            req.getHeader("X-B3-TraceId")
        ).orElse(UUID.randomUUID().toString().replace("-",""));

        // Put in MDC so all log statements include it
        MDC.put("traceId", traceId);
        // Include in response so client can correlate
        res.setHeader("X-Trace-Id", traceId);

        try {
            chain.doFilter(req, res);
        } finally {
            MDC.clear();
        }
    }
}
```

> **Code walkthrough:** The controller records three metrics:
> a counter for created orders, a counter for errors, and a
> timer with p50/p95/p99 percentiles. Prometheus scrapes these
> every 15 seconds; Grafana dashboards alert when p99 exceeds
> the SLO threshold. The `Timer.record()` wrapper measures
> every `createOrder` execution automatically. Structured logging
> with `kv()` (key-value pairs) produces JSON log lines that
> Kibana can query: "show all orders where amount > 1000 and
> traceId = X". The `TraceContextFilter` puts the trace ID in
> MDC - every log statement from any class in the same request
> thread automatically includes `traceId`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Monitor API health with the four golden signals: latency
> (p99), error rate (5xx%), traffic (rps), and saturation.
> Use Spring Actuator for health checks and Prometheus for
> metrics. Distributed tracing with Jaeger shows cross-service
> request paths.

---

**Senior / Staff (5+ years):**
> SLO definition is the most impactful monitoring decision.
> Without an SLO, monitoring is reactive: alerts when things
> are already broken. With an SLO, monitoring is proactive:
> error budget burn rate alerts when the system is trending
> toward missing the SLO, before users notice. I define SLOs
> per critical path: POST /orders, GET /products. Each has
> latency and availability targets. Alerts fire when burn rate
> predicts the budget will be exhausted in < 1 hour.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | Four golden signals + Spring Actuator |
| Mid | 5 min | Distributed tracing + structured logs |
| Senior | 7 min | SLI/SLO/error budget + monitoring as code |

---

---

# Breaking Change Management

🎯 Interview Weight: high - Breaking change management is tested
at senior/staff interviews. Reveals operational maturity.

---

### 🎯 Model Answer

**30 seconds:**
> Breaking changes are API changes that break existing clients:
> removing fields, renaming fields, changing types, removing
> endpoints. Management strategy: versioning (v1/v2), deprecation
> timeline (announce with Sunset header), contract testing
> (detect before deployment), and traffic monitoring (sunset
> only when traffic reaches 0).

**3 minutes (Senior):**
> Breaking change lifecycle:
>
> 1. Detection: identify the change as breaking (use contract
>    tests, backward-compat tools like openapi-diff).
> 2. Versioning: create a new version (v2 endpoint) with the
>    change. Keep v1 running.
> 3. Migration guide: document what changed and how to update.
>    Provide a migration script or updated client SDK.
> 4. Deprecation notice: add `Deprecation` and `Sunset` headers
>    to v1 responses. Email registered developers. Blog post.
> 5. Traffic monitoring: track requests by version in Grafana.
>    Identify who is still using v1 (by API key, by User-Agent).
> 6. Sunset: when v1 traffic is < 1% for 30 days, shut it down.
>    Return 410 Gone for v1 requests post-sunset.
>
> Non-breaking changes (safe to deploy without versioning):
> - Adding new optional fields to response
> - Adding new optional request parameters
> - Adding new endpoints
> - Making required request fields optional
>
> Avoid breaking changes:
> - Additive extension: add new fields instead of renaming
> - Tolerant reader: clients ignore unknown fields
> - Design for extension upfront: use extensible types
>   (`Object metadata` instead of `String tag`)
>
> Tooling: openapi-diff (detects breaking changes in OpenAPI
> specs), Pact (consumer contracts fail when provider breaks
> them), `Deprecation` header (RFC 8594).

**Blank Mind Recovery:**

**(1) Restate:** "How to evolve an API without breaking existing
clients."

**(2) First principles:** "All clients cannot update simultaneously.
New version + old version coexist. Clients migrate on their
schedule. Old version sunsets when no one uses it."

---

### 💻 Code Example

**GOOD - Backward-compatible evolution and Sunset headers:**

```java
// Adding a non-breaking field (safe, no versioning needed)
// Old: { "customerId": "123" }
// New: { "customerId": "123", "customerEmail": "a@b.com" }
// Old clients ignore customerEmail (tolerant reader)

@GetMapping("/api/v1/orders/{id}")
public OrderResponseV1 getOrder(@PathVariable String id) {
    Order order = orderService.findById(id);
    // V1 still returns the old format
    // New field is ADDED only, never removed/renamed
    return OrderResponseV1.from(order);
}

// Adding Sunset and Deprecation headers to v1 endpoints
@GetMapping("/api/v1/orders/{id}")
public ResponseEntity<OrderResponseV1> getOrderV1(
    @PathVariable String id
) {
    Order order = orderService.findById(id);
    return ResponseEntity.ok()
        // RFC 8594 Deprecation header
        .header(
            "Deprecation",
            "Sat, 01 Jan 2025 00:00:00 GMT"
        )
        // Sunset date: when v1 will be removed
        .header(
            "Sunset",
            "Sat, 01 Jul 2025 00:00:00 GMT"
        )
        // Link to migration guide
        .header(
            "Link",
            "</api/migration/v1-to-v2>; rel=\"successor-version\""
        )
        .body(OrderResponseV1.from(order));
}

// After sunset: return 410 Gone
@GetMapping("/api/v1/orders/{id}")
public ResponseEntity<ProblemDetail> getOrderV1Sunsetted(
    @PathVariable String id
) {
    ProblemDetail problem = ProblemDetail
        .forStatusAndDetail(
            HttpStatus.GONE,
            "API v1 was sunset on 2025-07-01. " +
            "Migrate to /api/v2/orders"
        );
    problem.setType(
        URI.create("https://api.example.com/errors/api-sunset")
    );
    problem.setProperty(
        "migrationGuide",
        "https://docs.example.com/api/migration/v1-to-v2"
    );
    return ResponseEntity.status(410).body(problem);
}
```

> **Code walkthrough:** The `Deprecation` header (RFC 8594) provides
> the date when the deprecation was announced. The `Sunset` header
> provides the date when the endpoint will be removed. Automated
> tools and SDK generators can read these headers and surface
> warnings to API consumers. The `Link` header with `rel="successor-version"`
> links to the migration guide. After the sunset date, the endpoint
> returns 410 Gone (not 404 Not Found - 410 signals permanent removal)
> with a `ProblemDetail` body that includes the migration guide URL.
> Clients receiving 410 can automatically alert developers to migrate.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Breaking changes require a new API version. Keep the old version
> running during a deprecation period. Return 410 Gone after sunset.
> Add `Deprecation` and `Sunset` headers to deprecated versions.

---

**Senior / Staff (5+ years):**
> The most important breaking change prevention tool is contract
> testing in CI. A CI check runs openapi-diff and Pact verification
> on every pull request. If a PR removes a field or changes a type,
> the PR cannot merge. This moves breaking change detection from
> "discovered in production by a customer" to "caught in pull
> request before merge." The developer experience is: the PR fails
> with a clear message "this change breaks consumer X's contract -
> coordinate with them or create a new version."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 2 min | What breaking changes are + versioning |
| Mid | 4 min | Sunset header + traffic monitoring |
| Senior | 7 min | CI detection + contract tests + governance |

---

---

# API Security Vulnerabilities

🎯 Interview Weight: very high - Security is tested at all levels.
OWASP API Security Top 10 is the reference.

---

### 🎯 Model Answer

**30 seconds:**
> OWASP API Security Top 10 most critical: Broken Object Level
> Authorization (BOLA/IDOR - user accesses another user's data),
> Broken Function Level Authorization (accessing admin endpoints),
> mass assignment (client sets fields it should not), and injection
> (SQL, command). Every API must validate object ownership, not
> just authentication.

**3 minutes (Senior):**
> OWASP API Security Top 10 (key ones):
>
> API1: Broken Object Level Authorization (BOLA): the most common.
> `GET /orders/12345` - is this user allowed to see order 12345?
> Just checking if the user is authenticated is not enough. Must
> verify ownership. Fix: always add `WHERE user_id = :currentUser`
> to queries, never trust client-provided resource IDs alone.
>
> API2: Broken Authentication: weak JWT signing (HS256 with weak
> secret), no token expiry, tokens in URLs. Fix: RS256, short expiry,
> tokens in headers only.
>
> API3: Broken Object Property Level Authorization (mass assignment):
> `PUT /users/123` with body `{"name": "Alice", "role": "admin"}`.
> If the server binds all request fields to the entity, the user
> elevates their own role. Fix: explicit DTO (only bind allowed
> fields), never bind the full request body to a JPA entity.
>
> API5: Broken Function Level Authorization: `POST /admin/reports`
> accessible without admin role check. Fix: per-endpoint role
> checks, not just global authentication.
>
> API8: Security Misconfiguration: CORS allows `*`, debug endpoints
> exposed in production, default credentials on backing services.
>
> API6: Unrestricted Resource Consumption: no rate limits, no
> request body size limits. Fix: rate limiting, max body size,
> max array size in batch endpoints.
>
> Injection (SQL, XSS, command): user input concatenated into
> queries. Fix: parameterized queries always.

**Blank Mind Recovery:**

**(1) Restate:** "What are the most critical security vulnerabilities
in REST APIs and how to prevent them?"

**(2) First principles:** "Authentication = who are you. Authorization
= what are you allowed to do. BOLA is an authorization failure:
authenticated but accessing someone else's resource."

---

### 💻 Code Example

**BAD - BOLA and mass assignment vulnerabilities:**

```java
// BAD: BOLA - no ownership check
@GetMapping("/api/v1/orders/{orderId}")
public Order getOrder(@PathVariable String orderId) {
    // ANY authenticated user can get ANY order
    return orderRepository.findById(orderId)
        .orElseThrow(() -> new NotFoundException());
}

// BAD: Mass assignment - binds all request fields
// Client can set role, internalNote, adminFlag
@PutMapping("/api/v1/users/{userId}")
public User updateUser(
    @PathVariable String userId,
    @RequestBody User user  // Entire User entity from request
) {
    user.setId(userId);
    return userRepository.save(user);  // Saves all fields!
}
```

**GOOD - BOLA prevention + explicit DTO:**

```java
// GOOD: Always check ownership

@GetMapping("/api/v1/orders/{orderId}")
public OrderResponse getOrder(
    @PathVariable String orderId,
    @AuthenticationPrincipal JwtPrincipal principal
) {
    Order order = orderRepository.findById(orderId)
        .orElseThrow(() -> new NotFoundException());

    // BOLA prevention: verify ownership
    if (!order.getCustomerId().equals(principal.getUserId())) {
        // Return 404 (not 403) to prevent information leakage
        // (do not reveal the order exists for another user)
        throw new NotFoundException();
    }

    return OrderResponse.from(order);
}

// GOOD: Explicit DTO - only allowed fields

public record UpdateUserRequest(
    @NotBlank @Size(max = 100) String name,
    @Email String email
    // NO: role, adminFlag, internalNote, createdAt
    // Client cannot set these via this endpoint
) {}

@PutMapping("/api/v1/users/{userId}")
public UserResponse updateUser(
    @PathVariable String userId,
    @RequestBody @Valid UpdateUserRequest request,
    @AuthenticationPrincipal JwtPrincipal principal
) {
    // Only the user themselves (or admin) can update
    if (!principal.getUserId().equals(userId)
        && !principal.hasRole("ADMIN")) {
        throw new ForbiddenException();
    }

    User user = userRepository.findById(userId)
        .orElseThrow();
    // Only update the allowed fields from DTO
    user.setName(request.name());
    user.setEmail(request.email());
    // role, adminFlag, etc. unchanged (not in DTO)
    return UserResponse.from(userRepository.save(user));
}
```

> **Code walkthrough:** The BAD BOLA example fetches any order
> by ID without checking the requester's identity. A logged-in
> user can access any order by guessing IDs (if sequential integers,
> trivially enumerable). The GOOD example checks `order.getCustomerId().equals(principal.getUserId())` and
> returns 404 (not 403) to prevent leaking whether the order
> exists for another user (information disclosure). The mass
> assignment fix uses a dedicated `UpdateUserRequest` DTO with
> only the fields the user is allowed to set. The JPA entity is
> updated field-by-field from the DTO - `role` and `adminFlag`
> cannot be set via this endpoint regardless of what the client
> sends.

---

### ⚖️ Comparison Table

| OWASP ID | Vulnerability | Detection | Fix |
|----------|--------------|-----------|-----|
| API1 BOLA | Access other user's data | Pentest, auth audit | Ownership check on every query |
| API2 Broken Auth | Weak JWT, no expiry | Security scan | RS256, short expiry, header only |
| API3 Mass Assignment | Set protected fields | Code review | Explicit DTO, no entity binding |
| API5 Broken FLA | Access admin endpoints | Role audit | Per-endpoint @PreAuthorize |
| API6 Resource Consumption | No limits = DoS | Load test | Rate limit + body size limit |

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> The most critical API security issue is BOLA: checking that the
> authenticated user is authorized to access the specific resource
> they requested. Always verify ownership, not just authentication.
> Use explicit DTOs to prevent mass assignment.

---

**Senior / Staff (5+ years):**
> BOLA is pervasive because it requires discipline on every single
> endpoint - there is no single fix. I enforce it through code
> review checklists (every `findById` must have an ownership check)
> and automated security tests (OWASP ZAP API scan, custom tests
> that attempt to access other users' resources with a valid but
> wrong token). The test: user A's token + user B's resource ID
> must return 404 or 403, never 200.

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Junior | 3 min | BOLA + mass assignment + injection |
| Mid | 5 min | Full OWASP API Top 10 |
| Senior | 7 min | Security testing + defense in depth + BOLA at scale |

---

**[DEBUGGING] A security researcher reported that your API allows
users to view other users' order details by incrementing the
order ID in the URL.** `[SENIOR]`

*Why they ask:* Classic BOLA vulnerability. Tests incident response
and fix ability.

*Likely follow-up:* "How do you prevent this class of bugs in the future?"

Immediate response (incident): (1) Confirm the vulnerability:
test with two accounts, access account A's order with account B's
token. (2) Quantify impact: query logs to find all requests where
the order's owner does not match the requester's user ID -
determine if any data was actually accessed. (3) Disable or add
temporary auth check to the vulnerable endpoint if exploitation
is ongoing. (4) Notify security team and legal (potential data
breach requiring notification). Fix: add ownership check to
`getOrder`: `WHERE order_id = :orderId AND customer_id = :userId`.
Systematic prevention: (1) Add security tests that automatically
test BOLA: test suite calls every read endpoint with a wrong user's
token and asserts 404 or 403. (2) Code review checklist: every
`findById` must include an ownership check. (3) Consider using
non-sequential IDs (UUIDs) to prevent enumeration attacks even
if the ownership check is ever missing.

*What separates good from great:* The log analysis to determine
if exploitation occurred (data breach assessment) and the systematic
prevention measures beyond just fixing the one endpoint.

---

| Interviewer Type | Emphasis |
|------------------|---------|
| Security Engineer | Full OWASP coverage + testing strategy |
| Technical Panel | BOLA + mass assignment code fixes |
| Bar Raiser | Security culture + systematic prevention |
